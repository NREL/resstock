# frozen_string_literal: true

start_time = Time.now

require 'fileutils'
require 'optparse'
require 'pathname'
require_relative '../HPXMLtoOpenStudio/resources/constants'
require_relative '../HPXMLtoOpenStudio/resources/meta_measure'
require_relative '../HPXMLtoOpenStudio/resources/version'

basedir = File.expand_path(File.dirname(__FILE__))

def run_workflow(basedir, rundir, hpxml, debug, timeseries_output_freq, timeseries_outputs, skip_validation, add_comp_loads,
                 output_format, building_id, ep_input_format, stochastic_schedules,
                 timeseries_output_variables)
  measures_dir = File.join(basedir, '..')

  measures = {}

  # Optionally add schedule file measure to workflow
  if stochastic_schedules
    measure_subdir = 'BuildResidentialScheduleFile'
    args = {}
    args['hpxml_path'] = hpxml
    args['hpxml_output_path'] = hpxml
    args['output_csv_path'] = File.join(rundir, 'stochastic.csv')
    args['debug'] = debug
    args['building_id'] = building_id
    update_args_hash(measures, measure_subdir, args)
  end

  # Add HPXML translator measure to workflow
  measure_subdir = 'HPXMLtoOpenStudio'
  args = {}
  args['hpxml_path'] = hpxml
  args['output_dir'] = rundir
  args['debug'] = debug
  args['add_component_loads'] = (add_comp_loads || timeseries_outputs.include?('componentloads'))
  args['skip_validation'] = skip_validation
  args['building_id'] = building_id
  update_args_hash(measures, measure_subdir, args)

  # Add reporting measure to workflow
  measure_subdir = 'ReportSimulationOutput'
  args = {}
  args['output_format'] = output_format
  args['timeseries_frequency'] = timeseries_output_freq
  args['include_timeseries_total_consumptions'] = timeseries_outputs.include? 'total'
  args['include_timeseries_fuel_consumptions'] = timeseries_outputs.include? 'fuels'
  args['include_timeseries_end_use_consumptions'] = timeseries_outputs.include? 'enduses'
  args['include_timeseries_system_use_consumptions'] = timeseries_outputs.include? 'systemuses'
  args['include_timeseries_emissions'] = timeseries_outputs.include? 'emissions'
  args['include_timeseries_emission_fuels'] = timeseries_outputs.include? 'emissionfuels'
  args['include_timeseries_emission_end_uses'] = timeseries_outputs.include? 'emissionenduses'
  args['include_timeseries_hot_water_uses'] = timeseries_outputs.include? 'hotwater'
  args['include_timeseries_total_loads'] = timeseries_outputs.include? 'loads'
  args['include_timeseries_component_loads'] = timeseries_outputs.include? 'componentloads'
  args['include_timeseries_unmet_hours'] = timeseries_outputs.include? 'unmethours'
  args['include_timeseries_zone_temperatures'] = timeseries_outputs.include? 'temperatures'
  args['include_timeseries_airflows'] = timeseries_outputs.include? 'airflows'
  args['include_timeseries_weather'] = timeseries_outputs.include? 'weather'
  args['include_timeseries_resilience'] = timeseries_outputs.include? 'resilience'
  args['user_output_variables'] = timeseries_output_variables.join(', ') unless timeseries_output_variables.empty?
  update_args_hash(measures, measure_subdir, args)

  output_format = 'csv' if output_format == 'csv_dview'

  # Add utility bills measure to workflow
  measure_subdir = 'ReportUtilityBills'
  args = {}
  args['output_format'] = output_format
  update_args_hash(measures, measure_subdir, args)

  results = run_hpxml_workflow(rundir, measures, measures_dir, debug: debug, ep_input_format: ep_input_format)

  return results[:success]
end

