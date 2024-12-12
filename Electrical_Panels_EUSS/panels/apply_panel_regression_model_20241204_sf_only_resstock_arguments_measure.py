""" Process 7-bins decision tree model for integration into ResStockArguments
updated: 10/22/24
Predictive capacity model numbers from LBNL (SMurphy@lbl.gov):
LBNL model numbers:
  - 134078: for electric heating homes, 8 inputs -> 7 binned outputs
  - 238518: for non-electric heating homes, 3 inputs -> 7 binned outputs
"""
from pathlib import Path
import pickle
import pandas as pd
import numpy as np
import re
import itertools


def load_model(model_file: Path, feature_names: list[str] | None = None):
    model = pickle.load(open(model_file, "rb"))
    # model.get_params()

    model.feature_names = model.get_booster().feature_names
    if model.feature_names is None and feature_names is not None:
        model.feature_names = feature_names

    assert set(model.classes_) == set(
        output_mapping.keys()
    ), f"mismatch between model.classes_ and output_mapping: \n{model.classes_} vs. {output_mapping.keys()}"

    return model


def yield_floor_area_dataframe():
    # https://github.com/NREL/resstock/blob/develop/measures/ResStockArguments/measure.rb
    df_fa = pd.DataFrame(
        data=[
            ("0-499", "Mobile Home", 298),
            ("0-499", "Single-Family Detached", 298),
            ("0-499", "Single-Family Attached", 273),
            ("0-499", "Multi-Family with 2 - 4 Units", 322),
            ("0-499", "Multi-Family with 5+ Units", 322),
            ("500-749", "Mobile Home", 634),
            ("500-749", "Single-Family Detached", 634),
            ("500-749", "Single-Family Attached", 625),
            ("500-749", "Multi-Family with 2 - 4 Units", 623),
            ("500-749", "Multi-Family with 5+ Units", 623),
            ("750-999", "Mobile Home", 881),
            ("750-999", "Single-Family Detached", 881),
            ("750-999", "Single-Family Attached", 872),
            ("750-999", "Multi-Family with 2 - 4 Units", 854),
            ("750-999", "Multi-Family with 5+ Units", 854),
            ("1000-1499", "Mobile Home", 1228),
            ("1000-1499", "Single-Family Detached", 1228),
            ("1000-1499", "Single-Family Attached", 1207),
            ("1000-1499", "Multi-Family with 2 - 4 Units", 1138),
            ("1000-1499", "Multi-Family with 5+ Units", 1138),
            ("1500-1999", "Mobile Home", 1698),
            ("1500-1999", "Single-Family Detached", 1698),
            ("1500-1999", "Single-Family Attached", 1678),
            ("1500-1999", "Multi-Family with 2 - 4 Units", 1682),
            ("1500-1999", "Multi-Family with 5+ Units", 1682),
            ("2000-2499", "Mobile Home", 2179),
            ("2000-2499", "Single-Family Detached", 2179),
            ("2000-2499", "Single-Family Attached", 2152),
            ("2000-2499", "Multi-Family with 2 - 4 Units", 2115),
            ("2000-2499", "Multi-Family with 5+ Units", 2115),
            ("2500-2999", "Mobile Home", 2678),
            ("2500-2999", "Single-Family Detached", 2678),
            ("2500-2999", "Single-Family Attached", 2663),
            ("2500-2999", "Multi-Family with 2 - 4 Units", 2648),
            ("2500-2999", "Multi-Family with 5+ Units", 2648),
            ("3000-3999", "Mobile Home", 3310),
            ("3000-3999", "Single-Family Detached", 3310),
            ("3000-3999", "Single-Family Attached", 3228),
            ("3000-3999", "Multi-Family with 2 - 4 Units", 3171),
            ("3000-3999", "Multi-Family with 5+ Units", 3171),
            ("4000+", "Mobile Home", 5587),
            ("4000+", "Single-Family Detached", 5587),
            ("4000+", "Single-Family Attached", 7414),
            ("4000+", "Multi-Family with 2 - 4 Units", 6348),
            ("4000+", "Multi-Family with 5+ Units", 6348),
        ],
        columns=["geometry_unit_cfa_bin", "geometry_building_type_recs", "sqft"],
    )
    df_fa["geometry_building_type_recs"] = df_fa["geometry_building_type_recs"].map({
        "Mobile Home": "manufactured home",
        "Single-Family Detached": "single-family detached",
        "Single-Family Attached": "single-family attached",
        "Multi-Family with 2 - 4 Units": "apartment unit, 2-4",
        "Multi-Family with 5+ Units": "apartment unit, 5+",
    })
    return df_fa


