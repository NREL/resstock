import os
import pandas as pd

outdir = 'baseline/results'
if not os.path.exists(outdir):
  os.makedirs(outdir)

df_testing = pd.read_csv('project_testing/testing_baseline.csv')
df_testing['building_id'] = df_testing['building_id'].apply(lambda x: 'project_testing-{}.osw'.format('%04d' % x))
df_testing.insert(1, 'color_index', 0)

df_national = pd.read_csv('project_national/national_baseline.csv')
df_national['building_id'] = df_national['building_id'].apply(lambda x: 'project_national-{}.osw'.format('%04d' % x))
df_national.insert(1, 'color_index', 1)

frames = [df_national, df_testing]
df = pd.concat(frames)
df = df.rename(columns={'building_id': 'OSW'})
del df['job_id']

build_existing_models = []
apply_upgrades = []
simulation_output_reports = ['color_index']

for col in df.columns.values:
  if 'applicable' in col:
    continue
  if col.startswith('apply_upgrade'):
    apply_upgrades.append(col)
  elif col.startswith('build_existing_model'):
    build_existing_models.append(col)
  elif col.startswith('simulation_output_report'):
    simulation_output_reports.append(col)

for col in apply_upgrades:
  del df[col]

results_characteristics = df[['OSW'] + build_existing_models]
for col in results_characteristics.columns.values:
  results_characteristics = results_characteristics.rename(columns={col: col.replace('build_existing_model.', '')})

results_output = df[['OSW'] + simulation_output_reports]
for col in results_output.columns.values:
  results_output = results_output.rename(columns={col: col.replace('simulation_output_report.', '')})

results_characteristics.set_index('OSW').to_csv('baseline/results/results_characteristics.csv')
results_output.set_index('OSW').to_csv('baseline/results/results_output.csv')
