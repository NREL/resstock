import os
import sys
import pandas as pd
import numpy as np
import time
import argparse
import warnings
from memory_profiler import profile
warnings.filterwarnings('ignore')
from configparser import ConfigParser
from sqlalchemy import create_engine
 
def config(filename='buildstock.ini', section='postgresql'):
  # create a parser
  parser = ConfigParser()
  # read config file
  parser.read(filename)

  # get section, default to postgresql
  db = {}
  if parser.has_section(section):
    params = parser.items(section)
    for param in params:
      db[param[0]] = param[1]
  else:
    raise Exception('Section {0} not found in the {1} file'.format(section, filename))

  return db

def main(output_file, tsv_file, func, chunk_size):

  # read connection parameters
  params = config()

  # connect to the PostgreSQL server
  print 'Connecting to the PostgreSQL database...'  
  engine = create_engine('postgresql://{user}:{password}@{host}:{port}/{database}'.format(**params))

  if func == 'write':

    db_writes(engine, output_file, tsv_file, chunk_size)
  
  else:
  
    states = ['WI', 'IL', 'IN', 'MI', 'OH', 'NY', 'PA', 'NJ', 'ME', 'NH', 'VT', 'MA', 'CT', 'RI', 'ND', 'SD', 'NE', 'KS', 'MN', 'IA', 'MO', 'TX', 'OK', 'AR', 'LA', 'WA', 'OR', 'CA', 'NV', 'ID', 'MT', 'WY', 'CO', 'UT', 'AZ', 'NM', 'WV', 'MD', 'DE', 'DC', 'VA', 'NC', 'SC', 'GA', 'FL', 'KY', 'TN', 'MS', 'AL']
    tables = ['Federal Poverty Level', 'Geometry House Size', 'Vintage']
    tables = ['Geometry House Size']
    bins = ['Own, 0-50', 'Own, 50-100', 'Own, 100-150', '0-1499', '1500-2499', '2500-3499', '3500+', '<1950', '1950s', '1960s', '1970s', '1980s', '1990s']
    enduses = ['simulation_output_report.Total Site Energy MBtu']
    
    db_reads(engine, states, tables, bins, enduses)

# @profile
def db_writes(engine, output_file, tsv_file, chunk_size):

  tsv = pd.read_csv(tsv_file, sep='\t')
  on = []
  for col in tsv.columns:
    if 'Dependency=' in col:
      tsv = tsv.rename(columns={col: col.replace('Dependency=', 'building_characteristics_report.')})
      on.append(col.replace('Dependency=', 'building_characteristics_report.'))
  
  predicted = pd.read_csv(output_file)
  
  predicted['ST'] = predicted['building_characteristics_report.Location EPW'].apply(lambda x: x.split('_')[1])
  
  # TODO: following is temp code until we can successfully run the national analysis with all the updated tsv files
  predicted['building_characteristics_report.Location Census Division'] = np.random.choice(['New England', 'East North Central', 'Middle Atlantic', 'Mountain - Pacific', 'South Atlantic - East South Central', 'West North Central', 'West South Central'], predicted.shape[0])
  predicted['building_characteristics_report.HVAC System Cooling Type'] = np.random.choice(['Central', 'Room', 'None'], predicted.shape[0])
  predicted['simulation_output_report.weight'] = 4000
  #
  
  try:
    predicted = predicted.merge(tsv, on=on, how='left')
  except KeyError as ke:
    sys.exit('Column {} does not exist in {}.'.format(ke, os.path.basename(output_file)))
  
  char_vars = []
  res_vars = []
  frac_vars = []
  for col in predicted.columns:
    if 'Option=' in col:
      frac_vars.append(col)
    elif not col in ['Count', 'Weight']:
      if col.startswith('simulation_output_report.'):
        res_vars.append(col)
      else:
        char_vars.append(col)

  # characteristics table
  print 'Creating table: characteristics'
  predicted[char_vars].set_index('_id').to_sql('characteristics', engine, if_exists='replace')
  
  # results table
  print 'Creating table: results'
  predicted[['_id'] + res_vars].set_index('_id').to_sql('results', engine, if_exists='replace')
  
  # weights table
  print 'Creating table: {}'.format(os.path.basename(tsv_file).replace('.tsv', ''))
  for col in predicted[frac_vars].columns:
    predicted = predicted.rename(columns={col: col.replace('Option=', '')})
  frac_vars = [col.replace('Option=', '') for col in frac_vars]
  predicted[['_id'] + frac_vars].set_index('_id').to_sql(os.path.basename(tsv_file).replace('.tsv', ''), engine, if_exists='replace')
  
def db_reads(engine, states=['CO'], tables=['Federal Poverty Level'], bins=['Own, 0-50'], enduses=['simulation_output_report.Total Site Energy MBtu']):

  char = pd.read_sql_table('characteristics', engine, index_col='_id')

  # apply filter(s)
  char = char[char['ST'].isin(states)]
  chars_already_sampled = char.columns
  char = char[['ST']]  
  
  # get results
  enduses.append('simulation_output_report.weight')
  results = pd.read_sql_table('results', engine, index_col='_id')
  results = char.join(results[enduses])
  
  # get weights
  for table in tables:
    
    for bin in bins:
    
      if not bin in weights.columns:
        continue

      if not 'building_characteristics_report.{}'.format(table) in chars_already_sampled: # new characteristic
        
        weights = pd.read_sql_table(table, engine, index_col='_id')
        table = weights[[bin]]
        table = results.join(table)

      else: # characteristic was already sampled
      
        table = results
        table[bin] = 1
        
      # apply weights
      for enduse in enduses:
        table[enduse] *= table[bin]
      
      del table[bin]
      
      table['count'] = 1      
      
      wm = lambda x: np.average(x, weights=table.loc[x.index, 'simulation_output_report.weight'])
      f = {'simulation_output_report.weight': np.sum, 'count': np.sum}
      for enduse in enduses:
        if enduse.endswith('.weight'):
          continue

        table['{} per house'.format(enduse)] = table[enduse]
          
        f[enduse] = np.sum
        f['{} per house'.format(enduse)] = wm
    
      print 'Creating table: {}, aggregated by ST'.format(bin)
      table.groupby('ST').agg(f).to_sql(bin, engine, if_exists='replace')
      
      print table.groupby('ST').agg(f).sum()
          
if __name__ == '__main__':

  t0 = time.time()
  
  parser = argparse.ArgumentParser()
  parser.add_argument('--output_file', default= '../analysis_results/resstock_national.csv', help='Relative path of the output csv file.')
  parser.add_argument('--tsv_file', default='../project_resstock_national/housing_characteristics/Federal Poverty Level.tsv', help='Relative path of the tsv file.')
  parser.add_argument('--function', default='write', help='Create the db or query it.')
  parser.add_argument('--chunk_size', default=500.0, help='Size of chunk.')
  args = parser.parse_args()

  main(args.output_file, args.tsv_file, args.function, args.chunk_size)
  
  print "All done! Completed rows in {0:.2f} seconds on".format(time.time()-t0), time.strftime("%Y-%m-%d %H:%M")
