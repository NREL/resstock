
import os, sys
import pandas as pd
from datetime import datetime
import psycopg2 as pg
import numpy as np
import sqlite3

def main(df):

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

  col_to_category_name = {'Heating Setpoint': 'Heating Set Point'} # TODO: complete this dictionary
  
  con = sqlite3.connect("../../../../BEopt-dev/trunk/Data/Measures.sqlite")
  category = pd.read_sql_query('SELECT CategoryID, CategoryName from Category', con)
  option = pd.read_sql_query('SELECT OptionName, OptionGUID, CategoryID from Option', con)
  for col in ['Heating Setpoint']:
    if not set(df[col].unique()) < set(option['OptionName']):
      continue
    category_id = category[category['CategoryName']==col_to_category_name[col]]['CategoryID'].values
    assert len(category_id) == 1
    df = pd.merge(df, option[option['CategoryID']==category_id[0]], how='left', left_on=col, right_on='OptionName')
    df = df.rename(columns={'OptionGUID': '{} OptionGUID'.format(col)})
    del df['CategoryID']
    del df['OptionName']
  
  df.to_csv('recs.csv', index=False)

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

  # TODO: did we just copy Windows.tsv from pnw?
  
  return df
  
def assign_hvac_system_heating(df): # Heating system type

  # TODO: how was this tsv created?
  df['Heating Setpoint'] = np.random.choice(['70 F', '71 F', '72 F'], df.shape[0])

  return df
  
def assign_hvac_system_cooling(df): # Cooling system type

  # TODO: how was this tsv created?

  return df
  
def assign_water_heater(df): # DHW system type

  # TODO: how was this tsv created?

  return df
  
def assign_cooking_range(df): # Cooking type

  # TODO: how was this tsv created?

  return df
  
def assign_clothes_dryer(df): # Clothes dryer type
  
  # TODO: how was this tsv created?
  
  return df
  
def assign_heating_setpoint(df): # Heating set points

  # TODO: how was this tsv created?

  return df
  
def assign_cooling_setpoint(df): # Cooling set points

  # TODO: how was this tsv created?

  return df
  
def assign_lighting(df): # Lighting

  # TODO: how was this tsv created?

  return df
  
def assign_refrigerator(df): # Appliances

  # TODO: how was this tsv created?

  return df
  
def assign_clothes_washer(df): # Appliances

  # TODO: how was this tsv created?
  
  return df
  
def assign_dishwasher(df): # Appliances

  # TODO: how was this tsv created?

  return df
  
def assign_misc_extra_refrigerator(df): # MELs

  # TODO: how was this tsv created?

  return df
  
def assign_misc_freezer(df): # MELs

  # TODO: how was this tsv created?

  return df

def assign_misc_gas_fireplace(df): # MELs

  # TODO: how was this tsv created?

  return df

def assign_misc_gas_grill(df): # MELs

  # TODO: how was this tsv created?

  return df
  
def assign_misc_gas_lighting(df): # MELs

  # TODO: how was this tsv created?

  return df
  
def assign_misc_hot_tub_spa(df): # MELs

  # TODO: how was this tsv created?

  return df

def assign_misc_pool(df): # MELs

  # TODO: how was this tsv created?

  return df

def assign_misc_well_pump(df): # MELs

  # TODO: how was this tsv created?

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
