# frozen_string_literal: true

require 'parallel'
require 'json'
require 'yaml'
require_relative '../resources/buildstock'
require_relative '../resources/run_sampling'

start_time = Time.now

def run_workflow(yml, measures_only, debug)
  cfg = YAML.load_file(yml)

  if ['residential_quota_downselect'].include?(cfg['sampler']['type'])
    fail "Not supporting 'residential_quota_downselect' at this time."
  end

  workflow_args = {}
  workflow_args.update(cfg['workflow_generator']['args'])

  measure_dir_names = { 'build_existing_model' => 'BuildExistingModel',
                        'simulation_output_report' => 'ReportSimulationOutput' }

  steps = []
  workflow_args.each do |measure_dir_name, arguments|
    if measure_dir_name == 'reporting_measures'
      workflow_args[measure_dir_name].each do |k|
        steps << { 'measure_dir_name' => k['measure_dir_name'] }
      end
    elsif measure_dir_name == 'server_directory_cleanup'
      next
    else
      arguments['building_id'] = 1 if measure_dir_name == 'build_existing_model'
      steps << { 'measure_dir_name' => measure_dir_names[measure_dir_name],
                 'arguments' => arguments }
    end
  end

  if cfg.keys.include?('upgrades')
    measure_d = cfg['upgrades'][0]
    apply_upgrade_measure = { 'measure_dir_name' => 'ApplyUpgrade',
                              'arguments' => { 'run_measure' => 1 } }
    if measure_d.include?('upgrade_name')
      apply_upgrade_measure['arguments']['upgrade_name'] = measure_d['upgrade_name']
    end
    measure_d['options'].each_with_index do |option, opt_num|
      opt_num += 1
      apply_upgrade_measure['arguments']["option_#{opt_num}"] = option['option']
      if option.include?('lifetime')
        apply_upgrade_measure['arguments']["option_#{opt_num}_lifetime"] = option['lifetime']
      end
      if option.include?('apply_logic')
        apply_upgrade_measure['arguments']["option_#{opt_num}_apply_logic"] = option['apply_logic']
      end
      option['costs'].each_with_index do |cost, cost_num|
        cost_num += 1
        ['value', 'multiplier'].each do |arg|
          next if !cost.include?(arg)

          apply_upgrade_measure['arguments']["option_#{opt_num}_cost_#{cost_num}_#{arg}"] = cost[arg]
        end
      end
    end
    if measure_d.include?('package_apply_logic')
      apply_upgrade_measure['arguments']['package_apply_logic'] = measure_d['package_apply_logic']
    end

    steps.insert(1, apply_upgrade_measure)
  end

  steps.insert(-2, { 'measure_dir_name' => 'ReportHPXMLOutput',
                     'arguments' => {
                       'output_format' => 'csv',
                     } })

  steps.insert(-2, { 'measure_dir_name' => 'UpgradeCosts' })

  osw = {
    'measure_paths': ['../../../measures', '../../../resources/hpxml-measures'],
    'steps': steps
  }

  thisdir = File.dirname(__FILE__)
  base, ext = File.basename(yml).split('.')

  osw_path = File.join(thisdir, "#{base}.osw")
  File.open(osw_path, 'w') do |f|
    f.write(JSON.pretty_generate(osw))
  end

  buildstock_directory = cfg['buildstock_directory']
  project_directory = cfg['project_directory']
  output_directory = cfg['output_directory']
  n_datapoints = cfg['sampler']['args']['n_datapoints']

  results_dir = File.absolute_path(File.join(thisdir, output_directory))
  fail "Output directory #{output_directory} already exists." if File.exist?(results_dir)

  Dir.mkdir(results_dir)

  # Create lib folder
  lib_dir = File.join(thisdir, '..', 'lib')
  resources_dir = File.join(thisdir, '..', 'resources')
  housing_characteristics_dir = File.join(File.dirname(yml), 'housing_characteristics')
  create_lib_folder(lib_dir, resources_dir, housing_characteristics_dir)

  # Create weather folder
  weather_dir = File.join(thisdir, '..', 'weather')
  if !File.exist?(weather_dir)
    if cfg.keys.include?('weather_files_url')
      require 'tempfile'
      tmpfile = Tempfile.new('epw')

      weather_files_url = cfg['weather_files_url']
      UrlResolver.fetch(weather_files_url, tmpfile)

      weather_files_path = tmpfile.path.to_s
    elsif cfg.keys.include?('weather_files_path')
      weather_files_path = cfg['weather_files_path']
    else
      fail "Must include 'weather_files_url' or 'weather_files_path' in yml."
    end
    puts 'Extracting weather files...'
    unzip_file = OpenStudio::UnzipFile.new(weather_files_path)
    unzip_file.extractAllFiles(OpenStudio::toPath(weather_dir))
  end

  # Create buildstock.csv
  outfile = File.join('..', 'lib', 'housing_characteristics', 'buildstock.csv')
  create_buildstock_csv(project_directory, n_datapoints, outfile)

  all_results_characteristics = []
  all_results_output = []
  samples_osw(results_dir, osw_path, n_datapoints, all_results_characteristics, all_results_output, measures_only, debug)

  results_csv_characteristics = RunOSWs.write_summary_results(results_dir, 'results_characteristics.csv', all_results_characteristics)
  results_csv_output = RunOSWs.write_summary_results(results_dir, 'results_output.csv', all_results_output)

  change_building_id(osw_path, 1)

  return true
end

def create_lib_folder(lib_dir, resources_dir, housing_characteristics_dir)
  Dir.mkdir(lib_dir) unless File.exist?(lib_dir)
  FileUtils.cp_r(resources_dir, lib_dir)
  FileUtils.cp_r(housing_characteristics_dir, lib_dir)
