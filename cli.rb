### Users of this script: be aware that this will be replaced at some point with a set of classes for 
### targets, queues, and the like. 

require 'optparse'
require 'openstudio-aws'
require 'openstudio-analysis'
require 'fileutils'
require 'pp'
require 'colored'

# Unzip an archive to a destination directory using Rubyzip gem
#
# @param archive [:string] archive path for extraction
# @param dest [:string] path for archived file to be extracted to
def unzip_archive(archive, dest)
  # Adapted from examples at...
  #  https://github.com/rubyzip/rubyzip
  #  http://seenuvasan.wordpress.com/2010/09/21/unzip-files-using-ruby/
  Zip::File.open(archive) do |zf|
    zf.each do |f|
      f_path = File.join(dest, f.name)
      FileUtils.mkdir_p(File.dirname(f_path))
      zf.extract(f, f_path) unless File.exist?(f_path) # No overwrite
    end
  end
end

# Get excel project and return analysis json and zip
#
# @param filename [:string] input path and filename
# @param output_path [:string] path and filename of output location, without extension
# @return aws_instance_options [:hash] parsed options required to define an instance
def process_excel_project(filename, output_path)
  analyses = OpenStudio::Analysis.from_excel(filename)
  if analyses.size != 1
    puts 'ERROR: EXCEL-PROJECT -- More than one seed model specified. This feature is deprecated'.red
    fail 1
  end
  analysis = analyses.first
  analysis.save "#{output_path}.json"
  analysis.save_zip "#{output_path}.zip"

  OpenStudio::Analysis.aws_instance_options(filename)
end

# Get batch measure project and return analysis json and zip
#
# @param filename [:string] input path and filename
# @param output_path [:string] path and filename of the output location, without extension
# @return aws_instance_options if required, otherwise empty hash
def process_csv_project(filename, output_path)
  analysis = OpenStudio::Analysis.from_csv(filename)
  analysis.save "#{output_path}.json"
  analysis.save_zip "#{output_path}.zip"

  OpenStudio::Analysis.aws_instance_options(filename)
end

# Get ruby project and return analysis json and zip
#
# @param filename [:string] input path and filename
# @param output_path [:string] path and filename of output location, without extension
# @return aws_instance_options [:hash] parsed options required to define an instance
def process_rb_project(filename, output_path)
  fail 'This feature is under development'.red
end

# Find url associated with non-aws targets
# TODO: Make a target class with access keys and such not that is referenced here.
#
# @param target_type [:string] Non-aws environment target to get url of
# @return URL of input environment target
def lookup_target_url(target_type)
  server_dns = nil
  case target_type.downcase
    when 'vagrant'
      server_dns = 'http://localhost:8080'
    when 'nrel24'
      server_dns = 'http://bball-130449.nrel.gov:8080'
    when 'nrel24a'
      server_dns = 'http://bball-130553.nrel.gov:8080'
    when 'nrel24b'
      server_dns = 'http://bball-130590.nrel.gov:8080'
    else
      puts "ERROR: TARGET -- Unknown 'target_type' in #{__method__}"
      fail 1
  end

  server_dns
end

