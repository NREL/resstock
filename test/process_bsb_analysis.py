import os
import pandas as pd
from functools import reduce
import csv

col_exclusions = ['applicable',
                  'include_timeseries_',
                  'output_format',
                  'timeseries_frequency',
                  'timeseries_timestamp_convention',
                  'timeseries_num_decimal_places',
                  'upgrade_name',
                  'add_timeseries_',
                  'user_output_variables']

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
report_simulation_outputs = ['color_index']
# simulation_outputs = []
# component_loads = []
# emissions = []
report_utility_bills = []
upgrade_costs = []
# cost_multipliers = []
qoi_reports = []

for col in df.columns.values:
  if any([col_exclusion in col for col_exclusion in col_exclusions]):
    continue

  if col.startswith('build_existing_model'):
    build_existing_models.append(col)
  elif col.startswith('report_simulation_output'):
    report_simulation_outputs.append(col)
    # if 'emissions' in col:
      # emissions.append(col)
    # else:
      # if 'component_load' in col:
        # component_loads.append(col)
      # else:
        # simulation_outputs.append(col)
  elif col.startswith('report_utility_bills'):
    report_utility_bills.append(col)
  elif col.startswith('upgrade_costs'):
    upgrade_costs.append(col)
    # if 'debug' in col or 'upgrade_cost_usd' in col:
      # pass # nop
    # else:
      # cost_multipliers.append(col)
  elif col.startswith('qoi_report'):
    qoi_reports.append(col)

build_existing_models = sorted(build_existing_models)
report_simulation_outputs = sorted(report_simulation_outputs)
# simulation_outputs = sorted(simulation_outputs)
# component_loads = sorted(component_loads)
# emissions = sorted(emissions)
report_utility_bills = sorted(report_utility_bills)
upgrade_costs = sorted(upgrade_costs)
# cost_multipliers = sorted(cost_multipliers)
qoi_reports = sorted(qoi_reports)

# Annual

outdir = 'baseline/annual'
if not os.path.exists(outdir):
  os.makedirs(outdir)

# results_characteristics.csv
results_characteristics = df[['OSW'] + build_existing_models]

results_characteristics = results_characteristics.set_index('OSW')
results_characteristics = results_characteristics.sort_index()
results_characteristics.to_csv(os.path.join(outdir, 'results_characteristics.csv'))

# results_output.csv
results_output = df[['OSW'] + report_simulation_outputs + report_utility_bills + upgrade_costs + qoi_reports]
results_output = results_output.dropna(how='all', axis=1)

results_output = results_output.set_index('OSW')
results_output = results_output.sort_index()
results_output.to_csv(os.path.join(outdir, 'results_output.csv'))

# def write_csv_cols(array, filename):
  # file = os.path.join('outputs', '{}'.format(filename))
  # wtr = csv.writer(open(file, 'w'), delimiter=',', lineterminator='\n')
  # for x in array:
    # wtr.writerow([x])
  # print('Wrote: {}'.format(file))

# # files for readthedocs
# if not os.path.exists('outputs'):
  # os.makedirs('outputs')

# write_csv_cols(build_existing_models, 'characteristics.csv')
# write_csv_cols(simulation_outputs, 'simulation_outputs.csv')
# write_csv_cols(component_loads, 'component_loads.csv')
# write_csv_cols(emissions, 'emissions.csv')
# write_csv_cols(report_utility_bills, 'utility_bills.csv')
# write_csv_cols(cost_multipliers, 'cost_multipliers.csv')
# write_csv_cols(qoi_reports, 'qoi_report.csv')

# Timeseries

def rename_ts_col(col):
  col = col.lower()
  col = col.replace(': ', '_')
  col = col.replace(' ', '_')
  col = col.replace('/', '_')
  col = 'report_simulation_output.{}'.format(col)
  return col

outdir = 'baseline/timeseries'
if not os.path.exists(outdir):
  os.makedirs(outdir)

df_nationals = []
df_testings = []
index_col = ['Time']
drops = ['TimeDST', 'TimeUTC']

dps = sorted(os.listdir('project_national/national_baseline/simulation_output/up00'))
for dp in dps:
  df_national = pd.read_csv('project_national/national_baseline/simulation_output/up00/{}/run/results_timeseries.csv'.format(dp), index_col=index_col)
  df_national = df_national.drop(drops, axis=1)

  for col, units in list(zip(df_national.columns.values, df_national.iloc[0, :].values)):
    new_col = rename_ts_col('{}_{}'.format(col, units))
    df_national = df_national.rename(columns={col: new_col})

  df_national = df_national.iloc[1:, :].apply(pd.to_numeric)

  df_nationals.append(df_national)

dps = sorted(os.listdir('project_testing/testing_baseline/simulation_output/up00'))
for dp in dps:
  df_testing = pd.read_csv('project_testing/testing_baseline/simulation_output/up00/{}/run/results_timeseries.csv'.format(dp), index_col=index_col)
  df_testing = df_testing.drop(drops, axis=1)

  for col, units in list(zip(df_testing.columns.values, df_testing.iloc[0, :].values)):
    new_col = rename_ts_col('{}_{}'.format(col, units))
    df_testing = df_testing.rename(columns={col: new_col})

  df_testing = df_testing.iloc[1:, :].apply(pd.to_numeric)

  df_testings.append(df_testing)

# results_output.csv

df_national = reduce(lambda x, y: x.add(y, fill_value=0), df_nationals)
df_national['PROJECT'] = 'project_national'

