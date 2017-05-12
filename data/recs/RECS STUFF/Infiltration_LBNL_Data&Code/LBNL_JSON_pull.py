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
import os, sys
sys.path.insert(0, os.path.join(os.getcwd(),'clustering'))
import re
from datetime import datetime
from datetime import timedelta
import pandas as pd
import itertools
import numpy as np
from ast import literal_eval
import random
import matplotlib.pyplot as plt
import itertools as it
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

climate_dict = {'Humid':'A',
                'Dry':'B',
                'Marine':'C',
                'Alaska':'D'}

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



###Collapse Rows

def collapse(df,col_name,var1,var2,new_name):
    print 'Rows Before Collapsing of',var1,'&',var2,':',len(df.index)
    df1 = df.loc[df[col_name] == var1].copy().reset_index(drop=True)
    df2 = df.loc[df[col_name] == var2].copy().reset_index(drop=True)
    df = df.drop(df.loc[df[col_name]==var1].index)
    df = df.drop(df.loc[df[col_name]==var2].index)
    val_list = df1.columns.tolist()[15:]
    col_list = df1.columns.tolist()[:15]
    headers = col_list + val_list
    df3 = (df1[val_list]+df2[val_list])/2
    frames = [df1[col_list],df3]
    df4 = pd.concat(frames,axis=1)
    df4[col_name] = new_name
    df = df.append(df4)
    df = df[headers]
    print 'Rows After Collapsing of',var1,'&',var2,':',len(df.index)
    df.reset_index(drop=True)
    return df
#
#df = pd.read_csv('LBNL_FRQ_Dist.tsv', sep='\t')
#df = collapse(df,'yearmaderange','1960s','1970s','1960/70s')
#df = collapse(df,'Foundation Type','Unconditioned Basement or Vented Crawlspace','Conditioned Basement or Unvented Crawlspace','Basement or Crawlspace')
#save_to_tsv(df, outfile='LBNL_FRQ_Dist_Collapsed.tsv')
#
#df = pd.read_csv('LBNL_FRQ_Dist_Collapsed.tsv', sep='\t')
#
#df_1 = pd.DataFrame()
#x = ['0.5', '1.0', '1.5', '2.0', '2.5', '3.0', '3.5', '4.0', '4.5', '5.0', '5.5',
#     '6.0', '6.5', '7.0', '7.5', '8.0', '8.5', '9.0', '9.5', '10.0', '11.0', '12.0',
#     '13.0', '14.0', '15.0', '16.0', '17.0', '18.0', '19.0', '20.0', '21.0', '22.0',
#     '23.0', '24.0', '25.0', '26.0', '27.0', '28.0', '29.0', '30.0', '31.0', '32.0',
#     '33.0', '34.0', '35.0', '36.0', '37.0', '38.0', '39.0', '40.0', '41.0', '42.0',
#     '43.0', '44.0', '45.0', '46.0', '47.0', '48.0', '49.0', '50.0']
#x5 = x[:19]
#x1 = x[19:]
#for i in range((len(x5)//2)):
#    header = str((float(x5[2*i]) + float(x5[2*i+1]))/2)
#    print header
#    df_1[header] = df[x5[2*i]]+df[x5[2*i+1]]
#for i in x1:
#    df_1[i] = df[i]
#df_col = df[['Duct', 'stories', 'Climate_Zone', 'Foundation Type', 'EE', 'Region', 'WAP', 'yearmaderange', 'Size', 'url','x_vals','y_vals']]
#df_col = df_col.reset_index(drop=True)
#df_1 = df_1.reset_index(drop=True)
#df1 = df_col.join(df_1)
#x_val = df_1.columns.tolist()
#x_val = [float(i) for i in x_val]
#df1['y_vals'] = df_1[df_1.columns[0:]].apply(lambda x: ','.join(x.dropna().astype(float).astype(str)),axis=1)
#df1['y_vals'] = df1.apply(lambda x: literal_eval(x['y_vals']),axis = 1)
#df1['y_vals'] = df1.apply(lambda x: list(x['y_vals']),axis = 1)
#df1['x_vals'] = [x_val] * len(df_1)
#
#
#save_to_tsv(df1, outfile='LBNL_FRQ_Dist_Bin1.tsv')
#print('done binning by 1')




