'''
Created on Apr 29, 2014
@author: ewilson
      : jalley
'''
import os, sys
import pandas
import matplotlib.pyplot as plt
import csv
sys.path.insert(0, os.path.join(os.getcwd(),'clustering'))
#from medoids_tstat import do_plot
import itertools
#recs_data_file = os.path.join("..", "RECS STUFF", "recs2009_public.csv")
import statsmodels.api as sm
import psycopg2 as pg
import pandas as pd
import numpy as np
from datetime import datetime
import pickle
from pandas import DataFrame, Series


startTime = datetime.now()


race_dict = {1:'White Alone',
             2:'Black or African/American Alone',
             3:'American Indian Alone',
             4:'Asian Alone',
             5:'Pacific Islander Alone',
             6:'Other Race Alone',
             7:'2 or More Races Selected'}

education_dict = {0:'No Schooling Completed',
                  1:'Kindergarten to Grade 12',
                  2:'High School Diploma/GED',
                  3:'Some College, No Degree',
                  4:"Associate's Degree",
                  5:"Bachelor's Degree",
                  6:"Master's Degree",
                  7:'Professional Degree',
                  8:'Doctorate Degree'}


region_def = {1:'CR01',
              2:'CR02',
              3:'CR03',
              4:'CR04',
              5:'CR05',
              6:'CR06',
              7:'CR07',
              8:'CR08',
              9:'CR09',
              10:'CR10',
              11:'CR11',
              12:'CR12'}

vintages = {1  :'1950-pre',
            2  :'1950s',
            3  :'1960s',
            4  :'1970s',
            5  :'1980s',
            6  :'1990s',
            7  :'2000s',
            8  :'2000s'}

fuels = {1:'Natural Gas',
         2:'Propane/LPG',
         3:'Fuel Oil',
         5:'Electricity',
         4:'Other Fuel',
         7:'Other Fuel',
         8:'Other Fuel',
         9:'Other Fuel',
         21:'Other Fuel',
         -2:'None'}

cooltype_dict = {1:'Central System',
                 2:'Window/wall Units',
                 3:'Both',
                 -2:'No A/C'}

equipage_dict = {1: '< 2 yrs',
               2: '2-4 yrs',
               3: '5-9 yrs',
               41:'10-14 yrs',
               42:'15-19 yrs',
               5: '20+ yrs',
               -2:'N/A'}

agecenac_dict = {1: '< 2 yrs',
               2: '2-4 yrs',
               3: '5-9 yrs',
               41:'10-14 yrs',
               42:'15-19 yrs',
               5: '20+ yrs',
               -2:'N/A'}

wwacage_dict = {1: '< 2 yrs',
               2: '2-4 yrs',
               3: '5-9 yrs',
               41:'10-14 yrs',
               42:'15-19 yrs',
               5: '20+ yrs',
               -2:'N/A'}

typeglass_dict = {1:'1 Pane',
                  2:'2+ Pane',
                  3:'2+ Pane',
                  -2:'No Windows'}
sizes = {500:'0-1499',
         1000:'0-1499',
         2000:'1500-2499',
         3000:'2500-3499',
         4000:'3500+',
         5000:'3500+',
         6000:'3500+',
         7000:'3500+',
         8000:'3500+',
         9000:'3500+',
         10000:'3500+'}

story_dict = {10:1,
              20:2,
              40:2,
              31:2,
              32:2}

income_range = {    1:'$2,500 and under',
                    2:'$2,500 to $4,999',
                    3:'$5,000 to $7,499',
                    4:'$7,500 to $9,999',
                    5:'$10,000 to $14,999',
                    6:'$15,000 to $19,999',
                    7:'$20,000 to $24,999',
                    8:'$25,000 to $29,999',
                    9:'$30,000 to $34,999',
                    10:'$35,000 to $39,999',
                    11:'$40,000 to $44,999',
                    12:'$45,000 to $49,999',
                    13:'$50,000 to $54,999',
                    14:'$55,000 to $59,999',
                    15:'$60,000 to $64,999',
                    16:'$65,000 to $69,999',
                    17:'$70,000 to $74,999',
                    18:'$75,000 to $79,999',
                    19:'$80,000 to $84,999',
                    20:'$85,000 to $89,999',
                    21:'$90,000 to $94,999',
                    22:'$95,000 to $99,999',
                    23:'$100,000 to $119,999',
                    24:'$120,000 or More'}

