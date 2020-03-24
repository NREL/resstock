require_relative '../../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class ResidentialScheduleGeneratorTest < MiniTest::Test
  @@design_levels_e = {
    "cooking_range" => 224.799466698323, # test_new_construction_electric
    "plug_loads" => 97.542065513059 + 97.542065513059 + 170.698614647853, # test_new_construction_energy_use
    "lighting_interior" => 239.813313104278 + 137.03617891673 + 137.03617891673, # test_new_construction_100_incandescent
    "lighting_exterior" => 105.096505339876, # test_new_construction_100_incandescent
    "lighting_garage" => 14.4960697020519, # test_new_construction_100_incandescent
    "lighting_exterior_holiday" => 311.901700057588, # test_new_construction_holiday_schedule_overlap_years
    "clothes_washer" => 70491.5361082842, # test_new_construction_standard
    "clothes_dryer" => 187100.865402176, # test_new_construction_standard_elec
    "dishwasher" => 182309.775344607, # test_new_construction_318_rated_kwh
    "baths" => 65146.3417951306, # test_new_construction_standard
    "showers" => 507081.308470722, # test_new_construction_standard
    "sinks" => 158036.112491921, # test_new_construction_standard
    "ceiling_fan" => 22.5, # test_specified_num
  }

  @@peak_flow_rates = {
    "clothes_washer" => 0.00629935656948612, # test_new_construction_standard
    "dishwasher" => 0.00195236583980626, # test_new_construction_318_rated_kwh
    "baths" => 0.00441642226310263, # test_new_construction_standard
    "showers" => 0.0176468149892557, # test_new_construction_standard
    "sinks" => 0.0157378848223646 # test_new_construction_standard
  }

  def test_sweep_building_ids_and_num_occupants
    full_load_hours = { "schedules_length" => [], "building_id" => [], "num_occupants" => [] }
    annual_energy_use = { "schedules_length" => [], "building_id" => [], "num_occupants" => [] }
    hot_water_gpd = { "schedules_length" => [], "building_id" => [], "num_occupants" => [] }
    args_hash = {}

    expected_values = { "SchedulesLength" => 8760, "SchedulesWidth" => 15 } # these are the old schedules
    full_load_hours["building_id"] << 1
    full_load_hours["num_occupants"] << 2.64
    annual_energy_use["building_id"] << 1
    annual_energy_use["num_occupants"] << 2.64
    hot_water_gpd["building_id"] << 1
    hot_water_gpd["num_occupants"] << 2.64
    full_load_hours, annual_energy_use, hot_water_gpd = _test_measure("SFD_2000sqft_2story_FB_UA_Denver.osm", args_hash, expected_values, "8760", "USA_CO_Denver.Intl.AP.725650_TMY3.epw", full_load_hours, annual_energy_use, hot_water_gpd)

    expected_values = { "SchedulesLength" => 8784, "SchedulesWidth" => 15 } # these are the old schedules
    full_load_hours["building_id"] << 1
    full_load_hours["num_occupants"] << 2.64
    annual_energy_use["building_id"] << 1
    annual_energy_use["num_occupants"] << 2.64
    hot_water_gpd["building_id"] << 1
    hot_water_gpd["num_occupants"] << 2.64
    full_load_hours, annual_energy_use, hot_water_gpd = _test_measure("SFD_Successful_EnergyPlus_Run_AMY_PV.osm", args_hash, expected_values, "8784", "USA_CO_Denver.Intl.AP.725650_TMY3.epw", full_load_hours, annual_energy_use, hot_water_gpd)

    num_building_ids = 20
    num_occupants = 6
    expected_values = { "SchedulesLength" => 52560, "SchedulesWidth" => 15 }
    (1..num_building_ids).to_a.each do |building_id|
      building_id = rand(1..450000)
      (1..num_occupants).to_a.each do |num_occupant|
        puts "\nBUILDING ID: #{building_id}, NUM_OCCUPANTS: #{num_occupant}"
        full_load_hours["building_id"] << building_id
        full_load_hours["num_occupants"] << num_occupant
        annual_energy_use["building_id"] << building_id
        annual_energy_use["num_occupants"] << num_occupant
        hot_water_gpd["building_id"] << building_id
        hot_water_gpd["num_occupants"] << num_occupant
        args_hash[:building_id] = building_id
        args_hash[:num_occupants] = num_occupant
        full_load_hours, annual_energy_use, hot_water_gpd = _test_measure("SFD_2000sqft_2story_FB_UA_Denver.osm", args_hash, expected_values, __method__, "USA_CO_Denver.Intl.AP.725650_TMY3.epw", full_load_hours, annual_energy_use, hot_water_gpd)
      end
    end

    csv_path = File.join(test_dir(__method__), "full_load_hours.csv")
    CSV.open(csv_path, "wb") do |csv|
      csv << full_load_hours.keys
      rows = full_load_hours.values.transpose
      rows.each do |row|
        csv << row
      end
    end

    csv_path = File.join(test_dir(__method__), "annual_electricity_use.csv")
    CSV.open(csv_path, "wb") do |csv|
      csv << annual_energy_use.keys
      rows = annual_energy_use.values.transpose
      rows.each do |row|
        csv << row
      end
    end

    csv_path = File.join(test_dir(__method__), "hot_water_gpd.csv")
    CSV.open(csv_path, "wb") do |csv|
      csv << hot_water_gpd.keys
      rows = hot_water_gpd.values.transpose
      rows.each do |row|
        csv << row
      end
    end
  end

  private

  def test_dir(test_name)
    # always generate test output in specially named 'output' directory so result files are not made part of the measure
    return "#{File.dirname(__FILE__)}/output/#{test_name}"
  end

  def schedule_file_path(test_name)
    return "#{test_dir(test_name)}/schedules.csv"
  end

  def _test_measure(osm_file_or_model, args_hash, expected_values, test_name, epw_name, full_load_hours, annual_energy_use, hot_water_gpd)
    # create an instance of the measure
    measure = ResidentialScheduleGenerator.new

    # check for standard methods
    assert(!measure.name.empty?)
    assert(!measure.description.empty?)

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    model = get_model(File.dirname(__FILE__), osm_file_or_model)

    args_hash[:schedules_path] = File.join(File.dirname(__FILE__), "../../HPXMLtoOpenStudio/resources/schedules")

    if "#{test_name}".include? "8760"
      schedules_path = File.join(File.dirname(__FILE__), "../../../../files/8760.csv")
    elsif "#{test_name}".include? "8784"
      schedules_path = File.join(File.dirname(__FILE__), "../../../../files/8784.csv")
    else
      if !File.exist?("#{test_dir(test_name)}")
        FileUtils.mkdir_p("#{test_dir(test_name)}")
      end

      schedules_path = schedule_file_path(test_name)
      schedule_generator = ScheduleGenerator.new(runner: runner, model: model, **args_hash)
      success = schedule_generator.create
      success = schedule_generator.export(output_path: schedules_path)
    end

    # make sure the enduse report file exists
    if expected_values.keys.include? "SchedulesLength" and expected_values.keys.include? "SchedulesWidth"
      assert(File.exist?(schedules_path))

      # make sure you're reporting at correct frequency
      schedules_length, schedules_width, full_load_hours, annual_energy_use, hot_water_gpd = get_schedule_file(model, runner, schedules_path, full_load_hours, annual_energy_use, hot_water_gpd)
      assert_equal(expected_values["SchedulesLength"], schedules_length)
      assert_equal(expected_values["SchedulesWidth"], schedules_width)
      full_load_hours["schedules_length"] << schedules_length
      annual_energy_use["schedules_length"] << schedules_length
      hot_water_gpd["schedules_length"] << schedules_length
    end

    return full_load_hours, annual_energy_use, hot_water_gpd
  end

  def get_schedule_file(model, runner, schedules_path, full_load_hours, annual_energy_use, hot_water_gpd)
    schedules_file = SchedulesFile.new(runner: runner, model: model, schedules_path: schedules_path)
    if not schedules_file.validated?
      return false
    end

    rows = CSV.read(File.expand_path(schedules_path))
    full_load_hours, annual_energy_use, hot_water_gpd = check_columns(rows[0], schedules_file, full_load_hours, annual_energy_use, hot_water_gpd)
    schedules_length = rows.length - 1
    cols = rows.transpose
    schedules_width = cols.length
    return schedules_length, schedules_width, full_load_hours, annual_energy_use, hot_water_gpd
  end

  def check_columns(col_names, schedules_file, full_load_hours, annual_energy_use, hot_water_gpd)
    col_names.each do |col_name|
      flh = schedules_file.annual_equivalent_full_load_hrs(col_name: col_name)
      aeu = nil
      if @@design_levels_e.keys.include? col_name
        aeu = UnitConversions.convert(flh * @@design_levels_e[col_name], "Wh", "kWh")
      end
      hwg = nil
      if @@peak_flow_rates.keys.include? col_name
        hwg = UnitConversions.convert(flh * @@peak_flow_rates[col_name], "m^3/s", "gal/min") * 60.0 / 365.0
      end

      full_load_hours[col_name] = [] unless full_load_hours.keys.include? col_name
      annual_energy_use[col_name] = [] unless annual_energy_use.keys.include? col_name
      hot_water_gpd[col_name] = [] unless hot_water_gpd.keys.include? col_name

      full_load_hours[col_name] << flh
      annual_energy_use[col_name] << aeu
      hot_water_gpd[col_name] << hwg
    end

    return full_load_hours, annual_energy_use, hot_water_gpd
  end
end
