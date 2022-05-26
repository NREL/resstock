import os
import pandas as pd
from functools import reduce

for project in ['national', 'testing']:
  buildstockbatch = pd.read_csv('buildstockbatch/project_{}/{}_baseline/results_csvs/results_up00.csv'.format(project))
  run_analysis = pd.read_csv('run_analysis/{}_baseline/results-Baseline.csv'.format(project))

  intersection = list(set(buildstockbatch.columns) & set(run_analysis.columns))
  union = list(set(buildstockbatch.columns) | set(run_analysis.columns))
  minus = list(set(union) - set(intersection))

  print('{} project: intersection: {}'.format(project, len(intersection)))
  print('{} project: minus: {}'.format(project, len(minus)))
