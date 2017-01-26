# -*- coding: utf-8 -*-
"""
Created on Mon Sep 26 15:26:57 2016

@author: jalley
"""
from __future__ import division
import plotly.plotly as py
import plotly.graph_objs as go
import pandas
import pandas as pd
import csv
import itertools
import numpy as np
from matplotlib.lines import Line2D
from scipy import stats
from matplotlib.pyplot import show
from colour import Color
import os, sys
import seaborn as sns
import matplotlib.pyplot as plt

import query_recs_raw_sql as recs


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

vintages = {'pre-1950' : 0,
            '1950s' : 1,
            '1960s' : 2,
            '1970s' : 3,
            '1980s' : 4,
            '1990s' : 5,
            '2000s' : 6}

num_vintages = {0 : 'pre-1950',
                1:'1950s' ,
                2:'1960s' ,
                3:'1970s' ,
                4:'1980s' ,
                5:'1990s' ,
                6:'2000s' }

sizes = {'0-1499' : 0,
         '1500-2499' : 1,
         '2500-3499' : 2,
         '3500+' : 3}

num_sizes = {0:'0-1499' ,
             1:'1500-2499' ,
             2:'2500-3499' ,
             3:'3500+'}

income_range = {1:'Less than $2,500',
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

med_income = {  1:1250,
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
                24:120000 }

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

fpl = fpl09

def calc_general(df, cut_by=['reportable_domain', 'fuelheat'], columns=None, outfile=None,norm=True):

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

#    if 'Foundation Type' in columns:
#        g['Weight'] = Weight / df['numfoundations']
#        g['Count'] = Count / df['numfoundations']

#Add Headers for Option and Dependency -- Turned Off For Graphs

    rename_dict = {}
    for col in g.columns:
        if col in ['Weight','Count']:
            rename_dict[col] = str(col)
        else:
            rename_dict[col] = 'Option=' + str(col)
        if col in cut_by:
            rename_dict[col] = 'Dependency=' + str(col)
    g = g.rename(columns=rename_dict)

#Generate Outfile -- Turned Off For Graphs

#    if not outfile is None:
#        g.to_csv(os.path.join("Probability Distributions", outfile), sep = '\t',index=False)
#        print g
    return g

def stackedbar(df, VAR, TITLE, NORM):
    #Set up cut by different FPL levels

    CUT = ['FPLALL','FPL250','FPL200','FPL150','FPL100','FPL50']
    i = len(CUT)

    #Colors for plot gradient

    colors = sns.color_palette("GnBu", i)

    #Loop to plot different poverty levels
    plt.figure()
    for j in range(len(CUT)):
        POV = CUT[j]
        df1 = calc_general(df, cut_by=[VAR],columns=[POV], norm = NORM)
        ax = sns.barplot(x = df1['Dependency=' + VAR], y = df1['Option=1'], color = colors[j])

   #Save and label
    ax.set_xlabel(VAR + " of Home", fontsize = 13.5)
    ax.set_ylabel("Distribution of Homes According to Income", fontsize = 12)
    ax.set_title(TITLE, fontsize = 15)
    fig = ax.get_figure()
    file_name = VAR+'_pov_lvls_V2.png'
    fig.savefig(os.path.join('Graphs',file_name), bbox_inches = 'tight')
    print fig

def kdeplot(df, VAR1, VAR2, TITLE):

    #removes values of 0 from the dataset
    temp_set = ['athome','temphome','tempgone','tempnite','temphomeac','tempgoneac','tempniteac']
    if VAR2 in temp_set:
        df1 = df[df[VAR2] !=0]
    else:
        df1 = df
    ax = sns.jointplot(x=VAR1, y = VAR2, data = df1, kind = "kde", joint_kws={'weights':'nweight'})
    ax.savefig(VAR1 +" vs. "+ VAR2 +'_kde .png', bbox_inches = 'tight')

def regenerate():

    # Use this to regenerate processed data if changes are made to any of the classes below

    df = retrieve_data()
    df = process_data(df)
    df = custom_region(df)
    df = assign_poverty_levels(df)
    df = foundation_type(df)
    df.to_pickle('processed_eia.recs_2009_microdata.pkl')
    return df

def plot(df):

#    stackedbar(df,'equipm', 'Heating Equipment' + ' vs. Federal Poverty Levels: 250,200,150,100,50_V2')
#    stackedbar(df,'fuelheat', 'Heating Fuel' + ' vs. Federal Poverty Levels: 250,200,150,100,50_V2')
#    stackedbar(df,'division', 'Census Division' + ' vs. Federal Poverty Levels: 250,200,150,100,50_V2')
#    stackedbar(df,'Size', 'House Size' + ' vs. Federal Poverty Levels: 250,200,150,100,50_V2',True)	#Percentage
#    stackedbar(df,'Size', 'House Size' + ' vs. Federal Poverty Levels: 250,200,150,100,50_V2',False)	#Distribution
#    stackedbar(df,'yearmaderange', 'Vintage' + ' vs. Federal Poverty Levels: 250,200,150,100,50_V2',True)		#Percentage
#    stackedbar(df,'yearmaderange', 'Vintage' + ' vs. Federal Poverty Levels: 250,200,150,100,50_V2',False)		#Distribution
#    stackedbar(df,'equipm', 'Heating Type' + ' vs. Federal Poverty Levels: 250,200,150,100,50_V2',True)	#Percentage
#    stackedbar(df,'equipm', 'Heating Type' + ' vs. Federal Poverty Levels: 250,200,150,100,50_V2',False)	#Distribution
#    stackedbar(df,'equipage', 'Heating System Age' + ' vs. Federal Poverty Levels: 250,200,150,100,50_V2',True)
#    stackedbar(df,'equipage', 'Heating System Age' + ' vs. Federal Poverty Levels: 250,200,150,100,50_V2',False)
#    stackedbar(df,'cooltype', 'A/C Type' + ' vs. Federal Poverty Levels: 250,200,150,100,50_V2',True)
#    stackedbar(df,'cooltype', 'A/C Type' + ' vs. Federal Poverty Levels: 250,200,150,100,50_V2',False)
#    stackedbar(df,'agecenac', 'Central A/C System Age' + ' vs. Federal Poverty Levels: 250,200,150,100,50_V2',True)
#    stackedbar(df,'agecenac', 'Central A/C System Age' + ' vs. Federal Poverty Levels: 250,200,150,100,50_V2',False)
#    stackedbar(df,'wwacage', 'Window A/C Unit Age' + ' vs. Federal Poverty Levels: 250,200,150,100,50_V2',True)
#    stackedbar(df,'wwacage', 'Window A/C Unit Age' + ' vs. Federal Poverty Levels: 250,200,150,100,50_V2',False)
#    stackedbar(df,'fuelheat', 'Heating Fuel' + ' vs. Federal Poverty Levels: 250,200,150,100,50_V2',False)
#    stackedbar(df,'division', 'Census Division' + ' vs. Federal Poverty Levels: 250,200,150,100,50_V2',False)
#    stackedbar(df,'householder_race', 'Householder Race' +' vs. Weighted Federal Poverty Levels: 250,200,150,100,50_V2',False)
#    stackedbar(df,'householder_race', 'Householder Race' +' vs. Proportional Federal Poverty Levels: 250,200,150,100,50_V2',True)
#    kdeplot(df,'income', 'temphome', 'Day Thermostat Temp When Home (Winter)_V2')
#    kdeplot(df,'income', 'tempgone', 'Day Thermostat Temp When Gone(Winter)_V2')
#    kdeplot(df,'income', 'tempnite', 'Night Thermostat Temp (Winter)_V2')
#    kdeplot(df,'income', 'temphomeac', 'Day Thermostat Temp When Home (Summer)_V2')
#    kdeplot(df,'income', 'tempgoneac', 'Day Thermostat Temp When Gone(Summer)_V2')
#    kdeplot(df,'income', 'tempniteac', 'Night Thermostat Temp (Winter)_V2')
    kdeplot(df,'rand_income', 'tothsqft', 'Night Thermostat Temp (Winter)_V2')
    print datetime.now() - startTime

if __name__ == '__main__':
    #Choose regerate if you want to redo the processed pkl file, otherwise comment out

#    df = regenerate()

    df = pd.read_pickle('processed_eia.recs_2009_microdata.pkl')
    plot(df)






    print datetime.now() - startTime

