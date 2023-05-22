import pandas as pd

# local cost for cummunity
cost = pd.read_csv('data/cost_Sanjose.csv')
r30_cost1 = cost.iat[0, 1]
r30_cost2 = cost.iat[0, 3]
r49_cost1 = cost.iat[1, 1]
r49_cost2 = cost.iat[1, 3]
r60_cost1 = cost.iat[2, 1]
r60_cost2 = cost.iat[2, 3]
reduce_infil_30_cost = cost.iat[3, 1]
ducts1 = cost.iat[4, 1]
ducts2 = cost.iat[5, 1]
ducts3 = cost.iat[6, 1]
ducts4 = cost.iat[7, 1]
ducts5 = cost.iat[8, 1]
wall_r13 = cost.iat[9, 1]

wall_foundation = cost.iat[10, 1]
wall_basement = cost.iat[11, 1]
rim = cost.iat[12, 1]
crawlspaces = cost.iat[13, 1]
roof = cost.iat[14, 1]

ASHP_cost1 = cost.iat[15, 1]
ASHP_cost2 = cost.iat[15, 3]
MSHP_max_9_cost1 = cost.iat[16, 1]
MSHP_max_9_cost2 = cost.iat[16, 3]
ducted_MSHP_cost1 = cost.iat[17, 1]
ducted_MSHP_cost2 = cost.iat[17, 3]
ducted_HP_cost1 = cost.iat[18, 1]
ducted_HP_cost2 = cost.iat[18, 3]
MSHP_max_14_cost1 = cost.iat[19, 1]
MSHP_max_14_cost2 = cost.iat[19, 3]
MSHP_ele_baseboard_cost1 = cost.iat[20, 1]
MSHP_ele_baseboard_cost2 = cost.iat[20, 3]
MSHP_ele_boiler_cost1 = cost.iat[21, 1]
MSHP_ele_boiler_cost2 = cost.iat[21, 3]
MSHP_furnace_cost1 = cost.iat[22, 1]
MSHP_furnace_cost2 = cost.iat[22, 3]
MSHP_upgrade_cost1 = cost.iat[23, 1]
MSHP_upgrade_cost2 = cost.iat[23, 3]
furnace_cost1 = cost.iat[24, 1]
furnace_cost2 = cost.iat[24, 3]
ASHP_fossil_cost1 = cost.iat[25, 1]
ASHP_fossil_cost2 = cost.iat[25, 3]

WH_50 = cost.iat[26, 1]
WH_66 = cost.iat[27, 1]
WH_80 = cost.iat[28, 1]

HPWH_50 = cost.iat[29, 1]
HPWH_66 = cost.iat[30, 1]
HPWH_80 = cost.iat[31, 1]

dryer = cost.iat[32, 1]
ele_range = cost.iat[33, 1]

high_ducted_HP_cost1 = cost.iat[34, 1]
high_ducted_HP_cost2 = cost.iat[34, 3]
high_ductless_HP_cost1 = cost.iat[35, 1]
high_ductless_HP_cost2 = cost.iat[35, 3]
dryer_HP = cost.iat[36, 1]
induction_range = cost.iat[37, 1]

ele_price = cost.iat[38, 1] #c/kWh
ele_month_fix = cost.iat[38, 3] #$/month
gas_price = cost.iat[39, 1] #$/therm
gas_month_fix = cost.iat[39, 3] #$/month
propane_price = cost.iat[40, 1] #$/gal
propane_month_fix = cost.iat[40, 3] #$/month
oil_price = cost.iat[41, 1] #$/gal 
oil_month_fix = cost.iat[41, 3] #$/month


##data processing for up01
up01 = pd.read_csv('data/up01_sample.csv')

#Insulate ceiling to R-30
up01['option_01_Delta_R'] = (up01['upgrade_costs.option_01_cost_usd']-up01['upgrade_costs.floor_area_attic_ft_2']*0.1992)/up01['upgrade_costs.floor_area_attic_ft_2']/0.0443
up01.loc[up01['upgrade_costs.option_01_cost_usd'] > 0, 'upgrade_costs.option_01_cost_usd'] = r30_cost1*up01['upgrade_costs.floor_area_attic_ft_2']*up01['option_01_Delta_R']+r30_cost2*up01['upgrade_costs.floor_area_attic_ft_2']
#Insulate ceiling to R-49
up01['option_02_Delta_R'] = (up01['upgrade_costs.option_02_cost_usd']-up01['upgrade_costs.floor_area_attic_ft_2']*0.1992)/up01['upgrade_costs.floor_area_attic_ft_2']/0.0443
up01.loc[up01['upgrade_costs.option_02_cost_usd'] > 0, 'upgrade_costs.option_02_cost_usd'] = r49_cost1*up01['upgrade_costs.floor_area_attic_ft_2']*up01['option_02_Delta_R']+r49_cost2*up01['upgrade_costs.floor_area_attic_ft_2']
#Insulate ceiling to R-60
up01['option_03_Delta_R'] = (up01['upgrade_costs.option_03_cost_usd']-up01['upgrade_costs.floor_area_attic_ft_2']*0.1992)/up01['upgrade_costs.floor_area_attic_ft_2']/0.0443
up01.loc[up01['upgrade_costs.option_03_cost_usd'] > 0, 'upgrade_costs.option_03_cost_usd'] = r60_cost1*up01['upgrade_costs.floor_area_attic_ft_2']*up01['option_03_Delta_R']+r60_cost2*up01['upgrade_costs.floor_area_attic_ft_2']
#Reduce infiltration by 30%
up01.loc[up01['upgrade_costs.option_04_cost_usd'] > 0, 'upgrade_costs.option_04_cost_usd'] = reduce_infil_30_cost*up01['upgrade_costs.floor_area_conditioned_ft_2']
#Insulate and seal ducts a lot to have 10% leakage and R-8 ducts
up01.loc[up01['upgrade_costs.option_05_cost_usd'] > 0, 'upgrade_costs.option_05_cost_usd'] = ducts1*up01['upgrade_costs.duct_unconditioned_surface_area_ft_2']
#Seal ducts a lot to have 10% leakage, already has R-8 insulation
up01.loc[up01['upgrade_costs.option_06_cost_usd'] > 0, 'upgrade_costs.option_06_cost_usd'] = ducts2*up01['upgrade_costs.duct_unconditioned_surface_area_ft_2']
#Insulate and seal ducts some to have 10% leakage and R-8 ducts
up01.loc[up01['upgrade_costs.option_07_cost_usd'] > 0, 'upgrade_costs.option_07_cost_usd'] = ducts3*up01['upgrade_costs.duct_unconditioned_surface_area_ft_2']
#Seal ducts some to have 10% leakage, already has R-8 insulation
up01.loc[up01['upgrade_costs.option_08_cost_usd'] > 0, 'upgrade_costs.option_08_cost_usd'] = ducts4*up01['upgrade_costs.duct_unconditioned_surface_area_ft_2']
#Only insulate ducts to R-8, no sealing
up01.loc[up01['upgrade_costs.option_09_cost_usd'] > 0, 'upgrade_costs.option_09_cost_usd'] = ducts5*up01['upgrade_costs.duct_unconditioned_surface_area_ft_2']
#Insulation Wall|Wood Stud, R-13
up01.loc[up01['upgrade_costs.option_10_cost_usd'] > 0, 'upgrade_costs.option_10_cost_usd'] = wall_r13*up01['upgrade_costs.wall_area_above_grade_conditioned_ft_2']

#bill
up01.loc[up01['report_simulation_output.fuel_use_electricity_net_m_btu'] > 0, 'bill_electricity_USD'] = up01['report_simulation_output.fuel_use_electricity_net_m_btu']*0.293*ele_price*0.01+ele_month_fix*12
up01.loc[up01['report_simulation_output.fuel_use_electricity_net_m_btu'] == 0, 'bill_electricity_USD'] = 0
up01.loc[up01['report_simulation_output.fuel_use_natural_gas_total_m_btu'] > 0, 'bill_natural_gas_USD'] = up01['report_simulation_output.fuel_use_natural_gas_total_m_btu']*0.01*gas_price+gas_month_fix*12
up01.loc[up01['report_simulation_output.fuel_use_natural_gas_total_m_btu'] == 0, 'bill_natural_gas_USD'] = 0
up01.loc[up01['report_simulation_output.fuel_use_propane_total_m_btu'] > 0, 'bill_propane__USD'] = up01['report_simulation_output.fuel_use_propane_total_m_btu']*10.929*propane_price+propane_month_fix*12
up01.loc[up01['report_simulation_output.fuel_use_propane_total_m_btu'] == 0, 'bill_propane__USD'] = 0
up01.loc[up01['report_simulation_output.fuel_use_fuel_oil_total_m_btu'] > 0, 'bill_fuel_oil_USD'] = up01['report_simulation_output.fuel_use_fuel_oil_total_m_btu']*7.407*oil_price+oil_month_fix*12 # 7.407 is for Kerosene
up01.loc[up01['report_simulation_output.fuel_use_fuel_oil_total_m_btu'] == 0, 'bill_fuel_oil_USD'] = 0
up01['total_bill_USD'] = up01['bill_electricity_USD']+up01['bill_natural_gas_USD']+up01['bill_propane__USD']+up01['bill_fuel_oil_USD']

