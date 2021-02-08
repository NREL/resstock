# frozen_string_literal: true

require 'openstudio'
require 'minitest/autorun'

require_relative '../../resources/hpxml-measures/HPXMLtoOpenStudio/resources/minitest_helper'
require_relative '../../resources/buildstock'

class RegressionWorkflowTest < MiniTest::Test
  def test_examples_osw
    all_results = []
    parent_dir = File.absolute_path(File.join(File.dirname(__FILE__), '..'))

    cli_path = OpenStudio.getOpenStudioCLI
    command = "cd #{parent_dir}/.. && \"#{cli_path}\" tasks.rb update_measures"
    system(command)

    create_lib_folder(parent_dir)
    Dir["#{parent_dir}/*.osw"].each do |osw|
      next if File.basename(osw).include? 'out'

      puts "\nOSW: #{osw} ...\n"

      RunOSWs.add_simulation_output_report(osw)
      out_osw, result = RunOSWs.run_and_check(osw, parent_dir)
      result['OSW'] = File.basename(osw)
      all_results << result

      # Check workflow was successful
      assert(File.exist?(out_osw))
      data_hash = JSON.parse(File.read(out_osw))
      assert_equal(data_hash['completed_status'], 'Success')
    end

    results_dir = File.join(parent_dir, 'results')
    RunOSWs._rm_path(results_dir)
    RunOSWs.write_summary_results(results_dir, all_results)
  end

  private

  def create_lib_folder(parent_dir)
    lib_dir = File.join(parent_dir, '../lib') # at top level
    resources_dir = File.join(parent_dir, '../resources')
    Dir.mkdir(lib_dir) unless File.exist?(lib_dir)
    FileUtils.cp_r(resources_dir, lib_dir)
  end
end
