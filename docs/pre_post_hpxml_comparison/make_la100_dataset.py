"""
# Create Aggregate Dataset For LA-100ES
- - - - - - - - -

**Authors:**
- Lixi.Liu@nrel.gov
- Anthony.Fontanini@nrel.gov
"""

import sys
import os
from pathlib import Path
import numpy as np
import pandas as pd
import boto3

from eulpda.smart_query.EULPAthena import EULPAthena
import eulpcv.resstock_enduse_categories as enduse_categories
import eulpcv.hpxml_resstock_enduse_categories as hpxml_enduse_categories


class AggregateDataLA:
    def __init__(self):
        """
        Initialize object to query and combine comparison data for LA100
        """
        # Initialize
        datadir = Path(__file__).resolve().parent / "data"
        datadir.mkdir(parents=True, exist_ok=True)

        # [1] raw data (outside of ResStock queries, e.g., LRD and old LA-100 data)
        self.raw_datadir = datadir / "raw_data"
        if not self.raw_datadir.exists():
            self.download_directory_from_s3(
                bucket="la-100",
                prefix="pre_post_hpxml_comparison/old_data_for_comparison",
                local=self.raw_datadir,
            )

        # [2] output directory for baseline data comparison
        self.baseline_datadir = datadir / "la100_baseline"
        self.baseline_datadir.mkdir(parents=True, exist_ok=True)

        print(f"\nraw data directory: {self.raw_datadir}")
        print(f"data directory for baseline output: {self.baseline_datadir}\n")

    @staticmethod
    def download_directory_from_s3(bucket, prefix, local):
        """
        params:
        - prefix: pattern to match in s3
        - local: local path to folder in which to place files
        - bucket: s3 bucket with target contents
        """
        keys = []
        dirs = []
        next_token = ""
        base_kwargs = {
            "Bucket": bucket,
            "Prefix": prefix,
        }
        client = boto3.client("s3")
        while next_token is not None:
            kwargs = base_kwargs.copy()
            if next_token != "":
                kwargs.update({"ContinuationToken": next_token})
            results = client.list_objects_v2(**kwargs)
            contents = results.get("Contents")
            for i in contents:
                k = i.get("Key")
                if k[-1] != "/":
                    keys.append(k)
                else:
                    dirs.append(k)
            next_token = results.get("NextContinuationToken")
        for k in keys:
            dest_pathname = os.path.join(local, k.split(prefix)[1][1:])
            if not os.path.exists(os.path.dirname(dest_pathname)):
                os.makedirs(os.path.dirname(dest_pathname))
                print(os.path.dirname(dest_pathname))

            if not os.path.exists(dest_pathname):
                print("Downloading %s ..." % k.split(prefix)[1][1:])
                client.download_file(bucket, k, dest_pathname)

    def process_lrd_data(self, lrd_year=2012):
        file = self.raw_datadir / f"la100_lrd_{lrd_year}.csv"
        df_lrd = pd.read_csv(file)

        df_lrd["timestamp"] = pd.to_datetime(df_lrd["Dt"]) + df_lrd["Hour"].apply(
            lambda x: pd.Timedelta(x - 1, unit="h")
        )  # make period-beginning
        df_lrd = df_lrd[["timestamp", "Residential"]].rename(
            columns={"Residential": "kwh"}
        )
        df_lrd["run"] = f"{lrd_year}_LRD"
        df_lrd["cohort"] = "Total Residential Stock"
        df_lrd["enduse_category"] = "total"
        df_lrd["dwelling_units"] = np.nan
        df_lrd["kwh_per_unit"] = np.nan

        return df_lrd

    def process_old_la_result(self):
        table_name = "2015_reference_old_la100"
        df_old = pd.read_csv(
            self.raw_datadir / "old_la100_reference_2015.csv", parse_dates=["timestamp"]
        )

        # set up enduse_dict
        enduse_dict_la = {
            key: val
            for key, val in enduse_categories.enduse_category_dict().items()
            if key in df_old
        }
        # assign gap energy to cooling
        enduse_dict_la["electricity_gap_kwh"] = "cooling"

        df_old["total_site_electricity_kwh"] = df_old[enduse_dict_la.keys()].sum(axis=1)
        enduse_dict_la["total_site_electricity_kwh"] = "total"

        # reduce data dimensions
        df_old = self.resample_data(
            df_old,
            freq="1h",
            make_period_beginning=False,
            time_col="timestamp",
            count_cols=[],
            enduse_cols=list(enduse_dict_la.keys()),
        )
        df_old = self.combine_end_uses(df_old, enduse_dict_la)

        # format for aggregation
        enduses = [x for x in df_old.columns if x not in ["timestamp"]]
        df_old = pd.melt(
            df_old,
            id_vars=["timestamp"],
            value_vars=enduses,
            var_name="enduse_category",
            value_name="kwh",
        )
        df_old["run"] = table_name
        df_old["cohort"] = "Total Residential Stock"
        # <--- Tony said 1.13 million but seems to high
        df_old["dwelling_units"] = 1 * 1e6
        df_old["kwh_per_unit"] = df_old["kwh"].divide(df_old["dwelling_units"])

        return df_old

    def query_old_resstock_run_baseline(self, dwelling_units):
        """ Query baseline timeseries from old_resstock run

        Args:
            dwelling_units (int or float) : number of dwelling_units to renormalize end use demands to (dwelling_units = scaled_unit_count)

        Returns:
            df_sim (pd.DataFrame) : dataframe after adjustments

        """
        table_name = "2012_old_resstock_mshp_run"

        # set up enduse_dict
        enduses_not_available = [
            "electricity_central_system_pumps_heating_kwh",
            "electricity_central_system_pumps_cooling_kwh",
            "electricity_central_system_heating_kwh",
            "electricity_central_system_cooling_kwh",
        ]
        enduse_dict = {
            key: val
            for key, val in enduse_categories.enduse_category_dict().items()
            if key not in enduses_not_available
        }
        enduse_list = list(enduse_dict.keys())

        # queried scaled_unit_count = 1.489524e+06 >> adjusting to actual dwelling units
        df_sim = self.query_resstock_baseline_timeseries(
            table_name, enduse_list, dwelling_units
        )

        # reduce data dimensions and format for agg
        df_sim = self.resample_data(df_sim, freq="1h", make_period_beginning=True)
        df_sim = self.combine_end_uses(df_sim, enduse_dict)
        df_sim = self.format_data_for_aggregation(df_sim, table_name)

        return df_sim

    def query_hpxml_resstock_run_baseline(self, dwelling_units):
        """ Query baseline timeseries from hpxml_resstock run

        Args:
            dwelling_units (int or float) : number of dwelling_units to renormalize end use demands to (dwelling_units = scaled_unit_count)

        Returns:
            df_sim (pd.DataFrame) : dataframe after adjustments

        """
        table_name = "2012_hpxml_mshp_run"

        # set up enduse_dict
        enduse_dict = hpxml_enduse_categories.enduse_category_dict()
        enduse_list = hpxml_enduse_categories.enduse_list()

        # queried scaled_unit_count = 16.720161 (wrong, caused by bsb version used) >> adjusting to actual dwelling units
        df_sim = self.query_resstock_baseline_timeseries(
            table_name, enduse_list, dwelling_units
        )

        # reduce data dimensions and format for agg
        df_sim = self.resample_data(df_sim, freq="1h", make_period_beginning=True)
        df_sim = self.combine_end_uses(df_sim, enduse_dict)
        df_sim = self.format_data_for_aggregation(df_sim, table_name)

        return df_sim

    def query_resstock_baseline_timeseries(
        self, table_name: str, enduses: list, dwelling_units: float
    ):
        """ Query resstock baseline timeseries by end uses, adjust values to dwelling_units specified

        Args:
            table_name : name of resstock simulaiton run (e.g., 2012_old_resstock_mshp_run)
            enduses : list of end uses to query
            dwelling_units : number of dwelling units the total demand should be adjusted to to represent 

        Returns:
            df_sim (pd.DataFrame) : dataframe after adjustments

        """

        # load directly or make query
        file = self.raw_datadir / f"{table_name}_baseline_15min_timeseries.csv"

        if file.exists():
            df_sim = pd.read_csv(file, parse_dates=["time"])

        else:
            # Initialize Athena object
            Athena = EULPAthena(
                workgroup="eulp",
                db_name="la-100",
                buildstock_type="resstock",
                table_name=table_name,
            )

            df_sim = Athena.aggregate_timeseries(
                enduses=enduses,
                group_by=["time"],
                order_by=["time"],
                restrict=[("upgrade", ["0"])],
                get_query_only=False,
            )

            # adjust total demand to dwelling_units specified
            for eu in enduses:
                df_sim[eu] = (
                    df_sim[eu].divide(df_sim["scaled_unit_count"]) * dwelling_units
                )
            df_sim["scaled_unit_count"] = dwelling_units

            # save to file
            df_sim.to_csv(file, index=False)

        return df_sim

    ### helper functions to make and process ResStock output ###
    @staticmethod
    def resample_data(
        df,
        freq="1h",
        make_period_beginning=True,
        time_col="time",
        count_cols=None,
        enduse_cols=None,
        groupby_cols=None,
    ):
        """ resample data, rename time to timestamp, and do other adjustments

        Args:
            df (pd.DataFrame) : input dataframe, containing "time", count_cols, and enduse_cols
            freq (str) : time frequency to resample data
            make_period_beginning (bool) :  whether to make timestamp period-beginning (ResStock output is period-ending)
            count_cols (list) : list of count column names
            enduse_cols (list) : list of end use column names
            groupby_cols (list) : list of column names to group by

        Returns:
            df (pd.DataFrame) : dataframe after adjustments

        """
        df = df.copy()
        df[time_col] = pd.to_datetime(df[time_col])
        df_freq = df[time_col].iloc[1] - df[time_col].iloc[0]

        if make_period_beginning:
            # dt.timedelta(minutes=15) # make time period-beginning
            df[time_col] -= df_freq

        if count_cols is None:
            count_cols = ["raw_count", "scaled_unit_count"]
        if enduse_cols is None:
            enduse_cols = [x for x in df.columns if x not in [time_col] + count_cols]

        if groupby_cols is None:
            groupby_cols = []
        else:
            groupby_cols = [x for x in groupby_cols if x != time_col]
        groupby_cols.append(pd.Grouper(key=time_col, freq=freq))

        df_list = []
        if len(count_cols) > 0:
            df_list.append(df.groupby(groupby_cols)[count_cols].mean())
        if len(enduse_cols) > 0:
            df_list.append(df.groupby(groupby_cols)[enduse_cols].sum())
        df = pd.concat(df_list, axis=1)
        df = df.reset_index().rename(columns={time_col: "timestamp"})

        return df

    @staticmethod
    def combine_end_uses(df, enduse_dict):
        """ map end uses based on enduse_dict 
        Args:
            df (pd.DataFrame) : input dataframe, containing "time", count_cols, and enduse_cols
            enduse_dict (dict) : df orgininal cols as keys and new cols as values
        Returns:
            df (pd.DataFrame) : dataframe after mapping and aggregations
        """
        cols_to_keep = [x for x in df.columns if x not in enduse_dict.keys()]

        df2 = df.drop(columns=cols_to_keep).rename(columns=enduse_dict)
        cols = list(dict.fromkeys(df2.columns))  # preserve ordering
        df2 = df2.groupby(df2.columns, axis=1).sum()
        df2 = pd.concat([df[cols_to_keep], df2[cols]], axis=1)

        return df2

    @staticmethod
    def format_data_for_aggregation(df_sim, table_name):
        enduses = [
            x
            for x in df_sim.columns
            if x not in ["timestamp", "raw_count", "scaled_unit_count"]
        ]
        df_sim = pd.melt(
            df_sim.rename(columns={"scaled_unit_count": "dwelling_units"}),
            id_vars=["timestamp", "dwelling_units"],
            value_vars=enduses,
            var_name="enduse_category",
            value_name="kwh",
        )
        df_sim["run"] = table_name
        df_sim["cohort"] = "Total Residential Stock"
        df_sim["kwh_per_unit"] = df_sim["kwh"].divide(df_sim["dwelling_units"])

        return df_sim

    def get_aggregated_dataset(self, lrd_year=2012):
        """ get and combine datasets together """
        dwelling_units = 1493108  # <-- from simulation yml

        # get processed data
        df_lrd = self.process_lrd_data(lrd_year)
        df_old = self.process_old_la_result()
        df_sim1 = self.query_old_resstock_run_baseline(dwelling_units)
        df_sim2 = self.query_hpxml_resstock_run_baseline(dwelling_units)

        # combine data
        df = pd.concat([df_lrd, df_sim1, df_sim2, df_old], axis=0, ignore_index=True)
        agg_file = self.baseline_datadir / f"aggregated_dataset_LRD_{lrd_year}.csv"
        df.to_csv(agg_file, index=False)

        print(f"aggregated dataset created: \n{agg_file}")

        return df


if __name__ == "__main__":
    """
    Usage:
    python path_to_make_la100_dataset.py lrd_year
    """
    if len(sys.argv) != 2:
        print(
            f"Usage: {sys.argv[0]} lrd_year\n" '"lrd_year" options: 2012 | 2016 | 2017"'
        )
        sys.exit(1)

    AggData = AggregateDataLA()
    AggData.get_aggregated_dataset(sys.argv[1])
