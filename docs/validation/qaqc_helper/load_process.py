import pandas as pd
from pathlib import Path

from . import utils

### [2] Load func
def load_baseline_and_upgrades(data_dir, baseline_data_dir=None, success_only=True):
    """
    Load files by combining baseline and upgrades

    Returns:
        dfb : pd.DataFrame
            baseline dataframe
        DFU : dict
            dictionary of upgrade dataframes : {upgrade_name: dataframe}
    """
    print(
        """
        Returned output is: 
            first output: baseline dataframe
            second output: dictionary of upgrade packages, with key = upgrade_name and value = upgrade dataframe
        """
    )

    if baseline_data_dir is None:
        print(f"Using data_dir for daseline_data_dir: {data_dir}")
        baseline_data_dir = data_dir
    dfb = pd.read_parquet(baseline_data_dir / "results_up00.parquet")
    dfb = dfb.sort_values(by=["building_id"]).reset_index(drop=True)
    print(f'Baseline: {dfb.groupby(["completed_status"])["building_id"].count()}')

    if success_only:
        bcond = dfb["completed_status"] == "Success"
        dfb = dfb.loc[bcond]
    dfb = dfb.set_index("building_id").sort_index()

    upgrade_files = sorted(
        [x for x in data_dir.rglob("*.parquet") if x.name != "results_up00.parquet"]
    )
    DFU = dict()
    for file in upgrade_files:
        dfu = pd.read_parquet(file)
        dfu = dfu.sort_values(by=["building_id"]).reset_index(drop=True)
        upg_name = dfu["apply_upgrade.upgrade_name"].unique()[0]

        print(
            f'Upgrade {upg_name}: {dfu.groupby(["completed_status"])["building_id"].count()}'
        )
        if success_only:
            cond = (
                bcond
                & (dfu["completed_status"] == "Success")
                & (dfu["apply_upgrade.applicable"] == True)
            )
            dfu = dfu.loc[cond]
        dfu = dfu.set_index("building_id").sort_index()

        DFU[upg_name] = dfu

    if DFU == dict():
        raise ValueError(f"DFU is empty, check that data_dir is not empty: {data_dir}!")
    return dfb, DFU


### [3] add new cols to df funcs
def calculate_energy_burden(dfi, dfb=None):
    if "rep_income" not in dfi.columns:
        assert (
            dfb is not None
        ), "dfb is required to give 'rep_income' col for calculate_energy_burden"
    else:
        dfb = dfi.copy()

    if "report_utility_bills.bills_total_usd" not in dfi.columns:
        raise ValueError("df does not have bill columns")

    if dfi.index.name == "building_id":
        if dfb.index.name == "building_id":
            cond = dfi.index
        else:
            raise ValueError("dfb has different index than dfi")

    if dfi.index.name is None:
        if dfb.index.name is None:
            cond = dfb["building_id"].isin(dfi["building_id"])
        else:
            raise ValueError("dfb has different index than dfi")

    dfi["energy_burden_pct"] = (
        dfi["report_utility_bills.bills_total_usd"].div(
            dfb.loc[cond, "rep_income"], axis=0
        )
        * 100
    ).round(2)

    return dfi


def add_consolidated_columns(df):
    orig_cols = df.columns
    df["lmi"] = df["build_existing_model.area_median_income"].map(
        {
            "0-30%": "0-80%",
            "30-60%": "0-80%",
            "60-80%": "0-80%",
            "80-100%": "80-120%",
            "100-120%": "80-120%",
            "120-150%": "120%+",
            "150%+": "120%+",
            "Not Available": "Not Available",
        }
    )

    df["fpl"] = df["build_existing_model.federal_poverty_level"].map(
        {
            "0-100%": "0-200%",
            "100-150%": "0-200%",
            "150-200%": "0-200%",
            "200-300%": "200-400%",
            "300-400%": "200-400%",
            "400%+": "400%+",
            "Not Available": "Not Available",
        }
    )

    df["tenure"] = df["build_existing_model.tenure"]

    df["iqr_cohort_energy"] = utils.divide_iqr_cohort_based_on(
        df, "report_simulation_output.energy_use_total_m_btu"
    )
    df["iqr_cohort_electricity"] = utils.divide_iqr_cohort_based_on(
        df, "report_simulation_output.fuel_use_electricity_total_m_btu"
    )

    df["iqr_cohort_utility_bill"] = utils.divide_iqr_cohort_based_on(
        df, "report_utility_bills.bills_total_usd"
    )
    df["iqr_cohort_electric_bill"] = utils.divide_iqr_cohort_based_on(
        df, "report_utility_bills.bills_electricity_total_usd"
    )

    new_cols = [col for col in df.columns if col not in orig_cols]
    return df, new_cols


def map_representative_income(baseline_df):
    income_lookup_dir = Path(".").resolve() / "data" / "helper_files"
    baseline_df = assign_representative_income(baseline_df, income_lookup_dir)

    return baseline_df

    return DF


