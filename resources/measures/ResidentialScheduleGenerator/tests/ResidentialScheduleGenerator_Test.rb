require_relative '../../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class ResidentialScheduleGeneratorTest < MiniTest::Test
  def test_default_values
    args_hash = {}
    expected_values = { "SchedulesLength" => 52560, "SchedulesWidth" => 14 }
    _test_measure("Denver.osm", args_hash, expected_values, __method__, "USA_CO_Denver.Intl.AP.725650_TMY3.epw")
  end

  def test_building_id_12345
    args_hash = {}
    args_hash["building_id"] = 12345
    expected_values = { "SchedulesLength" => 52560, "SchedulesWidth" => 14 }
    _test_measure("Denver.osm", args_hash, expected_values, __method__, "USA_CO_Denver.Intl.AP.725650_TMY3.epw")
  end

  private

  def model_in_path_default(osm_file_or_model)
    return File.absolute_path(File.join(File.dirname(__FILE__), "..", "..", "..", "..", "test", "osm_files", osm_file_or_model))
  end

  def epw_path_default(epw_name)
    epw = OpenStudio::Path.new("#{File.dirname(__FILE__)}/../../../../resources/measures/HPXMLtoOpenStudio/weather/#{epw_name}")
    assert(File.exist?(epw.to_s))
    return epw.to_s
  end

  def test_dir(test_name)
    # always generate test output in specially named 'output' directory so result files are not made part of the measure
    return "#{File.dirname(__FILE__)}/output/#{test_name}"
  end

  def model_out_path(osm_file_or_model, test_name)
    return "#{test_dir(test_name)}/#{osm_file_or_model}"
  end

  def sql_path(test_name)
    return "#{test_dir(test_name)}/run/eplusout.sql"
  end

  def schedule_file_path(test_name)
    return "#{test_dir(test_name)}/appliances_schedules.csv"
  end

  # create test files if they do not exist when the test first runs
  def setup_test(osm_file_or_model, test_name, epw_path, model_in_path)
    # convert output requests to OSM for testing, OS App and PAT will add these to the E+ Idf
    workspace = OpenStudio::Workspace.new("Draft".to_StrictnessLevel, "EnergyPlus".to_IddFileType)
    rt = OpenStudio::EnergyPlus::ReverseTranslator.new
    request_model = rt.translateWorkspace(workspace)

    translator = OpenStudio::OSVersion::VersionTranslator.new
    model = translator.loadModel(model_in_path)
    assert((not model.empty?))
    model = model.get
    model.addObjects(request_model.objects)
    model.save(model_out_path(osm_file_or_model, test_name), true)

    osw_path = File.join(test_dir(test_name), "in.osw")
    osw_path = File.absolute_path(osw_path)

    workflow = OpenStudio::WorkflowJSON.new
    workflow.setSeedFile(File.absolute_path(model_out_path(osm_file_or_model, test_name)))
    workflow.setWeatherFile(epw_path)
    workflow.saveAs(osw_path)

    if !File.exist?("#{test_dir(test_name)}")
      FileUtils.mkdir_p("#{test_dir(test_name)}")
    end

    cli_path = OpenStudio.getOpenStudioCLI
    cmd = "\"#{cli_path}\" --no-ssl run -m -w \"#{osw_path}\""
    puts cmd
    system(cmd)

    return model
  end

  def _test_measure(osm_file_or_model, args_hash, expected_values, test_name, epw_name)
    # create an instance of the measure
    measure = ResidentialScheduleGenerator.new

    # check for standard methods
    assert(!measure.name.empty?)
    assert(!measure.description.empty?)

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

    if !File.exist?(test_dir(test_name))
      FileUtils.mkdir_p(test_dir(test_name))
    end
    assert(File.exist?(test_dir(test_name)))

    assert(File.exist?(model_in_path_default(osm_file_or_model)))

    # set up runner, this will happen automatically when measure is run in PAT or OpenStudio
    runner.setLastOpenStudioModelPath(OpenStudio::Path.new(model_in_path_default(osm_file_or_model)))
    runner.setLastEpwFilePath(File.expand_path(epw_path_default(epw_name)))

    # mimic the process of running this measure in OS App or PAT. Optionally set custom model_in_path and custom epw_path.
    model = setup_test(osm_file_or_model, test_name, File.expand_path(epw_path_default(epw_name)), model_in_path_default(osm_file_or_model))
    assert(File.exist?(model_out_path(osm_file_or_model, test_name)))
    runner.setLastEnergyPlusSqlFilePath(OpenStudio::Path.new(sql_path(test_name)))

    # temporarily change directory to the run directory and run the measure
    start_dir = Dir.pwd
    begin
      Dir.chdir(test_dir(test_name))

      # run the measure
      measure.run(model, runner, argument_map)
      FileUtils.mv("../appliances_schedules.csv", "appliances_schedules.csv")
      result = runner.result
      show_output(result) unless result.value.valueName == 'Success'
    ensure
      Dir.chdir(start_dir)
    end

    # make sure the enduse report file exists
    if expected_values.keys.include? "SchedulesLength" and expected_values.keys.include? "SchedulesWidth"
      assert(File.exist?(schedule_file_path(test_name)))

      # make sure you're reporting at correct frequency
      schedules_length, schedules_width = get_schedule_file(model, runner, schedule_file_path(test_name))
      assert_equal(expected_values["SchedulesLength"], schedules_length)
      assert_equal(expected_values["SchedulesWidth"], schedules_width)
    end

    # assert that it ran correctly
    assert_equal("Success", result.value.valueName)
    assert(result.info.size > 0)

    return model
  end

  def get_schedule_file(model, runner, schedule_file)
    schedules_file = SchedulesFile.new(runner: runner, model: model, schedules_output_path: schedule_file)
    if not schedules_file.validated?
      return false
    end

    rows = CSV.read(File.expand_path(schedule_file))
    check_columns(rows[0], schedules_file)
    schedules_length = rows.length - 1
    cols = rows.transpose
    schedules_width = cols.length
    return schedules_length, schedules_width
  end

  def check_columns(col_names, schedules_file)
    passes = true
    col_names.each do |col_name|
      full_load_hrs = schedules_file.annual_equivalent_full_load_hrs(col_name: col_name)
      if full_load_hrs > 0
        full_load_hrs = "#{full_load_hrs.round(1)}".green
      else
        full_load_hrs = "#{full_load_hrs.round(1)}".red
        passes = false
      end

      puts "Checking #{col_name}... Full Load Hrs: #{full_load_hrs}"
    end
    assert(passes)
  end
end

class String
def red;            "\e[31m#{self}\e[0m" end
def green;          "\e[32m#{self}\e[0m" end
end