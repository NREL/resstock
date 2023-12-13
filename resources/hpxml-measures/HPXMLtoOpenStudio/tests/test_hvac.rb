# frozen_string_literal: true

require_relative '../resources/minitest_helper'
require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'fileutils'
require_relative '../measure.rb'
require_relative '../resources/util.rb'
require_relative 'util.rb'

class HPXMLtoOpenStudioHVACTest < Minitest::Test
  def setup
    @root_path = File.absolute_path(File.join(File.dirname(__FILE__), '..', '..'))
    @sample_files_path = File.join(@root_path, 'workflow', 'sample_files')
    @tmp_hpxml_path = File.join(@sample_files_path, 'tmp.xml')
  end

  def teardown
    File.delete(@tmp_hpxml_path) if File.exist? @tmp_hpxml_path
  end

  def test_central_air_conditioner_1_speed
    ['base-hvac-central-ac-only-1-speed.xml',
     'base-hvac-central-ac-only-1-speed-seer2.xml'].each do |hpxml_path|
      args_hash = {}
      args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, hpxml_path))
      model, _hpxml, _hpxml_bldg = _test_measure(args_hash)

      # Check cooling coil
      assert_equal(1, model.getCoilCoolingDXSingleSpeeds.size)
      clg_coil = model.getCoilCoolingDXSingleSpeeds[0]
      assert_in_epsilon(3.73, clg_coil.ratedCOP, 0.01)
      assert_in_epsilon(7230, clg_coil.ratedTotalCoolingCapacity.get, 0.01)

      # Check EMS
      assert_equal(1, model.getAirLoopHVACUnitarySystems.size)
      unitary_system = model.getAirLoopHVACUnitarySystems[0]
      program_values = get_ems_values(model.getEnergyManagementSystemPrograms, "#{unitary_system.name} IQ")
      assert(program_values.empty?) # Check no EMS program
    end
  end

  def test_central_air_conditioner_2_speed
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-central-ac-only-2-speed.xml'))
    model, _hpxml, _hpxml_bldg = _test_measure(args_hash)

    # Check cooling coil
    assert_equal(1, model.getCoilCoolingDXMultiSpeeds.size)
    clg_coil = model.getCoilCoolingDXMultiSpeeds[0]
    assert_equal(2, clg_coil.stages.size)
    [4.95, 4.59].each_with_index do |cop, i|
      assert_in_epsilon(cop, clg_coil.stages[i].grossRatedCoolingCOP, 0.01)
    end
    [5143, 7158].each_with_index do |capacity, i|
      assert_in_epsilon(capacity, clg_coil.stages[i].grossRatedTotalCoolingCapacity.get, 0.01)
    end

    # Check EMS
    assert_equal(1, model.getAirLoopHVACUnitarySystems.size)
    unitary_system = model.getAirLoopHVACUnitarySystems[0]
    program_values = get_ems_values(model.getEnergyManagementSystemPrograms, "#{unitary_system.name} IQ")
    assert(program_values.empty?) # Check no EMS program
  end

  def test_central_air_conditioner_var_speed
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-central-ac-only-var-speed.xml'))
    model, _hpxml, _hpxml_bldg = _test_measure(args_hash)

    # Check cooling coil
    assert_equal(1, model.getCoilCoolingDXMultiSpeeds.size)
    clg_coil = model.getCoilCoolingDXMultiSpeeds[0]
    assert_equal(2, clg_coil.stages.size)
    [5.89, 5.25].each_with_index do |cop, i|
      assert_in_epsilon(cop, clg_coil.stages[i].grossRatedCoolingCOP, 0.01)
    end
    [2780, 7169].each_with_index do |capacity, i|
      assert_in_epsilon(capacity, clg_coil.stages[i].grossRatedTotalCoolingCapacity.get, 0.01)
    end

    # Check EMS
    assert_equal(1, model.getAirLoopHVACUnitarySystems.size)
    unitary_system = model.getAirLoopHVACUnitarySystems[0]
    program_values = get_ems_values(model.getEnergyManagementSystemPrograms, "#{unitary_system.name} IQ")
    assert(program_values.empty?) # Check no EMS program
  end

  def test_room_air_conditioner
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-room-ac-only.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    cooling_system = hpxml_bldg.cooling_systems[0]
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
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-room-ac-only-ceer.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    cooling_system = hpxml_bldg.cooling_systems[0]
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
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-room-ac-with-heating.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    cooling_system = hpxml_bldg.cooling_systems[0]
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
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-ptac.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    cooling_system = hpxml_bldg.cooling_systems[0]
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
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-ptac-with-heating-electricity.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    cooling_system = hpxml_bldg.cooling_systems[0]
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
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-ptac-with-heating-electricity.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    cooling_system = hpxml_bldg.cooling_systems[0]
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
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-pthp.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    heat_pump = hpxml_bldg.heat_pumps[0]
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
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-room-ac-with-reverse-cycle.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    heat_pump = hpxml_bldg.heat_pumps[0]
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
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-furnace-gas-only.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    heating_system = hpxml_bldg.heating_systems[0]
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
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-furnace-elec-only.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    heating_system = hpxml_bldg.heating_systems[0]
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
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-boiler-gas-only.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    heating_system = hpxml_bldg.heating_systems[0]
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
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-boiler-coal-only.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    heating_system = hpxml_bldg.heating_systems[0]
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
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-boiler-elec-only.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    heating_system = hpxml_bldg.heating_systems[0]
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
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-elec-resistance-only.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    heating_system = hpxml_bldg.heating_systems[0]
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
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-stove-oil-only.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    heating_system = hpxml_bldg.heating_systems[0]
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
      args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, hpxml_path))
      model, _hpxml, hpxml_bldg = _test_measure(args_hash)

      # Get HPXML values
      heat_pump = hpxml_bldg.heat_pumps[0]
      backup_efficiency = heat_pump.backup_heating_efficiency_percent
      supp_htg_capacity = UnitConversions.convert(heat_pump.backup_heating_capacity, 'Btu/hr', 'W')

      # Check cooling coil
      assert_equal(1, model.getCoilCoolingDXSingleSpeeds.size)
      clg_coil = model.getCoilCoolingDXSingleSpeeds[0]
      assert_in_epsilon(3.73, clg_coil.ratedCOP, 0.01)
      assert_in_epsilon(10846, clg_coil.ratedTotalCoolingCapacity.get, 0.01)

      # Check heating coil
      assert_equal(1, model.getCoilHeatingDXSingleSpeeds.size)
      htg_coil = model.getCoilHeatingDXSingleSpeeds[0]
      assert_in_epsilon(3.28, htg_coil.ratedCOP, 0.01)
      assert_in_epsilon(10262, htg_coil.ratedTotalHeatingCapacity.get, 0.01)

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
      args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, hpxml_name))
      model, _hpxml, hpxml_bldg = _test_measure(args_hash)

      # Get HPXML values
      heat_pump = hpxml_bldg.heat_pumps[0]
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
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-air-to-air-heat-pump-2-speed.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    heat_pump = hpxml_bldg.heat_pumps[0]
    backup_efficiency = heat_pump.backup_heating_efficiency_percent
    supp_htg_capacity = UnitConversions.convert(heat_pump.backup_heating_capacity, 'Btu/hr', 'W')

    # Check cooling coil
    assert_equal(1, model.getCoilCoolingDXMultiSpeeds.size)
    clg_coil = model.getCoilCoolingDXMultiSpeeds[0]
    assert_equal(2, clg_coil.stages.size)
    [4.95, 4.59].each_with_index do |cop, i|
      assert_in_epsilon(cop, clg_coil.stages[i].grossRatedCoolingCOP, 0.01)
    end
    [7715, 10736].each_with_index do |clg_capacity, i|
      assert_in_epsilon(clg_capacity, clg_coil.stages[i].grossRatedTotalCoolingCapacity.get, 0.01)
    end

    # Check heating coil
    assert_equal(1, model.getCoilHeatingDXMultiSpeeds.size)
    htg_coil = model.getCoilHeatingDXMultiSpeeds[0]
    assert_equal(2, htg_coil.stages.size)
    [4.52, 4.08].each_with_index do |cop, i|
      assert_in_epsilon(cop, htg_coil.stages[i].grossRatedHeatingCOP, 0.01)
    end
    [7499, 10360].each_with_index do |htg_capacity, i|
      assert_in_epsilon(htg_capacity, htg_coil.stages[i].grossRatedHeatingCapacity.get, 0.01)
    end

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
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-air-to-air-heat-pump-var-speed.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    heat_pump = hpxml_bldg.heat_pumps[0]
    backup_efficiency = heat_pump.backup_heating_efficiency_percent
    supp_htg_capacity = UnitConversions.convert(heat_pump.backup_heating_capacity, 'Btu/hr', 'W')

    # Check cooling coil
    assert_equal(1, model.getCoilCoolingDXMultiSpeeds.size)
    clg_coil = model.getCoilCoolingDXMultiSpeeds[0]
    assert_equal(2, clg_coil.stages.size)
    [5.39, 4.77].each_with_index do |cop, i|
      assert_in_epsilon(cop, clg_coil.stages[i].grossRatedCoolingCOP, 0.01)
    end
    [4169, 10753].each_with_index do |clg_capacity, i|
      assert_in_epsilon(clg_capacity, clg_coil.stages[i].grossRatedTotalCoolingCapacity.get, 0.01)
    end

    # Check heating coil
    assert_equal(1, model.getCoilHeatingDXMultiSpeeds.size)
    htg_coil = model.getCoilHeatingDXMultiSpeeds[0]
    assert_equal(2, htg_coil.stages.size)
    [4.56, 3.89].each_with_index do |cop, i|
      assert_in_epsilon(cop, htg_coil.stages[i].grossRatedHeatingCOP, 0.01)
    end
    [3876, 10634].each_with_index do |htg_capacity, i|
      assert_in_epsilon(htg_capacity, htg_coil.stages[i].grossRatedHeatingCapacity.get, 0.01)
    end

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

  def test_air_to_air_heat_pump_var_speed_detailed_performance
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-air-to-air-heat-pump-var-speed-detailed-performance.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    heat_pump = hpxml_bldg.heat_pumps[0]

    # Check cooling coil
    assert_equal(1, model.getCoilCoolingDXMultiSpeeds.size)
    clg_coil = model.getCoilCoolingDXMultiSpeeds[0]
    assert_equal(2, clg_coil.stages.size)
    [4.51, 2.88].each_with_index do |cop, i|
      assert_in_epsilon(cop, clg_coil.stages[i].grossRatedCoolingCOP, 0.01)
    end
    [3435, 10726].each_with_index do |clg_capacity, i|
      assert_in_epsilon(clg_capacity, clg_coil.stages[i].grossRatedTotalCoolingCapacity.get, 0.01)
    end

    # Check heating coil
    assert_equal(1, model.getCoilHeatingDXMultiSpeeds.size)
    htg_coil = model.getCoilHeatingDXMultiSpeeds[0]
    assert_equal(2, htg_coil.stages.size)
    [4.75, 3.59].each_with_index do |cop, i|
      assert_in_epsilon(cop, htg_coil.stages[i].grossRatedHeatingCOP, 0.01)
    end
    [2927, 10376].each_with_index do |htg_capacity, i|
      assert_in_epsilon(htg_capacity, htg_coil.stages[i].grossRatedHeatingCapacity.get, 0.01)
    end

    # Check supp heating coil
    backup_efficiency = heat_pump.backup_heating_efficiency_percent
    supp_htg_capacity = UnitConversions.convert(heat_pump.backup_heating_capacity, 'Btu/hr', 'W')
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
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-mini-split-heat-pump-ductless.xml'))
    model, _hpxml, _hpxml_bldg = _test_measure(args_hash)

    # Check cooling coil
    assert_equal(1, model.getCoilCoolingDXMultiSpeeds.size)
    clg_coil = model.getCoilCoolingDXMultiSpeeds[0]
    assert_equal(2, clg_coil.stages.size)
    [4.40, 3.20].each_with_index do |cop, i|
      assert_in_epsilon(cop, clg_coil.stages[i].grossRatedCoolingCOP, 0.01)
    end
    [2691, 10606].each_with_index do |clg_capacity, i|
      assert_in_epsilon(clg_capacity, clg_coil.stages[i].grossRatedTotalCoolingCapacity.get, 0.01)
    end

    # Check heating coil
    assert_equal(1, model.getCoilHeatingDXMultiSpeeds.size)
    htg_coil = model.getCoilHeatingDXMultiSpeeds[0]
    assert_equal(2, htg_coil.stages.size)
    [4.63, 3.31].each_with_index do |cop, i|
      assert_in_epsilon(cop, htg_coil.stages[i].grossRatedHeatingCOP, 0.01)
    end
    [3273, 12890].each_with_index do |htg_capacity, i|
      assert_in_epsilon(htg_capacity, htg_coil.stages[i].grossRatedHeatingCapacity.get, 0.01)
    end

    # Check supp heating coil
    assert_equal(0, model.getCoilHeatingElectrics.size)

    # Check EMS
    assert_equal(1, model.getAirLoopHVACUnitarySystems.size)
    unitary_system = model.getAirLoopHVACUnitarySystems[0]
    program_values = get_ems_values(model.getEnergyManagementSystemPrograms, "#{unitary_system.name} IQ")
    assert(program_values.empty?) # Check no EMS program
  end

  def test_mini_split_heat_pump_detailed_performance
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-mini-split-heat-pump-ductless-detailed-performance.xml'))
    model, _hpxml = _test_measure(args_hash)

    # Check cooling coil
    assert_equal(1, model.getCoilCoolingDXMultiSpeeds.size)
    clg_coil = model.getCoilCoolingDXMultiSpeeds[0]
    assert_equal(2, clg_coil.stages.size)
    [4.06, 3.33].each_with_index do |cop, i|
      assert_in_epsilon(cop, clg_coil.stages[i].grossRatedCoolingCOP, 0.01)
    end
    [3041, 12557].each_with_index do |clg_capacity, i|
      assert_in_epsilon(clg_capacity, clg_coil.stages[i].grossRatedTotalCoolingCapacity.get, 0.01)
    end

    # Check heating coil
    assert_equal(1, model.getCoilHeatingDXMultiSpeeds.size)
    htg_coil = model.getCoilHeatingDXMultiSpeeds[0]
    assert_equal(2, htg_coil.stages.size)
    [4.82, 3.23].each_with_index do |cop, i|
      assert_in_epsilon(cop, htg_coil.stages[i].grossRatedHeatingCOP, 0.01)
    end
    [3557, 16426].each_with_index do |htg_capacity, i|
      assert_in_epsilon(htg_capacity, htg_coil.stages[i].grossRatedHeatingCapacity.get, 0.01)
    end

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
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-mini-split-air-conditioner-only-ductless.xml'))
    model, _hpxml, _hpxml_bldg = _test_measure(args_hash)

    # Check cooling coil
    assert_equal(1, model.getCoilCoolingDXMultiSpeeds.size)
    clg_coil = model.getCoilCoolingDXMultiSpeeds[0]
    assert_equal(2, clg_coil.stages.size)
    [4.40, 3.23].each_with_index do |cop, i|
      assert_in_epsilon(cop, clg_coil.stages[i].grossRatedCoolingCOP, 0.01)
    end
    [1794, 7086].each_with_index do |clg_capacity, i|
      assert_in_epsilon(clg_capacity, clg_coil.stages[i].grossRatedTotalCoolingCapacity.get, 0.01)
    end

    # Check EMS
    assert_equal(1, model.getAirLoopHVACUnitarySystems.size)
    unitary_system = model.getAirLoopHVACUnitarySystems[0]
    program_values = get_ems_values(model.getEnergyManagementSystemPrograms, "#{unitary_system.name} IQ")
    assert(program_values.empty?) # Check no EMS program
  end

  def test_ground_to_air_heat_pump
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-ground-to-air-heat-pump.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    heat_pump = hpxml_bldg.heat_pumps[0]
    backup_efficiency = heat_pump.backup_heating_efficiency_percent
    clg_capacity = UnitConversions.convert(heat_pump.cooling_capacity, 'Btu/hr', 'W')
    htg_capacity = UnitConversions.convert(heat_pump.heating_capacity, 'Btu/hr', 'W')
    supp_htg_capacity = UnitConversions.convert(heat_pump.backup_heating_capacity, 'Btu/hr', 'W')

    # Check cooling coil
    assert_equal(1, model.getCoilCoolingWaterToAirHeatPumpEquationFits.size)
    clg_coil = model.getCoilCoolingWaterToAirHeatPumpEquationFits[0]
    assert_in_epsilon(4.87, clg_coil.ratedCoolingCoefficientofPerformance, 0.01)
    assert_in_epsilon(clg_capacity, clg_coil.ratedTotalCoolingCapacity.get, 0.01)

    # Check heating coil
    assert_equal(1, model.getCoilHeatingWaterToAirHeatPumpEquationFits.size)
    htg_coil = model.getCoilHeatingWaterToAirHeatPumpEquationFits[0]
    assert_in_epsilon(3.6, htg_coil.ratedHeatingCoefficientofPerformance, 0.01)
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

    # Check ghx
    assert(1, model.getGroundHeatExchangerVerticals.size)
    ghx = model.getGroundHeatExchangerVerticals[0]

    # Check xing
    assert(1, model.getSiteGroundTemperatureUndisturbedXings.size)
    xing = model.getSiteGroundTemperatureUndisturbedXings[0]
    assert_in_epsilon(ghx.groundThermalConductivity.get, xing.soilThermalConductivity, 0.01)
    assert_in_epsilon(962, xing.soilDensity, 0.01)
    assert_in_epsilon(ghx.groundThermalHeatCapacity.get / xing.soilDensity, xing.soilSpecificHeat, 0.01)
    assert_in_epsilon(ghx.groundTemperature.get, xing.averageSoilSurfaceTemperature, 0.01)
    assert_in_epsilon(12.5, xing.soilSurfaceTemperatureAmplitude1, 0.01)
    assert_in_epsilon(-1.3, xing.soilSurfaceTemperatureAmplitude2, 0.01)
    assert_in_epsilon(20, xing.phaseShiftofTemperatureAmplitude1, 0.01)
    assert_in_epsilon(31, xing.phaseShiftofTemperatureAmplitude2, 0.01)
  end

  def test_shared_chiller_baseboard
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-bldgtype-mf-unit-shared-chiller-only-baseboard.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    cooling_system = hpxml_bldg.cooling_systems[0]
    capacity = UnitConversions.convert(cooling_system.cooling_capacity, 'Btu/hr', 'W')

    # Check cooling coil
    assert_equal(1, model.getCoilCoolingDXSingleSpeeds.size)
    clg_coil = model.getCoilCoolingDXSingleSpeeds[0]
    assert_in_epsilon(3.85, clg_coil.ratedCOP, 0.01)
    refute_in_epsilon(capacity, clg_coil.ratedTotalCoolingCapacity.get, 0.01) # Uses autosized capacity
  end

  def test_shared_chiller_fan_coil
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-bldgtype-mf-unit-shared-chiller-only-fan-coil.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    cooling_system = hpxml_bldg.cooling_systems[0]
    capacity = UnitConversions.convert(cooling_system.cooling_capacity, 'Btu/hr', 'W')

    # Check cooling coil
    assert_equal(1, model.getCoilCoolingDXSingleSpeeds.size)
    clg_coil = model.getCoilCoolingDXSingleSpeeds[0]
    assert_in_epsilon(3.45, clg_coil.ratedCOP, 0.01)
    refute_in_epsilon(capacity, clg_coil.ratedTotalCoolingCapacity.get, 0.01) # Uses autosized capacity
  end

  def test_shared_chiller_water_loop_heat_pump
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-bldgtype-mf-unit-shared-chiller-only-water-loop-heat-pump.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    cooling_system = hpxml_bldg.cooling_systems[0]
    capacity = UnitConversions.convert(cooling_system.cooling_capacity, 'Btu/hr', 'W')

    # Check cooling coil
    assert_equal(1, model.getCoilCoolingDXSingleSpeeds.size)
    clg_coil = model.getCoilCoolingDXSingleSpeeds[0]
    assert_in_epsilon(1.30, clg_coil.ratedCOP, 0.01)
    refute_in_epsilon(capacity, clg_coil.ratedTotalCoolingCapacity.get, 0.01) # Uses autosized capacity
  end

  def test_shared_cooling_tower_water_loop_heat_pump
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-bldgtype-mf-unit-shared-cooling-tower-only-water-loop-heat-pump.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    cooling_system = hpxml_bldg.cooling_systems[0]
    capacity = UnitConversions.convert(cooling_system.cooling_capacity.to_f, 'Btu/hr', 'W')

    # Check cooling coil
    assert_equal(1, model.getCoilCoolingDXSingleSpeeds.size)
    clg_coil = model.getCoilCoolingDXSingleSpeeds[0]
    assert_in_epsilon(3.68, clg_coil.ratedCOP, 0.01)
    refute_in_epsilon(capacity, clg_coil.ratedTotalCoolingCapacity.get, 0.01) # Uses autosized capacity
  end

  def test_shared_boiler_baseboard
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-bldgtype-mf-unit-shared-boiler-only-baseboard.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    heating_system = hpxml_bldg.heating_systems[0]
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
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-bldgtype-mf-unit-shared-boiler-only-fan-coil.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    heating_system = hpxml_bldg.heating_systems[0]
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
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-bldgtype-mf-unit-shared-boiler-only-water-loop-heat-pump.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    heating_system = hpxml_bldg.heating_systems[0]
    afue = heating_system.heating_efficiency_afue
    capacity = UnitConversions.convert(heating_system.heating_capacity.to_f, 'Btu/hr', 'W')
    fuel = heating_system.heating_system_fuel
    heat_pump = hpxml_bldg.heat_pumps[0]
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
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-bldgtype-mf-unit-shared-ground-loop-ground-to-air-heat-pump.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    heat_pump = hpxml_bldg.heat_pumps[0]
    backup_efficiency = heat_pump.backup_heating_efficiency_percent
    clg_capacity = UnitConversions.convert(heat_pump.cooling_capacity, 'Btu/hr', 'W')
    htg_capacity = UnitConversions.convert(heat_pump.heating_capacity, 'Btu/hr', 'W')
    supp_htg_capacity = UnitConversions.convert(heat_pump.backup_heating_capacity, 'Btu/hr', 'W')

    # Check cooling coil
    assert_equal(1, model.getCoilCoolingWaterToAirHeatPumpEquationFits.size)
    clg_coil = model.getCoilCoolingWaterToAirHeatPumpEquationFits[0]
    assert_in_epsilon(4.87, clg_coil.ratedCoolingCoefficientofPerformance, 0.01)
    assert_in_epsilon(clg_capacity, clg_coil.ratedTotalCoolingCapacity.get, 0.01)

    # Check heating coil
    assert_equal(1, model.getCoilHeatingWaterToAirHeatPumpEquationFits.size)
    htg_coil = model.getCoilHeatingWaterToAirHeatPumpEquationFits[0]
    assert_in_epsilon(3.6, htg_coil.ratedHeatingCoefficientofPerformance, 0.01)
    assert_in_epsilon(htg_capacity, htg_coil.ratedHeatingCapacity.get, 0.01)

    # Check supp heating coil
    assert_equal(1, model.getCoilHeatingElectrics.size)
    supp_htg_coil = model.getCoilHeatingElectrics[0]
    assert_in_epsilon(backup_efficiency, supp_htg_coil.efficiency, 0.01)
    assert_in_epsilon(supp_htg_capacity, supp_htg_coil.nominalCapacity.get, 0.01)
  end

  def test_install_quality_air_to_air_heat_pump_1_speed
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-install-quality-air-to-air-heat-pump-1-speed.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    heat_pump = hpxml_bldg.heat_pumps[0]
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

  def test_install_quality_air_to_air_heat_pump_2_speed
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-install-quality-air-to-air-heat-pump-2-speed.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    heat_pump = hpxml_bldg.heat_pumps[0]
    program_values = _check_install_quality_multispeed_ratio(heat_pump, model, heat_pump)
    [1.088, 1.088].each_with_index do |rated_airflow_ratio, i|
      assert_in_epsilon(rated_airflow_ratio, program_values['FF_AF_clg'][i], 0.01)
    end
    [0.806, 0.806].each_with_index do |rated_airflow_ratio, i|
      assert_in_epsilon(rated_airflow_ratio, program_values['FF_AF_htg'][i], 0.01)
    end
  end

  def test_install_quality_air_to_air_heat_pump_var_speed
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-install-quality-air-to-air-heat-pump-var-speed.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    heat_pump = hpxml_bldg.heat_pumps[0]
    program_values = _check_install_quality_multispeed_ratio(heat_pump, model, heat_pump)
    [0.936, 0.936].each_with_index do |rated_airflow_ratio, i|
      assert_in_epsilon(rated_airflow_ratio, program_values['FF_AF_clg'][i], 0.01)
    end
    [0.71, 0.71].each_with_index do |rated_airflow_ratio, i|
      assert_in_epsilon(rated_airflow_ratio, program_values['FF_AF_htg'][i], 0.01)
    end

    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-install-quality-air-to-air-heat-pump-var-speed-detailed-performance.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    heat_pump = hpxml_bldg.heat_pumps[0]
    program_values = _check_install_quality_multispeed_ratio(heat_pump, model, heat_pump)
    [0.936, 0.936].each_with_index do |rated_airflow_ratio, i|
      assert_in_epsilon(rated_airflow_ratio, program_values['FF_AF_clg'][i], 0.01)
    end
    [0.71, 0.71].each_with_index do |rated_airflow_ratio, i|
      assert_in_epsilon(rated_airflow_ratio, program_values['FF_AF_htg'][i], 0.01)
    end
  end

  def test_install_quality_furnace_central_air_conditioner_1_speed
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-install-quality-furnace-gas-central-ac-1-speed.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    cooling_system = hpxml_bldg.cooling_systems[0]
    heating_system = hpxml_bldg.heating_systems[0]
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

  def test_install_quality_furnace_central_air_conditioner_2_speed
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-install-quality-furnace-gas-central-ac-2-speed.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    cooling_system = hpxml_bldg.cooling_systems[0]
    program_values = _check_install_quality_multispeed_ratio(cooling_system, model)
    [1.088, 1.088].each_with_index do |rated_airflow_ratio, i|
      assert_in_epsilon(rated_airflow_ratio, program_values['FF_AF_clg'][i])
    end
  end

  def test_install_quality_furnace_central_air_conditioner_var_speed
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-install-quality-furnace-gas-central-ac-var-speed.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    cooling_system = hpxml_bldg.cooling_systems[0]
    program_values = _check_install_quality_multispeed_ratio(cooling_system, model)
    [0.936, 0.936].each_with_index do |rated_airflow_ratio, i|
      assert_in_epsilon(rated_airflow_ratio, program_values['FF_AF_clg'][i])
    end
  end

  def test_install_quality_furnace_gas
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-install-quality-furnace-gas-only.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    heating_system = hpxml_bldg.heating_systems[0]
    fan_watts_cfm = heating_system.fan_watts_per_cfm

    assert_equal(1, model.getAirLoopHVACUnitarySystems.size)
    unitary_system = model.getAirLoopHVACUnitarySystems[0]

    # Fan
    fan = unitary_system.supplyFan.get.to_FanSystemModel.get
    assert_in_epsilon(fan_watts_cfm, fan.designPressureRise / fan.fanTotalEfficiency * UnitConversions.convert(1.0, 'cfm', 'm^3/s'), 0.01)
  end

  def test_install_quality_ground_to_air_heat_pump
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-install-quality-ground-to-air-heat-pump.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    heat_pump = hpxml_bldg.heat_pumps[0]
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

  def test_install_quality_mini_split_air_conditioner
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-install-quality-mini-split-air-conditioner-only-ducted.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    cooling_system = hpxml_bldg.cooling_systems[0]
    program_values = _check_install_quality_multispeed_ratio(cooling_system, model)
    [0.936, 0.936].each_with_index do |rated_airflow_ratio, i|
      assert_in_epsilon(rated_airflow_ratio, program_values['FF_AF_clg'][i])
    end
  end

  def test_install_quality_mini_split_heat_pump
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-install-quality-mini-split-heat-pump-ducted.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    heat_pump = hpxml_bldg.heat_pumps[0]
    program_values = _check_install_quality_multispeed_ratio(heat_pump, model, heat_pump)
    [0.936, 0.936].each_with_index do |rated_airflow_ratio, i|
      assert_in_epsilon(rated_airflow_ratio, program_values['FF_AF_clg'][i], 0.01)
    end
    [0.71, 0.71].each_with_index do |rated_airflow_ratio, i|
      assert_in_epsilon(rated_airflow_ratio, program_values['FF_AF_htg'][i], 0.01)
    end
  end

  def test_custom_seasons
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-seasons.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    hvac_control = hpxml_bldg.hvac_controls[0]
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
    args_hash['hpxml_path'] = @tmp_hpxml_path
    hpxml, hpxml_bldg = _create_hpxml('base.xml')
    hpxml_bldg.cooling_systems[0].crankcase_heater_watts = 40.0
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    cooling_system = hpxml_bldg.cooling_systems[0]
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

    return model, hpxml, hpxml.buildings[0]
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

    return program_values
  end

  def _create_hpxml(hpxml_name)
    hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, hpxml_name))
    return hpxml, hpxml.buildings[0]
  end
end
