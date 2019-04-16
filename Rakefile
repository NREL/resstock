require 'fileutils'

require 'rake'
require 'rake/testtask'
require 'ci/reporter/rake/minitest'

require 'pp'
require 'colored'
require 'json'

desc 'perform tasks related to unit tests'
namespace :test do
  desc 'Run unit tests for all projects/measures'
  Rake::TestTask.new('all') do |t|
    t.libs << 'test'
    t.test_files = Dir['project_*/tests/*.rb'] + Dir['measures/*/tests/*.rb'] + Dir['resources/measures/*/tests/*.rb'] + Dir['workflows/tests/*.rb'] - Dir['measures/HPXMLtoOpenStudio/tests/*.rb'] # HPXMLtoOpenStudio is tested upstream
    t.warning = false
    t.verbose = true
  end

  desc 'regenerate test osm files from osw files'
  Rake::TestTask.new('regenerate_osms') do |t|
    t.libs << 'test'
    t.test_files = Dir['test/osw_files/tests/*.rb']
    t.warning = false
    t.verbose = true
  end
end

def regenerate_osms
  require 'openstudio'

  start_time = Time.now
  num_tot = 0
  num_success = 0

  osw_path = File.expand_path("../test/osw_files/", __FILE__)
  osm_path = File.expand_path("../test/osm_files/", __FILE__)

  osw_files = Dir.entries(osw_path).select { |entry| entry.end_with?(".osw") and entry != "out.osw" }

  if File.exists?(File.expand_path("../log", __FILE__))
    FileUtils.rm(File.expand_path("../log", __FILE__))
  end

  cli_path = OpenStudio.getOpenStudioCLI

  num_osws = osw_files.size

  osw_files.each do |osw|
    # Generate osm from osw
    num_tot += 1

    puts "[#{num_tot}/#{num_osws}] Regenerating osm from #{osw}..."
    osw = File.expand_path("../test/osw_files/#{osw}", __FILE__)
    update_and_format_osw(osw)
    osm = File.expand_path("../test/osw_files/run/in.osm", __FILE__)
    command = "\"#{cli_path}\" --no-ssl run -w #{osw} -m >> log"
    for _retry in 1..3
      system(command)
      break if File.exists?(osm)
    end
    if not File.exists?(osm)
      fail "  ERROR: Could not generate osm."
    end

    # Add auto-generated message to top of file
    # Update EPW file paths to be relative for the CircleCI machine
    file_text = File.readlines(osm)
    File.open(osm, "w") do |f|
      f.write("!- NOTE: Auto-generated from #{osw.gsub(File.dirname(__FILE__), "")}\n")
      file_text.each do |file_line|
        if file_line.strip.start_with?("file:///")
          file_data = file_line.split('/')
          epw_name = file_data[-1].split(',')[0]
          if File.exists? File.join(File.dirname(__FILE__), "resources/measures/HPXMLtoOpenStudio/weather/#{epw_name}")
            file_line = file_data[0] + "../weather/" + file_data[-1]
          else
            # File not found in weather dir, assume it's in measure's tests dir instead
            file_line = file_data[0] + "../tests/" + file_data[-1]
          end
        end
        f.write(file_line)
      end
    end

    # Copy to osm dir
    osm_new = File.join(osm_path, File.basename(osw).gsub(".osw", ".osm"))
    FileUtils.cp(osm, osm_new)
    num_success += 1

    # Clean up
    run_dir = File.expand_path("../test/osw_files/run", __FILE__)
    if Dir.exists?(run_dir)
      FileUtils.rmtree(run_dir)
    end
    if File.exists?(File.expand_path("../test/osw_files/out.osw", __FILE__))
      FileUtils.rm(File.expand_path("../test/osw_files/out.osw", __FILE__))
    end
  end

  puts "Completed. #{num_success} of #{num_tot} osm files were regenerated successfully (#{Time.now - start_time} seconds)."
end

def update_and_format_osw(osw)
  # Insert new step(s) into test osw files, if they don't already exist: {step1=>index1, step2=>index2, ...}
  # e.g., new_steps = {{"measure_dir_name"=>"ResidentialSimulationControls"}=>0}
  new_steps = {}
  json = JSON.parse(File.read(osw), :symbolize_names => true)
  steps = json[:steps]
  new_steps.each do |new_step, ix|
    insert_new_step = true
    steps.each do |step|
      step.each do |k, v|
        next if k != :measure_dir_name
        next if v != new_step.values[0] # already have this step

        insert_new_step = false
      end
    end
    next unless insert_new_step

    json[:steps].insert(ix, new_step)
  end
  File.open(osw, "w") do |f|
    f.write(JSON.pretty_generate(json)) # format nicely even if not updating the osw with new steps
  end
