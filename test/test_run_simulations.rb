require_relative 'minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require 'fileutils'
require 'csv'

class RunSimulationTest < MiniTest::Test

  def test_simulations
    num_samples_per_project = 10
    
    top_dir = File.absolute_path(File.join(File.dirname(__FILE__), ".."))
    resources_dir = File.join(top_dir, 'resources')
  
    # Load helper file and sampling file
    require File.join(resources_dir, 'buildstock')
    require File.join(resources_dir, 'run_sampling')
    
    project_dir_names = []
    Dir.entries(top_dir).each do |entry|
        next if not Dir.exist?(entry)
        next if not entry.start_with?("project_")
        project_dir_names << entry
    end
    assert(project_dir_names.size > 0)
  
    project_dir_names.each do |project_dir_name|
      project_dir = File.join(top_dir, project_dir_name)
      characteristics_dir = File.join(project_dir, 'housing_characteristics')
      
      # Copy resources and housing_characteristics to lib for consistency with OpenStudio-server
      lib_dir = File.join(project_dir, 'lib')
      lib_resources_dir = File.join(lib_dir, 'resources')
      lib_characteristics_dir = File.join(lib_dir, 'housing_characteristics')
      FileUtils.mkdir_p lib_resources_dir
      FileUtils.copy_entry resources_dir, lib_resources_dir
      FileUtils.copy_entry characteristics_dir, lib_characteristics_dir
      
      # Generate sampled file
      r = RunSampling.new
      output_file = r.run(project_dir_name, num_samples_per_project, File.join('..',project_dir_name,'lib','housing_characteristics','buildstock.csv'))
      assert(File.exists?(output_file))
      
      # For each building in sampling file...
      CSV.read(output_file, headers:true).each_with_index do |row, idx|
        # FIXME: Temporarily using Placeholder.epw for running the simulations.
        # Otherwise we need to parse the weather zip file, download, and extract it.
        placeholder_epw = File.join(project_dir, 'weather', 'Placeholder.epw')
        out_epw = File.join(project_dir, 'weather', row['Location EPW'])
        FileUtils.copy_file placeholder_epw, out_epw
        
        # Create and run osw
        osw_path = create_osw(row, top_dir, project_dir, idx+1)
        run_osw(osw_path, idx+1, project_dir_name)
        
        # Cleanup epw copy
        FileUtils.rm out_epw
      end
      FileUtils.rm_r lib_dir
    end
    
  end
  
  def create_osw(row, top_dir, project_dir, bldg_id)
    osw_path = File.join(File.dirname(__FILE__), "run.osw")
    osw = OpenStudio::WorkflowJSON.new
    osw.setOswPath(osw_path)
    osw.addMeasurePath(File.join(project_dir, "measures"))
    osw.setSeedFile(File.join(project_dir, "seeds", "EmptySeedModel.osm"))
    
    measures = {}
    measures['BuildExistingModel'] = {}
    measures['BuildExistingModel']['building_id'] = bldg_id
    measures['BuildExistingModel']['workflow_json'] = "measure-info.json"
    
    steps = OpenStudio::WorkflowStepVector.new
    measures.keys.each do |measure|
      step = OpenStudio::MeasureStep.new(measure)
      step.setName(measure)
      measures[measure].each do |arg,val|
        step.setArgument(arg, val)
      end
      steps.push(step)
    end  
    osw.setWorkflowSteps(steps)
    
    # Save OSW
    osw.save
    assert(File.exists?(osw_path))
    
    return osw_path
  end
  
  def run_osw(osw_path, bldg_id, project_dir_name)
    # FIXME: Get latest installed version of openstudio.exe
    os_clis = Dir["C:/openstudio-*/bin/openstudio.exe"] + Dir["/usr/bin/openstudio"] + Dir["/usr/local/bin/openstudio"]
    assert(os_clis.size > 0)
    os_cli = os_clis[-1]
    
    command = "\"#{os_cli}\" run -w \"#{osw_path}\" >> \"#{osw_path.gsub('.osw','.log')}\""
    puts "Running datapoint #{bldg_id} for #{project_dir_name}..."
    system(command)
    
    assert(File.exists?(File.join(File.dirname(osw_path), "run", "eplusout.sql")))
  end

end