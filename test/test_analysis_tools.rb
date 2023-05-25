# frozen_string_literal: true

require_relative '../resources/hpxml-measures/HPXMLtoOpenStudio/resources/minitest_helper'
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

      buildstockbatch_extras = buildstockbatch.headers - run_analysis.headers
      buildstockbatch_extras -= ['apply_upgrade.applicable']
      buildstockbatch_extras -= ['apply_upgrade.upgrade_name']
      buildstockbatch_extras -= ['apply_upgrade.reference_scenario']
      puts "#{project}_baseline, buildstockbatch - run_analysis: #{buildstockbatch_extras}" if !buildstockbatch_extras.empty?

      run_analysis_extras = run_analysis.headers - buildstockbatch.headers
      puts "#{project}_baseline, run_analysis - buildstockbatch: #{run_analysis_extras}" if !run_analysis_extras.empty?

      assert_equal(0, buildstockbatch_extras.size)
      assert_equal(0, run_analysis_extras.size)
    end
  end

  def test_upgrades_columns
    ['national', 'testing'].each do |project|
      buildstockbatch_path = File.join(@buildstock_directory, "buildstockbatch/project_#{project}/#{project}_upgrades/results_csvs/results_up15.csv")
      buildstockbatch = CSV.read(buildstockbatch_path, headers: true)

      run_analysis_path = File.join(@buildstock_directory, "run_analysis/project_#{project}/results-AllUpgrades.csv")
      run_analysis = CSV.read(run_analysis_path, headers: true)

      buildstockbatch_extras = buildstockbatch.headers - run_analysis.headers
      buildstockbatch_extras -= ['apply_upgrade.reference_scenario']
      buildstockbatch_extras -= ['simulation_output_report.applicable'] # buildstockbatch contains simulation_output_report.applicable (old workflow)
      buildstockbatch_extras -= ['upgrade_costs.option_04_name'] # buildstockbatch writes this because another upgrade (Lighting) has 4 options; see https://github.com/NREL/buildstockbatch/pull/271
      if project == 'national'
        # buildstockbatch has these column even though it's all null (because of join with baseline?)
        buildstockbatch_extras -= ['report_simulation_output.emissions_co_2_e_lrmer_mid_case_15_natural_gas_heating_lb']
        buildstockbatch_extras -= ['report_simulation_output.emissions_co_2_e_lrmer_mid_case_15_natural_gas_hot_water_lb']
      elsif project == 'testing'
        # buildstockbatch has these column even though it's all null (because of join with baseline?)
        buildstockbatch_extras -= ['report_simulation_output.emissions_co_2_e_lrmer_mid_case_15_fuel_oil_heating_lb']
        buildstockbatch_extras -= ['report_simulation_output.emissions_co_2_e_lrmer_mid_case_15_fuel_oil_total_lb']
        buildstockbatch_extras -= ['report_simulation_output.emissions_co_2_e_lrmer_mid_case_15_natural_gas_heating_lb']
        buildstockbatch_extras -= ['report_simulation_output.emissions_co_2_e_lrmer_mid_case_15_natural_gas_hot_water_lb']
        buildstockbatch_extras -= ['report_simulation_output.emissions_co_2_e_lrmer_mid_case_15_propane_heating_lb']
        buildstockbatch_extras -= ['report_simulation_output.emissions_co_2_e_lrmer_mid_case_15_propane_hot_water_lb']
        buildstockbatch_extras -= ['report_simulation_output.emissions_co_2_e_lrmer_mid_case_15_propane_total_lb']
        buildstockbatch_extras -= ['report_utility_bills.bills_fuel_oil_energy_usd']
        buildstockbatch_extras -= ['report_utility_bills.bills_fuel_oil_total_usd']
        buildstockbatch_extras -= ['report_utility_bills.bills_propane_energy_usd']
        buildstockbatch_extras -= ['report_utility_bills.bills_propane_total_usd']
      end
      puts "#{project}_upgrades, buildstockbatch - run_analysis: #{buildstockbatch_extras}" if !buildstockbatch_extras.empty?

      run_analysis_extras = run_analysis.headers - buildstockbatch.headers
      puts "#{project}_upgrades, run_analysis - buildstockbatch: #{run_analysis_extras}" if !run_analysis_extras.empty?

      assert_equal(0, buildstockbatch_extras.size)
      assert_equal(0, run_analysis_extras.size)
    end
  end

  def test_baseline_results
    columns = ['report_simulation_output.energy_use_total_m_btu']

    ['national', 'testing'].each do |project|
      buildstockbatch_path = File.join(@buildstock_directory, "buildstockbatch/project_#{project}/#{project}_baseline/results_csvs/results_up00.csv")
      buildstockbatch = CSV.read(buildstockbatch_path, headers: true)

      run_analysis_path = File.join(@buildstock_directory, "run_analysis/project_#{project}/results-Baseline.csv")
      run_analysis = CSV.read(run_analysis_path, headers: true)

      columns.each do |col|
        buildstockbatch_sum = buildstockbatch[col].map { |v| Float(v) }.sum
        run_analysis_sum = run_analysis[col].map { |v| Float(v) }.sum

        assert_equal(buildstockbatch[col].size, run_analysis[col].size)
        assert_in_delta(buildstockbatch_sum, run_analysis_sum, 0.01)
      end
    end
  end

  def test_upgrades_results
    columns = ['report_simulation_output.energy_use_total_m_btu']

    ['national', 'testing'].each do |project|
      buildstockbatch_path = File.join(@buildstock_directory, "buildstockbatch/project_#{project}/#{project}_upgrades/results_csvs/results_up15.csv")
      buildstockbatch = CSV.read(buildstockbatch_path, headers: true)

      run_analysis_path = File.join(@buildstock_directory, "run_analysis/project_#{project}/results-AllUpgrades.csv")
      run_analysis = CSV.read(run_analysis_path, headers: true)

      columns.each do |col|
        buildstockbatch_sum = buildstockbatch[col].map { |v| Float(v) }.sum
        run_analysis_sum = run_analysis[col].map { |v| Float(v) }.sum

        assert_equal(buildstockbatch[col].size, run_analysis[col].size)
        assert_in_delta(buildstockbatch_sum, run_analysis_sum, 0.01)
      end
    end
  end
end
