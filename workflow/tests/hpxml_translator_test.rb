# frozen_string_literal: true

require_relative '../../HPXMLtoOpenStudio/resources/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require 'fileutils'
require_relative '../../HPXMLtoOpenStudio/measure.rb'
require_relative '../../HPXMLtoOpenStudio/resources/constants'
require_relative '../../HPXMLtoOpenStudio/resources/meta_measure'
require_relative '../../HPXMLtoOpenStudio/resources/unit_conversions'
require_relative '../../HPXMLtoOpenStudio/resources/xmlhelper'

class HPXMLTest < MiniTest::Test
  @@simulation_runtime_key = 'Simulation Runtime'
  @@workflow_runtime_key = 'Workflow Runtime'

  def test_simulations
    OpenStudio::Logger.instance.standardOutLogger.setLogLevel(OpenStudio::Error)
    # OpenStudio::Logger.instance.standardOutLogger.setLogLevel(OpenStudio::Fatal)

    this_dir = File.dirname(__FILE__)
    results_dir = File.join(this_dir, 'results')
    _rm_path(results_dir)

    sample_files_dir = File.absolute_path(File.join(this_dir, '..', 'sample_files'))
    autosize_dir = File.absolute_path(File.join(this_dir, '..', 'sample_files', 'hvac_autosizing'))

    test_dirs = [sample_files_dir,
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
    all_sizing_results = {}
    xmls.each do |xml|
      all_results[xml], all_sizing_results[xml] = _run_xml(xml, this_dir)
    end

    Dir.mkdir(results_dir)
    _write_summary_results(results_dir, all_results)
    _write_hvac_sizing_results(results_dir, all_sizing_results)
  end

  def test_run_simulation_rb
    # Check that simulation works using run_simulation.rb script
    os_cli = OpenStudio.getOpenStudioCLI
    rb_path = File.join(File.dirname(__FILE__), '..', 'run_simulation.rb')
    xml = File.join(File.dirname(__FILE__), '..', 'sample_files', 'base.xml')
    command = "#{os_cli} #{rb_path} -x #{xml} --debug"
    system(command, err: File::NULL)

    # Check for output files
    sql_path = File.join(File.dirname(xml), 'run', 'eplusout.sql')
    assert(File.exist? sql_path)
    csv_output_path = File.join(File.dirname(xml), 'run', 'results_annual.csv')
    assert(File.exist? csv_output_path)

    # Check for debug files
    osm_path = File.join(File.dirname(xml), 'run', 'in.osm')
    assert(File.exist? osm_path)
    hpxml_defaults_path = File.join(File.dirname(xml), 'run', 'in.xml')
    assert(File.exist? hpxml_defaults_path)
  end

  def test_template_osw
    # Check that simulation works using template.osw
    require 'json'

    os_cli = OpenStudio.getOpenStudioCLI
    osw_path = File.join(File.dirname(__FILE__), '..', 'template.osw')

    # Create derivative OSW for testing
    osw_path_test = osw_path.gsub('.osw', '_test.osw')
    FileUtils.cp(osw_path, osw_path_test)

    # Turn on debug mode
    json = JSON.parse(File.read(osw_path_test), symbolize_names: true)
    json[:steps][0][:arguments][:debug] = true

    if Dir.exist? File.join(File.dirname(__FILE__), '..', '..', 'project')
      # CI checks out the repo as "project", so update dir name
      json[:steps][0][:measure_dir_name] = 'project'
    end

    File.open(osw_path_test, 'w') do |f|
      f.write(JSON.pretty_generate(json))
    end

    command = "#{os_cli} run -w #{osw_path_test}"
    system(command, err: File::NULL)

    # Check for output files
    sql_path = File.join(File.dirname(osw_path_test), 'run', 'eplusout.sql')
    assert(File.exist? sql_path)
    csv_output_path = File.join(File.dirname(osw_path_test), 'run', 'results_annual.csv')
    assert(File.exist? csv_output_path)

    # Check for debug files
    osm_path = File.join(File.dirname(osw_path_test), 'run', 'in.osm')
    assert(File.exist? osm_path)
    hpxml_defaults_path = File.join(File.dirname(osw_path_test), 'run', 'in.xml')
    assert(File.exist? hpxml_defaults_path)

    # Cleanup
    File.delete(osw_path_test)
  end

  def test_weather_cache
    this_dir = File.dirname(__FILE__)
    cache_orig = File.join(this_dir, '..', '..', 'weather', 'USA_CO_Denver.Intl.AP.725650_TMY3-cache.csv')
    cache_bak = cache_orig + '.bak'
    File.rename(cache_orig, cache_bak)
    _run_xml(File.absolute_path(File.join(this_dir, '..', 'sample_files', 'base.xml')), this_dir)
    File.rename(cache_bak, cache_orig) # Put original file back
  end

  def test_invalid
    this_dir = File.dirname(__FILE__)
    sample_files_dir = File.join(this_dir, '..', 'sample_files')

    expected_error_msgs = { 'cfis-with-hydronic-distribution.xml' => ["Attached HVAC distribution system 'HVACDistribution' cannot be hydronic for ventilation fan 'MechanicalVentilation'."],
                            'clothes-dryer-location.xml' => ["ClothesDryer location is 'garage' but building does not have this location specified."],
                            'clothes-dryer-location-other.xml' => ['Expected [1] element(s) but found 0 element(s) for xpath: /HPXML/Building/BuildingDetails/Appliances/ClothesDryer: [not(Location)] |'],
                            'clothes-washer-location.xml' => ["ClothesWasher location is 'garage' but building does not have this location specified."],
                            'clothes-washer-location-other.xml' => ['Expected [1] element(s) but found 0 element(s) for xpath: /HPXML/Building/BuildingDetails/Appliances/ClothesWasher: [not(Location)] |'],
                            'dhw-frac-load-served.xml' => ['Expected FractionDHWLoadServed to sum to 1, but calculated sum is 1.15.'],
                            'duct-location.xml' => ["Duct location is 'garage' but building does not have this location specified."],
                            'duct-location-other.xml' => ['Expected [1] element(s) but found 0 element(s) for xpath: /HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution/DistributionSystemType/AirDistribution/Ducts[DuctType="supply" or DuctType="return"]: DuctLocation'],
                            'duplicate-id.xml' => ["Duplicate SystemIdentifier IDs detected for 'Wall'."],
                            'heat-pump-mixed-fixed-and-autosize-capacities.xml' => ["HeatPump 'HeatPump' CoolingCapacity and HeatingCapacity must either both be auto-sized or fixed-sized."],
                            'heat-pump-mixed-fixed-and-autosize-capacities2.xml' => ["HeatPump 'HeatPump' CoolingCapacity and HeatingCapacity must either both be auto-sized or fixed-sized."],
                            'heat-pump-mixed-fixed-and-autosize-capacities3.xml' => ["HeatPump 'HeatPump' has HeatingCapacity17F provided but heating capacity is auto-sized."],
                            'heat-pump-mixed-fixed-and-autosize-capacities4.xml' => ["HeatPump 'HeatPump' BackupHeatingCapacity and HeatingCapacity must either both be auto-sized or fixed-sized."],
                            'hvac-invalid-distribution-system-type.xml' => ["Incorrect HVAC distribution system type for HVAC type: 'Furnace'. Should be one of: ["],
                            'hvac-distribution-multiple-attached-cooling.xml' => ["Multiple cooling systems found attached to distribution system 'HVACDistribution2'."],
                            'hvac-distribution-multiple-attached-heating.xml' => ["Multiple heating systems found attached to distribution system 'HVACDistribution'."],
                            'hvac-dse-multiple-attached-cooling.xml' => ["Multiple cooling systems found attached to distribution system 'HVACDistribution'."],
                            'hvac-dse-multiple-attached-heating.xml' => ["Multiple heating systems found attached to distribution system 'HVACDistribution'."],
                            'hvac-frac-load-served.xml' => ['Expected FractionCoolLoadServed to sum to <= 1, but calculated sum is 1.2.',
                                                            'Expected FractionHeatLoadServed to sum to <= 1, but calculated sum is 1.1.'],
                            'hvac-distribution-return-duct-leakage-missing.xml' => ["Return ducts exist but leakage was not specified for distribution system 'HVACDistribution'."],
                            'invalid-epw-filepath.xml' => ["foo.epw' could not be found."],
                            'invalid-neighbor-shading-azimuth.xml' => ['A neighbor building has an azimuth (145) not equal to the azimuth of any wall.'],
                            'invalid-relatedhvac-dhw-indirect.xml' => ["RelatedHVACSystem 'HeatingSystem_bad' not found for water heating system 'WaterHeater'"],
                            'invalid-relatedhvac-desuperheater.xml' => ["RelatedHVACSystem 'CoolingSystem_bad' not found for water heating system 'WaterHeater'."],
                            'invalid-timestep.xml' => ['Timestep (45) must be one of: 60, 30, 20, 15, 12, 10, 6, 5, 4, 3, 2, 1.'],
                            'invalid-runperiod.xml' => ['End Day of Month (31) must be one of: 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30.'],
                            'invalid-window-height.xml' => ["For Window 'WindowEast', overhangs distance to bottom (2.0) must be greater than distance to top (2.0)."],
                            'invalid-window-interior-shading.xml' => ["SummerShadingCoefficient (0.85) must be less than or equal to WinterShadingCoefficient (0.7) for window 'WindowNorth'."],
                            'invalid-wmo.xml' => ["Weather station WMO '999999' could not be found in"],
                            'lighting-fractions.xml' => ['Sum of fractions of interior lighting (1.05) is greater than 1.'],
                            'mismatched-slab-and-foundation-wall.xml' => ["Foundation wall 'FoundationWall' is adjacent to 'basement - conditioned' but no corresponding slab was found adjacent to"],
                            'missing-elements.xml' => ['Expected [1] element(s) but found 0 element(s) for xpath: /HPXML/Building/BuildingDetails/BuildingSummary/BuildingConstruction: NumberofConditionedFloors',
                                                       'Expected [1] element(s) but found 0 element(s) for xpath: /HPXML/Building/BuildingDetails/BuildingSummary/BuildingConstruction: ConditionedFloorArea'],
                            'missing-surfaces.xml' => ["'garage' must have at least one floor surface."],
                            'net-area-negative-wall.xml' => ["Calculated a negative net surface area for surface 'Wall'."],
                            'net-area-negative-roof.xml' => ["Calculated a negative net surface area for surface 'Roof'."],
                            'orphaned-hvac-distribution.xml' => ["Distribution system 'HVACDistribution' found but no HVAC system attached to it."],
                            'refrigerator-location.xml' => ["Refrigerator location is 'garage' but building does not have this location specified."],
                            'refrigerator-location-other.xml' => ['Expected [1] element(s) but found 0 element(s) for xpath: /HPXML/Building/BuildingDetails/Appliances/Refrigerator: [not(Location)] |'],
                            'repeated-relatedhvac-dhw-indirect.xml' => ["RelatedHVACSystem 'HeatingSystem' is attached to multiple water heating systems."],
                            'repeated-relatedhvac-desuperheater.xml' => ["RelatedHVACSystem 'CoolingSystem' is attached to multiple water heating systems."],
                            'slab-zero-exposed-perimeter.xml' => ["Exposed perimeter for Slab 'Slab' must be greater than zero."],
                            'solar-thermal-system-with-combi-tankless.xml' => ["Water heating system 'WaterHeater' connected to solar thermal system 'SolarThermalSystem' cannot be a space-heating boiler."],
                            'solar-thermal-system-with-desuperheater.xml' => ["Water heating system 'WaterHeater' connected to solar thermal system 'SolarThermalSystem' cannot be attached to a desuperheater."],
                            'solar-thermal-system-with-dhw-indirect.xml' => ["Water heating system 'WaterHeater' connected to solar thermal system 'SolarThermalSystem' cannot be a space-heating boiler."],
                            'unattached-cfis.xml' => ["Attached HVAC distribution system 'foobar' not found for ventilation fan 'MechanicalVentilation'."],
                            'unattached-door.xml' => ["Attached wall 'foobar' not found for door 'DoorNorth'."],
                            'unattached-hvac-distribution.xml' => ["Attached HVAC distribution system 'foobar' not found for HVAC system 'HeatingSystem'."],
                            'unattached-skylight.xml' => ["Attached roof 'foobar' not found for skylight 'SkylightNorth'."],
                            'unattached-solar-thermal-system.xml' => ["Attached water heating system 'foobar' not found for solar thermal system 'SolarThermalSystem'."],
                            'unattached-window.xml' => ["Attached wall 'foobar' not found for window 'WindowNorth'."],
                            'water-heater-location.xml' => ["WaterHeatingSystem location is 'crawlspace - vented' but building does not have this location specified."],
                            'water-heater-location-other.xml' => ['Expected [1] element(s) but found 0 element(s) for xpath: /HPXML/Building/BuildingDetails/Systems/WaterHeating/WaterHeatingSystem: [not(Location)] |'] }

    # Test simulations
    Dir["#{sample_files_dir}/invalid_files/*.xml"].sort.each do |xml|
      _run_xml(File.absolute_path(xml), this_dir, true, expected_error_msgs[File.basename(xml)])
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

  def _run_xml(xml, this_dir, expect_error = false, expect_error_msgs = nil)
    print "Testing #{File.basename(xml)}...\n"
    rundir = File.join(this_dir, 'run')
    _test_schema_validation(this_dir, xml) unless expect_error
    results, sizing_results = _test_simulation(this_dir, xml, rundir, expect_error, expect_error_msgs)
    return results, sizing_results
  end

  def _get_results(rundir, sim_time, workflow_time, annual_csv_path)
    # Grab all outputs from reporting measure CSV annual results
    results = {}
    CSV.foreach(annual_csv_path) do |row|
      next if row.nil? || (row.size < 2)

      results[row[0]] = Float(row[1])
    end

    sql_path = File.join(rundir, 'eplusout.sql')
    sqlFile = OpenStudio::SqlFile.new(sql_path, false)

    # Obtain hot water use
    # TODO: Add to reporting measure?
    query = "SELECT SUM(VariableValue) FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex IN (SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE VariableName='Water Use Equipment Hot Water Volume' AND VariableUnits='m3' AND ReportingFrequency='Run Period')"
    results['Volume: Hot Water (gal)'] = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, 'm^3', 'gal').round(2)

    # Obtain HVAC capacities
    # TODO: Add to reporting measure?
    htg_cap_w = 0
    for spd in [4, 2]
      # Get capacity of highest speed for multispeed coil
      query = "SELECT SUM(Value) FROM ComponentSizes WHERE CompType='Coil:Heating:DX:MultiSpeed' AND Description LIKE '%User-Specified Speed #{spd}%Capacity' AND Units='W'"
      htg_cap_w += sqlFile.execAndReturnFirstDouble(query).get
      break if htg_cap_w > 0
    end
    query = "SELECT SUM(Value) FROM ComponentSizes WHERE ((CompType LIKE 'Coil:Heating:%' OR CompType LIKE 'Boiler:%' OR CompType LIKE 'ZONEHVAC:BASEBOARD:%') AND CompType!='Coil:Heating:DX:MultiSpeed') AND Description LIKE '%User-Specified%Capacity' AND Units='W'"
    htg_cap_w += sqlFile.execAndReturnFirstDouble(query).get
    results['Capacity: Heating (W)'] = htg_cap_w

    clg_cap_w = 0
    for spd in [4, 2]
      # Get capacity of highest speed for multispeed coil
      query = "SELECT SUM(Value) FROM ComponentSizes WHERE CompType='Coil:Cooling:DX:MultiSpeed' AND Description LIKE 'User-Specified Speed #{spd}%Total%Capacity' AND Units='W'"
      clg_cap_w += sqlFile.execAndReturnFirstDouble(query).get
      break if clg_cap_w > 0
    end
    query = "SELECT SUM(Value) FROM ComponentSizes WHERE CompType LIKE 'Coil:Cooling:%' AND CompType!='Coil:Cooling:DX:MultiSpeed' AND Description LIKE '%User-Specified%Total%Capacity' AND Units='W'"
    clg_cap_w += sqlFile.execAndReturnFirstDouble(query).get
    results['Capacity: Cooling (W)'] = clg_cap_w

    sqlFile.close

    # Check discrepancy between total load and sum of component loads
    sum_component_htg_loads = results.select { |k, v| k.start_with? 'Component Load: Heating:' }.map { |k, v| v }.inject(0, :+)
    sum_component_clg_loads = results.select { |k, v| k.start_with? 'Component Load: Cooling:' }.map { |k, v| v }.inject(0, :+)
    residual_htg_load = results['Load: Heating (MBtu)'] - sum_component_htg_loads
    residual_clg_load = results['Load: Cooling (MBtu)'] - sum_component_clg_loads
    assert_operator(residual_htg_load.abs, :<, 0.45)
    assert_operator(residual_clg_load.abs, :<, 0.45)

    results[@@simulation_runtime_key] = sim_time
    results[@@workflow_runtime_key] = workflow_time

    return results
  end

  def _test_simulation(this_dir, xml, rundir, expect_error, expect_error_msgs)
    # Uses meta_measure workflow for faster simulations
    # TODO: Merge code with workflow/run_simulation.rb

    # Setup
    _rm_path(rundir)
    Dir.mkdir(rundir)

    workflow_start = Time.now
    model = OpenStudio::Model::Model.new
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    measures_dir = File.join(this_dir, '..', '..')

    measures = {}

    # Add HPXML translator measure to workflow
    measure_subdir = 'HPXMLtoOpenStudio'
    args = {}
    args['hpxml_path'] = xml
    args['weather_dir'] = 'weather'
    args['output_dir'] = File.absolute_path(rundir)
    args['debug'] = true
    update_args_hash(measures, measure_subdir, args)

    # Add reporting measure to workflow
    measure_subdir = 'SimulationOutputReport'
    args = {}
    args['timeseries_frequency'] = 'hourly'
    args['include_timeseries_zone_temperatures'] = true
    args['include_timeseries_fuel_consumptions'] = true
    args['include_timeseries_end_use_consumptions'] = true
    args['include_timeseries_hot_water_uses'] = true
    args['include_timeseries_total_loads'] = true
    args['include_timeseries_component_loads'] = true
    update_args_hash(measures, measure_subdir, args)

    # Apply measure
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
        flunk "No error message defined for #{File.basename(xml)}."
      else
        run_log = File.readlines(File.join(rundir, 'run.log')).map(&:strip)
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
      show_output(runner.result) unless success
      assert_equal(true, success)
    end

    # Add output variables for crankcase and defrost energy
    vars = ['Cooling Coil Crankcase Heater Electric Energy',
            'Heating Coil Crankcase Heater Electric Energy',
            'Heating Coil Defrost Electric Energy']
    vars.each do |var|
      output_var = OpenStudio::Model::OutputVariable.new(var, model)
      output_var.setReportingFrequency('runperiod')
      output_var.setKeyValue('*')
    end

    # Add output variables for CFIS tests
    @cfis_fan_power_output_var = OpenStudio::Model::OutputVariable.new("#{Constants.ObjectNameMechanicalVentilation} cfis fan power".gsub(' ', '_'), model)
    @cfis_fan_power_output_var.setReportingFrequency('runperiod')
    @cfis_fan_power_output_var.setKeyValue('EMS')

    @cfis_flow_rate_output_var = OpenStudio::Model::OutputVariable.new("#{Constants.ObjectNameMechanicalVentilation} cfis flow rate".gsub(' ', '_'), model)
    @cfis_flow_rate_output_var.setReportingFrequency('runperiod')
    @cfis_flow_rate_output_var.setKeyValue('EMS')

    # Add output variables for hot water volume
    output_var = OpenStudio::Model::OutputVariable.new('Water Use Equipment Hot Water Volume', model)
    output_var.setReportingFrequency('runperiod')
    output_var.setKeyValue('*')

    # Add output variables for combi system energy check
    output_var = OpenStudio::Model::OutputVariable.new('Water Heater Source Side Heat Transfer Energy', model)
    output_var.setReportingFrequency('runperiod')
    output_var.setKeyValue('*')
    output_var = OpenStudio::Model::OutputVariable.new('Baseboard Total Heating Energy', model)
    output_var.setReportingFrequency('runperiod')
    output_var.setKeyValue('*')
    output_var = OpenStudio::Model::OutputVariable.new('Boiler Heating Energy', model) # This is needed for energy checking if there's boiler not connected to combi systems.
    output_var.setReportingFrequency('runperiod')
    output_var.setKeyValue('*')
    model.getHeatExchangerFluidToFluids.each do |hx|
      output_var = OpenStudio::Model::OutputVariable.new('Fluid Heat Exchanger Heat Transfer Energy', model)
      output_var.setReportingFrequency('runperiod')
      output_var.setKeyValue(hx.name.to_s)
    end

    # Translate model to IDF
    forward_translator = OpenStudio::EnergyPlus::ForwardTranslator.new
    forward_translator.setExcludeLCCObjects(true)
    model_idf = forward_translator.translateModel(model)

    # Apply reporting measure output requests
    apply_energyplus_output_requests(measures_dir, measures, runner, model, model_idf)

    # Write IDF to file
    File.open(File.join(rundir, 'in.idf'), 'w') { |f| f << model_idf.to_s }

    # Run EnergyPlus
    # getEnergyPlusDirectory can be unreliable, using getOpenStudioCLI instead
    ep_path = File.absolute_path(File.join(OpenStudio.getOpenStudioCLI.to_s, '..', '..', 'EnergyPlus', 'energyplus'))
    command = "cd #{rundir} && #{ep_path} -w in.epw in.idf > stdout-energyplus"
    simulation_start = Time.now
    system(command, err: File::NULL)
    sim_time = (Time.now - simulation_start).round(1)
    workflow_time = (Time.now - workflow_start).round(1)
    puts "Completed #{File.basename(xml)} simulation in #{sim_time}, workflow in #{workflow_time}s."

    # Apply reporting measures
    runner.setLastEnergyPlusSqlFilePath(File.join(rundir, 'eplusout.sql'))
    success = apply_measures(measures_dir, measures, runner, model, true, 'OpenStudio::Measure::ReportingMeasure')
    runner.resetLastEnergyPlusSqlFilePath

    # Report warnings/errors
    File.open(File.join(rundir, 'run.log'), 'a') do |f|
      runner.result.stepWarnings.each do |s|
        f << "Warning: #{s}\n"
      end
      runner.result.stepErrors.each do |s|
        f << "Error: #{s}\n"
      end
    end

    assert_equal(true, success)

    annual_csv_path = File.join(rundir, 'results_annual.csv')
    timeseries_csv_path = File.join(rundir, 'results_timeseries.csv')
    assert(File.exist? annual_csv_path)
    assert(File.exist? timeseries_csv_path)

    results = _get_results(rundir, sim_time, workflow_time, annual_csv_path)

    # Verify simulation outputs
    _verify_simulation_outputs(runner, rundir, xml, results)

    # Get HVAC sizing outputs
    sizing_results = _get_sizing_results(runner)

    return results, sizing_results
  end

  def _get_sizing_results(runner)
    results = {}
    runner.result.stepInfo.each do |s_info|
      s_info.split("\n").each do |s|
        next unless s.start_with?('Heat ') || s.start_with?('Cool ')
        next unless s.include? '='

        vals = s.split('=')
        prop = vals[0].strip
        vals = vals[1].split(' ')
        value = Float(vals[0].strip)
        prop += " [#{vals[1].strip}]" # add units
        results[prop] = 0.0 if results[prop].nil?
        results[prop] += value
      end
    end
    assert(!results.empty?)
    return results
  end

  def _verify_simulation_outputs(runner, rundir, hpxml_path, results)
    # Check that eplusout.err has no lines that include "Blank Schedule Type Limits Name input"
    # Check that eplusout.err has no lines that include "FixViewFactors: View factors not complete"
    File.readlines(File.join(rundir, 'eplusout.err')).each do |err_line|
      next if err_line.include? 'Schedule:Constant="ALWAYS ON CONTINUOUS", Blank Schedule Type Limits Name input'
      next if err_line.include? 'Schedule:Constant="ALWAYS OFF DISCRETE", Blank Schedule Type Limits Name input'

      assert_equal(err_line.include?('Blank Schedule Type Limits Name input'), false)
      assert_equal(err_line.include?('FixViewFactors: View factors not complete'), false)
    end

    sql_path = File.join(rundir, 'eplusout.sql')
    assert(File.exist? sql_path)

    sqlFile = OpenStudio::SqlFile.new(sql_path, false)
    hpxml_defaults_path = File.join(rundir, 'in.xml')
    hpxml = HPXML.new(hpxml_path: hpxml_defaults_path)

    # Collapse windows further using same logic as measure.rb
    hpxml.windows.each do |window|
      window.fraction_operable = nil
    end
    hpxml.collapse_enclosure_surfaces()

    # Timestep
    timestep = hpxml.header.timestep
    if timestep.nil?
      timestep = 60
    end
    query = 'SELECT NumTimestepsPerHour FROM Simulations'
    sql_value = sqlFile.execAndReturnFirstDouble(query).get
    assert_equal(60 / timestep, sql_value)

    # Conditioned Floor Area
    sum_hvac_load_frac = 0.0
    (hpxml.heating_systems + hpxml.heat_pumps).each do |heating_system|
      sum_hvac_load_frac += heating_system.fraction_heat_load_served.to_f
    end
    (hpxml.cooling_systems + hpxml.heat_pumps).each do |cooling_system|
      sum_hvac_load_frac += cooling_system.fraction_cool_load_served.to_f
    end
    if sum_hvac_load_frac > 0 # EnergyPlus will only report conditioned floor area if there is an HVAC system
      hpxml_value = hpxml.building_construction.conditioned_floor_area
      query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='InputVerificationandResultsSummary' AND ReportForString='Entire Facility' AND TableName='Zone Summary' AND RowName='Conditioned Total' AND ColumnName='Area' AND Units='m2'"
      sql_value = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, 'm^2', 'ft^2')
      # Subtract duct return plenum conditioned floor area
      query = "SELECT SUM(Value) FROM TabularDataWithStrings WHERE ReportName='InputVerificationandResultsSummary' AND ReportForString='Entire Facility' AND TableName='Zone Summary' AND RowName LIKE '%RET AIR ZONE' AND ColumnName='Area' AND Units='m2'"
      sql_value -= UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, 'm^2', 'ft^2')
      assert_in_epsilon(hpxml_value, sql_value, 0.01)
    end

    # Enclosure Roofs
    hpxml.roofs.each do |roof|
      roof_id = roof.id.upcase

      # R-value
      hpxml_value = roof.insulation_assembly_r_value
      query = "SELECT AVG(Value) FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='Opaque Exterior' AND (RowName='#{roof_id}' OR RowName LIKE '#{roof_id}:%') AND ColumnName='U-Factor with Film' AND Units='W/m2-K'"
      sql_value = 1.0 / UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, 'W/(m^2*K)', 'Btu/(hr*ft^2*F)')
      assert_in_epsilon(hpxml_value, sql_value, 0.1) # TODO: Higher due to outside air film?

      # Net area
      hpxml_value = roof.area
      hpxml.skylights.each do |subsurface|
        next if subsurface.roof_idref.upcase != roof_id

        hpxml_value -= subsurface.area
      end
      query = "SELECT SUM(Value) FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='Opaque Exterior' AND (RowName='#{roof_id}' OR RowName LIKE '#{roof_id}:%') AND ColumnName='Net Area' AND Units='m2'"
      sql_value = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, 'm^2', 'ft^2')
      assert_operator(sql_value, :>, 0.01)
      assert_in_epsilon(hpxml_value, sql_value, 0.01)

      # Solar absorptance
      hpxml_value = roof.solar_absorptance
      query = "SELECT AVG(Value) FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='Opaque Exterior' AND (RowName='#{roof_id}' OR RowName LIKE '#{roof_id}:%') AND ColumnName='Reflectance'"
      sql_value = 1.0 - sqlFile.execAndReturnFirstDouble(query).get
      assert_in_epsilon(hpxml_value, sql_value, 0.01)

      # Tilt
      hpxml_value = UnitConversions.convert(Math.atan(roof.pitch / 12.0), 'rad', 'deg')
      query = "SELECT AVG(Value) FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='Opaque Exterior' AND (RowName='#{roof_id}' OR RowName LIKE '#{roof_id}:%') AND ColumnName='Tilt' AND Units='deg'"
      sql_value = sqlFile.execAndReturnFirstDouble(query).get
      assert_in_epsilon(hpxml_value, sql_value, 0.01)

      # Azimuth
      next unless (not roof.azimuth.nil?) && (Float(roof.pitch) > 0)

      hpxml_value = roof.azimuth
      query = "SELECT AVG(Value) FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='Opaque Exterior' AND (RowName='#{roof_id}' OR RowName LIKE '#{roof_id}:%') AND ColumnName='Azimuth' AND Units='deg'"
      sql_value = sqlFile.execAndReturnFirstDouble(query).get
      assert_in_epsilon(hpxml_value, sql_value, 0.01)
    end

    # Enclosure Foundations
    # Ensure Kiva instances have perimeter fraction of 1.0 as we explicitly define them to end up this way.
    num_kiva_instances = 0
    File.readlines(File.join(rundir, 'eplusout.eio')).each do |eio_line|
      next unless eio_line.downcase.start_with? 'foundation kiva'

      kiva_perim_frac = Float(eio_line.split(',')[5])
      assert_equal(1.0, kiva_perim_frac)

      num_kiva_instances += 1
    end

    num_expected_kiva_instances = { 'base-foundation-ambient.xml' => 0,               # no foundation in contact w/ ground
                                    'base-foundation-multiple.xml' => 2,              # additional instance for 2nd foundation type
                                    'base-enclosure-2stories-garage.xml' => 2,        # additional instance for garage
                                    'base-enclosure-garage.xml' => 2,                 # additional instance for garage
                                    'base-enclosure-adiabatic-surfaces.xml' => 0,     # no foundation in contact w/ ground
                                    'base-foundation-walkout-basement.xml' => 4,      # 3 foundation walls plus a no-wall exposed perimeter
                                    'base-foundation-complex.xml' => 10 }

    if not num_expected_kiva_instances[File.basename(hpxml_path)].nil?
      assert_equal(num_expected_kiva_instances[File.basename(hpxml_path)], num_kiva_instances)
    else
      assert_equal(1, num_kiva_instances)
    end

    # Enclosure Foundation Slabs
    num_slabs = hpxml.slabs.size
    if (num_slabs <= 1) && (num_kiva_instances <= 1) # The slab surfaces may be combined in these situations, so skip tests
      hpxml.slabs.each do |slab|
        slab_id = slab.id.upcase

        # Exposed Area
        hpxml_value = Float(slab.area)
        query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='Opaque Exterior' AND RowName='#{slab_id}' AND ColumnName='Gross Area' AND Units='m2'"
        sql_value = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, 'm^2', 'ft^2')
        assert_operator(sql_value, :>, 0.01)
        assert_in_epsilon(hpxml_value, sql_value, 0.01)

        # Tilt
        query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='Opaque Exterior' AND RowName='#{slab_id}' AND ColumnName='Tilt' AND Units='deg'"
        sql_value = sqlFile.execAndReturnFirstDouble(query).get
        assert_in_epsilon(180.0, sql_value, 0.01)
      end
    end

    # Enclosure Walls/RimJoists/FoundationWalls
    (hpxml.walls + hpxml.rim_joists + hpxml.foundation_walls).each do |wall|
      next unless [HPXML::LocationOutside, HPXML::LocationGround].include? wall.exterior_adjacent_to

      wall_id = wall.id.upcase

      # R-value
      if (not wall.insulation_assembly_r_value.nil?) && (not hpxml_path.include? 'base-foundation-unconditioned-basement-assembly-r.xml') # This file uses Foundation:Kiva for insulation, so skip it
        hpxml_value = wall.insulation_assembly_r_value
        query = "SELECT AVG(Value) FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='Opaque Exterior' AND (RowName='#{wall_id}' OR RowName LIKE '#{wall_id}:%') AND ColumnName='U-Factor with Film' AND Units='W/m2-K'"
        sql_value = 1.0 / UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, 'W/(m^2*K)', 'Btu/(hr*ft^2*F)')
        assert_in_epsilon(hpxml_value, sql_value, 0.03)
      end

      # Net area
      hpxml_value = wall.area
      (hpxml.windows + hpxml.doors).each do |subsurface|
        next if subsurface.wall_idref.upcase != wall_id

        hpxml_value -= subsurface.area
      end
      if wall.exterior_adjacent_to == HPXML::LocationGround
        # Calculate total length of walls
        wall_total_length = 0
        hpxml.foundation_walls.each do |foundation_wall|
          next unless foundation_wall.exterior_adjacent_to == HPXML::LocationGround
          next unless wall.interior_adjacent_to == foundation_wall.interior_adjacent_to

          wall_total_length += foundation_wall.area / foundation_wall.height
        end

        # Calculate total slab exposed perimeter
        slab_exposed_length = 0
        hpxml.slabs.each do |slab|
          next unless wall.interior_adjacent_to == slab.interior_adjacent_to

          slab_exposed_length += slab.exposed_perimeter
        end

        # Calculate exposed foundation wall area
        if slab_exposed_length < wall_total_length
          hpxml_value *= (slab_exposed_length / wall_total_length)
        end
      end
      query = "SELECT SUM(Value) FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='Opaque Exterior' AND (RowName='#{wall_id}' OR RowName LIKE '#{wall_id}:%' OR RowName LIKE '#{wall_id} %') AND ColumnName='Net Area' AND Units='m2'"
      sql_value = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, 'm^2', 'ft^2')
      assert_operator(sql_value, :>, 0.01)
      assert_in_epsilon(hpxml_value, sql_value, 0.01)

      # Solar absorptance
      if wall.respond_to? :solar_absorptance
        hpxml_value = wall.solar_absorptance
        query = "SELECT AVG(Value) FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='Opaque Exterior' AND (RowName='#{wall_id}' OR RowName LIKE '#{wall_id}:%') AND ColumnName='Reflectance'"
        sql_value = 1.0 - sqlFile.execAndReturnFirstDouble(query).get
        assert_in_epsilon(hpxml_value, sql_value, 0.01)
      end

      # Tilt
      query = "SELECT AVG(Value) FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='Opaque Exterior' AND (RowName='#{wall_id}' OR RowName LIKE '#{wall_id}:%') AND ColumnName='Tilt' AND Units='deg'"
      sql_value = sqlFile.execAndReturnFirstDouble(query).get
      assert_in_epsilon(90.0, sql_value, 0.01)

      # Azimuth
      next unless not wall.azimuth.nil?

      hpxml_value = wall.azimuth
      query = "SELECT AVG(Value) FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='Opaque Exterior' AND (RowName='#{wall_id}' OR RowName LIKE '#{wall_id}:%') AND ColumnName='Azimuth' AND Units='deg'"
      sql_value = sqlFile.execAndReturnFirstDouble(query).get
      assert_in_epsilon(hpxml_value, sql_value, 0.01)
    end

    # TODO: Enclosure FrameFloors

    # Enclosure Windows/Skylights
    (hpxml.windows + hpxml.skylights).each do |subsurface|
      subsurface_id = subsurface.id.upcase

      # Area
      hpxml_value = subsurface.area
      query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='Exterior Fenestration' AND RowName='#{subsurface_id}' AND ColumnName='Area of Multiplied Openings' AND Units='m2'"
      sql_value = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, 'm^2', 'ft^2')
      assert_operator(sql_value, :>, 0.01)
      assert_in_epsilon(hpxml_value, sql_value, 0.02)

      # U-Factor
      hpxml_value = subsurface.ufactor
      query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='Exterior Fenestration' AND RowName='#{subsurface_id}' AND ColumnName='Glass U-Factor' AND Units='W/m2-K'"
      sql_value = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, 'W/(m^2*K)', 'Btu/(hr*ft^2*F)')
      assert_in_epsilon(hpxml_value, sql_value, 0.01)

      # SHGC
      # TODO: Affected by interior shading

      # Azimuth
      hpxml_value = subsurface.azimuth
      query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='Exterior Fenestration' AND RowName='#{subsurface_id}' AND ColumnName='Azimuth' AND Units='deg'"
      sql_value = sqlFile.execAndReturnFirstDouble(query).get
      assert_in_epsilon(hpxml_value, sql_value, 0.01)

      # Tilt
      if subsurface.respond_to? :wall_idref
        query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='Exterior Fenestration' AND RowName='#{subsurface_id}' AND ColumnName='Tilt' AND Units='deg'"
        sql_value = sqlFile.execAndReturnFirstDouble(query).get
        assert_in_epsilon(90.0, sql_value, 0.01)
      elsif subsurface.respond_to? :roof_idref
        hpxml_value = nil
        hpxml.roofs.each do |roof|
          next if roof.id != subsurface.roof_idref

          hpxml_value = UnitConversions.convert(Math.atan(roof.pitch / 12.0), 'rad', 'deg')
        end
        query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='Exterior Fenestration' AND RowName='#{subsurface_id}' AND ColumnName='Tilt' AND Units='deg'"
        sql_value = sqlFile.execAndReturnFirstDouble(query).get
        assert_in_epsilon(hpxml_value, sql_value, 0.01)
      else
        flunk "Subsurface '#{subsurface_id}' should have either AttachedToWall or AttachedToRoof element."
      end
    end

    # Enclosure Doors
    hpxml.doors.each do |door|
      door_id = door.id.upcase

      # Area
      if not door.area.nil?
        hpxml_value = door.area
        query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='Exterior Door' AND RowName='#{door_id}' AND ColumnName='Gross Area' AND Units='m2'"
        sql_value = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, 'm^2', 'ft^2')
        assert_operator(sql_value, :>, 0.01)
        assert_in_epsilon(hpxml_value, sql_value, 0.01)
      end

      # R-Value
      next unless not door.r_value.nil?

      hpxml_value = door.r_value
      query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='Exterior Door' AND RowName='#{door_id}' AND ColumnName='U-Factor with Film' AND Units='W/m2-K'"
      sql_value = 1.0 / UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, 'W/(m^2*K)', 'Btu/(hr*ft^2*F)')
      assert_in_epsilon(hpxml_value, sql_value, 0.02)
    end

    # HVAC Heating Systems

    num_htg_sys = hpxml.heating_systems.size
    hpxml.heating_systems.each do |heating_system|
      htg_sys_type = heating_system.heating_system_type
      htg_sys_fuel = heating_system.heating_system_fuel
      htg_load_frac = heating_system.fraction_heat_load_served

      next unless htg_load_frac > 0

      # Electric Auxiliary Energy
      # For now, skip if multiple equipment
      next unless (num_htg_sys == 1) && [HPXML::HVACTypeFurnace, HPXML::HVACTypeBoiler, HPXML::HVACTypeWallFurnace, HPXML::HVACTypeStove].include?(htg_sys_type) && (htg_sys_fuel != HPXML::FuelTypeElectricity)

      if not heating_system.electric_auxiliary_energy.nil?
        hpxml_value = heating_system.electric_auxiliary_energy / 2.08
      else
        furnace_capacity_kbtuh = nil
        if htg_sys_type == HPXML::HVACTypeFurnace
          query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EquipmentSummary' AND ReportForString='Entire Facility' AND TableName='Heating Coils' AND RowName LIKE '%#{Constants.ObjectNameFurnace.upcase}%' AND ColumnName='Nominal Total Capacity' AND Units='W'"
          furnace_capacity_kbtuh = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, 'W', 'kBtu/hr')
        end
        hpxml_value = HVAC.get_default_eae(htg_sys_type, htg_sys_fuel, htg_load_frac, furnace_capacity_kbtuh) / 2.08
      end

      if htg_sys_type == HPXML::HVACTypeBoiler
        query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EquipmentSummary' AND ReportForString='Entire Facility' AND TableName='Pumps' AND RowName LIKE '%#{Constants.ObjectNameBoiler.upcase}%' AND ColumnName='Electric Power' AND Units='W'"
        sql_value = sqlFile.execAndReturnFirstDouble(query).get
      elsif htg_sys_type == HPXML::HVACTypeFurnace

        # Ratio fan power based on heating airflow rate divided by fan airflow rate since the
        # fan is sized based on cooling.
        query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EquipmentSummary' AND ReportForString='Entire Facility' AND TableName='Fans' AND RowName LIKE '%#{Constants.ObjectNameFurnace.upcase}%' AND ColumnName='Rated Electric Power' AND Units='W'"
        query_fan_airflow = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='ComponentSizingSummary' AND ReportForString='Entire Facility' AND TableName='Fan:OnOff' AND RowName LIKE '%#{Constants.ObjectNameFurnace.upcase}%' AND ColumnName='User-Specified Maximum Flow Rate' AND Units='m3/s'"
        query_htg_airflow = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='ComponentSizingSummary' AND ReportForString='Entire Facility' AND TableName='AirLoopHVAC:UnitarySystem' AND RowName LIKE '%#{Constants.ObjectNameFurnace.upcase}%' AND ColumnName='User-Specified Heating Supply Air Flow Rate' AND Units='m3/s'"
        sql_value = sqlFile.execAndReturnFirstDouble(query).get
        sql_value_fan_airflow = sqlFile.execAndReturnFirstDouble(query_fan_airflow).get
        sql_value_htg_airflow = sqlFile.execAndReturnFirstDouble(query_htg_airflow).get
        sql_value *= sql_value_htg_airflow / sql_value_fan_airflow
      elsif (htg_sys_type == HPXML::HVACTypeStove) || (htg_sys_type == HPXML::HVACTypeWallFurnace)
        query = "SELECT AVG(Value) FROM TabularDataWithStrings WHERE ReportName='EquipmentSummary' AND ReportForString='Entire Facility' AND TableName='Fans' AND RowName LIKE '%#{Constants.ObjectNameUnitHeater.upcase}%' AND ColumnName='Rated Electric Power' AND Units='W'"
        sql_value = sqlFile.execAndReturnFirstDouble(query).get
      else
        flunk "Unexpected heating system type '#{htg_sys_type}'."
      end
      assert_in_epsilon(hpxml_value, sql_value, 0.01)
    end

    # HVAC Capacities
    htg_cap = nil
    clg_cap = nil
    hpxml.heating_systems.each do |heating_system|
      htg_sys_cap = heating_system.heating_capacity
      if htg_sys_cap > 0
        htg_cap = 0 if htg_cap.nil?
        htg_cap += htg_sys_cap
      end
    end
    hpxml.cooling_systems.each do |cooling_system|
      clg_sys_cap = cooling_system.cooling_capacity
      if (not clg_sys_cap.nil?) && (Float(clg_sys_cap) > 0)
        clg_cap = 0 if clg_cap.nil?
        clg_cap += Float(clg_sys_cap)
      end
    end
    hpxml.heat_pumps.each do |heat_pump|
      hp_type = heat_pump.heat_pump_type
      hp_cap_clg = heat_pump.cooling_capacity
      hp_cap_htg = heat_pump.heating_capacity
      clg_cap_mult = 1.0
      htg_cap_mult = 1.0
      if hp_type == HPXML::HVACTypeHeatPumpMiniSplit
        # TODO: Generalize this
        clg_cap_mult = 1.20
        htg_cap_mult = 1.20
      elsif (hp_type == HPXML::HVACTypeHeatPumpAirToAir) && (heat_pump.cooling_efficiency_seer > 21)
        # TODO: Generalize this
        htg_cap_mult = 1.17
      end
      supp_hp_cap = heat_pump.backup_heating_capacity.to_f
      if hp_cap_clg > 0
        clg_cap = 0 if clg_cap.nil?
        clg_cap += (hp_cap_clg * clg_cap_mult)
      end
      if hp_cap_htg > 0
        htg_cap = 0 if htg_cap.nil?
        htg_cap += (hp_cap_htg * htg_cap_mult)
      end
      if supp_hp_cap > 0
        htg_cap = 0 if htg_cap.nil?
        htg_cap += supp_hp_cap
      end
    end
    if not clg_cap.nil?
      sql_value = UnitConversions.convert(results['Capacity: Cooling (W)'], 'W', 'Btu/hr')
      if clg_cap == 0
        assert_operator(sql_value, :<, 1)
      elsif clg_cap > 0
        assert_in_epsilon(clg_cap, sql_value, 0.01)
      else # autosized
        assert_operator(sql_value, :>, 1)
      end
    end
    if not htg_cap.nil?
      sql_value = UnitConversions.convert(results['Capacity: Heating (W)'], 'W', 'Btu/hr')
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
    (hpxml.heating_systems + hpxml.heat_pumps).each do |heating_system|
      htg_load_frac += heating_system.fraction_heat_load_served.to_f
    end
    (hpxml.cooling_systems + hpxml.heat_pumps).each do |cooling_system|
      clg_load_frac += cooling_system.fraction_cool_load_served.to_f
    end
    if not hpxml_path.include? 'location-miami'
      htg_energy = results.select { |k, v| (k.include?(': Heating (MBtu)') || k.include?(': Heating Fans/Pumps (MBtu)')) && !k.include?('Load') }.map { |k, v| v }.inject(0, :+)
      assert_equal(htg_load_frac > 0, htg_energy > 0)
    end
    clg_energy = results.select { |k, v| (k.include?(': Cooling (MBtu)') || k.include?(': Cooling Fans/Pumps (MBtu)')) && !k.include?('Load') }.map { |k, v| v }.inject(0, :+)
    assert_equal(clg_load_frac > 0, clg_energy > 0)

    # Water Heater
    if hpxml.water_heating_systems.size > 0
      query = "SELECT SUM(ABS(VariableValue)/1000000000) FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex IN (SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE VariableType='Sum' AND VariableName='Fluid Heat Exchanger Heat Transfer Energy' AND ReportingFrequency='Run Period' AND VariableUnits='J')"
      combi_hx_load = sqlFile.execAndReturnFirstDouble(query).get.round(2)
      query = "SELECT SUM(ABS(VariableValue)/1000000000) FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex IN (SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE VariableType='Sum' AND VariableName='Boiler Heating Energy' AND ReportingFrequency='Run Period' AND VariableUnits='J')"
      combi_htg_load = sqlFile.execAndReturnFirstDouble(query).get.round(2)

      if (combi_htg_load > 0) && (combi_hx_load > 0)
        # Check combi system energy balance
        query = "SELECT SUM(ABS(VariableValue)/1000000000) FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex IN (SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE VariableType='Sum' AND VariableName='Water Heater Source Side Heat Transfer Energy' AND VariableUnits='J')"
        combi_tank_source_load = sqlFile.execAndReturnFirstDouble(query).get.round(2)
        assert_in_epsilon(combi_hx_load, combi_tank_source_load, 0.02)

        # Check boiler, hx, pump, heating coil energy balance
        query = "SELECT SUM(ABS(VariableValue)/1000000000) FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex IN (SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE VariableType='Sum' AND VariableName='Baseboard Total Heating Energy' AND VariableUnits='J')"
        boiler_space_heating_load = sqlFile.execAndReturnFirstDouble(query).get.round(2)
        assert_in_epsilon(combi_hx_load + boiler_space_heating_load, combi_htg_load, 0.02)
      end
    end

    # Mechanical Ventilation
    vent_fan_whole_house = nil
    vent_fan_kitchen = nil
    vent_fan_bath = nil
    hpxml.ventilation_fans.each do |ventilation_fan|
      if ventilation_fan.used_for_local_ventilation
        if ventilation_fan.fan_location == HPXML::VentilationFanLocationKitchen
          vent_fan_kitchen = ventilation_fan
        elsif ventilation_fan.fan_location == HPXML::VentilationFanLocationBath
          vent_fan_bath = ventilation_fan
        end
      elsif ventilation_fan.used_for_whole_building_ventilation
        vent_fan_whole_house = ventilation_fan
      end
    end
    if (not vent_fan_whole_house.nil?) || (not vent_fan_kitchen.nil?) || (not vent_fan_bath.nil?)
      mv_energy = results['Electricity: Mech Vent (MBtu)']

      if (not vent_fan_whole_house.nil?) && (vent_fan_whole_house.fan_type == HPXML::MechVentTypeCFIS)
        # CFIS, check for positive mech vent energy that is less than the energy if it had run 24/7
        fan_gj = UnitConversions.convert(vent_fan_whole_house.fan_power * vent_fan_whole_house.hours_in_operation * 365.0, 'Wh', 'GJ')
        if fan_gj > 0
          assert_operator(mv_energy, :>, 0)
          assert_operator(mv_energy, :<, fan_gj)
        else
          assert_equal(mv_energy, 0.0)
        end

        # CFIS Fan power
        hpxml_value = vent_fan_whole_house.fan_power
        query = "SELECT Value FROM ReportData WHERE ReportDataDictionaryIndex IN (SELECT ReportDataDictionaryIndex FROM ReportDataDictionary WHERE Name='#{@cfis_fan_power_output_var.variableName}' AND ReportingFrequency='Run Period')"
        sql_value = sqlFile.execAndReturnFirstDouble(query).get
        assert_in_delta(hpxml_value, sql_value, 0.01)

        # CFIS Flow rate
        hpxml_value = vent_fan_whole_house.tested_flow_rate * vent_fan_whole_house.hours_in_operation / 24.0
        query = "SELECT Value FROM ReportData WHERE ReportDataDictionaryIndex IN (SELECT ReportDataDictionaryIndex FROM ReportDataDictionary WHERE Name='#{@cfis_flow_rate_output_var.variableName}' AND ReportingFrequency='Run Period')"
        sql_value = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, 'm^3/s', 'cfm')
        assert_in_delta(hpxml_value, sql_value, 0.01)
      else
        # Supply, exhaust, ERV, HRV, etc., check for appropriate mech vent energy
        fan_gj = 0
        if not vent_fan_whole_house.nil?
          fan_gj += UnitConversions.convert(vent_fan_whole_house.fan_power * vent_fan_whole_house.hours_in_operation * 365.0, 'Wh', 'GJ')
        end
        if not vent_fan_kitchen.nil?
          fan_gj += UnitConversions.convert(vent_fan_kitchen.fan_power * vent_fan_kitchen.hours_in_operation * 365.0, 'Wh', 'GJ')
        end
        if not vent_fan_bath.nil?
          fan_gj += UnitConversions.convert(vent_fan_bath.fan_power * vent_fan_bath.hours_in_operation * vent_fan_bath.quantity * 365.0, 'Wh', 'GJ')
        end
        assert_in_delta(mv_energy, fan_gj, 0.11)
      end
    end

    # Clothes Washer
    if (hpxml.clothes_washers.size > 0) && (hpxml.water_heating_systems.size > 0)
      # Location
      hpxml_value = hpxml.clothes_washers[0].location
      if hpxml_value.nil? || (hpxml_value == HPXML::LocationBasementConditioned)
        hpxml_value = HPXML::LocationLivingSpace
      end
      query = "SELECT Value FROM TabularDataWithStrings WHERE TableName='ElectricEquipment Internal Gains Nominal' AND ColumnName='Zone Name' AND RowName=(SELECT RowName FROM TabularDataWithStrings WHERE TableName='ElectricEquipment Internal Gains Nominal' AND ColumnName='Name' AND Value='#{Constants.ObjectNameClothesWasher.upcase}')"
      sql_value = sqlFile.execAndReturnFirstString(query).get
      assert_equal(hpxml_value.upcase, sql_value)
    end

    # Clothes Dryer
    if (hpxml.clothes_dryers.size > 0) && (hpxml.water_heating_systems.size > 0)
      # Location
      hpxml_value = hpxml.clothes_dryers[0].location
      if hpxml_value.nil? || (hpxml_value == HPXML::LocationBasementConditioned)
        hpxml_value = HPXML::LocationLivingSpace
      end
      query = "SELECT Value FROM TabularDataWithStrings WHERE TableName='ElectricEquipment Internal Gains Nominal' AND ColumnName='Zone Name' AND RowName=(SELECT RowName FROM TabularDataWithStrings WHERE TableName='ElectricEquipment Internal Gains Nominal' AND ColumnName='Name' AND Value='#{Constants.ObjectNameClothesDryer.upcase}')"
      sql_value = sqlFile.execAndReturnFirstString(query).get
      assert_equal(hpxml_value.upcase, sql_value)
    end

    # Refrigerator
    if hpxml.refrigerators.size > 0
      # Location
      hpxml_value = hpxml.refrigerators[0].location
      if hpxml_value.nil? || (hpxml_value == HPXML::LocationBasementConditioned)
        hpxml_value = HPXML::LocationLivingSpace
      end
      query = "SELECT Value FROM TabularDataWithStrings WHERE TableName='ElectricEquipment Internal Gains Nominal' AND ColumnName='Zone Name' AND RowName=(SELECT RowName FROM TabularDataWithStrings WHERE TableName='ElectricEquipment Internal Gains Nominal' AND ColumnName='Name' AND Value='#{Constants.ObjectNameRefrigerator.upcase}')"
      sql_value = sqlFile.execAndReturnFirstString(query).get
      assert_equal(hpxml_value.upcase, sql_value)
    end

    # Lighting
    ltg_energy = results.select { |k, v| k.include? 'Electricity: Lighting' }.map { |k, v| v }.inject(0, :+)
    assert_equal(hpxml.lighting_groups.size > 0, ltg_energy > 0)

    # Get fuels
    htg_fuels = []
    hpxml.heating_systems.each do |heating_system|
      htg_fuels << heating_system.heating_system_fuel
    end
    hpxml.heat_pumps.each do |heat_pump|
      htg_fuels << heat_pump.backup_heating_fuel
    end
    wh_fuels = []
    hpxml.water_heating_systems.each do |water_heating_system|
      related_hvac = water_heating_system.related_hvac_system
      if related_hvac.nil?
        wh_fuels << water_heating_system.fuel_type
      elsif related_hvac.respond_to? :heating_system_fuel
        wh_fuels << related_hvac.heating_system_fuel
      end
    end

    # Fuel consumption checks
    [HPXML::FuelTypeNaturalGas,
     HPXML::FuelTypeOil,
     HPXML::FuelTypePropane,
     HPXML::FuelTypeWood,
     HPXML::FuelTypeWoodPellets].each do |fuel|
      fuel_name = fuel.split.map(&:capitalize).join(' ')
      energy_htg = results.fetch("#{fuel_name}: Heating (MBtu)", 0)
      energy_dhw = results.fetch("#{fuel_name}: Hot Water (MBtu)", 0)
      energy_cd = results.fetch("#{fuel_name}: Clothes Dryer (MBtu)", 0)
      energy_cr = results.fetch("#{fuel_name}: Range/Oven (MBtu)", 0)
      if htg_fuels.include?(fuel) && (not hpxml_path.include? 'location-miami')
        assert_operator(energy_htg, :>, 0)
      else
        assert_equal(0, energy_htg)
      end
      if wh_fuels.include? fuel
        assert_operator(energy_dhw, :>, 0)
      else
        assert_equal(0, energy_dhw)
      end
      if (hpxml.clothes_dryers.size > 0) && (hpxml.clothes_dryers[0].fuel_type == fuel)
        assert_operator(energy_cd, :>, 0)
      else
        assert_equal(0, energy_cd)
      end
      if (hpxml.cooking_ranges.size > 0) && (hpxml.cooking_ranges[0].fuel_type == fuel)
        assert_operator(energy_cr, :>, 0)
      else
        assert_equal(0, energy_cr)
      end
    end

    sqlFile.close
  end

  def _write_summary_results(results_dir, results)
    require 'csv'
    csv_out = File.join(results_dir, 'results.csv')

    output_keys = []
    results.each do |xml, xml_results|
      output_keys = xml_results.keys
      break
    end

    column_headers = ['HPXML']
    output_keys.each do |key|
      column_headers << key
    end

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

    puts "Wrote summary results to #{csv_out}."
  end

  def _write_hvac_sizing_results(results_dir, all_sizing_results)
    require 'csv'
    csv_out = File.join(results_dir, 'results_hvac_sizing.csv')

    output_keys = nil
    all_sizing_results.each do |xml, xml_results|
      output_keys = xml_results.keys
      break
    end
    return if output_keys.nil?

    CSV.open(csv_out, 'w') do |csv|
      csv << ['HPXML'] + output_keys
      all_sizing_results.sort.each do |xml, xml_results|
        csv_row = [xml]
        output_keys.each do |key|
          csv_row << xml_results[key]
        end
        csv << csv_row
      end
    end

    puts "Wrote HVAC sizing results to #{csv_out}."
  end

  def _test_schema_validation(this_dir, xml)
    # TODO: Remove this when schema validation is included with CLI calls
    schemas_dir = File.absolute_path(File.join(this_dir, '..', '..', 'HPXMLtoOpenStudio', 'resources'))
    hpxml_doc = Oga.parse_xml(File.read(xml))
    errors = XMLHelper.validate(hpxml_doc.to_xml, File.join(schemas_dir, 'HPXML.xsd'), nil)
    if errors.size > 0
      puts "#{xml}: #{errors}"
    end
    assert_equal(0, errors.size)
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
    if Dir.exist?(path)
      FileUtils.rm_r(path)
    end
    while true
      break if not Dir.exist?(path)

      sleep(0.01)
    end
  end
end

def components
  return { 'Total' => 'tot',
           'Roofs' => 'roofs',
           'Ceilings' => 'ceilings',
           'Walls' => 'walls',
           'Rim Joists' => 'rim_joists',
           'Foundation Walls' => 'foundation_walls',
           'Doors' => 'doors',
           'Windows' => 'windows',
           'Skylights' => 'skylights',
           'Floors' => 'floors',
           'Slabs' => 'slabs',
           'Internal Mass' => 'internal_mass',
           'Infiltration' => 'infil',
           'Natural Ventilation' => 'natvent',
           'Mechanical Ventilation' => 'mechvent',
           'Whole House Fan' => 'whf',
           'Ducts' => 'ducts',
           'Internal Gains' => 'intgains' }
end
