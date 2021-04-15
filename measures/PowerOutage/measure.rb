# frozen_string_literal: true

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/measures/measure_writing_guide/

require 'openstudio'

# start the measure
class PowerOutage < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    return 'Power Outage'
  end

  # human readable description
  def description
    return 'This measures allows building power outages to be modeled. The user specifies the start time of the outage and the duration of the outage. During an outage, all energy consumption is set to 0, although occupants are still simulated in the home.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'This measure zeroes out the schedule for anything that consumes energy for the duration of the power outage.'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('outage_start_date', true)
    arg.setDisplayName('Power Outage: Start Date')
    arg.setDescription('Date of the start of the outage.')
    arg.setDefaultValue('January 1')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeIntegerArgument('outage_start_hour', true)
    arg.setDisplayName('Power Outage: Start Hour')
    arg.setUnits('hours')
    arg.setDescription('Hour of the day when the outage starts.')
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeIntegerArgument('outage_duration', true)
    arg.setDisplayName('Power Outage: Duration')
    arg.setUnits('hours')
    arg.setDescription('Duration of the power outage in hours.')
    arg.setDefaultValue(24)
    args << arg

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # assign the user inputs to variables
    outage_start_date = runner.getStringArgumentValue('outage_start_date', user_arguments)
    outage_start_hour = runner.getIntegerArgumentValue('outage_start_hour', user_arguments)
    outage_duration = runner.getIntegerArgumentValue('outage_duration', user_arguments)

    # check for valid inputs
    if (outage_start_hour < 0) || (outage_start_hour > 23)
      runner.registerError('Start hour must be between 0 and 23.')
      return false
    end

    if outage_duration == 0
      runner.registerError('Outage must last for at least one hour.')
      return false
    end

    schedules_file = nil
    model.getExternalFiles.each do |external_file|
      next unless external_file.fileName.end_with?('schedules.csv')

      schedules_file = SchedulesFile.new(runner: runner, model: model, schedules_path: external_file.filePath.to_s, col_names: ScheduleGenerator.col_names.keys)
    end

    if schedules_file.nil?
      runner.registerError('Could not locate the schedule file.')
      return false
    end

    schedules_file.set_outage(outage_start_date: outage_start_date, outage_start_hour: outage_start_hour, outage_duration: outage_duration)

    # add additional properties object with the date of the outage for use by reporting measures
    additional_properties = model.getYearDescription.additionalProperties
    additional_properties.setFeature('PowerOutageStartDate', outage_start_date)
    additional_properties.setFeature('PowerOutageStartHour', outage_start_hour)
    additional_properties.setFeature('PowerOutageDuration', outage_duration)

    runner.registerFinalCondition("A power outage has been added, starting on #{outage_start_date} at hour #{outage_start_hour} and lasting for #{outage_duration} hours.")

    return true
  end
end

# this allows the measure to be use by the application
PowerOutage.new.registerWithApplication
