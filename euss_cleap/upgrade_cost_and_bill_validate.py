"""
VALIDATION of upgrade and volumetric bill recalculation - 

C-LEAP Implementation of Community Cost Information into 
EUSS Round 1 Results

by: Lixi.Liu@nrel.gov
06-05-2023
"""

import pandas as pd
from pathlib import Path
import sys
import numpy as np
import re
import argparse


def main(community_name="Test", as_percentage=False):
    datadir = Path(__file__).resolve().parent / "data_" / "community_building_samples" / community_name
    outdir = Path(__file__).resolve().parent / "data_" / "community_building_samples_with_upgrade_cost_and_bill" / community_name
    ext = ""

    if community_name is not None:
        ext = "__" + community_name.lower().replace(" ", "_")
        print(f"Validating processed data for [[ {community_name} ]] ...")

    if not outdir.exists():
        print(
            f"outdir does not exist: {outdir} \n" "run upgrade_cost_and_bill.py first"
        )
        sys.exit(1)

    in_files = sorted(datadir.rglob("up[0-9][0-9]_duct_corrected.parquet"))
    out_files = sorted(outdir.rglob(f"up[0-9][0-9]{ext}.parquet"))

    assert len(in_files) == len(
        out_files
    ), f"{len(in_files)} in_files vs. {len(out_files)} out_files"

    for fi, fo in zip(in_files, out_files):
        upni, upno = re.findall(r"\d+", fi.stem), re.findall(r"\d+", fo.stem)
        assert upni == upno, f"input {upni} vs output {upno}"
        print("---------------------")
        print(f"For upgrade = {upni}:")
        print("---------------------")

        dfi = pd.read_parquet(fi).sort_values(by=["building_id"]).reset_index(drop=True)
        dfo = pd.read_parquet(fo).sort_values(by=["building_id"]).reset_index(drop=True)

        # check df len
        assert len(dfi) == len(dfo), f"dfi and dfo are not equal in length"
        assert (
            dfi.loc[dfi["completed_status"] == "Success", "building_id"].to_list()
            == dfo.loc[dfo["completed_status"] == "Success", "building_id"].to_list()
        ), "dfi and dfo do not have the same set of successful simulations"

        # check new cols
        new_cols = list(set(dfo.columns) - set(dfi.columns))
        if community_name == "hill_district":
            new_cols = [x for x in new_cols if x != "sample_weight"]
        assert len(new_cols) == 5, f"unknown new_cols found: {new_cols}"
        assert set(x.split(".")[0] for x in new_cols) == {
            "report_utility_bills"
        }, f"unknown new_cols found: {new_cols}"

        # check upgrade cost
        print("\n --- Check Upgrade Costs --- ")
        has_change = check_upgrade_cost_change(dfi, dfo, as_percentage=as_percentage)

        # check bills
        print("\n --- Check Bills --- ")
        check_bills(dfo)

        # clean up & save
        ndfi, ndfo = dfi.shape[1], dfo.shape[1]
        dfi = dfi.drop(columns=[x for x in dfi.columns if "Unnamed" in x])
        dfo = dfo.drop(columns=[x for x in dfo.columns if "Unnamed" in x])

        if dfi.shape[1] < ndfi:
            dfi.to_csv(fi, index=False)
            print(f" -> dfi cleaned up and saved to: {fi}")
        if dfo.shape[1] < ndfo:
            dfo.to_csv(fo, index=False)
            print(f" -> dfo cleaned up and saved to: {fo}")


def check_bills(dfo):
    for fuel in ["total", "electricity", "natural_gas", "propane", "fuel_oil"]:
        if fuel == "total":
            bill_col = f"report_utility_bills.bills_total_usd"
            energy_col = f"report_simulation_output.energy_use_net_m_btu"
        else:
            bill_col = f"report_utility_bills.bills_{fuel}_total_usd"
            energy_col = f"report_simulation_output.fuel_use_{fuel}_total_m_btu"
            if fuel == "electricity":
                energy_col = "report_simulation_output.fuel_use_electricity_net_m_btu"

        assert (
            dfo.loc[dfo[energy_col].isna(), bill_col].isna().prod() == 1
        ), f"{bill_col} has values for NAN rows: {dfo.loc[dfo[energy_col].isna(), bill_col]}"
        print(dfo[bill_col].describe())
        print()


