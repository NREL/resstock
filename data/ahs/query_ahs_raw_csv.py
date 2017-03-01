
import os
import pandas as pd
import numpy as np

cols = ['CONTROL', 'NUNIT2', 'ZINC2', 'ROOMS', 'BEDRMS', 'UNITSF', 'BUILT', 'HFUEL', 'GASPIP', 'WEIGHT']

def retrieve_data(file):
    
    df = pd.read_csv(file)
    df = df[cols]
    
    return df

def assign_vintage(df):

  vintagekey = {-6: np.nan,
                1919: '<1950',
                1920: '<1950',
                1930: '<1950',
                1940: '<1950',
                1950: '1950s',
                1960: '1960s',
                1970: '1970s',
                1975: '1970s',
                1980: '1980s',
                1985: '1980s',
                1990: '1990s',
                1995: '1990s',
                2000: '2000s',
                2001: '2000s',
                2002: '2000s',
                2003: '2000s',
                2004: '2000s',
                2005: '2000s',
                2006: '2000s',
                2007: '2000s',
                2008: '2000s',
                2009: '2000s',
                2010: '2010s',
                2011: '2010s',
                2012: '2010s',
                2013: '2010s'}

  df['vintage'] = df.apply(lambda x: vintagekey[x.BUILT], axis=1)
  
  return df
  
def assign_heating_fuel(df):

  def fuel(fuel, pipe):
    if fuel in ['-6', '9']:
      return np.nan
    elif fuel == '1':
      return 'Electricity'
    elif fuel == '2':
      if pipe == '1':
        return 'Natural Gas'
      elif pipe == '2':
        return 'Propane/LPG'
      return np.nan
    elif fuel == '3':
      return 'Fuel Oil'
    elif fuel in ['4', '5', '6', '7', '8']:
      return 'Other Fuel'

  df['heatingfuel'] = df.apply(lambda x: fuel(x.HFUEL[1:-1], x.GASPIP[1:-1]), axis=1)
  
  return df
  
def assign_federal_poverty_level(df):
  
  # https://aspe.hhs.gov/2013-poverty-guidelines
  incomelimitkey = {1: 11490.0,
                    2: 15510.0,
                    3: 19530.0,
                    4: 23550.0,
                    5: 27570.0,
                    6: 31590.0,
                    7: 35610.0,
                    8: 39630.0}
  
  def incomelimit(famsize, ftotinc):
    if famsize <= 8:
      incomelimit = incomelimitkey[famsize]
    else:
      incomelimit = incomelimitkey[8] + (famsize - 8) * 4020.0
    return ftotinc * 100.0 / incomelimit
  
  df['fpl'] = df.apply(lambda x: incomelimit(x.ZCROWD, x.ZINC2), axis=1)
  
  return df
  
def assign_size(df):

  def size(sf):
    if sf < 0:
      return np.nan
    elif sf >= 0 and sf < 1500:
      return '0-1499'
    elif sf >= 1500 and sf < 2500:
      return '1500-2499'
    elif sf >= 2500 and sf < 3500:
      return '2500-3499'
    else:
      return '3500+'
             
  df['size'] = df.apply(lambda x: size(float(x.UNITSF)), axis=1)
  
  return df
  
def assign_rooms(df):

  def rooms(rooms):
    if rooms <= 0:
      return np.nan
    return rooms

  df['rooms'] = df.apply(lambda x: rooms(x.ROOMS), axis=1)

  return df
  
def assign_bedrooms(df):

  def rooms(rooms):
    if rooms <= 0:
      return np.nan
    return rooms

  df['bedrooms'] = df.apply(lambda x: rooms(x.BEDRMS), axis=1)

  return df
  
def assign_income(df):

  def income(income):
    if income <= 0:
      return np.nan
    return income

  df['income'] = df.apply(lambda x: income(float(x.ZINC2)), axis=1)

  return df  
  
if __name__ == '__main__':
  
  file = 'newhouse.csv'
  
  df = retrieve_data(file)
  df = assign_vintage(df)
  df = assign_heating_fuel(df)
  # df = assign_federal_poverty_level(df)
  df = assign_size(df)
  df = assign_rooms(df)
  df = assign_bedrooms(df)
  df = assign_income(df)
    
  df.to_csv(os.path.join(os.path.dirname(__file__), 'MLR', 'ahs.csv'), index=False)
