# frozen_string_literal: true

require_relative '../../HPXMLtoOpenStudio/resources/minitest_helper'
require 'openstudio'
require 'fileutils'
require 'parallel'
require_relative '../../HPXMLtoOpenStudio/measure.rb'
require_relative 'util.rb'

class WorkflowACCATest < Minitest::Test
  def test_acca_examples
    results_dir = File.join(File.dirname(__FILE__), 'test_results')
    FileUtils.mkdir_p results_dir

    test_results_csv = File.join(results_dir, 'results_acca.csv')
    Dir.glob("#{File.dirname(test_results_csv)}/#{File.basename(test_results_csv).gsub('.csv', '*.csv')}").each { |file| File.delete(file) }

    acca_files_dir = File.absolute_path(File.join(File.dirname(__FILE__), 'ACCA_Examples'))

    xmls = []
    Dir["#{acca_files_dir}/*.xml"].sort.each do |xml|
      xmls << File.absolute_path(xml)
    end
    all_annual_results = run_simulation_tests(xmls)

    _write_results(all_annual_results.sort_by { |k, _v| k.downcase }.to_h, test_results_csv, output_groups_filter: ['hvac'])
  end
end
