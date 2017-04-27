require 'bundler'
Bundler.setup

desc 'Copy measures/osms from OpenStudio-BEopt repo'
task :copy_beopt_files do
  require 'fileutils'

  beopt_measures_dir = File.join(File.dirname(__FILE__), "..", "OpenStudio-BEopt", "measures")
  buildstock_measures_dir = File.join(File.dirname(__FILE__), "resources", "measures")
  if not Dir.exist?(beopt_measures_dir)
    puts "Cannot find OpenStudio-BEopt measures dir at #{beopt_measures_dir}."
  end
  
  project_dir_names = get_all_project_dir_names()
  
  extra_files = [
                 File.join("seeds", "EmptySeedModel.osm"),
                 File.join("resources", "geometry.rb"), # Needed by SimulationOutputReport
                 File.join("resources", "constants.rb") # Needed by geometry.rb
                ]
  extra_files.each do |extra_file|
      puts "Copying #{extra_file}..."
      beopt_file = File.join(File.dirname(__FILE__), "..", "OpenStudio-BEopt", extra_file)
      if extra_file.start_with?("seeds") # Distribute to all projects
        project_dir_names.each do |project_dir_name|
          buildstock_file = File.join(File.dirname(__FILE__), project_dir_name, extra_file)
          if File.exists?(buildstock_file)
            FileUtils.rm(buildstock_file)
          end
          FileUtils.cp(beopt_file, buildstock_file)
        end
      else # Copy to resources dir
        buildstock_file = File.join(File.dirname(__FILE__), extra_file)
        if File.exists?(buildstock_file)
          FileUtils.rm(buildstock_file)
        end
        FileUtils.cp(beopt_file, buildstock_file)
      end
  end
  
  puts "Deleting #{buildstock_measures_dir}..."
  while Dir.exist?(buildstock_measures_dir)
    FileUtils.rm_rf("#{buildstock_measures_dir}/.", secure: true)
    sleep 1
  end
  FileUtils.makedirs(buildstock_measures_dir)
  
  Dir.foreach(beopt_measures_dir) do |item|
    next if !item.include? 'Residential'
    beopt_measure_dir = File.join(beopt_measures_dir, item)
    next if not Dir.exist?(beopt_measure_dir)
    puts "Copying #{item} measure..."
    FileUtils.cp_r(beopt_measure_dir, buildstock_measures_dir)
    buildstock_measure_test_dir = File.join(buildstock_measures_dir, item, "tests")
    if Dir.exist?(buildstock_measure_test_dir)
      FileUtils.rm_rf("#{buildstock_measure_test_dir}/.", secure: true)
    end
    buildstock_measure_cov_dir = File.join(buildstock_measures_dir, item, "coverage")
    if Dir.exist?(buildstock_measure_cov_dir)
      FileUtils.rm_rf("#{buildstock_measure_cov_dir}/.", secure: true)
    end
  end
end

desc 'Perform integrity check on inputs for all projects'
task :integrity_check_all do
    integrity_check()
end # rake task

desc 'Perform integrity check on inputs for project_resstock_national'
task :integrity_check_resstock_national do
    integrity_check(['project_resstock_national'])
end # rake task

desc 'Perform integrity check on inputs for project_resstock_pnw'
task :integrity_check_resstock_pnw do
    integrity_check(['project_resstock_pnw'])
end # rake task

desc 'Perform integrity check on inputs for project_resstock_testing'
task :integrity_check_resstock_testing do
    integrity_check(['project_resstock_testing'])
end # rake task

def integrity_check(project_dir_names=nil)
  require 'openstudio'
  
  if project_dir_names.nil?
    project_dir_names = get_all_project_dir_names()
  end

  # Load helper file and sampling file
  resources_dir = File.join(File.dirname(__FILE__), 'resources')
  require File.join(resources_dir, 'helper_methods')
  require File.join(resources_dir, 'run_sampling')
    
  # Setup
  lookup_file = File.join(resources_dir, 'options_lookup.tsv')
  check_file_exists(lookup_file, nil)
  model = OpenStudio::Model::Model.new
  measure_instances = {}
  
  project_dir_names.each do |project_dir_name|
    # Perform various checks on each probability distribution file
    parameters_processed = []
    option_names = {}
    tsvfiles = {}
    measures = {}
    epw_files = []
    last_size = -1
  
    parameter_names = []
    get_parameters_ordered_from_options_lookup_tsv(resources_dir).each do |parameter_name|
      tsvpath = File.join(project_dir_name, "housing_characteristics", "#{parameter_name}.tsv")
      next if not File.exist?(tsvpath) # Not every parameter used by every project
      parameter_names << parameter_name
    end
    
    while parameters_processed.size != parameter_names.size
    
      if last_size == parameters_processed.size
        # No additional processing occurred during last pass
        unprocessed_parameters = parameter_names - parameters_processed
        puts "ERROR: Unable to process these parameters: #{unprocessed_parameters.join(', ')}."
        deps = []
        unprocessed_parameters.each do |p|
          tsvpath = File.join(project_dir_name, "housing_characteristics", "#{p}.tsv")
          tsvfile = TsvFile.new(tsvpath, nil)
          tsvfile.dependency_cols.keys.each do |d|
            next if deps.include?(d)
            deps << d
          end
        end
        puts "       Perhaps one of these dependency files is missing? #{(deps - unprocessed_parameters - parameters_processed).join(', ')}."
        exit
      end
      
      last_size = parameters_processed.size
      parameter_names.each do |parameter_name|
        # Already processed? Skip
        next if parameters_processed.include?(parameter_name)
        
        tsvpath = File.join(project_dir_name, "housing_characteristics", "#{parameter_name}.tsv")
        check_file_exists(tsvpath, nil)
        tsvfile = TsvFile.new(tsvpath, nil)
        tsvfiles[parameter_name] = tsvfile
        
        # Dependencies not yet processed? Skip until a subsequent pass
        skip = false
        tsvfile.dependency_cols.keys.each do |dep|
          next if parameters_processed.include?(dep)
          skip = true
        end
        next if skip

        puts "Checking for issues with #{project_dir_name}/#{parameter_name}..."
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
              next if measures[measure_subdir][parameter_name][opt_name].to_s != args_hash.to_s
              duplicate_args = true
              break
            end
            next if duplicate_args
                
            # Store arguments
            measures[measure_subdir][parameter_name][option_name] = args_hash
                
            # Store any EPW files referenced
            args_hash.each do |k, v|
              next if v.nil? or !v.downcase.end_with?(".epw") or epw_files.include?(v)
              epw_files << v
            end
          end
        end
      end
    end # parameter_name
    
    # Check referenced EPW files exist
    epw_files.each do |epw_file|
        epw_file_full = File.join(project_dir_name, 'weather', epw_file)
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
    output_file = r.run(project_dir_name, 1000)
    if File.exist?(output_file)
      File.delete(output_file) # Clean up
    end
    
  end # project_dir_name
end

def get_all_project_dir_names()
    project_dir_names = []
    Dir.entries(File.dirname(__FILE__)).each do |entry|
        next if not Dir.exist?(entry)
        next if not entry.start_with?("project_")
        project_dir_names << entry
    end
    return project_dir_names
end