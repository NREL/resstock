from buildstock_query import BuildStockQuery
import pandas as pd

##TO DO change the inpute data for new communities

price_ele_monthly_fixed_charge = 14.5 # $/month
price_ele_summer_1 = 0.124384 # $/kwh
price_ele_summer_2 = 0.126913 # $/kwh
price_ele_summer_boundary = 1000.00 # kwh
price_ele_winter_1 = 0.124384 # $/kwh
price_ele_winter_2 = 0.112384 # $/kwh
price_ele_winter_boundary = 750.00 # kwh
price_gas_monthly_fixed_charge = 7.98 #$/month
price_gas_1 = 1.9 # $/therm
price_gas_2 = 1.64 # $/therm
price_gas_3 = 1.59 # $/therm
price_gas_boundary_1 = 48.26 # therm
price_gas_boundary_2 = 193.05 # therm
KBTU_TO_THERM = 1e-2

"""
16 individual upgrades or packages and their savings:
-   [1] enclosure.basic_upgrade: 
        all (pkg 1)
-   [2] enclosure.enhanced_upgrade: 
        all (pkg 2)
-   [3] hvac.heat_pump_min_eff_electric_backup: 
        all (pkg 3)
-   [4] hvac.heat_pump_high_eff_electric_backup: 
        all (pkg 4)
-   [5] hvac.heat_pump_min_eff_existing_backup: 
        all (pkg 5)
-   [6] hvac.heat_pump_high_eff_electric_backup + HPWH + enclosure.basic_upgrade: 
        Heating & Cooling (by excluding: ["clothes_dryer", "range_oven"]) (pkg 9)
-   [7] hvac.heat_pump_high_eff_electric_backup + HPWH + enclosure.enhanced_upgrade: 
        Heating & Cooling (by excluding: ["clothes_dryer", "range_oven"]) (pkg 10)
-   [8] water_heater.heat_pump: 
        all (pkg 6)
-   [9] clothes_dryer.electric: 
        Clothes dryer (pkg 7)
-   [10] clothes_dryer.heat_pump: 
        Clothes dryer (pkg 8, 9, 10)
-   [11] cooking.electric: 
        Cooking ("range_oven") (pkg 7)
-   [12] cooking.induction: 
        Cooking ("range_oven") (pkg 8, 9, 10)
-   [13] whole_home.electrification_min_eff: 
        all (pkg 7)
-   [14] whole_home.electrification_high_eff: 
        all (pkg 8)
-   [15] whole_home.electrification_high_eff + enclosure.basic_upgrade: 
        all (pkg 9)
-   [16] whole_home.electrification_high_eff + enclosure.enhanced_upgrade: 
        all (pkg 10)
"""

# cleap_euss_mapping, the key is cleap package number, the value is euss upgrade id
cleap_euss_mapping = {
    "0": "0",
    "1": "1",
    "2": "2",
    "3": "3",
    "4": "4",
    "5": "5",
    "6": "9",
    "7": "10",
    "8": "6",
    "9": "7",
    "10": "8",
    "11": "7",
    "12": "8",
    "13": "7",
    "14": "8",
    "15": "9",
    "16": "10",
}

upgrade_name_list = ['baseline',
                     'Basic Enclosure',
                     'Enhanced Enclosure',
                     'Mininum Efficiency Heat Pump with Electric Heat Backup',
                     'High Efficiency Heat Pump with Electric Heat Backup',
                     'Mininum Efficiency Heat Pump with Existing Heat Backup',
                     'Basic Enclosure + HPWH + High Efficiency HP/Electric Backup',
                     'Enhanced Enclosure + HPWH + High Efficiency HP/Electric Backup',
                     'Heat Pump Water Heater',
                     'Electric Clothes Dryer',
                     'Heat Pump Clothes Dryer',
                     'Electric Cooking',
                     'Induction Cooking',
                     'Mininum Efficiency Whole Home Electrification',
                     'High Efficiency Whole Home Electrification',
                     'Basic Enclosure + High Efficiency Whole Home Electrification',
                     'Enhanced Enclosure + High Efficiency Whole Home Electrification'] # 17 in total

my_run = BuildStockQuery(db_name='euss-final',
                        table_name='euss_res_final_2018_550k_20220901',
                        workgroup='factsheets',
                        buildstock_type='resstock',
                        skip_reports=True)

