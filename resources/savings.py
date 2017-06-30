import os
import sys
import pandas as pd
import numpy as np
import time
from joblib import Parallel, delayed
import multiprocessing
import argparse
import zipfile

def assign_upgrades(df):

  upgrades = {}
  for name, group in df.groupby('build_existing_model.building_id'):    
    
    for ix, row in group.iterrows():
    
      ref_count = 0
      for col in group.columns:
        if not col.endswith('.run_measure'):
          continue
        ref_count += row[col]
      
      if ref_count == 0:
        ref = row
        
    for ix, row in group.iterrows():
    
      ref_count = 0
      for col in group.columns:
        if not col.endswith('.run_measure'):
          continue
        ref_count += row[col]
      
      if ref_count == 0:
        continue
        
      for col in group.columns:
        if not col.endswith('.run_measure'):
          continue
          
        if row[col] == 1:
          upgrade = col
          break
   
      for col in group.columns:      
        if not col.startswith('building_characteristics_report'):
          continue
        if ref[col] != row[col]:
          upgrades[upgrade] = '{}.run_measure'.format(col.replace('building_characteristics_report.', ''))
        
  if all(x==upgrades.values()[0] for x in upgrades.values()):
    for k, v in upgrades.items():
      upgrades[k] = k

  df = df.rename(columns=upgrades)

  return df
  
def main(zip_file):
    
  dir = os.path.dirname(zip_file)
    
  folder_zf = zipfile.ZipFile(zip_file)
  
  for item in folder_zf.namelist():
  
    if not item.endswith('results.csv'):
      continue
    
    folder_zf.extract(item, dir)

    df = pd.read_csv(os.path.join(dir, item), index_col=['_id'])

    df = df.dropna(axis=1, how='all')
    df = assign_upgrades(df)
    
    upgrades = [col for col in df.columns if col.endswith('.run_measure')]
    
    # summarize the upgrades applied
    df['upgrade'] = df.apply(lambda x: identify_upgrade(x, upgrades), axis=1)
    
    # remove NA (upgrade not applicable) rows
    df = df[~((pd.isnull(df['simulation_output_report.upgrade_cost_usd'])) & (df['upgrade'] != 'reference'))]

    # process only applicable columns
    full = df.copy()
      
    # get enduses  
    enduses = [col for col in df.columns if 'simulation_output_report' in col]
    enduses = [col for col in enduses if not '.weight' in col]
    enduses = [col for col in enduses if not '.upgrade_cost_usd' in col]
    enduses = [col for col in enduses if not '_not_met' in col]
    enduses = [col for col in enduses if not '_capacity_w' in col]
    
    # remove unused columns  
    cols = [col for col in df.columns if col.startswith('building_characteristics_report.')]
    cols += ['name', 'run_start_time', 'run_end_time', 'status', 'status_message']
    cols = [col for col in cols if not 'location_epw' in col]
    for col in cols:
      try:
        df = df.drop(col, 1)
      except:
        print ' ... did not remove {}'.format(col)  
    
    # clean cost column
    df['simulation_output_report.upgrade_cost_usd'] = df.apply(lambda x: 0.0 if is_reference_case(x, upgrades) else x['simulation_output_report.upgrade_cost_usd'], axis=1)
    
    df = parallelize(df.groupby('build_existing_model.building_id'), deltas, upgrades, enduses)
    
    cols_to_use = [col for col in df.columns if col not in full.columns]
    full = pd.concat([full, df[cols_to_use]], axis=1)
    
    return os.path.basename(item), full
    
def deltas(df, upgrades, enduses):
    
  # reference row for this building_id
  df_reference = df.loc[df[upgrades].sum(axis=1)==0]
  
  # upgrade rows for this building_id
  df_upgrades = df.loc[df[upgrades].sum(axis=1)!=0]
  
  # incremental cost
  df.loc[df_upgrades.index, 'incremental_cost_usd'] = df_upgrades['simulation_output_report.upgrade_cost_usd'].values - df_reference['simulation_output_report.upgrade_cost_usd'].values
  
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
  parser.add_argument('--zip_file', default='../analysis_results/data_points/resstock_pnw_localResults.zip', help='Relative path containing the data_point.zip files.')
  args = parser.parse_args()

  item, full = main(args.zip_file)
  
  file, ext = os.path.splitext(os.path.basename(item))
  new_file = '{}_savings{}'.format(file, ext)
  full.index.name = '_id'
  full.to_csv(os.path.join(os.path.dirname(args.zip_file), new_file))
  
  print "All done! Completed rows in {0:.2f} seconds on".format(time.time()-t0), time.strftime("%Y-%m-%d %H:%M")
