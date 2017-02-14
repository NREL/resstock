
import os
import pandas as pd
import psycopg2 as pg

con_string = "host={} port={} dbname={} user={} password={}".format(os.environ['GIS_HOST'], os.environ['GIS_PORT'], os.environ['GIS_DBNAME'], os.environ['GIS_USER'], os.environ['GIS_PASSWORD'])

def retrieve_data():
  if not os.path.exists('acs_2011_tractdata.pkl'):
    con = pg.connect(con_string)
    # sql = """SELECT * FROM acs_2011.acs_tract_5yr limit 100;"""
    sql = """SELECT * FROM acs_2011.acs_tract_5yr;"""
    df = pd.read_sql(sql, con)
    spatial = assemble_spatial(con, retrieve_spatial_headers(con), df['spatial'], df['gisjoin'])
    data = assemble_data(con, retrieve_data_headers(con), df['acs_data'], df['gisjoin'])
    df = pd.concat([spatial, data], axis=1)    
    df.to_pickle('acs_2011_tractdata.pkl')
  df = pd.read_pickle('acs_2011_tractdata.pkl')
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
  
def assemble_spatial(con, s, data, ix):
  df = pd.DataFrame(data.tolist(), columns=s, index=ix)
  return df
  
def assemble_data(con, s, data, ix):
  df = pd.DataFrame(data.tolist(), columns=s, index=ix)
  return df  
  
def regenerate():
  df = retrieve_data()
  return df

if __name__ == '__main__':

  df = regenerate()
  
  df.to_csv('acs.csv')
  