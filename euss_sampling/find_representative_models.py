msg = """
This script is used to find the most "representative" or "typical" buildings from 
an existing result summary or buildstock file for a given set of selection criteria.

Use case example: find the representative electrically heated home in Maine from EUSS R1.0

By: Lixi.Liu@nrel.gov, Yingli.Lou@nrel.gov
Date: 09/12/2023
Updated: 09/12/2023
"""

import getpass
from pathlib import Path
import re
from itertools import chain
import json
import logging
import argparse
import numpy as np
import pandas as pd


def setup_logging(name, filename, file_level=logging.INFO, console_level=logging.INFO):
    global logger
    logger = logging.getLogger(name)
    logger.setLevel(logging.INFO)
    fh = logging.FileHandler(filename, mode="w")
    fh.setLevel(file_level)
    ch = logging.StreamHandler()
    ch.setLevel(console_level)
    formatter = logging.Formatter("%(asctime)s - %(levelname)s - %(message)s")
    fh.setFormatter(formatter)
    ch.setFormatter(formatter)
    # add the handlers to the logger
    logger.addHandler(fh)
    logger.addHandler(ch)


class BuildingSearch:
    def __init__(self, result_file, downselection_dict=None, file_type=None):
        """
        Args:
            result_file: str | pathlib.Path
                path to result_file to be search
            downselection_dict: dict | None
                logic for downselecting df of result_file before search
            file_type: str | None
                file type of result_file (for coordinating column name conversions)
                valid selections: ['buildstock', 'internal_dataset', 'oedi_dataset']
                if None, will be inferred from df of result_file
        """
        logger.info("==========================================================")
        logger.info(msg)
        logger.info("==========================================================")

        # initialize
        self.result_file = Path(result_file)
        result_df = self.read_file(result_file)

        if file_type is None:
            file_type = self.infer_file_type(result_df)
        self.file_type = self.validate_file_type(file_type)

        self.building_column = self.get_building_column()
        self.downselection = downselection_dict
        self.downselected_df = self.apply_downselection(result_df).set_index(
            self.building_column
        )
        (
            self.housing_characteristics,
            self.hc_prevalent_values,
        ) = self.extract_housing_characteristics_and_prevalent_values()

    def read_file(self, result_file):
        if result_file.suffix == ".parquet":
            return pd.read_parquet(result_file)
        if result_file.suffix == ".csv":
            return self.read_csv(result_file)
        raise NotImplementedError(
            f"Unsupported file_type for read_file(): {result_file.suffix}, valid=[.csv, .parquet]"
        )

    @staticmethod
    def read_csv(csv_file_path, **kwargs):
        default_na_values = pd._libs.parsers.STR_NA_VALUES
        df = pd.read_csv(
            csv_file_path,
            na_values=list(default_na_values - {"None"}),
            keep_default_na=False,
            **kwargs,
        )
        return df

    @staticmethod
    def infer_file_type(df):
        if [x for x in df.columns if "build_existing_model." in x]:
            return "internal_dataset"
        if [x for x in df.columns if "in." in x]:
            return "oedi_dataset"
        if "Geometry Building Type RECS" in df.columns:
            return "buildstock"
        raise ValueError(
            f"file_type cannot be inferred, consider specifying file_type, valid options: \n"
            " 'buildstock': dataframe contains columns that are capitalized with spaces, e.g., Vintage\n"
            " 'internal_dataset': dataframe contains columns with prefix 'build_existing_model.'\n"
            " 'oedi_dataset': dataframe contains columns with prefix 'in.'"
        )

    @staticmethod
    def validate_file_type(file_type):
        accepted_file_types = ["buildstock", "internal_dataset", "oedi_dataset"]
        if file_type in accepted_file_types:
            return file_type
        raise ValueError(
            f"Unsupported file_type={file_type}, valid: {accepted_file_types}"
        )

    def get_building_column(self):
        if self.file_type == "buildstock":
            return "Building"
        if self.file_type == "internal_dataset":
            return "building_id"
        if self.file_type == "oedi_dataset":
            return "bldg_id"

    @staticmethod
    def format_hc(hc):
        if isinstance(hc, list):
            return [
                "_".join(
                    [
                        x
                        for x in chain(
                            *[re.split("(\d+)", x) for x in y.lower().split(" ")]
                        )
                        if x not in ["", "-"]
                    ]
                )
                for y in hc
            ]
        elif isinstance(hc, str):
            return "_".join(
                [
                    x
                    for x in chain(
                        *[re.split("(\d+)", x) for x in hc.lower().split(" ")]
                    )
                    if x not in ["", "-"]
                ]
            )
        raise NotImplementedError(
            f"Input for format_hc() has type: {type(hc)} and is not supported"
        )

    def convert_to_oedi_format(self, hc):
        hc = self.format_hc(hc)
        if isinstance(hc, list):
            return [f"in.{x}" for x in hc]
        elif isinstance(hc, str):
            return f"in.{hc}"

    def convert_to_internal_format(self, hc):
        hc = self.format_hc(hc)
        if isinstance(hc, list):
            return [f"build_existing_model.{x}" for x in hc]
        elif isinstance(hc, str):
            return f"build_existing_model.{hc}"

    def format_downselection(self):
        if self.downselection is None:
            return
        if self.file_type == "buildstock":
            return self.downselection
        if self.file_type == "internal_dataset":
            return {
                self.convert_to_internal_format(key): val
                for key, val in self.downselection.items()
            }
        if self.file_type == "oedi_dataset":
            return {
                self.convert_to_oedi_format(key): val
                for key, val in self.downselection.items()
            }

    def apply_downselection(self, df):
        if self.downselection is None:
            return df

        downselection = self.format_downselection()

        condition = None
        for key, val in downselection.items():
            if isinstance(val, list):
                cond = df[key].isin(val)
            else:
                cond = df[key] == val
            if condition is None:
                condition = cond
            else:
                condition &= cond
        df = df.loc[condition].reset_index(drop=True)

        return df

    def get_housing_characteristics_list(self):
        if self.file_type == "buildstock":
            HC = [x for x in self.downselected_df.columns if x != self.building_column]

        if self.file_type == "internal_dataset":
            HC = [
                x
                for x in self.downselected_df.columns
                if x.startswith("build_existing_model.")
            ]
            not_HC = [
                "applicable",
                "weather_file",
                "weather_file",
                "emissions",
                "sample_weight",
                "simulation_control",
            ]
            for hc in not_HC:
                HC = [x for x in HC if hc not in x]
        if self.file_type == "oedi_dataset":
            HC = [x for x in self.downselected_df.columns if x.startswith("in.")]

        return HC

    def extract_housing_characteristics_and_prevalent_values(self):
        """
        Note: hc_list can have repeated hc if there are more than 1 most-common field value for that hc
        returns:
            hc_list: list
                list of housing characteristics from euss_bl
            common_hc: list
                most-common field value for each hc in hc_list
        """
        HC = self.get_housing_characteristics_list()

        # Extract all most prevalent features from self.downselected_df
        # if there are more than 1 most prevalent, repeat hc
        hc_list, common_hc = [], []
        for hc in HC:
            vals = self.downselected_df[hc].value_counts()
            common_vals = (vals[vals == vals.values[0]]).index.to_list()
            common_hc += common_vals
            hc_list += [hc for x in common_vals]

        return hc_list, common_hc

    def convert_hc_list(self, hc_list):
        if self.file_type == "internal_dataset":
            return self.convert_to_internal_format(hc_list)
        if self.file_type == "oedi_dataset":
            return self.convert_to_oedi_format(hc_list)

    def validate_hc(self, hc):
        if isinstance(hc, str):
            if hc not in self.downselected_df.columns:
                return True, hc
            else:
                return False, None
        if isinstance(hc, list):
            diff = set(hc) - set(self.downselected_df.columns)
            if len(diff) != 0:
                return True, diff
            else:
                return False, None
        raise ValueError("Unsupported input, cannot validate_hc()")

    def get_must_match_housing_characteristcs(self):
        hc = [
            "Geometry Building Type RECS",
            "Vintage ACS",
            "Geometry Floor Area Bin",
            "Heating Fuel",
            "State",
        ]
        formatted_hc = self.convert_hc_list(hc)
        error, dev = self.validate_hc(formatted_hc)
        if error:
            raise ValueError(
                f"Invalid hc in get_must_match_housing_characteristcs(): {dev}"
            )
        return hc, formatted_hc

    def get_prefer_match_housing_characteristics(self):
        hc = [
            "ASHRAE IECC Climate Zone 2004",
            "Geometry Wall Type",
            "Water Heater Fuel",
            "HVAC Heating Type",
            "HVAC Cooling Type",
        ]
        formatted_hc = self.convert_hc_list(hc)
        error, dev = self.validate_hc(formatted_hc)
        if error:
            raise ValueError(
                f"Invalid hc in get_prefer_match_housing_characteristcs(): {dev}"
            )
        return hc, formatted_hc

    def check_must_match_housing_characteristcs(self, dfs, must_match_hc=None):
        """Check how many hc in 'must_match_hc' is dfs matching
        Args:
            dfs: pd.Series
                row of dataframe to be checked

            must_match_hc: list | None
                list of housing characteristics that must be matched
                if None, default list is generated

        Returns:
            must_match_matched: list
                list of hc in must_match_hc that is matched by dfs
            must_match_missed: list
                list of hc in must_match_hc that is not matched by dfs
        """

        if must_match_hc is None:
            must_match_hc = self.get_must_match_housing_characteristcs()

        matched_hc = dfs.replace(False, np.nan).dropna().index
        must_match_matched = sorted(set(must_match_hc).intersection(set(matched_hc)))
        must_match_missed = sorted(set(must_match_hc) - set(matched_hc))
        logger.info(
            f" - id: {dfs.name} matched {len(must_match_matched)} / {len(must_match_hc)} must_match_hc"
        )
        if len(must_match_missed) > 0:
            logger.info(f"   but not matching: {must_match_missed}")

        return must_match_matched, must_match_missed

    def get_prevalent_values_of(self, hc_to_match):
        """Helper func to return the most common value for each hc in selected_hc"""

        selected_hc, selected_vals = [], []
        for hc in hc_to_match:
            idx = [i for i, x in enumerate(self.housing_characteristics) if x == hc]
            selected_vals += [self.hc_prevalent_values[x] for x in idx]
            selected_hc += [hc for x in idx]

        return selected_hc, selected_vals

    @staticmethod
    def count_matches(df, hc_to_match, common_vals):
        """Helper func to count the number of times each col in hc_to_match match the
        corresponding common_vals
        """
        assert len(hc_to_match) == len(
            common_vals
        ), "mistmatch between size of hc_to_match and common_vals"
        matched = []
        for hc, val in zip(hc_to_match, common_vals):
            matched.append(df[hc] == val)
        matched = pd.concat(matched, axis=1)
        total_matched = matched.sum(axis=1).sort_values(ascending=False)
        matched = matched.loc[total_matched.index]
        return matched, total_matched

    @staticmethod
    def get_index_of_most_matched(total_matched):
        """Helper func to get the index of all rows with the most number of matches"""
        max_matched_count = total_matched.sort_values(ascending=False).values[0]
        best_matched_idx = (
            total_matched[total_matched == max_matched_count]
        ).index.to_list()

        return max_matched_count, best_matched_idx

    def get_must_matched_buildings(self, df, must_match_hc=None):
        """Search within df for the list of building(s) that match ALL of the common values
        of must_match_hc

        Args:
            downselected_euss_bl: pd.DataFrame
                input result to search
            must_match_hc: list | None
                list of housing characteristics to search (must match)
                if None, get default list

        Returns:
            must_matched_df: pd.DataFrame
                result for must-matched building(s)
        """
        if must_match_hc is None:
            must_match_hc = self.get_must_match_housing_characteristcs()
        must_match_hc, must_match_common_hc = self.get_prevalent_values_of(
            must_match_hc
        )

        matched, total_matched = self.count_matches(
            df, must_match_hc, must_match_common_hc
        )

        # get buildings with all matches only
        must_matched_idx = (
            total_matched[total_matched == len(must_match_hc)]
        ).index.to_list()
        if must_matched_idx:
            must_matched_df = df.loc[must_matched_idx]
            logger.info(
                f"1. {len(must_matched_idx)} / {len(df)} {self.building_column}(s) have full match to must_match_hc"
            )
            return must_matched_df

        # if cannot match all must_match_hc
        max_matched_count, best_matched_idx = self.get_index_of_most_matched(
            total_matched
        )
        matched_content = (
            matched.loc[best_matched_idx]
            .replace(False, np.nan)
            .dropna(how="all", axis=1)
        )
        raise ValueError(
            f"1. No building found from input df that can match all must_match_hc\n"
            f"Only {max_matched_count} / {len(must_match_hc)} hc are matched: \n{matched_content}\n"
            "Conisider modifying must_match_hc"
        )

    def get_most_matched_buildings(self, df, hc_to_match):
        """Search within df for the list of building(s) matching the MOST number of
        common values of hc_list

        Args:
            df pd.DataFrame
                input result to search
            hc_list: list
                list of housing characteristics to search
                (can have duplicated values to support hc having multiple common_hc)
            common_hc: list
                most-common field value for each hc in hc_list
            must_match_hc: list | None
                list of housing characteristcs that must be matched

        Returns:
            best_matched_euss_bl: pd.DataFrame
                result for most-matched building(s)
            match_meet_criteria: bool
                whether the matched building(s) match all must_match_hc
        """
        hc_to_match, common_vals = self.get_prevalent_values_of(hc_to_match)
        matched, total_matched = self.count_matches(df, hc_to_match, common_vals)

        # get all building_ids with the most matches
        max_matched_count, best_matched_idx = self.get_index_of_most_matched(
            total_matched
        )
        best_matched_df = df.loc[best_matched_idx]
        return matched, max_matched_count, best_matched_idx, best_matched_df

    def get_prefer_matched_buildings(self, df, prefer_match_hc):
        (
            _,
            max_matched_count,
            best_matched_idx,
            best_matched_df,
        ) = self.get_most_matched_buildings(df, prefer_match_hc)
        if max_matched_count >= 1:
            logger.info(
                f"2. {len(best_matched_idx)} / {len(df)} {self.building_column}(s) have match for "
                f"up to {max_matched_count} / {len(prefer_match_hc)} prefer_match_hc"
            )
            return best_matched_df

        logger.info(
            f"2. No building found to match any prefer_match_hc: {prefer_match_hc}"
        )
        logger.info("   Returning input df")
        return df

    def get_final_matched_buildings(self, df, must_match_hc=None):
        (
            matched,
            max_matched_count,
            best_matched_idx,
            best_matched_df,
        ) = self.get_most_matched_buildings(df, self.housing_characteristics)

        logger.info(
            f"3. The best matched {self.building_column}(s) are: {best_matched_idx}, "
        )
        logger.info(
            f"   with each matching overall {max_matched_count} / {len(self.housing_characteristics)} housing characteristics"
        )

        # check must_match_hc status
        if must_match_hc is None:
            must_match_hc = self.get_must_match_housing_characteristcs()
        to_keep = []
        for idx, row in matched.loc[best_matched_idx].iterrows():
            (
                must_match_matched,
                must_match_missed,
            ) = self.check_must_match_housing_characteristcs(
                row, must_match_hc=must_match_hc
            )
            if must_match_missed:
                _, common_values_missed = self.get_prevalent_values_of(
                    must_match_missed
                )
                logger.info(best_matched_df.loc[row.name, must_match_missed])
                logger.info(
                    f"These must-match field values should be: {common_values_missed}"
                )
            else:
                to_keep.append(row.name)

        if to_keep:
            best_matched_df.loc[to_keep]
            match_meet_criteria = True
            logger.info(
                f"\n** Final best-matched {self.building_column}(s) meeting all must_match_hc are: {to_keep}"
            )
            logger.info(
                "Note: if there are more than 1 best-matched, pick one randomly as the 'most representative'"
            )
        else:
            match_meet_criteria = False
            logger.info(
                f"\n * No best-matched {self.building_column}s meeting all must_match_hc found, "
                "returning initial best-matched results based on match count"
            )

        return best_matched_df, match_meet_criteria

    def run_search(self, export_results=False):
        # Get default list of must_match_hc and prefer_match_hc
        (
            must_match_hc_unformatted,
            must_match_hc,
        ) = self.get_must_match_housing_characteristcs()
        (
            prefer_match_hc_unformatted,
            prefer_match_hc,
        ) = self.get_prefer_match_housing_characteristics()

        # report
        logger.info(f"Using result_file: {self.result_file}")
        logger.info(f"and downselection criteria:")
        logger.info(json.dumps(self.downselection, indent=4, sort_keys=True))
        logger.info(
            f"{len(self.downselected_df)} {self.building_column} were available to search "
            "by matching the most prevalent value of the following:"
        )
        logger.info(
            f" 1. {len(must_match_hc)} must-match housing characteristics (must_match_hc): \n\t{must_match_hc_unformatted}"
        )
        logger.info(
            f" 2. {len(prefer_match_hc)} prefer-match housing characteristics (prefer_match_hc): \n\t{prefer_match_hc_unformatted}"
        )
        logger.info(
            f" 3. Return {self.building_column}(s) with the highest matching count while meeting 1 and 2\n"
        )
        logger.info("Search result:")

        # Do matching
        must_matched_euss_bl = self.get_must_matched_buildings(
            self.downselected_df, must_match_hc=must_match_hc
        )
        prefer_matched_euss_bl = self.get_prefer_matched_buildings(
            must_matched_euss_bl, prefer_match_hc
        )
        final_matched_euss_bl, match_meet_criteria = self.get_final_matched_buildings(
            prefer_matched_euss_bl, must_match_hc=must_match_hc
        )

        # Export result
        if match_meet_criteria and export_results:
            output_file = (
                self.result_file.parent
                / "output__downselected_most_representative_building.csv"
            )
            final_matched_euss_bl.to_csv(output_file, index=True)
            logger.info(f"Downselected best-matched results output to: {output_file}")

        return final_matched_euss_bl


