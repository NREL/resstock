"""
Purpose: 
Estimate energy savings using EUSS 2018 AMY results
Results available for download as a .csv here:
https://data.openei.org/s3_viewer?bucket=oedi-data-lake&prefix=nrel-pds-building-stock%2Fend-use-load-profiles-for-us-building-stock%2F2022%2Fresstock_amy2018_release_1%2Fmetadata_and_annual_results%2Fnational%2Fcsv%2F

Estimate average energy savings by state and by technology improvement
State excludes Hawaii and Alaska, Tribal lands, and territories
Technology improvements are gradiented by 10 options
More information can be found here:
https://oedi-data-lake.s3.amazonaws.com/nrel-pds-building-stock/end-use-load-profiles-for-us-building-stock/2022/EUSS_ResRound1_Technical_Documentation.pdf

Created by: Katelyn Stenger @NREL
Created on: Oct 4, 2022
"""

#import packages
import pandas as pd
import numpy as np
import os

#set working directory
default_dir = "/Users/kstenger/Documents/220930_IRA_Estimation/IRA Rebate Estimates"

## Results and Data

# load EUSS results
df_EUSS_base = pd.read_csv("baseline_metadata_and_annual_results.csv") # baseline means buildings stock as is
df_EUSS_up1 = pd.read_csv("upgrade01_metadata_and_annual_results.csv") # basic enclosure package
df_EUSS_up2 = pd.read_csv("upgrade02_metadata_and_annual_results.csv") #enhanced enclosure package
df_EUSS_up3 = pd.read_csv("upgrade03_metadata_and_annual_results.csv") # heat pumps, min-efficiency, electric backup
df_EUSS_up4 = pd.read_csv("upgrade04_metadata_and_annual_results.csv") # heat pumps, high-efficiency, electric backup
df_EUSS_up5 = pd.read_csv("upgrade05_metadata_and_annual_results.csv") # heat pumps, min-effi., existing heating as backup
df_EUSS_up6 = pd.read_csv("upgrade06_metadata_and_annual_results.csv") # heat pump water heaters
df_EUSS_up7 = pd.read_csv("upgrade07_metadata_and_annual_results.csv") # whole-home electrification, min eff.
df_EUSS_up8 = pd.read_csv("upgrade08_metadata_and_annual_results.csv") # whole-home electrification, max eff.
df_EUSS_up9 = pd.read_csv("upgrade09_metadata_and_annual_results.csv") # whole-home electrification, high eff. + basic enclosure package
df_EUSS_up10 = pd.read_csv("upgrade10_metadata_and_annual_results.csv") # whole-home electrification, high eff. + enhanced enclosure package

#load utility bill costs
df_elec_costs = pd.read_csv("Variable Elec Cost by State from EIA State Data.csv") # $/kWhr
df_ng_costs = pd.read_csv('NG costs by state.csv') # $/therm
df_fo_costs = pd.read_csv('Fuel Oil Prices Averaged by State.csv') # $/gallon
df_lp_costs = pd.read_csv('Propane costs by state.csv') # $/gallon

## define constants

# Source of utility data and year
elec_source = 'EIA (Utility Rate Database), 2019'
ng_source = 'American Gas Association, 2019'
fo_source = 'EIA, 2019'
lp_source = 'EIA, 2019'

# Conversion from source unit to Btu (currently)
# TODO: what kind of conversion do we need?
# TODO: may need in kWh since all EUSS results are in kWh.
btu_propane_in_one_gallon = 91452 #source: https://www.eia.gov/energyexplained/units-and-calculators/
gallons_to_barrels = 42 #source: https://www.eia.gov/energyexplained/units-and-calculators/
btu_fueloil_in_one_barrel = 6287000 #source: https://www.eia.gov/energyexplained/units-and-calculators/

##define functions

# choose results columns to work with for EUSS and Fuel data

## EUSS Consumption at Baseline (before upgrades)
# TODO: building types: water heating or space heating - ask for help on?
before_selected_cols = [
    'building_id', 
    'in.state', # location
    'in.tenure', # owner v. renter
    'in.geometry_building_type_recs', # single v. multifamily v mobile home (TODO: convert mobile home to single?)
    'out.site_energy.total.energy_consumption.kwh', # total energy
    'out.electricity.total.energy_consumption.kwh', # electric total
    'out.fuel_oil.total.energy_consumption.kwh', # fuel oil total
    'out.natural_gas.total.energy_consumption.kwh' #natural gas total
    'out.propane.total.energy_consumption.kwh', # propane total
    'out.emissions.all_fuels.lrmer_low_re_cost_25_2025_start.co2e_kg' # emissions - least controversial approach
    ]
def before_downselect_cols(df):
    df = df[before_selected_cols]
    return df

