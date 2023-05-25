# frozen_string_literal: true

require_relative '../resources/minitest_helper'
require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'fileutils'
require_relative '../measure.rb'
require_relative '../resources/util.rb'

class HPXMLtoOpenStudioSchedulesTest < MiniTest::Test
  def setup
    @root_path = File.absolute_path(File.join(File.dirname(__FILE__), '..', '..'))
    @sample_files_path = File.join(@root_path, 'workflow', 'sample_files')
    @tmp_hpxml_path = File.join(@sample_files_path, 'tmp.xml')
    @tmp_schedule_file_path = File.join(@sample_files_path, 'tmp.csv')
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

      return Schedule.annual_equivalent_full_load_hrs(2007, schedule)
    end
    flunk "Could not find schedule '#{name}'."
  end

  def test_default_schedules
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base.xml'))
    model, _hpxml = _test_measure(args_hash)

    schedule_constants = 11
    schedule_rulesets = 17
    schedule_fixed_intervals = 1
    schedule_files = 0

    assert_equal(schedule_constants, model.getScheduleConstants.size)
    assert_equal(schedule_rulesets, model.getScheduleRulesets.size)
    assert_equal(schedule_fixed_intervals, model.getScheduleFixedIntervals.size)
    assert_equal(schedule_files, model.getScheduleFiles.size)
    assert_equal(model.getSchedules.size, schedule_constants + schedule_rulesets + schedule_fixed_intervals + schedule_files)

    assert_in_epsilon(6020, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameOccupants + ' schedule'), 0.1)
    assert_in_epsilon(3321, get_annual_equivalent_full_load_hrs(model, 'lighting schedule'), 0.1)
    assert_in_epsilon(2763, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameExteriorLighting + ' schedule'), 0.1)
    assert_in_epsilon(6673, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameRefrigerator), 0.1)
    assert_in_epsilon(2224, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameCookingRange), 0.1)
    assert_in_epsilon(2994, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameDishwasher), 0.1)
    assert_in_epsilon(4158, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameClothesWasher), 0.1)
    assert_in_epsilon(4502, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameClothesDryer), 0.1)
    assert_in_epsilon(5468, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameMiscPlugLoads + ' schedule'), 0.1)
    assert_in_epsilon(2256, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameMiscTelevision + ' schedule'), 0.1)
    assert_in_epsilon(4204, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameFixtures), 0.1)
  end

  def test_simple_schedules
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-schedules-simple.xml'))
    model, _hpxml = _test_measure(args_hash)

    schedule_constants = 11
    schedule_rulesets = 17
    schedule_fixed_intervals = 1
    schedule_files = 0

    assert_equal(schedule_constants, model.getScheduleConstants.size)
    assert_equal(schedule_rulesets, model.getScheduleRulesets.size)
    assert_equal(schedule_fixed_intervals, model.getScheduleFixedIntervals.size)
    assert_equal(schedule_files, model.getScheduleFiles.size)
    assert_equal(model.getSchedules.size, schedule_constants + schedule_rulesets + schedule_fixed_intervals + schedule_files)

    assert_in_epsilon(6020, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameOccupants + ' schedule'), 0.1)
    assert_in_epsilon(3321, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameInteriorLighting + ' schedule'), 0.1)
    assert_in_epsilon(2763, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameExteriorLighting + ' schedule'), 0.1)
    assert_in_epsilon(6673, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameRefrigerator), 0.1)
    assert_in_epsilon(2224, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameCookingRange), 0.1)
    assert_in_epsilon(2994, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameDishwasher), 0.1)
    assert_in_epsilon(4158, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameClothesWasher), 0.1)
    assert_in_epsilon(4502, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameClothesDryer), 0.1)
    assert_in_epsilon(5468, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameMiscPlugLoads + ' schedule'), 0.1)
    assert_in_epsilon(2956, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameMiscTelevision + ' schedule'), 0.1)
    assert_in_epsilon(4204, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameFixtures), 0.1)
  end

  def test_simple_vacancy_schedules
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-schedules-simple-vacancy.xml'))
    model, _hpxml = _test_measure(args_hash)

    vacancy_hrs = 31.0 * 2.0 * 24.0
    occupied_ratio = (1.0 - vacancy_hrs / 8760.0)

    assert_in_epsilon(6020 * occupied_ratio, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameOccupants + ' schedule'), 0.1)
    assert_in_epsilon(3321 * occupied_ratio, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameInteriorLighting + ' schedule'), 0.1)
    assert_in_epsilon(2763 * occupied_ratio, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameExteriorLighting + ' schedule'), 0.1)
    assert_in_epsilon(6673, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameRefrigerator), 0.1)
    assert_in_epsilon(2224 * occupied_ratio, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameCookingRange), 0.1)
    assert_in_epsilon(2994 * occupied_ratio, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameDishwasher), 0.1)
    assert_in_epsilon(4158 * occupied_ratio, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameClothesWasher), 0.1)
    assert_in_epsilon(4502 * occupied_ratio, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameClothesDryer), 0.1)
    assert_in_epsilon(5468 * occupied_ratio, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameMiscPlugLoads + ' schedule'), 0.1)
    assert_in_epsilon(2956 * occupied_ratio, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameMiscTelevision + ' schedule'), 0.1)
    assert_in_epsilon(4204 * occupied_ratio, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameFixtures), 0.1)
  end

  def test_simple_vacancy_year_round_schedules
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-schedules-simple-vacancy-year-round.xml'))
    model, _hpxml = _test_measure(args_hash)

    vacancy_hrs = 8760.0
    occupied_ratio = (1.0 - vacancy_hrs / 8760.0)

    assert_in_epsilon(6020 * occupied_ratio, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameOccupants + ' schedule'), 0.1)
    assert_in_epsilon(3321 * occupied_ratio, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameInteriorLighting + ' schedule'), 0.1)
    assert_in_epsilon(2763 * occupied_ratio, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameExteriorLighting + ' schedule'), 0.1)
    assert_in_epsilon(6673, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameRefrigerator), 0.1)
    assert_in_epsilon(2224 * occupied_ratio, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameCookingRange), 0.1)
    assert_in_epsilon(2994 * occupied_ratio, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameDishwasher), 0.1)
    assert_in_epsilon(4158 * occupied_ratio, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameClothesWasher), 0.1)
    assert_in_epsilon(4502 * occupied_ratio, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameClothesDryer), 0.1)
    assert_in_epsilon(5468 * occupied_ratio, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameMiscPlugLoads + ' schedule'), 0.1)
    assert_in_epsilon(2956 * occupied_ratio, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameMiscTelevision + ' schedule'), 0.1)
    assert_in_epsilon(4204 * occupied_ratio, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameFixtures), 0.1)
  end

  def test_simple_power_outage_schedules
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-schedules-simple-power-outage.xml'))
    model, _hpxml = _test_measure(args_hash)

    outage_hrs = 31.0 * 1.0 * 24.0 - 15.0
    powered_ratio = (1.0 - outage_hrs / 8760.0)

    assert_in_epsilon(6020, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameOccupants + ' schedule'), 0.1)
    assert_in_epsilon(3321 * powered_ratio, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameInteriorLighting + ' schedule'), 0.1)
    assert_in_epsilon(2763 * powered_ratio, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameExteriorLighting + ' schedule'), 0.1)
    assert_in_epsilon(6673 * powered_ratio, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameRefrigerator), 0.1)
    assert_in_epsilon(2224 * powered_ratio, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameCookingRange), 0.1)
    assert_in_epsilon(2994 * powered_ratio, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameDishwasher), 0.1)
    assert_in_epsilon(4158 * powered_ratio, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameClothesWasher), 0.1)
    assert_in_epsilon(4502 * powered_ratio, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameClothesDryer), 0.1)
    assert_in_epsilon(5468 * powered_ratio, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameMiscPlugLoads + ' schedule'), 0.1)
    assert_in_epsilon(2956 * powered_ratio, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameMiscTelevision + ' schedule'), 0.1)
    assert_in_epsilon(4204 * powered_ratio, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameFixtures), 0.1)
    assert_in_epsilon(8760 * powered_ratio, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameMechanicalVentilationHouseFan + ' schedule'), 0.1)
  end

  def test_stochastic_schedules
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-schedules-detailed-occupancy-stochastic.xml'))
    model, _hpxml = _test_measure(args_hash)

    assert_equal(11, model.getScheduleFiles.size)

    schedule_file_names = []
    model.getScheduleFiles.each do |schedule_file|
      schedule_file_names << "#{schedule_file.name}"
    end
    assert(schedule_file_names.include?(SchedulesFile::ColumnOccupants))
    assert(schedule_file_names.include?(SchedulesFile::ColumnLightingInterior))
    assert(!schedule_file_names.include?(SchedulesFile::ColumnLightingExterior))
    assert_in_epsilon(2763, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameExteriorLighting + ' schedule'), 0.1)
    assert(!schedule_file_names.include?(SchedulesFile::ColumnLightingGarage))
    assert(!schedule_file_names.include?(SchedulesFile::ColumnLightingExteriorHoliday))
    assert(!schedule_file_names.include?(SchedulesFile::ColumnRefrigerator))
    assert_in_epsilon(6673, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameRefrigerator), 0.1)
    assert(schedule_file_names.include?(SchedulesFile::ColumnCookingRange))
    assert(schedule_file_names.include?(SchedulesFile::ColumnDishwasher))
    assert(schedule_file_names.include?(SchedulesFile::ColumnClothesWasher))
    assert(schedule_file_names.include?(SchedulesFile::ColumnClothesDryer))
    assert(!schedule_file_names.include?(SchedulesFile::ColumnCeilingFan))
    assert(schedule_file_names.include?(SchedulesFile::ColumnPlugLoadsOther))
    assert(schedule_file_names.include?(SchedulesFile::ColumnPlugLoadsTV))
    assert(schedule_file_names.include?(SchedulesFile::ColumnHotWaterClothesWasher))
    assert(schedule_file_names.include?(SchedulesFile::ColumnHotWaterDishwasher))
    assert(schedule_file_names.include?(SchedulesFile::ColumnHotWaterFixtures))
  end

  def test_stochastic_vacancy_schedules
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-schedules-detailed-occupancy-stochastic-vacancy.xml'))
    model, hpxml = _test_measure(args_hash)

    schedules_paths = hpxml.header.schedules_filepaths.collect { |sfp|
      FilePath.check_path(sfp,
                          File.dirname(args_hash['hpxml_path']),
                          'Schedules')
    }

    column_name = hpxml.header.unavailable_periods[0].column_name

    sf = SchedulesFile.new(model: model,
                           schedules_paths: schedules_paths,
                           year: 2007,
                           unavailable_periods: hpxml.header.unavailable_periods,
                           output_path: @tmp_schedule_file_path)

    vacancy_hrs = 31.0 * 2.0 * 24.0
    occupied_ratio = (1.0 - vacancy_hrs / 8760.0)

    assert_in_epsilon(6689 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnOccupants, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2086 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnLightingInterior, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2086 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnLightingGarage, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2763 * occupied_ratio, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameExteriorLighting + ' schedule'), 0.1)
    assert_in_epsilon(6673, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameRefrigerator), 0.1)
    assert_in_epsilon(534 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnCookingRange, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(213 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnDishwasher, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(134 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnClothesWasher, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(151 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnClothesDryer, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(3250 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnCeilingFan, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(4840 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnPlugLoadsOther, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(4840 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnPlugLoadsTV, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(298 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnHotWaterDishwasher, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(325 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnHotWaterClothesWasher, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(887 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnHotWaterFixtures, schedules: sf.tmp_schedules), 0.1)
    assert(!sf.schedules.keys.include?(SchedulesFile::ColumnSleeping))
    assert_in_epsilon(vacancy_hrs, sf.annual_equivalent_full_load_hrs(col_name: column_name, schedules: sf.tmp_schedules), 0.1)
  end

  def test_stochastic_vacancy_schedules2
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-schedules-detailed-occupancy-stochastic-vacancy.xml'))
    model, hpxml = _test_measure(args_hash)

    column_name = hpxml.header.unavailable_periods[0].column_name

    # intentionally overlaps the first vacancy period
    hpxml.header.unavailable_periods.add(column_name: column_name,
                                         begin_month: 1,
                                         begin_day: 25,
                                         end_month: 2,
                                         end_day: 28,
                                         natvent_availability: HPXML::ScheduleUnavailable)

    schedules_paths = hpxml.header.schedules_filepaths.collect { |sfp|
      FilePath.check_path(sfp,
                          File.dirname(args_hash['hpxml_path']),
                          'Schedules')
    }

    sf = SchedulesFile.new(model: model,
                           schedules_paths: schedules_paths,
                           year: 2007,
                           unavailable_periods: hpxml.header.unavailable_periods,
                           output_path: @tmp_schedule_file_path)

    vacancy_hrs = ((31.0 * 2.0) + (28.0 * 1.0)) * 24.0
    occupied_ratio = (1.0 - vacancy_hrs / 8760.0)

    assert_in_epsilon(6689 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnOccupants, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2086 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnLightingInterior, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2086 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnLightingGarage, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2763 * occupied_ratio, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameExteriorLighting + ' schedule'), 0.1)
    assert_in_epsilon(6673, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameRefrigerator), 0.1)
    assert_in_epsilon(534 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnCookingRange, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(213 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnDishwasher, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(134 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnClothesWasher, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(151 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnClothesDryer, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(3250 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnCeilingFan, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(4840 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnPlugLoadsOther, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(4840 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnPlugLoadsTV, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(298 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnHotWaterDishwasher, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(325 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnHotWaterClothesWasher, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(887 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnHotWaterFixtures, schedules: sf.tmp_schedules), 0.1)
    assert(!sf.schedules.keys.include?(SchedulesFile::ColumnSleeping))
    assert_in_epsilon(vacancy_hrs, sf.annual_equivalent_full_load_hrs(col_name: column_name, schedules: sf.tmp_schedules), 0.1)
  end

  def test_stochastic_vacancy_year_round_schedules
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-schedules-detailed-occupancy-stochastic-vacancy-year-round.xml'))
    model, hpxml = _test_measure(args_hash)

    schedules_paths = hpxml.header.schedules_filepaths.collect { |sfp|
      FilePath.check_path(sfp,
                          File.dirname(args_hash['hpxml_path']),
                          'Schedules')
    }

    column_name = hpxml.header.unavailable_periods[0].column_name

    sf = SchedulesFile.new(model: model,
                           schedules_paths: schedules_paths,
                           year: 2007,
                           unavailable_periods: hpxml.header.unavailable_periods,
                           output_path: @tmp_schedule_file_path)

    vacancy_hrs = 8760.0
    occupied_ratio = (1.0 - vacancy_hrs / 8760.0)

    assert_in_epsilon(6689 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnOccupants, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2086 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnLightingInterior, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2086 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnLightingGarage, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2763 * occupied_ratio, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameExteriorLighting + ' schedule'), 0.1)
    assert_in_epsilon(6673, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameRefrigerator), 0.1)
    assert_in_epsilon(534 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnCookingRange, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(213 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnDishwasher, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(134 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnClothesWasher, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(151 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnClothesDryer, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(3250 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnCeilingFan, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(4840 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnPlugLoadsOther, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(4840 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnPlugLoadsTV, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(298 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnHotWaterDishwasher, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(325 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnHotWaterClothesWasher, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(887 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnHotWaterFixtures, schedules: sf.tmp_schedules), 0.1)
    assert(!sf.schedules.keys.include?(SchedulesFile::ColumnSleeping))
    assert_in_epsilon(vacancy_hrs, sf.annual_equivalent_full_load_hrs(col_name: column_name, schedules: sf.tmp_schedules), 0.1)
  end

  def test_stochastic_power_outage_schedules
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-schedules-detailed-occupancy-stochastic-power-outage.xml'))
    model, hpxml = _test_measure(args_hash)

    schedules_paths = hpxml.header.schedules_filepaths.collect { |sfp|
      FilePath.check_path(sfp,
                          File.dirname(args_hash['hpxml_path']),
                          'Schedules')
    }

    column_name = hpxml.header.unavailable_periods[0].column_name

    sf = SchedulesFile.new(model: model,
                           schedules_paths: schedules_paths,
                           year: 2007,
                           unavailable_periods: hpxml.header.unavailable_periods,
                           output_path: @tmp_schedule_file_path)

    outage_hrs = 31.0 * 2.0 * 24.0 - 15.0
    powered_ratio = (1.0 - outage_hrs / 8760.0)

    assert_in_epsilon(6689, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnOccupants, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2086 * powered_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnLightingInterior, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2086 * powered_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnLightingGarage, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2763 * powered_ratio, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameExteriorLighting + ' schedule'), 0.1)
    assert_in_epsilon(6673 * powered_ratio, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameRefrigerator), 0.1)
    assert_in_epsilon(534 * powered_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnCookingRange, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(213 * powered_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnDishwasher, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(134 * powered_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnClothesWasher, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(151 * powered_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnClothesDryer, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(3250 * powered_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnCeilingFan, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(4840 * powered_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnPlugLoadsOther, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(4840 * powered_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnPlugLoadsTV, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(298 * powered_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnHotWaterDishwasher, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(325 * powered_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnHotWaterClothesWasher, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(887 * powered_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnHotWaterFixtures, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(8760 * powered_ratio, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameMechanicalVentilationHouseFan + ' schedule'), 0.1)
    assert(!sf.schedules.keys.include?(SchedulesFile::ColumnSleeping))
    assert_in_epsilon(outage_hrs, sf.annual_equivalent_full_load_hrs(col_name: column_name, schedules: sf.tmp_schedules), 0.1)
  end

  def test_stochastic_power_outage_schedules2
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-schedules-detailed-occupancy-stochastic-power-outage.xml'))
    model, hpxml = _test_measure(args_hash)

    column_name = hpxml.header.unavailable_periods[0].column_name

    # intentionally overlaps the first power outage period
    hpxml.header.unavailable_periods.add(column_name: column_name,
                                         begin_month: 1,
                                         begin_day: 25,
                                         begin_hour: 0,
                                         end_month: 2,
                                         end_day: 27,
                                         end_hour: 24)

    schedules_paths = hpxml.header.schedules_filepaths.collect { |sfp|
      FilePath.check_path(sfp,
                          File.dirname(args_hash['hpxml_path']),
                          'Schedules')
    }

    sf = SchedulesFile.new(model: model,
                           schedules_paths: schedules_paths,
                           year: 2007,
                           unavailable_periods: hpxml.header.unavailable_periods,
                           output_path: @tmp_schedule_file_path)

    outage_hrs = ((31.0 * 2.0) + (28.0 * 1.0)) * 24.0 - 5.0
    powered_ratio = (1.0 - outage_hrs / 8760.0)

    assert_in_epsilon(6689, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnOccupants, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2086 * powered_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnLightingInterior, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2086 * powered_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnLightingGarage, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2763 * powered_ratio, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameExteriorLighting + ' schedule'), 0.1)
    assert_in_epsilon(5743, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameRefrigerator), 0.1) # this reflects only the first outage period because we aren't applying the measure again
    assert_in_epsilon(534 * powered_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnCookingRange, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(213 * powered_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnDishwasher, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(134 * powered_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnClothesWasher, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(151 * powered_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnClothesDryer, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(3250 * powered_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnCeilingFan, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(4840 * powered_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnPlugLoadsOther, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(4840 * powered_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnPlugLoadsTV, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(298 * powered_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnHotWaterDishwasher, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(325 * powered_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnHotWaterClothesWasher, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(887 * powered_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnHotWaterFixtures, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(7286, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameMechanicalVentilationHouseFan + ' schedule'), 0.1) # this reflects only the first outage period because we aren't applying the measure again
    assert(!sf.schedules.keys.include?(SchedulesFile::ColumnSleeping))
    assert_in_epsilon(outage_hrs, sf.annual_equivalent_full_load_hrs(col_name: column_name, schedules: sf.tmp_schedules), 0.1)
  end

  def test_set_unavailable_periods_refrigerator
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base.xml'))

    begin_month = 1
    begin_day = 1
    begin_hour = 0
    end_month = 12
    end_day = 31
    end_hour = 24

    sch_name = Constants.ObjectNameRefrigerator

    # hours not specified
    model, hpxml = _test_measure(args_hash)
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

    model, hpxml = _test_measure(args_hash)
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

    model, hpxml = _test_measure(args_hash)
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

    model, hpxml = _test_measure(args_hash)
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

    model, hpxml = _test_measure(args_hash)
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

    model, hpxml = _test_measure(args_hash)
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

    model, hpxml = _test_measure(args_hash)
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

    model, hpxml = _test_measure(args_hash)
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

    sch_name = Constants.ObjectNameRefrigerator

    model, hpxml = _test_measure(args_hash)
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

    return model, hpxml
  end
end
