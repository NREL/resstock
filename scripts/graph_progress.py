import os
import pandas as pd
import shutil
import matplotlib.pyplot as plt
from matplotlib import dates
from datetime import datetime

thisdir = os.path.join(os.path.dirname(os.path.abspath(__file__)))
parentdir = os.path.join(thisdir, '..')

progressdir = os.path.join(parentdir, 'simulation_output')

dfs = []
for path, subdirs, files in os.walk(progressdir):
  for subdir in subdirs:

    filepath = os.path.join(progressdir, subdir, 'simulation_output.csv')
    df = pd.read_csv(filepath)
    df['total_site_energy_mbtu_per_simulation'] = df['simulation_output_report.total_site_energy_mbtu'] / df['simulation_output_report.applicable']
    df = df[['build_existing_model.geometry_building_type', 'total_site_energy_mbtu_per_simulation']]
    df['date'] = dates.date2num(datetime.strptime(subdir, '%Y-%m-%d'))

    dfs.append(df)

df = pd.concat(dfs)
df = df.pivot(index='date', columns='build_existing_model.geometry_building_type', values='total_site_energy_mbtu_per_simulation')
plot = df.plot()
plt.xticks(rotation=90)
plt.ylabel('total_site_energy_mbtu_per_simulation')
plt.grid()
fig = plot.get_figure()
fig.set_size_inches(16, 12)
ax = fig.axes[0]
ax.xaxis.set_major_formatter(dates.DateFormatter('%Y-%m-%d'))
plt.tight_layout(pad=0)
fig.savefig(os.path.join(progressdir, 'simulation_output.png'))