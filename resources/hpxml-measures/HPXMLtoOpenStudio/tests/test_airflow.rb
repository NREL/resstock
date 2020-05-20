# frozen_string_literal: true

require_relative '../resources/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require 'fileutils'
require_relative '../measure.rb'
require_relative '../resources/util.rb'

class HPXMLtoOpenStudioAirflowTest < MiniTest::Test
  def sample_files_dir
    return File.join(File.dirname(__FILE__), '..', '..', 'workflow', 'sample_files')
  end

  def get_ems_values(ems_objects, name)
    values = {}
    ems_objects.each do |ems_object|
      next unless ems_object.name.to_s.include? name.gsub(' ', '_')

      ems_object.lines.each do |line|
        next unless line.downcase.start_with? 'set'

        lhs, rhs = line.split('=')
        lhs = lhs.gsub('Set', '').gsub('set', '').strip
        rhs = rhs.gsub(',', '').gsub(';', '').strip
        values[lhs] = rhs
      end
    end
    assert_operator(values.size, :>, 0)
    return values
  end

  def test_infiltration_ach50
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base.xml'))
    model, hpxml = _test_measure(args_hash)

    # Check infiltration/ventilation program
    program_values = get_ems_values(model.getEnergyManagementSystemPrograms, "#{Constants.ObjectNameInfiltration} program")
    assert_in_epsilon(0.0436, Float(program_values['c']), 0.01)
    assert_in_epsilon(0.0544, Float(program_values['Cs']), 0.01)
    assert_in_epsilon(0.1446, Float(program_values['Cw']), 0.01)
  end

  def test_infiltration_cfm50
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-enclosure-infil-cfm50.xml'))
    model, hpxml = _test_measure(args_hash)

    # Check infiltration/ventilation program
    program_values = get_ems_values(model.getEnergyManagementSystemPrograms, "#{Constants.ObjectNameInfiltration} program")
    assert_in_epsilon(0.0436, Float(program_values['c']), 0.01)
    assert_in_epsilon(0.0544, Float(program_values['Cs']), 0.01)
    assert_in_epsilon(0.1446, Float(program_values['Cw']), 0.01)
  end

  def test_infiltration_natural_ach
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-enclosure-infil-natural-ach.xml'))
    model, hpxml = _test_measure(args_hash)

    # Check infiltration/ventilation program
    program_values = get_ems_values(model.getEnergyManagementSystemPrograms, "#{Constants.ObjectNameInfiltration} program")
    assert_in_epsilon(0.3127, Float(program_values['c']), 0.01)
    assert_in_epsilon(0.0544, Float(program_values['Cs']), 0.01)
    assert_in_epsilon(0.1446, Float(program_values['Cw']), 0.01)
  end

  def test_natural_ventilation
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base.xml'))
    model, hpxml = _test_measure(args_hash)

    # Check natural ventilation/whole house fan program
    program_values = get_ems_values(model.getEnergyManagementSystemPrograms, "#{Constants.ObjectNameNaturalVentilation} program")
    assert_in_epsilon(14.5, UnitConversions.convert(Float(program_values['NVArea']), 'cm^2', 'ft^2'), 0.01)
    assert_in_epsilon(0.000100, Float(program_values['Cs']), 0.01)
    assert_in_epsilon(0.000065, Float(program_values['Cw']), 0.01)
    assert_in_epsilon(0.0, UnitConversions.convert(Float(program_values['WHF_Flow']), 'm^3/s', 'cfm'), 0.01)
  end

  def test_mechanical_ventilation_none
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base.xml'))
    model, hpxml = _test_measure(args_hash)

    # Check infiltration/ventilation program
    program_values = get_ems_values(model.getEnergyManagementSystemPrograms, "#{Constants.ObjectNameInfiltration} program")
    assert_in_epsilon(0.0, UnitConversions.convert(Float(program_values['QWHV']), 'm^3/s', 'cfm'), 0.01)
    assert_in_epsilon(0.0, Float(program_values['mech_vent_house_fan_act']), 0.01)
    assert_in_epsilon(0.0, UnitConversions.convert(Float(program_values['Qrange']), 'm^3/s', 'cfm'), 0.01)
    assert_in_epsilon(0.0, UnitConversions.convert(Float(program_values['Qbath']), 'm^3/s', 'cfm'), 0.01)
  end

  def test_mechanical_ventilation_supply
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-mechvent-supply.xml'))
    model, hpxml = _test_measure(args_hash)

    # Get HPXML values
    vent_fan = hpxml.ventilation_fans.select { |f| f.used_for_whole_building_ventilation }[0]
    vent_fan_cfm = vent_fan.tested_flow_rate
    vent_fan_power = vent_fan.fan_power

    # Check infiltration/ventilation program
    program_values = get_ems_values(model.getEnergyManagementSystemPrograms, "#{Constants.ObjectNameInfiltration} program")
    assert_in_epsilon(vent_fan_cfm, UnitConversions.convert(Float(program_values['QWHV']), 'm^3/s', 'cfm'), 0.01)
    assert_in_epsilon(vent_fan_power, Float(program_values['mech_vent_house_fan_act']), 0.01)
    assert_in_epsilon(0.0, UnitConversions.convert(Float(program_values['Qrange']), 'm^3/s', 'cfm'), 0.01)
    assert_in_epsilon(0.0, UnitConversions.convert(Float(program_values['Qbath']), 'm^3/s', 'cfm'), 0.01)
  end

  def test_mechanical_ventilation_exhaust
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-mechvent-exhaust.xml'))
    model, hpxml = _test_measure(args_hash)

    # Get HPXML values
    vent_fan = hpxml.ventilation_fans.select { |f| f.used_for_whole_building_ventilation }[0]
    vent_fan_cfm = vent_fan.tested_flow_rate
    vent_fan_power = vent_fan.fan_power

    # Check infiltration/ventilation program
    program_values = get_ems_values(model.getEnergyManagementSystemPrograms, "#{Constants.ObjectNameInfiltration} program")
    assert_in_epsilon(vent_fan_cfm, UnitConversions.convert(Float(program_values['QWHV']), 'm^3/s', 'cfm'), 0.01)
    assert_in_epsilon(vent_fan_power, Float(program_values['mech_vent_house_fan_act']), 0.01)
    assert_in_epsilon(0.0, UnitConversions.convert(Float(program_values['Qrange']), 'm^3/s', 'cfm'), 0.01)
    assert_in_epsilon(0.0, UnitConversions.convert(Float(program_values['Qbath']), 'm^3/s', 'cfm'), 0.01)
  end

  def test_mechanical_ventilation_balanced
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-mechvent-balanced.xml'))
    model, hpxml = _test_measure(args_hash)

    # Get HPXML values
    vent_fan = hpxml.ventilation_fans.select { |f| f.used_for_whole_building_ventilation }[0]
    vent_fan_cfm = vent_fan.tested_flow_rate
    vent_fan_power = vent_fan.fan_power

    # Check infiltration/ventilation program
    program_values = get_ems_values(model.getEnergyManagementSystemPrograms, "#{Constants.ObjectNameInfiltration} program")
    assert_in_epsilon(vent_fan_cfm, UnitConversions.convert(Float(program_values['QWHV']), 'm^3/s', 'cfm'), 0.01)
    assert_in_epsilon(vent_fan_power, Float(program_values['mech_vent_house_fan_act']), 0.01)
    assert_in_epsilon(0.0, UnitConversions.convert(Float(program_values['Qrange']), 'm^3/s', 'cfm'), 0.01)
    assert_in_epsilon(0.0, UnitConversions.convert(Float(program_values['Qbath']), 'm^3/s', 'cfm'), 0.01)
  end

  def test_mechanical_ventilation_erv
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-mechvent-erv.xml'))
    model, hpxml = _test_measure(args_hash)

    # Get HPXML values
    vent_fan = hpxml.ventilation_fans.select { |f| f.used_for_whole_building_ventilation }[0]
    vent_fan_cfm = vent_fan.tested_flow_rate
    vent_fan_power = vent_fan.fan_power

    # Check infiltration/ventilation program
    program_values = get_ems_values(model.getEnergyManagementSystemPrograms, "#{Constants.ObjectNameInfiltration} program")
    assert_in_epsilon(vent_fan_cfm, UnitConversions.convert(Float(program_values['QWHV']), 'm^3/s', 'cfm'), 0.01)
    assert_in_epsilon(vent_fan_power, Float(program_values['mech_vent_house_fan_act']), 0.01)
    assert_in_epsilon(0.0, UnitConversions.convert(Float(program_values['Qrange']), 'm^3/s', 'cfm'), 0.01)
    assert_in_epsilon(0.0, UnitConversions.convert(Float(program_values['Qbath']), 'm^3/s', 'cfm'), 0.01)
  end

  def test_mechanical_ventilation_hrv
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-mechvent-hrv.xml'))
    model, hpxml = _test_measure(args_hash)

    # Get HPXML values
    vent_fan = hpxml.ventilation_fans.select { |f| f.used_for_whole_building_ventilation }[0]
    vent_fan_cfm = vent_fan.tested_flow_rate
    vent_fan_power = vent_fan.fan_power

    # Check infiltration/ventilation program
    program_values = get_ems_values(model.getEnergyManagementSystemPrograms, "#{Constants.ObjectNameInfiltration} program")
    assert_in_epsilon(vent_fan_cfm, UnitConversions.convert(Float(program_values['QWHV']), 'm^3/s', 'cfm'), 0.01)
    assert_in_epsilon(vent_fan_power, Float(program_values['mech_vent_house_fan_act']), 0.01)
    assert_in_epsilon(0.0, UnitConversions.convert(Float(program_values['Qrange']), 'm^3/s', 'cfm'), 0.01)
    assert_in_epsilon(0.0, UnitConversions.convert(Float(program_values['Qbath']), 'm^3/s', 'cfm'), 0.01)
  end

  def test_mechanical_ventilation_cfis
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-mechvent-cfis.xml'))
    model, hpxml = _test_measure(args_hash)

    # Get HPXML values
    vent_fan = hpxml.ventilation_fans.select { |f| f.used_for_whole_building_ventilation }[0]
    vent_fan_cfm = vent_fan.tested_flow_rate
    vent_fan_power = vent_fan.fan_power
    vent_fan_mins = vent_fan.hours_in_operation / 24.0 * 60.0

    # Check infiltration/ventilation program
    program_values = get_ems_values(model.getEnergyManagementSystemPrograms, "#{Constants.ObjectNameInfiltration} program")
    assert_in_epsilon(vent_fan_cfm, UnitConversions.convert(Float(program_values['CFIS_Q_duct']), 'm^3/s', 'cfm'), 0.01)
    assert_in_epsilon(vent_fan_power, Float(program_values['CFIS_fan_w']), 0.01)
    assert_in_epsilon(vent_fan_mins, Float(program_values['CFIS_t_min_hr_open']), 0.01)
    assert_in_epsilon(0.0, UnitConversions.convert(Float(program_values['Qrange']), 'm^3/s', 'cfm'), 0.01)
    assert_in_epsilon(0.0, UnitConversions.convert(Float(program_values['Qbath']), 'm^3/s', 'cfm'), 0.01)
  end

  def test_ventilation_bath_kitchen_fans
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-mechvent-bath-kitchen-fans.xml'))
    model, hpxml = _test_measure(args_hash)

    # Get HPXML values
    bath_fan = hpxml.ventilation_fans.select { |f| f.used_for_local_ventilation && f.fan_location == HPXML::VentilationFanLocationBath }[0]
    bath_fan_cfm = bath_fan.rated_flow_rate * bath_fan.quantity
    kitchen_fan = hpxml.ventilation_fans.select { |f| f.used_for_local_ventilation && f.fan_location == HPXML::VentilationFanLocationKitchen }[0]
    kitchen_fan_cfm = kitchen_fan.rated_flow_rate

    # Check infiltration/ventilation program
    program_values = get_ems_values(model.getEnergyManagementSystemPrograms, "#{Constants.ObjectNameInfiltration} program")
    program_values = get_ems_values(model.getEnergyManagementSystemPrograms, "#{Constants.ObjectNameInfiltration} program")
    assert_in_epsilon(0.0, UnitConversions.convert(Float(program_values['QWHV']), 'm^3/s', 'cfm'), 0.01)
    assert_in_epsilon(0.0, Float(program_values['mech_vent_house_fan_act']), 0.01)
    assert_in_epsilon(kitchen_fan_cfm, UnitConversions.convert(program_values['Qrange'].to_f, 'm^3/s', 'cfm'), 0.01)
    assert_in_epsilon(bath_fan_cfm, UnitConversions.convert(program_values['Qbath'].to_f, 'm^3/s', 'cfm'), 0.01)
  end

  def test_ducts_leakage_cfm25
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base.xml'))
    model, hpxml = _test_measure(args_hash)

    # Get HPXML values
    supply_leakage = hpxml.hvac_distributions[0].duct_leakage_measurements.select { |m| m.duct_type == HPXML::DuctTypeSupply }[0]
    return_leakage = hpxml.hvac_distributions[0].duct_leakage_measurements.select { |m| m.duct_type == HPXML::DuctTypeReturn }[0]
    supply_leakage_cfm25 = supply_leakage.duct_leakage_value
    return_leakage_cfm25 = return_leakage.duct_leakage_value

    # Check ducts program
    program_values = get_ems_values(model.getEnergyManagementSystemSubroutines, 'duct subroutine')
    assert_in_epsilon(supply_leakage_cfm25, UnitConversions.convert(program_values['f_sup'].to_f, 'm^3/s', 'cfm'), 0.01)
    assert_in_epsilon(return_leakage_cfm25, UnitConversions.convert(program_values['f_ret'].to_f, 'm^3/s', 'cfm'), 0.01)
    assert_in_epsilon(33.4, UnitConversions.convert(Float(program_values['supply_ua']), 'W/K', 'Btu/(hr*F)'), 0.01)
    assert_in_epsilon(29.4, UnitConversions.convert(Float(program_values['return_ua']), 'W/K', 'Btu/(hr*F)'), 0.01)
  end

  def test_ducts_leakage_percent
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-hvac-ducts-leakage-percent.xml'))
    model, hpxml = _test_measure(args_hash)

    # Get HPXML values
    supply_leakage = hpxml.hvac_distributions[0].duct_leakage_measurements.select { |m| m.duct_type == HPXML::DuctTypeSupply }[0]
    return_leakage = hpxml.hvac_distributions[0].duct_leakage_measurements.select { |m| m.duct_type == HPXML::DuctTypeReturn }[0]
    supply_leakage_frac = supply_leakage.duct_leakage_value
    return_leakage_frac = return_leakage.duct_leakage_value

    # Check ducts program
    program_values = get_ems_values(model.getEnergyManagementSystemSubroutines, 'duct subroutine')
    assert_in_epsilon(supply_leakage_frac, Float(program_values['f_sup']), 0.01)
    assert_in_epsilon(return_leakage_frac, Float(program_values['f_ret']), 0.01)
    assert_in_epsilon(33.4, UnitConversions.convert(Float(program_values['supply_ua']), 'W/K', 'Btu/(hr*F)'), 0.01)
    assert_in_epsilon(29.4, UnitConversions.convert(Float(program_values['return_ua']), 'W/K', 'Btu/(hr*F)'), 0.01)
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

    hpxml = HPXML.new(hpxml_path: args_hash['hpxml_path'])

    return model, hpxml
  end
end
