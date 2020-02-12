import os
import pandas as pd

this_file = os.path.basename(__file__)
dir_of_this_file = os.path.basename(os.path.dirname(__file__))
parent_dir_of_this_file = os.path.basename(os.path.dirname(os.path.dirname(__file__)))
created_by = os.path.join(parent_dir_of_this_file, dir_of_this_file, this_file)
this_file = os.path.basename(__file__)
source = ' using the 2015 U.S. Lighting Market Characterization report from U.S. DOE office of EERE prepared by Navigant Consulting.'

count_col_label = 'source_count'
weight_col_label = 'source_weight'

class Lighting():
    
    def __init__(self,projects):
       self.projects = projects

    def create_lighting_tsv(self):
    	""" 
    	Create a lighting housing characteristic.
    	"""
    	# Initialize dataframe
    	cols = ['Option=100% Incandescent','Option=100% CFL','Option=100% LED','source_count','source_weight']
    	self.df = pd.DataFrame(columns=cols)

    	# Using Data from Table 4.2 on page 49 of the report. 
    	# ASSUMPTION: Incandescent contains Incandescent, Halogen, High Intensity Discharge, Other
    	# ASSUMPTION: CFL contains CFL and LFL
    	# ASSUMPTION: LED contains LED
    	self.df.loc[0,cols] = [0.516,0.414,0.07,0,0]

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

    def export_and_tag(self, df, filepath, project):
        """
        Add bottom-left script and source tag to dataframe (for non testing projects). Save dataframe to tsv file.
        Parameters:
          df (dataframe): A pandas dataframe with dependency/option columns and fractions.
          filepath (str): The path of the tsv file to export.
          project (str): Name of the project.
        """
        # Write the data file
        df = self.enforce_float_format(df)
        df.to_csv(filepath,sep='\t',index=False, line_terminator='\r\n', float_format='%.6f')

        # Append the created by line
        if 'testing' not in project:
            tag = "Created by: " + created_by
            tag += source
            tag += "\r\n"
            with open(filepath, "a") as file_object:
                file_object.write(tag)
        print('{}'.format(filepath))

    def write_tsvs_to_projects(self):
        """Write new tsvs to all projects in the self.projects member."""
        for project in self.projects:
            # Lighting
            write_path = os.path.join('..','..',project,'housing_characteristics','Lighting.tsv')
            try:
                self.export_and_tag(self.df, write_path, project)
            except AttributeError:
                self.create_lighting_tsv()
                self.export_and_tag(self.df, write_path, project)