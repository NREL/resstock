# frozen_string_literal: true

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require 'openstudio'
require 'pathname'
require 'oga'
require_relative 'resources/schedules'
require_relative '../HPXMLtoOpenStudio/resources/constants'
require_relative '../HPXMLtoOpenStudio/resources/geometry'
require_relative '../HPXMLtoOpenStudio/resources/hpxml'
require_relative '../HPXMLtoOpenStudio/resources/lighting'
require_relative '../HPXMLtoOpenStudio/resources/meta_measure'
require_relative '../HPXMLtoOpenStudio/resources/schedules'
require_relative '../HPXMLtoOpenStudio/resources/xmlhelper'

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
  def arguments(model)
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

    arg = OpenStudio::Measure::OSArgument.makeIntegerArgument('schedules_random_seed', false)
    arg.setDisplayName('Schedules: Random Seed')
    arg.setUnits('#')
    arg.setDescription("This numeric field is the seed for the random number generator. Only applies if the schedules type is 'stochastic'.")
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('output_csv_path', true)
    arg.setDisplayName('Schedules: Output CSV Path')
    arg.setDescription('Absolute/relative path of the csv file containing user-specified occupancy schedules. Relative paths are relative to the HPXML output path.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('hpxml_output_path', true)
    arg.setDisplayName('HPXML Output File Path')
    arg.setDescription('Absolute/relative output path of the HPXML file. This HPXML file will include the output CSV path.')
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
      hpxml_path = File.expand_path(File.join(File.dirname(__FILE__), hpxml_path))
    end
    unless File.exist?(hpxml_path) && hpxml_path.downcase.end_with?('.xml')
      fail "'#{hpxml_path}' does not exist or is not an .xml file."
    end

    hpxml_output_path = args[:hpxml_output_path]
    unless (Pathname.new hpxml_output_path).absolute?
      hpxml_output_path = File.expand_path(File.join(File.dirname(__FILE__), hpxml_output_path))
    end
    args[:hpxml_output_path] = hpxml_output_path

    hpxml = HPXML.new(hpxml_path: hpxml_path)

    # create EpwFile object
    epw_path = hpxml.climate_and_risk_zones.weather_station_epw_filepath
    if not File.exist? epw_path
      epw_path = File.join(File.expand_path(File.join(File.dirname(__FILE__), '..', 'weather')), epw_path) # a filename was entered for weather_station_epw_filepath
    end
    if not File.exist? epw_path
      runner.registerError("Could not find EPW file at '#{epw_path}'.")
      return false
    end
    epw_file = OpenStudio::EpwFile.new(epw_path)

    # create the schedules
    success = create_schedules(runner, hpxml, epw_file, args)
    return false if not success

    # modify the hpxml with the schedules path
    # modify the doc directly in case our HPXML class doesn't handle all elements
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

    runner.registerInfo("Created #{args[:schedules_type]} schedule with #{info_msgs.join(', ')}")

    return true
  end

  def get_simulation_parameters(hpxml, epw_file, args)
    args[:minutes_per_step] = 60
    if !hpxml.header.timestep.nil?
      args[:minutes_per_step] = hpxml.header.timestep
    end
    args[:steps_in_day] = 24 * 60 / args[:minutes_per_step]
    args[:mkc_ts_per_day] = 96
    args[:mkc_ts_per_hour] = args[:mkc_ts_per_day] / 24

    calendar_year = 2007 # default to TMY
    if !hpxml.header.sim_calendar_year.nil?
      calendar_year = hpxml.header.sim_calendar_year
    end
    if epw_file.startDateActualYear.is_initialized # AMY
      calendar_year = epw_file.startDateActualYear.get
    end
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

    if args[:schedules_vacancy_period].is_initialized
      begin_month, begin_day, end_month, end_day = Schedule.parse_date_range(args[:schedules_vacancy_period].get)
      args[:schedules_vacancy_begin_month] = begin_month
      args[:schedules_vacancy_begin_day] = begin_day
      args[:schedules_vacancy_end_month] = end_month
      args[:schedules_vacancy_end_day] = end_day
    end

    if args[:geometry_num_occupants] == 0
      if args[:schedules_type] == 'stochastic'
        args[:geometry_num_occupants] = Geometry.get_occupancy_default_num(hpxml.building_construction.number_of_bedrooms)
      end

      args[:schedules_vacancy_begin_month] = 1
      args[:schedules_vacancy_begin_day] = 1
      args[:schedules_vacancy_end_month] = 12
      args[:schedules_vacancy_end_day] = 31
    end
  end
end

# register the measure to be used by the application
BuildResidentialScheduleFile.new.registerWithApplication
