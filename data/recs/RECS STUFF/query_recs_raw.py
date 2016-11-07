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
recs_data_file = os.path.join("..", "RECS STUFF", "recs2009_public.csv")
import statsmodels.api as sm

regions = {1:'CR01',
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
         pandas.np.NaN:'None'}

sizes = {500:'0-1499',
         1000:'0-1499',
         2000:'1500-2499',
         3000:'2500-3499',
         4000:'3500-4499',
         5000:'4500+',
         6000:'4500+',
         7000:'4500+',
         8000:'4500+',
         9000:'4500+',
         10000:'4500+'}

stories = {10:1,
           20:2,
           40:2,
           31:3,
           32:3}

income_range = {	1:'$2,500 and under',
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

med_income ={	1:1250,
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

wall_type ={ 	1:'Brick',
				2:'Wood',
				3:'Siding',
				4:'Stucco',
				5:'Composition',
				6:'Stone',
				7:'Concrete',
				8:'Glass',
				9:'Other'}

roof_type ={	1:'Ceramic/Clay',
				2:'Wood Shingles/Shakes',
				3:'Metal',
				4:'Slate',
				5:'Composition Shingles',
				6:'Asphalt',
				7:'Concrete Tiles',
				8:'Other'}

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

def process_csv_data():
	df = pandas.read_csv(recs_data_file,na_values=['-2'])
	for vint_num, vint_name in vintages.iteritems():
		df['YEARMADERANGE'].replace(vint_num,vint_name, inplace=True)
	return df

def calc_temp_stats(df):
	df['ATHOME']
	df['TEMPHOME']
	df['TEMPGONE']
	df['TEMPNITE']
	df['TEMPHOMEAC']
	df['TEMPGONEAC']
	df['TEMPNITEAC']
	T_avg = {}
	temp_hist = {}
	for season in ['Winter', 'Summer']:
		T_avg[season] = (df['ATHOME']*df['Temp {} Day Home'.format(season)]*8 + (df['ATHOME']==0)*df['Temp {} Day Away'.format(season)]*8 + df['Temp {} Day Home'.format(season)]*8 + df['Temp {} Night'.format(season)]*8) / 24.
		#	T_avg[season].hist(bins=range(40,97))
		#	plt.show()
		temp_hist[season] = pandas.np.histogram(T_avg[season],bins = range(40,97))
		#	do_plot(list(temp_hist[season][0]), list(temp_hist[season][1]), 'US')
	T_avg_weighted = {}
	for season in ['Winter', 'Summer']:
		T_avg_weighted[season] = sum(df['NWEIGHT'][T_avg[season].notnull()]*T_avg[season][T_avg[season].notnull()]) / (df['NWEIGHT'][T_avg[season].notnull()].sum()*1.0)
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
                    21:   'Other Equipment'               ,
                    -2:   'Not Applicable'}
	cut_by = ['Custom Region']# ,'YEARMADERANGE','Custom Region',
	df['FUELHEAT'].replace(2, 1, inplace=True) # Count Propane as Natural Gas for purposes of system type counting
	for fuel_num, fuel_name in fuels.iteritems():
		df['FUELHEAT'].replace(fuel_num,fuel_name, inplace=True)
		#df['EQUIPM'].replace([7,8,9,11,12],21, inplace=True)
	df['EQUIPM'].replace(pandas.np.nan, -2, inplace=True)
	grouped = df.groupby(cut_by)
	print ','.join(cut_by + heating_types.values())
	for name, group in grouped:
		checksum = 0
		vals = ''
		for htg_num, htg_name in heating_types.iteritems():
			val = group[group['EQUIPM'] == htg_num]['NWEIGHT'].sum() * 1.0 / group['NWEIGHT'].sum()
			checksum += val
			vals += (',' + str(val))
		if checksum == 0:
			pass
		#	print ','.join([regions[name[0]], name[1], name[2]]) + vals
		print ','.join([str(name)]) + vals

def calc_htg_type_by_wh_fuel(df, cut_by=['FUELH2O','REPORTABLE_DOMAIN','YEARMADERANGE','FUELHEAT'], outfile='output_calc_htg_type_by_wh_fuel.csv'):
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
		df['FUELH2O'].replace(fuel_num,fuel_name, inplace=True)
		df['FUELHEAT'].replace(fuel_num,fuel_name, inplace=True)
	df['YEARMADERANGE'].replace(['< 1950s', '1950s', '1960s', '1970s', '1980s'],'<=1980s', inplace=True)
	df['YEARMADERANGE'].replace(['1990s', '2000s'],'>=1990s', inplace=True)
	df['EQUIPM'].replace(pandas.np.nan, -2, inplace=True)
	grouped = df.groupby(cut_by)
	print ','.join(cut_by + heating_types.values() + ['Total'])
	wr.writerow(cut_by + heating_types.values())
	for name, group in grouped:
		checksum = 0
		vals = ''
		for htg_num, htg_name in heating_types.iteritems():
			val = group[group['EQUIPM'] == htg_num]['NWEIGHT'].sum() / 100.0 # factor of 100 in data by mistake
			checksum += val
			vals += (',' + str(val))
		vals += (',' + str(group['NWEIGHT'].sum()/ 100.0)) # factor of 100 in data by mistake
		if checksum == 0:
			pass
		row = ','.join([str(x) for x in name]) + vals
		print row
		wr.writerow(row.split(','))

def calc_htg_age(df):
	ages = ['1', '3', '7', '12', '17', '25', '-1']
	heating_types = {	2: 'Steam or Hot Water System'		, #'Steam or Hot Water System',
						3:	'Central Warm-Air Furnace'      , #'Central Warm-Air Furnace'      ,
						4:	'Heat Pump'                     , #'Heat Pump'                     ,
						5 :	'Built-In Electric Units'       , #'Built-In Electric Units'       ,
						6 :	'Floor or Wall Pipeless Furnace', #'Floor or Wall Pipeless Furnace',
						7 :	'Floor or Wall Pipeless Furnace', #'Built-In Room Heater'          ,
						8 :	'Other Equipment'               , #'Heating Stove'                 ,
						9 :	'Other Equipment'               , #'Fireplace'                     ,
						10:	'Built-In Electric Units'       , #'Portable Electric Heaters'     ,
						11: 'Other Equipment'               , #'Portable Kerosene Heaters'     ,
						12:   'Other Equipment'               , #'Cooking Stove'                 ,
						21:   'Other Equipment'               , #'Other Equipment'               ,
						-2:   'Not Applicable'}                 #'Not Applicable'}
	cut_by = ['YEARMADERANGE','FUELHEAT','EQUIPM']
	df['FUELHEAT'].replace(2, 1, inplace=True) # Count Propane as Natural Gas for purposes of system type counting
	for fuel_num, fuel_name in fuels.iteritems():
		df['FUELHEAT'].replace(fuel_num,fuel_name, inplace=True)
	df['EQUIPM'].replace(pandas.np.nan, -2, inplace=True)
	for num, name in heating_types.iteritems():
		df['EQUIPM'].replace(num,name, inplace=True)
	grouped = df.groupby(cut_by)
	print ','.join(cut_by + ages)
	for name, group in grouped:
		checksum = 0
		vals = ''
		for age in ages:
			val = group[group['EQUIPAGE'] == int(age)]['NWEIGHT'].sum() * 1.0 / group['NWEIGHT'].sum()
			checksum += val
			vals += (',' + str(val))
		if checksum == 0:
			pass
		print ','.join([name[0], name[1], name[2]]) + vals

def calc_occupancy(df):
	cut_by = ['Size']#,'Stories']
	for num, name in stories.iteritems():
		df['Stories'].replace(num,name, inplace=True)
	for num, name in sizes.iteritems():
		df['Size'].replace(num,name, inplace=True)
#	df[df['SizeMaxHeatCool'] == 0]['SizeMaxHeatCool'] = df[df['SizeMaxHeatCool'] == 0]['SizeExactTotal']
	df['SizeMaxHeatCool'].replace(0, pandas.np.nan, inplace=True)
	df['SizeMaxHeatCool'] = df['SizeMaxHeatCool'].combine_first(df['SizeExactTotal'])
	grouped = df.groupby(cut_by)
	for name, group in grouped:
		avg_occs = (group['NHSLDMEM'] * group['NWEIGHT'] * 1.0).sum() / group['NWEIGHT'].sum()
		avg_baths = (group['NumBaths'] * group['NWEIGHT'] * 1.0).sum() / group['NWEIGHT'].sum()
		avg_size = (group['SizeMaxHeatCool'] * group['NWEIGHT'] * 1.0).sum() / group['NWEIGHT'].sum()
		print ','.join([name, str(avg_occs), str(avg_baths), str(avg_size)])

def calc_ashp_cac(df):
	ashp_but_not_cac = df[(df['EQUIPM'] == 4) & (df['COOLTYPE'] != 1)]['NWEIGHT'].sum()*1.0 / df[(df['EQUIPM'] == 4)]['NWEIGHT'].sum()
	print "ashp_but_not_cac - {:.3f}".format(ashp_but_not_cac)

def assign_sizes(df):
	df['SizeMaxHeatCool'] = df[['TOTHSQFT','TOTCSQFT']].max(axis=1)
	df['Size'] = df['SizeMaxHeatCool']
	size_field = 'SizeMaxHeatCool'
	df.loc[:,'Size'] = pandas.np.nan
	df.loc[(df[size_field] < 1500),'Size'] = '0-1499'
	df.loc[(df[size_field] >= 1500) & (df[size_field] < 2500),'Size'] = '1500-2499'
	df.loc[(df[size_field] >= 2500) & (df[size_field] < 3500),'Size'] = '2500-3499'
	df.loc[(df[size_field] >= 3500) & (df[size_field] < 4500),'Size'] = '3500-4499'
	df.loc[(df[size_field] >= 4500),'Size'] = '4500+'
	return df

#def agg_bedrooms(df):
#	br_replace_dict = {5:4}
#	for num, name in br_replace_dict.iteritems():
#		df['BEDROOMS'].replace(num,name, inplace=True)
#	return df

def calc_general(df, cut_by=['REPORTABLE_DOMAIN','FUELHEAT'], columns=None, outfile=None,norm=True):
	fuels_list = ['Natural Gas','Propane/LPG','Fuel Oil','Electricity','Other Fuel']
	for fuel_num, fuel_name in fuels.iteritems():
		for field in ['FUELHEAT','FUELH2O','RNGFUEL','DRYRFUEL']:
			df[field].replace(fuel_num,fuel_name, inplace=True)

	if 'Stories' in cut_by or 'Stories' in columns:
		for num, name in stories.iteritems():
			df['Stories'].replace(num,name, inplace=True)
	fields = cut_by + columns
	grouped = df.groupby(cut_by + columns)
	df = grouped.sum().reset_index()
	combos = [list(set(df[field])) for field in fields]
	for i, combo in enumerate(combos):
		if pandas.np.nan in combo:
			x = pandas.np.array(combos[i])
			x = x[~pandas.np.isnan(x)]
			combos[i] = list(x)
	full_index = pandas.MultiIndex.from_product(combos, names=fields)
	g = grouped.sum()
	g = g['NWEIGHT'].reindex(full_index)
	g = g.fillna(0).reset_index()
	g = pandas.pivot_table(g, values='NWEIGHT', index=cut_by, columns=columns).reset_index()
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
	if not outfile is None:
		g.to_csv(outfile, index=False)
		print g
	return g

def query_stories(df, outfile='recs_query_stories.csv'):
	g = calc_general(df, cut_by=['YEARMADERANGE','Size'],columns=['Stories'], outfile=None)
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
	df = df[['YEARMADERANGE','Size','Foundation Type',1,2,3]]
	df.to_csv(outfile, index=False)
	print df

def poverty(df):
	df['INCOME_RANGE'] = df['MONEYPY']
	df['INCOME'] = df['MONEYPY']
	for income_range_num, income_range_name in income_range.iteritems():
		df['INCOME_RANGE'].replace(income_range_num,income_range_name,inplace=True)
	for num, name in med_income.iteritems():
		df['INCOME'].replace(num,name,inplace=True)
	#INFLATION
	df['INF_INCOME']=df['INCOME']*1.125344
	#FPL
	df['INCOMELIMIT'] = df['NHSLDMEM']
	for fpl_num,fpl_name in fpl.iteritems():
		for field in ['INCOMELIMIT']:
			df[field].replace(fpl_num,fpl_name,inplace=True)
	df['FPL'] = df['INCOME']
	df['FPL'] = df['INCOME']/df['INCOMELIMIT']*100
	df['FPL250','FPL200','FPL150','FPL100','FPL50'] = 0

	fpl_field = 'FPL'
	df.loc[(df[fpl_field] <= 250),'FPL250'] = 1
	df.loc[(df[fpl_field] <= 200),'FPL200'] = 1
	df.loc[(df[fpl_field] <= 150),'FPL150'] = 1
	df.loc[(df[fpl_field] <= 100),'FPL100'] = 1
	df.loc[(df[fpl_field] <= 50),'FPL50'] = 1
	df['FPL250'].fillna(value=0)
	df['FPL200'].fillna(value=0)
	df['FPL150'].fillna(value=0)
	df['FPL100'].fillna(value=0)
	df['FPL50'].fillna(value=0)
	df['FPLALL'] = df['FPL']
	df['FPLALL'] = 1
	#end code
	return df
if __name__ == '__main__':
    df = process_csv_data()
    assign_sizes(df)
    # Overwrite FUELHEAT Type field with UGWARM ('UGWARM') if discrepancy
#    df.loc[df['UGWARM'] == 1, 'FUELHEAT'] = 1
#     calc_temp_stats(df)
#     calc_htg_type(df)
#     calc_htg_age(df)
#     calc_htg_type_by_wh_fuel(df, cut_by=['FUELH2O','REPORTABLE_DOMAIN','YEARMADERANGE','FUELHEAT'], outfile='output_calc_htg_type_by_wh_fuel_vintage.csv')
#     calc_htg_type_by_wh_fuel(df, cut_by=['FUELH2O','REPORTABLE_DOMAIN','FUELHEAT'], outfile='output_calc_htg_type_by_wh_fuel.csv')
#     calc_num_beds(df)
#     calc_ashp_cac(df)
#     calc_occupancy(df)
#     calc_general(df, cut_by=['Size','Stories'],columns=['Foundation Type'], outfile='output_general.csv')
#     calc_general(df, cut_by=['DIVISION','YEARMADERANGE'],columns=['Foundation Type'], outfile='output_general.csv')
#    calc_general(df, cut_by=['YEARMADERANGE','Size'],columns=['PRKGPLC1'], outfile='output_general.csv')
    # Query Vintage
#     calc_general(df, cut_by=['REPORTABLE_DOMAIN'],columns=['YEARMADERANGE'], outfile='output_house_counts_vintage.csv')
    # Query Fuel Types
#     calc_general(df, cut_by=['REPORTABLE_DOMAIN','YEARMADERANGE'],columns=['FUELHEAT'], outfile='recs_query_heating_fuel.csv')
#     calc_general(df, cut_by=['FUELHEAT','Custom Region'],columns=['FUELH2O','H2OTYPE1'], outfile='recs_query_wh_fuel.csv')
#     calc_general(df, cut_by=['FUELHEAT','Custom Region'], columns=['RNGFUEL'], outfile='recs_query_range_fuel.csv')
#     calc_general(df, cut_by=['FUELHEAT','Custom Region'],columns=['DRYRFUEL'], outfile='recs_query_dryer_fuel.csv')
    # Query Size
#     calc_general(df, cut_by=['Custom Region','YEARMADERANGE'],columns=['Size'], outfile='recs_query_size.csv')
#     calc_general(df, cut_by=['FUELH2O_agg'],columns=['Size'], outfile='output_size.csv', norm=False)
    # Query Stories
#     query_stories(df)
#     calc_general(df, cut_by=[],columns=['ESCWASH'], outfile='output_cw.csv', norm=False)
#     calc_general(df, cut_by=[],columns=['ESDISHW'], outfile='output_dw.csv', norm=False)
#     calc_general(df, cut_by=[],columns=['ESFRIG'], outfile='output_ref.csv', norm=False)
#     calc_general(df, cut_by=[],columns=['Percent CFLs'], outfile='output_ltg.csv', norm=False)
#     calc_general(df, cut_by=['ESFRIG'],columns=['AGERFRI1'], outfile='output_ref_age.csv', norm=True)
#     calc_general(df, cut_by=['YEARMADERANGE','Custom Region'],columns=['WALLTYPE'], outfile='output_wall.csv', norm=True)
#     calc_general(df, cut_by=['DIVISION'],columns=['WALLTYPE'], outfile='output_wall_div.csv', norm=True)
#     calc_general(df, cut_by=['YEARMADERANGE','Custom Region'],columns=['ATTCHEAT'], outfile='output_ATTCHEAT.csv', norm=True)
#     calc_general(df, cut_by=['YEARMADERANGE','Custom Region'],columns=['Vented Attic'], outfile='output_vented attic.csv', norm=True)
#     calc_general(df, cut_by=[],columns=['ATTCHEAT'], outfile='output_ATTCHEAT.csv', norm=False)
#     calc_general(df, cut_by=[],columns=['Vented Attic'], outfile='output_vented attic.csv', norm=False)
#     calc_general(df, cut_by=[],columns=['Finished Attic'], outfile='output_vented attic.csv', norm=False)
#     calc_general(df, cut_by=[],columns=['Cathedral Ceiling'], outfile='output_vented attic.csv', norm=False)
#     calc_general(df, cut_by=[],columns=['ATTIC'], outfile='output_vented attic.csv', norm=False)
#     df = agg_bedrooms(df)
#     calc_general(df, cut_by=['FUELH2O_agg','Bedrooms_agg'],columns=['Water Heater Size'], outfile='output_wh_size.csv', norm=False)
    # Generic Query
#     calc_general(df, cut_by=['REPORTABLE_DOMAIN'],columns=['ESCWASH'], outfile='output_general.csv')
# FUELHEAT house counts
#     df = calc_general(df, cut_by=['Custom Region','YEARMADERANGE','FUELHEAT'],columns=[], outfile='output_heating_fuel.csv', norm=False)
#     df
#     df = calc_general(df, cut_by=['Custom Region'],columns=['FUELHEAT'], outfile='output_heating_fuel.csv', norm=True)
# df = calc_general(df, cut_by=[],columns=['ATHOME'], outfile='output_athome.csv', norm=False)
#     calc_htg_type(df)
#     calc_general(df, cut_by=['FUELHEAT'],columns=['EQUIPM'], outfile='recs_query_heating_type.csv', norm=False)