
import os, sys
import pandas as pd
from datetime import datetime
import psycopg2 as pg
import numpy as np
import sqlite3

def main(df):

  df = assign_epw_stations(df)
  df = assign_heating_fuel(df)
  df = assign_geometry_house_size(df)
  df = assign_geometry_stories(df)
  df = assign_geometry_garage(df)
  df = assign_windows(df)
  df = assign_hvac_system_heating(df)
  df = assign_hvac_system_cooling(df)
  df = assign_water_heater(df)
  df = assign_cooking_range(df)
  df = assign_clothes_dryer(df)
  df = assign_heating_setpoint(df)
  df = assign_cooling_setpoint(df)
  df = assign_lighting(df)
  df = assign_refrigerator(df)
  df = assign_clothes_washer(df)
  df = assign_dishwasher(df)
  df = assign_misc_extra_refrigerator(df)
  df = assign_misc_freezer(df)
  df = assign_misc_gas_fireplace(df)
  df = assign_misc_gas_grill(df)
  df = assign_misc_gas_lighting(df)
  df = assign_misc_hot_tub_spa(df)
  df = assign_misc_pool(df)
  df = assign_misc_well_pump(df)

  col_to_category_name = {
                          'Heating Setpoint': {'Heating Set Point': {'63F': ['63 F'], '68F': ['68 F'], '71F': ['71 F'], '73F': ['73 F']}},
                          'Cooling Setpoint': {'Cooling Set Point': {'69F': ['69 F'], '74F': ['74 F'], '76F': ['76 F'], '78F': ['78 F']}},
                          'Windows': {'Windows': {'1 Pane': ['Clear, Single, Metal', 'Clear, Single, Non-metal'], '2+ Pane': ['Clear, Double, Metal, Air', 'Clear, Double, Non-metal, Air', 'Low-E, Double, Non-metal, Air, L-Gain', 'Low-E, Triple, Non-metal, Air, L-Gain'], 'None': []}},
                          'Water Heater': {'Water Heater': {'Electric Standard': ['Electric Standard'], 'Electric Tankless': ['Electric Tankless'], 'Gas Standard': ['Gas Standard'], 'Gas Tankless': ['Gas Tankless'], 'Oil Standard': ['Oil Standard'], 'Propane Standard': ['Propane Standard'], 'Propane Tankless': ['Propane Tankless']}},
                          'Cooking Range': {'Cooking Range': {'Gas, 100% Usage': ['Gas, 80% Usage', 'Gas', 'Gas, 120% Usage'], 'Propane, 100% Usage': ['Propane, 80% Usage', 'Propane', 'Propane, 120% Usage'], 'Electric, 100% Usage': ['Electric, 80% Usage', 'Electric', 'Electric, 120% Usage'], 'None': ['None']}},
                          'Clothes Dryer': {'Clothes Dryer': {'Gas, 100% Usage': ['Gas, 80% Usage', 'Gas', 'Gas, 120% Usage'], 'Propane, 100% Usage': ['Propane, 80% Usage', 'Propane', 'Propane, 120% Usage'], 'Electric, 100% Usage': ['Electric, 80% Usage', 'Electric', 'Electric, 120% Usage'], 'None': ['None']}},
                          'Refrigerator': {'Refrigerator': {1: ['Bottom freezer, EF = 6.7', 'Bottom freezer, EF = 10.2', 'Top freezer, EF = 10.5', 'Bottom freezer, EF = 15.9'], 0: ['None']}},
                          'Lighting': {'Lighting': {1: ['60% CFL', '100% CFL'], 0: ['100% Incandescent']}},
                          'Dishwasher': {'Dishwasher': {1: ['290 Rated kWh, 80% Usage', '290 Rated kWh', '290 Rated kWh, 120% Usage', '318 Rated kWh, 80% Usage', '318 Rated kWh', '318 Rated kWh, 120% Usage'], 0: ['None']}},
                          'Clothes Washer': {'Clothes Washer': {'Standard': ['Standard, 80% Usage', 'Standard', 'Standard, 120% Usage'], 'EnergyStar': ['EnergyStar, 80% Usage', 'EnergyStar', 'EnergyStar, 120% Usage'], 'None': ['None']}},
                          'Misc Extra Refrigerator': {'Extra Refrigerator': {1: ['Top freezer, EF = 6.9, National Average']}},
                          'Misc Freezer': {'Freezer': {1: ['Upright, EF = 12, National Average']}},
                          'Misc Gas Fireplace': {'Gas Fireplace': {1: ['National Average']}},
                          'Misc Gas Grill': {'Gas Grill': {1: ['National Average']}},
                          'Misc Gas Lighting': {'Gas Lighting': {1: ['National Average']}},
                          'Misc Hot Tub Spa': {'Hot Tub/Spa Heater': {1: ['National Average']}},
                          'Misc Pool': {'Pool Heater': {1: ['National Average']}},
                          'Misc Well Pump': {'Well Pump': {1: ['National Average']}},
                          'HVAC System Cooling Central': {'Central Air Conditioner': {1: ['SEER 8', 'SEER 10', 'SEER 13', 'SEER 15'], 0: ['None']}},
                          'HVAC System Cooling Air Source Heat Pump': {'Air Source Heat Pump': {1: ['SEER 10, 6.2 HSPF', 'SEER 13, 7.7 HSPF', 'SEER 15, 8.5 HSPF'], 0: ['None']}},
                          'HVAC System Cooling Room': {'Room Air Conditioner': {1: ['EER 8.5, 20% Conditioned', 'EER 10.7, 20% Conditioned'], 0: ['None']}},
                          'HVAC System Heating Furnace': {'Furnace': {'Electric Furnace': ['Electric, 100% AFUE'], 'Gas Furnace': ['Gas, 60% AFUE', 'Gas, 76% AFUE', 'Gas, 80% AFUE', 'Gas, 92.5% AFUE', 'Gas, 96% AFUE'], 'None': ['None']}},
                          }
  
  con = sqlite3.connect('../../../../BEopt-dev/Build/BEopt/Data/Measures.sqlite')
  category = pd.read_sql_query('SELECT CategoryID, CategoryName from Category', con)
  option = pd.read_sql_query('SELECT OptionName, OptionGUID, CategoryID from Option', con)
  for col_name, values in col_to_category_name.items():
  
    print col_name
    category_id = category[category['CategoryName']==values.keys()[0]]['CategoryID'].values[0]
    df['{} OptionGUID'.format(col_name)] = df[col_name].apply(lambda x: get_guids(values.values()[0], x, option[option['CategoryID']==category_id]))
  
  df.to_csv('recs.csv', index=False)

