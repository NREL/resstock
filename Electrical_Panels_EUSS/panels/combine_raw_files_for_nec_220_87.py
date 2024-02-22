"""
Inputs raw EUSS baseline and upgrade files (.csv or .parquet)
Outputs .parquet file meant to be further processed by electrical_panel_size_nec_220_87.py

"""

from pathlib import Path
import pandas as pd
import numpy as np


# --- important variables ---

# List of columns necessary for analysis with electrical_panel_size_nec_220_87 program.
relevant_input_columns = [
    'building_id',
    'build_existing_model.ashrae_iecc_climate_zone_2004_2_a_split',
    'build_existing_model.state', # NOT PART OF INITIAL DATASET, CREATED BY SPLITTING COUNTY COLUMN
    'build_existing_model.county',
    'build_existing_model.clothes_dryer',
    'build_existing_model.cooking_range',
    'build_existing_model.heating_fuel',
    'build_existing_model.water_heater_efficiency',
    'build_existing_model.water_heater_fuel',
    'build_existing_model.water_heater_in_unit',
    'qoi_report.qoi_peak_magnitude_use_kw',
    'upgrade_costs.size_heating_system_primary_k_btu_h',
    'upgrade_costs.size_heating_system_secondary_k_btu_h',
    'upgrade_costs.size_heat_pump_backup_primary_k_btu_h'
]

# List of columns that need to be renamed for each input file, as data changes from package to package.
    # (Same as relevant_input_columns but without building_id and location data.)
needs_renaming = [
    'qoi_report.qoi_peak_magnitude_use_kw',
    'upgrade_costs.size_heating_system_primary_k_btu_h',
    'upgrade_costs.size_heating_system_secondary_k_btu_h',
    'upgrade_costs.size_heat_pump_backup_primary_k_btu_h'
]

# Blank array (to be filled with dataframes)
list_of_df = []


# --- functions ---

def read_file(filename, low_memory = True):
    """ Turns parquet and csv into dataframes; if file is large, use low_memory = False """

    filename = Path(filename)

    if filename.suffix == ".csv":
        df = pd.read_csv(filename, low_memory = low_memory)
    elif filename.suffix == ".parquet":
        df = pd.read_parquet(filename)
    else:
        raise TypeError(f"Unsupported file type, cannot read file: {filename}")

    """ Same as read_file function from postprocess_electrical_panel_size_nec.py """
    return df

def determine_package_number(filename):
    """ Finds package number from the name of the file. """

    # Setup variables and dataframe name dictionary
    pkg_prefix = ""
    possible_file = {
        'results_up00.parquet': 'pkg_00.',
        'results_up01.parquet': 'pkg_01.',
        'results_up02.parquet': 'pkg_02.',
        'results_up03.parquet': 'pkg_03.',
        'results_up04.parquet': 'pkg_04.',
        'results_up05.parquet': 'pkg_05.',
        'results_up06.parquet': 'pkg_06.',
        'results_up07.parquet': 'pkg_07.',
        'results_up08.parquet': 'pkg_08.',
        'results_up09.parquet': 'pkg_09.',
        'results_up10.parquet': 'pkg_10.'}
    
    # Use dataframe name to determine package
    pkg_prefix = possible_file[filename]

    return pkg_prefix

def create_state_and_county_columns(dataframe):
    """ Split build_existing_model.county into two columns, one for state and one for county. """

    # Split current column into two
    new_columns = dataframe['build_existing_model.county'].str.split(
        pat = ', ',
        expand = True)
    
    # Add resulting dataframe of new columns back to old dataframe (state = new column, county = replaces column)
    dataframe.insert(2, "build_existing_model.state", new_columns[0], True)
    dataframe['build_existing_model.county'] = new_columns[1]
    
    return dataframe

def eliminate_irrelevant_columns(dataframe):
    """ Sort columns (eliminating extras) to those relevant for panel sizing and analysis. """

    return dataframe.loc[: , relevant_input_columns]

def rename_pkg_specific_columns(pkgprefix, dataframe):
    """ Renames columns that change from package to package so each one has a distinct place and is organized. """    

    # Add appropriate package prefix to the columns needing new names
    new_column_names = [pkgprefix + x for x in needs_renaming]

    # Create a dictionary of new and old names
    rename_dictionary = dict(zip(needs_renaming, new_column_names))

    # Rename appropriate columns using dictionary
    dataframe = dataframe.rename(
        mapper = rename_dictionary,
        axis = 1)

    return dataframe