# Find or create the target machine 
# 
# @param target_type [:string] Environment to start /find (AWS, NREL***, vagrant)
# @param aws_instance_options [:hash] Number of workers to start. Can be zero
# @return [:osServerAPI] Return OpenStudioServerApi associated with the environment
def find_or_create_target(target_type, aws_instance_options)
  if target_type.downcase == 'aws'
    # Check or create new cluster on AWS
    if File.exist?("#{aws_instance_options[:cluster_name]}.json")
      puts "It appears that a cluster for #{aws_instance_options[:cluster_name]} is already running."
      puts "If this is not the case then delete ./#{aws_instance_options[:cluster_name]}.json file."
      puts "Or run 'bundle exec rake clean'"
      puts 'Will try to continue'

      # Load AWS instance
      aws = OpenStudio::Aws::Aws.new
      aws.load_instance_info_from_file("#{aws_instance_options[:cluster_name]}.json")
      server_dns = "http://#{aws.os_aws.server.data.dns}"
      puts "Server IP address #{server_dns}"

    else
      puts "Creating cluster for #{aws_instance_options[:user_id]}"
      puts 'Starting cluster...'

      # Don't use the old API (Version 1)
      aws = OpenStudio::Aws::Aws.new

      server_options = {
        instance_type: aws_instance_options[:server_instance_type],
        user_id: aws_instance_options[:user_id],
        tags: aws_instance_options[:aws_tags]
      }

      worker_options = {
        instance_type: aws_instance_options[:worker_instance_type],
        user_id: aws_instance_options[:user_id],
        tags: aws_instance_options[:aws_tags]
      }

      start_time = Time.now

      # Create the server & worker
      aws.create_server(server_options)
      aws.save_cluster_info("#{aws_instance_options[:cluster_name]}.json")
      aws.print_connection_info
      aws.create_workers(aws_instance_options[:worker_node_number], worker_options)
      aws.save_cluster_info("#{aws_instance_options[:cluster_name]}.json")
      aws.print_connection_info
      server_dns = "http://#{aws.os_aws.server.data.dns}"

      puts "Cluster setup in #{(Time.now - start_time).round} seconds. Awaiting analyses."
      puts "Server IP address is #{server_dns}"
    end
    OpenStudio::Analysis::ServerApi.new(hostname: server_dns)
  else
    OpenStudio::Analysis::ServerApi.new(hostname: lookup_target_url(target_type))
  end
end

# Execute threadsafe timeout loop for all requests contingent on analysis completion
#
# @param analysis_type [:string]
# @param download_dir [:string]
# @param flags [:hash]
# @param timeout [:fixnum] 
# @return [:hash]
def run_queued_tasks(analysis_type, download_dir, flags, timeout)
  completed = {}
  submit_time = Time.now
  while Time.now - submit_time < timeout
    server_status = @server_api.get_analysis_status(@analysis_id, analysis_type)
     if server_status == 'completed' || server_status == 'failed'
      begin
        puts 'INFO: ANALYSIS STATUS -- Analysis has completed. Attempting to execute queued tasks.' if server_status == 'completed'
        puts 'WARN: ANALYSIS STATUS -- Attempting to execute queued tasks on failed analysis.' if server_status == 'failed'
        # Download results and metadata rdataframe
        if flags[:download] && flags[:rdata]
          @server_api.download_dataframe(@analysis_id, 'rdata', download_dir) #results
          @server_api.download_variables(@analysis_id, 'rdata', download_dir) # metadata
          completed[:rdata] = true
          puts 'INFO: DOWNLOAD STATUS -- RDataFrames have been downloaded.'
        end

        # Download results and metadata csv
        if flags[:download] && flags[:csv]
          @server_api.download_dataframe(@analysis_id, 'csv', download_dir)
          @server_api.download_variables(@analysis_id, 'csv', download_dir)
          completed[:csv] = true
          puts 'INFO: DOWNLOAD STATUS -- CSVs have been downloaded.'
        end

        # Download datapoint directories
        if flags[:download] && flags[:zip]
          dps = @server_api.get_datapoint_status(@analysis_id, 'completed')
          dps_error_count = 0
          if dps.nil? || dps.empty?
            puts 'WARN: ZIP DOWNLOAD -- No datapoints found. Analysis completed with no datapoints'.red
          else
            dps.each do |dp|
              ok, f = @server_api.download_datapoint(dp[:_id], download_dir)
              if ok
                dest = File.join(File.dirname(f), File.basename(f, '.zip'))
                unzip_archive(f, dest)
                File.delete(f)
              else
                puts "ERROR: ZIP DOWNLOAD -- Failed to download data point #{dp[:_id]}"
                dps_error_count += 1
              end
            end
          end
          completed[:zip] = true
          puts "INFO: DOWNLOAD STATUS -- Zip file download complete. #{dps_error_count} of #{dps.count} datapoints failed to download."
        end

        # Stop aws instance
        if flags[:stop]
          aws.stop
          completed[:stop] = true
        end

        # Kill aws instance
        if flags[:kill]
          aws.terminate
          completed[:kill] = true
        end
      rescue => e # Print error message
        puts "ERROR: QUEUED TASKS -- Queued tasks (downloads, stop, or kill) commands erred in #{__method__}".red
        puts "with #{e.message}, #{e.backtrace.join("\n")}".red
      ensure # Return exit status
        return completed
      end
    end
    sleep 1
  end
