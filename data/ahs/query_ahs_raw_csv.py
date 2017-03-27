
import os
import pandas as pd
import numpy as np

cols = {'newhouse.csv': ['STATUS', 'NUNIT2', 'ZINC2', 'ROOMS', 'BEDRMS', 'UNITSF', 'BUILT', 'HFUEL', 'FLOORS', 'GASPIP', 'SMSA', 'CMSA', 'REGION', 'DIVISION', 'METRO3', 'POOR', 'HHREL', 'NONREL', 'AIRSYS', 'NUMAIR', 'WEIGHT']}

def retrieve_data(files):
    
    dfs = []
    for file in files:
      if not os.path.basename(file) in cols.keys():
        continue
      df = pd.read_csv(file, index_col=['CONTROL'], na_values=["'-6'", "'-7'", "'-8'", "'-9'", -6, -7, -8, -9])
      df = df[cols[os.path.basename(file)]]
      df['STATUS'] = df['STATUS'].str.replace("'", "")
      df = df[df['STATUS']=='1'] # Occupied
      df['NUNIT2'] = df['NUNIT2'].str.replace("'", "")
      df = df[df['NUNIT2']=='1'] # Single-family, detached
      dfs.append(df)
    
    return pd.concat(dfs)

def assign_vintage(df):

  def vintage(year):
    if year < 1950:
      return '<1950'
    elif year >= 1950 and year < 1960:
      return '1950s'
    elif year >= 1960 and year < 1970:
      return '1960s'
    elif year >= 1970 and year < 1980:
      return '1970s'
    elif year >= 1980 and year < 1990:
      return '1980s'
    elif year >= 1990 and year < 2000:
      return '1990s'
    elif year >= 2000 and year < 2010:
      return '2000s'
    elif year >= 2010:
      return '2000s' # TODO: 2010s?

  df['vintage'] = df['BUILT'].apply(lambda x: vintage(x))
  
  return df
  
def assign_heating_fuel(df):

  def fuel(fuel, pipe):
    if fuel == '1':
      return 'Electricity'
    elif fuel == '2':
      if pipe == '1':
        return 'Natural Gas'
      elif pipe == '2':
        return 'Propane'
      return np.nan
    elif fuel == '3':
      return 'Fuel Oil'
    elif fuel in ['4', '5', '6', '7', '8']:
      return 'Other Fuel'
    return 'None' # TODO: None or Other Fuel?

  df['HFUEL'] = df['HFUEL'].str.replace("'", "")
  df['GASPIP'] = df['GASPIP'].str.replace("'", "")
  df['heatingfuel'] = df.apply(lambda x: fuel(x.HFUEL, x.GASPIP), axis=1)
  
  return df
  
def assign_size(df):

  def size(sf):
    if sf >= 0 and sf < 1500:
      return '0-1499'
    elif sf >= 1500 and sf < 2500:
      return '1500-2499'
    elif sf >= 2500 and sf < 3500:
      return '2500-3499'
    elif sf >= 3500:
      return '3500+'
    return np.nan
             
  df['size'] = df.apply(lambda x: size(float(x.UNITSF)), axis=1)

  return df
  
