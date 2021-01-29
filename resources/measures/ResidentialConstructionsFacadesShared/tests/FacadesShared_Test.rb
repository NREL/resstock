require_relative '../../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class ProcessConstructionsFacadesSharedTest < MiniTest::Test
  def test_single_family_detached
    args_hash = {}
    args_hash["shared_building_facades"] = Constants.FacadeNone
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = { "SharedWalls" => 0 }
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  def test_single_family_attached
    skip
    args_hash = {}
    args_hash["shared_building_facades"] = "#{Constants.FacadeLeft}, #{Constants.FacadeRight}, #{Constants.FacadeBack}"
    expected_num_del_objects = {}
    expected_num_new_objects = { "Material" => 1, "Construction" => 1 }
    expected_values = { "SharedWalls" => 38 }
    _test_measure("SFA_10units_2story_FB_UA_3Beds_2Baths_Denver.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  def test_multifamily
    skip
    args_hash = {}
    args_hash["shared_building_facades"] = "#{Constants.FacadeLeft}, #{Constants.FacadeRight}, #{Constants.FacadeBack}"
    expected_num_del_objects = {}
    expected_num_new_objects = { "Material" => 1, "Construction" => 1 }
    expected_values = { "SharedWalls" => 55 }
    _test_measure("MF_40units_4story_CS_3Beds_2Baths_Denver.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
  end

  private

  def _test_measure(osm_file_or_model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values)
    # create an instance of the measure
    measure = ProcessConstructionsFacadesShared.new

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

    # get the final objects in the model
    final_objects = get_objects(model)

    # get new and deleted objects
    obj_type_exclusions = []
    all_new_objects = get_object_additions(initial_objects, final_objects, obj_type_exclusions)
    all_del_objects = get_object_additions(final_objects, initial_objects, obj_type_exclusions)

    # check we have the expected number of new/deleted objects
    check_num_objects(all_new_objects, expected_num_new_objects, "added")
    check_num_objects(all_del_objects, expected_num_del_objects, "deleted")

    assert_equal(expected_values["SharedWalls"], result.info.size)

    return model
  end
end
