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
else
  resources_path = File.absolute_path(File.join(File.dirname(__FILE__), '../HPXMLtoOpenStudio/resources'))
end
require File.join(resources_path, 'meta_measure')

# start the measure
class ResStockArguments < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    # Measure name should be the title case of the class name.
    return 'ResStock Arguments'
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
    measures_dir = File.absolute_path(File.join(File.dirname(__FILE__), '../../resources/hpxml-measures'))
    measure_subdir = 'BuildResidentialHPXML'
    full_measure_path = File.join(measures_dir, measure_subdir, 'measure.rb')
    measure = get_measure_instance(full_measure_path)

    args = OpenStudio::Measure::OSArgumentVector.new
    measure.arguments(model).each do |arg|
      next if ['hpxml_path'].include? arg.name
      next if ['software_program_used'].include? arg.name
      next if ['software_program_version'].include? arg.name

      args << arg
    end

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('plug_loads_television_usage_multiplier_2', true)
    arg.setDisplayName('Plug Loads: Television Usage Multiplier 2')
    arg.setDefaultValue(1.0)
    arg.setDescription('Additional multiplier on the television energy usage that can reflect, e.g., high/low usage occupants.')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('plug_loads_other_usage_multiplier_2', true)
    arg.setDisplayName('Plug Loads: Other Usage Multiplier 2')
    arg.setDescription('Additional multiplier on the other energy usage that can reflect, e.g., high/low usage occupants.')
    arg.setDefaultValue(1.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('plug_loads_well_pump_usage_multiplier_2', true)
    arg.setDisplayName('Plug Loads: Well Pump Usage Multiplier 2')
    arg.setDescription('Additional multiplier on the well pump energy usage that can reflect, e.g., high/low usage occupants.')
    arg.setDefaultValue(0.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('plug_loads_vehicle_usage_multiplier_2', true)
    arg.setDisplayName('Plug Loads: Vehicle Usage Multiplier 2')
    arg.setDescription('Additional multiplier on the electric vehicle energy usage that can reflect, e.g., high/low usage occupants.')
    arg.setDefaultValue(0.0)
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

    args = get_argument_values(runner, arguments(model), user_arguments)

    args['plug_loads_television_usage_multiplier'] *= args['plug_loads_television_usage_multiplier_2']
    args['plug_loads_other_usage_multiplier'] *= args['plug_loads_other_usage_multiplier_2']
    args['plug_loads_well_pump_usage_multiplier'] *= args['plug_loads_well_pump_usage_multiplier_2']
    args['plug_loads_vehicle_usage_multiplier'] *= args['plug_loads_vehicle_usage_multiplier_2']

    args.each do |arg_name, arg_value|
      begin
        if arg_value.is_initialized
          arg_value = arg_value.get
        else
          next
        end
      rescue
      end

      if ['plug_loads_television_usage_multiplier_2',
          'plug_loads_other_usage_multiplier_2',
          'plug_loads_well_pump_usage_multiplier_2',
          'plug_loads_vehicle_usage_multiplier_2'].include? arg_name
        arg_value = '' # don't assign these to BuildResidentialHPXML
      end

      runner.registerValue(arg_name, arg_value)
    end

    return true
  end
end

# register the measure to be used by the application
ResStockArguments.new.registerWithApplication
