import os
import pandas as pd
import numpy as np
import plotly
import plotly.express as px

def read_csv(csv_file_path, **kwargs) -> pd.DataFrame:
    default_na_values = pd._libs.parsers.STR_NA_VALUES
    df = pd.read_csv(csv_file_path, na_values=list(default_na_values - {'None'}), keep_default_na=False, **kwargs)
    return df

thisdir = os.path.abspath(os.path.dirname(__file__))
df = read_csv(os.path.join(thisdir, 'national_baseline/results-Baseline.csv'))

# End Use
cols = ['report_simulation_output.end_use_electricity_heating_fans_pumps_m_btu',
        'report_simulation_output.end_use_electricity_refrigerator_m_btu',
        'report_simulation_output.end_use_natural_gas_heating_m_btu',
        'report_simulation_output.end_use_natural_gas_hot_water_m_btu']
df2 = pd.melt(df, id_vars=['build_existing_model.geometry_height_above_grade'], value_vars=cols)

fig = px.scatter(df2, x='build_existing_model.geometry_height_above_grade', y='value', color='variable')
fig.update_layout(title_text='End Use')
plotly.offline.plot(fig, filename=os.path.join(thisdir, 'end-use.html'), auto_open=False)

# Fuel Use
cols = ['report_simulation_output.fuel_use_electricity_total_m_btu',
        'report_simulation_output.fuel_use_natural_gas_total_m_btu']
df2 = pd.melt(df, id_vars=['build_existing_model.geometry_height_above_grade'], value_vars=cols)

fig = px.scatter(df2, x='build_existing_model.geometry_height_above_grade', y='value', color='variable')
fig.update_layout(title_text='Fuel Use')
plotly.offline.plot(fig, filename=os.path.join(thisdir, 'fuel-use.html'), auto_open=False)

# Load
cols = ['report_simulation_output.hvac_design_load_cooling_latent_infiltration_btu_h',
        'report_simulation_output.hvac_design_load_cooling_latent_total_btu_h',
        'report_simulation_output.hvac_design_load_cooling_sensible_infiltration_btu_h',
        'report_simulation_output.hvac_design_load_heating_infiltration_btu_h',
        'report_simulation_output.load_heating_delivered_m_btu',
        'report_simulation_output.load_hot_water_delivered_m_btu',
        'report_simulation_output.peak_load_heating_delivered_k_btu_hr']
df2 = pd.melt(df, id_vars=['build_existing_model.geometry_height_above_grade'], value_vars=cols)

fig = px.scatter(df2, x='build_existing_model.geometry_height_above_grade', y='value', color='variable')
fig.update_layout(title_text='Load')
plotly.offline.plot(fig, filename=os.path.join(thisdir, 'load.html'), auto_open=False)