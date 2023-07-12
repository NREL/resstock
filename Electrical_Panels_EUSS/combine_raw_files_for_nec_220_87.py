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
    'build_existing_model.county',
    'build_existing_model.heating_fuel',
    'qoi_report.qoi_peak_magnitude_use_kw']

# List of columns that need to be renamed for each input file, as data changes from package to package.
    # (Same as relevant_input_columns but without building_id and location data.)
needs_renaming = [
    'build_existing_model.heating_fuel',
    'qoi_report.qoi_peak_magnitude_use_kw']

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

def clean_up_data_files(filename, low_memory = True):
    """ Combines previous functions to create a dataframe with only necessary columns, correctly named. """

    # Determine what package and create a dataframe from file
    pkg_prefix = determine_package_number(filename)
    pddf = read_file(filename, low_memory = low_memory)

    # Clean up dataframe columns.
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

"""
TO DO:
- variables to sort by (for analysis)
    * Heating fuel type (electric, natural gas, propane, other)
    * Dwelling unit size (200 square foot boxes? may want to analyze further to determine box size)
    * IECC Climate zone
    * State
    * Make each category a function; function input is which option within that category you want to choose
    * Input option, get out a dataframe with ONLY that option (ie, study heating fuel type, input electric, get out all regions but only buildings w/ electric)
- main function down here
    * Find a good way to input multiple files (since it's needed to combine all relevant packages into one file)

"""
