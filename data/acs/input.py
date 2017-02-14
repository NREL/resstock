
import os, sys
import util

class Create_DFs():

    def __init__(self, file):
        self.session = file

    def vintage(self):
        df = util.assign_vintage(self.session)
        df = add_option_prefix(df)
        df = df[['Option=<1950', 'Option=1950s', 'Option=1960s', 'Option=1970s', 'Option=1980s', 'Option=1990s', 'Option=2000s', 'Count', 'Weight']]
        return df
               
    def income(self):
        df = util.assign_income(self.session)
        df = add_option_prefix(df)
        df = df[['Option=<$10,000', 'Option=$10,000-14,999', 'Option=$15,000-19,999', 'Option=$20,000-24,999', 'Option=$25,000-29,999', 'Option=$30,000-34,999', 'Option=$35,000-39,999', 'Option=$40,000-44,999', 'Option=$45,000-49,999', 'Option=$50,000-59,999', 'Option=$60,000-74,999', 'Option=$75,000-99,999', 'Option=$100,000-124,999', 'Option=$125,000-149,999', 'Option=$150,000-199,999', 'Option=$200,000+', 'Count', 'Weight']]
        return df
        
    def census_tract(self):
        df = util.assign_census_tract(self.session)
        return df
        
def add_option_prefix(df):
    for col in df.columns:
        if not 'Dependency=' in col and not 'Count' in col and not 'Weight' in col and not 'group' in col:
            if col in ['GSHP', 'Dual-Fuel ASHP, SEER 14, 8.2 HSPF', 'Gas Stove, 75% AFUE', 'Oil Stove', 'Propane Stove', 'Wood Stove', 'Evaporative Cooler']:
                df.rename(columns={col: 'Option=FIXME {}'.format(col)}, inplace=True)
            else:
                df.rename(columns={col: 'Option={}'.format(col)}, inplace=True)
    return df
        
if __name__ == '__main__':

    dfs = Create_DFs('acs.csv')

    for category in ['Vintage', 'Income', 'Census Tract']:
        print category
        method = getattr(dfs, category.lower().replace(' ', '_'))
        df = method()

        if category in ['Census Tract']:
          df.to_csv('{}.tsv'.format(category), sep='\t', index=False)
        else:
          df.to_csv('{}.tsv'.format(category), sep='\t')