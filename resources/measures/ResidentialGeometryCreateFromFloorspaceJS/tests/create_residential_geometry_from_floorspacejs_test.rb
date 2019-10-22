require_relative '../../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class ResidentialGeometryFromFloorspaceJS_Test < MiniTest::Test
  def test_error_empty_floorplan_path
    args_hash = {}
    args_hash["floorplan_path"] = ""
    result = _test_error(nil, args_hash)
    assert(result.errors.size == 1)
    assert_equal("Fail", result.value.valueName)
    assert_includes(result.errors.map { |x| x.logMessage }, "Empty floorplan path was entered.")
  end

  def test_error_invalid_floorplan_path
    args_hash = {}
    args_hash["floorplan_path"] = File.join(File.dirname(__FILE__), "floorpaln.json")
    result = _test_error(nil, args_hash)
    assert(result.errors.size == 1)
    assert_equal("Fail", result.value.valueName)
    assert_includes(result.errors.map { |x| x.logMessage }, "Cannot find floorplan path '#{args_hash["floorplan_path"]}'.")
  end

  def test_warning_unexpected_space_type_name
    num_finished_spaces = 2
    args_hash = {}
    args_hash["floorplan_path"] = File.join(File.dirname(__FILE__), "unexpected_space_type_name.json")
    expected_num_del_objects = {}
    expected_num_new_objects = { "Building" => 1, "Surface" => 40, "Space" => 4, "SpaceType" => 3, "ThermalZone" => 3, "BuildingUnit" => 1, "BuildingStory" => 3, "PeopleDefinition" => num_finished_spaces, "People" => num_finished_spaces, "ScheduleRuleset" => 2 }
    expected_values = { "Beds" => { "Building Unit 1" => 3 }, "Baths" => { "Building Unit 1" => 2 }, "NumOccupants" => 2.64 }
    model, result = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, __method__)
    assert_includes(result.warnings.map { |x| x.logMessage }, "Unexpected space type 'grrage'.")
  end

  def test_error_mix_of_finished_and_unfinished_spaces_in_a_zone
    args_hash = {}
    args_hash["floorplan_path"] = File.join(File.dirname(__FILE__), "mix_of_spaces_in_a_zone.json")
    result = _test_error(nil, args_hash)
    assert(result.errors.size == 1)
    assert_equal("Fail", result.value.valueName)
    assert_includes(result.errors.map { |x| x.logMessage }, "'Thermal Zone 1' has a mix of finished and unfinished spaces.")
  end

  def test_error_empty_floorplan
    args_hash = {}
    args_hash["floorplan_path"] = File.join(File.dirname(__FILE__), "empty.json")
    result = _test_error(nil, args_hash)
    assert(result.errors.size == 1)
    assert_equal("Fail", result.value.valueName)
    assert_includes(result.errors.map { |x| x.logMessage }, "Cannot load floorplan from '#{args_hash["floorplan_path"]}'.")
  end

  def test_error_no_space_types
    args_hash = {}
    args_hash["floorplan_path"] = File.join(File.dirname(__FILE__), "no_space_types.json")
    result = _test_error(nil, args_hash)
    assert(result.errors.size == 1)
    assert_equal("Fail", result.value.valueName)
    assert_includes(result.errors.map { |x| x.logMessage }, "No space types were created.")
  end

  def test_no_zones_assigned_to_spaces
    num_finished_spaces = 2
    args_hash = {}
    args_hash["floorplan_path"] = File.join(File.dirname(__FILE__), "no_spaces_assigned_to_zones.json")
    expected_num_del_objects = {}
    expected_num_new_objects = { "Building" => 1, "Surface" => 40, "Space" => 4, "SpaceType" => 3, "ThermalZone" => 4, "BuildingUnit" => 1, "BuildingStory" => 3, "PeopleDefinition" => num_finished_spaces, "People" => num_finished_spaces, "ScheduleRuleset" => 2 }
    expected_values = { "Beds" => { "Building Unit 1" => 3 }, "Baths" => { "Building Unit 1" => 2 }, "NumOccupants" => 2.64 }
    model, result = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, __method__)
  end

  def test_simple_floorplan_unfinished_attic
    num_finished_spaces = 2
    args_hash = {}
    args_hash["floorplan_path"] = File.join(File.dirname(__FILE__), "SFD_UA.json")
    expected_num_del_objects = {}
    expected_num_new_objects = { "Building" => 1, "Surface" => 40, "Space" => 4, "SpaceType" => 3, "ThermalZone" => 3, "BuildingUnit" => 1, "BuildingStory" => 3, "PeopleDefinition" => num_finished_spaces, "People" => num_finished_spaces, "ScheduleRuleset" => 2 }
    expected_values = { "Beds" => { "Building Unit 1" => 3 }, "Baths" => { "Building Unit 1" => 2 }, "NumOccupants" => 2.64 }
    model, result = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, __method__)
  end

  def test_simple_floorplan_finished_attic
    num_finished_spaces = 3
    args_hash = {}
    args_hash["floorplan_path"] = File.join(File.dirname(__FILE__), "SFD_FA.json")
    expected_num_del_objects = {}
    expected_num_new_objects = { "Building" => 1, "Surface" => 40, "Space" => 4, "SpaceType" => 2, "ThermalZone" => 2, "BuildingUnit" => 1, "BuildingStory" => 3, "PeopleDefinition" => num_finished_spaces, "People" => num_finished_spaces, "ScheduleRuleset" => 2 }
    expected_values = { "Beds" => { "Building Unit 1" => 3 }, "Baths" => { "Building Unit 1" => 2 }, "NumOccupants" => 2.64 }
    model, result = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, __method__)
  end

  def test_single_family_attached
    num_finished_spaces = 4
    args_hash = {}
    args_hash["floorplan_path"] = File.join(File.dirname(__FILE__), "SFA_2unit.json")
    expected_num_del_objects = {}
    expected_num_new_objects = { "Building" => 1, "Surface" => 71, "Space" => 8, "SpaceType" => 3, "ThermalZone" => 6, "BuildingUnit" => 2, "BuildingStory" => 3, "PeopleDefinition" => num_finished_spaces, "People" => num_finished_spaces, "ScheduleRuleset" => 2 }
    expected_values = { "Beds" => { "Building Unit 1" => 3, "Building Unit 2" => 3 }, "Baths" => { "Building Unit 1" => 2, "Building Unit 2" => 2 }, "NumOccupants" => 6.78 }
    model, result = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, __method__)
  end

  def test_multifamily
    num_finished_spaces = 4
    args_hash = {}
    args_hash["floorplan_path"] = File.join(File.dirname(__FILE__), "MF_4unit.json")
    expected_num_del_objects = {}
    expected_num_new_objects = { "Building" => 1, "Surface" => 24, "Space" => 4, "SpaceType" => 1, "ThermalZone" => 4, "BuildingUnit" => 4, "BuildingStory" => 2, "PeopleDefinition" => num_finished_spaces, "People" => num_finished_spaces, "ScheduleRuleset" => 2 }
    expected_values = { "Beds" => { "Building Unit 1" => 3, "Building Unit 2" => 3, "Building Unit 3" => 3, "Building Unit 4" => 3 }, "Baths" => { "Building Unit 1" => 2, "Building Unit 2" => 2, "Building Unit 3" => 2, "Building Unit 4" => 2 }, "NumOccupants" => 13.56 }
    model, result = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, __method__)
  end

  def test_mf_with_corridor
    num_finished_spaces = 12
    args_hash = {}
    args_hash["floorplan_path"] = File.join(File.dirname(__FILE__), "MF_corr_12unit.json")
    expected_num_del_objects = {}
    expected_num_new_objects = { "Building" => 1, "Surface" => 92, "Space" => 14, "SpaceType" => 2, "ThermalZone" => 14, "BuildingUnit" => 12, "BuildingStory" => 2, "PeopleDefinition" => num_finished_spaces, "People" => num_finished_spaces, "ScheduleRuleset" => 2 }
    expected_values = { "Beds" => { "Building Unit 1" => 3, "Building Unit 2" => 3, "Building Unit 3" => 3, "Building Unit 4" => 3, "Building Unit 5" => 3, "Building Unit 6" => 3, "Building Unit 7" => 3, "Building Unit 8" => 3, "Building Unit 9" => 3, "Building Unit 10" => 3, "Building Unit 11" => 3, "Building Unit 12" => 3 }, "Baths" => { "Building Unit 1" => 2, "Building Unit 2" => 2, "Building Unit 3" => 2, "Building Unit 4" => 2, "Building Unit 5" => 2, "Building Unit 6" => 2, "Building Unit 7" => 2, "Building Unit 8" => 2, "Building Unit 9" => 2, "Building Unit 10" => 2, "Building Unit 11" => 2, "Building Unit 12" => 2 }, "NumOccupants" => 40.68 }
    model, result = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, __method__)
  end

  def test_sfd_multi_zone_floorplan
    num_finished_spaces = 10
    args_hash = {}
    args_hash["floorplan_path"] = File.join(File.dirname(__FILE__), "SFD_Multizone.json")
    expected_num_del_objects = {}
    expected_num_new_objects = { "Building" => 1, "Surface" => 80, "Space" => 12, "SpaceType" => 7, "ThermalZone" => 12, "BuildingUnit" => 1, "BuildingStory" => 3, "PeopleDefinition" => num_finished_spaces, "People" => num_finished_spaces, "ScheduleRuleset" => 2 }
    expected_values = { "Beds" => { "unit 1" => 3 }, "Baths" => { "unit 1" => 2 }, "NumOccupants" => 2.64 }
    model, result = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, __method__)
  end

  def test_mf_multi_zone_floorplan
    num_finished_spaces = 3 * 8
    args_hash = {}
    args_hash["floorplan_path"] = File.join(File.dirname(__FILE__), "MF_Multizone.json")
    expected_num_del_objects = {}
    expected_num_new_objects = { "Building" => 1, "Surface" => 181, "Space" => 26, "SpaceType" => 6, "ThermalZone" => 22, "BuildingUnit" => 2, "BuildingStory" => 3, "PeopleDefinition" => num_finished_spaces, "People" => num_finished_spaces, "ScheduleRuleset" => 2 }
    expected_values = { "Beds" => { "Building Unit 1" => 3, "Building Unit 2" => 3 }, "Baths" => { "Building Unit 1" => 2, "Building Unit 2" => 2 }, "NumOccupants" => 6.78 }
    model, result = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, __method__)
  end

  def test_mf_with_corridor_bedrooms_assignment
    num_finished_spaces = 12
    args_hash = {}
    args_hash["num_bedrooms"] = "1, 1, 2, 2, 3, 3, 1, 2, 3, 1, 2, 3"
    args_hash["floorplan_path"] = File.join(File.dirname(__FILE__), "MF_corr_12unit.json")
    expected_num_del_objects = {}
    expected_num_new_objects = { "Building" => 1, "Surface" => 92, "Space" => 14, "SpaceType" => 2, "ThermalZone" => 14, "BuildingUnit" => 12, "BuildingStory" => 2, "PeopleDefinition" => num_finished_spaces, "People" => num_finished_spaces, "ScheduleRuleset" => 2 }
    expected_values = { "Beds" => { "Building Unit 1" => 1, "Building Unit 2" => 1, "Building Unit 3" => 2, "Building Unit 4" => 2, "Building Unit 5" => 3, "Building Unit 6" => 3, "Building Unit 7" => 1, "Building Unit 8" => 2, "Building Unit 9" => 3, "Building Unit 10" => 1, "Building Unit 11" => 2, "Building Unit 12" => 3 }, "Baths" => { "Building Unit 1" => 2, "Building Unit 2" => 2, "Building Unit 3" => 2, "Building Unit 4" => 2, "Building Unit 5" => 2, "Building Unit 6" => 2, "Building Unit 7" => 2, "Building Unit 8" => 2, "Building Unit 9" => 2, "Building Unit 10" => 2, "Building Unit 11" => 2, "Building Unit 12" => 2 }, "NumOccupants" => 29.64 }
    model, result = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, __method__)
  end

  def test_argument_error_beds_not_equal_to_baths
    args_hash = {}
    args_hash["num_bedrooms"] = "3.0, 3.0, 3.0"
    args_hash["num_bathrooms"] = "2.0, 2.0"
    result = _test_error(nil, args_hash)
    assert_includes(result.errors.map { |x| x.logMessage }, "Number of bedroom elements specified inconsistent with number of bathroom elements specified.")
  end

  def test_argument_error_beds_not_equal_to_units
    args_hash = {}
    args_hash["num_bedrooms"] = "3.0, 3.0"
    result = _test_error(nil, args_hash)
    assert_includes(result.errors.map { |x| x.logMessage }, "Number of bedroom elements specified inconsistent with number of multifamily units defined in the model.")
  end

  def test_argument_error_baths_not_equal_to_units
    args_hash = {}
    args_hash["num_bathrooms"] = "2.0, 2.0"
    result = _test_error(nil, args_hash)
    assert_includes(result.errors.map { |x| x.logMessage }, "Number of bathroom elements specified inconsistent with number of multifamily units defined in the model.")
  end

  def test_argument_error_beds_not_numerical
    args_hash = {}
    args_hash["num_bedrooms"] = "3.0, 3.0, typo"
    result = _test_error(nil, args_hash)
    assert_includes(result.errors.map { |x| x.logMessage }, "Number of bedrooms must be a numerical value.")
  end

  def test_argument_error_baths_not_numerical
    args_hash = {}
    args_hash["num_bathrooms"] = "2.0, 2.0, typo"
    result = _test_error(nil, args_hash)
    assert_includes(result.errors.map { |x| x.logMessage }, "Number of bathrooms must be a numerical value.")
  end

  def test_argument_error_beds_not_positive_integer
    args_hash = {}
    args_hash["num_bedrooms"] = "3.0, 3.0, 3.5"
    result = _test_error(nil, args_hash)
    assert_includes(result.errors.map { |x| x.logMessage }, "Number of bedrooms must be a non-negative integer.")
  end

  def test_argument_error_baths_not_positive_multiple_of_0pt25
    args_hash = {}
    args_hash["num_bathrooms"] = "2.0, 2.0, 2.8"
    result = _test_error(nil, args_hash)
    assert_includes(result.errors.map { |x| x.logMessage }, "Number of bathrooms must be a positive multiple of 0.25.")
  end

  def test_argument_error_num_occ_bad_string
    args_hash = {}
    args_hash["num_occupants"] = "hello"
    result = _test_error(nil, args_hash)
    assert_includes(result.errors.map { |x| x.logMessage }, "Number of Occupants must be either '#{Constants.Auto}' or a number greater than or equal to 0.")
  end

  def test_argument_error_num_occ_negative
    args_hash = {}
    args_hash["num_occupants"] = "-1"
    result = _test_error(nil, args_hash)
    assert_includes(result.errors.map { |x| x.logMessage }, "Number of Occupants must be either '#{Constants.Auto}' or a number greater than or equal to 0.")
  end

  def test_argument_error_num_occ_incorrect_num_elements
    args_hash = {}
    args_hash["num_occupants"] = "2, 3, 4"
    result = _test_error(nil, args_hash)
    assert_includes(result.errors.map { |x| x.logMessage }, "Number of occupant elements specified inconsistent with number of multifamily units defined in the model.")
  end

  def test_argument_error_weekday_sch_wrong_number_of_values
    args_hash = {}
    args_hash["occupants_weekday_sch"] = "1,1"
    result = _test_error(nil, args_hash)
    assert_includes(result.errors.map { |x| x.logMessage }, "A comma-separated string of 24 numbers must be entered for the weekday schedule.")
  end

  def test_argument_error_weekday_sch_not_number
    args_hash = {}
    args_hash["occupants_weekday_sch"] = "str,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1"
    result = _test_error(nil, args_hash)
    assert_includes(result.errors.map { |x| x.logMessage }, "A comma-separated string of 24 numbers must be entered for the weekday schedule.")
  end

  def test_argument_error_weekend_sch_wrong_number_of_values
    args_hash = {}
    args_hash["occupants_weekend_sch"] = "1,1"
    result = _test_error(nil, args_hash)
    assert_includes(result.errors.map { |x| x.logMessage }, "A comma-separated string of 24 numbers must be entered for the weekend schedule.")
  end

  def test_argument_error_weekend_sch_not_number
    args_hash = {}
    args_hash["occupants_weekend_sch"] = "str,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1"
    result = _test_error(nil, args_hash)
    assert_includes(result.errors.map { |x| x.logMessage }, "A comma-separated string of 24 numbers must be entered for the weekend schedule.")
  end

  def test_argument_error_monthly_sch_wrong_number_of_values
    args_hash = {}
    args_hash["occupants_monthly_sch"] = "1,1"
    result = _test_error(nil, args_hash)
    assert_includes(result.errors.map { |x| x.logMessage }, "A comma-separated string of 12 numbers must be entered for the monthly schedule.")
  end

  def test_argument_error_monthly_sch_not_number
    args_hash = {}
    args_hash["occupants_monthly_sch"] = "str,1,1,1,1,1,1,1,1,1,1,1"
    result = _test_error(nil, args_hash)
    assert_includes(result.errors.map { |x| x.logMessage }, "A comma-separated string of 12 numbers must be entered for the monthly schedule.")
  end

  def test_new_construction_none
    args_hash = {}
    args_hash["num_occupants"] = "0"
    expected_num_del_objects = {}
    expected_num_new_objects = { "Building" => 1, "Surface" => 80, "Space" => 12, "SpaceType" => 7, "ThermalZone" => 12, "BuildingUnit" => 1, "BuildingStory" => 3 }
    expected_values = { "Beds" => { "unit 1" => 3 }, "Baths" => { "unit 1" => 2 }, "NumOccupants" => 0 }
    model, result = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, __method__)
  end

  def test_new_construction_auto
    num_finished_spaces = 10
    args_hash = {}
    args_hash["num_occupants"] = Constants.Auto
    expected_num_del_objects = {}
    expected_num_new_objects = { "Building" => 1, "Surface" => 80, "Space" => 12, "SpaceType" => 7, "ThermalZone" => 12, "BuildingUnit" => 1, "BuildingStory" => 3, "PeopleDefinition" => num_finished_spaces, "People" => num_finished_spaces, "ScheduleRuleset" => 2 }
    expected_values = { "Beds" => { "unit 1" => 3 }, "Baths" => { "unit 1" => 2 }, "NumOccupants" => 2.64 }
    model, result = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, __method__)
  end

  def test_new_construction_fixed_3
    num_finished_spaces = 10
    args_hash = {}
    args_hash["num_occupants"] = "3"
    expected_num_del_objects = {}
    expected_num_new_objects = { "Building" => 1, "Surface" => 80, "Space" => 12, "SpaceType" => 7, "ThermalZone" => 12, "BuildingUnit" => 1, "BuildingStory" => 3, "PeopleDefinition" => num_finished_spaces, "People" => num_finished_spaces, "ScheduleRuleset" => 2 }
    expected_values = { "Beds" => { "unit 1" => 3 }, "Baths" => { "unit 1" => 2 }, "NumOccupants" => 3 }
    model, result = _test_measure(nil, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, __method__)
  end

  private

  def _test_error(osm_file, args_hash)
    # create an instance of the measure
    measure = ResidentialGeometryFromFloorspaceJS.new

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

    return result
  end

  def _test_measure(osm_file_or_model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, test_name)
    # create an instance of the measure
    measure = ResidentialGeometryFromFloorspaceJS.new

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

    # save the model to test output directory
    # output_file_path = OpenStudio::Path.new(File.dirname(__FILE__) + "/output/#{test_name}.osm")
    # model.save(output_file_path, true)

    # show the output
    show_output(result) unless result.value.valueName == 'Success'

    # assert that it ran correctly
    assert_equal("Success", result.value.valueName)

    # get the final objects in the model
    final_objects = get_objects(model)

    # get new and deleted objects
    obj_type_exclusions = ["PortList", "ZoneHVACEquipmentList", "Node", "SizingZone", "RenderingColor", "ScheduleRule", "ScheduleDay", "ScheduleTypeLimits", "YearDescription"]
    all_new_objects = get_object_additions(initial_objects, final_objects, obj_type_exclusions)
    all_del_objects = get_object_additions(final_objects, initial_objects, obj_type_exclusions)

    # check we have the expected number of new/deleted objects
    check_num_objects(all_new_objects, expected_num_new_objects, "added")
    check_num_objects(all_del_objects, expected_num_del_objects, "deleted")

    Geometry.get_building_units(model, runner).each do |unit|
      unit_name = unit.name.to_s
      nbeds, nbaths = Geometry.get_unit_beds_baths(model, unit, runner)
      assert_equal(expected_values["Beds"][unit_name], nbeds)
      assert_equal(expected_values["Baths"][unit_name], nbaths)
    end

    actual_values = { "NumOccupants" => 0 }
    all_new_objects.each do |obj_type, new_objects|
      new_objects.each do |new_object|
        next if not new_object.respond_to?("to_#{obj_type}")

        new_object = new_object.public_send("to_#{obj_type}").get
        if obj_type == "People"
          actual_values["NumOccupants"] += new_object.peopleDefinition.numberofPeople.get
        end
      end
    end
    assert_in_epsilon(expected_values["NumOccupants"], actual_values["NumOccupants"], 0.01)

    return model, result
  end
end
