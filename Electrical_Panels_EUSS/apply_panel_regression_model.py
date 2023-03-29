from pathlib import Path
import argparse
import sys
import pickle
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import re


local_dir = Path(__file__).resolve().parent

def load_model():
    model_file = local_dir / "prelim_panel_model.p"
    model = pickle.load(open(model_file, "rb"))
    model.feature_names = [
        "sqft",
        "geometry_building_type_recs__Mobile Home",
        "geometry_building_type_recs__Multi-Family with 2 - 4 Units",
        "geometry_building_type_recs__Multi-Family with 5+ Units", 
        "geometry_building_type_recs__Single-Family Attached", 
        "geometry_building_type_recs__Single-Family Detached", 
        "hvac_cooling_type__Central AC", 
        "hvac_cooling_type__Heat Pump", 
        "hvac_cooling_type__None", 
        "hvac_cooling_type__Room AC", 
        "has_pv__No", 
        "has_pv__Yes", 
        "has_elec_heating__False", 
        "has_elec_heating__True", 
        "water_heater_fuel_simp__Electricity", 
        "water_heater_fuel_simp__non_Electricity", 
        "vintage__1940s", 
        "vintage__1950s", 
        "vintage__1960s", 
        "vintage__1970s", 
        "vintage__1980s", 
        "vintage__1990s", 
        "vintage__2000s", 
        "vintage__2010s", 
        "vintage__2020s", 
        "vintage__<1940"
    ] # ask LBNL to store this in model
    return model


def apply_model_to_results(df, model, predict_proba=False):
    ## -- process data to align with model inputs --
    input_cols_map = {
        "upgrade_costs.floor_area_conditioned_ft_2": "sqft", # numeric
        "build_existing_model.geometry_building_type_recs": "geometry_building_type_recs",
        "build_existing_model.hvac_cooling_type": "hvac_cooling_type",
        "build_existing_model.has_pv": "has_pv",
        "build_existing_model.heating_fuel": "has_elec_heating",
        "build_existing_model.water_heater_fuel": "water_heater_fuel_simp",
        "build_existing_model.vintage": "vintage",
    }
    categorical_columns = list(input_cols_map.values())[1:]

    cond = df["completed_status"] == "Success"
    dfi = df.loc[cond, ["building_id"]+list(input_cols_map.keys())].reset_index(drop=True).rename(columns=input_cols_map)

    # special mapping for heating fuels:
    dfi["has_elec_heating"] = dfi["has_elec_heating"].map({
        "Electricity": "True",
        "Fuel Oil": "False",
        "Natural Gas": "False",
        "None": "False",
        "Other Fuel": "False",
        "Propane": "False",
    })

    dfi["water_heater_fuel_simp"] = dfi["water_heater_fuel_simp"].map({
        "Electricity": "Electricity",
        "Fuel Oil": "non_Electricity",
        "Natural Gas": "non_Electricity",
        "Other Fuel": "non_Electricity",
        "Propane": "non_Electricity"
    })


    dfii = pd.get_dummies(dfi, columns=categorical_columns, prefix_sep="__").drop(columns=["building_id"])
    # add any missing cols
    for col in model.feature_names: 
        if col not in dfii.columns:
            print(f" - adding dummy encoding column to df: {col}")
            dfii[col] = 0

    ## -- predict --
    if predict_proba:
        panel_prob = model.predict_proba(dfii[model.feature_names], check_input=True)
        panel_labels = model.classes_

        # random draw according to probability
        panel_prob_cum = np.cumsum(panel_prob, axis=1)
        random_nums_uniform = np.random.default_rng(seed=8).uniform(0,1, size=len(panel_prob))

        panel_amp = np.array([
            panel_labels[num<=arr][0] for num, arr in zip(random_nums_uniform, panel_prob_cum)
            ])
        
    else:
        panel_amp = model.predict(dfii[model.feature_names], check_input=True)
    df["predicted_panel_amp"] = df["building_id"].map(dict(zip(dfi["building_id"], panel_amp)))

    return df


