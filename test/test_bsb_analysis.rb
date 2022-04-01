# frozen_string_literal: true

require 'minitest/autorun'
require 'rubygems/package'
require 'zlib'
require 'csv'

class TesBuildStockBatch < MiniTest::Test
  def before_setup
    @testing_baseline = 'project_testing/testing_baseline'
    @national_baseline = 'project_national/national_baseline'
    @testing_upgrades = 'project_testing/testing_upgrades'
    @national_upgrades = 'project_national/national_upgrades'
  end

  def test_testing_baseline
    assert(File.exist?(File.join(@testing_baseline, 'results_csvs', 'results_up00.csv')))
    results = CSV.read(File.join(@testing_baseline, 'results_csvs', 'results_up00.csv'), headers: true)

    assert(_test_baseline_columns(results))
    assert(!_test_upgrade_columns(results))
    assert(_test_nonnull_columns(results))
    assert(_test_nonzero_columns(results))

    assert(File.exist?(File.join(@testing_baseline, 'simulation_output', 'up00', 'bldg0000001', 'run')))
    contents = Dir[File.join(@testing_baseline, 'simulation_output', 'up00', 'bldg0000001', 'run/*')].collect { |x| File.basename(x) }

    assert(_test_baseline_contents(contents, true))
    assert(!_test_upgrade_contents(contents, true))

    timeseries = _get_timeseries_columns(Dir[File.join(@testing_baseline, 'simulation_output/up*/bldg*/run/results_timeseries.csv')])
    assert(_test_timeseries_columns(timeseries, true))
  end

  def test_national_baseline
    assert(File.exist?(File.join(@national_baseline, 'results_csvs', 'results_up00.csv')))
    results = CSV.read(File.join(@national_baseline, 'results_csvs', 'results_up00.csv'), headers: true)

    assert(_test_baseline_columns(results))
    assert(!_test_upgrade_columns(results))
    assert(_test_nonnull_columns(results))
    assert(_test_nonzero_columns(results))

    assert(File.exist?(File.join(@national_baseline, 'simulation_output', 'up00', 'bldg0000001', 'run')))
    contents = Dir[File.join(@national_baseline, 'simulation_output', 'up00', 'bldg0000001', 'run/*')].collect { |x| File.basename(x) }

    assert(_test_baseline_contents(contents))
    assert(!_test_upgrade_contents(contents))

    timeseries = _get_timeseries_columns(Dir[File.join(@national_baseline, 'simulation_output/up*/bldg*/run/results_timeseries.csv')])
    assert(_test_timeseries_columns(timeseries))
  end

  def test_testing_upgrades
    assert(File.exist?(File.join(@testing_upgrades, 'results_csvs', 'results_up00.csv')))
    results = CSV.read(File.join(@testing_upgrades, 'results_csvs', 'results_up00.csv'), headers: true)

    assert(_test_baseline_columns(results))
    assert(!_test_upgrade_columns(results))
    assert(_test_nonnull_columns(results))
    assert(_test_nonzero_columns(results))

    assert(File.exist?(File.join(@testing_upgrades, 'results_csvs', 'results_up01.csv')))
    results = CSV.read(File.join(@testing_upgrades, 'results_csvs', 'results_up01.csv'), headers: true)

    assert(_test_baseline_columns(results))
    assert(_test_upgrade_columns(results))
    assert(_test_nonnull_columns(results))
    assert(_test_nonzero_columns(results))

    assert(File.exist?(File.join(@testing_upgrades, 'simulation_output', 'up01', 'bldg0000001', 'run')))
    contents = Dir[File.join(@testing_upgrades, 'simulation_output', 'up01', 'bldg0000001', 'run/*')].collect { |x| File.basename(x) }

    assert(_test_baseline_contents(contents, true))
    assert(!_test_upgrade_contents(contents, true))

    timeseries = _get_timeseries_columns(Dir[File.join(@testing_upgrades, 'simulation_output/up*/bldg*/run/results_timeseries.csv')])
    assert(_test_timeseries_columns(timeseries, true))
  end

  def test_national_upgrades
    assert(File.exist?(File.join(@national_upgrades, 'results_csvs', 'results_up00.csv')))
    results = CSV.read(File.join(@national_upgrades, 'results_csvs', 'results_up00.csv'), headers: true)

    assert(_test_baseline_columns(results))
    assert(!_test_upgrade_columns(results))
    assert(_test_nonnull_columns(results))
    assert(_test_nonzero_columns(results))

    assert(File.exist?(File.join(@national_upgrades, 'results_csvs', 'results_up01.csv')))
    results = CSV.read(File.join(@national_upgrades, 'results_csvs', 'results_up01.csv'), headers: true)

    assert(_test_baseline_columns(results))
    assert(_test_upgrade_columns(results))
    assert(_test_nonnull_columns(results))
    assert(_test_nonzero_columns(results))

    assert(File.exist?(File.join(@national_upgrades, 'simulation_output', 'up01', 'bldg0000001', 'run')))
    contents = Dir[File.join(@national_upgrades, 'simulation_output', 'up01', 'bldg0000001', 'run/*')].collect { |x| File.basename(x) }

    assert(_test_baseline_contents(contents))
    assert(!_test_upgrade_contents(contents))

    timeseries = _get_timeseries_columns(Dir[File.join(@national_upgrades, 'simulation_output/up*/bldg*/run/results_timeseries.csv')])
    assert(_test_timeseries_columns(timeseries))
  end
end
