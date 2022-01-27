# frozen_string_literal: true

require 'parallel'
require 'json'
require 'yaml'
require 'zip'

require_relative '../resources/buildstock'
require_relative '../resources/run_sampling'
require_relative '../resources/util'

require_relative '../resources/measures/HPXMLtoOpenStudio/resources/version'

start_time = Time.now

def run_workflow(yml, measures_only)
  cfg = YAML.load_file(yml)

  upgrade_names = ['Baseline']
  if cfg.keys.include?('upgrades')
    cfg['upgrades'].each do |upgrade|
      upgrade_names << upgrade['upgrade_name'].gsub(' ', '')
    end
  end

  osw_paths = {}
  thisdir = File.dirname(__FILE__)

  upgrade_names.each_with_index do |upgrade_name, upgrade_idx|
    workflow_args = {
      'residential_simulation_controls' => {},
      'simulation_output' => {}
    }
    workflow_args.update(cfg['workflow_generator']['args'])

    measure_dir_names = { 'residential_simulation_controls' => 'ResidentialSimulationControls',
                          'simulation_output' => 'SimulationOutputReport',
                          'timeseries_csv_export' => 'TimeseriesCSVExport',
                          'server_directory_cleanup' => 'ServerDirectoryCleanup' }

    steps = []
    workflow_args.each do |measure_dir_name, arguments|
      if ['reporting_measures'].include?(measure_dir_name)
        workflow_args[measure_dir_name].each do |k|
          steps << { 'measure_dir_name' => k['measure_dir_name'] }
          if k.keys.include?('arguments')
            steps[-1]['arguments'] = k['arguments']
          end
        end
      elsif !['measures'].include?(measure_dir_name)
        steps << { 'measure_dir_name' => measure_dir_names[measure_dir_name],
                   'arguments' => arguments }
      end
    end

    steps.insert(1, { 'measure_dir_name' => 'BuildExistingModel',
                      'arguments' => {
                        'building_id' => 1,
                        'workflow_json' => 'measure-info.json'
                      } })

    if workflow_args.keys.include?('measures')
      workflow_args.each do |measure_dir_name, arguments|
        next unless ['measures'].include?(measure_dir_name)

        workflow_args[measure_dir_name].each_with_index do |k, i|
          step = { 'measure_dir_name' => k['measure_dir_name'] }
          if k.keys.include?('arguments')
            step['arguments'] = k['arguments']
          end
          steps.insert(2 + i, step)
        end
      end
    end

    if ['residential_quota_downselect'].include?(cfg['sampler']['type'])
      if cfg['sampler']['args']['resample']
        fail "Not supporting residential_quota_downselect's 'resample' at this time."
      end

      steps[1]['arguments']['downselect_logic'] = make_apply_logic_arg(cfg['sampler']['args']['logic'])
    end

    if upgrade_idx > 0
      measure_d = cfg['upgrades'][upgrade_idx - 1]
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
        next unless option.keys.include?('costs')

        option['costs'].each_with_index do |cost, cost_num|
          cost_num += 1
          ['value', 'multiplier'].each do |arg|
            next if !cost.include?(arg)

            apply_upgrade_measure['arguments']["option_#{opt_num}_cost_#{cost_num}_#{arg}"] = cost[arg]
          end
        end
      end
      if measure_d.keys.include?('package_apply_logic')
        apply_upgrade_measure['arguments']['package_apply_logic'] = make_apply_logic_arg(measure_d['package_apply_logic'])
      end

      steps.insert(2, apply_upgrade_measure)
    end

    osw = {
      'measure_paths': ['../../../measures'],
      'run_options': { 'skip_zip_results': true },
      'steps': steps
    }

    base, ext = File.basename(yml).split('.')

    osw_paths[upgrade_name] = File.join(thisdir, "#{base}-#{upgrade_name}.osw")
    File.open(osw_paths[upgrade_name], 'w') do |f|
      f.write(JSON.pretty_generate(osw))
    end
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
    Dir.mkdir(weather_dir)

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
    Zip::File.open(weather_files_path) do |zip_file|
      zip_file.each do |f|
        fpath = File.join(weather_dir, f.name)
        zip_file.extract(f, fpath) unless File.exist?(fpath)
      end
    end
  end

  # Create buildstock.csv
  outfile = File.join('..', 'lib', 'housing_characteristics', 'buildstock.csv')
  create_buildstock_csv(project_directory, n_datapoints, outfile)

  all_results_characteristics = []
  all_results_output = []
  osw_paths.each do |upgrade_name, osw_path|
    samples_osw(results_dir, osw_path, upgrade_name, n_datapoints, all_results_characteristics, all_results_output, measures_only)

    change_building_id(osw_path, 1)
  end

  results_csv_characteristics = RunOSWs.write_summary_results(results_dir, 'results_characteristics.csv', all_results_characteristics)
  results_csv_output = RunOSWs.write_summary_results(results_dir, 'results_output.csv', all_results_output)

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

def samples_osw(results_dir, osw_path, upgrade_name, num_samples, all_results_characteristics, all_results_output, measures_only)
  osw_dir = File.join(results_dir, 'osw')
  Dir.mkdir(osw_dir) unless File.exist?(osw_dir)

  scenario_dir = File.join(results_dir, 'osw', upgrade_name)
  Dir.mkdir(scenario_dir) unless File.exist?(scenario_dir)

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

    completed_status, result_characteristics, result_output = RunOSWs.run_and_check(osw, worker_dir, measures_only)

    osw = "#{building_id.to_s.rjust(4, '0')}-#{upgrade_name}.osw"

    result_characteristics['OSW'] = osw
    result_characteristics['completed_status'] = completed_status

    result_output['OSW'] = osw
    result_output['completed_status'] = completed_status

    all_results_characteristics << result_characteristics
    all_results_output << result_output

    run_dir = File.join(worker_dir, 'run')
    if File.exist?(File.join(run_dir, 'measures.osw'))
      FileUtils.mv(File.join(run_dir, 'measures.osw'), File.join(scenario_dir, "#{building_id}-measures.osw"))
    end
    if File.exist?(File.join(run_dir, 'measures-upgrade.osw'))
      FileUtils.mv(File.join(run_dir, 'measures-upgrade.osw'), File.join(scenario_dir, "#{building_id}-measures-upgrade.osw")) if File.exist?(File.join(run_dir, 'measures-upgrade.osw'))
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

def make_apply_logic_arg(logic)
  if logic.is_a?(Hash)
    key = logic.keys[0]
    val = logic[key]
    if key == 'and'
      return make_apply_logic_arg(val)
    elsif key == 'or'
      return "(#{val.map { |v| make_apply_logic_arg(v) }.join('||')})"
    elsif key == 'not'
      return "!#{make_apply_logic_arg(val)}"
    end
  elsif logic.is_a?(Array)
    return "(#{logic.map { |l| make_apply_logic_arg(l) }.join('&&')})"
  elsif logic.is_a?(String)
    return logic
  end
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

  opts.on_tail('-h', '--help', 'Display help') do
    puts opts
    exit!
  end
end.parse!

if options[:version]
  puts "#{Version.software_program_used} v#{Version.software_program_version}"
  exit!
end

if not options[:yml]
  fail "YML argument is required. Call #{File.basename(__FILE__)} -h for usage."
end

# Run analysis
puts "YML: #{options[:yml]}"
success = run_workflow(options[:yml], options[:measures_only])

if not success
  exit! 1
end

puts "Completed in #{(Time.now - start_time).round(1)}s."