df_testing = reduce(lambda x, y: x.add(y, fill_value=0), df_testings)
df_testing['PROJECT'] = 'project_testing'

results_output = pd.concat([df_national, df_testing]).fillna(0)
results_output = results_output.set_index('PROJECT')
results_output = results_output.sort_index()
results_output.to_csv(os.path.join(outdir, 'results_output.csv'))

# UPGRADES

if not os.path.exists('upgrades'):
  os.makedirs('upgrades')

# Annual

outdir = 'upgrades/annual'
if not os.path.exists(outdir):
  os.makedirs(outdir)

frames = []

national_num_scenarios = sum([len(files) for r, d, files in os.walk('project_national/national_upgrades/results_csvs')])
testing_num_scenarios = sum([len(files) for r, d, files in os.walk('project_testing/testing_upgrades/results_csvs')])
assert national_num_scenarios == testing_num_scenarios

for i in range(1, national_num_scenarios):

  df_national = pd.read_csv('project_national/national_upgrades/results_csvs/results_up{}.csv'.format('%02d' % i))
  df_testing = pd.read_csv('project_testing/testing_upgrades/results_csvs/results_up{}.csv'.format('%02d' % i))

  assert df_national['apply_upgrade.upgrade_name'][0] == df_testing['apply_upgrade.upgrade_name'][0]
  upgrade_name = df_national['apply_upgrade.upgrade_name'][0]

  df_national['building_id'] = df_national['building_id'].apply(lambda x: 'project_national-{}-{}.osw'.format(upgrade_name, '%04d' % x))
  df_national.insert(1, 'color_index', 1)

  frames.append(df_national)
  
  df_testing['building_id'] = df_testing['building_id'].apply(lambda x: 'project_testing-{}-{}.osw'.format(upgrade_name, '%04d' % x))
  df_testing.insert(1, 'color_index', 0)

  frames.append(df_testing)

df = pd.concat(frames)
df = df.rename(columns={'building_id': 'OSW'})
del df['job_id']

report_simulation_outputs = ['color_index']
report_utility_bills = []
upgrade_costs = []
qoi_reports = []

for col in df.columns.values:
  if any([col_exclusion in col for col_exclusion in col_exclusions]):
    continue

  if col.startswith('report_simulation_output'):
    report_simulation_outputs.append(col)
  elif col.startswith('report_utility_bills'):
    report_utility_bills.append(col)
  elif col.startswith('upgrade_costs'):
    upgrade_costs.append(col)
  elif col.startswith('qoi_report'):
    qoi_reports.append(col)

report_simulation_outputs = sorted(report_simulation_outputs)
report_utility_bills = sorted(report_utility_bills)
upgrade_costs = sorted(upgrade_costs)
qoi_reports = sorted(qoi_reports)

# results_output.csv
results_output = df[['OSW'] + report_simulation_outputs + report_utility_bills + upgrade_costs + qoi_reports]
results_output = results_output.dropna(how='all', axis=1)

results_output = results_output.set_index('OSW')
results_output = results_output.sort_index()
results_output.to_csv(os.path.join(outdir, 'results_output.csv'))

# Timeseries

outdir = 'upgrades/timeseries'
if not os.path.exists(outdir):
  os.makedirs(outdir)

df_nationals = []
df_testings = []

dps = sorted(os.listdir('project_national/national_upgrades/simulation_output/up00'))
for dp in dps:
  for i in range(1, national_num_scenarios):
    if not os.path.exists('project_national/national_upgrades/simulation_output/up{}/{}/run/results_timeseries.csv'.format('%02d' % i, dp)):
      continue

    df_national = pd.read_csv('project_national/national_upgrades/simulation_output/up{}/{}/run/results_timeseries.csv'.format('%02d' % i, dp), index_col=index_col)
    df_national = df_national.drop(drops, axis=1)

    for col, units in list(zip(df_national.columns.values, df_national.iloc[0, :].values)):
      new_col = rename_ts_col('{}_{}'.format(col, units))
      df_national = df_national.rename(columns={col: new_col})

    df_national = df_national.iloc[1:, :].apply(pd.to_numeric)

    df_nationals.append(df_national)

dps = sorted(os.listdir('project_testing/testing_upgrades/simulation_output/up00'))
for dp in dps:
  for i in range(1, national_num_scenarios):
    if not os.path.exists('project_testing/testing_upgrades/simulation_output/up{}/{}/run/results_timeseries.csv'.format('%02d' % i, dp)):
      continue

    df_testing = pd.read_csv('project_testing/testing_upgrades/simulation_output/up{}/{}/run/results_timeseries.csv'.format('%02d' % i, dp), index_col=index_col)
    df_testing = df_testing.drop(drops, axis=1)

    for col, units in list(zip(df_testing.columns.values, df_testing.iloc[0, :].values)):
      new_col = rename_ts_col('{}_{}'.format(col, units))
      df_testing = df_testing.rename(columns={col: new_col})

    df_testing = df_testing.iloc[1:, :].apply(pd.to_numeric)

    df_testings.append(df_testing)

# results_output.csv

df_national = reduce(lambda x, y: x.add(y, fill_value=0), df_nationals)
df_national['PROJECT'] = 'project_national'

df_testing = reduce(lambda x, y: x.add(y, fill_value=0), df_testings)
df_testing['PROJECT'] = 'project_testing'

results_output = pd.concat([df_national, df_testing]).fillna(0)
results_output = results_output.set_index('PROJECT')
results_output = results_output.sort_index()
results_output.to_csv(os.path.join(outdir, 'results_output.csv'))