end

# Run tasks contingent on the completion of the analysis
#
# @param options [:hash]
# @param analysis_type [:aliased string]
# @return [logical] Indicates if any errors were caught
def queued_tasks(options, analysis_type)
  # Initialize variables for queue dependent actions
  submit_time = Time.now #change to submit time for analysis
  rdata_flag = options[:rdata]
  csv_flag = options[:csv]
  zip_flag = options[:zip]
  download_flag = false
  stop_flag = options[:stop]
  kill_flag = options[:kill]
  warnings = []
  start_wait = options[:start_wait]
  analysis_wait = options[:analysis_wait]
  analysis_type = 'batch_run' if OpenStudio::Analysis::ServerApi::BATCH_RUN_METHODS.include? analysis_type

  # Verify download directories and set flags to true should they exist
  if rdata_flag || csv_flag || zip_flag
    if !File.exist? options[:download_directory]
      puts "INFO: MKDIR -- Making new directory for download results at #{options[:download_directory]}"
      Dir.mkdir options[:download_directory]
      download_flag = true
    else
      download_flag = true
    end
  end

  # Hash commands for run_queued_tasks and warning messages
  flags = {download: download_flag, rdata: rdata_flag, csv: csv_flag, zip: zip_flag, stop: stop_flag, kill: kill_flag}
  completed = {rdata: nil, csv: nil, zip: nil, stop: nil, kill: nil}

  # Execute queued tasks should they exist with a Timeout
  puts 'INFO: ANALYSIS STATUS -- Waiting for analysis to start.'
  while Time.now - submit_time < start_wait
    server_status = @server_api.get_analysis_status(@analysis_id, analysis_type)
     if server_status == 'started'
      puts 'INFO: ANALYSIS STATUS -- Analysis has started. Waiting for analysis to complete.'
      returned = run_queued_tasks(analysis_type, options[:download_directory], flags, analysis_wait)
      returned ||= {}
      completed.merge! returned
      break
    elsif server_status == 'failed'
      puts 'WARN: ANALYSIS STATUS -- The analysis status has transitioned to failed. Attempting to execute queued tasks.'
      returned = run_queued_tasks(analysis_type, options[:download_directory], flags, analysis_wait)
      completed.merge! returned
      break
    else
      sleep 1
    end
  end

  # Warn if flags were set to true but code not executed.
  if flags[:rdata]
    warnings << 'WARN: TIMEOUT -- RData results were not downloaded due to timeout' unless completed[:rdata]
  end

  if flags[:csv]
    warnings << 'WARN: TIMEOUT -- CSV results were not downloaded due to timeout' unless completed[:csv]
  end

  if flags[:zip]
    warnings << 'WARN: TIMEOUT -- Zipped files were not downloaded due to timeout' unless completed[:zip]
  end

  if flags[:stop]
    warnings << 'WARN: TIMEOUT -- Instance was not stopped due to timeout' unless completed[:stop]
  end

  if flags[:kill]
    warnings << 'WARN: TIMEOUT -- Instance was not killed due to timeout' unless completed[:kill]
  end

  warnings.join(". ") if warnings != []

end


# Initialize optionsParser ARGV hash
options = {}

