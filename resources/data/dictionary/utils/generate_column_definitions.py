"""
This script generates the column_definitions.csv file from the outputs.csv and inputs.csv files.
This script only needs to be run when the outputs.csv file is updated.
"""

import polars as pl
import pathlib
import re
from common import *


endues_energy_col_re = re.compile(
    rf"^report_simulation_output\.(fuel|end)_use_({fuel_pattern_annual})_(\w+)_(kwh|therm|mbtu|m_btu)$"
)
emissions_re = re.compile(
    rf"^report_simulation_output\.emissions_co_2_e_(\w+|<emissions_scenario_name>)_({fuel_pattern_annual})_(total)_lb$"
)
emissions_all_fuel_re = re.compile(
    rf"^report_simulation_output\.emissions_co_2_e_(\w+|<emissions_scenario_name>)_(total)_lb$"
)
energy_use_re = re.compile(
    r"^report_simulation_output\.energy_use_(net|total)_(m_btu)$"
)
hot_water_re = re.compile(
    r"^report_simulation_output\.hot_water_(\w+)_gal$"
)
load_delivered_re = re.compile(
    r"^report_simulation_output\.load_(cooling|heating|hot_water)_delivered_m_btu$"
)
peak_electricity_re = re.compile(
    r"^report_simulation_output\.peak_electricity_(summer|winter)_total_w$"
)
peak_load_re = re.compile(
    r"^report_simulation_output\.peak_load_(cooling|heating)_delivered_k_btu_hr$"
)
unmet_hours_re = re.compile(
    r"^report_simulation_output\.unmet_hours_(cooling|heating)_hr$"
)
upgrade_costs_re = re.compile(
    r"^upgrade_costs\.(?!.*(_name|_yrs|_usd|applicable|debug)$).*$"
)
bills_re = re.compile(
    rf"^report_utility_bills\.(\w+|<utility_bills_scenario_name>)_({fuel_pattern_annual})_total_usd$"
)
all_bills_re = re.compile(
    rf"^report_utility_bills\.(\w+|<utility_bills_scenario_name>)_total_usd$"
)
all_outcols_re = [endues_energy_col_re, emissions_re, emissions_all_fuel_re, energy_use_re, hot_water_re, load_delivered_re,
                  peak_electricity_re, peak_load_re, unmet_hours_re, upgrade_costs_re, bills_re, all_bills_re]
ts_enduse_re = re.compile(fr"^(End|Fuel) Use: ({fuel_pattern}): (.*)$")
ts_energy_use_re = re.compile(r"^Energy Use: (Net|Total)$")
ts_fuel_emissions_re = re.compile(fr"^Emissions: CO2e: ([\w _<>]+): ({fuel_pattern}): Total$")
ts_emissions_re = re.compile(r"^Emissions: CO2e: ([\w _<>]+): Total$")
ts_load_re = re.compile(r"^Load: (Cooling|Heating|Hot Water): Delivered$")
ts_zone_temp_re = re.compile(r"^Zone Mean Air Temperature: ([\w -]+)$")
ts_outdoor_temp_re = re.compile(r"^Site Outdoor Air Drybulb Temperature: Environment$")


def shrink_colname(col):
    col_parts = col.split(".")
    if col_parts[0] != "out":
        return col[:63]
    if col_parts[-1] == "energy_consumption_intensity":
        max_len = 63
    elif col_parts[-1] == "energy_consumption":
        max_len = 53  # 63 - len("_intensity")
    else:
        max_len = 63
    if len(col) > max_len:
        n_dots = len(col_parts) - 1
        if col_parts[-1].startswith("energy_consumption"):
            len_avail = (
                63
                - n_dots
                - len(col_parts[0])
                - len(col_parts[1])
                - len("energy_consumption_intensity")
            )
            name_replacements = [
                ("exterior", "ext"),
                ("lighting", "light"),
                ("heat_pump_backup", "hp_bkup"),
                ("precooling", "precool"),
                ("preheating", "preheat"),
                ("electric_vehicle", "ev"),
            ]
            for x, y in name_replacements:
                col_parts[2] = col_parts[2].replace(x, y)
            col_parts[2] = col_parts[2][:len_avail]
        elif col_parts[-1] == "co2e_kg":
            len_avail = (
                63 - n_dots - sum(len(x) for i, x in enumerate(col_parts) if i != 2)
            )
            col_parts[2] = col_parts[2][:len_avail]
        else:
            assert False
        return ".".join(col_parts)
    else:
        return col

