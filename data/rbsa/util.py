import pandas as pd
import datetime as dt
import numpy as np
import csv
import random

def create_dataframe(session, rdb, only_single_family=True):
        
    siteid = pd.Series([br.siteid for br in session.query(rdb.SFMasterLocation)])
    df = pd.DataFrame([(br.siteid, dt.datetime.now(), br) for br in session.query(rdb.SFMasterLocation)], columns=['siteid', 'created', 'object']).set_index('siteid')
    if only_single_family:
        df['building_type'] = df.apply(lambda x: x.object.sfmasterhousegeometry.sfbuildingtype, axis=1)
        df = df[df.building_type=='Single Family, Detached']
        del df['building_type']
    
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
    
def assign_location(df):
    
    def location(h, c, st):
        h = float(h)
        c = float(c)
        if h==1 and c==1 and st=='OR':
            return 'H1C1 OR'
        elif h==1 and c==1 and st=='WA':
            return 'H1C1 WA'
        elif h==1 and c==2:
            return 'H1C2'
        elif h==1 and c==3:
            return 'H1C3'
        elif h==2:
            return 'H2'
        elif h==3:
            return 'H3'
    
    df['Dependency=Location Region'] = df.apply(lambda x: location(x.H, x.C, x.ST), axis=1)
    
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
                   'Oil/Kerosene': 'Fuel Oil',
                   'Propane': 'Propane/LPG',
                   'Wood': 'Wood',
                   'Oil': 'Fuel Oil',
                   'Pellets': 'Wood'}
    
    # skip None
    # and rename Other Fuel To Wood (there are no primary Other in RBSA)
    
    def fuel(hvacheating):
        for eq in hvacheating:
            if eq.hvacprimary:
                try:
                    return fueltypekey[eq.hvacfuel]
                except:
                    return None
    
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
                rval_area.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Region'], rvalkey[atticceiling.atticinslvl]))

    return pd.DataFrame(rval_area, columns=['siteid', 'created', 'object', 'Dependency=Vintage', 'Dependency=Location Region', 'rval']).set_index('siteid')
    
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
                rval_area.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Region'], rvalkey[framedwall.framedinslvl]))
        
    return pd.DataFrame(rval_area, columns=['siteid', 'created', 'object', 'Dependency=Vintage', 'Dependency=Location Region', 'rval']).set_index('siteid')

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
                found_type.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Region'], foundtypekey[row.object.sfmasterhousegeometry.sffoundation]))
            except:
                if row.object.sfmasterhousegeometry.sffoundation == 'Mixed crawl and slab':
                    found_type.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Region'], 'Crawl'))
                    found_type.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Region'], 'Slab'))
                elif row.object.sfmasterhousegeometry.sffoundation == 'Mixed crawl and conditioned basement':
                    found_type.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Region'], 'Crawl'))
                    found_type.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Region'], 'Heated Basement'))
                elif row.object.sfmasterhousegeometry.sffoundation == 'Mixed crawl and unconditioned basement':
                    found_type.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Region'], 'Crawl'))
                    found_type.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Region'], 'Unheated Basement'))                                        

    return pd.DataFrame(found_type, columns=['siteid', 'created', 'object', 'Dependency=Vintage', 'Dependency=Location Region', 'Dependency=Geometry Foundation Type']).set_index('siteid')

def assign_size(df):
    
    def size(sfmasterhousegeometry):
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
            elif size >= 3500 and size < 4500:
                return '3500-4499'
            else:
                assert size >= 4500
                return '4500+'
        
    df['Dependency=Geometry House Size'] = df.apply(lambda x: size(x.object.sfmasterhousegeometry), axis=1)
    df = df.dropna(subset=['Dependency=Geometry House Size'])    

    return df

def assign_stories(df):
    
    storieskey = {'1': '1',
                  '1.5': '2',
                  '2': '2',
                  '2.5': '3+',
                  '3+': '3+'}
        
    df['Dependency=Stories'] = df.apply(lambda x: storieskey[x.object.sfmasterhousegeometry.sffloors], axis=1)
    df = df.dropna(subset=['Dependency=Stories'])
    
    return df

