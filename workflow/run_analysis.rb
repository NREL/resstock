# frozen_string_literal: true

require 'yaml'
require 'json'
require_relative '../resources/buildstock.rb'

start_time = Time.now

def run_workflow(yml)
  cfg = YAML.load_file(yml)

  workflow_args = {
    'residential_simulation_controls' => {},
    'simulation_output' => {}
  }
  workflow_args.update(cfg['workflow_generator']['args'])

  measure_dir_names = { 'residential_simulation_controls' => 'ResidentialSimulationControls',
                        'simulation_output' => 'SimulationOutputReport' }

  steps = []
  workflow_args.each do |measure_dir_name, arguments|
    if measure_dir_name == 'reporting_measures'
      workflow_args[measure_dir_name].each do |k|
        steps << { 'measure_dir_name' => k['measure_dir_name'] }
      end
    elsif measure_dir_name == 'server_directory_cleanup'
      next
    else
      steps << { 'measure_dir_name' => measure_dir_names[measure_dir_name],
                 'arguments' => arguments }
    end
  end

  steps.insert(1, { 'measure_dir_name' => 'BuildExistingModel',
                    'arguments' => {
                      'building_id' => 1,
                      'workflow_json' => 'measure-info.json'
                    } })

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

    steps.insert(2, apply_upgrade_measure)
  end

  osw = {
    'measure_paths': ['../../../measures'],
    'steps': steps
  }

  thisdir = File.dirname(__FILE__)
  base, ext = File.basename(yml).split('.')

  osw_path = File.join(thisdir, "workflow-#{base}.osw")
  File.open(osw_path, 'w') do |f|
    f.write(JSON.pretty_generate(osw))
  end

  # TODO: share methods with test_samples.rb

  project_dir = { cfg['project_directory'] => 1 }

  top_dir = File.absolute_path(File.join(File.dirname(__FILE__), 'results'))
  lib_dir = File.join(top_dir, '..', '..', 'lib')
  resources_dir = File.join(top_dir, '..', '..', 'resources')
  weather_dir = create_weather_folder(top_dir, 'project_testing')
  outfile = File.join('..', 'lib', 'housing_characteristics', 'buildstock.csv')

  scenario_dir = File.join(top_dir, 'workflow')
  Dir.mkdir(scenario_dir) unless File.exist?(scenario_dir)

  all_results_characteristics = []
  all_results_output = []
  project_dir.each_with_index do |(project_dir, num_samples), color_index|
    next unless num_samples > 0

    samples_osw(scenario_dir, project_dir, num_samples, all_results_characteristics, all_results_output, color_index)
  end

  results_dir = File.join(scenario_dir, 'results')
  RunOSWs._rm_path(results_dir)
  results_csv_characteristics = RunOSWs.write_summary_results(results_dir, 'results_characteristics.csv', all_results_characteristics)
  results_csv_output = RunOSWs.write_summary_results(results_dir, 'results_output.csv', all_results_output)

  FileUtils.rm_rf(lib_dir) if File.exist?(@lib_dir)
  FileUtils.rm_rf(weather_dir) if File.exist?(@weather_dir)

  Dir["#{top_dir}/workflow*.osw"].each do |osw|
    TestResStockMeasuresOSW.change_building_id(osw, 1)
  end

  return true
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

  opts.on_tail('-h', '--help', 'Display help') do
    puts opts
    exit!
  end
end.parse!

if options[:version]
  puts "ResStock v#{version['__version__']}"
  exit!
end

if not options[:yml]
  fail "YML argument is required. Call #{File.basename(__FILE__)} -h for usage."
end

# Run analysis
puts "YML: #{options[:yml]}"
success = run_workflow(options[:yml])

if not success
  exit! 1
end

puts "Completed in #{(Time.now - start_time).round(1)}s."
