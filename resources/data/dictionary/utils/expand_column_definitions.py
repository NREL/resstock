import polars as pl
import pathlib
import re


def to_underscore_case(s):
    # based on https://github.com/NREL/OpenStudio/blob/830323591aca37b9ae978ea1e708083cb3577072/src/utilities/core/StringHelpers.cpp#L36
    s = s.replace("OpenStudio", "Openstudio")
    s = s.replace("EnergyPlus", "Energyplus")

    s = re.sub(r'[^a-zA-Z0-9]', ' ', s)
    s = re.sub(r'[-]+', '_', s)
    s = re.sub(r'[\s]+', '_', s)
    s = re.sub(r'([A-Za-z])([0-9])', r'\1_\2', s)
    s = re.sub(r'([0-9]+)([A-Za-z])', r'\1_\2', s)
    s = re.sub(r'([A-Z]+)([A-Z][a-z])', r'\1_\2', s)
    s = re.sub(r'([a-z])([A-Z])', r'\1_\2', s)
    s = re.sub(r'([A-Z])', lambda m: m.group(0).lower(), s)

    return s.strip('_')

here = pathlib.Path(__file__).parent.parent


utility_bills_scenario_names = ['utility_rates_fixed_variable']
max_upgrade_options = 50


emissions_scenario_names_folder = here / '../emissions/cambium/2022'
emissions_scenario_names = [folder.name for folder in emissions_scenario_names_folder.iterdir() if folder.is_dir()]


output_df = pl.read_csv('/Users/radhikar/Documents/buildstock2025/resstock2025/resources/data/dictionary/column_definitions.csv')


emissions_selector = pl.any_horizontal(pl.col("*").fill_null("").str.contains("<emissions_scenario_name>"))
bills_selector = pl.any_horizontal(pl.col("*").fill_null("").str.contains("<utility_bills_scenario_name>"))
upgrade_options_selector = pl.any_horizontal(pl.col("*").fill_null("").str.contains("<upgrade_option_number>"))


emissions_df = output_df.filter(emissions_selector)
bills_df = output_df.filter(bills_selector)
upgrade_options_df = output_df.filter(upgrade_options_selector)
rest_of_the_df = output_df.filter((~emissions_selector) & (~bills_selector) & (~upgrade_options_selector))
assert len(rest_of_the_df) + len(emissions_df) + len(bills_df) + len(upgrade_options_df) == len(output_df)


all_dfs = [rest_of_the_df]
for emissions_scenario in emissions_scenario_names:
    all_dfs.append(
        emissions_df.with_columns(
            pl.col('Timeseries ResStock Name').str.replace("<emissions_scenario_name>", emissions_scenario)
        ).with_columns(
            pl.col(pl.String).str.replace("<emissions_scenario_name>", to_underscore_case(emissions_scenario))
        )
    )

for bills_scenario in utility_bills_scenario_names:
    all_dfs.append(bills_df.with_columns(pl.col(pl.String).str.replace("<utility_bills_scenario_name>", bills_scenario)))


for i in range(1, max_upgrade_options + 1):
    all_dfs.append(upgrade_options_df.with_columns(pl.col(pl.String).str.replace("<upgrade_option_number>", f"{i:02d}")))


final_df = pl.concat(all_dfs)
final_df.write_csv(here / 'expanded_column_definitions.csv')
                   