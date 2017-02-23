import os
import sys
import pandas as pd
import numpy as np
import time
from joblib import Parallel, delayed
import multiprocessing

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
  df.loc[df_upgrades.index, 'incremental_cost'] = df_upgrades['simulation_output_report.upgrade_cost'].values - df_reference['simulation_output_report.upgrade_cost'].values
  
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
      return upgrade
  return np.nan
    
def is_reference_case(x, upgrades):
  upgrades_applied = 0
  for upgrade in upgrades:
    upgrades_applied += x[upgrade]
  if upgrades_applied == 0:
    return True
  return False
      
def costs(full):

  rates = {}
  rates['elec'] = pd.read_csv('grid_elec.csv', index_col=['nsrdb_gid_new'])
  rates['ng'] = pd.read_csv('grid_ng.csv', index_col=['nsrdb_gid_new'])
  rates['oil'] = pd.read_csv('grid_oil.csv', index_col=['nsrdb_gid_new'])
  rates['prop'] = pd.read_csv('grid_prop.csv', index_col=['nsrdb_gid_new'])
  rates = {k: v[v['TotalSFD'] > 0] for k, v in rates.items()}
  rates = {k: v.rename(columns={'Location': 'state'}) for k, v in rates.items()}
  for k, v in rates.items():
    v['usaf'] = v['usaf'].map(str)

  # average rate in each usaf weighted by totalsfd
  usaf_rates = {}
  usaf_rates = {k: v.groupby('usaf').agg({'wt_mean_rate': lambda x: np.average(x, weights=rates[k].loc[x.index, 'TotalSFD'])}) for k, v in rates.items()}
  
  # average rate in each usaf-state weighted by totalsfd
  usaf_state_rates = {}
  usaf_state_rates = {k: v.groupby(['usaf', 'state']).agg({'wt_mean_rate': lambda x: np.average(x, weights=rates[k].loc[x.index, 'TotalSFD'])}) for k, v in rates.items()}
  
  full['usaf'] = full['building_characteristics_report.location_epw'].apply(lambda x: x.split('_')[-2].split('.')[-1])
  full['state'] = full['building_characteristics_report.location_epw'].apply(lambda x: x.split('_')[1])  
    
  full['utility_cost_savings'] = full.apply(lambda x: calc_utility_cost(x, usaf_rates['elec'].loc[usaf_rates['elec'].index==x['usaf'], 'wt_mean_rate'].values, usaf_rates['ng'].loc[usaf_rates['ng'].index==x['usaf'], 'wt_mean_rate'].values, usaf_rates['oil'].loc[usaf_rates['oil'].index==x['usaf'], 'wt_mean_rate'].values), axis=1)

  df = full.groupby(['usaf', 'state', 'upgrade']).agg({'savings_simulation_output_report.total_site_electricity_k_wh': np.sum, 'savings_simulation_output_report.total_site_natural_gas_therm': np.sum, 'savings_simulation_output_report.total_site_other_fuel_m_btu': np.sum, 'simulation_output_report.weight': np.sum})
  
  usaf_state_rates = {k: df.reset_index().merge(v.reset_index(), on=['usaf', 'state'], how='inner') for k, v in usaf_state_rates.items()} # HERE 726880 has three states
  for k, v in usaf_state_rates.items():
    v = v.set_index(['usaf', 'state', 'upgrade'])
    if k in ['prop']:
      continue
    if k == 'elec':
      v['wt'] = v['savings_simulation_output_report.total_site_electricity_k_wh'] * v['wt_mean_rate'] * v['simulation_output_report.weight']
      v.reset_index()[['state', 'upgrade', 'savings_simulation_output_report.total_site_electricity_k_wh', 'simulation_output_report.weight', 'wt']].groupby(['state', 'upgrade']).sum().reset_index().set_index('upgrade').sort_index().to_csv('state-{}.csv'.format(k))
      v[['savings_simulation_output_report.total_site_electricity_k_wh', 'simulation_output_report.weight', 'wt_mean_rate', 'wt']].reset_index().set_index('upgrade').sort_index().to_csv('usaf-state-{}.csv'.format(k))
    elif k == 'ng':
      v['wt'] = v['savings_simulation_output_report.total_site_natural_gas_therm'] * v['wt_mean_rate'] * v['simulation_output_report.weight']
      v.reset_index()[['state', 'upgrade', 'savings_simulation_output_report.total_site_natural_gas_therm', 'simulation_output_report.weight', 'wt']].groupby(['state', 'upgrade']).sum().reset_index().set_index('upgrade').sort_index().to_csv('state-{}.csv'.format(k))
      v[['savings_simulation_output_report.total_site_natural_gas_therm', 'simulation_output_report.weight', 'wt_mean_rate', 'wt']].reset_index().set_index('upgrade').sort_index().to_csv('usaf-state-{}.csv'.format(k))
    elif k == 'oil':
      v['wt'] = v['savings_simulation_output_report.total_site_other_fuel_m_btu'] * v['wt_mean_rate'] * v['simulation_output_report.weight']
      v.reset_index()[['state', 'upgrade', 'savings_simulation_output_report.total_site_other_fuel_m_btu', 'simulation_output_report.weight', 'wt']].groupby(['state', 'upgrade']).sum().reset_index().set_index('upgrade').sort_index().to_csv('state-{}.csv'.format(k))
      v[['savings_simulation_output_report.total_site_other_fuel_m_btu', 'simulation_output_report.weight', 'wt_mean_rate', 'wt']].reset_index().set_index('upgrade').sort_index().to_csv('usaf-state-{}.csv'.format(k))    

  return full

def calc_utility_cost(row, elec, ng, oil):
  cost = row['savings_simulation_output_report.total_site_electricity_k_wh'] * elec + \
         row['savings_simulation_output_report.total_site_natural_gas_therm'] * ng + \
         row['savings_simulation_output_report.total_site_other_fuel_m_btu'] * oil
  try:
    return cost[0]
  except:
    return np.nan      
      
if __name__ == '__main__':

  t0 = time.time()

  file = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'analysis_results', 'resstock_pnw.csv')

  df, full = main(file)
  # full = costs(full)
  
  # build_exist_models = full[['build_existing_models.building_id', 'building_characteristics_report.location_epw']].drop_duplicates()
  # usafs_models = build_exist_models.groupby('building_characteristics_report.location_epw').count()  
  
  full.to_csv(os.path.basename(file))
  
  print "All done! Completed rows in {0:.2f} seconds on".format(time.time()-t0), time.strftime("%Y-%m-%d %H:%M")
