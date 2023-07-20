"""
Electrical Panel Project: Estimate panel capacity using NEC 220.87 (2023)
- Focuses on leeway/slack (decrease in amperage) created by upgrade packages in EUSS data
- Compares this leeway to increases in amperage when new loads are added for electrification

By: Julia.Ehlers@nrel.gov
Date: 07/06/2023

--------------------

NEC 220.87 - Determining Existing Loads
  - Uses maximum demand data from a year to size service/electrical panel
  - Takes maximum demand (plus new load if applicable) times power factor 1.25 to find kVA of current load
  - Divide kVA value by 240 V to find panel amperage

kW = kVA * PF
  - kW: working/active power
  - kVA: apparent (active + reactive) power; used to size panel
  - PF: power factor; usually 0.8 for inductive load
  
Note: 1.25 comes from dividing both sides of above equation by 0.8.
To find panel size, take active power (from dataset) and multiply by 1.25 (or divide by its reciprocal, 0.8).

--------------------

OTHER NOTES:
- Baseline package data from input file starts with 'pkg_00.'
- All upgrade package data from input starts with 'pkg_##.' where ## is the package number (single digit, add a zero)
- Use 'combine_raw_files_for_nec_220_87.py' program to create an input file for this program

"""

import pandas as pd
import numpy as np
import math
from pathlib import Path


# --- basic panel sizing functions ---

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

def va_rating_from_peak_use(row, pkgnum):
    """
    Based on NEC 220.87 specifically
    - Pulls peak demand data from file (uses qoi_report.qoi_peak_magnitude_use_kw column)
    - Convert peak demand data from kW to VA (multiply by 1000)
    - Multiply by 1.25 (prevents load from passing 80% of panel capacity)
    - Note: baseline data is 'pkg_00'
    """

    demand_data = row[f'pkg_{pkgnum}.qoi_report.qoi_peak_magnitude_use_kw']

    return (demand_data * 1000 * 1.25)

def va_rating_to_panel_amperage(row, pkgnum):
    """ Assumes 120/240 V wiring; takes total VA and divides by 240V to find panel amperage """

    va_rating = va_rating_from_peak_use(row, pkgnum)

    return (va_rating / 240)

def determine_panel_sizing(row, pkgnum):
    """ Uses panel amperage value from va_rating_to_panel_amperage to select the best size panel """

    # Create list of panel sizes and determine the panel amperage of the row
    standard_panel_sizes = np.array([100, 125, 150, 200, 300, 400, 600])
    panel_amperage = va_rating_to_panel_amperage(row, pkgnum)

    if pd.isnull(panel_amperage):
        return np.nan

    # Variable factors >= 1 if panel size is big enough for given panel amperage
    factors = standard_panel_sizes / panel_amperage

    # Create a list of panel sizes big enough to accomodate panel amperage
    possible_panel_sizes = standard_panel_sizes[factors >= 1]

    # Find smallest possible panel size to accomodate panel amperage
    if len(possible_panel_sizes) == 0:
        # applies only if standard panel sizes are too small
        print(f"WARNING: {panel_amperage} is higher than the largest standard size. Check calculations.")
        return math.ceil(panel_amperage / 100) * 100

    # for all other cases    
    return possible_panel_sizes[0]

def amp_dif_two_packages(row, pkgnum1, pkgnum2):
    """ Difference (in amps) between two upgrade panel amperages; the first is treated as the 'baseline' """

    pkg1_amperage = va_rating_to_panel_amperage(row, pkgnum1)
    pkg2_amperage = va_rating_to_panel_amperage(row, pkgnum2)
    
    return (pkg2_amperage - pkg1_amperage)

def amp_dif_panel_size_and_amperage(row, pkgnum1, pkgnum2):
    """ Difference in amperage between the baseline panel size and panel amperage of a package """

    base_panel_size = determine_panel_sizing(row, pkgnum1)
    pkg2_amperage = va_rating_to_panel_amperage(row, pkgnum2)

    return (pkg2_amperage - base_panel_size)

