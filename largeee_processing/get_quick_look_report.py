from largeee import LARGEEE
import yaml
import pandas as pd
import functools
import polars as pl
import os
from get_quick_look_plots import get_plot


with open("config.yaml") as f:
    config = yaml.safe_load(f)

os.makedirs(config['output_folder'], exist_ok=True)

largee_run = LARGEEE(
    db_name=config['db_name'],
    run_names=[config['baseline_run']] + config['upgrade_runs'],
    state_split=config['state_split'],
    skip_parquet_download=True
)

upgrade_names_df = largee_run.get_upgrade_names()
upgrade_names_dict = dict(upgrade_names_df.select('upgrade', 'upgrade_name').iter_rows())


def get_quick_look_db_cols(athena_table):
    """ Get quick look columns as sqlalchemy DB column expression to be used for query"""
    enduse_cols = []
    for col in config['quick_look_columns']:
        if isinstance(col, str):
            enduse_cols.append(athena_table.c[col].label(col.split('.')[-1]))
        elif isinstance(col, dict):
            assert len(col) == 1
            col_alias = list(col.keys())[0]
            col_constituents = col[col_alias]
            col_expr = functools.reduce(lambda x, y: x + y, [athena_table.c[c] for c in col_constituents])
            enduse_cols.append(col_expr.label(col_alias))
    return enduse_cols


def get_quick_look_col_names():
    """Get the final names of quick look columns."""
    col_names = []
    for col in config['quick_look_columns']:
        if isinstance(col, str):
            col_names.append(col.split('.')[-1])
        elif isinstance(col, dict):
            assert len(col) == 1
            col_alias = list(col.keys())[0]
            col_names.append(col_alias)
    return col_names


all_report_dfs = []
for cat in range(1, len(config['upgrade_runs'])+1):
    fuels = ['electricity', 'natural_gas', 'fuel_oil', 'propane', 'wood_cord', 'wood_pellets']
    upgrade_queries = []
    upgrade_ids = []
    for upgrade_id in largee_run.run_objs[cat].get_available_upgrades():
        upgrade_id = int(upgrade_id)
        if upgrade_id == 0 and cat != 1:
            # Only process baseline for first category since it's the same for all
            continue
        athena_table = largee_run.run_objs[cat].up_table if upgrade_id > 0 else largee_run.run_objs[cat].bs_table
        assert athena_table is not None
        heating_cols = [athena_table.c[f'report_simulation_output.end_use_{fuel}_heating_m_btu'] for fuel in fuels]
        total_heating_col = functools.reduce(lambda x, y: x + y, heating_cols).label("total_heating_m_btu")
        query = largee_run.run_objs[cat].agg.aggregate_annual(enduses=get_quick_look_db_cols(athena_table),
                                                              upgrade_id=upgrade_id,
                                                              group_by=['state'],
                                                              sort=True,
                                                              get_query_only=True)
        upgrade_queries.append(query)
        upgrade_ids.append(upgrade_id)
        print(f"Got query for {cat}.{upgrade_id:02}")
    batch_id = largee_run.run_objs[cat].submit_batch_query(upgrade_queries)
    res_dfs = largee_run.run_objs[cat].get_batch_query_result(batch_id, combine=False)
    largee_run.run_objs[cat].save_cache()
    for upgrade_id, res_df in zip(upgrade_ids, res_dfs):
        res_df.insert(0, 'upgrade', f"{cat}.{upgrade_id:02}")
    all_report_dfs.extend(res_dfs)
    print(f"Query completed for {cat=}")

full_report = pd.concat(all_report_dfs)
if 'query_id' in full_report.columns:
    full_report = full_report.drop(columns='query_id')
full_report = full_report.reset_index(drop=True)
cols = get_quick_look_col_names()
full_report[cols] = full_report[cols].div(full_report['units_count'], axis=0)

pl_report_df = pl.from_pandas(full_report).join(upgrade_names_df, on='upgrade', how='left')
pl_report_df = pl_report_df.with_columns((pl.concat_str(pl.col("upgrade"),
                                                        pl.lit(" "),
                                                        pl.col("upgrade_name"))).alias("full_name"))

pl_report_df.write_csv(f"{config['output_folder']}/{config['file_prefix']}quick_look.csv")

upgrade_report = largee_run.get_combined_upgrade_report()
upgrade_report.write_csv(f"{config['output_folder']}/{config['file_prefix']}upgrade_report.csv")
