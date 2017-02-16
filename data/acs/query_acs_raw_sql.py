
import os
import pandas as pd
import psycopg2 as pg

con_string = "host={} port={} dbname={} user={} password={}".format(os.environ['GIS_HOST'], os.environ['GIS_PORT'], os.environ['GIS_DBNAME'], os.environ['GIS_USER'], os.environ['GIS_PASSWORD'])

cols = ['MTUE002', 'MTUM002', 
        'MTXE001', 'MTXE002', 'MTXE003', 'MTXE004', 'MTXE005', 'MTXE006', 'MTXE007', 'MTXE008', 'MTXE009', 'MTXE010', 'MTXM001', 'MTXM002', 'MTXM003', 'MTXM004', 'MTXM005', 'MTXM006', 'MTXM007', 'MTXM008', 'MTXM009', 'MTXM010',
        'MP0E001', 'MP0E002', 'MP0E003', 'MP0E004', 'MP0E005', 'MP0E006', 'MP0E007', 'MP0E008', 'MP0E009', 'MP0E010', 'MP0E011', 'MP0E012', 'MP0E013', 'MP0E014', 'MP0E015', 'MP0E016', 'MP0E017', 'MP0M001', 'MP0M002', 'MP0M003', 'MP0M004', 'MP0M005', 'MP0M006', 'MP0M007', 'MP0M008', 'MP0M009', 'MP0M010', 'MP0M011', 'MP0M012', 'MP0M013', 'MP0M014', 'MP0M015', 'MP0M016', 'MP0M017']

def retrieve_data():
  pkls = []
  for file in os.listdir(os.path.dirname(os.path.abspath(__file__))):
    if file.endswith('.pkl'):
      pkls.append(file)
  if not len(pkls) > 0:
    con = pg.connect(con_string)
    # sql = """SELECT * FROM acs_2011.acs_tract_5yr limit 1;"""
    sql = """SELECT * FROM acs_2011.acs_tract_5yr;""" # 74,001
    positions = [retrieve_data_headers(con).index(x) for x in cols]
    for i, df in enumerate(pd.read_sql(sql, con, chunksize=10000)):
      spatial = assemble_spatial(retrieve_spatial_headers(con), df['spatial'], df['gisjoin'])
      data = assemble_data(cols, df['acs_data'], df['gisjoin'], positions)
      data = data.loc[(data['MTUE002'] > 0) | (data['MTUM002'] > 0)] # SFD
      df = pd.concat([spatial, data], axis=1)
      df.to_pickle('acs_2011_tractdata_{}.pkl'.format(i))
      pkls.append('acs_2011_tractdata_{}.pkl'.format(i))
  dfs = []
  for pkl in pkls:
    dfs.append(pd.read_pickle(pkl))
  df = pd.concat(dfs)
  return df

def retrieve_data_headers(con):
  sql = """SELECT code FROM acs_2011.code_lookup_5yr;"""
  df = pd.read_sql(sql, con)
  s = df['code'].tolist()
  return s

def retrieve_spatial_headers(con):
  sql = """SELECT code FROM acs_2011.spatial_lookup_5yr;"""
  df = pd.read_sql(sql, con)
  s = df['code'].tolist()
  return s
  
def assemble_spatial(s, data, ix):
  df = pd.DataFrame(data.tolist(), columns=s, index=ix)
  return df
  
def assemble_data(s, data, ix, positions):
  data = data.tolist()
  subset = [[x[i] for i in positions] for x in data]
  df = pd.DataFrame(subset, columns=s, index=ix)
  return df

if __name__ == '__main__':

  df = retrieve_data()
  
  df.to_csv('acs.csv')
  