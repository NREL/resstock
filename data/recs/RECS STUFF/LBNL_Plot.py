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
sns.set(font_scale=1.25)

df = pd.read_csv('LBNL_FRQ_Dist.tsv', sep='\t')
wap = df.groupby(['Climate_Zone','WAP'])['Mean','Var'].mean()
wap['Stddev'] = np.sqrt(wap['Var'])
plt.figure()
ax = sns.boxplot(x=df['Climate_Zone'], y=df['Mean'], hue = df['WAP'],palette="muted")
ax.set(xlabel='Climate Zone',ylabel='ACH50 Value',title = 'Infiltration')
plt.figure()
ax = sns.violinplot(x=df['Climate_Zone'], y=df['Mean'], hue = df['WAP'],palette="muted")
ax.set(xlabel='Climate Zone',ylabel='ACH50 Value',title = 'Infiltration')
