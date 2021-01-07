import os
import time
import argparse
import pandas as pd
import numpy as np
import inspect
import pyproj
from joblib import Parallel, delayed
import multiprocessing
from scipy.spatial import cKDTree
from resources.util import StateAbbrev
from resources.util import ReportableDomain
from resources.util import CostEffectiveness
from resources.util import UtilityBillCalculations
import warnings
warnings.filterwarnings('ignore')

def add_columns(df, cols):
  """
  Call the methods in the ExtraColumns class.

  Parameters:
    cols (list): Array of additional columns to attach to dataframe.

  Returns:
    new_df (dataframe): A pandas dataframe with new column(s).

  """
  extra_columns = ExtraColumns()
  new_df = df.copy()
  for col in cols:
    df = new_df.copy()
    len_df_columns = len(df.columns)
    new_df = getattr(extra_columns, col)(df)
    if len(new_df.columns) != len_df_columns:
      print 'Adding {} ...'.format(col)
  return new_df

class ExtraColumns:
  """
  Methods for calculating and attaching additional columns onto the results csv file.

  Parameters:
    df (dataframe): A pandas dataframe originally parsed from the results csv file.

  Returns:
    df (dataframe): A pandas dataframe with the attached additional column(s).

  """
  def reportable_domain(self, df):
    state_to_reportabledomain = ReportableDomain.statename_to_reportabledomain()
    state_to_reportabledomain.update(ReportableDomain.stateabbrev_to_reportabledomain())
    if not 'build_existing_model.reportable_domain' in df.columns:
      df['build_existing_model.reportable_domain'] = df['build_existing_model.state'].apply(lambda x: np.nan if pd.isnull(x) else str(state_to_reportabledomain[x]))
    return df

  def egrid_subregions(self, df):
    if not 'egrid' in ['egrid' for col in df.columns if 'egrid' in col]:
      egrid = pd.read_csv(os.path.join(os.path.dirname(__file__), 'resources/egrid.csv'), index_col='grid_gid')
      egrid.rename(columns={'egrid_subregion': 'build_existing_model.egrid_subregion'}, inplace=True)

      latlonalt_proj = pyproj.Proj(proj='latlong', ellps='WGS84', datum='WGS84')
      ecef_proj = pyproj.Proj(proj='geocent', ellps='WGS84', datum='WGS84')
      egrid['x'], egrid['y'], egrid['z'] = pyproj.transform(
        latlonalt_proj,
        ecef_proj,
        egrid['nsrdb_cent_long'].values,
        egrid['nsrdb_cent_lat'].values,
        np.zeros(egrid.shape[0])
      )

      egrid_kdtree = cKDTree(egrid[['x', 'y', 'z']].values)

      xyz = pyproj.transform(
        latlonalt_proj,
        ecef_proj,
        df['build_existing_model.location_longitude'].values,
        df['build_existing_model.location_latitude'].values,
        np.zeros(df.shape[0])
      )
      distances, indexes = egrid_kdtree.query(np.array(xyz).T)
      found_gid = np.isfinite(distances)
      df.loc[found_gid, 'build_existing_model.grid_gid'] = egrid.iloc[indexes[found_gid]].index.values
      del egrid['x']
      del egrid['y']
      del egrid['z']

      df = pd.merge(df, egrid, left_on='build_existing_model.grid_gid', right_index=True, how='left')

      del df['state_name']
      del df['county_name']
      del df['nsrdb_gid_old']
      del df['nsrdb_gid_new']
      del df['nsrdb_cent_lat']
      del df['nsrdb_cent_long']
    return df
    
  def source_energy(self, df):
    if not 'simulation_output_report.total_source_energy_mbtu' in df.columns:
      total_source_electricity_mbtu = df['simulation_output_report.total_site_electricity_kwh'] * df['Electricity Primary Conversion Factor'] * (3412.0 / 1000000.0)
      total_source_natural_gas_mbtu = df['simulation_output_report.total_site_natural_gas_therm'] * df['Natural Gas Primary Conversion Factor'] * (10000.0 / 1e6)
      if 'simulation_output_report.total_site_fuel_oil_mbtu' in df.columns and 'simulation_output_report.total_site_propane_mbtu' in df.columns:
        total_source_fuel_oil_mbtu = df['simulation_output_report.total_site_fuel_oil_mbtu'] * df['Other Fuel Primary Conversion Factor']
        total_source_propane_mbtu = df['simulation_output_report.total_site_propane_mbtu'] * df['Other Fuel Primary Conversion Factor']
        total_source_other_fuel_mbtu = total_source_fuel_oil_mbtu + total_source_propane_mbtu
      elif 'simulation_output_report.total_site_other_fuel_mbtu' in df.columns: # for backwards compatibility
        total_source_other_fuel_mbtu = df['simulation_output_report.total_site_other_fuel_mbtu'] * df['Other Fuel Primary Conversion Factor']
      df['simulation_output_report.total_source_energy_mbtu'] = total_source_electricity_mbtu + total_source_natural_gas_mbtu + total_source_other_fuel_mbtu
    return df
  
  def total_utility_bill(self, df):
    if 'utility_bill_calculations' in ['utility_bill_calculations' for col in df.columns if 'utility_bill_calculations' in col]:
      df['utility_bill_calculations.electricity'] = df['utility_bill_calculations.electricity'].fillna(0)
      df['utility_bill_calculations.natural_gas'] = df['utility_bill_calculations.natural_gas'].fillna(0)
      df['utility_bill_calculations.fuel_oil'] = df['utility_bill_calculations.fuel_oil'].fillna(0)
      df['utility_bill_calculations.propane'] = df['utility_bill_calculations.propane'].fillna(0)
    else: # calculated with state-level rates
      df = UtilityBillCalculations.state_level_rates(df)
    df['utility_bill_calculations.total_bill'] = df[['utility_bill_calculations.electricity', 'utility_bill_calculations.natural_gas', 'utility_bill_calculations.fuel_oil', 'utility_bill_calculations.propane']].sum(axis=1)
    return df
    
  def simple_payback(self, df):
    if not 'savings_simulation_output_report.simple_payback' in df.columns:
      if 'savings_utility_bill_calculations.total_bill' in df.columns:
        df['savings_simulation_output_report.simple_payback'] = df.apply(lambda x: CostEffectiveness.simple_payback(x['simulation_output_report.upgrade_cost_usd'], x['savings_utility_bill_calculations.total_bill']), axis=1)
    return df
  
  def net_present_value(self, df):
    if not 'savings_simulation_output_report.net_present_value' in df.columns:
      if 'savings_utility_bill_calculations.total_bill' in df.columns:
        discount_rate = 0.03
        analysis_period = 30
        npvs = []
        for i in ['01', '02', '03', '04', '05', '06', '07', '08', '09', '10']:
          col = 'simulation_output_report.upgrade_option_{}'.format(i)
          df['savings_simulation_output_report.upgrade_option_{}_npv'.format(i)] = df.apply(lambda x: CostEffectiveness.net_present_value(discount_rate, analysis_period, x['{}_lifetime_yrs'.format(col)], x['{}_cost_usd'.format(col)], x['savings_utility_bill_calculations.total_bill'], 0, '1'), axis=1)
          npvs.append('savings_simulation_output_report.upgrade_option_{}_npv'.format(i))
        df['savings_simulation_output_report.net_present_value'] = df[npvs].sum(axis=1)
        for i in ['01', '02', '03', '04', '05', '06', '07', '08', '09', '10']:
          del df['savings_simulation_output_report.upgrade_option_{}_npv'.format(i)]
    return df

  def savings_investment_ratio(self, df):
    if not 'savings_simulation_output_report.savings_investment_ratio' in df.columns:
      if 'savings_utility_bill_calculations.total_bill' in df.columns:
        import json
        with open(os.path.join(os.path.dirname(__file__), 'resources/projected_fuel_price_indices.json')) as f:
          fuel_price_indices = json.load(f)
        discount_rate = 0.03
        analysis_period = 30
        sirs = []
        for i in ['01', '02', '03', '04', '05', '06', '07', '08', '09', '10']:
          col = 'simulation_output_report.upgrade_option_{}'.format(i)
          df['savings_simulation_output_report.upgrade_option_{}_sir'.format(i)] = df.apply(lambda x: CostEffectiveness.savings_investment_ratio(discount_rate, analysis_period, x['{}_lifetime_yrs'.format(col)], x['{}_cost_usd'.format(col)], x['build_existing_model.state'], fuel_price_indices, x['savings_utility_bill_calculations.electricity'], x['savings_utility_bill_calculations.natural_gas'], x['savings_utility_bill_calculations.fuel_oil'], x['savings_utility_bill_calculations.propane'], 0, '1'), axis=1)
          sirs.append('savings_simulation_output_report.upgrade_option_{}_sir'.format(i))
        df['savings_simulation_output_report.savings_investment_ratio'] = df[sirs].sum(axis=1)
        for i in ['01', '02', '03', '04', '05', '06', '07', '08', '09', '10']:
          del df['savings_simulation_output_report.upgrade_option_{}_sir'.format(i)]
    return df

