# frozen_string_literal: true

require_relative '../resources/minitest_helper'
require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'fileutils'
require_relative '../measure.rb'
require_relative '../resources/util.rb'

class HPXMLtoOpenStudioElectricPanelTest < Minitest::Test
  def setup
    @root_path = File.absolute_path(File.join(File.dirname(__FILE__), '..', '..'))
    @sample_files_path = File.join(@root_path, 'workflow', 'sample_files')
    @tmp_hpxml_path = File.join(@sample_files_path, 'tmp.xml')
  end

  def teardown
    File.delete(@tmp_hpxml_path) if File.exist? @tmp_hpxml_path
    File.delete(File.join(File.dirname(__FILE__), 'results_annual.csv')) if File.exist? File.join(File.dirname(__FILE__), 'results_annual.csv')
    File.delete(File.join(File.dirname(__FILE__), 'results_design_load_details.csv')) if File.exist? File.join(File.dirname(__FILE__), 'results_design_load_details.csv')
  end

  def sample_files_dir
    return File.join(File.dirname(__FILE__), '..', '..', 'workflow', 'sample_files')
  end

  def test_electric_panel
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-detailed-electric-panel.xml'))
    _model, hpxml, _hpxml_bldg = _test_measure(args_hash)
    hpxml_bldg = hpxml.buildings[0]
    electric_panel = hpxml_bldg.electric_panels[0]

    assert_in_epsilon(9762, electric_panel.clb_total_w, 0.01)
    assert_in_epsilon(9762 / Float(HPXML::ElectricPanelVoltage240), electric_panel.clb_total_a, 0.01)
    assert_in_epsilon(electric_panel.max_current_rating - 9762 / Float(HPXML::ElectricPanelVoltage240), electric_panel.clb_headroom_a, 0.01)
    assert_equal(12, electric_panel.bs_total)
    assert_equal(7, electric_panel.bs_occupied)
    assert_equal(12 - 7, electric_panel.bs_headroom)

    # Upgrade
    electric_panel.headroom_breaker_spaces = nil
    electric_panel.total_breaker_spaces = 12
    panel_loads = electric_panel.panel_loads
    pl = panel_loads.find { |pl| pl.type == HPXML::ElectricPanelLoadTypeHeating }
    pl.power = 17942
    pl.addition = true
    pl = panel_loads.find { |pl| pl.type == HPXML::ElectricPanelLoadTypeCooling }
    pl.power = 17942
    pl.addition = true
    panel_loads.add(type: HPXML::ElectricPanelLoadTypeWaterHeater,
                    power: 4500,
                    voltage: HPXML::ElectricPanelVoltage240,
                    breaker_spaces: 2,
                    addition: true,
                    system_idrefs: [hpxml_bldg.water_heating_systems[0].id])
    panel_loads.add(type: HPXML::ElectricPanelLoadTypeClothesDryer,
                    power: 5760,
                    voltage: HPXML::ElectricPanelVoltage120,
                    breaker_spaces: 2,
                    addition: true,
                    system_idrefs: [hpxml_bldg.clothes_dryers[0].id])
    panel_loads.add(type: HPXML::ElectricPanelLoadTypeRangeOven,
                    power: 12000,
                    voltage: HPXML::ElectricPanelVoltage240,
                    breaker_spaces: 2,
                    addition: true,
                    system_idrefs: [hpxml_bldg.cooking_ranges[0].id])
    hpxml_bldg.plug_loads.add(id: "PlugLoad#{hpxml_bldg.plug_loads.size + 1}",
                              plug_load_type: HPXML::PlugLoadTypeElectricVehicleCharging)
    panel_loads.add(type: HPXML::ElectricPanelLoadTypeElectricVehicleCharging,
                    power: 1650,
                    voltage: HPXML::ElectricPanelVoltage120,
                    breaker_spaces: 1,
                    addition: true,
                    system_idrefs: [hpxml_bldg.plug_loads[-1].id])
    XMLHelper.write_file(hpxml.to_doc(), @tmp_hpxml_path)
    args_hash['hpxml_path'] = @tmp_hpxml_path
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)
    electric_panel = hpxml_bldg.electric_panels[0]

    assert_in_epsilon(35851, electric_panel.clb_total_w, 0.01)
    assert_in_epsilon(35851 / Float(HPXML::ElectricPanelVoltage240), electric_panel.clb_total_a, 0.01)
    assert_in_epsilon(electric_panel.max_current_rating - 35851 / Float(HPXML::ElectricPanelVoltage240), electric_panel.clb_headroom_a, 0.01)
    assert_equal(12, electric_panel.bs_total)
    assert_equal(14, electric_panel.bs_occupied)
    assert_equal(12 - 14, electric_panel.bs_headroom)
  end

  def _test_measure(args_hash)
    # create an instance of the measure
    measure = HPXMLtoOpenStudio.new

    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    model = OpenStudio::Model::Model.new

    # get arguments
    args_hash['output_dir'] = File.dirname(__FILE__)
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

    hpxml = HPXML.new(hpxml_path: File.join(File.dirname(__FILE__), 'in.xml'))

    File.delete(File.join(File.dirname(__FILE__), 'in.xml'))

    return model, hpxml, hpxml.buildings[0]
  end
end
