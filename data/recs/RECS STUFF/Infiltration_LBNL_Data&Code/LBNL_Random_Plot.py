# -*- coding: utf-8 -*-
"""
Created on Thu Mar 23 15:13:24 2017

This randomly plots two variable that you wish to collapse and compares them. For instance
1960s and 1970s housing

@author: jalley
"""
from __future__ import division
import ast
from lxml import etree
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

df = pd.read_csv('Infiltration_LBNL_FRQ_Dist.tsv', sep='\t')
#wap = df.groupby(['Climate_Zone','WAP'])['Mean','Var'].mean()
#wap['Stddev'] = np.sqrt(wap['Var'])
#plt.figure()
#ax = sns.boxplot(x=df['Climate_Zone'], y=df['Mean'], hue = df['WAP'],palette="muted")
#ax.set(xlabel='Climate Zone',ylabel='ACH50 Value',title = 'Infiltration')
#plt.figure()
#ax = sns.violinplot(x=df['Climate_Zone'], y=df['Mean'], hue = df['WAP'],palette="muted")
#ax.set(xlabel='Climate Zone',ylabel='ACH50 Value',title = 'Infiltration')

#####60's and 70's
def rand_plots(df,col_name,var1,var2):
    df1 = df.loc[df[col_name] == var1].copy().reset_index()
    df2 = df.loc[df[col_name] == var2].copy().reset_index()

    frames = [df1,df2]
    df_new = pd.concat(frames)

    columns = df.columns.tolist()[:9]
    columns.remove(col_name)

    df_new = df_new.sort_values(by = columns, ascending = True).reset_index()


#Generate Plots

    n = random.randint(0, .5*len(df_new))
    for i in range(5):
        n = random.randint(0, .5*len(df_new))
        plt.figure()
        x_val1 = ast.literal_eval(df_new.loc[df_new.index[2*n],'x_vals'])
        y_val1 = ast.literal_eval(df_new.loc[df_new.index[2*n],'y_vals'])
        x_val2 = ast.literal_eval(df_new.loc[df_new.index[2*n+1],'x_vals'])
        y_val2 = ast.literal_eval(df_new.loc[df_new.index[2*n+1],'y_vals'])
        plt.plot(x_val1,y_val1,':b',label = var1,linewidth=3)
        plt.plot(x_val2,y_val2,'--r',label = var2,linewidth=3)
        plt.legend();
        plt.xlabel('ACH50')
        title = "House Specs: "
        count = 0
        for i in columns:
            title += str(i)+': '+str(df_new.loc[df_new.index[2*n],i])+" "
            if count/4 == 1:
                title += '\n'
            count += 1
        plt.title(title)

#rand_plots(df,'yearmaderange','1960s','1970s')
rand_plots(df,'Foundation Type','Unconditioned Basement or Vented Crawlspace','Conditioned Basement or Unvented Crawlspace')
#rand_plots(df,'Climate_Zone',6,7)


