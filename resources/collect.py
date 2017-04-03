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
warnings.filterwarnings('ignore')

def main(dir, format):

  if format == 'zip':
  
    process_into_zip(dir)
    
  elif format == 'hdf5':
  
    process_into_hdf5(dir)

def process_into_zip(dir):

  with zipfile.ZipFile('data_points.zip', 'w', zipfile.ZIP_DEFLATED) as new_zf:
  
    for item in os.listdir(dir):
    
      if not item.endswith(".zip"):
        continue
        
      with zipfile.ZipFile(os.path.join(dir, item), 'r') as old_zf:
              
        new_zf.writestr("{}.csv".format(uuid.uuid1()), old_zf.read('enduse_timeseries.csv')) # TODO: get actual uuid from where?
      
      # print len(new_zf.namelist())
      
  print "Created new zip file containing {} csv files.".format(len(new_zf.namelist()))
  new_zf.close()

def process_into_hdf5(dir):

  datapoint_ids = pd.DataFrame(columns=['datapoint', 'datapoint_id'])
  enduse_ids = pd.DataFrame(columns=['enduse', 'enduse_id'])
  # timestamp_ids = pd.DataFrame(columns=['timestamp', 'timestamp_id'])
  
  with pd.HDFStore('data_points.h5', mode='w') as hdf:
  
    for item in os.listdir(dir):
    
      if not item.endswith(".zip"):
        continue
    
      with zipfile.ZipFile(os.path.join(dir, item), 'r') as old_zf:
        
        df = pd.read_csv(old_zf.open('enduse_timeseries.csv'))
        df.columns = [re.sub(r"[^\w\s]", '_', col).replace(' ', '').rstrip('_') for col in df.columns]
        
        # enduse_id
        enduses = [col for col in df.columns if not 'Time' in col]
        for enduse in enduses:
          if not enduse in enduse_ids['enduse'].values:
            next_id = len(enduse_ids.index) + 1
            enduse_ids.loc[next_id] = [enduse, str(next_id)]
        df = df.rename(columns=dict(zip(enduse_ids['enduse'], enduse_ids['enduse_id'])))
        
        # datapoint_id
        datapoint = str(uuid.uuid1()) # TODO: get actual uuid from where?        
        if not datapoint in datapoint_ids['datapoint'].values:
          next_id = len(datapoint_ids.index) + 1
          datapoint_ids.loc[next_id] = [datapoint, str(next_id)]
        df.insert(0, 'datapoint_id', next_id)
        
        # timestamp_id
        # if timestamp_ids.empty:
          # for i, timestamp in enumerate(df['Time']):
            # timestamp_ids.loc[i] = [timestamp, str(i + 1)]
        # df = df.replace({'Time': dict(zip(timestamp_ids['timestamp'].values, timestamp_ids['timestamp_id'].values))})
        
        df = pd.melt(df, id_vars=['datapoint_id', 'Time'], var_name='enduse_id')
        df = df.set_index('datapoint_id')
   
        df.to_hdf(hdf, 'df', complib='bzip2', complevel=9, format='table', append=True) # complib='zlib'? something else?
        print hdf
      
    datapoint_ids.to_hdf(hdf, 'datapoint_ids', complib='bzip2', complevel=9)
    enduse_ids.to_hdf(hdf, 'enduse_ids', complib='bzip2', complevel=9)
    # timestamp_ids.to_hdf(hdf, 'timestamp_ids', complib='bzip2', complevel=9)
    
    print hdf    
    print "Created new hdf5 file containing {} groups.".format(len(hdf.keys()))
    
if __name__ == '__main__':

  t0 = time.time()
  
  parser = argparse.ArgumentParser()
  parser.add_argument('--directory', default='../analysis_results/data_points', help='Relative path containing the data_point.zip files.')
  formats = ['zip', 'hdf5']
  parser.add_argument('--format', choices=formats, default='hdf5', help='Desired format of the stored output csv files.')   
  args = parser.parse_args()

  main(args.directory, args.format)
  
  print "All done! Completed rows in {0:.2f} seconds on".format(time.time()-t0), time.strftime("%Y-%m-%d %H:%M")
