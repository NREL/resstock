"""
# Residential results.csv comparisons.
- - - - - - - - -
A class to compare two resstock runs and the resulting differences in the results.csv.

**Authors:**

- Anthony Fontanini (Anthony.Fontanini@nrel.gov)
"""

# Import Modules
import os, sys
import numpy as np
import pandas as pd
import seaborn as sns
import matplotlib
import matplotlib.pyplot as plt
import plotly
import plotly.graph_objects as go
import argparse
from plotly.subplots import make_subplots

model_types = ['Single-Family Detached', 'Single-Family Attached', 'Multi-Family']


class res_results_csv_comparisons:
    def __init__(self, base_table_name, feature_table_name, groupby, cols_to_use=None, out_dir=None):
        """
        A class to compare a baseline ResStock run to a new feature ResStock run.
        The comparisons are performed on the results.csv from each run
        Args:
            base_table_name (string): The name of the baseline table.
            feature_table_name (string): The name of the new feature table.
            groupby (list[str]): List of characteristics to query and group by.
        """

        # Initialize members
        # Constants
        self.base_table_name = base_table_name
        self.feature_table_name = feature_table_name
        self.groupby = groupby
        self.cols_to_use = cols_to_use
        self.out_dir = out_dir

        # Create output directories
        self.create_output_directories()

        # Download data or load into memory
        self.query_data()

        # Get fields
        self.get_common_output_fields()

        # Format queried data
        self.format_queried_data()

    def create_output_directories(self):
        """
        Create output directories for the figures and queried data.
        """

        # Directory for the queried data
        if self.out_dir:
            create_path = os.path.join(self.out_dir, 'comparisons')
        else:
            create_path = os.path.join(os.path.dirname(self.base_table_name), 'comparisons')
        if not os.path.exists(create_path):
            os.makedirs(create_path)

    def get_common_output_fields(self):
        """
        Get the common output fields for comparison.
        """
        print('Getting Common Fields...')
        self.base_fields = self.base_df.columns.tolist()
        self.feature_fields = self.feature_df.columns.tolist()

        # Get common fields
        self.common_fields = list(set(self.base_fields) & set(self.feature_fields))
        self.common_fields.sort()

        # Get common result columns
        self.common_result_columns = [field for field in self.common_fields if ('simulation_output_report' in field) or ('upgrade_costs' in field)]

        # Remove fields if exist
        fields = [
            'simulation_output_report.applicable',
            'simulation_output_report.include_enduse_subcategories',
            'simulation_output_report.upgrade_cost_usd',
            'simulation_output_report.output_format',
            'simulation_output_report.include_timeseries_airflows',
            'simulation_output_report.include_timeseries_component_loads',
            'simulation_output_report.include_timeseries_end_use_consumptions',
            'simulation_output_report.include_timeseries_fuel_consumptions',
            'simulation_output_report.include_timeseries_hot_water_uses',
            'simulation_output_report.include_timeseries_total_loads',
            'simulation_output_report.include_timeseries_unmet_loads',
            'simulation_output_report.include_timeseries_weather',
            'simulation_output_report.include_timeseries_zone_temperatures',
            'simulation_output_report.time',
            'simulation_output_report.timeseries_frequency',
            'upgrade_costs.applicable'
        ]

        for field in fields:
            if field in self.common_result_columns:
                self.common_result_columns.remove(field)

        # Get saved field names
        self.saved_fields = [col.split('.')[1] for col in self.common_result_columns]

    def map_end_uses(self, df):
        print("Mapping end uses...")
        cwd = os.path.dirname(os.path.realpath(__file__))
        map_df = pd.read_csv(os.path.join(cwd, 'column_mapping.csv'), usecols=['restructure_cols','develop_cols'])
        map_df = map_df.dropna(axis=0)
        map_dict = {k:v for k,v in zip(map_df['develop_cols'], map_df['restructure_cols'])}

        # Unit conversions
        for col in df.columns:
            units = col.split('_')[-1]
            if units == 'kwh':
                if col == 'simulation_output_report.electricity_heating_supplemental_kwh':
                    df[col] *= 3412.14/1000 # to kbtu
                else:
                    df[col] *= 3412.14/1000000  # to mbtu
            elif units == 'therm':
                df[col] *= 0.1  # to mbtu

        # Aggregate variables w/ multiple cols
        for cols, map_to in map_dict.items():
            cols = cols.split(',')
            if len(cols)>1:
                df[map_to] = df[cols].sum(axis=1)

        # Remove central systems from total site
        # central_htg_cond = ((df['build_existing_model.hvac_has_shared_system'] == 'Heating and Cooling') |
        #                     (df['build_existing_model.hvac_has_shared_system'] == 'Heating Only'))
        # central_clg_cond = ((df['build_existing_model.hvac_has_shared_system'] == 'Heating and Cooling') |
        #                     (df['build_existing_model.hvac_has_shared_system'] == 'Cooling Only'))
        # df.loc[central_htg_cond, 'simulation_output_report.total_site_electricity_kwh'] -= df.loc[central_htg_cond,'simulation_output_report.electricity_heating_kwh']
        # df.loc[central_clg_cond, 'simulation_output_report.total_site_electricity_kwh'] -= df.loc[central_clg_cond, 'simulation_output_report.electricity_cooling_kwh']

        df.rename(columns=map_dict, inplace=True)
        return(df)

    def query_data(self):
        """
        Query the result.csvs if they do not already exist. Load queried or local data into memory.
        """
        print('Querying/Loading Data...')

        # Query/Load Base Table Data
        base_data_path = self.base_table_name
        print('  Loading %s Data...' % self.base_table_name)
        self.base_df = pd.read_csv(base_data_path)

        # Query/Load Feature Table Data
        feature_data_path = self.feature_table_name
        print('  Loading %s Data...' % self.feature_table_name)
        self.feature_df = pd.read_csv(feature_data_path)

        # Map old columns to new columns
        if self.cols_to_use=='feature':
            self.base_df = self.map_end_uses(self.base_df)
        elif self.cols_to_use=='base':
            self.feature_df = self.map_end_uses(self.feature_df)

    def format_queried_data(self):
        """
        Format the queried data for plotting.
        """

        # Filter out buildings w/ central systems
        base_central = ((self.base_df['build_existing_model.hvac_has_shared_system'] == 'Heating and Cooling') |
                            (self.base_df['build_existing_model.hvac_has_shared_system'] == 'Cooling Only') |
                            (self.base_df['build_existing_model.hvac_has_shared_system'] == 'Heating Only'))
        feature_central = ((self.feature_df['build_existing_model.hvac_has_shared_system'] == 'Heating and Cooling') |
                            (self.feature_df['build_existing_model.hvac_has_shared_system'] == 'Cooling Only') |
                            (self.feature_df['build_existing_model.hvac_has_shared_system'] == 'Heating Only'))

        self.base_df = self.base_df[~base_central]
        self.feature_df = self.feature_df[~feature_central]

        for col in self.base_df.columns.tolist():
            if ('simulation_output_report' not in col) and ('upgrade_costs' not in col):
                continue
            self.base_df = self.base_df.rename(columns={col: col.split('.')[1]})

        for col in self.feature_df.columns.tolist():
            if ('simulation_output_report' not in col) and ('upgrade_costs' not in col):
                continue
            self.feature_df = self.feature_df.rename(columns={col: col.split('.')[1]})

        # Format data frames
        model_map = {
            'Mobile Home': 'Single-Family Detached',
            'Single-Family Detached': 'Single-Family Detached',
            'Single-Family Attached': 'Single-Family Attached',
            'Multi-Family with 2 - 4 Units': 'Multi-Family',
            'Multi-Family with 5+ Units': 'Multi-Family',
        }
        col = 'build_existing_model.geometry_building_type_recs'
        self.base_df[col] = self.base_df[col].map(model_map)
        self.feature_df[col] = self.feature_df[col].map(model_map)

        # Set Index
        self.base_df = self.base_df.groupby(self.groupby).mean().reset_index()
        self.feature_df = self.feature_df.groupby(self.groupby).mean().reset_index()

    def plot_failures(self):
        """
        Bar chart of the number of failures.
        """
        # Read DataFrames
        base_df = pd.read_csv(self.base_table_name)
        feature_df = pd.read_csv(self.feature_table_name)

        if not 'completed_status' in base_df.columns.tolist():
            return

        n_base = base_df[base_df['completed_status']=='Fail'].shape[0]
        n_feature = feature_df[feature_df['completed_status']=='Fail'].shape[0]

        print('Plotting number of failures...')
        print('  Failures %s: %d' % (self.base_table_name, n_base))
        print('  Failures %s: %d' % (self.feature_table_name, n_feature))

        # Figure
        plt.bar([0, 1], [n_base, n_feature])
        plt.xlim([-1, 2])
        plt.ylim([0, 1.2 * np.max([n_base, n_feature])])
        plt.xticks(ticks=[0, 1], labels=[os.path.basename(f'{self.base_table_name} (base)'), os.path.basename(f'{self.feature_table_name} (feature)')], rotation=30, ha='right')
        plt.title('Number of failures')
        plt.ylabel('Failures')

        if self.out_dir:
            output_path = os.path.join(self.out_dir, 'comparisons', 'failures.svg')
        else:
            output_path = os.path.join(os.path.dirname(self.base_table_name), 'comparisons', 'failures.svg')
        plt.savefig(output_path, bbox_inches='tight')
        plt.close()

    def condense_end_uses(self):
        """
        col_to_add: [cols_to_lump]
        """
        groups = {
         'end_use_electricity_cooling_m_btu': ['end_use_electricity_cooling_m_btu', 'end_use_electricity_cooling_fans_pumps_m_btu', 'end_use_electricity_mech_vent_precooling_m_btu'],
         'end_use_electricity_heating_m_btu': ['end_use_electricity_heating_m_btu', 'end_use_electricity_heating_fans_pumps_m_btu', 'end_use_electricity_mech_vent_preheating_m_btu'],
         'end_use_electricity_hot_water_m_btu': ['end_use_electricity_hot_water_m_btu', 'end_use_electricity_hot_water_recirc_pump_m_btu', 'end_use_electricity_hot_water_solar_thermal_pump_m_btu'],
         'end_use_electricity_lighting_m_btu': ['end_use_electricity_lighting_exterior_m_btu', 'end_use_electricity_lighting_garage_m_btu', 'end_use_electricity_lighting_interior_m_btu'],
         'end_use_electricity_pool_hot_tub_m_btu': ['end_use_electricity_pool_heater_m_btu', 'end_use_electricity_pool_pump_m_btu', 'end_use_electricity_hot_tub_heater_m_btu', 'end_use_electricity_hot_tub_pump_m_btu']
        }

        # Omit variables that are not present in original SimOutputReport
        if self.cols_to_use:
            groups = {
            'end_use_electricity_cooling_m_btu': ['end_use_electricity_cooling_m_btu', 'end_use_electricity_cooling_fans_pumps_m_btu'],
            'end_use_electricity_heating_m_btu': ['end_use_electricity_heating_m_btu', 'end_use_electricity_heating_fans_pumps_m_btu'],
            'end_use_electricity_hot_water_m_btu': ['end_use_electricity_hot_water_m_btu'],
            'end_use_electricity_lighting_m_btu': ['end_use_electricity_lighting_exterior_m_btu', 'end_use_electricity_lighting_garage_m_btu', 'end_use_electricity_lighting_interior_m_btu'],
            'end_use_electricity_pool_hot_tub_m_btu': ['end_use_electricity_pool_heater_m_btu', 'end_use_electricity_pool_pump_m_btu', 'end_use_electricity_hot_tub_heater_m_btu', 'end_use_electricity_hot_tub_pump_m_btu']
            }

        for new_col, old_cols in groups.items():
            self.base_df[new_col] = self.base_df[old_cols].sum(axis=1)
            self.feature_df[new_col] = self.feature_df[old_cols].sum(axis=1)

            for old_col in old_cols:
                if new_col == old_col:
                    old_cols.remove(old_col)

            self.base_df = self.base_df.drop(old_cols, axis = 1)
            self.feature_df = self.feature_df.drop(old_cols, axis = 1)

            for old_col in old_cols:
                self.saved_fields.remove(old_col)
            if not new_col in self.saved_fields:
                self.saved_fields.append(new_col)

        self.saved_fields = sorted(self.saved_fields)

    def regression_scatterplots(self):
        """
        Scatterplot for each model type and simulation_outupt_report value.
        """
        # Copy DataFrames
        base_df = self.base_df.copy()
        feature_df = self.feature_df.copy()

        print('Plotting regression scatterplots...')
        colors = list(matplotlib.colors.get_named_colors_mapping().values())
        for fuel_use in self.saved_fields:
            if not 'fuel_use' in fuel_use:
                continue

            fig = make_subplots(rows=1, cols=3, subplot_titles=model_types)
            for model_type in model_types:
                # Get model specific data
                btype_col = 'build_existing_model.geometry_building_type_recs'
                tmp_base_df = base_df.loc[base_df[btype_col] == model_type, :]
                tmp_base_df.set_index(self.groupby, inplace=True)
                tmp_feature_df = feature_df.loc[feature_df[btype_col] == model_type, :]
                tmp_feature_df.set_index(self.groupby, inplace=True)

                names = fuel_use.split('_')
                fuel_type = names[2]
                if names[3] in ['gas', 'oil']:
                    fuel_type += '_{}'.format(names[3])

                min_value = 0
                max_value = 0
                for i, end_use in enumerate(self.saved_fields):
                    if not 'end_use' in end_use:
                        continue
                    if not fuel_type in end_use:
                        continue
                    
                    col = model_types.index(model_type) + 1
                    showlegend = False
                    if col == 1:
                        showlegend = True

                    if 0.9 * np.min([tmp_base_df[end_use].min(), tmp_feature_df[end_use].min()]) < min_value:
                        min_value = 0.9 * np.min([tmp_base_df[end_use].min(), tmp_feature_df[end_use].min()])
                    if 1.1 * np.max([tmp_base_df[end_use].max(), tmp_feature_df[end_use].max()]) > max_value:
                        max_value = 1.1 * np.max([tmp_base_df[end_use].max(), tmp_feature_df[end_use].max()])

                    fig.add_trace(go.Scatter(x=tmp_base_df[end_use], y=tmp_feature_df[end_use], marker=dict(size=15, color=colors[i]), mode='markers', name=end_use, legendgroup=end_use, showlegend=showlegend), row=1, col=col)

                fig.add_trace(go.Scatter(x=[min_value, max_value], y=[min_value, max_value], line=dict(color='black', dash='dash', width=0.5), mode='lines', showlegend=False), row=1, col=col)
                fig.update_xaxes(title_text=os.path.basename(f'{self.base_table_name} (base)'), row=1, col=col)
                fig.update_yaxes(title_text=os.path.basename(f'{self.feature_table_name} (feature)'), row=1, col=col)

            fig['layout'].update(title=fuel_use, template='plotly_white')
            fig.update_layout(width=3600, height=1100, autosize=False, font=dict(size=24))
            for i in fig['layout']['annotations']:
                i['font'] = dict(size=30)
            if self.out_dir:
                output_path = os.path.join(self.out_dir, 'comparisons', fuel_use + '.svg')
            else:
                output_path = os.path.join(os.path.dirname(self.base_table_name), 'comparisons', fuel_use + '.svg')
            # plotly.offline.plot(fig, filename=output_path, auto_open=False) # html
            fig.write_image(output_path)

    def regression_tables(self):
        """
        Values for each model type and simulation_output_report value.
        """
        # Copy DataFrames
        base_df = self.base_df.copy()
        feature_df = self.feature_df.copy()

        base_df = base_df.set_index('build_existing_model.geometry_building_type_recs')[self.saved_fields]
        feature_df = feature_df.set_index('build_existing_model.geometry_building_type_recs')[self.saved_fields]

        included_model_types = base_df.index.unique()
        sorted_model_types = model_types
        for model_type in model_types:
            if not model_type in included_model_types:
                sorted_model_types.remove(model_type)

        print('Creating regression tables...')
    
        base_df = base_df.stack()
        feature_df = feature_df.stack()

        deltas = pd.DataFrame()
        deltas['base'] = base_df
        deltas['feature'] = feature_df
        deltas['diff'] = deltas['feature'] - deltas['base']
        deltas['% diff'] = 100*(deltas['diff']/deltas['base'])
        deltas = deltas.round(2)
        
        deltas.reset_index('build_existing_model.geometry_building_type_recs', inplace=True)
        model_type_map = {'Single-Family Detached':'SFD', 'Single-Family Attached':'SFA', 'Multi-Family':'MF'}
        deltas['build_existing_model.geometry_building_type_recs'] = deltas['build_existing_model.geometry_building_type_recs'].map(model_type_map)
        if self.out_dir:
            output_path = os.path.join(self.out_dir, 'comparisons', 'deltas.csv')
        else:
            output_path = os.path.join(os.path.dirname(self.base_table_name), 'comparisons', 'deltas.csv')
        deltas.to_csv(output_path)

