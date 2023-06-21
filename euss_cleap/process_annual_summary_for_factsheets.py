"""
This script requires resstock-estimation conda env and access to resstock-estimation GitHub repo

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
Created on: Oct 4, 2022
"""

"""
16 individual upgrades or packages and their savings:
-   [1] enclosure.basic_upgrade: 
        all (pkg 1)
-   [2] enclosure.enhanced_upgrade: 
        all (pkg 2)
-   [3] hvac.heat_pump_min_eff_electric_backup: 
        all (pkg 3)
-   [4] hvac.heat_pump_high_eff_electric_backup: 
        all (pkg 4)
-   [5] hvac.heat_pump_min_eff_existing_backup: 
        all (pkg 5)
-   [6] hvac.heat_pump_high_eff_electric_backup + HPWH + enclosure.basic_upgrade: 
        Heating & Cooling (by excluding: ["clothes_dryer", "range_oven"]) (pkg 9)
-   [7] hvac.heat_pump_high_eff_electric_backup + HPWH + enclosure.enhanced_upgrade: 
        Heating & Cooling (by excluding: ["clothes_dryer", "range_oven"]) (pkg 10)
-   [8] water_heater.heat_pump: 
        all (pkg 6)
-   [9] clothes_dryer.electric: 
        Clothes dryer (pkg 7)
-   [10] clothes_dryer.heat_pump: 
        Clothes dryer (pkg 8, 9, 10)
-   [11] cooking.electric: 
        Cooking ("range_oven") (pkg 7)
-   [12] cooking.induction: 
        Cooking ("range_oven") (pkg 8, 9, 10)
-   [13] whole_home.electrification_min_eff: 
        all (pkg 7)
-   [14] whole_home.electrification_high_eff: 
        all (pkg 8)
-   [15] whole_home.electrification_high_eff + enclosure.basic_upgrade: 
        all (pkg 9)
-   [16] whole_home.electrification_high_eff + enclosure.enhanced_upgrade: 
        all (pkg 10)

"""

# import packages
from pathlib import Path
import sys
import numpy as np
import pandas as pd
import csv
import re
import argparse

from add_ami_to_euss_annual_summary import add_ami_column_to_file, read_file


### Helper settings
LB_TO_KG = 0.453592

conversion_factors_from_kbtu = {
    "electricity": 0.29307107,  # to kWh
    "natural_gas": 1 / 100,  # therm
    "fuel_oil": 1 / 1000,  # to mmbtu
    "propane": 1 / 1000,  # to mmbtu
    "total": 1 / 1000,  # to mmbtu
}
conversion_factors_from_mmbtu = {
    "electricity": 293.07107,  # to kWh
    "natural_gas": 10,  # therm
    "fuel_oil": 1,  # to mmbtu
    "propane": 1,  # to mmbtu
    "total": 1,  # to mmbtu
}
converted_units = {
    "electricity": "kwh",
    "natural_gas": "therm",
    "fuel_oil": "mmbtu",
    "propane": "mmbtu",
    "total": "mmbtu",
}
PROPANE_HEAT_CONTENT = (
    91452 * 1e6  # MMBTU/gal - https://www.eia.gov/energyexplained/units-and-calculators/
)
FUEL_OIL_HEAT_CONTENT = (
    6287000 / 42 * 1e6
)  # MMBTU/gal - https://www.eia.gov/energyexplained/units-and-calculators/
CENTS_TO_DOLLARS = 1e-2

na_rep = {"None": np.nan, None: np.nan, "nan": np.nan, "NAN": np.nan}

