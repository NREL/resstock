"""
Requires env with python >= 3.10
-**
Electrical Panel Project: Estimate existing and new load in homes using NEC (2023)
Load Summing Method: 220.83
Maximum Demand Method: 220.87

NEC panel capacity = min. main circuit breaker size (A)

By: Lixi.Liu@nrel.gov, Ilan.Upfal@nrel.gov
Date: 02/01/2023
Updated: 07/09/2024

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

HVAC load includes:
    - includes 120V air handler for non-electric central furnace, e.g., if HP with secondary gas furance, HP ODU + 120V handler
    - HP heating load = HP + backup (even though for integrated backup, OS-HPXML assumes one of the two can be on at a time)
does not include:
    - shared heating/cooling
    - boiler pump

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
from typing import Optional

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

def get_nameplate_rating(df_rating, load_category, appliance, parameter="volt-amps"):
    row = df_rating.loc[(df_rating['load_category'] == load_category) & (df_rating['appliance'] == appliance)]
    return list(row[parameter])[0]

nameplate_rating = pd.read_csv("nameplate_rating_new_load.csv")
water_heater_electric_power_rating = get_nameplate_rating(nameplate_rating, 'water heater', 'electric')
water_heater_electric_tankless_1bath_power_rating = get_nameplate_rating(nameplate_rating, 'water heater', 'electric tankless, one bathroom')
water_heater_electric_tankless_more_1bath_power_rating = get_nameplate_rating(nameplate_rating, 'water heater', 'electric tankless, more than one bathroom')
water_heater_heat_pump_power_rating = get_nameplate_rating(nameplate_rating, 'water heater', 'heat pump')
water_heater_heat_pump_120_power_rating = get_nameplate_rating(nameplate_rating, 'water heater', 'heat pump, 120V, shared')

washer_power_rating = get_nameplate_rating(nameplate_rating, "clothes washer", "electric")
dryer_elctric_ventless_power_rating = get_nameplate_rating(nameplate_rating, 'clothes dryer', 'electric ventless')
dryer_elctric_power_rating = get_nameplate_rating(nameplate_rating, 'clothes dryer', 'electric')
dryer_elctric_120_power_rating = get_nameplate_rating(nameplate_rating, 'clothes dryer', 'electric, 120V')
dryer_heat_pump_power_rating = get_nameplate_rating(nameplate_rating, 'clothes dryer', 'heat pump')
dryer_heat_pump_120_power_rating = get_nameplate_rating(nameplate_rating, 'clothes dryer', 'heat pump, 120V')

range_elctric_power_rating = get_nameplate_rating(nameplate_rating, 'range/oven', 'electric')
range_induction_power_rating = get_nameplate_rating(nameplate_rating, 'range/oven', 'induction')
range_elctric_120_power_rating = get_nameplate_rating(nameplate_rating, 'range/oven', 'electric, 120V')
range_induction_120_power_rating = get_nameplate_rating(nameplate_rating, 'range/oven', 'induction, 120V')

dishwasher_power_rating = get_nameplate_rating(nameplate_rating, "dishwasher", "electric")
hot_tub_spa_power_rating = get_nameplate_rating(nameplate_rating, 'hot tub/spa', 'electric')
pool_heater_power_rating = get_nameplate_rating(nameplate_rating, 'pool heater', 'electric')
EVSE_power_rating_level1 = hot_tub_spa_power_rating = get_nameplate_rating(nameplate_rating, 'electric vehicle charger', 'electric, level 1')
EVSE_power_rating_level2 = hot_tub_spa_power_rating = get_nameplate_rating(nameplate_rating, 'electric vehicle charger', 'electric, level 2')


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

    Args:
        n: int | "auto"
            number of branches for general laundry load (exclude dryer), minimum 1
    """
    if row["completed_status"] != "Success":
        return np.nan
    if n == "auto":
        n = 1
    return 1500*n


def _general_load_washer(row):
    """If washer is larger than laundry branch circuit, add
        Pecan St clothes washers: 600-1440 W (1165 wt avg)
        Pecan St gas dryers: 600-2760 W (800 wt avg)

    Args:
        n: int | "auto"
            number of branches for general laundry load (exclude dryer), minimum 1
    """
    if row["completed_status"] != "Success":
        return np.nan

    if row["build_existing_model.clothes_washer_presence"] == "Yes":
        if washer_power_rating > 1500:
            return washer_power_rating
        return 0
    return 0


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
            if "120V" in row["build_existing_model.water_heater_efficiency"] or "120 V" in row["build_existing_model.water_heater_efficiency"]:
                return water_heater_heat_pump_120_power_rating
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


