import pandas as pd
import numpy as np
import re


### Helper constants
NG_HEAT_CONTENT = (
    1034.0  # BTU/ft3 - https://www.eia.gov/dnav/ng/ng_cons_heat_a_EPG0_VGTH_btucf_a.htm
)
MBTU_TO_THERM = 10
KBTU_TO_THERM = 1e-2
MBTU_TO_KWH = 293.07107
KBTU_TO_KWH = 0.29307107
KBTU_TO_MBTU = 1e-3
MBTU_TO_TBTU = 1e-6
KWH_TO_MWH = 1e-3
KWH_TO_GWH = 1e-6

### [4] Helper/utility funcs
def end_use_category_dictionary():
    """Dictionary of ResStock standard output end uses and their reassignment
    End uses cover all fuel type
    """
    enduse_category_dict = {
        "battery": "pv_gen_storage",
        "ceiling_fan": "ceiling_fan",
        "clothes_dryer": "clothes_dryer",
        "clothes_washer": "clothes_washer",
        "cooling": "cooling",
        "cooling_fans_pumps": "hvac_fan_pump",
        "dehumidifier": "hvac_fan_pump",
        "dishwasher": "dishwasher",
        "electric_vehicle_charging": "ev",
        "fireplace": "fireplace",
        "freezer": "freezer",
        "generator": "pv_gen_storage",
        "grill": "cooking",
        "heating": "heating",
        "heating_fans_pumps": "hvac_fan_pump",
        "heating_heat_pump_backup": "heating",
        "hot_tub_heater": "pool_hot_tub",
        "hot_tub_pump": "pool_hot_tub",
        "hot_water": "hot_water",
        "hot_water_recirc_pump": "hot_water",
        "hot_water_solar_thermal_pump": "hot_water",
        "lighting": "exterior_lighting",
        "lighting_exterior": "exterior_lighting",
        "lighting_garage": "exterior_lighting",
        "lighting_interior": "interior_lighting",
        "mech_vent": "vent_fans",
        "mech_vent_precooling": "vent_fans",
        "mech_vent_preheating": "vent_fans",
        "pv": "pv_gen_storage",
        "plug_loads": "plug_loads",
        "pool_heater": "pool_hot_tub",
        "pool_pump": "pool_hot_tub",
        "range_oven": "cooking_range",
        "refrigerator": "refrigerator",
        "television": "plug_loads",
        "well_pump": "well_pump",
        "whole_house_fan": "hvac_fan_pump",
    }

    return enduse_category_dict


def divide_iqr_cohort_based_on(df, metric):
    p25 = df[metric].quantile(0.25)
    p75 = df[metric].quantile(0.75)
    col = pd.Series("p25-p75", index=df.index)
    col.loc[df[metric] < p25] = "<p25"
    col.loc[df[metric] > p75] = ">p75"

    return col


def extract_left_edge(val):
    # for sorting things like AMI
    if val is None:
        return np.nan
    if not isinstance(val, str):
        return val
    first = val[0]
    if re.search(r"\d", val) or first in ["<", ">"] or first.isdigit():
        vals = [
            int(x)
            for x in re.split("\-| |\%|\<|\+|\>|s|th|p", val)
            if re.match("\d", x)
        ]
        if len(vals) > 0:
            num = vals[0]
            if "<" in val:
                num -= 1
            if ">" in val:
                num += 1
            return num
    return val


def sort_index(df, axis="index", **kwargs):
    """axis: ['index', 'columns']"""
    if axis in [0, "index"]:
        try:
            df = df.reindex(sorted(df.index, key=extract_left_edge, **kwargs))
        except TypeError:
            df = df.sort_index()
        return df
    if axis in [1, "columns"]:
        col_index_name = df.columns.name
        try:
            cols = sorted(df.columns, key=extract_left_edge, **kwargs)
        except TypeError:
            cols = sorted(df.columns)
        df = df[cols]
        df.columns.name = col_index_name
        return df
    raise ValueError(f"axis={axis} is invalid")


def get_conversion_factor(metric):
    factor = 1
    new_metric = metric
    if "electricity" in metric:
        if "m_btu" in metric:
            factor = MBTU_TO_KWH
            new_metric = metric.replace("m_btu", "kwh")
        elif "k_btu" in metric:
            factor = KBTU_TO_KWH
            new_metric = metric.replace("k_btu", "kwh")
    elif "natural_gas" in metric:
        if "m_btu" in metric:
            factor = MBTU_TO_THERM
            new_metric = metric.replace("m_btu", "therm")
        elif "k_btu" in metric:
            factor = KBTU_TO_THERM
            new_metric = metric.replace("k_btu", "therm")

    if "." in new_metric:
        new_metric = new_metric.split(".")[-1]

    return factor, new_metric


def get_95_confidence_interval(data):
    """data: pd.Series"""
    avg = data.mean()
    delta = 1.96 * data.std() / np.sqrt(len(data))
    return avg - delta, avg + delta


def get_median_from_bin(value_bin, lower_multiplier=0.9, upper_multipler=1.1):
    if "<" in value_bin:
        return float(value_bin.strip("<")) * lower_multiplier
    if "+" in value_bin:
        return float(value_bin.strip("+")) * upper_multipler

    return np.mean([float(x) for x in value_bin.split("-")])
