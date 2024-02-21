from pathlib import Path
import argparse
import sys
import pickle
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
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


def create_input_tsv(model, dummy_data_file: Path, tsv_file: Path | None = None):
    """Create input tsv from model,
    Missing fields are handled by duplicating predictions from fields that are similar to the missing fields
    E.g., fuel oil and other fuels is copied from the combined results of non-electric fuels

    model : scikit-learn DecisionTree model

    """

    print("\nTransforming model into a ResStock input tsv file ...")
    ## -- process data to align with model inputs --
    input_options = {
        "Geometry Floor Area": [
            "0-499",
            "500-749",
            "750-999",
            "1000-1499",
            "1500-1999",
            "2000-2499",
            "2500-2999",
            "3000-3999",
            "4000+",
        ],
        "Geometry Building Type RECS": [
            "Mobile Home",
            "Multi-Family with 2 - 4 Units",
            "Multi-Family with 5+ Units",
            "Single-Family Attached",
            "Single-Family Detached",
        ],
        "HVAC Cooling Type": ["Central AC", "Heat Pump", "None", "Room AC"],  # old
        "Heating Fuel": [
            "Electricity",
            "Fuel Oil",
            "Natural Gas",
            "Other Fuel",
            "Propane",
            "None",
        ],  # old # has special_mapping
        "Water Heater Fuel": [
            "Electricity",
            "Fuel Oil",
            "Natural Gas",
            "Other Fuel",
            "Propane",
        ],  # has special_mapping
        "Cooking Range": [
            "Electric, 80% Usage",
            "Gas, 80% Usage",
            "Propane, 80% Usage",
            "Electric, 100% Usage",
            "Gas, 100% Usage",
            "Propane, 100% Usage",
            "Electric, 120% Usage",
            "Gas, 120% Usage",
            "Propane, 120% Usage",
            "None",
        ],  # old # has special_mapping
        "Clothes Dryer": [
            "Electric, 80% Usage",
            "Gas, 80% Usage",
            "Propane, 80% Usage",
            "Electric, 100% Usage",
            "Gas, 100% Usage",
            "Propane, 100% Usage",
            "Electric, 120% Usage",
            "Gas, 120% Usage",
            "Propane, 120% Usage",
            "None",
        ],  # old # has special_mapping
        "Vintage": [
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
        ],  # We do not have 2020s yet
    }

    if model.model_num == "10410":
        input_options.pop("Cooking Range", None)
        input_options.pop("Clothes Dryer", None)
        input_options = {
            **input_options,
            **{
                "Has PV": ["No", "Yes"],
            },
        }

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
        columns=["Geometry Floor Area", "Geometry Building Type RECS", "sqft"],
    )

    df = pd.DataFrame(
        data=itertools.product(*input_options.values()), columns=input_options.keys()
    )

    dfi = df.merge(df_fa, on=["Geometry Floor Area", "Geometry Building Type RECS"])

    if model.model_num == "16574":
        input_cols_map = {
            "sqft": "sqft",  # numeric
            "Geometry Building Type RECS": "geometry_building_type_recs",
            "HVAC Cooling Type": "hvac_cooling_type",
            "Heating Fuel": "heating_fuel_simp",
            "Water Heater Fuel": "water_heater_fuel_simp",
            "Vintage": "vintage",
            "Cooking Range": "cooking_range_simp",
            "Clothes Dryer": "clothes_dryer_simp",
        }
        expected_missing_cols = {}
    elif model.model_num == "16570":
        input_cols_map = {
            "sqft": "sqft",  # numeric
            "Geometry Building Type RECS": "geometry_building_type_recs",
            "HVAC Cooling Type": "hvac_cooling_type",
            "Heating Fuel": "heating_fuel",  # missing None
            "Water Heater Fuel": "water_heater_fuel",  # missing Fuel Oil, Other Fuel
            "Vintage": "vintage",
            "Cooking Range": "cooking_range",  # mapping 100% Usage to 80% and 120% Usage
            "Clothes Dryer": "clothes_dryer",  # mapping 100% Usage to 80% and 120% Usage
        }
        expected_missing_cols = {
            "water_heater_fuel__Other Fuel",
            "water_heater_fuel__Fuel Oil",
            "heating_fuel__None",
        }
    else:
        input_cols_map = {
            "sqft": "sqft",  # numeric
            "Geometry Building Type RECS": "geometry_building_type_recs",
            "HVAC Cooling Type": "hvac_cooling_type",
            "Heating Fuel": "heating_fuel",  # missing None
            "Water Heater Fuel": "water_heater_fuel",  # missing Fuel Oil, Other Fuel
            "Vintage": "vintage",
            "Has PV": "has_pv",
        }
        expected_missing_cols = {
            "water_heater_fuel__Other Fuel",
            "water_heater_fuel__Fuel Oil",
            "heating_fuel__None",
        }

    categorical_columns = list(input_cols_map.values())[1:]

    dfi = dfi[input_cols_map.keys()].rename(columns=input_cols_map)

    # special mapping for heating fuels:
    dfi = apply_special_mapping(dfi, model.model_num)

    dfi = pd.get_dummies(dfi, columns=categorical_columns, prefix_sep="__")
    delta = set(dfi.columns) - set(model.feature_names)
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
            dfi[col] = 0

    ## -- predict --
    panel_prob = model.predict_proba(dfi[model.feature_names])
    panel_labels = [f"Option={output_mapping[x]}" for x in model.classes_]

    ## -- combine --
    df = df.rename(columns=lambda x: f"Dependency={x}")
    dep_cols = df.columns.tolist()
    df[panel_labels] = panel_prob

    # df.to_csv(data_dir / "panel_1.csv") # TODO

    # [1] Combine bins
    # [1.1] Vintage: combine 2010s and 2020s into 2010s, use LBNL data to inform prevalence of 2010s vs. 2020s
    dfd = pd.read_excel(
        dummy_data_file, sheet_name=data_input_sheetname, header=0
    ).iloc[:, :-2]

    p2010s = dfd["vintage__2010s"].sum() / (
        dfd["vintage__2010s"].sum() + dfd["vintage__2020s"].sum()
    )
    df["weight"] = 1.0
    df.loc[df["Dependency=Vintage"] == "2010s", "weight"] = p2010s
    df.loc[df["Dependency=Vintage"] == "2020s", "weight"] = 1 - p2010s
    df.loc[df["Dependency=Vintage"] == "2020s", "Dependency=Vintage"] = "2010s"

    df[panel_labels] = df[panel_labels].mul(df["weight"], axis=0)
    df = df.groupby(dep_cols)[panel_labels].sum().reset_index()

    if (df[panel_labels].sum(axis=1).round(1) != 1).sum() > 0:
        print("Error in combining rows for Vintage")
        breakpoint()

    # df.to_csv(data_dir / "panel_2_after_vintage.csv") # TODO

    if model.model_num in ["10410", "16570"]:
        # [2.1] Heating Fuel (None = non-electric)
        hf_ne = [
            x
            for x in dfd.columns
            if x.startswith("heating_fuel")
            and not x.endswith("Electricity")
            and not x.endswith("nan")
        ]

        df_new = []
        for col in hf_ne:
            val = col.split("__")[1]
            if val == "Other":
                val = "Other Fuel"
            dfn = df.loc[df["Dependency=Heating Fuel"] == val].copy()
            assert len(dfn) > 0, "dfn is empty"
            dfn["weight"] = dfd[col].sum() / dfd[hf_ne].sum().sum()
            df_new.append(dfn)

        df_new = pd.concat(df_new, axis=0)
        df_new[panel_labels] = df_new[panel_labels].mul(df_new["weight"], axis=0)
        df_new["Dependency=Heating Fuel"] = "None"
        df_new = df_new.groupby(dep_cols)[panel_labels].sum().reset_index()

        if (df_new[panel_labels].sum(axis=1).round(1) != 1).sum() > 0:
            print("Error in duplicating rows for Heating Fuel")
            breakpoint()

        df = pd.concat(
            [df.loc[df["Dependency=Heating Fuel"] != "None"], df_new], axis=0
        )
        # df.to_csv(data_dir / "panel_3_after_heating_fuel.csv") # TODO

        # [2.2] Water Heater Fuel (Fuel Oil, Other Fuel = non-electric)
        whf_ne = [
            x
            for x in dfd.columns
            if x.startswith("water_heater_fuel")
            and not x.endswith("Electricity")
            and not x.endswith("nan")
        ]

        df_new = []
        for col in whf_ne:
            val = col.split("__")[1]
            if val == "Other":
                val = "Other Fuel"
            dfn = df.loc[df["Dependency=Water Heater Fuel"] == val].copy()
            dfn["weight"] = dfd[col].sum() / dfd[whf_ne].sum().sum()
            df_new.append(dfn)

        df_new = pd.concat(df_new, axis=0)
        df_new[panel_labels] = df_new[panel_labels].mul(df_new["weight"], axis=0)
        df_new["Dependency=Water Heater Fuel"] = "Fuel Oil"
        df_new = df_new.groupby(dep_cols)[panel_labels].sum().reset_index()

        if (df_new[panel_labels].sum(axis=1).round(1) != 1).sum() > 0:
            print("Error in duplicating rows for Water Heater Fuel")
            breakpoint()

        df_new2 = df_new.copy()
        df_new["Dependency=Water Heater Fuel"] = "Other Fuel"
        df = pd.concat(
            [
                df.loc[
                    ~df["Dependency=Water Heater Fuel"].isin(["Fuel Oil", "Other Fuel"])
                ],
                df_new,
                df_new2,
            ],
            axis=0,
        )
        # df.to_csv(data_dir / "panel_4_after_water_heater_fuel.csv") # TODO

    del dfd

    if (df[panel_labels].sum(axis=1).round(1) != 1).sum() > 0:
        print("Error in combining/duplicating rows for Electrical Panel Amp.tsv")
        breakpoint()

    # renormalize all probs so sum is closer to 1
    df[panel_labels] = df[panel_labels].div(df[panel_labels].sum(axis=1), axis=0)

    ## -- save to tsv file --
    if tsv_file is None:
        tsv_file = data_dir / f"Electrical Panel Amp - Model {model.model_num}.tsv"

    df.to_csv(tsv_file, sep="\t", index=False, lineterminator="\r\n")
    print(f"** Electrical Panel Amp TSV exported to: {tsv_file}")

    return df


