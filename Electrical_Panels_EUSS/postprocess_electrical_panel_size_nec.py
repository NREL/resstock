"""
Electrical Panel Project: Estimate panel capacity using NEC (2023)
Standard method: 220 Part III. Feeder and Service Load Calculations
Optional method: 220 Part IV. Optional Feeder and Service Load Calculations

NEC panel capacity = min. main circuit breaker size (A)

By: Lixi.Liu@nrel.gov
Date: 02/01/2023

Updated: Ilan.Upfal@nrel.gov
Date: 3/3/2023

-----------------
kW = kVA * PF, kW: working (active) power, kVA: apparent (active + reactive) power, PF: power factor
For inductive load, use PF = 0.8 (except cooking per 220.55, PF=1)

Continous load := max current continues for 3+ hrs
Branch circuit rating for continous load >= 1.25 x nameplate rating

-----------------

STANDARD LOAD CALCULATION METHOD:

Overview:
Total Demand Load = General Load + Fixed Load + Special Load
Total Amperage = Total Demand / Circuit Voltage

Electrical circuit voltage = 
    * 240V for single-phase 120/240V service (most common)
    * 208V for three-phase 208/120V service

* General Load: 
    - lighting/recepticles + kitchen general + laundry general
    - Includes bathroom exhaust fans, most ceiling fans
    - Tiered demand factors for total General Load
* Fixed (fastened-in-place) Appliance Load: 
    - Water heater, dishwasher, garbage disposal, garbage compactor, 
    - Attic fan, central vacumm systems, microwave ...
    - At least 1/4 HP (500W), permanently fastened in place
    - ALWAYS exclude 3 special appliances: dryer, range, space heating & cooling 
    - Demand factor for total Fixed Load based on # of >=500W fixed appliances
* Special Appliance Load:
    - Clothes dryer, 
    - Range/oven,
    - Larger of space heating or cooling, 
    - Motor (usually AC compressor if cooling is larger, next is garbage disposal)
    - Hot tub (1.5-6kW + 1.5kW water pump), pool heater (~3kW), pool pump (0.75-1HP), well pump (0.5-5HP)
    - Demand factor depends on special appliance

Detailed description:
1. General Lighting and Receptacle Load (NEC 220.41):
    *general lighting:
        accounts for:
            - general-use receptacle outlets of 20 A including dedicated branch circuits for bathrooms, countertops, work surfaces and garages
            - outdoor receptacle outlets
            - lighting outlets
            - motors less than 1/8 hp and connected to lighting circuit
        floor area is defined as:
            - outside dimensions of dwelling unit
            - excludes "open porches or unfinished areas not adaptable for future use as a habitable room or occupiable space"
            - includes garage as of 2023
        general lighting load = 3 VA/ft^2

    *small appliance circuit load (NEC 220.52)
        small-appliance circuit load (NEC 220.52 (A))
            - 1500 VA per 2-wire small-appliance circuit
            - minimum of 2 small-appliance circuits per dwelling (NEC 210.11 (C)(1))
        laundry circuit load (NEC 220.52 (B))
            - 1500 VA per 2-wire small-appliance circuit
            - minimum of 1 laundry circuit per dwelling (NEC 210.11 (C)(1))

    *demand factor (NEC 220.45)
        - Up to 3,000 VA @ 100%
        - 3,000 VA to 120,000 VA @ 35%
        - Over 120,000 VA @ 25%

2. Special loads:
    *electric cooking appliances (NEC 220.55)
        applies to:
            - cooking appliances which are fastened in place and rated above 1750 W
        home with single cooking appliance: (Table 220.55)
            - for 1 appliance rated @ 12 kW or less: demand load = 8 kW or nameplate rating
            - for 1 appliance rated over 12 kW: add 5% onto 8 kW per additional kW over 8 kW
        home with multiple cooking appliances: (Table 220.55)
            - if all same rating: same as above
            - if different ratings: group by less than 3 1/2 and over 3 1/2 and apply relevant demand factors

    *dryer (NEC 220.54)
        Load is either 5 kW (VA) or nameplate rating whichever is greater for each dryer
        DF of 100% for first 4 dryers, 85% for 5th, 75% for 6th ...
    
    *space heating and air-conditioning
        omit the smaller of the heating and cooling loads (NEC 220.60)
        space heating (220.51)
            - applies to fixed space heating
            - 100% of connected load
        air-conditioning equipment (NEC 220.50 (B))
            - use full load

    *electric vehicle supply equipment (NEC 220.57)
        - 7200 W or nameplate rating whichever is larger
        - continuous load
        - Level 1 (slow): 1.2kW @ 120V (no special circuit) - receptacle plugs
        - Level 2 (fast): 6.2-19.2kW (7.6kW avg) @ 240V (likely dedicated circuit)
            -> same as 240V appliance plugs
            -> 80% of installed chargers are Level 2 (Market share in residential)

    *add 25% of largest motor load not already included (NEC 440.33)
    
3. Appliance load (NEC 220.53)
    applies to:
        - fastened in place appliances
        - 1/4 hp or greater, or 500 W or greater
    apply a demand factor of 75% if 4 or more
    125% for continuous loads

OPTIONAL METHOD: (NEC 220.82)
    applies to dwellings with min 100 A service
    first 10 kVA at 100% and reminader at 40% of sum of:
        - 3 VA/ft^2 for outside dimensions of dwelling not including garage, unfinished porches, unused or unfinished spaces
        - 1500 VA per laundry and small appliance branch
        - nameplate rating of:
            - fastened in place appliances, permanently connected or on specific circuit
            - ranges, wall-mounted ovens, counter-mounted cooking units
            - clothes dryers not connected to laundry circuit
            - water heaters
            - all permanenty connected motors not listed in this section
    and largest of:
        - 100% of nameplate of A\C
        - 100% of nameplate of heat pump with no supplemental heating
        - 100% of nameplate of heat pump compressor and 65% of supplemental electric heat for central space-heating system unless they are prevented from running simultaneously
        - 65% of nameplate rating of electric space heating if less than four seperately controlled units
        - 40% of nameplate rating of electric space heat if more than four seperately controlled units 
        - 100% of nameplate rating of electric thermal storage or other heating sustme which is expected to run continuously at max load
"""