#total cost
up01.loc[up01['upgrade_costs.upgrade_cost_usd'] > 0, 'upgrade_costs.upgrade_cost_usd'] = up01['upgrade_costs.option_01_cost_usd'].fillna(0)+up01['upgrade_costs.option_02_cost_usd'].fillna(0)+up01['upgrade_costs.option_03_cost_usd'].fillna(0)+up01['upgrade_costs.option_04_cost_usd'].fillna(0)+up01['upgrade_costs.option_05_cost_usd'].fillna(0)+up01['upgrade_costs.option_06_cost_usd'].fillna(0)+up01['upgrade_costs.option_07_cost_usd'].fillna(0)+up01['upgrade_costs.option_08_cost_usd'].fillna(0)+up01['upgrade_costs.option_09_cost_usd'].fillna(0)+up01['upgrade_costs.option_10_cost_usd'].fillna(0)
up01.to_csv('results/up01.csv')


##data processing for up02
up02 = pd.read_csv('data/up02_sample.csv')

#Insulate ceiling to R-30
up02['option_01_Delta_R'] = (up02['upgrade_costs.option_01_cost_usd']-up02['upgrade_costs.floor_area_attic_ft_2']*0.1992)/up02['upgrade_costs.floor_area_attic_ft_2']/0.0443
up02.loc[up02['upgrade_costs.option_01_cost_usd'] > 0, 'upgrade_costs.option_01_cost_usd'] = r30_cost1*up02['upgrade_costs.floor_area_attic_ft_2']*up02['option_01_Delta_R']+r30_cost2*up02['upgrade_costs.floor_area_attic_ft_2']
#Insulate ceiling to R-49
up02['option_02_Delta_R'] = (up02['upgrade_costs.option_02_cost_usd']-up02['upgrade_costs.floor_area_attic_ft_2']*0.1992)/up02['upgrade_costs.floor_area_attic_ft_2']/0.0443
up02.loc[up02['upgrade_costs.option_02_cost_usd'] > 0, 'upgrade_costs.option_02_cost_usd'] = r49_cost1*up02['upgrade_costs.floor_area_attic_ft_2']*up02['option_02_Delta_R']+r49_cost2*up02['upgrade_costs.floor_area_attic_ft_2']
#Insulate ceiling to R-60
up02['option_03_Delta_R'] = (up02['upgrade_costs.option_03_cost_usd']-up02['upgrade_costs.floor_area_attic_ft_2']*0.1992)/up02['upgrade_costs.floor_area_attic_ft_2']/0.0443
up02.loc[up02['upgrade_costs.option_03_cost_usd'] > 0, 'upgrade_costs.option_03_cost_usd'] = r60_cost1*up02['upgrade_costs.floor_area_attic_ft_2']*up02['option_03_Delta_R']+r60_cost2*up02['upgrade_costs.floor_area_attic_ft_2']
#Reduce infiltration by 30%
up02.loc[up02['upgrade_costs.option_04_cost_usd'] > 0, 'upgrade_costs.option_04_cost_usd'] = reduce_infil_30_cost*up02['upgrade_costs.floor_area_conditioned_ft_2']
#Insulate and seal ducts a lot to have 10% leakage and R-8 ducts
up02.loc[up02['upgrade_costs.option_05_cost_usd'] > 0, 'upgrade_costs.option_05_cost_usd'] = ducts1*up02['upgrade_costs.duct_unconditioned_surface_area_ft_2']
#Seal ducts a lot to have 10% leakage, already has R-8 insulation
up02.loc[up02['upgrade_costs.option_06_cost_usd'] > 0, 'upgrade_costs.option_06_cost_usd'] = ducts2*up02['upgrade_costs.duct_unconditioned_surface_area_ft_2']
#Insulate and seal ducts some to have 10% leakage and R-8 ducts
up02.loc[up02['upgrade_costs.option_07_cost_usd'] > 0, 'upgrade_costs.option_07_cost_usd'] = ducts3*up02['upgrade_costs.duct_unconditioned_surface_area_ft_2']
#Seal ducts some to have 10% leakage, already has R-8 insulation
up02.loc[up02['upgrade_costs.option_08_cost_usd'] > 0, 'upgrade_costs.option_08_cost_usd'] = ducts4*up02['upgrade_costs.duct_unconditioned_surface_area_ft_2']
#Only insulate ducts to R-8, no sealing
up02.loc[up02['upgrade_costs.option_09_cost_usd'] > 0, 'upgrade_costs.option_09_cost_usd'] = ducts5*up02['upgrade_costs.duct_unconditioned_surface_area_ft_2']
#Insulation Wall|Wood Stud, R-13
up02.loc[up02['upgrade_costs.option_10_cost_usd'] > 0, 'upgrade_costs.option_10_cost_usd'] = wall_r13*up02['upgrade_costs.wall_area_above_grade_conditioned_ft_2']

#Insulate interior foundation wall to R-10
up02.loc[up02['upgrade_costs.option_11_cost_usd'] > 0, 'upgrade_costs.option_11_cost_usd'] = wall_foundation*up02['upgrade_costs.wall_area_below_grade_ft_2']
#Insulate interior finished basement wall to R-10
up02.loc[up02['upgrade_costs.option_12_cost_usd'] > 0, 'upgrade_costs.option_12_cost_usd'] = wall_basement*up02['upgrade_costs.wall_area_below_grade_ft_2']
#Insulation Rim Joist|R-10, Exterior
up02.loc[up02['upgrade_costs.option_13_cost_usd'] > 0, 'upgrade_costs.option_13_cost_usd'] = rim*up02['upgrade_costs.rim_joist_area_above_grade_exterior_ft_2']
#Geometry Foundation Type|Unvented Crawlspace
up02.loc[up02['upgrade_costs.option_14_cost_usd'] > 0, 'upgrade_costs.option_14_cost_usd'] = crawlspaces*up02['upgrade_costs.floor_area_foundation_ft_2']
#Insulation Roof|Finished, R-30
up02.loc[up02['upgrade_costs.option_15_cost_usd'] > 0, 'upgrade_costs.option_15_cost_usd'] = roof*up02['upgrade_costs.roof_area_ft_2']

#bill
up02.loc[up02['report_simulation_output.fuel_use_electricity_net_m_btu'] > 0, 'bill_electricity_USD'] = up02['report_simulation_output.fuel_use_electricity_net_m_btu']*0.293*ele_price*0.01+ele_month_fix*12
up02.loc[up02['report_simulation_output.fuel_use_electricity_net_m_btu'] == 0, 'bill_electricity_USD'] = 0
up02.loc[up02['report_simulation_output.fuel_use_natural_gas_total_m_btu'] > 0, 'bill_natural_gas_USD'] = up02['report_simulation_output.fuel_use_natural_gas_total_m_btu']*0.01*gas_price+gas_month_fix*12
up02.loc[up02['report_simulation_output.fuel_use_natural_gas_total_m_btu'] == 0, 'bill_natural_gas_USD'] = 0
up02.loc[up02['report_simulation_output.fuel_use_propane_total_m_btu'] > 0, 'bill_propane__USD'] = up02['report_simulation_output.fuel_use_propane_total_m_btu']*10.929*propane_price+propane_month_fix*12
up02.loc[up02['report_simulation_output.fuel_use_propane_total_m_btu'] == 0, 'bill_propane__USD'] = 0
up02.loc[up02['report_simulation_output.fuel_use_fuel_oil_total_m_btu'] > 0, 'bill_fuel_oil_USD'] = up02['report_simulation_output.fuel_use_fuel_oil_total_m_btu']*7.407*oil_price+oil_month_fix*12 # 7.407 is for Kerosene
up02.loc[up02['report_simulation_output.fuel_use_fuel_oil_total_m_btu'] == 0, 'bill_fuel_oil_USD'] = 0
up02['total_bill_USD'] = up02['bill_electricity_USD']+up02['bill_natural_gas_USD']+up02['bill_propane__USD']+up02['bill_fuel_oil_USD']

