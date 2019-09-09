require 'csv'
require "#{File.dirname(__FILE__)}/meta_measure"

class TsvFile
  def initialize(full_path, runner)
    @full_path = full_path
    @filename = File.basename(full_path)
    @runner = runner
    @rows, @option_cols, @dependency_cols, @full_header, @header = get_file_data()
    @rows_keys_s = construct_rows_keys_s()
  end

  attr_accessor :dependency_cols, :rows, :option_cols, :header, :filename, :rows_keys_s

  def get_file_data()
    option_key = "Option="
    dep_key = "Dependency="

    full_header = nil
    rows = []
    CSV.foreach(@full_path, { :col_sep => "\t" }) do |row|
      row.delete_if { |x| x.nil? or x.size == 0 } # purge trailing empty fields

      # Store one header line
      if full_header.nil?
        full_header = row
        next
      end

      rows << row
    end

    if full_header.nil?
      register_error("Could not find header row in #{@filename.to_s}.", @runner)
    end

    # Strip out everything but options and dependencies from header
    header = full_header.select { |el| el.start_with?(option_key) or el.start_with?(dep_key) }

    # Get all option names/dependencies and corresponding column numbers on header row
    option_cols = {}
    dependency_cols = {}
    full_header.each_with_index do |d, col|
      next if d.nil?

      if d.strip.start_with?(option_key)
        val = d.strip.sub(option_key, "").strip
        option_cols[val] = col
      elsif d.strip.start_with?(dep_key)
        val = d.strip.sub(dep_key, "").strip
        dependency_cols[val] = col
      end
    end
    if option_cols.size == 0
      register_error("No options found in #{@filename.to_s}.", @runner)
    end

    return rows, option_cols, dependency_cols, full_header, header
  end

  def construct_rows_keys_s
    # Caches data for faster tsv lookups
    rows_keys_s = []
    @rows.each_with_index do |row, rownum|
      row_key_values = {}
      @dependency_cols.each do |dep, dep_col|
        row_key_values[dep] = row[@dependency_cols[dep]].downcase
      end
      rows_keys_s << hash_to_string(row_key_values).downcase
    end
    return rows_keys_s
  end

  def get_option_name_from_sample_number(sample_value, dependency_values)
    # Retrieve option name from probability file based on sample value

    matched_option_name = nil
    matched_row_num = nil

    if dependency_values.nil?
      dependency_values = {}
    end

    key_s = hash_to_string(dependency_values)
    key_s_downcase = key_s.downcase

    num_matches = @rows_keys_s.count(key_s_downcase)
    if num_matches > 1
      if key_s.size > 0
        register_error("Multiple rows found in #{@filename.to_s} with dependencies: #{key_s.to_s}.", @runner)
      else
        register_error("Multiple rows found in #{@filename.to_s}.", @runner)
      end
    elsif num_matches == 0
      if key_s.size > 0
        register_error("Could not determine appropriate option in #{@filename.to_s} for sample value #{sample_value.to_s} with dependencies: #{key_s.to_s}.", @runner)
      else
        register_error("Could not determine appropriate option in #{@filename.to_s} for sample value #{sample_value.to_s}.", @runner)
      end
    end

    rownum = @rows_keys_s.index(key_s_downcase)

    row = @rows[rownum]

    # Convert data to numeric row values
    rowvals = {}
    @option_cols.each do |option_name, option_col|
      if not row[option_col].is_number?
        register_error("Field '#{row[option_col].to_s}' in #{@filename.to_s} must be numeric.", @runner)
      end
      rowvals[option_name] = row[option_col].to_f
    end

    # Check positivity of the probability values
    if rowvals.values.min < 0
      register_error("Probability value in #{@filename.to_s} is less than zero.", @runner)
    end

    # Sum of values within 2% of 100%?
    sum_rowvals = rowvals.values.reduce(:+)
    if sum_rowvals < 0.98 or sum_rowvals > 1.02
      register_error("Values in #{@filename.to_s} incorrectly sum to #{sum_rowvals.to_s}.", @runner)
    end

    # If values don't exactly sum to 1, normalize them
    if sum_rowvals != 1.0
      rowvals.each do |option_name, rowval|
        rowvals[option_name] = rowval / sum_rowvals
      end
    end

    # Find appropriate value
    rowsum = 0
    @option_cols.each_with_index do |(option_name, option_col), index|
      rowsum += rowvals[option_name]
      if rowsum >= sample_value or (index == @option_cols.size - 1 and rowsum + 0.00001 >= sample_value)
        matched_option_name = option_name
        matched_row_num = rownum
        break
      end
    end

    return matched_option_name, matched_row_num
  end
