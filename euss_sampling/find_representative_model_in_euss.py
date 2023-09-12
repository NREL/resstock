"""
This script is used to find the most "representative" or "typical"
buildings from EUSS 1.0 annual summary file for a given set of selection criteria

Use cases: find the representative electrically heated home in Maine from EUSS

By: Lixi.Liu@nrel.gov
Date: 09/12/2023
Updated: 
"""
import getpass
from pathlib import Path
import re
from itertools import chain
import json
import numpy as np
import pandas as pd



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

def get_housing_characteristics_list(euss_bl, file_type, return_count=False):
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
    if return_count:
        return len(HC)
    return HC


def get_must_match_housing_characteristcs(file_type):
    must_match_hc = [
        "State",
        "ASHRAE IECC Climate Zone 2004",
        "Geometry Building Type RECS",
        "Vintage ACS",
        "Geometry Floor Area Bin",
        "Heating Fuel",
        "Geometry Wall Type",
        "Water Heater Fuel",
        "HVAC Heating Type",
        "HVAC Cooling Type",
    ]
    if file_type == "internal_dataset":
        must_match_hc = convert_to_internal_format(must_match_hc)
    if file_type == "oedi_dataset":
        must_match_hc = convert_to_oedi_format(must_match_hc)
    return must_match_hc

def check_must_match_housing_characteristcs(matched, file_type):
    """ matched: pd.Series """
    must_match_hc = get_must_match_housing_characteristcs(file_type)
    matched_hc = matched.replace(False, np.nan).dropna().index

    must_match_matched = sorted(set(must_match_hc).intersection(set(matched_hc)))
    must_match_missed = sorted(set(must_match_hc)-set(matched_hc))
    print(f" - id: {matched.name} matched {len(must_match_matched)} / {len(must_match_hc)} must-match housing characteristics")
    if len(must_match_missed) > 0: 
        print(f"   but not matching: {must_match_missed}")

    return must_match_matched, must_match_missed


