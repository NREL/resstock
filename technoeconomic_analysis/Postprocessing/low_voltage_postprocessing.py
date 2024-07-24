import pandas as pd
import numpy as np

#summrize the failed building id
def failed_building_id(file_path, up_list):
    total_failed_building_id = []
    df0 = pd.read_parquet(f'{file_path}/results_up00.parquet')
    vacant = df0.loc[df0['build_existing_model.vacancy_status'] == 'Vacant']['building_id']
    vacant = vacant.tolist()
    failed_baseline = df0.loc[df0['completed_status'] == 'Fail']['building_id']
    failed_baseline = failed_baseline.tolist()

    for up in up_list:
        df_failed = pd.DataFrame(columns=['failed_building_id'])
        df = pd.read_parquet(f'{file_path}/results_up{up}.parquet')
        df = df.loc[~df['building_id'].isin(vacant)]
        df = df.loc[~df['building_id'].isin(failed_baseline)]
        failed_building_id = df.loc[df['completed_status'] == 'Fail']['building_id']
        failed_building_id = failed_building_id.tolist()
        total_failed_building_id = total_failed_building_id + failed_building_id
        df_failed['failed_building_id'] = failed_building_id 
        df_failed.to_csv(f'{file_path}/failed_building_id{up}.csv', index=False)
    total_failed_building_id_unique = []
    for x in total_failed_building_id:
        if x not in total_failed_building_id_unique:
            total_failed_building_id_unique.append(x)
    df = pd.DataFrame(total_failed_building_id_unique, columns=['building_id'])
    df.to_csv(f'{file_path}/failed_building_id_total.csv', index=False)


#Remove vacant units, delete invalid and failed run
def data_cleaning(file_path, up_list):
    df0 = pd.read_parquet(f'{file_path}/results_up00.parquet')
    vacant = df0.loc[df0['build_existing_model.vacancy_status'] == 'Vacant']['building_id']
    vacant = vacant.tolist()
    failed_baseline = df0.loc[df0['completed_status'] == 'Fail']['building_id']
    failed_baseline = failed_baseline.tolist()

    for up in up_list:
        df = pd.read_parquet(f'{file_path}/results_up{up}.parquet')
        df = df.loc[~df['building_id'].isin(vacant)]
        df = df.loc[~df['building_id'].isin(failed_baseline)]
        df = df.loc[df['completed_status'] == 'Success']
        df['report_simulation_output.unmet_loads_hot_water_shower_energy_j'] = df['report_simulation_output.unmet_loads_hot_water_shower_energy_j']*900
        if up == '00':
            df['build_existing_model.heating_fuel'].fillna(value='None', inplace=True)
        df.to_csv(f'{file_path}/data_cleaning_results_up{up}.csv', index=False)

#revise the upgrade name for Low-voltage Upgrades
def hp_dryer_name(df):
    df['upgrade_costs.option_15_name'] = df['upgrade_costs.option_15_name'].replace('Clothes Dryer|Electric', 'Clothes Dryer|Electric Heat Pump, 120V')
    return df
def low_vol_cooking_name(df):
    df['upgrade_costs.option_14_name'] = df['upgrade_costs.option_14_name'].replace('Cooking Range|Electric Resistance', 'Cooking Range|Electric Induction, 120V, battery powered')
    return df

# Create new low-voltage upgrade that only has 120V HPWHs and 120V dryers
def create_new_low_vol_upgrade(file_path, up, upgrade_name, file_name):
    df = pd.read_csv(f'{file_path}/data_cleaning_results_up{up}.csv')
    df['apply_upgrade.upgrade_name'] = upgrade_name
    df = hp_dryer_name(df)
    df.to_csv(f'{file_path}/data_cleaning_{file_name}.csv', index=False)