def undummify_input_data(df: pd.DataFrame, input_options: dict):
    # undummy categorical columns
    cat_cols = [x for x in df.columns if x not in ["sqft", "dummy"]]
    dfd = undummify(df[cat_cols])

    # bin sqft
    para = "geometry_floor_area"
    bins = input_options["Geometry Floor Area"]
    bin_edges = [int(x.split("-")[0].split("+")[0]) for x in bins]
    dfd.loc[df["sqft"] >= bin_edges[-1], para] = bins[-1]
    for edge, label in zip(reversed(bin_edges[1:]), reversed(bins[:-1])):
        dfd.loc[df["sqft"] < edge, para] = label

    # remove "dummy" col - nothing to do

    return dfd


def undummify(df: pd.DataFrame, prefix_sep: str = "__"):
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


def apply_special_mapping(dfi: pd.DataFrame, model_num: str):
    if model_num == "16574":
        # for newer tsv
        dfi["heating_fuel_simp"] = dfi["heating_fuel_simp"].map(
            {
                "Electricity": "Electricity",
                "Fuel Oil": "non_Electricity",
                "Natural Gas": "non_Electricity",
                "Other Fuel": "non_Electricity",
                "Propane": "non_Electricity",
                "None": "non_Electricity",
            }
        )

        dfi["water_heater_fuel_simp"] = dfi["water_heater_fuel_simp"].map(
            {
                "Electricity": "Electricity",
                "Fuel Oil": "non_Electricity",
                "Natural Gas": "non_Electricity",
                "Other Fuel": "non_Electricity",
                "Propane": "non_Electricity",
            }
        )
        appliance_usage_map = {
            "Electric, 80% Usage": "Electric, 100% Usage",
            "Gas, 80% Usage": "non_Electricity",
            "Propane, 80% Usage": "non_Electricity",
            "Electric, 100% Usage": "Electric, 100% Usage",
            "Gas, 100% Usage": "non_Electricity",
            "Propane, 100% Usage": "non_Electricity",
            "Electric, 120% Usage": "Electric, 100% Usage",
            "Gas, 120% Usage": "non_Electricity",
            "Propane, 120% Usage": "non_Electricity",
            "None": "None",
        }

        dfi["clothes_dryer_simp"] = dfi["clothes_dryer_simp"].map(appliance_usage_map)
        dfi["cooking_range_simp"] = dfi["cooking_range_simp"].map(appliance_usage_map)
    else:
        dfi["heating_fuel"] = dfi["heating_fuel"].map(
            {
                "Electricity": "Electricity",
                "Fuel Oil": "Fuel Oil",
                "Natural Gas": "Natural Gas",
                "Other Fuel": "Other",
                "Propane": "Propane",
                "None": "None",
            }
        )
        if model_num == "16570":
            appliance_usage_map = {
                "Electric, 80% Usage": "Electric, 100% Usage",
                "Gas, 80% Usage": "Gas, 100% Usage",
                "Propane, 80% Usage": "Propane, 100% Usage",
                "Electric, 100% Usage": "Electric, 100% Usage",
                "Gas, 100% Usage": "Gas, 100% Usage",
                "Propane, 100% Usage": "Propane, 100% Usage",
                "Electric, 120% Usage": "Electric, 100% Usage",
                "Gas, 120% Usage": "Gas, 100% Usage",
                "Propane, 120% Usage": "Propane, 100% Usage",
                "None": "None",
            }
            dfi["clothes_dryer"] = dfi["clothes_dryer"].map(appliance_usage_map)
            dfi["cooking_range"] = dfi["cooking_range"].map(appliance_usage_map)

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

    return dfi


