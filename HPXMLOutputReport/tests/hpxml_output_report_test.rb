# frozen_string_literal: true

require_relative '../../HPXMLtoOpenStudio/resources/minitest_helper'
require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'fileutils'
require 'csv'
require_relative '../measure.rb'

class HPXMLOutputReportTest < MiniTest::Test
  Rows = [
    'Building Summary: Fixed (1)',
    'Building Summary: Wall Area Above-Grade Conditioned (ft^2)',
    'Building Summary: Wall Area Above-Grade Exterior (ft^2)',
    'Building Summary: Wall Area Below-Grade (ft^2)',
    'Building Summary: Floor Area Conditioned (ft^2)',
    'Building Summary: Floor Area Attic (ft^2)',
    'Building Summary: Floor Area Lighting (ft^2)',
    'Building Summary: Roof Area (ft^2)',
    'Building Summary: Window Area (ft^2)',
    'Building Summary: Door Area (ft^2)',
    'Building Summary: Duct Unconditioned Surface Area (ft^2)',
    'Building Summary: Size Heating System: HeatingSystem (kBtu/h)',
    'Building Summary: Size Cooling System: CoolingSystem (kBtu/h)',
    'Building Summary: Size Water Heater (gal)',
    'Building Summary: Flow Rate Mechanical Ventilation (cfm)',
    'Building Summary: Slab Perimeter Exposed Conditioned (ft)',
    'Building Summary: Rim Joist Area Above-Grade Exterior (ft^2)',
  ]

  def test_base_hpxml_output
    args_hash = {}
    hpxml_csv = _test_measure(args_hash)
    assert(File.exist?(hpxml_csv))
    expected_rows = Rows
    actual_rows = File.readlines(hpxml_csv).map { |x| x.split(',')[0].strip }.select { |x| !x.empty? }
    assert_equal(expected_rows.sort, actual_rows.sort)
  end

  def test_base_hpxml_output_with_primary_systems
    args_hash = { 'hpxml_path' => '../workflow/sample_files/base-hvac-multiple2.xml' }
    hpxml_csv = _test_measure(args_hash)
    assert(File.exist?(hpxml_csv))
    actual_rows = File.readlines(hpxml_csv).map { |x| x.split(',')[0].strip }.select { |x| !x.empty? }
    assert_includes(actual_rows.sort, 'Building Summary: Size Heating System: HeatingSystem2 (kBtu/h)')
    assert_includes(actual_rows.sort, 'Building Summary: Size Cooling System: CoolingSystem2 (kBtu/h)')
    assert_includes(actual_rows.sort, 'Building Summary: Size Heating System: Primary (kBtu/h)')
    assert_includes(actual_rows.sort, 'Building Summary: Size Heating System: Secondary (kBtu/h)')
    assert_includes(actual_rows.sort, 'Building Summary: Size Cooling System: Primary (kBtu/h)')
    assert_includes(actual_rows.sort, 'Building Summary: Size Cooling System: Secondary (kBtu/h)')
  end

  def test_base_xml
    args_hash = {}
    hpxml_csv = _test_measure(args_hash)
    assert(File.exist?(hpxml_csv))

    expected_multipliers = {
      'Building Summary: Fixed (1)' => 1.0,
      'Building Summary: Wall Area Above-Grade Conditioned (ft^2)' => 1200.0,
      'Building Summary: Wall Area Above-Grade Exterior (ft^2)' => 1490.0,
      'Building Summary: Wall Area Below-Grade (ft^2)' => 1200.0,
      'Building Summary: Floor Area Conditioned (ft^2)' => 2700.0,
      'Building Summary: Floor Area Attic (ft^2)' => 1350.0,
      'Building Summary: Floor Area Lighting (ft^2)' => 2700.0,
      'Building Summary: Roof Area (ft^2)' => 1509.3,
      'Building Summary: Window Area (ft^2)' => 360.0,
      'Building Summary: Door Area (ft^2)' => 40.0,
      'Building Summary: Duct Unconditioned Surface Area (ft^2)' => 200.0,
      'Building Summary: Size Heating System: HeatingSystem (kBtu/h)' => 36.0,
      'Building Summary: Size Cooling System: CoolingSystem (kBtu/h)' => 24.0,
      'Building Summary: Size Water Heater (gal)' => 40.0,
      'Building Summary: Flow Rate Mechanical Ventilation (cfm)' => 0.0,
      'Building Summary: Slab Perimeter Exposed Conditioned (ft)' => 150.0,
      'Building Summary: Rim Joist Area Above-Grade Exterior (ft^2)' => 116.0
    }

    actual_rows = File.readlines(hpxml_csv).map { |x| x.split(',')[0].strip }.select { |x| !x.empty? }
    actual_values = File.readlines(hpxml_csv).map { |x| x.split(',')[1].strip }.select { |x| !x.empty? }.map { |x| Float(x) }
    actual_multipliers = Hash[actual_rows.zip(actual_values)]

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

    hpxml_csv = File.join(File.dirname(template_osw), 'run', 'hpxml_output.csv')
    return hpxml_csv
  end
end