timeseries_types = ['ALL', 'total', 'fuels', 'enduses', 'systemuses', 'emissions', 'emissionfuels',
                    'emissionenduses', 'hotwater', 'loads', 'componentloads',
                    'unmethours', 'temperatures', 'airflows', 'weather', 'resilience']

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: #{File.basename(__FILE__)} -x building.xml"

  opts.on('-x', '--xml <FILE>', 'HPXML file') do |t|
    options[:hpxml] = t
  end

  opts.on('-o', '--output-dir <DIR>', 'Output directory') do |t|
    options[:output_dir] = t
  end

  opts.on('--output-format TYPE', ['csv', 'json', 'msgpack', 'csv_dview'], 'Output file format type (csv, json, msgpack, csv_dview)') do |t|
    options[:output_format] = t
  end

  options[:hourly_outputs] = []
  opts.on('--hourly TYPE', timeseries_types, "Request hourly output type (#{timeseries_types.join(', ')}); can be called multiple times") do |t|
    options[:hourly_outputs] << t
  end

  options[:daily_outputs] = []
  opts.on('--daily TYPE', timeseries_types, "Request daily output type (#{timeseries_types.join(', ')}); can be called multiple times") do |t|
    options[:daily_outputs] << t
  end

  options[:monthly_outputs] = []
  opts.on('--monthly TYPE', timeseries_types, "Request monthly output type (#{timeseries_types.join(', ')}); can be called multiple times") do |t|
    options[:monthly_outputs] << t
  end

  options[:timestep_outputs] = []
  opts.on('--timestep TYPE', timeseries_types, "Request timestep output type (#{timeseries_types.join(', ')}); can be called multiple times") do |t|
    options[:timestep_outputs] << t
  end

  options[:skip_validation] = false
  opts.on('-s', '--skip-validation', 'Skip Schema/Schematron validation for faster performance') do |_t|
    options[:skip_validation] = true
  end

  options[:add_comp_loads] = false
  opts.on('--add-component-loads', 'Add heating/cooling component loads calculation') do |_t|
    options[:add_comp_loads] = true
  end

  options[:stochastic_schedules] = false
  opts.on('--add-stochastic-schedules', 'Add detailed stochastic occupancy schedules') do |_t|
    options[:stochastic_schedules] = true
  end

  options[:timeseries_output_variables] = []
  opts.on('-t', '--add-timeseries-output-variable NAME', 'Add timeseries output variable; can be called multiple times') do |t|
    options[:timeseries_output_variables] << t
  end

  options[:ep_input_format] = 'idf'
  opts.on('--ep-input-format TYPE', 'EnergyPlus input file format (idf, epjson)') do |t|
    options[:ep_input_format] = t
  end

  opts.on('-b', '--building-id ID', 'ID of Building to simulate (required if the HPXML has multiple Building elements and WholeSFAorMFBuildingSimulation is not true)') do |t|
    options[:building_id] = t
  end

  options[:version] = false
  opts.on('-v', '--version', 'Reports the version') do |_t|
    options[:version] = true
  end

  options[:debug] = false
  opts.on('-d', '--debug', 'Generate additional debug output/files') do |_t|
    options[:debug] = true
  end

  opts.on_tail('-h', '--help', 'Display help') do
    puts opts
    exit!
  end
end.parse!

if options[:version]
  puts "OpenStudio-HPXML v#{Version::OS_HPXML_Version}"
  puts "OpenStudio v#{OpenStudio.openStudioLongVersion}"
  puts "EnergyPlus v#{OpenStudio.energyPlusVersion}.#{OpenStudio.energyPlusBuildSHA}"
else
  if not options[:hpxml]
    fail "HPXML argument is required. Call #{File.basename(__FILE__)} -h for usage."
  end

  timeseries_output_freq = 'none'
  timeseries_outputs = []
  n_freq = 0
  if not options[:hourly_outputs].empty?
    n_freq += 1
    timeseries_output_freq = 'hourly'
    timeseries_outputs = options[:hourly_outputs]
  end
  if not options[:daily_outputs].empty?
    n_freq += 1
    timeseries_output_freq = 'daily'
    timeseries_outputs = options[:daily_outputs]
  end
  if not options[:monthly_outputs].empty?
    n_freq += 1
    timeseries_output_freq = 'monthly'
    timeseries_outputs = options[:monthly_outputs]
  end
  if not options[:timestep_outputs].empty?
    n_freq += 1
    timeseries_output_freq = 'timestep'
    timeseries_outputs = options[:timestep_outputs]
  end

  if not options[:timeseries_output_variables].empty?
    timeseries_output_freq = 'timestep' if timeseries_output_freq == 'none'
  end

  if n_freq > 1
    fail 'Multiple timeseries frequencies (hourly, daily, monthly, timestep) are not supported.'
  end

  if timeseries_outputs.include? 'ALL'
    timeseries_outputs = timeseries_types[1..-1]
  end

  unless (Pathname.new options[:hpxml]).absolute?
    options[:hpxml] = File.expand_path(options[:hpxml])
  end
  unless File.exist?(options[:hpxml]) && options[:hpxml].downcase.end_with?('.xml')
    fail "'#{options[:hpxml]}' does not exist or is not an .xml file."
  end

  if options[:output_dir].nil?
    options[:output_dir] = File.dirname(options[:hpxml]) # default
  end
  options[:output_dir] = File.expand_path(options[:output_dir])

  unless Dir.exist?(options[:output_dir])
    FileUtils.mkdir_p(options[:output_dir])
  end

  # Create run dir
  rundir = File.join(options[:output_dir], 'run')

  # Run design
  puts "HPXML: #{options[:hpxml]}"
  if not options[:building_id].nil?
    puts "BuildingID: #{options[:building_id]}"
  end
  success = run_workflow(basedir, rundir, options[:hpxml], options[:debug], timeseries_output_freq, timeseries_outputs,
                         options[:skip_validation], options[:add_comp_loads], options[:output_format], options[:building_id],
                         options[:ep_input_format], options[:stochastic_schedules], options[:timeseries_output_variables])

  if not success
    exit! 1
  end

  puts "Completed in #{(Time.now - start_time).round(1)}s."
end
