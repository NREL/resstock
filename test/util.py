import os
import pandas as pd

# BASELINE

outdir = 'baseline'
if not os.path.exists(outdir):
  os.makedirs(outdir)

df_national = pd.read_csv('project_national/national_baseline/results_csvs/results_up00.csv')
df_national['building_id'] = df_national['building_id'].apply(lambda x: 'project_national-{}.osw'.format('%04d' % x))
df_national.insert(1, 'color_index', 1)

df_testing = pd.read_csv('project_testing/testing_baseline/results_csvs/results_up00.csv')
df_testing['building_id'] = df_testing['building_id'].apply(lambda x: 'project_testing-{}.osw'.format('%04d' % x))
df_testing.insert(1, 'color_index', 0)

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
for col in results_characteristics.columns.values:
  results_characteristics = results_characteristics.rename(columns={col: col.replace('build_existing_model.', '')})

results_characteristics = results_characteristics.set_index('OSW')
results_characteristics = results_characteristics.reindex(sorted(results_characteristics), axis=1)
results_characteristics.to_csv(os.path.join(outdir, 'results_characteristics.csv'))

# results_output.csv
results_output = df[['OSW'] + simulation_output_reports + qoi_reports]
results_output = results_output.dropna(how='all', axis=1)
results_output = results_output.round(1)
for col in results_output.columns.values:
  results_output = results_output.rename(columns={col: col.replace('simulation_output_report.', '')})
  results_output = results_output.rename(columns={col: col.replace('qoi_report.', 'qoi_')})

results_output = results_output.set_index('OSW')
results_output = results_output.reindex(sorted(results_output), axis=1)
results_output.to_csv(os.path.join(outdir, 'results_output.csv'))

# results_timeseries.csv
frames = []
index_col = ['Time', 'TimeDST', 'TimeUTC']

for dp in os.listdir('project_national/national_baseline/simulation_output/up00'):
  df = pd.read_csv('project_national/national_baseline/simulation_output/up00/{}/run/enduse_timeseries.csv'.format(dp), index_col=index_col)
  s = df.max() # FIXME
  df = pd.DataFrame([s.tolist()], columns=s.index)
  df['OSW'] = 'project_national-{}.osw'.format(dp[-4:])
  frames.append(df)

for dp in os.listdir('project_testing/testing_baseline/simulation_output/up00'):
  df = pd.read_csv('project_testing/testing_baseline/simulation_output/up00/{}/run/enduse_timeseries.csv'.format(dp), index_col=index_col)
  s = df.max() # FIXME
  df = pd.DataFrame([s.tolist()], columns=s.index)
  df['OSW'] = 'project_testing-{}.osw'.format(dp[-4:])
  frames.append(df)

results_timeseries = pd.concat(frames)
results_timeseries = results_timeseries.set_index('OSW')
results_timeseries.to_csv(os.path.join(outdir, 'results_timeseries.csv'))

# UPGRADES

outdir = 'upgrades'
if not os.path.exists(outdir):
  os.makedirs(outdir)

frames = []

num_scenarios = sum([len(files) for r, d, files in os.walk('project_testing/testing_upgrades/results_csvs')])
for i in range(1, num_scenarios):

  df_national = pd.read_csv('project_national/national_upgrades/results_csvs/results_up{}.csv'.format('%02d' % i))
  df_national['building_id'] = df_national['apply_upgrade.upgrade_name'].apply(lambda x: 'project_national-{}.osw'.format(x))
  df_national.insert(1, 'color_index', 1)

  frames.append(df_national)

  df_testing = pd.read_csv('project_testing/testing_upgrades/results_csvs/results_up{}.csv'.format('%02d' % i))
  df_testing['building_id'] = df_testing['apply_upgrade.upgrade_name'].apply(lambda x: 'project_testing-{}.osw'.format(x))
  df_testing.insert(1, 'color_index', 0)

  frames.append(df_testing)

df = pd.concat(frames)
df = df.rename(columns={'building_id': 'OSW'})
del df['job_id']

simulation_output_reports = ['color_index']
qoi_reports = []
apply_upgrades = []

for col in df.columns.values:
  if 'applicable' in col:
    continue

  elif col.startswith('simulation_output_report'):
    simulation_output_reports.append(col)
  elif col.startswith('qoi_report'):
    qoi_reports.append(col)
  elif col.startswith('apply_upgrade'):
    if not 'upgrade_name' in col:
      apply_upgrades.append(col)

# results_output.csv
results_output = df[['OSW'] + simulation_output_reports + qoi_reports + apply_upgrades]
results_output = results_output.dropna(how='all', axis=1)
results_output = results_output.round(1)
for col in results_output.columns.values:
  results_output = results_output.rename(columns={col: col.replace('simulation_output_report.', '')})
  results_output = results_output.rename(columns={col: col.replace('qoi_report.', 'qoi_')})
  results_output = results_output.rename(columns={col: col.replace('apply_upgrade.', '')})

results_output = results_output.set_index('OSW')
results_output = results_output.reindex(sorted(results_output), axis=1)
results_output.to_csv(os.path.join(outdir, 'results_output.csv'))