def assign_smsa(df):

  smsakey = {'0720': 'Baltimore-Towson, MD  Metro Area',
             '1120': 'Boston-Cambridge-Quincy, MA-NH  Metro Area',
             '9991': 'Chicago-Naperville-Joliet, IL + Lake County-Kenosha County, IL-WI',
             '2160': 'Detroit-Warren-Livonia, MI  Metro Area',
             '3280': 'Hartford-West Hartford-East Hartford, CT  Metro Area',
             '3360': 'Houston-Sugar Land-Baytown, TX  Metro Area',
             '5000': 'Miami-Miami Beach -Kendall, FL',
             '5120': 'Minneapolis-St. Paul-Bloomington, MN-WI  Metro Area',
             '9992': 'New York',
             '9993': 'Northern NJ',
             '5880': 'Oklahoma City, OK  Metro Area',
             '6160': 'Philadelphia, PA',
             '6840': 'Rochester, NY  Metro Area',
             '7240': 'San Antonio, TX  Metro Area',
             '7600': 'Seattle-Tacoma-Bellevue, WA  Metro Area',
             '8280': 'Tampa-St. Petersburg-Clearwater, FL  Metro Area',
             '8840': 'Washington-Arlington-Alexandria, DC-VA-MD-WV  Metro Area',
             '5960': 'Orlando-Kissimmee, FL  Metro Area',
             '4120': 'Las Vegas-Paradise, NV  Metro Area',
             '5360': 'Nashville-Davidson--Murfreesboro--Franklin, TN  Metro Area',
             '0640': 'Austin-Round Rock, TX  Metro Area',
             '3600': 'Jacksonville, FL  Metro Area',
             '4520': 'Louisville-Jefferson County, KY-IN  Metro Area',
             '6760': 'Richmond, VA  Metro Area',
             '8520': 'Tucson, AZ  Metro Area',
             '0620': 'Chicago-Naperville-Joliet, IL + Lake County-Kenosha County, IL-WI',
             '1600': 'Chicago-Naperville-Joliet, IL + Lake County-Kenosha County, IL-WI',
             '3690': 'Chicago-Naperville-Joliet, IL + Lake County-Kenosha County, IL-WI',
             '3965': 'Chicago-Naperville-Joliet, IL + Lake County-Kenosha County, IL-WI',
             '5380': 'New York',
             '5600': 'New York',
             '5950': 'New York',
             '0875': 'Northern NJ',
             '3640': 'Northern NJ',
             '5015': 'Northern NJ',
             '5190': 'Northern NJ',
             '5640': 'Northern NJ',
             '8480': 'Northern NJ'}

  def smsa(key):
    try:
      return smsakey[key]
    except:
      return np.nan
  
  df['SMSA'] = df['SMSA'].str.replace("'", "")
  df['smsa'] = df['SMSA'].apply(lambda x: smsa(x))
  
  return df
  
def assign_cmsa(df):

  def cmsa(key):
    return key
  
  df['CMSA'] = df['CMSA'].str.replace("'", "")
  df['cmsa'] = df['CMSA'].apply(lambda x: cmsa(x))
  
  return df  
  
def assign_region(df):

  regionkey = {'1': 'Northeast',
               '2': 'Midwest',
               '3': 'South',
               '4': 'West'}
  
  df['REGION'] = df['REGION'].str.replace("'", "")
  df['region'] = df['REGION'].apply(lambda x: regionkey[x])
  
  return df
  
def assign_division(df):

  divisionkey = {'01': 'New England',
                 '02': 'Middle Atlantic',
                 '03': 'East North Central',
                 '04': 'West North Central',
                 '07': 'West South Central',
                 '56': 'South Atlantic - East South Central',
                 '89': 'Mountain - Pacific'}
  
  df['DIVISION'] = df['DIVISION'].str.replace("'", "")
  df['division'] = df['DIVISION'].apply(lambda x: divisionkey[x])
  
  return df
  
def assign_metro(df):

  def metro(key):
    return key

  df['METRO3'] = df['METRO3'].str.replace("'", "")
  df['metro'] = df['METRO3'].apply(lambda x: metro(x))
  
  return df
  
def assign_stories(df):

  df['stories'] = df['FLOORS'].apply(lambda x: '1' if x == 1 else '2+')
  
  return df
  
def assign_actype(df):

  def actype(airsys, numair):
    if airsys == '1':
      return 'Central'
    elif airsys == '2':
      if not pd.isnull(numair):
        return 'Room'
    return 'None'

  df['AIRSYS'] = df['AIRSYS'].str.replace("'", "")
  df['actype'] = df.apply(lambda x: actype(x['AIRSYS'], x['NUMAIR']), axis=1)
  
  return df
  
def assign_fplbins(df):

  def fpl(val):
    if val < 50:
      return '0-50'
    elif val >= 50 and val < 100:
      return '50-100'
    elif val >= 100 and val < 150:
      return '100-150'
    elif val >= 150 and val < 200:
      return '150-200'
    elif val >= 200 and val < 250:
      return '200-250'
    elif val >= 250 and val < 300:
      return '250-300'
    elif val >= 300:
      return '300+'

  df['fplbins'] = df['POOR'].apply(lambda x: fpl(x))
  
  return df  
  
if __name__ == '__main__':
  
  files = [os.path.join(os.path.abspath(os.path.dirname(__file__)), 'csvs', 'national', file) for file in os.listdir(os.path.join(os.path.dirname(__file__), 'csvs', 'national'))]
    
  df = retrieve_data(files)
  df = assign_vintage(df)
  df = assign_heating_fuel(df)
  df = assign_size(df)
  df = assign_smsa(df)
  df = assign_cmsa(df)
  df = assign_region(df)
  df = assign_division(df)
  df = assign_metro(df)
  df = assign_stories(df)
  df = assign_actype(df)
  df = assign_fplbins(df)

  df.to_csv(os.path.join(os.path.dirname(__file__), 'MLR', 'ahs.csv'), index=True)
