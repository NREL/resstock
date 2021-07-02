import os
import sys
import argparse
import numpy as np
import pandas as pd
import csv
import plotly
import plotly.graph_objects as go
from plotly.subplots import make_subplots

class BaseCompare:
  def __init__(self, base_folder, feature_folder, export_folder):
    self.base_folder = base_folder
    self.feature_folder = feature_folder
    self.export_folder = export_folder

  def results(self, groupby_column, groupby_function, btype_map=None):
    groupby_columns = []
    if groupby_column:
      groupby_columns.append(groupby_column)

    excludes = ['buildstock.csv']

    files = []
    for file in os.listdir(self.base_folder):
      if not file in excludes:
        files.append(file)

    for file in sorted(files):
      base_df = pd.read_csv(os.path.join(self.base_folder, file), index_col=0)
      feature_df = pd.read_csv(os.path.join(self.feature_folder, file), index_col=0)

      try:
        df = feature_df - base_df
      except:
        df = feature_df != base_df
        df = df.astype(int)

      df = df.fillna('NA')
      df.to_csv(os.path.join(self.export_folder, file))    

      # Get results charactersistics of groupby columns
      if file == 'results_characteristics.csv':
        group_df = base_df[groupby_columns]

      # Write grouped & aggregated results dfs
      if file != 'results_characteristics.csv':
        # Map building types
        if 'build_existing_model.geometry_building_type_recs' in groupby_columns:
          group_df['build_existing_model.geometry_building_type_recs'] = group_df['build_existing_model.geometry_building_type_recs'].map(btype_map)

        # Merge groupby df and aggregate
        sim_ct_base = len(base_df)
        sim_ct_feature = len(feature_df)
        if groupby_columns:
          base_df = group_df.merge(base_df, 'outer', left_index=True, right_index=True).groupby(groupby_columns)
          feature_df = group_df.merge(feature_df, 'outer', left_index=True, right_index=True).groupby(groupby_columns)
          if groupby_function == 'sum':
            base_df = base_df.sum().stack()
            feature_df = feature_df.sum().stack()
          elif groupby_function == 'mean':
            base_df = base_df.mean().stack()
            feature_df = feature_df.mean().stack()
        else:
          if groupby_function == 'sum':
            base_df = base_df.sum(numeric_only=True)
            feature_df = feature_df.sum(numeric_only=True)
          elif groupby_function == 'mean':
            base_df = base_df.mean(numeric_only=True)
            feature_df = feature_df.mean(numeric_only=True)

    if not groupby_columns: return

    # Write aggregate results df
    deltas = pd.DataFrame()
    deltas['base'] = base_df
    deltas['feature'] = feature_df
    deltas['diff'] = deltas['feature'] - deltas['base']
    deltas['% diff'] = 100*(deltas['diff']/deltas['base'])
    deltas = deltas.round(2)                          
    deltas.reset_index(level=groupby_columns, inplace=True)
    deltas.index.name = 'enduse'
    sims_df = pd.DataFrame({'base': sim_ct_base,
                            'feature': sim_ct_feature,
                            'diff': 'n/a',
                            '% diff': 'n/a'},
                            index=['simulation_count'])
    sims_df[groupby_columns] = 'n/a'
    deltas = pd.concat([sims_df, deltas])
    for group in groupby_columns:
      first_col = deltas.pop(group)
      deltas.insert(0, group, first_col)

    basename, ext = os.path.splitext(file)
    if groupby_columns:
        basename += '_{groupby_column}'.format(groupby_column=groupby_columns[0])

    deltas.to_csv(os.path.join(self.export_folder, '{basename}_{groupby_function}.csv'.format(basename=basename, groupby_function=groupby_function)))

  def visualize(self, groupby_column, groupby_function, btype_map=None):
    groupby_columns = []
    if groupby_column:
      groupby_columns.append(groupby_column)

    excludes = ['buildstock.csv', 'results_characteristics.csv']

    files = []
    for file in os.listdir(self.base_folder):
      if not file in excludes:
        files.append(file)

    if groupby_columns:
      base_characteristics_df = pd.read_csv(os.path.join(self.base_folder, 'results_characteristics.csv'), index_col=0)[groupby_columns]
      feature_characteristics_df = pd.read_csv(os.path.join(self.feature_folder, 'results_characteristics.csv'), index_col=0)[groupby_columns]

    def get_min_max(x_col, y_col, min_value, max_value):
        try:
          if 0.9 * np.min([x_col.min(), y_col.min()]) < min_value:
            min_value = 0.9 * np.min([x_col.min(), y_col.min()])
        except:
          pass
        try:
          if 1.1 * np.max([x_col.max(), y_col.max()]) > max_value:
            max_value = 1.1 * np.max([x_col.max(), y_col.max()])
        except:
          pass

        return(min_value, max_value)

    def add_error_lines(fig, showlegend, row, col, min_value, max_value):
        fig.add_trace(go.Scatter(x=[min_value, max_value], y=[min_value, max_value], line=dict(color='black', dash='dash', width=1), mode='lines', showlegend=showlegend, name='0% Error'), row=row, col=col)
        fig.add_trace(go.Scatter(x=[min_value, max_value], y=[0.9*min_value, 0.9*max_value], line=dict(color='black', dash='dashdot', width=1), mode='lines', showlegend=showlegend, name='+/- 10% Error'), row=row, col=col)
        fig.add_trace(go.Scatter(x=[min_value, max_value], y=[1.1*min_value, 1.1*max_value], line=dict(color='black', dash='dashdot', width=1), mode='lines', showlegend=False), row=row, col=col)

    for file in files:
      base_df = pd.read_csv(os.path.join(self.base_folder, file), index_col=0)
      feature_df = pd.read_csv(os.path.join(self.feature_folder, file), index_col=0)

      end_uses = sorted(list(set(base_df.columns) | set(feature_df.columns)))
      if file == 'results.csv' or file == 'results_output.csv':
        end_uses = [x for x in end_uses if 'Fuel Use:' in x or 'fuel_use_' in x] # FIXME

      if groupby_columns:
        base_df = base_characteristics_df.join(base_df)
        feature_df = feature_characteristics_df.join(feature_df)
        if 'build_existing_model.geometry_building_type_recs' in groupby_columns:
          for df in [base_df, feature_df]:
            df['build_existing_model.geometry_building_type_recs'] = df['build_existing_model.geometry_building_type_recs'].map(btype_map)
        groups = list(base_df[groupby_columns[0]].unique())
      else:
        groups = ['1-to-1']
        groupby_function = '1-to-1'

      if groupby_function == '1-to-1':
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

            if groupby_columns:
              x = x.loc[x[groupby_columns[0]] == group, :]
              y = y.loc[y[groupby_columns[0]] == group, :]

            fig.add_trace(go.Scatter(x=x[end_use], y=y[end_use], marker=dict(size=8), mode='markers', text=base_df.index, name='', legendgroup=end_use, showlegend=False), row=row, col=col)

            min_value, max_value = get_min_max(x[end_use], y[end_use], 0, 0)
            add_error_lines(fig, showlegend, row, col, min_value, max_value)
            fig.update_xaxes(title_text='base', row=row, col=col)
            fig.update_yaxes(title_text='feature', row=row, col=col)

        fig['layout'].update(title=file, template='plotly_white')
        fig.update_layout(width=800*len(groups), height=600*len(end_uses), autosize=False, font=dict(size=12))
        for i in fig['layout']['annotations']:
            i['font'] = dict(size=12) if i['text'] in end_uses else dict(size=12)
      else:
        if groupby_function == 'sum':
          base_df = base_df.groupby(groupby_columns).sum().reset_index()
          feature_df = feature_df.groupby(groupby_columns).sum().reset_index()
        elif groupby_function == 'mean':
          base_df = base_df.groupby(groupby_columns).mean().reset_index()
          feature_df = feature_df.groupby(groupby_columns).mean().reset_index()

        fig = make_subplots(rows=len(end_uses), cols=1, subplot_titles=[groupby_function]*len(end_uses), row_titles=[f'<b>{f}</b>' for f in end_uses], vertical_spacing = 0.015)

        row = 0
        for end_use in end_uses:  
          row += 1
          min_value = 0
          max_value = 0
          for group in groups:
            showlegend = False
            if row == 1: showlegend = True
            
            x = base_df
            y = feature_df
            
            x = x.loc[x[groupby_columns[0]] == group, :]
            y = y.loc[y[groupby_columns[0]] == group, :]

            fig.add_trace(go.Scatter(x=x[end_use], y=y[end_use], marker=dict(size=8), mode='markers', text=group, name=group, legendgroup=end_use, showlegend=showlegend), row=row, col=1)

            min_v, max_v = get_min_max(x[end_use], y[end_use], 0, 0)
            min_value = np.min([min_value, min_v])
            max_value = np.max([max_value, max_v])
          add_error_lines(fig, showlegend, row, 1, min_value, max_value)
          fig.update_xaxes(title_text='base', row=row, col=1)
          fig.update_yaxes(title_text='feature', row=row, col=1)

        fig['layout'].update(title=file, template='plotly_white')
        fig.update_layout(width=800, height=600*len(end_uses), autosize=False, font=dict(size=12))
        for i in fig['layout']['annotations']:
            i['font'] = dict(size=12) if i['text'] in end_uses else dict(size=12)

      basename, ext = os.path.splitext(file)
      if groupby_columns:
        basename += '_{groupby_column}'.format(groupby_column=groupby_columns[0])

      plotly.offline.plot(fig, filename=os.path.join(self.export_folder, '{basename}_{groupby_function}.html'.format(basename=basename, groupby_function=groupby_function)), auto_open=False)