import pandas as pd
from pathlib import Path
import numpy as np
import math
import sys
import matplotlib.pyplot as plt

# --- lookup ---
geometry_unit_aspect_ratio = {
    "Single-Family Detached": 1.8,
    "Single-Family Attached": 0.5556,
    "Multi-Family with 2 - 4 Units": 0.5556,
    "Multi-Family with 5+ Units": 0.5556,
    "Mobile Home": 1.8,
} #  = front_back_length / left_right_width #TODO: check to see if it gets recalculated

# --- funcs ---

def apply_demand_factor_to_general_load(x):
    """
    Split load into the following tiers and apply associated multiplier factor
        <= 3kVA : 1.00
        > 3kVA & <= 120kVA : 0.35
        > 120kVA : 0.25
    """
    return (
        1 * min(3000, x)
        + 0.35 * (max(0, min(120000, x) - 3000))
        + 0.25 * max(0, x - 120000)
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
            garage_width = np.nan
            print("Error determine garage area")
    
    floor_area = row["upgrade_costs.floor_area_conditioned_ft_2"] + garage_width*garage_depth
    min_unit_load = 3 * floor_area

    # calculate based on perimeter of footprint with receptables at every 6-feet
    aspect_ratio = geometry_unit_aspect_ratio[row["build_existing_model.geometry_building_type_recs"]]
    fb_length = math.sqrt(floor_area * aspect_ratio)
    lr_width = floor_area / fb_length
    n_receptables = 2*(fb_length+lr_width) // 6

    receptable_load = n_receptables * 20*120 # 20-Amp @ 120V
    # TODO: add other potential unit loads

    return min_unit_load

def _optional_load_lighting(row): 
    """Not including open porches, garages, unused or unfinished spaces not adaptable for future use"""
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

        Type of dryers affect voltage service and # of circuits

    Args:
        n: int | "auto"
            number of branches for general laundry load (exclude dryer), minimum 1
    """
    if row["completed_status"] != "Success":
        return np.nan

    if n == "auto":
        # TODO, can expand based on floor_area, vintage, etc
        n = 1

    if n < 1:
        raise ValueError(f"n={n}, at least 1 laundry branch circuit for General Load")
    """
    if (row["build_existing_model.clothes_washer_presence"] == "Yes") or (
        row["build_existing_model.clothes_dryer"] != "None"
    ):
        return n * 1500 """ # This is incorrect, code requires 1 laundry branch circuit regardless of dryer type
    return n* 1500

def general_load_total(row, n_kit=2, n_ldr=1):
    """Total general load, has tiered demand factors
        General load: 15-20A breaker / branch, 120V

    Args:
        n_kit: int | "auto"
            number of branches for small appliances, minimum 2
        n_ldr: int | "auto"
            number of branches for general laundry load (exclude dryer), minimum 1
    """
    if row["completed_status"] != "Success":
        return np.nan

    general_loads = [
        _general_load_lighting(row),
        _general_load_kitchen(row, n=n_kit),
        _general_load_laundry(row, n=n_ldr),
    ]
    return apply_demand_factor_to_general_load(sum(general_loads))

def _fixed_load_water_heater(row):
    """
    Add water heater load if electric and in-unit
        - all electric storage and heat pump storage: 4500W (240V, 30A breaker), HomeDepot
        - electric tankless: 20000-36000W (27000W avg) (240V, takes 3x50A or 4x50A breakers), HomeDepot
    """
    if row["completed_status"] != "Success":
        return np.nan

    if (row["build_existing_model.water_heater_in_unit"] == "Yes") & (
        row["build_existing_model.water_heater_fuel"] == "Electricity"
    ):
        if row["build_existing_model.water_heater_efficiency"] == "Electric Tankless":
            return 27000
        return 4500
    return 0

def _fixed_load_dishwasher(row):
    """
    Dishwasher: 12-15A, 120V
        Amperage not super correlated with kWh rating, but will assume 12A for <=255kWh, and 15A else
    """
    if row["completed_status"] != "Success":
        return np.nan

    if row["build_existing_model.dishwasher"] == "None":
        return 0
    if (
        "270" in row["build_existing_model.dishwasher"]
        or "290" in row["build_existing_model.dishwasher"]
        or "318" in row["build_existing_model.dishwasher"]
    ):
        return 15 * 120
    return 12 * 120

def _fixed_load_garbage_disposal(row):
    """
    garbage disposal: 0.8 - 1.5 kVA (1.2kVA avg), typically second largest motor, after AC compressor

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
        if row["build_existing_model.geometry_floor_area"] in ["0-499"]:
            return 0
        elif row["build_existing_model.geometry_floor_area"] in ["500-749", "750-999"]:
            return 800  # 1/3 HP
        elif row["build_existing_model.geometry_floor_area"] in [
            "1000-1499",
            "1500-1999",
            "2000-2499",
        ]:
            return 1200  # 1/2 HP @ 115V from NEC Table 430-149 #TODO: Table 430.149 no longer exists, see Table 430.247
        else:
            return 1500
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

def _fixed_load_hot_tub_spa(row): # Not a continuous load, but some inconsistency on this
    """
    Hot tub (1.5-6kW + 1.5kW water pump)
    """
    if row["completed_status"] != "Success":
        return np.nan

    if row["build_existing_model.misc_hot_tub_spa"] == "Electric":
        return 4500  # or 8000 (2HP)
    return 0

def _fixed_load_well_pump(row): # Not a continuous load
    """NEC 680
    Well pump (0.5-5HP)
    1HP = 746W
    """
    if row["completed_status"] != "Success":
        return np.nan

    # TODO: verify
    if row["build_existing_model.misc_well_pump"] == "National Average":
        return 0.127 * 746  # based on usage multiplier in options_lookup #TODO: Once an estimate has been established we can use Table 430.247 to determine connected load
    if row["build_existing_model.misc_well_pump"] == "Typical Efficiency":
        return 1 * 746  # based on usage multiplier in options_lookup #TODO: Once an estimate has been established we can use Table 430.247 to determine connected load
    if row["build_existing_model.misc_well_pump"] == "High Efficiency":
        return 0.67 * 746  # based on usage multiplier in options_lookup #TODO: Once an estimate has been established we can use Table 430.247 to determine connected load
    return 0

def fixed_load_total(row):
    """Fastened-In-Place Appliances. NEC 220-17
    Use nameplate rating. Do not include electric ranges, clothes dryers, space-heating or A/C equipment

    Sum(fixed_load) * Demand Factor (1.0 if number of fixed_load < 4 else 0.75)
    In 2020 NEC, only count appliances rated at least 1/4HP or 500W
    """
    if row["completed_status"] != "Success":
        return np.nan

    fixed_loads = np.array(
        [
            _fixed_load_water_heater(row),
            _fixed_load_dishwasher(row),
            _fixed_load_garbage_disposal(row),
            _fixed_load_garbage_compactor(row),
            _fixed_load_hot_tub_spa(row),
            _fixed_load_well_pump(row),
        ]
    )

    n_fixed_loads = len(fixed_loads[fixed_loads >= 500])
    demand_factor = 1 if n_fixed_loads < 4 else 0.75

    return sum(fixed_loads) * demand_factor

def _special_load_electric_dryer(row):
    """Clothes Dryers. NEC 220-18
    Use 5000 watts or nameplate rating whichever is larger (in another version, use DF=1 for # appliance <=4)
    240V, 22/24/30A breaker (vented), 30/40A (ventless heat pump), 30A (ventless electric)
    """
    if row["completed_status"] != "Success":
        return np.nan

    if "Electric" not in row["build_existing_model.clothes_dryer"]:
        return 0

    if "Ventless" in row["build_existing_model.clothes_dryer"]:
        rating = 30 * 240
    else:
        rating = 24 * 240

    return max(5000, rating)

def _special_load_electric_range(row): # Assuming a single electric range (combined oven/stovetop) for each dwelling unit
    if row["completed_status"] != "Success":
        return np.nan

    if "Electric" not in row["build_existing_model.cooking_range"]:
        range_power = 0

    if "Induction" in row["build_existing_model.cooking_range"]:
        # range-oven: 10-13.6kW rating (240V, 40A) or 8.4kW (240V, 50A) or 8kW (240V, 40A)
        # cooktop: 11-12kW rating (240V, 30/50A) or 15.4kW rating (240V, 40A), 7.2-8.6kW (240V, 30/45A)
        # electric wall oven: 4.5kW (120V, 30A or 240V, 20/30A)
        # For induction cooktop + electric wall oven = 11+0.65*4.5 = 14kW 
        range_power = 12500  # 40*240 or 14000 #TODO: This should be the full nameplate rating (max connected load) of an electric induction range

    ## Electric, non-induction
    # range-oven: 10-12.1-13.5kW (240V, 40A)
    # cooktop: 9.2kW (240V, 40A), 7.7-10.5kW (240V, 40/50A), 7.4kW (240V, 40A)
    # For cooktop + wall oven = 11+0.65*4.5 = 14kW or 0.65*(8+4.5) = 8kW
    range_power = 10000  # or 12500 #TODO: This should be the full nameplate rating (max connected load) of an electric non-induction range

    if range_power <= 8000:
        range_power_w_df = min(8000,range_power)
    else:
        range_power_w_df = 8000 * (1 + 400*(max(0,range_power-12000)))
    
    return range_power_w_df

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
        return np.nan

    if row["build_existing_model.heating_fuel"] == "Electricity":
        heating_load = (
            row["upgrade_costs.size_heating_system_primary_k_btu_h"]
            + row["upgrade_costs.size_heating_system_secondary_k_btu_h"]
            + row["upgrade_costs.size_heat_pump_backup_primary_k_btu_h"]
        ) * 293.07103866
    else:
        heating_load = 0

    if row["build_existing_model.hvac_heating_type"].startswith("Ducted"):
        heating_load += 3 * 115  # 3A x 115V (air-handler motor) TODO: Check this value

    cooling_load = (
        row["upgrade_costs.size_cooling_system_primary_k_btu_h"] * 293.07103866
    )
    cooling_motor = cooling_load
    cooling_is_window_unit = True
    if row["build_existing_model.hvac_cooling_type"] == "Central AC" or (
        row["build_existing_model.hvac_heating_type"].startswith("Ducted")
        and row["build_existing_model.hvac_cooling_type"] == "Heat Pump"
    ):
        cooling_load += (
            3 * 115 + 460
        )  # 3A x 115V (condenser fan motor) + 460 (blower motor) TODO: Check this value
        cooling_is_window_unit = False

    loads = np.array([heating_load, cooling_load])

    if cooling_is_window_unit:
        cooling_motor /= (row["build_existing_model.bedrooms"] + 1)
    else:
        cooling_motor = cooling_load

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
        _special_load_pool_pump(row),
        _fixed_load_well_pump(row),
    )

    return 0.25 * motor_size

