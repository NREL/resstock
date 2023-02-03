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
  end

  def teardown
    File.delete(@tmp_hpxml_path) if File.exist? @tmp_hpxml_path
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

    schedule_constants = 9
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

  def test_default_vacancy_schedules
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-vacancy.xml'))
    model, _hpxml = _test_measure(args_hash)

    vacancy_hrs = 31.0 * 2.0 * 24.0
    occupied_ratio = (1.0 - vacancy_hrs / 8760.0)

    assert_in_epsilon(6020 * occupied_ratio, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameOccupants + ' schedule'), 0.1)
    assert_in_epsilon(3321 * occupied_ratio, get_annual_equivalent_full_load_hrs(model, 'lighting schedule'), 0.1)
    assert_in_epsilon(2763 * occupied_ratio, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameExteriorLighting + ' schedule'), 0.1)
    assert_in_epsilon(6673, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameRefrigerator), 0.1)
    assert_in_epsilon(2224 * occupied_ratio, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameCookingRange), 0.1)
    assert_in_epsilon(2994 * occupied_ratio, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameDishwasher), 0.1)
    assert_in_epsilon(4158 * occupied_ratio, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameClothesWasher), 0.1)
    assert_in_epsilon(4502 * occupied_ratio, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameClothesDryer), 0.1)
    assert_in_epsilon(5468 * occupied_ratio, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameMiscPlugLoads + ' schedule'), 0.1)
    assert_in_epsilon(2256 * occupied_ratio, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameMiscTelevision + ' schedule'), 0.1)
    assert_in_epsilon(4204 * occupied_ratio, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameFixtures), 0.1)
  end

  def test_simple_schedules
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-schedules-simple.xml'))
    model, _hpxml = _test_measure(args_hash)

    schedule_constants = 9
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
    assert(schedule_file_names.include?(SchedulesFile::ColumnLightingExterior))
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
    assert(!schedule_file_names.include?(SchedulesFile::ColumnPlugLoadsTV))
    assert_in_epsilon(2256, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameMiscTelevision + ' schedule'), 0.1)
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

    sf = SchedulesFile.new(model: model,
                           schedules_paths: schedules_paths,
                           year: 2007,
                           vacancy_periods: hpxml.header.vacancy_periods)

    vacancy_hrs = 31.0 * 2.0 * 24.0
    occupied_ratio = (1.0 - vacancy_hrs / 8760.0)

    assert_in_epsilon(6689 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnOccupants, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2086 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnLightingInterior, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(4090 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnLightingExterior, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(4090 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnLightingGarage, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(11, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnLightingExteriorHoliday, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(6673, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameRefrigerator), 0.1)
    assert_in_epsilon(534 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnCookingRange, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(213 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnDishwasher, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(134 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnClothesWasher, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(151 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnClothesDryer, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(3250 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnCeilingFan, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(4840 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnPlugLoadsOther, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2256 * occupied_ratio, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameMiscTelevision + ' schedule'), 0.1)
    assert_in_epsilon(298 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnHotWaterDishwasher, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(325 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnHotWaterClothesWasher, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(887 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnHotWaterFixtures, schedules: sf.tmp_schedules), 0.1)
    assert(!sf.schedules.keys.include?(SchedulesFile::ColumnSleeping))
    assert_in_epsilon(vacancy_hrs, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnVacancy, schedules: sf.tmp_schedules), 0.1)
  end

  def test_stochastic_vacancy_schedules2
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-schedules-detailed-occupancy-stochastic-vacancy.xml'))
    model, hpxml = _test_measure(args_hash)

    # intentionally overlaps the first vacancy period
    hpxml.header.vacancy_periods.add(begin_month: 1,
                                     begin_day: 25,
                                     end_month: 2,
                                     end_day: 28)

    schedules_paths = hpxml.header.schedules_filepaths.collect { |sfp|
      FilePath.check_path(sfp,
                          File.dirname(args_hash['hpxml_path']),
                          'Schedules')
    }

    sf = SchedulesFile.new(model: model,
                           schedules_paths: schedules_paths,
                           year: 2007,
                           vacancy_periods: hpxml.header.vacancy_periods)

    vacancy_hrs = ((31.0 * 2.0) + (28.0 * 1.0)) * 24.0
    occupied_ratio = (1.0 - vacancy_hrs / 8760.0)

    assert_in_epsilon(6689 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnOccupants, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2086 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnLightingInterior, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(4090 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnLightingExterior, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(4090 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnLightingGarage, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(11, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnLightingExteriorHoliday, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(6673, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameRefrigerator), 0.1)
    assert_in_epsilon(534 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnCookingRange, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(213 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnDishwasher, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(134 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnClothesWasher, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(151 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnClothesDryer, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(3250 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnCeilingFan, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(4840 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnPlugLoadsOther, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2256 * occupied_ratio, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameMiscTelevision + ' schedule'), 0.1)
    assert_in_epsilon(298 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnHotWaterDishwasher, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(325 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnHotWaterClothesWasher, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(887 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnHotWaterFixtures, schedules: sf.tmp_schedules), 0.1)
    assert(!sf.schedules.keys.include?(SchedulesFile::ColumnSleeping))
    assert_in_epsilon(vacancy_hrs, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnVacancy, schedules: sf.tmp_schedules), 0.1)
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

    sf = SchedulesFile.new(model: model,
                           schedules_paths: schedules_paths,
                           year: 2007,
                           vacancy_periods: hpxml.header.vacancy_periods)

    vacancy_hrs = 8760.0
    occupied_ratio = (1.0 - vacancy_hrs / 8760.0)

    assert_in_epsilon(6689 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnOccupants, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2086 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnLightingInterior, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(4090 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnLightingExterior, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(4090 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnLightingGarage, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(11 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnLightingExteriorHoliday, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(6673, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameRefrigerator), 0.1)
    assert_in_epsilon(534 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnCookingRange, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(213 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnDishwasher, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(134 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnClothesWasher, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(151 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnClothesDryer, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(3250 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnCeilingFan, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(4840 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnPlugLoadsOther, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2256 * occupied_ratio, get_annual_equivalent_full_load_hrs(model, Constants.ObjectNameMiscTelevision + ' schedule'), 0.1)
    assert_in_epsilon(298 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnHotWaterDishwasher, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(325 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnHotWaterClothesWasher, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(887 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnHotWaterFixtures, schedules: sf.tmp_schedules), 0.1)
    assert(!sf.schedules.keys.include?(SchedulesFile::ColumnSleeping))
    assert_in_epsilon(vacancy_hrs, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnVacancy, schedules: sf.tmp_schedules), 0.1)
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