def get_guids(values, x, option):

  if pd.isnull(x):
    return ''
  
  guids = []
  for value in values[x]:
    
    guids.append(option[option['OptionName']==value]['OptionGUID'].values[0])
  
  return ';'.join([str(x) for x in guids])
  
def assign_epw_stations(df):

  epw = pd.read_csv('RECS_EPW_matches.csv')[['DOEID', 'TMY3_ID', 'ProvState', 'Station', 'HDD65_Annual', 'CDD65_Annual']]
  df = pd.merge(df, epw, left_on='doeid', right_on='DOEID')
  del df['DOEID']

  return df
  
def assign_heating_fuel(df): # Heating fuel

  fuels = {1:'Natural Gas',
           2:'Propane',
           3:'Fuel Oil',
           5:'Electricity',
           4:'Other Fuel',
           7:'Other Fuel',
           8:'Other Fuel',
           9:'Other Fuel',
           21:'Other Fuel',
           -2:'None'}
           
  df['Heating Fuel'] = df['fuelheat'].apply(lambda x: fuels[x])
   
  return df
  
def assign_geometry_house_size(df): # Floor area

  df['Intsize'] = df[['tothsqft', 'totcsqft']].max(axis=1)
  df.loc[:, 'Geometry House Size'] = 0
  df.loc[(df['Intsize'] < 1500), 'Geometry House Size'] = '0-1499'
  df.loc[(df['Intsize'] >= 1500) & (df['Intsize'] < 2500), 'Geometry House Size'] = '1500-2499'
  df.loc[(df['Intsize'] >= 2500) & (df['Intsize'] < 3500), 'Geometry House Size'] = '2500-3499'
  df.loc[(df['Intsize'] >= 3500), 'Geometry House Size'] = '3500+'
  
  del df['Intsize']
  
  return df  
  
