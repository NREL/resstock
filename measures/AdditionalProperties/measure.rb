# frozen_string_literal: true

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require 'openstudio'

# start the measure
class AdditionalProperties < OpenStudio::Measure::ReportingMeasure
  # human readable name
  def name
    # Measure name should be the title case of the class name.
    return 'Additional Properties'
  end

  # human readable description
  def description
    return 'Measure that registers additional properties.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'Registers all additional properties found in upgraded.xml.'
  end

  # define the arguments that the user will input
  def arguments(model = nil)
    args = OpenStudio::Measure::OSArgumentVector.new

    return args
  end

  # define what happens when the measure is run
  def run(runner, user_arguments)
    super(runner, user_arguments)

    # get the last model and sql file
    model = runner.lastOpenStudioModel
    if model.empty?
      runner.registerError('Cannot find OpenStudio model.')
      return false
    end
    model = model.get

    # use the built-in error checking (need model)
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    upgraded_path = File.expand_path('../upgraded.xml')
    upgraded_hpxml = HPXML.new(hpxml_path: upgraded_path) if File.exist?(upgraded_path)

    if !upgraded_hpxml.nil?
      upgraded_hpxml.header.extension_properties.each do |k, v|
        register_value(runner, k, v)
      end
    end

    return true
  end
end

# register the measure to be used by the application
AdditionalProperties.new.registerWithApplication
