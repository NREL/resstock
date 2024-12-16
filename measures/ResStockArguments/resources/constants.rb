# frozen_string_literal: true

module Constants
  Auto = 'auto'
  Heating = 'heating'
  Cooling = 'cooling'
  Weekday = 'weekday'
  Weekend = 'weekend'

  # Exclude these BuildResidentialHPXML arguments as ResStockArguments arguments
  BuildResidentialHPXMLExcludes = ['hpxml_path',
                                   'existing_hpxml_path',
                                   'whole_sfa_or_mf_building_sim',
                                   'software_info_program_used',
                                   'software_info_program_version',
                                   'schedules_filepaths',
                                   'schedules_unavailable_period_types',
                                   'schedules_unavailable_period_dates',
                                   'schedules_unavailable_period_window_natvent_availabilities',
                                   'simulation_control_timestep',
                                   'simulation_control_run_period',
                                   'simulation_control_run_period_calendar_year',
                                   'simulation_control_daylight_saving_period',
                                   'simulation_control_temperature_capacitance_multiplier',
                                   'simulation_control_defrost_model_type',
                                   'simulation_control_onoff_thermostat_deadband',
                                   'simulation_control_heat_pump_backup_heating_capacity_increment',
                                   'unit_multiplier',
                                   'geometry_unit_height_above_grade',
                                   'geometry_unit_left_wall_is_adiabatic',
                                   'geometry_unit_right_wall_is_adiabatic',
                                   'geometry_unit_front_wall_is_adiabatic',
                                   'geometry_unit_back_wall_is_adiabatic',
                                   'geometry_unit_num_floors_above_grade',
                                   'air_leakage_has_flue_or_chimney_in_conditioned_space',
                                   'heating_system_airflow_defect_ratio',
                                   'cooling_system_airflow_defect_ratio',
                                   'cooling_system_charge_defect_ratio',
                                   'heat_pump_airflow_defect_ratio',
                                   'heat_pump_charge_defect_ratio',
                                   'hvac_control_heating_weekday_setpoint',
                                   'hvac_control_heating_weekend_setpoint',
                                   'hvac_control_cooling_weekday_setpoint',
                                   'hvac_control_cooling_weekend_setpoint',
                                   'pv_system_num_bedrooms_served',
                                   'battery_num_bedrooms_served',
                                   'emissions_scenario_names',
                                   'emissions_types',
                                   'emissions_electricity_units',
                                   'emissions_electricity_values_or_filepaths',
                                   'emissions_electricity_number_of_header_rows',
                                   'emissions_electricity_column_numbers',
                                   'emissions_fossil_fuel_units',
                                   'emissions_natural_gas_values',
                                   'emissions_propane_values',
                                   'emissions_fuel_oil_values',
                                   'emissions_wood_values',
                                   'emissions_coal_values',
                                   'emissions_wood_pellets_values',
                                   'ev_battery_capacity',
                                   'ev_battery_discharge_power',
                                   'ev_hours_per_week',
                                   'misc_plug_loads_vehicle_2_usage_multiplier',
                                   'misc_plug_loads_vehicle_annual_kwh',
                                   'misc_plug_loads_vehicle_present',
                                   'misc_plug_loads_vehicle_usage_multiplier',
                                   'utility_bill_scenario_names',
                                   'utility_bill_electricity_filepaths',
                                   'utility_bill_electricity_fixed_charges',
                                   'utility_bill_electricity_marginal_rates',
                                   'utility_bill_natural_gas_fixed_charges',
                                   'utility_bill_natural_gas_marginal_rates',
                                   'utility_bill_propane_fixed_charges',
                                   'utility_bill_propane_marginal_rates',
                                   'utility_bill_fuel_oil_fixed_charges',
                                   'utility_bill_fuel_oil_marginal_rates',
                                   'utility_bill_wood_fixed_charges',
                                   'utility_bill_wood_marginal_rates',
                                   'utility_bill_coal_fixed_charges',
                                   'utility_bill_coal_marginal_rates',
                                   'utility_bill_wood_pellets_fixed_charges',
                                   'utility_bill_wood_pellets_marginal_rates',
                                   'utility_bill_pv_compensation_types',
                                   'utility_bill_pv_net_metering_annual_excess_sellback_rate_types',
                                   'utility_bill_pv_net_metering_annual_excess_sellback_rates',
                                   'utility_bill_pv_feed_in_tariff_rates',
                                   'utility_bill_pv_monthly_grid_connection_fee_units',
                                   'utility_bill_pv_monthly_grid_connection_fees',
                                   'additional_properties',
                                   'combine_like_surfaces',
                                   'apply_defaults',
                                   'apply_validation']

  # Exclude these BuildResidentialScheduleFile arguments as ResStockArguments arguments
  BuildResidentialScheduleFileExcludes = ['hpxml_path',
                                          'schedules_column_names',
                                          'schedules_random_seed',
                                          'output_csv_path',
                                          'hpxml_output_path',
                                          'append_output',
                                          'debug',
                                          'building_id']

  # Exclude these ResStockArguments from being required in options_lookup.tsv
  OtherExcludes = ['building_id',
                   'heating_system_actual_cfm_per_ton',
                   'heating_system_rated_cfm_per_ton']

  # List of ResStockArguments arguments; reported as build_existing_model.<argument_name>, ...
  ArgumentsToRegister = ['heating_unavailable_period',
                         'cooling_unavailable_period']

  # List of ResStockArguments arguments; will not be passed into BuildResidentialHPXML
  ArgumentsToExclude = ['heating_unavailable_period',
                        'cooling_unavailable_period']
end
