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
simulation_output_reports = ['color_index']
qoi_reports = []

for col in df.columns.values:
  if 'applicable' in col:
    continue

  elif col.startswith('build_existing_model'):
    build_existing_models.append(col)
  elif col.startswith('simulation_output_report'):
    simulation_output_reports.append(col)
  elif col.startswith('qoi_report'):
    qoi_reports.append(col)

# results_characteristics.csv
results_characteristics = df[['OSW'] + build_existing_models]

results_characteristics = results_characteristics.set_index('OSW')
results_characteristics = results_characteristics.reindex(sorted(results_characteristics), axis=1)
results_characteristics.to_csv('baseline/results/results_characteristics.csv')

# results_output.csv
results_output = df[['OSW'] + simulation_output_reports + qoi_reports]
results_output = results_output.dropna(how='all', axis=1)
results_output = results_output.round(1)

results_output = results_output.set_index('OSW')
results_output = results_output.reindex(sorted(results_output), axis=1)
results_output.to_csv('baseline/results/results_output.csv')
