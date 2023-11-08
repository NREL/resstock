# frozen_string_literal: true

require_relative '../../HPXMLtoOpenStudio/resources/minitest_helper'
require 'openstudio'
require 'fileutils'
require 'parallel'
require_relative '../../HPXMLtoOpenStudio/measure.rb'
require_relative 'util.rb'

class WorkflowSimulations1Test < Minitest::Test
  def test_simulations1
    results_dir = File.join(File.dirname(__FILE__), 'results')
    FileUtils.mkdir_p results_dir

    results_out = File.join(results_dir, 'results_workflow_simulations1.csv')
    bills_out = File.join(results_dir, 'results_workflow_simulations1_bills.csv')
    File.delete(results_out) if File.exist? results_out
    File.delete(bills_out) if File.exist? bills_out

    sample_files_dir = File.absolute_path(File.join(File.dirname(__FILE__), '..', 'sample_files'))
    real_homes_dir = File.absolute_path(File.join(File.dirname(__FILE__), '..', 'real_homes'))

    # Run simulations BEFORE base-lighting*.xml; the remaining simulations are run using test_simulations2.rb
    # This distributes the simulations across two CI jobs for faster turnaround time.
    split_at_file = Dir["#{sample_files_dir}/*.xml"].sort.find_index { |f| f.include? 'base-lighting' }
    fail 'Unexpected error.' if split_at_file.nil?

    xmls = []
    [sample_files_dir, real_homes_dir].each do |hpxml_files_dir|
      Dir["#{hpxml_files_dir}/*.xml"].sort.each do |xml|
        xmls << File.absolute_path(xml)
      end
    end
    xmls = xmls[0..split_at_file - 1]
    all_results, all_results_bills = run_simulation_tests(xmls)

    _write_results(all_results.sort_by { |k, _v| k.downcase }.to_h, results_out)
    _write_results(all_results_bills.sort_by { |k, _v| k.downcase }.to_h, bills_out)
  end
end
