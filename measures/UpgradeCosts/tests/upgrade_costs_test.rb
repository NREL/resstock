# frozen_string_literal: true

require 'openstudio'
require 'minitest/autorun'

require_relative '../measure.rb'
require_relative '../../../resources/hpxml-measures/HPXMLtoOpenStudio/resources/minitest_helper'
require_relative '../../../resources/hpxml-measures/HPXMLtoOpenStudio/measure'

class UpgradeCostsTest < MiniTest::Test
  def test_SFD_1story_FB_UA_GRG_MSHP_FuelTanklessWH
    cost_multipliers = {
      'Fixed (1)' => 1,
      'Wall Area, Above-Grade, Conditioned (ft^2)' => 1633.82,
      'Wall Area, Above-Grade, Exterior (ft^2)' => 2176.31,
      'Wall Area, Below-Grade (ft^2)' => 1633.82 - 192.0,
      'Floor Area, Conditioned (ft^2)' => 4500,
      'Floor Area, Attic (ft^2)' => 2250,
      'Floor Area, Lighting (ft^2)' => 4788,
      'Roof Area (ft^2)' => 2837.57,
      'Window Area (ft^2)' => 168.74,
      'Door Area (ft^2)' => 30,
      'Duct Unconditioned Surface Area (ft^2)' => 1665,
      'Size, Heating System (kBtu/h)' => 60, # hp, not backup
      'Size, Heating Supplemental System (kBtu/h)' => 100, # backup
      'Size, Cooling System (kBtu/h)' => 60,
      'Size, Water Heater (gal)' => 0,
    }
    _test_cost_multipliers('SFD_1story_FB_UA_GRG_MSHP_FuelTanklessWH.osw', cost_multipliers)
  end

  private

  def _test_cost_multipliers(osw_file, cost_multipliers)
    require 'json'

    this_dir = File.dirname(__FILE__)

    osw = File.absolute_path("#{this_dir}/#{osw_file}")

    measures = {}
    puts "\nTesting #{File.basename(osw)}..."

    osw_hash = JSON.parse(File.read(osw))
    measures_dir = File.join(File.dirname(__FILE__), osw_hash['measure_paths'][0])
    osw_hash['steps'].each do |step|
      measures[step['measure_dir_name']] = [step['arguments']]
      model = OpenStudio::Model::Model.new
      runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

      # Apply measure
      success = apply_measures(measures_dir, measures, runner, model)

      # Report warnings/errors
      runner.result.stepWarnings.each do |s|
        puts "Warning: #{s}"
      end
      runner.result.stepErrors.each do |s|
        puts "Error: #{s}"
      end

      assert(success)
    end

    hpxml_path = File.join(this_dir, osw_file.gsub('osw', 'xml'))
    hpxml = HPXML.new(hpxml_path: hpxml_path)

    # create an instance of the measure
    measure = UpgradeCosts.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # Check for correct cost multiplier values
    cost_multipliers.each do |mult_type, mult_value|
      value = measure.get_cost_multiplier(mult_type, hpxml, runner)
      assert(!value.nil?)
      if mult_type.include?('ft^2') || mult_type.include?('gal')
        assert_in_epsilon(mult_value, value, 0.01)
      else
        assert_in_epsilon(mult_value, value, 0.05)
      end
    end
  end
end
