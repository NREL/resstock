from buildstock_query import BuildStockQuery
import polars as pl
from resstock import get_outcols, read_formatted_metadata_file
from metadata import process_upgrade
from polars.type_aliases import SelectorType
from typing import Union, Optional
import pandas as pd

class LARGEEE:
    def __init__(self, run_names: list[str],
                 db_name: str = "largeee_test_runs",
                 workgroup: str = "largeee",
                 filter_yamls: Optional[dict[int, str]] = None,
                 opt_sat_path: Optional[str] = None,
                 state_split: bool = False,
                 skip_parquet_download: bool = False) -> None:
        """
        A class to manage the processing of LARGEEE run consisting of series of individual upgrade runs (also
        called categories).

        Args:
            run_names: List of athena table names for the upgrade runs. First one is considered the baseline
            db_name: Athena database name where the runs reside.
            workgroup: Athena workgroup
            filter_yamls: A dictionary mapping run_number (or category number) which is the index of
                of the run in the run_names list to a upgrades filter yaml.
            opt_sat_path: Path to the options_saturation.csv file. Required when using filter_yamls.
            state_split: Whether to generate separate group of files for different state or one combined national file.
                If set to true, the class will add state to all parquet files (for each upgrade) for easy spliting.
            skip_parquet_download: Normally, the class will download the upgrade and baseline parquet files for
                all the runs during initialization. Sometimes it's useful to skip this step (eg. for quicklook).
        """

        self.run_names = run_names.copy()
        self.db_name = db_name
        self.workgroup = workgroup
        self.run_count = len(run_names)
        self.run_objs: dict[int, BuildStockQuery] = {}
        self.processed_bs_df, self.processed_all_up_df, self.combined_report_df = None, None, None
        self._get_run_objs()
        self.filter_yamls = filter_yamls or {}
        self.opt_sat_path = opt_sat_path
        if not skip_parquet_download:
            self.parquet_paths = self._download_parquets()
            self.outcols = get_outcols(list(set(self.parquet_paths.values())))
            if state_split:
                self.add_state_to_parquets()

    def _add_electrification_adder(self, bs_df: pl.DataFrame, up_df: pl.DataFrame):
        bs_chars = ["in.heating_fuel", "in.hvac_cooling_efficiency", "in.hvac_heating_efficiency",
                    "in.clothes_dryer", "in.cooking_range", "in.misc_pool_heater",
                    "in.hvac_cooling_type", "in.water_heater_fuel", "in.hvac_secondary_heating_fuel"]
        char_df = bs_df.select(["bldg_id"] + bs_chars)
        up_df = up_df.join(char_df, on="bldg_id", how="left")
        up_df = up_df.with_columns(
            pl.when(
                (
                    pl.col("upgrade.hvac_heating_efficiency").str.contains("ASHP|MSHP") &
                    ~pl.col("in.heating_fuel").str.contains("Electricity")
                )
                |
                (
                    pl.col("upgrade.hvac_cooling_efficiency").str.contains("SEER|Pump") &
                    pl.col("in.hvac_cooling_efficiency").str.contains("None")
                )
                |
                (
                    pl.col("upgrade.clothes_dryer").str.contains("Electric") &
                    ~pl.col("in.clothes_dryer").str.contains("Electric")
                )
                |
                (
                    pl.col("upgrade.cooking_range").str.contains("Electric") &
                    ~pl.col("in.cooking_range").str.contains("Electric")
                )
                |
                (
                    pl.col("upgrade.misc_pool_heater").str.contains("Electric") &
                    ~pl.col("in.misc_pool_heater").str.contains("Electric")
                )
                |
                (
                    pl.col("upgrade.hvac_cooling_type").str.contains("Central AC") &
                    pl.col("in.hvac_cooling_type").str.contains("None")
                )
                |
                (
                    pl.col("upgrade.water_heater_fuel").str.contains("Electric") &
                    ~pl.col("in.water_heater_fuel").str.contains("Electric")
                )
                |
                (
                    pl.col("upgrade.heating_fuel").str.contains("Electric") &
                    ~pl.col("in.heating_fuel").str.contains("Electric")
                )
                |
                (
                    pl.col("upgrade.hvac_secondary_heating_fuel").str.contains("Electric") &
                    ~pl.col("in.hvac_secondary_heating_fuel").str.contains("Electric")
                )
            ).then(pl.lit(True)).otherwise(pl.lit(False)).alias("upgrade.needs_electrification_update")
        )
        return up_df.select(pl.exclude(bs_chars))

    def _get_run_objs(self):
        for cat in range(0, len(self.run_names)):
            if cat == 0:
                table_name = self.run_names[0]
            else:
                table_name = f"{self.run_names[0]}_baseline", f"{self.run_names[cat]}_timeseries", \
                    f"{self.run_names[cat]}_upgrades"
            self.run_objs[cat] = BuildStockQuery(workgroup=self.workgroup,
                                                 db_name=self.db_name,
                                                 table_name=table_name)
            print(f"Run obj {cat} created")

    def _download_parquets(self):
        parquet_paths = dict()
        for cat in range(0, len(self.run_names)):
            available_upgrades = self.run_objs[cat].get_available_upgrades()
            for upgrade in available_upgrades:
                upgrade = int(upgrade)
                if int(upgrade) == 0:
                    local_path = self.run_objs[cat]._download_results_csv()
                else:
                    local_path = self.run_objs[cat]._download_upgrades_csv(upgrade_id=int(upgrade))
                parquet_paths[f"{cat}.{upgrade:02d}"] = str(local_path)
                print(f"Run {cat} upgrade {upgrade} parquet downloaded")
        return parquet_paths

    def add_state_to_parquets(self):
        bs_df = read_formatted_metadata_file(self.parquet_paths['1.00'], 'baseline', self.outcols)
        bs_df = pl.scan_parquet(self.parquet_paths['1.00']).filter(pl.col("completed_status") == "Success")
        state_map_df = bs_df.select("building_id", "build_existing_model.state").collect()
        for upgrade_name, path in self.parquet_paths.items():
            if upgrade_name.endswith(".00"):  # skip baseline - they already have state
                continue
            if 'build_existing_model.state' in pl.scan_parquet(path).columns:
                print(f"Already has state: {upgrade_name}")
                continue
            up_df = pl.read_parquet(path)
            up_df = up_df.join(state_map_df, on="building_id", how="left")
            up_df.write_parquet(path)
            print(f"Updated {upgrade_name} with state")

    def get_bs_up_df(self, filter_states: list[str] | None = None,
                     column_selector: Union[SelectorType, None] = None,
                     ugprade_filters: dict[str, str] | None = None,) -> tuple[pl.DataFrame, pl.DataFrame]:
        bs_df = read_formatted_metadata_file(self.parquet_paths['1.00'], 'baseline', self.outcols, filter_states)
        processed_bs_df = process_upgrade(bs_df)
        if column_selector is not None:
            processed_bs_df = processed_bs_df.select(column_selector)
        final_bs_df = processed_bs_df.collect()
        processed_up_df_list: list[pl.DataFrame] = []
        for cat in range(0, len(self.run_names)):
            available_upgrades = self.run_objs[cat].get_available_upgrades()
            if (filter_yaml := self.filter_yamls.get(cat)) and (self.opt_sat_path is not None):
                ua = self.run_objs[cat].get_upgrades_analyzer(filter_yaml_file=filter_yaml,
                                                              opt_sat_file=self.opt_sat_path)
                ua_report = ua.get_report().set_index('upgrade')
                removal_bldgs = ua_report['removal_buildings'].map(lambda x: set() if pd.isna(x) else x)

            for upgrade in available_upgrades:
                upgrade = int(upgrade)
                upgrade_name = f"{cat}.{upgrade:02}"
                if upgrade == 0:  # skip baseline for each run
                    continue
                path = self.parquet_paths.get(upgrade_name)
                if not filter_states:
                    print(f"Processing {upgrade_name} at {path}.")
                else:
                    print(f"Processing {upgrade_name} at {path} for {filter_states}")
                up_df = read_formatted_metadata_file(path, upgrade_name, self.outcols, filter_states)
                if filter_yaml:
                    # up_df = up_df.filter(pl.col())
                    up_df = up_df.filter(~pl.col('bldg_id').is_in(removal_bldgs.loc[upgrade]))
                if up_df.select(pl.count()).collect().row(0) == (0,):
                    print(f"Skipping {upgrade_name} - no data")
                    continue
                p_up_df = process_upgrade(bs_df=bs_df, up_df=up_df)
                if column_selector is not None:
                    p_up_df = p_up_df.select(column_selector)
                processed_up_df_list.append(p_up_df.collect())
        processed_all_up_df = pl.concat(processed_up_df_list, how='diagonal')
        processed_all_up_df = self._add_electrification_adder(final_bs_df, processed_all_up_df)
        return final_bs_df, processed_all_up_df

    def get_upgrade_names(self):
        up_name_dfs = [pl.DataFrame({"upgrade": ["1.00"], "upgrade_name": ["Baseline"]})]
        for cat in range(1, len(self.run_names)):
            up_names = self.run_objs[cat].get_upgrade_names()
            up_names = [{"upgrade": f"{cat}.{int(up_num):02}", "upgrade_name": up_name}
                        for up_num, up_name in up_names.items()]
            up_name_dfs.append(pl.from_dicts(up_names))
            self.run_objs[cat].save_cache()
            print(f"Got name for {cat=}")
        return pl.concat(up_name_dfs, how='diagonal')

    def get_combined_upgrade_report(self) -> pl.DataFrame:
        report_dfs = []
        for cat in range(1, len(self.run_names)):
            pd_report_df = self.run_objs[cat].report.get_success_report()
            schema = {col: pl.Int64 if "%" not in col else pl.Float64 for col in pd_report_df.columns}
            report_df = pl.from_pandas(pd_report_df, include_index=True, schema_overrides=schema)
            report_df = report_df.with_columns(pl.concat_str(pl.lit(f"{cat}."),
                                                             pl.col('upgrade').cast(str).str.zfill(2)).alias("upgrade"))
            report_dfs.append(report_df)
        combined_report_df = pl.concat(report_dfs, how='diagonal')
        name_df = self.get_upgrade_names()
        combined_report_df = combined_report_df.join(name_df, on="upgrade", how="left")
        return combined_report_df
