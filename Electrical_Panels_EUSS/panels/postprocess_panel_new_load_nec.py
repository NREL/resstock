"""
Requires env with python >= 3.10
-**
Electrical Panel Project: Estimate existing load in homes using NEC (2023)
Load Summing Method: 220.83
Maximum Demand Method: 220.87

NEC panel capacity = min. main circuit breaker size (A)

By: Lixi.Liu@nrel.gov, Ilan.Upfal@nrel.gov
Date: 02/01/2023
Updated: 06/07/2024

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
    All Load = Existing Load - Load Removed + New Load
   Total Load = 100% of first 8 kVA of All Load + 40% of remaining All Load
Part B: If new HVAC load is being added, 
   Total Load = 100% HVAC Load + 100% of first 8 kVA of Non-HVAC Load + 40% of remaining Non-HVAC load

[220.87] - Maximum Demand Method
Existing Load = 125% x 15_min_electricity_peak (1-full year)
Total Load = Existing Load + New Load
Note: no load is removed from existing load
"""

import pandas as pd
from pathlib import Path
import numpy as np
import math
import argparse
import sys
from itertools import chain

from plotting_functions import _plot_scatter, _plot_box
from clean_up00_file import get_housing_char_cols

# --- lookup ---
geometry_unit_aspect_ratio = {
    "Single-Family Detached": 1.8,
    "Single-Family Attached": 0.5556,
    "Multi-Family with 2 - 4 Units": 0.5556,
    "Multi-Family with 5+ Units": 0.5556,
    "Mobile Home": 1.8,
} #  = front_back_length / left_right_width #TODO: not used currently


hvac_fan_motor = 3*115 # 3A x 115V # TODO check value
KBTU_H_TO_W = 293.07103866

def get_power_rating(df_rating, load_category, appliance):
    row = df_rating.loc[(df_rating['load_category'] == load_category) & (df_rating['appliance'] == appliance)]
    return list(row['volt-amps'])[0]

nameplate_rating = pd.read_csv("nameplate_rating_new_load.csv")
water_heater_electric_power_rating = get_power_rating(nameplate_rating, 'water heater', 'electric')
water_heater_electric_tankless_1bath_power_rating = get_power_rating(nameplate_rating, 'water heater', 'electric tankless, one bathroom')
water_heater_electric_tankless_more_1bath_power_rating = get_power_rating(nameplate_rating, 'water heater', 'electric tankless, more than one bathroom')
water_heater_heat_pump_power_rating = get_power_rating(nameplate_rating, 'water heater', 'heat pump')
water_heater_heat_pump_120_power_rating = get_power_rating(nameplate_rating, 'water heater', 'heat pump, 120V, shared')

dryer_elctric_ventless_power_rating = get_power_rating(nameplate_rating, 'clothes dryer', 'electric ventless')
dryer_elctric_power_rating = get_power_rating(nameplate_rating, 'clothes dryer', 'electric')
dryer_elctric_120_power_rating = get_power_rating(nameplate_rating, 'clothes dryer', 'electric, 120V')
dryer_heat_pump_power_rating = get_power_rating(nameplate_rating, 'clothes dryer', 'heat pump')
dryer_heat_pump_120_power_rating = get_power_rating(nameplate_rating, 'clothes dryer', 'heat pump, 120V')

range_elctric_power_rating = get_power_rating(nameplate_rating, 'range/oven', 'electric')
range_induction_power_rating = get_power_rating(nameplate_rating, 'range/oven', 'induction')
range_elctric_120_power_rating = get_power_rating(nameplate_rating, 'range/oven', 'electric, 120V')
range_induction_120_power_rating = get_power_rating(nameplate_rating, 'range/oven', 'induction, 120V')

hot_tub_spa_power_rating = get_power_rating(nameplate_rating, 'hot tub/spa', 'electric')
pool_heater_power_rating = get_power_rating(nameplate_rating, 'pool heater', 'electric')


# --- funcs ---

### -------- existing load specs --------
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
    
    floor_area = float(row["upgrade_costs.floor_area_conditioned_ft_2"]) # already based on exterior dim (AHS)

    # calculate based on perimeter of footprint with receptables at every 6-feet
    aspect_ratio = geometry_unit_aspect_ratio[row["build_existing_model.geometry_building_type_recs"]]
    fb_length = math.sqrt(floor_area * aspect_ratio) # total as if single-story
    lr_width = floor_area / fb_length

    floor_area += garage_width*garage_depth

    n_receptables = 2*(fb_length+lr_width) // 6
    receptable_load = n_receptables * 20*120 # 20-Amp @ 120V
    # TODO: add other potential unit loads

    return 3 * floor_area


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
    
    washer = nameplate_rating.loc[(nameplate_rating['load_category'] == 'clothes washer') & (nameplate_rating['appliance'] == 'electric')]
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

    if (row["build_existing_model.water_heater_in_unit"] == "Yes") and ((
        row["build_existing_model.water_heater_fuel"] == "Electricity")or(
        "Electric" in row["build_existing_model.water_heater_efficiency"]
        )):
        if row["build_existing_model.water_heater_efficiency"] == "Electric Tankless":
            if int(row["build_existing_model.bedrooms"]) in [1,2]:
                return water_heater_electric_tankless_1bath_power_rating 
            if int(row["build_existing_model.bedrooms"]) in [3,4,5]:
                return water_heater_electric_tankless_more_1bath_power_rating
            raise ValueError("Cannot find bedrooms options.")
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
    
    dishwasher = nameplate_rating.loc[(nameplate_rating['load_category'] == 'dishwasher') & (nameplate_rating['appliance'] == 'electric')]
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
        garbage_disposal_one_third_hp = nameplate_rating.loc[(nameplate_rating['load_category'] == 'garbage disposal') & (nameplate_rating['appliance'] == '1/3 HP')]
        garbage_disposal_one_third_hp_power_rating = list(garbage_disposal_one_third_hp['volt-amps'])[0]
        garbage_disposal_half_hp = nameplate_rating.loc[(nameplate_rating['load_category'] == 'garbage disposal') & (nameplate_rating['appliance'] == '1/2 HP')]
        garbage_disposal_half_hp_power_rating = list(garbage_disposal_half_hp['volt-amps'])[0]
        garbage_disposal_three_quarters_hp = nameplate_rating.loc[(nameplate_rating['load_category'] == 'garbage disposal') & (nameplate_rating['appliance'] == '0.75 HP')]
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

    if "Electric" in row["build_existing_model.misc_hot_tub_spa"]:
        return hot_tub_spa_power_rating
    return 0


