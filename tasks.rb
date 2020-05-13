def generate_example_osws(data_hash, include_measures, exclude_measures,
                          osw_filename, weather_file, simplify = true)
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
  workflowJSON.addMeasurePath('../measures')
  workflowJSON.addMeasurePath('../resources/measures')

  steps = OpenStudio::WorkflowStepVector.new

  # Check for invalid measure names
  all_measures = []
  data_hash.each do |group|
    group['group_steps'].each do |group_step|
      group_step['measures'].each do |measure|
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
    group['group_steps'].each do |group_step|
      # Default to first measure in step
      measure = group_step['measures'][0]

      # Override with include measure?
      include_measures.each do |include_measure|
        if group_step['measures'].include? include_measure
          measure = include_measure
        end
      end

      # Skip exclude measures
      if exclude_measures.include? measure
        next
      end

      measure_path = File.expand_path(File.join('../resources/measures', measure), workflowJSON.oswDir.to_s)
      unless File.exist? measure_path
        measure_path = File.expand_path(File.join('../measures', measure), workflowJSON.oswDir.to_s) # for ResidentialSimulationControls, TimeseriesCSVExport
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
          arg_value = weather_file if (measure == 'ResidentialLocation') && (arg.name == 'weather_file_name')
          step.setArgument(arg.name, arg_value)
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
  data_hash.delete('created_at')
  data_hash.delete('updated_at')
  File.write(osw_path, JSON.pretty_generate(data_hash))
end

def get_and_proof_measure_order_json()
  # This function will check that all measure folders (in measures/)
  # are listed in the /resources/measure-info.json and vice versa
  # and return the list of all measures used in the proper order
  #
  # @return {data_hash} of measure-info.json

  # List all measures in measures/ folders
  measure_folder = File.expand_path('../measures/', __FILE__)
  resources_measure_folder = File.expand_path('../resources/measures/', __FILE__)
  all_measures = Dir.entries(measure_folder).select { |entry| entry.start_with?('Residential') } + Dir.entries(resources_measure_folder).select { |entry| entry.start_with?('Residential') }

  # Load json, and get all measures in there
  json_file = 'resources/measure-info.json'
  json_path = File.expand_path("../#{json_file}", __FILE__)
  data_hash = JSON.parse(File.read(json_path))

  measures_json = []
  data_hash.each do |group|
    group['group_steps'].each do |group_step|
      measures_json += group_step['measures']
    end
  end

  # Check for missing in JSON file
  missing_in_json = all_measures - measures_json
  if missing_in_json.size > 0
    puts "Warning: There are #{missing_in_json.size} measures missing in '#{json_file}': #{missing_in_json.join(',')}"
  end

  # Check for measures in JSON that don't have a corresponding folder
  extra_in_json = measures_json - all_measures
  if extra_in_json.size > 0
    puts "Warning: There are #{extra_in_json.size} measures extra in '#{json_file}': #{extra_in_json.join(',')}"
  end

  return data_hash
end

def update_and_format_osw(osw)
  # Insert new step(s) into test osw files, if they don't already exist: {step1=>index1, step2=>index2, ...}
  # e.g., new_steps = {{"measure_dir_name"=>"ResidentialSimulationControls"}=>0}
  new_steps = {}
  json = JSON.parse(File.read(osw), symbolize_names: true)
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
  File.open(osw, 'w') do |f|
    f.write(JSON.pretty_generate(json)) # format nicely even if not updating the osw with new steps
  end
end

def get_all_project_dir_names()
  project_dir_names = []
  Dir.entries(File.dirname(__FILE__)).each do |entry|
    next if not Dir.exist?(entry)
    next if (not entry.start_with?('project_')) && (entry != 'test')

    project_dir_names << entry
  end
  return project_dir_names
end

command_list = [:update_measures, :regenerate_osms, :integrity_check_multifamily_beta, :integrity_check_testing]

def display_usage(command_list)
  puts "Usage: openstudio #{File.basename(__FILE__)} [COMMAND]\nCommands:\n  " + command_list.join("\n  ")
end

if ARGV.size == 0
  puts 'ERROR: Missing command.'
  display_usage(command_list)
  exit!
elsif ARGV.size > 1
  puts 'ERROR: Too many commands.'
  display_usage(command_list)
  exit!
elsif not command_list.include? ARGV[0].to_sym
  puts "ERROR: Invalid command '#{ARGV[0]}'."
  display_usage(command_list)
  exit!
end

