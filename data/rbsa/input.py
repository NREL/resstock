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
        
    def location_heating_region(self):
        df = util.create_dataframe(self.session, rdb)
        df = util.assign_climate_zones(df)
        df = util.assign_state(df)
        df = util.assign_heating_location(df)
        df = util.assign_totalsfd(df)
        df, cols = util.categories_to_columns(df, 'Dependency=Location Heating Region')
        df['group'] = 'all'
        df = df.groupby(['group'])
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight']
        df = util.sum_cols(df, cols)
        df['Count'] = count
        df['Weight'] = weight
        df = add_option_prefix(df)
        df = df.reset_index().set_index('Option=H1')
        del df['group']
        return df
        
    def location_cooling_region(self):
        df = util.create_dataframe(self.session, rdb)
        df = util.assign_climate_zones(df)
        df = util.assign_state(df)
        df = util.assign_heating_location(df)
        df = util.assign_cooling_location(df)
        df = util.assign_totalsfd(df)
        df, cols = util.categories_to_columns(df, 'Dependency=Location Cooling Region')
        df = df.groupby(['Dependency=Location Heating Region'])
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight']
        df = util.sum_cols(df, cols)
        df['Count'] = count
        df['Weight'] = weight
        df = add_option_prefix(df)
        return df        
    
    def vintage(self):
        df = util.create_dataframe(self.session, rdb)
        df = util.assign_climate_zones(df)
        df = util.assign_state(df)
        df = util.assign_heating_location(df)        
        df = util.assign_vintage(df)
        df, cols = util.categories_to_columns(df, 'Dependency=Vintage')
        df = df.groupby(['Dependency=Location Heating Region'])
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight']
        df = util.sum_cols(df, cols)
        df['Count'] = count
        df['Weight'] = weight
        df = add_option_prefix(df)
        df = df[['Option=<1950', 'Option=1950s', 'Option=1960s', 'Option=1970s', 'Option=1980s', 'Option=1990s', 'Option=2000s', 'Count', 'Weight']]
        return df
    
    def heating_fuel(self, smooth=False):
        df = util.create_dataframe(self.session, rdb)
        df = util.assign_climate_zones(df)
        df = util.assign_state(df)
        df = util.assign_heating_location(df)
        df = util.assign_vintage(df)
        df = util.assign_heating_fuel(df)
        df, cols = util.categories_to_columns(df, 'Dependency=Heating Fuel')      
        df = df.groupby(['Dependency=Location Heating Region', 'Dependency=Vintage'])
        missing_groups = []
        for group in itertools.product(*[['H1', 'H2', 'H3'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s']]):
            if not group in list(df.groups):
                missing_groups.append(dict(zip(['Dependency=Location Heating Region', 'Dependency=Vintage'], group)))
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight']
        df = util.sum_cols(df, cols)
        df['Count'] = count
        df['Weight'] = weight
        columns = list(df.columns)
        columns.remove('Count')
        columns.remove('Weight')     
        for group in missing_groups:
            df_new = pd.DataFrame(data=dict(group.items() + dict(zip(columns, [1.0/len(columns)] * len(columns))).items()), index=[0]).set_index(['Dependency=Location Heating Region', 'Dependency=Vintage'])
            df_new['Count'] = 0
            df_new['Weight'] = 0
            df = df.append(df_new)
        df = add_option_prefix(df)
        df = df[['Option=Electricity', 'Option=Natural Gas', 'Option=Fuel Oil', 'Option=Propane', 'Option=Wood', 'Count', 'Weight']]
        df = df.reset_index()
        df['Dependency=Vintage'] = pd.Categorical(df['Dependency=Vintage'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s'])        
        df = df.sort_values(by=['Dependency=Location Heating Region', 'Dependency=Vintage']).set_index(['Dependency=Location Heating Region', 'Dependency=Vintage'])
        if smooth:
            df = apply_smoothing(df, 'Dependency=Location Heating Region', 'Dependency=Vintage')
        return df
        
    def insulation_unfinished_attic(self, smooth=False):
        df = util.create_dataframe(self.session, rdb)
        df = util.assign_climate_zones(df)
        df = util.assign_state(df)
        df = util.assign_heating_location(df)
        df = util.assign_vintage(df)
        df = util.assign_ceiling(df)
        df, cols = util.categories_to_columns(df, 'rval')
        df = df.groupby(['Dependency=Location Heating Region', 'Dependency=Vintage'])
        missing_groups = []
        for group in itertools.product(*[['H1', 'H2', 'H3'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s']]):
            if not group in list(df.groups):
                missing_groups.append(dict(zip(['Dependency=Location Heating Region', 'Dependency=Vintage'], group)))        
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight']
        df = util.sum_cols(df, cols)
        df['Count'] = count
        df['Weight'] = weight
        columns = list(df.columns)
        columns.remove('Count')
        columns.remove('Weight')   
        for group in missing_groups:
            df_new = pd.DataFrame(data=dict(group.items() + dict(zip(columns, [1.0/len(columns)] * len(columns))).items()), index=[0]).set_index(['Dependency=Location Heating Region', 'Dependency=Vintage'])
            df_new['Count'] = 0
            df_new['Weight'] = 0
            df = df.append(df_new)
        df = add_option_prefix(df)
        df = df[['Option=Uninsulated, Vented', 'Option=Ceiling R-7, Vented', 'Option=Ceiling R-13, Vented', 'Option=Ceiling R-19, Vented', 'Option=Ceiling R-30, Vented', 'Option=Ceiling R-38, Vented', 'Option=Ceiling R-49, Vented', 'Option=Ceiling R-60, Vented', 'Count', 'Weight']]
        df = df.reset_index()
        df['Dependency=Vintage'] = pd.Categorical(df['Dependency=Vintage'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s'])
        df = df.sort_values(by=['Dependency=Location Heating Region', 'Dependency=Vintage']).set_index(['Dependency=Location Heating Region', 'Dependency=Vintage'])
        if smooth:
            df = apply_smoothing(df, 'Dependency=Location Heating Region', 'Dependency=Vintage')        
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
    
    def insulation_wall(self, smooth=False):
        df = util.create_dataframe(self.session, rdb)
        df = util.assign_climate_zones(df)
        df = util.assign_state(df)
        df = util.assign_heating_location(df)
        df = util.assign_vintage(df)
        df = util.assign_wall(df)
        df, cols = util.categories_to_columns(df, 'rval')   
        df = df.groupby(['Dependency=Location Heating Region', 'Dependency=Vintage'])
        missing_groups = []
        for group in itertools.product(*[['H1', 'H2', 'H3'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s']]):
            if not group in list(df.groups):
                missing_groups.append(dict(zip(['Dependency=Location Heating Region', 'Dependency=Vintage'], group)))        
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight']
        df = util.sum_cols(df, cols)
        df['Count'] = count
        df['Weight'] = weight
        columns = list(df.columns)
        columns.remove('Count')
        columns.remove('Weight')    
        for group in missing_groups:
            df_new = pd.DataFrame(data=dict(group.items() + dict(zip(columns, [1.0/len(columns)] * len(columns))).items()), index=[0]).set_index(['Dependency=Location Heating Region', 'Dependency=Vintage'])
            df_new['Count'] = 0
            df_new['Weight'] = 0
            df = df.append(df_new)
        df = add_option_prefix(df)
        df = df[['Option=Wood Stud, Uninsulated', 'Option=Wood Stud, R-7', 'Option=Wood Stud, R-13', 'Option=Wood Stud, R-19', 'Option=Wood Stud, R-36', 'Count', 'Weight']]
        df = df.reset_index()
        df['Dependency=Vintage'] = pd.Categorical(df['Dependency=Vintage'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s'])
        df = df.sort_values(by=['Dependency=Location Heating Region', 'Dependency=Vintage']).set_index(['Dependency=Location Heating Region', 'Dependency=Vintage'])        
        if smooth:
            df = apply_smoothing(df, 'Dependency=Location Heating Region', 'Dependency=Vintage')
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
        df = util.assign_heating_location(df)
        df = util.assign_vintage(df)
        df = util.assign_foundation_type(df)
        df, cols = util.categories_to_columns(df, 'Dependency=Geometry Foundation Type')
        df = df.groupby(['Dependency=Location Heating Region', 'Dependency=Vintage'])
        missing_groups = []
        for group in itertools.product(*[['H1', 'H2', 'H3'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s']]):
            if not group in list(df.groups):
                missing_groups.append(dict(zip(['Dependency=Location Heating Region', 'Dependency=Vintage'], group)))          
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight']
        df = util.sum_cols(df, cols)
        df['Count'] = count
        df['Weight'] = weight
        columns = list(df.columns)
        columns.remove('Count')
        columns.remove('Weight')    
        for group in missing_groups:
            df_new = pd.DataFrame(data=dict(group.items() + dict(zip(columns, [1.0/len(columns)] * len(columns))).items()), index=[0]).set_index(['Dependency=Location Heating Region', 'Dependency=Vintage'])
            df_new['Count'] = 0
            df_new['Weight'] = 0
            df = df.append(df_new)
        df = add_option_prefix(df)
        df = df.reset_index()
        df['Dependency=Vintage'] = pd.Categorical(df['Dependency=Vintage'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s'])
        df = df.sort_values(by=['Dependency=Location Heating Region', 'Dependency=Vintage']).set_index(['Dependency=Location Heating Region', 'Dependency=Vintage'])
        return df
    
    def geometry_house_size(self, smooth=False):
        df = util.create_dataframe(self.session, rdb)
        df = util.assign_climate_zones(df)
        df = util.assign_state(df)
        df = util.assign_heating_location(df)        
        df = util.assign_vintage(df)
        df = util.assign_size(df)
        df, cols = util.categories_to_columns(df, 'Dependency=Geometry House Size')
        # df.groupby(['Dependency=Geometry House Size']).apply(lambda x: np.average(x['House Size'], weights=x['Weight'])).to_frame(name='Average House Size').to_csv(os.path.join(datafiles_dir, '{}.tsv'.format(category + ' House Size')), sep='\t')
        # df.groupby(['Dependency=Vintage']).apply(lambda x: np.average(x['House Size'], weights=x['Weight'])).to_frame(name='Average House Size').to_csv(os.path.join(datafiles_dir, '{}.tsv'.format(category + ' Vintage')), sep='\t')
        df = df.groupby(['Dependency=Location Heating Region', 'Dependency=Vintage'])
        missing_groups = []
        for group in itertools.product(*[['H1', 'H2', 'H3'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s']]):
            if not group in list(df.groups):
                missing_groups.append(dict(zip(['Dependency=Location Heating Region', 'Dependency=Vintage'], group)))        
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight']
        df = util.sum_cols(df, cols)
        df['Count'] = count
        df['Weight'] = weight
        columns = list(df.columns)
        columns.remove('Count')
        columns.remove('Weight')       
        for group in missing_groups:
            df_new = pd.DataFrame(data=dict(group.items() + dict(zip(columns, [1.0/len(columns)] * len(columns))).items()), index=[0]).set_index(['Dependency=Location Heating Region', 'Dependency=Vintage'])
            df_new['Count'] = 0
            df_new['Weight'] = 0
            df = df.append(df_new)
        df = add_option_prefix(df)
        df = df.reset_index()
        df['Dependency=Vintage'] = pd.Categorical(df['Dependency=Vintage'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s'])
        df = df.sort_values(by=['Dependency=Location Heating Region', 'Dependency=Vintage']).set_index(['Dependency=Location Heating Region', 'Dependency=Vintage'])
        if smooth:
            df = apply_smoothing(df, 'Dependency=Location Heating Region', 'Dependency=Vintage')        
        return df
    
    def geometry_stories(self, smooth=False):
        df = util.create_dataframe(self.session, rdb)
        df = util.assign_climate_zones(df)
        df = util.assign_state(df)
        df = util.assign_heating_location(df)
        df = util.assign_vintage(df) 
        df = util.assign_size(df)
        df = util.assign_stories(df)
        df, cols = util.categories_to_columns(df, 'Dependency=Geometry Stories')
        df = df.groupby(['Dependency=Vintage', 'Dependency=Geometry House Size'])
        missing_groups = []
        for group in itertools.product(*[['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s'], ['0-1499', '1500-2499', '2500-3499', '3500+']]):
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
        df = df.reset_index()
        df['Dependency=Vintage'] = pd.Categorical(df['Dependency=Vintage'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s'])
        df = df.sort_values(by=['Dependency=Geometry House Size', 'Dependency=Vintage']).set_index(['Dependency=Geometry House Size', 'Dependency=Vintage'])
        if smooth:
            df = apply_smoothing(df, 'Dependency=Geometry House Size', 'Dependency=Vintage')
        return df
    
    def heating_setpoint(self):
        df = util.create_dataframe(self.session, rdb)
        df = util.assign_htgsp(df)
        # df = util.assign_htgsbk(df)
        # df['Weight'] = df.apply(lambda x: x.object.sfmasterpopulations.svywt, axis=1)
        # df = df.groupby(['Dependency=Heating Setpoint']).apply(lambda x: np.average(x.htgsbk, weights=x.Weight)).to_frame('htgsbk')
        df, cols = util.categories_to_columns(df, 'Dependency=Heating Setpoint')
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
    
    def heating_setpoint_2(self):
        df = util.create_dataframe(self.session, rdb)
        df = util.assign_primary_heating_system_type(df)
        df = util.assign_htgsp(df)
        df, cols = util.categories_to_columns(df, 'Dependency=Heating Setpoint')
        df = df.groupby(['Dependency=Primary Heating System Type'])
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight']
        df = util.sum_cols(df, cols)        
        df['Count'] = count
        df['Weight'] = weight
        columns = list(df.columns)
        columns.remove('Count')
        columns.remove('Weight')
        df = add_option_prefix(df)
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
    
    def insulation_slab(self, smooth=False):
        df = util.create_dataframe(self.session, rdb)
        df = util.assign_climate_zones(df)
        df = util.assign_state(df)
        df = util.assign_heating_location(df)
        df = util.assign_vintage(df)
        df = util.assign_foundation_type(df)
        df = util.assign_slab(df)
        df, cols = util.categories_to_columns(df, 'rval')
        df = df.groupby(['Dependency=Location Heating Region', 'Dependency=Vintage', 'Dependency=Geometry Foundation Type'])
        missing_groups = []
        for group in itertools.product(*[['H1', 'H2', 'H3'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s'], ['Crawl', 'Heated Basement', 'Slab', 'Unheated Basement']]):
            if not group in list(df.groups):
                missing_groups.append(dict(zip(['Dependency=Location Heating Region', 'Dependency=Vintage', 'Dependency=Geometry Foundation Type'], group)))        
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
                df_new = pd.DataFrame(data=data, index=[0]).set_index(['Dependency=Location Heating Region', 'Dependency=Vintage', 'Dependency=Geometry Foundation Type'])
            else:
                data = dict(group.items() + dict(zip(columns, [0] * len(columns))).items())
                data['None'] = 1
                df_new = pd.DataFrame(data=data, index=[0]).set_index(['Dependency=Location Heating Region', 'Dependency=Vintage', 'Dependency=Geometry Foundation Type'])
            df_new['Count'] = 0
            df_new['Weight'] = 0
            df = df.append(df_new)
        df = add_option_prefix(df)
        df = df[['Option=Uninsulated', 'Option=4ft R5 Perimeter, R5 Gap', 'Option=R10 Whole Slab, R5 Gap', 'Option=None', 'Count', 'Weight']]
        df = df.reset_index()
        df['Dependency=Vintage'] = pd.Categorical(df['Dependency=Vintage'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s'])
        df = df.sort_values(by=['Dependency=Location Heating Region', 'Dependency=Geometry Foundation Type', 'Dependency=Vintage']).set_index(['Dependency=Location Heating Region', 'Dependency=Vintage', 'Dependency=Geometry Foundation Type'])
        if smooth:
            df_sub = df.reset_index()
            df_sub = df_sub[df_sub['Dependency=Geometry Foundation Type']=='Slab'].set_index(['Dependency=Location Heating Region', 'Dependency=Vintage', 'Dependency=Geometry Foundation Type'])                
            df_sub = apply_smoothing(df_sub, 'Dependency=Location Heating Region', 'Dependency=Vintage', ['Dependency=Geometry Foundation Type'])
            df.update(df_sub)
        return df               

    def insulation_crawlspace(self, smooth=False):
        df = util.create_dataframe(self.session, rdb)
        df = util.assign_climate_zones(df)
        df = util.assign_state(df)
        df = util.assign_heating_location(df)
        df = util.assign_vintage(df)
        df = util.assign_foundation_type(df)
        df = util.assign_crawl(df)
        df, cols = util.categories_to_columns(df, 'rval')      
        df = df.groupby(['Dependency=Location Heating Region', 'Dependency=Vintage', 'Dependency=Geometry Foundation Type'])
        missing_groups = []
        for group in itertools.product(*[['H1', 'H2', 'H3'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s'], ['Crawl', 'Heated Basement', 'Slab', 'Unheated Basement']]):
            if not group in list(df.groups):
                missing_groups.append(dict(zip(['Dependency=Location Heating Region', 'Dependency=Vintage', 'Dependency=Geometry Foundation Type'], group)))         
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
                df_new = pd.DataFrame(data=data, index=[0]).set_index(['Dependency=Location Heating Region', 'Dependency=Vintage', 'Dependency=Geometry Foundation Type'])
            else:
                data = dict(group.items() + dict(zip(columns, [0] * len(columns))).items())
                data['None'] = 1
                df_new = pd.DataFrame(data=data, index=[0]).set_index(['Dependency=Location Heating Region', 'Dependency=Vintage', 'Dependency=Geometry Foundation Type'])
            df_new['Count'] = 0
            df_new['Weight'] = 0
            df = df.append(df_new)
        df = add_option_prefix(df)
        df = df[['Option=Uninsulated, Unvented', 'Option=Uninsulated, Vented', 'Option=Wall R-13, Unvented', 'Option=Ceiling R-13, Vented', 'Option=Ceiling R-19, Vented', 'Option=Ceiling R-30, Vented', 'Option=None', 'Count', 'Weight']]
        df = df.reset_index()
        df['Dependency=Vintage'] = pd.Categorical(df['Dependency=Vintage'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s'])
        df = df.sort_values(by=['Dependency=Location Heating Region', 'Dependency=Geometry Foundation Type', 'Dependency=Vintage']).set_index(['Dependency=Location Heating Region', 'Dependency=Vintage', 'Dependency=Geometry Foundation Type'])
        if smooth:
            df_sub = df.reset_index()
            df_sub = df_sub[df_sub['Dependency=Geometry Foundation Type']=='Crawl'].set_index(['Dependency=Location Heating Region', 'Dependency=Vintage', 'Dependency=Geometry Foundation Type'])                
            df_sub = apply_smoothing(df_sub, 'Dependency=Location Heating Region', 'Dependency=Vintage', ['Dependency=Geometry Foundation Type'])
            df.update(df_sub)
        return df
    
    def insulation_unfinished_basement(self, smooth=False):
        df = util.create_dataframe(self.session, rdb)
        df = util.assign_climate_zones(df)
        df = util.assign_state(df)
        df = util.assign_heating_location(df)
        df = util.assign_vintage(df)
        df = util.assign_foundation_type(df)
        df = util.assign_ufbsmt(df)
        df, cols = util.categories_to_columns(df, 'rval')
        df = df.groupby(['Dependency=Location Heating Region', 'Dependency=Vintage', 'Dependency=Geometry Foundation Type'])
        missing_groups = []
        for group in itertools.product(*[['H1', 'H2', 'H3'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s'], ['Crawl', 'Heated Basement', 'Slab', 'Unheated Basement']]):
            if not group in list(df.groups):
                missing_groups.append(dict(zip(['Dependency=Location Heating Region', 'Dependency=Vintage', 'Dependency=Geometry Foundation Type'], group)))
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
                df_new = pd.DataFrame(data=data, index=[0]).set_index(['Dependency=Location Heating Region', 'Dependency=Vintage', 'Dependency=Geometry Foundation Type'])
            else:
                data = dict(group.items() + dict(zip(columns, [0] * len(columns))).items())
                data['None'] = 1
                df_new = pd.DataFrame(data=data, index=[0]).set_index(['Dependency=Location Heating Region', 'Dependency=Vintage', 'Dependency=Geometry Foundation Type'])
            df_new['Count'] = 0
            df_new['Weight'] = 0
            df = df.append(df_new)
        df = add_option_prefix(df)
        df = df[['Option=Uninsulated', 'Option=Ceiling R-13', 'Option=Ceiling R-19', 'Option=None', 'Count', 'Weight']]
        df = df.reset_index()
        df['Dependency=Vintage'] = pd.Categorical(df['Dependency=Vintage'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s'])
        df = df.sort_values(by=['Dependency=Location Heating Region', 'Dependency=Geometry Foundation Type', 'Dependency=Vintage']).set_index(['Dependency=Location Heating Region', 'Dependency=Vintage', 'Dependency=Geometry Foundation Type'])        
        if smooth:
            df_sub = df.reset_index()
            df_sub = df_sub[df_sub['Dependency=Geometry Foundation Type']=='Unheated Basement'].set_index(['Dependency=Location Heating Region', 'Dependency=Vintage', 'Dependency=Geometry Foundation Type'])                
            df_sub = apply_smoothing(df_sub, 'Dependency=Location Heating Region', 'Dependency=Vintage', ['Dependency=Geometry Foundation Type'])
            df.update(df_sub)
        return df
    
    def insulation_finished_basement(self, smooth=False):
        df = util.create_dataframe(self.session, rdb)
        df = util.assign_climate_zones(df)
        df = util.assign_state(df)
        df = util.assign_heating_location(df)
        df = util.assign_vintage(df)
        df = util.assign_foundation_type(df)
        df = util.assign_fbsmt(df)
        df, cols = util.categories_to_columns(df, 'rval')            
        df = df.groupby(['Dependency=Location Heating Region', 'Dependency=Vintage', 'Dependency=Geometry Foundation Type'])
        missing_groups = []
        for group in itertools.product(*[['H1', 'H2', 'H3'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s'], ['Crawl', 'Heated Basement', 'Slab', 'Unheated Basement']]):
            if not group in list(df.groups):
                missing_groups.append(dict(zip(['Dependency=Location Heating Region', 'Dependency=Vintage', 'Dependency=Geometry Foundation Type'], group)))
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
                df_new = pd.DataFrame(data=data, index=[0]).set_index(['Dependency=Location Heating Region', 'Dependency=Vintage', 'Dependency=Geometry Foundation Type'])
            else:
                data = dict(group.items() + dict(zip(columns, [0] * len(columns))).items())
                data['None'] = 1
                df_new = pd.DataFrame(data=data, index=[0]).set_index(['Dependency=Location Heating Region', 'Dependency=Vintage', 'Dependency=Geometry Foundation Type'])
            df_new['Count'] = 0
            df_new['Weight'] = 0
            df = df.append(df_new)
        df = add_option_prefix(df)
        df = df[['Option=Uninsulated', 'Option=Wall R-5', 'Option=Wall R-10', 'Option=Wall R-15', 'Option=None', 'Count', 'Weight']]
        df = df.reset_index()
        df['Dependency=Vintage'] = pd.Categorical(df['Dependency=Vintage'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s'])
        df = df.sort_values(by=['Dependency=Location Heating Region', 'Dependency=Geometry Foundation Type', 'Dependency=Vintage']).set_index(['Dependency=Location Heating Region', 'Dependency=Vintage', 'Dependency=Geometry Foundation Type'])
        if smooth:
            df_sub = df.reset_index()
            df_sub = df_sub[df_sub['Dependency=Geometry Foundation Type']=='Heated Basement'].set_index(['Dependency=Location Heating Region', 'Dependency=Vintage', 'Dependency=Geometry Foundation Type'])                
            df_sub = apply_smoothing(df_sub, 'Dependency=Location Heating Region', 'Dependency=Vintage', ['Dependency=Geometry Foundation Type'])
            df.update(df_sub)        
        return df
    
    def insulation_interzonal_floor(self, smooth=False):
        df = util.create_dataframe(self.session, rdb)
        df = util.assign_climate_zones(df)
        df = util.assign_state(df)
        df = util.assign_heating_location(df)
        df = util.assign_vintage(df)
        df = util.assign_intfloor(df)
        df, cols = util.categories_to_columns(df, 'rval')
        df = df.groupby(['Dependency=Location Heating Region', 'Dependency=Vintage'])
        missing_groups = []
        for group in itertools.product(*[['H1', 'H2', 'H3'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s']]):
            if not group in list(df.groups):
                missing_groups.append(dict(zip(['Dependency=Location Heating Region', 'Dependency=Vintage'], group)))        
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight']  
        df = util.sum_cols(df, cols)
        df['Count'] = count
        df['Weight'] = weight
        columns = list(df.columns)
        columns.remove('Count')
        columns.remove('Weight')     
        for group in missing_groups:
            df_new = pd.DataFrame(data=dict(group.items() + dict(zip(columns, [1.0/len(columns)] * len(columns))).items()), index=[0]).set_index(['Dependency=Location Heating Region', 'Dependency=Vintage'])
            df_new['Count'] = 0
            df_new['Weight'] = 0
            df = df.append(df_new)
        df = add_option_prefix(df)
        df = df[['Option=Uninsulated', 'Option=R-13', 'Option=R-19', 'Count', 'Weight']]
        df = df.reset_index()
        df['Dependency=Vintage'] = pd.Categorical(df['Dependency=Vintage'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s'])
        df = df.sort_values(by=['Dependency=Location Heating Region', 'Dependency=Vintage']).set_index(['Dependency=Location Heating Region', 'Dependency=Vintage'])        
        if smooth:
            df = apply_smoothing(df, 'Dependency=Location Heating Region', 'Dependency=Vintage')      
        return df
    
    def windows(self):
        df = util.create_dataframe(self.session, rdb)
        df = util.assign_climate_zones(df)
        df = util.assign_state(df)
        df = util.assign_heating_location(df)
        df = util.assign_vintage(df)
        df = util.assign_win(df)
        df, cols = util.categories_to_columns(df, 'rval')
        df = df.groupby(['Dependency=Location Heating Region', 'Dependency=Vintage'])
        missing_groups = []
        for group in itertools.product(*[['H1', 'H2', 'H3'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s']]):
            if not group in list(df.groups):
                missing_groups.append(dict(zip(['Dependency=Location Heating Region', 'Dependency=Vintage'], group)))         
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight'] 
        df = util.sum_cols(df, cols)
        df['Count'] = count
        df['Weight'] = weight
        columns = list(df.columns)
        columns.remove('Count')
        columns.remove('Weight')        
        for group in missing_groups:
            df_new = pd.DataFrame(data=dict(group.items() + dict(zip(columns, [1.0/len(columns)] * len(columns))).items()), index=[0]).set_index(['Dependency=Location Heating Region', 'Dependency=Vintage'])
            df_new['Count'] = 0
            df_new['Weight'] = 0
            df = df.append(df_new)
        df = add_option_prefix(df)
        df = df[['Option=Clear, Single, Metal', 'Option=Clear, Single, Non-metal', 'Option=Clear, Double, Metal, Air', 'Option=Clear, Double, Non-metal, Air', 'Option=Low-E, Double, Non-metal, Air, M-Gain', 'Count', 'Weight']]
        df = df.reset_index()
        df['Dependency=Vintage'] = pd.Categorical(df['Dependency=Vintage'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s'])
        df = df.sort_values(by=['Dependency=Location Heating Region', 'Dependency=Vintage']).set_index(['Dependency=Location Heating Region', 'Dependency=Vintage'])        
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
    
    def infiltration(self, smooth=False):
        df = util.create_dataframe(self.session, rdb)
        df = util.assign_vintage(df)
        df = util.assign_size(df)
        df = util.assign_inf(df)
        df, cols = util.categories_to_columns(df, 'inf')
        df = df.groupby(['Dependency=Vintage', 'Dependency=Geometry House Size'])
        missing_groups = []
        for group in itertools.product(*[['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s'], ['0-1499', '1500-2499', '2500-3499', '3500+']]):
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
        if smooth:
            df = apply_smoothing(df, 'Dependency=Geometry House Size', 'Dependency=Vintage')
        return df
        
    def hvac_system_combined(self, smooth=False):
        df = util.create_dataframe(self.session, rdb)
        df = util.assign_climate_zones(df)
        df = util.assign_state(df)
        df = util.assign_heating_location(df)
        df = util.assign_cooling_location(df)
        df = util.assign_vintage(df)
        df = util.assign_heating_fuel(df)
        df = util.assign_hvac_system_combined(df)
        df = util.assign_hvac_system_is_combined(df, 'htg_and_clg')
        df, cols = util.categories_to_columns(df, 'htg_and_clg')
        df = df.groupby(['Dependency=Location Heating Region', 'Dependency=Vintage', 'Dependency=Heating Fuel', 'Dependency=HVAC System Is Combined'])
        missing_groups = []
        for group in itertools.product(*[['H1', 'H2', 'H3'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s'], ['Electricity', 'Fuel Oil', 'Natural Gas', 'Propane', 'Wood'], ['Yes', 'No']]):
            if not group in list(df.groups):
                missing_groups.append(dict(zip(['Dependency=Location Heating Region', 'Dependency=Vintage', 'Dependency=Heating Fuel', 'Dependency=HVAC System Is Combined'], group)))            
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
                df_new = pd.DataFrame(data=data, index=[0]).set_index(['Dependency=Location Heating Region', 'Dependency=Vintage', 'Dependency=Heating Fuel', 'Dependency=HVAC System Is Combined'])
            else:
                data = dict(group.items() + dict(zip(columns, [0] * len(columns))).items())
                data['None'] = 1
                df_new = pd.DataFrame(data=data, index=[0]).set_index(['Dependency=Location Heating Region', 'Dependency=Vintage', 'Dependency=Heating Fuel', 'Dependency=HVAC System Is Combined'])
            df_new['Count'] = 0
            df_new['Weight'] = 0
            df = df.append(df_new)
        for index, row in df.iterrows():
          ashp_frac = row['ASHP, SEER 10.3, 7.0 HSPF'] + row['ASHP, SEER 11.5, 7.5 HSPF'] + row['ASHP, SEER 13, 8.0 HSPF'] + row['ASHP, SEER 14.3, 8.5 HSPF'] + row['ASHP, SEER 16, 9.0 HSPF']
          if ashp_frac > 0:
            df.loc[index, 'ASHP, SEER 10.3, 7.0 HSPF'] += row['ASHP'] * (row['ASHP, SEER 10.3, 7.0 HSPF'] / ashp_frac)
            df.loc[index, 'ASHP, SEER 11.5, 7.5 HSPF'] += row['ASHP'] * (row['ASHP, SEER 11.5, 7.5 HSPF'] / ashp_frac)
            df.loc[index, 'ASHP, SEER 13, 8.0 HSPF'] += row['ASHP'] * (row['ASHP, SEER 13, 8.0 HSPF'] / ashp_frac)
            df.loc[index, 'ASHP, SEER 14.3, 8.5 HSPF'] += row['ASHP'] * (row['ASHP, SEER 14.3, 8.5 HSPF'] / ashp_frac)
            df.loc[index, 'ASHP, SEER 16, 9.0 HSPF'] += row['ASHP'] * (row['ASHP, SEER 16, 9.0 HSPF'] / ashp_frac)
          else:
            df.loc[index, 'ASHP, SEER 10.3, 7.0 HSPF'] += row['ASHP'] / 5.0
            df.loc[index, 'ASHP, SEER 11.5, 7.5 HSPF'] += row['ASHP'] / 5.0
            df.loc[index, 'ASHP, SEER 13, 8.0 HSPF'] += row['ASHP'] / 5.0
            df.loc[index, 'ASHP, SEER 14.3, 8.5 HSPF'] += row['ASHP'] / 5.0
            df.loc[index, 'ASHP, SEER 16, 9.0 HSPF'] += row['ASHP'] / 5.0
        del df['ASHP']
        df = df.fillna(0)
        df = add_option_prefix(df)
        df = df.reset_index()
        df['Dependency=Vintage'] = pd.Categorical(df['Dependency=Vintage'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s'])
        df = df.sort_values(by=['Dependency=Location Heating Region', 'Dependency=Heating Fuel', 'Dependency=HVAC System Is Combined', 'Dependency=Vintage']).set_index(['Dependency=Location Heating Region', 'Dependency=Vintage', 'Dependency=Heating Fuel', 'Dependency=HVAC System Is Combined'])
        if smooth:
            df_sub = df.reset_index()
            df_sub = df_sub[(df_sub['Dependency=Heating Fuel']=='Electricity') & (df_sub['Dependency=HVAC System Is Combined']=='Yes')].set_index(['Dependency=Location Heating Region', 'Dependency=Vintage', 'Dependency=Heating Fuel', 'Dependency=HVAC System Is Combined'])                
            df_sub = apply_smoothing(df_sub, 'Dependency=Location Heating Region', 'Dependency=Vintage', ['Dependency=Heating Fuel', 'Dependency=HVAC System Is Combined'])
            df.update(df_sub)        
        return df
        
    def hvac_system_is_combined(self):
        df = util.create_dataframe(self.session, rdb)
        df = util.assign_climate_zones(df)
        df = util.assign_state(df)
        df = util.assign_heating_location(df)
        df = util.assign_cooling_location(df)
        df = util.assign_vintage(df)
        df = util.assign_heating_fuel(df)
        df = util.assign_hvac_system_combined(df)
        df = util.assign_hvac_system_is_combined(df, 'htg_and_clg')
        df, cols = util.categories_to_columns(df, 'Dependency=HVAC System Is Combined')
        df = df.groupby(['Dependency=Location Heating Region', 'Dependency=Vintage', 'Dependency=Heating Fuel'])
        missing_groups = []
        for group in itertools.product(*[['H1', 'H2', 'H3'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s'], ['Electricity', 'Fuel Oil', 'Natural Gas', 'Propane', 'Wood']]):
            if not group in list(df.groups):
                missing_groups.append(dict(zip(['Dependency=Location Heating Region', 'Dependency=Vintage', 'Dependency=Heating Fuel'], group)))
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
                df_new = pd.DataFrame(data=data, index=[0]).set_index(['Dependency=Location Heating Region', 'Dependency=Vintage', 'Dependency=Heating Fuel'])
            else:
                data = dict(group.items() + dict(zip(columns, [0] * len(columns))).items())
                data['No'] = 1
                df_new = pd.DataFrame(data=data, index=[0]).set_index(['Dependency=Location Heating Region', 'Dependency=Vintage', 'Dependency=Heating Fuel'])
            df_new['Count'] = 0
            df_new['Weight'] = 0
            df = df.append(df_new)
        df = add_option_prefix(df)
        df = df.reset_index()
        df['Dependency=Vintage'] = pd.Categorical(df['Dependency=Vintage'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s'])
        df = df.sort_values(by=['Dependency=Location Heating Region', 'Dependency=Heating Fuel', 'Dependency=Vintage']).set_index(['Dependency=Location Heating Region', 'Dependency=Heating Fuel', 'Dependency=Vintage'])        
        return df
        
    def hvac_system_heating_secondary(self):       
        df = util.create_dataframe(self.session, rdb, False)
        # df = util.assign_climate_zones(df)
        # df = util.assign_state(df)
        # df = util.assign_heating_location(df)
        # df = util.assign_cooling_location(df)
        # df = util.assign_vintage(df)
        # df = util.assign_heating_types_and_fuel(df)
        df = util.assign_presence_of_secondary_system(df)
        return df
        
    def hvac_system_heating_electricity(self, smooth=False):
        df = util.create_dataframe(self.session, rdb)
        df = util.assign_climate_zones(df)
        df = util.assign_state(df)
        df = util.assign_heating_location(df)
        df = util.assign_cooling_location(df)
        df = util.assign_vintage(df)
        df = util.assign_heating_fuel(df)
        df = util.assign_hvac_system_combined(df)
        df = util.assign_hvac_system_heating(df)      
        df = util.assign_hvac_system_is_combined(df, 'htg_and_clg')
        df.loc[df['Dependency=HVAC System Is Combined']=='Yes', 'htg'] = 'None'
        df, cols = util.categories_to_columns(df, 'htg')
        df = df.groupby(['Dependency=Location Heating Region', 'Dependency=Vintage', 'Dependency=Heating Fuel', 'Dependency=HVAC System Is Combined'])
        missing_groups = []
        for group in itertools.product(*[['H1', 'H2', 'H3'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s'], ['Electricity', 'Fuel Oil', 'Natural Gas', 'Propane', 'Wood'], ['Yes', 'No']]):
            if not group in list(df.groups):
                missing_groups.append(dict(zip(['Dependency=Location Heating Region', 'Dependency=Vintage', 'Dependency=Heating Fuel', 'Dependency=HVAC System Is Combined'], group)))           
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight']
        df = util.sum_cols(df, cols)
        df['Count'] = count
        df['Weight'] = weight
        columns = ['Electric Baseboard', 'Electric Boiler', 'Electric Furnace', 'None']
        for group in missing_groups:
            if group['Dependency=HVAC System Is Combined'] == 'No' and group['Dependency=Heating Fuel'] == 'Electricity':
                columns.remove('None')
                data = dict(group.items() + dict(zip(columns, [1.0/3.0] * 3)).items())
                columns.append('None')
                data['None'] = 0
                df_new = pd.DataFrame(data=data, index=[0]).set_index(['Dependency=Location Heating Region', 'Dependency=Vintage', 'Dependency=Heating Fuel', 'Dependency=HVAC System Is Combined'])
            else:
                data = dict(group.items() + dict(zip(columns, [0] * 3)).items())
                data['None'] = 1
                df_new = pd.DataFrame(data=data, index=[0]).set_index(['Dependency=Location Heating Region', 'Dependency=Vintage', 'Dependency=Heating Fuel', 'Dependency=HVAC System Is Combined'])
            df_new['Count'] = 0
            df_new['Weight'] = 0
            df = df.append(df_new)
        df = add_option_prefix(df)
        df = df[['Option=Electric Baseboard', 'Option=Electric Boiler', 'Option=Electric Furnace', 'Option=None', 'Count', 'Weight']]
        df = df.reset_index()
        df.loc[df['Dependency=Heating Fuel']!='Electricity', 'Option=None'] = 1
        df['Dependency=Vintage'] = pd.Categorical(df['Dependency=Vintage'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s'])
        df = df.sort_values(by=['Dependency=Location Heating Region', 'Dependency=Heating Fuel', 'Dependency=HVAC System Is Combined', 'Dependency=Vintage']).set_index(['Dependency=Location Heating Region', 'Dependency=Vintage', 'Dependency=Heating Fuel', 'Dependency=HVAC System Is Combined'])
        if smooth:
            df_sub = df.reset_index()
            df_sub = df_sub[(df_sub['Dependency=Heating Fuel']=='Electricity') & (df_sub['Dependency=HVAC System Is Combined']=='No')].set_index(['Dependency=Location Heating Region', 'Dependency=Vintage', 'Dependency=Heating Fuel', 'Dependency=HVAC System Is Combined'])                
            df_sub = apply_smoothing(df_sub, 'Dependency=Location Heating Region', 'Dependency=Vintage', ['Dependency=Heating Fuel', 'Dependency=HVAC System Is Combined'])
            df.update(df_sub)
        return df
        
    def hvac_system_heating_natural_gas(self, smooth=False):
        df = util.create_dataframe(self.session, rdb)
        df = util.assign_climate_zones(df)
        df = util.assign_state(df)
        df = util.assign_heating_location(df)
        df = util.assign_cooling_location(df)
        df = util.assign_vintage(df)
        df = util.assign_heating_fuel(df)
        df = util.assign_hvac_system_combined(df)
        df = util.assign_hvac_system_heating(df)      
        df = util.assign_hvac_system_is_combined(df, 'htg_and_clg')
        df.loc[df['Dependency=HVAC System Is Combined']=='Yes', 'htg'] = 'None'
        df, cols = util.categories_to_columns(df, 'htg')
        df = df.groupby(['Dependency=Location Heating Region', 'Dependency=Vintage', 'Dependency=Heating Fuel', 'Dependency=HVAC System Is Combined'])
        missing_groups = []
        for group in itertools.product(*[['H1', 'H2', 'H3'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s'], ['Electricity', 'Fuel Oil', 'Natural Gas', 'Propane', 'Wood'], ['Yes', 'No']]):
            if not group in list(df.groups):
                missing_groups.append(dict(zip(['Dependency=Location Heating Region', 'Dependency=Vintage', 'Dependency=Heating Fuel', 'Dependency=HVAC System Is Combined'], group)))           
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight']
        df = util.sum_cols(df, cols)
        df['Count'] = count
        df['Weight'] = weight
        columns = ['Gas Boiler, 72% AFUE', 'Gas Boiler, 76% AFUE', 'Gas Boiler, 80% AFUE', 'Gas Boiler, 85% AFUE', 'Gas Boiler, 96% AFUE', 'Gas Furnace, 60% AFUE', 'Gas Furnace, 68% AFUE', 'Gas Furnace, 76% AFUE', 'Gas Furnace, 80% AFUE', 'Gas Furnace, 90% AFUE', 'Gas Furnace, 96% AFUE', 'Gas Stove, 75% AFUE', 'None']
        for group in missing_groups:
            if group['Dependency=HVAC System Is Combined'] == 'No' and group['Dependency=Heating Fuel'] == 'Natural Gas':
                columns.remove('None')
                data = dict(group.items() + dict(zip(columns, [1.0/12.0] * 12)).items())
                columns.append('None')
                data['None'] = 0
                df_new = pd.DataFrame(data=data, index=[0]).set_index(['Dependency=Location Heating Region', 'Dependency=Vintage', 'Dependency=Heating Fuel', 'Dependency=HVAC System Is Combined'])
            else:
                data = dict(group.items() + dict(zip(columns, [0] * 12)).items())
                data['None'] = 1
                df_new = pd.DataFrame(data=data, index=[0]).set_index(['Dependency=Location Heating Region', 'Dependency=Vintage', 'Dependency=Heating Fuel', 'Dependency=HVAC System Is Combined'])
            df_new['Count'] = 0
            df_new['Weight'] = 0
            df = df.append(df_new)           
        for index, row in df.iterrows():
          gas_furnace_frac = row['Gas Furnace, 60% AFUE'] + row['Gas Furnace, 68% AFUE'] + row['Gas Furnace, 76% AFUE'] + row['Gas Furnace, 80% AFUE'] + row['Gas Furnace, 90% AFUE'] + row['Gas Furnace, 96% AFUE']
          if gas_furnace_frac > 0:
            df.loc[index, 'Gas Furnace, 60% AFUE'] += row['Gas Furnace'] * (row['Gas Furnace, 60% AFUE'] / gas_furnace_frac)
            df.loc[index, 'Gas Furnace, 68% AFUE'] += row['Gas Furnace'] * (row['Gas Furnace, 68% AFUE'] / gas_furnace_frac)
            df.loc[index, 'Gas Furnace, 76% AFUE'] += row['Gas Furnace'] * (row['Gas Furnace, 76% AFUE'] / gas_furnace_frac)
            df.loc[index, 'Gas Furnace, 80% AFUE'] += row['Gas Furnace'] * (row['Gas Furnace, 80% AFUE'] / gas_furnace_frac)
            df.loc[index, 'Gas Furnace, 90% AFUE'] += row['Gas Furnace'] * (row['Gas Furnace, 90% AFUE'] / gas_furnace_frac)
            df.loc[index, 'Gas Furnace, 96% AFUE'] += row['Gas Furnace'] * (row['Gas Furnace, 96% AFUE'] / gas_furnace_frac)
          else:
            df.loc[index, 'Gas Furnace, 60% AFUE'] += row['Gas Furnace'] / 6.0
            df.loc[index, 'Gas Furnace, 68% AFUE'] += row['Gas Furnace'] / 6.0
            df.loc[index, 'Gas Furnace, 76% AFUE'] += row['Gas Furnace'] / 6.0
            df.loc[index, 'Gas Furnace, 80% AFUE'] += row['Gas Furnace'] / 6.0
            df.loc[index, 'Gas Furnace, 90% AFUE'] += row['Gas Furnace'] / 6.0
            df.loc[index, 'Gas Furnace, 96% AFUE'] += row['Gas Furnace'] / 6.0
          gas_boiler_frac = row['Gas Boiler, 72% AFUE'] + row['Gas Boiler, 76% AFUE'] + row['Gas Boiler, 80% AFUE'] + row['Gas Boiler, 85% AFUE'] + row['Gas Boiler, 96% AFUE']
          if gas_boiler_frac > 0:
            df.loc[index, 'Gas Boiler, 72% AFUE'] += row['Gas Boiler'] * (row['Gas Boiler, 72% AFUE'] / gas_boiler_frac)
            df.loc[index, 'Gas Boiler, 76% AFUE'] += row['Gas Boiler'] * (row['Gas Boiler, 76% AFUE'] / gas_boiler_frac)
            df.loc[index, 'Gas Boiler, 80% AFUE'] += row['Gas Boiler'] * (row['Gas Boiler, 80% AFUE'] / gas_boiler_frac)
            df.loc[index, 'Gas Boiler, 85% AFUE'] += row['Gas Boiler'] * (row['Gas Boiler, 85% AFUE'] / gas_boiler_frac)
            df.loc[index, 'Gas Boiler, 96% AFUE'] += row['Gas Boiler'] * (row['Gas Boiler, 96% AFUE'] / gas_boiler_frac)
          else:
            df.loc[index, 'Gas Boiler, 72% AFUE'] += row['Gas Boiler'] / 5.0
            df.loc[index, 'Gas Boiler, 76% AFUE'] += row['Gas Boiler'] / 5.0
            df.loc[index, 'Gas Boiler, 80% AFUE'] += row['Gas Boiler'] / 5.0
            df.loc[index, 'Gas Boiler, 85% AFUE'] += row['Gas Boiler'] / 5.0
            df.loc[index, 'Gas Boiler, 96% AFUE'] += row['Gas Boiler'] / 5.0
        df = df.fillna(0)
        df = add_option_prefix(df)
        df = df[['Option=Gas Boiler, 72% AFUE', 'Option=Gas Boiler, 76% AFUE', 'Option=Gas Boiler, 80% AFUE', 'Option=Gas Boiler, 85% AFUE', 'Option=Gas Boiler, 96% AFUE', 'Option=Gas Furnace, 60% AFUE', 'Option=Gas Furnace, 68% AFUE', 'Option=Gas Furnace, 76% AFUE', 'Option=Gas Furnace, 80% AFUE', 'Option=Gas Furnace, 90% AFUE', 'Option=Gas Furnace, 96% AFUE', 'Option=FIXME Gas Stove, 75% AFUE', 'Option=None', 'Count', 'Weight']]
        df = df.reset_index()
        df.loc[df['Dependency=Heating Fuel']!='Natural Gas', 'Option=None'] = 1        
        df['Dependency=Vintage'] = pd.Categorical(df['Dependency=Vintage'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s'])
        df = df.sort_values(by=['Dependency=Location Heating Region', 'Dependency=Heating Fuel', 'Dependency=HVAC System Is Combined', 'Dependency=Vintage']).set_index(['Dependency=Location Heating Region', 'Dependency=Vintage', 'Dependency=Heating Fuel', 'Dependency=HVAC System Is Combined'])
        if smooth:
            df_sub = df.reset_index()
            df_sub = df_sub[(df_sub['Dependency=Heating Fuel']=='Natural Gas') & (df_sub['Dependency=HVAC System Is Combined']=='No')].set_index(['Dependency=Location Heating Region', 'Dependency=Vintage', 'Dependency=Heating Fuel', 'Dependency=HVAC System Is Combined'])        
            df_sub = apply_smoothing(df_sub, 'Dependency=Location Heating Region', 'Dependency=Vintage', ['Dependency=Heating Fuel', 'Dependency=HVAC System Is Combined'])
            df.update(df_sub)
        return df
        
    def hvac_system_heating_fuel_oil(self):
        df = util.create_dataframe(self.session, rdb)
        df = util.assign_climate_zones(df)
        df = util.assign_state(df)
        df = util.assign_heating_location(df)
        df = util.assign_cooling_location(df)
        df = util.assign_vintage(df)
        df = util.assign_heating_fuel(df)
        df = util.assign_hvac_system_combined(df)
        df = util.assign_hvac_system_heating(df)      
        df = util.assign_hvac_system_is_combined(df, 'htg_and_clg')
        df.loc[df['Dependency=HVAC System Is Combined']=='Yes', 'htg'] = 'None'
        df, cols = util.categories_to_columns(df, 'htg')
        df = df.groupby(['Dependency=Heating Fuel', 'Dependency=HVAC System Is Combined'])
        missing_groups = []
        for group in itertools.product(*[['Electricity', 'Fuel Oil', 'Natural Gas', 'Propane', 'Wood'], ['Yes', 'No']]):
            if not group in list(df.groups):
                missing_groups.append(dict(zip(['Dependency=Heating Fuel', 'Dependency=HVAC System Is Combined'], group)))           
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight']
        df = util.sum_cols(df, cols)
        df['Count'] = count
        df['Weight'] = weight
        columns = ['Oil Boiler', 'Oil Furnace', 'Oil Stove', 'None']
        for group in missing_groups:
            if group['Dependency=HVAC System Is Combined'] == 'No' and group['Dependency=Heating Fuel'] == 'Fuel Oil':
                columns.remove('None')
                data = dict(group.items() + dict(zip(columns, [1.0/3.0] * 3)).items())
                columns.append('None')
                data['None'] = 0
                df_new = pd.DataFrame(data=data, index=[0]).set_index(['Dependency=Heating Fuel', 'Dependency=HVAC System Is Combined'])
            else:
                data = dict(group.items() + dict(zip(columns, [0] * 3)).items())
                data['None'] = 1
                df_new = pd.DataFrame(data=data, index=[0]).set_index(['Dependency=Heating Fuel', 'Dependency=HVAC System Is Combined'])
            df_new['Count'] = 0
            df_new['Weight'] = 0
            df = df.append(df_new)
        df = add_option_prefix(df)
        df = df[['Option=Oil Boiler', 'Option=Oil Furnace', 'Option=FIXME Oil Stove', 'Option=None', 'Count', 'Weight']]
        df = df.reset_index()
        df.loc[df['Dependency=Heating Fuel']!='Fuel Oil', 'Option=None'] = 1
        df = df.sort_values(by=['Dependency=Heating Fuel', 'Dependency=HVAC System Is Combined']).set_index(['Dependency=Heating Fuel', 'Dependency=HVAC System Is Combined'])
        return df        
        
    def hvac_system_heating_propane(self):
        df = util.create_dataframe(self.session, rdb)
        df = util.assign_climate_zones(df)
        df = util.assign_state(df)
        df = util.assign_heating_location(df)
        df = util.assign_cooling_location(df)
        df = util.assign_vintage(df)
        df = util.assign_heating_fuel(df)
        df = util.assign_hvac_system_combined(df)
        df = util.assign_hvac_system_heating(df)      
        df = util.assign_hvac_system_is_combined(df, 'htg_and_clg')
        df.loc[df['Dependency=HVAC System Is Combined']=='Yes', 'htg'] = 'None'
        df, cols = util.categories_to_columns(df, 'htg')
        df = df.groupby(['Dependency=Heating Fuel', 'Dependency=HVAC System Is Combined'])
        missing_groups = []
        for group in itertools.product(*[['Electricity', 'Fuel Oil', 'Natural Gas', 'Propane', 'Wood'], ['Yes', 'No']]):
            if not group in list(df.groups):
                missing_groups.append(dict(zip(['Dependency=Heating Fuel', 'Dependency=HVAC System Is Combined'], group)))           
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight']
        df = util.sum_cols(df, cols)
        df['Count'] = count
        df['Weight'] = weight
        columns = ['Propane Boiler', 'Propane Stove', 'None']
        for group in missing_groups:
            if group['Dependency=HVAC System Is Combined'] == 'No' and group['Dependency=Heating Fuel'] == 'Propane':
                columns.remove('None')
                data = dict(group.items() + dict(zip(columns, [1.0/2.0] * 2)).items())
                columns.append('None')
                data['None'] = 0
                df_new = pd.DataFrame(data=data, index=[0]).set_index(['Dependency=Heating Fuel', 'Dependency=HVAC System Is Combined'])
            else:
                data = dict(group.items() + dict(zip(columns, [0] * 2)).items())
                data['None'] = 1
                df_new = pd.DataFrame(data=data, index=[0]).set_index(['Dependency=Heating Fuel', 'Dependency=HVAC System Is Combined'])
            df_new['Count'] = 0
            df_new['Weight'] = 0
            df = df.append(df_new)
        df = add_option_prefix(df)
        df = df[['Option=Propane Boiler', 'Option=FIXME Propane Stove', 'Option=None', 'Count', 'Weight']]
        df = df.reset_index()
        df.loc[df['Dependency=Heating Fuel']!='Propane', 'Option=None'] = 1
        df = df.sort_values(by=['Dependency=Heating Fuel', 'Dependency=HVAC System Is Combined']).set_index(['Dependency=Heating Fuel', 'Dependency=HVAC System Is Combined'])
        return df        
        
    def hvac_system_heating_wood(self):
        df = util.create_dataframe(self.session, rdb)
        df = util.assign_climate_zones(df)
        df = util.assign_state(df)
        df = util.assign_heating_location(df)
        df = util.assign_cooling_location(df)
        df = util.assign_vintage(df)
        df = util.assign_heating_fuel(df)
        df = util.assign_hvac_system_combined(df)
        df = util.assign_hvac_system_heating(df)      
        df = util.assign_hvac_system_is_combined(df, 'htg_and_clg')
        df.loc[df['Dependency=HVAC System Is Combined']=='Yes', 'htg'] = 'None'
        df, cols = util.categories_to_columns(df, 'htg')
        df = df.groupby(['Dependency=Heating Fuel', 'Dependency=HVAC System Is Combined'])
        missing_groups = []
        for group in itertools.product(*[['Electricity', 'Fuel Oil', 'Natural Gas', 'Propane', 'Wood'], ['Yes', 'No']]):
            if not group in list(df.groups):
                missing_groups.append(dict(zip(['Dependency=Heating Fuel', 'Dependency=HVAC System Is Combined'], group)))           
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight']
        df = util.sum_cols(df, cols)
        df['Count'] = count
        df['Weight'] = weight
        columns = ['Wood Stove', 'None']
        for group in missing_groups:
            if group['Dependency=HVAC System Is Combined'] == 'No' and group['Dependency=Heating Fuel'] == 'Wood':
                columns.remove('None')
                data = dict(group.items() + dict(zip(columns, [1.0/1.0] * 1)).items())
                columns.append('None')
                data['None'] = 0
                df_new = pd.DataFrame(data=data, index=[0]).set_index(['Dependency=Heating Fuel', 'Dependency=HVAC System Is Combined'])
            else:
                data = dict(group.items() + dict(zip(columns, [0] * 1)).items())
                data['None'] = 1
                df_new = pd.DataFrame(data=data, index=[0]).set_index(['Dependency=Heating Fuel', 'Dependency=HVAC System Is Combined'])
            df_new['Count'] = 0
            df_new['Weight'] = 0
            df = df.append(df_new)
        df = add_option_prefix(df)
        df = df[['Option=FIXME Wood Stove', 'Option=None', 'Count', 'Weight']]
        df = df.reset_index()
        df.loc[df['Dependency=Heating Fuel']!='Wood', 'Option=None'] = 1
        df = df.sort_values(by=['Dependency=Heating Fuel', 'Dependency=HVAC System Is Combined']).set_index(['Dependency=Heating Fuel', 'Dependency=HVAC System Is Combined'])
        return df        
        
    def hvac_system_cooling(self, smooth=False):
        df = util.create_dataframe(self.session, rdb)
        df = util.assign_climate_zones(df)
        df = util.assign_state(df)
        df = util.assign_heating_location(df)
        df = util.assign_cooling_location(df)
        df = util.assign_vintage(df)
        df = util.assign_heating_fuel(df)
        df = util.assign_hvac_system_combined(df)
        df = util.assign_hvac_system_cooling(df)
        df = util.assign_hvac_system_is_combined(df, 'htg_and_clg')        
        df.loc[df['Dependency=HVAC System Is Combined']=='Yes', 'clg'] = 'None'
        df, cols = util.categories_to_columns(df, 'clg')
        df = df.groupby(['Dependency=Location Cooling Region', 'Dependency=Vintage', 'Dependency=HVAC System Is Combined'])
        missing_groups = []
        for group in itertools.product(*[['C1', 'C2', 'C3'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s'], ['Yes', 'No']]):
            if not group in list(df.groups):
                missing_groups.append(dict(zip(['Dependency=Location Cooling Region', 'Dependency=Vintage', 'Dependency=HVAC System Is Combined'], group)))           
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
                df_new = pd.DataFrame(data=data, index=[0]).set_index(['Dependency=Location Cooling Region', 'Dependency=Vintage', 'Dependency=HVAC System Is Combined'])
            else:
                data = dict(group.items() + dict(zip(columns, [0] * len(columns))).items())
                data['None'] = 1
                df_new = pd.DataFrame(data=data, index=[0]).set_index(['Dependency=Location Cooling Region', 'Dependency=Vintage', 'Dependency=HVAC System Is Combined'])
            df_new['Count'] = 0
            df_new['Weight'] = 0
            df = df.append(df_new)
        for index, row in df.iterrows():
          ac_frac = row['AC, SEER 10'] + row['AC, SEER 13'] + row['AC, SEER 15']
          if ac_frac > 0:
            df.loc[index, 'AC, SEER 10'] += row['AC'] * (row['AC, SEER 10'] / ac_frac)
            df.loc[index, 'AC, SEER 13'] += row['AC'] * (row['AC, SEER 13'] / ac_frac)
            df.loc[index, 'AC, SEER 15'] += row['AC'] * (row['AC, SEER 15'] / ac_frac)
          else:
            df.loc[index, 'AC, SEER 10'] += row['AC'] / 3.0
            df.loc[index, 'AC, SEER 13'] += row['AC'] / 3.0
            df.loc[index, 'AC, SEER 15'] += row['AC'] / 3.0
        df = df.fillna(0)
        df = add_option_prefix(df)
        df = df[['Option=AC, SEER 10', 'Option=AC, SEER 13', 'Option=AC, SEER 15', 'Option=Room AC, EER 9.8, 20% Conditioned', 'Option=FIXME Evaporative Cooler', 'Option=None', 'Count', 'Weight']]
        df = df.reset_index()
        df['Dependency=Vintage'] = pd.Categorical(df['Dependency=Vintage'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s'])
        df = df.sort_values(by=['Dependency=Location Cooling Region', 'Dependency=HVAC System Is Combined', 'Dependency=Vintage']).set_index(['Dependency=Location Cooling Region', 'Dependency=Vintage', 'Dependency=HVAC System Is Combined'])
        if smooth:
            df_sub = df.reset_index()
            df_sub = df_sub[df_sub['Dependency=HVAC System Is Combined']=='No'].set_index(['Dependency=Location Cooling Region', 'Dependency=Vintage', 'Dependency=HVAC System Is Combined'])
            df_sub = apply_smoothing(df_sub, 'Dependency=Location Cooling Region', 'Dependency=Vintage', ['Dependency=HVAC System Is Combined'])
            df.update(df_sub)
        return df
    
    def ducts(self):
        """
        Ducts differ from other RBSA categories because leakage and insulation are in different DB tables and leakage values
        are only available for a subset of ~250 homes. For this reason, we construct the probability distributions entirely
        in util.py instead of in input.py.
        :return:
        """
        df = util.create_dataframe(self.session, rdb)
        df = util.assign_climate_zones(df)
        df = util.assign_state(df)
        df = util.assign_heating_location(df)
        df = util.assign_vintage(df)
        df = util.assign_foundation_type(df)
        df = util.assign_heated_basement_boolean(df)
        df = util.assign_ducts(df)
        return df
    
    def ducts_analysis(self):
        df = util.create_dataframe(self.session, rdb)
        df = util.assign_climate_zones(df)
        df = util.assign_state(df)
        df = util.assign_heating_location(df)
        df = util.assign_vintage(df)
        
        sfductsRval = {'R0': 0,
                       'R2-R4': 3,
                       'R7-R11': 9,
                       'R4 Flex': 4,
                       'R6 Flex': 6,
                       'R8 Flex': 8,
                       'R0 Metal; R4 Flex': 2,
                       'R0 Metal; R6 Flex': 3,
                       'R0 Metal; R8 Flex': 4,
                       'R2-R4 Metal; R4 Flex': 3.5,
                       'R2-R4 Metal; R6 Flex': 4.5,
                       'R2-R4 Metal; R8 Flex': 5.5,
                       'R7-R11 Metal; R4 Flex': 6.5,
                       'R7-R11 Metal; R6 Flex': 7.5,
                       'R7-R11 Metal; R8 Flex': 8.5,
                       '1" Ductboard': 4,
                       '2" Ductboard': 8,
                       '1" Ductboard; R4 Flex': 4,
                       '1" Ductboard; R6 Flex': 5,
                       '1" Ductboard; R8 Flex': 6,
                       '2" Ductboard; R4 Flex': 6,
                       '2" Ductboard; R6 Flex': 7}
    
        def ductrval(sfducts):
            if len(sfducts) == 0:
                return np.nan
            for ducts in sfducts:
                if ducts.ductinsulationtype:
                    return sfductsRval[ducts.ductinsulationtype]
                else:
                    return np.nan
                    
        def ductrvalbin(rval):
            if rval < 2:
                return 'Very low'
            elif rval >= 2 and rval < 4:
                return 'Low'
            elif rval >= 4 and rval < 6:
                return 'Medium'
            elif rval >= 6 and rval < 8:
                return 'High'
            elif rval >= 8 and rval:
                return 'Very high'                
                    
        sfductsincond = {0: 'None',
                         25: 'Partial',
                         50: 'Partial',
                         75: 'Partial',
                         100: 'All'}
    
        def ductincond(sfducts):
            if len(sfducts) == 0:
                return np.nan
            for ducts in sfducts:
                if ducts.ductsinconditioned:
                    return sfductsincond[ducts.ductsinconditioned]
                else:
                    return np.nan                    
                    
        def ductleak(sfducttesting_dbase):
            if len(sfducttesting_dbase) == 0:
                return np.nan
            for ducts in sfducttesting_dbase:
                if ducts.slfhalfplen and ducts.rlfhalfplen:
                    return ducts.slfhalfplen + ducts.rlfhalfplen
                else:
                    return np.nan
                    
        df['ductrval'] = df.apply(lambda x: ductrval(x.object.sfducts), axis=1)
        df['ductrvalbin'] = df.apply(lambda x: ductrvalbin(x.ductrval), axis=1)
        df['ductincond'] = df.apply(lambda x: ductincond(x.object.sfducts), axis=1)
        df['ductleak'] = df.apply(lambda x: ductleak(x.object.sfducttestingdbase), axis=1)
        
        df_duct_r_val = df.dropna(subset=['ductrval'])
        df_duct_leakage_test_performed = df_duct_r_val.dropna(subset=['ductleak'])
        ax = sns.kdeplot(df_duct_r_val['ductrval'], label='all insulation values')
        ax = sns.kdeplot(df_duct_leakage_test_performed['ductrval'], label='insulation values with leakage test')
        ax.set(xlabel='r-value', ylabel='density')
        plt.legend()
        plt.savefig('test1.png')
        plt.close()
        
        ax = sns.kdeplot(df_duct_leakage_test_performed[df_duct_leakage_test_performed['ductrvalbin']=='Very low']['ductleak'], label='Very low ins')
        ax = sns.kdeplot(df_duct_leakage_test_performed[df_duct_leakage_test_performed['ductrvalbin']=='Low']['ductleak'], label='Low ins')
        ax = sns.kdeplot(df_duct_leakage_test_performed[df_duct_leakage_test_performed['ductrvalbin']=='Medium']['ductleak'], label='Medium ins')
        ax = sns.kdeplot(df_duct_leakage_test_performed[df_duct_leakage_test_performed['ductrvalbin']=='High']['ductleak'], label='High ins')
        ax = sns.kdeplot(df_duct_leakage_test_performed[df_duct_leakage_test_performed['ductrvalbin']=='Very high']['ductleak'], label='Very high ins')
        ax.set(xlabel='leak frac', ylabel='density')
        plt.legend()
        plt.savefig('test2.png')
        plt.close()
        
        ax = sns.regplot(x=df_duct_leakage_test_performed['ductrval'], y=df_duct_leakage_test_performed['ductleak'], color="g")
        ax.set(xlabel='r-val', ylabel='leak frac')
        plt.legend()
        plt.savefig('test3.png')
        plt.close()              
        
        df[['Dependency=Location Heating Region', 'Dependency=Vintage', 'ductrval', 'ductrvalbin', 'ductincond', 'ductleak']].to_csv(os.path.join(datafiles_dir, 'Ducts Analysis.tsv'), sep='\t')
        
        sys.exit()
    
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
        df = df[['Option=Electric, 100% Usage', 'Option=Gas, 100% Usage', 'Option=Propane, 100% Usage', 'Option=None', 'Count', 'Weight']]
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
        df = df[['Option=Electric, 100% Usage', 'Option=Gas, 100% Usage', 'Option=None', 'Count', 'Weight']]
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
            if col in ['GSHP', 'Dual-Fuel ASHP, SEER 14, 8.2 HSPF', 'Gas Stove, 75% AFUE', 'Oil Stove', 'Propane Stove', 'Wood Stove', 'Evaporative Cooler']:
                df.rename(columns={col: 'Option=FIXME {}'.format(col)}, inplace=True)
            else:
                df.rename(columns={col: 'Option={}'.format(col)}, inplace=True)
    return df

def apply_smoothing(df, w1, w2, additional_indexes=[]):
    df = df.reset_index()
    for col in df.columns:
        if not 'Option' in col:
            continue
        df[col] *= df['Weight']
        p1 = df[[w1, col]].groupby([w1]).sum()
        p2 = df[[w2, col]].groupby([w2]).sum()        
        df[col] = df.apply(lambda row: smoothing_calculation(row, col, p1, p2), axis=1)
    df = df.set_index([w1, w2] + additional_indexes)
    del df['Weight']
    df['Weight'] = df.drop(['Count'], axis=1).sum(axis=1)
    for col in df.columns:
        if not 'Option' in col:
            continue
        df[col] = df[col] / df['Weight']
    return df
    
def smoothing_calculation(row, col, p1, p2):
    return ( p1.loc[row[p1.index.name], col] / p1[col].sum() ) * p2.loc[row[p2.index.name], col]
    
if __name__ == '__main__':
    
    datafiles_dir = '../../resources/inputs/pnw'
    heatmaps_dir = 'heatmaps'

    dfs = Create_DFs('rbsa.sqlite')
    
    # Other possible categories: 'Insulation Wall H1', 'Insulation Wall H2', 'Insulation Wall H3', 'Insulation Unfinished Attic H1', 'Insulation Unfinished Attic H2', 'Insulation Unfinished Attic H3', 'Windows H1', 'Windows H2', 'Windows H3'
    # for category in ['Location Heating Region', 'Location Cooling Region', 'Vintage', 'Heating Fuel', 'Geometry Foundation Type', 'Geometry House Size', 'Geometry Stories', 'Insulation Unfinished Attic', 'Insulation Wall', 'Heating Setpoint', 'Cooling Setpoint', 'Insulation Slab', 'Insulation Crawlspace', 'Insulation Unfinished Basement', 'Insulation Finished Basement', 'Insulation Interzonal Floor', 'Windows', 'Infiltration', 'HVAC System Combined', 'HVAC System Heating Electricity', 'HVAC System Heating Natural Gas', 'HVAC System Heating Fuel Oil', 'HVAC System Heating Propane', 'HVAC System Heating Wood', 'HVAC System Cooling', 'HVAC System Is Combined', 'Ducts', 'Water Heater', 'Lighting', 'Cooking Range', 'Clothes Dryer']:
    for category in ['HVAC System Heating Secondary']:
        print category
        method = getattr(dfs, category.lower().replace(' ', '_'))
        if category in ['Heating Fuel', 'Geometry Stories', 'HVAC System Heating Electricity', 'HVAC System Heating Natural Gas', 'HVAC System Cooling', 'Geometry House Size', 'HVAC System Combined', 'Infiltration', 'Insulation Crawlspace', 'Insulation Finished Basement', 'Insulation Interzonal Floor', 'Insulation Slab', 'Insulation Unfinished Attic', 'Insulation Wall', 'Insulation Unfinished Basement']: # these are smoothed
            df = method(True)
        else:
            df = method()
        df.to_csv(os.path.join(datafiles_dir, '{}.tsv'.format(category)), sep='\t')

        for col in ['Count', 'Weight']:
            if col in df.columns:
                del df[col]
        try:
            path = os.path.join(heatmaps_dir, '{}.png'.format(category))
            to_figure(df, path)
        except RuntimeError:
            print "Warning: Error in plotting figure; skipping {}.".format(path)
        to_figure(df, os.path.join(heatmaps_dir, '{}.png'.format(category)))