def _fixed_load_well_pump(row):
    """ pump/motor nameplates taken from NEC tables based on HP, not PF needed """
    if row["completed_status"] != "Success":
        return np.nan
    
    well_pump = nameplate_rating.loc[(nameplate_rating['load_category'] == 'well pump') & (nameplate_rating['appliance'] == 'electric')]
    well_pump_power_rating = list(well_pump['volt-amps'])[0]

    if row["build_existing_model.misc_well_pump"] != "None":
        return well_pump_power_rating 
    return 0


def _special_load_dryer(row):
    """Clothes Dryers. NEC 220-18
    Use 5000 watts or nameplate rating whichever is larger (in another version, use DF=1 for # appliance <=4)
    240V, 22/24/30A breaker (vented), 30/40A (ventless heat pump), 30A (ventless electric)
    """
    if row["completed_status"] != "Success":
        return np.nan

    if "Electric" not in row["build_existing_model.clothes_dryer"] or row["build_existing_model.clothes_dryer"] == "None":
        return 0

    if "Ventless" in row["build_existing_model.clothes_dryer"]:
        rating = dryer_elctric_ventless_power_rating
    else:
        rating = dryer_elctric_power_rating

    return max(5000, rating)


def _special_load_range_oven(row): 
    """ Assuming a single electric range (combined oven/stovetop) for each dwelling unit """

    if range_power <= 12000:
        range_power_w_df = min(range_power, 8000)
    elif range_power <= 27000:
        range_power_w_df = 8000 + 0.05*(max(0,range_power-12000)) # footnote 2
    else:
        raise ValueError(f"range_power={range_power} cannot exceed 27kW")
    
    return range_power_w_df


def _special_load_cooking_range_oven(row): 
    """ Assuming a single electric range (combined oven/stovetop) for each dwelling unit """
    if row["completed_status"] != "Success":
        return np.nan

    if "Electric" not in row["build_existing_model.cooking_range"] or row["build_existing_model.cooking_range"]=="None":
        return 0

    if "Induction" in row["build_existing_model.cooking_range"]:
        return range_induction_power_rating 

    return range_elctric_power_rating 


def _special_load_space_heating(row):
    if row["completed_status"] != "Success":
        return np.nan

    # shared heating is not part of dwelling unit's panel
    if row["build_existing_model.hvac_has_shared_system"] in ["Heating Only", "Heating and Cooling"]:
        return 0

    # heating load
    heat_eff = row["build_existing_model.hvac_heating_efficiency"]
    hvac_has_ducts = row["build_existing_model.hvac_has_ducts"]
    heat_eff_2 = row["build_existing_model.hvac_secondary_heating_efficiency"]

    heating_type = None
    secondary_heating_type = None

    if ("ASHP" in heat_eff) or ("MSHP" in heat_eff):
        if hvac_has_ducts:
            heating_type = "Ducted Heat Pump" # assume ducted
        else:
            heating_type = "Non-Ducted Heat Pump"
    elif ("Electric" in heat_eff):
        heating_type = "Electric Resistance"
    elif ("GSHP" in heat_eff):
        raise ValueError(f"Unsupported: {row[opt_col]}")

    if ("ASHP" in heat_eff_2):
        secondary_heating_type = "Ducted Heat Pump"
    elif ("MSHP" in heat_eff_2):
        secondary_heating_type = "Non-Ducted Heat Pump"
    elif ("Electric" in heat_eff_2):
        secondary_heating_type = "Electric Resistance"
    elif ("GSHP" in heat_eff_2):
        raise ValueError(f"Unsupported: {row[opt_col]}")

    heating_cols = [
        row["upgrade_costs.size_heating_system_primary_k_btu_h"],
        row["upgrade_costs.size_heating_system_secondary_k_btu_h"],
        row["upgrade_costs.size_heat_pump_backup_primary_k_btu_h"]
        ]
    system_cols = [
        heating_type,
        secondary_heating_type,
        "Electric Resistance",
        ]

    heating_load = sum(
            [hvac_heating_conversion(x, system_type=y) for x, y in zip(heating_cols, system_cols)]
        )
    if hvac_has_ducts == "Yes":
        heating_load += hvac_fan_motor

    return heating_load


