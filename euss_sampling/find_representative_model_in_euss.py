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

def format_downselection(downselection, file_type):
    if file_type == "buildstock":
        return downselection
    elif file_type == "internal_dataset":
        return {convert_to_internal_format(key): val for key, val in downselection.items()}
    elif file_type == "oedi_dataset":
        return {convert_to_oedi_format(key): val for key, val in downselection.items()}
    else:
        raise ValueError(f"Unsupported file_type={file_type}, valid: ['buildstock', 'internal_dataset', 'oedi_dataset']")

def apply_downselection(euss_bl, downselection, file_type):
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
    

# EUSS results, with in.<> and out.<> columns
results_to_sample = Path("/Users/lliu2/Documents/Documents_Files/Lab Call 5A - electrical panel constraints/FY23/Panels Estimation/euss1_2018_results_up00.parquet")  # <---
euss_bl = pd.read_parquet(results_to_sample)
file_type = "internal_dataset"

downselection = {
    "State": ["ME"],
    "Heating Fuel": ["Electricity"]
}
downselected_euss_bl = apply_downselection(euss_bl, downselection, file_type)

breakpoint()


