# frozen_string_literal: true

require 'parallel'
require 'json'
require 'yaml'
require 'zip'

require_relative '../resources/buildstock'
require_relative '../resources/run_sampling'
require_relative '../resources/util'

$start_time = Time.now

def run_workflow(yml, n_threads, measures_only, debug, building_ids, keep_run_folders, samplingonly)
  fail "YML file does not exist at '#{yml}'." if !File.exist?(yml)

  cfg = YAML.load_file(yml)

  if !cfg['workflow_generator']['args'].keys.include?('build_existing_model') || !cfg['workflow_generator']['args'].keys.include?('simulation_output_report')
    fail "Both 'build_existing_model' and 'simulation_output_report' must be included in yml."
  end

  if !['residential_quota', 'residential_quota_downselect', 'precomputed'].include?(cfg['sampler']['type'])
    fail "Sampler type '#{cfg['sampler']['type']}' is invalid or not supported."
  end

  if cfg['sampler']['type'] == 'residential_quota_downselect' && cfg['sampler']['args']['resample']
    fail "Not supporting residential_quota_downselect's 'resample' at this time."
  end

  thisdir = File.dirname(__FILE__)

  buildstock_directory = cfg['buildstock_directory']
  project_directory = cfg['project_directory']
  output_directory = cfg['output_directory']
  n_datapoints = cfg['sampler']['args']['n_datapoints']

  if !(Pathname.new buildstock_directory).absolute?
    buildstock_directory = File.absolute_path(File.join(File.dirname(yml), buildstock_directory))
  end

  if (Pathname.new output_directory).absolute?
    results_dir = output_directory
  else
    results_dir = File.absolute_path(output_directory)
  end
  fail "Output directory '#{output_directory}' already exists." if File.exist?(results_dir)

  Dir.mkdir(results_dir)

  osw_dir = File.join(results_dir, 'osw')
  Dir.mkdir(osw_dir)

  xml_dir = File.join(results_dir, 'xml')
  Dir.mkdir(xml_dir)

  upgrade_names = ['Baseline']
  if cfg.keys.include?('upgrades')
    cfg['upgrades'].each do |upgrade|
      upgrade_names << upgrade['upgrade_name'].gsub(' ', '')
    end
  end

  osw_paths = {}
  upgrade_names.each_with_index do |upgrade_name, upgrade_idx|
    scenario_osw_dir = File.join(results_dir, 'osw', upgrade_name)
    Dir.mkdir(scenario_osw_dir)

    scenario_xml_dir = File.join(results_dir, 'xml', upgrade_name)
    Dir.mkdir(scenario_xml_dir)

    workflow_args = {}
    workflow_args.update(cfg['workflow_generator']['args'])

    measure_dir_names = { 'build_existing_model' => 'BuildExistingModel',
                          'simulation_output_report' => 'ReportSimulationOutput',
                          'server_directory_cleanup' => 'ServerDirectoryCleanup' }

    steps = []
    measure_dir_names.each do |k, v|
      workflow_args.each do |measure_dir_name, arguments|
        next if k != measure_dir_name

        if measure_dir_name == 'build_existing_model'
          arguments['building_id'] = 1

          if workflow_args.keys.include?('emissions')
            arguments['emissions_scenario_names'] = workflow_args['emissions'].collect { |s| s['scenario_name'] }.join(',')
            arguments['emissions_types'] = workflow_args['emissions'].collect { |s| s['type'] }.join(',')
            arguments['emissions_electricity_folders'] = workflow_args['emissions'].collect { |s| s['elec_folder'] }.join(',')
            arguments['emissions_natural_gas_values'] = workflow_args['emissions'].collect { |s| s['gas_value'] }.join(',')
            arguments['emissions_propane_values'] = workflow_args['emissions'].collect { |s| s['propane_value'] }.join(',')
            arguments['emissions_fuel_oil_values'] = workflow_args['emissions'].collect { |s| s['oil_value'] }.join(',')
            arguments['emissions_wood_values'] = workflow_args['emissions'].collect { |s| s['wood_value'] }.join(',')
          end
        elsif measure_dir_name == 'simulation_output_report'
          arguments['include_timeseries_end_use_consumptions'] = true if !arguments.keys.include?('include_timeseries_end_use_consumptions')
          arguments['include_timeseries_total_loads'] = true if !arguments.keys.include?('include_timeseries_total_loads')
          arguments['add_timeseries_dst_column'] = true if !arguments.keys.include?('add_timeseries_dst_column')
          arguments['add_timeseries_utc_column'] = true if !arguments.keys.include?('add_timeseries_utc_column')

          arguments['user_output_variables'] = arguments['output_variables'].collect { |o| o['name'] }.join(',') if arguments.keys.include?('output_variables')
        elsif measure_dir_name == 'server_directory_cleanup'
          arguments['retain_in_idf'] = true if !arguments.keys.include?('retain_in_idf')
          arguments['retain_schedules_csv'] = true if !arguments.keys.include?('retain_schedules_csv')
        end

        steps << { 'measure_dir_name' => measure_dir_names[measure_dir_name],
                   'arguments' => arguments }
      end
    end

    workflow_args['simulation_output_report'].delete('output_variables')

    if cfg['sampler']['type'] == 'residential_quota_downselect'
      workflow_args['build_existing_model']['downselect_logic'] = make_apply_logic_arg(cfg['sampler']['args']['logic'])
    end

    step_idx = 1
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
          apply_upgrade_measure['arguments']["option_#{opt_num}_apply_logic"] = make_apply_logic_arg(option['apply_logic'])
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

      steps.insert(step_idx, apply_upgrade_measure)
      step_idx += 1
    end

    workflow_args.each do |measure_dir_name, arguments|
      next unless ['measures'].include?(measure_dir_name)

      workflow_args[measure_dir_name].each do |k|
        step = { 'measure_dir_name' => k['measure_dir_name'] }
        if k.keys.include?('arguments')
          step['arguments'] = k['arguments']
        end
        steps.insert(step_idx, step)
        step_idx += 1
      end
    end

    step_idx += 1 # for ReportSimulationOutput
    steps.insert(step_idx, { 'measure_dir_name' => 'ReportHPXMLOutput',
                             'arguments' => {
                               'output_format' => 'csv',
                             } })
    step_idx += 1

    steps.insert(step_idx, { 'measure_dir_name' => 'UpgradeCosts' })

    workflow_args.each do |measure_dir_name, arguments|
      next unless ['reporting_measures'].include?(measure_dir_name)

      workflow_args[measure_dir_name].each do |k|
        step = { 'measure_dir_name' => k['measure_dir_name'] }
        if k.keys.include?('arguments')
          step['arguments'] = k['arguments']
        end
        steps.insert(-2, step)
      end
    end

    measure_paths = [
      File.absolute_path(File.join(File.dirname(__FILE__), '../measures')),
      File.absolute_path(File.join(File.dirname(__FILE__), '../resources/hpxml-measures'))
    ]

    osw = {
      'measure_paths': measure_paths,
      'run_options': { 'skip_zip_results': true },
      'steps': steps
    }

    base, ext = File.basename(yml).split('.')

    osw_paths[upgrade_name] = File.join(results_dir, "#{base}-#{upgrade_name}.osw")
    File.open(osw_paths[upgrade_name], 'w') do |f|
      f.write(JSON.pretty_generate(osw))
    end
  end

  # Create lib folder
  lib_dir = File.join(thisdir, '../lib')
  resources_dir = File.join(thisdir, '../resources')
  housing_characteristics_dir = File.join(buildstock_directory, project_directory, 'housing_characteristics')
  create_lib_folder(lib_dir, resources_dir, housing_characteristics_dir)

  # Create weather folder
  weather_dir = File.join(thisdir, '../weather')
  if !File.exist?(weather_dir)
    if cfg.keys.include?('weather_files_url')
      Dir.mkdir(weather_dir)

      require 'tempfile'
      tmpfile = Tempfile.new('epw')

      weather_files_url = cfg['weather_files_url']
      UrlResolver.fetch(weather_files_url, tmpfile)

      weather_files_path = tmpfile.path.to_s
    elsif cfg.keys.include?('weather_files_path')
      Dir.mkdir(weather_dir)

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

  # Create or read buildstock.csv
  outfile = File.join('../lib/housing_characteristics/buildstock.csv')
  if !['precomputed'].include?(cfg['sampler']['type'])
    create_buildstock_csv(project_directory, n_datapoints, outfile)
    src = File.expand_path(File.join(File.dirname(__FILE__), '../lib/housing_characteristics/buildstock.csv'))
    des = results_dir
    FileUtils.cp(src, des)

    return if samplingonly

    datapoints = (1..n_datapoints).to_a
  else
    src = File.expand_path(File.join(File.dirname(yml), cfg['sampler']['args']['sample_file']))
    des = File.expand_path(File.join(File.dirname(__FILE__), outfile))
    FileUtils.cp(src, des)

    buildstock_csv = CSV.read(des, headers: true)
    datapoints = buildstock_csv['Building']
  end

  building_ids = datapoints if building_ids.empty?

  workflow_and_building_ids = []
  osw_paths.each do |upgrade_name, osw_path|
    datapoints.each do |building_id|
      next if !building_ids.include?(building_id)

      workflow_and_building_ids << [upgrade_name, osw_path, building_id]
    end
  end

  all_results_output = {}
  all_cli_output = []

  Parallel.map(workflow_and_building_ids, in_threads: n_threads) do |upgrade_name, workflow, building_id|
    if keep_run_folders
      job_id = workflow_and_building_ids.index([upgrade_name, workflow, building_id]) + 1
    else
      job_id = Parallel.worker_number + 1
    end

    all_results_output[upgrade_name] = [] if !all_results_output.keys.include?(upgrade_name)
    samples_osw(results_dir, upgrade_name, workflow, building_id, job_id, all_results_output, all_cli_output, measures_only, debug)

    info = "[Parallel(n_jobs=#{n_threads})]: "
    max_size = "#{workflow_and_building_ids.size}".size
    info += "%#{max_size}s" % "#{all_results_output.values.flatten.size}"
    info += " / #{workflow_and_building_ids.size}"
    info += ' | elapsed: '
    info += '%8s' % "#{get_elapsed_time(Time.now, $start_time)}"
    puts info
  end

  puts
  failures = []
  all_results_output.each do |upgrade_name, results_output|
    RunOSWs.write_summary_results(results_dir, "results-#{upgrade_name}.csv", results_output)

    results_output.each do |results|
      failures << results['building_id'] if results['completed_status'] == 'Fail'
    end
  end
  puts "\nFailures detected for: #{failures.uniq.sort.join(', ')}.\nSee #{File.join(results_dir, 'cli_output.log')}." if !failures.empty?

  File.open(File.join(results_dir, 'cli_output.log'), 'a') do |f|
    all_cli_output.each do |cli_output|
      f.puts(cli_output)
      f.puts
    end
  end

  FileUtils.rm_rf(lib_dir)

  return true