def _special_load_dryer(row, method):
    """Clothes Dryers. NEC 220-18
    Use 5000 watts or nameplate rating whichever is larger (in another version, use DF=1 for # appliance <=4)
    240V, 22/24/30A breaker (vented), 30/40A (ventless heat pump), 30A (ventless electric)
    """
    if row["completed_status"] != "Success":
        return np.nan

    if "Electric" not in row["build_existing_model.clothes_dryer"] or row["build_existing_model.clothes_dryer"] == "None":
        return 0

    if "Heat Pump" in row["build_existing_model.clothes_dryer"]:
        if "120V" in row["build_existing_model.clothes_dryer"] or "120 V" in row["build_existing_model.clothes_dryer"]:
            if method == "83":
                return 0
            if method == "87":
                return dryer_heat_pump_120_power_rating
            raise ValueError(f"Unsupported {method=}")
        return dryer_heat_pump_power_rating
    if "120V" in row["build_existing_model.clothes_dryer"] or "120 V" in row["build_existing_model.clothes_dryer"]:
        if method == "83":
            return 0
        if method == "87":
            return dryer_elctric_120_power_rating
        raise ValueError(f"Unsupported {method=}")
    if "Ventless" in row["build_existing_model.clothes_dryer"]:
        return dryer_elctric_ventless_power_rating
    return dryer_elctric_power_rating


def _special_load_cooking_range_oven(row): 
    """ Assuming a single electric range (combined oven/stovetop) for each dwelling unit """
    if row["completed_status"] != "Success":
        return np.nan

    if "Electric" not in row["build_existing_model.cooking_range"] or row["build_existing_model.cooking_range"]=="None":
        return 0

    if "Induction" in row["build_existing_model.cooking_range"]:
        if "120V" in row["build_existing_model.cooking_range"] or "120 V" in row["build_existing_model.cooking_range"]:
            return range_induction_120_power_rating
        return range_induction_power_rating 

    if "120V" in row["build_existing_model.cooking_range"] or "120 V" in row["build_existing_model.cooking_range"]:
        return range_elctric_120_power_rating

    return range_elctric_power_rating 


def _special_load_space_heating_no_ahu(row):
    if row["completed_status"] != "Success":
        return np.nan

    # shared heating is not part of dwelling unit's panel
    if row["build_existing_model.hvac_has_shared_system"] in ["Heating Only", "Heating and Cooling"]:
        return 0

    # heating load
    heating_type = get_heating_type(row["build_existing_model.hvac_heating_efficiency"])
    secondary_heating_type = get_heating_type(row["build_existing_model.hvac_secondary_heating_efficiency"])

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

    return heating_load


def _special_load_space_cooling_no_ahu(row):
    if row["completed_status"] != "Success":
        return np.nan

    # shared cooling is not part of dwelling unit's panel
    if row["build_existing_model.hvac_has_shared_system"] in ["Cooling Only", "Heating and Cooling"]:
        return 0

    cooling_type = get_cooling_type(row["build_existing_model.hvac_cooling_type"])
    cooling_load = hvac_cooling_conversion(
        row["upgrade_costs.size_cooling_system_primary_k_btu_h"],
        system_type=cooling_type
    )
 
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
    
    heating_load = _special_load_space_heating_no_ahu(row)
    cooling_load = _special_load_space_cooling_no_ahu(row)

    heating_type = get_heating_type(row["build_existing_model.hvac_heating_efficiency"])
    secondary_heating_type = get_heating_type(row["build_existing_model.hvac_secondary_heating_efficiency"])

    # Add AHU
    heat_ahu, cool_ahu = _get_air_handlers(row, heating_type, secondary_heating_type)
    heating_load += heat_ahu
    cooling_load += cool_ahu

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


def _special_load_evse(row, method):
    if row["completed_status"] != "Success":
        return np.nan

    if row["build_existing_model.electric_vehicle"] == "None":
        return 0
    if "Level 1" in row["build_existing_model.electric_vehicle"]:
        if method == "83":
            return 0
        if method == "87":
            return EVSE_power_rating_level1
        raise ValueError(f"Unsupported {method=}")
    if "Level 2" in row["build_existing_model.electric_vehicle"]:
        return EVSE_power_rating_level2


def _special_load_heat_pump_backup(row):
    if row["completed_status"] != "Success":
        return np.nan

    heat_pump_backup = hvac_heating_conversion(
        row["upgrade_costs.size_heat_pump_backup_primary_k_btu_h"], 
        system_type="Electric Resistance"
        )
    return heat_pump_backup


