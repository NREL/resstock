"""
Requires env with python >= 3.10
-**
Electrical Panel Project: Estimate existing load in homes using NEC (2023)
Load Summing Method: 220.83
Maximum Demand Method: 220.87

NEC panel capacity = min. main circuit breaker size (A)

By: Lixi.Liu@nrel.gov, Ilan.Upfal@nrel.gov
Date: 02/01/2023
Updated: 02/21/2024

-----------------
kW = kVA * PF, kW: working (active) power, kVA: apparent (active + reactive) power, PF: power factor
For inductive load, use PF = 0.8 (except cooking per 220.55, PF=1)
Reactive power is phantom in that there may be current draw or voltage drop but no power is actually dissipated
(Inductors and capacitors have this behavior)

Continous load := max current continues for 3+ hrs
Branch circuit rating for continous load >= 1.25 x nameplate rating, but not applicable to load calc

-----------------

[220.83] - Load Summing Method
Generally, sum the following loads and then apply tiered demand load factors to the total load (see CAVEATS)
1) general lighting and receptable loads at 3 VA/sqft;
2) at least 2 branch circuits for kitchen and 1 branch circuit for laundry at 1.5 kVA per branch; and
3) all appliances that are fastened in place and permanently connected:
   - HVAC (taken as the larger nameplate of space heating or cooling), 
   - water heaters,
   - clothes dryers, 
   - cooking ranges/ovens, 
   - dishwashers,
   - EVSE, 
   - hot tubs, pool heaters, pool pumps, well pumps, garbage disposals, garbage compactors, and 
   - other fixed appliances with at least a 1/4 HP (500W) nameplate rating.

CAVEATS:
Part A: If NO new HVAC load is being added,
   Existing Load = 100% of first 8 kVA of Total :oad + 40% of remaining Total Load
Part B: If new HVAC load is being added, 
   Existing Load = 100% HVAC Load + 100% of first 8 kVA of Non-HVAC Load + 40% of remaining Non-HVAC load

[220.87] - Maximum Demand Method
Existing Load = 125% x 15_min_electricity_peak (1-full year)

"""

import pandas as pd
from pathlib import Path
import numpy as np
import math
import argparse
import sys

from plotting_functions import _plot_scatter, _plot_box
from clean_up00_file import get_housing_char_cols

# --- lookup ---
geometry_unit_aspect_ratio = {
    "Single-Family Detached": 1.8,
    "Single-Family Attached": 0.5556,
    "Multi-Family with 2 - 4 Units": 0.5556,
    "Multi-Family with 5+ Units": 0.5556,
    "Mobile Home": 1.8,
} #  = front_back_length / left_right_width #TODO: check to see if it gets recalculated


hvac_fan_motor = 3*115*0.87 # 3A x 115V x PF (condenser fan motor) # TODO check value
hvac_blower_motor = 460 # TODO check value
KBTU_H_TO_W = 293.07103866

nameplate_power_rating = pd.read_csv("nameplate_rating.csv")

# --- funcs ---

def apply_demand_factor(x, threshold_load=8000):
    """
    Split load into the following tiers and apply associated multiplier factor
        If threshold_load == 8000:
            <= 10kVA : 1.00
            > 10kVA : 0.4
    """
    return (
        1 * min(threshold_load, x) +
        0.4 * max(0, x - threshold_load)
    )


def _general_load_lighting(row):
    """General Lighting & Receptacle Loads. NEC 220.41
    Accounts for motors < 1/8HP and connected to lighting circuit is covered by lighting load
    Dwelling footprint area MUST include garage

    Args:
        row : row of Pd.DataFrame()
        by_perimeter: bool
            Whether calculation is based on 
    """
    if row["completed_status"] != "Success":
        return np.nan

    garage_depth = 24 # ft
    match row["build_existing_model.geometry_garage"]:
        case "1 Car":
            garage_width = 12
        case "2 Car":
            garage_width = 24
        case "3 Car":
            garage_width = 36
        case "None":
            garage_width = 0
        case _:
            garage_width = 0
    
    floor_area = row["upgrade_costs.floor_area_conditioned_ft_2"] # already based on exterior dim (AHS)

    # calculate based on perimeter of footprint with receptables at every 6-feet
    aspect_ratio = geometry_unit_aspect_ratio[row["build_existing_model.geometry_building_type_recs"]]
    fb_length = math.sqrt(floor_area * aspect_ratio) # total as if single-story
    lr_width = floor_area / fb_length

    floor_area += garage_width*garage_depth

    n_receptables = 2*(fb_length+lr_width) // 6
    receptable_load = n_receptables * 20*120 # 20-Amp @ 120V
    # TODO: add other potential unit loads

    return 3 * floor_area


def _general_load_lighting_optm(row): 
    """Not including open porches, garages, unused or unfinished spaces not adaptable for future use"""
    if row["completed_status"] != "Success":
        return np.nan

    return 3 * row["upgrade_costs.floor_area_conditioned_ft_2"]


