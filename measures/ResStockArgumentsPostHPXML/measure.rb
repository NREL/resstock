# frozen_string_literal: true

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

# start the measure
class ResStockArgumentsPostHPXML < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    # Measure name should be the title case of the class name.
    return 'ResStockArgumentsPostHPXML'
  end

  # human readable description
  def description
    return 'TODO'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'TODO'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    arg = OpenStudio::Measure::OSArgument::makeStringArgument('output_csv_path', true)
    arg.setDisplayName('Schedules: Output CSV Path')
    arg.setDescription('Absolute/relative path of the csv file containing user-specified occupancy schedules. Relative paths are relative to the HPXML output path.')
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
