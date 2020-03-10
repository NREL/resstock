require 'fileutils'

require 'rake'
require 'rake/testtask'
require 'ci/reporter/rake/minitest'

require 'pp'
require 'colored'
require 'json'

desc 'Perform tasks related to unit tests'
namespace :test do
  desc 'Run unit tests for all projects/measures'
  Rake::TestTask.new('unit_tests') do |t|
    t.libs << 'test'
    t.test_files = Dir['project_*/tests/*.rb'] + Dir['test/test_integrity_checks.rb'] + Dir['test/test_measures_osw.rb']
    t.warning = false
    t.verbose = true
  end

  desc 'Run regression tests for all example osws'
  Rake::TestTask.new('regression_tests') do |t|
    t.libs << 'test'
    t.test_files = Dir['workflows/tests/*.rb']
    t.warning = false
    t.verbose = true
  end

  desc 'Test creating measure osws'
  Rake::TestTask.new('measures_osw') do |t|
    t.libs << 'test'
    t.test_files = Dir['test/test_measures_osw.rb']
    t.warning = false
    t.verbose = true
  end
end

desc 'Perform integrity check on inputs for all projects'
Rake::TestTask.new('integrity_check_all') do |t|
  t.libs << 'test'
  t.test_files = Dir['project_*/tests/*.rb']
  t.warning = false
  t.verbose = true
end # rake task

desc 'Perform integrity check on inputs for project_multifamily_beta'
Rake::TestTask.new('integrity_check_multifamily_beta') do |t|
  t.libs << 'test'
  t.test_files = Dir['project_multifamily_beta/tests/*.rb']
  t.warning = false
  t.verbose = true
end # rake task

desc 'Perform integrity check on inputs for project_testing'
Rake::TestTask.new('integrity_check_testing') do |t|
  t.libs << 'test'
  t.test_files = Dir['project_testing/tests/*.rb']
  t.warning = false
  t.verbose = true
end # rake task

desc 'Perform unit tests on integrity checks'
Rake::TestTask.new('integrity_check_unit_tests') do |t|
  t.libs << 'test'
  t.test_files = Dir['test/test_integrity_checks.rb']
  t.warning = false
  t.verbose = true
end # rake task

