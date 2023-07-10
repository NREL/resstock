# import packages
from pathlib import Path
import sys
import numpy as np
import pandas as pd
import csv
import re
import math
from itertools import chain

from postprocess_electrical_panel_size_nec import apply_standard_method, apply_optional_method

## func
def format_housing_parameter_name(hc):
	return "_".join([x for x in chain(*[re.split('(\d+)',x) for x in hc.lower().split(" ")]) if x not in ["", "-"]])


def min_amperage_main_breaker(x):
    """Convert min_amperage_nec_standard into standard panel size
    http://www.naffainc.com/x/CB2/Elect/EHtmFiles/StdPanelSizes.htm
    """
    if pd.isnull(x):
        return np.nan

    standard_sizes = np.array([50, 60, 70, 100, 125, 150, 200, 300, 400, 600]) # it is not permitted to size service below 100 A (NEC 230.79(C))
    factors = standard_sizes / x

    cond = standard_sizes[factors >= 1]
    if len(cond) == 0:
        print(
            f"WARNING: {x} is higher than the largest standard_sizes={standard_sizes[-1]}, "
            "double-check NEC calculations"
        )
        return math.ceil(x / 100) * 100

    return cond[0]

## main
community_name = "san_jose" # <--
use_peak_for_baseline = False # <---
use_qoi_for_peak = True ## Always use QOI

datadir = Path(".").resolve() / "data_" / "community_building_samples_with_upgrade_cost_and_bill"

### baseline
dfb = pd.read_parquet(datadir / community_name / f"up00__{community_name}.parquet")
dfb = dfb.loc[dfb["completed_status"]=="Success"].set_index("building_id")

if use_qoi_for_peak:
	metric = "qoi_report.qoi_peak_magnitude_use_kw"
	bl_peak_kw = dfb[metric]
else:
	metrics = [
		"report_simulation_output.peak_electricity_winter_total_w",
		"report_simulation_output.peak_electricity_summer_total_w"
		]
	bl_peak_kw = dfb[metrics].max(axis=1) / 1000


dff = apply_optional_method(dfb, new_load_calc=False)
if use_peak_for_baseline:
	baseline_amp = (bl_peak_kw * 1000 / 240) # W/V =[A]

	# according to "HEA data 15-min peak vs. panel amperage" from Brennan Less, peak ~ 1/4 of panel amp
	baseline_panel_amp = (baseline_amp * 4).apply(lambda x: min_amperage_main_breaker(x))

	# correct vacant home baseline panel size by using NEC optional method
	cond = dfb["build_existing_model.vacancy_status"]=="Vacant"
	baseline_panel_amp.loc[cond] = dff.loc[cond, "opt_m_nec_min_amp"].apply(lambda x: min_amperage_main_breaker(x))
else:
	baseline_panel_amp = dff["opt_m_nec_min_amp"].apply(lambda x: min_amperage_main_breaker(x))
del dff

# for new load calculation
dfb = apply_optional_method(dfb, new_load_calc=True) 

