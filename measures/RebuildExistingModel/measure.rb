# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/measures/measure_writing_guide/

require 'csv'

# start the measure
class RebuildExistingModel < OpenStudio::Ruleset::ModelUserScript

  # human readable name
  def name
    return "Rebuild Existing Model"
  end

  # human readable description
  def description
    return "Rebuilds the OpenStudio Model for an existing building."
  end

  # human readable description of modeling approach
  def modeler_description
    return "Rebuilds the OpenStudio Model using the analysis results csv file generated from an existing housing stock run."
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

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
    
    sample_value = runner.getDoubleArgumentValue("sample_value",user_arguments)
    
    # Get file/dir paths
    resources_dir = File.absolute_path(File.join(File.dirname(__FILE__), "../../lib/resources/")) # Should have been uploaded per 'Other Library Files' in analysis spreadsheet
    helper_methods_file = File.join(resources_dir, "helper_methods.rb")
    measures_dir = File.join(resources_dir, "measures")
    lookup_file = File.join(resources_dir, "options_lookup.txt")
    resstock_csv = File.absolute_path(File.join(File.dirname(__FILE__), "../../lib/existing_results/resstock.csv")) # Should have been uploaded per 'Other Library Files' in analysis spreadsheet
    resstock_metadata_csv = File.absolute_path(File.join(File.dirname(__FILE__), "../../lib/existing_results/resstock_metadata.csv")) # Should have been uploaded per 'Other Library Files' in analysis spreadsheet
    
    # Load helper_methods
    require File.join(File.dirname(helper_methods_file), File.basename(helper_methods_file, File.extname(helper_methods_file)))

    # Check file/dir paths exist
    check_dir_exists(measures_dir, runner)
    check_file_exists(lookup_file, runner)
    check_file_exists(resstock_csv, runner)
    check_file_exists(resstock_metadata_csv, runner)

    # Get mode
    res_stock_mode = get_value_from_runner_past_results("res_stock_mode", runner)

    # Convert sample value to a sample number
    total_samples = runner.analysis[:analysis][:problem][:algorithm][:number_of_samples].to_f
    sample_number = [(sample_value * total_samples).ceil, 1].max
    runner.registerInfo("Sample value #{sample_value.to_s} converted to sample number #{sample_number.to_s}.")
    
    # Retrieve all data associated with sample number
    bldg_data = get_data_for_sample(resstock_csv, sample_number)
    
    # Retrieve order of parameters to run
    key_prefix = "res_stock_reporting."
    parameters_ordered = get_parameters_ordered(resstock_metadata_csv, key_prefix)

    # Call each measure for sample to build up model
    parameters_ordered.each do |parameter|
        prob_dist_file = File.join(resources_dir, "inputs", res_stock_mode, parameter + ".txt")
        check_file_exists(prob_dist_file)
        
        # Get file data including parameter name, dependency columns, and option names
        headers, rows, parameter_name, all_option_names, dependency_cols = get_probability_file_data(prob_dist_file, runner)
        
        # Get measure name and arguments associated with the option name
        option_name = bldg_data[key_prefix + parameter]
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
    end
    
    return true

  end
  
  def get_data_for_sample(resstock_csv, sample_number)
    CSV.foreach(resstock_csv, headers:true) do |sample|
        next if sample['name'].sub("LHS Autogenerated ","").to_i != sample_number
        return sample
    end
    # If we got this far, couldn't find the sample #
    msg = "Could not find row for #{sample_number.to_s} in #{File.basename(resstock_csv).to_s}."
    runner.registerError(msg)
    fail msg
  end
  
  def get_parameters_ordered(resstock_metadata_csv, key_prefix)
    parameters = []
    CSV.foreach(resstock_metadata_csv, headers:true) do |row|
        next if not row['name'].start_with?(key_prefix)
        parameters << row['name'].sub(key_prefix, "")
    end
    return parameters
  end
  
end

# register the measure to be used by the application
RebuildExistingModel.new.registerWithApplication
