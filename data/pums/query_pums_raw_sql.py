
import os
import pandas as pd
import psycopg2 as pg

con_string = "host={} port={} dbname={} user={} password={}".format(os.environ['GIS_HOST'], os.environ['GIS_PORT'], os.environ['GIS_DBNAME'], os.environ['GIS_USER'], os.environ['GIS_PASSWORD'])

def retrieve_data():
  if not os.path.exists('pums_2011_microdata'):    
    con = pg.connect(con_string)
    sql = """SELECT * FROM pums_2011.ipums_acs_2011_5yr_co;"""
    df = pd.read_sql(sql, con)
    df.to_pickle('pums_2011_microdata.pkl')
    s = retrieve_headers(con)
    df = df.rename(s)
  df = pd.read_pickle('pums_2011_microdata.pkl')
  return df

def retrieve_headers(con):
  sql = """SELECT * FROM pums_2011.variables_lookup;"""
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
