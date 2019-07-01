require_relative '../../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class ResidentialMiscElectricLoadsTest < MiniTest::Test
  def test_new_construction_none
    args_hash = {}
    args_hash["mult"] = 0.0
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = { "Annual_kwh" => 0 }
    _test_measure("SFD_2000sqft_2story_FB_GRG_UA_3Beds_2Baths.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  def test_new_construction_energy_use
    num_fin_spaces = 3
    args_hash = {}
    args_hash["option_type"] = Constants.OptionTypePlugLoadsEnergyUse
    expected_num_del_objects = {}
    expected_num_new_objects = { "ElectricEquipmentDefinition" => num_fin_spaces, "ElectricEquipment" => num_fin_spaces, "ScheduleRuleset" => 1 }
    expected_values = { "Annual_kwh" => 2000 }
    _test_measure("SFD_2000sqft_2story_FB_GRG_UA_3Beds_2Baths.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  def test_new_construction_mult_1_0
    num_fin_spaces = 3
    args_hash = {}
    args_hash["mult"] = 1.0
    expected_num_del_objects = {}
    expected_num_new_objects = { "ElectricEquipmentDefinition" => num_fin_spaces, "ElectricEquipment" => num_fin_spaces, "ScheduleRuleset" => 1 }
    expected_values = { "Annual_kwh" => 2206 }
    _test_measure("SFD_2000sqft_2story_FB_GRG_UA_3Beds_2Baths.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  def test_new_construction_mult_1_5
    num_fin_spaces = 3
    args_hash = {}
    args_hash["mult"] = 1.5
    expected_num_del_objects = {}
    expected_num_new_objects = { "ElectricEquipmentDefinition" => num_fin_spaces, "ElectricEquipment" => num_fin_spaces, "ScheduleRuleset" => 1 }
    expected_values = { "Annual_kwh" => 3309 }
    _test_measure("SFD_2000sqft_2story_FB_GRG_UA_3Beds_2Baths.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  def test_new_construction_modified_schedule
    num_fin_spaces = 3
    args_hash = {}
    args_hash["weekday_sch"] = "1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24"
    args_hash["weekend_sch"] = "1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24"
    args_hash["monthly_sch"] = "1,2,3,4,5,6,7,8,9,10,11,12"
    expected_num_del_objects = {}
    expected_num_new_objects = { "ElectricEquipmentDefinition" => num_fin_spaces, "ElectricEquipment" => num_fin_spaces, "ScheduleRuleset" => 1 }
    expected_values = { "Annual_kwh" => 2206 }
    _test_measure("SFD_2000sqft_2story_FB_GRG_UA_3Beds_2Baths.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  def test_retrofit_replace
    num_fin_spaces = 3
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = { "ElectricEquipmentDefinition" => num_fin_spaces, "ElectricEquipment" => num_fin_spaces, "ScheduleRuleset" => 1 }
    expected_values = { "Annual_kwh" => 2206 }
    model = _test_measure("SFD_2000sqft_2story_FB_GRG_UA_3Beds_2Baths.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
    args_hash = {}
    args_hash["mult"] = 0.5
    expected_num_del_objects = { "ElectricEquipmentDefinition" => num_fin_spaces, "ElectricEquipment" => num_fin_spaces, "ScheduleRuleset" => 1 }
    expected_num_new_objects = { "ElectricEquipmentDefinition" => num_fin_spaces, "ElectricEquipment" => num_fin_spaces, "ScheduleRuleset" => 1 }
    expected_values = { "Annual_kwh" => 1103 }
    _test_measure(model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_fin_spaces)
  end

  def test_retrofit_remove
    num_fin_spaces = 3
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = { "ElectricEquipmentDefinition" => num_fin_spaces, "ElectricEquipment" => num_fin_spaces, "ScheduleRuleset" => 1 }
    expected_values = { "Annual_kwh" => 2206 }
    model = _test_measure("SFD_2000sqft_2story_FB_GRG_UA_3Beds_2Baths.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
    args_hash = {}
    args_hash["mult"] = 0.0
    expected_num_del_objects = { "ElectricEquipmentDefinition" => num_fin_spaces, "ElectricEquipment" => num_fin_spaces, "ScheduleRuleset" => 1 }
    expected_num_new_objects = {}
    expected_values = { "Annual_kwh" => 0 }
    _test_measure(model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_fin_spaces)
  end

  def test_argument_error_mult_negative
    args_hash = {}
    args_hash["mult"] = -1.0
    result = _test_error("SFD_2000sqft_2story_FB_GRG_UA_3Beds_2Baths.osm", args_hash)
    assert_equal(result.errors.map { |x| x.logMessage }[0], "Annual energy use must be greater than or equal to 0.")
  end

  def test_argument_error_weekday_sch_wrong_number_of_values
    args_hash = {}
    args_hash["weekday_sch"] = "1,1"
    result = _test_error("SFD_2000sqft_2story_FB_GRG_UA_3Beds_2Baths.osm", args_hash)
    assert_equal(result.errors.map { |x| x.logMessage }[0], "A comma-separated string of 24 numbers must be entered for the weekday schedule.")
  end

  def test_argument_error_weekday_sch_not_number
    args_hash = {}
    args_hash["weekday_sch"] = "str,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1"
    result = _test_error("SFD_2000sqft_2story_FB_GRG_UA_3Beds_2Baths.osm", args_hash)
    assert_equal(result.errors.map { |x| x.logMessage }[0], "A comma-separated string of 24 numbers must be entered for the weekday schedule.")
  end

  def test_argument_error_weekend_sch_wrong_number_of_values
    args_hash = {}
    args_hash["weekend_sch"] = "1,1"
    result = _test_error("SFD_2000sqft_2story_FB_GRG_UA_3Beds_2Baths.osm", args_hash)
    assert_equal(result.errors.map { |x| x.logMessage }[0], "A comma-separated string of 24 numbers must be entered for the weekend schedule.")
  end

  def test_argument_error_weekend_sch_not_number
    args_hash = {}
    args_hash["weekend_sch"] = "str,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1"
    result = _test_error("SFD_2000sqft_2story_FB_GRG_UA_3Beds_2Baths.osm", args_hash)
    assert_equal(result.errors.map { |x| x.logMessage }[0], "A comma-separated string of 24 numbers must be entered for the weekend schedule.")
  end

  def test_argument_error_monthly_sch_wrong_number_of_values
    args_hash = {}
    args_hash["monthly_sch"] = "1,1"
    result = _test_error("SFD_2000sqft_2story_FB_GRG_UA_3Beds_2Baths.osm", args_hash)
    assert_equal(result.errors.map { |x| x.logMessage }[0], "A comma-separated string of 12 numbers must be entered for the monthly schedule.")
  end

  def test_argument_error_monthly_sch_not_number
    args_hash = {}
    args_hash["monthly_sch"] = "str,1,1,1,1,1,1,1,1,1,1,1"
    result = _test_error("SFD_2000sqft_2story_FB_GRG_UA_3Beds_2Baths.osm", args_hash)
    assert_equal(result.errors.map { |x| x.logMessage }[0], "A comma-separated string of 12 numbers must be entered for the monthly schedule.")
  end

  def test_error_missing_geometry
    args_hash = {}
    result = _test_error(nil, args_hash)
    assert_equal(result.errors.map { |x| x.logMessage }[0], "No building geometry has been defined.")
  end

  def test_single_family_attached_new_construction
    num_units = 4
    num_fin_spaces = num_units * 2
    args_hash = {}
    args_hash["mult"] = 1.0
    expected_num_del_objects = {}
    expected_num_new_objects = { "ElectricEquipment" => num_fin_spaces, "ElectricEquipmentDefinition" => num_fin_spaces, "ScheduleRuleset" => 1 }
    expected_values = { "Annual_kwh" => 7589.07 }
    _test_measure("SFA_4units_1story_FB_UA_3Beds_2Baths_Denver.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_units)
  end

  def test_multifamily_new_construction
    num_units = 8
    num_fin_spaces = num_units
    args_hash = {}
    args_hash["mult"] = 1.0
    expected_num_del_objects = {}
    expected_num_new_objects = { "ElectricEquipment" => num_fin_spaces, "ElectricEquipmentDefinition" => num_fin_spaces, "ScheduleRuleset" => 1 }
    expected_values = { "Annual_kwh" => 15178.13 }
    _test_measure("MF_8units_1story_SL_3Beds_2Baths_Denver.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_units)
  end

  private

  def _test_error(osm_file, args_hash)
    # create an instance of the measure
    measure = ResidentialMiscElectricLoads.new

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
    measure = ResidentialMiscElectricLoads.new

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
    obj_type_exclusions = ["ScheduleRule", "ScheduleDay", "ScheduleTypeLimits"]
    all_new_objects = get_object_additions(initial_objects, final_objects, obj_type_exclusions)
    all_del_objects = get_object_additions(final_objects, initial_objects, obj_type_exclusions)

    # check we have the expected number of new/deleted objects
    check_num_objects(all_new_objects, expected_num_new_objects, "added")
    check_num_objects(all_del_objects, expected_num_del_objects, "deleted")

    actual_values = { "Annual_kwh" => 0 }
    all_new_objects.each do |obj_type, new_objects|
      new_objects.each do |new_object|
        next if not new_object.respond_to?("to_#{obj_type}")

        new_object = new_object.public_send("to_#{obj_type}").get
        if obj_type == "ElectricEquipment"
          full_load_hrs = Schedule.annual_equivalent_full_load_hrs(model.getYearDescription, new_object.schedule.get)
          actual_values["Annual_kwh"] += UnitConversions.convert(full_load_hrs * new_object.designLevel.get * new_object.multiplier, "Wh", "kWh")
        end
      end
    end
    assert_in_epsilon(expected_values["Annual_kwh"], actual_values["Annual_kwh"], 0.01)

    return model
  end
end
