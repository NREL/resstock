# frozen_string_literal: true

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require 'openstudio'
require_relative 'resources/constants'
require_relative '../../resources/hpxml-measures/HPXMLtoOpenStudio/resources/meta_measure'

# start the measure
class ResStockArguments < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    # Measure name should be the title case of the class name.
    return 'ResStock Arguments'
  end

  # human readable description
  def description
    return 'Measure that pre-processes the arguments passed to the BuildResidentialHPXML and BuildResidentialScheduleFile measures.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'Passes in all arguments from the options lookup, processes them, and then registers values to the runner to be used by other measures.'
  end

  # define the arguments that the user will input
  def arguments(model)
    measures_dir = File.absolute_path(File.join(File.dirname(__FILE__), '../../resources/hpxml-measures'))
    args = OpenStudio::Measure::OSArgumentVector.new

    # BuildResidentialHPXML

    full_measure_path = File.join(measures_dir, 'BuildResidentialHPXML', 'measure.rb')
    measure = get_measure_instance(full_measure_path)

    measure.arguments(model).each do |arg|
      next if Constants.build_residential_hpxml_excludes.include? arg.name

      # Following are arguments with the same name but different options
      next if arg.name == 'geometry_unit_cfa'

      # Convert optional arguments to string arguments that allow Constants.Auto for defaulting
      if !arg.required
        args << OpenStudio::Measure::OSArgument.makeStringArgument(arg.name, false)
      else
        args << arg
      end
    end

    # BuildResidentialScheduleFile

    full_measure_path = File.join(measures_dir, 'BuildResidentialScheduleFile', 'measure.rb')
    measure = get_measure_instance(full_measure_path)

    measure.arguments(model).each do |arg|
      next if Constants.build_residential_schedule_file_excludes.include? arg.name

      args << arg
    end

    # Additional arguments

    arg = OpenStudio::Measure::OSArgument::makeStringArgument('geometry_unit_cfa_bin', true)
    arg.setDisplayName('Geometry: Unit Conditioned Floor Area Bin')
    arg.setDescription("E.g., '2000-2499'.")
    arg.setDefaultValue('2000-2499')
    args << arg

    # Adds a geometry_unit_cfa argument similar to the BuildResidentialHPXML measure, but as a string with "auto" allowed
    arg = OpenStudio::Measure::OSArgument::makeStringArgument('geometry_unit_cfa', true)
    arg.setDisplayName('Geometry: Unit Conditioned Floor Area')
    arg.setDescription("E.g., '2000' or '#{Constants.Auto}'.")
    arg.setUnits('sqft')
    arg.setDefaultValue('2000')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('vintage', false)
    arg.setDisplayName('Building Construction: Vintage')
    arg.setDescription('The building vintage, used for informational purposes only.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeDoubleArgument('exterior_finish_r', true)
    arg.setDisplayName('Building Construction: Exterior Finish R-Value')
    arg.setUnits('h-ft^2-R/Btu')
    arg.setDescription('R-value of the exterior finish.')
    arg.setDefaultValue(0.6)
    args << arg

    level_choices = OpenStudio::StringVector.new
    level_choices << 'Bottom'
    level_choices << 'Middle'
    level_choices << 'Top'

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('geometry_unit_level', level_choices, false)
    arg.setDisplayName('Geometry: Unit Level')
    arg.setDescription("The level of the unit. This is required for #{HPXML::ResidentialTypeApartment}s.")
    args << arg

    horizontal_location_choices = OpenStudio::StringVector.new
    horizontal_location_choices << 'None'
    horizontal_location_choices << 'Left'
    horizontal_location_choices << 'Middle'
    horizontal_location_choices << 'Right'

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('geometry_unit_horizontal_location', horizontal_location_choices, false)
    arg.setDisplayName('Geometry: Unit Horizontal Location')
    arg.setDescription("The horizontal location of the unit when viewing the front of the building. This is required for #{HPXML::ResidentialTypeSFA} and #{HPXML::ResidentialTypeApartment}s.")
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeIntegerArgument('geometry_num_floors_above_grade', true)
    arg.setDisplayName('Geometry: Number of Floors Above Grade')
    arg.setUnits('#')
    arg.setDescription("The number of floors above grade (in the unit if #{HPXML::ResidentialTypeSFD} or #{HPXML::ResidentialTypeSFA}, and in the building if #{HPXML::ResidentialTypeApartment}). Conditioned attics are included.")
    arg.setDefaultValue(2)
    args << arg

    corridor_position_choices = OpenStudio::StringVector.new
    corridor_position_choices << 'Double-Loaded Interior'
    corridor_position_choices << 'Double Exterior'
    corridor_position_choices << 'Single Exterior (Front)'
    corridor_position_choices << 'None'

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('geometry_corridor_position', corridor_position_choices, true)
    arg.setDisplayName('Geometry: Corridor Position')
    arg.setDescription("The position of the corridor. Only applies to #{HPXML::ResidentialTypeSFA} and #{HPXML::ResidentialTypeApartment}s. Exterior corridors are shaded, but not enclosed. Interior corridors are enclosed and conditioned.")
    arg.setDefaultValue('Inside')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('geometry_corridor_width', true)
    arg.setDisplayName('Geometry: Corridor Width')
    arg.setUnits('ft')
    arg.setDescription("The width of the corridor. Only applies to #{HPXML::ResidentialTypeApartment}s.")
    arg.setDefaultValue(10.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('wall_continuous_exterior_r', false)
    arg.setDisplayName('Wall: Continuous Exterior Insulation Nominal R-value')
    arg.setUnits('h-ft^2-R/Btu')
    arg.setDescription('Nominal R-value for the wall continuous exterior insulation.')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('ceiling_insulation_r', true)
    arg.setDisplayName('Ceiling: Insulation Nominal R-value')
    arg.setUnits('h-ft^2-R/Btu')
    arg.setDescription('Nominal R-value for the ceiling (attic floor).')
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('rim_joist_continuous_exterior_r', true)
    arg.setDisplayName('Rim Joist: Continuous Exterior Insulation Nominal R-value')
    arg.setUnits('h-ft^2-R/Btu')
    arg.setDescription('Nominal R-value for the rim joist continuous exterior insulation. Only applies to basements/crawlspaces.')
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('rim_joist_continuous_interior_r', true)
    arg.setDisplayName('Rim Joist: Continuous Interior Insulation Nominal R-value')
    arg.setUnits('h-ft^2-R/Btu')
    arg.setDescription('Nominal R-value for the rim joist continuous interior insulation that runs parallel to floor joists. Only applies to basements/crawlspaces.')
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('rim_joist_assembly_interior_r', true)
    arg.setDisplayName('Rim Joist: Interior Assembly R-value')
    arg.setUnits('h-ft^2-R/Btu')
    arg.setDescription('Assembly R-value for the rim joist assembly interior insulation that runs perpendicular to floor joists. Only applies to basements/crawlspaces.')
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('air_leakage_percent_reduction', false)
    arg.setDisplayName('Air Leakage: Value Reduction')
    arg.setDescription('Reduction (%) on the air exchange rate value.')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('misc_plug_loads_other_2_usage_multiplier', true)
    arg.setDisplayName('Plug Loads: Other Usage Multiplier 2')
    arg.setDescription('Additional multiplier on the other energy usage that can reflect, e.g., high/low usage occupants.')
    arg.setDefaultValue(1.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('misc_plug_loads_well_pump_2_usage_multiplier', true)
    arg.setDisplayName('Plug Loads: Well Pump Usage Multiplier 2')
    arg.setDescription('Additional multiplier on the well pump energy usage that can reflect, e.g., high/low usage occupants.')
    arg.setDefaultValue(0.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('misc_plug_loads_vehicle_2_usage_multiplier', true)
    arg.setDisplayName('Plug Loads: Vehicle Usage Multiplier 2')
    arg.setDescription('Additional multiplier on the electric vehicle energy usage that can reflect, e.g., high/low usage occupants.')
    arg.setDefaultValue(0.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('hvac_control_heating_weekday_setpoint_temp', true)
    arg.setDisplayName('Heating Setpoint: Weekday Temperature')
    arg.setDescription('Specify the weekday heating setpoint temperature.')
    arg.setUnits('deg-F')
    arg.setDefaultValue(71)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('hvac_control_heating_weekend_setpoint_temp', true)
    arg.setDisplayName('Heating Setpoint: Weekend Temperature')
    arg.setDescription('Specify the weekend heating setpoint temperature.')
    arg.setUnits('deg-F')
    arg.setDefaultValue(71)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('hvac_control_heating_weekday_setpoint_offset_magnitude', true)
    arg.setDisplayName('Heating Setpoint: Weekday Offset Magnitude')
    arg.setDescription('Specify the weekday heating offset magnitude.')
    arg.setUnits('deg-F')
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('hvac_control_heating_weekend_setpoint_offset_magnitude', true)
    arg.setDisplayName('Heating Setpoint: Weekend Offset Magnitude')
    arg.setDescription('Specify the weekend heating offset magnitude.')
    arg.setUnits('deg-F')
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument('hvac_control_heating_weekday_setpoint_schedule', true)
    arg.setDisplayName('Heating Setpoint: Weekday Schedule')
    arg.setDescription('Specify the 24-hour comma-separated weekday heating schedule of 0s and 1s.')
    arg.setDefaultValue('0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument('hvac_control_heating_weekend_setpoint_schedule', true)
    arg.setDisplayName('Heating Setpoint: Weekend Schedule')
    arg.setDescription('Specify the 24-hour comma-separated weekend heating schedule of 0s and 1s.')
    arg.setDefaultValue('0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('use_auto_heating_season', true)
    arg.setDisplayName('Use Auto Heating Season')
    arg.setDescription('Specifies whether to automatically define the heating season based on the weather file.')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('hvac_control_cooling_weekday_setpoint_temp', true)
    arg.setDisplayName('Cooling Setpoint: Weekday Temperature')
    arg.setDescription('Specify the weekday cooling setpoint temperature.')
    arg.setUnits('deg-F')
    arg.setDefaultValue(76)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('hvac_control_cooling_weekend_setpoint_temp', true)
    arg.setDisplayName('Cooling Setpoint: Weekend Temperature')
    arg.setDescription('Specify the weekend cooling setpoint temperature.')
    arg.setUnits('deg-F')
    arg.setDefaultValue(76)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('hvac_control_cooling_weekday_setpoint_offset_magnitude', true)
    arg.setDisplayName('Cooling Setpoint: Weekday Offset Magnitude')
    arg.setDescription('Specify the weekday cooling offset magnitude.')
    arg.setUnits('deg-F')
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('hvac_control_cooling_weekend_setpoint_offset_magnitude', true)
    arg.setDisplayName('Cooling Setpoint: Weekend Offset Magnitude')
    arg.setDescription('Specify the weekend cooling offset magnitude.')
    arg.setUnits('deg-F')
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument('hvac_control_cooling_weekday_setpoint_schedule', true)
    arg.setDisplayName('Cooling Setpoint: Weekday Schedule')
    arg.setDescription('Specify the 24-hour comma-separated weekday cooling schedule of 0s and 1s.')
    arg.setDefaultValue('0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument('hvac_control_cooling_weekend_setpoint_schedule', true)
    arg.setDisplayName('Cooling Setpoint: Weekend Schedule')
    arg.setDescription('Specify the 24-hour comma-separated weekend cooling schedule of 0s and 1s.')
    arg.setDefaultValue('0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('use_auto_cooling_season', true)
    arg.setDisplayName('Use Auto Cooling Season')
    arg.setDescription('Specifies whether to automatically define the cooling season based on the weather file.')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument('heating_system_has_flue_or_chimney', true)
    arg.setDisplayName('Heating System: Has Flue or Chimney')
    arg.setDescription('Whether the heating system has a flue or chimney.')
    arg.setDefaultValue(Constants.Auto)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument('heating_system_2_has_flue_or_chimney', true)
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
    arg_names = []
    { 'BuildResidentialHPXML' => Constants.build_residential_hpxml_excludes,
      'BuildResidentialScheduleFile' => Constants.build_residential_schedule_file_excludes }.each do |measure_name, measure_excludes|
      full_measure_path = File.join(measures_dir, measure_name, 'measure.rb')
      measure = get_measure_instance(full_measure_path)

      measure.arguments(model).each do |arg|
        next if measure_excludes.include? arg.name

        arg_names << arg.name.to_sym
      end
    end

    args_to_delete = args.keys - arg_names # these are the extra ones added in the arguments section

    # Conditioned floor area
    if args[:geometry_unit_cfa] == Constants.Auto
      cfas = { ['0-499', HPXML::ResidentialTypeSFD] => 298, # AHS 2021, 1 detached and mobile home weighted average
               ['0-499', HPXML::ResidentialTypeSFA] => 273, # AHS 2021, 1 detached and mobile home weighted average
               ['0-499', HPXML::ResidentialTypeApartment] => 322, # AHS 2021, multi-family weighted average
               ['500-749', HPXML::ResidentialTypeSFD] => 634, # AHS 2021, 1 detached and mobile home weighted average
               ['500-749', HPXML::ResidentialTypeSFA] => 625, # AHS 2021, 1 attached
               ['500-749', HPXML::ResidentialTypeApartment] => 623, # AHS 2021, multi-family weighted average
               ['750-999', HPXML::ResidentialTypeSFD] => 881, # AHS 2021, 1 detached and mobile home weighted average
               ['750-999', HPXML::ResidentialTypeSFA] => 872, # AHS 2021, 1 attached
               ['750-999', HPXML::ResidentialTypeApartment] => 854, # AHS 2021, multi-family weighted average
               ['1000-1499', HPXML::ResidentialTypeSFD] => 1228, # AHS 2021, 1 detached and mobile home weighted average
               ['1000-1499', HPXML::ResidentialTypeSFA] => 1207, # AHS 2021, 1 attached
               ['1000-1499', HPXML::ResidentialTypeApartment] => 1138, # AHS 2021, multi-family weighted average
               ['1500-1999', HPXML::ResidentialTypeSFD] => 1698, # AHS 2021, 1 detached and mobile home weighted average
               ['1500-1999', HPXML::ResidentialTypeSFA] => 1678, # AHS 2021, 1 attached
               ['1500-1999', HPXML::ResidentialTypeApartment] => 1682, # AHS 2021, multi-family weighted average
               ['2000-2499', HPXML::ResidentialTypeSFD] => 2179, # AHS 2021, 1 detached and mobile home weighted average
               ['2000-2499', HPXML::ResidentialTypeSFA] => 2152, # AHS 2021, 1 attached
               ['2000-2499', HPXML::ResidentialTypeApartment] => 2115, # AHS 2021, multi-family weighted average
               ['2500-2999', HPXML::ResidentialTypeSFD] => 2678, # AHS 2021, 1 detached and mobile home weighted average
               ['2500-2999', HPXML::ResidentialTypeSFA] => 2663, # AHS 2021, 1 attached
               ['2500-2999', HPXML::ResidentialTypeApartment] => 2648, # AHS 2021, multi-family weighted average
               ['3000-3999', HPXML::ResidentialTypeSFD] => 3310, # AHS 2021, 1 detached and mobile home weighted average
               ['3000-3999', HPXML::ResidentialTypeSFA] => 3228, # AHS 2021, 1 attached
               ['3000-3999', HPXML::ResidentialTypeApartment] => 33171, # AHS 2021, multi-family weighted average
               ['4000+', HPXML::ResidentialTypeSFD] => 5587, # AHS 2021, 1 detached and mobile home weighted average
               ['4000+', HPXML::ResidentialTypeSFA] => 7414, # AHS 2019, 1 attached
               ['4000+', HPXML::ResidentialTypeApartment] => 6348 } # AHS 2021, 4,000 or more all unit average
      cfa = cfas[[args[:geometry_unit_cfa_bin], args[:geometry_unit_type]]]
      if cfa.nil?
        runner.registerError("ResStockArguments: Could not look up conditioned floor area for '#{args[:geometry_unit_cfa_bin]}' and '#{args[:geometry_unit_type]}'.")
        return false
      end
      args[:geometry_unit_cfa] = Float(cfa)
    else
      args[:geometry_unit_cfa] = Float(args[:geometry_unit_cfa])
    end

    # Vintage
    if args[:vintage].is_initialized
      args[:year_built] = Integer(Float(args[:vintage].get.gsub(/[^0-9]/, ''))) # strip non-numeric
    end

    # Num Occupants
    if args[:geometry_unit_num_occupants].to_s == Constants.Auto
      args[:geometry_unit_num_occupants] = Geometry.get_occupancy_default_num(args[:geometry_unit_num_bedrooms])
    else
      args[:geometry_unit_num_occupants] = Integer(args[:geometry_unit_num_occupants].to_s)
    end

    # Plug Loads
    args[:misc_plug_loads_television_annual_kwh] = 0.0 # "other" now accounts for television
    args[:misc_plug_loads_television_usage_multiplier] = 0.0 # "other" now accounts for television
    args[:misc_plug_loads_other_usage_multiplier] = Float(args[:misc_plug_loads_other_usage_multiplier].to_s) * args[:misc_plug_loads_other_2_usage_multiplier]
    args[:misc_plug_loads_well_pump_usage_multiplier] = Float(args[:misc_plug_loads_well_pump_usage_multiplier].to_s) * args[:misc_plug_loads_well_pump_2_usage_multiplier]
    args[:misc_plug_loads_vehicle_usage_multiplier] = Float(args[:misc_plug_loads_vehicle_usage_multiplier].to_s) * args[:misc_plug_loads_vehicle_2_usage_multiplier]

    if args[:misc_plug_loads_other_annual_kwh].to_s == Constants.Auto
      if [HPXML::ResidentialTypeSFD].include?(args[:geometry_unit_type])
        args[:misc_plug_loads_other_annual_kwh] = 1146.95 + 296.94 * args[:geometry_unit_num_occupants] + 0.3 * args[:geometry_unit_cfa] # RECS 2015
      elsif [HPXML::ResidentialTypeSFA].include?(args[:geometry_unit_type])
        args[:misc_plug_loads_other_annual_kwh] = 1395.84 + 136.53 * args[:geometry_unit_num_occupants] + 0.16 * args[:geometry_unit_cfa] # RECS 2015
      elsif [HPXML::ResidentialTypeApartment].include?(args[:geometry_unit_type])
        args[:misc_plug_loads_other_annual_kwh] = 875.22 + 184.11 * args[:geometry_unit_num_occupants] + 0.38 * args[:geometry_unit_cfa] # RECS 2015
      end
    end

    # PV
    if args[:pv_system_module_type] != 'none'
      args[:pv_system_num_bedrooms_served] = Integer(args[:geometry_unit_num_bedrooms])
    else
      args[:pv_system_num_bedrooms_served] = 0
    end

    # Setpoints
    weekday_heating_setpoints = [args[:hvac_control_heating_weekday_setpoint_temp]] * 24
    weekend_heating_setpoints = [args[:hvac_control_heating_weekend_setpoint_temp]] * 24

    weekday_cooling_setpoints = [args[:hvac_control_cooling_weekday_setpoint_temp]] * 24
    weekend_cooling_setpoints = [args[:hvac_control_cooling_weekend_setpoint_temp]] * 24

    hvac_control_heating_weekday_setpoint_offset_magnitude = args[:hvac_control_heating_weekday_setpoint_offset_magnitude]
    hvac_control_heating_weekday_setpoint_schedule = args[:hvac_control_heating_weekday_setpoint_schedule].split(',').map { |i| Float(i) }
    weekday_heating_setpoints = modify_setpoint_schedule(weekday_heating_setpoints, hvac_control_heating_weekday_setpoint_offset_magnitude, hvac_control_heating_weekday_setpoint_schedule)

    hvac_control_heating_weekend_setpoint_offset_magnitude = args[:hvac_control_heating_weekend_setpoint_offset_magnitude]
    hvac_control_heating_weekend_setpoint_schedule = args[:hvac_control_heating_weekend_setpoint_schedule].split(',').map { |i| Float(i) }
    weekend_heating_setpoints = modify_setpoint_schedule(weekend_heating_setpoints, hvac_control_heating_weekend_setpoint_offset_magnitude, hvac_control_heating_weekend_setpoint_schedule)

    hvac_control_cooling_weekday_setpoint_offset_magnitude = args[:hvac_control_cooling_weekday_setpoint_offset_magnitude]
    hvac_control_cooling_weekday_setpoint_schedule = args[:hvac_control_cooling_weekday_setpoint_schedule].split(',').map { |i| Float(i) }
    weekday_cooling_setpoints = modify_setpoint_schedule(weekday_cooling_setpoints, hvac_control_cooling_weekday_setpoint_offset_magnitude, hvac_control_cooling_weekday_setpoint_schedule)

    hvac_control_cooling_weekend_setpoint_offset_magnitude = args[:hvac_control_cooling_weekend_setpoint_offset_magnitude]
    hvac_control_cooling_weekend_setpoint_schedule = args[:hvac_control_cooling_weekend_setpoint_schedule].split(',').map { |i| Float(i) }
    weekend_cooling_setpoints = modify_setpoint_schedule(weekend_cooling_setpoints, hvac_control_cooling_weekend_setpoint_offset_magnitude, hvac_control_cooling_weekend_setpoint_schedule)

    args[:hvac_control_heating_weekday_setpoint] = weekday_heating_setpoints.join(', ')
    args[:hvac_control_heating_weekend_setpoint] = weekend_heating_setpoints.join(', ')
    args[:hvac_control_cooling_weekday_setpoint] = weekday_cooling_setpoints.join(', ')
    args[:hvac_control_cooling_weekend_setpoint] = weekend_cooling_setpoints.join(', ')

    # Seasons
    if args[:use_auto_heating_season]
      args[:hvac_control_heating_season_period] = HPXML::BuildingAmerica
    end

    if args[:use_auto_cooling_season]
      args[:hvac_control_cooling_season_period] = HPXML::BuildingAmerica
    end

    # Flue or Chimney
    if (args[:heating_system_has_flue_or_chimney] == 'false') &&
       (args[:heating_system_2_has_flue_or_chimney] == 'false') &&
       (args[:water_heater_has_flue_or_chimney] == 'false')
      args[:air_leakage_has_flue_or_chimney_in_conditioned_space] = false
    elsif (args[:heating_system_type] != 'none' && args[:heating_system_has_flue_or_chimney] == 'true') ||
          (args[:heating_system_2_type] != 'none' && args[:heating_system_2_has_flue_or_chimney] == 'true') ||
          (args[:water_heater_type] != 'none' && args[:water_heater_has_flue_or_chimney] == 'true')
      args[:air_leakage_has_flue_or_chimney_in_conditioned_space] = true
    end

    # HVAC Faults
    if args[:heating_system_rated_cfm_per_ton].is_initialized && args[:heating_system_actual_cfm_per_ton].is_initialized
      args[:heating_system_airflow_defect_ratio] = (args[:heating_system_actual_cfm_per_ton].get - args[:heating_system_rated_cfm_per_ton].get) / args[:heating_system_rated_cfm_per_ton].get
    end

    if args[:cooling_system_rated_cfm_per_ton].is_initialized && args[:cooling_system_actual_cfm_per_ton].is_initialized
      args[:cooling_system_airflow_defect_ratio] = (args[:cooling_system_actual_cfm_per_ton].get - args[:cooling_system_rated_cfm_per_ton].get) / args[:cooling_system_rated_cfm_per_ton].get
    end

    if args[:cooling_system_frac_manufacturer_charge].is_initialized
      args[:cooling_system_charge_defect_ratio] = args[:cooling_system_frac_manufacturer_charge].get - 1.0
    end

    if args[:heat_pump_rated_cfm_per_ton].is_initialized && args[:heat_pump_actual_cfm_per_ton].is_initialized
      args[:heat_pump_airflow_defect_ratio] = (args[:heat_pump_actual_cfm_per_ton].get - args[:heat_pump_rated_cfm_per_ton].get) / args[:cooling_system_rated_cfm_per_ton].get
    end

    if args[:heat_pump_frac_manufacturer_charge].is_initialized
      args[:heat_pump_charge_defect_ratio] = args[:heat_pump_frac_manufacturer_charge].get - 1.0
    end

    # Error check geometry inputs
    corridor_width = args[:geometry_corridor_width]
    corridor_position = args[:geometry_corridor_position].to_s

    if (corridor_width == 0) && (corridor_position != 'None')
      corridor_position = 'None'
    end
    if corridor_position == 'None'
      corridor_width = 0
    end
    if corridor_width < 0
      runner.registerError('ResStockArguments: Invalid corridor width entered.')
      return false
    end

    # Adiabatic Walls
    args[:geometry_unit_left_wall_is_adiabatic] = false
    args[:geometry_unit_right_wall_is_adiabatic] = false
    args[:geometry_unit_front_wall_is_adiabatic] = false
    args[:geometry_unit_back_wall_is_adiabatic] = false

    # Map corridor arguments to adiabatic walls and shading
    n_floors = Float(args[:geometry_num_floors_above_grade].to_s)
    if [HPXML::ResidentialTypeApartment, HPXML::ResidentialTypeSFA].include? args[:geometry_unit_type]
      n_units = Float(args[:geometry_building_num_units].to_s)
      horiz_location = args[:geometry_unit_horizontal_location].to_s
      aspect_ratio = Float(args[:geometry_unit_aspect_ratio].to_s)

      if args[:geometry_unit_type] == HPXML::ResidentialTypeApartment
        n_units_per_floor = n_units / n_floors
        if n_units_per_floor >= 4 && (corridor_position == 'Double Exterior' || corridor_position == 'None')
          has_rear_units = true
          args[:geometry_unit_back_wall_is_adiabatic] = true
        elsif n_units_per_floor >= 4 && (corridor_position == 'Double-Loaded Interior')
          has_rear_units = true
          args[:geometry_unit_front_wall_is_adiabatic] = true
        elsif (n_units_per_floor == 2) && (horiz_location == 'None') && (corridor_position == 'Double Exterior' || corridor_position == 'None')
          has_rear_units = true
          args[:geometry_unit_back_wall_is_adiabatic] = true
        elsif (n_units_per_floor == 2) && (horiz_location == 'None') && (corridor_position == 'Double-Loaded Interior')
          has_rear_units = true
          args[:geometry_unit_front_wall_is_adiabatic] = true
        elsif corridor_position == 'Single Exterior (Front)'
          has_rear_units = false
          args[:geometry_unit_front_wall_is_adiabatic] = false
        else
          has_rear_units = false
          args[:geometry_unit_front_wall_is_adiabatic] = false
        end

        # Error check MF & SFA geometry
        if !has_rear_units && ((corridor_position == 'Double-Loaded Interior') || (corridor_position == 'Double Exterior'))
          corridor_position = 'Single Exterior (Front)'
          runner.registerWarning("Specified incompatible corridor; setting corridor position to '#{corridor_position}'.")
        end

        # Model exterior corridors as overhangs
        if (corridor_position.include? 'Exterior') && corridor_width > 0
          args[:overhangs_front_depth] = corridor_width
          args[:overhangs_front_distance_to_top_of_window] = 1
        end

      elsif args[:geometry_unit_type] == HPXML::ResidentialTypeSFA
        n_floors = 1.0
        n_units_per_floor = n_units
        has_rear_units = false
      end

      if has_rear_units
        unit_width = n_units_per_floor / 2
      else
        unit_width = n_units_per_floor
      end
      if (unit_width <= 1) && (horiz_location != 'None')
        runner.registerWarning("No #{horiz_location} location exists, setting horizontal location to 'None'")
        horiz_location = 'None'
      end
      if (unit_width > 1) && (horiz_location == 'None')
        runner.registerError('ResStockArguments: Specified incompatible horizontal location for the corridor and unit configuration.')
        return false
      end
      if (unit_width <= 2) && (horiz_location == 'Middle')
        runner.registerError('ResStockArguments: Invalid horizontal location entered, no middle location exists.')
        return false
      end

      # Infiltration adjustment for SFA/MF units
      # Calculate exposed wall area ratio for the unit (unit exposed wall area
      # divided by average unit exposed wall area)
      if (n_units_per_floor <= 2) || (n_units_per_floor == 4 && has_rear_units) # No middle unit(s)
        exposed_wall_area_ratio = 1.0 # all units have same exterior wall area
      else # Has middle unit(s)
        if has_rear_units
          n_end_units = 4 * n_floors
          n_mid_units = n_units - n_end_units
          n_bldg_fronts_backs = n_end_units + n_mid_units
          n_bldg_sides = n_end_units
        else
          n_end_units = 2 * n_floors
          n_mid_units = n_units - n_end_units
          n_bldg_fronts_backs = n_end_units * 2 + n_mid_units * 2
          n_bldg_sides = n_end_units
        end
        if has_rear_units
          n_unit_fronts_backs = 1
        else
          n_unit_fronts_backs = 2
        end
        if ['Middle'].include? horiz_location
          n_unit_sides = 0
        elsif ['Left', 'Right'].include? horiz_location
          n_unit_sides = 1
        end
        n_bldg_sides_equivalent = n_bldg_sides + n_bldg_fronts_backs * aspect_ratio
        n_unit_sides_equivalent = n_unit_sides + n_unit_fronts_backs * aspect_ratio
        exposed_wall_area_ratio = n_unit_sides_equivalent / (n_bldg_sides_equivalent / n_units)
      end

      # Apply adjustment to infiltration value
      args[:air_leakage_value] *= exposed_wall_area_ratio

      if horiz_location == 'Left'
        args[:geometry_unit_right_wall_is_adiabatic] = true
      elsif horiz_location == 'Middle'
        args[:geometry_unit_left_wall_is_adiabatic] = true
        args[:geometry_unit_right_wall_is_adiabatic] = true
      elsif horiz_location == 'Right'
        args[:geometry_unit_left_wall_is_adiabatic] = true
      end
    end

    # Infiltration Reduction
    if args[:air_leakage_percent_reduction].is_initialized
      args[:air_leakage_value] *= (1.0 - args[:air_leakage_percent_reduction].get / 100.0)
    end

    # Num Floors
    if args[:geometry_unit_type] == HPXML::ResidentialTypeApartment
      args[:geometry_unit_num_floors_above_grade] = 1
    else
      args[:geometry_unit_num_floors_above_grade] = Integer(args[:geometry_num_floors_above_grade])
    end

    # Adiabatic Floor/Ceiling
    if args[:geometry_unit_level].is_initialized
      if args[:geometry_unit_level].get == 'Bottom'
        if args[:geometry_num_floors_above_grade] > 1 # this could be "bottom" of a 1-story building
          args[:geometry_attic_type] = HPXML::AtticTypeBelowApartment
        end
      elsif args[:geometry_unit_level].get == 'Middle'
        args[:geometry_foundation_type] = HPXML::FoundationTypeAboveApartment
        args[:geometry_attic_type] = HPXML::AtticTypeBelowApartment
      elsif args[:geometry_unit_level].get == 'Top'
        args[:geometry_foundation_type] = HPXML::FoundationTypeAboveApartment
      end
    end

    # Wall Assembly R-Value
    args[:wall_assembly_r] += args[:exterior_finish_r]

    if args[:wall_continuous_exterior_r].is_initialized
      args[:wall_assembly_r] += args[:wall_continuous_exterior_r].get
    end

    # Rim Joist Assembly R-Value
    rim_joist_assembly_r = 0
    if Float(args[:geometry_rim_joist_height].to_s) > 0
      drywall_assembly_r = 0.9
      uninsulated_wall_assembly_r = 3.4

      assembly_exterior_r = args[:exterior_finish_r] + args[:rim_joist_continuous_exterior_r]

      if args[:rim_joist_continuous_interior_r] > 0 && args[:rim_joist_assembly_interior_r] > 0
        # rim joist assembly = siding + half continuous interior insulation + half rim joist assembly - drywall
        # (rim joist assembly = nominal cavity + 1/2 in sheathing + 1/2 in drywall)
        assembly_interior_r = (args[:rim_joist_continuous_interior_r] + uninsulated_wall_assembly_r - drywall_assembly_r) / 2.0 # parallel to floor joists
        assembly_interior_r += (args[:rim_joist_assembly_interior_r]) / 2.0 # derated
      elsif args[:rim_joist_continuous_interior_r] > 0 || args[:rim_joist_assembly_interior_r] > 0
        runner.registerError('ResStockArguments: For rim joist interior insulation, must provide both continuous and assembly R-values.')
        return false
      else # uninsulated interior
        # rim joist assembly = siding + continuous foundation insulation + uninsulated wall - drywall
        # (uninsulated wall is nominal cavity + 1/2 in sheathing + 1/2 in drywall)
        assembly_interior_r = uninsulated_wall_assembly_r - drywall_assembly_r
      end

      rim_joist_assembly_r = assembly_exterior_r + assembly_interior_r
    end
    args[:rim_joist_assembly_r] = rim_joist_assembly_r

    args.each do |arg_name, arg_value|
      begin
        if arg_value.is_initialized
          arg_value = arg_value.get
        else
          next
        end
      rescue
      end

      if args_to_delete.include?(arg_name) || (arg_value == Constants.Auto)
        arg_value = '' # don't assign these to BuildResidentialHPXML or BuildResidentialScheduleFile
      end

      register_value(runner, arg_name.to_s, arg_value)
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