def preprocess(df):
  """
  Method for preprocessing the results csv file: field filling, subsetting, etc.

  Parameters:
    df (dataframe): The original results csv file.

  Returns:
    df (dataframe): The filled, subsetted, etc. pandas dataframe.

  """
  # if there are no upgrade columns, add them with null values  
  for col in ['simulation_output_report.upgrade_name', 'simulation_output_report.upgrade_cost_usd']:
    if not col in df.columns:
      df[col] = np.nan

  # assume that no upgrade means base building
  df['simulation_output_report.upgrade_name'] = df['simulation_output_report.upgrade_name'].fillna('BASE')
  df['simulation_output_report.upgrade_cost_usd'] = df['simulation_output_report.upgrade_cost_usd'].fillna(0)

  # if there is a status_message column, only retain the "completed normal" rows
  
  if 'status_message' in df.columns:
    df = df[df['status_message']=='completed normal']
  
  # remove any build_existing_model columns that have all null values
  for col in [col for col in df.columns if 'build_existing_model' in col]:
    if pd.isnull(df[col]).all():
      del df[col]

  # fill building characteristics columns for upgrade rows
  print 'Filling in characteristics for upgrade rows...'
  df = df.reset_index()
  df = df.set_index('build_existing_model.building_id')
  if 'status_message' in df.columns:
    base = df[(df['simulation_output_report.upgrade_name']=='BASE') & (df['status_message']=='completed normal')]
  else:
    base = df[df['simulation_output_report.upgrade_name']=='BASE']
  base = base[[col for col in df.columns if 'build_existing_model' in col]]
  upgrades = df[[col for col in df.columns if not 'build_existing_model' in col]]
  df = base.join(upgrades)
  df = df.reset_index()
  df = df.set_index('_id')

  return df

