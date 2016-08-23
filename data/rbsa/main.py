__author__ = 'ewilson'

import os
import rbsadbmodel as rdb
import util
#import matplotlib as mpl
#mpl.use('Agg') # Turn interactive plotting off
#mpl.use('qt4agg')
import matplotlib.pyplot as plt
import seaborn as sns
from matplotlib import rcParams
rcParams.update({'figure.autolayout': True})
import sys
import numpy as np
import itertools
import pandas as pd

class Create_DFs():
    
    def __init__(self, file):
        self.session = rdb.create_session(file)
        
    def location_region(self):
        df = util.create_dataframe(self.session, rdb)
        df = util.assign_climate_zones(df)
        df = util.assign_state(df)
        df = util.assign_location(df)
        df = util.assign_totalsfd(df)
        df, cols = util.categories_to_columns(df, 'Dependency=Location Region')
        df['group'] = 'all'
        df = df.groupby(['group'])
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight']
        df = util.sum_cols(df, cols)
        df['Count'] = count
        df['Weight'] = weight
        df = add_option_prefix(df)
        df = df.reset_index().set_index('Option=H1C1 OR')
        del df['group']
        return df
    
    def vintage(self):
        df = util.create_dataframe(self.session, rdb)
        df = util.assign_climate_zones(df)
        df = util.assign_state(df)
        df = util.assign_location(df)        
        df = util.assign_vintage(df)
        df, cols = util.categories_to_columns(df, 'Dependency=Vintage')
        df = df.groupby(['Dependency=Location Region'])
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight']
        df = util.sum_cols(df, cols)
        df['Count'] = count
        df['Weight'] = weight
        df = add_option_prefix(df)
        df = df[['Option=<1950', 'Option=1950s', 'Option=1960s', 'Option=1970s', 'Option=1980s', 'Option=1990s', 'Option=2000s', 'Count', 'Weight']]
        return df
    
    def heating_fuel(self):
        df = util.create_dataframe(self.session, rdb)
        df = util.assign_climate_zones(df)
        df = util.assign_state(df)
        df = util.assign_location(df)
        df = util.assign_vintage(df)
        df = util.assign_heating_fuel(df)
        df, cols = util.categories_to_columns(df, 'Dependency=Heating Fuel')      
        df = df.groupby(['Dependency=Location Region', 'Dependency=Vintage'])
        missing_groups = []
        for group in itertools.product(*[['H1C1 OR', 'H1C1 WA', 'H1C2', 'H1C3', 'H2', 'H3'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s']]):
            if not group in list(df.groups):
                missing_groups.append(dict(zip(['Dependency=Location Region', 'Dependency=Vintage'], group)))
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight']
        df = util.sum_cols(df, cols)
        df['Count'] = count
        df['Weight'] = weight
        columns = list(df.columns)
        columns.remove('Count')
        columns.remove('Weight')     
        for group in missing_groups:
            df_new = pd.DataFrame(data=dict(group.items() + dict(zip(columns, [1.0/len(columns)] * len(columns))).items()), index=[0]).set_index(['Dependency=Location Region', 'Dependency=Vintage'])
            df_new['Count'] = 0
            df_new['Weight'] = 0
            df = df.append(df_new)
        df = add_option_prefix(df)
        df = df[['Option=Electricity', 'Option=Natural Gas', 'Option=Fuel Oil', 'Option=Propane/LPG', 'Option=Wood', 'Count', 'Weight']]
        df = df.reset_index()
        df['Dependency=Vintage'] = pd.Categorical(df['Dependency=Vintage'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s'])        
        df = df.sort_values(by=['Dependency=Location Region', 'Dependency=Vintage']).set_index(['Dependency=Location Region', 'Dependency=Vintage'])        
        return df
        
    def insulation_unfinished_attic(self):
        df = util.create_dataframe(self.session, rdb)
        df = util.assign_climate_zones(df)
        df = util.assign_state(df)
        df = util.assign_location(df)
        df = util.assign_vintage(df)
        df = util.assign_ceiling(df)
        df, cols = util.categories_to_columns(df, 'rval')
        df = df.groupby(['Dependency=Location Region', 'Dependency=Vintage'])
        missing_groups = []
        for group in itertools.product(*[['H1C1 OR', 'H1C1 WA', 'H1C2', 'H1C3', 'H2', 'H3'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s']]):
            if not group in list(df.groups):
                missing_groups.append(dict(zip(['Dependency=Location Region', 'Dependency=Vintage'], group)))        
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight']
        df = util.sum_cols(df, cols)
        df['Count'] = count
        df['Weight'] = weight
        columns = list(df.columns)
        columns.remove('Count')
        columns.remove('Weight')   
        for group in missing_groups:
            df_new = pd.DataFrame(data=dict(group.items() + dict(zip(columns, [1.0/len(columns)] * len(columns))).items()), index=[0]).set_index(['Dependency=Location Region', 'Dependency=Vintage'])
            df_new['Count'] = 0
            df_new['Weight'] = 0
            df = df.append(df_new)
        df = add_option_prefix(df)
        df = df[['Option=Uninsulated, Vented', 'Option=Ceiling R-7, Vented', 'Option=Ceiling R-13, Vented', 'Option=Ceiling R-19, Vented', 'Option=Ceiling R-30, Vented', 'Option=Ceiling R-38, Vented', 'Option=Ceiling R-49, Vented', 'Option=Ceiling R-60, Vented', 'Count', 'Weight']]
        df = df.reset_index()
        df['Dependency=Vintage'] = pd.Categorical(df['Dependency=Vintage'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s'])
        df = df.sort_values(by=['Dependency=Location Region', 'Dependency=Vintage']).set_index(['Dependency=Location Region', 'Dependency=Vintage'])
        return df
    
    def insulation_unfinished_attic_h1(self):
        df = util.create_dataframe(self.session, rdb)
        df = util.assign_climate_zones(df)
        df = df[df['H']=='1']
        df = util.assign_state_2(df)
        df = util.assign_vintage(df)
        df = util.assign_ceiling_2(df)
        df, cols = util.categories_to_columns(df, 'rval')
        df = df.groupby(['Dependency=State', 'Dependency=Vintage'])
        missing_groups = []
        for group in itertools.product(*[['WA', 'OR', 'MT', 'ID'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s']]):
            if not group in list(df.groups):
                missing_groups.append(dict(zip(['Dependency=State', 'Dependency=Vintage'], group)))        
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight']
        df = util.sum_cols(df, cols)
        df['Count'] = count
        df['Weight'] = weight
        columns = list(df.columns)
        columns.remove('Count')
        columns.remove('Weight')   
        for group in missing_groups:
            df_new = pd.DataFrame(data=dict(group.items() + dict(zip(columns, [1.0/len(columns)] * len(columns))).items()), index=[0]).set_index(['Dependency=State', 'Dependency=Vintage'])
            df_new['Count'] = 0
            df_new['Weight'] = 0
            df = df.append(df_new)
        df = add_option_prefix(df)
        df = df[['Option=Uninsulated, Vented', 'Option=Ceiling R-7, Vented', 'Option=Ceiling R-13, Vented', 'Option=Ceiling R-19, Vented', 'Option=Ceiling R-30, Vented', 'Option=Ceiling R-38, Vented', 'Option=Ceiling R-49, Vented', 'Option=Ceiling R-60, Vented', 'Count', 'Weight']]
        df = df.reset_index()
        df['Dependency=Vintage'] = pd.Categorical(df['Dependency=Vintage'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s'])
        df = df.sort_values(by=['Dependency=State', 'Dependency=Vintage']).set_index(['Dependency=State', 'Dependency=Vintage'])
        return df
    
    def insulation_unfinished_attic_h2(self):
        df = util.create_dataframe(self.session, rdb)
        df = util.assign_climate_zones(df)
        df = df[df['H']=='2']
        df = util.assign_state_2(df)
        df = util.assign_vintage(df)
        df = util.assign_ceiling_2(df)
        df, cols = util.categories_to_columns(df, 'rval')
        df = df.groupby(['Dependency=State', 'Dependency=Vintage'])
        missing_groups = []
        for group in itertools.product(*[['WA', 'OR', 'MT', 'ID'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s']]):
            if not group in list(df.groups):
                missing_groups.append(dict(zip(['Dependency=State', 'Dependency=Vintage'], group)))        
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight']
        df = util.sum_cols(df, cols)
        df['Count'] = count
        df['Weight'] = weight
        columns = list(df.columns)
        columns.remove('Count')
        columns.remove('Weight')   
        for group in missing_groups:
            df_new = pd.DataFrame(data=dict(group.items() + dict(zip(columns, [1.0/len(columns)] * len(columns))).items()), index=[0]).set_index(['Dependency=State', 'Dependency=Vintage'])
            df_new['Count'] = 0
            df_new['Weight'] = 0
            df = df.append(df_new)
        df = add_option_prefix(df)
        df = df[['Option=Uninsulated, Vented', 'Option=Ceiling R-7, Vented', 'Option=Ceiling R-13, Vented', 'Option=Ceiling R-19, Vented', 'Option=Ceiling R-30, Vented', 'Option=Ceiling R-38, Vented', 'Option=Ceiling R-49, Vented', 'Option=Ceiling R-60, Vented', 'Count', 'Weight']]
        df = df.reset_index()
        df['Dependency=Vintage'] = pd.Categorical(df['Dependency=Vintage'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s'])
        df = df.sort_values(by=['Dependency=State', 'Dependency=Vintage']).set_index(['Dependency=State', 'Dependency=Vintage'])
        return df
    
    def insulation_unfinished_attic_h3(self):
        df = util.create_dataframe(self.session, rdb)
        df = util.assign_climate_zones(df)
        df = df[df['H']=='3']
        df = util.assign_state_2(df)
        df = util.assign_vintage(df)
        df = util.assign_ceiling_2(df)
        df, cols = util.categories_to_columns(df, 'rval')
        df = df.groupby(['Dependency=State', 'Dependency=Vintage'])
        missing_groups = []
        for group in itertools.product(*[['WA', 'OR', 'MT', 'ID'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s']]):
            if not group in list(df.groups):
                missing_groups.append(dict(zip(['Dependency=State', 'Dependency=Vintage'], group)))        
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight']
        df = util.sum_cols(df, cols)
        df['Count'] = count
        df['Weight'] = weight
        columns = list(df.columns)
        columns.remove('Count')
        columns.remove('Weight')   
        for group in missing_groups:
            df_new = pd.DataFrame(data=dict(group.items() + dict(zip(columns, [1.0/len(columns)] * len(columns))).items()), index=[0]).set_index(['Dependency=State', 'Dependency=Vintage'])
            df_new['Count'] = 0
            df_new['Weight'] = 0
            df = df.append(df_new)
        df = add_option_prefix(df)
        df['Option=Uninsulated, Vented'] = 0.0
        df = df[['Option=Uninsulated, Vented', 'Option=Ceiling R-7, Vented', 'Option=Ceiling R-13, Vented', 'Option=Ceiling R-19, Vented', 'Option=Ceiling R-30, Vented', 'Option=Ceiling R-38, Vented', 'Option=Ceiling R-49, Vented', 'Option=Ceiling R-60, Vented', 'Count', 'Weight']]
        df = df.reset_index()
        df['Dependency=Vintage'] = pd.Categorical(df['Dependency=Vintage'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s'])
        df = df.sort_values(by=['Dependency=State', 'Dependency=Vintage']).set_index(['Dependency=State', 'Dependency=Vintage'])
        return df
    
    def insulation_wall(self):
        df = util.create_dataframe(self.session, rdb)
        df = util.assign_climate_zones(df)
        df = util.assign_state(df)
        df = util.assign_location(df)
        df = util.assign_vintage(df)
        df = util.assign_wall(df)
        df, cols = util.categories_to_columns(df, 'rval')   
        df = df.groupby(['Dependency=Location Region', 'Dependency=Vintage'])
        missing_groups = []
        for group in itertools.product(*[['H1C1 OR', 'H1C1 WA', 'H1C2', 'H1C3', 'H2', 'H3'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s']]):
            if not group in list(df.groups):
                missing_groups.append(dict(zip(['Dependency=Location Region', 'Dependency=Vintage'], group)))        
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight']
        df = util.sum_cols(df, cols)
        df['Count'] = count
        df['Weight'] = weight
        columns = list(df.columns)
        columns.remove('Count')
        columns.remove('Weight')    
        for group in missing_groups:
            df_new = pd.DataFrame(data=dict(group.items() + dict(zip(columns, [1.0/len(columns)] * len(columns))).items()), index=[0]).set_index(['Dependency=Location Region', 'Dependency=Vintage'])
            df_new['Count'] = 0
            df_new['Weight'] = 0
            df = df.append(df_new)
        df = add_option_prefix(df)
        df = df[['Option=Uninsulated', 'Option=R-7', 'Option=R-13', 'Option=R-19', 'Option=R-36', 'Count', 'Weight']]
        df = df.reset_index()
        df['Dependency=Vintage'] = pd.Categorical(df['Dependency=Vintage'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s'])
        df = df.sort_values(by=['Dependency=Location Region', 'Dependency=Vintage']).set_index(['Dependency=Location Region', 'Dependency=Vintage'])        
        return df
    
    def insulation_wall_h1(self):
        df = util.create_dataframe(self.session, rdb)
        df = util.assign_climate_zones(df)
        df = df[df['H']=='1']
        df = util.assign_state_2(df)
        df = util.assign_vintage(df)
        df = util.assign_wall_2(df)
        df, cols = util.categories_to_columns(df, 'rval')   
        df = df.groupby(['Dependency=State', 'Dependency=Vintage'])
        missing_groups = []
        for group in itertools.product(*[['WA', 'OR', 'MT', 'ID'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s']]):
            if not group in list(df.groups):
                missing_groups.append(dict(zip(['Dependency=State', 'Dependency=Vintage'], group)))        
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight']
        df = util.sum_cols(df, cols)
        df['Count'] = count
        df['Weight'] = weight
        columns = list(df.columns)
        columns.remove('Count')
        columns.remove('Weight')    
        for group in missing_groups:
            df_new = pd.DataFrame(data=dict(group.items() + dict(zip(columns, [1.0/len(columns)] * len(columns))).items()), index=[0]).set_index(['Dependency=State', 'Dependency=Vintage'])
            df_new['Count'] = 0
            df_new['Weight'] = 0
            df = df.append(df_new)
        df = add_option_prefix(df)
        df = df[['Option=Uninsulated', 'Option=R-7', 'Option=R-13', 'Option=R-19', 'Option=R-36', 'Count', 'Weight']]
        df = df.reset_index()
        df['Dependency=Vintage'] = pd.Categorical(df['Dependency=Vintage'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s'])
        df = df.sort_values(by=['Dependency=State', 'Dependency=Vintage']).set_index(['Dependency=State', 'Dependency=Vintage'])        
        return df

    def insulation_wall_h2(self):
        df = util.create_dataframe(self.session, rdb)
        df = util.assign_climate_zones(df)
        df = df[df['H']=='2']
        df = util.assign_state_2(df)
        df = util.assign_vintage(df)
        df = util.assign_wall_2(df)
        df, cols = util.categories_to_columns(df, 'rval')   
        df = df.groupby(['Dependency=State', 'Dependency=Vintage'])
        missing_groups = []
        for group in itertools.product(*[['WA', 'OR', 'MT', 'ID'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s']]):
            if not group in list(df.groups):
                missing_groups.append(dict(zip(['Dependency=State', 'Dependency=Vintage'], group)))        
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight']
        df = util.sum_cols(df, cols)
        df['Count'] = count
        df['Weight'] = weight
        columns = list(df.columns)
        columns.remove('Count')
        columns.remove('Weight')    
        for group in missing_groups:
            df_new = pd.DataFrame(data=dict(group.items() + dict(zip(columns, [1.0/len(columns)] * len(columns))).items()), index=[0]).set_index(['Dependency=State', 'Dependency=Vintage'])
            df_new['Count'] = 0
            df_new['Weight'] = 0
            df = df.append(df_new)
        df = add_option_prefix(df)
        df = df[['Option=Uninsulated', 'Option=R-7', 'Option=R-13', 'Option=R-19', 'Option=R-36', 'Count', 'Weight']]
        df = df.reset_index()
        df['Dependency=Vintage'] = pd.Categorical(df['Dependency=Vintage'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s'])
        df = df.sort_values(by=['Dependency=State', 'Dependency=Vintage']).set_index(['Dependency=State', 'Dependency=Vintage'])        
        return df
    
    def insulation_wall_h3(self):
        df = util.create_dataframe(self.session, rdb)
        df = util.assign_climate_zones(df)
        df = df[df['H']=='3']
        df = util.assign_state_2(df)
        df = util.assign_vintage(df)
        df = util.assign_wall_2(df)
        df, cols = util.categories_to_columns(df, 'rval')   
        df = df.groupby(['Dependency=State', 'Dependency=Vintage'])
        missing_groups = []
        for group in itertools.product(*[['WA', 'OR', 'MT', 'ID'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s']]):
            if not group in list(df.groups):
                missing_groups.append(dict(zip(['Dependency=State', 'Dependency=Vintage'], group)))        
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight']
        df = util.sum_cols(df, cols)
        df['Count'] = count
        df['Weight'] = weight
        columns = list(df.columns)
        columns.remove('Count')
        columns.remove('Weight')    
        for group in missing_groups:
            df_new = pd.DataFrame(data=dict(group.items() + dict(zip(columns, [1.0/len(columns)] * len(columns))).items()), index=[0]).set_index(['Dependency=State', 'Dependency=Vintage'])
            df_new['Count'] = 0
            df_new['Weight'] = 0
            df = df.append(df_new)
        df = add_option_prefix(df)
        df = df[['Option=Uninsulated', 'Option=R-7', 'Option=R-13', 'Option=R-19', 'Option=R-36', 'Count', 'Weight']]
        df = df.reset_index()
        df['Dependency=Vintage'] = pd.Categorical(df['Dependency=Vintage'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s'])
        df = df.sort_values(by=['Dependency=State', 'Dependency=Vintage']).set_index(['Dependency=State', 'Dependency=Vintage'])        
        return df
    
    def geometry_foundation_type(self):
        df = util.create_dataframe(self.session, rdb)
        df = util.assign_climate_zones(df)
        df = util.assign_state(df)
        df = util.assign_location(df)
        df = util.assign_vintage(df)
        df = util.assign_foundation_type(df)
        df, cols = util.categories_to_columns(df, 'Dependency=Geometry Foundation Type')
        df = df.groupby(['Dependency=Location Region', 'Dependency=Vintage'])
        missing_groups = []
        for group in itertools.product(*[['H1C1 OR', 'H1C1 WA', 'H1C2', 'H1C3', 'H2', 'H3'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s']]):
            if not group in list(df.groups):
                missing_groups.append(dict(zip(['Dependency=Location Region', 'Dependency=Vintage'], group)))          
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight']
        df = util.sum_cols(df, cols)
        df['Count'] = count
        df['Weight'] = weight
        columns = list(df.columns)
        columns.remove('Count')
        columns.remove('Weight')    
        for group in missing_groups:
            df_new = pd.DataFrame(data=dict(group.items() + dict(zip(columns, [1.0/len(columns)] * len(columns))).items()), index=[0]).set_index(['Dependency=Location Region', 'Dependency=Vintage'])
            df_new['Count'] = 0
            df_new['Weight'] = 0
            df = df.append(df_new)
        df = add_option_prefix(df)
        df = df.reset_index()
        df['Dependency=Vintage'] = pd.Categorical(df['Dependency=Vintage'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s'])
        df = df.sort_values(by=['Dependency=Location Region', 'Dependency=Vintage']).set_index(['Dependency=Location Region', 'Dependency=Vintage'])
        return df
    
    def geometry_house_size(self):
        df = util.create_dataframe(self.session, rdb)
        df = util.assign_climate_zones(df)
        df = util.assign_state(df)
        df = util.assign_location(df)        
        df = util.assign_vintage(df) 
        df = util.assign_size(df)
        df, cols = util.categories_to_columns(df, 'Dependency=Geometry House Size')
        df = df.groupby(['Dependency=Location Region', 'Dependency=Vintage'])
        missing_groups = []
        for group in itertools.product(*[['H1C1 OR', 'H1C1 WA', 'H1C2', 'H1C3', 'H2', 'H3'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s']]):
            if not group in list(df.groups):
                missing_groups.append(dict(zip(['Dependency=Location Region', 'Dependency=Vintage'], group)))        
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight']
        df = util.sum_cols(df, cols)
        df['Count'] = count
        df['Weight'] = weight
        columns = list(df.columns)
        columns.remove('Count')
        columns.remove('Weight')       
        for group in missing_groups:
            df_new = pd.DataFrame(data=dict(group.items() + dict(zip(columns, [1.0/len(columns)] * len(columns))).items()), index=[0]).set_index(['Dependency=Location Region', 'Dependency=Vintage'])
            df_new['Count'] = 0
            df_new['Weight'] = 0
            df = df.append(df_new)
        df = add_option_prefix(df)
        df = df.reset_index()
        df['Dependency=Vintage'] = pd.Categorical(df['Dependency=Vintage'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s'])
        df = df.sort_values(by=['Dependency=Location Region', 'Dependency=Vintage']).set_index(['Dependency=Location Region', 'Dependency=Vintage'])
        return df
    
    def geometry_stories(self):       
        df = util.create_dataframe(self.session, rdb)
        df = util.assign_climate_zones(df)
        df = util.assign_state(df)
        df = util.assign_location(df)        
        df = util.assign_vintage(df) 
        df = util.assign_foundation_type(df)
        df = util.assign_size(df)
        df = util.assign_stories(df)
        df, cols = util.categories_to_columns(df, 'Dependency=Stories')
        df = df.groupby(['Dependency=Vintage', 'Dependency=Geometry House Size', 'Dependency=Geometry Foundation Type'])
        missing_groups = []
        for group in itertools.product(*[['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s'], ['0-1499', '1500-2499', '2500-3499', '3500-4499', '4500+'], ['Crawl', 'Heated Basement', 'Slab', 'Unheated Basement']]):
            if not group in list(df.groups):
                missing_groups.append(dict(zip(['Dependency=Vintage', 'Dependency=Geometry House Size', 'Dependency=Geometry Foundation Type'], group)))          
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight']
        df = util.sum_cols(df, cols)        
        df['Count'] = count
        df['Weight'] = weight
        columns = list(df.columns)
        columns.remove('Count')
        columns.remove('Weight')        
        for group in missing_groups:
            df_new = pd.DataFrame(data=dict(group.items() + dict(zip(columns, [1.0/len(columns)] * len(columns))).items()), index=[0]).set_index(['Dependency=Vintage', 'Dependency=Geometry House Size', 'Dependency=Geometry Foundation Type'])
            df_new['Count'] = 0
            df_new['Weight'] = 0
            df = df.append(df_new)
        df = add_option_prefix(df)
        df = df.reset_index()
        df['Dependency=Vintage'] = pd.Categorical(df['Dependency=Vintage'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s'])
        df = df.sort_values(by=['Dependency=Geometry Foundation Type', 'Dependency=Geometry House Size', 'Dependency=Vintage']).set_index(['Dependency=Geometry Foundation Type', 'Dependency=Geometry House Size', 'Dependency=Vintage'])
        return df
    
    def heating_setpoint(self):
        df = util.create_dataframe(self.session, rdb)
        df = util.assign_htgsp(df)
        df, cols = util.categories_to_columns(df, 'htgsp')
        df['group'] = 'all'
        df = df.groupby(['group'])
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight']
        df = util.sum_cols(df, cols)
        df['Count'] = count
        df['Weight'] = weight
        df = add_option_prefix(df)
        df = df.reset_index().set_index('Option=60F')
        del df['group']        
        return df
    
    def cooling_setpoint(self):
        df = util.create_dataframe(self.session, rdb)
        df = util.assign_clgsp(df)
        df, cols = util.categories_to_columns(df, 'clgsp')
        df['group'] = 'all'
        df = df.groupby(['group'])
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight']
        df = util.sum_cols(df, cols)
        df['Count'] = count
        df['Weight'] = weight
        df = add_option_prefix(df)
        df = df.reset_index().set_index('Option=65F')
        del df['group']        
        return df
    
    def insulation_slab(self):
        df = util.create_dataframe(self.session, rdb)
        df = util.assign_climate_zones(df)
        df = util.assign_state(df)
        df = util.assign_location(df)
        df = util.assign_vintage(df)
        df = util.assign_foundation_type(df)
        df = util.assign_slab(df)
        df, cols = util.categories_to_columns(df, 'rval')
        df = df.groupby(['Dependency=Location Region', 'Dependency=Vintage', 'Dependency=Geometry Foundation Type'])
        missing_groups = []
        for group in itertools.product(*[['H1C1 OR', 'H1C1 WA', 'H1C2', 'H1C3', 'H2', 'H3'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s'], ['Crawl', 'Heated Basement', 'Slab', 'Unheated Basement']]):
            if not group in list(df.groups):
                missing_groups.append(dict(zip(['Dependency=Location Region', 'Dependency=Vintage', 'Dependency=Geometry Foundation Type'], group)))        
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight']
        df = util.sum_cols(df, cols)
        df['Count'] = count
        df['Weight'] = weight
        columns = list(df.columns)
        columns.remove('Count')
        columns.remove('Weight')       
        for group in missing_groups:
            if group['Dependency=Geometry Foundation Type'] == 'Slab':
                columns.remove('None')
                data = dict(group.items() + dict(zip(columns, [1.0/len(columns)] * len(columns))).items())
                columns.append('None')
                data['None'] = 0
                df_new = pd.DataFrame(data=data, index=[0]).set_index(['Dependency=Location Region', 'Dependency=Vintage', 'Dependency=Geometry Foundation Type'])
            else:
                data = dict(group.items() + dict(zip(columns, [0] * len(columns))).items())
                data['None'] = 1
                df_new = pd.DataFrame(data=data, index=[0]).set_index(['Dependency=Location Region', 'Dependency=Vintage', 'Dependency=Geometry Foundation Type'])
            df_new['Count'] = 0
            df_new['Weight'] = 0
            df = df.append(df_new)
        df = add_option_prefix(df)
        df = df[['Option=Uninsulated', 'Option=4ft R5 Perimeter, R5 Gap', 'Option=R10 Whole Slab, R5 Gap', 'Option=None', 'Count', 'Weight']]
        df = df.reset_index()
        df['Dependency=Vintage'] = pd.Categorical(df['Dependency=Vintage'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s'])
        df = df.sort_values(by=['Dependency=Location Region', 'Dependency=Geometry Foundation Type', 'Dependency=Vintage']).set_index(['Dependency=Location Region', 'Dependency=Geometry Foundation Type', 'Dependency=Vintage'])
        return df               

    def insulation_crawlspace(self):
        df = util.create_dataframe(self.session, rdb)
        df = util.assign_climate_zones(df)
        df = util.assign_state(df)
        df = util.assign_location(df)
        df = util.assign_vintage(df)
        df = util.assign_foundation_type(df)
        df = util.assign_crawl(df)
        df, cols = util.categories_to_columns(df, 'rval')      
        df = df.groupby(['Dependency=Location Region', 'Dependency=Vintage', 'Dependency=Geometry Foundation Type'])
        missing_groups = []
        for group in itertools.product(*[['H1C1 OR', 'H1C1 WA', 'H1C2', 'H1C3', 'H2', 'H3'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s'], ['Crawl', 'Heated Basement', 'Slab', 'Unheated Basement']]):
            if not group in list(df.groups):
                missing_groups.append(dict(zip(['Dependency=Location Region', 'Dependency=Vintage', 'Dependency=Geometry Foundation Type'], group)))         
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight']
        df = util.sum_cols(df, cols)
        df['Count'] = count
        df['Weight'] = weight
        columns = list(df.columns)
        columns.remove('Count')
        columns.remove('Weight')      
        for group in missing_groups:
            if group['Dependency=Geometry Foundation Type'] == 'Crawl':
                columns.remove('None')
                data = dict(group.items() + dict(zip(columns, [1.0/len(columns)] * len(columns))).items())
                columns.append('None')
                data['None'] = 0
                df_new = pd.DataFrame(data=data, index=[0]).set_index(['Dependency=Location Region', 'Dependency=Vintage', 'Dependency=Geometry Foundation Type'])
            else:
                data = dict(group.items() + dict(zip(columns, [0] * len(columns))).items())
                data['None'] = 1
                df_new = pd.DataFrame(data=data, index=[0]).set_index(['Dependency=Location Region', 'Dependency=Vintage', 'Dependency=Geometry Foundation Type'])
            df_new['Count'] = 0
            df_new['Weight'] = 0
            df = df.append(df_new)
        df = add_option_prefix(df)
        df = df[['Option=Uninsulated, Unvented', 'Option=Uninsulated, Vented', 'Option=Wall R-13, Unvented', 'Option=Ceiling R-13, Vented', 'Option=Ceiling R-19, Vented', 'Option=Ceiling R-30, Vented', 'Option=None', 'Count', 'Weight']]
        df = df.reset_index()
        df['Dependency=Vintage'] = pd.Categorical(df['Dependency=Vintage'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s'])
        df = df.sort_values(by=['Dependency=Location Region', 'Dependency=Geometry Foundation Type', 'Dependency=Vintage']).set_index(['Dependency=Location Region', 'Dependency=Geometry Foundation Type', 'Dependency=Vintage'])        
        return df
    
    def insulation_unfinished_basement(self):
        df = util.create_dataframe(self.session, rdb)
        df = util.assign_climate_zones(df)
        df = util.assign_state(df)
        df = util.assign_location(df)
        df = util.assign_vintage(df)
        df = util.assign_foundation_type(df)
        df = util.assign_ufbsmt(df)
        df, cols = util.categories_to_columns(df, 'rval')
        df = df.groupby(['Dependency=Location Region', 'Dependency=Vintage', 'Dependency=Geometry Foundation Type'])
        missing_groups = []
        for group in itertools.product(*[['H1C1 OR', 'H1C1 WA', 'H1C2', 'H1C3', 'H2', 'H3'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s'], ['Crawl', 'Heated Basement', 'Slab', 'Unheated Basement']]):
            if not group in list(df.groups):
                missing_groups.append(dict(zip(['Dependency=Location Region', 'Dependency=Vintage', 'Dependency=Geometry Foundation Type'], group)))
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight']      
        df = util.sum_cols(df, cols)
        df['Count'] = count
        df['Weight'] = weight
        columns = list(df.columns)
        columns.remove('Count')
        columns.remove('Weight')
        for group in missing_groups:
            if group['Dependency=Geometry Foundation Type'] == 'Unheated Basement':
                columns.remove('None')
                data = dict(group.items() + dict(zip(columns, [1.0/len(columns)] * len(columns))).items())
                columns.append('None')
                data['None'] = 0
                df_new = pd.DataFrame(data=data, index=[0]).set_index(['Dependency=Location Region', 'Dependency=Vintage', 'Dependency=Geometry Foundation Type'])
            else:
                data = dict(group.items() + dict(zip(columns, [0] * len(columns))).items())
                data['None'] = 1
                df_new = pd.DataFrame(data=data, index=[0]).set_index(['Dependency=Location Region', 'Dependency=Vintage', 'Dependency=Geometry Foundation Type'])
            df_new['Count'] = 0
            df_new['Weight'] = 0
            df = df.append(df_new)
        df = add_option_prefix(df)
        df = df[['Option=Uninsulated', 'Option=Ceiling R-13', 'Option=Ceiling R-19', 'Option=None', 'Count', 'Weight']]
        df = df.reset_index()
        df['Dependency=Vintage'] = pd.Categorical(df['Dependency=Vintage'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s'])
        df = df.sort_values(by=['Dependency=Location Region', 'Dependency=Geometry Foundation Type', 'Dependency=Vintage']).set_index(['Dependency=Location Region', 'Dependency=Geometry Foundation Type', 'Dependency=Vintage'])        
        return df
    
    def insulation_finished_basement(self):
        df = util.create_dataframe(self.session, rdb)
        df = util.assign_climate_zones(df)
        df = util.assign_state(df)
        df = util.assign_location(df)
        df = util.assign_vintage(df)
        df = util.assign_foundation_type(df)
        df = util.assign_fbsmt(df)
        df, cols = util.categories_to_columns(df, 'rval')            
        df = df.groupby(['Dependency=Location Region', 'Dependency=Vintage', 'Dependency=Geometry Foundation Type'])
        missing_groups = []
        for group in itertools.product(*[['H1C1 OR', 'H1C1 WA', 'H1C2', 'H1C3', 'H2', 'H3'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s'], ['Crawl', 'Heated Basement', 'Slab', 'Unheated Basement']]):
            if not group in list(df.groups):
                missing_groups.append(dict(zip(['Dependency=Location Region', 'Dependency=Vintage', 'Dependency=Geometry Foundation Type'], group)))
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight']  
        df = util.sum_cols(df, cols)
        df['Count'] = count
        df['Weight'] = weight
        columns = list(df.columns)
        columns.remove('Count')
        columns.remove('Weight')
        for group in missing_groups:
            if group['Dependency=Geometry Foundation Type'] == 'Heated Basement':
                columns.remove('None')
                data = dict(group.items() + dict(zip(columns, [1.0/len(columns)] * len(columns))).items())
                columns.append('None')
                data['None'] = 0                
                df_new = pd.DataFrame(data=data, index=[0]).set_index(['Dependency=Location Region', 'Dependency=Vintage', 'Dependency=Geometry Foundation Type'])
            else:
                data = dict(group.items() + dict(zip(columns, [0] * len(columns))).items())
                data['None'] = 1
                df_new = pd.DataFrame(data=data, index=[0]).set_index(['Dependency=Location Region', 'Dependency=Vintage', 'Dependency=Geometry Foundation Type'])
            df_new['Count'] = 0
            df_new['Weight'] = 0
            df = df.append(df_new)
        df = add_option_prefix(df)
        df = df[['Option=Uninsulated', 'Option=Wall R-5', 'Option=Wall R-10', 'Option=Wall R-15', 'Option=None', 'Count', 'Weight']]
        df = df.reset_index()
        df['Dependency=Vintage'] = pd.Categorical(df['Dependency=Vintage'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s'])
        df = df.sort_values(by=['Dependency=Location Region', 'Dependency=Geometry Foundation Type', 'Dependency=Vintage']).set_index(['Dependency=Location Region', 'Dependency=Geometry Foundation Type', 'Dependency=Vintage'])        
        return df
    
    def insulation_interzonal_floor(self):
        df = util.create_dataframe(self.session, rdb)
        df = util.assign_climate_zones(df)
        df = util.assign_state(df)
        df = util.assign_location(df)
        df = util.assign_vintage(df)
        df = util.assign_intfloor(df)
        df, cols = util.categories_to_columns(df, 'rval')
        df = df.groupby(['Dependency=Location Region', 'Dependency=Vintage'])
        missing_groups = []
        for group in itertools.product(*[['H1C1 OR', 'H1C1 WA', 'H1C2', 'H1C3', 'H2', 'H3'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s']]):
            if not group in list(df.groups):
                missing_groups.append(dict(zip(['Dependency=Location Region', 'Dependency=Vintage'], group)))        
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight']  
        df = util.sum_cols(df, cols)
        df['Count'] = count
        df['Weight'] = weight
        columns = list(df.columns)
        columns.remove('Count')
        columns.remove('Weight')     
        for group in missing_groups:
            df_new = pd.DataFrame(data=dict(group.items() + dict(zip(columns, [1.0/len(columns)] * len(columns))).items()), index=[0]).set_index(['Dependency=Location Region', 'Dependency=Vintage'])
            df_new['Count'] = 0
            df_new['Weight'] = 0
            df = df.append(df_new)
        df = add_option_prefix(df)
        df = df[['Option=Uninsulated', 'Option=R-13', 'Option=R-19', 'Count', 'Weight']]
        df = df.reset_index()
        df['Dependency=Vintage'] = pd.Categorical(df['Dependency=Vintage'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s'])
        df = df.sort_values(by=['Dependency=Location Region', 'Dependency=Vintage']).set_index(['Dependency=Location Region', 'Dependency=Vintage'])        
        return df
    
    def windows(self):
        df = util.create_dataframe(self.session, rdb)
        df = util.assign_climate_zones(df)
        df = util.assign_state(df)
        df = util.assign_location(df)
        df = util.assign_vintage(df)
        df = util.assign_win(df)
        df, cols = util.categories_to_columns(df, 'rval')
        df = df.groupby(['Dependency=Location Region', 'Dependency=Vintage'])
        missing_groups = []
        for group in itertools.product(*[['H1C1 OR', 'H1C1 WA', 'H1C2', 'H1C3', 'H2', 'H3'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s']]):
            if not group in list(df.groups):
                missing_groups.append(dict(zip(['Dependency=Location Region', 'Dependency=Vintage'], group)))         
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight'] 
        df = util.sum_cols(df, cols)
        df['Count'] = count
        df['Weight'] = weight
        columns = list(df.columns)
        columns.remove('Count')
        columns.remove('Weight')        
        for group in missing_groups:
            df_new = pd.DataFrame(data=dict(group.items() + dict(zip(columns, [1.0/len(columns)] * len(columns))).items()), index=[0]).set_index(['Dependency=Location Region', 'Dependency=Vintage'])
            df_new['Count'] = 0
            df_new['Weight'] = 0
            df = df.append(df_new)
        df = add_option_prefix(df)
        df = df[['Option=Clear, Single, Metal', 'Option=Clear, Single, Non-metal', 'Option=Clear, Double, Metal, Air', 'Option=Clear, Double, Non-metal, Air', 'Option=Clear, Double, Thermal-Break, Air', 'Option=Low-E, Double, Non-metal, Air, M-Gain', 'Option=Low-E, Triple, Non-metal, Air, L-Gain', 'Count', 'Weight']]
        df = df.reset_index()
        df['Dependency=Vintage'] = pd.Categorical(df['Dependency=Vintage'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s'])
        df = df.sort_values(by=['Dependency=Location Region', 'Dependency=Vintage']).set_index(['Dependency=Location Region', 'Dependency=Vintage'])        
        return df
    
    def windows_h1(self):
        df = util.create_dataframe(self.session, rdb)
        df = util.assign_climate_zones(df)
        df = df[df['H']=='1']
        df = util.assign_state_2(df)
        df = util.assign_vintage(df)
        df = util.assign_win_2(df)
        df, cols = util.categories_to_columns(df, 'rval')
        df = df.groupby(['Dependency=State', 'Dependency=Vintage'])
        missing_groups = []
        for group in itertools.product(*[['WA', 'OR', 'MT', 'ID'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s']]):
            if not group in list(df.groups):
                missing_groups.append(dict(zip(['Dependency=State', 'Dependency=Vintage'], group)))         
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight'] 
        df = util.sum_cols(df, cols)
        df['Count'] = count
        df['Weight'] = weight
        columns = list(df.columns)
        columns.remove('Count')
        columns.remove('Weight')        
        for group in missing_groups:
            df_new = pd.DataFrame(data=dict(group.items() + dict(zip(columns, [1.0/len(columns)] * len(columns))).items()), index=[0]).set_index(['Dependency=State', 'Dependency=Vintage'])
            df_new['Count'] = 0
            df_new['Weight'] = 0
            df = df.append(df_new)
        df = add_option_prefix(df)
        df = df[['Option=Clear, Single, Metal', 'Option=Clear, Single, Non-metal', 'Option=Clear, Double, Metal, Air', 'Option=Clear, Double, Non-metal, Air', 'Option=Clear, Double, Thermal-Break, Air', 'Option=Low-E, Double, Non-metal, Air, M-Gain', 'Option=Low-E, Triple, Non-metal, Air, L-Gain', 'Count', 'Weight']]
        df = df.reset_index()
        df['Dependency=Vintage'] = pd.Categorical(df['Dependency=Vintage'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s'])
        df = df.sort_values(by=['Dependency=State', 'Dependency=Vintage']).set_index(['Dependency=State', 'Dependency=Vintage'])        
        return df
    
    def windows_h2(self):
        df = util.create_dataframe(self.session, rdb)
        df = util.assign_climate_zones(df)
        df = df[df['H']=='2']
        df = util.assign_state_2(df)
        df = util.assign_vintage(df)
        df = util.assign_win_2(df)
        df, cols = util.categories_to_columns(df, 'rval')
        df = df.groupby(['Dependency=State', 'Dependency=Vintage'])
        missing_groups = []
        for group in itertools.product(*[['WA', 'OR', 'MT', 'ID'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s']]):
            if not group in list(df.groups):
                missing_groups.append(dict(zip(['Dependency=State', 'Dependency=Vintage'], group)))         
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight'] 
        df = util.sum_cols(df, cols)
        df['Count'] = count
        df['Weight'] = weight
        columns = list(df.columns)
        columns.remove('Count')
        columns.remove('Weight')        
        for group in missing_groups:
            df_new = pd.DataFrame(data=dict(group.items() + dict(zip(columns, [1.0/len(columns)] * len(columns))).items()), index=[0]).set_index(['Dependency=State', 'Dependency=Vintage'])
            df_new['Count'] = 0
            df_new['Weight'] = 0
            df = df.append(df_new)
        df = add_option_prefix(df)
        df = df[['Option=Clear, Single, Metal', 'Option=Clear, Single, Non-metal', 'Option=Clear, Double, Metal, Air', 'Option=Clear, Double, Non-metal, Air', 'Option=Clear, Double, Thermal-Break, Air', 'Option=Low-E, Double, Non-metal, Air, M-Gain', 'Option=Low-E, Triple, Non-metal, Air, L-Gain', 'Count', 'Weight']]
        df = df.reset_index()
        df['Dependency=Vintage'] = pd.Categorical(df['Dependency=Vintage'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s'])
        df = df.sort_values(by=['Dependency=State', 'Dependency=Vintage']).set_index(['Dependency=State', 'Dependency=Vintage'])        
        return df
    
    def windows_h3(self):
        df = util.create_dataframe(self.session, rdb)
        df = util.assign_climate_zones(df)
        df = df[df['H']=='3']
        df = util.assign_state_2(df)
        df = util.assign_vintage(df)
        df = util.assign_win_2(df)
        df, cols = util.categories_to_columns(df, 'rval')
        df = df.groupby(['Dependency=State', 'Dependency=Vintage'])
        missing_groups = []
        for group in itertools.product(*[['WA', 'OR', 'MT', 'ID'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s']]):
            if not group in list(df.groups):
                missing_groups.append(dict(zip(['Dependency=State', 'Dependency=Vintage'], group)))         
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight'] 
        df = util.sum_cols(df, cols)
        df['Count'] = count
        df['Weight'] = weight
        columns = list(df.columns)
        columns.remove('Count')
        columns.remove('Weight')        
        for group in missing_groups:
            df_new = pd.DataFrame(data=dict(group.items() + dict(zip(columns, [1.0/len(columns)] * len(columns))).items()), index=[0]).set_index(['Dependency=State', 'Dependency=Vintage'])
            df_new['Count'] = 0
            df_new['Weight'] = 0
            df = df.append(df_new)
        df = add_option_prefix(df)
        df = df[['Option=Clear, Single, Metal', 'Option=Clear, Single, Non-metal', 'Option=Clear, Double, Metal, Air', 'Option=Clear, Double, Non-metal, Air', 'Option=Clear, Double, Thermal-Break, Air', 'Option=Low-E, Double, Non-metal, Air, M-Gain', 'Option=Low-E, Triple, Non-metal, Air, L-Gain', 'Count', 'Weight']]
        df = df.reset_index()
        df['Dependency=Vintage'] = pd.Categorical(df['Dependency=Vintage'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s'])
        df = df.sort_values(by=['Dependency=State', 'Dependency=Vintage']).set_index(['Dependency=State', 'Dependency=Vintage'])        
        return df    
    
    def infiltration(self):
        df = util.create_dataframe(self.session, rdb)
        df = util.assign_vintage(df)
        df = util.assign_size(df)
        df = util.assign_inf(df)
        df, cols = util.categories_to_columns(df, 'inf')
        df = df.groupby(['Dependency=Vintage', 'Dependency=Geometry House Size'])
        missing_groups = []
        for group in itertools.product(*[['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s'], ['0-1499', '1500-2499', '2500-3499', '3500-4499', '4500+']]):
            if not group in list(df.groups):
                missing_groups.append(dict(zip(['Dependency=Vintage', 'Dependency=Geometry House Size'], group)))         
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight']
        df = util.sum_cols(df, cols)
        df['Count'] = count
        df['Weight'] = weight
        columns = list(df.columns)
        columns.remove('Count')
        columns.remove('Weight')       
        for group in missing_groups:
            df_new = pd.DataFrame(data=dict(group.items() + dict(zip(columns, [1.0/len(columns)] * len(columns))).items()), index=[0]).set_index(['Dependency=Vintage', 'Dependency=Geometry House Size'])
            df_new['Count'] = 0
            df_new['Weight'] = 0
            df = df.append(df_new)
        df = add_option_prefix(df)
        df = df[['Option=2 ACH50', 'Option=4 ACH50', 'Option=6 ACH50', 'Option=8 ACH50', 'Option=10 ACH50', 'Option=15 ACH50', 'Option=20 ACH50', 'Option=25 ACH50', 'Count', 'Weight']]
        df = df.reset_index()
        df['Dependency=Vintage'] = pd.Categorical(df['Dependency=Vintage'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s'])
        df = df.sort_values(by=['Dependency=Geometry House Size', 'Dependency=Vintage']).set_index(['Dependency=Geometry House Size', 'Dependency=Vintage'])        
        return df
        
    def hvac_system_combined(self):
        df = util.create_dataframe(self.session, rdb)
        df = util.assign_climate_zones(df)
        df = util.assign_state(df)
        df = util.assign_location(df)
        df = util.assign_vintage(df)
        df = util.assign_heating_fuel(df)
        df = util.assign_hvac_system_combined(df)
        df = util.assign_hvac_system_is_combined(df, 'htg_and_clg')
        df, cols = util.categories_to_columns(df, 'htg_and_clg')
        df = df.groupby(['Dependency=Location Region', 'Dependency=Vintage', 'Dependency=Heating Fuel', 'Dependency=HVAC System Is Combined'])
        missing_groups = []
        for group in itertools.product(*[['H1C1 OR', 'H1C1 WA', 'H1C2', 'H1C3', 'H2', 'H3'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s'], ['Electricity', 'Fuel Oil', 'Natural Gas', 'Propane/LPG', 'Wood'], ['Yes', 'No']]):
            if not group in list(df.groups):
                missing_groups.append(dict(zip(['Dependency=Location Region', 'Dependency=Vintage', 'Dependency=Heating Fuel', 'Dependency=HVAC System Is Combined'], group)))            
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight']
        df = util.sum_cols(df, cols)
        df['Count'] = count
        df['Weight'] = weight
        columns = list(df.columns)
        columns.remove('Count')
        columns.remove('Weight')       
        for group in missing_groups:
            if group['Dependency=Heating Fuel'] == 'Electricity' and group['Dependency=HVAC System Is Combined'] == 'Yes':
                columns.remove('None')
                data = dict(group.items() + dict(zip(columns, [1.0/len(columns)] * len(columns))).items())
                columns.append('None')
                data['None'] = 0
                df_new = pd.DataFrame(data=data, index=[0]).set_index(['Dependency=Location Region', 'Dependency=Vintage', 'Dependency=Heating Fuel', 'Dependency=HVAC System Is Combined'])
            else:
                data = dict(group.items() + dict(zip(columns, [0] * len(columns))).items())
                data['None'] = 1
                df_new = pd.DataFrame(data=data, index=[0]).set_index(['Dependency=Location Region', 'Dependency=Vintage', 'Dependency=Heating Fuel', 'Dependency=HVAC System Is Combined'])
            df_new['Count'] = 0
            df_new['Weight'] = 0
            df = df.append(df_new)
        df = add_option_prefix(df)
        df = df.reset_index()
        df['Dependency=Vintage'] = pd.Categorical(df['Dependency=Vintage'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s'])
        df = df.sort_values(by=['Dependency=Location Region', 'Dependency=Heating Fuel', 'Dependency=HVAC System Is Combined', 'Dependency=Vintage']).set_index(['Dependency=Location Region', 'Dependency=Heating Fuel', 'Dependency=HVAC System Is Combined', 'Dependency=Vintage'])
        return df
        
    def hvac_system_is_combined(self):
        df = util.create_dataframe(self.session, rdb)
        df = util.assign_climate_zones(df)
        df = util.assign_state(df)
        df = util.assign_location(df)
        df = util.assign_vintage(df)
        df = util.assign_heating_fuel(df)
        df = util.assign_hvac_system_combined(df)
        df = util.assign_hvac_system_is_combined(df, 'htg_and_clg')
        df, cols = util.categories_to_columns(df, 'Dependency=HVAC System Is Combined')
        df = df.groupby(['Dependency=Location Region', 'Dependency=Vintage', 'Dependency=Heating Fuel'])
        missing_groups = []
        for group in itertools.product(*[['H1C1 OR', 'H1C1 WA', 'H1C2', 'H1C3', 'H2', 'H3'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s'], ['Electricity', 'Fuel Oil', 'Natural Gas', 'Propane/LPG', 'Wood']]):
            if not group in list(df.groups):
                missing_groups.append(dict(zip(['Dependency=Location Region', 'Dependency=Vintage', 'Dependency=Heating Fuel'], group)))
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight']
        df = util.sum_cols(df, cols)
        df['Count'] = count
        df['Weight'] = weight
        columns = list(df.columns)
        columns.remove('Count')
        columns.remove('Weight')
        for group in missing_groups:
            if group['Dependency=Heating Fuel'] == 'Electricity':
                data = dict(group.items() + dict(zip(columns, [1.0/len(columns)] * len(columns))).items())
                df_new = pd.DataFrame(data=data, index=[0]).set_index(['Dependency=Location Region', 'Dependency=Vintage', 'Dependency=Heating Fuel'])
            else:
                data = dict(group.items() + dict(zip(columns, [0] * len(columns))).items())
                data['No'] = 1
                df_new = pd.DataFrame(data=data, index=[0]).set_index(['Dependency=Location Region', 'Dependency=Vintage', 'Dependency=Heating Fuel'])
            df_new['Count'] = 0
            df_new['Weight'] = 0
            df = df.append(df_new)
        df = add_option_prefix(df)
        df = df.reset_index()
        df['Dependency=Vintage'] = pd.Categorical(df['Dependency=Vintage'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s'])
        df = df.sort_values(by=['Dependency=Location Region', 'Dependency=Heating Fuel', 'Dependency=Vintage']).set_index(['Dependency=Location Region', 'Dependency=Heating Fuel', 'Dependency=Vintage'])        
        return df
        
    def hvac_system_heating(self):
        df = util.create_dataframe(self.session, rdb)
        df = util.assign_climate_zones(df)
        df = util.assign_state(df)
        df = util.assign_location(df)
        df = util.assign_vintage(df)
        df = util.assign_heating_fuel(df)
        df = util.assign_hvac_system_combined(df)
        df = util.assign_hvac_system_heating(df)
        df = util.assign_hvac_system_is_combined(df, 'htg_and_clg')
        df, cols = util.categories_to_columns(df, 'htg')
        df = df.groupby(['Dependency=Location Region', 'Dependency=Vintage', 'Dependency=Heating Fuel', 'Dependency=HVAC System Is Combined'])
        missing_groups = []
        for group in itertools.product(*[['H1C1 OR', 'H1C1 WA', 'H1C2', 'H1C3', 'H2', 'H3'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s'], ['Electricity', 'Fuel Oil', 'Natural Gas', 'Propane/LPG', 'Wood'], ['Yes', 'No']]):
            if not group in list(df.groups):
                missing_groups.append(dict(zip(['Dependency=Location Region', 'Dependency=Vintage', 'Dependency=Heating Fuel', 'Dependency=HVAC System Is Combined'], group)))           
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight']
        df = util.sum_cols(df, cols)
        df['Count'] = count
        df['Weight'] = weight
        columns = list(df.columns)
        columns.remove('Count')
        columns.remove('Weight')       
        for group in missing_groups:
            if group['Dependency=HVAC System Is Combined'] == 'No':
                columns.remove('None')
                data = dict(group.items() + dict(zip(columns, [1.0/len(columns)] * len(columns))).items())
                columns.append('None')
                data['None'] = 0
                df_new = pd.DataFrame(data=data, index=[0]).set_index(['Dependency=Location Region', 'Dependency=Vintage', 'Dependency=Heating Fuel', 'Dependency=HVAC System Is Combined'])
            else:
                data = dict(group.items() + dict(zip(columns, [0] * len(columns))).items())
                data['None'] = 1
                df_new = pd.DataFrame(data=data, index=[0]).set_index(['Dependency=Location Region', 'Dependency=Vintage', 'Dependency=Heating Fuel', 'Dependency=HVAC System Is Combined'])
            df_new['Count'] = 0
            df_new['Weight'] = 0
            df = df.append(df_new)
        df = add_option_prefix(df)
        df = df[['Option=Electric Baseboard', 'Option=Electric Boiler', 'Option=Electric Furnace', 'Option=Gas Boiler, 72% AFUE', 'Option=Gas Boiler, 76% AFUE', 'Option=Gas Boiler, 80% AFUE', 'Option=Gas Boiler, 85% AFUE', 'Option=Gas Boiler, 96% AFUE', 'Option=Gas Furnace, 60% AFUE', 'Option=Gas Furnace, 68% AFUE', 'Option=Gas Furnace, 76% AFUE', 'Option=Gas Furnace, 80% AFUE', 'Option=Gas Furnace, 90% AFUE', 'Option=Gas Furnace, 96% AFUE', 'Option=Oil Boiler, 72% AFUE', 'Option=Propane Boiler, 72% AFUE', 'Option=None', 'Count', 'Weight']]
        df = df.reset_index()
        df['Dependency=Vintage'] = pd.Categorical(df['Dependency=Vintage'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s'])
        df = df.sort_values(by=['Dependency=Location Region', 'Dependency=Heating Fuel', 'Dependency=HVAC System Is Combined', 'Dependency=Vintage']).set_index(['Dependency=Location Region', 'Dependency=Heating Fuel', 'Dependency=HVAC System Is Combined', 'Dependency=Vintage'])
        return df        
        
    def hvac_system_cooling(self):
        df = util.create_dataframe(self.session, rdb)
        df = util.assign_climate_zones(df)
        df = util.assign_state(df)
        df = util.assign_location(df)
        df = util.assign_vintage(df)
        df = util.assign_heating_fuel(df)
        df = util.assign_hvac_system_combined(df)
        df = util.assign_hvac_system_cooling(df)
        df = util.assign_hvac_system_is_combined(df, 'htg_and_clg')
        df, cols = util.categories_to_columns(df, 'clg')
        df = df.groupby(['Dependency=Location Region', 'Dependency=Vintage', 'Dependency=Heating Fuel', 'Dependency=HVAC System Is Combined'])
        missing_groups = []
        for group in itertools.product(*[['H1C1 OR', 'H1C1 WA', 'H1C2', 'H1C3', 'H2', 'H3'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s'], ['Electricity', 'Fuel Oil', 'Natural Gas', 'Propane/LPG', 'Wood'], ['Yes', 'No']]):
            if not group in list(df.groups):
                missing_groups.append(dict(zip(['Dependency=Location Region', 'Dependency=Vintage', 'Dependency=Heating Fuel', 'Dependency=HVAC System Is Combined'], group)))           
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight']   
        df = util.sum_cols(df, cols)
        df['Count'] = count
        df['Weight'] = weight
        columns = list(df.columns)
        columns.remove('Count')
        columns.remove('Weight')       
        for group in missing_groups:
            if group['Dependency=HVAC System Is Combined'] == 'No':
                columns.remove('None')
                data = dict(group.items() + dict(zip(columns, [1.0/len(columns)] * len(columns))).items())
                columns.append('None')
                data['None'] = 0
                df_new = pd.DataFrame(data=data, index=[0]).set_index(['Dependency=Location Region', 'Dependency=Vintage', 'Dependency=Heating Fuel', 'Dependency=HVAC System Is Combined'])
            else:
                data = dict(group.items() + dict(zip(columns, [0] * len(columns))).items())
                data['None'] = 1
                df_new = pd.DataFrame(data=data, index=[0]).set_index(['Dependency=Location Region', 'Dependency=Vintage', 'Dependency=Heating Fuel', 'Dependency=HVAC System Is Combined'])
            df_new['Count'] = 0
            df_new['Weight'] = 0
            df = df.append(df_new)
        df = add_option_prefix(df)
        df = df[['Option=AC, SEER 8', 'Option=AC, SEER 10', 'Option=AC, SEER 13', 'Option=AC, SEER 15', 'Option=FIXME Room AC, EER 9.8, 10% Conditioned', 'Option=FIXME Room AC, EER 9.8, 20% Conditioned', 'Option=FIXME Room AC, EER 9.8, 30% Conditioned', 'Option=FIXME Room AC, EER 9.8, 50% Conditioned', 'Option=None', 'Count', 'Weight']]
        df = df.reset_index()
        df['Dependency=Vintage'] = pd.Categorical(df['Dependency=Vintage'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s'])
        df = df.sort_values(by=['Dependency=Location Region', 'Dependency=Heating Fuel', 'Dependency=HVAC System Is Combined', 'Dependency=Vintage']).set_index(['Dependency=Location Region', 'Dependency=Heating Fuel', 'Dependency=HVAC System Is Combined', 'Dependency=Vintage'])
        return df
    
    def ducts(self):
        df = util.create_dataframe(self.session, rdb)
        df = util.assign_climate_zones(df)
        df = util.assign_state(df)
        df = util.assign_location(df)        
        df = util.assign_vintage(df)
        df = util.assign_foundation_type(df)        
        df = util.assign_ducts(df)
        df, cols = util.categories_to_columns(df, 'ducts')
        df = df.groupby(['Dependency=Geometry Foundation Type', 'Dependency=Vintage'])
        missing_groups = []
        for group in itertools.product(*[['Crawl', 'Heated Basement', 'Slab', 'Unheated Basement'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s']]):
            if not group in list(df.groups):
                missing_groups.append(dict(zip(['Dependency=Geometry Foundation Type', 'Dependency=Vintage'], group)))           
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight']
        df = util.sum_cols(df, cols)
        df['Count'] = count
        df['Weight'] = weight
        columns = list(df.columns)
        columns.remove('Count')
        columns.remove('Weight')  
        for group in missing_groups:
            df_new = pd.DataFrame(data=dict(group.items() + dict(zip(columns, [1.0/len(columns)] * len(columns))).items()), index=[0]).set_index(['Dependency=Geometry Foundation Type', 'Dependency=Vintage'])
            df_new['Count'] = 0
            df_new['Weight'] = 0
            df = df.append(df_new)
        df = add_option_prefix(df)
        df = df[['Option=7.5% Leakage, Uninsulated', 'Option=7.5% Leakage, R-4', 'Option=7.5% Leakage, R-6', 'Option=7.5% Leakage, R-8', 'Option=10% Leakage, Uninsulated', 'Option=10% Leakage, R-4', 'Option=10% Leakage, R-6', 'Option=10% Leakage, R-8', 'Option=15% Leakage, Uninsulated', 'Option=15% Leakage, R-4', 'Option=15% Leakage, R-6', 'Option=15% Leakage, R-8', 'Option=20% Leakage, Uninsulated', 'Option=20% Leakage, R-4', 'Option=20% Leakage, R-6', 'Option=20% Leakage, R-8', 'Option=30% Leakage, Uninsulated', 'Option=30% Leakage, R-4', 'Option=30% Leakage, R-6', 'Option=30% Leakage, R-8', 'Option=In Finished Space', 'Count', 'Weight']]
        df = df.reset_index()
        df['Dependency=Vintage'] = pd.Categorical(df['Dependency=Vintage'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s'])
        df = df.sort_values(by=['Dependency=Geometry Foundation Type', 'Dependency=Vintage']).set_index(['Dependency=Geometry Foundation Type', 'Dependency=Vintage'])
        return df
    
    def water_heater(self):
        df = util.create_dataframe(self.session, rdb)
        df = util.assign_heating_fuel(df)
        df = util.assign_wh(df)
        df, cols = util.categories_to_columns(df, 'wh')
        df = df.groupby(['Dependency=Heating Fuel'])
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight']
        df = util.sum_cols(df, cols)
        df['Count'] = count
        df['Weight'] = weight
        df = add_option_prefix(df)
        df = df[['Option=Electric Standard', 'Option=Gas Standard', 'Option=Gas Tankless', 'Option=Oil Standard', 'Option=Propane Standard', 'Option=Propane Tankless', 'Count', 'Weight']]
        return df
    
    def lighting(self):
        df = util.create_dataframe(self.session, rdb)
        df = util.assign_ltg(df)
        df, cols = util.categories_to_columns(df, 'ltg')
        df['group'] = 'all'
        df = df.groupby(['group'])
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight']
        df = util.sum_cols(df, cols)
        df['Count'] = count
        df['Weight'] = weight
        df = add_option_prefix(df)
        df = df.reset_index().set_index('Option=100% CFL')
        del df['group']        
        return df
    
    def cooking_range(self):
        df = util.create_dataframe(self.session, rdb)        
        df = util.assign_heating_fuel(df)
        df = util.assign_rng(df)
        df, cols = util.categories_to_columns(df, 'rng')
        df = df.groupby(['Dependency=Heating Fuel'])
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight']
        df = util.sum_cols(df, cols)
        df['Count'] = count
        df['Weight'] = weight
        df = add_option_prefix(df)
        df = df[['Option=Electric, 100% Usage', 'Option=Gas, 100% Usage', 'Option=FIXME Propane, 100% Usage', 'Option=None', 'Count', 'Weight']]
        return df               
        
    def clothes_dryer(self):
        df = util.create_dataframe(self.session, rdb)   
        df = util.assign_heating_fuel(df)
        df = util.assign_cd(df)
        df, cols = util.categories_to_columns(df, 'cd')
        df = df.groupby(['Dependency=Heating Fuel'])
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight']
        df = util.sum_cols(df, cols)
        df['Count'] = count
        df['Weight'] = weight
        df = add_option_prefix(df)
        df = df[['Option=Electric, 100% Usage', 'Option=Gas, 100% Usage', 'Option=FIXME Propane, 100% Usage', 'Option=None', 'Count', 'Weight']]
        return df

def to_figure(df, file):
    
    sns.set(font_scale=1)
    f, ax = plt.subplots(figsize=(10, 10))
    ax = sns.heatmap(df, annot=True, annot_kws={'size': 10}, fmt='.2f')
    plt.savefig(file)
    plt.close()

def add_option_prefix(df):
    for col in df.columns:
        if not 'Dependency=' in col and not 'Count' in col and not 'Weight' in col and not 'group' in col:
            if col in ['Propane, 100% Usage', 'MSHP, SEER 18.0, 9.6 HSPF, 60% Conditioned', 'Room AC, EER 9.8, 10% Conditioned', 'Room AC, EER 9.8, 20% Conditioned', 'Room AC, EER 9.8, 30% Conditioned', 'Room AC, EER 9.8, 50% Conditioned']:
                df.rename(columns={col: 'Option=FIXME {}'.format(col)}, inplace=True)
            else:
                df.rename(columns={col: 'Option={}'.format(col)}, inplace=True)
    return df

if __name__ == '__main__':
    
    datafiles_dir = '../../resources/inputs/pnw'
    heatmaps_dir = 'heatmaps'
    
    dfs = Create_DFs('rbsa.sqlite')
    
    for category in ['Location Region', 'Vintage', 'Heating Fuel', 'Geometry Foundation Type', 'Geometry House Size', 'Geometry Stories', 'Insulation Unfinished Attic', 'Insulation Wall', 'Heating Setpoint', 'Cooling Setpoint', 'Insulation Slab', 'Insulation Crawlspace', 'Insulation Unfinished Basement', 'Insulation Finished Basement', 'Insulation Interzonal Floor', 'Windows', 'Infiltration', 'HVAC System Combined', 'HVAC System Heating', 'HVAC System Cooling', 'HVAC System Is Combined', 'Ducts', 'Water Heater', 'Lighting', 'Cooking Range', 'Clothes Dryer', 'Insulation Wall H1', 'Insulation Wall H2', 'Insulation Wall H3', 'Insulation Unfinished Attic H1', 'Insulation Unfinished Attic H2', 'Insulation Unfinished Attic H3', 'Windows H1', 'Windows H2', 'Windows H3']:
        print category
        method = getattr(dfs, category.lower().replace(' ', '_'))
        df = method()
        df.to_csv(os.path.join(datafiles_dir, '{}.tsv'.format(category)), sep='\t')
        del df['Count']
        del df['Weight']
        to_figure(df, os.path.join(heatmaps_dir, '{}.png'.format(category)))
  
    