def _special_load_space_cooling(row):
    if row["completed_status"] != "Success":
        return np.nan, False

    # shared cooling is not part of dwelling unit's panel
    if row["build_existing_model.hvac_has_shared_system"] in ["Cooling Only", "Heating and Cooling"]:
        return 0

    cooling_load = hvac_cooling_conversion(
        row["upgrade_costs.size_cooling_system_primary_k_btu_h"],
        system_type=row["build_existing_model.hvac_cooling_type"]
    )
    if row["build_existing_model.hvac_has_ducts"] == "Yes":
        cooling_load += hvac_fan_motor
    
    return cooling_load


def _special_load_space_conditioning(row):
    """ Not accounting for humidifier
    1 Btu/h = 0.29307103866W

    Returns:
        max(loads) : int
            special_load_for_heating_or_cooling
    """
    if row["completed_status"] != "Success":
        return np.nan
    
    heating_load = _special_load_space_heating(row)
    cooling_load = _special_load_space_cooling(row)

    return max(heating_load, cooling_load)


def _special_load_pool_heater(row, apply_df=True):
    """NEC 680.9
    https://twphamilton.com/wp/wp-content/uploads/doc033548.pdf
    """
    if row["completed_status"] != "Success":
        return np.nan

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
    pool_pump_1hp = nameplate_rating.loc[(nameplate_rating['load_category'] == 'pool pump') & (nameplate_rating['appliance'] == 'electric, 1.0 hp')]
    pool_pump_1hp_power_rating = list(pool_pump_1hp['volt-amps'])[0]
    pool_pump_three_quaters = nameplate_rating.loc[(nameplate_rating['load_category'] == 'pool pump') & (nameplate_rating['appliance'] == 'electric, 0.75 hp')]
    pool_pump_three_quaters_power_rating = list(pool_pump_three_quaters['volt-amps'])[0]

    if row["build_existing_model.misc_pool_pump"] == "1.0 HP Pump":
        return pool_pump_1hp_power_rating
    if row["build_existing_model.misc_pool_pump"] == "0.75 HP Pump":
        return pool_pump_three_quaters_power_rating
    return 0


def _special_load_evse(row):
    if row["completed_status"] != "Success":
        return np.nan
    EVSE = nameplate_rating.loc[(nameplate_rating['load_category'] == 'electric vehicle charger') & (nameplate_rating['appliance'] == 'electric')]
    EVSE_power_rating = list(EVSE['volt-amps'])[0]

    if row["build_existing_model.electric_vehicle"] == "None":
        EV_load = 0
    else: 
        EV_load = max(EVSE_power_rating, 7200)
    return EV_load


### -------- new load specs --------
def _new_load_evse(row, option_columns):
    if row["completed_status"] != "Success":
        return np.nan

    for opt_col in option_columns:
        if "Electric Vehicle" in row[opt_col] and "None" not in row[opt_col]:
            return max(EVSE_power_rating, 7200)

    return 0

def _new_load_pool_heater(row, option_columns):
    if row["completed_status"] != "Success":
        return np.nan

    for opt_col in option_columns:
        if "Misc Pool Heater" in row[opt_col] and "Electric" in row[opt_col]:
            return pool_heater_power_rating

    return 0


def _new_load_hot_tub_spa(row, option_columns):
    if row["completed_status"] != "Success":
        return np.nan

    for opt_col in option_columns:
        if "Misc Hot Tub Spa" in row[opt_col] and "Electricity" in row[opt_col]:
            return hot_tub_spa_power_rating 

    return 0


def _new_load_range_oven(row, option_columns):
    if row["completed_status"] != "Success":
        return np.nan

    for opt_col in option_columns:
        if "Cooking Range" in row[opt_col] and "Electric" in row[opt_col]:
            if "120V" in row[opt_col] or "120 V" in row[opt_col]:
                return range_elctric_120_power_rating
            if "Induction" in row[opt_col]:
                if "120V" in row[opt_col] or "120 V" in row[opt_col]:
                    return range_induction_120_power_rating
                return range_induction_power_rating
            return range_elctric_power_rating 

    return 0


def _new_load_dryer(row, option_columns):
    if row["completed_status"] != "Success":
        return np.nan

    for opt_col in option_columns:
        if "Clothes Dryer" in row[opt_col] and "Electric" in row[opt_col]:
            if "120V" in row[opt_col] or "120 V" in row[opt_col]:
                return dryer_elctric_120_power_rating
            if "Ventless" in row[opt_col]:
                return dryer_elctric_ventless_power_rating
            if "Heat Pump" in row[opt_col]:
                if "120V" in row[opt_col] or "120 V" in row[opt_col]:
                    return dryer_heat_pump_120_power_rating
                return dryer_heat_pump_120_power_rating
            return dryer_elctric_power_rating

    return 0



def _new_load_water_heating(row, option_columns):
    if row["completed_status"] != "Success":
        return np.nan

    for opt_col in option_columns:
        if "Water Heater Efficiency" in row[opt_col] and "Electric" in row[opt_col]: 
            if "Electric Tankless" in row[opt_col]:
                if int(row["build_existing_model.bedrooms"]) in [1,2]:
                    return water_heater_electric_tankless_1bath_power_rating 
                if int(row["build_existing_model.bedrooms"]) in [3,4,5]:
                    return water_heater_electric_tankless_more_1bath_power_rating
            if "Heat Pump" in row[opt_col]:
                if "120V" in row[opt_col] or "120 V" in row[opt_col]:
                    return water_heater_heat_pump_120_power_rating
                return water_heater_heat_pump_power_rating
            return water_heater_electric_power_rating

    return 0


