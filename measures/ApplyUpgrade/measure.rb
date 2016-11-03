# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/measures/measure_writing_guide/

# Adapted from Measure Picker measure
# https://github.com/NREL/OpenStudio-measures/blob/develop/NREL%20working%20measures/measure_picker/measure.rb

require 'csv'

# start the measure
class ApplyUpgrade < OpenStudio::Ruleset::ModelUserScript

  # human readable name
  def name
    return "Apply Upgrade"
  end

  # human readable description
  def description
    return "Measure that applies an upgrade (one or more child measures) to a building model based on the specified logic."
  end

  # human readable description of modeling approach
  def modeler_description
    return "Determines if the upgrade should apply to a given building model. If so, calls one or more child measures with the appropriate arguments."
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    # Make integer arg to run measure [1 is run, 0 is no run]
    run_measure = OpenStudio::Ruleset::OSArgument::makeIntegerArgument("run_measure",true)
    run_measure.setDisplayName("Run Measure")
    run_measure.setDescription("integer argument to run measure [1 is run, 0 is no run]")
    run_measure.setDefaultValue(1)
    args << run_measure 
    
    parameter_names = OpenStudio::Ruleset::OSArgument.makeStringArgument("parameter_names", true)
    parameter_names.setDisplayName("Parameter Name(s)")
    parameter_names.setDescription("The name(s) of the parameter, as specified in resources\options_lookup.tsv. Multiple names can be listed with a '|' between them.")
    args << parameter_names

    option_names = OpenStudio::Ruleset::OSArgument.makeStringArgument("option_names", true)
    option_names.setDisplayName("Option Name(s)")
    option_names.setDescription("The name(s) of the option for the corresponding parameter, as specified in resources\options_lookup.tsv. Multiple names can be listed with a '|' between them.")
    args << option_names

    apply_logic = OpenStudio::Ruleset::OSArgument.makeStringArgument("apply_logic", false)
    apply_logic.setDisplayName("Apply Logic")
    apply_logic.setDescription("The logic that specifies whether the upgrade should apply to a given building. If no logic is provided, the upgrade will be applied to all buildings.")
    args << apply_logic
    
    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end
    
    # Return N/A if not selected to run
    run_measure = runner.getIntegerArgumentValue("run_measure",user_arguments)
    if run_measure == 0
      runner.registerAsNotApplicable("Run Measure set to #{run_measure}.")
      return true     
    end

    parameter_names = runner.getStringArgumentValue("parameter_names",user_arguments)
    option_names = runner.getStringArgumentValue("option_names",user_arguments)
    apply_logic = runner.getStringArgumentValue("apply_logic",user_arguments)
    
    parameters = parameter_names.split("|")
    options = option_names.split("|")
    if parameters.size != options.size
        runner.registerError("The number of options (#{options.size.to_s}) did not match the number of parameters (#{parameters.size.to_s}).")
        return false
    end
    
    # Get file/dir paths
    resources_dir = File.absolute_path(File.join(File.dirname(__FILE__), "../../lib/resources/")) # Should have been uploaded per 'Other Library Files' in analysis spreadsheet
    helper_methods_file = File.join(resources_dir, "helper_methods.rb")
    measures_dir = File.join(resources_dir, "measures")
    lookup_file = File.join(resources_dir, "options_lookup.tsv")
    
    # Load helper_methods
    require File.join(File.dirname(helper_methods_file), File.basename(helper_methods_file, File.extname(helper_methods_file)))

    # Obtain measures and arguments to be called
    measures = {}
    parameters.zip(options).each do |parameter_name, option_name|
    
        # Register this option so that it replaces the existing building option in the results csv file
        print_option_assignment(parameter_name, option_name, runner)
        register_value(runner, parameter_name, option_name)

        # Check file/dir paths exist
        check_file_exists(lookup_file, runner)

        # Get measure name and arguments associated with the option
        get_measure_args_from_option_name(lookup_file, option_name, parameter_name, runner).each do |measure_subdir, args_hash|
            if not measures.has_key?(measure_subdir)
                measures[measure_subdir] = {}
            end
            # Append args_hash to measures[measure_subdir]
            args_hash.each do |k, v|
                measures[measure_subdir][k] = v
            end
        end
        
    end
    
    # Call each measure for sample to build up model
    measures.keys.each do |measure_subdir|
        # Gather measure arguments and call measure
        full_measure_path = File.join(measures_dir, measure_subdir, "measure.rb")
        check_file_exists(full_measure_path, runner)
        
        measure_instance = get_measure_instance(full_measure_path)
        argument_map = get_argument_map(model, measure_instance, measures[measure_subdir], lookup_file, measure_subdir, runner)
        print_measure_call(measures[measure_subdir], measure_subdir, runner)

        if not run_measure(model, measure_instance, argument_map, runner)
            return false
        end
    end
    
    return true

  end
    
end

# register the measure to be used by the application
ApplyUpgrade.new.registerWithApplication
