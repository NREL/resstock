def regenerate_osms
  require 'openstudio'
  require 'json'
  require_relative '../resources/meta_measure'

  OpenStudio::Logger.instance.standardOutLogger.setLogLevel(OpenStudio::Error)

  start_time = Time.now
  num_tot = 0
  num_success = 0

  osw_path = File.expand_path('../../test/osw_files/', __FILE__)
  osm_path = File.expand_path('../../test/osm_files/', __FILE__)

  osw_files = Dir.entries(osw_path).select { |entry| entry.end_with?('.osw') }
  num_osws = osw_files.size

  osw_files.each do |osw|
    # Generate osm from osw
    num_tot += 1

    puts "[#{num_tot}/#{num_osws}] Regenerating osm from #{osw}..."
    osw = File.expand_path("../../test/osw_files/#{osw}", __FILE__)

    update_and_format_osw(osw)
    osw_hash = JSON.parse(File.read(osw))

    # Create measures hashes for top-level measures and other residential measures
    measures = {}
    resources_measures = {}
    osw_hash['steps'].each do |step|
      if ['ResidentialSimulationControls', 'PowerOutage'].include? step['measure_dir_name']
        measures[step['measure_dir_name']] = [step['arguments']]
      else
        resources_measures[step['measure_dir_name']] = [step['arguments']]
      end
    end

    # Apply measures
    model = OpenStudio::Model::Model.new
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    success = apply_measures(File.expand_path('../../measures/', __FILE__), measures, runner, model)
    success = apply_measures(File.expand_path('../../resources/measures', __FILE__), resources_measures, runner, model)

    osm = File.expand_path('../../test/osw_files/in.osm', __FILE__)
    File.open(osm, 'w') { |f| f << model.to_s }

    # Add auto-generated message to top of file
    # Update EPW file paths to be relative for the CircleCI machine
    file_text = File.readlines(osm)
    File.open(osm, 'w') do |f|
      f.write("!- NOTE: Auto-generated from #{osw.gsub(File.dirname(__FILE__), '/test')}\n")
      file_text.each do |file_line|
        # if file_line.strip.start_with?('OS:Weather')
        if file_line.include? 'Url'
          file_data = file_line.split('/')
          epw_name = file_data[-1].split(',')[0]
          if File.exist? File.join(File.dirname(__FILE__), "../resources/measures/HPXMLtoOpenStudio/weather/#{epw_name}")
            file_line = '  ../weather/' + file_data[-1]
          else
            # File not found in weather dir, assume it's in measure's tests dir instead
            file_line = '  ../tests/' + file_data[-1]
          end
        end
        f.write(file_line)
      end
    end

    # Copy to osm dir
    osm_new = File.join(osm_path, File.basename(osw).gsub('.osw', '.osm'))
    FileUtils.mv(osm, osm_new)
    num_success += 1
  end

  puts "Completed. #{num_success} of #{num_tot} osm files were regenerated successfully (#{Time.now - start_time} seconds)."
end

def update_and_format_osw(osw)
  # Insert new step(s) into test osw files, if they don't already exist: {step1=>index1, step2=>index2, ...}
  # e.g., new_steps = {{"measure_dir_name"=>"ResidentialSimulationControls"}=>0}
  new_steps = {}
  json = JSON.parse(File.read(osw), symbolize_names: true)
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
  File.open(osw, 'w') do |f|
    f.write(JSON.pretty_generate(json)) # format nicely even if not updating the osw with new steps
  end
end
