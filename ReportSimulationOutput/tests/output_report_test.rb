# frozen_string_literal: true

require_relative '../../HPXMLtoOpenStudio/resources/minitest_helper'
require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'fileutils'
require 'csv'
require_relative '../measure.rb'
require_relative '../../HPXMLtoOpenStudio/resources/xmlhelper.rb'
require_relative '../../HPXMLtoOpenStudio/resources/constants.rb'
require 'oga'

class ReportSimulationOutputTest < MiniTest::Test
  def setup
    @tmp_hpxml_path = File.join(File.dirname(__FILE__), 'tmp.xml')
  end

  def teardown
    File.delete(@tmp_hpxml_path) if File.exist? @tmp_hpxml_path
  end

  AnnualRows = [
    'Energy Use: Total (MBtu)',
    'Energy Use: Net (MBtu)',
    'Fuel Use: Electricity: Total (MBtu)',
    'Fuel Use: Electricity: Net (MBtu)',
    'Fuel Use: Natural Gas: Total (MBtu)',
    'Fuel Use: Fuel Oil: Total (MBtu)',
    'Fuel Use: Propane: Total (MBtu)',
    'Fuel Use: Wood Cord: Total (MBtu)',
    'Fuel Use: Wood Pellets: Total (MBtu)',
    'Fuel Use: Coal: Total (MBtu)',
    'End Use: Electricity: Heating (MBtu)',
    'End Use: Electricity: Heating Heat Pump Backup (MBtu)',
    'End Use: Electricity: Heating Fans/Pumps (MBtu)',
    'End Use: Electricity: Cooling (MBtu)',
    'End Use: Electricity: Cooling Fans/Pumps (MBtu)',
    'End Use: Electricity: Hot Water (MBtu)',
    'End Use: Electricity: Hot Water Recirc Pump (MBtu)',
    'End Use: Electricity: Hot Water Solar Thermal Pump (MBtu)',
    'End Use: Electricity: Lighting Interior (MBtu)',
    'End Use: Electricity: Lighting Garage (MBtu)',
    'End Use: Electricity: Lighting Exterior (MBtu)',
    'End Use: Electricity: Mech Vent (MBtu)',
    'End Use: Electricity: Mech Vent Preheating (MBtu)',
    'End Use: Electricity: Mech Vent Precooling (MBtu)',
    'End Use: Electricity: Whole House Fan (MBtu)',
    'End Use: Electricity: Refrigerator (MBtu)',
    'End Use: Electricity: Freezer (MBtu)',
    'End Use: Electricity: Dehumidifier (MBtu)',
    'End Use: Electricity: Dishwasher (MBtu)',
    'End Use: Electricity: Clothes Washer (MBtu)',
    'End Use: Electricity: Clothes Dryer (MBtu)',
    'End Use: Electricity: Range/Oven (MBtu)',
    'End Use: Electricity: Ceiling Fan (MBtu)',
    'End Use: Electricity: Television (MBtu)',
    'End Use: Electricity: Plug Loads (MBtu)',
    'End Use: Electricity: Electric Vehicle Charging (MBtu)',
    'End Use: Electricity: Well Pump (MBtu)',
    'End Use: Electricity: Pool Heater (MBtu)',
    'End Use: Electricity: Pool Pump (MBtu)',
    'End Use: Electricity: Hot Tub Heater (MBtu)',
    'End Use: Electricity: Hot Tub Pump (MBtu)',
    'End Use: Electricity: PV (MBtu)',
    'End Use: Electricity: Generator (MBtu)',
    'End Use: Natural Gas: Heating (MBtu)',
    'End Use: Natural Gas: Heating Heat Pump Backup (MBtu)',
    'End Use: Natural Gas: Hot Water (MBtu)',
    'End Use: Natural Gas: Clothes Dryer (MBtu)',
    'End Use: Natural Gas: Range/Oven (MBtu)',
    'End Use: Natural Gas: Pool Heater (MBtu)',
    'End Use: Natural Gas: Hot Tub Heater (MBtu)',
    'End Use: Natural Gas: Grill (MBtu)',
    'End Use: Natural Gas: Lighting (MBtu)',
    'End Use: Natural Gas: Fireplace (MBtu)',
    'End Use: Natural Gas: Mech Vent Preheating (MBtu)',
    'End Use: Natural Gas: Generator (MBtu)',
    'End Use: Fuel Oil: Heating (MBtu)',
    'End Use: Fuel Oil: Heating Heat Pump Backup (MBtu)',
    'End Use: Fuel Oil: Hot Water (MBtu)',
    'End Use: Fuel Oil: Clothes Dryer (MBtu)',
    'End Use: Fuel Oil: Range/Oven (MBtu)',
    'End Use: Fuel Oil: Grill (MBtu)',
    'End Use: Fuel Oil: Lighting (MBtu)',
    'End Use: Fuel Oil: Fireplace (MBtu)',
    'End Use: Fuel Oil: Mech Vent Preheating (MBtu)',
    'End Use: Fuel Oil: Generator (MBtu)',
    'End Use: Propane: Heating (MBtu)',
    'End Use: Propane: Heating Heat Pump Backup (MBtu)',
    'End Use: Propane: Hot Water (MBtu)',
    'End Use: Propane: Clothes Dryer (MBtu)',
    'End Use: Propane: Range/Oven (MBtu)',
    'End Use: Propane: Grill (MBtu)',
    'End Use: Propane: Lighting (MBtu)',
    'End Use: Propane: Fireplace (MBtu)',
    'End Use: Propane: Mech Vent Preheating (MBtu)',
    'End Use: Propane: Generator (MBtu)',
    'End Use: Wood Cord: Heating (MBtu)',
    'End Use: Wood Cord: Heating Heat Pump Backup (MBtu)',
    'End Use: Wood Cord: Hot Water (MBtu)',
    'End Use: Wood Cord: Clothes Dryer (MBtu)',
    'End Use: Wood Cord: Range/Oven (MBtu)',
    'End Use: Wood Cord: Grill (MBtu)',
    'End Use: Wood Cord: Lighting (MBtu)',
    'End Use: Wood Cord: Fireplace (MBtu)',
    'End Use: Wood Cord: Mech Vent Preheating (MBtu)',
    'End Use: Wood Cord: Generator (MBtu)',
    'End Use: Wood Pellets: Heating (MBtu)',
    'End Use: Wood Pellets: Heating Heat Pump Backup (MBtu)',
    'End Use: Wood Pellets: Hot Water (MBtu)',
    'End Use: Wood Pellets: Clothes Dryer (MBtu)',
    'End Use: Wood Pellets: Range/Oven (MBtu)',
    'End Use: Wood Pellets: Grill (MBtu)',
    'End Use: Wood Pellets: Lighting (MBtu)',
    'End Use: Wood Pellets: Fireplace (MBtu)',
    'End Use: Wood Pellets: Mech Vent Preheating (MBtu)',
    'End Use: Wood Pellets: Generator (MBtu)',
    'End Use: Coal: Heating (MBtu)',
    'End Use: Coal: Heating Heat Pump Backup (MBtu)',
    'End Use: Coal: Hot Water (MBtu)',
    'End Use: Coal: Clothes Dryer (MBtu)',
    'End Use: Coal: Range/Oven (MBtu)',
    'End Use: Coal: Grill (MBtu)',
    'End Use: Coal: Lighting (MBtu)',
    'End Use: Coal: Fireplace (MBtu)',
    'End Use: Coal: Mech Vent Preheating (MBtu)',
    'End Use: Coal: Generator (MBtu)',
    'Load: Heating: Delivered (MBtu)',
    'Load: Cooling: Delivered (MBtu)',
    'Load: Hot Water: Delivered (MBtu)',
    'Load: Hot Water: Tank Losses (MBtu)',
    'Load: Hot Water: Desuperheater (MBtu)',
    'Load: Hot Water: Solar Thermal (MBtu)',
    'Unmet Hours: Heating (hr)',
    'Unmet Hours: Cooling (hr)',
    'Peak Electricity: Winter Total (W)',
    'Peak Electricity: Summer Total (W)',
    'Peak Load: Heating: Delivered (kBtu/hr)',
    'Peak Load: Cooling: Delivered (kBtu/hr)',
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

  BaseHPXMLTimeseriesColsEnergy = [
    'Energy Use: Total',
  ]

  BaseHPXMLTimeseriesColsFuels = [
    'Fuel Use: Electricity: Total',
    'Fuel Use: Natural Gas: Total',
  ]

  BaseHPXMLTimeseriesColsEndUses = [
    'End Use: Electricity: Clothes Dryer',
    'End Use: Electricity: Clothes Washer',
    'End Use: Electricity: Cooling',
    'End Use: Electricity: Cooling Fans/Pumps',
    'End Use: Electricity: Dishwasher',
    'End Use: Electricity: Heating Fans/Pumps',
    'End Use: Electricity: Hot Water',
    'End Use: Electricity: Lighting Exterior',
    'End Use: Electricity: Lighting Interior',
    'End Use: Electricity: Plug Loads',
    'End Use: Electricity: Range/Oven',
    'End Use: Electricity: Refrigerator',
    'End Use: Electricity: Television',
    'End Use: Natural Gas: Heating',
  ]

  BaseHPXMLTimeseriesColsWaterUses = [
    'Hot Water: Clothes Washer',
    'Hot Water: Dishwasher',
    'Hot Water: Distribution Waste',
    'Hot Water: Fixtures',
  ]

  BaseHPXMLTimeseriesColsTotalLoads = [
    'Load: Heating: Delivered',
    'Load: Cooling: Delivered',
    'Load: Hot Water: Delivered',
  ]

  BaseHPXMLTimeseriesColsComponentLoads = [
    'Component Load: Cooling: Ceilings',
    'Component Load: Cooling: Doors',
    'Component Load: Cooling: Ducts',
    'Component Load: Cooling: Foundation Walls',
    'Component Load: Cooling: Infiltration',
    'Component Load: Cooling: Internal Gains',
    'Component Load: Cooling: Internal Mass',
    'Component Load: Cooling: Mechanical Ventilation',
    'Component Load: Cooling: Natural Ventilation',
    'Component Load: Cooling: Rim Joists',
    'Component Load: Cooling: Slabs',
    'Component Load: Cooling: Walls',
    'Component Load: Cooling: Windows',
    'Component Load: Heating: Ceilings',
    'Component Load: Heating: Doors',
    'Component Load: Heating: Ducts',
    'Component Load: Heating: Foundation Walls',
    'Component Load: Heating: Infiltration',
    'Component Load: Heating: Internal Gains',
    'Component Load: Heating: Internal Mass',
    'Component Load: Heating: Mechanical Ventilation',
    'Component Load: Heating: Rim Joists',
    'Component Load: Heating: Slabs',
    'Component Load: Heating: Walls',
    'Component Load: Heating: Windows',
  ]

  BaseHPXMLTimeseriesColsUnmetHours = [
    'Unmet Hours: Heating',
    'Unmet Hours: Cooling',
  ]

  BaseHPXMLTimeseriesColsZoneTemps = [
    'Temperature: Attic - Unvented',
    'Temperature: Living Space',
    'Temperature: Heating Setpoint',
    'Temperature: Cooling Setpoint',
  ]

  BaseHPXMLTimeseriesColsAirflows = [
    'Airflow: Infiltration',
    'Airflow: Mechanical Ventilation',
    'Airflow: Natural Ventilation',
  ]

  BaseHPXMLTimeseriesColsWeather = [
    'Weather: Drybulb Temperature',
    'Weather: Wetbulb Temperature',
    'Weather: Relative Humidity',
    'Weather: Wind Speed',
    'Weather: Diffuse Solar Radiation',
    'Weather: Direct Solar Radiation',
  ]

  BaseHPXMLTimeseriesColsStandardOutputVariables = [
    'Zone People Occupant Count: Living Space',
    'Zone People Total Heating Energy: Living Space'
  ]

  BaseHPXMLTimeseriesColsAdvancedOutputVariables = [
    'Surface Construction Index: Door1',
    'Surface Construction Index: Foundationwall1',
    'Surface Construction Index: Framefloor1',
    'Surface Construction Index: Furniture Mass Living Space 1 Above Grade',
    'Surface Construction Index: Furniture Mass Living Space 1 Below Grade',
    'Surface Construction Index: Inferred Conditioned Ceiling',
    'Surface Construction Index: Inferred Conditioned Floor',
    'Surface Construction Index: Partition Wall Mass Above Grade',
    'Surface Construction Index: Partition Wall Mass Below Grade',
    'Surface Construction Index: Rimjoist1:0',
    'Surface Construction Index: Rimjoist1:90',
    'Surface Construction Index: Rimjoist1:180',
    'Surface Construction Index: Rimjoist1:270',
    'Surface Construction Index: Roof1:0',
    'Surface Construction Index: Roof1:90',
    'Surface Construction Index: Roof1:180',
    'Surface Construction Index: Roof1:270',
    'Surface Construction Index: Slab1',
    'Surface Construction Index: Surface 1',
    'Surface Construction Index: Surface 1 Reversed',
    'Surface Construction Index: Surface 2',
    'Surface Construction Index: Surface 3',
    'Surface Construction Index: Surface 4',
    'Surface Construction Index: Surface 5',
    'Surface Construction Index: Surface 6',
    'Surface Construction Index: Surface Door1',
    'Surface Construction Index: Surface Window1',
    'Surface Construction Index: Surface Window2',
    'Surface Construction Index: Surface Window3',
    'Surface Construction Index: Surface Window4',
    'Surface Construction Index: Wall1:0',
    'Surface Construction Index: Wall1:90',
    'Surface Construction Index: Wall1:180',
    'Surface Construction Index: Wall1:270',
    'Surface Construction Index: Wall2:0',
    'Surface Construction Index: Wall2:90',
    'Surface Construction Index: Wall2:180',
    'Surface Construction Index: Wall2:270',
    'Surface Construction Index: Window1',
    'Surface Construction Index: Window2',
    'Surface Construction Index: Window3',
    'Surface Construction Index: Window4'
  ]

  def all_base_hpxml_timeseries_cols
    return (BaseHPXMLTimeseriesColsEnergy +
            BaseHPXMLTimeseriesColsFuels +
            BaseHPXMLTimeseriesColsEndUses +
            BaseHPXMLTimeseriesColsWaterUses +
            BaseHPXMLTimeseriesColsTotalLoads +
            BaseHPXMLTimeseriesColsUnmetHours +
            BaseHPXMLTimeseriesColsZoneTemps +
            BaseHPXMLTimeseriesColsAirflows +
            BaseHPXMLTimeseriesColsWeather)
  end

  def emission_scenarios
    return ['CO2e: Cambium Hourly MidCase LRMER RMPA',
            'CO2e: Cambium Hourly LowRECosts LRMER RMPA',
            'CO2e: Cambium Annual MidCase AER National',
            'SO2: eGRID RMPA',
            'NOx: eGRID RMPA']
  end

  def emission_annual_cols
    cols = []
    emission_scenarios.each do |scenario|
      cols += ["Emissions: #{scenario}: Total (lb)",
               "Emissions: #{scenario}: Electricity: Total (lb)",
               "Emissions: #{scenario}: Electricity: Heating Fans/Pumps (lb)",
               "Emissions: #{scenario}: Electricity: Cooling (lb)",
               "Emissions: #{scenario}: Electricity: Cooling Fans/Pumps (lb)",
               "Emissions: #{scenario}: Electricity: Hot Water (lb)",
               "Emissions: #{scenario}: Electricity: Lighting Interior (lb)",
               "Emissions: #{scenario}: Electricity: Lighting Exterior (lb)",
               "Emissions: #{scenario}: Electricity: Refrigerator (lb)",
               "Emissions: #{scenario}: Electricity: Dishwasher (lb)",
               "Emissions: #{scenario}: Electricity: Clothes Washer (lb)",
               "Emissions: #{scenario}: Electricity: Clothes Dryer (lb)",
               "Emissions: #{scenario}: Electricity: Range/Oven (lb)",
               "Emissions: #{scenario}: Electricity: Television (lb)",
               "Emissions: #{scenario}: Electricity: Plug Loads (lb)",
               "Emissions: #{scenario}: Electricity: PV (lb)",
               "Emissions: #{scenario}: Natural Gas: Total (lb)",
               "Emissions: #{scenario}: Natural Gas: Heating (lb)"]
    end
    return cols
  end

  def emissions_timeseries_cols
    cols = []
    emission_scenarios.each do |scenario|
      cols += ["Emissions: #{scenario}: Total"]
    end
    return cols
  end

  def emission_fuels_timeseries_cols
    cols = []
    emission_scenarios.each do |scenario|
      cols += ["Emissions: #{scenario}: Electricity: Total",
               "Emissions: #{scenario}: Natural Gas: Total"]
    end
    return cols
  end

  def emission_end_uses_timeseries_cols
    cols = []
    emission_scenarios.each do |scenario|
      cols += ["Emissions: #{scenario}: Electricity: Heating Fans/Pumps",
               "Emissions: #{scenario}: Electricity: Cooling",
               "Emissions: #{scenario}: Electricity: Cooling Fans/Pumps",
               "Emissions: #{scenario}: Electricity: Hot Water",
               "Emissions: #{scenario}: Electricity: Lighting Interior",
               "Emissions: #{scenario}: Electricity: Lighting Exterior",
               "Emissions: #{scenario}: Electricity: Refrigerator",
               "Emissions: #{scenario}: Electricity: Dishwasher",
               "Emissions: #{scenario}: Electricity: Clothes Washer",
               "Emissions: #{scenario}: Electricity: Clothes Dryer",
               "Emissions: #{scenario}: Electricity: Range/Oven",
               "Emissions: #{scenario}: Electricity: Television",
               "Emissions: #{scenario}: Electricity: Plug Loads",
               "Emissions: #{scenario}: Electricity: PV",
               "Emissions: #{scenario}: Natural Gas: Heating"]
    end
    return cols
  end

  def test_annual_only
    args_hash = { 'hpxml_path' => File.join(File.dirname(__FILE__), '../../workflow/sample_files/base.xml'),
                  'add_component_loads' => true,
                  'timeseries_frequency' => 'hourly',
                  'include_timeseries_total_consumptions' => false,
                  'include_timeseries_fuel_consumptions' => false,
                  'include_timeseries_end_use_consumptions' => false,
                  'include_timeseries_emissions' => false,
                  'include_timeseries_emission_fuels' => false,
                  'include_timeseries_emission_end_uses' => false,
                  'include_timeseries_hot_water_uses' => false,
                  'include_timeseries_total_loads' => false,
                  'include_timeseries_unmet_hours' => false,
                  'include_timeseries_component_loads' => false,
                  'include_timeseries_zone_temperatures' => false,
                  'include_timeseries_airflows' => false,
                  'include_timeseries_weather' => false }
    annual_csv, timeseries_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(!File.exist?(timeseries_csv))
    expected_annual_rows = AnnualRows
    actual_annual_rows = File.readlines(annual_csv).map { |x| x.split(',')[0].strip }.select { |x| !x.empty? }
    assert_equal(expected_annual_rows.sort, actual_annual_rows.sort)
    _check_for_runner_registered_values(File.join(File.dirname(annual_csv), 'results.json'), expected_annual_rows)
  end

  def test_annual_only2
    args_hash = { 'hpxml_path' => File.join(File.dirname(__FILE__), '../../workflow/sample_files/base-misc-emissions.xml'),
                  'add_component_loads' => true,
                  'timeseries_frequency' => 'none',
                  'include_timeseries_total_consumptions' => false,
                  'include_timeseries_fuel_consumptions' => true,
                  'include_timeseries_end_use_consumptions' => true,
                  'include_timeseries_emissions' => true,
                  'include_timeseries_emission_fuels' => true,
                  'include_timeseries_emission_end_uses' => true,
                  'include_timeseries_hot_water_uses' => true,
                  'include_timeseries_total_loads' => true,
                  'include_timeseries_unmet_hours' => true,
                  'include_timeseries_component_loads' => true,
                  'include_timeseries_zone_temperatures' => true,
                  'include_timeseries_airflows' => true,
                  'include_timeseries_weather' => true }
    annual_csv, timeseries_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(!File.exist?(timeseries_csv))
    expected_annual_rows = AnnualRows + emission_annual_cols
    actual_annual_rows = File.readlines(annual_csv).map { |x| x.split(',')[0].strip }.select { |x| !x.empty? }
    assert_equal(expected_annual_rows.sort, actual_annual_rows.sort)
    _check_for_runner_registered_values(File.join(File.dirname(annual_csv), 'results.json'), expected_annual_rows)
  end

  def test_timeseries_hourly_total_energy
    args_hash = { 'hpxml_path' => File.join(File.dirname(__FILE__), '../../workflow/sample_files/base.xml'),
                  'timeseries_frequency' => 'hourly',
                  'include_timeseries_total_consumptions' => true }
    annual_csv, timeseries_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    expected_timeseries_cols = ['Time'] + BaseHPXMLTimeseriesColsEnergy
    actual_timeseries_cols = File.readlines(timeseries_csv)[0].strip.split(',')
    assert_equal(expected_timeseries_cols.sort, actual_timeseries_cols.sort)
    timeseries_rows = CSV.read(timeseries_csv)
    assert_equal(8760, timeseries_rows.size - 2)
    timeseries_cols = timeseries_rows.transpose
    assert_equal(1, _check_for_constant_timeseries_step(timeseries_cols[0]))
    _check_for_nonzero_timeseries_value(timeseries_csv, ['Energy Use: Total'])
  end

  def test_timeseries_hourly_total_energy_pv
    args_hash = { 'hpxml_path' => File.join(File.dirname(__FILE__), '../../workflow/sample_files/base-pv.xml'),
                  'timeseries_frequency' => 'hourly',
                  'include_timeseries_total_consumptions' => true }
    annual_csv, timeseries_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    expected_timeseries_cols = ['Time'] + BaseHPXMLTimeseriesColsEnergy + ['Energy Use: Net']
    actual_timeseries_cols = File.readlines(timeseries_csv)[0].strip.split(',')
    assert_equal(expected_timeseries_cols.sort, actual_timeseries_cols.sort)
    timeseries_rows = CSV.read(timeseries_csv)
    assert_equal(8760, timeseries_rows.size - 2)
    timeseries_cols = timeseries_rows.transpose
    assert_equal(1, _check_for_constant_timeseries_step(timeseries_cols[0]))
    _check_for_nonzero_timeseries_value(timeseries_csv, ['Energy Use: Total',
                                                         'Energy Use: Net'])
  end

  def test_timeseries_hourly_fuels
    args_hash = { 'hpxml_path' => File.join(File.dirname(__FILE__), '../../workflow/sample_files/base.xml'),
                  'timeseries_frequency' => 'hourly',
                  'include_timeseries_fuel_consumptions' => true }
    annual_csv, timeseries_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    expected_timeseries_cols = ['Time'] + BaseHPXMLTimeseriesColsFuels
    actual_timeseries_cols = File.readlines(timeseries_csv)[0].strip.split(',')
    assert_equal(expected_timeseries_cols.sort, actual_timeseries_cols.sort)
    timeseries_rows = CSV.read(timeseries_csv)
    assert_equal(8760, timeseries_rows.size - 2)
    timeseries_cols = timeseries_rows.transpose
    assert_equal(1, _check_for_constant_timeseries_step(timeseries_cols[0]))
    _check_for_nonzero_timeseries_value(timeseries_csv, ['Fuel Use: Electricity: Total'])
  end

  def test_timeseries_hourly_fuels_pv
    args_hash = { 'hpxml_path' => File.join(File.dirname(__FILE__), '../../workflow/sample_files/base-pv.xml'),
                  'timeseries_frequency' => 'hourly',
                  'include_timeseries_fuel_consumptions' => true }
    annual_csv, timeseries_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    expected_timeseries_cols = ['Time'] + BaseHPXMLTimeseriesColsFuels + ['Fuel Use: Electricity: Net']
    actual_timeseries_cols = File.readlines(timeseries_csv)[0].strip.split(',')
    assert_equal(expected_timeseries_cols.sort, actual_timeseries_cols.sort)
    timeseries_rows = CSV.read(timeseries_csv)
    assert_equal(8760, timeseries_rows.size - 2)
    timeseries_cols = timeseries_rows.transpose
    assert_equal(1, _check_for_constant_timeseries_step(timeseries_cols[0]))
    _check_for_nonzero_timeseries_value(timeseries_csv, ['Fuel Use: Electricity: Total',
                                                         'Fuel Use: Electricity: Net'])
  end

  def test_timeseries_hourly_emissions
    args_hash = { 'hpxml_path' => File.join(File.dirname(__FILE__), '../../workflow/sample_files/base-misc-emissions.xml'),
                  'timeseries_frequency' => 'hourly',
                  'include_timeseries_emissions' => true }
    annual_csv, timeseries_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    expected_timeseries_cols = ['Time'] + emissions_timeseries_cols
    actual_timeseries_cols = File.readlines(timeseries_csv)[0].strip.split(',')
    assert_equal(expected_timeseries_cols.sort, actual_timeseries_cols.sort)
    timeseries_rows = CSV.read(timeseries_csv)
    assert_equal(8760, timeseries_rows.size - 2)
    timeseries_cols = timeseries_rows.transpose
    _check_for_constant_timeseries_step(timeseries_cols[0])
    _check_for_nonzero_timeseries_value(timeseries_csv, emissions_timeseries_cols[0..2])
  end

  def test_timeseries_hourly_emission_end_uses
    args_hash = { 'hpxml_path' => File.join(File.dirname(__FILE__), '../../workflow/sample_files/base-misc-emissions.xml'),
                  'timeseries_frequency' => 'hourly',
                  'include_timeseries_emission_end_uses' => true }
    annual_csv, timeseries_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    expected_timeseries_cols = ['Time'] + emission_end_uses_timeseries_cols
    actual_timeseries_cols = File.readlines(timeseries_csv)[0].strip.split(',')
    assert_equal(expected_timeseries_cols.sort, actual_timeseries_cols.sort)
    timeseries_rows = CSV.read(timeseries_csv)
    assert_equal(8760, timeseries_rows.size - 2)
    timeseries_cols = timeseries_rows.transpose
    _check_for_constant_timeseries_step(timeseries_cols[0])
    _check_for_nonzero_timeseries_value(timeseries_csv, emission_end_uses_timeseries_cols[0..2])
  end

  def test_timeseries_hourly_emission_fuels
    args_hash = { 'hpxml_path' => File.join(File.dirname(__FILE__), '../../workflow/sample_files/base-misc-emissions.xml'),
                  'timeseries_frequency' => 'hourly',
                  'include_timeseries_emission_fuels' => true }
    annual_csv, timeseries_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    expected_timeseries_cols = ['Time'] + emission_fuels_timeseries_cols
    actual_timeseries_cols = File.readlines(timeseries_csv)[0].strip.split(',')
    assert_equal(expected_timeseries_cols.sort, actual_timeseries_cols.sort)
    timeseries_rows = CSV.read(timeseries_csv)
    assert_equal(8760, timeseries_rows.size - 2)
    timeseries_cols = timeseries_rows.transpose
    _check_for_constant_timeseries_step(timeseries_cols[0])
    _check_for_nonzero_timeseries_value(timeseries_csv, emission_fuels_timeseries_cols[0..2])
  end

  def test_timeseries_hourly_enduses
    args_hash = { 'hpxml_path' => File.join(File.dirname(__FILE__), '../../workflow/sample_files/base.xml'),
                  'timeseries_frequency' => 'hourly',
                  'include_timeseries_end_use_consumptions' => true }
    annual_csv, timeseries_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    expected_timeseries_cols = ['Time'] + BaseHPXMLTimeseriesColsEndUses
    actual_timeseries_cols = File.readlines(timeseries_csv)[0].strip.split(',')
    assert_equal(expected_timeseries_cols.sort, actual_timeseries_cols.sort)
    timeseries_rows = CSV.read(timeseries_csv)
    assert_equal(8760, timeseries_rows.size - 2)
    timeseries_cols = timeseries_rows.transpose
    assert_equal(1, _check_for_constant_timeseries_step(timeseries_cols[0]))
    _check_for_nonzero_timeseries_value(timeseries_csv, ['End Use: Electricity: Plug Loads'])
  end

  def test_timeseries_hourly_hotwateruses
    args_hash = { 'hpxml_path' => File.join(File.dirname(__FILE__), '../../workflow/sample_files/base.xml'),
                  'timeseries_frequency' => 'hourly',
                  'include_timeseries_hot_water_uses' => true }
    annual_csv, timeseries_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    expected_timeseries_cols = ['Time'] + BaseHPXMLTimeseriesColsWaterUses
    actual_timeseries_cols = File.readlines(timeseries_csv)[0].strip.split(',')
    assert_equal(expected_timeseries_cols.sort, actual_timeseries_cols.sort)
    timeseries_rows = CSV.read(timeseries_csv)
    assert_equal(8760, timeseries_rows.size - 2)
    timeseries_cols = timeseries_rows.transpose
    assert_equal(1, _check_for_constant_timeseries_step(timeseries_cols[0]))
    _check_for_nonzero_timeseries_value(timeseries_csv, BaseHPXMLTimeseriesColsWaterUses)
  end

  def test_timeseries_hourly_total_loads
    args_hash = { 'hpxml_path' => File.join(File.dirname(__FILE__), '../../workflow/sample_files/base.xml'),
                  'timeseries_frequency' => 'hourly',
                  'include_timeseries_total_loads' => true }
    annual_csv, timeseries_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    expected_timeseries_cols = ['Time'] + BaseHPXMLTimeseriesColsTotalLoads
    actual_timeseries_cols = File.readlines(timeseries_csv)[0].strip.split(',')
    assert_equal(expected_timeseries_cols.sort, actual_timeseries_cols.sort)
    timeseries_rows = CSV.read(timeseries_csv)
    assert_equal(8760, timeseries_rows.size - 2)
    timeseries_cols = timeseries_rows.transpose
    assert_equal(1, _check_for_constant_timeseries_step(timeseries_cols[0]))
    _check_for_nonzero_timeseries_value(timeseries_csv, BaseHPXMLTimeseriesColsTotalLoads)
  end

  def test_timeseries_hourly_component_loads
    args_hash = { 'hpxml_path' => File.join(File.dirname(__FILE__), '../../workflow/sample_files/base.xml'),
                  'add_component_loads' => true,
                  'timeseries_frequency' => 'hourly',
                  'include_timeseries_component_loads' => true }
    annual_csv, timeseries_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    expected_timeseries_cols = ['Time'] + BaseHPXMLTimeseriesColsComponentLoads
    actual_timeseries_cols = File.readlines(timeseries_csv)[0].strip.split(',')
    assert_equal(expected_timeseries_cols.sort, actual_timeseries_cols.sort)
    timeseries_rows = CSV.read(timeseries_csv)
    assert_equal(8760, timeseries_rows.size - 2)
    timeseries_cols = timeseries_rows.transpose
    assert_equal(1, _check_for_constant_timeseries_step(timeseries_cols[0]))
    _check_for_nonzero_timeseries_value(timeseries_csv, ['Component Load: Heating: Internal Gains', 'Component Load: Cooling: Internal Gains'])
  end

  def test_timeseries_hourly_unmet_hours
    args_hash = { 'hpxml_path' => File.join(File.dirname(__FILE__), '../../workflow/sample_files/base-hvac-undersized.xml'),
                  'add_component_loads' => true,
                  'timeseries_frequency' => 'hourly',
                  'include_timeseries_unmet_hours' => true }
    annual_csv, timeseries_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    expected_timeseries_cols = ['Time'] + BaseHPXMLTimeseriesColsUnmetHours
    actual_timeseries_cols = File.readlines(timeseries_csv)[0].strip.split(',')
    assert_equal(expected_timeseries_cols.sort, actual_timeseries_cols.sort)
    timeseries_rows = CSV.read(timeseries_csv)
    assert_equal(8760, timeseries_rows.size - 2)
    timeseries_cols = timeseries_rows.transpose
    assert_equal(1, _check_for_constant_timeseries_step(timeseries_cols[0]))
    _check_for_nonzero_timeseries_value(timeseries_csv, ['Unmet Hours: Heating', 'Unmet Hours: Cooling'])
  end

  def test_timeseries_hourly_zone_temperatures
    args_hash = { 'hpxml_path' => File.join(File.dirname(__FILE__), '../../workflow/sample_files/base.xml'),
                  'timeseries_frequency' => 'hourly',
                  'include_timeseries_zone_temperatures' => true }
    annual_csv, timeseries_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    expected_timeseries_cols = ['Time'] + BaseHPXMLTimeseriesColsZoneTemps
    actual_timeseries_cols = File.readlines(timeseries_csv)[0].strip.split(',')
    assert_equal(expected_timeseries_cols.sort, actual_timeseries_cols.sort)
    timeseries_rows = CSV.read(timeseries_csv)
    assert_equal(8760, timeseries_rows.size - 2)
    timeseries_cols = timeseries_rows.transpose
    assert_equal(1, _check_for_constant_timeseries_step(timeseries_cols[0]))
    _check_for_nonzero_timeseries_value(timeseries_csv, BaseHPXMLTimeseriesColsZoneTemps)
  end

  def test_timeseries_hourly_zone_temperatures_without_cooling
    args_hash = { 'hpxml_path' => File.join(File.dirname(__FILE__), '../../workflow/sample_files/base-hvac-furnace-gas-only.xml'),
                  'timeseries_frequency' => 'hourly',
                  'include_timeseries_zone_temperatures' => true }
    annual_csv, timeseries_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    expected_timeseries_cols = ['Time'] + BaseHPXMLTimeseriesColsZoneTemps - ['Temperature: Cooling Setpoint']
    actual_timeseries_cols = File.readlines(timeseries_csv)[0].strip.split(',')
    assert_equal(expected_timeseries_cols.sort, actual_timeseries_cols.sort)
    timeseries_rows = CSV.read(timeseries_csv)
    assert_equal(8760, timeseries_rows.size - 2)
    timeseries_cols = timeseries_rows.transpose
    assert_equal(1, _check_for_constant_timeseries_step(timeseries_cols[0]))
    _check_for_nonzero_timeseries_value(timeseries_csv, BaseHPXMLTimeseriesColsZoneTemps - ['Temperature: Cooling Setpoint'])
  end

  def test_timeseries_hourly_zone_temperatures_mf_space
    args_hash = { 'hpxml_path' => File.join(File.dirname(__FILE__), '../../workflow/sample_files/base-bldgtype-multifamily-adjacent-to-multiple.xml'),
                  'timeseries_frequency' => 'hourly',
                  'include_timeseries_zone_temperatures' => true }
    annual_csv, timeseries_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    actual_timeseries_cols = File.readlines(timeseries_csv)[0].strip.split(',')
    cols_temps_other_side = [
      'Temperature: Other Multifamily Buffer Space',
      'Temperature: Other Non-freezing Space',
      'Temperature: Other Housing Unit',
      'Temperature: Other Heated Space'
    ]
    cols_temps_other_side.each do |expected_col|
      assert(actual_timeseries_cols.include? expected_col)
    end
    timeseries_rows = CSV.read(timeseries_csv)
    assert_equal(8760, timeseries_rows.size - 2)
    timeseries_cols = timeseries_rows.transpose
    assert_equal(1, _check_for_constant_timeseries_step(timeseries_cols[0]))
    _check_for_nonzero_timeseries_value(timeseries_csv, cols_temps_other_side)
  end

  def test_timeseries_hourly_airflows_with_exhaust_mechvent
    args_hash = { 'hpxml_path' => File.join(File.dirname(__FILE__), '../../workflow/sample_files/base-mechvent-exhaust.xml'),
                  'timeseries_frequency' => 'hourly',
                  'include_timeseries_airflows' => true }
    annual_csv, timeseries_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    expected_timeseries_cols = ['Time'] + BaseHPXMLTimeseriesColsAirflows
    actual_timeseries_cols = File.readlines(timeseries_csv)[0].strip.split(',')
    assert_equal(expected_timeseries_cols.sort, actual_timeseries_cols.sort)
    timeseries_rows = CSV.read(timeseries_csv)
    assert_equal(8760, timeseries_rows.size - 2)
    timeseries_cols = timeseries_rows.transpose
    assert_equal(1, _check_for_constant_timeseries_step(timeseries_cols[0]))
    _check_for_nonzero_timeseries_value(timeseries_csv, BaseHPXMLTimeseriesColsAirflows.select { |t| t != 'Airflow: Whole House Fan' })
  end

  def test_timeseries_hourly_airflows_with_whf
    args_hash = { 'hpxml_path' => File.join(File.dirname(__FILE__), '../../workflow/sample_files/base-mechvent-whole-house-fan.xml'),
                  'timeseries_frequency' => 'hourly',
                  'include_timeseries_airflows' => true }
    annual_csv, timeseries_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    add_cols = ['Airflow: Whole House Fan']
    remove_cols = ['Airflow: Natural Ventilation']
    expected_timeseries_cols = ['Time'] + BaseHPXMLTimeseriesColsAirflows + add_cols - remove_cols
    actual_timeseries_cols = File.readlines(timeseries_csv)[0].strip.split(',')
    assert_equal(expected_timeseries_cols.sort, actual_timeseries_cols.sort)
    timeseries_rows = CSV.read(timeseries_csv)
    assert_equal(8760, timeseries_rows.size - 2)
    timeseries_cols = timeseries_rows.transpose
    assert_equal(1, _check_for_constant_timeseries_step(timeseries_cols[0]))
    _check_for_nonzero_timeseries_value(timeseries_csv, add_cols)
  end

  def test_timeseries_hourly_airflows_with_clothes_dryer_exhaust
    args_hash = { 'hpxml_path' => File.join(File.dirname(__FILE__), '../../workflow/sample_files/base-appliances-gas.xml'),
                  'timeseries_frequency' => 'hourly',
                  'include_timeseries_airflows' => true }
    annual_csv, timeseries_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    expected_timeseries_cols = ['Time'] + BaseHPXMLTimeseriesColsAirflows
    actual_timeseries_cols = File.readlines(timeseries_csv)[0].strip.split(',')
    assert_equal(expected_timeseries_cols.sort, actual_timeseries_cols.sort)
    timeseries_rows = CSV.read(timeseries_csv)
    assert_equal(8760, timeseries_rows.size - 2)
    timeseries_cols = timeseries_rows.transpose
    assert_equal(1, _check_for_constant_timeseries_step(timeseries_cols[0]))
    _check_for_nonzero_timeseries_value(timeseries_csv, ['Airflow: Mechanical Ventilation'])
  end

  def test_timeseries_hourly_airflows_with_balanced_mechvent
    args_hash = { 'hpxml_path' => File.join(File.dirname(__FILE__), '../../workflow/sample_files/base-mechvent-balanced.xml'),
                  'timeseries_frequency' => 'hourly',
                  'include_timeseries_airflows' => true }
    annual_csv, timeseries_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    expected_timeseries_cols = ['Time'] + BaseHPXMLTimeseriesColsAirflows
    actual_timeseries_cols = File.readlines(timeseries_csv)[0].strip.split(',')
    assert_equal(expected_timeseries_cols.sort, actual_timeseries_cols.sort)
    timeseries_rows = CSV.read(timeseries_csv)
    assert_equal(8760, timeseries_rows.size - 2)
    timeseries_cols = timeseries_rows.transpose
    assert_equal(1, _check_for_constant_timeseries_step(timeseries_cols[0]))
    _check_for_nonzero_timeseries_value(timeseries_csv, ['Airflow: Mechanical Ventilation'])
  end

  def test_timeseries_hourly_airflows_with_cfis
    args_hash = { 'hpxml_path' => File.join(File.dirname(__FILE__), '../../workflow/sample_files/base-mechvent-cfis.xml'),
                  'timeseries_frequency' => 'hourly',
                  'include_timeseries_airflows' => true }
    annual_csv, timeseries_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    expected_timeseries_cols = ['Time'] + BaseHPXMLTimeseriesColsAirflows
    actual_timeseries_cols = File.readlines(timeseries_csv)[0].strip.split(',')
    assert_equal(expected_timeseries_cols.sort, actual_timeseries_cols.sort)
    timeseries_rows = CSV.read(timeseries_csv)
    assert_equal(8760, timeseries_rows.size - 2)
    timeseries_cols = timeseries_rows.transpose
    assert_equal(1, _check_for_constant_timeseries_step(timeseries_cols[0]))
    _check_for_nonzero_timeseries_value(timeseries_csv, ['Airflow: Mechanical Ventilation'])
  end

  def test_timeseries_hourly_weather
    args_hash = { 'hpxml_path' => File.join(File.dirname(__FILE__), '../../workflow/sample_files/base.xml'),
                  'timeseries_frequency' => 'hourly',
                  'include_timeseries_weather' => true }
    annual_csv, timeseries_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    expected_timeseries_cols = ['Time'] + BaseHPXMLTimeseriesColsWeather
    actual_timeseries_cols = File.readlines(timeseries_csv)[0].strip.split(',')
    assert_equal(expected_timeseries_cols.sort, actual_timeseries_cols.sort)
    timeseries_rows = CSV.read(timeseries_csv)
    assert_equal(8760, timeseries_rows.size - 2)
    timeseries_cols = timeseries_rows.transpose
    assert_equal(1, _check_for_constant_timeseries_step(timeseries_cols[0]))
    _check_for_nonzero_timeseries_value(timeseries_csv, BaseHPXMLTimeseriesColsWeather)
  end

  def test_timeseries_hourly_ALL
    args_hash = { 'hpxml_path' => File.join(File.dirname(__FILE__), '../../workflow/sample_files/base-misc-emissions.xml'),
                  'timeseries_frequency' => 'hourly',
                  'include_timeseries_total_consumptions' => true,
                  'include_timeseries_fuel_consumptions' => true,
                  'include_timeseries_end_use_consumptions' => true,
                  'include_timeseries_emissions' => true,
                  'include_timeseries_emission_fuels' => true,
                  'include_timeseries_emission_end_uses' => true,
                  'include_timeseries_hot_water_uses' => true,
                  'include_timeseries_total_loads' => true,
                  'include_timeseries_unmet_hours' => true,
                  'include_timeseries_component_loads' => true,
                  'include_timeseries_zone_temperatures' => true,
                  'include_timeseries_airflows' => true,
                  'include_timeseries_weather' => true }
    annual_csv, timeseries_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    expected_timeseries_cols = ['Time'] +
                               all_base_hpxml_timeseries_cols +
                               emissions_timeseries_cols +
                               emission_fuels_timeseries_cols +
                               emission_end_uses_timeseries_cols +
                               ['End Use: Electricity: PV', 'Energy Use: Net', 'Fuel Use: Electricity: Net']
    actual_timeseries_cols = File.readlines(timeseries_csv)[0].strip.split(',')
    assert_equal(expected_timeseries_cols.sort, actual_timeseries_cols.sort)
    timeseries_rows = CSV.read(timeseries_csv)
    assert_equal(8760, timeseries_rows.size - 2)
    timeseries_cols = timeseries_rows.transpose
    assert_equal(1, _check_for_constant_timeseries_step(timeseries_cols[0]))
    _check_for_nonzero_timeseries_value(timeseries_csv, emissions_timeseries_cols[0..2])
    _check_for_zero_baseload_timeseries_value(timeseries_csv, ['End Use: Electricity: Refrigerator'])
  end

  def test_timeseries_daily_ALL
    args_hash = { 'hpxml_path' => File.join(File.dirname(__FILE__), '../../workflow/sample_files/base-misc-emissions.xml'),
                  'timeseries_frequency' => 'daily',
                  'include_timeseries_total_consumptions' => true,
                  'include_timeseries_fuel_consumptions' => true,
                  'include_timeseries_end_use_consumptions' => true,
                  'include_timeseries_emissions' => true,
                  'include_timeseries_emission_fuels' => true,
                  'include_timeseries_emission_end_uses' => true,
                  'include_timeseries_hot_water_uses' => true,
                  'include_timeseries_total_loads' => true,
                  'include_timeseries_unmet_hours' => true,
                  'include_timeseries_component_loads' => true,
                  'include_timeseries_zone_temperatures' => true,
                  'include_timeseries_airflows' => true,
                  'include_timeseries_weather' => true }
    annual_csv, timeseries_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    expected_timeseries_cols = ['Time'] +
                               all_base_hpxml_timeseries_cols +
                               emissions_timeseries_cols +
                               emission_fuels_timeseries_cols +
                               emission_end_uses_timeseries_cols +
                               ['End Use: Electricity: PV', 'Energy Use: Net', 'Fuel Use: Electricity: Net']
    actual_timeseries_cols = File.readlines(timeseries_csv)[0].strip.split(',')
    assert_equal(expected_timeseries_cols.sort, actual_timeseries_cols.sort)
    timeseries_rows = CSV.read(timeseries_csv)
    assert_equal(365, timeseries_rows.size - 2)
    timeseries_cols = timeseries_rows.transpose
    assert_equal(1, _check_for_constant_timeseries_step(timeseries_cols[0]))
    _check_for_nonzero_timeseries_value(timeseries_csv, emissions_timeseries_cols[0..2])
    _check_for_zero_baseload_timeseries_value(timeseries_csv, ['End Use: Electricity: Refrigerator'])
  end

  def test_timeseries_monthly_ALL
    args_hash = { 'hpxml_path' => File.join(File.dirname(__FILE__), '../../workflow/sample_files/base-misc-emissions.xml'),
                  'timeseries_frequency' => 'monthly',
                  'include_timeseries_total_consumptions' => true,
                  'include_timeseries_fuel_consumptions' => true,
                  'include_timeseries_end_use_consumptions' => true,
                  'include_timeseries_emissions' => true,
                  'include_timeseries_emission_fuels' => true,
                  'include_timeseries_emission_end_uses' => true,
                  'include_timeseries_hot_water_uses' => true,
                  'include_timeseries_total_loads' => true,
                  'include_timeseries_unmet_hours' => true,
                  'include_timeseries_component_loads' => true,
                  'include_timeseries_zone_temperatures' => true,
                  'include_timeseries_airflows' => true,
                  'include_timeseries_weather' => true }
    annual_csv, timeseries_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    expected_timeseries_cols = ['Time'] +
                               all_base_hpxml_timeseries_cols +
                               emissions_timeseries_cols +
                               emission_fuels_timeseries_cols +
                               emission_end_uses_timeseries_cols +
                               ['End Use: Electricity: PV', 'Energy Use: Net', 'Fuel Use: Electricity: Net']
    actual_timeseries_cols = File.readlines(timeseries_csv)[0].strip.split(',')
    assert_equal(expected_timeseries_cols.sort, actual_timeseries_cols.sort)
    timeseries_rows = CSV.read(timeseries_csv)
    assert_equal(12, timeseries_rows.size - 2)
    _check_for_nonzero_timeseries_value(timeseries_csv, emissions_timeseries_cols[0..2])
    _check_for_zero_baseload_timeseries_value(timeseries_csv, ['End Use: Electricity: Refrigerator'])
  end

  def test_timeseries_timestep
    args_hash = { 'hpxml_path' => File.join(File.dirname(__FILE__), '../../workflow/sample_files/base.xml'),
                  'timeseries_frequency' => 'timestep',
                  'include_timeseries_fuel_consumptions' => true }
    annual_csv, timeseries_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    timeseries_rows = CSV.read(timeseries_csv)
    assert_equal(8760, timeseries_rows.size - 2)
    timeseries_cols = timeseries_rows.transpose
    assert_equal(1, _check_for_constant_timeseries_step(timeseries_cols[0]))
  end

  def test_timeseries_timestep_emissions
    args_hash = { 'hpxml_path' => File.join(File.dirname(__FILE__), '../../workflow/sample_files/base-misc-emissions.xml'),
                  'timeseries_frequency' => 'timestep',
                  'include_timeseries_fuel_consumptions' => false,
                  'include_timeseries_end_use_consumptions' => false,
                  'include_timeseries_emissions' => true,
                  'include_timeseries_emission_fuels' => true,
                  'include_timeseries_emission_end_uses' => true,
                  'include_timeseries_hot_water_uses' => false,
                  'include_timeseries_total_loads' => false,
                  'include_timeseries_unmet_hours' => false,
                  'include_timeseries_component_loads' => false,
                  'include_timeseries_zone_temperatures' => false,
                  'include_timeseries_airflows' => false,
                  'include_timeseries_weather' => false }
    annual_csv, timeseries_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    expected_timeseries_cols = ['Time'] +
                               emissions_timeseries_cols +
                               emission_fuels_timeseries_cols +
                               emission_end_uses_timeseries_cols
    actual_timeseries_cols = File.readlines(timeseries_csv)[0].strip.split(',')
    assert_equal(expected_timeseries_cols.sort, actual_timeseries_cols.sort)
    timeseries_rows = CSV.read(timeseries_csv)
    assert_equal(8760, timeseries_rows.size - 2)
    timeseries_cols = timeseries_rows.transpose
    _check_for_constant_timeseries_step(timeseries_cols[0])
    _check_for_nonzero_timeseries_value(timeseries_csv, emissions_timeseries_cols[0..2])
  end

  def test_timeseries_timestep_10min
    args_hash = { 'hpxml_path' => File.join(File.dirname(__FILE__), '../../workflow/sample_files/base-simcontrol-timestep-10-mins.xml'),
                  'timeseries_frequency' => 'timestep',
                  'include_timeseries_fuel_consumptions' => true }
    annual_csv, timeseries_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    timeseries_rows = CSV.read(timeseries_csv)
    assert_equal(52560, timeseries_rows.size - 2)
    timeseries_cols = timeseries_rows.transpose
    assert_equal(1, _check_for_constant_timeseries_step(timeseries_cols[0]))
  end

  def test_timeseries_hourly_runperiod_Jan
    args_hash = { 'hpxml_path' => File.join(File.dirname(__FILE__), '../../workflow/sample_files/base-simcontrol-runperiod-1-month.xml'),
                  'timeseries_frequency' => 'hourly',
                  'include_timeseries_fuel_consumptions' => true }
    annual_csv, timeseries_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    timeseries_rows = CSV.read(timeseries_csv)
    assert_equal(31 * 24, timeseries_rows.size - 2)
    timeseries_cols = timeseries_rows.transpose
    assert_equal(1, _check_for_constant_timeseries_step(timeseries_cols[0]))
  end

  def test_timeseries_daily_runperiod_Jan
    args_hash = { 'hpxml_path' => File.join(File.dirname(__FILE__), '../../workflow/sample_files/base-simcontrol-runperiod-1-month.xml'),
                  'timeseries_frequency' => 'daily',
                  'include_timeseries_fuel_consumptions' => true }
    annual_csv, timeseries_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    timeseries_rows = CSV.read(timeseries_csv)
    assert_equal(31, timeseries_rows.size - 2)
    timeseries_cols = timeseries_rows.transpose
    assert_equal(1, _check_for_constant_timeseries_step(timeseries_cols[0]))
  end

  def test_timeseries_monthly_runperiod_Jan
    args_hash = { 'hpxml_path' => File.join(File.dirname(__FILE__), '../../workflow/sample_files/base-simcontrol-runperiod-1-month.xml'),
                  'timeseries_frequency' => 'monthly',
                  'include_timeseries_fuel_consumptions' => true }
    annual_csv, timeseries_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    timeseries_rows = CSV.read(timeseries_csv)
    assert_equal(1, timeseries_rows.size - 2)
  end

  def test_timeseries_timestep_runperiod_Jan
    args_hash = { 'hpxml_path' => File.join(File.dirname(__FILE__), '../../workflow/sample_files/base-simcontrol-runperiod-1-month.xml'),
                  'timeseries_frequency' => 'timestep',
                  'include_timeseries_fuel_consumptions' => true }
    annual_csv, timeseries_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    timeseries_rows = CSV.read(timeseries_csv)
    assert_equal(31 * 24, timeseries_rows.size - 2)
    timeseries_cols = timeseries_rows.transpose
    assert_equal(1, _check_for_constant_timeseries_step(timeseries_cols[0]))
  end

  def test_timeseries_hourly_AMY_2012
    args_hash = { 'hpxml_path' => File.join(File.dirname(__FILE__), '../../workflow/sample_files/base-location-AMY-2012.xml'),
                  'timeseries_frequency' => 'hourly',
                  'include_timeseries_fuel_consumptions' => true }
    annual_csv, timeseries_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    timeseries_rows = CSV.read(timeseries_csv)
    assert_equal(8784, timeseries_rows.size - 2)
    timeseries_cols = timeseries_rows.transpose
    assert_equal(1, _check_for_constant_timeseries_step(timeseries_cols[0]))
  end

  def test_timeseries_for_dview
    args_hash = { 'hpxml_path' => File.join(File.dirname(__FILE__), '../../workflow/sample_files/base.xml'),
                  'output_format' => 'csv_dview',
                  'timeseries_frequency' => 'timestep',
                  'include_timeseries_fuel_consumptions' => true,
                  'add_timeseries_dst_column' => true }
    annual_csv, timeseries_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    assert_equal('wxDVFileHeaderVer.1', CSV.readlines(timeseries_csv)[0][0].strip)
  end

  def test_timeseries_local_time_dst
    args_hash = { 'hpxml_path' => File.join(File.dirname(__FILE__), '../../workflow/sample_files/base.xml'),
                  'timeseries_frequency' => 'timestep',
                  'include_timeseries_fuel_consumptions' => true,
                  'add_timeseries_dst_column' => true }
    annual_csv, timeseries_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    timeseries_rows = CSV.read(timeseries_csv)
    assert_equal(8760, timeseries_rows.size - 2)
    timeseries_cols = timeseries_rows.transpose
    assert_equal(1, timeseries_rows[0].select { |r| r == 'Time' }.size)
    assert_equal(1, timeseries_rows[0].select { |r| r == 'TimeDST' }.size)
    assert_equal(1, _check_for_constant_timeseries_step(timeseries_cols[0]))
    assert_equal(3, _check_for_constant_timeseries_step(timeseries_cols[1]))
  end

  def test_timeseries_local_time_utc
    args_hash = { 'hpxml_path' => File.join(File.dirname(__FILE__), '../../workflow/sample_files/base.xml'),
                  'timeseries_frequency' => 'timestep',
                  'include_timeseries_fuel_consumptions' => true,
                  'add_timeseries_utc_column' => true }
    annual_csv, timeseries_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    timeseries_rows = CSV.read(timeseries_csv)
    assert_equal(8760, timeseries_rows.size - 2)
    timeseries_cols = timeseries_rows.transpose
    assert_equal(1, timeseries_rows[0].select { |r| r == 'Time' }.size)
    assert_equal(1, timeseries_rows[0].select { |r| r == 'TimeUTC' }.size)
    assert_equal(1, _check_for_constant_timeseries_step(timeseries_cols[0]))
    assert_equal(1, _check_for_constant_timeseries_step(timeseries_cols[1]))
  end

  def test_timeseries_local_time_dst_and_utc
    args_hash = { 'hpxml_path' => File.join(File.dirname(__FILE__), '../../workflow/sample_files/base.xml'),
                  'timeseries_frequency' => 'timestep',
                  'include_timeseries_fuel_consumptions' => true,
                  'add_timeseries_dst_column' => true,
                  'add_timeseries_utc_column' => true }
    annual_csv, timeseries_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    timeseries_rows = CSV.read(timeseries_csv)
    assert_equal(8760, timeseries_rows.size - 2)
    timeseries_cols = timeseries_rows.transpose
    assert_equal(1, timeseries_rows[0].select { |r| r == 'Time' }.size)
    assert_equal(1, timeseries_rows[0].select { |r| r == 'TimeDST' }.size)
    assert_equal(1, timeseries_rows[0].select { |r| r == 'TimeUTC' }.size)
    assert_equal(1, _check_for_constant_timeseries_step(timeseries_cols[0]))
    assert_equal(3, _check_for_constant_timeseries_step(timeseries_cols[1]))
    assert_equal(1, _check_for_constant_timeseries_step(timeseries_cols[2]))
  end

  def test_timeseries_user_defined_standard_output_variables
    args_hash = { 'hpxml_path' => File.join(File.dirname(__FILE__), '../../workflow/sample_files/base.xml'),
                  'timeseries_frequency' => 'hourly',
                  'include_timeseries_fuel_consumptions' => false,
                  'include_timeseries_end_use_consumptions' => false,
                  'include_timeseries_emissions' => false,
                  'include_timeseries_emission_fuels' => false,
                  'include_timeseries_emission_end_uses' => false,
                  'include_timeseries_hot_water_uses' => false,
                  'include_timeseries_total_loads' => false,
                  'include_timeseries_unmet_hours' => false,
                  'include_timeseries_component_loads' => false,
                  'include_timeseries_zone_temperatures' => false,
                  'include_timeseries_airflows' => false,
                  'include_timeseries_weather' => false,
                  'user_output_variables' => 'Zone People Occupant Count, Zone People Total Heating Energy, Foo' }
    annual_csv, timeseries_csv, run_log = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    expected_timeseries_cols = ['Time'] + BaseHPXMLTimeseriesColsStandardOutputVariables
    actual_timeseries_cols = File.readlines(timeseries_csv)[0].strip.split(',')
    assert_equal(expected_timeseries_cols.sort, actual_timeseries_cols.sort)
    timeseries_rows = CSV.read(timeseries_csv)
    assert_equal(8760, timeseries_rows.size - 2)
    timeseries_cols = timeseries_rows.transpose
    assert_equal(1, _check_for_constant_timeseries_step(timeseries_cols[0]))
    _check_for_nonzero_timeseries_value(timeseries_csv, BaseHPXMLTimeseriesColsStandardOutputVariables)
    assert(File.readlines(run_log).any? { |line| line.include?("Request for output variable 'Foo'") })
  end

  def test_timeseries_user_defined_advanced_output_variables
    args_hash = { 'hpxml_path' => File.join(File.dirname(__FILE__), '../../workflow/sample_files/base.xml'),
                  'add_component_loads' => true,
                  'timeseries_frequency' => 'hourly',
                  'include_timeseries_fuel_consumptions' => false,
                  'include_timeseries_end_use_consumptions' => false,
                  'include_timeseries_emissions' => false,
                  'include_timeseries_emission_fuels' => false,
                  'include_timeseries_emission_end_uses' => false,
                  'include_timeseries_hot_water_uses' => false,
                  'include_timeseries_total_loads' => false,
                  'include_timeseries_unmet_hours' => false,
                  'include_timeseries_component_loads' => false,
                  'include_timeseries_zone_temperatures' => false,
                  'include_timeseries_airflows' => false,
                  'include_timeseries_weather' => false,
                  'user_output_variables' => 'Surface Construction Index' }
    annual_csv, timeseries_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    expected_timeseries_cols = ['Time'] + BaseHPXMLTimeseriesColsAdvancedOutputVariables
    actual_timeseries_cols = File.readlines(timeseries_csv)[0].strip.split(',')
    assert_equal(expected_timeseries_cols.sort, actual_timeseries_cols.sort)
    timeseries_rows = CSV.read(timeseries_csv)
    assert_equal(8760, timeseries_rows.size - 2)
    timeseries_cols = timeseries_rows.transpose
    assert_equal(1, _check_for_constant_timeseries_step(timeseries_cols[0]))
    _check_for_nonzero_timeseries_value(timeseries_csv, BaseHPXMLTimeseriesColsAdvancedOutputVariables)
  end

  def test_eri_output
    args_hash = { 'hpxml_path' => File.join(File.dirname(__FILE__), '../../workflow/sample_files/base.xml'),
                  'generate_eri_outputs' => true }
    annual_csv, timeseries_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(!File.exist?(timeseries_csv))
    actual_annual_rows = File.readlines(annual_csv).map { |x| x.split(',')[0].strip }.select { |x| !x.empty? }
    assert(actual_annual_rows.include? 'ERI: Building: CFA')
  end

  def test_for_unsuccessful_simulation_infinity
    # Create HPXML w/ AFUE=0 to generate Infinity result
    hpxml_path = File.join(File.dirname(__FILE__), '../../workflow/sample_files/base.xml')
    hpxml = HPXML.new(hpxml_path: hpxml_path)
    hpxml.heating_systems[0].heating_efficiency_afue = 0.0
    XMLHelper.write_file(hpxml.to_oga(), @tmp_hpxml_path)

    args_hash = { 'hpxml_path' => @tmp_hpxml_path }
    annual_csv, timeseries_csv, run_log = _test_measure(args_hash, expect_success: false)
    assert(!File.exist?(annual_csv))
    assert(!File.exist?(timeseries_csv))
    assert(File.readlines(run_log).any? { |line| line.include?('Simulation used infinite energy; double-check inputs.') })
  end

  def _test_measure(args_hash, expect_success: true)
    # Run measure via OSW
    require 'json'
    template_osw = File.join(File.dirname(__FILE__), '..', '..', 'workflow', 'template-run-hpxml.osw')
    workflow = OpenStudio::WorkflowJSON.new(template_osw)
    json = JSON.parse(workflow.to_s)

    # Update measure args
    steps = OpenStudio::WorkflowStepVector.new
    found_args = []
    json['steps'].each do |json_step|
      next unless ['HPXMLtoOpenStudio', 'ReportSimulationOutput'].include? json_step['measure_dir_name']

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
    assert_equal(expect_success, success)

    # Cleanup
    File.delete(osw_path)

    annual_csv = File.join(File.dirname(template_osw), 'run', 'results_annual.csv')
    timeseries_csv = File.join(File.dirname(template_osw), 'run', 'results_timeseries.csv')
    run_log = File.join(File.dirname(template_osw), 'run', 'run.log')
    return annual_csv, timeseries_csv, run_log
  end

  def _parse_time(ts)
    date, time = ts.split('T')
    year, month, day = date.split('-')
    hour, minute, _second = time.split(':')
    return Time.utc(year, month, day, hour, minute)
  end

  def _check_for_constant_timeseries_step(time_col)
    steps = []
    time_col.each_with_index do |_ts, i|
      next if i < 3

      t0 = _parse_time(time_col[i - 1])
      t1 = _parse_time(time_col[i])

      steps << t1 - t0
    end
    return steps.uniq.size
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

  def _check_for_runner_registered_values(results_json, expected_annual_rows)
    expected_registered_values = expected_annual_rows.map { |c| OpenStudio::toUnderscoreCase(c).chomp('_') }

    require 'json'
    json = JSON.parse(File.read(results_json))
    actual_registered_values = json['ReportSimulationOutput'].keys

    expected_registered_values.each do |val|
      assert(actual_registered_values.include? val)
    end
  end
end
