#!/usr/bin/env python3

import os, sys
import pandas as pd
from IPython.display import display

openstudio_buildstock_path = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
sys.path.append(openstudio_buildstock_path)
from data.tsv_maker import TSVMaker

this_file = os.path.basename(__file__)
dir_of_this_file = os.path.basename(os.path.dirname(__file__))
parent_dir_of_this_file = os.path.basename(os.path.dirname(os.path.dirname(__file__)))

created_by = os.path.join(parent_dir_of_this_file, dir_of_this_file, this_file)
source = ' using the 2015 U.S. Lighting Market Characterization report from U.S. DOE office of EERE prepared by Navigant Consulting'

projects = ['project_singlefamilydetached', 'project_multifamily_beta', 'project_testing']
for project in projects:
    project_dir = os.path.join(os.path.dirname(__file__), project)
    if not os.path.exists(project_dir):
        os.mkdir(project_dir)

class OtherSources(TSVMaker):

    def __init__(self):
        pass

    def lighting(self):
        """ Create a lighting housing characteristic."""
        # Write and copy the file
        for project in projects:
            dependency_cols = []
            option_col = 'Lighting'

            if project != 'project_testing':
                cols = [
                    'Option=100% Incandescent',
                    'Option=100% CFL',
                    'Option=100% LED',
                    'sample_count',
                    'sample_weight'
                ]

                # Using Data from Table 4.2 on page 49 of the report.
                # ASSUMPTION: Incandescent contains Incandescent, Halogen, High Intensity Discharge, Other
                # ASSUMPTION: CFL contains CFL and LFL
                # ASSUMPTION: LED contains LED
                probs = [0.516, 0.414, 0.07, 0.0, 0.0]
            else:
                cols = [
                    'Option=100% Incandescent',
                    'Option=60% CFL Hardwired, 34% CFL Plugin',
                    'Option=60% LED Hardwired, 34% CFL Plugin',
                    'Option=60% CFL',
                    'Option=100% CFL',
                    'Option=100% LED',
                    'Option=100% LED, Low Efficacy',
                    'Option=100% LED, Holiday Lights',
                    'Option=20% LED',
                    'Option=None'
                ]

                probs = [1.0 / len(cols)] * len(cols)

            # Initialize dataframe
            lighting = pd.DataFrame(columns=cols)
            lighting.loc[0, cols] = probs

            filepath = os.path.normpath(os.path.join(os.path.dirname(__file__), project, '{}.tsv'.format(option_col)))
            self.export_and_tag(lighting, filepath, project, created_by, source)
            self.copy_file_to_project(filepath, project)

if __name__ == '__main__':
    # Initialize object
    tsv_maker = OtherSources()

    # Create housing characteristics
    tsv_maker.lighting()