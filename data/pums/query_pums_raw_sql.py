
import os
import pandas as pd
import psycopg2 as pg

con_string = "host={} port={} dbname={} user={} password={}".format(os.environ['GIS_HOST'], os.environ['GIS_PORT'], os.environ['GIS_DBNAME'], os.environ['GIS_USER'], os.environ['GIS_PASSWORD'])

cols = ['unitsstr', 'hhincome', 'repwt', 'hhwt', 'builtyr2', 'rooms', 'fuelheat', 'bedrooms', 'hhtype', 'region', 'ownershp', 'acrehous', 'kitchen', 'plumbing', 'vehicles', 'race', 'stateicp', 'statefip', 'vacancy', 'state_abbr']

def retrieve_tables():
    con = pg.connect(con_string)
    sql = """SELECT table_name FROM information_schema.tables WHERE table_schema='pums_2011';"""
    df = pd.read_sql(sql, con)
    table_names = list(df['table_name'])
    state_tables = []
    for table_name in table_names:
      if not table_name.startswith("ipums_acs") or table_name.endswith("parent") or table_name.endswith("metadata") or table_name.endswith("puma_codes"):
        continue
      # if table_name.endswith('5yr_ca') or table_name.endswith('5yr_oh') or table_name.endswith('5yr_nj'): # MemoryError
        # continue
      # if table_name.endswith("5yr_md") or table_name.endswith("5yr_nd") or table_name.endswith('5yr_nm'): # python.exe error
        # continue
      state_tables.append(table_name)
    return state_tables

def retrieve_data(table):  
    if not os.path.exists('{}.pkl'.format(table)):
      con = pg.connect(con_string)
      # sql = """SELECT {} FROM pums_2011.{} where unitsstr='3' order by random() limit 1000;""".format(",".join(cols), table)
      sql = """SELECT {} FROM pums_2011.{} where unitsstr='3' limit 50000;""".format(",".join(cols), table)
      # sql = """SELECT {} FROM pums_2011.{};""".format(",".join(cols), table)
      try:
        df = pd.read_sql(sql, con)
        df.to_pickle('{}.pkl'.format(table))
      except MemoryError:
        print '\t ... MemoryError'
        return None
    try:
      df = pd.read_pickle('{}.pkl'.format(table))
    except MemoryError:
      print '\t ... MemoryError'
      return None
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
  for table in retrieve_tables():
    print ' ... {}'.format(table)
    df = retrieve_data(table)
    if df is None:
      continue
    df = assign_vintage(df)
    df = assign_heatingfuel(df)
    dfs.append(df)
    
  pd.concat(dfs).to_csv(os.path.join(os.path.dirname(__file__), 'MLR', 'pums.csv'), index=False)
