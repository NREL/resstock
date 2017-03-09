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

story_dict = {8: 1,
              16: 2}

size_dict = {1000: '0-1499',
             2000: '1500-2499',
             3000: '2500-3499',
             4500: '3500+'}

vintage_dict = {1: 'Pre-1960s',
                2: '1970s',
                3: '1980s',
                4: '1990s',
                5: '2000s',
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

LoopTime = datetime.now()

n = 100

###### Create Dictionary & Dataframe of all possible values

x = {"Size": [1000, 2000, 3000, 4500], "yearmaderange": [1, 2, 3, 4, 5, 6], "WAP": [0, 1], "EE": [0, 1],
     "stories": [8, 16], "Region": [1, 2, 3, 4], "Climate_Zone": [1, 2, 3, 4, 5, 6, 7, 8], "Foundation Type": [1, 2, 3],
     "Duct": [1, 2, 3]}
df = pd.DataFrame(list(itertools.product(*x.values())), columns=x.keys())

###### Combinations that do not exist on Website

lh = {'Region': [1], 'Climate_Zone': [8]}
ld = {'Region': [2], 'Climate_Zone': [1, 7]}
lm = {'Region': [3], 'Climate_Zone': [1, 2, 5, 6, 7]}
la = {'Region': [4], 'Climate_Zone': [1, 2, 3, 4, 5, 6]}
lf = [lh, ld, lm, la]

###### Removal of non-existant combinations

for i in range(len(lf)):
    LF = lf[i]
    df = df.drop(df[df[list(LF)].isin(LF).all(axis=1)].index.tolist())

df = df.reset_index()
df = df.drop('index', axis=1)
df['p_dist'] = ""
df['c_dist'] = ""


###### Create URL and Query

def url(x):
    for i, row in x.iterrows():
        url = 'http://resdb.lbl.gov/main.php?step=2&sub=2&run_env_model=&dtype1=&dtype2=&is_ca=&calc_id=2&floor_area=' + str(
            row['Size']) + '&house_height=' + str(row['stories']) + '&year_built=' + str(
            row['yearmaderange']) + '&wap=' + str(row['WAP']) + '&ee_home=' + str(row['EE']) + '&region=' + str(
            row['Region']) + '&zone=' + str(row['Climate_Zone']) + '&foundation=' + str(
            row['Foundation Type']) + '&duct=' + str(row['Duct'])
        page = requests.get(url)
        m = re.search("'Prob Density', data: \[(.*)\]", page.text)
        n = re.search("'Cumulative Dist', data: \[(.*)\]", page.text)
        prob_density = m.group(1)
        c_dist = n.group(1)
        x.loc[(i, 'p_dist')] = prob_density
        x.loc[(i, 'c_dist')] = c_dist
        x['url'] = url
    return x


###### Call to Pull Data from LBNL

df1 = url(df)

###### Split Data into Cumulative Distributions and Probability Density Distributions
print 'data pulled'

P_Dist = df1.drop('c_dist', axis=1)
C_Dist = df1.drop('p_dist', axis=1)

###### Pull Coordinates into Unicode Lists of X & Y Values

P_Dist['x_vals'] = P_Dist.apply(lambda x: re.findall('(?<=\[)(.*?)(?=,)', x['p_dist']), axis=1)
P_Dist['y_vals'] = P_Dist.apply(lambda x: re.findall('(?<=\d,)(.+?)(?=\])', x['p_dist']), axis=1)
C_Dist['x_vals'] = C_Dist.apply(lambda x: re.findall('(?<=\[)(.*?)(?=,)', x['c_dist']), axis=1)
C_Dist['y_vals'] = C_Dist.apply(lambda x: re.findall('(?<=\d,)(.+?)(?=\])', x['c_dist']), axis=1)

###### Convert Unicode to Float for X & Y Values

P_Dist['x_vals'] = P_Dist.apply(lambda x: [float(unicode(x['x_vals'][i])) for i in range(len(x['x_vals']))], axis=1)
P_Dist['y_vals'] = P_Dist.apply(lambda x: [float(unicode(x['y_vals'][i])) for i in range(len(x['y_vals']))], axis=1)

C_Dist['x_vals'] = C_Dist.apply(lambda x: [float(unicode(x['x_vals'][i])) for i in range(len(x['x_vals']))], axis=1)
C_Dist['y_vals'] = C_Dist.apply(lambda x: [float(unicode(x['y_vals'][i])) for i in range(len(x['y_vals']))], axis=1)


###### Put Columns into RECS Format

def process_data(df):
    field_dicts = {'stories': story_dict,
                   'Foundation Type': foundation_dict,
                   'Duct': duct_dict,
                   'Size': size_dict,
                   'yearmaderange': vintage_dict,
                   'Region': region_dict}
    for field_name, field_dict in field_dicts.iteritems():
        for num, name in field_dict.iteritems():
            df.loc[:, field_name].replace(num, name, inplace=True)
    return df


####### Save Data to TSV

def save_to_tsv(g, outfile):
    g.to_csv(outfile, sep='\t', index=False)


####### Make Function Calls

P_Dist = process_data(P_Dist)
C_Dist = process_data(C_Dist)

save_to_tsv(P_Dist, outfile='LBNL_P_Dist.tsv')
save_to_tsv(C_Dist, outfile='LBNL_C_Dist.tsv')

###### Create Frequency Distribution & Distribution Table
print 'Create Frequency Distribution & Distribution Table'
df = pd.read_csv('LBNL_C_Dist.tsv', sep='\t')

C_Dist = df[0:n].copy()

C_Dist['y_vals'] = C_Dist.apply(lambda x: eval(x['y_vals']), axis=1)
C_Dist['x_vals'] = C_Dist.apply(lambda x: eval(x['x_vals']), axis=1)
C_Dist['Y_VALS'] = C_Dist['y_vals']

for i, row in C_Dist.iterrows():
    for k in range(len(row['Y_VALS'])):
        if k > 0:
            row['y_vals'][k] = float(row['Y_VALS'][k] - row['Y_VALS'][k - 1])
            if k == len(row['Y_VALS']) - 1:
                row['Cum_Max'] = row['Y_VALS'][k]


# Fill in P_Dist Values

def dict_zip(row):
    return dict(zip(row['x_vals'], row['y_vals']))


##### Create Additional Dataframe and Merge with Original

df1 = C_Dist[['x_vals', 'y_vals']].copy()
list_of_dicts = df1.apply(dict_zip, axis=1)
D_list = pd.DataFrame(list(list_of_dicts))

C_Dist = pd.concat([C_Dist, D_list], axis=1)
C_Dist = C_Dist.replace(np.NaN, 0)

save_to_tsv(C_Dist, outfile='LBNL_FRQ_Dist.tsv')

total = (datetime.now() - LoopTime).total_seconds() * (31104 / n)
print "Expected Time:" + str(timedelta(seconds=total))
