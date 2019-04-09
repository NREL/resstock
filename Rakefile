require 'rake'
require 'rake/testtask'

namespace :test do

  desc 'Run unit tests for all projects/measures'
  Rake::TestTask.new('all') do |t|
    t.libs << 'test'
    t.test_files = Dir['project_*/tests/*.rb'] + Dir['measures/*/tests/*.rb']
    t.warning = false
    t.verbose = true
  end
  
  desc 'regenerate test osm files from osw files'
  Rake::TestTask.new('regenerate_osms') do |t|
    t.libs << 'test'
    t.test_files = Dir['test/osw_files/tests/*.rb']
    t.warning = false
    t.verbose = true
  end
  
end

def regenerate_osms

    require 'openstudio'
  
    start_time = Time.now
    num_tot = 0
    num_success = 0
    
    osw_path = File.expand_path("../test/osw_files/", __FILE__)
  
    # Generate hash that maps osw's to measures
    osw_map = {}
    measures = Dir.entries(File.expand_path("../measures/", __FILE__)).select {|entry| File.directory? File.join(File.expand_path("../measures/", __FILE__), entry) and !(entry == '.' || entry == '..') }
    measures.each do |m|
        testrbs = Dir[File.expand_path("../measures/#{m}/tests/*.rb", __FILE__)]
        if testrbs.size == 1
            # Get osm's specified in the test rb
            testrb = testrbs[0]
            osms = get_osms_listed_in_test(testrb)
            osms.each do |osm|
                osw = File.basename(osm).gsub('.osm','.osw')
                if not osw_map.keys.include?(osw)
                    osw_map[osw] = []
                end
                osw_map[osw] << m
            end
        elsif testrbs.size > 1
            fail "ERROR: Multiple .rb files found in #{m} tests dir."
      end
    end
    
    osw_files = Dir.entries(osw_path).select {|entry| entry.end_with?(".osw")}
    if File.exists?(File.expand_path("../log", __FILE__))
        FileUtils.rm(File.expand_path("../log", __FILE__))
    end

    # Print warnings about unused OSWs
    osw_files.each do |osw|
        next if not osw_map[osw].nil?
        puts "Warning: Unused OSW '#{osw}'."
    end

    # Print more warnings
    osw_map.each do |osw, _measures|
        next if osw_files.include? osw
        puts "Warning: OSW not found '#{osw}'."
    end
    
    # Remove any extra osm's in the measures test dirs
    measures.each do |m|
        osms = Dir[File.expand_path("../measures/#{m}/tests/*.osm", __FILE__)]
        osms.each do |osm|
            osw = File.basename(osm).gsub('.osm','.osw')
            if osw_map[osw].nil? or !osw_map[osw].include?(m)
                puts "Extra file #{osw} found in #{m}/tests. Do you want to delete it? (y/n)"
                input = STDIN.gets.strip.downcase
                next if input != "y"
                FileUtils.rm(osm)
                puts "File deleted."
            end
        end
    end
    
    cli_path = OpenStudio.getOpenStudioCLI

    num_osws = 0
    osw_files.each do |osw|
        next if osw_map[osw].nil?
        num_osws += 1
    end

    osw_files.each do |osw|
    
        next if osw_map[osw].nil?

        # Generate osm from osw
        osw_filename = osw
        num_tot += 1
        
        puts "[#{num_tot}/#{num_osws}] Regenerating osm from #{osw}..."
        osw = File.expand_path("../test/osw_files/#{osw}", __FILE__)
        update_and_format_osw(osw)
        osm = File.expand_path("../test/osw_files/run/in.osm", __FILE__)
        command = "\"#{cli_path}\" --no-ssl run -w #{osw} -m >> log"
        for _retry in 1..3
            system(command)
            break if File.exists?(osm)
        end
        if not File.exists?(osm)
            fail "  ERROR: Could not generate osm."
        end

        # Add auto-generated message to top of file
        # Update EPW file paths to be relative for the CirceCI machine
        file_text = File.readlines(osm)
        File.open(osm, "w") do |f|
            f.write("!- NOTE: Auto-generated from #{osw.gsub(File.dirname(__FILE__), "")}\n")
            file_text.each do |file_line|
                if file_line.strip.start_with?("file:///")
                    file_data = file_line.split('/')
                    file_line = file_data[0] + "../tests/" + file_data[-1]
                end
                f.write(file_line)
            end
        end

        # Copy to appropriate measure test dirs
        osm_filename = osw_filename.gsub(".osw", ".osm")
        num_copied = 0
        osw_map[osw_filename].each do |measure|
            measure_test_dir = File.expand_path("../measures/#{measure}/tests/", __FILE__)
            FileUtils.cp(osm, File.expand_path("#{measure_test_dir}/#{osm_filename}", __FILE__))
            num_copied += 1
        end
        puts "  Copied to #{num_copied} measure(s)."
        num_success += 1

        # Clean up
        run_dir = File.expand_path("../test/osw_files/run", __FILE__)
        if Dir.exists?(run_dir)
            FileUtils.rmtree(run_dir)
        end
        if File.exists?(File.expand_path("../test/osw_files/out.osw", __FILE__))
            FileUtils.rm(File.expand_path("../test/osw_files/out.osw", __FILE__))
        end
    end
    
    puts "Completed. #{num_success} of #{num_tot} osm files were regenerated successfully (#{Time.now - start_time} seconds)."

