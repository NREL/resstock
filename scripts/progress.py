import os
import pandas as pd

for filepath in os.listdir(os.path.join(os.path.dirname(os.path.abspath(__file__)), '../progress')):
  filepath = os.path.join(os.path.dirname(os.path.abspath(__file__)), '../progress', filepath)
  df = pd.read_csv(filepath, index_col=['building_id'])
  results = {'num_dps': [df.shape[0]], 'total_site_energy_mbtu': [df['simulation_output_report.total_site_energy_mbtu'].sum()]}

  results = pd.DataFrame.from_dict(results)
  results = results.set_index('num_dps')
  results.to_csv(os.path.join(os.path.dirname(os.path.abspath(__file__)), '../progress/progress.csv'))
  break