# get monthly electricity and natural gas consumption
def euss_monthly_data(upgrade_id, building_ids_list):
    ts_agg = my_run.agg.aggregate_timeseries(enduses=['fuel_use__electricity__total__kwh',
                                                      'end_use__electricity__clothes_dryer__kwh',
                                                      'end_use__electricity__range_oven__kwh',
                                                      'fuel_use__natural_gas__total__kbtu',
                                                      'end_use__natural_gas__clothes_dryer__kbtu',
                                                      'end_use__natural_gas__range_oven__kbtu'],
                                             timestamp_grouping_func='month',
                                             upgrade_id = upgrade_id,
                                             restrict=[('building_id', building_ids_list)],
                                             group_by=['building_id'])
    ts_agg['fuel_use__electricity__total__kwh'] =\
        ts_agg['fuel_use__electricity__total__kwh']/ts_agg['units_count']
    ts_agg['end_use__electricity__clothes_dryer__kwh'] =\
        ts_agg['end_use__electricity__clothes_dryer__kwh']/ts_agg['units_count']
    ts_agg['end_use__electricity__range_oven__kwh'] =\
        ts_agg['end_use__electricity__range_oven__kwh']/ts_agg['units_count']
    ts_agg['fuel_use__natural_gas__total__therm'] =\
        KBTU_TO_THERM * ts_agg['fuel_use__natural_gas__total__kbtu']/ts_agg['units_count']
    ts_agg['end_use__natural_gas__clothes_dryer__therm'] =\
        KBTU_TO_THERM * ts_agg['end_use__natural_gas__clothes_dryer__kbtu']/ts_agg['units_count']
    ts_agg['end_use__natural_gas__range_oven__therm'] =\
        KBTU_TO_THERM * ts_agg['end_use__natural_gas__range_oven__kbtu']/ts_agg['units_count']
    ts_agg = ts_agg.drop(['sample_count',
                          'units_count',
                          'rows_per_sample',
                          'fuel_use__natural_gas__total__kbtu',
                          'end_use__natural_gas__clothes_dryer__kbtu',
                          'end_use__natural_gas__range_oven__kbtu'], axis=1)

    ts_agg_month = {}
    for mon in range (1, 10):
        ts_agg_month[f'ts_agg_{mon}'] =\
        ts_agg[ts_agg['time'].astype(str).str.contains(f'0{mon}-01')]
    for mon in range (10, 13):
        ts_agg_month[f'ts_agg_{mon}'] =\
            ts_agg[ts_agg['time'].astype(str).str.contains(f'{mon}-01')]
    
    ts_agg_month['ts_agg_1'] =\
        ts_agg_month['ts_agg_1'].rename(columns={
            'fuel_use__electricity__total__kwh': f'fuel_use__electricity__total__1__kwh',
            'end_use__electricity__clothes_dryer__kwh': f'end_use__electricity__clothes_dryer__1__kwh',
            'end_use__electricity__range_oven__kwh': f'end_use__electricity__range_oven__1__kwh',
            'fuel_use__natural_gas__total__therm': f'fuel_use__natural_gas__total__1__therm',
            'end_use__natural_gas__clothes_dryer__therm': f'end_use__natural_gas__clothes_dryer__1__therm',
            'end_use__natural_gas__range_oven__therm':f'end_use__natural_gas__range_oven__1__therm'})
    euss_monthly_data = ts_agg_month['ts_agg_1'].drop(['time'], axis=1)
    
    for mon in range (2, 13):
        ts_agg_month[f'ts_agg_{mon}'] =\
            ts_agg_month[f'ts_agg_{mon}'].rename(columns={
                'fuel_use__electricity__total__kwh': f'fuel_use__electricity__total__{mon}__kwh',
                'end_use__electricity__clothes_dryer__kwh': f'end_use__electricity__clothes_dryer__{mon}__kwh',
                'end_use__electricity__range_oven__kwh': f'end_use__electricity__range_oven__{mon}__kwh',
                'fuel_use__natural_gas__total__therm': f'fuel_use__natural_gas__total__{mon}__therm',
                'end_use__natural_gas__clothes_dryer__therm': f'end_use__natural_gas__clothes_dryer__{mon}__therm',
                'end_use__natural_gas__range_oven__therm': f'end_use__natural_gas__range_oven__{mon}__therm'})
        
        ts_agg_month[f'ts_agg_{mon}'] = ts_agg_month[f'ts_agg_{mon}'].drop(['time'], axis=1)
        euss_monthly_data = euss_monthly_data.join(ts_agg_month[f'ts_agg_{mon}'].set_index('building_id'), on='building_id')
        
    euss_monthly_data = euss_monthly_data.reset_index(drop=True)
    
    return euss_monthly_data

 # recaculate the monthly electricity and natural gas consumption for 16 upgrade packages needed in cleap 
