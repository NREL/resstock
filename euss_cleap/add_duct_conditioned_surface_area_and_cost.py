"""
This file calculates the duct_conditioned_surface_area based on OS-HPXML equations here:
https://github.com/NREL/OpenStudio-HPXML/blob/e96a47e70cb7070ac5baf4969dc4907b130a6e0a/HPXMLtoOpenStudio/resources/hpxml_defaults.rb#L1611-L1631

In EUSS v.1.0 Upgrades 01, 02, 09, 10 (basic and enhanced envelope), where duct sealing is applied and has an energy impacts, 
upgrade cost (using duct_conditioned_surface_area as multiplier) is added back.

Impetus:
we have some discrepancy between whether ducts belong in conditioned spaces in ResStock input tsv vs. where they ended up being assigned to in the modeling layer. 
Ideally, ducts in conditioned spaces should have 0 leakage into unconditioned spaces and therefore it doesn’t matter whether it’s sealed or not. 
But currently, ResStock models some of the ducts in conditioned spaces with leakage and they get energy benefits when sealed. 
More importantly, they get the energy benefit but 0 upgrade cost due to the multiplier. Therefore, for those with energy benefit from duct sealing, upgrade cost is to be added back.
"""

from pathlib import Path
import numpy as np
import pandas as pd
import argparse
import logging


def setup_logging(
        name, filename, file_level=logging.INFO, console_level=logging.INFO
        ):
    global logger
    logger = logging.getLogger(name)
    logger.setLevel(logging.INFO)
    fh = logging.FileHandler(filename, mode="w")
    fh.setLevel(file_level)
    ch = logging.StreamHandler()
    ch.setLevel(console_level)
    formatter = logging.Formatter(
        "%(asctime)s - %(levelname)s - %(message)s"
    )
    fh.setFormatter(formatter)
    ch.setFormatter(formatter)
    # add the handlers to the logger
    logger.addHandler(fh)
    logger.addHandler(ch)


def _assign_duct_location(x):
	""" Duplicating logics of primary duct location from
	https://github.com/NREL/OpenStudio-HPXML/blob/e96a47e70cb7070ac5baf4969dc4907b130a6e0a/HPXMLtoOpenStudio/resources/hvac.rb#L3665-L3684

	Secondary duct location is always Living Space
	"""

	if x["build_existing_model.geometry_foundation_type"]=="Heated Basement":
		return "Conditioned"
	if x["build_existing_model.geometry_foundation_type"]=="Unheated Basement":
		return "Unconditioned"
	if x["build_existing_model.geometry_foundation_type"]=="Heated Crawlspace":
		return "Conditioned" # not in ResStock
	if x["build_existing_model.geometry_foundation_type"]=="Vented Crawlspace":
		return "Unconditioned"
	if x["build_existing_model.geometry_foundation_type"]=="Unvented Crawlspace":
		return "Unconditioned"
	if x["build_existing_model.geometry_attic_type"]=="Vented Attic":
		return "Unconditioned"
	if x["build_existing_model.geometry_attic_type"]=="Unvented Attic":
		return "Unconditioned"
	if x["build_existing_model.geometry_garage"]!="None":
		return "Unconditioned"
	return "Conditioned"


def add_duct_location(dfb):
	dfb["duct_location"] = dfb[[
		"build_existing_model.geometry_foundation_type",
		"build_existing_model.geometry_attic_type",
		"build_existing_model.geometry_garage",
		]].apply(lambda x: _assign_duct_location(x), axis=1)
	return dfb


def get_default_duct_fraction_outside_conditioned_space(ncfl_ag):
	""" Duplicating logic from
	https://github.com/NREL/OpenStudio-HPXML/blob/e96a47e70cb7070ac5baf4969dc4907b130a6e0a/HPXMLtoOpenStudio/resources/hvac.rb#L3639-L3644
	ncfl_ag: pd.Series
	f_out: pd.Series
	"""
	f_out = pd.Series(0.75, index=ncfl_ag.index)
	f_out.loc[ncfl_ag <= 1] = 1
	return f_out

