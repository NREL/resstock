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
source = ' using U.S. EIA 2015 Residential Energy Consumption Survey (RECS) microdata'

projects = ['project_singlefamilydetached', 'project_multifamily_beta', 'project_testing']
for project in projects:
    project_dir = os.path.join(os.path.dirname(__file__), project)
    if not os.path.exists(project_dir):
        os.mkdir(project_dir)

class RECS2015(TSVMaker):

    def __init__(self):
        # Initialize members
        self.data_path = os.path.join(openstudio_buildstock_path, 'data', 'recs', '2015', 'data')
        self.data_file = os.path.join(self.data_path, 'recs2015_public_v4.csv') 

        # Download data if the data file does not exist
        if not os.path.exists(self.data_file):
            self.download_recs_2015_data_s3()

        # Load RECS 2009 microdata
        self.df = pd.read_csv(self.data_file, index_col=['DOEID'], low_memory=False)
        self.df[self.count_col_label()] = 1

        # Split out Hawaii
        hawaii_rows = self.df[(self.df['DIVISION'] == 10) & (self.df['IECC_CLIMATE_PUB'] == '1A-2A')].index

        # Split out Alaska
        alaska_rows = self.df[(self.df['DIVISION'] == 10) & (self.df['IECC_CLIMATE_PUB'] == '7A-7B-7AK-8AK')].index

        # Drop Alaska and Hawaii
        self.df.drop(hawaii_rows, inplace=True)
        self.df.drop(alaska_rows, inplace=True)

    def download_recs_2015_data_s3(self):
        """Go to s3 and download data needed for this tsv_maker."""
        print("Downloading RECS 2015 Data from s3...")        
        # Initialize members
        s3_client = boto3.client('s3')

        s3_bucket = 'resbldg-datasets'
        s3_prefix = os.path.join('various_datasets', 'recs_2015')
        self.s3_download_dir(s3_prefix, '.', s3_bucket, s3_client, self.data_path)

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
            bedrooms.reset_index(inplace=True, drop=False)

            filepath = os.path.normpath(os.path.join(os.path.dirname(__file__), project, '{}.tsv'.format(option_col)))
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
            occupants.reset_index(inplace=True, drop=False)

            filepath = os.path.normpath(os.path.join(os.path.dirname(__file__), project, '{}.tsv'.format(option_col)))
            self.export_and_tag(occupants, filepath, project, created_by, source)
            self.copy_file_to_project(filepath, project)

        return occupants

if __name__ == '__main__':    
    # Initialize object
    tsv_maker = RECS2015()

    # Create housing characteristics
    tsv_maker.bedrooms()
    tsv_maker.occupants()