require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class ResidentialLightingTest < MiniTest::Test

  def osm_geo
    return "2000sqft_2story_FB_GRG_UA.osm"
  end
  
  def osm_geo_beds
    return "2000sqft_2story_FB_GRG_UA_3Beds_2Baths.osm"
  end

  def osm_geo_beds_loc
    return "2000sqft_2story_FB_GRG_UA_3Beds_2Baths_Denver.osm"
  end

  def test_new_construction_100_incandescent
    args_hash = {}
    args_hash["hw_cfl"] = 0.0
    args_hash["hw_led"] = 0.0
    args_hash["hw_lfl"] = 0.0
    args_hash["pg_cfl"] = 0.0
    args_hash["pg_led"] = 0.0
    args_hash["pg_lfl"] = 0.0
    _test_measure(osm_geo_beds_loc, args_hash, 0, 5, 2085)
  end
  
  def test_new_construction_20_cfl_hw_34_cfl_pg
    args_hash = {}
    args_hash["hw_cfl"] = 0.2
    args_hash["hw_led"] = 0.0
    args_hash["hw_lfl"] = 0.0
    args_hash["pg_cfl"] = 0.34
    args_hash["pg_led"] = 0.0
    args_hash["pg_lfl"] = 0.0
    _test_measure(osm_geo_beds_loc, args_hash, 0, 5, 1848)
  end
  
  def test_new_construction_34_cfl_hw_34_cfl_pg
    args_hash = {}
    args_hash["hw_cfl"] = 0.34
    args_hash["hw_led"] = 0.0
    args_hash["hw_lfl"] = 0.0
    args_hash["pg_cfl"] = 0.34
    args_hash["pg_led"] = 0.0
    args_hash["pg_lfl"] = 0.0
    _test_measure(osm_geo_beds_loc, args_hash, 0, 5, 1733)
  end
  
  def test_new_construction_60_led_hw_34_cfl_pg
    args_hash = {}
    args_hash["hw_cfl"] = 0.0
    args_hash["hw_led"] = 0.6
    args_hash["hw_lfl"] = 0.0
    args_hash["pg_cfl"] = 0.34
    args_hash["pg_led"] = 0.0
    args_hash["pg_lfl"] = 0.0
    _test_measure(osm_geo_beds_loc, args_hash, 0, 5, 1461)
  end
  
  def test_new_construction_100_cfl
    args_hash = {}
    args_hash["hw_cfl"] = 1.0
    args_hash["hw_led"] = 0.0
    args_hash["hw_lfl"] = 0.0
    args_hash["pg_cfl"] = 1.0
    args_hash["pg_led"] = 0.0
    args_hash["pg_lfl"] = 0.0
    _test_measure(osm_geo_beds_loc, args_hash, 0, 5, 1110)
  end
  
  def test_new_construction_100_led
    args_hash = {}
    args_hash["hw_cfl"] = 0.0
    args_hash["hw_led"] = 1.0
    args_hash["hw_lfl"] = 0.0
    args_hash["pg_cfl"] = 0.0
    args_hash["pg_led"] = 1.0
    args_hash["pg_lfl"] = 0.0
    _test_measure(osm_geo_beds_loc, args_hash, 0, 5, 957)
  end
  
  def test_new_construction_100_led_low_efficacy
    args_hash = {}
    args_hash["hw_cfl"] = 0.0
    args_hash["hw_led"] = 1.0
    args_hash["hw_lfl"] = 0.0
    args_hash["pg_cfl"] = 0.0
    args_hash["pg_led"] = 1.0
    args_hash["pg_lfl"] = 0.0
    args_hash["led_eff"] = 50
    _test_measure(osm_geo_beds_loc, args_hash, 0, 5, 1159)
  end
  
  def test_retrofit_replace
    args_hash = {}
    model = _test_measure(osm_geo_beds_loc, args_hash, 0, 5, 1733)
    args_hash = {}
    args_hash["hw_cfl"] = 1.0
    _test_measure(model, args_hash, 5, 5, 1252)
  end

  def test_argument_error_hw_cfl_lt_0
    args_hash = {}
    args_hash["hw_cfl"] = -1.0
    _test_error(osm_geo_beds_loc, args_hash)
  end
  
  def test_argument_error_hw_cfl_gt_1
    args_hash = {}
    args_hash["hw_cfl"] = 1.1
    _test_error(osm_geo_beds_loc, args_hash)
  end
  
  def test_argument_error_hw_led_lt_0
    args_hash = {}
    args_hash["hw_led"] = -1.0
    _test_error(osm_geo_beds_loc, args_hash)
  end
  
  def test_argument_error_hw_led_gt_1
    args_hash = {}
    args_hash["hw_led"] = 1.1
    _test_error(osm_geo_beds_loc, args_hash)
  end
  
  def test_argument_error_hw_lfl_lt_0
    args_hash = {}
    args_hash["hw_lfl"] = -1.0
    _test_error(osm_geo_beds_loc, args_hash)
  end
  
  def test_argument_error_hw_lfl_gt_1
    args_hash = {}
    args_hash["hw_lfl"] = 1.1
    _test_error(osm_geo_beds_loc, args_hash)
  end
  
  def test_argument_error_pg_cfl_lt_0
    args_hash = {}
    args_hash["pg_cfl"] = -1.0
    _test_error(osm_geo_beds_loc, args_hash)
  end
  
  def test_argument_error_pg_cfl_gt_1
    args_hash = {}
    args_hash["pg_cfl"] = 1.1
    _test_error(osm_geo_beds_loc, args_hash)
  end
  
  def test_argument_error_pg_led_lt_0
    args_hash = {}
    args_hash["pg_led"] = -1.0
    _test_error(osm_geo_beds_loc, args_hash)
  end
  
  def test_argument_error_pg_led_gt_1
    args_hash = {}
    args_hash["pg_led"] = 1.1
    _test_error(osm_geo_beds_loc, args_hash)
  end
  
  def test_argument_error_pg_lfl_lt_0
    args_hash = {}
    args_hash["pg_lfl"] = -1.0
    _test_error(osm_geo_beds_loc, args_hash)
  end
  
  def test_argument_error_pg_lfl_gt_1
    args_hash = {}
    args_hash["pg_lfl"] = 1.1
    _test_error(osm_geo_beds_loc, args_hash)
  end

  def test_argument_error_in_eff_0
    args_hash = {}
    args_hash["in_eff"] = 0
    _test_error(osm_geo_beds_loc, args_hash)
  end

  def test_argument_error_cfl_eff_0
    args_hash = {}
    args_hash["cfl_eff"] = 0
    _test_error(osm_geo_beds_loc, args_hash)
  end

  def test_argument_error_led_eff_0
    args_hash = {}
    args_hash["led_eff"] = 0
    _test_error(osm_geo_beds_loc, args_hash)
  end

  def test_argument_error_lfl_eff_0
    args_hash = {}
    args_hash["lfl_eff"] = 0
    _test_error(osm_geo_beds_loc, args_hash)
  end
  
  def test_argument_error_hw_gt_1
    args_hash = {}
    args_hash["hw_cfl"] = 0.4
    args_hash["hw_lfl"] = 0.4
    args_hash["hw_led"] = 0.4
    _test_error(osm_geo_beds_loc, args_hash)  
  end
  
  def test_argument_error_pg_gt_1
    args_hash = {}
    args_hash["pg_cfl"] = 0.4
    args_hash["pg_lfl"] = 0.4
    args_hash["pg_led"] = 0.4
    _test_error(osm_geo_beds_loc, args_hash)  
  end

  def test_error_missing_geometry
    args_hash = {}
    _test_error(nil, args_hash)
  end
  
  def test_error_missing_beds
    args_hash = {}
    _test_error(osm_geo, args_hash)
  end
    
  def test_error_missing_location
    args_hash = {}
    _test_error(osm_geo_beds, args_hash)
  end

  private
  
  def _test_error(osm_file, args_hash)
    # create an instance of the measure
    measure = ResidentialLighting.new

    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new

    model = _get_model(osm_file)

    # get arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Ruleset.convertOSArgumentVectorToMap(arguments)

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args_hash[arg.name]
        assert(temp_arg_var.setValue(args_hash[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end

    # run the measure
    measure.run(model, runner, argument_map)
    result = runner.result

    # show the output
    #show_output(result)

    # assert that it didn't run
    assert_equal("Fail", result.value.valueName)
    assert(result.errors.size == 1)
  end

  def _test_measure(osm_file_or_model, args_hash, expected_num_del_objects=0, expected_num_new_objects=0, expected_annual_kwh=0.0)
    # create an instance of the measure
    measure = ResidentialLighting.new

    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new
    
    model = _get_model(osm_file_or_model)

    # store the original lights in the seed model
    orig_lights = model.getLightss + model.getExteriorLightss

    # get arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Ruleset.convertOSArgumentVectorToMap(arguments)

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args_hash[arg.name]
        assert(temp_arg_var.setValue(args_hash[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end

    # run the measure
    measure.run(model, runner, argument_map)
    result = runner.result

    # show the output
    #show_output(result)

    # assert that it ran correctly
    assert_equal("Success", result.value.valueName)
    if expected_num_del_objects > 0
        assert(result.info.size == 1)
    else
        assert(result.info.size == 0)
    end
    assert(result.warnings.size == 0)
    
    # get new/deleted light objects
    new_objects = []
    (model.getLightss + model.getExteriorLightss).each do |li|
        next if orig_lights.include?(li)
        new_objects << li
    end
    del_objects = []
    orig_lights.each do |li|
        next if model.getLightss.include?(li) or model.getExteriorLightss.include?(li)
        del_objects << li
    end
    
    # check for num new/del objects
    assert_equal(expected_num_del_objects, del_objects.size)
    assert_equal(expected_num_new_objects, new_objects.size)
    
    actual_annual_kwh = 0.0
    new_objects.each do |new_object|
        # check that the new object has the correct name
        assert(new_object.name.to_s.start_with?(Constants.ObjectNameLighting))
        
        # check for the correct annual energy consumption
        full_load_hrs = Schedule.annual_equivalent_full_load_hrs(model, new_object.schedule.get)
        if new_object.is_a?(OpenStudio::Model::Lights)
            actual_annual_kwh += OpenStudio.convert(full_load_hrs * new_object.lightingLevel.get * new_object.multiplier, "Wh", "kWh").get
        elsif new_object.is_a?(OpenStudio::Model::ExteriorLights)
            actual_annual_kwh += OpenStudio.convert(full_load_hrs * new_object.exteriorLightsDefinition.designLevel * new_object.multiplier, "Wh", "kWh").get
        end
    end
    assert_in_epsilon(expected_annual_kwh, actual_annual_kwh, 0.01)
    
    del_objects.each do |del_object|
        # check that the del object had the correct name
        assert(del_object.name.to_s.start_with?(Constants.ObjectNameLighting))
    end

    return model
  end
  
  def _get_model(osm_file_or_model)
    if osm_file_or_model.is_a?(OpenStudio::Model::Model)
        # nothing to do
        model = osm_file_or_model
    elsif osm_file_or_model.nil?
        # make an empty model
        model = OpenStudio::Model::Model.new
    else
        # load the test model
        translator = OpenStudio::OSVersion::VersionTranslator.new
        path = OpenStudio::Path.new(File.join(File.dirname(__FILE__), osm_file_or_model))
        model = translator.loadModel(path)
        assert((not model.empty?))
        model = model.get
    end
    return model
  end

end
