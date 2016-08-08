require 'csv'
require File.join(File.dirname(__FILE__), 'resources', 'helper_methods')
require 'optparse'
require 'fileutils'

def validate_sampling(mode)

    # This is where results will be located
    results_dir = File.join(File.dirname(__FILE__), "analysis_results")
    if not File.exists? results_dir
        Dir.mkdir(results_dir)
    end
    
    # Read all data from results csv file
    results_file = File.join(results_dir, "resstock_#{mode}.csv")
    check_file_exists(results_file)
    results_data = CSV.read(results_file)
    if results_data.size == 0
        exit
    end
    
    # Remove any data results for upgrades
    upgrade_cols = []
    results_data[0].each_with_index do |col_name, col_num|
        if col_name.end_with?('.run_measure')
            upgrade_cols << col_num
        end
    end
    new_results_data = [results_data[0]]
    results_data[1..-1].each do |row|
        has_upgrade = false
        upgrade_cols.each do |col_num|
            if row[col_num].to_i == 1
                has_upgrade = true
                break
            end
        end
        next if has_upgrade
        new_results_data << row
    end
    results_data = new_results_data
    
    skip_headers = ['Building']
    report_name = 'building_characteristics_report.'

    # Get data from all probability distribution files; store in tsvfiles hash
    tsvfiles = {}
    prob_dist_dir = File.join(File.dirname(__FILE__), "resources", "inputs", mode)
    results_data[0].each do |param_name|
        next if skip_headers.include?(param_name)
        next if !param_name.start_with?(report_name)
        param_name = param_name.sub(report_name,'')
        
        # Get all data from this probability distribution file
        prob_dist_file = File.join(prob_dist_dir, param_name + ".tsv")
        tsvfile = TsvFile.new(prob_dist_file, nil)
        
        # Store data
        tsvfiles[param_name] = tsvfile
    end

    # Data
    results_data_dir = File.join(results_dir, mode, "data")
    FileUtils.rm_rf("#{results_data_dir}/.", secure: true)
    FileUtils.mkpath(results_data_dir)
    all_samples_results = generate_data_output(results_data, tsvfiles, results_data_dir, skip_headers, report_name)
    generate_data_input(results_data, tsvfiles, results_data_dir, skip_headers, report_name)
    
    # Visualization
    results_vis_dir = File.join(results_dir, mode, "visualizations")
    FileUtils.rm_rf("#{results_vis_dir}/.", secure: true)
    FileUtils.mkpath(results_vis_dir)
    generate_visualizations(results_data, tsvfiles, results_vis_dir, all_samples_results, skip_headers, report_name)
end 