med_income ={1:1250,
             2:3250,
             3:6250,
             4:8750,
             5:12250,
             6:17250,
             7:22250,
             8:27250,
             9:32250,
             10:37250,
             11:42250,
             12:47250,
             13:52250,
             14:57250,
             15:62250,
             16:67250,
             17:72250,
             18:77250,
             19:82250,
             20:87250,
             21:92250,
             22:97250,
             23:110000,
             24:120000}

wall_type ={1:'Brick',
            2:'Wood',
            3:'Siding',
            4:'Stucco',
            5:'Composition',
            6:'Stone',
            7:'Concrete',
            8:'Glass',
            9:'Other'}

roof_type ={1:'Ceramic/Clay',
            2:'Wood Shingles/Shakes',
            3:'Metal',
            4:'Slate',
            5:'Composition Shingles',
            6:'Asphalt',
            7:'Concrete Tiles',
            8:'Other'}

fpl16 = {   1:11880,
            2:16020,
            3:20160,
            4:24300,
            5:28440,
            6:32580,
            7:36730,
            8:40890}

fpl09 = {   1:10830,
            2:14570,
            3:18310,
            4:22050,
            5:25790,
            6:29530,
            7:33270,
            8:37010}

census_div = {1:'New England Census Division (CT, MA, ME, NH, RI, VT)',
              2:'Middle Atlantic Census Division (NJ, NY, PA)',
              3:'East North Central Census Division (IL, IN, MI, OH, WI)',
              4:'West North Central Census Division (IA, KS, MN, MO, ND, NE, SD)',
              5:'South Atlantic  Census Division (DC, DE, FL, GA, MD, NC, SC, VA, WV)',
              6:'East South Central Census Division (AL, KY, MS, TN)',
              7:'West South Central Census Division (AR, LA, OK, TX)',
              8:'Mountain North Sub-Division (CO, ID, MT, UT, WY)',
              9:'Mountain South Sub-Division (AZ, NM, NV)',
              10:'Pacific Census Division (AK, CA, HI, OR, WA)' }

region_def = {1:3,
              2:3,
              3:7,
              4:7,
              5:7,
              6:4,
              7:4,
              8:4,
              9:2,
              10:2,
              11:8,
              12:8,
              13:8,
              14:8,
              15:9,
              16:9,
              17:9,
              18:9,
              19:8,
              20:9,
              21:9,
              22:5,
              23:5,
              24:10,
              25:10,
              26:11,
              27:6}

cr_str = {1:'CR01',
          2:'CR02',
          3:'CR03',
          4:'CR04',
          5:'CR05',
          6:'CR06',
          7:'CR07',
          8:'CR08',
          9:'CR09',
          10:'CR10',
          11:'CR11',
          12:'CR12'}
fpl = fpl09
heating_types = {    2: 'Steam or Hot Water System'        , #'Steam or Hot Water System',
                     3:    'Central Warm-Air Furnace'      , #'Central Warm-Air Furnace'      ,
                     4:    'Heat Pump'                     , #'Heat Pump'                     ,
                     5 :    'Built-In Electric Units'       , #'Built-In Electric Units'       ,
                     6 :    'Floor or Wall Pipeless Furnace', #'Floor or Wall Pipeless Furnace',
                     7 :    'Floor or Wall Pipeless Furnace', #'Built-In Room Heater'          ,
                     8 :    'Other Equipment'               , #'Heating Stove'                 ,
                     9 :    'Other Equipment'               , #'Fireplace'                     ,
                     10:    'Built-In Electric Units'       , #'Portable Electric Heaters'     ,
                     11: 'Other Equipment'               , #'Portable Kerosene Heaters'     ,
                     12:   'Other Equipment'               , #'Cooking Stove'                 ,
                     21:   'Other Equipment'               , #'Other Equipment'               ,
                     -2:   'Not Applicable'}                 #'Not Applicable'}
def retrieve_data():
    if not os.path.exists('eia.recs_2009_microdata.pkl'):
        con_string = "host = gispgdb.nrel.gov port = 5432 dbname = dav-gis user = jalley password = jalley"
        con =  con = pg.connect(con_string)
        sql = """SELECT *
                FROM eia.recs_2009_microdata;"""
        df = pd.read_sql(sql, con)
        df.to_pickle('eia.recs_2009_microdata.pkl')
    df = pd.read_pickle('eia.recs_2009_microdata.pkl')

    return df

