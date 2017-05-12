
import os, sys
import pandas as pd
import datetime as dt
import numpy as np
import itertools

class Create_DFs():

    def __init__(self, file):
        self.session = file

    def vintage(self):
        df = pd.read_csv(self.session)
        df = df.rename(columns={'gisjoin': 'Dependency=Census Tract'}).set_index('Dependency=Census Tract')    
        
        total1 = 'MTXE001'
        total2 = 'MTXM001'
        
        df['Total'] = df[total1] + df[total2]
        total = 'Total'
       
        fields = {'MTXE002':'2010s',
                  'MTXE003':'2000s',
                  'MTXE004':'1990s',
                  'MTXE005':'1980s',
                  'MTXE006':'1970s',
                  'MTXE007':'1960s',
                  'MTXE008':'1950s',
                  'MTXE009':'<1950',
                  'MTXE010':'<1950',
                  'MTXM002':'2010s',
                  'MTXM003':'2000s',
                  'MTXM004':'1990s',
                  'MTXM005':'1980s',
                  'MTXM006':'1970s',
                  'MTXM007':'1960s',
                  'MTXM008':'1950s',
                  'MTXM009':'<1950',
                  'MTXM010':'<1950'}
                  
        df = normalize(df, fields.keys(), total)
        df = map_cols(df, fields)
            
        df['Count'] = 1
        df['Weight'] = df['MTUE002'] + df['MTUM002']
        
        df = df[list(set(fields.values())) + ['Count'] + ['Weight']]

        df = add_option_prefix(df)
        df = df[['Option=<1950', 'Option=1950s', 'Option=1960s', 'Option=1970s', 'Option=1980s', 'Option=1990s', 'Option=2000s', 'Count', 'Weight']]
        return df
               
    def income(self):
        df = pd.read_csv(self.session)
        df = df.rename(columns={'gisjoin': 'Dependency=Census Tract'}).set_index('Dependency=Census Tract')    
       
        total1 = 'MP0E001'
        total2 = 'MP0M001'
        
        df['Total'] = df[total1] + df[total2]
        total = 'Total'    
       
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
                  'MP0E017': '$200,000+',
                  'MP0M002': '<$10,000',
                  'MP0M003': '$10,000-14,999',
                  'MP0M004': '$15,000-19,999',
                  'MP0M005': '$20,000-24,999',
                  'MP0M006': '$25,000-29,999',
                  'MP0M007': '$30,000-34,999',
                  'MP0M008': '$35,000-39,999',
                  'MP0M009': '$40,000-44,999',
                  'MP0M010': '$45,000-49,999',
                  'MP0M011': '$50,000-59,999',
                  'MP0M012': '$60,000-74,999',
                  'MP0M013': '$75,000-99,999',
                  'MP0M014': '$100,000-124,999',
                  'MP0M015': '$125,000-149,999',
                  'MP0M016': '$150,000-199,999',
                  'MP0M017': '$200,000+'}
                  
        df = normalize(df, fields.keys(), total)
        df = map_cols(df, fields)
        
        df['Count'] = 1
        df['Weight'] = df['MTUE002'] + df['MTUM002']
        
        df = df[list(set(fields.values())) + ['Count'] + ['Weight']]
    
        df = add_option_prefix(df)
        df = df[['Option=<$10,000', 'Option=$10,000-14,999', 'Option=$15,000-19,999', 'Option=$20,000-24,999', 'Option=$25,000-29,999', 'Option=$30,000-34,999', 'Option=$35,000-39,999', 'Option=$40,000-44,999', 'Option=$45,000-49,999', 'Option=$50,000-59,999', 'Option=$60,000-74,999', 'Option=$75,000-99,999', 'Option=$100,000-124,999', 'Option=$125,000-149,999', 'Option=$150,000-199,999', 'Option=$200,000+', 'Count', 'Weight']]
        return df
        
    def location_census_tract(self):
        df = pd.read_csv(self.session)
        epws = pd.read_csv('../other/by_usaf.csv', usecols=['EPW'])['EPW']
        df['Dependency=Location EPW'] = np.random.choice(epws, df.shape[0])
        df['Dependency=Vintage'] = np.random.choice(['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s'], df.shape[0])
        df['Dependency=Heating Fuel'] = np.random.choice(['Electricity', 'Fuel Oil', 'Natural Gas', 'Propane', 'Other Fuel'], df.shape[0])
        df = df.head(100) # TODO
        df, cols = categories_to_columns(df, 'gisjoin')
        df = df.groupby(['Dependency=Location EPW', 'Dependency=Vintage', 'Dependency=Heating Fuel'])
        missing_groups = []
        for group in itertools.product(*[epws.unique(), ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s'], ['Electricity', 'Fuel Oil', 'Natural Gas', 'Propane', 'Other Fuel']]):
            if not group in list(df.groups):
                missing_groups.append(dict(zip(['Dependency=Location EPW', 'Dependency=Vintage', 'Dependency=Heating Fuel'], group)))
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight']
        df = sum_cols(df, cols)
        df['Count'] = count
        df['Weight'] = weight
        columns = list(df.columns)
        columns.remove('Count')
        columns.remove('Weight')
        for group in missing_groups:
            df_new = pd.DataFrame(data=dict(group.items() + dict(zip(columns, [1.0/len(columns)] * len(columns))).items()), index=[0]).set_index(['Dependency=Location EPW', 'Dependency=Vintage', 'Dependency=Heating Fuel'])
            df_new['Count'] = 0
            df_new['Weight'] = 0
            df = df.append(df_new)
        df = add_option_prefix(df)
        return df
        
def categories_to_columns(df, column):
    categories = df[column]
    unique_categories = categories.unique()
    unique_category_weights = []
    for category in unique_categories:
        df[category] = df.apply(lambda x: (x['MTUE002'] + x['MTUM002']) * (1.0 / len(df[df.index==x.name])) if x[column] == category else 0, axis=1)

    df['Weight'] = df[unique_categories].sum(axis=1)
        
    return df, sorted(unique_categories.tolist())
        
def sum_cols(df, cols):
    
    df = df[cols]
    df_colsum = df.sum()

    return df_colsum.div(df_colsum.sum(axis=1), axis=0)
        
def add_option_prefix(df):
    for col in df.columns:
        if not 'Dependency=' in col and not 'Count' in col and not 'Weight' in col and not 'group' in col:
            if col in ['GSHP', 'Dual-Fuel ASHP, SEER 14, 8.2 HSPF', 'Gas Stove, 75% AFUE', 'Oil Stove', 'Propane Stove', 'Wood Stove', 'Evaporative Cooler']:
                df.rename(columns={col: 'Option=FIXME {}'.format(col)}, inplace=True)
            else:
                df.rename(columns={col: 'Option={}'.format(col)}, inplace=True)
    return df
        
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
        
if __name__ == '__main__':

    datafiles_dir = '../../project_resstock_national/housing_characteristics'

    dfs = Create_DFs('acs.csv')

    for category in ['Location Census Tract', 'Vintage', 'Income']:
        print category
        method = getattr(dfs, category.lower().replace(' ', '_'))
        df = method()
        df.to_csv(os.path.join(datafiles_dir, '{}.tsv'.format(category)), sep='\t')