def assign_geometry_stories(df): # Number of stories

  stories = {10: '1',
             20: '2+',
             31: '2+',
             32: '2+',
             40: '2+',
             50: np.nan,
             -2: np.nan}
                  
  df['Geometry Stories'] = df['stories'].apply(lambda x: stories[x])

  return df
  
def assign_geometry_garage(df): # Attached garage

  garage = {1: '1 Car',
            2: '2 Car',
            3: '3 Car',
            -2: 'None'}
            
  df['Geometry Garage'] = df['sizeofgarage'].apply(lambda x: garage[x])

  return df
  
def assign_windows(df): # Window type

  typeglass = {1:'1 Pane',
               2:'2+ Pane',
               3:'2+ Pane',
               -2:'None'}
                    
  df['Windows'] = df['typeglass'].apply(lambda x: typeglass[x])
  
  return df
  
def assign_hvac_system_heating(df): # Heating system type # TODO

  def furnace(type, fuel):
    if type == 3 and fuel == 5:
      return 'Electric Furnace'
    elif type == 3 and fuel == 1:
      return 'Gas Furnace'

  df['HVAC System Heating Furnace'] = df['equipm'].apply(lambda x: 1 if x == 3 else 0)
  df['HVAC System Heating Boiler'] = df['equipm'].apply(lambda x: 1 if x == 2 else 0)
  df['HVAC System Heating Electric Baseboard'] = df['equipm'].apply(lambda x: 1 if x == 5 or x == 6 or x == 7 or x == 10 else 0)
  df['HVAC System Heating Air Source Heat Pump'] = df['equipm'].apply(lambda x: 1 if x == 4 else 0)
  
def assign_hvac_system_cooling(df): # Cooling system type

  def central(type, hp):
    if ( type == 1 or type == 3 ) and not hp == 1:
      return 1
    else:
      return 0

  def ashp(type, hp):
    if ( type == 1 or type == 3 ) and hp == 1:
      return 1
    else:
      return 0
      
  df['HVAC System Cooling Central'] = df.apply(lambda x: central(x['cooltype'], x['cenachp']), axis=1)
  df['HVAC System Cooling Air Source Heat Pump'] = df.apply(lambda x: ashp(x['cooltype'], x['cenachp']), axis=1)
  df['HVAC System Cooling Room'] = df['cooltype'].apply(lambda x: 1 if x == 2 or x == 3 else 0)
  
  return df
  
def assign_water_heater(df): # DHW system type

  def wh(fuel, type):
    if fuel == 5 and type == 1:
      return 'Electric Standard'
    elif fuel == 5 and type == 2:
      return 'Electric Tankless'
    elif fuel == 1 and type == 1:
      return 'Gas Standard'
    elif fuel == 1 and type == 2:
      return 'Gas Tankless'
    elif fuel == 3 and type == 1:
      return 'Oil Standard'
    elif fuel == 1 and type == 2:
      return 'Gas Tankless'
    elif fuel == 2 and type == 1:
      return 'Propane Standard'
    elif fuel == 2 and type == 2:
      return 'Propane Tankless'
           
  df['Water Heater'] = df.apply(lambda x: wh(x['fuelh2o'], x['h2otype1']), axis=1)

  return df
  
def assign_cooking_range(df): # Cooking type
           
  def rng(fuel):
    if fuel == 1:
      return 'Gas, 100% Usage'
    elif fuel == 2:
      return 'Propane, 100% Usage'
    elif fuel == 5:
      return 'Electric, 100% Usage'
    else:
      return 'None'
           
  df['Cooking Range'] = df['rngfuel'].apply(lambda x: rng(x))

  return df
  