end

desc 'Perform integrity check on inputs for all projects'
task :integrity_check_all do
  get_all_project_dir_names().each do |project_dir_name|
    integrity_check(project_dir_name)
    integrity_check_options_lookup_tsv(project_dir_name)
  end
end # rake task

desc 'Perform integrity check on inputs for project_resstock_national'
task :integrity_check_resstock_national do
  integrity_check('project_resstock_national')
  integrity_check_options_lookup_tsv('project_resstock_national')
end # rake task

desc 'Perform integrity check on inputs for project_resstock_multifamily'
task :integrity_check_resstock_multifamily do
  integrity_check('project_resstock_multifamily')
  integrity_check_options_lookup_tsv('project_resstock_multifamily')
end # rake task

desc 'Perform integrity check on inputs for project_resstock_testing'
task :integrity_check_resstock_testing do
  integrity_check('project_resstock_testing')
  integrity_check_options_lookup_tsv('project_resstock_testing')
end # rake task

def integrity_check(project_dir_name)
  # Load helper file and sampling file
  resources_dir = File.join(File.dirname(__FILE__), 'resources')
  require File.join(resources_dir, 'buildstock')
  require File.join(resources_dir, 'run_sampling')

  # Setup
  lookup_file = File.join(resources_dir, 'options_lookup.tsv')
  check_file_exists(lookup_file, nil)

  # Perform various checks on each probability distribution file
  parameters_processed = []
  tsvfiles = {}
  last_size = -1

  parameter_names = []
  get_parameters_ordered_from_options_lookup_tsv(resources_dir).each do |parameter_name|
    tsvpath = File.join(project_dir_name, "housing_characteristics", "#{parameter_name}.tsv")
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
        tsvpath = File.join(project_dir_name, "housing_characteristics", "#{p}.tsv")
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
        tsvpath = File.join(project_dir_name, "housing_characteristics", "#{undefined_dep}.tsv")
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

    last_size = parameters_processed.size
    parameter_names.each do |parameter_name|
      # Already processed? Skip
      next if parameters_processed.include?(parameter_name)

      tsvpath = File.join(project_dir_name, "housing_characteristics", "#{parameter_name}.tsv")
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

      # Check for all options defined in options_lookup.tsv
      get_measure_args_from_option_names(lookup_file, tsvfile.option_cols.keys, parameter_name)
    end
  end # parameter_name

  # Test sampling
  r = RunSampling.new
  output_file = r.run(project_dir_name, 1000, 'buildstock.csv')
  if File.exist?(output_file)
    File.delete(output_file) # Clean up
  end

  # Unused TSVs?
  err = ""
  Dir[File.join(project_dir_name, "housing_characteristics", "*.tsv")].each do |tsvpath|
    parameter_name = File.basename(tsvpath, ".*")
    if not parameter_names.include? parameter_name
      err += "ERROR: TSV file #{tsvpath} not used in options_lookup.tsv.\n"
    end
  end
  if not err.empty?
    raise err
  end
end

