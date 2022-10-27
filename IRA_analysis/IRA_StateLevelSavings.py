"""
Purpose: 
Estimate energy savings using EUSS 2018 AMY results
Results available for download as a .csv here:
https://data.openei.org/s3_viewer?bucket=oedi-data-lake&prefix=nrel-pds-building-stock%2Fend-use-load-profiles-for-us-building-stock%2F2022%2Fresstock_amy2018_release_1%2Fmetadata_and_annual_results%2Fnational%2Fcsv%2F

Estimate average energy savings by state and by technology improvement
State excludes Hawaii and Alaska, Tribal lands, and territories

Technology improvements are gradiented by 10 options
More information can be found here:
https://oedi-data-lake.s3.amazonaws.com/nrel-pds-building-stock/end-use-load-profiles-for-us-building-stock/2022/EUSS_ResRound1_Technical_Documentation.pdf

Created by: Lixi.Liu@nrel.gov
Modified by: Katelyn.Stenger@nrel.gov
Created on: Oct 4, 2022
"""

"""
12 end use technologies and their savings are pulled for IRA:
-   Basic enclosure: all (pkg 1)
-   Enhanced enclosure: all (pkg 2)
-   Heat pump – min eff + existing backup: all (pkg 5)
-   Heat pump – min eff: all (pkg 3)
-   Heat pump – high eff: all (pkg 4)
-   Heat pump – high eff + basic enclosure: Heating & Cooling (pkg 9)
-   Heat pump – high eff + enhanced enclosure: Heating & Cooling (pkg 10)
-   Heat pump water heater: all (pkg 6)
-   Electric dryer: Clothes dryer (pkg 7)
-   Heat pump dryer: Clothes dryer (pkg 8, 9, 10)
-   Electric cooking: Cooking (pkg 7)
-   Induction cooking: Cooking (pkg 8, 9, 10)

"""

# import packages
from pathlib import Path
import sys
import numpy as np
import pandas as pd
import csv

from add_ami_to_euss_results import add_ami_column_to_file


### Helper settings
conversion_factors = {
    "electricity": 1,  # to kWh
    "fuel_oil": 1 / 293.0710701722222,  # to mmbtu
    "natural_gas": 1 / 29.307107017222222,  # therm
    "propane": 1 / 293.0710701722222,  # to mmbtu
    "site_energy": 1 / 293.0710701722222,  # to mmbtu
}
converted_units = {
    "electricity": "kwh",
    "fuel_oil": "mmbtu",
    "natural_gas": "therm",
    "propane": "mmbtu",
    "site_energy": "mmbtu",
}

ci_multipliers = {
    "50%CI": 0.67449,
    "75%CI": 1.15035,
    "90%CI": 1.64485,
    "95%CI": 1.95996,
    "99%CI": 2.57583,
}


