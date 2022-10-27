"""
Postprocess in.area_median_income to EUSS Round 1 results (2022-09-16) (applicable to baseline and 10 packages)

This script requires resstock-estimation conda env and access to resstock-estimation GitHub repo

Author: lixi.liu@nrel.gov 
Date: 2022-10-06
"""
from pathlib import Path
import sys
import numpy as np
import pandas as pd

resstock_estimation = Path(__file__).resolve().parents[2] / "resstock-estimation"
sys.path.append(resstock_estimation)
from utils.parameter_option_maps import ParameterOptionMaps

POM = ParameterOptionMaps()


data_dir = Path(__file__).resolve().parent / "data"

### Add AMI tags to EUSS
def process_ami_lookup(geography):
    """
    geography option: PUMA, State, Census Division

    """
    if geography == "PUMA":
        file = "income_bin_representative_values_by_puma_occ_FPL.csv"
    elif geography == "State":
        file = "income_bin_representative_values_by_state_occ_FPL.csv"
    elif geography == "Census Division":
        file = "income_bin_representative_values_by_cendiv_occ_FPL.csv"
    elif geography == "Census Region":
        file = "income_bin_representative_values_by_cenreg_occ_FPL.csv"
    elif geography == "National":
        file = "income_bin_representative_values_by_occ_FPL.csv"
    else:
        raise ValueError(f"geography={geography} not supported")

    ami_lookup = pd.read_csv(data_dir / file)
    deps = ["Occupants", "Federal Poverty Level", "Income"]
    deps = [geography] + deps if geography != "National" else deps
    income_col = "weighted_median"
    ami_lookup = ami_lookup[
        ~ami_lookup[deps + [income_col]].isna().any(axis=1)
    ].reset_index(drop=True)[deps + [income_col]]

    if geography == "PUMA":
        # map puma to version in EUSS
        puma_file_full_path = data_dir / "spatial_puma_lookup.csv"
        if puma_file_full_path.exists():
            puma_map = pd.read_csv(puma_file_full_path)
        else:
            puma_map = pd.read_parquet(data_dir / "spatial_block_lookup_table.parquet")
            puma_map = puma_map[
                ["puma_tsv", "nhgis_2010_puma_gisjoin"]
            ].drop_duplicates()
            puma_map.to_csv(puma_file_full_path, index=False)

        ami_lookup[geography] = ami_lookup[geography].map(
            puma_map.set_index("puma_tsv")["nhgis_2010_puma_gisjoin"]
        )

    ami_lookup = ami_lookup.rename(columns={income_col: "rep_income"})

    return ami_lookup, deps


def get_median_from_bin(value_bin, lower_multiplier=0.9, upper_multipler=1.1):
    if "<" in value_bin:
        return float(value_bin.strip("<")) * lower_multiplier
    if "+" in value_bin:
        return float(value_bin.strip("+")) * upper_multipler

    return np.mean([float(x) for x in value_bin.split("-")])


def assign_representative_income(df):
    # map value by PUMA
    geography = "PUMA"
    geo_col = "in." + geography.lower().replace(" ", "_")
    ami_lookup_puma, deps_puma = process_ami_lookup(geography)
    df = df.join(
        ami_lookup_puma.set_index(deps_puma),
        on=[geo_col, "in.occupants", "in.federal_poverty_level", "in.income"],
    )

    # map remaining value by State
    geography = "State"
    geo_col = "in." + geography.lower().replace(" ", "_")
    ami_lookup_state, deps_state = process_ami_lookup(geography)
    keys = [geo_col, "in.occupants", "in.federal_poverty_level", "in.income"]
    df.loc[df["rep_income"].isna(), "rep_income"] = (
        df[keys]
        .astype(str)
        .agg("-".join, axis=1)
        .map(
            ami_lookup_state.assign(
                key=ami_lookup_state[deps_state].astype(str).agg("-".join, axis=1)
            ).set_index("key")["rep_income"]
        )
    )

    # map remaining value by Census Division
    geography = "Census Division"
    geo_col = "in." + geography.lower().replace(" ", "_")
    ami_lookup_state, deps_state = process_ami_lookup(geography)
    keys = [geo_col, "in.occupants", "in.federal_poverty_level", "in.income"]
    df.loc[df["rep_income"].isna(), "rep_income"] = (
        df[keys]
        .astype(str)
        .agg("-".join, axis=1)
        .map(
            ami_lookup_state.assign(
                key=ami_lookup_state[deps_state].astype(str).agg("-".join, axis=1)
            ).set_index("key")["rep_income"]
        )
    )

    # map remaining value by Census Region
    geography = "Census Region"
    geo_col = "in." + geography.lower().replace(" ", "_")
    ami_lookup_state, deps_state = process_ami_lookup(geography)
    keys = [geo_col, "in.occupants", "in.federal_poverty_level", "in.income"]
    df.loc[df["rep_income"].isna(), "rep_income"] = (
        df[keys]
        .astype(str)
        .agg("-".join, axis=1)
        .map(
            ami_lookup_state.assign(
                key=ami_lookup_state[deps_state].astype(str).agg("-".join, axis=1)
            ).set_index("key")["rep_income"]
        )
    )

    # map remaining value by National
    geography = "National"
    ami_lookup_state, deps_state = process_ami_lookup(geography)
    keys = ["in.occupants", "in.federal_poverty_level", "in.income"]
    df.loc[df["rep_income"].isna(), "rep_income"] = (
        df[keys]
        .astype(str)
        .agg("-".join, axis=1)
        .map(
            ami_lookup_state.assign(
                key=ami_lookup_state[deps_state].astype(str).agg("-".join, axis=1)
            ).set_index("key")["rep_income"]
        )
    )

    assert len(df[df["rep_income"].isna()]) == 0, df[df["rep_income"].isna()]

    return df