def _general_load_kitchen(row, n=2):
    """Small Appliance Branch Circuits. NEC 220-16(a)
        At least 2 small appliances branch circuits at 20A must be included. NEC 210-11(c)1

        NEMA 5-15 3-prong plug, max up to 72A (60% * 120V) per circuit
        bldgtype-dependent: branch up to # receptacles

        Small appliances:
            - refrigerator: 100-250W
            - freezer: 30-100W

    Args:
        n: int | "auto"
            number of branches for small appliances, minimum 2
    """
    if row["completed_status"] != "Success":
        return np.nan

    if n == "auto":
        n = 2  # start with min requirement
        # TODO: can expand based on building_type, vintage, and floor_area
        """
        if (row["build_existing_model.misc_extra_refrigerator"] != "None") or (
            row["build_existing_model.misc_freezer"] != "None"
        ):
            n += 2  # 2 additional branches added for misc refrigeration (outside kitchen) #TODO: This is incorrect, small appliance branch circuits can only supply loads in the kitchen
        """
    if n < 2:
        raise ValueError(
            f"n={n}, at least 2 small appliance/kitchen branch circuit for General Load"
        )
    return n * 1500


def _general_load_laundry(row, n=1):
    """Laundry Branch Circuit(s). NEC 210-11(c)2, 220-16(b), 220-4(c)
        At least 1 laundry branch circuit must be included.

        Pecan St clothes washers: 600-1440 W (1165 wt avg)
        Pecan St gas dryers: 600-2760 W (800 wt avg)

    Args:
        n: int | "auto"
            number of branches for general laundry load (exclude dryer), minimum 1
    """
    if row["completed_status"] != "Success":
        return np.nan
    
    washer = nameplate_power_rating.loc[(nameplate_power_rating['load_category'] == 'clothes washer') & (nameplate_power_rating['appliance'] == 'electric')]
    washer_power_rating = list(washer['volt-amps'])[0]
    
    if n == "auto":
        if "Single-Family" in row["build_existing_model.geometry_building_type_recs"]:
            n = washer_power_rating # TODO, can expand based on floor_area, vintage, etc
        elif row["build_existing_model.clothes_washer_presence"] == "Yes":
            # for non-SF, if there's in-unit WD, then there's a branch
            n = washer_power_rating
        else:
            n = 0

        if "Electric" not in row["build_existing_model.clothes_dryer"] and row["build_existing_model.clothes_dryer"] != "None":
            n += 800 # add additional laundry circuit for non-electric dryer
    
    if "Single-Family" in row["build_existing_model.geometry_building_type_recs"] and n < 1:
        raise ValueError(f"n={n}, at least 1 laundry branch circuit for Laundry Load")
   
    return max(1500, n)


def _fixed_load_water_heater(row):
    if row["completed_status"] != "Success":
        return np.nan
    
    water_heater_electric = nameplate_power_rating.loc[(nameplate_power_rating['load_category'] == 'water heater') & (nameplate_power_rating['appliance'] == 'electric')]
    water_heater_electric_power_rating = list(water_heater_electric['volt-amps'])[0]

    water_heater_electric_tankless_1bath = nameplate_power_rating.loc[(nameplate_power_rating['load_category'] == 'water heater') & (nameplate_power_rating['appliance'] == 'electric tankless, one bathroom')]
    water_heater_electric_tankless_1bath_power_rating = list(water_heater_electric_tankless_1bath['volt-amps'])[0]

    water_heater_electric_tankless_more_1bath = nameplate_power_rating.loc[(nameplate_power_rating['load_category'] == 'water heater') & (nameplate_power_rating['appliance'] == 'electric tankless, more than one bathroom')]
    water_heater_electric_tankless_more_1bath_power_rating = list(water_heater_electric_tankless_more_1bath['volt-amps'])[0]

    water_heater_heat_pump = nameplate_power_rating.loc[(nameplate_power_rating['load_category'] == 'water heater') & (nameplate_power_rating['appliance'] == 'heat pump')]
    water_heater_heat_pump_power_rating = list(water_heater_heat_pump['volt-amps'])[0]

    # TODO: water heater in unit -- if discounting here, need it removed from peak load
    if (row["build_existing_model.water_heater_in_unit"] == "Yes") & ((
        row["build_existing_model.water_heater_fuel"] == "Electricity")|(
        "Electric" in row["build_existing_model.water_heater_efficiency"]
        )):
        if row["build_existing_model.water_heater_efficiency"] == "Electric Tankless":
            if row["build_existing_model.bedrooms"] in [1,2]:
                return water_heater_electric_tankless_1bath_power_rating 
            if row["build_existing_model.bedrooms"] in [3,4,5]:
                return water_heater_electric_tankless_more_1bath_power_rating
        if "Heat Pump" in row["build_existing_model.water_heater_efficiency"]:
            return water_heater_heat_pump_power_rating
        return water_heater_electric_power_rating
    return 0


def _fixed_load_dishwasher(row):
    """
    Dishwasher: 12-15A, 120V
        Amperage not super correlated with kWh rating, but will assume 12A for <=255kWh, and 15A else
    """
    if row["completed_status"] != "Success":
        return np.nan
    
    dishwasher = nameplate_power_rating.loc[(nameplate_power_rating['load_category'] == 'dishwasher') & (nameplate_power_rating['appliance'] == 'electric')]
    dishwasher_power_rating = list(dishwasher['volt-amps'])[0]

    if row["build_existing_model.dishwasher"] == "None":
        return 0
    return dishwasher_power_rating