def yield_input_options(hc_list=None):
    input_options = {
        "geometry_unit_cfa_bin": [
            "0-499",
            "500-749",
            "750-999",
            "1000-1499",
            "1500-1999",
            "2000-2499",
            "2500-2999",
            "3000-3999",
            "4000+",
        ], # all HPXML values
        "geometry_building_type_recs": [
            # "manufactured home", # HPXML value
            # "apartment unit, 2-4",
            # "apartment unit, 5+",
            "single-family detached", # HPXML value
            "single-family attached", # HPXML value
        ],
        "vintage": [
            "<1940",
            "1940s",
            "1950s",
            "1960s",
            "1970s",
            "1980s",
            "1990s",
            "2000s",
            "2010s",
            "2020s",
        ],  # We do not have 2020s yet, lumping with 2010s
        "hvac_cooling_type": [
            "central air conditioner", # HPXML value
            "room air conditioner", # HPXML value
            "heat pump", 
            "none",
        ],
        "clothes_dryer": [
            "electricity", # HPXML value
            "non-electricity",
            "none",
        ],
        "water_heater_fuel_type": [
            "electricity", # HPXML value
            "non-electricity",
        ],
        "cooking_range": [
            "electricity",  # HPXML value
            "non-electricity",
            "none",
        ],
    }

    if hc_list is None:
        return input_options

    return {k: v for k, v in input_options.items() if k in hc_list}


def create_distribution_electric_heating(model, dummy_file):

    print("\n-- Panel bin distribution for ELECTRIC heating fuel -- ")
    ## -- process data to align with model inputs --
    input_options = yield_input_options(hc_list=None)

    df_fa = yield_floor_area_dataframe()
    df = pd.DataFrame(
        data=itertools.product(*input_options.values()), columns=input_options.keys()
    )

    dfi = df.merge(df_fa, on=["geometry_unit_cfa_bin", "geometry_building_type_recs"])

    expected_missing_cols = set()
    input_cols_map = {
        "sqft": "sqft",  # numeric
        "geometry_building_type_recs": "geometry_building_type_recs",
        "vintage": "vintage",
        "hvac_cooling_type": "hvac_cooling_type",
        "clothes_dryer": "clothes_dryer_simp",
        "water_heater_fuel_type": "water_heater_fuel_simp",
        "cooking_range": "cooking_range_simp",
    }
    categorical_columns = list(input_cols_map.values())[1:]

    dfi = dfi[input_cols_map.keys()].rename(columns=input_cols_map)

    # special mapping for heating fuels:
    dfi = apply_special_mapping(dfi, "electric")

    dfi = pd.get_dummies(dfi, columns=categorical_columns, prefix_sep="__")
    delta = set(dfi.columns) - set(model.feature_names)

    if len(delta) != 0:
        if delta != expected_missing_cols:
            print(f"Expecting missing cols from model input data: {expected_missing_cols} ")
            print(f"but found these missing cols instead: {delta}")
            breakpoint()
        assert delta == expected_missing_cols, (
            f"Expecting missing cols from model input data: {expected_missing_cols}, "
            f"but found these missing cols instead: {delta}"
        )
    # add any missing cols
    for col in model.feature_names:
        if col not in dfi.columns:
            print(f" - adding dummy encoding column to df: {col}")
            dfi[col] = 1

    ## -- predict --
    panel_prob = model.predict_proba(dfi[model.feature_names])
    panel_labels = [output_mapping[x] for x in model.classes_]

    ## -- combine --
    df = df.rename(columns=lambda x: f"Dependency={x}")
    dep_cols = sorted(df.columns.tolist())
    df[panel_labels] = panel_prob

    # [1] Combine bins
    # [1.1] Vintage: combine 2010s and 2020s into 2010s, use LBNL data to inform prevalence of 2010s vs. 2020s
    dfd = pd.read_csv(dummy_file, header=0).iloc[:, :-2]

    p2010s = dfd["vintage__2010s"].sum() / (
        dfd["vintage__2010s"].sum() + dfd["vintage__2020s"].sum()
    )
    df["weight"] = 1.0
    df.loc[df["Dependency=vintage"] == "2010s", "weight"] = p2010s
    df.loc[df["Dependency=vintage"] == "2020s", "weight"] = 1 - p2010s
    df.loc[df["Dependency=vintage"] == "2020s", "Dependency=vintage"] = "2010s"

    df[panel_labels] = df[panel_labels].mul(df["weight"], axis=0)
    df = df.groupby(dep_cols)[panel_labels].sum().reset_index()

    assert (df[panel_labels].sum(axis=1).round(1) != 1).sum() == 0, "Error in combining rows for vintage"
    del dfd

    # renormalize all probs so sum is closer to 1
    df[panel_labels] = df[panel_labels].div(df[panel_labels].sum(axis=1), axis=0).round(6)

    # save intermediate tsv    
    csv_file = data_dir / f"electrical_panel_rated_capacity__single_family_electric_heating.csv"
    df.to_csv(csv_file, index=False)


