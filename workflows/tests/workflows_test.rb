require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require 'fileutils'
require 'json'

class WorkflowTest < MiniTest::Test
  def test_osw
    parent_dir = File.absolute_path(File.join(File.dirname(__FILE__), ".."))
    Dir["#{parent_dir}/*.osw"].each do |osw|
      run_and_check(osw, parent_dir)
    end
  end

  private

  def run_and_check(in_osw, parent_dir)
    # Run energy_rating_index workflow
    cli_path = OpenStudio.getOpenStudioCLI
    command = "cd #{parent_dir} && \"#{cli_path}\" --no-ssl run -w #{in_osw}"
    system(command)

    # Check all output files exist
    out_osw = File.join(parent_dir, "out.osw")
    assert(File.exists?(out_osw))

    # Check workflow was successful
    data_hash = JSON.parse(File.read(out_osw))
    assert_equal(data_hash["completed_status"], "Success")
  end
end
