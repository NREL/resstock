
import os
import pandas as pd
import psycopg2 as pg

con_string = "host={} port={} dbname={} user={} password={}".format(os.environ['GIS_HOST'], os.environ['GIS_PORT'], os.environ['GIS_DBNAME'], os.environ['GIS_USER'], os.environ['GIS_PASSWORD'])

cols = ['serial', 'unitsstr', 'hhincome', 'repwt', 'hhwt', 'builtyr2', 'rooms', 'fuelheat', 'bedrooms', 'hhtype', 'vacancy', 'state_abbr', 'nfams', 'numprec']

def retrieve_tables():
    con = pg.connect(con_string)
    sql = """SELECT table_name FROM information_schema.tables WHERE table_schema='pums_2011';"""
    df = pd.read_sql(sql, con)
    table_names = list(df['table_name'])
    state_tables = []
    for table_name in table_names:
      if not table_name.startswith("ipums_acs") or table_name.endswith("parent") or table_name.endswith("metadata") or table_name.endswith("puma_codes"):
        continue
      state_tables.append(table_name)
    return state_tables

def retrieve_data(table):
    pkls = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'pkls')
    if not os.path.exists(os.path.join(pkls, '{}.pkl'.format(table))):
      con = pg.connect(con_string)
      # sql = """SELECT {} FROM pums_2011.{} where unitsstr='3' order by random() limit 1000;""".format(",".join(cols), table)
      # sql = """SELECT {} FROM pums_2011.{} where unitsstr='3' limit 50000;""".format(",".join(cols), table)
      sql = """SELECT {} FROM pums_2011.{};""".format(",".join(cols), table)
      try:
        df = pd.read_sql(sql, con)
        df.to_pickle(os.path.join(pkls, '{}.pkl'.format(table)))
      except MemoryError:
        print '\t ... MemoryError'
        return None
    try:
      df = pd.read_pickle(os.path.join(pkls, '{}.pkl'.format(table)))
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
                15: '2010s',
                16: '2010s',
                17: '2010s'}

  df['vintage'] = df.apply(lambda x: vintagekey[x.builtyr2], axis=1)
  
  return df
  
def assign_heating_fuel(df):

  heatingfuelkey = {0: 'None',
                    1: 'None',
                    2: 'Natural Gas',
                    3: 'Propane/LPG',
                    4: 'Electricity',
                    5: 'Fuel Oil',
                    6: 'Other Fuel',
                    7: 'Other Fuel',
                    8: 'Other Fuel',
                    9: 'Other Fuel'}

  df['heatingfuel'] = df.apply(lambda x: heatingfuelkey[x.fuelheat], axis=1)
  
  return df
  
def assign_federal_poverty_level(df):
  
  # https://aspe.hhs.gov/2011-poverty-guidelines-federal-register-notice
  incomelimitkey = {1: 10890.0,
                    2: 14710.0,
                    3: 18530.0,
                    4: 22350.0,
                    5: 26170.0,
                    6: 29990.0,
                    7: 33810.0,
                    8: 37630.0}
  
  def incomelimit(famsize, ftotinc):
    if famsize <= 8:
      incomelimit = incomelimitkey[famsize]
    else:
      incomelimit = incomelimitkey[8] + (famsize - 8) * 3820.0
    return ftotinc * 100.0 / incomelimit
  
  df['fpl'] = df.apply(lambda x: incomelimit(x.famsize, x.ftotinc), axis=1)
  
  return df
  
if __name__ == '__main__':
  
  dfs = []
  for table in retrieve_tables():
    print ' ... {}'.format(table)
    df = retrieve_data(table)
    if df is None:
      continue
    df = df.drop_duplicates()
    df = assign_vintage(df)
    df = assign_heating_fuel(df)
    # df = assign_federal_poverty_level(df)
    dfs.append(df)
    
  pd.concat(dfs).to_csv(os.path.join(os.path.dirname(__file__), 'MLR', 'pums.csv'), index=False)
