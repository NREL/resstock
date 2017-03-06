require 'bundler'
Bundler.setup

require 'rake'
require 'rake/clean'

CLEAN.include('*.pem', '*.pub', './projects/*.json', '*.json', 'faraday.log')

desc 'Copy measures/osms from OpenStudio-BEopt repo'
task :copy_beopt_files do
  require 'fileutils'

  beopt_measures_dir = File.join(File.dirname(__FILE__), "..", "OpenStudio-BEopt", "measures")
  resstock_measures_dir = File.join(File.dirname(__FILE__), "resources", "measures")
  if not Dir.exist?(beopt_measures_dir)
    puts "Cannot find OpenStudio-BEopt measures dir at #{beopt_measures_dir}."
  end
  
  extra_files = [
                 File.join("seeds", "EmptySeedModel.osm"),
                 File.join("resources", "geometry.rb"), # Needed by SimulationOutputReport
                 File.join("resources", "constants.rb") # Needed by geometry.rb
                ]
  extra_files.each do |extra_file|
      puts "Copying #{extra_file}..."
      beopt_file = File.join(File.dirname(__FILE__), "..", "OpenStudio-BEopt", extra_file)
      resstock_file = File.join(File.dirname(__FILE__), extra_file)
      if File.exists?(resstock_file)
        FileUtils.rm(resstock_file)
      end
      FileUtils.cp(beopt_file, resstock_file)
  end
  
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

desc 'Perform integrity check on inputs for all modes'
task :integrity_check do
    integrity_check()
end # rake task

desc 'Perform integrity check on inputs for National mode'
task :integrity_check_national do
    integrity_check(['national'])
end # rake task

desc 'Perform integrity check on inputs for PNW mode'
task :integrity_check_pnw do
    integrity_check(['pnw'])
end # rake task

desc 'Perform integrity check on inputs for Testing mode'
task :integrity_check_testing do
    integrity_check(['testing'])
end # rake task

def integrity_check(modes=['national','pnw','testing'])
  require 'openstudio'

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
  model = OpenStudio::Model::Model.new
  measure_instances = {}
  
  modes.each do |mode|
    project_file = File.join("projects","resstock_#{mode}.xlsx")
    check_file_exists(project_file, nil)
      
    # Perform various checks on each probability distribution file
    parameters_processed = []
    option_names = {}
    tsvfiles = {}
    measures = {}
    epw_files = []
    
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
      
      # Integrity checks for option_lookup.tsv
      tsvfiles[parameter_name].option_cols.keys.each do |option_name|
        # Check for (parameter, option) names
        # Get measure name and arguments associated with the option
        get_measure_args_from_option_name(lookup_file, option_name, parameter_name, nil).each do |measure_subdir, args_hash|
            if not measures.has_key?(measure_subdir)
                measures[measure_subdir] = {}
            end
            if not measures[measure_subdir].has_key?(parameter_name)
                measures[measure_subdir][parameter_name] = {}
            end
            
            # Skip options with duplicate argument values as a previous option; speeds up processing.
            duplicate_args = false
            measures[measure_subdir][parameter_name].keys.each do |opt_name|
                if measures[measure_subdir][parameter_name][opt_name].to_s == args_hash.to_s
                    duplicate_args = true
                    break
                end
            end
            next if duplicate_args
            
            # Store arguments
            measures[measure_subdir][parameter_name][option_name] = args_hash
            
            # Store any EPW files referenced
            args_hash.each do |k, v|
                if not v.nil? and v.downcase.end_with?(".epw") and !epw_files.include?(v)
                    epw_files << v
                end
            end
        end
      end
      
    end # parameter_name
    
    # Check referenced EPW files exist
    epw_files.each do |epw_file|
        epw_file_full = File.join(File.dirname(__FILE__), 'weather', mode, epw_file)
        if not File.exists?(epw_file_full)
            puts "ERROR: Cannot find EPW file at #{epw_file_full}."
            exit
        end
    end
    
    # Additional integrity checks for option_lookup.tsv
    measures.keys.each do |measure_subdir|
      puts "Checking for issues with #{measure_subdir} measure..."
      # Check that measures exist
      if not measure_instances.keys.include?(measure_subdir)
        measurerb_path = File.absolute_path(File.join(File.dirname(lookup_file), 'measures', measure_subdir, 'measure.rb'))
        check_file_exists(measurerb_path, nil)
        measure_instances[measure_subdir] = get_measure_instance(measurerb_path)
      end
      # Validate measure arguments for each combination of options
      param_names = measures[measure_subdir].keys()
      options_array = []
      param_names.each do |parameter_name|
        options_array << measures[measure_subdir][parameter_name].keys()
      end
      option_combinations = options_array.first.product(*options_array[1..-1])
      all_measure_args = []
      option_combinations.each do |option_combination|
        measure_args = {}
        option_combination.each_with_index do |option_name, idx|
            measures[measure_subdir][param_names[idx]][option_name].each do |k,v|
                measure_args[k] = v
            end
        end
        next if all_measure_args.include?(measure_args)
        all_measure_args << measure_args
      end
      all_measure_args.each do |measure_args|
          validate_measure_args(measure_instances[measure_subdir].arguments(model), measure_args, lookup_file, measure_subdir, nil)
      end
    end
    
    # Test sampling
    r = RunSampling.new
    output_file = r.run(mode, 1000)
    if File.exist?(output_file)
      File.delete(output_file) # Clean up
    end
    
  end # mode
end