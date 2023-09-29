import polars as pl
from largeee import LARGEEE
import polars.selectors as cs
import os

run_folder = "med_run_2"
output_folder = "dashboard_data"
state_split = True

run_names = [
    "medium_run_baseline_20230810",  # baseline
    "medium_run_category_1_20230925",
    "medium_run_category_2_20230920",
    "medium_run_category_3_20230925",
    "medium_run_category_4_20230926",
    "medium_run_category_5_20230920",
    "medium_run_category_6_20230920",
    "medium_run_category_7_20230824",
    "medium_run_category_8_20230824",
    "medium_run_category_9_20230824",
    "medium_run_category_10_20230825",
    "medium_run_category_11_20230920",
    "medium_run_category_12_20230825",
    "medium_run_category_13_20230920",
    "medium_run_category_14_20230921",
    "medium_run_category_15_20230920"
]

export_chars = {
    "in.geometry_building_type_recs": "Building type RECS",
    'in.vintage': 'Vintage',
    'in.geometry_floor_area': 'Area bin',
    'in.heating_fuel': 'Heating fuel',
    'in.hvac_cooling_type': 'Cooling type',
    'in.hvac_heating_efficiency': 'Heating type',
    'in.geometry_wall_type': 'Wall type',
    'in.geometry_foundation_type': 'Foundation type',
    'in.windows': 'Windows',
    'in.cooking_range': 'Stove fuel',
    'in.water_heater_fuel': 'Water heater fuel',
    'in.clothes_dryer': 'Clothes dryer fuel',
    'in.infiltration': 'Infiltration',
    'in.insulation_wall': 'Wall insulation',
    'in.insulation_ceiling': 'Ceiling insulation',
    'in.geometry_attic_type': 'Attic type',
    'in.income': 'Income',
    'in.area_median_income': 'Area median income',
    'in.tenure': 'Tenure',
    'in.building_america_climate_zone': 'BA Climate Zone',
    'in.ashrae_iecc_climate_zone_2004': 'IECC Climate zone',
    'in.state': 'State',
    'in.county': 'County',
    'in.census_division': 'Census division',
}

state_grouping: dict[str, list[str] | None] = {
    "Mountain & Pacific Northwest": ["MT", "ID", "WY", "NV", "UT", "CO", "AZ", "NM", "OR", "WA"],
    "California": ["CA"],
    "Florida & Georgia": ["FL", "GA"],
    "Central Atlantic": ["SC", "NC", "VA", "DC", "MD", "DE"],
    "Three-Fifths of East North Central": ["MI", "IL", "IN"],
    "West North Central & Wisconsin": ["ND", "SD", "NE", "KS", "MN", "IA", "MO", "WI"],
    "New York & New Jersey": ["NY", "NJ"],
    "PA-OH-WV": ["PA", "OH", "WV"],
    "Texas": ["TX"],
    "East South Central": ["KY", "TN", "MS", "AL"],
    "New England": ["ME", "NH", "VT", "MA", "CT", "RI"],
    "Northeast West South Central": ["OK", "AR", "LA"]
}


def write_df(df: pl.DataFrame, id_vars: tuple[str, ...], col_selector: cs.SelectorType, variable_name: str,
             value_name: str, group_name: str, filename: str, melted: bool = False):
    cols = cs.expand_selector(df, col_selector)
    df = df.select(id_vars + cols)
    if melted:
        df = df.melt(id_vars=id_vars, value_vars=cols,
                     variable_name=variable_name, value_name=value_name)
    final_df = df
    print(f"Writing {output_folder}/{run_folder}/.../{group_name}/{filename}")
    os.makedirs(f"{output_folder}/{run_folder}/head/{group_name}", exist_ok=True)
    os.makedirs(f"{output_folder}/{run_folder}/full/{group_name}", exist_ok=True)
    final_df.write_csv(f"{output_folder}/{run_folder}/full/{group_name}/{filename}.csv")
    final_df.head(1000).write_csv(f"{output_folder}/{run_folder}/head/{group_name}/{filename}.csv")