def create_distribution_nonelectric_heating(model, dummy_file):

    print("\n-- Panel bin distribution for NON-ELECTRIC heating fuel --")
    ## -- process data to align with model inputs --
    hc_list = ["geometry_unit_cfa_bin", "geometry_building_type_recs", "vintage"]
    input_options = yield_input_options(hc_list=hc_list)

    df_fa = yield_floor_area_dataframe()
    df = pd.DataFrame(
        data=itertools.product(*input_options.values()), columns=input_options.keys()
    )

    dfi = df.merge(df_fa, on=["geometry_unit_cfa_bin", "geometry_building_type_recs"])

    input_cols_map = {
        "sqft": "sqft",  # numeric
        "geometry_building_type_recs": "geometry_building_type_recs_simp",
        "vintage": "vintage",
    }
    expected_missing_cols = set()

    categorical_columns = list(input_cols_map.values())[1:]

    dfi = dfi[input_cols_map.keys()].rename(columns=input_cols_map)

    # special mapping for heating fuels:
    dfi = apply_special_mapping(dfi, "non_electric")

    dfi = pd.get_dummies(dfi, columns=categorical_columns, prefix_sep="__")
    delta = set(dfi.columns) - set(model.feature_names)
    assert delta == expected_missing_cols, (
        f"Expecting missing cols from model input data: {expected_missing_cols}, "
        f"but found these missing cols instead: {delta}"
    )
    # add any missing cols
    for col in model.feature_names:
        if col not in dfi.columns:
            print(f" - adding dummy encoding column to df: {col}")
            dfi[col] = 0

    ## -- predict --
    panel_prob = model.predict_proba(dfi[model.feature_names])
    panel_labels = [output_mapping[x] for x in model.classes_]

    ## -- combine --
    df = df.rename(columns=lambda x: f"Dependency={x}")
    dep_cols = sorted(df.columns.tolist())
    df[panel_labels] = panel_prob

    # [1] Combine bins
    # [1.1] Vintage: combine 2010s and 2020s into 2010s, use LBNL data to inform prevalence of 2010s vs. 2020s
    dfd = pd.read_csv(dummy_file, header=0).iloc[:, :-2]

    p2010s = dfd["vintage__2010s"].sum() / (
        dfd["vintage__2010s"].sum() + dfd["vintage__2020s"].sum()
    )
    df["weight"] = 1.0
    df.loc[df["Dependency=vintage"] == "2010s", "weight"] = p2010s
    df.loc[df["Dependency=vintage"] == "2020s", "weight"] = 1 - p2010s
    df.loc[df["Dependency=vintage"] == "2020s", "Dependency=vintage"] = "2010s"

    df[panel_labels] = df[panel_labels].mul(df["weight"], axis=0)
    df = df.groupby(dep_cols)[panel_labels].sum().reset_index()

    assert (df[panel_labels].sum(axis=1).round(1) != 1).sum() == 0, "Error in combining rows for vintage"
    del dfd

    # renormalize all probs so sum is closer to 1
    df[panel_labels] = df[panel_labels].div(df[panel_labels].sum(axis=1), axis=0).round(6)

    # save intermediate tsv    
    csv_file = data_dir / f"electrical_panel_rated_capacity__single_family_nonelectric_heating.csv"
    df.to_csv(csv_file, index=False)


