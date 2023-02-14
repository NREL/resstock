"""
Create mapping from ResStock geography to 2010 American Indian Areas (Tribal Nations)
Author: Lixi.Liu@nrel.gov
Date: 10/20/2022

"""

# import packages
from pathlib import Path
import numpy as np
import pandas as pd

data_dir = Path(__file__).resolve().parent / "data"


resstock_geo = "PUMA"  # name of geography in resstock <--- "PUMA", County and PUMA"

if resstock_geo == "PUMA":
    geography = ["puma_tsv", "nhgis_2010_puma_gisjoin"]
    renamed_geography = [resstock_geo, "PUMA_nhgis"]
elif resstock_geo == "County and PUMA":
    geography = ["county_and_puma"]
    renamed_geography = [resstock_geo]
else:
    raise ValueError(f"resstock_geo={resstock_geo} unsupported")
print(
    f"Creating mapping from ResStock  {resstock_geo}  to 2010 American Indian Areas..."
)

## [1] Spatial tract lookup - 2010
filename = Path("spatial_tract_lookup_table.csv")
tract_map = pd.read_csv(data_dir / filename, low_memory=False)
assert (
    len(tract_map) == tract_map["nhgis_2010_tract_gisjoin"].nunique()
), f"nhgis_2010_tract_gisjoin col in {filename.stem} is not unique"

# [1.2] Get percent housing unit in tract relative to selected geography, or percent housing in geography that belongs tract
tract_map = tract_map.set_index(geography + ["nhgis_2010_tract_gisjoin"])
tract_map["percent_hu"] = (
    tract_map["housing_units"]
    .divide(tract_map.groupby(geography)["housing_units"].sum())
    .reindex(tract_map.index)
)
tract_map = tract_map.reset_index()

tract_map["statefp"] = tract_map["nhgis_2010_tract_gisjoin"].apply(
    lambda x: int(x[1:3])
)
state_map = (
    tract_map[["statefp", "state_abbreviation"]]
    .drop_duplicates()
    .set_index("statefp")["state_abbreviation"]
)


## [2] 2010 Census Tract to American Indian Area Relationship File:
# https://www.census.gov/programs-surveys/geography/technical-documentation/records-layout/2000-tract-to-aia-record-layout.html
# "PERCENT_HU": percent housing unit in tract that belongs to AIA
tract_aia = pd.read_csv(data_dir / "2010_tract_to_aia.csv")
print(f" - total housing units in AIA (truth): {tract_aia['HUINT'].sum()}")
aia_with_units = len(
    tract_aia.loc[tract_aia["HUINT"] > 0][["STATEFP", "NAME"]].drop_duplicates()
)
print(f" - # of AIA with housing units (truth): {aia_with_units}")

tract_aia["State"] = tract_aia["STATEFP"].map(state_map)
# in csv =CONCAT("G",TEXT(A2,"00"),"0",TEXT(B2,"000"),"0",TEXT(C2,"000000"))
tract_aia["nhgis_2010_tract_gisjoin"] = (
    "G"
    + tract_aia["STATEFP"].astype(str).str.zfill(2)
    + "0"
    + tract_aia["COUNTYFP"].astype(str).str.zfill(3)
    + "0"
    + tract_aia["TRACTCE"].astype(str).str.zfill(6)
)

## Adjust known geography changes from 2010 to 2015:
# https://www.census.gov/programs-surveys/acs/technical-documentation/table-and-geography-changes/2015/geography-changes.html
tract_aia["nhgis_2010_tract_gisjoin"] = tract_aia["nhgis_2010_tract_gisjoin"].replace(
    {
        # Shannon County (113) -> Oglala Lakota County (102), SD (46)
        "G4601130940500": "G4601020940500",
        "G4601130940800": "G4601020940800",
        "G4601130940900": "G4601020940900",
        # Wade Hampton Census Area (270) -> Kusilvak Census Area (158), AK (02)
        "G0202700000100": "G0201580000100",
    }
)
# Can't find geography change for "G3600530940103": Oneida city, Madison County, NY
# http://www.usa.com/NY053940103.html --> small (11) HU count, so okay to remove
tract_aia = tract_aia[
    tract_aia["nhgis_2010_tract_gisjoin"] != "G3600530940103"
].reset_index(drop=True)

# QC
tract_delta = set(tract_aia["nhgis_2010_tract_gisjoin"]) - set(
    tract_map["nhgis_2010_tract_gisjoin"]
)
assert (
    len(tract_delta) == 0
), f"AIA crosswalk contains tracts not in {filename.stem}:\n{tract_delta}"


# [3] Join two mappings, retaining only relevant tracts
tract_joined = tract_map[
    ["nhgis_2010_tract_gisjoin"] + geography + ["county_name", "percent_hu"]
].join(
    tract_aia.set_index("nhgis_2010_tract_gisjoin"),
    on="nhgis_2010_tract_gisjoin",
    how="right",
)

# QC
tract_delta = set(tract_aia["nhgis_2010_tract_gisjoin"].unique()) - set(
    tract_joined.loc[~tract_joined["PERCENT_HU"].isna(), "nhgis_2010_tract_gisjoin"]
)
assert (
    len(tract_delta) == 0
), f"Mapping join incorrect, these tribal-occupied tracts are missing in joined table:\n{tract_delta}"

# [4] Combine multiplers to get mapping from selected geography to AIA
# "percent_hu": percent housing in selected geography that belongs AIA
geography_to_aia = (
    tract_joined.groupby(geography + ["AIANNHCE", "NAME", "State"])
    .apply(lambda x: (x["percent_hu"] * x["PERCENT_HU"]).sum())
    .rename("percent_hu")
    .to_frame()
    .reset_index()
    .rename(columns=dict(zip(geography, renamed_geography)))
)


# [5] Optional - Add sampling_probability
opt_sat = pd.read_csv(data_dir / "options_saturations.csv")
opt_sat = opt_sat[opt_sat["Parameter"] == resstock_geo].set_index("Option")[
    "Saturation"
]
geography_to_aia["sampling_probability"] = geography_to_aia[resstock_geo].map(opt_sat)


# Save to file
label = resstock_geo.lower().replace(" ", "_")
output_filename = f"2010_derived_map_{label}_to_aia.csv"
geography_to_aia.to_csv(data_dir / output_filename, index=False)


# [6] Optional - Create saturation by AIA:
print("Estimating housing unit count for AIA based on mapping created...")
n_buildings_represented = 136569411  # American Community Survey 2019 5-year, B25001, does not include AK, HI, and territories

df = (
    (
        geography_to_aia.groupby(["AIANNHCE", "NAME", "State"]).apply(
            lambda x: (x["sampling_probability"] * x["percent_hu"]).sum()
        )
        * n_buildings_represented
    )
    .rename("housing_units")
    .to_frame()
    .reset_index()
)

print("Without AK and HI, ")
print(f" - total housing units in AIA (mapped): {df['housing_units'].sum()}")
print(f" - # of AIA with housing units (mapped): {len(df[df['housing_units']>0])}")

output_filename = f"2010_derived_housing_unit_count_for_aia_based_on_{label}.csv"
df.to_csv(data_dir / output_filename, index=False)
