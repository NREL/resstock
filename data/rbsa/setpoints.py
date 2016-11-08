import sqlalchemy
import pandas as pd
import matplotlib
import matplotlib.pyplot as plt
import numpy as np
from scipy.cluster.vq import kmeans

matplotlib.rc('font', **{'size': 8})

# HEATING SETPOINTS

# meter
engine = sqlalchemy.create_engine('sqlite:///c:/RBSA/year1/RBSA_METER_DATA_1/RBSA_METER_DATA_1.sqlite')
dict = {'meter_min_cluster':[], 'meter_max_cluster':[]}
for siteid in pd.read_sql_query("SELECT DISTINCT siteid FROM RBSA_METER_DATA", engine).values:
  siteid = int(siteid[0])
  df = pd.read_sql_query("SELECT siteid, time, IDT from RBSA_METER_DATA WHERE siteid='{}'".format(siteid), engine)
  df['siteid'] = df['siteid'].astype('int')
  df = df.set_index('siteid')
  df = df.dropna()
  df['month'] = df['time'].apply(lambda x: x[2:5])
  df = df.loc[df['month'].isin(['DEC', 'JAN', 'FEB'])]
  if pd.isnull(df['IDT']).all():
    continue
  codebook, _ = kmeans(np.array(df['IDT']), 2) # two clusters
  dict['meter_min_cluster'].append(min(codebook))
  dict['meter_max_cluster'].append(max(codebook))
  
df_meter = pd.DataFrame.from_dict(dict)

# audit
engine = sqlalchemy.create_engine('sqlite:///c:/OpenStudio-ResStock/OpenStudio-ResStock/data/rbsa/rbsa.sqlite')
df = pd.read_sql_query("SELECT siteid, ResInt_HeatTemp, ResInt_HeatTempNight from SF_ri_heu", engine)
resint_heattemp = df['ResInt_HeatTemp']
resint_heattemp = resint_heattemp[resint_heattemp > 0].dropna()
resint_heattempnight = df['ResInt_HeatTempNight']
resint_heattempnight = resint_heattempnight[resint_heattempnight > 0].dropna()
dict = {'heattemp': resint_heattemp, 'heattempnight': resint_heattempnight}
df_audit = pd.DataFrame.from_dict(dict)

# plot
plt.figure()
df_meter.plot.kde()
df_audit.plot.kde(ax=plt.gca())
plt.savefig('htgstpt.png', dpi=200)

# COOLING SETPOINTS

# meter
engine = sqlalchemy.create_engine('sqlite:///c:/RBSA/year1/RBSA_METER_DATA_1/RBSA_METER_DATA_1.sqlite')
dict = {'meter_min_cluster':[], 'meter_max_cluster':[]}
for siteid in pd.read_sql_query("SELECT DISTINCT siteid FROM RBSA_METER_DATA", engine).values:
  siteid = int(siteid[0])
  df = pd.read_sql_query("SELECT siteid, time, IDT from RBSA_METER_DATA WHERE siteid='{}'".format(siteid), engine)
  df['siteid'] = df['siteid'].astype('int')
  df = df.set_index('siteid')
  df = df.dropna()
  df['month'] = df['time'].apply(lambda x: x[2:5])
  df = df.loc[df['month'].isin(['JUN', 'JUL', 'AUG'])]
  if pd.isnull(df['IDT']).all():
    continue
  codebook, _ = kmeans(np.array(df['IDT']), 2) # two clusters
  dict['meter_min_cluster'].append(min(codebook))
  dict['meter_max_cluster'].append(max(codebook))
  
df_meter = pd.DataFrame.from_dict(dict)

# audit
engine = sqlalchemy.create_engine('sqlite:///c:/OpenStudio-ResStock/OpenStudio-ResStock/data/rbsa/rbsa.sqlite')
df = pd.read_sql_query("SELECT siteid, ResInt_ACTemp, ResInt_ACNight from SF_ri_heu", engine)
resint_actemp = df['ResInt_ACTemp']
resint_actemp = resint_actemp[resint_actemp > 0].dropna()
resint_acnight = df['ResInt_ACNight']
resint_acnight = resint_acnight[resint_acnight > 0].dropna()
dict_actemp = {'actemp': resint_actemp}
df_audit_actemp = pd.DataFrame.from_dict(dict_actemp)
dict_acnight  = {'acnight': resint_acnight}
df_audit_acnight = pd.DataFrame.from_dict(dict_acnight)

# plot
plt.figure()
df_meter.plot.kde()
df_audit_actemp.plot.kde(ax=plt.gca())
df_audit_acnight.plot.kde(ax=plt.gca())
plt.savefig('clgstpt.png', dpi=200)