class SavingsExtraction:
    def __init__(self, euss_dir, emission_type, bill_year, output_dir=None):

        # initialize
        self.euss_dir = self.validate_euss_directory(euss_dir)
        self.data_dir = Path(__file__).resolve().parent / "data"
        self.output_dir = self.validate_directory(output_dir)
        self.emission_type = emission_type
        self.bill_year = bill_year # controls state-avg bills
        self.community = self.euss_dir.stem

        self.fuels = ["electricity", "natural_gas", "fuel_oil", "propane"]

        print(
            "========================================================================="
        )
        print(
            f"""
            Process preprocessed EUSS 1.0 summary results for C-LEAP factsheets
                                       {self.community}
            """
        )
        print(
            "========================================================================="
        )

    @staticmethod
    def validate_directory(output_dir=None):
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
                "EUSS data can be downloaded from AWS nrel-aws-resbldg account"
                "s3://euss/final-2018/euss_res_final_2018_550k_20220901/"
            )
            sys.exit(1)
        print(f"EUSS input files: {euss_dir}")
        return euss_dir

    def add_ami_to_euss_files(self):
        for file_path in self.euss_dir.iterdir():
            columns = read_file(file_path).columns
            if "build_existing_model.area_median_income" not in columns:
                add_ami_column_to_file(file_path)  # modify file in-place

    def get_fuel_use_cols(self, metric_type="energy"):
        if metric_type == "energy":
            # 'report_simulation_output.fuel_use_electricity_total_m_btu',
            return [
                f"report_simulation_output.fuel_use_{fu}_total_m_btu"
                for fu in self.fuels
            ]

        if metric_type == "emission":
            # 'report_simulation_output.emissions_co_2_e_lrmer_low_re_cost_25_2025_start_electricity_total_lb'
            return [
                f"report_simulation_output.emissions_co_2_e_{self.emission_type}_{fu}_total_lb"
                for fu in self.fuels
            ]

        if metric_type == "cbill":
            return [f"report_utility_bills.bills_{fu}_total_usd" for fu in self.fuels]

        if metric_type == "bill":
            return [f"bill_{fu}_usd" for fu in self.fuels]

        raise ValueError(
            f"metric_type={metric_type} unsupported. Valid only: [energy, emission, cbill, bill]"
        )

    @staticmethod
    def get_site_total_col(metric_type="energy"):
        if metric_type == "energy":
            return "report_simulation_output.energy_use_total_m_btu"
        if metric_type == "emission":
            return "report_simulation_output.emissions_co_2_e_lrmer_low_re_cost_25_2025_start_total_lb"
        if metric_type == "cbill":
            return "report_utility_bills.bills_total_usd" # from community input
        if metric_type == "bill":
            return "bill_total_usd"
        raise ValueError(f"metric_type={metric_type} unsupported")

    @staticmethod
    def get_upgrade_cost_col():
        return "upgrade_costs.upgrade_cost_usd"

    def get_fuel_use_cols_for_end_use(self, enduse, metric_type="energy"):
        if metric_type == "energy":
            # report_simulation_output.end_use_electricity_clothes_dryer_m_btu
            return [
                f"report_simulation_output.end_use_{fu}_{enduse}_m_btu"
                for fu in self.fuels
            ]

        if metric_type == "emission":
            # 'report_simulation_output.emissions_co_2_e_lrmer_low_re_cost_25_2025_start_electricity_total_lb'
            return [
                f"report_simulation_output.emissions_co_2_e_{self.emission_type}_{fu}_{enduse}_lb"
                for fu in self.fuels
            ]

        raise ValueError(
            f"metric_type={metric_type} supported. Valid only: [energy, emission]"
        )

    @staticmethod
    def simplify_column_names(df):
        df.index.names = [
            x.removeprefix("build_existing_model.") for x in df.index.names
        ]
        df.columns = [x.removeprefix("build_existing_model.") for x in df.columns]

        return df

    def load_file(self, pkg):
        if isinstance(pkg, int):
            pkg = str(pkg).zfill(2)
        if isinstance(pkg, str):
            assert isinstance(int(pkg), int), f"Non-digit pkg = {pkg}"
            assert len(pkg) == 2, f"pkg does not have 2 digit = {pkg}"
        found = sorted(self.euss_dir.rglob(f"up{pkg}__*"))

        if found:
            pqt_file = [file for file in found if file.suffix == ".parquet"]
            csv_file = [file for file in found if file.suffix == ".csv"]
            if len(pqt_file) == 1:
                file = pqt_file[0]
            elif len(csv_file) == 1:
                file = csv_file[0]
            else:
                raise ValueError(
                    f"Multiple possible files found for {pkg}: {found}. "
                    f"Please keep files in {self.euss_dir} in original naming conventions. "
                    "e.g., results_up00.parquet (preferred) or results_up00.csv"
                )

            print(f"Loading {file}...")
            df = read_file(file, valid_only=True, fix_dtypes=True)
            return df
        raise FileNotFoundError(f"Cannot locate file for pkg={pkg}")

    def load_results_baseline(self):
        return self.load_file(0)

    def load_results_upgrade(self, pkgs: list):

        dfb = self.load_results_baseline().set_index("building_id")

        if not isinstance(pkgs, list):
            if pkgs == 0:
                raise ValueError(
                    f"pkg={0} indicates baseline results, use self.load_results_baseline() instead"
                )
            df = self.load_file(pkgs).set_index("building_id")

            meta_cols = [col for col in dfb.columns if col not in df.columns]
            cond = dfb.index.intersection(df.index)

            return df.loc[cond].reset_index(), dfb.loc[cond].reset_index()

        if isinstance(pkgs, list):
            if 0 in pkgs:
                raise ValueError(
                    "cannot combined baseline results (pkg0) with upgrade results."
                )
            DFB, DF = [], []
            for pkg in pkgs:
                df = self.load_file(pkg).set_index("building_id")
                cond = dfb.index.intersection(df.index)
                DF.append(df.loc[cond])
                DFB.append(dfb.loc[cond])

            DF = pd.concat(DF, axis=0)
            DFB = pd.concat(DFB, axis=0)

            # adjust weight by number of package
            DFB["build_existing_model.sample_weight"] /= len(pkgs)
            DFB["sample_weight"] /= len(pkgs)

            return DF.reset_index(), DFB.reset_index()

        raise ValueError(f"Invalid input pkgs={pkgs}")

    def _adjust_upgrade_total_by_ignoring_end_uses(self, dfu, dfb, end_uses):
        """
        For example, to extract only the impact of HEAT PUMP + ENVELOPE from a full electrification
        package (i.e., heat pump, envelope, water heating, dryer, cooking), I can do so by
        overriding the following end uses in the upgrade df with baseline df
            - water heating
            - dryer
            - cooking
        effectively, nullifying their savings.

        Assumes the end use replacement above have negligible effects on HVAC loads
        even though they do impact heat pump sizing and HVAC loads with internal gains in real life

        Args:
            dfu : upgrade dataframe
            dfb : baseline dataframe
            end_uses : list(str) end uses to override back to baseline

        Returns:
            dfu2, with adjusted fuel use and total columns (no change on end_use cols)

        """
        dfu2 = dfu.copy()

        for metric in ["energy", "emission"]:
            cols_enduse = []
            for eu in end_uses:

                cols_enduse.append(
                    self.get_fuel_use_cols_for_end_use(
                        eu,
                        metric_type=metric,
                    )
                )
            fuel_cols = self.get_fuel_use_cols(metric)

            total_col = self.get_site_total_col(metric)

            for eu_cols, fuel_col, in zip(
                np.transpose(cols_enduse),
                fuel_cols,
            ):

                available_enduses = list(set(eu_cols).intersection(set(dfb.columns)))

                if len(available_enduses) > 0:
                    delta = dfb[available_enduses].sum(axis=1) - dfu[
                        available_enduses
                    ].sum(axis=1)
                    dfu2[fuel_col] += delta  # changing upgrade df
                    dfu2[total_col] += delta

        # get those without any upgrade to excluded end_uses and replace with dfu
        _, name_cols, _ = self._get_upgrade_costs_columns(dfu, end_uses)
        cond = dfu[name_cols].replace(na_rep).fillna("").sum(axis=1)  # replace None with ""
        cond = cond == ""  # where all cols are None
        dfu2.loc[cond] = dfu.loc[cond]

        # QC
        for metric in ["energy", "emission", "cbill"]:
            total_col = self.get_site_total_col(metric)
            cond2 = dfu2[total_col] == dfu[total_col]
            print(
                f"** totals | {cond2.sum()} / {len(dfu2)} {total_col} did not change when adjusting by subtracting: {end_uses}"
            )
            print(
                f"   Of the {(cond2 & ~cond).sum()} bldgs without upgrade to {end_uses}, the vacancy_status is: "
            )
            print(
                dfb.loc[
                    (cond2 & ~cond), "build_existing_model.vacancy_status"
                ].value_counts()
            )

        return dfu2

    def _adjust_upgrade_total_by_accounting_end_uses(self, dfu, dfb, end_uses):
        """
        For example, to extract only the impact of DRYER from a full electrification
        package (i.e., heat pump, envelope, water heating, dryer, cooking), I can do so by
        making a copy of the baseline df and replacing the following end use with that from upgrade df:
            - dryer

        Assumes the end use replacement above have negligible effects on HVAC loads
        even though they do impact heat pump sizing and HVAC loads with internal gains in real life

        Args:
            dfu : upgrade dataframe
            dfb : baseline dataframe
            end_uses : list(str) end uses to override back to baseline

        Returns:
            dfu2, with adjusted fuel use and total columns (no change on end_use cols)

        """
        output_cols = [col for col in dfu.columns if "report_simulation_output." in col]
        other_cols = [col for col in dfu.columns if col not in output_cols]

        dfu2 = pd.concat([dfu[other_cols], dfb[output_cols]], axis=1)[dfu.columns]

        for metric in ["energy", "emission"]:
            cols_enduse = []
            for eu in end_uses:

                cols_enduse.append(
                    self.get_fuel_use_cols_for_end_use(
                        eu,
                        metric_type=metric,
                    )
                )
            fuel_cols = self.get_fuel_use_cols(metric)

            total_col = self.get_site_total_col(metric)

            for eu_cols, fuel_col, in zip(
                np.transpose(cols_enduse),
                fuel_cols,
            ):

                available_enduses = list(set(eu_cols).intersection(set(dfb.columns)))

                if len(available_enduses) > 0:
                    delta = dfb[available_enduses].sum(axis=1) - dfu[
                        available_enduses
                    ].sum(axis=1)
                    dfu2[fuel_col] -= delta  # changing baseline df
                    dfu2[total_col] -= delta

        # get those with end_uses upgraded only and replace with dfu
        _, _, name_cols_else = self._get_upgrade_costs_columns(dfu, end_uses)
        cond = dfu[name_cols_else].replace(na_rep).fillna("").sum(axis=1)  # replace None with ""
        cond = cond == ""  # where all cols are None
        dfu2.loc[cond] = dfu.loc[cond]

        # QC
        for metric in ["energy", "emission"]:
            total_col = self.get_site_total_col(metric)
            cond2 = dfu2[total_col] == dfu[total_col]
            print(
                f"** totals | {cond2.sum()} / {len(dfu2)} {total_col} did not change when adjusting by extracting to: {end_uses}"
            )
            print(
                f"   Of the {(cond2 & ~cond).sum()} bldgs with upgrade to {end_uses} only, the vacancy_status is: "
            )
            print(
                dfb.loc[
                    (cond2 & ~cond), "build_existing_model.vacancy_status"
                ].value_counts()
            )

        return dfu2

    @staticmethod
    def _get_upgrade_costs_columns(dfu, end_uses):
        """return upgrade_costs.xxx columns pertinent to each end use in end_uses list
        Returns :
            cost_cols : list of upgrade_costs.option_xx_cost_usd pertinent to end_uses
            name_cols : list of upgrade_costs.option_xx_name pertinent to end_uses
            name_cols_else : list of upgrade_costs.option_xx_name NOT pertinent to end_uses
        """
        uc_name_cols = [
            col
            for col in dfu.columns
            if "upgrade_costs.option" in col and "name" in col
        ]

        cost_cols = []
        name_cols = []
        name_cols_else = []
        for col in uc_name_cols:
            option = [x for x in dfu[col].dropna().unique() if x not in na_rep.keys()]
            if len(option) > 0:
                option = option[0].lower().replace(" ", "_")
                for eu in end_uses:
                    if eu == "range_oven":
                        eu = "cooking_range"
                    if eu == "hot_water":
                        eu = "water_heater_efficiency"
                    if eu in option:
                        cost_col = col.replace("name", "cost_usd")
                        assert cost_col in dfu.columns, f"{cost_col} not in dfu columns"
                        name_cols.append(col)
                        cost_cols.append(cost_col)
                    else:
                        name_cols_else.append(
                            col
                        )  # retain name cols that are not on the ignore list

        return cost_cols, name_cols, name_cols_else

    def _adjust_upgrade_cost_by_ignoring_end_uses(self, dfu, dfb, end_uses):
        """Modify total upgrade cost column by subtracting upgrade costs for certain end uses

        Returns:
            dfu, with adjusted total upgrade cost col, subset to where upgrade(s) have been applied
            dfb, subset to where upgrade(s) have been applied
        """
        cost_cols, name_cols, name_cols_else = self._get_upgrade_costs_columns(
            dfu, end_uses
        )

        # QC 1
        assert (
            len(cost_cols) > 0
        ), f"{len(cost_cols)} upgrade_cost columns found for {end_uses}"

        # retain only those that have been upgraded
        cond = dfu[name_cols_else].replace(na_rep).fillna("").sum(axis=1)  # replace None with ""
        cond = cond != ""  # where not all cols are None

        if cond.sum() != len(dfu):
            print(
                f"* upgrade costs | When adjusting upgrade_costs by excluding: {end_uses}, "
                f"dfu is reducing from {len(dfu)} to {cond.sum()} bldgs"
            )

            dfu = dfu.loc[cond].reset_index(drop=True)
            dfb = dfb.loc[cond].reset_index(drop=True)

        # check number of bldgs that do NOT have any of the excluded end_uses upgraded

        cond = dfu[name_cols].replace(na_rep).fillna("").sum(axis=1)  # replace None with ""
        cond = cond == ""  # where all cols are None
        print(
            f"* upgrade costs | {cond.sum()} / {len(dfu)} do not have any upgrades to {end_uses}."
        )

        # calculate
        upgrade_costs = dfu[cost_cols].fillna(0).sum(axis=1)

        # QC 2 - okay to have 0 upgrade costs from end uses here
        cond = upgrade_costs == 0
        print(
            f"* upgrade costs | {cond.sum()} / {len(dfu)} have zero upgrade costs for {end_uses}"
        )
        cond = dfu.loc[cond, name_cols].replace(na_rep).fillna("").sum(axis=1)
        assert (
            cond != ""
        ).sum() == 0, (
            f"Zero upgrade costs do not correspond None upgrade names: {cond[cond!='']}"
        )

        # assign
        dfu[
            self.get_upgrade_cost_col()
        ] -= upgrade_costs  # subtract cost of these end uses from total

        # QC 3
        assert (
            dfu[self.get_upgrade_cost_col()] < 0
        ).sum() == 0, f"{(dfu[self.get_upgrade_cost_col()]<0).sum()} negative upgrade costs found!"

        return dfu, dfb

    def _adjust_upgrade_cost_by_accounting_end_uses(self, dfu, dfb, end_uses):
        """Modify total upgrade cost column by summing the upgrade costs for certain end uses

        Returns:
            dfu, with adjusted total upgrade cost col, subset to where upgrade(s) have been applied
            dfb, subset to where upgrade(s) have been applied
        """
        cost_cols, name_cols, name_cols_else = self._get_upgrade_costs_columns(
            dfu, end_uses
        )

        # QC 1
        assert (
            len(cost_cols) > 0
        ), f"{len(cost_cols)} upgrade_cost columns found for {end_uses}"

        # retain only those that have been upgraded
        cond = dfu[name_cols].replace(na_rep).fillna("").sum(axis=1)  # replace None with ""
        cond = cond != ""  # where not all cols are None

        if cond.sum() != len(dfu):
            print(
                f"* upgrade costs | When adjusting upgrade_costs by extracting to: {end_uses}, "
                f"dfu is reducing from {len(dfu)} to {cond.sum()} bldgs"
            )

            dfu = dfu.loc[cond].reset_index(drop=True)
            dfb = dfb.loc[cond].reset_index(drop=True)

        # check number of bldgs that ONLY have the end_uses upgraded
        if len(name_cols_else) == 0:
            # no other columns, so all have the end_uses upgraded
            n_applied = len(dfu)
        else:
            cond = dfu[name_cols_else].replace(na_rep).fillna("").sum(axis=1)  # replace None with ""
            cond = cond == ""  # where all cols are None
            n_applied = cond.sum()
        print(
            f"* upgrade costs | {n_applied} / {len(dfu)} have upgrade for {end_uses} only"
        )

        # calculate
        upgrade_costs = dfu[cost_cols].fillna(0).sum(axis=1)

        # QC 2
        assert (
            upgrade_costs == 0
        ).sum() == 0, (
            f"{(upgrade_costs==0).sum()} zero upgrade costs found for {end_uses}"
        )

        # assign
        dfu[self.get_upgrade_cost_col()] = upgrade_costs

        return dfu, dfb

    @staticmethod
    def map_col_by_bin(dfs, bin_edges, bin_labels):
        """
        map a continuous-value column based on bin_edges, each bin is left-edge inclusive

        Args :
        ------
            dfs : pd.Series
            bin_edges : list(float/int)
                list of ordered bin edges, required: len(bin_edges) + 1 = len(bin_labels)
            bin_labels : list(str)
                list of ordered bin labels ( first label: <bin_edges[0], last label: >=bin_edges[-1] )

        Returns :
        ---------
            df : pd.DataFrame

        """
        # validate bin_edges and bin_labels
        if len(bin_edges) + 1 != len(bin_labels):
            raise ValueError(
                "`bin_edges` must be one element shorter than `bin_labels`"
            )
        # validate that col_to_map is a continous numeric dtype
        if not pd.api.types.is_numeric_dtype(dfs):
            raise ValueError(
                f"dfs has invalid dtype={dfs.dtype}. "
                "column series needs to be a continous numeric column to be converted to bins"
            )

        dfo = dfs.copy()

        # map bins
        for lb, ub, label in zip(bin_edges[:-1], bin_edges[1:], bin_labels[1:-1]):
            dfo.loc[(dfs >= lb) & (dfs < ub)] = label
        # edges
        dfo.loc[dfs < bin_edges[0]] = bin_labels[0]
        dfo.loc[dfs >= bin_edges[-1]] = bin_labels[-1]

        return dfo

    def create_energy_burden_tag(self, df_col_to_map):
        eb_bins = [2, 4, 6, 8, 10]
        eb_labels = ["<2%", "2-4%", "4-6%", "6-8%", "8-10%", "10%+"]

        df_col_to_map[df_col_to_map == np.inf] = 1000

        n_na = df_col_to_map.isna().sum()
        assert n_na == 0, f"{n_na} NA found in energy_burden column"

        n_neg = (df_col_to_map < 0).sum()
        assert n_neg == 0, f"{n_neg} negative value(s) found in energy_burden column"

        return self.map_col_by_bin(df_col_to_map, eb_bins, eb_labels)

    @staticmethod
    def consolidate_misc_appliances(df):
        cols = [
            "build_existing_model.misc_extra_refrigerator",
            "build_existing_model.misc_freezer",
            "build_existing_model.misc_gas_fireplace",
            "build_existing_model.misc_gas_grill",
            "build_existing_model.misc_gas_lighting",
            "build_existing_model.misc_hot_tub_spa",
            "build_existing_model.misc_pool",
            "build_existing_model.misc_pool_heater",
            "build_existing_model.misc_pool_pump",
            "build_existing_model.misc_well_pump",
        ]
        ncols = len(cols)
        df["build_existing_model.number_misc_appliances"] = df[cols].apply(
            lambda x: ncols - len(x.isna()), axis=1
        )

        return df

    @staticmethod
    def consolidate_number_of_building_units(df):
        metric = "build_existing_model.geometry_building_number_units"

        df[metric] = df["build_existing_model.geometry_building_number_units_mf"]
        cond = (
            df["build_existing_model.geometry_building_type_recs"]
            == "Single-Family Attached"
        )
        df.loc[cond, metric] = df.loc[
            cond, "build_existing_model.geometry_building_number_units_sfa"
        ]
        df.loc[df[metric] == "None", metric] = "1"

        return df

    @staticmethod
    def consolidate_story(df):
        metric = "build_existing_model.geometry_story"
        df[metric] = df["build_existing_model.geometry_stories_low_rise"].map(
            {
                "1": "<4",
                "2": "<4",
                "3": "<4",
                "4+": "4+",
            }
        )
        cond = df[metric] == "4+"
        df.loc[cond, metric] = df.loc[
            cond, "build_existing_model.geometry_stories"
        ].map(
            {
                "<8": "4-7",
                "8+": "8+",
            }
        )
        return df

    @staticmethod
    def consolidate_horizontal_location(df):
        metric = "build_existing_model.geometry_building_horizontal_location"

        df[metric] = df["build_existing_model.geometry_building_horizontal_location_mf"]
        cond = df[metric] == "None"
        df.loc[cond, metric] = df.loc[
            cond, "build_existing_model.geometry_building_horizontal_location_sfa"
        ]
        df[metric].map(
            {
                "Left": "End",
                "Right": "End",
                "Middle": "Middle",
                "Not Applicable": "None",
                "None": "None",
            }
        )

        return df

    def create_state_climate_zone(self, df):
        df["build_existing_model.state_and_iecc_climate_zone"] = (
            df["build_existing_model.state"]
            + " "
            + df["build_existing_model.ashrae_iecc_climate_zone_2004"]
        )
        return df

    @staticmethod
    def get_key_meta_columns():
        return [
            "building_id",
            "build_existing_model.sample_weight",  #
            # 'build_existing_model.ahs_region',
            "build_existing_model.ashrae_iecc_climate_zone_2004",  #
            # 'build_existing_model.building_america_climate_zone',
            # 'build_existing_model.cec_climate_zone',
            "build_existing_model.census_division",
            "build_existing_model.census_region",
            "build_existing_model.city",
            "build_existing_model.clothes_dryer",  #
            "build_existing_model.clothes_washer",
            "build_existing_model.cooking_range",
            "build_existing_model.county",
            "build_existing_model.county_and_puma",
            "build_existing_model.dishwasher",
            "build_existing_model.ducts",  #
            "build_existing_model.federal_poverty_level",
            # 'build_existing_model.generation_and_emissions_assessment_region',
            "build_existing_model.geometry_attic_type",
            # 'build_existing_model.geometry_building_level_mf',
            "build_existing_model.geometry_building_type_acs",
            "build_existing_model.geometry_building_type_height",
            "build_existing_model.geometry_building_type_recs",  #
            # 'build_existing_model.geometry_floor_area',
            "build_existing_model.geometry_floor_area_bin",  #
            "build_existing_model.geometry_foundation_type",  #
            # 'build_existing_model.geometry_garage',
            # 'build_existing_model.geometry_wall_exterior_finish',
            "build_existing_model.geometry_wall_type",  #
            "build_existing_model.has_pv",
            "build_existing_model.heating_fuel",  #
            # 'build_existing_model.hot_water_fixtures',
            "build_existing_model.hvac_cooling_efficiency",  #
            "build_existing_model.hvac_cooling_partial_space_conditioning",
            "build_existing_model.hvac_cooling_type",  #
            "build_existing_model.hvac_has_ducts",  #
            "build_existing_model.hvac_has_shared_system",  #
            # 'build_existing_model.hvac_has_zonal_electric_heating',
            "build_existing_model.hvac_heating_efficiency",  #
            "build_existing_model.hvac_heating_type",  #
            "build_existing_model.hvac_heating_type_and_fuel",  #
            "build_existing_model.hvac_secondary_heating_efficiency",  #
            "build_existing_model.hvac_secondary_heating_type_and_fuel",  #
            "build_existing_model.hvac_shared_efficiencies",
            # 'build_existing_model.income',
            # 'build_existing_model.income_recs_2015',
            "build_existing_model.income_recs_2020",  #
            "build_existing_model.infiltration",  #
            "build_existing_model.insulation_ceiling",  #
            # 'build_existing_model.insulation_floor',
            "build_existing_model.insulation_foundation_wall",  #
            "build_existing_model.insulation_rim_joist",  #
            "build_existing_model.insulation_roof",  #
            # 'build_existing_model.insulation_slab',
            "build_existing_model.insulation_wall",  #
            # 'build_existing_model.interior_shading',
            # 'build_existing_model.iso_rto_region',
            "build_existing_model.lighting",
            # 'build_existing_model.location_region',
            # 'build_existing_model.mechanical_ventilation',
            "build_existing_model.occupants",
            # 'build_existing_model.orientation',
            # 'build_existing_model.overhangs',
            # 'build_existing_model.plug_loads',
            "build_existing_model.puma",
            "build_existing_model.puma_metro_status",
            # 'build_existing_model.reeds_balancing_area',
            "build_existing_model.refrigerator",
            # 'build_existing_model.roof_material',
            # 'build_existing_model.solar_hot_water',
            "build_existing_model.state",  #
            "build_existing_model.tenure",  #
            # 'build_existing_model.units_represented',
            # 'build_existing_model.usage_level',
            "build_existing_model.vacancy_status",
            # 'build_existing_model.vintage',
            "build_existing_model.vintage_acs",  #
            "build_existing_model.water_heater_efficiency",
            "build_existing_model.water_heater_fuel",  #
            # 'build_existing_model.water_heater_in_unit',
            # 'build_existing_model.window_areas',
            "build_existing_model.windows",  #
            "build_existing_model.area_median_income",  #
        ]

    def create_new_metadata_columns(self, dfb):

        cols = dfb.columns

        # dfb = self.consolidate_misc_appliances(dfb)
        dfb = self.consolidate_number_of_building_units(dfb)
        dfb = self.consolidate_story(dfb)
        # dfb = self.consolidate_horizontal_location(dfb)
        dfb = self.create_state_climate_zone(dfb)

        new_cols = [col for col in dfb.columns if col not in cols]

        return dfb, new_cols

    def get_data_baseline(self):
        """Extract technology savings based on input pkg lists


        Calculated metrics include:
            - baseline fuel use, fuel saving, percent saving + total energy equivalent
            - emissions equivalent + total emission equivalent
            - bill by fuel equivalent + total bill equivalent
            - baseline energy burden TAG based on 2019 utility rates
            - energy burden based on 2019 utility rates (income kept at 2019USD)

        """
        dfb = self.load_results_baseline()

        dfb, new_cols = self.create_new_metadata_columns(dfb)
        res_meta_cols = self.get_key_meta_columns() + new_cols
        res_energy_cols = self.get_fuel_use_cols("energy") + [
            self.get_site_total_col("energy")
        ]
        res_emission_cols = self.get_fuel_use_cols("emission") + [
            self.get_site_total_col("emission")
        ]
        res_cbill_cols = self.get_fuel_use_cols("cbill") + [
            self.get_site_total_col("cbill")
        ]
        fuels = self.fuels + ["total"]

        # output cols
        meta_cols = res_meta_cols #[x.removeprefix("build_existing_model.") for x in res_meta_cols]

        energy_cols = [f"baseline_energy.{fu}_{converted_units[fu]}" for fu in fuels]
        emission_cols = [f"baseline_emission.{fu}_kgCO2e" for fu in fuels]
        bill_cols = [f"baseline_bill.{fu}_usd" for fu in fuels]
        cbill_cols = [f"baseline_cbill.{fu}_usd" for fu in fuels]

        # Metered costs
        # fuel order: [electricity, NG, fuel oil, propane]
        fixed_annum = self.load_utility_fixed_metered_rates()

        variable_rates_2019 = self.load_utility_variable_rates(
            year=2019
        )  # list of pd.Series, $/kWh, $/therm, $/mmbtu, $/mmbtu
        variable_rates = self.load_utility_variable_rates(
            year=self.bill_year
        )  # list of pd.Series, $/kWh, $/therm, $/mmbtu, $/mmbtu

        # assemble
        # df = dfb[res_meta_cols].rename(columns=dict(zip(res_meta_cols, meta_cols)))
        df = dfb.copy()
        df["upgrade_name"] = "baseline"

        baseline_bill_for_energy_burden_tag = []
        for i, fu in enumerate(fuels):

            # get savings
            conv = conversion_factors_from_mmbtu[fu]
            df[energy_cols[i]] = dfb[res_energy_cols[i]] * conv

            conv = LB_TO_KG
            df[emission_cols[i]] = dfb[res_emission_cols[i]] * conv

            df[cbill_cols[i]] = dfb[res_cbill_cols[i]]

            if fu == "total":
                baseline_bill_for_energy_burden_tag = pd.concat(
                    baseline_bill_for_energy_burden_tag, axis=1
                ).sum(axis=1)

                df[bill_cols[i]] = df[bill_cols[:i]].sum(axis=1)
            else:
                conv = conversion_factors_from_mmbtu[fu]

                # get variable rates
                var_rate_2019 = dfb["build_existing_model.state"].map(
                    variable_rates_2019[i]
                )
                var_rate = dfb["build_existing_model.state"].map(variable_rates[i])

                bill_baseline_2019 = pd.Series(
                    np.where(
                        dfb[res_energy_cols[i]] > 0,
                        dfb[res_energy_cols[i]] * conv * var_rate_2019 + fixed_annum[i],
                        0,
                    ),
                    index=dfb.index,
                )
                baseline_bill_for_energy_burden_tag.append(bill_baseline_2019)

                bill_baseline = np.where(
                    dfb[res_energy_cols[i]] > 0,
                    dfb[res_energy_cols[i]] * conv * var_rate + fixed_annum[i],
                    0,
                )
                df[bill_cols[i]] = bill_baseline

        baseline_energy_burden_2019 = pd.Series(
            np.where(
                dfb["rep_income"] > 0,
                (
                    baseline_bill_for_energy_burden_tag.divide(dfb["rep_income"]) * 100
                ).round(2),
                np.where(
                    baseline_bill_for_energy_burden_tag == 0,
                    np.nan,
                    np.where(baseline_bill_for_energy_burden_tag > 0, np.inf, -np.inf),
                ),
            ),
            index=dfb.index,
        )

        # TODO: energy_burden tags
        df["rep_income"] = dfb["rep_income"]
        df["energy_burden"] = self.create_energy_burden_tag(baseline_energy_burden_2019)

        # energy burden based on self.bill_year bills
        df[f"baseline_energy_burden_{self.bill_year}_bills.%"] = np.where(
            dfb["rep_income"] > 0,
            (df["baseline_bill.total_usd"].divide(dfb["rep_income"]) * 100).round(2),
            np.where(
                df["baseline_bill.total_usd"] == 0,
                np.nan,
                np.where(df["baseline_bill.total_usd"] > 0, np.inf, -np.inf),
            ),
        )
        # energy burden based on community bills
        df[f"baseline_energy_burden_2023_cbills.%"] = np.where(
            dfb["rep_income"] > 0,
            (df["baseline_cbill.total_usd"].divide(dfb["rep_income"]) * 100).round(2),
            np.where(
                df["baseline_cbill.total_usd"] == 0,
                np.nan,
                np.where(df["baseline_cbill.total_usd"] > 0, np.inf, -np.inf),
            ),
        )

        # rearrange cols
        meta_cols = meta_cols + ["rep_income", "energy_burden"]
        metric_cols = [col for col in df.columns if col not in meta_cols]

        df = df[meta_cols + metric_cols]

        # df.to_csv(self.output_dir / f"baseline.csv", index=False) # <---
        print(f" - Completed baseline data complilation\n")

        return df

    def make_upgrade_adjustments(self, dfu, dfb, adjustment_type=None, end_uses=None):
        """For extracting totals for a certain technology or end use from package total"""
        if adjustment_type is None:
            return dfu, dfb

        assert (
            end_uses is not None
        ), f"adjustment_type={adjustment_type}, need to specify end_uses"

        if adjustment_type == "extract_end_uses":
            dfu, dfb = self._adjust_upgrade_cost_by_accounting_end_uses(
                dfu, dfb, end_uses
            )  # include downselecting to those that apply
            dfu = self._adjust_upgrade_total_by_accounting_end_uses(dfu, dfb, end_uses)
        elif adjustment_type == "extract_end_uses_by_excluding":
            dfu, dfb = self._adjust_upgrade_cost_by_ignoring_end_uses(
                dfu, dfb, end_uses
            )  # include downselecting to those that apply
            dfu = self._adjust_upgrade_total_by_ignoring_end_uses(dfu, dfb, end_uses)
        else:
            raise ValueError(
                f"Unsupported adjustment_type={adjustment_type}, "
                "valid=['extract_end_uses', 'extract_end_uses_by_excluding']"
            )

        return dfu, dfb

    def get_data(self, pkgs, pkg_name, adjustment_type=None, end_uses=None):
        """Extract technology savings based on input pkg lists

        Calculated metrics include:
            - baseline fuel use, fuel saving, percent saving + total energy equivalent
            - emissions equivalent + total emission equivalent
            - bill by fuel equivalent + total bill equivalent
            - baseline energy burden TAG based on 2019 utility rates
            - energy burden based on 2019 utility rates (income kept at 2019USD)

        """

        pkgn = re.sub("[^a-zA-Z0-9 \n\.]", "_", pkg_name).replace(" ", "_")
        output_file = self.output_dir / f"results__{pkgn}.parquet"

        if output_file.exists():
            print(
                f" --- Compiled data found, loading data directly for [[ {pkg_name} ]] using packages: {pkgs} --- "
            )
            df = pd.read_parquet(output_file)
            return df

        print(f" --- Compiling data for [[ {pkg_name} ]] using packages: {pkgs} --- ")

        if isinstance(pkgs, list):
            dfu, dfb = [], []
            for pkg in pkgs:
                fu, fb = self.load_results_upgrade(pkg)
                fu, fb = self.make_upgrade_adjustments(
                    fu, fb, adjustment_type=adjustment_type, end_uses=end_uses
                )
                dfu.append(fu)
                dfb.append(fb)

            dfu = pd.concat(dfu, axis=0).reset_index(drop=True)
            dfb = pd.concat(dfb, axis=0).reset_index(drop=True)
            del fu, fb
            # adjust weight by number of package
            dfb["build_existing_model.sample_weight"] /= len(pkgs)
            dfb["sample_weight"] /= len(pkgs)

        else:
            dfu, dfb = self.load_results_upgrade(pkgs)
            dfu, dfb = self.make_upgrade_adjustments(
                dfu, dfb, adjustment_type=adjustment_type, end_uses=end_uses
            )

        dfb, new_cols = self.create_new_metadata_columns(dfb)
        res_meta_cols = self.get_key_meta_columns() + new_cols
        res_energy_cols = self.get_fuel_use_cols("energy") + [
            self.get_site_total_col("energy")
        ]
        res_emission_cols = self.get_fuel_use_cols("emission") + [
            self.get_site_total_col("emission")
        ]
        fuels = self.fuels + ["total"]

        # output cols
        meta_cols = res_meta_cols #[x.removeprefix("build_existing_model.") for x in res_meta_cols]

        energy_cols = [f"baseline_energy.{fu}_{converted_units[fu]}" for fu in fuels]
        energy_svg_cols = [f"saving_energy.{fu}_{converted_units[fu]}" for fu in fuels]
        energy_svg_pct_cols = [f"pct_saving_energy.{fu}_%" for fu in fuels]

        emission_cols = [f"baseline_emission.{fu}_kgCO2e" for fu in fuels]
        emission_svg_cols = [f"saving_emission.{fu}_kgCO2e" for fu in fuels]
        emission_svg_pct_cols = [f"pct_saving_emission.{fu}_%" for fu in fuels]

        bill_cols = [f"baseline_bill.{fu}_usd" for fu in fuels]
        bill_svg_cols = [f"saving_bill.{fu}_usd" for fu in fuels]
        bill_svg_pct_cols = [f"pct_saving_bill.{fu}_%" for fu in fuels]

        # these will be calculated similarly to (state) bills
        cbill_cols = [f"baseline_cbill.{fu}_usd" for fu in fuels]
        cbill_svg_cols = [f"saving_cbill.{fu}_usd" for fu in fuels] # calc same as bill_svg_cols
        cbill_svg_pct_cols = [f"pct_saving_cbill.{fu}_%" for fu in fuels] # calc same as bill_svg_cols

        # State-level rates
        # Metered costs in fuel order: [electricity, NG, fuel oil, propane]
        fixed_annum = self.load_utility_fixed_metered_rates()

        variable_rates_2019 = self.load_utility_variable_rates(
            year=2019
        )  # list of pd.Series, $/kWh, $/therm, $/mmbtu, $/mmbtu
        variable_rates = self.load_utility_variable_rates(
            year=self.bill_year
        )  # list of pd.Series, $/kWh, $/therm, $/mmbtu, $/mmbtu

        # Community-level rates:
        comm_fixed_annum, comm_variable_rates = self.load_community_fixed_and_variable_rates()

        # assemble
        # df = dfb[res_meta_cols].rename(columns=dict(zip(res_meta_cols, meta_cols)))
        df = dfb.copy()
        df["upgrade_name"] = pkg_name
        df["upgrade_cost_usd"] = dfu[self.get_upgrade_cost_col()]  # TODO fix to subset

        baseline_bill_for_energy_burden_tag = []
        for i, fu in enumerate(fuels):

            # get savings
            conv = conversion_factors_from_mmbtu[fu]
            df[energy_cols[i]] = dfb[res_energy_cols[i]].fillna(0) * conv
            df[energy_svg_cols[i]] = (
                dfb[res_energy_cols[i]] - dfu[res_energy_cols[i]]
            ).fillna(
                0
            ) * conv  # positive saving = net decrease
            df[energy_svg_pct_cols[i]] = np.where(
                df[energy_cols[i]] > 0,
                (df[energy_svg_cols[i]].divide(df[energy_cols[i]]) * 100).round(2),
                np.where(
                    df[energy_svg_cols[i]] == 0,
                    np.nan,
                    np.where(df[energy_svg_cols[i]] > 0, np.inf, -np.inf),
                ),
            )

            conv = LB_TO_KG
            df[emission_cols[i]] = dfb[res_emission_cols[i]].fillna(0) * conv
            df[emission_svg_cols[i]] = (
                dfb[res_emission_cols[i]] - dfu[res_emission_cols[i]]
            ).fillna(
                0
            ) * conv  # positive saving = net decrease
            df[emission_svg_pct_cols[i]] = np.where(
                df[emission_cols[i]] > 0,
                (df[emission_svg_cols[i]].divide(df[emission_cols[i]]) * 100).round(2),
                np.where(
                    df[emission_svg_cols[i]] == 0,
                    np.nan,
                    np.where(df[emission_svg_cols[i]] > 0, np.inf, -np.inf),
                ),
            )

            if fu == "total":
                baseline_bill_for_energy_burden_tag = pd.concat(
                    baseline_bill_for_energy_burden_tag, axis=1
                ).sum(axis=1)

                df[bill_cols[i]] = df[bill_cols[:i]].sum(axis=1)
                df[bill_svg_cols[i]] = df[bill_svg_cols[:i]].sum(axis=1)
            else:
                conv = conversion_factors_from_mmbtu[fu]

                # get variable rates
                var_rate_2019 = dfb["build_existing_model.state"].map(
                    variable_rates_2019[i]
                )
                var_rate = dfb["build_existing_model.state"].map(variable_rates[i])

                bill_baseline_2019 = pd.Series(
                    np.where(
                        dfb[res_energy_cols[i]] > 0,
                        dfb[res_energy_cols[i]] * conv * var_rate_2019 + fixed_annum[i],
                        0,
                    ),
                    index=dfb.index,
                )
                baseline_bill_for_energy_burden_tag.append(bill_baseline_2019)

                bill_baseline = np.where(
                    dfb[res_energy_cols[i]] > 0,
                    dfb[res_energy_cols[i]] * conv * var_rate + fixed_annum[i],
                    0,
                )
                bill_upgrade = np.where(
                    dfu[res_energy_cols[i]] > 0,
                    dfu[res_energy_cols[i]] * conv * var_rate + fixed_annum[i],
                    0,
                )
                df[bill_cols[i]] = bill_baseline
                df[bill_svg_cols[i]] = (
                    bill_baseline - bill_upgrade
                )  # positive saving = net decrease

            df[bill_svg_pct_cols[i]] = np.where(
                df[bill_cols[i]] > 0,
                (df[bill_svg_cols[i]].divide(df[bill_cols[i]]) * 100).round(2),
                np.where(
                    df[bill_svg_cols[i]] == 0,
                    np.nan,
                    np.where(df[bill_svg_cols[i]] > 0, np.inf, -np.inf),
                ),
            )


            # community bills
            if fu == "total":
                df[cbill_cols[i]] = df[cbill_cols[:i]].sum(axis=1)
                df[cbill_svg_cols[i]] = df[cbill_svg_cols[:i]].sum(axis=1)
            else:
                conv = conversion_factors_from_mmbtu[fu]

                # get variable rates
                cvar_rate = comm_variable_rates[i]
                cbill_baseline = np.where(
                    dfb[res_energy_cols[i]] > 0,
                    dfb[res_energy_cols[i]] * conv * cvar_rate + comm_fixed_annum[i],
                    0,
                )
                cbill_upgrade = np.where(
                    dfu[res_energy_cols[i]] > 0,
                    dfu[res_energy_cols[i]] * conv * cvar_rate + comm_fixed_annum[i],
                    0,
                )
                df[cbill_cols[i]] = cbill_baseline
                df[cbill_svg_cols[i]] = (
                    cbill_baseline - cbill_upgrade
                )  # positive saving = net decrease

            df[cbill_svg_pct_cols[i]] = np.where(
                df[cbill_cols[i]] > 0,
                (df[cbill_svg_cols[i]].divide(df[cbill_cols[i]]) * 100).round(2),
                np.where(
                    df[cbill_svg_cols[i]] == 0,
                    np.nan,
                    np.where(df[cbill_svg_cols[i]] > 0, np.inf, -np.inf),
                ),
            )

        baseline_energy_burden_2019 = pd.Series(
            np.where(
                dfb["rep_income"] > 0,
                (
                    baseline_bill_for_energy_burden_tag.divide(dfb["rep_income"]) * 100
                ).round(2),
                np.where(
                    baseline_bill_for_energy_burden_tag == 0,
                    np.nan,
                    np.where(baseline_bill_for_energy_burden_tag > 0, np.inf, -np.inf),
                ),
            ),
            index=dfb.index,
        )

        # TODO: energy_burden tags
        df["rep_income"] = dfb["rep_income"]
        df["energy_burden"] = self.create_energy_burden_tag(baseline_energy_burden_2019)

        # energy burden based on self.bill_year bills
        df[f"baseline_energy_burden_{self.bill_year}_bills.%"] = np.where(
            dfb["rep_income"] > 0,
            (df["baseline_bill.total_usd"].divide(dfb["rep_income"]) * 100).round(2),
            np.where(
                df["baseline_bill.total_usd"] == 0,
                np.nan,
                np.where(df["baseline_bill.total_usd"] > 0, np.inf, -np.inf),
            ),
        )

        upgraded_bill = df["baseline_bill.total_usd"] - df["saving_bill.total_usd"]
        df[f"post-upgrade_energy_burden_{self.bill_year}_bills.%"] = np.where(
            dfb["rep_income"] > 0,
            (upgraded_bill.divide(dfb["rep_income"]) * 100).round(2),
            np.where(
                upgraded_bill == 0, np.nan, np.where(upgraded_bill > 0, np.inf, -np.inf)
            ),
        )

        # energy burden based on community bills
        df[f"baseline_energy_burden_2023_cbills.%"] = np.where(
            dfb["rep_income"] > 0,
            (df["baseline_cbill.total_usd"].divide(dfb["rep_income"]) * 100).round(2),
            np.where(
                df["baseline_cbill.total_usd"] == 0,
                np.nan,
                np.where(df["baseline_cbill.total_usd"] > 0, np.inf, -np.inf),
            ),
        )
        upgraded_bill = df["baseline_cbill.total_usd"] - df["saving_cbill.total_usd"]
        df[f"post-upgrade_energy_burden_2023_cbills.%"] = np.where(
            dfb["rep_income"] > 0,
            (upgraded_bill.divide(dfb["rep_income"]) * 100).round(2),
            np.where(
                upgraded_bill == 0, np.nan, np.where(upgraded_bill > 0, np.inf, -np.inf)
            ),
        )

        # rearrange cols
        meta_cols = meta_cols + ["rep_income", "energy_burden", "upgrade_name"]
        metric_cols = [col for col in df.columns if col not in meta_cols]

        df = df[meta_cols + metric_cols]

        # retain only 1 pkg worth of data by averaging
        if isinstance(pkgs, list):
            df = df.groupby(meta_cols)[metric_cols].mean().reset_index()
            df["build_existing_model.sample_weight"] *= len(pkgs)
            df["sample_weight"] *= len(pkgs)  # redo weight

        # df.to_parquet(output_file)
        print(f" - Completed {pkg_name} using packages: {pkgs}\n")

        return df

    def load_utility_variable_rates(self, year=2019):
        """output variable rate lookup by state for:
        - electricity: $/kWh
        - natural gas: $/therm
        - fuel oil: $/mmbtu
        - propane: $/mmbtu
        Data files from Res Facades project (Elaina.Present@nrel.gov)
        """
        if year == 2019:
            folder = "Res Facades v1 2019"
        elif year == 2021:
            folder = "Res Facades v2 2021"
        else:
            raise ValueError(
                f"Cannot find utility variable rates for year={year}. "
                "Available: 2019, 2021"
            )

        rates_dir = self.data_dir / folder

        vr_electricity = pd.read_csv(
            rates_dir / "Variable Elec Cost by State from EIA State Data.csv"
        ).set_index(["State"])["Variable Elec Cost $/kWh"]
        vr_natural_gas = pd.read_csv(rates_dir / "NG costs by state.csv").set_index(
            ["State"]
        )[
            "NG Cost without Meter Charge [$/therm]"
        ]  # has US
        vr_fuel_oil = pd.read_csv(
            rates_dir / "Fuel Oil Prices Averaged by State.csv"
        ).set_index(["State"])["Average FO Price [$/gal]"]
        vr_propane = pd.read_csv(rates_dir / "Propane costs by state.csv").set_index(
            ["State"]
        )["Average Weekly Cost [$/gal]"]

        assert (
            len(set(vr_electricity.index)) >= 50
        ), "Variable rate lookup for electricity is missing state(s)"
        assert (
            len(set(vr_natural_gas.index)) >= 50
        ), "Variable rate lookup for natural gas is missing state(s)"
        assert (
            len(set(vr_fuel_oil.index)) >= 50
        ), "Variable rate lookup for fuel oil is missing state(s)"
        assert (
            len(set(vr_propane.index)) >= 50
        ), "Variable rate lookup for propane is missing state(s)"

        # https://www.eia.gov/energyexplained/units-and-calculators/
        hc_fuel_oil = 137381 / 1e6  # mmbtu/gal (residential heating oil)
        hc_propane = 91452 / 1e6  # mmbtu/gal (propane)

        # $/kWh, $/therm, $/mmbtu, $/mmbtu
        return [
            vr_electricity,
            vr_natural_gas,
            vr_fuel_oil / hc_fuel_oil,
            vr_propane / hc_propane,
        ]

    @staticmethod
    def load_utility_fixed_metered_rates():
        """ by state """
        fixed_annum = [
            10 * 12,  # Nov 2021 Utility Rate Database
            11.25 * 12,  # American Gas Association (2015)
            0 * 12, # fuel oil
            0 * 12, # propane
        ]  # $/year # based on fixed charges derived for Res Facades (Elaina.Present@nrel.gov)
        return fixed_annum

    def load_community_fixed_and_variable_rates(self):
        cost = pd.read_csv(self.output_dir.parents[1] / "community_cost" / f"cost_{self.community}.csv")

        ele_price = cost.iat[38, 1] * CENTS_TO_DOLLARS  # c/kwh -> $/kwh
        ele_month_fix = cost.iat[38, 3]  # $/month
        gas_price = cost.iat[39, 1]  # $/therm
        gas_month_fix = cost.iat[39, 3]  # $/month
        propane_price = cost.iat[40, 1]  # $/gal
        propane_month_fix = cost.iat[40, 3]  # $/month
        oil_price = cost.iat[41, 1]  # $/gal
        oil_month_fix = cost.iat[41, 3]  # $/month

        # fuel order: [electricity, NG, fuel oil, propane]
        fixed_annum = [ele_month_fix, gas_month_fix, oil_month_fix, propane_month_fix]*12
        # $/kWh, $/therm, $/mmbtu, $/mmbtu
        var_rates = [ele_price, gas_price, oil_price/FUEL_OIL_HEAT_CONTENT, propane_price/PROPANE_HEAT_CONTENT]
        return fixed_annum, var_rates