# Define allowed ARGV input
# --analysis-wait [integer]
# --server-wait [integer]
# -t --target default 'vagrant'
# -d --download-directory [string] default "./#{@analysis_id}/"
# -p --project [string] no default
# -r --rdataframe
# -c --csv
# -z --zipfiles
# -o --override
optparse = OptionParser.new do |opts|
  opts.banner = 'Usage:    bundle exec ruby cli.rb [-t] <target> [-p] <project> [-d] <download> [-s] [-k] [-o] [-h]'

  options[:target] = 'vagrant'
  opts.on( '-t', '--target <target_alias>', 'target OpenStudio-Server instance') do |server|
    options[:target] = server
  end

  options[:project] = nil
  opts.on('-p', '--project <file>', 'specified project FILE') do |project_file|
    options[:project] = project_file
  end

  options[:download_directory] = './analysis_results'
  opts.on('-d', '--download-directory <DIRECTORY>', 'specified DIRECTORY for downloading all result files') do |download_directory|
    options[:download_directory] = download_directory
  end

  options[:rdata] = false
  opts.on('-r', '--rdataframe', 'download rdataframe results and metadata files') do
    options[:rdata] = true
  end

  options[:csv] = false
  opts.on('-c', '--csv', 'download csv results and metadata files') do
    options[:csv] = true
  end

  options[:zip] = false
  opts.on('-z', '--zip', 'download zip files') do
    options[:zip] = true
  end

  options[:stop] = false
  opts.on('-s', '--stop', 'stop server once completed') do
    options[:stop] = true
  end

  options[:kill] = false
  opts.on('-k', '--kill', 'kill server once completed') do
    options[:kill] = true
  end

  options[:override_safety] = false
  opts.on('-o', '--override-safety', 'allow KILL without DOWNLOAD or allow server to not shutdown') do 
    options[:override_safety] = true
  end

  options[:start_wait] = 1800
  opts.on('--server-wait <INTEGER>', 'seconds to wait for job to start before timeout') do |start_wait|
    options[:start_wait] = start_wait.to_i
  end

  options[:analysis_wait] = 1800
  opts.on('--analysis-wait <INTEGER', 'seconds to wait for job to complete before timeout') do |analysis_wait|
    options[:analysis_wait] = analysis_wait.to_i
  end

  opts.on_tail('-h', '--help', 'display help') do
    puts opts
    exit
  end
end

# Execute ARGV parsing into options hash holding sybolized key values
optparse.parse!

# Check validity of options selected
unless options[:override_safety]
  if options[:kill] && options[:stop]
    fail 'ERROR: ARGV IN -- Both -s and -k entered. Please specify one or the other'
  elsif options[:kill] && (!options[:csv] || !options[:zip] || !options[:rdata])
    fail 'ERROR: ARGV IN -- Override required to keep server spinning after project or to kill the server without downloading'
  end
end

if (options[:target].downcase != 'aws') && options[:kill]
  fail 'ERROR: ARGV IN -- Unable to kill non-aws server'
end

# Process project file and construct cluster options
unless File.exists?(options[:project])
  fail "ERROR: ARGV IN -- Could not find project file #{options[:project]}."
end

unless %w[.rb .xlsx .csv].include? File.extname(options[:project])
  fail 'ERROR: Project file did not have a valid extension (.rb, .csv, or .xlsx)'
end

begin
  # Create temporary folder for server inputs
  Dir.mkdir '.temp' unless File.exist?('.temp')
  temp_filepath = '.temp/analysis'

  # Process project file and retrieve cluster options
  if File.extname(options[:project]).downcase == '.xlsx'
    aws_instance_options = process_excel_project(options[:project], temp_filepath)
  elsif File.extname(options[:project]).downcase == '.rb'
    aws_instance_options = process_rb_project(options[:project], temp_filepath)
  elsif File.extname(options[:project]).downcase == '.csv'
    aws_instance_options = process_csv_project(options[:project], temp_filepath)
  else
    fail "Did not recognize project file extension #{File.extname(options[:project])}"
  end

  # Get OpenStudioServerApi object and ensure the instance is running
  @server_api = find_or_create_target(options[:target], aws_instance_options)

  unless @server_api.machine_status
    fail "ERROR: Target #{options[:target]} server at #{@server_api.hostname} not responding".red
  end

  # Run project on target server
  @analysis_id = @server_api.run("#{temp_filepath}.json","#{temp_filepath}.zip",aws_instance_options[:analysis_type])
ensure
  #Ensure resource cleanup
  FileUtils.rm_r '.temp'
end

# Determine if there are queued tasks
options[:rdata] || options[:csv] || options[:zip] || options[:stop] || options[:kill] ? tasks_queued = true : tasks_queued = false

# Check if queued tasks are set to run
erred = queued_tasks(options, aws_instance_options[:analysis_type]) if tasks_queued
erred ||= nil

# Non-zero exit if errors in queued_tasks
fail erred if erred

# Puts completed
puts 'STATUS: COMPLETE'