def recaculate_monthly_data(euss_results_up, euss_baseline, building_ids_list, type):
    if type == 'all':
        euss_results_recaculate_up = euss_results_up
    elif type == 'dryer':
        euss_baseline_up = euss_baseline.loc[euss_baseline['building_id'].isin(building_ids_list)]
        euss_baseline_up = euss_baseline_up.reset_index(drop=True)
        euss_results_recaculate_up = euss_results_up.loc[euss_results_up['building_id'].isin(building_ids_list)]
        euss_results_recaculate_up= euss_results_recaculate_up.reset_index(drop=True)
        for mon in range (1, 13):
            euss_results_recaculate_up[f'fuel_use__electricity__total__{mon}__kwh'] =\
            euss_baseline_up[f'fuel_use__electricity__total__{mon}__kwh'] -\
            (euss_baseline_up[f'end_use__electricity__clothes_dryer__{mon}__kwh'].fillna(0) -\
             euss_results_recaculate_up[f'end_use__electricity__clothes_dryer__{mon}__kwh'].fillna(0))
            euss_results_recaculate_up[f'fuel_use__natural_gas__total__{mon}__therm'] =\
            euss_baseline_up[f'fuel_use__natural_gas__total__{mon}__therm'] -\
            (euss_baseline_up[f'end_use__natural_gas__clothes_dryer__{mon}__therm'].fillna(0) -\
             euss_results_recaculate_up[f'end_use__natural_gas__clothes_dryer__{mon}__therm'].fillna(0))
    elif type == 'cooking':
        euss_baseline_up = euss_baseline.loc[euss_baseline['building_id'].isin(building_ids_list)]
        euss_baseline_up = euss_baseline_up.reset_index(drop=True)
        euss_results_recaculate_up = euss_results_up.loc[euss_results_up['building_id'].isin(building_ids_list)]
        euss_results_recaculate_up= euss_results_recaculate_up.reset_index(drop=True)
        for mon in range (1, 13):
            euss_results_recaculate_up[f'fuel_use__electricity__total__{mon}__kwh'] =\
            euss_baseline_up[f'fuel_use__electricity__total__{mon}__kwh'] -\
            (euss_baseline_up[f'end_use__electricity__range_oven__{mon}__kwh'].fillna(0) -\
             euss_results_recaculate_up[f'end_use__electricity__range_oven__{mon}__kwh'].fillna(0))
            euss_results_recaculate_up[f'fuel_use__natural_gas__total__{mon}__therm'] =\
            euss_baseline_up[f'fuel_use__natural_gas__total__{mon}__therm'] -\
            (euss_baseline_up[f'end_use__natural_gas__range_oven__{mon}__therm'].fillna(0) -\
             euss_results_recaculate_up[f'end_use__natural_gas__range_oven__{mon}__therm'].fillna(0))
    elif type == 'no_dryer_cooking':
        euss_baseline_up = euss_baseline.loc[euss_baseline['building_id'].isin(building_ids_list)]
        euss_baseline_up = euss_baseline_up.reset_index(drop=True)
        euss_results_recaculate_up = euss_results_up.loc[euss_results_up['building_id'].isin(building_ids_list)]
        euss_results_recaculate_up = euss_results_recaculate_up.reset_index(drop=True)
        for mon in range (1, 13):
            euss_results_recaculate_up[f'fuel_use__electricity__total__{mon}__kwh'] +=\
                (euss_baseline_up[f'end_use__electricity__clothes_dryer__{mon}__kwh'].fillna(0) -\
                 euss_results_recaculate_up[f'end_use__electricity__clothes_dryer__{mon}__kwh'].fillna(0)) +\
                (euss_baseline_up[f'end_use__electricity__range_oven__{mon}__kwh'].fillna(0) -\
                 euss_results_recaculate_up[f'end_use__electricity__range_oven__{mon}__kwh'].fillna(0))
            euss_results_recaculate_up[f'fuel_use__natural_gas__total__{mon}__therm'] +=\
                (euss_baseline_up[f'end_use__natural_gas__clothes_dryer__{mon}__therm'].fillna(0) -\
                 euss_results_recaculate_up[f'end_use__natural_gas__clothes_dryer__{mon}__therm'].fillna(0)) +\
                (euss_baseline_up[f'end_use__natural_gas__range_oven__{mon}__therm'].fillna(0) -\
                 euss_results_recaculate_up[f'end_use__natural_gas__range_oven__{mon}__therm'].fillna(0))
    return euss_results_recaculate_up