def amp_percent_dif_two_packages(row, pkgnum1, pkgnum2):
    """ Percent difference between two upgrade panel amperages, the first is treated as the 'baseline' """

    pkg1_amperage = va_rating_from_peak_use(row, pkgnum1)
    difference = amp_dif_two_packages(row, pkgnum1, pkgnum2)

    return (difference / pkg1_amperage)

def amp_percent_dif_panel_size_and_amperage(row, pkgnum1, pkgnum2):
    """ Percent difference between baseline panel size and panel amperage of a package """

    base_panel_size = determine_panel_sizing(row, pkgnum1)
    difference = amp_dif_panel_size_and_amperage(row, pkgnum1, pkgnum2)

    return (difference / base_panel_size)


# --- appliance load functions ---

def add_low_efficiency_electric_heating(row):
    """
    Finds Volt-Amp rating of additional heating appliance.
    Adds a different heat pump depending on if the unit is ducted or ductless:
        - SEER 15, 9 HSPF centrally ducted heat pump, electric resistance backup heating
        - SEER 15, 9 HSPF ductless mini split, electric resistance backup heating
    This upgrade is part of package 7, so we use sizing data from that set.
    """

    # Check if dwelling unit has electric heating
    if row['build_existing_model.heating_fuel'] == 'Electricity':
        # Assume heating is already included in load, so additional load is zero
        return 0
    
    # Simplified version of _special_load_space_conditioning in postprocess_electrical_panel_size_nec.py
    # Intended to find the nameplate rating/nominal heating capacity of heating equipment
    kBTU_h_to_W = 293.07103866
    
    heating_cols = [
        row[f'pkg_07.upgrade_costs.size_heating_system_primary_k_btu_h'],
        row[f'pkg_07.upgrade_costs.size_heating_system_secondary_k_btu_h'],
        row[f'pkg_07.upgrade_costs.size_heat_pump_backup_primary_k_btu_h']]
    
    return sum(heating_cols) * kBTU_h_to_W # units: VA

def add_high_efficiency_electric_heating(row):
    """
    Finds Volt-Amp rating of additional heating appliance.
    Adds a different heat pump depending on if the unit is ducted or ductless:
        - SEER 24, 13 HSPF variable speed mini split heat pump, electric resistance backup heating
        - SEER 29.3, 14 HSPF variable speed mini split heat pump, electric resistance backup heating
    This upgrade is part of package 8, so we use sizing data from that set.
    """

    # Check if dwelling unit has electric heating
    if row['build_existing_model.heating_fuel'] == 'Electricity':
        # Assume heating is already included in load, so additional load is zero
        return 0
    
    # Simplified version of _special_load_space_conditioning in postprocess_electrical_panel_size_nec.py
    # Intended to find the nameplate rating/nominal heating capacity of heating equipment
    kBTU_h_to_W = 293.07103866
    
    heating_cols = [
        row[f'pkg_08.upgrade_costs.size_heating_system_primary_k_btu_h'],
        row[f'pkg_08.upgrade_costs.size_heating_system_secondary_k_btu_h'],
        row[f'pkg_08.upgrade_costs.size_heat_pump_backup_primary_k_btu_h']]
    
    return sum(heating_cols) * kBTU_h_to_W # units: VA

def add_electric_water_heating(row):
    """
    Finds Volt-Amp rating of additional electric water heating appliance.
    Adds a different unit depending on number of bedrooms:
        - 1-3 beds: 50 gallon, 3.45 UEF heat pump water heater
        - 4 beds: 66 gallon, 3.35 UEF heat pump water heater
        - 5+ beds: 80 gallon, 3.45 UEF heat pump water heater
    Water heating upgrade from packages 7 and 8 appears to be the same, so only one upgrade
    """

    if row['build_existing_model.water_heater_in_unit'] != "Yes":
        # Assumes apartment or multifamily dwelling unit, so water heater not necessary
        return 0
    
    electric_fuel = row['build_existing_model.water_heater_fuel'] == "Electricity"
    electric_efficiency = "Electric" in row['build_existing_model.water_heater_efficiency']

    if electric_fuel | electric_efficiency:
        # Assume water heating is already included in load, so additional load is zero
        return 0

    # Based on _fixed_load_water_heater function in postprocess_electrical_panel_size_nec.py:
    # All heat pump water heaters have nameplate rating of 5000 VA
    return 5000 # units: VA

