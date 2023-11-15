from buildstock_query import BuildStockQuery
import pandas as pd

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
                     'Enhanced Enclosure + High Efficiency Whole Home Electrification']

my_run = BuildStockQuery(db_name='euss-final',
                         table_name='euss_res_final_2018_550k_20220901',
                         workgroup='factsheets',
                         buildstock_type='resstock',
                         skip_reports=True)

def euss_TOU_bill(community, monthly_fixed_charge, euss_upgrade_id, building_ids_list):
    euss_results = my_run.utility.calculate_tou_bill(
        meter_col = ['fuel_use__electricity__total__kwh',
                     'end_use__electricity__clothes_dryer__kwh',
                     'end_use__electricity__range_oven__kwh'],
        rate_map = (f"data_/community_cost/TOU_{community}_weekday_cost.csv",
                    f"data_/community_cost/TOU_{community}_weekend_cost.csv"),
        upgrade_id = euss_upgrade_id,
        group_by = ["building_id"],
        restrict = [(my_run.ts_bldgid_column, building_ids_list)],
        collapse_ts = True,
    )
    
    euss_results['cbill.electricity__TOU__usd'] =\
        euss_results['fuel_use__electricity__total__kwh__TOU__dollars']/euss_results['units_count']\
        + monthly_fixed_charge * 12
    euss_results['cbill.electricity__clothes_dryer__TOU__usd'] =\
        euss_results['end_use__electricity__clothes_dryer__kwh__TOU__dollars']/euss_results['units_count']
    euss_results['cbill.electricity__range_oven__TOU__usd'] =\
        euss_results['end_use__electricity__range_oven__kwh__TOU__dollars']/euss_results['units_count']
    euss_results = euss_results.drop(['sample_count', 'units_count', 
                      'fuel_use__electricity__total__kwh__TOU__dollars',
                      'end_use__electricity__clothes_dryer__kwh__TOU__dollars',
                      'end_use__electricity__range_oven__kwh__TOU__dollars'], axis=1)
    return euss_results

def saving_calculation(cleap_results, euss_results, euss_baseline, building_ids_list, type):
    baseline = euss_baseline.loc[euss_baseline['building_id'].isin(building_ids_list)]
    community_results = cleap_results.join(baseline.set_index('building_id'), on='building_id')
    community_results = community_results.join(euss_results.set_index('building_id'), on='building_id')

    if type == 'all':
        community_results['saving_cbill.electricity_TOU_usd'] =\
            community_results['baseline_cbill.electricity__TOU__usd'] - community_results['cbill.electricity__TOU__usd']
    elif type == 'dryer':
         community_results['saving_cbill.electricity_TOU_usd'] =\
            community_results['baseline_cbill.electricity__clothes_dryer__TOU__usd'].fillna(0)\
            - community_results['cbill.electricity__clothes_dryer__TOU__usd'].fillna(0) 
    elif type == 'cooking':
        community_results['saving_cbill.electricity_TOU_usd'] =\
            community_results['baseline_cbill.electricity__range_oven__TOU__usd'].fillna(0)\
            - community_results['cbill.electricity__range_oven__TOU__usd'].fillna(0)
    elif type == 'no_dryer_cooking':
        community_results['saving_cbill.electricity_TOU_usd'] =\
            (community_results['baseline_cbill.electricity__TOU__usd'] -\
            community_results['baseline_cbill.electricity__clothes_dryer__TOU__usd'].fillna(0) -\
            community_results['baseline_cbill.electricity__range_oven__TOU__usd'].fillna(0)) -\
            (community_results['cbill.electricity__TOU__usd'] -\
            community_results['cbill.electricity__clothes_dryer__TOU__usd'].fillna(0) -\
            community_results['cbill.electricity__range_oven__TOU__usd'].fillna(0)) 
        
    community_results['pct_saving_cbill.electricity_TOU_%'] =\
        community_results['saving_cbill.electricity_TOU_usd']/community_results['baseline_cbill.electricity__TOU__usd'] * 100
    return community_results