def get_enduses(df):
  """
  Retrieve the list of enduses to calculate savings for.

  Parameters:
    df (dataframe): A pandas dataframe created from the results csv file.
  
  Returns:
    enduses (list): All of the dataframe columns for which we want to calculate savings.

  """
  enduses = [col for col in df.columns if 'simulation_output_report' in col or 'utility_bill_calculations' in col]
  enduses = [col for col in enduses if not '.weight' in col]
  enduses = [col for col in enduses if not '.upgrade_cost_usd' in col]
  enduses = [col for col in enduses if not '.upgrade_name' in col]
  enduses = [col for col in enduses if not '_not_met' in col]
  enduses = [col for col in enduses if not '_capacity_w' in col]
  return enduses

def deltas(df, enduses, reference_name, upgrade_name):
  """
  Calculate the delta (savings) between the upgrade and reference dataframes.

  Parameters:
    enduses (list):
    reference_name (str): The name of the reference scenario.
    upgrade_name (str): The name of the upgrade scenario.

  Returns:
    df (dataframe): A pandas dataframe with new attached savings columns.

  """    
  # reference rows for this building_id
  ref_df = df.loc[df['simulation_output_report.upgrade_name']==reference_name]

  # upgrade rows for this building_id
  upg_df = df.loc[df['simulation_output_report.upgrade_name']==upgrade_name]
  
  if not ref_df.empty:

    # incremental cost
    df.loc[upg_df.index, 'simulation_output_report.incremental_cost_usd'] = upg_df['simulation_output_report.upgrade_cost_usd'].values - ref_df['simulation_output_report.upgrade_cost_usd'].values
    
    # energy savings
    for enduse in enduses:
      df.loc[upg_df.index, 'savings_{}'.format(enduse)] = ref_df[enduse].values - upg_df[enduse].values
  
  else:
  
    # incremental cost
    df.loc[upg_df.index, 'simulation_output_report.incremental_cost_usd'] = np.nan
    
    # energy savings
    for enduse in enduses:
      df.loc[upg_df.index, 'savings_{}'.format(enduse)] = np.nan

  return df