if __name__ == '__main__':

  default_base_folder = 'workflow/tests/base_results'
  default_feature_folder = 'workflow/tests/results'
  default_export_folder = 'workflow/tests/comparisons'

  actions = [method for method in dir(BaseCompare) if method.startswith('__') is False]

  groupby_columns = []
  groupby_functions = ['1-to-1', 'sum', 'mean']

  parser = argparse.ArgumentParser()
  parser.add_argument('-b', '--base_folder', default=default_base_folder, help='TODO')
  parser.add_argument('-f', '--feature_folder', default=default_feature_folder, help='TODO')
  parser.add_argument('-a', '--actions', action='append', choices=actions, help='TODO')
  parser.add_argument('-e', '--export_folder', default=default_export_folder, help='TODO')
  parser.add_argument('-gc', '--groupby_column', choices=groupby_columns, help='TODO')
  parser.add_argument('-gf', '--groupby_function', default='sum', choices=groupby_functions, help='TODO')
  parser.add_argument('-m', '--mapping', help='TODO')
  args = parser.parse_args()

  if not os.path.exists(args.export_folder):
    os.makedirs(args.export_folder)

  compare = BaseCompare(args.base_folder, args.feature_folder, args.export_folder)

  if args.actions == None:
    args.actions = [] 

  for action in args.actions:
    if action == 'results':
      compare.results(args.groupby_column, args.groupby_function)
    elif action == 'visualize':
      compare.visualize(args.groupby_column, args.groupby_function)
