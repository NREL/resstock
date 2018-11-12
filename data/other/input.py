__author__ = 'ewilson'

import os
import sys
import numpy as np
import itertools
import pandas as pd

def _get_heating_set_point_auto(hdd, home_during_day=True, use_constant_average=True, smart_tstat=False):
    # Regression of heating setpoints vs HDD from RECS 2009
    T_home = round(-0.00037811*hdd + 71.185, 1) # deg F
    T_away = round(-0.00025154*hdd + 67.496, 1) # deg F
    T_night = round(-0.00044849*hdd + 69.375, 1) # deg F
    if use_constant_average: # Use weighted average of three values
        T_constant_average = ((T_night*6 + T_home*3 + T_away*8 + T_home*6 + T_night*1) + (T_night*6 + T_home*17 + T_night*1)) / 48
        if smart_tstat:
            T_setback = T_constant_average - 4 # Average night/away setback for Nest users (https://nest.com/downloads/press/documents/energy-savings-white-paper.pdf)
            weekday = [T_setback]*6 + [T_constant_average]*3 + [T_setback]*8 + [T_constant_average]*6 + [T_setback]*1
            weekend = [T_setback]*6 + [T_constant_average]*17 + [T_setback]*1            
        else:
            weekday = [T_constant_average]*24
            weekend = [T_constant_average]*24
    else: # Use the three values as a changing setpoint
        weekday = [T_night]*6 + [T_home]*3 + [T_away]*8 + [T_home]*6 + [T_night]*1
        weekend = [T_night]*6 + [T_home]*17 + [T_night]*1
    if not home_during_day:
        return weekday + weekend
    else:
        return weekend*2

def _get_cooling_set_point_auto(cdd, home_during_day=True, use_constant_average=True, smart_tstat=False):
    # Regression of cooling setpoints vs CDD from RECS 2009
    T_home = round(0.00115506*cdd + 71.351, 1) # deg F
    T_away = round(0.00137800*cdd + 72.714, 1) # deg F
    T_night = round(0.00097444*cdd + 71.446, 1) # deg F
    if use_constant_average: # Use weighted average of three values
        T_constant_average = ((T_night*6 + T_home*3 + T_away*8 + T_home*6 + T_night*1)*5 + (T_night*6 + T_home*17 + T_night*1)*2) / (24*7)
        if smart_tstat:
            T_setback = T_constant_average + 4 # Average away setup for Nest users--assume same as for heating (https://nest.com/downloads/press/documents/energy-savings-white-paper.pdf)
            weekday = [T_constant_average]*6 + [T_constant_average]*3 + [T_setback]*8 + [T_constant_average]*6 + [T_constant_average]*1
            weekend = [T_constant_average]*6 + [T_constant_average]*17 + [T_constant_average]*1            
        else:
            weekday = [T_constant_average]*24
            weekend = [T_constant_average]*24
    else: # Use the three values as a changing setpoint
        weekday = [T_night]*6 + [T_home]*3 + [T_away]*8 + [T_home]*6 + [T_night]*1
        weekend = [T_night]*6 + [T_home]*17 + [T_night]*1
    if not home_during_day:
        return weekday + weekend
    else:
        return weekend*2
        
def _calc_degree_days(epwfile, base_temp_f, is_heating):
    '''Calculates and returns degree days from a base temperature for either
    heating or cooling'''
    
    daily_dbs = _get_daily_dbs(epwfile)
    
    base_temp_c = (base_temp_f - 32.)/1.8
    if is_heating:
        deg_days = sum([(base_temp_c-x) for x in daily_dbs if x < base_temp_c])
    else:
        deg_days = sum([(x-base_temp_c) for x in daily_dbs if x > base_temp_c])
    return deg_days * 1.8
    
def _get_daily_dbs(epwfile):
    '''This snippet of code taken from BEopt's weather.py for retrieving daily dry-bulb temperatures'''

    f = open(epwfile, 'r')
    epwlines = f.readlines()

    epwlines = _remove_non_hourly_lines(epwlines)

    # Read data:
    hourdata = []
    dailydbs = []
    for hournum, epwline in enumerate(epwlines):

        data = epwline.strip().split(",")
        hourdict = {}
        hourdict['db'] = float(data[6])

        hourdata.append(hourdict)

        if (hournum+1) % 24 == 0:
            dailydbs.append(sum([x['db'] for x in hourdata][-24:])/24.0)
            
    return dailydbs
        
def _remove_non_hourly_lines(epwlines):
    '''Strips header lines until we get to the hourly data'''
    for epwline in epwlines:
        data = epwline.strip().split(",")
        if len(data) <= 4:
            epwlines = epwlines[1:]
        elif not (data[1] in ('1','01') and data[2] in ('1','01') and data[3] in ('1','01')):
            epwlines = epwlines[1:]
        else:
            break
    return epwlines[0:8760] # Exclude any text beyond the 8760th line
        
