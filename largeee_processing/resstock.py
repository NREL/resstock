import geopandas as gpd
import logging
import pandas as pd
import polars as pl
import polars.selectors as cs
import pathlib
import re
from typing import List
from collections import defaultdict

from utils import energy_unit_conv_to_kwh, shrink_colname, LB_TO_KG

logger = logging.getLogger(__name__)

endues_energy_col_re = re.compile(
    r"^report_simulation_output\.(fuel|end)_use_(electricity|natural_gas|fuel_oil|propane)_(\w+)_(kwh|therm|mbtu|m_btu)$"
)
emissions_re = re.compile(
    r"^report_simulation_output\.emissions_co_2_e_(\w+)_(electricity|natural_gas|fuel_oil|propane)_(total)_lb$"
)
energy_use_re = re.compile(
    r"^report_simulation_output\.energy_use_(net|total)_(m_btu)$"
)
hot_water_re = re.compile(
    r"^report_simulation_output\.hot_water_(\w+)_gal$"
)
load_delivered_re = re.compile(
    r"^report_simulation_output\.load_(cooling|heating|hot_water)_delivered_m_btu$"
)
peak_electricity_re = re.compile(
    r"^report_simulation_output\.peak_electricity_(summer|winter)_total_w$"
)
peak_load_re = re.compile(
    r"^report_simulation_output\.peak_load_(cooling|heating)_delivered_k_btu_hr$"
)
unmet_hours_re = re.compile(
    r"^report_simulation_output\.unmet_hours_(cooling|heating)_hr$"
)
upgrade_costs_re = re.compile(
    r"^upgrade_costs\.(?!.*(_yrs|applicable|floor_area_conditioned_ft_2)$).*$"
)
bill_costs_re = re.compile(
   r"^report_utility_bills\.utility_rates_fixed_variable(_electricity|_natural_gas|_fuel_oil|_propane)?_total_usd$"
)
all_outcols_re = [endues_energy_col_re, emissions_re, energy_use_re, hot_water_re, load_delivered_re,
                  peak_electricity_re, peak_load_re, unmet_hours_re, bill_costs_re]


ts_enduse_re = re.compile(
    r"^(end|fuel)_use__(electricity|natural_gas|fuel_oil|propane|wood_cord|wood_pellets|coal)__(\w+)__(kbtu|kwh)$"
)
ts_energy_use_re = re.compile(r"^energy_use__(net|total)__(kbtu|kwh)$")
ts_emissions_re = re.compile(r"^emissions__co2e__(\w+)__total__lb$")
ts_load_re = re.compile(r"^load__(cooling|heating|hot_water)__delivered__kbtu$")
ts_zone_temp_re = re.compile(r"^zone_mean_air_temperature__([\w-]+)__c$")
ts_outdoor_temp_re = re.compile(r"^site_outdoor_air_drybulb_temperature__environment__c$")


def convert_output_cols(
    df: pl.LazyFrame, sqft_col: str,
) -> pl.LazyFrame:
    new_cols_list = []
    all_fuel_emissions = defaultdict(list)
    for col in df.columns:
        if m1 := endues_energy_col_re.match(col):
            fuel_or_end, fueltype, enduse, fuelunits = m1.groups()
            newcol_name = shrink_colname(f"out.{fueltype}.{enduse}.energy_consumption")
            if fuelunits in energy_unit_conv_to_kwh:
                new_col = (pl.col(col) * energy_unit_conv_to_kwh[fuelunits]).alias(newcol_name)
            else:
                assert fuelunits == "kwh"
                new_col = pl.col(col).alias(newcol_name)
            new_cols_list.append(new_col)
            intensity_col = (new_col / pl.col(sqft_col)).alias(f"{newcol_name}_intensity")
            new_cols_list.append(intensity_col)
        elif m2 := emissions_re.match(col):
            emissions_scenario, fueltype, enduse = m2.groups()
            newcol_name = f"out.{fueltype}.{enduse}.{emissions_scenario}.co2e_kg"
            new_cols_list.append((pl.col(col) * LB_TO_KG).alias(newcol_name))
            all_fuel_emissions[emissions_scenario].append((pl.col(col) * LB_TO_KG))
        elif m3 := energy_use_re.match(col):
            net_or_total, fuelunits = m3.groups()
            newcol_name = f"out.site_energy.{net_or_total}.energy_consumption"
            new_col = pl.col(col) * energy_unit_conv_to_kwh[fuelunits]
            new_cols_list.append((new_col).alias(newcol_name))
            new_cols_list.append((new_col / pl.col(sqft_col)).alias(f"{newcol_name}_intensity"))
        elif m4 := hot_water_re.match(col):
            hot_water_enduse = m4.groups()[0]
            newcol_name = f"out.hot_water.{hot_water_enduse}.gal"
            new_cols_list.append((pl.col(col)).alias(newcol_name))
        elif m5 := load_delivered_re.match(col):
            load_end_use = m5.groups()[0]
            newcol_name = f"out.load.{load_end_use}.energy_delivered.kbtu"
            new_cols_list.append((pl.col(col) * 1000).alias(newcol_name))
        elif m6 := peak_electricity_re.match(col):
            peak_period = m6.groups()[0]
            newcol_name = f"out.electricity.{peak_period}.peak.kw"
            new_cols_list.append((pl.col(col) / 1000.0).alias(newcol_name))
        elif m7 := peak_load_re.match(col):
            load_type = m7.groups()[0]
            newcol_name = f"out.load.{load_type}.peak.kbtu_hr"
            new_cols_list.append((pl.col(col)).alias(newcol_name))
        elif m8 := unmet_hours_re.match(col):
            cooling_or_heating = m8.groups()[0]
            newcol_name = f"out.unmet_hours.{cooling_or_heating}.hour"
            new_cols_list.append((pl.col(col)).alias(newcol_name))
        elif m9 := bill_costs_re.match(col):
            fuel = m9.groups()[0]
            fuel = "all_fuel" if fuel is None else fuel[1:]
            newcol_name = f"out.bill_costs.{fuel}.usd"
            new_cols_list.append((pl.col(col)).alias(newcol_name))
        else:
            new_cols_list.append(pl.col(col))
    for scenario, emissions in all_fuel_emissions.items():
        newcol_name = f"out.emissions.all_fuels.{scenario}.co2e_kg"
        new_cols_list.append(pl.sum_horizontal(emissions).alias(newcol_name))
    return df.select(new_cols_list)


