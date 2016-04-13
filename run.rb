require 'optparse'

# Get excel project and return analysis json object
# Most code borrowed from cli.rb
def get_json_object_from_excel_analysis(filename)
    require 'openstudio-analysis'
    # Rather than parse the Excel file, we'll create the json file and parse that
    # Long-term, we hope to not have an Excel file and use/write the json file directly.
    Dir.mkdir '.temp' unless File.exist?('.temp')
    output_path = '.temp/analysis'
    analyses = OpenStudio::Analysis.from_excel(filename)
    if analyses.size != 1
        puts 'ERROR: EXCEL-PROJECT -- More than one seed model specified. This feature is deprecated'.red
        fail 1
    end
    analysis = analyses.first
    json_filename = "#{output_path}.json"
    analysis.save json_filename
    require 'json'
    json_object = JSON.parse(File.read(json_filename))
    return json_object
end

def get_probability_distribution_files(json, rsmode)
    files = []
    json['analysis']['problem']['workflow'].each do |w|
        next if w['measure_definition_class_name'] != 'CallMetaMeasure'
        dir = w['measure_definition_directory']
        w['arguments'].each do |a|
            next if a['name'] != 'probability_file'
            files << File.absolute_path(File.join(dir, 'resources', 'inputs', rsmode, a['value']))
        end
    end
    return files
end

def get_combination_hashes(parameter_option_names, dependencies)
    combos_hashes = []

    # Construct array of dependency value arrays
    depval_array = []
    dependencies.each do |dep|
        depval_array << parameter_option_names[dep]
    end
    
    if depval_array.size == 0
        return combos_hashes
    end
    
    # Create combinations
    combos = depval_array.first.product(*depval_array[1..-1])
    
    # Convert to combinations of hashes
    combos.each do |combo|
        # Convert to hash
        combo_hash = {}
        if combo.is_a?(String)
            combo_hash[dependencies[0]] = combo
        else
            dependencies.each_with_index do |dep, i|
                combo_hash[dep] = combo[i]
            end
        end
        combos_hashes << combo_hash
    end
    return combos_hashes
end

def perform_integrity_checks(project_file, rsmode)
    require File.join(File.dirname(__FILE__), 'measures', 'CallMetaMeasure', 'resources', 'helper_methods')

    check_file_exists(project_file)
    json = get_json_object_from_excel_analysis(project_file)
    pdfiles = get_probability_distribution_files(json, rsmode)
    lookup_file = File.absolute_path(File.join(pdfiles[0], '..', '..', '..', 'options_lookup.txt'))
    check_file_exists(lookup_file, nil)
  
    # Perform various checks on each probability distribution file
    parameters_processed = []
    parameter_option_names = {}
  
    pdfiles.each do |pdfile|
        puts "Checking for issues with #{File.basename(pdfile)}..."
        check_file_exists(pdfile, nil)
        headers, rows, parameter_name, parameter_option_names[parameter_name], dependency_cols = get_probability_file_data(pdfile, nil)
    
        # Check all dependencies have already been processed
        dependency_cols.keys.each do |dep|
            next if parameters_processed.include?(dep)
            puts "ERROR: Parameter '#{parameter_name}' has a dependency '#{dep}' that was not already processed."
            exit
        end
        parameters_processed << parameter_name
    
        # Test all possible combinations of dependency value combinations
        combo_hashes = get_combination_hashes(parameter_option_names, dependency_cols.keys)
        combo_hashes.each do |combo_hash|
            option_name, matched_row_num = get_option_name_from_sample_value(1.0, combo_hash, pdfile, dependency_cols, parameter_option_names[parameter_name], headers, rows, nil)
            rows.delete_at(matched_row_num) # speed up subsequent combo_hash searches
        end
    
        # Checks for option_lookup.txt
        measure_args_from_xml = {}
        parameter_option_names[parameter_name].each do |option_name|
            # Check for (parameter, option) names
            measure_args = get_measure_args_from_option_name(lookup_file, option_name, parameter_name, nil)
            # Check that measures exist and all measure arguments are provided
            measure_args.keys.each do |measure_subdir|
                if not measure_args_from_xml.keys.include?(measure_subdir)
                    measurerb_path = File.absolute_path(File.join(File.dirname(lookup_file), 'measures', measure_subdir, "measure.rb"))
                    check_file_exists(measurerb_path, nil)
                    measure_args_from_xml[measure_subdir] = get_measure_args_from_xml(measurerb_path.sub(".rb",".xml"))
                end
                validate_measure_args(measure_args_from_xml[measure_subdir], measure_args[measure_subdir].keys, lookup_file, parameter_name, option_name, nil)
            end
        end
    end
    
    # If we got this far...
    puts "ALL INTEGRITY CHECKS PASSED."
end

# Initialize optionsParser ARGV hash
options = {}

# Define allowed ARGV input
optparse = OptionParser.new do |opts|
    opts.banner = 'Usage:    ruby run.rb [-t] <target> [-m] <mode> [-r] [-k] [-n]'

    options[:target] = 'nrel24b'
    opts.on( '-t', '--target <target_alias>', 'target OpenStudio-Server instance') do |server|
        options[:target] = server
    end

    options[:rsmode] = 'national'
    opts.on('-m', '--mode <res_stock_mode>', 'national or pnw') do |mode_type|
        options[:rsmode] = mode_type
    end

    options[:runonly] = false
    opts.on('-r', '--runonly', 'run simulations only, don\'t check for issues') do
        options[:runonly] = true
    end

    options[:checkonly] = false
    opts.on('-k', '--checkonly', 'check for issues only, don\'t run simulations') do
        options[:checkonly] = true
    end

    options[:nocsv] = false
    opts.on('-n', '--nocsv', 'don\'t download csv results and metadata files') do
        options[:nocsv] = true
    end

    opts.on_tail('-h', '--help', 'display help') do
        puts opts
        exit
    end

end

# Execute ARGV parsing into options hash holding sybolized key values
optparse.parse!

if options[:runonly] and options[:checkonly]
    fail "ERROR: Both -k and -r entered. Please specify one or the other."
end

# Get project file associated with mode
if not (options[:rsmode] == 'national' or options[:rsmode] == 'pnw')
    fail "ERROR: mode must be either 'national' or 'pnw'"
end
project_file = nil
if options[:rsmode] == 'national'
    project_file = File.join(File.dirname(__FILE__),'projects/res_stock_national.xlsx')
elsif options[:rsmode] == 'pnw'
    project_file = File.join(File.dirname(__FILE__),'projects/res_stock_pnw.xlsx')
end

# Perform various checks to look for problems
if options[:checkonly] or not options[:runonly]
    perform_integrity_checks(project_file, options[:rsmode])
end

# Call cli.rb with appropriate args
if options[:runonly] or not options[:checkonly]
    c_arg = ' -c'
    if options[:nocsv]
        c_arg = ''
    end
    Kernel.exec("bundle exec ruby cli.rb -t #{options[:target].to_s} -p '#{project_file}'#{c_arg}")
end