def assign_htgsp(df):
    
    def temp(t):
        if t is None:
            return None
        if t <= 62:
            return '60F'
        elif t >= 63 and t <= 66:
            return '65F'
        elif t in [67, 68] or (t == 69 and random.choice([True, False])):
            return '68F'
        elif t in [69, 70] or (t == 71 and random.choice([True, False])):
            return '70F'
        elif t in [71, 72, 73]:
            return '72F'
        elif t >= 74:
            return '75F'
        else:
            print t 
    
    df['htgsp'] = df.apply(lambda x: temp(x.object.sfriheu.resintheattemp), axis=1)
    df = df.dropna(subset=['htgsp'])

    return df

def assign_clgsp(df):
    
    def temp(t):
        if t is None:
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
                    rval_area.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Region'], row['Dependency=Geometry Foundation Type'], 'None'))                
                else:
                    if slab.uslabperimfloor >= 0.73:
                        rval_area.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Region'], row['Dependency=Geometry Foundation Type'], 'Uninsulated'))
                    elif slab.uslabperimfloor > 0.67 and slab.uslabperimfloor < 0.73:
                        rval_area.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Region'], row['Dependency=Geometry Foundation Type'], '4ft R5 Perimeter, R5 Gap'))
                    elif slab.uslabperimfloor <= 0.67:
                        rval_area.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Region'], row['Dependency=Geometry Foundation Type'], 'R10 Whole Slab, R5 Gap'))

    return pd.DataFrame(rval_area, columns=['siteid', 'created', 'object', 'Dependency=Vintage', 'Dependency=Location Region', 'Dependency=Geometry Foundation Type', 'rval']).set_index('siteid')

def assign_crawl(df):
    
    rval_area = []
    for index, row in df.iterrows():
        for crawl in row.object.sfflcrawl:
            if crawl.ucrawlfloor is not None and crawl.ucrawlwall is not None:
                if row['Dependency=Geometry Foundation Type'] != 'Crawl':
                    rval_area.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Region'], row['Dependency=Geometry Foundation Type'], 'None'))
                else:
                    if crawl.ucrawlfloor >= 0.23 and crawl.ucrawlwall <= 3.1:
                        rval_area.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Region'], row['Dependency=Geometry Foundation Type'], 'Uninsulated, Vented'))
                    elif crawl.ucrawlfloor >= 0.23 and crawl.ucrawlwall > 3.1 and crawl.ucrawlwall <= 5.0:
                        rval_area.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Region'], row['Dependency=Geometry Foundation Type'], 'Uninsulated, Unvented'))
                    elif crawl.ucrawlfloor >= 0.23 and crawl.ucrawlwall > 5.0:
                        rval_area.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Region'], row['Dependency=Geometry Foundation Type'], 'Wall R-13, Unvented'))
                    elif crawl.ucrawlfloor < 0.23 and crawl.ucrawlfloor > 0.06:
                        rval_area.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Region'], row['Dependency=Geometry Foundation Type'], 'Ceiling R-13, Vented'))
                    elif crawl.ucrawlfloor <= 0.06 and crawl.ucrawlfloor >= 0.04:
                        rval_area.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Region'], row['Dependency=Geometry Foundation Type'], 'Ceiling R-19, Vented'))
                    elif crawl.ucrawlfloor < 0.04:
                        rval_area.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Region'], row['Dependency=Geometry Foundation Type'], 'Ceiling R-30, Vented'))

    return pd.DataFrame(rval_area, columns=['siteid', 'created', 'object', 'Dependency=Vintage', 'Dependency=Location Region', 'Dependency=Geometry Foundation Type', 'rval']).set_index('siteid')

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
                            rval_area.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Region'], row['Dependency=Geometry Foundation Type'], 'None'))
                        else:
                            rval_area.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Region'], row['Dependency=Geometry Foundation Type'], ceilinstypekey[bsmt.basementfloorinsulation]))
                    else:
                        if row['Dependency=Geometry Foundation Type'] != 'Unheated Basement':
                            rval_area.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Region'], row['Dependency=Geometry Foundation Type'], 'None'))                            
                        else:
                            rval_area.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Region'], row['Dependency=Geometry Foundation Type'], 'Uninsulated'))                    
                else:
                    if row['Dependency=Geometry Foundation Type'] != 'Unheated Basement':
                        rval_area.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Region'], row['Dependency=Geometry Foundation Type'], 'None'))                        
                    else:
                        rval_area.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Region'], row['Dependency=Geometry Foundation Type'], 'Uninsulated'))

    return pd.DataFrame(rval_area, columns=['siteid', 'created', 'object', 'Dependency=Vintage', 'Dependency=Location Region', 'Dependency=Geometry Foundation Type', 'rval']).set_index('siteid')

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
                            rval_area.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Region'], row['Dependency=Geometry Foundation Type'], 'None'))
                        else:
                            rval_area.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Region'], row['Dependency=Geometry Foundation Type'], wallinstypekey[bsmt.basementfloorinsulation]))
                    else:
                        if row['Dependency=Geometry Foundation Type'] != 'Heated Basement':
                            rval_area.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Region'], row['Dependency=Geometry Foundation Type'], 'None'))                        
                        else:
                            rval_area.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Region'], row['Dependency=Geometry Foundation Type'], 'Uninsulated'))
                else:
                    if row['Dependency=Geometry Foundation Type'] != 'Heated Basement':
                        rval_area.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Region'], row['Dependency=Geometry Foundation Type'], 'None'))                    
                    else:
                        rval_area.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Region'], row['Dependency=Geometry Foundation Type'], 'Uninsulated'))

    return pd.DataFrame(rval_area, columns=['siteid', 'created', 'object', 'Dependency=Vintage', 'Dependency=Location Region', 'Dependency=Geometry Foundation Type', 'rval']).set_index('siteid')

