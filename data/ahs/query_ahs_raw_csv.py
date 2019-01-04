
import os
import pandas as pd
import numpy as np
import random

cols = {'newhouse.csv': ['CONTROL', 'STATUS', 'NUNIT2', 'ZINC2', 'ROOMS', 'BEDRMS', 'UNITSF', 'BUILT', 'HEQUIP', 'HFUEL', 'FLOORS', 'GASPIP', 'SMSA', 'CMSA', 'REGION', 'DIVISION', 'METRO3', 'POOR', 'AIRSYS', 'NUMAIR', 'TENURE', 'WEIGHT'],
        'ahs2015n.csv': ['CONTROL', 'INTSTATUS', 'WEIGHT', 'DIVISION', 'TENURE', 'BLD', 'YRBUILT', 'FOUNDTYPE', 'UNITSIZE', 'STORIES', 'HEATTYPE', 'HEATFUEL', 'ACPRIMARY', 'NUMPEOPLE', 'HINCP', 'FINCP', 'PERPOVLVL', 'TOTROOMS']}

def retrieve_data(files):
    
    dfs = []
    for file in files:
      if not os.path.basename(file) in cols.keys():
        continue
      df = pd.read_csv(file, usecols=cols[os.path.basename(file)], na_values=["'-6'", "'-7'", "'-8'", "'-9'", -6, -7, -8, -9])
      df = df.set_index('CONTROL')
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
  
def assign_heating_type(df):

  def type(type):
    if type == 1:
      return 'Warm-air furnace'
    elif type == 2:
      return 'Steam or hot water system'
    elif type == 3:
      return 'Electric heat pump'
    elif type == 4:
      return 'Built-in electric units'
    elif type == 5:
      return 'Floor, wall, or other built-in hot-air units without ducts'
    elif type == 6:
      return 'Room heaters with flue'
    elif type == 7:
      return 'Room heaters without flue'
    elif type == 8:
      return 'Portable electric heaters'
    elif type == 9:
      return 'Stoves'
    elif type == 10:
      return 'Fireplaces with inserts'
    elif type == 11:
      return 'Fireplaces wihtout inserts'
    elif type == 14:
      return 'Cooking stove'
    elif type == 12:
      return 'Other'
    elif type == 13:
      return 'None'

  df['heatingtype'] = df.apply(lambda x: type(x.HEQUIP), axis=1)
  
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
    return 'Blank'
             
  df['size'] = df.apply(lambda x: size(float(x.UNITSF)), axis=1)

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
  
def assign_tenure(df):

  def tenure(key):
    if key == '1':
      return 'Own'
    elif key == '2':
      return 'Rent'
    elif key == '3':
      return 'None'

  df['TENURE'] = df['TENURE'].str.replace("'", "")
  df['tenure'] = df.apply(lambda x: tenure(x['TENURE']), axis=1)    
    
  return df
  