#total cost
up02.loc[up02['upgrade_costs.upgrade_cost_usd'] > 0, 'upgrade_costs.upgrade_cost_usd'] = up02['upgrade_costs.option_01_cost_usd'].fillna(0)+up02['upgrade_costs.option_02_cost_usd'].fillna(0)+up02['upgrade_costs.option_03_cost_usd'].fillna(0)+up02['upgrade_costs.option_04_cost_usd'].fillna(0)+up02['upgrade_costs.option_05_cost_usd'].fillna(0)+up02['upgrade_costs.option_06_cost_usd'].fillna(0)+up02['upgrade_costs.option_07_cost_usd'].fillna(0)+up02['upgrade_costs.option_08_cost_usd'].fillna(0)+up02['upgrade_costs.option_09_cost_usd'].fillna(0)+up02['upgrade_costs.option_10_cost_usd'].fillna(0)+up02['upgrade_costs.option_11_cost_usd'].fillna(0)+up02['upgrade_costs.option_12_cost_usd'].fillna(0)+up02['upgrade_costs.option_13_cost_usd'].fillna(0)+up02['upgrade_costs.option_14_cost_usd'].fillna(0)+up02['upgrade_costs.option_15_cost_usd'].fillna(0)
up02.to_csv('results/up02.csv')


##data processing for up03
up03 = pd.read_csv('data/up03_sample.csv')

#HVAC Heating Efficiency|ASHP, SEER 15, 9.0 HSPF
up03.loc[up03['upgrade_costs.option_01_cost_usd'] > 0, 'upgrade_costs.option_01_cost_usd'] = ASHP_cost1+ASHP_cost2*up03['upgrade_costs.size_heating_system_primary_k_btu_h']
#HVAC Heating Efficiency|MSHP, SEER 15, 9.0 HSPF, Max Load
up03.loc[up03['upgrade_costs.option_02_cost_usd'] > 0, 'upgrade_costs.option_02_cost_usd'] = MSHP_max_9_cost1+MSHP_max_9_cost2*up03['upgrade_costs.size_heating_system_primary_k_btu_h']

#bill
up03.loc[up03['report_simulation_output.fuel_use_electricity_net_m_btu'] > 0, 'bill_electricity_USD'] = up03['report_simulation_output.fuel_use_electricity_net_m_btu']*0.293*ele_price*0.01+ele_month_fix*12
up03.loc[up03['report_simulation_output.fuel_use_electricity_net_m_btu'] == 0, 'bill_electricity_USD'] = 0
up03.loc[up03['report_simulation_output.fuel_use_natural_gas_total_m_btu'] > 0, 'bill_natural_gas_USD'] = up03['report_simulation_output.fuel_use_natural_gas_total_m_btu']*0.01*gas_price+gas_month_fix*12
up03.loc[up03['report_simulation_output.fuel_use_natural_gas_total_m_btu'] == 0, 'bill_natural_gas_USD'] = 0
up03.loc[up03['report_simulation_output.fuel_use_propane_total_m_btu'] > 0, 'bill_propane__USD'] = up03['report_simulation_output.fuel_use_propane_total_m_btu']*10.929*propane_price+propane_month_fix*12
up03.loc[up03['report_simulation_output.fuel_use_propane_total_m_btu'] == 0, 'bill_propane__USD'] = 0
up03.loc[up03['report_simulation_output.fuel_use_fuel_oil_total_m_btu'] > 0, 'bill_fuel_oil_USD'] = up03['report_simulation_output.fuel_use_fuel_oil_total_m_btu']*7.407*oil_price+oil_month_fix*12 # 7.407 is for Kerosene
up03.loc[up03['report_simulation_output.fuel_use_fuel_oil_total_m_btu'] == 0, 'bill_fuel_oil_USD'] = 0
up03['total_bill_USD'] = up03['bill_electricity_USD']+up03['bill_natural_gas_USD']+up03['bill_propane__USD']+up03['bill_fuel_oil_USD']

#total cost
up03.loc[up03['upgrade_costs.upgrade_cost_usd'] > 0, 'upgrade_costs.upgrade_cost_usd'] = up03['upgrade_costs.option_01_cost_usd'].fillna(0)+up03['upgrade_costs.option_02_cost_usd'].fillna(0)
up03.to_csv('results/up03.csv')


##data processing for up04
up04 = pd.read_csv('data/up04_sample.csv')

#HVAC Heating Efficiency|MSHP, SEER 24, 13 HSPF
up04.loc[up04['upgrade_costs.option_01_cost_usd'] > 0, 'upgrade_costs.option_01_cost_usd'] = ducted_MSHP_cost1+ducted_MSHP_cost2*up04['upgrade_costs.size_heating_system_primary_k_btu_h']
#HVAC Heating Efficiency|MSHP, SEER 29.3, 14 HSPF, Max Load
up04.loc[up04['upgrade_costs.option_03_cost_usd'] > 0, 'upgrade_costs.option_03_cost_usd'] = MSHP_max_14_cost1+MSHP_max_14_cost2*up04['upgrade_costs.size_heating_system_primary_k_btu_h']

#bill
up04.loc[up04['report_simulation_output.fuel_use_electricity_net_m_btu'] > 0, 'bill_electricity_USD'] = up04['report_simulation_output.fuel_use_electricity_net_m_btu']*0.293*ele_price*0.01+ele_month_fix*12
up04.loc[up04['report_simulation_output.fuel_use_electricity_net_m_btu'] == 0, 'bill_electricity_USD'] = 0
up04.loc[up04['report_simulation_output.fuel_use_natural_gas_total_m_btu'] > 0, 'bill_natural_gas_USD'] = up04['report_simulation_output.fuel_use_natural_gas_total_m_btu']*0.01*gas_price+gas_month_fix*12
up04.loc[up04['report_simulation_output.fuel_use_natural_gas_total_m_btu'] == 0, 'bill_natural_gas_USD'] = 0
up04.loc[up04['report_simulation_output.fuel_use_propane_total_m_btu'] > 0, 'bill_propane__USD'] = up04['report_simulation_output.fuel_use_propane_total_m_btu']*10.929*propane_price+propane_month_fix*12
up04.loc[up04['report_simulation_output.fuel_use_propane_total_m_btu'] == 0, 'bill_propane__USD'] = 0
up04.loc[up04['report_simulation_output.fuel_use_fuel_oil_total_m_btu'] > 0, 'bill_fuel_oil_USD'] = up04['report_simulation_output.fuel_use_fuel_oil_total_m_btu']*7.407*oil_price+oil_month_fix*12 # 7.407 is for Kerosene
up04.loc[up04['report_simulation_output.fuel_use_fuel_oil_total_m_btu'] == 0, 'bill_fuel_oil_USD'] = 0
up04['total_bill_USD'] = up04['bill_electricity_USD']+up04['bill_natural_gas_USD']+up04['bill_propane__USD']+up04['bill_fuel_oil_USD']

#total cost
up04.loc[up04['upgrade_costs.upgrade_cost_usd'] > 0, 'upgrade_costs.upgrade_cost_usd'] = up04['upgrade_costs.option_01_cost_usd'].fillna(0)+up04['upgrade_costs.option_03_cost_usd'].fillna(0)
up04.to_csv('results/up04.csv')

##data processing for up05
up05 = pd.read_csv('data/up05_sample.csv')

#HVAC Heating Efficiency|Dual-System MSHP, SEER 15, 9.0 HSPF, Max Load, Separate Backup
up05.loc[up05['upgrade_costs.option_01_cost_usd'] > 0, 'upgrade_costs.option_01_cost_usd'] = MSHP_ele_baseboard_cost1+MSHP_ele_baseboard_cost2*up05['upgrade_costs.size_heating_system_primary_k_btu_h']
#HVAC Heating Efficiency|Dual-System MSHP, SEER 15, 9.0 HSPF, Max Load, Separate Backup
up05.loc[up05['upgrade_costs.option_04_cost_usd'] > 0, 'upgrade_costs.option_04_cost_usd'] = MSHP_ele_boiler_cost1+MSHP_ele_boiler_cost2*up05['upgrade_costs.size_heating_system_primary_k_btu_h']
#HVAC Heating Efficiency|Dual-System MSHP, SEER 15, 9.0 HSPF, Max Load, Separate Backup
up05.loc[up05['upgrade_costs.option_07_cost_usd'] > 0, 'upgrade_costs.option_07_cost_usd'] = MSHP_furnace_cost1+MSHP_furnace_cost2*up05['upgrade_costs.size_heating_system_primary_k_btu_h']
#HVAC Heating Efficiency|ASHP, SEER 15, 9.0 HSPF
up05.loc[up05['upgrade_costs.option_10_cost_usd'] > 0, 'upgrade_costs.option_10_cost_usd'] = ASHP_cost1+ASHP_cost2*up05['upgrade_costs.size_heating_system_primary_k_btu_h']
#HVAC Heating Efficiency|MSHP, SEER 15, 9.0 HSPF, Max Load
up05.loc[up05['upgrade_costs.option_11_cost_usd'] > 0, 'upgrade_costs.option_11_cost_usd'] = MSHP_upgrade_cost1+MSHP_upgrade_cost2*up05['upgrade_costs.size_heating_system_primary_k_btu_h']
#HVAC Heating Efficiency|Dual-Fuel ASHP, SEER 15, 9.0 HSPF, Separate Backup
up05.loc[up05['upgrade_costs.option_12_cost_usd'] > 0, 'upgrade_costs.option_12_cost_usd'] = ASHP_cost1+ASHP_cost2*up05['upgrade_costs.size_heating_system_primary_k_btu_h']
#HVAC Heating Efficiency|Dual-Fuel MSHP, SEER 15, 9.0 HSPF, Max Load, Separate Backup
up05.loc[up05['upgrade_costs.option_13_cost_usd'] > 0, 'upgrade_costs.option_13_cost_usd'] = MSHP_max_9_cost1+MSHP_max_9_cost2*up05['upgrade_costs.size_heating_system_primary_k_btu_h']