def clean_up_data_files(filename, dataframe, low_memory = True):
    """ Combines previous functions to create a dataframe with only necessary columns, correctly named. """

    # Determine what package and create a dataframe from file
    pkg_prefix = determine_package_number(filename)
    # dataframe = read_file(filename, low_memory = low_memory)
    # If using read_file function, delete dataframe input from function.

    # Clean up dataframe columns.
    pddf = create_state_and_county_columns(dataframe)
    pddf = eliminate_irrelevant_columns(pddf)
    pddf = rename_pkg_specific_columns(pkg_prefix, pddf)

    # Return organized and appropriately named dataframe
    return (rename_pkg_specific_columns(pkg_prefix, pddf))

def save_dataframes_to_list(listname, dataframe, pkgprefix):
    """ Identify upgrade package, and create appropriately named dataframe from file. """

    if pkgprefix == "pkg_00.":
        pkg_00_df = dataframe
        listname.append(pkg_00_df)
    if pkgprefix == "pkg_01.":
        pkg_01_df = dataframe
        listname.append(pkg_01_df)
    if pkgprefix == "pkg_02.":
        pkg_02_df = dataframe
        listname.append(pkg_02_df)
    if pkgprefix == "pkg_03.":
        pkg_03_df = dataframe
        listname.append(pkg_03_df)
    if pkgprefix == "pkg_04.":
        pkg_04_df = dataframe
        listname.append(pkg_04_df)
    if pkgprefix == "pkg_05.":
        pkg_05_df = dataframe
        listname.append(pkg_05_df)
    if pkgprefix == "pkg_06.":
        pkg_06_df = dataframe
        listname.append(pkg_06_df)
    if pkgprefix == "pkg_07.":
        pkg_07_df = dataframe
        listname.append(pkg_07_df)
    if pkgprefix == "pkg_08.":
        pkg_08_df = dataframe
        listname.append(pkg_08_df)
    if pkgprefix == "pkg_09.":
        pkg_09_df = dataframe
        listname.append(pkg_09_df)
    if pkgprefix == "pkg_10.":
        pkg_10_df = dataframe
        listname.append(pkg_10_df)

    return listname

def combine_dataframes_into_one(listofdf):
    """ Input an array of dataframes from different packages, combine into one new dataframe without duplicate columns. """
    
    df = pd.concat(listofdf, axis = 1)
    df = df.loc[: , ~df.columns.duplicated()]

    return df

def export_dataframe_as_parquet(filename, location, dataframe):
    """ Turn finished dataframe into a parquet file setup to be plugged in to electrical_panel_size_nec_220_87.py. """

    results = f"{location}/{filename}"
    dataframe.to_parquet(results)

    return f"Export completed. Check {location} for {filename} to confirm."


def main():

    """
    TODO:
    - For analysis, create sorting functions. Could sort by:
        * Heating fuel type (electric, natural gas, propane, other)
        * Dwelling unit size (200 square foot increments?)
        * IECC Climate zone
        * State (for regional or national datasets)

    """

    # Open relevant files into dataframes
    pkg_00_file_path = "LOCATION/HERE/results_up00.parquet"
    pkg_02_file_path = "LOCATION/HERE/results_up02.parquet"
    pkg_07_file_path = "LOCATION/HERE/results_up07.parquet"
    pkg_08_file_path = "LOCATION/HERE/results_up08.parquet"

    df_00 = pd.read_parquet(pkg_00_file_path)
    df_02 = pd.read_parquet(pkg_02_file_path)
    df_07 = pd.read_parquet(pkg_07_file_path)
    df_08 = pd.read_parquet(pkg_08_file_path)

    # Tidy up relevant dataframes
    df_00 = clean_up_data_files('results_up00.parquet', df_00, low_memory = True)
    df_02 = clean_up_data_files('results_up02.parquet', df_02, low_memory = True)
    df_07 = clean_up_data_files('results_up07.parquet', df_07, low_memory = True)
    df_08 = clean_up_data_files('results_up08.parquet', df_08, low_memory = True)

    # Save smaller dataframes to a list
    save_dataframes_to_list(list_of_df, df_00, 'pkg_00.')
    save_dataframes_to_list(list_of_df, df_02, 'pkg_02.')
    save_dataframes_to_list(list_of_df, df_07, 'pkg_07.')
    save_dataframes_to_list(list_of_df, df_08, 'pkg_08.')
    
    # Combine dataframes into one and export final dataframe as a parquet file.
    final_df = combine_dataframes_into_one(list_of_df)
    export_dataframe_as_parquet('IL_220_87_input.parquet', 'LOCATION/HERE', final_df)

if __name__ == '__main__':
    main()
