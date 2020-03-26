require_relative '../../HPXMLtoOpenStudio/resources/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require 'fileutils'
require 'rexml/document'
require 'rexml/xpath'
require_relative '../measure.rb'

class SimulationOutputReportTest < MiniTest::Test
  AnnualRows = [
    'Electricity: Total (MBtu)',
    'Electricity: Net (MBtu)',
    'Natural Gas: Total (MBtu)',
    'Fuel Oil: Total (MBtu)',
    'Propane: Total (MBtu)',
    'Wood: Total (MBtu)',
    'Wood Pellets: Total (MBtu)',
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
    'Electricity: Whole House Fan (MBtu)',
    'Electricity: Refrigerator (MBtu)',
    'Electricity: Dishwasher (MBtu)',
    'Electricity: Clothes Washer (MBtu)',
    'Electricity: Clothes Dryer (MBtu)',
    'Electricity: Range/Oven (MBtu)',
    'Electricity: Ceiling Fan (MBtu)',
    'Electricity: Television (MBtu)',
    'Electricity: Plug Loads (MBtu)',
    'Electricity: PV (MBtu)',
    'Natural Gas: Heating (MBtu)',
    'Natural Gas: Hot Water (MBtu)',
    'Natural Gas: Clothes Dryer (MBtu)',
    'Natural Gas: Range/Oven (MBtu)',
    'Fuel Oil: Heating (MBtu)',
    'Fuel Oil: Hot Water (MBtu)',
    'Fuel Oil: Clothes Dryer (MBtu)',
    'Fuel Oil: Range/Oven (MBtu)',
    'Propane: Heating (MBtu)',
    'Propane: Hot Water (MBtu)',
    'Propane: Clothes Dryer (MBtu)',
    'Propane: Range/Oven (MBtu)',
    'Wood: Heating (MBtu)',
    'Wood: Hot Water (MBtu)',
    'Wood: Clothes Dryer (MBtu)',
    'Wood: Range/Oven (MBtu)',
    'Wood Pellets: Heating (MBtu)',
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
  ]

  TimeseriesColsFuels = [
    'Electricity: Total',
    'Natural Gas: Total',
    'Fuel Oil: Total',
    'Propane: Total',
    'Wood: Total',
    'Wood Pellets: Total',
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
    'Electricity: Dishwasher',
    'Electricity: Clothes Washer',
    'Electricity: Clothes Dryer',
    'Electricity: Range/Oven',
    'Electricity: Ceiling Fan',
    'Electricity: Television',
    'Electricity: Plug Loads',
    'Electricity: PV',
    'Natural Gas: Heating',
    'Natural Gas: Hot Water',
    'Natural Gas: Clothes Dryer',
    'Natural Gas: Range/Oven',
    'Fuel Oil: Heating',
    'Fuel Oil: Hot Water',
    'Fuel Oil: Clothes Dryer',
    'Fuel Oil: Range/Oven',
    'Propane: Heating',
    'Propane: Hot Water',
    'Propane: Clothes Dryer',
    'Propane: Range/Oven',
    'Wood: Heating',
    'Wood: Hot Water',
    'Wood: Clothes Dryer',
    'Wood: Range/Oven',
    'Wood Pellets: Heating',
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

  TimeseriesColsTemperatures = [
    'Temperature: Attic - Unvented',
    'Temperature: Living Space',
  ]

  ERIRows = [
    'hpxml_eec_heats',
    'hpxml_eec_cools',
    'hpxml_eec_dhws',
    'hpxml_heat_fuels',
    'hpxml_dwh_fuels',
    'fuelElectricity',
    'fuelNaturalGas',
    'fuelFuelOil',
    'fuelPropane',
    'fuelWood',
    'fuelWoodPellets',
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
    'enduseElectricityWholeHouseFan',
    'enduseElectricityRefrigerator',
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
    'enduseFuelOilHeating',
    'enduseFuelOilHotWater',
    'enduseFuelOilClothesDryer',
    'enduseFuelOilRangeOven',
    'endusePropaneHeating',
    'endusePropaneHotWater',
    'endusePropaneClothesDryer',
    'endusePropaneRangeOven',
    'enduseWoodHeating',
    'enduseWoodHotWater',
    'enduseWoodClothesDryer',
    'enduseWoodRangeOven',
    'enduseWoodPelletsHeating',
    'loadHeating',
    'loadCooling',
    'loadHotWaterDelivered',
    'hpxml_cfa',
    'hpxml_nbr',
    'hpxml_nst',
  ]

  def test_annual_only
    args_hash = { 'hpxml_path' => '../workflow/sample_files/base.xml',
                  'timeseries_frequency' => 'hourly',
                  'include_timeseries_zone_temperatures' => false,
                  'include_timeseries_fuel_consumptions' => false,
                  'include_timeseries_end_use_consumptions' => false,
                  'include_timeseries_total_loads' => false,
                  'include_timeseries_component_loads' => false }
    annual_csv, timeseries_csv, eri_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(!File.exist?(timeseries_csv))
    expected_annual_rows = AnnualRows
    actual_annual_rows = File.readlines(annual_csv).map { |x| x.split(',')[0].strip }.select { |x| !x.empty? }
    assert_equal(expected_annual_rows.sort, actual_annual_rows.sort)
  end

  def test_timeseries_hourly_temperatures
    args_hash = { 'hpxml_path' => '../workflow/sample_files/base.xml',
                  'timeseries_frequency' => 'hourly',
                  'include_timeseries_zone_temperatures' => true,
                  'include_timeseries_fuel_consumptions' => false,
                  'include_timeseries_end_use_consumptions' => false,
                  'include_timeseries_total_loads' => false,
                  'include_timeseries_component_loads' => false }
    annual_csv, timeseries_csv, eri_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    expected_timeseries_cols = ['Hour'] + TimeseriesColsTemperatures
    actual_timeseries_cols = File.readlines(timeseries_csv)[0].strip.split(',')
    assert_equal(expected_timeseries_cols.sort, actual_timeseries_cols.sort)
    assert_equal(8760, File.readlines(timeseries_csv).size - 2)
  end

  def test_timeseries_hourly_fuels
    args_hash = { 'hpxml_path' => '../workflow/sample_files/base.xml',
                  'timeseries_frequency' => 'hourly',
                  'include_timeseries_zone_temperatures' => false,
                  'include_timeseries_fuel_consumptions' => true,
                  'include_timeseries_end_use_consumptions' => false,
                  'include_timeseries_total_loads' => false,
                  'include_timeseries_component_loads' => false }
    annual_csv, timeseries_csv, eri_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    expected_timeseries_cols = ['Hour'] + TimeseriesColsFuels
    actual_timeseries_cols = File.readlines(timeseries_csv)[0].strip.split(',')
    assert_equal(expected_timeseries_cols.sort, actual_timeseries_cols.sort)
    assert_equal(8760, File.readlines(timeseries_csv).size - 2)
  end

  def test_timeseries_hourly_enduses
    args_hash = { 'hpxml_path' => '../workflow/sample_files/base.xml',
                  'timeseries_frequency' => 'hourly',
                  'include_timeseries_zone_temperatures' => false,
                  'include_timeseries_fuel_consumptions' => false,
                  'include_timeseries_end_use_consumptions' => true,
                  'include_timeseries_total_loads' => false,
                  'include_timeseries_component_loads' => false }
    annual_csv, timeseries_csv, eri_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    expected_timeseries_cols = ['Hour'] + TimeseriesColsEndUses
    actual_timeseries_cols = File.readlines(timeseries_csv)[0].strip.split(',')
    assert_equal(expected_timeseries_cols.sort, actual_timeseries_cols.sort)
    assert_equal(8760, File.readlines(timeseries_csv).size - 2)
  end

  def test_timeseries_hourly_loads
    args_hash = { 'hpxml_path' => '../workflow/sample_files/base.xml',
                  'timeseries_frequency' => 'hourly',
                  'include_timeseries_zone_temperatures' => false,
                  'include_timeseries_fuel_consumptions' => false,
                  'include_timeseries_end_use_consumptions' => false,
                  'include_timeseries_total_loads' => true,
                  'include_timeseries_component_loads' => false }
    annual_csv, timeseries_csv, eri_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    expected_timeseries_cols = ['Hour'] + TimeseriesColsTotalLoads
    actual_timeseries_cols = File.readlines(timeseries_csv)[0].strip.split(',')
    assert_equal(expected_timeseries_cols.sort, actual_timeseries_cols.sort)
    assert_equal(8760, File.readlines(timeseries_csv).size - 2)
  end

  def test_timeseries_hourly_componentloads
    args_hash = { 'hpxml_path' => '../workflow/sample_files/base.xml',
                  'timeseries_frequency' => 'hourly',
                  'include_timeseries_zone_temperatures' => false,
                  'include_timeseries_fuel_consumptions' => false,
                  'include_timeseries_end_use_consumptions' => false,
                  'include_timeseries_total_loads' => false,
                  'include_timeseries_component_loads' => true }
    annual_csv, timeseries_csv, eri_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    expected_timeseries_cols = ['Hour'] + TimeseriesColsComponentLoads
    actual_timeseries_cols = File.readlines(timeseries_csv)[0].strip.split(',')
    assert_equal(expected_timeseries_cols.sort, actual_timeseries_cols.sort)
    assert_equal(8760, File.readlines(timeseries_csv).size - 2)
  end

  def test_timeseries_hourly_ALL
    args_hash = { 'hpxml_path' => '../workflow/sample_files/base.xml',
                  'timeseries_frequency' => 'hourly',
                  'include_timeseries_zone_temperatures' => true,
                  'include_timeseries_fuel_consumptions' => true,
                  'include_timeseries_end_use_consumptions' => true,
                  'include_timeseries_total_loads' => true,
                  'include_timeseries_component_loads' => true }
    annual_csv, timeseries_csv, eri_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    expected_timeseries_cols = ['Hour'] + TimeseriesColsFuels + TimeseriesColsEndUses + TimeseriesColsTotalLoads + TimeseriesColsComponentLoads + TimeseriesColsTemperatures
    actual_timeseries_cols = File.readlines(timeseries_csv)[0].strip.split(',')
    assert_equal(expected_timeseries_cols.sort, actual_timeseries_cols.sort)
    assert_equal(8760, File.readlines(timeseries_csv).size - 2)
  end

  def test_timeseries_daily_ALL
    args_hash = { 'hpxml_path' => '../workflow/sample_files/base.xml',
                  'timeseries_frequency' => 'daily',
                  'include_timeseries_zone_temperatures' => true,
                  'include_timeseries_fuel_consumptions' => true,
                  'include_timeseries_end_use_consumptions' => true,
                  'include_timeseries_total_loads' => true,
                  'include_timeseries_component_loads' => true }
    annual_csv, timeseries_csv, eri_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    expected_timeseries_cols = ['Day'] + TimeseriesColsFuels + TimeseriesColsEndUses + TimeseriesColsTotalLoads + TimeseriesColsComponentLoads + TimeseriesColsTemperatures
    actual_timeseries_cols = File.readlines(timeseries_csv)[0].strip.split(',')
    assert_equal(expected_timeseries_cols.sort, actual_timeseries_cols.sort)
    assert_equal(365, File.readlines(timeseries_csv).size - 2)
  end

  def test_timeseries_timestep_ALL_60min
    args_hash = { 'hpxml_path' => '../workflow/sample_files/base.xml',
                  'timeseries_frequency' => 'timestep',
                  'include_timeseries_zone_temperatures' => true,
                  'include_timeseries_fuel_consumptions' => true,
                  'include_timeseries_end_use_consumptions' => true,
                  'include_timeseries_total_loads' => true,
                  'include_timeseries_component_loads' => true }
    annual_csv, timeseries_csv, eri_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    expected_timeseries_cols = ['Timestep'] + TimeseriesColsFuels + TimeseriesColsEndUses + TimeseriesColsTotalLoads + TimeseriesColsComponentLoads + TimeseriesColsTemperatures
    actual_timeseries_cols = File.readlines(timeseries_csv)[0].strip.split(',')
    assert_equal(expected_timeseries_cols.sort, actual_timeseries_cols.sort)
    assert_equal(8760, File.readlines(timeseries_csv).size - 2)
  end

  def test_timeseries_timestep_ALL_10min
    args_hash = { 'hpxml_path' => '../workflow/sample_files/base-misc-timestep-10-mins.xml',
                  'timeseries_frequency' => 'timestep',
                  'include_timeseries_zone_temperatures' => true,
                  'include_timeseries_fuel_consumptions' => true,
                  'include_timeseries_end_use_consumptions' => true,
                  'include_timeseries_total_loads' => true,
                  'include_timeseries_component_loads' => true }
    annual_csv, timeseries_csv, eri_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    expected_timeseries_cols = ['Timestep'] + TimeseriesColsFuels + TimeseriesColsEndUses + TimeseriesColsTotalLoads + TimeseriesColsComponentLoads + TimeseriesColsTemperatures
    actual_timeseries_cols = File.readlines(timeseries_csv)[0].strip.split(',')
    assert_equal(expected_timeseries_cols.sort, actual_timeseries_cols.sort)
    assert_equal(52560, File.readlines(timeseries_csv).size - 2)
  end

  def test_eri_designs
    # Create derivative HPXML file w/ ERI design type set
    require 'fileutils'
    require_relative '../../HPXMLtoOpenStudio/resources/xmlhelper.rb'
    require_relative '../../HPXMLtoOpenStudio/resources/constants.rb'
    old_hpxml_path = File.join(File.dirname(__FILE__), '../../workflow/sample_files/base.xml')
    [Constants.CalcTypeERIReferenceHome, Constants.CalcTypeERIReferenceHome].each do |eri_design|
      new_hpxml_path = File.join(File.dirname(__FILE__), '../../workflow/sample_files/base-eri.xml')
      FileUtils.cp(old_hpxml_path, new_hpxml_path)
      hpxml = HPXML.new(hpxml_path: new_hpxml_path)
      hpxml.header.eri_design = eri_design
      XMLHelper.write_file(hpxml.to_rexml(), new_hpxml_path)

      # Run tests
      args_hash = { 'hpxml_path' => '../workflow/sample_files/base-eri.xml',
                    'timeseries_frequency' => 'hourly',
                    'include_timeseries_zone_temperatures' => true,
                    'include_timeseries_fuel_consumptions' => true,
                    'include_timeseries_end_use_consumptions' => true,
                    'include_timeseries_total_loads' => true,
                    'include_timeseries_component_loads' => true }
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
    assert_equal(7, found_args.size)

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
end
