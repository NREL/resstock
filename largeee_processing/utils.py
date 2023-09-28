from itertools import islice
from fsspec.core import url_to_fs
import logging
import yaml
import pathlib
import time
import pandas as pd
import random
import re

logger = logging.getLogger(__name__)

# Created using OpenStudio unit conversion library
energy_unit_conv_to_kwh = {
    "mbtu": 293.0710701722222,
    "m_btu": 293.0710701722222,
    "therm": 29.307107017222222,
    "kbtu": 0.2930710701722222,
}

LB_TO_KG = 0.45359237


def chunk(it, size):
    """ Yield successive size-sized chunks from iterator it."""
    it = iter(it)
    return iter(lambda: tuple(islice(it, size)), ())


def shrink_colname(col):
    col_parts = col.split(".")
    if col_parts[0] != "out":
        return col[:63]
    if col_parts[-1] == "energy_consumption_intensity":
        max_len = 63
    elif col_parts[-1] == "energy_consumption":
        max_len = 53  # 63 - len("_intensity")
    else:
        max_len = 63
    if len(col) > max_len:
        n_dots = len(col_parts) - 1
        if col_parts[-1].startswith("energy_consumption"):
            len_avail = (
                63
                - n_dots
                - len(col_parts[0])
                - len(col_parts[1])
                - len("energy_consumption_intensity")
            )
            name_replacements = [
                ("exterior", "ext"),
                ("lighting", "light"),
                ("heat_pump_backup", "hp_bkup"),
                ("precooling", "precool"),
                ("preheating", "preheat"),
                ("electric_vehicle", "ev"),
            ]
            for x, y in name_replacements:
                col_parts[2] = col_parts[2].replace(x, y)
            col_parts[2] = col_parts[2][:len_avail]
        elif col_parts[-1] == "co2e_kg":
            len_avail = (
                63 - n_dots - sum(len(x) for i, x in enumerate(col_parts) if i != 2)
            )
            col_parts[2] = col_parts[2][:len_avail]
        else:
            assert False
        return ".".join(col_parts)
    else:
        return col


def fill_fs_paths_in_config(cfg):
    # clean paths and create fsspec paths
    cfg['in_location']['path'] = cfg['in_location']['path'].rstrip("/")
    cfg['out_location']['path'] = cfg['out_location']['path'].rstrip("/")
    in_fs, in_fs_path = url_to_fs(cfg['in_location']['path'], profile=cfg['in_location'].get('aws_profile'))
    out_fs, out_fs_path = url_to_fs(cfg['out_location']['path'], profile=cfg['out_location'].get('aws_profile'))
    cfg['in_location']['fs'], cfg['in_location']['fs_path'] = in_fs, in_fs_path
    cfg['out_location']['fs'], cfg['out_location']['fs_path'] = out_fs, out_fs_path


def read_config(config_path):
    try:
        with open(config_path) as f:
            cfg = yaml.load(f, Loader=yaml.SafeLoader)
    except FileNotFoundError as err:
        logger.error("The provided config file doesn't exist")
        raise err
    parent_folder = pathlib.Path(__file__).parent.parent
    schema = yamale.make_schema(parent_folder / 'config_schema.yaml')
    data = yamale.make_data(config_path)
    yamale.validate(schema, data, strict=True)
    fill_fs_paths_in_config(cfg)
    return cfg


def remove_file(fs, file_path):
    attempt = 0
    max_attempts = 10
    while attempt < max_attempts:
        try:
            fs.rm(file_path)
            return
        except Exception as err:
            logger.error(err)
            time.sleep(random.random())
            attempt += 1
            if attempt >= max_attempts:
                raise


def read_df(fs, file_path, *args, **kwargs) -> pd.DataFrame:
    attempt = 0
    max_attempts = 10
    while attempt < max_attempts:
        try:
            with fs.open(file_path, "rb") as f:
                if file_path.endswith('csv'):
                    df = pd.read_csv(f, *args, **kwargs)
                elif file_path.endswith('parquet'):
                    df = pd.read_parquet(f, *args, **kwargs)
                else:
                    raise ValueError(f"Invalid filename extension in {file_path}.")
            return df
        except Exception as err:
            logger.error(err)
            time.sleep(random.random())
            attempt += 1
            if attempt >= max_attempts:
                raise
    raise ValueError("Should never get here")


def write_df(fs, file_path, df: pd.DataFrame, *args, **kwargs):
    attempt = 0
    max_attempts = 10
    while attempt < max_attempts:
        try:
            with fs.open(file_path, "wb") as f:
                if file_path.endswith('csv'):
                    df.to_csv(f, *args, **kwargs)
                elif file_path.endswith('parquet'):
                    df.to_parquet(f, *args, **kwargs)
                else:
                    raise ValueError(f"Invalid filename extension in {file_path}.")
                break
        except Exception as err:
            logger.error(err)
            time.sleep(random.random())
            attempt += 1
            if attempt >= max_attempts:
                raise


def agg_col_renamer(col: str) -> str:
    if col.startswith('out.') and col.endswith('co2e_kg') and not col.startswith('out.emissions'):
        # "out.total.lrmer_lowrecost_30.co2e_kg"->"out.emissions.all_fuels.lrmer_lowrecost_30.co2e_kg"
        if col.startswith('out.total'):
            return "out.emissions.all_fuels" + col[9:]

        # "out.electricity.total.lrmer_low_re_cost_15.co2e_kg"->"out.emissions.electricity.lrmer_low_re_cost_15.co2e_kg"
        col_vals = col.split('.')
        for tt in ['t', 'tot', 'tota', 'total']:
            if tt in col_vals:
                col_vals.remove(tt)
        return 'out.emissions.' + '.'.join(col_vals[1:])
    elif col.startswith('out.') and col.endswith('energy_consumption'):
        return col + '.kwh'
    elif col.startswith('out.') and col.endswith('energy_consumption_intensity'):
        return col + '.kwh_per_sqft'
    elif col.startswith('out.emissions') and col.endswith('savings'):
        return 'out.emissions_reduction.' + col[14:-8]
    else:
        return col


def make_dir(fs, path):
    if not isinstance(fs, s3fs.core.S3FileSystem):  # s3 doesn't need folder creation
        fs.mkdirs(path, exist_ok=True)


def get_available_upgrades(cfg):
    in_location = cfg['out_location']
    in_fs, _ = url_to_fs(in_location['path'],
                         profile=in_location.get('aws_profile'))
    search_path = in_location['path'] + \
        '/timeseries_individual_buildings/by_state/'
    available_upgrades = [int(match[1]) for dir in in_fs.listdir(search_path)
                          if (match := re.search("upgrade=(\d*)", dir['name'])) is not None]
    return sorted(available_upgrades)
