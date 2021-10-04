# frozen_string_literal: true

require_relative '../../HPXMLtoOpenStudio/resources/minitest_helper'
require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'fileutils'
require 'csv'
require_relative '../measure.rb'

class ReportHPXMLOutputTest < MiniTest::Test
  Rows = [
    'Enclosure: Wall Area Thermal Boundary (ft^2)',
    'Enclosure: Wall Area Exterior (ft^2)',
    'Enclosure: Foundation Wall Area Exterior (ft^2)',
    'Enclosure: Floor Area Conditioned (ft^2)',
    'Enclosure: Floor Area Lighting (ft^2)',
    'Enclosure: Ceiling Area Thermal Boundary (ft^2)',
    'Enclosure: Roof Area (ft^2)',
    'Enclosure: Window Area (ft^2)',
    'Enclosure: Door Area (ft^2)',
    'Enclosure: Duct Area Unconditioned (ft^2)',
    'Enclosure: Rim Joist Area (ft^2)',
    'Enclosure: Slab Exposed Perimeter Thermal Boundary (ft)',
    'Systems: Heating Capacity (kBtu/h)',
    'Systems: Cooling Capacity (kBtu/h)',
    'Systems: Heat Pump Backup Capacity (kBtu/h)',
    'Systems: Water Heater Tank Volume (gal)',
    'Systems: Mechanical Ventilation Flow Rate (cfm)',
    'Primary Systems: Cooling Capacity (kBtu/h)',
    'Primary Systems: Heating Capacity (kBtu/h)',
    'Primary Systems: Heat Pump Backup Capacity (kBtu/h)'
  ]

  def test_base_results_hpxml
    args_hash = {}
    hpxml_csv = _test_measure(args_hash)
    assert(File.exist?(hpxml_csv))
    expected_rows = Rows
    actual_rows = File.readlines(hpxml_csv).map { |x| x.split(',')[0].strip }.select { |x| !x.empty? }
    assert_equal(expected_rows.sort, actual_rows.sort)
  end

  def test_base_results_hpxml_with_secondary_systems
    args_hash = { 'hpxml_path' => '../workflow/sample_files/base-hvac-multiple.xml' }
    hpxml_csv = _test_measure(args_hash)
    assert(File.exist?(hpxml_csv))
    actual_rows = File.readlines(hpxml_csv).map { |x| x.split(',')[0].strip }.select { |x| !x.empty? }
    assert_includes(actual_rows.sort, 'Systems: Heating Capacity (kBtu/h)')
    assert_includes(actual_rows.sort, 'Systems: Cooling Capacity (kBtu/h)')
    assert_includes(actual_rows.sort, 'Primary Systems: Cooling Capacity (kBtu/h)')
    assert_includes(actual_rows.sort, 'Primary Systems: Heating Capacity (kBtu/h)')
    assert_includes(actual_rows.sort, 'Primary Systems: Heat Pump Backup Capacity (kBtu/h)')
    assert_includes(actual_rows.sort, 'Secondary Systems: Cooling Capacity (kBtu/h)')
    assert_includes(actual_rows.sort, 'Secondary Systems: Heating Capacity (kBtu/h)')
    assert_includes(actual_rows.sort, 'Secondary Systems: Heat Pump Backup Capacity (kBtu/h)')
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
      'Enclosure: Ceiling Area Thermal Boundary (ft^2)' => 1350.0,
      'Enclosure: Roof Area (ft^2)' => 1509.4,
      'Enclosure: Window Area (ft^2)' => 360.0,
      'Enclosure: Door Area (ft^2)' => 40.0,
      'Enclosure: Duct Area Unconditioned (ft^2)' => 200.0,
      'Enclosure: Rim Joist Area (ft^2)' => 115.6,
      'Enclosure: Slab Exposed Perimeter Thermal Boundary (ft)' => 150.0,
      'Systems: Heating Capacity (kBtu/h)' => 36.0,
      'Systems: Cooling Capacity (kBtu/h)' => 24.0,
      'Systems: Heat Pump Backup Capacity (kBtu/h)' => 0.0,
      'Systems: Water Heater Tank Volume (gal)' => 40.0,
      'Systems: Mechanical Ventilation Flow Rate (cfm)' => 0.0,
      'Primary Systems: Heating Capacity (kBtu/h)' => 36.0,
      'Primary Systems: Cooling Capacity (kBtu/h)' => 24.0,
      'Primary Systems: Heat Pump Backup Capacity (kBtu/h)' => 0.0
    }

    actual_multipliers = {}
    File.readlines(hpxml_csv).each do |line|
      next if line.strip.empty?

      key, value = line.split(',').map { |x| x.strip }
      actual_multipliers[key] = Float(value)
    end

    assert_equal(expected_multipliers, actual_multipliers)
  end

  def test_air_source_heat_pump_xml
    args_hash = { 'hpxml_path' => '../workflow/sample_files/base-hvac-air-to-air-heat-pump-1-speed.xml' }
    hpxml_csv = _test_measure(args_hash)
    assert(File.exist?(hpxml_csv))

    expected_multipliers = {
      'Enclosure: Wall Area Thermal Boundary (ft^2)' => 1200.0,
      'Enclosure: Wall Area Exterior (ft^2)' => 1425.0,
      'Enclosure: Foundation Wall Area Exterior (ft^2)' => 1200.0,
      'Enclosure: Floor Area Conditioned (ft^2)' => 2700.0,
      'Enclosure: Floor Area Lighting (ft^2)' => 2700.0,
      'Enclosure: Ceiling Area Thermal Boundary (ft^2)' => 1350.0,
      'Enclosure: Roof Area (ft^2)' => 1509.4,
      'Enclosure: Window Area (ft^2)' => 360.0,
      'Enclosure: Door Area (ft^2)' => 40.0,
      'Enclosure: Duct Area Unconditioned (ft^2)' => 200.0,
      'Enclosure: Rim Joist Area (ft^2)' => 115.6,
      'Enclosure: Slab Exposed Perimeter Thermal Boundary (ft)' => 150.0,
      'Systems: Heating Capacity (kBtu/h)' => 36.0,
      'Systems: Cooling Capacity (kBtu/h)' => 36.0,
      'Systems: Heat Pump Backup Capacity (kBtu/h)' => 36.0,
      'Systems: Water Heater Tank Volume (gal)' => 40.0,
      'Systems: Mechanical Ventilation Flow Rate (cfm)' => 0.0,
      'Primary Systems: Heating Capacity (kBtu/h)' => 36.0,
      'Primary Systems: Cooling Capacity (kBtu/h)' => 36.0,
      'Primary Systems: Heat Pump Backup Capacity (kBtu/h)' => 36.0
    }

    actual_multipliers = {}
    File.readlines(hpxml_csv).each do |line|
      next if line.strip.empty?

      key, value = line.split(',').map { |x| x.strip }
      actual_multipliers[key] = Float(value)
    end

    assert_equal(expected_multipliers, actual_multipliers)
  end

  def _test_measure(args_hash)
    # Run measure via OSW
    require 'json'
    template_osw = File.join(File.dirname(__FILE__), '..', '..', 'workflow', 'template.osw')
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
    success = system("#{OpenStudio.getOpenStudioCLI} run -w #{osw_path}")
    assert_equal(true, success)

    # Cleanup
    File.delete(osw_path)

    hpxml_csv = File.join(File.dirname(template_osw), 'run', 'results_hpxml.csv')
    return hpxml_csv
  end
end
