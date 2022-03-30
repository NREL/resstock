# frozen_string_literal: true

require_relative '../resources/hpxml-measures/HPXMLtoOpenStudio/resources/minitest_helper'
require 'minitest/autorun'
require 'openstudio'
require_relative '../resources/buildstock'

class TestRunAnalysis < MiniTest::Test
  def before_setup
    cli_path = OpenStudio.getOpenStudioCLI
    @command = "\"#{cli_path}\" workflow/run_analysis.rb"

    workflow_dir = File.join(File.dirname(__FILE__), '../workflow')
    @testing_baseline = File.join(workflow_dir, 'testing_baseline')
    @national_baseline = File.join(workflow_dir, 'national_baseline')
    @testing_upgrades = File.join(workflow_dir, 'testing_upgrades')
    @national_upgrades = File.join(workflow_dir, 'national_upgrades')

    # check that all results_output.csv contain these columns
    @expected_baseline_columns = [
      'building_id',
      'job_id',
      'completed_status',
      'report_simulation_output.add_timeseries_dst_column',
      'report_simulation_output.add_timeseries_utc_column',
      'report_simulation_output.energy_use_total_m_btu',
      'report_simulation_output.energy_use_net_m_btu',
      'report_simulation_output.fuel_use_electricity_total_m_btu',
      'report_simulation_output.end_use_natural_gas_heating_m_btu',
      'report_simulation_output.emissions_co_2_e_lrmer_mid_case_15_total_lb',
      'upgrade_costs.door_area_ft_2',
      'qoi_report.qoi_average_maximum_daily_timing_cooling_hour'
    ]

    # check that only projects with upgrades contain these columns
    @expected_upgrades_columns = @expected_baseline_columns + [
      'apply_upgrade.option_01_cost_1_multiplier_to_apply'
    ]

    # check that select columns aren't completely empty
    @expected_nonnull_columns = [
      'report_simulation_output.energy_use_net_m_btu',
      'apply_upgrade.upgrade_name',
      'upgrade_costs.door_area_ft_2',
      'upgrade_costs.option_01_name',
      'upgrade_costs.option_01_cost_usd'
    ]

    # check that select columns aren't all zeros
    @expected_nonzero_columns = [
      'report_simulation_output.energy_use_total_m_btu',
      'upgrade_costs.upgrade_cost_usd'
    ]
  end

  def test_version
    @command += ' -v'

    cli_output = `#{@command}`

    assert("#{Version.software_program_used} v#{Version.software_program_version}", cli_output)
  end

  def test_errors
    yml = ' -y test/yml_bad_value/testing_baseline.yml'
    @command += yml

    cli_output = `#{@command}`

    assert(File.read(File.join(@testing_baseline, 'cli_output.log')).include?('ERROR'))
    assert(cli_output.include?('Failures detected for: 1, 2.'))

    FileUtils.rm_rf(@testing_baseline)
  end

  def test_testing_baseline
    yml = ' -y project_testing/testing_baseline.yml'
    @command += yml

    system(@command)

    assert(File.exist?(File.join(@testing_baseline, 'cli_output.log')))
    assert(!File.read(File.join(@testing_baseline, 'cli_output.log')).include?('ERROR'))

    assert(File.exist?(File.join(@testing_baseline, 'osw', 'Baseline', '1.osw')))
    assert(File.exist?(File.join(@testing_baseline, 'xml', 'Baseline', '1.xml')))

    assert(File.exist?(File.join(@testing_baseline, 'results_characteristics.csv')))
    assert(File.exist?(File.join(@testing_baseline, 'results_output.csv')))

    results_output = CSV.read(File.join(@testing_baseline, 'results_output.csv'), headers: true)
    assert((@expected_baseline_columns - results_output.headers).empty?)
    assert(!(@expected_upgrades_columns - results_output.headers).empty?)
    @expected_nonnull_columns.each do |col|
      next if !results_output.headers.include?(col)

      assert(!results_output[col].all? { |i| i.nil? })
    end
    @expected_nonzero_columns.each do |col|
      next if !results_output.headers.include?(col)

      assert(!results_output[col].all? { |i| i == 0 })
    end

    FileUtils.rm_rf(@testing_baseline)
  end

  def test_national_baseline
    yml = ' -y project_national/national_baseline.yml'
    @command += yml

    system(@command)

    assert(File.exist?(File.join(@national_baseline, 'cli_output.log')))
    assert(!File.read(File.join(@national_baseline, 'cli_output.log')).include?('ERROR'))

    assert(File.exist?(File.join(@national_baseline, 'osw', 'Baseline', '1.osw')))
    assert(File.exist?(File.join(@national_baseline, 'xml', 'Baseline', '1.xml')))

    assert(File.exist?(File.join(@national_baseline, 'results_characteristics.csv')))
    assert(File.exist?(File.join(@national_baseline, 'results_output.csv')))

    results_output = CSV.read(File.join(@national_baseline, 'results_output.csv'), headers: true)
    assert((@expected_baseline_columns - results_output.headers).empty?)
    assert(!(@expected_upgrades_columns - results_output.headers).empty?)
    @expected_nonnull_columns.each do |col|
      next if !results_output.headers.include?(col)

      assert(!results_output[col].all? { |i| i.nil? })
    end
    @expected_nonzero_columns.each do |col|
      next if !results_output.headers.include?(col)

      assert(!results_output[col].all? { |i| i == 0 })
    end

    FileUtils.rm_rf(@national_baseline)
  end

  def test_testing_upgrades
    yml = ' -y project_testing/testing_upgrades.yml'
    @command += yml
    @command += ' -d'

    system(@command)

    assert(File.exist?(File.join(@testing_upgrades, 'cli_output.log')))
    assert(!File.read(File.join(@testing_upgrades, 'cli_output.log')).include?('ERROR'))

    assert(File.exist?(File.join(@testing_upgrades, 'osw', 'Baseline', '1-existing.osw')))
    assert(!File.exist?(File.join(@testing_upgrades, 'osw', 'Baseline', '1-upgraded.osw')))
    assert(File.exist?(File.join(@testing_upgrades, 'xml', 'Baseline', '1-existing-defaulted.xml')))
    assert(!File.exist?(File.join(@testing_upgrades, 'xml', 'Baseline', '1-upgraded-defaulted.xml')))
    assert(File.exist?(File.join(@testing_upgrades, 'xml', 'Baseline', '1-existing.xml')))
    assert(!File.exist?(File.join(@testing_upgrades, 'xml', 'Baseline', '1-upgraded.xml')))

    assert(File.exist?(File.join(@testing_upgrades, 'osw', 'Windows', '1-existing.osw')))
    assert(File.exist?(File.join(@testing_upgrades, 'osw', 'Windows', '1-upgraded.osw')))
    assert(!File.exist?(File.join(@testing_upgrades, 'xml', 'Windows', '1-existing-defaulted.xml')))
    assert(File.exist?(File.join(@testing_upgrades, 'xml', 'Windows', '1-upgraded-defaulted.xml')))
    assert(File.exist?(File.join(@testing_upgrades, 'xml', 'Windows', '1-existing.xml')))
    assert(File.exist?(File.join(@testing_upgrades, 'xml', 'Windows', '1-upgraded.xml')))

    assert(File.exist?(File.join(@testing_upgrades, 'results_characteristics.csv')))
    assert(File.exist?(File.join(@testing_upgrades, 'results_output.csv')))

    results_output = CSV.read(File.join(@testing_upgrades, 'results_output.csv'), headers: true)
    assert((@expected_upgrades_columns - results_output.headers).empty?)
    @expected_nonnull_columns.each do |col|
      next if !results_output.headers.include?(col)

      assert(!results_output[col].all? { |i| i.nil? })
    end
    @expected_nonzero_columns.each do |col|
      next if !results_output.headers.include?(col)

      assert(!results_output[col].all? { |i| i == 0 })
    end

    FileUtils.rm_rf(@testing_upgrades)
  end

  def test_national_upgrades
    yml = ' -y project_national/national_upgrades.yml'
    @command += yml
    @command += ' -d'

    system(@command)

    assert(File.exist?(File.join(@national_upgrades, 'cli_output.log')))
    assert(!File.read(File.join(@national_upgrades, 'cli_output.log')).include?('ERROR'))

    assert(File.exist?(File.join(@national_upgrades, 'osw', 'Baseline', '1-existing.osw')))
    assert(!File.exist?(File.join(@national_upgrades, 'osw', 'Baseline', '1-upgraded.osw')))
    assert(File.exist?(File.join(@national_upgrades, 'xml', 'Baseline', '1-existing-defaulted.xml')))
    assert(!File.exist?(File.join(@national_upgrades, 'xml', 'Baseline', '1-upgraded-defaulted.xml')))
    assert(File.exist?(File.join(@national_upgrades, 'xml', 'Baseline', '1-existing.xml')))
    assert(!File.exist?(File.join(@national_upgrades, 'xml', 'Baseline', '1-upgraded.xml')))

    assert(File.exist?(File.join(@national_upgrades, 'osw', 'Windows', '1-existing.osw')))
    assert(File.exist?(File.join(@national_upgrades, 'osw', 'Windows', '1-upgraded.osw')))
    assert(!File.exist?(File.join(@national_upgrades, 'xml', 'Windows', '1-existing-defaulted.xml')))
    assert(File.exist?(File.join(@national_upgrades, 'xml', 'Windows', '1-upgraded-defaulted.xml')))
    assert(File.exist?(File.join(@national_upgrades, 'xml', 'Windows', '1-existing.xml')))
    assert(File.exist?(File.join(@national_upgrades, 'xml', 'Windows', '1-upgraded.xml')))

    assert(File.exist?(File.join(@national_upgrades, 'results_characteristics.csv')))
    assert(File.exist?(File.join(@national_upgrades, 'results_output.csv')))

    results_output = CSV.read(File.join(@national_upgrades, 'results_output.csv'), headers: true)
    assert((@expected_upgrades_columns - results_output.headers).empty?)
    @expected_nonnull_columns.each do |col|
      next if !results_output.headers.include?(col)

      assert(!results_output[col].all? { |i| i.nil? })
    end
    @expected_nonzero_columns.each do |col|
      next if !results_output.headers.include?(col)

      assert(!results_output[col].all? { |i| i == 0 })
    end

    FileUtils.rm_rf(@national_upgrades)
  end
end
