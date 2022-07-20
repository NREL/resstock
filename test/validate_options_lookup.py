from pathlib import Path
import sys
import pandas as pd


def load_data(file):
    if Path(file).suffix == ".csv":
        df = pd.read_csv(file)
    elif Path(file).suffix == ".tsv":
        df = pd.read_csv(file, sep="\t", low_memory=False)
    elif Path(file).suffix == ".parquet":
        df = pd.read_parquet(file)
    else:
        raise ValueError(f"File type={Path(file).suffix} is not supported. "
            "Accepts only .csv, .tsv, or .parquet")

    return df


def validate_parameters(lkup_options, tsv_options, project_folder="project_national"):
    error = False
    HC = f"{project_folder} housing_characteristics"
    print(f"\nChecking options_lookup PARAMETERS against {HC}...")
    left_diff = set(tsv_options) - set(lkup_options.index)
    right_diff = set(lkup_options.index) - set(tsv_options)

    if left_diff:
        print(f"  - ERROR : options_lookup is missing {len(left_diff)} tsvs/parameters compared to {HC}:")
        print(left_diff, sep="\n")
        error = True
    if right_diff:
        print(f"  - options_lookup has {len(right_diff)} extra tsvs/parameters compared to {HC}:")
        print(right_diff, sep="\n")

    return error


def validate_options(lkup_options, tsv_options, project_folder="project_national"):
    error = False
    HC = f"{project_folder} housing_characteristics"
    print(f"\nChecking options_lookup OPTIONS against {HC}...")
    missing_tsv_options = {}
    idx = 1
    for tsv, opts in tsv_options.items():
        if tsv in lkup_options.index:
            diff = set(opts) - set(lkup_options[tsv])
            if diff:
                print(f"  ERROR {idx:02d}.  Missing options for '{tsv}':  {diff}")
                idx += 1
                error = True
        else:
            missing_tsv_options[tsv] = opts

    if missing_tsv_options:
        print("ERROR : options_lookup is missing following parameter-option pair(s):  ")
        print(*missing_tsv_options.items(), sep="\n")
        error = True

    return error


def get_options_from_options_lookup(opt_lkup):
    """ 
    return pd.Series
    """
    opt_lkup["Option Name"] = opt_lkup["Option Name"].astype(str)
    options = opt_lkup.groupby("Parameter Name")["Option Name"].apply(list)
    return options


def extract_options_from_tsv(tsv_file):
    df = load_data(tsv_file)
    return [col.removeprefix("Option=") for col in df.columns if col.startswith("Option=")]


def validate_options_lookup(project_folder="project_national"):
    # load files
    resstock_dir = Path(__file__).resolve().parents[1]
    project = resstock_dir / project_folder / "housing_characteristics"
    options_lookup_file = resstock_dir / "resources" / "options_lookup.tsv"

    tsv_options = {}
    HC_files = sorted(project.glob("*.tsv"))
    for file in HC_files:
        tsv_name = file.stem
        tsv_options[tsv_name] = extract_options_from_tsv(file)

    opt_lkup = load_data(options_lookup_file)
    lkup_options = get_options_from_options_lookup(opt_lkup)

    # apply checks
    error = 0
    error += validate_parameters(lkup_options, tsv_options, project_folder=project_folder)
    error += validate_options(lkup_options, tsv_options, project_folder=project_folder)

    if error:
        print(f"\nERROR: options_lookup.tsv does NOT match {project_folder} housing_characteristics, exiting")
        sys.exit(1)


if __name__ == '__main__':
    validate_options_lookup()
    