if __name__ == '__main__':

    # Inputs
    example_use = 'python res_results_csv_comparisons.py <base_results.csv> <feature_results.csv> --use_cols feature'
    parser = argparse.ArgumentParser(epilog=f'Example usage (uses feature columns):\n{example_use}', formatter_class=argparse.RawTextHelpFormatter)
    parser.add_argument("base_table_name", help="Filepath to base results table", type=str)
    parser.add_argument("feature_table_name", help="Filepath to feature results table", type=str)
    parser.add_argument("--use_cols", help="Which table's variable names to use (base or feature)", type=str)  # Only can map from old to new right now
    parser.add_argument("--out_dir", help="Filepath to output directory", type=str)
    args = parser.parse_args()

    base_table_name = args.base_table_name
    feature_table_name = args.feature_table_name
    cols_to_use = args.use_cols
    out_dir = args.out_dir 

    groupby = [
        'build_existing_model.geometry_building_type_recs',  # Needed to split out by models
        # 'build_existing_model.county'  # Choose any other characteristic(s)
    ]

    # Initialize object
    results_csv_comparison = res_results_csv_comparisons(
        base_table_name=base_table_name,
        feature_table_name=feature_table_name,
        groupby=groupby,
        cols_to_use=cols_to_use,
        out_dir=out_dir
    )

    # Plot the number of failures for each run
    results_csv_comparison.plot_failures()

    # Generate tables for each model type and simulation_output_report field
    results_csv_comparison.regression_tables()

    # Condense some end uses
    results_csv_comparison.condense_end_uses()

    # Generate scatterplots for each model type and simulation_output_report field
    results_csv_comparison.regression_scatterplots()
