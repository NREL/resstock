require 'csv'
require File.join(File.dirname(__FILE__), 'measures', 'CallMetaMeasure', 'resources', 'helper_methods')

# This is where results will be located
results_dir = File.join(File.dirname(__FILE__), "sampling_results")
results_vis_dir = File.join(results_dir, "visualizations")
results_data_dir = File.join(results_dir, "data")
if not File.exists? results_dir
    Dir.mkdir(results_dir)
end
if not File.exists? results_vis_dir
    Dir.mkdir(results_vis_dir)
end
if not File.exists? results_data_dir
    Dir.mkdir(results_data_dir)
end

# Read all data from results csv file
results_file = File.join(File.dirname(__FILE__), "analysis_results", "resstock.csv")
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
prob_dist_dir = File.join(File.dirname(__FILE__), "measures", "CallMetaMeasure", "resources", "inputs", "national")
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
        dep_combos = []
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
            sys.exit("Num samples doesn't match.")
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

# Generate html visualizations via Google
results_data[0].each do |col_header|
    next if not param_names.keys.include?(col_header)
    
    param_name = param_names[col_header]
    rows = all_prob_dist_data[param_name]["rows"]
    prob_dist_file = all_prob_dist_data[param_name]["prob_dist_file"]
    dep_cols = all_prob_dist_data[param_name]["dep_cols"]
    
    # Adopted from https://developers.google.com/chart/interactive/docs/gallery/scatterchart
    html_text = %{
<html>
  <head>
    <script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"></script>
    <script type="text/javascript">
      google.charts.load('current', {'packages':['corechart']});
      google.charts.setOnLoadCallback(drawChart);
      function drawChart() {
        var data = google.visualization.arrayToDataTable([
          ['Input', 'Output'],
          // Sample code
          //[ 8,      12],
          //[ 4,      5.5],
          //[ 11,     14]
          <TABLE_HERE>
        ]);

        var options = {
          title: '<TITLE_HERE>',
          hAxis: {title: 'Input', minValue: 0, maxValue: 1},
          vAxis: {title: 'Output', minValue: 0, maxValue: 1},
          legend: 'none'
        };

        var chart = new google.visualization.ScatterChart(document.getElementById('chart_div'));

        chart.draw(data, options);
      }
    </script>
  </head>
  <body>
    <div id="chart_div" style="width: 900px; height: 500px;"></div>
  </body>
</html>
}

    # Replace <TABLE_HERE> with javascript array based on actual data
    table_html = ""
    rows.each_with_index do |row, i|
        row[dep_cols.size..row.size-1].each_with_index do |value, j|
            next if all_samples_results[col_header][i].nil? 
            table_html += "\n[ #{value.to_s}  , #{all_samples_results[col_header][i][j+dep_cols.size].to_s} ],"
        end
    end
    html_text.sub!("<TABLE_HERE>", table_html.chop)
    
    # Replace <TITLE_HERE> with parameter name
    html_text.sub!("<TITLE_HERE>", param_name)
    
    outfile = File.join(results_vis_dir, prob_dist_file.sub(".txt",".html"))
    File.write(outfile, html_text)
    
end