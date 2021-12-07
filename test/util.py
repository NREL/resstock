import os
import pandas as pd

# BASELINE

if not os.path.exists('baseline'):
  os.makedirs('baseline')

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

results_characteristics = df[['OSW'] + build_existing_models]
for col in results_characteristics.columns.values:
  results_characteristics = results_characteristics.rename(columns={col: col.replace('build_existing_model.', '')})

results_characteristics = results_characteristics.set_index('OSW')
results_characteristics = results_characteristics.reindex(sorted(results_characteristics), axis=1)

# Annual

outdir = 'baseline/annual'
if not os.path.exists(outdir):
  os.makedirs(outdir)

# results_characteristics.csv
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

# Timeseries

outdir = 'baseline/timeseries'
if not os.path.exists(outdir):
  os.makedirs(outdir)

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

# results_characteristics.csv
results_characteristics.to_csv(os.path.join(outdir, 'results_characteristics.csv'))

# results_output.csv
results_output = pd.concat(frames)
results_output = results_output.set_index('OSW')
results_output.to_csv(os.path.join(outdir, 'results_output.csv'))

# UPGRADES

if not os.path.exists('upgrades'):
  os.makedirs('upgrades')

# Annual

outdir = 'upgrades/annual'
if not os.path.exists(outdir):
  os.makedirs(outdir)

frames = []
upgrades = {}

num_scenarios = sum([len(files) for r, d, files in os.walk('project_testing/testing_upgrades/results_csvs')])
for i in range(1, num_scenarios):

  df_national = pd.read_csv('project_national/national_upgrades/results_csvs/results_up{}.csv'.format('%02d' % i))
  df_testing = pd.read_csv('project_testing/testing_upgrades/results_csvs/results_up{}.csv'.format('%02d' % i))

  assert df_national['apply_upgrade.upgrade_name'][0] == df_testing['apply_upgrade.upgrade_name'][0]
  upgrades[i] = df_national['apply_upgrade.upgrade_name'][0]

  df_national['building_id'] = 'project_national-{}.osw'.format(upgrades[i])
  df_national.insert(1, 'color_index', 1)

  frames.append(df_national)
  
  df_testing['building_id'] = 'project_testing-{}.osw'.format(upgrades[i])
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

# Timeseries

outdir = 'upgrades/timeseries'
if not os.path.exists(outdir):
  os.makedirs(outdir)

frames = []
index_col = ['Time', 'TimeDST', 'TimeUTC']

for i in range(1, num_scenarios):
  df_national = pd.read_csv('project_national/national_upgrades/simulation_output/up{}/bldg0000001/run/enduse_timeseries.csv'.format('%02d' % i), index_col=index_col)
  s = df_national.max() # FIXME
  df_national = pd.DataFrame([s.tolist()], columns=s.index)
  df_national.insert(0, 'OSW', 'project_national-{}.osw'.format(upgrades[i]))
  df_national.insert(1, 'color_index', 1)

  frames.append(df_national)

  df_testing = pd.read_csv('project_testing/testing_upgrades/simulation_output/up{}/bldg0000001/run/enduse_timeseries.csv'.format('%02d' % i), index_col=index_col)
  s = df_testing.max() # FIXME
  df_testing = pd.DataFrame([s.tolist()], columns=s.index)
  df_testing.insert(0, 'OSW', 'project_testing-{}.osw'.format(upgrades[i]))
  df_testing.insert(1, 'color_index', 0)

  frames.append(df_testing)

# results_output.csv
results_output = pd.concat(frames)
results_output = results_output.set_index('OSW')
results_output.to_csv(os.path.join(outdir, 'results_output.csv'))
