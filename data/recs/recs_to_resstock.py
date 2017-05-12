
import os, sys
import pandas as pd
from datetime import datetime
import psycopg2 as pg
import numpy as np
import sqlite3

con = sqlite3.connect('../../../../BEopt-dev/Build/BEopt/Data/Measures.sqlite')
Category = pd.read_sql_query('SELECT CategoryID, CategoryName from Category', con)
Option = pd.read_sql_query('SELECT OptionGUID, OptionName from Option', con)

con = sqlite3.connect('../../../../Users/jrobert1/Downloads/Output_2016-01-27_1m_EPSA_LEDDWCW.sqlite/Output.sqlite')
BEoptCategoryDependency = pd.read_sql_query('SELECT * from BEoptCategoryDependency', con)
MetaCategory = pd.read_sql_query('SELECT * from MetaCategory', con)
MetaOption = pd.read_sql_query('SELECT ID, MetaCategoryID, Name from MetaOption', con)
MetaOptionCombo = pd.read_sql_query('SELECT * from MetaOptionCombo', con)
OutputArchetypeVariant = pd.read_sql_query('SELECT * from OutputArchetypeVariant', con)
BEoptWeightingFactor = pd.read_sql_query('SELECT * from BEoptWeightingFactor', con)
EPWs = MetaOption[MetaOption['MetaCategoryID']==1]['Name'].values

def main(df):

  # meta
  df = assign_epw_stations(df)
  df = assign_location(df)
  df = assign_vintage(df)
  df = assign_heating_fuel(df)
  df = assign_size(df)
  df = assign_stories(df)
  df = assign_foundation_type(df)
  df = assign_daytime_occupancy(df)
  df = assign_usage_level(df)
  df = assign_attached_garage(df)
  
  # extra
  # df = assign_heating_setpoint(df) # TODO: has no dependencies in appdata.sqlite
  # df = assign_cooling_setpoint(df) # TODO: has no dependencies in appdata.sqlite

  # beopt
  df = assign_variant_ids(df, con)
  # for option in ['Water Heater', 'Windows', 'Cooking Range', 'Clothes Dryer', 'Refrigerator', 'Lighting', 'Dishwasher', 'Clothes Washer', 'Central Air Conditioner', 'Room Air Conditioner', 'Furnace', 'Boiler', 'Electric Baseboard', 'Air Source Heat Pump']:
    # print option
    # df = assign_option_guids(df, con, option)
  
  df.to_csv('recs.csv', index=False)
  
def assign_epw_stations(df):

  epw = pd.read_csv('RECS_EPW_matches.csv')[['DOEID', 'TMY3_ID', 'ProvState', 'Station', 'HDD65_Annual', 'CDD65_Annual']]
  df = pd.merge(df, epw, left_on='doeid', right_on='DOEID')
  del df['DOEID']

  return df
  
def assign_location(df): # Location

  def epw(tmy3_id):
    for EPW in EPWs:
      if str(tmy3_id) in str(EPW):
        return EPW

  df['Location'] = df['TMY3_ID'].apply(lambda x: epw(x))

  return df
 
def assign_vintage(df): # Vintage

  vintages = {1: 'pre-1950',
              2: '1950s',
              3: '1960s',
              4: '1970s',
              5: '1980s',
              6: '1990s',
              7: '2000s',
              8: '2000s'}
              
  df['Vintage'] = df['yearmaderange'].apply(lambda x: vintages[x])  
   
  return df 
 