def _special_load_pool_heater(row): # This is a continuous load so 125% factor must be applied
    """NEC 680.9
    Pool heater (~3kW), is considered continous load, demand factor = 1.25
    https://twphamilton.com/wp/wp-content/uploads/doc033548.pdf
    """
    if row["completed_status"] != "Success":
        return np.nan

    if row["build_existing_model.misc_pool_heater"].startswith("Electric"):
        return 3000 * 1.25
    return 0

def _special_load_pool_pump(row):
    """NEC 680
    Pool pump (0.75-1HP), 15A or 20A, 120V or 240V
    1HP = 746W
    """
    if row["completed_status"] != "Success":
        return np.nan

    if row["build_existing_model.misc_pool_pump"] == "1.0 HP Pump":
        return 1.25* 1 * 746 #TODO: Once an estimate has been established we can use Table 430.247 to determine connected load
    if row["build_existing_model.misc_pool_pump"] == "0.75 HP Pump":
        return 1.25 * 0.75 * 746 #TODO: Once an estimate has been established we can use Table 430.247 to determine connected load
    return 0

def special_load_total(row):
    if row["completed_status"] != "Success":
        return np.nan

    space_cond_load, _ = _special_load_space_conditioning(row)
    special_loads = sum(
        [
            _special_load_electric_dryer(row),
            _special_load_electric_range(row),
            space_cond_load,
            _special_load_motor(row),
            _special_load_pool_heater(row),
            _special_load_pool_pump(row),
            EVSE_load(row)
        ]
    )
    return special_loads

