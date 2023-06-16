"""
Purpose: 
Estimate energy savings using EUSS 2018 AMY results
Results available for download as a .csv here:
https://data.openei.org/s3_viewer?bucket=oedi-data-lake&prefix=nrel-pds-building-stock%2Fend-use-load-profiles-for-us-building-stock%2F2022%2Fresstock_amy2018_release_1%2Fmetadata_and_annual_results%2Fnational%2Fcsv%2F

Estimate average energy savings by state and by technology improvement
All by Census Regions for 8 figure, Fact Sheets
State excludes Hawaii and Alaska, Tribal lands, and territories

Technology improvements are gradiented
More information can be found here:
https://oedi-data-lake.s3.amazonaws.com/nrel-pds-building-stock/end-use-load-profiles-for-us-building-stock/2022/EUSS_ResRound1_Technical_Documentation.pdf

Need to run resStock estimation environment

Created by: Katelyn.Stenger@nrel.gov
Created on: June 16, 2023
"""
"""
4 end use technologies and their savings are pulled for IRA:
-   Basic enclosure: all (pkg 1)
-   Heat pump – min eff + existing backup: all (pkg 5)
-   Heat pump – high eff: all (pkg 4)
-   Heat pump – high eff + basic enclosure: Heating & Cooling (pkg 9)

"""

# import packages
from pathlib import Path
import sys
import numpy as np
import pandas as pd
import csv

from add_ami_to_euss_results import add_ami_column_to_file


### Helper settings
conversion_factors = {
    "electricity": 1,  # to kWh
    "fuel_oil": 1 / 293.0710701722222,  # to mmbtu
    "natural_gas": 1 / 29.307107017222222,  # therm
    "propane": 1 / 293.0710701722222,  # to mmbtu
    "site_energy": 1 / 293.0710701722222,  # to mmbtu
}
converted_units = {
    "electricity": "kwh",
    "fuel_oil": "mmbtu",
    "natural_gas": "therm",
    "propane": "mmbtu",
    "site_energy": "mmbtu",
}

ci_multipliers = {
    "50%CI": 0.67449,
    "75%CI": 1.15035,
    "90%CI": 1.64485,
    "95%CI": 1.95996,
    "99%CI": 2.57583,
}


class CensusFactSheets:
    def __init__(
        self, euss_dir, groupby_cols, coarsening_map, emission_type, output_dir=None
    ):

        print(
            "========================================================================="
        )
        print(
            f"""
            Analysis for 2022 Inflation Reduction Act (IRA) using EUSS Round 1 summary files.
            """
        )
        print(
            "========================================================================="
        )
        print(
            f"Energy/savings are grouped by: {groupby_cols}\nwith coarsening_map: {coarsening_map}"
        )

        # initialize
        self.groupby_cols = groupby_cols
        self.coarsening_map = coarsening_map
        self.emission_type = emission_type
        self.euss_dir = self.validate_euss_directory(euss_dir)
        self.data_dir = Path(__file__).resolve().parent / "data"
        self.output_dir = self.validate_output_directory(output_dir)

    @staticmethod
    def validate_output_directory(output_dir):
        if output_dir is None:
            output_dir = Path(__file__).resolve().parent / "output_state_1980_022723"
        else:
            output_dir = Path(output_dir)
        output_dir.mkdir(parents=True, exist_ok=True)
        print(f"Analysis output will be exported to: {output_dir}")
        return output_dir

    @staticmethod
    def validate_euss_directory(euss_dir):
        euss_dir = Path(euss_dir)
        if not euss_dir.exists():
            print(f"Cannot find EUSS data folder:\n{euss_dir}")
            print(
                "EUSS data can be downloaded from "
                "https://data.openei.org/s3_viewer?bucket=oedi-data-lake&prefix=nrel-pds-building-stock%2Fend-use-load-profiles-for-us-building-stock%2F2022%2Fresstock_amy2018_release_1%2Fmetadata_and_annual_results%2Fnational%2Fcsv%2F"
            )
            sys.exit(1)
        print(f"EUSS input files: {euss_dir}")
        return euss_dir

    def add_ami_to_euss_files(self):
        for file_path in self.euss_dir.iterdir():
            if file_path.suffix != ".csv":
                continue
            with open(file_path, newline="") as f:
                reader = csv.reader(f)
                columns = next(reader)  # gets the first line
                # NOTE: Overwriting for first run
                if "in.area_median_income" not in columns:
                    add_ami_column_to_file(file_path)  # modify file in-place