def assign_intfloor(df):
    
    rval_area = []
    for index, row in df.iterrows():
        for intfloor in row.object.sfflooroverarea:
            if intfloor.uoverareafloor is not None:
                if intfloor.uoverareafloor >= 0.23:
                    rval_area.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Region'], 'Uninsulated'))
                elif intfloor.uoverareafloor > 0.04 and intfloor.uoverareafloor < 0.23:
                    rval_area.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Region'], 'R-13'))
                elif intfloor.uoverareafloor <= 0.04:
                    rval_area.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Region'], 'R-19'))

    return pd.DataFrame(rval_area, columns=['siteid', 'created', 'object', 'Dependency=Vintage', 'Dependency=Location Region', 'rval']).set_index('siteid')

def assign_win(df):
    
    rval_area = []
    for index, row in df.iterrows():
        for win in row.object.sfwindow:
            if win.uwindow is not None:
                if win.uwindow in [1.1]:
                    rval_area.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Region'], 'Clear, Single, Metal'))
                elif win.uwindow in [0.9, 0.95]:
                    rval_area.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Region'], 'Clear, Single, Non-metal'))
                elif win.uwindow in [0.8, 0.85]:
                    rval_area.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Region'], 'Clear, Double, Metal, Air'))
                elif win.uwindow in [0.75]:
                    rval_area.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Region'], 'Clear, Double, Thermal-Break, Air'))
                elif win.uwindow in [0.55, 0.6, 0.65, 0.7]:
                    rval_area.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Region'], 'Clear, Double, Non-metal, Air'))
                elif win.uwindow in [0.4, 0.45, 0.5]:
                    rval_area.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Region'], 'Low-E, Double, Non-metal, Air, M-Gain'))
                elif win.uwindow in [0.22, 0.35]:
                    rval_area.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Region'], 'Low-E, Triple, Non-metal, Air, L-Gain'))
                else:
                    print index, win.uwindow

    return pd.DataFrame(rval_area, columns=['siteid', 'created', 'object', 'Dependency=Vintage', 'Dependency=Location Region', 'rval']).set_index('siteid')

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
                       'MSHP': ', 60% Conditioned'}
    
    htg_and_clg = []
    for index, row in df.iterrows():
        htg = 'None'
        clg = 'None'
        htg_sys = None
        clg_sys = None
        for eq in row.object.hvacheating:
            if eq.hvacprimary:
                if eq.hvactype in ['heatpump', 'heatpumpdualfuel', 'gshp']:
                    if eq.hspf:
                        htg = round(eq.hspf * 2) / 2 # nearest half integer
                    htg_sys = 'ASHP'
                elif eq.hvactype in ['dhp']:
                    htg = 9.6
                    htg_sys = 'MSHP'
        for eq in row.object.hvaccooling:
            if eq.hvacprimarycooling:
                if eq.hvactype in ['heatpump', 'heatpumpdualfuel', 'gshp']:
                    if eq.seer:
                        clg = round(eq.seer * 2) / 2 # nearest half integer
                    clg_sys = 'ASHP'
                elif eq.hvactype in ['dhp']:
                    clg = 18.0
                    clg_sys = 'MSHP'
        if not row['Dependency=Heating Fuel'] =='Electricity':
            htg_and_clg.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Region'], row['Dependency=Heating Fuel'], 'None'))
        else:
            if not htg == 'None' and not clg == 'None':
                assert htg_sys == clg_sys
                try:
                    htg_and_clg.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Region'], row['Dependency=Heating Fuel'], '{type}, SEER {clg}, {htg} HSPF{cond}'.format(type=htg_sys, htg=htg, clg={7: 10.3, 7.5: 11.5, 8: 13, 8.5: 14.3, 9: 16}[htg], cond=conditioned_key[htg_sys])))
                except:
                    htg_and_clg.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Region'], row['Dependency=Heating Fuel'], '{type}, SEER {clg}, {htg} HSPF{cond}'.format(type=htg_sys, htg=htg, clg=clg, cond=conditioned_key[htg_sys])))
            elif not htg == 'None':
                htg_and_clg.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Region'], row['Dependency=Heating Fuel'], '{type}, SEER {clg}, {htg} HSPF{cond}'.format(type=htg_sys, htg=htg, clg={7: 10.3, 7.5: 11.5, 8: 13, 8.5: 14.3, 9: 16}[htg], cond=conditioned_key[htg_sys])))
            elif not clg == 'None':
                if clg_sys == 'MSHP':
                    htg_and_clg.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Region'], row['Dependency=Heating Fuel'], '{type}, SEER {clg}, 9.6 HSPF{cond}'.format(type=clg_sys, clg=clg, cond=conditioned_key[clg_sys])))
            else:
                htg_and_clg.append((index, row.created, row.object, row['Dependency=Vintage'], row['Dependency=Location Region'], row['Dependency=Heating Fuel'], 'None'))

    return pd.DataFrame(htg_and_clg, columns=['siteid', 'created', 'object', 'Dependency=Vintage', 'Dependency=Location Region', 'Dependency=Heating Fuel', 'htg_and_clg']).set_index('siteid')