def apply_tsv_to_results(df: pd.DataFrame, tsv_file: Path, retain_proba: bool = False):
    """Apply tsv (derived from model) to ResStock result dataframe
    Args :
        df : pd.DataFrame
            dataframe of ResStock results_up00 file
        tsv_file : Path
            path to tsv_file
        retain_proba : bool
            if True, predicted output value is a distribution of output labels instead of a single label
            if False, predicted output value is a single label probablistically chosen based on output distribution
    """
    tsv = pd.read_csv(tsv_file, delimiter="\t", keep_default_na=False)

    dep_cols = [x for x in tsv.columns if x.startswith("Dependency=")]
    res_cols = [
        "build_existing_model."
        + x.removeprefix("Dependency=").lower().replace(" ", "_")
        for x in dep_cols
    ]
    option_cols = [x for x in tsv.columns if x.startswith("Option=")]
    panel_labels = [x.removeprefix("Option=") for x in option_cols]

    dff = df[res_cols].join(
        tsv.rename(
            columns=dict(zip(dep_cols + option_cols, res_cols + panel_labels))
        ).set_index(res_cols)[panel_labels],
        on=res_cols,
        how="left",
    )

    assert (
        dff[panel_labels].isna().sum().sum() == 0
    ), "Prediction in apply_tsv_to_results has NA values"

    if retain_proba:
        return pd.concat([df, dff[panel_labels]], axis=1)

    # random draw according to probability
    panel_prob_cum = np.cumsum(dff[panel_labels].values, axis=1)
    random_nums_uniform = np.random.default_rng(seed=8).uniform(0, 1, size=len(dff))
    panel_amp = np.array(
        [
            np.array(panel_labels)[num <= arr][0]
            for num, arr in zip(random_nums_uniform, panel_prob_cum)
        ]
    )
    panel_amp = pd.Series(panel_amp, index=dff.index).rename("predicted_panel_amp")
    return pd.concat([df, panel_amp], axis=1)