def _fixed_load_garbage_disposal(row):
    """
    garbage disposal: 0.8 - 1.5 kVA (1.2kVA avg), typically second largest motor, after AC compressor

    pump/motor nameplates taken from NEC tables based on HP, not PF needed

    We do not currently model disposal, will use vintage and floor area as proxy for now
    there could be a jurisdition restriction as well as dep to dwelling type

    Garbage disposal became available in 1940s and lives in ~ 50% US households according to:
    https://www.michaelsplumbingorlando.com/a-brief-history-of-the-garbage-disposal-what-you-shouldnt-throw-down-it/

    """
    if row["completed_status"] != "Success":
        return np.nan

    if row["build_existing_model.vintage"] in [
        "1940-59",
        "1960-79",
        "1980-99",
        "2000-09",
        "2010s",
    ]:
        garbage_disposal_one_third_hp = nameplate_power_rating.loc[(nameplate_power_rating['load_category'] == 'garbage disposal') & (nameplate_power_rating['appliance'] == '1/3 HP')]
        garbage_disposal_one_third_hp_power_rating = list(garbage_disposal_one_third_hp['volt-amps'])[0]
        garbage_disposal_half_hp = nameplate_power_rating.loc[(nameplate_power_rating['load_category'] == 'garbage disposal') & (nameplate_power_rating['appliance'] == '1/2 HP')]
        garbage_disposal_half_hp_power_rating = list(garbage_disposal_half_hp['volt-amps'])[0]
        garbage_disposal_three_quarters_hp = nameplate_power_rating.loc[(nameplate_power_rating['load_category'] == 'garbage disposal') & (nameplate_power_rating['appliance'] == '0.75 HP')]
        garbage_disposal_three_quarters_hp_power_rating = list(garbage_disposal_three_quarters_hp['volt-amps'])[0]

        if row["build_existing_model.geometry_floor_area"] in ["0-499"]:
            return 0
        elif row["build_existing_model.geometry_floor_area"] in ["500-749", "750-999"]:
            return garbage_disposal_one_third_hp_power_rating  # 1/3 HP
        elif row["build_existing_model.geometry_floor_area"] in [
            "1000-1499",
            "1500-1999",
            "2000-2499",
        ]:
            return garbage_disposal_half_hp_power_rating  # 1/2 HP
        else:
            return garbage_disposal_three_quarters_hp_power_rating # .75 HP
    return 0


def _fixed_load_garbage_compactor(row):
    """
    We do not currently model compactor
    "Ownership dropped to under 3.5% across the nation by 2009" according to:
    https://www.familyhandyman.com/article/what-ever-happened-to-the-trash-compactor/
    """
    if row["completed_status"] != "Success":
        return np.nan

    return 0


def _fixed_load_hot_tub_spa(row):
    if row["completed_status"] != "Success":
        return np.nan
    
    hot_tub_spa = nameplate_power_rating.loc[(nameplate_power_rating['load_category'] == 'hot tub/spa') & (nameplate_power_rating['appliance'] == 'electric')]
    hot_tub_spa_power_rating = list(hot_tub_spa['volt-amps'])[0]

    if row["build_existing_model.misc_hot_tub_spa"] == "Electric":
        return hot_tub_spa_power_rating
    return 0


def _fixed_load_well_pump(row):
    """ pump/motor nameplates taken from NEC tables based on HP, not PF needed """
    if row["completed_status"] != "Success":
        return np.nan
    
    well_pump = nameplate_power_rating.loc[(nameplate_power_rating['load_category'] == 'well pump') & (nameplate_power_rating['appliance'] == 'electric')]
    well_pump_power_rating = list(well_pump['volt-amps'])[0]

    # TODO: verify
    if row["build_existing_model.misc_well_pump"] != "None":
        return well_pump_power_rating 
    return 0


def _special_load_electric_dryer(row):
    """Clothes Dryers. NEC 220-18
    Use 5000 watts or nameplate rating whichever is larger (in another version, use DF=1 for # appliance <=4)
    240V, 22/24/30A breaker (vented), 30/40A (ventless heat pump), 30A (ventless electric)
    """
    if row["completed_status"] != "Success":
        return np.nan
    
    dryer_elctric = nameplate_power_rating.loc[(nameplate_power_rating['load_category'] == 'clothes dryer') & (nameplate_power_rating['appliance'] == 'electric')]
    dryer_elctric_power_rating = list(dryer_elctric['volt-amps'])[0]
    dryer_elctric_ventless = nameplate_power_rating.loc[(nameplate_power_rating['load_category'] == 'clothes dryer') & (nameplate_power_rating['appliance'] == 'electric ventless')]
    dryer_elctric_ventless_power_rating = list(dryer_elctric_ventless['volt-amps'])[0]

    if "Electric" not in row["build_existing_model.clothes_dryer"] or row["build_existing_model.clothes_dryer"] == "None":
        return 0

    if "Ventless" in row["build_existing_model.clothes_dryer"]:
        rating = dryer_elctric_ventless_power_rating
    else:
        rating = dryer_elctric_power_rating

    return max(5000, rating)


def _special_load_electric_range(row): 
    """ Assuming a single electric range (combined oven/stovetop) for each dwelling unit """
    range_power = _special_load_electric_range_nameplate(row)

    if range_power <= 12000:
        range_power_w_df = min(range_power, 8000)
    elif range_power <= 27000:
        range_power_w_df = 8000 + 0.05*(max(0,range_power-12000)) # footnote 2
    else:
        raise ValueError(f"range_power={range_power} cannot exceed 27kW")
    
    return range_power_w_df


