# frozen_string_literal: true

require_relative '../resources/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require 'fileutils'
require_relative '../measure.rb'
require_relative '../resources/util.rb'

class HPXMLtoOpenStudioDuctsTest < MiniTest::Test
  def before_setup
    @root_path = File.absolute_path(File.join(File.dirname(__FILE__), '..', '..'))
    @tmp_hpxml_path = File.join(@root_path, 'workflow', 'sample_files', 'tmp.xml')
    @tmp_output_path = File.join(@root_path, 'workflow', 'sample_files', 'tmp_output')
    @tmp_output_hpxml_path = File.join(@tmp_output_path, 'in.xml')
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

  def test_ducts
    hpxml_name = 'base.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    model, hpxml = _test_measure(@args_hash)
    expected_supply_locations = ['attic - unvented']
    expected_return_locations = ['attic - unvented']
    expected_supply_areas = [150.0]
    expected_return_areas = [50.0]
    expected_n_return_registers = hpxml.building_construction.number_of_conditioned_floors
    _test_default_duct_values(hpxml, expected_supply_locations, expected_return_locations, expected_supply_areas, expected_return_areas, expected_n_return_registers)

    default_hpxml('base.xml')
    model, hpxml = _test_measure(@args_hash)
    expected_supply_locations = ['basement - conditioned']
    expected_return_locations = ['basement - conditioned']
    expected_supply_areas = [729.0]
    expected_return_areas = [270.0]
    expected_n_return_registers = hpxml.building_construction.number_of_conditioned_floors
    _test_default_duct_values(hpxml, expected_supply_locations, expected_return_locations, expected_supply_areas, expected_return_areas, expected_n_return_registers)

    default_hpxml('base-foundation-multiple.xml')
    model, hpxml = _test_measure(@args_hash)
    expected_supply_locations = ['basement - unconditioned']
    expected_return_locations = ['basement - unconditioned']
    expected_supply_areas = [364.5]
    expected_return_areas = [67.5]
    expected_n_return_registers = hpxml.building_construction.number_of_conditioned_floors
    _test_default_duct_values(hpxml, expected_supply_locations, expected_return_locations, expected_supply_areas, expected_return_areas, expected_n_return_registers)

    default_hpxml('base-foundation-ambient.xml')
    model, hpxml = _test_measure(@args_hash)
    expected_supply_locations = ['attic - unvented']
    expected_return_locations = ['attic - unvented']
    expected_supply_areas = [364.5]
    expected_return_areas = [67.5]
    expected_n_return_registers = hpxml.building_construction.number_of_conditioned_floors
    _test_default_duct_values(hpxml, expected_supply_locations, expected_return_locations, expected_supply_areas, expected_return_areas, expected_n_return_registers)

    default_hpxml('base-enclosure-other-housing-unit.xml')
    model, hpxml = _test_measure(@args_hash)
    expected_supply_locations = ['living space']
    expected_return_locations = ['living space']
    expected_supply_areas = [364.5]
    expected_return_areas = [67.5]
    expected_n_return_registers = hpxml.building_construction.number_of_conditioned_floors
    _test_default_duct_values(hpxml, expected_supply_locations, expected_return_locations, expected_supply_areas, expected_return_areas, expected_n_return_registers)

    default_hpxml('base-enclosure-2stories.xml')
    model, hpxml = _test_measure(@args_hash)
    expected_supply_locations = ['basement - conditioned', 'living space']
    expected_return_locations = ['basement - conditioned', 'living space']
    expected_supply_areas = [820.125, 273.375]
    expected_return_areas = [455.625, 151.875]
    expected_n_return_registers = hpxml.building_construction.number_of_conditioned_floors
    _test_default_duct_values(hpxml, expected_supply_locations, expected_return_locations, expected_supply_areas, expected_return_areas, expected_n_return_registers)

    hpxml_files = ['base-hvac-multiple.xml',
                   'base-hvac-multiple2.xml']
    hpxml_files.each do |hpxml_file|
      default_hpxml(hpxml_file)
      model, hpxml = _test_measure(@args_hash)
      expected_supply_locations = ['basement - conditioned', 'basement - conditioned'] * hpxml.hvac_distributions.size
      expected_return_locations = ['basement - conditioned', 'basement - conditioned'] * hpxml.hvac_distributions.size
      expected_supply_areas = [91.125, 91.125] * hpxml.hvac_distributions.size
      expected_return_areas = [33.75, 33.75] * hpxml.hvac_distributions.size
      expected_n_return_registers = hpxml.building_construction.number_of_conditioned_floors
      _test_default_duct_values(hpxml, expected_supply_locations, expected_return_locations, expected_supply_areas, expected_return_areas, expected_n_return_registers)
    end

    default_hpxml('base-hvac-multiple.xml')
    hpxml = HPXML.new(hpxml_path: @tmp_hpxml_path)
    hpxml.building_construction.number_of_conditioned_floors_above_grade = 2
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    model, hpxml = _test_measure(@args_hash)
    expected_supply_locations = ['basement - conditioned', 'basement - conditioned', 'living space', 'living space'] * hpxml.hvac_distributions.size
    expected_return_locations = ['basement - conditioned', 'basement - conditioned', 'living space', 'living space'] * hpxml.hvac_distributions.size
    expected_supply_areas = [68.34375, 68.34375, 22.78125, 22.78125] * hpxml.hvac_distributions.size
    expected_return_areas = [25.3125, 25.3125, 8.4375, 8.4375] * hpxml.hvac_distributions.size
    expected_n_return_registers = hpxml.building_construction.number_of_conditioned_floors
    _test_default_duct_values(hpxml, expected_supply_locations, expected_return_locations, expected_supply_areas, expected_return_areas, expected_n_return_registers)
  end

  def _test_measure(args_hash)
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
      if args_hash.has_key?(arg.name)
        assert(temp_arg_var.setValue(args_hash[arg.name]))
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

    hpxml = HPXML.new(hpxml_path: @tmp_output_hpxml_path)

    return model, hpxml
  end

  def _test_default_duct_values(hpxml, expected_supply_locations, expected_return_locations, expected_supply_areas, expected_return_areas, expected_n_return_registers)
    supply_duct_idx = 0
    return_duct_idx = 0
    hpxml.hvac_distributions.each do |hvac_distribution|
      assert_equal(hvac_distribution.number_of_return_registers, expected_n_return_registers) if hvac_distribution.distribution_system_type == HPXML::HVACDistributionTypeAir
      hvac_distribution.ducts.each do |duct|
        if duct.duct_type == HPXML::DuctTypeSupply
          assert_equal(duct.duct_location, expected_supply_locations[supply_duct_idx])
          assert_in_epsilon(duct.duct_surface_area, expected_supply_areas[supply_duct_idx], 0.01)
          supply_duct_idx += 1
        elsif duct.duct_type == HPXML::DuctTypeReturn
          assert_equal(duct.duct_location, expected_return_locations[return_duct_idx])
          assert_in_epsilon(duct.duct_surface_area, expected_return_areas[return_duct_idx], 0.01)
          return_duct_idx += 1
        end
      end
    end
  end

  def default_hpxml(hpxml_name)
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))

    hpxml.hvac_distributions.each do |hvac_distribution|
      hvac_distribution.ducts.each do |duct|
        duct.duct_location = nil
        duct.duct_surface_area = nil
      end
    end

    # save new file
    hpxml_name = File.basename(@tmp_hpxml_path)
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)

    return hpxml_name
  end
end