class IRAAnalysis:
    def __init__(
        self, euss_dir, groupby_cols, coarsening_map, emission_type, output_dir=None
    ):

        print(
            "========================================================================="
        )
        print(
            f"""
            Analysis for 2022 Inflation Reduction Act (IRA) using EUSS Round 1 summary files.
            """
        )
        print(
            "========================================================================="
        )
        print(
            f"Energy/savings are grouped by: {groupby_cols}\nwith coarsening_map: {coarsening_map}"
        )

        # initialize
        self.groupby_cols = groupby_cols
        self.coarsening_map = coarsening_map
        self.emission_type = emission_type
        self.euss_dir = self.validate_euss_directory(euss_dir)
        self.data_dir = Path(__file__).resolve().parent / "data"
        self.output_dir = self.validate_output_directory(output_dir)

    @staticmethod
    def validate_output_directory(output_dir):
        if output_dir is None:
            output_dir = Path(__file__).resolve().parent / "output_by_technology"
        else:
            output_dir = Path(output_dir)
        output_dir.mkdir(parents=True, exist_ok=True)
        print(f"Analysis output will be exported to: {output_dir}")
        return output_dir

    @staticmethod
    def validate_euss_directory(euss_dir):
        euss_dir = Path(euss_dir)
        if not euss_dir.exists():
            print(f"Cannot find EUSS data folder:\n{euss_dir}")
            print(
                "EUSS data can be downloaded from "
                "https://data.openei.org/s3_viewer?bucket=oedi-data-lake&prefix=nrel-pds-building-stock%2Fend-use-load-profiles-for-us-building-stock%2F2022%2Fresstock_amy2018_release_1%2Fmetadata_and_annual_results%2Fnational%2Fcsv%2F"
            )
            sys.exit(1)
        print(f"EUSS input files: {euss_dir}")
        return euss_dir

    def add_ami_to_euss_files(self):
        for file_path in self.euss_dir.iterdir():
            if file_path.suffix != ".csv":
                continue
            with open(file_path, newline="") as f:
                reader = csv.reader(f)
                columns = next(reader)  # gets the first line
                if "in.area_median_income" not in columns:
                    add_ami_column_to_file(file_path)  # modify file in-place

    @staticmethod
    def get_groupby_cols_with_coarsening(groupby_cols, coarsening_map=None):
        if coarsening_map is None:
            return groupby_cols
        else:
            assert isinstance(
                coarsening_map, dict
            ), "only support single coarsening_map currently, coarsening_map: None or dict."
            return [
                coarsening_map[col] if col in coarsening_map else col
                for col in groupby_cols
            ]

    @staticmethod
    def get_energy_savings_cols(end_use="total", output="all"):
        if output not in ["all", "total_fuel", "by_fuel"]:
            raise ValueError(f"output={output} not supported")
        energy_cols = [
            f"out.electricity.{end_use}.energy_consumption.kwh.savings",
            f"out.fuel_oil.{end_use}.energy_consumption.kwh.savings",
            f"out.natural_gas.{end_use}.energy_consumption.kwh.savings",
            f"out.propane.{end_use}.energy_consumption.kwh.savings",
            f"out.site_energy.{end_use}.energy_consumption.kwh.savings",
        ]
        if output == "total_fuel":
            # site_energy only
            return energy_cols[-1]
        if output == "by_fuel":
            # all except site_energy
            return energy_cols[:-1]
        if output == "all":
            return energy_cols
        else:
            raise ValueError(f"output={output} unsupported")

    @staticmethod
    def get_emission_savings_cols(
        emission_type="lrmer_low_re_cost_25_2025_start", output="all"
    ):
        if output not in ["all", "total_fuel", "by_fuel"]:
            raise ValueError(f"output={output} not supported")
        emission_cols = [
            f"out.emissions_reduction.electricity.{emission_type}.co2e_kg",
            f"out.emissions_reduction.fuel_oil.{emission_type}.co2e_kg",
            f"out.emissions_reduction.natural_gas.{emission_type}.co2e_kg",
            f"out.emissions_reduction.propane.{emission_type}.co2e_kg",
            f"out.emissions_reduction.all_fuels.{emission_type}.co2e_kg",
        ]
        if output == "total_fuel":
            # all_fuels only
            return emission_cols[-1]
        if output == "by_fuel":
            # all except all_fuels
            return emission_cols[:-1]
        if output == "all":
            return emission_cols
        else:
            raise ValueError(f"output={output} unsupported")

    def get_energy_cols(self, end_use="total", output="all"):
        cols = self.get_energy_savings_cols(end_use=end_use, output=output)
        if isinstance(cols, str):
            return cols.removesuffix(".savings")
        return [col.removesuffix(".savings") for col in cols]

    def get_emission_cols(
        self, emission_type="lrmer_low_re_cost_25_2025_start", output="all"
    ):
        cols = self.get_emission_savings_cols(
            emission_type=emission_type, output=output
        )
        if isinstance(cols, str):
            return cols.replace("emissions_reduction", "emissions")
        return [col.replace("emissions_reduction", "emissions") for col in cols]

    @staticmethod
    def remap_building_type(df):
        df["building_type"] = df["in.geometry_building_type_recs"].map(
            {
                "Mobile Home": "Single-Family",
                "Single-Family Detached": "Single-Family",
                "Single-Family Attached": "Single-Family",
                "Multi-Family with 2 - 4 Units": "Multi-Family",
                "Multi-Family with 5+ Units": "Multi-Family",
            }
        )
        return df

    @staticmethod
    def remap_federal_poverty(df):
        df["FPL"] = df["in.federal_poverty_level"].map(
            {
                "0-100%": "<200% FPL",
                "100-150%": "<200% FPL",
                "150-200%": "<200% FPL",
                "200-300%": "200%+ FPL",
                "300-400%": "200%+ FPL",
                "400%+": "200%+ FPL",
            }
        )
        return df

    @staticmethod
    def remap_area_median_income(df):
        df["AMI"] = df["in.area_median_income"].map(
            {
                "0-30%": "<80% AMI",
                "30-60%": "<80% AMI",
                "60-80%": "<80% AMI",
                "80-100%": "80-150% AMI",
                "100-120%": "80-150% AMI",
                "120-150%": "80-150% AMI",
                "150%+": "150%+ AMI",
            }
        )
        return df

    def remap_columns(self, df):
        df = self.remap_building_type(df)
        df = self.remap_federal_poverty(df)
        df = self.remap_area_median_income(df)
        return df

    @staticmethod
    def simplify_column_names(df):
        df.index.names = [x.removeprefix("in.") for x in df.index.names]
        df.columns = [x.removeprefix("in.") for x in df.columns]

        return df

    @staticmethod
    def validate_value_column(value_col):
        if value_col.endswith(".kwh.savings") or value_col.endswith(".kwh"):
            fuel_type = value_col.split(".")[1]
            end_use = value_col.split(".")[2]
            conversion = conversion_factors[fuel_type]
            unit = converted_units[fuel_type]

        elif value_col.endswith(".co2e_kg"):
            fuel_type = value_col.split(".")[2] + "_emissions"
            conversion = 1
            unit = value_col.split(".")[-1]

        else:
            raise ValueError(
                f"value_col={value_col} cannot be used with calculate_mean_values"
            )

        return fuel_type, unit, conversion

    @staticmethod
    def calculate_household_counts(df, groupby_cols: list):
        df_groupby = df.loc[df["applicability"] == True].groupby(groupby_cols)

        df_count = df_groupby["bldg_id"].count()
        df_count = df_count.rename("modeled_count").to_frame()
        df_count["applicable_household_count"] = df_groupby["weight"].sum()

        return df_count

    def calculate_mean_values(
        self, df, groupby_cols: list, value_col: str, as_percentage=False
    ):
        fuel_type, unit, conversion = self.validate_value_column(value_col)
        if as_percentage:
            unit = "fraction"
            conversion = 1
        col_label = f"{fuel_type}_{unit}"
        df_mean = (
            df.loc[df["applicability"] == True].groupby(groupby_cols)[value_col].mean()
        )
        df_mean = (df_mean * conversion).rename(col_label).to_frame()

        return df_mean

    @staticmethod
    def calculate_confidence_intervals(
        self, df, groupby_cols: list, value_col: str, confidence="95%CI"
    ):
        fuel_type, unit, conversion = validate_value_column(value_col)
        ci_multiplier = ci_multipliers[confidence]
        lb = f"LB {confidence}"
        ub = f"UB {confidence}"

        df_ci = (
            df.loc[df["applicability"] == True]
            .groupby(groupby_cols)[value_col]
            .describe()
        )
        ci_delta = ci_multiplier * df_ci["std"] / np.sqrt(df_ci["count"])
        df_ci[lb] = df_ci["mean"] - ci_delta
        df_ci[ub] = df_ci["mean"] + ci_delta
        df_ci = df_ci[[lb, ub]]

        # apply unit conversion as needed
        df_ci = df_ci.applymap(lambda x: x * conversion)

        return df_ci

    def load_results(self, pkgs: list):
        if not isinstance(pkgs, list):
            filename = f"upgrade{pkgs:02d}_metadata_and_annual_results.csv"
            if pkgs == 0:
                filename = "baseline_metadata_and_annual_results.csv"
            df = pd.read_csv(self.euss_dir / filename, low_memory=False)
            df = self.remap_columns(df)
            return df

        if isinstance(pkgs, list):
            if 0 in pkgs:
                raise ValueError(
                    "cannot combined baseline results (pkg0) with upgrade results."
                )
            DF = []
            for pkg in pkgs:
                filename = f"upgrade{pkg:02d}_metadata_and_annual_results.csv"
                df = pd.read_csv(self.euss_dir / filename, low_memory=False)
                DF.append(self.remap_columns(df))
            return pd.concat(DF, axis=0).reset_index(drop=True)

        raise ValueError(f"Invalid input pkgs={pkgs}")

    def _get_mean_dataframe_base(
        self,
        df,
        groupby_cols: list,
        energy_savings_cols: list,
        total_emission_col: str,
        as_percentage=False,
    ):
        """Base method for getting mean savings"""
        # get mean savings
        DF = [self.calculate_household_counts(df, groupby_cols)]
        for energy_col in energy_savings_cols:
            DF.append(
                self.calculate_mean_values(
                    df, groupby_cols, energy_col, as_percentage=as_percentage
                )
            )
            print(f" - added {energy_col}")
        DF.append(
            self.calculate_mean_values(
                df, groupby_cols, total_emission_col, as_percentage=as_percentage
            )
        )
        print(f" - added {total_emission_col}")

        DF = pd.concat(DF, axis=1)

        # QC
        small_count = DF[DF["modeled_count"] < 10]
        if len(small_count) > 0:
            print(f"WARNING, {len(small_count)} / {len(DF)} segment has <10 models!")

        return DF

    def _get_mean_dataframe_with_coarsening(
        self,
        df,
        groupby_cols: list,
        energy_savings_cols: list,
        total_emission_col: str,
        as_percentage=False,
        coarsening_map=None,
    ):

        if coarsening_map is None:
            return self._get_mean_dataframe_base(
                df,
                groupby_cols,
                energy_savings_cols,
                total_emission_col,
                as_percentage=as_percentage,
            )

        # get mean savings for coarsened groupby_cols
        groupby_cols_coarsened = self.get_groupby_cols_with_coarsening(
            groupby_cols, coarsening_map=coarsening_map
        )
        DF = self._get_mean_dataframe_base(
            df,
            groupby_cols_coarsened,
            energy_savings_cols,
            total_emission_col,
            as_percentage=as_percentage,
        )

        # map mean savings back to groupby_cols (using weight based on bldg_id count)
        groupby_cols_all = groupby_cols + list(coarsening_map.values())
        df_map = df.groupby(groupby_cols_all)["bldg_id"].count()
        df_map = df_map.div(
            df_map.groupby(groupby_cols).sum()
        )  # normalize to give breakdown of mapped_col by orig_col
        df_map = (
            df_map.rename("fraction")
            .to_frame()
            .reset_index()
            .set_index(groupby_cols_coarsened)
        )

        DF2 = (
            df_map.join(DF, how="left")
            .groupby(groupby_cols)
            .apply(lambda x: x[DF.columns].multiply(x["fraction"], axis=0).sum())
        )  # applicable_household_count cannot be mapped back

        df_count_actual = self.calculate_household_counts(df, groupby_cols)
        # replace applicable_household_count with actual count from groupby_cols
        DF2["applicable_household_count"] = df_count_actual[
            "applicable_household_count"
        ]

        return DF2

    def _replace_savings_cols_as_percentage(
        self, df, energy_saving_cols, total_emission_saving_col
    ):
        dfi = df.copy()

        # get baseline energy
        energy_cols = self.get_energy_cols(end_use="total")
        energy_saving_cols_baseline = self.get_energy_savings_cols(end_use="total")
        total_emission_col = self.get_emission_cols(
            emission_type=self.emission_type, output="total_fuel"
        )
        total_emission_saving_col_baseline = self.get_emission_savings_cols(
            emission_type=self.emission_type, output="total_fuel"
        )

        assert (
            len(energy_saving_cols)
            == len(energy_cols)
            == len(energy_saving_cols_baseline)
        ), f"mismatch:\nenergy_saving_cols={energy_saving_cols}\nenergy_cols={energy_cols}\nenergy_saving_cols_baseline={energy_saving_cols_baseline}"

        # calculate percent savings
        for saving_col, total_col, saving_col_baseline in zip(
            energy_saving_cols, energy_cols, energy_saving_cols_baseline
        ):
            baseline = dfi[[total_col, saving_col_baseline]].sum(
                axis=1
            )  # upgraded_baseline + saving = pre-upgrade baseline
            dfi[saving_col] /= baseline
        baseline_emission = dfi[
            [total_emission_col, total_emission_saving_col_baseline]
        ].sum(
            axis=1
        )  # <-- baseline CO2
        dfi[total_emission_saving_col] /= baseline_emission

        return dfi

    def validate_percent_savings(self, DF):
        fraction_cols = [col for col in DF.columns if col.endswith("fraction")]
        df_over_100pct = DF[(DF[fraction_cols] > 1) | (DF[fraction_cols] < -1)].dropna(
            how="all"
        )
        if len(df_over_100pct) > 0:
            print(
                f"{len(df_over_100pct)} / {len(DF)} have percent savings or increase beyond 100%"
            )

    def save_to_file(self, DF, pkg_name, as_percentage=False):
        DF = self.simplify_column_names(DF)
        output_file = f"mean_savings-{pkg_name}.csv"
        if as_percentage:
            output_file = f"mean_pct_savings-{pkg_name}.csv"
        DF.to_csv(self.output_dir / output_file)

    def _create_new_cols_for_enduse_(
        self, df, enduse, energy_cols_enduse, energy_cols_total, emission_cols
    ):
        # calculate savings attributed to end use, add as new cols
        emission_cols_new = []
        dfi = df.copy()
        for enduse_col, total_col, emission_col in zip(
            energy_cols_enduse, energy_cols_total, emission_cols
        ):
            print(f" {enduse_col}")
            if not enduse_col in dfi.columns:
                print(f"   {enduse_col} not in df.columns, replacing with 0s...")
                dfi[enduse_col] = 0
            new_emission_col = emission_col.replace(
                "emissions_reduction", f"emissions_reduction_{enduse}"
            )
            savings_factor = dfi[enduse_col] / dfi[total_col]
            dfi[new_emission_col] = dfi[emission_col] * savings_factor
            emission_cols_new.append(new_emission_col)

        # combined attributed savings, add as new cols
        total_col = self.get_energy_savings_cols(
            end_use="total", output="total_fuel"
        ).replace("total", enduse)
        dfi[total_col] = dfi[energy_cols_enduse].sum(axis=1)
        energy_cols_enduse.append(total_col)

        total_emission_col = self.get_emission_savings_cols(
            emission_type=self.emission_type, output="total_fuel"
        ).replace("emissions_reduction", f"emissions_reduction_{enduse}")
        dfi[total_emission_col] = dfi[emission_cols_new].sum(axis=1)

        return dfi, energy_cols_enduse, total_emission_col

    def _get_savings_dataframe_for_an_enduse(
        self, df, enduse, as_percentage=False, coarsening=True
    ):
        energy_saving_cols_enduse = self.get_energy_savings_cols(
            end_use=enduse, output="by_fuel"
        )
        energy_saving_cols_total = self.get_energy_savings_cols(
            end_use="total", output="by_fuel"
        )
        emission_saving_cols = self.get_emission_savings_cols(
            emission_type=self.emission_type, output="by_fuel"
        )

        (
            dfi,
            energy_saving_cols_enduse,
            total_emission_saving_col,
        ) = self._create_new_cols_for_enduse_(
            df,
            enduse,
            energy_saving_cols_enduse,
            energy_saving_cols_total,
            emission_saving_cols,
        )

        if as_percentage:
            dfi = self._replace_savings_cols_as_percentage(
                dfi, energy_saving_cols_enduse, total_emission_saving_col
            )

        # get mean savings
        coarsening_map = self.coarsening_map if coarsening else None
        DF = self._get_mean_dataframe_with_coarsening(
            dfi,
            self.groupby_cols,
            energy_saving_cols_enduse,
            total_emission_saving_col,
            as_percentage=as_percentage,
            coarsening_map=coarsening_map,
        )

        if as_percentage:
            self.validate_percent_savings(DF)

        return DF

    def _get_savings_dataframe(self, df, as_percentage=False, coarsening=True):
        energy_saving_cols = self.get_energy_savings_cols(end_use="total")
        total_emission_saving_col = self.get_emission_savings_cols(
            emission_type=self.emission_type, output="total_fuel"
        )
        dfi = df.copy()

        if as_percentage:
            dfi = self._replace_savings_cols_as_percentage(
                df, energy_saving_cols, total_emission_saving_col
            )

        # get mean savings
        coarsening_map = self.coarsening_map if coarsening else None
        DF = self._get_mean_dataframe_with_coarsening(
            dfi,
            self.groupby_cols,
            energy_saving_cols,
            total_emission_saving_col,
            as_percentage=as_percentage,
            coarsening_map=coarsening_map,
        )

        if as_percentage:
            self.validate_percent_savings(DF)

        return DF

    def get_savings_total(
        self, pkg, pkg_name, as_percentage=False, coarsening=True, return_df=False
    ):
        print(
            f"\n> Calculating total savings for [[ {pkg_name} ]] from upgrade {pkg}..."
        )
        df = self.load_results(pkg)

        # filter
        cond = (df["applicability"] == True) & (df["in.vacancy_status"] == "Occupied")
        df = df.loc[cond]
        DF = self._get_savings_dataframe(
            df, as_percentage=as_percentage, coarsening=coarsening
        )

        # save to file
        self.save_to_file(DF, pkg_name, as_percentage=as_percentage)
        if return_df:
            return DF

    def get_savings_dryer(
        self, pkg, pkg_name, as_percentage=False, coarsening=True, return_df=False
    ):
        print(
            f"\n> Calculating dryer savings for [[ {pkg_name} ]] from upgrade {pkg}..."
        )
        df = self.load_results(pkg)

        # filter to tech
        cond = (df["applicability"] == True) & (df["in.vacancy_status"] == "Occupied")
        cond &= ~df["upgrade.clothes_dryer"].isna()
        df = df.loc[cond]
        enduse = "clothes_dryer"
        DF = self._get_savings_dataframe_for_an_enduse(
            df, enduse, as_percentage=as_percentage, coarsening=coarsening
        )

        # save to file
        self.save_to_file(DF, pkg_name, as_percentage=as_percentage)
        if return_df:
            return DF

    def get_savings_cooking(
        self, pkg, pkg_name, as_percentage=False, coarsening=True, return_df=False
    ):
        print(
            f"\n> Calculating cooking savings for [[ {pkg_name} ]] from upgrade {pkg}..."
        )
        df = self.load_results(pkg)

        # filter to tech
        cond = (df["applicability"] == True) & (df["in.vacancy_status"] == "Occupied")
        cond &= ~df["upgrade.cooking_range"].isna()
        df = df.loc[cond]
        enduse = "range_oven"
        DF = self._get_savings_dataframe_for_an_enduse(
            df, enduse, as_percentage=as_percentage, coarsening=coarsening
        )

        # save to file
        self.save_to_file(DF, pkg_name, as_percentage=as_percentage)
        if return_df:
            return DF

    def _create_new_cols_for_heating_and_cooling_(self, df):
        """
        This attributes all savings that are not:
            - water heating
            - dryer
            - cooking
        as savings (heating and cooling) for heat pumps + envelope upgrades

        """
        energy_cols_hot_water = self.get_energy_savings_cols(
            end_use="hot_water", output="by_fuel"
        )
        energy_cols_dryer = self.get_energy_savings_cols(
            end_use="clothes_dryer", output="by_fuel"
        )
        energy_cols_cooking = self.get_energy_savings_cols(
            end_use="range_oven", output="by_fuel"
        )
        energy_cols_total = self.get_energy_savings_cols(
            end_use="total", output="by_fuel"
        )
        emission_cols = self.get_emission_savings_cols(
            emission_type=self.emission_type, output="by_fuel"
        )

        # calculate savings attributed to heat/cool, add as new cols
        enduse_new = "heat_cool"
        energy_cols_new = []
        emission_cols_new = []
        dfi = df.copy()
        for hot_water_col, dryer_col, cooking_col, total_col, emission_col in zip(
            energy_cols_hot_water,
            energy_cols_dryer,
            energy_cols_cooking,
            energy_cols_total,
            emission_cols,
        ):
            available_enduses = list(
                {hot_water_col, dryer_col, cooking_col}.intersection(set(dfi.columns))
            )
            new_col = total_col.replace("total", enduse_new)
            dfi[new_col] = dfi[total_col] - dfi[available_enduses].sum(axis=1)
            energy_cols_new.append(new_col)

            new_emission_col = emission_col.replace(
                "emissions_reduction", f"emissions_reduction_{enduse_new}"
            )
            savings_factor = dfi[new_col] / dfi[total_col]
            dfi[new_emission_col] = dfi[emission_col] * savings_factor
            emission_cols_new.append(new_emission_col)

        # combined attributed savings, add as new cols
        total_col = self.get_energy_savings_cols(
            end_use="total", output="total_fuel"
        ).replace("total", enduse_new)
        dfi[total_col] = dfi[energy_cols_new].sum(axis=1)
        energy_cols_new.append(total_col)

        total_emission_col = self.get_emission_savings_cols(
            emission_type=self.emission_type, output="total_fuel"
        ).replace("emissions_reduction", f"emissions_reduction_{enduse_new}")
        dfi[total_emission_col] = dfi[emission_cols_new].sum(axis=1)

        return dfi, energy_cols_new, total_emission_col

    def get_savings_heating_and_cooling(
        self, pkg, pkg_name, as_percentage=False, coarsening=True, return_df=False
    ):
        print(
            f"\n> Calculating heat/cool savings for [[ {pkg_name} ]] from upgrade {pkg}..."
        )
        print(f"  by removing from total savings: water_heating, dryer, cooking...")
        df = self.load_results(pkg)

        # filter to tech
        cond = (df["applicability"] == True) & (df["in.vacancy_status"] == "Occupied")
        cond &= ~(
            df["upgrade.hvac_cooling_efficiency"].isna()
            & df["upgrade.hvac_heating_efficiency"].isna()
        )
        df = df.loc[cond]

        (
            dfi,
            energy_cols_new,
            total_emission_col,
        ) = self._create_new_cols_for_heating_and_cooling_(df)
        if as_percentage:
            dfi = self._replace_savings_cols_as_percentage(
                dfi, energy_cols_new, total_emission_col
            )

        # get mean savings
        coarsening_map = self.coarsening_map if coarsening else None
        DF = self._get_mean_dataframe_with_coarsening(
            dfi,
            self.groupby_cols,
            energy_cols_new,
            total_emission_col,
            as_percentage=as_percentage,
            coarsening_map=coarsening_map,
        )

        if as_percentage:
            self.validate_percent_savings(DF)

        # save to file
        self.save_to_file(DF, pkg_name, as_percentage=as_percentage)
        if return_df:
            return DF

    def get_baseline_consumption(self, pkg, pkg_name, coarsening=True, return_df=False):
        print(f"\n> Calculating [[ {pkg_name} ]] from run {pkg}...")
        print(f"  for Occupied units only...")
        df = self.load_results(pkg)
        # filter to tech
        cond = df["in.vacancy_status"] == "Occupied"
        df = df.loc[cond]

        # metric columns
        energy_cols = self.get_energy_cols(end_use="total")
        total_emission_col = self.get_emission_cols(
            emission_type=self.emission_type, output="total_fuel"
        )

        # get mean savings
        coarsening_map = self.coarsening_map if coarsening else None
        DF = self._get_mean_dataframe_with_coarsening(
            df,
            self.groupby_cols,
            energy_cols,
            total_emission_col,
            coarsening_map=coarsening_map,
        )

        # save to file
        DF = self.simplify_column_names(DF)
        output_file = f"mean-{pkg_name}.csv"
        DF.to_csv(self.output_dir / output_file)

        if return_df:
            return DF

    def get_segment_count_in_baseline(self):
        """get unit count in segment (from baseline file)"""
        df = self.load_results(0)
        # filter to tech
        cond = df["in.vacancy_status"] == "Occupied"
        df = df.loc[cond]
        DF = (
            df.groupby(self.groupby_cols)["weight"]
            .sum()
            .rename("total_household_count")
            .to_frame()
        )

        return DF

    def get_segment_fraction_above_targets(
        self,
        pkg,
        pkg_name,
        end_use="total",
        saving_targets=[0.15, 0.20, 0.35],
        return_df=False,
    ):
        """get applicable count and stock fractions above target"""
        print(
            f"\n> Calculating fraction of stock above savings for [[ {pkg_name} ]] from upgrade {pkg} {end_use}..."
        )

        df = self.load_results(pkg)

        # filter and reformat df as needed
        cond = (df["applicability"] == True) & (df["in.vacancy_status"] == "Occupied")
        if end_use == "total":
            df = df.loc[cond]
            energy_saving_cols = self.get_energy_savings_cols(end_use="total")
            total_emission_saving_col = self.get_emission_savings_cols(
                emission_type=self.emission_type, output="total_fuel"
            )
            dfi = df.copy()

        elif end_use in ["dryer", "cooking"]:
            if end_use == "dryer":
                cond &= ~df["upgrade.clothes_dryer"].isna()
                df = df.loc[cond]
                enduse = "clothes_dryer"
            else:
                cond &= ~df["upgrade.cooking_range"].isna()
                df = df.loc[cond]
                enduse = "range_oven"
            energy_saving_cols_enduse = self.get_energy_savings_cols(
                end_use=enduse, output="by_fuel"
            )
            energy_saving_cols_total = self.get_energy_savings_cols(
                end_use="total", output="by_fuel"
            )
            emission_saving_cols = self.get_emission_savings_cols(
                emission_type=self.emission_type, output="by_fuel"
            )

            (
                dfi,
                energy_saving_cols,
                total_emission_saving_col,
            ) = self._create_new_cols_for_enduse_(
                df,
                enduse,
                energy_saving_cols_enduse,
                energy_saving_cols_total,
                emission_saving_cols,
            )

        elif end_use == "heat_cool":
            cond &= ~(
                df["upgrade.hvac_cooling_efficiency"].isna()
                & df["upgrade.hvac_heating_efficiency"].isna()
            )
            df = df.loc[cond]

            (
                dfi,
                energy_saving_cols,
                total_emission_saving_col,
            ) = self._create_new_cols_for_heating_and_cooling_(df)

        else:
            raise ValueError(
                f"Invalide, end_use={end_use}, only 'total', dryer', 'cooking', and 'heat_cool' supported"
            )

        # get savings as pct
        dfi = self._replace_savings_cols_as_percentage(
            dfi, energy_saving_cols, total_emission_saving_col
        )

        # get fractions
        site_saving_pct = self.get_energy_savings_cols(
            end_use="total", output="total_fuel"
        )
        DF = dfi.groupby(self.groupby_cols).apply(
            lambda x: self._fraction_stats_(x, saving_targets=saving_targets)
        )

        # combine with baesline count
        DF = pd.concat([self.get_segment_count_in_baseline(), DF], axis=1)

        output_file = f"stock_fraction_above_targets-{pkg_name}.csv"
        DF.to_csv(self.output_dir / output_file)

        return DF

    def _fraction_stats_(self, df, saving_targets):
        dfo = dict()
        dfo["applicable_household_count"] = df["weight"].sum()

        site_saving_pct = self.get_energy_savings_cols(
            end_use="total", output="total_fuel"
        )
        for goal in saving_targets:
            label = f"fraction_with_site_saving_{int(goal*100)}pct_plus"
            fraction = (
                df.loc[df[site_saving_pct] >= goal, site_saving_pct].count()
                / df[site_saving_pct].count()
            )
            dfo[label] = fraction

        return pd.Series(dfo)


