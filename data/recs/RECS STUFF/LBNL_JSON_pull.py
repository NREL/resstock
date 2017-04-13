# -*- coding: utf-8 -*-
"""
Created on Thu Feb 09 11:27:26 2017

@author: jalley
"""
from __future__ import division
import csv
import requests
import lxml
from lxml import etree
import re
from datetime import datetime
from datetime import timedelta
import pandas as pd
import itertools
import numpy as np
from ast import literal_eval
import random
import matplotlib.pyplot as plt

story_dict = {8: 1,
              16: 2}

size_dict = {1000: '0-1499',
             2000: '1500-2499',
             3000: '2500-3499',
             4500: '3500+'}

vintage_dict = {1: 'Pre-1960s',
                2: '1960s',
                3: '1970s',
                4: '1980s',
                5: '1990s',
                6: '2000s'}

region_dict = {1: 'Humid',
               2: 'Dry',
               3: 'Marine',
               4: 'Alaska'}

foundation_dict = {1: 'Slab',
                   2: 'Conditioned Basement or Unvented Crawlspace',
                   3: 'Unconditioned Basement or Vented Crawlspace'}

duct_dict = {1: 'Inside conditioned space',
             2: 'Attic or basement (unconditioned)',
             3: 'Vented crawlspace'}


######## Save Data to TSV

def save_to_tsv(g, outfile):
    g.to_csv(outfile, sep='\t', index=False)

####### Create Dictionary & Dataframe of all possible values

