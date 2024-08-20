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

## main code
file_path = 'full_run'
up_list = ['00','01','02','03','04','05','06','07','08','09','10','11','12','13','14','15','16','17','18','19']

failed_building_id(file_path, up_list)
# data cleaning
data_cleaning(file_path, up_list)
