# frozen_string_literal: true

require_relative '../../HPXMLtoOpenStudio/resources/minitest_helper'
require 'openstudio'
require 'fileutils'
require 'parallel'
require_relative '../../HPXMLtoOpenStudio/measure.rb'
require_relative 'util.rb'

class WorkflowRealHomesTest < Minitest::Test
  def test_simulations_real_homes
    results_dir = File.join(File.dirname(__FILE__), 'results')
    FileUtils.mkdir_p results_dir

    results_out = File.join(results_dir, 'results_real_homes.csv')
    bills_out = File.join(results_dir, 'results_real_homes_bills.csv')
    File.delete(results_out) if File.exist? results_out
    File.delete(bills_out) if File.exist? bills_out

    hpxml_files_dir = File.absolute_path(File.join(File.dirname(__FILE__), '..', 'real_homes'))
    all_results, all_results_bills = run_simulation_tests(hpxml_files_dir)

    _write_results(all_results.sort_by { |k, _v| k.downcase }.to_h, results_out)
    _write_results(all_results_bills.sort_by { |k, _v| k.downcase }.to_h, bills_out)
  end
end