class Create_DFs():
    
    def __init__(self, file):
        self.session = pd.read_csv(file, index_col=['WMO'])

    def heating_setpoint(self):
        df = pd.read_csv('by_usaf.csv', usecols=['EPW'])
        df = df.rename(columns={'EPW': 'Dependency=Location EPW'})
        df['hdd'] = df['Dependency=Location EPW'].apply(lambda x: _calc_degree_days(x, 65, True))
        df['setpoint'] = df['hdd'].apply(lambda x: '{}F'.format(int(round(_get_heating_set_point_auto(x)[0]))))
        df['TotalSFD'] = 1
        df, cols = categories_to_columns(df, 'setpoint', False)
        df = df.set_index('Dependency=Location EPW')
        del df['hdd']
        del df['setpoint']
        del df['TotalSFD']
        del df['Weight']
        df = add_option_prefix(df)
        df = df[['Option=66F', 'Option=67F', 'Option=68F', 'Option=69F', 'Option=70F']]
        return df

    def cooling_setpoint(self):
        df = pd.read_csv('by_usaf.csv', usecols=['EPW'])
        df = df.rename(columns={'EPW': 'Dependency=Location EPW'})
        df['cdd'] = df['Dependency=Location EPW'].apply(lambda x: _calc_degree_days(x, 65, False))
        df['setpoint'] = df['cdd'].apply(lambda x: '{}F'.format(int(round(_get_cooling_set_point_auto(x)[0]))))
        df['TotalSFD'] = 1
        df, cols = categories_to_columns(df, 'setpoint', False)
        df = df.set_index('Dependency=Location EPW')
        del df['cdd']
        del df['setpoint']
        del df['TotalSFD']
        del df['Weight']
        df = add_option_prefix(df)
        df = df[['Option=72F', 'Option=73F', 'Option=74F', 'Option=75F', 'Option=76F', 'Option=77F']]
        return df
        
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
    
    def location_census_division(self):
    
        def assign_division(state):
            if state in ['WI', 'IL', 'IN', 'MI', 'OH']:
                return 'East North Central'
            elif state in ['NY', 'PA', 'NJ']:
                return 'Middle Atlantic'
            elif state in ['ME', 'NH', 'VT', 'MA', 'CT', 'RI']:
                return 'New England'
            elif state in ['ND', 'SD', 'NE', 'KS', 'MN', 'IA', 'MO']:
                return 'West North Central'
            elif state in ['TX', 'OK', 'AR', 'LA']:
                return 'West South Central'
            elif state in ['WA', 'OR', 'CA', 'NV', 'ID', 'MT', 'WY', 'CO', 'UT', 'AZ', 'NM']:    
                return 'Mountain - Pacific'
            elif state in ['WV', 'MD', 'DE', 'DC', 'VA', 'NC', 'SC', 'GA', 'FL', 'KY', 'TN', 'MS', 'AL']:
                return 'South Atlantic - East South Central'
    
        df = pd.read_csv('by_usaf.csv', index_col=['usaf'])
        df = df.rename(columns={'EPW': 'Dependency=Location EPW'})
        df['ST'] = df['Dependency=Location EPW'].apply(lambda x: x.split('_')[1])
        df['division'] = df['ST'].apply(lambda x: assign_division(x))
        df, cols = categories_to_columns(df, 'division')
        df = df.groupby(['Dependency=Location EPW'])
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight']
        df = sum_cols(df, cols)
        df['Count'] = count
        df['Weight'] = weight
        df = add_option_prefix(df)        
        return df
        
    def location_nsrdb(self):
        df = pd.read_csv('by_usaf.csv', index_col=['usaf'], usecols=['usaf', 'EPW'])
        df = df.rename(columns={'EPW': 'Dependency=Location EPW'})
        df = df.join(pd.read_csv('by_nsrdb.csv', index_col=['usaf'], usecols=['usaf', 'nsrdb_gid_new', 'TotalSFD']))
        df = pd.merge(df, pd.read_csv('nsrdb_regions.csv', usecols=['grid_gid', 'nsrdb_gid_new']), on='nsrdb_gid_new', how='left')
        df = df[df['TotalSFD']>0]
        count = df.groupby(['Dependency=Location EPW'])['TotalSFD'].count().to_frame()
        count = count.rename(columns={'TotalSFD': 'Count'})
        weight = df.groupby(['Dependency=Location EPW'])['TotalSFD'].sum().to_frame()
        weight = weight.rename(columns={'TotalSFD': 'Weight'})
        df = (df.groupby(['Dependency=Location EPW', 'nsrdb_gid_new'])['TotalSFD'].sum() / df.groupby('Dependency=Location EPW')['TotalSFD'].sum()).to_frame().reset_index()        
        df = df.pivot(index='Dependency=Location EPW', columns='nsrdb_gid_new', values='TotalSFD')
        df.columns = [str(col) for col in df.columns]
        df = pd.concat([df, count, weight], axis=1)
        df = df.fillna(0)
        df = add_option_prefix(df)
        return df
    
def categories_to_columns(df, column, svywt=True):
    df = df[df['TotalSFD']>0]
    categories = df[column]
    unique_categories = categories.unique()
    unique_category_weights = []
    for i, category in enumerate(unique_categories):
        print ' ... {}%'.format(100*(i+1)/float(len(unique_categories)))
        if svywt:
            df[str(category)] = df.apply(lambda x: x['TotalSFD'] * (1.0 / len(df[df.index==x.name])) if x[column] == category else 0, axis=1)
            df['%s_weight' % category] = df.apply(lambda x: x['TotalSFD'] * (1.0 / len(df[df.index==x.name])) if x[column] == category else 0, axis=1)
            unique_category_weights.append('%s_weight' % category)
        else:
            df[str(category)] = df.apply(lambda x: 1 if x[column] == category else 0, axis=1)
            unique_category_weights.append(str(category))

    df['Weight'] = df[unique_category_weights].sum(axis=1)
        
    return df, sorted([str(x) for x in unique_categories])    
    
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

    dfs = Create_DFs('Zones.csv')

    # for category in ['Heating Setpoint', 'Cooling Setpoint', 'Location Census Division', 'Location IECC EPW', 'Location BA EPW', 'Location NSRDB']:
    for category in ['Heating Setpoint', 'Cooling Setpoint']:
        print category
        method = getattr(dfs, category.lower().replace(' ', '_'))
        df = method()
        df.to_csv(os.path.join(datafiles_dir, '{}.tsv'.format(category)), sep='\t')
        