def generate_data_output(results_data, tsvfiles, results_data_dir, skip_headers, report_name)
    # Create map of parameter names to results_file columns
    results_file_cols = {}
    tsvfiles.keys.each do |param_name|
        results_data[0].each_with_index do |col_header, index|
            next if !col_header.start_with?(report_name)
            col_header = col_header.sub(report_name,'')
            next if col_header != param_name
            results_file_cols[param_name] = index
        end
    end

    # Generate sample results output for each reported column in the results csv file
    all_samples_results = {}
    results_data[0].each do |param_name|
        next if skip_headers.include?(param_name)
        next if !param_name.start_with?(report_name)
        param_name = param_name.sub(report_name,'')
        
        tsvfile = tsvfiles[param_name]
        puts "Processing data for #{param_name}..."
        
        # Generate combinations of dependency options
        if tsvfile.dependency_cols.size > 0
            dep_combos = []
            tsvfile.rows.each do |row|
                next if row.size == 0
                dep_combo = []
                tsvfile.dependency_cols.each do |dep_name, dep_col|
                    dep_combo << row[dep_col]
                end
                dep_combos << dep_combo
            end
        else
            dep_combos = [[]]
        end
        
        # Get sampling percentages for each option for each combination
        samples_results = []
        dep_combos.each do |dep_combo|
        
            # Init results for this combo
            sample_results = []
            tsvfile.option_cols.each do |option_name|
                sample_results << 0
            end
            num_samples = 0
            
            # Calculate results for this combo
            results_data[1..-1].each do |row|
                row_match = true
                tsvfile.dependency_cols.each_with_index do |(dep_name, dep_col), index|
                    if row[results_file_cols[dep_name]].downcase != dep_combo[index].downcase
                        row_match = false
                    end
                end
                next if not row_match
                num_samples += 1
                tsvfile.option_cols.each_with_index do |(option_name, option_col), index|
                    next if option_name.downcase != row[results_file_cols[param_name]].downcase
                    sample_results[index] += 1
                end
            end
            
            # Error check that sum of option sample numbers equals total number of samples for this combo
            sum_option_samples = 0
            tsvfile.option_cols.each_with_index do |(option_name, option_col), index|
                sum_option_samples += sample_results[index]
            end
            if sum_option_samples != num_samples
                puts "Num samples doesn't match for #{param_name}."
                exit
            end
            
            # Convert num samples to percentage
            if num_samples > 0
                tsvfile.option_cols.each_with_index do |(option_name, option_col), index|
                    sample_results[index] = sample_results[index]/num_samples.to_f
                end 
            end
            
            # Insert dependency option names
            tsvfile.dependency_cols.each_with_index do |(dep_name, dep_col), index|
                sample_results.insert(index, dep_combo[index])
            end
            
            # Append number of samples
            sample_results << num_samples
            samples_results << sample_results
        end
        
        # Write *_output.csv
        outfile = File.join(results_data_dir, tsvfile.filename.sub(File.extname(tsvfile.filename),"_output.csv"))
        CSV.open(outfile, "wb") do |csv|
            csv << tsvfile.header + ["# Samples"]
            samples_results.each do |sample_results|
                csv << sample_results
            end
        end
        
        all_samples_results[param_name] = samples_results
    end
    return all_samples_results
end

def generate_data_input(results_data, tsvfiles, results_data_dir, skip_headers, report_name)
    # Generate probability distribution inputs in compatible form
    results_data[0].each do |param_name|
        next if skip_headers.include?(param_name)
        next if !param_name.start_with?(report_name)
        param_name = param_name.sub(report_name,'')
        
        tsvfile = tsvfiles[param_name]
        
        # Write *_input.csv
        outfile = File.join(results_data_dir, tsvfile.filename.sub(File.extname(tsvfile.filename),"_input.csv"))
        CSV.open(outfile, "wb") do |csv|
            csv << tsvfile.header
            tsvfile.rows.each do |row|
                rowdata = []
                row.each_with_index do |val, col|
                    next if not tsvfile.option_cols.values.include?(col) and not tsvfile.dependency_cols.values.include?(col)
                    rowdata << val
                end
                csv << rowdata
            end
        end
    end
end

