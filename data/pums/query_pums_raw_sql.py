
import os
import pandas as pd
import psycopg2 as pg

con_string = "host={} port={} dbname={} user={} password={}".format(os.environ['GIS_HOST'], os.environ['GIS_PORT'], os.environ['GIS_DBNAME'], os.environ['GIS_USER'], os.environ['GIS_PASSWORD'])

def retrieve_data(st):  
    if not os.path.exists('pums_2011_{}_microdata.pkl'.format(st)):
      con = pg.connect(con_string)
      sql = """SELECT * FROM pums_2011.ipums_acs_2011_5yr_{} order by random() limit 10000;""".format(st)
      df = pd.read_sql(sql, con)
      df.to_pickle('pums_2011_{}_microdata.pkl'.format(st))
    df = pd.read_pickle('pums_2011_{}_microdata.pkl'.format(st))
    return df
    
def regenerate(st):
  df = retrieve_data(st)
  return df

def assign_vintage(df):

  vintagekey = {0: None,
                1: '<1950',
                2: '<1950',
                3: '1950s',
                4: '1960s',
                5: '1970s',
                6: '1980s',
                7: '1990s',
                8: '1990s',
                9: '2000s',
                10: '2000s',
                11: '2000s',
                12: '2000s',
                13: '2000s',
                14: '2000s',
                15: '2000s',
                16: '2000s',
                17: '2000s'}

  df['vintage'] = df.apply(lambda x: vintagekey[x.builtyr2], axis=1)
  
  return df
  
def assign_heatingfuel(df):

  heatingfuelkey = {0: None,
                    1: 'None',
                    2: 'Natural Gas',
                    3: 'Propane',
                    4: 'Electricity',
                    5: 'Fuel Oil',
                    6: 'Coal',
                    7: 'Wood',
                    8: 'Solar',
                    9: 'Other'}

  df['heatingfuel'] = df.apply(lambda x: heatingfuelkey[x.fuelheat], axis=1)
  
  return df
  
if __name__ == '__main__':
  
  dfs = []
  # for st in ['co', 'ca', 'la', 'fl', 'tx', 'mn']:
  for st in ['co']:
    df = regenerate(st)
    df = assign_vintage(df)
    df = assign_heatingfuel(df)
    dfs.append(df)
    
  pd.concat(dfs).to_csv(os.path.join(os.path.dirname(__file__), 'MLR', 'pums.csv'), index=False)
