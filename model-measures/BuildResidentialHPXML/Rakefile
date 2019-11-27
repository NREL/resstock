require 'rake'
require 'rake/testtask'
require 'ci/reporter/rake/minitest'
require_relative "resources/hpxml"

desc 'update all measures'
task :update_measures do
  # Prevent NREL error regarding U: drive when not VPNed in
  ENV['HOME'] = 'C:' if !ENV['HOME'].nil? and ENV['HOME'].start_with? 'U:'
  ENV['HOMEDRIVE'] = 'C:\\' if !ENV['HOMEDRIVE'].nil? and ENV['HOMEDRIVE'].start_with? 'U:'

  # Apply rubocop
  command = "rubocop --auto-correct --format simple --only Layout"
  puts "Applying rubocop style to measures..."
  system(command)

  create_osws

  puts "Done."
end

def create_osws
  require 'openstudio'

  this_dir = File.dirname(__FILE__)
  tests_dir = File.join(this_dir, "tests")

  # Hash of OSW -> Parent OSW
  osws_files = {
    'base.osw' => nil,
  }

  puts "Generating #{osws_files.size} OSW files..."

  osws_files.each do |derivative, parent|
    print "."

    begin
      osw_files = [derivative]
      unless parent.nil?
        osw_files.unshift(parent)
      end
      while not parent.nil?
        if osws_files.keys.include? parent
          unless osws_files[parent].nil?
            osw_files.unshift(osws_files[parent])
          end
          parent = osws_files[parent]
        end
      end

      workflow = OpenStudio::WorkflowJSON.new
      workflow.setOswPath(File.absolute_path(File.join(tests_dir, derivative)))
      workflow.addMeasurePath(".")
      steps = OpenStudio::WorkflowStepVector.new
      step = OpenStudio::MeasureStep.new("BuildResidentialHPXML")

      osw_files.each do |osw_file|
        step = get_osw_file_osw_values(osw_file, step)
        step = get_osw_file_walls_values(osw_file, step)
      end

      steps.push(step)
      workflow.setWorkflowSteps(steps)
      workflow.save
    rescue Exception => e
      puts "\n#{e}\n#{e.backtrace.join('\n')}"
      puts "\nError: Did not successfully generate #{derivative}."
      exit!
    end
  end
end

def get_osw_file_osw_values(osw_file, step)
  if ['base.osw'].include? osw_file
    step.setArgument("hpxml_output_path", File.absolute_path(File.join(File.dirname(__FILE__), "tests", "run", "in.xml")))
    step.setArgument("unit_type", "single-family detached")
    step.setArgument("unit_multiplier", 1)
    step.setArgument("total_ffa", 2000.0)
    step.setArgument("wall_height", 8.0)
    step.setArgument("num_floors", 2)
    step.setArgument("aspect_ratio", 2.0)
    step.setArgument("garage_width", 0.0)
    step.setArgument("garage_depth", 20.0)
    step.setArgument("garage_protrusion", 0.0)
    step.setArgument("garage_position", "Right")
    step.setArgument("foundation_type", "slab")
    step.setArgument("foundation_height", 3.0)
    step.setArgument("attic_type", "unfinished attic")
    step.setArgument("roof_type", "gable")
    step.setArgument("roof_pitch", "6:12")
    step.setArgument("roof_structure", "truss, cantilever")
    step.setArgument("eaves_depth", 2.0)
    step.setArgument("num_bedrooms", "3")
    step.setArgument("num_bathrooms", "2")
    step.setArgument("num_occupants", "auto")
    step.setArgument("occupants_weekday_sch", "1.00, 1.00, 1.00, 1.00, 1.00, 1.00, 1.00, 0.88, 0.41, 0.24, 0.24, 0.24, 0.24, 0.24, 0.24, 0.24, 0.29, 0.55, 0.90, 0.90, 0.90, 1.00, 1.00, 1.00")
    step.setArgument("occupants_weekend_sch", "1.00, 1.00, 1.00, 1.00, 1.00, 1.00, 1.00, 0.88, 0.41, 0.24, 0.24, 0.24, 0.24, 0.24, 0.24, 0.24, 0.29, 0.55, 0.90, 0.90, 0.90, 1.00, 1.00, 1.00")
    step.setArgument("occupants_monthly_sch", "1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0")
    step.setArgument("neighbor_left_offset", 10.0)
    step.setArgument("neighbor_right_offset", 10.0)
    step.setArgument("neighbor_back_offset", 10.0)
    step.setArgument("neighbor_front_offset", 10.0)
    step.setArgument("orientation", 180.0)
  end
  return step
end

def get_osw_file_walls_values(osw_file, step)
  if ['base-enclosure-walltype-woodstud.osw'].include? osw_file
    step.setArgument("cavity_r", 13)
  end
  return step
end
