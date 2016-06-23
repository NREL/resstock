require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class NewMeasureTest < MiniTest::Test

  def test_new_construction_none1
    # Using rated annual consumption
    args_hash = {}
    args_hash["fridge_E"] = 0.0
    _test_new_construction("2000sqft_2story_FB_GRG_UA.osm", args_hash, false)
  end
  
  def test_new_construction_none2
    # Using energy multiplier
    args_hash = {}
    args_hash["mult"] = 0.0
    _test_new_construction("2000sqft_2story_FB_GRG_UA.osm", args_hash, false)
  end
  
  def test_new_construction_ef_17_6
    args_hash = {}
    args_hash["fridge_E"] = 434.0
    _test_new_construction("2000sqft_2story_FB_GRG_UA.osm", args_hash, true, 434.0)
  end
  
  def test_new_construction_mult_0_95
    args_hash = {}
    args_hash["fridge_E"] = 434.0
    args_hash["mult"] = 0.95
    _test_new_construction("2000sqft_2story_FB_GRG_UA.osm", args_hash, true, 412.3)
  end
  
  def test_new_construction_mult_1_05
    args_hash = {}
    args_hash["fridge_E"] = 434.0
    args_hash["mult"] = 1.05
    _test_new_construction("2000sqft_2story_FB_GRG_UA.osm", args_hash, true, 455.7)
  end
  
  def test_new_construction_modified_schedule
    args_hash = {}
    args_hash["fridge_E"] = 434.0
    args_hash["weekday_sch"] = "1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24"
    args_hash["weekend_sch"] = "1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24"
    args_hash["monthly_sch"] = "1,2,3,4,5,6,7,8,9,10,11,12"
    _test_new_construction("2000sqft_2story_FB_GRG_UA.osm", args_hash, true, 434.0)
  end

  def test_new_construction_basement
    args_hash = {}
    args_hash["fridge_E"] = 434.0
    args_hash["space"] = Constants.FinishedBasementSpace
    _test_new_construction("2000sqft_2story_FB_GRG_UA.osm", args_hash, true, 434.0)
  end

  def test_retrofit_replace
    args_hash = {}
    args_hash["fridge_E"] = 434.0
    model = _test_new_construction("2000sqft_2story_FB_GRG_UA.osm", args_hash, true, 434.0)
    args_hash = {}
    args_hash["fridge_E"] = 348.0
    _test_retrofit(model, args_hash, false, 348.0)
  end
    
  def test_retrofit_remove
    args_hash = {}
    args_hash["fridge_E"] = 434.0
    model = _test_new_construction("2000sqft_2story_FB_GRG_UA.osm", args_hash, true, 434.0)
    args_hash = {}
    args_hash["fridge_E"] = 0.0
    _test_retrofit(model, args_hash, true)
  end
  
  def test_argument_error_fridge_E_negative
    args_hash = {}
    args_hash["fridge_E"] = -1.0
    _test_error("2000sqft_2story_FB_GRG_UA.osm", args_hash)
  end
  
  def test_argument_error_mult_negative
    args_hash = {}
    args_hash["mult"] = -1.0
    _test_error("2000sqft_2story_FB_GRG_UA.osm", args_hash)
  end
  
  def test_argument_error_weekday_sch_wrong_number_of_values
    args_hash = {}
    args_hash["weekday_sch"] = "1,1"
    _test_error("2000sqft_2story_FB_GRG_UA.osm", args_hash)
  end
  
  def test_argument_error_weekday_sch_not_number
    args_hash = {}
    args_hash["weekday_sch"] = "str,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1"
    _test_error("2000sqft_2story_FB_GRG_UA.osm", args_hash)
  end
    
  def test_argument_error_weekend_sch_wrong_number_of_values
    args_hash = {}
    args_hash["weekend_sch"] = "1,1"
    _test_error("2000sqft_2story_FB_GRG_UA.osm", args_hash)
  end
    
  def test_argument_error_weekend_sch_not_number
    args_hash = {}
    args_hash["weekend_sch"] = "str,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1"
    _test_error("2000sqft_2story_FB_GRG_UA.osm", args_hash)
  end
  
  def test_argument_error_monthly_sch_wrong_number_of_values  
    args_hash = {}
    args_hash["monthly_sch"] = "1,1"
    _test_error("2000sqft_2story_FB_GRG_UA.osm", args_hash)
  end
  
  def test_argument_error_monthly_sch_not_number
    args_hash = {}
    args_hash["monthly_sch"] = "str,1,1,1,1,1,1,1,1,1,1,1"
    _test_error("2000sqft_2story_FB_GRG_UA.osm", args_hash)
  end
    
  def test_error_missing_geometry
    args_hash = {}
    _test_error(nil, args_hash)
  end

  private
  
  def _test_error(osm_file, args_hash)
    # create an instance of the measure
    measure = ResidentialRefrigerator.new

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

  def _test_new_construction(osm_file, args_hash, expected_new_object, expected_annual_kwh=nil)
    # create an instance of the measure
    measure = ResidentialRefrigerator.new

    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new

    model = _get_model(osm_file)

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
    assert(result.info.size == 0)
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

    if expected_new_object
        # check that 1 equipment object was created; 0 deleted
        assert_equal(1, new_objects.size)
        assert_equal(0, del_objects.size)
        new_object = new_objects[0]
        
        # check that the new object has the correct name
        assert_equal(new_object.name.to_s, Constants.ObjectNameRefrigerator)
        
        # check new object is in correct space
        if argument_map["space"].hasValue
            assert_equal(new_object.space.get.name.to_s, argument_map["space"].valueAsString)
        else
            assert_equal(new_object.space.get.name.to_s, argument_map["space"].defaultValueAsString)
        end

        # check for the correct annual energy consumption
        full_load_hrs = Schedule.annual_equivalent_full_load_hrs(model, new_object.schedule.get)
        actual_annual_kwh = OpenStudio.convert(full_load_hrs * new_object.designLevel.get * new_object.multiplier, "Wh", "kWh").get
        assert_in_epsilon(expected_annual_kwh, actual_annual_kwh, 0.01)
    else
        # check that no equipment object was deleted or created
        assert_equal(0, new_objects.size)
        assert_equal(0, del_objects.size)
    end
    
    return model
    
  end
  
  def _test_retrofit(model, args_hash, expected_del_object, expected_annual_kwh=nil)
    # create an instance of the measure
    measure = ResidentialRefrigerator.new

    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new

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
    assert(result.info.size == 1)
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
    
    if expected_del_object
        # check that 1 equipment object was deleted; 0 created
        assert_equal(1, del_objects.size)
        assert_equal(0, new_objects.size)
        del_object = del_objects[0]
        
        # check that the deleted object had the correct name
        assert_equal(del_object.name.to_s, Constants.ObjectNameRefrigerator)
    else # replaced object
        # check that 1 equipment object was deleted; 1 created
        assert_equal(1, del_objects.size)
        assert_equal(1, new_objects.size)
        new_object = new_objects[0]
        
        # check that the new object has the correct name
        assert_equal(new_object.name.to_s, Constants.ObjectNameRefrigerator)
        
        # check new object is in correct space
        if argument_map["space"].hasValue
            assert_equal(new_object.space.get.name.to_s, argument_map["space"].valueAsString)
        else
            assert_equal(new_object.space.get.name.to_s, argument_map["space"].defaultValueAsString)
        end
        
        # check for the correct annual energy consumption
        full_load_hrs = Schedule.annual_equivalent_full_load_hrs(model, new_object.schedule.get)
        actual_annual_kwh = OpenStudio.convert(full_load_hrs * new_object.designLevel.get * new_object.multiplier, "Wh", "kWh").get
        assert_in_epsilon(expected_annual_kwh, actual_annual_kwh, 0.01)
    end

  end
  
  def _get_model(osm_file)
    if osm_file.nil?
        # make an empty model
        model = OpenStudio::Model::Model.new
    else
        # load the test model
        translator = OpenStudio::OSVersion::VersionTranslator.new
        path = OpenStudio::Path.new(File.join(File.dirname(__FILE__), osm_file))
        model = translator.loadModel(path)
        assert((not model.empty?))
        model = model.get
    end
    return model
  end

end