end

def get_osms_listed_in_test(testrb)
    osms = []
    if not File.exists?(testrb)
      return osms
    end
    str = File.readlines(testrb).join("\n")
    osms = str.scan(/\w+\.osm/)
    return osms.uniq
end

def update_and_format_osw(osw)
  # Insert new step(s) into test osw files, if they don't already exist: {{step1=>index, step2=>index}}
  new_steps = {}
  json = JSON.parse(File.read(osw), :symbolize_names=>true)
  steps = json[:steps]
  new_steps.each do |new_step, ix|
    insert_new_step = true
    steps.each do |step|
      step.each do |k, v|
        next if k != :measure_dir_name
        next if v != new_step.values[0] # already have this step
        insert_new_step = false
      end
    end
    next unless insert_new_step
    json[:steps].insert(ix, new_step)
  end
  File.open(osw, "w") do |f|
    f.write(JSON.pretty_generate(json)) # format nicely even if not updating the osw with new steps
  end
end

desc 'Perform integrity check on inputs for all projects'
task :integrity_check_all do
    get_all_project_dir_names().each do |project_dir_name|
      integrity_check(project_dir_name)
      integrity_check_options_lookup_tsv(project_dir_name)
    end
end # rake task

desc 'Perform integrity check on inputs for project_resstock_national'
task :integrity_check_resstock_national do
    integrity_check('project_resstock_national')
    integrity_check_options_lookup_tsv('project_resstock_national')
end # rake task

desc 'Perform integrity check on inputs for project_resstock_testing'
task :integrity_check_resstock_testing do
    integrity_check('project_resstock_testing')
    integrity_check_options_lookup_tsv('project_resstock_testing')
end # rake task

