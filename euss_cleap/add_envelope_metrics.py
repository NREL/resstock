"""
This file rates wall insulation, roof insulation, and infiltration into "code-compliant", "above-average", "below-average"

Each community gets their climate zone-specific recommendations per IECC 2021.

Summary can be found in "Envelope Requirements per community" prepared by Jes.Brossman@nrel.gov
https://nrel.sharepoint.com/:w:/r/sites/CBldgStock-ResStockC-LEAP/_layouts/15/Doc.aspx?sourcedoc=%
7BA728CC2A-D2B8-40BE-B650-F3ED245B9E40%7D&file=Deliverables%20to%20C-LEAP.docx&wdOrigin=TEAMS-ELECTRON
.p2p.bim&action=default&mobileredirect=true
"""

from pathlib import Path
import numpy as np
import pandas as pd
import argparse
import logging
import math


def setup_logging(
        name, filename, file_level=logging.INFO, console_level=logging.INFO
        ):
    global logger
    logger = logging.getLogger(name)
    logger.setLevel(logging.INFO)
    fh = logging.FileHandler(filename, mode="w")
    fh.setLevel(file_level)
    ch = logging.StreamHandler()
    ch.setLevel(console_level)
    formatter = logging.Formatter(
        "%(asctime)s - %(levelname)s - %(message)s"
    )
    fh.setFormatter(formatter)
    ch.setFormatter(formatter)
    # add the handlers to the logger
    logger.addHandler(fh)
    logger.addHandler(ch)


def material_assembly_r_value_mapping():
	global wall_assembly_r_map, wall_exterior_finish_r_map, ceiling_assmebly_r_map, roof_assembly_r_map
	wall_assembly_r_map = {
		'Wood Stud, Uninsulated': 3.4,
		'Wood Stud, R-7': 8.7,
		'Wood Stud, R-11': 10.3,
		'Wood Stud, R-15': 12.1,
		'Wood Stud, R-19': 15.4,
		'CMU, 6-in Hollow, Uninsulated': 4,
		'CMU, 6-in Hollow, R-7': 9.4,
		'CMU, 6-in Hollow, R-11': 12.4,
		'CMU, 6-in Hollow, R-15': 15,
		'CMU, 6-in Hollow, R-19': 17.4,
		'Brick, 12-in, 3-wythe, Uninsulated': 4.9,
		'Brick, 12-in, 3-wythe, R-7': 10.3,
		'Brick, 12-in, 3-wythe, R-11': 13.3,
		'Brick, 12-in, 3-wythe, R-15': 15.9,
		'Brick, 12-in, 3-wythe, R-19': 18.3,
	}
	wall_exterior_finish_r_map = {
		'Aluminum, Light': 0.6,
		'Brick, Light': 0.7,
		'Brick, Medium/Dark': 0.7,
		'Fiber-Cement, Light': 0.2,
		'Shingle, Composition, Medium': 0.6,
		'Shingle, Asbestos, Medium': 0.6,
		'Stucco, Light': 0.2,
		'Stucco, Medium/Dark': 0.2,
		'Vinyl, Light': 0.6,
		'Wood, Medium/Dark': 1.4,
		'None': 0,
	}
	ceiling_assmebly_r_map = {
		'None': 0,
		'Uninsulated': 2.1,
		'R-7': 8.7,
		'R-13': 14.6,
		'R-19': 20.6,
		'R-30': 31.6,
		'R-38': 39.6,
		'R-49': 50.6,
	}
	roof_assembly_r_map = {
		'Unfinished, Uninsulated': 2.3,
		'Finished, Uninsulated': 3.7,
		'Finished, R-7': 10.2,
		'Finished, R-13': 14.3,
		'Finished, R-19': 21.2,
		'Finished, R-30': 29.7,
		'Finished, R-38': 36.5,
		'Finished, R-49': 47.0,
	}
	return wall_assembly_r_map, wall_exterior_finish_r_map, ceiling_assmebly_r_map, roof_assembly_r_map


