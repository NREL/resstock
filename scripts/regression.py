import os
import pandas as pd
import plotly
import plotly.graph_objects as go
from datetime import date

thisdir = os.path.join(os.path.dirname(os.path.abspath(__file__)))
parentdir = os.path.join(thisdir, '..')

progressdir = os.path.join(parentdir, 'resstock-regression')

def total_per_unit(total, building_type, num_units_sfa, num_units_mf):
  if building_type in ['Single-Family Detached', 'Mobile Home']:
    return total / 1.0
  elif building_type in ['Single-Family Attached']:
    return total / float(num_units_sfa)
  elif building_type in ['Multi-Family with 2 - 4 Units', 'Multi-Family with 5+ Units']:
    return total / float(num_units_mf)
  else:
    sys.exit('Unsupported type: {}'.format(building_type))

def eui_per_unit(total, building_type, floor_area, num_units_sfa, num_units_mf):
  if building_type in ['Single-Family Detached', 'Mobile Home']:
    return (total / 1.0) / floor_area
  elif building_type in ['Single-Family Attached']:
    return (total / floor_area) / float(num_units_sfa)
  elif building_type in ['Multi-Family with 2 - 4 Units', 'Multi-Family with 5+ Units']:
    return (total / floor_area) / float(num_units_mf)
  else:
    sys.exit('Unsupported type: {}'.format(building_type))

dfs = []
for path, subdirs, files in os.walk(progressdir):
  for subdir in subdirs:

    if not 'v' in subdir:
      continue

    filepath = os.path.join(progressdir, subdir, 'results.csv')
    df = pd.read_csv(filepath)

    df['VERSION'] = subdir
    df['TOTAL_SITE_PER_UNIT'] = df.apply(lambda x: total_per_unit(x['total_site_energy_mbtu'], x['geometry_building_type_recs'], x['geometry_building_number_units_sfa'], x['geometry_building_number_units_mf']), axis=1)
    df['SITE_EUI_PER_UNIT'] = df.apply(lambda x: eui_per_unit(x['total_site_energy_mbtu'], x['geometry_building_type_recs'], x['floor_area_conditioned_ft_2'], x['geometry_building_number_units_sfa'], x['geometry_building_number_units_mf']), axis=1)

    df = df[['PROJECT', 'VERSION', 'geometry_building_type_recs', 'TOTAL_SITE_PER_UNIT', 'SITE_EUI_PER_UNIT']]

    dfs.append(df)

df = pd.concat(dfs)

layout = go.Layout(
    xaxis=dict(title='month')
) 

date = date.today().strftime('%Y-%m-%d')
if not os.path.exists(os.path.join(progressdir, date)):
    os.makedirs(os.path.join(progressdir, date))

for project in df['PROJECT'].unique():
  t = df.copy()

  t = t[t['PROJECT']==project]

  if not os.path.exists(os.path.join(progressdir, date, project)):
      os.makedirs(os.path.join(progressdir, date, project))

  for values in ['TOTAL_SITE_PER_UNIT', 'SITE_EUI_PER_UNIT']:
    print('{}, {}...'.format(project, values))

    d = t.copy()

    d = d.pivot(index='VERSION', columns='geometry_building_type_recs', values=values)

    fig = go.Figure()
    for col in d.columns:    
      fig.add_trace(go.Scatter(x=d.index, y=d[col], name=col))

    fig.update_layout(
      xaxis = dict(
        tickangle = -90
      )
    )
    plotly.offline.plot(fig, filename=os.path.join(progressdir, date, project, '{}.html'.format(values)), auto_open=False)