###### main ######

# calculated unit count, rep unit count, savings by fuel, carbon saving
# TODO: bills calc (here), upgrade costs (in another script pull from results on AWS)


def main(euss_dir):

    ### Upgrade settings
    emission_type = (
        "lrmer_low_re_cost_25_2025_start"  # <---- least controversial approach
    )
    groupby_cols = [
        "in.state",
        "in.heating_fuel",
        "building_type",
        "in.tenure",
        "AMI",  # "AMI", "FPL"
    ]

    coarsening_map = {"in.state": "in.ashrae_iecc_climate_zone_2004_2_a_split"}

    # Initialize
    IRA = IRAAnalysis(euss_dir, groupby_cols, coarsening_map, emission_type)

    # Pre-process:
    IRA.add_ami_to_euss_files()

    ## Set control variables
    coarsening = True  # <--- # whether to use coarsening_map
    as_percentage = True  # <--- # whether to calculate savings as pct

    print(f"coarsening = {coarsening}")
    print(f"as_percentage = {as_percentage}")

    # Do calculations
    # get baseline consumption
    # IRA.get_baseline_consumption(0, "baseline_consumption", coarsening=coarsening)

    # [1] Basic enclosure: all (pkg 1)
    IRA.get_savings_total(
        1, "basic_enclosure_upgrade", as_percentage=as_percentage, coarsening=coarsening
    )

    # [2] Enhanced enclosure: all (pkg 2)
    IRA.get_savings_total(
        2,
        "enhanced_enclosure_upgrade",
        as_percentage=as_percentage,
        coarsening=coarsening,
    )

    # [3] Heat pump – min eff: all (pkg 3)
    IRA.get_savings_total(
        3,
        "heat_pump_min_eff_with_electric_backup",
        as_percentage=as_percentage,
        coarsening=coarsening,
    )

    # [4] Heat pump – high eff: all (pkg 4)
    IRA.get_savings_total(
        4,
        "heat_pump_high_eff_with_electric_backup",
        as_percentage=as_percentage,
        coarsening=coarsening,
    )

    # [5] Heat pump – min eff + existing backup: all (pkg 5)
    IRA.get_savings_total(
        5,
        "heat_pump_min_eff_with_existing_backup",
        as_percentage=as_percentage,
        coarsening=coarsening,
    )

    # [6] Heat pump – high eff + basic enclosure: Heating & Cooling (pkg 9)
    IRA.get_savings_heating_and_cooling(
        9,
        "heat_pump_high_eff_with_basic_enclosure",
        as_percentage=as_percentage,
        coarsening=coarsening,
    )

    # [7] Heat pump – high eff + enhanced enclosure: Heating & Cooling (pkg 10)
    IRA.get_savings_heating_and_cooling(
        10,
        "heat_pump_high_eff_with_enhanced_enclosure",
        as_percentage=as_percentage,
        coarsening=coarsening,
    )

    # [8] Heat pump water heater: all (pkg 6)
    IRA.get_savings_total(
        6, "heat_pump_water_heater", as_percentage=as_percentage, coarsening=coarsening
    )

    # [9] Electric dryer: Clothes dryer (pkg 7)
    IRA.get_savings_dryer(
        7, "electric_clothes_dryer", as_percentage=as_percentage, coarsening=coarsening
    )

    # [10] Heat pump dryer: Clothes dryer (pkg 8, 9, 10)
    IRA.get_savings_dryer(
        [8, 9, 10],
        "heat_pump_clothes_dryer",
        as_percentage=as_percentage,
        coarsening=coarsening,
    )

    # [11] Electric cooking: Cooking (pkg 7)
    IRA.get_savings_cooking(
        7, "electric_cooking", as_percentage=as_percentage, coarsening=coarsening
    )

    # [12] Induction cooking: Cooking (pkg 8, 9, 10)
    IRA.get_savings_cooking(
        [8, 9, 10],
        "induction_cooking",
        as_percentage=as_percentage,
        coarsening=coarsening,
    )

    #####################################