def insulation_r_value_mapping():
	global wall_r_value_map, ceiling_r_value_map, roof_r_value_map
	wall_r_value_map = {
		'Wood Stud, Uninsulated': 0,
		'Wood Stud, R-7': 7,
		'Wood Stud, R-11': 11,
		'Wood Stud, R-15': 15,
		'Wood Stud, R-19': 19,
		'CMU, 6-in Hollow, Uninsulated': 0,
		'CMU, 6-in Hollow, R-7': 7,
		'CMU, 6-in Hollow, R-11': 11,
		'CMU, 6-in Hollow, R-15': 15,
		'CMU, 6-in Hollow, R-19': 19,
		'Brick, 12-in, 3-wythe, Uninsulated': 0,
		'Brick, 12-in, 3-wythe, R-7': 7,
		'Brick, 12-in, 3-wythe, R-11': 11,
		'Brick, 12-in, 3-wythe, R-15': 15,
		'Brick, 12-in, 3-wythe, R-19': 19,
	}
	
	ceiling_r_value_map = {
		'None': 0,
		'Uninsulated': 0,
		'R-7': 7,
		'R-13': 13,
		'R-19': 19,
		'R-30': 30,
		'R-38': 38,
		'R-49': 49,
	}
	roof_r_value_map = {
		'Unfinished, Uninsulated': 0,
		'Finished, Uninsulated': 0,
		'Finished, R-7': 7,
		'Finished, R-13': 13,
		'Finished, R-19': 19,
		'Finished, R-30': 30,
		'Finished, R-38': 38,
		'Finished, R-49': 49,
	}
	return wall_r_value_map, ceiling_r_value_map, roof_r_value_map

def get_iecc_code_rating_threholds(community):
	""" community-specific threholds for 
		wall (R-value), roof/ceiling (R-value), infiltration (ACH50) ratings
	Wall distinguished between frame and masonry
	Same code between SF and MF
	code_rating dict: comes from IECC 2021 except Title 24 for San Jose
	average_rating_dict: educated guess
	"""
	if community == "duluth":
		# IECC 7
		code_rating_dict ={
			"wall": {"frame": 30, "masonry": 19},
			"infiltration": 3,
			"ceiling_roof": 60,
		}
	elif community == "lawrence":
		# IECC 5a
		code_rating_dict ={
			"wall": {"frame": 30, "masonry": 13},
			"infiltration": 3,
			"ceiling_roof": 60,
		}
	elif community in ["jackson_county", "hill_district", "louisville"]:
		# IECC 4a
		code_rating_dict ={
			"wall": {"frame": 30, "masonry": 8},
			"infiltration": 3,
			"ceiling_roof": 60,
		}
	elif community in ["north_birmingham", "columbia"]:
		# IECC 3a
		code_rating_dict ={
			"wall": {"frame": 20, "masonry": 8},
			"infiltration": 3,
			"ceiling_roof": 49,
		}
	elif community == "san_jose":
		# IECC 3C, Title 24
		code_rating_dict ={
			"wall": {"frame": 9, "masonry": 8},
			"infiltration": 2,
			"ceiling_roof": 23,
		}
	else:
		raise ValueError(f"Undefined community={community}")

	return code_rating_dict