def parallelize(groups, func, enduses, reference_name, upgrade_name):
  n_jobs = multiprocessing.cpu_count()
  print 'Using {} parallel processes...'.format(n_jobs)
  list = Parallel(n_jobs=n_jobs, verbose=5)(delayed(func)(group, enduses, reference_name, upgrade_name) for building_id, group in groups)
  return pd.concat(list)

def savings(results_csv, results_savings_csv, extra_cols, ref_upg_pairs):
  """
  Produce results savings csv file from results csv file. Also add cost-effectiveness, etc. columns.

  Parameters:
    results_csv (str): Relative path of the results csv file.
    results_savings_csv (str): Relative path of the results savings csv file.
    extra_cols (list): Additional columns to add to the results csv file.
    ref_upg_pairs (list): Reference, upgrade pairs for calculating savings.

  """
  print 'Starting to process {}...'.format(os.path.basename(results_csv))

  results_csv = pd.read_csv(results_csv, index_col=['_id'])
  
  # preprocess the savings dataframe
  results_csv = preprocess(results_csv)

  # get the list of upgrades
  upgrade_names = results_csv['simulation_output_report.upgrade_name'].unique()

  # calculate and include additional columns
  if 'egrid_subregions' in extra_cols: # egrid_subregions has dependency on location
    extra_cols.insert(len(extra_cols), extra_cols.pop(extra_cols.index('egrid_subregions')))
  if 'source_energy' in extra_cols: # source_energy has dependency on egrid_subregions
    extra_cols.insert(len(extra_cols), extra_cols.pop(extra_cols.index('source_energy')))
  results_csv = add_columns(results_csv, extra_cols)
  
  # remove unused columns
  cols = ['name', 'run_start_time', 'run_end_time', 'status', 'status_message']
  cols += [col for col in results_csv.columns if col.startswith('apply_upgrade')]
  for col in cols:
    try:
      results_csv = results_csv.drop(col, 1)
    except:
      pass
  
  # FIXME: Temporarily remove PV upgrade (net variables are not calculating correctly)
  results_csv = results_csv.drop(results_csv[results_csv['simulation_output_report.upgrade_name']=='pv'].index)

  # FIXME: Temp remove net variables
  for col in ['simulation_output_report.net_site_electricity_kwh', 'simulation_output_report.net_site_energy_mbtu']:
    if col in results_csv.columns:
      del results_csv[col]
  
  # get the list of enduses
  enduses = get_enduses(results_csv)
  
  print 'Grouping by building id...'
  ref_dfs = []
  upg_dfs = []
  if len(upgrade_names) == 1: # if there are no upgrades, just assign np.nan to every savings_ field

    df = results_csv.copy()
    for enduse in enduses:
      df['savings_{}'.format(enduse)] = np.nan
    df['simulation_output_report.incremental_cost_usd'] = 0.0

  else: # has upgrades for which to calculate savings

    if len(ref_upg_pairs) == 0: # user didn't supply any pairs, so assume all pairs are all upgrades relative to base
      for upgrade_name in upgrade_names:
        if upgrade_name != 'BASE':
          ref_upg_pairs.append('"BASE", "{}"'.format(upgrade_name))

    for pair in ref_upg_pairs:

      ref_upg_quote_split = pair.split('"')
      ref_upg_sep = '"{}"'.format(ref_upg_quote_split[2])
      ref_upg_comma_split = pair.split(ref_upg_sep)
      reference_name, upgrade_name = [x.replace('"', '').replace("'", '').strip() for x in ref_upg_comma_split]
      
      print '\t... {}, {}'.format(reference_name, upgrade_name)
      if not reference_name in upgrade_names or not upgrade_name in upgrade_names:
        print '\t\t... Skip'
        continue

      # copy the full results csv
      df = results_csv.copy()

      ref_df = df[df['simulation_output_report.upgrade_name']==reference_name]
      ref_dfs.append(ref_df) # you want all the references even if the upgrade doesn't apply
      upg_df = df[df['simulation_output_report.upgrade_name']==upgrade_name]
      
      ref_df = ref_df[ref_df['build_existing_model.building_id'].isin(upg_df['build_existing_model.building_id'])] # only references for which the upgrade applied
      upg_df = upg_df[upg_df['build_existing_model.building_id'].isin(ref_df['build_existing_model.building_id'])] # only upgrades for which there is a reference
      ref_upg_df = pd.concat([ref_df, upg_df])

      ref_upg_df = parallelize(ref_upg_df.groupby('build_existing_model.building_id'), deltas, enduses, reference_name, upgrade_name)
      
      upg_df = ref_upg_df[ref_upg_df['simulation_output_report.upgrade_name']==upgrade_name]
      upg_df['simulation_output_report.upgrade_name'] = '{}-{}'.format(reference_name, upgrade_name)

      # cost-effectiveness calculations
      for extra_col in extra_cols:
        if not extra_col in ['simple_payback', 'net_present_value', 'savings_investment_ratio']:
          extra_cols.remove(extra_col)
      upg_df = add_columns(upg_df, extra_cols)
      
      upg_dfs.append(upg_df)

  print 'Cleaning up ...'
  
  if ref_dfs and upg_dfs:
    ref_df = pd.concat(ref_dfs)
    ref_df = ref_df.drop_duplicates()
    df = pd.concat([ref_df] + upg_dfs)
  
  # sort on the building_id and upgrade_name
  df = df.sort(['build_existing_model.building_id', 'simulation_output_report.upgrade_name'])

  df = df.dropna(axis=1, how='all')
  df.to_csv(results_savings_csv)

  print 'CSV export(s) of savings calculations complete.'