def random_draw():
    num = np.random.default_rng().uniform(0,1)
    

def validate_model_with_dummy_data(model):
    df = pd.read_excel(local_dir / "model_input_example.xlsx", sheet_name="inputs", header=1)
    output = pd.read_excel(local_dir / "model_input_example.xlsx", sheet_name="outputs", dtype=str)

    # -- check predicted values against dummy data --
    panel_amp = model.predict(df[model.feature_names], check_input=True)
    check = panel_amp == np.array(output.iloc[:,0])
    assert len(check[check==False])==0, f"Predicted panel amperage does not match LBNL input and output dummy data: \n{check[check==False]}"
    print("Model validated against dummy data!")

def plot_output_saturation(df, output_dir, sfd_only=False):
    print(f"Plots output to: {output_dir}")
    cond = df["completed_status"] == "Success"
    if sfd_only:
        cond &= df["build_existing_model.geometry_building_type_recs"]=="Single-Family Detached"
        print(f"Plotting applies to {len(df.loc[cond])} valid Single-Family Detached samples only")
    else:
        print(f"Plotting applies to {len(df.loc[cond])} valid samples only")

    panel_metric = "predicted_panel_amp"
    _plot_bar(df, ["build_existing_model.census_region", panel_metric], output_dir=output_dir, sfd_only=sfd_only)
    _plot_bar(df, ["build_existing_model.federal_poverty_level", panel_metric], output_dir=output_dir, sfd_only=sfd_only)
    _plot_bar(df, ["build_existing_model.tenure", panel_metric], output_dir=output_dir, sfd_only=sfd_only)
    _plot_bar(df, ["build_existing_model.geometry_floor_area_bin", panel_metric], output_dir=output_dir, sfd_only=sfd_only)

    _plot_bar_stacked(df, ["build_existing_model.census_region", panel_metric], output_dir=output_dir, sfd_only=sfd_only)
    _plot_bar_stacked(df, ["build_existing_model.census_division", panel_metric], output_dir=output_dir, sfd_only=sfd_only)
    _plot_bar_stacked(df, ["build_existing_model.ashrae_iecc_climate_zone_2004", panel_metric], output_dir=output_dir, sfd_only=sfd_only)
    _plot_bar_stacked(df, ["build_existing_model.geometry_building_type_recs", panel_metric], output_dir=output_dir, sfd_only=sfd_only)
    _plot_bar_stacked(df, ["build_existing_model.vintage", panel_metric], output_dir=output_dir, sfd_only=sfd_only)
    _plot_bar_stacked(df, ["build_existing_model.federal_poverty_level", panel_metric], output_dir=output_dir, sfd_only=sfd_only)
    _plot_bar_stacked(df, ["build_existing_model.tenure", panel_metric], output_dir=output_dir, sfd_only=sfd_only)
    _plot_bar_stacked(df, ["build_existing_model.geometry_floor_area_bin", panel_metric], output_dir=output_dir, sfd_only=sfd_only)
    _plot_bar_stacked(df, ["build_existing_model.geometry_floor_area", panel_metric], output_dir=output_dir, sfd_only=sfd_only)

def _plot_bar(df, groupby_cols, output_dir=None, sfd_only=False):
    if sfd_only:
        cond = df["build_existing_model.geometry_building_type_recs"]=="Single-Family Detached"
        dfi = df.loc[cond, groupby_cols+["building_id"]]
    else:
         dfi = df[groupby_cols+["building_id"]]
    dfi = dfi.groupby(groupby_cols)["building_id"].count().unstack()

    fig, ax = plt.subplots()
    sort_index(sort_index(dfi, axis=0), axis=1).plot(kind="bar", ax=ax)
    if output_dir is not None:
        metric = "__by__".join(groupby_cols)
        fig.savefig(output_dir / f"bar_{metric}.png", dpi=400, bbox_inches="tight")

