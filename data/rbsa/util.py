import pandas as pd
import datetime as dt
import csv
import random
import sqlite3
import itertools
import numpy as np

random.seed(9801)

def create_dataframe(session, rdb, only_single_family=True, screen_scen='No Screens'):
        
    siteid = pd.Series([br.siteid for br in session.query(rdb.SFMasterLocation)])
    df = pd.DataFrame([(br.siteid, dt.datetime.now(), br) for br in session.query(rdb.SFMasterLocation)], columns=['siteid', 'created', 'object']).set_index('siteid')
    if only_single_family:
        df['building_type'] = df.apply(lambda x: x.object.sfmasterhousegeometry.sfbuildingtype, axis=1)
        df = df[df.building_typev == 'Single Family, Detached', ]
        del df['building_type']

    if not screen_scen == 'No Screens':
        screens = pd.read_csv('screens.csv', index_col=['SiteID'])[[screen_scen]]
        inclusions = screens[screens[screen_scen]==0].index.values
        df = df.loc[df.index.isin(inclusions)]    

    return df

def categories_to_columns(df, column, svywt=True):
    categories = df[column]
    unique_categories = categories.unique()
    unique_category_weights = []
    for category in unique_categories:
        unique_category_weights.append('%s_weight' % category)
        if svywt:
            try:
                df[category] = df.apply(lambda x: x.object.sfmasterpopulations.svywt * x.area * (1.0 / len(df[df.index==x.name])) if x[column] == category else 0, axis=1)
            except:
                df[category] = df.apply(lambda x: x.object.sfmasterpopulations.svywt * (1.0 / len(df[df.index==x.name])) if x[column] == category else 0, axis=1)
            df['%s_weight' % category] = df.apply(lambda x: x.object.sfmasterpopulations.svywt * (1.0 / len(df[df.index==x.name])) if x[column] == category else 0, axis=1)
        else:
            try:
                df[category] = df.apply(lambda x: x.area if x[column] == category else 0, axis=1)
            except:
                df[category] = df.apply(lambda x: 1 if x[column] == category else 0, axis=1)

    df['Weight'] = df[unique_category_weights].sum(axis=1)
        
    return df, sorted(unique_categories.tolist())

def sum_cols(df, cols):
    
    df = df[cols]
    df_colsum = df.sum()

    return df_colsum.div(df_colsum.sum(axis=1), axis=0)

def assign_state(df):
    
    df['ST'] = df.apply(lambda x: x.object.state, axis=1)
    
    return df

def assign_state_2(df):
    
    df['Dependency=State'] = df.apply(lambda x: x.object.state, axis=1)
    
    return df

def assign_totalsfd(df):
    
    df['TotalSFD'] = df.apply(lambda x: x.object.sfmasterpopulations.svywt, axis=1)
    
    return df

def assign_climate_zones(df):
    
    df['H'] = df.apply(lambda x: x.object.sfmasterpopulations.heatclimzone, axis=1)
    df['C'] = df.apply(lambda x: x.object.sfmasterpopulations.coolclimzone, axis=1)    
    
    return df
    
def assign_heating_location(df):
    
    def location(h):
        h = float(h)
        if h==1:
            return 'H1'
        elif h==2:
            return 'H2'
        elif h==3:
            return 'H3'
    
    df['Dependency=Location Heating Region'] = df.apply(lambda x: location(x.H), axis=1)
    
    return df
    
def assign_cooling_location(df):
    
    def location(c, st):
        c = float(c)
        if c==1:
            return 'C1'
        elif c==2:
            return 'C2'
        elif c==3:
            return 'C3'
    
    df['Dependency=Location Cooling Region'] = df.apply(lambda x: location(x.C, x.ST), axis=1)
    
    return df        