def add_low_efficiency_clothes_dryer(row):
    """
    Finds Volt-Amp rating of additional low efficiency clothes dryer.
    Possible electrification unit specs:
        - Electric Clothes Dryer, 80% usage
        - Electric Clothes Dryer, 100% usage
        - Electric Clothes Dryer, 120% usage
    Clothes dryer upgrade is from package 7.
    """

    if row['build_existing_model.clothes_dryer'] == "None":
        # Assume multifamily building where clothes dryers are communal, upgrade unnecessary
        return 0
    
    if "Electric" in row['build_existing_model.clothes_dryer']:
        # Assume clothes dryer is already included in load, so additional load is zero
        return 0

    # Based on _special_load_electric_dryer function in postprocess_electrical_panel_size_nec.py:
    # All vented clothes dryers have nameplate rating of 5600 VA
    return 5600 # units: VA

def add_high_efficiency_clothes_dryer(row):
    """
    Finds Volt-Amp rating of additional high efficiency clothes dryer.
    Possible electrification unit specs:
        - Premium Electric Ventless Heat Pump Clothes Dryer, 80% usage
        - Premium Electric Ventless Heat Pump Clothes Dryer, 100% usage
        - Premium Electric Ventless Heat Pump Clothes Dryer, 120% usage
    Clothes dryer upgrade is from package 8.
    """

    if row['build_existing_model.clothes_dryer'] == "None":
        # Assume multifamily building where clothes dryers are communal, upgrade unnecessary
        return 0
    
    if "Electric" in row['build_existing_model.clothes_dryer']:
        # Assume clothes dryer is already included in load, so additional load is zero
        return 0

    # Based on _special_load_electric_dryer function in postprocess_electrical_panel_size_nec.py:
    # All ventless clothes dryers have nameplate rating of 5400 VA
    return 5400 # units: VA

def add_low_efficiency_cooking_range(row):
    """
    Finds Volt-Amp rating of additional low efficiency cooking range (combined oven and stovetop).
    Possible elecrification specs:
        - Electric Cooking Range, 80% Usage
        - Electric Cooking Range, 100% Usage
        - Electric Cooking Range, 120% Usage
    Cooking range upgrade is from package 7.
    """

    if "Electric" in row['build_existing_model.cooking_range']:
        # Assume cooking range is already included in load, so additional load is zero
        return 0

    # Based on _special_load_electric_dryer function in postprocess_electrical_panel_size_nec.py:
    # Electric, non-induction combination range and oven assumes 13.5 kW nameplate rating.
    return 13500 # units: VA

def add_high_efficiency_cooking_range(row):
    """
    Finds Volt-Amp rating of additional high efficiency cooking range (combined oven and stovetop).
    Possible elecrification specs:
        - Electric Induction Cooking Range, 80% Usage
        - Electric Induction Cooking Range, 100% Usage
        - Electric Induction Cooking Range, 120% Usage
    Cooking range upgrade is from package 8.
    """

    if "Electric" in row['build_existing_model.cooking_range']:
        # Assume cooking range is already included in load, so additional load is zero
        return 0

    # Based on _special_load_electric_dryer function in postprocess_electrical_panel_size_nec.py:
    # Electric, induction combination range and oven assumes 8.4 kW nameplate rating.
    return 8400  # units: VA

