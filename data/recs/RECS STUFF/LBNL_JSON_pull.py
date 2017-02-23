# -*- coding: utf-8 -*-
"""
Created on Thu Feb 09 11:27:26 2017

@author: jalley
"""
import csv
import requests
import lxml
from lxml import etree
import re
from datetime import datetime
from datetime import timedelta
import pandas as pd
import itertools

###### Original test of loop

#LoopTime = datetime.now()
#for i in range(5):
#    url = "http://resdb.lbl.gov/main.php?step=2&sub=2&run_env_model=&dtype1=&dtype2=&is_ca=&calc_id=2&floor_area=1500&house_height=8&year_built=1&wap=0&ee_home=0&region=2&zone=1&foundation=1&duct=1.html"
#    try:
#        page = requests.get(url)
#        re.search("data: \[(.*)\]",page.text)
#    finally:
#        print ""
#
#
#print "Loop:" + str(datetime.now() - LoopTime)



###### Create Dictionary of all possible values

x = {"Floor_Area":[1000,2000,3000,4500],"Vintage":[1,2,3,4,5,6],"WAP":[0,1],"EE":[0,1],"Stories":[8,16],"Region":[1,2,3,4],"Climate_Zone":[1,2,3,4,5,6,7,8],"Foundation_Type":[1,2,3],"Duct":[1,2,3]}
df = pd.DataFrame(list(itertools.product(*x.values())),columns=x.keys())

###### Combinations that do not exist on Website

lh = {'Region':[1],'Climate_Zone':[8]}
ld = {'Region':[2],'Climate_Zone':[1,7]}
lm = {'Region':[3],'Climate_Zone':[1,2,5,6,7]}
la = {'Region':[4],'Climate_Zone':[1,2,3,4,5,6]}
lf = [lh,ld,lm,la]

###### Removal of non-existant combinations

for i in range(len(lf)):
    LF = lf[i]
    df = df.drop(df[df[list(LF)].isin(LF).all(axis=1)].index.tolist())

df = df.reset_index()
df = df.drop('index',axis=1)
df['Coordinates']='.'
df['URL']=""
df['p_dist']=""
df['c_dist'] = ""

###### Create URL and Query

LoopTime = datetime.now()

def url(x):
    Y = []
    CLIMATE = x[x.columns[0]].tolist()
    FOUNDATION = x[x.columns[1]].tolist()
    STORIES = x[x.columns[2]].tolist()
    FLOOR_AREA = x[x.columns[3]].tolist()
    EE = x[x.columns[4]].tolist()
    VINTAGE = x[x.columns[5]].tolist()
    REGION = x[x.columns[6]].tolist()
    DUCT = x[x.columns[7]].tolist()
    WAP = x[x.columns[8]].tolist()
    for i in range(len(EE)):
        url = 'http://resdb.lbl.gov/main.php?step=2&sub=2&run_env_model=&dtype1=&dtype2=&is_ca=&calc_id=2&floor_area='+str(FLOOR_AREA[i])+'&house_height='+str(STORIES[0])+'&year_built='+str(VINTAGE[i])+'&wap='+str(WAP[i])+'&ee_home='+str(EE[i])+'&region='+str(REGION[i])+'&zone='+str(CLIMATE[i])+'&foundation='+str(FOUNDATION[i])+'&duct='+str(DUCT[i])+'.html'
        page = requests.get(url)
        m = re.search("'Prob Density', data: \[(.*)\]",page.text)
#        n = re.search("'Cumulative Dist', data: \[(.*)\]",page.text)
        prob_density = m.group(1)
#        c_dist = n.group(1)
        x.loc[(i,'p_dist')] = prob_density
#        x.loc[(i,'c_dist')]= c_dist
    return x

###### Start Test Loop Time


###### Start Call

n = 20

df1 = url(df[0:n])

###### Split Strings into Coordinates

P_Dist = df1.drop('c_dist', axis=1)
#C_Dist = df1.drop('p_dist',axis=1)
#
P_Dist['p_dist_cords'] = P_Dist.apply(lambda x: re.split('(?<!\d)[,](?!\d)',x['p_dist']),axis=1)
#C_Dist['c_dist_cords'] = C_Dist.apply(lambda x: re.split('(?<!\d)[,](?!\d)',x['c_dist']),axis=1)
#

###### Pull First Coordinate and Compare to Column Values


y = re.search('(?<=\[)(.*)(?=,)',l[i])



for i in P_Dist['p_dist_cords']:

###


####### Save Data to TSV
#
#def save_to_tsv(g, outfile):
#    g.to_csv(outfile, sep='\t', index=False)
#
#
#
#save_to_tsv(P_Dist,outfile = 'LBNL_P_Dist.tsv')
#save_to_tsv(C_Dist,outfile = 'LBNL_C_Dist.tsv')















time = datetime.now() - LoopTime

total = time.total_seconds()*(len(df)/n)
print "Loop:" + str(time)
print "Expected Time:" + str(timedelta(seconds= total))