end

def get_parameters_ordered_from_options_lookup_tsv(lookup_file, characteristics_dir = nil)
  # Obtain full list of parameters and their order
  params = []
  CSV.foreach(lookup_file, { :col_sep => "\t" }) do |row|
    next if row.size < 2
    next if row[0].nil? or row[0].downcase == "parameter name" or row[1].nil?
    next if params.include?(row[0])

    if not characteristics_dir.nil?
      # skip this option if there is no tsv file provided
      tsvpath = File.join(characteristics_dir, row[0] + ".tsv")
      next if not File.exist?(tsvpath)
    end
    params << row[0]
  end

  return params
end

def get_options_for_parameter_from_options_lookup_tsv(lookup_file, parameter_name)
  options = []
  CSV.foreach(lookup_file, { :col_sep => "\t" }) do |row|
    next if row.size < 2
    next if row[0].nil? or row[0].downcase == "parameter name" or row[1].nil?
    next if row[0].downcase != parameter_name.downcase

    options << row[1]
  end

  return options
end

def get_combination_hashes(tsvfiles, dependencies)
  # Returns an array with hashes that include each combination of
  # dependency values for the given dependencies.
  combos_hashes = []

  # Construct array of dependency value arrays
  depval_array = []
  dependencies.each do |dep|
    depval_array << tsvfiles[dep].option_cols.keys
  end

  if depval_array.size == 0
    return combos_hashes
  end

  # Create combinations
  combos = depval_array.first.product(*depval_array[1..-1])

  # Convert to combinations of hashes
  combos.each do |combo|
    # Convert to hash
    combo_hash = {}
    if combo.is_a?(String)
      combo_hash[dependencies[0]] = combo
    else
      dependencies.each_with_index do |dep, i|
        combo_hash[dep] = combo[i]
      end
    end
    combos_hashes << combo_hash
  end
  return combos_hashes
end

def get_value_from_workflow_step_value(step_value)
  variant_type = step_value.variantType
  if variant_type == "Boolean".to_VariantType
    return step_value.valueAsBoolean
  elsif variant_type == "Double".to_VariantType
    return step_value.valueAsDouble
  elsif variant_type == "Integer".to_VariantType
    return step_value.valueAsInteger
  elsif variant_type == "String".to_VariantType
    return step_value.valueAsString
  end
end

def get_value_from_runner_past_results(runner, key_lookup, measure_name, error_if_missing = true)
  require 'openstudio'
  key_lookup = OpenStudio::toUnderscoreCase(key_lookup)
  success_value = OpenStudio::StepResult.new("Success")
  runner.workflow.workflowSteps.each do |step|
    next if not step.result.is_initialized

    step_result = step.result.get
    next if not step_result.measureName.is_initialized
    next if step_result.measureName.get != measure_name
    next if step_result.value != success_value

    step_result.stepValues.each do |step_value|
      next if step_value.name != key_lookup

      return get_value_from_workflow_step_value(step_value)
    end
  end
  if error_if_missing
    register_error("Could not find past value for '#{key_lookup}'.", runner)
  end
  return nil
end

def get_value_from_runner(runner, key_lookup, error_if_missing = true)
  key_lookup = OpenStudio::toUnderscoreCase(key_lookup)
  runner.result.stepValues.each do |step_value|
    next if step_value.name != key_lookup

    return get_value_from_workflow_step_value(step_value)
  end
  if error_if_missing
    register_error("Could not find value for '#{key_lookup}'.", runner)
  end
end