#ducted furnace
up05.loc[up05['upgrade_costs.option_30_cost_usd'] > 0, 'upgrade_costs.option_30_cost_usd'] = furnace_cost1+furnace_cost2*up05['upgrade_costs.size_heating_system_primary_k_btu_h']
up05.loc[up05['upgrade_costs.option_33_cost_usd'] > 0, 'upgrade_costs.option_33_cost_usd'] = furnace_cost1+furnace_cost2*up05['upgrade_costs.size_heating_system_primary_k_btu_h']
up05.loc[up05['upgrade_costs.option_34_cost_usd'] > 0, 'upgrade_costs.option_34_cost_usd'] = furnace_cost1+furnace_cost2*up05['upgrade_costs.size_heating_system_primary_k_btu_h']
up05.loc[up05['upgrade_costs.option_37_cost_usd'] > 0, 'upgrade_costs.option_37_cost_usd'] = furnace_cost1+furnace_cost2*up05['upgrade_costs.size_heating_system_primary_k_btu_h']
up05.loc[up05['upgrade_costs.option_39_cost_usd'] > 0, 'upgrade_costs.option_39_cost_usd'] = furnace_cost1+furnace_cost2*up05['upgrade_costs.size_heating_system_primary_k_btu_h']
up05.loc[up05['upgrade_costs.option_42_cost_usd'] > 0, 'upgrade_costs.option_42_cost_usd'] = furnace_cost1+furnace_cost2*up05['upgrade_costs.size_heating_system_primary_k_btu_h']
up05.loc[up05['upgrade_costs.option_43_cost_usd'] > 0, 'upgrade_costs.option_43_cost_usd'] = furnace_cost1+furnace_cost2*up05['upgrade_costs.size_heating_system_primary_k_btu_h']
up05.loc[up05['upgrade_costs.option_46_cost_usd'] > 0, 'upgrade_costs.option_46_cost_usd'] = furnace_cost1+furnace_cost2*up05['upgrade_costs.size_heating_system_primary_k_btu_h']
up05.loc[up05['upgrade_costs.option_51_cost_usd'] > 0, 'upgrade_costs.option_51_cost_usd'] = furnace_cost1+furnace_cost2*up05['upgrade_costs.size_heating_system_primary_k_btu_h']
up05.loc[up05['upgrade_costs.option_52_cost_usd'] > 0, 'upgrade_costs.option_52_cost_usd'] = furnace_cost1+furnace_cost2*up05['upgrade_costs.size_heating_system_primary_k_btu_h']
up05.loc[up05['upgrade_costs.option_55_cost_usd'] > 0, 'upgrade_costs.option_55_cost_usd'] = furnace_cost1+furnace_cost2*up05['upgrade_costs.size_heating_system_primary_k_btu_h']

#shared heating
up05.loc[up05['upgrade_costs.option_57_cost_usd'] > 0, 'upgrade_costs.option_57_cost_usd'] = ASHP_fossil_cost1+ASHP_fossil_cost2*up05['upgrade_costs.size_heating_system_primary_k_btu_h']
up05.loc[up05['upgrade_costs.option_58_cost_usd'] > 0, 'upgrade_costs.option_58_cost_usd'] = ASHP_fossil_cost1+ASHP_fossil_cost2*up05['upgrade_costs.size_heating_system_primary_k_btu_h']
up05.loc[up05['upgrade_costs.option_59_cost_usd'] > 0, 'upgrade_costs.option_59_cost_usd'] = ASHP_fossil_cost1+ASHP_fossil_cost2*up05['upgrade_costs.size_heating_system_primary_k_btu_h']
up05.loc[up05['upgrade_costs.option_60_cost_usd'] > 0, 'upgrade_costs.option_60_cost_usd'] = ASHP_fossil_cost1+ASHP_fossil_cost2*up05['upgrade_costs.size_heating_system_primary_k_btu_h']

#HVAC Heating Efficiency|Dual-Fuel MSHP, SEER 15, 9.0 HSPF, Max Load, Separate Backup
up05.loc[up05['upgrade_costs.option_61_cost_usd'] > 0, 'upgrade_costs.option_61_cost_usd'] = MSHP_max_9_cost1+MSHP_max_9_cost2*up05['upgrade_costs.size_heating_system_primary_k_btu_h']
#HVAC Heating Efficiency|MSHP, SEER 15, 9.0 HSPF, Max Load
up05.loc[up05['upgrade_costs.option_62_cost_usd'] > 0, 'upgrade_costs.option_62_cost_usd'] = MSHP_max_9_cost1+MSHP_max_9_cost2*up05['upgrade_costs.size_heating_system_primary_k_btu_h']

#bill
up05.loc[up05['report_simulation_output.fuel_use_electricity_net_m_btu'] > 0, 'bill_electricity_USD'] = up05['report_simulation_output.fuel_use_electricity_net_m_btu']*0.293*ele_price*0.01+ele_month_fix*12
up05.loc[up05['report_simulation_output.fuel_use_electricity_net_m_btu'] == 0, 'bill_electricity_USD'] = 0
up05.loc[up05['report_simulation_output.fuel_use_natural_gas_total_m_btu'] > 0, 'bill_natural_gas_USD'] = up05['report_simulation_output.fuel_use_natural_gas_total_m_btu']*0.01*gas_price+gas_month_fix*12
up05.loc[up05['report_simulation_output.fuel_use_natural_gas_total_m_btu'] == 0, 'bill_natural_gas_USD'] = 0
up05.loc[up05['report_simulation_output.fuel_use_propane_total_m_btu'] > 0, 'bill_propane__USD'] = up05['report_simulation_output.fuel_use_propane_total_m_btu']*10.929*propane_price+propane_month_fix*12
up05.loc[up05['report_simulation_output.fuel_use_propane_total_m_btu'] == 0, 'bill_propane__USD'] = 0
up05.loc[up05['report_simulation_output.fuel_use_fuel_oil_total_m_btu'] > 0, 'bill_fuel_oil_USD'] = up05['report_simulation_output.fuel_use_fuel_oil_total_m_btu']*7.407*oil_price+oil_month_fix*12 # 7.407 is for Kerosene
up05.loc[up05['report_simulation_output.fuel_use_fuel_oil_total_m_btu'] == 0, 'bill_fuel_oil_USD'] = 0
up05['total_bill_USD'] = up05['bill_electricity_USD']+up05['bill_natural_gas_USD']+up05['bill_propane__USD']+up05['bill_fuel_oil_USD']

#total cost
up05.loc[up05['upgrade_costs.upgrade_cost_usd'] > 0, 'upgrade_costs.upgrade_cost_usd'] = up05['upgrade_costs.option_01_cost_usd'].fillna(0)+up05['upgrade_costs.option_04_cost_usd'].fillna(0)+up05['upgrade_costs.option_07_cost_usd'].fillna(0)+up05['upgrade_costs.option_10_cost_usd'].fillna(0)+up05['upgrade_costs.option_11_cost_usd'].fillna(0)+up05['upgrade_costs.option_12_cost_usd'].fillna(0)+up05['upgrade_costs.option_13_cost_usd'].fillna(0)+up05['upgrade_costs.option_30_cost_usd'].fillna(0)+up05['upgrade_costs.option_33_cost_usd'].fillna(0)+up05['upgrade_costs.option_34_cost_usd'].fillna(0)+up05['upgrade_costs.option_37_cost_usd'].fillna(0)+up05['upgrade_costs.option_39_cost_usd'].fillna(0)+up05['upgrade_costs.option_42_cost_usd'].fillna(0)+up05['upgrade_costs.option_43_cost_usd'].fillna(0)+up05['upgrade_costs.option_46_cost_usd'].fillna(0)+up05['upgrade_costs.option_51_cost_usd'].fillna(0)+up05['upgrade_costs.option_52_cost_usd'].fillna(0)+up05['upgrade_costs.option_55_cost_usd'].fillna(0)+up05['upgrade_costs.option_57_cost_usd'].fillna(0)+up05['upgrade_costs.option_58_cost_usd'].fillna(0)+up05['upgrade_costs.option_59_cost_usd'].fillna(0)+up05['upgrade_costs.option_60_cost_usd'].fillna(0)+up05['upgrade_costs.option_61_cost_usd'].fillna(0)+up05['upgrade_costs.option_62_cost_usd'].fillna(0)
up05.to_csv('results/up05.csv')

##data processing for up06
up06 = pd.read_csv('data/up06_sample.csv')

