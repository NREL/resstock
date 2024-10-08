import pandas as pd
from get_major_elec_load_count_ev_pv import get_major_elec_load_count_w_ev_pv
import pickle
import numpy as np
from numpy import random

model = '7bins'
resstock_baseline_file = f"test_data/full_run/data_cleaning_results_up00_550k_0820.csv"
resstock_panel_size = f"test_data/full_run/panel_capacity/panel_result__model_{model}__tsv_based__predicted_panels_probablistically_assigned.csv"
df = pd.read_csv(resstock_baseline_file)
df_panel_size = pd.read_csv(resstock_panel_size)

df['predicted_panel_amp_bin'] = df_panel_size['predicted_panel_amp_bin']

df.loc[df["build_existing_model.heating_fuel"] != "Electricity", "has_elec_heating_primary"] = 0
df.loc[df["build_existing_model.heating_fuel"] == "Electricity", "has_elec_heating_primary"] = 1 
df.loc[df["build_existing_model.hvac_cooling_type"] == "None", "has_cooling"] = 0
df.loc[df["build_existing_model.hvac_cooling_type"] != "None", "has_cooling"] = 1
df.loc[df["build_existing_model.water_heater_fuel"] != "Electricity", "has_elec_water_heater"] = 0
df.loc[df["build_existing_model.water_heater_fuel"] == "Electricity", "has_elec_water_heater"] = 1 
df.loc[~df["build_existing_model.clothes_dryer"].isin(['Electric']), "has_elec_drying"] = 0
df.loc[df["build_existing_model.clothes_dryer"].isin(['Electric']), "has_elec_drying"] = 1
df.loc[~df["build_existing_model.cooking_range"].isin(['Electric Resistance', 'Electric Induction']), "has_elec_cooking"] = 0
df.loc[df["build_existing_model.cooking_range"].isin(['Electric Resistance','Electric Induction']), "has_elec_cooking"] = 1
df["has_ev_charging"] = 0

df.loc[df["build_existing_model.misc_hot_tub_spa"] != "Electricity", "has_elec_hot_tub_spa"] = 0
df.loc[df["build_existing_model.misc_hot_tub_spa"] == "Electricity", "has_elec_hot_tub_spa"] = 1
df.loc[df["build_existing_model.misc_pool_heater"] != "Electricity", "has_elec_pool_heater"] = 0
df.loc[df["build_existing_model.misc_pool_heater"] == "Electricity", "has_elec_pool_heater"] = 1
df.loc[df["build_existing_model.misc_pool_pump"] != "1.0 HP Pump", "has_elec_pool_pump"] = 0
df.loc[df["build_existing_model.misc_pool_pump"] == "1.0 HP Pump", "has_elec_pool_pump"] = 1
df.loc[df["build_existing_model.misc_well_pump"] != "Typical Efficiency", "has_elec_well_pump"] = 0
df.loc[df["build_existing_model.misc_well_pump"] == "Typical Efficiency", "has_elec_well_pump"] = 1

load_count_list = []
for index, row in df.iterrows():
    load_count = get_major_elec_load_count_w_ev_pv(row['has_elec_heating_primary'],
                                           row['has_elec_water_heater'],
                                           row['has_elec_drying'],
                                           row['has_elec_cooking'],
                                           row['has_cooling'],
                                           row['has_ev_charging'],
                                           row['build_existing_model.has_pv'],
                                           row['has_elec_hot_tub_spa'],
                                           row['has_elec_pool_heater'],
                                           row['has_elec_pool_pump'],
                                           row['has_elec_well_pump'])
    load_count_list.append(load_count)

df['major_elec_load_count_w_ev_pv'] = load_count_list
df.to_csv(f"test_data/full_run/panel_capacity/panel_result__model_{model}__tsv_based__predicted_panels_probablistically_assigned_major_ele_load.csv", na_rep='None', index=False)






