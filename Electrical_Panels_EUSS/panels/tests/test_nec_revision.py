
"""
Requires env with python >= 3.10
-**
Electrical Panel Project: Estimate existing and new load in homes using 2026 revised NEC per LBNL
Load Summing Method: 220.83
Maximum Demand Method: 220.87

NEC panel capacity = min. main circuit breaker size (A)

By: Lixi.Liu@nrel.gov, Ilan.Upfal@nrel.gov
Date: 07/09/2024
Updated: 07/09/2024

-----------------

[220.83] - Load Summing Method
# Revision: 2 kVA/sqft instead of 3, no A/B sections, new demand factors
Generally, sum the following loads and then apply tiered demand load factors to the total load (see CAVEATS)
1) general lighting and receptable loads at 2 VA/sqft;
2) at least 2 branch circuits for kitchen and 1 branch circuit for laundry at 1.5 kVA per branch; and
3) all appliances that are fastened in place and permanently connected:
   - HVAC (taken as the larger nameplate of space heating or cooling), 
   - water heaters,
   - clothes dryers, 
   - cooking ranges/ovens, 
   - dishwashers,
   - EVSE (individual branch circuit), 
   - hot tubs, pool heaters, pool pumps, well pumps, garbage disposals, garbage compactors, and 
   - other fixed appliances with at least a 1/4 HP (500W) nameplate rating.

Total Load = 100% of first 8 kVA existing load + 40% of remaining existing load + \
80% new EVSE + 80% new ER space heating + 50% all other new loads
This means: 
If adding HP and keeping existing ER as backup,
    - remove cooling from existing load
    - add HP at 50% (likely heating-dominant)
If new HVAC is HP+ER backup, 
    - remove heating and cooling from existing load
    - add ER at 80%, HP at 50% (likely heating-dominant)
If replacing existing heating with ER heating,
    - determine dominance unadjusted
    - if heating-dominant, remove cooling from existing, add ER at 80%
    - if cooling-dominant, no action

HVAC load includes:
    - includes 120V air handler for non-electric central furnace, e.g., if HP with secondary gas furance, HP ODU + 120V handler
    - HP heating load = HP + backup (even though for integrated backup, OS-HPXML assumes one of the two can be on at a time)
does not include:
    - shared heating/cooling
    - boiler pump

[220.87] - Maximum Demand Method
# Revision: net load change instead of new loads to add on top of 125% peak, demand factors from 220.83 applicable to net change
# Different ways to determine peak if preceding year data is incomplete or low resolution
Existing Peak = 125% x 15_min_electricity_peak (1-full year)
Net change = New Load - Existing Load replaced
Adjusted net change = 80% net EVSE + 80% net ER space heating + 50% all other net loads
Total Load = Existing Peak + Adjusted net change

Adjustment made if hourly data is used, if less than 1 year of data is available
Load can account for partial usage (per Parts III-IV)
"""

import pytest
import pandas as pd
from pathlib import Path
import numpy as np
import math
import argparse
import sys
from itertools import chain
from typing import Optional


file_dir = Path(".").resolve() / "test_data" / "nec_calculations"
panel_30k_dir = Path("/Volumes/Lixi_Liu/panels_results_30k_updated_cost")

@pytest.fixture
def baseline_euss():
    file_path = file_dir / "euss1_2018_results_up00_100.csv"
    df = pd.read_csv(file_path, low_memory=False, keep_default_na=False)
    return df

@pytest.fixture
def upgrade_result_euss():
    # Electrification with min-eff HP + electric backup
    file_path = file_dir / "euss1_2018_results_up07_100__2026nec_new_load_exploded.csv"
    if not file_path.exists():
        raise FileNotFoundError(f"{file_path=}\n does not exist, run python postprocess_panel_new_load_nec_revision.py -x")
    df = pd.read_csv(file_path, low_memory=False, keep_default_na=False)
    return df

@pytest.fixture
def baseline_panel():
    # 30k run for panels project
    file_path = panel_30k_dir / "results_up00.csv"
    df = pd.read_csv(file_path, low_memory=False, keep_default_na=False)
    return df


@pytest.fixture
def upgrade_result_panel():
    # Electrification with min-eff HP + existing backup
    file_path = panel_30k_dir / "nec_calculations" / "results_up08_cost_updated__2026nec_new_load_exploded.csv"
    if not panel_30k_dir.exists():
        print(f"{panel_30k_dir=} does not exist, need to plug in external hard drive")
        sys.exit()
    if not file_path.exists():
        raise FileNotFoundError(f"{file_path=}\n does not exist, run python postprocess_panel_new_load_nec_revision.py -x")
    df = pd.read_csv(file_path, low_memory=False, keep_default_na=False)
    return df


