start_time = Time.now

require 'fileutils'
require 'optparse'
require 'pathname'
require 'openstudio'
require_relative '../HPXMLtoOpenStudio/resources/meta_measure'

basedir = File.expand_path(File.dirname(__FILE__))

def rm_path(path)
  if Dir.exist?(path)
    FileUtils.rm_r(path)
  end
  while true
    break if not Dir.exist?(path)

    sleep(0.01)
  end
end

def run_workflow(basedir, rundir, hpxml, debug, hourly_outputs)
  puts 'Creating input...'

  OpenStudio::Logger.instance.standardOutLogger.setLogLevel(OpenStudio::Fatal)

  model = OpenStudio::Model::Model.new
  runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
  measures_dir = File.join(basedir, '..')

  measures = {}

  # Add HPXML translator measure to workflow
  measure_subdir = 'HPXMLtoOpenStudio'
  args = {}
  args['hpxml_path'] = hpxml
  args['weather_dir'] = 'weather'
  args['epw_output_path'] = File.join(rundir, 'in.epw')
  if debug
    args['osm_output_path'] = File.join(rundir, 'in.osm')
  end
  update_args_hash(measures, measure_subdir, args)

  # Add reporting measure to workflow
  measure_subdir = 'SimulationOutputReport'
  args = {}
  args['timeseries_frequency'] = 'hourly'
  args['include_timeseries_zone_temperatures'] = hourly_outputs.include? 'temperatures'
  args['include_timeseries_fuel_consumptions'] = hourly_outputs.include? 'fuels'
  args['include_timeseries_end_use_consumptions'] = hourly_outputs.include? 'enduses'
  args['include_timeseries_total_loads'] = hourly_outputs.include? 'loads'
  args['include_timeseries_component_loads'] = hourly_outputs.include? 'componentloads'
  update_args_hash(measures, measure_subdir, args)

  # Apply measures
  success = apply_measures(measures_dir, measures, runner, model, true, 'OpenStudio::Measure::ModelMeasure')
  report_measure_errors_warnings(runner, rundir, debug)

  if not success
    fail 'Simulation unsuccessful.'
  end

  # Translate model to IDF
  forward_translator = OpenStudio::EnergyPlus::ForwardTranslator.new
  forward_translator.setExcludeLCCObjects(true)
  model_idf = forward_translator.translateModel(model)
  report_ft_errors_warnings(forward_translator, rundir)

  # Apply reporting measure output requests
  apply_energyplus_output_requests(measures_dir, measures, runner, model, model_idf)

  # Write IDF to file
  File.open(File.join(rundir, 'in.idf'), 'w') { |f| f << model_idf.to_s }

  puts 'Running simulation...'

  # getEnergyPlusDirectory can be unreliable, using getOpenStudioCLI instead
  ep_path = File.absolute_path(File.join(OpenStudio.getOpenStudioCLI.to_s, '..', '..', 'EnergyPlus', 'energyplus'))
  command = "cd \"#{rundir}\" && \"#{ep_path}\" -w in.epw in.idf > stdout-energyplus"
  system(command, err: File::NULL)

  puts 'Processing output...'

  # Apply reporting measures
  runner.setLastEnergyPlusSqlFilePath(File.join(rundir, 'eplusout.sql'))
  success = apply_measures(measures_dir, measures, runner, model, true, 'OpenStudio::Measure::ReportingMeasure')
  report_measure_errors_warnings(runner, rundir, debug)

  annual_csv_path = File.join(rundir, 'results_annual.csv')
  if File.exist? annual_csv_path
    puts "Wrote output file: #{annual_csv_path}."
  end

  timeseries_csv_path = File.join(rundir, 'results_timeseries.csv')
  if File.exist? timeseries_csv_path
    puts "Wrote output file: #{timeseries_csv_path}."
  end

  if not success
    fail 'Processing output unsuccessful.'
  end
end

def report_measure_errors_warnings(runner, designdir, debug)
  # Report warnings/errors
  File.open(File.join(designdir, 'run.log'), 'w') do |f|
    if debug
      runner.result.stepInfo.each do |s|
        f << "Info: #{s}\n"
      end
    end
    runner.result.stepWarnings.each do |s|
      f << "Warning: #{s}\n"
    end
    runner.result.stepErrors.each do |s|
      f << "Error: #{s}\n"
    end
  end
end

def report_ft_errors_warnings(forward_translator, designdir)
  # Report warnings/errors
  File.open(File.join(designdir, 'run.log'), 'a') do |f|
    forward_translator.warnings.each do |s|
      f << "FT Warning: #{s.logMessage}\n"
    end
    forward_translator.errors.each do |s|
      f << "FT Error: #{s.logMessage}\n"
    end
  end
end

hourly_types = ['ALL', 'fuels', 'enduses', 'loads', 'componentloads', 'temperatures']

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: #{File.basename(__FILE__)} -x building.xml\n e.g., #{File.basename(__FILE__)} -x base.xml\n"

  opts.on('-x', '--xml <FILE>', 'HPXML file') do |t|
    options[:hpxml] = t
  end

  opts.on('-o', '--output-dir <DIR>', 'Output directory') do |t|
    options[:output_dir] = t
  end

  options[:hourly_outputs] = []
  opts.on('--hourly TYPE', hourly_types, "Request hourly output type (#{hourly_types[0..3].join(', ')}", "#{hourly_types[4..-1].join(', ')}); can be called multiple times") do |t|
    options[:hourly_outputs] << t
  end

  options[:version] = false
  opts.on('-v', '--version', 'Reports the version') do |t|
    options[:version] = true
  end

  options[:debug] = false
  opts.on('-d', '--debug') do |t|
    options[:debug] = true
  end

  opts.on_tail('-h', '--help', 'Display help') do
    puts opts
    exit!
  end
end.parse!

if options[:version]
  workflow_version = '0.8.0'
  puts "OpenStudio-HPXML v#{workflow_version}"
  exit!
end

if options[:hourly_outputs].include? 'ALL'
  options[:hourly_outputs] = hourly_types[1..-1]
end

if not options[:hpxml]
  fail "HPXML argument is required. Call #{File.basename(__FILE__)} -h for usage."
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
rm_path(rundir)
Dir.mkdir(rundir)

# Run design
puts "HPXML: #{options[:hpxml]}"
run_workflow(basedir, rundir, options[:hpxml], options[:debug], options[:hourly_outputs])

puts "Completed in #{(Time.now - start_time).round(1)} seconds."
