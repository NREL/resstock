# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require 'openstudio'
require 'rexml/document'
require 'rexml/xpath'
require 'pathname'
require 'csv'
require_relative "resources/xmlhelper"
require_relative "resources/hpxml"

# start the measure
class HPXMLExporter < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    return "HPXML Exporter"
  end

  # human readable description
  def description
    return "Exports residential modeling arguments to HPXML file"
  end

  # human readable description of modeling approach
  def modeler_description
    return ""
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # Check for correct versions of OS
    os_version = "2.9.0"
    if OpenStudio.openStudioVersion != os_version
      fail "OpenStudio version #{os_version} is required."
    end
  end
end

# register the measure to be used by the application
HPXMLExporter.new.registerWithApplication