def _new_load_space_conditioning(row, option_columns):
    if row["completed_status"] != "Success":
        return np.nan

    if row["build_existing_model.hvac_has_ducts"] == "Yes":
        hvac_has_ducts = True
    else:
        hvac_has_ducts = False

    # heating load
    heating_type = None
    secondary_heating_type = None
    for opt_col in option_columns:
        if ("HVAC Heating Efficiency" in row[opt_col]):
            if ("ASHP" in row[opt_col]) or ("MSHP" in row[opt_col]):
                if hvac_has_ducts:
                    heating_type = "Ducted Heat Pump" # assume ducted
                else:
                    heating_type = "Non-Ducted Heat Pump"
            elif ("Electric" in row[opt_col]):
                heating_type = "Electric Resistance"
            elif ("GSHP" in row[opt_col]):
                raise ValueError(f"Unsupported: {row[opt_col]}")

        if ("HVAC Secondary Heating Efficiency" in row[opt_col]):
            if ("ASHP" in row[opt_col]):
                secondary_heating_type = "Ducted Heat Pump"
            elif ("MSHP" in row[opt_col]):
                secondary_heating_type = "Non-Ducted Heat Pump"
            elif ("Electric" in row[opt_col]):
                secondary_heating_type = "Electric Resistance"
            elif ("GSHP" in row[opt_col]):
                raise ValueError(f"Unsupported: {row[opt_col]}")

    heating_cols = [
        row["upgrade_costs.size_heating_system_primary_k_btu_h"],
        row["upgrade_costs.size_heating_system_secondary_k_btu_h"],
        row["upgrade_costs.size_heat_pump_backup_primary_k_btu_h"]
        ]
    system_cols = [
        heating_type,
        secondary_heating_type,
        "Electric Resistance",
        ]

    heating_load = sum(
        [hvac_heating_conversion(x, system_type=y) for x, y in zip(heating_cols, system_cols)]
    )


    # cooling load
    cooling_type = None
    for opt_col in option_columns:
        if ("HVAC Cooling Efficiency" in row[opt_col]):
            if "Room AC" in row[opt_col]:
                cooling_type = "Room AC"
            elif "AC" in row[opt_col]:
                cooling_type = "Central AC"
            elif  "Heat Pump" in row[opt_col]:
                cooling_type = "Heat Pump"
            elif "Swamp Cooler" in row[opt_col]:
                raise ValueError(f"Unsupported: {row[opt_col]}")

    cooling_load = hvac_cooling_conversion(
        row["upgrade_costs.size_cooling_system_primary_k_btu_h"],
        system_type=cooling_type
    )
    if hvac_has_ducts:
        heating_load += hvac_fan_motor
        cooling_load += hvac_fan_motor

    return max(heating_load, cooling_load)


### -------- util funcs --------
def hvac_heating_conversion(nom_heat_cap, system_type=None):
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
    if system_type is None or system_type == "None":
        return 0

    nom_heat_cap = float(nom_heat_cap)
    if "Heat Pump" in system_type:
        heating = nameplate_rating.loc[(nameplate_rating['load_category'] == 'space heating') & (nameplate_rating['appliance'] == 'heat pump')]
        voltage = list(heating['voltage'])[0]
        slope = float(list(heating['amperage'])[0].split(',')[0])
        intercept = float(list(heating['amperage'])[0].split(',')[1])  
        return (slope*nom_heat_cap + intercept) * voltage
    if system_type == "Electric Resistance":
        return nom_heat_cap * KBTU_H_TO_W
    raise ValueError(f"Unknown {system_type=}")


def hvac_cooling_conversion(nom_cool_cap, system_type=None):
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
    if system_type is None or system_type == "None":
        return 0

    nom_cool_cap = float(nom_cool_cap)
    if "Heat Pump" in system_type:
        cooling = nameplate_rating.loc[(nameplate_rating['load_category'] == 'space cooling') & (nameplate_rating['appliance'] == 'heat pump')]
    elif system_type == "Central AC":
        cooling = nameplate_rating.loc[(nameplate_rating['load_category'] == 'space cooling') & (nameplate_rating['appliance'] == 'central ac')]
    elif system_type == "Room AC":
        cooling = nameplate_rating.loc[(nameplate_rating['load_category'] == 'space cooling') & (nameplate_rating['appliance'] == 'room ac')]
    else:
        raise ValueError(f"Unknown {system_type=}")

    voltage = list(cooling['voltage'])[0]
    slope = float(list(cooling['amperage'])[0].split(',')[0])
    intercept = float(list(cooling['amperage'])[0].split(',')[1])
    return (slope*nom_cool_cap + intercept) * voltage


def standard_amperage(x: float) -> int:
    """Convert min_amp_col into standard panel size
    http://www.naffainc.com/x/CB2/Elect/EHtmFiles/StdPanelSizes.htm
    """
    if pd.isnull(x):
        return np.nan

    # TODO: refine
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