def convert_annual_col(col):
    if not col:
        return None, None, None
    if col.startswith("build_existing_model."):
        if col == "build_existing_model.sample_weight":
            return "weight", "", 1.0
        return col.replace("build_existing_model.", "in."), "", 1.0
    if m1 := endues_energy_col_re.match(col):
        fuel_or_end, fueltype, enduse, fuelunits = m1.groups()
        newcol = shrink_colname(f"out.{fueltype}.{enduse}.energy_consumption")
        if fuelunits in energy_unit_conv_to_kwh:
            new_unit = "kwh"
            unit_conversion_factor = energy_unit_conv_to_kwh[fuelunits]
        else:
            assert fuelunits == "kwh"
            unit_conversion_factor = 1.0
        return newcol, new_unit, unit_conversion_factor
    elif m2 := emissions_re.match(col):
        emissions_scenario, fueltype, enduse = m2.groups()
        newcol = f"out.{fueltype}.{enduse}.{emissions_scenario}.co2e_kg"
        new_unit = "kg"
        return newcol, new_unit, LB_TO_KG
    elif m21 := emissions_all_fuel_re.match(col):
        emissions_scenario, enduse = m21.groups()
        newcol = f"out.all_fuels.{enduse}.{emissions_scenario}.co2e_kg"
        new_unit = "kg"
        return newcol, new_unit, LB_TO_KG
    elif m3 := energy_use_re.match(col):
        net_or_total, fuelunits = m3.groups()
        newcol = f"out.site_energy.{net_or_total}.energy_consumption"
        return newcol, "kwh", energy_unit_conv_to_kwh[fuelunits]
    elif m4 := hot_water_re.match(col):
        hot_water_enduse = m4.groups()[0]
        new_col = f"out.hot_water.{hot_water_enduse}.gal"
        return new_col, "gal", 1.0
    elif m5 := load_delivered_re.match(col):
        load_end_use = m5.groups()[0]
        new_col = f"out.load.{load_end_use}.energy_delivered.kbtu"
        return new_col, "kbtu", 1000.0
    elif m6 := peak_electricity_re.match(col):
        peak_period = m6.groups()[0]
        new_col = f"out.electricity.{peak_period}.peak.kw"
        return new_col, "kw", 1/1000.0
    elif m7 := peak_load_re.match(col):
        load_type = m7.groups()[0]
        new_col = f"out.load.{load_type}.peak.kbtu_hr"
        return new_col, "kbtu_hr", 1.0
    elif m8 := unmet_hours_re.match(col):
        cooling_or_heating = m8.groups()[0]
        new_col = f"out.unmet_hours.{cooling_or_heating}.hour"
        return new_col, "hour", 1.0
    elif m9 := bills_re.match(col):
        scenario_name = m9.groups()[0]
        fuel_type = m9.groups()[1]
        new_col = f"out.bills.{fuel_type}.usd"
        return new_col, "usd", 1.0
    elif m91 := all_bills_re.match(col):
        new_col = f"out.bills.all_fuels.usd"
        return new_col, "usd", 1.0
    elif m10 := upgrade_costs_re.match(col):
        if col == 'upgrade_costs.floor_area_conditioned_ft_2':
            return 'in.sqft', 'ft_2', 1.0
        # Extract unit from column name
        unit_match = re.search(r'_(r_value|ach_50|ft_2|gal|k_btu_h|cfm|ft)$', col)
        unit = unit_match.group(1) if unit_match else None
        # Replace prefix and keep the rest of the column name
        new_col = re.sub(r"^upgrade_costs\.", "out.params.", col)
        return new_col, unit, 1.0  # Assuming no conversion needed, so factor is 1.0
    return None, None, None

ts_fuel_units = {
    'Coal': 'kBtu',
    'Wood Cord': 'kBtu',
    'Wood Pellets': 'kBtu',
    'Natural Gas': 'kBtu',
    'Fuel Oil': 'kBtu',
    'Propane': 'kBtu',
    'Electricity': 'kWh'
}


def convert_ts_col(col):
    if not col:
        return None, None, None
    if m1 := ts_enduse_re.match(col):
        end_or_fuel, fuel_type, end_use = m1.groups()
        end_use = end_use.lower().replace(' ', '_').replace('/', '_')
        fuel_units = ts_fuel_units[fuel_type]
        fuel_type = fuel_type.lower().replace(' ', '_')
        new_col = shrink_colname(f"out.{fuel_type}.{end_use}.energy_consumption")
        return new_col, 'kWh', energy_unit_conv_to_kwh[fuel_units.lower()]
    elif m15 := ts_fuel_emissions_re.match(col):
        emissions_scenario, fuel_type, = m15.groups()
        emissions_scenario = emissions_scenario.lower().replace(' ', '_')
        fuel_type = fuel_type.lower().replace(' ', '_')
        new_col = shrink_colname(f"out.total.{emissions_scenario}__{fuel_type}.co2e_kg")
        return new_col, 'kg', LB_TO_KG
    elif m2 := ts_emissions_re.match(col):
        emissions_scenario = m2.group(1)
        emissions_scenario = emissions_scenario.lower().replace(' ', '_')
        new_col = f"out.total.{emissions_scenario}.co2e_kg"
        return new_col, "kg", LB_TO_KG
    elif m3 := ts_energy_use_re.match(col):
        net_or_total = m3.group(1)
        fuel_units = 'kBtu'
        net_or_total = net_or_total.lower().replace(' ', '_')
        new_col = shrink_colname(f"out.site_energy.{net_or_total}.energy_consumption")
        return new_col, 'kWh', energy_unit_conv_to_kwh[fuel_units.lower()]
    elif m4 := ts_load_re.match(col):
        load_type = m4.groups()[0]
        load_type = load_type.lower().replace(' ', '_')
        new_col = f"out.load.{load_type}.energy_delivered.kbtu"
        return new_col, "kBtu", 1.0
    elif m5 := ts_zone_temp_re.match(col):
        zone_name = m5.groups()[0]
        cleaned_up_name = zone_name.replace(" - ", "_").lower().replace(' ', '_')
        new_col =f"out.zone_mean_air_temp.{cleaned_up_name}.c"
        return new_col, "C", 1.0
    elif m6 := ts_outdoor_temp_re.match(col):
        new_col = "out.outdoor_air_dryblub_temp.c"
        return new_col, "C", 1.0
    return None, None, None


