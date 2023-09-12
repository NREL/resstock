"""
This script is used to find the most "representative" or "typical"
buildings from EUSS 1.0 annual summary file for a given set of selection criteria

Use cases: find the representative electrically heated home in Maine from EUSS

By: Lixi.Liu@nrel.gov
Date: 09/12/2023
Updated: 
"""
import pandas as pd
from pathlib import Path
import re
from itertools import chain



def format_hc(hc):
    if isinstance(hc, list):
        return ["_".join([x for x in chain(*[re.split('(\d+)',x) for x in y.lower().split(" ")]) if x not in ["", "-"]]) for y in hc]
    elif isinstance(hc, str):
        return "_".join([x for x in chain(*[re.split('(\d+)',x) for x in hc.lower().split(" ")]) if x not in ["", "-"]])
    raise NotImplementedError(f"Input for format_hc() has type: {type(hc)} and is not supported")

def convert_to_oedi_format(hc):
    hc = format_hc(hc)
    if isinstance(hc, list):
        return [f"in.{x}" for x in hc]
    elif isinstance(hc, str):
        return f"in.{hc}"

def convert_to_internal_format(hc):
    hc = format_hc(hc)
    if isinstance(hc, list):
        return [f"build_existing_model.{x}" for x in hc]
    elif isinstance(hc, str):
        return f"build_existing_model.{hc}"

def validate_file_type(file_type):
    accepted_file_types = ['buildstock', 'internal_dataset', 'oedi_dataset']
    if file_type not in accepted_file_types:
        raise ValueError(f"Unsupported file_type={file_type}, valid: {accepted_file_types}")

def get_building_column(file_type):
    if file_type == "buildstock":
        return "Building"
    if file_type == "internal_dataset":
        return "building_id"
    if file_type == "oedi_dataset":
        return "building_id"

def format_downselection(downselection, file_type):
    if file_type == "buildstock":
        return downselection
    if file_type == "internal_dataset":
        return {convert_to_internal_format(key): val for key, val in downselection.items()}
    if file_type == "oedi_dataset":
        return {convert_to_oedi_format(key): val for key, val in downselection.items()}

def apply_downselection(euss_bl, downselection, file_type):
    validate_file_type(file_type)
    downselection = format_downselection(downselection, file_type)

    condition = None
    for key, val in downselection.items():
        if isinstance(val, list):
            cond = euss_bl[key].isin(val)
        else:
            cond = euss_bl[key]==val
        if condition is None:
            condition = cond
        else:
            condition &= cond

    euss_bl = euss_bl.loc[condition].reset_index(drop=True)

    return euss_bl

def get_housing_characteristics_list(euss_bl, file_type):
    if file_type == "buildstock":
        HC = [x for x in euss_bl.columns if x != get_building_column(file_type)]

    if file_type == "internal_dataset":
        HC = [x for x in euss_bl.columns if x.startswith("build_existing_model.")]
        not_HC = ["applicable", "weather_file", "weather_file", "emissions", "sample_weight", "simulation_control"]
        for hc in not_HC:
            HC = [x for x in HC if hc not in x]
    if file_type == "oedi_dataset":
        HC = [x for x in euss_bl.columns if x.startswith("in.")]
        # TODO: remove not_HC
    return HC

def extract_common_housing_characteristics(euss_bl, file_type):
    """ 
    Note: hc_list can have repeated hc if there are more than 1 most-common field value for that hc
    returns:
        hc_list: list of housing characteristics from euss_bl
        common_hc: list of most-common field value for each hc in hc_list
    """
    HC = get_housing_characteristics_list(euss_bl, file_type)

    # Extract all most common features from euss_bl
    # if there are more than 1 most common, repeat hc
    hc_list, common_hc = [], []
    for hc in HC:
        vals = euss_bl[hc].value_counts()
        common_vals = (vals[vals == vals.values[0]]).index.to_list()
        common_hc += common_vals
        hc_list += [hc for x in common_vals]

    return hc_list, common_hc
    


# Load EUSS results
results_to_sample = Path("/Users/lliu2/Documents/Documents_Files/Lab Call 5A - electrical panel constraints/FY23/Panels Estimation/euss1_2018_results_up00.parquet")  # <---
euss_bl = pd.read_parquet(results_to_sample)
file_type = "internal_dataset"

# Specify downselection
downselection = {
    "State": ["ME"],
    "Heating Fuel": ["Electricity"]
}

downselected_euss_bl = apply_downselection(euss_bl, downselection, file_type)
hc_list, common_hc = extract_common_housing_characteristics(downselected_euss_bl, file_type)

# Do matching
matched = []
for hc, val in zip(hc_list, common_hc):
    matched.append(downselected_euss_bl[hc]==val)
matched = pd.concat(matched, axis=1).sum(axis=1).sort_values(ascending=False)

# get all building_ids with the most matches
best_matched = (matched[matched == matched.values[0]]).index.to_list()
best_matched_euss_bl = downselected_euss_bl.loc[best_matched]

# How to handle if there are more than 1:

breakpoint()


