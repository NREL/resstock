# frozen_string_literal: true

require 'openstudio'
require 'minitest/autorun'

require_relative '../measure.rb'
require_relative '../../../resources/hpxml-measures/HPXMLtoOpenStudio/resources/minitest_helper'
require_relative '../../../resources/hpxml-measures/HPXMLtoOpenStudio/measure'

class ApplyUpgradeTest < MiniTest::Test
  def test_SFD_1story_FB_UA_GRG_MSHP_FuelTanklessWH
    # Retain the heat pump capacities since you aren't upgrading the heat pump
    args_hash = {}
    expected_capacities = {
      'heating_system_heating_capacity' => nil,
      'heating_system_heating_capacity_2' => nil,
      'cooling_system_cooling_capacity' => nil,
      'heat_pump_heating_capacity' => 60000.0,
      'heat_pump_cooling_capacity' => 60000.0,
      'heat_pump_backup_heating_capacity' => 100000.0,
    }
    _test_retaining_capacities('SFD_1story_FB_UA_GRG_MSHP_FuelTanklessWH.xml', args_hash, expected_capacities)

    # Don't retain the heat pump capacities because you are upgrading the heat pump
    args_hash['heat_pump_type'] = 'air-to-air'
    expected_capacities['heat_pump_heating_capacity'] = nil
    expected_capacities['heat_pump_cooling_capacity'] = nil
    expected_capacities['heat_pump_backup_heating_capacity'] = nil
    _test_retaining_capacities('SFD_1story_FB_UA_GRG_MSHP_FuelTanklessWH.xml', args_hash, expected_capacities)

    # Retain the heat pump capacities, but they'll be ignored anyway (since heat_pump_type=none)
    args_hash = {}
    args_hash['heating_system_type'] = 'Furnace'
    expected_capacities['heat_pump_heating_capacity'] = 60000.0
    expected_capacities['heat_pump_cooling_capacity'] = 60000.0
    expected_capacities['heat_pump_backup_heating_capacity'] = 100000.0
    _test_retaining_capacities('SFD_1story_FB_UA_GRG_MSHP_FuelTanklessWH.xml', args_hash, expected_capacities)
  end

  private

  def _test_retaining_capacities(hpxml_file, args_hash, expected_capacities)

    this_dir = File.dirname(__FILE__)

    hpxml_path = File.join(this_dir, hpxml_file)
    hpxml = HPXML.new(hpxml_path: hpxml_path)

    # create an instance of the measure
    measure = ApplyUpgrade.new

    system_upgrades = measure.get_system_upgrades([], args_hash)
    actual_capacities = measure.get_system_capacities(hpxml, system_upgrades)

    expected_capacities.each do |str, val|
      if val.nil?
        assert_nil(actual_capacities[str])
      else
        assert_equal(val, actual_capacities[str])
      end
    end
  end
end
