import os
import sys
import numpy as np
import itertools
import pandas as pd

class Create_DFs():
    
    def __init__(self, file):
        self.session = pd.read_csv(file, index_col=['CONTROL'])

    def hvac_system_cooling_type(self):
        df = pd.DataFrame({'Dependency=HVAC System Cooling': ['None',	'AC, SEER 8', 'AC, SEER 10', 'AC, SEER 13', 'AC, SEER 15', 'FIXME Room AC, EER 8.5, 20% Conditioned', 'FIXME Room AC, EER 10.7, 20% Conditioned'], 'Option=Central': [0, 1, 1, 1, 1, 0, 0], 'Option=Room':[0, 0, 0, 0, 0, 1, 1], 'Option=None':[1, 0, 0, 0, 0, 0, 0]}).set_index('Dependency=HVAC System Cooling')
        return df
        
    def federal_poverty_level(self):
        df = self.session
        df = df[df['tenure'].isin(['Own', 'Rent'])]
        df = df[df['size'].isin(['0-1499', '1500-2499', '2500-3499', '3500+'])]
        # df['fplbinstenure'] = df.apply(lambda x: '{}, {}'.format(x.tenure, x.fplbins), axis=1)
        df = df.rename(columns={'division': 'Dependency=Location Census Division', 'vintage': 'Dependency=Vintage', 'size': 'Dependency=Geometry House Size', 'actype': 'Dependency=HVAC System Cooling Type'})
        df, cols = categories_to_columns(df, 'fplbins')
        cd = df['Dependency=Location Census Division'].unique()
        df = df.groupby(['Dependency=Location Census Division', 'Dependency=Vintage', 'Dependency=Geometry House Size', 'Dependency=HVAC System Cooling Type'])
        missing_groups = []
        for group in itertools.product(*[cd, ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s'], ['0-1499', '1500-2499', '2500-3499', '3500+'], ['None', 'Central', 'Room']]):
            if not group in list(df.groups):
                missing_groups.append(dict(zip(['Dependency=Location Census Division', 'Dependency=Vintage', 'Dependency=Geometry House Size', 'Dependency=HVAC System Cooling Type'], group)))
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight']
        df = sum_cols(df, cols)
        df['Count'] = count
        df['Weight'] = weight
        columns = list(df.columns)
        columns.remove('Count')
        columns.remove('Weight')
        for group in missing_groups:
            df_new = pd.DataFrame(data=dict(group.items() + dict(zip(columns, [1.0/len(columns)] * len(columns))).items()), index=[0]).set_index(['Dependency=Location Census Division', 'Dependency=Vintage', 'Dependency=Geometry House Size', 'Dependency=HVAC System Cooling Type'])
            df_new['Count'] = 0
            df_new['Weight'] = 0
            df = df.append(df_new)
        df = add_option_prefix(df)
        # df = df[['Option=Own, 0-50', 'Option=Own, 50-100', 'Option=Own, 100-150', 'Option=Own, 150-200', 'Option=Own, 200-250', 'Option=Own, 250-300', 'Option=Own, 300+', 'Option=Rent, 0-50', 'Option=Rent, 50-100', 'Option=Rent, 100-150', 'Option=Rent, 150-200', 'Option=Rent, 200-250', 'Option=Rent, 250-300', 'Option=Rent, 300+', 'Count', 'Weight']]
        df = df[['Option=0-50', 'Option=50-100', 'Option=100-150', 'Option=150-200', 'Option=200-250', 'Option=250-300', 'Option=300+', 'Count', 'Weight']]
        df = df.reset_index()
        df['Dependency=Location Census Division'] = pd.Categorical(df['Dependency=Location Census Division'], cd)
        df['Dependency=Vintage'] = pd.Categorical(df['Dependency=Vintage'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s'])
        df['Dependency=Geometry House Size'] = pd.Categorical(df['Dependency=Geometry House Size'], ['0-1499', '1500-2499', '2500-3499', '3500+'])
        df['Dependency=HVAC System Cooling Type'] = pd.Categorical(df['Dependency=HVAC System Cooling Type'], ['None', 'Central', 'Room'])
        df = df.sort_values(by=['Dependency=Location Census Division', 'Dependency=Vintage', 'Dependency=Geometry House Size', 'Dependency=HVAC System Cooling Type']).set_index(['Dependency=Location Census Division', 'Dependency=Vintage', 'Dependency=Geometry House Size', 'Dependency=HVAC System Cooling Type'])
        return df
    
    def geometry_house_size(self):
        df = self.session
        df = df[df['size'].isin(['0-1499', '1500-2499', '2500-3499', '3500+'])]
        df = df.rename(columns={'division': 'Dependency=Location Census Division', 'vintage': 'Dependency=Vintage'})
        df, cols = categories_to_columns(df, 'size')
        df = df.groupby(['Dependency=Location Census Division', 'Dependency=Vintage'])
        missing_groups = []
        for group in itertools.product(*[['New England', 'East North Central', 'Middle Atlantic', 'Mountain - Pacific', 'South Atlantic - East South Central', 'West North Central', 'West South Central'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s']]):
            if not group in list(df.groups):
                missing_groups.append(dict(zip(['Dependency=Location Census Division', 'Dependency=Vintage'], group)))
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight']
        df = sum_cols(df, cols)
        df['Count'] = count
        df['Weight'] = weight
        columns = list(df.columns)
        columns.remove('Count')
        columns.remove('Weight')
        for group in missing_groups:
            df_new = pd.DataFrame(data=dict(group.items() + dict(zip(columns, [1.0/len(columns)] * len(columns))).items()), index=[0]).set_index(['Dependency=Location Census Division', 'Dependency=Vintage'])
            df_new['Count'] = 0
            df_new['Weight'] = 0
            df = df.append(df_new)
        df = add_option_prefix(df)
        df = df[['Option=0-1499', 'Option=1500-2499', 'Option=2500-3499', 'Option=3500+', 'Count', 'Weight']]
        df = df.reset_index()
        df['Dependency=Location Census Division'] = pd.Categorical(df['Dependency=Location Census Division'], ['New England', 'East North Central', 'Middle Atlantic', 'Mountain - Pacific', 'South Atlantic - East South Central', 'West North Central', 'West South Central'])
        df['Dependency=Vintage'] = pd.Categorical(df['Dependency=Vintage'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s'])
        df = df.sort_values(by=['Dependency=Location Census Division', 'Dependency=Vintage']).set_index(['Dependency=Location Census Division', 'Dependency=Vintage'])
        return df
        
    def income(self):
        df = self.session
        df = df.head(100)
        df = df[['income', 'WEIGHT']]
        df = df.groupby('income').sum()
        df['frac'] = df['WEIGHT'] / df['WEIGHT'].sum()
        df = df[['frac']]
        df = df.T.reset_index(drop=True)
        df = add_option_prefix(df)
        df = df[['Option=0-25K', 'Option=25-50K', 'Option=50-75K', 'Option=75-100K', 'Option=100-125K', 'Option=125-150K', 'Option=150-200K', 'Option=200K+']].set_index('Option=0-25K')
        return df   
    
    def location_msa_cd(self):
        df = self.session
        df = df[df['tenure'].isin(['Own', 'Rent'])]
        df = df[df['size'].isin(['0-1499', '1500-2499', '2500-3499', '3500+'])]
        tracts = pd.read_csv('../acs/acs.csv', usecols=['gisjoin'])['gisjoin']
        df['Dependency=Location Census Tract'] = np.random.choice(tracts, df.shape[0])
        df = df.head(10) # TODO
        df, cols = categories_to_columns(df, 'location')
        df = df.groupby(['Dependency=Location Census Tract'])
        missing_groups = []
        for group in itertools.product(*[tracts]):
            if not group in list(df.groups):
                missing_groups.append(dict(zip(['Dependency=Location Census Tract'], group)))
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight']
        df = sum_cols(df, cols)
        df['Count'] = count
        df['Weight'] = weight
        columns = list(df.columns)
        columns.remove('Count')
        columns.remove('Weight')
        for group in missing_groups:
            df_new = pd.DataFrame(data=dict(group.items() + dict(zip(columns, [1.0/len(columns)] * len(columns))).items()), index=[0]).set_index(['Dependency=Location Census Tract'])
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
    
    datafiles_dir = '../../project_resstock_national/housing_characteristics'

    dfs = Create_DFs('MLR/ahs.csv')
    
    for category in ['Location MSA CD', 'Federal Poverty Level', 'HVAC System Cooling Type', 'Geometry House Size']:
        print category
        method = getattr(dfs, category.lower().replace(' ', '_'))
        df = method()
        df.to_csv(os.path.join(datafiles_dir, '{}.tsv'.format(category)), sep='\t')
        