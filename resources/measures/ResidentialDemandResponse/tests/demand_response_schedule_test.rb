require_relative '../../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class DemandResponseScheduleTest < MiniTest::Test
  def test_error_invalid_DR_schedule
	args_hash = {}
	args_hash["offset_magnitude_heat"] = 4
	args_hash["dr_directory"] = "./tests"
	args_hash["dr_schedule_heat"] = "DR_schedule_invalid.csv"	
	result = _test_error("SFD_2000sqft_2story_CS_UA_3Beds_2Baths_Denver_Furnace_CentralAC.osm", args_hash)
	assert_includes(result.errors.map { |x| x.logMessage }, "The DR schedule must have values of -1, 0, or 1.")
  end  
  
  def test_error_no_DR_schedule
	args_hash = {}
	args_hash["offset_magnitude_heat"] = 4
	args_hash["dr_directory"] = "./tests"
	args_hash["dr_schedule_heat"] = "doesnt_exist.csv"
    result = _test_error("SFD_2000sqft_2story_CS_UA_3Beds_2Baths_Denver_Furnace_CentralAC.osm", args_hash)
	assert_includes(result.errors.map { |x| x.logMessage }, "File doesnt_exist.csv does not exist")
  end
  
  def test_error_wrong_DR_schedule_length
  #8760 or 8784 schedules
    args_hash = {}
	args_hash["offset_magnitude_heat"] = 4
	args_hash["dr_directory"] = "./tests"
	args_hash["dr_schedule_heat"] = "DR_schedule_wrong_number.csv"
	result = _test_error("SFD_2000sqft_2story_CS_UA_3Beds_2Baths_Denver_Furnace_CentralAC.osm", args_hash)
	assert_includes(result.errors.map { |x| x.logMessage }, "DR schedule is too long")
  end
  
  def test_no_offset
    args_hash = {}
    args_hash["offset_magnitude_heat"] = 0
    args_hash["offset_magnitude_cool"] = 0
	expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = {}
    _test_measure("SFD_2000sqft_2story_CS_UA_3Beds_2Baths_Denver_Furnace_CentralAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1)
  end
  	
  def test_normal_tsp
    args_hash = {}
	args_hash["offset_magnitude_heat"] = 4
    args_hash["offset_magnitude_cool"] = 3
    args_hash["dr_directory"] = "./tests"
	args_hash["dr_schedule_heat"] = "DR_schedule_h.csv"
    args_hash["dr_schedule_cool"] = "DR_schedule_c.csv"
    expected_num_new_objects = { "ScheduleFixedInterval" => 4}  # DR sched 2x, heat TSP, cool TSP
    expected_num_del_objects = {"ScheduleRuleset" => 2, "ScheduleRule" => 24} 
    expected_values = {"heat_tsp_non_dr" => 70,
                       "heat_tsp_dr_plus" => 74,
                       "heat_tsp_dr_minus" => 66,
                       "cool_tsp_non_dr" => 75,
                       "cool_tsp_dr_plus" => 78,
                       "cool_tsp_dr_minus" => 72}
    _test_measure("SFD_70heat_75cool_12mo_seasons.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 6)
    #6 assertions: 2 DR sched found, 2 Thermostat found, 2 setting thermostat
  end
  
  def test_overlap_offset
    args_hash = {}
	args_hash["offset_magnitude_heat"] = 4
    args_hash["offset_magnitude_cool"] = 4
    args_hash["dr_directory"] = "./tests"
	args_hash["dr_schedule_heat"] = "DR_schedule_overlap.csv"
    args_hash["dr_schedule_cool"] = "DR_schedule_overlap.csv"
    expected_num_new_objects = { "ScheduleFixedInterval" => 4}  # DR sched 2x, heat TSP, cool TSP
    expected_num_del_objects = {"ScheduleRuleset" => 2, "ScheduleRule" => 24} 
    expected_values = {"heat_tsp_non_dr" => 70,
                       "heat_tsp_dr_plus" => 74,
                       "heat_tsp_dr_minus" => 66,
                       "cool_tsp_non_dr" => 75,
                       "cool_tsp_dr_plus" => 79,
                       "cool_tsp_dr_minus" => 71}
    _test_measure("SFD_70heat_75cool_12mo_seasons.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 6)
    #6 assertions: 2 DR sched found, 2 Thermostat found, 2 setting thermostat
  end
  
  def test_inverted_tsp
    args_hash = {}
	args_hash["offset_magnitude_heat"] = 4
    args_hash["offset_magnitude_cool"] = 4
    args_hash["dr_directory"] = "./tests"
	args_hash["dr_schedule_heat"] = "DR_schedule_h.csv"
    args_hash["dr_schedule_cool"] = "DR_schedule_c.csv"
    expected_num_new_objects = {"ScheduleFixedInterval" => 4}  # DR sched 2x, heat TSP, cool TSP
    expected_num_del_objects = {"ScheduleRuleset" => 2, "ScheduleRule" => 24} 
    expected_values = {"heat_tsp_non_dr" => 69,
                       "heat_tsp_dr_plus" => 71,
                       "heat_tsp_dr_minus" => 66,
                       "cool_tsp_non_dr" => 69,
                       "cool_tsp_dr_plus" => 72,
                       "cool_tsp_dr_minus" => 67}
    _test_measure("SFD_70heat_68cool_12mo_seasons.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 6)
  end
  
  def test_inverted_tsp_auto_season
    args_hash = {}
	args_hash["offset_magnitude_heat"] = 4
    args_hash["offset_magnitude_cool"] = 4
    args_hash["dr_directory"] = "./tests"
	args_hash["dr_schedule_heat"] = "DR_schedule_h.csv"
    args_hash["dr_schedule_cool"] = "DR_schedule_c.csv"
    expected_num_new_objects = {"ScheduleFixedInterval" => 4}  # DR sched 2x, heat TSP, cool TSP
    expected_num_del_objects = {"ScheduleRuleset" => 2, "ScheduleRule" => 24} 
    expected_values = {"heat_tsp_non_dr" => 70,
                       "heat_tsp_dr_plus" => 74,
                       "heat_tsp_dr_minus" => 66,
                       "cool_tsp_non_dr" => 70,
                       "cool_tsp_dr_plus" => 72,
                       "cool_tsp_dr_minus" => 70}
    _test_measure("SFD_70heat_68cool_auto_seasons.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 6)
  end
  
  
  #Test that the cooling setpoint is not averaged with heating (it does currently)
  def test_no_cooling_eqpt
    args_hash = {}
	args_hash["offset_magnitude_heat"] = 4
    args_hash["offset_magnitude_cool"] = 3
    args_hash["dr_directory"] = "./tests"
	args_hash["dr_schedule_heat"] = "DR_schedule_h.csv"
    args_hash["dr_schedule_cool"] = "DR_schedule_c.csv"
    expected_num_new_objects = { "ScheduleFixedInterval" => 4}  # DR sched 2x, heat TSP, cool TSP
    expected_num_del_objects = {"ScheduleRuleset" => 2, "ScheduleRule" => 24} 
    expected_values = {"heat_tsp_non_dr" => 70,
                       "heat_tsp_dr_plus" => 74,
                       "heat_tsp_dr_minus" => 66,
                       "cool_tsp_non_dr" => 75,
                       "cool_tsp_dr_plus" => 78,
                       "cool_tsp_dr_minus" => 72}
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver_Furnace.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 6)
    #6 assertions: 2 DR sched found, 2 Thermostat found, 2 setting thermostat
  end
  
  def test_zero_DR_schedule
	args_hash = {}
	args_hash["offset_magnitude_heat"] = 4
	args_hash["dr_directory"] = "./tests"
	args_hash["dr_schedule_heat"] = "DR_schedule_zeros.csv"
    args_hash["dr_schedule_cool"] = "DR_schedule_zeros.csv"
    expected_num_del_objects = {} #2 cooling sp and heating sp
    expected_num_new_objects = { "ScheduleFixedInterval" => 2}  #DR sched
    expected_values = {}
    _test_measure("SFD_2000sqft_2story_CS_UA_3Beds_2Baths_Denver_Furnace_CentralAC.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 3)
  end
  
  def test_no_thermostat
	args_hash = {}
	args_hash["offset_magnitude"] = 4
	args_hash["dr_directory_heat"] = "./tests"
	args_hash["dr_schedule_heat"] = "DR_schedule_invalid.csv"
    expected_num_del_objects = {}
    expected_num_new_objects = {}  #DR sched
    expected_values = {}
    _test_measure("SFD_2000sqft_2story_SL_UA_3Beds_2Baths_Denver_CentralAC_NoSetpoints.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, 1)
  end  
  
  private

  def _test_error(osm_file_or_model, args_hash)
    # create an instance of the measure
    measure = DemandResponseSchedule.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    model = get_model(File.dirname(__FILE__), osm_file_or_model)

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
    # assert that it didn't run
    assert_equal("Fail", result.value.valueName)
    assert(result.errors.size == 1)

    return result
  end

  def _test_measure(osm_file_or_model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, num_infos = 0, num_warnings = 0, debug = false)
    # create an instance of the measure
    measure = DemandResponseSchedule.new
    
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

    # show_output(result)

    # assert that it ran correctly
    assert_equal("Success", result.value.valueName)
    assert_equal(num_infos, result.info.size)
    assert_equal(num_warnings, result.warnings.size)

    # get the final objects in the model
    final_objects = get_objects(model)

    # get new and deleted objects
    obj_type_exclusions = ["ScheduleDay", "ScheduleTypeLimits"]
    all_new_objects = get_object_additions(initial_objects, final_objects, obj_type_exclusions)
    all_del_objects = get_object_additions(final_objects, initial_objects, obj_type_exclusions)

    # check we have the expected number of new/deleted objects
    check_num_objects(all_new_objects, expected_num_new_objects, "added")
    check_num_objects(all_del_objects, expected_num_del_objects, "deleted")

    no_dr = 0
    if args_hash["dr_schedule_heat"] == "DR_schedule_h.csv"
      ht_dr_plus = 1
      ht_dr_minus = 2
    end    
    if args_hash["dr_schedule_cool"] == "DR_schedule_c.csv"
      cl_dr_plus = 3
      cl_dr_minus = 4
    end
    if args_hash["dr_schedule_heat"] == "DR_schedule_overlap.csv"
      ht_dr_plus = 1
      ht_dr_minus = 2
    end
    if args_hash["dr_schedule_cool"] == "DR_schedule_overlap.csv"
      cl_dr_plus = 1
      cl_dr_minus = 2
    end    
    
    all_new_objects.each do |obj_type, new_objects|
      new_objects.each do |new_object|
        next if not new_object.respond_to?("to_#{obj_type}")
             
        #Obj type == ScheduleFixedInterval
        if new_object.name.get == "HeatingTSP"
          assert_in_epsilon(expected_values["heat_tsp_non_dr"], UnitConversions.convert(new_object.to_ScheduleFixedInterval.get.timeSeries.values[no_dr], "C", "F"), 0.01)
          assert_in_epsilon(expected_values["heat_tsp_dr_plus"], UnitConversions.convert(new_object.to_ScheduleFixedInterval.get.timeSeries.values[ht_dr_plus], "C", "F"), 0.01)
          assert_in_epsilon(expected_values["heat_tsp_dr_minus"], UnitConversions.convert(new_object.to_ScheduleFixedInterval.get.timeSeries.values[ht_dr_minus], "C", "F"), 0.01)
        elsif new_object.name.get == "CoolingTSP"
          assert_in_epsilon(expected_values["cool_tsp_non_dr"], UnitConversions.convert(new_object.to_ScheduleFixedInterval.get.timeSeries.values[no_dr], "C", "F"), 0.01)     
          assert_in_epsilon(expected_values["cool_tsp_dr_plus"], UnitConversions.convert(new_object.to_ScheduleFixedInterval.get.timeSeries.values[cl_dr_plus], "C", "F"), 0.01)
          assert_in_epsilon(expected_values["cool_tsp_dr_minus"], UnitConversions.convert(new_object.to_ScheduleFixedInterval.get.timeSeries.values[cl_dr_minus], "C", "F"), 0.01)
        end
        
      end
    end

    return model
  end
end
