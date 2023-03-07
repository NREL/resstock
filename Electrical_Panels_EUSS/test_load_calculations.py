# TEST CASES

import postprocess_electrical_panel_size_nec as nec
import pandas as pd

# test apply_demand_factor_to_general_load
def test_all():
    a = nec.apply_demand_factor_to_general_load(1000)
    b = nec.apply_demand_factor_to_general_load(10000)
    c = nec.apply_demand_factor_to_general_load(13000)

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

    out1 = df_test1.apply(lambda x: nec._general_load_lighting(x), axis=1)

    assert out1[0] == 3*(2000 + 24*24)

    #test _optional_load_lighting
    test2 = {
        "upgrade_costs.floor_area_conditioned_ft_2": [2000],
        "build_existing_model.geometry_garage": ["2 Car"],
        "build_existing_model.geometry_building_type_recs": ["Single-Family Detached"]
        }
    df_test2 = pd.DataFrame(test2)

    out2 = df_test2.apply(lambda x: nec._optional_load_lighting(x), axis=1)

    assert out2[0] == 3*(2000)

    # test _general_load_kitchen
    test3 = {
        "build_existing_model.misc_extra_refrigerator": ["None"],
        "build_existing_model.misc_freezer": ["EF 12, National Average"],
        "completed_status": ["Success"]
    }
    df_test3 = pd.DataFrame(test3)
    out3 = df_test3.apply(lambda x: nec._general_load_kitchen(x), axis=1)
    assert out3[0] == 3000

    # test _general_load_laundry
    test4 = {
        "completed_status": ["Success"]
    }
    df_test4 = pd.DataFrame(test4)
    out4 = df_test4.apply(lambda x: nec._general_load_laundry(x), axis=1)
    assert out4[0] == 1500

    # test _fixed_load_water_heater

    test5 = {
        "completed_status": ["Success"],
        "build_existing_model.water_heater_in_unit": ["Yes"],
        "build_existing_model.water_heater_fuel": ["Electricity"],
        "build_existing_model.water_heater_efficiency": ["Electric Tankless"]
        }    
    df_test5 = pd.DataFrame(test5)
    out5 = df_test5.apply(lambda x: nec._fixed_load_water_heater(x),axis=1)
    assert out5[0] == 27000

    test6 = {
        "completed_status": ["Success"],
        "build_existing_model.water_heater_in_unit": ["Yes"],
        "build_existing_model.water_heater_fuel": ["Electricity"],
        "build_existing_model.water_heater_efficiency": ["Electric Standard"]
        }    
    df_test6 = pd.DataFrame(test6)
    out6 = df_test6.apply(lambda x: nec._fixed_load_water_heater(x),axis=1)
    assert out6[0] == 4500

    test7 = {
        "completed_status": ["Success"],
        "build_existing_model.water_heater_in_unit": ["Yes"],
        "build_existing_model.water_heater_fuel": ["Natural Gas"],
        "build_existing_model.water_heater_efficiency": ["Natural Gas Standard"]
        }    
    df_test7 = pd.DataFrame(test7)
    out7 = df_test7.apply(lambda x: nec._fixed_load_water_heater(x),axis=1)
    assert out7[0] == 0

    # test _fixed_load_dishwasher
    test8 = {
        "completed_status": ["Success"],
        "build_existing_model.dishwasher": ["290 Rated kWh, 80% Usage"]
    }
    df_test8 = pd.DataFrame(test8)
    out8 = df_test8.apply(lambda x: nec._fixed_load_dishwasher(x),axis=1)
    assert out8[0] == 15*120

    #test _fixed_garbage_disposal
    test9 = {
        "completed_status": ["Success"],
        "build_existing_model.vintage": ["2000-09"],
        "build_existing_model.geometry_floor_area": ["750-999"]
    }
    df_test9 = pd.DataFrame(test9)
    out9 = df_test9.apply(lambda x: nec._fixed_load_garbage_disposal(x),axis=1)
    assert out9[0] == 800

    # test apply_opt_demand_factor
    assert nec.apply_opt_demand_factor(12000) == 10000 + .4*2000

    # test min_amperage_main_breaker(x):
    assert nec.min_amperage_main_breaker(120) == 125
    # assert min_amperage_main_breaker(770) == 800 # commented to avoid false warning
    assert nec.min_amperage_main_breaker(90) == 100
