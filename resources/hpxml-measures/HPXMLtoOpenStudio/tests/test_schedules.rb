# frozen_string_literal: true

require_relative '../resources/minitest_helper'
require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'fileutils'
require_relative '../measure.rb'
require_relative '../resources/util.rb'

class HPXMLtoOpenStudioSchedulesTest < Minitest::Test
  def setup
    @root_path = File.absolute_path(File.join(File.dirname(__FILE__), '..', '..'))
    @sample_files_path = File.join(@root_path, 'workflow', 'sample_files')
    @tmp_hpxml_path = File.join(@sample_files_path, 'tmp.xml')
    @tmp_schedule_file_path = File.join(@sample_files_path, 'tmp.csv')

    @year = 2007
    @tol = 0.005
  end

  def teardown
    File.delete(@tmp_hpxml_path) if File.exist? @tmp_hpxml_path
    File.delete(@tmp_schedule_file_path) if File.exist? @tmp_schedule_file_path
  end

  def sample_files_dir
    return File.join(File.dirname(__FILE__), '..', '..', 'workflow', 'sample_files')
  end

  def get_annual_equivalent_full_load_hrs(model, name)
    (model.getScheduleConstants + model.getScheduleRulesets + model.getScheduleFixedIntervals).each do |schedule|
      next if schedule.name.to_s != name

      return Schedule.annual_equivalent_full_load_hrs(@year, schedule)
    end
    flunk "Could not find schedule '#{name}'."
  end

  def get_available_hrs_ratio(unavailable_month_hrs, mults = '1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1')
    # month_idx => unavailable_hrs
    mults = mults.split(',').map { |i| i.to_f }
    total_unavailable_hrs = 0.0
    unavailable_month_hrs.each do |unavailable_month, unavailable_hrs|
      total_unavailable_hrs += unavailable_hrs * mults[unavailable_month]
    end
    return 1.0 - (total_unavailable_hrs / Constants.NumHoursInYear(@year))
  end

  def test_default_schedules
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base.xml'))
    model, _hpxml, _hpxml_bldg = _test_measure(args_hash)

    schedule_constants = 12
    schedule_rulesets = 17
    schedule_fixed_intervals = 1
    schedule_files = 0

    assert_equal(schedule_constants, model.getScheduleConstants.size)
    assert_equal(schedule_rulesets, model.getScheduleRulesets.size)
    assert_equal(schedule_fixed_intervals, model.getScheduleFixedIntervals.size)
    assert_equal(schedule_files, model.getScheduleFiles.size)
    assert_equal(model.getSchedules.size, schedule_constants + schedule_rulesets + schedule_fixed_intervals + schedule_files)

    assert_in_epsilon(4451, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameOccupants + ' schedule'), @tol)
    assert_in_epsilon(2764, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameLightingInterior + ' schedule'), @tol)
    assert_in_epsilon(4342, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameLightingExterior + ' schedule'), @tol)
    assert_in_epsilon(2724, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameCookingRange + ' schedule'), @tol)
    assert_in_epsilon(3288, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameDishwasher + ' schedule'), @tol)
    assert_in_epsilon(4244, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameClothesWasher + ' schedule'), @tol)
    assert_in_epsilon(4502, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameClothesDryer + ' schedule'), @tol)
    assert_in_epsilon(7157, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameMiscPlugLoads + ' schedule'), @tol)
    assert_in_epsilon(2765, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameMiscTelevision + ' schedule'), @tol)
    assert_in_epsilon(4244, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameFixtures + ' schedule'), @tol)
    assert_in_epsilon(5000, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameGeneralWaterUse + ' schedule'), @tol)
    assert_in_epsilon(8760, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameMechanicalVentilationHouseFan + ' schedule'), @tol)
  end

  def test_simple_schedules
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-schedules-simple.xml'))
    model, _hpxml, _hpxml_bldg = _test_measure(args_hash)

    schedule_constants = 11
    schedule_rulesets = 19
    schedule_fixed_intervals = 1
    schedule_files = 0

    assert_equal(schedule_constants, model.getScheduleConstants.size)
    assert_equal(schedule_rulesets, model.getScheduleRulesets.size)
    assert_equal(schedule_fixed_intervals, model.getScheduleFixedIntervals.size)
    assert_equal(schedule_files, model.getScheduleFiles.size)
    assert_equal(model.getSchedules.size, schedule_constants + schedule_rulesets + schedule_fixed_intervals + schedule_files)

    assert_in_epsilon(6020, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameOccupants + ' schedule'), @tol)
    assert_in_epsilon(3049, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameLightingInterior + ' schedule'), @tol)
    assert_in_epsilon(2895, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameLightingExterior + ' schedule'), @tol)
    assert_in_epsilon(6673, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameRefrigerator + ' schedule'), @tol)
    assert_in_epsilon(2441, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameCookingRange + ' schedule'), @tol)
    assert_in_epsilon(3285, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameDishwasher + ' schedule'), @tol)
    assert_in_epsilon(4248, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameClothesWasher + ' schedule'), @tol)
    assert_in_epsilon(4502, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameClothesDryer + ' schedule'), @tol)
    assert_in_epsilon(6880, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameMiscPlugLoads + ' schedule'), @tol)
    assert_in_epsilon(3373, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameMiscTelevision + ' schedule'), @tol)
    assert_in_epsilon(4204, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameFixtures + ' schedule'), @tol)
    assert_in_epsilon(4244, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameHotWaterRecircPump + ' schedule'), @tol)
    assert_in_epsilon(5000, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameGeneralWaterUse + ' schedule'), @tol)
    assert_in_epsilon(8760, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameMechanicalVentilationHouseFan + ' schedule'), @tol)
  end

  def test_simple_vacancy_schedules
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-schedules-simple-vacancy.xml'))
    model, _hpxml, _hpxml_bldg = _test_measure(args_hash)

    unavailable_month_hrs = { 0 => 31.0 * 24.0, 11 => 31.0 * 24.0 }

    assert_in_epsilon(6020 * get_available_hrs_ratio(unavailable_month_hrs, Schedule.OccupantsMonthlyMultipliers), get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameOccupants + ' schedule'), @tol)
    assert_in_epsilon(3049 * get_available_hrs_ratio(unavailable_month_hrs, Schedule.LightingMonthlyMultipliers), get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameLightingInterior + ' schedule'), @tol)
    assert_in_epsilon(2895 * get_available_hrs_ratio(unavailable_month_hrs, Schedule.LightingMonthlyMultipliers), get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameLightingExterior + ' schedule'), @tol)
    assert_in_epsilon(6673, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameRefrigerator + ' schedule'), @tol)
    assert_in_epsilon(2441 * get_available_hrs_ratio(unavailable_month_hrs, Schedule.CookingRangeMonthlyMultipliers), get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameCookingRange + ' schedule'), @tol)
    assert_in_epsilon(3285 * get_available_hrs_ratio(unavailable_month_hrs, Schedule.DishwasherMonthlyMultipliers), get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameDishwasher + ' schedule'), @tol)
    assert_in_epsilon(4248 * get_available_hrs_ratio(unavailable_month_hrs, Schedule.ClothesWasherMonthlyMultipliers), get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameClothesWasher + ' schedule'), @tol)
    assert_in_epsilon(4502 * get_available_hrs_ratio(unavailable_month_hrs, Schedule.ClothesDryerMonthlyMultipliers), get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameClothesDryer + ' schedule'), @tol)
    assert_in_epsilon(6880 * get_available_hrs_ratio(unavailable_month_hrs, Schedule.PlugLoadsOtherMonthlyMultipliers), get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameMiscPlugLoads + ' schedule'), @tol)
    assert_in_epsilon(3373 * get_available_hrs_ratio(unavailable_month_hrs, Schedule.PlugLoadsTVMonthlyMultipliers), get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameMiscTelevision + ' schedule'), @tol)
    assert_in_epsilon(4204 * get_available_hrs_ratio(unavailable_month_hrs, Schedule.FixturesMonthlyMultipliers), get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameFixtures + ' schedule'), @tol)
    assert_in_epsilon(4244 * get_available_hrs_ratio(unavailable_month_hrs, Schedule.RecirculationPumpMonthlyMultipliers), get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameHotWaterRecircPump + ' schedule'), @tol)
    assert_in_epsilon(5000 * get_available_hrs_ratio(unavailable_month_hrs, Schedule.GeneralWaterUseMonthlyMultipliers), get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameGeneralWaterUse + ' schedule'), @tol)
    assert_in_epsilon(8760, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameMechanicalVentilationHouseFan + ' schedule'), @tol)
  end

  def test_simple_vacancy_year_round_schedules
    args_hash = {}
    hpxml_path = File.absolute_path(File.join(sample_files_dir, 'base-schedules-simple-vacancy.xml'))
    hpxml = HPXML.new(hpxml_path: hpxml_path)
    hpxml.header.unavailable_periods[0].begin_month = 1
    hpxml.header.unavailable_periods[0].begin_day = 1
    hpxml.header.unavailable_periods[0].end_month = 12
    hpxml.header.unavailable_periods[0].end_day = 31
    XMLHelper.write_file(hpxml.to_doc(), @tmp_hpxml_path)
    args_hash['hpxml_path'] = @tmp_hpxml_path
    model, _hpxml, _hpxml_bldg = _test_measure(args_hash)

    assert_equal(0, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameOccupants + ' schedule'))
    assert_equal(0, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameLightingInterior + ' schedule'))
    assert_equal(0, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameLightingExterior + ' schedule'))
    assert_in_epsilon(6673, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameRefrigerator + ' schedule'), @tol)
    assert_equal(0, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameCookingRange + ' schedule'))
    assert_equal(0, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameDishwasher + ' schedule'))
    assert_equal(0, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameClothesWasher + ' schedule'))
    assert_equal(0, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameClothesDryer + ' schedule'))
    assert_equal(0, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameMiscPlugLoads + ' schedule'))
    assert_equal(0, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameMiscTelevision + ' schedule'))
    assert_equal(0, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameFixtures + ' schedule'))
    assert_equal(0, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameHotWaterRecircPump + ' schedule'))
    assert_equal(0, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameGeneralWaterUse + ' schedule'))
    assert_in_epsilon(8760, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameMechanicalVentilationHouseFan + ' schedule'), @tol)
  end

  def test_simple_power_outage_schedules
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-schedules-simple-power-outage.xml'))
    model, _hpxml, _hpxml_bldg = _test_measure(args_hash)

    unavailable_month_hrs = { 6 => 31.0 * 24.0 - 15.0 }

    assert_in_epsilon(6020, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameOccupants + ' schedule'), @tol)
    assert_in_epsilon(3049 * get_available_hrs_ratio(unavailable_month_hrs, Schedule.LightingMonthlyMultipliers), get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameLightingInterior + ' schedule'), @tol)
    assert_in_epsilon(2895 * get_available_hrs_ratio(unavailable_month_hrs, Schedule.LightingMonthlyMultipliers), get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameLightingExterior + ' schedule'), @tol)
    assert_in_epsilon(6673 * get_available_hrs_ratio(unavailable_month_hrs, Schedule.RefrigeratorMonthlyMultipliers), get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameRefrigerator + ' schedule'), @tol)
    assert_in_epsilon(2441 * get_available_hrs_ratio(unavailable_month_hrs, Schedule.CookingRangeMonthlyMultipliers), get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameCookingRange + ' schedule'), @tol)
    assert_in_epsilon(3285 * get_available_hrs_ratio(unavailable_month_hrs, Schedule.DishwasherMonthlyMultipliers), get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameDishwasher + ' schedule'), @tol)
    assert_in_epsilon(4248 * get_available_hrs_ratio(unavailable_month_hrs, Schedule.ClothesWasherMonthlyMultipliers), get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameClothesWasher + ' schedule'), @tol)
    assert_in_epsilon(4502 * get_available_hrs_ratio(unavailable_month_hrs, Schedule.ClothesDryerMonthlyMultipliers), get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameClothesDryer + ' schedule'), @tol)
    assert_in_epsilon(6880 * get_available_hrs_ratio(unavailable_month_hrs, Schedule.PlugLoadsOtherMonthlyMultipliers), get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameMiscPlugLoads + ' schedule'), @tol)
    assert_in_epsilon(3373 * get_available_hrs_ratio(unavailable_month_hrs, Schedule.PlugLoadsTVMonthlyMultipliers), get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameMiscTelevision + ' schedule'), @tol)
    assert_in_epsilon(4204 * get_available_hrs_ratio(unavailable_month_hrs, Schedule.FixturesMonthlyMultipliers), get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameFixtures + ' schedule'), @tol)
    assert_in_epsilon(4244 * get_available_hrs_ratio(unavailable_month_hrs, Schedule.RecirculationPumpMonthlyMultipliers), get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameHotWaterRecircPump + ' schedule'), @tol)
    assert_in_epsilon(5000, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameGeneralWaterUse + ' schedule'), @tol)
    assert_in_epsilon(8760 * get_available_hrs_ratio(unavailable_month_hrs), get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameMechanicalVentilationHouseFan + ' schedule'), @tol)
  end

  def test_stochastic_schedules
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-schedules-detailed-occupancy-stochastic.xml'))
    model, hpxml, hpxml_bldg = _test_measure(args_hash)

    schedule_file_names = []
    model.getScheduleFiles.each do |schedule_file|
      schedule_file_names << "#{schedule_file.name}"
    end
    assert_equal(12, schedule_file_names.size)

    schedules_paths = hpxml_bldg.header.schedules_filepaths.collect { |sfp|
      FilePath.check_path(sfp,
                          File.dirname(args_hash['hpxml_path']),
                          'Schedules')
    }

    sf = SchedulesFile.new(schedules_paths: schedules_paths,
                           year: @year,
                           unavailable_periods: hpxml.header.unavailable_periods,
                           output_path: @tmp_schedule_file_path)

    assert(schedule_file_names.include?(SchedulesFile::Columns[:Occupants].name))
    assert_in_epsilon(6689, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:Occupants].name, schedules: sf.tmp_schedules), @tol)
    assert(schedule_file_names.include?(SchedulesFile::Columns[:LightingInterior].name))
    assert_in_epsilon(2086, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:LightingInterior].name, schedules: sf.tmp_schedules), @tol)
    assert(!schedule_file_names.include?(SchedulesFile::Columns[:LightingGarage].name))
    assert_in_epsilon(2086, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:LightingGarage].name, schedules: sf.tmp_schedules), @tol)
    assert(!schedule_file_names.include?(SchedulesFile::Columns[:LightingExterior].name))
    assert_in_epsilon(4342, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameLightingExterior + ' schedule'), @tol)
    assert(!schedule_file_names.include?(SchedulesFile::Columns[:LightingExteriorHoliday].name))
    assert(!schedule_file_names.include?(SchedulesFile::Columns[:Refrigerator].name))
    assert(schedule_file_names.include?(SchedulesFile::Columns[:CookingRange].name))
    assert_in_epsilon(534, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:CookingRange].name, schedules: sf.tmp_schedules), @tol)
    assert(schedule_file_names.include?(SchedulesFile::Columns[:Dishwasher].name))
    assert_in_epsilon(213, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:Dishwasher].name, schedules: sf.tmp_schedules), @tol)
    assert(schedule_file_names.include?(SchedulesFile::Columns[:ClothesWasher].name))
    assert_in_epsilon(134, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:ClothesWasher].name, schedules: sf.tmp_schedules), @tol)
    assert(schedule_file_names.include?(SchedulesFile::Columns[:ClothesDryer].name))
    assert_in_epsilon(151, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:ClothesDryer].name, schedules: sf.tmp_schedules), @tol)
    assert(!schedule_file_names.include?(SchedulesFile::Columns[:CeilingFan].name))
    assert_in_epsilon(3016, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:CeilingFan].name, schedules: sf.tmp_schedules), @tol)
    assert(schedule_file_names.include?(SchedulesFile::Columns[:PlugLoadsOther].name))
    assert_in_epsilon(5388, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:PlugLoadsOther].name, schedules: sf.tmp_schedules), @tol)
    assert(schedule_file_names.include?(SchedulesFile::Columns[:PlugLoadsTV].name))
    assert_in_epsilon(1517, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:PlugLoadsTV].name, schedules: sf.tmp_schedules), @tol)
    assert(schedule_file_names.include?(SchedulesFile::Columns[:HotWaterDishwasher].name))
    assert_in_epsilon(273, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:HotWaterDishwasher].name, schedules: sf.tmp_schedules), @tol)
    assert(schedule_file_names.include?(SchedulesFile::Columns[:HotWaterClothesWasher].name))
    assert_in_epsilon(346, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:HotWaterClothesWasher].name, schedules: sf.tmp_schedules), @tol)
    assert(schedule_file_names.include?(SchedulesFile::Columns[:HotWaterFixtures].name))
    assert_in_epsilon(887, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:HotWaterFixtures].name, schedules: sf.tmp_schedules), @tol)
    assert(!schedule_file_names.include?(SchedulesFile::Columns[:GeneralWaterUse].name))
    assert_in_epsilon(8760, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameMechanicalVentilationHouseFan + ' schedule'), @tol)
    assert(!schedule_file_names.include?(SchedulesFile::Columns[:Sleeping].name))
    assert(!schedule_file_names.include?('Vacancy'))
    assert(!schedule_file_names.include?('Power Outage'))
  end

  def test_stochastic_vacancy_schedules
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-schedules-detailed-occupancy-stochastic-vacancy.xml'))
    model, hpxml, hpxml_bldg = _test_measure(args_hash)

    schedules_paths = hpxml_bldg.header.schedules_filepaths.collect { |sfp|
      FilePath.check_path(sfp,
                          File.dirname(args_hash['hpxml_path']),
                          'Schedules')
    }

    unavailable_period = hpxml.header.unavailable_periods[0]
    column_name = unavailable_period.column_name

    sf = SchedulesFile.new(schedules_paths: schedules_paths,
                           year: @year,
                           unavailable_periods: hpxml.header.unavailable_periods,
                           output_path: @tmp_schedule_file_path)

    unavailable_month_hrs = { 0 => 31.0 * 24.0, 11 => 31.0 * 24.0 }

    assert_in_epsilon(6689 - sf.period_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:Occupants].name, period: unavailable_period), sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:Occupants].name, schedules: sf.tmp_schedules), @tol)
    assert_in_epsilon(2086 - sf.period_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:LightingInterior].name, period: unavailable_period), sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:LightingInterior].name, schedules: sf.tmp_schedules), @tol)
    assert_in_epsilon(2086 - sf.period_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:LightingGarage].name, period: unavailable_period), sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:LightingGarage].name, schedules: sf.tmp_schedules), @tol)
    assert_in_epsilon(4342 * get_available_hrs_ratio(unavailable_month_hrs, Schedule.LightingMonthlyMultipliers), get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameLightingExterior + ' schedule'), @tol)
    assert_in_epsilon(534 - sf.period_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:CookingRange].name, period: unavailable_period), sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:CookingRange].name, schedules: sf.tmp_schedules), @tol)
    assert_in_epsilon(213 - sf.period_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:Dishwasher].name, period: unavailable_period), sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:Dishwasher].name, schedules: sf.tmp_schedules), @tol)
    assert_in_epsilon(134 - sf.period_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:ClothesWasher].name, period: unavailable_period), sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:ClothesWasher].name, schedules: sf.tmp_schedules), @tol)
    assert_in_epsilon(151 - sf.period_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:ClothesDryer].name, period: unavailable_period), sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:ClothesDryer].name, schedules: sf.tmp_schedules), @tol)
    assert_in_epsilon(3016 - sf.period_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:CeilingFan].name, period: unavailable_period), sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:CeilingFan].name, schedules: sf.tmp_schedules), @tol)
    assert_in_epsilon(5388 - sf.period_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:PlugLoadsOther].name, period: unavailable_period), sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:PlugLoadsOther].name, schedules: sf.tmp_schedules), @tol)
    assert_in_epsilon(1517 - sf.period_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:PlugLoadsTV].name, period: unavailable_period), sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:PlugLoadsTV].name, schedules: sf.tmp_schedules), @tol)
    assert_in_epsilon(273 - sf.period_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:HotWaterDishwasher].name, period: unavailable_period), sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:HotWaterDishwasher].name, schedules: sf.tmp_schedules), @tol)
    assert_in_epsilon(346 - sf.period_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:HotWaterClothesWasher].name, period: unavailable_period), sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:HotWaterClothesWasher].name, schedules: sf.tmp_schedules), @tol)
    assert_in_epsilon(887 - sf.period_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:HotWaterFixtures].name, period: unavailable_period), sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:HotWaterFixtures].name, schedules: sf.tmp_schedules), @tol)
    assert_in_epsilon(8760, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameMechanicalVentilationHouseFan + ' schedule'), @tol)
    assert(!sf.schedules.keys.include?(SchedulesFile::Columns[:Sleeping].name))
    assert_in_epsilon(unavailable_month_hrs.values.sum, sf.annual_equivalent_full_load_hrs(col_name: column_name, schedules: sf.tmp_schedules), 0.001)
  end

  def test_stochastic_vacancy_schedules2
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-schedules-detailed-occupancy-stochastic-vacancy.xml'))
    _model, hpxml, _hpxml_bldg = _test_measure(args_hash)

    column_name = hpxml.header.unavailable_periods[0].column_name

    # intentionally overlaps the first vacancy period
    hpxml.header.unavailable_periods.add(column_name: column_name,
                                         begin_month: 1,
                                         begin_day: 25,
                                         end_month: 2,
                                         end_day: 28,
                                         natvent_availability: HPXML::ScheduleUnavailable)

    XMLHelper.write_file(hpxml.to_doc(), @tmp_hpxml_path)
    args_hash['hpxml_path'] = @tmp_hpxml_path
    model, hpxml, hpxml_bldg = _test_measure(args_hash)

    schedules_paths = hpxml_bldg.header.schedules_filepaths.collect { |sfp|
      FilePath.check_path(sfp,
                          File.dirname(args_hash['hpxml_path']),
                          'Schedules')
    }

    sf = SchedulesFile.new(schedules_paths: schedules_paths,
                           year: @year,
                           unavailable_periods: hpxml.header.unavailable_periods,
                           output_path: @tmp_schedule_file_path)

    hpxml.header.unavailable_periods.add(column_name: column_name,
                                         begin_month: 12,
                                         begin_day: 1,
                                         end_month: 2,
                                         end_day: 28)
    unavailable_period = hpxml.header.unavailable_periods[-1]

    unavailable_month_hrs = { 0 => 31.0 * 24.0, 1 => 28.0 * 24.0, 11 => 31.0 * 24.0 }

    assert_in_epsilon(6689 - sf.period_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:Occupants].name, period: unavailable_period), sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:Occupants].name, schedules: sf.tmp_schedules), @tol)
    assert_in_epsilon(2086 - sf.period_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:LightingInterior].name, period: unavailable_period), sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:LightingInterior].name, schedules: sf.tmp_schedules), @tol)
    assert_in_epsilon(2086 - sf.period_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:LightingGarage].name, period: unavailable_period), sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:LightingGarage].name, schedules: sf.tmp_schedules), @tol)
    assert_in_epsilon(4342 * get_available_hrs_ratio(unavailable_month_hrs, Schedule.LightingMonthlyMultipliers), get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameLightingExterior + ' schedule'), @tol)
    assert_in_epsilon(534 - sf.period_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:CookingRange].name, period: unavailable_period), sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:CookingRange].name, schedules: sf.tmp_schedules), @tol)
    assert_in_epsilon(213 - sf.period_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:Dishwasher].name, period: unavailable_period), sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:Dishwasher].name, schedules: sf.tmp_schedules), @tol)
    assert_in_epsilon(134 - sf.period_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:ClothesWasher].name, period: unavailable_period), sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:ClothesWasher].name, schedules: sf.tmp_schedules), @tol)
    assert_in_epsilon(151 - sf.period_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:ClothesDryer].name, period: unavailable_period), sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:ClothesDryer].name, schedules: sf.tmp_schedules), @tol)
    assert_in_epsilon(3016 - sf.period_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:CeilingFan].name, period: unavailable_period), sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:CeilingFan].name, schedules: sf.tmp_schedules), @tol)
    assert_in_epsilon(5388 - sf.period_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:PlugLoadsOther].name, period: unavailable_period), sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:PlugLoadsOther].name, schedules: sf.tmp_schedules), @tol)
    assert_in_epsilon(1517 - sf.period_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:PlugLoadsTV].name, period: unavailable_period), sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:PlugLoadsTV].name, schedules: sf.tmp_schedules), @tol)
    assert_in_epsilon(273 - sf.period_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:HotWaterDishwasher].name, period: unavailable_period), sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:HotWaterDishwasher].name, schedules: sf.tmp_schedules), @tol)
    assert_in_epsilon(346 - sf.period_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:HotWaterClothesWasher].name, period: unavailable_period), sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:HotWaterClothesWasher].name, schedules: sf.tmp_schedules), @tol)
    assert_in_epsilon(887 - sf.period_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:HotWaterFixtures].name, period: unavailable_period), sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:HotWaterFixtures].name, schedules: sf.tmp_schedules), @tol)
    assert_in_epsilon(8760, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameMechanicalVentilationHouseFan + ' schedule'), @tol)
    assert(!sf.schedules.keys.include?(SchedulesFile::Columns[:Sleeping].name))
    assert_in_epsilon(unavailable_month_hrs.values.sum, sf.annual_equivalent_full_load_hrs(col_name: column_name, schedules: sf.tmp_schedules), 0.001)
  end

  def test_stochastic_vacancy_year_round_schedules
    args_hash = {}
    hpxml_path = File.absolute_path(File.join(sample_files_dir, 'base-schedules-detailed-occupancy-stochastic-vacancy.xml'))
    hpxml = HPXML.new(hpxml_path: hpxml_path)
    hpxml.header.unavailable_periods[0].begin_month = 1
    hpxml.header.unavailable_periods[0].begin_day = 1
    hpxml.header.unavailable_periods[0].end_month = 12
    hpxml.header.unavailable_periods[0].end_day = 31
    XMLHelper.write_file(hpxml.to_doc(), @tmp_hpxml_path)
    args_hash['hpxml_path'] = @tmp_hpxml_path
    model, hpxml, hpxml_bldg = _test_measure(args_hash)

    schedules_paths = hpxml_bldg.header.schedules_filepaths.collect { |sfp|
      FilePath.check_path(sfp,
                          File.dirname(args_hash['hpxml_path']),
                          'Schedules')
    }

    column_name = hpxml.header.unavailable_periods[0].column_name

    sf = SchedulesFile.new(schedules_paths: schedules_paths,
                           year: @year,
                           unavailable_periods: hpxml.header.unavailable_periods,
                           output_path: @tmp_schedule_file_path)

    assert_equal(0, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:Occupants].name, schedules: sf.tmp_schedules))
    assert_equal(0, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:LightingInterior].name, schedules: sf.tmp_schedules))
    assert_equal(0, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:LightingGarage].name, schedules: sf.tmp_schedules))
    assert_equal(0, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameLightingExterior + ' schedule'))
    assert_equal(0, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:CookingRange].name, schedules: sf.tmp_schedules))
    assert_equal(0, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:Dishwasher].name, schedules: sf.tmp_schedules))
    assert_equal(0, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:ClothesWasher].name, schedules: sf.tmp_schedules))
    assert_equal(0, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:ClothesDryer].name, schedules: sf.tmp_schedules))
    assert_equal(0, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:CeilingFan].name, schedules: sf.tmp_schedules))
    assert_equal(0, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:PlugLoadsOther].name, schedules: sf.tmp_schedules))
    assert_equal(0, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:PlugLoadsTV].name, schedules: sf.tmp_schedules))
    assert_equal(0, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:HotWaterDishwasher].name, schedules: sf.tmp_schedules))
    assert_equal(0, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:HotWaterClothesWasher].name, schedules: sf.tmp_schedules))
    assert_equal(0, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:HotWaterFixtures].name, schedules: sf.tmp_schedules))
    assert_in_epsilon(8760, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameMechanicalVentilationHouseFan + ' schedule'), @tol)
    assert(!sf.schedules.keys.include?(SchedulesFile::Columns[:Sleeping].name))
    assert_in_epsilon(Constants.NumHoursInYear(@year), sf.annual_equivalent_full_load_hrs(col_name: column_name, schedules: sf.tmp_schedules), @tol)
  end

  def test_stochastic_power_outage_schedules
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-schedules-detailed-occupancy-stochastic-power-outage.xml'))
    model, hpxml, hpxml_bldg = _test_measure(args_hash)

    schedules_paths = hpxml_bldg.header.schedules_filepaths.collect { |sfp|
      FilePath.check_path(sfp,
                          File.dirname(args_hash['hpxml_path']),
                          'Schedules')
    }

    unavailable_period = hpxml.header.unavailable_periods[0]
    column_name = unavailable_period.column_name

    sf = SchedulesFile.new(schedules_paths: schedules_paths,
                           year: @year,
                           unavailable_periods: hpxml.header.unavailable_periods,
                           output_path: @tmp_schedule_file_path)

    unavailable_month_hrs = { 0 => 31.0 * 24.0 - 10.0, 11 => 31.0 * 24.0 - 5.0 }

    assert_in_epsilon(6689, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:Occupants].name, schedules: sf.tmp_schedules), @tol)
    assert_in_epsilon(2086 - sf.period_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:LightingInterior].name, period: unavailable_period), sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:LightingInterior].name, schedules: sf.tmp_schedules), @tol)
    assert_in_epsilon(2086 - sf.period_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:LightingGarage].name, period: unavailable_period), sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:LightingGarage].name, schedules: sf.tmp_schedules), @tol)
    assert_in_epsilon(4342 * get_available_hrs_ratio(unavailable_month_hrs, Schedule.LightingMonthlyMultipliers), get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameLightingExterior + ' schedule'), @tol)
    assert_in_epsilon(534 - sf.period_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:CookingRange].name, period: unavailable_period), sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:CookingRange].name, schedules: sf.tmp_schedules), @tol)
    assert_in_epsilon(213 - sf.period_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:Dishwasher].name, period: unavailable_period), sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:Dishwasher].name, schedules: sf.tmp_schedules), @tol)
    assert_in_epsilon(134 - sf.period_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:ClothesWasher].name, period: unavailable_period), sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:ClothesWasher].name, schedules: sf.tmp_schedules), @tol)
    assert_in_epsilon(151 - sf.period_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:ClothesDryer].name, period: unavailable_period), sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:ClothesDryer].name, schedules: sf.tmp_schedules), @tol)
    assert_in_epsilon(3016 - sf.period_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:CeilingFan].name, period: unavailable_period), sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:CeilingFan].name, schedules: sf.tmp_schedules), @tol)
    assert_in_epsilon(5388 - sf.period_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:PlugLoadsOther].name, period: unavailable_period), sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:PlugLoadsOther].name, schedules: sf.tmp_schedules), @tol)
    assert_in_epsilon(1517 - sf.period_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:PlugLoadsTV].name, period: unavailable_period), sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:PlugLoadsTV].name, schedules: sf.tmp_schedules), @tol)
    assert_in_epsilon(273 - sf.period_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:HotWaterDishwasher].name, period: unavailable_period), sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:HotWaterDishwasher].name, schedules: sf.tmp_schedules), @tol)
    assert_in_epsilon(346 - sf.period_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:HotWaterClothesWasher].name, period: unavailable_period), sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:HotWaterClothesWasher].name, schedules: sf.tmp_schedules), @tol)
    assert_in_epsilon(887 - sf.period_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:HotWaterFixtures].name, period: unavailable_period), sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:HotWaterFixtures].name, schedules: sf.tmp_schedules), @tol)
    assert_in_epsilon(8760 * get_available_hrs_ratio(unavailable_month_hrs), get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameMechanicalVentilationHouseFan + ' schedule'), @tol)
    assert(!sf.schedules.keys.include?(SchedulesFile::Columns[:Sleeping].name))
    assert_in_epsilon(unavailable_month_hrs.values.sum, sf.annual_equivalent_full_load_hrs(col_name: column_name, schedules: sf.tmp_schedules), 0.001)
  end

  def test_stochastic_power_outage_schedules2
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-schedules-detailed-occupancy-stochastic-power-outage.xml'))
    _model, hpxml, _hpxml_bldg = _test_measure(args_hash)

    column_name = hpxml.header.unavailable_periods[0].column_name

    # intentionally overlaps the first power outage period
    hpxml.header.unavailable_periods.add(column_name: column_name,
                                         begin_month: 1,
                                         begin_day: 25,
                                         begin_hour: 0,
                                         end_month: 2,
                                         end_day: 27,
                                         end_hour: 24)

    XMLHelper.write_file(hpxml.to_doc(), @tmp_hpxml_path)
    args_hash['hpxml_path'] = @tmp_hpxml_path
    model, hpxml, hpxml_bldg = _test_measure(args_hash)

    schedules_paths = hpxml_bldg.header.schedules_filepaths.collect { |sfp|
      FilePath.check_path(sfp,
                          File.dirname(args_hash['hpxml_path']),
                          'Schedules')
    }

    sf = SchedulesFile.new(schedules_paths: schedules_paths,
                           year: @year,
                           unavailable_periods: hpxml.header.unavailable_periods,
                           output_path: @tmp_schedule_file_path)

    hpxml.header.unavailable_periods.add(column_name: column_name,
                                         begin_month: 12,
                                         begin_day: 1,
                                         end_month: 2,
                                         end_day: 27,
                                         end_hour: 24)
    unavailable_period = hpxml.header.unavailable_periods[-1]

    unavailable_month_hrs = { 0 => 31.0 * 24.0, 1 => 28.0 * 24.0 - 24.0, 11 => 31.0 * 24.0 - 5.0 }

    assert_in_epsilon(6689, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:Occupants].name, schedules: sf.tmp_schedules), @tol)
    assert_in_epsilon(2086 - sf.period_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:LightingInterior].name, period: unavailable_period), sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:LightingInterior].name, schedules: sf.tmp_schedules), @tol)
    assert_in_epsilon(2086 - sf.period_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:LightingGarage].name, period: unavailable_period), sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:LightingGarage].name, schedules: sf.tmp_schedules), @tol)
    assert_in_epsilon(4342 * get_available_hrs_ratio(unavailable_month_hrs, Schedule.LightingMonthlyMultipliers), get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameLightingExterior + ' schedule'), @tol)
    assert_in_epsilon(534 - sf.period_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:CookingRange].name, period: unavailable_period), sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:CookingRange].name, schedules: sf.tmp_schedules), @tol)
    assert_in_epsilon(213 - sf.period_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:Dishwasher].name, period: unavailable_period), sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:Dishwasher].name, schedules: sf.tmp_schedules), @tol)
    assert_in_epsilon(134 - sf.period_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:ClothesWasher].name, period: unavailable_period), sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:ClothesWasher].name, schedules: sf.tmp_schedules), @tol)
    assert_in_epsilon(151 - sf.period_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:ClothesDryer].name, period: unavailable_period), sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:ClothesDryer].name, schedules: sf.tmp_schedules), @tol)
    assert_in_epsilon(3016 - sf.period_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:CeilingFan].name, period: unavailable_period), sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:CeilingFan].name, schedules: sf.tmp_schedules), @tol)
    assert_in_epsilon(5388 - sf.period_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:PlugLoadsOther].name, period: unavailable_period), sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:PlugLoadsOther].name, schedules: sf.tmp_schedules), @tol)
    assert_in_epsilon(1517 - sf.period_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:PlugLoadsTV].name, period: unavailable_period), sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:PlugLoadsTV].name, schedules: sf.tmp_schedules), @tol)
    assert_in_epsilon(273 - sf.period_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:HotWaterDishwasher].name, period: unavailable_period), sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:HotWaterDishwasher].name, schedules: sf.tmp_schedules), @tol)
    assert_in_epsilon(346 - sf.period_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:HotWaterClothesWasher].name, period: unavailable_period), sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:HotWaterClothesWasher].name, schedules: sf.tmp_schedules), @tol)
    assert_in_epsilon(887 - sf.period_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:HotWaterFixtures].name, period: unavailable_period), sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:HotWaterFixtures].name, schedules: sf.tmp_schedules), @tol)
    assert_in_epsilon(8760 * get_available_hrs_ratio(unavailable_month_hrs), get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameMechanicalVentilationHouseFan + ' schedule'), @tol)
    assert(!sf.schedules.keys.include?(SchedulesFile::Columns[:Sleeping].name))
    assert_in_epsilon(unavailable_month_hrs.values.sum, sf.annual_equivalent_full_load_hrs(col_name: column_name, schedules: sf.tmp_schedules), 0.001)
  end

  def test_set_unavailable_periods_lighting
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base.xml'))

    begin_month = 1
    begin_day = 1
    begin_hour = 0
    end_month = 12
    end_day = 31
    end_hour = 24

    sch_name = Constants.ObjectNameLightingInterior + ' schedule'

    # hours not specified
    model, hpxml, _hpxml_bldg = _test_measure(args_hash)
    year = model.getYearDescription.assumedYear

    schedule = model.getScheduleRulesets.find { |schedule| schedule.name.to_s == sch_name }
    unavailable_periods = _add_unavailable_period(hpxml, 'Power Outage', begin_month, begin_day, begin_hour, end_month, end_day, end_hour)

    schedule_rules = schedule.scheduleRules
    Schedule.set_unavailable_periods(schedule, sch_name, unavailable_periods, year)
    unavailable_schedule_rules = schedule.scheduleRules - schedule_rules

    assert_equal(1, unavailable_schedule_rules.size)

    _test_day_schedule(schedule, begin_month, begin_day, year, 0, 24)
    _test_day_schedule(schedule, begin_month + 5, begin_day + 10, year, 0, 24)
    _test_day_schedule(schedule, end_month, end_day, year, 0, 24)

    # 1 calendar day
    end_month = 1
    end_day = 1
    end_hour = 5

    model, hpxml, _hpxml_bldg = _test_measure(args_hash)
    year = model.getYearDescription.assumedYear

    schedule = model.getScheduleRulesets.find { |schedule| schedule.name.to_s == sch_name }
    unavailable_periods = _add_unavailable_period(hpxml, 'Power Outage', begin_month, begin_day, begin_hour, end_month, end_day, end_hour) # note the change of end month/day

    schedule_rules = schedule.scheduleRules
    Schedule.set_unavailable_periods(schedule, sch_name, unavailable_periods, year)
    unavailable_schedule_rules = schedule.scheduleRules - schedule_rules

    assert_equal(1, unavailable_schedule_rules.size)

    _test_day_schedule(schedule, begin_month, begin_day, year, 0, end_hour)
    _test_day_schedule(schedule, end_month, begin_day + 1, year, nil, nil)

    # 2 calendar days, partial first day
    begin_hour = 5
    end_day = 2
    end_hour = 24

    model, hpxml, _hpxml_bldg = _test_measure(args_hash)
    year = model.getYearDescription.assumedYear

    schedule = model.getScheduleRulesets.find { |schedule| schedule.name.to_s == sch_name }
    unavailable_periods = _add_unavailable_period(hpxml, 'Power Outage', begin_month, begin_day, begin_hour, end_month, end_day, end_hour) # note the change of end month/day

    schedule_rules = schedule.scheduleRules
    Schedule.set_unavailable_periods(schedule, sch_name, unavailable_periods, year)
    unavailable_schedule_rules = schedule.scheduleRules - schedule_rules

    assert_equal(2, unavailable_schedule_rules.size)

    _test_day_schedule(schedule, begin_month, begin_day, year, begin_hour, 24)
    _test_day_schedule(schedule, end_month, begin_day + 1, year, 0, 24)
    _test_day_schedule(schedule, end_month, begin_day + 2, year, nil, nil)

    # 2 calendar days, partial last day
    begin_hour = 0
    end_day = 2
    end_hour = 11

    model, hpxml, _hpxml_bldg = _test_measure(args_hash)
    year = model.getYearDescription.assumedYear

    schedule = model.getScheduleRulesets.find { |schedule| schedule.name.to_s == sch_name }
    unavailable_periods = _add_unavailable_period(hpxml, 'Power Outage', begin_month, begin_day, begin_hour, end_month, end_day, end_hour) # note the change of end month/day

    schedule_rules = schedule.scheduleRules
    Schedule.set_unavailable_periods(schedule, sch_name, unavailable_periods, year)
    unavailable_schedule_rules = schedule.scheduleRules - schedule_rules

    assert_equal(2, unavailable_schedule_rules.size)

    _test_day_schedule(schedule, begin_month, begin_day, year, 0, 24)
    _test_day_schedule(schedule, end_month, end_day, year, 0, end_hour)
    _test_day_schedule(schedule, end_month, end_day + 1, year, nil, nil)

    # wrap around
    begin_month = 12
    begin_day = 1
    begin_hour = 5
    end_month = 1
    end_day = 31
    end_hour = 12

    model, hpxml, _hpxml_bldg = _test_measure(args_hash)
    year = model.getYearDescription.assumedYear

    schedule = model.getScheduleRulesets.find { |schedule| schedule.name.to_s == sch_name }
    unavailable_periods = _add_unavailable_period(hpxml, 'Power Outage', begin_month, begin_day, begin_hour, end_month, end_day, end_hour) # note the change of end month/day

    schedule_rules = schedule.scheduleRules
    Schedule.set_unavailable_periods(schedule, sch_name, unavailable_periods, year)
    unavailable_schedule_rules = schedule.scheduleRules - schedule_rules

    assert_equal(3, unavailable_schedule_rules.size)

    _test_day_schedule(schedule, begin_month, begin_day, year, begin_hour, 24)
    _test_day_schedule(schedule, end_month + 5, begin_day + 10, year, nil, nil)
    _test_day_schedule(schedule, end_month, end_day, year, 0, end_hour)
  end

  def test_set_unavailable_periods_natvent
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base.xml'))

    # normal availability
    begin_month = 1
    begin_day = 1
    begin_hour = 0
    end_month = 6
    end_day = 30
    end_hour = 24
    natvent_availability = HPXML::ScheduleRegular

    sch_name = "#{Constants.ObjectNameNaturalVentilation} schedule"

    model, hpxml, _hpxml_bldg = _test_measure(args_hash)
    year = model.getYearDescription.assumedYear

    schedule = model.getScheduleRulesets.find { |schedule| schedule.name.to_s == sch_name }
    unavailable_periods = _add_unavailable_period(hpxml, 'Power Outage', begin_month, begin_day, begin_hour, end_month, end_day, end_hour, natvent_availability)

    schedule_rules = schedule.scheduleRules
    Schedule.set_unavailable_periods(schedule, sch_name, unavailable_periods, year)
    unavailable_schedule_rules = schedule.scheduleRules - schedule_rules

    assert_equal(0, unavailable_schedule_rules.size)

    _test_day_schedule(schedule, begin_month, begin_day, year, 0, 24, 1)
    _test_day_schedule(schedule, begin_month, begin_day + 1, year, 0, 24, 0)

    # not available
    natvent_availability = HPXML::ScheduleUnavailable

    model, hpxml, _hpxml_bldg = _test_measure(args_hash)
    year = model.getYearDescription.assumedYear

    schedule = model.getScheduleRulesets.find { |schedule| schedule.name.to_s == sch_name }
    unavailable_periods = _add_unavailable_period(hpxml, 'Power Outage', begin_month, begin_day, begin_hour, end_month, end_day, end_hour, natvent_availability)

    schedule_rules = schedule.scheduleRules
    Schedule.set_unavailable_periods(schedule, sch_name, unavailable_periods, year)
    unavailable_schedule_rules = schedule.scheduleRules - schedule_rules

    assert_equal(1, unavailable_schedule_rules.size)

    _test_day_schedule(schedule, begin_month, begin_day, year, 0, 24, 0)
    _test_day_schedule(schedule, begin_month, begin_day + 1, year, 0, 24, 0)

    # available
    natvent_availability = HPXML::ScheduleAvailable

    model, hpxml, _hpxml_bldg = _test_measure(args_hash)
    year = model.getYearDescription.assumedYear

    schedule = model.getScheduleRulesets.find { |schedule| schedule.name.to_s == sch_name }
    unavailable_periods = _add_unavailable_period(hpxml, 'Power Outage', begin_month, begin_day, begin_hour, end_month, end_day, end_hour, natvent_availability)

    schedule_rules = schedule.scheduleRules
    Schedule.set_unavailable_periods(schedule, sch_name, unavailable_periods, year)
    unavailable_schedule_rules = schedule.scheduleRules - schedule_rules

    assert_equal(1, unavailable_schedule_rules.size)

    _test_day_schedule(schedule, begin_month, begin_day, year, 0, 24, 1)
    _test_day_schedule(schedule, begin_month, begin_day + 1, year, 0, 24, 1)
  end

  def test_set_unavailable_periods_leap_year
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-location-AMY-2012.xml'))

    begin_month = 1
    begin_day = 1
    begin_hour = 0
    end_month = 3
    end_day = 30
    end_hour = 24

    sch_name = Constants.ObjectNameLightingInterior + ' schedule'

    model, hpxml, _hpxml_bldg = _test_measure(args_hash)
    year = model.getYearDescription.assumedYear
    assert_equal(2012, year)

    schedule = model.getScheduleRulesets.find { |schedule| schedule.name.to_s == sch_name }
    unavailable_periods = _add_unavailable_period(hpxml, 'Power Outage', begin_month, begin_day, begin_hour, end_month, end_day, end_hour)

    schedule_rules = schedule.scheduleRules
    Schedule.set_unavailable_periods(schedule, sch_name, unavailable_periods, year)
    unavailable_schedule_rules = schedule.scheduleRules - schedule_rules

    assert_equal(1, unavailable_schedule_rules.size)

    _test_day_schedule(schedule, 2, 28, year, 0, 24)
    _test_day_schedule(schedule, 2, 29, year, 0, 24)
    _test_day_schedule(schedule, 3, 1, year, 0, 24)
  end

  def test_unavailable_period_csv_entries
    csv_entries = Schedule.get_unavailable_periods_csv_data.map { |h| h['Schedule Name'] }
    unavailable_period_columns = SchedulesFile::Columns.values.select { |c| c.used_by_unavailable_periods }.map { |c| c.name }.sort
    assert_equal(unavailable_period_columns.sort, csv_entries.sort)
  end

  def _add_unavailable_period(hpxml, column_name, begin_month, begin_day, begin_hour, end_month, end_day, end_hour, natvent_availability = nil)
    hpxml.header.unavailable_periods.add(column_name: column_name,
                                         begin_month: begin_month,
                                         begin_day: begin_day,
                                         begin_hour: begin_hour,
                                         end_month: end_month,
                                         end_day: end_day,
                                         end_hour: end_hour,
                                         natvent_availability: natvent_availability)
    return hpxml.header.unavailable_periods
  end

  def _test_day_schedule(schedule, month, day, year, begin_hour, end_hour, expected_value = 0)
    month_of_year = OpenStudio::MonthOfYear.new(month)
    date = OpenStudio::Date.new(month_of_year, day, year)
    day_schedule = schedule.getDaySchedules(date, date)[0]

    (0..23).each do |h|
      time = OpenStudio::Time.new(0, h + 1, 0, 0)
      actual_value = day_schedule.getValue(time)
      if (begin_hour.nil? && end_hour.nil?) || (h < begin_hour) || (h >= end_hour)
        assert_operator(actual_value, :>, expected_value)
      else
        assert_equal(expected_value, actual_value)
      end
    end
  end

  def _test_measure(args_hash)
    # create an instance of the measure
    measure = HPXMLtoOpenStudio.new

    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    model = OpenStudio::Model::Model.new

    # get arguments
    args_hash['output_dir'] = File.dirname(__FILE__)
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args_hash.has_key?(arg.name)
        assert(temp_arg_var.setValue(args_hash[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end

    # run the measure
    measure.run(model, runner, argument_map)
    result = runner.result

    # show the output
    show_output(result) unless result.value.valueName == 'Success'

    # assert that it ran correctly
    assert_equal('Success', result.value.valueName)

    hpxml = HPXML.new(hpxml_path: args_hash['hpxml_path'])

    File.delete(File.join(File.dirname(__FILE__), 'in.xml'))

    return model, hpxml, hpxml.buildings[0]
  end
end
