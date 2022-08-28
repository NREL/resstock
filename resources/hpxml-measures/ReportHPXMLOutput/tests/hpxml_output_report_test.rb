# frozen_string_literal: true

require_relative '../../HPXMLtoOpenStudio/resources/minitest_helper'
require_relative '../../HPXMLtoOpenStudio/resources/hpxml'
require_relative '../../HPXMLtoOpenStudio/resources/xmlhelper'
require 'oga'
require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'fileutils'
require 'csv'
require_relative '../measure.rb'

class ReportHPXMLOutputTest < MiniTest::Test
  def test_hpxml_with_primary_systems
    args_hash = { 'hpxml_path' => '../../../workflow/sample_files/base-hvac-multiple.xml' }
    hpxml_csv = _test_measure(args_hash)
    assert(File.exist?(hpxml_csv))
    actual_rows = File.readlines(hpxml_csv).map { |x| x.split(',')[0].strip }.select { |x| !x.empty? }
    assert_includes(actual_rows, 'Systems: Heating Capacity (Btu/h)')
    assert_includes(actual_rows, 'Systems: Cooling Capacity (Btu/h)')
    assert_includes(actual_rows, 'Primary Systems: Cooling Capacity (Btu/h)')
    assert_includes(actual_rows, 'Primary Systems: Heating Capacity (Btu/h)')
    assert_includes(actual_rows, 'Primary Systems: Heat Pump Backup Capacity (Btu/h)')
    assert_includes(actual_rows, 'Secondary Systems: Cooling Capacity (Btu/h)')
    assert_includes(actual_rows, 'Secondary Systems: Heating Capacity (Btu/h)')
    assert_includes(actual_rows, 'Secondary Systems: Heat Pump Backup Capacity (Btu/h)')
  end

  def test_hpxml_without_primary_systems
    hpxml = HPXML.new(hpxml_path: File.join(File.dirname(__FILE__), '..', '..', 'workflow', 'sample_files', 'base.xml'))
    hpxml.hvac_systems.each do |hvac_system|
      hvac_system.primary_system = false
    end
    tmp_hpxml_path = File.join(File.dirname(__FILE__), 'tmp.xml')
    XMLHelper.write_file(hpxml.to_oga(), tmp_hpxml_path)
    args_hash = { 'hpxml_path' => '../../../ReportHPXMLOutput/tests/tmp.xml' }
    hpxml_csv = _test_measure(args_hash)
    File.delete(tmp_hpxml_path) if File.exist?(tmp_hpxml_path)
    assert(File.exist?(hpxml_csv))
    actual_rows = File.readlines(hpxml_csv).map { |x| x.split(',')[0].strip }.select { |x| !x.empty? }
    assert_includes(actual_rows, 'Systems: Heating Capacity (Btu/h)')
    assert_includes(actual_rows, 'Systems: Cooling Capacity (Btu/h)')
    refute_includes(actual_rows, 'Primary Systems: Cooling Capacity (Btu/h)')
    refute_includes(actual_rows, 'Primary Systems: Heating Capacity (Btu/h)')
    refute_includes(actual_rows, 'Primary Systems: Heat Pump Backup Capacity (Btu/h)')
    refute_includes(actual_rows, 'Secondary Systems: Cooling Capacity (Btu/h)')
    refute_includes(actual_rows, 'Secondary Systems: Heating Capacity (Btu/h)')
    refute_includes(actual_rows, 'Secondary Systems: Heat Pump Backup Capacity (Btu/h)')
  end

  def test_furnace_and_central_air_conditioner_xml
    args_hash = {}
    hpxml_csv = _test_measure(args_hash)
    assert(File.exist?(hpxml_csv))

    expected_multipliers = {
      'Enclosure: Wall Area Thermal Boundary (ft^2)' => 1200.0,
      'Enclosure: Wall Area Exterior (ft^2)' => 1425.0,
      'Enclosure: Foundation Wall Area Exterior (ft^2)' => 1200.0,
      'Enclosure: Floor Area Conditioned (ft^2)' => 2700.0,
      'Enclosure: Floor Area Lighting (ft^2)' => 2700.0,
      'Enclosure: Floor Area Foundation (ft^2)' => 1350.0,
      'Enclosure: Ceiling Area Thermal Boundary (ft^2)' => 1350.0,
      'Enclosure: Roof Area (ft^2)' => 1509.4,
      'Enclosure: Window Area (ft^2)' => 360.0,
      'Enclosure: Door Area (ft^2)' => 40.0,
      'Enclosure: Duct Area Unconditioned (ft^2)' => 200.0,
      'Enclosure: Rim Joist Area (ft^2)' => 115.6,
      'Enclosure: Slab Exposed Perimeter Thermal Boundary (ft)' => 150.0,
      'Systems: Heating Capacity (Btu/h)' => 36000.0,
      'Systems: Cooling Capacity (Btu/h)' => 24000.0,
      'Systems: Heat Pump Backup Capacity (Btu/h)' => 0.0,
      'Systems: Water Heater Tank Volume (gal)' => 40.0,
      'Systems: Mechanical Ventilation Flow Rate (cfm)' => 0.0,
      'Primary Systems: Heating Capacity (Btu/h)' => 36000.0,
      'Primary Systems: Cooling Capacity (Btu/h)' => 24000.0,
      'Primary Systems: Heat Pump Backup Capacity (Btu/h)' => 0.0,
      'Design Loads Heating: Total (Btu/h)' => 32302.0,
      'Design Loads Heating: Ducts (Btu/h)' => 8597.0,
      'Design Loads Heating: Windows (Btu/h)' => 7508.0,
      'Design Loads Heating: Skylights (Btu/h)' => 0.0,
      'Design Loads Heating: Doors (Btu/h)' => 575.0,
      'Design Loads Heating: Walls (Btu/h)' => 6409.0,
      'Design Loads Heating: Roofs (Btu/h)' => 0.0,
      'Design Loads Heating: Floors (Btu/h)' => 0.0,
      'Design Loads Heating: Slabs (Btu/h)' => 2446.0,
      'Design Loads Heating: Ceilings (Btu/h)' => 2171.0,
      'Design Loads Heating: Infiltration/Ventilation (Btu/h)' => 4597.0,
      'Design Loads Cooling Sensible: Total (Btu/h)' => 17964.0,
      'Design Loads Cooling Sensible: Ducts (Btu/h)' => 5216.0,
      'Design Loads Cooling Sensible: Windows (Btu/h)' => 7127.0,
      'Design Loads Cooling Sensible: Skylights (Btu/h)' => 0.0,
      'Design Loads Cooling Sensible: Doors (Btu/h)' => 207.0,
      'Design Loads Cooling Sensible: Walls (Btu/h)' => 265.0,
      'Design Loads Cooling Sensible: Roofs (Btu/h)' => 0.0,
      'Design Loads Cooling Sensible: Floors (Btu/h)' => 0.0,
      'Design Loads Cooling Sensible: Slabs (Btu/h)' => 0.0,
      'Design Loads Cooling Sensible: Ceilings (Btu/h)' => 2010.0,
      'Design Loads Cooling Sensible: Infiltration/Ventilation (Btu/h)' => 619.0,
      'Design Loads Cooling Sensible: Internal Gains (Btu/h)' => 2520.0,
      'Design Loads Cooling Latent: Total (Btu/h)' => 0.0,
      'Design Loads Cooling Latent: Ducts (Btu/h)' => 0.0,
      'Design Loads Cooling Latent: Infiltration/Ventilation (Btu/h)' => 0.0,
      'Design Loads Cooling Latent: Internal Gains (Btu/h)' => 0.0
    }

    actual_multipliers = _get_actual_multipliers(hpxml_csv)
    assert_equal(expected_multipliers, actual_multipliers)
  end

  def test_air_source_heat_pump_xml
    hpxml_files = ['base-hvac-air-to-air-heat-pump-1-speed.xml',
                   'base-hvac-air-to-air-heat-pump-var-speed-backup-boiler.xml']
    hpxml_files.each do |hpxml_file|
      args_hash = { 'hpxml_path' => "../../../workflow/sample_files/#{hpxml_file}" }
      hpxml_csv = _test_measure(args_hash)
      assert(File.exist?(hpxml_csv))

      if hpxml_file == 'base-hvac-air-to-air-heat-pump-1-speed.xml'
        hp_capacity = 36000.0
        backup_capacity = 36000.0
      elsif hpxml_file == 'base-hvac-air-to-air-heat-pump-var-speed-backup-boiler.xml'
        hp_capacity = 18000.0
        backup_capacity = 60000.0
      end

      expected_multipliers = {
        'Enclosure: Wall Area Thermal Boundary (ft^2)' => 1200.0,
        'Enclosure: Wall Area Exterior (ft^2)' => 1425.0,
        'Enclosure: Foundation Wall Area Exterior (ft^2)' => 1200.0,
        'Enclosure: Floor Area Conditioned (ft^2)' => 2700.0,
        'Enclosure: Floor Area Lighting (ft^2)' => 2700.0,
        'Enclosure: Floor Area Foundation (ft^2)' => 1350.0,
        'Enclosure: Ceiling Area Thermal Boundary (ft^2)' => 1350.0,
        'Enclosure: Roof Area (ft^2)' => 1509.4,
        'Enclosure: Window Area (ft^2)' => 360.0,
        'Enclosure: Door Area (ft^2)' => 40.0,
        'Enclosure: Duct Area Unconditioned (ft^2)' => 200.0,
        'Enclosure: Rim Joist Area (ft^2)' => 115.6,
        'Enclosure: Slab Exposed Perimeter Thermal Boundary (ft)' => 150.0,
        'Systems: Heating Capacity (Btu/h)' => hp_capacity,
        'Systems: Cooling Capacity (Btu/h)' => hp_capacity,
        'Systems: Heat Pump Backup Capacity (Btu/h)' => backup_capacity,
        'Systems: Water Heater Tank Volume (gal)' => 40.0,
        'Systems: Mechanical Ventilation Flow Rate (cfm)' => 0.0,
        'Primary Systems: Heating Capacity (Btu/h)' => hp_capacity,
        'Primary Systems: Cooling Capacity (Btu/h)' => hp_capacity,
        'Primary Systems: Heat Pump Backup Capacity (Btu/h)' => backup_capacity,
        'Design Loads Heating: Total (Btu/h)' => 31214.0,
        'Design Loads Heating: Ducts (Btu/h)' => 7508.0,
        'Design Loads Heating: Windows (Btu/h)' => 7508.0,
        'Design Loads Heating: Skylights (Btu/h)' => 0.0,
        'Design Loads Heating: Doors (Btu/h)' => 575.0,
        'Design Loads Heating: Walls (Btu/h)' => 6409.0,
        'Design Loads Heating: Roofs (Btu/h)' => 0.0,
        'Design Loads Heating: Floors (Btu/h)' => 0.0,
        'Design Loads Heating: Slabs (Btu/h)' => 2446.0,
        'Design Loads Heating: Ceilings (Btu/h)' => 2171.0,
        'Design Loads Heating: Infiltration/Ventilation (Btu/h)' => 4597.0,
        'Design Loads Cooling Sensible: Total (Btu/h)' => 17964.0,
        'Design Loads Cooling Sensible: Ducts (Btu/h)' => 5216.0,
        'Design Loads Cooling Sensible: Windows (Btu/h)' => 7127.0,
        'Design Loads Cooling Sensible: Skylights (Btu/h)' => 0.0,
        'Design Loads Cooling Sensible: Doors (Btu/h)' => 207.0,
        'Design Loads Cooling Sensible: Walls (Btu/h)' => 265.0,
        'Design Loads Cooling Sensible: Roofs (Btu/h)' => 0.0,
        'Design Loads Cooling Sensible: Floors (Btu/h)' => 0.0,
        'Design Loads Cooling Sensible: Slabs (Btu/h)' => 0.0,
        'Design Loads Cooling Sensible: Ceilings (Btu/h)' => 2010.0,
        'Design Loads Cooling Sensible: Infiltration/Ventilation (Btu/h)' => 619.0,
        'Design Loads Cooling Sensible: Internal Gains (Btu/h)' => 2520.0,
        'Design Loads Cooling Latent: Total (Btu/h)' => 0.0,
        'Design Loads Cooling Latent: Ducts (Btu/h)' => 0.0,
        'Design Loads Cooling Latent: Infiltration/Ventilation (Btu/h)' => 0.0,
        'Design Loads Cooling Latent: Internal Gains (Btu/h)' => 0.0
      }

      actual_multipliers = _get_actual_multipliers(hpxml_csv)
      assert_equal(expected_multipliers, actual_multipliers)
    end
  end

  def test_foundations
    hpxml_files = ['base-foundation-ambient.xml',
                   'base-foundation-basement-garage.xml',
                   'base-foundation-conditioned-basement-slab-insulation.xml',
                   'base-foundation-conditioned-crawlspace.xml',
                   'base-foundation-slab.xml',
                   'base-foundation-unconditioned-basement.xml',
                   'base-foundation-unvented-crawlspace.xml',
                   'base-foundation-vented-crawlspace.xml',
                   'base-foundation-walkout-basement.xml']
    hpxml_files.each do |hpxml_file|
      args_hash = { 'hpxml_path' => "../../../workflow/sample_files/#{hpxml_file}" }
      hpxml_csv = _test_measure(args_hash)
      assert(File.exist?(hpxml_csv))

      foundation_wall_area_exterior = 1200.0
      floor_area_foundation = 1350.0
      rim_joist_area = 115.6
      slab_exposed_perimeter_thermal_boundary = 150.0

      if hpxml_file == 'base-foundation-ambient.xml'
        foundation_wall_area_exterior = 0.0
        floor_area_foundation = 0.0
        rim_joist_area = 0.0
        slab_exposed_perimeter_thermal_boundary = 0.0
      elsif hpxml_file == 'base-foundation-basement-garage.xml'
        floor_area_foundation = 950.0
        slab_exposed_perimeter_thermal_boundary = 110.0
      elsif hpxml_file == 'base-foundation-conditioned-crawlspace.xml'
        foundation_wall_area_exterior = 600.0
      elsif hpxml_file == 'base-foundation-slab.xml'
        foundation_wall_area_exterior = 0.0
        rim_joist_area = 0.0
      elsif hpxml_file == 'base-foundation-unconditioned-basement.xml'
        slab_exposed_perimeter_thermal_boundary = 0.0
      elsif hpxml_file == 'base-foundation-unvented-crawlspace.xml'
        foundation_wall_area_exterior = 600.0
        slab_exposed_perimeter_thermal_boundary = 0.0
      elsif hpxml_file == 'base-foundation-vented-crawlspace.xml'
        foundation_wall_area_exterior = 600.0
        slab_exposed_perimeter_thermal_boundary = 0.0
      elsif hpxml_file == 'base-foundation-walkout-basement.xml'
        foundation_wall_area_exterior = 660.0
      end

      expected_multipliers = {
        'Enclosure: Foundation Wall Area Exterior (ft^2)' => foundation_wall_area_exterior,
        'Enclosure: Floor Area Foundation (ft^2)' => floor_area_foundation,
        'Enclosure: Rim Joist Area (ft^2)' => rim_joist_area,
        'Enclosure: Slab Exposed Perimeter Thermal Boundary (ft)' => slab_exposed_perimeter_thermal_boundary
      }

      actual_multipliers = _get_actual_multipliers(hpxml_csv)
      expected_multipliers.each do |multiplier_name, expected_multiplier|
        assert_equal(expected_multiplier, actual_multipliers[multiplier_name])
      end
    end
  end

  def _get_actual_multipliers(hpxml_csv)
    actual_multipliers = {}
    File.readlines(hpxml_csv).each do |line|
      next if line.strip.empty?

      key, value = line.split(',').map { |x| x.strip }
      actual_multipliers[key] = Float(value)
    end
    return actual_multipliers
  end

  def _test_measure(args_hash)
    # Run measure via OSW
    require 'json'
    template_osw = File.join(File.dirname(__FILE__), '..', '..', 'workflow', 'template-run-hpxml.osw')
    workflow = OpenStudio::WorkflowJSON.new(template_osw)
    json = JSON.parse(workflow.to_s)

    # Update measure args
    steps = OpenStudio::WorkflowStepVector.new
    found_args = []
    json['steps'].each do |json_step|
      step = OpenStudio::MeasureStep.new(json_step['measure_dir_name'])
      json_step['arguments'].each do |json_arg_name, json_arg_val|
        if args_hash.keys.include? json_arg_name
          # Override value
          found_args << json_arg_name
          json_arg_val = args_hash[json_arg_name]
        end
        step.setArgument(json_arg_name, json_arg_val)
      end
      steps.push(step)
    end
    workflow.setWorkflowSteps(steps)
    osw_path = File.join(File.dirname(template_osw), 'test.osw')
    workflow.saveAs(osw_path)
    assert_equal(args_hash.size, found_args.size)

    # Run OSW
    success = system("#{OpenStudio.getOpenStudioCLI} run -w \"#{osw_path}\"")
    assert_equal(true, success)

    # Cleanup
    File.delete(osw_path)

    hpxml_csv = File.join(File.dirname(template_osw), 'run', 'results_hpxml.csv')
    return hpxml_csv
  end
end
