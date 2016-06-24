# These methods are here so that they are easily used by both
# the CallMetaMeasure measure and run.rb

def check_file_exists(full_path, runner=nil)
    if not File.exist?(full_path)
        register_error("Cannot find file #{full_path.to_s}.", runner)
    end
end

def check_dir_exists(full_path, runner=nil)
    if not Dir.exist?(full_path)
        register_error("Cannot find directory #{full_path.to_s}.", runner)
    end
end
  
def get_value_from_runner_past_results(key_lookup, runner=nil)
    runner.past_results.each do |measure, values|
        values.each do |k, v|
            if k.to_s == key_lookup.to_s
                return v.to_s
            end
        end
    end
    register_error("Could not find dependency value for '#{key_lookup.to_s}'.", runner)
end

def get_dependency_values_from_runner(dependency_cols, runner)
    # Return hash of dependencies with their values from the runner (from
    # previous meta-measure calls).
    dependency_values = {}
    dependency_cols.keys.each do |dep|
        val = get_value_from_runner_past_results(dep, runner)
        dependency_values[dep] = val
    end
    return dependency_values
end

def get_probability_file_data(full_probability_path, runner)
    header = nil
    rows = []
    CSV.foreach(full_probability_path, { :col_sep => "\t" }) do |row|

        row.delete_if {|x| x.nil? or x.size == 0} # purge trailing empty fields

        # Store one header line
        if header.nil?
            header = row
            next
        end

        rows << row
    end
    
    if header.nil?
        register_error("Could not find header row in #{full_probability_path.to_s}.", runner)
    end
    
    # Get option names on header row
    option_names = []
    header.each do |d|
        next if d.nil?
        next if d.strip.start_with?("Dependency=")
        option_names << d.strip
    end
    if option_names.size == 0
        register_error("No options found in #{File.basename(full_probability_path).to_s}.", runner)
    end
    
    # Get all dependencies and corresponding column numbers on second row
    dependency_cols = {}
    header.each_with_index do |d, col|
        next if d.nil?
        next if not d.strip.start_with?("Dependency=")
        val = d.strip.sub("Dependency=","").strip
        dependency_cols[val] = col
    end

    return rows, option_names, dependency_cols, header
end

def get_option_name_from_sample_number(sample_value, dependency_values, full_probability_path, dependency_cols, option_names, rows, runner=nil)
    # Retrieve option name from probability file based on sample value
    
    option_name = nil
    matched_row_num = nil
    
    rows.each_with_index do |row, rownum|
    
        # Find appropriate row by matching dependency values
        found_row = false
        if dependency_values.nil? or dependency_values.size == 0
            found_row = true
        else
            num_deps_matched = 0
            dependency_values.each do |dep,dep_val|
                next if row[dependency_cols[dep]].nil?
                if row[dependency_cols[dep]].downcase == dep_val.downcase
                    num_deps_matched += 1
                    if num_deps_matched == dependency_values.size
                        found_row = true
                        break
                    end
                end
            end
        end
        next if not found_row
    
        # Convert data to numeric row values
        rowvals = []
        for col in (dependency_values.size)..(row.size-1)
            if not row[col].is_number?
                register_error("Field '#{row[col].to_s}' in #{full_probability_path.to_s} must be numeric.", runner)
            end
            rowvals << row[col].to_f
        end
        
        # Sum of values within 5%?
        sum_rowvals = rowvals.reduce(:+)
        if sum_rowvals < 0.95 or sum_rowvals > 1.05
            register_error("Values in #{full_probability_path.to_s} incorrectly sum to #{sum_rowvals.to_s}.", runner)
        end
        
        # If values don't exactly sum to 1, normalize them
        if sum_rowvals != 1.0
            rowvals = rowvals.collect { |n| n / sum_rowvals }
        end
        
        # Find appropriate value
        rowsum = 0
        rowvals.each_with_index do |rowval, index|
            rowsum += rowval
            if rowsum >= sample_value or (index == rowvals.size-1 and rowsum + 0.00001 >= sample_value)
                option_name = option_names[index]
                matched_row_num = rownum
                break
            end
        end
        
    end
    
    if option_name.nil? or option_name.size == 0
        deps_s = hash_to_string(dependency_values)
        if deps_s.size > 0
            register_error("Could not determine appropriate option in #{full_probability_path.to_s} for sample value #{sample_value.to_s} with dependencies: #{deps_s.to_s}.", runner)
        else
            register_error("Could not determine appropriate option in #{full_probability_path.to_s} for sample value #{sample_value.to_s}.", runner)
        end
        return option_name
    end
    
    return option_name, matched_row_num
end
  
def get_measure_args_from_option_name(lookup_file, option_name, parameter_name, runner=nil)
    found_option = false
    measure_args = {}
    CSV.foreach(lookup_file, { :col_sep => "\t" }) do |row|
        next if row.size < 2
        if not found_option
            # Found option row?
            if not row[0].nil? and not row[1].nil? and row[0].downcase == parameter_name.downcase and row[1].downcase == option_name.downcase
                found_option = true
                if row.size >= 3 and not row[2].nil?
                    measure_dir = row[2]
                    args = {}
                    for col in 3..(row.size-1)
                        next if row[col].nil? or not row[col].include?("=")
                        data = row[col].split("=")
                        arg_name = data[0]
                        arg_val = data[1]
                        args[arg_name] = arg_val
                    end
                    measure_args[measure_dir] = args
                end
                next
            end
        else
            # Additional rows for option?
            if row[0].nil? and row[1].nil?
                if row.size >= 3 and not row[2].nil?
                    measure_dir = row[2]
                    args = {}
                    for col in 3..(row.size-1)
                        next if row[col].nil? or not row[col].include?("=")
                        data = row[col].split("=")
                        arg_name = data[0]
                        arg_val = data[1]
                        args[arg_name] = arg_val
                    end
                    measure_args[measure_dir] = args
                end
            else
                break # we're done searching
            end
        end
    end
    if not found_option
        register_error("Could not find parameter '#{parameter_name.to_s}' and option '#{option_name.to_s}' in #{lookup_file.to_s}.", runner)
    end
    return measure_args
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
    end
    args2.each do |k|
        next if args1.include?(k)
        register_error("Extra argument '#{k}' specified in #{lookup_file.to_s} for parameter '#{parameter_name.to_s}' and option '#{option_name.to_s}'.", runner)
    end
end
  
def get_argument_map(model, measure, measure_args, lookup_file, parameter_name, option_name, runner=nil)
    # Get default arguments
    args_hash = default_args_hash(model, measure)
    
    validate_measure_args(args_hash.keys, measure_args.keys, lookup_file, parameter_name, option_name, runner)
    
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
        hash_s << "#{k.to_s}#{delim.to_s}#{v.to_s}#{separator.to_s}"
    end
    if hash_s.size > 0
        hash_s = hash_s.chomp(separator.to_s)
    end
    return hash_s
end

def register_error(msg, runner=nil)
    if not runner.nil?
        runner.registerError(msg)
        fail msg # OS 2.0 will handle this more gracefully
    else
        puts "ERROR: #{msg}"
        exit
    end
end

class String
  def is_number?
    true if Float(self) rescue false
  end
end
