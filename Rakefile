require 'bundler'
Bundler.setup

require 'rake'
require 'rake/clean'

CLEAN.include('*.pem', '*.pub', './projects/*.json', '*.json', 'faraday.log')

desc 'Copy measures/osms from OpenStudio-Beopt repo'
task :copy_beopt_files do
  require 'fileutils'

  beopt_measures_dir = File.join(File.dirname(__FILE__), "..", "OpenStudio-Beopt", "measures")
  resstock_measures_dir = File.join(File.dirname(__FILE__), "resources", "measures")
  if not Dir.exist?(beopt_measures_dir)
    puts "Cannot find OpenStudio-Beopt measures dir at #{beopt_measures_dir}."
  end
  
  empty_osm = "EmptySeedModel.osm"
  puts "Copying #{empty_osm}..."
  beopt_empty_seed_model = File.join(File.dirname(__FILE__), "..", "OpenStudio-Beopt", "geometries", empty_osm)
  resstock_empty_seed_model = File.join(File.dirname(__FILE__), "seeds", empty_osm)
  if File.exists?(resstock_empty_seed_model)
    FileUtils.rm(resstock_empty_seed_model)
  end
  FileUtils.cp(beopt_empty_seed_model, resstock_empty_seed_model)
  
  puts "Deleting #{resstock_measures_dir}..."
  while Dir.exist?(resstock_measures_dir)
    FileUtils.rm_rf("#{resstock_measures_dir}/.", secure: true)
    sleep 1
  end
  FileUtils.makedirs(resstock_measures_dir)
  
  Dir.foreach(beopt_measures_dir) do |item|
    next if item == '.' or item == '..'
    beopt_measure_dir = File.join(beopt_measures_dir, item)
    next if not Dir.exist?(beopt_measure_dir)
    puts "Copying #{item} measure..."
    FileUtils.cp_r(beopt_measure_dir, resstock_measures_dir)
    resstock_measure_test_dir = File.join(resstock_measures_dir, item, "tests")
    if Dir.exist?(resstock_measure_test_dir)
      FileUtils.rm_rf("#{resstock_measure_test_dir}/.", secure: true)
    end
    resstock_measure_cov_dir = File.join(resstock_measures_dir, item, "coverage")
    if Dir.exist?(resstock_measure_cov_dir)
      FileUtils.rm_rf("#{resstock_measure_cov_dir}/.", secure: true)
    end
  end
end

desc 'Perform integrity checking on inputs to look for problems'
task :integrity_check do
  # Load helper file
  resources_dir = File.join(File.dirname(__FILE__), 'resources')
  require File.join(resources_dir, 'helper_methods')
  
  # Load sampling file
  worker_initialize_dir = File.join(File.dirname(__FILE__), 'worker_initialize')
  require File.join(worker_initialize_dir, 'run_sampling')
    
  # Setup
  lookup_file = File.join(resources_dir, 'options_lookup.tsv')
  check_file_exists(lookup_file, nil)
  parameter_names = get_parameters_ordered_from_options_lookup_tsv(resources_dir)
  
  modes = ['national','pnw']
    
  modes.each do |mode|
    project_file = File.join("projects","resstock_#{mode}.xlsx")
    check_file_exists(project_file, nil)
      
    # Perform various checks on each probability distribution file
    parameters_processed = []
    option_names = {}
    tsvfiles = {}
    
    parameter_names.each do |parameter_name|
      tsvpath = File.join(resources_dir, "inputs", mode, "#{parameter_name}.tsv")
      next if not File.exist?(tsvpath) # Not every parameter used by every mode
      
      puts "Checking for issues with #{mode}/#{parameter_name}..."
      check_file_exists(tsvpath, nil)
      tsvfile = TsvFile.new(tsvpath, nil)
      tsvfiles[parameter_name] = tsvfile
      
      # Check all dependencies have already been processed
      tsvfile.dependency_cols.keys.each do |dep|
        next if parameters_processed.include?(dep)
        puts "ERROR: #{File.basename(tsvpath)} has a dependency '#{dep}' that was not found."
        exit
      end
      parameters_processed << parameter_name
      
      # Test all possible combinations of dependency value combinations
      combo_hashes = get_combination_hashes(tsvfiles, tsvfile.dependency_cols.keys)
      combo_hashes.each do |combo_hash|
        _matched_option_name, matched_row_num = tsvfile.get_option_name_from_sample_number(1.0, combo_hash)
      end
      
      # Integrity checks for option_lookup.txt
      measure_args_from_xml = {}
      tsvfiles[parameter_name].option_cols.keys.each do |option_name|
        # Check for (parameter, option) names
        measure_args = get_measure_args_from_option_name(lookup_file, option_name, parameter_name, nil)
        # Check that measures exist and all measure arguments are provided
        measure_args.keys.each do |measure_subdir|
          if not measure_args_from_xml.keys.include?(measure_subdir)
            measurerb_path = File.absolute_path(File.join(File.dirname(lookup_file), 'measures', measure_subdir, 'measure.rb'))
            check_file_exists(measurerb_path, nil)
            measure_args_from_xml[measure_subdir] = get_measure_args_from_xml(measurerb_path.sub('.rb','.xml'))
          end
          validate_measure_args(measure_args_from_xml[measure_subdir], measure_args[measure_subdir].keys, lookup_file, parameter_name, option_name, nil)
        end
      end
      
    end # parameter_name
    
    # Test sampling
    r = RunSampling.new
    output_file = r.run(mode, 1000)
    if File.exist?(output_file)
      File.delete(output_file) # Clean up
    end
    
  end # mode
  
end # rake task
