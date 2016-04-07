# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/measures/measure_writing_guide/

# Adapted from Measure Picker measure
# https://github.com/NREL/OpenStudio-measures/blob/develop/NREL%20working%20measures/measure_picker/measure.rb

require 'csv'

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
    
    full_probability_path = check_file_exists(inputs_dir, probability_file, runner)
    if full_probability_path.nil?
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
    
    option_name = get_option_name_from_sample_value(sample_value, dependency_values, probability_file, full_probability_path, runner)
    if option_name.nil?
        return false
    end
    
    measure_subdir, measure_args = get_measure_args_from_name(lookup_file, option_name, parameter_name, runner)
    if measure_args.nil?
        return false
    end

    if not measure_subdir.nil?
        # Gather measure arguments and call measure
        
        full_measure_path = check_file_exists(measures_dir, File.join(measure_subdir, "measure.rb"), runner)
        if full_measure_path.nil?
            return false
        end
        
        measure = get_measure_instance(full_measure_path, runner)
        if measure.nil?
            return false
        end
        
        argument_map = get_argument_map(model, measure, measure_args, lookup_file, parameter_name, runner)
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
  
  def get_value_from_runner_past_results(key_lookup, runner)
    runner.past_results.each do |measure, values|
        values.each do |k, v|
            if k.to_s == key_lookup.to_s
                return v.to_s
            end
        end
    end
    runner.registerError("Could not find dependency value for '#{key_lookup.to_s}'.")
    return nil
  end
  
  def get_parameter_name_and_dependencies(full_probability_path, runner)
    parameter_name = nil
    dependencies = []
    CSV.foreach(full_probability_path, { :col_sep => "\t" }) do |row|
        if parameter_name.nil?
            # First line should be parameter name
            if row.nil? or not row[0].downcase.start_with?("parametername=")
                runner.registerError("Could not find parameter name in #{full_probability_path.to_s}.")
                return parameter_name, dependencies
            end
            val = row[0].downcase.sub("parametername=","").strip
            parameter_name = val
            next
        end
        row.each do |val|
            if not val.nil? and val.downcase.start_with?("dependency=")
                val = val.downcase.sub("dependency=","").strip
                dependencies << val
            end
        end
        break
    end
    return parameter_name, dependencies
  end
  
  def check_file_exists(parent_path, file_name, runner)
    full_path = File.join(parent_path, file_name)
    if not File.exist?(full_path)
        runner.registerError("Cannot find file #{full_path.to_s}.")
        return nil
    end
    return full_path
  end
  
  def get_dependency_values_from_runner(dependencies, runner)
    # Return hash of dependencies with their values from the runner (from
    # previous meta-measure calls).
    dependency_values = {}
    dependencies.each do |dep|
        val = get_value_from_runner_past_results(dep, runner)
        if val.nil?
            return nil
        end
        dependency_values[dep] = val
    end
    return dependency_values
  end
  
  def get_option_name_from_sample_value(sample_value, dependency_values, probability_file, full_probability_path, runner)
    # Retrieve option name from probability file based on sample value
    
    option_name = nil
    header_lines = []
    
    CSV.foreach(full_probability_path, { :col_sep => "\t" }) do |row|
    
        # Store two header lines
        if header_lines.size < 2
            header_lines << row
            next
        end
    
        # Find appropriate row by matching dependency values
        found_row = false
        if dependency_values.nil? or dependency_values.size == 0
            found_row = true
        else
            num_deps_matched = 0
            dependency_values.each do |dep,dep_val|
                col_s = "Dependency=#{dep.to_s}"
                dep_col = -1
                for col in 0..(header_lines[1].size-1)
                    if header_lines[1][col].strip.downcase == col_s.downcase
                        dep_col = col
                        break
                    end
                end
                if dep_col == -1
                    runner.registerError("Could not find column '#{col_s.to_s}' in #{probability_file.to_s}.")
                    return option_name
                end
                next if row[dep_col].nil?
                if row[dep_col].downcase == dep_val.downcase
                    num_deps_matched += 1
                end
            end
            if num_deps_matched == dependency_values.size
                found_row = true
            end
        end
        next if not found_row
    
        # Convert data to numeric row values
        rowvals = []
        for col in (dependency_values.size)..(row.size-1)
            rowvals << row[col].to_f
        end
        
        # Sum of values within 5%?
        sum_rowvals = rowvals.reduce(:+)
        if sum_rowvals < 0.95 or sum_rowvals > 1.05
            runner.registerError("Values in #{probability_file.to_s} incorrectly sum to #{sum_rowvals.to_s}")
            return option_name
        end
        
        # If values don't exactly sum to 1, normalize them
        rowvals = rowvals.collect { |n| n / sum_rowvals }
        
        # Find appropriate value
        rowsum = 0
        rowvals.each_with_index do |rowval, index|
            rowsum += rowval.to_f
            if rowsum > sample_value
                option_name = header_lines[1][index+dependency_values.size]
                break
            end
        end
    end
    
    if option_name.nil?
        deps_s = hash_to_string(dependency_values)
        if deps_s.size > 0
            runner.registerError("Could not determine appropriate option in #{probability_file.to_s} with dependencies #{deps_s.to_s} using sample value #{sample_value.to_s}.")
        else
            runner.registerError("Could not determine appropriate option in #{probability_file.to_s} using sample value #{sample_value.to_s}.")
        end
        return option_name
    end
    
    return option_name
  end
  
  def get_measure_args_from_name(lookup_file, option_name, parameter_name, runner)
    found = false
    measure_dir = nil
    measure_args = {}
    CSV.foreach(lookup_file, { :col_sep => "\t" }) do |row|
        if row[0].downcase == parameter_name.downcase and row[1].downcase == option_name.downcase
            measure_dir = row[2]
            for col in 3..(row.size-1)
                next if row[col].nil? or not row[col].include?("=")
                data = row[col].split("=")
                arg_name = data[0]
                arg_val = data[1]
                measure_args[arg_name] = arg_val
            end
            found = true
        end
    end
    if not found
        runner.registerError("Could not find measure arguments for parameter '#{parameter_name.to_s}' and option '#{option_name.to_s}'.")
        return nil, nil
    end
    return measure_dir, measure_args
  end
  
  def print_info(measure_args, measure_dir, option_name, runner)
    if measure_args.nil? or measure_dir.nil?
        runner.registerInfo("Assigning option '#{option_name.to_s}'.")
    else
        args_s = hash_to_string(measure_args, delim=" -> ", separator="\n")
        if args_s.size > 0
            runner.registerInfo("Assigning option '#{option_name.to_s}'.")
            runner.registerInfo("Calling #{measure_dir.to_s} measure with arguments:\n#{args_s}")
        else
            runner.registerInfo("Assigning option '#{option_name.to_s}'.")
            runner.registerInfo("Calling #{measure_dir.to_s} measure with no arguments.")
        end
    end
  end
  
  def get_measure_instance(full_measure_path, runner)
    # Parse XML file for class name
    # Hacky, but doesn't require 3rd party XML parser
    measure_class = ""
    File.open(full_measure_path.sub(".rb",".xml"), "r") do |f|
        f.each_line do |line|
            line = line.strip
            if line.start_with?("<class_name>") and line.end_with?("</class_name>")
                measure_class = line.sub("<class_name>", "")
                measure_class = measure_class.sub("</class_name>", "")
            end
        end
    end
    # Create new instance
    require (full_measure_path)
    measure = eval(measure_class).new
    return measure
  end
  
  def get_argument_map(model, measure, measure_args, lookup_file, parameter_name, runner)
    # Get default arguments
    args_hash = default_args_hash(model, measure)
    
    # Verify all arguments have been provided
    args_hash.each do |k,v|
        next if measure_args.keys.include?(k)
        runner.registerError("Argument '#{k}' not provided in #{File.basename(lookup_file).to_s} for parameter '#{parameter_name.to_s}'.")
        return nil
    end
    measure_args.each do |k,v|
        next if args_hash.keys.include?(k)
        runner.registerError("Extra argument '#{k}' specified in #{File.basename(lookup_file).to_s} for parameter '#{parameter_name.to_s}'.")
        return nil
    end
    
    # Overwrite with specified arguments
    measure_args.each do |k,v|
        args_hash[k] = v
    end
    
    # Convert to argument map needed by OS
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Ruleset.convertOSArgumentVectorToMap(arguments)
    arguments.each do |arg|
        temp_arg_var = arg.clone
        if args_hash[arg.name]
            temp_arg_var.setValue(args_hash[arg.name])
        end
        argument_map[arg.name] = temp_arg_var
    end
    return argument_map
  end
  
  def default_args_hash(model, measure)
    args_hash = {}
    arguments = measure.arguments(model)
    arguments.each do |arg| 
        if arg.hasDefaultValue
            type = arg.type.valueName
            case type.downcase
            when "boolean"
                args_hash[arg.name] = arg.defaultValueAsBool
            when "double"
                args_hash[arg.name] = arg.defaultValueAsDouble
            when "integer"
                args_hash[arg.name] = arg.defaultValueAsInteger
            when "string"
                args_hash[arg.name] = arg.defaultValueAsString
            when "choice"
                args_hash[arg.name] = arg.defaultValueAsString
            end
        else
            args_hash[arg.name] = nil
        end
    end
    return args_hash
  end
  
  def run_measure(model, measure, argument_map, runner)
    begin

      # run the measure
      runner_child = OpenStudio::Ruleset::OSRunner.new
      measure.run(model, runner_child, argument_map)
      result_child = runner_child.result

      # get initial and final condition
      if result_child.initialCondition.is_initialized
        runner.registerInitialCondition(result_child.initialCondition.get.logMessage)
      end
      if result_child.finalCondition.is_initialized
        runner.registerFinalCondition(result_child.finalCondition.get.logMessage)
      end

      # log messages
      result_child.errors.each do |error|
        runner.registerError(error.logMessage)
        return false
      end
      result_child.warnings.each do |warning|
        runner.registerWarning(warning.logMessage)
      end
      result_child.info.each do |info|
        runner.registerInfo(info.logMessage)
      end

      # convert a return false in the measure to a return false and error here.
      if result_child.value.valueName == "Fail"
        runner.registerError("The measure was not successful")
        return false
      end

    rescue => e
      runner.registerError("Measure Failed with Error: #{e.backtrace.join("\n")}")
      return false
    end
    return true
  end
  
  def register_value(runner, parameter_name, option_name)
    runner.registerValue(parameter_name, option_name)
  end
  
  def hash_to_string(hash, delim="=", separator=",")
    hash_s = ""
    hash.each do |k,v|
        hash_s += "#{k.to_s}#{delim.to_s}#{v.to_s}#{separator.to_s}"
    end
    if hash_s.size > 0
        hash_s = hash_s.chomp(separator.to_s)
    end
    return hash_s
  end
  
end

# register the measure to be used by the application
CallMetaMeasure.new.registerWithApplication