def assign_hvac_system_is_combined(df, col):
    def hvac_system_is_combined(sys):
        if 'ASHP' in sys or 'MSHP' in sys:
            return 'Yes'
        return 'No'
    
    df['Dependency=HVAC System Is Combined'] = df[col].apply(lambda x: hvac_system_is_combined(x))

    return df    

def assign_hvac_system_heating(df):
    
    fueltypekey = {'Electric': 'Electric',
                   'Gas': 'Gas',
                   'Oil/Kerosene': 'Oil',
                   'Propane': 'Propane',
                   'Wood': 'Other Fuel',
                   'Other': 'Other Fuel',
                   'Oil': 'Oil',
                   'Pellets': 'Other'}   
    
    def htg(hvacheating, htg_and_clg):
        if htg_and_clg != 'None':
            return 'None'
        for eq in hvacheating:
            if eq.hvacprimary:
                if eq.hvactype is not None:
                    if eq.hvactype == 'faf':
                        if not eq.hvacfuel:
                            continue
                        if fueltypekey[eq.hvacfuel] == 'Electric':
                            return 'Electric Furnace'
                        else:
                            if eq.combeffic is not None:
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

                    elif eq.hvactype == 'boiler':
                        if not eq.hvacfuel:
                            continue
                        if fueltypekey[eq.hvacfuel] == 'Electric':
                            return 'Electric Boiler'
                        else:
                            if eq.combeffic is not None:
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
        
                    elif eq.hvactype in ['baseboard', 'pluginheater']:
                        return 'Electric Baseboard'
        return 'None'
        
    df['htg'] = df.apply(lambda x: htg(x.object.hvacheating, x.htg_and_clg), axis=1)
    df = df.dropna(subset=['htg'])
    
    return df
    