###### main ######

def main(euss_dir):
    output_dir = Path(euss_dir)
    emission_type = "lrmer_low_re_cost_25_2025_start"
    bill_year = 2019

    SE = SavingsExtraction(euss_dir, emission_type, bill_year, output_dir=output_dir)
    # SE.add_ami_to_euss_files()

    # baseline
    DF = [SE.get_data_baseline()]

    # [1] Basic enclosure: all (pkg 1)
    DF.append(SE.get_data(1, "Basic Enclosure"))

    # [2] Enhanced enclosure: all (pkg 2)
    DF.append(
        SE.get_data(
            2,
            "Enhanced Enclosure",
        )
    )

    # [3] Heat pump – min eff: all (pkg 3)
    DF.append(
        SE.get_data(
            3,
            "Mininum Efficiency Heat Pump with Electric Heat Backup",
        )
    )

    # [4] Heat pump – high eff: all (pkg 4)
    DF.append(
        SE.get_data(
            4,
            "High Efficiency Heat Pump with Electric Heat Backup",
        )
    )

    # [5] Heat pump – min eff + existing backup: all (pkg 5)
    DF.append(
        SE.get_data(
            5,
            "Mininum Efficiency Heat Pump with Existing Heat Backup",
        )
    )

    # [6] Heat pump – high eff + HPWH + basic enclosure: Heating & Cooling (pkg 9)
    DF.append(
        SE.get_data(
            9,
            "Basic Enclosure + HPWH + High Efficiency HP/Electric Backup",
            adjustment_type="extract_end_uses_by_excluding",
            end_uses=["clothes_dryer", "range_oven"],
        )
    )

    # [7] Heat pump – high eff + HPWH+ enhanced enclosure: Heating & Cooling (pkg 10)
    DF.append(
        SE.get_data(
            10,
            "Enhanced Enclosure + HPWH + High Efficiency HP/Electric Backup",
            adjustment_type="extract_end_uses_by_excluding",
            end_uses=["clothes_dryer", "range_oven"],
        )
    )

    # [8] Heat pump water heater: all (pkg 6)
    DF.append(
        SE.get_data(
            6,
            "Heat Pump Water Heater",
        )
    )

    # [9] Electric dryer: Clothes dryer (pkg 7)
    DF.append(
        SE.get_data(
            7,
            "Electric Clothes Dryer",
            adjustment_type="extract_end_uses",
            end_uses=["clothes_dryer"],
        )
    )

    # [10] Heat pump dryer: Clothes dryer (pkg 8, 9, 10)
    DF.append(
        SE.get_data(
            [8, 9, 10],
            "Heat Pump Clothes Dryer",
            adjustment_type="extract_end_uses",
            end_uses=["clothes_dryer"],
        )
    )

    # [11] Electric cooking: Cooking (pkg 7)
    DF.append(
        SE.get_data(
            7,
            "Electric Cooking",
            adjustment_type="extract_end_uses",
            end_uses=["range_oven"],
        )
    )

    # [12] Induction cooking: Cooking (pkg 8, 9, 10)
    DF.append(
        SE.get_data(
            [8, 9, 10],
            "Induction Cooking",
            adjustment_type="extract_end_uses",
            end_uses=["range_oven"],
        )
    )

    ## rest of the full electrification packages
    # [13] pkg 7 - all
    DF.append(
        SE.get_data(
            7,
            "Mininum Efficiency Whole Home Electrification",
        )
    )
    # [14] pkg 8 - all
    DF.append(
        SE.get_data(
            8,
            "High Efficiency Whole Home Electrification",
        )
    )
    # [15] pkg 9 - all
    DF.append(
        SE.get_data(
            9,
            "Basic Enclosure + High Efficiency Whole Home Electrification",
        )
    )
    # [16] pkg 10 - all
    DF.append(
        SE.get_data(
            10,
            "Enhanced Enclosure + High Efficiency Whole Home Electrification",
        )
    )

    DF = pd.concat(DF, axis=0)

    # save to file
    DF.to_parquet(output_dir / "processed_upgrade_results.parquet")
    DF.to_csv(output_dir / "processed_upgrade_results.csv", index=False)

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "upgrade_run_result_directory",
        help=f"path to directory containing EUSS result csv files",
    )
    args = parser.parse_args()
    euss_dir = args.upgrade_run_result_directory
    main(euss_dir)