def apply_opt_demand_factor(x):
    return (
        1 * min(10000, x) +
        0.4 * max(0, x - 10000)
    )

def optional_general_load(row, n_kit=2, n_ldr=1):
    general_loads = [
        _optional_load_lighting(row),
        _general_load_kitchen(row, n=n_kit),
        _general_load_laundry(row, n=n_ldr),
        _fixed_load_water_heater(row),
        _fixed_load_dishwasher(row),
        _fixed_load_garbage_disposal(row),
        _fixed_load_garbage_compactor(row),
        _special_load_electric_range(row),
        _fixed_load_hot_tub_spa(row),
        _fixed_load_well_pump(row)
    ]
    return apply_opt_demand_factor(sum(general_loads))

def optional_continuous_load(row):
    continuous_loads = [
        _special_load_pool_heater(row),
        _special_load_pool_pump(row),
        EVSE_load(row)
    ]
    return(sum(continuous_loads))

def optional_space_cond_load(row):
    AC_load = row["upgrade_costs.size_cooling_system_primary_k_btu_h"] * 293.07103866

    if row["build_existing_model.hvac_cooling_type"] == "Central AC" or (
        row["build_existing_model.hvac_heating_type"].startswith("Ducted")
        and row["build_existing_model.hvac_cooling_type"] == "Heat Pump"
    ):
        AC_load += (3 * 115 + 460)  # 3A x 115V (condenser fan motor) + 460 (blower motor) TODO: Check this value
    
    if row["build_existing_model.heating_fuel"] == "Electricity":
        heating_load = (
            row["upgrade_costs.size_heating_system_primary_k_btu_h"]
            + row["upgrade_costs.size_heating_system_secondary_k_btu_h"]
            + .65*row["upgrade_costs.size_heat_pump_backup_primary_k_btu_h"]
        ) * 293.07103866
    else:
        heating_load = 0
    if row["build_existing_model.hvac_heating_type"].startswith("Ducted"):
        heating_load += 3 * 115  # 3A x 115V (air-handler motor)
    
    if row["build_existing_model.hvac_has_zonal_electric_heating"] == "Yes":
        if  row["build_existing_model.bedrooms"] >= 3: # determine number of individually controlled heating units using number of bedrooms, assuming total = # bedrooms + 1
            sep_controlled_heaters = row["upgrade_costs.size_heating_system_primary_k_btu_h"]*293.07103866*.4 
        else: 
            sep_controlled_heaters = row["upgrade_costs.size_heating_system_primary_k_btu_h"]*293.07103866*.65 
    else:
        sep_controlled_heaters = 0

    continous_heat = 0 # TODO: Determine if we would like to include continuous heat and how to estimate it (NEC 220.82(C)(6) 
    
    space_cond_loads = [
        AC_load , # 100% of AC load (use cooling system primary btu)
        heating_load, # 100% of heating load in absence of supplemental heat or 100% of heating load primary and 65% of secondary or backup heat
        sep_controlled_heaters, # 65% of nameplate of less than 4 seperately controlled heating units, 40% of nameplate of 4 of more seperately controlled heating units
        continous_heat # 100% of electric heat storage or other continuous heating load, assume this to be zero
    ]
    
    return(max(space_cond_loads))