def main(community, monthly_fixed_charge):
    data = pd.read_parquet(f"data_/community_building_samples_with_upgrade_cost_and_bill/{community}/processed_upgrade_results.parquet")
    
    cleap_results = {} 
    for up in range (len(upgrade_name_list )):
        cleap_results[f'{up}'] = data.loc[data['upgrade_name'] == upgrade_name_list[up]]
    
    building_ids_list = {}
    for up in cleap_results:
        building_ids_list[f'{up}'] = cleap_results[up].building_id.tolist()

    euss_results = {}
    for up in cleap_euss_mapping:
        euss_results[f'{up}'] = euss_TOU_bill(community, monthly_fixed_charge, cleap_euss_mapping[up], building_ids_list[up])
    
    euss_results['0'] =\
        euss_results['0'].rename(columns={'cbill.electricity__TOU__usd': 'baseline_cbill.electricity__TOU__usd',
                                          'cbill.electricity__clothes_dryer__TOU__usd': 'baseline_cbill.electricity__clothes_dryer__TOU__usd',
                                          'cbill.electricity__range_oven__TOU__usd': 'baseline_cbill.electricity__range_oven__TOU__usd'})
    
    community_results = pd.DataFrame()
    all_frame = []
    community_results_baseline =\
        cleap_results['0'].join(euss_results['0'].set_index('building_id'), on = 'building_id')
    all_frame.append(community_results_baseline)

    for up in (cleap_euss_mapping):
        if up == '0':
            pass
        elif up in ['1', '2', '3', '4', '5', '8', '13', '14', '15', '16']:
            cleap_results_TOU =\
                saving_calculation(cleap_results[f'{up}'], euss_results[f'{up}'], euss_results['0'], building_ids_list[f'{up}'], 'all')
            all_frame.append(cleap_results_TOU)
        elif up in ['6', '7']:
            cleap_results_TOU =\
                saving_calculation(cleap_results[f'{up}'], euss_results[f'{up}'], euss_results['0'], building_ids_list[f'{up}'], 'no_dryer_cooking')
            all_frame.append(cleap_results_TOU)
        elif up in ['9', '10']:
            cleap_results_TOU =\
                saving_calculation(cleap_results[f'{up}'], euss_results[f'{up}'], euss_results['0'], building_ids_list[f'{up}'], 'dryer')
            all_frame.append(cleap_results_TOU)
        elif up in ['11', '12']:
            cleap_results_TOU =\
                saving_calculation(cleap_results[f'{up}'], euss_results[f'{up}'], euss_results['0'], building_ids_list[f'{up}'], 'cooking')
            all_frame.append(cleap_results_TOU)

    community_results = pd.concat(all_frame)

    community_results['baseline_cbill.electricity_usd'] =\
        community_results['baseline_cbill.electricity__TOU__usd']
    community_results['saving_cbill.electricity_usd'] =\
        community_results['saving_cbill.electricity_TOU_usd']
    community_results['pct_saving_cbill.electricity_%'] =\
        community_results['pct_saving_cbill.electricity_TOU_%']
    
    community_results = community_results.drop(['cbill.electricity__TOU__usd',
                                                'cbill.electricity__clothes_dryer__TOU__usd',
                                                'cbill.electricity__range_oven__TOU__usd',
                                                'baseline_cbill.electricity__clothes_dryer__TOU__usd',
                                                'baseline_cbill.electricity__range_oven__TOU__usd',
                                                'baseline_cbill.electricity__TOU__usd',
                                                'saving_cbill.electricity_TOU_usd',
                                                'pct_saving_cbill.electricity_TOU_%'], axis=1)
    
    community_results['baseline_cbill.total_usd'] =\
        community_results['baseline_cbill.electricity_usd'] +\
        community_results['baseline_cbill.natural_gas_usd'] + \
        community_results['baseline_cbill.fuel_oil_usd'] +\
        community_results['baseline_cbill.propane_usd']
    
    community_results['saving_cbill.total_usd'] =\
        community_results['saving_cbill.electricity_usd'] +\
        community_results['saving_cbill.natural_gas_usd'] +\
        community_results['saving_cbill.fuel_oil_usd'] +\
        community_results['saving_cbill.propane_usd']
    
    community_results['pct_saving_cbill.total_%'] =\
        community_results['saving_cbill.total_usd']/community_results['baseline_cbill.total_usd'] * 100
    community_results['baseline_energy_burden_2023_cbills.%'] =\
        community_results['baseline_cbill.total_usd']/community_results['rep_income'] * 100
    community_results['post-upgrade_energy_burden_2023_cbills.%'] =\
        (community_results['baseline_cbill.total_usd']-community_results['saving_cbill.total_usd'])/community_results['rep_income'] * 100

    community_results.to_csv(f"data_/community_building_samples_with_upgrade_cost_and_bill/{community}/processed_upgrade_results_TOU.csv")
    community_results.to_parquet(f"data_/community_building_samples_with_upgrade_cost_and_bill/{community}/processed_upgrade_results_TOU.parquet")

main('san_jose', 10) # community name and monthly fixed fee