def process_data(df):
#	df = pandas.read_csv(recs_data_file,na_values=['-2'])
    field_dicts = {'equipm': heating_types,
                   'division': census_div,
                   'stories': story_dict,
                   'cooltype': cooltype_dict,
                   'yearmaderange': vintages,
                   'fuelheat':fuels,
                   'fuelh2o':fuels,
                   'rngfuel':fuels,
                   'dryrfuel':fuels,
                   'equipage':equipage_dict,
                   'agecenac':agecenac_dict,
                   'wwacage':wwacage_dict,
                   'typeglass':typeglass_dict,
                   'householder_race':race_dict,
                   'education':education_dict}
    for field_name, field_dict in field_dicts.iteritems():
        for num, name in field_dict.iteritems():
            df[field_name].replace(num, name, inplace=True)

    df['Size'] = df[['tothsqft','totcsqft']].max(axis=1)
    df.loc[:,'Size'] = 0
    df.loc[(df['Size'] < 1500),'Size'] = '0-1499'
    df.loc[(df['Size'] >= 1500) & (df['Size'] < 2500),'Size'] = '1500-2499'
    df.loc[(df['Size'] >= 2500) & (df['Size'] < 3500),'Size'] = '2500-3499'
    df.loc[(df['Size'] >= 3500),'Size'] = '3500+'


    df['Count']=1
    return df

def assign_aliases(df):
    aliases = {'prkgplc1':'HasGarage'}
    return df.rename(columns=aliases)

def calc_temp_stats(df):
    df['athome'].replace(0,np.NaN)
    df['temphome']
    df['tempgone']
    df['tempnite']
    df['temphomeac']
    df['tempgoneac']
    df['tempniteac']
    T_avg = {}
    temp_hist = {}
    for season in ['Winter', 'Summer']:
        T_avg[season] = (df['athome']*df['Temp {} Day Home'.format(season)]*8 + (df['athome']==0)*df['Temp {} Day Away'.format(season)]*8 + df['Temp {} Day Home'.format(season)]*8 + df['Temp {} Night'.format(season)]*8) / 24.
        #    T_avg[season].hist(bins=range(40,97))
        #    plt.show()
        temp_hist[season] = pandas.np.histogram(T_avg[season],bins = range(40,97))
        #    do_plot(list(temp_hist[season][0]), list(temp_hist[season][1]), 'US')
    T_avg_weighted = {}
    for season in ['Winter', 'Summer']:
        T_avg_weighted[season] = sum(df['nweight'][T_avg[season].notnull()]*T_avg[season][T_avg[season].notnull()]) / (df['nweight'][T_avg[season].notnull()].sum()*1.0)
    print temp_hist

def calc_htg_type(df):
    heating_types = {2:   'Steam or Hot Water System'      ,
                    3 :   'Central Warm-Air Furnace'      ,
                    4 :   'Heat Pump'                     ,
                    5 :   'Built-In Electric Units'       ,
                    6 :   'Floor or Wall Pipeless Furnace',
                    7 :   'Built-In Room Heater'          ,
                    8 :   'Heating Stove'                 ,
                    9 :   'Fireplace'                     ,
                    10:   'Portable Electric Heaters'     ,
                    11:   'Portable Kerosene Heaters'     ,
                    12:   'Cooking Stove'                 ,
                    21:   'Other equipment'               ,
                    -2:   'Not Applicable'}
    cut_by = ['Custom Region']# ,'yearmaderange','Custom Region',
    df['fuelheat'].replace(2, 1, inplace=True) # Count Propane as Natural Gas for purposes of system type counting
    for fuel_num, fuel_name in fuels.iteritems():
        df['fuelheat'].replace(fuel_num,fuel_name, inplace=True)
        #df['equipm'].replace([7,8,9,11,12],21, inplace=True)
    df['equipm'].replace(pandas.np.nan, -2, inplace=True)
    grouped = df.groupby(cut_by)
    print ','.join(cut_by + heating_types.values())
    for name, group in grouped:
        checksum = 0
        vals = ''
        for htg_num, htg_name in heating_types.iteritems():
            val = group[group['equipm'] == htg_num]['nweight'].sum() * 1.0 / group['nweight'].sum()
            checksum += val
            vals += (',' + str(val))
        if checksum == 0:
            pass
        #    print ','.join([regions[name[0]], name[1], name[2]]) + vals
        print ','.join([str(name)]) + vals