def average_ratings_by_climate_zone():
	file = "/Volumes/Lixi_Liu/euss_aws/results_up00.parquet"
	df = pd.read_parquet(file)

	# wall R-value
	df_wall = df.groupby([
		"build_existing_model.ashrae_iecc_climate_zone_2004", 
		"build_existing_model.geometry_wall_type",
		"build_existing_model.insulation_wall"])["building_id"].count().rename("count").reset_index()
	df_wall["wall_type"] = df_wall["build_existing_model.geometry_wall_type"].map(
		{"Wood Frame": "frame", "Brick": "masonry", "Concrete": "masonry", "Steel Frame": "frame"}
		)
	df_wall["r_value"] = df_wall["build_existing_model.insulation_wall"].map(wall_r_value_map)
	df_wall = df_wall.groupby(["build_existing_model.ashrae_iecc_climate_zone_2004", "wall_type"]).apply(
		lambda x: math.ceil(sum(x["r_value"]*x["count"]) / x["count"].sum())
		) # two indices

	# ceiling/roof R-value
	df_ceil = df.groupby([
		"build_existing_model.ashrae_iecc_climate_zone_2004", 
		"build_existing_model.insulation_ceiling"])["building_id"].count().rename("count").reset_index()
	df_ceil["r_value"] = df_ceil["build_existing_model.insulation_ceiling"].map(ceiling_r_value_map)

	df_roof = df.groupby([
		"build_existing_model.ashrae_iecc_climate_zone_2004", 
		"build_existing_model.insulation_roof"])["building_id"].count().rename("count").reset_index()
	df_roof["r_value"] = df_roof["build_existing_model.insulation_roof"].map(roof_r_value_map)

	df_ceil_roof = pd.concat([
		df_ceil.drop(columns=["build_existing_model.insulation_ceiling"]),
		df_roof.drop(columns=["build_existing_model.insulation_roof"]),
		], axis=0)
	df_ceil_roof = df_ceil_roof.groupby(["build_existing_model.ashrae_iecc_climate_zone_2004"]).apply(
		lambda x: math.ceil(sum(x["r_value"]*x["count"]) / x["count"].sum())
		)

	# infiltration
	df_infil = df.groupby([
		"build_existing_model.ashrae_iecc_climate_zone_2004", 
		"build_existing_model.infiltration"])["building_id"].count().rename("count").reset_index()
	df_infil["ACH50"] = df_infil["build_existing_model.infiltration"].str.removesuffix(" ACH50").astype(int)
	df_infil = df_infil.groupby(["build_existing_model.ashrae_iecc_climate_zone_2004"]).apply(
		lambda x: math.floor(sum(x["ACH50"]*x["count"]) / x["count"].sum())
		)

	return df_wall, df_ceil_roof, df_infil



def get_average_rating_thresholds(community, df_wall, df_ceil_roof, df_infil):
	iecc_cz_dict = {
		"duluth": "7A",
		"lawrence": "5A",
		"jackson_county": "4A",
		"hill_district": "4A",
		"louisville": "4A",
		"north_birmingham": "3A",
		"columbia": "3A",
		"san_jose": "3C",
	}

	cz = iecc_cz_dict[community]

	avg_rating_dict ={
			"wall": {"frame": df_wall[(cz, "frame")], "masonry": df_wall[(cz, "masonry")]},
			"infiltration": df_infil[cz],
			"ceiling_roof": df_ceil_roof[cz],
		}

	return avg_rating_dict


def create_rating_table(code_ratings, avg_ratings):
	df = pd.DataFrame({
		"code-compliant": [f">= {code_ratings['wall']['frame']}", f">= {code_ratings['wall']['masonry']}", f">= {code_ratings['ceiling_roof']}", f"<= {code_ratings['infiltration']}"],
		"above-average": [
		f"< {code_ratings['wall']['frame']}, >= {avg_ratings['wall']['frame']}", 
		f"< {code_ratings['wall']['masonry']}, >= {avg_ratings['wall']['masonry']}", 
		f"< {code_ratings['ceiling_roof']}, >= {avg_ratings['ceiling_roof']}", 
		f"> {code_ratings['infiltration']}, <= {avg_ratings['infiltration']}"
		],
		"below-average": [f"< {avg_ratings['wall']['frame']}", f"< {avg_ratings['wall']['masonry']}", f"< {avg_ratings['ceiling_roof']}", f"> {avg_ratings['infiltration']}"],
		}, index=[
			"Frame Wall (R-value)",
			"Masonry Wall (R-value)",
			"Ceiling/Roof (R-value)",
			"Air Leakage (ACH50)"
			])
	return df


