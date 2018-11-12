import os
import sys
import numpy as np
import itertools
import pandas as pd
import psycopg2 as pg

con_string = "host={} port={} dbname={} user={} password={}".format(os.environ['GIS_HOST'], os.environ['GIS_PORT'], os.environ['GIS_DBNAME'], os.environ['GIS_USER'], os.environ['GIS_PASSWORD'])

class Create_DFs():
    
  def __init__(self, table_name):
    sql = "SELECT * FROM cleap_ami.{};".format(table_name)
    self.session = pd.read_sql(sql, con)

  def area_median_income(self, st):
  
    def tract_to_tract_gisjoin(tract):
      tract = str(int(tract))
      return 'G' + tract.zfill(11)[0:2] + tract.zfill(11)[2:5].zfill(4) + tract.zfill(11)[5:12].zfill(7)
  
    df = self.session
    
    tract_to_nsrdb = pd.read_csv('tract_to_nsrdb_grid_crosswalk.csv')
    nsrdb_gid_old_to_new = pd.read_csv('nsrdb_gid_old_to_new.csv')
    nsrdb_grid_to_station_lkup_tmy3 = pd.read_csv('nsrdb_grid_to_station_lkup_tmy3.csv', usecols=['nsrdb_gid', 'usaf'])
    usaf_to_epw = pd.read_csv('usaf_to_epw.csv', usecols=['usaf', 'EPW'])

    df = df[~df['hfl index'].isin([4, 6])] # Remove COAL, SOLAR
    df = df[df['bld index'].isin([0])] # Only '1 DETACHED'
    df['tract_gisjoin'] = df.apply(lambda x: tract_to_tract_gisjoin(x['tract']), axis=1) # TODO
    df = df.merge(tract_to_nsrdb, on='tract_gisjoin', how='left')
    df = df.merge(nsrdb_gid_old_to_new, left_on='nsrdb_gid', right_on='nsrdb_gid_old')
    df = df.merge(nsrdb_grid_to_station_lkup_tmy3, left_on='nsrdb_gid_new', right_on='nsrdb_gid')    
    df = df.merge(usaf_to_epw, on='usaf')
    
    # options = ['OWNER 0-30%', 'OWNER 30-60%', 'OWNER 60-80%', 'OWNER 80-100%', 'OWNER 100%+', 'RENTER 0-30%', 'RENTER 30-60%', 'RENTER 60-80%', 'RENTER 80-100%', 'RENTER 100%+']
    options = df.columns[9:19].values # HOUSING UNIT COUNTS (?)
    
    # If tract is in multiple epw locations, use allocation factors
    for col in options:
      df[col] *= df['tract2nsrdb_alloc_ratio']
    
    # Preprocess LMI file into vintage, etc. enumerations we use (divide by two)
    df['hfl index'] = df['hfl index'].apply(lambda x: assign_heating_fuel(x))
    df = df.rename(columns={'ybl index': 'Dependency=Vintage', 'hfl index': 'Dependency=Heating Fuel', 'EPW': 'Dependency=Location EPW', 'tract_gisjoin': 'Dependency=Location Census Tract', 'countyfp': 'Dependency=Location County'})

    df['Dependency=Location County'] = df['Dependency=Location County'].apply(lambda x: str(x).zfill(5))
    
    for vintage in [4, 3, 2]:
      sub = df[df['Dependency=Vintage']==vintage].copy()
      if vintage == 4:
        sub['Dependency=Vintage'] = sub['Dependency=Vintage'].map({vintage: '<1950'})
      elif vintage == 3:
        sub['Dependency=Vintage'] = sub['Dependency=Vintage'].map({vintage: '1960s'})
      elif vintage == 2:
        sub['Dependency=Vintage'] = sub['Dependency=Vintage'].map({vintage: '1980s'})
      df = df.append([sub])

    df['Dependency=Vintage'] = df['Dependency=Vintage'].map({5: '<1940', '<1950': '<1950', 4: '1950s', '1960s': '1960s', 3: '1970s', '1980s': '1980s', 2: '1990s', 1: '2000s', 0: '2010s'})

    for col in df.columns:
      if 'owner' in col or 'renter' in col:
        df.loc[df['Dependency=Vintage'].isin(['<1950', '1950s', '1960s', '1970s', '1980s', '1990s']), col] *= 0.5

    df['Dependency=Vintage'] = df['Dependency=Vintage'].map({'<1940': '<1950', '<1950': '<1950', '1950s': '1950s', '1960s': '1960s', '1970s': '1970s', '1980s': '1980s', '1990s': '1990s', '2000s': '2000s', '2010s': '2000s'})
    
    df = df[np.concatenate([['Dependency=Vintage', 'Dependency=Heating Fuel', 'Dependency=Location EPW', 'Dependency=Location Census Tract', 'Dependency=Location County'], options])]
    df = add_option_prefix(df)
    
    return df

def assign_heating_fuel(row):
  if row == 1:
    return 'Propane'
  elif row == 2:
    return 'Electricity'
  elif row == 3:
    return 'Fuel Oil'
  elif row == 0:
    return 'Natural Gas'
  elif row == 5:
    return 'Wood'
  elif row == 7:
    return 'Other Fuel'
  elif row == 8:
    return 'None'
  
def add_option_prefix(df):
    for col in df.columns:
        if not 'Dependency=' in col and not 'Count' in col and not 'Weight' in col and not 'group' in col:
            if col in ['GSHP', 'Dual-Fuel ASHP, SEER 14, 8.2 HSPF', 'Gas Stove, 75% AFUE', 'Oil Stove', 'Propane Stove', 'Wood Stove', 'Evaporative Cooler']:
                df.rename(columns={col: 'Option=FIXME {}'.format(col)}, inplace=True)
            else:
                df.rename(columns={col: 'Option={}'.format(col)}, inplace=True)
    return df
  
if __name__ == '__main__':
  
  datafiles_dir = '../../project_resstock_national/housing_characteristics'

  con = pg.connect(con_string)
  sql = "SELECT table_name FROM information_schema.tables WHERE table_schema='cleap_ami';"
  df = pd.read_sql(sql, con)
  table_names = list(df['table_name'])
  table_names = [x for x in table_names if not 'utility' in x]
  
  for i, table_name in enumerate(table_names):

    print i+1, table_name
    dfs = Create_DFs(table_name)
    
    st = table_name.split('_')[-1].upper()
  
    for category in ['Area Median Income']:
      method = getattr(dfs, category.lower().replace(' ', '_'))
      df = method(st)

    df = df.groupby(['Dependency=Vintage', 'Dependency=Heating Fuel', 'Dependency=Location EPW', 'Dependency=Location Census Tract', 'Dependency=Location County']).sum()

    count = df.sum(axis=1)
    df = df.div(df.sum(axis=1), axis=0)
    df['Count'] = count

    if not df.empty:
      options = [col for col in df.columns if 'Option=' in col]
      df['Count'] = df['Count'].fillna(0)
      df[options] = df[options].fillna(1.0 / len(options)) # we don't want any zero rows; so assign equal prob
      df.to_csv(os.path.join(datafiles_dir, '{} {}.tsv'.format(category, st)), sep='\t')
        