def integrity_check(project_dir_name, housing_characteristics_dir = "housing_characteristics", lookup_file = nil)
  # Load helper file and sampling file
  resources_dir = File.join(File.dirname(__FILE__), 'resources')
  require File.join(resources_dir, 'buildstock')
  require File.join(resources_dir, 'run_sampling')
  require 'csv'

  # Setup
  if lookup_file.nil?
    lookup_file = File.join(resources_dir, 'options_lookup.tsv')
  end
  check_file_exists(lookup_file, nil)

  # Perform various checks on each probability distribution file
  parameters_processed = []
  tsvfiles = {}
  last_size = -1

  parameter_names = []
  get_parameters_ordered_from_options_lookup_tsv(lookup_file).each do |parameter_name|
    tsvpath = File.join(project_dir_name, housing_characteristics_dir, "#{parameter_name}.tsv")
    next if not File.exist?(tsvpath) # Not every parameter used by every project

    parameter_names << parameter_name
  end

  while parameters_processed.size != parameter_names.size

    if last_size == parameters_processed.size
      # No additional processing occurred during last pass
      unprocessed_parameters = parameter_names - parameters_processed
      err = "ERROR: Unable to process these parameters: #{unprocessed_parameters.join(', ')}."
      deps = []
      unprocessed_parameters.each do |p|
        tsvpath = File.join(project_dir_name, housing_characteristics_dir, "#{p}.tsv")
        tsvfile = TsvFile.new(tsvpath, nil)
        tsvfile.dependency_cols.keys.each do |d|
          next if deps.include?(d)

          deps << d
        end
      end
      undefined_deps = deps - unprocessed_parameters - parameters_processed
      # Check if undefined deps exist but are undefined simply because they're not in options_lookup.tsv
      undefined_deps_exist = true
      undefined_deps.each do |undefined_dep|
        tsvpath = File.join(project_dir_name, housing_characteristics_dir, "#{undefined_dep}.tsv")
        next if File.exist?(tsvpath)

        undefined_deps_exist = false
      end
      if undefined_deps_exist
        err += "\nPerhaps one of these dependency files has options missing from options_lookup.tsv? #{undefined_deps.join(', ')}."
      else
        err += "\nPerhaps one of these dependency files is missing? #{undefined_deps.join(', ')}."
      end
      raise err
    end

    err = ""
    last_size = parameters_processed.size
    parameter_names.each do |parameter_name|
      # Already processed? Skip
      next if parameters_processed.include?(parameter_name)

      tsvpath = File.join(project_dir_name, housing_characteristics_dir, "#{parameter_name}.tsv")
      check_file_exists(tsvpath, nil)
      tsvfile = TsvFile.new(tsvpath, nil)
      tsvfiles[parameter_name] = tsvfile

      # Dependencies not yet processed? Skip until a subsequent pass
      skip = false
      tsvfile.dependency_cols.keys.each do |dep|
        next if parameters_processed.include?(dep)

        skip = true
      end
      next if skip

      puts "Checking for issues with #{project_dir_name}/#{parameter_name}..."
      parameters_processed << parameter_name

      # Test that dependency options exist
      tsvfile.dependency_options.each do |dependency, options|
        options.each do |option|
          if not tsvfiles[dependency].option_cols.keys.include? option
            err += "ERROR: #{dependency}=#{option} not a valid dependency option for #{parameter_name}.\n"
          end
        end
      end

      # Test all possible combinations of dependency value combinations
      combo_hashes = get_combination_hashes(tsvfiles, tsvfile.dependency_cols.keys)
      if combo_hashes.size > 0
        combo_hashes.each do |combo_hash|
          _matched_option_name, _matched_row_num = tsvfile.get_option_name_from_sample_number(1.0, combo_hash)
        end
      else
        # global distribution
        _matched_option_name, _matched_row_num = tsvfile.get_option_name_from_sample_number(1.0, nil)
      end

      # Check file format to be consistent with specified guidelines
      check_parameter_file_format(tsvpath, tsvfile.dependency_cols.length(), parameter_name)

      # Check for all options defined in options_lookup.tsv
      get_measure_args_from_option_names(lookup_file, tsvfile.option_cols.keys, parameter_name)
    end
    if not err.empty?
      raise err
    end
  end # parameter_name

  # Test sampling
  r = RunSampling.new
  output_file = r.run(project_dir_name, 1000, 'buildstock.csv', housing_characteristics_dir, lookup_file)

  # Cache {parameter => options}
  parameters_options = {}
  CSV.foreach(output_file, headers: true).each do |row|
    row.each do |parameter_name, option_name|
      next if parameter_name == "Building Unit"

      unless parameters_options.keys.include? parameter_name
        parameters_options[parameter_name] = []
      end

      unless parameters_options[parameter_name].include? option_name
        parameters_options[parameter_name] << option_name
      end
    end
  end

  # Cache {parameter => {option => {measure => {arg => value}}}}
  parameters_options_measure_args = {}
  parameters_options.each do |parameter_name, option_names|
    parameters_options_measure_args[parameter_name] = get_measure_args_from_option_names(lookup_file, option_names, parameter_name)
  end

  # Check that measure arguments aren't getting overwritten
  err = ""
  CSV.foreach(output_file, headers: true).each do |row|
    row.each do |parameter_name, option_name|
      next if parameter_name == "Building Unit"

      parameters_options_measure_args[parameter_name][option_name].each do |measure_name, args|
        parameters_options_measure_args.each do |parameter_name_2, options|
          next if parameter_name == parameter_name_2

          parameters_options_measure_args[parameter_name_2][row[parameter_name_2]].each do |measure_name_2, args_2|
            next if measure_name != measure_name_2

            arg_names = args.keys & args_2.keys
            next if arg_names.empty?
            next if err.include? parameter_name and err.include? parameter_name_2 and err.include? measure_name

            err += "ERROR: Duplicate measure argument assignment(s) across #{[parameter_name, parameter_name_2]} parameters. (#{measure_name} => #{arg_names}) already assigned.\n"
          end
        end
      end
    end
  end
  if not err.empty?
    raise err
  end

  if File.exist?(output_file)
    File.delete(output_file) # Clean up
  end

  # Unused TSVs?
  err = ""
  Dir[File.join(project_dir_name, housing_characteristics_dir, "*.tsv")].each do |tsvpath|
    parameter_name = File.basename(tsvpath, ".*")
    if not parameter_names.include? parameter_name
      err += "ERROR: TSV file #{tsvpath} not used in options_lookup.tsv.\n"
    end
  end
  if not err.empty?
    raise err
  end