def calc_htg_type_by_wh_fuel(df, cut_by=['fuelh2o','reportable_domain','yearmaderange','fuelheat'], outfile='output_calc_htg_type_by_wh_fuel.csv'):
    resultFyle = open(outfile,'wb')
    wr = csv.writer(resultFyle, dialect='excel')
    heating_types = {2:   'Steam or Hot Water System'      ,
                    3 :   'Central Warm-Air Furnace'      ,
                    4 :   'Heat Pump'                     ,
                    5 :   'Built-In Electric Units'       ,
                    6 :   'Floor or Wall Pipeless Furnace',
                    7 :   'Built-In Room Heater'          ,
                    8 :   'Heating Stove'                 ,
                    9 :   'Fireplace'                     ,
                    10:   'Portable Electric Heaters'     ,
                    11:   'Portable Kerosene Heaters'     ,
                    12:   'Cooking Stove'                 ,
                    21:   'Other Equipment'               ,
                    -2:   'Not Applicable'}
    for fuel_num, fuel_name in fuels.iteritems():
        df['fuelh2o'].replace(fuel_num,fuel_name, inplace=True)
        df['fuelheat'].replace(fuel_num,fuel_name, inplace=True)
    df['yearmaderange'].replace(['< 1950s', '1950s', '1960s', '1970s', '1980s'],'<=1980s', inplace=True)
    df['yearmaderange'].replace(['1990s', '2000s'],'>=1990s', inplace=True)
    df['equipm'].replace(pandas.np.nan, -2, inplace=True)
    grouped = df.groupby(cut_by)
    print ','.join(cut_by + heating_types.values() + ['Total'])
    wr.writerow(cut_by + heating_types.values())
    for name, group in grouped:
        checksum = 0
        vals = ''
        for htg_num, htg_name in heating_types.iteritems():
            val = group[group['equipm'] == htg_num]['nweight'].sum() / 100.0 # factor of 100 in data by mistake
            checksum += val
            vals += (',' + str(val))
        vals += (',' + str(group['nweight'].sum()/ 100.0)) # factor of 100 in data by mistake
        if checksum == 0:
            pass
        row = ','.join([str(x) for x in name]) + vals
        print row
        wr.writerow(row.split(','))

def calc_htg_age(df):
    ages = ['1', '3', '7', '12', '17', '25', '-1']
    heating_types = {    2: 'Steam or Hot Water System'        , #'Steam or Hot Water System',
                        3:    'Central Warm-Air Furnace'      , #'Central Warm-Air Furnace'      ,
                        4:    'Heat Pump'                     , #'Heat Pump'                     ,
                        5 :    'Built-In Electric Units'       , #'Built-In Electric Units'       ,
                        6 :    'Floor or Wall Pipeless Furnace', #'Floor or Wall Pipeless Furnace',
                        7 :    'Floor or Wall Pipeless Furnace', #'Built-In Room Heater'          ,
                        8 :    'Other Equipment'               , #'Heating Stove'                 ,
                        9 :    'Other Equipment'               , #'Fireplace'                     ,
                        10:    'Built-In Electric Units'       , #'Portable Electric Heaters'     ,
                        11: 'Other Equipment'               , #'Portable Kerosene Heaters'     ,
                        12:   'Other Equipment'               , #'Cooking Stove'                 ,
                        21:   'Other Equipment'               , #'Other Equipment'               ,
                        -2:   'Not Applicable'}                 #'Not Applicable'}
    cut_by = ['yearmaderange','fuelheat','equipm']
    df['fuelheat'].replace(2, 1, inplace=True) # Count Propane as Natural Gas for purposes of system type counting
    for fuel_num, fuel_name in fuels.iteritems():
        df['fuelheat'].replace(fuel_num,fuel_name, inplace=True)
    df['equipm'].replace(pandas.np.nan, -2, inplace=True)
    for num, name in heating_types.iteritems():
        df['equipm'].replace(num,name, inplace=True)
    grouped = df.groupby(cut_by)
    print ','.join(cut_by + ages)
    for name, group in grouped:
        checksum = 0
        vals = ''
        for age in ages:
            val = group[group['equipage'] == int(age)]['nweight'].sum() * 1.0 / group['nweight'].sum()
            checksum += val
            vals += (',' + str(val))
        if checksum == 0:
            pass
        print ','.join([name[0], name[1], name[2]]) + vals

