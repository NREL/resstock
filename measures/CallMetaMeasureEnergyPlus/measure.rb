# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/measures/measure_writing_guide/

# Adapted from Measure Picker measure
# https://github.com/NREL/OpenStudio-measures/blob/develop/NREL%20working%20measures/measure_picker/measure.rb

require 'csv'

# start the measure
class CallMetaMeasureEnergyPlus < OpenStudio::Ruleset::WorkspaceUserScript

  # human readable name
  def name
    return "Call Meta Measure for EnergyPlus Measures"
  end

  # human readable description
  def description
    return "Measure that calls one or more child measures based on the sample value and probability distribution file provided."
  end

  # human readable description of modeling approach
  def modeler_description
    return "Based on the sample value provided by the sampling algorithm and the housing characteristics probability distribution file, one or more child measures will be called with appropriate arguments. This measure also handles any upstream dependencies that have been previously set."
  end

  # define the arguments that the user will input
  def arguments(workspace)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    probability_file = OpenStudio::Ruleset::OSArgument.makeStringArgument("probability_file", true)
    probability_file.setDisplayName("Probability DistributionFile.tsv")
    probability_file.setDescription("The name of the file that provides probability distributions. The file's directory is currently hard-coded.")
    args << probability_file

    sample_value = OpenStudio::Ruleset::OSArgument.makeDoubleArgument("sample_value", true)
    sample_value.setDisplayName("Sample Value")
    sample_value.setDescription("The sample value determined by the OpenStudio sampling algorithm.")
    args << sample_value
    
    return args
  end

  # define what happens when the measure is run
  def run(workspace, runner, user_arguments)
    super(workspace, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(workspace), user_arguments)
      return false
    end
    
    probability_file = runner.getStringArgumentValue("probability_file",user_arguments)
    sample_value = runner.getDoubleArgumentValue("sample_value",user_arguments)
    parameter_name = File.basename(probability_file, File.extname(probability_file))
    
    # Get file/dir paths
    resources_dir = File.absolute_path(File.join(File.dirname(__FILE__), "../../lib/resources/")) # Should have been uploaded per 'Other Library Files' in analysis spreadsheet
    helper_methods_file = File.join(resources_dir, "helper_methods.rb")
    measures_dir = File.join(resources_dir, "measures")
    lookup_file = File.join(resources_dir, "options_lookup.tsv")
    
    # Load helper_methods
    require File.join(File.dirname(helper_methods_file), File.basename(helper_methods_file, File.extname(helper_methods_file)))

    # Check file/dir paths exist
    check_dir_exists(measures_dir, runner)
    check_file_exists(lookup_file, runner)

    # Get mode
    res_stock_mode = get_value_from_runner_past_results("res_stock_mode", runner)

    # Get probability file data including parameter name, dependency columns, and option names
    full_probability_path = File.join(resources_dir, "inputs", res_stock_mode, probability_file)
    check_file_exists(full_probability_path, runner)
    tsvfile = TsvFile.new(full_probability_path, runner)
    
    # Get dependency values from previous meta-measure calls
    dependency_values = get_dependency_values_from_runner(tsvfile.dependency_cols, runner)
    
    # Get option name given the sample value and dependency values
    option_name, matched_row_num = tsvfile.get_option_name_from_sample_number(sample_value, dependency_values)
    
    # Get measure name and arguments associated with the option name
    measure_args = get_measure_args_from_option_name(lookup_file, option_name, parameter_name, runner)

    measure_args.keys.each do |measure_subdir|
        # Gather measure arguments and call measure
        full_measure_path = File.join(measures_dir, measure_subdir, "measure.rb")
        check_file_exists(full_measure_path, runner)
        
        measure = get_measure_instance(full_measure_path)
        argument_map = get_argument_map(workspace, measure, measure_args[measure_subdir], lookup_file, parameter_name, option_name, runner)
        print_info(measure_args[measure_subdir], measure_subdir, option_name, runner)

        if not run_measure(workspace, measure, argument_map, runner)
            return false
        end
    end
    
    if measure_args.empty?
        print_info(nil, nil, option_name, runner)
    end
    
    register_value(runner, "ResStock Parameter Name", parameter_name)
    register_value(runner, "ResStock Option Name", option_name)
    
    return true

  end
    
end

# register the measure to be used by the application
CallMetaMeasureEnergyPlus.new.registerWithApplication