#x = {"Size": [1000, 2000, 3000, 4500], "yearmaderange": [1, 2, 3, 4, 5, 6], "WAP": [0, 1], "EE": [0, 1],
#     "stories": [8, 16], "Region": [1, 2, 3, 4], "Climate_Zone": [1, 2, 3, 4, 5, 6, 7, 8], "Foundation Type": [1, 2, 3],
#     "Duct": [1, 2, 3]}
#df = pd.DataFrame(list(itertools.product(*x.values())), columns=x.keys())
#
####### Combinations that do not exist on Website
#
#lh = {'Region': [1], 'Climate_Zone': [8]}
#ld = {'Region': [2], 'Climate_Zone': [1, 7]}
#lm = {'Region': [3], 'Climate_Zone': [1, 2, 5, 6, 7]}
#la = {'Region': [4], 'Climate_Zone': [1, 2, 3, 4, 5, 6]}
#lf = [lh, ld, lm, la]
#
######## Removal of non-existant combinations
#
#for i in range(len(lf)):
#    LF = lf[i]
#    df = df.drop(df[df[list(LF)].isin(LF).all(axis=1)].index.tolist())
#
#df = df.reset_index()
#df = df.drop('index', axis=1)
#df['p_dist'] = ""
#df['c_dist'] = ""
#
#
######## Create URL and Query
#
#def url(x):
#    for i, row in x.iterrows():
#        url = 'http://resdb.lbl.gov/main.php?step=2&sub=2&run_env_model=&dtype1=&dtype2=&is_ca=&calc_id=2&floor_area=' + str(
#            row['Size']) + '&house_height=' + str(row['stories']) + '&year_built=' + str(
#            row['yearmaderange']) + '&wap=' + str(row['WAP']) + '&ee_home=' + str(row['EE']) + '&region=' + str(
#            row['Region']) + '&zone=' + str(row['Climate_Zone']) + '&foundation=' + str(
#            row['Foundation Type']) + '&duct=' + str(row['Duct'])
#        page = requests.get(url)
#        m = re.search("'Prob Density', data: \[(.*)\]", page.text)
#        n = re.search("'Cumulative Dist', data: \[(.*)\]", page.text)
#        prob_density = m.group(1)
#        c_dist = n.group(1)
#        x.loc[(i, 'p_dist')] = prob_density
#        x.loc[(i, 'c_dist')] = c_dist
#        x['url'] = url
#        print str(i)
#    return x
#
#
######## Call to Pull Data from LBNL
#
#df1 = url(df)
#save_to_tsv(df1, outfile='ORIGINAL_LBNL.tsv')
#
######## Split Data into Cumulative Distributions and Probability Density Distributions
#
#P_Dist = df1.drop('c_dist', axis=1)
#C_Dist = df1.drop('p_dist', axis=1)
#
######## Pull Coordinates into Unicode Lists of X & Y Values
#
#P_Dist['x_vals'] = P_Dist.apply(lambda x: re.findall('(?<=\[)(.*?)(?=,)', x['p_dist']), axis=1)
#P_Dist['y_vals'] = P_Dist.apply(lambda x: re.findall('(?<=\d,)(.+?)(?=\])', x['p_dist']), axis=1)
#C_Dist['x_vals'] = C_Dist.apply(lambda x: re.findall('(?<=\[)(.*?)(?=,)', x['c_dist']), axis=1)
#C_Dist['y_vals'] = C_Dist.apply(lambda x: re.findall('(?<=\d,)(.+?)(?=\])', x['c_dist']), axis=1)
#
######## Convert Unicode to Float for X & Y Values
#
#P_Dist['x_vals'] = P_Dist.apply(lambda x: [float(unicode(x['x_vals'][i])) for i in range(len(x['x_vals']))], axis=1)
#P_Dist['y_vals'] = P_Dist.apply(lambda x: [float(unicode(x['y_vals'][i])) for i in range(len(x['y_vals']))], axis=1)
#
#C_Dist['x_vals'] = C_Dist.apply(lambda x: [float(unicode(x['x_vals'][i])) for i in range(len(x['x_vals']))], axis=1)
#C_Dist['y_vals'] = C_Dist.apply(lambda x: [float(unicode(x['y_vals'][i])) for i in range(len(x['y_vals']))], axis=1)
#
#
######## Put Columns into RECS Format
#
#def process_data(df):
#    field_dicts = {'stories': story_dict,
#                   'Foundation Type': foundation_dict,
#                   'Duct': duct_dict,
#                   'Size': size_dict,
#                   'yearmaderange': vintage_dict,
#                   'Region': region_dict}
#    for field_name, field_dict in field_dicts.iteritems():
#        for num, name in field_dict.iteritems():
#            df.loc[:, field_name].replace(num, name, inplace=True)
#    return df
#
######## Make Function Calls
#
#P_Dist = process_data(P_Dist)
#C_Dist = process_data(C_Dist)
#
#save_to_tsv(P_Dist, outfile='LBNL_P_Dist.tsv')
#save_to_tsv(C_Dist, outfile='LBNL_C_Dist.tsv')


