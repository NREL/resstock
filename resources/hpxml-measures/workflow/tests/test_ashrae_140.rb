# frozen_string_literal: true

require_relative '../../HPXMLtoOpenStudio/resources/minitest_helper'
require 'openstudio'
require 'fileutils'
require 'parallel'
require_relative '../../HPXMLtoOpenStudio/measure.rb'
require_relative 'util.rb'

class WorkflowASHRAE140Test < Minitest::Test
  def test_simulations_ashrae_140
    results_dir = File.join(File.dirname(__FILE__), 'results')
    FileUtils.mkdir_p results_dir

    results_out = File.join(results_dir, 'results_ashrae_140.csv')
    File.delete(results_out) if File.exist? results_out

    xmls = []
    ashrae140_dir = File.absolute_path(File.join(File.dirname(__FILE__), 'ASHRAE_Standard_140'))
    Dir["#{ashrae140_dir}/*.xml"].sort.each do |xml|
      xmls << File.absolute_path(xml)
    end
    all_results = run_simulation_tests(xmls)

    _write_ashrae_140_results(all_results.sort_by { |k, _v| k.downcase }.to_h, results_out)
  end

  def _write_ashrae_140_results(all_results, csv_out)
    require 'csv'

    htg_loads = {}
    clg_loads = {}
    CSV.open(csv_out, 'w') do |csv|
      csv << ['Test Case', 'Annual Heating Load [MMBtu]', 'Annual Cooling Load [MMBtu]']
      all_results.sort.each do |xml, xml_results|
        next unless xml.include? 'C.xml'

        htg_load = xml_results['Load: Heating: Delivered (MBtu)'].round(2)
        csv << [File.basename(xml), htg_load, 'N/A']
        test_name = File.basename(xml, File.extname(xml))
        htg_loads[test_name] = htg_load
      end
      all_results.sort.each do |xml, xml_results|
        next unless xml.include? 'L.xml'

        clg_load = xml_results['Load: Cooling: Delivered (MBtu)'].round(2)
        csv << [File.basename(xml), 'N/A', clg_load]
        test_name = File.basename(xml, File.extname(xml))
        clg_loads[test_name] = clg_load
      end
    end

    puts "Wrote ASHRAE 140 results to #{csv_out}."
  end
end
