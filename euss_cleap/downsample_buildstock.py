# import packages
from pathlib import Path
import sys
import numpy as np
import pandas as pd
import csv
import re
import networkx as nx

from utils.sampling_probability import level_calc


def downselect_buildstock(bst_to_match, bst_to_search, HC_to_match=None, HC_to_search=None, n=1000):
    """ downselect buildings in bst_to_search based on bst_to_match 
    by matching the list of HC_to_match as much as possible

    If multiple matches are possible, a random draw takes place

    Args :
        bst_to_match : pd.DataFrame
            builstock to match to
        bst_to_search : pd.DataFrame
            buildstock or simulated results to search from
        HC_to_match : list(str)
            list of housing characteristics to match to, order-dependent
            items in the list need to match columns in bst_to_match
        HC_to_search : list(str)
            list of housing characteristics corresponding to HC_to_match
            that would be available as columns in bst_to_search
            Optional, if None, HC_to_search = HC_to_match

    Returns : 
        DF : a subset of bst_to_search based on matching criteria
    """
    if HC_to_match is None:
    	HC_to_match = [col for col in bst_to_match.columns if col != "Building"]
    if HC_to_search is None:
        HC_to_search = HC_to_match

    # QC
    assert len(set(HC_to_match)) == len(set(HC_to_search)), "Mismatch in length between HC_to_match and HC_to_search"

    diff = set(HC_to_match)-set(bst_to_match.columns)
    assert diff == set(), f"Unknown {len(diff)} parameter(s) found: {diff}"

    diff = set(HC_to_search)-set(bst_to_search.columns)
    assert diff == set(), f"Unknown {len(diff)} parameter(s) found: {diff}"

    print(
        f"Creating n={n} buildlstock by downsampling from a database buildstock with {len(bst_to_search)} samples\n"
    )

    weight_map = bst_to_search[["Building"]]
    weight = pd.Series(1, index=weight_map.index)
    for hcm, hcs in zip(HC_to_match, HC_to_search):
    	weight *= modulate_weight(bst_to_match, bst_to_search, hcm, hcs)

    weight_map = weight_map.assign(weight= weight)

    cond = weight_map["weight"]>0
    if cond.sum() == 0:
    	print("--- WARNING: Cannot downsample bst_to_search with positive weight ---")
    	wt_matrix = []
    	for hcm, hcs in zip(HC_to_match, HC_to_search):
    		wt_matrix.append(modulate_weight(bst_to_match, bst_to_search, hcm, hcs).rename(hcm))
    	wt_matrix = pd.concat(wt_matrix, axis=1)
    	n_zero = wt_matrix[wt_matrix==0].replace(0,1).sum(axis=1)
    	n_zero.value_counts()
    	wt_matrix.loc[n_zero==1]
    	wt_matrix.loc[666][wt_matrix.loc[666]==0]
    	# idx = n_zero==0
    	# wt_matrix.loc[idx].sum(axis=0)
    	# (wt_matrix.loc[idx].div(wt_matrix.loc[idx].sum(axis=0), axis=1)).product(axis=1)
    	print()
    	breakpoint()
    else:
    	print(f"--- Located {cond.sum()} rows in bst_to_search with positive weight ---")

    # recalculate weight based on first round of downselection
    weight = pd.Series(1, index=cond[cond].index)
    for hcm, hcs in zip(HC_to_match, HC_to_search):
    	weight *= modulate_weight(bst_to_match, bst_to_search.loc[cond], hcm, hcs)

    # normalize to n
    weight = weight / weight.sum() * n

    weight_map.loc[cond, "weight"] = weight
    weight_map_downselect = weight_map.loc[cond]
    
    breakpoint()

    
    return weight_map_downselect