def _plot_bar_stacked(df, groupby_cols, output_dir=None, sfd_only=False):
    if sfd_only:
        cond = df["build_existing_model.geometry_building_type_recs"]=="Single-Family Detached"
        dfi = df.loc[cond, groupby_cols+["building_id"]]
    else:
         dfi = df[groupby_cols+["building_id"]]
    dfi = dfi.groupby(groupby_cols)["building_id"].count().unstack()
    dfi = dfi.divide(dfi.sum(axis=1), axis=0)

    fig, ax = plt.subplots()
    sort_index(sort_index(dfi, axis=0), axis=1).plot(kind="bar", stacked=True, ax=ax)
    ax.legend(loc='center left', bbox_to_anchor=(1, 0.5))
    ax.set_title(f"Saturation of {groupby_cols[-1]}")
    if output_dir is not None:
        metric = "__by__".join(groupby_cols)
        fig.savefig(output_dir / f"stacked_bar_{metric}.png", dpi=400, bbox_inches="tight")


def extract_left_edge(val):
    # for sorting things like AMI
    if val is None:
        return np.nan
    if not isinstance(val, str):
        return val
    first = val[0]
    if re.search(r"\d", val) or first in ["<", ">"] or first.isdigit():
        vals = [int(x) for x in re.split("\-|\%|\<|\+|\>|s|th|p|A|B|C", val) if re.match("\d", x)]
        if len(vals) > 0:
            num = vals[0]
            if "<" in val:
                num -= 1
            if ">" in val:
                num += 1
            return num
    return val

def sort_index(df, axis="index", **kwargs):
    """ axis: ['index', 'columns'] """
    if axis in [0, "index"]:
        return df.reindex(sorted(df.index, key=extract_left_edge, **kwargs))
    if axis in [1, "columns"]:
        col_index_name = df.columns.name
        cols = sorted(df.columns, key=extract_left_edge, **kwargs)
        df = df[cols]
        df.columns.name = col_index_name
        return df
    raise ValueError(f"axis={axis} is invalid")


def main(filename=None, predict_proba=False, plot_only=False, sfd_only=False):

    if filename is None:
        filename = local_dir / "test_data" / "euss1_2018_results_up00_100.csv"
    else:
        filename = Path(filename)

    ext = "__predicted_prob_panels" if predict_proba else "__predicted_panels"
    output_filename = filename.parent / (filename.stem + ext + filename.suffix)
    plot_dir_name = "plots_sfd" if sfd_only else "plots"
    output_dir = filename.parent / plot_dir_name
    output_dir.mkdir(parents=True, exist_ok=True)

    if plot_only:
        if not output_filename.exists():
            raise FileNotFoundError(f"Cannot create plots, output_filename not found: {output_filename}")
        df = pd.read_csv(output_filename, low_memory=False)
        plot_output_saturation(df, output_dir, sfd_only=sfd_only)
        sys.exit()

    df = pd.read_csv(filename)
    model = load_model()
    validate_model_with_dummy_data(model)
    df = apply_model_to_results(df, model, predict_proba=predict_proba)

    ## -- export --
    df.to_csv(output_filename, index=False)
    print(f"File output to: {output_filename}")

    ## -- plot --
    plot_output_saturation(df, output_dir, sfd_only=sfd_only)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "filename",
        action="store",
        default=None,
        nargs="?",
        help="Path to ResStock result file, e.g., results_up00.csv, "
        "defaults to test data: test_data/euss1_2018_results_up00_100.csv"
        )
    parser.add_argument(
        "-b",
        "--predict_proba",
        action="store_true",
        default=False,
        help="Whether to use model.predict_proba() tp predict probabilities of input samples",
    )
    parser.add_argument(
        "-p",
        "--plot_only",
        action="store_true",
        default=False,
        help="Make plots only based on expected output file",
    )
    parser.add_argument(
        "-d",
        "--sfd_only",
        action="store_true",
        default=False,
        help="Apply calculation to Single-Family Detached only (this is only on plotting for now)",
    )

    args = parser.parse_args()
    main(args.filename, predict_proba=args.predict_proba, plot_only=args.plot_only, sfd_only=args.sfd_only)
