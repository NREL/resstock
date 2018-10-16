require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class ThermalCapacitanceReportTest < MiniTest::Test

  def test_test
    thermal_capacitances = {
                             "wall_ext_ins_fin"=>100,
                           }
    _test_thermal_capacitances("SFD_2story_S_UA_GRG_ASHP1_FuelTanklessWH.osm", thermal_capacitances)
  end
    
  private

  def _test_thermal_capacitances(osm_file, thermal_capacitances)
    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new(File.join(File.dirname(__FILE__), osm_file))
    model = translator.loadModel(path)
    assert((not model.empty?))
    model = model.get

    # create an instance of the measure
    measure = SimulationOutputReport.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    
    # Check for correct thermal capacitance values
    thermal_capacitances.each do |constr_name, thermal_capacitance|
      constr = nil
      model.getConstructions.each do |construction|
        next if construction.name.to_s != constr_name
        constr = construction
      end
      assert(!constr.nil?)
      area = measure.get_surface_area(model, construction) + measure.get_foundation_area(model, construction) + measure.get_sub_surface_area(model, construction) + measure.get_internal_mass_area(model, construction)
      value = measure.get_thermal_capacitance(constr, area)
      assert(!value.nil?)
      assert_in_epsilon(thermal_capacitance, value, 0.05)
    end
  end

end
