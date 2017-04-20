import os
import sys
import pandas as pd
import numpy as np
import time
import argparse
import warnings
from joblib import Parallel, delayed
import multiprocessing
from odo import odo
import gc
import shutil
from memory_profiler import profile
warnings.filterwarnings('ignore')

def main(output_file, tsv_file, chunk_size):

  post_process_with_option_fracs(output_file, tsv_file, chunk_size)

@profile
def post_process_with_option_fracs(output_file, tsv_file, chunk_size):

  tsv = pd.read_csv(tsv_file, sep='\t')
  on = []
  for col in tsv.columns:
    if 'Dependency=' in col:
      tsv = tsv.rename(columns={col: col.replace('Dependency=', 'building_characteristics_report.')})
      on.append(col.replace('Dependency=', 'building_characteristics_report.'))
  
  predicted = pd.read_csv(output_file)
  
  # TODO: following is temp code until we can successfully run the national analysis with all the updated tsv files
  predicted['building_characteristics_report.Location Census Division'] = np.random.choice(['New England', 'East North Central', 'Middle Atlantic', 'Mountain - Pacific', 'South Atlantic - East South Central', 'West North Central', 'West South Central'], predicted.shape[0])
  predicted['building_characteristics_report.HVAC System Cooling Type'] = np.random.choice(['Central', 'Room', 'None'], predicted.shape[0])
  predicted['simulation_output_report.weight'] = 4000
  #
  
  try:
    predicted = predicted.merge(tsv, on=on, how='left')
  except KeyError as ke:
    sys.exit('Column {} does not exist in {}.'.format(ke, os.path.basename(output_file)))
  
  id_vars = []
  value_vars = []
  for col in predicted.columns:
    if 'Option=' in col:
      value_vars.append(col)
    else:
      id_vars.append(col)    
  
  predicted = predicted.fillna(1.0 / len(value_vars)) # evenly distribute in case there weren't any matches on the merge
  
  dfs = np.array_split(predicted, int(predicted.shape[0] / chunk_size))
  
  if os.path.exists('h5s'):
    shutil.rmtree('h5s')
  os.mkdir('h5s')
  h5s = parallelize(dfs, batch_melt, id_vars, value_vars, tsv_file)
 
  # approach #1: make one hdf5 file and then read it into pandas dataframe
  # for h5 in h5s:
    # print ' ... appending chunk {}'.format(h5)
    # odo('hdfstore://{}::df'.format(h5), 'hdfstore://h5s/df.h5::df')  
  # with pd.HDFStore('h5s/df.h5') as hdf: 
    # predicted = hdf['df']
  # predicted = predicted.set_index('name')
  # predicted.to_csv(output_file.replace(output_file, '{}_expanded.csv'.format(output_file.replace('.csv', ''))))    
  
  # approach #2: read each hdf5 file into pandas dataframe and append to large pandas dataframe
  # predicted = pd.DataFrame()
  # for h5 in h5s:
    # print ' ... appending chunk {}'.format(h5)
    # with pd.HDFStore(h5) as hdf:
      # predicted = pd.concat([predicted, hdf['df']])
  # predicted = predicted.set_index('name')
  # predicted.to_csv(output_file.replace(output_file, '{}_expanded.csv'.format(output_file.replace('.csv', ''))))

  # approach #3: read each hdf5 file into pandas dataframe and append directly to csv
  with open(output_file.replace(output_file, '{}_expanded.csv'.format(output_file.replace('.csv', ''))), 'w') as f:
    for h5 in h5s:
      # for item in gc.get_objects():
        # if sys.getsizeof(item) > 1000*1000:
          # print item, sys.getsizeof(item)
      with pd.HDFStore(h5) as hdf:
        hdf['df'].set_index('name').to_csv(f)
        del hdf['df']
        hdf.close()
  
  try:
    shutil.rmtree('h5s')
  except:
    pass
          
def parallelize(dfs, func, id_vars, value_vars, tsv_file):
  list = Parallel(n_jobs=multiprocessing.cpu_count())(delayed(func)(df, id_vars, value_vars, tsv_file, i) for i, df in enumerate(dfs))
  return list
          
def batch_melt(df, id_vars, value_vars, tsv_file, i):
  h5 = 'h5s/{}.h5'.format(i+1)
  print ' ... melting chunk {}'.format(h5)  
  with pd.HDFStore(h5, mode='w') as hdf:
    melted = pd.melt(df, id_vars=id_vars, value_vars=value_vars, var_name='building_characteristics_report.{}'.format(os.path.basename(tsv_file).replace('.tsv', '')), value_name='frac')
    
    melted['building_characteristics_report.{}'.format(os.path.basename(tsv_file).replace('.tsv', ''))] = melted['building_characteristics_report.{}'.format(os.path.basename(tsv_file).replace('.tsv', ''))].str.replace('Option=', '')
    
    # TODO: do we have own vs rent for recs data?
    melted['building_characteristics_report.{}'.format(os.path.basename(tsv_file).replace('.tsv', ''))] = melted['building_characteristics_report.{}'.format(os.path.basename(tsv_file).replace('.tsv', ''))].str.replace('Own, ', '')
    melted['building_characteristics_report.{}'.format(os.path.basename(tsv_file).replace('.tsv', ''))] = melted['building_characteristics_report.{}'.format(os.path.basename(tsv_file).replace('.tsv', ''))].str.replace('Rent, ', '')
    #
    
    del melted['Count']
    del melted['Weight']
    
    for col in melted.columns:
      if col.endswith('.weight') or col.endswith('MBtu') or col.endswith('kWh') or col.endswith('therm'):
        melted[col] *= melted['frac'].values
    
    melted.to_hdf(hdf, 'df', append=True)
    hdf.close()
  return h5
          
if __name__ == '__main__':

  t0 = time.time()
  
  parser = argparse.ArgumentParser()
  parser.add_argument('--output_file', default= '../analysis_results/resstock_national.csv', help='Relative path of the output csv file.')
  parser.add_argument('--tsv_file', default='../resources/inputs/national/Federal Poverty Level.tsv', help='Relative path of the tsv file.')
  parser.add_argument('--chunk_size', default=500.0, help='Number of rows to melt at a time.')
  args = parser.parse_args()

  main(args.output_file, args.tsv_file, args.chunk_size)
  
  print "All done! Completed rows in {0:.2f} seconds on".format(time.time()-t0), time.strftime("%Y-%m-%d %H:%M")