end

def integrity_check_options_lookup_tsv(project_dir_name, housing_characteristics_dir = "housing_characteristics", lookup_file = nil)
  require 'openstudio'

  # Load helper file and sampling file
  resources_dir = File.join(File.dirname(__FILE__), 'resources')
  require File.join(resources_dir, 'buildstock')

  # Setup
  if lookup_file.nil?
    lookup_file = File.join(resources_dir, 'options_lookup.tsv')
  end
  check_file_exists(lookup_file, nil)

  # Integrity checks for option_lookup.tsv
  measures = {}
  model = OpenStudio::Model::Model.new

  # Gather all options/arguments
  parameter_names = get_parameters_ordered_from_options_lookup_tsv(lookup_file)
  parameter_names.each do |parameter_name|
    check_for_illegal_chars(parameter_name, 'parameter')

    tsvpath = File.join(project_dir_name, housing_characteristics_dir, "#{parameter_name}.tsv")
    next if not File.exist?(tsvpath) # Not every parameter used by every project

    option_names = get_options_for_parameter_from_options_lookup_tsv(lookup_file, parameter_name)
    options_measure_args = get_measure_args_from_option_names(lookup_file, option_names, parameter_name, nil)
    option_names.each do |option_name|
      check_for_illegal_chars(option_name, 'option')

      # Check for (parameter, option) names
      # Get measure name and arguments associated with the option
      options_measure_args[option_name].each do |measure_subdir, args_hash|
        if not measures.has_key?(measure_subdir)
          measures[measure_subdir] = {}
        end
        if not measures[measure_subdir].has_key?(parameter_name)
          measures[measure_subdir][parameter_name] = {}
        end

        # Skip options with duplicate argument values as a previous option; speeds up processing.
        duplicate_args = false
        measures[measure_subdir][parameter_name].keys.each do |opt_name|
          next if measures[measure_subdir][parameter_name][opt_name].to_s != args_hash.to_s

          duplicate_args = true
          break
        end
        next if duplicate_args

        # Store arguments
        measures[measure_subdir][parameter_name][option_name] = args_hash
      end
    end
  end

  measures.keys.each do |measure_subdir|
    puts "Checking for issues with #{measure_subdir} measure..."

    measurerb_path = File.absolute_path(File.join(File.dirname(lookup_file), "..", "resources", "hpxml-measures", measure_subdir, "measure.rb"))
    check_file_exists(measurerb_path, nil)
    measure_instance = get_measure_instance(measurerb_path)

    # Validate measure arguments for combinations of options
    param_names = measures[measure_subdir].keys()
    options_array = []
    max_param_size = 0
    param_names.each do |parameter_name|
      options_array << measures[measure_subdir][parameter_name].keys()
      max_param_size = [max_param_size, options_array[-1].size].max
    end

    option_combinations = []
    options_array.each_with_index do |option_array, idx|
      for n in 0..max_param_size - 1
        if idx == 0
          option_combinations << []
        end
        option_combinations[n] << option_array[n % option_array.size]
      end
    end

    all_measure_args = []
    max_checks_reached = false
    option_combinations.each_with_index do |option_combination, combo_num|
      measure_args = {}
      option_combination.each_with_index do |option_name, idx|
        measures[measure_subdir][param_names[idx]][option_name].each do |k, v|
          measure_args[k] = v
        end
      end
      next if all_measure_args.include?(measure_args)

      all_measure_args << measure_args
    end

    all_measure_args.shuffle.each_with_index do |measure_args, idx|
      validate_measure_args(measure_instance.arguments(model), measure_args, lookup_file, measure_subdir, nil)
    end
  end
end

def check_for_illegal_chars(name, name_type)
  # Check for illegal characters in parameter/option names. These characters are
  # reserved for use in the apply upgrade logic.
  ['(', ')', '|', '&'].each do |char|
    next unless name.include? char

    raise "ERROR: Illegal character ('#{char}') found in #{name_type} name '#{name}'."
  end
end

