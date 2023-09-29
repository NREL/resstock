import logging
from utils import agg_col_renamer
import polars as pl
from collections import defaultdict

logger = logging.getLogger(__name__)


def verify_single_application_per_param(param2cols, up_df):
    """
    verify that a building is not getting duplicated parameter applied.
    For example, say out.params.option_1_name and out.params.option_2_name for a given row
    has HVAC Cooling Type|Room AC and HVAC Cooling Type|Central AC. Here, HVAC Cooling Type
    was applied multiple times to the same building. This should never happen in a valid
    resstock run.
    """
    multi_application_cols = []
    for param, cols in param2cols.items():
        # For each paramn count how many of the columns have non-null values. If more than one
        # (which is an error) it will have a value 1 otherwise 0. Save this in a new column named
        # param. Later we will sum all these columns to see if any building has more than one
        # non-null column for any parameter
        multi_application_cols.append(
            pl.sum_horizontal(pl.col(cols).is_not_null()).alias(param) > 1
        )
    assert up_df.select(pl.sum_horizontal(multi_application_cols)).sum().collect()['sum'].to_list() == [0]


def add_upgrade_option_cols(up_df):
    """
    Add upgrade.<param> columns to the dataframe based one out.params.option_(\d*)_name columns
    Each of the out.params.option_(\d*)_name columns has a value like "HVAC Cooling Type|Room AC"
    Sometimes same parameter (HVAC Cooling Type) is spread accross multiple columns, but one column
    always have only one type of parameter.
    """
    # Find out which paramter each of the option_<num>_name columns represent
    col2param = up_df.select(pl.col(r"^out.params.option_(\d*)_name$")
                             .backward_fill().str.split("|").list.first()).first().collect().to_dicts()[0]
    # Group all columns we need to look at for each parameter
    param2cols = defaultdict(list)
    for col, param in col2param.items():
        if param is None:
            continue
        param2cols[param].append(col)
    # Add each parameter as a column to the dataframe, and value being the option taken by the param
    # We need to look at all columns for each parameter to find the value, and take the first non-null value
    # Only one of the columns belonging to a parameter shuld have a non-null value
    verify_single_application_per_param(param2cols, up_df)
    upgrade_cols = []
    for param, cols in param2cols.items():
        upgrade_col_name = f"upgrade.{param.lower().replace(' ', '_')}"
        upgrade_cols.append(
            pl.coalesce(pl.col(cols)).str.split("|").list.get(1).alias(upgrade_col_name)
        )
    return up_df.with_columns(upgrade_cols)


def process_upgrade(bs_df: pl.LazyFrame, up_df: pl.LazyFrame | None = None) -> pl.LazyFrame:
    bs_front_cols = ['bldg_id', 'upgrade', 'weight', 'applicability']
    all_cols = list(bs_df.columns)
    emission_cols = [col for col in all_cols if col.endswith('co2e_kg')]

    energy_cols = [col for col in all_cols if 'energy_consumption' in col and 'intensity' not in col]
    intensity_cols = [col for col in all_cols if 'energy_consumption_intensity' in col]
    hot_water_cols = [col for col in all_cols if col.startswith("out.hot_water.")]
    load_cols = [col for col in all_cols if col.startswith("out.load.") and col.endswith(".kbtu")]
    peak_cols = [col for col in all_cols if ".peak." in col]
    unmet_hours_cols = [col for col in all_cols if col.startswith("out.unmet_hours.")]
    bs_params_cols = [col for col in all_cols if col.startswith("out.params.")]
    bill_cols = [col for col in all_cols if col.startswith("out.bill_costs.")]
    in_cols = [col for col in all_cols if col.startswith('in.')]
    outcols_to_keep = energy_cols + hot_water_cols + load_cols + peak_cols + unmet_hours_cols + emission_cols
    outcols_to_keep += bill_cols
    bs_df = bs_df.select(bs_front_cols + in_cols + outcols_to_keep + bs_params_cols)

    bs_df = bs_df.rename({col: agg_col_renamer(col) for col in bs_df.columns})
    # bs_df = add_all_fuels_emissions(bs_df)

    if up_df is None:
        return bs_df

    up_front_cols = ['bldg_id', 'upgrade', 'applicability']
    up_front_cols.extend([col for col in up_df.columns if col.startswith('in.')])
    up_params_cols = [col for col in up_df.columns if col.startswith("out.params.")]
    up_df = up_df.select(up_front_cols + outcols_to_keep + up_params_cols)
    up_df = up_df.rename({col: agg_col_renamer(col) for col in bs_df.columns})
    # up_df = add_all_fuels_emissions(up_df)
    up_df = up_df.rename({col: agg_col_renamer(col) for col in up_df.columns})
    outcols = set([col for col in up_df.columns if col.startswith("out.") and not col.startswith("out.params")])
    bs_out_df = bs_df.select(['bldg_id'] + [pl.col(col).alias(f"baseline_{col}") for col in outcols])
    up_df = up_df.join(bs_out_df, on='bldg_id')
    up_df = up_df.with_columns([(pl.col(f"baseline_{col}") - pl.col(col)).alias(f"{col}.savings")
                                for col in outcols])
    upgrade_opt_cols = []
    col2paramname = up_df.select(
        pl.col("^out.params.option_(\d*)_name$").str.split("|").list.get(0).first()).head(1).collect().to_dicts()[0]
    for col, paramname in col2paramname.items():
        if paramname is None:
            continue
        upgrade_col_name = f"upgrade.{paramname.lower().replace(' ', '_')}"
        upgrade_opt_cols.append(pl.col(col).str.split("|").list.get(1).alias(upgrade_col_name))
    up_df = add_upgrade_option_cols(up_df)
    return up_df.select(pl.exclude("^out.params.option_.*$"))