def apply_model_to_results(df: pd.DataFrame, model, retain_proba: bool = False):
    """Apply regression model to ResStock result dataframe
    Args :
        df : pd.DataFrame
            dataframe of ResStock results_up00 file
        model : scikit-learn DecisionTree model
            regression model
        retain_proba : bool
            only applicable when predict_proba=True
            if True, predicted output value is a distribution of output labels instead of a single label
            if False, predicted output value is a single label probablistically chosen based on output distribution
    """

    print("\nApplying model to results ...")
    ## -- process data to align with model inputs --
    input_cols_map = {
        "upgrade_costs.floor_area_conditioned_ft_2": "sqft",  # numeric
        "build_existing_model.geometry_building_type_recs": "geometry_building_type_recs",
        "build_existing_model.hvac_cooling_type": "hvac_cooling_type",
        "build_existing_model.heating_fuel": "heating_fuel",
        "build_existing_model.water_heater_fuel": "water_heater_fuel",
        "build_existing_model.cooking_range": "cooking_range",
        "build_existing_model.clothes_dryer": "clothes_dryer",
        "build_existing_model.vintage": "vintage",
    }

    categorical_columns = list(input_cols_map.values())[1:]

    cond = df["completed_status"] == "Success"
    if df.index.name == "building_id":
        dfi = df.loc[cond, list(input_cols_map.keys())].rename(columns=input_cols_map)
    else:
        dfi = (
            df.loc[cond, ["building_id"] + list(input_cols_map.keys())]
            .reset_index(drop=True)
            .rename(columns=input_cols_map)
        )

    # special mapping for heating fuels:
    dfi = apply_special_mapping(dfi, model.model_num)

    dfii = pd.get_dummies(dfi, columns=categorical_columns, prefix_sep="__")
    if "building_id" in dfii.columns:
        dfii = dfii.drop(columns=["building_id"])

    # add any missing cols
    for col in model.feature_names:
        if col not in dfii.columns:
            print(f" - adding dummy encoding column to df: {col}")
            dfii[col] = 0

    ## -- predict --
    panel_prob = model.predict_proba(dfii[model.feature_names])
    panel_labels = np.array([output_mapping[x] for x in model.classes_])

    if retain_proba:
        dfii = dfi[["building_id"]].copy()
        dfii[panel_labels] = panel_prob
        df = df.merge(dfii, on="building_id")

    # random draw according to probability
    panel_prob_cum = np.cumsum(panel_prob, axis=1)
    random_nums_uniform = np.random.default_rng(seed=8).uniform(
        0, 1, size=len(panel_prob)
    )

    panel_amp = np.array(
        [
            panel_labels[num <= arr][0]
            for num, arr in zip(random_nums_uniform, panel_prob_cum)
        ]
    )

    if df.index.name == "building_id":
        df = pd.concat(
            [df, pd.Series(panel_amp, index=dfi.index).rename("predicted_panel_amp")],
            axis=1,
        )
    else:
        df["predicted_panel_amp"] = df["building_id"].map(
            dict(zip(dfi["building_id"], panel_amp))
        )

    # replace with labels if not already
    df["predicted_panel_amp"] = df["predicted_panel_amp"].map(output_mapping)

    return df


