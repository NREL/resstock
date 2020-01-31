require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require_relative 'minitest_helper'
require 'minitest/autorun'
require 'fileutils'
require 'json'
require_relative '../resources/run_sampling'

class TestResStockMeasuresOSW < MiniTest::Test
  def test_measures_osw
    project_dir = "project_testing"
    num_samples = 1

    parent_dir = File.absolute_path(File.join(File.dirname(__FILE__), "test_measures_osw"))

    buildstock_csv = create_buildstock_csv(project_dir, num_samples)
    lib_dir = create_lib_folder(parent_dir, project_dir, buildstock_csv)
    weather_dir = create_weather_folder(parent_dir, project_dir)

    measures_osw_dir = File.join(parent_dir, "measures_osw")
    Dir.mkdir(measures_osw_dir) unless File.exist?(measures_osw_dir)
    (1..num_samples).to_a.each do |building_id|
      Dir["#{parent_dir}/build_existing_model.osw"].each do |osw|
        change_building_id(osw, building_id)
        run_and_check(osw, parent_dir, measures_osw_dir, building_id)
      end
    end

    Dir["#{parent_dir}/build_existing_model.osw"].each do |osw|
      change_building_id(osw, 1)
    end

    FileUtils.rm_rf(lib_dir) if File.exist?(lib_dir)
    FileUtils.rm_rf(weather_dir) if File.exist?(weather_dir)
    FileUtils.rm_rf(File.join(parent_dir, "run"))
    FileUtils.rm_rf(File.join(parent_dir, "reports"))
  end

  def run_and_check(in_osw, parent_dir, measures_osw_dir, building_id)
    # Create measures.osw
    cli_path = OpenStudio.getOpenStudioCLI
    command = "cd #{parent_dir} && \"#{cli_path}\" --no-ssl run -w #{in_osw}"
    system(command)

    # Check output file exists
    out_osw = File.join(parent_dir, "out.osw")
    new_out_osw = File.join(measures_osw_dir, "#{building_id}.osw")
    FileUtils.mv(out_osw, new_out_osw)
    assert(File.exists?(new_out_osw))

    # Check workflow was successful
    data_hash = JSON.parse(File.read(new_out_osw))
    assert_equal(data_hash["completed_status"], "Success")
  end

  def create_buildstock_csv(project_dir, num_samples)
    outfile = File.join("..", "test", "test_measures_osw", "buildstock.csv")
    r = RunSampling.new
    r.run(project_dir, num_samples, outfile)

    return outfile
  end

  def create_lib_folder(parent_dir, project_dir, buildstock_csv)
    lib_dir = File.join(parent_dir, "..", "..", "lib") # at top level
    resources_dir = File.join(parent_dir, "..", "..", "resources")
    housing_characteristics_dir = File.join(parent_dir, "..", "..", project_dir, "housing_characteristics")
    Dir.mkdir(lib_dir) unless File.exist?(lib_dir)
    FileUtils.cp_r(resources_dir, lib_dir)
    FileUtils.cp_r(housing_characteristics_dir, lib_dir)
    FileUtils.cp(File.join(resources_dir, buildstock_csv), File.join(lib_dir, "housing_characteristics"))

    return lib_dir
  end

  def create_weather_folder(parent_dir, project_dir)
    src = File.join(parent_dir, "..", "..", "resources", "measures", "HPXMLtoOpenStudio", "weather", project_dir)
    des = File.join(parent_dir, "..", "..", "weather")
    FileUtils.cp_r(src, des)

    return des
  end

  def change_building_id(osw, building_id)
    json = JSON.parse(File.read(osw), symbolize_names: true)
    json[:steps].each do |measure|
      next if measure[:measure_dir_name] != "BuildExistingModel"

      measure[:arguments][:building_id] = "#{building_id}"
    end
    File.open(osw, "w") do |f|
      f.write(JSON.pretty_generate(json))
    end
  end
end