def assign_hvac_system_cooling(df):
        
    def clg(object, htg_and_clg):
        if htg_and_clg != 'None':
            return 'None'        
        for eq in object.hvaccooling:
            if eq.hvacprimarycooling:
                if eq.hvactype is not None:
                    if eq.hvactype in ['centralAC']:
                        if eq.seer < 9:
                            return 'AC, SEER 8'
                        elif eq.seer >= 9 and eq.seer < 11.5:
                            return 'AC, SEER 10'
                        elif eq.seer >= 11.5 and eq.seer < 14:
                            return 'AC, SEER 13'
                        else:
                            assert eq.seer >= 14
                            return 'AC, SEER 15'

                    elif eq.hvactype in ['windowshaker', 'PTAC']:
                        if eq.unitacdaysofuse < 10:
                            return 'None'
                        energy_multiplier = int(10 * round(float(eq.unitacquantity * 100/ ( object.sfmasterhousegeometry.summarynumberofroomscalculated - object.sfricustdat.resintbath )) / 10))                        
                        if 'Room AC, EER 9.8, {}% Conditioned'.format(energy_multiplier) in ['Room AC, EER 9.8, 40% Conditioned', 'Room AC, EER 9.8, 50% Conditioned', 'Room AC, EER 9.8, 60% Conditioned', 'Room AC, EER 9.8, 70% Conditioned']:
                            return 'Room AC, EER 9.8, 50% Conditioned'
                        else:
                            return 'Room AC, EER 9.8, {}% Conditioned'.format(energy_multiplier)
                    
        return 'None'
    
    df['clg'] = df.apply(lambda x: clg(x.object, x.htg_and_clg), axis=1)
    df = df.dropna(subset=['clg'])
    
    return df

def assign_ducts(df):
    
    sfductsRval = {'R0': 'Uninsulated',
                   'R2-R4': 'R-4',
                   'R7-R11': 'R-8',
                   'R4 Flex': 'R-4',
                   'R6 Flex': 'R-6',
                   'R8 Flex': 'R-8',
                   'R0 Metal; R4 Flex': 'R-4',
                   'R0 Metal; R6 Flex': 'R-4',
                   'R0 Metal; R8 Flex': 'R-4',
                   'R2-R4 Metal; R4 Flex': 'R-4',
                   'R2-R4 Metal; R6 Flex': 'R-4',
                   'R2-R4 Metal; R8 Flex': 'R-6',
                   'R7-R11 Metal; R4 Flex': 'R-8',
                   'R7-R11 Metal; R6 Flex': 'R-8',
                   'R7-R11 Metal; R8 Flex': 'R-8',
                   '1" Ductboard': 'R-4',
                   '2" Ductboard': 'R-8',
                   '1" Ductboard; R4 Flex': 'R-4',
                   '1" Ductboard; R6 Flex': 'R-6',
                   '1" Ductboard; R8 Flex': 'R-8',
                   '2" Ductboard; R4 Flex': 'R-4',
                   '2" Ductboard; R6 Flex': 'R-6'}
    
    def ductrval(sfducts):
        if len(sfducts) == 0:
            pass
        for ducts in sfducts:
            if ducts.ductinsulationtype:
                return sfductsRval[ducts.ductinsulationtype]
            else:
                return 'Uninsulated' # FIXME: Change to 'None'
            
    def ductleak(sfducttesting_dbase):
        if len(sfducttesting_dbase) == 0:
            return 'In Finished Space'
        for ducts in sfducttesting_dbase:
            if ducts.slfhalfplen or ducts.rlfhalfplen:
                try:
                    frac = (ducts.slfhalfplen + ducts.rlfhalfplen)
                except: # FIXME: Incorrect assumption that NULL is zero
                    try:
                        frac = ducts.slfhalfplen
                    except:
                        try:
                            frac = ducts.slfhalfplen
                        except:
                            pass
                if frac < .0875:
                    return '7.5% Leakage'
                elif frac >= .0875 and frac < .125:
                    return '10% Leakage'
                elif frac >= .125 and frac < .175:
                    return '15% Leakage'
                elif frac >= .175 and frac < .25:
                    return '20% Leakage'
                elif frac >= .25:
                    return '30% Leakage'
            else:
                return 'In Finished Space' # FIXME: Change to 'None'
    
    def ductname(rval, leak):
        if rval == 'None':
            return 'None'
        elif not leak == 'In Finished Space':
            return '{leak}, {rval}'.format(leak=leak, rval=rval)
        else:
            return 'In Finished Space' # FIXME: Change to 'None'

    df['ductrval'] = df.apply(lambda x: ductrval(x.object.sfducts), axis=1)
    df['ductleak'] = df.apply(lambda x: ductleak(x.object.sfducttestingdbase), axis=1)
    df = df.dropna(subset=['ductleak'])
    df['ducts'] = df.apply(lambda x: ductname(x['ductrval'], x['ductleak']), axis=1)

    return df    
    
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
                   'Propane': 'Propane',
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
    