def check_parameter_file_format(tsvpath, n_deps, name)
  # For each line in file
  i = 1
  File.read(tsvpath, mode: "rb").each_line do |line|
    # If not a comment line
    next if line.start_with? "\#"

    # Check endline character
    if line.include? "\r\n"
      # Do not perform other checks if the line is the header
      if i > 1
        # Check float format
        # Remove endline character and split the string into array
        line = line.split("\r\n")[0].split("\t")
        # For each non dependency entry check format
        for j in n_deps..line.length() - 1 do
          # Check for scientific format
          if (line[j].include?('e-') || line[j].include?('e+') ||
              line[j].include?('E-') || line[j].include?('E+'))
            raise "ERROR: Scientific notation found in '#{name}', line '#{i}'."
          end

          begin # Try to get the float precision
            float_precision = line[j].split('.')[1].length()
          rescue NoMethodError
            # Catch non floats
            raise "ERROR: Incorrect non float found in '#{name}', line '#{i}'."
          end
          # If float precision is not 6 digits, raise error
          if float_precision != 6
            raise "ERROR: Incorrect float precision found in '#{name}', line '#{i}'."
          end
        end
      end
    else
      # Found wrong endline format
      raise "ERROR: Incorrect newline character found in '#{name}', line '#{i}'."
    end # End checks
    i += 1
  end
end

def get_all_project_dir_names()
  project_dir_names = []
  Dir.entries(File.dirname(__FILE__)).each do |entry|
    next if not Dir.exist?(entry)
    next if not entry.start_with?("project_") and entry != "test"

    project_dir_names << entry
  end
  return project_dir_names
end

desc 'Apply rubocop, and regenerate example osws'
Rake::TestTask.new('update_measures') do |t|
  t.libs << 'test'
  t.test_files = Dir['test/test_update_measures.rb']
  t.warning = false
  t.verbose = true
end

def update_measures
  require 'openstudio'

  # Apply rubocop
  command = "rubocop --auto-correct --format simple --only Layout"
  puts "Applying rubocop style to measures..."
  system(command)

  # Generate example OSWs

  # Check that there is no missing/extra measures in the measure-info.json
  # and get all_measures name (folders) in the correct order
  data_hash = get_and_proof_measure_order_json()

  example_osws = {
    "TMY" => {
      "weather_station_epw_filename" => "USA_CO_Denver.Intl.AP.725650_TMY3.epw"
    },
    "AMY2012" => {
      "weather_station_epw_filename" => "0465925_US_CO_Boulder_8013_0-20000-0-72469_40.13_-105.22_NSRDB_2.0.1_AMY_2012.epw"
    },
    "AMY2014" => {
      "weather_station_epw_filename" => "0465925_US_CO_Boulder_8013_0-20000-0-72469_40.13_-105.22_NSRDB_2.0.1_AMY_2014.epw"
    }
  }
  example_osws.each do |weather_year, weather_station|
    include_args = {
      "BuildResidentialHPXML" => {
        "hpxml_path" => File.expand_path(File.join(File.dirname(__FILE__), "workflows/run/in.xml")),
        "schedules_output_path" => File.expand_path(File.join(File.dirname(__FILE__), "workflows/run/schedules.csv"))
      },
      "HPXMLtoOpenStudio" => {
        "hpxml_path" => File.expand_path(File.join(File.dirname(__FILE__), "workflows/run/in.xml")),
        "weather_dir" => File.expand_path(File.join(File.dirname(__FILE__), "weather")),
      }
    }

    # SFD
    include_args["BuildResidentialHPXML"]["unit_type"] = "single-family detached"
    include_args["BuildResidentialHPXML"]["cfa"] = "2000"
    include_args["BuildResidentialHPXML"].update(weather_station)
    generate_example_osws(data_hash,
                          include_args,
                          "example_single_family_detached_#{weather_year}.osw")

    # SFA
    include_args["BuildResidentialHPXML"]["unit_type"] = "single-family attached"
    include_args["BuildResidentialHPXML"]["cfa"] = "900"
    include_args["BuildResidentialHPXML"].update(weather_station)
    generate_example_osws(data_hash,
                          include_args,
                          "example_single_family_attached_#{weather_year}.osw")

    # MF
    include_args["BuildResidentialHPXML"]["unit_type"] = "multifamily"
    include_args["BuildResidentialHPXML"]["cfa"] = "900"
    include_args["BuildResidentialHPXML"].update(weather_station)
    generate_example_osws(data_hash,
                          include_args,
                          "example_multifamily_#{weather_year}.osw")
  end
end

