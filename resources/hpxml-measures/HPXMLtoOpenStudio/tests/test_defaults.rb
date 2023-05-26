# frozen_string_literal: true

require_relative '../resources/minitest_helper'
require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'fileutils'
require_relative '../measure.rb'
require_relative '../resources/util.rb'

class HPXMLtoOpenStudioDefaultsTest < MiniTest::Test
  ConstantDaySchedule = '0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1'
  ConstantMonthSchedule = '1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1'

  def setup
    @root_path = File.absolute_path(File.join(File.dirname(__FILE__), '..', '..'))
    @sample_files_path = File.join(@root_path, 'workflow', 'sample_files')
    @tmp_hpxml_path = File.join(@sample_files_path, 'tmp.xml')
    @tmp_output_path = File.join(@sample_files_path, 'tmp_output')
    FileUtils.mkdir_p(@tmp_output_path)

    @args_hash = {}
    @args_hash['hpxml_path'] = File.absolute_path(@tmp_hpxml_path)
    @args_hash['debug'] = true
    @args_hash['output_dir'] = File.absolute_path(@tmp_output_path)
  end

  def teardown
    File.delete(@tmp_hpxml_path) if File.exist? @tmp_hpxml_path
    FileUtils.rm_rf(@tmp_output_path)
  end

  def test_header
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base-hvac-air-to-air-heat-pump-1-speed.xml')
    hpxml.header.timestep = 30
    hpxml.header.sim_begin_month = 2
    hpxml.header.sim_begin_day = 2
    hpxml.header.sim_end_month = 11
    hpxml.header.sim_end_day = 11
    hpxml.header.sim_calendar_year = 2009
    hpxml.header.dst_enabled = false
    hpxml.header.dst_begin_month = 3
    hpxml.header.dst_begin_day = 3
    hpxml.header.dst_end_month = 10
    hpxml.header.dst_end_day = 10
    hpxml.header.heat_pump_sizing_methodology = HPXML::HeatPumpSizingMaxLoad
    hpxml.header.allow_increased_fixed_capacities = true
    hpxml.header.state_code = 'CA'
    hpxml.header.time_zone_utc_offset = -8
    hpxml.header.temperature_capacitance_multiplier = 1.5
    hpxml.header.natvent_days_per_week = 7
    hpxml.header.unavailable_periods.add(column_name: 'Power Outage', begin_month: 1, begin_day: 1, begin_hour: 3, end_month: 12, end_day: 31, end_hour: 4, natvent_availability: HPXML::ScheduleUnavailable)
    hpxml.header.shading_summer_begin_month = 2
    hpxml.header.shading_summer_begin_day = 3
    hpxml.header.shading_summer_end_month = 4
    hpxml.header.shading_summer_end_day = 5
    hpxml.header.manualj_heating_design_temp = 0.0
    hpxml.header.manualj_cooling_design_temp = 100.0
    hpxml.header.manualj_heating_setpoint = 68.0
    hpxml.header.manualj_cooling_setpoint = 78.0
    hpxml.header.manualj_humidity_setpoint = 0.44
    hpxml.header.manualj_internal_loads_sensible = 1600.0
    hpxml.header.manualj_internal_loads_latent = 60.0
    hpxml.header.manualj_num_occupants = 8
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_header_values(hpxml_default, 30, 2, 2, 11, 11, 2009, false, 3, 3, 10, 10, HPXML::HeatPumpSizingMaxLoad, true, 'CA',
                                -8, 1.5, 7, 3, 4, HPXML::ScheduleUnavailable, 2, 3, 4, 5, 0.0, 100.0, 68.0, 78.0, 0.44, 1600.0, 60.0, 8)

    # Test defaults - DST not in weather file
    hpxml.header.timestep = nil
    hpxml.header.sim_begin_month = nil
    hpxml.header.sim_begin_day = nil
    hpxml.header.sim_end_month = nil
    hpxml.header.sim_end_day = nil
    hpxml.header.sim_calendar_year = nil
    hpxml.header.dst_enabled = nil
    hpxml.header.dst_begin_month = nil
    hpxml.header.dst_begin_day = nil
    hpxml.header.dst_end_month = nil
    hpxml.header.dst_end_day = nil
    hpxml.header.heat_pump_sizing_methodology = nil
    hpxml.header.allow_increased_fixed_capacities = nil
    hpxml.header.state_code = nil
    hpxml.header.time_zone_utc_offset = nil
    hpxml.header.temperature_capacitance_multiplier = nil
    hpxml.header.natvent_days_per_week = nil
    hpxml.header.unavailable_periods[-1].begin_hour = nil
    hpxml.header.unavailable_periods[-1].end_hour = nil
    hpxml.header.unavailable_periods[-1].natvent_availability = nil
    hpxml.header.shading_summer_begin_month = nil
    hpxml.header.shading_summer_begin_day = nil
    hpxml.header.shading_summer_end_month = nil
    hpxml.header.shading_summer_end_day = nil
    hpxml.header.manualj_heating_design_temp = nil
    hpxml.header.manualj_cooling_design_temp = nil
    hpxml.header.manualj_heating_setpoint = nil
    hpxml.header.manualj_cooling_setpoint = nil
    hpxml.header.manualj_humidity_setpoint = nil
    hpxml.header.manualj_internal_loads_sensible = nil
    hpxml.header.manualj_internal_loads_latent = nil
    hpxml.header.manualj_num_occupants = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_header_values(hpxml_default, 60, 1, 1, 12, 31, 2007, true, 3, 12, 11, 5, HPXML::HeatPumpSizingHERS, false, 'CO',
                                -7, 1.0, 3, 0, 24, HPXML::ScheduleRegular, 5, 1, 10, 31, 6.8, 91.8, 70.0, 75.0, 0.5, 2400.0, 0.0, 4)

    # Test defaults - DST in weather file
    hpxml = _create_hpxml('base-location-AMY-2012.xml')
    hpxml.header.timestep = nil
    hpxml.header.sim_begin_month = nil
    hpxml.header.sim_begin_day = nil
    hpxml.header.sim_end_month = nil
    hpxml.header.sim_end_day = nil
    hpxml.header.sim_calendar_year = nil
    hpxml.header.dst_enabled = nil
    hpxml.header.dst_begin_month = nil
    hpxml.header.dst_begin_day = nil
    hpxml.header.dst_end_month = nil
    hpxml.header.dst_end_day = nil
    hpxml.header.heat_pump_sizing_methodology = nil
    hpxml.header.allow_increased_fixed_capacities = nil
    hpxml.header.state_code = nil
    hpxml.header.time_zone_utc_offset = nil
    hpxml.header.temperature_capacitance_multiplier = nil
    hpxml.header.shading_summer_begin_month = nil
    hpxml.header.shading_summer_begin_day = nil
    hpxml.header.shading_summer_end_month = nil
    hpxml.header.shading_summer_end_day = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_header_values(hpxml_default, 60, 1, 1, 12, 31, 2012, true, 3, 11, 11, 4, nil, false, 'CO',
                                -7, 1.0, 3, nil, nil, nil, 5, 1, 9, 30, 10.2, 91.4, 70.0, 75.0, 0.5, 2400.0, 0.0, 4)

    # Test defaults - calendar year override by AMY year
    hpxml.header.sim_calendar_year = 2020
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_header_values(hpxml_default, 60, 1, 1, 12, 31, 2012, true, 3, 11, 11, 4, nil, false, 'CO',
                                -7, 1.0, 3, nil, nil, nil, 5, 1, 9, 30, 10.2, 91.4, 70.0, 75.0, 0.5, 2400.0, 0.0, 4)

    # Test defaults - southern hemisphere, invalid state code
    hpxml = _create_hpxml('base-location-capetown-zaf.xml')
    hpxml.header.timestep = nil
    hpxml.header.sim_begin_month = nil
    hpxml.header.sim_begin_day = nil
    hpxml.header.sim_end_month = nil
    hpxml.header.sim_end_day = nil
    hpxml.header.sim_calendar_year = nil
    hpxml.header.dst_enabled = nil
    hpxml.header.dst_begin_month = nil
    hpxml.header.dst_begin_day = nil
    hpxml.header.dst_end_month = nil
    hpxml.header.dst_end_day = nil
    hpxml.header.heat_pump_sizing_methodology = nil
    hpxml.header.allow_increased_fixed_capacities = nil
    hpxml.header.state_code = nil
    hpxml.header.time_zone_utc_offset = nil
    hpxml.header.temperature_capacitance_multiplier = nil
    hpxml.header.shading_summer_begin_month = nil
    hpxml.header.shading_summer_begin_day = nil
    hpxml.header.shading_summer_end_month = nil
    hpxml.header.shading_summer_end_day = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_header_values(hpxml_default, 60, 1, 1, 12, 31, 2007, true, 3, 12, 11, 5, nil, false, nil,
                                2, 1.0, 3, nil, nil, nil, 12, 1, 4, 30, 41.0, 84.4, 70.0, 75.0, 0.5, 2400.0, 0.0, 4)
  end

  def test_emissions_factors
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base-misc-loads-large-uncommon.xml')
    for emissions_type in ['CO2e', 'NOx', 'SO2', 'foo']
      hpxml.header.emissions_scenarios.add(name: emissions_type,
                                           emissions_type: emissions_type,
                                           elec_units: HPXML::EmissionsScenario::UnitsLbPerMWh,
                                           elec_schedule_filepath: File.join(File.dirname(__FILE__), '..', 'resources', 'data', 'cambium', 'LRMER_MidCase.csv'),
                                           elec_schedule_number_of_header_rows: 1,
                                           elec_schedule_column_number: 9,
                                           natural_gas_units: HPXML::EmissionsScenario::UnitsLbPerMBtu,
                                           natural_gas_value: 123.0,
                                           propane_units: HPXML::EmissionsScenario::UnitsLbPerMBtu,
                                           propane_value: 234.0,
                                           fuel_oil_units: HPXML::EmissionsScenario::UnitsKgPerMBtu,
                                           fuel_oil_value: 345.0,
                                           coal_units: HPXML::EmissionsScenario::UnitsKgPerMBtu,
                                           coal_value: 456.0,
                                           wood_units: HPXML::EmissionsScenario::UnitsKgPerMBtu,
                                           wood_value: 666.0,
                                           wood_pellets_units: HPXML::EmissionsScenario::UnitsLbPerMBtu,
                                           wood_pellets_value: 999.0)
    end
    hpxml.water_heating_systems[0].fuel_type = HPXML::FuelTypePropane
    hpxml.clothes_dryers[0].fuel_type = HPXML::FuelTypeOil
    hpxml.cooking_ranges[0].fuel_type = HPXML::FuelTypeWoodCord
    hpxml.fuel_loads[0].fuel_type = HPXML::FuelTypeWoodPellets
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    hpxml_default.header.emissions_scenarios.each do |scenario|
      _test_default_emissions_values(scenario, 1, 9,
                                     HPXML::EmissionsScenario::UnitsLbPerMBtu, 123.0,
                                     HPXML::EmissionsScenario::UnitsLbPerMBtu, 234.0,
                                     HPXML::EmissionsScenario::UnitsKgPerMBtu, 345.0,
                                     HPXML::EmissionsScenario::UnitsKgPerMBtu, 456.0,
                                     HPXML::EmissionsScenario::UnitsKgPerMBtu, 666.0,
                                     HPXML::EmissionsScenario::UnitsLbPerMBtu, 999.0)
    end

    # Test defaults
    hpxml.header.emissions_scenarios.each do |scenario|
      scenario.elec_schedule_column_number = nil
      scenario.natural_gas_units = nil
      scenario.natural_gas_value = nil
      scenario.propane_units = nil
      scenario.propane_value = nil
      scenario.fuel_oil_units = nil
      scenario.fuel_oil_value = nil
      scenario.coal_units = nil
      scenario.coal_value = nil
      scenario.wood_units = nil
      scenario.wood_value = nil
      scenario.wood_pellets_units = nil
      scenario.wood_pellets_value = nil
    end
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    hpxml_default.header.emissions_scenarios.each do |scenario|
      if scenario.emissions_type == 'CO2e'
        natural_gas_value, propane_value, fuel_oil_value = 147.3, 177.8, 195.9 # lb/MBtu
      elsif scenario.emissions_type == 'NOx'
        natural_gas_value, propane_value, fuel_oil_value = 0.0922, 0.1421, 0.1300 # lb/MBtu
      elsif scenario.emissions_type == 'SO2'
        natural_gas_value, propane_value, fuel_oil_value = 0.0006, 0.0002, 0.0015 # lb/MBtu
      else
        natural_gas_value, propane_value, fuel_oil_value = nil, nil, nil
      end
      _test_default_emissions_values(scenario, 1, 1,
                                     HPXML::EmissionsScenario::UnitsLbPerMBtu, natural_gas_value,
                                     HPXML::EmissionsScenario::UnitsLbPerMBtu, propane_value,
                                     HPXML::EmissionsScenario::UnitsLbPerMBtu, fuel_oil_value,
                                     nil, nil,
                                     nil, nil,
                                     nil, nil)
    end
  end

  def test_utility_bills
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base-pv.xml')
    hpxml.header.utility_bill_scenarios.clear
    for pv_compensation_type in [HPXML::PVCompensationTypeNetMetering, HPXML::PVCompensationTypeFeedInTariff]
      hpxml.header.utility_bill_scenarios.add(name: pv_compensation_type,
                                              elec_fixed_charge: 8,
                                              natural_gas_fixed_charge: 9,
                                              propane_fixed_charge: 10,
                                              fuel_oil_fixed_charge: 11,
                                              coal_fixed_charge: 12,
                                              wood_fixed_charge: 13,
                                              wood_pellets_fixed_charge: 14,
                                              elec_marginal_rate: 0.2,
                                              natural_gas_marginal_rate: 0.3,
                                              propane_marginal_rate: 0.4,
                                              fuel_oil_marginal_rate: 0.5,
                                              coal_marginal_rate: 0.6,
                                              wood_marginal_rate: 0.7,
                                              wood_pellets_marginal_rate: 0.8,
                                              pv_compensation_type: pv_compensation_type,
                                              pv_net_metering_annual_excess_sellback_rate_type: HPXML::PVAnnualExcessSellbackRateTypeRetailElectricityCost,
                                              pv_net_metering_annual_excess_sellback_rate: 0.04,
                                              pv_feed_in_tariff_rate: 0.15,
                                              pv_monthly_grid_connection_fee_dollars: 3)
    end
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    scenarios = hpxml_default.header.utility_bill_scenarios
    _test_default_bills_values(scenarios[0], 8, 9, 10, 11, 12, 13, 14, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, HPXML::PVCompensationTypeNetMetering, HPXML::PVAnnualExcessSellbackRateTypeRetailElectricityCost, nil, nil, nil, 3)
    _test_default_bills_values(scenarios[1], 8, 9, 10, 11, 12, 13, 14, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, HPXML::PVCompensationTypeFeedInTariff, nil, nil, 0.15, nil, 3)

    # Test defaults
    hpxml.header.utility_bill_scenarios.each do |scenario|
      scenario.elec_fixed_charge = nil
      scenario.natural_gas_fixed_charge = nil
      scenario.propane_fixed_charge = nil
      scenario.fuel_oil_fixed_charge = nil
      scenario.coal_fixed_charge = nil
      scenario.wood_fixed_charge = nil
      scenario.wood_pellets_fixed_charge = nil
      scenario.elec_marginal_rate = nil
      scenario.natural_gas_marginal_rate = nil
      scenario.propane_marginal_rate = nil
      scenario.fuel_oil_marginal_rate = nil
      scenario.coal_marginal_rate = nil
      scenario.wood_marginal_rate = nil
      scenario.wood_pellets_marginal_rate = nil
      scenario.pv_compensation_type = nil
      scenario.pv_net_metering_annual_excess_sellback_rate_type = nil
      scenario.pv_net_metering_annual_excess_sellback_rate = nil
      scenario.pv_feed_in_tariff_rate = nil
      scenario.pv_monthly_grid_connection_fee_dollars_per_kw = nil
      scenario.pv_monthly_grid_connection_fee_dollars = nil
    end
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    hpxml_default.header.utility_bill_scenarios.each do |scenario|
      _test_default_bills_values(scenario, 12, 12, nil, nil, nil, nil, nil, 0.11362695139911635, 0.7169975308418142, nil, nil, nil, nil, nil, HPXML::PVCompensationTypeNetMetering, HPXML::PVAnnualExcessSellbackRateTypeUserSpecified, 0.03, nil, nil, 0)
    end

    # Test defaults w/ electricity JSON file
    hpxml.header.utility_bill_scenarios.each do |scenario|
      scenario.elec_tariff_filepath = File.join(File.dirname(__FILE__), '..', '..', 'ReportUtilityBills', 'resources', 'detailed_rates', 'Sample Tiered Rate.json')
    end
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    hpxml_default.header.utility_bill_scenarios.each do |scenario|
      _test_default_bills_values(scenario, nil, 12, nil, nil, nil, nil, nil, nil, 0.7169975308418142, nil, nil, nil, nil, nil, HPXML::PVCompensationTypeNetMetering, HPXML::PVAnnualExcessSellbackRateTypeUserSpecified, 0.03, nil, nil, 0)
    end
  end

  def test_site
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base.xml')
    hpxml.site.site_type = HPXML::SiteTypeRural
    hpxml.site.shielding_of_home = HPXML::ShieldingExposed
    hpxml.site.ground_conductivity = 0.8
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_site_values(hpxml_default, HPXML::SiteTypeRural, HPXML::ShieldingExposed, 0.8)

    # Test defaults
    hpxml.site.site_type = nil
    hpxml.site.shielding_of_home = nil
    hpxml.site.ground_conductivity = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_site_values(hpxml_default, HPXML::SiteTypeSuburban, HPXML::ShieldingNormal, 1.0)
  end

  def test_neighbor_buildings
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base-misc-neighbor-shading.xml')
    hpxml.neighbor_buildings[0].azimuth = 123
    hpxml.neighbor_buildings[1].azimuth = 321
    hpxml.walls[0].azimuth = 123
    hpxml.walls[1].azimuth = 321
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_neighbor_building_values(hpxml_default, [123, 321])

    # Test defaults
    hpxml.neighbor_buildings[0].azimuth = nil
    hpxml.neighbor_buildings[1].azimuth = nil
    hpxml.neighbor_buildings[0].orientation = HPXML::OrientationEast
    hpxml.neighbor_buildings[1].orientation = HPXML::OrientationNorth
    hpxml.walls[0].azimuth = 90
    hpxml.walls[1].azimuth = 0
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_neighbor_building_values(hpxml_default, [90, 0])
  end

  def test_occupancy
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base.xml')
    hpxml.building_occupancy.weekday_fractions = ConstantDaySchedule
    hpxml.building_occupancy.weekend_fractions = ConstantDaySchedule
    hpxml.building_occupancy.monthly_multipliers = ConstantMonthSchedule
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_occupancy_values(hpxml_default, ConstantDaySchedule, ConstantDaySchedule, ConstantMonthSchedule)

    # Test defaults
    hpxml.building_occupancy.weekday_fractions = nil
    hpxml.building_occupancy.weekend_fractions = nil
    hpxml.building_occupancy.monthly_multipliers = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_occupancy_values(hpxml_default, Schedule.OccupantsWeekdayFractions, Schedule.OccupantsWeekendFractions, Schedule.OccupantsMonthlyMultipliers)
  end

  def test_building_construction
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base.xml')
    hpxml.building_construction.number_of_bathrooms = 4
    hpxml.building_construction.conditioned_building_volume = 20000
    hpxml.building_construction.average_ceiling_height = 7
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_building_construction_values(hpxml_default, 20000, 7, 4)

    # Test defaults
    hpxml.building_construction.conditioned_building_volume = nil
    hpxml.building_construction.average_ceiling_height = nil
    hpxml.building_construction.number_of_bathrooms = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_building_construction_values(hpxml_default, 21600, 8, 2)

    # Test defaults w/ average ceiling height
    hpxml.building_construction.conditioned_building_volume = nil
    hpxml.building_construction.average_ceiling_height = 10
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_building_construction_values(hpxml_default, 27000, 10, 2)

    # Test defaults w/ conditioned building volume
    hpxml.building_construction.conditioned_building_volume = 20000
    hpxml.building_construction.average_ceiling_height = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_building_construction_values(hpxml_default, 20000, 7.4, 2)

    # Test defaults w/ infiltration volume
    hpxml.building_construction.conditioned_building_volume = nil
    hpxml.air_infiltration_measurements[0].infiltration_volume = 25650
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_building_construction_values(hpxml_default, 21600, 8, 2)

    # Test defaults w/ infiltration volume
    hpxml.building_construction.conditioned_building_volume = nil
    hpxml.air_infiltration_measurements[0].infiltration_volume = 18000
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_building_construction_values(hpxml_default, 18000, 6.67, 2)

    # Test defaults w/ conditioned crawlspace
    hpxml = _create_hpxml('base-foundation-conditioned-crawlspace.xml')
    hpxml.building_construction.conditioned_building_volume = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_building_construction_values(hpxml_default, 16200, 8, 2)
  end

  def test_climate_and_risk_zones
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base.xml')
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].year = 2009
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone = '2B'
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_climate_and_risk_zones_values(hpxml_default, 2009, '2B')

    # Test defaults
    hpxml.climate_and_risk_zones.climate_zone_ieccs[0].delete
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_climate_and_risk_zones_values(hpxml_default, 2006, '5B')

    # Test defaults - invalid IECC zone
    hpxml = _create_hpxml('base-location-capetown-zaf.xml')
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_climate_and_risk_zones_values(hpxml_default, nil, nil)
  end

  def test_infiltration
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base.xml')
    hpxml.air_infiltration_measurements[0].infiltration_volume = 25000
    hpxml.air_infiltration.has_flue_or_chimney_in_conditioned_space = true
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_infiltration_values(hpxml_default, 25000, true)

    # Test defaults w/ conditioned basement
    hpxml.air_infiltration_measurements[0].infiltration_volume = nil
    hpxml.air_infiltration.has_flue_or_chimney_in_conditioned_space = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_infiltration_values(hpxml_default, 2700 * 8, false)

    # Test defaults w/ conditioned basement and atmospheric water heater w/ flue
    hpxml.water_heating_systems[0].fuel_type = HPXML::FuelTypeNaturalGas
    hpxml.water_heating_systems[0].energy_factor = 0.6
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_infiltration_values(hpxml_default, 2700 * 8, true)

    # Test defaults w/o conditioned basement
    hpxml = _create_hpxml('base-foundation-slab.xml')
    hpxml.air_infiltration_measurements[0].infiltration_volume = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_infiltration_values(hpxml_default, 1350 * 8, false)

    # Test defaults w/ conditioned crawlspace
    hpxml = _create_hpxml('base-foundation-conditioned-crawlspace.xml')
    hpxml.air_infiltration_measurements[0].infiltration_volume = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_infiltration_values(hpxml_default, 1350 * 12, false)
  end

  def test_infiltration_compartmentaliztion_test_adjustment
    # Test single-family detached
    hpxml = _create_hpxml('base.xml')
    hpxml.air_infiltration_measurements[0].infiltration_type = HPXML::InfiltrationTypeUnitTotal
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_infiltration_compartmentalization_test_values(hpxml_default.air_infiltration_measurements[0], nil)

    # Test single-family attached not overridden by defaults
    hpxml = _create_hpxml('base-bldgtype-attached.xml')
    hpxml.air_infiltration_measurements[0].infiltration_type = HPXML::InfiltrationTypeUnitTotal
    hpxml.air_infiltration_measurements[0].a_ext = 0.5
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_infiltration_compartmentalization_test_values(hpxml_default.air_infiltration_measurements[0], 0.5)

    # Test single-family attached defaults
    hpxml.air_infiltration_measurements[0].a_ext = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_infiltration_compartmentalization_test_values(hpxml_default.air_infiltration_measurements[0], 0.840)

    hpxml.attics[0].within_infiltration_volume = true
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_infiltration_compartmentalization_test_values(hpxml_default.air_infiltration_measurements[0], 0.817)

    # Test multifamily not overridden by defaults
    hpxml = _create_hpxml('base-bldgtype-multifamily.xml')
    hpxml.air_infiltration_measurements[0].infiltration_type = HPXML::InfiltrationTypeUnitTotal
    hpxml.air_infiltration_measurements[0].a_ext = 0.5
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_infiltration_compartmentalization_test_values(hpxml_default.air_infiltration_measurements[0], 0.5)

    # Test multifamily defaults
    hpxml.air_infiltration_measurements[0].a_ext = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_infiltration_compartmentalization_test_values(hpxml_default.air_infiltration_measurements[0], 0.247)
  end

  def test_attics
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base-atticroof-vented.xml')
    hpxml.attics[0].vented_attic_sla = 0.001
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_attic_values(hpxml_default.attics[0], 0.001)

    # Test defaults
    hpxml.attics[0].vented_attic_sla = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_attic_values(hpxml_default.attics[0], 1.0 / 300.0)

    # Test defaults w/o Attic element
    hpxml.attics[0].delete
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_attic_values(hpxml_default.attics[0], 1.0 / 300.0)
  end

  def test_foundations
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base-foundation-vented-crawlspace.xml')
    hpxml.foundations[0].vented_crawlspace_sla = 0.001
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_foundation_values(hpxml_default.foundations[0], 0.001)

    # Test defaults
    hpxml.foundations[0].vented_crawlspace_sla = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_foundation_values(hpxml_default.foundations[0], 1.0 / 150.0)

    # Test defaults w/o Foundation element
    hpxml.foundations[0].delete
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_foundation_values(hpxml_default.foundations[0], 1.0 / 150.0)
  end

  def test_roofs
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base-atticroof-radiant-barrier.xml')
    hpxml.roofs[0].roof_type = HPXML::RoofTypeMetal
    hpxml.roofs[0].solar_absorptance = 0.77
    hpxml.roofs[0].roof_color = HPXML::ColorDark
    hpxml.roofs[0].emittance = 0.88
    hpxml.roofs[0].interior_finish_type = HPXML::InteriorFinishPlaster
    hpxml.roofs[0].interior_finish_thickness = 0.25
    hpxml.roofs[0].azimuth = 123
    hpxml.roofs[0].radiant_barrier_grade = 3
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_roof_values(hpxml_default.roofs[0], HPXML::RoofTypeMetal, 0.77, HPXML::ColorDark, 0.88, true, 3, HPXML::InteriorFinishPlaster, 0.25, 123)

    # Test defaults w/ RoofColor
    hpxml.roofs[0].roof_type = nil
    hpxml.roofs[0].solar_absorptance = nil
    hpxml.roofs[0].roof_color = HPXML::ColorLight
    hpxml.roofs[0].emittance = nil
    hpxml.roofs[0].interior_finish_thickness = nil
    hpxml.roofs[0].orientation = HPXML::OrientationNortheast
    hpxml.roofs[0].azimuth = nil
    hpxml.roofs[0].radiant_barrier_grade = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_roof_values(hpxml_default.roofs[0], HPXML::RoofTypeAsphaltShingles, 0.75, HPXML::ColorLight, 0.90, true, 1, HPXML::InteriorFinishPlaster, 0.5, 45)

    # Test defaults w/ SolarAbsorptance
    hpxml.roofs[0].solar_absorptance = 0.99
    hpxml.roofs[0].roof_color = nil
    hpxml.roofs[0].interior_finish_type = nil
    hpxml.roofs[0].radiant_barrier = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_roof_values(hpxml_default.roofs[0], HPXML::RoofTypeAsphaltShingles, 0.99, HPXML::ColorDark, 0.90, false, nil, HPXML::InteriorFinishNone, nil, 45)

    # Test defaults w/o RoofColor & SolarAbsorptance
    hpxml.roofs[0].solar_absorptance = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_roof_values(hpxml_default.roofs[0], HPXML::RoofTypeAsphaltShingles, 0.85, HPXML::ColorMedium, 0.90, false, nil, HPXML::InteriorFinishNone, nil, 45)

    # Test defaults w/ conditioned space
    hpxml = _create_hpxml('base-atticroof-cathedral.xml')
    hpxml.roofs[0].roof_type = nil
    hpxml.roofs[0].solar_absorptance = nil
    hpxml.roofs[0].roof_color = HPXML::ColorLight
    hpxml.roofs[0].emittance = nil
    hpxml.roofs[0].interior_finish_type = nil
    hpxml.roofs[0].interior_finish_thickness = nil
    hpxml.roofs[0].orientation = HPXML::OrientationNortheast
    hpxml.roofs[0].azimuth = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_roof_values(hpxml_default.roofs[0], HPXML::RoofTypeAsphaltShingles, 0.75, HPXML::ColorLight, 0.90, false, nil, HPXML::InteriorFinishGypsumBoard, 0.5, 45)
  end

  def test_rim_joists
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base.xml')
    hpxml.rim_joists[0].siding = HPXML::SidingTypeBrick
    hpxml.rim_joists[0].solar_absorptance = 0.55
    hpxml.rim_joists[0].color = HPXML::ColorLight
    hpxml.rim_joists[0].emittance = 0.88
    hpxml.rim_joists[0].azimuth = 123
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_rim_joist_values(hpxml_default.rim_joists[0], HPXML::SidingTypeBrick, 0.55, HPXML::ColorLight, 0.88, 123)

    # Test defaults w/ Color
    hpxml.rim_joists[0].siding = nil
    hpxml.rim_joists[0].solar_absorptance = nil
    hpxml.rim_joists[0].color = HPXML::ColorDark
    hpxml.rim_joists[0].emittance = nil
    hpxml.rim_joists[0].orientation = HPXML::OrientationNorthwest
    hpxml.rim_joists[0].azimuth = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_rim_joist_values(hpxml_default.rim_joists[0], HPXML::SidingTypeWood, 0.95, HPXML::ColorDark, 0.90, 315)

    # Test defaults w/ SolarAbsorptance
    hpxml.rim_joists[0].solar_absorptance = 0.99
    hpxml.rim_joists[0].color = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_rim_joist_values(hpxml_default.rim_joists[0], HPXML::SidingTypeWood, 0.99, HPXML::ColorDark, 0.90, 315)

    # Test defaults w/o Color & SolarAbsorptance
    hpxml.rim_joists[0].solar_absorptance = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_rim_joist_values(hpxml_default.rim_joists[0], HPXML::SidingTypeWood, 0.7, HPXML::ColorMedium, 0.90, 315)
  end

  def test_walls
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base.xml')
    hpxml.walls[0].siding = HPXML::SidingTypeFiberCement
    hpxml.walls[0].solar_absorptance = 0.66
    hpxml.walls[0].color = HPXML::ColorDark
    hpxml.walls[0].emittance = 0.88
    hpxml.walls[0].interior_finish_type = HPXML::InteriorFinishWood
    hpxml.walls[0].interior_finish_thickness = 0.75
    hpxml.walls[0].azimuth = 123
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_wall_values(hpxml_default.walls[0], HPXML::SidingTypeFiberCement, 0.66, HPXML::ColorDark, 0.88, HPXML::InteriorFinishWood, 0.75, 123)

    # Test defaults w/ Color
    hpxml.walls[0].siding = nil
    hpxml.walls[0].solar_absorptance = nil
    hpxml.walls[0].color = HPXML::ColorLight
    hpxml.walls[0].emittance = nil
    hpxml.walls[0].interior_finish_type = HPXML::InteriorFinishWood
    hpxml.walls[0].interior_finish_thickness = nil
    hpxml.walls[0].orientation = HPXML::OrientationSouth
    hpxml.walls[0].azimuth = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_wall_values(hpxml_default.walls[0], HPXML::SidingTypeWood, 0.5, HPXML::ColorLight, 0.90, HPXML::InteriorFinishWood, 0.5, 180)

    # Test defaults w/ SolarAbsorptance
    hpxml.walls[0].solar_absorptance = 0.99
    hpxml.walls[0].color = nil
    hpxml.walls[0].interior_finish_type = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_wall_values(hpxml_default.walls[0], HPXML::SidingTypeWood, 0.99, HPXML::ColorDark, 0.90, HPXML::InteriorFinishGypsumBoard, 0.5, 180)

    # Test defaults w/o Color & SolarAbsorptance
    hpxml.walls[0].solar_absorptance = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_wall_values(hpxml_default.walls[0], HPXML::SidingTypeWood, 0.7, HPXML::ColorMedium, 0.90, HPXML::InteriorFinishGypsumBoard, 0.5, 180)

    # Test defaults w/ unconditioned space
    hpxml.walls[1].siding = nil
    hpxml.walls[1].solar_absorptance = nil
    hpxml.walls[1].color = HPXML::ColorLight
    hpxml.walls[1].emittance = nil
    hpxml.walls[1].interior_finish_type = nil
    hpxml.walls[1].interior_finish_thickness = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_wall_values(hpxml_default.walls[1], HPXML::SidingTypeWood, 0.5, HPXML::ColorLight, 0.90, HPXML::InteriorFinishNone, nil, nil)
  end

  def test_foundation_walls
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base.xml')
    hpxml.foundation_walls[0].thickness = 7.0
    hpxml.foundation_walls[0].interior_finish_type = HPXML::InteriorFinishGypsumCompositeBoard
    hpxml.foundation_walls[0].interior_finish_thickness = 0.625
    hpxml.foundation_walls[0].azimuth = 123
    hpxml.foundation_walls[0].area = 789
    hpxml.foundation_walls[0].insulation_interior_distance_to_top = 0.5
    hpxml.foundation_walls[0].insulation_interior_distance_to_bottom = 7.75
    hpxml.foundation_walls[0].insulation_exterior_distance_to_top = 0.75
    hpxml.foundation_walls[0].insulation_exterior_distance_to_bottom = 7.5
    hpxml.foundation_walls[0].type = HPXML::FoundationWallTypeConcreteBlock
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_foundation_wall_values(hpxml_default.foundation_walls[0], 7.0, HPXML::InteriorFinishGypsumCompositeBoard, 0.625, 123,
                                         789, 0.5, 7.75, 0.75, 7.5, HPXML::FoundationWallTypeConcreteBlock)

    # Test defaults
    hpxml.foundation_walls[0].thickness = nil
    hpxml.foundation_walls[0].interior_finish_type = nil
    hpxml.foundation_walls[0].interior_finish_thickness = nil
    hpxml.foundation_walls[0].orientation = HPXML::OrientationSoutheast
    hpxml.foundation_walls[0].azimuth = nil
    hpxml.foundation_walls[0].area = nil
    hpxml.foundation_walls[0].length = 100
    hpxml.foundation_walls[0].insulation_interior_distance_to_bottom = nil
    hpxml.foundation_walls[0].insulation_exterior_distance_to_bottom = nil
    hpxml.foundation_walls[0].type = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_foundation_wall_values(hpxml_default.foundation_walls[0], 8.0, HPXML::InteriorFinishGypsumBoard, 0.5, 135,
                                         800, 0.5, 8.0, 0.75, 8.0, HPXML::FoundationWallTypeSolidConcrete)

    # Test defaults w/ unconditioned surfaces
    hpxml = _create_hpxml('base-foundation-unconditioned-basement.xml')
    hpxml.foundation_walls[0].thickness = nil
    hpxml.foundation_walls[0].interior_finish_type = nil
    hpxml.foundation_walls[0].interior_finish_thickness = nil
    hpxml.foundation_walls[0].orientation = HPXML::OrientationSoutheast
    hpxml.foundation_walls[0].azimuth = nil
    hpxml.foundation_walls[0].area = nil
    hpxml.foundation_walls[0].length = 100
    hpxml.foundation_walls[0].height = 10
    hpxml.foundation_walls[0].insulation_interior_distance_to_top = nil
    hpxml.foundation_walls[0].insulation_interior_distance_to_bottom = nil
    hpxml.foundation_walls[0].insulation_exterior_distance_to_top = nil
    hpxml.foundation_walls[0].insulation_exterior_distance_to_bottom = nil
    hpxml.foundation_walls[0].type = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_foundation_wall_values(hpxml_default.foundation_walls[0], 8.0, HPXML::InteriorFinishNone, nil, 135,
                                         1000, 0.0, 10.0, 0.0, 10.0, HPXML::FoundationWallTypeSolidConcrete)
  end

  def test_floors
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base.xml')
    hpxml.floors[0].interior_finish_type = HPXML::InteriorFinishWood
    hpxml.floors[0].interior_finish_thickness = 0.375
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_floor_values(hpxml_default.floors[0], HPXML::InteriorFinishWood, 0.375)

    # Test defaults w/ ceiling
    hpxml.floors[0].interior_finish_type = nil
    hpxml.floors[0].interior_finish_thickness = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_floor_values(hpxml_default.floors[0], HPXML::InteriorFinishGypsumBoard, 0.5)

    # Test defaults w/ floor
    hpxml = _create_hpxml('base-foundation-vented-crawlspace.xml')
    hpxml.floors[0].interior_finish_type = nil
    hpxml.floors[0].interior_finish_thickness = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_floor_values(hpxml_default.floors[0], HPXML::InteriorFinishNone, nil)
  end

  def test_slabs
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base.xml')
    hpxml.slabs[0].thickness = 7.0
    hpxml.slabs[0].carpet_r_value = 1.1
    hpxml.slabs[0].carpet_fraction = 0.5
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_slab_values(hpxml_default.slabs[0], 7.0, 1.1, 0.5)

    # Test defaults w/ conditioned basement
    hpxml.slabs[0].thickness = nil
    hpxml.slabs[0].carpet_r_value = nil
    hpxml.slabs[0].carpet_fraction = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_slab_values(hpxml_default.slabs[0], 4.0, 2.0, 0.8)

    # Test defaults w/ crawlspace
    hpxml = _create_hpxml('base-foundation-unvented-crawlspace.xml')
    hpxml.slabs[0].thickness = nil
    hpxml.slabs[0].carpet_r_value = nil
    hpxml.slabs[0].carpet_fraction = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_slab_values(hpxml_default.slabs[0], 0.0, 0.0, 0.0)
  end

  def test_windows
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base-enclosure-windows-shading.xml')
    hpxml.windows.each do |window|
      window.fraction_operable = 0.5
      window.exterior_shading_factor_summer = 0.44
      window.exterior_shading_factor_winter = 0.55
      window.interior_shading_factor_summer = 0.66
      window.interior_shading_factor_winter = 0.77
      window.azimuth = 123
    end
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    n_windows = hpxml_default.windows.size
    _test_default_window_values(hpxml_default, [0.44] * n_windows, [0.55] * n_windows, [0.66] * n_windows, [0.77] * n_windows, [0.5] * n_windows, [123] * n_windows)

    # Test defaults
    hpxml.windows.each do |window|
      window.fraction_operable = nil
      window.exterior_shading_factor_summer = nil
      window.exterior_shading_factor_winter = nil
      window.interior_shading_factor_summer = nil
      window.interior_shading_factor_winter = nil
      window.orientation = HPXML::OrientationSouthwest
      window.azimuth = nil
    end
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    n_windows = hpxml_default.windows.size
    _test_default_window_values(hpxml_default, [1.0] * n_windows, [1.0] * n_windows, [0.7] * n_windows, [0.85] * n_windows, [0.67] * n_windows, [225] * n_windows)
  end

  def test_windows_properties
    # Test defaults w/ single pane, aluminum frame
    hpxml = _create_hpxml('base.xml')
    hpxml.windows[0].ufactor = nil
    hpxml.windows[0].shgc = nil
    hpxml.windows[0].frame_type = HPXML::WindowFrameTypeAluminum
    hpxml.windows[0].glass_layers = HPXML::WindowLayersSinglePane
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()

    assert_equal(false, hpxml_default.windows[0].thermal_break)
    assert_equal(HPXML::WindowGlassTypeClear, hpxml_default.windows[0].glass_type)
    assert_nil(hpxml_default.windows[0].gas_fill)

    # Test defaults w/ double pane, metal frame
    hpxml = _create_hpxml('base.xml')
    hpxml.windows[0].ufactor = nil
    hpxml.windows[0].shgc = nil
    hpxml.windows[0].frame_type = HPXML::WindowFrameTypeMetal
    hpxml.windows[0].glass_layers = HPXML::WindowLayersDoublePane
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()

    assert_equal(true, hpxml_default.windows[0].thermal_break)
    assert_equal(HPXML::WindowGlassTypeClear, hpxml_default.windows[0].glass_type)
    assert_equal(HPXML::WindowGasAir, hpxml_default.windows[0].gas_fill)

    # Test defaults w/ single pane, wood frame
    hpxml = _create_hpxml('base.xml')
    hpxml.windows[0].ufactor = nil
    hpxml.windows[0].shgc = nil
    hpxml.windows[0].frame_type = HPXML::WindowFrameTypeWood
    hpxml.windows[0].glass_layers = HPXML::WindowLayersTriplePane
    hpxml.windows[0].glass_type = HPXML::WindowGlassTypeLowE
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()

    assert_nil(hpxml_default.windows[0].thermal_break)
    assert_equal(HPXML::WindowGlassTypeLowE, hpxml_default.windows[0].glass_type)
    assert_equal(HPXML::WindowGasArgon, hpxml_default.windows[0].gas_fill)

    # Test U/SHGC lookups [frame_type, thermal_break, glass_layers, glass_type, gas_fill] => [ufactor, shgc]
    tests = { [HPXML::WindowFrameTypeAluminum, false, HPXML::WindowLayersSinglePane, nil, nil] => [1.27, 0.75],
              [HPXML::WindowFrameTypeWood, nil, HPXML::WindowLayersSinglePane, nil, nil] => [0.89, 0.64],
              [HPXML::WindowFrameTypeAluminum, false, HPXML::WindowLayersSinglePane, HPXML::WindowGlassTypeTintedReflective, nil] => [1.27, 0.64],
              [HPXML::WindowFrameTypeWood, nil, HPXML::WindowLayersSinglePane, HPXML::WindowGlassTypeTintedReflective, nil] => [0.89, 0.54],
              [HPXML::WindowFrameTypeAluminum, false, HPXML::WindowLayersDoublePane, nil, HPXML::WindowGasAir] => [0.81, 0.67],
              [HPXML::WindowFrameTypeAluminum, true, HPXML::WindowLayersDoublePane, nil, HPXML::WindowGasAir] => [0.60, 0.67],
              [HPXML::WindowFrameTypeWood, nil, HPXML::WindowLayersDoublePane, nil, HPXML::WindowGasAir] => [0.51, 0.56],
              [HPXML::WindowFrameTypeAluminum, false, HPXML::WindowLayersDoublePane, HPXML::WindowGlassTypeTintedReflective, HPXML::WindowGasAir] => [0.81, 0.55],
              [HPXML::WindowFrameTypeAluminum, true, HPXML::WindowLayersDoublePane, HPXML::WindowGlassTypeTintedReflective, HPXML::WindowGasAir] => [0.60, 0.55],
              [HPXML::WindowFrameTypeWood, nil, HPXML::WindowLayersDoublePane, HPXML::WindowGlassTypeTintedReflective, HPXML::WindowGasAir] => [0.51, 0.46],
              [HPXML::WindowFrameTypeWood, nil, HPXML::WindowLayersDoublePane, HPXML::WindowGlassTypeLowE, HPXML::WindowGasAir] => [0.42, 0.52],
              [HPXML::WindowFrameTypeAluminum, true, HPXML::WindowLayersDoublePane, HPXML::WindowGlassTypeLowE, HPXML::WindowGasArgon] => [0.47, 0.62],
              [HPXML::WindowFrameTypeWood, nil, HPXML::WindowLayersDoublePane, HPXML::WindowGlassTypeLowE, HPXML::WindowGasArgon] => [0.39, 0.52],
              [HPXML::WindowFrameTypeAluminum, false, HPXML::WindowLayersDoublePane, HPXML::WindowGlassTypeReflective, HPXML::WindowGasAir] => [0.67, 0.37],
              [HPXML::WindowFrameTypeAluminum, true, HPXML::WindowLayersDoublePane, HPXML::WindowGlassTypeReflective, HPXML::WindowGasAir] => [0.47, 0.37],
              [HPXML::WindowFrameTypeWood, nil, HPXML::WindowLayersDoublePane, HPXML::WindowGlassTypeReflective, HPXML::WindowGasAir] => [0.39, 0.31],
              [HPXML::WindowFrameTypeWood, nil, HPXML::WindowLayersDoublePane, HPXML::WindowGlassTypeReflective, HPXML::WindowGasArgon] => [0.36, 0.31],
              [HPXML::WindowFrameTypeWood, nil, HPXML::WindowLayersTriplePane, HPXML::WindowGlassTypeLowE, HPXML::WindowGasArgon] => [0.27, 0.31],
              [nil, nil, HPXML::WindowLayersGlassBlock, nil, nil] => [0.60, 0.60] }
    tests.each do |k, v|
      frame_type, thermal_break, glass_layers, glass_type, gas_fill = k
      ufactor, shgc = v

      hpxml = _create_hpxml('base.xml')
      hpxml.windows[0].ufactor = nil
      hpxml.windows[0].shgc = nil
      hpxml.windows[0].frame_type = frame_type
      hpxml.windows[0].thermal_break = thermal_break
      hpxml.windows[0].glass_layers = glass_layers
      hpxml.windows[0].glass_type = glass_type
      hpxml.windows[0].gas_fill = gas_fill
      XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
      hpxml_default = _test_measure()

      assert_equal(ufactor, hpxml_default.windows[0].ufactor)
      assert_equal(shgc, hpxml_default.windows[0].shgc)
    end
  end

  def test_skylights
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base-enclosure-skylights.xml')
    hpxml.skylights.each do |skylight|
      skylight.exterior_shading_factor_summer = 0.44
      skylight.exterior_shading_factor_winter = 0.55
      skylight.interior_shading_factor_summer = 0.66
      skylight.interior_shading_factor_winter = 0.77
      skylight.azimuth = 123
    end
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    n_skylights = hpxml_default.skylights.size
    _test_default_skylight_values(hpxml_default, [0.44] * n_skylights, [0.55] * n_skylights, [0.66] * n_skylights, [0.77] * n_skylights, [123] * n_skylights)

    # Test defaults
    hpxml.skylights.each do |skylight|
      skylight.exterior_shading_factor_summer = nil
      skylight.exterior_shading_factor_winter = nil
      skylight.interior_shading_factor_summer = nil
      skylight.interior_shading_factor_winter = nil
      skylight.orientation = HPXML::OrientationWest
      skylight.azimuth = nil
    end
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    n_skylights = hpxml_default.skylights.size
    _test_default_skylight_values(hpxml_default, [1.0] * n_skylights, [1.0] * n_skylights, [1.0] * n_skylights, [1.0] * n_skylights, [270] * n_skylights)
  end

  def test_skylights_properties
    # Test defaults w/ single pane, aluminum frame
    hpxml = _create_hpxml('base-enclosure-skylights.xml')
    hpxml.skylights[0].ufactor = nil
    hpxml.skylights[0].shgc = nil
    hpxml.skylights[0].frame_type = HPXML::WindowFrameTypeAluminum
    hpxml.skylights[0].glass_layers = HPXML::WindowLayersSinglePane
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()

    assert_equal(false, hpxml_default.skylights[0].thermal_break)
    assert_equal(HPXML::WindowGlassTypeClear, hpxml_default.skylights[0].glass_type)
    assert_nil(hpxml_default.skylights[0].gas_fill)

    # Test defaults w/ double pane, metal frame
    hpxml = _create_hpxml('base-enclosure-skylights.xml')
    hpxml.skylights[0].ufactor = nil
    hpxml.skylights[0].shgc = nil
    hpxml.skylights[0].frame_type = HPXML::WindowFrameTypeMetal
    hpxml.skylights[0].glass_layers = HPXML::WindowLayersDoublePane
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()

    assert_equal(true, hpxml_default.skylights[0].thermal_break)
    assert_equal(HPXML::WindowGlassTypeClear, hpxml_default.skylights[0].glass_type)
    assert_equal(HPXML::WindowGasAir, hpxml_default.skylights[0].gas_fill)

    # Test defaults w/ single pane, wood frame
    hpxml = _create_hpxml('base-enclosure-skylights.xml')
    hpxml.skylights[0].ufactor = nil
    hpxml.skylights[0].shgc = nil
    hpxml.skylights[0].frame_type = HPXML::WindowFrameTypeWood
    hpxml.skylights[0].glass_layers = HPXML::WindowLayersTriplePane
    hpxml.skylights[0].glass_type = HPXML::WindowGlassTypeLowE
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()

    assert_nil(hpxml_default.skylights[0].thermal_break)
    assert_equal(HPXML::WindowGlassTypeLowE, hpxml_default.skylights[0].glass_type)
    assert_equal(HPXML::WindowGasArgon, hpxml_default.skylights[0].gas_fill)

    # Test U/SHGC lookups [frame_type, thermal_break, glass_layers, glass_type, gas_fill] => [ufactor, shgc]
    tests = { [HPXML::WindowFrameTypeAluminum, false, HPXML::WindowLayersSinglePane, nil, nil] => [1.98, 0.75],
              [HPXML::WindowFrameTypeWood, nil, HPXML::WindowLayersSinglePane, nil, nil] => [1.47, 0.64],
              [HPXML::WindowFrameTypeAluminum, false, HPXML::WindowLayersSinglePane, HPXML::WindowGlassTypeTintedReflective, nil] => [1.98, 0.64],
              [HPXML::WindowFrameTypeWood, nil, HPXML::WindowLayersSinglePane, HPXML::WindowGlassTypeTintedReflective, nil] => [1.47, 0.54],
              [HPXML::WindowFrameTypeAluminum, false, HPXML::WindowLayersDoublePane, nil, HPXML::WindowGasAir] => [1.30, 0.67],
              [HPXML::WindowFrameTypeAluminum, true, HPXML::WindowLayersDoublePane, nil, HPXML::WindowGasAir] => [1.10, 0.67],
              [HPXML::WindowFrameTypeWood, nil, HPXML::WindowLayersDoublePane, nil, HPXML::WindowGasAir] => [0.84, 0.56],
              [HPXML::WindowFrameTypeAluminum, false, HPXML::WindowLayersDoublePane, HPXML::WindowGlassTypeTintedReflective, HPXML::WindowGasAir] => [1.30, 0.55],
              [HPXML::WindowFrameTypeAluminum, true, HPXML::WindowLayersDoublePane, HPXML::WindowGlassTypeTintedReflective, HPXML::WindowGasAir] => [1.10, 0.55],
              [HPXML::WindowFrameTypeWood, nil, HPXML::WindowLayersDoublePane, HPXML::WindowGlassTypeTintedReflective, HPXML::WindowGasAir] => [0.84, 0.46],
              [HPXML::WindowFrameTypeWood, nil, HPXML::WindowLayersDoublePane, HPXML::WindowGlassTypeLowE, HPXML::WindowGasAir] => [0.74, 0.52],
              [HPXML::WindowFrameTypeAluminum, true, HPXML::WindowLayersDoublePane, HPXML::WindowGlassTypeLowE, HPXML::WindowGasArgon] => [0.95, 0.62],
              [HPXML::WindowFrameTypeWood, nil, HPXML::WindowLayersDoublePane, HPXML::WindowGlassTypeLowE, HPXML::WindowGasArgon] => [0.68, 0.52],
              [HPXML::WindowFrameTypeAluminum, false, HPXML::WindowLayersDoublePane, HPXML::WindowGlassTypeReflective, HPXML::WindowGasAir] => [1.17, 0.37],
              [HPXML::WindowFrameTypeAluminum, true, HPXML::WindowLayersDoublePane, HPXML::WindowGlassTypeReflective, HPXML::WindowGasAir] => [0.98, 0.37],
              [HPXML::WindowFrameTypeWood, nil, HPXML::WindowLayersDoublePane, HPXML::WindowGlassTypeReflective, HPXML::WindowGasAir] => [0.71, 0.31],
              [HPXML::WindowFrameTypeWood, nil, HPXML::WindowLayersDoublePane, HPXML::WindowGlassTypeReflective, HPXML::WindowGasArgon] => [0.65, 0.31],
              [HPXML::WindowFrameTypeWood, nil, HPXML::WindowLayersTriplePane, HPXML::WindowGlassTypeLowE, HPXML::WindowGasArgon] => [0.47, 0.31],
              [nil, nil, HPXML::WindowLayersGlassBlock, nil, nil] => [0.60, 0.60] }
    tests.each do |k, v|
      frame_type, thermal_break, glass_layers, glass_type, gas_fill = k
      ufactor, shgc = v

      hpxml = _create_hpxml('base-enclosure-skylights.xml')
      hpxml.skylights[0].ufactor = nil
      hpxml.skylights[0].shgc = nil
      hpxml.skylights[0].frame_type = frame_type
      hpxml.skylights[0].thermal_break = thermal_break
      hpxml.skylights[0].glass_layers = glass_layers
      hpxml.skylights[0].glass_type = glass_type
      hpxml.skylights[0].gas_fill = gas_fill
      XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
      hpxml_default = _test_measure()

      assert_equal(ufactor, hpxml_default.skylights[0].ufactor)
      assert_equal(shgc, hpxml_default.skylights[0].shgc)
    end
  end

  def test_doors
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base.xml')
    hpxml.doors.each_with_index do |door, i|
      door.azimuth = 35 * (i + 1)
    end
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_door_values(hpxml_default, [35, 70])

    # Test defaults w/ AttachedToWall azimuth
    hpxml.walls[0].azimuth = 89
    hpxml.doors.each do |door|
      door.azimuth = nil
    end
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_door_values(hpxml_default, [89, 89])

    # Test defaults w/o AttachedToWall azimuth
    hpxml.walls[0].azimuth = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_door_values(hpxml_default, [0, 0])

    # Test defaults w/ Orientation
    hpxml.doors.each do |door|
      door.orientation = HPXML::OrientationEast
    end
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_door_values(hpxml_default, [90, 90])
  end

  def test_thermal_mass
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base-enclosure-thermal-mass.xml')
    hpxml.partition_wall_mass.area_fraction = 0.5
    hpxml.partition_wall_mass.interior_finish_thickness = 0.75
    hpxml.partition_wall_mass.interior_finish_type = HPXML::InteriorFinishWood
    hpxml.furniture_mass.area_fraction = 0.75
    hpxml.furniture_mass.type = HPXML::FurnitureMassTypeHeavyWeight
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_partition_wall_mass_values(hpxml_default.partition_wall_mass, 0.5, HPXML::InteriorFinishWood, 0.75)
    _test_default_furniture_mass_values(hpxml_default.furniture_mass, 0.75, HPXML::FurnitureMassTypeHeavyWeight)

    # Test defaults
    hpxml.partition_wall_mass.area_fraction = nil
    hpxml.partition_wall_mass.interior_finish_thickness = nil
    hpxml.partition_wall_mass.interior_finish_type = nil
    hpxml.furniture_mass.area_fraction = nil
    hpxml.furniture_mass.type = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_partition_wall_mass_values(hpxml_default.partition_wall_mass, 1.0, HPXML::InteriorFinishGypsumBoard, 0.5)
    _test_default_furniture_mass_values(hpxml_default.furniture_mass, 0.4, HPXML::FurnitureMassTypeLightWeight)
  end

  def test_central_air_conditioners
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base-hvac-central-ac-only-1-speed.xml')
    hpxml.cooling_systems[0].cooling_shr = 0.88
    hpxml.cooling_systems[0].compressor_type = HPXML::HVACCompressorTypeVariableSpeed
    hpxml.cooling_systems[0].fan_watts_per_cfm = 0.66
    hpxml.cooling_systems[0].charge_defect_ratio = -0.11
    hpxml.cooling_systems[0].airflow_defect_ratio = -0.22
    hpxml.cooling_systems[0].cooling_capacity = 12345
    hpxml.cooling_systems[0].cooling_efficiency_seer = 12.0
    hpxml.cooling_systems[0].crankcase_heater_watts = 40.0
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_central_air_conditioner_values(hpxml_default.cooling_systems[0], 0.88, HPXML::HVACCompressorTypeVariableSpeed, 0.66, -0.11, -0.22, 12345, 12.0, 40.0)

    # Test defaults - SEER2
    hpxml.cooling_systems[0].cooling_efficiency_seer = nil
    hpxml.cooling_systems[0].cooling_efficiency_seer2 = 11.4
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_central_air_conditioner_values(hpxml_default.cooling_systems[0], 0.88, HPXML::HVACCompressorTypeVariableSpeed, 0.66, -0.11, -0.22, 12345, 12.0, 40.0)

    # Test defaults
    hpxml.cooling_systems[0].cooling_shr = nil
    hpxml.cooling_systems[0].compressor_type = nil
    hpxml.cooling_systems[0].fan_watts_per_cfm = nil
    hpxml.cooling_systems[0].charge_defect_ratio = nil
    hpxml.cooling_systems[0].airflow_defect_ratio = nil
    hpxml.cooling_systems[0].cooling_capacity = nil
    hpxml.cooling_systems[0].crankcase_heater_watts = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_central_air_conditioner_values(hpxml_default.cooling_systems[0], 0.73, HPXML::HVACCompressorTypeSingleStage, 0.5, 0, 0, nil, 12.0, 50.0)
  end

  def test_room_air_conditioners
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base-hvac-room-ac-only.xml')
    hpxml.cooling_systems[0].cooling_shr = 0.88
    hpxml.cooling_systems[0].cooling_capacity = 12345
    hpxml.cooling_systems[0].crankcase_heater_watts = 40.0
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_room_air_conditioner_ptac_values(hpxml_default.cooling_systems[0], 0.88, 12345, 40.0)

    # Test defaults
    hpxml.cooling_systems[0].cooling_shr = nil
    hpxml.cooling_systems[0].cooling_capacity = nil
    hpxml.cooling_systems[0].crankcase_heater_watts = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_room_air_conditioner_ptac_values(hpxml_default.cooling_systems[0], 0.65, nil, 0.0)
  end

  def test_evaporative_coolers
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base-hvac-evap-cooler-only.xml')
    hpxml.cooling_systems[0].cooling_capacity = 12345
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_evap_cooler_values(hpxml_default.cooling_systems[0], 12345)

    # Test defaults
    hpxml.cooling_systems[0].cooling_capacity = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_evap_cooler_values(hpxml_default.cooling_systems[0], nil)
  end

  def test_mini_split_air_conditioners
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base-hvac-mini-split-air-conditioner-only-ducted.xml')
    hpxml.cooling_systems[0].cooling_shr = 0.78
    hpxml.cooling_systems[0].fan_watts_per_cfm = 0.66
    hpxml.cooling_systems[0].charge_defect_ratio = -0.11
    hpxml.cooling_systems[0].airflow_defect_ratio = -0.22
    hpxml.cooling_systems[0].cooling_capacity = 12345
    hpxml.cooling_systems[0].crankcase_heater_watts = 40.0
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_mini_split_air_conditioner_values(hpxml_default.cooling_systems[0], 0.78, 0.66, -0.11, -0.22, 12345, 19.0, 40.0)

    # Test defaults
    hpxml.cooling_systems[0].cooling_shr = nil
    hpxml.cooling_systems[0].fan_watts_per_cfm = nil
    hpxml.cooling_systems[0].charge_defect_ratio = nil
    hpxml.cooling_systems[0].airflow_defect_ratio = nil
    hpxml.cooling_systems[0].cooling_capacity = nil
    hpxml.cooling_systems[0].crankcase_heater_watts = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_mini_split_air_conditioner_values(hpxml_default.cooling_systems[0], 0.73, 0.18, 0, 0, nil, 19.0, 50.0)

    # Test defaults w/ ductless
    hpxml.cooling_systems[0].distribution_system.delete
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_mini_split_air_conditioner_values(hpxml_default.cooling_systems[0], 0.73, 0.07, 0, 0, nil, 19.0, 50.0)

    # Test defaults w/ ductless - SEER2
    hpxml.cooling_systems[0].cooling_efficiency_seer = nil
    hpxml.cooling_systems[0].cooling_efficiency_seer2 = 13.3
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_mini_split_air_conditioner_values(hpxml_default.cooling_systems[0], 0.73, 0.07, 0, 0, nil, 13.3, 50.0)
  end

  def test_ptac
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base-hvac-ptac-with-heating-electricity.xml')
    hpxml.cooling_systems[0].cooling_shr = 0.75
    hpxml.cooling_systems[0].cooling_capacity = 12345
    hpxml.cooling_systems[0].crankcase_heater_watts = 40.0
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_room_air_conditioner_ptac_values(hpxml_default.cooling_systems[0], 0.75, 12345, 40.0)

    # Test defaults
    hpxml.cooling_systems[0].cooling_shr = nil
    hpxml.cooling_systems[0].cooling_capacity = nil
    hpxml.cooling_systems[0].crankcase_heater_watts = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_room_air_conditioner_ptac_values(hpxml_default.cooling_systems[0], 0.65, nil, 0.0)
  end

  def test_furnaces
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base.xml')
    hpxml.heating_systems[0].fan_watts_per_cfm = 0.66
    hpxml.heating_systems[0].airflow_defect_ratio = -0.22
    hpxml.heating_systems[0].heating_capacity = 12345
    hpxml.heating_systems[0].pilot_light = true
    hpxml.heating_systems[0].pilot_light_btuh = 999
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_furnace_values(hpxml_default.heating_systems[0], 0.66, -0.22, 12345, true, 999)

    # Test defaults
    hpxml.heating_systems[0].fan_watts_per_cfm = nil
    hpxml.heating_systems[0].airflow_defect_ratio = nil
    hpxml.heating_systems[0].heating_capacity = nil
    hpxml.heating_systems[0].pilot_light_btuh = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_furnace_values(hpxml_default.heating_systems[0], 0.375, 0, nil, true, 500)

    # Test defaults w/o pilot
    hpxml.heating_systems[0].pilot_light = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_furnace_values(hpxml_default.heating_systems[0], 0.375, 0, nil, false, nil)

    # Test defaults w/ gravity distribution system
    hpxml = _create_hpxml('base-hvac-furnace-gas-only.xml')
    hpxml.heating_systems[0].distribution_system.air_type = HPXML::AirTypeGravity
    hpxml.heating_systems[0].fan_watts_per_cfm = nil
    hpxml.heating_systems[0].airflow_defect_ratio = nil
    hpxml.heating_systems[0].heating_capacity = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_furnace_values(hpxml_default.heating_systems[0], 0.0, 0, nil, false, nil)
  end

  def test_wall_furnaces
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base-hvac-wall-furnace-elec-only.xml')
    hpxml.heating_systems[0].fan_watts = 22
    hpxml.heating_systems[0].heating_capacity = 12345
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_wall_furnace_values(hpxml_default.heating_systems[0], 22, 12345)

    # Test defaults
    hpxml.heating_systems[0].fan_watts = nil
    hpxml.heating_systems[0].heating_capacity = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_wall_furnace_values(hpxml_default.heating_systems[0], 0, nil)

    # Test defaults w/o pilot
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_wall_furnace_values(hpxml_default.heating_systems[0], 0, nil)
  end

  def test_floor_furnaces
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base-hvac-floor-furnace-propane-only.xml')
    hpxml.heating_systems[0].fan_watts = 22
    hpxml.heating_systems[0].heating_capacity = 12345
    hpxml.heating_systems[0].pilot_light = true
    hpxml.heating_systems[0].pilot_light_btuh = 999
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_floor_furnace_values(hpxml_default.heating_systems[0], 22, 12345, true, 999)

    # Test defaults
    hpxml.heating_systems[0].fan_watts = nil
    hpxml.heating_systems[0].pilot_light_btuh = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_floor_furnace_values(hpxml_default.heating_systems[0], 0, nil, true, 500)

    # Test defaults w/o pilot
    hpxml.heating_systems[0].pilot_light = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_floor_furnace_values(hpxml_default.heating_systems[0], 0, nil, false, nil)
  end

  def test_boilers
    # Test inputs not overridden by defaults (in-unit boiler)
    hpxml = _create_hpxml('base-hvac-boiler-gas-only.xml')
    hpxml.heating_systems[0].electric_auxiliary_energy = 99.9
    hpxml.heating_systems[0].heating_capacity = 12345
    hpxml.heating_systems[0].pilot_light = true
    hpxml.heating_systems[0].pilot_light_btuh = 999
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_boiler_values(hpxml_default.heating_systems[0], 99.9, 12345, true, 999)

    # Test defaults w/ in-unit boiler
    hpxml.heating_systems[0].electric_auxiliary_energy = nil
    hpxml.heating_systems[0].heating_capacity = nil
    hpxml.heating_systems[0].pilot_light_btuh = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_boiler_values(hpxml_default.heating_systems[0], 170.0, nil, true, 500)

    # Test inputs not overridden by defaults (shared boiler)
    hpxml = _create_hpxml('base-bldgtype-multifamily-shared-boiler-only-baseboard.xml')
    hpxml.heating_systems[0].shared_loop_watts = nil
    hpxml.heating_systems[0].electric_auxiliary_energy = 99.9
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_boiler_values(hpxml_default.heating_systems[0], 99.9, nil, false, nil)
  end

  def test_stoves
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base-hvac-stove-oil-only.xml')
    hpxml.heating_systems[0].fan_watts = 22
    hpxml.heating_systems[0].heating_capacity = 12345
    hpxml.heating_systems[0].pilot_light = true
    hpxml.heating_systems[0].pilot_light_btuh = 999
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_stove_values(hpxml_default.heating_systems[0], 22, 12345, true, 999)

    # Test defaults
    hpxml.heating_systems[0].fan_watts = nil
    hpxml.heating_systems[0].heating_capacity = nil
    hpxml.heating_systems[0].pilot_light_btuh = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_stove_values(hpxml_default.heating_systems[0], 40, nil, true, 500)

    # Test defaults w/o pilot
    hpxml.heating_systems[0].pilot_light = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_stove_values(hpxml_default.heating_systems[0], 40, nil, false, nil)
  end

  def test_portable_heaters
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base-hvac-portable-heater-gas-only.xml')
    hpxml.heating_systems[0].fan_watts = 22
    hpxml.heating_systems[0].heating_capacity = 12345
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_portable_heater_values(hpxml_default.heating_systems[0], 22, 12345)

    # Test defaults
    hpxml.heating_systems[0].fan_watts = nil
    hpxml.heating_systems[0].heating_capacity = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_portable_heater_values(hpxml_default.heating_systems[0], 0, nil)
  end

  def test_fixed_heaters
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base-hvac-fixed-heater-gas-only.xml')
    hpxml.heating_systems[0].fan_watts = 22
    hpxml.heating_systems[0].heating_capacity = 12345
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_fixed_heater_values(hpxml_default.heating_systems[0], 22, 12345)

    # Test defaults
    hpxml.heating_systems[0].fan_watts = nil
    hpxml.heating_systems[0].heating_capacity = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_fixed_heater_values(hpxml_default.heating_systems[0], 0, nil)
  end

  def test_fireplaces
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base-hvac-fireplace-wood-only.xml')
    hpxml.heating_systems[0].fan_watts = 22
    hpxml.heating_systems[0].heating_capacity = 12345
    hpxml.heating_systems[0].pilot_light = true
    hpxml.heating_systems[0].pilot_light_btuh = 999
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_fireplace_values(hpxml_default.heating_systems[0], 22, 12345, true, 999)

    # Test defaults
    hpxml.heating_systems[0].fan_watts = nil
    hpxml.heating_systems[0].heating_capacity = nil
    hpxml.heating_systems[0].pilot_light_btuh = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_fireplace_values(hpxml_default.heating_systems[0], 0, nil, true, 500)

    # Test defaults w/o pilot
    hpxml.heating_systems[0].pilot_light = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_fireplace_values(hpxml_default.heating_systems[0], 0, nil, false, nil)
  end

  def test_air_source_heat_pumps
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base-hvac-air-to-air-heat-pump-1-speed.xml')
    hpxml.heat_pumps[0].cooling_shr = 0.88
    hpxml.heat_pumps[0].compressor_type = HPXML::HVACCompressorTypeVariableSpeed
    hpxml.heat_pumps[0].fan_watts_per_cfm = 0.66
    hpxml.heat_pumps[0].charge_defect_ratio = -0.11
    hpxml.heat_pumps[0].airflow_defect_ratio = -0.22
    hpxml.heat_pumps[0].cooling_capacity = 12345
    hpxml.heat_pumps[0].heating_capacity = 23456
    hpxml.heat_pumps[0].backup_heating_capacity = 34567
    hpxml.heat_pumps[0].cooling_efficiency_seer = 14.0
    hpxml.heat_pumps[0].heating_efficiency_hspf = 8.0
    hpxml.heat_pumps[0].heating_capacity_retention_fraction = 0.1
    hpxml.heat_pumps[0].heating_capacity_retention_temp = 2.0
    hpxml.heat_pumps[0].crankcase_heater_watts = 40.0
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_air_to_air_heat_pump_values(hpxml_default.heat_pumps[0], 0.88, HPXML::HVACCompressorTypeVariableSpeed, 0.66, -0.11, -0.22, 12345, 23456, nil, 34567, 14.0, 8.0, 0.1, 2.0, 40.0)

    # Test w/ heating capacity 17F
    hpxml.heat_pumps[0].heating_capacity_17F = 9876
    hpxml.heat_pumps[0].heating_capacity_retention_fraction = nil
    hpxml.heat_pumps[0].heating_capacity_retention_temp = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_air_to_air_heat_pump_values(hpxml_default.heat_pumps[0], 0.88, HPXML::HVACCompressorTypeVariableSpeed, 0.66, -0.11, -0.22, 12345, 23456, 9876, 34567, 14.0, 8.0, nil, nil, 40.0)

    # Test defaults - SEER2/HSPF2
    hpxml.heat_pumps[0].cooling_efficiency_seer = nil
    hpxml.heat_pumps[0].cooling_efficiency_seer2 = 13.3
    hpxml.heat_pumps[0].heating_efficiency_hspf = nil
    hpxml.heat_pumps[0].heating_efficiency_hspf2 = 6.8
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_air_to_air_heat_pump_values(hpxml_default.heat_pumps[0], 0.88, HPXML::HVACCompressorTypeVariableSpeed, 0.66, -0.11, -0.22, 12345, 23456, 9876, 34567, 14.0, 8.0, nil, nil, 40.0)

    # Test defaults
    hpxml.heat_pumps[0].cooling_shr = nil
    hpxml.heat_pumps[0].compressor_type = nil
    hpxml.heat_pumps[0].fan_watts_per_cfm = nil
    hpxml.heat_pumps[0].charge_defect_ratio = nil
    hpxml.heat_pumps[0].airflow_defect_ratio = nil
    hpxml.heat_pumps[0].cooling_capacity = nil
    hpxml.heat_pumps[0].heating_capacity = nil
    hpxml.heat_pumps[0].heating_capacity_17F = nil
    hpxml.heat_pumps[0].backup_heating_capacity = nil
    hpxml.heat_pumps[0].crankcase_heater_watts = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_air_to_air_heat_pump_values(hpxml_default.heat_pumps[0], 0.73, HPXML::HVACCompressorTypeSingleStage, 0.5, 0, 0, nil, nil, nil, nil, 14.0, 8.0, 0.425, 5.0, 50.0)
  end

  def test_pthp
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base-hvac-pthp.xml')
    hpxml.heat_pumps[0].cooling_shr = 0.88
    hpxml.heat_pumps[0].cooling_capacity = 12345
    hpxml.heat_pumps[0].heating_capacity = 23456
    hpxml.heat_pumps[0].heating_capacity_retention_fraction = 0.1
    hpxml.heat_pumps[0].heating_capacity_retention_temp = 2.0
    hpxml.heat_pumps[0].crankcase_heater_watts = 40.0
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_pthp_values(hpxml_default.heat_pumps[0], 0.88, 12345, 23456, nil, 0.1, 2.0, 40.0)

    # Test w/ heating capacity 17F
    hpxml.heat_pumps[0].heating_capacity_17F = 9876
    hpxml.heat_pumps[0].heating_capacity_retention_fraction = nil
    hpxml.heat_pumps[0].heating_capacity_retention_temp = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_pthp_values(hpxml_default.heat_pumps[0], 0.88, 12345, 23456, 9876, nil, nil, 40.0)

    # Test defaults
    hpxml.heat_pumps[0].cooling_shr = nil
    hpxml.heat_pumps[0].cooling_capacity = nil
    hpxml.heat_pumps[0].heating_capacity = nil
    hpxml.heat_pumps[0].backup_heating_capacity = nil
    hpxml.heat_pumps[0].heating_capacity_17F = nil
    hpxml.heat_pumps[0].crankcase_heater_watts = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_pthp_values(hpxml_default.heat_pumps[0], 0.65, nil, nil, nil, 0.425, 5.0, 0.0)
  end

  def test_mini_split_heat_pumps
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base-hvac-mini-split-heat-pump-ducted.xml')
    hpxml.heat_pumps[0].cooling_shr = 0.78
    hpxml.heat_pumps[0].fan_watts_per_cfm = 0.66
    hpxml.heat_pumps[0].charge_defect_ratio = -0.11
    hpxml.heat_pumps[0].airflow_defect_ratio = -0.22
    hpxml.heat_pumps[0].cooling_capacity = 12345
    hpxml.heat_pumps[0].heating_capacity = 23456
    hpxml.heat_pumps[0].backup_heating_capacity = 34567
    hpxml.heat_pumps[0].heating_capacity_retention_fraction = 0.1
    hpxml.heat_pumps[0].heating_capacity_retention_temp = 2.0
    hpxml.heat_pumps[0].crankcase_heater_watts = 40.0
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_mini_split_heat_pump_values(hpxml_default.heat_pumps[0], 0.78, 0.66, -0.11, -0.22, 12345, 23456, nil, 34567, 19.0, 10.0, 0.1, 2.0, 40.0)

    # Test w/ heating capacity 17F
    hpxml.heat_pumps[0].heating_capacity_17F = 9876
    hpxml.heat_pumps[0].heating_capacity_retention_fraction = nil
    hpxml.heat_pumps[0].heating_capacity_retention_temp = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_mini_split_heat_pump_values(hpxml_default.heat_pumps[0], 0.78, 0.66, -0.11, -0.22, 12345, 23456, 9876, 34567, 19.0, 10.0, nil, nil, 40.0)

    # Test defaults
    hpxml.heat_pumps[0].cooling_shr = nil
    hpxml.heat_pumps[0].fan_watts_per_cfm = nil
    hpxml.heat_pumps[0].charge_defect_ratio = nil
    hpxml.heat_pumps[0].airflow_defect_ratio = nil
    hpxml.heat_pumps[0].cooling_capacity = nil
    hpxml.heat_pumps[0].heating_capacity = nil
    hpxml.heat_pumps[0].heating_capacity_17F = nil
    hpxml.heat_pumps[0].backup_heating_capacity = nil
    hpxml.heat_pumps[0].crankcase_heater_watts = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_mini_split_heat_pump_values(hpxml_default.heat_pumps[0], 0.73, 0.18, 0, 0, nil, nil, nil, nil, 19.0, 10.0, 0.5, 5.0, 50.0)

    # Test defaults w/ ductless and no backup
    hpxml.heat_pumps[0].distribution_system.delete
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_mini_split_heat_pump_values(hpxml_default.heat_pumps[0], 0.73, 0.07, 0, 0, nil, nil, nil, nil, 19.0, 10.0, 0.5, 5.0, 50.0)

    # Test defaults w/ ductless - SEER2/HSPF2
    hpxml.heat_pumps[0].cooling_efficiency_seer = nil
    hpxml.heat_pumps[0].cooling_efficiency_seer2 = 13.3
    hpxml.heat_pumps[0].heating_efficiency_hspf = nil
    hpxml.heat_pumps[0].heating_efficiency_hspf2 = 6.8
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_mini_split_heat_pump_values(hpxml_default.heat_pumps[0], 0.73, 0.07, 0, 0, nil, nil, nil, nil, 13.3, 7.56, 0.5, 5.0, 50.0)
  end

  def test_heat_pump_temperatures
    # Test inputs not overridden by defaults - ASHP w/ electric backup
    hpxml = _create_hpxml('base-hvac-air-to-air-heat-pump-1-speed.xml')
    hpxml.heat_pumps[0].compressor_lockout_temp = -2.0
    hpxml.heat_pumps[0].backup_heating_lockout_temp = 44.0
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_heat_pump_temperature_values(hpxml_default.heat_pumps[0], -2.0, 44.0, nil)

    # Test defaults
    hpxml.heat_pumps[0].compressor_lockout_temp = nil
    hpxml.heat_pumps[0].backup_heating_lockout_temp = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_heat_pump_temperature_values(hpxml_default.heat_pumps[0], 0.0, 40.0, nil)

    # Test inputs not overridden by defaults - MSHP w/o backup
    hpxml = _create_hpxml('base-hvac-mini-split-heat-pump-ductless.xml')
    hpxml.heat_pumps[0].compressor_lockout_temp = 33.0
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_heat_pump_temperature_values(hpxml_default.heat_pumps[0], 33.0, nil, nil)

    # Test defaults
    hpxml.heat_pumps[0].compressor_lockout_temp = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_heat_pump_temperature_values(hpxml_default.heat_pumps[0], -20.0, nil, nil)

    # Test inputs not overridden by defaults - MSHP w/ electric backup
    hpxml = _create_hpxml('base-hvac-mini-split-heat-pump-ductless-backup-baseboard.xml')
    hpxml.heat_pumps[0].compressor_lockout_temp = -2.0
    hpxml.heat_pumps[0].backup_heating_lockout_temp = 44.0
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_heat_pump_temperature_values(hpxml_default.heat_pumps[0], -2.0, 44.0, nil)

    # Test defaults
    hpxml.heat_pumps[0].compressor_lockout_temp = nil
    hpxml.heat_pumps[0].backup_heating_lockout_temp = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_heat_pump_temperature_values(hpxml_default.heat_pumps[0], -20.0, 40.0, nil)

    # Test inputs not overridden by defaults - HP w/ fuel backup
    ['base-hvac-dual-fuel-air-to-air-heat-pump-1-speed.xml',
     'base-hvac-air-to-air-heat-pump-var-speed-backup-boiler.xml',
     'base-hvac-mini-split-heat-pump-ductless-backup-stove.xml'].each do |hpxml_name|
      hpxml = _create_hpxml(hpxml_name)
      hpxml.heat_pumps[0].backup_heating_switchover_temp = 33.0
      XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
      hpxml_default = _test_measure()
      _test_default_heat_pump_temperature_values(hpxml_default.heat_pumps[0], nil, nil, 33.0)

      # Test inputs not overridden by defaults - HP w/ integrated/separate fuel backup, lockout temps
      hpxml.heat_pumps[0].backup_heating_switchover_temp = nil
      hpxml.heat_pumps[0].compressor_lockout_temp = 22.0
      hpxml.heat_pumps[0].backup_heating_lockout_temp = 44.0
      XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
      hpxml_default = _test_measure()
      _test_default_heat_pump_temperature_values(hpxml_default.heat_pumps[0], 22.0, 44.0, nil)

      # Test defaults
      hpxml.heat_pumps[0].compressor_lockout_temp = nil
      hpxml.heat_pumps[0].backup_heating_lockout_temp = nil
      XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
      hpxml_default = _test_measure()
      _test_default_heat_pump_temperature_values(hpxml_default.heat_pumps[0], 25.0, 50.0, nil)
    end
  end

  def test_ground_source_heat_pumps
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base-hvac-ground-to-air-heat-pump.xml')
    hpxml.heat_pumps[0].pump_watts_per_ton = 9.9
    hpxml.heat_pumps[0].fan_watts_per_cfm = 0.66
    hpxml.heat_pumps[0].airflow_defect_ratio = -0.22
    hpxml.heat_pumps[0].cooling_capacity = 12345
    hpxml.heat_pumps[0].heating_capacity = 23456
    hpxml.heat_pumps[0].backup_heating_capacity = 34567
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_ground_to_air_heat_pump_values(hpxml_default.heat_pumps[0], 9.9, 0.66, -0.22, 12345, 23456, 34567)

    # Test defaults
    hpxml.heat_pumps[0].pump_watts_per_ton = nil
    hpxml.heat_pumps[0].fan_watts_per_cfm = nil
    hpxml.heat_pumps[0].airflow_defect_ratio = nil
    hpxml.heat_pumps[0].cooling_capacity = nil
    hpxml.heat_pumps[0].heating_capacity = nil
    hpxml.heat_pumps[0].backup_heating_capacity = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_ground_to_air_heat_pump_values(hpxml_default.heat_pumps[0], 30.0, 0.375, 0, nil, nil, nil)
  end

  def test_hvac_location
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base-foundation-unconditioned-basement.xml')
    hpxml.heating_systems[0].location = HPXML::LocationAtticUnvented
    hpxml.cooling_systems[0].delete
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_hvac_location_values(hpxml_default.heating_systems[0], HPXML::LocationAtticUnvented)

    # Test defaults
    hpxml.heating_systems[0].location = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_hvac_location_values(hpxml_default.heating_systems[0], HPXML::LocationBasementUnconditioned)

    # Test defaults -- multiple duct locations
    hpxml.heating_systems[0].distribution_system.ducts.add(id: "Ducts#{hpxml.heating_systems[0].distribution_system.ducts.size + 1}",
                                                           duct_type: HPXML::DuctTypeSupply,
                                                           duct_insulation_r_value: 0,
                                                           duct_location: HPXML::LocationAtticUnvented,
                                                           duct_surface_area: 151)
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_hvac_location_values(hpxml_default.heating_systems[0], HPXML::LocationAtticUnvented)

    # Test defaults -- ducts outside
    hpxml.heating_systems[0].distribution_system.ducts.each do |d|
      d.duct_location = HPXML::LocationOutside
    end
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_hvac_location_values(hpxml_default.heating_systems[0], HPXML::LocationOtherExterior)

    # Test defaults -- hydronic
    hpxml.heating_systems[0].heating_system_type = HPXML::HVACTypeBoiler
    hpxml.heating_systems[0].distribution_system.distribution_system_type = HPXML::HVACDistributionTypeHydronic
    hpxml.heating_systems[0].distribution_system.hydronic_type = HPXML::HydronicTypeBaseboard
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_hvac_location_values(hpxml_default.heating_systems[0], HPXML::LocationBasementUnconditioned)

    # Test defaults -- DSE = 1
    hpxml.heating_systems[0].distribution_system.distribution_system_type = HPXML::HVACDistributionTypeDSE
    hpxml.heating_systems[0].distribution_system.annual_heating_dse = 1.0
    hpxml.heating_systems[0].distribution_system.annual_cooling_dse = 0.5
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_hvac_location_values(hpxml_default.heating_systems[0], HPXML::LocationLivingSpace)

    # Test defaults -- DSE < 1
    hpxml.heating_systems[0].distribution_system.annual_heating_dse = 0.8
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_hvac_location_values(hpxml_default.heating_systems[0], HPXML::LocationUnconditionedSpace)

    # Test defaults -- ductless
    hpxml.heating_systems[0].heating_system_type = HPXML::HVACTypeWallFurnace
    hpxml.heating_systems[0].distribution_system.delete
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_hvac_location_values(hpxml_default.heating_systems[0], HPXML::LocationLivingSpace)
  end

  def test_hvac_controls
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base.xml')
    hpxml.hvac_controls[0].heating_setpoint_temp = 71.5
    hpxml.hvac_controls[0].cooling_setpoint_temp = 77.5
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_hvac_control_setpoint_values(hpxml_default.hvac_controls[0], 71.5, 77.5)

    # Test defaults
    hpxml.hvac_controls[0].heating_setpoint_temp = nil
    hpxml.hvac_controls[0].cooling_setpoint_temp = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_hvac_control_setpoint_values(hpxml_default.hvac_controls[0], 68, 78)

    # Test inputs not overridden by defaults (w/ setbacks)
    hpxml = _create_hpxml('base-hvac-setpoints-daily-setbacks.xml')
    hpxml.hvac_controls[0].heating_setback_start_hour = 12
    hpxml.hvac_controls[0].cooling_setup_start_hour = 12
    hpxml.hvac_controls[0].seasons_heating_begin_month = 1
    hpxml.hvac_controls[0].seasons_heating_begin_day = 1
    hpxml.hvac_controls[0].seasons_heating_end_month = 6
    hpxml.hvac_controls[0].seasons_heating_end_day = 30
    hpxml.hvac_controls[0].seasons_cooling_begin_month = 7
    hpxml.hvac_controls[0].seasons_cooling_begin_day = 1
    hpxml.hvac_controls[0].seasons_cooling_end_month = 12
    hpxml.hvac_controls[0].seasons_cooling_end_day = 31
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_hvac_control_setback_values(hpxml_default.hvac_controls[0], 12, 12)
    _test_default_hvac_control_season_values(hpxml_default.hvac_controls[0], 1, 1, 6, 30, 7, 1, 12, 31)

    # Test defaults w/ setbacks
    hpxml.hvac_controls[0].heating_setback_start_hour = nil
    hpxml.hvac_controls[0].cooling_setup_start_hour = nil
    hpxml.hvac_controls[0].seasons_heating_begin_month = nil
    hpxml.hvac_controls[0].seasons_heating_begin_day = nil
    hpxml.hvac_controls[0].seasons_heating_end_month = nil
    hpxml.hvac_controls[0].seasons_heating_end_day = nil
    hpxml.hvac_controls[0].seasons_cooling_begin_month = nil
    hpxml.hvac_controls[0].seasons_cooling_begin_day = nil
    hpxml.hvac_controls[0].seasons_cooling_end_month = nil
    hpxml.hvac_controls[0].seasons_cooling_end_day = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_hvac_control_setback_values(hpxml_default.hvac_controls[0], 23, 9)
    _test_default_hvac_control_season_values(hpxml_default.hvac_controls[0], 1, 1, 12, 31, 1, 1, 12, 31)
  end

  def test_hvac_distribution
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base.xml')
    hpxml.hvac_distributions[0].conditioned_floor_area_served = 2700.0
    hpxml.hvac_distributions[0].number_of_return_registers = 2
    hpxml.hvac_distributions[0].ducts[0].duct_surface_area_multiplier = 0.5
    hpxml.hvac_distributions[0].ducts[1].duct_surface_area_multiplier = 1.5
    hpxml.hvac_distributions[0].ducts[0].duct_buried_insulation_level = HPXML::DuctBuriedInsulationPartial
    hpxml.hvac_distributions[0].ducts[1].duct_buried_insulation_level = HPXML::DuctBuriedInsulationDeep
    hpxml.hvac_distributions[0].ducts[0].duct_insulation_r_value = nil
    hpxml.hvac_distributions[0].ducts[1].duct_insulation_r_value = nil
    hpxml.hvac_distributions[0].ducts[0].duct_effective_r_value = 1.23
    hpxml.hvac_distributions[0].ducts[1].duct_effective_r_value = 3.21
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    expected_supply_locations = ['attic - unvented']
    expected_return_locations = ['attic - unvented']
    expected_supply_areas = [150.0]
    expected_return_areas = [50.0]
    expected_supply_fracs = [1.0]
    expected_return_fracs = [1.0]
    expected_supply_area_mults = [0.5]
    expected_return_area_mults = [1.5]
    expected_supply_effective_rvalues = [1.23]
    expected_return_effective_rvalues = [3.21]
    expected_supply_buried_levels = [HPXML::DuctBuriedInsulationPartial]
    expected_return_buried_levels = [HPXML::DuctBuriedInsulationDeep]
    expected_n_return_registers = hpxml_default.building_construction.number_of_conditioned_floors
    _test_default_duct_values(hpxml_default, expected_supply_locations, expected_return_locations, expected_supply_areas, expected_return_areas,
                              expected_supply_fracs, expected_return_fracs, expected_n_return_registers, expected_supply_area_mults, expected_return_area_mults,
                              expected_supply_buried_levels, expected_return_buried_levels, expected_supply_effective_rvalues, expected_return_effective_rvalues)

    # Test defaults w/ conditioned basement
    hpxml.hvac_distributions[0].number_of_return_registers = nil
    hpxml.hvac_distributions[0].ducts.each do |duct|
      duct.duct_location = nil
      duct.duct_surface_area = nil
      duct.duct_surface_area_multiplier = nil
      duct.duct_buried_insulation_level = nil
      duct.duct_effective_r_value = nil
    end
    hpxml.hvac_distributions[0].ducts[0].duct_insulation_r_value = 4
    hpxml.hvac_distributions[0].ducts[1].duct_insulation_r_value = 0
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    expected_supply_locations = ['basement - conditioned']
    expected_return_locations = ['basement - conditioned']
    expected_supply_areas = [729.0]
    expected_return_areas = [270.0]
    expected_supply_fracs = [1.0]
    expected_return_fracs = [1.0]
    expected_supply_area_mults = [1.0]
    expected_return_area_mults = [1.0]
    expected_supply_buried_levels = [HPXML::DuctBuriedInsulationNone]
    expected_return_buried_levels = [HPXML::DuctBuriedInsulationNone]
    expected_supply_effective_rvalues = [4.5]
    expected_return_effective_rvalues = [1.7]
    expected_n_return_registers = hpxml_default.building_construction.number_of_conditioned_floors
    _test_default_duct_values(hpxml_default, expected_supply_locations, expected_return_locations, expected_supply_areas, expected_return_areas,
                              expected_supply_fracs, expected_return_fracs, expected_n_return_registers, expected_supply_area_mults, expected_return_area_mults,
                              expected_supply_buried_levels, expected_return_buried_levels, expected_supply_effective_rvalues, expected_return_effective_rvalues)

    # Test defaults w/ multiple foundations
    hpxml = _create_hpxml('base-foundation-multiple.xml')
    hpxml.hvac_distributions[0].conditioned_floor_area_served = 1350.0
    hpxml.hvac_distributions[0].number_of_return_registers = 1
    hpxml.hvac_distributions[0].ducts.each do |duct|
      duct.duct_location = nil
      duct.duct_surface_area = nil
      duct.duct_surface_area_multiplier = nil
      duct.duct_buried_insulation_level = nil
    end
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    expected_supply_locations = ['basement - unconditioned']
    expected_return_locations = ['basement - unconditioned']
    expected_supply_areas = [364.5]
    expected_return_areas = [67.5]
    expected_supply_fracs = [1.0]
    expected_return_fracs = [1.0]
    expected_supply_area_mults = [1.0]
    expected_return_area_mults = [1.0]
    expected_supply_effective_rvalues = [4.5]
    expected_return_effective_rvalues = [1.7]
    expected_supply_buried_levels = [HPXML::DuctBuriedInsulationNone]
    expected_return_buried_levels = [HPXML::DuctBuriedInsulationNone]
    expected_n_return_registers = hpxml_default.building_construction.number_of_conditioned_floors
    _test_default_duct_values(hpxml_default, expected_supply_locations, expected_return_locations, expected_supply_areas, expected_return_areas,
                              expected_supply_fracs, expected_return_fracs, expected_n_return_registers, expected_supply_area_mults, expected_return_area_mults,
                              expected_supply_buried_levels, expected_return_buried_levels, expected_supply_effective_rvalues, expected_return_effective_rvalues)

    # Test defaults w/ foundation exposed to ambient
    hpxml = _create_hpxml('base-foundation-ambient.xml')
    hpxml.hvac_distributions[0].conditioned_floor_area_served = 1350.0
    hpxml.hvac_distributions[0].number_of_return_registers = 1
    hpxml.hvac_distributions[0].ducts.each do |duct|
      duct.duct_location = nil
      duct.duct_surface_area = nil
      duct.duct_surface_area_multiplier = nil
      duct.duct_buried_insulation_level = nil
    end
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    expected_supply_locations = ['attic - unvented']
    expected_return_locations = ['attic - unvented']
    expected_supply_areas = [364.5]
    expected_return_areas = [67.5]
    expected_supply_fracs = [1.0]
    expected_return_fracs = [1.0]
    expected_supply_area_mults = [1.0]
    expected_return_area_mults = [1.0]
    expected_supply_effective_rvalues = [4.5]
    expected_return_effective_rvalues = [1.7]
    expected_supply_buried_levels = [HPXML::DuctBuriedInsulationNone]
    expected_return_buried_levels = [HPXML::DuctBuriedInsulationNone]
    expected_n_return_registers = hpxml_default.building_construction.number_of_conditioned_floors
    _test_default_duct_values(hpxml_default, expected_supply_locations, expected_return_locations, expected_supply_areas, expected_return_areas,
                              expected_supply_fracs, expected_return_fracs, expected_n_return_registers, expected_supply_area_mults, expected_return_area_mults,
                              expected_supply_buried_levels, expected_return_buried_levels, expected_supply_effective_rvalues, expected_return_effective_rvalues)

    # Test defaults w/ building/unit adjacent to other housing unit
    hpxml = _create_hpxml('base-bldgtype-multifamily-adjacent-to-other-housing-unit.xml')
    hpxml.hvac_distributions[0].conditioned_floor_area_served = 900.0
    hpxml.hvac_distributions[0].number_of_return_registers = 1
    hpxml.hvac_distributions[0].ducts.each do |duct|
      duct.duct_location = nil
      duct.duct_surface_area = nil
      duct.duct_surface_area_multiplier = nil
      duct.duct_buried_insulation_level = nil
    end
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    expected_supply_locations = ['living space']
    expected_return_locations = ['living space']
    expected_supply_areas = [243.0]
    expected_return_areas = [45.0]
    expected_supply_fracs = [1.0]
    expected_return_fracs = [1.0]
    expected_supply_area_mults = [1.0]
    expected_return_area_mults = [1.0]
    expected_supply_effective_rvalues = [1.7]
    expected_return_effective_rvalues = [1.7]
    expected_supply_buried_levels = [HPXML::DuctBuriedInsulationNone]
    expected_return_buried_levels = [HPXML::DuctBuriedInsulationNone]
    expected_n_return_registers = hpxml_default.building_construction.number_of_conditioned_floors
    _test_default_duct_values(hpxml_default, expected_supply_locations, expected_return_locations, expected_supply_areas, expected_return_areas,
                              expected_supply_fracs, expected_return_fracs, expected_n_return_registers, expected_supply_area_mults, expected_return_area_mults,
                              expected_supply_buried_levels, expected_return_buried_levels, expected_supply_effective_rvalues, expected_return_effective_rvalues)

    # Test defaults w/ 2-story building
    hpxml = _create_hpxml('base-enclosure-2stories.xml')
    hpxml.hvac_distributions[0].conditioned_floor_area_served = 4050.0
    hpxml.hvac_distributions[0].number_of_return_registers = 3
    hpxml.hvac_distributions[0].ducts.each do |duct|
      duct.duct_location = nil
      duct.duct_surface_area = nil
      duct.duct_surface_area_multiplier = nil
      duct.duct_buried_insulation_level = nil
    end
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    expected_supply_locations = ['basement - conditioned', 'basement - conditioned', 'living space', 'living space']
    expected_return_locations = ['basement - conditioned', 'basement - conditioned', 'living space', 'living space']
    expected_supply_areas = [410.06, 410.06, 136.69, 136.69]
    expected_return_areas = [227.82, 227.82, 75.94, 75.94]
    expected_supply_fracs = [0.375, 0.375, 0.125, 0.125]
    expected_return_fracs = [0.375, 0.375, 0.125, 0.125]
    expected_supply_area_mults = [1.0, 1.0, 1.0, 1.0]
    expected_return_area_mults = [1.0, 1.0, 1.0, 1.0]
    expected_supply_buried_levels = [HPXML::DuctBuriedInsulationNone] * 4
    expected_return_buried_levels = [HPXML::DuctBuriedInsulationNone] * 4
    expected_supply_effective_rvalues = [4.5] * 4
    expected_return_effective_rvalues = [1.7] * 4
    expected_n_return_registers = hpxml_default.building_construction.number_of_conditioned_floors
    _test_default_duct_values(hpxml_default, expected_supply_locations, expected_return_locations, expected_supply_areas, expected_return_areas,
                              expected_supply_fracs, expected_return_fracs, expected_n_return_registers, expected_supply_area_mults, expected_return_area_mults,
                              expected_supply_buried_levels, expected_return_buried_levels, expected_supply_effective_rvalues, expected_return_effective_rvalues)

    # Test defaults w/ 1-story building & multiple HVAC systems
    hpxml = _create_hpxml('base-hvac-multiple.xml')
    hpxml.hvac_distributions.each do |hvac_distribution|
      next unless hvac_distribution.distribution_system_type == HPXML::HVACDistributionTypeAir

      hvac_distribution.conditioned_floor_area_served = 270.0
      hvac_distribution.number_of_return_registers = 2
      hvac_distribution.ducts.each do |duct|
        duct.duct_location = nil
        duct.duct_surface_area = nil
        duct.duct_surface_area_multiplier = nil
        duct.duct_buried_insulation_level = nil
      end
    end
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    expected_supply_locations = ['basement - conditioned', 'basement - conditioned'] * hpxml_default.hvac_distributions.size
    expected_return_locations = ['basement - conditioned', 'basement - conditioned'] * hpxml_default.hvac_distributions.size
    expected_supply_areas = [36.45, 36.45] * hpxml_default.hvac_distributions.size
    expected_return_areas = [13.5, 13.5] * hpxml_default.hvac_distributions.size
    expected_supply_fracs = [0.5, 0.5] * hpxml_default.hvac_distributions.size
    expected_return_fracs = [0.5, 0.5] * hpxml_default.hvac_distributions.size
    expected_supply_area_mults = [1.0, 1.0] * hpxml_default.hvac_distributions.size
    expected_return_area_mults = [1.0, 1.0] * hpxml_default.hvac_distributions.size
    expected_supply_buried_levels = [HPXML::DuctBuriedInsulationNone] * 2 * hpxml_default.hvac_distributions.size
    expected_return_buried_levels = [HPXML::DuctBuriedInsulationNone] * 2 * hpxml_default.hvac_distributions.size
    expected_supply_effective_rvalues = [6.74] * 2 * hpxml_default.hvac_distributions.size
    expected_return_effective_rvalues = [4.86] * 2 * hpxml_default.hvac_distributions.size
    expected_n_return_registers = hpxml_default.building_construction.number_of_conditioned_floors
    _test_default_duct_values(hpxml_default, expected_supply_locations, expected_return_locations, expected_supply_areas, expected_return_areas,
                              expected_supply_fracs, expected_return_fracs, expected_n_return_registers, expected_supply_area_mults, expected_return_area_mults,
                              expected_supply_buried_levels, expected_return_buried_levels, expected_supply_effective_rvalues, expected_return_effective_rvalues)

    # Test defaults w/ 2-story building & multiple HVAC systems
    hpxml = _create_hpxml('base-hvac-multiple.xml')
    hpxml.building_construction.number_of_conditioned_floors_above_grade = 2
    hpxml.hvac_distributions.each do |hvac_distribution|
      next unless hvac_distribution.distribution_system_type == HPXML::HVACDistributionTypeAir

      hvac_distribution.conditioned_floor_area_served = 270.0
      hvac_distribution.number_of_return_registers = 2
      hvac_distribution.ducts.each do |duct|
        duct.duct_location = nil
        duct.duct_surface_area = nil
        duct.duct_surface_area_multiplier = nil
        duct.duct_buried_insulation_level = nil
      end
    end
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    expected_supply_locations = ['basement - conditioned', 'basement - conditioned', 'living space', 'living space'] * hpxml_default.hvac_distributions.size
    expected_return_locations = ['basement - conditioned', 'basement - conditioned', 'living space', 'living space'] * hpxml_default.hvac_distributions.size
    expected_supply_areas = [27.34, 27.34, 9.11, 9.11] * hpxml_default.hvac_distributions.size
    expected_return_areas = [10.125, 10.125, 3.375, 3.375] * hpxml_default.hvac_distributions.size
    expected_supply_fracs = [0.375, 0.375, 0.125, 0.125] * hpxml_default.hvac_distributions.size
    expected_return_fracs = [0.375, 0.375, 0.125, 0.125] * hpxml_default.hvac_distributions.size
    expected_supply_area_mults = [1.0, 1.0, 1.0, 1.0] * hpxml_default.hvac_distributions.size
    expected_return_area_mults = [1.0, 1.0, 1.0, 1.0] * hpxml_default.hvac_distributions.size
    expected_supply_buried_levels = [HPXML::DuctBuriedInsulationNone] * 4 * hpxml_default.hvac_distributions.size
    expected_return_buried_levels = [HPXML::DuctBuriedInsulationNone] * 4 * hpxml_default.hvac_distributions.size
    expected_supply_effective_rvalues = [6.74] * 4 * hpxml_default.hvac_distributions.size
    expected_return_effective_rvalues = [4.86] * 4 * hpxml_default.hvac_distributions.size
    expected_n_return_registers = hpxml_default.building_construction.number_of_conditioned_floors
    _test_default_duct_values(hpxml_default, expected_supply_locations, expected_return_locations, expected_supply_areas, expected_return_areas,
                              expected_supply_fracs, expected_return_fracs, expected_n_return_registers, expected_supply_area_mults, expected_return_area_mults,
                              expected_supply_buried_levels, expected_return_buried_levels, expected_supply_effective_rvalues, expected_return_effective_rvalues)

    # Test defaults w/ 2-story building & multiple HVAC systems & duct area fractions
    hpxml = _create_hpxml('base-hvac-multiple.xml')
    hpxml.building_construction.number_of_conditioned_floors_above_grade = 2
    hpxml.hvac_distributions.each do |hvac_distribution|
      next unless hvac_distribution.distribution_system_type == HPXML::HVACDistributionTypeAir

      hvac_distribution.conditioned_floor_area_served = 270.0
      hvac_distribution.number_of_return_registers = 2
      hvac_distribution.ducts[0].duct_fraction_area = 0.75
      hvac_distribution.ducts[1].duct_fraction_area = 0.25
      hvac_distribution.ducts[2].duct_fraction_area = 0.5
      hvac_distribution.ducts[3].duct_fraction_area = 0.5
    end
    hpxml.hvac_distributions.each do |hvac_distribution|
      hvac_distribution.ducts.each do |duct|
        duct.duct_surface_area = nil
        duct.duct_surface_area_multiplier = nil
        duct.duct_buried_insulation_level = nil
      end
    end
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    expected_supply_locations = ['attic - unvented', 'outside', 'attic - unvented', 'outside'] * hpxml_default.hvac_distributions.size
    expected_return_locations = ['attic - unvented', 'outside', 'attic - unvented', 'outside'] * hpxml_default.hvac_distributions.size
    expected_supply_areas = [54.675, 18.225] * hpxml_default.hvac_distributions.size
    expected_return_areas = [13.5, 13.5] * hpxml_default.hvac_distributions.size
    expected_supply_fracs = [0.75, 0.25] * hpxml_default.hvac_distributions.size
    expected_return_fracs = [0.5, 0.5] * hpxml_default.hvac_distributions.size
    expected_supply_area_mults = [1.0, 1.0] * hpxml_default.hvac_distributions.size
    expected_return_area_mults = [1.0, 1.0] * hpxml_default.hvac_distributions.size
    expected_supply_buried_levels = [HPXML::DuctBuriedInsulationNone] * 2 * hpxml_default.hvac_distributions.size
    expected_return_buried_levels = [HPXML::DuctBuriedInsulationNone] * 2 * hpxml_default.hvac_distributions.size
    expected_supply_effective_rvalues = [6.74] * 2 * hpxml_default.hvac_distributions.size
    expected_return_effective_rvalues = [4.86] * 2 * hpxml_default.hvac_distributions.size
    expected_n_return_registers = hpxml_default.building_construction.number_of_conditioned_floors
    _test_default_duct_values(hpxml_default, expected_supply_locations, expected_return_locations, expected_supply_areas, expected_return_areas,
                              expected_supply_fracs, expected_return_fracs, expected_n_return_registers, expected_supply_area_mults, expected_return_area_mults,
                              expected_supply_buried_levels, expected_return_buried_levels, expected_supply_effective_rvalues, expected_return_effective_rvalues)
  end

  def test_mech_ventilation_fans
    # Test inputs not overridden by defaults w/ shared exhaust system
    hpxml = _create_hpxml('base-bldgtype-attached.xml')
    hpxml.ventilation_fans.add(id: 'MechanicalVentilation',
                               fan_type: HPXML::MechVentTypeExhaust,
                               used_for_whole_building_ventilation: true,
                               is_shared_system: true,
                               fraction_recirculation: 0.0,
                               in_unit_flow_rate: 10.0,
                               hours_in_operation: 22.0,
                               fan_power: 12.5,
                               delivered_ventilation: 89)
    vent_fan = hpxml.ventilation_fans[0]
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_mech_vent_values(hpxml_default, true, 22.0, 12.5, 89)

    # Test inputs w/ TestedFlowRate
    vent_fan.tested_flow_rate = 79
    vent_fan.rated_flow_rate = nil
    vent_fan.calculated_flow_rate = nil
    vent_fan.delivered_ventilation = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_mech_vent_values(hpxml_default, true, 22.0, 12.5, 79)

    # Test inputs w/ RatedFlowRate
    vent_fan.tested_flow_rate = nil
    vent_fan.rated_flow_rate = 69
    vent_fan.calculated_flow_rate = nil
    vent_fan.delivered_ventilation = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_mech_vent_values(hpxml_default, true, 22.0, 12.5, 69)

    # Test inputs w/ CalculatedFlowRate
    vent_fan.tested_flow_rate = nil
    vent_fan.rated_flow_rate = nil
    vent_fan.calculated_flow_rate = 59
    vent_fan.delivered_ventilation = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_mech_vent_values(hpxml_default, true, 22.0, 12.5, 59)

    # Test defaults
    vent_fan.rated_flow_rate = nil
    vent_fan.start_hour = nil
    vent_fan.count = nil
    vent_fan.is_shared_system = nil
    vent_fan.fraction_recirculation = nil
    vent_fan.in_unit_flow_rate = nil
    vent_fan.hours_in_operation = nil
    vent_fan.fan_power = nil
    vent_fan.tested_flow_rate = nil
    vent_fan.rated_flow_rate = nil
    vent_fan.calculated_flow_rate = nil
    vent_fan.delivered_ventilation = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_mech_vent_values(hpxml_default, false, 24.0, 27.1, 77.3)

    # Test defaults w/ SFA building, compartmentalization test
    hpxml = _create_hpxml('base-bldgtype-attached.xml')
    hpxml.air_infiltration_measurements[0].infiltration_type = HPXML::InfiltrationTypeUnitTotal
    hpxml.ventilation_fans.add(id: 'MechanicalVentilation',
                               fan_type: HPXML::MechVentTypeExhaust,
                               used_for_whole_building_ventilation: true)
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_mech_vent_values(hpxml_default, false, 24.0, 27.4, 78.4)

    # Test defaults w/ SFA building, guarded test
    hpxml.air_infiltration_measurements[0].infiltration_type = HPXML::InfiltrationTypeUnitExterior
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_mech_vent_values(hpxml_default, false, 24.0, 27.2, 77.3)

    # Test defaults w/ MF building, compartmentalization test
    hpxml = _create_hpxml('base-bldgtype-multifamily.xml')
    hpxml.air_infiltration_measurements[0].infiltration_type = HPXML::InfiltrationTypeUnitTotal
    hpxml.ventilation_fans.add(id: 'MechanicalVentilation',
                               fan_type: HPXML::MechVentTypeExhaust,
                               used_for_whole_building_ventilation: true)
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_mech_vent_values(hpxml_default, false, 24.0, 19.8, 56.5)

    # Test defaults w/ MF building, guarded test
    hpxml.air_infiltration_measurements[0].infiltration_type = HPXML::InfiltrationTypeUnitExterior
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_mech_vent_values(hpxml_default, false, 24.0, 19.2, 54.9)

    # Test defaults w/ nACH infiltration
    hpxml = _create_hpxml('base-enclosure-infil-natural-ach.xml')
    hpxml.ventilation_fans.add(id: 'MechanicalVentilation',
                               fan_type: HPXML::MechVentTypeExhaust,
                               used_for_whole_building_ventilation: true)
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_mech_vent_values(hpxml_default, false, 24.0, 21.6, 61.7)

    # Test defaults w/ CFM50 infiltration
    hpxml = _create_hpxml('base-enclosure-infil-cfm50.xml')
    hpxml.ventilation_fans.add(id: 'MechanicalVentilation',
                               fan_type: HPXML::MechVentTypeExhaust,
                               used_for_whole_building_ventilation: true)
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_mech_vent_values(hpxml_default, false, 24.0, 34.9, 99.6)

    # Test defaults w/ balanced system
    hpxml = _create_hpxml('base.xml')
    hpxml.ventilation_fans.add(id: 'MechanicalVentilation',
                               fan_type: HPXML::MechVentTypeBalanced,
                               used_for_whole_building_ventilation: true)
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_mech_vent_values(hpxml_default, false, 24.0, 52.8, 75.4)

    # Test defaults w/ cathedral ceiling
    hpxml = _create_hpxml('base-atticroof-cathedral.xml')
    hpxml.ventilation_fans.add(id: 'MechanicalVentilation',
                               fan_type: HPXML::MechVentTypeExhaust,
                               used_for_whole_building_ventilation: true)
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_mech_vent_values(hpxml_default, false, 24.0, 27.0, 77.1)

    # Test inputs not overridden by defaults w/ CFIS
    hpxml = _create_hpxml('base-mechvent-cfis.xml')
    vent_fan = hpxml.ventilation_fans.find { |f| f.used_for_whole_building_ventilation }
    vent_fan.is_shared_system = false
    vent_fan.hours_in_operation = 12.0
    vent_fan.fan_power = 12.5
    vent_fan.rated_flow_rate = 222.0
    vent_fan.cfis_vent_mode_airflow_fraction = 0.5
    vent_fan.cfis_addtl_runtime_operating_mode = HPXML::CFISModeSupplementalFan
    hpxml.ventilation_fans.add(id: "VentilationFan#{hpxml.ventilation_fans.size + 1}",
                               tested_flow_rate: 79.0,
                               fan_power: 9.0,
                               fan_type: HPXML::MechVentTypeExhaust,
                               is_shared_system: false,
                               used_for_whole_building_ventilation: true)
    suppl_vent_fan = hpxml.ventilation_fans[-1]
    vent_fan.cfis_supplemental_fan_idref = suppl_vent_fan.id
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_mech_vent_values(hpxml_default, false, 12.0, 12.5, 222.0, 0.5, HPXML::CFISModeSupplementalFan)
    _test_default_mech_vent_suppl_values(hpxml_default, false, nil, 9.0, 79.0)

    # Test defaults w/ CFIS supplemental fan
    suppl_vent_fan.tested_flow_rate = nil
    suppl_vent_fan.is_shared_system = nil
    suppl_vent_fan.fan_power = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_mech_vent_suppl_values(hpxml_default, false, nil, 35.0, 100.0)

    # Test defaults w/ CFIS
    vent_fan.is_shared_system = nil
    vent_fan.hours_in_operation = nil
    vent_fan.fan_power = nil
    vent_fan.rated_flow_rate = nil
    vent_fan.cfis_vent_mode_airflow_fraction = nil
    vent_fan.cfis_addtl_runtime_operating_mode = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_mech_vent_values(hpxml_default, false, 8.0, 149.4, 298.7, 1.0, HPXML::CFISModeAirHandler)

    # Test inputs not overridden by defaults w/ ERV
    hpxml = _create_hpxml('base-mechvent-erv.xml')
    vent_fan = hpxml.ventilation_fans.find { |f| f.used_for_whole_building_ventilation }
    vent_fan.is_shared_system = false
    vent_fan.hours_in_operation = 20.0
    vent_fan.fan_power = 45.0
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_mech_vent_values(hpxml_default, false, 20.0, 45.0, 110)

    # Test defaults w/ ERV
    vent_fan.is_shared_system = nil
    vent_fan.hours_in_operation = nil
    vent_fan.fan_power = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_mech_vent_values(hpxml_default, false, 24.0, 110.0, 110)
  end

  def test_local_ventilation_fans
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base-mechvent-bath-kitchen-fans.xml')
    kitchen_fan = hpxml.ventilation_fans.find { |f| f.used_for_local_ventilation && f.fan_location == HPXML::LocationKitchen }
    kitchen_fan.rated_flow_rate = 300
    kitchen_fan.fan_power = 20
    kitchen_fan.start_hour = 12
    kitchen_fan.count = 2
    kitchen_fan.hours_in_operation = 2
    bath_fan = hpxml.ventilation_fans.find { |f| f.used_for_local_ventilation && f.fan_location == HPXML::LocationBath }
    bath_fan.rated_flow_rate = 80
    bath_fan.fan_power = 33
    bath_fan.start_hour = 6
    bath_fan.count = 3
    bath_fan.hours_in_operation = 3
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_kitchen_fan_values(hpxml_default, 2, 300, 2, 20, 12)
    _test_default_bath_fan_values(hpxml_default, 3, 80, 3, 33, 6)

    # Test defaults
    kitchen_fan.rated_flow_rate = nil
    kitchen_fan.fan_power = nil
    kitchen_fan.start_hour = nil
    kitchen_fan.count = nil
    kitchen_fan.hours_in_operation = nil
    bath_fan.rated_flow_rate = nil
    bath_fan.fan_power = nil
    bath_fan.start_hour = nil
    bath_fan.count = nil
    bath_fan.hours_in_operation = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_kitchen_fan_values(hpxml_default, 1, 100, 1, 30, 18)
    _test_default_bath_fan_values(hpxml_default, 2, 50, 1, 15, 7)
  end

  def test_whole_house_fan
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base-mechvent-whole-house-fan.xml')
    whf = hpxml.ventilation_fans.find { |f| f.used_for_seasonal_cooling_load_reduction }
    whf.rated_flow_rate = 3000
    whf.fan_power = 321
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_whole_house_fan_values(hpxml_default, 3000, 321)

    # Test defaults
    whf.rated_flow_rate = nil
    whf.fan_power = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_whole_house_fan_values(hpxml_default, 5400, 540)
  end

  def test_storage_water_heaters
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base-bldgtype-attached.xml')
    hpxml.water_heating_systems.each do |wh|
      wh.is_shared_system = true
      wh.number_of_units_served = 2
      wh.heating_capacity = 15000.0
      wh.tank_volume = 40.0
      wh.recovery_efficiency = 0.95
      wh.location = HPXML::LocationLivingSpace
      wh.temperature = 111
      wh.energy_factor = 0.90
      wh.tank_model_type = HPXML::WaterHeaterTankModelTypeStratified
    end
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_storage_water_heater_values(hpxml_default,
                                              [true, 15000.0, 40.0, 0.95, HPXML::LocationLivingSpace, 111, 0.90, HPXML::WaterHeaterTankModelTypeStratified])

    # Test defaults w/ 3-bedroom house & electric storage water heater
    hpxml.water_heating_systems.each do |wh|
      wh.is_shared_system = nil
      wh.heating_capacity = nil
      wh.tank_volume = nil
      wh.recovery_efficiency = nil
      wh.location = nil
      wh.temperature = nil
      wh.tank_model_type = nil
    end
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_storage_water_heater_values(hpxml_default,
                                              [false, 18766.7, 50.0, 0.98, HPXML::LocationBasementConditioned, 125, 0.9, HPXML::WaterHeaterTankModelTypeMixed])

    # Test defaults w/ 5-bedroom house & electric storage water heater
    hpxml = _create_hpxml('base-enclosure-beds-5.xml')
    hpxml.water_heating_systems.each do |wh|
      wh.is_shared_system = nil
      wh.heating_capacity = nil
      wh.tank_volume = nil
      wh.recovery_efficiency = nil
      wh.location = nil
      wh.temperature = nil
      wh.tank_model_type = nil
    end
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_storage_water_heater_values(hpxml_default,
                                              [false, 18766.7, 66.0, 0.98, HPXML::LocationBasementConditioned, 125, 0.95, HPXML::WaterHeaterTankModelTypeMixed])

    # Test defaults w/ 3-bedroom house & 2 storage water heaters (1 electric and 1 natural gas)
    hpxml = _create_hpxml('base-dhw-multiple.xml')
    hpxml.water_heating_systems.each do |wh|
      wh.is_shared_system = nil
      next unless wh.water_heater_type == HPXML::WaterHeaterTypeStorage

      wh.heating_capacity = nil
      wh.tank_volume = nil
      wh.recovery_efficiency = nil
      wh.location = nil
      wh.temperature = nil
      wh.tank_model_type = nil
    end
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_storage_water_heater_values(hpxml_default,
                                              [false, 15354.6, 50.0, 0.98, HPXML::LocationBasementConditioned, 125, 0.95, HPXML::WaterHeaterTankModelTypeMixed],
                                              [false, 36000.0, 40.0, 0.757, HPXML::LocationBasementConditioned, 125, 0.59, HPXML::WaterHeaterTankModelTypeMixed])

    # Test inputs not overridden by defaults w/ UEF
    hpxml = _create_hpxml('base-dhw-tank-gas-uef.xml')
    hpxml.water_heating_systems.each do |wh|
      wh.first_hour_rating = nil
      wh.usage_bin = HPXML::WaterHeaterUsageBinVerySmall
      wh.tank_model_type = HPXML::WaterHeaterTankModelTypeStratified
    end
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    assert_nil(hpxml_default.water_heating_systems[0].first_hour_rating)
    assert_equal(HPXML::WaterHeaterUsageBinVerySmall, hpxml_default.water_heating_systems[0].usage_bin)
    assert_equal(HPXML::WaterHeaterTankModelTypeStratified, hpxml_default.water_heating_systems[0].tank_model_type)

    # Test defaults w/ UEF & FHR
    hpxml.water_heating_systems.each do |wh|
      wh.first_hour_rating = 40
      wh.usage_bin = nil
      wh.tank_model_type = nil
    end
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    assert_equal(40, hpxml_default.water_heating_systems[0].first_hour_rating)
    assert_equal(HPXML::WaterHeaterUsageBinLow, hpxml_default.water_heating_systems[0].usage_bin)
    assert_equal(HPXML::WaterHeaterTankModelTypeMixed, hpxml_default.water_heating_systems[0].tank_model_type)

    # Test defaults w/ UEF & no FHR
    hpxml.water_heating_systems.each do |wh|
      wh.first_hour_rating = nil
      wh.usage_bin = nil
      wh.tank_model_type = nil
    end
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    assert_nil(hpxml_default.water_heating_systems[0].first_hour_rating)
    assert_equal(HPXML::WaterHeaterUsageBinMedium, hpxml_default.water_heating_systems[0].usage_bin)
    assert_equal(HPXML::WaterHeaterTankModelTypeMixed, hpxml_default.water_heating_systems[0].tank_model_type)
  end

  def test_tankless_water_heaters
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base-dhw-tankless-gas.xml')
    hpxml.water_heating_systems[0].performance_adjustment = 0.88
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_tankless_water_heater_values(hpxml_default, [0.88])

    # Test defaults w/ EF
    hpxml.water_heating_systems[0].performance_adjustment = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_tankless_water_heater_values(hpxml_default, [0.92])

    # Test defaults w/ UEF
    hpxml.water_heating_systems[0].energy_factor = nil
    hpxml.water_heating_systems[0].uniform_energy_factor = 0.93
    hpxml.water_heating_systems[0].first_hour_rating = 5.7
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_tankless_water_heater_values(hpxml_default, [0.94])
  end

  def test_heat_pump_water_heaters
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base-dhw-tank-heat-pump.xml')
    hpxml.water_heating_systems[0].operating_mode = HPXML::WaterHeaterOperatingModeHeatPumpOnly
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_heat_pump_water_heater_values(hpxml_default, [HPXML::WaterHeaterOperatingModeHeatPumpOnly])

    # Test defaults
    hpxml.water_heating_systems[0].operating_mode = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_heat_pump_water_heater_values(hpxml_default, [HPXML::WaterHeaterOperatingModeHybridAuto])
  end

  def test_indirect_water_heaters
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base-dhw-indirect.xml')
    hpxml.water_heating_systems[0].standby_loss_value = 0.99
    hpxml.water_heating_systems[0].standby_loss_units = HPXML::UnitsDegFPerHour
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_indirect_water_heater_values(hpxml_default, [HPXML::UnitsDegFPerHour, 0.99])

    # Test defaults
    hpxml.water_heating_systems[0].standby_loss_value = nil
    hpxml.water_heating_systems[0].standby_loss_units = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_indirect_water_heater_values(hpxml_default, [HPXML::UnitsDegFPerHour, 0.843])
  end

  def test_hot_water_distribution
    # Test inputs not overridden by defaults -- standard
    hpxml = _create_hpxml('base.xml')
    hpxml.hot_water_distributions[0].pipe_r_value = 2.5
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_standard_distribution_values(hpxml_default.hot_water_distributions[0], 50.0, 2.5)

    # Test inputs not overridden by defaults -- recirculation
    hpxml = _create_hpxml('base-dhw-recirc-demand.xml')
    hpxml.hot_water_distributions[0].recirculation_pump_power = 65.0
    hpxml.hot_water_distributions[0].pipe_r_value = 2.5
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_recirc_distribution_values(hpxml_default.hot_water_distributions[0], 50.0, 50.0, 65.0, 2.5)

    # Test inputs not overridden by defaults -- shared recirculation
    hpxml = _create_hpxml('base-bldgtype-multifamily-shared-water-heater-recirc.xml')
    hpxml.hot_water_distributions[0].shared_recirculation_pump_power = 333.0
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_shared_recirc_distribution_values(hpxml_default.hot_water_distributions[0], 333.0)

    # Test defaults w/ conditioned basement
    hpxml = _create_hpxml('base.xml')
    hpxml.hot_water_distributions[0].standard_piping_length = nil
    hpxml.hot_water_distributions[0].pipe_r_value = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_standard_distribution_values(hpxml_default.hot_water_distributions[0], 93.48, 0.0)

    # Test defaults w/ unconditioned basement
    hpxml = _create_hpxml('base-foundation-unconditioned-basement.xml')
    hpxml.hot_water_distributions[0].standard_piping_length = nil
    hpxml.hot_water_distributions[0].pipe_r_value = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_standard_distribution_values(hpxml_default.hot_water_distributions[0], 88.48, 0.0)

    # Test defaults w/ 2-story building
    hpxml = _create_hpxml('base-enclosure-2stories.xml')
    hpxml.hot_water_distributions[0].standard_piping_length = nil
    hpxml.hot_water_distributions[0].pipe_r_value = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_standard_distribution_values(hpxml_default.hot_water_distributions[0], 103.48, 0.0)

    # Test defaults w/ recirculation & conditioned basement
    hpxml = _create_hpxml('base-dhw-recirc-demand.xml')
    hpxml.hot_water_distributions[0].recirculation_piping_length = nil
    hpxml.hot_water_distributions[0].recirculation_branch_piping_length = nil
    hpxml.hot_water_distributions[0].recirculation_pump_power = nil
    hpxml.hot_water_distributions[0].pipe_r_value = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_recirc_distribution_values(hpxml_default.hot_water_distributions[0], 166.96, 10.0, 50.0, 0.0)

    # Test defaults w/ recirculation & unconditioned basement
    hpxml = _create_hpxml('base-foundation-unconditioned-basement.xml')
    hpxml.hot_water_distributions.clear
    hpxml.hot_water_distributions.add(id: 'HotWaterDistribution',
                                      system_type: HPXML::DHWDistTypeRecirc,
                                      recirculation_control_type: HPXML::DHWRecirControlTypeSensor)
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_recirc_distribution_values(hpxml_default.hot_water_distributions[0], 156.96, 10.0, 50.0, 0.0)

    # Test defaults w/ recirculation & 2-story building
    hpxml = _create_hpxml('base-enclosure-2stories.xml')
    hpxml.hot_water_distributions.clear
    hpxml.hot_water_distributions.add(id: 'HotWaterDistribution',
                                      system_type: HPXML::DHWDistTypeRecirc,
                                      recirculation_control_type: HPXML::DHWRecirControlTypeSensor)
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_recirc_distribution_values(hpxml_default.hot_water_distributions[0], 186.96, 10.0, 50.0, 0.0)

    # Test defaults w/ shared recirculation
    hpxml = _create_hpxml('base-bldgtype-multifamily-shared-water-heater-recirc.xml')
    hpxml.hot_water_distributions[0].shared_recirculation_pump_power = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_shared_recirc_distribution_values(hpxml_default.hot_water_distributions[0], 220.0)
  end

  def test_water_fixtures
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base.xml')
    hpxml.water_heating.water_fixtures_usage_multiplier = 2.0
    hpxml.water_heating.water_fixtures_weekday_fractions = ConstantDaySchedule
    hpxml.water_heating.water_fixtures_weekend_fractions = ConstantDaySchedule
    hpxml.water_heating.water_fixtures_monthly_multipliers = ConstantMonthSchedule
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_water_fixture_values(hpxml_default, 2.0, ConstantDaySchedule, ConstantDaySchedule, ConstantMonthSchedule)

    # Test defaults
    hpxml.water_heating.water_fixtures_usage_multiplier = nil
    hpxml.water_heating.water_fixtures_weekday_fractions = nil
    hpxml.water_heating.water_fixtures_weekend_fractions = nil
    hpxml.water_heating.water_fixtures_monthly_multipliers = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_water_fixture_values(hpxml_default, 1.0, Schedule.FixturesWeekdayFractions, Schedule.FixturesWeekendFractions, Schedule.FixturesMonthlyMultipliers)
  end

  def test_solar_thermal_systems
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base-dhw-solar-direct-flat-plate.xml')
    hpxml.solar_thermal_systems[0].storage_volume = 55.0
    hpxml.solar_thermal_systems[0].collector_azimuth = 123
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_solar_thermal_values(hpxml_default.solar_thermal_systems[0], 55.0, 123)

    # Test defaults w/ collector area of 40 sqft
    hpxml.solar_thermal_systems[0].storage_volume = nil
    hpxml.solar_thermal_systems[0].collector_orientation = HPXML::OrientationNorth
    hpxml.solar_thermal_systems[0].collector_azimuth = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_solar_thermal_values(hpxml_default.solar_thermal_systems[0], 60.0, 0)

    # Test defaults w/ collector area of 100 sqft
    hpxml.solar_thermal_systems[0].collector_area = 100.0
    hpxml.solar_thermal_systems[0].storage_volume = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_solar_thermal_values(hpxml_default.solar_thermal_systems[0], 150.0, 0)
  end

  def test_pv_systems
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base-bldgtype-attached.xml')
    hpxml.pv_systems.add(id: 'PVSystem',
                         is_shared_system: true,
                         number_of_bedrooms_served: 20,
                         system_losses_fraction: 0.20,
                         location: HPXML::LocationGround,
                         tracking: HPXML::PVTrackingType1Axis,
                         module_type: HPXML::PVModuleTypePremium,
                         array_azimuth: 123,
                         array_tilt: 0,
                         max_power_output: 1000,
                         inverter_idref: 'Inverter')
    hpxml.inverters.add(id: 'Inverter',
                        inverter_efficiency: 0.90)
    pv = hpxml.pv_systems[0]
    inv = hpxml.inverters[0]
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_pv_system_values(hpxml_default, 0.90, 0.20, true, HPXML::LocationGround, HPXML::PVTrackingType1Axis, HPXML::PVModuleTypePremium, 123)

    # Test defaults w/o year modules manufactured
    pv.is_shared_system = nil
    pv.system_losses_fraction = nil
    pv.location = nil
    pv.tracking = nil
    pv.module_type = nil
    pv.array_orientation = HPXML::OrientationSoutheast
    pv.array_azimuth = nil
    inv.inverter_efficiency = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_pv_system_values(hpxml_default, 0.96, 0.14, false, HPXML::LocationRoof, HPXML::PVTrackingTypeFixed, HPXML::PVModuleTypeStandard, 135)

    # Test defaults w/ year modules manufactured
    pv.year_modules_manufactured = 2010
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_pv_system_values(hpxml_default, 0.96, 0.194, false, HPXML::LocationRoof, HPXML::PVTrackingTypeFixed, HPXML::PVModuleTypeStandard, 135)
  end

  def test_batteries
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base-pv-battery.xml')
    hpxml.batteries[0].nominal_capacity_kwh = 45.0
    hpxml.batteries[0].nominal_capacity_ah = nil
    hpxml.batteries[0].usable_capacity_kwh = 34.0
    hpxml.batteries[0].usable_capacity_ah = nil
    hpxml.batteries[0].rated_power_output = 1234.0
    hpxml.batteries[0].location = HPXML::LocationBasementConditioned
    # hpxml.batteries[0].lifetime_model = HPXML::BatteryLifetimeModelKandlerSmith
    hpxml.batteries[0].round_trip_efficiency = 0.9
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_battery_values(hpxml_default.batteries[0], 45.0, nil, 34.0, nil, 1234.0, HPXML::LocationBasementConditioned, nil, 0.9)

    # Test w/ Ah instead of kWh
    hpxml.batteries[0].nominal_capacity_kwh = nil
    hpxml.batteries[0].nominal_capacity_ah = 987.0
    hpxml.batteries[0].usable_capacity_kwh = nil
    hpxml.batteries[0].usable_capacity_ah = 876.0
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_battery_values(hpxml_default.batteries[0], nil, 987.0, nil, 876.0, 1234.0, HPXML::LocationBasementConditioned, nil, 0.9)

    # Test defaults
    hpxml.batteries[0].nominal_capacity_kwh = nil
    hpxml.batteries[0].nominal_capacity_ah = nil
    hpxml.batteries[0].usable_capacity_kwh = nil
    hpxml.batteries[0].usable_capacity_ah = nil
    hpxml.batteries[0].rated_power_output = nil
    hpxml.batteries[0].location = nil
    hpxml.batteries[0].lifetime_model = nil
    hpxml.batteries[0].round_trip_efficiency = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_battery_values(hpxml_default.batteries[0], 10.0, nil, 9.0, nil, 5000.0, HPXML::LocationOutside, nil, 0.925)

    # Test defaults w/ nominal kWh
    hpxml.batteries[0].nominal_capacity_kwh = 14.0
    hpxml.batteries[0].nominal_capacity_ah = nil
    hpxml.batteries[0].usable_capacity_kwh = nil
    hpxml.batteries[0].usable_capacity_ah = nil
    hpxml.batteries[0].rated_power_output = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_battery_values(hpxml_default.batteries[0], 14.0, nil, 12.6, nil, 7000.0, HPXML::LocationOutside, nil, 0.925)

    # Test defaults w/ usable kWh
    hpxml.batteries[0].nominal_capacity_kwh = nil
    hpxml.batteries[0].nominal_capacity_ah = nil
    hpxml.batteries[0].usable_capacity_kwh = 12.0
    hpxml.batteries[0].usable_capacity_ah = nil
    hpxml.batteries[0].rated_power_output = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_battery_values(hpxml_default.batteries[0], 13.33, nil, 12.0, nil, 6665.0, HPXML::LocationOutside, nil, 0.925)

    # Test defaults w/ nominal Ah
    hpxml.batteries[0].nominal_capacity_kwh = nil
    hpxml.batteries[0].nominal_capacity_ah = 280.0
    hpxml.batteries[0].usable_capacity_kwh = nil
    hpxml.batteries[0].usable_capacity_ah = nil
    hpxml.batteries[0].rated_power_output = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_battery_values(hpxml_default.batteries[0], nil, 280.0, nil, 252.0, 7000.0, HPXML::LocationOutside, nil, 0.925)

    # Test defaults w/ usable Ah
    hpxml.batteries[0].nominal_capacity_kwh = nil
    hpxml.batteries[0].nominal_capacity_ah = nil
    hpxml.batteries[0].usable_capacity_kwh = nil
    hpxml.batteries[0].usable_capacity_ah = 240.0
    hpxml.batteries[0].rated_power_output = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_battery_values(hpxml_default.batteries[0], nil, 266.67, nil, 240.0, 6667.0, HPXML::LocationOutside, nil, 0.925)

    # Test defaults w/ rated power output
    hpxml.batteries[0].nominal_capacity_kwh = nil
    hpxml.batteries[0].nominal_capacity_ah = nil
    hpxml.batteries[0].usable_capacity_kwh = nil
    hpxml.batteries[0].usable_capacity_ah = nil
    hpxml.batteries[0].rated_power_output = 10000.0
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_battery_values(hpxml_default.batteries[0], 20.0, nil, 18.0, nil, 10000.0, HPXML::LocationOutside, nil, 0.925)

    # Test defaults w/ garage
    hpxml = _create_hpxml('base-pv-battery-garage.xml')
    hpxml.batteries[0].nominal_capacity_kwh = nil
    hpxml.batteries[0].nominal_capacity_ah = nil
    hpxml.batteries[0].usable_capacity_kwh = nil
    hpxml.batteries[0].usable_capacity_ah = nil
    hpxml.batteries[0].rated_power_output = nil
    hpxml.batteries[0].location = nil
    hpxml.batteries[0].lifetime_model = nil
    hpxml.batteries[0].round_trip_efficiency = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_battery_values(hpxml_default.batteries[0], 10.0, nil, 9.0, nil, 5000.0, HPXML::LocationGarage, nil, 0.925)
  end

  def test_generators
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base-bldgtype-attached.xml')
    hpxml.generators.add(id: 'Generator',
                         is_shared_system: true,
                         number_of_bedrooms_served: 20,
                         fuel_type: HPXML::FuelTypeNaturalGas,
                         annual_consumption_kbtu: 8500,
                         annual_output_kwh: 500)
    generator = hpxml.generators[0]
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_generator_values(hpxml_default, true)

    # Test defaults
    generator.is_shared_system = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_generator_values(hpxml_default, false)
  end

  def test_clothes_washers
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base-bldgtype-attached.xml')
    hpxml.water_heating_systems[0].is_shared_system = true
    hpxml.water_heating_systems[0].number_of_units_served = 6
    hpxml.clothes_washers[0].location = HPXML::LocationBasementConditioned
    hpxml.clothes_washers[0].is_shared_appliance = true
    hpxml.clothes_washers[0].usage_multiplier = 1.5
    hpxml.clothes_washers[0].water_heating_system_idref = hpxml.water_heating_systems[0].id
    hpxml.clothes_washers[0].weekday_fractions = ConstantDaySchedule
    hpxml.clothes_washers[0].weekend_fractions = ConstantDaySchedule
    hpxml.clothes_washers[0].monthly_multipliers = ConstantMonthSchedule
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_clothes_washer_values(hpxml_default.clothes_washers[0], true, HPXML::LocationBasementConditioned, 1.21, 380.0, 0.12, 1.09, 27.0, 3.2, 6.0, 1.5, ConstantDaySchedule, ConstantDaySchedule, ConstantMonthSchedule)

    # Test defaults
    hpxml.clothes_washers[0].is_shared_appliance = nil
    hpxml.clothes_washers[0].location = nil
    hpxml.clothes_washers[0].integrated_modified_energy_factor = nil
    hpxml.clothes_washers[0].rated_annual_kwh = nil
    hpxml.clothes_washers[0].label_electric_rate = nil
    hpxml.clothes_washers[0].label_gas_rate = nil
    hpxml.clothes_washers[0].label_annual_gas_cost = nil
    hpxml.clothes_washers[0].capacity = nil
    hpxml.clothes_washers[0].label_usage = nil
    hpxml.clothes_washers[0].usage_multiplier = nil
    hpxml.clothes_washers[0].weekday_fractions = nil
    hpxml.clothes_washers[0].weekend_fractions = nil
    hpxml.clothes_washers[0].monthly_multipliers = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_clothes_washer_values(hpxml_default.clothes_washers[0], false, HPXML::LocationLivingSpace, 1.0, 400.0, 0.12, 1.09, 27.0, 3.0, 6.0, 1.0, Schedule.ClothesWasherWeekdayFractions, Schedule.ClothesWasherWeekendFractions, Schedule.ClothesWasherMonthlyMultipliers)

    # Test defaults before 301-2019 Addendum A
    hpxml = _create_hpxml('base.xml')
    hpxml.header.eri_calculation_version = '2019'
    hpxml.clothes_washers[0].is_shared_appliance = nil
    hpxml.clothes_washers[0].location = nil
    hpxml.clothes_washers[0].integrated_modified_energy_factor = nil
    hpxml.clothes_washers[0].rated_annual_kwh = nil
    hpxml.clothes_washers[0].label_electric_rate = nil
    hpxml.clothes_washers[0].label_gas_rate = nil
    hpxml.clothes_washers[0].label_annual_gas_cost = nil
    hpxml.clothes_washers[0].capacity = nil
    hpxml.clothes_washers[0].label_usage = nil
    hpxml.clothes_washers[0].usage_multiplier = nil
    hpxml.clothes_washers[0].weekday_fractions = nil
    hpxml.clothes_washers[0].weekend_fractions = nil
    hpxml.clothes_washers[0].monthly_multipliers = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_clothes_washer_values(hpxml_default.clothes_washers[0], false, HPXML::LocationLivingSpace, 0.331, 704.0, 0.08, 0.58, 23.0, 2.874, 999, 1.0, Schedule.ClothesWasherWeekdayFractions, Schedule.ClothesWasherWeekendFractions, Schedule.ClothesWasherMonthlyMultipliers)
  end

  def test_clothes_dryers
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base-bldgtype-attached.xml')
    hpxml.water_heating_systems[0].is_shared_system = true
    hpxml.water_heating_systems[0].number_of_units_served = 6
    hpxml.clothes_dryers[0].location = HPXML::LocationBasementConditioned
    hpxml.clothes_dryers[0].is_shared_appliance = true
    hpxml.clothes_dryers[0].combined_energy_factor = 3.33
    hpxml.clothes_dryers[0].usage_multiplier = 1.1
    hpxml.clothes_dryers[0].weekday_fractions = ConstantDaySchedule
    hpxml.clothes_dryers[0].weekend_fractions = ConstantDaySchedule
    hpxml.clothes_dryers[0].monthly_multipliers = ConstantMonthSchedule
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_clothes_dryer_values(hpxml_default.clothes_dryers[0], true, HPXML::LocationBasementConditioned, 3.33, 1.1, ConstantDaySchedule, ConstantDaySchedule, ConstantMonthSchedule)

    # Test defaults w/ electric clothes dryer
    hpxml.clothes_dryers[0].location = nil
    hpxml.clothes_dryers[0].is_shared_appliance = nil
    hpxml.clothes_dryers[0].combined_energy_factor = nil
    hpxml.clothes_dryers[0].usage_multiplier = nil
    hpxml.clothes_dryers[0].weekday_fractions = nil
    hpxml.clothes_dryers[0].weekend_fractions = nil
    hpxml.clothes_dryers[0].monthly_multipliers = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_clothes_dryer_values(hpxml_default.clothes_dryers[0], false, HPXML::LocationLivingSpace, 3.01, 1.0, Schedule.ClothesDryerWeekdayFractions, Schedule.ClothesDryerWeekendFractions, Schedule.ClothesDryerMonthlyMultipliers)

    # Test defaults w/ gas clothes dryer
    hpxml.clothes_dryers[0].fuel_type = HPXML::FuelTypeNaturalGas
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_clothes_dryer_values(hpxml_default.clothes_dryers[0], false, HPXML::LocationLivingSpace, 3.01, 1.0, Schedule.ClothesDryerWeekdayFractions, Schedule.ClothesDryerWeekendFractions, Schedule.ClothesDryerMonthlyMultipliers)

    # Test defaults w/ electric clothes dryer before 301-2019 Addendum A
    hpxml.header.eri_calculation_version = '2019'
    hpxml.clothes_dryers[0].fuel_type = HPXML::FuelTypeElectricity
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_clothes_dryer_values(hpxml_default.clothes_dryers[0], false, HPXML::LocationLivingSpace, 2.62, 1.0, Schedule.ClothesDryerWeekdayFractions, Schedule.ClothesDryerWeekendFractions, Schedule.ClothesDryerMonthlyMultipliers)

    # Test defaults w/ gas clothes dryer before 301-2019 Addendum A
    hpxml.clothes_dryers[0].fuel_type = HPXML::FuelTypeNaturalGas
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_clothes_dryer_values(hpxml_default.clothes_dryers[0], false, HPXML::LocationLivingSpace, 2.32, 1.0, Schedule.ClothesDryerWeekdayFractions, Schedule.ClothesDryerWeekendFractions, Schedule.ClothesDryerMonthlyMultipliers)
  end

  def test_clothes_dryer_exhaust
    # Test inputs not overridden by defaults w/ vented dryer
    hpxml_name = 'base.xml'
    hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
    clothes_dryer = hpxml.clothes_dryers[0]
    clothes_dryer.is_vented = true
    clothes_dryer.vented_flow_rate = 200
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_clothes_dryer_exhaust_values(hpxml_default.clothes_dryers[0], true, 200)

    # Test inputs not overridden by defaults w/ unvented dryer
    clothes_dryer.is_vented = false
    clothes_dryer.vented_flow_rate = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_clothes_dryer_exhaust_values(hpxml_default.clothes_dryers[0], false, nil)

    # Test defaults
    clothes_dryer.is_vented = nil
    clothes_dryer.vented_flow_rate = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_clothes_dryer_exhaust_values(hpxml_default.clothes_dryers[0], true, 100)
  end

  def test_dishwashers
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base-bldgtype-attached.xml')
    hpxml.water_heating_systems[0].is_shared_system = true
    hpxml.water_heating_systems[0].number_of_units_served = 6
    hpxml.dishwashers[0].location = HPXML::LocationBasementConditioned
    hpxml.dishwashers[0].is_shared_appliance = true
    hpxml.dishwashers[0].usage_multiplier = 1.3
    hpxml.dishwashers[0].water_heating_system_idref = hpxml.water_heating_systems[0].id
    hpxml.dishwashers[0].weekday_fractions = ConstantDaySchedule
    hpxml.dishwashers[0].weekend_fractions = ConstantDaySchedule
    hpxml.dishwashers[0].monthly_multipliers = ConstantMonthSchedule
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_dishwasher_values(hpxml_default.dishwashers[0], true, HPXML::LocationBasementConditioned, 307.0, 0.12, 1.09, 22.32, 4.0, 12, 1.3, ConstantDaySchedule, ConstantDaySchedule, ConstantMonthSchedule)

    # Test defaults
    hpxml.dishwashers[0].is_shared_appliance = nil
    hpxml.dishwashers[0].location = nil
    hpxml.dishwashers[0].rated_annual_kwh = nil
    hpxml.dishwashers[0].label_electric_rate = nil
    hpxml.dishwashers[0].label_gas_rate = nil
    hpxml.dishwashers[0].label_annual_gas_cost = nil
    hpxml.dishwashers[0].label_usage = nil
    hpxml.dishwashers[0].place_setting_capacity = nil
    hpxml.dishwashers[0].usage_multiplier = nil
    hpxml.dishwashers[0].weekday_fractions = nil
    hpxml.dishwashers[0].weekend_fractions = nil
    hpxml.dishwashers[0].monthly_multipliers = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_dishwasher_values(hpxml_default.dishwashers[0], false, HPXML::LocationLivingSpace, 467.0, 0.12, 1.09, 33.12, 4.0, 12, 1.0, Schedule.DishwasherWeekdayFractions, Schedule.DishwasherWeekendFractions, Schedule.DishwasherMonthlyMultipliers)

    # Test defaults before 301-2019 Addendum A
    hpxml.header.eri_calculation_version = '2019'
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_dishwasher_values(hpxml_default.dishwashers[0], false, HPXML::LocationLivingSpace, 467.0, 999, 999, 999, 999, 12, 1.0, Schedule.DishwasherWeekdayFractions, Schedule.DishwasherWeekendFractions, Schedule.DishwasherMonthlyMultipliers)
  end

  def test_refrigerators
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base.xml')
    hpxml.refrigerators[0].location = HPXML::LocationBasementConditioned
    hpxml.refrigerators[0].usage_multiplier = 1.2
    hpxml.refrigerators[0].weekday_fractions = ConstantDaySchedule
    hpxml.refrigerators[0].weekend_fractions = ConstantDaySchedule
    hpxml.refrigerators[0].monthly_multipliers = ConstantMonthSchedule
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_refrigerator_values(hpxml_default, HPXML::LocationBasementConditioned, 650.0, 1.2, ConstantDaySchedule, ConstantDaySchedule, ConstantMonthSchedule)

    # Test defaults
    hpxml.refrigerators[0].location = nil
    hpxml.refrigerators[0].rated_annual_kwh = nil
    hpxml.refrigerators[0].usage_multiplier = nil
    hpxml.refrigerators[0].weekday_fractions = nil
    hpxml.refrigerators[0].weekend_fractions = nil
    hpxml.refrigerators[0].monthly_multipliers = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_refrigerator_values(hpxml_default, HPXML::LocationLivingSpace, 691.0, 1.0, Schedule.RefrigeratorWeekdayFractions, Schedule.RefrigeratorWeekendFractions, Schedule.RefrigeratorMonthlyMultipliers)

    # Test defaults w/ refrigerator in 5-bedroom house
    hpxml.building_construction.number_of_bedrooms = 5
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_refrigerator_values(hpxml_default, HPXML::LocationLivingSpace, 727.0, 1.0, Schedule.RefrigeratorWeekdayFractions, Schedule.RefrigeratorWeekendFractions, Schedule.RefrigeratorMonthlyMultipliers)

    # Test defaults before 301-2019 Addendum A
    hpxml.header.eri_calculation_version = '2019'
    hpxml.building_construction.number_of_bedrooms = 3
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_refrigerator_values(hpxml_default, HPXML::LocationLivingSpace, 691.0, 1.0, Schedule.RefrigeratorWeekdayFractions, Schedule.RefrigeratorWeekendFractions, Schedule.RefrigeratorMonthlyMultipliers)
  end

  def test_extra_refrigerators
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base-misc-loads-large-uncommon.xml')
    hpxml.refrigerators.each do |refrigerator|
      refrigerator.location = HPXML::LocationLivingSpace
      refrigerator.rated_annual_kwh = 333.0
      refrigerator.usage_multiplier = 1.5
      refrigerator.weekday_fractions = ConstantDaySchedule
      refrigerator.weekend_fractions = ConstantDaySchedule
      refrigerator.monthly_multipliers = ConstantMonthSchedule
    end
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_extra_refrigerators_values(hpxml_default, HPXML::LocationLivingSpace, 333.0, 1.5, ConstantDaySchedule, ConstantDaySchedule, ConstantMonthSchedule)

    # Test defaults
    hpxml.refrigerators.each do |refrigerator|
      refrigerator.location = nil
      refrigerator.rated_annual_kwh = nil
      refrigerator.usage_multiplier = nil
      refrigerator.weekday_fractions = nil
      refrigerator.weekend_fractions = nil
      refrigerator.monthly_multipliers = nil
    end
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_extra_refrigerators_values(hpxml_default, HPXML::LocationBasementConditioned, 244.0, 1.0, Schedule.ExtraRefrigeratorWeekdayFractions, Schedule.ExtraRefrigeratorWeekendFractions, Schedule.ExtraRefrigeratorMonthlyMultipliers)
  end

  def test_freezers
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base-misc-loads-large-uncommon.xml')
    hpxml.freezers.each do |freezer|
      freezer.location = HPXML::LocationLivingSpace
      freezer.rated_annual_kwh = 333.0
      freezer.usage_multiplier = 1.5
      freezer.weekday_fractions = ConstantDaySchedule
      freezer.weekend_fractions = ConstantDaySchedule
      freezer.monthly_multipliers = ConstantMonthSchedule
    end
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_freezers_values(hpxml_default, HPXML::LocationLivingSpace, 333.0, 1.5, ConstantDaySchedule, ConstantDaySchedule, ConstantMonthSchedule)

    # Test defaults
    hpxml.freezers.each do |freezer|
      freezer.location = nil
      freezer.rated_annual_kwh = nil
      freezer.usage_multiplier = nil
      freezer.weekday_fractions = nil
      freezer.weekend_fractions = nil
      freezer.monthly_multipliers = nil
    end
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_freezers_values(hpxml_default, HPXML::LocationBasementConditioned, 320.0, 1.0, Schedule.FreezerWeekdayFractions, Schedule.FreezerWeekendFractions, Schedule.FreezerMonthlyMultipliers)
  end

  def test_cooking_ranges
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base.xml')
    hpxml.cooking_ranges[0].location = HPXML::LocationBasementConditioned
    hpxml.cooking_ranges[0].is_induction = true
    hpxml.cooking_ranges[0].usage_multiplier = 1.1
    hpxml.cooking_ranges[0].weekday_fractions = ConstantDaySchedule
    hpxml.cooking_ranges[0].weekend_fractions = ConstantDaySchedule
    hpxml.cooking_ranges[0].monthly_multipliers = ConstantMonthSchedule
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_cooking_range_values(hpxml_default.cooking_ranges[0], HPXML::LocationBasementConditioned, true, 1.1, ConstantDaySchedule, ConstantDaySchedule, ConstantMonthSchedule)

    # Test defaults
    hpxml.cooking_ranges[0].location = nil
    hpxml.cooking_ranges[0].is_induction = nil
    hpxml.cooking_ranges[0].usage_multiplier = nil
    hpxml.cooking_ranges[0].weekday_fractions = nil
    hpxml.cooking_ranges[0].weekend_fractions = nil
    hpxml.cooking_ranges[0].monthly_multipliers = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_cooking_range_values(hpxml_default.cooking_ranges[0], HPXML::LocationLivingSpace, false, 1.0, Schedule.CookingRangeWeekdayFractions, Schedule.CookingRangeWeekendFractions, Schedule.CookingRangeMonthlyMultipliers)

    # Test defaults before 301-2019 Addendum A
    hpxml.header.eri_calculation_version = '2019'
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_cooking_range_values(hpxml_default.cooking_ranges[0], HPXML::LocationLivingSpace, false, 1.0, Schedule.CookingRangeWeekdayFractions, Schedule.CookingRangeWeekendFractions, Schedule.CookingRangeMonthlyMultipliers)
  end

  def test_ovens
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base.xml')
    hpxml.ovens[0].is_convection = true
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_oven_values(hpxml_default.ovens[0], true)

    # Test defaults
    hpxml.ovens[0].is_convection = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_oven_values(hpxml_default.ovens[0], false)

    # Test defaults before 301-2019 Addendum A
    hpxml.header.eri_calculation_version = '2019'
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_oven_values(hpxml_default.ovens[0], false)
  end

  def test_lighting
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base.xml')
    hpxml.lighting.interior_usage_multiplier = 2.0
    hpxml.lighting.garage_usage_multiplier = 2.0
    hpxml.lighting.exterior_usage_multiplier = 2.0
    hpxml.lighting.interior_weekday_fractions = ConstantDaySchedule
    hpxml.lighting.interior_weekend_fractions = ConstantDaySchedule
    hpxml.lighting.interior_monthly_multipliers = ConstantMonthSchedule
    hpxml.lighting.exterior_weekday_fractions = ConstantDaySchedule
    hpxml.lighting.exterior_weekend_fractions = ConstantDaySchedule
    hpxml.lighting.exterior_monthly_multipliers = ConstantMonthSchedule
    hpxml.lighting.garage_weekday_fractions = ConstantDaySchedule
    hpxml.lighting.garage_weekend_fractions = ConstantDaySchedule
    hpxml.lighting.garage_monthly_multipliers = ConstantMonthSchedule
    hpxml.lighting.holiday_exists = true
    hpxml.lighting.holiday_kwh_per_day = 0.7
    hpxml.lighting.holiday_period_begin_month = 10
    hpxml.lighting.holiday_period_begin_day = 19
    hpxml.lighting.holiday_period_end_month = 12
    hpxml.lighting.holiday_period_end_day = 31
    hpxml.lighting.holiday_weekday_fractions = ConstantDaySchedule
    hpxml.lighting.holiday_weekend_fractions = ConstantDaySchedule
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_lighting_values(hpxml_default, 2.0, 2.0, 2.0,
                                  { int_wk_sch: ConstantDaySchedule,
                                    int_wknd_sch: ConstantDaySchedule,
                                    int_month_mult: ConstantMonthSchedule,
                                    ext_wk_sch: ConstantDaySchedule,
                                    ext_wknd_sch: ConstantDaySchedule,
                                    ext_month_mult: ConstantMonthSchedule,
                                    grg_wk_sch: ConstantDaySchedule,
                                    grg_wknd_sch: ConstantDaySchedule,
                                    grg_month_mult: ConstantMonthSchedule,
                                    hol_kwh_per_day: 0.7,
                                    hol_begin_month: 10,
                                    hol_begin_day: 19,
                                    hol_end_month: 12,
                                    hol_end_day: 31,
                                    hol_wk_sch: ConstantDaySchedule,
                                    hol_wknd_sch: ConstantDaySchedule })

    # Test defaults
    hpxml.lighting.interior_usage_multiplier = nil
    hpxml.lighting.garage_usage_multiplier = nil
    hpxml.lighting.exterior_usage_multiplier = nil
    hpxml.lighting.interior_weekday_fractions = nil
    hpxml.lighting.interior_weekend_fractions = nil
    hpxml.lighting.interior_monthly_multipliers = nil
    hpxml.lighting.exterior_weekday_fractions = nil
    hpxml.lighting.exterior_weekend_fractions = nil
    hpxml.lighting.exterior_monthly_multipliers = nil
    hpxml.lighting.garage_weekday_fractions = nil
    hpxml.lighting.garage_weekend_fractions = nil
    hpxml.lighting.garage_monthly_multipliers = nil
    hpxml.lighting.holiday_exists = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_lighting_values(hpxml_default, 1.0, 1.0, 1.0,
                                  { ext_wk_sch: Schedule.LightingExteriorWeekdayFractions,
                                    ext_wknd_sch: Schedule.LightingExteriorWeekendFractions,
                                    ext_month_mult: Schedule.LightingExteriorMonthlyMultipliers })

    # Test defaults w/ holiday lighting
    hpxml.lighting.holiday_exists = true
    hpxml.lighting.holiday_kwh_per_day = nil
    hpxml.lighting.holiday_period_begin_month = nil
    hpxml.lighting.holiday_period_begin_day = nil
    hpxml.lighting.holiday_period_end_month = nil
    hpxml.lighting.holiday_period_end_day = nil
    hpxml.lighting.holiday_weekday_fractions = nil
    hpxml.lighting.holiday_weekend_fractions = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_lighting_values(hpxml_default, 1.0, 1.0, 1.0,
                                  { ext_wk_sch: Schedule.LightingExteriorWeekdayFractions,
                                    ext_wknd_sch: Schedule.LightingExteriorWeekendFractions,
                                    ext_month_mult: Schedule.LightingExteriorMonthlyMultipliers,
                                    hol_kwh_per_day: 1.1,
                                    hol_begin_month: 11,
                                    hol_begin_day: 24,
                                    hol_end_month: 1,
                                    hol_end_day: 6,
                                    hol_wk_sch: Schedule.LightingExteriorHolidayWeekdayFractions,
                                    hol_wknd_sch: Schedule.LightingExteriorHolidayWeekendFractions })
    # Test defaults w/ garage
    hpxml = _create_hpxml('base-enclosure-garage.xml')
    hpxml.lighting.interior_usage_multiplier = nil
    hpxml.lighting.garage_usage_multiplier = nil
    hpxml.lighting.exterior_usage_multiplier = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_lighting_values(hpxml_default, 1.0, 1.0, 1.0,
                                  { ext_wk_sch: Schedule.LightingExteriorWeekdayFractions,
                                    ext_wknd_sch: Schedule.LightingExteriorWeekendFractions,
                                    ext_month_mult: Schedule.LightingExteriorMonthlyMultipliers,
                                    grg_wk_sch: Schedule.LightingExteriorWeekdayFractions,
                                    grg_wknd_sch: Schedule.LightingExteriorWeekendFractions,
                                    grg_month_mult: Schedule.LightingExteriorMonthlyMultipliers })
  end

  def test_ceiling_fans
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base-lighting-ceiling-fans.xml')
    hpxml.ceiling_fans[0].count = 2
    hpxml.ceiling_fans[0].efficiency = 100
    hpxml.ceiling_fans[0].weekday_fractions = ConstantDaySchedule
    hpxml.ceiling_fans[0].weekend_fractions = ConstantDaySchedule
    hpxml.ceiling_fans[0].monthly_multipliers = ConstantMonthSchedule
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_ceiling_fan_values(hpxml_default.ceiling_fans[0], 2, 100, ConstantDaySchedule, ConstantDaySchedule, ConstantMonthSchedule)

    # Test defaults
    hpxml.ceiling_fans.each do |ceiling_fan|
      ceiling_fan.count = nil
      ceiling_fan.efficiency = nil
      ceiling_fan.weekday_fractions = nil
      ceiling_fan.weekend_fractions = nil
      ceiling_fan.monthly_multipliers = nil
    end
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_ceiling_fan_values(hpxml_default.ceiling_fans[0], 4, 70.4, Schedule.CeilingFanWeekdayFractions, Schedule.CeilingFanWeekendFractions, '0, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0')
  end

  def test_pools
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base-misc-loads-large-uncommon.xml')
    pool = hpxml.pools[0]
    pool.heater_load_units = HPXML::UnitsKwhPerYear
    pool.heater_load_value = 1000
    pool.heater_usage_multiplier = 1.4
    pool.heater_weekday_fractions = ConstantDaySchedule
    pool.heater_weekend_fractions = ConstantDaySchedule
    pool.heater_monthly_multipliers = ConstantMonthSchedule
    pool.pump_kwh_per_year = 3000
    pool.pump_usage_multiplier = 1.3
    pool.pump_weekday_fractions = ConstantDaySchedule
    pool.pump_weekend_fractions = ConstantDaySchedule
    pool.pump_monthly_multipliers = ConstantMonthSchedule
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_pool_heater_values(hpxml_default.pools[0], HPXML::UnitsKwhPerYear, 1000, 1.4, ConstantDaySchedule, ConstantDaySchedule, ConstantMonthSchedule)
    _test_default_pool_pump_values(hpxml_default.pools[0], 3000, 1.3, ConstantDaySchedule, ConstantDaySchedule, ConstantMonthSchedule)

    # Test defaults
    pool = hpxml.pools[0]
    pool.heater_load_units = nil
    pool.heater_load_value = nil
    pool.heater_usage_multiplier = nil
    pool.heater_weekday_fractions = nil
    pool.heater_weekend_fractions = nil
    pool.heater_monthly_multipliers = nil
    pool.pump_kwh_per_year = nil
    pool.pump_usage_multiplier = nil
    pool.pump_weekday_fractions = nil
    pool.pump_weekend_fractions = nil
    pool.pump_monthly_multipliers = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_pool_heater_values(hpxml_default.pools[0], HPXML::UnitsThermPerYear, 236, 1.0, Schedule.PoolHeaterWeekdayFractions, Schedule.PoolHeaterWeekendFractions, Schedule.PoolHeaterMonthlyMultipliers)
    _test_default_pool_pump_values(hpxml_default.pools[0], 2496, 1.0, Schedule.PoolPumpWeekdayFractions, Schedule.PoolPumpWeekendFractions, Schedule.PoolPumpMonthlyMultipliers)

    # Test defaults 2
    hpxml = _create_hpxml('base-misc-loads-large-uncommon2.xml')
    pool = hpxml.pools[0]
    pool.heater_load_units = nil
    pool.heater_load_value = nil
    pool.heater_usage_multiplier = nil
    pool.heater_weekday_fractions = nil
    pool.heater_weekend_fractions = nil
    pool.heater_monthly_multipliers = nil
    pool.pump_kwh_per_year = nil
    pool.pump_usage_multiplier = nil
    pool.pump_weekday_fractions = nil
    pool.pump_weekend_fractions = nil
    pool.pump_monthly_multipliers = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_pool_heater_values(hpxml_default.pools[0], nil, nil, nil, nil, nil, nil)
    _test_default_pool_pump_values(hpxml_default.pools[0], 2496, 1.0, Schedule.PoolPumpWeekdayFractions, Schedule.PoolPumpWeekendFractions, Schedule.PoolPumpMonthlyMultipliers)
  end

  def test_hot_tubs
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base-misc-loads-large-uncommon.xml')
    hot_tub = hpxml.hot_tubs[0]
    hot_tub.heater_load_units = HPXML::UnitsThermPerYear
    hot_tub.heater_load_value = 1000
    hot_tub.heater_usage_multiplier = 0.8
    hot_tub.heater_weekday_fractions = ConstantDaySchedule
    hot_tub.heater_weekend_fractions = ConstantDaySchedule
    hot_tub.heater_monthly_multipliers = ConstantMonthSchedule
    hot_tub.pump_kwh_per_year = 3000
    hot_tub.pump_usage_multiplier = 0.7
    hot_tub.pump_weekday_fractions = ConstantDaySchedule
    hot_tub.pump_weekend_fractions = ConstantDaySchedule
    hot_tub.pump_monthly_multipliers = ConstantMonthSchedule
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_hot_tub_heater_values(hpxml_default.hot_tubs[0], HPXML::UnitsThermPerYear, 1000, 0.8, ConstantDaySchedule, ConstantDaySchedule, ConstantMonthSchedule)
    _test_default_hot_tub_pump_values(hpxml_default.hot_tubs[0], 3000, 0.7, ConstantDaySchedule, ConstantDaySchedule, ConstantMonthSchedule)

    # Test defaults
    hot_tub = hpxml.hot_tubs[0]
    hot_tub.heater_load_units = nil
    hot_tub.heater_load_value = nil
    hot_tub.heater_usage_multiplier = nil
    hot_tub.heater_weekday_fractions = nil
    hot_tub.heater_weekend_fractions = nil
    hot_tub.heater_monthly_multipliers = nil
    hot_tub.pump_kwh_per_year = nil
    hot_tub.pump_usage_multiplier = nil
    hot_tub.pump_weekday_fractions = nil
    hot_tub.pump_weekend_fractions = nil
    hot_tub.pump_monthly_multipliers = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_hot_tub_heater_values(hpxml_default.hot_tubs[0], HPXML::UnitsKwhPerYear, 1125, 1.0, Schedule.HotTubHeaterWeekdayFractions, Schedule.HotTubHeaterWeekendFractions, Schedule.HotTubHeaterMonthlyMultipliers)
    _test_default_hot_tub_pump_values(hpxml_default.hot_tubs[0], 1111, 1.0, Schedule.HotTubPumpWeekdayFractions, Schedule.HotTubPumpWeekendFractions, Schedule.HotTubPumpMonthlyMultipliers)

    # Test defaults 2
    hpxml = _create_hpxml('base-misc-loads-large-uncommon2.xml')
    hot_tub = hpxml.hot_tubs[0]
    hot_tub.heater_load_units = nil
    hot_tub.heater_load_value = nil
    hot_tub.heater_usage_multiplier = nil
    hot_tub.heater_weekday_fractions = nil
    hot_tub.heater_weekend_fractions = nil
    hot_tub.heater_monthly_multipliers = nil
    hot_tub.pump_kwh_per_year = nil
    hot_tub.pump_usage_multiplier = nil
    hot_tub.pump_weekday_fractions = nil
    hot_tub.pump_weekend_fractions = nil
    hot_tub.pump_monthly_multipliers = nil
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_hot_tub_heater_values(hpxml_default.hot_tubs[0], HPXML::UnitsKwhPerYear, 225, 1.0, Schedule.HotTubHeaterWeekdayFractions, Schedule.HotTubHeaterWeekendFractions, Schedule.HotTubHeaterMonthlyMultipliers)
    _test_default_hot_tub_pump_values(hpxml_default.hot_tubs[0], 1111, 1.0, Schedule.HotTubPumpWeekdayFractions, Schedule.HotTubPumpWeekendFractions, Schedule.HotTubPumpMonthlyMultipliers)
  end

  def test_plug_loads
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base-misc-loads-large-uncommon.xml')
    tv_pl = hpxml.plug_loads.find { |pl| pl.plug_load_type == HPXML::PlugLoadTypeTelevision }
    tv_pl.kwh_per_year = 1000
    tv_pl.usage_multiplier = 1.1
    tv_pl.frac_sensible = 0.6
    tv_pl.frac_latent = 0.3
    tv_pl.weekday_fractions = ConstantDaySchedule
    tv_pl.weekend_fractions = ConstantDaySchedule
    tv_pl.monthly_multipliers = ConstantMonthSchedule
    other_pl = hpxml.plug_loads.find { |pl| pl.plug_load_type == HPXML::PlugLoadTypeOther }
    other_pl.kwh_per_year = 2000
    other_pl.usage_multiplier = 1.2
    other_pl.frac_sensible = 0.5
    other_pl.frac_latent = 0.4
    other_pl.weekday_fractions = ConstantDaySchedule
    other_pl.weekend_fractions = ConstantDaySchedule
    other_pl.monthly_multipliers = ConstantMonthSchedule
    veh_pl = hpxml.plug_loads.find { |pl| pl.plug_load_type == HPXML::PlugLoadTypeElectricVehicleCharging }
    veh_pl.kwh_per_year = 4000
    veh_pl.usage_multiplier = 1.3
    veh_pl.frac_sensible = 0.4
    veh_pl.frac_latent = 0.5
    veh_pl.weekday_fractions = ConstantDaySchedule
    veh_pl.weekend_fractions = ConstantDaySchedule
    veh_pl.monthly_multipliers = ConstantMonthSchedule
    wellpump_pl = hpxml.plug_loads.find { |pl| pl.plug_load_type == HPXML::PlugLoadTypeWellPump }
    wellpump_pl.kwh_per_year = 3000
    wellpump_pl.usage_multiplier = 1.4
    wellpump_pl.frac_sensible = 0.3
    wellpump_pl.frac_latent = 0.6
    wellpump_pl.weekday_fractions = ConstantDaySchedule
    wellpump_pl.weekend_fractions = ConstantDaySchedule
    wellpump_pl.monthly_multipliers = ConstantMonthSchedule
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_plug_load_values(hpxml_default, HPXML::PlugLoadTypeTelevision, 1000, 0.6, 0.3, 1.1, ConstantDaySchedule, ConstantDaySchedule, ConstantMonthSchedule)
    _test_default_plug_load_values(hpxml_default, HPXML::PlugLoadTypeOther, 2000, 0.5, 0.4, 1.2, ConstantDaySchedule, ConstantDaySchedule, ConstantMonthSchedule)
    _test_default_plug_load_values(hpxml_default, HPXML::PlugLoadTypeElectricVehicleCharging, 4000, 0.4, 0.5, 1.3, ConstantDaySchedule, ConstantDaySchedule, ConstantMonthSchedule)
    _test_default_plug_load_values(hpxml_default, HPXML::PlugLoadTypeWellPump, 3000, 0.3, 0.6, 1.4, ConstantDaySchedule, ConstantDaySchedule, ConstantMonthSchedule)

    # Test defaults
    hpxml.plug_loads.each do |plug_load|
      plug_load.kwh_per_year = nil
      plug_load.usage_multiplier = nil
      plug_load.frac_sensible = nil
      plug_load.frac_latent = nil
      plug_load.weekday_fractions = nil
      plug_load.weekend_fractions = nil
      plug_load.monthly_multipliers = nil
    end
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_plug_load_values(hpxml_default, HPXML::PlugLoadTypeTelevision, 620, 1.0, 0.0, 1.0, Schedule.PlugLoadsTVWeekdayFractions, Schedule.PlugLoadsTVWeekendFractions, Schedule.PlugLoadsTVMonthlyMultipliers)
    _test_default_plug_load_values(hpxml_default, HPXML::PlugLoadTypeOther, 2457, 0.855, 0.045, 1.0, Schedule.PlugLoadsOtherWeekdayFractions, Schedule.PlugLoadsOtherWeekendFractions, Schedule.PlugLoadsOtherMonthlyMultipliers)
    _test_default_plug_load_values(hpxml_default, HPXML::PlugLoadTypeElectricVehicleCharging, 1667, 0.0, 0.0, 1.0, Schedule.PlugLoadsVehicleWeekdayFractions, Schedule.PlugLoadsVehicleWeekendFractions, Schedule.PlugLoadsVehicleMonthlyMultipliers)
    _test_default_plug_load_values(hpxml_default, HPXML::PlugLoadTypeWellPump, 441, 0.0, 0.0, 1.0, Schedule.PlugLoadsWellPumpWeekdayFractions, Schedule.PlugLoadsWellPumpWeekendFractions, Schedule.PlugLoadsWellPumpMonthlyMultipliers)
  end

  def test_fuel_loads
    # Test inputs not overridden by defaults
    hpxml = _create_hpxml('base-misc-loads-large-uncommon.xml')
    gg_fl = hpxml.fuel_loads.find { |fl| fl.fuel_load_type == HPXML::FuelLoadTypeGrill }
    gg_fl.therm_per_year = 1000
    gg_fl.usage_multiplier = 0.9
    gg_fl.frac_sensible = 0.6
    gg_fl.frac_latent = 0.3
    gg_fl.weekday_fractions = ConstantDaySchedule
    gg_fl.weekend_fractions = ConstantDaySchedule
    gg_fl.monthly_multipliers = ConstantMonthSchedule
    gl_fl = hpxml.fuel_loads.find { |fl| fl.fuel_load_type == HPXML::FuelLoadTypeLighting }
    gl_fl.therm_per_year = 2000
    gl_fl.usage_multiplier = 0.8
    gl_fl.frac_sensible = 0.5
    gl_fl.frac_latent = 0.4
    gl_fl.weekday_fractions = ConstantDaySchedule
    gl_fl.weekend_fractions = ConstantDaySchedule
    gl_fl.monthly_multipliers = ConstantMonthSchedule
    gf_fl = hpxml.fuel_loads.find { |fl| fl.fuel_load_type == HPXML::FuelLoadTypeFireplace }
    gf_fl.therm_per_year = 3000
    gf_fl.usage_multiplier = 0.7
    gf_fl.frac_sensible = 0.4
    gf_fl.frac_latent = 0.5
    gf_fl.weekday_fractions = ConstantDaySchedule
    gf_fl.weekend_fractions = ConstantDaySchedule
    gf_fl.monthly_multipliers = ConstantMonthSchedule
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_fuel_load_values(hpxml_default, HPXML::FuelLoadTypeGrill, 1000, 0.6, 0.3, 0.9, ConstantDaySchedule, ConstantDaySchedule, ConstantMonthSchedule)
    _test_default_fuel_load_values(hpxml_default, HPXML::FuelLoadTypeLighting, 2000, 0.5, 0.4, 0.8, ConstantDaySchedule, ConstantDaySchedule, ConstantMonthSchedule)
    _test_default_fuel_load_values(hpxml_default, HPXML::FuelLoadTypeFireplace, 3000, 0.4, 0.5, 0.7, ConstantDaySchedule, ConstantDaySchedule, ConstantMonthSchedule)

    # Test defaults
    hpxml.fuel_loads.each do |fuel_load|
      fuel_load.therm_per_year = nil
      fuel_load.usage_multiplier = nil
      fuel_load.frac_sensible = nil
      fuel_load.frac_latent = nil
      fuel_load.weekday_fractions = nil
      fuel_load.weekend_fractions = nil
      fuel_load.monthly_multipliers = nil
    end
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    hpxml_default = _test_measure()
    _test_default_fuel_load_values(hpxml_default, HPXML::FuelLoadTypeGrill, 33, 0.0, 0.0, 1.0, Schedule.FuelLoadsGrillWeekdayFractions, Schedule.FuelLoadsGrillWeekendFractions, Schedule.FuelLoadsGrillMonthlyMultipliers)
    _test_default_fuel_load_values(hpxml_default, HPXML::FuelLoadTypeLighting, 20, 0.0, 0.0, 1.0, Schedule.FuelLoadsLightingWeekdayFractions, Schedule.FuelLoadsLightingWeekendFractions, Schedule.FuelLoadsLightingMonthlyMultipliers)
    _test_default_fuel_load_values(hpxml_default, HPXML::FuelLoadTypeFireplace, 67, 0.5, 0.1, 1.0, Schedule.FuelLoadsFireplaceWeekdayFractions, Schedule.FuelLoadsFireplaceWeekendFractions, Schedule.FuelLoadsFireplaceMonthlyMultipliers)
  end

  def _test_measure()
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
      if @args_hash.has_key?(arg.name)
        assert(temp_arg_var.setValue(@args_hash[arg.name]))
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

    hpxml_default = HPXML.new(hpxml_path: File.join(@tmp_output_path, 'in.xml'))

    return hpxml_default
  end

  def _test_default_header_values(hpxml, tstep, sim_begin_month, sim_begin_day, sim_end_month, sim_end_day, sim_calendar_year,
                                  dst_enabled, dst_begin_month, dst_begin_day, dst_end_month, dst_end_day, heat_pump_sizing_methodology,
                                  allow_increased_fixed_capacities, state_code, time_zone_utc_offset, temperature_capacitance_multiplier,
                                  natvent_days_per_week, unavailable_period_begin_hour, unavailable_period_end_hour, unavailable_period_natvent_availability,
                                  shading_summer_begin_month, shading_summer_begin_day, shading_summer_end_month, shading_summer_end_day,
                                  manualj_heating_design_temp, manualj_cooling_design_temp, manualj_heating_setpoint, manualj_cooling_setpoint,
                                  manualj_humidity_setpoint, manualj_internal_loads_sensible, manualj_internal_loads_latent, manualj_num_occupants)
    assert_equal(tstep, hpxml.header.timestep)
    assert_equal(sim_begin_month, hpxml.header.sim_begin_month)
    assert_equal(sim_begin_day, hpxml.header.sim_begin_day)
    assert_equal(sim_end_month, hpxml.header.sim_end_month)
    assert_equal(sim_end_day, hpxml.header.sim_end_day)
    assert_equal(sim_calendar_year, hpxml.header.sim_calendar_year)
    assert_equal(dst_enabled, hpxml.header.dst_enabled)
    assert_equal(dst_begin_month, hpxml.header.dst_begin_month)
    assert_equal(dst_begin_day, hpxml.header.dst_begin_day)
    assert_equal(dst_end_month, hpxml.header.dst_end_month)
    assert_equal(dst_end_day, hpxml.header.dst_end_day)
    if heat_pump_sizing_methodology.nil?
      assert_nil(hpxml.header.heat_pump_sizing_methodology)
    else
      assert_equal(heat_pump_sizing_methodology, hpxml.header.heat_pump_sizing_methodology)
    end
    assert_equal(allow_increased_fixed_capacities, hpxml.header.allow_increased_fixed_capacities)
    if state_code.nil?
      assert_nil(hpxml.header.state_code)
    else
      assert_equal(state_code, hpxml.header.state_code)
    end
    assert_equal(time_zone_utc_offset, hpxml.header.time_zone_utc_offset)
    assert_equal(temperature_capacitance_multiplier, hpxml.header.temperature_capacitance_multiplier)
    assert_equal(natvent_days_per_week, hpxml.header.natvent_days_per_week)
    if unavailable_period_begin_hour.nil? && unavailable_period_end_hour.nil? && unavailable_period_natvent_availability.nil?
      assert_equal(0, hpxml.header.unavailable_periods.size)
    else
      assert_equal(unavailable_period_begin_hour, hpxml.header.unavailable_periods[-1].begin_hour)
      assert_equal(unavailable_period_end_hour, hpxml.header.unavailable_periods[-1].end_hour)
      assert_equal(unavailable_period_natvent_availability, hpxml.header.unavailable_periods[-1].natvent_availability)
    end
    assert_equal(shading_summer_begin_month, hpxml.header.shading_summer_begin_month)
    assert_equal(shading_summer_begin_day, hpxml.header.shading_summer_begin_day)
    assert_equal(shading_summer_end_month, hpxml.header.shading_summer_end_month)
    assert_equal(shading_summer_end_day, hpxml.header.shading_summer_end_day)
    assert_in_epsilon(manualj_heating_design_temp, hpxml.header.manualj_heating_design_temp, 0.01)
    assert_in_epsilon(manualj_cooling_design_temp, hpxml.header.manualj_cooling_design_temp, 0.01)
    assert_equal(manualj_heating_setpoint, hpxml.header.manualj_heating_setpoint)
    assert_equal(manualj_cooling_setpoint, hpxml.header.manualj_cooling_setpoint)
    assert_equal(manualj_humidity_setpoint, hpxml.header.manualj_humidity_setpoint)
    assert_equal(manualj_internal_loads_sensible, hpxml.header.manualj_internal_loads_sensible)
    assert_equal(manualj_internal_loads_latent, hpxml.header.manualj_internal_loads_latent)
    assert_equal(manualj_num_occupants, hpxml.header.manualj_num_occupants)
  end

  def _test_default_emissions_values(scenario, elec_schedule_number_of_header_rows, elec_schedule_column_number,
                                     natural_gas_units, natural_gas_value, propane_units, propane_value,
                                     fuel_oil_units, fuel_oil_value, coal_units, coal_value, wood_units, wood_value,
                                     wood_pellets_units, wood_pellets_value)
    assert_equal(elec_schedule_number_of_header_rows, scenario.elec_schedule_number_of_header_rows)
    assert_equal(elec_schedule_column_number, scenario.elec_schedule_column_number)
    if natural_gas_value.nil?
      assert_nil(scenario.natural_gas_units)
      assert_nil(scenario.natural_gas_value)
    else
      assert_equal(natural_gas_units, scenario.natural_gas_units)
      assert_equal(natural_gas_value, scenario.natural_gas_value)
    end
    if propane_value.nil?
      assert_nil(scenario.propane_units)
      assert_nil(scenario.propane_value)
    else
      assert_equal(propane_units, scenario.propane_units)
      assert_equal(propane_value, scenario.propane_value)
    end
    if fuel_oil_value.nil?
      assert_nil(scenario.fuel_oil_units)
      assert_nil(scenario.fuel_oil_value)
    else
      assert_equal(fuel_oil_units, scenario.fuel_oil_units)
      assert_equal(fuel_oil_value, scenario.fuel_oil_value)
    end
    if coal_value.nil?
      assert_nil(scenario.coal_units)
      assert_nil(scenario.coal_value)
    else
      assert_equal(coal_units, scenario.coal_units)
      assert_equal(coal_value, scenario.coal_value)
    end
    if wood_value.nil?
      assert_nil(scenario.wood_units)
      assert_nil(scenario.wood_value)
    else
      assert_equal(wood_units, scenario.wood_units)
      assert_equal(wood_value, scenario.wood_value)
    end
    if wood_pellets_value.nil?
      assert_nil(scenario.wood_pellets_units)
      assert_nil(scenario.wood_pellets_value)
    else
      assert_equal(wood_pellets_units, scenario.wood_pellets_units)
      assert_equal(wood_pellets_value, scenario.wood_pellets_value)
    end
  end

  def _test_default_bills_values(scenario,
                                 elec_fixed_charge, natural_gas_fixed_charge, propane_fixed_charge, fuel_oil_fixed_charge, coal_fixed_charge, wood_fixed_charge, wood_pellets_fixed_charge,
                                 elec_marginal_rate, natural_gas_marginal_rate, propane_marginal_rate, fuel_oil_marginal_rate, coal_marginal_rate, wood_marginal_rate, wood_pellets_marginal_rate,
                                 pv_compensation_type, pv_net_metering_annual_excess_sellback_rate_type, pv_net_metering_annual_excess_sellback_rate,
                                 pv_feed_in_tariff_rate, pv_monthly_grid_connection_fee_dollars_per_kw, pv_monthly_grid_connection_fee_dollars)
    if elec_fixed_charge.nil?
      assert_nil(scenario.elec_fixed_charge)
    else
      assert_equal(elec_fixed_charge, scenario.elec_fixed_charge)
    end
    if natural_gas_fixed_charge.nil?
      assert_nil(scenario.natural_gas_fixed_charge)
    else
      assert_equal(natural_gas_fixed_charge, scenario.natural_gas_fixed_charge)
    end
    if propane_fixed_charge.nil?
      assert_nil(scenario.propane_fixed_charge)
    else
      assert_equal(propane_fixed_charge, scenario.propane_fixed_charge)
    end
    if fuel_oil_fixed_charge.nil?
      assert_nil(scenario.fuel_oil_fixed_charge)
    else
      assert_equal(fuel_oil_fixed_charge, scenario.fuel_oil_fixed_charge)
    end
    if coal_fixed_charge.nil?
      assert_nil(scenario.coal_fixed_charge)
    else
      assert_equal(coal_fixed_charge, scenario.coal_fixed_charge)
    end
    if wood_fixed_charge.nil?
      assert_nil(scenario.wood_fixed_charge)
    else
      assert_equal(wood_fixed_charge, scenario.wood_fixed_charge)
    end
    if wood_pellets_fixed_charge.nil?
      assert_nil(scenario.wood_pellets_fixed_charge)
    else
      assert_equal(wood_pellets_fixed_charge, scenario.wood_pellets_fixed_charge)
    end
    if elec_marginal_rate.nil?
      assert_nil(scenario.elec_marginal_rate)
    else
      assert_equal(elec_marginal_rate, scenario.elec_marginal_rate)
    end
    if natural_gas_marginal_rate.nil?
      assert_nil(scenario.natural_gas_marginal_rate)
    else
      assert_equal(natural_gas_marginal_rate, scenario.natural_gas_marginal_rate)
    end
    if propane_marginal_rate.nil?
      assert_nil(scenario.propane_marginal_rate)
    else
      assert_equal(propane_marginal_rate, scenario.propane_marginal_rate)
    end
    if fuel_oil_marginal_rate.nil?
      assert_nil(scenario.fuel_oil_marginal_rate)
    else
      assert_equal(fuel_oil_marginal_rate, scenario.fuel_oil_marginal_rate)
    end
    if coal_marginal_rate.nil?
      assert_nil(scenario.coal_marginal_rate)
    else
      assert_equal(coal_marginal_rate, scenario.coal_marginal_rate)
    end
    if wood_marginal_rate.nil?
      assert_nil(scenario.wood_marginal_rate)
    else
      assert_equal(wood_marginal_rate, scenario.wood_marginal_rate)
    end
    if wood_pellets_marginal_rate.nil?
      assert_nil(scenario.wood_pellets_marginal_rate)
    else
      assert_equal(wood_pellets_marginal_rate, scenario.wood_pellets_marginal_rate)
    end
    if pv_compensation_type.nil?
      assert_nil(scenario.pv_compensation_type)
    else
      assert_equal(pv_compensation_type, scenario.pv_compensation_type)
    end
    if pv_net_metering_annual_excess_sellback_rate_type.nil?
      assert_nil(scenario.pv_net_metering_annual_excess_sellback_rate_type)
    else
      assert_equal(pv_net_metering_annual_excess_sellback_rate_type, scenario.pv_net_metering_annual_excess_sellback_rate_type)
    end
    if pv_net_metering_annual_excess_sellback_rate.nil?
      assert_nil(scenario.pv_net_metering_annual_excess_sellback_rate)
    else
      assert_equal(pv_net_metering_annual_excess_sellback_rate, scenario.pv_net_metering_annual_excess_sellback_rate)
    end
    if pv_feed_in_tariff_rate.nil?
      assert_nil(scenario.pv_feed_in_tariff_rate)
    else
      assert_equal(pv_feed_in_tariff_rate, scenario.pv_feed_in_tariff_rate)
    end
    if pv_monthly_grid_connection_fee_dollars_per_kw.nil?
      assert_nil(scenario.pv_monthly_grid_connection_fee_dollars_per_kw)
    else
      assert_equal(pv_monthly_grid_connection_fee_dollars_per_kw, scenario.pv_monthly_grid_connection_fee_dollars_per_kw)
    end
    if pv_monthly_grid_connection_fee_dollars.nil?
      assert_nil(scenario.pv_monthly_grid_connection_fee_dollars)
    else
      assert_equal(pv_monthly_grid_connection_fee_dollars, scenario.pv_monthly_grid_connection_fee_dollars)
    end
  end

  def _test_default_site_values(hpxml, site_type, shielding_of_home, ground_conductivity)
    assert_equal(site_type, hpxml.site.site_type)
    assert_equal(shielding_of_home, hpxml.site.shielding_of_home)
    assert_equal(ground_conductivity, hpxml.site.ground_conductivity)
  end

  def _test_default_neighbor_building_values(hpxml, azimuths)
    assert_equal(azimuths.size, hpxml.neighbor_buildings.size)
    hpxml.neighbor_buildings.each_with_index do |neighbor_building, idx|
      assert_equal(azimuths[idx], neighbor_building.azimuth)
    end
  end

  def _test_default_occupancy_values(hpxml, weekday_sch, weekend_sch, monthly_mults)
    if weekday_sch.nil?
      assert_nil(hpxml.building_occupancy.weekday_fractions)
    else
      assert_equal(weekday_sch, hpxml.building_occupancy.weekday_fractions)
    end
    if weekend_sch.nil?
      assert_nil(hpxml.building_occupancy.weekend_fractions)
    else
      assert_equal(weekend_sch, hpxml.building_occupancy.weekend_fractions)
    end
    if monthly_mults.nil?
      assert_nil(hpxml.building_occupancy.monthly_multipliers)
    else
      assert_equal(monthly_mults, hpxml.building_occupancy.monthly_multipliers)
    end
  end

  def _test_default_climate_and_risk_zones_values(hpxml, iecc_year, iecc_zone)
    if iecc_year.nil?
      assert_equal(0, hpxml.climate_and_risk_zones.climate_zone_ieccs.size)
    else
      assert_equal(iecc_year, hpxml.climate_and_risk_zones.climate_zone_ieccs[0].year)
    end
    if iecc_zone.nil?
      assert_equal(0, hpxml.climate_and_risk_zones.climate_zone_ieccs.size)
    else
      assert_equal(iecc_zone, hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone)
    end
  end

  def _test_default_building_construction_values(hpxml, building_volume, average_ceiling_height, n_bathrooms)
    assert_equal(building_volume, hpxml.building_construction.conditioned_building_volume)
    assert_in_epsilon(average_ceiling_height, hpxml.building_construction.average_ceiling_height, 0.01)
    assert_equal(n_bathrooms, hpxml.building_construction.number_of_bathrooms)
  end

  def _test_default_infiltration_values(hpxml, volume, has_flue_or_chimney_in_conditioned_space)
    assert_equal(volume, hpxml.air_infiltration_measurements[0].infiltration_volume)
    assert_equal(has_flue_or_chimney_in_conditioned_space, hpxml.air_infiltration.has_flue_or_chimney_in_conditioned_space)
  end

  def _test_default_infiltration_compartmentalization_test_values(air_infiltration_measurement, a_ext)
    if a_ext.nil?
      assert_nil(air_infiltration_measurement.a_ext)
    else
      assert_in_delta(a_ext, air_infiltration_measurement.a_ext, 0.001)
    end
  end

  def _test_default_attic_values(attic, sla)
    assert_in_epsilon(sla, attic.vented_attic_sla, 0.001)
  end

  def _test_default_foundation_values(foundation, sla)
    assert_in_epsilon(sla, foundation.vented_crawlspace_sla, 0.001)
  end

  def _test_default_roof_values(roof, roof_type, solar_absorptance, roof_color, emittance, radiant_barrier,
                                radiant_barrier_grade, int_finish_type, int_finish_thickness, azimuth)
    assert_equal(roof_type, roof.roof_type)
    assert_equal(solar_absorptance, roof.solar_absorptance)
    assert_equal(roof_color, roof.roof_color)
    assert_equal(emittance, roof.emittance)
    assert_equal(radiant_barrier, roof.radiant_barrier)
    if not radiant_barrier_grade.nil?
      assert_equal(radiant_barrier_grade, roof.radiant_barrier_grade)
    else
      assert_nil(roof.radiant_barrier_grade)
    end
    assert_equal(int_finish_type, roof.interior_finish_type)
    if not int_finish_thickness.nil?
      assert_equal(int_finish_thickness, roof.interior_finish_thickness)
    else
      assert_nil(roof.interior_finish_thickness)
    end
    assert_equal(azimuth, roof.azimuth)
  end

  def _test_default_rim_joist_values(rim_joist, siding, solar_absorptance, color, emittance, azimuth)
    assert_equal(siding, rim_joist.siding)
    assert_equal(solar_absorptance, rim_joist.solar_absorptance)
    assert_equal(color, rim_joist.color)
    assert_equal(emittance, rim_joist.emittance)
    assert_equal(azimuth, rim_joist.azimuth)
  end

  def _test_default_wall_values(wall, siding, solar_absorptance, color, emittance, int_finish_type, int_finish_thickness, azimuth)
    assert_equal(siding, wall.siding)
    assert_equal(solar_absorptance, wall.solar_absorptance)
    assert_equal(color, wall.color)
    assert_equal(emittance, wall.emittance)
    assert_equal(int_finish_type, wall.interior_finish_type)
    if not int_finish_thickness.nil?
      assert_equal(int_finish_thickness, wall.interior_finish_thickness)
    else
      assert_nil(wall.interior_finish_thickness)
    end
    if not azimuth.nil?
      assert_equal(azimuth, wall.azimuth)
    else
      assert_nil(wall.azimuth)
    end
  end

  def _test_default_foundation_wall_values(foundation_wall, thickness, int_finish_type, int_finish_thickness, azimuth, area,
                                           ins_int_top, ins_int_bottom, ins_ext_top, ins_ext_bottom, type)
    assert_equal(thickness, foundation_wall.thickness)
    assert_equal(int_finish_type, foundation_wall.interior_finish_type)
    if not int_finish_thickness.nil?
      assert_equal(int_finish_thickness, foundation_wall.interior_finish_thickness)
    else
      assert_nil(foundation_wall.interior_finish_thickness)
    end
    assert_equal(azimuth, foundation_wall.azimuth)
    assert_equal(area, foundation_wall.area)
    assert_equal(ins_int_top, foundation_wall.insulation_interior_distance_to_top)
    assert_equal(ins_int_bottom, foundation_wall.insulation_interior_distance_to_bottom)
    assert_equal(ins_ext_top, foundation_wall.insulation_exterior_distance_to_top)
    assert_equal(ins_ext_bottom, foundation_wall.insulation_exterior_distance_to_bottom)
    assert_equal(type, foundation_wall.type)
  end

  def _test_default_floor_values(floor, int_finish_type, int_finish_thickness)
    assert_equal(int_finish_type, floor.interior_finish_type)
    if not int_finish_thickness.nil?
      assert_equal(int_finish_thickness, floor.interior_finish_thickness)
    else
      assert_nil(floor.interior_finish_thickness)
    end
  end

  def _test_default_slab_values(slab, thickness, carpet_r_value, carpet_fraction)
    assert_equal(thickness, slab.thickness)
    assert_equal(carpet_r_value, slab.carpet_r_value)
    assert_equal(carpet_fraction, slab.carpet_fraction)
  end

  def _test_default_window_values(hpxml, ext_summer_sfs, ext_winter_sfs, int_summer_sfs, int_winter_sfs, fraction_operable, azimuths)
    assert_equal(ext_summer_sfs.size, hpxml.windows.size)
    hpxml.windows.each_with_index do |window, idx|
      assert_equal(ext_summer_sfs[idx], window.exterior_shading_factor_summer)
      assert_equal(ext_winter_sfs[idx], window.exterior_shading_factor_winter)
      assert_equal(int_summer_sfs[idx], window.interior_shading_factor_summer)
      assert_equal(int_winter_sfs[idx], window.interior_shading_factor_winter)
      assert_equal(fraction_operable[idx], window.fraction_operable)
      assert_equal(azimuths[idx], window.azimuth)
    end
  end

  def _test_default_skylight_values(hpxml, ext_summer_sfs, ext_winter_sfs, int_summer_sfs, int_winter_sfs, azimuths)
    assert_equal(ext_summer_sfs.size, hpxml.skylights.size)
    hpxml.skylights.each_with_index do |skylight, idx|
      assert_equal(ext_summer_sfs[idx], skylight.exterior_shading_factor_summer)
      assert_equal(ext_winter_sfs[idx], skylight.exterior_shading_factor_winter)
      assert_equal(int_summer_sfs[idx], skylight.interior_shading_factor_summer)
      assert_equal(int_winter_sfs[idx], skylight.interior_shading_factor_winter)
      assert_equal(azimuths[idx], skylight.azimuth)
    end
  end

  def _test_default_door_values(hpxml, azimuths)
    hpxml.doors.each_with_index do |door, idx|
      assert_equal(azimuths[idx], door.azimuth)
    end
  end

  def _test_default_partition_wall_mass_values(partition_wall_mass, area_fraction, int_finish_type, int_finish_thickness)
    assert_equal(area_fraction, partition_wall_mass.area_fraction)
    assert_equal(int_finish_type, partition_wall_mass.interior_finish_type)
    assert_equal(int_finish_thickness, partition_wall_mass.interior_finish_thickness)
  end

  def _test_default_furniture_mass_values(furniture_mass, area_fraction, type)
    assert_equal(area_fraction, furniture_mass.area_fraction)
    assert_equal(type, furniture_mass.type)
  end

  def _test_default_central_air_conditioner_values(cooling_system, shr, compressor_type, fan_watts_per_cfm, charge_defect_ratio,
                                                   airflow_defect_ratio, cooling_capacity, cooling_efficiency_seer, crankcase_heater_watts)
    assert_equal(shr, cooling_system.cooling_shr)
    assert_equal(compressor_type, cooling_system.compressor_type)
    assert_equal(fan_watts_per_cfm, cooling_system.fan_watts_per_cfm)
    assert_equal(charge_defect_ratio, cooling_system.charge_defect_ratio)
    assert_equal(airflow_defect_ratio, cooling_system.airflow_defect_ratio)
    assert_equal(crankcase_heater_watts, cooling_system.crankcase_heater_watts)
    if cooling_capacity.nil?
      assert(cooling_system.cooling_capacity > 0)
    else
      assert_equal(cooling_capacity, cooling_system.cooling_capacity)
    end
    if cooling_efficiency_seer.nil?
      assert_nil(cooling_system.cooling_efficiency_seer)
    else
      assert_equal(cooling_efficiency_seer, cooling_system.cooling_efficiency_seer)
    end
  end

  def _test_default_room_air_conditioner_ptac_values(cooling_system, shr, cooling_capacity, crankcase_heater_watts)
    assert_equal(shr, cooling_system.cooling_shr)
    assert_equal(crankcase_heater_watts, cooling_system.crankcase_heater_watts)
    if cooling_capacity.nil?
      assert(cooling_system.cooling_capacity > 0)
    else
      assert_equal(cooling_capacity, cooling_system.cooling_capacity)
    end
  end

  def _test_default_evap_cooler_values(cooling_system, cooling_capacity)
    if cooling_capacity.nil?
      assert(cooling_system.cooling_capacity > 0)
    else
      assert_equal(cooling_system.cooling_capacity, cooling_capacity)
    end
  end

  def _test_default_mini_split_air_conditioner_values(cooling_system, shr, fan_watts_per_cfm, charge_defect_ratio,
                                                      airflow_defect_ratio, cooling_capacity, cooling_efficiency_seer, crankcase_heater_watts)
    assert_equal(shr, cooling_system.cooling_shr)
    assert_equal(fan_watts_per_cfm, cooling_system.fan_watts_per_cfm)
    assert_equal(charge_defect_ratio, cooling_system.charge_defect_ratio)
    assert_equal(airflow_defect_ratio, cooling_system.airflow_defect_ratio)
    assert_equal(crankcase_heater_watts, cooling_system.crankcase_heater_watts)
    if cooling_capacity.nil?
      assert(cooling_system.cooling_capacity > 0)
    else
      assert_equal(cooling_capacity, cooling_system.cooling_capacity)
    end
    if cooling_efficiency_seer.nil?
      assert_nil(cooling_system.cooling_efficiency_seer)
    else
      assert_equal(cooling_efficiency_seer, cooling_system.cooling_efficiency_seer)
    end
    assert_equal(HPXML::HVACCompressorTypeVariableSpeed, cooling_system.compressor_type)
  end

  def _test_default_furnace_values(heating_system, fan_watts_per_cfm, airflow_defect_ratio, heating_capacity,
                                   pilot_light, pilot_light_btuh)
    assert_equal(fan_watts_per_cfm, heating_system.fan_watts_per_cfm)
    assert_equal(airflow_defect_ratio, heating_system.airflow_defect_ratio)
    if heating_capacity.nil?
      assert(heating_system.heating_capacity > 0)
    else
      assert_equal(heating_capacity, heating_system.heating_capacity)
    end
    assert_equal(pilot_light, heating_system.pilot_light)
    if pilot_light_btuh.nil?
      assert_nil(heating_system.pilot_light_btuh)
    else
      assert_equal(pilot_light_btuh, heating_system.pilot_light_btuh)
    end
  end

  def _test_default_wall_furnace_values(heating_system, fan_watts, heating_capacity)
    assert_equal(fan_watts, heating_system.fan_watts)
    if heating_capacity.nil?
      assert(heating_system.heating_capacity > 0)
    else
      assert_equal(heating_capacity, heating_system.heating_capacity)
    end
  end

  def _test_default_floor_furnace_values(heating_system, fan_watts, heating_capacity, pilot_light, pilot_light_btuh)
    assert_equal(fan_watts, heating_system.fan_watts)
    if heating_capacity.nil?
      assert(heating_system.heating_capacity > 0)
    else
      assert_equal(heating_capacity, heating_system.heating_capacity)
    end
    assert_equal(pilot_light, heating_system.pilot_light)
    if pilot_light_btuh.nil?
      assert_nil(heating_system.pilot_light_btuh)
    else
      assert_equal(pilot_light_btuh, heating_system.pilot_light_btuh)
    end
  end

  def _test_default_boiler_values(heating_system, eae, heating_capacity, pilot_light, pilot_light_btuh)
    assert_equal(eae, heating_system.electric_auxiliary_energy)
    if heating_capacity.nil?
      assert(heating_system.heating_capacity > 0)
    else
      assert_equal(heating_capacity, heating_system.heating_capacity)
    end
    assert_equal(pilot_light, heating_system.pilot_light)
    if pilot_light_btuh.nil?
      assert_nil(heating_system.pilot_light_btuh)
    else
      assert_equal(pilot_light_btuh, heating_system.pilot_light_btuh)
    end
  end

  def _test_default_stove_values(heating_system, fan_watts, heating_capacity, pilot_light, pilot_light_btuh)
    assert_equal(fan_watts, heating_system.fan_watts)
    if heating_capacity.nil?
      assert(heating_system.heating_capacity > 0)
    else
      assert_equal(heating_capacity, heating_system.heating_capacity)
    end
    assert_equal(pilot_light, heating_system.pilot_light)
    if pilot_light_btuh.nil?
      assert_nil(heating_system.pilot_light_btuh)
    else
      assert_equal(pilot_light_btuh, heating_system.pilot_light_btuh)
    end
  end

  def _test_default_portable_heater_values(heating_system, fan_watts, heating_capacity)
    assert_equal(fan_watts, heating_system.fan_watts)
    if heating_capacity.nil?
      assert(heating_system.heating_capacity > 0)
    else
      assert_equal(heating_capacity, heating_system.heating_capacity)
    end
  end

  def _test_default_fixed_heater_values(heating_system, fan_watts, heating_capacity)
    assert_equal(fan_watts, heating_system.fan_watts)
    if heating_capacity.nil?
      assert(heating_system.heating_capacity > 0)
    else
      assert_equal(heating_capacity, heating_system.heating_capacity)
    end
  end

  def _test_default_fireplace_values(heating_system, fan_watts, heating_capacity, pilot_light, pilot_light_btuh)
    assert_equal(fan_watts, heating_system.fan_watts)
    if heating_capacity.nil?
      assert(heating_system.heating_capacity > 0)
    else
      assert_equal(heating_capacity, heating_system.heating_capacity)
    end
    assert_equal(pilot_light, heating_system.pilot_light)
    if pilot_light_btuh.nil?
      assert_nil(heating_system.pilot_light_btuh)
    else
      assert_equal(pilot_light_btuh, heating_system.pilot_light_btuh)
    end
  end

  def _test_default_air_to_air_heat_pump_values(heat_pump, shr, compressor_type, fan_watts_per_cfm, charge_defect_ratio,
                                                airflow_defect_ratio, cooling_capacity, heating_capacity,
                                                heating_capacity_17F, backup_heating_capacity,
                                                cooling_efficiency_seer, heating_efficiency_hspf,
                                                heating_capacity_retention_fraction, heating_capacity_retention_temp,
                                                crankcase_heater_watts)
    assert_equal(shr, heat_pump.cooling_shr)
    assert_equal(compressor_type, heat_pump.compressor_type)
    assert_equal(fan_watts_per_cfm, heat_pump.fan_watts_per_cfm)
    assert_equal(charge_defect_ratio, heat_pump.charge_defect_ratio)
    assert_equal(airflow_defect_ratio, heat_pump.airflow_defect_ratio)
    assert_equal(crankcase_heater_watts, heat_pump.crankcase_heater_watts)
    if cooling_capacity.nil?
      assert(heat_pump.cooling_capacity > 0)
    else
      assert_equal(cooling_capacity, heat_pump.cooling_capacity)
    end
    if heating_capacity.nil?
      assert(heat_pump.heating_capacity > 0)
    else
      assert_equal(heating_capacity, heat_pump.heating_capacity)
    end
    if heating_capacity_17F.nil?
      assert_nil(heat_pump.heating_capacity_17F)
    else
      assert_equal(heating_capacity_17F, heat_pump.heating_capacity_17F)
    end
    if backup_heating_capacity.nil?
      assert(heat_pump.backup_heating_capacity > 0)
    else
      assert_equal(backup_heating_capacity, heat_pump.backup_heating_capacity)
    end
    if cooling_efficiency_seer.nil?
      assert_nil(heat_pump.cooling_efficiency_seer)
    else
      assert_equal(cooling_efficiency_seer, heat_pump.cooling_efficiency_seer)
    end
    if heating_efficiency_hspf.nil?
      assert_nil(heat_pump.heating_efficiency_hspf)
    else
      assert_equal(heating_efficiency_hspf, heat_pump.heating_efficiency_hspf)
    end
    if heating_capacity_retention_fraction.nil?
      assert_nil(heat_pump.heating_capacity_retention_fraction)
    else
      assert_in_delta(heating_capacity_retention_fraction, heat_pump.heating_capacity_retention_fraction, 0.01)
    end
    if heating_capacity_retention_temp.nil?
      assert_nil(heat_pump.heating_capacity_retention_temp)
    else
      assert_equal(heating_capacity_retention_temp, heat_pump.heating_capacity_retention_temp)
    end
  end

  def _test_default_pthp_values(heat_pump, shr, cooling_capacity, heating_capacity, heating_capacity_17F,
                                heating_capacity_retention_fraction, heating_capacity_retention_temp,
                                crankcase_heater_watts)
    assert_equal(shr, heat_pump.cooling_shr)
    assert_equal(crankcase_heater_watts, heat_pump.crankcase_heater_watts)
    if cooling_capacity.nil?
      assert(heat_pump.cooling_capacity > 0)
    else
      assert_equal(cooling_capacity, heat_pump.cooling_capacity)
    end
    if heating_capacity.nil?
      assert(heat_pump.heating_capacity > 0)
    else
      assert_equal(heating_capacity, heat_pump.heating_capacity)
    end
    if heating_capacity_17F.nil?
      assert_nil(heat_pump.heating_capacity_17F)
    else
      assert_equal(heating_capacity_17F, heat_pump.heating_capacity_17F)
    end
    if heating_capacity_retention_fraction.nil?
      assert_nil(heat_pump.heating_capacity_retention_fraction)
    else
      assert_in_delta(heating_capacity_retention_fraction, heat_pump.heating_capacity_retention_fraction, 0.01)
    end
    if heating_capacity_retention_temp.nil?
      assert_nil(heat_pump.heating_capacity_retention_temp)
    else
      assert_equal(heating_capacity_retention_temp, heat_pump.heating_capacity_retention_temp)
    end
  end

  def _test_default_mini_split_heat_pump_values(heat_pump, shr, fan_watts_per_cfm, charge_defect_ratio,
                                                airflow_defect_ratio, cooling_capacity, heating_capacity,
                                                heating_capacity_17F, backup_heating_capacity,
                                                cooling_efficiency_seer, heating_efficiency_hspf,
                                                heating_capacity_retention_fraction, heating_capacity_retention_temp,
                                                crankcase_heater_watts)
    assert_equal(shr, heat_pump.cooling_shr)
    assert_equal(fan_watts_per_cfm, heat_pump.fan_watts_per_cfm)
    assert_equal(charge_defect_ratio, heat_pump.charge_defect_ratio)
    assert_equal(airflow_defect_ratio, heat_pump.airflow_defect_ratio)
    assert_equal(crankcase_heater_watts, heat_pump.crankcase_heater_watts)
    if cooling_capacity.nil?
      assert(heat_pump.cooling_capacity > 0)
    else
      assert_equal(cooling_capacity, heat_pump.cooling_capacity)
    end
    if heating_capacity.nil?
      assert(heat_pump.heating_capacity > 0)
    else
      assert_equal(heating_capacity, heat_pump.heating_capacity)
    end
    if heating_capacity_17F.nil?
      assert_nil(heat_pump.heating_capacity_17F)
    else
      assert_equal(heating_capacity_17F, heat_pump.heating_capacity_17F)
    end
    if backup_heating_capacity.nil?
      assert(heat_pump.backup_heating_capacity > 0)
    else
      assert_equal(backup_heating_capacity, heat_pump.backup_heating_capacity)
    end
    if cooling_efficiency_seer.nil?
      assert_nil(heat_pump.cooling_efficiency_seer)
    else
      assert_equal(cooling_efficiency_seer, heat_pump.cooling_efficiency_seer)
    end
    if heating_efficiency_hspf.nil?
      assert_nil(heat_pump.heating_efficiency_hspf)
    else
      assert_equal(heating_efficiency_hspf, heat_pump.heating_efficiency_hspf)
    end
    assert_equal(HPXML::HVACCompressorTypeVariableSpeed, heat_pump.compressor_type)
    if heating_capacity_retention_fraction.nil?
      assert_nil(heat_pump.heating_capacity_retention_fraction)
    else
      assert_in_delta(heating_capacity_retention_fraction, heat_pump.heating_capacity_retention_fraction, 0.01)
    end
    if heating_capacity_retention_temp.nil?
      assert_nil(heat_pump.heating_capacity_retention_temp)
    else
      assert_equal(heating_capacity_retention_temp, heat_pump.heating_capacity_retention_temp)
    end
  end

  def _test_default_heat_pump_temperature_values(heat_pump, compressor_lockout_temp, backup_heating_lockout_temp,
                                                 backup_heating_switchover_temp)
    if compressor_lockout_temp.nil?
      assert_nil(heat_pump.compressor_lockout_temp)
    else
      assert_equal(compressor_lockout_temp, heat_pump.compressor_lockout_temp)
    end
    if backup_heating_lockout_temp.nil?
      assert_nil(heat_pump.backup_heating_lockout_temp)
    else
      assert_equal(backup_heating_lockout_temp, heat_pump.backup_heating_lockout_temp)
    end
    if backup_heating_switchover_temp.nil?
      assert_nil(heat_pump.backup_heating_switchover_temp)
    else
      assert_equal(backup_heating_switchover_temp, heat_pump.backup_heating_switchover_temp)
    end
  end

  def _test_default_ground_to_air_heat_pump_values(heat_pump, pump_watts_per_ton, fan_watts_per_cfm,
                                                   airflow_defect_ratio, cooling_capacity, heating_capacity,
                                                   backup_heating_capacity)
    assert_equal(pump_watts_per_ton, heat_pump.pump_watts_per_ton)
    assert_equal(fan_watts_per_cfm, heat_pump.fan_watts_per_cfm)
    assert_equal(airflow_defect_ratio, heat_pump.airflow_defect_ratio)
    if cooling_capacity.nil?
      assert(heat_pump.cooling_capacity > 0)
    else
      assert_equal(cooling_capacity, heat_pump.cooling_capacity)
    end
    if heating_capacity.nil?
      assert(heat_pump.heating_capacity > 0)
    else
      assert_equal(heating_capacity, heat_pump.heating_capacity)
    end
    if backup_heating_capacity.nil?
      assert(heat_pump.backup_heating_capacity > 0)
    else
      assert_equal(backup_heating_capacity, heat_pump.backup_heating_capacity)
    end
  end

  def _test_default_hvac_location_values(hvac_system, location)
    assert_equal(location, hvac_system.location)
  end

  def _test_default_hvac_control_setpoint_values(hvac_control, heating_setpoint_temp, cooling_setpoint_temp)
    assert_equal(heating_setpoint_temp, hvac_control.heating_setpoint_temp)
    assert_equal(cooling_setpoint_temp, hvac_control.cooling_setpoint_temp)
  end

  def _test_default_hvac_control_setback_values(hvac_control, htg_setback_start_hr, clg_setup_start_hr)
    assert_equal(htg_setback_start_hr, hvac_control.heating_setback_start_hour)
    assert_equal(clg_setup_start_hr, hvac_control.cooling_setup_start_hour)
  end

  def _test_default_hvac_control_season_values(hvac_control, htg_season_begin_month, htg_season_begin_day, htg_season_end_month, htg_season_end_day, clg_season_begin_month, clg_season_begin_day, clg_season_end_month, clg_season_end_day)
    assert_equal(htg_season_begin_month, hvac_control.seasons_heating_begin_month)
    assert_equal(htg_season_begin_day, hvac_control.seasons_heating_begin_day)
    assert_equal(htg_season_end_month, hvac_control.seasons_heating_end_month)
    assert_equal(htg_season_end_day, hvac_control.seasons_heating_end_day)
    assert_equal(clg_season_begin_month, hvac_control.seasons_cooling_begin_month)
    assert_equal(clg_season_begin_day, hvac_control.seasons_cooling_begin_day)
    assert_equal(clg_season_end_month, hvac_control.seasons_cooling_end_month)
    assert_equal(clg_season_end_day, hvac_control.seasons_cooling_end_day)
  end

  def _test_default_duct_values(hpxml, supply_locations, return_locations, supply_areas, return_areas,
                                supply_fracs, return_fracs, n_return_registers, supply_area_mults, return_area_mults,
                                supply_buried_levels, return_buried_levels, supply_effective_rvalues, return_effective_rvalues)
    supply_duct_idx = 0
    return_duct_idx = 0
    hpxml.hvac_distributions.each do |hvac_distribution|
      next unless [HPXML::HVACDistributionTypeAir].include? hvac_distribution.distribution_system_type

      assert_equal(n_return_registers, hvac_distribution.number_of_return_registers)
      hvac_distribution.ducts.each do |duct|
        if duct.duct_type == HPXML::DuctTypeSupply
          assert_equal(supply_locations[supply_duct_idx], duct.duct_location)
          assert_in_epsilon(supply_areas[supply_duct_idx], duct.duct_surface_area, 0.01)
          assert_in_epsilon(supply_fracs[supply_duct_idx], duct.duct_fraction_area, 0.01)
          assert_in_epsilon(supply_area_mults[supply_duct_idx], duct.duct_surface_area_multiplier, 0.01)
          assert_equal(supply_buried_levels[supply_duct_idx], duct.duct_buried_insulation_level)
          assert_in_epsilon(supply_effective_rvalues[supply_duct_idx], duct.duct_effective_r_value, 0.01)
          supply_duct_idx += 1
        elsif duct.duct_type == HPXML::DuctTypeReturn
          assert_equal(return_locations[return_duct_idx], duct.duct_location)
          assert_in_epsilon(return_areas[return_duct_idx], duct.duct_surface_area, 0.01)
          assert_in_epsilon(return_fracs[return_duct_idx], duct.duct_fraction_area, 0.01)
          assert_in_epsilon(return_area_mults[return_duct_idx], duct.duct_surface_area_multiplier, 0.01)
          assert_equal(return_buried_levels[return_duct_idx], duct.duct_buried_insulation_level)
          assert_in_epsilon(return_effective_rvalues[return_duct_idx], duct.duct_effective_r_value, 0.01)
          return_duct_idx += 1
        end
      end
    end
  end

  def _test_default_mech_vent_values(hpxml, is_shared_system, hours_in_operation, fan_power, flow_rate,
                                     cfis_vent_mode_airflow_fraction = nil, cfis_addtl_runtime_operating_mode = nil)
    vent_fan = hpxml.ventilation_fans.find { |f| f.used_for_whole_building_ventilation && !f.is_cfis_supplemental_fan? }

    assert_equal(is_shared_system, vent_fan.is_shared_system)
    assert_equal(hours_in_operation, vent_fan.hours_in_operation)
    assert_in_delta(fan_power, vent_fan.fan_power, 0.1)
    assert_in_delta(flow_rate, vent_fan.rated_flow_rate.to_f + vent_fan.calculated_flow_rate.to_f + vent_fan.tested_flow_rate.to_f + vent_fan.delivered_ventilation.to_f, 0.1)
    if cfis_vent_mode_airflow_fraction.nil?
      assert_nil(vent_fan.cfis_vent_mode_airflow_fraction)
    else
      assert_equal(cfis_vent_mode_airflow_fraction, vent_fan.cfis_vent_mode_airflow_fraction)
    end
    if cfis_addtl_runtime_operating_mode.nil?
      assert_nil(vent_fan.cfis_addtl_runtime_operating_mode)
    else
      assert_equal(cfis_addtl_runtime_operating_mode, vent_fan.cfis_addtl_runtime_operating_mode)
    end
  end

  def _test_default_mech_vent_suppl_values(hpxml, is_shared_system, hours_in_operation, fan_power, flow_rate)
    vent_fan = hpxml.ventilation_fans.find { |f| f.used_for_whole_building_ventilation && f.is_cfis_supplemental_fan? }

    assert_equal(is_shared_system, vent_fan.is_shared_system)
    if hours_in_operation.nil?
      assert_nil(hours_in_operation, vent_fan.hours_in_operation)
    else
      assert_equal(hours_in_operation, vent_fan.hours_in_operation)
    end
    assert_in_epsilon(fan_power, vent_fan.fan_power, 0.01)
    assert_in_epsilon(flow_rate, vent_fan.rated_flow_rate.to_f + vent_fan.calculated_flow_rate.to_f + vent_fan.tested_flow_rate.to_f + vent_fan.delivered_ventilation.to_f, 0.01)
  end

  def _test_default_kitchen_fan_values(hpxml, count, flow_rate, hours_in_operation, fan_power, start_hour)
    kitchen_fan = hpxml.ventilation_fans.find { |f| f.used_for_local_ventilation && f.fan_location == HPXML::LocationKitchen }

    assert_equal(count, kitchen_fan.count)
    assert_equal(flow_rate, kitchen_fan.rated_flow_rate.to_f + kitchen_fan.calculated_flow_rate.to_f + kitchen_fan.tested_flow_rate.to_f + kitchen_fan.delivered_ventilation.to_f)
    assert_equal(hours_in_operation, kitchen_fan.hours_in_operation)
    assert_equal(fan_power, kitchen_fan.fan_power)
    assert_equal(start_hour, kitchen_fan.start_hour)
  end

  def _test_default_bath_fan_values(hpxml, count, flow_rate, hours_in_operation, fan_power, start_hour)
    bath_fan = hpxml.ventilation_fans.find { |f| f.used_for_local_ventilation && f.fan_location == HPXML::LocationBath }

    assert_equal(count, bath_fan.count)
    assert_equal(flow_rate, bath_fan.rated_flow_rate.to_f + bath_fan.calculated_flow_rate.to_f + bath_fan.tested_flow_rate.to_f + bath_fan.delivered_ventilation.to_f)
    assert_equal(hours_in_operation, bath_fan.hours_in_operation)
    assert_equal(fan_power, bath_fan.fan_power)
    assert_equal(start_hour, bath_fan.start_hour)
  end

  def _test_default_whole_house_fan_values(hpxml, flow_rate, fan_power)
    whf = hpxml.ventilation_fans.find { |f| f.used_for_seasonal_cooling_load_reduction }

    assert_equal(flow_rate, whf.rated_flow_rate.to_f + whf.calculated_flow_rate.to_f + whf.tested_flow_rate.to_f + whf.delivered_ventilation.to_f)
    assert_equal(fan_power, whf.fan_power)
  end

  def _test_default_storage_water_heater_values(hpxml, *expected_wh_values)
    storage_water_heaters = hpxml.water_heating_systems.select { |w| w.water_heater_type == HPXML::WaterHeaterTypeStorage }
    assert_equal(expected_wh_values.size, storage_water_heaters.size)
    storage_water_heaters.each_with_index do |wh_system, idx|
      is_shared, heating_capacity, tank_volume, recovery_efficiency, location, temperature, energy_factor, tank_model_type = expected_wh_values[idx]

      assert_equal(is_shared, wh_system.is_shared_system)
      assert_in_epsilon(heating_capacity, wh_system.heating_capacity, 0.01)
      assert_equal(tank_volume, wh_system.tank_volume)
      assert_in_epsilon(recovery_efficiency, wh_system.recovery_efficiency, 0.01)
      assert_equal(location, wh_system.location)
      assert_equal(temperature, wh_system.temperature)
      if energy_factor.nil?
        assert_nil(wh_system.energy_factor)
      else
        assert_equal(energy_factor, wh_system.energy_factor)
      end
      assert_equal(tank_model_type, wh_system.tank_model_type)
    end
  end

  def _test_default_tankless_water_heater_values(hpxml, *expected_wh_values)
    tankless_water_heaters = hpxml.water_heating_systems.select { |w| w.water_heater_type == HPXML::WaterHeaterTypeTankless }
    assert_equal(expected_wh_values.size, tankless_water_heaters.size)
    tankless_water_heaters.each_with_index do |wh_system, idx|
      performance_adjustment, = expected_wh_values[idx]

      assert_equal(performance_adjustment, wh_system.performance_adjustment)
    end
  end

  def _test_default_heat_pump_water_heater_values(hpxml, *expected_wh_values)
    heat_pump_water_heaters = hpxml.water_heating_systems.select { |w| w.water_heater_type == HPXML::WaterHeaterTypeHeatPump }
    assert_equal(expected_wh_values.size, heat_pump_water_heaters.size)
    heat_pump_water_heaters.each_with_index do |wh_system, idx|
      operating_mode, = expected_wh_values[idx]

      assert_equal(operating_mode, wh_system.operating_mode)
    end
  end

  def _test_default_indirect_water_heater_values(hpxml, *expected_wh_values)
    indirect_water_heaters = hpxml.water_heating_systems.select { |w| w.water_heater_type == HPXML::WaterHeaterTypeCombiStorage }
    assert_equal(expected_wh_values.size, indirect_water_heaters.size)
    indirect_water_heaters.each_with_index do |wh_system, idx|
      standby_loss_units, standby_loss_value, = expected_wh_values[idx]

      assert_equal(standby_loss_units, wh_system.standby_loss_units)
      assert_equal(standby_loss_value, wh_system.standby_loss_value)
    end
  end

  def _test_default_standard_distribution_values(hot_water_distribution, piping_length, pipe_r_value)
    assert_in_epsilon(piping_length, hot_water_distribution.standard_piping_length, 0.01)
    assert_equal(pipe_r_value, hot_water_distribution.pipe_r_value)
  end

  def _test_default_recirc_distribution_values(hot_water_distribution, piping_length, branch_piping_length, pump_power, pipe_r_value)
    assert_in_epsilon(piping_length, hot_water_distribution.recirculation_piping_length, 0.01)
    assert_in_epsilon(branch_piping_length, hot_water_distribution.recirculation_branch_piping_length, 0.01)
    assert_in_epsilon(pump_power, hot_water_distribution.recirculation_pump_power, 0.01)
    assert_equal(pipe_r_value, hot_water_distribution.pipe_r_value)
  end

  def _test_default_shared_recirc_distribution_values(hot_water_distribution, pump_power)
    assert_in_epsilon(pump_power, hot_water_distribution.shared_recirculation_pump_power, 0.01)
  end

  def _test_default_water_fixture_values(hpxml, usage_multiplier, weekday_sch, weekend_sch, monthly_mults)
    assert_equal(usage_multiplier, hpxml.water_heating.water_fixtures_usage_multiplier)
    if weekday_sch.nil?
      assert_nil(hpxml.water_heating.water_fixtures_weekday_fractions)
    else
      assert_equal(weekday_sch, hpxml.water_heating.water_fixtures_weekday_fractions)
    end
    if weekend_sch.nil?
      assert_nil(hpxml.water_heating.water_fixtures_weekend_fractions)
    else
      assert_equal(weekend_sch, hpxml.water_heating.water_fixtures_weekend_fractions)
    end
    if monthly_mults.nil?
      assert_nil(hpxml.water_heating.water_fixtures_monthly_multipliers)
    else
      assert_equal(monthly_mults, hpxml.water_heating.water_fixtures_monthly_multipliers)
    end
  end

  def _test_default_solar_thermal_values(solar_thermal_system, storage_volume, azimuth)
    assert_equal(storage_volume, solar_thermal_system.storage_volume)
    assert_equal(azimuth, solar_thermal_system.collector_azimuth)
  end

  def _test_default_pv_system_values(hpxml, interver_efficiency, system_loss_frac, is_shared_system, location, tracking, module_type, azimuth)
    hpxml.pv_systems.each do |pv|
      assert_equal(is_shared_system, pv.is_shared_system)
      assert_in_epsilon(system_loss_frac, pv.system_losses_fraction, 0.01)
      assert_equal(location, pv.location)
      assert_equal(tracking, pv.tracking)
      assert_equal(module_type, pv.module_type)
      assert_equal(azimuth, pv.array_azimuth)
    end
    hpxml.inverters.each do |inv|
      assert_equal(interver_efficiency, inv.inverter_efficiency)
    end
  end

  def _test_default_battery_values(battery, nominal_capacity_kwh, nominal_capacity_ah, usable_capacity_kwh, usable_capacity_ah,
                                   rated_power_output, location, lifetime_model, round_trip_efficiency)
    if nominal_capacity_kwh.nil?
      assert_nil(battery.nominal_capacity_kwh)
    else
      assert_equal(nominal_capacity_kwh, battery.nominal_capacity_kwh)
    end
    if nominal_capacity_ah.nil?
      assert_nil(battery.nominal_capacity_ah)
    else
      assert_equal(nominal_capacity_ah, battery.nominal_capacity_ah)
    end
    if usable_capacity_kwh.nil?
      assert_nil(battery.usable_capacity_kwh)
    else
      assert_equal(usable_capacity_kwh, battery.usable_capacity_kwh)
    end
    if usable_capacity_ah.nil?
      assert_nil(battery.usable_capacity_ah)
    else
      assert_equal(usable_capacity_ah, battery.usable_capacity_ah)
    end
    assert_equal(rated_power_output, battery.rated_power_output)
    assert_equal(location, battery.location)
    if lifetime_model.nil?
      assert_nil(battery.lifetime_model)
    else
      assert_equal(lifetime_model, battery.lifetime_model)
    end
    assert_equal(round_trip_efficiency, battery.round_trip_efficiency)
  end

  def _test_default_generator_values(hpxml, is_shared_system)
    hpxml.generators.each do |generator|
      assert_equal(is_shared_system, generator.is_shared_system)
    end
  end

  def _test_default_clothes_washer_values(clothes_washer, is_shared, location, imef, rated_annual_kwh, label_electric_rate,
                                          label_gas_rate, label_annual_gas_cost, capacity, label_usage, usage_multiplier,
                                          weekday_sch, weekend_sch, monthly_mults)
    assert_equal(is_shared, clothes_washer.is_shared_appliance)
    assert_equal(location, clothes_washer.location)
    assert_equal(imef, clothes_washer.integrated_modified_energy_factor)
    assert_equal(rated_annual_kwh, clothes_washer.rated_annual_kwh)
    assert_equal(label_electric_rate, clothes_washer.label_electric_rate)
    assert_equal(label_gas_rate, clothes_washer.label_gas_rate)
    assert_equal(label_annual_gas_cost, clothes_washer.label_annual_gas_cost)
    assert_equal(capacity, clothes_washer.capacity)
    assert_equal(label_usage, clothes_washer.label_usage)
    assert_equal(usage_multiplier, clothes_washer.usage_multiplier)
    if weekday_sch.nil?
      assert_nil(clothes_washer.weekday_fractions)
    else
      assert_equal(weekday_sch, clothes_washer.weekday_fractions)
    end
    if weekend_sch.nil?
      assert_nil(clothes_washer.weekend_fractions)
    else
      assert_equal(weekend_sch, clothes_washer.weekend_fractions)
    end
    if monthly_mults.nil?
      assert_nil(clothes_washer.monthly_multipliers)
    else
      assert_equal(monthly_mults, clothes_washer.monthly_multipliers)
    end
  end

  def _test_default_clothes_dryer_values(clothes_dryer, is_shared, location, cef, usage_multiplier,
                                         weekday_sch, weekend_sch, monthly_mults)
    assert_equal(is_shared, clothes_dryer.is_shared_appliance)
    assert_equal(location, clothes_dryer.location)
    assert_equal(cef, clothes_dryer.combined_energy_factor)
    assert_equal(usage_multiplier, clothes_dryer.usage_multiplier)
    if weekday_sch.nil?
      assert_nil(clothes_dryer.weekday_fractions)
    else
      assert_equal(weekday_sch, clothes_dryer.weekday_fractions)
    end
    if weekend_sch.nil?
      assert_nil(clothes_dryer.weekend_fractions)
    else
      assert_equal(weekend_sch, clothes_dryer.weekend_fractions)
    end
    if monthly_mults.nil?
      assert_nil(clothes_dryer.monthly_multipliers)
    else
      assert_equal(monthly_mults, clothes_dryer.monthly_multipliers)
    end
  end

  def _test_default_clothes_dryer_exhaust_values(clothes_dryer, is_vented, vented_flow_rate)
    assert_equal(is_vented, clothes_dryer.is_vented)
    if vented_flow_rate.nil?
      assert_nil(clothes_dryer.vented_flow_rate)
    else
      assert_equal(vented_flow_rate, clothes_dryer.vented_flow_rate)
    end
  end

  def _test_default_dishwasher_values(dishwasher, is_shared, location, rated_annual_kwh, label_electric_rate, label_gas_rate, label_annual_gas_cost, label_usage, place_setting_capacity, usage_multiplier, weekday_sch, weekend_sch, monthly_mults)
    assert_equal(is_shared, dishwasher.is_shared_appliance)
    assert_equal(location, dishwasher.location)
    assert_equal(rated_annual_kwh, dishwasher.rated_annual_kwh)
    assert_equal(label_electric_rate, dishwasher.label_electric_rate)
    assert_equal(label_gas_rate, dishwasher.label_gas_rate)
    assert_equal(label_annual_gas_cost, dishwasher.label_annual_gas_cost)
    assert_equal(label_usage, dishwasher.label_usage)
    assert_equal(place_setting_capacity, dishwasher.place_setting_capacity)
    assert_equal(usage_multiplier, dishwasher.usage_multiplier)
    if weekday_sch.nil?
      assert_nil(dishwasher.weekday_fractions)
    else
      assert_equal(weekday_sch, dishwasher.weekday_fractions)
    end
    if weekend_sch.nil?
      assert_nil(dishwasher.weekend_fractions)
    else
      assert_equal(weekend_sch, dishwasher.weekend_fractions)
    end
    if monthly_mults.nil?
      assert_nil(dishwasher.monthly_multipliers)
    else
      assert_equal(monthly_mults, dishwasher.monthly_multipliers)
    end
  end

  def _test_default_refrigerator_values(hpxml, location, rated_annual_kwh, usage_multiplier, weekday_sch, weekend_sch, monthly_mults)
    hpxml.refrigerators.each do |refrigerator|
      next unless refrigerator.primary_indicator

      assert_equal(location, refrigerator.location)
      assert_equal(rated_annual_kwh, refrigerator.rated_annual_kwh)
      assert_equal(usage_multiplier, refrigerator.usage_multiplier)
      if weekday_sch.nil?
        assert_nil(refrigerator.weekday_fractions)
      else
        assert_equal(weekday_sch, refrigerator.weekday_fractions)
      end
      if weekend_sch.nil?
        assert_nil(refrigerator.weekend_fractions)
      else
        assert_equal(weekend_sch, refrigerator.weekend_fractions)
      end
      if monthly_mults.nil?
        assert_nil(refrigerator.monthly_multipliers)
      else
        assert_equal(monthly_mults, refrigerator.monthly_multipliers)
      end
    end
  end

  def _test_default_extra_refrigerators_values(hpxml, location, rated_annual_kwh, usage_multiplier, weekday_sch, weekend_sch, monthly_mults)
    hpxml.refrigerators.each do |refrigerator|
      next if refrigerator.primary_indicator

      assert_equal(location, refrigerator.location)
      assert_in_epsilon(rated_annual_kwh, refrigerator.rated_annual_kwh, 0.01)
      assert_equal(usage_multiplier, refrigerator.usage_multiplier)
      if weekday_sch.nil?
        assert_nil(refrigerator.weekday_fractions)
      else
        assert_equal(weekday_sch, refrigerator.weekday_fractions)
      end
      if weekend_sch.nil?
        assert_nil(refrigerator.weekend_fractions)
      else
        assert_equal(weekend_sch, refrigerator.weekend_fractions)
      end
      if monthly_mults.nil?
        assert_nil(refrigerator.monthly_multipliers)
      else
        assert_equal(monthly_mults, refrigerator.monthly_multipliers)
      end
    end
  end

  def _test_default_freezers_values(hpxml, location, rated_annual_kwh, usage_multiplier, weekday_sch, weekend_sch, monthly_mults)
    hpxml.freezers.each do |freezer|
      assert_equal(location, freezer.location)
      assert_in_epsilon(rated_annual_kwh, freezer.rated_annual_kwh, 0.01)
      assert_equal(usage_multiplier, freezer.usage_multiplier)
      if weekday_sch.nil?
        assert_nil(freezer.weekday_fractions)
      else
        assert_equal(weekday_sch, freezer.weekday_fractions)
      end
      if weekend_sch.nil?
        assert_nil(freezer.weekend_fractions)
      else
        assert_equal(weekend_sch, freezer.weekend_fractions)
      end
      if monthly_mults.nil?
        assert_nil(freezer.monthly_multipliers)
      else
        assert_equal(monthly_mults, freezer.monthly_multipliers)
      end
    end
  end

  def _test_default_cooking_range_values(cooking_range, location, is_induction, usage_multiplier, weekday_sch, weekend_sch, monthly_mults)
    assert_equal(location, cooking_range.location)
    assert_equal(is_induction, cooking_range.is_induction)
    assert_equal(usage_multiplier, cooking_range.usage_multiplier)
    if weekday_sch.nil?
      assert_nil(cooking_range.weekday_fractions)
    else
      assert_equal(weekday_sch, cooking_range.weekday_fractions)
    end
    if weekend_sch.nil?
      assert_nil(cooking_range.weekend_fractions)
    else
      assert_equal(weekend_sch, cooking_range.weekend_fractions)
    end
    if monthly_mults.nil?
      assert_nil(cooking_range.monthly_multipliers)
    else
      assert_equal(monthly_mults, cooking_range.monthly_multipliers)
    end
  end

  def _test_default_oven_values(oven, is_convection)
    assert_equal(is_convection, oven.is_convection)
  end

  def _test_default_lighting_values(hpxml, interior_usage_multiplier, garage_usage_multiplier, exterior_usage_multiplier, schedules = {})
    assert_equal(interior_usage_multiplier, hpxml.lighting.interior_usage_multiplier)
    assert_equal(garage_usage_multiplier, hpxml.lighting.garage_usage_multiplier)
    assert_equal(exterior_usage_multiplier, hpxml.lighting.exterior_usage_multiplier)
    if not schedules[:grg_wk_sch].nil?
      assert_equal(schedules[:grg_wk_sch], hpxml.lighting.garage_weekday_fractions)
    else
      assert_nil(hpxml.lighting.garage_weekday_fractions)
    end
    if not schedules[:grg_wknd_sch].nil?
      assert_equal(schedules[:grg_wknd_sch], hpxml.lighting.garage_weekend_fractions)
    else
      assert_nil(hpxml.lighting.garage_weekend_fractions)
    end
    if not schedules[:grg_month_mult].nil?
      assert_equal(schedules[:grg_month_mult], hpxml.lighting.garage_monthly_multipliers)
    else
      assert_nil(hpxml.lighting.garage_monthly_multipliers)
    end
    if not schedules[:ext_wk_sch].nil?
      assert_equal(schedules[:ext_wk_sch], hpxml.lighting.exterior_weekday_fractions)
    else
      assert_nil(hpxml.lighting.exterior_weekday_fractions)
    end
    if not schedules[:ext_wknd_sch].nil?
      assert_equal(schedules[:ext_wknd_sch], hpxml.lighting.exterior_weekend_fractions)
    else
      assert_nil(hpxml.lighting.exterior_weekday_fractions)
    end
    if not schedules[:ext_month_mult].nil?
      assert_equal(schedules[:ext_month_mult], hpxml.lighting.exterior_monthly_multipliers)
    else
      assert_nil(hpxml.lighting.exterior_monthly_multipliers)
    end
    if not schedules[:hol_kwh_per_day].nil?
      assert_equal(schedules[:hol_kwh_per_day], hpxml.lighting.holiday_kwh_per_day)
    else
      assert_nil(hpxml.lighting.holiday_kwh_per_day)
    end
    if not schedules[:hol_begin_month].nil?
      assert_equal(schedules[:hol_begin_month], hpxml.lighting.holiday_period_begin_month)
    else
      assert_nil(hpxml.lighting.holiday_period_begin_month)
    end
    if not schedules[:hol_begin_day].nil?
      assert_equal(schedules[:hol_begin_day], hpxml.lighting.holiday_period_begin_day)
    else
      assert_nil(hpxml.lighting.holiday_period_begin_day)
    end
    if not schedules[:hol_end_month].nil?
      assert_equal(schedules[:hol_end_month], hpxml.lighting.holiday_period_end_month)
    else
      assert_nil(hpxml.lighting.holiday_period_end_month)
    end
    if not schedules[:hol_end_day].nil?
      assert_equal(schedules[:hol_end_day], hpxml.lighting.holiday_period_end_day)
    else
      assert_nil(hpxml.lighting.holiday_period_end_day)
    end
    if not schedules[:hol_wk_sch].nil?
      assert_equal(schedules[:hol_wk_sch], hpxml.lighting.holiday_weekday_fractions)
    else
      assert_nil(hpxml.lighting.holiday_weekday_fractions)
    end
    if not schedules[:hol_wknd_sch].nil?
      assert_equal(schedules[:hol_wknd_sch], hpxml.lighting.holiday_weekend_fractions)
    else
      assert_nil(hpxml.lighting.holiday_weekend_fractions)
    end
  end

  def _test_default_ceiling_fan_values(ceiling_fan, count, efficiency, weekday_sch, weekend_sch, monthly_mults)
    assert_equal(count, ceiling_fan.count)
    assert_in_epsilon(efficiency, ceiling_fan.efficiency, 0.01)
    if weekday_sch.nil?
      assert_nil(ceiling_fan.weekday_fractions)
    else
      assert_equal(weekday_sch, ceiling_fan.weekday_fractions)
    end
    if weekend_sch.nil?
      assert_nil(ceiling_fan.weekend_fractions)
    else
      assert_equal(weekend_sch, ceiling_fan.weekend_fractions)
    end
    if monthly_mults.nil?
      assert_nil(ceiling_fan.monthly_multipliers)
    else
      assert_equal(monthly_mults, ceiling_fan.monthly_multipliers)
    end
  end

  def _test_default_pool_heater_values(pool, load_units, load_value, usage_multiplier, weekday_sch, weekend_sch, monthly_mults)
    if load_units.nil?
      assert_nil(pool.heater_load_units)
    else
      assert_equal(load_units, pool.heater_load_units)
    end
    if load_value.nil?
      assert_nil(pool.heater_load_value)
    else
      assert_in_epsilon(load_value, pool.heater_load_value, 0.01)
    end
    if usage_multiplier.nil?
      assert_nil(pool.heater_usage_multiplier)
    else
      assert_equal(usage_multiplier, pool.heater_usage_multiplier)
    end
    if weekday_sch.nil?
      assert_nil(pool.heater_weekday_fractions)
    else
      assert_equal(weekday_sch, pool.heater_weekday_fractions)
    end
    if weekend_sch.nil?
      assert_nil(pool.heater_weekend_fractions)
    else
      assert_equal(weekend_sch, pool.heater_weekend_fractions)
    end
    if monthly_mults.nil?
      assert_nil(pool.heater_monthly_multipliers)
    else
      assert_equal(monthly_mults, pool.heater_monthly_multipliers)
    end
  end

  def _test_default_pool_pump_values(pool, kwh_per_year, usage_multiplier, weekday_sch, weekend_sch, monthly_mults)
    assert_in_epsilon(kwh_per_year, pool.pump_kwh_per_year, 0.01)
    assert_equal(usage_multiplier, pool.pump_usage_multiplier)
    assert_equal(weekday_sch, pool.pump_weekday_fractions)
    assert_equal(weekend_sch, pool.pump_weekend_fractions)
    assert_equal(monthly_mults, pool.pump_monthly_multipliers)
  end

  def _test_default_hot_tub_heater_values(hot_tub, load_units, load_value, usage_multiplier, weekday_sch, weekend_sch, monthly_mults)
    if load_units.nil?
      assert_nil(hot_tub.heater_load_units)
    else
      assert_equal(load_units, hot_tub.heater_load_units)
    end
    if load_value.nil?
      assert_nil(hot_tub.heater_load_value)
    else
      assert_in_epsilon(load_value, hot_tub.heater_load_value, 0.01)
    end
    if usage_multiplier.nil?
      assert_nil(hot_tub.heater_usage_multiplier)
    else
      assert_equal(usage_multiplier, hot_tub.heater_usage_multiplier)
    end
    if weekday_sch.nil?
      assert_nil(hot_tub.heater_weekday_fractions)
    else
      assert_equal(weekday_sch, hot_tub.heater_weekday_fractions)
    end
    if weekend_sch.nil?
      assert_nil(hot_tub.heater_weekend_fractions)
    else
      assert_equal(weekend_sch, hot_tub.heater_weekend_fractions)
    end
    if monthly_mults.nil?
      assert_nil(hot_tub.heater_monthly_multipliers)
    else
      assert_equal(monthly_mults, hot_tub.heater_monthly_multipliers)
    end
  end

  def _test_default_hot_tub_pump_values(hot_tub, kwh_per_year, usage_multiplier, weekday_sch, weekend_sch, monthly_mults)
    assert_in_epsilon(kwh_per_year, hot_tub.pump_kwh_per_year, 0.01)
    assert_equal(usage_multiplier, hot_tub.pump_usage_multiplier)
    assert_equal(weekday_sch, hot_tub.pump_weekday_fractions)
    assert_equal(weekend_sch, hot_tub.pump_weekend_fractions)
    assert_equal(monthly_mults, hot_tub.pump_monthly_multipliers)
  end

  def _test_default_plug_load_values(hpxml, load_type, kwh_per_year, frac_sensible, frac_latent, usage_multiplier, weekday_sch, weekend_sch, monthly_mults)
    pl = hpxml.plug_loads.find { |pl| pl.plug_load_type == load_type }

    assert_in_epsilon(kwh_per_year, pl.kwh_per_year, 0.01)
    assert_equal(usage_multiplier, pl.usage_multiplier)
    assert_in_epsilon(frac_sensible, pl.frac_sensible, 0.01)
    assert_in_epsilon(frac_latent, pl.frac_latent, 0.01)
    assert_equal(weekday_sch, pl.weekday_fractions)
    assert_equal(weekend_sch, pl.weekend_fractions)
    assert_equal(monthly_mults, pl.monthly_multipliers)
  end

  def _test_default_fuel_load_values(hpxml, load_type, therm_per_year, frac_sensible, frac_latent, usage_multiplier, weekday_sch, weekend_sch, monthly_mults)
    fl = hpxml.fuel_loads.find { |fl| fl.fuel_load_type == load_type }

    assert_in_epsilon(therm_per_year, fl.therm_per_year, 0.01)
    assert_equal(usage_multiplier, fl.usage_multiplier)
    assert_in_epsilon(frac_sensible, fl.frac_sensible, 0.01)
    assert_in_epsilon(frac_latent, fl.frac_latent, 0.01)
    assert_equal(weekday_sch, fl.weekday_fractions)
    assert_equal(weekend_sch, fl.weekend_fractions)
    assert_equal(monthly_mults, fl.monthly_multipliers)
  end

  def _create_hpxml(hpxml_name)
    return HPXML.new(hpxml_path: File.join(@sample_files_path, hpxml_name))
  end
end
