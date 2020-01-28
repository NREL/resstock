import os
import json
import boto3
import shutil
import requests
import itertools
import numpy as np
import pandas as pd
from IPython.display import display
from math import sin, cos, sqrt, atan2, radians

this_file = os.path.basename(__file__)
dir_of_this_file = os.path.basename(os.path.dirname(__file__))
parent_dir_of_this_file = os.path.basename(os.path.dirname(os.path.dirname(__file__)))
created_by = os.path.join(parent_dir_of_this_file, dir_of_this_file, this_file)

class TSVMaker():
    
    def __init__(self,projects,buildstockdb_path):
        print('Initializing TSVMaker')
        print('---------------------')
        # Define file paths
        self.fips_file = os.path.join('various_datasets','spatial_data','county_fips_master.csv')
        self.cz_file = os.path.join('various_datasets','spatial_data','climate_zones.csv')
        self.buildstockdb_path = buildstockdb_path

        # Define the projects to copy the tsvs
        self.projects = projects

        # Create an s3 client
        self.s3_client = boto3.client('s3')

        # Download Data from s3
        self.download_data_s3()

        # Create the spatial lookup table
        self.create_spatial_lookup_table()

        # Create county spatial lookup table
        self.create_county_spatial_lookup_table()

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
        # Download climate zone and county data
        print('  Spatial Data...')
        spatial_data_path = os.path.join('various_datasets','spatial_data')
        if not os.path.exists(spatial_data_path):
            s3_bucket = 'resbldg-datasets'
            s3_prefix = os.path.join('various_datasets','spatial_data')
            self.s3_download_dir(s3_prefix,'.', s3_bucket,self.s3_client)
                
        # Download PUMS data if not exists
        print('  ACS Data...')
        acs_data_path = os.path.join('various_datasets','acs')
        if not os.path.exists(acs_data_path):
            s3_bucket = 'resbldg-datasets'
            s3_prefix = os.path.join('various_datasets','acs')
            self.s3_download_dir(s3_prefix,'.', s3_bucket,self.s3_client)

        # Download CHIA data if not exist
        print('  CHIA Data...')
        chia_path = os.path.join('..','chia','original')
        if not os.path.exists(chia_path):
            s3_bucket = 'resbldg-datasets'
            s3_prefix = os.path.join('chia','original')
            self.s3_download_dir(s3_prefix,'..', s3_bucket, self.s3_client)

    def create_county_to_location_lookup(self):
        """Create the weather station location to county lookup table. Previously the counties were fractionally
        assigned to multiple weather stations. The assignment was based on NSRDB grid cells spatial distance and
        elevation. In this update the fractions are replaced so that a county is fully allocated to a weather 
        station. The assignment of a county to a weather station is based on 1) ASHRAE 169 climate zone number
        and 2) geospatial distance.
        """
        # Load data from CHIA data and buildstockdb fips.py
        ami_mf_df = pd.read_csv(os.path.join(self.buildstockdb_path,'data','chia','AMI_MF.tsv.gz'),sep='\t')

        # Reduce dataframe to total unit counts
        ami_mf_df = ami_mf_df[['county_fips_code','location','weight']].groupby(['county_fips_code','location']).sum().reset_index()

        # Extract usafn
        ami_mf_df['usafn'] = [int(loc.split('.')[-1]) for loc in ami_mf_df['location']]

        # Add in Oglala Lakota County (Oglala Lakota County changed from Shannon County in 2015)
        ami_mf_df.loc[len(ami_mf_df),ami_mf_df.columns.values] = [46102,'SD_Rapid.City.Rgnl.AP.726620',1,726620]

        # Merge in resstock station data
        rs_epws_df = pd.read_csv(os.path.join('various_datasets','spatial_data','resstock_epws.csv'))
        location_county_df = pd.merge(rs_epws_df[['location','latitude','longitude','elevation','station_fips']],ami_mf_df,on='location')

        # Merge in County Population Centroids
        county_pop_df = pd.read_csv(os.path.join('various_datasets','spatial_data','CenPop2010_Mean_CO.csv'),encoding='latin-1')
        county_pop_df['county_fips_code'] = (county_pop_df['STATEFP'].astype(str) + county_pop_df['COUNTYFP'].astype(int).astype(str).apply(lambda x: x.zfill(3))).astype(float)
        location_county_df = pd.merge(location_county_df,county_pop_df[['LATITUDE','LONGITUDE','county_fips_code']],on='county_fips_code')

        # Merge in county climate zone number
        location_county_df = pd.merge(location_county_df,self.county_lookup_df[['fips','cz_number']],left_on='county_fips_code',right_on='fips')
        location_county_df = pd.merge(location_county_df,self.county_lookup_df[['fips','cz_number']],left_on='station_fips',right_on='fips')

        # Calculate Weather Station Distations (km) from County population Centroid
        location_county_df['station_dist_km'] = [self.lat_lon_distance(radians(location_county_df['latitude'].loc[i]),
                                                                       radians(location_county_df['longitude'].loc[i]),
                                                                       radians(location_county_df['LATITUDE'].loc[i]),
                                                                       radians(location_county_df['LONGITUDE'].loc[i])
                                                                      ) for i in range(len(location_county_df))]

        # Normalize elevation and station distance so they get the same weight
        location_county_df['elevation'] = location_county_df['elevation']/location_county_df['elevation'].max()
        location_county_df['station_dist_km'] = location_county_df['station_dist_km']/location_county_df['station_dist_km'].max()

        # Get the location with the same ASHRAE 169 climate zone number and nearest geospatial distance
        fips = location_county_df['county_fips_code'].unique()
        location = []
        count = 0
        for fip in fips:
            idx = np.where(location_county_df['county_fips_code'] == fip)[0]
            diff_arr = np.abs(location_county_df['cz_number_x'].loc[idx]-location_county_df['cz_number_y'].loc[idx]) + 1.0
            dist_arr = np.array(diff_arr*location_county_df['station_dist_km'].loc[idx])

            arg_x = np.argmin(dist_arr)
            location.append(str(location_county_df['location'].loc[idx[arg_x]]))        

        # Write new county to location mapping
        location_to_county_df = pd.DataFrame()
        location_to_county_df['fips'] = fips.astype(int)
        location_to_county_df['location'] = location
        location_to_county_df.to_csv(os.path.join('various_datasets','spatial_data','location_to_county.csv'),index=False)

    def create_spatial_lookup_table(self):
        """Creates a dataframe that joins the spatial and climate zone data."""    
        # Load Data
        ## Load the FIPS table
        fips_df = pd.read_csv(self.fips_file, encoding='latin-1')
        fips_df['long_name'] = fips_df['state_abbr'] + ', ' + fips_df['county_name']

        ## Load the IECC climate zone to county table
        iecc_county_df = pd.read_csv(self.cz_file, encoding='latin-1')
        iecc_county_df['climate_zone'] = iecc_county_df['IECC Climate Zone'].astype(str) + iecc_county_df['IECC Moisture Regime'].astype(str)

        ## Load the Custom Region to state lookup table
        custom_region_state_df = pd.read_csv(os.path.join('various_datasets','spatial_data','state_to_custom_region.csv'))
        
        ## Load PUMA to Census Tract relationship file
        puma_to_tract_df = pd.read_csv(os.path.join('various_datasets','spatial_data','2010_Census_Tract_to_2010_PUMA.csv'))
        puma_to_tract_df['geoid'] = (puma_to_tract_df['STATEFP'].astype(int).astype(str).apply(lambda x: x.zfill(2)) + 
                            puma_to_tract_df['COUNTYFP'].astype(int).astype(str).apply(lambda x: x.zfill(3)) +
                            puma_to_tract_df['TRACTCE'].astype(int).astype(str).apply(lambda x: x.zfill(6)) 
        )        

        ## Load County to ISO/RTO territory table
        county_to_iso_df = pd.read_csv(os.path.join('various_datasets','spatial_data','county_iso_lookup_rider.csv'))
        county_to_iso_df.drop(['state','statefp','state_abbr','countyfp','county_name','county_id'],inplace=True,axis=1)

        ## Load the County to location lookup table
        county_to_location_df = pd.read_csv(os.path.join('various_datasets','spatial_data','location_to_county.csv'))

        ## Load ACS Unit counts by census tract
        acs_tract_df = pd.read_csv(os.path.join('various_datasets','acs','ACS_16_5YR_B25001_with_ann.csv'))
        acs_tract_df['Id2'] = acs_tract_df['Id2'].astype(str).apply(lambda x: x.zfill(11))
        acs_tract_df = acs_tract_df[['Id2','Estimate; Total']].groupby('Id2').sum().reset_index()

        # Merge dataframes into a census tract based table
        ## Merge FIPS table with Climate Zone dataframe
        ### Perform the Merge
        self.df = pd.merge(fips_df,iecc_county_df,left_on=['state','county'],right_on=['State FIPS','County FIPS'])

        ### Drop columns
        self.df.drop(['crosswalk','State','State FIPS','County FIPS','sumlev','County Name'],inplace=True,axis=1)

        ### Remove Alaska and Hawaii
        idx = np.where((self.df['state_abbr'] != 'AK') & (self.df['state_abbr'] != 'HI'))[0]
        self.df = self.df.loc[idx].reset_index(drop=True)

        ### Replace types
        self.df['region'] = self.df['region'].astype(int)
        self.df['division'] = self.df['division'].astype(int)
        self.df['state'] = self.df['state'].astype(int)
        self.df['county'] = self.df['county'].astype(int)
        self.df['IECC Climate Zone'] = self.df['IECC Climate Zone'].astype(int)
        self.df['fips'] = self.df['fips'].astype(int)

        # Merge in ISO/RTO Territories
        self.df = pd.merge(self.df,county_to_iso_df,on='fips',how='left')
        self.df['iso_zone'].fillna('None',inplace=True)

        # Merge Custom Region to State
        self.df = pd.merge(self.df,custom_region_state_df,on='state_abbr')

        ## Merge in PUMA to Census Tract relationship file
        ### Perform the merge
        self.df = pd.merge(puma_to_tract_df,self.df,left_on=['STATEFP','COUNTYFP'],right_on=['state','county'],how='right')

        ### Add data for Oglala Lakota County, SD
        self.df.loc[len(self.df)-1,self.df.columns.values[:5]] = [46.0,102.0,940500,'00200','46102940500']
        self.df.loc[len(self.df),self.df.columns.values] = self.df.loc[len(self.df)-1]
        self.df.loc[len(self.df)-1,self.df.columns.values[:5]] = [46.0,102.0,940800,'00200','46102940800']
        self.df.loc[len(self.df),self.df.columns.values] = self.df.loc[len(self.df)-1]
        self.df.loc[len(self.df)-1,self.df.columns.values[:5]] = [46.0,102.0,940900,'00200','46102940900']

        ### Drop columns
        self.df.drop(['STATEFP','COUNTYFP'],inplace=True,axis=1)
        
        ## Merge in ACS Unit Counts
        ### Perform the merge
        self.df = pd.merge(self.df,acs_tract_df[['Id2','Estimate; Total']],left_on=['geoid'],right_on='Id2',how='left')
        self.df.drop(['Id2'],inplace=True,axis=1)
        
        ## Rename columns
        mapper = {'TRACTCE':'tractce','PUMA5CE':'puma5ce','IECC Climate Zone':'cz_number',
                  'IECC Moisture Regime':'cz_moisture_regime','BA Climate Zone':'ba_climate_zone',
                  'pums_total':'pums_tract_ave','Estimate; Total':'acs_count'}
        self.df.rename(columns=mapper,inplace=True)

        ## Create a pumace and state id
        self.df['puma7ce'] = self.df['state'].astype(int).astype(str).apply(lambda x: x.zfill(2)) + self.df['puma5ce'].astype(str)
        self.df['puma_tsv'] = self.df['state_abbr'] + ', ' + self.df['puma5ce'].astype(int).astype(str).apply(lambda x: x.zfill(5))

        ## Merge in the county to location
        self.df = pd.merge(self.df,county_to_location_df,on='fips')

        ## Add a weight column (used only for pivoting the mapping tsvs)
        self.df['weight'] = 1

        ## Write Spatial lookup table
        self.df.to_csv(os.path.join('various_datasets','spatial_data','spatial_tract_lookup_table.csv'),index=False)

    def create_county_spatial_lookup_table(self):
        """Creates a dataframe that reduces the tract level lookup table to counties."""
        # Copy the tract level lookup table
        self.county_lookup_df = self.df.copy()

        # Drop some columns
        self.county_lookup_df.drop(['tractce','puma7ce','puma5ce','geoid','puma_tsv'],inplace=True,axis=1)

        # Groupby all string variables
        self.county_lookup_df = self.county_lookup_df.groupby(['long_name','county_name','state_abbr',
            'state_name','region_name','division_name','climate_zone','ba_climate_zone','iso_zone',
            'custom_region','location']).sum()

        # Recalculate spatial ids from the sum
        for col in self.county_lookup_df.columns.values:
            if (col != 'acs_count'):
                self.county_lookup_df[col] = self.county_lookup_df[col].div(self.county_lookup_df['weight'],axis=0)
        self.county_lookup_df.reset_index(inplace=True)

        # Write the county spatial lookup data file
        self.county_lookup_df.to_csv(os.path.join('various_datasets','spatial_data','spatial_county_lookup_table.csv'),index=False)

    def add_option_string_to_columns(self,df):
        """Add 'Option=' to all option columns in a dataframe.
        Args: 
            df (pandas.DataFrame): The data frame you want to add the 'Options=' string to the columns
        Returns:
            df (pandas.DataFrame): The data same input dataframe except all columns have a 'Options=' prefix.
        """
        [df.rename(columns={col:'Option=' + col},inplace=True) for col in df.columns.values]
        matching = [s for s in df.columns.values if "Option=" in s]
        for col in matching:
            df[col] = df[col].astype(float)
        return df

    def fill_missing_dependency_rows(self,df,dependency_cols,arr=0):
        """Looks for missing dependency combinations and adds them to the dataframe.
        Args:
            df (pandas.DataFrame): the data frame to check for missing dependencies
            dependency_cols (list(string)): A list of the dependency column names
        Returns:
            df (pandas.DataFrame): the data frame with all dependency column combinations.
        """
        # Get Combinations
        if arr == 0:
            arr = list()
            for i in range(len(dependency_cols)):
                arr.append(self.df[dependency_cols[i]].unique())
        combos = list(itertools.product(*arr))
        
        # For each combo
        df.reset_index(inplace=True)
        for j in range(len(combos)):
            # For each dependency
            tmp = np.ones(len(df)).astype(int)
            for i in range(len(combos[j])):
                tmp = tmp * ( df[df.columns[i]]==combos[j][i] ).astype(int)

            # If there was no depencency combo, add it
            if not np.sum(tmp) == 1:
                # Add Dependencies
                tmp = list()
                for i in range(len(combos[j])):
                    tmp.append(combos[j][i])
                # Add the options
                for i in range(len(df.columns)-len(combos[j])):
                    tmp.append(0)

                # Create a temporary DataFrame
                tmp = pd.DataFrame([tmp], columns=df.columns)

                # Append the temporary DataFrame
                df = df.append(tmp)
        
        return df

    def fill_option_none(self,df,dependency_cols):
        """Looks for rows with small row sums and adds a Option=None column and assigns with 1. This function
        is a result of adding dependency combinations that do not exist in the data.  The row sum is in this
        case is 0. This function ensures that these rows sum to 1.0. The function will not catch rows that are
        close to 1, but not equal to 1.
        Args:
            df (pandas.DataFrame): the data frame to check row sums
            dependency_cols (list(string)): A list of the dependency column names
        Returns:
            df (pandas.DataFrame): the data frame with all rows sum to 1.
        """
        df.set_index(dependency_cols,inplace=True)
        row_sum = df.sum(axis=1)

        if np.min(row_sum) < 1e-14:
            df['Option=None'] = row_sum < 1e-14
            df['Option=None'] = df['Option=None'].astype(int)
        df.reset_index(inplace=True)

        return df   

    def lat_lon_distance(self,lat1,lon1,lat2,lon2):
        """Calculate the distance between two points on earth based on their latitudes and longitudes.
        Args:
            lat1 (float): Latitude of first point
            lon1 (float): Longitude of first point
            lat2 (float): Latitude of second point
            lon2 (float): Longitude of second point
        Returns:
            distance (float): Geospatial distance between the two points in km.
        """
        # approximate radius of earth in km
        R = 6373.0

        dlon = lon2 - lon1
        dlat = lat2 - lat1

        a = sin(dlat / 2)**2 + cos(lat1) * cos(lat2) * sin(dlon / 2)**2
        c = 2 * atan2(sqrt(a), sqrt(1 - a))

        distance = R * c

        return distance

    def enforce_float_format(self,df):
        """Ensure that all non Dependency= Columuns are floats.
        Args:
            df (pandas.DataFrame): the dataframe that the non "Dependency=" columns are converted to floats
        Returns:
            df (pandas.DataFrame): the same dataframe as the input argument except with non dependency columns as floats
        """
        matching = [s for s in df.columns.values if not "Dependency=" in s]
        for col in matching:
            df[col] = df[col].astype(float)
        return df

    def create_ashrae_169_climate_zone_tsv(self):
        """Create the distribution of housing units by ASHRAE 169 climate zone."""
        # Pivot dataframe
        self.ashrae_169_cz_df = pd.pivot_table(self.county_lookup_df,'acs_count',columns='climate_zone',aggfunc=np.sum,fill_value=0)

        # Normalize row
        total_housing_units_acs = float(self.df['acs_count'].sum())
        self.ashrae_169_cz_df = self.ashrae_169_cz_df.astype(float)/total_housing_units_acs

        # Add Option= to each column
        self.ashrae_169_cz_df = self.add_option_string_to_columns(self.ashrae_169_cz_df)

        # Enforce float format
        self.ashrae_169_cz_df = self.enforce_float_format(self.ashrae_169_cz_df)

    def create_state_tsv(self):
        """Create the distribution of housing units by states."""
        # Pivot dataframe
        self.state_df = pd.pivot_table(self.county_lookup_df,'weight',index=['long_name'],columns='state_abbr',aggfunc=np.sum,fill_value=0).reset_index()

        # Rename dependency column
        dependency_fields = ['long_name']
        dependency_cols = ['Dependency=County']
        for i in range(len(dependency_cols)):
            self.state_df.rename(columns={dependency_fields[i]:dependency_cols[i]},inplace=True)

        # Add Option= to each column
        self.state_df = self.state_df.set_index(dependency_cols)
        self.state_df = self.add_option_string_to_columns(self.state_df).reset_index()

        # Enforce float format
        self.state_df = self.enforce_float_format(self.state_df)


    def create_county_tsv(self):
        """Create the distribution of housing units by county."""
        # Pivot dataframe
        self.county_df = pd.pivot_table(self.county_lookup_df,'acs_count',index=['climate_zone'],columns='long_name',aggfunc=np.sum,fill_value=0)

        # Normalize
        self.county_df = self.county_df.div(self.county_df.sum(axis=1),axis=0).reset_index()

        # Rename dependency column
        dependency_fields = ['climate_zone']
        dependency_cols = ['Dependency=ASHRAE IECC Climate Zone 2004']
        for i in range(len(dependency_cols)):
            self.county_df.rename(columns={dependency_fields[i]:dependency_cols[i]},inplace=True)

        # Add Option= to each column
        self.county_df = self.county_df.set_index(dependency_cols)
        self.county_df = self.add_option_string_to_columns(self.county_df)
        
        # Add missing dependencies
        self.county_df = self.fill_missing_dependency_rows(self.county_df,dependency_fields)
        self.county_df.set_index(dependency_cols,inplace=True)
        self.county_df.sort_index(inplace=True)
        self.county_df.reset_index(inplace=True)

        # Add Option=None if needed
        self.county_df = self.fill_option_none(self.county_df,dependency_cols)

        # Enforce float format
        self.county_df = self.enforce_float_format(self.county_df)

    def create_puma_tsv(self):
        """Create the distribution of housing units by PUMA."""
        # Pivot dataframe
        self.puma_df = pd.pivot_table(self.df,'acs_count',index=['state_abbr','long_name'],columns='puma_tsv',aggfunc=np.sum,fill_value=0)
        
        # Normalize
        self.puma_df = self.puma_df.div(self.puma_df.sum(axis=1),axis=0).reset_index()
        self.puma_df.drop(['state_abbr'],inplace=True,axis=1)

        # Rename dependency column
        dependency_fields = ['long_name']
        dependency_cols = ['Dependency=County']
        for i in range(len(dependency_cols)):
            self.puma_df.rename(columns={dependency_fields[i]:dependency_cols[i]},inplace=True)

        # Add Option= to each column
        self.puma_df = self.puma_df.set_index(dependency_cols)
        self.puma_df = self.add_option_string_to_columns(self.puma_df).reset_index()

        # Enforce float format
        self.puma_df = self.enforce_float_format(self.puma_df)

    def create_census_division_tsv(self):
        """Create a mapping housing characteristic that maps states to census divisions."""
        # Pivot dataframe
        self.census_division_df = pd.pivot_table(self.df,'weight',index=['division','state_abbr'],columns='division_name',aggfunc=np.sum,fill_value=0).reset_index()
        self.census_division_df.drop(['division'],inplace=True,axis=1)
        
        # Rename dependency column
        dependency_col = 'Dependency=State'
        self.census_division_df.rename(columns={'state_abbr':dependency_col},inplace=True)

        # Add Option= to each column
        self.census_division_df.set_index(dependency_col,inplace=True)
        self.census_division_df = self.add_option_string_to_columns(self.census_division_df)
        self.census_division_df = (self.census_division_df > 0).astype(int).reset_index()

        # Enforce float format
        self.census_division_df = self.enforce_float_format(self.census_division_df)

    def create_census_region_tsv(self):
        """Create a mapping housing characteristic that maps census divisions to census regions."""
        # Pivot dataframe
        self.census_region_df = pd.pivot_table(self.county_lookup_df,'weight',index=['region','division_name'],columns='region_name',aggfunc=np.sum,fill_value=0).reset_index()
        self.census_region_df.drop(['region'],inplace=True,axis=1)
        
        # Rename dependency column
        dep_col = 'Dependency=Census Division'
        self.census_region_df.rename(columns={'division_name':dep_col},inplace=True)

        # Add Option= to each column
        self.census_region_df.set_index(dep_col,inplace=True)
        self.census_region_df = self.add_option_string_to_columns(self.census_region_df)
        self.census_region_df = (self.census_region_df > 0).astype(int).reset_index()

        # Enforce float format
        self.census_region_df = self.enforce_float_format(self.census_region_df)

    def create_location_region_tsv(self):
        """Create a mapping housing characteristic that maps states to custom regions."""
        # Pivot dataframe
        self.location_region_df = pd.pivot_table(self.county_lookup_df,'weight',index=['state_abbr'],columns='custom_region',aggfunc=np.sum,fill_value=0).reset_index()
        
        # Rename dependency column
        dependency_col = 'Dependency=State'
        self.location_region_df.rename(columns={'state_abbr':dependency_col},inplace=True)

        # Add Option= to each column
        self.location_region_df.set_index(dependency_col,inplace=True)
        self.location_region_df = self.add_option_string_to_columns(self.location_region_df)
        self.location_region_df = (self.location_region_df > 0).astype(int).reset_index()

        # Enforce float format
        self.location_region_df = self.enforce_float_format(self.location_region_df)

    def create_building_america_climate_zone_tsv(self):
        """Create a mapping housing characteristic that maps counties to Building America climate zones."""
        # Pivot dataframe
        self.ba_cz_df = pd.pivot_table(self.county_lookup_df,'weight',index=['state_name','long_name'],columns='ba_climate_zone',aggfunc=np.sum,fill_value=0).reset_index()
        self.ba_cz_df.drop(['state_name'],inplace=True,axis=1)

        # Rename dependency column
        dependency_col = 'Dependency=County'
        self.ba_cz_df.rename(columns={'long_name':dependency_col},inplace=True)

        # Add Option= to each column
        self.ba_cz_df.set_index(dependency_col,inplace=True)
        self.ba_cz_df = self.add_option_string_to_columns(self.ba_cz_df).reset_index()

        # Enforce float format
        self.ba_cz_df = self.enforce_float_format(self.ba_cz_df)

    def create_iso_rto_region_tsv(self):
        """Create a mapping housing characteristic that maps counties to ISO/RTO regions."""
        # Pivot dataframe
        self.iso_rto_df = pd.pivot_table(self.county_lookup_df,'weight',index=['state_name','long_name'],columns='iso_zone',aggfunc=np.sum,fill_value=0).reset_index()
        self.iso_rto_df.drop(['state_name'],inplace=True,axis=1)

        # Rename dependency column
        dependency_col = 'Dependency=County'
        self.iso_rto_df.rename(columns={'long_name':dependency_col},inplace=True)

        # Add Option= to each column
        self.iso_rto_df.set_index(dependency_col,inplace=True)
        self.iso_rto_df = self.add_option_string_to_columns(self.iso_rto_df).reset_index()

        # Enforce float format
        self.iso_rto_df = self.enforce_float_format(self.iso_rto_df)

    def create_location_tsv(self):
        """Create a mapping housing characteristic that maps counties to weather station locations."""
        # Pivot dataframe
        self.location_df = pd.pivot_table(self.county_lookup_df,'weight',index=['state_name','long_name'],columns='location',aggfunc=np.sum,fill_value=0).reset_index()
        self.location_df.drop(['state_name'],inplace=True,axis=1)

        # Rename dependency column
        dependency_col = 'Dependency=County'
        self.location_df.rename(columns={'long_name':dependency_col},inplace=True)

        # Add Option= to each column
        self.location_df.set_index(dependency_col,inplace=True)
        self.location_df = self.add_option_string_to_columns(self.location_df).reset_index()

        # Enforce float format
        self.location_df = self.enforce_float_format(self.location_df)

    def write_tsvs_to_projects(self):
        """Write new tsvs to all projects in the self.projects member."""
        for project in self.projects:
            # ASHRAE 169 Climate Zone
            write_path = os.path.join('..','..',project,'housing_characteristics','ASHRAE IECC Climate Zone 2004.tsv')
            try:
                self.ashrae_169_cz_df.to_csv(write_path,sep='\t',index=False, line_terminator='\r\n', float_format='%.6f')
            except AttributeError:
                self.create_ashrae_169_climate_zone_tsv()
                self.ashrae_169_cz_df.to_csv(write_path,sep='\t',index=False, line_terminator='\r\n', float_format='%.6f')

            # State
            write_path = os.path.join('..','..',project,'housing_characteristics','State.tsv')
            try:
                self.state_df.to_csv(write_path,sep='\t',index=False, line_terminator='\r\n', float_format='%.6f')
            except AttributeError:
                self.create_state_tsv()
                self.state_df.to_csv(write_path,sep='\t',index=False, line_terminator='\r\n', float_format='%.6f')

            # Census Division
            write_path = os.path.join('..','..',project,'housing_characteristics','Census Division.tsv')
            try:
                self.census_division_df.to_csv(write_path,sep='\t',index=False, line_terminator='\r\n', float_format='%.6f')
            except AttributeError:
                self.create_census_division_tsv()
                self.census_division_df.to_csv(write_path,sep='\t',index=False, line_terminator='\r\n', float_format='%.6f')

            # Census Region
            write_path = os.path.join('..','..',project,'housing_characteristics','Census Region.tsv')
            try:
                self.census_region_df.to_csv(write_path,sep='\t',index=False, line_terminator='\r\n', float_format='%.6f')
            except AttributeError:
                self.create_census_region_tsv()
                self.census_region_df.to_csv(write_path,sep='\t',index=False, line_terminator='\r\n', float_format='%.6f')

            # Location Region
            write_path = os.path.join('..','..',project,'housing_characteristics','Location Region.tsv')
            try:
                self.location_region_df.to_csv(write_path,sep='\t',index=False, line_terminator='\r\n', float_format='%.6f')
            except AttributeError:
                self.create_location_region_tsv()
                self.location_region_df.to_csv(write_path,sep='\t',index=False, line_terminator='\r\n', float_format='%.6f')

            # ISO/RTO Region
            write_path = os.path.join('..','..',project,'housing_characteristics','ISO RTO Region.tsv')
            try:
                self.iso_rto_df.to_csv(write_path,sep='\t',index=False, line_terminator='\r\n', float_format='%.6f')
            except AttributeError:
                self.create_iso_rto_region_tsv()
                self.iso_rto_df.to_csv(write_path,sep='\t',index=False, line_terminator='\r\n', float_format='%.6f')

            # Location
            write_path = os.path.join('..','..',project,'housing_characteristics','Location.tsv')
            try:
                self.location_df.to_csv(write_path,sep='\t',index=False, line_terminator='\r\n', float_format='%.6f')
            except AttributeError:
                self.create_location_tsv()
                self.location_df.to_csv(write_path,sep='\t',index=False, line_terminator='\r\n', float_format='%.6f')

            # Location
            write_path = os.path.join('..','..',project,'housing_characteristics','Building America Climate Zone.tsv')
            try:
                self.ba_cz_df.to_csv(write_path,sep='\t',index=False, line_terminator='\r\n', float_format='%.6f')
            except AttributeError:
                self.create_building_america_climate_zone_tsv()
                self.ba_cz_df.to_csv(write_path,sep='\t',index=False, line_terminator='\r\n', float_format='%.6f')

            # County
            write_path = os.path.join('..','..',project,'housing_characteristics','County.tsv')
            try:
                self.county_df.to_csv(write_path,sep='\t',index=False, line_terminator='\r\n', float_format='%.6f')
            except AttributeError:
                self.create_county_tsv()
                self.county_df.to_csv(write_path,sep='\t',index=False, line_terminator='\r\n', float_format='%.6f')

            # PUMA
            write_path = os.path.join('..','..',project,'housing_characteristics','PUMA.tsv')
            try:
                self.puma_df.to_csv(write_path,sep='\t',index=False, line_terminator='\r\n', float_format='%.6f')
            except AttributeError:
                self.create_puma_tsv()
                self.puma_df.to_csv(write_path,sep='\t',index=False, line_terminator='\r\n', float_format='%.6f')