def _special_load_electric_range_nameplate(row): 
    """ Assuming a single electric range (combined oven/stovetop) for each dwelling unit """
    if row["completed_status"] != "Success":
        return np.nan
    
    range_elctric = nameplate_power_rating.loc[(nameplate_power_rating['load_category'] == 'range/oven') & (nameplate_power_rating['appliance'] == 'electric')]
    range_elctric_power_rating = list(range_elctric['volt-amps'])[0]
    range_induction = nameplate_power_rating.loc[(nameplate_power_rating['load_category'] == 'range/oven') & (nameplate_power_rating['appliance'] == 'induction')]
    range_induction_power_rating = list(range_induction['volt-amps'])[0]

    if "Electric" not in row["build_existing_model.cooking_range"] or row["build_existing_model.cooking_range"]=="None":
        return 0

    if "Induction" in row["build_existing_model.cooking_range"]:
        # range-oven: 10-13.6kW rating (240V, 40A) or 8.4kW (240V, 50A) or 8kW (240V, 40A)
        # cooktop: 11-12kW rating (240V, 30/50A) or 15.4kW rating (240V, 40A), 7.2-8.6kW (240V, 30/45A)
        # electric wall oven: 4.5kW (120V, 30A or 240V, 20/30A)
        # For induction cooktop + electric wall oven = 11+0.65*4.5 = 14kW 
        return range_induction_power_rating  # 40*240 or 14000 #TODO: This should be the full nameplate rating (max connected load) of an electric induction range

    ## Electric, non-induction
    # range-oven: 10-12.1-13.5kW (240V, 40A)
    # cooktop: 9.2kW (240V, 40A), 7.7-10.5kW (240V, 40/50A), 7.4kW (240V, 40A)
    # For cooktop + wall oven = 11+0.65*4.5 = 14kW or 0.65*(8+4.5) = 8kW
    return range_elctric_power_rating  # or 12500 #TODO: This should be the full nameplate rating (max connected load) of an electric non-induction range


def hvac_heating_conversion(nom_heat_cap, heating_eff, system_type=None):
    """ 
    Relationship between either minimum breaker or minimum circuit amp (x voltage) and nameplate capacity
    nominal conditions refer to AHRI standard conditions: 47F?
    Args :
        nom_heat_cap : float
            nominal heating capacity in kbtu/h
        system_type : str
            system type
        heating_eff : str
            heating efficiency
    Returns : 
        W = Amp*V
    """ 
    if system_type == "Ducted Heat Pump" and ('ASHP' in heating_eff):
        heating = nameplate_power_rating.loc[(nameplate_power_rating['load_category'] == 'space heating') & (nameplate_power_rating['appliance'] == 'ducted heat pump')]
        voltage = list(heating['voltage'])[0]
        coef1 = float(list(heating['amperage'])[0].split(',')[0])
        coef2 = float(list(heating['amperage'])[0].split(',')[1])
        intercept = float(list(heating['amperage'])[0].split(',')[2])
        seer = float(heating_eff.split(',')[1].split(' ')[2])   
        return (coef1*nom_heat_cap + coef2*seer + intercept) * voltage
    if system_type == "Non-Ducted Heat Pump"and ('MSHP' in heating_eff):
        heating = nameplate_power_rating.loc[(nameplate_power_rating['load_category'] == 'space heating') & (nameplate_power_rating['appliance'] == 'non-ducted heat pump')]
        voltage = list(heating['voltage'])[0]
        coef1 = float(list(heating['amperage'])[0].split(',')[0])
        coef2 = float(list(heating['amperage'])[0].split(',')[1])
        intercept = float(list(heating['amperage'])[0].split(',')[2])
        seer = float(heating_eff.split(',')[1].split(' ')[2])   
        return (coef1*nom_heat_cap + coef2*seer + intercept) * voltage

    return nom_heat_cap * KBTU_H_TO_W


def hvac_cooling_conversion(nom_cool_cap, heating_eff, cooling_eff, system_type=None):
    """ 
    Relationship between either minimum breaker or minimum circuit amp (x voltage) and nameplate capacity
    nominal conditions refer to AHRI standard conditions: 95F?
    Args :
        nom_cool_cap : float
            nominal cooling capacity in kbtu/h
        system_type : str
            system type
    Returns : 
        W = Amp*V
    """
    if system_type == "Ducted Heat Pump" and ('ASHP' in heating_eff):
        cooling = nameplate_power_rating.loc[(nameplate_power_rating['load_category'] == 'space cooling') & (nameplate_power_rating['appliance'] == 'ducted heat pump')]
        voltage = list(cooling['voltage'])[0]
        coef1 = float(list(cooling['amperage'])[0].split(',')[0])
        coef2 = float(list(cooling['amperage'])[0].split(',')[1])
        intercept = float(list(cooling['amperage'])[0].split(',')[2])
        seer = float(heating_eff.split(',')[1].split(' ')[2])   
        return (coef1*nom_cool_cap + coef2*seer + intercept) * voltage
    if system_type == "Non-Ducted Heat Pump" and ('MSHP' in heating_eff):
        cooling = nameplate_power_rating.loc[(nameplate_power_rating['load_category'] == 'space cooling') & (nameplate_power_rating['appliance'] == 'non-ducted heat pump')]
        voltage = list(cooling['voltage'])[0]
        coef1 = float(list(cooling['amperage'])[0].split(',')[0])
        coef2 = float(list(cooling['amperage'])[0].split(',')[1])
        intercept = float(list(cooling['amperage'])[0].split(',')[2])
        seer = float(heating_eff.split(',')[1].split(' ')[2])   
        return (coef1*nom_cool_cap + coef2*seer + intercept) * voltage
    if system_type == "Central AC":
        cooling = nameplate_power_rating.loc[(nameplate_power_rating['load_category'] == 'space cooling') & (nameplate_power_rating['appliance'] == 'central ac')]
        voltage = list(cooling['voltage'])[0]
        coef1 = float(list(cooling['amperage'])[0].split(',')[0])
        coef2 = float(list(cooling['amperage'])[0].split(',')[1])
        intercept = float(list(cooling['amperage'])[0].split(',')[2])
        seer = float(cooling_eff.split(',')[1].split(' ')[2])   
        return (coef1*nom_cool_cap + coef2*seer + intercept) * voltage
    if system_type == "Room AC":
        cooling = nameplate_power_rating.loc[(nameplate_power_rating['load_category'] == 'space cooling') & (nameplate_power_rating['appliance'] == 'room ac')]
        voltage = list(cooling['voltage'])[0]
        coef1 = float(list(cooling['amperage'])[0].split(',')[0])
        coef2 = float(list(cooling['amperage'])[0].split(',')[1])
        intercept = float(list(cooling['amperage'])[0].split(',')[2])
        eer = float(cooling_eff.split(',')[1].split(' ')[2])
        seer =  eer/0.875
        return (coef1*nom_cool_cap + coef2*seer + intercept) * voltage

    return nom_cool_cap * KBTU_H_TO_W