#update energy and emissions for low-voltage appliance
def dryer_cooking_data_postprocesing(df):
    for i, row in df.iterrows():
        emission_dryer = row['report_simulation_output.emissions_co_2_e_lrmer_low_re_cost_25_electricity_clothes_dryer_lb']
        emission_cooking = row['report_simulation_output.emissions_co_2_e_lrmer_low_re_cost_25_electricity_range_oven_lb']
        emission_ele = row['report_simulation_output.emissions_co_2_e_lrmer_low_re_cost_25_electricity_total_lb']
        emission_total = row['report_simulation_output.emissions_co_2_e_lrmer_low_re_cost_25_total_lb']
        
        ele_dryer = row['report_simulation_output.end_use_electricity_clothes_dryer_m_btu']
        ele_cooking = row['report_simulation_output.end_use_electricity_range_oven_m_btu']
        ele_net = row['report_simulation_output.fuel_use_electricity_net_m_btu']
        ele_total = row['report_simulation_output.fuel_use_electricity_total_m_btu']
        energy_total = row['report_simulation_output.energy_use_total_m_btu']
        
        bills_ele_energy = row['report_utility_bills.utility_rates_fixed_variable_electricity_energy_usd']
        bills_ele_total = row['report_utility_bills.utility_rates_fixed_variable_electricity_total_usd']
        bills_total = row['report_utility_bills.utility_rates_fixed_variable_total_usd']
        
        #update cooking and dryer emission and electricity
        if row['upgrade_costs.option_14_name'] == 'Cooking Range|Electric Induction, 120V, battery powered':
            df.at[i, 'report_simulation_output.emissions_co_2_e_lrmer_low_re_cost_25_electricity_range_oven_lb'] = 0.91*emission_cooking
            df.at[i, 'report_simulation_output.end_use_electricity_range_oven_m_btu'] = 0.91*ele_cooking
        if row['upgrade_costs.option_15_name'] == 'Clothes Dryer|Electric Heat Pump, 120V':
            df.at[i, 'report_simulation_output.emissions_co_2_e_lrmer_low_re_cost_25_electricity_clothes_dryer_lb'] = 0.6*emission_dryer
            df.at[i, 'report_simulation_output.end_use_electricity_clothes_dryer_m_btu'] = 0.6*ele_dryer            
     
        #update total emission, electricity, and bills
        #both cooking and dryer
        if row['upgrade_costs.option_14_name'] == 'Cooking Range|Electric Induction, 120V, battery powered' and\
        row['upgrade_costs.option_15_name'] == 'Clothes Dryer|Electric Heat Pump, 120V':
            df.at[i, 'report_simulation_output.emissions_co_2_e_lrmer_low_re_cost_25_electricity_total_lb'] = emission_ele-0.4*emission_dryer-0.09*emission_cooking           
            df.at[i, 'report_simulation_output.emissions_co_2_e_lrmer_low_re_cost_25_total_lb'] = emission_total-0.4*emission_dryer-0.09*emission_cooking           
            df.at[i, 'report_simulation_output.fuel_use_electricity_net_m_btu'] = ele_net-0.4*ele_dryer-0.09*ele_cooking
            ele_total_new = ele_total-0.4*ele_dryer-0.09*ele_cooking
            df.at[i, 'report_simulation_output.fuel_use_electricity_total_m_btu'] = ele_total_new
            df.at[i, 'report_simulation_output.energy_use_total_m_btu'] = energy_total-0.4*ele_dryer-0.09*ele_cooking
            bills_ele_energy_new = bills_ele_energy/ele_total*ele_total_new
            df.at[i, 'report_utility_bills.utility_rates_fixed_variable_electricity_energy_usd'] = bills_ele_energy_new
            df.at[i, 'report_utility_bills.utility_rates_fixed_variable_electricity_total_usd'] = bills_ele_total - bills_ele_energy + bills_ele_energy_new
            df.at[i, 'report_utility_bills.utility_rates_fixed_variable_total_usd'] = bills_total - bills_ele_energy + bills_ele_energy_new
        #only cooking                
        elif row['upgrade_costs.option_14_name'] == 'Cooking Range|Electric Induction, 120V, battery powered' and\
        row['upgrade_costs.option_15_name'] != 'Clothes Dryer|Electric Heat Pump, 120V':
            df.at[i, 'report_simulation_output.emissions_co_2_e_lrmer_low_re_cost_25_electricity_total_lb'] = emission_ele-0.09*emission_cooking           
            df.at[i, 'report_simulation_output.emissions_co_2_e_lrmer_low_re_cost_25_total_lb'] = emission_total-0.09*emission_cooking           
            df.at[i, 'report_simulation_output.fuel_use_electricity_net_m_btu'] = ele_net-0.09*ele_cooking
            ele_total_new = ele_total-0.09*ele_cooking
            df.at[i, 'report_simulation_output.fuel_use_electricity_total_m_btu'] = ele_total_new
            df.at[i, 'report_simulation_output.energy_use_total_m_btu'] = energy_total-0.09*ele_cooking
            bills_ele_energy_new = bills_ele_energy/ele_total*ele_total_new
            df.at[i, 'report_utility_bills.utility_rates_fixed_variable_electricity_energy_usd'] = bills_ele_energy_new
            df.at[i, 'report_utility_bills.utility_rates_fixed_variable_electricity_total_usd'] = bills_ele_total - bills_ele_energy + bills_ele_energy_new
            df.at[i, 'report_utility_bills.utility_rates_fixed_variable_total_usd'] = bills_total - bills_ele_energy + bills_ele_energy_new
        #only dryer
        elif row['upgrade_costs.option_14_name'] != 'Cooking Range|Electric Induction, 120V, battery powered' and\
        row['upgrade_costs.option_15_name'] == 'Clothes Dryer|Electric Heat Pump, 120V':
            df.at[i, 'report_simulation_output.emissions_co_2_e_lrmer_low_re_cost_25_electricity_total_lb'] = emission_ele-0.4*emission_dryer           
            df.at[i, 'report_simulation_output.emissions_co_2_e_lrmer_low_re_cost_25_total_lb'] = emission_total-0.4*emission_dryer           
            df.at[i, 'report_simulation_output.fuel_use_electricity_net_m_btu'] = ele_net-0.4*ele_dryer
            ele_total_new = ele_total-0.4*ele_dryer
            df.at[i, 'report_simulation_output.fuel_use_electricity_total_m_btu'] = ele_total_new
            df.at[i, 'report_simulation_output.energy_use_total_m_btu'] = energy_total-0.4*ele_dryer
            bills_ele_energy_new = bills_ele_energy/ele_total*ele_total_new
            df.at[i, 'report_utility_bills.utility_rates_fixed_variable_electricity_energy_usd'] = bills_ele_energy_new
            df.at[i, 'report_utility_bills.utility_rates_fixed_variable_electricity_total_usd'] = bills_ele_total - bills_ele_energy + bills_ele_energy_new
            df.at[i, 'report_utility_bills.utility_rates_fixed_variable_total_usd'] = bills_total - bills_ele_energy + bills_ele_energy_new

    return df

