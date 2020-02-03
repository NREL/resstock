require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require_relative '../../test/minitest_helper'
require 'minitest/autorun'
require 'fileutils'
require 'json'
require_relative '../../resources/run_sampling'

class TestResStockMeasuresOSW < MiniTest::Test
  def test_build_existing_model
    parent_dir = File.absolute_path(File.join(File.dirname(__FILE__), ".."))
    num_samples = 1
    if ENV.keys.include? "NUM_SAMPLES"
      num_samples = Integer(ENV["NUM_SAMPLES"])
    end
    measures_osw_dir = File.join(parent_dir, "measures_osws")
    Dir.mkdir(measures_osw_dir) unless File.exist?(measures_osw_dir)

    weather_dir = create_weather_folder(parent_dir)

    all_results = []
    Dir["project_*"].each do |project_dir|
      next if project_dir.include? "testing" or project_dir.include? "zip"

      buildstock_csv = create_buildstock_csv(project_dir, num_samples)
      lib_dir = create_lib_folder(parent_dir, project_dir, buildstock_csv)

      Dir.mkdir(measures_osw_dir) unless File.exist?(measures_osw_dir)
      (1..num_samples).to_a.each do |building_id|
        Dir["#{parent_dir}/build_existing_model.osw"].each do |osw|
          change_building_id(osw, building_id)
          all_results << run_and_check(osw, parent_dir, measures_osw_dir, building_id, project_dir)
        end
      end

      Dir["#{parent_dir}/build_existing_model.osw"].each do |osw|
        change_building_id(osw, 1)
      end

      _rm_path(lib_dir)
    end

    _rm_path(weather_dir)

    results_dir = File.join(parent_dir, "build_existing_model_results")
    _rm_path(results_dir)
    write_summary_results(results_dir, all_results)
  end

  private

  def run_and_check(in_osw, parent_dir, measures_osw_dir, building_id, project_dir)
    # Create measures.osw
    cli_path = OpenStudio.getOpenStudioCLI
    command = "cd #{parent_dir} && \"#{cli_path}\" --no-ssl run -w #{in_osw}"
    simulation_start = Time.now
    system(command)
    sim_time = (Time.now - simulation_start).round(1)

    # Check output file exists
    out_osw = File.join(parent_dir, "out.osw")
    measures_osw = File.join(parent_dir, "run", "measures.osw")
    new_measures_osw = File.join(measures_osw_dir, "#{building_id}_#{project_dir}.osw")
    FileUtils.mv(measures_osw, new_measures_osw)
    assert(File.exists?(new_measures_osw))

    # Check workflow was successful
    data_hash = JSON.parse(File.read(out_osw))
    assert_equal(data_hash["completed_status"], "Success")

    data_point_out = File.join(parent_dir, "run", "data_point_out.json")
    result = {
      "OSW" => File.basename(new_measures_osw),
      "PROJECT" => project_dir,
      "SIM_TIME" => sim_time
    }
    result = get_output_report(result, data_point_out)
    return result
  end

  def create_buildstock_csv(project_dir, num_samples)
    outfile = File.join("..", "workflows", "buildstock.csv")
    r = RunSampling.new
    r.run(project_dir, num_samples, outfile)

    return outfile
  end

  def create_lib_folder(parent_dir, project_dir, buildstock_csv)
    lib_dir = File.join(parent_dir, "..", "lib") # at top level
    resources_dir = File.join(parent_dir, "..", "resources")
    housing_characteristics_dir = File.join(parent_dir, "..", project_dir, "housing_characteristics")
    Dir.mkdir(lib_dir) unless File.exist?(lib_dir)
    FileUtils.cp_r(resources_dir, lib_dir)
    FileUtils.cp_r(housing_characteristics_dir, lib_dir)
    FileUtils.cp(File.join(resources_dir, buildstock_csv), File.join(lib_dir, "housing_characteristics"))

    return lib_dir
  end

  def create_weather_folder(parent_dir)
    require 'aws-sdk-s3'

    Aws.config.update({
                        region: 'us-east-1',
                        access_key_id: ENV['AWS_ACCESS_KEY_ID'],
                        secret_access_key: ENV['AWS_SECRET_ACCESS_KEY']
                      })
    Aws.use_bundled_cert!

    s3 = Aws::S3::Resource.new
    bucket = s3.bucket("epwweatherfiles")

    filename = "project_resstock_national.zip"
    obj = bucket.object(filename)
    response_target = File.join(parent_dir, "..", filename)
    # obj.get(response_target: response_target)

    des = File.join(parent_dir, "..", "weather")

    response_target_zip = OpenStudio::toPath(response_target)
    unzip_file = OpenStudio::UnzipFile.new(response_target_zip)
    unzip_file.extractAllFiles(des)

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

  def get_output_report(result, data_point_out)
    rows = JSON.parse(File.read(File.expand_path(data_point_out)))
    result = result.merge(rows["BuildExistingModel"])
    result = result.merge(rows["SimulationOutputReport"])
    result.delete("applicable")
    result.delete("upgrade_name")
    result.delete("upgrade_cost_usd")
    return result
  end

  def write_summary_results(results_dir, results)
    Dir.mkdir(results_dir)
    csv_out = File.join(results_dir, "results.csv")

    column_headers = results[0].keys.sort
    CSV.open(csv_out, "wb") do |csv|
      csv << column_headers
      results.each do |result|
        csv_row = []
        column_headers.each do |column_header|
          csv_row << result[column_header]
        end
        csv << csv_row
      end
    end
  end

  def _rm_path(path)
    if Dir.exists?(path)
      FileUtils.rm_r(path)
    end
    while true
      break if not Dir.exists?(path)

      sleep(0.01)
    end
  end
end
