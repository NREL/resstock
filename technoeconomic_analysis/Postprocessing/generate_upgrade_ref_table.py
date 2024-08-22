"""
Get summary of upgrades:
file_name, upgrade_name, Success, Fail, Invalid
"""
import numpy as np
from pathlib import Path
import argparse
from typing import Optional

import pandas as pd


def get_summary(csv_dir: Path, output_file: Optional[Path]=None):
    ref_table = []
    for file in csv_dir.glob("*results_up*"):
        suffixes = file.suffixes
        assert suffixes != [], f"{file=} has no suffixes."
        suffix = "".join(suffixes)
        file_name = file.stem.removesuffix(suffix)
        if suffix == ".csv" or suffix == ".csv.gz":
            df = pd.read_csv(file, compression="infer", low_memory=False, keep_default_na=False)
        elif suffix == ".parquet":
            df = pd.read_parquet(file)
        else:
            raise ValueError(f"Unsupported {suffix=}")

        if "results_up00" in file_name:
            upgrade_name = "baseline"
        else:
            upg_names = [x for x in df["apply_upgrade.upgrade_name"].dropna().unique() if x not in ["", None, np.nan]]
            assert len(upg_names) == 1, f"Difficulty extracting upgrade name: {upg_names}"
            upgrade_name = upg_names[0]

        completed_stats = df.groupby(["completed_status"])["building_id"].count()

        stats = pd.Series({
            "filename": file_name,
            "upgrade_name": upgrade_name
            })

        stats = pd.concat([stats, completed_stats])
        ref_table.append(stats)
        print(f"Processed: {file_name}")

    ref_table = pd.concat(ref_table, axis=1).transpose()
    print(ref_table)


    if output_file is None:
        output_file = csv_dir / "summary_table.csv"
    ref_table.to_csv(output_file, index=False)

    print(f"Summary table output to: {output_file}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "csv_dir",
        action="store",
        help="Path to results csv directory"
        )
    parser.add_argument(
        "output_file",
        nargs="?",
        action="store",
        default=None,
        help="Path to to save the ref_table to, default to save file to csv_dir as 'summmary_table.csv'"
        )

    args = parser.parse_args()
    csv_dir = Path(args.csv_dir)
    output_file = args.output_file
    if output_file is not None:
        output_file = Path(output_file)

    get_summary(csv_dir, output_file=output_file)
