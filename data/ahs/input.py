__author__ = 'ewilson'

import os
import sys
import numpy as np
import itertools
import pandas as pd

class Create_DFs():
    
    def __init__(self, file):
        self.session = pd.read_csv(file, index_col=['CONTROL'])

    def federal_poverty_level_own(self):
        df = self.session
        df = df[df['tenure']=='Own']
        df = df.rename(columns={'metro3': 'Dependency=Location', 'vintage': 'Dependency=Vintage', 'size': 'Dependency=Geometry House Size', 'actype': 'Dependency=HVAC System Cooling'})
        df, cols = categories_to_columns(df, 'fplbins')
        unique_location = df['Dependency=Location'].unique()
        unique_vintage = df['Dependency=Vintage'].unique()
        unique_geometry_house_size = df['Dependency=Geometry House Size'].unique()
        unique_hvac_system_cooling = df['Dependency=HVAC System Cooling'].unique()
        df = df.groupby(['Dependency=Location', 'Dependency=Vintage', 'Dependency=Geometry House Size', 'Dependency=HVAC System Cooling'])
        missing_groups = []
        for group in itertools.product(*[unique_location, unique_vintage, unique_geometry_house_size, unique_hvac_system_cooling]):
            if not group in list(df.groups):
                missing_groups.append(dict(zip(['Dependency=Location', 'Dependency=Vintage', 'Dependency=Geometry House Size', 'Dependency=HVAC System Cooling'], group)))
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight']
        df = sum_cols(df, cols)
        df['Count'] = count
        df['Weight'] = weight
        columns = list(df.columns)
        columns.remove('Count')
        columns.remove('Weight')
        for group in missing_groups:
            df_new = pd.DataFrame(data=dict(group.items() + dict(zip(columns, [1.0/len(columns)] * len(columns))).items()), index=[0]).set_index(['Dependency=Location', 'Dependency=Vintage', 'Dependency=Geometry House Size', 'Dependency=HVAC System Cooling'])
            df_new['Count'] = 0
            df_new['Weight'] = 0
            df = df.append(df_new)
        df = add_option_prefix(df)
        df = df[['Option=0-50', 'Option=50-100', 'Option=100-150', 'Option=150-200', 'Option=200-250', 'Option=250-300', 'Option=300+', 'Count', 'Weight']]
        df = df.reset_index()
        df['Dependency=Location'] = pd.Categorical(df['Dependency=Location'], unique_location)
        df['Dependency=Vintage'] = pd.Categorical(df['Dependency=Vintage'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s'])
        df['Dependency=Geometry House Size'] = pd.Categorical(df['Dependency=Geometry House Size'], ['0-1499', '1500-2499', '2500-3499', '3500+', 'Blank'])
        df['Dependency=HVAC System Cooling'] = pd.Categorical(df['Dependency=HVAC System Cooling'], ['Central', 'Room', 'None'])
        df = df.sort_values(by=['Dependency=Location', 'Dependency=Vintage', 'Dependency=Geometry House Size', 'Dependency=HVAC System Cooling']).set_index(['Dependency=Location', 'Dependency=Vintage', 'Dependency=Geometry House Size', 'Dependency=HVAC System Cooling'])
        return df
    
    def federal_poverty_level_rent(self):
        df = self.session
        df = df[df['tenure']=='Rent']
        df = df.rename(columns={'metro3': 'Dependency=Location', 'vintage': 'Dependency=Vintage', 'size': 'Dependency=Geometry House Size', 'actype': 'Dependency=HVAC System Cooling'})
        df, cols = categories_to_columns(df, 'fplbins')
        unique_location = df['Dependency=Location'].unique()
        unique_vintage = df['Dependency=Vintage'].unique()
        unique_geometry_house_size = df['Dependency=Geometry House Size'].unique()
        unique_hvac_system_cooling = df['Dependency=HVAC System Cooling'].unique()
        df = df.groupby(['Dependency=Location', 'Dependency=Vintage', 'Dependency=Geometry House Size', 'Dependency=HVAC System Cooling'])
        missing_groups = []
        for group in itertools.product(*[unique_location, unique_vintage, unique_geometry_house_size, unique_hvac_system_cooling]):
            if not group in list(df.groups):
                missing_groups.append(dict(zip(['Dependency=Location', 'Dependency=Vintage', 'Dependency=Geometry House Size', 'Dependency=HVAC System Cooling'], group)))
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight']
        df = sum_cols(df, cols)
        df['Count'] = count
        df['Weight'] = weight
        columns = list(df.columns)
        columns.remove('Count')
        columns.remove('Weight')
        for group in missing_groups:
            df_new = pd.DataFrame(data=dict(group.items() + dict(zip(columns, [1.0/len(columns)] * len(columns))).items()), index=[0]).set_index(['Dependency=Location', 'Dependency=Vintage', 'Dependency=Geometry House Size', 'Dependency=HVAC System Cooling'])
            df_new['Count'] = 0
            df_new['Weight'] = 0
            df = df.append(df_new)
        df = add_option_prefix(df)
        df = df[['Option=0-50', 'Option=50-100', 'Option=100-150', 'Option=150-200', 'Option=200-250', 'Option=250-300', 'Option=300+', 'Count', 'Weight']]
        df = df.reset_index()
        df['Dependency=Location'] = pd.Categorical(df['Dependency=Location'], unique_location)
        df['Dependency=Vintage'] = pd.Categorical(df['Dependency=Vintage'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s'])
        df['Dependency=Geometry House Size'] = pd.Categorical(df['Dependency=Geometry House Size'], ['0-1499', '1500-2499', '2500-3499', '3500+', 'Blank'])
        df['Dependency=HVAC System Cooling'] = pd.Categorical(df['Dependency=HVAC System Cooling'], ['Central', 'Room', 'None'])
        df = df.sort_values(by=['Dependency=Location', 'Dependency=Vintage', 'Dependency=Geometry House Size', 'Dependency=HVAC System Cooling']).set_index(['Dependency=Location', 'Dependency=Vintage', 'Dependency=Geometry House Size', 'Dependency=HVAC System Cooling'])
        return df
    
    def geometry_house_size(self):
        df = self.session
        df = df.rename(columns={'metro3': 'Dependency=Location', 'vintage': 'Dependency=Vintage', 'income': 'Dependency=Income'})
        df, cols = categories_to_columns(df, 'size')
        unique_location = df['Dependency=Location'].unique()
        unique_vintage = df['Dependency=Vintage'].unique()
        unique_income = df['Dependency=Income'].unique()
        df = df.groupby(['Dependency=Location', 'Dependency=Vintage', 'Dependency=Income'])
        missing_groups = []
        for group in itertools.product(*[unique_location, unique_vintage, unique_income]):
            if not group in list(df.groups):
                missing_groups.append(dict(zip(['Dependency=Location', 'Dependency=Vintage', 'Dependency=Income'], group)))
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight']
        df = sum_cols(df, cols)
        df['Count'] = count
        df['Weight'] = weight
        columns = list(df.columns)
        columns.remove('Count')
        columns.remove('Weight')
        for group in missing_groups:
            df_new = pd.DataFrame(data=dict(group.items() + dict(zip(columns, [1.0/len(columns)] * len(columns))).items()), index=[0]).set_index(['Dependency=Location', 'Dependency=Vintage', 'Dependency=Income'])
            df_new['Count'] = 0
            df_new['Weight'] = 0
            df = df.append(df_new)
        df = add_option_prefix(df)
        df = df[['Option=0-1499', 'Option=1500-2499', 'Option=2500-3499', 'Option=3500+', 'Count', 'Weight']]
        df = df.reset_index()
        df['Dependency=Location'] = pd.Categorical(df['Dependency=Location'], unique_location)
        df['Dependency=Vintage'] = pd.Categorical(df['Dependency=Vintage'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s'])
        df['Dependency=Income'] = pd.Categorical(df['Dependency=Income'], ['0-25K', '25-50K', '50-75K', '75-100K', '100-125K', '125-150K', '150-200K', '200K+'])
        df = df.sort_values(by=['Dependency=Location', 'Dependency=Vintage', 'Dependency=Income']).set_index(['Dependency=Location', 'Dependency=Vintage', 'Dependency=Income'])
        return df
    
def categories_to_columns(df, column):
    categories = df[column]
    unique_categories = categories.unique()
    unique_category_weights = []
    for category in unique_categories:
        df[category] = df.apply(lambda x: x['WEIGHT'] * (1.0 / len(df[df.index==x.name])) if x[column] == category else 0, axis=1)

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
    
if __name__ == '__main__':
    
    datafiles_dir = '../../resources/inputs/national'

    dfs = Create_DFs('MLR/ahs.csv')
    
    for category in ['Federal Poverty Level Own', 'Federal Poverty Level Rent', 'Geometry House Size']:
    # for category in ['Geometry House Size']:
        print category
        method = getattr(dfs, category.lower().replace(' ', '_'))
        df = method()
        df.to_csv(os.path.join(datafiles_dir, '{}.tsv'.format(category)), sep='\t')
        