def _get_non_ducted_heating():
	return [
		"None", 
		"Other",
		"Shared Heating", # all shared systems are ductless
		"MSHP, SEER 14.5, 8.2 HSPF",
		"MSHP, SEER 29.3, 14 HSPF",
		"MSHP, SEER 18.0, 9.6 HSPF, 60% Conditioned",
		"MSHP, SEER 17, 9.5 HSPF",
		"MSHP, SEER 25, 12.7 HSPF",
		"MSHP, SEER 33, 13.3 HSPF",
		"Electric Baseboard, 100% Efficiency",
		"Electric Boiler, 100% AFUE",
		"Electric Wall Furnace, 100% AFUE",
		"Fuel Boiler, 72% AFUE",
		"Fuel Boiler, 76% AFUE",
		"Fuel Boiler, 80% AFUE",
		"Fuel Boiler, 82% AFUE",
		"Fuel Boiler, 85% AFUE",
		"Fuel Boiler, 90% AFUE",
		"Fuel Boiler, 95% AFUE, OAT Reset",
		"Fuel Boiler, 96% AFUE",
		"Fuel Wall/Floor Furnace, 60% AFUE",
		"Fuel Wall/Floor Furnace, 68% AFUE",
		"Dual-System MSHP, SEER 15, 9.0 HSPF, Max Load, Separate Backup",
		"Dual-Fuel MSHP, SEER 15, 9.0 HSPF, Max Load, Separate Backup",
		"MSHP, SEER 15, 9.0 HSPF, Max Load", # non-ducted
		# "MSHP, SEER 24, 13 HSPF", # ducted (do not turn on)
		"MSHP, SEER 29.3, 14 HSPF, Max Load", # non-ducted
	]


def _get_non_ducted_cooling():
	return [
		"None",
		"Heat Pump", # superceded by heating eff
		"Shared Heating", # all shared systems are ductless
		"Room AC, EER 8.5",
		"Room AC, EER 9.8",
		"Room AC, EER 10.7",
		"Room AC, EER 12.0",
		"Evaporative Cooler",

	]

def _get_load_fraction_served(heating_eff, cooling_eff, cooling_partial_space_cond):
	"""
	Utility function to calculate fraction of heating and cooling load served to get cfa_served

	This takes care of distinguishing between ducted and ductless, where load_frac_served=0 if ductless
	Each input is a pd.Series of the same index
	Returns a pd.Series of the same index
	"""
	non_ducted_heating = _get_non_ducted_heating()
	non_ducted_cooling = _get_non_ducted_cooling()

	# heating
	heat_load_frac_served = pd.Series(1, index=heating_eff.index)
	cond = heating_eff.isin(non_ducted_heating)
	heat_load_frac_served.loc[cond] = 0

	# cooling
	cool_load_frac_served = cooling_partial_space_cond.map({
		"<10% Conditioned": 0.1,
		"20% Conditioned": 0.2,
		"40% Conditioned": 0.4,
		"60% Conditioned": 0.6,
		"80% Conditioned": 0.8,
		"100% Conditioned": 1,
		"None": 0,
		})
	cond = cooling_eff.isin(non_ducted_cooling)
	cool_load_frac_served.loc[cond] = 0

	load_frac_served = np.maximum(heat_load_frac_served, cool_load_frac_served)

	return load_frac_served