def assign_clothes_dryer(df): # Clothes dryer type
  
  def cd(fuel):
    if fuel == 1:
      return 'Gas, 100% Usage'
    elif fuel == 2:
      return 'Propane, 100% Usage'
    elif fuel == 5:
      return 'Electric, 100% Usage'
    else:
      return 'None'
           
  df['Clothes Dryer'] = df['dryrfuel'].apply(lambda x: cd(x))
  
  return df
  
def assign_heating_setpoint(df): # Heating set points

  def htgstpt(stpt):
    if stpt > 0 and stpt < 65.5:
      return '63F'
    elif stpt >= 65.5 and stpt < 69.5:
      return '68F'
    elif stpt >= 69.5 and stpt < 72.0:
      return '71F'
    elif stpt >= 72.0:
      return '73F'
    else:
      return np.nan
  
  df['Heating Setpoint'] = df['temphome'].apply(lambda x: htgstpt(x))

  return df
  
def assign_cooling_setpoint(df): # Cooling set points

  def clgstpt(stpt):
    if stpt > 0 and stpt < 71.5:
      return '69F'
    elif stpt >= 71.5 and stpt < 75.0:
      return '74F'
    elif stpt >= 75.0 and stpt < 77.0:
      return '76F'
    elif stpt >= 77.0:
      return '78F'
    else:
      return np.nan
  
  df['Cooling Setpoint'] = df['temphomeac'].apply(lambda x: clgstpt(x))

  return df
  
def assign_lighting(df): # Lighting

  df['Lighting'] = df['instlcfl'].apply(lambda x: 1 if x == 1 else 0)

  return df
  
def assign_refrigerator(df): # Appliances

  df['Refrigerator'] = df['numfrig'].apply(lambda x: 1 if x > 0 else 0)

  return df
  
def assign_clothes_washer(df): # Appliances

  def cl(used, estar):
    if used == 1 and estar == 1:
      return 'EnergyStar'
    elif used == 1:
      return 'Standard'
    else:
      return 'None'
      
  df['Clothes Washer'] = df.apply(lambda x: cl(x['cwasher'], x['escwash']), axis=1)
  
  return df
  
def assign_dishwasher(df): # Appliances

  df['Dishwasher'] = df['dishwash'].apply(lambda x: 1 if x == 1 else 0)

  return df
  
def assign_misc_extra_refrigerator(df): # MELs

  df['Misc Extra Refrigerator'] = 1

  return df
  
def assign_misc_freezer(df): # MELs

  df['Misc Freezer'] = 1

  return df

def assign_misc_gas_fireplace(df): # MELs

  df['Misc Gas Fireplace'] = 1

  return df

def assign_misc_gas_grill(df): # MELs

  df['Misc Gas Grill'] = 1

  return df
  
def assign_misc_gas_lighting(df): # MELs

  df['Misc Gas Lighting'] = 1

  return df
  
def assign_misc_hot_tub_spa(df): # MELs

  df['Misc Hot Tub Spa'] = 1

  return df

def assign_misc_pool(df): # MELs

  df['Misc Pool'] = 1

  return df

def assign_misc_well_pump(df): # MELs

  df['Misc Well Pump'] = 1

  return df
  
def retrieve_data():
  if not os.path.exists('eia.recs_2009_microdata.pkl'):
    con_string = "host = gispgdb.nrel.gov port = 5432 dbname = dav-gis user = jalley password = jalley"
    con =  con = pg.connect(con_string)
    sql = """SELECT * FROM eia.recs_2009_microdata;"""
    df = pd.read_sql(sql, con)
    df.to_pickle('eia.recs_2009_microdata.pkl')
  df = pd.read_pickle('eia.recs_2009_microdata.pkl')

  return df  
  
def regenerate():

  # Use this to regenerate processed data if changes are made to any of the classes below
  df = retrieve_data()
  df.to_pickle('processed_eia.recs_2009_microdata.pkl')
  return df

if __name__ == '__main__':
  
  # Choose regerate if you want to redo the processed pkl file, otherwise comment out
  df = regenerate()

  df = pd.read_pickle('processed_eia.recs_2009_microdata.pkl')
  main(df)
