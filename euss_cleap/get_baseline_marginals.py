# import packages
from pathlib import Path
import sys
import numpy as np
import pandas as pd
import csv
import re
import math
from itertools import chain


community_name = "hill_district" # <---

data_dir = Path(".").resolve() / "data_" / "community_building_samples_with_upgrade_cost_and_bill" / community_name 
file  = data_dir / f"up00__{community_name}.parquet"

df = pd.read_parquet(file)

hc_dir = Path(".").resolve().parents[0] / "project_national" / "housing_characteristics"
hc = [x.stem for x in hc_dir.rglob("*.tsv")]
hc = ["_".join([x for x in chain(*[re.split('(\d+)',x) for x in y.lower().split(" ")]) if x not in ["", "-"]]) for y in hc]
hc = [f"build_existing_model.{x}" for x in hc]

# -- prefilters --
cond = df["build_existing_model.geometry_wall_type"].isin(["Brick", "Concrete"])
cond &= df["build_existing_model.vintage"]=="<1940"
cond &= df["build_existing_model.area_median_income"].isin(["0-30%", "30-60%", "60-80%"])

df = df.loc[cond, hc+["sample_weight"]].reset_index(drop=True)

# -- get marginals --
DF = []
for i, x in enumerate(hc,1):
	hc_name = x.removeprefix("build_existing_model.")
	vals = (df.groupby([x])["sample_weight"].sum() / df["sample_weight"].sum()).sort_index()
	vals = vals.rename("Saturation").to_frame()
	vals.index.name = "Option"
	vals = vals.reset_index()
	vals["Parameter"] = hc_name
	vals["Index"] = i
	DF.append(vals)

DF = pd.concat(DF, axis=0)
DF = DF[["Index", "Parameter", "Option", "Saturation"]]
DF.to_csv(data_dir / "baseline_housing_characteristics_saturations.csv", index=False)
