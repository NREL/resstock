# frozen_string_literal: true

require_relative '../resources/minitest_helper'
require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'fileutils'
require_relative '../resources/weather.rb'
require_relative '../resources/unit_conversions.rb'
require_relative '../resources/psychrometrics.rb'
require_relative '../resources/materials.rb'
require_relative '../resources/constants.rb'
require_relative '../resources/util.rb'

class HPXMLtoOpenStudioWeatherTest < Minitest::Test
  def weather_dir
    return File.join(File.dirname(__FILE__), '..', '..', 'weather')
  end

  def test_denver
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    weather = WeatherProcess.new(epw_path: File.join(weather_dir, 'USA_CO_Denver.Intl.AP.725650_TMY3.epw'), runner: runner)

    # Check header
    assert_equal('Denver Intl Ap', weather.header.City)
    assert_equal('CO', weather.header.State)
    assert_equal('USA', weather.header.Country)
    assert_equal('TMY3', weather.header.DataSource)
    assert_equal('725650', weather.header.Station)
    assert_equal(39.83, weather.header.Latitude)
    assert_equal(-104.65, weather.header.Longitude)
    assert_equal(-7.0, weather.header.Timezone)
    assert_in_delta(5413.4, weather.header.Altitude, 0.1)
    assert_in_delta(0.82, weather.header.LocalPressure, 0.01)

    # Check data
    assert_equal(1, weather.header.RecordsPerHour)
    assert_in_delta(51.6, weather.data.AnnualAvgDrybulb, 0.1)
    assert_in_delta(3072.3, weather.data.CDD50F, 0.1)
    assert_in_delta(883.6, weather.data.CDD65F, 0.1)
    assert_in_delta(2497.2, weather.data.HDD50F, 0.1)
    assert_in_delta(5783.5, weather.data.HDD65F, 0.1)
    assert_equal(0.59, weather.data.WSF)
    [33.4, 31.9, 43.0, 42.5, 59.9, 73.6, 72.1, 72.7, 66.5, 50.1, 37.2, 34.6].each_with_index do |monthly_temp, i|
      assert_in_delta(monthly_temp, weather.data.MonthlyAvgDrybulbs[i], 0.1)
    end
    [47.4, 46.6, 55.2, 53.7, 72.8, 88.7, 86.2, 85.9, 82.1, 63.2, 48.7, 48.9].each_with_index do |monthly_temp, i|
      assert_in_delta(monthly_temp, weather.data.MonthlyAvgDailyHighDrybulbs[i], 0.1)
    end
    [19.3, 19.9, 30.3, 31.1, 47.4, 57.9, 59.1, 61.0, 52.4, 38.4, 27.0, 23.0].each_with_index do |monthly_temp, i|
      assert_in_delta(monthly_temp, weather.data.MonthlyAvgDailyLowDrybulbs[i], 0.1)
    end
    [45.6, 42.4, 42.2, 43.7, 49.7, 55.8, 61.0, 64.3, 64.6, 61.9, 56.8, 51.0].each_with_index do |monthly_temp, i|
      assert_in_delta(monthly_temp, weather.data.GroundMonthlyTemps[i], 0.1)
    end

    # Check design
    assert_in_delta(6.8, weather.design.HeatingDrybulb, 0.1)
    assert_in_delta(91.8, weather.design.CoolingDrybulb, 0.1)
    assert_in_delta(60.1, weather.design.CoolingWetbulb, 0.1)
    assert_in_delta(0.0061, weather.design.CoolingHumidityRatio, 0.0001)
    assert_in_delta(27.4, weather.design.DailyTemperatureRange, 0.1)

    # Check runner
    assert_equal(0, runner.result.stepErrors.size)
    assert_equal(0, runner.result.stepWarnings.size)
  end

  def test_honolulu
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    weather = WeatherProcess.new(epw_path: File.join(weather_dir, 'USA_HI_Honolulu.Intl.AP.911820_TMY3.epw'), runner: runner)

    # Check header
    assert_equal('Honolulu Intl Arpt', weather.header.City)
    assert_equal('HI', weather.header.State)
    assert_equal('USA', weather.header.Country)
    assert_equal('TMY3', weather.header.DataSource)
    assert_equal('911820', weather.header.Station)
    assert_equal(21.32, weather.header.Latitude)
    assert_equal(-157.93, weather.header.Longitude)
    assert_equal(-10.0, weather.header.Timezone)
    assert_in_delta(6.6, weather.header.Altitude, 0.1)
    assert_in_delta(1.0, weather.header.LocalPressure, 0.01)

    # Check data
    assert_equal(1, weather.header.RecordsPerHour)
    assert_in_delta(76.8, weather.data.AnnualAvgDrybulb, 0.1)
    assert_in_delta(9798.7, weather.data.CDD50F, 0.1)
    assert_in_delta(4323.7, weather.data.CDD65F, 0.1)
    assert_in_delta(0.0, weather.data.HDD50F, 0.1)
    assert_in_delta(0.0, weather.data.HDD65F, 0.1)
    assert_equal(0.42, weather.data.WSF)
    [72.5, 73.0, 73.7, 74.8, 77.4, 78.6, 80.4, 80.7, 80.4, 79.2, 76.6, 74.6].each_with_index do |monthly_temp, i|
      assert_in_delta(monthly_temp, weather.data.MonthlyAvgDrybulbs[i], 0.1)
    end
    [80.0, 80.6, 81.7, 82.5, 85.4, 84.3, 87.8, 88.9, 87.0, 88.2, 83.6, 80.6].each_with_index do |monthly_temp, i|
      assert_in_delta(monthly_temp, weather.data.MonthlyAvgDailyHighDrybulbs[i], 0.1)
    end
    [66.1, 65.9, 66.6, 68.8, 70.7, 73.7, 75.2, 74.5, 75.2, 71.9, 70.6, 69.1].each_with_index do |monthly_temp, i|
      assert_in_delta(monthly_temp, weather.data.MonthlyAvgDailyLowDrybulbs[i], 0.1)
    end
    [74.9, 74.2, 74.2, 74.5, 75.7, 76.9, 77.9, 78.6, 78.6, 78.1, 77.1, 75.9].each_with_index do |monthly_temp, i|
      assert_in_delta(monthly_temp, weather.data.GroundMonthlyTemps[i], 0.1)
    end

    # Check design
    assert_in_delta(63.3, weather.design.HeatingDrybulb, 0.1)
    assert_in_delta(89.1, weather.design.CoolingDrybulb, 0.1)
    assert_in_delta(73.6, weather.design.CoolingWetbulb, 0.1)
    assert_in_delta(0.0141, weather.design.CoolingHumidityRatio, 0.0001)
    assert_in_delta(12.8, weather.design.DailyTemperatureRange, 0.1)

    # Check runner
    assert_equal(0, runner.result.stepErrors.size)
    assert_equal(0, runner.result.stepWarnings.size)
  end

  def test_cape_town
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    weather = WeatherProcess.new(epw_path: File.join(weather_dir, 'ZAF_Cape.Town.688160_IWEC.epw'), runner: runner)

    # Check header
    assert_equal('CAPE TOWN', weather.header.City)
    assert_equal('-', weather.header.State)
    assert_equal('ZAF', weather.header.Country)
    assert_equal('IWEC Data', weather.header.DataSource)
    assert_equal('688160', weather.header.Station)
    assert_equal(-33.98, weather.header.Latitude)
    assert_equal(18.6, weather.header.Longitude)
    assert_equal(2.0, weather.header.Timezone)
    assert_in_delta(137.8, weather.header.Altitude, 0.1)
    assert_in_delta(1.0, weather.header.LocalPressure, 0.01)

    # Check data
    assert_equal(1, weather.header.RecordsPerHour)
    assert_in_delta(61.7, weather.data.AnnualAvgDrybulb, 0.1)
    assert_in_delta(4297.8, weather.data.CDD50F, 0.1)
    assert_in_delta(503.0, weather.data.CDD65F, 0.1)
    assert_in_delta(17.5, weather.data.HDD50F, 0.1)
    assert_in_delta(1697.6, weather.data.HDD65F, 0.1)
    assert_equal(0.56, weather.data.WSF)
    [69.5, 69.5, 66.4, 61.7, 58.6, 55.1, 54.2, 55.2, 57.8, 60.7, 65.0, 67.6].each_with_index do |monthly_temp, i|
      assert_in_delta(monthly_temp, weather.data.MonthlyAvgDrybulbs[i], 0.1)
    end
    [79.0, 78.5, 74.2, 70.0, 68.8, 64.6, 63.3, 64.2, 66.4, 70.6, 72.3, 76.0].each_with_index do |monthly_temp, i|
      assert_in_delta(monthly_temp, weather.data.MonthlyAvgDailyHighDrybulbs[i], 0.1)
    end
    [61.0, 61.9, 59.7, 54.5, 50.8, 46.7, 45.3, 47.7, 50.1, 50.6, 57.9, 59.6].each_with_index do |monthly_temp, i|
      assert_in_delta(monthly_temp, weather.data.MonthlyAvgDailyLowDrybulbs[i], 0.1)
    end
    [59.7, 58.6, 58.5, 59.1, 61.3, 63.5, 65.5, 66.7, 66.8, 65.8, 63.9, 61.7].each_with_index do |monthly_temp, i|
      assert_in_delta(monthly_temp, weather.data.GroundMonthlyTemps[i], 0.1)
    end

    # Check design
    assert_in_delta(41.0, weather.design.HeatingDrybulb, 0.1)
    assert_in_delta(84.4, weather.design.CoolingDrybulb, 0.1)
    assert_in_delta(66.2, weather.design.CoolingWetbulb, 0.1)
    assert_in_delta(0.0095, weather.design.CoolingHumidityRatio, 0.0001)
    assert_in_delta(17.1, weather.design.DailyTemperatureRange, 0.1)

    # Check runner
    assert_equal(0, runner.result.stepErrors.size)
    assert_equal(0, runner.result.stepWarnings.size)
  end

  def test_boulder_amy_with_leap_day
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    weather = WeatherProcess.new(epw_path: File.join(weather_dir, 'US_CO_Boulder_AMY_2012.epw'), runner: runner)

    # Check header
    assert_equal('Boulder', weather.header.City)
    assert_equal('CO', weather.header.State)
    assert_equal('US', weather.header.Country)
    assert_equal('NSRDB 2.0.1 2012 AMY', weather.header.DataSource)
    assert_equal('724699', weather.header.Station)
    assert_equal(40.13, weather.header.Latitude)
    assert_equal(-105.22, weather.header.Longitude)
    assert_equal(-7.0, weather.header.Timezone)
    assert_in_delta(5300.2, weather.header.Altitude, 0.1)
    assert_in_delta(0.82, weather.header.LocalPressure, 0.01)

    # Check data
    assert_equal(1, weather.header.RecordsPerHour)
    assert_in_delta(49.4, weather.data.AnnualAvgDrybulb, 0.1)
    assert_in_delta(2633.8, weather.data.CDD50F, 0.1)
    assert_in_delta(609.1, weather.data.CDD65F, 0.1)
    assert_in_delta(2863.0, weather.data.HDD50F, 0.1)
    assert_in_delta(6328.3, weather.data.HDD65F, 0.1)
    assert_equal(0.58, weather.data.WSF)
    [30.8, 26.4, 43.0, 49.4, 56.8, 71.1, 71.2, 70.4, 60.8, 45.3, 39.6, 27.0].each_with_index do |monthly_temp, i|
      assert_in_delta(monthly_temp, weather.data.MonthlyAvgDrybulbs[i], 0.1)
    end
    [42.4, 37.8, 59.1, 66.2, 73.9, 89.2, 86.2, 87.5, 76.5, 61.2, 54.5, 38.2].each_with_index do |monthly_temp, i|
      assert_in_delta(monthly_temp, weather.data.MonthlyAvgDailyHighDrybulbs[i], 0.1)
    end
    [22.1, 17.4, 30.4, 34.4, 40.8, 54.1, 57.5, 55.6, 48.1, 33.5, 30.0, 18.9].each_with_index do |monthly_temp, i|
      assert_in_delta(monthly_temp, weather.data.MonthlyAvgDailyLowDrybulbs[i], 0.1)
    end
    [43.0, 39.6, 39.3, 40.9, 47.5, 54.0, 59.6, 63.2, 63.5, 60.6, 55.1, 48.8].each_with_index do |monthly_temp, i|
      assert_in_delta(monthly_temp, weather.data.GroundMonthlyTemps[i], 0.1)
    end

    # Check design
    assert_in_delta(10.2, weather.design.HeatingDrybulb, 0.1)
    assert_in_delta(91.4, weather.design.CoolingDrybulb, 0.1)
    assert_in_delta(58.0, weather.design.CoolingWetbulb, 0.1)
    assert_in_delta(0.0046, weather.design.CoolingHumidityRatio, 0.0001)
    assert_in_delta(31.9, weather.design.DailyTemperatureRange, 0.1)

    # Check runner
    assert_equal(0, runner.result.stepErrors.size)
    assert_equal(1, runner.result.stepWarnings.select { |w| w == 'No design condition info found; calculating design conditions from EPW weather data.' }.size)
  end

  def test_ground_temperatures
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    ['USA_CO_Denver.Intl.AP.725650_TMY3.epw',
     'USA_HI_Honolulu.Intl.AP.911820_TMY3.epw',
     'ZAF_Cape.Town.688160_IWEC.epw',
     'US_CO_Boulder_AMY_2012.epw',
     'USA_FL_Miami.Intl.AP.722020_TMY3.epw',
     'USA_AZ_Phoenix-Sky.Harbor.Intl.AP.722780_TMY3.epw',
     'USA_MN_Duluth.Intl.AP.727450_TMY3.epw'].each do |epw_filename|
      weather = WeatherProcess.new(epw_path: File.join(weather_dir, epw_filename), runner: runner)
      ground_temp_f = weather.data.GroundMonthlyTemps.sum(0.0) / weather.data.GroundMonthlyTemps.size

      if epw_filename == 'USA_CO_Denver.Intl.AP.725650_TMY3.epw'
        gtf = 53.25
      elsif epw_filename == 'USA_HI_Honolulu.Intl.AP.911820_TMY3.epw'
        gtf = 76.38
      elsif epw_filename == 'ZAF_Cape.Town.688160_IWEC.epw'
        gtf = 62.6
      elsif epw_filename == 'US_CO_Boulder_AMY_2012.epw'
        gtf = 51.24
      elsif epw_filename == 'USA_FL_Miami.Intl.AP.722020_TMY3.epw'
        gtf = 75.69
      elsif epw_filename == 'USA_AZ_Phoenix-Sky.Harbor.Intl.AP.722780_TMY3.epw'
        gtf = 74.42
      elsif epw_filename == 'USA_MN_Duluth.Intl.AP.727450_TMY3.epw'
        gtf = 41.97
      end
      assert_in_delta(gtf, ground_temp_f, 0.01)
    end
  end
end
