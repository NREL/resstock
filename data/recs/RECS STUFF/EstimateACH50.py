'''
Created on Apr 23, 2014
@author: ewilson
'''
import sql_query_recs_V2 as recs
from math import exp, trunc
import os, sys
import pandas as pd
sys.path.insert(0, os.path.join(os.getcwd(),'clustering'))

regions = {'CR01':'7',
           'CR02':'6A',
           'CR03':'5B',
           'CR04':'5A',
           'CR05':'5A',
           'CR06':'4C',
           'CR07':'4A',
           'CR08':'4A',
           'CR09':'2A',
           'CR10':'2B',
           'CR11':'3B',
           'CR12':'1A'}

vintages = {'pre-1950': 1955, # pre 1960 is identical
            '1950s':   1955,
            '1960s':   1965,
            '1970s':   1975,
            '1980s':   1985,
            '1990s':   1995,
            '2000s':   2005}

sizes = {'0-1499':1024, #Used Weighted Median Floor Area
         '1500-2499':1901.72,
         '2500-3499':2886.275,
         '3500+':4624.878,}

stories = {'1':1,
           '2+':2,}

def EstimatedACH50(YearBuilt,Climate,Area,Height,LowIncome,EnergyEfficient,Volume):
    # Coded by Dennis Barley, July 2013.
    # This routine calculates the estimated air leakage area of an existing home,
    #   based on a multivariate regression analysis presented by Chan et al.
    #   [LBNL-5966E, August 2012; Eqn. 2 and Table 1].
    # PARAMETERS:
    #   Age = Age of existing home, yr
    #   Climate: IECC climate zone, ranging from A1-A7, B2-B6, C3-C4, or AK7-AK8
    #   Area   = Floor area, ft2
    #   Height = House height, ft
    #   LowIncome       = true or false
    #   EnergyEfficient = true or false
    #   Volume = volume of conditioned space, ft3
    # Convert age of house to vintage coefficient (Cv):
    V = trunc(YearBuilt/10.) - 194  # V is vintage index
    if V<1: V=1
    if V>6: V=6
    Cvs = [-0.25, -0.433, -0.452, -0.654, -0.915, -1.058]
    Cv = Cvs[V-1]

    # Identify climate zone and coefficient (Cc):
    # Note: Combined 7A and 7AK into the single IECC 7 climate zone

    Climates = ['1A', '2A', '3A', '4A', '5A', '6A', '7',  '2B',  '3B',  '4B',  '5B',  '6B', '3C', '4C', '8']

#     Ccs =      [0.473,0.473,0.253,0.326,0.112,  0,   0.013,-0.038,-0.038,-0.009,-0.009,0.019,0.048,0.258,-0.512]

    Ccs =      [0.473,0.473,0.253,0.326,0.112,  0,  0.013,0.473,0.253,0.326,0.112,     0,  0.253,0.326,-0.512]

    if Climate in Climates:
        C = Climates.index(Climate)
        Cc = Ccs[C]
    else:
        raise('In EstimatedCFM50, Climate variable is not in the list')

    # Coefficients for low income and energy-efficient homes:
    Cli = 0
    if LowIncome: Cli = 0.42
    Cee = 0
    if EnergyEfficient: Cee = -0.384

    # Convert area and height to metric units:

    H = Height*0.3048   # meters
    A = Area*(0.09290)  # square meters

    # Apply regression formula

    LogNL = A*(-0.00208) + H*(0.064) + Cv + Cli + Cee + Cc
    NL = exp(LogNL)
    ELA = NL/1000.*144.*Area/(Height/8.)**0.3
    CFM50 = ELA / 0.05486
    ACH50 = CFM50 * 60. / Volume

    mindiff = 99999
    for option in [25,20,15,10,8,7,6,5,4,3,2,1]:
        if abs(ACH50 - option) < mindiff:
            ach50_bin = option
            mindiff = abs(ACH50 - option)

    return ACH50, CFM50, ELA, NL, ach50_bin

df = pd.DataFrame()

Region, Vintage_Bin, Size_Bin, Story_Bin, ACH50_Value, ACH50_Bin = ([] for i in range(6))


if __name__ == '__main__':
    for region, cz in regions.iteritems():
        for vintage_bin, year in vintages.iteritems():
            for size_bin, area in sizes.iteritems():
                for story_bin, story_num in stories.iteritems():
                    ACH50, CFM50, ELA, NL, ach50_bin = EstimatedACH50(year, cz, area, story_num*8, False, False, area*8)
                    Region.append(region)
                    Vintage_Bin.append(vintage_bin)
                    Size_Bin.append(size_bin)
                    Story_Bin.append(story_bin)
                    ACH50_Value.append(ACH50)
                    ACH50_Bin.append(str(ach50_bin))
    data = {'Region':Region,'Vintage':Vintage_Bin,'Size':Size_Bin,'Stories':Story_Bin,'ACH50':ACH50_Value,'ACH50_Bin':ACH50_Bin}

    g = pd.DataFrame(data)
    g = g[['Region','Vintage','Size','Stories','ACH50_Bin','ACH50']]
    g = g.pivot_table(index=['Region','Vintage','Size','Stories','ACH50_Bin']).unstack('ACH50_Bin').reset_index()
    g.to_csv(os.path.join("RECS_Outputs_TSV", 'Infiltration.tsv'), sep='\t', index=False)
