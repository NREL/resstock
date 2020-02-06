#!/usr/bin/env python3

import os, sys
import pandas as pd
import parameter_option_maps
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")))
from recs.tsv_maker import TSVMaker

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

    def __init__(self, file):
        self.df = pd.read_csv(file, index_col=['DOEID'])
        self.df[self.count_col_label()] = 1

        # Split out Hawaii
        hawaii_rows = self.df[(self.df['REPORTABLE_DOMAIN'] == 27) & ((self.df['AIA_Zone'] == 5) | (self.df['HDD65'] < 4000))].index

        # Split out Alaska
        alaska_rows = self.df[(self.df['REPORTABLE_DOMAIN'] == 27) & ((self.df['HDD65'] > 6930))].index # Source for 6930 HDD: Dennis Barley

        # Drop Alaska and Hawaii
        self.df.drop(hawaii_rows, inplace=True)
        self.df.drop(alaska_rows, inplace=True)

    def geometry_wall_type(self): # for WoodStud or Masonry walls
        df = self.df.copy()

        df = parameter_option_maps.map_location_region(df) # dependency
        df = parameter_option_maps.map_vintage(df) # dependency
        df = parameter_option_maps.map_geometry_wall_type(df) # option

        dependency_cols = ['Location Region', 'Vintage']
        option_col = 'Geometry Wall Type'

        for project in projects:
            if project != 'project_multifamily_beta':
                continue

            geometry_wall_type = df.copy()

            geometry_wall_type, count, weight = self.groupby_and_pivot(geometry_wall_type, dependency_cols, option_col)

            # Add in 2010s
            geometry_wall_type = geometry_wall_type.reset_index()
            test_df = geometry_wall_type.loc[geometry_wall_type['Vintage'] == '2000s'].copy()
            test_df["Vintage"] = '2010s'
            geometry_wall_type = pd.concat([geometry_wall_type, test_df])
            geometry_wall_type = geometry_wall_type.set_index(dependency_cols)

            geometry_wall_type = self.add_missing_dependency_rows(geometry_wall_type, project, count, weight)
            geometry_wall_type = self.rename_cols(geometry_wall_type, dependency_cols, project)

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

            filepath = os.path.normpath(os.path.join(os.path.dirname(__file__), project, '{}.tsv'.format(option_col)))
            self.export_and_tag(misc_pool, filepath, project, created_by, source)
            self.copy_file_to_project(filepath, project)

if __name__ == '__main__':
    recs_filepath = 'c:/recs2009/recs2009_public.csv' # raw recs microdata

    tsv_maker = RECS2009(recs_filepath)

    tsv_maker.geometry_wall_type()
    tsv_maker.misc_pool()
    tsv_maker.misc_pool_heater()
    tsv_maker.misc_hot_tub_spa()