# def calc_occupancy(df):
#     cut_by = ['Size']#,'Stories']
#     for num, name in stories.iteritems():
#         df['Stories'].replace(num,name, inplace=True)
#     for num, name in sizes.iteritems():
#         df['Size'].replace(num,name, inplace=True)
# #    df[df['Size'] == 0]['Size'] = df[df['Size'] == 0]['SizeExactTotal']
#     df['Size'].replace(0, pandas.np.nan, inplace=True)
#     df['Size'] = df['Size'].combine_first(df['SizeExactTotal'])
#     grouped = df.groupby(cut_by)
#     for name, group in grouped:
#         avg_occs = (group['NHSLDMEM'] * group['NWEIGHT'] * 1.0).sum() / group['NWEIGHT'].sum()
#         avg_baths = (group['NumBaths'] * group['NWEIGHT'] * 1.0).sum() / group['NWEIGHT'].sum()
#         avg_size = (group['Size'] * group['NWEIGHT'] * 1.0).sum() / group['NWEIGHT'].sum()
#         print ','.join([name, str(avg_occs), str(avg_baths), str(avg_size)])

def calc_ashp_cac(df):
    ashp_but_not_cac = df[(df['equipm'] == 4) & (df['cooltype'] != 1)]['nweight'].sum()*1.0 / df[(df['equipm'] == 4)]['nweight'].sum()
    print "ashp_but_not_cac - {:.3f}".format(ashp_but_not_cac)


#def agg_bedrooms(df):
#	br_replace_dict = {5:4}
#	for num, name in br_replace_dict.iteritems():
#		df['BEDROOMS'].replace(num,name, inplace=True)
#	return df

def calc_general(df, cut_by=['reportable_domain', 'fuelheat'], columns=None, outfile=None,norm=True):
    #Temp set 0 as NaN

#Use Dictionaries to Define Data


#Start Analyzing Specific Data
    fields = cut_by + columns
    grouped = df.groupby(fields)
    df.groupby(cut_by)['Count'].sum()
    combos = [list(set(df[field])) for field in fields]
    for i, combo in enumerate(combos):
        if pandas.np.nan in combo:
            x = pandas.np.array(combos[i])
            combos[i] = list(x)
    full_index = pandas.MultiIndex.from_product(combos, names=fields)

#Implement Total Weight of Each Type
    g = grouped.sum()
    g = g['nweight'].reindex(full_index)
    g = g.fillna(0).reset_index()
    g = pandas.pivot_table(g, values='nweight', index=cut_by, columns=columns).reset_index()
    Weight = g[g.columns[len(cut_by):]].sum(axis = 1)

#Implement Count of Each Type
    ct = grouped.sum()
    ct = ct['Count'].reindex(full_index)
    ct = ct.fillna(0).reset_index()
    ct = pandas.pivot_table(ct, values='Count', index=cut_by, columns=columns).reset_index()
    Count = ct[ct.columns[len(cut_by):]].sum(axis=1)    #only adds Options, not Dependencies

#Normalize Data
    if norm:
        total = g.sum(axis=1)
        if isinstance(g.columns, pandas.core.index.MultiIndex):
            for col in g.columns:
                if not col[0] in cut_by:
                    g[col] = g[col] / total
        else:
            for col in g.columns:
                if not col in cut_by:
                    g[col] = g[col] / total
    g['Weight']=Weight
    g['Count']=Count

#Add Headers for Option and Dependency
    rename_dict = {}
    for col in g.columns:
        if col in ['Weight','Count']:
            rename_dict[col] = str(col)
        else:
            rename_dict[col] = 'Option=' + str(col)
        if col in cut_by:
            rename_dict[col] = 'Dependency=' + str(col)
    g = g.rename(columns=rename_dict)

#Generate Outfile
    if not outfile is None:
        g.to_csv(os.path.join("Probability Distributions", outfile), sep = '\t',index=False)
        print g
    return g

def save_to_tsv(g, cut_by, columns, outfile):
    rename_dict = {}
    for col in g.columns:
        if col in cut_by:
            rename_dict[col] = 'Dependency=' + col
        if col in columns:
            rename_dict[col] = 'Option=' + col
    g = g.rename(columns=rename_dict)
    print g
    g.to_csv(outfile, sep='\t', index=False)

