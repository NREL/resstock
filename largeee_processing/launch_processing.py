import polars as pl
from largeee import LARGEEE
import polars.selectors as cs
import os

output_prefix = "medium_run"
process_synthetic = False
split_by_state = False

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

state_grouping = {
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
if not split_by_state:
    state_grouping = {"All": None}

os.makedirs("largee_dashboard_data", exist_ok=True)


def write_df(df: pl.LazyFrame, id_vars: tuple[str, ...], cols: tuple[str, ...], variable_name: str,
             value_name: str, filename: str, melted: bool = True):

    if split_by_state and 'in.state' not in id_vars and 'in.state' not in cols:
        id_vars = id_vars + ('in.state',)
    df = df.select(id_vars + cols)

    for group_name, states in state_grouping.items():
        os.makedirs(f"largee_dashboard_data/full/{group_name}", exist_ok=True)
        os.makedirs(f"largee_dashboard_data/samples/{group_name}", exist_ok=True)
        if states is not None:
            new_df = df.filter(pl.col("in.state").is_in(states))
        else:
            new_df = df

        if melted:
            new_df = new_df.melt(id_vars=id_vars, value_vars=cols,
                                 variable_name=variable_name, value_name=value_name)
        print(f"Collectin {group_name}/{filename}...")
        final_df = new_df.collect()
        print(f"Writing {group_name}/{filename}...")
        final_df.write_csv(f"largee_dashboard_data/full/{group_name}/{filename}.csv")
        final_df.head(1000).write_csv(f"largee_dashboard_data/samples/{group_name}/{filename}.csv")
    print(f"Written {filename}")


largee_run = LARGEEE(
    run_names=run_names
)

# Remove this when using actual full run data
if process_synthetic:
    for key in largee_run.parquet_paths:
        largee_run.parquet_paths[key] = largee_run.parquet_paths[key].replace("medium", "full")


bs_df, up_df = largee_run.get_bs_up_df()

report = largee_run.get_combined_upgrade_report()
report.write_csv(f"{output_prefix}_upgrade_report.csv")

energy_cols = cs.expand_selector(bs_df, cs.matches(r"^out\.(.*)\.total.(.*)energy_consumption.kwh$"))
energy_saving_cols = cs.expand_selector(up_df, cs.matches(r"^out\.(.*)\.total.(.*)energy_consumption.kwh.savings$"))
upgrade_cost_cols = cs.expand_selector(up_df, cs.matches(r"^out\.params.upgrade_cost_usd$"))
bill_cols = cs.expand_selector(up_df, cs.matches(r"^^out\.bill_costs.(.*).usd$"))
bill_saving_cols = cs.expand_selector(up_df, cs.matches(r"^^out\.bill_costs.(.*).usd.savings$"))
emission_saving_cols = cs.expand_selector(up_df, cs.matches(r"^out\.emissions.all_fuels.(.*)\.savings$"))
emission_cols = cs.expand_selector(up_df, cs.matches(r"^out\.emissions.all_fuels.(.*)kg$"))
upgrade_opt_cols = cs.expand_selector(up_df, cs.matches(r"^upgrade\.(.*)$"))
# write_df(bs_df, id_vars=('bldg_id', 'weight'), cols=tuple(export_chars.keys()), variable_name="Characteristics",
#          value_name="value", filename=f"{output_prefix}_characteristics", )
write_df(bs_df, id_vars=('bldg_id', 'weight'), cols=tuple(export_chars.keys()), variable_name="Characteristics",
         value_name="value", filename=f"{output_prefix}_characteristics_wide", melted=False)

write_df(bs_df, id_vars=('bldg_id',), cols=energy_cols, variable_name="energy type", value_name="value",
         filename=f"{output_prefix}_baseline_energy_wide", melted=False)
write_df(bs_df, id_vars=('bldg_id',),
         cols=bill_cols, variable_name="bill type", value_name="value",
         filename=f"{output_prefix}_baseline_bill_cost_wide", melted=False)
write_df(bs_df, id_vars=('bldg_id',),
         cols=emission_cols, variable_name="emission scenario", value_name="value",
         filename=f"{output_prefix}_baseline_emission_wide", melted=False)

if split_by_state:
    up_df = up_df.join(bs_df.select("bldg_id", "in.state"), on="bldg_id")

write_df(up_df, id_vars=('bldg_id', 'upgrade'), cols=energy_saving_cols, variable_name="energy type",
         value_name="value", filename=f"{output_prefix}_upgrade_energy_savings_wide", melted=False)
write_df(up_df, id_vars=('bldg_id', 'upgrade'),
         cols=bill_saving_cols, variable_name="bill type", value_name="value",
         filename=f"{output_prefix}_upgrade_bill_savings_wide", melted=False)
write_df(up_df, id_vars=('bldg_id', 'upgrade'), cols=upgrade_cost_cols, variable_name="cost type",
         value_name="value", filename=f"{output_prefix}_upgrade_cost_wide", melted=False)
write_df(up_df, id_vars=('bldg_id', 'upgrade'), cols=emission_saving_cols, variable_name="emission scenario",
         value_name="value", filename=f"{output_prefix}_upgrade_emission_savings_wide", melted=False)

write_df(up_df, id_vars=('bldg_id', 'upgrade'), cols=upgrade_opt_cols, variable_name="Applied option",
         value_name="value", filename=f"{output_prefix}_applied_options_wide", melted=False)
