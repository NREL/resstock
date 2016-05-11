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
    
    # Get file/dir paths
    resources_dir = File.absolute_path(File.join(File.dirname(__FILE__), "resources"))
    measures_dir = File.join(resources_dir, "measures")
    inputs_dir = File.join(resources_dir, "inputs", res_stock_mode)
    lookup_file = File.join(resources_dir, "options_lookup.txt")
    
    full_probability_path = File.join(inputs_dir, probability_file)
    check_file_exists(full_probability_path, runner)
    
    # Get file data including parameter name, dependency columns, and option names
    headers, rows, parameter_name, all_option_names, dependency_cols = get_probability_file_data(full_probability_path, runner)
    
    # Get dependency values from previous meta-measure calls
    dependency_values = get_dependency_values_from_runner(dependency_cols, runner)
    
    # Get option name given the sample value and dependency values
    option_name, matched_row_num = get_option_name_from_sample_number(sample_value, dependency_values, full_probability_path, dependency_cols, all_option_names, headers, rows, runner)
    
    # Get measure name and arguments associated with the option name
    measure_args = get_measure_args_from_option_name(lookup_file, option_name, parameter_name, runner)

    measure_args.keys.each do |measure_subdir|
        # Gather measure arguments and call measure
        full_measure_path = File.join(measures_dir, measure_subdir, "measure.rb")
        check_file_exists(full_measure_path, runner)
        
        measure = get_measure_instance(full_measure_path)
        argument_map = get_argument_map(model, measure, measure_args[measure_subdir], lookup_file, parameter_name, option_name, runner)
        print_info(measure_args[measure_subdir], measure_subdir, option_name, runner)

        if not run_measure(model, measure, argument_map, runner)
            return false
        end
    end
    
    if measure_args.empty?
        print_info(nil, nil, option_name, runner)
    end
    
    register_value(runner, parameter_name, option_name)
    
    return true

  end
    
end

# register the measure to be used by the application
CallMetaMeasure.new.registerWithApplication