def query_stories(df, outfile='recs_query_stories.csv'):
    g = calc_general(df, cut_by=['yearmaderange','Size'],columns=['stories'], outfile=None)
    fnd_types = ['Crawl',
                 'Heated Basement',
                 'None',
                 'Slab',
                 'Unheated Basement']
    dfs = []
    for fnd_type in fnd_types:
        df2 = g.copy()
        df2['Foundation Type'] = fnd_type

        # Redistribute 1-story weighting factors if not heated basement
        if fnd_type != 'Heated Basement':
            df2.loc[df2['Size'] == '4500+', 2] += df2.loc[df2['Size'] == '4500+', 1]
            df2.loc[df2['Size'] == '4500+', 1] = 0
        dfs.append(df2)
    df = pandas.concat(dfs)
    df = df[['yearmaderange','Size','Foundation Type',1,2,3]]
    df.to_csv(outfile, index=False)
    print df

def assign_poverty_levels(df):
    df['income_range'] = df['moneypy']
    df['income'] = df['moneypy']
    for income_range_num, income_range_name in income_range.iteritems():
        df['income_range'].replace(income_range_num,income_range_name,inplace=True)
    for num, name in med_income.iteritems():
        df['income'].replace(num, name, inplace=True)
    inflation_2009_to_2016 = 1.125344
    df['inf_income']=df['income']*inflation_2009_to_2016

    df['incomelimit'] = df['nhsldmem']
    for fpl_num,fpl_name in fpl.iteritems():
        for field in ['incomelimit']:
            df[field].replace(fpl_num,fpl_name,inplace=True)
    df['FPL'] = df['income']/df['incomelimit']*100
    df['FPLALL'] = 1
    df['FPL300','FPL250','FPL200','FPL150','FPL100','FPL50'] = df['FPLALL']
    df.loc[(df['FPL'] <= 300),'FPL300'] = 1
    df.loc[(df['FPL'] <= 250),'FPL250'] = 1
    df.loc[(df['FPL'] <= 200),'FPL200'] = 1
    df.loc[(df['FPL'] <= 150),'FPL150'] = 1
    df.loc[(df['FPL'] <= 100),'FPL100'] = 1
    df.loc[(df['FPL'] <= 50),'FPL50'] = 1

    #Create FPL Bins
    df['FPL_BINS'] = 0
    df.loc[(df['FPL'] >= 300),'FPL_BINS'] = "300+"
    df.loc[(df['FPL'] >= 250) & (df['FPL'] < 300),'FPL_BINS'] = "250-300"
    df.loc[(df['FPL'] >= 200) & (df['FPL'] < 250),'FPL_BINS'] = "200-250"
    df.loc[(df['FPL'] >= 150) & (df['FPL'] < 200),'FPL_BINS'] = "150-200"
    df.loc[(df['FPL'] >= 100) & (df['FPL'] < 150),'FPL_BINS'] = "100-150"
    df.loc[(df['FPL'] >= 50) & (df['FPL'] < 100),'FPL_BINS'] = "50-100"
    df.loc[(df['FPL'] < 50),'FPL_BINS'] = "0-50"
    return df


def custom_region(df):
    df['CR'] = df['reportable_domain']
    df['CR'].replace(region_def, inplace=True)

# Split out Kentucky and put in 8:
    df.ix[(df['reportable_domain'] == 18) & (df['aia_zone'] == 3), 'CR'] = 8

# Split out Hawaii and put in 12:
    df.ix[(df['reportable_domain'] == 27) & ((df['aia_zone'] == 5) | (df['hdd65'] < 4000)), 'CR'] = 12

# Split out Alaska and put in 1:
    df.ix[(df['reportable_domain'] == 27) & (df['hdd65'] > 6930), 'CR'] = 1 #Source for 6930 HDD: Dennis Barley
    return df


if __name__ == '__main__':

#preallocate steps for speed. Delete pkl files if objects are changed

    if not os.path.exists('processed_eia.recs_2009_microdata.pkl'):
        df = retrieve_data()
        df = process_data(df)
        df = custom_region(df)
        df = assign_poverty_levels(df)
#        df = assign_aliases(df)
        df.to_pickle('processed_eia.recs_2009_microdata.pkl')
    else:
        df = pd.read_pickle('processed_eia.recs_2009_microdata.pkl')


