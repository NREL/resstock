import pandas as pd
from get_major_elec_load_count import get_major_elec_load_count
import pickle
import numpy as np
from numpy import random

model = 41906
#resstock_baseline_file = "test_data/euss1_2018_results_up00_clean__model_41138__tsv_based__predicted_panels_probablistically_assigned.csv"
resstock_baseline_file = f"test_data/panel_run_30k/results_up00__model_{model}__tsv_based__predicted_panels_probablistically_assigned.csv"
df = pd.read_csv(resstock_baseline_file)
model_file = 'breaker_space_model_20240318/breaker_space_model_breaker_min_4_no_outliers.pickle'

df.loc[df["build_existing_model.heating_fuel"] != "Electricity", "has_elec_heating_primary"] = 0
df.loc[df["build_existing_model.heating_fuel"] == "Electricity", "has_elec_heating_primary"] = 1 
df.loc[df["build_existing_model.hvac_cooling_type"] == "None", "has_cooling"] = 0
df.loc[df["build_existing_model.hvac_cooling_type"] != "None", "has_cooling"] = 1
df.loc[df["build_existing_model.water_heater_fuel"] != "Electricity", "has_elec_water_heater"] = 0
df.loc[df["build_existing_model.water_heater_fuel"] == "Electricity", "has_elec_water_heater"] = 1 
df.loc[~df["build_existing_model.clothes_dryer"].isin(['Electric, 80% Usage', 'Electric, 100% Usage','Electric, 120% Usage']), "has_elec_drying"] = 0
df.loc[df["build_existing_model.clothes_dryer"].isin(['Electric, 80% Usage', 'Electric, 100% Usage','Electric, 120% Usage']), "has_elec_drying"] = 1
df.loc[~df["build_existing_model.cooking_range"].isin(['Electric, 80% Usage', 'Electric, 100% Usage','Electric, 120% Usage']), "has_elec_cooking"] = 0
df.loc[df["build_existing_model.cooking_range"].isin(['Electric, 80% Usage', 'Electric, 100% Usage','Electric, 120% Usage']), "has_elec_cooking"] = 1

load_count_list = []
for index, row in df.iterrows():
    load_count = get_major_elec_load_count(row['has_elec_heating_primary'],
                                           row['has_elec_water_heater'],
                                           row['has_elec_drying'],
                                           row['has_elec_cooking'],
                                           row['has_cooling'],
                                           row['build_existing_model.hvac_cooling_type'],
                                           row['build_existing_model.hvac_heating_type'])
    load_count_list.append(load_count)

df['const'] = 1
df['major_elec_load_count'] = load_count_list
if model == 41138:
    df.loc[df['predicted_panel_amp'].isin(['101-199']),"panel_amp_pre_bin_4__101_199"] = 1
    df.loc[~df['predicted_panel_amp'].isin(['101-199']),"panel_amp_pre_bin_4__101_199"] = 0
    df.loc[df['predicted_panel_amp'].isin(['200', '201+']),"panel_amp_pre_bin_4__200_plus"] = 1
    df.loc[~df['predicted_panel_amp'].isin(['200', '201+']),"panel_amp_pre_bin_4__200_plus"] = 0
    df.loc[df['predicted_panel_amp'].isin(['<100', '100']),"panel_amp_pre_bin_4__lt_100"] = 1
    df.loc[~df['predicted_panel_amp'].isin(['<100', '100']),"panel_amp_pre_bin_4__lt_100"] = 0
if model == 41906:
    df.loc[df['predicted_panel_amp'].isin(['101-124', '125', '126-199']),"panel_amp_pre_bin_4__101_199"] = 1
    df.loc[~df['predicted_panel_amp'].isin(['101-124', '125', '126-199']),"panel_amp_pre_bin_4__101_199"] = 0
    df.loc[df['predicted_panel_amp'].isin(['200', '201+']),"panel_amp_pre_bin_4__200_plus"] = 1
    df.loc[~df['predicted_panel_amp'].isin(['200', '201+']),"panel_amp_pre_bin_4__200_plus"] = 0
    df.loc[df['predicted_panel_amp'].isin(['<100', '100']),"panel_amp_pre_bin_4__lt_100"] = 1
    df.loc[~df['predicted_panel_amp'].isin(['<100', '100']),"panel_amp_pre_bin_4__lt_100"] = 0

zinb_data = df[['const',
                 'major_elec_load_count',
                 'panel_amp_pre_bin_4__101_199',
                 'panel_amp_pre_bin_4__200_plus',
                 'panel_amp_pre_bin_4__lt_100']].copy()


with open(model_file, "rb") as f:
    zinb_model = pickle.load(f)

indep_vars =  [x for x in zinb_data.columns if "panel_slots_empty" not in x]

print(zinb_data.info())
indep_vars =  [x for x in zinb_data.columns if "panel_slots_empty" not in x]
print(indep_vars)
print(zinb_model.summary())

predictions = zinb_model.predict(exog=zinb_data[indep_vars],
                                 exog_infl=zinb_data[indep_vars],
                                 which="prob")

predictions["delta"] = (1 - predictions.sum(axis=1)) #24
for index, row in predictions.iterrows():
    column_index = random.randint(32)
    row[column_index] += row["delta"]
    predictions.at[index, column_index] = row[column_index]
predictions = predictions.drop(columns=['delta'])
print(predictions)
slots = [x for x in range(0,32)]
predictions["prediction"] = predictions.apply(lambda x: np.random.choice(slots,1,p=x)[0],axis=1)

df['panel_slots_empty'] = predictions["prediction"]

df = df.drop(columns=['has_elec_heating_primary',
                      'has_cooling',
                      'has_elec_water_heater',
                      'has_elec_drying',
                      'has_elec_cooking',
                      'const',
                      'panel_amp_pre_bin_4__101_199',
                      'panel_amp_pre_bin_4__200_plus',
                      'panel_amp_pre_bin_4__lt_100'])

df.to_csv(f"test_data/panel_run_30k/results_up00__model_{model}__tsv_based__predicted_panels_probablistically_assigned_breaker_space.csv", na_rep='None', index=False)