def _special_load_space_heating(row):
    if row["completed_status"] != "Success":
        return np.nan

    if ((row["build_existing_model.heating_fuel"] == "Electricity") | (
        "ASHP" in row["build_existing_model.hvac_heating_efficiency"]
        ) | (
        "MSHP" in row["build_existing_model.hvac_heating_efficiency"]
        ) | (
        "GSHP" in row["build_existing_model.hvac_heating_efficiency"]
        ) | (
        "Electric" in row["build_existing_model.hvac_heating_efficiency"]
        ) | (
        "Electricity" in row["build_existing_model.hvac_shared_efficiencies"]
        )): 

        heating_cols = [
            row["upgrade_costs.size_heating_system_primary_k_btu_h"],
            row["upgrade_costs.size_heating_system_secondary_k_btu_h"],
            row["upgrade_costs.size_heat_pump_backup_primary_k_btu_h"]
            ]
        system_cols = [
            row["build_existing_model.hvac_heating_type"],
            row["build_existing_model.hvac_secondary_heating_efficiency"],
            "Electric", # TODO this depends on package
            ]
        
        heating_eff = row["build_existing_model.hvac_heating_efficiency"]

        heating_load = sum(
            [hvac_heating_conversion(x, heating_eff, system_type=y) for x, y in zip(heating_cols, system_cols)]
        )
    else:
        heating_load = 0

    if row["build_existing_model.hvac_has_ducts"] == "Yes":
        heating_load += hvac_fan_motor

    return heating_load


def _special_load_space_cooling(row):
    if row["completed_status"] != "Success":
        return np.nan, False

    cooling_load = hvac_cooling_conversion(
        row["upgrade_costs.size_cooling_system_primary_k_btu_h"],
        row["build_existing_model.hvac_heating_efficiency"],
        row["build_existing_model.hvac_cooling_efficiency"],
        system_type=row["build_existing_model.hvac_heating_type"]
    )
    cooling_motor = cooling_load
    cooling_is_window_unit = True
    if row["build_existing_model.hvac_has_ducts"] == "Yes":
        cooling_load += hvac_fan_motor + hvac_blower_motor
        cooling_is_window_unit = False

    if cooling_is_window_unit:
        cooling_motor /= (int(row["build_existing_model.bedrooms"]) + 1)
    
    return cooling_load, cooling_motor


def _special_load_space_conditioning(row):
    """Heating or Air Conditioning. NEC 220-19.
    Take the larger between heating and cooling. Demand Factor = 1
    Include the air handler when using either one. (guessing humidifier too?)
    For heat pumps, include the compressor and the max. amount of electric heat which can be energized with the compressor running

    1 Btu/h = 0.29307103866W

    Returns:
        max(loads) : int
            special_load_for_heating_or_cooling
        cooling_motor : float
            size of cooling motor,
            = size_cooling_system_primary if central
            = approximate size of window AC if not central
            = 0 when heating is max load
    """
    if row["completed_status"] != "Success":
        return np.nan, np.nan

    heating_load = _special_load_space_heating(row)
    cooling_load, cooling_motor = _special_load_space_cooling(row)
    
    # combine
    loads = np.array([heating_load, cooling_load])

    return max(loads), cooling_motor # Always include cooling motor in largest motor at 25%


def _special_load_motor(row):
    """Largest motor (only one). NEC 220-14, 430-24
    Multiply the largest motor volt-amps x 25%
    Usually the air-conditioner compressor is the largest motor. Use if special_load is space cooling.
    Else use he next largest motor, usually garbage disposal
    """
    if row["completed_status"] != "Success":
        return np.nan

    _, cooling_motor = _special_load_space_conditioning(row)

    motor_size = max(
        cooling_motor,
        _fixed_load_garbage_disposal(row),
        _special_load_pool_pump(row, apply_df=False),
        _fixed_load_well_pump(row),
    )

    return 0.25 * motor_size


def _special_load_pool_heater(row, apply_df=True): # This is a continuous load so 125% factor must be applied
    """NEC 680.9
    https://twphamilton.com/wp/wp-content/uploads/doc033548.pdf
    """
    if row["completed_status"] != "Success":
        return np.nan
    
    pool_heater = nameplate_power_rating.loc[(nameplate_power_rating['load_category'] == 'pool heater') & (nameplate_power_rating['appliance'] == 'electric')]
    pool_heater_power_rating = list(pool_heater['volt-amps'])[0]

    if isinstance(row["build_existing_model.misc_pool_heater"], str) and "Electric" in row["build_existing_model.misc_pool_heater"]:
        return pool_heater_power_rating
    return 0