def EVSE_load(row):
    if row["build_existing_model.electric_vehicle"] == "None":
        EV_load = 0
    else: 
        EV_load = 1.25*7200 # TODO: Insert EV charger load, NEC code says use max of nameplate rating and 7200 W, add 1.25 factor since continuous load
    return EV_load

def min_amperage_nec(row, n_kit=2, n_ldr=1):
    """
    Min Amperes for Service
    Min Amperage (A) = Demand Load (total, VA) / Voltage Service (V)
    """
    if row["completed_status"] != "Success":
        return np.nan

    total_demand_load = sum(
        [
            general_load_total(row, n_kit=n_kit, n_ldr=n_ldr),
            fixed_load_total(row),
            special_load_total(row),
        ]
    )  # [VA]

    voltage_service = 240  # [V]

    return total_demand_load / voltage_service

def min_amperage_main_breaker(x):
    """Convert min_amperage_nec into standard panel size
    http://www.naffainc.com/x/CB2/Elect/EHtmFiles/StdPanelSizes.htm
    """
    if pd.isnull(x):
        return np.nan

    standard_sizes = np.array([40, 70, 100, 125, 150, 200, 225, 300, 400, 600])
    factors = standard_sizes / x

    cond = standard_sizes[factors >= 1]
    if len(cond) == 0:
        print(
            f"WARNING: {x} is higher than the largest standard_sizes={standard_sizes[-1]}, "
            "double-check NEC calculations"
        )
        return math.ceil(x / 100) * 100

    return cond[0]

