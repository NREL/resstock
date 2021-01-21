# frozen_string_literal: true

require 'openstudio'
require 'minitest/autorun'

require_relative '../measure.rb'
require_relative '../../../resources/hpxml-measures/HPXMLtoOpenStudio/resources/minitest_helper'
require_relative '../../../resources/hpxml-measures/HPXMLtoOpenStudio/measure'

class UpgradeCostsTest < MiniTest::Test
  def sample_files_dir
    return File.join(File.dirname(__FILE__), '..', '..', '..', 'resources', 'hpxml-measures', 'workflow', 'sample_files')
  end

  def test_single_family_detached
    cost_multipliers = {
      'Fixed (1)' => 1,
      'Wall Area, Above-Grade, Conditioned (ft^2)' => 1200.0,
      'Wall Area, Above-Grade, Exterior (ft^2)' => 1200.0 + 290.0,
      'Wall Area, Below-Grade (ft^2)' => 1200.0,
      'Floor Area, Conditioned (ft^2)' => 2700.0,
      'Floor Area, Attic (ft^2)' => 1350.0,
      'Floor Area, Lighting (ft^2)' => 2700.0,
      'Roof Area (ft^2)' => 1510.0,
      'Window Area (ft^2)' => 108.0 * 2 + 72.0 * 2,
      'Door Area (ft^2)' => 40.0 * 2,
      'Duct Surface Area (ft^2)' => 150.0 + 50.0,
      'Size, Heating System (kBtu/h)' => 64.0,
      'Size, Heating Supplemental System (kBtu/h)' => 0.0,
      'Size, Cooling System (kBtu/h)' => 48.0,
      'Size, Water Heater (gal)' => 40.0,
    }
    _test_cost_multipliers('base.xml', cost_multipliers)
  end

  def test_single_family_detached_garage
    cost_multipliers = {
      'Fixed (1)' => 1,
      'Wall Area, Above-Grade, Conditioned (ft^2)' => 960.0 + 240.0,
      'Wall Area, Above-Grade, Exterior (ft^2)' => 960.0 + 560.0 + 113.0,
      'Wall Area, Below-Grade (ft^2)' => 1200.0,
      'Floor Area, Conditioned (ft^2)' => 2700.0,
      'Floor Area, Attic (ft^2)' => 1350.0,
      'Floor Area, Lighting (ft^2)' => 2700.0 + 600.0,
      'Roof Area (ft^2)' => 2180.0,
      'Window Area (ft^2)' => 108.0 + 12.0 + 72.0 * 2,
      'Door Area (ft^2)' => 40.0 * 2 + 70.0,
      'Duct Surface Area (ft^2)' => 150.0 + 50.0,
      'Size, Heating System (kBtu/h)' => 64.0,
      'Size, Heating Supplemental System (kBtu/h)' => 0.0,
      'Size, Cooling System (kBtu/h)' => 48.0,
      'Size, Water Heater (gal)' => 40.0,
    }
    _test_cost_multipliers('base-enclosure-garage.xml', cost_multipliers)
  end

  def test_single_family_attached
    cost_multipliers = {
      'Fixed (1)' => 1,
      'Wall Area, Above-Grade, Conditioned (ft^2)' => 686.0,
      'Wall Area, Above-Grade, Exterior (ft^2)' => 686.0 + 169.0,
      'Wall Area, Below-Grade (ft^2)' => 686.0 + 294.0,
      'Floor Area, Conditioned (ft^2)' => 1800.0,
      'Floor Area, Attic (ft^2)' => 900.0,
      'Floor Area, Lighting (ft^2)' => 1800.0,
      'Roof Area (ft^2)' => 1006.0,
      'Window Area (ft^2)' => 35.4 * 2 + 53.0,
      'Door Area (ft^2)' => 40.0 * 2,
      'Duct Surface Area (ft^2)' => 150.0 + 50.0,
      'Size, Heating System (kBtu/h)' => 64.0,
      'Size, Heating Supplemental System (kBtu/h)' => 0.0,
      'Size, Cooling System (kBtu/h)' => 48.0,
      'Size, Water Heater (gal)' => 40.0,
    }
    _test_cost_multipliers('base-bldgtype-single-family-attached.xml', cost_multipliers)
  end

  def test_multifamily
    cost_multipliers = {
      'Fixed (1)' => 1,
      'Wall Area, Above-Grade, Conditioned (ft^2)' => 686.0,
      'Wall Area, Above-Grade, Exterior (ft^2)' => 686.0,
      'Wall Area, Below-Grade (ft^2)' => 0.0,
      'Floor Area, Conditioned (ft^2)' => 900.0,
      'Floor Area, Attic (ft^2)' => 0.0,
      'Floor Area, Lighting (ft^2)' => 900.0,
      'Roof Area (ft^2)' => 0.0,
      'Window Area (ft^2)' => 35.0 * 2 + 53.0,
      'Door Area (ft^2)' => 20.0,
      'Duct Surface Area (ft^2)' => 150.0 + 50.0,
      'Size, Heating System (kBtu/h)' => 64.0,
      'Size, Heating Supplemental System (kBtu/h)' => 0.0,
      'Size, Cooling System (kBtu/h)' => 48.0,
      'Size, Water Heater (gal)' => 40.0,
    }
    _test_cost_multipliers('base-bldgtype-multifamily.xml', cost_multipliers)
  end

  private

  def _test_cost_multipliers(xml_file, cost_multipliers)
    # load the test model
    hpxml_path = File.absolute_path(File.join(sample_files_dir, xml_file))
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