def get_load_fraction_served(dfb, dfu=None):
	"""
	Calculate fraction of heating and cooling load served to get cfa_served

	"""
	heating_eff = dfb["build_existing_model.hvac_heating_efficiency"].copy()
	cooling_eff = dfb["build_existing_model.hvac_cooling_efficiency"].copy()
	cooling_partial_space_cond = dfb["build_existing_model.hvac_cooling_partial_space_conditioning"].copy()

	if dfu is not None:
		upgrade_option_names = [col for col in dfu.columns if col.startswith("upgrade_costs.option_") and col.endswith("_name")]
		for col in upgrade_option_names:
			vals = dfu[col].unique()
			# update heating_eff
			relevant_options = [val for val in vals if val is not None and "HVAC Heating Efficiency" in val]
			if len(relevant_options) > 0:
				# logger.info("heating")
				# breakpoint()
				for upgrade_option in relevant_options:
					cond = dfu[col]==upgrade_option
					heating_eff.loc[cond] = upgrade_option.split("|")[1]
			# update cooling_eff
			relevant_options = [val for val in vals if val is not None and "HVAC Cooling Efficiency" in val]
			if len(relevant_options) > 0:
				# logger.info("cooling")
				# breakpoint()
				for upgrade_option in relevant_options:
					cond = dfu[col]==upgrade_option
					cooling_eff.loc[cond] = upgrade_option.split("|")[1]
			# update cooling_partial_space_cond
			relevant_options = [val for val in vals if val is not None and "HVAC Cooling Partial Space Conditioning" in val]
			if len(relevant_options) > 0:
				# breakpoint()
				for upgrade_option in relevant_options:
					cond = dfu[col]==upgrade_option
					cooling_partial_space_cond.loc[cond] = upgrade_option.split("|")[1]

	load_frac_served = _get_load_fraction_served(
		heating_eff, cooling_eff, cooling_partial_space_cond
		)
	
	return load_frac_served


def calculate_duct_surface_areas(df_baseline, df_upgrade=None):
	""" Duplicating logic of primary and secondary duct surface area from
	https://github.com/NREL/OpenStudio-HPXML/blob/e96a47e70cb7070ac5baf4969dc4907b130a6e0a/HPXMLtoOpenStudio/resources/hvac.rb#L3646C12-L3663
	"""
	if df_upgrade is None:
		dfb = df_baseline.copy()
		dfu = df_baseline.copy()
		load_frac_served = get_load_fraction_served(dfb, dfu=None)
	else:
		idx = sorted(set(df_upgrade.index).intersection(set(df_baseline.index)))
		dfb = df_baseline.loc[idx]
		dfu = df_upgrade.loc[idx]
		load_frac_served = get_load_fraction_served(dfb, dfu=dfu)

	if "duct_location" not in dfb:
		dfb = add_duct_location(dfb)

	cfa_served = dfu["upgrade_costs.floor_area_conditioned_ft_2"] * load_frac_served

	# number of conditioned floors above grade
	ncfl_ag = dfb["build_existing_model.geometry_stories"].astype(int)
	cond = dfb["build_existing_model.geometry_building_type_recs"].isin(["Multi-Family with 2 - 4 Units", "Multi-Family with 5+ Units"])
	ncfl_ag.loc[cond] = 1

	# number of registers = ncfl = ncfl_ag + 1 if a conditioned basement
	n_registers = ncfl_ag
	cond = dfb["build_existing_model.geometry_foundation_type"]=="Heated Basement"
	n_registers.loc[cond] += 1

	# fraction of ducts outside conditioned space
	f_out = get_default_duct_fraction_outside_conditioned_space(ncfl_ag)

	# supply surface areas
	supply_primary = 0.27 * cfa_served * f_out
	supply_secondary = 0.27 * cfa_served * (1-f_out)

	# return surface areas
	b_r = 0.05*n_registers
	b_r.loc[n_registers >= 6] = 0.25
	return_primary = b_r * cfa_served * f_out
	return_secondary = b_r * cfa_served * (1-f_out)

	# conditioned surface area
	conditioned_area = supply_secondary + return_secondary
	cond = dfb["duct_location"] == "Conditioned"
	conditioned_area.loc[cond] += supply_primary.loc[cond] + return_primary.loc[cond]

	# unconditioned surface area
	unconditioned_area = pd.Series(0, index=dfb.index)
	cond = dfb["duct_location"] == "Unconditioned"
	unconditioned_area.loc[cond] += supply_primary.loc[cond] + return_primary.loc[cond]

	total_duct_area = conditioned_area + unconditioned_area

	return [conditioned_area, unconditioned_area, total_duct_area]

