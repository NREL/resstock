import polars as pl
from largeee import LARGEEE
from get_full_report import run_names

largee_run = LARGEEE(
    run_names=run_names
)


def blow_up_medium_to_full(path):
    print(f"Reading {path}")
    df = pl.read_parquet(path)
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
for path in all_paths:
    blow_up_medium_to_full(path)
