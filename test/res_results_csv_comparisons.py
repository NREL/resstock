"""
# Residential results.csv comparisons.
- - - - - - - - -
A class to compare two resstock runs and the resulting differences in the results.csv.

**Authors:**

- Anthony Fontanini (Anthony.Fontanini@nrel.gov)
"""

# Import Modules
import os, sys
# import boto3
# import logging
import numpy as np
import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt
# from eulpda.smart_query.EULPAthena import EULPAthena

# Plot theme
# sns.set_theme()
# sns.set(font_scale=1.5)

# Create logger for AWS queries
# logging.basicConfig(level=logging.INFO)
# logger = logging.getLogger(__name__)


class res_results_csv_comparisons:
    def __init__(self, base_table_name, feature_table_name, groupby):
        """
        A class to query Athena and compare a baseline ResStock run to a new feature ResStock run. \
        The comparisons are performed on the results.csv from each run
        Args:
            base_table_name (string): The name of the baseline table to query on AWS Athena.
            feature_table_name (string): The name of the new feature table to query on AWS Athena.
            groupby (list[str]): List of characteristics to query and group by.
        """

        # Initialize members
        # Constants
        self.base_table_name = base_table_name
        self.feature_table_name = feature_table_name
        self.groupby = groupby

        # Create output directories
        self.create_output_directories()

        self.baseline_athena = None
        if not os.path.exists(self.base_table_name):
            # Initialize EULPAthena object for queries
            self.baseline_athena = EULPAthena(
                workgroup='eulp',
                db_name='enduse',
                buildstock_type='resstock',
                table_name=self.base_table_name
            )

        self.feature_athena = None
        if not os.path.exists(self.feature_table_name):
            self.feature_athena = EULPAthena(
                workgroup='eulp',
                db_name='enduse',
                buildstock_type='resstock',
                table_name=self.feature_table_name
            )

        if self.baseline_athena or self.feature_athena:
            # Initialize s3 client
            self.s3_client = boto3.client('s3')

        # Get fields
        self.get_common_output_fields()

        # Download data or load into memory
        self.query_data()

        # Format queried data
        self.format_queried_data()

    def create_output_directories(self):
        """Create output directories for the figures and queried data."""
        # Directory for the queried data
        # create_path = os.path.join(
            # 'resstock_data'
        # )
        # if not os.path.exists(create_path):
            # os.makedirs(create_path)

        # Directory for the queried data
        create_path = os.path.join(os.path.dirname(self.base_table_name), 'figures')
        if not os.path.exists(create_path):
            os.makedirs(create_path)

    def get_common_output_fields(self):
        """Get the common output fields for comparison."""
        print('Getting Common Fields...')

        if self.baseline_athena or self.feature_athena:
            # Get base table fields
            query = 'SHOW COLUMNS IN enduse.%s_baseline' % self.base_table_name
            result = self.baseline_athena.execute(query)
            self.base_fields = list(result[result.columns.values[0]])
            self.base_fields.append(result.columns.values[0])

            # Get feature table fields
            query = 'SHOW COLUMNS IN enduse.%s_baseline' % self.feature_table_name
            result = self.feature_athena.execute(query)
            self.feature_fields = list(result[result.columns.values[0]])
            self.feature_fields.append(result.columns.values[0])
        else:
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
        """Query the result.csvs if they do not already exist. Load queried or local data into memory."""
        print('Querying/Loading Data...')

        # Query/Load Base Table Data
        if self.baseline_athena:
            base_data_path = os.path.join(
                'resstock_data',
                self.base_table_name + '.csv'
            )
        else:
            base_data_path = self.base_table_name

        if not os.path.exists(base_data_path):
            print('  Querying %s Data...' % self.base_table_name)
            os.makedirs('resstock_data', exist_ok=True)

            self.base_df = self.baseline_athena.aggregate_annual(
                enduses=self.common_result_columns,
                group_by=self.groupby
            )

            self.base_df.dropna(inplace=True)
            self.base_df.to_csv(base_data_path, index=False)
        else:
            print('  Loading %s Data...' % self.base_table_name)
            self.base_df = pd.read_csv(base_data_path)

            if not self.baseline_athena:
                for col in self.base_df.columns.tolist():
                    if not 'simulation_output_report' in col:
                        continue
                    self.base_df = self.base_df.rename(columns={col: col.split('.')[1]})

        # Query/Load Feature Table Data
        if self.feature_athena:
            feature_data_path = os.path.join(
                'resstock_data',
                self.feature_table_name + '.csv'
            )
        else:
            feature_data_path = self.feature_table_name

        if not os.path.exists(feature_data_path):
            print('  Querying %s Data...' % self.feature_table_name)
            os.makedirs('resstock_data', exist_ok=True)

            self.feature_df = self.feature_athena.aggregate_annual(
                enduses=self.common_result_columns,
                group_by=self.groupby
            )

            self.feature_df.dropna(inplace=True)
            self.feature_df.to_csv(feature_data_path, index=False)
        else:
            print('  Loading %s Data...' % self.feature_table_name)
            self.feature_df = pd.read_csv(feature_data_path)

            if not self.feature_athena: 
                for col in self.feature_df.columns.tolist():
                    if not 'simulation_output_report' in col:
                        continue
                    self.feature_df = self.feature_df.rename(columns={col: col.split('.')[1]})

    def shift_central_system_energy(self, base_df, feature_df):
        """
        This function removes the central system energy from the feature_df that is in the base_df.
        Args:
            base_df (pandas.core.dataframe): Baseline DataFrame with central system energy
            feature_df (pandas.core.dataframe): Feature DataFrame that needs the central system energy removed
        """
        # Electricity
        feature_df['electricity_cooling_kwh'] -= base_df['electricity_central_system_cooling_kwh']
        feature_df['electricity_heating_kwh'] -= base_df['electricity_central_system_heating_kwh']

        # Fuel Oil
        feature_df['fuel_oil_heating_mbtu'] -= base_df['fuel_oil_central_system_heating_mbtu']

        # Natural Gas
        feature_df['natural_gas_heating_therm'] -= base_df['natural_gas_central_system_heating_therm']

        # Propane
        feature_df['propane_heating_mbtu'] -= base_df['propane_central_system_heating_mbtu']

        return feature_df

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

    def plot_failures(self, n_expected_baseline, n_expected_feature, show_plot=False):
        """
        Bar chart of the number of failures.
        Args:
            n_expected_baseline (int): The number of simulations expected in the baseline run.
            n_expected_feature (int): The number of simulations expected in the feature run.
            show_plots (bool): True if in notebook, false if in command line.
        """
        # Calculate the number of failures
        n_base = n_expected_baseline - self.base_df['raw_count'].sum()
        n_feature = n_expected_feature - self.feature_df['raw_count'].sum()
        print('Plotting number of failures...')
        print('  Failures %s: %d' % (self.base_table_name, n_base))
        print('  Failures %s: %d' % (self.feature_table_name, n_feature))

        # Figure
        plt.bar([0, 1], [n_base, n_feature])
        plt.xlim([-1, 2])
        plt.ylim([0, 1.2 * np.max([n_base, n_feature])])
        plt.xticks(ticks=[0, 1], labels=[self.base_table_name, self.feature_table_name], rotation=30, ha='right')
        plt.title('Number of failures')
        plt.ylabel('Failures')

        output_path = os.path.join(
            'figures',
            'failures.png'
        )
        plt.savefig(output_path, bbox_inches='tight')
        if show_plot:
            plt.show()
        plt.close()

    def regression_scatterplots(self, per_unit_tf, show_plots=False, shift_central_system_energy=False):
        """
        Scatterplot for each model type and simulation_outupt_report value.
        Args:
            per_unit_tf (bool): True if the scatterplots are to be per unit values, false if totals
            show_plots (bool): True if in notebook, false if in command line.
            shift_central_system_energy (bool): Shift central system energy from baseline to feature
        """
        # Copy DataFrames
        base_df = self.base_df.copy()
        feature_df = self.feature_df.copy()

        # Remove Central System Energy From Feature if desired
        if shift_central_system_energy:
            feature_df = shift_central_system_energy(base_df, feature_df)

        print('Plotting regression scatterplots...')
        model_types = ['Single-Family Detached', 'Single-Family Attached', 'Multi-Family']
        for col in self.saved_fields:
            fig, ax = plt.subplots(1, 3, figsize=(15, 5))
            i = 0
            for model_type in model_types:
                # Get model specific data
                btype_col = 'build_existing_model.geometry_building_type_recs'
                tmp_base_df = base_df.loc[base_df[btype_col] == model_type, :]
                tmp_base_df.set_index(self.groupby, inplace=True)
                tmp_feature_df = feature_df.loc[feature_df[btype_col] == model_type, :]
                tmp_feature_df.set_index(self.groupby, inplace=True)

                # Make all simulation_output_report values per unit
                if per_unit_tf:
                    tmp_base_df[col] = tmp_base_df[col] / tmp_base_df['scaled_unit_count']
                    tmp_feature_df[col] = tmp_feature_df[col] / tmp_feature_df['scaled_unit_count']

                # Scatterplot
                ax[i].scatter(tmp_base_df[col], tmp_feature_df[col])

                # Equal line
                max_value = 1.1 * np.max([tmp_base_df[col].max(), tmp_feature_df[col].max()])
                min_value = 0.9 * np.min([tmp_base_df[col].min(), tmp_feature_df[col].min()])
                ax[i].plot([min_value, max_value], [min_value, max_value], '-k')

                # Labels
                ax[i].set_xlabel(self.base_table_name)
                ax[i].set_ylabel(self.feature_table_name)
                ax[i].set_title("%s\n%s" % (model_type, col))
                i += 1
            plt.tight_layout()
            output_path = os.path.join(os.path.dirname(self.base_table_name), 'figures', col + '.png')
            plt.savefig(output_path, bbox_inches='tight')
            if show_plots:
                plt.show()
            plt.close()


if __name__ == '__main__':

    # Inputs
    base_table_name = sys.argv[1]
    feature_table_name = sys.argv[2]
    groupby = [
        'build_existing_model.geometry_building_type_recs',  # Needed to split out by models
        'build_existing_model.county'  # Choose any other characteristic(s)
    ]

    # Initialize object
    results_csv_comparison = res_results_csv_comparisons(
        base_table_name=base_table_name,
        feature_table_name=feature_table_name,
        groupby=groupby
    )

    # Plot the number of failures for each run
    n_expected = 550000
    if not os.path.exists(base_table_name) and not os.path.exists(feature_table_name):
        results_csv_comparison.plot_failures(
            n_expected_baseline=n_expected,
            n_expected_feature=n_expected,
        )

    # Generate scatterplots for each model type and simulation_output_report field
    results_csv_comparison.regression_scatterplots(
        per_unit_tf=False,
        show_plots=False,
        shift_central_system_energy=False
    )
