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

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('hpxml_path', true)
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

    hpxml_path = args[:hpxml_path]
    unless (Pathname.new hpxml_path).absolute?
      hpxml_path = File.expand_path(File.join(File.dirname(__FILE__), hpxml_path))
    end
    unless File.exist?(hpxml_path) && hpxml_path.downcase.end_with?('.xml')
      fail "'#{hpxml_path}' does not exist or is not an .xml file."
    end

    # get occupancy schedules
    schedules = get_occupancy_schedules(args)

    # init
    new_schedules = {}

    # create HVAC setpoints
    success = create_hvac_setpoints(schedules, new_schedules, args)
    return false if not success

    # write schedules
    schedules_filepath = File.join(File.dirname(args[:output_csv_path].get), 'schedules2.csv')
    success = write_new_schedules(new_schedules, schedules_filepath)
    return false if not success

    # modify the hpxml with the schedules path
    doc = XMLHelper.parse_file(hpxml_path)
    extension = XMLHelper.create_elements_as_needed(XMLHelper.get_element(doc, '/HPXML'), ['SoftwareInfo', 'extension'])
    schedules_filepaths = XMLHelper.get_values(extension, 'SchedulesFilePath', :string)
    if !schedules_filepaths.include?(schedules_filepath)
      XMLHelper.add_element(extension, 'SchedulesFilePath', schedules_filepath, :string)
    end

    # write out the modified hpxml
    XMLHelper.write_file(doc, hpxml_path)
    runner.registerInfo("Wrote file: #{hpxml_path}")

    return true
  end

  def write_new_schedules(schedules, schedules_filepath)
    CSV.open(schedules_filepath, 'w') do |csv|
      csv << schedules.keys
      rows = schedules.values.transpose
      rows.each do |row|
        csv << row.map { |x| '%.3g' % x }
      end
    end
    return true
  end

  def create_hvac_setpoints(schedules, new_schedules, args)
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
        cooling_setpoints << cooling_setpoint - cooling_setpoint_offset_daytime_unoccupied
      else # no offset
        heating_setpoints << heating_setpoint
        cooling_setpoints << cooling_setpoint
      end
    end

    new_schedules[SchedulesFile::ColumnHeatingSetpoint] = heating_setpoints
    new_schedules[SchedulesFile::ColumnCoolingSetpoint] = cooling_setpoints

    return true
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
