require 'bundler'
require 'rake'
require 'rake/testtask'
Bundler.setup

desc 'Copy measures/osms from OpenStudio-BEopt repo'
task :copy_beopt_files do
  require 'fileutils'

  # TODO: Should really grab latest from https://github.com/NREL/OpenStudio-BEopt/archive/master.zip
  beopt_measures_dir = File.join(File.dirname(__FILE__), "..", "OpenStudio-BEopt", "measures")
  buildstock_resource_measures_dir = File.join(File.dirname(__FILE__), "resources", "measures")
  if not Dir.exist?(beopt_measures_dir)
    puts "Cannot find OpenStudio-BEopt measures dir at #{beopt_measures_dir}."
  end
  
  # Copy seed osm and other needed resource files
  project_dir_names = get_all_project_dir_names()
  extra_files = [
                 File.join("seeds", "EmptySeedModel.osm"),
                 File.join("workflows", "measure-info.json"),
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
        buildstock_file = File.join(File.dirname(__FILE__), "resources", File.basename(extra_file))
        if File.exists?(buildstock_file)
          FileUtils.rm(buildstock_file)
        end
        FileUtils.cp(beopt_file, buildstock_file)
      end
  end
  
  # Clean out resources/measures/ dir
  puts "Deleting #{buildstock_resource_measures_dir}..."
  while Dir.exist?(buildstock_resource_measures_dir)
    FileUtils.rm_rf("#{buildstock_resource_measures_dir}/.", secure: true)
    sleep 1
  end
  FileUtils.makedirs(buildstock_resource_measures_dir)
  
  # Copy residential measures to resources/measures/
  Dir.foreach(beopt_measures_dir) do |beopt_measure|
    next if !beopt_measure.include? 'Residential'
    beopt_measure_dir = File.join(beopt_measures_dir, beopt_measure)
    next if not Dir.exist?(beopt_measure_dir)
    puts "Copying #{beopt_measure} measure..."
    FileUtils.cp_r(beopt_measure_dir, buildstock_resource_measures_dir)
    ["coverage","tests"].each do |subdir|
      buildstock_resource_measures_subdir = File.join(buildstock_resource_measures_dir, beopt_measure, subdir)
      if Dir.exist?(buildstock_resource_measures_subdir)
        FileUtils.rm_rf("#{buildstock_resource_measures_subdir}/.", secure: true)
      end
    end
  end
  
  # Copy other measures to measure/ dir
  other_measures = ["TimeseriesCSVExport"]
  buildstock_measures_dir = buildstock_resource_measures_dir = File.join(File.dirname(__FILE__), "measures")
  other_measures.each do |other_measure|
    puts "Copying #{other_measure} measure..."
    FileUtils.cp_r(File.join(beopt_measures_dir, other_measure), buildstock_measures_dir)
    ["coverage","tests"].each do |subdir|
      buildstock_measure_subdir = File.join(buildstock_measures_dir, other_measure, subdir)
      if Dir.exist?(buildstock_measure_subdir)
        FileUtils.rm_rf("#{buildstock_measure_subdir}/.", secure: true)
      end
    end
  end
end

namespace :test do

  desc 'Run unit tests for all measures'
  Rake::TestTask.new('all') do |t|
    t.libs << 'test'
    t.test_files = Dir['project_*/tests/*.rb']
    t.warning = false
    t.verbose = true
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

desc 'Perform integrity check on inputs for project_resstock_dsgrid'
task :integrity_check_resstock_dsgrid do
    integrity_check(['project_resstock_dsgrid'])
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
        err = "ERROR: Unable to process these parameters: #{unprocessed_parameters.join(', ')}."
        deps = []
        unprocessed_parameters.each do |p|
          tsvpath = File.join(project_dir_name, "housing_characteristics", "#{p}.tsv")
          tsvfile = TsvFile.new(tsvpath, nil)
          tsvfile.dependency_cols.keys.each do |d|
            next if deps.include?(d)
            deps << d
          end
        end
        err += "       Perhaps one of these dependency files is missing? #{(deps - unprocessed_parameters - parameters_processed).join(', ')}."
        raise err
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
        if combo_hashes.size > 0
          combo_hashes.each do |combo_hash|
            _matched_option_name, _matched_row_num = tsvfile.get_option_name_from_sample_number(1.0, combo_hash)
          end
        else
          # global distribution
          _matched_option_name, _matched_row_num = tsvfile.get_option_name_from_sample_number(1.0, nil)
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
                
          end
        end
      end
    end # parameter_name
    
    # Additional integrity checks for option_lookup.tsv
    max_checks = 1000
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
      max_checks_reached = false
      option_combinations.each_with_index do |option_combination, combo_num|
        if combo_num > max_checks
          max_checks_reached = true
          break
        end
        measure_args = {}
        option_combination.each_with_index do |option_name, idx|
            measures[measure_subdir][param_names[idx]][option_name].each do |k,v|
                measure_args[k] = v
            end
        end
        next if all_measure_args.include?(measure_args)
        all_measure_args << measure_args
      end
      all_measure_args.shuffle.each_with_index do |measure_args, idx|
        validate_measure_args(measure_instances[measure_subdir].arguments(model), measure_args, lookup_file, measure_subdir, nil)
      end
      if max_checks_reached
        puts "Max number of checks (#{max_checks}) reached. Continuing..."
      end
    end
    
    # Test sampling
    r = RunSampling.new
    output_file = r.run(project_dir_name, 1000, 'buildstock.csv')
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