#NEW QUERIES
#    calc_general(df, cut_by=['CR','FPL_BINS'], columns = ['yearmaderange'], outfile = 'output_calc_CR_FPL_by_vintage.tsv')
#    calc_general(df, cut_by=['CR','FPL_BINS','yearmaderange'], columns = ['equipm'], outfile = 'heatingequipment_output_by_CR_FPL_vintage.tsv')
#    calc_general(df, cut_by=['CR','FPL_BINS','yearmaderange'], columns = ['equipm'], outfile = 'heatingequipment_output_by_CR_FPL_vintage.tsv')
#    calc_general(df, cut_by=['CR','FPL_BINS','yearmaderange'], columns = ['fuelheat'], outfile = 'heatingfuel_output_by_CR_FPL_vintage.tsv')
#    calc_general(df, cut_by=['CR','FPL_BINS','yearmaderange'], columns = ['Size'], outfile = 'Size_output_by_CR_FPL_vintage.tsv')
#    calc_general(df, cut_by=['CR','FPL_BINS','yearmaderange'], columns = ['equipage'], outfile = 'heating_equipment_age_output_by_CR_FPL_vintage.tsv')
#    calc_general(df, cut_by=['CR','FPL_BINS','yearmaderange'], columns = ['cooltype'], outfile = 'AC_type_output_by_CR_FPL_vintage.tsv')
#    calc_general(df, cut_by=['CR','FPL_BINS','yearmaderange'], columns = ['agecenac'], outfile = 'Central-AC-Sys-Age_output_by_CR_FPL_vintage.tsv')
#    calc_general(df, cut_by=['CR','FPL_BINS','yearmaderange'], columns = ['wwacage'], outfile = 'Window-AC-Sys-Age_output_by_CR_FPL_vintage.tsv')
#    calc_general(df, cut_by=['CR','FPL_BINS','yearmaderange'], columns = ['temphome'], outfile = 'Temp-Winter-Home_output_by_CR_FPL_vintage.tsv')
#    calc_general(df, cut_by=['CR','FPL_BINS','yearmaderange'], columns = ['tempgone'], outfile = 'Temp-Winter-Gone_output_by_CR_FPL_vintage.tsv')
#    calc_general(df, cut_by=['CR','FPL_BINS','yearmaderange'], columns = ['tempnite'], outfile = 'Temp-Winter-Night_output_by_CR_FPL_vintage.tsv')
#    calc_general(df, cut_by=['CR','FPL_BINS','yearmaderange'], columns = ['temphomeac'], outfile = 'Temp-Summer-Home_output_by_CR_FPL_vintage.tsv')
#    calc_general(df, cut_by=['CR','FPL_BINS','yearmaderange'], columns = ['tempgoneac'], outfile = 'Temp-Summer-Gone_output_by_CR_FPL_vintage.tsv')
#    calc_general(df, cut_by=['CR','FPL_BINS','yearmaderange'], columns = ['tempniteac'], outfile = 'Temp-Summer-Night_output_by_CR_FPL_vintage.tsv')
#    calc_general(df, cut_by=['CR','FPL_BINS','yearmaderange'], columns = ['typeglass'], outfile = 'Window-Type_output_by_CR_FPL_vintage.tsv')
#    calc_general(df, cut_by=['CR','FPL_BINS','yearmaderange'], columns = ['nhsldmem'], outfile = 'Household-Occ-Num_output_by_CR_FPL_vintage.tsv')
#    calc_general(df, cut_by=['CR','FPL_BINS','yearmaderange'], columns = [''], outfile = '_output_by_CR_FPL_vintage.tsv')

#OLD QUERIES

   # Overwrite fuelheat Type field with UGWARM ('UGWARM') if discrepancy
#    df.loc[df['ugwarm'] == 1, 'fuelheat'] = 1
#    calc_temp_stats(df)
#     calc_htg_type(df)
#     calc_htg_age(df)
#     calc_htg_type_by_wh_fuel(df, cut_by=['fuelh2o','reportable_domain','yearmaderange','fuelheat'], outfile='output_calc_htg_type_by_wh_fuel_vintage.csv')
#     calc_htg_type_by_wh_fuel(df, cut_by=['fuelh2o','reportable_domain','fuelheat'], outfile='output_calc_htg_type_by_wh_fuel.csv')
#     calc_num_beds(df)
#     calc_ashp_cac(df)
#     calc_occupancy(df)
#    calc_general(df, cut_by=['Size','stories'],columns=['Foundation Type'], outfile='output_general.csv')
#     calc_general(df, cut_by=['division','yearmaderange'],columns=['Foundation Type'], outfile='output_general.csv')
#    calc_general(df, cut_by=['yearmaderange','Size'],columns=['PRKGPLC1'], outfile='output_general.csv')
    # Query Vintage
