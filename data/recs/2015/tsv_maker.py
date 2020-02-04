#!/usr/bin/env python3

import os, sys
import pandas as pd
import itertools
import boto3
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

count_col_label = 'source_count'
weight_col_label = 'source_weight'

class RECS2015(TSVMaker):
    
    def __init__(self,resstock_projects_dir):
        # Initialize members
        self.resstock_projects_dir = resstock_projects_dir

        # Create an s3 client
        self.s3_client = boto3.client('s3')

        # Download Data from s3
        self.download_data_s3()

        # Read file into memory
        filepath = os.path.join(self.resstock_projects_dir,'data','recs','2015','various_datasets','recs_2015','recs2015_public_v4.csv')
        self.df = pd.read_csv(filepath, index_col=['DOEID'])
        self.df[count_col_label] = 1

        # Split out Hawaii
        hawaii_rows = self.df[(self.df['DIVISION'] == 10) & (self.df['IECC_CLIMATE_PUB'] == '1A-2A')].index

        # Split out Alaska
        alaska_rows = self.df[(self.df['DIVISION'] == 10) & (self.df['IECC_CLIMATE_PUB'] == '7A-7B-7AK-8AK')].index

        # Drop Alaska and Hawaii
        self.df.drop(hawaii_rows, inplace=True)
        self.df.drop(alaska_rows, inplace=True)

    def s3_download_dir(self,prefix, local, bucket, client):
        """Download a directory from s3
        Args:
            prefix (string): pattern to match in s3
            local (string): local path to folder in which to place files
            bucket (string): s3 bucket with target contents
            client (boto3.client): initialized s3 client object
        """
        keys = []
        dirs = []
        next_token = ''
        base_kwargs = {
            'Bucket':bucket,
            'Prefix':prefix
        }
        while next_token is not None:
            kwargs = base_kwargs.copy()
            if next_token != '':
                kwargs.update({'ContinuationToken': next_token})
            results = client.list_objects_v2(**kwargs)
            contents = results.get('Contents')
            for i in contents:
                k = i.get('Key')
                if k[-1] != '/':
                    keys.append(k)
                else:
                    dirs.append(k)
            next_token = results.get('NextContinuationToken')
        for d in dirs:
            dest_pathname = os.path.join(local, d)
            if not os.path.exists(os.path.dirname(dest_pathname)):
                os.makedirs(os.path.dirname(dest_pathname))
        for k in keys:
            dest_pathname = os.path.join(local, k)
            if not os.path.exists(os.path.dirname(dest_pathname)):
                os.makedirs(os.path.dirname(dest_pathname))
            client.download_file(bucket, k, dest_pathname)

    def download_data_s3(self):
        """Go to s3 and download data needed for this tsv_maker."""
        recs_2015_data_path = os.path.join('various_datasets','recs_2015')
        if not os.path.exists(recs_2015_data_path):
            print('Downloading data from s3')
            # Download climate zone and county data
            print('  RECS 2015...')
            s3_bucket = 'resbldg-datasets'
            s3_prefix = os.path.join('various_datasets','recs_2015')
            self.s3_download_dir(s3_prefix,'.', s3_bucket,self.s3_client)
  
    def groupby_and_pivot(self, df, dependency_cols, option_col):
        """
        Subset the dataframe to columns of interest. Pivot the table, row sum the source weights, and divide each element by its row sum.

        Parameters:
          df (dataframe): The path of the tsv file to copy to projects' housing_characteristics folders.
          dependency_cols (list): A list of the dependency column names.
          option_col (str): The name of the tsv file. This dataframe column contains mapped items from the data source.
          
        Returns:
          df (dataframe): A pandas dataframe with dependency/option columns and fractions.
          count (dataframe): A pandas dataframe with dependency columns and source sample sizes.
          weight (dataframe): A pandas dataframe with dependency columns and source weights.

        """
        df = df[dependency_cols + [option_col] + [count_col_label] + ['NWEIGHT']]
        groups = df.groupby(dependency_cols + [option_col]).sum()
        df = groups.reset_index()
        count = df[dependency_cols + [count_col_label]]
        count = count.groupby(dependency_cols).sum()
        count = count.reset_index()        
        df = df.pivot_table(index=dependency_cols, columns=option_col, values='NWEIGHT')
        option_cols = df.columns.values
        df[weight_col_label] = df.sum(axis=1)
        weight = df[[weight_col_label]]
        weight = weight.reset_index()
        df = df[list(option_cols)].div(df[weight_col_label], axis=0)
        df = df[option_cols]
        df = df.fillna(0)
        return df, count, weight

    def add_missing_dependency_rows(self, df, project, count, weight):
        """
        Add combinations of dependencies for which we have no sample data; distribute option probabilities for these rows uniformly.

        Parameters:
          df (dataframe): A pandas dataframe with dependency/option columns and fractions.
          project (str): Name of the project.
          count (dataframe): A pandas dataframe with dependency columns and source sample sizes.
          weight (dataframe): A pandas dataframe with dependency columns and source weights.

        Returns:
          df (dataframe): A pandas dataframe updated with missing dependency rows, source sample sizes, and source weights.

        """
        levels = df.index.levels
        names = df.index.names
        option_cols = df.columns.values
        df = df.reset_index()
        
        if 'testing' in project:
            df = df[0: 0]
        
        for group in itertools.product(*levels):
            if not group in list(df.groupby(names).groups):
                data = dict(zip(names, group))
                data.update(dict(zip(option_cols, [1.0 / len(option_cols)] * len(option_cols))))
                df = df.append(data, ignore_index=True, verify_integrity=True)
        df = df.merge(count, on=names, how='outer')
        df = df.merge(weight, on=names, how='outer')
        df = df.fillna(0)
        return df

    def rename_cols(self, df, dependency_cols, project):
        """
        Prepend 'Dependency=' to dependency columns and 'Option=' to option columns. Sort by levels in order of dependencies from left to right.

        Parameters:
          df (dataframe): A pandas dataframe with dependency/option columns and fractions.
          dependency_cols (list): A list of the dependency column names.
          project (str): Name of the project.

        Returns:
          df (dataframe): A pandas dataframe with updated dependency/column names.

        """
        new_dependency_cols = []
        for dependency_col in dependency_cols:
            new_dependency_col = 'Dependency={}'.format(dependency_col)
            df = df.rename(columns={dependency_col: new_dependency_col})
            new_dependency_cols.append(new_dependency_col)
            
        if 'singlefamilydetached' in project:
            df = df[df['Dependency=Geometry Building Type RECS']=='Single-Family Detached']
            
        df = df.set_index(new_dependency_cols)
        for col in list(df.columns.values):
            if col in [count_col_label, weight_col_label]:
                continue
            df = df.rename(columns={col: 'Option={}'.format(col)})
        df = df.sort_values(by=new_dependency_cols)
        return df

    def export_and_tag(self, df, filepath, project):
        """
        Add bottom-left script and source tag to dataframe (for non testing projects). Save dataframe to tsv file.
        Parameters:
          df (dataframe): A pandas dataframe with dependency/option columns and fractions.
          filepath (str): The path of the tsv file to export.
          project (str): Name of the project.
        """
        # Write the data file
        df.to_csv(filepath,sep='\t', line_terminator='\r\n', float_format='%.6f')

        # Append the created by line
        if 'testing' not in project:
            tag = "# Created by:" + created_by
            tag += source
            tag += "\r\n"
            with open(filepath, "a") as file_object:
                file_object.write(tag)
        print('{}...'.format(filepath))

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

            filepath = os.path.join(self.resstock_projects_dir, project, 'housing_characteristics', '{}.tsv'.format(option_col))
            self.export_and_tag(bedrooms, filepath, project)

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
            
            filepath = os.path.join(self.resstock_projects_dir, project, 'housing_characteristics', '{}.tsv'.format(option_col))        
            self.export_and_tag(occupants, filepath, project)
        
        return occupants

if __name__ == '__main__':    

    tsv_maker = RECS2015(sys.argv[1])

    tsv_maker.bedrooms()
    tsv_maker.occupants()