import os
import os.path

file_path = '/kfs2/projects/panels/ochre/resstock_model/30k_20240918' 
#upgrade_list = list(range(1, 20))
upgrade_list = [1,2,3,4,5,6,7,9,10,11,13,14,16,17,18,19]
for upgrade in upgrade_list:
    folder = f'{file_path}/upgrade{upgrade}/results/simulation_output/up01'
    build_list = [name for name in os.listdir(folder) if os.path.isdir(os.path.join(folder, name))]
    for build in build_list:
        xml = f'{folder}/{build}/run/in.xml'
        schedule = f'{folder}/{build}/run/schedules.csv'
        if os.path.isfile(xml) == False or os.path.isfile(schedule) == False:
            print(f'{upgrade}_{build}')


