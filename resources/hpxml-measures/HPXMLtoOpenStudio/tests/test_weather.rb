# frozen_string_literal: true

require_relative '../resources/minitest_helper'
require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'fileutils'
require 'time'
require_relative '../resources/weather.rb'
require_relative '../resources/unit_conversions.rb'
require_relative '../resources/psychrometrics.rb'
require_relative '../resources/materials.rb'
require_relative '../resources/constants.rb'
require_relative '../resources/util.rb'
require_relative '../resources/location.rb'
require_relative '../resources/calendar.rb'
require_relative '../resources/defaults.rb'
require_relative '../resources/math.rb'

class HPXMLtoOpenStudioWeatherTest < Minitest::Test
  def teardown
    File.delete(File.join(File.dirname(__FILE__), 'in.schedules.csv')) if File.exist? File.join(File.dirname(__FILE__), 'in.schedules.csv')
    File.delete(File.join(File.dirname(__FILE__), 'results_annual.csv')) if File.exist? File.join(File.dirname(__FILE__), 'results_annual.csv')
    File.delete(File.join(File.dirname(__FILE__), 'results_design_load_details.csv')) if File.exist? File.join(File.dirname(__FILE__), 'results_design_load_details.csv')
  end

  def weather_dir
    return File.join(File.dirname(__FILE__), '..', '..', 'weather')
  end

  def test_denver
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    weather = WeatherFile.new(epw_path: File.join(weather_dir, 'USA_CO_Denver.Intl.AP.725650_TMY3.epw'), runner: runner)

    # Check data
    assert_in_delta(51.6, weather.data.AnnualAvgDrybulb, 0.1)
    assert_in_delta(51.6, weather.data.ShallowGroundAnnualTemp, 0.1)
    assert_in_delta(56.3, weather.data.DeepGroundAnnualTemp, 0.1)
    assert_in_delta(57.6, weather.data.MainsAnnualTemp, 0.1)
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
    [44.1, 40.9, 40.6, 42.2, 48.2, 54.3, 59.5, 62.8, 63.1, 60.4, 55.3, 49.4].each_with_index do |monthly_temp, i|
      assert_in_delta(monthly_temp, weather.data.ShallowGroundMonthlyTemps[i], 0.1)
    end
    [48.7, 47.7, 49.2, 52.9, 57.8, 62.7, 66.2, 67.5, 66.2, 62.7, 57.8, 52.9].each_with_index do |monthly_temp, i|
      assert_in_delta(monthly_temp, weather.data.MainsMonthlyTemps[i], 0.1)
    end

    # Check design
    assert_in_delta(6.8, weather.design.HeatingDrybulb, 0.1)
    assert_in_delta(91.8, weather.design.CoolingDrybulb, 0.1)
    assert_in_delta(0.0061, weather.design.CoolingHumidityRatio, 0.0001)
    assert_in_delta(27.4, weather.design.DailyTemperatureRange, 0.1)

    # Check runner
    assert_equal(0, runner.result.stepErrors.size)
    assert_equal(0, runner.result.stepWarnings.size)
  end

  def test_honolulu
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    weather = WeatherFile.new(epw_path: File.join(weather_dir, 'USA_HI_Honolulu.Intl.AP.911820_TMY3.epw'), runner: runner)

    # Check data
    assert_in_delta(76.8, weather.data.AnnualAvgDrybulb, 0.1)
    assert_in_delta(76.8, weather.data.ShallowGroundAnnualTemp, 0.1)
    assert_in_delta(81.0, weather.data.DeepGroundAnnualTemp, 0.1)
    assert_in_delta(82.8, weather.data.MainsAnnualTemp, 0.1)
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
    [75.6, 75.0, 74.9, 75.2, 76.4, 77.6, 78.7, 79.3, 79.4, 78.9, 77.8, 76.7].each_with_index do |monthly_temp, i|
      assert_in_delta(monthly_temp, weather.data.ShallowGroundMonthlyTemps[i], 0.1)
    end
    [79.8, 80.2, 81.2, 82.7, 84.2, 85.3, 85.8, 85.6, 84.6, 83.2, 81.6, 80.4].each_with_index do |monthly_temp, i|
      assert_in_delta(monthly_temp, weather.data.MainsMonthlyTemps[i], 0.1)
    end

    # Check design
    assert_in_delta(63.3, weather.design.HeatingDrybulb, 0.1)
    assert_in_delta(89.1, weather.design.CoolingDrybulb, 0.1)
    assert_in_delta(0.0141, weather.design.CoolingHumidityRatio, 0.0001)
    assert_in_delta(12.8, weather.design.DailyTemperatureRange, 0.1)

    # Check runner
    assert_equal(0, runner.result.stepErrors.size)
    assert_equal(0, runner.result.stepWarnings.size)
  end

  def test_cape_town
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    weather = WeatherFile.new(epw_path: File.join(weather_dir, 'ZAF_Cape.Town.688160_IWEC.epw'), runner: runner)

    # Check data
    assert_in_delta(61.7, weather.data.AnnualAvgDrybulb, 0.1)
    assert_in_delta(61.7, weather.data.ShallowGroundAnnualTemp, 0.1)
    assert_in_delta(65.8, weather.data.DeepGroundAnnualTemp, 0.1)
    assert_in_delta(67.7, weather.data.MainsAnnualTemp, 0.1)
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
    [64.9, 66.1, 66.2, 65.2, 63.3, 61.1, 59.2, 58.0, 57.9, 58.5, 60.7, 62.9].each_with_index do |monthly_temp, i|
      assert_in_delta(monthly_temp, weather.data.ShallowGroundMonthlyTemps[i], 0.1)
    end
    [72.0, 72.1, 71.0, 69.1, 66.9, 64.8, 63.5, 63.4, 64.3, 66.1, 68.4, 70.5].each_with_index do |monthly_temp, i|
      assert_in_delta(monthly_temp, weather.data.MainsMonthlyTemps[i], 0.1)
    end

    # Check design
    assert_in_delta(41.0, weather.design.HeatingDrybulb, 0.1)
    assert_in_delta(84.4, weather.design.CoolingDrybulb, 0.1)
    assert_in_delta(0.0095, weather.design.CoolingHumidityRatio, 0.0001)
    assert_in_delta(17.1, weather.design.DailyTemperatureRange, 0.1)

    # Check runner
    assert_equal(0, runner.result.stepErrors.size)
    assert_equal(0, runner.result.stepWarnings.size)
  end

  def test_boulder_amy_with_leap_day
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    weather = WeatherFile.new(epw_path: File.join(weather_dir, 'US_CO_Boulder_AMY_2012.epw'), runner: runner)

    # Check data
    assert_in_delta(49.4, weather.data.AnnualAvgDrybulb, 0.1)
    assert_in_delta(49.4, weather.data.ShallowGroundAnnualTemp, 0.1)
    assert_in_delta(55.2, weather.data.DeepGroundAnnualTemp, 0.1)
    assert_in_delta(55.4, weather.data.MainsAnnualTemp, 0.1)
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
    [41.3, 37.9, 37.6, 39.2, 45.7, 52.2, 57.9, 61.4, 61.8, 58.8, 53.4, 47.1].each_with_index do |monthly_temp, i|
      assert_in_delta(monthly_temp, weather.data.ShallowGroundMonthlyTemps[i], 0.1)
    end
    [46.5, 45.2, 46.6, 50.2, 55.2, 60.3, 64.0, 65.5, 64.4, 60.9, 56.0, 50.9].each_with_index do |monthly_temp, i|
      assert_in_delta(monthly_temp, weather.data.MainsMonthlyTemps[i], 0.1)
    end

    # Check design
    assert_in_delta(10.2, weather.design.HeatingDrybulb, 0.1)
    assert_in_delta(91.4, weather.design.CoolingDrybulb, 0.1)
    assert_in_delta(0.0046, weather.design.CoolingHumidityRatio, 0.0001)
    assert_in_delta(28.7, weather.design.DailyTemperatureRange, 0.1)

    # Check runner
    assert_equal(0, runner.result.stepErrors.size)
    assert_equal(1, runner.result.stepWarnings.count { |w| w == 'No design condition info found; calculating design conditions from EPW weather data.' })
  end
end