# calculate the annual tiered bill of electricity and natural gas based on the monthly consumption data
def tiered_bill(euss_results_up):
    # calculate the monthly tiered bill of electricity
    # tiered electricity bill in summer 
    for mon in range (6, 10):
        euss_results_up[f'cbill.electricity__tiered__{mon}__usd'] = ""
        for building in range (len(euss_results_up[f'fuel_use__electricity__total__{mon}__kwh'])):
            if euss_results_up[f'fuel_use__electricity__total__{mon}__kwh'][building] == 0:
                euss_results_up[f'cbill.electricity__tiered__{mon}__usd'][building] =0
            elif euss_results_up[f'fuel_use__electricity__total__{mon}__kwh'][building] <= price_ele_summer_boundary:
                euss_results_up[f'cbill.electricity__tiered__{mon}__usd'][building] =\
                    price_ele_monthly_fixed_charge +\
                    euss_results_up[f'fuel_use__electricity__total__{mon}__kwh'][building]*price_ele_summer_1
            else:
                euss_results_up[f'cbill.electricity__tiered__{mon}__usd'][building] =\
                    price_ele_monthly_fixed_charge +\
                    price_ele_summer_boundary*price_ele_summer_1 +\
                    (euss_results_up[f'fuel_use__electricity__total__{mon}__kwh'][building]-price_ele_summer_boundary)*price_ele_summer_2
    # tiered electricity bill in winter
    for mon in [1, 2, 3, 4, 5, 10, 11, 12]:
        euss_results_up[f'cbill.electricity__tiered__{mon}__usd'] = ""
        for building in range (len(euss_results_up[f'fuel_use__electricity__total__{mon}__kwh'])):
            if euss_results_up[f'fuel_use__electricity__total__{mon}__kwh'][building] == 0:
                euss_results_up[f'cbill.electricity__tiered__{mon}__usd'][building] =0
            elif euss_results_up[f'fuel_use__electricity__total__{mon}__kwh'][building] <= price_ele_winter_boundary:
                euss_results_up[f'cbill.electricity__tiered__{mon}__usd'][building] =\
                    price_ele_monthly_fixed_charge +\
                    euss_results_up[f'fuel_use__electricity__total__{mon}__kwh'][building]*price_ele_winter_1
            else:
                euss_results_up[f'cbill.electricity__tiered__{mon}__usd'][building] =\
                    price_ele_monthly_fixed_charge +\
                    price_ele_winter_boundary*price_ele_winter_1 +\
                    (euss_results_up[f'fuel_use__electricity__total__{mon}__kwh'][building]-price_ele_winter_boundary)*price_ele_winter_2
    
    # calculate the monthly tiered bill of natural gas            
    for mon in range (1, 13):
        euss_results_up[f'cbill.natural_gas__tiered__{mon}__usd'] = ""
        for building in range (len(euss_results_up[f'fuel_use__natural_gas__total__{mon}__therm'])):
            if euss_results_up[f'fuel_use__natural_gas__total__{mon}__therm'][building] == 0:
                euss_results_up[f'cbill.natural_gas__tiered__{mon}__usd'][building] = 0  
            elif euss_results_up[f'fuel_use__natural_gas__total__{mon}__therm'][building] <= price_gas_boundary_1:
                euss_results_up[f'cbill.natural_gas__tiered__{mon}__usd'][building] =\
                    price_gas_monthly_fixed_charge +\
                    euss_results_up[f'fuel_use__natural_gas__total__{mon}__therm'][building]*price_gas_1  
            elif euss_results_up[f'fuel_use__natural_gas__total__{mon}__therm'][building] <= price_gas_boundary_2:
                euss_results_up[f'cbill.natural_gas__tiered__{mon}__usd'][building] =\
                    price_gas_monthly_fixed_charge +\
                    price_gas_boundary_1*price_gas_1 +\
                    (euss_results_up[f'fuel_use__natural_gas__total__{mon}__therm'][building]-price_gas_boundary_1)*price_gas_2
            else:
                euss_results_up[f'cbill.natural_gas__tiered__{mon}__usd'][building] =\
                    price_gas_monthly_fixed_charge +\
                    price_gas_boundary_1*price_gas_1 +\
                    (price_gas_boundary_2-price_gas_boundary_1)*price_gas_2 +\
                    (euss_results_up[f'fuel_use__natural_gas__total__{mon}__therm'][building]-price_gas_boundary_2)*price_gas_3
                
    # calculate the annual tired bill of electricity and natural gas
    euss_results_up['cbill.electricity__tiered__usd'] = 0
    euss_results_up['cbill.natural_gas__tiered__usd'] = 0
    for mon in range (1, 13):
        euss_results_up['cbill.electricity__tiered__usd'] +=\
            euss_results_up[f'cbill.electricity__tiered__{mon}__usd']
        euss_results_up['cbill.natural_gas__tiered__usd'] +=\
            euss_results_up[f'cbill.natural_gas__tiered__{mon}__usd']

    return euss_results_up[['building_id', 'cbill.electricity__tiered__usd', 'cbill.natural_gas__tiered__usd']]

