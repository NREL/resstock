"""
Purpose: 
Estimate energy savings using EUSS 2018 AMY results
Results available for download as a .csv here:
https://data.openei.org/s3_viewer?bucket=oedi-data-lake&prefix=nrel-pds-building-stock%2Fend-use-load-profiles-for-us-building-stock%2F2022%2Fresstock_amy2018_release_1%2Fmetadata_and_annual_results%2Fnational%2Fcsv%2F

Estimate average energy savings by state and by technology improvement
State excludes Hawaii and Alaska, Tribal lands, and territories
Technology improvements are gradiented by 10 options
More information can be found here:
https://oedi-data-lake.s3.amazonaws.com/nrel-pds-building-stock/end-use-load-profiles-for-us-building-stock/2022/EUSS_ResRound1_Technical_Documentation.pdf

Created by: Katelyn Stenger @NREL
Created on: Oct 4, 2022
"""

"""
Savings to pull for IRA:
-   Basic enclosure: all (pkg 1)
-   Enhanced enclosure: all (pkg 2)
-   Heat pump – min eff + existing backup: all (pkg 5)
-   Heat pump – min eff: all (pkg 3)
-   Heat pump – high eff: all (pkg 4)
-   Heat pump – high eff + basic enclosure: Heating & Cooling (pkg 9)
-   Heat pump – high eff + enhanced enclosure: Heating & Cooling (pkg 10)
-   Heat pump water heater: all (pkg 6)
-   Electric dryer: Clothes dryer (pkg 7)
-   Heat pump dryer: Clothes dryer (pkg 8, 9, 10)
-   Electric cooking: Cooking (pkg 7)
-   Induction cooking: Cooking (pkg 8, 9, 10)

"""

#import packages
from pathlib import Path
import sys
import numpy as np
import pandas as pd

from add_ami_to_euss_results import add_ami_column_to_file

#set working directory
euss_dir = Path("/Volumes/Lixi_Liu/euss")
data_dir = Path(__file__).resolve().parent / "data"
output_dir = Path(__file__).resolve().parent / "output_by_technology"
output_dir.mkdir(parents=True, exist_ok=True)

if not euss_dir.exists():
    print(f"Cannot find EUSS data folder:\n{euss_dir}")
    print(
        "EUSS data can be downloaded from "
        "https://data.openei.org/s3_viewer?bucket=oedi-data-lake&prefix=nrel-pds-building-stock%2Fend-use-load-profiles-for-us-building-stock%2F2022%2Fresstock_amy2018_release_1%2Fmetadata_and_annual_results%2Fnational%2Fcsv%2F"
        )
    sys.exit(1)

### Upgrade settings
emission_type = "lrmer_low_re_cost_25_2025_start" # <---- least controversial approach
groupby_cols = [
    "in.state",
    "in.heating_fuel",
    "in.water_heater_fuel",
    "building_type",
    "in.tenure",
    "AMI",
]

def get_energy_savings_cols(end_use="total", output="all"):
    if output not in ["all", "total_fuel", "by_fuel"]:
        raise ValueError(f"output={output} not supported")
    energy_cols = [
        f'out.electricity.{end_use}.energy_consumption.kwh.savings',
        f'out.fuel_oil.{end_use}.energy_consumption.kwh.savings',
        f'out.natural_gas.{end_use}.energy_consumption.kwh.savings',
        f'out.propane.{end_use}.energy_consumption.kwh.savings',
        f'out.site_energy.{end_use}.energy_consumption.kwh.savings',
    ]
    if output == "total_fuel":
        return energy_cols[-1]
    if output == "by_fuel":
        return energy_cols[:-1]
    return energy_cols

def get_emission_savings_cols(emission_type="lrmer_low_re_cost_25_2025_start", output="all"):
    emission_cols = [
        f'out.emissions_reduction.electricity.{emission_type}.co2e_kg',
        f'out.emissions_reduction.fuel_oil.{emission_type}.co2e_kg',
        f'out.emissions_reduction.natural_gas.{emission_type}.co2e_kg',
        f'out.emissions_reduction.propane.{emission_type}.co2e_kg',
        f'out.emissions_reduction.all_fuels.{emission_type}.co2e_kg',
    ]
    if output == "total_fuel":
        return emission_cols[-1]
    if output == "by_fuel":
        return emission_cols[:-1]
    return emission_cols


