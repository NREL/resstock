# -*- coding: utf-8 -*-
"""
Created on Thu Mar 23 15:13:24 2017

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
import seaborn as sns
import matplotlib.pyplot as plt
import random
from ast import literal_eval
sns.set(font_scale=1.25)


######## Save Data to TSV

def save_to_tsv(g, outfile):
    g.to_csv(outfile, sep='\t', index=False)

df = pd.read_csv('LBNL_FRQ_Dist.tsv', sep='\t')
#wap = df.groupby(['Climate_Zone','WAP'])['Mean','Var'].mean()
#wap['Stddev'] = np.sqrt(wap['Var'])
#plt.figure()
#ax = sns.boxplot(x=df['Climate_Zone'], y=df['Mean'], hue = df['WAP'],palette="muted")
#ax.set(xlabel='Climate Zone',ylabel='ACH50 Value',title = 'Infiltration')
#plt.figure()
#ax = sns.violinplot(x=df['Climate_Zone'], y=df['Mean'], hue = df['WAP'],palette="muted")
#ax.set(xlabel='Climate Zone',ylabel='ACH50 Value',title = 'Infiltration')

#####TEMPORARY-Create List of X and Y Values for plotting
#df_val = df[df.columns[11:-2]].copy()
#x_val = df.columns.tolist()[11:-4]
#x_val = [float(i) for i in x_val]
#df['x_vals'] = [x_val] * len(df)
#df['Y_VALS'] = df_val[df_val.columns[1:]].apply(lambda x: ','.join(x.dropna().astype(float).astype(str)),axis=1)
#df['Y_VALS'] = df.apply(lambda x: literal_eval(x['Y_VALS']),axis = 1)
#####60's and 70's

df1 = df.loc[df['yearmaderange'] == '1970s'].copy().reset_index()
df2 = df.loc[df['yearmaderange'] == '1980s'].copy().reset_index()

frames = [df1,df2]
df_new = pd.concat(frames)

columns = df.columns.tolist()[:11]
columns.remove('yearmaderange')

df_new = df_new.sort_values(by = columns, ascending = True).reset_index()


#Generate Plots

n = random.randint(0, .5*len(df_new))
for i in range(3):
    n = random.randint(0, .5*len(df_new))
    plt.figure()
    y_val = list(df.loc[df.index[2*n],'Y_VALS'])
    ax = sns.pointplot(x_val,y_val)
    sns.pointplot(x=x_val, y = df[df.index[2*n-1]])