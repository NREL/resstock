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

    arg = OpenStudio::Measure::OSArgument::makeStringArgument('output_csv_path', true)
    arg.setDisplayName('Schedules: Output CSV Path')
    arg.setDescription('Absolute/relative path of the csv file containing user-specified occupancy schedules. Relative paths are relative to the HPXML output path.')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('heating_setpoint', true)
    arg.setDisplayName('Heating Setpoint: Weekday Temperature')
    arg.setDescription('Specify the weekday heating setpoint temperature.')
    arg.setUnits('deg-F')
    arg.setDefaultValue(71)
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeDoubleArgument('heating_setpoint_offset_nighttime', false)
    arg.setDisplayName('Setpoint Schedules: Heating Setpoint Offset Nighttime')
    arg.setDescription('The magnitude of the heating setpoint offset (setpoint is lowered) for nighttime hours. For smooth schedules, nighttime hours occur during the period from 10pm - 7am. For stochastic schedules, nighttime hours can vary.')
    arg.setUnits('deg-F')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeDoubleArgument('heating_setpoint_offset_daytime_unoccupied', false)
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

    arg = OpenStudio::Measure::OSArgument.makeDoubleArgument('cooling_setpoint_offset_nighttime', false)
    arg.setDisplayName('Setpoint Schedules: Cooling Setpoint Offset Nighttime')
    arg.setDescription('The magnitude of the cooling setpoint offset (setpoint is raised) for nighttime hours. For smooth schedules, nighttime hours occur during the period from 10pm - 7am. For stochastic schedules, nighttime hours can vary.')
    arg.setUnits('deg-F')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeDoubleArgument('cooling_setpoint_offset_daytime_unoccupied', false)
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

    # TODO

    return true
  end
end

# register the measure to be used by the application
ResStockArgumentsPostHPXML.new.registerWithApplication
