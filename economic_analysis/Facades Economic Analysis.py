#import packages
import pandas as pd
import numpy as np
import os

#set working directory
default_dir = "C:/Users/EPRESENT/Documents/Mini Projects/Facades/ResStock Results/test10No3"

#load utility bill costs
df_elec_costs = pd.read_csv("C:/Users/EPRESENT/Documents/Mini Projects/Facades/Economic Analysis/Variable Elec Cost by State from EIA State Data.csv")
df_ng_costs = pd.read_csv('C:/Users/EPRESENT/Documents/Load Shapes Project/Modeling and Calibration/Calculating Utility Bills/NG costs by state.csv')
df_fo_costs = pd.read_csv('C:/Users/EPRESENT/Documents/Load Shapes Project/Modeling and Calibration/Calculating Utility Bills/Fuel Oil Prices Averaged by State.csv')
df_lp_costs = pd.read_csv('C:/Users/EPRESENT/Documents/Load Shapes Project/Modeling and Calibration/Calculating Utility Bills/Propane costs by state.csv')

 
##define functions

#choose results columns to work with
selected_cols = [
    'building_id', 
    'simulation_output_report.total_site_electricity_kwh', 
    'simulation_output_report.total_site_natural_gas_therm',
    'simulation_output_report.total_site_fuel_oil_mbtu',
    'simulation_output_report.total_site_propane_mbtu',
    'simulation_output_report.upgrade_cost_usd']
def downselect_cols(df):
	df = df[selected_cols]
	return df

#calculate total energy difference for each upgrade, for each home, add to the mini dataframes
def calc_delta_elec(df_upgrade, df_baseline):
	return (df_upgrade['simulation_output_report.total_site_electricity_kwh']-df_baseline['simulation_output_report.total_site_electricity_kwh'])
def calc_delta_ng(df_upgrade, df_baseline):
	return (df_upgrade['simulation_output_report.total_site_natural_gas_therm']-df_baseline['simulation_output_report.total_site_natural_gas_therm'])
def calc_delta_fo(df_upgrade, df_baseline):
	return (df_upgrade['simulation_output_report.total_site_fuel_oil_mbtu']-df_baseline['simulation_output_report.total_site_fuel_oil_mbtu'])
def calc_delta_lp(df_upgrade, df_baseline):
	return (df_upgrade['simulation_output_report.total_site_propane_mbtu']-df_baseline['simulation_output_report.total_site_propane_mbtu'])


#calculate year1 utility bill savings
def calc_year1_savings(var_util_costs, delta_elec):
	return (var_util_costs*delta_elec)

#calculate simple payback period
def calc_spp(upfront_cost, year1_savings):
	return(upfront_cost/year1_savings)

#calculate npv
analysis_period = 30
discount_rate = 0.034
def calc_npv(upfront_cost, year1_savings): #note: assuming 30 year lifetime for everything, which is not a general solution to this situation
	npv_list = []
	for cost, savings in zip(upfront_cost, year1_savings): #this loops through all the rows in the results_csv (ie each dwelling unit)
		cost_array = [0]*(analysis_period+1)
		cost_array[0] = cost
		savings_array = [savings] * (analysis_period+1)
		cash_flows = list(np.array(savings_array)-np.array(cost_array))
		npv = 0
		for year in range(0,analysis_period + 1):
			npv += (1/((1 + discount_rate) ** year)) * cash_flows[year]
		npv_list.append(npv)
	return npv_list

##Set up and run things!
#number of upgrade packages
num_ups = 4

#load baseline results
results_b = pd.read_parquet(os.path.join(default_dir, "results_up00.parquet"), engine = "auto")

#add utility bill cost unformation to the baseline results
results_b = pd.merge(results_b, df_elec_costs[['State', 'Variable Elec Cost $/kWh']], left_on = "build_existing_model.state", right_on = 'State', how = 'left')
results_b = pd.merge(results_b, df_ng_costs[['State', 'NG Cost without Meter Charge [$/therm]']], left_on = "build_existing_model.state", right_on = 'State', how = 'left')
results_b = pd.merge(results_b, df_fo_costs[['State', 'Average FO Price [$/gal]']], left_on = "build_existing_model.state", right_on = 'State', how = 'left')
results_b = pd.merge(results_b, df_lp_costs[['State', 'Average Weekly Cost [$/gal]']], left_on = "build_existing_model.state", right_on = 'State', how = 'left')


#define string parts for upgrades
file_start = "results_up"
file_end = ".parquet"
up_start = "up"

#do economic calculations for each upgrade package
for i in range(1, num_ups):
    if i<10:
        upnum = "0" + str(i)
    else:
        upnum = str(i)
    filename = file_start + upnum + file_end
    upgrade = up_start + upnum
    results_up = pd.read_parquet(os.path.join(default_dir, filename), engine = "auto")
    df = downselect_cols(results_up)
    delta_elec = calc_delta_elec(results_b, df)
    results_b[upgrade + "_delta_elec_kWh"] = delta_elec
    delta_ng = calc_delta_ng(results_b, df)
    results_b[upgrade + "_delta_ng_therms"] = delta_ng
    results_fo = calc_delta_fo(res)
    year1_savings = calc_year1_savings(delta_elec, results_b['Variable Elec Cost $/kWh'])
    results_b[upgrade + "_year1_util_bill_savings"] = year1_savings
    simple_payback_period = calc_spp(df['simulation_output_report.upgrade_cost_usd'], year1_savings)
    results_b[upgrade + "_simple_payback_period"] = simple_payback_period
    npv = calc_npv(df['simulation_output_report.upgrade_cost_usd'], year1_savings)
    results_b[upgrade + "_npv"] = npv

results_b.to_csv('results_with_economics.csv')