# calculate the annual bill savings based on the baseline bill in community_results_baseline_up and community_results_upgrade_up
def saving_calculation(community_results_baseline_up, community_results_upgrade_up):
    community_results_up = community_results_baseline_up.join(community_results_upgrade_up.set_index('building_id'), on = 'building_id')
    community_results_up['saving_cbill.electricity_tiered_usd'] =\
        community_results_up['baseline_cbill.electricity__tiered__usd'] -\
        community_results_up['cbill.electricity__tiered__usd'] 
    community_results_up['pct_saving_cbill.electricity_tiered_%'] =\
        community_results_up['saving_cbill.electricity_tiered_usd']/community_results_up['baseline_cbill.electricity__tiered__usd'] * 100
    community_results_up =\
        community_results_up.drop(['cbill.electricity__tiered__usd'], axis=1)

    community_results_up['saving_cbill.natural_gas_tiered_usd'] =\
        community_results_up['baseline_cbill.natural_gas__tiered__usd'] -\
        community_results_up['cbill.natural_gas__tiered__usd'] 
    community_results_up['pct_saving_cbill.natural_gas_tiered_%'] =\
        community_results_up['saving_cbill.natural_gas_tiered_usd']/community_results_up['baseline_cbill.natural_gas__tiered__usd'] * 100
    community_results_up =\
        community_results_up.drop(['cbill.natural_gas__tiered__usd'], axis=1)
    
    return community_results_up