def assign_vintage(df):
    
    vintagekey = {'1950s': '1950s',
                  '1960s': '1960s',
                  '1970s': '1970s',
                  '1980s': '1980s',
                  '1990s': '1990s',
                  '2000s': '2000s',
                  '2010s': '2000s'}
    
    df['yearbuilt'] = df.apply(lambda x: x.object.sfricustdat.resintyearbuilt, axis=1)
    
    def decade(row):
        try:
            year = (row // 10.0) * 10.0
            if year < 1950:
                year = '<1950'
            else:
                year = vintagekey['%ss' % int(year)]
            return year
        except:
            return None

    df['Dependency=Vintage'] = df.apply(lambda x: decade(x.yearbuilt), axis=1)
    df = df.dropna(subset=['Dependency=Vintage'])
        
    return df

def assign_heating_fuel(df):
    
    fueltypekey = {'Electric': 'Electricity',
                   'Gas': 'Natural Gas',
                   'Propane': 'Propane',
                   'Wood': 'Wood',
                   'Oil': 'Fuel Oil',
                   'Pellets': 'Wood'}
    
    def fuel(hvacheating):
        for eq in hvacheating:
            if eq.hvacprimary:
                return fueltypekey[eq.hvacfuel]
    
    df['Dependency=Heating Fuel'] = df.apply(lambda x: fuel(x.object.hvacheating), axis=1)
    df = df[pd.notnull(df['Dependency=Heating Fuel'])]

    return df 

def assign_ceiling(df):
    
    with open('data/rbsa to beopt mapping/Ceiling.csv', 'rU') as file:
        reader = csv.reader(file, delimiter=',')
        reader.next()
        rvalkey = {row[0]:row[1] for row in reader}      
    
    rval_area = []
    for index, row in df.iterrows():
        for atticceiling in row.object.sfatticceiling:
            if atticceiling.atticinslvl is not None:
                rval_area.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Heating Region'], rvalkey[atticceiling.atticinslvl]))

    return pd.DataFrame(rval_area, columns=['siteid', 'created', 'object', 'Dependency=Vintage', 'Dependency=Location Heating Region', 'rval']).set_index('siteid')
    
def assign_ceiling_2(df):
    
    with open('data/rbsa to beopt mapping/Ceiling.csv', 'rU') as file:
        reader = csv.reader(file, delimiter=',')
        reader.next()
        rvalkey = {row[0]:row[1] for row in reader}      
    
    rval_area = []
    for index, row in df.iterrows():
        for atticceiling in row.object.sfatticceiling:
            if atticceiling.atticinslvl is not None:
                rval_area.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=State'], rvalkey[atticceiling.atticinslvl]))

    return pd.DataFrame(rval_area, columns=['siteid', 'created', 'object', 'Dependency=Vintage', 'Dependency=State', 'rval']).set_index('siteid')    
    
def assign_wall(df):
    
    with open('data/rbsa to beopt mapping/Walls.csv', 'rU') as file:
        reader = csv.reader(file, delimiter=',')
        reader.next()
        rvalkey = {row[0]:row[1] for row in reader}
    
    rval_area = []
    for index, row in df.iterrows():
        for framedwall in row.object.sfframedwall:
            if framedwall.framedinslvl is not None:
                if rvalkey[framedwall.framedinslvl] == 'NaN':
                    continue
                rval_area.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Heating Region'], rvalkey[framedwall.framedinslvl]))
        
    return pd.DataFrame(rval_area, columns=['siteid', 'created', 'object', 'Dependency=Vintage', 'Dependency=Location Heating Region', 'rval']).set_index('siteid')

def assign_wall_2(df):
    
    with open('data/rbsa to beopt mapping/Walls.csv', 'rU') as file:
        reader = csv.reader(file, delimiter=',')
        reader.next()
        rvalkey = {row[0]:row[1] for row in reader}
    
    rval_area = []
    for index, row in df.iterrows():
        for framedwall in row.object.sfframedwall:
            if framedwall.framedinslvl is not None and framedwall.framedwallarea is not None:
                if rvalkey[framedwall.framedinslvl] == 'NaN':
                    continue
                rval_area.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=State'], rvalkey[framedwall.framedinslvl]))
        
    return pd.DataFrame(rval_area, columns=['siteid', 'created', 'object', 'Dependency=Vintage', 'Dependency=State', 'rval']).set_index('siteid')

def assign_foundation_type(df):
    
    foundtypekey = {'>90% conditioned basement': 'Heated Basement',
                    '>90% Crawl': 'Crawl',
                    '>90% Slab': 'Slab',
                    '>90% unconditioned basement': 'Unheated Basement'}
            
    found_type = []
    for index, row in df.iterrows():
        if row.object.sfmasterhousegeometry.sffoundation:
            try:
                found_type.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Heating Region'], foundtypekey[row.object.sfmasterhousegeometry.sffoundation]))
            except:
                if row.object.sfmasterhousegeometry.sffoundation == 'Mixed crawl and slab':
                    found_type.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Heating Region'], 'Crawl'))
                    found_type.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Heating Region'], 'Slab'))
                elif row.object.sfmasterhousegeometry.sffoundation == 'Mixed crawl and conditioned basement':
                    found_type.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Heating Region'], 'Crawl'))
                    found_type.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Heating Region'], 'Heated Basement'))
                elif row.object.sfmasterhousegeometry.sffoundation == 'Mixed crawl and unconditioned basement':
                    found_type.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Heating Region'], 'Crawl'))
                    found_type.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Heating Region'], 'Unheated Basement'))                                        

    return pd.DataFrame(found_type, columns=['siteid', 'created', 'object', 'Dependency=Vintage', 'Dependency=Location Heating Region', 'Dependency=Geometry Foundation Type']).set_index('siteid')

def assign_heated_basement_boolean(df):
    key = {'Heated Basement': 'Yes',
           'Crawl': 'No',
           'Slab': 'No',
           'Unheated Basement': 'No'}

    df.loc[:,'Dependency=Geometry Heated Basement'] = df['Dependency=Geometry Foundation Type'].replace(key)
    return df

def assign_size(df):
    
    def binned_size(sfmasterhousegeometry):
        if sfmasterhousegeometry.summarysketchsqftcalculated is None:
            return None
        else:
            size = float(sfmasterhousegeometry.summarysketchsqftcalculated)
            if size < 1500:
                return '0-1499'
            elif size >= 1500 and size < 2500:
                return '1500-2499'
            elif size >= 2500 and size < 3500:
                return '2500-3499'
            else:
                assert size >= 3500
                return '3500+'
                
    def size(sfmasterhousegeometry):
        if sfmasterhousegeometry.summarysketchsqftcalculated is None:
            return None
        else:
            size = float(sfmasterhousegeometry.summarysketchsqftcalculated)
            return size        

    df['House Size'] = df.apply(lambda x: size(x.object.sfmasterhousegeometry), axis=1)
    df['Dependency=Geometry House Size'] = df.apply(lambda x: binned_size(x.object.sfmasterhousegeometry), axis=1)
    df = df.dropna(subset=['Dependency=Geometry House Size'])
    
    return df

def assign_stories(df):
    
    storieskey = {'1': '1',
                  '1.5': '2+',
                  '2': '2+',
                  '2.5': '2+',
                  '3+': '2+'}
        
    df['Dependency=Geometry Stories'] = df.apply(lambda x: storieskey[x.object.sfmasterhousegeometry.sffloors], axis=1)
    df = df.dropna(subset=['Dependency=Geometry Stories'])
    
    return df

def assign_primary_heating_system_type(df):

    def htg(hvacheating):
        for eq in hvacheating:
            if eq.hvacprimary:
                return eq.hvactype
        
    df['Dependency=Primary Heating System Type'] = df.apply(lambda x: htg(x.object.hvacheating), axis=1)
    df = df.fillna('None')
    return df
    
def assign_htgsp(df):
    
    def temp(t, sb):
        if t is None or t == 0:
            return None
        if t <= 62:
            if sb is None or sb == 0:
                return '60F'
            else:
                return '60F w/setback'
        elif t >= 63 and t <= 66:
            if sb is None or sb == 0:
                return '65F'
            else:
                return '65F w/setback'
        elif t in [67, 68] or (t == 69 and random.choice([True, False])):
            if sb is None or sb == 0:
                return '68F'
            else:
                return '68F w/setback'
        elif t in [69, 70] or (t == 71 and random.choice([True, False])):
            if sb is None or sb == 0:
                return '70F'
            else:
                return '70F w/setback'
        elif t in [71, 72, 73]:
            if sb is None or sb == 0:
                return '72F'
            else:
                return '72F w/setback'
        elif t >= 74:
            if sb is None or sb == 0:
                return '75F'
            else:
                return '75F w/setback'
        else:
            print t
    
    df['Dependency=Heating Setpoint'] = df.apply(lambda x: temp(x.object.sfriheu.resintheattemp, x.object.sfriheu.resintheattempnight), axis=1)
    df = df.dropna(subset=['Dependency=Heating Setpoint'])

    return df

def assign_htgsbk(df):
    
    def temp(sb):
        if sb is None or sb == 0:
            return None
        else:
            return sb
    
    df['htgsbk'] = df.apply(lambda x: temp(x.object.sfriheu.resintheattempnight), axis=1)
    df = df.dropna(subset=['htgsbk'])

    return df    
    
def assign_clgsp(df):
    
    def temp(t):
        if t is None or t == 0:
            return None
        if t <= 66:
            return '65F'
        elif t in [67, 68] or (t == 69 and random.choice([True, False])):
            return '68F'
        elif t in [69, 70] or (t == 71 and random.choice([True, False])):
            return '70F'
        elif t in [71, 72, 73]:
            return '72F'
        elif t >= 74 and t <= 76:
            return '75F'
        elif t in [77, 78] or (t == 79 and random.choice([True, False])):
            return '78F'
        elif t == 79 or t >= 80:
            return '80F'
        else:
            print t 
    
    df['clgsp'] = df.apply(lambda x: temp(x.object.sfriheu.resintactemp), axis=1)
    df = df.dropna(subset=['clgsp'])

    return df

def assign_slab(df):
    
    rval_area = []
    for index, row in df.iterrows():
        for slab in row.object.sfflslab:
            if slab.uslabperimfloor is not None:
                if row['Dependency=Geometry Foundation Type'] != 'Slab':
                    rval_area.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Heating Region'], row['Dependency=Geometry Foundation Type'], 'None'))                
                else:
                    if slab.uslabperimfloor >= 0.73:
                        rval_area.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Heating Region'], row['Dependency=Geometry Foundation Type'], 'Uninsulated'))
                    elif slab.uslabperimfloor > 0.67 and slab.uslabperimfloor < 0.73:
                        rval_area.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Heating Region'], row['Dependency=Geometry Foundation Type'], '4ft R5 Perimeter, R5 Gap'))
                    elif slab.uslabperimfloor <= 0.67:
                        rval_area.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Heating Region'], row['Dependency=Geometry Foundation Type'], 'R10 Whole Slab, R5 Gap'))

    return pd.DataFrame(rval_area, columns=['siteid', 'created', 'object', 'Dependency=Vintage', 'Dependency=Location Heating Region', 'Dependency=Geometry Foundation Type', 'rval']).set_index('siteid')

def assign_crawl(df):
    
    rval_area = []
    for index, row in df.iterrows():
        for crawl in row.object.sfflcrawl:
            if crawl.ucrawlfloor is not None and crawl.ucrawlwall is not None:
                if row['Dependency=Geometry Foundation Type'] != 'Crawl':
                    rval_area.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Heating Region'], row['Dependency=Geometry Foundation Type'], 'None'))
                else:
                    if crawl.ucrawlfloor >= 0.23 and crawl.ucrawlwall <= 3.1:
                        rval_area.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Heating Region'], row['Dependency=Geometry Foundation Type'], 'Uninsulated, Vented'))
                    elif crawl.ucrawlfloor >= 0.23 and crawl.ucrawlwall > 3.1 and crawl.ucrawlwall <= 5.0:
                        rval_area.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Heating Region'], row['Dependency=Geometry Foundation Type'], 'Uninsulated, Unvented'))
                    elif crawl.ucrawlfloor >= 0.23 and crawl.ucrawlwall > 5.0:
                        rval_area.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Heating Region'], row['Dependency=Geometry Foundation Type'], 'Wall R-13, Unvented'))
                    elif crawl.ucrawlfloor < 0.23 and crawl.ucrawlfloor > 0.06:
                        rval_area.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Heating Region'], row['Dependency=Geometry Foundation Type'], 'Ceiling R-13, Vented'))
                    elif crawl.ucrawlfloor <= 0.06 and crawl.ucrawlfloor >= 0.04:
                        rval_area.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Heating Region'], row['Dependency=Geometry Foundation Type'], 'Ceiling R-19, Vented'))
                    elif crawl.ucrawlfloor < 0.04:
                        rval_area.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Heating Region'], row['Dependency=Geometry Foundation Type'], 'Ceiling R-30, Vented'))

    return pd.DataFrame(rval_area, columns=['siteid', 'created', 'object', 'Dependency=Vintage', 'Dependency=Location Heating Region', 'Dependency=Geometry Foundation Type', 'rval']).set_index('siteid')

def assign_ufbsmt(df):
    
    ceilinstypekey = {'R16-R22': 'Ceiling R-19',
                      'None': 'Uninsulated',
                      'R11-R15': 'Ceiling R-13',
                      'R4-R10': 'Ceiling R-13',
                      'R28-R35': 'Ceiling R-19',
                      'R23-R27': 'Ceiling R-19'}

    rval_area = []
    for index, row in df.iterrows():
        for bsmt in row.object.sfflbasement:
            if not bsmt.basementconditioned:
                if bsmt.basementfloorinsulation and not bsmt.basementfloorinsulation == 'None':
                    if bsmt.basementfloorinsulationcond > 0:
                        if row['Dependency=Geometry Foundation Type'] != 'Unheated Basement':
                            rval_area.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Heating Region'], row['Dependency=Geometry Foundation Type'], 'None'))
                        else:
                            rval_area.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Heating Region'], row['Dependency=Geometry Foundation Type'], ceilinstypekey[bsmt.basementfloorinsulation]))
                    else:
                        if row['Dependency=Geometry Foundation Type'] != 'Unheated Basement':
                            rval_area.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Heating Region'], row['Dependency=Geometry Foundation Type'], 'None'))                            
                        else:
                            rval_area.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Heating Region'], row['Dependency=Geometry Foundation Type'], 'Uninsulated'))                    
                else:
                    if row['Dependency=Geometry Foundation Type'] != 'Unheated Basement':
                        rval_area.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Heating Region'], row['Dependency=Geometry Foundation Type'], 'None'))                        
                    else:
                        rval_area.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Heating Region'], row['Dependency=Geometry Foundation Type'], 'Uninsulated'))

    return pd.DataFrame(rval_area, columns=['siteid', 'created', 'object', 'Dependency=Vintage', 'Dependency=Location Heating Region', 'Dependency=Geometry Foundation Type', 'rval']).set_index('siteid')

def assign_fbsmt(df):
    
    wallinstypekey = {'R16-R22': 'Wall R-15',
                      'None': 'Uninsulated',
                      'R11-R15': 'Wall R-10',
                      'R4-R10': 'Wall R-5',
                      'R28-R35': 'Wall R-15',
                      'R23-R27': 'Wall R-15'}

    rval_area = []
    for index, row in df.iterrows():
        for bsmt in row.object.sfflbasement:            
            if bsmt.basementconditioned:                
                if bsmt.basementfloorinsulation is not None:
                    if bsmt.basementfloorarea is not None:
                        if row['Dependency=Geometry Foundation Type'] != 'Heated Basement':
                            rval_area.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Heating Region'], row['Dependency=Geometry Foundation Type'], 'None'))
                        else:
                            rval_area.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Heating Region'], row['Dependency=Geometry Foundation Type'], wallinstypekey[bsmt.basementfloorinsulation]))
                    else:
                        if row['Dependency=Geometry Foundation Type'] != 'Heated Basement':
                            rval_area.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Heating Region'], row['Dependency=Geometry Foundation Type'], 'None'))                        
                        else:
                            rval_area.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Heating Region'], row['Dependency=Geometry Foundation Type'], 'Uninsulated'))
                else:
                    if row['Dependency=Geometry Foundation Type'] != 'Heated Basement':
                        rval_area.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Heating Region'], row['Dependency=Geometry Foundation Type'], 'None'))                    
                    else:
                        rval_area.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Heating Region'], row['Dependency=Geometry Foundation Type'], 'Uninsulated'))

    return pd.DataFrame(rval_area, columns=['siteid', 'created', 'object', 'Dependency=Vintage', 'Dependency=Location Heating Region', 'Dependency=Geometry Foundation Type', 'rval']).set_index('siteid')

def assign_intfloor(df):
    
    rval_area = []
    for index, row in df.iterrows():
        for intfloor in row.object.sfflooroverarea:
            if intfloor.uoverareafloor is not None:
                if intfloor.uoverareafloor >= 0.23:
                    rval_area.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Heating Region'], 'Uninsulated'))
                elif intfloor.uoverareafloor > 0.04 and intfloor.uoverareafloor < 0.23:
                    rval_area.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Heating Region'], 'R-13'))
                elif intfloor.uoverareafloor <= 0.04:
                    rval_area.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Heating Region'], 'R-19'))

    return pd.DataFrame(rval_area, columns=['siteid', 'created', 'object', 'Dependency=Vintage', 'Dependency=Location Heating Region', 'rval']).set_index('siteid')

def assign_win(df):
    
    rval_area = []                    
    for index, row in df.iterrows():
        for win in row.object.sfwindow:
            if win.windowtypeclass is not None:
                if win.windowtypeclass in ['Metal:Single', 'Metal:Single:low-e']:
                    rval_area.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Heating Region'], 'Clear, Single, Metal'))
                elif win.windowtypeclass in ['Metal:Double']:
                    rval_area.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Heating Region'], 'Clear, Double, Metal, Air'))
                elif win.windowtypeclass in ['Wood-Vinyl-Fiberglass:Single', 'Wood-Vinyl-Fiberglass:Single:low-e']:
                    rval_area.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Heating Region'], 'Clear, Single, Non-metal'))
                elif win.windowtypeclass in ['Wood-Vinyl-Fiberglass:Double']:
                    rval_area.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Heating Region'], 'Clear, Double, Non-metal, Air'))
                elif win.windowtypeclass in ['Wood-Vinyl-Fiberglass:Double:low-e', 'Metal:Double:low-e', 'Metal:Triple', 'Wood-Vinyl-Fiberglass:Triple', 'Wood-Vinyl-Fiberglass:Triple:low-e']:
                    rval_area.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Heating Region'], 'Low-E, Double, Non-metal, Air, M-Gain'))
                else:
                    print index, win.windowtypeclass
            else:
                print index, win.windowtypeclass

    return pd.DataFrame(rval_area, columns=['siteid', 'created', 'object', 'Dependency=Vintage', 'Dependency=Location Heating Region', 'rval']).set_index('siteid')

def assign_win_2(df):
    
    rval_area = []
    for index, row in df.iterrows():
        for win in row.object.sfwindow:
            if win.uwindow is not None:
                if win.uwindow in [1.1]:
                    rval_area.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=State'], 'Clear, Single, Metal'))
                elif win.uwindow in [0.9, 0.95]:
                    rval_area.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=State'], 'Clear, Single, Non-metal'))
                elif win.uwindow in [0.8, 0.85]:
                    rval_area.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=State'], 'Clear, Double, Metal, Air'))
                elif win.uwindow in [0.75]:
                    rval_area.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=State'], 'Clear, Double, Thermal-Break, Air'))
                elif win.uwindow in [0.55, 0.6, 0.65, 0.7]:
                    rval_area.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=State'], 'Clear, Double, Non-metal, Air'))
                elif win.uwindow in [0.4, 0.45, 0.5]:
                    rval_area.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=State'], 'Low-E, Double, Non-metal, Air, M-Gain'))
                elif win.uwindow in [0.22, 0.35]:
                    rval_area.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=State'], 'Low-E, Triple, Non-metal, Air, L-Gain'))
                else:
                    print index, win.uwindow

    return pd.DataFrame(rval_area, columns=['siteid', 'created', 'object', 'Dependency=Vintage', 'Dependency=State', 'rval']).set_index('siteid')

def assign_inf(df):
    
    def ach(sfblowerdoor):
        try:
            if sfblowerdoor.ach50 is None:
                return None
            else:
                size = float(sfblowerdoor.ach50)
                if size < 3.0:
                    return '2 ACH50'
                elif size >= 3.0 and size < 5.0:
                    return '4 ACH50'
                elif size >= 5.0 and size < 7.0:
                    return '6 ACH50'
                elif size >= 7.0 and size < 9.0:
                    return '8 ACH50'
                elif size >= 9 and size < 12.5:
                    return '10 ACH50'
                elif size >= 12.5 and size < 17.5:
                    return '15 ACH50'
                elif size >= 17.5 and size < 22.5:
                    return '20 ACH50'                                                                       
                else:
                    assert size >= 22.5
                    return '25 ACH50'
        except:
            return None
        
    df['inf'] = df.apply(lambda x: ach(x.object.sfblowerdoor), axis=1)
    df = df.dropna(subset=['inf'])
    
    return df

def assign_hvac_system_combined(df):
    
    conditioned_key = {'ASHP': '',
                       'MSHP': ', 60% Conditioned',
                       'Dual-Fuel ASHP': '',
                       'GSHP': ''}
    
    htg_and_clg = []
    for index, row in df.iterrows():
        htg = 'None'
        clg = 'None'
        htg_sys = None
        clg_sys = None
        for eq in row.object.hvacheating:
            if eq.hvacprimary:
                if eq.hvactype == 'heatpump':
                    if eq.hspf:
                        htg = round(eq.hspf * 2) / 2 # nearest half integer
                    htg_sys = 'ASHP'
                elif eq.hvactype == 'dhp':
                    htg = 9.6
                    htg_sys = 'MSHP'
                elif eq.hvactype == 'heatpumpdualfuel':
                    htg = 8.2
                    htg_sys = 'Dual-Fuel ASHP'
                elif eq.hvactype == 'gshp':
                    htg_sys = 'GSHP'
        for eq in row.object.hvaccooling:
            if eq.hvacprimarycooling:
                if eq.hvactype == 'heatpump':
                    if eq.seer:
                        clg = round(eq.seer * 2) / 2 # nearest half integer
                    clg_sys = 'ASHP'
                elif eq.hvactype == 'dhp':
                    clg = 18.0
                    clg_sys = 'MSHP'
                elif eq.hvactype == 'heatpumpdualfuel':
                    clg = 14
                    clg_sys = 'Dual-Fuel ASHP'
                elif eq.hvactype == 'gshp':
                    clg_sys = 'GSHP'
        if not row['Dependency=Heating Fuel'] == 'Electricity':
            htg_and_clg.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Heating Region'], row['Dependency=Location Cooling Region'], row['Dependency=Heating Fuel'], 'None'))
        else:
            if not htg == 'None' and not clg == 'None':
                assert htg_sys == clg_sys
                try:
                    htg_and_clg.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Heating Region'], row['Dependency=Location Cooling Region'], row['Dependency=Heating Fuel'], '{type}, SEER {clg}, {htg} HSPF{cond}'.format(type=htg_sys, htg=htg, clg={7: 10.3, 7.5: 11.5, 8: 13, 8.5: 14.3, 9: 16}[htg], cond=conditioned_key[htg_sys])))
                except:
                    htg_and_clg.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Heating Region'], row['Dependency=Location Cooling Region'], row['Dependency=Heating Fuel'], '{type}, SEER {clg}, {htg} HSPF{cond}'.format(type=htg_sys, htg=htg, clg=clg, cond=conditioned_key[htg_sys])))
            elif not htg == 'None':
                htg_and_clg.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Heating Region'], row['Dependency=Location Cooling Region'], row['Dependency=Heating Fuel'], '{type}, SEER {clg}, {htg} HSPF{cond}'.format(type=htg_sys, htg=htg, clg={7: 10.3, 7.5: 11.5, 8: 13, 8.5: 14.3, 9: 16}[htg], cond=conditioned_key[htg_sys])))
            elif not clg == 'None':
                if clg_sys == 'MSHP':
                    htg_and_clg.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Heating Region'], row['Dependency=Location Cooling Region'], row['Dependency=Heating Fuel'], '{type}, SEER {clg}, 9.6 HSPF{cond}'.format(type=clg_sys, clg=clg, cond=conditioned_key[clg_sys])))
            else:
                assert htg_sys == clg_sys
                htg_and_clg.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Heating Region'], row['Dependency=Location Cooling Region'], row['Dependency=Heating Fuel'], '{type}'.format(type=htg_sys)))

    return pd.DataFrame(htg_and_clg, columns=['siteid', 'created', 'object', 'Dependency=Vintage', 'Dependency=Location Heating Region', 'Dependency=Location Cooling Region', 'Dependency=Heating Fuel', 'htg_and_clg']).set_index('siteid')

def assign_hvac_system_is_combined(df, col):
    def hvac_system_is_combined(sys):
        if 'ASHP' in sys or 'MSHP' in sys or 'GSHP' in sys:
            return 'Yes'
        return 'No'
    
    df['Dependency=HVAC System Is Combined'] = df[col].apply(lambda x: hvac_system_is_combined(x))

    return df    

def assign_heating_types_and_fuel(df):

    gas_systems = ['faf', 'htstove', 'boiler']

    def primary_htg(hvacheating):
        for eq in hvacheating:
            if eq.hvacprimary:
                if eq.hvacfuel == 'Gas':
                    if eq.hvactype in gas_systems:
                        return eq.hvactype

    def secondary_htg(primary_gas_system, hvacheating, sys):
        fuel = None
        if '_' in sys:
            fuel = sys.split('_')[0]
            sys = sys.split('_')[1]
        
        for eq in hvacheating:
            if not eq.hvacprimary:
                if fuel:
                    if sys == eq.hvactype and fuel == eq.hvacfuel:
                        return 1
                else:
                    if sys == eq.hvactype:
                        return 1
                        
    df['primary_gas_system'] = df.apply(lambda x: primary_htg(x.object.hvacheating), axis=1)
    df = df.dropna(subset=['primary_gas_system'])
    secondary_systems = ['baseboard', 'pluginheater', 'faf', 'Gas_htstove', 'Oil_htstove', 'Other_htstove', 'Pellets_htstove', 'Propane_htstove', 'Wood_htstove', 'heatpump', 'Wood_fireplace', 'Propane_fireplace', 'heatpumpdualfuel', 'boiler', 'dhp', 'gshp']
    for sys in secondary_systems:
        df[sys] = df.apply(lambda x: secondary_htg(x.primary_gas_system, x.object.hvacheating, sys), axis=1)
    df = df.fillna(0.0)
    df['num_secondary_systems'] = df[secondary_systems].sum(axis=1)
    df['no_secondary'] = df['num_secondary_systems'].apply(lambda x: 1.0 if x == 0 else 0.0)
    print df.shape
    df[secondary_systems + ['no_secondary']].sum().to_frame(name='counts')

    return df
    
def assign_presence_of_secondary_system(df):
    
    def secondary_htg(hvacheating):        
        if len(hvacheating) > 1:
            return 1
        else:
            return 0
            
    df['secondary_system'] = df.apply(lambda x: secondary_htg(x.object.hvacheating), axis=1)
    return df
    
def assign_hvac_system_heating(df):
    
    fueltypekey = {'Electric': 'Electric',
                   'Gas': 'Gas',
                   'Oil/Kerosene': 'Oil',
                   'Propane': 'Propane',
                   'Wood': 'Wood',
                   'Other': 'Other Fuel',
                   'Oil': 'Oil',
                   'Pellets': 'Wood'}   
    
    def htg(hvacheating):
        for eq in hvacheating:
            if eq.hvacprimary:
                if eq.hvactype is not None:
                    if eq.hvactype in ['heatpump', 'heatpumpdualfuel', 'gshp', 'dhp']:
                        return np.nan
                    elif eq.hvactype == 'faf':
                        if not eq.hvacfuel:
                            continue
                        if fueltypekey[eq.hvacfuel] == 'Electric':
                            return 'Electric Furnace'
                        else:
                            if eq.combeffic is not None and fueltypekey[eq.hvacfuel] == 'Gas':
                                if eq.combeffic < .62:
                                    return '{fuel} Furnace, 60% AFUE'.format(fuel=fueltypekey[eq.hvacfuel])
                                elif eq.combeffic >= .62 and eq.combeffic < .66:
                                    return '{fuel} Furnace, 64% AFUE'.format(fuel=fueltypekey[eq.hvacfuel])                        
                                elif eq.combeffic >= .66 and eq.combeffic < .7:
                                    return '{fuel} Furnace, 68% AFUE'.format(fuel=fueltypekey[eq.hvacfuel])
                                elif eq.combeffic >= .7 and eq.combeffic < .74:
                                    return '{fuel} Furnace, 72% AFUE'.format(fuel=fueltypekey[eq.hvacfuel])
                                elif eq.combeffic >= .74 and eq.combeffic < .78:
                                    return '{fuel} Furnace, 76% AFUE'.format(fuel=fueltypekey[eq.hvacfuel])                        
                                elif eq.combeffic >= .78 and eq.combeffic < .85:
                                    return '{fuel} Furnace, 80% AFUE'.format(fuel=fueltypekey[eq.hvacfuel])
                                elif eq.combeffic >= .85 and eq.combeffic < .925:
                                    return '{fuel} Furnace, 90% AFUE'.format(fuel=fueltypekey[eq.hvacfuel])
                                else:
                                    return '{fuel} Furnace, 96% AFUE'.format(fuel=fueltypekey[eq.hvacfuel])
                            else:
                                return '{fuel} Furnace'.format(fuel=fueltypekey[eq.hvacfuel])

                    elif eq.hvactype == 'boiler':
                        if not eq.hvacfuel:
                            continue
                        if fueltypekey[eq.hvacfuel] == 'Electric':
                            return 'Electric Boiler'
                        else:
                            if eq.combeffic is not None and fueltypekey[eq.hvacfuel] == 'Gas':
                                if eq.combeffic < 0.74:
                                    return '{fuel} Boiler, 72% AFUE'.format(fuel=fueltypekey[eq.hvacfuel])
                                elif eq.combeffic >= 0.74 and eq.combeffic < 0.78:
                                    return '{fuel} Boiler, 76% AFUE'.format(fuel=fueltypekey[eq.hvacfuel])
                                elif eq.combeffic >= 0.78 and eq.combeffic < 0.835:
                                    return '{fuel} Boiler, 80% AFUE'.format(fuel=fueltypekey[eq.hvacfuel])
                                elif eq.combeffic >= 0.835 and eq.combeffic < 0.875:
                                    return '{fuel} Boiler, 85% AFUE'.format(fuel=fueltypekey[eq.hvacfuel])
                                elif eq.combeffic >= 0.875:
                                    return '{fuel} Boiler, 96% AFUE'.format(fuel=fueltypekey[eq.hvacfuel])
                            else:
                                return '{fuel} Boiler'.format(fuel=fueltypekey[eq.hvacfuel])
        
                    elif eq.hvactype in ['baseboard', 'pluginheater']:
                        return 'Electric Baseboard'
                    elif eq.hvactype == 'htstove':
                        if fueltypekey[eq.hvacfuel] == 'Gas':
                            return '{fuel} Stove, 75% AFUE'.format(fuel=fueltypekey[eq.hvacfuel])
                        else:
                            return '{fuel} Stove'.format(fuel=fueltypekey[eq.hvacfuel])
                    elif eq.hvactype == 'fireplace':
                        if fueltypekey[eq.hvacfuel] == 'Wood':
                            return '{fuel} Stove'.format(fuel=fueltypekey[eq.hvacfuel])
                        else:
                            return '{fuel} Fireplace'.format(fuel=fueltypekey[eq.hvacfuel])
        print eq.hvactype, eq.hvacfuel
        return 'None' # shouldn't hit this
        
    df['htg'] = df.apply(lambda x: htg(x.object.hvacheating), axis=1)
    df = df.dropna(subset=['htg'])
    
    return df
    
def assign_hvac_system_cooling(df):
        
    def clg(object):       
        for eq in object.hvaccooling:
            if eq.hvacprimarycooling:
                if eq.hvactype is not None:
                    if eq.hvactype in ['heatpump', 'heatpumpdualfuel', 'gshp', 'dhp']:
                        return np.nan                    
                    elif eq.hvactype == 'centralAC':
                        if eq.seer is not None:
                            if eq.seer < 9:
                                return 'AC, SEER 8'
                            elif eq.seer >= 9 and eq.seer < 11.5:
                                return 'AC, SEER 10'
                            elif eq.seer >= 11.5 and eq.seer < 14:
                                return 'AC, SEER 13'
                            else:
                                assert eq.seer >= 14
                                return 'AC, SEER 15'
                        else:
                            return 'AC'

                    elif eq.hvactype in ['windowshaker', 'PTAC']:
                        if eq.unitacdaysofuse < 10:
                            return 'None'
                        energy_multiplier = int(10 * round(float(eq.unitacquantity * 100/ ( object.sfmasterhousegeometry.summarynumberofroomscalculated - object.sfricustdat.resintbath )) / 10))                        
                        return 'Room AC, EER 9.8, 20% Conditioned'
                    elif eq.hvactype == 'evapcooler':
                        return 'Evaporative Cooler'
        return 'None'
    
    df['clg'] = df.apply(lambda x: clg(x.object), axis=1)
    df = df.dropna(subset=['clg'])
    
    return df

def assign_ducts(df):
    """
    :param df: DataFrame of all RBSA homes to be used in calculations
    :return: DataFrame containing probability distributions for Ducts

    Ducts differ from other RBSA categories because leakage and insulation are in different DB tables and leakage values
    are only available for a subset of ~250 homes. For this reason, we construct the probability distributions entirely
    here in util.py instead of in input.py. The probability distributions for duct location
    (in conditioned space or not), duct leakage, and duct insulation are queried separately (with different dependencies)
    and combined.
    """

    # Two bins: 'Uninsulated' and 'R-6'
    sfductsRval = {'R0': 'Uninsulated',
                   'R2-R4': 'R-6',
                   'R7-R11': 'R-6',
                   'R4 Flex': 'R-6',
                   'R6 Flex': 'R-6',
                   'R8 Flex': 'R-6',
                   'R0 Metal; R4 Flex': 'R-6',
                   'R0 Metal; R6 Flex': 'R-6',
                   'R0 Metal; R8 Flex': 'R-6',
                   'R2-R4 Metal; R4 Flex': 'R-6',
                   'R2-R4 Metal; R6 Flex': 'R-6',
                   'R2-R4 Metal; R8 Flex': 'R-6',
                   'R7-R11 Metal; R4 Flex': 'R-6',
                   'R7-R11 Metal; R6 Flex': 'R-6',
                   'R7-R11 Metal; R8 Flex': 'R-6',
                   '1" Ductboard': 'R-6',
                   '2" Ductboard': 'R-6',
                   '1" Ductboard; R4 Flex': 'R-6',
                   '1" Ductboard; R6 Flex': 'R-6',
                   '1" Ductboard; R8 Flex': 'R-6',
                   '2" Ductboard; R4 Flex': 'R-6',
                   '2" Ductboard; R6 Flex': 'R-6'}

    # Bins designed to be roughly equally weighted; could be improved with k-medoid clustering
    leakage_map = {(0.00, 0.10): 0.06,  # Min, Max, Mapped value
                   (0.10, 0.20): 0.14,
                   (0.20, 0.30): 0.24,
                   (0.30, 0.40): 0.34,
                   (0.40, 0.70): 0.53,
                   (0.70, 9999): 0.85}

    con = sqlite3.connect('rbsa.sqlite')

    # Weighting factors
    fields = ['siteid', 'svy_wt']
    df_wt = pd.read_sql("SELECT {} FROM SFMaster_populations".format(', '.join(fields)), con, index_col='siteid')

    # Load general SFducts table
    fields = ['siteid', 'DuctInsulationType', 'DuctsInConditioned', 'DuctsInUnconditioned', 'DuctsReturnInUnconditioned']
    df_ducts = pd.read_sql("SELECT {} FROM SFducts".format(', '.join(fields)), con, index_col='siteid')
    df_ducts = df_ducts.join(df_wt) # Join in weights

    # Probability that ducts are in unconditioned space (depends on foundation type)
    df_cond = pd.DataFrame((df_ducts['DuctsInConditioned'] == 100.0) & (df_ducts['DuctsReturnInUnconditioned'] == 0.0), columns=['InConditioned']) # Convert % values to True/False
    df_cond = df_cond.join(df_wt)
    # depend1 = ['Dependency=Geometry Foundation Type'] # Dependency for 'InConditioned'
    depend1 = ['Dependency=Geometry Heated Basement'] # Dependency for 'InConditioned'
    df_cond = df_cond.join(df[depend1]).dropna(subset=depend1)
    df_cond = group_and_normalize(df_cond, 'InConditioned', depend=depend1)

    # Probability of duct insulation level (depends on vintage)
    df_ducts = df_ducts[((df_ducts['DuctsInConditioned'] < 100) & (df_ducts['DuctsReturnInUnconditioned'] > 0))]
    df_ducts['DuctInsulationType'] = df_ducts['DuctInsulationType'].replace(sfductsRval) # Apply mapping
    depend2 = ['Dependency=Vintage']
    df_ducts = df_ducts.join(df[depend2]).dropna(subset=depend2)
    df_ins = group_and_normalize(df_ducts, 'DuctInsulationType', depend=depend2)

    # Load Duct Leakage Database Table
    fields = ['siteid', 'slf_halfplen', 'rlf_halfplen', 'DB_MajorityReturnLocation', 'DB_MajoritySupplyLocation']
    df_ductleakage = pd.read_sql("SELECT {} FROM SFducttesting_dbase".format(', '.join(fields)), con, index_col='siteid')

    # Probability of duct leakage levels (no dependencies)
    df_ductleakage = df_ductleakage.dropna(subset=['slf_halfplen', 'rlf_halfplen']) # Drop rows with null leakage fractions. Usually means the duct blaster or flow rate test failed
    df_ductleakage.loc[:, 'tlf_halfplen'] = df_ductleakage.loc[:, 'slf_halfplen'] + df_ductleakage.loc[:,'rlf_halfplen'] # Total = Supply + Return
    df_ductleakage = df_ductleakage.join(df_wt)
    # Bin leakage values using leakage map above
    for (v_min, v_max), v_map in leakage_map.iteritems():
        df_ductleakage.loc[(df_ductleakage['tlf_halfplen'] >= v_min) & (df_ductleakage['tlf_halfplen'] < v_max), 'tlf_bin'] = v_map
    df_ductleakage = group_and_normalize(df_ductleakage, 'tlf_bin')

    # Combine probability distributions
    df_product = pd.DataFrame(columns=['option', depend1[0], depend2[0], 'value'])
    for htd_bsmt_bool in df_cond.index:
        for vintage in df_ins.index:
            df_product.loc[len(df_product.index)] = {'option': 'Option=In Finished Space',
                                                     depend1[0]: htd_bsmt_bool,
                                                     depend2[0]: vintage,
                                                     'value': df_cond.loc[htd_bsmt_bool, True]}
            for (ins_label, leak_label), (ins_value, leak_value) in zip(itertools.product(df_ins.loc[vintage].index, df_ductleakage.index), itertools.product(df_ins.loc[vintage], df_ductleakage)):
                index = len(df_product.index)
                df_product.loc[index, 'option'] = 'Option={f:.0f}% Leakage, {s}'.format(f=leak_label*100, s=ins_label)
                df_product.loc[index, depend1[0]] = htd_bsmt_bool
                df_product.loc[index, depend2[0]] = vintage
                df_product.loc[index, 'value'] = ins_value * leak_value * df_cond.loc[htd_bsmt_bool, False]

    # Clean up formatting
    df_product = df_product.set_index([depend1[0],depend2[0], 'option']).unstack()
    df_product.columns = df_product.columns.droplevel()

    # Improve sort order
    rval_sort_order = {'Uninsulated':0.1, 'R-6':0.2}
    new_columns = ['Option=In Finished Space'] + sorted(df_product.columns[:-1], key=lambda x: float(x.split('=')[-1].split('%')[0]) + rval_sort_order[x.split(' ')[-1]])
    df_product = df_product.reindex_axis(new_columns, axis=1)
    df_product = df_product.reset_index()
    df_product[depend2[0]] = pd.Categorical(df_product[depend2[0]], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s'])
    depend = [depend1[0], depend2[0]]
    df_product = df_product.sort_values(by=depend)
    df_product = df_product.set_index(depend)

    return df_product

def group_and_normalize(df, field, depend=None, weight_field='svy_wt'):
    """
    :param df: DataFrame to group and normalize
    :param field: field to group by (i.e. the option)
    :param depend: (optional) other field to group by (i.e. dependency)
    :param weight_field: (optional) name of the columns containing weights
    :return: DataFrame grouped and normalized to percent of row totals
    """
    if depend is None:
        return df.groupby(field).sum()[weight_field] / df[weight_field].sum()
    else:
        df2 = df.groupby(depend + [field]).sum()[weight_field]
        df2 = df2.unstack().fillna(0)
        dfsum = df2.sum(axis=1)
        for col in df2.columns:
            df2[col] = df2[col] / dfsum
        return df2

def product_index(values, names=None):
    """Make a MultiIndex from the combinatorial product of the values."""
    iterable = itertools.product(*values)
    idx = pd.MultiIndex.from_tuples(list(iterable), names=names)
    return idx

def assign_wh(df):

    fueltypekey = {'Electric': 'Electric',
                   'Gas': 'Gas',
                   'Oil/Kerosene': 'Oil',
                   'Propane': 'Propane',
                   'Wood': 'Other Fuel',
                   'Oil': 'Oil'}
    
    whtypekey = {'Storage': 'Standard',
                 'Instantaneous': 'Tankless'}
    
    wheater = []
    for index, row in df.iterrows():
        if len(row.object.sfwheater) == 0:
            pass
        for wh in row.object.sfwheater:
            if wh.whheatpump and wh.whfuel == 'Electric':
                pass
            elif wh.whfuel == 'Oil' and wh.waterheatertype == 'Tankless':
                pass
            elif wh.whfuel == 'Electric' and wh.waterheatertype == 'Tankless':
                pass
            else:
                if not wh.whfuel and not wh.waterheatertype:
                    pass
                elif wh.whfuel == 'Wood':
                    pass
                else:
                    if not wh.waterheatertype:
                        wheater.append((index, row.created, row.object, row['Dependency=Heating Fuel'], '{whfuel} {whtype}'.format(whfuel=fueltypekey[wh.whfuel], whtype=whtypekey['Storage'])))
                    elif not wh.whfuel:
                        wheater.append((index, row.created, row.object, row['Dependency=Heating Fuel'], '{whfuel} {whtype}'.format(whfuel=fueltypekey['Gas'], whtype=whtypekey[wh.waterheatertype])))
                    else:
                        wheater.append((index, row.created, row.object, row['Dependency=Heating Fuel'], '{whfuel} {whtype}'.format(whfuel=fueltypekey[wh.whfuel], whtype=whtypekey[wh.waterheatertype])))
    
    return pd.DataFrame(wheater, columns=['siteid', 'created', 'object', 'Dependency=Heating Fuel', 'wh']).set_index('siteid') 

def assign_ltg(df):
    
    ltgkey = {'Incandescent': 'Incandescent',
              'Compact Fluorescent': 'CFL',
              'Linear Fluorescent': 'CFL',
              'Halogen': 'Incandescent',
              'Other': 'Other'}
    
    ltg = []
    for index, row in df.iterrows():
        for lighting in row.object.sflighting:
            if not ltgkey[lighting.lightinglampcategory] == 'Other':
                ltg.append((index, row.created, row.object, '100% {}'.format(ltgkey[lighting.lightinglampcategory])))
        
    return pd.DataFrame(ltg, columns=['siteid', 'created', 'object', 'ltg']).set_index('siteid')    
    
def assign_rng(df):
    
    fueltypekey = {'Electric': 'Electric',
                   'Gas': 'Gas',
                   'Oil/Kerosene': 'Other Fuel',
                   'Propane': 'Propane',
                   'Wood': 'Other Fuel',
                   'Other': 'Other Fuel',
                   'Oil': 'Other Fuel',
                   'Pellets': 'Other Fuel',
                   None: 'Other Fuel'}    
    
    rng = []
    for index, row in df.iterrows():
        for cookeq in row.object.sfcookeq:
            if not fueltypekey[cookeq.cooktopfuel] == 'Other Fuel':
                rng.append((index, row.created, row.object, row['Dependency=Heating Fuel'], '{}, 100% Usage'.format(fueltypekey[cookeq.cooktopfuel])))
            else:
                rng.append((index, row.created, row.object, row['Dependency=Heating Fuel'], 'None'))
        
    return pd.DataFrame(rng, columns=['siteid', 'created', 'object', 'Dependency=Heating Fuel', 'rng']).set_index('siteid') 

def assign_cd(df):
    
    fueltypekey = {'Electric': 'Electric',
                   'Gas': 'Gas',
                   'Oil/Kerosene': 'Oil',
                   'Propane': 'Gas',
                   'Wood': 'Other Fuel',
                   'Other': 'Other Fuel',
                   'Oil': 'Oil',
                   'Pellets': 'Other Fuel',
                   None: 'Other Fuel'}
    
    cd = []
    for index, row in df.iterrows():
        if len(row.object.sfdryer) == 0:
            cd.append((index, row.created, row.object, row['Dependency=Heating Fuel'], 'None'))
        for dryer in row.object.sfdryer:
            if not fueltypekey[dryer.dryerfuel] == 'Other Fuel':
                cd.append((index, row.created, row.object, row['Dependency=Heating Fuel'], '{}, 100% Usage'.format(fueltypekey[dryer.dryerfuel])))
            else:
                cd.append((index, row.created, row.object, row['Dependency=Heating Fuel'], 'None'))
        
    return pd.DataFrame(cd, columns=['siteid', 'created', 'object', 'Dependency=Heating Fuel', 'cd']).set_index('siteid')
    
def assign_electricity_consumption(df):

    df['kwh_nrm'] = df.apply(lambda x: x.object.sfenergysumtmy3.kwhnrmy, axis=1)
    df['Weight'] = df.apply(lambda x: x.object.sfmasterpopulations.svywt, axis=1)
    df = df.fillna(0)

    return df
    
def assign_natural_gas_consumption(df):

    df['thm_nrm'] = df.apply(lambda x: x.object.sfenergysumtmy3.thmnrmy, axis=1)
    df['Weight'] = df.apply(lambda x: x.object.sfmasterpopulations.svywt, axis=1)
    df = df.fillna(0)

    return df
    
def assign_natural_gas_consumption_tmy2_nrm_sel(df):

    df['thm_nrm'] = df.apply(lambda x: x.object.sfenergysum.thmnrmsel, axis=1)
    df['Weight'] = df.apply(lambda x: x.object.sfmasterpopulations.svywt, axis=1)
    df = df.fillna(0)

    return df
    
def assign_natural_gas_consumption_tmy2_nrm(df):

    df['thm_nrm'] = df.apply(lambda x: x.object.sfenergysum.thmnrmy, axis=1)
    df['Weight'] = df.apply(lambda x: x.object.sfmasterpopulations.svywt, axis=1)
    df = df.fillna(0)

    return df

def assign_natural_gas_consumption_tmy2_act(df):

    df['thm_nrm'] = df.apply(lambda x: x.object.sfenergysum.thmy, axis=1)
    df['Weight'] = df.apply(lambda x: x.object.sfmasterpopulations.svywt, axis=1)
    df = df.fillna(0)

    return df    