def validate_model_with_dummy_data(model, raise_error: bool = False):
    df = pd.read_excel(dummy_data_file, sheet_name=data_input_sheetname, header=0)
    # drop last col, "truth" amperage
    df = df.iloc[:, :-2]
    output = pd.read_excel(dummy_data_file, sheet_name=data_output_sheetname)

    # -- check predicted values against dummy data --
    truth = np.array(output.iloc[:, 0])

    predicted = model.predict(df[model.feature_names])
    check = predicted == truth
    n_error = len(check[check == False])

    if n_error == 0:
        print("Model validated against dummy data!")
        return

    msg = f"{n_error} / {len(check)} ({n_error/len(check)*100:.2f} %) predicted panel amperage does not match LBNL input and output dummy data"

    df["expected"] = truth
    df["predicted"] = predicted
    df_error = df.loc[df["predicted"] != df["expected"]]
    df_error_file = data_dir / "check.csv"
    df_error.to_csv(df_error_file)
    msg2 = f"Dataframe subset with discrepancy is exported to: {df_error_file}"

    if raise_error:
        raise ValueError(msg + "\n" + msg2)
    else:
        print(f"Error caught but not raised:\n{msg}\n{msg2}")


def extract_left_edge(val):
    # for sorting things like AMI
    if val is None:
        return np.nan
    if not isinstance(val, str):
        return val
    first = val[0]
    if re.search(r"\d", val) or first in ["<", ">"] or first.isdigit():
        vals = [
            int(x)
            for x in re.split("\-| |\%|\<|\+|\>|s|th|p|A|B|C| ", val)
            if re.match("\d", x)
        ]
        if len(vals) > 0:
            num = vals[0]
            if "<" in val:
                num -= 1
            if ">" in val:
                num += 1
            return num
    return val