def panel_amperage_with_electrified_load(row, electricload, pkgnum):
    """ NEC 220.87: demand load at 125% plus given additional load
    Input options for 'electricload': lo_ef_heat, hi_ef_heat, h2o_heat, lo_ef_dryer, hi_ef_dryer, lo_ef_range, hi_ef_range """

    if electricload == "lo_ef_heat":
        demand = va_rating_from_peak_use(row, pkgnum)
        load = add_low_efficiency_electric_heating(row)
        return ( (demand + load) / 240) # units: Amps
    elif electricload == "hi_ef_heat":
        demand = va_rating_from_peak_use(row, pkgnum)
        load = add_high_efficiency_electric_heating(row)
        return ( (demand + load) / 240) # units: Amps
    elif electricload == "h2o_heat":
        demand = va_rating_from_peak_use(row, pkgnum)
        load = add_electric_water_heating(row)
        return ( (demand + load) / 240) # units: Amps
    elif electricload == "lo_ef_dryer":
        demand = va_rating_from_peak_use(row, pkgnum)
        load = add_low_efficiency_clothes_dryer(row)
        return ( (demand + load) / 240) # units: Amps
    elif electricload == "hi_ef_dryer":
        demand = va_rating_from_peak_use(row, pkgnum)
        load = add_high_efficiency_clothes_dryer(row)
        return ( (demand + load) / 240) # units: Amps
    elif electricload == "lo_ef_range":
        demand = va_rating_from_peak_use(row, pkgnum)
        load = add_low_efficiency_cooking_range(row)
        return ( (demand + load) / 240) # units: Amps
    elif electricload == "hi_ef_range":
        demand = va_rating_from_peak_use(row, pkgnum)
        load = add_low_efficiency_cooking_range(row)
        return ( (demand + load) / 240) # units: Amps
    else:
        print('Check function inputs.')
        return 0


# --- appliance analysis functions ---

def supports_heating(row, pkgnum, efficiency):
    """
    pkgnum = '##', efficiency = 'low' or 'high'
    Returns True, False or None depending on whether a heating load is supported by a package.
        - True: load is supported, stays under baseline panel capacity
        - False: load is NOT supported, exceeds baseline panel capacity
        - None: load does not apply to dwelling unit (upgrade isn't needed or is already electric)
    """

    # Define existing panel size, and amperage from demand and new load
    with_load = None
    panel_size = determine_panel_sizing(row, pkgnum)

    if efficiency == "low":
        with_load = panel_amperage_with_electrified_load(row, 'lo_ef_heat', pkgnum)
    if efficiency == "high":
        with_load = panel_amperage_with_electrified_load(row, 'hi_ef_heat', pkgnum)

    # Determine if load applies to dwelling unit
    if row['build_existing_model.heating_fuel'] == 'Electricity':
        return "None"

    # Determine if load is supported by upgrade
    if with_load <= panel_size:
        return "True"
    if with_load > panel_size:
        return "False"

    return "Error"
    
def supports_water_heating(row, pkgnum):
    """
    pkgnum = '##'
    Returns True, False or None depending on whether a water heating load is supported by a package.
        - True: load is supported, stays under baseline panel capacity
        - False: load is NOT supported, exceeds baseline panel capacity
        - None: load does not apply to dwelling unit (upgrade isn't needed or is already electric)
    """

    # Define existing panel size, and amperage from demand and new load
    with_load = panel_amperage_with_electrified_load(row, 'h2o_heat', pkgnum)
    panel_size = determine_panel_sizing(row, pkgnum)

    # Determine if load applies to dwelling unit
    no_h2o_heat = row['build_existing_model.water_heater_in_unit'] != "Yes"
    electric_fuel = row['build_existing_model.water_heater_fuel'] == "Electricity"
    electric_efficiency = "Electric" in row['build_existing_model.water_heater_efficiency']

    if no_h2o_heat | electric_fuel | electric_efficiency:
        return "None"

    # Determine if load is supported by upgrade
    if with_load <= panel_size:
        return "True"
    if with_load > panel_size:
        return "False"

    return "Error"