end

def create_buildstock_csv(project_dir, num_samples, outfile)
  r = RunSampling.new
  r.run(project_dir, num_samples, outfile)
end

def samples_osw(results_dir, osw_path, num_samples, all_results_characteristics, all_results_output, measures_only, debug)
  osw_dir = File.join(results_dir, 'osw')
  Dir.mkdir(osw_dir) unless File.exist?(osw_dir)

  xml_dir = File.join(results_dir, 'xml')
  Dir.mkdir(xml_dir) unless File.exist?(xml_dir)

  workflow_and_building_ids = []
  (1..num_samples).to_a.each do |building_id|
    workflow_and_building_ids << [osw_path, building_id]
  end

  Parallel.map(workflow_and_building_ids, in_threads: Parallel.processor_count) do |workflow, building_id|
    worker_number = Parallel.worker_number
    osw_basename = File.basename(workflow)
    puts "\nWorkflow: #{osw_basename}, Building ID: #{building_id} (#{workflow_and_building_ids.index([workflow, building_id]) + 1} / #{workflow_and_building_ids.size}), Worker Number: #{worker_number} ...\n"

    worker_folder = "run#{worker_number}"
    worker_dir = File.join(results_dir, worker_folder)
    Dir.mkdir(worker_dir) unless File.exist?(worker_dir)
    FileUtils.cp(workflow, worker_dir)
    osw = File.join(worker_dir, File.basename(workflow))

    change_building_id(osw, building_id)

    finished_job, result_characteristics, result_output = RunOSWs.run_and_check(osw, worker_dir, measures_only)

    osw = "#{building_id.to_s.rjust(4, '0')}.osw"
    result_characteristics['OSW'] = osw
    result_output['OSW'] = osw

    check_finished_job(result_characteristics, finished_job)
    check_finished_job(result_output, finished_job)

    all_results_characteristics << result_characteristics
    all_results_output << result_output

    run_dir = File.join(worker_dir, 'run')
    if debug
      FileUtils.mv(File.join(run_dir, 'in.xml'), File.join(xml_dir, "#{building_id}-existing-defaulted.xml")) if !File.exist?(File.join(run_dir, 'upgraded.xml'))
      FileUtils.mv(File.join(run_dir, 'in.xml'), File.join(xml_dir, "#{building_id}-upgraded-defaulted.xml")) if File.exist?(File.join(run_dir, 'upgraded.xml'))
      FileUtils.mv(File.join(run_dir, 'existing.xml'), File.join(xml_dir, "#{building_id}-existing.xml"))
      FileUtils.mv(File.join(run_dir, 'upgraded.xml'), File.join(xml_dir, "#{building_id}-upgraded.xml")) if File.exist?(File.join(run_dir, 'upgraded.xml'))
      FileUtils.mv(File.join(run_dir, 'existing.osw'), File.join(osw_dir, "#{building_id}-existing.osw"))
      FileUtils.mv(File.join(run_dir, 'upgraded.osw'), File.join(osw_dir, "#{building_id}-upgraded.osw")) if File.exist?(File.join(run_dir, 'upgraded.osw'))
    else
      FileUtils.mv(File.join(run_dir, 'in.xml'), File.join(xml_dir, "#{building_id}.xml"))
      FileUtils.mv(File.join(run_dir, 'existing.osw'), File.join(osw_dir, "#{building_id}.osw")) if !File.exist?(File.join(run_dir, 'upgraded.osw'))
      FileUtils.mv(File.join(run_dir, 'upgraded.osw'), File.join(osw_dir, "#{building_id}.osw")) if File.exist?(File.join(run_dir, 'upgraded.osw'))
    end
  end
end

def change_building_id(osw, building_id)
  json = JSON.parse(File.read(osw), symbolize_names: true)
  json[:steps].each do |measure|
    next if measure[:measure_dir_name] != 'BuildExistingModel'

    measure[:arguments][:building_id] = "#{building_id}"
  end
  File.open(osw, 'w') do |f|
    f.write(JSON.pretty_generate(json))
  end
end

def check_finished_job(result, finished_job)
  result['completed_status'] = 'Fail'
  if File.exist?(finished_job)
    result['completed_status'] = 'Success'
  end

  return result
end

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: #{File.basename(__FILE__)} -y buildstockbatch.yml\n e.g., #{File.basename(__FILE__)} -y national_baseline.yml\n"

  opts.on('-y', '--yml <FILE>', 'YML file') do |t|
    options[:yml] = t
  end

  options[:version] = false
  opts.on('-v', '--version', 'Reports the version') do |t|
    options[:version] = true
  end

  options[:measures_only] = false
  opts.on('-m', '--measures_only', 'Only run the OpenStudio and EnergyPlus measures') do |t|
    options[:measures_only] = true
  end

  options[:debug] = false
  opts.on('-d', '--debug', 'Save both existing and upgraded osw files.') do |t|
    options[:debug] = true
  end

  opts.on_tail('-h', '--help', 'Display help') do
    puts opts
    exit!
  end
end.parse!

if options[:version]
  puts "#{software_program_used} v#{software_program_version}"
  exit!
end

if not options[:yml]
  fail "YML argument is required. Call #{File.basename(__FILE__)} -h for usage."
end

# Run analysis
puts "YML: #{options[:yml]}"
success = run_workflow(options[:yml], options[:measures_only], options[:debug])

if not success
  exit! 1
end

puts "Completed in #{(Time.now - start_time).round(1)}s."