def add_envelope_ratings(dfb, community):
	# initialize
	logger.info(f"Adding envelope metrics to {community}")
	wall_assembly_r_map, wall_exterior_finish_r_map, ceiling_assmebly_r_map, roof_assembly_r_map = material_assembly_r_value_mapping()
	wall_r_value_map, ceiling_r_value_map, roof_r_value_map = insulation_r_value_mapping()
	df_wall, df_ceil_roof, df_infil = average_ratings_by_climate_zone()

	# set thresholds
	code_ratings = get_iecc_code_rating_threholds(community)
	avg_ratings = get_average_rating_thresholds(community, df_wall, df_ceil_roof, df_infil)
	table_ratings = create_rating_table(code_ratings, avg_ratings)
	logger.info(f"\n{table_ratings}")

	# calcualte rating values
	wall_value = dfb['build_existing_model.insulation_wall'].map(wall_r_value_map).fillna(0)

	ceil_roof_value = dfb['build_existing_model.insulation_ceiling'].map(ceiling_r_value_map).fillna(0) + \
		dfb['build_existing_model.insulation_roof'].map(roof_r_value_map).fillna(0)

	infil_value = dfb['build_existing_model.infiltration'].str.removesuffix(' ACH50').astype(int)

	# categorize ratings
	wall_type = dfb["build_existing_model.geometry_wall_type"].map(
		{"Wood Frame": "frame", "Brick": "masonry", "Concrete": "masonry", "Steel Frame": "frame"}
		)
	wall_rating = pd.Series("code-compliant", index=dfb.index)
	for wtype in ["frame", "masonry"]:
		cond = wall_type==wtype
		wall_rating.loc[cond & (wall_value<code_ratings["wall"][wtype])] = "above-average"
		wall_rating.loc[cond & (wall_value<avg_ratings["wall"][wtype])] = "below-average"

	ceil_roof_rating = pd.Series("code-compliant", index=dfb.index)
	ceil_roof_rating.loc[ceil_roof_value<code_ratings["ceiling_roof"]] = "above-average"
	ceil_roof_rating.loc[ceil_roof_value<avg_ratings["ceiling_roof"]] = "below-average"

	infil_rating = pd.Series("code-compliant", index=dfb.index)
	infil_rating.loc[infil_value>code_ratings["infiltration"]] = "above-average"
	infil_rating.loc[infil_value>avg_ratings["infiltration"]] = "below-average"

	# overall rating
	mapping = {"code-compliant": 1, "above-average": 2, "below-average": 3}
	overall_rating = pd.concat([wall_rating, ceil_roof_rating, infil_rating], axis=1).replace(mapping)
	overall_rating = overall_rating.max(axis=1).replace({v:k for k, v in mapping.items()})

	combined_rating = pd.concat([wall_rating, ceil_roof_rating, infil_rating, overall_rating], axis=1)
	combined_rating.columns=["wall_rating", "ceiling_roof_rating", "infiltration_rating", "combined_envelope_rating"]

	summary = combined_rating.assign(count=1).groupby(["combined_envelope_rating", "wall_rating", "ceiling_roof_rating", "infiltration_rating"])["count"].count()

	logger.info(f"\n{summary}")

	# add to baseline
	dfb = pd.concat([dfb, combined_rating], axis=1)

	return dfb


def process_baseline_file(community):
	data_dir = Path(".").resolve() / "data_" / "community_building_samples" / community
	setup_logging(community, data_dir / f"output__envelope_rating__{community}.log")

	# read file
	baseline_file = data_dir / f"up00.parquet"
	dfb = pd.read_parquet(baseline_file).set_index("building_id")
	dfb = dfb.loc[dfb["completed_status"]=="Success"]

	if "combined_envelope_rating" in dfb.columns:
		x = input('Envelope ratings such as "combined_envelope_rating" already exist, remove them? [y|n]: ')
		if x == "n":
			sys.exit()
		else:
			dfb = dfb.drop(columns=["combined_envelope_rating", "wall_rating", "ceiling_roof_rating", "infiltration_rating"])

	dfb = add_envelope_ratings(dfb, community)

	# save to file - add to existing file
	dfb.reset_index().to_parquet(baseline_file)
	logger.info(f"Baseline file updated and saved to: {baseline_file}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "community_name",
        help="name of community, for adding extension to output file",
    )

    community = parser.parse_args().community_name
    process_baseline_file(community)
