require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require_relative '../../test/minitest_helper'
require 'minitest/autorun'
require 'fileutils'
require 'json'
require 'csv'

class WorkflowTest < MiniTest::Test
  def test_osw
    all_results = []
    parent_dir = File.absolute_path(File.join(File.dirname(__FILE__), ".."))
    Dir["#{parent_dir}/*.osw"].each do |osw|
      next if File.basename(osw).include? "out"

      add_simulation_output_report(osw)
      lib_dir = create_lib_folder(parent_dir)
      all_results << run_and_check(osw, parent_dir)
    end

    results_dir = File.join(parent_dir, "results")
    _rm_path(results_dir)
    write_summary_results(results_dir, all_results)
  end

  private

  def add_simulation_output_report(osw)
    json = JSON.parse(File.read(osw))
    simulation_output_report = { "arguments": { "include_enduse_subcategories": true }, "measure_dir_name": "SimulationOutputReport" }
    json["steps"] << simulation_output_report

    File.open(osw, "w") do |f|
      f.write(JSON.pretty_generate(json))
    end
  end

  def create_lib_folder(parent_dir)
    lib_dir = File.join(parent_dir, "..", "lib") # at top level
    resources_dir = File.join(parent_dir, "..", "resources")
    Dir.mkdir(lib_dir) unless File.exist?(lib_dir)
    FileUtils.cp_r(resources_dir, lib_dir)

    return lib_dir
  end

  def run_and_check(in_osw, parent_dir)
    # Run workflow
    cli_path = OpenStudio.getOpenStudioCLI
    command = "cd #{parent_dir} && \"#{cli_path}\" --no-ssl run -w #{in_osw}"
    simulation_start = Time.now
    system(command)
    sim_time = (Time.now - simulation_start).round(1)

    # Check all output files exist
    out_osw = File.join(parent_dir, "out.osw")
    assert(File.exists?(out_osw))

    # Check workflow was successful
    data_hash = JSON.parse(File.read(out_osw))
    assert_equal(data_hash["completed_status"], "Success")

    data_point_out = File.join(parent_dir, "run", "data_point_out.json")
    result = { "OSW" => File.basename(in_osw) }
    result = get_simulation_output_report(result, data_point_out)
    result["simulation_time"] = sim_time
    return result
  end

  def get_simulation_output_report(result, data_point_out)
    rows = JSON.parse(File.read(File.expand_path(data_point_out)))
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
