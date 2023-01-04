# frozen_string_literal: true

require 'openstudio'
require_relative '../../../resources/hpxml-measures/HPXMLtoOpenStudio/resources/minitest_helper'
require_relative '../measure.rb'

class ApplyUpgradeTest < MiniTest::Test
  def test_SFD_1story_FB_UA_GRG_MSHP_FuelTanklessWH
    osw_file = '../../UpgradeCosts/tests/SFD_1story_FB_UA_GRG_MSHP_FuelTanklessWH.osw'
    puts "\nTesting #{File.basename(osw_file)}..."

    args_hash = {}
    expected_capacities = {
      'heating_system_heating_capacity' => nil,
      'heating_system_2_heating_capacity' => nil,
      'cooling_system_cooling_capacity' => nil,
      'heat_pump_heating_capacity' => 60000.0,
      'heat_pump_cooling_capacity' => 60000.0,
      'heat_pump_backup_heating_capacity' => 100000.0
    }

    _lighting_upgrade(args_hash)
    _test_retaining_capacities(osw_file, args_hash, expected_capacities)

    _heating_system_upgrade(args_hash, expected_capacities)
    _test_retaining_capacities(osw_file, args_hash, expected_capacities)

    _heating_system_2_upgrade(args_hash, expected_capacities)
    _test_retaining_capacities(osw_file, args_hash, expected_capacities)

    _cooling_system_upgrade(args_hash, expected_capacities)
    _test_retaining_capacities(osw_file, args_hash, expected_capacities)

    _heat_pump_upgrade(args_hash, expected_capacities)
    _test_retaining_capacities(osw_file, args_hash, expected_capacities)
  end

  def test_SFD_1story_UB_UA_GRG_ACV_FuelFurnace_PortableHeater_HPWH
    osw_file = '../../UpgradeCosts/tests/SFD_1story_UB_UA_GRG_ACV_FuelFurnace_PortableHeater_HPWH.osw'
    puts "\nTesting #{File.basename(osw_file)}..."

    args_hash = {}
    expected_capacities = {
      'heating_system_heating_capacity' => 100000.0,
      'heating_system_2_heating_capacity' => 20000.0,
      'cooling_system_cooling_capacity' => 60000.0,
      'heat_pump_heating_capacity' => nil,
      'heat_pump_cooling_capacity' => nil,
      'heat_pump_backup_heating_capacity' => nil
    }

    _lighting_upgrade(args_hash)
    _test_retaining_capacities(osw_file, args_hash, expected_capacities)

    _heating_system_upgrade(args_hash, expected_capacities)
    _test_retaining_capacities(osw_file, args_hash, expected_capacities)

    _heating_system_2_upgrade(args_hash, expected_capacities)
    _test_retaining_capacities(osw_file, args_hash, expected_capacities)

    _cooling_system_upgrade(args_hash, expected_capacities)
    _test_retaining_capacities(osw_file, args_hash, expected_capacities)

    _heat_pump_upgrade(args_hash, expected_capacities)
    _test_retaining_capacities(osw_file, args_hash, expected_capacities)
  end

  private

  def _lighting_upgrade(args_hash)
    puts "\twindow upgrade..."
    args_hash['window_ufactor'] = 0.29
    args_hash['window_shgc'] = 0.26
  end

  def _heating_system_upgrade(args_hash, expected_capacities)
    puts "\theating system upgrade..."
    args_hash['heating_system_type'] = HPXML::HVACTypeFurnace
    args_hash['heat_pump_type'] = 'none'
    expected_capacities['heating_system_heating_capacity'] = nil
    expected_capacities['heat_pump_heating_capacity'] = nil
    expected_capacities['heat_pump_cooling_capacity'] = nil
    expected_capacities['heat_pump_backup_heating_capacity'] = nil
  end

  def _heating_system_2_upgrade(args_hash, expected_capacities)
    puts "\tsecondary heating system upgrade..."
    args_hash['heating_system_2_type'] = HPXML::HVACTypeFireplace
    expected_capacities['heating_system_2_heating_capacity'] = nil
  end

  def _cooling_system_upgrade(args_hash, expected_capacities)
    puts "\tcooling system upgrade..."
    args_hash['cooling_system_type'] = HPXML::HVACTypeCentralAirConditioner
    args_hash['heat_pump_type'] = 'none'
    expected_capacities['cooling_system_cooling_capacity'] = nil
    expected_capacities['heat_pump_heating_capacity'] = nil
    expected_capacities['heat_pump_cooling_capacity'] = nil
    expected_capacities['heat_pump_backup_heating_capacity'] = nil
  end

  def _heat_pump_upgrade(args_hash, expected_capacities)
    puts "\theat pump upgrade..."
    args_hash['heating_system_type'] = 'none'
    args_hash['cooling_system_type'] = 'none'
    args_hash['heat_pump_type'] = HPXML::HVACTypeHeatPumpAirToAir
    expected_capacities['heating_system_heating_capacity'] = nil
    expected_capacities['cooling_system_cooling_capacity'] = nil
    expected_capacities['heat_pump_heating_capacity'] = nil
    expected_capacities['heat_pump_cooling_capacity'] = nil
    expected_capacities['heat_pump_backup_heating_capacity'] = nil
  end

  def _test_retaining_capacities(osw_file, args_hash, expected_capacities)
    require 'json'

    this_dir = File.dirname(__FILE__)
    osw = File.absolute_path("#{this_dir}/#{osw_file}")

    measures = {}

    osw_hash = JSON.parse(File.read(osw))
    measures_dir = File.join(File.dirname(__FILE__), osw_hash['measure_paths'][0])
    osw_hash['steps'].each do |step|
      measures[step['measure_dir_name']] = [step['arguments']]
    end

    model = OpenStudio::Model::Model.new
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # Apply measure
    cdir = File.expand_path('.')
    success = apply_measures(measures_dir, measures, runner, model)
    Dir.chdir(cdir) # we need this because of Dir.chdir in HPXMLtoOS

    # Report warnings/errors
    runner.result.stepWarnings.each do |s|
      puts "Warning: #{s}"
    end
    runner.result.stepErrors.each do |s|
      puts "Error: #{s}"
    end

    assert(success)

    hpxml_path = File.join(this_dir, '../../UpgradeCosts/tests/in.xml')
    hpxml_in = HPXML.new(hpxml_path: hpxml_path)

    # Create instance of the measure
    measure = ApplyUpgrade.new

    # Check for correct capacity values
    system_upgrades = measure.get_system_upgrades(hpxml_in, [], args_hash)
    actual_capacities = measure.get_system_capacities(hpxml_in, system_upgrades)

    expected_capacities.each do |str, val|
      if val.nil?
        assert_nil(actual_capacities[str])
      else
        assert_equal(val, actual_capacities[str])
      end
    end
  end
end
