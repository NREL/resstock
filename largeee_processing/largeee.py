from buildstock_query import BuildStockQuery
import pandas as pd
import polars as pl
import re
import json
from resstock import get_outcols, get_bs_metadata_and_annual, get_up_annual
from metadata import process_upgrade
import polars.selectors as cs


class LARGEEE:
    def __init__(self, run_names: list[str],
                 db_name: str = "largeee_test_runs",
                 workgroup: str = "largeee") -> None:
        if "baseline" not in run_names[0]:
            raise ValueError("First run name must be baseline")

        self.run_names = run_names.copy()
        self.db_name = db_name
        self.workgroup = workgroup
        self.run_count = len(run_names)
        self.run_objs: dict[int, BuildStockQuery] = {}
        self.parquet_paths = dict()
        self.processed_bs_df, self.processed_all_up_df, self.combined_report_df = None, None, None
        self._get_run_objs()
        self._download_parquets()

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
        for cat in range(0, len(self.run_names)):
            available_upgrades = self.run_objs[cat].get_available_upgrades()
            for upgrade in available_upgrades:
                if int(upgrade) == 0:
                    local_path = self.run_objs[cat]._download_results_csv()
                else:
                    local_path = self.run_objs[cat]._download_upgrades_csv(upgrade_id=int(upgrade))
                self.parquet_paths[f"{cat}.{upgrade}"] = str(local_path)
                print(f"Run {cat} upgrade {upgrade} parquet downloaded")

    def get_bs_up_df(self, states: list[str] = []) -> tuple[pl.LazyFrame, pl.LazyFrame]:
        if self.processed_bs_df is not None and self.processed_all_up_df is not None:
            return self.processed_bs_df, self.processed_all_up_df
        outcols = get_outcols(list(set(self.parquet_paths.values())))
        bs_df = get_bs_metadata_and_annual(self.parquet_paths['1.0'], outcols)
        self.processed_bs_df = process_upgrade(bs_df)
        processed_up_df_list = []
        for upgrade_name, path in self.parquet_paths.items():
            if upgrade_name.endswith(".0"):  # skip baseline for each run
                continue
            print(f"Processing {upgrade_name}")
            up_df = get_up_annual(path, upgrade_name=upgrade_name, outcols=outcols)
            p_up_df = process_upgrade(bs_df=bs_df, up_df=up_df)
            processed_up_df_list.append(p_up_df)
        self.processed_all_up_df = pl.concat(processed_up_df_list, how='diagonal')
        return self.processed_bs_df, self.processed_all_up_df

    def get_combined_upgrade_report(self) -> pl.DataFrame:
        if self.combined_report_df is not None:
            return self.combined_report_df
        report_dfs = []
        for cat in range(1, len(self.run_names)):
            pd_report_df = self.run_objs[cat].report.get_success_report()
            schema = {col: pl.Int64 if "%" not in col else pl.Float64 for col in pd_report_df.columns}
            report_df = pl.from_pandas(pd_report_df, include_index=True, schema_overrides=schema)
            report_df = report_df.with_columns(pl.concat_str(pl.lit(f"{cat}."), pl.col('upgrade')).alias("upgrade"))
            report_dfs.append(report_df)
        _, up_df = self.get_bs_up_df()
        combined_report_df = pl.concat(report_dfs, how='diagonal')
        name_df = up_df.select("upgrade", "out.params.upgrade_name").unique(maintain_order=True).collect()
        self.combined_report_df = combined_report_df.join(name_df, on="upgrade", how="left")
        return self.combined_report_df
