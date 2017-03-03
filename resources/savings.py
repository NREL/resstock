import os
import sys
import pandas as pd
import numpy as np
import time
from joblib import Parallel, delayed
import multiprocessing
import argparse

def main(file):

  df = pd.read_csv(file, index_col=['_id'])
  full = df.copy()
  
  # get upgrades  
  upgrades = [col for col in df.columns if col.endswith('.run_measure')]
    
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
  
  # clean cost column
  df['simulation_output_report.upgrade_cost'] = df['simulation_output_report.upgrade_cost'].str.strip()
  df['simulation_output_report.upgrade_cost'] = df['simulation_output_report.upgrade_cost'].str.replace(',', '')
  df['simulation_output_report.upgrade_cost'] = df['simulation_output_report.upgrade_cost'].astype(float)
  df['simulation_output_report.upgrade_cost'] = df.apply(lambda x: 0.0 if is_reference_case(x, upgrades) else x['simulation_output_report.upgrade_cost'], axis=1)
  
  df = parallelize(df.groupby('build_existing_models.building_id'), deltas, upgrades, enduses)
  
  cols_to_use = [col for col in df.columns if col not in full.columns]
  full = pd.concat([full, df[cols_to_use]], axis=1)
  
  full['upgrade'] = full.apply(lambda x: identify_upgrade(x, upgrades), axis=1)
  
  return df, full
    
def deltas(df, upgrades, enduses):
    
  # reference row for this building_id
  df_reference = df.loc[df[upgrades].sum(axis=1)==0]
  
  # upgrade rows for this building_id
  df_upgrades = df.loc[df[upgrades].sum(axis=1)!=0]
  
  # incremental cost
  df.loc[df_upgrades.index, 'incremental_cost_usd'] = df_upgrades['simulation_output_report.upgrade_cost'].values - df_reference['simulation_output_report.upgrade_cost'].values
  
  # energy savings
  for enduse in enduses:
    df.loc[df_upgrades.index, 'savings_{}'.format(enduse)] = df_reference[enduse].values - df_upgrades[enduse].values

  return df  
    
def parallelize(groups, func, upgrades, enduses):
    list = Parallel(n_jobs=multiprocessing.cpu_count())(delayed(func)(group, upgrades, enduses) for building_id, group in groups)
    return pd.concat(list)
    
def identify_upgrade(row, upgrades):
  for upgrade in upgrades:
    if row[upgrade]:
      return upgrade.replace('.run_measure', '')
  return 'reference'
    
def is_reference_case(x, upgrades):
  upgrades_applied = 0
  for upgrade in upgrades:
    upgrades_applied += x[upgrade]
  if upgrades_applied == 0:
    return True
  return False  
      
if __name__ == '__main__':

  t0 = time.time()
  
  parser = argparse.ArgumentParser()
  parser.add_argument('--file', default= '../analysis_results/resstock_pnw.csv', help='Relative path of the output csv file.')
  args = parser.parse_args()
  file = os.path.abspath(os.path.join(os.path.dirname(__file__), args.file))

  df, full = main(file)
  
  new_file = '{}_savings{}'.format(os.path.splitext(os.path.basename(file))[0], os.path.splitext(os.path.basename(file))[1])
  full.to_csv(os.path.join(os.path.dirname(file), new_file))
  
  print "All done! Completed rows in {0:.2f} seconds on".format(time.time()-t0), time.strftime("%Y-%m-%d %H:%M")