def main(filename: str = None):
    if filename is None:
        filename = (
            Path(__file__).resolve().parent
            / "test_data"
            / "euss1_2018_results_up00_100.csv"
        )
    else:
        filename = Path(filename)

    df = pd.read_csv(filename, low_memory=False)
    df_columns = df.columns

    # --- [1] NEC - STANDARD METHOD ----
    df["std_m_demand_load_general_VA"] = df.apply(
        lambda x: general_load_total(x, n_kit="auto", n_ldr="auto"), axis=1
    )
    df["std_m_demand_load_fixed_VA"] = df.apply(lambda x: fixed_load_total(x), axis=1)
    df["std_m_demand_load_special_VA"] = df.apply(lambda x: special_load_total(x), axis=1)

    # df["nec_min_amp"] = df.apply(lambda x: min_amperage_nec(x, n_kit="auto", n_ldr="auto"), axis=1) # this is daisy-ed
    df["std_m_nec_min_amp"] = (
        df[
            ["std_m_demand_load_general_VA", "std_m_demand_load_fixed_VA", "std_m_demand_load_special_VA"]
        ].sum(axis=1)
        / 240
    )
    df["std_m_nec_electrical_panel_amp"] = df["std_m_nec_min_amp"].apply(
        lambda x: min_amperage_main_breaker(x)
    )

    ### compare
    df["peak_amp"] = (
        df[
            [
                "report_simulation_output.peak_electricity_summer_total_w",
                "report_simulation_output.peak_electricity_winter_total_w",
            ]
        ].max(axis=1)
        / 240
    )

    df["std_m_amp_pct_delta"] = np.nan
    cond = df["peak_amp"] > df["std_m_nec_electrical_panel_amp"]
    df.loc[cond, "std_m_amp_pct_delta"] = (
        df["peak_amp"] - df["std_m_nec_electrical_panel_amp"]
    ) / df["std_m_nec_electrical_panel_amp"]

    # --- [2] NEC - OPTIONAL METHOD ----
    # Sum _general_load_lighting, _general_load_kitchen and _general_load_laundry, _fixed_load_total, _special_load_electric_range
    #  _special_load_hot_tub_spa, _special_load_pool_heater, _special_load_pool_pump, _special_load_well_pump
   
    df["opt_m_demand_load_general_VA"] = df.apply(lambda x: optional_general_load(x), axis=1) # 100 / 40 for 10/10+ kVA demand factor function
    df["opt_m_demand_load_space_cond_VA"] = df.apply(lambda x: optional_space_cond_load(x), axis=1) # compute space conditioning load
    df["opt_m_demand_load_continuous_VA"] = df.apply(lambda x: optional_continuous_load(x), axis=1) #continuous loads

    df["opt_m_nec_min_amp"] = (
        df[
            ["opt_m_demand_load_general_VA", "opt_m_demand_load_space_cond_VA", "opt_m_demand_load_continuous_VA"]
        ].sum(axis=1)
        / 240
    )
    df["opt_m_nec_electrical_panel_amp"] = df["opt_m_nec_min_amp"].apply(lambda x: min_amperage_main_breaker(x))
    
    new_columns = [x for x in df.columns if x not in df_columns]
    print(df.loc[cond, ["building_id"] + new_columns])
    # --- save to file ---
    output_filename = filename.parent / (filename.stem + "__panels5" + filename.suffix)
    df.to_csv(output_filename, index=False)
    print(f"File output to: {output_filename}")

    # Plot histograms:  
    """
    plt.figure(1)
    std_m_sizes = pd.Series.tolist(df.std_m_nec_electrical_panel_amp)
    plt.bar(*np.unique(std_m_sizes,return_counts = True), width = 10)
    plt.xlabel('Capacity of Panel (A)')
    plt.ylabel('Percentage of Panels (%)')
    plt.title('Standard Method')
    plt.xlim([0,400])
    plt.ylim([0,50])
    
    plt.figure(2)
    opt_m_sizes = pd.Series.tolist(df.opt_m_nec_electrical_panel_amp)
    plt.bar(*np.unique(opt_m_sizes,return_counts = True), width = 10)
    plt.xlabel('Capacity of Panel (A)')
    plt.ylabel('Percentage of Panels (%)')
    plt.title('Optional Method')
    plt.xlim([0,400])
    plt.ylim([0,50])

    plt.show()
"""
if __name__ == "__main__":
    if len(sys.argv) == 2:
        filename = sys.argv[1]
        print(f"Applying NEC panel calculation to {filename}...")

    elif len(sys.argv) == 1:
        filename = None
        print(
            "<path_to_results_00.csv> is not specified, NEC panel calculation will be applied to "
            "default file: test_data/euss1_2018_results_up00_100.csv"
        )

    else:
        print(
            """
            Usage: python postprocess_electrical_panel_size_nec.py [optional <path_to_results_00.csv>]

            Code-minimum electrical panel amperage per National Electrical Code can be estimated 
            using ResStock summary result csv file only.
            """
        )
        sys.exit(1)

    main(filename)

