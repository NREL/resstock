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

"""

import pandas as pd
import numpy as np
import math
from pathlib import Path

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

def va_rating_from_peak_use_base(row):
    """
    Based on NEC 220.87 specifically
    - Pulls peak demand data from file (uses qoi_report.qoi_peak_magnitude_use_kw column)
    - Convert peak demand data from kW to VA (multiply by 1000)
    - Multiply by 1.25 (prevents load from passing 80% of panel capacity)
    """

    demand_data = row['base.qoi_report.qoi_peak_magnitude_use_kw']

    return (demand_data * 1000 * 1.25)

def va_rating_from_peak_use_package(row, pkgnum):
    """
    Works the same as 'va_rating_from_peak_use_base.' Differences below:
    - Needs a second input (upgrade number in the format '##') so it can find the correct data column
    - Having a function for the baseline and for upgrades makes it simpler to compare the two
    """

    demand_data = row[f'pkg_{pkgnum}.qoi_report.qoi_peak_magnitude_use_kw']

    return (demand_data * 1000 * 1.25)

def va_rating_to_panel_amperage_base(row):
    """ Assumes 120/240 V wiring; takes total VA and divides by 240V to find panel amperage """

    va_rating = va_rating_from_peak_use_base(row)

    return (va_rating / 240)

def va_rating_to_panel_amperage_package(row, pkgnum):
    """ Assumes 120/240 V wiring; takes total VA and divides by 240V to find panel amperage """

    va_rating = va_rating_from_peak_use_package(row, pkgnum)

    return (va_rating / 240)

def amperage_difference_base_and_upgrade(row, pkgnum):
    """ Difference (in amps) between the baseline panel amperage and chosen upgraded panel amperage """

    base_amperage = va_rating_to_panel_amperage_base(row)
    pkg_amperage = va_rating_to_panel_amperage_package(row, pkgnum)

    return (pkg_amperage - base_amperage)

def amperage_difference_two_upgrades(row, pkgnum1, pkgnum2):
    """ Difference (in amps) between two upgrade panel amperages; the first is treated as the 'baseline' """

    pkg1_amperage = va_rating_to_panel_amperage_package(row, pkgnum1)
    pkg2_amperage = va_rating_to_panel_amperage_package(row, pkgnum2)
    
    return (pkg2_amperage - pkg1_amperage)

def amperage_percent_difference_base_and_upgrade(row, pkgnum):
    """ Percent difference between baseline panel amperage and chosen upgraded panel amperage """

    base_amperage = va_rating_to_panel_amperage_base(row)
    difference = amperage_difference_base_and_upgrade(row, pkgnum)

    return (difference / base_amperage)

def amperage_percent_difference_two_upgrades(row, pkgnum1, pkgnum2):
    """ Percent difference between two upgrade panel amperages, the first is treated as the 'baseline' """

    pkg1_amperage = va_rating_from_peak_use_package(row, pkgnum1)
    difference = amperage_difference_two_upgrades(row, pkgnum1, pkgnum2)

    return (difference / pkg1_amperage)

def main():

    """
    TO DO:
    - Debug and test functions that are already written
    - Write functions for the following:
        * Finding individual loads/amperages of commonly electrified appliances
            - Common: heating (and ac?), water heating, cooking range, clothes dryer, maybe electric vehicle charger
            - Uncommon: fireplace, grill, gas lighting, pool heater, hot tub/spa heater
        * Finding total loads (from peak demand data of upgrade or baseline plus any additional loads being tested)
        * Reading and condensing/simplifying data files (??)
        * Comparing decrease in amperage (from upgrades) to increase in amperage (from electrified appliances)
    - Code main function/section with other functions to analyze EUSS data

    """

if __name__ == "__main__":
    main()    