# TODO: create figures for each Census Region

# Figure 1: Applicably households with bill increases by upgrade (bar graph)
# Figure 2: Average bill savings by heating fuel and upgrade type (bar graph)
# Figure 3: Distribution of bill impacts by upgrade type (scateter plot or bar graph?)
# Table 1: min and max utility bills for electricity and natural gas by state in census region by upgrade
# Figure 4: total household by cooling type (Y/N) and if they had bill savings (T/F) by upgrade
# Figure 5: Average utility bill savings by cooling type by upgrade
# Figure 6: Percentage of heating by income and vintage (Percent bar graph) (baseline)
# Figure 7: Percentage of cooling access by tenure and income (baselin)



###### main ######

# calculated unit count, rep unit count, consumption by fuel, carbon emission

def main(euss_dir):

    ### Upgrade settings
    emission_type = (
        "lrmer_low_re_cost_25_2025_start"  # <---- least controversial approach
    )

    groupby_cols = [
        "build_existing_model.census_division"
        # "in.state",
        # #"in.county", 
        # "vintage_filter", 
        # "city", 
        # "in.heating_fuel",
        # "building_type",
        # "in.tenure",
        # "AMI",  # "AMI", "FPL"
        # "in.building_america_climate_zone", # BA Climate Zone
        # "cooling",# TODO: need to test, new feature
        # "washing_machine", #TODO: need to test, new feature
    ]

    coarsening_map = {"in.state": "in.ashrae_iecc_climate_zone_2004_2_a_split"}

    # Initialize
    IRA = CensusFactSheets(euss_dir, groupby_cols, coarsening_map, emission_type)

    # Pre-process:
    IRA.add_ami_to_euss_files()

    ## Set control variables
    coarsening = False # <--- # whether to use coarsening_map
    as_percentage = True  # <--- # whether to calculate savings as pct

    print(f"coarsening = {coarsening}")
    print(f"as_percentage = {as_percentage}")

    # [0] get baseline consumption
    IRA.get_baseline_consumption(0, 
    "baseline_consumption", coarsening=coarsening)

    # [1] Basic enclosure: all (pkg 1)
    IRA.get_baseline_consumption(
        1, "basic_enclosure_upgrade", coarsening=coarsening
    )
    
    # NOTE: new feature; create a baseline dataframe using bldg id that are applicable in the upgrade
    IRA.get_baseline_for_upgrade(
      1, "basic_enclosure_baseline", coarsening=coarsening
    )

    # [2] Heat pump – high eff: all (pkg 4)
    IRA.get_baseline_consumption(
        4,
        "heat_pump_high_eff_with_electric_backup",
        coarsening=coarsening,
    )

    IRA.get_baseline_for_upgrade(
        4,
        "heat_pump_high_eff_with_electric_backup",
        coarsening=coarsening,
    )

    # [3] Heat pump – min eff + existing backup: all (pkg 5)
    IRA.get_baseline_consumption(
        5,
        "heat_pump_min_eff_with_existing_backup",
        coarsening=coarsening,
    )

    IRA.get_baseline_for_upgrade(
        5,
        "heat_pump_min_eff_with_existing_backup",
        coarsening=coarsening,
    )

    # [4] Heat pump – high eff + basic enclosure: Heating & Cooling (pkg 9)
    IRA.get_consumption_heating_and_cooling(
        9,
        "heat_pump_high_eff_with_basic_enclosure",
        coarsening=coarsening,
    )
    
    # NOTE: needs revision for partial upgrade
    IRA.get_baseline_for_upgrade(
        9,
        "heat_pump_high_eff_with_basic_enclosure",
        coarsening=coarsening,
    )
    
    #####################################


if __name__ == "__main__":

    if len(sys.argv) == 2:
        euss_dir = sys.argv[1]
    elif len(sys.argv) == 1:
        # set working directory if no path is provided
        euss_dir = Path("/Users/kstenger/Documents/c. IRA_Estimation/EUSS data/data")  
        # NOTE: ADJUST to your own default
    else:
        print(
            """
            usage: python IRA_StateLevelSavings.py [optional] <path_to_downloaded_euss_round1_sightglass_files>
            check code for default path_to_downloaded_euss_round1_sightglass_files
            """
        )
        sys.exit(1)

    main(euss_dir)
