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
from plotly.subplots import make_subplots


class res_results_csv_comparisons:
    def __init__(self, base_table_name, feature_table_name, groupby):
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

        # Create output directories
        self.create_output_directories()

        # Get fields
        self.get_common_output_fields()

        # Download data or load into memory
        self.query_data()

        # Format queried data
        self.format_queried_data()

    def create_output_directories(self):
        """
        Create output directories for the figures and queried data.
        """

        # Directory for the queried data
        create_path = os.path.join(os.path.dirname(self.base_table_name), 'figures')
        if not os.path.exists(create_path):
            os.makedirs(create_path)

    def get_common_output_fields(self):
        """
        Get the common output fields for comparison.
        """
        print('Getting Common Fields...')

        self.base_fields = pd.read_csv(self.base_table_name, index_col=0, nrows=0).columns.tolist()
        self.feature_fields = pd.read_csv(self.feature_table_name, index_col=0, nrows=0).columns.tolist()

        # Get common fields
        self.common_fields = list(set(self.base_fields) & set(self.feature_fields))
        self.common_fields.sort()

        # Get common result columns
        self.common_result_columns = [field for field in self.common_fields if 'simulation_output_report' in field]

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
            'simulation_output_report.timeseries_frequency'

        ]
        for field in fields:
            if field in self.common_result_columns:
                self.common_result_columns.remove(field)

        # Get saved field names
        self.saved_fields = [col.split('.')[1] for col in self.common_result_columns]

    def query_data(self):
        """
        Query the result.csvs if they do not already exist. Load queried or local data into memory.
        """
        print('Querying/Loading Data...')

        # Query/Load Base Table Data
        base_data_path = self.base_table_name

        print('  Loading %s Data...' % self.base_table_name)
        self.base_df = pd.read_csv(base_data_path)

        for col in self.base_df.columns.tolist():
            if not 'simulation_output_report' in col:
                continue
            self.base_df = self.base_df.rename(columns={col: col.split('.')[1]})

        # Query/Load Feature Table Data
        feature_data_path = self.feature_table_name

        print('  Loading %s Data...' % self.feature_table_name)
        self.feature_df = pd.read_csv(feature_data_path)

        for col in self.feature_df.columns.tolist():
            if not 'simulation_output_report' in col:
                continue
            self.feature_df = self.feature_df.rename(columns={col: col.split('.')[1]})

    def format_queried_data(self):
        """
        Format the queried data for plotting.
        """
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
        self.base_df = self.base_df.groupby(self.groupby).sum().reset_index()
        self.feature_df = self.feature_df.groupby(self.groupby).sum().reset_index()

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
        plt.xticks(ticks=[0, 1], labels=[os.path.basename(self.base_table_name), os.path.basename(self.feature_table_name)], rotation=30, ha='right')
        plt.title('Number of failures')
        plt.ylabel('Failures')

        output_path = os.path.join(os.path.dirname(self.base_table_name), 'figures', 'failures.png')
        plt.savefig(output_path, bbox_inches='tight')
        plt.close()

    def regression_scatterplots(self):
        """
        Scatterplot for each model type and simulation_outupt_report value.
        """
        # Copy DataFrames
        base_df = self.base_df.copy()
        feature_df = self.feature_df.copy()

        print('Plotting regression scatterplots...')
        model_types = ['Single-Family Detached', 'Single-Family Attached', 'Multi-Family']
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

                    fig.add_trace(go.Scatter(x=tmp_base_df[end_use], y=tmp_feature_df[end_use], marker=dict(size=10, color=colors[i]), mode='markers', name=end_use, legendgroup=end_use, showlegend=showlegend), row=1, col=col)

                fig.add_trace(go.Scatter(x=[min_value, max_value], y=[min_value, max_value], line=dict(color='black', dash='dash', width=0.5), mode='lines', showlegend=False), row=1, col=col)
                fig.update_xaxes(title_text=self.base_table_name, row=1, col=col)
                fig.update_yaxes(title_text=self.feature_table_name, row=1, col=col)

            fig['layout'].update(title=fuel_use, template='plotly_white')
            fig.update_layout(width=1800, height=600, autosize=False)
            output_path = os.path.join(os.path.dirname(self.base_table_name), 'figures', fuel_use + '.png')
            # plotly.offline.plot(fig, filename=output_path, auto_open=False) # html
            fig.write_image(output_path)


if __name__ == '__main__':

    # Inputs
    base_table_name = sys.argv[1]
    feature_table_name = sys.argv[2]
    groupby = [
        'build_existing_model.geometry_building_type_recs',  # Needed to split out by models
        # 'build_existing_model.county'  # Choose any other characteristic(s)
    ]

    # Initialize object
    results_csv_comparison = res_results_csv_comparisons(
        base_table_name=base_table_name,
        feature_table_name=feature_table_name,
        groupby=groupby
    )

    # Plot the number of failures for each run
    results_csv_comparison.plot_failures()

    # Generate scatterplots for each model type and simulation_output_report field
    results_csv_comparison.regression_scatterplots()
