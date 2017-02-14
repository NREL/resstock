import pandas as pd
import datetime as dt
    
def normalize(df, fields, total):
    for field in fields:
        df[field] = df[field] / df[total]
    df.replace([pd.np.inf, -pd.np.inf], 0, inplace=True)
    return df
    
def map_cols(df, field_dict):
    for from_col, to_col in field_dict.iteritems():
        if to_col in df.columns:
            df[to_col] += df[from_col]
        else:
            df[to_col] = df[from_col]
    return df
    
def assign_vintage(session):
    
    df = pd.read_csv(session)
    df = df.rename(columns={'gisjoin': 'Dependency=Census Tract'}).set_index('Dependency=Census Tract')    
    
    total = 'MTUE002'
   
    fields = {'MTXE002':'2010s',
              'MTXE003':'2000s',
              'MTXE004':'1990s',
              'MTXE005':'1980s',
              'MTXE006':'1970s',
              'MTXE007':'1960s',
              'MTXE008':'1950s',
              'MTXE009':'<1950',
              'MTXE010':'<1950'}
              
    df = normalize(df, fields.keys(), total)
    df = map_cols(df, fields)
    
    df = df[list(set(fields.values())) + [total]]
    
    df = df.rename(columns={total: 'Weight'})
    df['Count'] = 1
        
    return df
    
def assign_income(session):
    
    df = pd.read_csv(session)
    df = df.rename(columns={'gisjoin': 'Dependency=Census Tract'}).set_index('Dependency=Census Tract')    
   
    total = 'MTUE002'
   
    fields = {'MP0E002': '<$10,000',
              'MP0E003': '$10,000-14,999',
              'MP0E004': '$15,000-19,999',
              'MP0E005': '$20,000-24,999',
              'MP0E006': '$25,000-29,999',
              'MP0E007': '$30,000-34,999',
              'MP0E008': '$35,000-39,999',
              'MP0E009': '$40,000-44,999',
              'MP0E010': '$45,000-49,999',
              'MP0E011': '$50,000-59,999',
              'MP0E012': '$60,000-74,999',
              'MP0E013': '$75,000-99,999',
              'MP0E014': '$100,000-124,999',
              'MP0E015': '$125,000-149,999',
              'MP0E016': '$150,000-199,999',
              'MP0E017': '$200,000+'}
              
    df = normalize(df, fields.keys(), total)
    df = map_cols(df, fields)
    
    df = df[list(set(fields.values())) + [total]]
    
    df = df.rename(columns={total: 'Weight'})
    df['Count'] = 1
        
    return df
    
def assign_census_tract(session):
    
    df = pd.read_csv(session)
    df = df.rename(columns={'gisjoin': 'Dependency=Census Tract'}).set_index('Dependency=Census Tract')    
   
    total = 'MTUE002'
    
    df = df[[total]]
    df['frac'] = df[[total]] / df[[total]].sum()
    
    df = df[['frac']]
    df = df.transpose()
        
    return df