def _special_load_pool_pump(row, apply_df=True):
    """NEC 680
    Pool pump (0.75-1HP), 15A or 20A, 120V or 240V
    1HP = 746W
    """
    if row["completed_status"] != "Success":
        return np.nan
    pool_pump_1hp = nameplate_power_rating.loc[(nameplate_power_rating['load_category'] == 'pool pump') & (nameplate_power_rating['appliance'] == 'electric, 1.0 hp')]
    pool_pump_1hp_power_rating = list(pool_pump_1hp['volt-amps'])[0]
    pool_pump_three_quaters = nameplate_power_rating.loc[(nameplate_power_rating['load_category'] == 'pool pump') & (nameplate_power_rating['appliance'] == 'electric, 0.75 hp')]
    pool_pump_three_quaters_power_rating = list(pool_pump_three_quaters['volt-amps'])[0]

    if row["build_existing_model.misc_pool_pump"] == "1.0 HP Pump":
        return pool_pump_1hp_power_rating #TODO: Once an estimate has been established we can use Table 430.247 to determine connected load
    if row["build_existing_model.misc_pool_pump"] == "0.75 HP Pump":
        return pool_pump_three_quaters_power_rating #TODO: Once an estimate has been established we can use Table 430.247 to determine connected load
    return 0


def _special_load_EVSE(row):
    if row["completed_status"] != "Success":
        return np.nan
    EVSE = nameplate_power_rating.loc[(nameplate_power_rating['load_category'] == 'electric vehicle charger') & (nameplate_power_rating['appliance'] == 'electric')]
    EVSE_power_rating = list(EVSE['volt-amps'])[0]

    if row["build_existing_model.electric_vehicle"] == "None":
        EV_load = 0
    else: 
        EV_load = EVSE_power_rating # TODO: Insert EV charger load, NEC code says use max of nameplate rating and 7200 W
    return EV_load


def optional_special_load_space_conditioning(row, new_load_calc=False):
    if row["completed_status"] != "Success":
        return np.nan

    AC_load = hvac_cooling_conversion(
        row["upgrade_costs.size_cooling_system_primary_k_btu_h"],
        row["build_existing_model.hvac_heating_efficiency"],
        row["build_existing_model.hvac_cooling_efficiency"],
        row["build_existing_model.hvac_cooling_type"]
        )

    if row["build_existing_model.hvac_has_ducts"] == "Yes":
            AC_load += hvac_fan_motor + hvac_blower_motor
    
    # TODO: shared efficiency -- if not being counted, remove load from peak
    if ((row["build_existing_model.heating_fuel"] == "Electricity") | (
            "ASHP" in row["build_existing_model.hvac_heating_efficiency"]
            ) | (
            "MSHP" in row["build_existing_model.hvac_heating_efficiency"]
            ) | (
            "GSHP" in row["build_existing_model.hvac_heating_efficiency"]
            ) | (
            "Electric" in row["build_existing_model.hvac_heating_efficiency"]
            ) | (
            "Electricity" in row["build_existing_model.hvac_shared_efficiencies"]
            )): 
        heating_cols = [
            row["upgrade_costs.size_heating_system_primary_k_btu_h"],
            row["upgrade_costs.size_heating_system_secondary_k_btu_h"],
            row["upgrade_costs.size_heat_pump_backup_primary_k_btu_h"]
            ]
        system_cols = [
            row["build_existing_model.hvac_heating_type"],
            row["build_existing_model.hvac_secondary_heating_efficiency"],
            "Electric",
            ]
        fractions = [1, 0.65, 0.65]

        heating_eff = row["build_existing_model.hvac_heating_efficiency"]

        heating_load = sum(
            [hvac_heating_conversion(x, heating_eff, system_type=y,)*z for x, y, z in zip(heating_cols, system_cols, fractions)]
        )
    else:
        heating_load = 0
    if row["build_existing_model.hvac_has_ducts"] == "Yes":
        heating_load += hvac_fan_motor
    
    if row["build_existing_model.hvac_has_zonal_electric_heating"] == "Yes":
        # only applies to "Electric Baseboard, 100% Efficiency"
        sep_controlled_heaters = hvac_heating_conversion(
                row["upgrade_costs.size_heating_system_primary_k_btu_h"],
                row["build_existing_model.hvac_heating_efficiency"],
                row["build_existing_model.hvac_heating_type"]
                )
        if new_load_calc:
            demand_factor_sch_less_than_four = 1
        else:
            demand_factor_sch_less_than_four  = 0.65
        demand_factor_sch_four_plus = demand_factor_sch_less_than_four * (0.4/0.65)
        if  int(row["build_existing_model.bedrooms"]) >= 3: # determine number of individually controlled heating units using number of bedrooms, assuming total = # bedrooms + 1
            sep_controlled_heaters *= demand_factor_sch_four_plus
        else: 
            sep_controlled_heaters *= demand_factor_sch_less_than_four
    else:
        sep_controlled_heaters = 0

    continous_heat = 0 # TODO: Determine if we would like to include continuous heat and how to estimate it (NEC 220.82(C)(6) 
    
    space_cond_loads = [
        AC_load, # 100% of AC load (use cooling system primary btu)
        heating_load, # 100% of heating load in absence of supplemental heat or 100% of heating load primary and 65% of secondary or backup heat
        sep_controlled_heaters, # 65% of nameplate of less than 4 seperately controlled heating units, 40% of nameplate of 4 of more seperately controlled heating units
        continous_heat # 100% of electric heat storage or other continuous heating load, assume this to be zero
    ]
    
    return (max(space_cond_loads))