def assign_heating_fuel(df): # Heating fuel

  fuels = {1:'Natural Gas',
           2:'Propane/LPG',
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
  
def assign_size(df): # Floor area
  
  df['Intsize'] = df[['tothsqft', 'totcsqft']].max(axis=1)
  df.loc[:, 'Size'] = 0
  df.loc[(df['Intsize'] < 1500), 'Size'] = '0-1499'
  df.loc[(df['Intsize'] >= 1500) & (df['Intsize'] < 2500), 'Size'] = '1500-2499'
  df.loc[(df['Intsize'] >= 2500) & (df['Intsize'] < 3500), 'Size'] = '2500-3499'
  df.loc[(df['Intsize'] >= 3500) & (df['Intsize'] < 4500), 'Size'] = '3500-4499'
  df.loc[(df['Intsize'] >= 4500), 'Size'] = '4500+'
  
  del df['Intsize']
  
  return df 
  
def assign_stories(df): # Number of stories

  stories = {10: '1',
             20: '2',
             31: '3+',
             32: '3+',
             40: '2',
             50: '1;2;3+',
             -2: '1;2;3+'}
                  
  df['Stories'] = df['stories'].apply(lambda x: stories[x])

  return df
  
def assign_foundation_type(df):

	def assign_foundation(crawl, cellar, concrete, baseheat):
	
		foundations = []
		if crawl == 1:
			foundations.append('Crawl')
		if concrete == 1:
			foundations.append('Slab')
		if cellar == 1 and baseheat == 1:
			foundations.append('Heated Basement')
		if cellar == 1 and baseheat == 0:
			foundations.append('Unheated Basement')
		if len(foundations) == 0:
			foundations.append('None')
		
		return ';'.join([str(x) for x in foundations])

	df['Foundation Type'] = df.apply(lambda x: assign_foundation(x['crawl'], x['cellar'], x['concrete'], x['baseheat']), axis=1)

	return df

def assign_daytime_occupancy(df):
  
    df['Daytime Occupancy'] = 'No;Yes;Average'
  
    return df
  
def assign_usage_level(df): # Usage level

    df['Usage Level'] = 'Low;Medium;High;Average'
  
    return df
  
def assign_attached_garage(df): # Attached garage

    garage = {1: 'No;Yes',
              2: 'No;Yes',
              3: 'No;Yes',
              -2: 'No;Yes'}
            
    df['Attached Garage'] = df['sizeofgarage'].apply(lambda x: garage[x])

    return df  
  
def assign_heating_setpoint(df): # Heating set points

  def htgstpt(stpt):
    if stpt > 0 and stpt < 65.5:
      return Option[Option['OptionName']=='63 F']['OptionGUID'].values[0]
    elif stpt >= 65.5 and stpt < 69.5:
      return Option[Option['OptionName']=='68 F']['OptionGUID'].values[0]
    elif stpt >= 69.5 and stpt < 72.0:
      return Option[Option['OptionName']=='71 F']['OptionGUID'].values[0]
    elif stpt >= 72.0:
      return Option[Option['OptionName']=='73 F']['OptionGUID'].values[0]
    else:
      return np.nan
  
  df['Heating Set Point'] = df['temphome'].apply(lambda x: htgstpt(x))

  return df
  
def assign_cooling_setpoint(df): # Cooling set points

  def clgstpt(stpt):
    if stpt > 0 and stpt < 71.5:
      return Option[Option['OptionName']=='69 F']['OptionGUID'].values[0]
    elif stpt >= 71.5 and stpt < 75.0:
      return Option[Option['OptionName']=='74 F']['OptionGUID'].values[0]
    elif stpt >= 75.0 and stpt < 77.0:
      return Option[Option['OptionName']=='76 F']['OptionGUID'].values[0]
    elif stpt >= 77.0:
      return Option[Option['OptionName']=='78 F']['OptionGUID'].values[0]
    else:
      return np.nan
  
  df['Cooling Set Point'] = df['temphomeac'].apply(lambda x: clgstpt(x))

  return df  
  
def assign_option_guids(df, con, option):

  def iter(row, category_id, meta_category_dependency_ids):

    IDs = {}
    for meta_category_dependency_id in meta_category_dependency_ids:
    
      meta_option = MetaOption[(MetaOption['MetaCategoryID']==meta_category_dependency_id) & (MetaOption['Name']==row[MetaCategory[MetaCategory['ID']==meta_category_dependency_id]['Name'].values[0]])]

      IDs['MetaOptionIDForMetaCategoryID{}'.format(meta_category_dependency_id)] = [meta_option['ID'].values[0]]
    
    meta_option_combo = MetaOptionCombo
    
    for i in range(1, 10):
      if 'MetaOptionIDForMetaCategoryID{}'.format(i) in IDs.keys():
        meta_option_combo = meta_option_combo[meta_option_combo['MetaOptionIDForMetaCategoryID{}'.format(i)]==IDs['MetaOptionIDForMetaCategoryID{}'.format(i)]]
      else:
        meta_option_combo = meta_option_combo[pd.isnull(meta_option_combo['MetaOptionIDForMetaCategoryID{}'.format(i)])]

    meta_option_combo_id = meta_option_combo['ID'].values[0]
    
    beopt_weighting_factor = BEoptWeightingFactor[BEoptWeightingFactor['MetaOptionComboID']==meta_option_combo_id]
    beopt_weighting_factor = beopt_weighting_factor[beopt_weighting_factor['CategoryID']==category_id]
    
    beopt_weighting_factor = beopt_weighting_factor[beopt_weighting_factor['Value']>0.0001] # don't include the options that aren't sampled

    return ';'.join([str(x) for x in beopt_weighting_factor['OptionGUID'].values])
  
  category_id = Category[Category['CategoryName']==option]['CategoryID'].values[0]
  
  meta_category_dependency_ids = BEoptCategoryDependency[BEoptCategoryDependency['CategoryID']==category_id]['MetaCategoryDependencyID']  
  
  df[option] = df.apply(lambda x: iter(x, category_id, meta_category_dependency_ids), axis=1)
  
  return df
  
def assign_variant_ids(df, con):
  
  def iter(row, meta_category_dependency_ids):

    IDs = {}
    for meta_category_dependency_id in meta_category_dependency_ids:
    
      params = []
      for param in row[MetaCategory[MetaCategory['ID']==meta_category_dependency_id]['Name']].values[0].split(';'):
		params.append(param)

      meta_option = MetaOption[(MetaOption['MetaCategoryID']==meta_category_dependency_id) & (MetaOption['Name'].isin(params))]

      IDs['MetaOptionIDForMetaCategoryID{}'.format(meta_category_dependency_id)] = meta_option['ID'].tolist()
    
    output_archetype_variant = OutputArchetypeVariant
    
    for i in range(1, 10):
      output_archetype_variant = output_archetype_variant[output_archetype_variant['MetaOptionIDForMetaCategoryID{}'.format(i)].isin(IDs['MetaOptionIDForMetaCategoryID{}'.format(i)])]
	
    return ';'.join([str(x) for x in output_archetype_variant['ID'].values])
  
  meta_category_dependency_ids = range(1, 10)
  
  df['OutputArchetypeVariantID'] = df.apply(lambda x: iter(x, meta_category_dependency_ids), axis=1)
  
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