def sort_index(df: pd.DataFrame, axis: str = "index", **kwargs):
    """axis: ['index', 'columns']"""
    if axis in [0, "index"]:
        try:
            df = df.reindex(sorted(df.index, key=extract_left_edge, **kwargs))
        except TypeError:
            df = df.reindex(sorted(df.index, **kwargs))
        return df

    if axis in [1, "columns"]:
        col_index_name = df.columns.name
        try:
            cols = sorted(df.columns, key=extract_left_edge, **kwargs)
        except TypeError:
            cols = sorted(df.columns, **kwargs)
        df = df[cols]
        df.columns.name = col_index_name
        return df
    raise ValueError(f"axis={axis} is invalid")


def plot_output_saturation(
    df: pd.DataFrame, output_dir: Path, panel_metrics: list[str], sfd_only=False
):
    print(f"Plots output to: {output_dir}")
    cond = df["completed_status"] == "Success"
    if sfd_only:
        cond &= (
            df["build_existing_model.geometry_building_type_recs"]
            == "Single-Family Detached"
        )
        df = df.loc[cond]
        print(
            f"Plotting applies to {len(df)} valid Single-Family Detached samples only"
        )
    else:
        df = df.loc[cond]
        print(f"Plotting applies to {len(df)} valid samples only")

    for hc in [
        "build_existing_model.census_region",
        "build_existing_model.federal_poverty_level",
        "build_existing_model.area_median_income",
        "build_existing_model.geometry_floor_area_bin",
        "build_existing_model.geometry_building_type_recs",
        "build_existing_model.vintage",
    ]:
        _plot_bar(df, [hc], panel_metrics, output_dir=output_dir)

    for hc in [
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
    ]:
        _plot_bar_stacked(df, [hc], panel_metrics, output_dir=output_dir)

    _plot_bar_stacked(
        df,
        ["build_existing_model.vintage", "build_existing_model.geometry_floor_area"],
        panel_metrics,
        output_dir=output_dir,
    )
    _plot_bar_stacked(
        df,
        [
            "build_existing_model.census_region",
            "build_existing_model.geometry_building_type_recs",
        ],
        panel_metrics,
        output_dir=output_dir,
    )


def _plot_bar(
    df: pd.DataFrame,
    groupby_cols: list[str],
    metric_cols: list[str],
    output_dir: Path | None = None,
):
    if "predicted_panel_amp" in metric_cols:
        dfi = df[groupby_cols + metric_cols + ["building_id"]]
        dfi = dfi.groupby(groupby_cols + metric_cols)["building_id"].count().unstack()
    else:
        dfi = df.groupby(groupby_cols)[metric_cols].sum()
        metric_cols = ["predicted_panel_amp_expected_value"]
    dfi = sort_index(sort_index(dfi, axis=0), axis=1)

    fig, ax = plt.subplots()
    dfi.plot(kind="bar", ax=ax)
    if output_dir is not None:
        metric_cols
        metric = "__by__".join(groupby_cols + metric_cols)
        fig.savefig(output_dir / f"bar_{metric}.png", dpi=400, bbox_inches="tight")
        dfi.to_csv(output_dir / f"data__bar_{metric}.csv", index=True)
    plt.close()


