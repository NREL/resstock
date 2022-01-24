# frozen_string_literal: true

require_relative '../../HPXMLtoOpenStudio/resources/minitest_helper'
require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'fileutils'
# require 'csv'
require_relative '../measure.rb'

class BuildResidentialScheduleFileTest < Minitest::Test
  def setup
    @root_path = File.absolute_path(File.join(File.dirname(__FILE__), '..', '..'))
    @sample_files_path = File.join(@root_path, 'workflow', 'sample_files')
    @tmp_hpxml_path = File.join(@sample_files_path, 'tmp.xml')
    @tmp_output_path = File.join(@sample_files_path, 'tmp_output')
    FileUtils.mkdir_p(@tmp_output_path)

    @args_hash = {}
    @args_hash['hpxml_path'] = File.absolute_path(@tmp_hpxml_path)
    @args_hash['hpxml_output_path'] = @args_hash['hpxml_path']
  end

  def teardown
    File.delete(@tmp_hpxml_path) if File.exist? @tmp_hpxml_path
    FileUtils.rm_rf(@tmp_output_path)
  end

  def test_smooth
    hpxml = _create_hpxml('base.xml')
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)

    @args_hash['output_csv_path'] = File.absolute_path(File.join(@tmp_output_path, 'smooth.csv'))
    model, hpxml, result = _test_measure()

    info_msgs = result.info.map { |x| x.logMessage }
    warn_msgs = result.warnings.map { |x| x.logMessage }
    assert(info_msgs.any? { |info_msg| info_msg.include?('smooth schedule') })
    assert(info_msgs.any? { |info_msg| info_msg.include?('SimYear=2007') })
    assert(info_msgs.any? { |info_msg| info_msg.include?('MinutesPerStep=60') })
    assert(info_msgs.any? { |info_msg| info_msg.include?('State=CO') })
    assert(!info_msgs.any? { |info_msg| info_msg.include?('RandomSeed') })
    assert(info_msgs.any? { |info_msg| info_msg.include?('GeometryNumOccupants=3.0') })
    assert(!info_msgs.any? { |info_msg| info_msg.include?('VacancyPeriod') })

    sf = SchedulesFile.new(model: model, schedules_paths: hpxml.header.schedules_filepaths, col_names: SchedulesFile.ColumnNames)
    sf.validate_schedules(year: 2007)

    assert_in_epsilon(6020, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnOccupants, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(3321, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnLightingInterior, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2763, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnLightingExterior, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2763, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnLightingGarage, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(150, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnLightingExteriorHoliday, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2224, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnCookingRange, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(6673, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnRefrigerator, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(6673, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnExtraRefrigerator, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(6673, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnFreezer, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2994, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnDishwasher, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(4158, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnClothesWasher, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(4503, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnClothesDryer, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(6020, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnCeilingFan, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(5468, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnPlugLoadsOther, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2288, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnPlugLoadsTV, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(8760, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnPlugLoadsVehicle, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(3671, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnPlugLoadsWellPump, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2074, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnFuelLoadsGrill, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(3671, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnFuelLoadsLighting, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(3671, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnFuelLoadsFireplace, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2471, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnPoolPump, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2471, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnPoolHeater, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2502, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnHotTubPump, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2650, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnHotTubHeater, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2994, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnHotWaterDishwasher, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(4158, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnHotWaterClothesWasher, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(4204, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnHotWaterFixtures, schedules: sf.tmp_schedules), 0.1)
    assert(!sf.schedules.keys.include?(SchedulesFile::ColumnVacancy))
  end

  def test_smooth_vacancy
    hpxml = _create_hpxml('base.xml')
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)

    @args_hash['schedules_vacancy_period'] = 'Dec 1 - Jan 31'
    @args_hash['output_csv_path'] = File.absolute_path(File.join(@tmp_output_path, 'smooth-vacancy.csv'))
    model, hpxml, result = _test_measure()

    info_msgs = result.info.map { |x| x.logMessage }
    warn_msgs = result.warnings.map { |x| x.logMessage }
    assert(info_msgs.any? { |info_msg| info_msg.include?('smooth schedule') })
    assert(info_msgs.any? { |info_msg| info_msg.include?('SimYear=2007') })
    assert(info_msgs.any? { |info_msg| info_msg.include?('MinutesPerStep=60') })
    assert(info_msgs.any? { |info_msg| info_msg.include?('State=CO') })
    assert(!info_msgs.any? { |info_msg| info_msg.include?('RandomSeed') })
    assert(info_msgs.any? { |info_msg| info_msg.include?('GeometryNumOccupants=3.0') })
    assert(info_msgs.any? { |info_msg| info_msg.include?('VacancyPeriod=Dec 1 - Jan 31') })

    sf = SchedulesFile.new(model: model, schedules_paths: hpxml.header.schedules_filepaths, col_names: SchedulesFile.ColumnNames)
    sf.validate_schedules(year: 2007)

    vacancy_hrs = 31.0 * 2.0 * 24.0
    occupied_ratio = (1.0 - vacancy_hrs / 8760.0)

    assert_in_epsilon(6020 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnOccupants, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(3321 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnLightingInterior, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2763 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnLightingExterior, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2763 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnLightingGarage, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(19, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnLightingExteriorHoliday, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2224 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnCookingRange, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(6673, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnRefrigerator, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(6673, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnExtraRefrigerator, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(6673, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnFreezer, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2994 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnDishwasher, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(4158 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnClothesWasher, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(4503 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnClothesDryer, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(6020 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnCeilingFan, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(5468 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnPlugLoadsOther, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2288 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnPlugLoadsTV, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(8760 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnPlugLoadsVehicle, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(3671 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnPlugLoadsWellPump, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2074 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnFuelLoadsGrill, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(3671 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnFuelLoadsLighting, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(3671 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnFuelLoadsFireplace, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2471, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnPoolPump, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2471, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnPoolHeater, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2502, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnHotTubPump, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2650, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnHotTubHeater, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2994 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnHotWaterDishwasher, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(4158 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnHotWaterClothesWasher, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(4204 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnHotWaterFixtures, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(vacancy_hrs, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnVacancy, schedules: sf.tmp_schedules), 0.1)
  end

  def test_stochastic
    hpxml = _create_hpxml('base.xml')
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)

    @args_hash['schedules_type'] = 'stochastic'
    @args_hash['output_csv_path'] = File.absolute_path(File.join(@tmp_output_path, 'stochastic.csv'))
    model, hpxml, result = _test_measure()

    info_msgs = result.info.map { |x| x.logMessage }
    warn_msgs = result.warnings.map { |x| x.logMessage }
    assert(info_msgs.any? { |info_msg| info_msg.include?('stochastic schedule') })
    assert(info_msgs.any? { |info_msg| info_msg.include?('SimYear=2007') })
    assert(info_msgs.any? { |info_msg| info_msg.include?('MinutesPerStep=60') })
    assert(info_msgs.any? { |info_msg| info_msg.include?('State=CO') })
    assert(!info_msgs.any? { |info_msg| info_msg.include?('RandomSeed') })
    assert(info_msgs.any? { |info_msg| info_msg.include?('GeometryNumOccupants=3.0') })
    assert(!info_msgs.any? { |info_msg| info_msg.include?('VacancyPeriod') })

    sf = SchedulesFile.new(model: model, schedules_paths: hpxml.header.schedules_filepaths, col_names: SchedulesFile.ColumnNames)
    sf.validate_schedules(year: 2007)

    assert_in_epsilon(6689, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnOccupants, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2086, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnLightingInterior, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(4090, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnLightingExterior, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(4090, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnLightingGarage, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(150, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnLightingExteriorHoliday, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(534, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnCookingRange, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(6673, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnRefrigerator, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(6673, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnExtraRefrigerator, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(6673, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnFreezer, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(213, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnDishwasher, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(134, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnClothesWasher, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(151, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnClothesDryer, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(3250, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnCeilingFan, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(4840, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnPlugLoadsOther, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2288, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnPlugLoadsTV, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(8760, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnPlugLoadsVehicle, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(3671, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnPlugLoadsWellPump, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2074, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnFuelLoadsGrill, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(3671, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnFuelLoadsLighting, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(3671, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnFuelLoadsFireplace, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2471, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnPoolPump, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2471, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnPoolHeater, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2502, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnHotTubPump, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2650, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnHotTubHeater, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(298, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnHotWaterDishwasher, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(325, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnHotWaterClothesWasher, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(887, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnHotWaterFixtures, schedules: sf.tmp_schedules), 0.1)
    assert(!sf.schedules.keys.include?(SchedulesFile::ColumnVacancy))
  end

  def test_stochastic_vacancy
    hpxml = _create_hpxml('base.xml')
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)

    @args_hash['schedules_type'] = 'stochastic'
    @args_hash['schedules_vacancy_period'] = 'Dec 1 - Jan 31'
    @args_hash['output_csv_path'] = File.absolute_path(File.join(@tmp_output_path, 'stochastic-vacancy.csv'))
    model, hpxml, result = _test_measure()

    info_msgs = result.info.map { |x| x.logMessage }
    warn_msgs = result.warnings.map { |x| x.logMessage }
    assert(info_msgs.any? { |info_msg| info_msg.include?('stochastic schedule') })
    assert(info_msgs.any? { |info_msg| info_msg.include?('SimYear=2007') })
    assert(info_msgs.any? { |info_msg| info_msg.include?('MinutesPerStep=60') })
    assert(info_msgs.any? { |info_msg| info_msg.include?('State=CO') })
    assert(!info_msgs.any? { |info_msg| info_msg.include?('RandomSeed') })
    assert(info_msgs.any? { |info_msg| info_msg.include?('GeometryNumOccupants=3.0') })
    assert(info_msgs.any? { |info_msg| info_msg.include?('VacancyPeriod=Dec 1 - Jan 31') })

    sf = SchedulesFile.new(model: model, schedules_paths: hpxml.header.schedules_filepaths, col_names: SchedulesFile.ColumnNames)
    sf.validate_schedules(year: 2007)

    vacancy_hrs = 31.0 * 2.0 * 24.0
    occupied_ratio = (1.0 - vacancy_hrs / 8760.0)

    assert_in_epsilon(6689 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnOccupants, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2086 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnLightingInterior, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(4090 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnLightingExterior, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(4090 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnLightingGarage, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(11, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnLightingExteriorHoliday, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(534 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnCookingRange, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(6673, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnRefrigerator, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(6673, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnExtraRefrigerator, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(6673, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnFreezer, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(213 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnDishwasher, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(134 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnClothesWasher, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(151 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnClothesDryer, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(3250 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnCeilingFan, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(4840 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnPlugLoadsOther, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2288 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnPlugLoadsTV, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(8760 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnPlugLoadsVehicle, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(3671 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnPlugLoadsWellPump, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2074 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnFuelLoadsGrill, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(3671 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnFuelLoadsLighting, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(3671 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnFuelLoadsFireplace, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2471, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnPoolPump, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2471, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnPoolHeater, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2502, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnHotTubPump, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2650, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnHotTubHeater, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(298 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnHotWaterDishwasher, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(325 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnHotWaterClothesWasher, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(887 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnHotWaterFixtures, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(vacancy_hrs, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnVacancy, schedules: sf.tmp_schedules), 0.1)
  end

  def test_random_seed
    hpxml = _create_hpxml('base-location-baltimore-md.xml')
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)

    @args_hash['schedules_type'] = 'stochastic'
    @args_hash['schedules_random_seed'] = 1
    @args_hash['output_csv_path'] = File.absolute_path(File.join(@tmp_output_path, 'stochastic.csv'))
    model, hpxml, result = _test_measure()

    info_msgs = result.info.map { |x| x.logMessage }
    warn_msgs = result.warnings.map { |x| x.logMessage }
    assert(info_msgs.any? { |info_msg| info_msg.include?('stochastic schedule') })
    assert(info_msgs.any? { |info_msg| info_msg.include?('SimYear=2007') })
    assert(info_msgs.any? { |info_msg| info_msg.include?('MinutesPerStep=60') })
    assert(info_msgs.any? { |info_msg| info_msg.include?('State=MD') })
    assert(info_msgs.any? { |info_msg| info_msg.include?('RandomSeed=1') })
    assert(info_msgs.any? { |info_msg| info_msg.include?('GeometryNumOccupants=3.0') })
    assert(!info_msgs.any? { |info_msg| info_msg.include?('VacancyPeriod') })

    sf = SchedulesFile.new(model: model, schedules_paths: hpxml.header.schedules_filepaths, col_names: SchedulesFile.ColumnNames)
    sf.validate_schedules(year: 2007)

    assert_in_epsilon(6689, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnOccupants, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2086, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnLightingInterior, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(4090, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnLightingExterior, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(4090, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnLightingGarage, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(150, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnLightingExteriorHoliday, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(534, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnCookingRange, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(6673, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnRefrigerator, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(6673, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnExtraRefrigerator, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(6673, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnFreezer, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(213, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnDishwasher, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(134, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnClothesWasher, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(151, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnClothesDryer, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(3250, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnCeilingFan, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(4840, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnPlugLoadsOther, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2288, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnPlugLoadsTV, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(8760, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnPlugLoadsVehicle, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(3671, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnPlugLoadsWellPump, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2074, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnFuelLoadsGrill, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(3671, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnFuelLoadsLighting, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(3671, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnFuelLoadsFireplace, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2471, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnPoolPump, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2471, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnPoolHeater, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2502, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnHotTubPump, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2650, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnHotTubHeater, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(298, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnHotWaterDishwasher, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(325, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnHotWaterClothesWasher, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(898, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnHotWaterFixtures, schedules: sf.tmp_schedules), 0.1)
    assert(!sf.schedules.keys.include?(SchedulesFile::ColumnVacancy))

    @args_hash['schedules_random_seed'] = 2
    model, hpxml, result = _test_measure()

    info_msgs = result.info.map { |x| x.logMessage }
    warn_msgs = result.warnings.map { |x| x.logMessage }
    assert(info_msgs.any? { |info_msg| info_msg.include?('stochastic schedule') })
    assert(info_msgs.any? { |info_msg| info_msg.include?('SimYear=2007') })
    assert(info_msgs.any? { |info_msg| info_msg.include?('MinutesPerStep=60') })
    assert(info_msgs.any? { |info_msg| info_msg.include?('State=MD') })
    assert(info_msgs.any? { |info_msg| info_msg.include?('RandomSeed=2') })
    assert(info_msgs.any? { |info_msg| info_msg.include?('GeometryNumOccupants=3.0') })
    assert(!info_msgs.any? { |info_msg| info_msg.include?('VacancyPeriod') })

    sf = SchedulesFile.new(model: model, schedules_paths: hpxml.header.schedules_filepaths, col_names: SchedulesFile.ColumnNames)
    sf.validate_schedules(year: 2007)

    assert_in_epsilon(6072, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnOccupants, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(1765, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnLightingInterior, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(4090, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnLightingExterior, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(4090, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnLightingGarage, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(150, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnLightingExteriorHoliday, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(356, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnCookingRange, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(6673, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnRefrigerator, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(6673, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnExtraRefrigerator, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(6673, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnFreezer, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(165, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnDishwasher, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(101, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnClothesWasher, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(166, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnClothesDryer, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(3250, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnCeilingFan, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(4840, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnPlugLoadsOther, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2288, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnPlugLoadsTV, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(8760, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnPlugLoadsVehicle, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(3671, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnPlugLoadsWellPump, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2074, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnFuelLoadsGrill, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(3671, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnFuelLoadsLighting, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(3671, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnFuelLoadsFireplace, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2471, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnPoolPump, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2471, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnPoolHeater, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2502, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnHotTubPump, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2650, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnHotTubHeater, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(226, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnHotWaterDishwasher, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(244, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnHotWaterClothesWasher, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(1077, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnHotWaterFixtures, schedules: sf.tmp_schedules), 0.1)
    assert(!sf.schedules.keys.include?(SchedulesFile::ColumnVacancy))
  end

  def test_AMY_2012_vacancy
    hpxml = _create_hpxml('base-location-AMY-2012.xml')
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)

    @args_hash['schedules_vacancy_period'] = 'Jan 1 - Dec 31'
    @args_hash['output_csv_path'] = File.absolute_path(File.join(@tmp_output_path, 'smooth.csv'))
    model, hpxml, result = _test_measure()

    info_msgs = result.info.map { |x| x.logMessage }
    warn_msgs = result.warnings.map { |x| x.logMessage }
    assert(info_msgs.any? { |info_msg| info_msg.include?('smooth schedule') })
    assert(info_msgs.any? { |info_msg| info_msg.include?('SimYear=2012') })
    assert(info_msgs.any? { |info_msg| info_msg.include?('MinutesPerStep=60') })
    assert(info_msgs.any? { |info_msg| info_msg.include?('State=CO') })
    assert(!info_msgs.any? { |info_msg| info_msg.include?('RandomSeed') })
    assert(info_msgs.any? { |info_msg| info_msg.include?('GeometryNumOccupants=3.0') })
    assert(info_msgs.any? { |info_msg| info_msg.include?('VacancyPeriod=Jan 1 - Dec 31') })

    sf = SchedulesFile.new(model: model, schedules_paths: hpxml.header.schedules_filepaths, col_names: SchedulesFile.ColumnNames)
    sf.validate_schedules(year: 2012)

    vacancy_hrs = 366.0 * 24.0

    assert_in_epsilon(0, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnOccupants, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(0, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnLightingInterior, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(0, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnLightingExterior, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(0, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnLightingGarage, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(0, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnLightingExteriorHoliday, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(0, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnCookingRange, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(6688, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnRefrigerator, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(6688, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnExtraRefrigerator, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(6688, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnFreezer, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(0, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnDishwasher, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(0, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnClothesWasher, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(0, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnClothesDryer, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(0, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnCeilingFan, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(0, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnPlugLoadsOther, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(0, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnPlugLoadsTV, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(0, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnPlugLoadsVehicle, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(0, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnPlugLoadsWellPump, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(0, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnFuelLoadsGrill, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(0, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnFuelLoadsLighting, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(0, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnFuelLoadsFireplace, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2479, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnPoolPump, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2479, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnPoolHeater, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2508, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnHotTubPump, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2656, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnHotTubHeater, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(0, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnHotWaterDishwasher, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(0, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnHotWaterClothesWasher, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(0, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnHotWaterFixtures, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(vacancy_hrs, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnVacancy, schedules: sf.tmp_schedules), 0.1)
  end

  def test_10_min_timestep_vacancy
    hpxml = _create_hpxml('base-simcontrol-timestep-10-mins.xml')
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)

    @args_hash['output_csv_path'] = File.absolute_path(File.join(@tmp_output_path, 'smooth.csv'))
    model, hpxml, result = _test_measure()

    info_msgs = result.info.map { |x| x.logMessage }
    warn_msgs = result.warnings.map { |x| x.logMessage }
    assert(info_msgs.any? { |info_msg| info_msg.include?('smooth schedule') })
    assert(info_msgs.any? { |info_msg| info_msg.include?('SimYear=2007') })
    assert(info_msgs.any? { |info_msg| info_msg.include?('MinutesPerStep=10') })
    assert(info_msgs.any? { |info_msg| info_msg.include?('State=CO') })
    assert(!info_msgs.any? { |info_msg| info_msg.include?('RandomSeed') })
    assert(info_msgs.any? { |info_msg| info_msg.include?('GeometryNumOccupants=3.0') })
    assert(!info_msgs.any? { |info_msg| info_msg.include?('VacancyPeriod') })

    sf = SchedulesFile.new(model: model, schedules_paths: hpxml.header.schedules_filepaths, col_names: SchedulesFile.ColumnNames)
    sf.validate_schedules(year: 2007)

    assert_in_epsilon(6020, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnOccupants, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(3321, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnLightingInterior, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2763, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnLightingExterior, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2763, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnLightingGarage, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(150, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnLightingExteriorHoliday, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2224, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnCookingRange, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(6673, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnRefrigerator, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(6673, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnExtraRefrigerator, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(6673, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnFreezer, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2994, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnDishwasher, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(4158, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnClothesWasher, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(4503, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnClothesDryer, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(6020, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnCeilingFan, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(5468, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnPlugLoadsOther, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2288, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnPlugLoadsTV, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(8760, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnPlugLoadsVehicle, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(3671, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnPlugLoadsWellPump, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2074, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnFuelLoadsGrill, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(3671, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnFuelLoadsLighting, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(3671, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnFuelLoadsFireplace, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2471, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnPoolPump, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2471, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnPoolHeater, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2502, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnHotTubPump, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2650, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnHotTubHeater, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2994, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnHotWaterDishwasher, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(4158, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnHotWaterClothesWasher, schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(4204, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::ColumnHotWaterFixtures, schedules: sf.tmp_schedules), 0.1)
    assert(!sf.schedules.keys.include?(SchedulesFile::ColumnVacancy))
  end

  def _test_measure()
    # create an instance of the measure
    measure = BuildResidentialScheduleFile.new

    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    model = OpenStudio::Model::Model.new

    # get arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if @args_hash.has_key?(arg.name)
        assert(temp_arg_var.setValue(@args_hash[arg.name]))
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

    hpxml = HPXML.new(hpxml_path: @tmp_hpxml_path)

    return model, hpxml, result
  end

  def _create_hpxml(hpxml_name)
    return HPXML.new(hpxml_path: File.join(@sample_files_path, hpxml_name))
  end
end
