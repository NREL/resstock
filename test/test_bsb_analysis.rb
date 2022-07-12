# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../test/analysis'

class TesBuildStockBatch < MiniTest::Test
  def before_setup
    @la100es_baseline = 'project_la/la100es_baseline'
    @testing_baseline = 'project_testing/testing_baseline'
    @national_baseline = 'project_national/national_baseline'
    @testing_upgrades = 'project_testing/testing_upgrades'
    @national_upgrades = 'project_national/national_upgrades'
  end

  def test_testing_baseline
    skip
    assert(File.exist?(File.join(@testing_baseline, 'results_csvs', 'results_up00.csv')))
    results = CSV.read(File.join(@testing_baseline, 'results_csvs', 'results_up00.csv'), headers: true)

    _test_columns(results)

    assert(File.exist?(File.join(@testing_baseline, 'simulation_output', 'up00', 'bldg0000001', 'run')))
    contents = Dir[File.join(@testing_baseline, 'simulation_output', 'up00', 'bldg0000001', 'run/*')].collect { |x| File.basename(x) }

    _test_contents(contents, false, true)

    timeseries = _get_timeseries_columns(Dir[File.join(@testing_baseline, 'simulation_output/up*/bldg*/run/results_timeseries.csv')])
    assert(_test_timeseries_columns(timeseries, true))
  end

  def test_national_baseline
    skip
    assert(File.exist?(File.join(@national_baseline, 'results_csvs', 'results_up00.csv')))
    results = CSV.read(File.join(@national_baseline, 'results_csvs', 'results_up00.csv'), headers: true)

    _test_columns(results)

    assert(File.exist?(File.join(@national_baseline, 'simulation_output', 'up00', 'bldg0000001', 'run')))
    contents = Dir[File.join(@national_baseline, 'simulation_output', 'up00', 'bldg0000001', 'run/*')].collect { |x| File.basename(x) }

    _test_contents(contents, false, false)

    timeseries = _get_timeseries_columns(Dir[File.join(@national_baseline, 'simulation_output/up*/bldg*/run/results_timeseries.csv')])
    assert(_test_timeseries_columns(timeseries))
  end

  def test_testing_upgrades
    skip
    assert(File.exist?(File.join(@testing_upgrades, 'results_csvs', 'results_up00.csv')))
    results = CSV.read(File.join(@testing_upgrades, 'results_csvs', 'results_up00.csv'), headers: true)

    _test_columns(results)

    assert(File.exist?(File.join(@testing_upgrades, 'simulation_output', 'up00', 'bldg0000001', 'run')))
    contents = Dir[File.join(@testing_upgrades, 'simulation_output', 'up00', 'bldg0000001', 'run/*')].collect { |x| File.basename(x) }

    _test_contents(contents, false, true)

    assert(File.exist?(File.join(@testing_upgrades, 'results_csvs', 'results_up14.csv')))
    results = CSV.read(File.join(@testing_upgrades, 'results_csvs', 'results_up14.csv'), headers: true)

    _test_columns(results, true)

    assert(File.exist?(File.join(@testing_upgrades, 'simulation_output', 'up14', 'bldg0000001', 'run')))
    contents = Dir[File.join(@testing_upgrades, 'simulation_output', 'up14', 'bldg0000001', 'run/*')].collect { |x| File.basename(x) }

    _test_contents(contents, true, true)

    timeseries = _get_timeseries_columns(Dir[File.join(@testing_upgrades, 'simulation_output/up*/bldg*/run/results_timeseries.csv')])
    assert(_test_timeseries_columns(timeseries, true))
  end

  def test_national_upgrades
    skip
    assert(File.exist?(File.join(@national_upgrades, 'results_csvs', 'results_up00.csv')))
    results = CSV.read(File.join(@national_upgrades, 'results_csvs', 'results_up00.csv'), headers: true)

    _test_columns(results)

    assert(File.exist?(File.join(@national_upgrades, 'simulation_output', 'up00', 'bldg0000001', 'run')))
    contents = Dir[File.join(@national_upgrades, 'simulation_output', 'up00', 'bldg0000001', 'run/*')].collect { |x| File.basename(x) }

    _test_contents(contents, false, false)

    assert(File.exist?(File.join(@national_upgrades, 'results_csvs', 'results_up14.csv')))
    results = CSV.read(File.join(@national_upgrades, 'results_csvs', 'results_up14.csv'), headers: true)

    _test_columns(results, true)

    assert(File.exist?(File.join(@national_upgrades, 'simulation_output', 'up14', 'bldg0000001', 'run')))
    contents = Dir[File.join(@national_upgrades, 'simulation_output', 'up14', 'bldg0000001', 'run/*')].collect { |x| File.basename(x) }

    _test_contents(contents, true, false)

    timeseries = _get_timeseries_columns(Dir[File.join(@national_upgrades, 'simulation_output/up*/bldg*/run/results_timeseries.csv')])
    assert(_test_timeseries_columns(timeseries))
  end

  def test_la100es_baseline
    assert(File.exist?(File.join(@la100es_baseline, 'results_csvs', 'results_up00.csv')))
    results = CSV.read(File.join(@la100es_baseline, 'results_csvs', 'results_up00.csv'), headers: true)

    _test_columns(results)

    assert(File.exist?(File.join(@la100es_baseline, 'simulation_output', 'up00', 'bldg0000001', 'run')))
    contents = Dir[File.join(@la100es_baseline, 'simulation_output', 'up00', 'bldg0000001', 'run/*')].collect { |x| File.basename(x) }

    _test_contents(contents, false, true)

    timeseries = _get_timeseries_columns(Dir[File.join(@la100es_baseline, 'simulation_output/up*/bldg*/run/results_timeseries.csv')])
    assert(_test_timeseries_columns(timeseries, false))
  end
end
