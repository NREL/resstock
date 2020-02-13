#!/usr/bin/env python3

import os, sys
import pandas as pd
import boto3
import parameter_option_maps

openstudio_buildstock_path = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)),"..", "..", ".."))
sys.path.append(openstudio_buildstock_path)
from data.tsv_maker import TSVMaker

this_file = os.path.basename(__file__)
dir_of_this_file = os.path.basename(os.path.dirname(__file__))
parent_dir_of_this_file = os.path.basename(os.path.dirname(os.path.dirname(__file__)))

created_by = os.path.join(parent_dir_of_this_file, dir_of_this_file, this_file)
source = ' using U.S. EIA 2009 Residential Energy Consumption Survey (RECS) microdata'

projects = ['project_singlefamilydetached', 'project_multifamily_beta', 'project_testing']
for project in projects:
    project_dir = os.path.join(os.path.dirname(__file__), project)
    if not os.path.exists(project_dir):
        os.mkdir(project_dir)

class RECS2009(TSVMaker):

    def __init__(self):
        # Initialize members
        self.data_path = os.path.join(openstudio_buildstock_path,'data','recs','2009','data')
        self.data_file = os.path.join(self.data_path, 'recs2009_public.csv') 

        # Download data if the data file does not exist
        if not os.path.exists(self.data_file):
            self.download_recs_2009_data_s3()
        
        # Load RECS 2009 microdata
        self.df = pd.read_csv(self.data_file, index_col=['DOEID'],low_memory=False)
        self.df[self.count_col_label()] = 1
        
        # Split out Hawaii
        hawaii_rows = self.df[(self.df['REPORTABLE_DOMAIN'] == 27) & ((self.df['AIA_Zone'] == 5) | (self.df['HDD65'] < 4000))].index

        # Split out Alaska
        alaska_rows = self.df[(self.df['REPORTABLE_DOMAIN'] == 27) & ((self.df['HDD65'] > 6930))].index # Source for 6930 HDD: Dennis Barley

        # Drop Alaska and Hawaii
        self.df.drop(hawaii_rows, inplace=True)
        self.df.drop(alaska_rows, inplace=True)

    def download_recs_2009_data_s3(self):
        """Go to s3 and download data needed for this tsv_maker."""
        print("Downloading RECS 2009 Data from s3...")        
        # Initialize members
        self.s3_client = boto3.client('s3')

        s3_bucket = 'resbldg-datasets'
        s3_prefix = os.path.join('various_datasets','recs_2009')
        self.s3_download_dir(s3_prefix,'.', s3_bucket,self.s3_client,self.data_path)

    def geometry_wall_type(self): # for WoodStud or Masonry walls
        df = self.df.copy()

        df = parameter_option_maps.map_geometry_building_type(df) # dependency
        df = parameter_option_maps.map_location_region(df) # dependency        
        df = parameter_option_maps.map_geometry_wall_type(df) # option

        for project in projects:
            dependency_cols = ['Geometry Building Type RECS', 'Location Region']
            option_col = 'Geometry Wall Type'

            if project == 'project_testing':
                dependency_cols.remove('Location Region')

            geometry_wall_type = df.copy()

            geometry_wall_type, count, weight = self.groupby_and_pivot(geometry_wall_type, dependency_cols, option_col)
            geometry_wall_type = self.add_missing_dependency_rows(geometry_wall_type, project, count, weight)
            geometry_wall_type = self.rename_cols(geometry_wall_type, dependency_cols, project)
            geometry_wall_type.reset_index(inplace=True,drop=False)

            filepath = os.path.normpath(os.path.join(os.path.dirname(__file__), project, '{}.tsv'.format(option_col)))
            self.export_and_tag(geometry_wall_type, filepath, project, created_by, source)
            self.copy_file_to_project(filepath, project)

        return geometry_wall_type

    def misc_pool(self):
        df = self.df.copy()

        df = parameter_option_maps.map_geometry_building_type(df)
        df = parameter_option_maps.map_location_region(df)
        df = parameter_option_maps.map_misc_pool(df)

        for project in projects:
            dependency_cols = ['Geometry Building Type RECS', 'Location Region']
            option_col = 'Misc Pool'

            if project == 'project_testing':
                dependency_cols.remove('Location Region')
            
            misc_pool = df.copy()

            misc_pool, count, weight = self.groupby_and_pivot(misc_pool, dependency_cols, option_col)
            misc_pool = self.add_missing_dependency_rows(misc_pool, project, count, weight)
            misc_pool = self.rename_cols(misc_pool, dependency_cols, project)
            misc_pool.reset_index(inplace=True,drop=False)

            filepath = os.path.normpath(os.path.join(os.path.dirname(__file__), project, '{}.tsv'.format(option_col)))
            self.export_and_tag(misc_pool, filepath, project, created_by, source)
            self.copy_file_to_project(filepath, project)

    def misc_pool_heater(self):
        df = self.df.copy()

        df = parameter_option_maps.map_misc_pool(df)
        df = parameter_option_maps.map_location_region(df)
        df = parameter_option_maps.map_misc_pool_heater(df)

        for project in projects:
            dependency_cols = ['Misc Pool', 'Location Region']
            option_col = 'Misc Pool Heater'

            if project == 'project_testing':
                dependency_cols.remove('Location Region')

            misc_pool = df.copy()

            misc_pool, count, weight = self.groupby_and_pivot(misc_pool, dependency_cols, option_col)
            misc_pool = self.add_missing_dependency_rows(misc_pool, project, count, weight)
            misc_pool = self.rename_cols(misc_pool, dependency_cols, project)
            misc_pool.reset_index(inplace=True,drop=False)

            filepath = os.path.normpath(os.path.join(os.path.dirname(__file__), project, '{}.tsv'.format(option_col)))
            self.export_and_tag(misc_pool, filepath, project, created_by, source)
            self.copy_file_to_project(filepath, project)

    def misc_hot_tub_spa(self):
        df = self.df.copy()

        df = parameter_option_maps.map_geometry_building_type(df)
        df = parameter_option_maps.map_location_region(df)
        df = parameter_option_maps.map_misc_hot_tub_spa(df)

        for project in projects:
            dependency_cols = ['Geometry Building Type RECS', 'Location Region']
            option_col = 'Misc Hot Tub Spa'

            if project == 'project_testing':
                dependency_cols.remove('Location Region')

            misc_pool = df.copy()

            misc_pool, count, weight = self.groupby_and_pivot(misc_pool, dependency_cols, option_col)
            misc_pool = self.add_missing_dependency_rows(misc_pool, project, count, weight)
            misc_pool = self.rename_cols(misc_pool, dependency_cols, project)
            misc_pool.reset_index(inplace=True,drop=False)

            filepath = os.path.normpath(os.path.join(os.path.dirname(__file__), project, '{}.tsv'.format(option_col)))
            self.export_and_tag(misc_pool, filepath, project, created_by, source)
            self.copy_file_to_project(filepath, project)

if __name__ == '__main__':
    # Initialize object
    tsv_maker = RECS2009()

    # Create housing characteristics
    tsv_maker.geometry_wall_type()
    tsv_maker.misc_pool()
    tsv_maker.misc_pool_heater()
    tsv_maker.misc_hot_tub_spa()