####### Create Frequency Distribution & Distribution Table
#
#df = pd.read_csv('LBNL_C_Dist.tsv', sep='\t')
#
#C_Dist = df.copy()
#
#C_Dist['Y_VALS'] = C_Dist['y_vals'].copy()
#C_Dist['y_vals'] = C_Dist.apply(lambda x: eval(x['y_vals']), axis=1)
#C_Dist['x_vals'] = C_Dist.apply(lambda x: eval(x['x_vals']), axis=1)
#C_Dist['Y_VALS'] = C_Dist.apply(lambda x: eval(x['Y_VALS']), axis=1)
#C_Dist['Cum_Max'] =  C_Dist.apply(lambda x: max(x['Y_VALS']), axis =1)
#
#
#for i, row in C_Dist.iterrows():
#    for k in range(len(row['Y_VALS'])):
#        if k > 0:
#            row['y_vals'][k] = float(row['Y_VALS'][k]) - float(row['Y_VALS'][k - 1])
#            if k == len(row['Y_VALS'])-1:
#                row['y_vals'][k] = float(row['y_vals'][k]) + (1-float(row['Cum_Max']))
#    print str(i)
### Fill in P_Dist Values / Generate Mean and Var
#
#def dict_zip(row):
#    return dict(zip(row['x_vals'], row['y_vals']))
#
#def mean(x,y):
#    u = 0
#    for i in range(len(x)):
#        u += float(y[i])*float(x[i])
#    return u
#
#def var(x,y):
#    u = 0
#    u2 = 0
#    for i in range(len(x)):
#        u += float(y[i])*float(x[i])
#        u2 += float(y[i])*(float(x[i])**2)
#    return u2-u**2
#
#
##### Create Additional Dataframe and Merge with Original
#
#df1 = C_Dist[['x_vals', 'y_vals']].copy()
#list_of_dicts = df1.apply(dict_zip, axis=1)
#D_list = pd.DataFrame(list(list_of_dicts))
#C_Dist = pd.concat([C_Dist, D_list], axis=1)
#C_Dist = C_Dist.replace(np.NaN, 0)
#C_Dist['Mean'] =  C_Dist.apply(lambda x: mean(x['x_vals'],x['y_vals']), axis =1)
#C_Dist['Var'] = C_Dist.apply(lambda x: var(x['x_vals'],x['y_vals']), axis=1)
#C_Dist = C_Dist.drop(['c_dist'],axis=1)
#save_to_tsv(C_Dist, outfile='LBNL_FRQ_Dist.tsv')

##### Bin Different Columns together
#df_1 = increments by 1
#df_2 = increments by 2

df = pd.read_csv('LBNL_FRQ_Dist.tsv', sep='\t')

#Bin by every 1

df_1 = pd.DataFrame()
x = df.columns.tolist()[14:-2]
x5 = x[:19]
x1 = x[19:]
for i in range((len(x5)//2)):
    header = str((float(x5[2*i]) + float(x5[2*i+1]))/2)
    print header
    df_1[header] = df[x5[2*i]]+df[x5[2*i+1]]
for i in x1:
    df_1[i] = df[i]

#Create New Dataframe

df_col = df[df.columns[:9]]
df1 = df_col.join(df_1)
x_val = df_1.columns.tolist()
x_val = [float(i) for i in x_val]
df1['y_vals'] = df_1[df_1.columns[0:]].apply(lambda x: ','.join(x.dropna().astype(float).astype(str)),axis=1)
df1['y_vals'] = df1.apply(lambda x: literal_eval(x['y_vals']),axis = 1)
df1['x_vals'] = [x_val] * len(df_1)
#Bin by every 2

x = df_1.columns.tolist()
df_2 = pd.DataFrame()
for i in range(len(x)//2):
    header = str((float(x[2*i]) + float(x[2*i+1]))/2)
    print header
    df_2[header] = df1[x[2*i]]+df1[x[2*i+1]]


x_val = df_2.columns.tolist()
x_val = [float(i) for i in x_val]
df_2['y_vals'] = df_2[df_2.columns[0:]].apply(lambda x: ','.join(x.dropna().astype(float).astype(str)),axis=1)
df_2['y_vals'] = df_2.apply(lambda x: list(x['y_vals']),axis = 1)
df_2['x_vals'] = [x_val] * len(df_2)
df2 = df_col.join(df_2)
save_to_tsv(df_2, outfile='LBNL_FRQ_Dist_Bin2.tsv')

#####Plots of binned vs unbinned

for i in range(3):
    n = random.randint(0, .5*len(df1))
    plt.figure()
    x_val1 = df1.loc[df1.index[n],'x_vals']
    x_val2 = df1.loc[df2.index[n],'x_vals']
    y_val1 = df1.loc[df1.index[n],'y_vals']
    y_val2 = df2.loc[df2.index[n],'y_vals']
    plt.plot(x_val1,y_val1,':b',label = 'Bin1',linewidth=3)
    plt.plot(x_val2,y_val2,'--r',label = 'Bin2',linewidth=3)
    plt.legend();