def standard_amperage(x: float) -> int:
    """Convert min_amp_col into standard panel size
    http://www.naffainc.com/x/CB2/Elect/EHtmFiles/StdPanelSizes.htm
    """
    if pd.isnull(x):
        return np.nan

    standard_sizes = np.array([
        50, 100, 125, 150, 200, 225,
        250])
    standard_sizes = np.append(standard_sizes, np.arange(300, 1250, 50))
    factors = standard_sizes / x

    cond = standard_sizes[factors >= 1]
    if len(cond) == 0:
        print(
            f"WARNING: {x} is higher than the largest standard_sizes={standard_sizes[-1]}, "
            "double-check NEC calculations"
        )
        return math.ceil(x / 100) * 100

    return cond[0]


def read_file(filename: str, low_memory: bool =True, **kwargs) -> pd.DataFrame:
    """ If file is large, use low_memory=False"""
    filename = Path(filename)
    if filename.suffix == ".csv":
        df = pd.read_csv(filename, low_memory=low_memory, keep_default_na=False, **kwargs)
    elif filename.suffix == ".parquet":
        df = pd.read_parquet(filename, **kwargs)
    else:
        raise TypeError(f"Unsupported file type, cannot read file: {filename}")

    return df


def bin_panel_sizes(df_column: pd.Series) -> pd.Series:
    df_out = df_column.copy()
    df_out.loc[df_column<100] = "<100"
    df_out.loc[(df_column>100) & (df_column<200)] = "101-199"
    df_out.loc[df_column>200] = "200+"
    df_out = df_out.astype(str)

    return df_out


def generate_plots(df: pd.DataFrame, output_dir: Path, sfd_only: bool = False):
    msg = " for Single-Family Detached only" if sfd_only else ""
    print(f"generating plots{msg}...")
    _plot_scatter(df, "existing_amp_220_83", "existing_amp_220_87", title=None, output_dir=output_dir, sfd_only=sfd_only)
    for metric in ["existing_amp_220_83", "existing_amp_220_87"]:
        for hc in [
        "build_existing_model.census_region",
        "build_existing_model.census_division",
        "build_existing_model.ashrae_iecc_climate_zone_2004",
        "build_existing_model.geometry_building_type_recs",  # dep
        "build_existing_model.state",
        # "build_existing_model.vintage",  # dep
        "build_existing_model.vintage_acs",
        "build_existing_model.federal_poverty_level",
        "build_existing_model.area_median_income",
        "build_existing_model.tenure",
        "build_existing_model.geometry_floor_area_bin",
        # "build_existing_model.geometry_floor_area",  # dep
        "build_existing_model.heating_fuel",  # dep
        "build_existing_model.water_heater_fuel",  # dep
        "build_existing_model.hvac_heating_type",
        "build_existing_model.hvac_cooling_type",  # dep
        ]:
            _plot_box(df, metric, hc, output_dir=output_dir, sfd_only=sfd_only)
    print(f"plots output to: {output_dir}")
    


### -------- new load calcs --------
def apply_existing_load_total_220_83(dfi: pd.DataFrame, new_hvac_loads: pd.Series, n_kit: int = 2, n_ldr: int = 1, explode_result: bool = False) -> pd.DataFrame:
    """
    NEC 220.83 - Load summing method
    Use NEC 220.83 (A) (has_new_hvac_load=False) for existing + additional new loads calc 
    where additional AC or space-heating IS NOT being installed
    
    Use NEC 220.83 (B) (has_new_hvac_load=True) existing + additional new loads calc
    where additional AC or space-heating IS being installed

    new_hvac_loads: pd.Series indicating where dfi rows has new electric HVAC loads
    """

    df = dfi.copy()

    result_type = "expand" if explode_result else None
    labels = existing_load_total_220_83_labels(include_intermediate_result_labels=explode_result)

    for cond, new_hvac in zip(
        [~new_hvac_loads, new_hvac_loads],
        [False, True]
        ):
        if cond.sum() > 0:
            df.loc[cond, labels] = df.loc[cond].apply(
                lambda x: existing_load_total_220_83(x, n_kit=n_kit, n_ldr=n_ldr, has_new_hvac_load=new_hvac, include_intermediate_results=explode_result), 
                axis=1, result_type=result_type).values

    # convert to amp
    total_load_label = df.columns[-1]
    df["existing_amp_220_83"] = df[total_load_label] / 240

    return df

def existing_load_total_220_83_labels(include_intermediate_result_labels: bool = False) -> str | list[str]:
    hvac_load_label = "load_hvac"
    other_loads_labels = [
        "load_lighting",
        "load_kitchen",
        "load_laundry",
        "load_water_heater",
        "load_dishwasher",
        "load_dryer",
        "load_range_oven",
        "load_garbage_disposal",
        "load_garbage_compactor",
        "load_hot_tub_spa",
        "load_well_pump",
        "load_pool_heater",
        "load_pool_pump",
        "load_evse"
    ]
    total_load_label = "existing_load_total_VA"
    if include_intermediate_result_labels:
        return [hvac_load_label] + other_loads_labels + [total_load_label]
    return total_load_label


