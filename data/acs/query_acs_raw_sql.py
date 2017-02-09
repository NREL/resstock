
import os
import pandas as pd
import psycopg2 as pg

con_string = "host={} port={} dbname={} user={} password={}".format(os.environ['GIS_HOST'], os.environ['GIS_PORT'], os.environ['GIS_DBNAME'], os.environ['GIS_USER'], os.environ['GIS_PASSWORD'])

def retrieve_data():
  if not os.path.exists('acs_2011_tractdata'):
    con = pg.connect(con_string)
    sql = """SELECT * FROM acs_2011.acs_tract_5yr;"""
    df = pd.read_sql(sql, con)
    df.to_pickle('acs_2011_tractdata.pkl')
    s = retrieve_headers(con)
    df = df.rename(s)
  df = pd.read_pickle('acs_2011_tractdata.pkl')
  return df

def retrieve_headers(con):  
  sql = """SELECT * FROM acs_2011.acs_tract_5yr;"""
  df = pd.read_sql(sql, con)
  s = something
  return s
    
def regenerate():
  df = retrieve_data()
  return df

if __name__ == '__main__':

  df = regenerate()
  print df.head()
  sys.exit()  
