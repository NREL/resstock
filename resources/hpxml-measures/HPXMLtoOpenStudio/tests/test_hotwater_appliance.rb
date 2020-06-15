# frozen_string_literal: true

require_relative '../resources/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require 'fileutils'
require_relative '../measure.rb'
require_relative '../resources/util.rb'

class HPXMLtoOpenStudioHotWaterApplianceTest < MiniTest::Test
  def sample_files_dir
    return File.join(File.dirname(__FILE__), '..', '..', 'workflow', 'sample_files')
  end

  def get_ee_kwh_per_year(model, name)
    model.getElectricEquipments.each do |ee|
      next unless ee.name.to_s == name

      hrs = Schedule.annual_equivalent_full_load_hrs(model.yearDescription.get.assumedYear, ee.schedule.get)
      kwh_yr = UnitConversions.convert(hrs * ee.designLevel.get * ee.multiplier * ee.space.get.multiplier, 'Wh', 'kWh')
      return kwh_yr
    end
    return
  end

  def get_ee_fractions(model, name)
    model.getElectricEquipments.each do |ee|
      next unless ee.name.to_s == name

      sens_frac = 1.0 - ee.electricEquipmentDefinition.fractionLost - ee.electricEquipmentDefinition.fractionLatent
      lat_frac = ee.electricEquipmentDefinition.fractionLatent
      return sens_frac, lat_frac
    end
    return []
  end

  def get_oe_kwh_fuel(model, name)
    model.getOtherEquipments.each do |oe|
      next unless oe.name.to_s.include? name

      hrs = Schedule.annual_equivalent_full_load_hrs(model.yearDescription.get.assumedYear, oe.schedule.get)
      kwh_yr = UnitConversions.convert(hrs * oe.otherEquipmentDefinition.designLevel.get * oe.multiplier * oe.space.get.multiplier, 'Wh', 'kWh')
      return kwh_yr, oe.fuelType
    end
    return []
  end

  def get_oe_fractions(model, name)
    model.getOtherEquipments.each do |oe|
      next unless oe.name.to_s.include? name

      sens_frac = 1.0 - oe.otherEquipmentDefinition.fractionLost - oe.otherEquipmentDefinition.fractionLatent
      lat_frac = oe.otherEquipmentDefinition.fractionLatent
      return sens_frac, lat_frac
    end
    return []
  end

  def get_wu_gpd(model, name)
    model.getWaterUseEquipments.each do |wue|
      next unless wue.name.to_s == name

      full_load_hrs = Schedule.annual_equivalent_full_load_hrs(model.yearDescription.get.assumedYear, wue.flowRateFractionSchedule.get)
      gpd = UnitConversions.convert(full_load_hrs * wue.waterUseEquipmentDefinition.peakFlowRate * wue.multiplier, 'm^3/s', 'gal/min') * 60.0 / 365.0
      return gpd
    end
    return
  end

  def test_recirc_demand
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-dhw-recirc-demand.xml'))
    model, hpxml = _test_measure(args_hash)

    # Get HPXML values
    hot_water_distribution = hpxml.hot_water_distributions[0]
    pump_kwh_yr = 0.15 * hot_water_distribution.recirculation_pump_power
    assert_in_epsilon(pump_kwh_yr, get_ee_kwh_per_year(model, 'dhw recirc pump'), 0.001)
  end

  def test_recirc_manual
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-dhw-recirc-manual.xml'))
    model, hpxml = _test_measure(args_hash)

    # Get HPXML values
    hot_water_distribution = hpxml.hot_water_distributions[0]
    pump_kwh_yr = 0.10 * hot_water_distribution.recirculation_pump_power
    assert_in_epsilon(pump_kwh_yr, get_ee_kwh_per_year(model, 'dhw recirc pump'), 0.001)
  end

  def test_recirc_no_control
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-dhw-recirc-nocontrol.xml'))
    model, hpxml = _test_measure(args_hash)

    # Get HPXML values
    hot_water_distribution = hpxml.hot_water_distributions[0]
    pump_kwh_yr = 8.76 * hot_water_distribution.recirculation_pump_power
    assert_in_epsilon(pump_kwh_yr, get_ee_kwh_per_year(model, 'dhw recirc pump'), 0.001)
  end

  def test_recirc_timer
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-dhw-recirc-timer.xml'))
    model, hpxml = _test_measure(args_hash)

    # Get HPXML values
    hot_water_distribution = hpxml.hot_water_distributions[0]
    pump_kwh_yr = 8.76 * hot_water_distribution.recirculation_pump_power
    assert_in_epsilon(pump_kwh_yr, get_ee_kwh_per_year(model, 'dhw recirc pump'), 0.001)
  end

  def test_recirc_temp
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-dhw-recirc-temperature.xml'))
    model, hpxml = _test_measure(args_hash)

    # Get HPXML values
    hot_water_distribution = hpxml.hot_water_distributions[0]
    pump_kwh_yr = 1.46 * hot_water_distribution.recirculation_pump_power
    assert_in_epsilon(pump_kwh_yr, get_ee_kwh_per_year(model, 'dhw recirc pump'), 0.001)
  end

  def test_appliances_none
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-appliances-none.xml'))
    model, hpxml = _test_measure(args_hash)

    # water use equipment peak flows
    fixture_gpd = 44.60
    dist_peak_gpd = 10.2343
    assert_in_epsilon(fixture_gpd, get_wu_gpd(model, Constants.ObjectNameFixtures), 0.001)
    assert_in_epsilon(dist_peak_gpd, get_wu_gpd(model, Constants.ObjectNameDistributionWaste), 0.001)
    assert_nil(get_wu_gpd(model, Constants.ObjectNameClothesWasher))
    assert_nil(get_wu_gpd(model, Constants.ObjectNameDishwasher))

    # electric equipment
    assert_nil(get_ee_kwh_per_year(model, Constants.ObjectNameClothesWasher))
    assert_equal([], get_ee_fractions(model, Constants.ObjectNameClothesWasher))

    assert_nil(get_ee_kwh_per_year(model, Constants.ObjectNameDishwasher))
    assert_equal([], get_ee_fractions(model, Constants.ObjectNameDishwasher))

    assert_nil(get_ee_kwh_per_year(model, Constants.ObjectNameClothesDryer))
    assert_equal([], get_ee_fractions(model, Constants.ObjectNameClothesDryer))

    assert_nil(get_ee_kwh_per_year(model, Constants.ObjectNameRefrigerator))
    assert_equal([], get_ee_fractions(model, Constants.ObjectNameRefrigerator))

    assert_nil(get_ee_kwh_per_year(model, Constants.ObjectNameCookingRange))
    assert_equal([], get_ee_fractions(model, Constants.ObjectNameCookingRange))

    # other equipment
    water_sens = -262.507
    water_lat = 266.358
    assert_in_epsilon(water_sens, get_oe_kwh_fuel(model, Constants.ObjectNameWater + ' Sensible')[0], 0.001)
    assert_in_epsilon(1.0, get_oe_fractions(model, Constants.ObjectNameWater + ' Sensible')[0], 0.001)
    assert_in_epsilon(0.0, get_oe_fractions(model, Constants.ObjectNameWater + ' Sensible')[1], 0.001)

    assert_in_epsilon(water_lat, get_oe_kwh_fuel(model, Constants.ObjectNameWater + ' Latent')[0], 0.001)
    assert_in_epsilon(0.0, get_oe_fractions(model, Constants.ObjectNameWater + ' Latent')[0], 0.001)
    assert_in_epsilon(1.0, get_oe_fractions(model, Constants.ObjectNameWater + ' Latent')[1], 0.001)
  end

  def test_base_appliances
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base.xml'))
    model, hpxml = _test_measure(args_hash)

    # water use equipment peak flows
    fixture_gpd = 44.60
    dist_gpd = 10.2343
    cw_gpd = 3.7116
    dw_gpd = 2.7342
    assert_in_epsilon(fixture_gpd, get_wu_gpd(model, Constants.ObjectNameFixtures), 0.001)
    assert_in_epsilon(dist_gpd, get_wu_gpd(model, Constants.ObjectNameDistributionWaste), 0.001)
    assert_in_epsilon(cw_gpd, get_wu_gpd(model, Constants.ObjectNameClothesWasher), 0.001)
    assert_in_epsilon(dw_gpd, get_wu_gpd(model, Constants.ObjectNameDishwasher), 0.001)

    # electric equipment
    cw_ee_kwh_yr = 107.059
    cw_sens_frac = 0.27
    cw_lat_frac = 0.03
    assert_in_epsilon(cw_ee_kwh_yr, get_ee_kwh_per_year(model, Constants.ObjectNameClothesWasher), 0.001)
    assert_in_epsilon(cw_sens_frac, get_ee_fractions(model, Constants.ObjectNameClothesWasher)[0], 0.001)
    assert_in_epsilon(cw_lat_frac, get_ee_fractions(model, Constants.ObjectNameClothesWasher)[1], 0.001)

    dw_ee_kwh_yr = 93.392
    dw_sens_frac = 0.3
    dw_lat_frac = 0.300
    assert_in_epsilon(dw_ee_kwh_yr, get_ee_kwh_per_year(model, Constants.ObjectNameDishwasher), 0.001)
    assert_in_epsilon(dw_sens_frac, get_ee_fractions(model, Constants.ObjectNameDishwasher)[0], 0.001)
    assert_in_epsilon(dw_lat_frac, get_ee_fractions(model, Constants.ObjectNameDishwasher)[1], 0.001)

    cd_ee_kwh_yr = 443.317
    cd_sens_frac = 0.135
    cd_lat_frac = 0.015
    assert_in_epsilon(cd_ee_kwh_yr, get_ee_kwh_per_year(model, Constants.ObjectNameClothesDryer), 0.001)
    assert_in_epsilon(cd_sens_frac, get_ee_fractions(model, Constants.ObjectNameClothesDryer)[0], 0.001)
    assert_in_epsilon(cd_lat_frac, get_ee_fractions(model, Constants.ObjectNameClothesDryer)[1], 0.001)

    rf_ee_kwh_yr = 650.0
    rf_sens_frac = 1.0
    rf_lat_frac = 0.0
    assert_in_epsilon(rf_ee_kwh_yr, get_ee_kwh_per_year(model, Constants.ObjectNameRefrigerator), 0.001)
    assert_in_epsilon(rf_sens_frac, get_ee_fractions(model, Constants.ObjectNameRefrigerator)[0], 0.001)
    assert_in_epsilon(rf_lat_frac, get_ee_fractions(model, Constants.ObjectNameRefrigerator)[1], 0.001)

    cook_ee_kwh_yr = 448.0
    cook_sens_frac = 0.72
    cook_lat_frac = 0.080
    assert_in_epsilon(cook_ee_kwh_yr, get_ee_kwh_per_year(model, Constants.ObjectNameCookingRange), 0.001)
    assert_in_epsilon(cook_sens_frac, get_ee_fractions(model, Constants.ObjectNameCookingRange)[0], 0.001)
    assert_in_epsilon(cook_lat_frac, get_ee_fractions(model, Constants.ObjectNameCookingRange)[1], 0.001)

    # other equipment
    water_sens = -262.507
    water_lat = 266.358
    assert_in_epsilon(water_sens, get_oe_kwh_fuel(model, Constants.ObjectNameWater + ' Sensible')[0], 0.001)
    assert_in_epsilon(1.0, get_oe_fractions(model, Constants.ObjectNameWater + ' Sensible')[0], 0.001)
    assert_in_epsilon(0.0, get_oe_fractions(model, Constants.ObjectNameWater + ' Sensible')[1], 0.001)

    assert_in_epsilon(water_lat, get_oe_kwh_fuel(model, Constants.ObjectNameWater + ' Latent')[0], 0.001)
    assert_in_epsilon(0.0, get_oe_fractions(model, Constants.ObjectNameWater + ' Latent')[0], 0.001)
    assert_in_epsilon(1.0, get_oe_fractions(model, Constants.ObjectNameWater + ' Latent')[1], 0.001)
  end

  def test_appliances_modified
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-appliances-modified.xml'))
    model, hpxml = _test_measure(args_hash)

    # water use equipment peak flows
    fixture_gpd = 44.60
    dist_gpd = 10.2343
    cw_gpd = 3.7116
    dw_gpd = 5.475
    assert_in_epsilon(fixture_gpd, get_wu_gpd(model, Constants.ObjectNameFixtures), 0.001)
    assert_in_epsilon(dist_gpd, get_wu_gpd(model, Constants.ObjectNameDistributionWaste), 0.001)
    assert_in_epsilon(cw_gpd, get_wu_gpd(model, Constants.ObjectNameClothesWasher), 0.001)
    assert_in_epsilon(dw_gpd, get_wu_gpd(model, Constants.ObjectNameDishwasher), 0.001)

    # electric equipment
    cw_ee_kwh_yr = 107.059
    cw_sens_frac = 0.27
    cw_lat_frac = 0.03
    assert_in_epsilon(cw_ee_kwh_yr, get_ee_kwh_per_year(model, Constants.ObjectNameClothesWasher), 0.001)
    assert_in_epsilon(cw_sens_frac, get_ee_fractions(model, Constants.ObjectNameClothesWasher)[0], 0.001)
    assert_in_epsilon(cw_lat_frac, get_ee_fractions(model, Constants.ObjectNameClothesWasher)[1], 0.001)

    dw_ee_kwh_yr = 186.6
    dw_sens_frac = 0.3
    dw_lat_frac = 0.300
    assert_in_epsilon(dw_ee_kwh_yr, get_ee_kwh_per_year(model, Constants.ObjectNameDishwasher), 0.001)
    assert_in_epsilon(dw_sens_frac, get_ee_fractions(model, Constants.ObjectNameDishwasher)[0], 0.001)
    assert_in_epsilon(dw_lat_frac, get_ee_fractions(model, Constants.ObjectNameDishwasher)[1], 0.001)

    cd_ee_kwh_yr = 445.1052
    cd_sens_frac = 0.135
    cd_lat_frac = 0.015
    assert_in_epsilon(cd_ee_kwh_yr, get_ee_kwh_per_year(model, Constants.ObjectNameClothesDryer), 0.001)
    assert_in_epsilon(cd_sens_frac, get_ee_fractions(model, Constants.ObjectNameClothesDryer)[0], 0.001)
    assert_in_epsilon(cd_lat_frac, get_ee_fractions(model, Constants.ObjectNameClothesDryer)[1], 0.001)

    rf_ee_kwh_yr = 600.0
    rf_sens_frac = 1.0
    rf_lat_frac = 0.0
    assert_in_epsilon(rf_ee_kwh_yr, get_ee_kwh_per_year(model, Constants.ObjectNameRefrigerator), 0.001)
    assert_in_epsilon(rf_sens_frac, get_ee_fractions(model, Constants.ObjectNameRefrigerator)[0], 0.001)
    assert_in_epsilon(rf_lat_frac, get_ee_fractions(model, Constants.ObjectNameRefrigerator)[1], 0.001)

    cook_ee_kwh_yr = 448.0
    cook_sens_frac = 0.72
    cook_lat_frac = 0.080
    assert_in_epsilon(cook_ee_kwh_yr, get_ee_kwh_per_year(model, Constants.ObjectNameCookingRange), 0.001)
    assert_in_epsilon(cook_sens_frac, get_ee_fractions(model, Constants.ObjectNameCookingRange)[0], 0.001)
    assert_in_epsilon(cook_lat_frac, get_ee_fractions(model, Constants.ObjectNameCookingRange)[1], 0.001)

    # other equipment
    water_sens = -262.507
    water_lat = 266.358
    assert_in_epsilon(water_sens, get_oe_kwh_fuel(model, Constants.ObjectNameWater + ' Sensible')[0], 0.001)
    assert_in_epsilon(1.0, get_oe_fractions(model, Constants.ObjectNameWater + ' Sensible')[0], 0.001)
    assert_in_epsilon(0.0, get_oe_fractions(model, Constants.ObjectNameWater + ' Sensible')[1], 0.001)

    assert_in_epsilon(water_lat, get_oe_kwh_fuel(model, Constants.ObjectNameWater + ' Latent')[0], 0.001)
    assert_in_epsilon(0.0, get_oe_fractions(model, Constants.ObjectNameWater + ' Latent')[0], 0.001)
    assert_in_epsilon(1.0, get_oe_fractions(model, Constants.ObjectNameWater + ' Latent')[1], 0.001)
  end

  def test_appliances_oil
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-appliances-oil.xml'))
    model, hpxml = _test_measure(args_hash)

    # water use equipment peak flows
    fixture_gpd = 44.60
    dist_gpd = 10.2343
    cw_gpd = 3.7116
    dw_gpd = 2.7342
    assert_in_epsilon(fixture_gpd, get_wu_gpd(model, Constants.ObjectNameFixtures), 0.001)
    assert_in_epsilon(dist_gpd, get_wu_gpd(model, Constants.ObjectNameDistributionWaste), 0.001)
    assert_in_epsilon(cw_gpd, get_wu_gpd(model, Constants.ObjectNameClothesWasher), 0.001)
    assert_in_epsilon(dw_gpd, get_wu_gpd(model, Constants.ObjectNameDishwasher), 0.001)

    # electric equipment
    cw_ee_kwh_yr = 107.059
    cw_sens_frac = 0.27
    cw_lat_frac = 0.03
    assert_in_epsilon(cw_ee_kwh_yr, get_ee_kwh_per_year(model, Constants.ObjectNameClothesWasher), 0.001)
    assert_in_epsilon(cw_sens_frac, get_ee_fractions(model, Constants.ObjectNameClothesWasher)[0], 0.001)
    assert_in_epsilon(cw_lat_frac, get_ee_fractions(model, Constants.ObjectNameClothesWasher)[1], 0.001)

    dw_ee_kwh_yr = 93.392
    dw_sens_frac = 0.3
    dw_lat_frac = 0.300
    assert_in_epsilon(dw_ee_kwh_yr, get_ee_kwh_per_year(model, Constants.ObjectNameDishwasher), 0.001)
    assert_in_epsilon(dw_sens_frac, get_ee_fractions(model, Constants.ObjectNameDishwasher)[0], 0.001)
    assert_in_epsilon(dw_lat_frac, get_ee_fractions(model, Constants.ObjectNameDishwasher)[1], 0.001)

    cd_ee_kwh_yr = 39.646
    cd_sens_frac = 0.1335
    cd_lat_frac = 0.01648
    assert_in_epsilon(cd_ee_kwh_yr, get_ee_kwh_per_year(model, Constants.ObjectNameClothesDryer), 0.001)
    assert_in_epsilon(cd_sens_frac, get_ee_fractions(model, Constants.ObjectNameClothesDryer)[0], 0.001)
    assert_in_epsilon(cd_lat_frac, get_ee_fractions(model, Constants.ObjectNameClothesDryer)[1], 0.001)

    rf_ee_kwh_yr = 650.0
    rf_sens_frac = 1.0
    rf_lat_frac = 0.0
    assert_in_epsilon(rf_ee_kwh_yr, get_ee_kwh_per_year(model, Constants.ObjectNameRefrigerator), 0.001)
    assert_in_epsilon(rf_sens_frac, get_ee_fractions(model, Constants.ObjectNameRefrigerator)[0], 0.001)
    assert_in_epsilon(rf_lat_frac, get_ee_fractions(model, Constants.ObjectNameRefrigerator)[1], 0.001)

    cook_ee_kwh_yr = 30.70
    cook_sens_frac = 0.6382
    cook_lat_frac = 0.1618
    assert_in_epsilon(cook_ee_kwh_yr, get_ee_kwh_per_year(model, Constants.ObjectNameCookingRange), 0.001)
    assert_in_epsilon(cook_sens_frac, get_ee_fractions(model, Constants.ObjectNameCookingRange)[0], 0.001)
    assert_in_epsilon(cook_lat_frac, get_ee_fractions(model, Constants.ObjectNameCookingRange)[1], 0.001)

    # other equipment
    water_sens = -262.507
    water_lat = 266.358
    assert_in_epsilon(water_sens, get_oe_kwh_fuel(model, Constants.ObjectNameWater + ' Sensible')[0], 0.001)
    assert_in_epsilon(1.0, get_oe_fractions(model, Constants.ObjectNameWater + ' Sensible')[0], 0.001)
    assert_in_epsilon(0.0, get_oe_fractions(model, Constants.ObjectNameWater + ' Sensible')[1], 0.001)

    assert_in_epsilon(water_lat, get_oe_kwh_fuel(model, Constants.ObjectNameWater + ' Latent')[0], 0.001)
    assert_in_epsilon(0.0, get_oe_fractions(model, Constants.ObjectNameWater + ' Latent')[0], 0.001)
    assert_in_epsilon(1.0, get_oe_fractions(model, Constants.ObjectNameWater + ' Latent')[1], 0.001)

    cd_fuel_kwh = UnitConversions.convert(17.972, 'therm', 'kWh')
    assert_in_epsilon(cd_fuel_kwh, get_oe_kwh_fuel(model, Constants.ObjectNameClothesDryer)[0], 0.001)
    assert_equal('FuelOilNo1', get_oe_kwh_fuel(model, Constants.ObjectNameClothesDryer)[1], 0.001)
    assert_in_epsilon(cd_sens_frac, get_oe_fractions(model, Constants.ObjectNameClothesDryer)[0], 0.001)
    assert_in_epsilon(cd_lat_frac, get_oe_fractions(model, Constants.ObjectNameClothesDryer)[1], 0.001)

    cook_fuel_kwh = UnitConversions.convert(30.70, 'therm', 'kWh')
    assert_in_epsilon(cook_fuel_kwh, get_oe_kwh_fuel(model, Constants.ObjectNameCookingRange)[0], 0.001)
    assert_equal('FuelOilNo1', get_oe_kwh_fuel(model, Constants.ObjectNameCookingRange)[1], 0.001)
    assert_in_epsilon(cook_sens_frac, get_oe_fractions(model, Constants.ObjectNameCookingRange)[0], 0.001)
    assert_in_epsilon(cook_lat_frac, get_oe_fractions(model, Constants.ObjectNameCookingRange)[1], 0.001)
  end

  def test_appliances_gas
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-appliances-gas.xml'))
    model, hpxml = _test_measure(args_hash)

    # water use equipment peak flows
    fixture_gpd = 44.60
    dist_gpd = 10.2343
    cw_gpd = 3.7116
    dw_gpd = 2.7342
    assert_in_epsilon(fixture_gpd, get_wu_gpd(model, Constants.ObjectNameFixtures), 0.001)
    assert_in_epsilon(dist_gpd, get_wu_gpd(model, Constants.ObjectNameDistributionWaste), 0.001)
    assert_in_epsilon(cw_gpd, get_wu_gpd(model, Constants.ObjectNameClothesWasher), 0.001)
    assert_in_epsilon(dw_gpd, get_wu_gpd(model, Constants.ObjectNameDishwasher), 0.001)

    # electric equipment
    cw_ee_kwh_yr = 107.059
    cw_sens_frac = 0.27
    cw_lat_frac = 0.03
    assert_in_epsilon(cw_ee_kwh_yr, get_ee_kwh_per_year(model, Constants.ObjectNameClothesWasher), 0.001)
    assert_in_epsilon(cw_sens_frac, get_ee_fractions(model, Constants.ObjectNameClothesWasher)[0], 0.001)
    assert_in_epsilon(cw_lat_frac, get_ee_fractions(model, Constants.ObjectNameClothesWasher)[1], 0.001)

    dw_ee_kwh_yr = 93.392
    dw_sens_frac = 0.3
    dw_lat_frac = 0.300
    assert_in_epsilon(dw_ee_kwh_yr, get_ee_kwh_per_year(model, Constants.ObjectNameDishwasher), 0.001)
    assert_in_epsilon(dw_sens_frac, get_ee_fractions(model, Constants.ObjectNameDishwasher)[0], 0.001)
    assert_in_epsilon(dw_lat_frac, get_ee_fractions(model, Constants.ObjectNameDishwasher)[1], 0.001)

    cd_ee_kwh_yr = 39.646
    cd_sens_frac = 0.1335
    cd_lat_frac = 0.01648
    assert_in_epsilon(cd_ee_kwh_yr, get_ee_kwh_per_year(model, Constants.ObjectNameClothesDryer), 0.001)
    assert_in_epsilon(cd_sens_frac, get_ee_fractions(model, Constants.ObjectNameClothesDryer)[0], 0.001)
    assert_in_epsilon(cd_lat_frac, get_ee_fractions(model, Constants.ObjectNameClothesDryer)[1], 0.001)

    rf_ee_kwh_yr = 650.0
    rf_sens_frac = 1.0
    rf_lat_frac = 0.0
    assert_in_epsilon(rf_ee_kwh_yr, get_ee_kwh_per_year(model, Constants.ObjectNameRefrigerator), 0.001)
    assert_in_epsilon(rf_sens_frac, get_ee_fractions(model, Constants.ObjectNameRefrigerator)[0], 0.001)
    assert_in_epsilon(rf_lat_frac, get_ee_fractions(model, Constants.ObjectNameRefrigerator)[1], 0.001)

    cook_ee_kwh_yr = 30.70
    cook_sens_frac = 0.6382
    cook_lat_frac = 0.1618
    assert_in_epsilon(cook_ee_kwh_yr, get_ee_kwh_per_year(model, Constants.ObjectNameCookingRange), 0.001)
    assert_in_epsilon(cook_sens_frac, get_ee_fractions(model, Constants.ObjectNameCookingRange)[0], 0.001)
    assert_in_epsilon(cook_lat_frac, get_ee_fractions(model, Constants.ObjectNameCookingRange)[1], 0.001)

    # other equipment
    water_sens = -262.507
    water_lat = 266.358
    assert_in_epsilon(water_sens, get_oe_kwh_fuel(model, Constants.ObjectNameWater + ' Sensible')[0], 0.001)
    assert_in_epsilon(1.0, get_oe_fractions(model, Constants.ObjectNameWater + ' Sensible')[0], 0.001)
    assert_in_epsilon(0.0, get_oe_fractions(model, Constants.ObjectNameWater + ' Sensible')[1], 0.001)

    assert_in_epsilon(water_lat, get_oe_kwh_fuel(model, Constants.ObjectNameWater + ' Latent')[0], 0.001)
    assert_in_epsilon(0.0, get_oe_fractions(model, Constants.ObjectNameWater + ' Latent')[0], 0.001)
    assert_in_epsilon(1.0, get_oe_fractions(model, Constants.ObjectNameWater + ' Latent')[1], 0.001)

    cd_fuel_kwh = UnitConversions.convert(17.972, 'therm', 'kWh')
    assert_in_epsilon(cd_fuel_kwh, get_oe_kwh_fuel(model, Constants.ObjectNameClothesDryer)[0], 0.001)
    assert_equal('NaturalGas', get_oe_kwh_fuel(model, Constants.ObjectNameClothesDryer)[1], 0.001)
    assert_in_epsilon(cd_sens_frac, get_oe_fractions(model, Constants.ObjectNameClothesDryer)[0], 0.001)
    assert_in_epsilon(cd_lat_frac, get_oe_fractions(model, Constants.ObjectNameClothesDryer)[1], 0.001)

    cook_fuel_kwh = UnitConversions.convert(30.70, 'therm', 'kWh')
    assert_in_epsilon(cook_fuel_kwh, get_oe_kwh_fuel(model, Constants.ObjectNameCookingRange)[0], 0.001)
    assert_equal('NaturalGas', get_oe_kwh_fuel(model, Constants.ObjectNameCookingRange)[1], 0.001)
    assert_in_epsilon(cook_sens_frac, get_oe_fractions(model, Constants.ObjectNameCookingRange)[0], 0.001)
    assert_in_epsilon(cook_lat_frac, get_oe_fractions(model, Constants.ObjectNameCookingRange)[1], 0.001)
  end

  def test_appliances_propane
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-appliances-propane.xml'))
    model, hpxml = _test_measure(args_hash)

    # water use equipment peak flows
    fixture_gpd = 44.60
    dist_gpd = 10.2343
    cw_gpd = 3.7116
    dw_gpd = 2.7342
    assert_in_epsilon(fixture_gpd, get_wu_gpd(model, Constants.ObjectNameFixtures), 0.001)
    assert_in_epsilon(dist_gpd, get_wu_gpd(model, Constants.ObjectNameDistributionWaste), 0.001)
    assert_in_epsilon(cw_gpd, get_wu_gpd(model, Constants.ObjectNameClothesWasher), 0.001)
    assert_in_epsilon(dw_gpd, get_wu_gpd(model, Constants.ObjectNameDishwasher), 0.001)

    # electric equipment
    cw_ee_kwh_yr = 107.059
    cw_sens_frac = 0.27
    cw_lat_frac = 0.03
    assert_in_epsilon(cw_ee_kwh_yr, get_ee_kwh_per_year(model, Constants.ObjectNameClothesWasher), 0.001)
    assert_in_epsilon(cw_sens_frac, get_ee_fractions(model, Constants.ObjectNameClothesWasher)[0], 0.001)
    assert_in_epsilon(cw_lat_frac, get_ee_fractions(model, Constants.ObjectNameClothesWasher)[1], 0.001)

    dw_ee_kwh_yr = 93.392
    dw_sens_frac = 0.3
    dw_lat_frac = 0.300
    assert_in_epsilon(dw_ee_kwh_yr, get_ee_kwh_per_year(model, Constants.ObjectNameDishwasher), 0.001)
    assert_in_epsilon(dw_sens_frac, get_ee_fractions(model, Constants.ObjectNameDishwasher)[0], 0.001)
    assert_in_epsilon(dw_lat_frac, get_ee_fractions(model, Constants.ObjectNameDishwasher)[1], 0.001)

    cd_ee_kwh_yr = 39.646
    cd_sens_frac = 0.1335
    cd_lat_frac = 0.01648
    assert_in_epsilon(cd_ee_kwh_yr, get_ee_kwh_per_year(model, Constants.ObjectNameClothesDryer), 0.001)
    assert_in_epsilon(cd_sens_frac, get_ee_fractions(model, Constants.ObjectNameClothesDryer)[0], 0.001)
    assert_in_epsilon(cd_lat_frac, get_ee_fractions(model, Constants.ObjectNameClothesDryer)[1], 0.001)

    rf_ee_kwh_yr = 650.0
    rf_sens_frac = 1.0
    rf_lat_frac = 0.0
    assert_in_epsilon(rf_ee_kwh_yr, get_ee_kwh_per_year(model, Constants.ObjectNameRefrigerator), 0.001)
    assert_in_epsilon(rf_sens_frac, get_ee_fractions(model, Constants.ObjectNameRefrigerator)[0], 0.001)
    assert_in_epsilon(rf_lat_frac, get_ee_fractions(model, Constants.ObjectNameRefrigerator)[1], 0.001)

    cook_ee_kwh_yr = 30.70
    cook_sens_frac = 0.6382
    cook_lat_frac = 0.1618
    assert_in_epsilon(cook_ee_kwh_yr, get_ee_kwh_per_year(model, Constants.ObjectNameCookingRange), 0.001)
    assert_in_epsilon(cook_sens_frac, get_ee_fractions(model, Constants.ObjectNameCookingRange)[0], 0.001)
    assert_in_epsilon(cook_lat_frac, get_ee_fractions(model, Constants.ObjectNameCookingRange)[1], 0.001)

    # other equipment
    water_sens = -262.507
    water_lat = 266.358
    assert_in_epsilon(water_sens, get_oe_kwh_fuel(model, Constants.ObjectNameWater + ' Sensible')[0], 0.001)
    assert_in_epsilon(1.0, get_oe_fractions(model, Constants.ObjectNameWater + ' Sensible')[0], 0.001)
    assert_in_epsilon(0.0, get_oe_fractions(model, Constants.ObjectNameWater + ' Sensible')[1], 0.001)

    assert_in_epsilon(water_lat, get_oe_kwh_fuel(model, Constants.ObjectNameWater + ' Latent')[0], 0.001)
    assert_in_epsilon(0.0, get_oe_fractions(model, Constants.ObjectNameWater + ' Latent')[0], 0.001)
    assert_in_epsilon(1.0, get_oe_fractions(model, Constants.ObjectNameWater + ' Latent')[1], 0.001)

    cd_fuel_kwh = UnitConversions.convert(17.972, 'therm', 'kWh')
    assert_in_epsilon(cd_fuel_kwh, get_oe_kwh_fuel(model, Constants.ObjectNameClothesDryer)[0], 0.001)
    assert_equal('Propane', get_oe_kwh_fuel(model, Constants.ObjectNameClothesDryer)[1], 0.001)
    assert_in_epsilon(cd_sens_frac, get_oe_fractions(model, Constants.ObjectNameClothesDryer)[0], 0.001)
    assert_in_epsilon(cd_lat_frac, get_oe_fractions(model, Constants.ObjectNameClothesDryer)[1], 0.001)

    cook_fuel_kwh = UnitConversions.convert(30.70, 'therm', 'kWh')
    assert_in_epsilon(cook_fuel_kwh, get_oe_kwh_fuel(model, Constants.ObjectNameCookingRange)[0], 0.001)
    assert_equal('Propane', get_oe_kwh_fuel(model, Constants.ObjectNameCookingRange)[1], 0.001)
    assert_in_epsilon(cook_sens_frac, get_oe_fractions(model, Constants.ObjectNameCookingRange)[0], 0.001)
    assert_in_epsilon(cook_lat_frac, get_oe_fractions(model, Constants.ObjectNameCookingRange)[1], 0.001)
  end

  def test_appliances_wood
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-appliances-wood.xml'))
    model, hpxml = _test_measure(args_hash)

    # water use equipment peak flows
    fixture_gpd = 44.60
    dist_gpd = 10.2343
    cw_gpd = 3.7116
    dw_gpd = 2.7342
    assert_in_epsilon(fixture_gpd, get_wu_gpd(model, Constants.ObjectNameFixtures), 0.001)
    assert_in_epsilon(dist_gpd, get_wu_gpd(model, Constants.ObjectNameDistributionWaste), 0.001)
    assert_in_epsilon(cw_gpd, get_wu_gpd(model, Constants.ObjectNameClothesWasher), 0.001)
    assert_in_epsilon(dw_gpd, get_wu_gpd(model, Constants.ObjectNameDishwasher), 0.001)

    # electric equipment
    cw_ee_kwh_yr = 107.059
    cw_sens_frac = 0.27
    cw_lat_frac = 0.03
    assert_in_epsilon(cw_ee_kwh_yr, get_ee_kwh_per_year(model, Constants.ObjectNameClothesWasher), 0.001)
    assert_in_epsilon(cw_sens_frac, get_ee_fractions(model, Constants.ObjectNameClothesWasher)[0], 0.001)
    assert_in_epsilon(cw_lat_frac, get_ee_fractions(model, Constants.ObjectNameClothesWasher)[1], 0.001)

    dw_ee_kwh_yr = 93.392
    dw_sens_frac = 0.3
    dw_lat_frac = 0.300
    assert_in_epsilon(dw_ee_kwh_yr, get_ee_kwh_per_year(model, Constants.ObjectNameDishwasher), 0.001)
    assert_in_epsilon(dw_sens_frac, get_ee_fractions(model, Constants.ObjectNameDishwasher)[0], 0.001)
    assert_in_epsilon(dw_lat_frac, get_ee_fractions(model, Constants.ObjectNameDishwasher)[1], 0.001)

    cd_ee_kwh_yr = 39.646
    cd_sens_frac = 0.1335
    cd_lat_frac = 0.01648
    assert_in_epsilon(cd_ee_kwh_yr, get_ee_kwh_per_year(model, Constants.ObjectNameClothesDryer), 0.001)
    assert_in_epsilon(cd_sens_frac, get_ee_fractions(model, Constants.ObjectNameClothesDryer)[0], 0.001)
    assert_in_epsilon(cd_lat_frac, get_ee_fractions(model, Constants.ObjectNameClothesDryer)[1], 0.001)

    rf_ee_kwh_yr = 650.0
    rf_sens_frac = 1.0
    rf_lat_frac = 0.0
    assert_in_epsilon(rf_ee_kwh_yr, get_ee_kwh_per_year(model, Constants.ObjectNameRefrigerator), 0.001)
    assert_in_epsilon(rf_sens_frac, get_ee_fractions(model, Constants.ObjectNameRefrigerator)[0], 0.001)
    assert_in_epsilon(rf_lat_frac, get_ee_fractions(model, Constants.ObjectNameRefrigerator)[1], 0.001)

    cook_ee_kwh_yr = 30.70
    cook_sens_frac = 0.6382
    cook_lat_frac = 0.1618
    assert_in_epsilon(cook_ee_kwh_yr, get_ee_kwh_per_year(model, Constants.ObjectNameCookingRange), 0.001)
    assert_in_epsilon(cook_sens_frac, get_ee_fractions(model, Constants.ObjectNameCookingRange)[0], 0.001)
    assert_in_epsilon(cook_lat_frac, get_ee_fractions(model, Constants.ObjectNameCookingRange)[1], 0.001)

    # other equipment
    water_sens = -262.507
    water_lat = 266.358
    assert_in_epsilon(water_sens, get_oe_kwh_fuel(model, Constants.ObjectNameWater + ' Sensible')[0], 0.001)
    assert_in_epsilon(1.0, get_oe_fractions(model, Constants.ObjectNameWater + ' Sensible')[0], 0.001)
    assert_in_epsilon(0.0, get_oe_fractions(model, Constants.ObjectNameWater + ' Sensible')[1], 0.001)

    assert_in_epsilon(water_lat, get_oe_kwh_fuel(model, Constants.ObjectNameWater + ' Latent')[0], 0.001)
    assert_in_epsilon(0.0, get_oe_fractions(model, Constants.ObjectNameWater + ' Latent')[0], 0.001)
    assert_in_epsilon(1.0, get_oe_fractions(model, Constants.ObjectNameWater + ' Latent')[1], 0.001)

    cd_fuel_kwh = UnitConversions.convert(17.972, 'therm', 'kWh')
    assert_in_epsilon(cd_fuel_kwh, get_oe_kwh_fuel(model, Constants.ObjectNameClothesDryer)[0], 0.001)
    assert_equal('OtherFuel1', get_oe_kwh_fuel(model, Constants.ObjectNameClothesDryer)[1], 0.001)
    assert_in_epsilon(cd_sens_frac, get_oe_fractions(model, Constants.ObjectNameClothesDryer)[0], 0.001)
    assert_in_epsilon(cd_lat_frac, get_oe_fractions(model, Constants.ObjectNameClothesDryer)[1], 0.001)

    cook_fuel_kwh = UnitConversions.convert(30.70, 'therm', 'kWh')
    assert_in_epsilon(cook_fuel_kwh, get_oe_kwh_fuel(model, Constants.ObjectNameCookingRange)[0], 0.001)
    assert_equal('OtherFuel1', get_oe_kwh_fuel(model, Constants.ObjectNameCookingRange)[1], 0.001)
    assert_in_epsilon(cook_sens_frac, get_oe_fractions(model, Constants.ObjectNameCookingRange)[0], 0.001)
    assert_in_epsilon(cook_lat_frac, get_oe_fractions(model, Constants.ObjectNameCookingRange)[1], 0.001)
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
