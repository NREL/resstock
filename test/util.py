import os
import pandas as pd

col_exclusions = ['applicable',
                  'include_timeseries_',
                  'output_format',
                  'timeseries_frequency',
                  'upgrade_name']

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
report_simulation_outputs = ['color_index']
upgrade_costs = []
qoi_reports = []

for col in df.columns.values:
  if any([col_exclusion in col for col_exclusion in col_exclusions]):
    continue

  if col.startswith('build_existing_model'):
    build_existing_models.append(col)
  elif col.startswith('report_simulation_output'):
    report_simulation_outputs.append(col)
  elif col.startswith('upgrade_costs'):
    upgrade_costs.append(col)
  elif col.startswith('qoi_report'):
    qoi_reports.append(col)

# results_characteristics.csv
results_characteristics = df[['OSW'] + build_existing_models]

results_characteristics = results_characteristics.set_index('OSW')
results_characteristics = results_characteristics.reindex(sorted(results_characteristics), axis=1)
results_characteristics.to_csv(os.path.join(outdir, 'results_characteristics.csv'))

# results_output.csv
results_output = df[['OSW'] + report_simulation_outputs + upgrade_costs + qoi_reports]
results_output = results_output.dropna(how='all', axis=1)

results_output = results_output.set_index('OSW')
results_output = results_output.reindex(sorted(results_output), axis=1)
results_output.to_csv(os.path.join(outdir, 'results_output.csv'))

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

report_simulation_outputs = ['color_index']
upgrade_costs = []
qoi_reports = []
apply_upgrades = []

for col in df.columns.values:
  if any([col_exclusion in col for col_exclusion in col_exclusions]):
    continue

  if col.startswith('report_simulation_output'):
    report_simulation_outputs.append(col)
  elif col.startswith('upgrade_costs'):
    upgrade_costs.append(col)
  elif col.startswith('qoi_report'):
    qoi_reports.append(col)
  elif col.startswith('apply_upgrade'):
    apply_upgrades.append(col)

# results_output.csv
results_output = df[['OSW'] + report_simulation_outputs + upgrade_costs + qoi_reports + apply_upgrades]
results_output = results_output.dropna(how='all', axis=1)

results_output = results_output.set_index('OSW')
results_output = results_output.reindex(sorted(results_output), axis=1)
results_output.to_csv(os.path.join(outdir, 'results_output.csv'))