def check_upgrade_cost_change(dfi, dfo, as_percentage=False):
    """check changes in upgrade costs"""
    threshold = 25 # [%] TODO

    change_type = "absolute"
    if as_percentage:
        change_type = "percent"

    metric = "upgrade_costs.upgrade_cost_usd"
    uc_pct_diff = (((dfo[metric] - dfi[metric]) / dfi[metric]) * 100).fillna(0)
    has_change = False
    beyond_threshold = False

    if (uc_pct_diff!=0).sum() > 0:
        has_change = True

    cond = uc_pct_diff > threshold
    if cond.sum() > 0:
        beyond_threshold = True
        n1, n2 = cond.sum(), len(dfi)
        print(
            f" * {n1} / {n2} ( {n1/n2*100:.02f}% ) building_id see upgrade_cost INCREASED by {threshold}%+ after processing"
        )
        df_opt = calculate_option_cost_change(
            dfi, dfo, cond, as_percentage=as_percentage
        )
        top_n = 4
        df_max, df_idxmax = get_max_option_cost_change(
            df_opt, top_n=top_n, as_percentage=as_percentage
        )
        df_namemax = get_max_option_cost_change_name(df_idxmax, dfo)
        df_max = pd.concat(
            [
                dfi.loc[cond, metric].rename("upgrade_cost_before"),
                dfo.loc[cond, metric].rename("upgrade_cost_after"),
                uc_pct_diff.loc[cond].rename("pct_delta"),
                df_max,
            ],
            axis=1,
        )
        print(f"Top {top_n} largest {change_type} change in option cost usd:")
        print(df_max)
        print("from option:")
        print(df_namemax)
        print()

    cond = uc_pct_diff < -threshold
    if cond.sum() > 0:
        beyond_threshold = True
        n1, n2 = cond.sum(), len(dfi)
        print(
            f" * {n1} / {n2} ( {n1/n2*100:.02f}% ) building_id see upgrade_cost DECREASED by {threshold}%+ after processing"
        )
        df_opt = calculate_option_cost_change(
            dfi, dfo, cond, as_percentage=as_percentage
        )
        top_n = 4
        df_max, df_idxmax = get_max_option_cost_change(
            df_opt, top_n=top_n, as_percentage=as_percentage
        )
        df_namemax = get_max_option_cost_change_name(df_idxmax, dfo)
        df_max = pd.concat(
            [
                dfi.loc[cond, metric].rename("upgrade_cost_before"),
                dfo.loc[cond, metric].rename("upgrade_cost_after"),
                uc_pct_diff.loc[cond].rename("pct_delta"),
                df_max,
            ],
            axis=1,
        )
        print(f"Top {top_n} largest change in option cost usd:")
        print(df_max)
        print("from option:")
        print(df_namemax)
        print()

    if not has_change:
        print("No change to upgrade costs!")
    if has_change and not beyond_threshold:
        print(f"Upgrade cost changes are ALL less than {threshold}%")

    return has_change


def get_max_option_cost_change_name(df_idxmax, dfo):
    """get option_name of option_cost columns"""
    df = df_idxmax.copy()
    for idx in df_idxmax.index:
        for col in df.columns:
            name = df.loc[idx, col]
            if isinstance(name, str):
                name = name.removesuffix("cost_usd") + "name"
                df.loc[idx, col] = dfo.loc[idx, name]

    return df


def calculate_option_cost_change(dfi, dfo, cond, as_percentage=False):
    """calculate percent change for each option cost column"""
    cost_cols = [
        col
        for col in dfi.columns
        if col.startswith("upgrade_costs.option_") and col.endswith("_cost_usd")
    ]
    df_option = dfo.loc[cond, cost_cols] - dfi.loc[cond, cost_cols]
    if as_percentage:
        df_option *= 100 / dfi.loc[cond, cost_cols]
    return df_option


def get_max_option_cost_change(df_option, top_n=5, as_percentage=False):
    """get top_n largest option_cost change and which option they come from"""
    ext = "abs"
    if as_percentage:
        ext = "pct"
    df_max, df_idxmax = [], []
    for i in range(1, top_n + 1):
        df_max.append(df_option.max(axis=1).rename(f"largest_{i}_{ext}_delta"))
        max_idx = df_option.idxmax(axis=1)
        df_idxmax.append(max_idx.rename(f"largest_{i}_source"))

        for idx in df_option.index:
            col = max_idx[idx]
            if isinstance(col, str):
                df_option.loc[idx, col] = np.nan

    df_max, df_idxmax = pd.concat(df_max, axis=1), pd.concat(df_idxmax, axis=1)
    return df_max, df_idxmax


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "community_name",
        help="name of community, for adding extension to output file",
    )
    parser.add_argument(
        "-p",
        "--as_percentage",
        action="store_true",
        help="whether to show change in option_cost in percentage (as opposed to absolute) where change in total upgrade_cost > 50 percent",
    )
    parser.add_argument(
        "-t",
        "--test",
        action="store_true",
        help="whether to use EUSS default costs (cost_test.csv) as input file for testing",
    )

    args = parser.parse_args()
    community_name = args.community_name.lower().replace(" ", "_")
    if args.test:
        community_name = "test"

    main(community_name=community_name, as_percentage=args.as_percentage)
