"""
Electrical Panel Project: Estimate panel capacity using NEC (What Year)
Standard method (DF=0.75 for fixed)
Optimal method (DF=0.4 for fixed)

NEC panel capacity = min. main circuit breaker size (A)

By: Lixi.Liu@nrel.gov
Date: 02/08/2023

-----------------
At a power factor of 1, kW = kVA
Continous load := max current continues for 3+ hrs
Branch circuit rating for continous load >= 1.25 x nameplate rating

-----------------
[1] STANDARD method overview:
Total Demand Load = General Load + Fixed Load + Special Load
Total Amperage = Total Demand / Circuit Voltage

Electrical circuit voltage = 
    * 240V for single-phase 120/240V service (most common)
    * 208V for three-phase 208/120V service

* General Load: 
    - lighting/recepticles + kitchen general + laundry general
    - Includes bathroom exhaust fans, most ceiling fans
    - Tiered demand factors for total General Load
* Fixed (fastened-in-place) Appliances: 
    - Water heater, dishwasher, garbage disposal, garbage compactor, 
    - Attic fan, central vacumm systems, microwave ...
    - At least 1/4 HP (500W), permanently fastened in place
    - ALWAYS exclude 3 special appliances: dryer, range, space heating & cooling 
    - Demand factor for total Fixed Load based on # of >=500W fixed appliances
* Special Appliances:
    - Clothes dryer, 
    - Range/oven,
    - Larger of space heating or cooling, 
    - Motor (usually AC compressor if cooling is larger, next is garbage disposal)
    - Hot tub (1.5-6kW + 1.5kW water pump), pool heater (~3kW), pool pump (0.75-1HP), well pump (0.5-5HP)
    - Demand factor depends on special appliance

EV charger:
    - Level 1 (slow): 1.2kW @ 120V (no special circuit)
    - Level 2 (fast): 6.2-19.2kW (7.6kW avg) @ 240V (likely dedicated circuit)
    Demand factor: CONTINUOUS load, may have its own section in newer NEC

TODO: Attached or Detached garage can have up to 1 branch of 120V, 20A

120V service line can provide up to 1.8kW, beyond that appliance needs to go to 240V

[2] OPTIMAL method overview:

"""

import pandas as pd
from pathlib import Path
import numpy as np
import math
import sys

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
    """General Lighting & Receptacle Loads. NEC 220-3(b)
    Not including open porches, garages, unused or unfinished spaces not adaptable for future use
    """
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
        if (row["build_existing_model.misc_extra_refrigerator"] != "None") or (
            row["build_existing_model.misc_freezer"] != "None"
        ):
            n += 2  # 2 additional branches added for misc refrigeration (outside kitchen)

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

    if (row["build_existing_model.clothes_washer_presence"] == "Yes") or (
        row["build_existing_model.clothes_dryer"] != "None"
    ):
        return n * 1500
    return 0


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
            return 1200  # 1/2 HP @ 115V from NEC Table 430-149
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


def _special_load_electric_range(row):
    """Ranges, ovens, Cooktops and other cooking appliances over 1750 watts. NEC 220-19.
    Look up values using Table 220-19 along with table footnotes
    http://www.naffainc.com/x/CB2/Elect/EHtmFiles/Table%20220-19.htm
    Table gives demand loads for:
        - Electric Range ,
        - Wall-Mounted Ovens,
        - Counter-Mounted Cooking Units, and
        - Other Household Cooking Appliances over 1.75kW Rating
    based on number of appliances and name plate power rating of each appliance
    (Column A to be used in all cases except as otherwise permitted in Note 3 below.)

    Always 240V
    """
    if row["completed_status"] != "Success":
        return np.nan

    if "Electric" not in row["build_existing_model.cooking_range"]:
        return 0

    if "Induction" in row["build_existing_model.cooking_range"]:
        # TODO: can give diversity
        # range-oven: 10-13.6kW rating (240V, 40A) or 8.4kW (240V, 50A) or 8kW (240V, 40A)
        # cooktop: 11-12kW rating (240V, 30/50A) or 15.4kW rating (240V, 40A), 7.2-8.6kW (240V, 30/45A)
        # electric wall oven: 4.5kW (120V, 30A or 240V, 20/30A)
        # For induction cooktop + electric wall oven = 11+0.65*4.5 = 14kW
        return 12500  # 40*240 or 14000

    ## Electric, non-induction
    # range-oven: 10-12.1-13.5kW (240V, 40A)
    # cooktop: 9.2kW (240V, 40A), 7.7-10.5kW (240V, 40/50A), 7.4kW (240V, 40A)
    # For cooktop + wall oven = 11+0.65*4.5 = 14kW or 0.65*(8+4.5) = 8kW
    return 10000  # or 12500


