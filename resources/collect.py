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

def main(zip_file, format, package, func, file, driver):

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
  elif func == 'build_db':
    build_db(zip_file, driver)
    
def assign_upgrades(df):

  upgrades = {}
  for name, group in df.groupby('build_existing_model.building_id'):    
    
    for ix, row in group.iterrows():
    
      ref_count = 0
      for col in group.columns:
        if not col.endswith('.run_measure'):
          continue
        ref_count += row[col]
      
      if ref_count == 0:
        ref = row
        
    for ix, row in group.iterrows():
    
      ref_count = 0
      for col in group.columns:
        if not col.endswith('.run_measure'):
          continue
        ref_count += row[col]
      
      if ref_count == 0:
        continue
        
      for col in group.columns:
        if not col.endswith('.run_measure'):
          continue
          
        if row[col] == 1:
          upgrade = col
          break
   
      for col in group.columns:      
        if not col.startswith('BuildingCharacteristicsReport'):
          continue
        if ref[col] != row[col]:
          upgrades[upgrade] = '{}.run_measure'.format(col.replace('BuildingCharacteristicsReport.', ''))
        
  df = df.rename(columns=upgrades)

  return df
    
def build_db(zip_file, driver):
  import buildstockdbmodel as bsdb
  from buildstockdbmodel import Datapoint, Building, Upgrade, ParameterOption, Parameter, Enduse, FuelType, DatapointParameterOption, DatapointSimulationOutput, FederalPovertyLevelBins
  
  folder_zf = zipfile.ZipFile(zip_file)  
  for datapoint in folder_zf.namelist():  
    if datapoint.endswith('results.csv'):
      folder_zf.extract(datapoint, os.path.dirname(zip_file))
      df = pd.read_csv(os.path.join(os.path.dirname(zip_file), datapoint), index_col='_id')
      df = df.dropna(axis=1, how='all')
  df = assign_upgrades(df)
  
  session = bsdb.create_session(driver)
  
  parameter_names = [col.replace('BuildingCharacteristicsReport.', '') for col in df.columns if 'BuildingCharacteristicsReport' in col]
  parameter_ids = [i + 1 for i in range(len(parameter_names))]
  session.bulk_insert_mappings(Parameter, [{'parameter_id': i+1, 'parameter_name': item} for i, item in enumerate(parameter_names)])
  parameter_dict = dict(zip(parameter_names, parameter_ids))
  
  parameteroption = []
  i = 1
  for col in df.columns:
    if not 'BuildingCharacteristicsReport' in col:
      continue
    for item in list(set(df[col])):
      parameteroption.append({'parameteroption_id': i, 'parameter_id': parameter_dict[col.replace('BuildingCharacteristicsReport.', '')], 'parameteroption_name': item})
      i += 1
  session.bulk_insert_mappings(ParameterOption, parameteroption)
  parameteroption_dict = dict(zip(session.query(ParameterOption.parameter_id, ParameterOption.parameteroption_name).all(), [item[0] for item in session.query(ParameterOption.parameteroption_id).all()]))
  
  upgrade_names = [col.replace('.run_measure', '') for col in df.columns if '.run_measure' in col]
  upgrade_names.insert(0, 'none')
  upgrade_ids = [i + 1 for i in range(len(upgrade_names))]
  session.bulk_insert_mappings(Upgrade, [{'upgrade_id': i+1, 'upgrade_name': item} for i, item in enumerate(upgrade_names)])
  upgrade_dict = dict(zip(upgrade_names, upgrade_ids))
  
  fueltype_names = ['electricity_', 'natural_gas_', 'other_fuel_']  
  enduse_names = [col.replace('SimulationOutputReport.', '') for col in df.columns if 'SimulationOutputReport' in col]
  for i, enduse_name in enumerate(enduse_names):
    for fueltype_name in fueltype_names:
      if fueltype_name in enduse_name:
        enduse_names[i] = enduse_name.replace(fueltype_name, '')
  enduse_ids = [i + 1 for i in range(len(enduse_names))]
  session.bulk_insert_mappings(Enduse, [{'enduse_id': i+1, 'enduse_name': item} for i, item in enumerate(enduse_names)])
  enduse_dict = dict(zip(enduse_names, enduse_ids))
  
  fueltype_ids = [i + 1 for i in range(len(fueltype_names))]
  session.bulk_insert_mappings(FuelType, [{'fueltype_id': i+1, 'fueltype_name': item} for i, item in enumerate(fueltype_names)])
  fueltype_dict = dict(zip(fueltype_names, fueltype_ids))

  for ix, row in df.iterrows():

    building = Building(ix, row['build_existing_model.building_id'])
    session.add(building)
  
    upgrade_id = 1
    for upgrade in upgrade_dict.keys():  
      
      for col in row.index.values:

        if not '.run_measure' in col:
          continue        
        
        if not upgrade == 'none':
          if row['{}.run_measure'.format(upgrade)] == 1:
            upgrade_id = upgrade_dict[col.replace('.run_measure', '')]

    upgrade_cost_usd = None
    if 'SimulationOutputReport.upgrade_cost_usd' in row.index.values:
      upgrade_cost_usd = row['SimulationOutputReport.upgrade_cost_usd']
            
    datapoint = Datapoint(ix, upgrade_id, upgrade_cost_usd)
    session.add(datapoint)

    for col in row.index.values:        
    
      if 'BuildingCharacteristicsReport' in col:

        datapointparameteroption = DatapointParameterOption(ix, parameteroption_dict[(parameter_dict[col.replace('BuildingCharacteristicsReport.', '')], str(row[col]))])
        session.add(datapointparameteroption)

      elif 'SimulationOutputReport' in col:
        
        for fueltype_name in fueltype_names:
          if fueltype_name in col:
            fueltype_id = fueltype_dict[fueltype_name]

        datapointsimulationoutput = DatapointSimulationOutput(ix, enduse_dict[col.replace('SimulationOutputReport.', '').replace('electricity_', '').replace('natural_gas_', '').replace('other_fuel_', '')], fueltype_id, row[col])
        session.add(datapointsimulationoutput)
        
  fpl = pd.read_csv('../project_resstock_national/housing_characteristics/Federal Poverty Level.tsv', sep='\t')
  fplbin_names = [col.replace('Option=', '') for col in fpl.columns if 'Option=' in col]
  fplbin_ids = [i + 1 for i in range(len(fplbin_names))]
  session.bulk_insert_mappings(FederalPovertyLevelBins, [{'fplbin_id': i+1, 'fplbin_name': item} for i, item in enumerate(fplbin_names)])
  
  session.commit()

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

  dir = os.path.dirname(os.path.abspath(zip_file))
    
  folder_zf = zipfile.ZipFile(zip_file)
  
  df = pd.DataFrame()
  
  for datapoint in folder_zf.namelist():
  
    if not datapoint.endswith('.zip'):
      continue
    
    folder_zf.extract(datapoint, dir)
    
    with zipfile.ZipFile(os.path.join(dir, datapoint), 'r') as data_point_zf:
  
      if df.empty:
        df = pd.read_csv(data_point_zf.open('enduse_timeseries.csv'), index_col='Time')
      else:
        df = df.add(pd.read_csv(data_point_zf.open('enduse_timeseries.csv'), index_col='Time'), fill_value=0)
        
  df = df.reset_index()
  del df['Time']
  df.columns = [re.sub(r"[^\w\s]", '_', col).replace(' ', '').rstrip('_').replace('Electricity', 'Elec') for col in df.columns]
  
  f = DSGridFile()
  sector = f.add_sector('res', 'Residential')
  subsector = sector.add_subsector("sf", "Single-Family", Hours(), df.columns.values)
  subsector.add_data(df, (8, 59))
  f.write(file)

from dsgrid.timeformats import TimeFormat
class Hours(TimeFormat):

  def __init__(self):
    TimeFormat.__init__(self, "Hours", 8760)

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
    print 'here1'
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
  dbtypes = ['sqlite', 'postgresql']
  parser.add_argument('--driver', default='sqlite:///buildstock.sql', help='Type of db to build.')
  args = parser.parse_args()

  main(args.zip, args.format, args.package, args.function, args.file, args.driver)
  
  print "All done! Completed rows in {0:.2f} seconds on".format(time.time()-t0), time.strftime("%Y-%m-%d %H:%M")