def integrity_check_options_lookup_tsv(project_dir_name)
  require 'openstudio'

  # Load helper file and sampling file
  resources_dir = File.join(File.dirname(__FILE__), 'resources')
  require File.join(resources_dir, 'buildstock')

  # Setup
  lookup_file = File.join(resources_dir, 'options_lookup.tsv')
  check_file_exists(lookup_file, nil)

  # Integrity checks for option_lookup.tsv
  measures = {}
  model = OpenStudio::Model::Model.new

  # Gather all options/arguments
  parameter_names = get_parameters_ordered_from_options_lookup_tsv(resources_dir)
  parameter_names.each do |parameter_name|
    tsvpath = File.join(project_dir_name, "housing_characteristics", "#{parameter_name}.tsv")
    next if not File.exist?(tsvpath) # Not every parameter used by every project

    option_names = get_options_for_parameter_from_options_lookup_tsv(resources_dir, parameter_name)
    options_measure_args = get_measure_args_from_option_names(lookup_file, option_names, parameter_name, nil)
    option_names.each do |option_name|
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

  max_checks = 1000
  measures.keys.each do |measure_subdir|
    puts "Checking for issues with #{measure_subdir} measure..."

    measurerb_path = File.absolute_path(File.join(File.dirname(lookup_file), 'measures', measure_subdir, 'measure.rb'))
    check_file_exists(measurerb_path, nil)
    measure_instance = get_measure_instance(measurerb_path)

    # Validate measure arguments for each combination of options
    param_names = measures[measure_subdir].keys()
    options_array = []
    param_names.each do |parameter_name|
      if ["Bathroom Spot Vent Hour", "Clothes Dryer Spot Vent Hour", "Range Spot Vent Hour"].include? parameter_name
        # Prevent "too big to product" error for airflow measure by just
        # using first option for these parameters.
        options_array << [measures[measure_subdir][parameter_name].keys()[0]]
      else
        options_array << measures[measure_subdir][parameter_name].keys()
      end
    end
    option_combinations = options_array.first.product(*options_array[1..-1])

    all_measure_args = []
    max_checks_reached = false
    option_combinations.shuffle.each_with_index do |option_combination, combo_num|
      if combo_num > max_checks
        max_checks_reached = true
        break
      end
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

    if max_checks_reached
      puts "Max number of checks (#{max_checks}) reached. Continuing..."
    end
  end
end

def get_all_project_dir_names()
  project_dir_names = []
  Dir.entries(File.dirname(__FILE__)).each do |entry|
    next if not Dir.exist?(entry)
    next if not entry.start_with?("project_")

    project_dir_names << entry
  end
  return project_dir_names
end

desc 'update all measures'
task :update_measures do
  require 'openstudio'

  # Apply rubocop
  command = "rubocop --auto-correct --format simple --only Layout"
  puts "Applying rubocop style to measures..."
  system(command)

  [File.expand_path("../measures/", __FILE__), File.expand_path("../resources/measures/", __FILE__)].each do |measures_dir|
    # Update measure xmls
    cli_path = OpenStudio.getOpenStudioCLI
    command = "\"#{cli_path}\" --no-ssl measure --update_all #{measures_dir} >> log"
    puts "Updating measure.xml files in #{measures_dir}..."
    system(command)
  end

  # Generate example OSWs

  # Check that there is no missing/extra measures in the measure-info.json
  # and get all_measures name (folders) in the correct order
  data_hash = get_and_proof_measure_order_json()

  exclude_measures = ["ResidentialHotWaterSolar",
                      "ResidentialHVACCeilingFan",
                      "ResidentialHVACDehumidifier",
                      "ResidentialMiscLargeUncommonLoads"]

  # SFD
  include_measures = ["ResidentialGeometryCreateSingleFamilyDetached"]
  generate_example_osws(data_hash,
                        include_measures,
                        exclude_measures,
                        "example_single_family_detached.osw")

  # SFA
  include_measures = ["ResidentialGeometryCreateSingleFamilyAttached"]
  generate_example_osws(data_hash,
                        include_measures,
                        exclude_measures,
                        "example_single_family_attached.osw")

  # MF
  include_measures = ["ResidentialGeometryCreateMultifamily", "ResidentialConstructionsFinishedRoof"]
  generate_example_osws(data_hash,
                        include_measures,
                        exclude_measures,
                        "example_multifamily.osw")

  # FloorspaceJS
  # include_measures = ["ResidentialGeometryCreateFromFloorspaceJS"]
  # generate_example_osws(data_hash,
  #                      include_measures,
  #                      exclude_measures,
  #                      "example_from_floorspacejs.osw")
end

