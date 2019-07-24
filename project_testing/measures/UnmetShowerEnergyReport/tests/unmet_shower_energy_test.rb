require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class UnmetShowerEnergyReportTest < MiniTest::Test
  def test_functionality_sfd
    num_units = 1
    measure = UnmetShowerEnergyReport.new
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = { "unmet_shower_energy_kbtu" => 1.420, "unmet_shower_time_hr" => 0.700, "shower_draw_time_hr" => 139.0 }
    _test_measure("SFD_Successful_EnergyPlus_Run_TMY_Fixtures_PV.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, __method__, "USA_CO_Denver_Intl_AP_725650_TMY3.epw", 3, 0, 3 * num_units)
  end

  def test_functionality_mf
    num_units = 2
    measure = UnmetShowerEnergyReport.new
    args_hash = {}
    expected_num_del_objects = {}
    expected_num_new_objects = {}
    expected_values = { "unmet_shower_energy_kbtu" => 1.579, "unmet_shower_time_hr" => 1.528, "shower_draw_time_hr" => 278.0 }
    _test_measure("MF_Successful_EnergyPlus_Run_TMY_Fixtures_PV.osm", args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, __method__, "USA_CO_Denver_Intl_AP_725650_TMY3.epw", 3, 0, 3 * num_units)
  end

  def model_in_path_default(osm_file_or_model)
    return File.absolute_path(File.join(File.dirname(__FILE__), "..", "..", "..", "test", "osm_files", osm_file_or_model))
  end

  def epw_path_default(epw_name)
    # make sure we have a weather data location
    epw = nil
    epw = OpenStudio::Path.new("#{File.dirname(__FILE__)}/#{epw_name}")
    assert(File.exist?(epw.to_s))
    return epw.to_s
  end

  def run_dir(test_name)
    # always generate test output in specially named 'output' directory so result files are not made part of the measure
    return "#{File.dirname(__FILE__)}/output/#{test_name}/run"
  end

  def tests_dir(test_name)
    return "#{File.dirname(__FILE__)}/output/#{test_name}/tests"
  end

  def model_out_path(osm_file_or_model, test_name)
    return "#{run_dir(test_name)}/#{osm_file_or_model}"
  end

  def sql_path(test_name)
    return "#{run_dir(test_name)}/run/eplusout.sql"
  end

  # create test files if they do not exist when the test first runs
  def setup_test(osm_file_or_model, test_name, idf_output_requests, epw_path, model_in_path)
    # convert output requests to OSM for testing, OS App and PAT will add these to the E+ Idf
    workspace = OpenStudio::Workspace.new("Draft".to_StrictnessLevel, "EnergyPlus".to_IddFileType)
    workspace.addObjects(idf_output_requests)
    rt = OpenStudio::EnergyPlus::ReverseTranslator.new
    request_model = rt.translateWorkspace(workspace)

    translator = OpenStudio::OSVersion::VersionTranslator.new
    model = translator.loadModel(model_in_path)
    assert((not model.empty?))
    model = model.get
    model.addObjects(request_model.objects)
    model.save(model_out_path(osm_file_or_model, test_name), true)

    osw_path = File.join(run_dir(test_name), "in.osw")
    osw_path = File.absolute_path(osw_path)

    workflow = OpenStudio::WorkflowJSON.new
    workflow.setSeedFile(File.absolute_path(model_out_path(osm_file_or_model, test_name)))
    workflow.setWeatherFile(epw_path)
    workflow.saveAs(osw_path)

    if !File.exist?("#{run_dir(test_name)}")
      FileUtils.mkdir_p("#{run_dir(test_name)}")
    end

    cli_path = OpenStudio.getOpenStudioCLI
    cmd = "\"#{cli_path}\" --no-ssl run -w \"#{osw_path}\""
    puts cmd
    system(cmd)

    FileUtils.cp(epw_path, "#{tests_dir(test_name)}")

    return model
  end

  def _test_measure(osm_file_or_model, args_hash, expected_num_del_objects, expected_num_new_objects, expected_values, test_name, epw_name, num_infos = 0, num_warnings = 0, num_output_requests = 0, debug = false)
    # create an instance of the measure
    measure = UnmetShowerEnergyReport.new

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
    arguments = measure.arguments()
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args_hash.has_key?(arg.name)
        assert(temp_arg_var.setValue(args_hash[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end

    if !File.exist?(run_dir(test_name))
      FileUtils.mkdir_p(run_dir(test_name))
    end
    assert(File.exist?(run_dir(test_name)))

    if !File.exist?(tests_dir(test_name))
      FileUtils.mkdir_p(tests_dir(test_name))
    end
    assert(File.exist?(tests_dir(test_name)))

    assert(File.exist?(model_in_path_default(osm_file_or_model)))

    # set up runner, this will happen automatically when measure is run in PAT or OpenStudio
    runner.setLastOpenStudioModelPath(OpenStudio::Path.new(model_in_path_default(osm_file_or_model)))
    runner.setLastEpwFilePath(File.expand_path(epw_path_default(epw_name)))

    # get the energyplus output requests, this will be done automatically by OS App and PAT
    idf_output_requests = measure.energyPlusOutputRequests(runner, argument_map)
    assert(idf_output_requests.size == num_output_requests)

    # mimic the process of running this measure in OS App or PAT. Optionally set custom model_in_path and custom epw_path.
    model = setup_test(osm_file_or_model, test_name, idf_output_requests, File.expand_path(epw_path_default(epw_name)), model_in_path_default(osm_file_or_model))
    assert(File.exist?(model_out_path(osm_file_or_model, test_name)))
    runner.setLastEnergyPlusSqlFilePath(OpenStudio::Path.new(sql_path(test_name)))

    # temporarily change directory to the run directory and run the measure
    start_dir = Dir.pwd
    begin
      Dir.chdir(run_dir(test_name))

      # run the measure
      measure.run(runner, argument_map)
      result = runner.result
      # show_output(result)
    ensure
      Dir.chdir(start_dir)
    end

    # assert that it ran correctly
    assert_equal("Success", result.value.valueName)
    assert_equal(num_infos, result.info.size)
    assert_equal(num_warnings, result.warnings.size)

    result.stepValues.each do |value|
      assert_in_epsilon(expected_values[value.name], value.valueAsDouble)
    end

    return model
  end
end