### -------- util funcs --------
def _get_heating_has_ducts(row) -> bool:
    return True if row["build_existing_model.hvac_heating_type"] in ["Ducted Heat Pump", "Ducted Heating"] else False

def _get_cooling_has_ducts(row) -> bool:
    return True if row["build_existing_model.hvac_cooling_type"] in ["Central AC", "Ducted Heat Pump"] else False

def _get_air_handlers(row, heating_type, secondary_heating_type) -> (float, float):
    """Typically you need more volume of air to cool the house than to heat it. 
    So the cooling requirements determine the size of the air handler. 
    However the air handler comes with the furnace. 
    So the air handler size determines the furnace size.

    Current logic: 
    - if gas furnace with CAC, use gas furnace (based on heat cap only, 120V)
    - if electric furnace with CAC, take max of heat/cool to determine AHU
    - if no ducted heating, use CAC (based on cool cap only)
    """
    if heating_type == "Heat Pump":
        if row["build_existing_model.hvac_has_ducts"] == "Yes":
            cooling_has_ducts = heating_has_ducts = True
        else:
            cooling_has_ducts = heating_has_ducts = False
    else:
        heating_has_ducts = _get_heating_has_ducts(row)
        cooling_has_ducts = _get_cooling_has_ducts(row)

    heat_ahu, cool_ahu = 0, 0

    if heating_has_ducts:
        if heating_type == "fuel" or secondary_heating_type == "fuel":
            # if dual fuel, retain old 120V AHU
            heat_ahu = hvac_120V_air_handler(row["upgrade_costs.size_heating_system_primary_k_btu_h"])
        else:
            heat_ahu = hvac_240V_air_handler(row["upgrade_costs.size_heating_system_primary_k_btu_h"])

    if cooling_has_ducts:
        if heating_has_ducts:
            if heating_type == "fuel" or secondary_heating_type == "fuel":
                # gas furnace with CAC, use gas furnace
                cool_ahu = heat_ahu
            else:
                cool_ahu = heat_ahu = max(
                    heat_ahu, 
                    hvac_240V_air_handler(row["upgrade_costs.size_cooling_system_primary_k_btu_h"])
                    )
        else:
            cool_ahu = hvac_240V_air_handler(row["upgrade_costs.size_cooling_system_primary_k_btu_h"])

    return (heat_ahu, cool_ahu)


def get_cooling_type(cool_eff) -> Optional[str]:
    if "Room AC" in cool_eff:
        return "Room AC"
    if "AC" in cool_eff:
        return "Central AC"
    if "Heat Pump" in cool_eff:
        return "Heat Pump"
    if cool_eff in ["None", "Shared Cooling"]:
        return None
    if cool_eff == "Evaporative Cooler":
        raise ValueError(f"Unsupported: {cool_eff}")
    raise ValueError("Unknown cooling type")
    

def get_heating_type(heat_eff) -> Optional[str]:
    if ("ASHP" in heat_eff) or ("MSHP" in heat_eff):
        return "Heat Pump"
    if ("Electric" in heat_eff):
        return "Electric Resistance"
    if ("GSHP" in heat_eff):
        raise ValueError(f"Unsupported: {heat_eff}")
    if heat_eff in ["None", "Shared Heating"]:
        return None
    return "fuel"


def hvac_240V_air_handler(nom_cap) -> float:
    ahu_volt = get_nameplate_rating(nameplate_rating, 'space heating/cooling', 'electric air handler', parameter="voltage")
    amp_para = get_nameplate_rating(nameplate_rating, 'space heating/cooling', 'electric air handler', parameter="amperage").split(",")
    ahu_amp = min(float(amp_para[2]), float(amp_para[0])*float(nom_cap) + float(amp_para[1]))
    return ahu_volt * ahu_amp


def hvac_120V_air_handler(nom_cap) -> float:
    ahu_volt = get_nameplate_rating(nameplate_rating, 'space heating', 'fuel air handler', parameter="voltage")
    amp_para = get_nameplate_rating(nameplate_rating, 'space heating', 'fuel air handler', parameter="amperage").split(",")
    ahu_amp = min(float(amp_para[2]), float(amp_para[0])*float(nom_cap) + float(amp_para[1]))
    return ahu_volt * ahu_amp


