"""
Calculate panel replacement
    - capacity upgrade requirement based on panel capacity prediction and NEC new load calculations
    - subpanel requirement based on available breaker space prediction and breaker space calculations (Not implemented yet)
created: 06-14-2024
updated: 06-14-2024
"""
import numpy as np
from pathlib import Path
import argparse
from itertools import chain

import pandas as pd

from plotting_functions import _plot_bar_stacked


def read_file(filename: str, low_memory: bool =True, sort_bldg_id: bool = False, **kwargs) -> pd.DataFrame:
    """ If file is large, use low_memory=False"""
    filename = Path(filename)
    if filename.suffix in [".csv", ".gz"]:
        df = pd.read_csv(filename, low_memory=low_memory, keep_default_na=False, **kwargs)
    elif filename.suffix == ".parquet":
        df = pd.read_parquet(filename, **kwargs)
    else:
        raise TypeError(f"Unsupported file type, cannot read file: {filename}")

    if sort_bldg_id:
        df = df.sort_values(by="building_id").reset_index(drop=True)

    return df


def generate_plots(dfb: pd.DataFrame, dfu: pd.DataFrame, output_dir: Path, sfd_only: bool = False, upgrade_num: str = ""):
    msg = " for Single-Family Detached only" if sfd_only else ""
    print(f"generating plots{msg}...")
    HC_list = [
        "build_existing_model.census_region",
        "build_existing_model.census_division",
        "build_existing_model.ashrae_iecc_climate_zone_2004",
        "build_existing_model.geometry_building_type_recs",  # dep
        "build_existing_model.state",
        "build_existing_model.vintage",  # dep
        "build_existing_model.vintage_acs",
        "build_existing_model.federal_poverty_level",
        "build_existing_model.area_median_income",
        "build_existing_model.tenure",
        "build_existing_model.geometry_floor_area_bin",
        "build_existing_model.geometry_floor_area",  # dep
        "build_existing_model.heating_fuel",  # dep
        "build_existing_model.water_heater_fuel",  # dep
        "build_existing_model.hvac_heating_type",
        "build_existing_model.hvac_cooling_type",  # dep
        "build_existing_model.has_pv", # dep
    ]

    df = dfu.join(dfb.set_index("building_id")[HC_list], on="building_id", how="left")
    upgrade_name = [x for x in df["apply_upgrade.upgrade_name"].unique() if x not in [None, "", np.nan]][0]

    panel_metrics = ["panel_capacity_upgrade_220.83", "panel_capacity_upgrade_220.87"]

    for metric in panel_metrics:
        title = f"{upgrade_name}\n{metric.replace('_', ' ')}"
        _plot_bar_stacked(
            df,
            ["build_existing_model.vintage", "build_existing_model.geometry_floor_area", metric],
            output_dir=output_dir,
            sfd_only=sfd_only,
            upgrade_num=upgrade_num,
            title=title
        )
        _plot_bar_stacked(
            df,
            [
                "build_existing_model.census_region",
                "build_existing_model.geometry_building_type_recs",
                metric,
            ],
            output_dir=output_dir,
            sfd_only=sfd_only,
            upgrade_num=upgrade_num,
            title=title
        )

        for hc in HC_list + ["predicted_panel_amp_bin", "loads_upgraded"]:
            _plot_bar_stacked(df, [hc, metric], output_dir=output_dir, sfd_only=sfd_only, upgrade_num=upgrade_num, title=title)

    print(f"plots output to: {output_dir}")


def calculate_panel_capacity_upgrade(dfb, dfu):
    assert "predicted_panel_amp" in dfb.columns, "'predicted_panel_amp' not in baseline file"
    assert "amp_total_post_upgrade_A_220_87" in dfu.columns, "'upgrade file does not contain NEC calculations'"

    df_up = dfu.join(dfb.set_index(["building_id"])[["predicted_panel_amp_bin", "predicted_panel_amp"]], on=["building_id"], how="left")

    for method in ["83", "87"]:
        label = f"panel_capacity_upgrade_220.{method}"
        df_up.loc[df_up[f"amp_total_post_upgrade_A_220_{method}"]>df_up["predicted_panel_amp"], label] = True
        df_up.loc[df_up[f"amp_total_post_upgrade_A_220_{method}"]<=df_up["predicted_panel_amp"], label] = False

    return df_up



def main(baseline_file: Path, upgrade_nec_file: Path, sfd_only: bool=False):
    dfb = read_file(baseline_file)
    dfu = read_file(upgrade_nec_file)
    dfu = calculate_panel_capacity_upgrade(dfb, dfu)

    output_filedir = upgrade_nec_file.parents[1] / "panel_replacement"
    output_filedir.mkdir(parents=True, exist_ok=True)
    output_filename = output_filedir / (upgrade_nec_file.stem+".csv")
    dfu.to_csv(output_filename, index=False)
    print(f"Added panel_capacity_upgrade columns and save to {output_filedir}")

    upgrade_num = [x for x in 
        list(chain(*[x.split(".") for x in upgrade_nec_file.stem.split("_")]))
        if "up" in x][0]
    output_dir = upgrade_nec_file.parents[1] / "plots" / "panel_replacement" / upgrade_num
    output_dir.mkdir(parents=True, exist_ok=True)
    generate_plots(dfb, dfu, output_dir, sfd_only=sfd_only, upgrade_num=upgrade_num)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "baseline_file",
        action="store",
        help="Path to file containing 'predicted_panel_amp' column"
        )
    parser.add_argument(
        "upgrade_nec_file",
        action="store",
        help="Path to file containing NEC calculation columns such as 'amp_total_post_upgrade_A_220_83'"
        )
    parser.add_argument(
        "-d",
        "--sfd_only",
        action="store_true",
        default=False,
        help="Apply calculation to Single-Family Detached only (this is only on plotting for now)",
    )

    args = parser.parse_args()

    main(Path(args.baseline_file), Path(args.upgrade_nec_file), sfd_only=args.sfd_only)
