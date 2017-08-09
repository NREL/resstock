import os
import sys
import numpy as np
import itertools
import pandas as pd

class Create_DFs():
    
  def __init__(self, file):
    self.session = pd.read_csv(file, skiprows=1)

  def area_median_income(self):
  
    df = self.session

    # Remove COAL, SOLAR
    df = df[~df['HFL'].isin(['COAL', 'SOLAR'])]
    df = df[df['BLD9'].isin(['1 DETACHED'])]
    df['tract_gisjoin'] = 'G0100010020200' # FIXME
    tract_to_nsrdb = pd.read_csv('tract_to_nsrdb_grid_crosswalk.csv')
    df = df.merge(tract_to_nsrdb, on='tract_gisjoin', how='left')
    nsrdb_grid_to_station_lkup_tmy3 = pd.read_csv('nsrdb_grid_to_station_lkup_tmy3.csv', usecols=['nsrdb_gid', 'usaf'])
    df = df.merge(nsrdb_grid_to_station_lkup_tmy3, on='nsrdb_gid')
    usaf_to_epw = pd.read_csv('usaf_to_epw.csv', usecols=['usaf', 'EPW'])
    df = df.merge(usaf_to_epw, on='usaf')
    
    # options = ['OWNER 0-30%', 'OWNER 30-60%', 'OWNER 60-80%', 'OWNER 80-100%', 'OWNER 100%+', 'RENTER 0-30%', 'RENTER 30-60%', 'RENTER 60-80%', 'RENTER 80-100%', 'RENTER 100%+']
    options = df.columns[8:18].values # HOUSING UNIT COUNTS
    # options = df.columns[16:26] # HOUSEHOLD INCOME
    # options = df.columns[26:36] # ENERGY EXPENDITURES    
    
    # If tract is in multiple epw locations, use allocation factors and blow up the house counts in LMI
    for col in options:
      df[col] *= df['tract2nsrdb_alloc_ratio']
    
    # Preprocess LMI file into vintage, etc. enumerations we use (divide by two)
    df['HFL'] = df['HFL'].apply(lambda x: assign_heating_fuel(x))
    df = df.rename(columns={'YBL5': 'Dependency=Vintage', 'HFL': 'Dependency=Heating Fuel', 'EPW': 'Dependency=Location EPW'})
    
    for vintage in ['1940-59', '1960-79', '1980-99']:
      sub = df[df['Dependency=Vintage']==vintage].copy()
      if vintage == '1940-59':
        sub['Dependency=Vintage'] = sub['Dependency=Vintage'].map({vintage: '<1950'})
      elif vintage == '1960-79':
        sub['Dependency=Vintage'] = sub['Dependency=Vintage'].map({vintage: '1960s'})
      elif vintage == '1980-99':
        sub['Dependency=Vintage'] = sub['Dependency=Vintage'].map({vintage: '1980s'})
      df = df.append([sub])

    df['Dependency=Vintage'] = df['Dependency=Vintage'].map({'BEFORE 1940': '<1940', '<1950': '<1950', '1940-59': '1950s', '1960s': '1960s', '1960-79': '1970s', '1980s': '1980s', '1980-99': '1990s', '2000+': '2000s'})

    for col in df.columns:
      if 'OWNER' in col or 'RENTER' in col:
        df.loc[df['Dependency=Vintage'].isin(['<1950', '1950s', '1960s', '1970s', '1980s', '1990s']), col] *= 0.5
    
    df['Dependency=Vintage'] = df['Dependency=Vintage'].map({'<1940': '<1950', '<1950': '<1950', '1950s': '1950s', '1960s': '1960s', '1970s': '1970s', '1980s': '1980s', '1990s': '1990s', '2000s': '2000s'})
    
    df = df[np.concatenate([['Dependency=Vintage', 'Dependency=Heating Fuel', 'Dependency=Location EPW'], options])]

    return df

def assign_heating_fuel(row):
  if row == 'BOTTLED GAS':
    return 'Propane'
  elif row == 'ELECTRICITY':
    return 'Electricity'
  elif row == 'FUEL OIL':
    return 'Fuel Oil'
  elif row == 'UTILITY GAS':
    return 'Natural Gas'
  elif row == 'WOOD':
    return 'Other Fuel'
  elif row == 'OTHER':
    return 'Other Fuel'
  elif row == 'NONE':
    return 'None'
  
if __name__ == '__main__':
    
  # 'G' || substr(lpad(tract::text, 11, '0'), 1, 2) || lpad(substr(lpad(tract::text, 11, '0'), 3, 3), 4, '0') || lpad(substr(lpad(tract::text, 11, '0'), 6, 15), 7, '0')
  # 'G 11 0111 1111111'
  
  datafiles_dir = '../../project_resstock_national/housing_characteristics'

  tsvs = []
  
  files = ['LMI TEMPLATE CO v02.csv', 'LMI TEMPLATE IA v02.csv']
  
  for file in files:
  
    dfs = Create_DFs(file)
  
    for category in ['Area Median Income']:
      print category
      method = getattr(dfs, category.lower().replace(' ', '_'))
      df = method()
      tsvs.append(df)
  
  df = pd.concat(tsvs)
  df = df.groupby(['Dependency=Vintage', 'Dependency=Heating Fuel', 'Dependency=Location EPW']).sum()
  
  count = df.sum(axis=1)
  df = df.div(df.sum(axis=1), axis=0)
  df['Count'] = count
    
  df.to_csv(os.path.join(datafiles_dir, '{}.tsv'.format(category)), sep='\t')
        