def get_upgrade_saving_dataframe(
    dfb, DFU, metric, output_type="saving", add_metadata=True
):
    """Calculate saving or delta for metric for each upgrade, concatenate into a single dataframe with baseline metadata
    saving = baseline - upgrade
    delta = upgrade - baseline
    None is used for metrics only available in DFU, such as upgrade_cost
    """
    if output_type not in ["saving", "delta", None]:
        raise ValueError(
            f"Unsupported output_type={output_type}, valid options = ['saving', 'delta', None]"
        )

    DF = []
    for dfu in DFU.values():
        dfu = dfu.rename(columns={"apply_upgrade.upgrade_name": "upgrade"})
        if output_type is None:
            df = dfu[["upgrade", metric]]
        else:
            delta = dfu[metric] - dfb.loc[dfu.index, metric]
            if output_type == "saving":
                delta *= -1

            df = pd.concat(
                [
                    dfu["upgrade"],
                    delta.rename(metric + f"_{output_type}"),
                ],
                axis=1,
            )

        if add_metadata:
            df = add_metadata_from_baseline(df, dfb)
        DF.append(df.reset_index())

    DF = pd.concat(DF, axis=0, ignore_index=True)

    return DF


def add_metadata_from_baseline(dfu, dfb):
    not_cols = [
        col for col in dfb.columns if col.startswith("report_simulation_output")
    ]
    not_cols += [col for col in dfb.columns if col.startswith("upgrade_costs")]
    not_cols += [col for col in dfb.columns if col.startswith("qoi_report")]
    not_cols += [col for col in dfb.columns if col.startswith("report_utility_bills")]
    not_cols += [col for col in dfb.columns if col.startswith("apply_upgrade")]
    not_cols += ["job_id", "started_at", "completed_at", "completed_status"]
    meta_cols = [col for col in dfb.columns if col not in not_cols]
    return dfb[meta_cols].join(dfu, how="right")


### funcs for mapping rep_income recursively
def process_ami_lookup(geography, data_dir):
    """
    geography option: PUMA, State, Census Division

    """
    if geography == "County and PUMA":
        file = "income_bin_representative_values_by_county_puma_occ_FPL.csv"
    elif geography == "PUMA":
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
        puma_file_full_path = data_dir / "spatial_puma_lookup-v2.csv"
        if puma_file_full_path.exists():
            puma_map = pd.read_csv(puma_file_full_path)
        else:
            puma_map = pd.read_parquet(
                data_dir / "spatial_block_lookup_table-v2.parquet"
            )
            puma_map = puma_map[
                ["puma_tsv", "nhgis_2010_puma_gisjoin"]
            ].drop_duplicates()
            puma_map.to_csv(puma_file_full_path, index=False)

        ami_lookup[geography] = ami_lookup[geography].map(
            puma_map.set_index("puma_tsv")["nhgis_2010_puma_gisjoin"]
        )

    ami_lookup = ami_lookup.rename(columns={income_col: "rep_income"})

    return ami_lookup, deps


def assign_representative_income(df, data_dir):
    non_geo_cols = [
        "build_existing_model.occupants",
        "build_existing_model.federal_poverty_level",
        "build_existing_model.income",
    ]
    geographies = [
        "County and PUMA",
        "PUMA",
        "State",
        "Census Division",
        "Census Region",
    ]
    geo_cols = [
        "build_existing_model." + geo.lower().replace(" ", "_") for geo in geographies
    ]
    df_section = df[geo_cols + non_geo_cols].copy()
    geographies += ["National"]

    # map rep income by increasingly large geographic resolution
    for idx in range(len(geographies)):
        geography = geographies[idx]
        ami_lookup, deps = process_ami_lookup(geography, data_dir)
        if idx == len(geographies) - 1:
            keys = non_geo_cols
        else:
            keys = [geo_cols[idx]] + non_geo_cols

        if idx == 0:
            # map value by County and PUMA
            df_section = df_section.join(
                ami_lookup.set_index(deps),
                on=keys,
            )
        else:
            # map remaining value
            df_section.loc[df_section["rep_income"].isna(), "rep_income"] = (
                df_section[keys]
                .astype(str)
                .agg("-".join, axis=1)
                .map(
                    ami_lookup.assign(
                        key=ami_lookup[deps].astype(str).agg("-".join, axis=1)
                    ).set_index("key")["rep_income"]
                )
            )
            if len(df_section[df_section["rep_income"].isna()]) == 0:
                print(
                    f"Highest resolution used for mapping representative income: {geography}"
                )
                break

    if len(df_section[df_section["rep_income"].isna()]) > 0:
        df_in_question = df_section.loc[df_section["rep_income"].isna()]
        assert list(df_in_question["build_existing_model.occupants"].unique()) == [
            "0"
        ], f"rep_income cannot be mapped for the following:\n{df_in_question}"

    df["rep_income"] = df_section["rep_income"]

    return df
