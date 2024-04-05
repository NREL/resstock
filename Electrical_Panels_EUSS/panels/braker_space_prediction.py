import pandas as pd
from get_major_elec_load_count import get_major_elec_load_count
import pickle

resstock_baseline_file = "test_data/euss1_2018_results_up00_clean__model_41138__tsv_based__predicted_panels_probablistically_assigned.csv"
df = pd.read_csv(resstock_baseline_file)
df = df.head(841)
model_file = 'breaker_space_model_20240318/breaker_space_model_breaker_min_4_no_outliers.pickle'

df.loc[df["build_existing_model.hvac_heating_type"] == "None", "has_elec_heating_primary"] = 0
df.loc[df["build_existing_model.hvac_heating_type"] != "None", "has_elec_heating_primary"] = 1
df.loc[df["build_existing_model.hvac_cooling_type"] == "None", "has_cooling"] = 0
df.loc[df["build_existing_model.hvac_cooling_type"] != "None", "has_cooling"] = 1
df["has_elec_water_heater"] = 1 
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
df.loc[df['predicted_panel_amp'].isin(['101-199']),"panel_amp_pre_bin_4__101_199"] = 1
df.loc[~df['predicted_panel_amp'].isin(['101-199']),"panel_amp_pre_bin_4__101_199"] = 0
df.loc[df['predicted_panel_amp'].isin(['200', '201+']),"panel_amp_pre_bin_4__200_plus"] = 1
df.loc[~df['predicted_panel_amp'].isin(['200', '201+']),"panel_amp_pre_bin_4__200_plus"] = 0
df.loc[df['predicted_panel_amp'].isin(['<100', '100']),"panel_amp_pre_bin_4__lt_100"] = 1
df.loc[~df['predicted_panel_amp'].isin(['<100', '100']),"panel_amp_pre_bin_4__lt_100"] = 0

df_breaker = df[['const',
                 'major_elec_load_count',
                 'panel_amp_pre_bin_4__101_199',
                 'panel_amp_pre_bin_4__200_plus',
                 'panel_amp_pre_bin_4__lt_100']].copy()

model=pickle.load(open(model_file,'rb'))
predictions=model.predict(df_breaker)

df['panel_slots_empty'] = predictions
df = df.drop(columns=['has_elec_heating_primary',
                      'has_cooling',
                      'has_elec_water_heater',
                      'has_elec_drying',
                      'has_elec_cooking',
                      'const',
                      'panel_amp_pre_bin_4__101_199',
                      'panel_amp_pre_bin_4__200_plus',
                      'panel_amp_pre_bin_4__lt_100'])

df.to_csv('test_data/euss1_2018_results_up00_clean__model_41138__tsv_based__predicted_panels_probablistically_assigned_braker_space.csv')





