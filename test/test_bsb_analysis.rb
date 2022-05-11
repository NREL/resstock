# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../test/analysis'

class TesBuildStockBatch < MiniTest::Test
  def before_setup
    @la100es_baseline = 'project_la/la100es_baseline'
  end

  def test_la100es_baseline
    assert(File.exist?(File.join(@la100es_baseline, 'results_csvs', 'results_up00.csv')))
    results = CSV.read(File.join(@la100es_baseline, 'results_csvs', 'results_up00.csv'), headers: true)

    _test_columns(results)

    assert(File.exist?(File.join(@la100es_baseline, 'simulation_output', 'up00', 'bldg0000001', 'run')))
    contents = Dir[File.join(@la100es_baseline, 'simulation_output', 'up00', 'bldg0000001', 'run/*')].collect { |x| File.basename(x) }

    _test_contents(contents, false, true)

    timeseries = _get_timeseries_columns(Dir[File.join(@la100es_baseline, 'simulation_output/up*/bldg*/run/results_timeseries.csv')])
    assert(_test_timeseries_columns(timeseries, true))
  end
end