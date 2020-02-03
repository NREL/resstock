import os, sys
import pandas as pd
import parameter_option_maps
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")))
from recs.tsv_maker import TSVMaker

this_file = os.path.basename(__file__)
dir_of_this_file = os.path.basename(os.path.dirname(__file__))
parent_dir_of_this_file = os.path.basename(os.path.dirname(os.path.dirname(__file__)))
created_by = os.path.join(parent_dir_of_this_file, dir_of_this_file, this_file)
source = ' using U.S. EIA 2015 Residential Energy Consumption Survey (RECS) microdata'

projects = ['project_singlefamilydetached', 'project_multifamily_beta', 'project_testing']
for project in projects:
    project_dir = os.path.join(os.path.dirname(__file__), project)
    if not os.path.exists(project_dir):
        os.mkdir(project_dir)

count_col_label = 'sample_size'

class RECS2015(TSVMaker):
    
    def __init__(self, file):
        self.df = pd.read_csv(file, index_col=['DOEID'])
        self.df[count_col_label] = 1

        # Split out Hawaii
        hawaii_rows = self.df[(self.df['REPORTABLE_DOMAIN'] == 27) & ((self.df['AIA_Zone'] == 5) | (self.df['HDD65'] < 4000))].index

        # Split out Alaska:
        alaska_rows = self.df[(self.df['REPORTABLE_DOMAIN'] == 27) & ((self.df['HDD65'] > 6930))].index # Source for 6930 HDD: Dennis Barley

        # Drop Alaska and Hawaii
        self.df.drop(hawaii_rows, inplace=True)
        self.df.drop(alaska_rows, inplace=True)


    def bedrooms(self):
        df = self.df.copy()
        
        df = parameter_option_maps.map_geometry_building_type(df)
        df = parameter_option_maps.map_geometry_house_size(df)
        df = parameter_option_maps.map_bedrooms(df)
        
        dependency_cols = ['Geometry Building Type RECS', 'Geometry House Size']
        option_col = 'Bedrooms'
        
        for project in projects:
            bedrooms = df.copy()
            
            bedrooms, count, weight = self.groupby_and_pivot(bedrooms, dependency_cols, option_col)
            bedrooms = self.add_missing_dependency_rows(bedrooms, project, count, weight)
            bedrooms = self.rename_cols(bedrooms, dependency_cols, project)
            
            filepath = os.path.join(os.path.dirname(__file__), project, '{}.tsv'.format(option_col))
            self.export_and_tag(bedrooms, filepath, project, created_by, source)
            self.copy_file_to_project(filepath, project)

    def occupants(self):
        df = self.df.copy()
        
        df = parameter_option_maps.map_geometry_building_type(df)
        df = parameter_option_maps.map_bedrooms(df)
        df = parameter_option_maps.map_occupants(df)
        
        dependency_cols = ['Geometry Building Type RECS', 'Bedrooms']
        option_col = 'Occupants'

        for project in projects:
            occupants = df.copy()
        
            occupants, count, weight = self.groupby_and_pivot(occupants, dependency_cols, option_col)
            occupants = self.add_missing_dependency_rows(occupants, project, count, weight)
            occupants = self.rename_cols(occupants, dependency_cols, project)
            
            filepath = os.path.join(os.path.dirname(__file__), project, '{}.tsv'.format(option_col))        
            self.export_and_tag(occupants, filepath, project, created_by, source)
            self.copy_file_to_project(filepath, project)
        
        return occupants

if __name__ == '__main__':    
    recs_filepath = 'c:/recs2015/recs2015_public_v4.csv' # raw recs microdata

    tsv_maker = RECS2015(recs_filepath)

    tsv_maker.bedrooms()
    tsv_maker.occupants()