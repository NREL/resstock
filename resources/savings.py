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
        if not col.startswith('BuildingCharacteristicsReport'):
          continue
        if ref[col] != row[col]:
          upgrades[upgrade] = '{}.run_measure'.format(col.replace('BuildingCharacteristicsReport.', ''))
        
  df = df.rename(columns=upgrades)

  return df
  
def main(dir):

  for item in os.listdir(dir):
  
    if not item.endswith('.zip'):
      continue

    print os.path.join(dir, item)
    
    folder_zf = zipfile.ZipFile(os.path.join(dir, item))
    
    for datapoint in folder_zf.namelist():
    
      if not datapoint.endswith('results.csv'):
        continue
      
      folder_zf.extract(datapoint, dir)

      df = pd.read_csv(os.path.join(dir, datapoint), index_col=['_id'])

      df = df.dropna(axis=1, how='all')
      df = assign_upgrades(df)
      
      upgrades = [col for col in df.columns if col.endswith('.run_measure')]
      
      # summarize the upgrades applied
      df['upgrade'] = df.apply(lambda x: identify_upgrade(x, upgrades), axis=1)
      
      # remove NA (upgrade not applicable) rows
      df = df[~((pd.isnull(df['SimulationOutputReport.upgrade_cost_usd'])) & (df['upgrade'] != 'reference'))]

      # process only applicable columns
      full = df.copy()
        
      # get enduses  
      enduses = [col for col in df.columns if 'SimulationOutputReport' in col]
      enduses = [col for col in enduses if not '.weight' in col]
      enduses = [col for col in enduses if not '.upgrade_cost_usd' in col]
      enduses = [col for col in enduses if not '_not_met' in col]
      enduses = [col for col in enduses if not '_capacity_w' in col]
      
      # remove unused columns  
      cols = [col for col in df.columns if col.startswith('BuildingCharacteristicsReport.')]
      cols += ['name', 'run_start_time', 'run_end_time', 'status', 'status_message']
      cols = [col for col in cols if not 'location_epw' in col]
      for col in cols:
        try:
          df = df.drop(col, 1)
        except:
          print ' ... did not remove {}'.format(col)  
      
      # clean cost column
      df['SimulationOutputReport.upgrade_cost_usd'] = df.apply(lambda x: 0.0 if is_reference_case(x, upgrades) else x['SimulationOutputReport.upgrade_cost_usd'], axis=1)
      
      df = parallelize(df.groupby('build_existing_model.building_id'), deltas, upgrades, enduses)
      
      cols_to_use = [col for col in df.columns if col not in full.columns]
      full = pd.concat([full, df[cols_to_use]], axis=1)
      
      return os.path.basename(datapoint), full
    
def deltas(df, upgrades, enduses):
    
  # reference row for this building_id
  df_reference = df.loc[df[upgrades].sum(axis=1)==0]
  
  # upgrade rows for this building_id
  df_upgrades = df.loc[df[upgrades].sum(axis=1)!=0]
  
  # incremental cost
  df.loc[df_upgrades.index, 'incremental_cost_usd'] = df_upgrades['SimulationOutputReport.upgrade_cost_usd'].values - df_reference['SimulationOutputReport.upgrade_cost_usd'].values
  
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
  parser.add_argument('--directory', default='../analysis_results/data_points', help='Relative path containing the data_point.zip files.')
  args = parser.parse_args()

  datapoint, full = main(args.directory)
  
  print datapoint
  
  new_file = '{}_savings{}'.format(os.path.splitext(os.path.basename(datapoint))[0], os.path.splitext(os.path.basename(datapoint))[1])
  full.index.name = '_id'
  full.to_csv(os.path.join(args.directory, new_file))
  
  print "All done! Completed rows in {0:.2f} seconds on".format(time.time()-t0), time.strftime("%Y-%m-%d %H:%M")