def main_goal_achievement(euss_dir):

    ### Upgrade settings
    emission_type = (
        "lrmer_low_re_cost_25_2025_start"  # <---- least controversial approach
    )
    groupby_cols = [
        "in.state",
        "in.heating_fuel",
        "building_type",
    ]
    coarsening_map = None

    # Initialize
    IRA = IRAAnalysis(euss_dir, groupby_cols, coarsening_map, emission_type)

    # Pre-process:
    IRA.add_ami_to_euss_files()

    # Do calculations
    # [1] Basic enclosure: all (pkg 1)
    IRA.get_segment_fraction_above_targets(
        1, "basic_enclosure_upgrade", end_use="total"
    )

    # [2] Enhanced enclosure: all (pkg 2)
    IRA.get_segment_fraction_above_targets(
        2, "enhanced_enclosure_upgrade", end_use="total"
    )

    # [3] Heat pump – min eff: all (pkg 3)
    IRA.get_segment_fraction_above_targets(
        3, "heat_pump_min_eff_with_electric_backup", end_use="total"
    )

    # [4] Heat pump – high eff: all (pkg 4)
    IRA.get_segment_fraction_above_targets(
        4, "heat_pump_high_eff_with_electric_backup", end_use="total"
    )

    # [5] Heat pump – min eff + existing backup: all (pkg 5)
    IRA.get_segment_fraction_above_targets(
        5, "heat_pump_min_eff_with_existing_backup", end_use="total"
    )

    # [6] Heat pump – high eff + basic enclosure: Heating & Cooling (pkg 9)
    IRA.get_segment_fraction_above_targets(
        9, "heat_pump_high_eff_with_basic_enclosure", end_use="heat_cool"
    )

    # [7] Heat pump – high eff + enhanced enclosure: Heating & Cooling (pkg 10)
    IRA.get_segment_fraction_above_targets(
        10, "heat_pump_high_eff_with_enhanced_enclosure", end_use="heat_cool"
    )

    # [8] Heat pump water heater: all (pkg 6)
    IRA.get_segment_fraction_above_targets(6, "heat_pump_water_heater", end_use="total")

    # [9] Electric dryer: Clothes dryer (pkg 7)
    IRA.get_segment_fraction_above_targets(7, "electric_clothes_dryer", end_use="dryer")

    # [10] Heat pump dryer: Clothes dryer (pkg 8, 9, 10)
    IRA.get_segment_fraction_above_targets(
        [8, 9, 10], "heat_pump_clothes_dryer", end_use="dryer"
    )

    # [11] Electric cooking: Cooking (pkg 7)
    IRA.get_segment_fraction_above_targets(7, "electric_cooking", end_use="cooking")

    # [12] Induction cooking: Cooking (pkg 8, 9, 10)
    IRA.get_segment_fraction_above_targets(
        [8, 9, 10], "induction_cooking", end_use="cooking"
    )


if __name__ == "__main__":

    if len(sys.argv) == 2:
        euss_dir = sys.argv[1]
    elif len(sys.argv) == 1:
        # set working directory if no path is provided
        euss_dir = Path("/Volumes/Lixi_Liu/euss")  # ADJUST to your own default
    else:
        print(
            """
            usage: python IRA_StateLevelSavings.py [optional] <path_to_downloaded_euss_round1_sightglass_files>
            check code for default path_to_downloaded_euss_round1_sightglass_files
            """
        )
        sys.exit(1)

    main(euss_dir)
    main_goal_achievement(euss_dir)