here = pathlib.Path(__file__).parent.parent
inputs_df = pl.read_csv(here / 'inputs.csv')
inputs_df = inputs_df.select(
    pl.lit('Input').alias(str_column_type),
    pl.col('Input Name').alias(str_res_annual_name),
    pl.col('Input Description').alias(str_notes)
)
outputs_df = pl.read_csv(here / 'outputs.csv')
outputs_df = outputs_df.select(pl.lit('Output').alias(str_column_type),
                               pl.col('*'))
outputs_df = pl.concat(items=[outputs_df, inputs_df], how='diagonal')


converted_annual_col = {col: convert_annual_col(col) for col in outputs_df['Annual Name'].to_list()}
converted_ts_col = {col: convert_ts_col(col) for col in outputs_df[str_res_ts_name].to_list()}

outputs_df2 = outputs_df.select(
    pl.col(str_column_type),
    pl.col(str_res_annual_name),
    pl.col(str_res_annual_unit),
    pl.col(str_res_annual_name).map_elements(lambda x: converted_annual_col[x][0], skip_nulls=False, return_dtype=pl.String).alias(str_pub_annual_name),
    pl.col(str_res_annual_name).map_elements(lambda x: converted_annual_col[x][1], skip_nulls=False, return_dtype=pl.String).alias(str_pub_annual_unit),
    pl.col(str_res_annual_name).map_elements(lambda x: converted_annual_col[x][2], skip_nulls=False, return_dtype=pl.Float64).alias(str_annual_unit_conv_factor),
    pl.col(str_res_ts_name),
    pl.col(str_res_ts_unit),
    pl.col(str_res_ts_name).map_elements(lambda x: converted_ts_col[x][0], skip_nulls=False, return_dtype=pl.String).alias(str_pub_ts_name),
    pl.col(str_res_ts_name).map_elements(lambda x: converted_ts_col[x][1], skip_nulls=False, return_dtype=pl.String).alias(str_pub_ts_unit),
    pl.col(str_res_ts_name).map_elements(lambda x: converted_ts_col[x][2], skip_nulls=False, return_dtype=pl.Float64).alias(str_ts_unit_conv_factor),
    pl.col(str_notes)
)

# Add intensity columns to the definition
intensity_cols = [f"{col}_intensity" for col in outputs_df2[str_pub_annual_name].to_list() if col and 'energy_consumption' in col]
notes = 'Calculated from annual energy consumption by dividing by conditioned floor area'
# add to outputs_df2 with 'Calculated' column type and str_pub_annual_name with intensity_cols
new_df = pl.DataFrame({
    str_column_type: ['Calculated'] * len(intensity_cols),
    str_pub_annual_name: intensity_cols,
    str_pub_annual_unit: ['kwh/sqft'] * len(intensity_cols),
    str_pub_ts_name: intensity_cols,
    str_pub_ts_unit: ['kwh/sqft'] * len(intensity_cols),
    str_notes: [notes] * len(intensity_cols)
})
outputs_df2 = pl.concat(items=[outputs_df2, new_df], how='diagonal')

# Add other miscelleneus columns
#  'in.representative_income', 'in.county_name', 'out.energy_burden.percentage'
misc_df = pl.DataFrame({
    str_column_type: ['Calculated'] * 3,
    str_pub_annual_name: ['in.representative_income', 'in.county_name', 'out.energy_burden.percentage'],
    str_pub_annual_unit: ['usd', '', 'percentage'],
    str_notes: ['Average representative income of the country',
                'County name',
                'Percentage of income spent on energy']
})
outputs_df2 = pl.concat(items=[outputs_df2, misc_df], how='diagonal')

outputs_df2.write_csv(here / 'column_definitions.csv')
