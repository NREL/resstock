# frozen_string_literal: true

require_relative '../../HPXMLtoOpenStudio/resources/minitest_helper'
require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'minitest/autorun'
require 'fileutils'
require 'csv'
require_relative '../measure.rb'

class SimulationOutputReportTest < MiniTest::Test
  AnnualRows = [
    'Electricity: Total (MBtu)',
    'Electricity: Net (MBtu)',
    'Natural Gas: Total (MBtu)',
    'Fuel Oil: Total (MBtu)',
    'Propane: Total (MBtu)',
    'Wood Cord: Total (MBtu)',
    'Wood Pellets: Total (MBtu)',
    'Coal: Total (MBtu)',
    'Electricity: Heating (MBtu)',
    'Electricity: Heating Fans/Pumps (MBtu)',
    'Electricity: Cooling (MBtu)',
    'Electricity: Cooling Fans/Pumps (MBtu)',
    'Electricity: Hot Water (MBtu)',
    'Electricity: Hot Water Recirc Pump (MBtu)',
    'Electricity: Hot Water Solar Thermal Pump (MBtu)',
    'Electricity: Lighting Interior (MBtu)',
    'Electricity: Lighting Garage (MBtu)',
    'Electricity: Lighting Exterior (MBtu)',
    'Electricity: Mech Vent (MBtu)',
    'Electricity: Mech Vent Preheating (MBtu)',
    'Electricity: Mech Vent Precooling (MBtu)',
    'Electricity: Whole House Fan (MBtu)',
    'Electricity: Refrigerator (MBtu)',
    'Electricity: Freezer (MBtu)',
    'Electricity: Dehumidifier (MBtu)',
    'Electricity: Dishwasher (MBtu)',
    'Electricity: Clothes Washer (MBtu)',
    'Electricity: Clothes Dryer (MBtu)',
    'Electricity: Range/Oven (MBtu)',
    'Electricity: Ceiling Fan (MBtu)',
    'Electricity: Television (MBtu)',
    'Electricity: Plug Loads (MBtu)',
    'Electricity: Electric Vehicle Charging (MBtu)',
    'Electricity: Well Pump (MBtu)',
    'Electricity: Pool Heater (MBtu)',
    'Electricity: Pool Pump (MBtu)',
    'Electricity: Hot Tub Heater (MBtu)',
    'Electricity: Hot Tub Pump (MBtu)',
    'Electricity: PV (MBtu)',
    'Natural Gas: Heating (MBtu)',
    'Natural Gas: Hot Water (MBtu)',
    'Natural Gas: Clothes Dryer (MBtu)',
    'Natural Gas: Range/Oven (MBtu)',
    'Natural Gas: Pool Heater (MBtu)',
    'Natural Gas: Hot Tub Heater (MBtu)',
    'Natural Gas: Grill (MBtu)',
    'Natural Gas: Lighting (MBtu)',
    'Natural Gas: Fireplace (MBtu)',
    'Natural Gas: Mech Vent Preheating (MBtu)',
    'Fuel Oil: Heating (MBtu)',
    'Fuel Oil: Hot Water (MBtu)',
    'Fuel Oil: Clothes Dryer (MBtu)',
    'Fuel Oil: Range/Oven (MBtu)',
    'Fuel Oil: Grill (MBtu)',
    'Fuel Oil: Lighting (MBtu)',
    'Fuel Oil: Fireplace (MBtu)',
    'Fuel Oil: Mech Vent Preheating (MBtu)',
    'Propane: Heating (MBtu)',
    'Propane: Hot Water (MBtu)',
    'Propane: Clothes Dryer (MBtu)',
    'Propane: Range/Oven (MBtu)',
    'Propane: Grill (MBtu)',
    'Propane: Lighting (MBtu)',
    'Propane: Fireplace (MBtu)',
    'Propane: Mech Vent Preheating (MBtu)',
    'Wood Cord: Heating (MBtu)',
    'Wood Cord: Hot Water (MBtu)',
    'Wood Cord: Clothes Dryer (MBtu)',
    'Wood Cord: Range/Oven (MBtu)',
    'Wood Cord: Grill (MBtu)',
    'Wood Cord: Lighting (MBtu)',
    'Wood Cord: Fireplace (MBtu)',
    'Wood Cord: Mech Vent Preheating (MBtu)',
    'Wood Pellets: Heating (MBtu)',
    'Wood Pellets: Hot Water (MBtu)',
    'Wood Pellets: Clothes Dryer (MBtu)',
    'Wood Pellets: Range/Oven (MBtu)',
    'Wood Pellets: Grill (MBtu)',
    'Wood Pellets: Lighting (MBtu)',
    'Wood Pellets: Fireplace (MBtu)',
    'Wood Pellets: Mech Vent Preheating (MBtu)',
    'Coal: Heating (MBtu)',
    'Coal: Hot Water (MBtu)',
    'Coal: Clothes Dryer (MBtu)',
    'Coal: Range/Oven (MBtu)',
    'Coal: Grill (MBtu)',
    'Coal: Lighting (MBtu)',
    'Coal: Fireplace (MBtu)',
    'Coal: Mech Vent Preheating (MBtu)',
    'Load: Heating (MBtu)',
    'Load: Cooling (MBtu)',
    'Load: Hot Water: Delivered (MBtu)',
    'Load: Hot Water: Tank Losses (MBtu)',
    'Load: Hot Water: Desuperheater (MBtu)',
    'Load: Hot Water: Solar Thermal (MBtu)',
    'Unmet Load: Heating (MBtu)',
    'Unmet Load: Cooling (MBtu)',
    'Peak Electricity: Winter Total (W)',
    'Peak Electricity: Summer Total (W)',
    'Peak Load: Heating (kBtu)',
    'Peak Load: Cooling (kBtu)',
    'Component Load: Heating: Roofs (MBtu)',
    'Component Load: Heating: Ceilings (MBtu)',
    'Component Load: Heating: Walls (MBtu)',
    'Component Load: Heating: Rim Joists (MBtu)',
    'Component Load: Heating: Foundation Walls (MBtu)',
    'Component Load: Heating: Doors (MBtu)',
    'Component Load: Heating: Windows (MBtu)',
    'Component Load: Heating: Skylights (MBtu)',
    'Component Load: Heating: Floors (MBtu)',
    'Component Load: Heating: Slabs (MBtu)',
    'Component Load: Heating: Internal Mass (MBtu)',
    'Component Load: Heating: Infiltration (MBtu)',
    'Component Load: Heating: Natural Ventilation (MBtu)',
    'Component Load: Heating: Mechanical Ventilation (MBtu)',
    'Component Load: Heating: Whole House Fan (MBtu)',
    'Component Load: Heating: Ducts (MBtu)',
    'Component Load: Heating: Internal Gains (MBtu)',
    'Component Load: Cooling: Roofs (MBtu)',
    'Component Load: Cooling: Ceilings (MBtu)',
    'Component Load: Cooling: Walls (MBtu)',
    'Component Load: Cooling: Rim Joists (MBtu)',
    'Component Load: Cooling: Foundation Walls (MBtu)',
    'Component Load: Cooling: Doors (MBtu)',
    'Component Load: Cooling: Windows (MBtu)',
    'Component Load: Cooling: Skylights (MBtu)',
    'Component Load: Cooling: Floors (MBtu)',
    'Component Load: Cooling: Slabs (MBtu)',
    'Component Load: Cooling: Internal Mass (MBtu)',
    'Component Load: Cooling: Infiltration (MBtu)',
    'Component Load: Cooling: Natural Ventilation (MBtu)',
    'Component Load: Cooling: Mechanical Ventilation (MBtu)',
    'Component Load: Cooling: Whole House Fan (MBtu)',
    'Component Load: Cooling: Ducts (MBtu)',
    'Component Load: Cooling: Internal Gains (MBtu)',
    'Hot Water: Clothes Washer (gal)',
    'Hot Water: Dishwasher (gal)',
    'Hot Water: Fixtures (gal)',
    'Hot Water: Distribution Waste (gal)',
  ]

  TimeseriesColsFuels = [
    'Electricity: Total',
    'Natural Gas: Total',
    'Fuel Oil: Total',
    'Propane: Total',
    'Wood Cord: Total',
    'Wood Pellets: Total',
    'Coal: Total',
  ]

  TimeseriesColsEndUses = [
    'Electricity: Heating',
    'Electricity: Heating Fans/Pumps',
    'Electricity: Cooling',
    'Electricity: Cooling Fans/Pumps',
    'Electricity: Hot Water',
    'Electricity: Hot Water Recirc Pump',
    'Electricity: Hot Water Solar Thermal Pump',
    'Electricity: Lighting Interior',
    'Electricity: Lighting Garage',
    'Electricity: Lighting Exterior',
    'Electricity: Mech Vent',
    'Electricity: Whole House Fan',
    'Electricity: Refrigerator',
    'Electricity: Freezer',
    'Electricity: Dehumidifier',
    'Electricity: Dishwasher',
    'Electricity: Clothes Washer',
    'Electricity: Clothes Dryer',
    'Electricity: Range/Oven',
    'Electricity: Ceiling Fan',
    'Electricity: Television',
    'Electricity: Plug Loads',
    'Electricity: Electric Vehicle Charging',
    'Electricity: Well Pump',
    'Electricity: Pool Heater',
    'Electricity: Pool Pump',
    'Electricity: Hot Tub Heater',
    'Electricity: Hot Tub Pump',
    'Electricity: PV',
    'Natural Gas: Heating',
    'Natural Gas: Hot Water',
    'Natural Gas: Clothes Dryer',
    'Natural Gas: Range/Oven',
    'Natural Gas: Pool Heater',
    'Natural Gas: Hot Tub Heater',
    'Natural Gas: Grill',
    'Natural Gas: Lighting',
    'Natural Gas: Fireplace',
    'Fuel Oil: Heating',
    'Fuel Oil: Hot Water',
    'Fuel Oil: Clothes Dryer',
    'Fuel Oil: Range/Oven',
    'Fuel Oil: Grill',
    'Fuel Oil: Lighting',
    'Fuel Oil: Fireplace',
    'Propane: Heating',
    'Propane: Hot Water',
    'Propane: Clothes Dryer',
    'Propane: Range/Oven',
    'Propane: Grill',
    'Propane: Lighting',
    'Propane: Fireplace',
    'Wood Cord: Heating',
    'Wood Cord: Hot Water',
    'Wood Cord: Clothes Dryer',
    'Wood Cord: Range/Oven',
    'Wood Cord: Grill',
    'Wood Cord: Lighting',
    'Wood Cord: Fireplace',
    'Wood Pellets: Heating',
    'Wood Pellets: Hot Water',
    'Wood Pellets: Clothes Dryer',
    'Wood Pellets: Range/Oven',
    'Wood Pellets: Grill',
    'Wood Pellets: Lighting',
    'Wood Pellets: Fireplace',
    'Coal: Heating',
    'Coal: Hot Water',
    'Coal: Clothes Dryer',
    'Coal: Range/Oven',
    'Coal: Grill',
    'Coal: Lighting',
    'Coal: Fireplace',
  ]

  TimeseriesColsWaterUses = [
    'Hot Water: Clothes Washer',
    'Hot Water: Dishwasher',
    'Hot Water: Fixtures',
    'Hot Water: Distribution Waste',
  ]

  TimeseriesColsTotalLoads = [
    'Load: Heating',
    'Load: Cooling',
  ]

  TimeseriesColsComponentLoads = [
    'Component Load: Heating: Roofs',
    'Component Load: Heating: Ceilings',
    'Component Load: Heating: Walls',
    'Component Load: Heating: Rim Joists',
    'Component Load: Heating: Foundation Walls',
    'Component Load: Heating: Doors',
    'Component Load: Heating: Windows',
    'Component Load: Heating: Skylights',
    'Component Load: Heating: Floors',
    'Component Load: Heating: Slabs',
    'Component Load: Heating: Internal Mass',
    'Component Load: Heating: Infiltration',
    'Component Load: Heating: Natural Ventilation',
    'Component Load: Heating: Mechanical Ventilation',
    'Component Load: Heating: Whole House Fan',
    'Component Load: Heating: Ducts',
    'Component Load: Heating: Internal Gains',
    'Component Load: Cooling: Roofs',
    'Component Load: Cooling: Ceilings',
    'Component Load: Cooling: Walls',
    'Component Load: Cooling: Rim Joists',
    'Component Load: Cooling: Foundation Walls',
    'Component Load: Cooling: Doors',
    'Component Load: Cooling: Windows',
    'Component Load: Cooling: Skylights',
    'Component Load: Cooling: Floors',
    'Component Load: Cooling: Slabs',
    'Component Load: Cooling: Internal Mass',
    'Component Load: Cooling: Infiltration',
    'Component Load: Cooling: Natural Ventilation',
    'Component Load: Cooling: Mechanical Ventilation',
    'Component Load: Cooling: Whole House Fan',
    'Component Load: Cooling: Ducts',
    'Component Load: Cooling: Internal Gains',
  ]

  TimeseriesColsZoneTemps = [
    'Temperature: Attic - Unvented',
    'Temperature: Living Space',
  ]

  TimeseriesColsTempsOtherSide = [
    'Temperature: Other Multifamily Buffer Space',
    'Temperature: Other Non-freezing Space',
    'Temperature: Other Housing Unit',
    'Temperature: Other Heated Space'
  ]

  TimeseriesColsAirflows = [
    'Airflow: Infiltration',
    'Airflow: Mechanical Ventilation',
    'Airflow: Natural Ventilation',
    'Airflow: Whole House Fan',
  ]

  TimeseriesColsWeather = [
    'Weather: Drybulb Temperature',
    'Weather: Wetbulb Temperature',
    'Weather: Relative Humidity',
    'Weather: Wind Speed',
    'Weather: Diffuse Solar Radiation',
    'Weather: Direct Solar Radiation',
  ]

  ERIRows = [
    'hpxml_heat_sys_ids',
    'hpxml_cool_sys_ids',
    'hpxml_dhw_sys_ids',
    'hpxml_vent_preheat_sys_ids',
    'hpxml_vent_precool_sys_ids',
    'hpxml_eec_heats',
    'hpxml_eec_cools',
    'hpxml_eec_dhws',
    'hpxml_eec_vent_preheats',
    'hpxml_eec_vent_precools',
    'hpxml_heat_fuels',
    'hpxml_dwh_fuels',
    'hpxml_vent_preheat_fuels',
    'fuelElectricity',
    'fuelNaturalGas',
    'fuelFuelOil',
    'fuelPropane',
    'fuelWoodCord',
    'fuelWoodPellets',
    'fuelCoal',
    'enduseElectricityHeating',
    'enduseElectricityHeatingFansPumps',
    'enduseElectricityCooling',
    'enduseElectricityCoolingFansPumps',
    'enduseElectricityHotWater',
    'enduseElectricityHotWaterRecircPump',
    'enduseElectricityHotWaterSolarThermalPump',
    'enduseElectricityLightingInterior',
    'enduseElectricityLightingGarage',
    'enduseElectricityLightingExterior',
    'enduseElectricityMechVent',
    'enduseElectricityMechVentPreheating',
    'enduseElectricityMechVentPrecooling',
    'enduseElectricityWholeHouseFan',
    'enduseElectricityRefrigerator',
    'enduseElectricityDehumidifier',
    'enduseElectricityDishwasher',
    'enduseElectricityClothesWasher',
    'enduseElectricityClothesDryer',
    'enduseElectricityRangeOven',
    'enduseElectricityCeilingFan',
    'enduseElectricityTelevision',
    'enduseElectricityPlugLoads',
    'enduseElectricityPV',
    'enduseNaturalGasHeating',
    'enduseNaturalGasHotWater',
    'enduseNaturalGasClothesDryer',
    'enduseNaturalGasRangeOven',
    'enduseNaturalGasMechVentPreheating',
    'enduseFuelOilHeating',
    'enduseFuelOilHotWater',
    'enduseFuelOilClothesDryer',
    'enduseFuelOilRangeOven',
    'enduseFuelOilMechVentPreheating',
    'endusePropaneHeating',
    'endusePropaneHotWater',
    'endusePropaneClothesDryer',
    'endusePropaneRangeOven',
    'endusePropaneMechVentPreheating',
    'enduseWoodCordHeating',
    'enduseWoodCordHotWater',
    'enduseWoodCordClothesDryer',
    'enduseWoodCordRangeOven',
    'enduseWoodCordMechVentPreheating',
    'enduseWoodPelletsHeating',
    'enduseWoodPelletsHotWater',
    'enduseWoodPelletsClothesDryer',
    'enduseWoodPelletsRangeOven',
    'enduseWoodPelletsMechVentPreheating',
    'enduseCoalHeating',
    'enduseCoalHotWater',
    'enduseCoalClothesDryer',
    'enduseCoalRangeOven',
    'enduseCoalMechVentPreheating',
    'loadHeating',
    'loadCooling',
    'loadHotWaterDelivered',
    'hpxml_cfa',
    'hpxml_nbr',
    'hpxml_nst',
  ]

  def all_timeseries_cols
    return (TimeseriesColsFuels +
            TimeseriesColsEndUses +
            TimeseriesColsWaterUses +
            TimeseriesColsTotalLoads +
            TimeseriesColsComponentLoads +
            TimeseriesColsZoneTemps +
            TimeseriesColsAirflows +
            TimeseriesColsWeather)
  end

  def test_annual_only
    args_hash = { 'hpxml_path' => '../workflow/sample_files/base.xml',
                  'timeseries_frequency' => 'hourly',
                  'include_timeseries_fuel_consumptions' => false,
                  'include_timeseries_end_use_consumptions' => false,
                  'include_timeseries_hot_water_uses' => false,
                  'include_timeseries_total_loads' => false,
                  'include_timeseries_component_loads' => false,
                  'include_timeseries_zone_temperatures' => false,
                  'include_timeseries_airflows' => false,
                  'include_timeseries_weather' => false }
    annual_csv, timeseries_csv, eri_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(!File.exist?(timeseries_csv))
    expected_annual_rows = AnnualRows
    actual_annual_rows = File.readlines(annual_csv).map { |x| x.split(',')[0].strip }.select { |x| !x.empty? }
    assert_equal(expected_annual_rows.sort, actual_annual_rows.sort)
  end

  def test_annual_only2
    args_hash = { 'hpxml_path' => '../workflow/sample_files/base.xml',
                  'timeseries_frequency' => 'none',
                  'include_timeseries_fuel_consumptions' => true,
                  'include_timeseries_end_use_consumptions' => true,
                  'include_timeseries_hot_water_uses' => true,
                  'include_timeseries_total_loads' => true,
                  'include_timeseries_component_loads' => true,
                  'include_timeseries_zone_temperatures' => true,
                  'include_timeseries_airflows' => true,
                  'include_timeseries_weather' => true }
    annual_csv, timeseries_csv, eri_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(!File.exist?(timeseries_csv))
    expected_annual_rows = AnnualRows
    actual_annual_rows = File.readlines(annual_csv).map { |x| x.split(',')[0].strip }.select { |x| !x.empty? }
    assert_equal(expected_annual_rows.sort, actual_annual_rows.sort)
  end

  def test_timeseries_hourly_fuels
    args_hash = { 'hpxml_path' => '../workflow/sample_files/base.xml',
                  'timeseries_frequency' => 'hourly',
                  'include_timeseries_fuel_consumptions' => true,
                  'include_timeseries_end_use_consumptions' => false,
                  'include_timeseries_hot_water_uses' => false,
                  'include_timeseries_total_loads' => false,
                  'include_timeseries_component_loads' => false,
                  'include_timeseries_zone_temperatures' => false,
                  'include_timeseries_airflows' => false,
                  'include_timeseries_weather' => false }
    annual_csv, timeseries_csv, eri_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    expected_timeseries_cols = ['Time'] + TimeseriesColsFuels
    actual_timeseries_cols = File.readlines(timeseries_csv)[0].strip.split(',')
    assert_equal(expected_timeseries_cols.sort, actual_timeseries_cols.sort)
    assert_equal(8760, File.readlines(timeseries_csv).size - 2)
    _check_for_nonzero_timeseries_value(timeseries_csv, ['Electricity: Total'])
  end

  def test_timeseries_hourly_enduses
    args_hash = { 'hpxml_path' => '../workflow/sample_files/base.xml',
                  'timeseries_frequency' => 'hourly',
                  'include_timeseries_fuel_consumptions' => false,
                  'include_timeseries_end_use_consumptions' => true,
                  'include_timeseries_hot_water_uses' => false,
                  'include_timeseries_total_loads' => false,
                  'include_timeseries_component_loads' => false,
                  'include_timeseries_zone_temperatures' => false,
                  'include_timeseries_airflows' => false,
                  'include_timeseries_weather' => false }
    annual_csv, timeseries_csv, eri_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    expected_timeseries_cols = ['Time'] + TimeseriesColsEndUses
    actual_timeseries_cols = File.readlines(timeseries_csv)[0].strip.split(',')
    assert_equal(expected_timeseries_cols.sort, actual_timeseries_cols.sort)
    assert_equal(8760, File.readlines(timeseries_csv).size - 2)
    _check_for_nonzero_timeseries_value(timeseries_csv, ['Electricity: Plug Loads'])
  end

  def test_timeseries_hourly_hotwateruses
    args_hash = { 'hpxml_path' => '../workflow/sample_files/base.xml',
                  'timeseries_frequency' => 'hourly',
                  'include_timeseries_fuel_consumptions' => false,
                  'include_timeseries_end_use_consumptions' => false,
                  'include_timeseries_hot_water_uses' => true,
                  'include_timeseries_total_loads' => false,
                  'include_timeseries_component_loads' => false,
                  'include_timeseries_zone_temperatures' => false,
                  'include_timeseries_airflows' => false,
                  'include_timeseries_weather' => false }
    annual_csv, timeseries_csv, eri_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    expected_timeseries_cols = ['Time'] + TimeseriesColsWaterUses
    actual_timeseries_cols = File.readlines(timeseries_csv)[0].strip.split(',')
    assert_equal(expected_timeseries_cols.sort, actual_timeseries_cols.sort)
    assert_equal(8760, File.readlines(timeseries_csv).size - 2)
    _check_for_nonzero_timeseries_value(timeseries_csv, TimeseriesColsWaterUses)
  end

  def test_timeseries_hourly_loads
    args_hash = { 'hpxml_path' => '../workflow/sample_files/base.xml',
                  'timeseries_frequency' => 'hourly',
                  'include_timeseries_fuel_consumptions' => false,
                  'include_timeseries_end_use_consumptions' => false,
                  'include_timeseries_hot_water_uses' => false,
                  'include_timeseries_total_loads' => true,
                  'include_timeseries_component_loads' => false,
                  'include_timeseries_zone_temperatures' => false,
                  'include_timeseries_airflows' => false,
                  'include_timeseries_weather' => false }
    annual_csv, timeseries_csv, eri_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    expected_timeseries_cols = ['Time'] + TimeseriesColsTotalLoads
    actual_timeseries_cols = File.readlines(timeseries_csv)[0].strip.split(',')
    assert_equal(expected_timeseries_cols.sort, actual_timeseries_cols.sort)
    assert_equal(8760, File.readlines(timeseries_csv).size - 2)
    _check_for_nonzero_timeseries_value(timeseries_csv, TimeseriesColsTotalLoads)
  end

  def test_timeseries_hourly_componentloads
    args_hash = { 'hpxml_path' => '../workflow/sample_files/base.xml',
                  'timeseries_frequency' => 'hourly',
                  'include_timeseries_fuel_consumptions' => false,
                  'include_timeseries_end_use_consumptions' => false,
                  'include_timeseries_hot_water_uses' => false,
                  'include_timeseries_total_loads' => false,
                  'include_timeseries_component_loads' => true,
                  'include_timeseries_zone_temperatures' => false,
                  'include_timeseries_airflows' => false,
                  'include_timeseries_weather' => false }
    annual_csv, timeseries_csv, eri_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    expected_timeseries_cols = ['Time'] + TimeseriesColsComponentLoads
    actual_timeseries_cols = File.readlines(timeseries_csv)[0].strip.split(',')
    assert_equal(expected_timeseries_cols.sort, actual_timeseries_cols.sort)
    assert_equal(8760, File.readlines(timeseries_csv).size - 2)
    _check_for_nonzero_timeseries_value(timeseries_csv, ['Component Load: Heating: Internal Gains', 'Component Load: Cooling: Internal Gains'])
  end

  def test_timeseries_hourly_zone_temperatures
    args_hash = { 'hpxml_path' => '../workflow/sample_files/base.xml',
                  'timeseries_frequency' => 'hourly',
                  'include_timeseries_fuel_consumptions' => false,
                  'include_timeseries_end_use_consumptions' => false,
                  'include_timeseries_hot_water_uses' => false,
                  'include_timeseries_total_loads' => false,
                  'include_timeseries_component_loads' => false,
                  'include_timeseries_zone_temperatures' => true,
                  'include_timeseries_airflows' => false,
                  'include_timeseries_weather' => false }
    annual_csv, timeseries_csv, eri_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    expected_timeseries_cols = ['Time'] + TimeseriesColsZoneTemps
    actual_timeseries_cols = File.readlines(timeseries_csv)[0].strip.split(',')
    assert_equal(expected_timeseries_cols.sort, actual_timeseries_cols.sort)
    assert_equal(8760, File.readlines(timeseries_csv).size - 2)
    _check_for_nonzero_timeseries_value(timeseries_csv, TimeseriesColsZoneTemps)
  end

  def test_timeseries_hourly_zone_temperatures_mf_space
    args_hash = { 'hpxml_path' => '../workflow/sample_files/base-enclosure-attached-multifamily.xml',
                  'timeseries_frequency' => 'hourly',
                  'include_timeseries_fuel_consumptions' => false,
                  'include_timeseries_end_use_consumptions' => false,
                  'include_timeseries_hot_water_uses' => false,
                  'include_timeseries_total_loads' => false,
                  'include_timeseries_component_loads' => false,
                  'include_timeseries_zone_temperatures' => true,
                  'include_timeseries_airflows' => false,
                  'include_timeseries_weather' => false }
    annual_csv, timeseries_csv, eri_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    expected_timeseries_cols = ['Time'] + TimeseriesColsZoneTemps + TimeseriesColsTempsOtherSide
    actual_timeseries_cols = File.readlines(timeseries_csv)[0].strip.split(',')
    assert_equal(expected_timeseries_cols.sort, actual_timeseries_cols.sort)
    assert_equal(8760, File.readlines(timeseries_csv).size - 2)
    _check_for_nonzero_timeseries_value(timeseries_csv, TimeseriesColsTempsOtherSide)
  end

  def test_timeseries_hourly_airflows
    args_hash = { 'hpxml_path' => '../workflow/sample_files/base-mechvent-exhaust.xml',
                  'timeseries_frequency' => 'hourly',
                  'include_timeseries_fuel_consumptions' => false,
                  'include_timeseries_end_use_consumptions' => false,
                  'include_timeseries_hot_water_uses' => false,
                  'include_timeseries_total_loads' => false,
                  'include_timeseries_component_loads' => false,
                  'include_timeseries_zone_temperatures' => false,
                  'include_timeseries_airflows' => true,
                  'include_timeseries_weather' => false }
    annual_csv, timeseries_csv, eri_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    expected_timeseries_cols = ['Time'] + TimeseriesColsAirflows
    actual_timeseries_cols = File.readlines(timeseries_csv)[0].strip.split(',')
    assert_equal(expected_timeseries_cols.sort, actual_timeseries_cols.sort)
    assert_equal(8760, File.readlines(timeseries_csv).size - 2)
    _check_for_nonzero_timeseries_value(timeseries_csv, TimeseriesColsAirflows.select { |t| t != 'Airflow: Whole House Fan' })
  end

  def test_timeseries_hourly_airflows_with_whf
    args_hash = { 'hpxml_path' => '../workflow/sample_files/base-mechvent-whole-house-fan.xml',
                  'timeseries_frequency' => 'hourly',
                  'include_timeseries_fuel_consumptions' => false,
                  'include_timeseries_end_use_consumptions' => false,
                  'include_timeseries_hot_water_uses' => false,
                  'include_timeseries_total_loads' => false,
                  'include_timeseries_component_loads' => false,
                  'include_timeseries_zone_temperatures' => false,
                  'include_timeseries_airflows' => true,
                  'include_timeseries_weather' => false }
    annual_csv, timeseries_csv, eri_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    expected_timeseries_cols = ['Time'] + TimeseriesColsAirflows
    actual_timeseries_cols = File.readlines(timeseries_csv)[0].strip.split(',')
    assert_equal(expected_timeseries_cols.sort, actual_timeseries_cols.sort)
    assert_equal(8760, File.readlines(timeseries_csv).size - 2)
    _check_for_nonzero_timeseries_value(timeseries_csv, ['Airflow: Whole House Fan'])
  end

  def test_timeseries_hourly_airflows_with_clothes_dryer_exhaust
    args_hash = { 'hpxml_path' => '../workflow/sample_files/base-appliances-gas.xml',
                  'timeseries_frequency' => 'hourly',
                  'include_timeseries_fuel_consumptions' => false,
                  'include_timeseries_end_use_consumptions' => false,
                  'include_timeseries_hot_water_uses' => false,
                  'include_timeseries_total_loads' => false,
                  'include_timeseries_component_loads' => false,
                  'include_timeseries_zone_temperatures' => false,
                  'include_timeseries_airflows' => true,
                  'include_timeseries_weather' => false }
    annual_csv, timeseries_csv, eri_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    expected_timeseries_cols = ['Time'] + TimeseriesColsAirflows
    actual_timeseries_cols = File.readlines(timeseries_csv)[0].strip.split(',')
    assert_equal(expected_timeseries_cols.sort, actual_timeseries_cols.sort)
    assert_equal(8760, File.readlines(timeseries_csv).size - 2)
    _check_for_nonzero_timeseries_value(timeseries_csv, ['Airflow: Mechanical Ventilation'])
  end

  def test_timeseries_hourly_airflows_with_balanced_mechvent
    args_hash = { 'hpxml_path' => '../workflow/sample_files/base-mechvent-balanced.xml',
                  'timeseries_frequency' => 'hourly',
                  'include_timeseries_fuel_consumptions' => false,
                  'include_timeseries_end_use_consumptions' => false,
                  'include_timeseries_hot_water_uses' => false,
                  'include_timeseries_total_loads' => false,
                  'include_timeseries_component_loads' => false,
                  'include_timeseries_zone_temperatures' => false,
                  'include_timeseries_airflows' => true,
                  'include_timeseries_weather' => false }
    annual_csv, timeseries_csv, eri_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    expected_timeseries_cols = ['Time'] + TimeseriesColsAirflows
    actual_timeseries_cols = File.readlines(timeseries_csv)[0].strip.split(',')
    assert_equal(expected_timeseries_cols.sort, actual_timeseries_cols.sort)
    assert_equal(8760, File.readlines(timeseries_csv).size - 2)
    _check_for_nonzero_timeseries_value(timeseries_csv, ['Airflow: Mechanical Ventilation'])
  end

  def test_timeseries_hourly_airflows_with_cfis
    args_hash = { 'hpxml_path' => '../workflow/sample_files/base-mechvent-cfis.xml',
                  'timeseries_frequency' => 'hourly',
                  'include_timeseries_fuel_consumptions' => false,
                  'include_timeseries_end_use_consumptions' => false,
                  'include_timeseries_hot_water_uses' => false,
                  'include_timeseries_total_loads' => false,
                  'include_timeseries_component_loads' => false,
                  'include_timeseries_zone_temperatures' => false,
                  'include_timeseries_airflows' => true,
                  'include_timeseries_weather' => false }
    annual_csv, timeseries_csv, eri_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    expected_timeseries_cols = ['Time'] + TimeseriesColsAirflows
    actual_timeseries_cols = File.readlines(timeseries_csv)[0].strip.split(',')
    assert_equal(expected_timeseries_cols.sort, actual_timeseries_cols.sort)
    assert_equal(8760, File.readlines(timeseries_csv).size - 2)
    _check_for_nonzero_timeseries_value(timeseries_csv, ['Airflow: Mechanical Ventilation'])
  end

  def test_timeseries_hourly_weather
    args_hash = { 'hpxml_path' => '../workflow/sample_files/base.xml',
                  'timeseries_frequency' => 'hourly',
                  'include_timeseries_fuel_consumptions' => false,
                  'include_timeseries_end_use_consumptions' => false,
                  'include_timeseries_hot_water_uses' => false,
                  'include_timeseries_total_loads' => false,
                  'include_timeseries_component_loads' => false,
                  'include_timeseries_zone_temperatures' => false,
                  'include_timeseries_airflows' => false,
                  'include_timeseries_weather' => true }
    annual_csv, timeseries_csv, eri_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    expected_timeseries_cols = ['Time'] + TimeseriesColsWeather
    actual_timeseries_cols = File.readlines(timeseries_csv)[0].strip.split(',')
    assert_equal(expected_timeseries_cols.sort, actual_timeseries_cols.sort)
    assert_equal(8760, File.readlines(timeseries_csv).size - 2)
    _check_for_nonzero_timeseries_value(timeseries_csv, TimeseriesColsWeather)
  end

  def test_timeseries_hourly_ALL
    args_hash = { 'hpxml_path' => '../workflow/sample_files/base.xml',
                  'timeseries_frequency' => 'hourly',
                  'include_timeseries_fuel_consumptions' => true,
                  'include_timeseries_end_use_consumptions' => true,
                  'include_timeseries_hot_water_uses' => true,
                  'include_timeseries_total_loads' => true,
                  'include_timeseries_component_loads' => true,
                  'include_timeseries_zone_temperatures' => true,
                  'include_timeseries_airflows' => true,
                  'include_timeseries_weather' => true }
    annual_csv, timeseries_csv, eri_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    expected_timeseries_cols = ['Time'] + all_timeseries_cols
    actual_timeseries_cols = File.readlines(timeseries_csv)[0].strip.split(',')
    assert_equal(expected_timeseries_cols.sort, actual_timeseries_cols.sort)
    assert_equal(8760, File.readlines(timeseries_csv).size - 2)
    _check_for_zero_baseload_timeseries_value(timeseries_csv, ['Electricity: Refrigerator'])
  end

  def test_timeseries_daily_ALL
    args_hash = { 'hpxml_path' => '../workflow/sample_files/base.xml',
                  'timeseries_frequency' => 'daily',
                  'include_timeseries_fuel_consumptions' => true,
                  'include_timeseries_end_use_consumptions' => true,
                  'include_timeseries_hot_water_uses' => true,
                  'include_timeseries_total_loads' => true,
                  'include_timeseries_component_loads' => true,
                  'include_timeseries_zone_temperatures' => true,
                  'include_timeseries_airflows' => true,
                  'include_timeseries_weather' => true }
    annual_csv, timeseries_csv, eri_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    expected_timeseries_cols = ['Time'] + all_timeseries_cols
    actual_timeseries_cols = File.readlines(timeseries_csv)[0].strip.split(',')
    assert_equal(expected_timeseries_cols.sort, actual_timeseries_cols.sort)
    assert_equal(365, File.readlines(timeseries_csv).size - 2)
    _check_for_zero_baseload_timeseries_value(timeseries_csv, ['Electricity: Refrigerator'])
  end

  def test_timeseries_monthly_ALL
    args_hash = { 'hpxml_path' => '../workflow/sample_files/base.xml',
                  'timeseries_frequency' => 'monthly',
                  'include_timeseries_fuel_consumptions' => true,
                  'include_timeseries_end_use_consumptions' => true,
                  'include_timeseries_hot_water_uses' => true,
                  'include_timeseries_total_loads' => true,
                  'include_timeseries_component_loads' => true,
                  'include_timeseries_zone_temperatures' => true,
                  'include_timeseries_airflows' => true,
                  'include_timeseries_weather' => true }
    annual_csv, timeseries_csv, eri_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    expected_timeseries_cols = ['Time'] + all_timeseries_cols
    actual_timeseries_cols = File.readlines(timeseries_csv)[0].strip.split(',')
    assert_equal(expected_timeseries_cols.sort, actual_timeseries_cols.sort)
    assert_equal(12, File.readlines(timeseries_csv).size - 2)
    _check_for_zero_baseload_timeseries_value(timeseries_csv, ['Electricity: Refrigerator'])
  end

  def test_timeseries_timestep_ALL_60min
    args_hash = { 'hpxml_path' => '../workflow/sample_files/base.xml',
                  'timeseries_frequency' => 'timestep',
                  'include_timeseries_fuel_consumptions' => true,
                  'include_timeseries_end_use_consumptions' => true,
                  'include_timeseries_hot_water_uses' => true,
                  'include_timeseries_total_loads' => true,
                  'include_timeseries_component_loads' => true,
                  'include_timeseries_zone_temperatures' => true,
                  'include_timeseries_airflows' => true,
                  'include_timeseries_weather' => true }
    annual_csv, timeseries_csv, eri_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    expected_timeseries_cols = ['Time'] + all_timeseries_cols
    actual_timeseries_cols = File.readlines(timeseries_csv)[0].strip.split(',')
    assert_equal(expected_timeseries_cols.sort, actual_timeseries_cols.sort)
    assert_equal(8760, File.readlines(timeseries_csv).size - 2)
    _check_for_zero_baseload_timeseries_value(timeseries_csv, ['Electricity: Refrigerator'])
  end

  def test_timeseries_timestep_ALL_10min
    args_hash = { 'hpxml_path' => '../workflow/sample_files/base-simcontrol-timestep-10-mins.xml',
                  'timeseries_frequency' => 'timestep',
                  'include_timeseries_fuel_consumptions' => true,
                  'include_timeseries_end_use_consumptions' => true,
                  'include_timeseries_hot_water_uses' => true,
                  'include_timeseries_total_loads' => true,
                  'include_timeseries_component_loads' => true,
                  'include_timeseries_zone_temperatures' => true,
                  'include_timeseries_airflows' => true,
                  'include_timeseries_weather' => true }
    annual_csv, timeseries_csv, eri_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    expected_timeseries_cols = ['Time'] + all_timeseries_cols
    actual_timeseries_cols = File.readlines(timeseries_csv)[0].strip.split(',')
    assert_equal(expected_timeseries_cols.sort, actual_timeseries_cols.sort)
    assert_equal(52560, File.readlines(timeseries_csv).size - 2)
    _check_for_zero_baseload_timeseries_value(timeseries_csv, ['Electricity: Refrigerator'])
  end

  def test_timeseries_hourly_ALL_runperiod_Jan
    args_hash = { 'hpxml_path' => '../workflow/sample_files/base-simcontrol-runperiod-1-month.xml',
                  'timeseries_frequency' => 'hourly',
                  'include_timeseries_fuel_consumptions' => true,
                  'include_timeseries_end_use_consumptions' => true,
                  'include_timeseries_hot_water_uses' => true,
                  'include_timeseries_total_loads' => true,
                  'include_timeseries_component_loads' => true,
                  'include_timeseries_zone_temperatures' => true,
                  'include_timeseries_airflows' => true,
                  'include_timeseries_weather' => true }
    annual_csv, timeseries_csv, eri_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    expected_timeseries_cols = ['Time'] + all_timeseries_cols
    actual_timeseries_cols = File.readlines(timeseries_csv)[0].strip.split(',')
    assert_equal(expected_timeseries_cols.sort, actual_timeseries_cols.sort)
    assert_equal(31 * 24, File.readlines(timeseries_csv).size - 2)
    _check_for_zero_baseload_timeseries_value(timeseries_csv, ['Electricity: Refrigerator'])
  end

  def test_timeseries_daily_ALL_runperiod_Jan
    args_hash = { 'hpxml_path' => '../workflow/sample_files/base-simcontrol-runperiod-1-month.xml',
                  'timeseries_frequency' => 'daily',
                  'include_timeseries_fuel_consumptions' => true,
                  'include_timeseries_end_use_consumptions' => true,
                  'include_timeseries_hot_water_uses' => true,
                  'include_timeseries_total_loads' => true,
                  'include_timeseries_component_loads' => true,
                  'include_timeseries_zone_temperatures' => true,
                  'include_timeseries_airflows' => true,
                  'include_timeseries_weather' => true }
    annual_csv, timeseries_csv, eri_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    expected_timeseries_cols = ['Time'] + all_timeseries_cols
    actual_timeseries_cols = File.readlines(timeseries_csv)[0].strip.split(',')
    assert_equal(expected_timeseries_cols.sort, actual_timeseries_cols.sort)
    assert_equal(31, File.readlines(timeseries_csv).size - 2)
    _check_for_zero_baseload_timeseries_value(timeseries_csv, ['Electricity: Refrigerator'])
  end

  def test_timeseries_monthly_ALL_runperiod_Jan
    args_hash = { 'hpxml_path' => '../workflow/sample_files/base-simcontrol-runperiod-1-month.xml',
                  'timeseries_frequency' => 'monthly',
                  'include_timeseries_fuel_consumptions' => true,
                  'include_timeseries_end_use_consumptions' => true,
                  'include_timeseries_hot_water_uses' => true,
                  'include_timeseries_total_loads' => true,
                  'include_timeseries_component_loads' => true,
                  'include_timeseries_zone_temperatures' => true,
                  'include_timeseries_airflows' => true,
                  'include_timeseries_weather' => true }
    annual_csv, timeseries_csv, eri_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    expected_timeseries_cols = ['Time'] + all_timeseries_cols
    actual_timeseries_cols = File.readlines(timeseries_csv)[0].strip.split(',')
    assert_equal(expected_timeseries_cols.sort, actual_timeseries_cols.sort)
    assert_equal(1, File.readlines(timeseries_csv).size - 2)
    _check_for_zero_baseload_timeseries_value(timeseries_csv, ['Electricity: Refrigerator'])
  end

  def test_timeseries_timestep_ALL_60min_runperiod_Jan
    args_hash = { 'hpxml_path' => '../workflow/sample_files/base-simcontrol-runperiod-1-month.xml',
                  'timeseries_frequency' => 'timestep',
                  'include_timeseries_fuel_consumptions' => true,
                  'include_timeseries_end_use_consumptions' => true,
                  'include_timeseries_hot_water_uses' => true,
                  'include_timeseries_total_loads' => true,
                  'include_timeseries_component_loads' => true,
                  'include_timeseries_zone_temperatures' => true,
                  'include_timeseries_airflows' => true,
                  'include_timeseries_weather' => true }
    annual_csv, timeseries_csv, eri_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    expected_timeseries_cols = ['Time'] + all_timeseries_cols
    actual_timeseries_cols = File.readlines(timeseries_csv)[0].strip.split(',')
    assert_equal(expected_timeseries_cols.sort, actual_timeseries_cols.sort)
    assert_equal(31 * 24, File.readlines(timeseries_csv).size - 2)
    _check_for_zero_baseload_timeseries_value(timeseries_csv, ['Electricity: Refrigerator'])
  end

  def test_timeseries_hourly_ALL_AMY_2012
    args_hash = { 'hpxml_path' => '../workflow/sample_files/base-location-AMY-2012.xml',
                  'timeseries_frequency' => 'hourly',
                  'include_timeseries_fuel_consumptions' => true,
                  'include_timeseries_end_use_consumptions' => true,
                  'include_timeseries_hot_water_uses' => true,
                  'include_timeseries_total_loads' => true,
                  'include_timeseries_component_loads' => true,
                  'include_timeseries_zone_temperatures' => true,
                  'include_timeseries_airflows' => true,
                  'include_timeseries_weather' => true }
    annual_csv, timeseries_csv, eri_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    expected_timeseries_cols = ['Time'] + all_timeseries_cols
    actual_timeseries_cols = File.readlines(timeseries_csv)[0].strip.split(',')
    assert_equal(expected_timeseries_cols.sort, actual_timeseries_cols.sort)
    assert_equal(8784, File.readlines(timeseries_csv).size - 2)
    _check_for_zero_baseload_timeseries_value(timeseries_csv, ['Electricity: Refrigerator'])
  end

  def test_timeseries_daily_ALL_AMY_2012
    args_hash = { 'hpxml_path' => '../workflow/sample_files/base-location-AMY-2012.xml',
                  'timeseries_frequency' => 'daily',
                  'include_timeseries_fuel_consumptions' => true,
                  'include_timeseries_end_use_consumptions' => true,
                  'include_timeseries_hot_water_uses' => true,
                  'include_timeseries_total_loads' => true,
                  'include_timeseries_component_loads' => true,
                  'include_timeseries_zone_temperatures' => true,
                  'include_timeseries_airflows' => true,
                  'include_timeseries_weather' => true }
    annual_csv, timeseries_csv, eri_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    expected_timeseries_cols = ['Time'] + all_timeseries_cols
    actual_timeseries_cols = File.readlines(timeseries_csv)[0].strip.split(',')
    assert_equal(expected_timeseries_cols.sort, actual_timeseries_cols.sort)
    assert_equal(366, File.readlines(timeseries_csv).size - 2)
    _check_for_zero_baseload_timeseries_value(timeseries_csv, ['Electricity: Refrigerator'])
  end

  def test_timeseries_timestep_ALL_60min_AMY_2012
    args_hash = { 'hpxml_path' => '../workflow/sample_files/base-location-AMY-2012.xml',
                  'timeseries_frequency' => 'timestep',
                  'include_timeseries_fuel_consumptions' => true,
                  'include_timeseries_end_use_consumptions' => true,
                  'include_timeseries_hot_water_uses' => true,
                  'include_timeseries_total_loads' => true,
                  'include_timeseries_component_loads' => true,
                  'include_timeseries_zone_temperatures' => true,
                  'include_timeseries_airflows' => true,
                  'include_timeseries_weather' => true }
    annual_csv, timeseries_csv, eri_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    expected_timeseries_cols = ['Time'] + all_timeseries_cols
    actual_timeseries_cols = File.readlines(timeseries_csv)[0].strip.split(',')
    assert_equal(expected_timeseries_cols.sort, actual_timeseries_cols.sort)
    assert_equal(8784, File.readlines(timeseries_csv).size - 2)
    _check_for_zero_baseload_timeseries_value(timeseries_csv, ['Electricity: Refrigerator'])
  end

  def test_eri_designs
    # Create derivative HPXML file w/ ERI design type set
    require 'fileutils'
    require_relative '../../HPXMLtoOpenStudio/resources/xmlhelper.rb'
    require_relative '../../HPXMLtoOpenStudio/resources/constants.rb'
    require 'oga'
    old_hpxml_path = File.join(File.dirname(__FILE__), '../../workflow/sample_files/base.xml')
    [Constants.CalcTypeERIReferenceHome, Constants.CalcTypeERIReferenceHome].each do |eri_design|
      new_hpxml_path = File.join(File.dirname(__FILE__), '../../workflow/sample_files/base-eri.xml')
      FileUtils.cp(old_hpxml_path, new_hpxml_path)
      hpxml = HPXML.new(hpxml_path: new_hpxml_path)
      hpxml.header.eri_design = eri_design
      XMLHelper.write_file(hpxml.to_oga(), new_hpxml_path)

      # Run tests
      args_hash = { 'hpxml_path' => '../workflow/sample_files/base-eri.xml',
                    'timeseries_frequency' => 'hourly',
                    'include_timeseries_fuel_consumptions' => true,
                    'include_timeseries_end_use_consumptions' => true,
                    'include_timeseries_hot_water_uses' => true,
                    'include_timeseries_total_loads' => true,
                    'include_timeseries_component_loads' => true,
                    'include_timeseries_zone_temperatures' => true,
                    'include_timeseries_airflows' => true,
                    'include_timeseries_weather' => true }
      annual_csv, timeseries_csv, eri_csv = _test_measure(args_hash, eri_design)
      assert(File.exist?(annual_csv))
      assert(File.exist?(timeseries_csv))
      assert(File.exist?(eri_csv))
      expected_eri_rows = ERIRows
      actual_eri_rows = File.readlines(eri_csv).map { |x| x.split(',')[0].strip }.select { |x| !x.empty? }
      assert_equal(expected_eri_rows.sort, actual_eri_rows.sort)

      # Cleanup
      File.delete(new_hpxml_path)
      File.delete(annual_csv)
      File.delete(timeseries_csv)
      File.delete(eri_csv)
    end
  end

  def _test_measure(args_hash, eri_design = nil)
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
    assert_equal(10, found_args.size)

    # Run OSW
    success = system("#{OpenStudio.getOpenStudioCLI} run -w #{osw_path}")
    assert_equal(true, success)

    # Cleanup
    File.delete(osw_path)

    if not eri_design.nil?
      annual_csv = File.join(File.dirname(template_osw), File.dirname(args_hash['hpxml_path']), "#{eri_design.gsub(' ', '')}.csv")
      timeseries_csv = File.join(File.dirname(template_osw), File.dirname(args_hash['hpxml_path']), "#{eri_design.gsub(' ', '')}_Hourly.csv")
      eri_csv = File.join(File.dirname(template_osw), File.dirname(args_hash['hpxml_path']), "#{eri_design.gsub(' ', '')}_ERI.csv")
    else
      annual_csv = File.join(File.dirname(template_osw), 'run', 'results_annual.csv')
      timeseries_csv = File.join(File.dirname(template_osw), 'run', 'results_timeseries.csv')
      eri_csv = nil
    end
    return annual_csv, timeseries_csv, eri_csv
  end

  def _check_for_nonzero_timeseries_value(timeseries_csv, timeseries_cols)
    values = {}
    timeseries_cols.each do |col|
      values[col] = []
    end
    CSV.foreach(timeseries_csv, headers: true) do |row|
      next if row['Time'].nil?

      timeseries_cols.each do |col|
        fail "Unexpected column: #{col}." if row[col].nil?

        values[col] << Float(row[col])
      end
    end
    timeseries_cols.each do |col|
      avg_value = values[col].sum(0.0) / values[col].size
      assert_operator(avg_value, :!=, 0)
    end
  end

  def _check_for_zero_baseload_timeseries_value(timeseries_csv, timeseries_cols)
    # check that every day has non zero values for baseload equipment (e.g., refrigerator)
    values = {}
    timeseries_cols.each do |col|
      values[col] = []
    end
    CSV.foreach(timeseries_csv, headers: true) do |row|
      next if row['Time'].nil?

      timeseries_cols.each do |col|
        fail "Unexpected column: #{col}." if row[col].nil?

        values[col] << Float(row[col])
      end
    end

    timeseries_cols.each do |col|
      has_no_zero_timeseries_value = !values[col].include?(0.0)
      assert(has_no_zero_timeseries_value)
    end
  end
end
