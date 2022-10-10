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
  end

  def test_stochastic_schedules
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-schedules-detailed-occupancy-stochastic.xml'))
    model, hpxml = _test_measure(args_hash)

    schedule_constants = 9
    schedule_rulesets = 5
    schedule_fixed_intervals = 1
    schedule_files = 14

    assert_equal(schedule_constants, model.getScheduleConstants.size)
    assert_equal(schedule_rulesets, model.getScheduleRulesets.size)
    assert_equal(schedule_fixed_intervals, model.getScheduleFixedIntervals.size)
    assert_equal(schedule_files, model.getScheduleFiles.size)
    assert_equal(model.getSchedules.size, schedule_constants + schedule_rulesets + schedule_fixed_intervals + schedule_files)

    schedule_file_names = []
    model.getScheduleFiles.each do |schedule_file|
      schedule_file_names << "#{schedule_file.name}"
    end
    assert(schedule_file_names.include?(SchedulesFile::ColumnOccupants))
    assert(schedule_file_names.include?(SchedulesFile::ColumnLightingInterior))
    assert(schedule_file_names.include?(SchedulesFile::ColumnLightingExterior))
    assert(!schedule_file_names.include?(SchedulesFile::ColumnLightingGarage))
    assert(!schedule_file_names.include?(SchedulesFile::ColumnLightingExteriorHoliday))
    assert(schedule_file_names.include?(SchedulesFile::ColumnCookingRange))
    assert(schedule_file_names.include?(SchedulesFile::ColumnRefrigerator))
    assert(!schedule_file_names.include?(SchedulesFile::ColumnExtraRefrigerator))
    assert(!schedule_file_names.include?(SchedulesFile::ColumnFreezer))
    assert(schedule_file_names.include?(SchedulesFile::ColumnDishwasher))
    assert(schedule_file_names.include?(SchedulesFile::ColumnClothesWasher))
    assert(schedule_file_names.include?(SchedulesFile::ColumnClothesDryer))
    assert(!schedule_file_names.include?(SchedulesFile::ColumnCeilingFan))
    assert(schedule_file_names.include?(SchedulesFile::ColumnPlugLoadsOther))
    assert(schedule_file_names.include?(SchedulesFile::ColumnPlugLoadsTV))
    assert(!schedule_file_names.include?(SchedulesFile::ColumnPlugLoadsVehicle))
    assert(!schedule_file_names.include?(SchedulesFile::ColumnPlugLoadsWellPump))
    assert(!schedule_file_names.include?(SchedulesFile::ColumnFuelLoadsGrill))
    assert(!schedule_file_names.include?(SchedulesFile::ColumnFuelLoadsLighting))
    assert(!schedule_file_names.include?(SchedulesFile::ColumnFuelLoadsFireplace))
    assert(!schedule_file_names.include?(SchedulesFile::ColumnPoolPump))
    assert(!schedule_file_names.include?(SchedulesFile::ColumnPoolHeater))
    assert(!schedule_file_names.include?(SchedulesFile::ColumnHotTubPump))
    assert(!schedule_file_names.include?(SchedulesFile::ColumnHotTubHeater))
    assert(schedule_file_names.include?(SchedulesFile::ColumnHotWaterClothesWasher))
    assert(schedule_file_names.include?(SchedulesFile::ColumnHotWaterDishwasher))
    assert(schedule_file_names.include?(SchedulesFile::ColumnHotWaterFixtures))

    # add a pool
    hpxml.pools.add(id: 'Pool',
                    type: HPXML::TypeUnknown,
                    pump_type: HPXML::TypeUnknown,
                    pump_kwh_per_year: 2700,
                    heater_type: HPXML::HeaterTypeGas,
                    heater_load_units: HPXML::UnitsThermPerYear,
                    heater_load_value: 500)

    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    model, _hpxml = _test_measure(args_hash)

    schedule_file_names = []
    model.getScheduleFiles.each do |schedule_file|
      schedule_file_names << "#{schedule_file.name}"
    end
    assert(schedule_file_names.include?(SchedulesFile::ColumnPoolPump))
    assert(schedule_file_names.include?(SchedulesFile::ColumnPoolHeater))
  end

  def test_stochastic_vacancy_schedules
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-schedules-detailed-occupancy-stochastic-vacancy.xml'))
    model, _hpxml = _test_measure(args_hash)

    schedule_constants = 9
    schedule_rulesets = 5
    schedule_fixed_intervals = 1
    schedule_files = 14

    assert_equal(schedule_constants, model.getScheduleConstants.size)
    assert_equal(schedule_rulesets, model.getScheduleRulesets.size)
    assert_equal(schedule_fixed_intervals, model.getScheduleFixedIntervals.size)
    assert_equal(schedule_files, model.getScheduleFiles.size)
    assert_equal(model.getSchedules.size, schedule_constants + schedule_rulesets + schedule_fixed_intervals + schedule_files)
  end

  def test_stochastic_outage_schedules
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-schedules-detailed-occupancy-stochastic-outage-full-year.xml'))
    model, _hpxml = _test_measure(args_hash)

    schedule_constants = 8
    schedule_rulesets = 5
    schedule_fixed_intervals = 1
    schedule_files = 18

    assert_equal(schedule_constants, model.getScheduleConstants.size)
    assert_equal(schedule_rulesets, model.getScheduleRulesets.size)
    assert_equal(schedule_fixed_intervals, model.getScheduleFixedIntervals.size)
    assert_equal(schedule_files, model.getScheduleFiles.size)
    assert_equal(model.getSchedules.size, schedule_constants + schedule_rulesets + schedule_fixed_intervals + schedule_files)
  end

  def test_stochastic_outage_natvent_schedules
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-schedules-detailed-occupancy-stochastic-outage-summer.xml'))
    model, _hpxml = _test_measure(args_hash)

    schedule_constants = 6
    schedule_rulesets = 4
    schedule_fixed_intervals = 3
    schedule_files = 19

    assert_equal(schedule_constants, model.getScheduleConstants.size)
    assert_equal(schedule_rulesets, model.getScheduleRulesets.size)
    assert_equal(schedule_fixed_intervals, model.getScheduleFixedIntervals.size)
    assert_equal(schedule_files, model.getScheduleFiles.size)
    assert_equal(model.getSchedules.size, schedule_constants + schedule_rulesets + schedule_fixed_intervals + schedule_files)
  end

  def test_smooth_schedules
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-schedules-detailed-occupancy-smooth.xml'))
    model, _hpxml = _test_measure(args_hash)

    schedule_constants = 9
    schedule_rulesets = 5
    schedule_fixed_intervals = 1
    schedule_files = 14

    assert_equal(schedule_constants, model.getScheduleConstants.size)
    assert_equal(schedule_rulesets, model.getScheduleRulesets.size)
    assert_equal(schedule_fixed_intervals, model.getScheduleFixedIntervals.size)
    assert_equal(schedule_files, model.getScheduleFiles.size)
    assert_equal(model.getSchedules.size, schedule_constants + schedule_rulesets + schedule_fixed_intervals + schedule_files)
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
