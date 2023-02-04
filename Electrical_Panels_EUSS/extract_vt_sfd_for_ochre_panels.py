"""
Electrical Panel Project: support controls simulation in OCHRE
Downselect 20 (occupied) SFD in VT from EUSS 1.0, using newly sampled buildstock for VT containing:

- 5 homes with electric heating fuel
- 15 homes with non-electric heating fuel

By: Lixi.Liu@nrel.gov
Date: 02/03/2023
"""
import pandas as pd
from pathlib import Path

buildstock_to_match = Path("/Users/lliu2/Downloads/buildstock-vt-20.csv")  # <---
vt_bst = pd.read_csv(buildstock_to_match)

results_to_sample = Path("/Users/lliu2/Downloads/euss_baseline-vt.csv")  # <---
euss_bl = pd.read_csv(results_to_sample)

HC = [
    "Geometry Building Type RECS",
    "Heating Fuel",
    "Water Heater Fuel",
    "Clothes Dryer",  # has usage
    "Cooking Range",  # has usage
    "Geometry Floor Area",
    "Geometry Wall Type",
    "Vintage",
    "Insulation Wall",
    "Infiltration",
    "Occupants",
    "Windows",
    "Usage Level",
    "Plug Load Diversity",
    "HVAC Heating Efficiency",
    "Water Heater Efficiency",
    "HVAC Cooling Efficiency",
    "Hot Water Fixtures",
    "PUMA Metro Status",
    "Geometry Foundation Type",
    "Geometry Stories",
]

euss_hc = [f"in.{x.lower().replace(' ', '_')}" for x in HC]

# QC
for hc, ehc in zip(HC, euss_hc):
    assert hc in vt_bst.columns
    assert ehc in euss_bl.columns

print(
    f"Sampling {len(vt_bst)} rows from: {results_to_sample} \n"
    f"to match buildstock: {buildstock_to_match}..."
)

DF = []
for i, row in vt_bst.iterrows():
    df = euss_bl.copy()
    bhc = "None"  # housing char before
    n = 0
    for hc, ehc in zip(HC, euss_hc):
        cond = euss_bl[ehc] == row[hc]

        if hc in ["Clothes Dryer", "Cooking Range"]:
            # match fuel type only
            val = row[hc].split(",")[0]
            cond = euss_bl[ehc].str.startswith(val)

        df2 = df.loc[cond, :]
        if len(df2) < 1:
            hc = bhc
            break
        df = df2
        bhc = hc
        n += 1

    print(
        f"Row {i+1} in buildstock matches {len(df)} sample(s) in EUSS after matching {n} HC(s) up to: {hc}"
    )
    # randomly select 1
    DF.append(df.sample(1, random_state=9))

DF = pd.concat(DF, axis=0, ignore_index=True)

# save to file
output_file = results_to_sample.parent / (
    results_to_sample.stem + f"__{len(DF)}samples" + results_to_sample.suffix
)
DF.to_csv(output_file, index=False)
print(f"File output to: {output_file}")