### upgrade
DF_by_peak_delta, DF_by_nec = [], []
for upn in range(1, 11):
	df = pd.read_parquet(datadir / community_name / f"up{upn:02d}__{community_name}.parquet")
	df = df.loc[df["completed_status"]=="Success"].set_index("building_id").reindex(dfb.index)
	upgrade_name = df["apply_upgrade.upgrade_name"].unique()[0]
	n_applicable = df["sample_weight"].sum()

	if use_qoi_for_peak:
		up_peak_kw = df[metric]
	else:
		up_peak_kw = df[metrics].max(axis=1) / 1000

	upgrade_amp = up_peak_kw * 1000 / 240 # W/V =[A]

	peak_delta_kw = (up_peak_kw - bl_peak_kw)
	peak_delta_pct = peak_delta_kw / bl_peak_kw * 100 # [%]


	delta_thresholds = [25, 50, 75, 100, 125, 150]
	delta_pct_above = []
	# check delta:
	for min_delta in delta_thresholds:
		cond_high_delta = peak_delta_pct >= min_delta
		n_high_delta = df.loc[cond_high_delta, "sample_weight"].sum()
		pct_high_delta = n_high_delta / n_applicable
		delta_pct_above.append(pct_high_delta)

	df_delta = pd.Series(
		[int(n_applicable)]+delta_pct_above, 
		index=["n_applicable"]+[f"peak_increase>={x}%" for x in delta_thresholds]
		).rename(upgrade_name)
	DF_by_peak_delta.append(df_delta)

	# --- new load calc ---
	df_new_meta = dfb[[x for x in dfb.columns if x.startswith("build_existing_model.")]]
	option_name_cols = [x for x in df.columns if "upgrade_costs.option" in x and "name" in x]
	for col in option_name_cols:
		cond = df[col].str.contains("|").fillna(False)
		if cond.sum() > 0:
			dfs = df.loc[cond, col]
			up_para, up_optn = dfs.str.split("|").iloc[0] # take only one entry
			up_para = "build_existing_model." + format_housing_parameter_name(up_para)

			# temp bypass (TODO)
			if up_para == "build_existing_model.infiltration_reduction":
				continue

			assert up_para in df_new_meta.columns, f"Unknown up_para: {up_para} from {col}"
			df_new_meta.loc[cond, up_para] = up_optn

	dfu = df = df.join(df_new_meta)
	
	# --- NEC 220.80 (Optional Method) ---
	dfu = apply_optional_method(dfu, new_load_calc=True)
	new_panel_amp_opt_method  = dfu["opt_m_nec_min_amp"]
	new_loads = (dfu["opt_m_demand_load_total_VA"] - dfb["opt_m_demand_load_total_VA"]).clip(lower=0)

	cond_replace_opt_method = (new_loads > 0) & (new_panel_amp_opt_method >= baseline_panel_amp)
	n_replace_opt_method = df.loc[cond_replace_opt_method, "sample_weight"].sum()
	pct_replace_opt_method = n_replace_opt_method / n_applicable
	
	# --- NEC 220.87 (Load Study) ---
	new_panel_amp_load_study = (bl_peak_kw*1000*1.25 + new_loads) / 240 # W/V = [A] # TODO: new load should be at 100% DF

	cond_replace_load_study = (new_loads > 0) & (new_panel_amp_load_study >= baseline_panel_amp)
	cond_replace_load_study = df.loc[cond_replace_load_study, "sample_weight"].sum()
	pct_replace_load_study = cond_replace_load_study / n_applicable

	if "Heat pumps, min-efficiency, existing heating as" in upgrade_name:
		breakpoint()

	# combine
	df_replace = pd.Series(
		[int(n_applicable), pct_replace_opt_method, pct_replace_load_study], 
		index=["n_applicable", "optional method", "load_study"]
		).rename(upgrade_name)
	DF_by_nec.append(df_replace)


DF_by_peak_delta = pd.concat(DF_by_peak_delta, axis=1).transpose()
DF_by_peak_delta.index.name = "upgrade_name"
print("Of those applicable to each upgrade package, the fraction seeing electric peak increase post-upgrade:")
print(DF_by_peak_delta)

DF_by_peak_delta.to_csv(datadir / community_name /  f"fraction_of_peak_increase_{community_name}.csv", index=True)

# Based on NEC calc, assuming baseline_amp
DF_by_nec = pd.concat(DF_by_nec, axis=1).transpose()
DF_by_nec.index.name = "upgrade_name"
DF_by_nec["average"] = DF_by_nec[DF_by_nec.columns[1:]].mean(axis=1)
print("Of those applicable to each upgrade package, the fraction likely requiring panel upgrade based on NEC calculation:")
print(DF_by_nec)

DF_by_nec.to_csv(datadir / community_name / f"fraction_of_panel_upgrade_nec_{community_name}.csv", index=True)




