import os
import csv
import pandas as pd

folder = 'comparisons' # comparison csv files will be exported to this folder

dir = os.path.join('test/test_samples_osw', folder)
if not os.path.exists(dir):
  os.makedirs(dir)

def value_counts(df, file):
  value_counts = []
  with open(file, 'w', newline='') as f:

    for col in sorted(df.columns):
      if col == 'Building':
        continue

      value_count = df[col].value_counts(normalize=True)
      value_count = value_count.round(2)
      keys_to_values = dict(zip(value_count.index.values, value_count.values))
      keys_to_values = dict(sorted(keys_to_values.items(), key=lambda x: (x[1], x[0]), reverse=True))
      value_counts.append([value_count.name])
      value_counts.append(keys_to_values.keys())
      value_counts.append(keys_to_values.values())
      value_counts.append('\n')

    w = csv.writer(f)
    w.writerows(value_counts)

df = pd.read_csv('resources/base_buildstock.csv')
file = os.path.join(dir, 'base_samples.csv')
value_counts(df, file)

df = pd.read_csv('resources/buildstock.csv')
file = os.path.join(dir, 'feature_samples.csv')
value_counts(df, file)
