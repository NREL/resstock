# frozen_string_literal: true

class Constants
  def self.build_residential_hpxml_excludes
    # don't make these BuildResidentialHPXML arguments into ResStockArguments arguments
    return ['hpxml_path',
            'software_info_program_used',
            'software_info_program_version',
            'geometry_unit_left_wall_is_adiabatic',
            'geometry_unit_right_wall_is_adiabatic',
            'geometry_unit_front_wall_is_adiabatic',
            'geometry_unit_back_wall_is_adiabatic',
            'geometry_unit_num_floors_above_grade',
            'hvac_control_heating_weekday_setpoint',
            'hvac_control_heating_weekend_setpoint',
            'hvac_control_cooling_weekday_setpoint',
            'hvac_control_cooling_weekend_setpoint',
            'geometry_has_flue_or_chimney',
            'heating_system_airflow_defect_ratio',
            'cooling_system_airflow_defect_ratio',
            'cooling_system_charge_defect_ratio',
            'heat_pump_airflow_defect_ratio',
            'heat_pump_charge_defect_ratio',
            'misc_plug_loads_television_annual_kwh',
            'misc_plug_loads_television_usage_multiplier',
            'pv_system_num_bedrooms_served',
            'occupancy_calculation_type']
  end

  def self.build_residential_schedule_file_excludes
    # don't make these BuildResidentialScheduleFile arguments into ResStockArguments arguments
    return ['hpxml_path',
            'output_csv_path',
            'hpxml_output_path',
            'debug']
  end

  def self.Auto
    return 'auto'
  end
end
