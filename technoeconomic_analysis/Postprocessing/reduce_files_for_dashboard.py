"""
Get summary of upgrades:
file_name, upgrade_name, Success, Fail, Invalid
"""
import numpy as np
from pathlib import Path
import argparse
from typing import Optional

import pandas as pd


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

def reduce_columns_in_files(csv_dir: Path):
    output_dir = csv_dir.parent / (csv_dir.stem+"__reduced")
    output_dir.mkdir(parents=True, exist_ok=True)

    for file in csv_dir.glob("results_up*"):
        file_name = file.stem.removesuffix(".csv")
        print(f"Reducing {file_name}...")
        df = pd.read_csv(file, compression="infer", low_memory=False, keep_default_na=False)

        cols = get_metric_columns()
        if "results_up00" in file_name:
            cols += get_metadata_columns(df) 

        df[cols].to_csv(output_dir / (file_name+".csv"), index=False)

    print(f"Reduced files output to: {output_dir}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "csv_dir",
        action="store",
        help="Path to results csv directory"
        )

    args = parser.parse_args()
    csv_dir = Path(args.csv_dir)

    reduce_columns_in_files(csv_dir)
