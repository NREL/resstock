import os
import pandas as pd

usecols = ['Annual Name', 'Annual Units', 'Timeseries Name', 'Timeseries Units', 'Notes']
df = pd.read_csv(os.path.join(os.path.abspath(__file__), '../../../../../resources/data/dictionary/outputs.csv'), usecols=usecols)

tables = {
    # 'characteristics.csv': ['.build_existing_model'],
    'simulation_outputs.csv': ['.end_use', 'fuel_use', '.energy_use'],
    'cost_multipliers.csv': ['.upgrade_costs'],
    'component_loads.csv': ['.component_load'],
    'emissions.csv': ['.emissions'],
    'utility_bills.csv': ['report_utility_bills.'],
    'qoi_report.csv': ['qoi_report.']
}
    
for csv, strings in tables.items():
    sub = df.copy()
    subs = []
    for string in strings:
        sub = sub[sub['Annual Name'].str.contains(string, na=False)]
        subs.append(sub)
    sub = pd.concat(subs)
    sub.set_index('Annual Name').to_csv(os.path.join(os.path.abspath(__file__), '../{}'.format(csv)))
