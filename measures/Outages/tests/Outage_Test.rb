require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class OutageTest < MiniTest::Test
  # Test Cases:
  # Potential Additional Test Cases:
  # Apply the outage multiple times
  # Apply outage to a building that doesn't have everything
  # Unit test to ensure electricity is 0 during an outage
  # Eventually, add unit tests with different water heater types

  def test_outage_after_year_end
    args_hash = {}
    args_hash["otg_date"] = "December 31"
    args_hash["otg_len"] = 48
    result = _test_error("example_single_family_detached.osm", args_hash)
    assert_equal(result.errors.map { |x| x.logMessage }[0], "Outage end day is after the run period ends")
  end

  def test_outage_starts_before_run_period
    args_hash = {}
    args_hash["otg_date"] = "January 30"
    args_hash["otg_len"] = 48
    result = _test_error("example_single_family_detached_FebruaryRunPeriod.osm", args_hash)
    assert_equal(result.errors.map { |x| x.logMessage }[0], "Outage start day is before the run period start")
  end

  def test_outage_ends_after_run_period
    args_hash = {}
    args_hash["otg_date"] = "February 28"
    args_hash["otg_len"] = 48
    result = _test_error("example_single_family_detached_FebruaryRunPeriod.osm", args_hash)
    assert_equal(result.errors.map { |x| x.logMessage }[0], "Outage end day is after the run period ends")
  end

  def test_outage_len_zero
    args_hash = {}
    args_hash["otg_len"] = 0
    result = _test_error("example_single_family_detached.osm", args_hash)
    assert_equal(result.errors.map { |x| x.logMessage }[0], "Outage must last for at least one hour")
  end

  def test_outage_over_one_year
    args_hash = {}
    args_hash["otg_len"] = 9000
    result = _test_error("example_single_family_detached.osm", args_hash)
    assert_equal(result.errors.map { |x| x.logMessage }[0], "Outage can't run for longer than one year")
  end

  def test_outage_negative_start_hour
    args_hash = {}
    args_hash["otg_hr"] = -1
    result = _test_error("example_single_family_detached.osm", args_hash)
    assert_equal(result.errors.map { |x| x.logMessage }[0], "Start hour must be between 0 and 23")
  end

  def test_outage_start_hour_over_24
    args_hash = {}
    args_hash["otg_hr"] = 25
    result = _test_error("example_single_family_detached.osm", args_hash)
    assert_equal(result.errors.map { |x| x.logMessage }[0], "Start hour must be between 0 and 23")
  end

  def test_outage_less_than_one_day_dst
    args_hash = {}
    args_hash["otg_date"] = "June 2"
    args_hash["otg_hr"] = 8
    args_hash["otg_len"] = 8
    expected_num_del_objects = {}
    expected_num_new_objects = { "ScheduleRule" => 21, "ScheduleDay" => 21 }
    expected_values = {}
    _test_measure("example_single_family_detached.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  def test_outage_one_day_dst
    args_hash = {}
    args_hash["otg_date"] = "June 2"
    args_hash["otg_hr"] = 8
    args_hash["otg_len"] = 24
    expected_num_del_objects = {}
    expected_num_new_objects = { "ScheduleRule" => 42, "ScheduleDay" => 42 }
    expected_values = {}
    _test_measure("example_single_family_detached.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  def test_outage_more_than_one_day_dst
    args_hash = {}
    args_hash["otg_date"] = "June 2"
    args_hash["otg_hr"] = 8
    args_hash["otg_len"] = 48
    expected_num_del_objects = {}
    expected_num_new_objects = { "ScheduleRule" => 63, "ScheduleDay" => 63 }
    expected_values = {}
    _test_measure("example_single_family_detached.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  def test_outage_less_than_one_day
    args_hash = {}
    args_hash["otg_date"] = "January 2"
    args_hash["otg_hr"] = 8
    args_hash["otg_len"] = 8
    expected_num_del_objects = {}
    expected_num_new_objects = { "ScheduleRule" => 21, "ScheduleDay" => 21 }
    expected_values = {}
    _test_measure("example_single_family_detached.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  def test_outage_one_day
    args_hash = {}
    args_hash["otg_date"] = "January 2"
    args_hash["otg_hr"] = 8
    args_hash["otg_len"] = 24
    expected_num_del_objects = {}
    expected_num_new_objects = { "ScheduleRule" => 42, "ScheduleDay" => 42 }
    expected_values = {}
    _test_measure("example_single_family_detached.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  def test_outage_more_than_one_day
    args_hash = {}
    args_hash["otg_date"] = "January 2"
    args_hash["otg_hr"] = 8
    args_hash["otg_len"] = 48
    expected_num_del_objects = {}
    expected_num_new_objects = { "ScheduleRule" => 63, "ScheduleDay" => 63 }
    expected_values = {}
    _test_measure("example_single_family_detached.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  private

  def _test_error(osm_file, args_hash)
    # create an instance of the measure
    measure = ProcessPowerOutage.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    model = get_model(File.dirname(__FILE__), osm_file)

    # get arguments
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
    show_output(result) unless result.value.valueName == 'Fail'

    # assert that it didn't run
    assert_equal("Fail", result.value.valueName)
    assert(result.errors.size == 1)

    return result
  end

  def _test_measure(osm_file_or_model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_infos = 0, num_warnings = 0)
    # create an instance of the measure
    measure = ProcessPowerOutage.new

    # check for standard methods
    assert(!measure.name.empty?)
    assert(!measure.description.empty?)
    assert(!measure.modeler_description.empty?)

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    model = get_model(File.dirname(__FILE__), osm_file_or_model)

    # get the initial objects in the model
    initial_objects = get_objects(model)

    # get arguments
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
    assert_equal("Success", result.value.valueName)
    assert_equal(num_infos, result.info.size)
    assert_equal(num_warnings, result.warnings.size)
    assert(result.finalCondition.is_initialized)

    # get the final objects in the model
    final_objects = get_objects(model)

    # get new and deleted objects
    obj_type_exclusions = []
    all_new_objects = get_object_additions(initial_objects, final_objects, obj_type_exclusions)
    all_del_objects = get_object_additions(final_objects, initial_objects, obj_type_exclusions)

    # check we have the expected number of new/deleted objects
    check_num_objects(all_new_objects, expected_num_new_objects, "added")
    check_num_objects(all_del_objects, expected_num_del_objects, "deleted")

    return model
  end
end
