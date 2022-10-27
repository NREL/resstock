"""
Get stats for each set of EUSS aggregates for IRA and combine for comparison

By: Lixi.Liu@nrel.gov
Date: 2022-10-10

"""
from pathlib import Path
import pandas as pd


output_dirs = [
    "/Volumes/Lixi_Liu/output_by_technology_v1",
    "/Volumes/Lixi_Liu/output_v2_by_iecc",
    "/Volumes/Lixi_Liu/output_v3_by_iecc_no_wh",
    "/Volumes/Lixi_Liu/output_by_technology_fpl",
]

dfo = []
for output_dir in output_dirs:
    output_dir = Path(output_dir)
    dir_name = output_dir.stem
    print()
    dfm = []
    for file in output_dir.iterdir():
        if file.suffix != ".csv":
            continue
        value_type, upgrade = file.stem.split("-")
        df = pd.read_csv(file)
        print(file)
        for col in ["electricity_kwh", "natural_gas_therm", "all_fuels_co2e_kg"]:
            dfi = df[col].describe()
            dfi["weighted_mean"] = (
                df["applicable_household_count"] * df[col]
            ).sum() / df["applicable_household_count"].sum()
            dfi = (
                dfi.rename(dir_name)
                .to_frame()
                .reset_index()
                .rename(columns={"index": "metric"})
            )
            dfi["technology"] = upgrade
            dfi[f"{value_type}_column"] = col
            dfi = dfi.set_index(["technology", f"{value_type}_column", "metric"])
            dfm.append(dfi)

        cond = df["modeled_count"] < 10
        small_count = df[cond]
        if len(small_count) > 0:
            print(f"  - {len(small_count)} / {len(df)} segment has <10 models!")

        cond &= df["heating_fuel"].isin(["Electricity", "Natural Gas"])
        small_count = df[cond]
        if len(small_count) > 0:
            print(
                f"  - {len(small_count)} of Electricity/Natural Gas heating_fuel segment has <10 models!"
            )

    dfm = pd.concat(dfm, axis=0)
    dfo.append(dfm)

dfo = pd.concat(dfo, axis=1)

here = Path(__file__).resolve().parent
dfo.to_csv(here / "data" / "ira_output_comparison_ami.csv", index=True)
