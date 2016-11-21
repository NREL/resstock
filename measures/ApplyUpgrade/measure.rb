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
  
  def num_options
    return 20
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
    
    # Option arguments
    (1..num_options).each do |option_num|
        is_required = false
        if option_num == 1
            is_required = true
        end
        option = OpenStudio::Ruleset::OSArgument.makeStringArgument("option_#{option_num}", is_required)
        option.setDisplayName("Option #{option_num}")
        option.setDescription("Specify the parameter|option as found in resources\\options_lookup.tsv.")
        args << option
    end
    
    # Option Apply Logic arguments
    (1..num_options).each do |option_num|
        option_apply_logic = OpenStudio::Ruleset::OSArgument.makeStringArgument("option_#{option_num}_apply_logic", false)
        option_apply_logic.setDisplayName("Option #{option_num} Apply Logic")
        option_apply_logic.setDescription("Logic that specifies if the Option #{option_num} upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.")
        args << option_apply_logic
    end

    package_apply_logic = OpenStudio::Ruleset::OSArgument.makeStringArgument("package_apply_logic", false)
    package_apply_logic.setDisplayName("Package Apply Logic")
    package_apply_logic.setDescription("Logic that specifies if the entire package upgrade (all options) will apply based on the existing building's options. Specify one or more parameter|option as found in resources\\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.")
    args << package_apply_logic

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

    # Retrieve Option X argument values
    options = {}
    (1..num_options).each do |option_num|
        if option_num == 1
            arg = runner.getStringArgumentValue("option_#{option_num}",user_arguments)
        else
            arg = runner.getOptionalStringArgumentValue("option_#{option_num}",user_arguments)
            next if not arg.is_initialized
            arg = arg.get
        end
        next if arg.strip.size == 0
        if not arg.include?('|')
            runner.registerError("Option #{option_num} is missing the '|' delimiter.")
            return false
        end
        options[option_num] = arg.strip
    end
    
    # Retrieve Option X Apply Logic argument values
    options_apply_logic = {}
    (1..num_options).each do |option_num|
        arg = runner.getOptionalStringArgumentValue("option_#{option_num}_apply_logic",user_arguments)
        next if not arg.is_initialized
        arg = arg.get
        next if arg.strip.size == 0
        if not arg.include?('|')
            runner.registerError("Option #{option_num} Apply Logic is missing the '|' delimiter.")
            return false
        end
        if not options.keys.include?(option_num)
            runner.registerError("Option #{option_num} Apply Logic was provided, but a corresponding Option #{option_num} was not provided.")
            return false
        end
        options_apply_logic[option_num] = arg.strip
    end
    
    # Retrieve Package Apply Logic argument value
    arg = runner.getOptionalStringArgumentValue("package_apply_logic",user_arguments)
    if not arg.is_initialized
        package_apply_logic = nil
    else
        arg = arg.get
        if arg.strip.size == 0
            package_apply_logic = nil
        else
            if not arg.include?('|')
                runner.registerError("Package Apply Logic is missing the '|' delimiter.")
                return false
            end
            package_apply_logic = arg.strip
        end
    end
    
    # Get file/dir paths
    resources_dir = File.absolute_path(File.join(File.dirname(__FILE__), "..", "..", "lib", "resources")) # Should have been uploaded per 'Other Library Files' in analysis spreadsheet
    helper_methods_file = File.join(resources_dir, "helper_methods.rb")
    measures_dir = File.join(resources_dir, "measures")
    lookup_file = File.join(resources_dir, "options_lookup.tsv")
    resstock_csv = File.absolute_path(File.join(File.dirname(__FILE__), "..", "..", "lib", "worker_initialize", "resstock.csv")) # Should have been generated by the Worker Initialization Script (run_sampling.rb)
    
    # Load helper_methods
    require File.join(File.dirname(helper_methods_file), File.basename(helper_methods_file, File.extname(helper_methods_file)))
    
    # Process package apply logic if provided
    apply_package_upgrade = true
    if not package_apply_logic.nil?
        # Apply this package?
        apply_package_upgrade = evaluate_logic(package_apply_logic, runner)
        if apply_package_upgrade.nil?
            return false
        end
    end
    
    measures = {}
    if apply_package_upgrade
    
        # Obtain measures and arguments to be called
        # Process options apply logic if provided
        options.each do |option_num, option|
            parameter_name, option_name = option.split('|')
            
            # Apply this option?
            apply_option_upgrade = true
            if options_apply_logic.include?(option_num)
                apply_option_upgrade = evaluate_logic(options_apply_logic[option_num], runner)
                if apply_option_upgrade.nil?
                    return false
                end
            end
            
            if not apply_option_upgrade
                runner.registerInfo("Parameter #{parameter_name}, Option #{option_name} will not be applied.")
                next
            end
        
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
        
        # Add measure arguments from existing building if needed
        building_col_name = "Building"
        parameters = get_parameters_ordered(resstock_csv)
        measures.keys.each do |measure_subdir|
        
            parameters.each do |parameter_name|
                next if parameter_name == building_col_name
                existing_option_name = get_value_from_runner_past_results(parameter_name, runner)
                
                get_measure_args_from_option_name(lookup_file, existing_option_name, parameter_name, runner).each do |measure_subdir2, args_hash|
                    next if measure_subdir != measure_subdir2
                    # Append any new arguments
                    args_hash.each do |k, v|
                        next if measures[measure_subdir].has_key?(k)
                        measures[measure_subdir][k] = v
                    end
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
    
    end # apply_package_upgrade
    
    if measures.size == 0
        # Upgrade not applied; skip from CSV
        # FIXME: doesn't currently stop datapoint from continuing.
        runner.registerAsNotApplicable("No measures to apply.") 
        return false
    end

    return true

  end
  
end

# register the measure to be used by the application
ApplyUpgrade.new.registerWithApplication