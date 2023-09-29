from buildstock_query import BuildStockQuery
import polars as pl
from collections import defaultdict
from resstock import get_outcols, read_formatted_metadata_file
from metadata import process_upgrade
import polars.selectors as cs


class LARGEEE:
    def __init__(self, run_names: list[str],
                 db_name: str = "largeee_test_runs",
                 workgroup: str = "largeee",
                 state_split: bool = False) -> None:
        if "baseline" not in run_names[0]:
            raise ValueError("First run name must be baseline")

        self.run_names = run_names.copy()
        self.db_name = db_name
        self.workgroup = workgroup
        self.run_count = len(run_names)
        self.run_objs: dict[int, BuildStockQuery] = {}
        self.processed_bs_df, self.processed_all_up_df, self.combined_report_df = None, None, None
        self._get_run_objs()
        self.parquet_paths = self._download_parquets()
        self.outcols = get_outcols(list(set(self.parquet_paths.values())))
        if state_split:
            self.add_state_to_parquets()

    def _get_run_objs(self):
        for cat in range(0, len(self.run_names)):
            if cat == 0:
                table_name = self.run_names[0]
            else:
                table_name = f"{self.run_names[0]}_baseline", f"{self.run_names[cat]}_timeseries",\
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
                if int(upgrade) == 0:
                    local_path = self.run_objs[cat]._download_results_csv()
                else:
                    local_path = self.run_objs[cat]._download_upgrades_csv(upgrade_id=int(upgrade))
                parquet_paths[f"{cat}.{upgrade}"] = str(local_path)
                print(f"Run {cat} upgrade {upgrade} parquet downloaded")
        return parquet_paths

    def add_state_to_parquets(self):
        bs_df = read_formatted_metadata_file(self.parquet_paths['1.0'], 'baseline', self.outcols)
        bs_df = pl.scan_parquet(self.parquet_paths['1.0']).filter(pl.col("completed_status") == "Success")
        state_map_df = bs_df.select("building_id", "build_existing_model.state").collect()
        for upgrade_name, path in self.parquet_paths.items():
            if upgrade_name.endswith(".0"):  # skip baseline - they already have state
                continue
            if 'build_existing_model.state' in pl.scan_parquet(path).columns:
                print(f"Already has state: {upgrade_name}")
                continue
            up_df = pl.read_parquet(path)
            up_df = up_df.join(state_map_df, on="building_id", how="left")
            up_df.write_parquet(path)
            print(f"Updated {upgrade_name} with state")

    def get_bs_up_df(self, filter_states: list[str] | None = None,
                     column_selector: cs.SelectorType | None = None) -> tuple[pl.DataFrame, pl.DataFrame]:
        bs_df = read_formatted_metadata_file(self.parquet_paths['1.0'], 'baseline', self.outcols, filter_states)
        processed_bs_df = process_upgrade(bs_df)
        if column_selector is not None:
            processed_bs_df = processed_bs_df.select(column_selector)
        processed_up_df_list: list[pl.DataFrame] = []
        for upgrade_name, path in self.parquet_paths.items():
            if upgrade_name.endswith(".0"):  # skip baseline for each run
                continue
            if not filter_states:
                print(f"Processing {upgrade_name} at {path}.")
            else:
                print(f"Processing {upgrade_name} at {path} for {filter_states}")
            up_df = read_formatted_metadata_file(path, upgrade_name, self.outcols, filter_states)
            if up_df.select(pl.count()).collect().row(0) == (0,):
                print(f"Skipping {upgrade_name} - no data")
                continue
            p_up_df = process_upgrade(bs_df=bs_df, up_df=up_df)
            if column_selector is not None:
                p_up_df = p_up_df.select(column_selector)
            processed_up_df_list.append(p_up_df.collect())
        processed_all_up_df = pl.concat(processed_up_df_list, how='diagonal')
        return processed_bs_df.collect(), processed_all_up_df

    def get_upgrade_names(self):
        upgrade_name_dict = defaultdict(list)
        for upgrade_num, path in self.parquet_paths.items():
            if upgrade_num.endswith(".0"):  # skip baseline for each run
                continue
            upgrade_name = (pl.scan_parquet(path)
                            .filter(pl.col("completed_status") == "Success")
                            .select("apply_upgrade.upgrade_name")
                            .first().collect().row(0)[0]
                            )
            upgrade_name_dict['upgrade'].append(upgrade_num)
            upgrade_name_dict['upgrade_name'].append(upgrade_name)
        return pl.from_dict(upgrade_name_dict)

    def get_combined_upgrade_report(self) -> pl.DataFrame:
        report_dfs = []
        for cat in range(1, len(self.run_names)):
            pd_report_df = self.run_objs[cat].report.get_success_report()
            schema = {col: pl.Int64 if "%" not in col else pl.Float64 for col in pd_report_df.columns}
            report_df = pl.from_pandas(pd_report_df, include_index=True, schema_overrides=schema)
            report_df = report_df.with_columns(pl.concat_str(pl.lit(f"{cat}."), pl.col('upgrade')).alias("upgrade"))
            report_dfs.append(report_df)
        # _, up_df = self.get_bs_up_df()
        combined_report_df = pl.concat(report_dfs, how='diagonal')
        name_df = self.get_upgrade_names()
        # name_df = up_df.select("upgrade", "out.params.upgrade_name").unique(maintain_order=True).collect()
        combined_report_df = combined_report_df.join(name_df, on="upgrade", how="left")
        return combined_report_df