def filter_to_homes_with_fuels(baseline):
    # buildings with non-electric heating, water heating, cooking, or dryer
    cond = baseline["build_existing_model.heating_fuel"]!="Electricity"
    cond &= baseline["build_existing_model.water_heater_fuel"]!="Electricity"
    cond &= ~baseline["build_existing_model.cooking_range"].str.contains("Electric")
    cond &= ~baseline["build_existing_model.clothes_dryer"].str.contains("Electric")
    cond &= baseline["build_existing_model.cooking_range"]!="None"
    cond &= baseline["build_existing_model.clothes_dryer"]!="None"
    return baseline.loc[cond, "building_id"].to_list()


def apply_demand_factor(load):
    if load < 8000:
        return load
    return 8000 + (load - 8000)*0.4


def check_calculation_by_id(bldg_id, baseline, upgrade_result):
    dfb = baseline.loc[baseline["building_id"]==bldg_id].iloc[0]
    dfu = upgrade_result.loc[upgrade_result["building_id"]==bldg_id].iloc[0]

    primary_load_cols = [
        "load_hvac_primary_heating_heat_pump", 
        "load_hvac_primary_heating_electric_resistance",
        "load_hvac_secondary_heating_heat_pump", 
        "load_hvac_secondary_heating_electric_resistance", 
        "load_hvac_heat_pump_backup", 
        "load_hvac_heating_air_handler", 
        "load_water_heater",
        "load_dryer",
        "load_range_oven",
        ]
    second_load_cols = [
        "load_hvac_cooling", 
        "load_hvac_cooling_air_handler",
        "load_hot_tub_spa",
        "load_pool_heater",
        "load_evse",
    ]
    other_load_cols = [
        "load_lighting",
        "load_kitchen",
        "load_laundry",
        "load_dishwasher",
        "load_garbage_disposal",
        "load_garbage_compactor",
        "load_well_pump",
        "load_pool_pump",
    ]

    # check existing loads
    primary_no_ahu_cols = [x for x in primary_load_cols if "air_handler" not in x]
    assert dfu[primary_no_ahu_cols].astype(float).sum() == 0, f"{bldg_id=} should have 0 value for all \n{primary_no_ahu_cols=}"
    floor_area = float(dfu["upgrade_costs.floor_area_conditioned_ft_2"])
    garage_depth = 24 # ft
    match dfb["build_existing_model.geometry_garage"]:
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
    floor_area += garage_depth*garage_width
    assert round(floor_area*2,1) == round(float(dfu["load_lighting"]),1), f"{bldg_id=} error in load_lighting"
    heating_cols = [x for x in primary_load_cols if "heating" in x or "heat_pump" in x]
    cooling_cols = [x for x in second_load_cols if "cooling" in x]
    primary_non_hvac_cols = [x for x in primary_load_cols if x not in heating_cols]
    second_non_hvac_cols = [x for x in second_load_cols if x not in cooling_cols]
    heating_load, cooling_load = dfu[heating_cols].sum(), dfu[cooling_cols].sum()
    if heating_load > cooling_load:
        assert dfu["load_hvac_determinant"] == "heating", f"{bldg_id=} should have heating dominance"
        hvac_load = heating_load
    elif heating_load < cooling_load:
        assert dfu["load_hvac_determinant"] == "cooling", f"{bldg_id=} should have cooling dominance"
        hvac_load = cooling_load
    else:
        assert dfu["load_hvac_determinant"] == "heating/cooling", f"{bldg_id=} should have heating/cooling dominance"
        hvac_load = heating_load

    existing_total_load = hvac_load + dfu[primary_non_hvac_cols+second_non_hvac_cols+other_load_cols].sum()
    existing_total_load = apply_demand_factor(existing_total_load)
    assert round(existing_total_load,1) == round(float(dfu["load_total_pre_upgrade_VA_220_83"]),1), f"{bldg_id=} error in load_total_pre_upgrade_VA_220_83"

    # check new loads
    assert dfu["loads_upgraded"] == "['load_hvac', 'load_water_heater', 'load_dryer', 'load_range_oven']", f"{bldg_id=} error in load_upgraded"

    new_load_hp = (0.626*float(dfu["upgrade_costs.size_cooling_system_primary_k_btu_h"])+1.634)*230
    assert round(new_load_hp,1) == round(float(dfu["new_load_hvac_primary_heating_heat_pump"]),1), f"{bldg_id=} error in new_load_hvac_primary_heating_heat_pump"
    new_load_hpbk = dfu["upgrade_costs.size_heat_pump_backup_primary_k_btu_h"]*293.07107
    assert round(new_load_hpbk, 1) == round(float(dfu["new_load_hvac_heat_pump_backup"]),1), f"{bldg_id=} error in new_load_hvac_heat_pump_backup"

    # specific to heat pump upgrade
    if dfb["build_existing_model.hvac_has_ducts"]=="Yes":
        assert bool(dfu["new_load_hvac_heating_has_ducts"])==True, f"{bldg_id=} should have True for new_load_hvac_heating_has_ducts"
        assert bool(dfu["new_load_hvac_cooling_has_ducts"])==True, f"{bldg_id=} should have True for new_load_hvac_cooling_has_ducts"
        assert float(dfu["new_load_hvac_heating_air_handler"])>0, f"{bldg_id=} should have non-zero ew_load_hvac_heating_air_handler"
        assert float(dfu["new_load_hvac_cooling_air_handler"])>0, f"{bldg_id=} should have non-zero ew_load_hvac_cooling_air_handler"

    if dfb["build_existing_model.hvac_has_ducts"]=="No":
        assert bool(dfu["new_load_hvac_heating_has_ducts"])==False, f"{bldg_id=} should have False for new_load_hvac_heating_has_ducts"
        assert bool(dfu["new_load_hvac_cooling_has_ducts"])==False, f"{bldg_id=} should have False for new_load_hvac_cooling_has_ducts"
        assert dfu["new_load_hvac_heating_air_handler"]=="", f"{bldg_id=} should have null for new_load_hvac_heating_air_handler"
        assert dfu["new_load_hvac_cooling_air_handler"]=="", f"{bldg_id=} should have null for new_load_hvac_cooling_air_handler"

    assert float(dfu["new_load_water_heater"])==4500, f"{bldg_id=} error in new_load_water_heater"
    assert float(dfu["new_load_range_oven"])==12000, f"{bldg_id=} error in new_load_range_oven"
    if "Ventless" in dfb["build_existing_model.clothes_dryer"]:
        assert float(dfu["new_load_dryer"]) == 2640, f"{bldg_id=} should have 2640 for electric ventless dryer"
    else:
        assert float(dfu["new_load_dryer"]) == 5760, f"{bldg_id=} should have 5760 for electric dryer"

    assert dfu["post_load_hvac_determinant"] == "heating", f"{bldg_id=} should have heating dominance post-upgrade"

    # check post-upgrade load calculations
    # 220.83
    post_existing_load = 0
    post_new_load = 0
    for col in primary_load_cols+second_load_cols:
        new_col = "new_"+col
        if dfu[new_col] == "":
            dfu[new_col] = 0
        else:
            dfu[new_col] = float(dfu[new_col])
        if dfu[col] == "":
            dfu[col] = 0
        else:
            dfu[col] = float(dfu[col])

        if dfu[new_col] > 0:
            if "heating" in dfu["post_load_hvac_determinant"]:
                if "primary_heating_electric_resistance" in new_col or "backup" in new_col:
                    post_new_load += 0.8*dfu[new_col]
                    continue
                elif "cooling" in new_col:
                    continue  
                elif "secondary_heating" in new_col:
                    post_existing_load += dfu[new_col]
                    continue
            else:
                if "heating" in new_col or "backup" in new_col:
                    continue
            post_new_load += 0.5*dfu[new_col]
        else:
            post_existing_load += dfu[col]
        # print(dfu[[col, new_col]]); print(post_existing_load, post_new_load)
        # breakpoint()

    post_existing_load += dfu[other_load_cols].sum()
    post_existing_load = apply_demand_factor(post_existing_load)
    post_total_load = post_existing_load + post_new_load
    assert round(post_total_load,1) == round(float(dfu["load_total_post_upgrade_VA_220_83"]),1), f"{bldg_id=} error in load_total_post_upgrade_VA_220_83"
    
    # 220.87
    if dfb["build_existing_model.vacancy_status"] == "Occupied":
        assert round(float(dfu["net_change_in_load_total_VA_220_87"]),1) == round(float(dfu["load_total_post_upgrade_VA_220_83"]) - float(dfu["load_total_pre_upgrade_VA_220_83"]),1), f"{bldg_id=} error in net_change_in_load_total_VA_220_87"

        peak_col = "report_simulation_output.peak_electricity_annual_total_w"
        mult = 1
        if peak_col not in dfb.index:
            peak_col = "qoi_report.qoi_peak_magnitude_use_kw"
            mult = 1000
        existing_total_load_87 = float(dfb[peak_col])*1.25*mult
        assert round(existing_total_load_87, 1) == round(float(dfu["load_total_pre_upgrade_VA_220_87"]),1), f"{bldg_id=} error in load_total_pre_upgrade_VA_220_87"
        assert round(float(dfu["load_total_post_upgrade_VA_220_87"]),1)== round(float(dfu["load_total_pre_upgrade_VA_220_87"])+float(dfu["net_change_in_load_total_VA_220_87"]),1), f"{bldg_id=} error in load_total_post_upgrade_VA_220_87"


# --- Tests ---
def test_nec_revision_euss_test_data(baseline_euss, upgrade_result_euss):
    building_ids = filter_to_homes_with_fuels(baseline_euss)
    for bldg_id in building_ids:
        check_calculation_by_id(bldg_id, baseline_euss, upgrade_result_euss)


def test_nec_revision_existing_heating_as_backup(baseline_panel, upgrade_result_panel):
    building_ids = filter_to_homes_with_fuels(baseline_panel)
    if len(building_ids) > 5:
        building_ids = building_ids[:5]
    for bldg_id in building_ids:
        check_calculation_by_id(bldg_id, baseline_panel, upgrade_result_panel)
