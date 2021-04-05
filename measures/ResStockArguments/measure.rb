# frozen_string_literal: true

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/measures/measure_writing_guide/

require 'openstudio'
if File.exist? File.absolute_path(File.join(File.dirname(__FILE__), '../../lib/resources/hpxml-measures/HPXMLtoOpenStudio/resources')) # Hack to run ResStock on AWS
  resources_path = File.absolute_path(File.join(File.dirname(__FILE__), '../../lib/resources/hpxml-measures/HPXMLtoOpenStudio/resources'))
elsif File.exist? File.absolute_path(File.join(File.dirname(__FILE__), '../../resources/hpxml-measures/HPXMLtoOpenStudio/resources')) # Hack to run ResStock unit tests locally
  resources_path = File.absolute_path(File.join(File.dirname(__FILE__), '../../resources/hpxml-measures/HPXMLtoOpenStudio/resources'))
elsif File.exist? File.join(OpenStudio::BCLMeasure::userMeasuresDir.to_s, 'HPXMLtoOpenStudio/resources') # Hack to run measures in the OS App since applied measures are copied off into a temporary directory
  resources_path = File.join(OpenStudio::BCLMeasure::userMeasuresDir.to_s, 'HPXMLtoOpenStudio/resources')
else
  resources_path = File.absolute_path(File.join(File.dirname(__FILE__), '../HPXMLtoOpenStudio/resources'))
end
require File.join(resources_path, 'meta_measure')

require_relative 'resources/constants'

