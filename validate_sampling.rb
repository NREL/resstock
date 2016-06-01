require 'csv'
require File.join(File.dirname(__FILE__), 'measures', 'CallMetaMeasure', 'resources', 'helper_methods')
require 'optparse'

def validate_sampling(mode)

    # This is where results will be located
    results_dir = File.join(File.dirname(__FILE__), "results", mode)
    if not File.exists? results_dir
        Dir.mkdir(results_dir)
    end
    
    puts "Processing data..."

    # Read all data from results csv file
    results_file = File.join(results_dir, "resstock.csv")
    check_file_exists(results_file)
    results_data = CSV.read(results_file)
    if results_data.size == 0
        exit
    end

    # Get data from all probability distribution files; store in all_prob_dist_data hash
    # Also generate col_header=>param_name hash
    all_prob_dist_data = {}
    param_names = {}
    key_prefix = "res_stock_reporting."
    prob_dist_dir = File.join(File.dirname(__FILE__), "measures", "CallMetaMeasure", "resources", "inputs", mode)
    results_data[0].each do |col_header|
        next if not col_header.start_with?(key_prefix)
        
        # Get all data from this probability distribution file
        prob_dist_file = File.join(prob_dist_dir, col_header.sub(key_prefix, "") + ".txt")
        headers, rows, param_name, option_names, dep_cols = get_probability_file_data(prob_dist_file, nil)
        
        # Store data
        all_prob_dist_data[param_name] = {"headers"=>headers, 
                                          "rows"=>rows, 
                                          "option_names"=>option_names, 
                                          "dep_cols"=>dep_cols,
                                          "prob_dist_file"=>File.basename(prob_dist_file)}
        param_names[col_header] = param_name
        
    end

    # Data
    results_data_dir = File.join(results_dir, "data")
    if not File.exists? results_data_dir
        Dir.mkdir(results_data_dir)
    end
    all_samples_results = generate_data_output(results_data, param_names, all_prob_dist_data, results_data_dir, key_prefix)
    generate_data_input(results_data, param_names, all_prob_dist_data, results_data_dir)
    
    # Visualization
    results_vis_dir = File.join(results_dir, "visualizations")
    if not File.exists? results_vis_dir
        Dir.mkdir(results_vis_dir)
    end
    html_filenames = generate_visualizations(results_data, param_names, all_prob_dist_data, results_vis_dir, all_samples_results)
    generate_visualizations_index(results_data, param_names, results_vis_dir, html_filenames)
end 

def generate_data_output(results_data, param_names, all_prob_dist_data, results_data_dir, key_prefix)
    # Create map of parameter names to results_file columns
    results_file_cols = {}
    all_prob_dist_data.keys.each do |param_name|
        results_data[0].each_with_index do |col_header, index|
            next if not param_names.keys.include?(col_header)
            
            if col_header == key_prefix + all_prob_dist_data[param_name]["prob_dist_file"].sub(".txt","")
                results_file_cols[param_name] = index
            end
        end
    end

    # Generate sample results output for each reported column in the results csv file
    all_samples_results = {}
    results_data[0].each do |col_header|
        next if not param_names.keys.include?(col_header)
        
        param_name = param_names[col_header]
        headers = all_prob_dist_data[param_name]["headers"]
        option_names = all_prob_dist_data[param_name]["option_names"]
        dep_cols = all_prob_dist_data[param_name]["dep_cols"]
        prob_dist_file = all_prob_dist_data[param_name]["prob_dist_file"]
        
        # Generate combinations of dependency options
        dep_options = []
        dep_cols.keys.each do |dep|
            dep_options << all_prob_dist_data[dep]["option_names"]
        end
        if dep_options.size > 0
            dep_combos = dep_options.first.product(*dep_options[1..-1])
        else
            dep_combos = [[]]
        end
        
        # Get sampling percentages for each option for each combination
        samples_results = []
        dep_combos.each do |dep_combo|
        
            # Init results for this combo
            sample_results = []
            option_names.each do |option_name|
                sample_results << 0
            end
            num_samples = 0
            
            # Calculate results for this combo
            results_data[1..-1].each do |row|
                row_match = true
                dep_cols.keys.each_with_index do |dep_col, index|
                    if row[results_file_cols[dep_col]] != dep_combo[index]
                        row_match = false
                    end
                end
                next if not row_match
                num_samples += 1
                option_names.each_with_index do |option_name, index|
                    next if option_name != row[results_file_cols[param_name]]
                    sample_results[index] += 1
                end
            end
            
            # Error check that sum of option sample numbers equals total number of samples for this combo
            sum_option_samples = 0
            option_names.each_with_index do |option_name, index|
                sum_option_samples += sample_results[index]
            end
            if sum_option_samples != num_samples
                puts "Num samples doesn't match for #{param_name}."
                exit
            end
            
            # Convert num samples to percentage
            if num_samples > 0
                option_names.each_with_index do |option_name, index|
                    sample_results[index] = sample_results[index]/num_samples.to_f
                end 
            end
            
            # Insert dependency option names
            dep_cols.keys.each_with_index do |dep_col, index|
                sample_results.insert(index, dep_combo[index])
            end
            
            # Append number of samples
            sample_results << num_samples
            samples_results << sample_results
        end
        
        # Write *_output.csv
        outfile = File.join(results_data_dir, prob_dist_file.sub(".txt","_output.csv"))
        CSV.open(outfile, "wb") do |csv|
            csv << headers[1] + ["# Samples"]
            samples_results.each do |sample_results|
                csv << sample_results
            end
        end
        
        all_samples_results[col_header] = samples_results
    end
    return all_samples_results