def assign_location(df):

  smsakey = {'0080': 'Akron, OH',
             '0160': 'Albany-Schenectady-Troy, NY',
             '0200': 'Albuquerque, NM',
             '0240': 'Allentown-Bethlehem-Easton, PA',
             '0275': 'Alton-Granite City, IL',
             '0360': 'Anaheim-Santa Ana (Orange County), CA',
             '0460': 'Appleton-Oshkosh-Neenah, WI',
             '0520': 'Atlanta, GA',
             '0560': 'Atlantic City, NJ',
             '0600': 'Augusta, GA-SC',
             '0620': 'Aurora-Elgin, IL',
             '0640': 'Austin, TX',
             '0680': 'Bakersfield, CA',
             '0720': 'Baltimore, MD',
             '0760': 'Baton Rouge, LA',
             '0840': 'Beaumont-Port Arthur, TX',
             '0845': 'Beaver, PA',
             '0875': 'Bergen-Passaic, NJ',
             '1000': 'Birmingham, AL',
             '1120': 'Boston, MA',
             '1125': 'Boulder-Longmont, CO',
             '1160': 'Bridgeport-Milford, CT',
             '1320': 'Canton, OH',
             '1440': 'Charleston, SC',
             '1560': 'Chattanooga, TN-GA',
             '1600': 'Chicago, IL',
             '1640': 'Cincinnati, OH-KY-IN',
             '1680': 'Cleveland, OH',
             '1720': 'Colorado Springs, CO',
             '1760': 'Columbia, SC',
             '1840': 'Columbus, OH',
             '1880': 'Corpus Christi, TX',
             '1920': 'Dallas, TX',
             '1960': 'Davenport-Rock Island-Moline, IA-IL',
             '2020': 'Daytona Beach, FL',
             '2080': 'Denver, CO',
             '2120': 'Des Moines, IA',
             '2160': 'Detroit, MI',
             '2240': 'Duluth, MN-WI',             
             '2285': 'East Saint Louis-Belleville, IL',
             '2320': 'El Paso, TX',
             '2360': 'Erie, PA',
             '2400': 'Eugene-Springfield, OR',
             '2440': 'Evansville, IN-KY',
             '2640': 'Flint, MI',
             '2680': 'Fort Lauderdale-Hollywood, FL',
             '2700': 'Fort Myers-Cape Coral, FL',
             '2760': 'Fort Wayne, IN',
             '2800': 'Fort Worth-Arlington, TX',
             '2840': 'Fresno, CA',
             '2960': 'Gary-Hammond, IN',
             '3000': 'Grand Rapids, MI',
             '3120': 'Greensboro-Winston Salem-High Point, NC',
             '3160': 'Greenville-Spartanburg, SC',
             '3280': 'Hartford, CT',
             '3320': 'Honolulu, HI',
             '3360': 'Houston, TX',
             '3480': 'Indianapolis, IN',
             '3560': 'Jackson, MS',
             '3600': 'Jacksonville, FL',
             '3640': 'Jersey City, NJ',
             '3660': 'Johnson City-Kingsport-Bristol, TN-VA',
             '3690': 'Chicago-Naperville-Joliet, IL + Lake County-Kenosha County, IL-WI',
             '3760': 'Kansas City, MO-KS',
             '3840': 'Knoxville, TN',
             '3965': 'Lake County, IL',
             '3980': 'Lakeland-Winter Haven, FL',
             '4000': 'Lancaster, PA',
             '4040': 'Lansing-East Lansing, MI',
             '4120': 'Las Vegas, NV',
             '4160': 'Lawrence-Haverhill, MA-NH',
             '4280': 'Lexington-Fayette, KY',
             '4400': 'Little Rock-North Little Rock, AR',
             '4520': 'Louisville-Jefferson County, KY-IN',
             '4480': 'Los Angeles-Long Beach, CA',
             '4720': 'Madison, WI',
             '4880': 'McAllen-Edinburgh-Mission, TX',
             '4900': 'Melbourne-Titusville-Palm Bay, FL',
             '4920': 'Memphis, TN-AR-MS',
             '5000': 'Miami-Hialeah, FL',
             '5015': 'Middlesex-Somerset-Hunterdon, NJ',
             '5080': 'Milwaukee, WI',
             '5120': 'Minneapolis-Saint Paul, MN',
             '5160': 'Mobile, AL',
             '5170': 'Modesto, CA',
             '5190': 'Monmouth-Ocean, NJ',
             '5240': 'Montgomery, AL',
             '5360': 'Nashville, TN',
             '5380': 'Nassau-Suffolk, NY',
             '5480': 'New Haven-Meriden, CT',
             '5560': 'New Orleans, LA',
             '5600': 'New York City, NY',
             '5640': 'Newark, NJ',
             '5680': 'Norfolk-Newport News, VA-NC',
             '5775': 'Oakland, CA',
             '5880': 'Oklahoma City, OK',
             '5920': 'Omaha, NE-IA',
             '5950': 'New York, NY',
             '5960': 'Orlando, FL',
             '6000': 'Oxnard-Ventura, CA',
             '6080': 'Pensacola, FL',
             '6120': 'Peoria, IL',
             '6160': 'Philadelphia, PA-NJ',
             '6200': 'Phoenix, AZ',
             '6280': 'Pittsburgh, PA',
             '6480': 'Providence, RI',
             '6640': 'Raleigh-Durham, NC',
             '6760': 'Richmond, VA',
             '6780': 'Riverside-San Bernardino, CA',
             '6840': 'Rochester, NY',
             '6880': 'Rockford, IL',
             '6920': 'Sacramento, CA',
             '7040': 'Saint Louis, MO-IL',
             '7090': 'Salem-Gloucester, MA',
             '7120': 'Salinas-Seaside-Monterey, CA',
             '7160': 'Salt Lake City-Ogden, UT',
             '7240': 'San Antonio, TX',
             '7600': 'Seattle-Tacoma-Bellevue, WA',
             '8280': 'Tampa-St. Petersburg-Clearwater, FL',
             '8480': 'Northern NJ, NJ',
             '8520': 'Tucson, AZ',
             '8840': 'Washington-Arlington-Alexandria, DC-VA-MD-WV',
             '9991': 'Chicago-Naperville-Joliet, IL + Lake County-Kenosha County, IL-WI',
             '9992': 'New York, NY',
             '9993': 'Northern NJ, NJ',
             }

  cmsakey = {'07': 'Boston-Lawrence-Salem, MA-NH',
             '10': 'Buffalo-Niagara Falls, NY',
             '31': 'Dallas-Fort Worth, TX',
             '34': 'Denver-Boulder, CO',
             '41': 'Hartford-New Britain-Middletown, CT',
             '47': 'Kansas City, MO-KS',
             '49': 'Los Angeles-Anaheim-Riverside, CA',
             '56': 'Miami-Fort Lauderdale, FL',
             '70': 'New York-Northern New Jersey-Long Island, NY-NJ-CT',
             '78': 'Pittsburgh-Beaver Valley, PA',
             '79': 'Portland-Vancouver, OR-WA',
             '80': 'Providence-Pawtucket-Fall River, RI-MA',
             '82': 'Saint Louis-East Saint Louis-Alton, MO-IL',
             '91': 'Seattle-Tacoma, WA'}             
             
  metrokey = {'1': 'Central city of MSA',
              '2': 'Inside MSA, but not in central city - urban',
              '3': 'Inside MSA, but not in central city - rural',
              '4': 'Outside MSA, urban',
              '5': 'Outside MSA, rural'}             
             
  divisionkey = {'01': 'New England',
                 '02': 'Middle Atlantic',
                 '03': 'East North Central',
                 '04': 'West North Central',
                 '07': 'West South Central',
                 '56': 'South Atlantic - East South Central',
                 '89': 'Mountain - Pacific'}               
             
  def smsa(key):
    if key in smsakey.keys():
      return smsakey[key]
    else:
      return 'Blank'
      
  def cmsa(key):
    if key in cmsakey.keys():
      return cmsakey[key]
    else:
      return 'Blank'

  def metro3(key):
    if key in metrokey.keys():
      return metrokey[key]
    else:
      return 'Blank'        

  def division(key):
    if key in divisionkey.keys():
      return divisionkey[key]
    else:
      return 'Blank'      
      
  def location(smsa, cmsa, metro, div):
    if smsa in smsakey.keys():
      return smsakey[smsa]
    elif cmsa in cmsakey.keys():
      return cmsakey[cmsa]
    else:
      return divisionkey[div]
    
  df['SMSA'] = df['SMSA'].str.replace("'", "")
  df['smsa'] = df['SMSA'].apply(lambda x: smsa(x))
  df['CMSA'] = df['CMSA'].str.replace("'", "")
  df['cmsa'] = df['CMSA'].apply(lambda x: cmsa(x))
  df['METRO3'] = df['METRO3'].str.replace("'", "")
  df['metro3'] = df['METRO3'].apply(lambda x: metro3(x))
  df['DIVISION'] = df['DIVISION'].str.replace("'", "")
  df['division'] = df['DIVISION'].apply(lambda x: division(x))
  df['location'] = df.apply(lambda x: location(x['SMSA'], x['CMSA'], x['METRO3'], x['DIVISION']), axis=1)   

  return df
  