def generate_example_osws(data_hash, include_args, osw_filename, simplify = true)
  # This function will generate OpenStudio OSWs
  # with all the measures in it, in the order specified in /resources/measure-info.json

  require 'openstudio'
  require_relative 'resources/meta_measure'

  puts "Updating #{osw_filename}..."

  model = OpenStudio::Model::Model.new
  osw_path = "workflows/#{osw_filename}"

  if File.exist?(osw_path)
    File.delete(osw_path)
  end

  workflowJSON = OpenStudio::WorkflowJSON.new
  workflowJSON.setOswPath(osw_path)
  workflowJSON.addMeasurePath("../resources/hpxml-measures")
  workflowJSON.addMeasurePath("../measures")

  steps = OpenStudio::WorkflowStepVector.new

  # Check for invalid measure names
  all_measures = []
  data_hash.each do |group|
    group["group_steps"].each do |group_step|
      group_step["measures"].each do |measure|
        all_measures << measure
      end
    end
  end

  data_hash.each do |group|
    group["group_steps"].each do |group_step|
      # Default to first measure in step
      measure = group_step["measures"][0]

      measure_path = File.expand_path(File.join("../resources/hpxml-measures", measure), workflowJSON.oswDir.to_s)
      unless File.exist? measure_path
        measure_path = File.expand_path(File.join("../measures", measure), workflowJSON.oswDir.to_s) # for ResidentialSimulationControls, ResidentialDemandResponse
      end
      measure_instance = get_measure_instance("#{measure_path}/measure.rb")

      begin
        measure_args = measure_instance.arguments(model).sort_by { |arg| arg.name }
      rescue
        measure_args = measure_instance.arguments.sort_by { |arg| arg.name } # for reporting measures
      end

      step = OpenStudio::MeasureStep.new(measure)
      if not simplify
        step.setName(measure_instance.name)
        step.setDescription(measure_instance.description)
        step.setModelerDescription(measure_instance.modeler_description)
      end

      # Loop on each argument
      measure_args.each do |arg|
        if arg.hasDefaultValue
          arg_value = arg.defaultValueAsString
          step.setArgument(arg.name, arg_value)
        elsif arg.required
          puts "No default value provided for #{measure} argument '#{arg.name}'."
        end
      end

      if include_args.keys.include? measure
        include_args[measure].each do |arg_name, arg_value|
          step.setArgument(arg_name, arg_value)
        end
      end

      # Push step in Steps
      steps.push(step)
    end
  end

  workflowJSON.setWorkflowSteps(steps)
  workflowJSON.save

  # Strip created_at/updated_at
  require 'json'
  file = File.read(osw_path)
  data_hash = JSON.parse(file)
  data_hash.delete("created_at")
  data_hash.delete("updated_at")
  File.write(osw_path, JSON.pretty_generate(data_hash))
end

def get_and_proof_measure_order_json()
  # This function will check that all measure folders (in measures/)
  # are listed in the /resources/measure-info.json and vice versa
  # and return the list of all measures used in the proper order
  #
  # @return {data_hash} of measure-info.json

  # List all measures in measures/ folders
  model_measure_folder = File.expand_path("../resources/hpxml-measures/", __FILE__)
  resstock_measure_folder = File.expand_path("../measures/", __FILE__)
  all_measures = Dir.entries(model_measure_folder).select { |entry| entry.include?("HPXML") } + Dir.entries(resstock_measure_folder).select { |entry| entry.start_with?("Residential") }

  # Load json, and get all measures in there
  json_file = "resources/measure-info.json"
  json_path = File.expand_path("../#{json_file}", __FILE__)
  data_hash = JSON.parse(File.read(json_path))

  measures_json = []
  data_hash.each do |group|
    group["group_steps"].each do |group_step|
      measures_json += group_step["measures"]
    end
  end

  # Check for missing in JSON file
  missing_in_json = all_measures - measures_json
  if missing_in_json.size > 0
    puts "Warning: There are #{missing_in_json.size} measures missing in '#{json_file}': #{missing_in_json.join(",")}"
  end

  # Check for measures in JSON that don't have a corresponding folder
  extra_in_json = measures_json - all_measures
  if extra_in_json.size > 0
    puts "Warning: There are #{extra_in_json.size} measures extra in '#{json_file}': #{extra_in_json.join(",")}"
  end

  return data_hash
end
