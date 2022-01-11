# frozen_string_literal: true

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/measures/measure_writing_guide/

require 'openstudio'
require 'open3'

# start the measure
class HEScoreHPXML < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    # Measure name should be the title case of the class name.
    return 'HEScore-HPXML'
  end

  # human readable description
  def description
    return 'Translates HPXML files to a Home Energy Score input json file'
  end

  # human readable description of modeling approach
  def modeler_description
    return ''
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    arg = OpenStudio::Measure::OSArgument::makeStringArgument('hpxml_path', true)
    arg.setDisplayName('HPXML Filepath')
    arg.setDescription('Path of HPXML file to be translated')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument('output_path', true)
    arg.setDisplayName('HEScore JSON Output Filepath')
    arg.setDescription('Path of HEScore JSON file that is output by the translator')
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

    # get arguments
    hpxml_path = runner.getStringArgumentValue('hpxml_path', user_arguments)
    outfile = runner.getStringArgumentValue('output_path', user_arguments)

    hpxml_path = File.expand_path(hpxml_path)
    outfile = File.expand_path(outfile)

    runner.registerInfo('Translating HPXML to HEScore JSON')
    command = "hpxml2hescore #{hpxml_path} -o #{outfile} --resstock"
    stdout, stderr, status = Open3.capture3(command)

    if not status.success?
      runner.registerError(stderr)
      return false
    end

    runner.registerInfo("Translated HPXML to HEScore JSON, output #{outfile}")

    return true
  end
end

# register the measure to be used by the application
HEScoreHPXML.new.registerWithApplication
