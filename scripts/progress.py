import os
import pandas as pd
import shutil

thisdir = os.path.join(os.path.dirname(os.path.abspath(__file__)))
parentdir = os.path.join(thisdir, '..')

progressdir = os.path.join(parentdir, 'progress')
if os.path.exists(progressdir):
  shutil.rmtree(progressdir)
os.mkdir(progressdir)

for filepath in os.listdir(parentdir):
  base, ext = os.path.splitext(filepath)
  if ext != '.csv':
    continue

  filepath = os.path.join(parentdir, filepath)
  df = pd.read_csv(filepath, index_col=['building_id'])
  results = {'num_dps': [df.shape[0]], 'total_site_energy_mbtu': [df['simulation_output_report.total_site_energy_mbtu'].sum()]}

  results = pd.DataFrame.from_dict(results)
  results = results.set_index('num_dps')
  results.to_csv(os.path.join(progressdir, 'progress.csv'))
  break