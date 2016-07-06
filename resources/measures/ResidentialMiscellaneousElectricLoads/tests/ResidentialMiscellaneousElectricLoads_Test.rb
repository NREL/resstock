require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class ResidentialMiscellaneousElectricLoadsTest < MiniTest::Test

  def test_new_construction_none
    # Using energy multiplier
    args_hash = {}
    args_hash["mult"] = 0.0
    _test_measure("2000sqft_2story_FB_GRG_UA_3Beds_2Baths.osm", args_hash)
  end
  
  def test_new_construction_mult_1_0
    args_hash = {}
    args_hash["mult"] = 1.0
    _test_measure("2000sqft_2story_FB_GRG_UA_3Beds_2Baths.osm", args_hash, 0, 3, _calc_energy(1.0, 3, 2000))
  end
  
  def test_new_construction_mult_1_5
    args_hash = {}
    args_hash["mult"] = 1.5
    _test_measure("2000sqft_2story_FB_GRG_UA_3Beds_2Baths.osm", args_hash, 0, 3, _calc_energy(1.5, 3, 2000))
  end
  
  def test_new_construction_modified_schedule
    args_hash = {}
    args_hash["weekday_sch"] = "1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24"
    args_hash["weekend_sch"] = "1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24"
    args_hash["monthly_sch"] = "1,2,3,4,5,6,7,8,9,10,11,12"
    _test_measure("2000sqft_2story_FB_GRG_UA_3Beds_2Baths.osm", args_hash, 0, 3, _calc_energy(1.0, 3, 2000))
  end

  def test_retrofit_replace
    args_hash = {}
    model = _test_measure("2000sqft_2story_FB_GRG_UA_3Beds_2Baths.osm", args_hash, 0, 3, _calc_energy(1.0, 3, 2000))
    args_hash = {}
    args_hash["mult"] = 0.5
    _test_measure(model, args_hash, 3, 3, _calc_energy(0.5, 3, 2000))
  end
    
  def test_retrofit_remove
    args_hash = {}
    model = _test_measure("2000sqft_2story_FB_GRG_UA_3Beds_2Baths.osm", args_hash, 0, 3, _calc_energy(1.0, 3, 2000))
    args_hash = {}
    args_hash["mult"] = 0.0
    _test_measure(model, args_hash, 3, 0)
  end
  
  def test_argument_error_mult_negative
    args_hash = {}
    args_hash["mult"] = -1.0
    _test_error("2000sqft_2story_FB_GRG_UA_3Beds_2Baths.osm", args_hash)
  end
  
  def test_argument_error_weekday_sch_wrong_number_of_values
    args_hash = {}
    args_hash["weekday_sch"] = "1,1"
    _test_error("2000sqft_2story_FB_GRG_UA_3Beds_2Baths.osm", args_hash)
  end
  
  def test_argument_error_weekday_sch_not_number
    args_hash = {}
    args_hash["weekday_sch"] = "str,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1"
    _test_error("2000sqft_2story_FB_GRG_UA_3Beds_2Baths.osm", args_hash)
  end
    
  def test_argument_error_weekend_sch_wrong_number_of_values
    args_hash = {}
    args_hash["weekend_sch"] = "1,1"
    _test_error("2000sqft_2story_FB_GRG_UA_3Beds_2Baths.osm", args_hash)
  end
    
  def test_argument_error_weekend_sch_not_number
    args_hash = {}
    args_hash["weekend_sch"] = "str,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1"
    _test_error("2000sqft_2story_FB_GRG_UA_3Beds_2Baths.osm", args_hash)
  end
  
  def test_argument_error_monthly_sch_wrong_number_of_values  
    args_hash = {}
    args_hash["monthly_sch"] = "1,1"
    _test_error("2000sqft_2story_FB_GRG_UA_3Beds_2Baths.osm", args_hash)
  end
  
  def test_argument_error_monthly_sch_not_number
    args_hash = {}
    args_hash["monthly_sch"] = "str,1,1,1,1,1,1,1,1,1,1,1"
    _test_error("2000sqft_2story_FB_GRG_UA_3Beds_2Baths.osm", args_hash)
  end
  
  def test_error_missing_beds
    args_hash = {}
    _test_error("2000sqft_2story_FB_GRG_UA.osm", args_hash)
  end
    
  def test_error_missing_geometry
    args_hash = {}
    _test_error(nil, args_hash)
  end

  private
  
  def _calc_energy(multiplier, nbr, ffa)
    return (1108.1 + 180.2 * nbr + 0.2785 * ffa) * multiplier
  end
  
  def _test_error(osm_file, args_hash)
    # create an instance of the measure
    measure = ResidentialMiscellaneousElectricLoads.new

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
    measure = ResidentialMiscellaneousElectricLoads.new

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
        assert(new_object.name.to_s.start_with?(Constants.ObjectNameMiscPlugLoads))
        
        # check for the correct annual energy consumption
        full_load_hrs = Schedule.annual_equivalent_full_load_hrs(model, new_object.schedule.get)
        actual_annual_kwh += OpenStudio.convert(full_load_hrs * new_object.designLevel.get * new_object.multiplier, "Wh", "kWh").get
    end
    assert_in_epsilon(expected_annual_kwh, actual_annual_kwh, 0.01)
    
    del_objects.each do |del_object|
        # check that the del object had the correct name
        assert(del_object.name.to_s.start_with?(Constants.ObjectNameMiscPlugLoads))
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