def _special_load_space_conditioning(row):
    """Heating or Air Conditioning. NEC 220-19.
    Take the larger between heating and cooling. Demand Factor = 1
    Include the air handler when using either one. (guessing humidifier too?)
    For heat pumps, include the compressor and the max. amount of electric heat which can be energized with the compressor running

    1Btu/h = 0.29307103866W

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
        ) * 293.07103866
    else:
        heating_load = 0

    if row["build_existing_model.hvac_heating_type"].startswith("Ducted"):
        heating_load += 3 * 115  # 3A x 115V (air-handler motor)

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
        )  # 3A x 115V (condenser fan motor) + 460 (blower motor)
        cooling_is_window_unit = False

    loads = np.array([heating_load, cooling_load])
    labels = np.array(["heating", "cooling"])

    # if cooling is max load, return non-zero motor size
    if labels[loads == max(loads)][0] == "cooling":
        if cooling_is_window_unit:
            cooling_motor /= row[
                "build_existing_model.bedrooms"
            ]  # TODO, need a method to decide largest room AC size
    else:
        cooling_motor = 0

    return max(loads), cooling_motor


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
        _special_load_well_pump(row),
    )

    return 0.25 * motor_size


def _special_load_hot_tub_spa(row):
    """
    Hot tub (1.5-6kW + 1.5kW water pump)
    """
    if row["completed_status"] != "Success":
        return np.nan

    if row["build_existing_model.misc_hot_tub_spa"] == "Electric":
        return 4500  # or 8000 (2HP)
    return 0


def _special_load_pool_heater(row):
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
        return 1 * 746
    if row["build_existing_model.misc_pool_pump"] == "0.75 HP Pump":
        return 0.75 * 746
    return 0


def _special_load_well_pump(row):
    """NEC 680
    Well pump (0.5-5HP)
    1HP = 746W
    """
    if row["completed_status"] != "Success":
        return np.nan

    # TODO: verify
    if row["build_existing_model.misc_well_pump"] == "National Average":
        return 0.127 * 746  # based on usage multiplier in options_lookup
    if row["build_existing_model.misc_well_pump"] == "Typical Efficiency":
        return 1 * 746  # based on usage multiplier in options_lookup
    if row["build_existing_model.misc_well_pump"] == "High Efficiency":
        return 0.67 * 746  # based on usage multiplier in options_lookup
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
            _special_load_hot_tub_spa(row),
            _special_load_pool_heater(row),
            _special_load_pool_pump(row),
            _special_load_well_pump(row),
        ]
    )
    return special_loads


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
    """Convert min_amperage_nec into standard panel sice
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
    df["demand_load_general_VA"] = df.apply(
        lambda x: general_load_total(x, n_kit="auto", n_ldr="auto"), axis=1
    )
    df["demand_load_fixed_VA"] = df.apply(lambda x: fixed_load_total(x), axis=1)
    df["demand_load_special_VA"] = df.apply(lambda x: special_load_total(x), axis=1)

    # df["nec_min_amp"] = df.apply(lambda x: min_amperage_nec(x, n_kit="auto", n_ldr="auto"), axis=1) # this is daisy-ed
    df["nec_min_amp"] = (
        df[
            ["demand_load_general_VA", "demand_load_fixed_VA", "demand_load_special_VA"]
        ].sum(axis=1)
        / 240
    )
    df["nec_electrical_panel_amp"] = df["nec_min_amp"].apply(
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

    df["amp_pct_delta"] = np.nan
    cond = df["peak_amp"] > df["nec_electrical_panel_amp"]
    df.loc[cond, "amp_pct_delta"] = (
        df["peak_amp"] - df["nec_electrical_panel_amp"]
    ) / df["nec_electrical_panel_amp"]

    new_columns = [x for x in df.columns if x not in df_columns]
    print(df.loc[cond, ["building_id"] + new_columns])

    # --- [2] NEC - OPTIMAL METHOD ----

    # --- save to file ---
    output_filename = filename.parent / (filename.stem + "__panels" + filename.suffix)
    df.to_csv(output_filename, index=False)
    print(f"File output to: {output_filename}")


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