def assign_median_income_by_county(df):
    mi_county = pd.read_csv(data_dir / "fy2019_hud_median_income_by_county.csv")
    df = df.join(mi_county.set_index("county_gis")["median2019"], on=["in.county"])

    assert len(df[df["median2019"].isna()]) == 0, df[df["median2019"].isna()]

    return df


def assign_representative_occupants(df):
    """representative value for 10+ is 11 according to 2019_5yrs_PUMS data in resstock-estimation"""
    df["rep_occupants"] = df["in.occupants"].replace("10+", "11").astype(int)

    return df


def read_file(file_path: Path):
    file_type = file_path.suffix
    if file_type == ".csv":
        return pd.read_csv(file_path, low_memory=False)
    elif file_type == ".parquet":
        return pd.read_parquet(file_path, low_memory=False)
    else:
        raise ValueError(f"file_type={file_type} not supported")


def write_to_file(df, file_path: Path):
    file_type = file_path.suffix
    if file_type == ".csv":
        df.to_csv(file_path, index=False)
    elif file_type == ".parquet":
        df.to_parquet(file_path)
    else:
        raise ValueError(f"file_type={file_type} not supported")

    print("File modified and saved in place of original file.")


def add_ami_column_to_file(file_path):
    print(
        "=============================================================================="
    )
    print(
        "This script is for use on ResStock results postprocessed for Sightglass only. "
    )
    print("Such as End Use Load Profile Round 1 results uploaded to OEDI (2022-09-16)")
    print(
        """
        https://data.openei.org/s3_viewer?bucket=oedi-data-lake&prefix=nrel-pds-building-
        stock%2Fend-use-load-profiles-for-us-building-stock%2F2022%2Fresstock_amy2018_
        release_1%2Fmetadata_and_annual_results%2Fnational%2Fcsv%2F
        """
    )
    print("It expects result columns with prefixes such as: 'in.', 'out.'")
    print("")
    print(
        "This script requires resstock-estimation conda env and access to resstock-estimation GitHub repo"
    )
    print("Adding in.area_median_income to file:")
    print(
        f"""
        {file_path}
        """
    )
    print(
        "=============================================================================="
    )
    file_path = Path(file_path)
    df = read_file(file_path)
    df = assign_representative_income(df)
    df = assign_median_income_by_county(df)
    df = assign_representative_occupants(df)
    df = POM.map_percent_area_median_income(
        df,
        "median2019",
        "rep_income",
        "rep_occupants",
        output_col="in.area_median_income",
    )
    assert len(df[df["in.area_median_income"].isna()]) == 0, df[
        df["in.area_median_income"].isna()
    ]

    df = df.drop(columns=["median2019", "rep_income", "rep_occupants"])
    write_to_file(df, file_path)


def main():
    """
    This
    Usage: python add_ami_to_euss_results.py path_to_euss_result_file.csv
    """
    if len(sys.argv) != 2:
        print("Usage: python add_ami_to_euss_results.py <path_to_euss_result_file.csv>")
        sys.exit(1)
    else:
        add_ami_column_to_file(sys.argv[1])


if __name__ == "__main__":
    main()