def supports_clothes_dryer(row, pkgnum, efficiency):
    """
    pkgnum = '##', efficiency = 'low' or 'high'
    Returns True, False or None depending on whether a clothes dryer load is supported by a package.
        - True: load is supported, stays under baseline panel capacity
        - False: load is NOT supported, exceeds baseline panel capacity
        - None: load does not apply to dwelling unit (upgrade isn't needed or is already electric)
    """

    # Define existing panel size, and amperage from demand and new load
    with_load = None
    panel_size = determine_panel_sizing(row, pkgnum)

    if efficiency == "low":
        with_load = panel_amperage_with_electrified_load(row, 'lo_ef_dryer', pkgnum)
    if efficiency == "high":
        with_load = panel_amperage_with_electrified_load(row, 'hi_ef_dryer', pkgnum)

    # Determine if load applies to dwelling unit
    dryer_dne = row['build_existing_model.clothes_dryer'] == "None"
    dryer_electric = "Electric" in row['build_existing_model.clothes_dryer']
    
    if dryer_dne | dryer_electric:
        return "None"
    
    # Determine if load is supported by upgrade
    if with_load <= panel_size:
        return "True"
    if with_load > panel_size:
        return "False"

    return "Error"

def supports_cooking_range(row, pkgnum, efficiency):
    """
    pkgnum = '##', efficiency = 'low' or 'high'
    Returns True, False or None depending on whether a cooking range load is supported by a package.
        - True: load is supported, stays under baseline panel capacity
        - False: load is NOT supported, exceeds baseline panel capacity
        - None: load does not apply to dwelling unit (upgrade isn't needed or is already electric)
    """

    # Define existing panel size, and amperage from demand and new load
    with_load = None
    panel_size = determine_panel_sizing(row, pkgnum)

    if efficiency == "low":
        with_load = panel_amperage_with_electrified_load(row, 'lo_ef_range', pkgnum)
    if efficiency == "high":
        with_load = panel_amperage_with_electrified_load(row, 'hi_ef_range', pkgnum)

    # Determine if load applies to dwelling unit
    if "Electric" in row['build_existing_model.cooking_range']:
        return "None"
    
    # Determine if load is supported by upgrade
    if with_load <= panel_size:
        return "True"
    if with_load > panel_size:
        return "False"

    return "Error"

def boolean_to_numbers(x):
    if x == "True":
        return 1
    else:
        return 0