def read_file(filename: str, low_memory: bool =True, sort_bldg_id: bool = False, **kwargs) -> pd.DataFrame:
    """ If file is large, use low_memory=False"""
    filename = Path(filename)
    if filename.suffix in [".csv", ".gz"]:
        df = pd.read_csv(filename, low_memory=low_memory, keep_default_na=False, **kwargs)
    elif filename.suffix == ".parquet":
        df = pd.read_parquet(filename, **kwargs)
    else:
        raise TypeError(f"Unsupported file type, cannot read file: {filename}")

    if sort_bldg_id:
        df = df.sort_values(by="building_id").reset_index(drop=True)

    return df


def bin_panel_sizes(df_column: pd.Series) -> pd.Series:
    df_out = df_column.copy()
    df_out.loc[df_column<100] = "<100"
    df_out.loc[(df_column>100) & (df_column<125)] = "101-124"
    df_out.loc[(df_column>125) & (df_column<200)] = "126-199"
    df_out.loc[df_column>200] = "200+"
    df_out = df_out.astype(str)

    return df_out



def generate_plots(df: pd.DataFrame, dfo: pd.DataFrame, output_dir: Path, sfd_only: bool = False, upgrade_num: str = ""):
    msg = " for Single-Family Detached only" if sfd_only else ""
    print(f"generating plots{msg}...")
    HC_list = [
        "build_existing_model.census_region",
        "build_existing_model.census_division",
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
    ]
    dfo = dfo.join(df.set_index("building_id")[HC_list], on="building_id", how="left")
    upgrade_name = [x for x in dfo["apply_upgrade.upgrade_name"].unique() if x not in [None, "", np.nan]][0]

    _plot_scatter(dfo, "amp_total_pre_upgrade_A_220_83", "amp_total_pre_upgrade_A_220_87", 
        title=f"{upgrade_name}\nPre-upgrade comparison", output_dir=output_dir, sfd_only=sfd_only, upgrade_num=upgrade_num)
    _plot_scatter(dfo, "amp_total_post_upgrade_A_220_83", "amp_total_post_upgrade_A_220_87", 
        title=f"{upgrade_name}\nPost-upgrade comparison", output_dir=output_dir, sfd_only=sfd_only, upgrade_num=upgrade_num)
    _plot_scatter(dfo, "amp_total_pre_upgrade_A_220_83", "amp_total_post_upgrade_A_220_83", 
        title=f"{upgrade_name}\nNEC 220.83", output_dir=output_dir, sfd_only=sfd_only, upgrade_num=upgrade_num)
    _plot_scatter(dfo, "amp_total_pre_upgrade_A_220_87", "amp_total_post_upgrade_A_220_87", 
        title=f"{upgrade_name}\nNEC 220.87", output_dir=output_dir, sfd_only=sfd_only, upgrade_num=upgrade_num)
    print("scatter plots completed.")
    for metric in [
        "amp_total_pre_upgrade_A_220_83", 
        "amp_total_pre_upgrade_A_220_87",
        "amp_total_post_upgrade_A_220_83", 
        "amp_total_post_upgrade_A_220_87",
        ]:
        for hc in HC_list:
            _plot_box(dfo, metric, hc, output_dir=output_dir, sfd_only=sfd_only, upgrade_num=upgrade_num)
    print(f"plots output to: {output_dir}")


def existing_load_labels() -> list[str]:
    existing_loads_labels = [
        "load_hvac",
        "load_water_heater",
        "load_dryer",
        "load_range_oven",
        "load_hot_tub_spa",
        "load_pool_heater",
        "load_evse",

        "load_lighting",
        "load_kitchen",
        "load_laundry",
        "load_dishwasher",
        "load_garbage_disposal",
        "load_garbage_compactor",
        "load_well_pump",
        "load_pool_pump",
        
    ]
    return existing_loads_labels


def apply_existing_loads(row, n_kit: int = 2, n_ldr: int = 1) -> list[float]:
    """ Load summing method """
    if row["completed_status"] != "Success":
        return np.nan

    existing_loads = [
            _special_load_space_conditioning(row), # max of heating or cooling
            _fixed_load_water_heater(row),
            _special_load_dryer(row),
            _special_load_cooking_range_oven(row),
            _fixed_load_hot_tub_spa(row),
            _special_load_pool_heater(row),
            _special_load_evse(row),

            _general_load_lighting(row), # sqft
            _general_load_kitchen(row, n=n_kit), # consider logic based on sqft
            _general_load_laundry(row, n=n_ldr), # consider logic based on sqft (up to 2)
            _fixed_load_dishwasher(row),
            _fixed_load_garbage_disposal(row),
            _fixed_load_garbage_compactor(row),
            _fixed_load_well_pump(row),
            _special_load_pool_pump(row),
            
        ] # no largest motor load

    return existing_loads


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


def apply_total_load_220_83(row, has_new_hvac_load: bool) -> float | list[float]:
    """Apply demand factor to existing loads per 220.83"""
    threshold_load = 8000 # VA
    if has_new_hvac_load:
        # 220.83 [B]: 100% HVAC load + 100% of 1st 8kVA other_loads + 40% of remainder other_loads
        hvac_load = row["load_hvac"]
        other_load = row.sum() - hvac_load
        total_load = hvac_load + apply_demand_factor(other_load, threshold_load=threshold_load)

    else:
        # 220.83 [A]: 100% of 1st 8kVA all loads + 40% of remainder loads
        total_load = apply_demand_factor(row.sum(), threshold_load=threshold_load)

    return total_load