# Load EUSS results
if __name__ == "__main__":
    # setting for testing
    result_file_testing = "./ME_baseline_metadata_and_annual_results.csv"
    downselection_json_testing = "./downselection_logic.json"
    export_results_testing = False

    parser = argparse.ArgumentParser()
    parser.add_argument(
        "result_file",
        help="path of result_file, can be an annual summary file from OEDI, from ResStock, or a buildstock",
    )
    parser.add_argument(
        "downselection_json",
        nargs="?",
        help="path of downselection logic json file, optional",
    )
    parser.add_argument(
        "-x",
        "--export_results",
        action="store_true",
        help="whether to export downselected, best-matched results.",
    )
    parser.add_argument(
        "-t",
        "--testing",
        action="store_true",
        help="for testing, will override setting with the following defaults:\n"
        f"result_file='{result_file_testing}'\n"
        f"downselection_json='{downselection_json_testing}'\n"
        f"export_results={export_results_testing}",
    )

    args = parser.parse_args()

    result_file = args.result_file
    downselection_json = args.downselection_json
    export_results = args.export_results
    if args.testing:
        result_file = result_file_testing
        downselection_json = downselection_json_testing
        export_results = export_results_testing

    result_file = Path(result_file).resolve()
    if downselection_json:
        with open(downselection_json, "r") as f:
            downselection_dict = json.load(f)
    else:
        downselection_dict = None

    log_file = result_file.parent / f"output__building_search.log"
    setup_logging("Building Search", log_file)
    logger.info(f"Log file avaialble: {log_file}")
    if args.testing:
        logger.info(
            "TESTING mode, all settings are overriden to defaults, see --help for default settings"
        )

    BS = BuildingSearch(
        result_file, downselection_dict=downselection_dict, file_type=None
    )
    BS.run_search(export_results=export_results)
