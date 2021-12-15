# frozen_string_literal: true

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/measures/measure_writing_guide/

require 'openstudio'
if File.exist? File.absolute_path(File.join(File.dirname(__FILE__), '../../lib/resources/hpxml-measures/HPXMLtoOpenStudio/resources')) # Hack to run ResStock on AWS
  resources_path = File.absolute_path(File.join(File.dirname(__FILE__), '../../lib/resources/hpxml-measures/HPXMLtoOpenStudio/resources'))
elsif File.exist? File.absolute_path(File.join(File.dirname(__FILE__), '../../resources/hpxml-measures/HPXMLtoOpenStudio/resources')) # Hack to run ResStock unit tests locally
  resources_path = File.absolute_path(File.join(File.dirname(__FILE__), '../../resources/hpxml-measures/HPXMLtoOpenStudio/resources'))
elsif File.exist? File.join(OpenStudio::BCLMeasure::userMeasuresDir.to_s, 'HPXMLtoOpenStudio/resources') # Hack to run measures in the OS App since applied measures are copied off into a temporary directory
  resources_path = File.join(OpenStudio::BCLMeasure::userMeasuresDir.to_s, 'HPXMLtoOpenStudio/resources')
end
require File.join(resources_path, 'location')
require File.join(resources_path, 'meta_measure')
require File.join(resources_path, 'weather')
require 'pycall'

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

    hpxml_path = File.expand_path('../in.xml') # this is the defaulted hpxml
    outfile = File.expand_path('../hes.json')

    runner.registerWarning('Translating xml to HES json')
    command = "hpxml2hescore #{hpxml_path} -o #{outfile} --resstock"
    system(command)
    runner.registerWarning("Translated xml to HES json, output #{outfile}")

    return true
  end
end

# register the measure to be used by the application
HEScoreHPXML.new.registerWithApplication