if ARGV[0].to_sym == :update_measures
  require 'openstudio'
  require 'json'

  # Prevent NREL error regarding U: drive when not VPNed in
  ENV['HOME'] = 'C:' if !ENV['HOME'].nil? && ENV['HOME'].start_with?('U:')
  ENV['HOMEDRIVE'] = 'C:\\' if !ENV['HOMEDRIVE'].nil? && ENV['HOMEDRIVE'].start_with?('U:')

  # Apply rubocop
  cops = ['Layout',
          'Lint/DeprecatedClassMethods',
          'Lint/StringConversionInInterpolation',
          'Style/AndOr',
          'Style/HashSyntax',
          'Style/Next',
          'Style/NilComparison',
          'Style/RedundantParentheses',
          'Style/RedundantSelf',
          'Style/ReturnNil',
          'Style/SelfAssignment',
          'Style/StringLiterals',
          'Style/StringLiteralsInInterpolation']
  commands = ["\"require 'rubocop/rake_task'\"",
              "\"RuboCop::RakeTask.new(:rubocop) do |t| t.options = ['--auto-correct', '--format', 'simple', '--only', '#{cops.join(',')}'] end\"",
              '"Rake.application[:rubocop].invoke"']
  command = "#{OpenStudio.getOpenStudioCLI} -e #{commands.join(' -e ')}"
  puts 'Applying rubocop auto-correct to measures...'
  system(command)

  # Update measures XMLs
  command = "#{OpenStudio.getOpenStudioCLI} measure -t '#{File.join(File.dirname(__FILE__), 'measures')}'"
  puts 'Updating measure.xmls...'
  system(command, [:out, :err] => File::NULL)

  # Generate example OSWs

  # Check that there is no missing/extra measures in the measure-info.json
  # and get all_measures name (folders) in the correct order
  data_hash = get_and_proof_measure_order_json()

  exclude_measures = ['ResidentialHotWaterSolar',
                      'ResidentialHVACCeilingFan',
                      'ResidentialHVACDehumidifier',
                      'ResidentialMiscLargeUncommonLoads']

  example_osws = { 'TMY' => 'USA_CO_Denver.Intl.AP.725650_TMY3.epw', 'AMY2012' => '0465925_US_CO_Boulder_8013_0-20000-0-72469_40.13_-105.22_NSRDB_2.0.1_AMY_2012.epw', 'AMY2014' => '0465925_US_CO_Boulder_8013_0-20000-0-72469_40.13_-105.22_NSRDB_2.0.1_AMY_2014.epw' }
  example_osws.each do |weather_year, weather_file|
    # SFD
    include_measures = ['ResidentialGeometryCreateSingleFamilyDetached']
    generate_example_osws(data_hash,
                          include_measures,
                          exclude_measures,
                          "example_single_family_detached_#{weather_year}.osw",
                          weather_file)

    # SFA
    include_measures = ['ResidentialGeometryCreateSingleFamilyAttached']
    generate_example_osws(data_hash,
                          include_measures,
                          exclude_measures,
                          "example_single_family_attached_#{weather_year}.osw",
                          weather_file)

    # MF
    include_measures = ['ResidentialGeometryCreateMultifamily', 'ResidentialConstructionsFinishedRoof']
    generate_example_osws(data_hash,
                          include_measures,
                          exclude_measures,
                          "example_multifamily_#{weather_year}.osw",
                          weather_file)

    # FloorspaceJS
    # include_measures = ["ResidentialGeometryCreateFromFloorspaceJS"]
    # generate_example_osws(data_hash,
    #                      include_measures,
    #                      exclude_measures,
    #                      "example_from_floorspacejs.osw")
  end

  puts 'Done.'
end

if ARGV[0].to_sym == :regenerate_osms
  require 'openstudio'
  require 'json'
  require_relative 'resources/meta_measure'

  OpenStudio::Logger.instance.standardOutLogger.setLogLevel(OpenStudio::Error)

  start_time = Time.now
  num_tot = 0
  num_success = 0

  osw_path = File.expand_path('../test/osw_files/', __FILE__)
  osm_path = File.expand_path('../test/osm_files/', __FILE__)

  osw_files = Dir.entries(osw_path).select { |entry| entry.end_with?('.osw') }
  num_osws = osw_files.size

  osw_files.each do |osw|
    # Generate osm from osw
    num_tot += 1

    puts "[#{num_tot}/#{num_osws}] Regenerating osm from #{osw}..."
    osw = File.expand_path("../test/osw_files/#{osw}", __FILE__)
    update_and_format_osw(osw)
    osw_hash = JSON.parse(File.read(osw))

    # Create measures hashes for top-level measures and other residential measures
    measures = {}
    resources_measures = {}
    osw_hash['steps'].each do |step|
      if ['ResidentialSimulationControls', 'PowerOutage'].include? step['measure_dir_name']
        measures[step['measure_dir_name']] = [step['arguments']]
      else
        resources_measures[step['measure_dir_name']] = [step['arguments']]
      end
    end

    # Apply measures
    model = OpenStudio::Model::Model.new
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    success = apply_measures(File.expand_path('../measures/', __FILE__), measures, runner, model)
    success = apply_measures(File.expand_path('../resources/measures', __FILE__), resources_measures, runner, model)

    osm = File.expand_path('../test/osw_files/in.osm', __FILE__)
    File.open(osm, 'w') { |f| f << model.to_s }

    # Add auto-generated message to top of file
    # Update EPW file paths to be relative for the CircleCI machine
    file_text = File.readlines(osm)
    File.open(osm, 'w') do |f|
      f.write("!- NOTE: Auto-generated from #{osw.gsub(File.dirname(__FILE__), '')}\n")
      file_text.each do |file_line|
        if file_line.strip.start_with?('file:///')
          file_data = file_line.split('/')
          epw_name = file_data[-1].split(',')[0]
          if File.exist? File.join(File.dirname(__FILE__), "resources/measures/HPXMLtoOpenStudio/weather/#{epw_name}")
            file_line = file_data[0] + '../weather/' + file_data[-1]
          else
            # File not found in weather dir, assume it's in measure's tests dir instead
            file_line = file_data[0] + '../tests/' + file_data[-1]
          end
        end
        f.write(file_line)
      end
    end

    # Copy to osm dir
    osm_new = File.join(osm_path, File.basename(osw).gsub('.osw', '.osm'))
    FileUtils.mv(osm, osm_new)
    num_success += 1
  end

  puts "Completed. #{num_success} of #{num_tot} osm files were regenerated successfully (#{Time.now - start_time} seconds)."
end

if ARGV[0].to_sym == :integrity_check_multifamily_beta
  require_relative 'test/integrity_checks'

  project_dir_name = 'project_multifamily_beta'
  integrity_check(project_dir_name)
  integrity_check_options_lookup_tsv(project_dir_name)
end

if ARGV[0].to_sym == :integrity_check_testing
  require_relative 'test/integrity_checks'

  project_dir_name = 'project_testing'
  integrity_check(project_dir_name)
  integrity_check_options_lookup_tsv(project_dir_name)
end