def integrity_check(project_dir_name)
  # Load helper file and sampling file
  resources_dir = File.join(File.dirname(__FILE__), 'resources')
  require File.join(resources_dir, 'buildstock')
  require File.join(resources_dir, 'run_sampling')
    
  # Setup
  lookup_file = File.join(resources_dir, 'options_lookup.tsv')
  check_file_exists(lookup_file, nil)
  
  # Perform various checks on each probability distribution file
  parameters_processed = []
  tsvfiles = {}
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
      undefined_deps = deps - unprocessed_parameters - parameters_processed
      # Check if undefined deps exist but are undefined simply because they're not in options_lookup.tsv
      undefined_deps_exist = true
      undefined_deps.each do |undefined_dep|
        tsvpath = File.join(project_dir_name, "housing_characteristics", "#{undefined_dep}.tsv")
        next if File.exist?(tsvpath)
        undefined_deps_exist = false
      end
      if undefined_deps_exist
        err += "\nPerhaps one of these dependency files has options missing from options_lookup.tsv? #{undefined_deps.join(', ')}."
      else
        err += "\nPerhaps one of these dependency files is missing? #{undefined_deps.join(', ')}."
      end
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
      
      # Check for all options defined in options_lookup.tsv
      get_measure_args_from_option_names(lookup_file, tsvfile.option_cols.keys, parameter_name)
        
    end
  end # parameter_name
  
  # Test sampling
  r = RunSampling.new
  output_file = r.run(project_dir_name, 1000, 'buildstock.csv')
  if File.exist?(output_file)
    File.delete(output_file) # Clean up
  end
  
  # Unused TSVs?
  err = ""
  Dir[File.join(project_dir_name, "housing_characteristics", "*.tsv")].each do |tsvpath|
    parameter_name = File.basename(tsvpath, ".*")
    if not parameter_names.include? parameter_name
      err += "ERROR: TSV file #{tsvpath} not used in options_lookup.tsv.\n"
    end
  end
  if not err.empty?
    raise err
  end
  
end

def integrity_check_options_lookup_tsv(project_dir_name)

  require 'openstudio'

  # Load helper file and sampling file
  resources_dir = File.join(File.dirname(__FILE__), 'resources')
  require File.join(resources_dir, 'buildstock')
    
  # Setup
  lookup_file = File.join(resources_dir, 'options_lookup.tsv')
  check_file_exists(lookup_file, nil)

  # Integrity checks for option_lookup.tsv
  measures = {}
  model = OpenStudio::Model::Model.new
  
  # Gather all options/arguments
  parameter_names = get_parameters_ordered_from_options_lookup_tsv(resources_dir)
  parameter_names.each do |parameter_name|
    
    tsvpath = File.join(project_dir_name, "housing_characteristics", "#{parameter_name}.tsv")
    next if not File.exist?(tsvpath) # Not every parameter used by every project
  
    option_names = get_options_for_parameter_from_options_lookup_tsv(resources_dir, parameter_name)
    options_measure_args = get_measure_args_from_option_names(lookup_file, option_names, parameter_name, nil)
    option_names.each do |option_name|
      # Check for (parameter, option) names
      # Get measure name and arguments associated with the option
      options_measure_args[option_name].each do |measure_subdir, args_hash|
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

  max_checks = 1000
  measures.keys.each do |measure_subdir|
    puts "Checking for issues with #{measure_subdir} measure..."

    measurerb_path = File.absolute_path(File.join(File.dirname(lookup_file), 'measures', measure_subdir, 'measure.rb'))
    check_file_exists(measurerb_path, nil)
    measure_instance = get_measure_instance(measurerb_path)

    # Validate measure arguments for each combination of options
    param_names = measures[measure_subdir].keys()
    options_array = []
    param_names.each do |parameter_name|
      if ["Bathroom Spot Vent Hour", "Clothes Dryer Spot Vent Hour", "Range Spot Vent Hour"].include? parameter_name
        # Prevent "too big to product" error for airflow measure by just 
        # using first option for these parameters.
        options_array << [measures[measure_subdir][parameter_name].keys()[0]]
      else
        options_array << measures[measure_subdir][parameter_name].keys()
      end
    end
    option_combinations = options_array.first.product(*options_array[1..-1])
    
    all_measure_args = []
    max_checks_reached = false
    option_combinations.shuffle.each_with_index do |option_combination, combo_num|
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
      validate_measure_args(measure_instance.arguments(model), measure_args, lookup_file, measure_subdir, nil)
    end
    
    if max_checks_reached
      puts "Max number of checks (#{max_checks}) reached. Continuing..."
    end
  end
  
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