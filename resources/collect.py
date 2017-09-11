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

def main(zip_file, format, package, func, file):

  if func == 'write':
    if format == 'zip':    
      write_zip(file)      
    elif format == 'hdf5':    
      if package == 'pandas':    
        write_pandas_hdf5(zip_file, file)      
      elif package == 'h5py':      
        write_h5py_hdf5(zip_file, file)      
  elif func == 'read':  
    if format == 'zip':    
      print "Haven't written this code yet."      
    elif format == 'hdf5':
      if package == 'pandas':    
        read_pandas_hdf5(file)
      elif package == 'h5py':      
        read_h5py_hdf5(file)

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

def write_pandas_hdf5(zip_file, file):

  dir = os.path.dirname(os.path.abspath(zip_file))

  datapoint_ids = pd.DataFrame(columns=['datapoint', 'datapoint_id'])
  enduse_ids = pd.DataFrame(columns=['enduse', 'enduse_id'])
  
  with pd.HDFStore(file, mode='w', complib='zlib', complevel=9) as hdf:
        
    folder_zf = zipfile.ZipFile(zip_file)
    
    for datapoint in folder_zf.namelist():
    
      if datapoint.endswith('results.csv'):
        folder_zf.extract(datapoint, dir)
        chars = pd.read_csv(os.path.join(dir, datapoint), index_col='_id')
        chars = chars.dropna(axis=1, how='all')      
    
      if not datapoint.endswith('.zip'):
        continue
      
      folder_zf.extract(datapoint, os.path.dirname(os.path.abspath(zip_file)))
      
      with zipfile.ZipFile(os.path.join(os.path.dirname(os.path.abspath(zip_file)), datapoint), 'r') as data_point_zf:
    
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
    
def write_h5py_hdf5(zip_file, file):  
  from dsgrid.dataformat import DSGridFile

  results_csv = pd.read_csv('../analysis_results/data_points/comed_savings.csv') # TODO
  
  dir = os.path.dirname(os.path.abspath(zip_file))
    
  folder_zf = zipfile.ZipFile(zip_file)
  
  df = pd.DataFrame()
  
  dfs = {}
  for i, datapoint in enumerate(folder_zf.namelist()):
  
    if not datapoint.endswith('.zip'):
      continue

    id = datapoint.split('/')[1]
    epw = results_csv.loc[results_csv['_id']==id, 'building_characteristics_report.location_epw'].values
    if not len(epw) > 0: # this one is not in the results csv
      continue
    epw = epw[0]
    
    folder_zf.extract(datapoint, dir)
    
    with zipfile.ZipFile(os.path.join(dir, datapoint), 'r') as data_point_zf:
  
      if not 'enduse_timeseries.csv' in data_point_zf.namelist():
        continue
  
      if not epw in dfs.keys():
        df = pd.DataFrame()
      else:
        df = dfs[epw]
  
      if df.empty:
        df = pd.read_csv(data_point_zf.open('enduse_timeseries.csv'), index_col='Time')
      else:
        df = df.add(pd.read_csv(data_point_zf.open('enduse_timeseries.csv'), index_col='Time'), fill_value=0)
       
      print i / 2, id, epw
      dfs[epw] = df
        
  f = DSGridFile()
  for epw, df in dfs.items():
        
    df = df.reset_index()
    del df['Time']
    df.columns = [re.sub(r"[^\w\s]", '_', col).replace(' ', '').rstrip('_').replace('Electricity', 'Elec') for col in df.columns]  
    
    sector = f.add_sector('res', 'Residential')
    subsector = sector.add_subsector(epw[0:3], epw, Hours(), df.columns.values)
    subsector.add_data(df, (8, 59))
  
  f.write(file)

from dsgrid.timeformats import TimeFormat
class Hours(TimeFormat):

  def __init__(self):
    TimeFormat.__init__(self, "Hours", 8784)

  def timeindex(self):
    return pd.Index(range(self.periods))
    
def read_pandas_hdf5(file):
    
  import plotly
  import plotly.graph_objs as go   
    
  # one datapoint, one enduse  
  datapoints = ['03f05f93-27ae-46b5-ba6b-c97cc39a0663', '0b7aab40-c8fb-4d37-aae0-921b3a7856a6']
  enduses = ['Heating_Gas_kBtu', 'Cooling_Electricity_kWh']
    
  with pd.HDFStore(file) as hdf:
  
    for key in hdf.keys():
      # print hdf[key].head()
      # print hdf[key].shape
      print hdf[key]
    
    # load dataframes into memory
    characteristics = hdf['characteristics']
    datapoint_ids = hdf['datapoint_ids']
    enduse_ids = hdf['enduse_ids']    
    df = hdf['df']
    
    for datapoint in datapoints:
      datapoint_id = datapoint_ids[datapoint_ids['datapoint']==datapoint].index.values[0]
      data = []
      for enduse in enduses:

        enduse_id = enduse_ids[enduse_ids['enduse']==enduse].index.values[0]
        d = df.ix[int(datapoint_id)]
        d = d[d['enduse_id']==enduse_id]
        if 'kWh' in enduse:
          data.append({'x': d['Time'], 'y': kWh2MBtu(d['value']), 'name': enduse})
        elif 'kBtu' in enduse:
          data.append({'x': d['Time'], 'y': kBtu2MBtu(d['value']), 'name': enduse})

      layout = go.Layout(title=characteristics[characteristics.index==datapoint]['BuildingCharacteristicsReport.location_epw'].values[0], yaxis=dict(title='MBtu'))
      data = go.Figure(data=data, layout=layout)
      plotly.offline.plot(data, filename='{}.html'.format(datapoint), auto_open=True)

def read_h5py_hdf5(file):

  with h5py.File(file, mode='r') as hdf:

    datapoint_ids = 0
    nrows = 0
    for group in hdf:
        
      # for attr in hdf[group].attrs:
        
        # print hdf[group].attrs[attr]
              
      datapoint_ids += 1
      nrows += hdf[group].shape[0]
        
    print datapoint_ids, nrows
          
def kWh2MBtu(x):
    return 3412.0 * 0.000001 * x
    
def kBtu2MBtu(x):
    return x / 1000.0 
          
if __name__ == '__main__':

  t0 = time.time()
  
  parser = argparse.ArgumentParser()
  parser.add_argument('--zip', default='../analysis_results/data_points/resstock_pnw_localResults.zip', help='Relative path of the localResults.zip file.')
  formats = ['zip', 'hdf5']
  parser.add_argument('--format', choices=formats, default='hdf5', help='Desired format of the stored output csv files.')
  packages = ['pandas', 'h5py']
  parser.add_argument('--package', choices=packages, default='pandas', help='HDF5 tool.')
  functions = ['read', 'write', 'build_db']
  parser.add_argument('--function', choices=functions, default='write', help='Read or write.')
  parser.add_argument('--file', default='data_points.h5', help='Name of the existing hdf5 file.')
  args = parser.parse_args()

  main(args.zip, args.format, args.package, args.function, args.file)
  
  print "All done! Completed rows in {0:.2f} seconds on".format(time.time()-t0), time.strftime("%Y-%m-%d %H:%M")
