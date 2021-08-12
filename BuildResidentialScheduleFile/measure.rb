# frozen_string_literal: true

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require 'openstudio'
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
    return ''
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
    arg.setDescription("The type of occupant-related schedules to use. Schedules corresponding to 'smooth' are average (e.g., Building America). Schedules corresponding to 'stochastic' are generated using time-inhomogeneous Markov chains derived from American Time Use Survey data, and supplemented with sampling duration and power level from NEEA RBSA data as well as DHW draw duration and flow rate from Aquacraft/AWWA data.")
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
    arg.setDisplayName('Schedules: Path')
    arg.setDescription('Absolute (or relative) path of the csv file containing user-specified occupancy schedules.')
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

    hpxml = HPXML.new(hpxml_path: hpxml_path)

    # Create EpwFile object
    epw_path = hpxml.climate_and_risk_zones.weather_station_epw_filepath
    if not File.exist? epw_path
      epw_path = File.join(File.expand_path(File.join(File.dirname(__FILE__), '..', 'weather')), epw_path) # a filename was entered for weather_station_epw_filepath
    end
    if not File.exist? epw_path
      runner.registerError("Could not find EPW file at '#{epw_path}'.")
      return false
    end
    epw_file = OpenStudio::EpwFile.new(epw_path)

    success = create_schedules(runner, hpxml, model, epw_file, args)
    return false if not success

    # modify the hpxml with the schedules path
    hpxml.header.schedules_filepath = args[:output_csv_path]
    hpxml_doc = hpxml.to_oga()
    XMLHelper.write_file(hpxml_doc, hpxml_path)
    runner.registerInfo("Wrote file: #{hpxml_path}")

    return true
  end

  def create_schedules(runner, hpxml, model, epw_file, args)
    info_msgs = []

    # set the calendar year
    year_description = model.getYearDescription
    year_description.setCalendarYear(2007) # default to TMY
    unless hpxml.header.sim_calendar_year.nil?
      year_description.setCalendarYear(hpxml.header.sim_calendar_year)
    end
    if epw_file.startDateActualYear.is_initialized # AMY
      year_description.setCalendarYear(epw_file.startDateActualYear.get)
    end
    info_msgs << "CalendarYear=#{year_description.calendarYear}"

    # set the timestep
    timestep = model.getTimestep
    timestep.setNumberOfTimestepsPerHour(1)
    unless hpxml.header.timestep.nil?
      timestep.setNumberOfTimestepsPerHour(60 / hpxml.header.timestep)
    end
    info_msgs << "NumberOfTimestepsPerHour=#{timestep.numberOfTimestepsPerHour}"

    # get generator inputs
    state = 'CO'
    state = epw_file.stateProvinceRegion unless epw_file.stateProvinceRegion.empty?
    state = hpxml.header.state_code unless hpxml.header.state_code.nil?
    random_seed = args[:schedules_random_seed].get if args[:schedules_random_seed].is_initialized
    if hpxml.building_occupancy.number_of_residents.nil?
      args[:geometry_num_occupants] = Geometry.get_occupancy_default_num(hpxml.building_construction.number_of_bedrooms)
    else
      args[:geometry_num_occupants] = hpxml.building_occupancy.number_of_residents
    end
    if args[:schedules_vacancy_period].is_initialized
      begin_month, begin_day, end_month, end_day = parse_date_range(args[:schedules_vacancy_period].get)
      args[:schedules_vacancy_begin_month] = begin_month
      args[:schedules_vacancy_begin_day] = begin_day
      args[:schedules_vacancy_end_month] = end_month
      args[:schedules_vacancy_end_day] = end_day
    end

    # generate the schedule
    schedule_generator = ScheduleGenerator.new(runner: runner, model: model, epw_file: epw_file, state: state, random_seed: random_seed)

    args[:resources_path] = File.join(File.dirname(__FILE__), 'resources')

    success = schedule_generator.create(args: args)
    return false if not success

    success = schedule_generator.export(schedules_path: File.expand_path(args[:output_csv_path]))
    return false if not success

    runner.registerInfo("Created schedule with #{info_msgs.join(', ')}")

    return true
  end

  def parse_date_range(date_range)
    begin_end_dates = date_range.split('-').map { |v| v.strip }
    if begin_end_dates.size != 2
      fail "Invalid date format specified for '#{date_range}'."
    end

    begin_values = begin_end_dates[0].split(' ').map { |v| v.strip }
    end_values = begin_end_dates[1].split(' ').map { |v| v.strip }

    if (begin_values.size != 2) || (end_values.size != 2)
      fail "Invalid date format specified for '#{date_range}'."
    end

    require 'date'
    begin_month = Date::ABBR_MONTHNAMES.index(begin_values[0].capitalize)
    end_month = Date::ABBR_MONTHNAMES.index(end_values[0].capitalize)
    begin_day = begin_values[1].to_i
    end_day = end_values[1].to_i
    if begin_month.nil? || end_month.nil? || begin_day == 0 || end_day == 0
      fail "Invalid date format specified for '#{date_range}'."
    end

    return begin_month, begin_day, end_month, end_day
  end
end

# register the measure to be used by the application
BuildResidentialScheduleFile.new.registerWithApplication