def calculate_new_loads(df: pd.DataFrame, dfu: pd.DataFrame, result_as_map: bool = False)-> pd.DataFrame:
    ## apply new load
    # 1 add necessary baseline HC
    HC_list = [
        "build_existing_model.hvac_has_ducts",
        "build_existing_model.bedrooms",
    ]
    df_up = dfu.join(df.set_index(["building_id"])[HC_list], on=["building_id"], how="left")

    # 2 obtain valid list of upgrade option columns
    option_columns = [x for x in dfu.columns if x.startswith("upgrade_costs.option") and x.endswith("name")]
    option_cols = []
    upgrade_options = []
    for opt_col in option_columns:
        upgrade_option = [x for x in dfu[opt_col].unique() if x not in [None, np.nan, ""]]
        if upgrade_option:
            assert len(upgrade_option) == 1, f"{upgrade_option=} has more than one option."
            option_cols.append(opt_col)
            upgrade_options.append(upgrade_option[0])

    # 3 convert upgrade options to nameplate power ratings
    # [1] Heating and cooling
    df_up["new_load_hvac"] = df_up.apply(lambda x: _new_load_space_conditioning(x, option_cols), axis=1)

    # [2] Water heating
    wh_option_cols, _ = get_upgrade_columns_and_options(option_cols, upgrade_options, "Water Heater Efficiency")
    df_up["new_load_water_heater"] = df_up.apply(lambda x: _new_load_water_heating(x, wh_option_cols), axis=1)

    # [3] Appliances
    dryer_option_cols, _ = get_upgrade_columns_and_options(option_cols, upgrade_options, "Clothes Dryer")
    df_up["new_load_dryer"] = df_up.apply(lambda x: _new_load_dryer(x, dryer_option_cols), axis=1)

    cooking_option_cols, _ = get_upgrade_columns_and_options(option_cols, upgrade_options, "Cooking Range")
    df_up["new_load_range_oven"] = df_up.apply(lambda x: _new_load_range_oven(x, cooking_option_cols), axis=1)

    hot_tub_spa_option_cols, _ = get_upgrade_columns_and_options(option_cols, upgrade_options, "Misc Hot Tub Spa")
    df_up["new_load_hot_tub_spa"] = df_up.apply(lambda x: _new_load_hot_tub_spa(x, hot_tub_spa_option_cols), axis=1)

    pool_heater_option_cols, _ = get_upgrade_columns_and_options(option_cols, upgrade_options, "Misc Pool Heater")
    df_up["new_load_pool_heater"] = df_up.apply(lambda x: _new_load_pool_heater(x, pool_heater_option_cols), axis=1)

    ev_option_cols, _ = get_upgrade_columns_and_options(option_cols, upgrade_options, "Electric Vehicle")
    df_up["new_load_evse"] = df_up.apply(lambda x: _new_load_evse(x, ev_option_cols), axis=1)


    if result_as_map:
        new_load_cols = [x for x in df_up.columns if "new_load" in x]
        df_up = df_up[["building_id"] + new_load_cols]
    else:
        df_up = df_up.drop(columns=HC_list)

    return df_up


def get_upgrade_columns_and_options(option_columns, upgrade_options, parameter):
    columns = [] # 'upgrade_costs.option_<>_name'
    options = [] # e.g., 'ASHP, SEER 15, 9.0 HSPF' if parameter = 'HVAC Heating Efficiency'
    for col, upgrade_option in zip(option_columns, upgrade_options):
        if parameter in upgrade_option:
            options.append(upgrade_option.split("|")[1])
            columns.append(col)
    return columns, options