end

def generate_data_input(results_data, param_names, all_prob_dist_data, results_data_dir)
    # Generate probability distribution inputs in compatible form
    results_data[0].each do |col_header|
        next if not param_names.keys.include?(col_header)
        
        param_name = param_names[col_header]
        headers = all_prob_dist_data[param_name]["headers"]
        rows = all_prob_dist_data[param_name]["rows"]
        prob_dist_file = all_prob_dist_data[param_name]["prob_dist_file"]
        
        # Write *_input.csv
        outfile = File.join(results_data_dir, prob_dist_file.sub(".txt","_input.csv"))
        CSV.open(outfile, "wb") do |csv|
            csv << headers[1]
            rows.each do |row|
                csv << row
            end
        end
    end
end

def generate_visualizations(results_data, param_names, all_prob_dist_data, results_vis_dir, all_samples_results)
    # Generate html visualizations via Google
    html_filenames = {}
    results_data[0].each do |col_header|
        next if not param_names.keys.include?(col_header)
        
        param_name = param_names[col_header]
        rows = all_prob_dist_data[param_name]["rows"]
        prob_dist_file = all_prob_dist_data[param_name]["prob_dist_file"]
        dep_cols = all_prob_dist_data[param_name]["dep_cols"]
        headers = all_prob_dist_data[param_name]["headers"]
        
        # Uses a series for each option so that the series legend/color can be assigned
        num_data_series = headers[1].size - dep_cols.size
        
        if num_data_series > 20
            puts "Skipping visualization for #{capitalize_string(param_name)} (too large)..."
            next
        end
        puts "Generating visualization for #{capitalize_string(param_name)}..."
        
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
        <div id="chart_div" style="width: 100%; height: 100%;"></div>
      </body>
    </html>
    }

        # Replace <TITLE_HERE> with html title
        html_text.sub!("<TITLE_HERE>", capitalize_string(param_name))

        # Determine sizes of points
        # FIXME: This should come from the inputs, not outputs
        max_point_size = 15 # pixels
        min_point_size = 5 # pixels
        num_samples = []
        all_samples_results[col_header].each do |result|
            num_samples << result[-1]
        end
        max_num_samples = num_samples.max.to_f
        
        # Replace <TABLE_HEADER_HERE> with the appropriate header
        table_header_html = "['Input', "
        (1..num_data_series).each do |series_num|
            series_name = headers[1][series_num+dep_cols.size-1].to_s
            table_header_html << "'#{series_name}', {'type': 'string', 'role': 'style'},"
        end
        table_header_html << "'Line','Line +20%','Line -20%']"
        html_text.sub!("<TABLE_HEADER_HERE>", table_header_html)
    
        # Replace <TABLE_DATA_HERE> with javascript array based on actual data
        table_data_html = ""
        rows.each_with_index do |row, i|
            next if row.size == 0
            point_size = (num_samples[i]/max_num_samples * (max_point_size.to_f - min_point_size.to_f)).ceil + min_point_size
            row[dep_cols.size..row.size-1].each_with_index do |value, j|
                next if all_samples_results[col_header][i].nil? 
                xval = value
                yval = all_samples_results[col_header][i][j+dep_cols.size]
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
        html_text.sub!("<CHART_TITLE_HERE>", capitalize_string(param_name))
        
        outfile = File.join(results_vis_dir, prob_dist_file.sub(".txt",".html"))
        File.write(outfile, html_text)
        html_filenames[col_header] = File.basename(outfile)
    end
    return html_filenames
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

def capitalize_string(s)
    return s.split.map(&:capitalize).join(' ')
end

def generate_visualizations_index(results_data, param_names, results_vis_dir, html_filenames)
    # Create index.html file
    outfile = File.join(results_vis_dir, "index.html")
    html_text = "<html><head><title>ResStock Visualizations</title></head><body><ul>"
    results_data[0].each do |col_header|
        next if not html_filenames.include?(col_header)
        param_name = param_names[col_header]
        html_text << "<li><a href='#{html_filenames[col_header]}'>#{capitalize_string(param_name)}</a></li>"
    end
    html_text << "</ul></body></html>"
    File.write(outfile, html_text)
    puts "Generating #{File.basename(outfile)} for visualizations..."
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