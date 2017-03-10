__author__ = 'ewilson'

import os
import sys
import numpy as np
import itertools
import pandas as pd

class Create_DFs():
    
    def __init__(self, file):
        self.session = pd.read_csv(file, index_col=['WMO'])

    def location_iecc_epw(self):
        df = self.session
        df = df.rename(columns={'IECC ZONE': 'Dependency=Climate Zone'})
        usaf = pd.read_csv('by_usaf.csv', index_col=['usaf'])
        df = df.join(usaf, how='inner')
        df, cols = categories_to_columns(df, 'EPW')
        df = df.groupby(['Dependency=Climate Zone'])
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight']
        df = sum_cols(df, cols)
        df['Count'] = count
        df['Weight'] = weight
        df = add_option_prefix(df)        
        return df

    def location_ba_epw(self):
        df = self.session
        df = df.rename(columns={'BA ZONE': 'Dependency=Climate Zone'})
        usaf = pd.read_csv('by_usaf.csv', index_col=['usaf'])
        df = df.join(usaf, how='inner')
        df, cols = categories_to_columns(df, 'EPW')
        df = df.groupby(['Dependency=Climate Zone'])
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight']
        df = sum_cols(df, cols)
        df['Count'] = count
        df['Weight'] = weight
        df = add_option_prefix(df)        
        return df
    
def categories_to_columns(df, column, svywt=True):
    categories = df[column]
    unique_categories = categories.unique()
    unique_category_weights = []
    for category in unique_categories:
        if svywt:
            df[category] = df.apply(lambda x: x['TotalSFD'] * (1.0 / len(df[df.index==x.name])) if x[column] == category else 0, axis=1)
            df['%s_weight' % category] = df.apply(lambda x: x['TotalSFD'] * (1.0 / len(df[df.index==x.name])) if x[column] == category else 0, axis=1)
            unique_category_weights.append('%s_weight' % category)
        else:
            df[category] = df.apply(lambda x: 1 if x[column] == category else 0, axis=1)
            unique_category_weights.append(category)

    df['Weight'] = df[unique_category_weights].sum(axis=1)
        
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

    dfs = Create_DFs('Zones.csv')
    
    for category in ['Location IECC EPW', 'Location BA EPW']:
        print category
        method = getattr(dfs, category.lower().replace(' ', '_'))
        df = method()
        df.to_csv(os.path.join(datafiles_dir, '{}.tsv'.format(category)), sep='\t')
        