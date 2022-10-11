# frozen_string_literal: true

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require 'openstudio'
require 'pathname'
require 'oga'
Dir["#{File.dirname(__FILE__)}/resources/*.rb"].each do |resource_file|
  require resource_file
end
Dir["#{File.dirname(__FILE__)}/../HPXMLtoOpenStudio/resources/*.rb"].each do |resource_file|
  next if resource_file.include? 'minitest_helper.rb'

  require resource_file
end

# start the measure
class BuildResidentialScheduleFile < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    return 'Schedule File Builder'
  end

  # human readable description
  def description
    return 'Builds a residential schedule file.'
  end

  # human readable description of modeling approach
  def modeler_description
    return "Generates a CSV of schedules at the specified file path, and inserts the CSV schedule file path into the output HPXML file (or overwrites it if one already exists). Schedules corresponding to 'smooth' are average (e.g., Building America). Schedules corresponding to 'stochastic' are generated using time-inhomogeneous Markov chains derived from American Time Use Survey data, and supplemented with sampling duration and power level from NEEA RBSA data as well as DHW draw duration and flow rate from Aquacraft/AWWA data."
  end

  # define the arguments that the user will input
  def arguments(model) # rubocop:disable Lint/UnusedMethodArgument
    args = OpenStudio::Measure::OSArgumentVector.new

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('hpxml_path', true)
    arg.setDisplayName('HPXML File Path')
    arg.setDescription('Absolute/relative path of the HPXML file.')
    args << arg

    schedules_type_choices = OpenStudio::StringVector.new
    schedules_type_choices << 'smooth'
    schedules_type_choices << 'stochastic'

    arg = OpenStudio::Measure::OSArgument.makeChoiceArgument('schedules_type', schedules_type_choices, true)
    arg.setDisplayName('Schedules: Type')
    arg.setDescription('The type of occupant-related schedules to use.')
    arg.setDefaultValue('smooth')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('schedules_vacancy_period', false)
    arg.setDisplayName('Schedules: Vacancy Period')
    arg.setDescription('Specifies the vacancy period. Enter a date like "Dec 15 - Jan 15".')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('schedules_outage_period', false)
    arg.setDisplayName('Schedules: Outage Period')
    arg.setDescription('Specifies the outage period. Enter a date/time like "Dec 15 10am - Jan 15 2pm". For start date/time, "12am" is the beginning of the day. For end date/time, "12am" is the end of the day.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeBoolArgument('schedules_outage_window_natvent_availability', false)
    arg.setDisplayName('Schedules: Outage Period Natural Ventilation Availability')
    arg.setDescription('Whether natural ventilation is available during the outage period.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeIntegerArgument('schedules_random_seed', false)
    arg.setDisplayName('Schedules: Random Seed')
    arg.setUnits('#')
    arg.setDescription("This numeric field is the seed for the random number generator. Only applies if the schedules type is 'stochastic'.")
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('output_csv_path', true)
    arg.setDisplayName('Schedules: Output CSV Path')
    arg.setDescription('Absolute/relative path of the CSV file containing occupancy schedules. Relative paths are relative to the HPXML output path.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('hpxml_output_path', true)
    arg.setDisplayName('HPXML Output File Path')
    arg.setDescription('Absolute/relative output path of the HPXML file. This HPXML file will include the output CSV path.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeBoolArgument('debug', false)
    arg.setDisplayName('Debug Mode?')
    arg.setDescription('Applicable when schedules type is stochastic. If true: Write extra state column(s).')
    arg.setDefaultValue(false)
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
    args = Hash[args.collect { |k, v| [k.to_sym, v] }]

    hpxml_path = args[:hpxml_path]
    unless (Pathname.new hpxml_path).absolute?
      hpxml_path = File.expand_path(hpxml_path)
    end
    unless File.exist?(hpxml_path) && hpxml_path.downcase.end_with?('.xml')
      fail "'#{hpxml_path}' does not exist or is not an .xml file."
    end

    hpxml_output_path = args[:hpxml_output_path]
    unless (Pathname.new hpxml_output_path).absolute?
      hpxml_output_path = File.expand_path(hpxml_output_path)
    end
    args[:hpxml_output_path] = hpxml_output_path

    hpxml = HPXML.new(hpxml_path: hpxml_path)

    # create EpwFile object
    epw_path = Location.get_epw_path(hpxml, hpxml_path)
    epw_file = OpenStudio::EpwFile.new(epw_path)

    # create the schedules
    success = create_schedules(runner, hpxml, epw_file, args)
    return false if not success

    # modify the hpxml with the schedules path
    doc = XMLHelper.parse_file(hpxml_path)
    extension = XMLHelper.create_elements_as_needed(XMLHelper.get_element(doc, '/HPXML'), ['SoftwareInfo', 'extension'])
    schedules_filepaths = XMLHelper.get_values(extension, 'SchedulesFilePath', :string)
    if !schedules_filepaths.include?(args[:output_csv_path])
      XMLHelper.add_element(extension, 'SchedulesFilePath', args[:output_csv_path], :string)
    end

    # write out the modified hpxml
    if (hpxml_path != hpxml_output_path) || !schedules_filepaths.include?(args[:output_csv_path])
      XMLHelper.write_file(doc, hpxml_output_path)
      runner.registerInfo("Wrote file: #{hpxml_output_path}")
    end

    return true
  end

  def create_schedules(runner, hpxml, epw_file, args)
    info_msgs = []

    get_simulation_parameters(hpxml, epw_file, args)
    get_generator_inputs(hpxml, epw_file, args)

    args[:resources_path] = File.join(File.dirname(__FILE__), 'resources')
    schedule_generator = ScheduleGenerator.new(runner: runner, epw_file: epw_file, **args)

    success = schedule_generator.create(args: args)
    return false if not success

    output_csv_path = args[:output_csv_path]
    unless (Pathname.new output_csv_path).absolute?
      output_csv_path = File.expand_path(File.join(File.dirname(args[:hpxml_output_path]), output_csv_path))
    end

    success = schedule_generator.export(schedules_path: output_csv_path)
    return false if not success

    info_msgs << "SimYear=#{args[:sim_year]}"
    info_msgs << "MinutesPerStep=#{args[:minutes_per_step]}"
    info_msgs << "State=#{args[:state]}"
    info_msgs << "RandomSeed=#{args[:random_seed]}" if args[:schedules_random_seed].is_initialized
    info_msgs << "GeometryNumOccupants=#{args[:geometry_num_occupants]}"
    info_msgs << "VacancyPeriod=#{args[:schedules_vacancy_period].get}" if args[:schedules_vacancy_period].is_initialized
    info_msgs << "OutagePeriod=#{args[:schedules_outage_period].get}" if args[:schedules_outage_period].is_initialized

    runner.registerInfo("Created #{args[:schedules_type]} schedule with #{info_msgs.join(', ')}")

    return true
  end

  def get_simulation_parameters(hpxml, epw_file, args)
    args[:minutes_per_step] = 60
    if !hpxml.header.timestep.nil?
      args[:minutes_per_step] = hpxml.header.timestep
    end
    args[:steps_in_hour] = 60 / args[:minutes_per_step]
    args[:steps_in_day] = 24 * args[:steps_in_hour]
    args[:mkc_ts_per_day] = 96
    args[:mkc_ts_per_hour] = args[:mkc_ts_per_day] / 24

    calendar_year = Location.get_sim_calendar_year(hpxml.header.sim_calendar_year, epw_file)
    args[:sim_year] = calendar_year
    args[:sim_start_day] = DateTime.new(args[:sim_year], 1, 1)
    args[:total_days_in_year] = Constants.NumDaysInYear(calendar_year)
  end

  def get_generator_inputs(hpxml, epw_file, args)
    args[:state] = 'CO'
    args[:state] = epw_file.stateProvinceRegion if Constants.StateCodesMap.keys.include?(epw_file.stateProvinceRegion)
    args[:state] = hpxml.header.state_code if !hpxml.header.state_code.nil?

    args[:random_seed] = args[:schedules_random_seed].get if args[:schedules_random_seed].is_initialized

    if hpxml.building_occupancy.number_of_residents.nil?
      args[:geometry_num_occupants] = Geometry.get_occupancy_default_num(hpxml.building_construction.number_of_bedrooms)
    else
      args[:geometry_num_occupants] = hpxml.building_occupancy.number_of_residents
    end
    # Stochastic occupancy required integer number of occupants
    if args[:schedules_type] == 'stochastic'
      args[:geometry_num_occupants] = Float(Integer(args[:geometry_num_occupants]))
    end

    # Local Ventilation
    vent_fans_kitchen = []
    vent_fans_bath = []
    hpxml.ventilation_fans.each do |vent_fan|
      next unless vent_fan.hours_in_operation.nil? || vent_fan.hours_in_operation > 0

      if vent_fan.used_for_local_ventilation
        if vent_fan.fan_location == HPXML::LocationKitchen
          vent_fans_kitchen << vent_fan
        elsif vent_fan.fan_location == HPXML::LocationBath
          vent_fans_bath << vent_fan
        end
      end
    end

    args[:kitchen_fan_hours_in_operation] = 1.0
    args[:kitchen_fan_start_hour] = 18
    if !vent_fans_kitchen.empty?
      # FIXME: what if 2+?
      args[:kitchen_fan_hours_in_operation] = vent_fans_kitchen[0].hours_in_operation if !vent_fans_kitchen[0].hours_in_operation.nil?
      args[:kitchen_fan_start_hour] = vent_fans_kitchen[0].start_hour if !vent_fans_kitchen[0].start_hour.nil?
    end

    args[:bath_fan_hours_in_operation] = 1.0
    args[:bath_fan_start_hour] = 7
    if !vent_fans_bath.empty?
      # FIXME: what if 2+?
      args[:bath_fan_hours_in_operation] = vent_fans_bath[0].hours_in_operation if !vent_fans_bath[0].hours_in_operation.nil?
      args[:bath_fan_start_hour] = vent_fans_bath[0].start_hour if !vent_fans_bath[0].start_hour.nil?
    end

    # Whole House Fan
    args[:whole_house_fan_availability] = 7

    # Vacancy
    if args[:schedules_vacancy_period].is_initialized
      begin_month, begin_day, end_month, end_day = Schedule.parse_date_range(args[:schedules_vacancy_period].get)
      args[:schedules_vacancy_begin_month] = begin_month
      args[:schedules_vacancy_begin_day] = begin_day
      args[:schedules_vacancy_end_month] = end_month
      args[:schedules_vacancy_end_day] = end_day
    end

    # Outage
    if args[:schedules_outage_period].is_initialized
      begin_month, begin_day, begin_hour, end_month, end_day, end_hour = Schedule.parse_date_time_range(args[:schedules_outage_period].get)
      args[:schedules_outage_begin_month] = begin_month
      args[:schedules_outage_begin_day] = begin_day
      args[:schedules_outage_begin_hour] = begin_hour
      args[:schedules_outage_end_month] = end_month
      args[:schedules_outage_end_day] = end_day
      args[:schedules_outage_end_hour] = end_hour

      # Heating/Cooling Seasons
      args[:seasons_heating_begin_month] = 1
      args[:seasons_heating_begin_day] = 1
      args[:seasons_heating_end_month] = 12
      args[:seasons_heating_end_day] = 31
      args[:seasons_cooling_begin_month] = 1
      args[:seasons_cooling_begin_day] = 1
      args[:seasons_cooling_end_month] = 12
      args[:seasons_cooling_end_day] = 31
      hpxml.hvac_controls.each do |hvac_control|
        args[:seasons_heating_begin_month] = hvac_control.seasons_heating_begin_month if !hvac_control.seasons_heating_begin_month.nil?
        args[:seasons_heating_begin_day] = hvac_control.seasons_heating_begin_day if !hvac_control.seasons_heating_begin_day.nil?
        args[:seasons_heating_end_month] = hvac_control.seasons_heating_end_month if !hvac_control.seasons_heating_end_month.nil?
        args[:seasons_heating_end_day] = hvac_control.seasons_heating_end_day if !hvac_control.seasons_heating_end_day.nil?
        args[:seasons_cooling_begin_month] = hvac_control.seasons_cooling_begin_month if !hvac_control.seasons_cooling_begin_month.nil?
        args[:seasons_cooling_begin_day] = hvac_control.seasons_cooling_begin_day if !hvac_control.seasons_cooling_begin_day.nil?
        args[:seasons_cooling_end_month] = hvac_control.seasons_cooling_end_month if !hvac_control.seasons_cooling_end_month.nil?
        args[:seasons_cooling_end_day] = hvac_control.seasons_cooling_end_day if !hvac_control.seasons_cooling_end_day.nil?
      end

      # Natural Ventilation
      args[:window_natvent_availability] = 3
      args[:window_natvent_availability] = hpxml.header.natvent_days_per_week if !hpxml.header.natvent_days_per_week.nil?

      # Water Heating
      args[:water_heater_setpoint] = 125.0
      if !hpxml.water_heating_systems.empty?
        # FIXME: what if 2+?
        args[:water_heater_setpoint] = hpxml.water_heating_systems[0].temperature if !hpxml.water_heating_systems[0].temperature.nil?
      end
    end

    # Debug
    debug = false
    if args[:schedules_type] == 'stochastic' && args[:debug].is_initialized
      debug = args[:debug].get
    end
    args[:debug] = debug
  end
end

# register the measure to be used by the application
BuildResidentialScheduleFile.new.registerWithApplication