def apply_special_mapping(dfi: pd.DataFrame, model_type: str) -> pd.DataFrame:
    """ translate resstock argument options to model input options """

    dfi["vintage"] = dfi["vintage"].map(
        dict(
            zip(
                [
                    "<1940",
                    "1940s",
                    "1950s",
                    "1960s",
                    "1970s",
                    "1980s",
                    "1990s",
                    "2000s",
                    "2010s",
                    "2020s",
                ],
                [
                    "lt_1940",
                    "1940s",
                    "1950s",
                    "1960s",
                    "1970s",
                    "1980s",
                    "1990s",
                    "2000s",
                    "2010s",
                    "2020s",
                ],
            )
        )
    )
    if model_type == "non_electric":
        dfi["geometry_building_type_recs_simp"] = dfi["geometry_building_type_recs_simp"].map(
            {
                "manufactured home": "Mobile Home",
                "apartment unit, 2-4": "Multi-Family with 2 - 4 Units",
                "apartment unit, 5+": "Multi-Family with 5+ Units",
                "single-family attached": "Single-Family",
                "single-family detached": "Single-Family",
            }
        )
    else:
        dfi["geometry_building_type_recs"] = dfi["geometry_building_type_recs"].map(
            {
                "manufactured home": "Mobile Home",
                "apartment unit, 2-4": "Multi-Family with 2 - 4 Units",
                "apartment unit, 5+": "Multi-Family with 5+ Units",
                "single-family attached": "Single-Family Attached",
                "single-family detached": "Single-Family Detached",
            }
        )
        dfi["water_heater_fuel_simp"] = dfi["water_heater_fuel_simp"].map(
            {
                "electricity": "Electricity",
                "non-electricity": "non_Electricity",
            }
        )
        dfi["hvac_cooling_type"] = dfi["hvac_cooling_type"].map(
            {
                "central air conditioner": "Central AC",
                "heat pump": "Heat Pump",
                "none": "None",
                "room air conditioner": "Room AC",
            }
        )
        dfi["clothes_dryer_simp"] = dfi["clothes_dryer_simp"].map(
            {
                "electricity": "Electric, 100% Usage",
                "non-electricity": "non_Electricity",
                "none": "None",
            }
        )
        dfi["cooking_range_simp"] = dfi["cooking_range_simp"].map(
            {
                "electricity": "Electric, 100% Usage",
                "non-electricity": "non_Electricity",
                "none": "None",
            }
        )

    return dfi


