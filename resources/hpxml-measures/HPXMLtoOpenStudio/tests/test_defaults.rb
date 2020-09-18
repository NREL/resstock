# frozen_string_literal: true

require_relative '../resources/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require 'fileutils'
require_relative '../measure.rb'
require_relative '../resources/util.rb'

class HPXMLtoOpenStudioDefaultsTest < MiniTest::Test
  ConstantDaySchedule = '0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1'
  ConstantMonthSchedule = '1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1'

  def before_setup
    @root_path = File.absolute_path(File.join(File.dirname(__FILE__), '..', '..'))
    @sample_files_path = File.join(@root_path, 'workflow', 'sample_files')
    @tmp_hpxml_path = File.join(@sample_files_path, 'tmp.xml')
    @tmp_output_path = File.join(@sample_files_path, 'tmp_output')
    FileUtils.mkdir_p(@tmp_output_path)

    @args_hash = {}
    @args_hash['hpxml_path'] = File.absolute_path(@tmp_hpxml_path)
    @args_hash['debug'] = true
    @args_hash['output_dir'] = File.absolute_path(@tmp_output_path)
  end

  def after_teardown
    File.delete(@tmp_hpxml_path) if File.exist? @tmp_hpxml_path
    FileUtils.rm_rf(@tmp_output_path)
  end

  def test_header
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base.xml')
    hpxml.header.timestep = 30
    hpxml.header.sim_begin_month = 2
    hpxml.header.sim_begin_day_of_month = 2
    hpxml.header.sim_end_month = 11
    hpxml.header.sim_end_day_of_month = 11
    hpxml.header.dst_enabled = false
    hpxml.header.dst_begin_month = 3
    hpxml.header.dst_begin_day_of_month = 3
    hpxml.header.dst_end_month = 10
    hpxml.header.dst_end_day_of_month = 10
    hpxml.header.use_max_load_for_heat_pumps = false
    hpxml.header.allow_increased_fixed_capacities = true
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_header_values(hpxml_default, 30, 2, 2, 11, 11, false, 3, 3, 10, 10, false, true)

    # Test defaults - DST not in weather file
    hpxml.header.timestep = nil
    hpxml.header.sim_begin_month = nil
    hpxml.header.sim_begin_day_of_month = nil
    hpxml.header.sim_end_month = nil
    hpxml.header.sim_end_day_of_month = nil
    hpxml.header.dst_enabled = nil
    hpxml.header.dst_begin_month = nil
    hpxml.header.dst_begin_day_of_month = nil
    hpxml.header.dst_end_month = nil
    hpxml.header.dst_end_day_of_month = nil
    hpxml.header.use_max_load_for_heat_pumps = nil
    hpxml.header.allow_increased_fixed_capacities = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_header_values(hpxml_default, 60, 1, 1, 12, 31, true, 3, 12, 11, 5, true, false)

    # Test defaults - DST in weather file
    hpxml = _create_hpxml('base-location-epw-filepath-AMY-2012.xml')
    hpxml.header.timestep = nil
    hpxml.header.sim_begin_month = nil
    hpxml.header.sim_begin_day_of_month = nil
    hpxml.header.sim_end_month = nil
    hpxml.header.sim_end_day_of_month = nil
    hpxml.header.dst_enabled = nil
    hpxml.header.dst_begin_month = nil
    hpxml.header.dst_begin_day_of_month = nil
    hpxml.header.dst_end_month = nil
    hpxml.header.dst_end_day_of_month = nil
    hpxml.header.use_max_load_for_heat_pumps = nil
    hpxml.header.allow_increased_fixed_capacities = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_header_values(hpxml_default, 60, 1, 1, 12, 31, true, 3, 11, 11, 4, true, false)
  end

  def test_site
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base.xml')
    hpxml.site.site_type = HPXML::SiteTypeRural
    hpxml.site.shelter_coefficient = 0.3
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_site_values(hpxml_default, HPXML::SiteTypeRural, 0.3)

    # Test defaults
    hpxml.site.site_type = nil
    hpxml.site.shelter_coefficient = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_site_values(hpxml_default, HPXML::SiteTypeSuburban, 0.5)
  end

  def test_occupancy
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base.xml')
    hpxml.building_occupancy.number_of_residents = 1
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_occupancy_values(hpxml_default, 1)

    # Test defaults
    hpxml.building_occupancy.number_of_residents = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_occupancy_values(hpxml_default, 3)
  end

  def test_building_construction
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base-enclosure-infil-flue.xml')
    hpxml.building_construction.number_of_bathrooms = 4.0
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_building_construction_values(hpxml_default, 21600, true, 4)

    # Test defaults w/ average ceiling height
    hpxml.building_construction.conditioned_building_volume = nil
    hpxml.building_construction.average_ceiling_height = 10
    hpxml.building_construction.has_flue_or_chimney = nil
    hpxml.building_construction.number_of_bathrooms = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_building_construction_values(hpxml_default, 27000, false, 2)
  end

  def test_attics
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base-atticroof-vented.xml')
    hpxml.attics[0].vented_attic_sla = 0.001
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_attic_values(hpxml_default, 0.001)

    # Test defaults
    hpxml.attics[0].vented_attic_sla = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_attic_values(hpxml_default, 1.0 / 300.0)
  end

  def test_foundations
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base-foundation-vented-crawlspace.xml')
    hpxml.foundations[0].vented_crawlspace_sla = 0.001
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_foundation_values(hpxml_default, 0.001)

    # Test defaults
    hpxml.foundations[0].vented_crawlspace_sla = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_foundation_values(hpxml_default, 1.0 / 150.0)
  end

  def test_infiltration
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base.xml')
    hpxml.air_infiltration_measurements[0].infiltration_volume = 25000
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_infiltration_values(hpxml_default, 25000)

    # Test defaults w/ conditioned basement
    hpxml.air_infiltration_measurements[0].infiltration_volume = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_infiltration_values(hpxml_default, 2700 * 8)

    # Test defaults w/o conditioned basement
    hpxml = _create_hpxml('base-foundation-slab.xml')
    hpxml.air_infiltration_measurements[0].infiltration_volume = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_infiltration_values(hpxml_default, 1350 * 8)
  end

  def test_roofs
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base.xml')
    hpxml.roofs[0].roof_type = HPXML::RoofTypeMetal
    hpxml.roofs[0].solar_absorptance = 0.77
    hpxml.roofs[0].roof_color = HPXML::ColorDark
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_roof_values(hpxml_default, HPXML::RoofTypeMetal, 0.77, HPXML::ColorDark)

    # Test defaults
    hpxml.roofs[0].roof_type = nil
    hpxml.roofs[0].solar_absorptance = nil
    hpxml.roofs[0].roof_color = HPXML::ColorLight
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_roof_values(hpxml_default, HPXML::RoofTypeAsphaltShingles, 0.75, HPXML::ColorLight)
  end

  def test_walls
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base.xml')
    hpxml.walls[0].siding = HPXML::SidingTypeFiberCement
    hpxml.walls[0].solar_absorptance = 0.66
    hpxml.walls[0].color = HPXML::ColorDark
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_wall_values(hpxml_default, HPXML::SidingTypeFiberCement, 0.66, HPXML::ColorDark)

    # Test defaults
    hpxml.walls[0].siding = nil
    hpxml.walls[0].solar_absorptance = nil
    hpxml.walls[0].color = HPXML::ColorLight
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_wall_values(hpxml_default, HPXML::SidingTypeWood, 0.5, HPXML::ColorLight)
  end

  def test_rim_joists
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base.xml')
    hpxml.rim_joists[0].siding = HPXML::SidingTypeBrick
    hpxml.rim_joists[0].solar_absorptance = 0.55
    hpxml.rim_joists[0].color = HPXML::ColorLight
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_rim_joist_values(hpxml_default, HPXML::SidingTypeBrick, 0.55, HPXML::ColorLight)

    # Test defaults
    hpxml.rim_joists[0].siding = nil
    hpxml.rim_joists[0].solar_absorptance = nil
    hpxml.rim_joists[0].color = HPXML::ColorDark
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_rim_joist_values(hpxml_default, HPXML::SidingTypeWood, 0.95, HPXML::ColorDark)
  end

  def test_windows
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base-enclosure-windows-interior-shading.xml')
    hpxml.windows.each do |window|
      window.fraction_operable = 0.5
      window.interior_shading_factor_summer = 0.66
      window.interior_shading_factor_winter = 0.77
    end
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    n_windows = hpxml_default.windows.size
    _test_default_window_values(hpxml_default, [0.66] * n_windows, [0.77] * n_windows, [0.5] * n_windows)

    # Test defaults
    hpxml.windows.each do |window|
      window.fraction_operable = nil
      window.interior_shading_factor_summer = nil
      window.interior_shading_factor_winter = nil
    end
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    n_windows = hpxml_default.windows.size
    _test_default_window_values(hpxml_default, [0.7] * n_windows, [0.85] * n_windows, [0.67] * n_windows)
  end

  def test_skylights
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base-enclosure-skylights.xml')
    hpxml.skylights.each do |skylight|
      skylight.interior_shading_factor_summer = 0.66
      skylight.interior_shading_factor_winter = 0.77
    end
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    n_skylights = hpxml_default.skylights.size
    _test_default_skylight_values(hpxml_default, [0.66] * n_skylights, [0.77] * n_skylights)

    # Test defaults
    hpxml.skylights.each do |skylight|
      skylight.interior_shading_factor_summer = nil
      skylight.interior_shading_factor_winter = nil
    end
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    n_skylights = hpxml_default.skylights.size
    _test_default_skylight_values(hpxml_default, [1.0] * n_skylights, [1.0] * n_skylights)
  end

  def test_air_conditioners
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base.xml')
    hpxml.cooling_systems[0].cooling_shr = 0.88
    hpxml.cooling_systems[0].compressor_type = HPXML::HVACCompressorTypeVariableSpeed
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_air_conditioner_values(hpxml_default, 0.88, HPXML::HVACCompressorTypeVariableSpeed)

    # Test defaults
    hpxml.cooling_systems[0].cooling_shr = nil
    hpxml.cooling_systems[0].compressor_type = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_air_conditioner_values(hpxml_default, 0.73, HPXML::HVACCompressorTypeSingleStage)
  end

  def test_boilers
    # Test inputs not overridden by defaults (in-unit boiler)
    hpxml = _create_hpxml('base-hvac-boiler-gas-only.xml')
    hpxml.heating_systems[0].electric_auxiliary_energy = 99.9
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_boiler_values(hpxml_default, 99.9)

    # Test defaults w/ in-unit boiler
    hpxml.heating_systems[0].electric_auxiliary_energy = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_boiler_values(hpxml_default, 170.0)

    # Test inputs not overridden by defaults (shared boiler)
    hpxml = _create_hpxml('base-hvac-shared-boiler-only-baseboard.xml')
    hpxml.heating_systems[0].shared_loop_watts = nil
    hpxml.heating_systems[0].electric_auxiliary_energy = 99.9
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_boiler_values(hpxml_default, 99.9)

    # Test defaults w/ shared boiler
    hpxml.heating_systems[0].electric_auxiliary_energy = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_boiler_values(hpxml_default, 220.0)
  end

  def test_ground_source_heat_pumps
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base-hvac-ground-to-air-heat-pump.xml')
    hpxml.heat_pumps[0].pump_watts_per_ton = 9.9
    hpxml.heat_pumps[0].fan_watts_per_cfm = 0.99
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_gshp_values(hpxml_default, 9.9, 0.99)

    # Test defaults
    hpxml.heat_pumps[0].pump_watts_per_ton = nil
    hpxml.heat_pumps[0].fan_watts_per_cfm = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_gshp_values(hpxml_default, 30.0, 0.5)
  end

  def test_hvac_distribution
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base.xml')
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    expected_supply_locations = ['attic - unvented']
    expected_return_locations = ['attic - unvented']
    expected_supply_areas = [150.0]
    expected_return_areas = [50.0]
    expected_n_return_registers = hpxml_default.building_construction.number_of_conditioned_floors
    _test_default_duct_values(hpxml_default, expected_supply_locations, expected_return_locations, expected_supply_areas, expected_return_areas, expected_n_return_registers)

    # Test defaults w/ conditioned basement
    hpxml.hvac_distributions.each do |hvac_distribution|
      hvac_distribution.ducts.each do |duct|
        duct.duct_location = nil
        duct.duct_surface_area = nil
      end
    end
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    expected_supply_locations = ['basement - conditioned']
    expected_return_locations = ['basement - conditioned']
    expected_supply_areas = [729.0]
    expected_return_areas = [270.0]
    expected_n_return_registers = hpxml_default.building_construction.number_of_conditioned_floors
    _test_default_duct_values(hpxml_default, expected_supply_locations, expected_return_locations, expected_supply_areas, expected_return_areas, expected_n_return_registers)

    # Test defaults w/ multiple foundations
    hpxml = _create_hpxml('base-foundation-multiple.xml')
    hpxml.hvac_distributions.each do |hvac_distribution|
      hvac_distribution.ducts.each do |duct|
        duct.duct_location = nil
        duct.duct_surface_area = nil
      end
    end
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    expected_supply_locations = ['basement - unconditioned']
    expected_return_locations = ['basement - unconditioned']
    expected_supply_areas = [364.5]
    expected_return_areas = [67.5]
    expected_n_return_registers = hpxml_default.building_construction.number_of_conditioned_floors
    _test_default_duct_values(hpxml_default, expected_supply_locations, expected_return_locations, expected_supply_areas, expected_return_areas, expected_n_return_registers)

    # Test defaults w/ foundation exposed to ambient
    hpxml = _create_hpxml('base-foundation-ambient.xml')
    hpxml.hvac_distributions.each do |hvac_distribution|
      hvac_distribution.ducts.each do |duct|
        duct.duct_location = nil
        duct.duct_surface_area = nil
      end
    end
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    expected_supply_locations = ['attic - unvented']
    expected_return_locations = ['attic - unvented']
    expected_supply_areas = [364.5]
    expected_return_areas = [67.5]
    expected_n_return_registers = hpxml_default.building_construction.number_of_conditioned_floors
    _test_default_duct_values(hpxml_default, expected_supply_locations, expected_return_locations, expected_supply_areas, expected_return_areas, expected_n_return_registers)

    # Test defaults w/ building/unit adjacent to other housing unit
    hpxml = _create_hpxml('base-enclosure-other-housing-unit.xml')
    hpxml.hvac_distributions.each do |hvac_distribution|
      hvac_distribution.ducts.each do |duct|
        duct.duct_location = nil
        duct.duct_surface_area = nil
      end
    end
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    expected_supply_locations = ['living space']
    expected_return_locations = ['living space']
    expected_supply_areas = [364.5]
    expected_return_areas = [67.5]
    expected_n_return_registers = hpxml_default.building_construction.number_of_conditioned_floors
    _test_default_duct_values(hpxml_default, expected_supply_locations, expected_return_locations, expected_supply_areas, expected_return_areas, expected_n_return_registers)

    # Test defaults w/ 2-story building
    hpxml = _create_hpxml('base-enclosure-2stories.xml')
    hpxml.hvac_distributions.each do |hvac_distribution|
      hvac_distribution.ducts.each do |duct|
        duct.duct_location = nil
        duct.duct_surface_area = nil
      end
    end
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    expected_supply_locations = ['basement - conditioned', 'living space']
    expected_return_locations = ['basement - conditioned', 'living space']
    expected_supply_areas = [820.13, 273.38]
    expected_return_areas = [455.63, 151.88]
    expected_n_return_registers = hpxml_default.building_construction.number_of_conditioned_floors
    _test_default_duct_values(hpxml_default, expected_supply_locations, expected_return_locations, expected_supply_areas, expected_return_areas, expected_n_return_registers)

    # Test defaults w/ 1-story building & multiple HVAC systems
    hpxml = _create_hpxml('base-hvac-multiple.xml')
    hpxml.hvac_distributions.each do |hvac_distribution|
      hvac_distribution.ducts.each do |duct|
        duct.duct_location = nil
        duct.duct_surface_area = nil
      end
    end
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    expected_supply_locations = ['basement - conditioned', 'basement - conditioned'] * hpxml_default.hvac_distributions.size
    expected_return_locations = ['basement - conditioned', 'basement - conditioned'] * hpxml_default.hvac_distributions.size
    expected_supply_areas = [91.125, 91.125] * hpxml_default.hvac_distributions.size
    expected_return_areas = [33.75, 33.75] * hpxml_default.hvac_distributions.size
    expected_n_return_registers = hpxml_default.building_construction.number_of_conditioned_floors
    _test_default_duct_values(hpxml_default, expected_supply_locations, expected_return_locations, expected_supply_areas, expected_return_areas, expected_n_return_registers)

    # Test defaults w/ 2-story building & multiple HVAC systems
    hpxml = _create_hpxml('base-hvac-multiple.xml')
    hpxml.building_construction.number_of_conditioned_floors_above_grade = 2
    hpxml.hvac_distributions.each do |hvac_distribution|
      hvac_distribution.ducts.each do |duct|
        duct.duct_location = nil
        duct.duct_surface_area = nil
      end
    end
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    expected_supply_locations = ['basement - conditioned', 'basement - conditioned', 'living space', 'living space'] * hpxml_default.hvac_distributions.size
    expected_return_locations = ['basement - conditioned', 'basement - conditioned', 'living space', 'living space'] * hpxml_default.hvac_distributions.size
    expected_supply_areas = [68.34, 68.34, 22.78, 22.78] * hpxml_default.hvac_distributions.size
    expected_return_areas = [25.31, 25.31, 8.44, 8.44] * hpxml_default.hvac_distributions.size
    expected_n_return_registers = hpxml_default.building_construction.number_of_conditioned_floors
    _test_default_duct_values(hpxml_default, expected_supply_locations, expected_return_locations, expected_supply_areas, expected_return_areas, expected_n_return_registers)
  end

  def test_water_heaters
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base.xml')
    hpxml.building_construction.residential_facility_type = HPXML::ResidentialTypeSFA
    hpxml.water_heating_systems.each do |wh|
      wh.is_shared_system = true
      wh.number_of_units_served = 2
      wh.heating_capacity = 15000.0
      wh.tank_volume = 40.0
      wh.recovery_efficiency = 0.95
    end
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_water_heater_values(hpxml_default, [true, 15000.0, 40.0, 0.95])

    # Test defaults w/ 3-bedroom house & electric storage water heater
    hpxml.water_heating_systems.each do |water_heating_system|
      water_heating_system.is_shared_system = nil
      next unless water_heating_system.water_heater_type == HPXML::WaterHeaterTypeStorage

      water_heating_system.heating_capacity = nil
      water_heating_system.tank_volume = nil
      water_heating_system.recovery_efficiency = nil
    end
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_water_heater_values(hpxml_default, [false, 18766.7, 50.0, 0.98])

    # Test defaults w/ 5-bedroom house & electric storage water heater
    hpxml = _create_hpxml('base-enclosure-beds-5.xml')
    hpxml.water_heating_systems.each do |water_heating_system|
      water_heating_system.is_shared_system = nil
      next unless water_heating_system.water_heater_type == HPXML::WaterHeaterTypeStorage

      water_heating_system.heating_capacity = nil
      water_heating_system.tank_volume = nil
      water_heating_system.recovery_efficiency = nil
    end
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_water_heater_values(hpxml_default, [false, 18766.7, 66.0, 0.98])

    # Test defaults w/ 3-bedroom house & 2 storage water heaters (1 electric and 1 natural gas)
    hpxml = _create_hpxml('base-dhw-multiple.xml')
    hpxml.water_heating_systems.each do |water_heating_system|
      water_heating_system.is_shared_system = nil
      next unless water_heating_system.water_heater_type == HPXML::WaterHeaterTypeStorage

      water_heating_system.heating_capacity = nil
      water_heating_system.tank_volume = nil
      water_heating_system.recovery_efficiency = nil
    end
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_water_heater_values(hpxml_default, [false, 15354.6, 50.0, 0.98],
                                      [false, 36000.0, 40.0, 0.756])
  end

  def test_hot_water_distribution
    # Test inputs not overridden by defaults -- standard
    hpxml = _create_hpxml('base.xml')
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_standard_distribution_values(hpxml_default, 50.0)

    # Test inputs not overridden by defaults -- recirculation
    hpxml = _create_hpxml('base-dhw-recirc-demand.xml')
    hpxml.hot_water_distributions[0].recirculation_pump_power = 65.0
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_recirc_distribution_values(hpxml_default, 50.0, 50.0, 65.0)

    # Test inputs not overridden by defaults -- shared recirculation
    hpxml = _create_hpxml('base-dhw-shared-water-heater-recirc.xml')
    hpxml.hot_water_distributions[0].shared_recirculation_pump_power = 333.0
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_shared_recirc_distribution_values(hpxml_default, 333.0)

    # Test defaults w/ conditioned basement
    hpxml = _create_hpxml('base.xml')
    hpxml.hot_water_distributions[0].standard_piping_length = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_standard_distribution_values(hpxml_default, 93.48)

    # Test defaults w/ unconditioned basement
    hpxml = _create_hpxml('base-foundation-unconditioned-basement.xml')
    hpxml.hot_water_distributions[0].standard_piping_length = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_standard_distribution_values(hpxml_default, 88.48)

    # Test defaults w/ 2-story building
    hpxml = _create_hpxml('base-enclosure-2stories.xml')
    hpxml.hot_water_distributions[0].standard_piping_length = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_standard_distribution_values(hpxml_default, 103.48)

    # Test defaults w/ recirculation & conditioned basement
    hpxml = _create_hpxml('base-dhw-recirc-demand.xml')
    hpxml.hot_water_distributions[0].recirculation_piping_length = nil
    hpxml.hot_water_distributions[0].recirculation_branch_piping_length = nil
    hpxml.hot_water_distributions[0].recirculation_pump_power = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_recirc_distribution_values(hpxml_default, 166.96, 10.0, 50.0)

    # Test defaults w/ recirculation & unconditioned basement
    hpxml = _create_hpxml('base-foundation-unconditioned-basement.xml')
    hpxml.hot_water_distributions.clear
    hpxml.hot_water_distributions.add(id: 'HotWaterDistribution',
                                      system_type: HPXML::DHWDistTypeRecirc,
                                      recirculation_control_type: HPXML::DHWRecirControlTypeSensor,
                                      pipe_r_value: 3.0)
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_recirc_distribution_values(hpxml_default, 156.96, 10.0, 50.0)

    # Test defaults w/ recirculation & 2-story building
    hpxml = _create_hpxml('base-enclosure-2stories.xml')
    hpxml.hot_water_distributions.clear
    hpxml.hot_water_distributions.add(id: 'HotWaterDistribution',
                                      system_type: HPXML::DHWDistTypeRecirc,
                                      recirculation_control_type: HPXML::DHWRecirControlTypeSensor,
                                      pipe_r_value: 3.0)
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_recirc_distribution_values(hpxml_default, 186.96, 10.0, 50.0)

    # Test defaults w/ shared recirculation
    hpxml = _create_hpxml('base-dhw-shared-water-heater-recirc.xml')
    hpxml.hot_water_distributions[0].shared_recirculation_pump_power = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_shared_recirc_distribution_values(hpxml_default, 220.0)
  end

  def test_water_fixtures
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base.xml')
    hpxml.water_heating.water_fixtures_usage_multiplier = 2.0
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_water_fixture_values(hpxml_default, 2.0)

    # Test defaults
    hpxml.water_heating.water_fixtures_usage_multiplier = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_water_fixture_values(hpxml_default, 1.0)
  end

  def test_solar_thermal_systems
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base-dhw-solar-direct-flat-plate.xml')
    hpxml.solar_thermal_systems[0].storage_volume = 55.0
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_solar_thermal_values(hpxml_default, 55.0)

    # Test defaults w/ collector area of 40 sqft
    hpxml.solar_thermal_systems[0].storage_volume = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_solar_thermal_values(hpxml_default, 60.0)

    # Test defaults w/ collector area of 100 sqft
    hpxml.solar_thermal_systems[0].collector_area = 100.0
    hpxml.solar_thermal_systems[0].storage_volume = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_solar_thermal_values(hpxml_default, 150.0)
  end

  def test_ventilation_fans
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base-mechvent-bath-kitchen-fans.xml')
    kitchen_fan = hpxml.ventilation_fans.select { |f| f.used_for_local_ventilation && f.fan_location == HPXML::LocationKitchen }[0]
    kitchen_fan.rated_flow_rate = 300
    kitchen_fan.fan_power = 20
    kitchen_fan.start_hour = 12
    kitchen_fan.quantity = 2
    kitchen_fan.hours_in_operation = 2
    bath_fan = hpxml.ventilation_fans.select { |f| f.used_for_local_ventilation && f.fan_location == HPXML::LocationBath }[0]
    bath_fan.rated_flow_rate = 80
    bath_fan.fan_power = 33
    bath_fan.start_hour = 6
    bath_fan.quantity = 3
    bath_fan.hours_in_operation = 3
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_kitchen_fan_values(hpxml_default, 2, 300, 2, 20, 12)
    _test_default_bath_fan_values(hpxml_default, 3, 80, 3, 33, 6)

    # Test defaults
    kitchen_fan.rated_flow_rate = nil
    kitchen_fan.fan_power = nil
    kitchen_fan.start_hour = nil
    kitchen_fan.quantity = nil
    kitchen_fan.hours_in_operation = nil
    bath_fan.rated_flow_rate = nil
    bath_fan.fan_power = nil
    bath_fan.start_hour = nil
    bath_fan.quantity = nil
    bath_fan.hours_in_operation = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_kitchen_fan_values(hpxml_default, 1, 100, 1, 30, 18)
    _test_default_bath_fan_values(hpxml_default, 2, 50, 1, 15, 7)
  end

  def test_ceiling_fans
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base-lighting-ceiling-fans.xml')
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_ceiling_fan_values(hpxml_default, 2, 100)

    # Test defaults
    hpxml.ceiling_fans.each do |ceiling_fan|
      ceiling_fan.quantity = nil
      ceiling_fan.efficiency = nil
    end
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_ceiling_fan_values(hpxml_default, 4, 70.4)
  end

  def test_pools
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base-misc-loads-large-uncommon.xml')
    pool = hpxml.pools[0]
    pool.heater_load_units = HPXML::UnitsKwhPerYear
    pool.heater_load_value = 1000
    pool.pump_kwh_per_year = 3000
    pool.heater_weekday_fractions = ConstantDaySchedule
    pool.heater_weekend_fractions = ConstantDaySchedule
    pool.heater_monthly_multipliers = ConstantMonthSchedule
    pool.pump_weekday_fractions = ConstantDaySchedule
    pool.pump_weekend_fractions = ConstantDaySchedule
    pool.pump_monthly_multipliers = ConstantMonthSchedule
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_pool_heater_values(hpxml_default, HPXML::UnitsKwhPerYear, 1000, ConstantDaySchedule, ConstantDaySchedule, ConstantMonthSchedule)
    _test_default_pool_pump_values(hpxml_default, 3000, ConstantDaySchedule, ConstantDaySchedule, ConstantMonthSchedule)

    # Test defaults
    pool = hpxml.pools[0]
    pool.heater_load_units = nil
    pool.heater_load_value = nil
    pool.pump_kwh_per_year = nil
    pool.heater_weekday_fractions = nil
    pool.heater_weekend_fractions = nil
    pool.heater_monthly_multipliers = nil
    pool.pump_weekday_fractions = nil
    pool.pump_weekend_fractions = nil
    pool.pump_monthly_multipliers = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_pool_heater_values(hpxml_default, HPXML::UnitsThermPerYear, 236, '0.003, 0.003, 0.003, 0.004, 0.008, 0.015, 0.026, 0.044, 0.084, 0.121, 0.127, 0.121, 0.120, 0.090, 0.075, 0.061, 0.037, 0.023, 0.013, 0.008, 0.004, 0.003, 0.003, 0.003', '0.003, 0.003, 0.003, 0.004, 0.008, 0.015, 0.026, 0.044, 0.084, 0.121, 0.127, 0.121, 0.120, 0.090, 0.075, 0.061, 0.037, 0.023, 0.013, 0.008, 0.004, 0.003, 0.003, 0.003', '1.154, 1.161, 1.013, 1.010, 1.013, 0.888, 0.883, 0.883, 0.888, 0.978, 0.974, 1.154')
    _test_default_pool_pump_values(hpxml_default, 2496, '0.003, 0.003, 0.003, 0.004, 0.008, 0.015, 0.026, 0.044, 0.084, 0.121, 0.127, 0.121, 0.120, 0.090, 0.075, 0.061, 0.037, 0.023, 0.013, 0.008, 0.004, 0.003, 0.003, 0.003', '0.003, 0.003, 0.003, 0.004, 0.008, 0.015, 0.026, 0.044, 0.084, 0.121, 0.127, 0.121, 0.120, 0.090, 0.075, 0.061, 0.037, 0.023, 0.013, 0.008, 0.004, 0.003, 0.003, 0.003', '1.154, 1.161, 1.013, 1.010, 1.013, 0.888, 0.883, 0.883, 0.888, 0.978, 0.974, 1.154')

    # Test defaults 2
    hpxml = _create_hpxml('base-misc-loads-large-uncommon2.xml')
    pool = hpxml.pools[0]
    pool.heater_load_units = nil
    pool.heater_load_value = nil
    pool.pump_kwh_per_year = nil
    pool.heater_weekday_fractions = nil
    pool.heater_weekend_fractions = nil
    pool.heater_monthly_multipliers = nil
    pool.pump_weekday_fractions = nil
    pool.pump_weekend_fractions = nil
    pool.pump_monthly_multipliers = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_pool_heater_values(hpxml_default, nil, nil, nil, nil, nil)
    _test_default_pool_pump_values(hpxml_default, 2496, '0.003, 0.003, 0.003, 0.004, 0.008, 0.015, 0.026, 0.044, 0.084, 0.121, 0.127, 0.121, 0.120, 0.090, 0.075, 0.061, 0.037, 0.023, 0.013, 0.008, 0.004, 0.003, 0.003, 0.003', '0.003, 0.003, 0.003, 0.004, 0.008, 0.015, 0.026, 0.044, 0.084, 0.121, 0.127, 0.121, 0.120, 0.090, 0.075, 0.061, 0.037, 0.023, 0.013, 0.008, 0.004, 0.003, 0.003, 0.003', '1.154, 1.161, 1.013, 1.010, 1.013, 0.888, 0.883, 0.883, 0.888, 0.978, 0.974, 1.154')
  end

  def test_hot_tubs
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base-misc-loads-large-uncommon.xml')
    hot_tub = hpxml.hot_tubs[0]
    hot_tub.heater_load_units = HPXML::UnitsThermPerYear
    hot_tub.heater_load_value = 1000
    hot_tub.pump_kwh_per_year = 3000
    hot_tub.heater_weekday_fractions = ConstantDaySchedule
    hot_tub.heater_weekend_fractions = ConstantDaySchedule
    hot_tub.heater_monthly_multipliers = ConstantMonthSchedule
    hot_tub.pump_weekday_fractions = ConstantDaySchedule
    hot_tub.pump_weekend_fractions = ConstantDaySchedule
    hot_tub.pump_monthly_multipliers = ConstantMonthSchedule
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_hot_tub_heater_values(hpxml_default, HPXML::UnitsThermPerYear, 1000, ConstantDaySchedule, ConstantDaySchedule, ConstantMonthSchedule)
    _test_default_hot_tub_pump_values(hpxml_default, 3000, ConstantDaySchedule, ConstantDaySchedule, ConstantMonthSchedule)

    # Test defaults
    hot_tub = hpxml.hot_tubs[0]
    hot_tub.heater_load_units = nil
    hot_tub.heater_load_value = nil
    hot_tub.pump_kwh_per_year = nil
    hot_tub.heater_weekday_fractions = nil
    hot_tub.heater_weekend_fractions = nil
    hot_tub.heater_monthly_multipliers = nil
    hot_tub.pump_weekday_fractions = nil
    hot_tub.pump_weekend_fractions = nil
    hot_tub.pump_monthly_multipliers = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_hot_tub_heater_values(hpxml_default, HPXML::UnitsKwhPerYear, 1125, '0.024, 0.029, 0.024, 0.029, 0.047, 0.067, 0.057, 0.024, 0.024, 0.019, 0.015, 0.014, 0.014, 0.014, 0.024, 0.058, 0.126, 0.122, 0.068, 0.061, 0.051, 0.043, 0.024, 0.024', '0.024, 0.029, 0.024, 0.029, 0.047, 0.067, 0.057, 0.024, 0.024, 0.019, 0.015, 0.014, 0.014, 0.014, 0.024, 0.058, 0.126, 0.122, 0.068, 0.061, 0.051, 0.043, 0.024, 0.024', '0.837, 0.835, 1.084, 1.084, 1.084, 1.096, 1.096, 1.096, 1.096, 0.931, 0.925, 0.837')
    _test_default_hot_tub_pump_values(hpxml_default, 1111, '0.024, 0.029, 0.024, 0.029, 0.047, 0.067, 0.057, 0.024, 0.024, 0.019, 0.015, 0.014, 0.014, 0.014, 0.024, 0.058, 0.126, 0.122, 0.068, 0.061, 0.051, 0.043, 0.024, 0.024', '0.024, 0.029, 0.024, 0.029, 0.047, 0.067, 0.057, 0.024, 0.024, 0.019, 0.015, 0.014, 0.014, 0.014, 0.024, 0.058, 0.126, 0.122, 0.068, 0.061, 0.051, 0.043, 0.024, 0.024', '0.921, 0.928, 0.921, 0.915, 0.921, 1.160, 1.158, 1.158, 1.160, 0.921, 0.915, 0.921')

    # Test defaults 2
    hpxml = _create_hpxml('base-misc-loads-large-uncommon2.xml')
    hot_tub = hpxml.hot_tubs[0]
    hot_tub.heater_load_units = nil
    hot_tub.heater_load_value = nil
    hot_tub.pump_kwh_per_year = nil
    hot_tub.heater_weekday_fractions = nil
    hot_tub.heater_weekend_fractions = nil
    hot_tub.heater_monthly_multipliers = nil
    hot_tub.pump_weekday_fractions = nil
    hot_tub.pump_weekend_fractions = nil
    hot_tub.pump_monthly_multipliers = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_hot_tub_heater_values(hpxml_default, HPXML::UnitsKwhPerYear, 225, '0.024, 0.029, 0.024, 0.029, 0.047, 0.067, 0.057, 0.024, 0.024, 0.019, 0.015, 0.014, 0.014, 0.014, 0.024, 0.058, 0.126, 0.122, 0.068, 0.061, 0.051, 0.043, 0.024, 0.024', '0.024, 0.029, 0.024, 0.029, 0.047, 0.067, 0.057, 0.024, 0.024, 0.019, 0.015, 0.014, 0.014, 0.014, 0.024, 0.058, 0.126, 0.122, 0.068, 0.061, 0.051, 0.043, 0.024, 0.024', '0.837, 0.835, 1.084, 1.084, 1.084, 1.096, 1.096, 1.096, 1.096, 0.931, 0.925, 0.837')
    _test_default_hot_tub_pump_values(hpxml_default, 1111, '0.024, 0.029, 0.024, 0.029, 0.047, 0.067, 0.057, 0.024, 0.024, 0.019, 0.015, 0.014, 0.014, 0.014, 0.024, 0.058, 0.126, 0.122, 0.068, 0.061, 0.051, 0.043, 0.024, 0.024', '0.024, 0.029, 0.024, 0.029, 0.047, 0.067, 0.057, 0.024, 0.024, 0.019, 0.015, 0.014, 0.014, 0.014, 0.024, 0.058, 0.126, 0.122, 0.068, 0.061, 0.051, 0.043, 0.024, 0.024', '0.921, 0.928, 0.921, 0.915, 0.921, 1.160, 1.158, 1.158, 1.160, 0.921, 0.915, 0.921')
  end

  def test_plug_loads
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base-misc-loads-large-uncommon.xml')
    tv_pl = hpxml.plug_loads.select { |pl| pl.plug_load_type == HPXML::PlugLoadTypeTelevision }[0]
    tv_pl.kWh_per_year = 1000
    tv_pl.frac_sensible = 0.6
    tv_pl.frac_latent = 0.3
    tv_pl.location = HPXML::LocationExterior
    tv_pl.weekday_fractions = ConstantDaySchedule
    tv_pl.weekend_fractions = ConstantDaySchedule
    tv_pl.monthly_multipliers = ConstantMonthSchedule
    other_pl = hpxml.plug_loads.select { |pl| pl.plug_load_type == HPXML::PlugLoadTypeOther }[0]
    other_pl.kWh_per_year = 2000
    other_pl.frac_sensible = 0.5
    other_pl.frac_latent = 0.4
    other_pl.location = HPXML::LocationExterior
    other_pl.weekday_fractions = ConstantDaySchedule
    other_pl.weekend_fractions = ConstantDaySchedule
    other_pl.monthly_multipliers = ConstantMonthSchedule
    veh_pl = hpxml.plug_loads.select { |pl| pl.plug_load_type == HPXML::PlugLoadTypeElectricVehicleCharging }[0]
    veh_pl.kWh_per_year = 4000
    veh_pl.frac_sensible = 0.4
    veh_pl.frac_latent = 0.5
    veh_pl.location = HPXML::LocationInterior
    veh_pl.weekday_fractions = ConstantDaySchedule
    veh_pl.weekend_fractions = ConstantDaySchedule
    veh_pl.monthly_multipliers = ConstantMonthSchedule
    wellpump_pl = hpxml.plug_loads.select { |pl| pl.plug_load_type == HPXML::PlugLoadTypeWellPump }[0]
    wellpump_pl.kWh_per_year = 3000
    wellpump_pl.frac_sensible = 0.3
    wellpump_pl.frac_latent = 0.6
    wellpump_pl.location = HPXML::LocationInterior
    wellpump_pl.weekday_fractions = ConstantDaySchedule
    wellpump_pl.weekend_fractions = ConstantDaySchedule
    wellpump_pl.monthly_multipliers = ConstantMonthSchedule
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_plug_load_values(hpxml_default, HPXML::PlugLoadTypeTelevision, 1000, 0.6, 0.3, HPXML::LocationExterior, ConstantDaySchedule, ConstantDaySchedule, ConstantMonthSchedule)
    _test_default_plug_load_values(hpxml_default, HPXML::PlugLoadTypeOther, 2000, 0.5, 0.4, HPXML::LocationExterior, ConstantDaySchedule, ConstantDaySchedule, ConstantMonthSchedule)
    _test_default_plug_load_values(hpxml_default, HPXML::PlugLoadTypeElectricVehicleCharging, 4000, 0.4, 0.5, HPXML::LocationInterior, ConstantDaySchedule, ConstantDaySchedule, ConstantMonthSchedule)
    _test_default_plug_load_values(hpxml_default, HPXML::PlugLoadTypeWellPump, 3000, 0.3, 0.6, HPXML::LocationInterior, ConstantDaySchedule, ConstantDaySchedule, ConstantMonthSchedule)

    # Test defaults
    hpxml.plug_loads.each do |plug_load|
      plug_load.kWh_per_year = nil
      plug_load.frac_sensible = nil
      plug_load.frac_latent = nil
      plug_load.location = nil
      plug_load.weekday_fractions = nil
      plug_load.weekend_fractions = nil
      plug_load.monthly_multipliers = nil
    end
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_plug_load_values(hpxml_default, HPXML::PlugLoadTypeTelevision, 620, 1.0, 0.0, HPXML::LocationInterior, '0.037, 0.018, 0.009, 0.007, 0.011, 0.018, 0.029, 0.040, 0.049, 0.058, 0.065, 0.072, 0.076, 0.086, 0.091, 0.102, 0.127, 0.156, 0.210, 0.294, 0.363, 0.344, 0.208, 0.090', '0.044, 0.022, 0.012, 0.008, 0.011, 0.014, 0.024, 0.043, 0.071, 0.094, 0.112, 0.123, 0.132, 0.156, 0.178, 0.196, 0.206, 0.213, 0.251, 0.330, 0.388, 0.358, 0.226, 0.103', '1.137, 1.129, 0.961, 0.969, 0.961, 0.993, 0.996, 0.96, 0.993, 0.867, 0.86, 1.137')
    _test_default_plug_load_values(hpxml_default, HPXML::PlugLoadTypeOther, 2457, 0.855, 0.045, HPXML::LocationInterior, '0.035, 0.033, 0.032, 0.031, 0.032, 0.033, 0.037, 0.042, 0.043, 0.043, 0.043, 0.044, 0.045, 0.045, 0.044, 0.046, 0.048, 0.052, 0.053, 0.05, 0.047, 0.045, 0.04, 0.036', '0.035, 0.033, 0.032, 0.031, 0.032, 0.033, 0.037, 0.042, 0.043, 0.043, 0.043, 0.044, 0.045, 0.045, 0.044, 0.046, 0.048, 0.052, 0.053, 0.05, 0.047, 0.045, 0.04, 0.036', '1.248, 1.257, 0.993, 0.989, 0.993, 0.827, 0.821, 0.821, 0.827, 0.99, 0.987, 1.248')
    _test_default_plug_load_values(hpxml_default, HPXML::PlugLoadTypeElectricVehicleCharging, 1667, 0.0, 0.0, HPXML::LocationExterior, '0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042', '0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042', '1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1')
    _test_default_plug_load_values(hpxml_default, HPXML::PlugLoadTypeWellPump, 441, 0.0, 0.0, HPXML::LocationExterior, '0.044, 0.023, 0.019, 0.015, 0.016, 0.018, 0.026, 0.033, 0.033, 0.032, 0.033, 0.033, 0.032, 0.032, 0.032, 0.033, 0.045, 0.057, 0.066, 0.076, 0.081, 0.086, 0.075, 0.065', '0.044, 0.023, 0.019, 0.015, 0.016, 0.018, 0.026, 0.033, 0.033, 0.032, 0.033, 0.033, 0.032, 0.032, 0.032, 0.033, 0.045, 0.057, 0.066, 0.076, 0.081, 0.086, 0.075, 0.065', '1.154, 1.161, 1.013, 1.010, 1.013, 0.888, 0.883, 0.883, 0.888, 0.978, 0.974, 1.154')
  end

  def test_fuel_loads
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base-misc-loads-large-uncommon.xml')
    gg_fl = hpxml.fuel_loads.select { |fl| fl.fuel_load_type == HPXML::FuelLoadTypeGrill }[0]
    gg_fl.therm_per_year = 1000
    gg_fl.frac_sensible = 0.6
    gg_fl.frac_latent = 0.3
    gg_fl.location = HPXML::LocationInterior
    gg_fl.weekday_fractions = ConstantDaySchedule
    gg_fl.weekend_fractions = ConstantDaySchedule
    gg_fl.monthly_multipliers = ConstantMonthSchedule
    gl_fl = hpxml.fuel_loads.select { |fl| fl.fuel_load_type == HPXML::FuelLoadTypeLighting }[0]
    gl_fl.therm_per_year = 2000
    gl_fl.frac_sensible = 0.5
    gl_fl.frac_latent = 0.4
    gl_fl.location = HPXML::LocationInterior
    gl_fl.weekday_fractions = ConstantDaySchedule
    gl_fl.weekend_fractions = ConstantDaySchedule
    gl_fl.monthly_multipliers = ConstantMonthSchedule
    gf_fl = hpxml.fuel_loads.select { |fl| fl.fuel_load_type == HPXML::FuelLoadTypeFireplace }[0]
    gf_fl.therm_per_year = 3000
    gf_fl.frac_sensible = 0.4
    gf_fl.frac_latent = 0.5
    gf_fl.location = HPXML::LocationExterior
    gf_fl.weekday_fractions = ConstantDaySchedule
    gf_fl.weekend_fractions = ConstantDaySchedule
    gf_fl.monthly_multipliers = ConstantMonthSchedule
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_fuel_load_values(hpxml_default, HPXML::FuelLoadTypeGrill, 1000, 0.6, 0.3, HPXML::LocationInterior, ConstantDaySchedule, ConstantDaySchedule, ConstantMonthSchedule)
    _test_default_fuel_load_values(hpxml_default, HPXML::FuelLoadTypeLighting, 2000, 0.5, 0.4, HPXML::LocationInterior, ConstantDaySchedule, ConstantDaySchedule, ConstantMonthSchedule)
    _test_default_fuel_load_values(hpxml_default, HPXML::FuelLoadTypeFireplace, 3000, 0.4, 0.5, HPXML::LocationExterior, ConstantDaySchedule, ConstantDaySchedule, ConstantMonthSchedule)

    # Test defaults
    hpxml.fuel_loads.each do |fuel_load|
      fuel_load.therm_per_year = nil
      fuel_load.frac_sensible = nil
      fuel_load.frac_latent = nil
      fuel_load.location = nil
      fuel_load.weekday_fractions = nil
      fuel_load.weekend_fractions = nil
      fuel_load.monthly_multipliers = nil
    end
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_fuel_load_values(hpxml_default, HPXML::FuelLoadTypeGrill, 33, 0.0, 0.0, HPXML::LocationExterior, '0.004, 0.001, 0.001, 0.002, 0.007, 0.012, 0.029, 0.046, 0.044, 0.041, 0.044, 0.046, 0.042, 0.038, 0.049, 0.059, 0.110, 0.161, 0.115, 0.070, 0.044, 0.019, 0.013, 0.007', '0.004, 0.001, 0.001, 0.002, 0.007, 0.012, 0.029, 0.046, 0.044, 0.041, 0.044, 0.046, 0.042, 0.038, 0.049, 0.059, 0.110, 0.161, 0.115, 0.070, 0.044, 0.019, 0.013, 0.007', '1.097, 1.097, 0.991, 0.987, 0.991, 0.890, 0.896, 0.896, 0.890, 1.085, 1.085, 1.097')
    _test_default_fuel_load_values(hpxml_default, HPXML::FuelLoadTypeLighting, 20, 0.0, 0.0, HPXML::LocationExterior, '0.044, 0.023, 0.019, 0.015, 0.016, 0.018, 0.026, 0.033, 0.033, 0.032, 0.033, 0.033, 0.032, 0.032, 0.032, 0.033, 0.045, 0.057, 0.066, 0.076, 0.081, 0.086, 0.075, 0.065', '0.044, 0.023, 0.019, 0.015, 0.016, 0.018, 0.026, 0.033, 0.033, 0.032, 0.033, 0.033, 0.032, 0.032, 0.032, 0.033, 0.045, 0.057, 0.066, 0.076, 0.081, 0.086, 0.075, 0.065', '1.154, 1.161, 1.013, 1.010, 1.013, 0.888, 0.883, 0.883, 0.888, 0.978, 0.974, 1.154')
    _test_default_fuel_load_values(hpxml_default, HPXML::FuelLoadTypeFireplace, 67, 0.5, 0.1, HPXML::LocationInterior, '0.044, 0.023, 0.019, 0.015, 0.016, 0.018, 0.026, 0.033, 0.033, 0.032, 0.033, 0.033, 0.032, 0.032, 0.032, 0.033, 0.045, 0.057, 0.066, 0.076, 0.081, 0.086, 0.075, 0.065', '0.044, 0.023, 0.019, 0.015, 0.016, 0.018, 0.026, 0.033, 0.033, 0.032, 0.033, 0.033, 0.032, 0.032, 0.032, 0.033, 0.045, 0.057, 0.066, 0.076, 0.081, 0.086, 0.075, 0.065', '1.154, 1.161, 1.013, 1.010, 1.013, 0.888, 0.883, 0.883, 0.888, 0.978, 0.974, 1.154')
  end

  def test_clothes_washers
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base.xml')
    hpxml.building_construction.residential_facility_type = HPXML::ResidentialTypeSFA
    hpxml.water_heating_systems[0].is_shared_system = true
    hpxml.water_heating_systems[0].number_of_units_served = 6
    hpxml.water_heating_systems[0].fraction_dhw_load_served = 0
    hpxml.clothes_washers[0].location = HPXML::LocationBasementConditioned
    hpxml.clothes_washers[0].is_shared_appliance = true
    hpxml.clothes_washers[0].usage_multiplier = 1.5
    hpxml.clothes_washers[0].water_heating_system_idref = hpxml.water_heating_systems[0].id
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_clothes_washer_values(hpxml_default, true, HPXML::LocationBasementConditioned, 1.21, 380.0, 0.12, 1.09, 27.0, 3.2, 6.0, 1.5)

    # Test defaults
    hpxml.clothes_washers[0].is_shared_appliance = nil
    hpxml.clothes_washers[0].location = nil
    hpxml.clothes_washers[0].integrated_modified_energy_factor = nil
    hpxml.clothes_washers[0].rated_annual_kwh = nil
    hpxml.clothes_washers[0].label_electric_rate = nil
    hpxml.clothes_washers[0].label_gas_rate = nil
    hpxml.clothes_washers[0].label_annual_gas_cost = nil
    hpxml.clothes_washers[0].capacity = nil
    hpxml.clothes_washers[0].label_usage = nil
    hpxml.clothes_washers[0].usage_multiplier = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_clothes_washer_values(hpxml_default, false, HPXML::LocationLivingSpace, 1.0, 400.0, 0.12, 1.09, 27.0, 3.0, 6.0, 1.0)

    # Test defaults before 301-2019 Addendum A
    hpxml = _create_hpxml('base.xml')
    hpxml.header.eri_calculation_version = '2019'
    hpxml.clothes_washers[0].is_shared_appliance = nil
    hpxml.clothes_washers[0].location = nil
    hpxml.clothes_washers[0].integrated_modified_energy_factor = nil
    hpxml.clothes_washers[0].rated_annual_kwh = nil
    hpxml.clothes_washers[0].label_electric_rate = nil
    hpxml.clothes_washers[0].label_gas_rate = nil
    hpxml.clothes_washers[0].label_annual_gas_cost = nil
    hpxml.clothes_washers[0].capacity = nil
    hpxml.clothes_washers[0].label_usage = nil
    hpxml.clothes_washers[0].usage_multiplier = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_clothes_washer_values(hpxml_default, false, HPXML::LocationLivingSpace, 0.331, 704.0, 0.08, 0.58, 23.0, 2.874, 6.0, 1.0)
  end

  def test_clothes_dryers
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base.xml')
    hpxml.building_construction.residential_facility_type = HPXML::ResidentialTypeSFA
    hpxml.water_heating_systems[0].is_shared_system = true
    hpxml.water_heating_systems[0].number_of_units_served = 6
    hpxml.water_heating_systems[0].fraction_dhw_load_served = 0
    hpxml.clothes_dryers[0].location = HPXML::LocationBasementConditioned
    hpxml.clothes_dryers[0].is_shared_appliance = true
    hpxml.clothes_dryers[0].control_type = HPXML::ClothesDryerControlTypeMoisture
    hpxml.clothes_dryers[0].combined_energy_factor = 3.33
    hpxml.clothes_dryers[0].usage_multiplier = 1.1
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_clothes_dryer_values(hpxml_default, true, HPXML::LocationBasementConditioned, HPXML::ClothesDryerControlTypeMoisture, 3.33, 1.1)

    # Test defaults w/ electric clothes dryer
    hpxml.clothes_dryers[0].location = nil
    hpxml.clothes_dryers[0].is_shared_appliance = false
    hpxml.clothes_dryers[0].control_type = nil
    hpxml.clothes_dryers[0].combined_energy_factor = nil
    hpxml.clothes_dryers[0].usage_multiplier = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_clothes_dryer_values(hpxml_default, false, HPXML::LocationLivingSpace, HPXML::ClothesDryerControlTypeTimer, 3.01, 1.0)

    # Test defaults w/ gas clothes dryer
    hpxml.clothes_dryers[0].fuel_type = HPXML::FuelTypeNaturalGas
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_clothes_dryer_values(hpxml_default, false, HPXML::LocationLivingSpace, HPXML::ClothesDryerControlTypeTimer, 3.01, 1.0)

    # Test defaults w/ electric clothes dryer before 301-2019 Addendum A
    hpxml.header.eri_calculation_version = '2019'
    hpxml.clothes_dryers[0].fuel_type = HPXML::FuelTypeElectricity
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_clothes_dryer_values(hpxml_default, false, HPXML::LocationLivingSpace, HPXML::ClothesDryerControlTypeTimer, 2.62, 1.0)

    # Test defaults w/ gas clothes dryer before 301-2019 Addendum A
    hpxml.clothes_dryers[0].fuel_type = HPXML::FuelTypeNaturalGas
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_clothes_dryer_values(hpxml_default, false, HPXML::LocationLivingSpace, HPXML::ClothesDryerControlTypeTimer, 2.32, 1.0)
  end

  def test_dishwashers
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base.xml')
    hpxml.building_construction.residential_facility_type = HPXML::ResidentialTypeSFA
    hpxml.water_heating_systems[0].is_shared_system = true
    hpxml.water_heating_systems[0].number_of_units_served = 6
    hpxml.water_heating_systems[0].fraction_dhw_load_served = 0
    hpxml.dishwashers[0].location = HPXML::LocationBasementConditioned
    hpxml.dishwashers[0].is_shared_appliance = true
    hpxml.dishwashers[0].usage_multiplier = 1.3
    hpxml.dishwashers[0].water_heating_system_idref = hpxml.water_heating_systems[0].id
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_dishwasher_values(hpxml_default, true, HPXML::LocationBasementConditioned, 307.0, 0.12, 1.09, 22.32, 4.0, 12, 1.3)

    # Test defaults
    hpxml.dishwashers[0].is_shared_appliance = nil
    hpxml.dishwashers[0].location = nil
    hpxml.dishwashers[0].rated_annual_kwh = nil
    hpxml.dishwashers[0].label_electric_rate = nil
    hpxml.dishwashers[0].label_gas_rate = nil
    hpxml.dishwashers[0].label_annual_gas_cost = nil
    hpxml.dishwashers[0].label_usage = nil
    hpxml.dishwashers[0].place_setting_capacity = nil
    hpxml.dishwashers[0].usage_multiplier = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_dishwasher_values(hpxml_default, false, HPXML::LocationLivingSpace, 467.0, 0.12, 1.09, 33.12, 4.0, 12, 1.0)

    # Test defaults before 301-2019 Addendum A
    hpxml.header.eri_calculation_version = '2019'
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_dishwasher_values(hpxml_default, false, HPXML::LocationLivingSpace, 467.0, 0.12, 1.09, 33.12, 4.0, 12, 1.0)
  end

  def test_refrigerators
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base.xml')
    hpxml.refrigerators[0].location = HPXML::LocationBasementConditioned
    hpxml.refrigerators[0].usage_multiplier = 1.2
    hpxml.refrigerators[0].weekday_fractions = ConstantDaySchedule
    hpxml.refrigerators[0].weekend_fractions = ConstantDaySchedule
    hpxml.refrigerators[0].monthly_multipliers = ConstantMonthSchedule
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_refrigerator_values(hpxml_default, HPXML::LocationBasementConditioned, 650.0, 1.2, ConstantDaySchedule, ConstantDaySchedule, ConstantMonthSchedule)

    # Test defaults
    hpxml.refrigerators[0].location = nil
    hpxml.refrigerators[0].rated_annual_kwh = nil
    hpxml.refrigerators[0].usage_multiplier = nil
    hpxml.refrigerators[0].weekday_fractions = nil
    hpxml.refrigerators[0].weekend_fractions = nil
    hpxml.refrigerators[0].monthly_multipliers = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_refrigerator_values(hpxml_default, HPXML::LocationLivingSpace, 691.0, 1.0, '0.040, 0.039, 0.038, 0.037, 0.036, 0.036, 0.038, 0.040, 0.041, 0.041, 0.040, 0.040, 0.042, 0.042, 0.042, 0.041, 0.044, 0.048, 0.050, 0.048, 0.047, 0.046, 0.044, 0.041', '0.040, 0.039, 0.038, 0.037, 0.036, 0.036, 0.038, 0.040, 0.041, 0.041, 0.040, 0.040, 0.042, 0.042, 0.042, 0.041, 0.044, 0.048, 0.050, 0.048, 0.047, 0.046, 0.044, 0.041', '0.837, 0.835, 1.084, 1.084, 1.084, 1.096, 1.096, 1.096, 1.096, 0.931, 0.925, 0.837')

    # Test defaults w/ refrigerator in 5-bedroom house
    hpxml.building_construction.number_of_bedrooms = 5
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_refrigerator_values(hpxml_default, HPXML::LocationLivingSpace, 727.0, 1.0, '0.040, 0.039, 0.038, 0.037, 0.036, 0.036, 0.038, 0.040, 0.041, 0.041, 0.040, 0.040, 0.042, 0.042, 0.042, 0.041, 0.044, 0.048, 0.050, 0.048, 0.047, 0.046, 0.044, 0.041', '0.040, 0.039, 0.038, 0.037, 0.036, 0.036, 0.038, 0.040, 0.041, 0.041, 0.040, 0.040, 0.042, 0.042, 0.042, 0.041, 0.044, 0.048, 0.050, 0.048, 0.047, 0.046, 0.044, 0.041', '0.837, 0.835, 1.084, 1.084, 1.084, 1.096, 1.096, 1.096, 1.096, 0.931, 0.925, 0.837')

    # Test defaults before 301-2019 Addendum A
    hpxml.header.eri_calculation_version = '2019'
    hpxml.building_construction.number_of_bedrooms = 3
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_refrigerator_values(hpxml_default, HPXML::LocationLivingSpace, 691.0, 1.0, '0.040, 0.039, 0.038, 0.037, 0.036, 0.036, 0.038, 0.040, 0.041, 0.041, 0.040, 0.040, 0.042, 0.042, 0.042, 0.041, 0.044, 0.048, 0.050, 0.048, 0.047, 0.046, 0.044, 0.041', '0.040, 0.039, 0.038, 0.037, 0.036, 0.036, 0.038, 0.040, 0.041, 0.041, 0.040, 0.040, 0.042, 0.042, 0.042, 0.041, 0.044, 0.048, 0.050, 0.048, 0.047, 0.046, 0.044, 0.041', '0.837, 0.835, 1.084, 1.084, 1.084, 1.096, 1.096, 1.096, 1.096, 0.931, 0.925, 0.837')
  end

  def test_cooking_ranges
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base.xml')
    hpxml.cooking_ranges[0].location = HPXML::LocationBasementConditioned
    hpxml.cooking_ranges[0].is_induction = true
    hpxml.cooking_ranges[0].usage_multiplier = 1.1
    hpxml.cooking_ranges[0].weekday_fractions = ConstantDaySchedule
    hpxml.cooking_ranges[0].weekend_fractions = ConstantDaySchedule
    hpxml.cooking_ranges[0].monthly_multipliers = ConstantMonthSchedule
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_cooking_range_values(hpxml_default, HPXML::LocationBasementConditioned, true, 1.1, ConstantDaySchedule, ConstantDaySchedule, ConstantMonthSchedule)

    # Test defaults
    hpxml.cooking_ranges[0].location = nil
    hpxml.cooking_ranges[0].is_induction = nil
    hpxml.cooking_ranges[0].usage_multiplier = nil
    hpxml.cooking_ranges[0].weekday_fractions = nil
    hpxml.cooking_ranges[0].weekend_fractions = nil
    hpxml.cooking_ranges[0].monthly_multipliers = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_cooking_range_values(hpxml_default, HPXML::LocationLivingSpace, false, 1.0, '0.007, 0.007, 0.004, 0.004, 0.007, 0.011, 0.025, 0.042, 0.046, 0.048, 0.042, 0.050, 0.057, 0.046, 0.057, 0.044, 0.092, 0.150, 0.117, 0.060, 0.035, 0.025, 0.016, 0.011', '0.007, 0.007, 0.004, 0.004, 0.007, 0.011, 0.025, 0.042, 0.046, 0.048, 0.042, 0.050, 0.057, 0.046, 0.057, 0.044, 0.092, 0.150, 0.117, 0.060, 0.035, 0.025, 0.016, 0.011', '1.097, 1.097, 0.991, 0.987, 0.991, 0.890, 0.896, 0.896, 0.890, 1.085, 1.085, 1.097')

    # Test defaults before 301-2019 Addendum A
    hpxml.header.eri_calculation_version = '2019'
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_cooking_range_values(hpxml_default, HPXML::LocationLivingSpace, false, 1.0, '0.007, 0.007, 0.004, 0.004, 0.007, 0.011, 0.025, 0.042, 0.046, 0.048, 0.042, 0.050, 0.057, 0.046, 0.057, 0.044, 0.092, 0.150, 0.117, 0.060, 0.035, 0.025, 0.016, 0.011', '0.007, 0.007, 0.004, 0.004, 0.007, 0.011, 0.025, 0.042, 0.046, 0.048, 0.042, 0.050, 0.057, 0.046, 0.057, 0.044, 0.092, 0.150, 0.117, 0.060, 0.035, 0.025, 0.016, 0.011', '1.097, 1.097, 0.991, 0.987, 0.991, 0.890, 0.896, 0.896, 0.890, 1.085, 1.085, 1.097')
  end

  def test_ovens
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base.xml')
    hpxml.ovens[0].is_convection = true
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_oven_values(hpxml_default, true)

    # Test defaults
    hpxml.ovens[0].is_convection = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_oven_values(hpxml_default, false)

    # Test defaults before 301-2019 Addendum A
    hpxml.header.eri_calculation_version = '2019'
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_oven_values(hpxml_default, false)
  end

  def test_extra_refrigerators
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base-misc-loads-large-uncommon.xml')
    hpxml.refrigerators.each do |refrigerator|
      refrigerator.location = HPXML::LocationBasementConditioned
      refrigerator.rated_annual_kwh = 333.0
      refrigerator.usage_multiplier = 1.5
      refrigerator.weekday_fractions = ConstantDaySchedule
      refrigerator.weekend_fractions = ConstantDaySchedule
      refrigerator.monthly_multipliers = ConstantMonthSchedule
    end
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_extra_refrigerators_values(hpxml_default, HPXML::LocationBasementConditioned, 333.0, 1.5, ConstantDaySchedule, ConstantDaySchedule, ConstantMonthSchedule)

    # Test defaults
    hpxml.refrigerators.each do |refrigerator|
      refrigerator.location = nil
      refrigerator.rated_annual_kwh = nil
      refrigerator.usage_multiplier = nil
      refrigerator.weekday_fractions = nil
      refrigerator.weekend_fractions = nil
      refrigerator.monthly_multipliers = nil
    end
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_extra_refrigerators_values(hpxml_default, HPXML::LocationGarage, 244.0, 1.0, '0.040, 0.039, 0.038, 0.037, 0.036, 0.036, 0.038, 0.040, 0.041, 0.041, 0.040, 0.040, 0.042, 0.042, 0.042, 0.041, 0.044, 0.048, 0.050, 0.048, 0.047, 0.046, 0.044, 0.041', '0.040, 0.039, 0.038, 0.037, 0.036, 0.036, 0.038, 0.040, 0.041, 0.041, 0.040, 0.040, 0.042, 0.042, 0.042, 0.041, 0.044, 0.048, 0.050, 0.048, 0.047, 0.046, 0.044, 0.041', '0.837, 0.835, 1.084, 1.084, 1.084, 1.096, 1.096, 1.096, 1.096, 0.931, 0.925, 0.837')
  end

  def test_freezers
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base-misc-loads-large-uncommon.xml')
    hpxml.freezers.each do |freezer|
      freezer.location = HPXML::LocationBasementConditioned
      freezer.rated_annual_kwh = 333.0
      freezer.usage_multiplier = 1.5
      freezer.weekday_fractions = ConstantDaySchedule
      freezer.weekend_fractions = ConstantDaySchedule
      freezer.monthly_multipliers = ConstantMonthSchedule
    end
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_freezers_values(hpxml_default, HPXML::LocationBasementConditioned, 333.0, 1.5, ConstantDaySchedule, ConstantDaySchedule, ConstantMonthSchedule)

    # Test defaults
    hpxml.freezers.each do |freezer|
      freezer.location = nil
      freezer.rated_annual_kwh = nil
      freezer.usage_multiplier = nil
      freezer.weekday_fractions = nil
      freezer.weekend_fractions = nil
      freezer.monthly_multipliers = nil
    end
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_freezers_values(hpxml_default, HPXML::LocationGarage, 320.0, 1.0, '0.040, 0.039, 0.038, 0.037, 0.036, 0.036, 0.038, 0.040, 0.041, 0.041, 0.040, 0.040, 0.042, 0.042, 0.042, 0.041, 0.044, 0.048, 0.050, 0.048, 0.047, 0.046, 0.044, 0.041', '0.040, 0.039, 0.038, 0.037, 0.036, 0.036, 0.038, 0.040, 0.041, 0.041, 0.040, 0.040, 0.042, 0.042, 0.042, 0.041, 0.044, 0.048, 0.050, 0.048, 0.047, 0.046, 0.044, 0.041', '0.837, 0.835, 1.084, 1.084, 1.084, 1.096, 1.096, 1.096, 1.096, 0.931, 0.925, 0.837')
  end

  def test_lighting
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base.xml')
    hpxml.lighting.interior_usage_multiplier = 2.0
    hpxml.lighting.garage_usage_multiplier = 2.0
    hpxml.lighting.exterior_usage_multiplier = 2.0
    hpxml.lighting.interior_weekday_fractions = ConstantDaySchedule
    hpxml.lighting.interior_weekend_fractions = ConstantDaySchedule
    hpxml.lighting.interior_monthly_multipliers = ConstantMonthSchedule
    hpxml.lighting.exterior_weekday_fractions = ConstantDaySchedule
    hpxml.lighting.exterior_weekend_fractions = ConstantDaySchedule
    hpxml.lighting.exterior_monthly_multipliers = ConstantMonthSchedule
    hpxml.lighting.garage_weekday_fractions = ConstantDaySchedule
    hpxml.lighting.garage_weekend_fractions = ConstantDaySchedule
    hpxml.lighting.garage_monthly_multipliers = ConstantMonthSchedule
    hpxml.lighting.holiday_exists = true
    hpxml.lighting.holiday_kwh_per_day = 0.7
    hpxml.lighting.holiday_period_begin_month = 11
    hpxml.lighting.holiday_period_begin_day_of_month = 19
    hpxml.lighting.holiday_period_end_month = 12
    hpxml.lighting.holiday_period_end_day_of_month = 31
    hpxml.lighting.holiday_weekday_fractions = ConstantDaySchedule
    hpxml.lighting.holiday_weekend_fractions = ConstantDaySchedule
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_lighting_values(hpxml_default, 2.0, 2.0, 2.0,
                                  { int_wk_sch: ConstantDaySchedule,
                                    int_wknd_sch: ConstantDaySchedule,
                                    int_month_mult: ConstantMonthSchedule,
                                    ext_wk_sch: ConstantDaySchedule,
                                    ext_wknd_sch: ConstantDaySchedule,
                                    ext_month_mult: ConstantMonthSchedule,
                                    grg_wk_sch: ConstantDaySchedule,
                                    grg_wknd_sch: ConstantDaySchedule,
                                    grg_month_mult: ConstantMonthSchedule,
                                    hol_kwh_per_day: 0.7,
                                    hol_begin_month: 11,
                                    hol_begin_day_of_month: 19,
                                    hol_end_month: 12,
                                    hol_end_day_of_month: 31,
                                    hol_wk_sch: ConstantDaySchedule,
                                    hol_wknd_sch: ConstantDaySchedule })

    # Test defaults
    hpxml.lighting.interior_usage_multiplier = nil
    hpxml.lighting.garage_usage_multiplier = nil
    hpxml.lighting.exterior_usage_multiplier = nil
    hpxml.lighting.interior_weekday_fractions = nil
    hpxml.lighting.interior_weekend_fractions = nil
    hpxml.lighting.interior_monthly_multipliers = nil
    hpxml.lighting.exterior_weekday_fractions = nil
    hpxml.lighting.exterior_weekend_fractions = nil
    hpxml.lighting.exterior_monthly_multipliers = nil
    hpxml.lighting.garage_weekday_fractions = nil
    hpxml.lighting.garage_weekend_fractions = nil
    hpxml.lighting.garage_monthly_multipliers = nil
    hpxml.lighting.holiday_exists = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_lighting_values(hpxml_default, 1.0, 1.0, 1.0,
                                  { ext_wk_sch: '0.046, 0.046, 0.046, 0.046, 0.046, 0.037, 0.035, 0.034, 0.033, 0.028, 0.022, 0.015, 0.012, 0.011, 0.011, 0.012, 0.019, 0.037, 0.049, 0.065, 0.091, 0.105, 0.091, 0.063',
                                    ext_wknd_sch: '0.046, 0.046, 0.045, 0.045, 0.046, 0.045, 0.044, 0.041, 0.036, 0.03, 0.024, 0.016, 0.012, 0.011, 0.011, 0.012, 0.019, 0.038, 0.048, 0.06, 0.083, 0.098, 0.085, 0.059',
                                    ext_month_mult: '1.248, 1.257, 0.993, 0.989, 0.993, 0.827, 0.821, 0.821, 0.827, 0.99, 0.987, 1.248' })

    # Test defaults w/ garage
    hpxml = _create_hpxml('base-enclosure-garage.xml')
    hpxml.lighting.interior_usage_multiplier = nil
    hpxml.lighting.garage_usage_multiplier = nil
    hpxml.lighting.exterior_usage_multiplier = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_lighting_values(hpxml_default, 1.0, 1.0, 1.0,
                                  { ext_wk_sch: '0.046, 0.046, 0.046, 0.046, 0.046, 0.037, 0.035, 0.034, 0.033, 0.028, 0.022, 0.015, 0.012, 0.011, 0.011, 0.012, 0.019, 0.037, 0.049, 0.065, 0.091, 0.105, 0.091, 0.063',
                                    ext_wknd_sch: '0.046, 0.046, 0.045, 0.045, 0.046, 0.045, 0.044, 0.041, 0.036, 0.03, 0.024, 0.016, 0.012, 0.011, 0.011, 0.012, 0.019, 0.038, 0.048, 0.06, 0.083, 0.098, 0.085, 0.059',
                                    ext_month_mult: '1.248, 1.257, 0.993, 0.989, 0.993, 0.827, 0.821, 0.821, 0.827, 0.99, 0.987, 1.248',
                                    grg_wk_sch: '0.046, 0.046, 0.046, 0.046, 0.046, 0.037, 0.035, 0.034, 0.033, 0.028, 0.022, 0.015, 0.012, 0.011, 0.011, 0.012, 0.019, 0.037, 0.049, 0.065, 0.091, 0.105, 0.091, 0.063',
                                    grg_wknd_sch: '0.046, 0.046, 0.045, 0.045, 0.046, 0.045, 0.044, 0.041, 0.036, 0.03, 0.024, 0.016, 0.012, 0.011, 0.011, 0.012, 0.019, 0.038, 0.048, 0.06, 0.083, 0.098, 0.085, 0.059',
                                    grg_month_mult: '1.248, 1.257, 0.993, 0.989, 0.993, 0.827, 0.821, 0.821, 0.827, 0.99, 0.987, 1.248' })
  end

  def test_pv_systems
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base-pv.xml')
    hpxml.building_construction.residential_facility_type = HPXML::ResidentialTypeSFA
    hpxml.pv_systems.each do |pv|
      pv.is_shared_system = true
      pv.number_of_bedrooms_served = 20
      pv.inverter_efficiency = 0.90
      pv.system_losses_fraction = 0.20
    end
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    expected_interver_efficiency = [0.90, 0.90]
    expected_system_loss_frac = [0.20, 0.20]
    _test_default_pv_system_values(hpxml_default, expected_interver_efficiency, expected_system_loss_frac, true)

    # Test defaults w/o year modules manufactured
    hpxml.pv_systems.each do |pv|
      pv.is_shared_system = nil
      pv.inverter_efficiency = nil
      pv.system_losses_fraction = nil
    end
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    expected_interver_efficiency = [0.96, 0.96]
    expected_system_loss_frac = [0.14, 0.14]
    _test_default_pv_system_values(hpxml_default, expected_interver_efficiency, expected_system_loss_frac, false)

    # Test defaults w/ year modules manufactured
    hpxml.pv_systems.each do |pv|
      pv.year_modules_manufactured = 2010
    end
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    expected_interver_efficiency = [0.96, 0.96]
    expected_system_loss_frac = [0.182, 0.182]
    _test_default_pv_system_values(hpxml_default, expected_interver_efficiency, expected_system_loss_frac, false)
  end

  def _test_measure()
    # create an instance of the measure
    measure = HPXMLtoOpenStudio.new

    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    model = OpenStudio::Model::Model.new

    # get arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if @args_hash.has_key?(arg.name)
        assert(temp_arg_var.setValue(@args_hash[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end

    # run the measure
    measure.run(model, runner, argument_map)
    result = runner.result

    # show the output
    show_output(result) unless result.value.valueName == 'Success'

    # assert that it ran correctly
    assert_equal('Success', result.value.valueName)

    hpxml_default = HPXML.new(hpxml_path: File.join(@tmp_output_path, 'in.xml'))

    return hpxml_default
  end

  def _test_default_header_values(hpxml, tstep, sim_begin_month, sim_begin_day, sim_end_month, sim_end_day,
                                  dst_enabled, dst_begin_month, dst_begin_day_of_month, dst_end_month, dst_end_day_of_month,
                                  use_max_load_for_heat_pumps, allow_increased_fixed_capacities)
    assert_equal(tstep, hpxml.header.timestep)
    assert_equal(sim_begin_month, hpxml.header.sim_begin_month)
    assert_equal(sim_begin_day, hpxml.header.sim_begin_day_of_month)
    assert_equal(sim_end_month, hpxml.header.sim_end_month)
    assert_equal(sim_end_day, hpxml.header.sim_end_day_of_month)
    assert_equal(dst_enabled, hpxml.header.dst_enabled)
    assert_equal(dst_begin_month, hpxml.header.dst_begin_month)
    assert_equal(dst_begin_day_of_month, hpxml.header.dst_begin_day_of_month)
    assert_equal(dst_end_month, hpxml.header.dst_end_month)
    assert_equal(dst_end_day_of_month, hpxml.header.dst_end_day_of_month)
    assert_equal(use_max_load_for_heat_pumps, hpxml.header.use_max_load_for_heat_pumps)
    assert_equal(allow_increased_fixed_capacities, hpxml.header.allow_increased_fixed_capacities)
  end

  def _test_default_site_values(hpxml, site_type, shelter_coefficient)
    assert_equal(site_type, hpxml.site.site_type)
    assert_equal(shelter_coefficient, hpxml.site.shelter_coefficient)
  end

  def _test_default_occupancy_values(hpxml, num_occupants)
    assert_equal(num_occupants, hpxml.building_occupancy.number_of_residents)
  end

  def _test_default_air_conditioner_values(hpxml, shr, compressor_type)
    cooling_system = hpxml.cooling_systems[0]
    assert_equal(shr, cooling_system.cooling_shr)
    assert_equal(compressor_type, cooling_system.compressor_type)
  end

  def _test_default_boiler_values(hpxml, eae)
    heating_system = hpxml.heating_systems[0]
    assert_equal(eae, heating_system.electric_auxiliary_energy)
  end

  def _test_default_gshp_values(hpxml, pump_w_per_ton, fan_w_per_cfm)
    heat_pump = hpxml.heat_pumps[0]
    assert_equal(pump_w_per_ton, heat_pump.pump_watts_per_ton)
    assert_equal(fan_w_per_cfm, heat_pump.fan_watts_per_cfm)
  end

  def _test_default_duct_values(hpxml, supply_locations, return_locations, supply_areas, return_areas, n_return_registers)
    supply_duct_idx = 0
    return_duct_idx = 0
    hpxml.hvac_distributions.each do |hvac_distribution|
      next unless [HPXML::HVACDistributionTypeAir, HPXML::HVACDistributionTypeHydronicAndAir].include? hvac_distribution.distribution_system_type

      assert_equal(n_return_registers, hvac_distribution.number_of_return_registers)
      hvac_distribution.ducts.each do |duct|
        if duct.duct_type == HPXML::DuctTypeSupply
          assert_equal(supply_locations[supply_duct_idx], duct.duct_location)
          assert_in_epsilon(supply_areas[supply_duct_idx], duct.duct_surface_area, 0.01)
          supply_duct_idx += 1
        elsif duct.duct_type == HPXML::DuctTypeReturn
          assert_equal(return_locations[return_duct_idx], duct.duct_location)
          assert_in_epsilon(return_areas[return_duct_idx], duct.duct_surface_area, 0.01)
          return_duct_idx += 1
        end
      end
    end
  end

  def _test_default_pv_system_values(hpxml, interver_efficiency, system_loss_frac, is_shared_system)
    assert_equal(interver_efficiency.size, hpxml.pv_systems.size)
    hpxml.pv_systems.each_with_index do |pv, idx|
      assert_equal(is_shared_system, pv.is_shared_system)
      assert_equal(interver_efficiency[idx], pv.inverter_efficiency)
      assert_in_epsilon(system_loss_frac[idx], pv.system_losses_fraction, 0.01)
    end
  end

  def _test_default_building_construction_values(hpxml, building_volume, has_flue_or_chimney, n_bathrooms)
    assert_equal(building_volume, hpxml.building_construction.conditioned_building_volume)
    assert_equal(has_flue_or_chimney, hpxml.building_construction.has_flue_or_chimney)
    assert_equal(n_bathrooms, hpxml.building_construction.number_of_bathrooms)
  end

  def _test_default_attic_values(hpxml, sla)
    attic = hpxml.attics[0]
    assert_equal(sla, attic.vented_attic_sla)
  end

  def _test_default_foundation_values(hpxml, sla)
    foundation = hpxml.foundations[0]
    assert_equal(sla, foundation.vented_crawlspace_sla)
  end

  def _test_default_infiltration_values(hpxml, volume)
    air_infiltration_measurement = hpxml.air_infiltration_measurements[0]
    assert_equal(volume, air_infiltration_measurement.infiltration_volume)
  end

  def _test_default_roof_values(hpxml, roof_type, solar_absorptance, roof_color)
    roof = hpxml.roofs[0]
    assert_equal(roof_type, roof.roof_type)
    assert_equal(solar_absorptance, roof.solar_absorptance)
    assert_equal(roof_color, roof.roof_color)
  end

  def _test_default_wall_values(hpxml, siding, solar_absorptance, color)
    wall = hpxml.walls[0]
    assert_equal(siding, wall.siding)
    assert_equal(solar_absorptance, wall.solar_absorptance)
    assert_equal(color, wall.color)
  end

  def _test_default_rim_joist_values(hpxml, siding, solar_absorptance, color)
    rim_joist = hpxml.rim_joists[0]
    assert_equal(siding, rim_joist.siding)
    assert_equal(solar_absorptance, rim_joist.solar_absorptance)
    assert_equal(color, rim_joist.color)
  end

  def _test_default_window_values(hpxml, summer_shade_coeffs, winter_shade_coeffs, fraction_operable)
    assert_equal(summer_shade_coeffs.size, hpxml.windows.size)
    hpxml.windows.each_with_index do |window, idx|
      assert_equal(summer_shade_coeffs[idx], window.interior_shading_factor_summer)
      assert_equal(winter_shade_coeffs[idx], window.interior_shading_factor_winter)
      assert_equal(fraction_operable[idx], window.fraction_operable)
    end
  end

  def _test_default_skylight_values(hpxml, summer_shade_coeffs, winter_shade_coeffs)
    assert_equal(summer_shade_coeffs.size, hpxml.skylights.size)
    hpxml.skylights.each_with_index do |skylight, idx|
      assert_equal(summer_shade_coeffs[idx], skylight.interior_shading_factor_summer)
      assert_equal(winter_shade_coeffs[idx], skylight.interior_shading_factor_winter)
    end
  end

  def _test_default_clothes_washer_values(hpxml, is_shared, location, imef, rated_annual_kwh, label_electric_rate, label_gas_rate, label_annual_gas_cost, capacity, label_usage, usage_multiplier)
    clothes_washer = hpxml.clothes_washers[0]
    assert_equal(is_shared, clothes_washer.is_shared_appliance)
    assert_equal(location, clothes_washer.location)
    assert_equal(imef, clothes_washer.integrated_modified_energy_factor)
    assert_equal(rated_annual_kwh, clothes_washer.rated_annual_kwh)
    assert_equal(label_electric_rate, clothes_washer.label_electric_rate)
    assert_equal(label_gas_rate, clothes_washer.label_gas_rate)
    assert_equal(label_annual_gas_cost, clothes_washer.label_annual_gas_cost)
    assert_equal(capacity, clothes_washer.capacity)
    assert_equal(label_usage, clothes_washer.label_usage)
    assert_equal(usage_multiplier, clothes_washer.usage_multiplier)
  end

  def _test_default_clothes_dryer_values(hpxml, is_shared, location, control_type, cef, usage_multiplier)
    clothes_dryer = hpxml.clothes_dryers[0]
    assert_equal(is_shared, clothes_dryer.is_shared_appliance)
    assert_equal(location, clothes_dryer.location)
    assert_equal(control_type, clothes_dryer.control_type)
    assert_equal(cef, clothes_dryer.combined_energy_factor)
    assert_equal(usage_multiplier, clothes_dryer.usage_multiplier)
  end

  def _test_default_dishwasher_values(hpxml, is_shared, location, rated_annual_kwh, label_electric_rate, label_gas_rate, label_annual_gas_cost, label_usage, place_setting_capacity, usage_multiplier)
    dishwasher = hpxml.dishwashers[0]
    assert_equal(is_shared, dishwasher.is_shared_appliance)
    assert_equal(location, dishwasher.location)
    assert_equal(rated_annual_kwh, dishwasher.rated_annual_kwh)
    assert_equal(label_electric_rate, dishwasher.label_electric_rate)
    assert_equal(label_gas_rate, dishwasher.label_gas_rate)
    assert_equal(label_annual_gas_cost, dishwasher.label_annual_gas_cost)
    assert_equal(label_usage, dishwasher.label_usage)
    assert_equal(place_setting_capacity, dishwasher.place_setting_capacity)
    assert_equal(usage_multiplier, dishwasher.usage_multiplier)
  end

  def _test_default_refrigerator_values(hpxml, location, rated_annual_kwh, usage_multiplier, weekday_sch, weekend_sch, monthly_mults)
    hpxml.refrigerators.each do |refrigerator|
      next unless refrigerator.primary_indicator

      assert_equal(location, refrigerator.location)
      assert_equal(rated_annual_kwh, refrigerator.rated_annual_kwh)
      assert_equal(usage_multiplier, refrigerator.usage_multiplier)
      if weekday_sch.nil?
        assert_nil(refrigerator.weekday_fractions)
      else
        assert_equal(weekday_sch, refrigerator.weekday_fractions)
      end
      if weekend_sch.nil?
        assert_nil(refrigerator.weekend_fractions)
      else
        assert_equal(weekend_sch, refrigerator.weekend_fractions)
      end
      if monthly_mults.nil?
        assert_nil(refrigerator.monthly_multipliers)
      else
        assert_equal(monthly_mults, refrigerator.monthly_multipliers)
      end
    end
  end

  def _test_default_extra_refrigerators_values(hpxml, location, rated_annual_kwh, usage_multiplier, weekday_sch, weekend_sch, monthly_mults)
    hpxml.refrigerators.each do |refrigerator|
      next if refrigerator.primary_indicator

      assert_equal(location, refrigerator.location)
      assert_in_epsilon(rated_annual_kwh, refrigerator.rated_annual_kwh, 0.01)
      assert_equal(usage_multiplier, refrigerator.usage_multiplier)
      if weekday_sch.nil?
        assert_nil(refrigerator.weekday_fractions)
      else
        assert_equal(weekday_sch, refrigerator.weekday_fractions)
      end
      if weekend_sch.nil?
        assert_nil(refrigerator.weekend_fractions)
      else
        assert_equal(weekend_sch, refrigerator.weekend_fractions)
      end
      if monthly_mults.nil?
        assert_nil(refrigerator.monthly_multipliers)
      else
        assert_equal(monthly_mults, refrigerator.monthly_multipliers)
      end
    end
  end

  def _test_default_freezers_values(hpxml, location, rated_annual_kwh, usage_multiplier, weekday_sch, weekend_sch, monthly_mults)
    hpxml.freezers.each do |freezer|
      assert_equal(location, freezer.location)
      assert_in_epsilon(rated_annual_kwh, freezer.rated_annual_kwh, 0.01)
      assert_equal(usage_multiplier, freezer.usage_multiplier)
      if weekday_sch.nil?
        assert_nil(freezer.weekday_fractions)
      else
        assert_equal(weekday_sch, freezer.weekday_fractions)
      end
      if weekend_sch.nil?
        assert_nil(freezer.weekend_fractions)
      else
        assert_equal(weekend_sch, freezer.weekend_fractions)
      end
      if monthly_mults.nil?
        assert_nil(freezer.monthly_multipliers)
      else
        assert_equal(monthly_mults, freezer.monthly_multipliers)
      end
    end
  end

  def _test_default_cooking_range_values(hpxml, location, is_induction, usage_multiplier, weekday_sch, weekend_sch, monthly_mults)
    cooking_range = hpxml.cooking_ranges[0]
    assert_equal(location, cooking_range.location)
    assert_equal(is_induction, cooking_range.is_induction)
    assert_equal(usage_multiplier, cooking_range.usage_multiplier)
    if weekday_sch.nil?
      assert_nil(cooking_range.weekday_fractions)
    else
      assert_equal(weekday_sch, cooking_range.weekday_fractions)
    end
    if weekend_sch.nil?
      assert_nil(cooking_range.weekend_fractions)
    else
      assert_equal(weekend_sch, cooking_range.weekend_fractions)
    end
    if monthly_mults.nil?
      assert_nil(cooking_range.monthly_multipliers)
    else
      assert_equal(monthly_mults, cooking_range.monthly_multipliers)
    end
  end

  def _test_default_oven_values(hpxml, is_convection)
    oven = hpxml.ovens[0]
    assert_equal(is_convection, oven.is_convection)
  end

  def _test_default_lighting_values(hpxml, interior_usage_multiplier, garage_usage_multiplier, exterior_usage_multiplier, schedules = {})
    assert_equal(interior_usage_multiplier, hpxml.lighting.interior_usage_multiplier)
    assert_equal(garage_usage_multiplier, hpxml.lighting.garage_usage_multiplier)
    assert_equal(exterior_usage_multiplier, hpxml.lighting.exterior_usage_multiplier)
    if not schedules[:grg_wk_sch].nil?
      assert_equal(schedules[:grg_wk_sch], hpxml.lighting.garage_weekday_fractions)
    else
      assert_nil(hpxml.lighting.garage_weekday_fractions)
    end
    if not schedules[:grg_wknd_sch].nil?
      assert_equal(schedules[:grg_wknd_sch], hpxml.lighting.garage_weekend_fractions)
    else
      assert_nil(hpxml.lighting.garage_weekend_fractions)
    end
    if not schedules[:grg_month_mult].nil?
      assert_equal(schedules[:grg_month_mult], hpxml.lighting.garage_monthly_multipliers)
    else
      assert_nil(hpxml.lighting.garage_monthly_multipliers)
    end
    if not schedules[:ext_wk_sch].nil?
      assert_equal(schedules[:ext_wk_sch], hpxml.lighting.exterior_weekday_fractions)
    else
      assert_nil(hpxml.lighting.exterior_weekday_fractions)
    end
    if not schedules[:ext_wknd_sch].nil?
      assert_equal(schedules[:ext_wknd_sch], hpxml.lighting.exterior_weekend_fractions)
    else
      assert_nil(hpxml.lighting.exterior_weekday_fractions)
    end
    if not schedules[:ext_month_mult].nil?
      assert_equal(schedules[:ext_month_mult], hpxml.lighting.exterior_monthly_multipliers)
    else
      assert_nil(hpxml.lighting.exterior_monthly_multipliers)
    end
    if not schedules[:hol_kwh_per_day].nil?
      assert_equal(schedules[:hol_kwh_per_day], hpxml.lighting.holiday_kwh_per_day)
    else
      assert_nil(hpxml.lighting.holiday_kwh_per_day)
    end
    if not schedules[:hol_begin_month].nil?
      assert_equal(schedules[:hol_begin_month], hpxml.lighting.holiday_period_begin_month)
    else
      assert_nil(hpxml.lighting.holiday_period_begin_month)
    end
    if not schedules[:hol_begin_day_of_month].nil?
      assert_equal(schedules[:hol_begin_day_of_month], hpxml.lighting.holiday_period_begin_day_of_month)
    else
      assert_nil(hpxml.lighting.holiday_period_begin_day_of_month)
    end
    if not schedules[:hol_end_month].nil?
      assert_equal(schedules[:hol_end_month], hpxml.lighting.holiday_period_end_month)
    else
      assert_nil(hpxml.lighting.holiday_period_end_month)
    end
    if not schedules[:hol_end_day_of_month].nil?
      assert_equal(schedules[:hol_end_day_of_month], hpxml.lighting.holiday_period_end_day_of_month)
    else
      assert_nil(hpxml.lighting.holiday_period_end_day_of_month)
    end
    if not schedules[:hol_wk_sch].nil?
      assert_equal(schedules[:hol_wk_sch], hpxml.lighting.holiday_weekday_fractions)
    else
      assert_nil(hpxml.lighting.holiday_weekday_fractions)
    end
    if not schedules[:hol_wknd_sch].nil?
      assert_equal(schedules[:hol_wknd_sch], hpxml.lighting.holiday_weekend_fractions)
    else
      assert_nil(hpxml.lighting.holiday_weekend_fractions)
    end
  end

  def _test_default_standard_distribution_values(hpxml, piping_length)
    hot_water_distribution = hpxml.hot_water_distributions[0]
    assert_in_epsilon(piping_length, hot_water_distribution.standard_piping_length, 0.01)
  end

  def _test_default_recirc_distribution_values(hpxml, piping_length, branch_piping_length, pump_power)
    hot_water_distribution = hpxml.hot_water_distributions[0]
    assert_in_epsilon(piping_length, hot_water_distribution.recirculation_piping_length, 0.01)
    assert_in_epsilon(branch_piping_length, hot_water_distribution.recirculation_branch_piping_length, 0.01)
    assert_in_epsilon(pump_power, hot_water_distribution.recirculation_pump_power, 0.01)
  end

  def _test_default_shared_recirc_distribution_values(hpxml, pump_power)
    hot_water_distribution = hpxml.hot_water_distributions[0]
    assert_in_epsilon(pump_power, hot_water_distribution.shared_recirculation_pump_power, 0.01)
  end

  def _test_default_water_fixture_values(hpxml, usage_multiplier)
    assert_equal(usage_multiplier, hpxml.water_heating.water_fixtures_usage_multiplier)
  end

  def _test_default_solar_thermal_values(hpxml, storage_volume)
    assert_in_epsilon(storage_volume, hpxml.solar_thermal_systems[0].storage_volume)
  end

  def _test_default_kitchen_fan_values(hpxml, quantity, rated_flow_rate, hours_in_operation, fan_power, start_hour)
    kitchen_fan = hpxml.ventilation_fans.select { |f| f.used_for_local_ventilation && f.fan_location == HPXML::LocationKitchen }[0]
    assert_equal(quantity, kitchen_fan.quantity)
    assert_equal(rated_flow_rate, kitchen_fan.rated_flow_rate)
    assert_equal(hours_in_operation, kitchen_fan.hours_in_operation)
    assert_equal(fan_power, kitchen_fan.fan_power)
    assert_equal(start_hour, kitchen_fan.start_hour)
  end

  def _test_default_bath_fan_values(hpxml, quantity, rated_flow_rate, hours_in_operation, fan_power, start_hour)
    bath_fan = hpxml.ventilation_fans.select { |f| f.used_for_local_ventilation && f.fan_location == HPXML::LocationBath }[0]
    assert_equal(quantity, bath_fan.quantity)
    assert_equal(rated_flow_rate, bath_fan.rated_flow_rate)
    assert_equal(hours_in_operation, bath_fan.hours_in_operation)
    assert_equal(fan_power, bath_fan.fan_power)
    assert_equal(start_hour, bath_fan.start_hour)
  end

  def _test_default_ceiling_fan_values(hpxml, quantity, efficiency)
    assert_equal(quantity, hpxml.ceiling_fans[0].quantity)
    assert_in_epsilon(efficiency, hpxml.ceiling_fans[0].efficiency, 0.01)
  end

  def _test_default_pool_heater_values(hpxml, load_units, load_value, weekday_sch, weekend_sch, monthly_mults)
    pool = hpxml.pools[0]
    if load_units.nil?
      assert_nil(pool.heater_load_units)
    else
      assert_equal(load_units, pool.heater_load_units)
    end
    if load_value.nil?
      assert_nil(pool.heater_load_value)
    else
      assert_in_epsilon(load_value, pool.heater_load_value.to_f, 0.01)
    end
    if weekday_sch.nil?
      assert_nil(pool.heater_weekday_fractions)
    else
      assert_equal(weekday_sch, pool.heater_weekday_fractions)
    end
    if weekend_sch.nil?
      assert_nil(pool.heater_weekend_fractions)
    else
      assert_equal(weekend_sch, pool.heater_weekend_fractions)
    end
    if monthly_mults.nil?
      assert_nil(pool.heater_monthly_multipliers)
    else
      assert_equal(monthly_mults, pool.heater_monthly_multipliers)
    end
  end

  def _test_default_pool_pump_values(hpxml, kWh_per_year, weekday_sch, weekend_sch, monthly_mults)
    pool = hpxml.pools[0]
    assert_in_epsilon(kWh_per_year, pool.pump_kwh_per_year, 0.01)
    assert_equal(weekday_sch, pool.pump_weekday_fractions)
    assert_equal(weekend_sch, pool.pump_weekend_fractions)
    assert_equal(monthly_mults, pool.pump_monthly_multipliers)
  end

  def _test_default_hot_tub_heater_values(hpxml, load_units, load_value, weekday_sch, weekend_sch, monthly_mults)
    hot_tub = hpxml.hot_tubs[0]
    if load_units.nil?
      assert_nil(hot_tub.heater_load_units)
    else
      assert_equal(load_units, hot_tub.heater_load_units)
    end
    if load_value.nil?
      assert_nil(hot_tub.heater_load_value)
    else
      assert_in_epsilon(load_value, hot_tub.heater_load_value.to_f, 0.01)
    end
    if weekday_sch.nil?
      assert_nil(hot_tub.heater_weekday_fractions)
    else
      assert_equal(weekday_sch, hot_tub.heater_weekday_fractions)
    end
    if weekend_sch.nil?
      assert_nil(hot_tub.heater_weekend_fractions)
    else
      assert_equal(weekend_sch, hot_tub.heater_weekend_fractions)
    end
    if monthly_mults.nil?
      assert_nil(hot_tub.heater_monthly_multipliers)
    else
      assert_equal(monthly_mults, hot_tub.heater_monthly_multipliers)
    end
  end

  def _test_default_hot_tub_pump_values(hpxml, kWh_per_year, weekday_sch, weekend_sch, monthly_mults)
    hot_tub = hpxml.hot_tubs[0]
    assert_in_epsilon(kWh_per_year, hot_tub.pump_kwh_per_year, 0.01)
    assert_equal(weekday_sch, hot_tub.pump_weekday_fractions)
    assert_equal(weekend_sch, hot_tub.pump_weekend_fractions)
    assert_equal(monthly_mults, hot_tub.pump_monthly_multipliers)
  end

  def _test_default_plug_load_values(hpxml, load_type, kWh_per_year, frac_sensible, frac_latent, location, weekday_sch, weekend_sch, monthly_mults)
    pl = hpxml.plug_loads.select { |pl| pl.plug_load_type == load_type }[0]
    assert_in_epsilon(kWh_per_year, pl.kWh_per_year, 0.01)
    assert_in_epsilon(frac_sensible, pl.frac_sensible, 0.01)
    assert_in_epsilon(frac_latent, pl.frac_latent, 0.01)
    assert_equal(location, pl.location)
    assert_equal(weekday_sch, pl.weekday_fractions)
    assert_equal(weekend_sch, pl.weekend_fractions)
    assert_equal(monthly_mults, pl.monthly_multipliers)
  end

  def _test_default_fuel_load_values(hpxml, load_type, therm_per_year, frac_sensible, frac_latent, location, weekday_sch, weekend_sch, monthly_mults)
    fl = hpxml.fuel_loads.select { |fl| fl.fuel_load_type == load_type }[0]
    assert_in_epsilon(therm_per_year, fl.therm_per_year, 0.01)
    assert_in_epsilon(frac_sensible, fl.frac_sensible, 0.01)
    assert_in_epsilon(frac_latent, fl.frac_latent, 0.01)
    assert_equal(location, fl.location)
    assert_equal(weekday_sch, fl.weekday_fractions)
    assert_equal(weekend_sch, fl.weekend_fractions)
    assert_equal(monthly_mults, fl.monthly_multipliers)
  end

  def _test_default_water_heater_values(hpxml, *expected_wh_values)
    storage_water_heaters = hpxml.water_heating_systems.select { |w| w.water_heater_type == HPXML::WaterHeaterTypeStorage }
    assert_equal(expected_wh_values.size, storage_water_heaters.size)
    storage_water_heaters.each_with_index do |wh_system, idx|
      is_shared, heating_capacity, tank_volume, recovery_efficiency = expected_wh_values[idx]
      assert_equal(is_shared, wh_system.is_shared_system)
      assert_in_epsilon(heating_capacity, wh_system.heating_capacity, 0.01)
      assert_equal(tank_volume, wh_system.tank_volume)
      assert_in_epsilon(recovery_efficiency, wh_system.recovery_efficiency, 0.01)
    end
  end

  def _create_hpxml(hpxml_name)
    return HPXML.new(hpxml_path: File.join(@sample_files_path, hpxml_name))
  end
end
