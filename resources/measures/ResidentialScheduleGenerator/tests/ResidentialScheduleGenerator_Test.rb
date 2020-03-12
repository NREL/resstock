require_relative '../../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class ResidentialScheduleGeneratorTest < MiniTest::Test
  @@full_load_hrs_range = {
    "occupants" => [0, 8784], # TODO
    "cooking_range" => [0, 8784], # TODO
    "plug_loads" => [0, 8784], # TODO
    "lighting_interior" => [0, 8784], # TODO
    "lighting_exterior" => [0, 8784], # TODO
    "lighting_garage" => [0, 8784], # TODO
    "lighting_exterior_holiday" => [0, 8784], # TODO
    "clothes_washer" => [0, 8784], # TODO
    "clothes_dryer" => [0, 8784], # TODO
    "dishwasher" => [0, 8784], # TODO
    "baths" => [0, 8784], # TODO
    "showers" => [0, 8784], # TODO
    "sinks" => [0, 8784], # TODO
    "ceiling_fan" => [0, 8784], # TODO
    "clothes_dryer_exhaust" => [0, 8784] # TODO
  }

  def test_sweep_building_ids_and_num_occupants
    num_building_ids = 10
    num_occupants = 6
    results = { "building_id" => [], "num_occupants" => [] }
    expected_values = { "SchedulesLength" => 52560, "SchedulesWidth" => 15 }
    (1..num_building_ids).to_a.each do |building_id|
      building_id = rand(1..450000)
      (1..num_occupants).to_a.each do |num_occupant|
        puts "\nBUILDING ID: #{building_id}, NUM_OCCUPANTS: #{num_occupant}"
        results["building_id"] << building_id
        results["num_occupants"] << num_occupant
        args_hash = {}
        args_hash[:building_id] = building_id
        args_hash[:num_occupants] = num_occupant
        results = _test_measure("SFD_2000sqft_2story_FB_UA_Denver.osm", args_hash, expected_values, __method__, "USA_CO_Denver.Intl.AP.725650_TMY3.epw", results)
      end
    end
    csv_path = File.join(test_dir(__method__), "full_load_hours.csv")
    CSV.open(csv_path, "wb") do |csv|
      csv << results.keys
      rows = results.values.transpose
      rows.each do |row|
        csv << row
      end
    end
  end

  def test_3bed_8760 # these are the old schedules
    args_hash = {}
    expected_values = { "SchedulesLength" => 8760, "SchedulesWidth" => 15 }
    _test_measure("SFD_2000sqft_2story_FB_UA_Denver.osm", args_hash, expected_values, __method__, "USA_CO_Denver.Intl.AP.725650_TMY3.epw")
  end

  def test_3bed_8784 # these are the old schedules
    args_hash = {}
    expected_values = { "SchedulesLength" => 8784, "SchedulesWidth" => 15 }
    _test_measure("SFD_Successful_EnergyPlus_Run_AMY_PV.osm", args_hash, expected_values, __method__, "USA_CO_Denver.Intl.AP.725650_TMY3.epw")
  end

  private

  def test_dir(test_name)
    # always generate test output in specially named 'output' directory so result files are not made part of the measure
    return "#{File.dirname(__FILE__)}/output/#{test_name}"
  end

  def schedule_file_path(test_name)
    return "#{test_dir(test_name)}/schedules.csv"
  end

  def _test_measure(osm_file_or_model, args_hash, expected_values, test_name, epw_name, results = nil)
    # create an instance of the measure
    measure = ResidentialScheduleGenerator.new

    # check for standard methods
    assert(!measure.name.empty?)
    assert(!measure.description.empty?)

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    model = get_model(File.dirname(__FILE__), osm_file_or_model)

    if !File.exist?("#{test_dir(test_name)}")
      FileUtils.mkdir_p("#{test_dir(test_name)}")
    end

    args_hash[:schedules_path] = File.join(File.dirname(__FILE__), "../../HPXMLtoOpenStudio/resources/schedules")

    if "#{test_name}".include? "8760"
      schedules_path = File.join(File.dirname(__FILE__), "../../../../files/8760.csv")
    elsif "#{test_name}".include? "8784"
      schedules_path = File.join(File.dirname(__FILE__), "../../../../files/8784.csv")
    else
      schedules_path = schedule_file_path(test_name)
      schedule_generator = ScheduleGenerator.new(runner: runner, model: model, **args_hash)
      success = schedule_generator.create
      success = schedule_generator.export(output_path: schedules_path)
    end

    # make sure the enduse report file exists
    if expected_values.keys.include? "SchedulesLength" and expected_values.keys.include? "SchedulesWidth"
      assert(File.exist?(schedules_path))

      # make sure you're reporting at correct frequency
      schedules_length, schedules_width, results = get_schedule_file(model, runner, schedules_path, results)
      assert_equal(expected_values["SchedulesLength"], schedules_length)
      assert_equal(expected_values["SchedulesWidth"], schedules_width)
    end

    return results
  end

  def get_schedule_file(model, runner, schedules_path, results)
    schedules_file = SchedulesFile.new(runner: runner, model: model, schedules_path: schedules_path)
    if not schedules_file.validated?
      return false
    end

    rows = CSV.read(File.expand_path(schedules_path))
    results = check_columns(rows[0], schedules_file, results)
    schedules_length = rows.length - 1
    cols = rows.transpose
    schedules_width = cols.length
    return schedules_length, schedules_width, results
  end

  def check_columns(col_names, schedules_file, results)
    passes = true
    col_names.each do |col_name|
      results[col_name] = [] unless results.keys.include? col_name
      full_load_hrs = schedules_file.annual_equivalent_full_load_hrs(col_name: col_name)
      results[col_name] << full_load_hrs
      if full_load_hrs >= @@full_load_hrs_range[col_name][0] and full_load_hrs <= @@full_load_hrs_range[col_name][1]
        full_load_hrs = "#{full_load_hrs.round(2)}".green
      else
        full_load_hrs = "#{full_load_hrs.round(2)}".red
        passes = false
      end      
      puts "#{col_name}: full load hrs: #{full_load_hrs}"
    end
    assert(passes)
    return results
  end
end

class String
  def red
    return "\e[31m#{self}\e[0m"
  end

  def green
    return "\e[32m#{self}\e[0m"
  end
end