def extract_common_housing_characteristics(euss_bl, file_type):
    """ 
    Note: hc_list can have repeated hc if there are more than 1 most-common field value for that hc
    returns:
        hc_list: list 
            list of housing characteristics from euss_bl
        common_hc: list 
            most-common field value for each hc in hc_list
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

def extract_must_match_common_housing_characteristics(euss_bl, must_match_hc):
    """ 
    returns:
        must_match_common_hc: list 
            most-common field value for each hc in must_match_hc
    """
    must_match_common_hc = []
    for hc in must_match_hc:
        vals = euss_bl[hc].value_counts()
        common_vals = (vals[vals == vals.values[0]]).index.to_list()
        must_match_common_hc += common_vals

    return must_match_common_hc


def get_common_values_of(selected_hc, hc_list, common_hc):
    return [common_hc[hc_list.index(x)] for x in selected_hc]


def get_most_matched_buildings(downselected_euss_bl, hc_list, common_hc):
    """ Search within downselected_euss_bl for the list of building(s) matching
    the most common_hc

    Args:
        downselected_euss_bl: pd.DataFrame
            input result to search
        hc_list: list 
            list of housing characteristics to search (not guarenteed to be unique)
        common_hc: list
            most-common field value for each hc in hc_list

    Returns:
        best_matched_euss_bl: pd.DataFrame
            result for most-matched building(s)
        match_meet_criteria: bool
            whether the matched building(s) match all must-match housing characteristics
    """
    matched = []
    for hc, val in zip(hc_list, common_hc):
        matched.append(downselected_euss_bl[hc]==val)
    matched = pd.concat(matched, axis=1)
    total_matched = matched.sum(axis=1).sort_values(ascending=False)

    # get all building_ids with the most matches
    max_matched_count = total_matched.values[0]
    best_matched_idx = (total_matched[total_matched == max_matched_count]).index.to_list()
    best_matched_euss_bl = downselected_euss_bl.loc[best_matched_idx]

    # check 
    print(f"Using result_file: {result_file}")
    print(f"and downselection criteria:")
    print(json.dumps(downselection, indent=4, sort_keys=True))
    print(f"The best matched {bldg_id}s are: {best_matched_idx}, with ")
    print(f"each matching {max_matched_count} / {get_housing_characteristics_list(euss_bl, file_type, return_count=True)} housing characteristics")
    # print(matched.loc[best_matched_idx].replace(False, np.nan).dropna(how="all", axis=1).transpose())
    to_keep = []
    for idx, row in matched.loc[best_matched_idx].iterrows():
        must_match_matched, must_match_missed = check_must_match_housing_characteristcs(row, file_type)
        if must_match_missed:
            common_values_missed = get_common_values_of(must_match_missed, hc_list, common_hc)
            print(best_matched_euss_bl.loc[row.name, must_match_missed])
            print(f"These must-match field values should be: {common_values_missed}")
        else:
            to_keep.append(row.name)

    if to_keep:
        best_matched_euss_bl.loc[to_keep]
        match_meet_criteria = True
        print(f"\n** Final best matched {bldg_id}s meeting must-match criteria are: {to_keep}")
        print("Note: if there are more than 1 best-matched, pick one randomly as the 'most representative'")
    else:
        match_meet_criteria = False
        print(f"\n * No best matched {bldg_id}s meeting must-match criteria found, returning initial best-matched results based on match count")
        
    return best_matched_euss_bl, match_meet_criteria

def get_must_matched_buildings(downselected_euss_bl, must_match_hc, must_match_common_hc):
    """ Search within downselected_euss_bl for the list of building(s) matching
    all common_hc

    Args:
        downselected_euss_bl: pd.DataFrame
            input result to search
        must_match_hc: list 
            list of housing characteristics to search (must match)
        must_match_common_hc: list
            most-common field value for each hc in hc_list

    Returns:
        must_matched_euss_bl: pd.DataFrame
            result for must-matched building(s)
    """
    matched = []
    for hc, val in zip(must_match_hc, must_match_common_hc):
        matched.append(downselected_euss_bl[hc]==val)
    matched = pd.concat(matched, axis=1)
    total_matched = matched.sum(axis=1).sort_values(ascending=False)

    # get all building_ids with the most matches
    max_matched_count = total_matched.values[0]
    best_matched_idx = (total_matched[total_matched == max_matched_count]).index.to_list()
    must_matched_euss_bl = downselected_euss_bl.loc[best_matched_idx]

    return must_matched_euss_bl
    

# Load EUSS results
if getpass.getuser() == "lliu2":
    result_file = Path("/Users/lliu2/Documents/Documents_Files/Lab Call 5A - electrical panel constraints/FY23/Panels Estimation/euss1_2018_results_up00.parquet")
    file_type = "internal_dataset"
elif getpass.getuser() == "ylou2":
    result_file = Path("../euss_cleap/data_/euss_res_final_2018_550k_20220901/results_up00.parquet")
    file_type = "internal_dataset"
else:
    raise ValueError("need to specify result_file path")

euss_bl = pd.read_parquet(result_file)

# Specify downselection
downselection = {
    "State": ["ME"],
    "Heating Fuel": ["Electricity"]
}

bldg_id = get_building_column(file_type)
downselected_euss_bl = apply_downselection(euss_bl, downselection, file_type).set_index(bldg_id)
hc_list, common_hc = extract_common_housing_characteristics(downselected_euss_bl, file_type)

# Get the most-common field value for each hc in must_match_hc
must_match_hc = get_must_match_housing_characteristcs(file_type)
must_match_common_hc = extract_must_match_common_housing_characteristics(downselected_euss_bl, must_match_hc)
# Do matching
must_matched_euss_bl = get_must_matched_buildings(downselected_euss_bl, must_match_hc, must_match_common_hc)
best_matched_euss_bl, match_meet_criteria = get_most_matched_buildings(must_matched_euss_bl, hc_list, common_hc)

# TODO: new method that prioritizes must_match hc first
breakpoint()


