"""
Create housing characteristics breakdown for Tribal Nations
Author: Lixi.Liu@nrel.gov
Date: 10/20/2022

"""

# import packages
from pathlib import Path
import numpy as np
import pandas as pd
import sys
import itertools

resstock_estimation = Path(__file__).resolve().parents[2] / "resstock-estimation"
sys.path.append(resstock_estimation)
from utils.get_joint_marginal_probability import get_tsv_joint_marginals

data_dir = Path(__file__).resolve().parent / "data"
output_dir = resstock_estimation / "utils" / "sampled_joint_marginals"


# load mappings
mapping = pd.read_csv(data_dir / "2010_derived_map_puma_to_aia.csv").drop(
    columns=["sampling_probability"]
)


def create_output_filename(tsv_list_to_use, tsv_to_pivot=None):
    pivot_ext = pivot_msg = ""
    if tsv_to_pivot:
        tsv_list_to_use = [tsv for tsv in tsv_list if tsv != tsv_to_pivot]
        pivot_ext = f'_pivoted_by_{tsv_to_pivot.replace(" ", "")}'
    file_name = "_".join([t.replace(" ", "") for t in tsv_list_to_use])
    file_name += pivot_ext
    output_file = output_dir / (file_name + ".csv")
    return output_file


project_path = resstock_estimation / "projects" / "project_national_ira"

tsv_list1 = ["Vacancy Status", "State", "PUMA", "Tenure", "Geometry Building Type RECS"]
tsv_list2 = [
    "Vacancy Status",
    "Federal Poverty Level Tribal",
    "State",
    "PUMA",
    "Tenure",
    "Geometry Building Type RECS",
]
tsv_list3 = [
    "Vacancy Status",
    "Area Median Income Tribal",
    "State",
    "PUMA",
    "Tenure",
    "Geometry Building Type RECS",
]
tsv_to_pivot1 = "Heating Fuel"
tsv_to_pivot2 = "Water Heater Fuel"

"""
# Not quite working, I think it's due to import not being set up as a real pkg
print(f"Calculating joint marginal probability for: {project_path}")
for tsv_list, tsv_to_pivot in itertools.product([tsv_list1, tsv_list2, tsv_list3], [tsv_to_pivot1, tsv_to_pivot2]):
    print(f" - tsv list: {tsv_list} , pivoted by {tsv_to_pivot}")
    get_tsv_joint_marginals(
        project_path,
        tsv_list=tsv_list,
        tsv_to_pivot=tsv_to_pivot,
        output_file=create_output_filename(tsv_list, tsv_to_pivot)
        )
"""

for tsv_list, filtering in zip(
    [tsv_list1, tsv_list2, tsv_list3, tsv_list3],
    ["", "_below_200fpl", "_below_80ami", "_80_to_150ami"],
):
    for idx, tsv_to_pivot in enumerate([tsv_to_pivot1, tsv_to_pivot2]):
        print(f" - Processing distribution of : {tsv_list} , pivoted by {tsv_to_pivot}")
        filename = create_output_filename(tsv_list, tsv_to_pivot)

        df = pd.read_csv(filename)
        # col = "Unnamed: 0"
        # if col in df.columns:
        #     del df[col]
        # df.to_csv(filename, index=False)

        pivoted_cols = [col for col in df.columns if col not in tsv_list]

        # post-processing
        new_col = "Geometry Building Type"
        df[new_col] = "Single-Family"
        df.loc[
            df["Geometry Building Type RECS"].str.startswith("Multi-Family"), new_col
        ] = "Multi-Family"

        tsv_list_new = tsv_list.copy()
        tsv_list_new.remove("Geometry Building Type RECS")
        tsv_list_new.remove("Vacancy Status")
        tsv_list_new.append(new_col)

        cond = df["Vacancy Status"] == "Occupied"
        if filtering == "_below_200fpl":
            filter_col = "Federal Poverty Level Tribal"
            filter_list = ["0-100%", "100-150%", "150-200%"]
        if filtering == "_below_80ami":
            filter_col = "Area Median Income Tribal"
            filter_list = ["0-30%", "30-60%", "60-80%"]
        if filtering == "_80_to_150ami":
            filter_col = "Area Median Income Tribal"
            filter_list = ["80-100%", "100-120%", "120-150%"]

        if filtering != "":
            print(f"filtering to {filtering}...")
            tsv_list_new.remove(filter_col)
            delta = set(filter_list) - set(df[filter_col].unique())
            assert len(delta) == 0, f"Invalid filter_list for {filter_col}: {delta}"
            cond &= df[filter_col].isin(filter_list)

        df = df.loc[cond].groupby(tsv_list_new)[pivoted_cols].sum().reset_index()

        # apply AIA mapping
        df = df.join(
            mapping.set_index(["PUMA", "State"]), on=["PUMA", "State"], how="inner"
        )

        tsv_list_new.remove("PUMA")
        tsv_list_new.remove("State")
        tsv_list_new = ["State", "AIANNHCE", "NAME"] + tsv_list_new
        df = df.groupby(tsv_list_new).apply(
            lambda x: x[pivoted_cols].multiply(x["percent_hu"], axis=0).sum()
        )
        total_col = "Total Homes" if filtering == "" else "Total Homes Below Threshold"
        df[total_col] = df[pivoted_cols].sum(axis=1)

        # extend to total national count
        n_buildings_represented = 136569411  # American Community Survey 2019 5-year, B25001, does not include AK, HI, and territories
        df[pivoted_cols + [total_col]] *= n_buildings_represented
        print(f"Total homes in AIA: {df[total_col].sum()}")

        # combine df and save to file
        new_filename = f"Processed_HC_breakdown_tribal_{tsv_to_pivot}{filtering}.csv"
        df.to_csv(data_dir / new_filename, index=True)
        print(f"file saved to: {data_dir / new_filename}\n")
