import os
import pandas as pd

outdir = 'baseline/results'
if not os.path.exists(outdir):
  os.makedirs(outdir)

df_national = pd.read_csv('project_national/national_baseline.csv')
df_testing = pd.read_csv('project_testing/testing_baseline.csv')

frames = [df_national, df_testing]
df = pd.concat(frames)

print(df)
print(df.shape)

# results_characteristics.csv
# TODO

# results_output.csv
# TODO

results_characteristics.to_csv('baseline/results/results_characteristics.csv')
results_output.to_csv('baseline/results/results_output.csv')