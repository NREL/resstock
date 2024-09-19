"""
Remove vacant units from result files (any upgrade files with a building_id column)
based on results_up00
"""
import numpy as np
from pathlib import Path
import argparse
from typing import Optional

import pandas as pd


def parse_filename(file):
    suffixes = file.suffixes
    assert suffixes != [], f"{file=} has no suffixes."
    suffix = "".join(suffixes)
    file_name = file.stem.removesuffix(suffix)
    return file_name

def parse_suffix(file):
    suffixes = file.suffixes
    assert suffixes != [], f"{file=} has no suffixes."
    suffix = "".join(suffixes)
    return suffix

def read_file(file):
    suffix = parse_suffix(file)
    if suffix == ".csv" or suffix == ".csv.gz":
        return pd.read_csv(file, compression="infer", low_memory=False, keep_default_na=False)
    if suffix == ".parquet":
        return pd.read_parquet(file)
    raise ValueError(f"Unsupported {suffix=}")

def save_to_file(df, file):
    suffix = parse_suffix(file)
    if suffix == ".csv" or suffix == ".csv.gz":
        df.to_csv(file, compression="infer", index=False)
        return
    if suffix == ".parquet":
        df.to_parquet(file)
        return
    raise ValueError(f"Unsupported {suffix=}")

def remove_vacant_units(result_dir: Path, baseline_file: Path):
    file_list = sorted(result_dir.glob("*results_up*"))

    dfb = read_file(baseline_file)
    cond = dfb["completed_status"]=="Success"
    cond &= dfb["build_existing_model.vacancy_status"] != "Vacant"
    bldgs = dfb.loc[cond, "building_id"]
    for file in file_list:
        df = read_file(file)
        n1 = len(df)
        df = df.loc[df["building_id"].isin(bldgs)].reset_index(drop=True)
        n2 = len(df)
        assert n2 > 0, "After removing vacant units, df is empty."
        print(f"   Removed {n1-n2} vacant units, n={n1} -> {n2}")
        save_to_file(df, file)
        print(f"Processed: {parse_filename(file)}")

    print(f"All files modified and saved in place. Processing completed.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "result_dir",
        action="store",
        help="Path to results directory"
        )
    parser.add_argument(
        "baseline_file",
        action="store",
        help="Path to baseline_file, can be a file inside the results directory"
        )

    args = parser.parse_args()
    remove_vacant_units(Path(args.result_dir), Path(args.baseline_file))
