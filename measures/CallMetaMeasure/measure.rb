# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/measures/measure_writing_guide/

# Adapted from Measure Picker measure
# https://github.com/NREL/OpenStudio-measures/blob/develop/NREL%20working%20measures/measure_picker/measure.rb

require 'csv'
require File.join(File.dirname(__FILE__), 'resources', 'helper_methods')

# start the measure
class CallMetaMeasure < OpenStudio::Ruleset::ModelUserScript

  # human readable name
  def name
    return "Call Meta Measure"
  end

  # human readable description
  def description
    return "Measure that calls a child measure based on the sample value and probability distribution file provided."
  end

  # human readable description of modeling approach
  def modeler_description
    return "Based on the sample value provided by the sampling algorithm and the housing characteristics probability distribution file, a child measure will be called with appropriate arguments. This measure also handles any upstream dependencies that have been previously set."
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    probability_file = OpenStudio::Ruleset::OSArgument.makeStringArgument("probability_file", true)
    probability_file.setDisplayName("ProbabilityDistributionFile.txt")
    probability_file.setDescription("The name of the file that provides probability distributions. (Note: The path to this file's parent directory is currently hardcoded.)")
    args << probability_file

    sample_value = OpenStudio::Ruleset::OSArgument.makeDoubleArgument("sample_value", true)
    sample_value.setDisplayName("Sample Value")
    sample_value.setDescription("The sample value determined by the OpenStudio sampling algorithm.")
    args << sample_value
    
    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end
    
    probability_file = runner.getStringArgumentValue("probability_file",user_arguments)
    sample_value = runner.getDoubleArgumentValue("sample_value",user_arguments)
    
    # Get mode and corresponding subdirectory (as found in the MetaMeasure resources dir)
    res_stock_mode = get_value_from_runner_past_results("res_stock_mode", runner)
    if res_stock_mode.nil?
        return false
    end
    
    # Get file/dir paths
    resources_dir = File.absolute_path(File.join(File.dirname(__FILE__), "resources"))
    measures_dir = File.join(resources_dir, "measures")
    subdir_hash = {"National" => File.join("inputs","national"), 
                   "Pacific Northwest" => File.join("inputs","pnw")}
    inputs_dir = File.join(resources_dir, subdir_hash[res_stock_mode])
    lookup_file = File.join(resources_dir, "options_lookup.txt")
    
    full_probability_path = File.join(inputs_dir, probability_file)
    if not check_file_exists(full_probability_path, runner)
        return false
    end
    
    parameter_name, dependencies = get_parameter_name_and_dependencies(full_probability_path, runner)
    if parameter_name.nil? or dependencies.nil?
        return false
    end
    
    dependency_values = get_dependency_values_from_runner(dependencies, runner)
    if dependency_values.nil?
        return false
    end
    
    headers, rows = get_file_data(full_probability_path)
    option_name = get_option_name_from_sample_value(sample_value, dependency_values, full_probability_path, headers, rows, runner)
    if option_name.nil?
        return false
    end
    
    measure_subdir, measure_args = get_measure_args_from_name(lookup_file, option_name, parameter_name, runner)
    if measure_args.nil?
        return false
    end

    if not measure_subdir.nil?
        # Gather measure arguments and call measure
        
        full_measure_path = File.join(measures_dir, measure_subdir, "measure.rb")
        if not check_file_exists(full_measure_path, runner)
            return false
        end
        
        measure = get_measure_instance(full_measure_path)
        if measure.nil?
            return false
        end
        
        argument_map = get_argument_map(model, measure, measure_args, lookup_file, parameter_name, option_name, runner)
        if argument_map.nil?
            return false
        end
        
        print_info(measure_args, measure_subdir, option_name, runner)

        if not run_measure(model, measure, argument_map, runner)
            return false
        end
    else
    
        print_info(nil, nil, option_name, runner)
    
    end
    
    register_value(runner, parameter_name, option_name)
    
    return true

  end
    
end

# register the measure to be used by the application
CallMetaMeasure.new.registerWithApplication
