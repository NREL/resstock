# frozen_string_literal: true

require 'minitest/autorun'
require 'csv'

class TestTools < MiniTest::Test
  def before_setup
    @buildstock_directory = File.join(File.dirname(__FILE__), '..')
  end

  def test_baseline_columns
    ['national', 'testing'].each do |project|
      buildstockbatch_path = File.join(@buildstock_directory, "buildstockbatch/project_#{project}/#{project}_baseline/results_csvs/results_up00.csv")
      buildstockbatch = CSV.read(buildstockbatch_path, headers: true)

      run_analysis_path = File.join(@buildstock_directory, "run_analysis/project_#{project}/results-Baseline.csv")
      run_analysis = CSV.read(run_analysis_path, headers: true)

      puts "\n#{project}_baseline"

      buildstockbatch_extras = buildstockbatch.headers - run_analysis.headers
      puts "buildstockbatch - run_analysis: #{buildstockbatch_extras}"

      run_analysis_extras = run_analysis.headers - buildstockbatch.headers
      puts "run_analysis - buildstockbatch: #{run_analysis_extras}"

      buildstockbatch_extras -= ['apply_upgrade.applicable', 'apply_upgrade.upgrade_name', 'apply_upgrade.reference_scenario']
      assert_equal(0, buildstockbatch_extras.size)

      assert_equal(0, run_analysis_extras.size)
    end
  end

  def test_upgrades_columns
    ['national', 'testing'].each do |project|
      buildstockbatch_path = File.join(@buildstock_directory, "buildstockbatch/project_#{project}/#{project}_upgrades/results_csvs/results_up13.csv")
      buildstockbatch = CSV.read(buildstockbatch_path, headers: true)

      run_analysis_path = File.join(@buildstock_directory, "run_analysis/project_#{project}/results-AllUpgrades.csv")
      run_analysis = CSV.read(run_analysis_path, headers: true)

      puts "\n#{project}_upgrades"

      buildstockbatch_extras = buildstockbatch.headers - run_analysis.headers
      puts "buildstockbatch - run_analysis: #{buildstockbatch_extras}"

      run_analysis_extras = run_analysis.headers - buildstockbatch.headers
      puts "run_analysis - buildstockbatch: #{run_analysis_extras}"

      buildstockbatch_extras -= ['apply_upgrade.reference_scenario', 'simulation_output_report.applicable'] # TODO: remove simulation_output_report.applicable from buildstockbatch
      assert_equal(0, buildstockbatch_extras.size)

      assert_equal(0, run_analysis_extras.size)
    end
  end
end
