"""
Run scipt to update buildstock.csv for tests:
- yml_precomputed
- yml_precomputed_outdated
- yml_precomputed_weight
"""

import os
import sys
import subprocess
import yaml
from pathlib import Path
import pandas as pd

resstock_dir = Path(__file__).resolve().parents[1]
project_file = resstock_dir / "project_testing" / "testing_baseline.yml"
test_dir = resstock_dir / "test" / "tests_yml_files"


def load_project_yaml(project_file):
    with open(project_file) as f:
        cfg = yaml.load(f, Loader=yaml.SafeLoader)
    return cfg


def save_project_yaml(cfg, project_file):
    with open(project_file, "w") as f:
        yaml.dump(cfg, f)


def openstudio_exe():
     return os.environ.get("OPENSTUDIO_EXE", "openstudio")


def read_csv(csv_file_path, **kwargs) -> pd.DataFrame:
     default_na_values = pd._libs.parsers.STR_NA_VALUES
     df = pd.read_csv(csv_file_path, na_values=list(default_na_values - {"None"}), keep_default_na=False, **kwargs)
     return df


def generate_buildstock():
    output_dir = test_dir / "yml_precomputed" / "testing_baseline"
    if output_dir.exists():
        output_dir.rmdir()
    cfg = load_project_yaml(project_file)
    cfg["sampler"]["args"]["n_datapoints"] = 2
    cfg["output_directory"] = str(output_dir)
    tmp_file = project_file.parent / (project_file.stem + "_tmp" + project_file.suffix)
    save_project_yaml(cfg, tmp_file)

    result = subprocess.run(
        [openstudio_exe(), resstock_dir / "workflow" / "run_analysis.rb", "-y", tmp_file, "-s"],
        capture_output=True,
        text=True,
    )
    print(result)
    if not result.stderr:
        tmp_file.unlink()
    else:
        print(f"{tmp_file} did not run successfully, existing.\n{result.stderr}")
        sys.exit(1)

    # copy file
    result = subprocess.run(
        ["mv", output_dir / "buildstock.csv",  output_dir.parent / "buildstock.csv"],
        capture_output=True,
        text=True,
        )
    print(result)
    output_dir.rmdir()


def adjust_buildstock_for_yml_precomputed_tests():
    input_file = test_dir / "yml_precomputed" / "buildstock.csv"
    df = read_csv(input_file)
    df1 = df.copy()

    # For yml_precomputed_outdated
    df1["Extra Parameter"] = [1, 2]
    output_file1 = test_dir / "yml_precomputed_outdated" / "buildstock_extra.csv"
    df1.to_csv(output_file1, index=False)

    df2 = df.drop(columns=["HVAC Cooling Partial Space Conditioning"])
    output_file2 = test_dir / "yml_precomputed_outdated" / "buildstock_missing.csv"
    df2.to_csv(output_file2, index=False)

    # For yml_precomputed_weight
    df["sample_weight"] = [226.2342, 1.000009]
    output_file3 = test_dir / "yml_precomputed_weight" / "buildstock.csv"
    df.to_csv(output_file3, index=False)
    print("yml_precomputed tests buildstocks updated.")


if __name__ == "__main__":
    generate_buildstock()
    adjust_buildstock_for_yml_precomputed_tests()
