from pathlib import Path
import sys
import collections
import numpy as np
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


def get_options_from_options_lookup(opt_lkup):
    """ 
    return pd.Series
    """
    # [1] check nan rows
    n_na_rows = len(opt_lkup[opt_lkup.isna().all(axis=1)])
    if n_na_rows>0:
        print("  * options_lookup has {n_na_rows} empty rows")

    # [2] get options
    opt_lkup["Option Name"] = opt_lkup["Option Name"].astype(str)
    options = opt_lkup.groupby("Parameter Name")["Option Name"].apply(list)

    # [3] check duplicated_values:
    dup_dict = {}
    for para, opts in options.items():
        dup = get_duplicated_values(opts)
        if dup:
            dup_dict[para] = dup

    if dup_dict:
        print(f"  * The following Parameter-Option pairs are duplicated:")
        for para, opts in dup_dict.items():
            for opt in opts:
                print(f"\t{para} : {opt}")
    return options


def get_duplicated_values(lst):
    return [item for item, count in collections.Counter(lst).items() if count > 1]


def compare_options_lookups(file1, file2):
    # file2 is the basis of comparison

    # Display files:
    print("------------------------------------------------------------------------------")
    print("Compare File1 options_lookup relative to File2 options_lookup: ")
    print(f"File1: {file1}")
    print(f"File2: {file2}")
    print("------------------------------------------------------------------------------")


    # load files
    f1 = load_data(Path(file1))
    f2 = load_data(Path(file2))

    print(f"\nValidating options for File1...")
    f1_options = get_options_from_options_lookup(f1)
    print(f"\nValidating options for File2...")
    f2_options = get_options_from_options_lookup(f2)

    compare_parameter_and_option_names(f1_options, f2_options)
    compare_parameter_measure_args(f1, f2, f1_options)


def compare_parameter_and_option_names(f1_options, f2_options):
    print("\n\n1. Compare Parameter and Option Names ------------------------------------ ")
    print("\n1.1. Parameter Name Check")
    diff = set(f1_options.keys())-set(f2_options.keys())
    if diff:
        print(f"  File1 has {len(diff)} EXTRA parameters compared to f2: {diff}")
    diff = set(f2_options.keys())-set(f1_options.keys())
    if diff:
        print(f"  File1 is MISSING {len(diff)} parameters compared to f2: {diff}")

    print("\n1.2. Option Name Check")
    for para, options in f1_options.items():
        diff = set(options)-set(f2_options[para])
        if diff:
            print(f"  (+) File1 has {len(diff)} EXTRA - {para} - options: \n\t{diff}")
        diff = set(f2_options[para])-set(options)
        if diff:
            print(f"  (-) File1 is MISSING {len(diff)} - {para} - options: \n\t{diff}")

def compare_parameter_measure_args(f1, f2, f1_options):
    # [2] - compare MeasureArgs
    print("\n\n2. Compare Parameter Measure Args ---------------------------------------- ")
    for para in f1_options.keys():
        f1_args = f1.loc[f1["Parameter Name"]==para].dropna(axis=1, how="all").reset_index(drop=True)
        f2_args = f2.loc[f2["Parameter Name"]==para].dropna(axis=1, how="all").reset_index(drop=True)
        #vertical_diff = f1_args.compare(f2_args, align_axis=0)
        if set(f1_args.columns) != set(f2_args.columns):
            print(f"\n  [x] File1 and File2 has a DIFFERENT NUMBER of Measure Args for: {para}")
            print(f1_args)
            print(f2_args)
        elif len(f1_args) != len(f2_args):
            if len(f1_args) > len(f2_args):
                check_extra = True
                left_args = f1_args
                right_args = f2_args
            else:
                check_extra = False
                left_args = f2_args
                right_args = f1_args
            diff = []
            for idx, row in left_args.iterrows():
                same_fields = right_args[right_args["Option Name"]==row["Option Name"]].values == np.array(row)
                same_row = np.product(same_fields)
                # if para == "Infiltration Reduction":
                #     breakpoint()
                if len(same_fields)>0 and same_row:
                    continue
                diff.append(row)

            diff = pd.DataFrame(diff)
            if check_extra:
                print(f"\n  [x] File1 has {len(diff)} EXTRA - {para} - options: ")
            else:
                print(f"\n  [x] File1 has {len(diff)} MISSING - {para} - options: ")
            print(diff)

        else:
            diff = f1_args.compare(f2_args, align_axis=1)
            if len(diff)>0:
                print(f"\n  [x] File1 and File2 has DIFFERENT Measure Args for: {para}")
                print(diff)



if __name__ == '__main__':
    if len(sys.argv) != 3:
        print("Error in usage")
        print("Usage: python compare_options_lookups.py <file1> <file2 (basis of comparison)>")
        sys.exit(1)

    compare_options_lookups(sys.argv[1], sys.argv[2])
    