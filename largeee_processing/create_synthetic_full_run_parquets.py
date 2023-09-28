from buildstock_query import BuildStockQuery
import pandas as pd
import polars as pl
import re
import json
from resstock import get_outcols, get_bs_metadata_and_annual, get_up_annual
from largeee import LARGEEE

run_names =[
    "medium_run_baseline_20230810",  # baseline
    "medium_run_category_1_20230622",
    # "medium_run_category_2_20230814",
    # "medium_run_category_3_20230713",
    # "medium_run_category_4_20230828",
    # "medium_run_category_5_20230912",
    # "medium_run_category_6_20230914",
    # "medium_run_category_7_20230824",
    # "medium_run_category_8_20230824",
    # "medium_run_category_9_20230824",
    # "medium_run_category_10_20230825",
    # # "medium_run_category_11_20230825", has error
    # "medium_run_category_12_20230825",  # Use instead of 11
    # "medium_run_category_12_20230825",
    # "medium_run_category_13_20230912",
    # "medium_run_category_14_20230910",
    # "medium_run_category_15_20230914"
]

largee_run = LARGEEE(
    run_names=run_names
)


def blow_up_medium_to_full(state_county_map_df, path):
    print(f"Reading {path}")
    df = pl.read_parquet(path)
    df = df.join(state_county_map_df)
    new_path = path.replace("medium", "full")
    full_df_list = [df]
    for i in range(1, 74):
        new_df = df.with_columns((pl.col('building_id') + i * 30000))
        full_df_list.append(new_df)
    print("Creating full df")
    full_df = pl.concat(full_df_list)
    print(f"Writing to {new_path}")
    full_df.write_parquet(new_path)

all_paths = list(largee_run.parquet_paths.values())
state_county_map_df = pl.read_parquet(all_paths[0], columns=['building_id', 'build_existing_model.state', 'build_existing_model.county'])
for path in all_paths[1:]:
    blow_up_medium_to_full(state_county_map_df, path)