end

def create_lib_folder(lib_dir, resources_dir, housing_characteristics_dir)
  FileUtils.rm_rf(lib_dir)
  Dir.mkdir(lib_dir)
  FileUtils.cp_r(resources_dir, lib_dir)
  FileUtils.cp_r(housing_characteristics_dir, lib_dir)
end

def create_buildstock_csv(project_dir, num_samples, outfile)
  r = RunSampling.new
  r.run(project_dir, num_samples, outfile)
  puts "Sampling took: #{get_elapsed_time(Time.now, $start_time)}."
end

def get_elapsed_time(t1, t0)
  s = t1 - t0
  if s > 60 # min
    t = "#{(s / 60).round(1)}min"
  elsif s > 3600 # hr
    t = "#{(s / 3600).round(1)}hr"
  else # sec
    t = "#{s.round(1)}s"
  end
  return t
end

def samples_osw(results_dir, upgrade_name, workflow, building_id, job_id, all_results_output, all_cli_output, measures_only, debug)
  scenario_osw_dir = File.join(results_dir, 'osw', upgrade_name)

  scenario_xml_dir = File.join(results_dir, 'xml', upgrade_name)

  osw_basename = File.basename(workflow)

  worker_folder = "run#{job_id}"
  worker_dir = File.join(results_dir, worker_folder)
  FileUtils.rm_rf(worker_dir)
  Dir.mkdir(worker_dir)
  FileUtils.cp(workflow, worker_dir)
  osw = File.join(worker_dir, File.basename(workflow))

  change_building_id(osw, building_id)

  cli_output = "Building ID: #{building_id}. Upgrade Name: #{upgrade_name}. Job ID: #{job_id}.\n"
  upgrade = upgrade_name != 'Baseline'
  completed_status, result_output, cli_output = RunOSWs.run_and_check(osw, worker_dir, cli_output, upgrade, measures_only)

  osw = "#{building_id.to_s.rjust(4, '0')}-#{upgrade_name}.osw"

  result_output['OSW'] = osw
  result_output['building_id'] = building_id
  result_output['job_id'] = job_id
  result_output['completed_status'] = completed_status

  all_results_output[upgrade_name] << result_output
  all_cli_output << cli_output

  run_dir = File.join(worker_dir, 'run')
  if debug
    FileUtils.cp(File.join(run_dir, 'in.xml'), File.join(scenario_xml_dir, "#{building_id}-existing-defaulted.xml")) if File.exist?(File.join(run_dir, 'in.xml')) && !File.exist?(File.join(run_dir, 'upgraded.xml'))
    FileUtils.cp(File.join(run_dir, 'in.xml'), File.join(scenario_xml_dir, "#{building_id}-upgraded-defaulted.xml")) if File.exist?(File.join(run_dir, 'in.xml')) && File.exist?(File.join(run_dir, 'upgraded.xml'))
    FileUtils.cp(File.join(run_dir, 'existing.xml'), File.join(scenario_xml_dir, "#{building_id}-existing.xml")) if File.exist?(File.join(run_dir, 'existing.xml'))
    FileUtils.cp(File.join(run_dir, 'upgraded.xml'), File.join(scenario_xml_dir, "#{building_id}-upgraded.xml")) if File.exist?(File.join(run_dir, 'upgraded.xml'))
    FileUtils.cp(File.join(run_dir, 'existing.osw'), File.join(scenario_osw_dir, "#{building_id}-existing.osw")) if File.exist?(File.join(run_dir, 'existing.osw'))
    FileUtils.cp(File.join(run_dir, 'upgraded.osw'), File.join(scenario_osw_dir, "#{building_id}-upgraded.osw")) if File.exist?(File.join(run_dir, 'upgraded.osw'))
  else
    FileUtils.cp(File.join(run_dir, 'in.xml'), File.join(scenario_xml_dir, "#{building_id}.xml")) if File.exist?(File.join(run_dir, 'in.xml'))
    FileUtils.cp(File.join(run_dir, 'existing.osw'), File.join(scenario_osw_dir, "#{building_id}.osw")) if File.exist?(File.join(run_dir, 'existing.osw')) && !File.exist?(File.join(run_dir, 'upgraded.osw'))
    FileUtils.cp(File.join(run_dir, 'upgraded.osw'), File.join(scenario_osw_dir, "#{building_id}.osw")) if File.exist?(File.join(run_dir, 'upgraded.osw'))
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

  options[:threads] = Parallel.processor_count
  opts.on('-n', '--threads N', Integer, 'Number of parallel simulations (defaults to processor count)') do |t|
    options[:threads] = t
  end

  options[:measures_only] = false
  opts.on('-m', '--measures_only', 'Only run the OpenStudio and EnergyPlus measures') do |t|
    options[:measures_only] = true
  end

  options[:debug] = false
  opts.on('-d', '--debug', 'Save both existing and upgraded xml/osw files') do |t|
    options[:debug] = true
  end

  options[:building_ids] = []
  opts.on('-i', '--building_id ID', Integer, 'Only run this building ID; can be called multiple times') do |t|
    options[:building_ids] << t
  end

  options[:keep_run_folders] = false
  opts.on('-k', '--keep_run_folders', 'Preserve run folder for all datapoints') do |t|
    options[:keep_run_folders] = true
  end

  options[:samplingonly] = false
  opts.on('-s', '--samplingonly', 'Run the sampling only') do |t|
    options[:samplingonly] = true
  end

  opts.on_tail('-h', '--help', 'Display help') do
    puts opts
    exit!
  end

  options[:version] = false
  opts.on_tail('-v', '--version', 'Display version') do
    options[:version] = true
    puts "#{Version.software_program_used} v#{Version.software_program_version}"
  end
end.parse!

if not options[:version]
  if not options[:yml]
    fail "YML argument is required. Call #{File.basename(__FILE__)} -h for usage."
  end

  # Run analysis
  puts "YML: #{options[:yml]}"
  success = run_workflow(options[:yml], options[:threads], options[:measures_only], options[:debug],
                         options[:building_ids], options[:keep_run_folders], options[:samplingonly])

  if not success
    exit! 1
  end

  puts "\nCompleted in #{get_elapsed_time(Time.now, $start_time)}."
end
