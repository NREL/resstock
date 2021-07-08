import os
import sys
import argparse
import numpy as np
import pandas as pd
import csv
import plotly
import plotly.graph_objects as go
from plotly.subplots import make_subplots
sys.path.pop(0)
sys.path.insert(0, os.path.abspath(os.path.join(os.path.abspath(__file__), '../../resources/hpxml-measures/workflow/tests')))

from compare import BaseCompare

enum_maps = {'build_existing_model.geometry_building_type_recs': {'Single-Family Detached': 'SFD',
                                                                  'Single-Family Attached': 'SFA',
                                                                  'Multi-Family with 2 - 4 Units': 'MF',
                                                                  'Multi-Family with 5+ Units': 'MF'} }

class MoreCompare(BaseCompare):
  def __init__(self, base_folder, feature_folder, export_folder):
    self.base_folder = base_folder
    self.feature_folder = feature_folder
    self.export_folder = export_folder

  def samples(self):

    def value_counts(df, file):
      value_counts = []
      with open(file, 'w', newline='') as f:

        for col in sorted(df.columns):
          if col == 'Building':
            continue

          value_count = df[col].value_counts(normalize=True)
          value_count = value_count.round(2)
          keys_to_values = dict(zip(value_count.index.values, value_count.values))
          keys_to_values = dict(sorted(keys_to_values.items(), key=lambda x: (x[1], x[0]), reverse=True))
          value_counts.append([value_count.name])
          value_counts.append(keys_to_values.keys())
          value_counts.append(keys_to_values.values())
          value_counts.append('')

        w = csv.writer(f)
        w.writerows(value_counts)

    df = pd.read_csv(os.path.join(self.base_folder, 'buildstock.csv'))
    file = os.path.join(self.export_folder, 'base_samples.csv')
    value_counts(df, file)

    df = pd.read_csv(os.path.join(self.feature_folder, 'buildstock.csv'))
    file = os.path.join(self.export_folder, 'feature_samples.csv')
    value_counts(df, file)

if __name__ == '__main__':

  default_base_folder = 'test/test_samples_osw/base'
  default_feature_folder = 'test/test_samples_osw/results'
  default_export_folder = 'test/test_samples_osw/comparisons'
  actions = [method for method in dir(MoreCompare) if method.startswith('__') is False]
  aggregate_columns = ['build_existing_model.geometry_building_type_recs',
                       'build_existing_model.county']
  aggregate_functions = ['sum', 'mean']
  display_columns = ['build_existing_model.geometry_building_type_recs',
                     'build_existing_model.county']

  parser = argparse.ArgumentParser()
  parser.add_argument('-b', '--base_folder', default=default_base_folder, help='The path of the base folder.')
  parser.add_argument('-f', '--feature_folder', default=default_feature_folder, help='The path of the feature folder.')
  parser.add_argument('-e', '--export_folder', default=default_export_folder, help='The path of the export folder.')
  parser.add_argument('-a', '--actions', action='append', choices=actions, help='The method to call.')
  parser.add_argument('-ac', '--aggregate_column', choices=aggregate_columns, help='On which column to aggregate data.')
  parser.add_argument('-af', '--aggregate_function', choices=aggregate_functions, help='Function to use for aggregating data.')
  parser.add_argument('-dc', '--display_column', choices=display_columns, help='How to organize the subplots.')
  args = parser.parse_args()

  if not os.path.exists(args.export_folder):
    os.makedirs(args.export_folder)

  compare = MoreCompare(args.base_folder, args.feature_folder, args.export_folder)

  if args.actions == None:
    args.actions = [] 

  for action in args.actions:
    if action == 'samples':
      compare.samples()
    elif action == 'results':
      excludes = ['buildstock.csv']
      compare.results(args.aggregate_column, args.aggregate_function, excludes, enum_maps)
    elif action == 'visualize':
      excludes = ['buildstock.csv', 'results_characteristics.csv']
      compare.visualize(args.display_column, args.aggregate_column, args.aggregate_function, excludes, enum_maps)
