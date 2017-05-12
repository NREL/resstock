import os
import sys
import pandas as pd
import numpy as np
import time
import argparse
import zipfile
import uuid
import re
import warnings
import csv
import h5py
warnings.filterwarnings('ignore')
import shutil

def main(dir, format, package, func, file):

  if func == 'write':
    if format == 'zip':    
      write_zip(dir)      
    elif format == 'hdf5':    
      if package == 'pandas':    
        write_pandas_hdf5(dir, file)      
      elif package == 'h5py':      
        write_h5py_hdf5(dir, file)      
  elif func == 'read':  
    if format == 'zip':    
      print "Haven't written this code yet."      
    elif format == 'hdf5':
      if package == 'pandas':    
        read_pandas_hdf5(dir, file)        
      elif package == 'h5py':      
        read_h5py_hdf5(dir, file)

def write_zip(dir):

  with zipfile.ZipFile('data_points.zip', 'w', zipfile.ZIP_DEFLATED) as new_zf:
  
    for item in os.listdir(dir):
    
      if not item.endswith('.zip'):
        continue
        
      with zipfile.ZipFile(os.path.join(dir, item), 'r') as old_zf:
              
        new_zf.writestr("{}.csv".format(uuid.uuid1()), old_zf.read('enduse_timeseries.csv')) # TODO: get actual uuid from where?
      
      # print len(new_zf.namelist())
      
  print "Created new zip file containing {} csv files.".format(len(new_zf.namelist()))
  new_zf.close()

def write_pandas_hdf5(dir, file):

  datapoint_ids = pd.DataFrame(columns=['datapoint', 'datapoint_id'])
  enduse_ids = pd.DataFrame(columns=['enduse', 'enduse_id'])
  
  with pd.HDFStore(file, mode='w', complib='zlib', complevel=9) as hdf:
  
    for item in os.listdir(dir):
    
      if not item.endswith('.zip'):
        continue
    
      print os.path.join(dir, item)
      
      folder_zf = zipfile.ZipFile(os.path.join(dir, item))
      
      for datapoint in folder_zf.namelist():
      
        if datapoint.endswith('results.csv'):
          folder_zf.extract(datapoint, dir)
          chars = pd.read_csv(os.path.join(dir, datapoint), index_col='_id')
          chars = chars.dropna(axis=1, how='all')
      
        if not datapoint.endswith('.zip'):
          continue
        
        folder_zf.extract(datapoint, dir)
        
        with zipfile.ZipFile(os.path.join(dir, datapoint), 'r') as data_point_zf:
      
          df = pd.read_csv(data_point_zf.open('enduse_timeseries.csv'))
          df.columns = [re.sub(r"[^\w\s]", '_', col).replace(' ', '').rstrip('_') for col in df.columns]

          # enduse_id
          enduses = [col for col in df.columns if not 'Time' in col]
          for enduse in enduses:
            if not enduse in enduse_ids['enduse'].values:
              next_id = len(enduse_ids.index) + 1
              enduse_ids.loc[next_id] = [enduse, str(next_id)]
          df = df.rename(columns=dict(zip(enduse_ids['enduse'], enduse_ids['enduse_id'])))
          
          # datapoint_id
          m = re.search('([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})', datapoint)
          if m:
            datapoint_id = m.group(1)
          if not datapoint_id in datapoint_ids['datapoint'].values:
            next_id = len(datapoint_ids.index) + 1
            datapoint_ids.loc[next_id] = [datapoint_id, str(next_id)]
          df.insert(0, 'datapoint_id', next_id)
          
          df = pd.melt(df, id_vars=['datapoint_id', 'Time'], var_name='enduse_id')
          df = df.set_index('datapoint_id')

          df.to_hdf(hdf, 'df', format='table', append=True)

        shutil.rmtree(os.path.join(dir, os.path.dirname(datapoint)))
      
    datapoint_ids.set_index('datapoint_id').to_hdf(hdf, 'datapoint_ids', format='table')
    enduse_ids.set_index('enduse_id').to_hdf(hdf, 'enduse_ids', format='table')
    chars.to_hdf(hdf, 'characteristics', format='table')
    
    print hdf
    print "Created new hdf5 file containing {} groups.".format(len(hdf.keys()))
    
def write_h5py_hdf5(dir, file):
  
  with h5py.File(file, mode='w') as hdf:
  
    for item in os.listdir(dir):
    
      if not item.endswith(".zip"):
        continue
    
      with zipfile.ZipFile(os.path.join(dir, item), 'r') as old_zf:
        
        csv_file = csv.reader(old_zf.open('enduse_timeseries.csv'))
        header = csv_file.next()
        lines = list(csv_file)
      
      df = hdf.create_dataset(str(uuid.uuid1()), data=lines, compression='gzip', compression_opts=9)
        
      df.attrs['column_names'] = header
    
    print hdf
    print "Created new hdf5 file containing {} groups.".format(len(hdf.keys()))
    
def read_pandas_hdf5(dir, file):
    
  with pd.HDFStore(file) as hdf: 
    
    for key in hdf.keys():
      # print hdf[key].head()
      # print hdf[key].shape
      print hdf[key]
    
def read_h5py_hdf5(dir, file):

  with h5py.File(file, mode='r') as hdf:
    
    datapoint_ids = 0
    nrows = 0
    
    for group in hdf:
        
      # for attr in hdf[group].attrs:
        
        # print hdf[group].attrs[attr]
              
      datapoint_ids += 1
      nrows += hdf[group].shape[0]
        
    print datapoint_ids, nrows
          
if __name__ == '__main__':

  t0 = time.time()
  
  parser = argparse.ArgumentParser()
  parser.add_argument('--directory', default='../analysis_results/data_points', help='Relative path containing the data_point.zip files.')
  formats = ['zip', 'hdf5']
  parser.add_argument('--format', choices=formats, default='hdf5', help='Desired format of the stored output csv files.')
  packages = ['pandas', 'h5py']
  parser.add_argument('--package', choices=packages, default='pandas', help='HDF5 tool.')
  functions = ['read', 'write']
  parser.add_argument('--function', choices=functions, default='write', help='Read or write.')
  parser.add_argument('--file', default='data_points.h5', help='Name of the existing hdf5 file.')
  args = parser.parse_args()

  main(args.directory, args.format, args.package, args.function, args.file)
  
  print "All done! Completed rows in {0:.2f} seconds on".format(time.time()-t0), time.strftime("%Y-%m-%d %H:%M")