## EUSS Upgrade results
after_selected_cols = [
    'building_id', 
    'out.site_energy.total.energy_consumption.kwh', # total energy
    'out.electricity.total.energy_consumption.kwh', # electric total
    'out.fuel_oil.total.energy_consumption.kwh', # fuel oil total
    'out.natural_gas.total.energy_consumption.kwh' #natural gas total
    'out.propane.total.energy_consumption.kwh', # propane total
    'out.emissions.all_fuels.lrmer_low_re_cost_25_2025_start.co2e_kg' # emissions - least controversial approach
    ]
def after_downselect_cols(df):
    df = df[after_selected_cols]
    return df


#calculate total energy difference for each upgrade, for each home, add to the mini dataframes
def calc_delta_energy(df_baseline, df_upgrade):
    return (df_baseline['out.site_energy.total.energy_consumption.kwh']-df_upgrade['out.site_energy.total.energy_consumption.kwh'])
def calc_delta_elec(df_baseline, df_upgrade):
    return (df_baseline['out.electricity.total.energy_consumption.kwh']-df_upgrade['out.electricity.total.energy_consumption.kwh'])
def calc_delta_fo(df_baseline, df_upgrade):
    return (df_baseline['out.fuel_oil.total.energy_consumption.kwh']-df_upgrade['out.fuel_oil.total.energy_consumption.kwh'])
def calc_delta_ng(df_baseline, df_upgrade):
    return (df_baseline['out.natural_gas.total.energy_consumption.kwh']-df_upgrade['out.natural_gas.total.energy_consumption.kwh'])
def calc_delta_lp(df_baseline, df_upgrade):
    return (df_baseline['out.propane.total.energy_consumption.kwh']-df_upgrade['out.propane.total.energy_consumption.kwh'])
def calc_delta_emission(df_baseline, df_upgrade):
    return (df_baseline['out.emissions.all_fuels.lrmer_low_re_cost_25_2025_start.co2e_kg']-df_upgrade['out.emissions.all_fuels.lrmer_low_re_cost_25_2025_start.co2e_kg'])

# Create baseline dataframe 
df_EUSS_base = before_downselect_cols(df_EUSS_base)

"""
# TODO: Still need to figure this section out
# This is based off of 'Facades Economic Analysis for Sharing.py

#add utility bill cost information to the baseline results
results_b = pd.merge(df_EUSS_base, df_elec_costs[['State', 'Variable Elec Cost $/kWh']], left_on = "build_existing_model.state", right_on = 'State', how = 'left')
results_b = results_b.drop(['State'], 1)
results_b = pd.merge(results_b, df_ng_costs[['State', 'NG Cost without Meter Charge [$/therm]']], left_on = "build_existing_model.state", right_on = 'State', how = 'left')
results_b = results_b.drop(['State'], 1)
results_b = pd.merge(results_b, df_fo_costs[['State', 'Average FO Price [$/gal]']], left_on = "build_existing_model.state", right_on = 'State', how = 'left')
results_b = results_b.drop(['State'], 1)
results_b = pd.merge(results_b, df_lp_costs[['State', 'Average Weekly Cost [$/gal]']], left_on = "build_existing_model.state", right_on = 'State', how = 'left')
results_b = results_b.drop(['State'], 1)
results_b.rename(columns={
    'Variable Elec Cost $/kWh': 'Elec Variable Cost [$/kWh]',
    'NG Cost without Meter Charge [$/therm]': 'NG Variable Cost [$/therm]', 
    'Average FO Price [$/gal]': 'FO Average Cost [$/gal]',
    'Average Weekly Cost [$/gal]': 'LP Average Price [$/gal]'},
    inplace=True)

##Set up and run things!
#number of upgrade packages
num_ups = 9
up_start = "up"

for i in range(1, num_ups+1):
    if i<10:
        upnum = str(i)
    else:
        upnum = str(i)
    df_name = "df_EUSS_up" + upnum
    upgrade = up_start + upnum
    df = after_downselect_cols(df_name)
    #calculate changes in energy use for each fuel
    delta_elec = calc_delta_elec(df_EUSS_base, df)
    results_b[upgrade + "_delta_elec_kWh"] = delta_elec
    delta_ng = calc_delta_ng(df_EUSS_base, df)
    results_b[upgrade + "_delta_ng_kWh"] = delta_ng
    delta_fo = calc_delta_fo(df_EUSS_base, df)
    results_b[upgrade + "_delta_fo_kWh"] = delta_fo
    delta_lp = calc_delta_lp(df_EUSS_base, df)
    results_b[upgrade + "_delta_lp_kWh"] = delta_lp
    delta_energy = calc_delta_energy(df_EUSS_base, df)
    results_b[upgrade + "_delta_allfuels_kWh"] = delta_energy
    delta_energy = calc_delta_emission(df_EUSS_base, df)
    results_b[upgrade + "_delta_emissions_C02e_kg"] = delta_energy


#save results
# results_b.to_csv('results_with_economics_allfuels.csv')
"""