def modulate_weight(dfm, dfs, hcm, hcs):
	""" Normalize housing characteristic (HC) in df_to_search based on prevalence of the HC in df_to_match

	Args:
		dfm : pd.DataFrame
			dataframe to match to
		dfs : pd.DataFrame
			dataframe to search and calculate weight for
		hcm : str
			name of housing characteristic in dfm
		hcs : str
			name of housing characteristic in dfs

	Returns:
		weight : pd.Series
		normalized weight of housing characteristic such that it sums to len(dfs), indexed to dfs
	"""
	df = dfm.copy()
	if diff := list(set(df[hcm].unique()) - set(dfs[hcs].unique())):
		print(f"- WARNING: For hc={hcm}, dfm has {len(diff)} extra keys not in dfs, removing those keys...")
		print(f"    E.g., {diff[:min(3, len(diff))]}")

		df = df.loc[~df[hcm].isin(diff)]
		print(f"  Remaining {df[hcm].nunique()} keys: ")
		print(f"    E.g., {df[hcm].unique()[:min(3, df[hcm].nunique())]}")

	wt_map = df[hcm].value_counts().sort_index() / len(df) # normalized to 1
	denom = dfs[hcs].value_counts().sort_index()

	denom = denom[wt_map.index]
	if len(denom[wt_map.index]) == 0:
		print(f"No overlap in hc={hcm} keys between dfm and dfs: {wt_map.index} vs. {denom.index}")
		breakpoint()
		# raise KeyError(f"No overlap in hc={hcm} keys between dfm and dfs: {wt_map.index} vs. {denom.index}")
	
	wt_map = wt_map / denom * len(dfs) # weight such that after mapping, sum of weight = len(dfs)
	weight = dfs[hcs].map(wt_map).fillna(0)

	assert round(weight.sum()) == len(dfs), "sum of weight != len(dfs)"

	return weight

# --- Main ---

# new buildstock
# buildstock_to_match = Path("/Users/lliu2/Documents/GitHub/ResStock/euss_cleap/data/buildstock-duluth.csv")  # <---
# df_match = pd.read_csv(buildstock_to_match, dtype=str)

# EUSS buildstock
buildstock_database = Path("/Users/lliu2/Documents/Lab Call 5A - electrical panel constraints/FY23/Panels Estimation/euss1_buildstock.csv")
df_main = pd.read_csv(buildstock_database, dtype=str)#, low_memory=False)

df_match = df_main.loc[df_main["PUMA"]=="MN, 00500"].reset_index(drop=True)

hc = "PUMA"
project_national_path = Path("/Users/lliu2/Documents/GitHub/ResStock/project_national/housing_characteristics")
graph = level_calc(project_national_path)
# HC = [hc] + sorted(nx.descendants(graph, hc))
HC = [hc] + list(graph.successors(hc))

Geography = [
]

# HC = [
# 	"ASHRAE IECC Climate Zone 2004 - 2A Split", # n=18
# 	"ASHRAE IECC Climate Zone 2004", # n=17
# 	"Building America Climate Zone", # n=8
# 	"CEC Climate Zone", # n=16
#     "State",
#     "Geometry Building Type RECS",
#     "Heating Fuel",
#     "HVAC Heating Type",
#     "Water Heater Fuel",
#     "Clothes Dryer",  # has usage
#     "Cooking Range",  # has usage
#     "Misc Gas Fireplace",
#     "Misc Gas Grill",
#     "Misc Gas Lighting",
#     "Geometry Floor Area",
#     "Geometry Wall Type",
#     "Vintage",
#     "Insulation Wall",
#     "Infiltration",
#     "Occupants",
#     "Windows",
#     "Usage Level",
#     "Plug Load Diversity",
#     "HVAC Heating Efficiency",
#     "Water Heater Efficiency",
#     "HVAC Cooling Efficiency",
#     "Hot Water Fixtures",
#     "PUMA Metro Status",
#     "Geometry Foundation Type",
#     "Geometry Stories",
# ]

# 1. downselect EUSS results
euss_hc = [f"in.{x.lower().replace(' ', '_')}" for x in HC]
dfd = downselect_buildstock(df_match, df_main, HC_to_match=HC, HC_to_search=HC)

# save to file
output_file = buildstock_database.parent / (
    buildstock_database.stem + f"__downsampled" + results_to_sample.suffix
)
dfd.to_csv(output_file, index=False)
print(f"Database down-selected result output to: {output_file}\n")


