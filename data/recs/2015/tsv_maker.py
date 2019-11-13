import os
import pandas as pd
import parameter_option_maps
import itertools

this_file = os.path.basename(__file__)
dir_of_this_file = os.path.basename(os.path.dirname(__file__))
parent_dir_of_this_file = os.path.basename(os.path.dirname(os.path.dirname(__file__)))
created_by = os.path.join(parent_dir_of_this_file, dir_of_this_file, this_file)

projects = ['project_singlefamilydetached', 'project_multifamily_beta', 'project_testing']
for project in projects:
    project_dir = os.path.join(os.path.dirname(__file__), project)
    if not os.path.exists(project_dir):
        os.mkdir(project_dir)

class TSVMaker():
    
    def __init__(self, file):
        self.df = pd.read_csv(file, index_col=['DOEID'])

    def bedrooms(self):
        df = self.df.copy()
        
        df = parameter_option_maps.map_geometry_building_type(df)
        df = parameter_option_maps.map_geometry_house_size(df)
        df = parameter_option_maps.map_bedrooms(df)
        
        dependency_cols = ['Geometry Building Type', 'Geometry House Size']
        option_col = 'Bedrooms'
        
        for project in projects:
            bedrooms = df.copy()
            
            bedrooms = self.groupby_and_pivot(bedrooms, dependency_cols, option_col, project)
            bedrooms = self.add_missing_dependency_rows(bedrooms)
            bedrooms = self.rename_cols(bedrooms, dependency_cols)
            
            filepath = os.path.join(os.path.dirname(__file__), project, '{}.tsv'.format(option_col))        
            self.export_and_tag(bedrooms, filepath)

    def occupants(self):
        df = self.df.copy()
        
        df = parameter_option_maps.map_geometry_building_type(df)
        df = parameter_option_maps.map_bedrooms(df)
        df = parameter_option_maps.map_occupants(df)
        
        dependency_cols = ['Geometry Building Type', 'Bedrooms']
        option_col = 'Occupants'
        
        for project in projects:
            occupants = df.copy()
        
            occupants = self.groupby_and_pivot(occupants, dependency_cols, option_col, project)            
            occupants = self.add_missing_dependency_rows(occupants)
            occupants = self.rename_cols(occupants, dependency_cols)
            
            filepath = os.path.join(os.path.dirname(__file__), project, '{}.tsv'.format(option_col))        
            self.export_and_tag(occupants, filepath)
        
        return occupants
  
    def groupby_and_pivot(self, df, dependency_cols, option_col, project):
        df = df[dependency_cols + [option_col] + ['NWEIGHT']]        
        groups = df.groupby(dependency_cols + [option_col]).sum()
        df = groups.reset_index()
        
        if 'singlefamilydetached' in project:
            df = df[df['Geometry Building Type']=='Single-Family Detached']
        elif 'multifamily_beta' in project:
            pass
        elif 'testing' in project:
            pass
        
        df = df.pivot_table(index=dependency_cols, columns=option_col, values='NWEIGHT')
        option_cols = df.columns.values
        df['TOTAL'] = df.sum(axis=1)
        df = df[list(option_cols)].div(df['TOTAL'], axis=0)
        df = df[option_cols]
        df = df.fillna(0)
        return df

    def add_missing_dependency_rows(self, df):
        levels = df.index.levels
        names = df.index.names
        option_cols = df.columns.values
        df = df.reset_index()
        for group in itertools.product(*levels):
            if not group in list(df.groupby(names).groups):
                data = dict(zip(names, group))
                data.update(dict(zip(option_cols, [1.0 / len(option_cols)] * len(option_cols))))
                df = df.append(data, ignore_index=True, verify_integrity=True)
        return df

    def rename_cols(self, df, dependency_cols):
        new_dependency_cols = []
        for dependency_col in dependency_cols:
            new_dependency_col = 'Dependency={}'.format(dependency_col)
            df = df.rename(columns={dependency_col: new_dependency_col})
            new_dependency_cols.append(new_dependency_col)
        df = df.set_index(new_dependency_cols)
        for option_val in list(df.columns.values):
            df = df.rename(columns={option_val: 'Option={}'.format(option_val)})
        df = df.sort_values(by=new_dependency_cols)
        return df
  
    def export_and_tag(self, df, filepath):
        df.to_csv(filepath, sep='\t')
        with open(filepath, 'a') as f:
            f.write('Created by: {}'.format(created_by))
        print '{}...'.format(filepath)

if __name__ == '__main__':
    
    recs_filepath = 'c:/recs2015/recs2015_public_v4.csv'

    tsv_maker = TSVMaker(recs_filepath)
    
    print '\n'
    tsv_maker.bedrooms()
    tsv_maker.occupants()