### Helper settings
conversion_factors = {
    "electricity": 1, # to kWh
    "fuel_oil": 1/293.0710701722222, # to mmbtu 
    "natural_gas": 1/29.307107017222222, # therm
    "propane": 1/293.0710701722222, # to mmbtu 
    "site_energy": 1/293.0710701722222, # to mmbtu 
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


### func
def add_ami_to_euss_files():
    for file_path in euss_dir.iterdir():
        add_ami_column_to_file(file_path)


def remap_building_type(df):
    df["building_type"] = df["in.geometry_building_type_recs"].map({
        "Mobile Home": "Single-Family",
        "Single-Family Detached": "Single-Family",
        "Single-Family Attached": "Single-Family",
        "Multi-Family with 2 - 4 Units": "Multi-Family",
        "Multi-Family with 5+ Units": "Multi-Family",
        })
    return df

def remap_federal_poverty(df):
    df["FPL"] = df["in.federal_poverty_level"].map({
        "0-100%": "<200% FPL",
        "100-150%": "<200% FPL",
        "150-200%": "<200% FPL",
        "200-300%": "200%+ FPL",
        "300-400%": "200%+ FPL",
        "400%+": "200%+ FPL",
        })
    return df

def remap_area_median_income(df):
    df["AMI"] = df["in.area_median_income"].map({
        "0-30%": "<80% AMI",
        "30-60%": "<80% AMI",
        "60-80%": "<80% AMI",
        "80-100%": "80-150% AMI",
        "100-120%": "80-150% AMI",
        "120-150%": "80-150% AMI",
        "150%+": "150%+ AMI",
        })
    return df

def remap_columns(df):
    df = remap_building_type(df)
    df = remap_federal_poverty(df)
    df = remap_area_median_income(df)
    return df


def calculate_household_counts(df, groupby_cols, value_col):
    weight = df["weight"].unique()
    assert len(weight)==1
    weight = weight[0]

    df_count = df.loc[df["applicability"]==True].groupby(groupby_cols)[value_col].count()
    df_count = df_count.rename("modeled_count").to_frame()
    df_count["applicable_household_count"] = df_count["modeled_count"]*weight

    return df_count

def calculate_mean_savings(df, groupby_cols, value_col):
    fuel_type, unit, conversion = validate_value_column(value_col)
    col_label = f"{fuel_type}_{unit}"
    df_mean = df.loc[df["applicability"]==True].groupby(groupby_cols)[value_col].mean()
    df_mean = (df_mean*conversion).rename(col_label).to_frame()

    return df_mean

def calculate_ci_savings(df, groupby_cols, value_col, confidence="95%CI"):
    fuel_type, unit, conversion = validate_value_column(value_col)
    ci_multiplier = ci_multipliers[confidence]
    lb = f"LB {confidence}"
    ub = f"UB {confidence}"

    df_ci = df.loc[df["applicability"]==True].groupby(groupby_cols)[value_col].describe()
    ci_delta = ci_multiplier*df_ci["std"]/np.sqrt(df_ci["count"])
    df_ci[lb] = df_ci["mean"]-ci_delta
    df_ci[ub] = df_ci["mean"]+ci_delta
    df_ci = df_ci[[lb, ub]]

    # apply unit conversion as needed
    df_ci = df_ci.applymap(lambda x: x*conversion)

    return df_ci

def validate_value_column(value_col):
    if value_col.endswith("kwh.savings"):
        fuel_type = value_col.split(".")[1]
        end_use = value_col.split(".")[2]
        conversion = conversion_factors[fuel_type]
        unit = converted_units[fuel_type]
        
    elif value_col.endswith("co2e_kg"):
        assert "reduction" in value_col, value_col
        fuel_type = value_col.split(".")[2]
        conversion = 1
        unit = "co2e_kg"

    else:
        raise ValueError(f"value_col={value_col} cannot be used with calculate_mean_savings")

    return fuel_type, unit, conversion


def load_results(pkgs: list):
    if not isinstance(pkgs, list):
        pkgs = [pkgs]

    DF = []
    for pkg in pkgs:
        filename = f"upgrade{pkg:02d}_metadata_and_annual_results.csv"
        df = pd.read_csv(euss_dir / filename, low_memory=False)
        DF.append(remap_columns(df))

    return pd.concat(DF, axis=0).reset_index(drop=True)


def get_savings_dataframe_base(df, groupby_cols, energy_savings_cols, total_emission_col):
    # get mean savings
    DF = [calculate_household_counts(df, groupby_cols, "bldg_id")]
    for energy_col in energy_savings_cols:
        DF.append(calculate_mean_savings(df, groupby_cols, energy_col))
        print(f" - added {energy_col}")
    DF.append(calculate_mean_savings(df, groupby_cols, total_emission_col))
    print(f" - added {total_emission_col}")
    
    DF = pd.concat(DF, axis=1)
    DF.index.names = [x.strip("in.") for x in DF.index.names]

    # QC
    small_count = DF[DF["modeled_count"]<10]
    if len(small_count)>0:
        print(f"WARNING, {len(small_count)} / {len(DF)} segment has <10 models!")

    return DF


def get_savings_dataframe_for_an_enduse(df, enduse):
    energy_cols_enduse = get_energy_savings_cols(enduse, output="by_fuel")
    energy_cols_total = get_energy_savings_cols("total", output="by_fuel")
    emission_cols = get_emission_savings_cols(emission_type, output="by_fuel")

    # calculate savings attributed to heat/cool, add as new cols
    emission_cols_new = []
    dfi = df.copy()
    for enduse_col, total_col, emission_col in zip(
        energy_cols_enduse,
        energy_cols_total, 
        emission_cols
        ):
        if not enduse_col in dfi.columns:
            print(f"   {enduse_col} not in df.columns, skipping...")
            energy_cols_enduse.remove(enduse_col)
            continue
        print(f"   {enduse_col}")
        new_emission_col = emission_col.replace("emissions_reduction", f"emissions_reduction_{enduse}")
        savings_factor = dfi[enduse_col]/dfi[total_col]
        dfi[new_emission_col] = dfi[emission_col] * savings_factor
        emission_cols_new.append(new_emission_col)

    # combined attributed savings, add as new cols
    total_col = get_energy_savings_cols("total", output="total_fuel").replace("total", enduse)
    dfi[total_col] = dfi[energy_cols_enduse].sum(axis=1)
    energy_cols_enduse.append(total_col)

    total_emission_col = get_emission_savings_cols(emission_type, output="total_fuel")\
        .replace("emissions_reduction", f"emissions_reduction_{enduse}")
    dfi[total_emission_col] = dfi[emission_cols_new].sum(axis=1)

    # get mean savings
    DF = get_savings_dataframe_base(dfi, groupby_cols, energy_cols_enduse, total_emission_col)

    return DF


def get_savings_total(pkg, pkg_name, return_df=False):
    print(f"\n> Calculating total savings for [[ {pkg_name} ]] from upgrade {pkg}...")
    df = load_results(pkg)

    # filter, applicability is applied during calculation
    cond = (df["in.vacancy_status"]=="Occupied")
    df = df.loc[cond]

    energy_savings_cols = get_energy_savings_cols("total")
    total_emission_col = f'out.emissions_reduction.all_fuels.{emission_type}.co2e_kg'

    # get mean savings
    DF = get_savings_dataframe_base(df, groupby_cols, energy_savings_cols, total_emission_col)

    # save to file
    output_file = f"mean-{pkg_name}.csv"
    DF.to_csv(output_dir / output_file)


def get_savings_dryer(pkg, pkg_name, return_df=False):
    print(f"\n> Calculating dryer savings for [[ {pkg_name} ]] from upgrade {pkg}...")
    df = load_results(pkg)

    # filter to tech, applicability is applied during calculation
    cond = (df["in.vacancy_status"]=="Occupied")
    cond &= (~df["upgrade.clothes_dryer"].isna())
    df = df.loc[cond]
    enduse = "clothes_dryer"
    DF = get_savings_dataframe_for_an_enduse(df, enduse)

    # save to file
    output_file = f"mean-{pkg_name}.csv"
    DF.to_csv(output_dir / output_file)


def get_savings_cooking(pkg, pkg_name, return_df=False):
    print(f"\n> Calculating cooking savings for [[ {pkg_name} ]] from upgrade {pkg}...")
    df = load_results(pkg)

    # filter to tech, applicability is applied during calculation
    cond = (df["in.vacancy_status"]=="Occupied")
    cond &= (~df["upgrade.cooking_range"].isna())
    df = df.loc[cond]
    enduse = "range_oven"
    DF = get_savings_dataframe_for_an_enduse(df, enduse)

    # save to file
    output_file = f"mean-{pkg_name}.csv"
    DF.to_csv(output_dir / output_file)


def get_savings_heating_and_cooling(pkg, pkg_name, return_df=False):
    """ 
    This attributes all savings that are not:
        - water heating
        - dryer
        - cooking
    as savings (heating and cooling) for heat pumps + envelope upgrades

    """
    print(f"\n> Calculating heat/cool savings for [[ {pkg_name} ]] from upgrade {pkg}...")
    print(f"  by removing from total savings: water_heating, dryer, cooking...")
    df = load_results(pkg)

    # filter to tech, applicability is applied during calculation
    cond = (df["in.vacancy_status"]=="Occupied")
    cond &= (~(
        df["upgrade.hvac_cooling_efficiency"].isna() & df["upgrade.hvac_heating_efficiency"].isna()
        ))
    df = df.loc[cond]
    energy_cols_hot_water = get_energy_savings_cols("hot_water", output="by_fuel")
    energy_cols_dryer = get_energy_savings_cols("clothes_dryer", output="by_fuel")
    energy_cols_cooking = get_energy_savings_cols("range_oven", output="by_fuel")
    energy_cols_total = get_energy_savings_cols("total", output="by_fuel")
    emission_cols = get_emission_savings_cols(emission_type, output="by_fuel")

    # calculate savings attributed to heat/cool, add as new cols
    enduse_new = "heat_cool"
    energy_cols_new = []
    emission_cols_new = []
    dfi = df.copy()
    for hot_water_col, dryer_col, cooking_col, total_col, emission_col in zip(
        energy_cols_hot_water,
        energy_cols_dryer,
        energy_cols_cooking,
        energy_cols_total, 
        emission_cols
        ):
        available_enduses = list({hot_water_col, dryer_col, cooking_col}.intersection(set(dfi.columns)))
        new_col = total_col.replace("total", enduse_new)
        dfi[new_col] = dfi[total_col]-dfi[available_enduses].sum(axis=1)
        energy_cols_new.append(new_col)
        
        new_emission_col = emission_col.replace("emissions_reduction", f"emissions_reduction_{enduse_new}")
        savings_factor = dfi[new_col]/dfi[total_col]
        dfi[new_emission_col] = dfi[emission_col] * savings_factor
        emission_cols_new.append(new_emission_col)

    # combined attributed savings, add as new cols
    total_col = get_energy_savings_cols("total", output="total_fuel").replace("total", enduse_new)
    dfi[total_col] = dfi[energy_cols_new].sum(axis=1)
    energy_cols_new.append(total_col)

    total_emission_col = get_emission_savings_cols(emission_type, output="total_fuel")\
        .replace("emissions_reduction", f"emissions_reduction_{enduse_new}")
    dfi[total_emission_col] = dfi[emission_cols_new].sum(axis=1)

    # get mean savings
    DF = get_savings_dataframe_base(dfi, groupby_cols, energy_cols_new, total_emission_col)

    # save to file
    output_file = f"mean-{pkg_name}.csv"
    DF.to_csv(output_dir / output_file)


###### main ###### 
# # Pre-process:
# add_ami_to_euss_files() # run it once

# calculated unit count, rep unit count, savings by fuel, carbon saving
# TODO: bills calc (here), upgrade costs (in another script pull from results on AWS)
# [1] Basic enclosure: all (pkg 1)
get_savings_total(1, "basic_enclosure_upgrade")

# [2] Enhanced enclosure: all (pkg 2)
get_savings_total(2, "enhanced_enclosure_upgrade")

# [3] Heat pump – min eff: all (pkg 3)
get_savings_total(3, "heat_pump_min_eff_with_electric_backup")

# [4] Heat pump – high eff: all (pkg 4)
get_savings_total(4, "heat_pump_high_eff_with_electric_backup")

# [5] Heat pump – min eff + existing backup: all (pkg 5)
get_savings_total(5, "heat_pump_min_eff_with_existing_backup")

# [6] Heat pump – high eff + basic enclosure: Heating & Cooling (pkg 9)
get_savings_heating_and_cooling(9, "heat_pump_high_eff_with_basic_enclosure")

# [7] Heat pump – high eff + enhanced enclosure: Heating & Cooling (pkg 10)
get_savings_heating_and_cooling(10, "heat_pump_high_eff_with_enhanced_enclosure")

# [8] Heat pump water heater: all (pkg 6)
get_savings_total(6, "heat_pump_water_heater")

# [9] Electric dryer: Clothes dryer (pkg 7)
get_savings_dryer(7, "electric_clothes_dryer")

# [10] Heat pump dryer: Clothes dryer (pkg 8, 9, 10)
get_savings_dryer([8,9,10], "heat_pump_clothes_dryer")

# [11] Electric cooking: Cooking (pkg 7)
get_savings_cooking(7, "electric_cooking")

# [12] Induction cooking: Cooking (pkg 8, 9, 10)
get_savings_cooking([8,9,10], "induction_cooking")

# breakpoint()

# # load EUSS results
# df_EUSS_base = pd.read_csv("baseline_metadata_and_annual_results.csv") # baseline means buildings stock as is
# df_EUSS_up1 = pd.read_csv("upgrade01_metadata_and_annual_results.csv") # basic enclosure package
# df_EUSS_up2 = pd.read_csv("upgrade02_metadata_and_annual_results.csv") #enhanced enclosure package
# df_EUSS_up3 = pd.read_csv("upgrade03_metadata_and_annual_results.csv") # heat pumps, min-efficiency, electric backup
# df_EUSS_up4 = pd.read_csv("upgrade04_metadata_and_annual_results.csv") # heat pumps, high-efficiency, electric backup
# df_EUSS_up5 = pd.read_csv("upgrade05_metadata_and_annual_results.csv") # heat pumps, min-effi., existing heating as backup
# df_EUSS_up6 = pd.read_csv("upgrade06_metadata_and_annual_results.csv") # heat pump water heaters
# df_EUSS_up7 = pd.read_csv("upgrade07_metadata_and_annual_results.csv") # whole-home electrification, min eff.
# df_EUSS_up8 = pd.read_csv("upgrade08_metadata_and_annual_results.csv") # whole-home electrification, max eff.
# df_EUSS_up9 = pd.read_csv("upgrade09_metadata_and_annual_results.csv") # whole-home electrification, high eff. + basic enclosure package
# df_EUSS_up10 = pd.read_csv("upgrade10_metadata_and_annual_results.csv") # whole-home electrification, high eff. + enhanced enclosure package

# #load utility bill costs
# df_elec_costs = pd.read_csv("Variable Elec Cost by State from EIA State Data.csv") # $/kWhr
# df_ng_costs = pd.read_csv('NG costs by state.csv') # $/therm
# df_fo_costs = pd.read_csv('Fuel Oil Prices Averaged by State.csv') # $/gallon
# df_lp_costs = pd.read_csv('Propane costs by state.csv') # $/gallon

# ## define constants

# # Source of utility data and year
# elec_source = 'EIA (Utility Rate Database), 2019'
# ng_source = 'American Gas Association, 2019'
# fo_source = 'EIA, 2019'
# lp_source = 'EIA, 2019'

# # Conversion from source unit to Btu (currently)
# # TODO: what kind of conversion do we need?
# # TODO: may need in kWh since all EUSS results are in kWh.
# btu_propane_in_one_gallon = 91452 #source: https://www.eia.gov/energyexplained/units-and-calculators/
# gallons_to_barrels = 42 #source: https://www.eia.gov/energyexplained/units-and-calculators/
# btu_fueloil_in_one_barrel = 6287000 #source: https://www.eia.gov/energyexplained/units-and-calculators/

# ##define functions

# # choose results columns to work with for EUSS and Fuel data

# ## EUSS Consumption at Baseline (before upgrades)
# # TODO: building types: water heating or space heating - ask for help on?
# before_selected_cols = [
#     'building_id', 
#     'in.state', # location
#     'in.tenure', # owner v. renter
#     'in.geometry_building_type_recs', # single v. multifamily v mobile home (TODO: convert mobile home to single?)
#     'out.site_energy.total.energy_consumption.kwh', # total energy
#     'out.electricity.total.energy_consumption.kwh', # electric total
#     'out.fuel_oil.total.energy_consumption.kwh', # fuel oil total
#     'out.natural_gas.total.energy_consumption.kwh' #natural gas total
#     'out.propane.total.energy_consumption.kwh', # propane total
#     'out.emissions.all_fuels.lrmer_low_re_cost_25_2025_start.co2e_kg' # emissions - least controversial approach
#     ]
# def before_downselect_cols(df):
#     df = df[before_selected_cols]
#     return df

# ## EUSS Upgrade results
# after_selected_cols = [
#     'building_id', 
#     'out.site_energy.total.energy_consumption.kwh', # total energy
#     'out.electricity.total.energy_consumption.kwh', # electric total
#     'out.fuel_oil.total.energy_consumption.kwh', # fuel oil total
#     'out.natural_gas.total.energy_consumption.kwh' #natural gas total
#     'out.propane.total.energy_consumption.kwh', # propane total
#     'out.emissions.all_fuels.lrmer_low_re_cost_25_2025_start.co2e_kg' # emissions - least controversial approach
#     ]
# def after_downselect_cols(df):
#     df = df[after_selected_cols]
#     return df


# #calculate total energy difference for each upgrade, for each home, add to the mini dataframes
# def calc_delta_energy(df_baseline, df_upgrade):
#     return (df_baseline['out.site_energy.total.energy_consumption.kwh']-df_upgrade['out.site_energy.total.energy_consumption.kwh'])
# def calc_delta_elec(df_baseline, df_upgrade):
#     return (df_baseline['out.electricity.total.energy_consumption.kwh']-df_upgrade['out.electricity.total.energy_consumption.kwh'])
# def calc_delta_fo(df_baseline, df_upgrade):
#     return (df_baseline['out.fuel_oil.total.energy_consumption.kwh']-df_upgrade['out.fuel_oil.total.energy_consumption.kwh'])
# def calc_delta_ng(df_baseline, df_upgrade):
#     return (df_baseline['out.natural_gas.total.energy_consumption.kwh']-df_upgrade['out.natural_gas.total.energy_consumption.kwh'])
# def calc_delta_lp(df_baseline, df_upgrade):
#     return (df_baseline['out.propane.total.energy_consumption.kwh']-df_upgrade['out.propane.total.energy_consumption.kwh'])
# def calc_delta_emission(df_baseline, df_upgrade):
#     return (df_baseline['out.emissions.all_fuels.lrmer_low_re_cost_25_2025_start.co2e_kg']-df_upgrade['out.emissions.all_fuels.lrmer_low_re_cost_25_2025_start.co2e_kg'])

# # Create baseline dataframe 
# df_EUSS_base = before_downselect_cols(df_EUSS_base)

"""
# TODO: Still need to figure this section out
# This is based off of 'Facades Economic Analysis for Sharing.py

#add utility bill cost information to the baseline results
results_b = pd.merge(df_EUSS_base, df_elec_costs[['State', 'Variable Elec Cost $/kWh']], left_on = "build_existing_model.state", right_on = 'State', how = 'left')
results_b = results_b.drop(['State'], 1)
results_b = pd.merge(results_b, df_ng_costs[['State', 'NG Cost without Meter Charge [$/therm]']], left_on = "build_existing_model.state", right_on = 'State', how = 'left')
results_b = results_b.drop(['State'], 1)
results_b = pd.merge(results_b, df_fo_costs[['State', 'Average FO Price [$/gal]']], left_on = "build_existing_model.state", right_on = 'State', how = 'left')
results_b = results_b.drop(['State'], 1)
results_b = pd.merge(results_b, df_lp_costs[['State', 'Average Weekly Cost [$/gal]']], left_on = "build_existing_model.state", right_on = 'State', how = 'left')
results_b = results_b.drop(['State'], 1)
results_b.rename(columns={
    'Variable Elec Cost $/kWh': 'Elec Variable Cost [$/kWh]',
    'NG Cost without Meter Charge [$/therm]': 'NG Variable Cost [$/therm]', 
    'Average FO Price [$/gal]': 'FO Average Cost [$/gal]',
    'Average Weekly Cost [$/gal]': 'LP Average Price [$/gal]'},
    inplace=True)

##Set up and run things!
#number of upgrade packages
num_ups = 9
up_start = "up"

for i in range(1, num_ups+1):
    if i<10:
        upnum = str(i)
    else:
        upnum = str(i)
    df_name = "df_EUSS_up" + upnum
    upgrade = up_start + upnum
    df = after_downselect_cols(df_name)
    #calculate changes in energy use for each fuel
    delta_elec = calc_delta_elec(df_EUSS_base, df)
    results_b[upgrade + "_delta_elec_kWh"] = delta_elec
    delta_ng = calc_delta_ng(df_EUSS_base, df)
    results_b[upgrade + "_delta_ng_kWh"] = delta_ng
    delta_fo = calc_delta_fo(df_EUSS_base, df)
    results_b[upgrade + "_delta_fo_kWh"] = delta_fo
    delta_lp = calc_delta_lp(df_EUSS_base, df)
    results_b[upgrade + "_delta_lp_kWh"] = delta_lp
    delta_energy = calc_delta_energy(df_EUSS_base, df)
    results_b[upgrade + "_delta_allfuels_kWh"] = delta_energy
    delta_energy = calc_delta_emission(df_EUSS_base, df)
    results_b[upgrade + "_delta_emissions_C02e_kg"] = delta_energy


#save results
# results_b.to_csv('results_with_economics_allfuels.csv')
"""
