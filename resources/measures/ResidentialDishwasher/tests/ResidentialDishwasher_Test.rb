require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class ResidentialDishwasherTest < MiniTest::Test

  def test_new_construction_none
    # Using energy multiplier
    args_hash = {}
    args_hash["mult_e"] = 0.0
    args_hash["mult_hw"] = 0.0
    _test_measure("2000sqft_2story_FB_GRG_UA_3Beds_2Baths_Denver_ElecWH.osm", args_hash)
  end
  
  def test_new_construction_318_rated_kwh
    args_hash = {}
    args_hash["num_settings"] = 8
    args_hash["dw_E"] = 318
    args_hash["eg_gas_cost"] = 24
    _test_measure("2000sqft_2story_FB_GRG_UA_3Beds_2Baths_Denver_ElecWH.osm", args_hash, 0, 1, 111, 3.1)
  end
  
  def test_new_construction_290_rated_kwh
    args_hash = {}
    args_hash["num_settings"] = 12
    args_hash["dw_E"] = 290
    args_hash["eg_gas_cost"] = 23
    _test_measure("2000sqft_2story_FB_GRG_UA_3Beds_2Baths_Denver_ElecWH.osm", args_hash, 0, 1, 83.1, 1.7)
  end
  
  def test_new_construction_318_rated_kwh_mult_0_80
    args_hash = {}
    args_hash["num_settings"] = 8
    args_hash["dw_E"] = 318
    args_hash["eg_gas_cost"] = 24
    args_hash["mult_e"] = 0.8
    args_hash["mult_hw"] = 0.8
    _test_measure("2000sqft_2story_FB_GRG_UA_3Beds_2Baths_Denver_ElecWH.osm", args_hash, 0, 1, 88.8, 2.5)
  end
  
  def test_new_construction_basement
    args_hash = {}
    args_hash["num_settings"] = 8
    args_hash["dw_E"] = 318
    args_hash["eg_gas_cost"] = 24
    args_hash["space"] = Constants.FinishedBasementSpace
    _test_measure("2000sqft_2story_FB_GRG_UA_3Beds_2Baths_Denver_ElecWH.osm", args_hash, 0, 1, 111, 3.1)
  end

  def test_retrofit_replace
    args_hash = {}
    args_hash["num_settings"] = 8
    args_hash["dw_E"] = 318
    args_hash["eg_gas_cost"] = 24
    model = _test_measure("2000sqft_2story_FB_GRG_UA_3Beds_2Baths_Denver_ElecWH.osm", args_hash, 0, 1, 111, 3.1)
    args_hash = {}
    args_hash["num_settings"] = 12
    args_hash["dw_E"] = 290
    args_hash["eg_gas_cost"] = 23
    _test_measure(model, args_hash, 1, 1, 83.1, 1.7)
  end
    
  def test_retrofit_remove
    args_hash = {}
    args_hash["num_settings"] = 8
    args_hash["dw_E"] = 318
    args_hash["eg_gas_cost"] = 24
    model = _test_measure("2000sqft_2story_FB_GRG_UA_3Beds_2Baths_Denver_ElecWH.osm", args_hash, 0, 1, 111, 3.1)
    args_hash = {}
    args_hash["mult_e"] = 0.0
    args_hash["mult_hw"] = 0.0
    _test_measure(model, args_hash, 1, 0)
  end
  
  def test_argument_error_num_settings_negative
    args_hash = {}
    args_hash["num_settings"] = -1
    _test_error("2000sqft_2story_FB_GRG_UA_3Beds_2Baths_Denver_ElecWH.osm", args_hash)
  end
  
  def test_argument_error_num_settings_zero
    args_hash = {}
    args_hash["num_settings"] = 0
    _test_error("2000sqft_2story_FB_GRG_UA_3Beds_2Baths_Denver_ElecWH.osm", args_hash)
  end

  def test_argument_error_dw_E_negative
    args_hash = {}
    args_hash["dw_E"] = -1.0
    _test_error("2000sqft_2story_FB_GRG_UA_3Beds_2Baths_Denver_ElecWH.osm", args_hash)
  end
  
  def test_argument_error_cold_use_negative
    args_hash = {}
    args_hash["cold_use"] = -1.0
    _test_error("2000sqft_2story_FB_GRG_UA_3Beds_2Baths_Denver_ElecWH.osm", args_hash)
  end

  def test_argument_error_eg_date_negative
    args_hash = {}
    args_hash["eg_date"] = -1
    _test_error("2000sqft_2story_FB_GRG_UA_3Beds_2Baths_Denver_ElecWH.osm", args_hash)
  end

  def test_argument_error_eg_date_zero
    args_hash = {}
    args_hash["eg_date"] = 0
    _test_error("2000sqft_2story_FB_GRG_UA_3Beds_2Baths_Denver_ElecWH.osm", args_hash)
  end

  def test_argument_error_eg_gas_cost_negative
    args_hash = {}
    args_hash["eg_gas_cost"] = -1
    _test_error("2000sqft_2story_FB_GRG_UA_3Beds_2Baths_Denver_ElecWH.osm", args_hash)
  end

  def test_argument_error_eg_gas_cost_zero
    args_hash = {}
    args_hash["eg_gas_cost"] = 0
    _test_error("2000sqft_2story_FB_GRG_UA_3Beds_2Baths_Denver_ElecWH.osm", args_hash)
  end

  def test_argument_error_mult_e_negative
    args_hash = {}
    args_hash["mult_e"] = -1
    _test_error("2000sqft_2story_FB_GRG_UA_3Beds_2Baths_Denver_ElecWH.osm", args_hash)
  end

  def test_argument_error_mult_hw_negative
    args_hash = {}
    args_hash["mult_hw"] = -1
    _test_error("2000sqft_2story_FB_GRG_UA_3Beds_2Baths_Denver_ElecWH.osm", args_hash)
  end

  def test_error_missing_geometry
    args_hash = {}
    _test_error(nil, args_hash)
  end
  
  def test_error_missing_water_heater
    args_hash = {}
    _test_error("2000sqft_2story_FB_GRG_UA.osm", args_hash)
  end

  private
  
  def _test_error(osm_file, args_hash)
    # create an instance of the measure
    measure = ResidentialDishwasher.new

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

  def _test_measure(osm_file_or_model, args_hash, expected_num_del_objects=0, expected_num_new_objects=0, expected_annual_kwh=0.0, expected_hw_gpd=0.0)
    # create an instance of the measure
    measure = ResidentialDishwasher.new

    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new
    
    model = _get_model(osm_file_or_model)

    # store the original equipment in the seed model
    orig_equip = model.getElectricEquipments

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
    
    # get new/deleted electric equipment objects
    new_objects = []
    model.getElectricEquipments.each do |ee|
        next if orig_equip.include?(ee)
        new_objects << ee
    end
    del_objects = []
    orig_equip.each do |ee|
        next if model.getElectricEquipments.include?(ee)
        del_objects << ee
    end
    
    # check for num new/del objects
    assert_equal(expected_num_del_objects, del_objects.size)
    assert_equal(expected_num_new_objects, new_objects.size)
    
    actual_annual_kwh = 0.0
    new_objects.each do |new_object|
        # check that the new object has the correct name
        assert_equal(new_object.name.to_s, Constants.ObjectNameDishwasher)
        
        # check new object is in correct space
        if argument_map["space"].hasValue
            assert_equal(new_object.space.get.name.to_s, argument_map["space"].valueAsString)
        else
            assert_equal(new_object.space.get.name.to_s, argument_map["space"].defaultValueAsString)
        end
        
        # check for the correct annual energy consumption
        full_load_hrs = Schedule.annual_equivalent_full_load_hrs(model, new_object.schedule.get)
        actual_annual_kwh += OpenStudio.convert(full_load_hrs * new_object.designLevel.get * new_object.multiplier, "Wh", "kWh").get
    end
    assert_in_epsilon(expected_annual_kwh, actual_annual_kwh, 0.01)

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