def write_group(largee_run: LARGEEE, group_name: str, filter_states: list[str] | None = None):
    if filter_states is not None:
        upgrade_id_cols = ('bldg_id', 'upgrade', 'in.state')
        bs_id_cols = ('bldg_id', 'in.state')
        print(f"Processing for {group_name} with states {filter_states}")
    else:
        upgrade_id_cols = ('bldg_id', 'upgrade')
        bs_id_cols = ('bldg_id',)

    cs_energy_cols = cs.matches(r"^out\.(.*)\.total.(.*)energy_consumption.kwh$")
    cs_energy_saving_cols = cs.matches(r"^out\.(.*)\.total.(.*)energy_consumption.kwh.savings$")
    cs_upgrade_cost_cols = cs.matches(r"^out\.params.upgrade_cost_usd$")
    cs_bill_cols = cs.matches(r"^^out\.bill_costs.(.*).usd$")
    cs_bill_saving_cols = cs.matches(r"^^out\.bill_costs.(.*).usd.savings$")
    cs_emission_saving_cols = cs.matches(r"^out\.emissions.all_fuels.(.*)\.savings$")
    cs_emission_cols = cs.matches(r"^out\.emissions.all_fuels.(.*)kg$")
    cs_upgrade_opt_cols = cs.matches(r"^upgrade\.(.*)$")
    all_selectors = cs_energy_cols | cs_energy_saving_cols | cs_upgrade_cost_cols | cs_bill_cols |\
        cs_bill_saving_cols | cs_emission_saving_cols | cs_emission_cols | cs_upgrade_opt_cols
    all_selectors |= cs.starts_with("bldg_id", "in.state", "upgrade", "weight")
    all_selectors |= cs.contains(export_chars.keys())

    bs_df, up_df = largee_run.get_bs_up_df(filter_states=filter_states, column_selector=all_selectors)

    write_df(bs_df, id_vars=('bldg_id', 'weight'), col_selector=cs.by_name(export_chars.keys()),
             variable_name="characteristics",
             value_name="value", group_name=group_name, filename="characteristics_wide")

    write_df(bs_df, id_vars=bs_id_cols, col_selector=cs_energy_cols, variable_name="energy type", value_name="value",
             group_name=group_name, filename="baseline_energy_wide")
    write_df(bs_df, id_vars=bs_id_cols,
             col_selector=cs_bill_cols, variable_name="bill type", value_name="value",
             group_name=group_name, filename="baseline_bill_cost_wide")
    write_df(bs_df, id_vars=bs_id_cols,
             col_selector=cs_emission_cols, variable_name="emission scenario", value_name="value",
             group_name=group_name, filename="baseline_emission_wide")

    write_df(up_df, id_vars=upgrade_id_cols, col_selector=cs_energy_saving_cols, variable_name="energy type",
             value_name="value",  group_name=group_name, filename="upgrade_energy_savings_wide")
    write_df(up_df, id_vars=upgrade_id_cols,
             col_selector=cs_bill_saving_cols, variable_name="bill type", value_name="value",
             group_name=group_name, filename="upgrade_bill_savings_wide")
    write_df(up_df, id_vars=upgrade_id_cols, col_selector=cs_upgrade_cost_cols, variable_name="cost type",
             value_name="value",  group_name=group_name, filename="upgrade_cost_wide")
    write_df(up_df, id_vars=upgrade_id_cols, col_selector=cs_emission_saving_cols, variable_name="emission scenario",
             value_name="value",  group_name=group_name, filename="upgrade_emission_savings_wide")

    write_df(up_df, id_vars=upgrade_id_cols, col_selector=cs_upgrade_opt_cols, variable_name="applied option",
             value_name="value",  group_name=group_name, filename="applied_options_wide")


def write_all():
    if not state_split:
        state_grouping.clear()
        state_grouping['All'] = None

    largee_run = LARGEEE(
        run_names=run_names,
        state_split=state_split
    )

    for group_name, states in state_grouping.items():
        write_group(largee_run, group_name, states)
    upgrade_report_df = largee_run.get_combined_upgrade_report()
    upgrade_report_df.write_csv(f"{output_folder}/{run_folder}/upgrade_report.csv")


if __name__ == "__main__":
    write_all()