###Bin by every 2
##
#x = df_1.columns.tolist()
#df_2 = pd.DataFrame()
#for i in range(len(x)//2):
#    header = str((float(x[2*i]) + float(x[2*i+1])+1)/2)
#    print header
#    df_2[header] = (df1[x[2*i]]+df1[x[2*i+1]])/2
#
#
#x_val = df_2.columns.tolist()
#x_val = [float(i) for i in x_val]
#df_2 = df_2.reset_index(drop=True)
#df2 = df_col.join(df_2)
#df2['y_vals'] = df_2[df_2.columns[0:]].apply(lambda x: ','.join(x.dropna().astype(float).astype(str)),axis=1)
#df2['y_vals'] = df2.apply(lambda x: literal_eval(x['y_vals']),axis = 1)
#df2['y_vals'] = df2.apply(lambda x: list(x['y_vals']),axis = 1)
#df2['x_vals'] = [x_val] * len(df_2)
#
##df['Y_VALS'] = df_val[df_val.columns[1:]].apply(lambda x: ','.join(x.dropna().astype(float).astype(str)),axis=1)
##df['Y_VALS'] = df.apply(lambda x: literal_eval(x['Y_VALS']),axis = 1)
#save_to_tsv(df2, outfile='LBNL_FRQ_Dist_Bin2.tsv')
#print('Done binning by 2')


####Binning Alg

