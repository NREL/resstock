import os
import os.path

file_path = '/kfs2/projects/panels/ochre/resstock_model/30k' 
upgrade_list = list(range(1, 20))
for upgrade in upgrade_list:
    folder = f'/kfs2/projects/panels/ochre/resstock_model/30k/upgrade{upgrade}/results/simulation_output/up01'
    build_list = [name for name in os.listdir(folder) if os.path.isdir(os.path.join(folder, name))]
    for build in build_list:
        xml = f'{folder}/{build}/run/in.xml'
        schedule = f'{folder}/{build}/run/schedules.csv'
        if os.path.isfile(xml) == False or os.path.isfile(schedule) == False:
            print(f'{upgrade}_{build}')


