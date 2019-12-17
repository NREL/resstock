start_time = Time.now

require 'fileutils'
require 'optparse'
require 'pathname'
require_relative "meta_measure"

basedir = File.expand_path(File.dirname(__FILE__))

def rm_path(path)
  if Dir.exists?(path)
    FileUtils.rm_r(path)
  end
  while true
    break if not Dir.exists?(path)

    sleep(0.01)
  end
end

def create_idf(basedir, rundir, hpxml, debug, skip_validation)
  OpenStudio::Logger.instance.standardOutLogger.setLogLevel(OpenStudio::Fatal)

  model = OpenStudio::Model::Model.new
  runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
  measures_dir = File.join(basedir, "..", "..")

  measures = {}

  # Add HPXML translator measure to workflow
  measure_subdir = File.absolute_path(File.join(basedir, "..")).split('/')[-1]
  args = {}
  args['hpxml_path'] = hpxml
  args['weather_dir'] = "weather"
  args['epw_output_path'] = File.join(rundir, "in.epw")
  if debug
    args['osm_output_path'] = File.join(rundir, "in.osm")
  end
  args['skip_validation'] = skip_validation
  update_args_hash(measures, measure_subdir, args)

  # Apply measures
  success = apply_measures(measures_dir, measures, runner, model)

  # Report warnings/errors
  File.open(File.join(rundir, 'run.log'), 'w') do |f|
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

  if not success
    fail "Simulation unsuccessful."
  end

  # Translate model to IDF
  forward_translator = OpenStudio::EnergyPlus::ForwardTranslator.new
  forward_translator.setExcludeLCCObjects(true)
  model_idf = forward_translator.translateModel(model)

  # Report warnings/errors
  File.open(File.join(rundir, 'run.log'), 'a') do |f|
    forward_translator.warnings.each do |s|
      f << "FT Warning: #{s.logMessage}\n"
    end
    forward_translator.errors.each do |s|
      f << "FT Error: #{s.logMessage}\n"
    end
  end

  # Write IDF to file
  File.open(File.join(rundir, "in.idf"), 'w') { |f| f << model_idf.to_s }
end

def run_energyplus(rundir)
  # getEnergyPlusDirectory can be unreliable, using getOpenStudioCLI instead
  ep_path = File.absolute_path(File.join(OpenStudio.getOpenStudioCLI.to_s, '..', '..', 'EnergyPlus', 'energyplus'))
  command = "cd #{rundir} && #{ep_path} -w in.epw in.idf > stdout-energyplus"
  system(command, :err => File::NULL)
end

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: #{File.basename(__FILE__)} -x building.xml\n e.g., #{File.basename(__FILE__)} -s -x tests/base.xml\n"

  opts.on('-x', '--xml <FILE>', 'HPXML file') do |t|
    options[:hpxml] = t
  end

  opts.on('-o', '--output-dir <DIR>', 'Output directory') do |t|
    options[:output_dir] = t
  end

  options[:skip_validation] = false
  opts.on('-s', '--skip-validation', 'Skips HPXML validation') do |t|
    options[:skip_validation] = true
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

if not options[:hpxml]
  fail "HPXML argument is required. Call #{File.basename(__FILE__)} -h for usage."
end

unless (Pathname.new options[:hpxml]).absolute?
  options[:hpxml] = File.expand_path(options[:hpxml])
end
unless File.exists?(options[:hpxml]) and options[:hpxml].downcase.end_with? ".xml"
  fail "'#{options[:hpxml]}' does not exist or is not an .xml file."
end

if options[:output_dir].nil?
  options[:output_dir] = File.dirname(options[:hpxml]) # default
end
options[:output_dir] = File.expand_path(options[:output_dir])

unless Dir.exists?(options[:output_dir])
  FileUtils.mkdir_p(options[:output_dir])
end

# Create run dir
rundir = File.join(options[:output_dir], "run")
rm_path(rundir)
Dir.mkdir(rundir)

# Run design
puts "HPXML: #{options[:hpxml]}"
puts "Creating input..."
create_idf(basedir, rundir, options[:hpxml], options[:debug], options[:skip_validation])

puts "Running simulation..."
run_energyplus(rundir)

puts "Completed in #{(Time.now - start_time).round(1)} seconds."
