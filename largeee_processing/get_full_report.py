import polars as pl
from largeee import LARGEEE
import polars.selectors as cs
from polars.type_aliases import SelectorType
import os
import yaml


with open("config.yaml") as f:
    config = yaml.safe_load(f)


def write_df(df: pl.DataFrame, id_vars: tuple[str, ...], col_selector: SelectorType, variable_name: str,
             value_name: str, group_name: str, filename: str, melted: bool = False, drop_nulls: bool = False):
    cols = cs.expand_selector(df, col_selector)
    df = df.select(id_vars + cols)
    if melted:
        df = df.melt(id_vars=id_vars, value_vars=cols,
                     variable_name=variable_name, value_name=value_name)
        if drop_nulls:
            df = df.filter(pl.col(value_name).is_not_null())
    final_df = df
    print(f"Writing {config['output_folder']}/.../{group_name}/{filename}")
    os.makedirs(f"{config['output_folder']}/head/{group_name}", exist_ok=True)
    os.makedirs(f"{config['output_folder']}/full/{group_name}", exist_ok=True)
    final_df.write_csv(f"{config['output_folder']}/full/{group_name}/{config['file_prefix']}{filename}.csv")
    final_df.head(1000).write_csv(f"{config['output_folder']}/head/{group_name}/{config['file_prefix']}{filename}.csv")


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
    cs_upgrade_cost_cols = cs.matches(r"^out\.params.upgrade_cost*")
    cs_bill_cols = cs.matches(r"^^out\.bill_costs.(.*).usd$")
    cs_bill_saving_cols = cs.matches(r"^^out\.bill_costs.(.*).usd.savings$")
    cs_emission_saving_cols = cs.matches(r"^out\.emissions.all_fuels.(.*)\.savings$")
    cs_emission_cols = cs.matches(r"^out\.emissions.all_fuels.(.*)kg$")
    cs_upgrade_opt_cols = cs.matches(r"^upgrade\.(.*)$")
    all_selectors = cs_energy_cols | cs_energy_saving_cols | cs_upgrade_cost_cols | cs_bill_cols |\
        cs_bill_saving_cols | cs_emission_saving_cols | cs_emission_cols | cs_upgrade_opt_cols
    all_selectors |= cs.starts_with("bldg_id", "in.state", "upgrade", "weight")
    all_selectors |= cs.contains(set(config['long_chars']) | set(config['wide_chars']))

    bs_df, up_df = largee_run.get_bs_up_df(filter_states=filter_states,
                                           column_selector=all_selectors)

    up_df = up_df.with_columns(
        pl.when(pl.col("upgrade.needs_electrification_update"))
        .then(pl.col('out.params.upgrade_cost_usd') + config['electrification_adder'])
        .otherwise(pl.col('out.params.upgrade_cost_usd'))
        .alias('out.params.upgrade_cost_with_adder_usd')
        )

    write_df(bs_df, id_vars=('bldg_id', 'weight'), col_selector=cs.by_name(config['wide_chars']),
             variable_name="characteristics",
             value_name="value", group_name=group_name, filename="characteristics_wide")
    write_df(bs_df, id_vars=('bldg_id', ), col_selector=cs.by_name(config['long_chars']),
             variable_name="characteristics",
             value_name="value", group_name=group_name, filename="characteristics_long", melted=True)

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

    write_df(up_df, id_vars=upgrade_id_cols, col_selector=cs_upgrade_cost_cols,
             variable_name="Cost Type", value_name="out.params.upgrade_cost_usd",
             group_name=group_name, filename="upgrade_cost_long", melted=True, drop_nulls=True)

    write_df(up_df, id_vars=upgrade_id_cols, col_selector=cs_emission_saving_cols, variable_name="emission scenario",
             value_name="value",  group_name=group_name, filename="upgrade_emission_savings_wide")

    write_df(up_df, id_vars=upgrade_id_cols, col_selector=cs_upgrade_opt_cols, variable_name="applied option",
             value_name="value",  group_name=group_name, filename="applied_options_wide")


def write_all():
    if not config['state_split']:
        config['state_grouping'].clear()
        config['state_grouping']['All'] = None

    largee_run = LARGEEE(
        db_name=config['db_name'],
        run_names=[config['baseline_run']] + config['upgrade_runs'],
        state_split=config['state_split']
    )

    for group_name, states in config['state_grouping'].items():
        write_group(largee_run, group_name, states)
    upgrade_report_df = largee_run.get_combined_upgrade_report()
    upgrade_report_df.write_csv(f"{config['output_folder']}/{config['file_prefix']}upgrade_report.csv")


if __name__ == "__main__":
    write_all()
