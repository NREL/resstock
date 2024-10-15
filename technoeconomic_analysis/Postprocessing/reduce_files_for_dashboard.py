"""
Reduce columns in baseline and upgrade files for Tableau viz
created 06-13-2024
revised: 10/14/24
"""
import numpy as np
from pathlib import Path
import argparse
from typing import Optional
import sys

import pandas as pd


def get_upgrade_cost_by_category_columns(df):
    cols = [x for x in df.columns if 
        "upgrade_cost_" in x
    ]
    return cols

def get_metadata_columns(df):
    cols = [x for x in df.columns if 
        ("build_existing_model." in x) and ("simulation_control" not in x) and ("utility_bill" not in x)
    ]
    return cols

def get_metric_columns():
    return [
        "building_id",
        "apply_upgrade.upgrade_name",
        "report_simulation_output.emissions_co_2_e_lrmer_low_re_cost_25_electricity_total_lb",
        "report_simulation_output.emissions_co_2_e_lrmer_low_re_cost_25_net_lb",
        "report_simulation_output.emissions_co_2_e_lrmer_low_re_cost_25_total_lb",
        "report_simulation_output.energy_use_net_m_btu",
        "report_simulation_output.energy_use_total_m_btu",
        "report_simulation_output.fuel_use_electricity_net_m_btu",
        "report_simulation_output.fuel_use_electricity_total_m_btu",
        "report_simulation_output.hvac_capacity_cooling_btu_h",
        "report_simulation_output.hvac_capacity_heat_pump_backup_btu_h",
        "report_simulation_output.hvac_capacity_heating_btu_h",
        "report_simulation_output.load_hot_water_delivered_m_btu",
        "report_simulation_output.load_hot_water_tank_losses_m_btu",
        "report_simulation_output.unmet_hours_cooling_hr",
        "report_simulation_output.unmet_hours_heating_hr",
        "report_simulation_output.unmet_loads_hot_water_shower_energy_j",
        "report_simulation_output.unmet_loads_hot_water_shower_time_hr",
        "report_simulation_output.unmet_loads_hot_water_shower_unmet_time_hr",
        "upgrade_costs.size_cooling_system_primary_k_btu_h",
        "upgrade_costs.size_heat_pump_backup_primary_k_btu_h",
        "upgrade_costs.size_heating_system_primary_k_btu_h",
        "upgrade_costs.size_heating_system_secondary_k_btu_h",
        "upgrade_costs.size_water_heater_gal",
        "upgrade_costs.upgrade_cost_usd",
        "report_utility_bills.utility_rates_fixed_variable_electricity_total_usd",
        "report_utility_bills.utility_rates_fixed_variable_total_usd"
    ]

def reduce_columns_in_files(file_dir: Path, file_type: str = ".csv"):
    output_dir = file_dir.parent / (file_dir.stem+"__reduced")
    output_dir.mkdir(parents=True, exist_ok=True)

    files_to_process = sorted(file_dir.glob("results_up*"))
    baseline_file = [x for x in files_to_process if "results_up00" in str(x)]
    if len(baseline_file) == 1:
        files_to_process = baseline_file + [x for x in files_to_process if x not in baseline_file]
    elif len(baseline_file) == 0:
        raise ValueError("No baseline file found.")
    else:
        raise ValueError(f"More than one baseline found, expecting only one.\n{baseline_file}")

    for file in files_to_process:
        file_name = file.stem.removesuffix(file_type)
        print(f"Reducing {file_name}...")
        if file_type == ".csv":
            df = pd.read_csv(file, compression="infer", low_memory=False, keep_default_na=False)
        elif file_type == ".parquet":
            df = pd.read_parquet(file)
        else:
            raise ValueError(f"Unsupported {file_type}. Use either .csv (default) or .parquet")

        cols = get_metric_columns()
        if "results_up00" in file_name:
            cols += get_metadata_columns(df) 
            col = "build_existing_model.county_fips"
            df[col] = df["build_existing_model.county_and_puma"].str.split(",").str[0]
            df[col] = df[col].str[1:3] + df[col].str[4:7]
            cols.append(col)

            # remove unsuccessful sims and vacant units
            cond = df["completed_status"]=="Success"
            cond2 = df["build_existing_model.vacancy_status"] != "Vacant"
            df = df.loc[cond&cond2, cols]
            bl_bldgs = df["building_id"]
            assert len(bl_bldgs) > 0, "Occupied bldgs is empty!"
        else:
            cols2 = get_upgrade_cost_by_category_columns(df)
            cols += [x for x in cols2 if x not in cols]
            # remove unsuccessful sims and vacant units
            cond3 = df["completed_status"]=="Success"
            cond4 = df["building_id"].isin(bl_bldgs)
            df = df.loc[cond3&cond4, cols]

        # QC
        print(df.shape)
        if len(df) == 0:
            print("Filtering has led to 0 rows.")
            sys.exit(1)

        if file_type == "csv":
            df.to_csv(output_dir / (file_name+".csv"), index=False)
        elif file_type == ".parquet":
            df.reset_index(drop=True).to_parquet(output_dir / (file_name+".parquet"))

    print(f"Reduced files output to: {output_dir}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "file_dir",
        action="store",
        help="Path to results csv directory"
        )
    parser.add_argument(
        "file_type",
        action="store",
        default=None,
        nargs="?",
        help="Result file type to collect from directory. Default to '.csv'."
        )

    args = parser.parse_args()
    file_dir = Path(args.file_dir)
    file_type = args.file_type

    reduce_columns_in_files(file_dir, file_type=file_type)