def assign_region(df):

  regionkey = {'1': 'Northeast',
               '2': 'Midwest',
               '3': 'South',
               '4': 'West'}
  
  df['REGION'] = df['REGION'].str.replace("'", "")
  df['region'] = df['REGION'].apply(lambda x: regionkey[x])
  
  return df  
  
def assign_income(df):

  def income(val):
    if val < 25000:
      return '0-25K'
    elif val >= 25000 and val < 50000:
      return '25-50K'
    elif val >= 50000 and val < 75000:
      return '50-75K'
    elif val >= 75000 and val < 100000:
      return '75-100K'
    elif val >= 100000 and val < 125000:
      return '100-125K'
    elif val >= 125000 and val < 150000:
      return '125-150K'
    elif val >= 150000 and val < 200000:
      return '150-200K'
    else:
      return '200K+'

  df['income'] = df['ZINC2'].apply(lambda x: income(x))
  
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
  
  files = [os.path.join(os.path.abspath(os.path.dirname(__file__)), 'data', '2013', 'national', file) for file in os.listdir(os.path.join(os.path.dirname(__file__), 'data', '2013', 'national'))]
    
  df = retrieve_data(files)
  df = assign_vintage(df)
  df = assign_heating_type(df)
  df = assign_heating_fuel(df)
  df = assign_size(df)
  df = assign_location(df)
  df = assign_stories(df)
  df = assign_actype(df)
  df = assign_tenure(df)
  df = assign_location(df)
  df = assign_region(df)
  df = assign_income(df)
  df = assign_fplbins(df)

  df.to_csv(os.path.join(os.path.dirname(__file__), 'MLR', 'ahs.csv'), index=True)