def update_baseline(dfb):
	dfb = add_duct_location(dfb)
	duct_areas = calculate_duct_surface_areas(dfb)

	dfb["build_existing_model.hvac_has_ducts"] = "Yes"
	dfb.loc[duct_areas[2]==0, "build_existing_model.hvac_has_ducts"] = "No"
	dfb.loc[duct_areas[2]==0, "duct_location"] = "None" # override

	# fix other hc based on HVAC Has Shared System, with which HVAC Has Ducts is coordinated
	cond = dfb["build_existing_model.hvac_has_shared_system"].isin(["Heating Only", "Heating and Cooling"])
	dfb.loc[cond, "build_existing_model.hvac_heating_type"] = "Non-Ducted Heating"

	cond = dfb["build_existing_model.hvac_has_shared_system"].isin(["Cooling Only", "Heating and Cooling"])
	dfb.loc[cond, "build_existing_model.hvac_cooling_type"] = "Fan Coil Cooling"

	dfb = dfb.assign(duct_conditioned_surface_area=duct_areas[0])
	dfb = dfb.assign(duct_unconditioned_surface_area=duct_areas[1])
	dfb = dfb.assign(duct_total_surface_area=duct_areas[2])

	return dfb


def recalculate_duct_sealing_costs(dfu, dfb):
	duct_areas = calculate_duct_surface_areas(dfb, df_upgrade=dfu)

	dfu = dfu.assign(duct_conditioned_surface_area=duct_areas[0])
	dfu = dfu.assign(duct_unconditioned_surface_area=duct_areas[1])
	dfu = dfu.assign(duct_total_surface_area=duct_areas[2])

	upgrade_hc = "build_existing_model.ducts"
	upgrade_option = "Ducts|10% Leakage, R-8"
	upgrade_from = [
		["30% Leakage, R-4", "30% Leakage, R-6"],
		["30% Leakage, R-8"],
		["20% Leakage, Uninsulated", "20% Leakage, R-4", "20% Leakage, R-6",],
		["20% Leakage, R-8"],
		["10% Leakage, Uninsulated", "10% Leakage, R-4", "10% Leakage, R-6",],
	]

	upgrade_cost_rate = [
		2.84,
		1.04,
		2.32,
		0.52,
		1.80,
	] 
	upgrade_option_names = [col for col in dfu.columns if col.startswith("upgrade_costs.option_") and col.endswith("_name")]

	need_modify = []
	for col in upgrade_option_names:
		if upgrade_option in dfu[col].unique():
			no_change = True
			cost_col = col.replace("_name", "_cost_usd")
			cond0 = dfu[col]==upgrade_option

			for uf, ucr in zip(upgrade_from, upgrade_cost_rate):
				cond = cond0 & dfb[upgrade_hc].isin(uf)
				if cond.sum() > 0:
					logger.info(f"Updating {cond0.sum()} {cost_col} from {uf}")
					assert cond.sum() == cond0.sum(), f"mismatch conditions: {cond.sum()} found, expecting {cond0.sum()}"
					new_cost = dfu.loc[cond, "duct_total_surface_area"] * ucr

					if (new_cost==0).sum() > 0:
						subset = new_cost.loc[new_cost==0]
						logger.info(f"{len(subset)} new_cost=0 found:\n{subset}")
						# not required, just showing for context
						subset_baseline = dfb.loc[subset.index, 
						["build_existing_model.hvac_has_ducts", "duct_total_surface_area",
						"build_existing_model.ducts", "build_existing_model.hvac_heating_efficiency", 
						"build_existing_model.hvac_cooling_efficiency", "build_existing_model.hvac_shared_efficiencies"]]
						logger.info(subset_baseline)

						test_cond = dfb.loc[subset.index, "duct_total_surface_area"]==0
						test_cond &= dfu.loc[subset.index, "duct_total_surface_area"]==0
						assert test_cond.sum() == len(subset), "test_cond != len(subset)"
						dfu.loc[subset.index, col] = np.nan # override with null because upgrade did not apply
						need_modify += list(subset.index)

					dfu.loc[cond, "upgrade_costs.upgrade_cost_usd"] += new_cost - dfu.loc[cond, cost_col].fillna(0)
					dfu.loc[cond, cost_col] = new_cost

					no_change = False

			if no_change:
				logger.info(f" X No update made for {cost_col} from {uf}")

	if len(need_modify) > 0:
		test_cond = dfu.loc[need_modify, "upgrade_costs.upgrade_cost_usd"]==0
		need_remove = test_cond.loc[test_cond].index
		metric = "report_simulation_output.energy_use_total_m_btu"
		test_cond2 = dfu.loc[need_remove, metric].round(1) == dfb.loc[need_remove, metric].round(1)
		assert (test_cond2).prod() == 1, f"total energy dfu != dfb for {list(need_remove)}\n{test_cond2}"
		logger.info(f"Dropping {len(need_remove)} / {len(need_modify)} building_id(s) whose content have been modified for duct correction.\n{list(need_remove)}")
		logger.info("For these buildings, duct sealing was the only applicable component in the upgrade and it no longer applies after the correction.")
		dfu = dfu.drop(index=need_remove)

	return dfu


