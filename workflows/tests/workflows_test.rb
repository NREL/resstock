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

      all_results << run_and_check(osw, parent_dir)
    end

    results_dir = File.join(parent_dir, "results")
    _rm_path(results_dir)
    write_summary_results(results_dir, all_results)
  end

  private

  def run_and_check(in_osw, parent_dir)
    # Run workflow
    cli_path = OpenStudio.getOpenStudioCLI
    command = "cd #{parent_dir} && \"#{cli_path}\" --no-ssl run -w #{in_osw}"
    system(command)

    # Check all output files exist
    out_osw = File.join(parent_dir, "out.osw")
    assert(File.exists?(out_osw))

    # Check workflow was successful
    data_hash = JSON.parse(File.read(out_osw))
    assert_equal(data_hash["completed_status"], "Success")

    enduse_timeseries = File.join(parent_dir, "run", "enduse_timeseries.csv")
    result = { "OSW" => File.basename(in_osw) }
    sum_enduse_timeseries(result, enduse_timeseries)
    return result
  end

  def sum_enduse_timeseries(result, enduse_timeseries)
    rows = CSV.read(File.expand_path(enduse_timeseries))
    cols = rows.transpose
    cols = cols[1..-1] # remove the Time col
    cols.each do |col|
      vals = col[1..-1].map { |v| v.to_f }
      result[col[0]] = vals.reduce(:+)
    end
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