# start the measure
class ResStockArguments < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    # Measure name should be the title case of the class name.
    return 'ResStock Arguments'
  end

  # human readable description
  def description
    return 'Measure that extends the arguments available for ResStock.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'Defines the set of arguments needed for ResStock that are not available in BuildResidentialHPXML.'
  end

  # define the arguments that the user will input
  def arguments(model)
    measures_dir = File.absolute_path(File.join(File.dirname(__FILE__), '../../resources/hpxml-measures'))
    measure_subdir = 'BuildResidentialHPXML'
    full_measure_path = File.join(measures_dir, measure_subdir, 'measure.rb')
    measure = get_measure_instance(full_measure_path)

    args = OpenStudio::Measure::OSArgumentVector.new
    measure.arguments(model).each do |arg|
      next if Constants.excludes.include? arg.name

      args << arg
    end

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('plug_loads_other_usage_multiplier_2', true)
    arg.setDisplayName('Plug Loads: Other Usage Multiplier 2')
    arg.setDescription('Additional multiplier on the other energy usage that can reflect, e.g., high/low usage occupants.')
    arg.setDefaultValue(1.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('plug_loads_well_pump_usage_multiplier_2', true)
    arg.setDisplayName('Plug Loads: Well Pump Usage Multiplier 2')
    arg.setDescription('Additional multiplier on the well pump energy usage that can reflect, e.g., high/low usage occupants.')
    arg.setDefaultValue(0.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('plug_loads_vehicle_usage_multiplier_2', true)
    arg.setDisplayName('Plug Loads: Vehicle Usage Multiplier 2')
    arg.setDescription('Additional multiplier on the electric vehicle energy usage that can reflect, e.g., high/low usage occupants.')
    arg.setDefaultValue(0.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('setpoint_heating_weekday_temp', true)
    arg.setDisplayName('Heating Setpoint: Weekday Temperature')
    arg.setDescription('Specify the weekday heating setpoint temperature.')
    arg.setUnits('deg-F')
    arg.setDefaultValue(71)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('setpoint_heating_weekend_temp', true)
    arg.setDisplayName('Heating Setpoint: Weekend Temperature')
    arg.setDescription('Specify the weekend heating setpoint temperature.')
    arg.setUnits('deg-F')
    arg.setDefaultValue(71)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('setpoint_heating_weekday_offset_magnitude', true)
    arg.setDisplayName('Heating Setpoint: Weekday Offset Magnitude')
    arg.setDescription('Specify the weekday heating offset magnitude.')
    arg.setUnits('deg-F')
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('setpoint_heating_weekend_offset_magnitude', true)
    arg.setDisplayName('Heating Setpoint: Weekend Offset Magnitude')
    arg.setDescription('Specify the weekend heating offset magnitude.')
    arg.setUnits('deg-F')
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument('setpoint_heating_weekday_schedule', true)
    arg.setDisplayName('Heating Setpoint: Weekday Schedule')
    arg.setDescription('Specify the 24-hour comma-separated weekday heating schedule of 0s and 1s.')
    arg.setDefaultValue('0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument('setpoint_heating_weekend_schedule', true)
    arg.setDisplayName('Heating Setpoint: Weekend Schedule')
    arg.setDescription('Specify the 24-hour comma-separated weekend heating schedule of 0s and 1s.')
    arg.setDefaultValue('0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('setpoint_cooling_weekday_temp', true)
    arg.setDisplayName('Cooling Setpoint: Weekday Temperature')
    arg.setDescription('Specify the weekday cooling setpoint temperature.')
    arg.setUnits('deg-F')
    arg.setDefaultValue(76)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('setpoint_cooling_weekend_temp', true)
    arg.setDisplayName('Cooling Setpoint: Weekend Temperature')
    arg.setDescription('Specify the weekend cooling setpoint temperature.')
    arg.setUnits('deg-F')
    arg.setDefaultValue(76)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('setpoint_cooling_weekday_offset_magnitude', true)
    arg.setDisplayName('Cooling Setpoint: Weekday Offset Magnitude')
    arg.setDescription('Specify the weekday cooling offset magnitude.')
    arg.setUnits('deg-F')
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('setpoint_cooling_weekend_offset_magnitude', true)
    arg.setDisplayName('Cooling Setpoint: Weekend Offset Magnitude')
    arg.setDescription('Specify the weekend cooling offset magnitude.')
    arg.setUnits('deg-F')
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument('setpoint_cooling_weekday_schedule', true)
    arg.setDisplayName('Cooling Setpoint: Weekday Schedule')
    arg.setDescription('Specify the 24-hour comma-separated weekday cooling schedule of 0s and 1s.')
    arg.setDefaultValue('0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument('setpoint_cooling_weekend_schedule', true)
    arg.setDisplayName('Cooling Setpoint: Weekend Schedule')
    arg.setDescription('Specify the 24-hour comma-separated weekend cooling schedule of 0s and 1s.')
    arg.setDefaultValue('0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument('heating_system_has_flue_or_chimney', true)
    arg.setDisplayName('Heating System: Has Flue or Chimney')
    arg.setDescription('Whether the heating system has a flue or chimney.')
    arg.setDefaultValue(Constants.Auto)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument('heating_system_has_flue_or_chimney_2', true)
    arg.setDisplayName('Heating System 2: Has Flue or Chimney')
    arg.setDescription('Whether the second heating system has a flue or chimney.')
    arg.setDefaultValue(Constants.Auto)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument('water_heater_has_flue_or_chimney', true)
    arg.setDisplayName('Water Heater: Has Flue or Chimney')
    arg.setDescription('Whether the water heater has a flue or chimney.')
    arg.setDefaultValue(Constants.Auto)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('heating_system_rated_cfm_per_ton', false)
    arg.setDisplayName('Heating System: Rated CFM Per Ton')
    arg.setUnits('cfm/ton')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('heating_system_actual_cfm_per_ton', false)
    arg.setDisplayName('Heating System: Actual CFM Per Ton')
    arg.setUnits('cfm/ton')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('cooling_system_rated_cfm_per_ton', false)
    arg.setDisplayName('Cooling System: Rated CFM Per Ton')
    arg.setUnits('cfm/ton')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('cooling_system_actual_cfm_per_ton', false)
    arg.setDisplayName('Cooling System: Actual CFM Per Ton')
    arg.setUnits('cfm/ton')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('cooling_system_frac_manufacturer_charge', false)
    arg.setDisplayName('Cooling System: Fraction of Manufacturer Recommended Charge')
    arg.setUnits('Frac')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('heat_pump_rated_cfm_per_ton', false)
    arg.setDisplayName('Heat Pump: Rated CFM Per Ton')
    arg.setUnits('cfm/ton')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('heat_pump_actual_cfm_per_ton', false)
    arg.setDisplayName('Heat Pump: Actual CFM Per Ton')
    arg.setUnits('cfm/ton')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('heat_pump_frac_manufacturer_charge', false)
    arg.setDisplayName('Heat Pump: Fraction of Manufacturer Recommended Charge')
    arg.setUnits('Frac')
    args << arg

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # assign the user inputs to variables
    args = get_argument_values(runner, arguments(model), user_arguments)

    measures_dir = File.absolute_path(File.join(File.dirname(__FILE__), '../../resources/hpxml-measures'))
    measure_subdir = 'BuildResidentialHPXML'
    full_measure_path = File.join(measures_dir, measure_subdir, 'measure.rb')
    measure = get_measure_instance(full_measure_path)

    arg_names = []
    measure.arguments(model).each do |arg|
      next if Constants.excludes.include? arg.name

      arg_names << arg.name
    end

    args_to_delete = args.keys - arg_names # these are the extra ones added in the arguments section

    # Plug Loads
    args['plug_loads_television_annual_kwh'] = 0.0 # "other" now accounts for television
    args['plug_loads_television_usage_multiplier'] = 0.0 # "other" now accounts for television
    args['plug_loads_other_usage_multiplier'] *= args['plug_loads_other_usage_multiplier_2']
    args['plug_loads_well_pump_usage_multiplier'] *= args['plug_loads_well_pump_usage_multiplier_2']
    args['plug_loads_vehicle_usage_multiplier'] *= args['plug_loads_vehicle_usage_multiplier_2']

    if args['geometry_num_occupants'] == Constants.Auto
      args['geometry_num_occupants'] = Geometry.get_occupancy_default_num(args['geometry_num_bedrooms'])
    else
      args['geometry_num_occupants'] = Integer(args['geometry_num_occupants'])
    end

    if [HPXML::ResidentialTypeSFD].include?(args['geometry_unit_type'])
      args['plug_loads_other_annual_kwh'] = 1146.95 + 296.94 * args['geometry_num_occupants'] + 0.3 * args['geometry_cfa'] # RECS 2015
    elsif [HPXML::ResidentialTypeSFA].include?(args['geometry_unit_type'])
      args['plug_loads_other_annual_kwh'] = 1395.84 + 136.53 * args['geometry_num_occupants'] + 0.16 * args['geometry_cfa'] # RECS 2015
    elsif [HPXML::ResidentialTypeApartment].include?(args['geometry_unit_type'])
      args['plug_loads_other_annual_kwh'] = 875.22 + 184.11 * args['geometry_num_occupants'] + 0.38 * args['geometry_cfa'] # RECS 2015
    end

    # Setpoints
    weekday_heating_setpoints = [args['setpoint_heating_weekday_temp']] * 24
    weekend_heating_setpoints = [args['setpoint_heating_weekend_temp']] * 24

    weekday_cooling_setpoints = [args['setpoint_cooling_weekday_temp']] * 24
    weekend_cooling_setpoints = [args['setpoint_cooling_weekend_temp']] * 24

    setpoint_heating_weekday_offset_magnitude = args['setpoint_heating_weekday_offset_magnitude']
    setpoint_heating_weekday_schedule = args['setpoint_heating_weekday_schedule'].split(',').map { |i| Float(i) }
    weekday_heating_setpoints = modify_setpoint_schedule(weekday_heating_setpoints, setpoint_heating_weekday_offset_magnitude, setpoint_heating_weekday_schedule)

    setpoint_heating_weekend_offset_magnitude = args['setpoint_heating_weekend_offset_magnitude']
    setpoint_heating_weekend_schedule = args['setpoint_heating_weekend_schedule'].split(',').map { |i| Float(i) }
    weekend_heating_setpoints = modify_setpoint_schedule(weekend_heating_setpoints, setpoint_heating_weekend_offset_magnitude, setpoint_heating_weekend_schedule)

    setpoint_cooling_weekday_offset_magnitude = args['setpoint_cooling_weekday_offset_magnitude']
    setpoint_cooling_weekday_schedule = args['setpoint_cooling_weekday_schedule'].split(',').map { |i| Float(i) }
    weekday_cooling_setpoints = modify_setpoint_schedule(weekday_cooling_setpoints, setpoint_cooling_weekday_offset_magnitude, setpoint_cooling_weekday_schedule)

    setpoint_cooling_weekend_offset_magnitude = args['setpoint_cooling_weekend_offset_magnitude']
    setpoint_cooling_weekend_schedule = args['setpoint_cooling_weekend_schedule'].split(',').map { |i| Float(i) }
    weekend_cooling_setpoints = modify_setpoint_schedule(weekend_cooling_setpoints, setpoint_cooling_weekend_offset_magnitude, setpoint_cooling_weekend_schedule)

    args['setpoint_heating_weekday'] = weekday_heating_setpoints.join(', ')
    args['setpoint_heating_weekend'] = weekend_heating_setpoints.join(', ')
    args['setpoint_cooling_weekday'] = weekday_cooling_setpoints.join(', ')
    args['setpoint_cooling_weekend'] = weekend_cooling_setpoints.join(', ')

    # Flue or Chimney
    args['geometry_has_flue_or_chimney'] = Constants.Auto
    if (args['heating_system_has_flue_or_chimney'] == 'false') &&
       (args['heating_system_has_flue_or_chimney_2'] == 'false') &&
       (args['water_heater_has_flue_or_chimney'] == 'false')
      args['geometry_has_flue_or_chimney'] = 'false'
    elsif (args['heating_system_type'] != 'none' && args['heating_system_has_flue_or_chimney'] == 'true') ||
          (args['heating_system_type_2'] != 'none' && args['heating_system_has_flue_or_chimney_2'] == 'true') ||
          (args['water_heater_type'] != 'none' && args['water_heater_has_flue_or_chimney'] == 'true')
      args['geometry_has_flue_or_chimney'] = 'true'
    end

    # HVAC Faults
    if args['heating_system_rated_cfm_per_ton'].is_initialized && args['heating_system_actual_cfm_per_ton'].is_initialized
      args['heating_system_airflow_defect_ratio'] = (args['heating_system_actual_cfm_per_ton'].get - args['heating_system_rated_cfm_per_ton'].get) / args['heating_system_rated_cfm_per_ton'].get
    end

    if args['cooling_system_rated_cfm_per_ton'].is_initialized && args['cooling_system_actual_cfm_per_ton'].is_initialized
      args['cooling_system_airflow_defect_ratio'] = (args['cooling_system_actual_cfm_per_ton'].get - args['cooling_system_rated_cfm_per_ton'].get) / args['cooling_system_rated_cfm_per_ton'].get
    end

    if args['cooling_system_frac_manufacturer_charge'].is_initialized
      args['cooling_system_charge_defect_ratio'] = args['cooling_system_frac_manufacturer_charge'].get - 1.0
    end

    if args['heat_pump_rated_cfm_per_ton'].is_initialized && args['heat_pump_actual_cfm_per_ton'].is_initialized
      args['heat_pump_airflow_defect_ratio'] = (args['heat_pump_actual_cfm_per_ton'].get - args['heat_pump_rated_cfm_per_ton'].get) / args['cooling_system_rated_cfm_per_ton'].get
    end

    if args['heat_pump_frac_manufacturer_charge'].is_initialized
      args['heat_pump_charge_defect_ratio'] = args['heat_pump_frac_manufacturer_charge'].get - 1.0
    end

    args.each do |arg_name, arg_value|
      begin
        if arg_value.is_initialized
          arg_value = arg_value.get
        else
          next
        end
      rescue
      end

      if args_to_delete.include? arg_name
        arg_value = '' # don't assign these to BuildResidentialHPXML
      end

      runner.registerValue(arg_name, arg_value)
    end

    return true
  end

  def modify_setpoint_schedule(schedule, offset_magnitude, offset_schedule)
    offset_schedule.each_with_index do |direction, i|
      schedule[i] += offset_magnitude * direction
    end
    return schedule
  end
end

# register the measure to be used by the application
ResStockArguments.new.registerWithApplication