def apply_va_linear_regression(nom_cap, load_category, appliance) -> float:
    volt = get_nameplate_rating(nameplate_rating, load_category, appliance, parameter="voltage")
    amp_para = get_nameplate_rating(nameplate_rating, load_category, appliance, parameter="amperage").split(",")
    amp = float(amp_para[0])*float(nom_cap) + float(amp_para[1])
    return volt * amp


def hvac_heating_conversion(nom_heat_cap, system_type=None) -> float:
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
    if system_type is None or system_type in ["None", "fuel"]:
        return 0

    nom_heat_cap = float(nom_heat_cap)
    if "Heat Pump" in system_type:
        return apply_va_linear_regression(nom_heat_cap, "space heating", "heat pump")
    if system_type == "Electric Resistance":
        return nom_heat_cap * KBTU_H_TO_W
    raise ValueError(f"Unknown {system_type=}")


def hvac_cooling_conversion(nom_cool_cap, system_type=None) -> float:
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
        return apply_va_linear_regression(nom_cool_cap, "space cooling", "heat pump")
    elif system_type == "Central AC":
        return apply_va_linear_regression(nom_cool_cap, "space cooling", "central ac")
    elif system_type == "Room AC":
        return apply_va_linear_regression(nom_cool_cap, "space cooling", "room ac")
    else:
        raise ValueError(f"Unknown {system_type=}")


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
        df = pd.read_parquet(filename)
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


def generate_plots(df: pd.DataFrame, output_dir: Path, sfd_only: bool = False):
    msg = " for Single-Family Detached only" if sfd_only else ""
    print(f"generating plots{msg}...")
    _plot_scatter(df, "amp_total_pre_upgrade_A_220_83", "amp_total_pre_upgrade_A_220_87", 
        title=None, output_dir=output_dir, sfd_only=sfd_only)
    for metric in ["amp_total_pre_upgrade_A_220_83", "amp_total_pre_upgrade_A_220_87"]:
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
        "load_washer",
        "load_dishwasher",
        "load_garbage_disposal",
        # "load_garbage_compactor",
        "load_well_pump",
        "load_pool_pump",
        
    ]
    return existing_loads_labels


def apply_existing_loads(row, method: str, n_kit: int = 2, n_ldr: int = 1) -> list[float]:
    """ Load summing method """
    if row["completed_status"] != "Success":
        return [np.nan for x in range(15)]

    existing_loads = [
            _special_load_space_conditioning(row), # max of heating or cooling
            _fixed_load_water_heater(row),
            _special_load_dryer(row, method),
            _special_load_cooking_range_oven(row),
            _fixed_load_hot_tub_spa(row),
            _special_load_pool_heater(row),
            _special_load_evse(row, method),

            _general_load_lighting(row), # sqft
            _general_load_kitchen(row, n=n_kit), # consider logic based on sqft
            _general_load_laundry(row, n=n_ldr), # consider logic based on sqft (up to 2)
            _general_load_washer(row),
            _fixed_load_dishwasher(row),
            _fixed_load_garbage_disposal(row),
            # _fixed_load_garbage_compactor(row),
            _fixed_load_well_pump(row),
            _special_load_pool_pump(row),
            
        ] # no largest motor load

    return existing_loads


def apply_demand_factor(x, threshold_load=8000):
    """
    Split load into the following tiers and apply associated multiplier factor
        If threshold_load == 8000:
            <= 8kVA : 1.00
            > 8kVA : 0.4
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


### -------- load method calcs --------
def calculate_existing_load_total_220_83(dfi: pd.DataFrame, n_kit: int = 2, n_ldr: int = 1, explode_result: bool = False, result_as_map: bool = False) -> pd.DataFrame:
    """
    Calculate existing load using 220.83(A)
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
    print("Performing NEC 220.83 (load-summing) (A) calculations...")
    df = dfi.copy()

    # Existing loads
    existing_loads = existing_load_labels()
    df_existing = pd.DataFrame(
        df.apply(lambda x: apply_existing_loads(x, "83", n_kit=n_kit, n_ldr=n_ldr), axis=1).to_list(),
        index = df.index, columns=existing_loads
        )
    # df_backup = df.apply(lambda x: _special_load_heat_pump_backup(x), axis=1).rename("load_hvac_hp_backup")

    # Total pre-upgrade load based on no new hvac
    total_load_pre = "load_total_pre_upgrade_VA_220_83"
    total_amp_pre = "amp_total_pre_upgrade_A_220_83"
    df_existing[total_load_pre] = df_existing.apply(lambda x: apply_total_load_220_83(x, has_new_hvac_load=False), axis=1)
    df_existing[total_amp_pre] = df_existing[total_load_pre] / 240

    df_result = pd.concat([
        df["building_id"],
        df_existing,
        # df_backup,
        ], axis=1)

    if explode_result:
        cols = df_result.columns
    else:
        cols = ["building_id", total_load_pre, total_amp_pre]

    if result_as_map:
        return df_result[cols]

    return df.join(df_result[cols].set_index("building_id"), on="building_id")


