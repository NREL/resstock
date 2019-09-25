require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require_relative 'minitest_helper'
require 'minitest/autorun'
require 'fileutils'

class TestResStockModelFidelity < MiniTest::Test
  def test_each_unit_has_at_least_one_outdoor_wall
    # Check fidelity of each osm
    translator = OpenStudio::OSVersion::VersionTranslator.new

    _get_test_model_osms.each do |osm|
      path = OpenStudio::Path.new(osm)
      model = translator.loadModel(path)
      assert((not model.empty?))
      model = model.get

      model.getBuildingUnits.each do |unit|
        unit_has_at_least_one_outdoor_wall = false
        unit.spaces.each do |space|
          next if unit_has_at_least_one_outdoor_wall

          space.surfaces.each do |surface|
            next if surface.surfaceType.downcase != "wall"
            next if surface.outsideBoundaryCondition.downcase != "outdoors"

            unit_has_at_least_one_outdoor_wall = true
          end
        end
        assert(unit_has_at_least_one_outdoor_wall)
      end
    end
  end

  private

  def _get_test_model_osms
    parent_dir = File.absolute_path(File.join(File.dirname(__FILE__), "test_measures_osw"))
    measures_dir = File.join(parent_dir, "measures")
    skip unless File.exist?(measures_dir)

    osms = []
    Dir.glob(File.join(measures_dir, "*.osm")) do |osm|
      osms << osm
    end

    return osms
  end
end
