require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class ResidentialDishwasherTest < MiniTest::Test

  def osm_geo
    return "2000sqft_2story_FB_GRG_UA.osm"
  end

  def osm_geo_beds_loc_tankwh
    return "2000sqft_2story_FB_GRG_UA_3Beds_2Baths_Denver_ElecWHtank.osm"
  end

  def osm_geo_beds_loc_tanklesswh
    return "2000sqft_2story_FB_GRG_UA_3Beds_2Baths_Denver_ElecWHtankless.osm"
  end
  
  def test_new_construction_none
    # Using energy multiplier
    args_hash = {}
    args_hash["mult_e"] = 0.0
    args_hash["mult_hw"] = 0.0
    _test_measure(osm_geo_beds_loc_tankwh, args_hash)
  end
  
  def test_new_construction_318_rated_kwh
    args_hash = {}
    args_hash["num_settings"] = 8
    args_hash["dw_E"] = 318
    args_hash["eg_gas_cost"] = 24
    _test_measure(osm_geo_beds_loc_tankwh, args_hash, 0, 2, 111, 3.10)
  end
  
  def test_new_construction_290_rated_kwh
    args_hash = {}
    args_hash["num_settings"] = 12
    args_hash["dw_E"] = 290
    args_hash["eg_gas_cost"] = 23
    _test_measure(osm_geo_beds_loc_tankwh, args_hash, 0, 2, 83.1, 1.65)
  end
  
  def test_new_construction_318_rated_kwh_mult_0_80
    args_hash = {}
    args_hash["num_settings"] = 8
    args_hash["dw_E"] = 318
    args_hash["eg_gas_cost"] = 24
    args_hash["mult_e"] = 0.8
    args_hash["mult_hw"] = 0.8
    _test_measure(osm_geo_beds_loc_tankwh, args_hash, 0, 2, 88.8, 2.48)
  end
  
  def test_new_construction_318_rated_kwh_cold_inlet
    args_hash = {}
    args_hash["num_settings"] = 8
    args_hash["dw_E"] = 318
    args_hash["eg_gas_cost"] = 24
    args_hash["cold_inlet"] = "true"
    args_hash["cold_use"] = 3.5
    _test_measure(osm_geo_beds_loc_tankwh, args_hash, 0, 2, 303.8, 5.0)
  end

  def test_new_construction_318_rated_kwh_cold_inlet_tankless
    args_hash = {}
    args_hash["num_settings"] = 8
    args_hash["dw_E"] = 318
    args_hash["eg_gas_cost"] = 24
    args_hash["cold_inlet"] = "true"
    args_hash["cold_use"] = 3.5
    _test_measure(osm_geo_beds_loc_tanklesswh, args_hash, 0, 2, 303.8, 5.0)
  end

  def test_new_construction_318_rated_kwh_no_int_heater
    args_hash = {}
    args_hash["num_settings"] = 8
    args_hash["dw_E"] = 318
    args_hash["eg_gas_cost"] = 24
    args_hash["int_htr"] = "false"
    _test_measure(osm_geo_beds_loc_tankwh, args_hash, 0, 2, 124.8, 2.41)
  end

  def test_new_construction_basement
    args_hash = {}
    args_hash["num_settings"] = 8
    args_hash["dw_E"] = 318
    args_hash["eg_gas_cost"] = 24
    args_hash["space"] = Constants.FinishedBasementSpace
    _test_measure(osm_geo_beds_loc_tankwh, args_hash, 0, 2, 111, 3.10)
  end

  def test_retrofit_replace
    args_hash = {}
    args_hash["num_settings"] = 8
    args_hash["dw_E"] = 318
    args_hash["eg_gas_cost"] = 24
    model = _test_measure(osm_geo_beds_loc_tankwh, args_hash, 0, 2, 111, 3.10)
    args_hash = {}
    args_hash["num_settings"] = 12
    args_hash["dw_E"] = 290
    args_hash["eg_gas_cost"] = 23
    _test_measure(model, args_hash, 2, 2, 83.1, 1.65)
  end
    
  def test_retrofit_remove
    args_hash = {}
    args_hash["num_settings"] = 8
    args_hash["dw_E"] = 318
    args_hash["eg_gas_cost"] = 24
    model = _test_measure(osm_geo_beds_loc_tankwh, args_hash, 0, 2, 111, 3.10)
    args_hash = {}
    args_hash["mult_e"] = 0.0
    args_hash["mult_hw"] = 0.0
    _test_measure(model, args_hash, 2, 0)
  end
  
  def test_argument_error_num_settings_negative
    args_hash = {}
    args_hash["num_settings"] = -1
    _test_error(osm_geo_beds_loc_tankwh, args_hash)
  end
  
  def test_argument_error_num_settings_zero
    args_hash = {}
    args_hash["num_settings"] = 0
    _test_error(osm_geo_beds_loc_tankwh, args_hash)
  end

  def test_argument_error_dw_E_negative
    args_hash = {}
    args_hash["dw_E"] = -1.0
    _test_error(osm_geo_beds_loc_tankwh, args_hash)
  end
  
  def test_argument_error_cold_use_negative
    args_hash = {}
    args_hash["cold_use"] = -1.0
    _test_error(osm_geo_beds_loc_tankwh, args_hash)
  end

  def test_argument_error_eg_date_negative
    args_hash = {}
    args_hash["eg_date"] = -1
    _test_error(osm_geo_beds_loc_tankwh, args_hash)
  end

  def test_argument_error_eg_date_zero
    args_hash = {}
    args_hash["eg_date"] = 0
    _test_error(osm_geo_beds_loc_tankwh, args_hash)
  end

  def test_argument_error_eg_gas_cost_negative
    args_hash = {}
    args_hash["eg_gas_cost"] = -1
    _test_error(osm_geo_beds_loc_tankwh, args_hash)
  end

  def test_argument_error_eg_gas_cost_zero
    args_hash = {}
    args_hash["eg_gas_cost"] = 0
    _test_error(osm_geo_beds_loc_tankwh, args_hash)
  end

  def test_argument_error_mult_e_negative
    args_hash = {}
    args_hash["mult_e"] = -1
    _test_error(osm_geo_beds_loc_tankwh, args_hash)
  end

  def test_argument_error_mult_hw_negative
    args_hash = {}
    args_hash["mult_hw"] = -1
    _test_error(osm_geo_beds_loc_tankwh, args_hash)
  end

  def test_error_missing_geometry
    args_hash = {}
    _test_error(nil, args_hash)
  end
  
  def test_error_missing_water_heater
    args_hash = {}
    _test_error(osm_geo, args_hash)
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
    orig_equip = model.getElectricEquipments + model.getWaterUseEquipments

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
    (model.getElectricEquipments + model.getWaterUseEquipments).each do |equip|
        next if orig_equip.include?(equip)
        new_objects << equip
    end
    del_objects = []
    orig_equip.each do |equip|
        next if (model.getElectricEquipments + model.getWaterUseEquipments).include?(equip)
        del_objects << equip
    end
    
    # check for num new/del objects
    assert_equal(expected_num_del_objects, del_objects.size)
    assert_equal(expected_num_new_objects, new_objects.size)
    
    new_objects.each do |new_object|
        # check that the new object has the correct name
        assert_equal(new_object.name.to_s, Constants.ObjectNameDishwasher)
    
        # check new object is in correct space
        if argument_map["space"].hasValue
            assert_equal(new_object.space.get.name.to_s, argument_map["space"].valueAsString)
        else
            assert_equal(new_object.space.get.name.to_s, argument_map["space"].defaultValueAsString)
        end
        
        if new_object.is_a?(OpenStudio::Model::ElectricEquipment)
            # check for the correct annual energy consumption
            full_load_hrs = Schedule.annual_equivalent_full_load_hrs(model, new_object.schedule.get)
            actual_annual_kwh = OpenStudio.convert(full_load_hrs * new_object.designLevel.get * new_object.multiplier, "Wh", "kWh").get
            assert_in_epsilon(expected_annual_kwh, actual_annual_kwh, 0.01)
        elsif new_object.is_a?(OpenStudio::Model::WaterUseEquipment)
            # check for the correct daily hot water consumption
            full_load_hrs = Schedule.annual_equivalent_full_load_hrs(model, new_object.flowRateFractionSchedule.get)
            actual_hw_gpd = OpenStudio.convert(full_load_hrs * new_object.waterUseEquipmentDefinition.peakFlowRate * new_object.multiplier, "m^3/s", "gal/min").get * 60.0 / 365.0
            assert_in_epsilon(expected_hw_gpd, actual_hw_gpd, 0.02)
        end
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