def _plot_bar_stacked(
    df: pd.DataFrame,
    groupby_cols: list[str],
    metric_cols: list[str],
    output_dir: Path | None = None,
):
    if "predicted_panel_amp" in metric_cols:
        dfi = df[groupby_cols + metric_cols + ["building_id"]]
        dfi = dfi.groupby(groupby_cols + metric_cols)["building_id"].count().unstack()
    else:
        dfi = df.groupby(groupby_cols)[metric_cols].sum()
        metric_cols = ["predicted_panel_amp_expected_value"]

    dfi = dfi.divide(dfi.sum(axis=1), axis=0)
    dfi = sort_index(sort_index(dfi, axis=0), axis=1)

    fig, ax = plt.subplots()
    dfi.plot(kind="bar", stacked=True, ax=ax)
    ax.legend(loc="center left", bbox_to_anchor=(1, 0.5))
    ax.set_title(f"Saturation of {metric_cols[0]}")
    if output_dir is not None:
        metric = "__by__".join(groupby_cols + metric_cols)
        fig.savefig(
            output_dir / f"stacked_bar_{metric}.png", dpi=400, bbox_inches="tight"
        )
        dfi.to_csv(output_dir / f"data__stacked_bar_{metric}.csv", index=True)
    plt.close()


def read_file(filename: Path, low_memory: bool = True, **kwargs):
    """If file is large, use low_memory=False"""
    filename = Path(filename)
    if filename.suffix == ".csv":
        df = pd.read_csv(
            filename, low_memory=low_memory, keep_default_na=False, **kwargs
        )
    elif filename.suffix == ".parquet":
        df = pd.read_parquet(filename, **kwargs)
    else:
        raise TypeError(f"Unsupported file type, cannot read file: {filename}")
    return df


def get_model_parameters(model):
    output_mapping = {
        0: "100",
        1: "101-199",
        2: "200",
        3: "201+",
        4: "<100",  # "lt_100",
    }
    if model == "16574":
        # Original bins, no upsampling of electric heating
        model_filename = "final_panel_model_rank_test_custom_delta_v2_16574.p"
    elif model == "16570":
        # Original bins, no upsampling of electric heating
        model_filename = "final_panel_model_rank_test_f1_weighted_16570.p"
    elif model == "10410":
        # Original bins, no upsampling of electric heating
        model_filename = "final_panel_model_rank_test_custom_delta_v2_10410.p"
    else:
        raise ValueError(f"Unknown model={model}, valid: [16574, 10410, 16570]")

    data_input_sheetname = f"input_{model}"
    data_output_sheetname = f"output_{model}"

    return model_filename, data_input_sheetname, data_output_sheetname, output_mapping


