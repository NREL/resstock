# frozen_string_literal: true

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

# start the measure
class ResStockArgumentsPostHPXML < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    # Measure name should be the title case of the class name.
    return 'ResStock Arguments Post-HPXML'
  end

  # human readable description
  def description
    return 'Measure that post-processes the output of the BuildResidentialHPXML and BuildResidentialScheduleFile measures.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'Passes in all ResStockArgumentsPostHPXML arguments from the options lookup, processes them, and then modifies output of other measures.'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('hpxml_path', false)
    arg.setDisplayName('HPXML File Path')
    arg.setDescription('Absolute/relative path of the HPXML file.')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument('output_csv_path', false)
    arg.setDisplayName('Schedules: Output CSV Path')
    arg.setDescription('Absolute/relative path of the csv file containing user-specified occupancy schedules. Relative paths are relative to the HPXML output path.')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('use_auto_heating_season', true)
    arg.setDisplayName('Use Auto Heating Season')
    arg.setDescription('Specifies whether to automatically define the heating season based on the weather file.')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('use_auto_cooling_season', true)
    arg.setDisplayName('Use Auto Cooling Season')
    arg.setDescription('Specifies whether to automatically define the cooling season based on the weather file.')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('heating_setpoint', true)
    arg.setDisplayName('Heating Setpoint: Weekday Temperature')
    arg.setDescription('Specify the weekday heating setpoint temperature.')
    arg.setUnits('deg-F')
    arg.setDefaultValue(71)
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeDoubleArgument('heating_setpoint_offset_nighttime', true)
    arg.setDisplayName('Setpoint Schedules: Heating Setpoint Offset Nighttime')
    arg.setDescription('The magnitude of the heating setpoint offset (setpoint is lowered) for nighttime hours. For smooth schedules, nighttime hours occur during the period from 10pm - 7am. For stochastic schedules, nighttime hours can vary.')
    arg.setUnits('deg-F')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeDoubleArgument('heating_setpoint_offset_daytime_unoccupied', true)
    arg.setDisplayName('Setpoint Schedules: Heating Setpoint Offset Daytime Unoccupied')
    arg.setDescription('The magnitude of the heating setpoint offset (setpoint is lowered) for daytime unoccupied hours. For smooth schedules, daytime unoccupied hours never occur. For stochastic schedules, daytime unoccupied hours can vary.')
    arg.setUnits('deg-F')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('cooling_setpoint', true)
    arg.setDisplayName('Cooling Setpoint: Weekday Temperature')
    arg.setDescription('Specify the weekday cooling setpoint temperature.')
    arg.setUnits('deg-F')
    arg.setDefaultValue(76)
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeDoubleArgument('cooling_setpoint_offset_nighttime', true)
    arg.setDisplayName('Setpoint Schedules: Cooling Setpoint Offset Nighttime')
    arg.setDescription('The magnitude of the cooling setpoint offset (setpoint is raised) for nighttime hours. For smooth schedules, nighttime hours occur during the period from 10pm - 7am. For stochastic schedules, nighttime hours can vary.')
    arg.setUnits('deg-F')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeDoubleArgument('cooling_setpoint_offset_daytime_unoccupied', true)
    arg.setDisplayName('Setpoint Schedules: Cooling Setpoint Offset Daytime Unoccupied')
    arg.setDescription('The magnitude of the cooling setpoint offset (setpoint is raised) for daytime unoccupied hours. For smooth schedules, daytime unoccupied hours never occur. For stochastic schedules, daytime unoccupied hours can vary.')
    arg.setUnits('deg-F')
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

    hpxml_path = args[:hpxml_path].get
    unless (Pathname.new hpxml_path).absolute?
      hpxml_path = File.expand_path(File.join(File.dirname(__FILE__), hpxml_path))
    end
    unless File.exist?(hpxml_path) && hpxml_path.downcase.end_with?('.xml')
      fail "'#{hpxml_path}' does not exist or is not an .xml file."
    end

    hpxml = HPXML.new(hpxml_path: hpxml_path)

    # skip measure
    return true if skip_measure(hpxml)

    # get occupancy schedules
    schedules = get_occupancy_schedules(args)

    # init
    new_schedules = {}

    # create HVAC setpoints
    create_hvac_setpoints(runner, hpxml, schedules, new_schedules, args)

    # return if not writing schedules
    return true if new_schedules.empty?

    # write schedules
    schedules_filepath = File.join(File.dirname(args[:output_csv_path].get), 'schedules2.csv')
    write_new_schedules(new_schedules, schedules_filepath)

    # modify the hpxml with the schedules path
    doc = XMLHelper.parse_file(hpxml_path)
    extension = XMLHelper.create_elements_as_needed(XMLHelper.get_element(doc, '/HPXML'), ['SoftwareInfo', 'extension'])
    schedules_filepaths = XMLHelper.get_values(extension, 'SchedulesFilePath', :string)
    if !schedules_filepaths.include?(schedules_filepath)
      XMLHelper.add_element(extension, 'SchedulesFilePath', schedules_filepath, :string)

      # write out the modified hpxml
      XMLHelper.write_file(doc, hpxml_path)
      runner.registerInfo("Wrote file: #{hpxml_path}")
    end

    return true
  end

  def skip_measure(hpxml)
    return true if hpxml.hvac_controls.size == 0

    return false
  end

  def write_new_schedules(schedules, schedules_filepath)
    CSV.open(schedules_filepath, 'w') do |csv|
      csv << schedules.keys
      rows = schedules.values.transpose
      rows.each do |row|
        csv << row.map { |x| '%.3g' % x }
      end
    end
  end

  def create_hvac_setpoints(runner, hpxml, schedules, new_schedules, args)
    heating_setpoints = []
    cooling_setpoints = []

    heating_setpoint = args[:heating_setpoint]
    heating_setpoint_offset_nighttime = args[:heating_setpoint_offset_nighttime]
    heating_setpoint_offset_daytime_unoccupied = args[:heating_setpoint_offset_daytime_unoccupied]
    cooling_setpoint = args[:cooling_setpoint]
    cooling_setpoint_offset_nighttime = args[:cooling_setpoint_offset_nighttime]
    cooling_setpoint_offset_daytime_unoccupied = args[:cooling_setpoint_offset_daytime_unoccupied]

    schedules[SchedulesFile::ColumnOccupants].zip(schedules[SchedulesFile::ColumnSleep]).each do |occupants, sleep|
      if sleep == 1 # nighttime
        heating_setpoints << heating_setpoint - heating_setpoint_offset_nighttime
        cooling_setpoints << cooling_setpoint + cooling_setpoint_offset_nighttime
      elsif sleep == 0 && occupants == 0 # daytime unoccupied
        heating_setpoints << heating_setpoint - heating_setpoint_offset_daytime_unoccupied
        cooling_setpoints << cooling_setpoint + cooling_setpoint_offset_daytime_unoccupied
      else # no offset
        heating_setpoints << heating_setpoint
        cooling_setpoints << cooling_setpoint
      end
    end

    calendar_year = get_calendar_year(hpxml)

    HPXMLDefaults.apply_hvac_control(hpxml, nil)
    hvac_control = hpxml.hvac_controls[0]

    htg_start_month = hvac_control.seasons_heating_begin_month
    htg_start_day = hvac_control.seasons_heating_begin_day
    htg_end_month = hvac_control.seasons_heating_end_month
    htg_end_day = hvac_control.seasons_heating_end_day
    clg_start_month = hvac_control.seasons_cooling_begin_month
    clg_start_day = hvac_control.seasons_cooling_begin_day
    clg_end_month = hvac_control.seasons_cooling_end_month
    clg_end_day = hvac_control.seasons_cooling_end_day

    heating_days = Schedule.get_daily_season(calendar_year, htg_start_month, htg_start_day, htg_end_month, htg_end_day)
    cooling_days = Schedule.get_daily_season(calendar_year, clg_start_month, clg_start_day, clg_end_month, clg_end_day)

    steps_in_day = steps_in_day(hpxml)
    by_day_heating_setpoints = create_by_day_setpoints(heating_setpoints, steps_in_day)
    htg_weekday_setpoints = htg_weekend_setpoints = by_day_heating_setpoints
    by_day_cooling_setpoints = create_by_day_setpoints(cooling_setpoints, steps_in_day)
    clg_weekday_setpoints = clg_weekend_setpoints = by_day_cooling_setpoints

    by_day_htg_setpoints, _, by_day_clg_setpoints, _ = HVAC.create_setpoint_schedules(runner, heating_days, cooling_days, htg_weekday_setpoints, htg_weekend_setpoints, clg_weekday_setpoints, clg_weekend_setpoints, calendar_year)

    new_schedules[SchedulesFile::ColumnHeatingSetpoint] = by_day_heating_setpoints.flatten
    new_schedules[SchedulesFile::ColumnCoolingSetpoint] = by_day_cooling_setpoints.flatten
  end

  def create_by_day_setpoints(setpoints, steps_in_day)
    by_day_setpoints = []
    setpoints.each_slice(steps_in_day) do |day|
      by_day_setpoints << day
    end
    return by_day_setpoints
  end

  def steps_in_day(hpxml)
    minutes_per_step = 60
    if !hpxml.header.timestep.nil?
      minutes_per_step = hpxml.header.timestep
    end
    return 24 * 60 / minutes_per_step
  end

  def get_calendar_year(hpxml)
    # Create EpwFile object
    epw_path = hpxml.climate_and_risk_zones.weather_station_epw_filepath