# TEST CASES

# test apply_demand_factor_to_general_load

a = apply_demand_factor_to_general_load(1000)
b = apply_demand_factor_to_general_load(10000)
c = apply_demand_factor_to_general_load(13000)

assert a == 1000
assert b == 3000 + 0.35*7000
assert c == 3000 + 10000*.35

# test _general_load_lighting
test1 = {
    "upgrade_costs.floor_area_conditioned_ft_2": [2000],
    "build_existing_model.geometry_garage": ["2 Car"],
    "build_existing_model.geometry_building_type_recs": ["Single-Family Detached"]
    }
df_test1 = pd.DataFrame(test1)

out1 = df_test1.apply(lambda x: _general_load_lighting(x), axis=1)

assert out1[0] == 3*(2000 + 24*24)

#test _optional_load_lighting
test2 = {
    "upgrade_costs.floor_area_conditioned_ft_2": [2000],
    "build_existing_model.geometry_garage": ["2 Car"],
    "build_existing_model.geometry_building_type_recs": ["Single-Family Detached"]
    }
df_test2 = pd.DataFrame(test2)

out2 = df_test2.apply(lambda x: _optional_load_lighting(x), axis=1)

assert out2[0] == 3*(2000)

# test _general_load_kitchen
test3 = {
    "build_existing_model.misc_extra_refrigerator": ["None"],
    "build_existing_model.misc_freezer": ["EF 12, National Average"],
    "completed_status": ["Success"]
}

df_test3 = pd.DataFrame(test3)

out3 = df_test3.apply(lambda x: _general_load_kitchen(x), axis=1)

assert out3[0] == 3000

# test _general_load_laundry
test4 = {
    "completed_status": ["Success"]
}

df_test4 = pd.DataFrame(test4)

out4 = df_test4.apply(lambda x: _general_load_laundry(x), axis=1)

assert out4[0] == 1500

# test min_amperage_main_breaker(x):
assert min_amperage_main_breaker(120) == 125
# assert min_amperage_main_breaker(770) == 800 # commented to avoid false warning
assert min_amperage_main_breaker(90) == 100

