require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class QOIReportTest < MiniTest::Test
  def test_average_daily_use_base
    # create an instance of the measure
    measure = QOIReport.new

    temperature, total_site_electricity_kw = _setup_test
    timeseries = { "Temperature" => temperature, "total_site_electricity_kw" => total_site_electricity_kw }

    actual_val = measure.average_daily_use(timeseries, measure.seasons[Constants.SeasonHeating], "min")
    assert_in_epsilon(5.0, actual_val, 0.001)

    actual_val = measure.average_daily_use(timeseries, measure.seasons[Constants.SeasonCooling], "min")
    assert_in_epsilon(9.0, actual_val, 0.001)

    actual_val = measure.average_daily_use(timeseries, measure.seasons[Constants.SeasonOverlap], "min")
    assert_in_epsilon(7.5, actual_val, 0.001)
  end

  def test_average_daily_use_peak
    # create an instance of the measure
    measure = QOIReport.new

    temperature, total_site_electricity_kw = _setup_test
    timeseries = { "Temperature" => temperature, "total_site_electricity_kw" => total_site_electricity_kw }

    actual_val = measure.average_daily_use(timeseries, measure.seasons[Constants.SeasonHeating], "max")
    assert_in_epsilon(11.0, actual_val, 0.001)

    actual_val = measure.average_daily_use(timeseries, measure.seasons[Constants.SeasonCooling], "max")
    assert_in_epsilon(13.0, actual_val, 0.001)

    actual_val = measure.average_daily_use(timeseries, measure.seasons[Constants.SeasonOverlap], "max")
    assert_in_epsilon(14.5, actual_val, 0.001)
  end

  def test_average_daily_timing_base
    # create an instance of the measure
    measure = QOIReport.new

    temperature, total_site_electricity_kw = _setup_test
    timeseries = { "Temperature" => temperature, "total_site_electricity_kw" => total_site_electricity_kw }

    actual_val = measure.average_daily_timing(timeseries, measure.seasons[Constants.SeasonHeating], "min")
    assert_in_epsilon(0.0, actual_val, 0.001)

    actual_val = measure.average_daily_timing(timeseries, measure.seasons[Constants.SeasonCooling], "min")
    assert_in_epsilon(1.5, actual_val, 0.001)

    actual_val = measure.average_daily_timing(timeseries, measure.seasons[Constants.SeasonOverlap], "min")
    assert_in_epsilon(5.0, actual_val, 0.001)
  end

  def test_average_daily_timing_peak
    # create an instance of the measure
    measure = QOIReport.new

    temperature, total_site_electricity_kw = _setup_test
    timeseries = { "Temperature" => temperature, "total_site_electricity_kw" => total_site_electricity_kw }

    actual_val = measure.average_daily_timing(timeseries, measure.seasons[Constants.SeasonHeating], "max")
    assert_in_epsilon(2.5, actual_val, 0.001)

    actual_val = measure.average_daily_timing(timeseries, measure.seasons[Constants.SeasonCooling], "max")
    assert_in_epsilon(6.5, actual_val, 0.001)

    actual_val = measure.average_daily_timing(timeseries, measure.seasons[Constants.SeasonOverlap], "max")
    assert_in_epsilon(10.0, actual_val, 0.001)
  end

  def _setup_test
    temperature = []
    temperature += _daily_heating_temperatures * 2
    temperature += _daily_cooling_temperatures * 2
    temperature += _daily_overlap_temperatures * 2

    total_site_electricity_kw = []
    total_site_electricity_kw += [0, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10]
    total_site_electricity_kw += [10, 10, 10, 10, 12, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10]
    total_site_electricity_kw += [10, 10, 10, 8, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10]
    total_site_electricity_kw += [10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 16, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10]
    total_site_electricity_kw += [10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 5, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10]
    total_site_electricity_kw += [10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 19, 10, 10, 10]

    return temperature, total_site_electricity_kw
  end

  def _daily_heating_temperatures
    # create an instance of the measure
    measure = QOIReport.new

    lower = 0
    upper = measure.seasons[Constants.SeasonHeating][1].to_i
    return (lower..upper).to_a.sample(24)
  end

  def _daily_cooling_temperatures
    # create an instance of the measure
    measure = QOIReport.new

    lower = measure.seasons[Constants.SeasonCooling][0].to_i
    upper = 100
    return (lower..upper).to_a.sample(24)
  end

  def _daily_overlap_temperatures
    # create an instance of the measure
    measure = QOIReport.new

    lower = measure.seasons[Constants.SeasonOverlap][0].to_i
    upper = measure.seasons[Constants.SeasonOverlap][1].to_i
    return (lower..upper).to_a.sample(24)
  end
end
