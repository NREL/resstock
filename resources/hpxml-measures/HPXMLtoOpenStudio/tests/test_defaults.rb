# frozen_string_literal: true

require_relative '../resources/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require 'fileutils'
require_relative '../measure.rb'
require_relative '../resources/util.rb'

class HPXMLtoOpenStudioDefaultsTest < MiniTest::Test
  def before_setup
    @root_path = File.absolute_path(File.join(File.dirname(__FILE__), '..', '..'))
    @tmp_hpxml_path = File.join(@root_path, 'workflow', 'sample_files', 'tmp.xml')
    @tmp_output_path = File.join(@root_path, 'workflow', 'sample_files', 'tmp_output')
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
    hpxml_name = 'base.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml.header.timestep = 30
    hpxml.header.begin_month = 2
    hpxml.header.begin_day_of_month = 2
    hpxml.header.end_month = 11
    hpxml.header.end_day_of_month = 11
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_header_values(hpxml_default, 30, 2, 2, 11, 11)

    # Test defaults
    hpxml = apply_hpxml_defaults('base.xml')
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_header_values(hpxml_default, 60, 1, 1, 12, 31)
  end

  def test_site
    # Test inputs not overridden by defaults
    hpxml_name = 'base.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml.site.site_type = HPXML::SiteTypeRural
    hpxml.site.shelter_coefficient = 0.3
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_site_values(hpxml_default, HPXML::SiteTypeRural, 0.3)

    # Test defaults
    hpxml = apply_hpxml_defaults('base.xml')
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_site_values(hpxml_default, HPXML::SiteTypeSuburban, 0.5)
  end

  def test_occupancy
    # Test inputs not overridden by defaults
    hpxml_name = 'base.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml.building_occupancy.number_of_residents = 1
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_occupancy_values(hpxml_default, 1)

    # Test defaults
    hpxml = apply_hpxml_defaults('base.xml')
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_occupancy_values(hpxml_default, 3)
  end

  def test_building_construction
    # Test inputs not overridden by defaults
    hpxml_name = 'base.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_building_construction_values(hpxml_default, 21600)

    # Test defaults w/ average ceiling height
    hpxml = apply_hpxml_defaults('base.xml')
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_building_construction_values(hpxml_default, 27000)
  end

  def test_attics
    # Test inputs not overridden by defaults
    hpxml_name = 'base-atticroof-vented.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml.attics[0].vented_attic_sla = 0.001
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_attic_values(hpxml_default, 0.001)

    # Test defaults
    hpxml = apply_hpxml_defaults('base-atticroof-vented.xml')
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_attic_values(hpxml_default, 1.0 / 300.0)
  end

  def test_foundations
    # Test inputs not overridden by defaults
    hpxml_name = 'base-foundation-vented-crawlspace.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml.foundations[0].vented_crawlspace_sla = 0.001
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_foundation_values(hpxml_default, 0.001)

    # Test defaults
    hpxml = apply_hpxml_defaults('base-foundation-vented-crawlspace.xml')
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_foundation_values(hpxml_default, 1.0 / 150.0)
  end

  def test_infiltration
    # Test inputs not overridden by defaults
    hpxml_name = 'base.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml.air_infiltration_measurements[0].infiltration_volume = 25000
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_infiltration_values(hpxml_default, 25000)

    # Test defaults w/ conditioned basement
    hpxml = apply_hpxml_defaults('base.xml')
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_infiltration_values(hpxml_default, 2700 * 10)

    # Test defaults w/o conditioned basement
    hpxml = apply_hpxml_defaults('base-foundation-slab.xml')
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_infiltration_values(hpxml_default, 1350 * 10)
  end

  def test_roofs
    # Test inputs not overridden by defaults
    hpxml_name = 'base.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml.roofs[0].roof_type = HPXML::RoofTypeMetal
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_roof_values(hpxml_default, HPXML::RoofTypeMetal, 0.7, HPXML::ColorMedium)

    # Test defaults
    hpxml = apply_hpxml_defaults('base.xml')
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_roof_values(hpxml_default, HPXML::RoofTypeAsphaltShingles, 0.75, HPXML::ColorLight)
  end

  def test_walls
    # Test inputs not overridden by defaults
    hpxml_name = 'base.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml.walls[0].siding = HPXML::SidingTypeFiberCement
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_wall_values(hpxml_default, HPXML::SidingTypeFiberCement, 0.7, HPXML::ColorMedium)

    # Test defaults
    hpxml = apply_hpxml_defaults('base.xml')
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_wall_values(hpxml_default, HPXML::SidingTypeWood, 0.5, HPXML::ColorLight)
  end

  def test_rim_joists
    # Test inputs not overridden by defaults
    hpxml_name = 'base.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml.rim_joists[0].siding = HPXML::SidingTypeBrick
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_rim_joist_values(hpxml_default, HPXML::SidingTypeBrick, 0.7, HPXML::ColorMedium)

    # Test defaults
    hpxml = apply_hpxml_defaults('base.xml')
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_rim_joist_values(hpxml_default, HPXML::SidingTypeWood, 0.95, HPXML::ColorDark)
  end

  def test_windows
    # Test inputs not overridden by defaults
    hpxml_name = 'base-enclosure-windows-interior-shading.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml.windows.each do |window|
      window.fraction_operable = 0.5
    end
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    n_windows = hpxml_default.windows.size
    _test_default_window_values(hpxml_default, [0.7, 0.01, 0.0, 1.0], [0.85, 0.99, 0.5, 1.0], [0.5] * n_windows)

    # Test defaults
    hpxml = apply_hpxml_defaults('base.xml')
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    n_windows = hpxml_default.windows.size
    _test_default_window_values(hpxml_default, [0.7] * n_windows, [0.85] * n_windows, [0.67] * n_windows)
  end

  def test_skylights
    # Test inputs not overridden by defaults
    hpxml_name = 'base-enclosure-skylights.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml.skylights.each do |skylight|
      skylight.interior_shading_factor_summer = 0.90
      skylight.interior_shading_factor_winter = 0.95
    end
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    n_skylights = hpxml_default.skylights.size
    _test_default_skylight_values(hpxml_default, [0.90] * n_skylights, [0.95] * n_skylights)

    # Test defaults
    hpxml = apply_hpxml_defaults('base-enclosure-skylights.xml')
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    n_skylights = hpxml_default.skylights.size
    _test_default_skylight_values(hpxml_default, [1.0] * n_skylights, [1.0] * n_skylights)
  end

  def test_ducts
    # Test inputs not overridden by defaults
    hpxml_name = 'base.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    expected_supply_locations = ['attic - unvented']
    expected_return_locations = ['attic - unvented']
    expected_supply_areas = [150.0]
    expected_return_areas = [50.0]
    expected_n_return_registers = hpxml_default.building_construction.number_of_conditioned_floors
    _test_default_duct_values(hpxml_default, expected_supply_locations, expected_return_locations, expected_supply_areas, expected_return_areas, expected_n_return_registers)

    # Test defaults w/ conditioned basement
    hpxml = apply_hpxml_defaults('base.xml')
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    expected_supply_locations = ['basement - conditioned']
    expected_return_locations = ['basement - conditioned']
    expected_supply_areas = [729.0]
    expected_return_areas = [270.0]
    expected_n_return_registers = hpxml_default.building_construction.number_of_conditioned_floors
    _test_default_duct_values(hpxml_default, expected_supply_locations, expected_return_locations, expected_supply_areas, expected_return_areas, expected_n_return_registers)

    # Test defaults w/ multiple foundations
    hpxml = apply_hpxml_defaults('base-foundation-multiple.xml')
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    expected_supply_locations = ['basement - unconditioned']
    expected_return_locations = ['basement - unconditioned']
    expected_supply_areas = [364.5]
    expected_return_areas = [67.5]
    expected_n_return_registers = hpxml_default.building_construction.number_of_conditioned_floors
    _test_default_duct_values(hpxml_default, expected_supply_locations, expected_return_locations, expected_supply_areas, expected_return_areas, expected_n_return_registers)

    # Test defaults w/ foundation exposed to ambient
    hpxml = apply_hpxml_defaults('base-foundation-ambient.xml')
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    expected_supply_locations = ['attic - unvented']
    expected_return_locations = ['attic - unvented']
    expected_supply_areas = [364.5]
    expected_return_areas = [67.5]
    expected_n_return_registers = hpxml_default.building_construction.number_of_conditioned_floors
    _test_default_duct_values(hpxml_default, expected_supply_locations, expected_return_locations, expected_supply_areas, expected_return_areas, expected_n_return_registers)

    # Test defaults w/ building/unit adjacent to other housing unit
    hpxml = apply_hpxml_defaults('base-enclosure-other-housing-unit.xml')
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    expected_supply_locations = ['living space']
    expected_return_locations = ['living space']
    expected_supply_areas = [364.5]
    expected_return_areas = [67.5]
    expected_n_return_registers = hpxml_default.building_construction.number_of_conditioned_floors
    _test_default_duct_values(hpxml_default, expected_supply_locations, expected_return_locations, expected_supply_areas, expected_return_areas, expected_n_return_registers)

    # Test defaults w/ 2-story building
    hpxml = apply_hpxml_defaults('base-enclosure-2stories.xml')
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    expected_supply_locations = ['basement - conditioned', 'living space']
    expected_return_locations = ['basement - conditioned', 'living space']
    expected_supply_areas = [820.125, 273.375]
    expected_return_areas = [455.625, 151.875]
    expected_n_return_registers = hpxml_default.building_construction.number_of_conditioned_floors
    _test_default_duct_values(hpxml_default, expected_supply_locations, expected_return_locations, expected_supply_areas, expected_return_areas, expected_n_return_registers)

    # Test defaults w/ 1-story building & multiple HVAC systems
    hpxml_files = ['base-hvac-multiple.xml',
                   'base-hvac-multiple2.xml']
    hpxml_files.each do |hpxml_file|
      hpxml = apply_hpxml_defaults(hpxml_file)
      XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
      hpxml_default = _test_measure()
      expected_supply_locations = ['basement - conditioned', 'basement - conditioned'] * hpxml_default.hvac_distributions.size
      expected_return_locations = ['basement - conditioned', 'basement - conditioned'] * hpxml_default.hvac_distributions.size
      expected_supply_areas = [91.125, 91.125] * hpxml_default.hvac_distributions.size
      expected_return_areas = [33.75, 33.75] * hpxml_default.hvac_distributions.size
      expected_n_return_registers = hpxml_default.building_construction.number_of_conditioned_floors
      _test_default_duct_values(hpxml_default, expected_supply_locations, expected_return_locations, expected_supply_areas, expected_return_areas, expected_n_return_registers)
    end

    # Test defaults w/ 2-story building & multiple HVAC systems
    hpxml = apply_hpxml_defaults('base-hvac-multiple.xml')
    hpxml.building_construction.number_of_conditioned_floors_above_grade = 2
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    expected_supply_locations = ['basement - conditioned', 'basement - conditioned', 'living space', 'living space'] * hpxml_default.hvac_distributions.size
    expected_return_locations = ['basement - conditioned', 'basement - conditioned', 'living space', 'living space'] * hpxml_default.hvac_distributions.size
    expected_supply_areas = [68.344, 68.344, 22.781, 22.781] * hpxml_default.hvac_distributions.size
    expected_return_areas = [25.312, 25.312, 8.438, 8.438] * hpxml_default.hvac_distributions.size
    expected_n_return_registers = hpxml_default.building_construction.number_of_conditioned_floors
    _test_default_duct_values(hpxml_default, expected_supply_locations, expected_return_locations, expected_supply_areas, expected_return_areas, expected_n_return_registers)
  end

  def test_water_heaters
    # Test inputs not overridden by defaults
    hpxml_name = 'base.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml.water_heating_systems.each do |wh|
      wh.heating_capacity = 15000.0
      wh.tank_volume = 40.0
      wh.recovery_efficiency = 0.95
    end
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_water_heater_values(hpxml_default, [15000.0, 40.0, 0.95])
    _test_default_number_of_bathrooms(hpxml_default, 2.0)

    # Test defaults w/ 3-bedroom house & electric storage water heater
    hpxml = apply_hpxml_defaults('base.xml')
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_water_heater_values(hpxml_default, [18766.7, 50.0, 0.98])
    _test_default_number_of_bathrooms(hpxml_default, 2.0)

    # Test defaults w/ 5-bedroom house & electric storage water heater
    hpxml = apply_hpxml_defaults('base-enclosure-beds-5.xml')
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_water_heater_values(hpxml_default, [18766.7, 66.0, 0.98])
    _test_default_number_of_bathrooms(hpxml_default, 3.0)

    # Test defaults w/ 3-bedroom house & 2 storage water heaters (1 electric and 1 natural gas)
    hpxml = apply_hpxml_defaults('base-dhw-multiple.xml')
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_water_heater_values(hpxml_default, [15354.6, 50.0, 0.98],
                                      [36000.0, 40.0, 0.756])
    _test_default_number_of_bathrooms(hpxml_default, 2.0)
  end

  def test_hot_water_distribution
    # Test inputs not overridden by defaults -- standard
    hpxml_name = 'base.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_standard_distribution_values(hpxml_default, 50.0)

    # Test inputs not overridden by defaults -- recirculation
    hpxml_name = 'base-dhw-recirc-demand.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml.hot_water_distributions[0].recirculation_pump_power = 65.0
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_recirc_distribution_values(hpxml_default, 50.0, 50.0, 65.0)

    # Test defaults w/ conditioned basement
    hpxml = apply_hpxml_defaults('base.xml')
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_standard_distribution_values(hpxml_default, 93.48)

    # Test defaults w/ unconditioned basement
    hpxml = apply_hpxml_defaults('base-foundation-unconditioned-basement.xml')
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_standard_distribution_values(hpxml_default, 88.48)

    # Test defaults w/ 2-story building
    hpxml = apply_hpxml_defaults('base-enclosure-2stories.xml')
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_standard_distribution_values(hpxml_default, 103.48)

    # Test defaults w/ recirculation & conditioned basement
    hpxml = apply_hpxml_defaults('base-dhw-recirc-demand.xml')
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_recirc_distribution_values(hpxml_default, 166.96, 10.0, 50.0)

    # Test defaults w/ recirculation & unconditioned basement
    hpxml = apply_hpxml_defaults('base-foundation-unconditioned-basement.xml')
    hpxml.hot_water_distributions.clear
    hpxml.hot_water_distributions.add(id: 'HotWaterDstribution',
                                      system_type: HPXML::DHWDistTypeRecirc,
                                      recirculation_control_type: HPXML::DHWRecirControlTypeSensor,
                                      pipe_r_value: 3.0)
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_recirc_distribution_values(hpxml_default, 156.96, 10.0, 50.0)

    # Test defaults w/ recirculation & 2-story building
    hpxml = apply_hpxml_defaults('base-enclosure-2stories.xml')
    hpxml.hot_water_distributions.clear
    hpxml.hot_water_distributions.add(id: 'HotWaterDstribution',
                                      system_type: HPXML::DHWDistTypeRecirc,
                                      recirculation_control_type: HPXML::DHWRecirControlTypeSensor,
                                      pipe_r_value: 3.0)
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_recirc_distribution_values(hpxml_default, 186.96, 10.0, 50.0)
  end

  def test_water_fixtures
    # Test inputs not overridden by defaults
    hpxml_name = 'base.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml.water_heating.water_fixtures_usage_multiplier = 2.0
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_water_fixture_values(hpxml_default, 2.0)

    # Test defaults
    hpxml = apply_hpxml_defaults('base.xml')
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_water_fixture_values(hpxml_default, 1.0)
  end

  def test_solar_thermal_system
    # Test inputs not overridden by defaults
    hpxml_name = 'base-dhw-solar-direct-flat-plate.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml.solar_thermal_systems[0].storage_volume = 55.0
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_solar_thermal_values(hpxml_default, 55.0)

    # Test defaults w/ collector area of 40 sqft
    hpxml = apply_hpxml_defaults('base-dhw-solar-direct-flat-plate.xml')
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_solar_thermal_values(hpxml_default, 60.0)

    # Test defaults w/ collector area of 100 sqft
    hpxml = apply_hpxml_defaults('base-dhw-solar-direct-flat-plate.xml')
    hpxml.solar_thermal_systems[0].collector_area = 100.0
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_solar_thermal_values(hpxml_default, 150.0)
  end

  def test_ventilation_fans
    # Test inputs not overridden by defaults
    hpxml_name = 'base-mechvent-bath-kitchen-fans.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    kitchen_fan = hpxml.ventilation_fans.select { |f| f.used_for_local_ventilation && f.fan_location == HPXML::LocationKitchen }[0]
    kitchen_fan.rated_flow_rate = 300
    kitchen_fan.fan_power = 20
    kitchen_fan.start_hour = 12
    bath_fan = hpxml.ventilation_fans.select { |f| f.used_for_local_ventilation && f.fan_location == HPXML::LocationBath }[0]
    bath_fan.rated_flow_rate = 80
    bath_fan.fan_power = 33
    bath_fan.start_hour = 6
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_kitchen_fan_values(hpxml_default, 300, 1.5, 20, 12)
    _test_default_bath_fan_values(hpxml_default, 2, 80, 1.5, 33, 6)

    # Test defaults
    hpxml = apply_hpxml_defaults('base-mechvent-bath-kitchen-fans.xml')
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_kitchen_fan_values(hpxml_default, 100, 1, 30, 18)
    _test_default_bath_fan_values(hpxml_default, 2, 50, 1, 15, 7)
  end

  def test_ceiling_fans
    # Test inputs not overridden by defaults
    hpxml_name = 'base-misc-ceiling-fans.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_ceiling_fan_values(hpxml_default, 2, 100)

    # Test defaults
    hpxml = apply_hpxml_defaults('base-misc-ceiling-fans.xml')
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_ceiling_fan_values(hpxml_default, 4, 70.4)
  end

  def test_plug_loads
    # Test inputs not overridden by defaults
    hpxml_name = 'base.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    tv_pl = hpxml.plug_loads.select { |pl| pl.plug_load_type == HPXML::PlugLoadTypeTelevision }[0]
    tv_pl.kWh_per_year = 1000
    other_pl = hpxml.plug_loads.select { |pl| pl.plug_load_type == HPXML::PlugLoadTypeOther }[0]
    other_pl.kWh_per_year = 2000
    other_pl.frac_sensible = 0.8
    other_pl.frac_latent = 0.1
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_tv_plug_load_values(hpxml_default, 1000)
    _test_default_other_plug_load_values(hpxml_default, 2000, 0.8, 0.1)

    # Test defaults
    hpxml = apply_hpxml_defaults('base.xml')
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_tv_plug_load_values(hpxml_default, 620)
    _test_default_other_plug_load_values(hpxml_default, 2457, 0.855, 0.045)
  end

  def test_appliances
    # Test inputs not overridden by defaults
    hpxml_name = 'base.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_clothes_washer_values(hpxml_default, HPXML::LocationLivingSpace, 1.21, 380.0, 0.12, 1.09, 27.0, 3.2, 6.0, 1.0)
    _test_default_clothes_dryer_values(hpxml_default, HPXML::LocationLivingSpace, HPXML::ClothesDryerControlTypeTimer, 3.73, 1.0)
    _test_default_dishwasher_values(hpxml_default, HPXML::LocationLivingSpace, 307.0, 0.12, 1.09, 22.32, 4.0, 12, 1.0)
    _test_default_refrigerator_values(hpxml_default, HPXML::LocationLivingSpace, 650.0, 1.0)
    _test_default_cooking_range_values(hpxml_default, HPXML::LocationLivingSpace, false, 1.0)
    _test_default_oven_values(hpxml_default, false)

    # Test defaults w/ appliances
    hpxml = apply_hpxml_defaults('base.xml')
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_clothes_washer_values(hpxml_default, HPXML::LocationLivingSpace, 1.0, 400.0, 0.12, 1.09, 27.0, 3.0, 6.0, 1.0)
    _test_default_clothes_dryer_values(hpxml_default, HPXML::LocationLivingSpace, HPXML::ClothesDryerControlTypeTimer, 3.01, 1.0)
    _test_default_dishwasher_values(hpxml_default, HPXML::LocationLivingSpace, 467.0, 0.12, 1.09, 33.12, 4.0, 12, 1.0)
    _test_default_refrigerator_values(hpxml_default, HPXML::LocationLivingSpace, 691.0, 1.0)
    _test_default_cooking_range_values(hpxml_default, HPXML::LocationLivingSpace, false, 1.0)
    _test_default_oven_values(hpxml_default, false)

    # Test defaults w/ gas clothes dryer
    hpxml = apply_hpxml_defaults('base.xml')
    hpxml.clothes_dryers[0].fuel_type = HPXML::FuelTypeNaturalGas
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_clothes_dryer_values(hpxml_default, HPXML::LocationLivingSpace, HPXML::ClothesDryerControlTypeTimer, 3.01, 1.0)

    # Test defaults w/ refrigerator in 5-bedroom house
    hpxml = apply_hpxml_defaults('base-enclosure-beds-5.xml')
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_refrigerator_values(hpxml_default, HPXML::LocationLivingSpace, 727.0, 1.0)

    # Test defaults w/ appliances before 301-2019 Addendum A
    hpxml = apply_hpxml_defaults('base.xml')
    hpxml.header.eri_calculation_version = '2019'
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_clothes_washer_values(hpxml_default, HPXML::LocationLivingSpace, 0.331, 704.0, 0.08, 0.58, 23.0, 2.874, 6.0, 1.0)
    _test_default_clothes_dryer_values(hpxml_default, HPXML::LocationLivingSpace, HPXML::ClothesDryerControlTypeTimer, 2.62, 1.0)
    _test_default_dishwasher_values(hpxml_default, HPXML::LocationLivingSpace, 467.0, 0.12, 1.09, 33.12, 4.0, 12, 1.0)
    _test_default_refrigerator_values(hpxml_default, HPXML::LocationLivingSpace, 691.0, 1.0)
    _test_default_cooking_range_values(hpxml_default, HPXML::LocationLivingSpace, false, 1.0)
    _test_default_oven_values(hpxml_default, false)

    # Test defaults w/ gas clothes dryer before 301-2019 Addendum A
    hpxml = apply_hpxml_defaults('base.xml')
    hpxml.header.eri_calculation_version = '2019'
    hpxml.clothes_dryers[0].fuel_type = HPXML::FuelTypeNaturalGas
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_clothes_dryer_values(hpxml_default, HPXML::LocationLivingSpace, HPXML::ClothesDryerControlTypeTimer, 2.32, 1.0)
  end

  def test_lighting
    # Test inputs not overridden by defaults
    hpxml_name = 'base.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml.lighting.usage_multiplier = 2.0
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_lighting_values(hpxml_default, 2.0)

    # Test defaults
    hpxml = apply_hpxml_defaults('base.xml')
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_lighting_values(hpxml_default, 1.0)
  end

  def test_pv
    # Test inputs not overridden by defaults
    hpxml_name = 'base-pv.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    hpxml.pv_systems.each do |pv|
      pv.inverter_efficiency = 0.90
      pv.system_losses_fraction = 0.20
    end
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    expected_interver_efficiency = [0.90, 0.90]
    expected_system_loss_frac = [0.20, 0.20]
    _test_default_pv_system_values(hpxml_default, expected_interver_efficiency, expected_system_loss_frac)

    # Test defaults w/o year modules manufactured
    hpxml = apply_hpxml_defaults('base-pv.xml')
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    expected_interver_efficiency = [0.96, 0.96]
    expected_system_loss_frac = [0.14, 0.14]
    _test_default_pv_system_values(hpxml_default, expected_interver_efficiency, expected_system_loss_frac)

    # Test defaults w/ year modules manufactured
    hpxml = apply_hpxml_defaults('base-pv.xml')
    hpxml.pv_systems.each do |pv|
      pv.year_modules_manufactured = 2010
    end
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    expected_interver_efficiency = [0.96, 0.96]
    expected_system_loss_frac = [0.182, 0.182]
    _test_default_pv_system_values(hpxml_default, expected_interver_efficiency, expected_system_loss_frac)
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

  def _test_default_header_values(hpxml, tstep, begin_month, begin_day, end_month, end_day)
    assert_equal(tstep, hpxml.header.timestep)
    assert_equal(begin_month, hpxml.header.begin_month)
    assert_equal(begin_day, hpxml.header.begin_day_of_month)
    assert_equal(end_month, hpxml.header.end_month)
    assert_equal(end_day, hpxml.header.end_day_of_month)
  end

  def _test_default_site_values(hpxml, site_type, shelter_coefficient)
    assert_equal(site_type, hpxml.site.site_type)
    assert_equal(shelter_coefficient, hpxml.site.shelter_coefficient)
  end

  def _test_default_occupancy_values(hpxml, num_occupants)
    assert_equal(num_occupants, hpxml.building_occupancy.number_of_residents)
  end

  def _test_default_duct_values(hpxml, supply_locations, return_locations, supply_areas, return_areas, n_return_registers)
    supply_duct_idx = 0
    return_duct_idx = 0
    hpxml.hvac_distributions.each do |hvac_distribution|
      next unless hvac_distribution.distribution_system_type == HPXML::HVACDistributionTypeAir
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

  def _test_default_pv_system_values(hpxml, interver_efficiency, system_loss_frac)
    assert_equal(interver_efficiency.size, hpxml.pv_systems.size)
    hpxml.pv_systems.each_with_index do |pv, idx|
      assert_equal(interver_efficiency[idx], pv.inverter_efficiency)
      assert_in_epsilon(system_loss_frac[idx], pv.system_losses_fraction, 0.01)
    end
  end

  def _test_default_building_construction_values(hpxml, building_volume)
    assert_equal(building_volume, hpxml.building_construction.conditioned_building_volume)
  end

  def _test_default_attic_values(hpxml, sla)
    assert_equal(sla, hpxml.attics[0].vented_attic_sla)
  end

  def _test_default_foundation_values(hpxml, sla)
    assert_equal(sla, hpxml.foundations[0].vented_crawlspace_sla)
  end

  def _test_default_infiltration_values(hpxml, volume)
    assert_equal(volume, hpxml.air_infiltration_measurements[0].infiltration_volume)
  end

  def _test_default_roof_values(hpxml, roof_type, solar_absorptance, roof_color)
    assert_equal(roof_type, hpxml.roofs[0].roof_type)
    assert_equal(solar_absorptance, hpxml.roofs[0].solar_absorptance)
    assert_equal(roof_color, hpxml.roofs[0].roof_color)
  end

  def _test_default_wall_values(hpxml, siding, solar_absorptance, color)
    assert_equal(siding, hpxml.walls[0].siding)
    assert_equal(solar_absorptance, hpxml.walls[0].solar_absorptance)
    assert_equal(color, hpxml.walls[0].color)
  end

  def _test_default_rim_joist_values(hpxml, siding, solar_absorptance, color)
    assert_equal(siding, hpxml.rim_joists[0].siding)
    assert_equal(solar_absorptance, hpxml.rim_joists[0].solar_absorptance)
    assert_equal(color, hpxml.rim_joists[0].color)
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

  def _test_default_clothes_washer_values(hpxml, location, imef, rated_annual_kwh, label_electric_rate, label_gas_rate, label_annual_gas_cost, capacity, label_usage, usage_multiplier)
    assert_equal(location, hpxml.clothes_washers[0].location)
    assert_equal(imef, hpxml.clothes_washers[0].integrated_modified_energy_factor)
    assert_equal(rated_annual_kwh, hpxml.clothes_washers[0].rated_annual_kwh)
    assert_equal(label_electric_rate, hpxml.clothes_washers[0].label_electric_rate)
    assert_equal(label_gas_rate, hpxml.clothes_washers[0].label_gas_rate)
    assert_equal(label_annual_gas_cost, hpxml.clothes_washers[0].label_annual_gas_cost)
    assert_equal(capacity, hpxml.clothes_washers[0].capacity)
    assert_equal(label_usage, hpxml.clothes_washers[0].label_usage)
    assert_equal(usage_multiplier, hpxml.clothes_washers[0].usage_multiplier)
  end

  def _test_default_clothes_dryer_values(hpxml, location, control_type, cef, usage_multiplier)
    assert_equal(location, hpxml.clothes_dryers[0].location)
    assert_equal(control_type, hpxml.clothes_dryers[0].control_type)
    assert_equal(cef, hpxml.clothes_dryers[0].combined_energy_factor)
    assert_equal(usage_multiplier, hpxml.clothes_dryers[0].usage_multiplier)
  end

  def _test_default_dishwasher_values(hpxml, location, rated_annual_kwh, label_electric_rate, label_gas_rate, label_annual_gas_cost, label_usage, place_setting_capacity, usage_multiplier)
    assert_equal(location, hpxml.dishwashers[0].location)
    assert_equal(rated_annual_kwh, hpxml.dishwashers[0].rated_annual_kwh)
    assert_equal(label_electric_rate, hpxml.dishwashers[0].label_electric_rate)
    assert_equal(label_gas_rate, hpxml.dishwashers[0].label_gas_rate)
    assert_equal(label_annual_gas_cost, hpxml.dishwashers[0].label_annual_gas_cost)
    assert_equal(label_usage, hpxml.dishwashers[0].label_usage)
    assert_equal(place_setting_capacity, hpxml.dishwashers[0].place_setting_capacity)
    assert_equal(usage_multiplier, hpxml.dishwashers[0].usage_multiplier)
  end

  def _test_default_refrigerator_values(hpxml, location, rated_annual_kwh, usage_multiplier)
    assert_equal(location, hpxml.refrigerators[0].location)
    assert_equal(rated_annual_kwh, hpxml.refrigerators[0].rated_annual_kwh)
    assert_equal(usage_multiplier, hpxml.refrigerators[0].usage_multiplier)
  end

  def _test_default_cooking_range_values(hpxml, location, is_induction, usage_multiplier)
    assert_equal(location, hpxml.cooking_ranges[0].location)
    assert_equal(is_induction, hpxml.cooking_ranges[0].is_induction)
    assert_equal(usage_multiplier, hpxml.cooking_ranges[0].usage_multiplier)
  end

  def _test_default_oven_values(hpxml, is_convection)
    assert_equal(is_convection, hpxml.ovens[0].is_convection)
  end

  def _test_default_lighting_values(hpxml, usage_multiplier)
    assert_equal(usage_multiplier, hpxml.lighting.usage_multiplier)
  end

  def _test_default_standard_distribution_values(hpxml, piping_length)
    assert_in_epsilon(piping_length, hpxml.hot_water_distributions[0].standard_piping_length, 0.01)
  end

  def _test_default_recirc_distribution_values(hpxml, piping_length, branch_piping_length, pump_power)
    assert_in_epsilon(piping_length, hpxml.hot_water_distributions[0].recirculation_piping_length, 0.01)
    assert_in_epsilon(branch_piping_length, hpxml.hot_water_distributions[0].recirculation_branch_piping_length, 0.01)
    assert_in_epsilon(pump_power, hpxml.hot_water_distributions[0].recirculation_pump_power, 0.01)
  end

  def _test_default_water_fixture_values(hpxml, usage_multiplier)
    assert_equal(usage_multiplier, hpxml.water_heating.water_fixtures_usage_multiplier)
  end

  def _test_default_solar_thermal_values(hpxml, storage_volume)
    assert_in_epsilon(storage_volume, hpxml.solar_thermal_systems[0].storage_volume)
  end

  def _test_default_kitchen_fan_values(hpxml, rated_flow_rate, hours_in_operation, fan_power, start_hour)
    kitchen_fan = hpxml.ventilation_fans.select { |f| f.used_for_local_ventilation && f.fan_location == HPXML::LocationKitchen }[0]
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

  def _test_default_tv_plug_load_values(hpxml, kWh_per_year)
    tv_pl = hpxml.plug_loads.select { |pl| pl.plug_load_type == HPXML::PlugLoadTypeTelevision }[0]
    assert_equal(kWh_per_year, tv_pl.kWh_per_year)
  end

  def _test_default_other_plug_load_values(hpxml, kWh_per_year, frac_sensible, frac_latent)
    other_pl = hpxml.plug_loads.select { |pl| pl.plug_load_type == HPXML::PlugLoadTypeOther }[0]
    assert_equal(kWh_per_year, other_pl.kWh_per_year)
    assert_in_epsilon(frac_sensible, other_pl.frac_sensible, 0.01)
    assert_in_epsilon(frac_latent, other_pl.frac_latent, 0.01)
  end

  def _test_default_number_of_bathrooms(hpxml, n_bathrooms)
    assert_equal(n_bathrooms, hpxml.building_construction.number_of_bathrooms)
  end

  def _test_default_water_heater_values(hpxml, *expected_wh_values)
    storage_water_heaters = hpxml.water_heating_systems.select { |w| w.water_heater_type == HPXML::WaterHeaterTypeStorage }
    assert_equal(expected_wh_values.size, storage_water_heaters.size)
    storage_water_heaters.each_with_index do |wh_system, idx|
      heating_capacity, tank_volume, recovery_efficiency = expected_wh_values[idx]
      assert_in_epsilon(heating_capacity, wh_system.heating_capacity, 0.01)
      assert_equal(tank_volume, wh_system.tank_volume)
      assert_in_epsilon(recovery_efficiency, wh_system.recovery_efficiency, 0.01)
    end
  end

  def apply_hpxml_defaults(hpxml_name)
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))

    hpxml.header.timestep = nil
    hpxml.header.begin_month = nil
    hpxml.header.begin_day_of_month = nil
    hpxml.header.end_month = nil
    hpxml.header.end_day_of_month = nil

    hpxml.site.site_type = nil
    hpxml.site.shelter_coefficient = nil

    hpxml.building_construction.conditioned_building_volume = nil
    hpxml.building_construction.average_ceiling_height = 10
    hpxml.building_construction.number_of_bathrooms = nil

    hpxml.attics.each do |attic|
      attic.vented_attic_sla = nil
    end

    hpxml.foundations.each do |foundation|
      foundation.vented_crawlspace_sla = nil
    end

    hpxml.air_infiltration_measurements.each do |infil|
      infil.infiltration_volume = nil
    end

    hpxml.roofs.each do |roof|
      roof.roof_type = nil
      roof.solar_absorptance = nil
      roof.roof_color = HPXML::ColorLight
    end

    hpxml.walls.each do |wall|
      wall.siding = nil
      wall.solar_absorptance = nil
      wall.color = HPXML::ColorLight
    end

    hpxml.rim_joists.each do |rim_joist|
      rim_joist.siding = nil
      rim_joist.solar_absorptance = nil
      rim_joist.color = HPXML::ColorDark
    end

    hpxml.windows.each do |window|
      window.fraction_operable = nil
      window.interior_shading_factor_summer = nil
      window.interior_shading_factor_winter = nil
    end

    hpxml.skylights.each do |skylight|
      skylight.interior_shading_factor_summer = nil
      skylight.interior_shading_factor_winter = nil
    end

    hpxml.hvac_distributions.each do |hvac_distribution|
      hvac_distribution.ducts.each do |duct|
        duct.duct_location = nil
        duct.duct_surface_area = nil
      end
    end

    hpxml.water_heating.water_fixtures_usage_multiplier = nil

    hpxml.water_heating_systems.each do |water_heating_system|
      next unless water_heating_system.water_heater_type == HPXML::WaterHeaterTypeStorage

      water_heating_system.heating_capacity = nil
      water_heating_system.tank_volume = nil
      water_heating_system.recovery_efficiency = nil
    end

    if hpxml.hot_water_distributions[0].system_type == HPXML::DHWDistTypeStandard
      hpxml.hot_water_distributions[0].standard_piping_length = nil
    end

    if hpxml.hot_water_distributions[0].system_type == HPXML::DHWDistTypeRecirc
      hpxml.hot_water_distributions[0].recirculation_piping_length = nil
      hpxml.hot_water_distributions[0].recirculation_branch_piping_length = nil
      hpxml.hot_water_distributions[0].recirculation_pump_power = nil
    end

    hpxml.solar_thermal_systems.each do |solar_thermal_system|
      solar_thermal_system.storage_volume = nil
    end

    hpxml.ventilation_fans.each do |vent_fan|
      next unless vent_fan.used_for_local_ventilation

      vent_fan.quantity = nil
      vent_fan.rated_flow_rate = nil
      vent_fan.hours_in_operation = nil
      vent_fan.fan_power = nil
      vent_fan.start_hour = nil
    end

    hpxml.ceiling_fans.each do |ceiling_fan|
      ceiling_fan.quantity = nil
      ceiling_fan.efficiency = nil
    end

    hpxml.clothes_washers[0].location = nil
    hpxml.clothes_washers[0].integrated_modified_energy_factor = nil
    hpxml.clothes_washers[0].rated_annual_kwh = nil
    hpxml.clothes_washers[0].label_electric_rate = nil
    hpxml.clothes_washers[0].label_gas_rate = nil
    hpxml.clothes_washers[0].label_annual_gas_cost = nil
    hpxml.clothes_washers[0].capacity = nil
    hpxml.clothes_washers[0].label_usage = nil
    hpxml.clothes_washers[0].usage_multiplier = nil

    hpxml.clothes_dryers[0].location = nil
    hpxml.clothes_dryers[0].control_type = nil
    hpxml.clothes_dryers[0].combined_energy_factor = nil
    hpxml.clothes_dryers[0].usage_multiplier = nil

    hpxml.dishwashers[0].location = nil
    hpxml.dishwashers[0].rated_annual_kwh = nil
    hpxml.dishwashers[0].label_electric_rate = nil
    hpxml.dishwashers[0].label_gas_rate = nil
    hpxml.dishwashers[0].label_annual_gas_cost = nil
    hpxml.dishwashers[0].label_usage = nil
    hpxml.dishwashers[0].place_setting_capacity = nil
    hpxml.dishwashers[0].usage_multiplier = nil

    hpxml.refrigerators[0].location = nil
    hpxml.refrigerators[0].rated_annual_kwh = nil
    hpxml.refrigerators[0].usage_multiplier = nil

    hpxml.cooking_ranges[0].location = nil
    hpxml.cooking_ranges[0].is_induction = nil
    hpxml.cooking_ranges[0].usage_multiplier = nil

    hpxml.ovens[0].is_convection = nil

    hpxml.plug_loads.each do |plug_load|
      plug_load.kWh_per_year = nil
      plug_load.frac_sensible = nil
      plug_load.frac_latent = nil
    end

    hpxml.lighting.usage_multiplier = nil

    hpxml.pv_systems.each do |pv|
      pv.inverter_efficiency = nil
      pv.system_losses_fraction = nil
    end

    return hpxml
  end
end