#Water Heater Efficiency|Electric Heat Pump, 50 gal, 3.45 UEF
up06.loc[up06['upgrade_costs.option_01_cost_usd'] > 0, 'upgrade_costs.option_01_cost_usd'] = HPWH_50
#Water Heater Efficiency|Electric Heat Pump, 66 gal, 3.35 UEF
up06.loc[up06['upgrade_costs.option_02_cost_usd'] > 0, 'upgrade_costs.option_02_cost_usd'] = HPWH_66
#Water Heater Efficiency|Electric Heat Pump, 80 gal, 3.45 UEF
up06.loc[up06['upgrade_costs.option_03_cost_usd'] > 0, 'upgrade_costs.option_03_cost_usd'] = HPWH_80

#bill
up06.loc[up06['report_simulation_output.fuel_use_electricity_net_m_btu'] > 0, 'bill_electricity_USD'] = up06['report_simulation_output.fuel_use_electricity_net_m_btu']*0.293*ele_price*0.01+ele_month_fix*12
up06.loc[up06['report_simulation_output.fuel_use_electricity_net_m_btu'] == 0, 'bill_electricity_USD'] = 0
up06.loc[up06['report_simulation_output.fuel_use_natural_gas_total_m_btu'] > 0, 'bill_natural_gas_USD'] = up06['report_simulation_output.fuel_use_natural_gas_total_m_btu']*0.01*gas_price+gas_month_fix*12
up06.loc[up06['report_simulation_output.fuel_use_natural_gas_total_m_btu'] == 0, 'bill_natural_gas_USD'] = 0
up06.loc[up06['report_simulation_output.fuel_use_propane_total_m_btu'] > 0, 'bill_propane__USD'] = up06['report_simulation_output.fuel_use_propane_total_m_btu']*10.929*propane_price+propane_month_fix*12
up06.loc[up06['report_simulation_output.fuel_use_propane_total_m_btu'] == 0, 'bill_propane__USD'] = 0
up06.loc[up06['report_simulation_output.fuel_use_fuel_oil_total_m_btu'] > 0, 'bill_fuel_oil_USD'] = up06['report_simulation_output.fuel_use_fuel_oil_total_m_btu']*7.407*oil_price+oil_month_fix*12 # 7.407 is for Kerosene
up06.loc[up06['report_simulation_output.fuel_use_fuel_oil_total_m_btu'] == 0, 'bill_fuel_oil_USD'] = 0
up06['total_bill_USD'] = up06['bill_electricity_USD']+up06['bill_natural_gas_USD']+up06['bill_propane__USD']+up06['bill_fuel_oil_USD']

#total cost
up06.loc[up06['upgrade_costs.upgrade_cost_usd'] > 0, 'upgrade_costs.upgrade_cost_usd'] = up06['upgrade_costs.option_01_cost_usd'].fillna(0)+up06['upgrade_costs.option_02_cost_usd'].fillna(0)+up06['upgrade_costs.option_03_cost_usd'].fillna(0)
up06.to_csv('results/up06.csv')


##data processing for up07
up07 = pd.read_csv('data/up07_sample.csv')

#HVAC Heating Efficiency|ASHP, SEER 15, 9.0 HSPF
up07.loc[up07['upgrade_costs.option_01_cost_usd'] > 0, 'upgrade_costs.option_01_cost_usd'] = ASHP_cost1+ASHP_cost2*up07['upgrade_costs.size_heating_system_primary_k_btu_h']
#HVAC Heating Efficiency|MSHP, SEER 15, 9.0 HSPF, Max Load
up07.loc[up07['upgrade_costs.option_02_cost_usd'] > 0, 'upgrade_costs.option_02_cost_usd'] = MSHP_max_9_cost1+MSHP_max_9_cost2*up07['upgrade_costs.size_heating_system_primary_k_btu_h']
#Water Heater Efficiency|Electric Heat Pump, 50 gal, 3.45 UEF
up07.loc[up07['upgrade_costs.option_04_cost_usd'] > 0, 'upgrade_costs.option_04_cost_usd'] = WH_50
#Water Heater Efficiency|Electric Heat Pump, 66 gal, 3.35 UEF
up07.loc[up07['upgrade_costs.option_05_cost_usd'] > 0, 'upgrade_costs.option_05_cost_usd'] = WH_66
#Water Heater Efficiency|Electric Heat Pump, 80 gal, 3.45 UEF
up07.loc[up07['upgrade_costs.option_06_cost_usd'] > 0, 'upgrade_costs.option_06_cost_usd'] = WH_80

#Clothes Dryer|Electric, 80% Usage
up07.loc[up07['upgrade_costs.option_07_cost_usd'] > 0, 'upgrade_costs.option_07_cost_usd'] = dryer
#Clothes Dryer|Electric, 100% Usage
up07.loc[up07['upgrade_costs.option_08_cost_usd'] > 0, 'upgrade_costs.option_08_cost_usd'] = dryer
#Clothes Dryer|Electric, 120% Usage
up07.loc[up07['upgrade_costs.option_09_cost_usd'] > 0, 'upgrade_costs.option_09_cost_usd'] = dryer

#Cooking Range|Electric, 80% Usage
up07.loc[up07['upgrade_costs.option_10_cost_usd'] > 0, 'upgrade_costs.option_10_cost_usd'] = ele_range
#Cooking Range|Electric, 100% Usage
up07.loc[up07['upgrade_costs.option_11_cost_usd'] > 0, 'upgrade_costs.option_11_cost_usd'] = ele_range
#Cooking Range|Electric, 120% Usage
up07.loc[up07['upgrade_costs.option_12_cost_usd'] > 0, 'upgrade_costs.option_12_cost_usd'] = ele_range

#bill
up07.loc[up07['report_simulation_output.fuel_use_electricity_net_m_btu'] > 0, 'bill_electricity_USD'] = up07['report_simulation_output.fuel_use_electricity_net_m_btu']*0.293*ele_price*0.01+ele_month_fix*12
up07.loc[up07['report_simulation_output.fuel_use_electricity_net_m_btu'] == 0, 'bill_electricity_USD'] = 0
up07.loc[up07['report_simulation_output.fuel_use_natural_gas_total_m_btu'] > 0, 'bill_natural_gas_USD'] = up07['report_simulation_output.fuel_use_natural_gas_total_m_btu']*0.01*gas_price+gas_month_fix*12
up07.loc[up07['report_simulation_output.fuel_use_natural_gas_total_m_btu'] == 0, 'bill_natural_gas_USD'] = 0
up07.loc[up07['report_simulation_output.fuel_use_propane_total_m_btu'] > 0, 'bill_propane__USD'] = up07['report_simulation_output.fuel_use_propane_total_m_btu']*10.929*propane_price+propane_month_fix*12
up07.loc[up07['report_simulation_output.fuel_use_propane_total_m_btu'] == 0, 'bill_propane__USD'] = 0
up07.loc[up07['report_simulation_output.fuel_use_fuel_oil_total_m_btu'] > 0, 'bill_fuel_oil_USD'] = up07['report_simulation_output.fuel_use_fuel_oil_total_m_btu']*7.407*oil_price+oil_month_fix*12 # 7.407 is for Kerosene
up07.loc[up07['report_simulation_output.fuel_use_fuel_oil_total_m_btu'] == 0, 'bill_fuel_oil_USD'] = 0
up07['total_bill_USD'] = up07['bill_electricity_USD']+up07['bill_natural_gas_USD']+up07['bill_propane__USD']+up07['bill_fuel_oil_USD']

#total cost
up07.loc[up07['upgrade_costs.upgrade_cost_usd'] > 0, 'upgrade_costs.upgrade_cost_usd'] = up07['upgrade_costs.option_01_cost_usd'].fillna(0)+up07['upgrade_costs.option_02_cost_usd'].fillna(0)+up07['upgrade_costs.option_04_cost_usd'].fillna(0)+up07['upgrade_costs.option_05_cost_usd'].fillna(0)+up07['upgrade_costs.option_06_cost_usd'].fillna(0)+up07['upgrade_costs.option_07_cost_usd'].fillna(0)+up07['upgrade_costs.option_08_cost_usd'].fillna(0)+up07['upgrade_costs.option_09_cost_usd'].fillna(0)+up07['upgrade_costs.option_10_cost_usd'].fillna(0)+up07['upgrade_costs.option_11_cost_usd'].fillna(0)+up07['upgrade_costs.option_12_cost_usd'].fillna(0)
up07.to_csv('results/up07.csv')


##data processing for up08
up08 = pd.read_csv('data/up08_sample.csv')