def get_representative_value_for_bin(dummy_file):
    def mode(df, *args, **kwargs):
        return df.mode(*args, **kwargs)

    df = pd.read_csv(dummy_file)
    input_options = yield_input_options()
    df = undummify_input_data(df, input_options)

    df = df.rename(columns={
        "panel_amp_pre_bin_7": "panel_bin",
        "panel_amp_pre": "panel_value",
        })
    df.loc[df["panel_bin"] == "lt_100", "panel_bin"] = "<100"

    # Get distribution of discrete values
    dfi = df.groupby(["panel_bin", "panel_value"])["vintage"].count().rename("count").to_frame().reset_index()
    dfi["fraction"] = dfi.groupby(["panel_bin"])["count"].transform(lambda x: x/x.sum())
    dfi.to_csv(dummy_file.parent / "weighted_standardized_panel_bin_values.csv", index=False)

    # Get agg values of bins by floor area
    bins = [x for x in df["panel_bin"].unique() if "-" in x or "+" in x or "<" in x]
    dfi2 = df.loc[df["panel_bin"].isin(bins)].groupby(
        ["panel_bin", "geometry_unit_cfa_bin"])["panel_value"].agg(["mean", "median", mode, "count"])
    print(f"\nFor {dummy_file.parent.stem}")
    print(dfi2)
    dfi2.to_csv(dummy_file.parent / "by_floor_area_panel_bin_values.csv", index=True)


def undummify_input_data(df: pd.DataFrame, input_options: dict) -> pd.DataFrame:
    # undummy categorical columns
    cat_cols = [x for x in df.columns if x not in ["sqft", "dummy"] or "Unnamed" in x]
    dfd = undummify(df[cat_cols])

    # bin sqft
    para = "geometry_unit_cfa_bin"
    bins = input_options["geometry_unit_cfa_bin"]
    bin_edges = [int(x.split("-")[0].split("+")[0]) for x in bins]
    dfd.loc[df["sqft"] >= bin_edges[-1], para] = bins[-1]
    for edge, label in zip(reversed(bin_edges[1:]), reversed(bins[:-1])):
        dfd.loc[df["sqft"] < edge, para] = label

    return dfd


def undummify(df: pd.DataFrame, prefix_sep: str = "__") -> pd.DataFrame:
    cols2collapse = {
        item.split(prefix_sep)[0]: (prefix_sep in item) for item in df.columns
    }
    series_list = []
    for col, needs_to_collapse in cols2collapse.items():
        if needs_to_collapse:
            undummified = (
                df.filter(like=col)
                .idxmax(axis=1)
                .apply(lambda x: x.split(prefix_sep, maxsplit=1)[1])
                .rename(col)
            )
            series_list.append(undummified)
        else:
            series_list.append(df[col])
    undummified_df = pd.concat(series_list, axis=1)

    return undummified_df


def main():
    global local_dir, data_dir, output_filedir, output_mapping

    local_dir = Path(__file__).resolve().parent
    data_dir = local_dir / "models_20241204_sf_only"

    # Model specs
    output_mapping = {
        0: "100",
        1: "101-124",
        2: "125",
        3: "126-199",
        4: "200", 
        5: "201+",
        6: "<100",  # "lt_100",
    }

    model_file_e = data_dir / "panel_capacity_elec_heat" / "final_panel_model_rank_test_f1_weighted_730046.p"
    dummy_file_e = data_dir / "panel_capacity_elec_heat" / "train_data_with_continuous_panel_amp_730046.csv"
    model_file_ne = data_dir / "panel_capacity_non_elec_heat" / "final_panel_model_rank_test_f1_weighted_822198.p"
    dummy_file_ne = data_dir / "panel_capacity_non_elec_heat" / "train_data_with_continuous_panel_amp_822198.csv"

    # Load model
    feature_names = pd.read_csv(
        dummy_file_e, header=0, nrows=0
    ).columns.tolist()[:-2]
    model_e = load_model(model_file_e, feature_names)
    model_ne = load_model(model_file_ne, feature_names)

    # Generate distributions
    create_distribution_electric_heating(model_e, dummy_file_e)
    create_distribution_nonelectric_heating(model_ne, dummy_file_ne)

    # Calculate representative values
    all_data_file_e = data_dir / "panel_capacity_elec_heat" / "all_data_with_continuous_panel_amp_730046.csv"
    all_data_file_ne = data_dir / "panel_capacity_non_elec_heat" / "all_data_with_continuous_panel_amp_822198.csv"
    get_representative_value_for_bin(all_data_file_e)
    get_representative_value_for_bin(all_data_file_ne)

    print("Electrical panel rated capacity distributions generated.")


if __name__ == "__main__":
    main()