def main(community):
    data = pd.read_parquet(f"data_/community_building_samples_with_upgrade_cost_and_bill/{community}/processed_upgrade_results.parquet")
    cleap_results = {} # results before calculating tired bill
    for up in range (len(upgrade_name_list)):
        cleap_results[f'{up}'] = data.loc[data['upgrade_name'] == upgrade_name_list[up]]
        cleap_results[f'{up}'] = cleap_results[f'{up}'].reset_index(drop=True)
    
    building_ids_list = {} # building id in each upgrade/package
    for up in cleap_results:
        building_ids_list[f'{up}'] = cleap_results[up].building_id.tolist()
    
    euss_results = {} # results from euss, which have monthly electricity and natural gas consumption data
    for up in cleap_euss_mapping:
        euss_results[f'{up}'] = euss_monthly_data(cleap_euss_mapping[up],
                                                  building_ids_list[up])

    community_results = pd.DataFrame() # results after calculating tired bill
    all_frame = []
    euss_baseline_tired_bill = tiered_bill(euss_results['0'])
    euss_baseline_tired_bill =\
        euss_baseline_tired_bill.rename(columns={'cbill.electricity__tiered__usd': 'baseline_cbill.electricity__tiered__usd',
                                                 'cbill.natural_gas__tiered__usd': 'baseline_cbill.natural_gas__tiered__usd'})
    community_results_baseline =\
        cleap_results['0'].join(euss_baseline_tired_bill.set_index('building_id'), on='building_id')
    all_frame.append(community_results_baseline)

    for up in (cleap_euss_mapping):
        if up == '0':
            pass
        else:
            community_results_baseline_up = community_results_baseline.loc[community_results_baseline['building_id'].isin(building_ids_list[f'{up}'])]
            cleap_results[f'{up}'] =\
                cleap_results[f'{up}'].join(community_results_baseline_up.loc[:, ['building_id',
                                                                                  'baseline_cbill.electricity__tiered__usd',
                                                                                  'baseline_cbill.natural_gas__tiered__usd']].set_index('building_id'),
                                                                          on = 'building_id')
            if up in ['1', '2', '3', '4', '5', '8', '13', '14', '15', '16']:
                package_type = 'all'
            elif up in ['6', '7']:
                package_type = 'no_dryer_cooking'
            elif up in ['9', '10']:
                package_type = 'dryer'
            elif up in ['11', '12']:
                package_type = 'cooking'
            euss_results_up = recaculate_monthly_data(euss_results[f'{up}'],
                                                      euss_results['0'],
                                                      building_ids_list[f'{up}'],
                                                      package_type)
            tired_bill_up = tiered_bill(euss_results_up)
            community_results_up = saving_calculation(cleap_results[f'{up}'], tired_bill_up)
            all_frame.append(community_results_up)
    
    community_results = pd.concat(all_frame)

    community_results['baseline_cbill.electricity_usd'] =\
        community_results['baseline_cbill.electricity__tiered__usd']
    community_results['saving_cbill.electricity_usd'] =\
        community_results['saving_cbill.electricity_tiered_usd']
    community_results['pct_saving_cbill.electricity_%'] =\
        community_results['pct_saving_cbill.electricity_tiered_%']
    community_results['baseline_cbill.natural_gas_usd'] =\
        community_results['baseline_cbill.natural_gas__tiered__usd']
    community_results['saving_cbill.natural_gas_usd'] =\
        community_results['saving_cbill.natural_gas_tiered_usd']
    community_results['pct_saving_cbill.natural_gas_%'] =\
        community_results['pct_saving_cbill.natural_gas_tiered_%']
    
    community_results = community_results.drop(['baseline_cbill.electricity__tiered__usd',
                                                'saving_cbill.electricity_tiered_usd',
                                                'pct_saving_cbill.electricity_tiered_%',
                                                'baseline_cbill.natural_gas__tiered__usd',
                                                'saving_cbill.natural_gas_tiered_usd',
                                                'pct_saving_cbill.natural_gas_tiered_%'], axis=1)
    
    community_results['baseline_cbill.total_usd'] =\
        community_results['baseline_cbill.electricity_usd'].fillna(0) +\
        community_results['baseline_cbill.natural_gas_usd'].fillna(0) +\
        community_results['baseline_cbill.fuel_oil_usd'].fillna(0) +\
        community_results['baseline_cbill.propane_usd'].fillna(0)
    community_results['saving_cbill.total_usd'] =\
        community_results['saving_cbill.electricity_usd'].fillna(0) +\
        community_results['saving_cbill.natural_gas_usd'].fillna(0) +\
        community_results['saving_cbill.fuel_oil_usd'].fillna(0) +\
        community_results['saving_cbill.propane_usd'].fillna(0)
    community_results['pct_saving_cbill.total_%'] =\
        community_results['saving_cbill.total_usd']/community_results['baseline_cbill.total_usd'] * 100
    
    community_results['baseline_energy_burden_2023_cbills.%'] =\
        community_results['baseline_cbill.total_usd']/community_results['rep_income'] * 100
    community_results['post-upgrade_energy_burden_2023_cbills.%'] =\
        (community_results['baseline_cbill.total_usd']-community_results['saving_cbill.total_usd'])/community_results['rep_income'] * 100

    
    community_results.to_csv(f"data_/community_building_samples_with_upgrade_cost_and_bill/{community}/processed_upgrade_results_tiered.csv")
    community_results.to_parquet(f"data_/community_building_samples_with_upgrade_cost_and_bill/{community}/processed_upgrade_results_tiered.parquet")

main('north_birmingham')