if __name__ == '__main__':

  t0 = time.time()

  extra_cols = []
  for item in inspect.getmembers(ExtraColumns, predicate=inspect.ismethod):
    extra_cols.append(item[0])
  extra_cols.append('all')

  local_results = os.path.join(os.path.dirname(__file__), '../data/analysis_results/localResults/results.csv')
  
  parser = argparse.ArgumentParser()
  parser.add_argument('-r', '--results', default=local_results, help='Path of the results csv file.')
  parser.add_argument('-e', '--extra_cols', action='append', choices=extra_cols, help='Additional columns available to add.')
  parser.add_argument('-u', '--ref_upg_pairs', action='append', help='Reference, upgrade pairs for calculating savings.')
  args = parser.parse_args()

  if args.extra_cols == None:
    args.extra_cols = []
  elif 'all' in args.extra_cols:
    args.extra_cols = []
    for item in inspect.getmembers(ExtraColumns, predicate=inspect.ismethod):
      args.extra_cols.append(item[0])

  if args.ref_upg_pairs == None:
    args.ref_upg_pairs = []

  results_csv = args.results
  file, ext = os.path.splitext(os.path.basename(results_csv))
  results_savings_csv = os.path.join(os.path.dirname(results_csv), '{}_savings{}'.format(file, ext))
  if not os.path.exists(results_savings_csv):
    savings(results_csv, results_savings_csv, args.extra_cols, args.ref_upg_pairs)
  
  print "All done! Completed rows in {0:.2f} seconds on".format(time.time()-t0), time.strftime("%Y-%m-%d %H:%M") + "."