import os
import sys
import pandas as pd
import numpy as np

def main(file):

  df = pd.read_csv(file, index_col=['_id'])
  full = df.copy()
  
  # get upgrades  
  upgrades = [col for col in df.columns if 'upgrade' in col]
  upgrades = [col for col in upgrades if not 'simulation_output_report' in col]
  
  # get enduses  
  enduses = [col for col in df.columns if 'simulation_output_report' in col]
  enduses = [col for col in enduses if not '.weight' in col]
  enduses = [col for col in enduses if not '.upgrade_cost' in col]
  enduses = [col for col in enduses if not '_not_met' in col]
  enduses = [col for col in enduses if not '_capacity_w' in col]
  
  # remove unused columns  
  cols = [col for col in df.columns if col.startswith('building_characteristics_report.')]
  cols += ['name', 'run_start_time', 'run_end_time', 'status', 'status_message', 'build_existing_models_energyplus.always_run']
  cols = [col for col in cols if not 'location_epw' in col]
  for col in cols:
    try:
      df = df.drop(col, 1)
    except:
      print ' ... did not remove {}'.format(col)  
  
  # clean columns  
  df['simulation_output_report.upgrade_cost'] = df['simulation_output_report.upgrade_cost'].str.strip()
  df['simulation_output_report.upgrade_cost'] = df['simulation_output_report.upgrade_cost'].str.replace('$', '')
  df['simulation_output_report.upgrade_cost'] = df['simulation_output_report.upgrade_cost'].str.replace(',', '')
  df['simulation_output_report.upgrade_cost'] = df['simulation_output_report.upgrade_cost'].astype(float)
  df['simulation_output_report.upgrade_cost'] = df.apply(lambda x: 0.0 if is_reference_case(x, upgrades) else x['simulation_output_report.upgrade_cost'], axis=1)
      
  total_stock = df['simulation_output_report.weight'].sum()
  
  for building_id, group in df.groupby('build_existing_models.building_id'):
    
    # reference
    df_reference = get_reference_rows(group, upgrades)
    
    # upgrades
    df_upgrades = get_upgrade_rows(group, upgrades)
    
    # incremental cost
    full.loc[df_upgrades.index, 'incremental_cost'] = df_upgrades['simulation_output_report.upgrade_cost'].values - df_reference['simulation_output_report.upgrade_cost'].values
    
    # energy savings
    for enduse in enduses:
      full.loc[df_upgrades.index, 'savings_{}'.format(enduse)] = df_reference[enduse].values - df_upgrades[enduse].values
    
  return full
    
def is_reference_case(x, upgrades):
  upgrades_applied = 0
  for upgrade in upgrades:
    upgrades_applied += x[upgrade]
  if upgrades_applied == 0:
    return True
  return False
  
def get_reference_rows(df, upgrades):
  return df.loc[df[upgrades].sum(axis=1)==0]
  
def get_upgrade_rows(df, upgrades):
  return df.loc[df[upgrades].sum(axis=1)!=0]
      
if __name__ == '__main__':

  file = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'analysis_results', 'resstock_pnw.csv')

  df = main(file)  
  
  build_exist_models = df[['build_existing_models.building_id', 'building_characteristics_report.location_epw']].drop_duplicates()
  usafs_models = build_exist_models.groupby('building_characteristics_report.location_epw').count()
  
  df.to_csv(os.path.basename(file))