def main(
    filename: str | None = None,
    retain_proba: bool = False,
    validate_model: bool = False,
    plot_only: bool = False,
    sfd_only: bool = False,
    predict_using_model: bool = False,
):
    global local_dir, data_dir, dummy_data_file, data_input_sheetname, data_output_sheetname, output_mapping

    local_dir = Path(__file__).resolve().parent
    data_dir = local_dir / "model_20240122"

    if filename is None:
        filename = local_dir / "test_data" / "euss1_2018_results_up00_100.csv"
    else:
        filename = Path(filename)

    # Model specs
    model_num = "16570"  # <-- [16574, 10410, 16570 (best)]
    (
        model_filename,
        data_input_sheetname,
        data_output_sheetname,
        output_mapping,
    ) = get_model_parameters(model_num)

    model_file = data_dir / model_filename
    dummy_data_file = data_dir / f"model_data_{model_num}.xlsx"
    tsv_file = data_dir / f"Electrical Panel Amp - Model {model_num}.tsv"

    msg = "Default: Probabilistic prediction based on distribution of labels"
    if retain_proba:
        msg = "Prediction as a distribution of labels"

    if predict_using_model:
        fp = "model_based"
        msg2 = "Prediction using model (CAUTION! model does not contain all predictor combinations, suggest using default: prediction using tsv)"
    else:
        fp = "tsv_based"
        msg2 = "Default: Prediction using tsv"

    print(
        f"""
        ===============================================
        Predict panel capacity using MODEL {model_num}
        - {msg}
        - {msg2}
        ===============================================
        """
    )

    panel_metrics = ["predicted_panel_amp"]
    if retain_proba:
        panel_metrics = list(output_mapping.values())

    ext = f"model_{model_num}__{fp}__predicted_panels_probablistically_assigned"
    if retain_proba:
        ext = f"model_{model_num}__{fp}__predicted_panels_in_probability"

    output_filename = filename.parent / (filename.stem + "__" + ext + ".csv")
    plot_dir_name = "plots_sfd" if sfd_only else "plots"
    output_dir = filename.parent / plot_dir_name / ext
    output_dir.mkdir(parents=True, exist_ok=True)

    # If plotting only
    if plot_only:
        print(
            f"Plotting output {panel_metrics} only, using output_filename: {output_filename}"
        )
        if not output_filename.exists():
            raise FileNotFoundError(
                f"Cannot create plots, output_filename not found: {output_filename}, "
                "try running command without -p flag to create the file first"
            )
        df = pd.read_csv(output_filename, low_memory=False, keep_default_na=False)
        plot_output_saturation(df, output_dir, panel_metrics, sfd_only=sfd_only)
        sys.exit()

    # Prediction
    if predict_using_model or not tsv_file.exists():
        # Load model
        feature_names = pd.read_excel(
            dummy_data_file, sheet_name=data_input_sheetname, header=0, nrows=0
        ).columns.tolist()[:-2]
        model = load_model(model_file, feature_names)
        model.model_num = model_num
        validate_model_with_dummy_data(model, raise_error=validate_model)

        create_input_tsv(model, dummy_data_file, tsv_file=tsv_file)

    df = read_file(filename, low_memory=False)
    if predict_using_model:
        print(
            "CAUTION! model does not contain all predictor combinations, suggest using default: prediction using tsv"
        )
        df = apply_model_to_results(
            df, model, retain_proba=retain_proba
        )  # do not have all combos
    else:
        df = apply_tsv_to_results(df, tsv_file, retain_proba=retain_proba)

    ## -- export --
    df.to_csv(output_filename, index=False)
    print(f"File output to: {output_filename}")

    ## -- plot --
    plot_output_saturation(df, output_dir, panel_metrics, sfd_only=sfd_only)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "filename",
        action="store",
        default=None,
        nargs="?",
        help="Path to ResStock result file, e.g., results_up00.csv, "
        "defaults to test data: test_data/euss1_2018_results_up00_100.csv",
    )
    parser.add_argument(
        "-r",
        "--retain_proba",
        action="store_true",
        default=False,
        help="If true, output is retained as a probablistic distribution of all output labels "
        "and saturation plots give the expected saturation of output. "
        "Default is one output label per dwelling unit, PROBABLISTICALLY assigned.",
    )
    parser.add_argument(
        "-v",
        "--validate_model",
        action="store_true",
        default=False,
        help="Whether to raise error if caught when validating model with LBNL supplied input data",
    )
    parser.add_argument(
        "-p",
        "--plot_only",
        action="store_true",
        default=False,
        help="Make plots only based on expected output file without regenerating output file",
    )
    parser.add_argument(
        "-d",
        "--sfd_only",
        action="store_true",
        default=False,
        help="Apply calculation to Single-Family Detached only (this is only on plotting for now)",
    )
    parser.add_argument(
        "-m",
        "--predict_using_model",
        action="store_true",
        default=False,
        help="Whether to predict using model, note: model does not have all predictor combinations and "
        "will result in slightly different prediction. Default to predict using tsv, which contains full combinations",
    )

    args = parser.parse_args()
    main(
        args.filename,
        retain_proba=args.retain_proba,
        validate_model=args.validate_model,
        plot_only=args.plot_only,
        sfd_only=args.sfd_only,
        predict_using_model=args.predict_using_model,
    )