def get_outcols(metadata_parquet_list) -> List[str]:
    """Get the output columns to keep from the analysis
    """
    logger.info("Getting output columns")

    def get_cols_that_match_any_outcol_re(cols):
        return [col for col in cols if any(re.match(col) for re in all_outcols_re)]

    outcols = set()
    for parquet_file in metadata_parquet_list:
        df = pl.scan_parquet(parquet_file)
        upg_outcols_all = get_cols_that_match_any_outcol_re(df.columns)
        outcols.update(upg_outcols_all)

    sorted_outcols = sorted(outcols)

    return sorted_outcols


def read_formatted_metadata_file(file_path: str, upgrade_name: str, outcols):
    df = pl.scan_parquet(file_path).filter(pl.col("completed_status") == "Success")
    applicable_cols = [col for col in df.columns if "applicable" in col]
    df = df.select(pl.exclude(applicable_cols))
    df = df.rename({
        col: col
             .replace("building_id", "bldg_id")
             .replace("upgrade_costs.floor_area_conditioned_ft_2", "in.sqft")
             .replace("build_existing_model.sample_weight", "weight")
             .replace("build_existing_model.", "in.")
             .replace("upgrade_costs.", "out.params.")
             .replace("apply_upgrade.upgrade_name", "out.params.upgrade_name")
        for col in df.columns
    })

    missing_cols = set(outcols).difference(df.columns)
    df = df.with_columns(pl.lit(0).alias(missing_col) for missing_col in missing_cols)
    df = convert_output_cols(df, "in.sqft")
    df = df.with_columns(pl.lit(upgrade_name).alias("upgrade"))
    df = df.with_columns(pl.lit(True).alias("applicability"))
    df = df.select(cs.starts_with("bldg_id", "weight", "upgrade", "applicability", "in.", "out."))
    return df


def get_bs_metadata_and_annual(baseline_path: str, outcols: List[str]) -> pl.LazyFrame:
    """Process the baseline metadata into the SightGlass format
    """
    logger.info("Calling process_baseline_metadata")
    df = read_formatted_metadata_file(baseline_path, 'baseline', outcols)
    # PUMA Substitution
    # here = pathlib.Path(__file__).resolve()
    # pumas = gpd.read_file(
    #     here.parent / "gisdata" / "ipums_pums_2010_simple_t100_area_conus.geojson"
    # )
    # puma_map = pumas[["GISJOIN", "puma_tsv"]].set_index("puma_tsv")["GISJOIN"].to_dict()

    # # County Substitution
    # county_map = (
    #     pd.read_csv(
    #         here.parent / "gisdata" / "spatial_county_lookup_table.csv",
    #         usecols=["long_name", "original_FIP"],
    #     )
    #     .set_index("long_name")["original_FIP"]
    #     .to_dict()
    # )
    # df = df.with_columns(pl.col("in.county").map_dict(county_map))
    # df = df.with_columns(pl.col("in.puma").map_dict(puma_map)) -> puma mapping is incomplete
    # df = df
    # df = df.with_columns(pl.Series(range(len(df))).alias("metadata_index"))
    return df


def get_up_annual(
    file_path, upgrade_name, outcols: List[str]
) -> pl.LazyFrame:
    up_df = read_formatted_metadata_file(file_path, upgrade_name, outcols)
    return up_df
