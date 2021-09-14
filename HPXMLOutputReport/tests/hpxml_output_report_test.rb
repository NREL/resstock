# frozen_string_literal: true

require_relative '../../HPXMLtoOpenStudio/resources/minitest_helper'
require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'fileutils'
require 'csv'
require_relative '../measure.rb'

class HPXMLOutputReportTest < MiniTest::Test
  Rows = [
    'Surface Area: Wall Above-Grade Conditioned (ft^2)',
    'Surface Area: Wall Above-Grade Exterior (ft^2)',
    'Surface Area: Wall Below-Grade (ft^2)',
    'Surface Area: Floor Conditioned (ft^2)',
    'Surface Area: Floor Attic (ft^2)',
    'Surface Area: Floor Lighting (ft^2)',
    'Surface Area: Roof (ft^2)',
    'Surface Area: Window (ft^2)',
    'Surface Area: Door (ft^2)',
    'Surface Area: Duct Unconditioned (ft^2)',
    'Surface Area: Rim Joist Above-Grade Exterior (ft^2)',
    'Size: Heating System (kBtu/h)',
    'Size: Cooling System (kBtu/h)',
    'Size: Heat Pump Backup (kBtu/h)',
    'Size: Water Heater (gal)',
    'Other: Flow Rate Mechanical Ventilation (cfm)',
    'Other: Slab Perimeter Exposed Conditioned (ft)',
  ]

  def test_base_results_hpxml
    args_hash = {}
    hpxml_csv = _test_measure(args_hash)
    assert(File.exist?(hpxml_csv))
    expected_rows = Rows
    actual_rows = File.readlines(hpxml_csv).map { |x| x.split(',')[0].strip }.select { |x| !x.empty? }
    assert_equal(expected_rows.sort, actual_rows.sort)
  end

  def test_base_results_hpxml_with_primary_systems
    args_hash = { 'hpxml_path' => '../workflow/sample_files/base-hvac-multiple.xml' }
    hpxml_csv = _test_measure(args_hash)
    assert(File.exist?(hpxml_csv))
    actual_rows = File.readlines(hpxml_csv).map { |x| x.split(',')[0].strip }.select { |x| !x.empty? }
    assert_includes(actual_rows.sort, 'Size: Heating System (kBtu/h)')
    assert_includes(actual_rows.sort, 'Size: Cooling System (kBtu/h)')
    assert_includes(actual_rows.sort, 'Size: Heating System: Primary (kBtu/h)')
    assert_includes(actual_rows.sort, 'Size: Heating System: Secondary (kBtu/h)')
    assert_includes(actual_rows.sort, 'Size: Cooling System: Primary (kBtu/h)')
    assert_includes(actual_rows.sort, 'Size: Cooling System: Secondary (kBtu/h)')
    assert(!actual_rows.sort.include?('Size: Heat Pump Backup: Primary (kBtu/h)')) # there is no primary heat pump
    assert_includes(actual_rows.sort, 'Size: Heat Pump Backup: Secondary (kBtu/h)') # all heat pumps are secondary
  end

  def test_furnace_and_central_air_conditioner_xml
    args_hash = {}
    hpxml_csv = _test_measure(args_hash)
    assert(File.exist?(hpxml_csv))

    expected_multipliers = {
      'Surface Area: Wall Above-Grade Conditioned (ft^2)' => 1200.0,
      'Surface Area: Wall Above-Grade Exterior (ft^2)' => 1490.0,
      'Surface Area: Wall Below-Grade (ft^2)' => 1200.0,
      'Surface Area: Floor Conditioned (ft^2)' => 2700.0,
      'Surface Area: Floor Attic (ft^2)' => 1350.0,
      'Surface Area: Floor Lighting (ft^2)' => 2700.0,
      'Surface Area: Roof (ft^2)' => 1509.3,
      'Surface Area: Window (ft^2)' => 360.0,
      'Surface Area: Door (ft^2)' => 40.0,
      'Surface Area: Duct Unconditioned (ft^2)' => 200.0,
      'Surface Area: Rim Joist Above-Grade Exterior (ft^2)' => 116.0,
      'Size: Heating System (kBtu/h)' => 36.0,
      'Size: Cooling System (kBtu/h)' => 24.0,
      'Size: Heat Pump Backup (kBtu/h)' => 0.0,
      'Size: Water Heater (gal)' => 40.0,
      'Other: Flow Rate Mechanical Ventilation (cfm)' => 0.0,
      'Other: Slab Perimeter Exposed Conditioned (ft)' => 150.0
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
      'Surface Area: Wall Above-Grade Conditioned (ft^2)' => 1200.0,
      'Surface Area: Wall Above-Grade Exterior (ft^2)' => 1490.0,
      'Surface Area: Wall Below-Grade (ft^2)' => 1200.0,
      'Surface Area: Floor Conditioned (ft^2)' => 2700.0,
      'Surface Area: Floor Attic (ft^2)' => 1350.0,
      'Surface Area: Floor Lighting (ft^2)' => 2700.0,
      'Surface Area: Roof (ft^2)' => 1509.3,
      'Surface Area: Window (ft^2)' => 360.0,
      'Surface Area: Door (ft^2)' => 40.0,
      'Surface Area: Duct Unconditioned (ft^2)' => 200.0,
      'Surface Area: Rim Joist Above-Grade Exterior (ft^2)' => 116.0,
      'Size: Heating System (kBtu/h)' => 36.0,
      'Size: Cooling System (kBtu/h)' => 36.0,
      'Size: Heat Pump Backup (kBtu/h)' => 36.0,
      'Size: Water Heater (gal)' => 40.0,
      'Other: Flow Rate Mechanical Ventilation (cfm)' => 0.0,
      'Other: Slab Perimeter Exposed Conditioned (ft)' => 150.0
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
