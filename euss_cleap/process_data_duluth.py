# import packages
from pathlib import Path
import sys
import numpy as np
import pandas as pd
import csv
import re

baseline_file = Path("/Volumes/Lixi_Liu/cleap_dashboard_files/baseline_processed_duluth.csv")
data_dict_file = Path("/Users/lliu2/Documents/GitHub/ResStock/euss_cleap/data/data_dictionary.csv")

df = pd.read_csv(baseline_file)

# # customize
# cond = df["puma"] == "MN, 00500"
# df = df.loc[cond].reset_index(drop=True)

# n_units = 2000
# # 70% renters + 30% owners
# frac = 0.7
# cond = df["tenure"] == "Renter"
# df.loc[cond, "sample_weight"] = n_units*frac/len(df.loc[cond])

# frac = 0.3
# cond = df["tenure"] == "Owner"
# df.loc[cond, "sample_weight"] = n_units*frac/len(df.loc[cond])

# add new categories
df["air leakage"] = df["infiltration"].map({
	"1 ACH50": "<4 ACH50",
	"2 ACH50": "<4 ACH50",
	"3 ACH50": "<4 ACH50",
	"4 ACH50": "4-10 ACH50",
	"5 ACH50": "4-10 ACH50",
	"6 ACH50": "4-10 ACH50",
	"7 ACH50": "4-10 ACH50",
	"8 ACH50": "4-10 ACH50",
	"10 ACH50": "4-10 ACH50",
	"15 ACH50": "11-29 ACH50",
	"20 ACH50": "11-29 ACH50",
	"25 ACH50": "11-29 ACH50",
	"30 ACH50": "30+ ACH50",
	"40 ACH50": "30+ ACH50",
	"50 ACH50": "30+ ACH50",
	})

# # remap end uses into categories
# eu_map = pd.read_csv(data_dict_file)
# eu_map = eu_map.loc[eu_map["is_modeled"]=="Yes"]
# fuels = ["electricity", "natural_gas", "fuel_oil", "propane"]

# agg_cols = []
# for fuel in fuels:
#     cond = eu_map[fuel]=="Yes"
#     res_eu = eu_map.loc[cond, "annual_end_use"].to_list()
#     res_cat = eu_map.loc[cond, "fact_sheets_category"].to_list()

#     cols = [f"end_use_{fuel}_{eu}_m_btu" for eu in res_eu]
#     new_cols = [f"{fuel}_{eu}_m_btu" for eu in res_cat]
#     df = df.rename(columns=dict(zip(cols, new_cols)))
#     agg_cols += new_cols

# df = df.groupby(df.columns, axis=1).sum()

# # QC
# agg_cols = sorted(set(agg_cols))
# assert len(df.loc[df[agg_cols].isnull().any(axis=1)]) == 0, df.loc[df[agg_cols].isnull().any(axis=1)]

# save to file
output_file = Path("/Volumes/Lixi_Liu/cleap_dashboard_files/baseline_processed_duluth.csv")
df.to_csv(output_file, index=False)
print(f"Processed baseline data for Duluth: {str(output_file)}")


