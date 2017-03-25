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
              
        new_zf.writestr("{}.csv".format(uuid.uuid1()), old_zf.read('enduse_timeseries.csv')) # TODO: get actual uuid from metadata
      
      print len(new_zf.namelist())
      
  print "Created new zip file containing {} csv files.".format(len(new_zf.namelist()))
  new_zf.close()

def process_into_hdf5(dir):
  
  with pd.HDFStore('data_points.h5', mode='w') as hdf:
  
    for item in os.listdir(dir):
    
      if not item.endswith(".zip"):
        continue
    
      with zipfile.ZipFile(os.path.join(dir, item), 'r') as old_zf:
        
        df = pd.read_csv(old_zf.open('enduse_timeseries.csv'))
        df.columns = [re.sub(r"[^\w\s]", '_', col).replace(' ', '').rstrip('_') for col in df.columns]
   
        df.to_hdf(hdf, str(uuid.uuid1()), complib='zlib', complevel=9) # TODO: get actual uuid from metadata
    
      print len(hdf.keys())
  
  print "Created new hdf5 file containing {} csv files.".format(len(hdf.keys()))
  hdf.close()    
    
if __name__ == '__main__':

  t0 = time.time()
  
  parser = argparse.ArgumentParser()
  parser.add_argument('--directory', default='../analysis_results/data_points', help='Relative path containing the data_point.zip files.')
  formats = ['zip', 'hdf5']
  parser.add_argument('--format', choices=formats, default='hdf5', help='Desired format of the stored output csv files.')   
  args = parser.parse_args()

  main(args.directory, args.format)
  
  print "All done! Completed rows in {0:.2f} seconds on".format(time.time()-t0), time.strftime("%Y-%m-%d %H:%M")