## main code
file_path = 'full_run'
up_list = ['00','01','02','03','04','05','06','07','08','09','10','11','12','13','14','15']
low_vol_dryer_cooking_list = ['06','07','13','14']
low_vol_dryer_list = ['16_up06_only_hpwh_dryer',
                      '17_up07_only_hpwh_dryer',
                      '18_up13_only_hpwh_dryer',
                      '19_up14_only_hpwh_dryer']
low_vol_up_list = low_vol_dryer_cooking_list + low_vol_dryer_list

failed_building_id(file_path, up_list)

# data cleaning
data_cleaning(file_path, up_list)

# For low voltage upgrade measure with both cooking and dryer, update option name
for up in low_vol_dryer_cooking_list:
    df = pd.read_csv(f'{file_path}/data_cleaning_results_up{up}.csv')
    df = hp_dryer_name(df)
    df = low_vol_cooking_name(df)
    df.to_csv(f'{file_path}/data_cleaning_results_up{up}.csv', index=False)

# Create new low-voltage upgrade that only has 120V HPWHs and 120V dryers
create_new_low_vol_upgrade(file_path,
                           '06',
                           '1.6 Low-voltage Electrification only hpwh and dryer',
                           'results_up16_up06_only_hpwh_dryer')
create_new_low_vol_upgrade(file_path,
                           '07',
                           '1.7 High Efficiency and Low-voltage only hpwh and dryer Electrification',
                           'results_up17_up07_only_hpwh_dryer')
create_new_low_vol_upgrade(file_path,
                           '13',
                           '2.5 Low-voltage Electrification with Envelope only hpwh and dryer',
                           'results_up18_up13_only_hpwh_dryer')
create_new_low_vol_upgrade(file_path,
                           '14',
                           '2.6 High Efficiency and Low-voltage Electrification with Envelope only hpwh and dryer Electrification',
                           'results_up19_up14_only_hpwh_dryer')

# data postprocesing for energy, emission, and utility bills
for up in low_vol_up_list:
    df = pd.read_csv(f'{file_path}/data_cleaning_results_up{up}.csv')
    df = dryer_cooking_data_postprocesing(df)
    df.to_csv(f'{file_path}/data_cleaning_results_up{up}.csv', index=False)
