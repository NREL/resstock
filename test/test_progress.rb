require_relative 'minitest_helper'
require 'minitest/autorun'
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), "..")
load 'Rakefile'
require 'csv'

class TestProgress < MiniTest::Test
  def test_progress_example
    results = {}
    Dir[File.join(File.dirname(__FILE__), "../results/*.csv")].each do |filepath|
      table = CSV.parse(File.read(filepath), headers: true)
      num_dps = table.length
      total_site_energy_mbtu = 0.0
      (0...num_dps).each do |row|
        total_site_energy_mbtu += Float(table[row]["simulation_output_report.total_site_energy_mbtu"])
      end

      results["num_dps"] = num_dps
      results["total_site_energy_mbtu"] = total_site_energy_mbtu
      CSV.open(File.join(File.dirname(__FILE__), "../results/results.csv"), "wb") {|csv| results.to_a.each {|e| csv << e} }
    end
  end
end