### -------- load method calcs --------
def calculate_new_load_total_220_83(dfi: pd.DataFrame, dfu: pd.DataFrame, n_kit: int = 2, n_ldr: int = 1, explode_result: bool = False, result_as_map: bool = False) -> pd.DataFrame:
    """
    NEC 220.83 - Load summing method
        Total loads = existing loads - loads removed + new loads
        Total loads get discounted based on whether additional space conditioning is added: (A)=No or (B)=Yes

    NEC 220.83 (A) where additional AC or space-heating IS NOT being installed
        - Total load = existing + new loads, 100% 1st 8kVA of total, 40% remainder of total
        - Used if upgrade has no electric space conditioning
    
    NEC 220.83 (B) where additional AC or space-heating IS being installed
        - 100% HVAC load + 100% 1st 8kVA other loads + 40% remainder of other
        - Used if upgrade has electric space conditioning, includes ER heating -> HP

    """
    print("Performing NEC 220.83 (load-summing) calculations...")
    df = dfi.copy()

    ## New loads
    df_new = calculate_new_loads(df, dfu, result_as_map=True)
    new_loads = [x for x in df_new.columns if "new_load" in x]

    # Existing loads
    existing_loads = existing_load_labels()
    df_existing = pd.DataFrame(
        df.apply(lambda x: apply_existing_loads(x, n_kit=n_kit, n_ldr=n_ldr), axis=1).to_list(),
        index = df.index, columns=existing_loads
        )
    df_loads = df_existing.copy() # for i/o accounting

    # Total pre-upgrade load based on no new hvac
    total_load_pre = "load_total_pre_upgrade_VA_220_83"
    total_amp_pre = "amp_total_pre_upgrade_A_220_83"
    new_hvac = (df_new["new_load_hvac"]>0).rename("upgrade_has_new_hvac")
    df_existing[total_load_pre] = df_existing.apply(lambda x: apply_total_load_220_83(x, has_new_hvac_load=False), axis=1)
    df_existing[total_amp_pre] = df_existing[total_load_pre] / 240

    # remove upgraded loads from existing loads and replace with new loads
    upgradable_loads = [x.removeprefix("new_") for x in new_loads]
    df_upgraded = df_new.drop(columns=["building_id"]).rename(columns=dict(zip(new_loads, upgradable_loads)))
    cond_upgraded = df_upgraded>0
    loads_upgraded = cond_upgraded.apply(lambda x: list(x[x].index), axis=1).rename("loads_upgraded") # record which loads are upgraded
    # replace where upgraded with nan then update with new loads
    df_change = df_loads[upgradable_loads].mask(cond_upgraded)
    df_change.update(df_upgraded, overwrite=False)
    df_loads[upgradable_loads] = df_change

    # QC
    diff = df_existing[existing_loads].compare(df_loads)
    assert len(diff) > 0, "No difference between existing loads and updated loads"

    # Total post-upgrade load based on whether has new hvac
    total_load_post = "load_total_post_upgrade_VA_220_83"
    total_amp_post = "amp_total_post_upgrade_A_220_83"
    new_hvac = (df_new["new_load_hvac"]>0).rename("upgrade_has_new_hvac")
    df_loads.loc[new_hvac, total_load_post] = df_loads.loc[new_hvac].apply(lambda x: apply_total_load_220_83(x, has_new_hvac_load=True), axis=1)
    df_loads.loc[~new_hvac, total_load_post] = df_loads.loc[~new_hvac].apply(lambda x: apply_total_load_220_83(x, has_new_hvac_load=False), axis=1)
    df_loads[total_amp_post] = df_loads[total_load_post] / 240

    df_result = pd.concat([
        df_new["building_id"],
        dfu["apply_upgrade.upgrade_name"],
        new_hvac,
        df_existing,
        loads_upgraded,
        df_new[new_loads],
        df_loads[[total_load_post, total_amp_post]],
        ], axis=1)

    if explode_result:
        cols = df_result.columns
    else:
        cols = ["building_id", total_load_pre, total_amp_pre, total_load_post, total_amp_post]

    if result_as_map:
        return df_result[cols]

    return dfu.join(df_result[cols].set_index("building_id"), on="building_id")


def calculate_new_load_total_220_87(df: pd.DataFrame, dfu: pd.DataFrame, explode_result: bool = False, result_as_map: bool = False) -> pd.DataFrame:
    """ Maximum demand method 
        - "report_simulation_output.peak_electricity_annual_total_w": timestep -- not available in EUSS RR1
        - "qoi_report.qoi_hourly_peak_magnitude_use_kw": peak of hourly aggregates, different from above
        - EUSS RR1 uses "qoi_report.qoi_peak_magnitude_use_kw"
    """
    print("Performing NEC 220.87 (max-load) calculations...")

    # New Loads
    df_new = calculate_new_loads(df, dfu, result_as_map=True)

    # Existing Loads
    total_load_pre = "load_total_pre_upgrade_VA_220_87"
    total_amp_pre = "amp_total_pre_upgrade_A_220_87"
    peak_col = "report_simulation_output.peak_electricity_annual_total_w"
    if peak_col in df.columns:
        conversion = 1
    else:
        peak_col = "qoi_report.qoi_peak_magnitude_use_kw"
        if peak_col in df.columns:
            conversion = 1000
        else:
            raise ValueError("No suitable electricity peak column found.")
    print(f"Peak electricity column used: {peak_col}")

    df[total_load_pre] = df[peak_col].astype(float) * conversion * 1.25 # VA
    df.loc[df["build_existing_model.vacancy_status"]=="Vacant", total_load_pre] = np.nan
    df[total_amp_pre] = df[total_load_pre] / 240 # amp


    ## Total Loads
    total_load_post = "load_total_post_upgrade_VA_220_87"
    total_amp_post = "amp_total_post_upgrade_A_220_87"
    cols = [
        "building_id",
        "load_total_pre_upgrade_VA_220_87",
        "amp_total_pre_upgrade_A_220_87",
    ]
    df_new = df[cols].join(
        df_new.set_index(["building_id"]), on=["building_id"], how="right"
        )

    new_loads = [x for x in df_new.columns if "new_load" in x]
    df_new["new_load_total_VA_220_87"] = df_new[new_loads].sum(axis=1)
    df_new[total_load_post] = df_new[total_load_pre] + df_new["new_load_total_VA_220_87"]
    df_new[total_amp_post] = df_new[total_load_post] / 240

    if explode_result:
        cols = df_new.columns # include new loads
    else:
        cols = ["building_id", total_load_pre, total_amp_pre, total_load_post, total_amp_post]

    if result_as_map:
        return df_new[cols]

    return dfu.join(df_new[cols].set_index("building_id"), on="building_id")



