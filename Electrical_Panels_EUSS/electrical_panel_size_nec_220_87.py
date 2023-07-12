"""
Electrical Panel Project: Estimate panel capacity using NEC 220.87 (2023)
- Focuses on leeway (decrease in amperage) created by upgrade packages in EUSS data
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

OTHER NOTES:
- Baseline package data from input file starts with 'pkg_00.'
- All upgrade package data from input starts with 'pkg_##.' where ## is the package number (single digit add a zero)

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

def amperage_difference_two_packages(row, pkgnum1, pkgnum2):
    """ Difference (in amps) between two upgrade panel amperages; the first is treated as the 'baseline' """

    pkg1_amperage = va_rating_to_panel_amperage(row, pkgnum1)
    pkg2_amperage = va_rating_to_panel_amperage(row, pkgnum2)
    
    return (pkg2_amperage - pkg1_amperage)

def amperage_percent_difference_two_packages(row, pkgnum1, pkgnum2):
    """ Percent difference between two upgrade panel amperages, the first is treated as the 'baseline' """

    pkg1_amperage = va_rating_from_peak_use(row, pkgnum1)
    difference = amperage_difference_two_packages(row, pkgnum1, pkgnum2)

    return (difference / pkg1_amperage)

# --- appliance analysis functions ---

def main():

    # Open data file
    df = read_file('FILE NAME HERE')
    df = pd.read_csv('FILE LOCATION HERE')

    # Find volt-amps rating and create columns containing data for each dwelling unit
    df['pkg_00.va_rating'] = df.apply(lambda x: va_rating_from_peak_use(x, '00'), axis = 1)
    df['pkg_02.va_rating'] = df.apply(lambda x: va_rating_from_peak_use(x, '02'), axis = 1)

    # Find panel capacity rating and create columns containing data for each dwelling unit
    df['pkg_00.panel_capacity'] = df.apply(lambda x: va_rating_to_panel_amperage(x, '00'), axis = 1)
    df['pkg_02.panel_capacity'] = df.apply(lambda x: va_rating_to_panel_amperage(x, '02'), axis = 1)

    # Analyze panel capacity difference between base and package
    df['00_and_02.amps_difference'] = df.apply(lambda x: amperage_difference_two_packages(x, '00', '02'), axis = 1)
    df['00_and_02.amps_percent_dif'] = df.apply(lambda x: amperage_percent_difference_two_packages(x, '00', '02'), axis = 1)

    # Export .csv file with results
    df.to_csv('FINAL LOCATION HERE')

    """

    # Need to open file into a dataframe to begin with
    # Figure out how to plug a dataframe into a function and get out a new column???

    TO DO:
    - Debug and test functions that are already written
    - Write functions for the following:
        * Finding individual loads/amperages of commonly electrified appliances
            - Common: heating (and ac?), water heating, cooking range, clothes dryer, maybe electric vehicle charger
            - Uncommon: fireplace, grill, gas lighting, pool heater, hot tub/spa heater
        * Finding total loads (from peak demand data of upgrade or baseline plus any additional loads being tested)
        * Comparing decrease in amperage (from upgrades) to increase in amperage (from electrified appliances)
        * Converting panel amperage into panel sizing
    - Code 'main' with other functions to analyze EUSS data

    """

if __name__ == "__main__":
    main()    
