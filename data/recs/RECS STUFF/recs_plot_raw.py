# -*- coding: utf-8 -*-
"""
Created on Mon Sep 26 15:26:57 2016

@author: jalley
"""
import plotly.plotly as py
import plotly.graph_objs as go
import os, sys
import pandas as pd
import matplotlib.pyplot as plt
import csv
#from medoids_tstat import do_plot
import itertools
import numpy as np
from matplotlib.lines import Line2D
import seaborn as sns
from scipy import stats
from matplotlib.pyplot import show

from query_recs_raw import poverty, process_csv_data, calc_temp_stats,calc_htg_type, calc_htg_type_by_wh_fuel, calc_htg_age, calc_occupancy,calc_ashp_cac,assign_sizes,calc_general,query_stories

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
         '3500-4499' : 3,
         '4500+' : 4}

num_sizes = {0:'0-1499' ,
         1:'1500-2499' ,
         2:'2500-3499' ,
         3:'3500-4499' ,
         4:'4500+' }

income_range = {	1:'Less than $2,500',
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

income = {	1:1250,
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

fpl16 = {	1:11880,
			2:16020,
			3:20160,
			4:24300,
			5:28440,
			6:32580,
			7:36730,
			8:40890}

fpl09 = {	1:10830,
			2:14570,
			3:18310,
			4:22050,
			5:25790,
			6:29530,
			7:33270,
			8:37010}

fpl = fpl09

if __name__ == '__main__':
	df = process_csv_data()
	assign_sizes(df)



#JOINTPLOT

#	df1 = df1[PROB]=df1[1].where(df1[1]>0,other=0)
#	df = df[(df[PROB] >0)]

#	sns.jointplot(x=VAR1, y = VAR2, data = df, kind = "kde", joint_kws={'weights':'NWEIGHT'})
#	sns.jointplot(x=VAR1, y = VAR2, data = df, kind = "reg")
#	plt.title(TITLE)
#BARCHART
#	ax = plt.axes()
#	sns.barplot(x=VAR,y= 1, palette = 'Reds_d', data = df1)
#	ax.set_title(TITLE)
#	plt.show()

#STACKED BAR
	CUT = ['Size','FPL50','FPL100','FPL150','FPL200','FPL250','FPLALL']
#	df1 = calc_general(df, cut_by=[CUT],columns=[PROB], outfile='output_general.csv')

	cut_by = CUT
	grouped = df.groupby(cut_by, as_index=False).sum()
	grouped.index
	i = df.columns.size
#	while (i > -1):
	df1 = pandas.pivot_table(grouped, values = 'NWEIGHT', index = CUT, columns = ['Garage'])






















#Other calls



