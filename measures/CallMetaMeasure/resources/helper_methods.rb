# These methods are here so that they are easily used by both
# the CallMetaMeasure measure and run.rb

def get_value_from_runner_past_results(key_lookup, runner=nil)
    runner.past_results.each do |measure, values|
        values.each do |k, v|
            if k.to_s == key_lookup.to_s
                return v.to_s
            end
        end
    end
    register_error("Could not find dependency value for '#{key_lookup.to_s}'.", runner)
    return nil
end
  
def get_parameter_name_and_dependencies(full_probability_path, runner=nil)
    parameter_name = nil
    dependencies = []
    CSV.foreach(full_probability_path, { :col_sep => "\t" }) do |row|
        if parameter_name.nil?
            # First line should be parameter name
            if row.nil? or not row[0].downcase.start_with?("parametername=")
                register_error("Could not find parameter name in #{full_probability_path.to_s}.", runner)
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
  
def check_file_exists(full_path, runner=nil)
    if not File.exist?(full_path)
        register_error("Cannot find file #{full_path.to_s}.", runner)
        return false
    end
    return true
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

def get_all_option_names(full_probability_path, runner=nil)

    option_names = []
    header_lines = []
    
    CSV.foreach(full_probability_path, { :col_sep => "\t" }) do |row|
    
        # Skip one header line
        if header_lines.size < 1
            header_lines << row
            next
        end
        
        # Return option names on third row that aren't
        row.each do |d|
            next if d.nil?
            next if d.strip.downcase.start_with?("dependency=")
            option_names << d.strip
        end
        
        break
    end
    
    if option_names.size == 0
        register_error("No options found in #{File.basename(full_probability_path).to_s}.", runner)
    end

    return option_names
end

def get_option_name_from_sample_value(sample_value, dependency_values, full_probability_path, runner=nil, checkonly=false)
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
                    register_error("Could not find column '#{col_s.to_s}' in #{full_probability_path.to_s}.", runner)
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
            register_error("Values in #{full_probability_path.to_s} incorrectly sum to #{sum_rowvals.to_s}", runner)
            return option_name
        end
        
        # If values don't exactly sum to 1, normalize them
        rowvals = rowvals.collect { |n| n / sum_rowvals }
        
        # Find appropriate value
        rowsum = 0
        rowvals.each_with_index do |rowval, index|
            rowsum += rowval.to_f
            if rowsum >= sample_value
                option_name = header_lines[1][index+dependency_values.size]
                break
            end
        end
    end
    
    if option_name.nil?
        deps_s = hash_to_string(dependency_values)
        if checkonly
            register_error("Could not find row in #{full_probability_path.to_s} with dependencies: #{deps_s.to_s}.")
        elsif deps_s.size > 0
            register_error("Could not determine appropriate option in #{full_probability_path.to_s} for sample value #{sample_value.to_s} with dependencies: #{deps_s.to_s}.", runner)
        else
            register_error("Could not determine appropriate option in #{full_probability_path.to_s} for sample value #{sample_value.to_s}.", runner)
        end
        return option_name
    end
    
    return option_name
end
  
def get_measure_args_from_name(lookup_file, option_name, parameter_name, runner=nil)
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
        register_error("Could not find parameter '#{parameter_name.to_s}' and option '#{option_name.to_s}' in #{lookup_file.to_s}.", runner)
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

def get_measure_args_from_xml(measure_xml_path)
    # Parse XML file for argument names
    require 'rexml/document'
    require 'rexml/xpath'
    xmldoc = REXML::Document.new(File.read(measure_xml_path))
    measure_args = REXML::XPath.match(xmldoc, "//measure/arguments/argument/name").map {|x| x.text }
    return measure_args
end

def get_measure_instance(measure_rb_path)
    # Parse XML file for class name
    require 'rexml/document'
    require 'rexml/xpath'
    xmldoc = REXML::Document.new(File.read(measure_rb_path.sub(".rb",".xml")))
    measure_class = REXML::XPath.first(xmldoc, "//measure/class_name").text
    # Create new instance
    require (measure_rb_path)
    measure = eval(measure_class).new
    return measure
end

def validate_measure_args(args1, args2, lookup_file, parameter_name, option_name, runner=nil)
    # Verify all arguments have been provided
    args1.each do |k|
        next if args2.include?(k)
        register_error("Argument '#{k}' not provided in #{lookup_file.to_s} for parameter '#{parameter_name.to_s}' and option '#{option_name.to_s}'.", runner)
        return false
    end
    args2.each do |k|
        next if args1.include?(k)
        register_error("Extra argument '#{k}' specified in #{lookup_file.to_s} for parameter '#{parameter_name.to_s}' and option '#{option_name.to_s}'.", runner)
        return false
    end
    return true
end
  
def get_argument_map(model, measure, measure_args, lookup_file, parameter_name, option_name, runner=nil)
    # Get default arguments
    args_hash = default_args_hash(model, measure)
    
    if not validate_measure_args(args_hash.keys, measure_args.keys, lookup_file, parameter_name, option_name, runner)
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

def register_error(msg, runner=nil)
    if not runner.nil?
        runner.registerError(msg)
    else
        puts "ERROR: #{msg}"
        exit
    end
end