def process_files(community_name):
	data_dir = Path(".").resolve() / "data_" / "community_building_samples" / community_name 
	setup_logging(community, data_dir / f"output__duct_correction__{community}.log")

	baseline_file = data_dir / f"up00.parquet"
	dfb = pd.read_parquet(baseline_file).set_index("building_id")
	dfb = dfb.loc[dfb["completed_status"]=="Success"]
	dfb_orig = dfb.copy()
	dfb = update_baseline(dfb)

	# report change
	metrics = ["build_existing_model.hvac_has_ducts", "build_existing_model.hvac_heating_type", "build_existing_model.hvac_cooling_type",]
	delta = dfb_orig[metrics].compare(dfb[metrics])
	logger.info(f"After duct correction, housing characteristics for {len(delta)} / {len(dfb_orig)} buildings in baseline are changed: ")
	logger.info("Note: self=original, other=new. NAN values represent no change.")
	logger.info(f"\n{delta}")

	# save to file
	baseline_file_out = baseline_file.parent / (baseline_file.stem+"_duct_corrected"+baseline_file.suffix)
	dfb.reset_index().to_parquet(baseline_file_out)
	logger.info(f"Baseline fle updated and saved to: {baseline_file.parent}")

	for upgrade_no in range(1, 11):
		upgrade_file  = data_dir / f"up{upgrade_no:02d}.parquet"
		dfu = pd.read_parquet(upgrade_file).set_index("building_id")
		dfu = dfu.loc[dfu["completed_status"]=="Success"]

		logger.info("")
		logger.info("=====================================================================================")
		logger.info(f"\n>> Recalculating duct sealing applicability and costs for upgrade_no = {upgrade_no}...")
		dfu2 = recalculate_duct_sealing_costs(dfu, dfb)

		# report change
		upgrade_cost_change = pd.concat([
				dfu["upgrade_costs.upgrade_cost_usd"].replace(0, np.nan).describe().rename("Before Correction (excludes 0)"),
				dfu2["upgrade_costs.upgrade_cost_usd"].describe().rename("After Correction")
				], axis=1)

		logger.info(f"After duct correction, dfu has reduced in size from {len(dfu)} to len(dfu2) rows.")
		logger.info("Change in upgrade_costs.upgrade_cost_usd:")
		logger.info(f"\n{upgrade_cost_change}")

		# save to file
		upgrade_file_out = upgrade_file.parent / (upgrade_file.stem+"_duct_corrected"+upgrade_file.suffix)
		dfu2.reset_index().to_parquet(upgrade_file_out)
		logger.info(f"Upgrade file updated and saved to: {upgrade_file_out}")
		

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "community_name",
        help="name of community, for adding extension to output file",
    )

    community = parser.parse_args().community_name
    process_files(community)
