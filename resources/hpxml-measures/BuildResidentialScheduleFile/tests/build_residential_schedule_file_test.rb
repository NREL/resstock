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
  end

  def teardown
    File.delete(@tmp_hpxml_path) if File.exist? @tmp_hpxml_path
    FileUtils.rm_rf(@tmp_output_path)
  end

  def test_smooth
    hpxml = _create_hpxml('base.xml')
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)

    @args_hash['output_csv_path'] = File.absolute_path(File.join(@tmp_output_path, 'smooth.csv'))
    model, hpxml = _test_measure()

    sf = SchedulesFile.new(model: model, schedules_path: @args_hash['output_csv_path'], col_names: Constants.ScheduleColNames.keys)

    assert_in_epsilon(6020, sf.annual_equivalent_full_load_hrs(col_name: 'occupants', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(3321, sf.annual_equivalent_full_load_hrs(col_name: 'lighting_interior', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2763, sf.annual_equivalent_full_load_hrs(col_name: 'lighting_exterior', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2763, sf.annual_equivalent_full_load_hrs(col_name: 'lighting_garage', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(150, sf.annual_equivalent_full_load_hrs(col_name: 'lighting_exterior_holiday', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2224, sf.annual_equivalent_full_load_hrs(col_name: 'cooking_range', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(6673, sf.annual_equivalent_full_load_hrs(col_name: 'refrigerator', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(6673, sf.annual_equivalent_full_load_hrs(col_name: 'extra_refrigerator', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(6673, sf.annual_equivalent_full_load_hrs(col_name: 'freezer', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2994, sf.annual_equivalent_full_load_hrs(col_name: 'dishwasher', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(4158, sf.annual_equivalent_full_load_hrs(col_name: 'clothes_washer', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(4503, sf.annual_equivalent_full_load_hrs(col_name: 'clothes_dryer', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(6020, sf.annual_equivalent_full_load_hrs(col_name: 'ceiling_fan', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(5468, sf.annual_equivalent_full_load_hrs(col_name: 'plug_loads_other', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2288, sf.annual_equivalent_full_load_hrs(col_name: 'plug_loads_tv', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(8760, sf.annual_equivalent_full_load_hrs(col_name: 'plug_loads_vehicle', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(3671, sf.annual_equivalent_full_load_hrs(col_name: 'plug_loads_well_pump', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2074, sf.annual_equivalent_full_load_hrs(col_name: 'fuel_loads_grill', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(3671, sf.annual_equivalent_full_load_hrs(col_name: 'fuel_loads_lighting', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(3671, sf.annual_equivalent_full_load_hrs(col_name: 'fuel_loads_fireplace', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2471, sf.annual_equivalent_full_load_hrs(col_name: 'pool_pump', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2471, sf.annual_equivalent_full_load_hrs(col_name: 'pool_heater', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2502, sf.annual_equivalent_full_load_hrs(col_name: 'hot_tub_pump', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2650, sf.annual_equivalent_full_load_hrs(col_name: 'hot_tub_heater', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2994, sf.annual_equivalent_full_load_hrs(col_name: 'hot_water_dishwasher', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(4158, sf.annual_equivalent_full_load_hrs(col_name: 'hot_water_clothes_washer', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(4204, sf.annual_equivalent_full_load_hrs(col_name: 'hot_water_fixtures', schedules: sf.tmp_schedules), 0.1)
    assert(!sf.schedules.keys.include?('vacancy'))
  end

  def test_smooth_vacancy
    hpxml = _create_hpxml('base.xml')
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)

    @args_hash['schedules_vacancy_period'] = 'Dec 1 - Jan 31'
    @args_hash['output_csv_path'] = File.absolute_path(File.join(@tmp_output_path, 'smooth-vacancy.csv'))
    model, hpxml = _test_measure()

    sf = SchedulesFile.new(model: model, schedules_path: @args_hash['output_csv_path'], col_names: Constants.ScheduleColNames.keys)

    vacancy_hrs = 31 * 2 * 24
    occupied_ratio = (1 - vacancy_hrs / 8760)

    assert_in_epsilon(4997 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: 'occupants', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2763 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: 'lighting_interior', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2176 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: 'lighting_exterior', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2176 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: 'lighting_garage', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(19 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: 'lighting_exterior_holiday', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(1810 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: 'cooking_range', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(6673 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: 'refrigerator', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(6673 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: 'extra_refrigerator', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(6673 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: 'freezer', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2436 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: 'dishwasher', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(3444 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: 'clothes_washer', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(3738 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: 'clothes_dryer', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(5342 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: 'ceiling_fan', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(4308 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: 'plug_loads_other', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(1844 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: 'plug_loads_tv', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(7272 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: 'plug_loads_vehicle', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2951 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: 'plug_loads_well_pump', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(1688 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: 'fuel_loads_grill', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2951 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: 'fuel_loads_lighting', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2951 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: 'fuel_loads_fireplace', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2471 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: 'pool_pump', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2471 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: 'pool_heater', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2502 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: 'hot_tub_pump', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2650 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: 'hot_tub_heater', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2436 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: 'hot_water_dishwasher', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(3444 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: 'hot_water_clothes_washer', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(3490 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: 'hot_water_fixtures', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(vacancy_hrs, sf.annual_equivalent_full_load_hrs(col_name: 'vacancy', schedules: sf.tmp_schedules), 0.1)
  end

  def test_stochastic
    hpxml = _create_hpxml('base.xml')
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)

    @args_hash['schedules_type'] = 'stochastic'
    @args_hash['output_csv_path'] = File.absolute_path(File.join(@tmp_output_path, 'stochastic.csv'))
    model, hpxml = _test_measure()

    sf = SchedulesFile.new(model: model, schedules_path: @args_hash['output_csv_path'], col_names: Constants.ScheduleColNames.keys)

    assert_in_epsilon(6689, sf.annual_equivalent_full_load_hrs(col_name: 'occupants', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2086, sf.annual_equivalent_full_load_hrs(col_name: 'lighting_interior', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(4090, sf.annual_equivalent_full_load_hrs(col_name: 'lighting_exterior', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(4090, sf.annual_equivalent_full_load_hrs(col_name: 'lighting_garage', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(150, sf.annual_equivalent_full_load_hrs(col_name: 'lighting_exterior_holiday', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(534, sf.annual_equivalent_full_load_hrs(col_name: 'cooking_range', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(6673, sf.annual_equivalent_full_load_hrs(col_name: 'refrigerator', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(6673, sf.annual_equivalent_full_load_hrs(col_name: 'extra_refrigerator', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(6673, sf.annual_equivalent_full_load_hrs(col_name: 'freezer', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(213, sf.annual_equivalent_full_load_hrs(col_name: 'dishwasher', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(134, sf.annual_equivalent_full_load_hrs(col_name: 'clothes_washer', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(151, sf.annual_equivalent_full_load_hrs(col_name: 'clothes_dryer', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(3250, sf.annual_equivalent_full_load_hrs(col_name: 'ceiling_fan', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(4840, sf.annual_equivalent_full_load_hrs(col_name: 'plug_loads_other', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2288, sf.annual_equivalent_full_load_hrs(col_name: 'plug_loads_tv', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(8760, sf.annual_equivalent_full_load_hrs(col_name: 'plug_loads_vehicle', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(3671, sf.annual_equivalent_full_load_hrs(col_name: 'plug_loads_well_pump', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2074, sf.annual_equivalent_full_load_hrs(col_name: 'fuel_loads_grill', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(3671, sf.annual_equivalent_full_load_hrs(col_name: 'fuel_loads_lighting', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(3671, sf.annual_equivalent_full_load_hrs(col_name: 'fuel_loads_fireplace', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2471, sf.annual_equivalent_full_load_hrs(col_name: 'pool_pump', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2471, sf.annual_equivalent_full_load_hrs(col_name: 'pool_heater', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2502, sf.annual_equivalent_full_load_hrs(col_name: 'hot_tub_pump', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2650, sf.annual_equivalent_full_load_hrs(col_name: 'hot_tub_heater', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(298, sf.annual_equivalent_full_load_hrs(col_name: 'hot_water_dishwasher', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(325, sf.annual_equivalent_full_load_hrs(col_name: 'hot_water_clothes_washer', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(1009, sf.annual_equivalent_full_load_hrs(col_name: 'hot_water_fixtures', schedules: sf.tmp_schedules), 0.1)
    assert(!sf.schedules.keys.include?('vacancy'))
  end

  def test_stochastic_vacancy
    hpxml = _create_hpxml('base.xml')
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)

    @args_hash['schedules_type'] = 'stochastic'
    @args_hash['schedules_vacancy_period'] = 'Dec 1 - Jan 31'
    @args_hash['output_csv_path'] = File.absolute_path(File.join(@tmp_output_path, 'stochastic-vacancy.csv'))
    model, hpxml = _test_measure()

    sf = SchedulesFile.new(model: model, schedules_path: @args_hash['output_csv_path'], col_names: Constants.ScheduleColNames.keys)

    vacancy_hrs = 31 * 2 * 24
    occupied_ratio = (1 - vacancy_hrs / 8760)

    assert_in_epsilon(5548 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: 'occupants', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(1675 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: 'lighting_interior', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(3222 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: 'lighting_exterior', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(3222 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: 'lighting_garage', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(11 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: 'lighting_exterior_holiday', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(439 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: 'cooking_range', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(6673 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: 'refrigerator', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(6673 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: 'extra_refrigerator', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(6673 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: 'freezer', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(179 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: 'dishwasher', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(111 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: 'clothes_washer', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(126 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: 'clothes_dryer', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2620 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: 'ceiling_fan', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(3912 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: 'plug_loads_other', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(1844 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: 'plug_loads_tv', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(7272 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: 'plug_loads_vehicle', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2951 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: 'plug_loads_well_pump', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(1688 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: 'fuel_loads_grill', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2951 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: 'fuel_loads_lighting', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2951 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: 'fuel_loads_fireplace', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2471 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: 'pool_pump', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2471 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: 'pool_heater', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2502 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: 'hot_tub_pump', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2650 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: 'hot_tub_heater', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(264 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: 'hot_water_dishwasher', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(273 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: 'hot_water_clothes_washer', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(832 * occupied_ratio, sf.annual_equivalent_full_load_hrs(col_name: 'hot_water_fixtures', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(vacancy_hrs, sf.annual_equivalent_full_load_hrs(col_name: 'vacancy', schedules: sf.tmp_schedules), 0.1)
  end

  def test_random_seed
    hpxml = _create_hpxml('base.xml')
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)

    @args_hash['schedules_type'] = 'stochastic'
    @args_hash['schedules_random_seed'] = 1
    @args_hash['output_csv_path'] = File.absolute_path(File.join(@tmp_output_path, 'stochastic.csv'))
    model, hpxml = _test_measure()

    sf = SchedulesFile.new(model: model, schedules_path: @args_hash['output_csv_path'], col_names: Constants.ScheduleColNames.keys)

    assert_in_epsilon(6689, sf.annual_equivalent_full_load_hrs(col_name: 'occupants', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2086, sf.annual_equivalent_full_load_hrs(col_name: 'lighting_interior', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(4090, sf.annual_equivalent_full_load_hrs(col_name: 'lighting_exterior', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(4090, sf.annual_equivalent_full_load_hrs(col_name: 'lighting_garage', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(150, sf.annual_equivalent_full_load_hrs(col_name: 'lighting_exterior_holiday', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(534, sf.annual_equivalent_full_load_hrs(col_name: 'cooking_range', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(6673, sf.annual_equivalent_full_load_hrs(col_name: 'refrigerator', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(6673, sf.annual_equivalent_full_load_hrs(col_name: 'extra_refrigerator', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(6673, sf.annual_equivalent_full_load_hrs(col_name: 'freezer', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(213, sf.annual_equivalent_full_load_hrs(col_name: 'dishwasher', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(134, sf.annual_equivalent_full_load_hrs(col_name: 'clothes_washer', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(151, sf.annual_equivalent_full_load_hrs(col_name: 'clothes_dryer', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(3250, sf.annual_equivalent_full_load_hrs(col_name: 'ceiling_fan', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(4840, sf.annual_equivalent_full_load_hrs(col_name: 'plug_loads_other', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2288, sf.annual_equivalent_full_load_hrs(col_name: 'plug_loads_tv', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(8760, sf.annual_equivalent_full_load_hrs(col_name: 'plug_loads_vehicle', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(3671, sf.annual_equivalent_full_load_hrs(col_name: 'plug_loads_well_pump', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2074, sf.annual_equivalent_full_load_hrs(col_name: 'fuel_loads_grill', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(3671, sf.annual_equivalent_full_load_hrs(col_name: 'fuel_loads_lighting', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(3671, sf.annual_equivalent_full_load_hrs(col_name: 'fuel_loads_fireplace', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2471, sf.annual_equivalent_full_load_hrs(col_name: 'pool_pump', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2471, sf.annual_equivalent_full_load_hrs(col_name: 'pool_heater', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2502, sf.annual_equivalent_full_load_hrs(col_name: 'hot_tub_pump', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2650, sf.annual_equivalent_full_load_hrs(col_name: 'hot_tub_heater', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(298, sf.annual_equivalent_full_load_hrs(col_name: 'hot_water_dishwasher', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(325, sf.annual_equivalent_full_load_hrs(col_name: 'hot_water_clothes_washer', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(1009, sf.annual_equivalent_full_load_hrs(col_name: 'hot_water_fixtures', schedules: sf.tmp_schedules), 0.1)
    assert(!sf.schedules.keys.include?('vacancy'))

    @args_hash['schedules_random_seed'] = 2
    model, hpxml = _test_measure()

    sf = SchedulesFile.new(model: model, schedules_path: @args_hash['output_csv_path'], col_names: Constants.ScheduleColNames.keys)

    assert_in_epsilon(6072, sf.annual_equivalent_full_load_hrs(col_name: 'occupants', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(1765, sf.annual_equivalent_full_load_hrs(col_name: 'lighting_interior', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(4090, sf.annual_equivalent_full_load_hrs(col_name: 'lighting_exterior', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(4090, sf.annual_equivalent_full_load_hrs(col_name: 'lighting_garage', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(150, sf.annual_equivalent_full_load_hrs(col_name: 'lighting_exterior_holiday', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(356, sf.annual_equivalent_full_load_hrs(col_name: 'cooking_range', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(6673, sf.annual_equivalent_full_load_hrs(col_name: 'refrigerator', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(6673, sf.annual_equivalent_full_load_hrs(col_name: 'extra_refrigerator', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(6673, sf.annual_equivalent_full_load_hrs(col_name: 'freezer', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(165, sf.annual_equivalent_full_load_hrs(col_name: 'dishwasher', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(101, sf.annual_equivalent_full_load_hrs(col_name: 'clothes_washer', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(166, sf.annual_equivalent_full_load_hrs(col_name: 'clothes_dryer', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(3250, sf.annual_equivalent_full_load_hrs(col_name: 'ceiling_fan', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(4840, sf.annual_equivalent_full_load_hrs(col_name: 'plug_loads_other', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2288, sf.annual_equivalent_full_load_hrs(col_name: 'plug_loads_tv', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(8760, sf.annual_equivalent_full_load_hrs(col_name: 'plug_loads_vehicle', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(3671, sf.annual_equivalent_full_load_hrs(col_name: 'plug_loads_well_pump', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2074, sf.annual_equivalent_full_load_hrs(col_name: 'fuel_loads_grill', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(3671, sf.annual_equivalent_full_load_hrs(col_name: 'fuel_loads_lighting', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(3671, sf.annual_equivalent_full_load_hrs(col_name: 'fuel_loads_fireplace', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2471, sf.annual_equivalent_full_load_hrs(col_name: 'pool_pump', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2471, sf.annual_equivalent_full_load_hrs(col_name: 'pool_heater', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2502, sf.annual_equivalent_full_load_hrs(col_name: 'hot_tub_pump', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(2650, sf.annual_equivalent_full_load_hrs(col_name: 'hot_tub_heater', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(226, sf.annual_equivalent_full_load_hrs(col_name: 'hot_water_dishwasher', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(244, sf.annual_equivalent_full_load_hrs(col_name: 'hot_water_clothes_washer', schedules: sf.tmp_schedules), 0.1)
    assert_in_epsilon(1126, sf.annual_equivalent_full_load_hrs(col_name: 'hot_water_fixtures', schedules: sf.tmp_schedules), 0.1)
    assert(!sf.schedules.keys.include?('vacancy'))
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

    return model, hpxml
  end

  def _create_hpxml(hpxml_name)
    return HPXML.new(hpxml_path: File.join(@sample_files_path, hpxml_name))
  end
end