def generate_visualizations(results_data, tsvfiles, results_vis_dir, all_samples_results, skip_headers, report_name)
    # Generate html visualizations via Google

    html_filenames = {}
    results_data[0].each do |param_name|
        next if skip_headers.include?(param_name)
        next if !param_name.start_with?(report_name)
        param_name = param_name.sub(report_name,'')
        
        tsvfile = tsvfiles[param_name]
        
        # Uses a series for each option so that the series legend/color can be assigned
        num_data_series = tsvfile.option_cols.size
        
        if num_data_series > 20
            puts "Skipping visualization for #{param_name} (too large)..."
            next
        end
        puts "Generating visualization for #{param_name}..."
        
        # Adopted from https://developers.google.com/chart/interactive/docs/gallery/scatterchart
        # See https://developers.google.com/chart/interactive/docs/points#customizing-individual-points for customizing individual points
        html_text = %{
    <html>
      <head>
      <title>ResStock Visualization: <TITLE_HERE></title>
        <script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"></script>
        <script type="text/javascript">
          google.charts.load('current', {'packages':['corechart']});
          google.charts.setOnLoadCallback(drawChart);
          function drawChart() {
            var data = google.visualization.arrayToDataTable([
              // ['X', 'Y', {'type': 'string', 'role': 'style'}],
              // [1, 3, null],
              // [2, 2.5, null],
              // [3, 3, null],
              // [4, 4, null],
              // [5, 4, null],
              // [6, 3, 'point { size: 18; shape-type: star; fill-color: #a52714; }'],
              // [7, 2.5, null],
              // [8, 3, null]
              <TABLE_HEADER_HERE>,
              <TABLE_DATA_HERE>
            ]);

            var options = {
              title: '<CHART_TITLE_HERE>',
              hAxis: {title: 'Input (Data)', minValue: 0, maxValue: 1, gridlines: {count: 6} },
              vAxis: {title: 'Output (Models)', minValue: 0, maxValue: 1, gridlines: {count: 6} },
              dataOpacity: 0.6,
              trendlines: { 
                #{num_data_series}: {type: 'linear', color: 'black', lineWidth: 2, opacity: 0.3, showR2: false, visibleInLegend: false, tooltip: false}, // Line of perfect agreement
                #{num_data_series+1}: {type: 'linear', color: 'grey', lineWidth: 1, opacity: 0.3, showR2: false, visibleInLegend: false, tooltip: false}, // Line + 20%
                #{num_data_series+2}: {type: 'linear', color: 'grey', lineWidth: 1, opacity: 0.3, showR2: false, visibleInLegend: false, tooltip: false} // Line - 20%
              },
              series: { 
                #{num_data_series}: {visibleInLegend: false, pointsVisible: false, labelInLegend: false}, // Line of perfect agreement
                #{num_data_series+1}: {visibleInLegend: false, pointsVisible: false, labelInLegend: false}, // Line + 20%
                #{num_data_series+2}: {visibleInLegend: false, pointsVisible: false, labelInLegend: false} // Line - 20%
              }
            };

            var chart = new google.visualization.ScatterChart(document.getElementById('chart_div'));

            chart.draw(data, options);
          }
        </script>
      </head>
      <body>
        <div style="display:inline-block; width: 100%; text-align:center;">
            <PREV_BUTTON_HERE>
            <form style="display: inline-block">
                <select name="select" onChange="window.open(this.options[this.selectedIndex].value,'_self')" onKeyPress="window.open(this.options[this.selectedIndex].value,'_self')">
                    <OPTIONS_HERE>
                </select>
            </form>
            <NEXT_BUTTON_HERE>
        </div>
        <div id="chart_div" style="width: 100%; height: 100%;"></div>
      </body>
    </html>
    }

        # Replace <TITLE_HERE> with html title
        html_text.sub!("<TITLE_HERE>", param_name)

        # Determine sizes of points
        # FIXME: Weighting should be calculated based on the inputs, not outputs
        max_point_size = 15 # pixels
        min_point_size = 1 # pixels
        num_samples = []
        all_samples_results[param_name].each do |result|
            num_samples << result[-1]
        end
        max_num_samples = num_samples.max.to_f
        
        # Replace <TABLE_HEADER_HERE> with the appropriate header
        table_header_html = "['Input', "
        (1..num_data_series).each do |series_num|
            series_name = tsvfile.header[series_num+tsvfile.dependency_cols.size-1].to_s
            table_header_html << "'#{series_name}', {'type': 'string', 'role': 'style'},"
        end
        table_header_html << "'Line','Line +20%','Line -20%']"
        html_text.sub!("<TABLE_HEADER_HERE>", table_header_html)
    
        # Replace <TABLE_DATA_HERE> with javascript array based on actual data
        table_data_html = ""
        tsvfile.rows.each_with_index do |row, i|
            next if row.size == 0
            if num_samples[i] == 0
                point_size = 0
            else
                point_size = (num_samples[i]/max_num_samples * (max_point_size.to_f - min_point_size.to_f)).ceil + min_point_size
            end
            tsvfile.option_cols.each_with_index do |(option_name, option_col), j|
                next if all_samples_results[param_name][i].nil? 
                xval = row[option_col]
                yval = all_samples_results[param_name][i][j+tsvfile.dependency_cols.size]
                table_data_html << add_datapoint(xval, yval, j+1, num_data_series, point_size)
            end
        end
        # Add line for perfect agreement
        table_data_html << add_datapoint(0.0, 0, 0, num_data_series, 0, xval_equal=0.0, xval_plus20="null", xval_minus20="null")
        table_data_html << add_datapoint(1.0, 0, 0, num_data_series, 0, xval_equal=1.0, xval_plus20="null", xval_minus20="null")
        # Add line for +20%
        table_data_html << add_datapoint(0.0, 0, 0, num_data_series, 0, xval_equal="null", xval_plus20=0.2, xval_minus20="null")
        table_data_html << add_datapoint(0.8, 0, 0, num_data_series, 0, xval_equal="null", xval_plus20=1.0, xval_minus20="null")
        # Add line for -20%
        table_data_html << add_datapoint(0.2, 0, 0, num_data_series, 0, xval_equal="null", xval_plus20="null", xval_minus20=0.0)
        table_data_html << add_datapoint(1.0, 0, 0, num_data_series, 0, xval_equal="null", xval_plus20="null", xval_minus20=0.8)
        html_text.sub!("<TABLE_DATA_HERE>", table_data_html.chop)
        
        # Replace <CHART_TITLE_HERE> with parameter name
        html_text.sub!("<CHART_TITLE_HERE>", param_name)
        
        outfile = File.join(results_vis_dir, tsvfile.filename.sub(File.extname(tsvfile.filename),".html"))
        File.write(outfile, html_text)
        html_filenames[param_name] = File.basename(outfile)
    end
    
    # Update select dropdowns and buttons in each file
    sorted_params = html_filenames.keys.sort
    html_filenames.keys.sort.each_with_index do |param_name, index|
        # Select dropdown
        options_html = ""
        html_filenames.keys.sort.each do |param_name2|
            if param_name == param_name2
                options_html << "<option value=\"#{html_filenames[param_name2]}\" selected=\"selected\">#{param_name2}</option>"
            else
                options_html << "<option value=\"#{html_filenames[param_name2]}\">#{param_name2}</option>"
            end
        end
        full_filename = File.join(results_vis_dir, html_filenames[param_name])
        File.write(full_filename,File.open(full_filename,&:read).gsub("<OPTIONS_HERE>",options_html))
        
        # Prev button
        if index > 0
            prev_html = "<form action=\"#{html_filenames[sorted_params[index-1]]}\" style=\"display: inline-block\"><input type=\"submit\" value=\"<<\" title=\"#{sorted_params[index-1]}\"></form>"
        else
            prev_html = "<form style=\"display: inline-block\"><input type=\"submit\" value=\"<<\" disabled=\"disabled\"></form>"
        end
        File.write(full_filename,File.open(full_filename,&:read).gsub("<PREV_BUTTON_HERE>",prev_html))
        
        # Next button
        if index < html_filenames.size-1
            next_html = "<form action=\"#{html_filenames[sorted_params[index+1]]}\" style=\"display: inline-block\"><input type=\"submit\" value=\">>\" title=\"#{sorted_params[index+1]}\"></form>"
        else
            next_html = "<form style=\"display: inline-block\"><input type=\"submit\" value=\">>\" disabled=\"disabled\"></form>"
        end
        File.write(full_filename,File.open(full_filename,&:read).gsub("<NEXT_BUTTON_HERE>",next_html))
    end
    
    first_param = html_filenames.keys.sort[0]
    puts "Launching visualization for #{first_param}..."
    %x{call "#{File.absolute_path(File.join(results_vis_dir, html_filenames[first_param]))}"}
end

def add_datapoint(xval, yval, series_position, num_data_series, point_size, xval_equal="null", xval_plus20="null", xval_minus20="null")
    s = "\n[ #{xval}, "
    (1..num_data_series).each do |series_num|
        if series_num == series_position
            s << "#{yval},'point {size: #{point_size};}',"
        else
            s << "null,null,"
        end
    end
    s << "#{xval_equal},#{xval_plus20},#{xval_minus20}],"
    return s
end

# Initialize optionsParser ARGV hash
options = {}

# Define allowed ARGV input
optparse = OptionParser.new do |opts|
    opts.banner = 'Usage:    ruby validate_sampling.rb [-m] <mode>'

    options[:rsmode] = 'national'
    opts.on('-m', '--mode <res_stock_mode>', 'national|pnw') do |mode_type|
        options[:rsmode] = mode_type
    end
    opts.on_tail('-h', '--help', 'display help') do
        puts opts
        exit
    end

end

# Execute ARGV parsing into options hash holding sybolized key values
optparse.parse!

if not (options[:rsmode] == 'national' or options[:rsmode] == 'pnw')
    fail "ERROR: mode must be either 'national' or 'pnw'"
end

validate_sampling(options[:rsmode])
puts "Done!"