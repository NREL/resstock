# frozen_string_literal: true

require 'openstudio'
require 'minitest/autorun'

require_relative '../../resources/hpxml-measures/HPXMLtoOpenStudio/resources/minitest_helper'
require_relative '../../resources/buildstock'

class RegressionWorkflowTest < MiniTest::Test
  def before_setup
    @top_dir = File.absolute_path(File.join(File.dirname(__FILE__), '..'))
    @lib_dir = File.join(@top_dir, '..', 'lib')
    @resources_dir = File.join(@top_dir, '..', 'resources')
  end

  def after_teardown
    FileUtils.rm_rf(@lib_dir) if File.exist?(@lib_dir)
    FileUtils.rm_rf(File.join(@top_dir, 'run'))
    FileUtils.rm_rf(File.join(@top_dir, 'reports'))
    FileUtils.rm_rf(File.join(@top_dir, 'generated_files'))
    FileUtils.rm(File.join(@top_dir, 'out.osw'))
  end

  def test_examples_osw
    all_results = []

    cli_path = OpenStudio.getOpenStudioCLI
    command = "cd #{@top_dir}/.. && \"#{cli_path}\" tasks.rb update_measures"
    system(command)

    create_lib_folder

    Dir["#{@top_dir}/*.osw"].each do |osw|
      next if File.basename(osw).include? 'out'

      puts "\nOSW: #{osw} ...\n"

      RunOSWs.add_simulation_output_report(osw)
      out_osw, result = RunOSWs.run_and_check(osw, @top_dir)
      result['OSW'] = File.basename(osw)
      if osw.include?('single_family_detached')
        result['build_existing_model.geometry_building_type_recs'] = 'Single-Family Detached'
      elsif osw.include?('single_family_attached')
        result['build_existing_model.geometry_building_type_recs'] = 'Single-Family Attached'
      elsif osw.include?('multifamily')
        result['build_existing_model.geometry_building_type_recs'] = 'Multi-Family with 5+ Units'
      end
      result['build_existing_model.county'] = 'CO, Denver County'
      all_results << result

      # Check workflow was successful
      assert(File.exist?(out_osw))
      data_hash = JSON.parse(File.read(out_osw))
      assert_equal(data_hash['completed_status'], 'Success')
    end

    results_dir = File.join(@top_dir, 'results')
    RunOSWs._rm_path(results_dir)
    RunOSWs.write_summary_results(results_dir, all_results, 'feature.csv')
  end

  private

  def create_lib_folder
    Dir.mkdir(@lib_dir) unless File.exist?(@lib_dir)
    FileUtils.cp_r(@resources_dir, @lib_dir)
  end
end