#HVAC Heating Efficiency|MSHP, SEER 24, 13 HSPF
up08.loc[up08['upgrade_costs.option_01_cost_usd'] > 0, 'upgrade_costs.option_01_cost_usd'] = ducted_MSHP_cost1+ducted_MSHP_cost2*up08['upgrade_costs.size_heating_system_primary_k_btu_h']
#HVAC Heating Efficiency|MSHP, SEER 29.3, 14 HSPF, Max Load
up08.loc[up08['upgrade_costs.option_03_cost_usd'] > 0, 'upgrade_costs.option_03_cost_usd'] = MSHP_max_14_cost1+MSHP_max_14_cost2*up08['upgrade_costs.size_heating_system_primary_k_btu_h']

#Water Heater Efficiency|Electric Heat Pump, 50 gal, 3.45 UEF
up08.loc[up08['upgrade_costs.option_05_cost_usd'] > 0, 'upgrade_costs.option_05_cost_usd'] = HPWH_50
#Water Heater Efficiency|Electric Heat Pump, 66 gal, 3.35 UEF
up08.loc[up08['upgrade_costs.option_06_cost_usd'] > 0, 'upgrade_costs.option_06_cost_usd'] = HPWH_66
#Water Heater Efficiency|Electric Heat Pump, 80 gal, 3.45 UEF
up08.loc[up08['upgrade_costs.option_07_cost_usd'] > 0, 'upgrade_costs.option_07_cost_usd'] = HPWH_80

#Clothes Dryer|Electric, Premium, Heat Pump, Ventless, 80% Usage
up08.loc[up08['upgrade_costs.option_08_cost_usd'] > 0, 'upgrade_costs.option_08_cost_usd'] = dryer_HP
#Clothes Dryer|Electric, Premium, Heat Pump, Ventless, 100% Usage
up08.loc[up08['upgrade_costs.option_09_cost_usd'] > 0, 'upgrade_costs.option_09_cost_usd'] = dryer_HP
#Clothes Dryer|Electric, Premium, Heat Pump, Ventless, 120% Usage
up08.loc[up08['upgrade_costs.option_10_cost_usd'] > 0, 'upgrade_costs.option_10_cost_usd'] = dryer_HP

#Cooking Range|Electric, Induction, 80% Usage
up08.loc[up08['upgrade_costs.option_11_cost_usd'] > 0, 'upgrade_costs.option_11_cost_usd'] = induction_range
#Cooking Range|Electric, Induction, 100% Usage
up08.loc[up08['upgrade_costs.option_12_cost_usd'] > 0, 'upgrade_costs.option_12_cost_usd'] = induction_range
#Cooking Range|Electric, Induction, 120% Usage
up08.loc[up08['upgrade_costs.option_13_cost_usd'] > 0, 'upgrade_costs.option_13_cost_usd'] = induction_range

#bill
up08.loc[up08['report_simulation_output.fuel_use_electricity_net_m_btu'] > 0, 'bill_electricity_USD'] = up08['report_simulation_output.fuel_use_electricity_net_m_btu']*0.293*ele_price*0.01+ele_month_fix*12
up08.loc[up08['report_simulation_output.fuel_use_electricity_net_m_btu'] == 0, 'bill_electricity_USD'] = 0
up08.loc[up08['report_simulation_output.fuel_use_natural_gas_total_m_btu'] > 0, 'bill_natural_gas_USD'] = up08['report_simulation_output.fuel_use_natural_gas_total_m_btu']*0.01*gas_price+gas_month_fix*12
up08.loc[up08['report_simulation_output.fuel_use_natural_gas_total_m_btu'] == 0, 'bill_natural_gas_USD'] = 0
up08.loc[up08['report_simulation_output.fuel_use_propane_total_m_btu'] > 0, 'bill_propane__USD'] = up08['report_simulation_output.fuel_use_propane_total_m_btu']*10.929*propane_price+propane_month_fix*12
up08.loc[up08['report_simulation_output.fuel_use_propane_total_m_btu'] == 0, 'bill_propane__USD'] = 0
up08.loc[up08['report_simulation_output.fuel_use_fuel_oil_total_m_btu'] > 0, 'bill_fuel_oil_USD'] = up08['report_simulation_output.fuel_use_fuel_oil_total_m_btu']*7.407*oil_price+oil_month_fix*12 # 7.407 is for Kerosene
up08.loc[up08['report_simulation_output.fuel_use_fuel_oil_total_m_btu'] == 0, 'bill_fuel_oil_USD'] = 0
up08['total_bill_USD'] = up08['bill_electricity_USD']+up08['bill_natural_gas_USD']+up08['bill_propane__USD']+up08['bill_fuel_oil_USD']

#total cost
up08.loc[up08['upgrade_costs.upgrade_cost_usd'] > 0, 'upgrade_costs.upgrade_cost_usd'] = up08['upgrade_costs.option_01_cost_usd'].fillna(0)+up08['upgrade_costs.option_03_cost_usd'].fillna(0)+up08['upgrade_costs.option_05_cost_usd'].fillna(0)+up08['upgrade_costs.option_06_cost_usd'].fillna(0)+up08['upgrade_costs.option_07_cost_usd'].fillna(0)+up08['upgrade_costs.option_08_cost_usd'].fillna(0)+up08['upgrade_costs.option_09_cost_usd'].fillna(0)+up08['upgrade_costs.option_10_cost_usd'].fillna(0)+up08['upgrade_costs.option_11_cost_usd'].fillna(0)+up08['upgrade_costs.option_12_cost_usd'].fillna(0)+up08['upgrade_costs.option_13_cost_usd'].fillna(0)
up08.to_csv('results/up08_test.csv')


##data processing for up09
up09 = pd.read_csv('data/up09_sample.csv')

#Insulate ceiling to R-30
up09['option_01_Delta_R'] = (up09['upgrade_costs.option_01_cost_usd']-up09['upgrade_costs.floor_area_attic_ft_2']*0.1992)/up09['upgrade_costs.floor_area_attic_ft_2']/0.0443
up09.loc[up09['upgrade_costs.option_01_cost_usd'] > 0, 'upgrade_costs.option_01_cost_usd'] = r30_cost1*up09['upgrade_costs.floor_area_attic_ft_2']*up09['option_01_Delta_R']+r30_cost2*up09['upgrade_costs.floor_area_attic_ft_2']
#Insulate ceiling to R-49
up09['option_02_Delta_R'] = (up09['upgrade_costs.option_02_cost_usd']-up09['upgrade_costs.floor_area_attic_ft_2']*0.1992)/up09['upgrade_costs.floor_area_attic_ft_2']/0.0443
up09.loc[up09['upgrade_costs.option_02_cost_usd'] > 0, 'upgrade_costs.option_02_cost_usd'] = r49_cost1*up09['upgrade_costs.floor_area_attic_ft_2']*up09['option_02_Delta_R']+r49_cost2*up09['upgrade_costs.floor_area_attic_ft_2']
#Insulate ceiling to R-60
up09['option_03_Delta_R'] = (up09['upgrade_costs.option_03_cost_usd']-up09['upgrade_costs.floor_area_attic_ft_2']*0.1992)/up09['upgrade_costs.floor_area_attic_ft_2']/0.0443
up09.loc[up09['upgrade_costs.option_03_cost_usd'] > 0, 'upgrade_costs.option_03_cost_usd'] = r60_cost1*up09['upgrade_costs.floor_area_attic_ft_2']*up09['option_03_Delta_R']+r60_cost2*up09['upgrade_costs.floor_area_attic_ft_2']
#Reduce infiltration by 30%
up09.loc[up09['upgrade_costs.option_04_cost_usd'] > 0, 'upgrade_costs.option_04_cost_usd'] = reduce_infil_30_cost*up09['upgrade_costs.floor_area_conditioned_ft_2']
#Insulate and seal ducts a lot to have 10% leakage and R-8 ducts
up09.loc[up09['upgrade_costs.option_05_cost_usd'] > 0, 'upgrade_costs.option_05_cost_usd'] = ducts1*up09['upgrade_costs.duct_unconditioned_surface_area_ft_2']
#Seal ducts a lot to have 10% leakage, already has R-8 insulation
up09.loc[up09['upgrade_costs.option_06_cost_usd'] > 0, 'upgrade_costs.option_06_cost_usd'] = ducts2*up09['upgrade_costs.duct_unconditioned_surface_area_ft_2']
#Insulate and seal ducts some to have 10% leakage and R-8 ducts
up09.loc[up09['upgrade_costs.option_07_cost_usd'] > 0, 'upgrade_costs.option_07_cost_usd'] = ducts3*up09['upgrade_costs.duct_unconditioned_surface_area_ft_2']
#Seal ducts some to have 10% leakage, already has R-8 insulation
up09.loc[up09['upgrade_costs.option_08_cost_usd'] > 0, 'upgrade_costs.option_08_cost_usd'] = ducts4*up09['upgrade_costs.duct_unconditioned_surface_area_ft_2']
#Only insulate ducts to R-8, no sealing
up09.loc[up09['upgrade_costs.option_09_cost_usd'] > 0, 'upgrade_costs.option_09_cost_usd'] = ducts5*up09['upgrade_costs.duct_unconditioned_surface_area_ft_2']
#Insulation Wall|Wood Stud, R-13
up09.loc[up09['upgrade_costs.option_10_cost_usd'] > 0, 'upgrade_costs.option_10_cost_usd'] = wall_r13*up09['upgrade_costs.wall_area_above_grade_conditioned_ft_2']