def get_measure_args_from_option_names(lookup_file, option_names, parameter_name, runner = nil)
  found_options = {}
  options_measure_args = {}
  option_names.each do |option_name|
    found_options[option_name] = false
    options_measure_args[option_name] = {}
  end
  current_option = nil

  CSV.foreach(lookup_file, { :col_sep => "\t" }) do |row|
    next if row.size < 2

    # Found option row?
    if not row[0].nil? and not row[1].nil?
      current_option = nil # reset
      option_names.each do |option_name|
        if row[0].downcase == parameter_name.downcase and row[1].downcase == option_name.downcase
          current_option = option_name
          break
        end
      end
    end
    if not current_option.nil?
      found_options[current_option] = true
      if row.size >= 3 and not row[2].nil?
        measure_dir = row[2]
        args = {}
        for col in 3..(row.size - 1)
          next if row[col].nil? or not row[col].include?("=")

          data = row[col].split("=")
          arg_name = data[0]
          arg_val = data[1]
          args[arg_name] = arg_val
        end
        options_measure_args[current_option][measure_dir] = args
      end
    else
      break if found_options.all? { |elem| elem == true }
    end
  end
  option_names.each do |option_name|
    if not found_options[option_name]
      register_error("Could not find parameter '#{parameter_name.to_s}' and option '#{option_name.to_s}' in #{lookup_file.to_s}.", runner)
    end
  end
  return options_measure_args
end

def print_option_assignment(parameter_name, option_name, runner)
  runner.registerInfo("Assigning option '#{option_name.to_s}' for parameter '#{parameter_name.to_s}'.")
end

def register_value(runner, parameter_name, option_name)
  runner.registerValue(parameter_name, option_name)
end

# Accepts string option_apply_logic and tries to evaluate it based on
# (parameter_name, option_name) pairs stored in runner.
#
# Returns a Boolean if evaluating and applying the logic is successful; nil
# otherwise. Returning true means that the building as defined in runner belongs
# to the downselect set (should be run); returning false means that this
# building has been filtered out.
def evaluate_logic(option_apply_logic, runner, past_results = true)
  # Convert to appropriate ruby statement for evaluation
  if option_apply_logic.count("(") != option_apply_logic.count(")")
    runner.registerError("Inconsistent number of open and close parentheses in logic.")
    return nil
  end

  ruby_eval_str = ""
  option_apply_logic.split("||").each do |or_segment|
    or_segment.split("&&").each do |segment|
      segment.strip!

      # Handle presence of open parentheses
      rindex = segment.rindex("(")
      if rindex.nil?
        rindex = 0
      else
        rindex += 1
      end
      segment_open = segment[0, rindex].gsub(" ", "")

      # Handle presence of exclamation point
      segment_equality = "'=='"
      if segment[rindex] == '!'
        segment_equality = "'!='"
        rindex += 1
      end

      # Handle presence of close parentheses
      lindex = segment.index(")")
      if lindex.nil?
        lindex = segment.size
      end
      segment_close = segment[lindex, segment.size - lindex].gsub(" ", "")

      segment_parameter, segment_option = segment[rindex, lindex - rindex].strip.split("|")

      # Get existing building option name for the same parameter
      if past_results
        segment_existing_option = get_value_from_runner_past_results(runner, segment_parameter, "build_existing_model")
      else
        segment_existing_option = get_value_from_runner(runner, segment_parameter)
      end

      ruby_eval_str += segment_open + "'" + segment_existing_option + segment_equality + segment_option + "'" + segment_close + " and "
    end
    ruby_eval_str.chomp!(" and ")
    ruby_eval_str += " or "
  end
  ruby_eval_str.chomp!(" or ")
  result = eval(ruby_eval_str)
  runner.registerInfo("Evaluating logic: #{option_apply_logic}.")
  runner.registerInfo("Converted to Ruby: #{ruby_eval_str}.")
  runner.registerInfo("Ruby Evaluation: #{result.to_s}.")
  if not [true, false].include?(result)
    runner.registerError("Logic was not successfully evaluated: #{ruby_eval_str}")
    return nil
  end
  return result
end
