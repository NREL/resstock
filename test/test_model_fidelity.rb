require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require_relative 'minitest_helper'
require 'minitest/autorun'
require 'fileutils'
require 'csv'

class TestResStockModelFidelity < MiniTest::Test
  def test_model_fidelity
    # Check fidelity of each osm
    translator = OpenStudio::OSVersion::VersionTranslator.new
    parent_dir = File.absolute_path(File.join(File.dirname(__FILE__)))
    all_results = {}
    get_test_model_osms.each do |osm|
      path = OpenStudio::Path.new(osm)
      model = translator.loadModel(path)
      assert((not model.empty?))
      model = model.get

      # test_each_unit_has_at_least_one_outdoor_wall
      unless all_results.keys.include? "each_unit_has_at_least_one_outdoor_wall"
        all_results["each_unit_has_at_least_one_outdoor_wall"] = {}
      end
      osm_passes = true
      model.getBuildingUnits.each do |unit|
        unit_has_at_least_one_outdoor_wall = false
        unit.spaces.each do |space|
          next if unit_has_at_least_one_outdoor_wall

          space.surfaces.each do |surface|
            next if surface.surfaceType.downcase != "wall"
            next if surface.outsideBoundaryCondition.downcase != "outdoors"

            unit_has_at_least_one_outdoor_wall = true
            break
          end
        end
        unless unit_has_at_least_one_outdoor_wall
          osm_passes = false
        end
      end
      all_results["each_unit_has_at_least_one_outdoor_wall"][File.basename(osm)] = osm_passes

      # test_coil_heating_electric_is_sized_non_zero
      unless all_results.keys.include? "coil_heating_electric_is_sized_non_zero"
        all_results["coil_heating_electric_is_sized_non_zero"] = {}
      end
      osm_passes = true
      model.getAirLoopHVACUnitarySystems.each do |unitary_system|
        coil_heating_electric_is_sized_non_zero = true
        heating_coil = unitary_system.heatingCoil
        next unless heating_coil.is_initialized

        heating_coil = heating_coil.get
        next unless heating_coil.to_CoilHeatingElectric.is_initialized

        heating_coil = heating_coil.to_CoilHeatingElectric.get
        next unless heating_coil.nominalCapacity.is_initialized

        if coil.nominalCapacity.get == 0
          coil_heating_electric_is_sized_non_zero = false
        end
        unless coil_heating_electric_is_sized_non_zero
          osm_passes = false
        end
      end
      all_results["coil_heating_electric_is_sized_non_zero"][File.basename(osm)] = osm_passes

      # TODO: more tests
    end

    results_dir = File.join(parent_dir, "fidelity")
    _rm_path(results_dir)
    write_summary_results(results_dir, all_results)
  end

  private

  def get_test_model_osms
    parent_dir = File.absolute_path(File.join(File.dirname(__FILE__), "test_measures_osw"))
    measures_dir = File.join(parent_dir, "measures")
    if ENV.keys.include? "OSMDIR"
      measures_dir = ENV["OSMDIR"] # so you can run this on any folder with osm files in it
    end
    skip unless File.exist?(measures_dir)

    return Dir.glob(File.join(measures_dir, "**/*.osm"))
  end

  def write_summary_results(results_dir, results)
    Dir.mkdir(results_dir)
    csv_out = File.join(results_dir, "results.csv")

    column_headers = ["OSM"]
    csv_rows = {}
    results.each_with_index do |(test_name, summary), i|
      column_headers << test_name
      summary.each do |osm_name, osm_passes|
        unless csv_rows.keys.include? osm_name
          csv_rows[osm_name] = [nil] * results.keys.length
        end
        csv_rows[osm_name][i] = osm_passes
      end
    end

    CSV.open(csv_out, "wb") do |csv|
      csv << column_headers
      csv_rows.each do |osm_name, osm_passes|
        csv << [osm_name] + osm_passes
      end
    end
  end

  def _rm_path(path)
    if Dir.exists?(path)
      FileUtils.rm_r(path)
    end
    while true
      break if not Dir.exists?(path)

      sleep(0.01)
    end
  end
end