def main(
    baseline_filename: str | None = None, 
    upgrade_filename: str | None = None, 
    plot: bool = False, sfd_only: bool = False, explode_result: bool = False, result_as_map: bool = False):
    if baseline_filename is None:
        baseline_filename = (
            Path(__file__).resolve().parent
            / "test_data"
            / "euss1_2018_results_up00_100.csv" # "euss1_2018_results_up00_400plus.csv"
        )
    else:
        baseline_filename = Path(baseline_filename)


    if upgrade_filename is None:
        upgrade_filename = (
            Path(__file__).resolve().parent
            / "test_data"
            / "euss1_2018_results_up07_100.csv" # min-eff electrification package
        )
    else:
        upgrade_filename = Path(upgrade_filename)

    output_filedir = upgrade_filename.parent / "nec_calculations"
    ext = ""
    if explode_result:
        ext = "_exploded"
    if result_as_map:
        output_filename = output_filedir / (upgrade_filename.stem.split(".")[0] + f"__res_map__nec_new_load{ext}" + ".csv")
    else:
        output_filename = output_filedir / (upgrade_filename.stem.split(".")[0] + f"__nec_new_load{ext}" + ".csv")

    upgrade_num = [x for x in 
        list(chain(*[x.split(".") for x in upgrade_filename.stem.split("_")]))
        if "up" in x][0]
    plot_dir_name = f"plots_sfd" if sfd_only else f"plots"
    output_dir = upgrade_filename.parent / plot_dir_name / "nec_calculations" / upgrade_num
    output_dir.mkdir(parents=True, exist_ok=True) 

    plot_later = False
    if plot:
        if not output_filename.exists():
            plot_later = True
        else:
            df = read_file(baseline_filename, compression="infer", low_memory=False)
            dfo = read_file(output_filename, low_memory=False)
            for col in [ 
                "amp_total_pre_upgrade_A_220_83",  
                "amp_total_pre_upgrade_A_220_87",
                "amp_total_post_upgrade_A_220_83",  
                "amp_total_post_upgrade_A_220_87",
            ]:
                dfo[col] = dfo[col].replace("", np.nan).astype(float)
            generate_plots(df, dfo, output_dir, sfd_only=sfd_only, upgrade_num=upgrade_num)
            sys.exit()
        
    df = read_file(baseline_filename, compression="infer", low_memory=False, sort_bldg_id=True)
    dfu = read_file(upgrade_filename, compression="infer", low_memory=False, sort_bldg_id=True)
    dfu = dfu[dfu["completed_status"]=="Success"].reset_index(drop=True)
    df = df[df["completed_status"]=="Success"].reset_index(drop=True)

    # QC
    bldgs_no_bl = set(dfu["building_id"]) - set(df["building_id"])
    if bldgs_no_bl:
        print(f"WARNING: {len(bldgs_no_bl)} buildings have upgrade but no baseline: {bldgs_no_bl}")
    valid_bldgs = sorted(set(dfu["building_id"]).intersection(set(df["building_id"])))
    df = df[df["building_id"].isin(valid_bldgs)].reset_index(drop=True)
    dfu = dfu[dfu["building_id"].isin(valid_bldgs)].reset_index(drop=True)
    assert (dfu["building_id"] == df["building_id"]).prod() == 1, "Ordering of building_id does not match between upgrade and baseline"

    # --- NEW LOAD calcs ---
    # NEC 220.83 - Load Summing Method
    # NEC 220.87 - Maximum Demand Method
    if result_as_map:
        df1 = calculate_new_load_total_220_83(df, dfu, n_kit=2, n_ldr=1, explode_result=explode_result, result_as_map=result_as_map)
        df2 = calculate_new_load_total_220_87(df, dfu, result_as_map=result_as_map)
        dfo = df1.join(df2.set_index("building_id"), on="building_id")
    else:
        dfu1 = calculate_new_load_total_220_83(df, dfu, n_kit=2, n_ldr=1, explode_result=explode_result)
        dfo = calculate_new_load_total_220_87(df, dfu1)

    # --- save to file ---
    dfo.to_csv(output_filename, index=False)
    print(f"File output to: {output_filename}")

    if plot_later:
        generate_plots(df, dfo, output_dir, sfd_only=sfd_only, upgrade_num=upgrade_num)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "baseline_filename",
        action="store",
        default=None,
        nargs="?",
        help="Path to ResStock baseline result file, e.g., results_up00.csv, "
        "defaults to test data: test_data/euss1_2018_results_up00_100.csv"
        )
    parser.add_argument(
        "upgrade_filename",
        action="store",
        default=None,
        nargs="?",
        help="Path to ResStock upgrade result file, e.g., results_up01.csv, "
        "defaults to test data: test_data/euss1_2018_results_up01_100.csv"
        )
    parser.add_argument(
        "-p",
        "--plot",
        action="store_true",
        default=False,
        help="Make plots based on expected output file without regenerating output_file",
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
    parser.add_argument(
        "-m",
        "--result_as_map",
        action="store_true",
        default=False,
        help="Whether to export NEC calculation result as a building_id map only. "
        "Default to appending NEC result as new column(s) to input result file. ",
    )

    args = parser.parse_args()
    print("======================================================")
    print("New load calculation using 2023 NEC 220.83 and 220.87")
    print("======================================================")
    main(
        args.baseline_filename, args.upgrade_filename,
        plot=args.plot, sfd_only=args.sfd_only, explode_result=args.explode_result, result_as_map=args.result_as_map
        )
