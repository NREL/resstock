import os
import pandas as pd
import shutil

thisdir = os.path.join(os.path.dirname(os.path.abspath(__file__)))
parentdir = os.path.join(thisdir, '..')

progressdir = os.path.join(parentdir, 'simulation_output')
if os.path.exists(progressdir):
  shutil.rmtree(progressdir)
os.mkdir(progressdir)

for filepath in os.listdir(parentdir):
  base, ext = os.path.splitext(filepath)
  if ext != '.csv':
    continue

  filepath = os.path.join(parentdir, filepath)
  df = pd.read_csv(filepath, index_col=['building_id'])

  cols_to_keep = [col for col in df.columns if 'simulation_output_report' in col]
  cols_to_keep += ['build_existing_model.geometry_building_type']
  cols_to_keep.insert(0, 'build_existing_model.units_represented')
  cols_to_keep.insert(0, 'build_existing_model.units_modeled')
  cols_to_keep.insert(0, 'build_existing_model.sample_weight')
  df = df[cols_to_keep]

  groups = df.groupby('build_existing_model.geometry_building_type')
  results = groups.sum()
  results.to_csv(os.path.join(progressdir, 'simulation_output.csv'))
  break