def generate_example_osws(data_hash, include_measures, exclude_measures,
                          osw_filename, simplify = true)
  # This function will generate OpenStudio OSWs
  # with all the measures in it, in the order specified in /resources/measure-info.json

  require 'openstudio'
  require_relative 'resources/measures/HPXMLtoOpenStudio/resources/meta_measure'

  puts "Updating #{osw_filename}..."

  model = OpenStudio::Model::Model.new
  osw_path = "workflows/#{osw_filename}"

  if File.exist?(osw_path)
    File.delete(osw_path)
  end

  workflowJSON = OpenStudio::WorkflowJSON.new
  workflowJSON.setOswPath(osw_path)
  workflowJSON.addMeasurePath("../measures")
  workflowJSON.addMeasurePath("../resources/measures")

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
  (include_measures + exclude_measures).each do |m|
    next if all_measures.include? m

    puts "Error: No measure found with name '#{m}'."
    exit
  end

  data_hash.each do |group|
    group["group_steps"].each do |group_step|
      # Default o first measure in step
      measure = group_step["measures"][0]

      # Override with include measure?
      include_measures.each do |include_measure|
        if group_step["measures"].include? include_measure
          measure = include_measure
        end
      end

      # Skip exclude measures
      if exclude_measures.include? measure
        next
      end

      measure_path = File.expand_path(File.join("../resources/measures", measure), workflowJSON.oswDir.to_s)
      unless File.exist? measure_path
        measure_path = File.expand_path(File.join("../measures", measure), workflowJSON.oswDir.to_s) # for ResidentialSimulationControls
      end
      measure_instance = get_measure_instance("#{measure_path}/measure.rb")

      measure_args = measure_instance.arguments(model).sort_by { |arg| arg.name }

      step = OpenStudio::MeasureStep.new(measure)
      if not simplify
        step.setName(measure_instance.name)
        step.setDescription(measure_instance.description)
        step.setModelerDescription(measure_instance.modeler_description)
      end

      # Loop on each argument
      measure_args.each do |arg|
        if arg.hasDefaultValue
          step.setArgument(arg.name, arg.defaultValueAsString)
        elsif arg.required
          puts "Error: No default value provided for #{measure} argument '#{arg.name}'."
          exit
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
  measure_folder = File.expand_path("../measures/", __FILE__)
  resources_measure_folder = File.expand_path("../resources/measures/", __FILE__)
  all_measures = Dir.entries(measure_folder).select { |entry| entry.start_with?('Residential') } + Dir.entries(resources_measure_folder).select { |entry| entry.start_with?('Residential') }

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

desc 'update urdb tariffs'
task :update_tariffs do
  require 'csv'
  require 'net/https'
  require 'zip'

  tariffs_path = "./resources/tariffs"
  tariffs_zip = "#{tariffs_path}.zip"

  if not File.exists?(tariffs_path)
    FileUtils.mkdir_p("./resources/tariffs")
  end

  if File.exists?(tariffs_zip)
    Zip::File.open(tariffs_zip) do |zip_file|
      zip_file.each do |entry|
        next unless entry.file?

        entry_path = File.join(tariffs_path, entry.name)
        zip_file.extract(entry, entry_path) unless File.exists?(entry_path)
      end
    end
    FileUtils.rm_rf(tariffs_zip)
  end

  result = get_tariff_json_files(tariffs_path)

  if result
    Zip::File.open(tariffs_zip, Zip::File::CREATE) do |zip_file|
      Dir[File.join(tariffs_path, "*")].each do |entry|
        zip_file.add(entry.sub(tariffs_path + "/", ""), entry)
      end
    end
    FileUtils.rm_rf(tariffs_path)
  end
end

def get_tariff_json_files(tariffs_path)
  require 'parallel'

  STDOUT.puts "Enter API Key:"
  api_key = STDIN.gets.strip
  return false if api_key.empty?

  url = URI.parse("https://api.openei.org/utility_rates?")
  http = Net::HTTP.new(url.host, url.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE

  rows = CSV.read("./resources/utilities.csv", { :encoding => 'ISO-8859-1' })
  rows = rows[1..-1] # ignore header
  interval = 1
  report_at = interval
  timestep = Time.now
  num_parallel = 1 # FIXME: segfault when num_parallel > 1
  Parallel.each_with_index(rows, in_threads: num_parallel) do |row, i|
    utility, eiaid, name, label = row

    params = { 'version' => 3, 'format' => 'json', 'detail' => 'full', 'getpage' => label, 'api_key' => api_key }
    url.query = URI.encode_www_form(params)
    request = Net::HTTP::Get.new(url.request_uri)
    response = http.request(request)
    response = JSON.parse(response.body, :symbolize_names => true)

    if response.keys.include? :error
      puts "#{response[:error][:message]}."
      if response[:error][:message].include? "exceeded your rate limit"
        false
      end
      next
    end

    entry_path = File.join(tariffs_path, "#{label}.json")

    if response[:items].empty?
      puts "Skipping #{entry_path}: empty tariff."
      next
    end

    File.open(entry_path, "w") do |f|
      f.write(response.to_json)
    end
    puts "Added #{entry_path}."

    # Report out progress
    if i.to_f * 100 / rows.length >= report_at
      puts "INFO: Completed #{report_at}%; #{(Time.now - timestep).round}s"
      report_at += interval
      timestep = Time.now
    end
  end

  return true
end
