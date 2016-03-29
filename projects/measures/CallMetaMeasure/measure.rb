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
    return ""
  end

  # human readable description of modeling approach
  def modeler_description
    return ""
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    parameter_name = OpenStudio::Ruleset::OSArgument.makeStringArgument("parameter_name", true)
    parameter_name.setDisplayName("ParameterName")
    parameter_name.setDescription("The name of the parameter.")
    args << parameter_name
    
    probability_file = OpenStudio::Ruleset::OSArgument.makeStringArgument("probability_file", true)
    probability_file.setDisplayName("ProbabilityDistributionsFile.txt")
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
    
    parameter_name = runner.getStringArgumentValue("parameter_name",user_arguments)
    probability_file = runner.getStringArgumentValue("probability_file",user_arguments)
    sample_value = runner.getDoubleArgumentValue("sample_value",user_arguments)
    
    # FIXME: Hardcoded values
    # According to Ry, can get total num samples by:
    # analysis_json = runner.get_analysis
    # analysis_json[:analysis][:problem][:number_of_samples]
    total_num_samples = 100
    lookup_file = "C:\\Users\\shorowit\\Documents\\GitHub\\OpenStudio-ResStock\\input\\national scale\\_options_lookup.txt"
    parent_probability_path = "C:\\Users\\shorowit\\Documents\\GitHub\\OpenStudio-ResStock\\input\\national scale"
    parent_measure_path = "C:\\Users\\shorowit\\Documents\\GitHub\\OpenStudio-Beopt\\measures"

    full_probability_path = check_file_exists(parent_probability_path, probability_file, runner)
    if full_probability_path.nil?
        return false
    end
    
    dependencies = get_dependencies(runner, full_probability_path)
    if dependencies.nil?
        return false
    end
    
    dependency_values = get_dependency_values_from_runner(runner, dependencies)
    if dependency_values.nil?
        return false
    end
    
    option_name = get_option_name_from_sample_value(sample_value, dependency_values, total_num_samples, probability_file, full_probability_path, runner)
    if option_name.nil?
        return false
    end
    
    measure_dir, measure_args = get_measure_args_from_name(lookup_file, option_name, parameter_name, runner)
    if measure_args.nil?
        return false
    end

    if not measure_dir.nil?
        # Gather measure arguments and call measure
        
        full_measure_path = check_file_exists(parent_measure_path, measure_dir + "\\measure.rb", runner)
        if full_measure_path.nil?
            return false
        end
        
        print_info(measure_args, measure_dir, option_name, runner)
        
        measure = get_measure_instance(full_measure_path, runner)
        if measure.nil?
            return false
        end
        
        argument_map = get_argument_map(model, measure, measure_args)
        
        if not run_measure(model, measure, argument_map, runner)
            return false
        end
    else
    
        print_info(nil, nil, option_name, runner)
    
    end
    
    register_value(runner, parameter_name, option_name)
    
    return true

  end
  
  def get_dependencies(runner, full_probability_path)
    dependencies = []
    CSV.foreach(full_probability_path, { :col_sep => "\t" }) do |row|
        row.each do |val|
            if not val.nil? and val.downcase.start_with?("dependency=")
                val = val.downcase.sub("dependency=","").strip
                dependencies << val
            end
        end
        break
    end
    return dependencies
  end
  
  def check_file_exists(parent_path, file_name, runner)
    full_path = parent_path + "\\" + file_name
    if not File.exist?(full_path)
        runner.registerError("Cannot find file #{full_path.to_s}.")
        return nil
    end
    return full_path
  end
  
  def get_dependency_values_from_runner(runner, dependencies)
    # Return hash of dependencies with their values from the runner (from
    # previous meta-measure calls).
    
    dependency_values = {}
    # FIXME: Need Ry's help to retrieve runner values
    # Currently hard-coding...
    dependencies.each do |dep|
        if dep.downcase == "location"
            dependency_values[dep] = "USA_FL_Jacksonville.Intl.AP.722060_TMY3.epw"
        elsif dep.downcase == "vintage"
            dependency_values[dep] = "pre-1950"
        else
            runner.registerError("Could not find dependency value for #{dep.to_s}.")
            return nil
        end
    end
    return dependency_values
  end
  
  def get_option_name_from_sample_value(sample_value, dependency_values, total_num_samples, probability_file, full_probability_path, runner)
    # Retrieve option name from probability file based on sample value
    
    option_name = nil
    header_line = nil
    
    CSV.foreach(full_probability_path, { :col_sep => "\t" }) do |row|
    
        # Store single header line
        if header_line.nil?
            header_line = row
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
                for col in 0..(header_line.size-1)
                    if header_line[col].strip.downcase == col_s.downcase
                        dep_col = col
                        break
                    end
                end
                if dep_col == -1
                    runner.registerError("Could not find column '#{col_s.to_s}' in #{probability_file.to_s}.")
                    return option_name
                end
                if row[dep_col].downcase == dep_val.downcase
                    num_deps_matched += 1
                end
            end
            if num_deps_matched == dependency_values.size
                found_row = true
            end
        end
        #runner.registerInfo("row #{row.to_s} num_deps_matched #{num_deps_matched.to_s} dependency_values.size #{dependency_values.size.to_s} found_row #{found_row.to_s}")
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
            #runner.registerInfo("index #{index.to_s} rowval #{rowval.to_s} rowsum #{rowsum.to_s} sampleval #{(sample_value/total_num_samples.to_f).to_s}")
            if rowsum > sample_value/total_num_samples.to_f
                option_name = header_line[index+dependency_values.size]
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
        runner.registerError("Could not find measure arguments for parameter #{parameter_name.to_s} and option #{option_name.to_s}.")
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
  
  def get_argument_map(model, measure, measure_args)
    # Get arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Ruleset.convertOSArgumentVectorToMap(arguments)
    
    # Default/overwrite arguments as appropriate
    args_hash = default_args_hash(model, measure)
    measure_args.each do |k,v|
        args_hash[k] = v
    end
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
      # FIXME: Why look at this as opposed to the return value of measure.run?
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
    #FIXME: Ry will help
    #runner.RegisterValue(parameter_name, option_name)
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