def main():

    # Open data file
    # df = read_file('FILE NAME HERE', low_memory = True)
    df = pd.read_parquet('C:/Users/jehlers/Desktop/git/IL_220_87_input.parquet')


    # --- PANEL CAPACITY DATA ---

    # Find volt-amps rating and create columns containing data for each dwelling unit
    df['pkg_00.va_rating'] = df.apply(lambda x: va_rating_from_peak_use(x, '00'), axis = 1)
    df['pkg_02.va_rating'] = df.apply(lambda x: va_rating_from_peak_use(x, '02'), axis = 1)

    # Find panel amperage and create columns containing data for each dwelling unit
    df['pkg_00.panel_amperage'] = df.apply(lambda x: va_rating_to_panel_amperage(x, '00'), axis = 1)
    df['pkg_02.panel_amperage'] = df.apply(lambda x: va_rating_to_panel_amperage(x, '02'), axis = 1)

    # Find panel size and create columns with data for each dwelling unit
    df['pkg_00.220_87_panel_size'] = df.apply(lambda x: determine_panel_sizing(x, '00'), axis = 1)
    df['pkg_02.220_87_panel_size'] = df.apply(lambda x: determine_panel_sizing(x, '02'), axis = 1)

    # Analyze panel capacity difference between base and package
    df['00_and_02.amps_dif'] = df.apply(lambda x: amp_dif_two_packages(x, '00', '02'), axis = 1)
    df['00_and_02.amps_percent_dif'] = df.apply(lambda x: amp_percent_dif_two_packages(x, '00', '02'), axis = 1)

    # Analyze difference between base panel size and package amperage
    df['00_and_02.size_amps_dif'] = df.apply(lambda x: amp_dif_panel_size_and_amperage(x, '00', '02'), axis = 1)
    df['00_and_02.size_amps_percent_dif'] = df.apply(lambda x: amp_percent_dif_panel_size_and_amperage(x, '00', '02'), axis = 1)


    # --- APPLIANCE DATA ---

    # Analyze if heating is supported
    df['pkg_02.supports_low_efficiency_heat'] = df.apply(lambda x: supports_heating(x, '02', 'low'), axis = 1)
    df['pkg_02.supports_high_efficiency_heat'] = df.apply(lambda x: supports_heating(x, '02', 'high'), axis = 1)

    # Analyze if water heating is supported
    df['pkg_02.supports_water_heating'] = df.apply(lambda x: supports_water_heating(x, '02'), axis = 1)

    # Analyze if clothes dryer is supported
    df['pkg_02.supports_low_efficiency_dryer'] = df.apply(lambda x: supports_clothes_dryer(x, '02', 'low'), axis = 1)
    df['pkg_02.supports_high_efficiency_dryer'] = df.apply(lambda x: supports_clothes_dryer(x, '02', 'high'), axis = 1)

    # Analyze if cooking range is supported
    df['pkg_02.supports_low_efficiency_range'] = df.apply(lambda x: supports_cooking_range(x, '02', 'low'), axis = 1)
    df['pkg_02.supports_high_efficiency_range'] = df.apply(lambda x: supports_cooking_range(x, '02', 'high'), axis = 1)

    # TODO: Was not sure how to make the percentage analysis below into a function, but it should probably be one
    # Find percent supported in each county, start with empty dataframe
    geography = pd.DataFrame()

    # low efficiency heat
    df['numbers_lo_ef_heat'] = df['pkg_02.supports_low_efficiency_heat'].apply(boolean_to_numbers)
    geography['low_efficiency_heating'] = df.groupby('build_existing_model.county').numbers_lo_ef_heat.sum() / df['build_existing_model.county'].value_counts() * 100

    # high efficiency heat
    df['numbers_hi_ef_heat'] = df['pkg_02.supports_high_efficiency_heat'].apply(boolean_to_numbers)
    geography['high_efficiency_heating'] = df.groupby('build_existing_model.county').numbers_hi_ef_heat.sum() / df['build_existing_model.county'].value_counts() * 100

    # water heating
    df['numbers_h2o_heat'] = df['pkg_02.supports_water_heating'].apply(boolean_to_numbers)
    geography['water_heating'] = df.groupby('build_existing_model.county').numbers_h2o_heat.sum() / df['build_existing_model.county'].value_counts() * 100

    # low efficiency dryer
    df['numbers_lo_ef_dryer'] = df['pkg_02.supports_low_efficiency_dryer'].apply(boolean_to_numbers)
    geography['low_efficiency_dryer'] = df.groupby('build_existing_model.county').numbers_lo_ef_dryer.sum() / df['build_existing_model.county'].value_counts() * 100

    # high efficiency dryer
    df['numbers_hi_ef_dryer'] = df['pkg_02.supports_high_efficiency_dryer'].apply(boolean_to_numbers)
    geography['high_efficiency_dryer'] = df.groupby('build_existing_model.county').numbers_hi_ef_dryer.sum() / df['build_existing_model.county'].value_counts() * 100

    # low efficiency range
    df['numbers_lo_ef_range'] = df['pkg_02.supports_low_efficiency_range'].apply(boolean_to_numbers)
    geography['low_efficiency_range'] = df.groupby('build_existing_model.county').numbers_lo_ef_range.sum() / df['build_existing_model.county'].value_counts() * 100

    # high efficiency range
    df['numbers_hi_ef_range'] = df['pkg_02.supports_high_efficiency_range'].apply(boolean_to_numbers)
    geography['high_efficiency_range'] = df.groupby('build_existing_model.county').numbers_hi_ef_range.sum() / df['build_existing_model.county'].value_counts() * 100
    
    
    # Export .csv file with results
    df.to_csv('C:/Users/jehlers/Desktop/panel_sizing_results.csv')
    geography.to_csv('C:/Users/jehlers/Desktop/supported_electrification_results.csv')

       
    
    # REVIEW AND DELETE SECTION BELOW

    """
    TODO:
    * Create a function to find individual loads of commonly electrified appliances
        - Already created: heating, water heating, cooking range, clothes dryer
        - Other ideas: EV charger, fireplace, grill, gas lighting, pool heater, hot tub/spa heater
        - Note that the functions that have been created may need to be updated - load sizing is not necessarily super accurate
    * Create a function to analyze appliances by geography (county or state)

    """

if __name__ == "__main__":
    main()    
