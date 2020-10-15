require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class ScoutInputReportTest < MiniTest::Test
  def test_SFD_1story_FB_UA_GRG_MSHP_FuelTanklessWH
    skip
    scout_inputs = {
      "conv_walls_heating" => 0,
      "conv_walls_secondary_heating" => 0,
      "conv_walls_cooling" => 0,
      "conv_roof_heating" => 0,
      "conv_roof_secondary_heating" => 0,
      "conv_roof_cooling" => 0,
      "conv_ground_heating" => 0,
      "conv_ground_secondary_heating" => 0,
      "conv_ground_cooling" => 0,
      "infiltration_heating" => 0,
      "infiltration_secondary_heating" => 0,
      "infiltration_cooling" => 0,
      "people_heating" => 0,
      "people_secondary_heating" => 0,
      "people_cooling" => 0,
      "equipment_heating" => 0,
      "equipment_secondary_heating" => 0,
      "equipment_cooling" => 0,
      "solar_windows_heating" => 0,
      "solar_windows_secondary_heating" => 0,
      "solar_windows_cooling" => 0,
      "cond_windows_heating" => 0,
      "cond_windows_secondary_heating" => 0,
      "cond_windows_cooling" => 0
    }
    _test_scout_inputs("SFD_1story_FB_UA_GRG_MSHP_FuelTanklessWH.osm", scout_inputs)
  end

  private

  def _test_scout_inputs(osm_file, scout_inputs)
    # load the test model
    model = get_model(File.dirname(__FILE__), osm_file)

    # create an instance of the measure
    measure = ScoutInputReport.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # Check for correct scout input values
    scout_inputs.each do |scout_input_type, scout_input_value|
      puts scout_input_type
      value = measure.get_scout_input(scout_input_type, model, runner)
      assert(!value.nil?)
      assert_in_epsilon(scout_input_value, value, 0.01)
    end
  end
end
