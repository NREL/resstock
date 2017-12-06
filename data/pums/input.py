import os
import sys
import numpy as np
import pandas as pd

class Create_DFs():
    
  def __init__(self, file):
    self.session = pd.read_csv(file, index_col=['serial'], usecols=['serial', 'unitsstr', 'hhwt', 'state_abbr'])
    self.session = self.session[~self.session['unitsstr'].isin([0, 1, 2])] # not NA, mobile home, boat, tent, van, etc.
      
  def pums_sf_vs_mf(self):
    df = self.session
    
    print df
    
if __name__ == '__main__':
    
  datafiles_dir = '.'

  dfs = Create_DFs('MLR/pums.csv')
  
  for category in ['PUMS_SF_vs_MF']:
    print category
    method = getattr(dfs, category.lower().replace(' ', '_'))
    df = method()
    df.to_csv(os.path.join(datafiles_dir, '{}.tsv'.format(category)), sep='\t')
        