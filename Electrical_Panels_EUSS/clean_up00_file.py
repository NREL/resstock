import numpy as np
import re
from itertools import chain
from pathlib import Path
import argparse
import pandas as pd

def clean_up00_file(input_file):
	input_file = Path(input_file)
	if input_file.suffix == ".csv":
		df = pd.read_parquet(input_file, low_memory=False)
	elif input_file.suffix == ".parquet":
		df = pd.read_parquet(input_file)
	else:
		raise TypeError(f"Unsupported file type: {input_file}")
	assert [col for col in df.columns if col.startswith("build_existing_model.")], f"input_file is not a ResStock summary output file: {input_file}"

	if ami_col := [col for col in df.columns if "area_median_income" in col]:
		print(f"df has AMI column: {ami_col}")
	else:
		print("df is missing AMI column, consider running: add_ami_to_euss_annual_summary.py")

	# retain only relevant columns
	meta_cols = ["building_id", "completed_status", "build_existing_model.sample_weight"]
	meta_cols += get_housing_char_cols(search=True)
	metric_cols = get_metric_cols(df, emission_type = "lrmer_low_re_cost_25_2025_start")

	if diff := set(meta_cols)-set(df.columns):
		print(f"{len(diff)} meta_col(s) missing in df, removing them: \n{diff}")
		meta_cols = [col for col in meta_cols if col in df.columns]

	print(f"Downsizing df from {df.shape[1]} to {len(meta_cols)+len(metric_cols)}")
	df = df[meta_cols+metric_cols]
	output_file = input_file.parent / (input_file.stem+"_clean"+input_file.suffix)
	df.to_parquet(output_file)
	print(f"Downsized df saved to: {output_file}")

def get_metric_cols(df, emission_type=None):
        prefixes = [
            # "report_simulation_output.emissions", 
            "report_simulation_output.end_use", 
            "report_simulation_output.fuel_use", 
            "report_simulation_output.energy_use", 
            "report_simulation_output.peak_",
            "report_simulation_output.unmet_hours_",
            "upgrade_costs.", 
            # "report_utility_bills."
            ]
        metric_cols = []
        for pfx in prefixes:
            if pfx == "upgrade_costs.":
                new_cols = [col for col in df.columns if col.startswith(pfx) and not col.startswith("upgrade_costs.option_")]
            elif pfx == "emissions" and emission_type is not None:
            	new_cols = [col for col in df.columns if col.startswith(pfx) and emission_type in col]
            else:
                new_cols =[col for col in df.columns if col.startswith(pfx)]
            print(f" - metric type: {pfx} yields {len(new_cols)}")
            metric_cols += new_cols

        return metric_cols

def get_housing_char_cols(search=False, get_ami=True):
	if search:
		hc_dir = Path(__file__).resolve().parents[1] / "project_national" / "housing_characteristics"
		hc = [x.stem for x in hc_dir.rglob("*.tsv")]
		hc = ["_".join([x for x in chain(*[re.split('(\d+)',x) for x in y.lower().split(" ")]) if x not in ["", "-"]]) for y in hc]
	else:
		hc = [
			'ahs_region',
			# 'aiannh_area',
			'area_median_income',
			'ashrae_iecc_climate_zone_2004',
			'ashrae_iecc_climate_zone_2004_2_a_split',
			'bathroom_spot_vent_hour',
			'bedrooms',
			'building_america_climate_zone',
			'cec_climate_zone',
			'ceiling_fan',
			'census_division',
			'census_division_recs',
			'census_region',
			'city',
			'clothes_dryer',
			'clothes_washer',
			'clothes_washer_presence',
			'cooking_range',
			'cooling_setpoint',
			'cooling_setpoint_has_offset',
			'cooling_setpoint_offset_magnitude',
			'cooling_setpoint_offset_period',
			'corridor',
			'county',
			'county_and_puma',
			'dehumidifier',
			'dishwasher',
			'door_area',
			'doors',
			'ducts',
			'eaves',
			'electric_vehicle',
			'federal_poverty_level',
			'generation_and_emissions_assessment_region',
			'geometry_attic_type',
			'geometry_building_horizontal_location_mf',
			'geometry_building_horizontal_location_sfa',
			'geometry_building_level_mf',
			'geometry_building_number_units_mf',
			'geometry_building_number_units_sfa',
			'geometry_building_type_acs',
			'geometry_building_type_height',
			'geometry_building_type_recs',
			'geometry_floor_area',
			'geometry_floor_area_bin',
			'geometry_foundation_type',
			'geometry_garage',
			'geometry_stories',
			'geometry_stories_low_rise',
			'geometry_story_bin',
			'geometry_wall_exterior_finish',
			'geometry_wall_type',
			'has_pv',
			'heating_fuel',
			'heating_setpoint',
			'heating_setpoint_has_offset',
			'heating_setpoint_offset_magnitude',
			'heating_setpoint_offset_period',
			'holiday_lighting',
			'hot_water_distribution',
			'hot_water_fixtures',
			# 'household_has_tribal_persons',
			'hvac_cooling_efficiency',
			'hvac_cooling_partial_space_conditioning',
			'hvac_cooling_type',
			'hvac_has_ducts',
			'hvac_has_shared_system',
			'hvac_has_zonal_electric_heating',
			'hvac_heating_efficiency',
			'hvac_heating_type',
			'hvac_heating_type_and_fuel',
			'hvac_secondary_heating_efficiency',
			'hvac_secondary_heating_type_and_fuel',
			'hvac_shared_efficiencies',
			'hvac_system_is_faulted',
			'hvac_system_single_speed_ac_airflow',
			'hvac_system_single_speed_ac_charge',
			'hvac_system_single_speed_ashp_airflow',
			'hvac_system_single_speed_ashp_charge',
			'income',
			'income_recs_2015',
			'income_recs_2020',
			'infiltration',
			'insulation_ceiling',
			'insulation_floor',
			'insulation_foundation_wall',
			'insulation_rim_joist',
			'insulation_roof',
			'insulation_slab',
			'insulation_wall',
			'interior_shading',
			'iso_rto_region',
			'lighting',
			'lighting_interior_use',
			'lighting_other_use',
			'location_region',
			'mechanical_ventilation',
			'misc_extra_refrigerator',
			'misc_freezer',
			'misc_gas_fireplace',
			'misc_gas_grill',
			'misc_gas_lighting',
			'misc_hot_tub_spa',
			'misc_pool',
			'misc_pool_heater',
			'misc_pool_pump',
			'misc_well_pump',
			'natural_ventilation',
			'neighbors',
			'occupants',
			'orientation',
			'overhangs',
			'plug_load_diversity',
			'plug_loads',
			'puma',
			'puma_metro_status',
			'pv_orientation',
			'pv_system_size',
			'radiant_barrier',
			'range_spot_vent_hour',
			'reeds_balancing_area',
			'refrigerator',
			'roof_material',
			'solar_hot_water',
			'state',
			'tenure',
			'usage_level',
			'vacancy_status',
			'vintage',
			'vintage_acs',
			'water_heater_efficiency',
			'water_heater_fuel',
			'water_heater_in_unit',
			'window_areas',
			'windows'
			]
		if not get_ami:
			hc = [x for x in hc if x != "area_median_income"]
	return [f"build_existing_model.{x}" for x in hc]

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "result_csv_file",
        help=f"path to EUSS result csv file",
    )
    args = parser.parse_args()
    clean_up00_file(args.result_csv_file)


if __name__ == "__main__":
    main()


