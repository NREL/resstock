require_relative 'minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'
require 'rexml/document'
require 'rexml/xpath'
require_relative '../resources/constants'
require_relative '../resources/meta_measure'
require_relative '../resources/unit_conversions'
require_relative '../resources/xmlhelper'

class HPXMLTranslatorTest < MiniTest::Test
  def test_simulations
    OpenStudio::Logger.instance.standardOutLogger.setLogLevel(OpenStudio::Error)
    # OpenStudio::Logger.instance.standardOutLogger.setLogLevel(OpenStudio::Fatal)

    this_dir = File.dirname(__FILE__)
    results_dir = File.join(this_dir, "results")
    _rm_path(results_dir)

    args = {}
    args['weather_dir'] = File.absolute_path(File.join(this_dir, "..", "weather"))
    args['skip_validation'] = false

    @simulation_runtime_key = "Simulation Runtime"
    @workflow_runtime_key = "Workflow Runtime"

    cfis_dir = File.absolute_path(File.join(this_dir, "cfis"))
    hvac_base_dir = File.absolute_path(File.join(this_dir, "hvac_base"))
    hvac_multiple_dir = File.absolute_path(File.join(this_dir, "hvac_multiple"))
    hvac_partial_dir = File.absolute_path(File.join(this_dir, "hvac_partial"))
    hvac_load_fracs_dir = File.absolute_path(File.join(this_dir, "hvac_load_fracs"))
    water_heating_multiple_dir = File.absolute_path(File.join(this_dir, "water_heating_multiple"))
    autosize_dir = File.absolute_path(File.join(this_dir, "hvac_autosizing"))

    test_dirs = [this_dir,
                 cfis_dir,
                 hvac_base_dir,
                 hvac_multiple_dir,
                 hvac_partial_dir,
                 hvac_load_fracs_dir,
                 water_heating_multiple_dir,
                 autosize_dir]

    xmls = []
    test_dirs.each do |test_dir|
      Dir["#{test_dir}/base*.xml"].sort.each do |xml|
        xmls << File.absolute_path(xml)
      end
    end

    # Test simulations
    puts "Running #{xmls.size} HPXML files..."
    all_results = {}
    xmls.each do |xml|
      all_results[xml] = _run_xml(xml, this_dir, args.dup)
    end

    _write_summary_results(results_dir, all_results)

    # Cross simulation tests
    _test_multiple_hvac(xmls, hvac_multiple_dir, hvac_base_dir, all_results)
    _test_multiple_water_heaters(xmls, water_heating_multiple_dir, all_results)
    _test_partial_hvac(xmls, hvac_partial_dir, hvac_base_dir, all_results)
    _test_hrv_erv_inputs(this_dir, all_results)
    _test_heating_cooling_loads(xmls, hvac_base_dir, all_results)
    _test_collapsed_surfaces(all_results, this_dir)
  end

  def test_invalid
    this_dir = File.dirname(__FILE__)

    args = {}
    args['weather_dir'] = File.absolute_path(File.join(this_dir, "..", "weather"))
    args['skip_validation'] = false

    expected_error_msgs = { 'bad-wmo.xml' => ["Weather station WMO '999999' could not be found in weather/data.csv."],
                            'bad-site-neighbor-azimuth.xml' => ["A neighbor building has an azimuth (145) not equal to the azimuth of any wall."],
                            'cfis-with-hydronic-distribution.xml' => ["Attached HVAC distribution system 'HVACDistribution' cannot be hydronic for mechanical ventilation 'MechanicalVentilation'."],
                            'clothes-dryer-location.xml' => ["ClothesDryer location is 'garage' but building does not have this location specified."],
                            'clothes-dryer-location-other.xml' => ["Expected [1] element(s) but found 0 element(s) for xpath: /HPXML/Building/BuildingDetails/Appliances/ClothesDryer[Location="],
                            'clothes-washer-location.xml' => ["ClothesWasher location is 'garage' but building does not have this location specified."],
                            'clothes-washer-location-other.xml' => ["Expected [1] element(s) but found 0 element(s) for xpath: /HPXML/Building/BuildingDetails/Appliances/ClothesWasher[Location="],
                            'dhw-frac-load-served.xml' => ["Expected FractionDHWLoadServed to sum to 1, but calculated sum is 1.15."],
                            'duct-location.xml' => ["Duct location is 'garage' but building does not have this location specified."],
                            'duct-location-other.xml' => ["Expected [1] element(s) but found 0 element(s) for xpath: /HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution/DistributionSystemType/AirDistribution/Ducts[DuctType='supply' or DuctType='return'][DuctLocation="],
                            'heat-pump-mixed-fixed-and-autosize-capacities.xml' => ["HeatPump 'HeatPump' CoolingCapacity and HeatingCapacity must either both be auto-sized or fixed-sized."],
                            'heat-pump-mixed-fixed-and-autosize-capacities2.xml' => ["HeatPump 'HeatPump' CoolingCapacity and HeatingCapacity must either both be auto-sized or fixed-sized."],
                            'heat-pump-mixed-fixed-and-autosize-capacities3.xml' => ["HeatPump 'HeatPump' has HeatingCapacity17F provided but heating capacity is auto-sized."],
                            'heat-pump-mixed-fixed-and-autosize-capacities4.xml' => ["HeatPump 'HeatPump' BackupHeatingCapacity and HeatingCapacity must either both be auto-sized or fixed-sized."],
                            'hvac-distribution-multiple-attached-cooling.xml' => ["Multiple cooling systems found attached to distribution system 'HVACDistribution4'."],
                            'hvac-distribution-multiple-attached-heating.xml' => ["Multiple heating systems found attached to distribution system 'HVACDistribution3'."],
                            'hvac-dse-multiple-attached-cooling.xml' => ["Multiple cooling systems found attached to distribution system 'HVACDistribution'."],
                            'hvac-dse-multiple-attached-heating.xml' => ["Multiple heating systems found attached to distribution system 'HVACDistribution'."],
                            'hvac-frac-load-served.xml' => ["Expected FractionCoolLoadServed to sum to <= 1, but calculated sum is 1.2.",
                                                            "Expected FractionHeatLoadServed to sum to <= 1, but calculated sum is 1.1."],
                            'invalid-relatedhvac-dhw-indirect.xml' => ["RelatedHVACSystem 'HeatingSystem_bad' not found for water heating system 'WaterHeater'"],
                            'invalid-relatedhvac-desuperheater.xml' => ["RelatedHVACSystem 'CoolingSystem_bad' not found for water heating system 'WaterHeater'."],
                            'missing-elements.xml' => ["Expected [1] element(s) but found 0 element(s) for xpath: /HPXML/Building/BuildingDetails/BuildingSummary/BuildingConstruction/NumberofConditionedFloors",
                                                       "Expected [1] element(s) but found 0 element(s) for xpath: /HPXML/Building/BuildingDetails/BuildingSummary/BuildingConstruction/ConditionedFloorArea"],
                            'missing-surfaces.xml' => ["'garage' must have at least one floor surface."],
                            'net-area-negative-wall.xml' => ["Calculated a negative net surface area for surface 'Wall'."],
                            'net-area-negative-roof.xml' => ["Calculated a negative net surface area for surface 'Roof'."],
                            'orphaned-hvac-distribution.xml' => ["Distribution system 'HVACDistribution' found but no HVAC system attached to it."],
                            'refrigerator-location.xml' => ["Refrigerator location is 'garage' but building does not have this location specified."],
                            'refrigerator-location-other.xml' => ["Expected [1] element(s) but found 0 element(s) for xpath: /HPXML/Building/BuildingDetails/Appliances/Refrigerator[Location="],
                            'repeated-relatedhvac-dhw-indirect.xml' => ["RelatedHVACSystem 'HeatingSystem' for water heating system 'WaterHeater2' is already attached to another water heating system."],
                            'repeated-relatedhvac-desuperheater.xml' => ["RelatedHVACSystem 'CoolingSystem' for water heating system 'WaterHeater2' is already attached to another water heating system."],
                            'unattached-cfis.xml' => ["Attached HVAC distribution system 'foobar' not found for mechanical ventilation 'MechanicalVentilation'."],
                            'unattached-door.xml' => ["Attached wall 'foobar' not found for door 'DoorNorth'."],
                            'unattached-hvac-distribution.xml' => ["Attached HVAC distribution system 'foobar' cannot be found for HVAC system 'HeatingSystem'."],
                            'unattached-skylight.xml' => ["Attached roof 'foobar' not found for skylight 'SkylightNorth'."],
                            'unattached-window.xml' => ["Attached wall 'foobar' not found for window 'WindowNorth'."],
                            'water-heater-location.xml' => ["WaterHeatingSystem location is 'crawlspace - vented' but building does not have this location specified."],
                            'water-heater-location-other.xml' => ["Expected [1] element(s) but found 0 element(s) for xpath: /HPXML/Building/BuildingDetails/Systems/WaterHeating/WaterHeatingSystem[Location="] }

    # Test simulations
    Dir["#{this_dir}/invalid_files/*.xml"].sort.each do |xml|
      _run_xml(File.absolute_path(xml), this_dir, args.dup, true, expected_error_msgs[File.basename(xml)])
    end
  end

  def test_generalized_hvac
    # single-speed air conditioner
    seer_to_expected_eer = { 13 => 11.2, 14 => 12.1, 15 => 13.0, 16 => 13.6 }
    seer_to_expected_eer.each do |seer, expected_eer|
      fan_power_rated = HVAC.get_fan_power_rated(seer)
      actual_eer = HVAC.calc_EER_cooling_1spd(seer, fan_power_rated, HVAC.cOOL_EIR_FT_SPEC_AC)
      assert_in_epsilon(expected_eer, actual_eer, 0.01)
    end

    # single-speed air source heat pump
    hspf_to_seer = { 7.7 => 13, 8.2 => 14, 8.5 => 15 }
    seer_to_expected_eer = { 13 => 11.31, 14 => 12.21, 15 => 13.12 }
    seer_to_expected_eer.each do |seer, expected_eer|
      fan_power_rated = HVAC.get_fan_power_rated(seer)
      actual_eer = HVAC.calc_EER_cooling_1spd(seer, fan_power_rated, HVAC.cOOL_EIR_FT_SPEC_ASHP)
      assert_in_epsilon(expected_eer, actual_eer, 0.01)
    end
    hspf_to_expected_cop = { 7.7 => 3.09, 8.2 => 3.35, 8.5 => 3.51 }
    hspf_to_expected_cop.each do |hspf, expected_cop|
      fan_power_rated = HVAC.get_fan_power_rated(hspf_to_seer[hspf])
      actual_cop = HVAC.calc_COP_heating_1spd(hspf, HVAC.get_c_d_heating(1, hspf), fan_power_rated, HVAC.hEAT_EIR_FT_SPEC_ASHP, HVAC.hEAT_CAP_FT_SPEC_ASHP)
      assert_in_epsilon(expected_cop, actual_cop, 0.01)
    end

    # two-speed air conditioner
    seer_to_expected_eers = { 16 => [13.8, 12.7], 17 => [14.7, 13.6], 18 => [15.5, 14.5], 21 => [18.2, 17.2] }
    seer_to_expected_eers.each do |seer, expected_eers|
      fan_power_rated = HVAC.get_fan_power_rated(seer)
      actual_eers = HVAC.calc_EERs_cooling_2spd(nil, seer, HVAC.get_c_d_cooling(2, seer), HVAC.two_speed_capacity_ratios, HVAC.two_speed_fan_speed_ratios_cooling, fan_power_rated, HVAC.cOOL_EIR_FT_SPEC_AC(2), HVAC.cOOL_CAP_FT_SPEC_AC(2))
      expected_eers.zip(actual_eers).each do |expected_eer, actual_eer|
        assert_in_epsilon(expected_eer, actual_eer, 0.01)
      end
    end

    # two-speed air source heat pump
    hspf_to_seer = { 8.6 => 16, 8.7 => 17, 9.3 => 18, 9.5 => 19 }
    seer_to_expected_eers = { 16 => [13.2, 12.2], 17 => [14.1, 13.0], 18 => [14.9, 13.9], 19 => [15.7, 14.7] }
    seer_to_expected_eers.each do |seer, expected_eers|
      fan_power_rated = HVAC.get_fan_power_rated(seer)
      actual_eers = HVAC.calc_EERs_cooling_2spd(nil, seer, HVAC.get_c_d_cooling(2, seer), HVAC.two_speed_capacity_ratios, HVAC.two_speed_fan_speed_ratios_cooling, fan_power_rated, HVAC.cOOL_EIR_FT_SPEC_ASHP(2), HVAC.cOOL_CAP_FT_SPEC_ASHP(2))
      expected_eers.zip(actual_eers).each do |expected_eer, actual_eer|
        assert_in_epsilon(expected_eer, actual_eer, 0.01)
      end
    end
    hspf_to_expected_cops = { 8.6 => [3.85, 3.34], 8.7 => [3.90, 3.41], 9.3 => [4.24, 3.83], 9.5 => [4.35, 3.98] }
    hspf_to_expected_cops.each do |hspf, expected_cops|
      fan_power_rated = HVAC.get_fan_power_rated(hspf_to_seer[hspf])
      actual_cops = HVAC.calc_COPs_heating_2spd(hspf, HVAC.get_c_d_heating(2, hspf), HVAC.two_speed_capacity_ratios, HVAC.two_speed_fan_speed_ratios_heating, fan_power_rated, HVAC.hEAT_EIR_FT_SPEC_ASHP(2), HVAC.hEAT_CAP_FT_SPEC_ASHP(2))
      expected_cops.zip(actual_cops).each do |expected_cop, actual_cop|
        assert_in_epsilon(expected_cop, actual_cop, 0.01)
      end
    end

    # variable-speed air conditioner
    capacity_ratios = HVAC.variable_speed_capacity_ratios_cooling
    fan_speed_ratios = HVAC.variable_speed_fan_speed_ratios_cooling
    cap_ratio_seer = [capacity_ratios[0], capacity_ratios[1], capacity_ratios[3]]
    fan_speed_seer = [fan_speed_ratios[0], fan_speed_ratios[1], fan_speed_ratios[3]]
    seer_to_expected_eers = { 24.5 => [19.5, 20.2, 19.7, 18.3] }
    seer_to_expected_eers.each do |seer, expected_eers|
      fan_power_rated = HVAC.get_fan_power_rated(seer)
      actual_eers = HVAC.calc_EERs_cooling_4spd(nil, seer, HVAC.get_c_d_cooling(4, seer), cap_ratio_seer, fan_speed_seer, fan_power_rated, HVAC.cOOL_EIR_FT_SPEC_AC([0, 1, 4]), HVAC.cOOL_CAP_FT_SPEC_AC([0, 1, 4]))
      expected_eers.zip(actual_eers).each do |expected_eer, actual_eer|
        assert_in_epsilon(expected_eer, actual_eer, 0.01)
      end
    end

    # variable-speed air source heat pump
    capacity_ratios = HVAC.variable_speed_capacity_ratios_cooling
    fan_speed_ratios = HVAC.variable_speed_fan_speed_ratios_cooling
    cap_ratio_seer = [capacity_ratios[0], capacity_ratios[1], capacity_ratios[3]]
    fan_speed_seer = [fan_speed_ratios[0], fan_speed_ratios[1], fan_speed_ratios[3]]
    seer_to_expected_eers = { 22.0 => [17.49, 18.09, 17.64, 16.43], 24.5 => [19.5, 20.2, 19.7, 18.3] }
    seer_to_expected_eers.each do |seer, expected_eers|
      fan_power_rated = HVAC.get_fan_power_rated(seer)
      actual_eers = HVAC.calc_EERs_cooling_4spd(nil, seer, HVAC.get_c_d_cooling(4, seer), cap_ratio_seer, fan_speed_seer, fan_power_rated, HVAC.cOOL_EIR_FT_SPEC_ASHP([0, 1, 4]), HVAC.cOOL_CAP_FT_SPEC_ASHP([0, 1, 4]))
      expected_eers.zip(actual_eers).each do |expected_eer, actual_eer|
        assert_in_epsilon(expected_eer, actual_eer, 0.01)
      end
    end
    capacity_ratios = HVAC.variable_speed_capacity_ratios_heating
    fan_speed_ratios = HVAC.variable_speed_fan_speed_ratios_heating
    hspf_to_expected_cops = { 10.0 => [5.18, 4.48, 3.83, 3.67] }
    hspf_to_expected_cops.each do |hspf, expected_cops|
      fan_power_rated = 0.14
      actual_cops = HVAC.calc_COPs_heating_4spd(nil, hspf, HVAC.get_c_d_heating(4, hspf), capacity_ratios, fan_speed_ratios, fan_power_rated, HVAC.hEAT_EIR_FT_SPEC_ASHP(4), HVAC.hEAT_CAP_FT_SPEC_ASHP(4))
      expected_cops.zip(actual_cops).each do |expected_cop, actual_cop|
        assert_in_epsilon(expected_cop, actual_cop, 0.01)
      end
    end
  end

  def _run_xml(xml, this_dir, args, expect_error = false, expect_error_msgs = nil)
    print "Testing #{File.basename(xml)}...\n"
    rundir = File.join(this_dir, "run")
    args['epw_output_path'] = File.absolute_path(File.join(rundir, "in.epw"))
    args['osm_output_path'] = File.absolute_path(File.join(rundir, "in.osm"))
    args['hpxml_path'] = xml
    args['map_tsv_dir'] = rundir
    _test_schema_validation(this_dir, xml)
    results = _test_simulation(args, this_dir, rundir, expect_error, expect_error_msgs)
    return results
  end

  def _get_results(rundir, sim_time, workflow_time)
    sql_path = File.join(rundir, "eplusout.sql")
    sqlFile = OpenStudio::SqlFile.new(sql_path, false)

    tdws = 'TabularDataWithStrings'
    abups = 'AnnualBuildingUtilityPerformanceSummary'
    ef = 'Entire Facility'
    eubs = 'End Uses By Subcategory'
    s = 'Subcategory'

    # Obtain fueltypes
    query = "SELECT ColumnName FROM #{tdws} WHERE ReportName='#{abups}' AND ReportForString='#{ef}' AND TableName='#{eubs}' and ColumnName!='#{s}'"
    fueltypes = sqlFile.execAndReturnVectorOfString(query).get

    # Obtain units
    query = "SELECT Units FROM #{tdws} WHERE ReportName='#{abups}' AND ReportForString='#{ef}' AND TableName='#{eubs}' and ColumnName!='#{s}'"
    units = sqlFile.execAndReturnVectorOfString(query).get

    # Obtain categories
    query = "SELECT RowName FROM #{tdws} WHERE ReportName='#{abups}' AND ReportForString='#{ef}' AND TableName='#{eubs}' AND ColumnName='#{s}'"
    categories = sqlFile.execAndReturnVectorOfString(query).get
    # Fill in blanks based on previous non-blank value
    full_categories = []
    (0..categories.size - 1).each do |i|
      full_categories << categories[i]
      next if full_categories[i].size > 0

      full_categories[i] = full_categories[i - 1]
    end
    full_categories = full_categories * fueltypes.uniq.size # Expand to size of fueltypes

    # Obtain subcategories
    query = "SELECT Value FROM #{tdws} WHERE ReportName='#{abups}' AND ReportForString='#{ef}' AND TableName='#{eubs}' AND ColumnName='#{s}'"
    subcategories = sqlFile.execAndReturnVectorOfString(query).get
    subcategories = subcategories * fueltypes.uniq.size # Expand to size of fueltypes

    # Obtain starting position of results
    query = "SELECT MIN(TabularDataIndex) FROM #{tdws} WHERE ReportName='#{abups}' AND ReportForString='#{ef}' AND TableName='#{eubs}' AND ColumnName='#{fueltypes[0]}'"
    starting_index = sqlFile.execAndReturnFirstInt(query).get

    # TabularDataWithStrings table is positional, so we access results by position.
    results = {}
    fueltypes.zip(full_categories, subcategories, units).each_with_index do |(fueltype, category, subcategory, fuel_units), index|
      next if ['District Cooling', 'District Heating'].include? fueltype # Exclude ideal loads results

      query = "SELECT Value FROM #{tdws} WHERE ReportName='#{abups}' AND ReportForString='#{ef}' AND TableName='#{eubs}' AND TabularDataIndex='#{starting_index + index}'"
      val = sqlFile.execAndReturnFirstDouble(query).get
      next if val == 0

      results[[fueltype, category, subcategory, fuel_units]] = val
    end

    # Move EC_adj from Interior Equipment category to a single EC_adj subcategory in Water Systems
    results.keys.each do |k|
      if k[1] == "Interior Equipment" and k[2].end_with? Constants.ObjectNameWaterHeaterAdjustment(nil)
        new_key = [k[0], "Water Systems", "EC_adj", k[3]]
        results[new_key] = 0 if results[new_key].nil?
        results[new_key] += results[k]
        results.delete(k)
      end
    end

    # Disaggregate any crankcase and defrost energy from results
    query = "SELECT SUM(Value)/1000000000 FROM ReportData WHERE ReportDataDictionaryIndex IN (SELECT ReportDataDictionaryIndex FROM ReportDataDictionary WHERE Name='Cooling Coil Crankcase Heater Electric Energy')"
    sql_value = sqlFile.execAndReturnFirstDouble(query)
    if sql_value.is_initialized
      cooling_crankcase = sql_value.get.round(2)
      if cooling_crankcase > 0
        results[["Electricity", "Cooling", "General", "GJ"]] -= cooling_crankcase
        results[["Electricity", "Cooling", "Crankcase", "GJ"]] = cooling_crankcase
      end
    end
    query = "SELECT SUM(Value)/1000000000 FROM ReportData WHERE ReportDataDictionaryIndex IN (SELECT ReportDataDictionaryIndex FROM ReportDataDictionary WHERE Name='Heating Coil Crankcase Heater Electric Energy')"
    sql_value = sqlFile.execAndReturnFirstDouble(query)
    if sql_value.is_initialized
      heating_crankcase = sql_value.get.round(2)
      if heating_crankcase > 0
        results[["Electricity", "Heating", "General", "GJ"]] -= heating_crankcase
        results[["Electricity", "Heating", "Crankcase", "GJ"]] = heating_crankcase
      end
    end
    query = "SELECT SUM(Value)/1000000000 FROM ReportData WHERE ReportDataDictionaryIndex IN (SELECT ReportDataDictionaryIndex FROM ReportDataDictionary WHERE Name='Heating Coil Defrost Electric Energy')"
    sql_value = sqlFile.execAndReturnFirstDouble(query)
    if sql_value.is_initialized
      heating_defrost = sql_value.get.round(2)
      if heating_defrost > 0
        results[["Electricity", "Heating", "General", "GJ"]] -= heating_defrost
        results[["Electricity", "Heating", "Defrost", "GJ"]] = heating_defrost
      end
    end

    # Obtain hot water use
    query = "SELECT SUM(VariableValue) FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex IN (SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE VariableName='Water Use Equipment Hot Water Volume' AND VariableUnits='m3')"
    results[["Volume", "Hot Water", "General", "gal"]] = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, "m^3", "gal").round(2)

    # Obtain HVAC capacities
    query = "SELECT SUM(Value) FROM ComponentSizes WHERE (CompType LIKE 'Coil:Heating:%' OR CompType LIKE 'Boiler:%' OR CompType LIKE 'ZONEHVAC:BASEBOARD:%') AND Description LIKE '%User-Specified%Capacity' AND Description NOT LIKE '%Supplemental%' AND Units='W'"
    results[["Capacity", "Heating", "General", "W"]] = sqlFile.execAndReturnFirstDouble(query).get.round(2)

    query = "SELECT SUM(Value) FROM ComponentSizes WHERE CompType LIKE 'Coil:Cooling:%' AND Description LIKE '%User-Specified%Total%Capacity' AND Units='W'"
    results[["Capacity", "Cooling", "General", "W"]] = sqlFile.execAndReturnFirstDouble(query).get.round(2)

    # Obtain Heating/Cooling loads
    query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnergyMeters' AND ReportForString='Entire Facility' AND TableName='Annual and Peak Values - Other' AND RowName='Heating:EnergyTransfer' AND ColumnName='Annual Value' AND Units='GJ'"
    results[["Load", "Heating", "General", "GJ"]] = sqlFile.execAndReturnFirstDouble(query).get.round(2)

    query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnergyMeters' AND ReportForString='Entire Facility' AND TableName='Annual and Peak Values - Other' AND RowName='Cooling:EnergyTransfer' AND ColumnName='Annual Value' AND Units='GJ'"
    results[["Load", "Cooling", "General", "GJ"]] = sqlFile.execAndReturnFirstDouble(query).get.round(2)

    sqlFile.close

    results[@simulation_runtime_key] = sim_time
    results[@workflow_runtime_key] = workflow_time

    return results
  end

  def _test_simulation(args, this_dir, rundir, expect_error, expect_error_msgs)
    # Uses meta_measure workflow for faster simulations

    # Setup
    _rm_path(rundir)
    Dir.mkdir(rundir)

    workflow_start = Time.now
    model = OpenStudio::Model::Model.new
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # Add measure to workflow
    measures = {}
    measure_subdir = File.absolute_path(File.join(this_dir, "..")).split('/')[-1]
    update_args_hash(measures, measure_subdir, args)

    # Apply measure
    measures_dir = File.join(this_dir, "../../")
    success = apply_measures(measures_dir, measures, runner, model)

    # Report warnings/errors
    File.open(File.join(rundir, 'run.log'), 'w') do |f|
      runner.result.stepWarnings.each do |s|
        f << "Warning: #{s}\n"
      end
      runner.result.stepErrors.each do |s|
        f << "Error: #{s}\n"
      end
    end

    if expect_error
      assert_equal(false, success)

      if expect_error_msgs.nil?
        flunk "No error message defined for #{File.basename(args['hpxml_path'])}."
      else
        run_log = File.readlines(File.join(rundir, "run.log")).map(&:strip)
        expect_error_msgs.each do |error_msg|
          found_error_msg = false
          run_log.each do |run_line|
            next unless run_line.include? error_msg

            found_error_msg = true
            break
          end
          assert(found_error_msg)
        end
      end

      return
    else
      assert_equal(true, success)
    end

    # Add output variables for crankcase and defrost energy
    vars = ["Cooling Coil Crankcase Heater Electric Energy",
            "Heating Coil Crankcase Heater Electric Energy",
            "Heating Coil Defrost Electric Energy"]
    vars.each do |var|
      output_var = OpenStudio::Model::OutputVariable.new(var, model)
      output_var.setReportingFrequency('runperiod')
      output_var.setKeyValue('*')
    end

    # Add output variables for CFIS tests
    @cfis_fan_power_output_var = OpenStudio::Model::OutputVariable.new("#{Constants.ObjectNameMechanicalVentilation} cfis fan power".gsub(" ", "_"), model)
    @cfis_fan_power_output_var.setReportingFrequency('runperiod')
    @cfis_fan_power_output_var.setKeyValue('EMS')

    @cfis_flow_rate_output_var = OpenStudio::Model::OutputVariable.new("#{Constants.ObjectNameMechanicalVentilation} cfis flow rate".gsub(" ", "_"), model)
    @cfis_flow_rate_output_var.setReportingFrequency('runperiod')
    @cfis_flow_rate_output_var.setKeyValue('EMS')

    # Add output variables for hot water volume
    output_var = OpenStudio::Model::OutputVariable.new('Water Use Equipment Hot Water Volume', model)
    output_var.setReportingFrequency('runperiod')
    output_var.setKeyValue('*')

    # Write model to IDF
    forward_translator = OpenStudio::EnergyPlus::ForwardTranslator.new
    model_idf = forward_translator.translateModel(model)
    File.open(File.join(rundir, "in.idf"), 'w') { |f| f << model_idf.to_s }

    # Run EnergyPlus
    ep_path = File.absolute_path(File.join(OpenStudio.getOpenStudioCLI.to_s, '..', '..', 'EnergyPlus', 'energyplus'))
    command = "cd #{rundir} && #{ep_path} -w in.epw in.idf > stdout-energyplus"
    simulation_start = Time.now
    system(command, :err => File::NULL)
    sim_time = (Time.now - simulation_start).round(1)
    workflow_time = (Time.now - workflow_start).round(1)
    puts "Completed #{File.basename(args['hpxml_path'])} simulation in #{sim_time}, workflow in #{workflow_time}s."

    results = _get_results(rundir, sim_time, workflow_time)

    # Verify simulation outputs
    _verify_simulation_outputs(runner, rundir, args['hpxml_path'], results)

    return results
  end

  def _verify_simulation_outputs(runner, rundir, hpxml_path, results)
    # Check that eplusout.err has no lines that include "Blank Schedule Type Limits Name input"
    File.readlines(File.join(rundir, "eplusout.err")).each do |err_line|
      next if err_line.include? 'Schedule:Constant="ALWAYS ON CONTINUOUS", Blank Schedule Type Limits Name input'
      next if err_line.include? 'Schedule:Constant="ALWAYS OFF DISCRETE", Blank Schedule Type Limits Name input'

      assert_equal(err_line.include?("Blank Schedule Type Limits Name input"), false)
    end

    sql_path = File.join(rundir, "eplusout.sql")
    assert(File.exists? sql_path)

    sqlFile = OpenStudio::SqlFile.new(sql_path, false)
    hpxml_doc = REXML::Document.new(File.read(hpxml_path))

    bldg_details = hpxml_doc.elements['/HPXML/Building/BuildingDetails']

    # Conditioned Floor Area
    sum_hvac_load_frac = (bldg_details.elements['sum(Systems/HVAC/HVACPlant/CoolingSystem/FractionCoolLoadServed)'] +
                          bldg_details.elements['sum(Systems/HVAC/HVACPlant/HeatingSystem/FractionHeatLoadServed)'] +
                          bldg_details.elements['sum(Systems/HVAC/HVACPlant/HeatPump/FractionCoolLoadServed)'] +
                          bldg_details.elements['sum(Systems/HVAC/HVACPlant/HeatPump/FractionHeatLoadServed)'])
    if sum_hvac_load_frac > 0 # EnergyPlus will only report conditioned floor area if there is an HVAC system
      hpxml_value = Float(XMLHelper.get_value(bldg_details, 'BuildingSummary/BuildingConstruction/ConditionedFloorArea'))
      query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='InputVerificationandResultsSummary' AND ReportForString='Entire Facility' AND TableName='Zone Summary' AND RowName='Conditioned Total' AND ColumnName='Area' AND Units='m2'"
      sql_value = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, 'm^2', 'ft^2')
      # Subtract duct return plenum conditioned floor area
      query = "SELECT SUM(Value) FROM TabularDataWithStrings WHERE ReportName='InputVerificationandResultsSummary' AND ReportForString='Entire Facility' AND TableName='Zone Summary' AND RowName LIKE '%RET AIR ZONE' AND ColumnName='Area' AND Units='m2'"
      sql_value -= UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, 'm^2', 'ft^2')
      assert_in_epsilon(hpxml_value, sql_value, 0.01)
    end

    enclosure = bldg_details.elements["Enclosure"]
    HPXML.collapse_enclosure(enclosure)

    # Enclosure Roofs
    enclosure.elements.each('Roofs/Roof') do |roof|
      roof_id = roof.elements["SystemIdentifier"].attributes["id"].upcase

      # R-value
      hpxml_value = Float(XMLHelper.get_value(roof, 'Insulation/AssemblyEffectiveRValue'))
      query = "SELECT AVG(Value) FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='Opaque Exterior' AND (RowName='#{roof_id}' OR RowName LIKE '#{roof_id}:%') AND ColumnName='U-Factor with Film' AND Units='W/m2-K'"
      sql_value = 1.0 / UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, 'W/(m^2*K)', 'Btu/(hr*ft^2*F)')
      assert_in_epsilon(hpxml_value, sql_value, 0.1) # TODO: Higher due to outside air film?

      # Net area
      hpxml_value = Float(XMLHelper.get_value(roof, 'Area'))
      enclosure.elements.each('Skylights/Skylight') do |subsurface|
        next if subsurface.elements["AttachedToRoof"].attributes["idref"].upcase != roof_id

        hpxml_value -= Float(XMLHelper.get_value(subsurface, 'Area'))
      end
      query = "SELECT SUM(Value) FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='Opaque Exterior' AND (RowName='#{roof_id}' OR RowName LIKE '#{roof_id}:%') AND ColumnName='Net Area' AND Units='m2'"
      sql_value = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, 'm^2', 'ft^2')
      assert_in_epsilon(hpxml_value, sql_value, 0.01)

      # Solar absorptance
      hpxml_value = Float(XMLHelper.get_value(roof, 'SolarAbsorptance'))
      query = "SELECT AVG(Value) FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='Opaque Exterior' AND (RowName='#{roof_id}' OR RowName LIKE '#{roof_id}:%') AND ColumnName='Reflectance'"
      sql_value = 1.0 - sqlFile.execAndReturnFirstDouble(query).get
      assert_in_epsilon(hpxml_value, sql_value, 0.01)

      # Tilt
      hpxml_value = UnitConversions.convert(Math.atan(Float(XMLHelper.get_value(roof, "Pitch")) / 12.0), "rad", "deg")
      query = "SELECT AVG(Value) FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='Opaque Exterior' AND (RowName='#{roof_id}' OR RowName LIKE '#{roof_id}:%') AND ColumnName='Tilt' AND Units='deg'"
      sql_value = sqlFile.execAndReturnFirstDouble(query).get
      assert_in_epsilon(hpxml_value, sql_value, 0.01)

      # Azimuth
      if XMLHelper.has_element(roof, 'Azimuth') and Float(XMLHelper.get_value(roof, "Pitch")) > 0
        hpxml_value = Float(XMLHelper.get_value(roof, 'Azimuth'))
        query = "SELECT AVG(Value) FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='Opaque Exterior' AND (RowName='#{roof_id}' OR RowName LIKE '#{roof_id}:%') AND ColumnName='Azimuth' AND Units='deg'"
        sql_value = sqlFile.execAndReturnFirstDouble(query).get
        assert_in_epsilon(hpxml_value, sql_value, 0.01)
      end
    end

    # Enclosure Foundations
    # Ensure Kiva instances have perimeter fraction of 1.0 as we explicitly define them to end up this way.
    num_kiva_instances = 0
    File.readlines(File.join(rundir, "eplusout.eio")).each do |eio_line|
      if eio_line.downcase.start_with? "foundation kiva"
        kiva_perim_frac = Float(eio_line.split(",")[5])
        assert_equal(1.0, kiva_perim_frac)

        num_kiva_instances += 1
      end
    end

    num_expected_kiva_instances = { 'base-foundation-ambient.xml' => 0,               # no foundation in contact w/ ground
                                    'base-foundation-ambient-autosize.xml' => 0,      # no foundation in contact w/ ground
                                    'base-foundation-multiple.xml' => 2,              # additional instance for 2nd foundation type
                                    'base-enclosure-2stories-garage.xml' => 2,        # additional instance for garage
                                    'base-enclosure-garage.xml' => 2,                 # additional instance for garage
                                    'base-enclosure-garage-autosize.xml' => 2,        # additional instance for garage
                                    'base-enclosure-adiabatic-surfaces.xml' => 0,     # no foundation in contact w/ ground
                                    'base-foundation-walkout-basement.xml' => 4,      # 3 foundation walls plus a no-wall exposed perimeter
                                    'base-foundation-complex.xml' => 10 }

    if not num_expected_kiva_instances[File.basename(hpxml_path)].nil?
      assert_equal(num_expected_kiva_instances[File.basename(hpxml_path)], num_kiva_instances)
    else
      assert_equal(1, num_kiva_instances)
    end

    # Enclosure Foundation Slabs
    num_slabs = enclosure.elements['count(Slabs/Slab)']
    if num_slabs <= 1 and num_kiva_instances <= 1 # The slab surfaces may be combined in these situations, so skip tests
      enclosure.elements.each('Slabs/Slab') do |slab|
        slab_id = slab.elements["SystemIdentifier"].attributes["id"].upcase

        # Exposed Area
        hpxml_value = Float(XMLHelper.get_value(slab, 'Area'))
        query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='Opaque Exterior' AND RowName='#{slab_id}' AND ColumnName='Gross Area' AND Units='m2'"
        sql_value = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, 'm^2', 'ft^2')
        assert_in_epsilon(hpxml_value, sql_value, 0.01)

        # Tilt
        query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='Opaque Exterior' AND RowName='#{slab_id}' AND ColumnName='Tilt' AND Units='deg'"
        sql_value = sqlFile.execAndReturnFirstDouble(query).get
        assert_in_epsilon(180.0, sql_value, 0.01)
      end
    end

    # Enclosure Walls/RimJoists/FoundationWalls
    enclosure.elements.each('Walls/Wall[ExteriorAdjacentTo="outside"] | RimJoists/RimJoist[ExteriorAdjacentTo="outside"] | FoundationWalls/FoundationWall[ExteriorAdjacentTo="ground"]') do |wall|
      wall_id = wall.elements["SystemIdentifier"].attributes["id"].upcase

      # R-value
      if XMLHelper.has_element(wall, 'Insulation/AssemblyEffectiveRValue') and not hpxml_path.include? "base-foundation-unconditioned-basement-assembly-r.xml" # This file uses Foundation:Kiva for insulation, so skip it
        hpxml_value = Float(XMLHelper.get_value(wall, 'Insulation/AssemblyEffectiveRValue'))
        query = "SELECT AVG(Value) FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='Opaque Exterior' AND (RowName='#{wall_id}' OR RowName LIKE '#{wall_id}:%') AND ColumnName='U-Factor with Film' AND Units='W/m2-K'"
        sql_value = 1.0 / UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, 'W/(m^2*K)', 'Btu/(hr*ft^2*F)')
        assert_in_epsilon(hpxml_value, sql_value, 0.03)
      end

      # Net area
      hpxml_value = Float(XMLHelper.get_value(wall, 'Area'))
      enclosure.elements.each('Windows/Window | Doors/Door') do |subsurface|
        next if subsurface.elements["AttachedToWall"].attributes["idref"].upcase != wall_id

        hpxml_value -= Float(XMLHelper.get_value(subsurface, 'Area'))
      end
      if XMLHelper.get_value(wall, "ExteriorAdjacentTo") == "ground"
        # Calculate total length of walls
        wall_total_length = 0
        enclosure.elements.each('FoundationWalls/FoundationWall[ExteriorAdjacentTo="ground"]') do |fwall|
          next unless XMLHelper.get_value(wall, "InteriorAdjacentTo") == XMLHelper.get_value(fwall, "InteriorAdjacentTo")

          wall_total_length += Float(XMLHelper.get_value(fwall, "Area")) / Float(XMLHelper.get_value(fwall, "Height"))
        end

        # Calculate total slab exposed perimeter
        slab_exposed_length = 0
        enclosure.elements.each('Slabs/Slab') do |slab|
          next unless XMLHelper.get_value(wall, "InteriorAdjacentTo") == XMLHelper.get_value(slab, "InteriorAdjacentTo")

          slab_exposed_length += Float(XMLHelper.get_value(slab, "ExposedPerimeter"))
        end

        # Calculate exposed foundation wall area
        if slab_exposed_length < wall_total_length
          hpxml_value *= (slab_exposed_length / wall_total_length)
        end
      end
      query = "SELECT SUM(Value) FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='Opaque Exterior' AND (RowName='#{wall_id}' OR RowName LIKE '#{wall_id}:%' OR RowName LIKE '#{wall_id} %') AND ColumnName='Net Area' AND Units='m2'"
      sql_value = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, 'm^2', 'ft^2')
      assert_in_epsilon(hpxml_value, sql_value, 0.01)

      # Solar absorptance
      if XMLHelper.has_element(wall, 'SolarAbsorptance')
        hpxml_value = Float(XMLHelper.get_value(wall, 'SolarAbsorptance'))
        query = "SELECT AVG(Value) FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='Opaque Exterior' AND (RowName='#{wall_id}' OR RowName LIKE '#{wall_id}:%') AND ColumnName='Reflectance'"
        sql_value = 1.0 - sqlFile.execAndReturnFirstDouble(query).get
        assert_in_epsilon(hpxml_value, sql_value, 0.01)
      end

      # Tilt
      query = "SELECT AVG(Value) FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='Opaque Exterior' AND (RowName='#{wall_id}' OR RowName LIKE '#{wall_id}:%') AND ColumnName='Tilt' AND Units='deg'"
      sql_value = sqlFile.execAndReturnFirstDouble(query).get
      assert_in_epsilon(90.0, sql_value, 0.01)

      # Azimuth
      if XMLHelper.has_element(wall, 'Azimuth')
        hpxml_value = Float(XMLHelper.get_value(wall, 'Azimuth'))
        query = "SELECT AVG(Value) FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='Opaque Exterior' AND (RowName='#{wall_id}' OR RowName LIKE '#{wall_id}:%') AND ColumnName='Azimuth' AND Units='deg'"
        sql_value = sqlFile.execAndReturnFirstDouble(query).get
        assert_in_epsilon(hpxml_value, sql_value, 0.01)
      end
    end

    # TODO: Enclosure FrameFloors

    # Enclosure Windows/Skylights
    enclosure.elements.each('Windows/Window | Skylights/Skylight') do |subsurface|
      subsurface_id = subsurface.elements["SystemIdentifier"].attributes["id"].upcase

      # Area
      hpxml_value = Float(XMLHelper.get_value(subsurface, 'Area'))
      query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='Exterior Fenestration' AND RowName='#{subsurface_id}' AND ColumnName='Area of Multiplied Openings' AND Units='m2'"
      sql_value = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, 'm^2', 'ft^2')
      assert_in_epsilon(hpxml_value, sql_value, 0.01)

      # U-Factor
      hpxml_value = Float(XMLHelper.get_value(subsurface, 'UFactor'))
      query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='Exterior Fenestration' AND RowName='#{subsurface_id}' AND ColumnName='Glass U-Factor' AND Units='W/m2-K'"
      sql_value = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, 'W/(m^2*K)', 'Btu/(hr*ft^2*F)')
      assert_in_epsilon(hpxml_value, sql_value, 0.01)

      # SHGC
      # TODO: Affected by interior shading

      # Azimuth
      hpxml_value = Float(XMLHelper.get_value(subsurface, 'Azimuth'))
      query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='Exterior Fenestration' AND RowName='#{subsurface_id}' AND ColumnName='Azimuth' AND Units='deg'"
      sql_value = sqlFile.execAndReturnFirstDouble(query).get
      assert_in_epsilon(hpxml_value, sql_value, 0.01)

      # Tilt
      if XMLHelper.has_element(subsurface, "AttachedToWall")
        query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='Exterior Fenestration' AND RowName='#{subsurface_id}' AND ColumnName='Tilt' AND Units='deg'"
        sql_value = sqlFile.execAndReturnFirstDouble(query).get
        assert_in_epsilon(90.0, sql_value, 0.01)
      elsif XMLHelper.has_element(subsurface, "AttachedToRoof")
        hpxml_value = nil
        enclosure.elements.each('Roofs/Roof') do |roof|
          next if roof.elements["SystemIdentifier"].attributes["id"] != subsurface.elements["AttachedToRoof"].attributes["idref"]

          hpxml_value = UnitConversions.convert(Math.atan(Float(XMLHelper.get_value(roof, "Pitch")) / 12.0), "rad", "deg")
        end
        query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='Exterior Fenestration' AND RowName='#{subsurface_id}' AND ColumnName='Tilt' AND Units='deg'"
        sql_value = sqlFile.execAndReturnFirstDouble(query).get
        assert_in_epsilon(hpxml_value, sql_value, 0.01)
      else
        flunk "Subsurface '#{subsurface_id}' should have either AttachedToWall or AttachedToRoof element."
      end
    end

    # Enclosure Doors
    enclosure.elements.each('Doors/Door') do |door|
      door_id = door.elements["SystemIdentifier"].attributes["id"].upcase

      # Area
      door_area = XMLHelper.get_value(door, 'Area')
      if not door_area.nil?
        hpxml_value = Float(door_area)
        query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='Exterior Door' AND RowName='#{door_id}' AND ColumnName='Gross Area' AND Units='m2'"
        sql_value = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, 'm^2', 'ft^2')
        assert_in_epsilon(hpxml_value, sql_value, 0.01)
      end

      # R-Value
      door_rvalue = XMLHelper.get_value(door, 'RValue')
      if not door_rvalue.nil?
        hpxml_value = Float(door_rvalue)
        query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='Exterior Door' AND RowName='#{door_id}' AND ColumnName='U-Factor with Film' AND Units='W/m2-K'"
        sql_value = 1.0 / UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, 'W/(m^2*K)', 'Btu/(hr*ft^2*F)')
        assert_in_epsilon(hpxml_value, sql_value, 0.02)
      end
    end

    # HVAC Heating Systems
    num_htg_sys = bldg_details.elements['count(Systems/HVAC/HVACPlant/HeatingSystem)']
    bldg_details.elements.each('Systems/HVAC/HVACPlant/HeatingSystem') do |htg_sys|
      htg_sys_type = XMLHelper.get_child_name(htg_sys, 'HeatingSystemType')
      htg_sys_fuel = to_beopt_fuel(XMLHelper.get_value(htg_sys, 'HeatingSystemFuel'))
      htg_load_frac = Float(XMLHelper.get_value(htg_sys, "FractionHeatLoadServed"))

      if htg_load_frac > 0

        # Electric Auxiliary Energy
        # For now, skip if multiple equipment
        if num_htg_sys == 1 and ['Furnace', 'Boiler', 'WallFurnace', 'Stove'].include? htg_sys_type and htg_sys_fuel != Constants.FuelTypeElectric
          if XMLHelper.has_element(htg_sys, 'ElectricAuxiliaryEnergy')
            hpxml_value = Float(XMLHelper.get_value(htg_sys, 'ElectricAuxiliaryEnergy')) / 2.08
          else
            furnace_capacity_kbtuh = nil
            if htg_sys_type == 'Furnace'
              query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EquipmentSummary' AND ReportForString='Entire Facility' AND TableName='Heating Coils' AND RowName LIKE '%#{Constants.ObjectNameFurnace.upcase}%' AND ColumnName='Nominal Total Capacity' AND Units='W'"
              furnace_capacity_kbtuh = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, 'W', 'kBtu/hr')
            end
            frac_load_served = Float(XMLHelper.get_value(htg_sys, "FractionHeatLoadServed"))
            hpxml_value = HVAC.get_default_eae(htg_sys_type, htg_sys_fuel, frac_load_served, furnace_capacity_kbtuh) / 2.08
          end

          if htg_sys_type == 'Boiler'
            query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EquipmentSummary' AND ReportForString='Entire Facility' AND TableName='Pumps' AND RowName LIKE '%#{Constants.ObjectNameBoiler.upcase}%' AND ColumnName='Electric Power' AND Units='W'"
            sql_value = sqlFile.execAndReturnFirstDouble(query).get
          elsif htg_sys_type == 'Furnace'

            # Ratio fan power based on heating airflow rate divided by fan airflow rate since the
            # fan is sized based on cooling.
            query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EquipmentSummary' AND ReportForString='Entire Facility' AND TableName='Fans' AND RowName LIKE '%#{Constants.ObjectNameFurnace.upcase}%' AND ColumnName='Rated Electric Power' AND Units='W'"
            query_fan_airflow = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='ComponentSizingSummary' AND ReportForString='Entire Facility' AND TableName='Fan:OnOff' AND RowName LIKE '%#{Constants.ObjectNameFurnace.upcase}%' AND ColumnName='User-Specified Maximum Flow Rate' AND Units='m3/s'"
            query_htg_airflow = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='ComponentSizingSummary' AND ReportForString='Entire Facility' AND TableName='AirLoopHVAC:UnitarySystem' AND RowName LIKE '%#{Constants.ObjectNameFurnace.upcase}%' AND ColumnName='User-Specified Heating Supply Air Flow Rate' AND Units='m3/s'"
            sql_value = sqlFile.execAndReturnFirstDouble(query).get
            sql_value_fan_airflow = sqlFile.execAndReturnFirstDouble(query_fan_airflow).get
            sql_value_htg_airflow = sqlFile.execAndReturnFirstDouble(query_htg_airflow).get
            sql_value *= sql_value_htg_airflow / sql_value_fan_airflow
          elsif htg_sys_type == 'Stove' or htg_sys_type == 'WallFurnace'
            query = "SELECT AVG(Value) FROM TabularDataWithStrings WHERE ReportName='EquipmentSummary' AND ReportForString='Entire Facility' AND TableName='Fans' AND RowName LIKE '%#{Constants.ObjectNameUnitHeater.upcase}%' AND ColumnName='Rated Electric Power' AND Units='W'"
            sql_value = sqlFile.execAndReturnFirstDouble(query).get
          else
            flunk "Unexpected heating system type '#{htg_sys_type}'."
          end
          assert_in_epsilon(hpxml_value, sql_value, 0.01)
        end

      end
    end

    # HVAC Capacities
    htg_cap = nil
    clg_cap = nil
    has_multispeed_dx_heating_coil = false # FIXME: Remove this when https://github.com/NREL/EnergyPlus/issues/7381 is fixed
    has_gshp_coil = false # FIXME: Remove this when https://github.com/NREL/EnergyPlus/issues/7381 is fixed
    bldg_details.elements.each('Systems/HVAC/HVACPlant/HeatingSystem') do |htg_sys|
      htg_sys_cap = Float(XMLHelper.get_value(htg_sys, "HeatingCapacity"))
      if htg_sys_cap > 0
        htg_cap = 0 if htg_cap.nil?
        htg_cap += htg_sys_cap
      end
    end
    bldg_details.elements.each('Systems/HVAC/HVACPlant/CoolingSystem') do |clg_sys|
      clg_sys_cap = Float(XMLHelper.get_value(clg_sys, "CoolingCapacity"))
      if clg_sys_cap > 0
        clg_cap = 0 if clg_cap.nil?
        clg_cap += clg_sys_cap
      end
    end
    bldg_details.elements.each('Systems/HVAC/HVACPlant/HeatPump') do |hp|
      hp_type = XMLHelper.get_value(hp, "HeatPumpType")
      hp_cap_clg = Float(XMLHelper.get_value(hp, "CoolingCapacity"))
      hp_cap_htg = Float(XMLHelper.get_value(hp, "HeatingCapacity"))
      if hp_type == "mini-split"
        hp_cap_clg *= 1.20 # TODO: Generalize this
        hp_cap_htg *= 1.20 # TODO: Generalize this
      end
      supp_hp_cap = XMLHelper.get_value(hp, "BackupHeatingCapacity").to_f
      if hp_cap_clg > 0
        clg_cap = 0 if clg_cap.nil?
        clg_cap += hp_cap_clg
      end
      if hp_cap_htg > 0
        htg_cap = 0 if htg_cap.nil?
        htg_cap += hp_cap_htg
      end
      if supp_hp_cap > 0
        htg_cap = 0 if htg_cap.nil?
        htg_cap += supp_hp_cap
      end
      if XMLHelper.get_value(hp, "AnnualCoolingEfficiency[Units='SEER']/Value").to_f > 15
        has_multispeed_dx_heating_coil = true
      end
      if hp_type == "ground-to-air"
        has_gshp_coil = true
      end
    end
    if not clg_cap.nil?
      sql_value = UnitConversions.convert(results[["Capacity", "Cooling", "General", "W"]], 'W', 'Btu/hr')
      if clg_cap == 0
        assert_operator(sql_value, :<, 1)
      elsif clg_cap > 0
        assert_in_epsilon(clg_cap, sql_value, 0.01)
      else # autosized
        assert_operator(sql_value, :>, 1)
      end
    end
    if not htg_cap.nil? and not (has_multispeed_dx_heating_coil or has_gshp_coil)
      sql_value = UnitConversions.convert(results[["Capacity", "Heating", "General", "W"]], 'W', 'Btu/hr')
      if htg_cap == 0
        assert_operator(sql_value, :<, 1)
      elsif htg_cap > 0
        assert_in_epsilon(htg_cap, sql_value, 0.01)
      else # autosized
        assert_operator(sql_value, :>, 1)
      end
    end

    # HVAC Load Fractions
    htg_load_frac = 0.0
    clg_load_frac = 0.0
    bldg_details.elements.each('Systems/HVAC/HVACPlant/HeatingSystem') do |htg_sys|
      htg_load_frac += Float(XMLHelper.get_value(htg_sys, "FractionHeatLoadServed"))
    end
    bldg_details.elements.each('Systems/HVAC/HVACPlant/CoolingSystem') do |clg_sys|
      clg_load_frac += Float(XMLHelper.get_value(clg_sys, "FractionCoolLoadServed"))
    end
    bldg_details.elements.each('Systems/HVAC/HVACPlant/HeatPump') do |hp|
      htg_load_frac += Float(XMLHelper.get_value(hp, "FractionHeatLoadServed"))
      clg_load_frac += Float(XMLHelper.get_value(hp, "FractionCoolLoadServed"))
    end
    if htg_load_frac == 0
      found_htg_energy = false
      results.keys.each do |k|
        next unless k[1] == 'Heating' and k[0] != 'Capacity' and k[0] != "Load"

        found_htg_energy = true
      end
      assert_equal(false, found_htg_energy)
    end
    if clg_load_frac == 0
      found_clg_energy = false
      results.keys.each do |k|
        next unless k[1] == 'Cooling' and k[0] != 'Capacity' and k[0] != "Load"

        found_clg_energy = true
      end
      assert_equal(false, found_clg_energy)
    end

    # Water Heater
    wh = bldg_details.elements["Systems/WaterHeating/WaterHeatingSystem"]
    if not wh.nil?
      # EC_adj, compare calculated value to value obtained from simulation results
      calculated_ec_adj = nil
      runner.result.stepInfo.each do |s|
        next unless s.start_with? "EC_adj="

        calculated_ec_adj = Float(s.gsub("EC_adj=", ""))
      end

      # Obtain water heating energy consumption and adjusted water heating energy consumption
      water_heater_energy = 0.0
      water_heater_adj_energy = 0.0
      results.keys.each do |k|
        next unless k[1] == "Water Systems" and k[3] == "GJ"

        if k[2] == "EC_adj"
          water_heater_adj_energy += results[k]
        else
          water_heater_energy += results[k]
        end
      end

      # Add any combi water heating energy use
      query = "SELECT SUM(ABS(VariableValue)/1000000000) FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex IN (SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE VariableType='Sum' AND VariableName='#{OutputVars.WaterHeatingCombiBoilerHeatExchanger.values[0][0]}' AND ReportingFrequency='Run Period' AND VariableUnits='J')"
      combi_hx_load = sqlFile.execAndReturnFirstDouble(query).get.round(2)
      query = "SELECT SUM(ABS(VariableValue)/1000000000) FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex IN (SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE VariableType='Sum' AND VariableName='#{OutputVars.WaterHeatingCombiBoiler.values[0][0]}' AND ReportingFrequency='Run Period' AND VariableUnits='J')"
      combi_htg_load = sqlFile.execAndReturnFirstDouble(query).get.round(2)
      if combi_htg_load > 0 and combi_hx_load > 0
        results.keys.each do |k|
          next unless k[0] != "Load" and k[1] == "Heating" and k[3] == "GJ"

          water_heater_energy += (results[k] * combi_hx_load / combi_htg_load)
        end
      end

      simulated_ec_adj = (water_heater_energy + water_heater_adj_energy) / water_heater_energy
      assert_in_epsilon(calculated_ec_adj, simulated_ec_adj, 0.02)
    end

    # Mechanical Ventilation
    mv = bldg_details.elements["Systems/MechanicalVentilation/VentilationFans/VentilationFan[UsedForWholeBuildingVentilation='true']"]
    if not mv.nil?
      mv_energy = 0.0
      results.keys.each do |k|
        next if k[0] != 'Electricity' or k[1] != 'Interior Equipment' or not k[2].start_with? Constants.ObjectNameMechanicalVentilation

        mv_energy = results[k]
      end
      if XMLHelper.has_element(mv, "AttachedToHVACDistributionSystem")
        # CFIS, check for positive mech vent energy that is less than the energy if it had run 24/7
        fan_w = Float(XMLHelper.get_value(mv, "FanPower"))
        hrs_per_day = Float(XMLHelper.get_value(mv, "HoursInOperation"))
        fan_kwhs = UnitConversions.convert(fan_w * hrs_per_day * 365.0, 'Wh', 'GJ')
        if fan_kwhs > 0
          assert_operator(mv_energy, :>, 0)
          assert_operator(mv_energy, :<, fan_kwhs)
        else
          assert_equal(mv_energy, 0.0)
        end
      else
        # Supply, exhaust, ERV, HRV, etc., check for appropriate mech vent energy
        fan_w = Float(XMLHelper.get_value(mv, "FanPower"))
        hrs_per_day = Float(XMLHelper.get_value(mv, "HoursInOperation"))
        fan_kwhs = UnitConversions.convert(fan_w * hrs_per_day * 365.0, 'Wh', 'GJ')
        assert_in_delta(mv_energy, fan_kwhs, 0.1)
      end

      # CFIS
      if XMLHelper.get_value(mv, "FanType") == "central fan integrated supply"
        # Fan power
        hpxml_value = Float(XMLHelper.get_value(mv, "FanPower"))
        query = "SELECT Value FROM ReportData WHERE ReportDataDictionaryIndex IN (SELECT ReportDataDictionaryIndex FROM ReportDataDictionary WHERE Name= '#{@cfis_fan_power_output_var.variableName}')"
        sql_value = sqlFile.execAndReturnFirstDouble(query).get
        assert_in_delta(hpxml_value, sql_value, 0.01)

        # Flow rate
        hpxml_value = Float(XMLHelper.get_value(mv, "TestedFlowRate")) * Float(XMLHelper.get_value(mv, "HoursInOperation")) / 24.0
        query = "SELECT Value FROM ReportData WHERE ReportDataDictionaryIndex IN (SELECT ReportDataDictionaryIndex FROM ReportDataDictionary WHERE Name= '#{@cfis_flow_rate_output_var.variableName}')"
        sql_value = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, "m^3/s", "cfm")
        assert_in_delta(hpxml_value, sql_value, 0.01)
      end

    end

    # Clothes Washer
    cw = bldg_details.elements["Appliances/ClothesWasher"]
    if not cw.nil? and not wh.nil?
      # Location
      location = XMLHelper.get_value(cw, "Location")
      hpxml_value = { nil => Constants.SpaceTypeLiving,
                      'living space' => Constants.SpaceTypeLiving,
                      'basement - conditioned' => Constants.SpaceTypeLiving,
                      'basement - unconditioned' => Constants.SpaceTypeUnconditionedBasement,
                      'garage' => Constants.SpaceTypeGarage }[location].upcase
      query = "SELECT Value FROM TabularDataWithStrings WHERE TableName='ElectricEquipment Internal Gains Nominal' AND ColumnName='Zone Name' AND RowName=(SELECT RowName FROM TabularDataWithStrings WHERE TableName='ElectricEquipment Internal Gains Nominal' AND ColumnName='Name' AND Value='#{Constants.ObjectNameClothesWasher.upcase}')"
      sql_value = sqlFile.execAndReturnFirstString(query).get
      assert_equal(hpxml_value, sql_value)
    end

    # Clothes Dryer
    cd = bldg_details.elements["Appliances/ClothesDryer"]
    if not cd.nil? and not wh.nil?
      # Location
      location = XMLHelper.get_value(cd, "Location")
      hpxml_value = { nil => Constants.SpaceTypeLiving,
                      'living space' => Constants.SpaceTypeLiving,
                      'basement - conditioned' => Constants.SpaceTypeLiving,
                      'basement - unconditioned' => Constants.SpaceTypeUnconditionedBasement,
                      'garage' => Constants.SpaceTypeGarage }[location].upcase
      query = "SELECT Value FROM TabularDataWithStrings WHERE TableName='ElectricEquipment Internal Gains Nominal' AND ColumnName='Zone Name' AND RowName=(SELECT RowName FROM TabularDataWithStrings WHERE TableName='ElectricEquipment Internal Gains Nominal' AND ColumnName='Name' AND Value='#{Constants.ObjectNameClothesDryer.upcase}')"
      sql_value = sqlFile.execAndReturnFirstString(query).get
      assert_equal(hpxml_value, sql_value)
    end

    # Refrigerator
    refr = bldg_details.elements["Appliances/Refrigerator"]
    if not refr.nil?
      # Location
      location = XMLHelper.get_value(refr, "Location")
      hpxml_value = { nil => Constants.SpaceTypeLiving,
                      'living space' => Constants.SpaceTypeLiving,
                      'basement - conditioned' => Constants.SpaceTypeLiving,
                      'basement - unconditioned' => Constants.SpaceTypeUnconditionedBasement,
                      'garage' => Constants.SpaceTypeGarage }[location].upcase
      query = "SELECT Value FROM TabularDataWithStrings WHERE TableName='ElectricEquipment Internal Gains Nominal' AND ColumnName='Zone Name' AND RowName=(SELECT RowName FROM TabularDataWithStrings WHERE TableName='ElectricEquipment Internal Gains Nominal' AND ColumnName='Name' AND Value='#{Constants.ObjectNameRefrigerator.upcase}')"
      sql_value = sqlFile.execAndReturnFirstString(query).get
      assert_equal(hpxml_value, sql_value)
    end

    # Lighting
    found_ltg_energy = false
    results.keys.each do |k|
      next unless k[1].include? 'Lighting'

      found_ltg_energy = true
    end
    assert_equal(bldg_details.elements["Lighting"].nil?, !found_ltg_energy)

    # Natural Gas check
    ng_htg = results.fetch(["Natural Gas", "Heating", "General", "GJ"], 0) + results.fetch(["Natural Gas", "Heating", "Other", "GJ"], 0)
    ng_dhw = results.fetch(["Natural Gas", "Water Systems", "General", "GJ"], 0)
    ng_cd = results.fetch(["Natural Gas", "Interior Equipment", "clothes dryer", "GJ"], 0)
    ng_cr = results.fetch(["Natural Gas", "Interior Equipment", "cooking range", "GJ"], 0)
    if not bldg_details.elements["Systems/HVAC/HVACPlant/HeatingSystem[HeatingSystemFuel='natural gas']"].nil? and not hpxml_path.include? "location-miami"
      assert_operator(ng_htg, :>, 0)
    else
      assert_equal(ng_htg, 0)
    end
    if not bldg_details.elements["Systems/WaterHeating/WaterHeatingSystem[FuelType='natural gas']"].nil?
      assert_operator(ng_dhw, :>, 0)
    else
      assert_equal(ng_dhw, 0)
    end
    if not bldg_details.elements["Appliances/ClothesDryer[FuelType='natural gas']"].nil?
      assert_operator(ng_cd, :>, 0)
    else
      assert_equal(ng_cd, 0)
    end
    if not bldg_details.elements["Appliances/CookingRange[FuelType='natural gas']"].nil?
      assert_operator(ng_cr, :>, 0)
    else
      assert_equal(ng_cr, 0)
    end

    # Additional Fuel check
    af_htg = results.fetch(["Additional Fuel", "Heating", "General", "GJ"], 0) + results.fetch(["Additional Fuel", "Heating", "Other", "GJ"], 0)
    af_dhw = results.fetch(["Additional Fuel", "Water Systems", "General", "GJ"], 0)
    af_cd = results.fetch(["Additional Fuel", "Interior Equipment", "clothes dryer", "GJ"], 0)
    af_cr = results.fetch(["Additional Fuel", "Interior Equipment", "cooking range", "GJ"], 0)
    if not bldg_details.elements["Systems/HVAC/HVACPlant/HeatingSystem[HeatingSystemFuel='fuel oil' or HeatingSystemFuel='propane' or HeatingSystemFuel='wood']"].nil? and not hpxml_path.include? "location-miami"
      assert_operator(af_htg, :>, 0)
    else
      assert_equal(af_htg, 0)
    end
    if not bldg_details.elements["Systems/WaterHeating/WaterHeatingSystem[FuelType='fuel oil' or FuelType='propane' or FuelType='wood']"].nil?
      assert_operator(af_dhw, :>, 0)
    else
      assert_equal(af_dhw, 0)
    end
    if not bldg_details.elements["Appliances/ClothesDryer[FuelType='fuel oil' or FuelType='propane' or FuelType='wood']"].nil?
      assert_operator(af_cd, :>, 0)
    else
      assert_equal(af_cd, 0)
    end
    if not bldg_details.elements["Appliances/CookingRange[FuelType='fuel oil' or FuelType='propane' or FuelType='wood']"].nil?
      assert_operator(af_cr, :>, 0)
    else
      assert_equal(af_cr, 0)
    end

    sqlFile.close
  end

  def _write_summary_results(results_dir, results)
    Dir.mkdir(results_dir)
    csv_out = File.join(results_dir, 'results.csv')

    # Get all keys across simulations for output columns
    output_keys = []
    results.each do |xml, xml_results|
      xml_results.keys.each do |key|
        next if not key.is_a? Array
        next if output_keys.include? key

        output_keys << key
      end
    end
    output_keys.sort!

    # Append runtimes at the end
    output_keys << @simulation_runtime_key
    output_keys << @workflow_runtime_key

    column_headers = ['HPXML']
    output_keys.each do |key|
      if key.is_a? Array
        column_headers << "#{key[0]}: #{key[1]}: #{key[2]} [#{key[3]}]"
      else
        column_headers << key
      end
    end

    require 'csv'
    CSV.open(csv_out, 'w') do |csv|
      csv << column_headers
      results.sort.each do |xml, xml_results|
        csv_row = [xml]
        output_keys.each do |key|
          if xml_results[key].nil?
            csv_row << 0
          else
            csv_row << xml_results[key]
          end
        end
        csv << csv_row
      end
    end

    puts "Wrote results to #{csv_out}."
  end

  def _test_schema_validation(this_dir, xml)
    # TODO: Remove this when schema validation is included with CLI calls
    schemas_dir = File.absolute_path(File.join(this_dir, "..", "hpxml_schemas"))
    hpxml_doc = REXML::Document.new(File.read(xml))
    errors = XMLHelper.validate(hpxml_doc.to_s, File.join(schemas_dir, "HPXML.xsd"), nil)
    if errors.size > 0
      puts "#{xml}: #{errors.to_s}"
    end
    assert_equal(0, errors.size)
  end

  def _test_hrv_erv_inputs(test_dir, all_results)
    # Compare HRV and ERV results that use different inputs
    ["hrv", "erv"].each do |mv_type|
      puts "#{mv_type.upcase} test results:"

      base_xml = "#{test_dir}/base-mechvent-#{mv_type}.xml"
      results_base = all_results[base_xml]
      next if results_base.nil?

      Dir["#{test_dir}/base-mechvent-#{mv_type}-*.xml"].sort.each do |xml|
        results = all_results[xml]
        next if results.nil?

        # Compare results
        results_base.keys.each do |k|
          next if [@simulation_runtime_key, @workflow_runtime_key].include? k

          result_base = results_base[k].to_f
          result = results[k].to_f
          next if result_base == 0.0 and result == 0.0

          _display_result_epsilon(xml, result_base, result, k)
          assert_in_epsilon(result_base, result, 0.01)
        end
      end
    end
  end

  def _test_heating_cooling_loads(xmls, hvac_base_dir, all_results)
    puts "Heating/Cooling Loads test results:"

    base_xml = "#{hvac_base_dir}/base-hvac-ideal-air-base.xml"
    results_base = all_results[File.absolute_path(base_xml)]
    return if results_base.nil?

    xmls.sort.each do |xml|
      next if not xml.include? hvac_base_dir

      xml_compare = File.absolute_path(xml)
      results_compare = all_results[xml_compare]
      next if results_compare.nil?

      # Compare results
      results_compare.keys.each do |k|
        next if not ["Heating", "Cooling"].include? k[1]
        next if not ["Load"].include? k[0]

        result_base = results_base[k].to_f
        result_compare = results_compare[k].to_f
        next if result_base <= 0.1 or result_compare <= 0.1

        _display_result_delta(xml, result_base, result_compare, k)
        assert_in_delta(result_base, result_compare, 0.25)
      end
    end
  end

  def _test_multiple_hvac(xmls, hvac_multiple_dir, hvac_base_dir, all_results)
    # Compare end use results for three of an HVAC system to results for one HVAC system.
    puts "Multiple HVAC test results:"
    xmls.sort.each do |xml|
      next if not xml.include? hvac_multiple_dir

      xml_x3 = File.absolute_path(xml)
      xml_x1 = File.absolute_path(xml.gsub(hvac_multiple_dir, hvac_base_dir).gsub("-x3.xml", "-base.xml"))

      results_x3 = all_results[xml_x3]
      results_x1 = all_results[xml_x1]
      next if results_x1.nil?

      # Compare results
      results_x3.keys.each do |k|
        next unless ["Heating", "Cooling"].include? k[1]
        next unless ["General"].include? k[2] # Exclude crankcase/defrost
        next if k[0] == "Load"

        result_x1 = results_x1[k].to_f
        result_x3 = results_x3[k].to_f
        next if result_x1 == 0.0 and result_x3 == 0.0

        _display_result_epsilon(xml, result_x1, result_x3, k)
        if result_x1 > 1.0
          assert_in_epsilon(result_x1, result_x3, 0.12)
        else
          assert_in_delta(result_x1, result_x3, 0.1)
        end
      end
    end
  end

  def _test_multiple_water_heaters(xmls, water_heating_multiple_dir, all_results)
    # Compare end use results for three tankless water heaters to results for one tankless water heater.
    puts "Multiple water heater test results:"
    xmls.sort.each do |xml|
      next if not xml.include? water_heating_multiple_dir

      xml_x3 = File.absolute_path(xml)
      xml_x1 = File.absolute_path(File.join(File.dirname(xml), "..", File.basename(xml.gsub("-x3.xml", ".xml"))))

      results_x3 = all_results[xml_x3]
      results_x1 = all_results[xml_x1]
      next if results_x1.nil?

      # Compare results
      results_x3.keys.each do |k|
        next if [@simulation_runtime_key, @workflow_runtime_key].include? k

        result_x1 = results_x1[k].to_f
        result_x3 = results_x3[k].to_f
        next if result_x1 == 0.0 and result_x3 == 0.0

        _display_result_delta(xml, result_x1, result_x3, k)
        if k[0] == "Volume"
          # Annual hot water volumes are large, use epsilon
          assert_in_epsilon(result_x1, result_x3, 0.001)
        else
          assert_in_delta(result_x1, result_x3, 0.1)
        end
      end
    end
  end

  def _test_partial_hvac(xmls, hvac_partial_dir, hvac_base_dir, all_results)
    # Compare end use results for a partial HVAC system to a full HVAC system.
    puts "Partial HVAC test results:"
    xmls.sort.each do |xml|
      next if not xml.include? hvac_partial_dir

      xml_33 = File.absolute_path(xml)
      xml_100 = File.absolute_path(xml.gsub(hvac_partial_dir, hvac_base_dir).gsub("-33percent.xml", "-base.xml"))

      results_33 = all_results[xml_33]
      results_100 = all_results[xml_100]
      next if results_100.nil?

      # Compare results
      results_33.keys.each do |k|
        next unless ["Heating", "Cooling"].include? k[1]
        next unless ["General"].include? k[2] # Exclude crankcase/defrost
        next if k[0] == "Load"

        result_33 = results_33[k].to_f
        result_100 = results_100[k].to_f
        next if result_33 == 0.0 and result_100 == 0.0

        _display_result_epsilon(xml, result_33, result_100 / 3.0, k)
        if result_33 > 1.0
          assert_in_epsilon(result_33, result_100 / 3.0, 0.05)
        else
          assert_in_delta(result_33, result_100 / 3.0, 0.1)
        end
      end
    end
  end

  def _test_collapsed_surfaces(all_results, this_dir)
    results_base = all_results[File.absolute_path("#{this_dir}/base-enclosure-skylights.xml")]
    results_collapsed = all_results[File.absolute_path("#{this_dir}/base-enclosure-split-surfaces.xml")]
    return if results_base.nil? or results_collapsed.nil?

    # Compare results
    results_base.keys.each do |k|
      next if [@simulation_runtime_key, @workflow_runtime_key].include? k

      assert_equal(results_base[k].to_f, results_collapsed[k].to_f)
    end
  end

  def _display_result_epsilon(xml, result1, result2, key)
    epsilon = (result1 - result2).abs / [result1, result2].min
    puts "#{xml}: epsilon=#{epsilon.round(5)} [#{key}]"
  end

  def _display_result_delta(xml, result1, result2, key)
    delta = (result1 - result2).abs
    puts "#{xml}: delta=#{delta.round(5)} [#{key}]"
  end

  def _rm_path(path)
    if Dir.exists?(path)
      FileUtils.rm_r(path)
    end
    while true
      break if not Dir.exists?(path)

      sleep(0.01)
    end
  end
end