#HVAC Heating Efficiency|MSHP, SEER 24, 13 HSPF
up09.loc[up09['upgrade_costs.option_11_cost_usd'] > 0, 'upgrade_costs.option_11_cost_usd'] = ducted_MSHP_cost1+ducted_MSHP_cost2*up09['upgrade_costs.size_heating_system_primary_k_btu_h']
#HVAC Heating Efficiency|MSHP, SEER 29.3, 14 HSPF, Max Load
up09.loc[up09['upgrade_costs.option_13_cost_usd'] > 0, 'upgrade_costs.option_13_cost_usd'] = MSHP_max_14_cost1+MSHP_max_14_cost2*up09['upgrade_costs.size_heating_system_primary_k_btu_h']

#Water Heater Efficiency|Electric Heat Pump, 50 gal, 3.45 UEF
up09.loc[up09['upgrade_costs.option_15_cost_usd'] > 0, 'upgrade_costs.option_15_cost_usd'] = HPWH_50
#Water Heater Efficiency|Electric Heat Pump, 66 gal, 3.35 UEF
up09.loc[up09['upgrade_costs.option_16_cost_usd'] > 0, 'upgrade_costs.option_16_cost_usd'] = HPWH_66
#Water Heater Efficiency|Electric Heat Pump, 80 gal, 3.45 UEF
up09.loc[up09['upgrade_costs.option_17_cost_usd'] > 0, 'upgrade_costs.option_17_cost_usd'] = HPWH_80

#Clothes Dryer|Electric, Premium, Heat Pump, Ventless, 80% Usage
up09.loc[up09['upgrade_costs.option_18_cost_usd'] > 0, 'upgrade_costs.option_18_cost_usd'] = dryer_HP
#Clothes Dryer|Electric, Premium, Heat Pump, Ventless, 100% Usage
up09.loc[up09['upgrade_costs.option_19_cost_usd'] > 0, 'upgrade_costs.option_19_cost_usd'] = dryer_HP
#Clothes Dryer|Electric, Premium, Heat Pump, Ventless, 120% Usage
up09.loc[up09['upgrade_costs.option_20_cost_usd'] > 0, 'upgrade_costs.option_20_cost_usd'] = dryer_HP

#Cooking Range|Electric, Induction, 80% Usage
up09.loc[up09['upgrade_costs.option_21_cost_usd'] > 0, 'upgrade_costs.option_21_cost_usd'] = induction_range
#Cooking Range|Electric, Induction, 100% Usage
up09.loc[up09['upgrade_costs.option_22_cost_usd'] > 0, 'upgrade_costs.option_22_cost_usd'] = induction_range
#Cooking Range|Electric, Induction, 120% Usage
up09.loc[up09['upgrade_costs.option_23_cost_usd'] > 0, 'upgrade_costs.option_23_cost_usd'] = induction_range

#bill
up09.loc[up09['report_simulation_output.fuel_use_electricity_net_m_btu'] > 0, 'bill_electricity_USD'] = up09['report_simulation_output.fuel_use_electricity_net_m_btu']*0.293*ele_price*0.01+ele_month_fix*12
up09.loc[up09['report_simulation_output.fuel_use_electricity_net_m_btu'] == 0, 'bill_electricity_USD'] = 0
up09.loc[up09['report_simulation_output.fuel_use_natural_gas_total_m_btu'] > 0, 'bill_natural_gas_USD'] = up09['report_simulation_output.fuel_use_natural_gas_total_m_btu']*0.01*gas_price+gas_month_fix*12
up09.loc[up09['report_simulation_output.fuel_use_natural_gas_total_m_btu'] == 0, 'bill_natural_gas_USD'] = 0
up09.loc[up09['report_simulation_output.fuel_use_propane_total_m_btu'] > 0, 'bill_propane__USD'] = up09['report_simulation_output.fuel_use_propane_total_m_btu']*10.929*propane_price+propane_month_fix*12
up09.loc[up09['report_simulation_output.fuel_use_propane_total_m_btu'] == 0, 'bill_propane__USD'] = 0
up09.loc[up09['report_simulation_output.fuel_use_fuel_oil_total_m_btu'] > 0, 'bill_fuel_oil_USD'] = up09['report_simulation_output.fuel_use_fuel_oil_total_m_btu']*7.407*oil_price+oil_month_fix*12 # 7.407 is for Kerosene
up09.loc[up09['report_simulation_output.fuel_use_fuel_oil_total_m_btu'] == 0, 'bill_fuel_oil_USD'] = 0
up09['total_bill_USD'] = up09['bill_electricity_USD']+up09['bill_natural_gas_USD']+up09['bill_propane__USD']+up09['bill_fuel_oil_USD']

#total cost
up09.loc[up09['upgrade_costs.upgrade_cost_usd'] > 0, 'upgrade_costs.upgrade_cost_usd'] = up09['upgrade_costs.option_01_cost_usd'].fillna(0)+up09['upgrade_costs.option_02_cost_usd'].fillna(0)+up09['upgrade_costs.option_03_cost_usd'].fillna(0)+up09['upgrade_costs.option_04_cost_usd'].fillna(0)+up09['upgrade_costs.option_05_cost_usd'].fillna(0)+up09['upgrade_costs.option_06_cost_usd'].fillna(0)+up09['upgrade_costs.option_07_cost_usd'].fillna(0)+up09['upgrade_costs.option_08_cost_usd'].fillna(0)+up09['upgrade_costs.option_09_cost_usd'].fillna(0)+up09['upgrade_costs.option_10_cost_usd'].fillna(0)+up09['upgrade_costs.option_11_cost_usd'].fillna(0)+up09['upgrade_costs.option_13_cost_usd'].fillna(0)+up09['upgrade_costs.option_15_cost_usd'].fillna(0)+up09['upgrade_costs.option_16_cost_usd'].fillna(0)+up09['upgrade_costs.option_17_cost_usd'].fillna(0)+up09['upgrade_costs.option_18_cost_usd'].fillna(0)+up09['upgrade_costs.option_19_cost_usd'].fillna(0)+up09['upgrade_costs.option_20_cost_usd'].fillna(0)+up09['upgrade_costs.option_21_cost_usd'].fillna(0)+up09['upgrade_costs.option_22_cost_usd'].fillna(0)+up09['upgrade_costs.option_23_cost_usd'].fillna(0)
up09.to_csv('results/up09.csv')


##data processing for up10
up10 = pd.read_csv('data/up10_sample.csv')

#Insulate ceiling to R-30
up10['option_01_Delta_R'] = (up10['upgrade_costs.option_01_cost_usd']-up10['upgrade_costs.floor_area_attic_ft_2']*0.1992)/up10['upgrade_costs.floor_area_attic_ft_2']/0.0443
up10.loc[up10['upgrade_costs.option_01_cost_usd'] > 0, 'upgrade_costs.option_01_cost_usd'] = r30_cost1*up10['upgrade_costs.floor_area_attic_ft_2']*up10['option_01_Delta_R']+r30_cost2*up10['upgrade_costs.floor_area_attic_ft_2']
#Insulate ceiling to R-49
up10['option_02_Delta_R'] = (up10['upgrade_costs.option_02_cost_usd']-up10['upgrade_costs.floor_area_attic_ft_2']*0.1992)/up10['upgrade_costs.floor_area_attic_ft_2']/0.0443
up10.loc[up10['upgrade_costs.option_02_cost_usd'] > 0, 'upgrade_costs.option_02_cost_usd'] = r49_cost1*up10['upgrade_costs.floor_area_attic_ft_2']*up10['option_02_Delta_R']+r49_cost2*up10['upgrade_costs.floor_area_attic_ft_2']
#Insulate ceiling to R-60
up10['option_03_Delta_R'] = (up10['upgrade_costs.option_03_cost_usd']-up10['upgrade_costs.floor_area_attic_ft_2']*0.1992)/up10['upgrade_costs.floor_area_attic_ft_2']/0.0443
up10.loc[up10['upgrade_costs.option_03_cost_usd'] > 0, 'upgrade_costs.option_03_cost_usd'] = r60_cost1*up10['upgrade_costs.floor_area_attic_ft_2']*up10['option_03_Delta_R']+r60_cost2*up10['upgrade_costs.floor_area_attic_ft_2']
#Reduce infiltration by 30%
up10.loc[up10['upgrade_costs.option_04_cost_usd'] > 0, 'upgrade_costs.option_04_cost_usd'] = reduce_infil_30_cost*up10['upgrade_costs.floor_area_conditioned_ft_2']
#Insulate and seal ducts a lot to have 10% leakage and R-8 ducts
up10.loc[up10['upgrade_costs.option_05_cost_usd'] > 0, 'upgrade_costs.option_05_cost_usd'] = ducts1*up10['upgrade_costs.duct_unconditioned_surface_area_ft_2']
#Seal ducts a lot to have 10% leakage, already has R-8 insulation
up10.loc[up10['upgrade_costs.option_06_cost_usd'] > 0, 'upgrade_costs.option_06_cost_usd'] = ducts2*up10['upgrade_costs.duct_unconditioned_surface_area_ft_2']
#Insulate and seal ducts some to have 10% leakage and R-8 ducts
up10.loc[up10['upgrade_costs.option_07_cost_usd'] > 0, 'upgrade_costs.option_07_cost_usd'] = ducts3*up10['upgrade_costs.duct_unconditioned_surface_area_ft_2']
#Seal ducts some to have 10% leakage, already has R-8 insulation
up10.loc[up10['upgrade_costs.option_08_cost_usd'] > 0, 'upgrade_costs.option_08_cost_usd'] = ducts4*up10['upgrade_costs.duct_unconditioned_surface_area_ft_2']
#Only insulate ducts to R-8, no sealing
up10.loc[up10['upgrade_costs.option_09_cost_usd'] > 0, 'upgrade_costs.option_09_cost_usd'] = ducts5*up10['upgrade_costs.duct_unconditioned_surface_area_ft_2']
#Insulation Wall|Wood Stud, R-13
up10.loc[up10['upgrade_costs.option_10_cost_usd'] > 0, 'upgrade_costs.option_10_cost_usd'] = wall_r13*up10['upgrade_costs.wall_area_above_grade_conditioned_ft_2']

