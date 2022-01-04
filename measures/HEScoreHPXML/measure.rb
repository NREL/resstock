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

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    hpxml_path = File.expand_path('../existing.xml')
    outfile = File.expand_path('../hes.json')

    runner.registerInfo('Translating xml to HES json')
    command = "hpxml2hescore #{hpxml_path} -o #{outfile} --resstock"
    stdout, stderr, status = Open3.capture3(command)

    if not status.success?
      runner.registerError(stderr)
      return false
    end

    runner.registerInfo("Translated xml to HES json, output #{outfile}")

    return true
  end
end

# register the measure to be used by the application
HEScoreHPXML.new.registerWithApplication