puts "HERE0 #{epw_path}"
    if not File.exist? epw_path
puts "HERE1 #{epw_path}"
      epw_path = File.join(File.expand_path(File.join(File.dirname(__FILE__), 'weather')), epw_path) # a filename was entered for weather_station_epw_filepath
    end
puts "HERE2 #{File.expand_path(epw_path)}"
    if not File.exist? epw_path
      runner.registerError("Could not find EPW file at '#{epw_path}'.")
      return false
    end
    epw_file = OpenStudio::EpwFile.new(epw_path)

    calendar_year = 2007 # default to TMY
    if !hpxml.header.sim_calendar_year.nil?
      calendar_year = hpxml.header.sim_calendar_year
    end
    if epw_file.startDateActualYear.is_initialized # AMY
      calendar_year = epw_file.startDateActualYear.get
    end
    return calendar_year
  end

  def get_occupancy_schedules(args)
    schedules = {}

    schedules_path = args[:output_csv_path].get
    columns = CSV.read(schedules_path).transpose
    columns.each do |col|
      col_name = col[0]

      values = col[1..-1].reject { |v| v.nil? }

      begin
        values = values.map { |v| Float(v) }
      rescue ArgumentError
        fail "Schedule value must be numeric for column '#{col_name}'. [context: #{schedules_path}]"
      end

      schedules[col_name] = values
    end

    return schedules
  end
end

# register the measure to be used by the application
ResStockArgumentsPostHPXML.new.registerWithApplication
