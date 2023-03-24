# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../test/analysis'

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

    _test_columns(results)

    assert(File.exist?(File.join(@testing_baseline, 'simulation_output', 'up00', 'bldg0000001', 'run')))
    contents = Dir[File.join(@testing_baseline, 'simulation_output', 'up00', 'bldg0000001', 'run/*')].collect { |x| File.basename(x) }

    _test_contents(contents, false, true)

    timeseries = _get_timeseries_columns(Dir[File.join(@testing_baseline, 'simulation_output/up*/bldg*/run/results_timeseries.csv')])
    assert(_test_timeseries_columns(timeseries, true))
  end

  def test_national_baseline
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
    assert(File.exist?(File.join(@testing_upgrades, 'results_csvs', 'results_up00.csv')))
    results = CSV.read(File.join(@testing_upgrades, 'results_csvs', 'results_up00.csv'), headers: true)

    _test_columns(results)

    assert(File.exist?(File.join(@testing_upgrades, 'simulation_output', 'up00', 'bldg0000001', 'run')))
    contents = Dir[File.join(@testing_upgrades, 'simulation_output', 'up00', 'bldg0000001', 'run/*')].collect { |x| File.basename(x) }

    _test_contents(contents, false, true)

    assert(File.exist?(File.join(@testing_upgrades, 'results_csvs', 'results_up15.csv')))
    results = CSV.read(File.join(@testing_upgrades, 'results_csvs', 'results_up15.csv'), headers: true)

    _test_columns(results, true)

    assert(File.exist?(File.join(@testing_upgrades, 'simulation_output', 'up15', 'bldg0000001', 'run')))
    contents = Dir[File.join(@testing_upgrades, 'simulation_output', 'up15', 'bldg0000001', 'run/*')].collect { |x| File.basename(x) }

    _test_contents(contents, true, true)

    timeseries = _get_timeseries_columns(Dir[File.join(@testing_upgrades, 'simulation_output/up*/bldg*/run/results_timeseries.csv')])
    assert(_test_timeseries_columns(timeseries, true))
  end

  def test_national_upgrades
    assert(File.exist?(File.join(@national_upgrades, 'results_csvs', 'results_up00.csv')))
    results = CSV.read(File.join(@national_upgrades, 'results_csvs', 'results_up00.csv'), headers: true)

    _test_columns(results)

    assert(File.exist?(File.join(@national_upgrades, 'simulation_output', 'up00', 'bldg0000001', 'run')))
    contents = Dir[File.join(@national_upgrades, 'simulation_output', 'up00', 'bldg0000001', 'run/*')].collect { |x| File.basename(x) }

    _test_contents(contents, false, false)

    assert(File.exist?(File.join(@national_upgrades, 'results_csvs', 'results_up15.csv')))
    results = CSV.read(File.join(@national_upgrades, 'results_csvs', 'results_up15.csv'), headers: true)

    _test_columns(results, true)

    assert(File.exist?(File.join(@national_upgrades, 'simulation_output', 'up15', 'bldg0000001', 'run')))
    contents = Dir[File.join(@national_upgrades, 'simulation_output', 'up15', 'bldg0000001', 'run/*')].collect { |x| File.basename(x) }

    _test_contents(contents, true, false)

    timeseries = _get_timeseries_columns(Dir[File.join(@national_upgrades, 'simulation_output/up*/bldg*/run/results_timeseries.csv')])
    assert(_test_timeseries_columns(timeseries))
  end

  def test_annual_outputs
    expected_outputs = CSV.read(File.join('resources', 'data', 'dictionary', 'outputs.csv'), headers: true)
    expected_annual_names = expected_outputs['Annual Name'].select { |n| !n.nil? }

    actual_outputs = CSV.read(File.join('baseline', 'annual', 'results_output.csv'), headers: true)
    actual_annual_names = actual_outputs.headers

    actual_extras = actual_annual_names - expected_annual_names
    actual_extras -= ['OSW']
    actual_extras -= ['color_index']
    puts "Annual Name, actual - expected: #{}" if !actual_extras.empty?

    expected_extras = expected_annual_names - actual_annual_names
    puts "Annual Name, expected - actual: #{}" if !expected_extras.empty?

    assert_equal(0, actual_extras.size)
    # assert_equal(0, expected_extras.size) # allow
  end

  def test_timeseries_outputs
    expected_outputs = CSV.read(File.join('resources', 'data', 'dictionary', 'outputs.csv'), headers: true)
    expected_timeseries_names = expected_outputs['Timeseries Name'].select { |n| !n.nil? }

    actual_outputs = CSV.read(File.join('baseline', 'timeseries', 'results_output.csv'), headers: true)
    actual_timeseries_names = actual_outputs.headers

    actual_extras = actual_timeseries_names - expected_timeseries_names
    actual_extras -= ['PROJECT']
    puts "Timeseries Name, actual - expected: #{}" if !actual_extras.empty?

    expected_extras = expected_timeseries_names - actual_timeseries_names
    puts "Timeseries Name, expected - actual: #{}" if !expected_extras.empty?

    assert_equal(0, actual_extras.size)
    # assert_equal(0, expected_extras.size) # allow
  end
end