#     calc_general(df, cut_by=['reportable_domain'],columns=['yearmaderange'], outfile='output_house_counts_vintage.csv')
    # Query Fuel Types
#     calc_general(df, cut_by=['reportable_domain','yearmaderange'],columns=['fuelheat'], outfile='recs_query_heating_fuel.csv')
#     calc_general(df, cut_by=['fuelheat','Custom Region'],columns=['fuelh2o','H2OTYPE1'], outfile='recs_query_wh_fuel.csv')
#     calc_general(df, cut_by=['fuelheat','Custom Region'], columns=['rngfuel'], outfile='recs_query_range_fuel.csv')
#     calc_general(df, cut_by=['fuelheat','Custom Region'],columns=['dryrfuel'], outfile='recs_query_dryer_fuel.csv')
    # Query Size
#     calc_general(df, cut_by=['Custom Region','yearmaderange'],columns=['Size'], outfile='recs_query_size.csv')
#     calc_general(df, cut_by=['fuelh2o_agg'],columns=['Size'], outfile='output_size.csv', norm=False)
    # Query stories
#     query_stories(df)
#     calc_general(df, cut_by=[],columns=['ESCWASH'], outfile='output_cw.csv', norm=False)
#     calc_general(df, cut_by=[],columns=['ESDISHW'], outfile='output_dw.csv', norm=False)
#     calc_general(df, cut_by=[],columns=['ESFRIG'], outfile='output_ref.csv', norm=False)
#     calc_general(df, cut_by=[],columns=['Percent CFLs'], outfile='output_ltg.csv', norm=False)
#     calc_general(df, cut_by=['ESFRIG'],columns=['AGERFRI1'], outfile='output_ref_age.csv', norm=True)
#     calc_general(df, cut_by=['yearmaderange','Custom Region'],columns=['WALLTYPE'], outfile='output_wall.csv', norm=True)
#     calc_general(df, cut_by=['division'],columns=['WALLTYPE'], outfile='output_wall_div.csv', norm=True)
#     calc_general(df, cut_by=['yearmaderange','Custom Region'],columns=['ATTCHEAT'], outfile='output_ATTCHEAT.csv', norm=True)
#     calc_general(df, cut_by=['yearmaderange','Custom Region'],columns=['Vented Attic'], outfile='output_vented attic.csv', norm=True)
#     calc_general(df, cut_by=[],columns=['ATTCHEAT'], outfile='output_ATTCHEAT.csv', norm=False)
#     calc_general(df, cut_by=[],columns=['Vented Attic'], outfile='output_vented attic.csv', norm=False)
#     calc_general(df, cut_by=[],columns=['Finished Attic'], outfile='output_vented attic.csv', norm=False)
#     calc_general(df, cut_by=[],columns=['Cathedral Ceiling'], outfile='output_vented attic.csv', norm=False)
#     calc_general(df, cut_by=[],columns=['ATTIC'], outfile='output_vented attic.csv', norm=False)
#     df = agg_bedrooms(df)
#     calc_general(df, cut_by=['fuelh2o_agg','Bedrooms_agg'],columns=['Water Heater Size'], outfile='output_wh_size.csv', norm=False)
    # Generic Query
#     calc_general(df, cut_by=['reportable_domain'],columns=['ESCWASH'], outfile='output_general.csv')
# fuelheat house counts
#     df = calc_general(df, cut_by=['Custom Region','yearmaderange','fuelheat'],columns=[], outfile='output_heating_fuel.csv', norm=False)
#     df
#     df = calc_general(df, cut_by=['Custom Region'],columns=['fuelheat'], outfile='output_heating_fuel.csv', norm=True)
# df = calc_general(df, cut_by=[],columns=['athome'], outfile='output_athome.csv', norm=False)
#     calc_htg_type(df)
#     calc_general(df, cut_by=['fuelheat'],columns=['equipm'], outfile='recs_query_heating_type.csv', norm=False)

    print datetime.now() - startTime
