import os
import argparse
import numpy as np
import pandas as pd
import csv
import plotly
import plotly.graph_objects as go
from plotly.subplots import make_subplots

class Compare:

  def samples(self, base_folder, feature_folder, export_folder, groupby=[]):

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

    df = pd.read_csv(os.path.join(base_folder, 'base_buildstock.csv'))
    file = os.path.join(export_folder, 'base_samples.csv')
    value_counts(df, file)

    df = pd.read_csv(os.path.join(feature_folder, 'buildstock.csv'))
    file = os.path.join(export_folder, 'feature_samples.csv')
    value_counts(df, file)

  def results(self, base_folder, feature_folder, export_folder, groupby=[]):
    files = []
    for file in os.listdir(base_folder):
      if file.startswith('results') and file.endswith('.csv'):
        files.append(file)

    for file in sorted(files):
      base_df = pd.read_csv(os.path.join(base_folder, file), index_col=0)
      feature_df = pd.read_csv(os.path.join(feature_folder, file), index_col=0)

      try:
        df = feature_df - base_df
      except:
        df = feature_df != base_df
        df = df.astype(int)

      df = df.fillna('NA')
      df.to_csv(os.path.join(export_folder, file))    

      # Get results charactersistics of groupby columns
      if file == 'results_characteristics.csv':
        if 'build_existing_model.geometry_building_type_recs' not in groupby:
          groupby.append('build_existing_model.geometry_building_type_recs')
        group_df = base_df[groupby]

      # Write grouped & aggregated results dfs
      if file == 'results_output.csv':
        # Map building types
        if 'build_existing_model.geometry_building_type_recs' in groupby:
          btype_map = {'Single-Family Detached': 'SFD',
                      'Single-Family Attached': 'SFA',
                      'Multi-Family with 2 - 4 Units': 'MF',
                      'Multi-Family with 5+ Units': 'MF'}
          group_df['build_existing_model.geometry_building_type_recs'] = group_df['build_existing_model.geometry_building_type_recs'].map(btype_map)

        # Merge groupby df and aggregate
        base_df = group_df.merge(base_df, 'outer', left_index=True, right_index=True).groupby(groupby)
        base_df = base_df.sum().stack()
        feature_df = group_df.merge(feature_df, 'outer', left_index=True, right_index=True).groupby(groupby).sum()
        feature_df = feature_df.stack()

    # Write aggregate results df
    deltas = pd.DataFrame()
    deltas['base'] = base_df
    deltas['feature'] = feature_df
    deltas['diff'] = deltas['feature'] - deltas['base']
    deltas['% diff'] = 100*(deltas['diff']/deltas['base'])
    deltas = deltas.round(2)                          
    deltas.reset_index(level=groupby, inplace=True)
    deltas.index.name = 'enduse'
    sims_df = pd.DataFrame({'base':len(base_df),
                            'feature':len(feature_df),
                            'diff':'n/a',
                            '% diff':'n/a'},
                            index=['simulation_count'])
    sims_df[groupby] = 'n/a'
    deltas = pd.concat([sims_df, deltas])
    for group in groupby:
      first_col = deltas.pop(group)
      deltas.insert(0, group, first_col)

    deltas.to_csv(os.path.join(export_folder, 'aggregate_results.csv'))

  def visualize(self, base_folder, feature_folder, export_folder, groupby=[]):
    excludes = ['buildstock.csv', 'results_characteristics.csv']

    if groupby:
      base_characteristics_df = pd.read_csv(os.path.join(base_folder, 'results_characteristics.csv'), index_col=0)[groupby]
      feature_characteristics_df = pd.read_csv(os.path.join(feature_folder, 'results_characteristics.csv'), index_col=0)[groupby]

    def get_min_max(x_col, y_col, min_value, max_value):
        if 0.9 * np.min([x_col.min(), y_col.min()]) < min_value:
                        min_value = 0.9 * np.min([x_col.min(), y_col.min()])
        if 1.1 * np.max([x_col.max(), y_col.max()]) > max_value:
                        max_value = 1.1 * np.max([x_col.max(), y_col.max()])

        return(min_value, max_value)

    def add_error_lines(fig, showlegend, row, col, min_value, max_value):
        fig.add_trace(go.Scatter(x=[min_value, max_value], y=[min_value, max_value], line=dict(color='black', dash='dash', width=1), mode='lines', showlegend=showlegend, name='0% Error'), row=row, col=col)
        fig.add_trace(go.Scatter(x=[min_value, max_value], y=[0.9*min_value, 0.9*max_value], line=dict(color='black', dash='dashdot', width=1), mode='lines', showlegend=showlegend, name='+/- 10% Error'), row=row, col=col)
        fig.add_trace(go.Scatter(x=[min_value, max_value], y=[1.1*min_value, 1.1*max_value], line=dict(color='black', dash='dashdot', width=1), mode='lines', showlegend=False), row=row, col=col)

    files = []
    for file in os.listdir(base_folder):
      if not file in excludes:
        files.append(file)

    for file in files:
      base_df = pd.read_csv(os.path.join(base_folder, file), index_col=0)
      feature_df = pd.read_csv(os.path.join(feature_folder, file), index_col=0)

      end_uses = sorted(list(set(base_df.columns) | set(feature_df.columns)))
      if file == 'results.csv' or file == 'results_output.csv':
        end_uses = [x for x in end_uses if 'Fuel Use:' in x or 'fuel_use_' in x] # FIXME

      if groupby:
        base_df = base_characteristics_df.join(base_df)
        feature_df = feature_characteristics_df.join(feature_df)
        groups = list(base_df[groupby[0]].unique())
      else:
        groups = ['1:1']

      fig = make_subplots(rows=len(end_uses), cols=len(groups), subplot_titles=groups*len(end_uses), row_titles=[f'<b>{f}</b>' for f in end_uses], vertical_spacing = 0.015)

      row = 0
      for end_use in end_uses:
        row += 1
        for group in groups:
          col = groups.index(group) + 1
          showlegend = False
          if col == 1 and row == 1: showlegend = True

          x = base_df
          y = feature_df

          if groupby:
            x = x.loc[x[groupby[0]] == group, :]
            y = y.loc[y[groupby[0]] == group, :]

          fig.add_trace(go.Scatter(x=x[end_use], y=y[end_use], marker=dict(size=8), mode='markers', text=base_df.index, name='', legendgroup=end_use, showlegend=False), row=row, col=col)

          min_value, max_value = get_min_max(x[end_use], y[end_use], 0, 0)
          add_error_lines(fig, showlegend, row, col, min_value, max_value)
          fig.update_xaxes(title_text='base', row=row, col=col)
          fig.update_yaxes(title_text='feature', row=row, col=col)

      fig['layout'].update(title=file, template='plotly_white')
      fig.update_layout(width=800*len(groups), height=600*len(end_uses), autosize=False, font=dict(size=12))
      for i in fig['layout']['annotations']:
          i['font'] = dict(size=12) if i['text'] in end_uses else dict(size=12)
      basename, ext = os.path.splitext(file)
      if groupby:
        basename += '_{groupby}'.format(groupby=groupby[0])
      fig.write_image(os.path.join(export_folder, '{basename}.svg'.format(basename=basename)))
      plotly.offline.plot(fig, filename=os.path.join(export_folder, '{basename}.html'.format(basename=basename)), auto_open=False)

if __name__ == '__main__':

  default_base_folder = 'workflow/tests/base_results'
  default_feature_folder = 'workflow/tests/results'
  default_export_folder = 'workflow/tests/comparisons'

  actions = [method for method in dir(Compare) if method.startswith('__') is False]

  groupby = ['build_existing_model.geometry_building_type_recs']

  parser = argparse.ArgumentParser()
  parser.add_argument('-b', '--base_folder', default=default_base_folder, help='TODO')
  parser.add_argument('-f', '--feature_folder', default=default_feature_folder, help='TODO')
  parser.add_argument('-a', '--actions', action='append', choices=actions, help='TODO')
  parser.add_argument('-e', '--export_folder', default=default_export_folder, help='TODO')
  parser.add_argument('-g', '--groupby', action='append', choices=groupby, help='TODO')
  parser.add_argument('-m', '--mapping', help='TODO')
  args = parser.parse_args()

  if not os.path.exists(args.export_folder):
    os.makedirs(args.export_folder)

  compare = Compare()

  if args.actions == None:
    args.actions = []

  if args.groupby == None:
    args.groupby = []

  for action in args.actions:
    getattr(compare, action)(args.base_folder, args.feature_folder, args.export_folder, args.groupby)
