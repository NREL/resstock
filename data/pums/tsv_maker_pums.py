#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Thu Jan  9 16:11:32 2020

@author: oadekany
"""

# just rerun file and check
import os
import json
import boto3
import shutil
import requests
import itertools
import numpy as np
import pandas as pd


class TSVMaker(object):
    def __init__(self,project):
        print('Initializing PUMA TSVMaker')
        print('---------------------')
        # Define file paths

        # PUMA data csv file path
        self.puma_file = os.path.join('various_datasets','puma_files','usa_00007.csv')

        # data dictionary file path
        self.dep_mapping = os.path.join('various_datasets','puma_files','ColumnsCoding.xlsx')

        # Define the projects to copy the tsvs
        self.project = project

        # Set members
        self.dep_list = []
        self.option_col = []

        #Create an s3 client
        self.s3_client = boto3.client('s3')

        #Download Data from s3
        self.download_data_s3()

        # Load PUMS data intp memory
        self.load_pums_data()

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
        print('Downloading data from s3')

        # Download puma csv and data dictionary files
        print('PUMA Files...')

        puma_data_path = os.path.join('various_datasets','puma_files')
        if not os.path.exists(puma_data_path):
            s3_bucket = 'resbldg-datasets'
            s3_prefix = os.path.join('various_datasets','puma_files')
            self.s3_download_dir(s3_prefix,'.', s3_bucket,self.s3_client)

    def load_pums_data(self):
        print ("Loading PUMA data csv file - this may take a while")
        # read in puma file
        chunks = pd.read_csv(self.puma_file, chunksize = 100000)
        self.puma_df = pd.concat(chunks)

        # select rows where puma_df equals 0
        df_equals_zero = self.puma_df[(self.puma_df['OWNERSHP'] == 0) & (self.puma_df['OWNERSHPD'] == 0) & \
                          (self.puma_df['VACANCY'] == 0) & (self.puma_df['ROOMS'] == 0) & \
                          (self.puma_df['BEDROOMS'] == 0) & (self.puma_df['BUILTYR2'] == 0) & \
                          (self.puma_df['FUELHEAT'] == 0) ]

        # drop all observations where puma_df equals 0
        self.puma_df = self.puma_df[~self.puma_df.isin(df_equals_zero)].dropna()

        # create new column in puma file with State Abbreviation
        print("Create longPUMA column...")
        sheet_state_abbrev = pd.read_excel(self.dep_mapping, sheet_name = "STATEFIP")

        # remove Hawaii, Puerto Rico and Alaska states
        sheet_state_abbrev =  sheet_state_abbrev[~sheet_state_abbrev['State (FIPS code)'].str.contains('Hawaii|Puerto Rico|Alaska')]

        self.puma_df = pd.merge(self.puma_df, sheet_state_abbrev[['STATEFIP', "StateAbbrev"]], on = "STATEFIP")

        self.puma_df['PUMA'] = self.puma_df['PUMA'].astype(int)

        # add leading zeros to those digits less than 5
        self.puma_df['PUMA'] = self.puma_df['PUMA'].apply(lambda x: '{0:0>5}'.format(x))

        # convert type to string
        self.puma_df['PUMA'] = self.puma_df['PUMA'].astype(str)

        # reformat PUMA mame to include
        self.puma_df['longPUMA'] = self.puma_df["StateAbbrev"] + ", " + self.puma_df["PUMA"]

        # Copy integers from Built year to built year acs (will be different after mapping)
        self.puma_df['BUILTYR2_ACS'] = self.puma_df['BUILTYR2'].copy()        
        self.puma_df['GBT_RECS'] = self.puma_df['UNITSSTR'].copy()  

        # Add a count column
        self.puma_df['COUNT'] = 1

        print("Loading PUMS data complete.")

    def create_mapping_files(self):

        # Copy PUMS data
        self.df = self.puma_df.copy()

        # create list of columns that will be mapped to their correct names
        if self.dep_list == ["longPUMA"] :
            sheets_mapped = self.option_col
        else:
            sheets_mapped = self.dep_list + self.option_col
            try:
                sheets_mapped.remove("longPUMA")
            except ValueError:
                pass

        dep_mapping = os.path.join('various_datasets','puma_files','ColumnsCoding.xlsx')
        for col in sheets_mapped:
            dep_sheet = pd.read_excel(self.dep_mapping, sheet_name = col)
            self.df[col] = self.df[col].map(dep_sheet.set_index(col)[dep_sheet.columns.values[2]])

    def create_tsv_with_dependencies(self,dep_list,option_col):
        # Set members
        self.dep_list = dep_list
        self.option_col = [option_col]

        # Create Mapping
        print('Creating mapping...')
        self.create_mapping_files()

        print("Pivoting table...")
        self.pivot_df = pd.pivot_table(self.df, values = "HHWT", columns = self.option_col, index = self.dep_list, aggfunc = np.sum, dropna = False, fill_value = 0)

        # Get Counts and Weights
        counts = pd.pivot_table(self.df, values = "COUNT", columns = self.option_col, index = self.dep_list, aggfunc = np.sum, dropna = False, fill_value = 0)
        counts = np.array(counts.sum(axis=1))
        weights = np.array(self.pivot_df.sum(axis=1))

        # Reweight columns to 1
        print("Formating table into tsv...")
        self.pivot_df = self.pivot_df.div(self.pivot_df.sum(axis=1),axis=0)

        # Fill Nans with 0 (Correct in notebook)
        self.pivot_df = self.pivot_df.fillna(0.0)

        # Add Option= to each column
        self.pivot_df = self.add_option_string_to_columns(self.pivot_df).reset_index()

        # Add Dependency to columns
        self.pivot_df = self.rename_dependencies(self.pivot_df)

        # Add Weight Column
        self.pivot_df['source_count'] = counts
        self.pivot_df['source_count'] = self.pivot_df['source_count'].astype(float)
        self.pivot_df['source_weight'] = weights
        self.pivot_df['source_weight'] = self.pivot_df['source_weight'].astype(float)

        # Reset members
        self.dep_list = []
        self.option_col = []

    def rename_dependencies(self, df):
        """Add 'Depedency=' to all dependency columns
        Args:
            df (pandas.DataFrame): The data frame you want to add the 'Dependency=' string to the columns
        Returns:
            df (pandas.DataFrame): The same dataframe input but all dependencies column now has the "Dependency=" prefix
        """
        """Here, we also get the updated tsv file name """

        # columns from PUMA data csv
        original_columns = ['OWNERSHP', 'BUILTYR2', 'BUILTYR2_ACS', 'UNITSSTR', 'BEDROOMS', 'FUELHEAT', 'GBT_RECS']

        # renaming those column names
        new_columns = ['Occupancy Status', 'Vintage', 'Vintage ACS','Geometry Building Type ACS', 'Bedrooms', 'Heating Fuel', 'Geometry Building Type RECS']

        # get the new filename
        self.tsv_name = new_columns[original_columns.index(self.option_col[0])]


        # add dependency to new columns
        new_columns = [("Dependency=" + item )for item in new_columns]
        df = df.rename(columns = dict(zip(original_columns,new_columns)))

        # add dependency long PUMA
        df = df.rename(columns={"longPUMA": "Dependency=PUMA"})

        return df

    def add_option_string_to_columns(self,df):
        """Add 'Option=' to all option columns in a dataframe.
        Args:
            df (pandas.DataFrame): The data frame you want to add the 'Options=' string to the columns
        Returns:
            df (pandas.DataFrame): The data same input dataframe except all columns have a 'Options=' prefix.
        """
        [df.rename(columns={col:'Option=' + col},inplace=True) for col in df.columns.values]
        #matching = [s for s in df.columns.values if "Option=" in s]
        #for col in matching:
        #    df[col] = df[col].astype(float)
        return df


    def write_tsv_to_projects(self):
        """Write new tsv to projects member"""
        try:
            write_path = os.path.join(self.project, '{}.tsv'.format(self.tsv_name))
            self.pivot_df.to_csv(write_path,sep='\t',index=False, line_terminator='\r\n', float_format='%.6f')
        except AttributeError:
            self.create_tsv_with_dependencies()
            write_path = os.path.join('..',self.project, '{}.tsv'.format(self.tsv_name))
            self.pivot_df.to_csv(write_path,sep='\t',index=False, line_terminator='\r\n', float_format='%.6f')
        print ('All done! file(s) written into tsv paths!')