def calculate_existing_load_total_220_87(dfi: pd.DataFrame, result_as_map: bool = False) -> pd.DataFrame:
    """ Maximum demand method 
        - "report_simulation_output.peak_electricity_annual_total_w": timestep -- not available in EUSS RR1
        - "qoi_report.qoi_hourly_peak_magnitude_use_kw": peak of hourly aggregates, different from above
        - EUSS RR1 uses "qoi_report.qoi_peak_magnitude_use_kw"
    """
    print("Performing NEC 220.87 (max-load) calculations...")
    df = dfi.copy()

    # Total pre-upgrade load
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

    if result_as_map:
        cols = ["building_id", total_load_pre, total_amp_pre]
        return df[cols]

    return df



def main(
    baseline_filename: str | None = None, 
    plot: bool = False, sfd_only: bool = False, explode_result: bool = False, result_as_map: bool = False):
    if baseline_filename is None:
        baseline_filename = (
            Path(__file__).resolve().parent
            / "test_data"
            / "euss1_2018_results_up00_100.csv" # "euss1_2018_results_up00_400plus.csv"
        )
    else:
        baseline_filename = Path(baseline_filename)

    output_filedir = baseline_filename.parent / "nec_calculations"
    output_filedir.mkdir(parents=True, exist_ok=True) 
    ext = ""
    if explode_result:
        ext = "_exploded"
    if result_as_map:
        output_filename = output_filedir / (baseline_filename.stem.split(".")[0] + f"__res_map__nec_existing_load{ext}" + baseline_filename.suffix)
    else:
        output_filename = output_filedir / (baseline_filename.stem.split(".")[0] + f"__nec_existing_load{ext}" + baseline_filename.suffix)

    plot_dir_name = f"plots_sfd" if sfd_only else f"plots"
    output_dir = baseline_filename.parent / plot_dir_name / "nec_calculations" / "existing_load"
    output_dir.mkdir(parents=True, exist_ok=True) 

    plot_later = False
    if plot:
        if not output_filename.exists():
            plot_later = True
        else:
            dfo = read_file(output_filename, low_memory=False)
            for col in [ 
                "amp_total_pre_upgrade_A_220_83",  
                "amp_total_pre_upgrade_A_220_87",
            ]:
                dfo[col] = dfo[col].replace("", np.nan).astype(float)
            generate_plots(dfo, output_dir, sfd_only=sfd_only)
            sys.exit()
        
    df = read_file(baseline_filename, compression="infer", low_memory=False, sort_bldg_id=True)
    df = df[df["completed_status"]=="Success"].reset_index(drop=True)

    # Format
    columns = [x for x in df.columns if "build_existing_model" in x]
    df[columns] = df[columns].fillna("None")


    # --- NEW LOAD calcs ---
    # NEC 220.83 - Load Summing Method
    # NEC 220.87 - Maximum Demand Method
    if result_as_map:
        df1 = calculate_existing_load_total_220_83(df, n_kit=2, n_ldr=1, explode_result=explode_result, result_as_map=result_as_map)
        df2 = calculate_existing_load_total_220_87(df, result_as_map=result_as_map)
        dfo = df1.join(df2.set_index("building_id"), on="building_id")
    else:
        df1 = calculate_existing_load_total_220_83(df, n_kit=2, n_ldr=1, explode_result=explode_result)
        dfo = calculate_existing_load_total_220_87(df1)

    # --- save to file ---
    if output_filename.suffix == ".csv":
        dfo.to_csv(output_filename, index=False)
    elif output_filename.suffix == ".parquet":
        dfo.to_parquet(output_filename)
    print(f"File output to: {output_filename}")

    if plot_later:
        generate_plots(dfo, output_dir, sfd_only=sfd_only)


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
    msg = ""
    if not args.baseline_filename:
        msg = "Using test data files"
    print("======================================================")
    print(f"Existing load calculation using 2023 NEC 220.83 and 220.87\n{msg}")
    print("======================================================")
    main(
        args.baseline_filename,
        plot=args.plot, sfd_only=args.sfd_only, explode_result=args.explode_result, result_as_map=args.result_as_map
        )
