require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class CustomRunPeriodRangeTest < MiniTest::Test
  
  def test_start_date_outside_of_epw_period
    args_hash = {}
    args_hash["run_start_date"] = "December 30 2011"
    result = _test_error("SFD_Successful_EnergyPlus_Run_AMY.osm", args_hash, "0884454_United_States_IL_Cook_17031_725300_41.97_-87.9_NSRDB_2.0.1_2012_AMY.epw")
    assert(result.errors.size == 1)
    assert_equal("Fail", result.value.valueName)
    assert_includes(result.errors.map{ |x| x.logMessage }, "The run period start date is not within the epw data period.")       
  end
  
  def test_end_date_outside_of_epw_period
    args_hash = {}
    args_hash["run_end_date"] = "December 31 2013"
    result = _test_error("SFD_Successful_EnergyPlus_Run_AMY.osm", args_hash, "0884454_United_States_IL_Cook_17031_725300_41.97_-87.9_NSRDB_2.0.1_2012_AMY.epw")
    assert(result.errors.size == 1)
    assert_equal("Fail", result.value.valueName)
    assert_includes(result.errors.map{ |x| x.logMessage }, "The run period end date is not within the epw data period.")       
  end
  
  def test_new_start_date
    args_hash = {}
    args_hash["run_start_date"] = "December 31 2011"
    expected_num_del_objects = {"RunPeriod"=>1}
    expected_num_new_objects = {"RunPeriodCustomRange"=>1}
    expected_values = {"StartMonth"=>"12", "StartDay"=>"31", "StartYear"=>"2011", "EndMonth"=>"12", "EndDay"=>"31", "EndYear"=>"2012"}
    _test_measure("SFD_Successful_EnergyPlus_Run_AMY.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, "0884454_United_States_IL_Cook_17031_725300_41.97_-87.9_NSRDB_2.0.1_2012_AMY.epw", 0, 1)
  end
  
  private
  
  def model_in_path_default(osm_file_or_model)
    return "#{File.dirname(__FILE__)}/#{osm_file_or_model}"
  end

  def epw_path_default(epw_name)
    # make sure we have a weather data location
    epw = nil
    epw = OpenStudio::Path.new("#{File.dirname(__FILE__)}/#{epw_name}")
    assert(File.exist?(epw.to_s))
    return epw.to_s
  end

  # create test files if they do not exist when the test first runs
  def setup_test(epw_path, model_in_path)

    assert(File.exist?(model_in_path))
    
    translator = OpenStudio::OSVersion::VersionTranslator.new
    model = translator.loadModel(model_in_path)
    assert((not model.empty?))
    model = model.get

    # forward translate OSM file to IDF file
    ft = OpenStudio::EnergyPlus::ForwardTranslator.new
    workspace = ft.translateModel(model)

    FileUtils.cp(epw_path, "../in.epw")

    return workspace
    
  end
  
  def _test_error(osm_file_or_model, args_hash, epw_name)
    # create an instance of the measure
    measure = CustomRunPeriodRange.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    model = get_model(File.dirname(__FILE__), osm_file_or_model)

    # mimic the process of running this measure in OS App or PAT. Optionally set custom model_in_path and custom epw_path.
    workspace = setup_test(File.expand_path(epw_path_default(epw_name)), model_in_path_default(osm_file_or_model))
    
    # get arguments
    arguments = measure.arguments(workspace)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args_hash[arg.name]
        assert(temp_arg_var.setValue(args_hash[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end

    # set up runner, this will happen automatically when measure is run in PAT or OpenStudio
    runner.setLastOpenStudioModelPath(OpenStudio::Path.new(model_in_path_default(osm_file_or_model)))
    
    # run the measure
    measure.run(workspace, runner, argument_map)
    result = runner.result
      
    return result
    
  end
  
  def _test_measure(osm_file_or_model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, epw_name, num_infos=0, num_warnings=0)
    # create an instance of the measure
    measure = CustomRunPeriodRange.new

    # check for standard methods
    assert(!measure.name.empty?)
    assert(!measure.description.empty?)
    assert(!measure.modeler_description.empty?)

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    
    model = get_model(File.dirname(__FILE__), osm_file_or_model)

    # mimic the process of running this measure in OS App or PAT. Optionally set custom model_in_path and custom epw_path.
    workspace = setup_test(File.expand_path(epw_path_default(epw_name)), model_in_path_default(osm_file_or_model))    

    # get the initial objects in the workspace
    initial_objects = get_workspace_objects(workspace)
    
    # get arguments
    arguments = measure.arguments(workspace)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args_hash[arg.name]
        assert(temp_arg_var.setValue(args_hash[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end

    # set up runner, this will happen automatically when measure is run in PAT or OpenStudio
    runner.setLastOpenStudioModelPath(OpenStudio::Path.new(model_in_path_default(osm_file_or_model)))    
    
    # run the measure
    measure.run(workspace, runner, argument_map)
    result = runner.result
    # show_output(result)
    
    # assert that it ran correctly
    assert_equal("Success", result.value.valueName)
    assert(result.info.size == num_infos)
    assert(result.warnings.size == num_warnings)
    
    # get the final objects in the model
    final_objects = get_workspace_objects(workspace)
    
    # get new and deleted objects
    obj_type_exclusions = []
    all_new_objects = get_object_additions(initial_objects, final_objects, obj_type_exclusions)
    all_del_objects = get_object_additions(final_objects, initial_objects, obj_type_exclusions)
    
    # check we have the expected number of new/deleted objects
    check_num_objects(all_new_objects, expected_num_new_objects, "added")
    check_num_objects(all_del_objects, expected_num_del_objects, "deleted")
    
    actual_values = {}
    all_new_objects.each do |obj_type, new_objects|
        new_objects.each do |new_object|
            if obj_type == "RunPeriodCustomRange"
                assert_equal(expected_values["StartMonth"], new_object.getString(1).to_s)
                assert_equal(expected_values["StartDay"], new_object.getString(2).to_s)
                assert_equal(expected_values["StartYear"], new_object.getString(3).to_s)
                assert_equal(expected_values["EndMonth"], new_object.getString(4).to_s)
                assert_equal(expected_values["EndDay"], new_object.getString(5).to_s)
                assert_equal(expected_values["EndYear"], new_object.getString(6).to_s)
            end
        end
    end
    
    lines = File.readlines("../in.epw")
    string1, num1, num2, string2, day_of_week, header_start_date, header_end_date = lines[7].strip.split(",")
    ts_start_year, ts_start_month, ts_start_day, = lines[8].strip.split(",")
    ts_end_year, ts_end_month, ts_end_day, = lines[-1].strip.split(",")    
    header_start_month, header_start_day, header_start_year = header_start_date.split("/")
    header_end_month, header_end_day, header_end_year = header_end_date.split("/")
    assert_equal(ts_start_year, header_start_year)
    assert_equal(ts_start_month, header_start_month)
    assert_equal(ts_start_day, header_start_day)
    assert_equal(ts_end_year, header_end_year)
    assert_equal(ts_end_month, header_end_month)
    assert_equal(ts_end_day, header_end_day)
      
    return model
  end
  
end