#Insulate interior foundation wall to R-10
up10.loc[up10['upgrade_costs.option_11_cost_usd'] > 0, 'upgrade_costs.option_11_cost_usd'] = wall_foundation*up10['upgrade_costs.wall_area_below_grade_ft_2']
#Geometry Foundation Type|Unvented Crawlspace
up10.loc[up10['upgrade_costs.option_12_cost_usd'] > 0, 'upgrade_costs.option_12_cost_usd'] = crawlspaces*up10['upgrade_costs.floor_area_foundation_ft_2']
#Insulation Roof|Finished, R-30
up10.loc[up10['upgrade_costs.option_13_cost_usd'] > 0, 'upgrade_costs.option_13_cost_usd'] = roof*up10['upgrade_costs.roof_area_ft_2']

#HVAC Heating Efficiency|MSHP, SEER 24, 13 HSPF
up10.loc[up10['upgrade_costs.option_14_cost_usd'] > 0, 'upgrade_costs.option_14_cost_usd'] = ducted_MSHP_cost1+ducted_MSHP_cost2*up10['upgrade_costs.size_heating_system_primary_k_btu_h']
#HVAC Heating Efficiency|MSHP, SEER 29.3, 14 HSPF, Max Load
up10.loc[up10['upgrade_costs.option_16_cost_usd'] > 0, 'upgrade_costs.option_16_cost_usd'] = MSHP_max_14_cost1+MSHP_max_14_cost2*up10['upgrade_costs.size_heating_system_primary_k_btu_h']

#Water Heater Efficiency|Electric Heat Pump, 50 gal, 3.45 UEF
up10.loc[up10['upgrade_costs.option_18_cost_usd'] > 0, 'upgrade_costs.option_18_cost_usd'] = HPWH_50
#Water Heater Efficiency|Electric Heat Pump, 66 gal, 3.35 UEF
up10.loc[up10['upgrade_costs.option_19_cost_usd'] > 0, 'upgrade_costs.option_19_cost_usd'] = HPWH_66
#Water Heater Efficiency|Electric Heat Pump, 80 gal, 3.45 UEF
up10.loc[up10['upgrade_costs.option_20_cost_usd'] > 0, 'upgrade_costs.option_20_cost_usd'] = HPWH_80

#Clothes Dryer|Electric, Premium, Heat Pump, Ventless, 80% Usage
up10.loc[up10['upgrade_costs.option_21_cost_usd'] > 0, 'upgrade_costs.option_21_cost_usd'] = dryer_HP
#Clothes Dryer|Electric, Premium, Heat Pump, Ventless, 100% Usage
up10.loc[up10['upgrade_costs.option_22_cost_usd'] > 0, 'upgrade_costs.option_22_cost_usd'] = dryer_HP
#Clothes Dryer|Electric, Premium, Heat Pump, Ventless, 120% Usage
up10.loc[up10['upgrade_costs.option_23_cost_usd'] > 0, 'upgrade_costs.option_23_cost_usd'] = dryer_HP

#Cooking Range|Electric, Induction, 80% Usage
up10.loc[up10['upgrade_costs.option_24_cost_usd'] > 0, 'upgrade_costs.option_24_cost_usd'] = induction_range
#Cooking Range|Electric, Induction, 100% Usage
up10.loc[up10['upgrade_costs.option_25_cost_usd'] > 0, 'upgrade_costs.option_25_cost_usd'] = induction_range
#Cooking Range|Electric, Induction, 120% Usage
up10.loc[up10['upgrade_costs.option_26_cost_usd'] > 0, 'upgrade_costs.option_26_cost_usd'] = induction_range

#bill
up10.loc[up10['report_simulation_output.fuel_use_electricity_net_m_btu'] > 0, 'bill_electricity_USD'] = up10['report_simulation_output.fuel_use_electricity_net_m_btu']*0.293*ele_price*0.01+ele_month_fix*12
up10.loc[up10['report_simulation_output.fuel_use_electricity_net_m_btu'] == 0, 'bill_electricity_USD'] = 0
up10.loc[up10['report_simulation_output.fuel_use_natural_gas_total_m_btu'] > 0, 'bill_natural_gas_USD'] = up10['report_simulation_output.fuel_use_natural_gas_total_m_btu']*0.01*gas_price+gas_month_fix*12
up10.loc[up10['report_simulation_output.fuel_use_natural_gas_total_m_btu'] == 0, 'bill_natural_gas_USD'] = 0
up10.loc[up10['report_simulation_output.fuel_use_propane_total_m_btu'] > 0, 'bill_propane__USD'] = up10['report_simulation_output.fuel_use_propane_total_m_btu']*10.929*propane_price+propane_month_fix*12
up10.loc[up10['report_simulation_output.fuel_use_propane_total_m_btu'] == 0, 'bill_propane__USD'] = 0
up10.loc[up10['report_simulation_output.fuel_use_fuel_oil_total_m_btu'] > 0, 'bill_fuel_oil_USD'] = up10['report_simulation_output.fuel_use_fuel_oil_total_m_btu']*7.407*oil_price+oil_month_fix*12 # 7.407 is for Kerosene
up10.loc[up10['report_simulation_output.fuel_use_fuel_oil_total_m_btu'] == 0, 'bill_fuel_oil_USD'] = 0
up10['total_bill_USD'] = up10['bill_electricity_USD']+up10['bill_natural_gas_USD']+up10['bill_propane__USD']+up10['bill_fuel_oil_USD']

#total cost
up10.loc[up10['upgrade_costs.upgrade_cost_usd'] > 0, 'upgrade_costs.upgrade_cost_usd'] = up10['upgrade_costs.option_01_cost_usd'].fillna(0)+up10['upgrade_costs.option_02_cost_usd'].fillna(0)+up10['upgrade_costs.option_03_cost_usd'].fillna(0)+up10['upgrade_costs.option_04_cost_usd'].fillna(0)+up10['upgrade_costs.option_05_cost_usd'].fillna(0)+up10['upgrade_costs.option_06_cost_usd'].fillna(0)+up10['upgrade_costs.option_07_cost_usd'].fillna(0)+up10['upgrade_costs.option_08_cost_usd'].fillna(0)+up10['upgrade_costs.option_09_cost_usd'].fillna(0)+up10['upgrade_costs.option_10_cost_usd'].fillna(0)+up10['upgrade_costs.option_11_cost_usd'].fillna(0)+up10['upgrade_costs.option_12_cost_usd'].fillna(0)+up10['upgrade_costs.option_13_cost_usd'].fillna(0)+up10['upgrade_costs.option_14_cost_usd'].fillna(0)+up10['upgrade_costs.option_16_cost_usd'].fillna(0)+up10['upgrade_costs.option_18_cost_usd'].fillna(0)+up10['upgrade_costs.option_19_cost_usd'].fillna(0)+up10['upgrade_costs.option_20_cost_usd'].fillna(0)+up10['upgrade_costs.option_21_cost_usd'].fillna(0)+up10['upgrade_costs.option_22_cost_usd'].fillna(0)+up10['upgrade_costs.option_23_cost_usd'].fillna(0)+up10['upgrade_costs.option_24_cost_usd'].fillna(0)+up10['upgrade_costs.option_25_cost_usd'].fillna(0)+up10['upgrade_costs.option_26_cost_usd'].fillna(0)
up10.to_csv('results/up10_test.csv')