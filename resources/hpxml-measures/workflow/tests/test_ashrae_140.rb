# frozen_string_literal: true

require_relative '../../HPXMLtoOpenStudio/resources/minitest_helper'
require 'openstudio'
require 'fileutils'
require 'parallel'
require_relative '../../HPXMLtoOpenStudio/measure.rb'
require_relative 'util.rb'

class WorkflowASHRAE140Test < Minitest::Test
  def test_ashrae_140
    results_dir = File.join(File.dirname(__FILE__), 'test_results')
    FileUtils.mkdir_p results_dir

    test_results_csv = File.join(results_dir, 'results_ashrae_140.csv')
    File.delete(test_results_csv) if File.exist? test_results_csv

    xmls = []
    ashrae140_dir = File.absolute_path(File.join(File.dirname(__FILE__), 'ASHRAE_Standard_140'))
    Dir["#{ashrae140_dir}/*.xml"].sort.each do |xml|
      xmls << File.absolute_path(xml)
    end
    all_results = run_simulation_tests(xmls)

    load_results = {}
    all_results.each do |xml, results|
      htg_load, clg_load = _get_simulation_load_results(results)
      if xml.include? 'C.xml'
        load_results[xml] = [htg_load, 'N/A']
        assert_operator(htg_load, :>, 0)
      elsif xml.include? 'L.xml'
        load_results[xml] = ['N/A', clg_load]
        assert_operator(clg_load, :>, 0)
      end
    end

    htg_loads, clg_loads = _write_ashrae_140_results(load_results, test_results_csv)

    # Check results
    _check_ashrae_140_results(htg_loads, clg_loads)
  end
end