def existing_load_total_220_83(row, n_kit: int = 2, n_ldr: int = 1, has_new_hvac_load: bool = False, include_intermediate_results: bool = False) -> float | list[float]:
    """ Load summing method """
    if row["completed_status"] != "Success":
        return np.nan

    hvac_load, _ = _special_load_space_conditioning(row) # max of heating or cooling
    
    other_loads = [
            _general_load_lighting(row), # sqft
            _general_load_kitchen(row, n=n_kit), # consider logic based on sqft
            _general_load_laundry(row, n=n_ldr), # consider logic based on sqft (up to 2)
            _fixed_load_water_heater(row),
            _fixed_load_dishwasher(row),
            _special_load_electric_dryer(row),
            _special_load_electric_range_nameplate(row),
            _fixed_load_garbage_disposal(row),
            _fixed_load_garbage_compactor(row),
            _fixed_load_hot_tub_spa(row),
            _fixed_load_well_pump(row),
            _special_load_pool_heater(row),
            _special_load_pool_pump(row),
            _special_load_EVSE(row)
        ] # no largest motor load

    threshold_load = 8000 # VA
    if has_new_hvac_load:
        # 100% HVAC load + 100% of 1st 8kVA other_loads + 40% of remainder other_loads
        total_load = hvac_load + apply_demand_factor(sum(other_loads), threshold_load=threshold_load)

    else:
        # 100% of 1st 8kVA all loads + 40% of remainder loads
        total_load = apply_demand_factor(hvac_load + sum(other_loads), threshold_load=threshold_load)
    total_load_label = "existing_load_total_VA"

    if include_intermediate_results:
        return [hvac_load] + other_loads + [total_load]

    return total_load


def apply_existing_load_total_220_87(df: pd.DataFrame) -> pd.DataFrame:
    """ Maximum demand method """
    df["existing_amp_220_87"] = df["qoi_report.qoi_peak_magnitude_use_kw"] * 1000 / 240 * 1.25 # amp
    df.loc[df["build_existing_model.vacancy_status"]=="Vacant", "existing_amp_220_87"] = np.nan

    return df


def main_existing_load(filename: str | None = None, plot_only: bool = False, sfd_only: bool = False, explode_result: bool = False):
    if filename is None:
        filename = (
            Path(__file__).resolve().parent
            / "test_data"
            / "euss1_2018_results_up00_100.csv" # "euss1_2018_results_up00_400plus.csv"
        )
    else:
        filename = Path(filename)

    ext = ""
    if explode_result:
        ext = "_exploded"
    output_filename = filename.parent / (filename.stem + f"__existing_load{ext}" + ".csv")

    plot_dir_name = f"plots_sfd" if sfd_only else f"plots"
    output_dir = filename.parent / plot_dir_name / "nec_calculations"
    output_dir.mkdir(parents=True, exist_ok=True) 

    if plot_only:
        if not output_filename.exists():
            raise FileNotFoundError(f"Cannot create plots, output_filename not found: {output_filename}")
        df = read_file(output_filename, low_memory=False)
        for col in ["existing_amp_220_83", "existing_amp_220_87"]:
            df[col] = df[col].replace("", np.nan).astype(float)
        generate_plots(df, output_dir, sfd_only=sfd_only)
        sys.exit()
        
    df = read_file(filename, low_memory=False)

    # reduce df
    peak_cols = [
                    "report_simulation_output.peak_electricity_summer_total_w",
                    "report_simulation_output.peak_electricity_winter_total_w",
                    "qoi_report.qoi_peak_magnitude_use_kw",
                ]
    cols_to_keep = [
        "building_id", "completed_status", "build_existing_model.sample_weight", 
        "report_simulation_output.unmet_hours_cooling_hr", "report_simulation_output.unmet_hours_heating_hr"
        ]
    cols_to_keep += get_housing_char_cols(search=False, get_ami=True)+peak_cols+[col for col in df.columns if col.startswith("upgrade_costs.")]
    df = df[cols_to_keep]

    # --- NEW LOAD calc: existing loads ---
    # NEC 220.83 - Load Summing Method
    new_hvac_loads = pd.Series(False, index=df.index)
    df = apply_existing_load_total_220_83(df, new_hvac_loads, n_kit=2, n_ldr=1, explode_result=explode_result)

    # NEC 220.87 - Maximum Demand Method
    df = apply_existing_load_total_220_87(df)

    # --- save to file ---
    df.to_csv(output_filename, index=False)
    print(f"File output to: {output_filename}")

    generate_plots(df, output_dir, sfd_only=sfd_only)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "filename",
        action="store",
        default=None,
        nargs="?",
        help="Path to ResStock result file, e.g., results_up00.csv, "
        "defaults to test data: test_data/euss1_2018_results_up00_100.csv"
        )
    parser.add_argument(
        "-p",
        "--plot_only",
        action="store_true",
        default=False,
        help="Make plots only based on expected output file without regenerating output_file",
    )

    parser.add_argument(
        "-d",
        "--sfd_only",
        action="store_true",
        default=False,
        help="Apply calculation to Single-Family Detached only (this is only on plotting for now)",
    )
    parser.add_argument(
        "-x",
        "--explode_result",
        action="store_true",
        default=False,
        help="Whether to export intermediate calculations as part of the results (useful for debugging)",
    )

    args = parser.parse_args()
    main_existing_load(args.filename, plot_only=args.plot_only, sfd_only=args.sfd_only, explode_result=args.explode_result)