def binning_alg(width,df_1,df1, df_col):
    x = df_1.columns.tolist()
    df_n = pd.DataFrame()
    for i in range((len(x)//width)):
        v=0
        val = 0
        for j in range(width):
            if (width*i+j) < len(x):
                v += float(x[width*i+j])
                header = str((v)/(j+1))
                val += df1[x[width*i+j]]
        df_n[header] = (val)/(width)
        print i,header
    x_val = df_n.columns.tolist()
    x_val = [float(i) for i in x_val]
    df_n = df_n.reset_index(drop=True)
    dfn = df_col.join(df_n)
    dfn['y_vals'] = df_n[df_n.columns[0:]].apply(lambda x: ','.join(x.dropna().astype(float).astype(str)),axis=1)
    dfn['y_vals'] = dfn.apply(lambda x: literal_eval(x['y_vals']),axis = 1)
    dfn['y_vals'] = dfn.apply(lambda x: list(x['y_vals']),axis = 1)
    dfn['x_vals'] = [x_val] * len(df_n)
    save_to_tsv(dfn, outfile='Infiltration_LBNL_FRQ_Dist_Bin'+str(width)+'.tsv')
    print 'done binning by',width
    return dfn


####Bin by 2


df1 =pd.read_csv('Infiltration_LBNL_FRQ_Dist_Bin1.tsv',sep ='\t')
df_col = df1[['Duct', 'stories', 'Climate_Zone', 'Foundation Type', 'EE', 'Region',
             'WAP', 'yearmaderange', 'Size', 'url','x_vals','y_vals']]

x = ['0.75', '1.75', '2.75', '3.75', '4.75', '5.75', '6.75', '7.75', '8.75', '10.0', '11.0', '12.0', '13.0', '14.0', '15.0', '16.0', '17.0', '18.0', '19.0', '20.0', '21.0', '22.0', '23.0', '24.0', '25.0', '26.0', '27.0', '28.0', '29.0', '30.0', '31.0', '32.0', '33.0', '34.0', '35.0', '36.0', '37.0', '38.0', '39.0', '40.0', '41.0', '42.0', '43.0', '44.0', '45.0', '46.0', '47.0', '48.0', '49.0', '50.0']
df_1 = df1[x]
df2 = binning_alg(2,df_1,df1,df_col)
df3 = binning_alg(3,df_1,df1,df_col)
df4 = binning_alg(4,df_1,df1,df_col)

#####Plots of binned vs unbinned
print 'Plots'
df1 = pd.read_csv('Infiltration_LBNL_FRQ_Dist_Bin1.tsv', sep='\t')
df2 = pd.read_csv('Infiltration_LBNL_FRQ_Dist_Bin2.tsv', sep='\t')
df3 = pd.read_csv('Infiltration_LBNL_FRQ_Dist_Bin3.tsv', sep='\t')
df4 = pd.read_csv('Infiltration_LBNL_FRQ_Dist_Bin4.tsv', sep='\t')

for i in range(10):
    n = random.randint(0, .5*len(df1))
    plt.figure()

    x_val1 = literal_eval(df1.loc[df1.index[n],'x_vals'])
    x_val2 = literal_eval(df2.loc[df2.index[n],'x_vals'])
    x_val3 = literal_eval(df3.loc[df3.index[n],'x_vals'])
    x_val4 = literal_eval(df4.loc[df4.index[n],'x_vals'])

    y_val1 = literal_eval(df1.loc[df1.index[n],'y_vals'])
    y_val2 = literal_eval(df2.loc[df2.index[n],'y_vals'])
    y_val3 = literal_eval(df3.loc[df3.index[n],'y_vals'])
    y_val4 = literal_eval(df4.loc[df4.index[n],'y_vals'])

    plt.plot(x_val1,y_val1,':b',label = 'Bin1',linewidth=4)
    plt.plot(x_val2,y_val2,'--r',label = 'Bin2',linewidth=4)
    plt.plot(x_val3,y_val3,'-*g',label = 'Bin3',linewidth=2)
    plt.plot(x_val4,y_val4,'-.y',label = 'Bin4',linewidth=4)
    plt.xlabel('ACH50 Value')
    plt.ylabel('Probability Density')
    plt.legend();

#####Create TSV's

def calc_general(df, cut_by, columns=None, outfile=None,norm=True,outpath="Probability Distributions"):

    #Start Analyzing Specific Data
    fields = cut_by + columns
    grouped = df.groupby(fields)
    df.groupby(cut_by)['Count'].sum()
    combos = [list(set(df[field])) for field in fields]
    for i, combo in enumerate(combos):
        if pd.np.nan in combo:
            x = pd.np.array(combos[i])
            combos[i] = list(x)
    full_index = pd.MultiIndex.from_product(combos, names=fields)

    #Implement Total Weight of Each Type
    g = grouped.sum()
    g = g['nweight'].reindex(full_index)
    g = g.fillna(0).reset_index()
    g = pd.pivot_table(g, values='nweight', index=cut_by, columns=columns).reset_index()
    Weight = g[g.columns[len(cut_by):]].sum(axis = 1)

    #Implement Count of Each Type
    ct = grouped.sum()
    ct = ct['Count'].reindex(full_index)
    ct = ct.fillna(0).reset_index()
    ct = pd.pivot_table(ct, values='Count', index=cut_by, columns=columns).reset_index()
    Count = ct[ct.columns[len(cut_by):]].sum(axis=1)    #only adds Options, not Dependencies

    #Normalize Data
    if norm:
        total = g.sum(axis=1)
        if isinstance(g.columns, pd.core.index.MultiIndex):
            for col in g.columns:
                if not col[0] in cut_by:
                    g[col] = g[col] / total
        else:
            for col in g.columns:
                if not col in cut_by:
                    g[col] = g[col] / total
    g['Count']=Count
    g['Weight']=Weight

    #Rename columns
    cut_by = [x.replace('yearmaderange', 'Vintage') for x in cut_by]
    cut_by = [x.replace('Size', 'Geometry House Size') for x in cut_by]

    g = g.rename(columns={'yearmaderange': 'Vintage', 'Size': 'Geometry House Size'})
    #Rename rows
    if 'Vintage' in g.columns:
        g['Vintage'] = g['Vintage'].replace({'pre-1960s': '<1960'})

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
        g.to_csv(os.path.join(outpath, outfile), sep='\t', index=False)
        print g
    return g


#####Combine IECC Region and Climate Zone
#df = pd.read_csv('Infiltration_LBNL_FRQ_Dist_Bin2.tsv', sep='\t')
#
#field_dicts = {'Region':climate_dict}
#for field_name, field_dict in field_dicts.iteritems():
#    for num, name in field_dict.iteritems():
#        df.loc[:, field_name].replace(num, name, inplace=True)
#
#df['Climate Zone'] = df['Climate Zone'].map(str)+df['Region']
#df = df.drop(['Region']

#####Create TSV in format of Dependency-Option:

def tsv_outfile(g, cut_by, columns, outfile):
    rename_dict = {}
    for col in g.columns:
        if col in cut_by:
            rename_dict[col] = 'Dependency=' + col
        if col in columns:
            rename_dict[col] = 'Option=' + col
    g = g.rename(columns=rename_dict)
    print g
    g.to_csv(outfile, sep='\t', index=False)
    return

#columns = ['1.25', '3.25', '5.25', '7.25', '9.375', '11.5', '13.5', '15.5', '17.5', '19.5', '21.5', '23.5', '25.5', '27.5', '29.5', '31.5', '33.5', '35.5', '37.5', '39.5', '41.5', '43.5', '45.5', '47.5', '49.5']
#cut_by = ['Duct', 'Stories', 'IECC Region', 'Foundation Type', 'EE', 'WAP', 'yearmaderange', 'Size', 'url', 'x_vals', 'y_vals']
#
#tsv_outfile(df, cut_by, columns,'LBNL Infiltration.tsv')
