# frozen_string_literal: true

require_relative '../resources/minitest_helper'
require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'fileutils'
require_relative '../measure.rb'
require_relative '../resources/util.rb'
require_relative 'util.rb'

class HPXMLtoOpenStudioHVACTest < Minitest::Test
  def sample_files_dir
    return File.join(File.dirname(__FILE__), '..', '..', 'workflow', 'sample_files')
  end

  def test_central_air_conditioner_1_speed
    ['base-hvac-central-ac-only-1-speed.xml',
     'base-hvac-central-ac-only-1-speed-seer2.xml'].each do |hpxml_path|
      args_hash = {}
      args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, hpxml_path))
      model, hpxml = _test_measure(args_hash)

      # Get HPXML values
      cooling_system = hpxml.cooling_systems[0]
      capacity = UnitConversions.convert(cooling_system.cooling_capacity, 'Btu/hr', 'W')

      # Check cooling coil
      assert_equal(1, model.getCoilCoolingDXSingleSpeeds.size)
      clg_coil = model.getCoilCoolingDXSingleSpeeds[0]
      cop = 3.73 # Expected value
      assert_in_epsilon(cop, clg_coil.ratedCOP, 0.01)
      assert_in_epsilon(capacity, clg_coil.ratedTotalCoolingCapacity.get, 0.01)

      # Check EMS
      assert_equal(1, model.getAirLoopHVACUnitarySystems.size)
      unitary_system = model.getAirLoopHVACUnitarySystems[0]
      program_values = get_ems_values(model.getEnergyManagementSystemPrograms, "#{unitary_system.name} IQ")
      assert(program_values.empty?) # Check no EMS program
    end
  end

  def test_central_air_conditioner_2_speed
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-hvac-central-ac-only-2-speed.xml'))
    model, hpxml = _test_measure(args_hash)

    # Get HPXML values
    cooling_system = hpxml.cooling_systems[0]
    capacity = UnitConversions.convert(cooling_system.cooling_capacity, 'Btu/hr', 'W')

    # Check cooling coil
    assert_equal(1, model.getCoilCoolingDXMultiSpeeds.size)
    clg_coil = model.getCoilCoolingDXMultiSpeeds[0]
    cops = [4.95, 4.59] # Expected values
    cops.each_with_index do |cop, i|
      assert_in_epsilon(cop, clg_coil.stages[i].grossRatedCoolingCOP, 0.01)
    end
    assert_in_epsilon(capacity, clg_coil.stages[-1].grossRatedTotalCoolingCapacity.get, 0.01)

    # Check EMS
    assert_equal(1, model.getAirLoopHVACUnitarySystems.size)
    unitary_system = model.getAirLoopHVACUnitarySystems[0]
    program_values = get_ems_values(model.getEnergyManagementSystemPrograms, "#{unitary_system.name} IQ")
    assert(program_values.empty?) # Check no EMS program
  end

  def test_central_air_conditioner_var_speed
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-hvac-central-ac-only-var-speed.xml'))
    model, hpxml = _test_measure(args_hash)

    # Get HPXML values
    cooling_system = hpxml.cooling_systems[0]
    capacity = UnitConversions.convert(cooling_system.cooling_capacity, 'Btu/hr', 'W')

    # Check cooling coil
    assert_equal(1, model.getCoilCoolingDXMultiSpeeds.size)
    clg_coil = model.getCoilCoolingDXMultiSpeeds[0]
    cops = [6.57, 6.81, 6.63, 6.14] # Expected values
    cops.each_with_index do |cop, i|
      assert_in_epsilon(cop, clg_coil.stages[i].grossRatedCoolingCOP, 0.01)
    end
    assert_in_epsilon(capacity, clg_coil.stages[-1].grossRatedTotalCoolingCapacity.get, 0.01)

    # Check EMS
    assert_equal(1, model.getAirLoopHVACUnitarySystems.size)
    unitary_system = model.getAirLoopHVACUnitarySystems[0]
    program_values = get_ems_values(model.getEnergyManagementSystemPrograms, "#{unitary_system.name} IQ")
    assert(program_values.empty?) # Check no EMS program
  end

  def test_room_air_conditioner
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-hvac-room-ac-only.xml'))
    model, hpxml = _test_measure(args_hash)

    # Get HPXML values
    cooling_system = hpxml.cooling_systems[0]
    eer = cooling_system.cooling_efficiency_eer
    ceer = eer / 1.01 # convert to ceer
    cop = UnitConversions.convert(ceer, 'Btu/hr', 'W') # Expected value
    capacity = UnitConversions.convert(cooling_system.cooling_capacity, 'Btu/hr', 'W')

    # Check cooling coil
    assert_equal(1, model.getCoilCoolingDXSingleSpeeds.size)
    clg_coil = model.getCoilCoolingDXSingleSpeeds[0]
    assert_in_epsilon(cop, clg_coil.ratedCOP, 0.001)
    assert_in_epsilon(capacity, clg_coil.ratedTotalCoolingCapacity.get, 0.01)
  end

  def test_room_air_conditioner_ceer
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-hvac-room-ac-only-ceer.xml'))
    model, hpxml = _test_measure(args_hash)

    # Get HPXML values
    cooling_system = hpxml.cooling_systems[0]
    ceer = cooling_system.cooling_efficiency_ceer
    cop = UnitConversions.convert(ceer, 'Btu/hr', 'W') # Expected value
    capacity = UnitConversions.convert(cooling_system.cooling_capacity, 'Btu/hr', 'W')

    # Check cooling coil
    assert_equal(1, model.getCoilCoolingDXSingleSpeeds.size)
    clg_coil = model.getCoilCoolingDXSingleSpeeds[0]
    assert_in_epsilon(cop, clg_coil.ratedCOP, 0.001)
    assert_in_epsilon(capacity, clg_coil.ratedTotalCoolingCapacity.get, 0.01)
  end

  def test_room_ac_with_heating
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-hvac-room-ac-with-heating.xml'))
    model, hpxml = _test_measure(args_hash)

    # Get HPXML values
    cooling_system = hpxml.cooling_systems[0]
    eer = cooling_system.cooling_efficiency_eer
    ceer = eer / 1.01 # convert to ceer
    cop = UnitConversions.convert(ceer, 'Btu/hr', 'W') # Expected value
    cool_capacity = UnitConversions.convert(cooling_system.cooling_capacity, 'Btu/hr', 'W')

    heat_efficiency = cooling_system.integrated_heating_system_efficiency_percent
    heat_efficiency = 1.0 if heat_efficiency.nil?
    heat_capacity = UnitConversions.convert(cooling_system.integrated_heating_system_capacity, 'Btu/hr', 'W')

    # Check cooling coil
    assert_equal(1, model.getAirLoopHVACUnitarySystems.size)
    assert_equal(1, model.getCoilCoolingDXSingleSpeeds.size)
    clg_coil = model.getCoilCoolingDXSingleSpeeds[0]
    assert_in_epsilon(cop, clg_coil.ratedCOP, 0.001)
    assert_in_epsilon(cool_capacity, clg_coil.ratedTotalCoolingCapacity.get, 0.01)

    # Check heating coil
    assert_equal(1, model.getCoilHeatingElectrics.size)
    baseboard = model.getCoilHeatingElectrics[0]
    assert_in_epsilon(heat_efficiency, baseboard.efficiency, 0.01)
    assert_in_epsilon(heat_capacity, baseboard.nominalCapacity.get, 0.01)
  end

  def test_ptac
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-hvac-ptac.xml'))
    model, hpxml = _test_measure(args_hash)

    # Get HPXML values
    cooling_system = hpxml.cooling_systems[0]
    eer = cooling_system.cooling_efficiency_eer
    ceer = eer / 1.01 # convert to ceer
    cop = UnitConversions.convert(ceer, 'Btu/hr', 'W') # Expected value
    capacity = UnitConversions.convert(cooling_system.cooling_capacity, 'Btu/hr', 'W')

    # Check cooling coil
    assert_equal(1, model.getCoilCoolingDXSingleSpeeds.size)
    assert_equal(1, model.getAirLoopHVACUnitarySystems.size)
    clg_coil = model.getCoilCoolingDXSingleSpeeds[0]
    assert_in_epsilon(cop, clg_coil.ratedCOP, 0.001)
    assert_in_epsilon(capacity, clg_coil.ratedTotalCoolingCapacity.get, 0.01)
  end

  def test_ptac_with_heating_electricity
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-hvac-ptac-with-heating-electricity.xml'))
    model, hpxml = _test_measure(args_hash)

    # Get HPXML values
    cooling_system = hpxml.cooling_systems[0]
    eer = cooling_system.cooling_efficiency_eer
    ceer = eer / 1.01 # convert to ceer
    cop = UnitConversions.convert(ceer, 'Btu/hr', 'W') # Expected value
    cool_capacity = UnitConversions.convert(cooling_system.cooling_capacity, 'Btu/hr', 'W')

    heat_efficiency = cooling_system.integrated_heating_system_efficiency_percent
    heat_efficiency = 1.0 if heat_efficiency.nil?
    heat_capacity = UnitConversions.convert(cooling_system.integrated_heating_system_capacity, 'Btu/hr', 'W')

    # Check cooling coil
    assert_equal(1, model.getAirLoopHVACUnitarySystems.size)
    assert_equal(1, model.getCoilCoolingDXSingleSpeeds.size)
    clg_coil = model.getCoilCoolingDXSingleSpeeds[0]
    assert_in_epsilon(cop, clg_coil.ratedCOP, 0.001)
    assert_in_epsilon(cool_capacity, clg_coil.ratedTotalCoolingCapacity.get, 0.01)

    # Check heating coil
    assert_equal(1, model.getCoilHeatingElectrics.size)
    baseboard = model.getCoilHeatingElectrics[0]
    assert_in_epsilon(heat_efficiency, baseboard.efficiency, 0.01)
    assert_in_epsilon(heat_capacity, baseboard.nominalCapacity.get, 0.01)
  end

  def test_ptac_with_heating_gas
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-hvac-ptac-with-heating-electricity.xml'))
    model, hpxml = _test_measure(args_hash)

    # Get HPXML values
    cooling_system = hpxml.cooling_systems[0]
    eer = cooling_system.cooling_efficiency_eer
    ceer = eer / 1.01 # convert to ceer
    cop = UnitConversions.convert(ceer, 'Btu/hr', 'W') # Expected value
    cool_capacity = UnitConversions.convert(cooling_system.cooling_capacity, 'Btu/hr', 'W')

    heat_efficiency = cooling_system.integrated_heating_system_efficiency_percent
    heat_efficiency = 1.0 if heat_efficiency.nil?
    heat_capacity = UnitConversions.convert(cooling_system.integrated_heating_system_capacity, 'Btu/hr', 'W')

    # Check cooling coil
    assert_equal(1, model.getAirLoopHVACUnitarySystems.size)
    assert_equal(1, model.getCoilCoolingDXSingleSpeeds.size)
    clg_coil = model.getCoilCoolingDXSingleSpeeds[0]
    assert_in_epsilon(cop, clg_coil.ratedCOP, 0.001)
    assert_in_epsilon(cool_capacity, clg_coil.ratedTotalCoolingCapacity.get, 0.01)

    # Check heating coil
    assert_equal(1, model.getCoilHeatingElectrics.size)
    baseboard = model.getCoilHeatingElectrics[0]
    assert_in_epsilon(heat_efficiency, baseboard.efficiency, 0.01)
    assert_in_epsilon(heat_capacity, baseboard.nominalCapacity.get, 0.01)
  end

  def test_pthp
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-hvac-pthp.xml'))
    model, hpxml = _test_measure(args_hash)

    # Get HPXML values
    heat_pump = hpxml.heat_pumps[0]
    backup_efficiency = heat_pump.backup_heating_efficiency_percent
    clg_capacity = UnitConversions.convert(heat_pump.cooling_capacity, 'Btu/hr', 'W')
    htg_capacity = UnitConversions.convert(heat_pump.heating_capacity, 'Btu/hr', 'W')
    supp_htg_capacity = UnitConversions.convert(heat_pump.backup_heating_capacity, 'Btu/hr', 'W')
    eer = heat_pump.cooling_efficiency_eer
    ceer = eer / 1.01 # convert to ceer
    cop_cool = UnitConversions.convert(ceer, 'Btu/hr', 'W') # Expected value
    cop_heat = heat_pump.heating_efficiency_cop # Expected value

    # Check cooling coil
    assert_equal(1, model.getCoilCoolingDXSingleSpeeds.size)
    clg_coil = model.getCoilCoolingDXSingleSpeeds[0]
    assert_in_epsilon(cop_cool, clg_coil.ratedCOP, 0.01)
    assert_in_epsilon(clg_capacity, clg_coil.ratedTotalCoolingCapacity.get, 0.01)

    # Check heating coil
    assert_equal(1, model.getCoilHeatingDXSingleSpeeds.size)
    htg_coil = model.getCoilHeatingDXSingleSpeeds[0]
    assert_in_epsilon(cop_heat, htg_coil.ratedCOP, 0.01)
    assert_in_epsilon(htg_capacity, htg_coil.ratedTotalHeatingCapacity.get, 0.01)

    # Check supp heating coil
    assert_equal(1, model.getCoilHeatingElectrics.size)
    supp_htg_coil = model.getCoilHeatingElectrics[0]
    assert_in_epsilon(backup_efficiency, supp_htg_coil.efficiency, 0.01)
    assert_in_epsilon(supp_htg_capacity, supp_htg_coil.nominalCapacity.get, 0.01)
  end

  def test_room_heat_pump
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-hvac-room-ac-with-reverse-cycle.xml'))
    model, hpxml = _test_measure(args_hash)

    # Get HPXML values
    heat_pump = hpxml.heat_pumps[0]
    clg_capacity = UnitConversions.convert(heat_pump.cooling_capacity, 'Btu/hr', 'W')
    htg_capacity = UnitConversions.convert(heat_pump.heating_capacity, 'Btu/hr', 'W')
    supp_htg_capacity = UnitConversions.convert(heat_pump.backup_heating_capacity, 'Btu/hr', 'W')
    eer = heat_pump.cooling_efficiency_eer
    ceer = eer / 1.01 # convert to ceer
    cop_cool = UnitConversions.convert(ceer, 'Btu/hr', 'W') # Expected value
    cop_heat = heat_pump.heating_efficiency_cop

    # Check cooling coil
    assert_equal(1, model.getCoilCoolingDXSingleSpeeds.size)
    clg_coil = model.getCoilCoolingDXSingleSpeeds[0]
    assert_in_epsilon(cop_cool, clg_coil.ratedCOP, 0.01)
    assert_in_epsilon(clg_capacity, clg_coil.ratedTotalCoolingCapacity.get, 0.01)

    # Check heating coil
    assert_equal(1, model.getCoilHeatingDXSingleSpeeds.size)
    htg_coil = model.getCoilHeatingDXSingleSpeeds[0]
    assert_in_epsilon(cop_heat, htg_coil.ratedCOP, 0.01)
    assert_in_epsilon(htg_capacity, htg_coil.ratedTotalHeatingCapacity.get, 0.01)

    # Check supp heating coil
    assert_equal(1, model.getCoilHeatingElectrics.size)
    supp_htg_coil = model.getCoilHeatingElectrics[0]
    assert_in_epsilon(supp_htg_capacity, supp_htg_coil.nominalCapacity.get, 0.01)
  end

  def test_evap_cooler
    # TODO
  end

  def test_furnace_gas
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-hvac-furnace-gas-only.xml'))
    model, hpxml = _test_measure(args_hash)

    # Get HPXML values
    heating_system = hpxml.heating_systems[0]
    afue = heating_system.heating_efficiency_afue
    capacity = UnitConversions.convert(heating_system.heating_capacity, 'Btu/hr', 'W')
    fuel = heating_system.heating_system_fuel

    # Check heating coil
    assert_equal(1, model.getCoilHeatingGass.size)
    htg_coil = model.getCoilHeatingGass[0]
    assert_in_epsilon(afue, htg_coil.gasBurnerEfficiency, 0.01)
    assert_in_epsilon(capacity, htg_coil.nominalCapacity.get, 0.01)
    assert_equal(EPlus.fuel_type(fuel), htg_coil.fuelType)
  end

  def test_furnace_electric
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-hvac-furnace-elec-only.xml'))
    model, hpxml = _test_measure(args_hash)

    # Get HPXML values
    heating_system = hpxml.heating_systems[0]
    afue = heating_system.heating_efficiency_afue
    capacity = UnitConversions.convert(heating_system.heating_capacity, 'Btu/hr', 'W')

    # Check heating coil
    assert_equal(1, model.getCoilHeatingElectrics.size)
    htg_coil = model.getCoilHeatingElectrics[0]
    assert_in_epsilon(afue, htg_coil.efficiency, 0.01)
    assert_in_epsilon(capacity, htg_coil.nominalCapacity.get, 0.01)
  end

  def test_boiler_gas
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-hvac-boiler-gas-only.xml'))
    model, hpxml = _test_measure(args_hash)

    # Get HPXML values
    heating_system = hpxml.heating_systems[0]
    afue = heating_system.heating_efficiency_afue
    capacity = UnitConversions.convert(heating_system.heating_capacity, 'Btu/hr', 'W')
    fuel = heating_system.heating_system_fuel

    # Check boiler
    assert_equal(1, model.getBoilerHotWaters.size)
    boiler = model.getBoilerHotWaters[0]
    assert_in_epsilon(afue, boiler.nominalThermalEfficiency, 0.01)
    assert_in_epsilon(capacity, boiler.nominalCapacity.get, 0.01)
    assert_equal(EPlus.fuel_type(fuel), boiler.fuelType)
  end

  def test_boiler_coal
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-hvac-boiler-coal-only.xml'))
    model, hpxml = _test_measure(args_hash)

    # Get HPXML values
    heating_system = hpxml.heating_systems[0]
    afue = heating_system.heating_efficiency_afue
    capacity = UnitConversions.convert(heating_system.heating_capacity, 'Btu/hr', 'W')
    fuel = heating_system.heating_system_fuel

    # Check boiler
    assert_equal(1, model.getBoilerHotWaters.size)
    boiler = model.getBoilerHotWaters[0]
    assert_in_epsilon(afue, boiler.nominalThermalEfficiency, 0.01)
    assert_in_epsilon(capacity, boiler.nominalCapacity.get, 0.01)
    assert_equal(EPlus.fuel_type(fuel), boiler.fuelType)
  end

  def test_boiler_electric
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-hvac-boiler-elec-only.xml'))
    model, hpxml = _test_measure(args_hash)

    # Get HPXML values
    heating_system = hpxml.heating_systems[0]
    afue = heating_system.heating_efficiency_afue
    capacity = UnitConversions.convert(heating_system.heating_capacity, 'Btu/hr', 'W')
    fuel = heating_system.heating_system_fuel

    # Check boiler
    assert_equal(1, model.getBoilerHotWaters.size)
    boiler = model.getBoilerHotWaters[0]
    assert_in_epsilon(afue, boiler.nominalThermalEfficiency, 0.01)
    assert_in_epsilon(capacity, boiler.nominalCapacity.get, 0.01)
    assert_equal(EPlus.fuel_type(fuel), boiler.fuelType)
  end

  def test_electric_resistance
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-hvac-elec-resistance-only.xml'))
    model, hpxml = _test_measure(args_hash)

    # Get HPXML values
    heating_system = hpxml.heating_systems[0]
    efficiency = heating_system.heating_efficiency_percent
    capacity = UnitConversions.convert(heating_system.heating_capacity, 'Btu/hr', 'W')

    # Check baseboard
    assert_equal(1, model.getZoneHVACBaseboardConvectiveElectrics.size)
    baseboard = model.getZoneHVACBaseboardConvectiveElectrics[0]
    assert_in_epsilon(efficiency, baseboard.efficiency, 0.01)
    assert_in_epsilon(capacity, baseboard.nominalCapacity.get, 0.01)
  end

  def test_stove_oil
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-hvac-stove-oil-only.xml'))
    model, hpxml = _test_measure(args_hash)

    # Get HPXML values
    heating_system = hpxml.heating_systems[0]
    efficiency = heating_system.heating_efficiency_percent
    capacity = UnitConversions.convert(heating_system.heating_capacity, 'Btu/hr', 'W')
    fuel = heating_system.heating_system_fuel

    # Check heating coil
    assert_equal(1, model.getCoilHeatingGass.size)
    htg_coil = model.getCoilHeatingGass[0]
    assert_in_epsilon(efficiency, htg_coil.gasBurnerEfficiency, 0.01)
    assert_in_epsilon(capacity, htg_coil.nominalCapacity.get, 0.01)
    assert_equal(EPlus.fuel_type(fuel), htg_coil.fuelType)
  end

  def test_air_to_air_heat_pump_1_speed
    ['base-hvac-air-to-air-heat-pump-1-speed.xml',
     'base-hvac-air-to-air-heat-pump-1-speed-seer2-hspf2.xml'].each do |hpxml_path|
      args_hash = {}
      args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, hpxml_path))
      model, hpxml = _test_measure(args_hash)

      # Get HPXML values
      heat_pump = hpxml.heat_pumps[0]
      backup_efficiency = heat_pump.backup_heating_efficiency_percent
      clg_capacity = UnitConversions.convert(heat_pump.cooling_capacity, 'Btu/hr', 'W')
      htg_capacity = UnitConversions.convert(heat_pump.heating_capacity, 'Btu/hr', 'W')
      supp_htg_capacity = UnitConversions.convert(heat_pump.backup_heating_capacity, 'Btu/hr', 'W')

      # Check cooling coil
      assert_equal(1, model.getCoilCoolingDXSingleSpeeds.size)
      clg_coil = model.getCoilCoolingDXSingleSpeeds[0]
      cop = 3.73 # Expected value
      assert_in_epsilon(cop, clg_coil.ratedCOP, 0.01)
      assert_in_epsilon(clg_capacity, clg_coil.ratedTotalCoolingCapacity.get, 0.01)

      # Check heating coil
      assert_equal(1, model.getCoilHeatingDXSingleSpeeds.size)
      htg_coil = model.getCoilHeatingDXSingleSpeeds[0]
      cop = 3.28 # Expected value
      assert_in_epsilon(cop, htg_coil.ratedCOP, 0.01)
      assert_in_epsilon(htg_capacity, htg_coil.ratedTotalHeatingCapacity.get, 0.01)

      # Check supp heating coil
      assert_equal(1, model.getCoilHeatingElectrics.size)
      supp_htg_coil = model.getCoilHeatingElectrics[0]
      assert_in_epsilon(backup_efficiency, supp_htg_coil.efficiency, 0.01)
      assert_in_epsilon(supp_htg_capacity, supp_htg_coil.nominalCapacity.get, 0.01)

      # Check EMS
      assert_equal(1, model.getAirLoopHVACUnitarySystems.size)
      unitary_system = model.getAirLoopHVACUnitarySystems[0]
      program_values = get_ems_values(model.getEnergyManagementSystemPrograms, "#{unitary_system.name} IQ")
      assert(program_values.empty?) # Check no EMS program
    end
  end

  def test_heat_pump_temperatures
    ['base-hvac-air-to-air-heat-pump-1-speed.xml',
     'base-hvac-air-to-air-heat-pump-1-speed-lockout-temperatures.xml',
     'base-hvac-air-to-air-heat-pump-var-speed-backup-boiler.xml',
     'base-hvac-dual-fuel-air-to-air-heat-pump-1-speed.xml',
     'base-hvac-mini-split-heat-pump-ductless.xml',
     'base-hvac-mini-split-heat-pump-ductless-backup-baseboard.xml'].each do |hpxml_name|
      args_hash = {}
      args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, hpxml_name))
      model, hpxml = _test_measure(args_hash)

      # Get HPXML values
      heat_pump = hpxml.heat_pumps[0]
      if not heat_pump.backup_heating_switchover_temp.nil?
        backup_lockout_temp = UnitConversions.convert(heat_pump.backup_heating_switchover_temp, 'F', 'C')
        compressor_lockout_temp = UnitConversions.convert(heat_pump.backup_heating_switchover_temp, 'F', 'C')
      else
        if not heat_pump.backup_heating_lockout_temp.nil?
          backup_lockout_temp = UnitConversions.convert(heat_pump.backup_heating_lockout_temp, 'F', 'C')
        end
        if not heat_pump.compressor_lockout_temp.nil?
          compressor_lockout_temp = UnitConversions.convert(heat_pump.compressor_lockout_temp, 'F', 'C')
        end
      end

      # Check unitary system
      assert_equal(1, model.getAirLoopHVACUnitarySystems.size)
      unitary_system = model.getAirLoopHVACUnitarySystems[0]
      if not backup_lockout_temp.nil?
        assert_in_delta(backup_lockout_temp, unitary_system.maximumOutdoorDryBulbTemperatureforSupplementalHeaterOperation, 0.01)
      end

      # Check coil
      assert_equal(1, model.getCoilHeatingDXSingleSpeeds.size + model.getCoilHeatingDXMultiSpeeds.size)
      if not compressor_lockout_temp.nil?
        heating_coil = model.getCoilHeatingDXSingleSpeeds.size > 0 ? model.getCoilHeatingDXSingleSpeeds[0] : model.getCoilHeatingDXMultiSpeeds[0]
        assert_in_delta(compressor_lockout_temp, heating_coil.minimumOutdoorDryBulbTemperatureforCompressorOperation, 0.01)
      end
    end
  end

  def test_air_to_air_heat_pump_2_speed
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-hvac-air-to-air-heat-pump-2-speed.xml'))
    model, hpxml = _test_measure(args_hash)

    # Get HPXML values
    heat_pump = hpxml.heat_pumps[0]
    backup_efficiency = heat_pump.backup_heating_efficiency_percent
    clg_capacity = UnitConversions.convert(heat_pump.cooling_capacity, 'Btu/hr', 'W')
    htg_capacity = UnitConversions.convert(heat_pump.heating_capacity, 'Btu/hr', 'W')
    supp_htg_capacity = UnitConversions.convert(heat_pump.backup_heating_capacity, 'Btu/hr', 'W')

    # Check cooling coil
    assert_equal(1, model.getCoilCoolingDXMultiSpeeds.size)
    clg_coil = model.getCoilCoolingDXMultiSpeeds[0]
    cops = [4.95, 4.59] # Expected values
    cops.each_with_index do |cop, i|
      assert_in_epsilon(cop, clg_coil.stages[i].grossRatedCoolingCOP, 0.01)
    end
    assert_in_epsilon(clg_capacity, clg_coil.stages[-1].grossRatedTotalCoolingCapacity.get, 0.01)

    # Check heating coil
    assert_equal(1, model.getCoilHeatingDXMultiSpeeds.size)
    htg_coil = model.getCoilHeatingDXMultiSpeeds[0]
    cops = [4.52, 4.08] # Expected values
    cops.each_with_index do |cop, i|
      assert_in_epsilon(cop, htg_coil.stages[i].grossRatedHeatingCOP, 0.01)
    end
    assert_in_epsilon(htg_capacity, htg_coil.stages[-1].grossRatedHeatingCapacity.get, 0.01)

    # Check supp heating coil
    assert_equal(1, model.getCoilHeatingElectrics.size)
    supp_htg_coil = model.getCoilHeatingElectrics[0]
    assert_in_epsilon(backup_efficiency, supp_htg_coil.efficiency, 0.01)
    assert_in_epsilon(supp_htg_capacity, supp_htg_coil.nominalCapacity.get, 0.01)

    # Check EMS
    assert_equal(1, model.getAirLoopHVACUnitarySystems.size)
    unitary_system = model.getAirLoopHVACUnitarySystems[0]
    program_values = get_ems_values(model.getEnergyManagementSystemPrograms, "#{unitary_system.name} IQ")
    assert(program_values.empty?) # Check no EMS program
  end

  def test_air_to_air_heat_pump_var_speed
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-hvac-air-to-air-heat-pump-var-speed.xml'))
    model, hpxml = _test_measure(args_hash)

    # Get HPXML values
    heat_pump = hpxml.heat_pumps[0]
    backup_efficiency = heat_pump.backup_heating_efficiency_percent
    clg_capacity = UnitConversions.convert(heat_pump.cooling_capacity, 'Btu/hr', 'W')
    htg_capacity = UnitConversions.convert(heat_pump.heating_capacity, 'Btu/hr', 'W')
    supp_htg_capacity = UnitConversions.convert(heat_pump.backup_heating_capacity, 'Btu/hr', 'W')

    # Check cooling coil
    assert_equal(1, model.getCoilCoolingDXMultiSpeeds.size)
    clg_coil = model.getCoilCoolingDXMultiSpeeds[0]
    cops = [5.93, 6.15, 5.98, 5.54] # Expected values
    cops.each_with_index do |cop, i|
      assert_in_epsilon(cop, clg_coil.stages[i].grossRatedCoolingCOP, 0.01)
    end
    assert_in_epsilon(clg_capacity, clg_coil.stages[-1].grossRatedTotalCoolingCapacity.get, 0.01)

    # Check heating coil
    assert_equal(1, model.getCoilHeatingDXMultiSpeeds.size)
    htg_coil = model.getCoilHeatingDXMultiSpeeds[0]
    cops = [5.67, 4.84, 4.09, 3.91] # Expected values
    cops.each_with_index do |cop, i|
      assert_in_epsilon(cop, htg_coil.stages[i].grossRatedHeatingCOP, 0.01)
    end
    assert_in_epsilon(htg_capacity, htg_coil.stages[-2].grossRatedHeatingCapacity.get, 0.01)

    # Check supp heating coil
    assert_equal(1, model.getCoilHeatingElectrics.size)
    supp_htg_coil = model.getCoilHeatingElectrics[0]
    assert_in_epsilon(backup_efficiency, supp_htg_coil.efficiency, 0.01)
    assert_in_epsilon(supp_htg_capacity, supp_htg_coil.nominalCapacity.get, 0.01)

    # Check EMS
    assert_equal(1, model.getAirLoopHVACUnitarySystems.size)
    unitary_system = model.getAirLoopHVACUnitarySystems[0]
    program_values = get_ems_values(model.getEnergyManagementSystemPrograms, "#{unitary_system.name} IQ")
    assert(program_values.empty?) # Check no EMS program
  end

  def test_mini_split_heat_pump
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-hvac-mini-split-heat-pump-ductless.xml'))
    model, hpxml = _test_measure(args_hash)

    # Get HPXML values
    heat_pump = hpxml.heat_pumps[0]
    clg_capacity = UnitConversions.convert(heat_pump.cooling_capacity, 'Btu/hr', 'W')
    htg_capacity = UnitConversions.convert(heat_pump.heating_capacity, 'Btu/hr', 'W')

    # Check cooling coil
    assert_equal(1, model.getCoilCoolingDXMultiSpeeds.size)
    clg_coil = model.getCoilCoolingDXMultiSpeeds[0]
    cops = [5.76, 4.99, 4.19, 3.10] # Expected values
    cops.each_with_index do |cop, i|
      assert_in_epsilon(cop, clg_coil.stages[i].grossRatedCoolingCOP, 0.01)
    end
    assert_in_epsilon(clg_capacity * 1.2, clg_coil.stages[-1].grossRatedTotalCoolingCapacity.get, 0.01)

    # Check heating coil
    assert_equal(1, model.getCoilHeatingDXMultiSpeeds.size)
    htg_coil = model.getCoilHeatingDXMultiSpeeds[0]
    cops = [5.42, 4.34, 3.98, 3.60] # Expected values
    cops.each_with_index do |cop, i|
      assert_in_epsilon(cop, htg_coil.stages[i].grossRatedHeatingCOP, 0.01)
    end
    assert_in_epsilon(htg_capacity * 1.2, htg_coil.stages[-1].grossRatedHeatingCapacity.get, 0.01)

    # Check supp heating coil
    assert_equal(0, model.getCoilHeatingElectrics.size)

    # Check EMS
    assert_equal(1, model.getAirLoopHVACUnitarySystems.size)
    unitary_system = model.getAirLoopHVACUnitarySystems[0]
    program_values = get_ems_values(model.getEnergyManagementSystemPrograms, "#{unitary_system.name} IQ")
    assert(program_values.empty?) # Check no EMS program
  end

  def test_mini_split_air_conditioner
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-hvac-mini-split-air-conditioner-only-ductless.xml'))
    model, hpxml = _test_measure(args_hash)

    # Get HPXML values
    cooling_system = hpxml.cooling_systems[0]
    clg_capacity = UnitConversions.convert(cooling_system.cooling_capacity, 'Btu/hr', 'W')

    # Check cooling coil
    assert_equal(1, model.getCoilCoolingDXMultiSpeeds.size)
    clg_coil = model.getCoilCoolingDXMultiSpeeds[0]
    cops = [5.76, 4.99, 4.19, 3.10] # Expected values
    cops.each_with_index do |cop, i|
      assert_in_epsilon(cop, clg_coil.stages[i].grossRatedCoolingCOP, 0.01)
    end
    assert_in_epsilon(clg_capacity * 1.2, clg_coil.stages[-1].grossRatedTotalCoolingCapacity.get, 0.01)

    # Check EMS
    assert_equal(1, model.getAirLoopHVACUnitarySystems.size)
    unitary_system = model.getAirLoopHVACUnitarySystems[0]
    program_values = get_ems_values(model.getEnergyManagementSystemPrograms, "#{unitary_system.name} IQ")
    assert(program_values.empty?) # Check no EMS program
  end

  def test_ground_to_air_heat_pump
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-hvac-ground-to-air-heat-pump.xml'))
    model, hpxml = _test_measure(args_hash)

    # Get HPXML values
    heat_pump = hpxml.heat_pumps[0]
    backup_efficiency = heat_pump.backup_heating_efficiency_percent
    clg_capacity = UnitConversions.convert(heat_pump.cooling_capacity, 'Btu/hr', 'W')
    htg_capacity = UnitConversions.convert(heat_pump.heating_capacity, 'Btu/hr', 'W')
    supp_htg_capacity = UnitConversions.convert(heat_pump.backup_heating_capacity, 'Btu/hr', 'W')

    # Check cooling coil
    assert_equal(1, model.getCoilCoolingWaterToAirHeatPumpEquationFits.size)
    clg_coil = model.getCoilCoolingWaterToAirHeatPumpEquationFits[0]
    cop = 4.87 # Expected values
    assert_in_epsilon(cop, clg_coil.ratedCoolingCoefficientofPerformance, 0.01)
    assert_in_epsilon(clg_capacity, clg_coil.ratedTotalCoolingCapacity.get, 0.01)

    # Check heating coil
    assert_equal(1, model.getCoilHeatingWaterToAirHeatPumpEquationFits.size)
    htg_coil = model.getCoilHeatingWaterToAirHeatPumpEquationFits[0]
    cop = 3.6 # Expected values
    assert_in_epsilon(cop, htg_coil.ratedHeatingCoefficientofPerformance, 0.01)
    assert_in_epsilon(htg_capacity, htg_coil.ratedHeatingCapacity.get, 0.01)

    # Check supp heating coil
    assert_equal(1, model.getCoilHeatingElectrics.size)
    supp_htg_coil = model.getCoilHeatingElectrics[0]
    assert_in_epsilon(backup_efficiency, supp_htg_coil.efficiency, 0.01)
    assert_in_epsilon(supp_htg_capacity, supp_htg_coil.nominalCapacity.get, 0.01)

    # Check EMS
    assert_equal(1, model.getAirLoopHVACUnitarySystems.size)
    unitary_system = model.getAirLoopHVACUnitarySystems[0]
    program_values = get_ems_values(model.getEnergyManagementSystemPrograms, "#{unitary_system.name} IQ")
    assert(program_values.empty?) # Check no EMS program
  end

  def test_shared_chiller_baseboard
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-bldgtype-multifamily-shared-chiller-only-baseboard.xml'))
    model, hpxml = _test_measure(args_hash)

    # Get HPXML values
    cooling_system = hpxml.cooling_systems[0]
    capacity = UnitConversions.convert(cooling_system.cooling_capacity, 'Btu/hr', 'W')

    # Check cooling coil
    assert_equal(1, model.getCoilCoolingDXSingleSpeeds.size)
    clg_coil = model.getCoilCoolingDXSingleSpeeds[0]
    cop = 3.85 # Expected value
    assert_in_epsilon(cop, clg_coil.ratedCOP, 0.01)
    refute_in_epsilon(capacity, clg_coil.ratedTotalCoolingCapacity.get, 0.01) # Uses autosized capacity
  end

  def test_shared_chiller_fan_coil
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-bldgtype-multifamily-shared-chiller-only-fan-coil.xml'))
    model, hpxml = _test_measure(args_hash)

    # Get HPXML values
    cooling_system = hpxml.cooling_systems[0]
    capacity = UnitConversions.convert(cooling_system.cooling_capacity, 'Btu/hr', 'W')

    # Check cooling coil
    assert_equal(1, model.getCoilCoolingDXSingleSpeeds.size)
    clg_coil = model.getCoilCoolingDXSingleSpeeds[0]
    cop = 3.45 # Expected value
    assert_in_epsilon(cop, clg_coil.ratedCOP, 0.01)
    refute_in_epsilon(capacity, clg_coil.ratedTotalCoolingCapacity.get, 0.01) # Uses autosized capacity
  end

  def test_shared_chiller_water_loop_heat_pump
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-bldgtype-multifamily-shared-chiller-only-water-loop-heat-pump.xml'))
    model, hpxml = _test_measure(args_hash)

    # Get HPXML values
    cooling_system = hpxml.cooling_systems[0]
    capacity = UnitConversions.convert(cooling_system.cooling_capacity, 'Btu/hr', 'W')

    # Check cooling coil
    assert_equal(1, model.getCoilCoolingDXSingleSpeeds.size)
    clg_coil = model.getCoilCoolingDXSingleSpeeds[0]
    cop = 1.30 # Expected value
    assert_in_epsilon(cop, clg_coil.ratedCOP, 0.01)
    refute_in_epsilon(capacity, clg_coil.ratedTotalCoolingCapacity.get, 0.01) # Uses autosized capacity
  end

  def test_shared_cooling_tower_water_loop_heat_pump
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-bldgtype-multifamily-shared-cooling-tower-only-water-loop-heat-pump.xml'))
    model, hpxml = _test_measure(args_hash)

    # Get HPXML values
    cooling_system = hpxml.cooling_systems[0]
    capacity = UnitConversions.convert(cooling_system.cooling_capacity.to_f, 'Btu/hr', 'W')

    # Check cooling coil
    assert_equal(1, model.getCoilCoolingDXSingleSpeeds.size)
    clg_coil = model.getCoilCoolingDXSingleSpeeds[0]
    cop = 3.68 # Expected value
    assert_in_epsilon(cop, clg_coil.ratedCOP, 0.01)
    refute_in_epsilon(capacity, clg_coil.ratedTotalCoolingCapacity.get, 0.01) # Uses autosized capacity
  end

  def test_shared_boiler_baseboard
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-bldgtype-multifamily-shared-boiler-only-baseboard.xml'))
    model, hpxml = _test_measure(args_hash)

    # Get HPXML values
    heating_system = hpxml.heating_systems[0]
    afue = heating_system.heating_efficiency_afue
    capacity = UnitConversions.convert(heating_system.heating_capacity.to_f, 'Btu/hr', 'W')
    fuel = heating_system.heating_system_fuel

    # Check boiler
    assert_equal(1, model.getBoilerHotWaters.size)
    boiler = model.getBoilerHotWaters[0]
    assert_in_epsilon(afue, boiler.nominalThermalEfficiency, 0.01)
    refute_in_epsilon(capacity, boiler.nominalCapacity.get, 0.01) # Uses autosized capacity
    assert_equal(EPlus.fuel_type(fuel), boiler.fuelType)
  end

  def test_shared_boiler_fan_coil
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-bldgtype-multifamily-shared-boiler-only-fan-coil.xml'))
    model, hpxml = _test_measure(args_hash)

    # Get HPXML values
    heating_system = hpxml.heating_systems[0]
    afue = heating_system.heating_efficiency_afue
    capacity = UnitConversions.convert(heating_system.heating_capacity.to_f, 'Btu/hr', 'W')
    fuel = heating_system.heating_system_fuel

    # Check boiler
    assert_equal(1, model.getBoilerHotWaters.size)
    boiler = model.getBoilerHotWaters[0]
    assert_in_epsilon(afue, boiler.nominalThermalEfficiency, 0.01)
    refute_in_epsilon(capacity, boiler.nominalCapacity.get, 0.01) # Uses autosized capacity
    assert_equal(EPlus.fuel_type(fuel), boiler.fuelType)
  end

  def test_shared_boiler_water_loop_heat_pump
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-bldgtype-multifamily-shared-boiler-only-water-loop-heat-pump.xml'))
    model, hpxml = _test_measure(args_hash)

    # Get HPXML values
    heating_system = hpxml.heating_systems[0]
    afue = heating_system.heating_efficiency_afue
    capacity = UnitConversions.convert(heating_system.heating_capacity.to_f, 'Btu/hr', 'W')
    fuel = heating_system.heating_system_fuel
    heat_pump = hpxml.heat_pumps[0]
    wlhp_cop = heat_pump.heating_efficiency_cop

    # Check boiler
    assert_equal(1, model.getBoilerHotWaters.size)
    boiler = model.getBoilerHotWaters[0]
    assert_in_epsilon(afue, boiler.nominalThermalEfficiency, 0.01)
    refute_in_epsilon(capacity, boiler.nominalCapacity.get, 0.01) # Uses autosized capacity
    assert_equal(EPlus.fuel_type(fuel), boiler.fuelType)

    # Check cooling coil
    assert_equal(0, model.getCoilCoolingDXSingleSpeeds.size)

    # Check heating coil
    assert_equal(1, model.getCoilHeatingDXSingleSpeeds.size)
    htg_coil = model.getCoilHeatingDXSingleSpeeds[0]
    assert_in_epsilon(wlhp_cop, htg_coil.ratedCOP, 0.01)
    refute_in_epsilon(capacity, htg_coil.ratedTotalHeatingCapacity.get, 0.01) # Uses autosized capacity

    # Check supp heating coil
    assert_equal(0, model.getCoilHeatingElectrics.size)
  end

  def test_shared_ground_loop_ground_to_air_heat_pump
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-bldgtype-multifamily-shared-ground-loop-ground-to-air-heat-pump.xml'))
    model, hpxml = _test_measure(args_hash)

    # Get HPXML values
    heat_pump = hpxml.heat_pumps[0]
    backup_efficiency = heat_pump.backup_heating_efficiency_percent
    clg_capacity = UnitConversions.convert(heat_pump.cooling_capacity, 'Btu/hr', 'W')
    htg_capacity = UnitConversions.convert(heat_pump.heating_capacity, 'Btu/hr', 'W')
    supp_htg_capacity = UnitConversions.convert(heat_pump.backup_heating_capacity, 'Btu/hr', 'W')

    # Check cooling coil
    assert_equal(1, model.getCoilCoolingWaterToAirHeatPumpEquationFits.size)
    clg_coil = model.getCoilCoolingWaterToAirHeatPumpEquationFits[0]
    cop = 4.87 # Expected values
    assert_in_epsilon(cop, clg_coil.ratedCoolingCoefficientofPerformance, 0.01)
    assert_in_epsilon(clg_capacity, clg_coil.ratedTotalCoolingCapacity.get, 0.01)

    # Check heating coil
    assert_equal(1, model.getCoilHeatingWaterToAirHeatPumpEquationFits.size)
    htg_coil = model.getCoilHeatingWaterToAirHeatPumpEquationFits[0]
    cop = 3.6 # Expected values
    assert_in_epsilon(cop, htg_coil.ratedHeatingCoefficientofPerformance, 0.01)
    assert_in_epsilon(htg_capacity, htg_coil.ratedHeatingCapacity.get, 0.01)

    # Check supp heating coil
    assert_equal(1, model.getCoilHeatingElectrics.size)
    supp_htg_coil = model.getCoilHeatingElectrics[0]
    assert_in_epsilon(backup_efficiency, supp_htg_coil.efficiency, 0.01)
    assert_in_epsilon(supp_htg_capacity, supp_htg_coil.nominalCapacity.get, 0.01)
  end

  def test_install_quality_air_to_air_heat_pump_1_speed_ratio
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-hvac-install-quality-air-to-air-heat-pump-1-speed.xml'))
    model, hpxml = _test_measure(args_hash)

    # Get HPXML values
    heat_pump = hpxml.heat_pumps[0]
    charge_defect = heat_pump.charge_defect_ratio
    fan_watts_cfm = heat_pump.fan_watts_per_cfm

    # model objects:
    # Unitary system
    assert_equal(1, model.getAirLoopHVACUnitarySystems.size)
    unitary_system = model.getAirLoopHVACUnitarySystems[0]
    cooling_cfm = UnitConversions.convert(unitary_system.supplyAirFlowRateDuringCoolingOperation.get, 'm^3/s', 'cfm')
    heating_cfm = UnitConversions.convert(unitary_system.supplyAirFlowRateDuringHeatingOperation.get, 'm^3/s', 'cfm')

    # Cooling coil
    assert_equal(1, model.getCoilCoolingDXSingleSpeeds.size)
    clg_coil = model.getCoilCoolingDXSingleSpeeds[0]
    rated_airflow_cfm_clg = UnitConversions.convert(clg_coil.ratedAirFlowRate.get, 'm^3/s', 'cfm')

    # Heating coil
    assert_equal(1, model.getCoilHeatingDXSingleSpeeds.size)
    htg_coil = model.getCoilHeatingDXSingleSpeeds[0]
    rated_airflow_cfm_htg = UnitConversions.convert(htg_coil.ratedAirFlowRate.get, 'm^3/s', 'cfm')

    # Fan
    fan = unitary_system.supplyFan.get.to_FanSystemModel.get
    assert_in_epsilon(fan_watts_cfm, fan.designPressureRise / fan.fanTotalEfficiency * UnitConversions.convert(1.0, 'cfm', 'm^3/s'), 0.01)

    # Check installation quality EMS
    program_values = get_ems_values(model.getEnergyManagementSystemPrograms, "#{unitary_system.name} IQ")

    # defect ratios in EMS is calculated correctly
    assert_in_epsilon(program_values['F_CH'].sum, charge_defect, 0.01)
    assert_in_epsilon(program_values['FF_AF_clg'].sum, cooling_cfm / rated_airflow_cfm_clg, 0.01)
    assert_in_epsilon(program_values['FF_AF_htg'].sum, heating_cfm / rated_airflow_cfm_htg, 0.01)
  end

  def test_install_quality_air_to_air_heat_pump_2_speed_ratio
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-hvac-install-quality-air-to-air-heat-pump-2-speed.xml'))
    model, hpxml = _test_measure(args_hash)

    # Get HPXML values
    heat_pump = hpxml.heat_pumps[0]
    _check_install_quality_multispeed_ratio(heat_pump, model, heat_pump)
  end

  def test_install_quality_air_to_air_heat_pump_var_speed_ratio
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-hvac-install-quality-air-to-air-heat-pump-var-speed.xml'))
    model, hpxml = _test_measure(args_hash)

    # Get HPXML values
    heat_pump = hpxml.heat_pumps[0]
    _check_install_quality_multispeed_ratio(heat_pump, model, heat_pump)
  end

  def test_install_quality_furnace_central_air_conditioner_1_speed_ratio
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-hvac-install-quality-furnace-gas-central-ac-1-speed.xml'))
    model, hpxml = _test_measure(args_hash)

    # Get HPXML values
    cooling_system = hpxml.cooling_systems[0]
    heating_system = hpxml.heating_systems[0]
    charge_defect = cooling_system.charge_defect_ratio
    fan_watts_cfm = cooling_system.fan_watts_per_cfm
    fan_watts_cfm2 = heating_system.fan_watts_per_cfm

    # model objects:
    # Unitary system
    assert_equal(1, model.getAirLoopHVACUnitarySystems.size)
    unitary_system = model.getAirLoopHVACUnitarySystems[0]
    cooling_cfm = UnitConversions.convert(unitary_system.supplyAirFlowRateDuringCoolingOperation.get, 'm^3/s', 'cfm')

    # Cooling coil
    assert_equal(1, model.getCoilCoolingDXSingleSpeeds.size)
    clg_coil = model.getCoilCoolingDXSingleSpeeds[0]
    rated_airflow_cfm = UnitConversions.convert(clg_coil.ratedAirFlowRate.get, 'm^3/s', 'cfm')

    # Fan
    fan = unitary_system.supplyFan.get.to_FanSystemModel.get
    assert_in_epsilon(fan_watts_cfm, fan.designPressureRise / fan.fanTotalEfficiency * UnitConversions.convert(1.0, 'cfm', 'm^3/s'), 0.01)
    assert_in_epsilon(fan_watts_cfm2, fan.designPressureRise / fan.fanTotalEfficiency * UnitConversions.convert(1.0, 'cfm', 'm^3/s'), 0.01)

    # Check installation quality EMS
    program_values = get_ems_values(model.getEnergyManagementSystemPrograms, "#{unitary_system.name} IQ")

    # defect ratios in EMS is calculated correctly
    assert_in_epsilon(program_values['F_CH'].sum, charge_defect, 0.01)

    # Fan air flow has already applied air flow defect ratio
    assert_in_epsilon(program_values['FF_AF_clg'].sum, cooling_cfm / rated_airflow_cfm, 0.01)
  end

  def test_install_quality_furnace_central_air_conditioner_2_speed_ratio
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-hvac-install-quality-furnace-gas-central-ac-2-speed.xml'))
    model, hpxml = _test_measure(args_hash)

    # Get HPXML values
    cooling_system = hpxml.cooling_systems[0]
    _check_install_quality_multispeed_ratio(cooling_system, model)
  end

  def test_install_quality_furnace_central_air_conditioner_var_speed_ratio
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-hvac-install-quality-furnace-gas-central-ac-var-speed.xml'))
    model, hpxml = _test_measure(args_hash)

    # Get HPXML values
    cooling_system = hpxml.cooling_systems[0]
    _check_install_quality_multispeed_ratio(cooling_system, model)
  end

  def test_install_quality_furnace_gas_ratio
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-hvac-install-quality-furnace-gas-only.xml'))
    model, hpxml = _test_measure(args_hash)

    # Get HPXML values
    heating_system = hpxml.heating_systems[0]
    fan_watts_cfm = heating_system.fan_watts_per_cfm

    assert_equal(1, model.getAirLoopHVACUnitarySystems.size)
    unitary_system = model.getAirLoopHVACUnitarySystems[0]

    # Fan
    fan = unitary_system.supplyFan.get.to_FanSystemModel.get
    assert_in_epsilon(fan_watts_cfm, fan.designPressureRise / fan.fanTotalEfficiency * UnitConversions.convert(1.0, 'cfm', 'm^3/s'), 0.01)
  end

  def test_install_quality_ground_to_air_heat_pump_ratio
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-hvac-install-quality-ground-to-air-heat-pump.xml'))
    model, hpxml = _test_measure(args_hash)

    # Get HPXML values
    heat_pump = hpxml.heat_pumps[0]
    charge_defect = heat_pump.charge_defect_ratio
    fan_watts_cfm = heat_pump.fan_watts_per_cfm

    # model objects:
    # Unitary system
    assert_equal(1, model.getAirLoopHVACUnitarySystems.size)
    unitary_system = model.getAirLoopHVACUnitarySystems[0]
    cooling_cfm = UnitConversions.convert(unitary_system.supplyAirFlowRateDuringCoolingOperation.get, 'm^3/s', 'cfm')
    heating_cfm = UnitConversions.convert(unitary_system.supplyAirFlowRateDuringHeatingOperation.get, 'm^3/s', 'cfm')

    # Cooling coil
    assert_equal(1, model.getCoilCoolingWaterToAirHeatPumpEquationFits.size)
    clg_coil = model.getCoilCoolingWaterToAirHeatPumpEquationFits[0]
    rated_airflow_cfm_clg = UnitConversions.convert(clg_coil.ratedAirFlowRate.get, 'm^3/s', 'cfm')

    # Heating coil
    assert_equal(1, model.getCoilHeatingWaterToAirHeatPumpEquationFits.size)
    htg_coil = model.getCoilHeatingWaterToAirHeatPumpEquationFits[0]
    rated_airflow_cfm_htg = UnitConversions.convert(htg_coil.ratedAirFlowRate.get, 'm^3/s', 'cfm')

    # Fan
    fan = unitary_system.supplyFan.get.to_FanSystemModel.get
    assert_in_epsilon(fan_watts_cfm, fan.designPressureRise / fan.fanTotalEfficiency * UnitConversions.convert(1.0, 'cfm', 'm^3/s'), 0.01)

    # Check installation quality EMS
    program_values = get_ems_values(model.getEnergyManagementSystemPrograms, "#{unitary_system.name} IQ")

    # defect ratios in EMS is calculated correctly
    assert_in_epsilon(program_values['F_CH'].sum, charge_defect, 0.01)
    assert_in_epsilon(program_values['FF_AF_clg'].sum, cooling_cfm / rated_airflow_cfm_clg, 0.01)
    assert_in_epsilon(program_values['FF_AF_htg'].sum, heating_cfm / rated_airflow_cfm_htg, 0.01)
  end

  def test_install_quality_mini_split_air_conditioner_ratio
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-hvac-install-quality-mini-split-air-conditioner-only-ducted.xml'))
    model, hpxml = _test_measure(args_hash)

    # Get HPXML values
    cooling_system = hpxml.cooling_systems[0]
    _check_install_quality_multispeed_ratio(cooling_system, model)
  end

  def test_install_quality_mini_split_heat_pump_ratio
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-hvac-install-quality-mini-split-heat-pump-ducted.xml'))
    model, hpxml = _test_measure(args_hash)

    # Get HPXML values
    heat_pump = hpxml.heat_pumps[0]
    _check_install_quality_multispeed_ratio(heat_pump, model, heat_pump)
  end

  def test_custom_seasons
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-hvac-seasons.xml'))
    model, hpxml = _test_measure(args_hash)

    # Get HPXML values
    hvac_control = hpxml.hvac_controls[0]
    seasons_heating_begin_month = hvac_control.seasons_heating_begin_month
    seasons_heating_begin_day = hvac_control.seasons_heating_begin_day
    seasons_heating_end_month = hvac_control.seasons_heating_end_month
    seasons_heating_end_day = hvac_control.seasons_heating_end_day
    seasons_cooling_begin_month = hvac_control.seasons_cooling_begin_month
    seasons_cooling_begin_day = hvac_control.seasons_cooling_begin_day
    seasons_cooling_end_month = hvac_control.seasons_cooling_end_month
    seasons_cooling_end_day = hvac_control.seasons_cooling_end_day

    # Get objects
    unitary_system = model.getAirLoopHVACUnitarySystems[0]
    zone = unitary_system.controllingZoneorThermostatLocation.get
    year = model.getYearDescription.assumedYear

    # Check heating season
    start_day_num = Schedule.get_day_num_from_month_day(year, seasons_heating_begin_month, seasons_heating_begin_day)
    end_day_num = Schedule.get_day_num_from_month_day(year, seasons_heating_end_month, seasons_heating_end_day)
    start_date = OpenStudio::Date::fromDayOfYear(start_day_num, year)
    end_date = OpenStudio::Date::fromDayOfYear(end_day_num, year)
    heating_days = zone.sequentialHeatingFractionSchedule(zone.airLoopHVACTerminals[0]).get.to_ScheduleRuleset.get
    assert_equal(heating_days.scheduleRules.size, 3)
    start_dates = []
    end_dates = []
    heating_days.scheduleRules.each do |schedule_rule|
      next unless schedule_rule.daySchedule.values.include? 1

      start_dates.push(schedule_rule.startDate.get)
      end_dates.push(schedule_rule.endDate.get)
    end
    assert_includes(start_dates, start_date)
    assert_includes(end_dates, end_date)

    # Check cooling season
    start_day_num = Schedule.get_day_num_from_month_day(year, seasons_cooling_begin_month, seasons_cooling_begin_day)
    end_day_num = Schedule.get_day_num_from_month_day(year, seasons_cooling_end_month, seasons_cooling_end_day)
    start_date = OpenStudio::Date::fromDayOfYear(start_day_num, year)
    end_date = OpenStudio::Date::fromDayOfYear(end_day_num, year)
    cooling_days = zone.sequentialCoolingFractionSchedule(zone.airLoopHVACTerminals[0]).get.to_ScheduleRuleset.get
    assert_equal(cooling_days.scheduleRules.size, 3)
    cooling_days.scheduleRules.each do |schedule_rule|
      next unless schedule_rule.daySchedule.values.include? 1

      start_dates.push(schedule_rule.startDate.get)
      end_dates.push(schedule_rule.endDate.get)
    end
    assert_includes(start_dates, start_date)
    assert_includes(end_dates, end_date)
  end

  def test_crankcase_heater_watts
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-hvac-crankcase-heater-40w.xml'))
    model, hpxml = _test_measure(args_hash)

    # Get HPXML values
    cooling_system = hpxml.cooling_systems[0]
    crankcase_heater_watts = cooling_system.crankcase_heater_watts

    # Check cooling coil
    clg_coil = model.getCoilCoolingDXSingleSpeeds[0]
    assert_in_epsilon(crankcase_heater_watts, clg_coil.crankcaseHeaterCapacity, 0.01)
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

    hpxml = HPXML.new(hpxml_path: args_hash['hpxml_path'])

    File.delete(File.join(File.dirname(__FILE__), 'in.xml'))

    return model, hpxml
  end

  def _check_install_quality_multispeed_ratio(hpxml_clg_sys, model, hpxml_htg_sys = nil)
    charge_defect = hpxml_clg_sys.charge_defect_ratio
    fan_watts_cfm = hpxml_clg_sys.fan_watts_per_cfm

    # model objects:
    # Unitary system
    assert_equal(1, model.getAirLoopHVACUnitarySystems.size)
    unitary_system = model.getAirLoopHVACUnitarySystems[0]
    perf = unitary_system.designSpecificationMultispeedObject.get.to_UnitarySystemPerformanceMultispeed.get
    clg_ratios = perf.supplyAirflowRatioFields.map { |field| field.coolingRatio.get }
    cooling_cfm = UnitConversions.convert(unitary_system.supplyAirFlowRateDuringCoolingOperation.get, 'm^3/s', 'cfm')

    # Cooling coil
    assert_equal(1, model.getCoilCoolingDXMultiSpeeds.size)
    clg_coil = model.getCoilCoolingDXMultiSpeeds[0]
    rated_airflow_cfm_clg = []
    clg_coil.stages.each do |stage|
      rated_airflow_cfm_clg << UnitConversions.convert(stage.ratedAirFlowRate.get, 'm^3/s', 'cfm')
    end

    # Fan
    fan = unitary_system.supplyFan.get.to_FanSystemModel.get
    assert_in_epsilon(fan_watts_cfm, fan.designPressureRise / fan.fanTotalEfficiency * UnitConversions.convert(1.0, 'cfm', 'm^3/s'), 0.01)

    # Check installation quality EMS
    program_values = get_ems_values(model.getEnergyManagementSystemPrograms, "#{unitary_system.name} IQ")
    clg_speed_cfms = clg_ratios.map { |ratio| cooling_cfm * ratio }
    assert_in_epsilon(program_values['F_CH'].sum, charge_defect, 0.01)
    assert_in_epsilon(program_values['FF_AF_clg'].sum, clg_speed_cfms.zip(rated_airflow_cfm_clg).map { |cfm, rated_cfm| cfm / rated_cfm }.sum, 0.01)
    if not hpxml_htg_sys.nil?
      heating_cfm = UnitConversions.convert(unitary_system.supplyAirFlowRateDuringHeatingOperation.get, 'm^3/s', 'cfm')
      htg_ratios = perf.supplyAirflowRatioFields.map { |field| field.heatingRatio.get }

      # Heating coil
      assert_equal(1, model.getCoilHeatingDXMultiSpeeds.size)
      htg_coil = model.getCoilHeatingDXMultiSpeeds[0]
      rated_airflow_cfm_htg = []
      htg_coil.stages.each do |stage|
        rated_airflow_cfm_htg << UnitConversions.convert(stage.ratedAirFlowRate.get, 'm^3/s', 'cfm')
      end

      htg_speed_cfms = htg_ratios.map { |ratio| heating_cfm * ratio }
      assert_in_epsilon(program_values['FF_AF_htg'].sum, htg_speed_cfms.zip(rated_airflow_cfm_htg).map { |cfm, rated_cfm| cfm / rated_cfm }.sum, 0.01)
    end
  end
end
