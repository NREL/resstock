# frozen_string_literal: true

require_relative '../../HPXMLtoOpenStudio/resources/minitest_helper'
require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
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

  @@os_log = OpenStudio::StringStreamLogSink.new
  @@os_log.setLogLevel(OpenStudio::Warn)

  def test_simulations
    this_dir = File.dirname(__FILE__)
    results_dir = File.join(this_dir, 'results')
    rm_path(results_dir)

    sample_files_dir = File.absolute_path(File.join(this_dir, '..', 'sample_files'))
    autosize_dir = File.absolute_path(File.join(this_dir, '..', 'sample_files', 'hvac_autosizing'))
    ashrae_140_dir = File.absolute_path(File.join(this_dir, 'ASHRAE_Standard_140'))

    test_dirs = [sample_files_dir,
                 autosize_dir,
                 ashrae_140_dir]

    xmls = []
    test_dirs.each do |test_dir|
      Dir["#{test_dir}/*.xml"].sort.each do |xml|
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
    _write_and_check_ashrae_140_results(results_dir, all_results, ashrae_140_dir)
  end

  def test_run_simulation_rb
    # Check that simulation works using run_simulation.rb script
    os_cli = OpenStudio.getOpenStudioCLI
    rb_path = File.join(File.dirname(__FILE__), '..', 'run_simulation.rb')
    xml = File.join(File.dirname(__FILE__), '..', 'sample_files', 'base.xml')
    command = "#{os_cli} #{rb_path} -x #{xml} --debug --hourly ALL"
    system(command, err: File::NULL)

    # Check for output files
    sql_path = File.join(File.dirname(xml), 'run', 'eplusout.sql')
    assert(File.exist? sql_path)
    csv_output_path = File.join(File.dirname(xml), 'run', 'results_annual.csv')
    assert(File.exist? csv_output_path)
    csv_output_path = File.join(File.dirname(xml), 'run', 'results_timeseries.csv')
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

    expected_error_msgs = { 'appliances-location-unconditioned-space.xml' => ['Expected 1 element(s) for xpath: [not(Location)] | Location[text()="living space" or text()="basement - conditioned" or text()="basement - unconditioned" or text()="garage" or text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space"] [context: /HPXML/Building/BuildingDetails/Appliances/ClothesWasher]',
                                                                              'Expected 1 element(s) for xpath: [not(Location)] | Location[text()="living space" or text()="basement - conditioned" or text()="basement - unconditioned" or text()="garage" or text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space"] [context: /HPXML/Building/BuildingDetails/Appliances/ClothesDryer]',
                                                                              'Expected 1 element(s) for xpath: [not(Location)] | Location[text()="living space" or text()="basement - conditioned" or text()="basement - unconditioned" or text()="garage" or text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space"] [context: /HPXML/Building/BuildingDetails/Appliances/Dishwasher]',
                                                                              'Expected 1 element(s) for xpath: [not(Location)] | Location[text()="living space" or text()="basement - conditioned" or text()="basement - unconditioned" or text()="garage" or text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space"] [context: /HPXML/Building/BuildingDetails/Appliances/Refrigerator]',
                                                                              'Expected 1 element(s) for xpath: [not(Location)] | Location[text()="living space" or text()="basement - conditioned" or text()="basement - unconditioned" or text()="garage" or text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space"] [context: /HPXML/Building/BuildingDetails/Appliances/CookingRange]'],
                            'cfis-with-hydronic-distribution.xml' => ["Attached HVAC distribution system 'HVACDistribution' cannot be hydronic for ventilation fan 'MechanicalVentilation'."],
                            'clothes-dryer-location.xml' => ["ClothesDryer location is 'garage' but building does not have this location specified."],
                            'clothes-washer-location.xml' => ["ClothesWasher location is 'garage' but building does not have this location specified."],
                            'cooking-range-location.xml' => ["CookingRange location is 'garage' but building does not have this location specified."],
                            'dishwasher-location.xml' => ["Dishwasher location is 'garage' but building does not have this location specified."],
                            'dhw-frac-load-served.xml' => ['Expected FractionDHWLoadServed to sum to 1, but calculated sum is 1.15.'],
                            'duct-location.xml' => ["Duct location is 'garage' but building does not have this location specified."],
                            'duct-location-unconditioned-space.xml' => ['Expected 0 or 2 element(s) for xpath: DuctSurfaceArea | DuctLocation[text()="living space" or text()="basement - conditioned" or text()="basement - unconditioned" or text()="crawlspace - vented" or text()="crawlspace - unvented" or text()="attic - vented" or text()="attic - unvented" or text()="garage" or text()="exterior wall" or text()="under slab" or text()="roof deck" or text()="outside" or text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space"] [context: /HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution/DistributionSystemType/AirDistribution/Ducts[DuctType="supply" or DuctType="return"]]'],
                            'duplicate-id.xml' => ["Duplicate SystemIdentifier IDs detected for 'Wall'."],
                            'enclosure-attic-missing-roof.xml' => ['There must be at least one roof adjacent to attic - unvented.'],
                            'enclosure-basement-missing-exterior-foundation-wall.xml' => ['There must be at least one exterior foundation wall adjacent to basement - unconditioned.'],
                            'enclosure-basement-missing-slab.xml' => ['There must be at least one slab adjacent to basement - unconditioned.'],
                            'enclosure-floor-area-exceeds-cfa.xml' => ['Sum of floor/slab area adjacent to conditioned space (1350.0) is greater than conditioned floor area (540.0).'],
                            'enclosure-garage-missing-exterior-wall.xml' => ['There must be at least one exterior wall/foundation wall adjacent to garage.'],
                            'enclosure-garage-missing-roof-ceiling.xml' => ['There must be at least one roof/ceiling adjacent to garage.'],
                            'enclosure-garage-missing-slab.xml' => ['There must be at least one slab adjacent to garage.'],
                            'enclosure-living-missing-ceiling-roof.xml' => ['There must be at least one ceiling/roof adjacent to conditioned space.'],
                            'enclosure-living-missing-exterior-wall.xml' => ['There must be at least one exterior wall adjacent to conditioned space.'],
                            'enclosure-living-missing-floor-slab.xml' => ['There must be at least one floor/slab adjacent to conditioned space.'],
                            'heat-pump-mixed-fixed-and-autosize-capacities.xml' => ["HeatPump 'HeatPump' must have both HeatingCapacity and HeatingCapacity17F provided or not provided."],
                            'heat-pump-mixed-fixed-and-autosize-capacities2.xml' => ["HeatPump 'HeatPump' must have both HeatingCapacity and BackupHeatingCapacity provided or not provided."],
                            'hvac-invalid-distribution-system-type.xml' => ["Incorrect HVAC distribution system type for HVAC type: 'Furnace'. Should be one of: ["],
                            'hvac-distribution-multiple-attached-cooling.xml' => ["Multiple cooling systems found attached to distribution system 'HVACDistribution2'."],
                            'hvac-distribution-multiple-attached-heating.xml' => ["Multiple heating systems found attached to distribution system 'HVACDistribution'."],
                            'hvac-dse-multiple-attached-cooling.xml' => ["Multiple cooling systems found attached to distribution system 'HVACDistribution'."],
                            'hvac-dse-multiple-attached-heating.xml' => ["Multiple heating systems found attached to distribution system 'HVACDistribution'."],
                            'hvac-frac-load-served.xml' => ['Expected FractionCoolLoadServed to sum to <= 1, but calculated sum is 1.2.',
                                                            'Expected FractionHeatLoadServed to sum to <= 1, but calculated sum is 1.1.'],
                            'hvac-distribution-return-duct-leakage-missing.xml' => ["Return ducts exist but leakage was not specified for distribution system 'HVACDistribution'."],
                            'invalid-calendar-year.xml' => ['Calendar Year (20018) must be between 1600 and 9999.'],
                            'invalid-distribution-cfa-served.xml' => ['The total conditioned floor area served by the HVAC distribution system(s) for heating is larger than the conditioned floor area of the building.',
                                                                      'The total conditioned floor area served by the HVAC distribution system(s) for cooling is larger than the conditioned floor area of the building.'],
                            'invalid-epw-filepath.xml' => ["foo.epw' could not be found."],
                            'invalid-facility-type.xml' => ['Expected 1 element(s) for xpath: ../../../BuildingSummary/BuildingConstruction[ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]] [context: /HPXML/Building/BuildingDetails/Systems/WaterHeating/WaterHeatingSystem[IsSharedSystem="true"]]',
                                                            'Expected 1 element(s) for xpath: ../../BuildingSummary/BuildingConstruction[ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]] [context: /HPXML/Building/BuildingDetails/Appliances/ClothesWasher[IsSharedAppliance="true"]]',
                                                            'Expected 1 element(s) for xpath: ../../BuildingSummary/BuildingConstruction[ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]] [context: /HPXML/Building/BuildingDetails/Appliances/ClothesDryer[IsSharedAppliance="true"]]',
                                                            'Expected 1 element(s) for xpath: ../../BuildingSummary/BuildingConstruction[ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]] [context: /HPXML/Building/BuildingDetails/Appliances/Dishwasher[IsSharedAppliance="true"]]',
                                                            "The building is of type 'single-family detached' but the surface",
                                                            "The building is of type 'single-family detached' but the object",
                                                            "The building is of type 'single-family detached' but the HVAC distribution"],
                            'invalid-input-parameters.xml' => ["Expected Transaction to be 'create' or 'update' [context: /HPXML/XMLTransactionHeaderInformation]",
                                                               "Expected SiteType to be 'rural' or 'suburban' or 'urban' [context: /HPXML/Building/BuildingDetails/BuildingSummary/Site]",
                                                               "Expected Year to be '2012' or '2009' or '2006' or '2003' [context: /HPXML/Building/BuildingDetails/ClimateandRiskZones/ClimateZoneIECC]",
                                                               'Expected Azimuth to be less than 360 [context: /HPXML/Building/BuildingDetails/Enclosure/Roofs/Roof]',
                                                               'Expected RadiantBarrierGrade to be less than or equal to 3 [context: /HPXML/Building/BuildingDetails/Enclosure/Roofs/Roof]',
                                                               'Expected EnergyFactor to be less than or equal to 5 [context: /HPXML/Building/BuildingDetails/Appliances/Dishwasher]'],
                            'invalid-neighbor-shading-azimuth.xml' => ['A neighbor building has an azimuth (145) not equal to the azimuth of any wall.'],
                            'invalid-relatedhvac-dhw-indirect.xml' => ["RelatedHVACSystem 'HeatingSystem_bad' not found for water heating system 'WaterHeater'"],
                            'invalid-relatedhvac-desuperheater.xml' => ["RelatedHVACSystem 'CoolingSystem_bad' not found for water heating system 'WaterHeater'."],
                            'invalid-timestep.xml' => ['Timestep (45) must be one of: 60, 30, 20, 15, 12, 10, 6, 5, 4, 3, 2, 1.'],
                            'invalid-runperiod.xml' => ['Run Period End Day of Month (31) must be one of: 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30.'],
                            'invalid-window-height.xml' => ["For Window 'WindowEast', overhangs distance to bottom (2.0) must be greater than distance to top (2.0)."],
                            'invalid-daylight-saving.xml' => ['Daylight Saving End Day of Month (31) must be one of: 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30.'],
                            'lighting-fractions.xml' => ['Sum of fractions of interior lighting (1.15) is greater than 1.'],
                            'mismatched-slab-and-foundation-wall.xml' => ["Foundation wall 'FoundationWall' is adjacent to 'basement - conditioned' but no corresponding slab was found adjacent to"],
                            'missing-elements.xml' => ['Expected 1 element(s) for xpath: NumberofConditionedFloors [context: /HPXML/Building/BuildingDetails/BuildingSummary/BuildingConstruction]',
                                                       'Expected 1 element(s) for xpath: ConditionedFloorArea [context: /HPXML/Building/BuildingDetails/BuildingSummary/BuildingConstruction]'],
                            'missing-duct-location.xml' => ['Expected 0 or 2 element(s) for xpath: DuctSurfaceArea | DuctLocation[text()="living space" or text()="basement - conditioned" or text()="basement - unconditioned" or text()="crawlspace - vented" or text()="crawlspace - unvented" or text()="attic - vented" or text()="attic - unvented" or text()="garage" or text()="exterior wall" or text()="under slab" or text()="roof deck" or text()="outside" or text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space"] [context: /HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution/DistributionSystemType/AirDistribution/Ducts[DuctType="supply" or DuctType="return"]]'],
                            'missing-duct-location-and-surface-area.xml' => ['Error: The location and surface area of all ducts must be provided or blank.'],
                            'multifamily-reference-appliance.xml' => ["The building is of type 'single-family detached' but"],
                            'multifamily-reference-duct.xml' => ["The building is of type 'single-family detached' but"],
                            'multifamily-reference-surface.xml' => ["The building is of type 'single-family detached' but"],
                            'multifamily-reference-water-heater.xml' => ["The building is of type 'single-family detached' but"],
                            'net-area-negative-wall.xml' => ["Calculated a negative net surface area for surface 'Wall'."],
                            'net-area-negative-roof.xml' => ["Calculated a negative net surface area for surface 'Roof'."],
                            'num-bedrooms-exceeds-limit.xml' => ['Number of bedrooms (40) exceeds limit of (CFA-120)/70=36.9.'],
                            'orphaned-hvac-distribution.xml' => ["Distribution system 'HVACDistribution' found but no HVAC system attached to it."],
                            'refrigerator-location.xml' => ["Refrigerator location is 'garage' but building does not have this location specified."],
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
                            'unattached-shared-clothes-washer-water-heater.xml' => ["Attached water heating system 'foobar' not found for clothes washer"],
                            'unattached-shared-dishwasher-water-heater.xml' => ["Attached water heating system 'foobar' not found for dishwasher"],
                            'unattached-window.xml' => ["Attached wall 'foobar' not found for window 'WindowNorth'."],
                            'water-heater-location.xml' => ["WaterHeatingSystem location is 'crawlspace - vented' but building does not have this location specified."],
                            'water-heater-location-other.xml' => ['Expected 1 element(s) for xpath: [not(Location)] | Location[text()="living space" or text()="basement - unconditioned" or text()="basement - conditioned" or text()="attic - unvented" or text()="attic - vented" or text()="garage" or text()="crawlspace - unvented" or text()="crawlspace - vented" or text()="other exterior" or text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space"] [context: /HPXML/Building/BuildingDetails/Systems/WaterHeating/WaterHeatingSystem]'],
                            'refrigerators-multiple-primary.xml' => ['More than one refrigerator designated as the primary.'],
                            'refrigerators-no-primary.xml' => ['Could not find a primary refrigerator.'] }

    # Test simulations
    Dir["#{sample_files_dir}/invalid_files/*.xml"].sort.each do |xml|
      _run_xml(File.absolute_path(xml), this_dir, true, expected_error_msgs[File.basename(xml)])
    end
  end

  def _run_xml(xml, this_dir, expect_error = false, expect_error_msgs = nil)
    print "Testing #{File.basename(xml)}...\n"
    rundir = File.join(this_dir, 'run')

    measures_dir = File.join(this_dir, '..', '..')

    measures = {}

    # Add HPXML translator measure to workflow
    measure_subdir = 'HPXMLtoOpenStudio'
    args = {}
    args['hpxml_path'] = xml
    args['output_dir'] = File.absolute_path(rundir)
    args['debug'] = true
    update_args_hash(measures, measure_subdir, args)

    # Add reporting measure to workflow
    measure_subdir = 'SimulationOutputReport'
    args = {}
    args['timeseries_frequency'] = 'monthly'
    args['include_timeseries_fuel_consumptions'] = true
    args['include_timeseries_end_use_consumptions'] = true
    args['include_timeseries_hot_water_uses'] = true
    args['include_timeseries_total_loads'] = true
    args['include_timeseries_component_loads'] = true
    args['include_timeseries_zone_temperatures'] = true
    args['include_timeseries_airflows'] = true
    args['include_timeseries_weather'] = true
    update_args_hash(measures, measure_subdir, args)

    # Add output variables for combi system energy check and CFIS
    output_vars = [['Water Heater Source Side Heat Transfer Energy', 'runperiod', '*'],
                   ['Baseboard Total Heating Energy', 'runperiod', '*'],
                   ['Boiler Heating Energy', 'runperiod', '*'],
                   ['Fluid Heat Exchanger Heat Transfer Energy', 'runperiod', '*'],
                   ['Fan Electricity Rate', 'runperiod', '*'],
                   ['Fan Runtime Fraction', 'runperiod', '*'],
                   ['Electric Equipment Electricity Energy', 'runperiod', Constants.ObjectNameMechanicalVentilationHouseFanCFIS],
                   ['Boiler Part Load Ratio', 'runperiod', Constants.ObjectNameBoiler],
                   ['Pump Electricity Rate', 'runperiod', Constants.ObjectNameBoiler + ' hydronic pump'],
                   ['Unitary System Part Load Ratio', 'runperiod', Constants.ObjectNameGroundSourceHeatPump + ' unitary system'],
                   ['Pump Electricity Rate', 'runperiod', Constants.ObjectNameGroundSourceHeatPump + ' pump']]
    # Run workflow
    workflow_start = Time.now
    results = run_hpxml_workflow(rundir, xml, measures, measures_dir,
                                 debug: true, output_vars: output_vars,
                                 run_measures_only: expect_error)
    workflow_time = (Time.now - workflow_start).round(1)
    success = results[:success]
    runner = results[:runner]
    sim_time = results[:sim_time]
    puts "Completed in #{workflow_time} seconds."
    puts

    # Check results
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
    end

    show_output(runner.result) unless success
    assert_equal(true, success)

    # Check for output files
    annual_csv_path = File.join(rundir, 'results_annual.csv')
    timeseries_csv_path = File.join(rundir, 'results_timeseries.csv')
    assert(File.exist? annual_csv_path)
    assert(File.exist? timeseries_csv_path)

    # Get results
    results = _get_results(rundir, sim_time, workflow_time, annual_csv_path, xml)
    sizing_results = _get_sizing_results(rundir)

    # Check outputs
    _verify_outputs(runner, rundir, xml, results)

    return results, sizing_results
  end

  def _get_results(rundir, sim_time, workflow_time, annual_csv_path, xml)
    # Grab all outputs from reporting measure CSV annual results
    results = {}
    CSV.foreach(annual_csv_path) do |row|
      next if row.nil? || (row.size < 2)

      results[row[0]] = Float(row[1])
    end

    sql_path = File.join(rundir, 'eplusout.sql')
    sqlFile = OpenStudio::SqlFile.new(sql_path, false)

    # Obtain HVAC capacities
    # TODO: Add to reporting measure?
    htg_cap_w = 0
    for spd in [4, 2]
      # Get capacity of highest speed for multi-speed coil
      query = "SELECT SUM(Value) FROM ComponentSizes WHERE CompType='Coil:Heating:DX:MultiSpeed' AND Description LIKE '%User-Specified Speed #{spd}%Capacity' AND Units='W'"
      htg_cap_w += sqlFile.execAndReturnFirstDouble(query).get
      break if htg_cap_w > 0
    end
    query = "SELECT SUM(Value) FROM ComponentSizes WHERE ((CompType LIKE 'Coil:Heating:%' OR CompType LIKE 'Boiler:%' OR CompType LIKE 'ZONEHVAC:BASEBOARD:%') AND CompType!='Coil:Heating:DX:MultiSpeed') AND Description LIKE '%User-Specified%Capacity' AND Units='W'"
    htg_cap_w += sqlFile.execAndReturnFirstDouble(query).get
    results['Capacity: Heating (W)'] = htg_cap_w

    clg_cap_w = 0
    for spd in [4, 2]
      # Get capacity of highest speed for multi-speed coil
      query = "SELECT SUM(Value) FROM ComponentSizes WHERE CompType='Coil:Cooling:DX:MultiSpeed' AND Description LIKE 'User-Specified Speed #{spd}%Total%Capacity' AND Units='W'"
      clg_cap_w += sqlFile.execAndReturnFirstDouble(query).get
      break if clg_cap_w > 0
    end
    query = "SELECT SUM(Value) FROM ComponentSizes WHERE CompType LIKE 'Coil:Cooling:%' AND CompType!='Coil:Cooling:DX:MultiSpeed' AND Description LIKE '%User-Specified%Total%Capacity' AND Units='W'"
    clg_cap_w += sqlFile.execAndReturnFirstDouble(query).get
    results['Capacity: Cooling (W)'] = clg_cap_w

    sqlFile.close

    # Check discrepancy between total load and sum of component loads
    if not xml.include? 'ASHRAE_Standard_140'
      sum_component_htg_loads = results.select { |k, v| k.start_with? 'Component Load: Heating:' }.map { |k, v| v }.sum(0.0)
      sum_component_clg_loads = results.select { |k, v| k.start_with? 'Component Load: Cooling:' }.map { |k, v| v }.sum(0.0)
      residual_htg_load = results['Load: Heating (MBtu)'] - sum_component_htg_loads
      residual_clg_load = results['Load: Cooling (MBtu)'] - sum_component_clg_loads
      assert_operator(residual_htg_load.abs, :<, 0.5)
      assert_operator(residual_clg_load.abs, :<, 0.5)
    end

    results[@@simulation_runtime_key] = sim_time
    results[@@workflow_runtime_key] = workflow_time

    return results
  end

  def _get_sizing_results(rundir)
    results = {}
    File.readlines(File.join(rundir, 'run.log')).each do |s|
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
    assert(!results.empty?)
    return results
  end

  def _verify_outputs(runner, rundir, hpxml_path, results)
    sql_path = File.join(rundir, 'eplusout.sql')
    assert(File.exist? sql_path)

    sqlFile = OpenStudio::SqlFile.new(sql_path, false)
    hpxml_defaults_path = File.join(rundir, 'in.xml')
    hpxml = HPXML.new(hpxml_path: hpxml_defaults_path)
    HVAC.apply_shared_systems(hpxml)

    # Collapse windows further using same logic as measure.rb
    hpxml.windows.each do |window|
      window.fraction_operable = nil
    end
    hpxml.collapse_enclosure_surfaces()

    # Check run.log warnings
    File.readlines(File.join(rundir, 'run.log')).each do |log_line|
      next if log_line.strip.empty?
      next if log_line.include? 'Warning: Could not load nokogiri, no HPXML validation performed.'
      next if log_line.start_with? 'Info: '
      next if log_line.start_with? 'Executing command'
      next if (log_line.start_with?('Heat ') || log_line.start_with?('Cool ')) && log_line.include?('=')
      next if log_line.include? "-cache.csv' could not be found; regenerating it."
      next if log_line.include?('Warning: HVACDistribution') && log_line.include?('has ducts entirely within conditioned space but there is non-zero leakage to the outside.')

      if hpxml.clothes_washers.empty?
        next if log_line.include? 'No clothes washer specified, the model will not include clothes washer energy use.'
      end
      if hpxml.clothes_dryers.empty?
        next if log_line.include? 'No clothes dryer specified, the model will not include clothes dryer energy use.'
      end
      if hpxml.dishwashers.empty?
        next if log_line.include? 'No dishwasher specified, the model will not include dishwasher energy use.'
      end
      if hpxml.refrigerators.empty?
        next if log_line.include? 'No refrigerator specified, the model will not include refrigerator energy use.'
      end
      if hpxml.cooking_ranges.empty?
        next if log_line.include? 'No cooking range specified, the model will not include cooking range/oven energy use.'
      end
      if hpxml.water_heating_systems.empty?
        next if log_line.include? 'No water heater specified, the model will not include water heating energy use.'
      end
      if (hpxml.heating_systems + hpxml.heat_pumps).select { |h| h.fraction_heat_load_served.to_f > 0 }.empty?
        next if log_line.include? 'No heating system specified, the model will not include space heating energy use.'
      end
      if (hpxml.cooling_systems + hpxml.heat_pumps).select { |c| c.fraction_cool_load_served.to_f > 0 }.empty?
        next if log_line.include? 'No cooling system specified, the model will not include space cooling energy use.'
      end
      if hpxml.plug_loads.select { |p| p.plug_load_type == HPXML::PlugLoadTypeOther }.empty?
        next if log_line.include? "No '#{HPXML::PlugLoadTypeOther}' plug loads specified, the model will not include misc plug load energy use."
      end
      if hpxml.plug_loads.select { |p| p.plug_load_type == HPXML::PlugLoadTypeTelevision }.empty?
        next if log_line.include? "No '#{HPXML::PlugLoadTypeTelevision}' plug loads specified, the model will not include television plug load energy use."
      end
      if hpxml.lighting_groups.empty?
        next if log_line.include? 'No lighting specified, the model will not include lighting energy use.'
      end

      flunk "Unexpected warning found in run.log: #{log_line}"
    end

    # Check for unexpected warnings
    File.readlines(File.join(rundir, 'eplusout.err')).each do |err_line|
      next unless err_line.include? '** Warning **'

      # General
      next if err_line.include? 'Schedule:Constant="ALWAYS ON CONTINUOUS", Blank Schedule Type Limits Name input'
      next if err_line.include? 'Schedule:Constant="ALWAYS OFF DISCRETE", Blank Schedule Type Limits Name input'
      next if err_line.include? 'Output:Meter: invalid Key Name'
      next if err_line.include? 'Entered Zone Volumes differ from calculated zone volume'
      next if err_line.include?('CalculateZoneVolume') && err_line.include?('not fully enclosed')
      next if err_line.include?('GetInputViewFactors') && err_line.include?('not enough values')
      next if err_line.include? 'Pump nominal power or motor efficiency is set to 0'
      next if err_line.include? 'volume flow rate per watt of rated total cooling capacity is out of range'
      next if err_line.include? 'volume flow rate per watt of rated total heating capacity is out of range'
      next if err_line.include? 'The following Report Variables were requested but not generated'
      next if err_line.include? 'Timestep: Requested number'
      next if err_line.include? 'The Standard Ratings is calculated for'
      next if err_line.include?('CheckUsedConstructions') && err_line.include?('nominally unused constructions')
      next if err_line.include?('WetBulb not converged after') && err_line.include?('iterations(PsyTwbFnTdbWPb)')
      next if err_line.include? 'Inside surface heat balance did not converge with Max Temp Difference'
      next if err_line.include? 'Missing temperature setpoint for LeavingSetpointModulated mode' # These warnings are fine, simulation continues with assigning plant loop setpoint to boiler, which is the expected one
      next if err_line.include?('Glycol: Temperature') && err_line.include?('out of range (too low) for fluid')
      next if err_line.include?('Glycol: Temperature') && err_line.include?('out of range (too high) for fluid')
      next if err_line.include? 'Plant loop exceeding upper temperature limit'
      next if err_line.include?('Foundation:Kiva') && err_line.include?('wall surfaces with more than four vertices') # TODO: Check alternative approach
      next if err_line.include? 'Temperature out of range [-100. to 200.] (PsyPsatFnTemp)'
      next if err_line.include? 'Full load outlet air dry-bulb temperature < 2C. This indicates the possibility of coil frost/freeze.'
      next if err_line.include? 'Full load outlet temperature indicates a possibility of frost/freeze error continues.'
      next if err_line.include? 'Air-cooled condenser inlet dry-bulb temperature below 0 C.'
      next if err_line.include? 'Low condenser dry-bulb temperature error continues.'

      # HPWHs
      if hpxml.water_heating_systems.select { |wh| wh.water_heater_type == HPXML::WaterHeaterTypeHeatPump }.size > 0
        next if err_line.include? 'Recovery Efficiency and Energy Factor could not be calculated during the test for standard ratings'
        next if err_line.include? 'SimHVAC: Maximum iterations (20) exceeded for all HVAC loops'
      end
      # HP defrost curves
      if hpxml.heat_pumps.select { |hp| [HPXML::HVACTypeHeatPumpAirToAir, HPXML::HVACTypeHeatPumpMiniSplit].include? hp.heat_pump_type }.size > 0
        next if err_line.include?('GetDXCoils: Coil:Heating:DX') && err_line.include?('curve values')
      end
      if hpxml.cooling_systems.select { |c| c.cooling_system_type == HPXML::HVACTypeEvaporativeCooler }.size > 0
        # Evap cooler model is not really using Controller:MechanicalVentilation object, so these warnings of ignoring some features are fine.
        # OS requires a Controller:MechanicalVentilation to be attached to the oa controller, however it's not required by E+.
        # Manually removing Controller:MechanicalVentilation from idf eliminates these two warnings.
        # FUTURE: Can we update OS to allow removing it?
        next if err_line.include?('Zone') && err_line.include?('is not accounted for by Controller:MechanicalVentilation object')
        next if err_line.include?('PEOPLE object for zone') && err_line.include?('is not accounted for by Controller:MechanicalVentilation object')
        # "The only valid controller type for an AirLoopHVAC is Controller:WaterCoil.", evap cooler doesn't need one.
        next if err_line.include?('GetAirPathData: AirLoopHVAC') && err_line.include?('has no Controllers')
        # input "Autosize" for Fixed Minimum Air Flow Rate is added by OS translation, now set it to 0 to skip potential sizing process, though no way to prevent this warning.
        next if err_line.include? 'Since Zone Minimum Air Flow Input Method = CONSTANT, input for Fixed Minimum Air Flow Rate will be ignored'
      end
      if hpxml.cooling_systems.select { |c| c.cooling_system_type == HPXML::HVACTypeRoomAirConditioner }.size > 0
        next if err_line.include? 'GetDXCoils: Coil:Cooling:DX:SingleSpeed="ROOM AC CLG COIL" curve values' # TODO: Double-check Room AC curves
      end
      if hpxml.hvac_distributions.select { |d| d.hydronic_and_air_type.to_s == HPXML::HydronicAndAirTypeFanCoil }.size > 0
        next if err_line.include? 'In calculating the design coil UA for Coil:Cooling:Water' # Warning for unused cooling coil for fan coil
      end
      if hpxml_path.include?('base-schedules-stochastic.xml') || hpxml_path.include?('base-schedules-user-specified.xml')
        next if err_line.include?('GetCurrentScheduleValue: Schedule=') && err_line.include?('is a Schedule:File')
      end

      flunk "Unexpected warning found: #{err_line}"
    end

    # Timestep
    timestep = hpxml.header.timestep
    if timestep.nil?
      timestep = 60
    end
    query = 'SELECT NumTimestepsPerHour FROM Simulations'
    sql_value = sqlFile.execAndReturnFirstDouble(query).get
    assert_equal(60 / timestep, sql_value)

    # Conditioned Floor Area
    if (hpxml.total_fraction_cool_load_served > 0) || (hpxml.total_fraction_heat_load_served > 0) # EnergyPlus will only report conditioned floor area if there is an HVAC system
      hpxml_value = hpxml.building_construction.conditioned_floor_area
      query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='InputVerificationandResultsSummary' AND ReportForString='Entire Facility' AND TableName='Zone Summary' AND RowName='Conditioned Total' AND ColumnName='Area' AND Units='m2'"
      sql_value = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, 'm^2', 'ft^2')
      assert_in_epsilon(hpxml_value, sql_value, 0.01)
    end

    # Enclosure Roofs
    hpxml.roofs.each do |roof|
      roof_id = roof.id.upcase

      # R-value
      hpxml_value = roof.insulation_assembly_r_value
      if hpxml_path.include? 'ASHRAE_Standard_140'
        # Compare R-value w/o film
        hpxml_value -= Material.AirFilmRoofASHRAE140.rvalue
        hpxml_value -= Material.AirFilmOutsideASHRAE140.rvalue
        query = "SELECT AVG(Value) FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='Opaque Exterior' AND (RowName='#{roof_id}' OR RowName LIKE '#{roof_id}:%') AND ColumnName='U-Factor no Film' AND Units='W/m2-K'"
      else
        # Compare R-value w/ film
        query = "SELECT AVG(Value) FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='Opaque Exterior' AND (RowName='#{roof_id}' OR RowName LIKE '#{roof_id}:%') AND ColumnName='U-Factor with Film' AND Units='W/m2-K'"
      end
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

    num_expected_kiva_instances = { 'base-foundation-ambient.xml' => 0,                       # no foundation in contact w/ ground
                                    'base-foundation-multiple.xml' => 2,                      # additional instance for 2nd foundation type
                                    'base-enclosure-2stories-garage.xml' => 2,                # additional instance for garage
                                    'base-enclosure-garage.xml' => 2,                         # additional instance for garage
                                    'base-enclosure-other-housing-unit.xml' => 0,             # no foundation in contact w/ ground
                                    'base-enclosure-other-heated-space.xml' => 0,             # no foundation in contact w/ ground
                                    'base-enclosure-other-non-freezing-space.xml' => 0,       # no foundation in contact w/ ground
                                    'base-enclosure-other-multifamily-buffer-space.xml' => 0, # no foundation in contact w/ ground
                                    'base-enclosure-common-surfaces.xml' => 2,                # additional instance for vented crawlspace
                                    'base-foundation-walkout-basement.xml' => 4,              # 3 foundation walls plus a no-wall exposed perimeter
                                    'base-foundation-complex.xml' => 10,
                                    'base-misc-loads-large-uncommon.xml' => 2,
                                    'base-misc-loads-large-uncommon2.xml' => 2 }

    if hpxml_path.include? 'ASHRAE_Standard_140'
      # nop
    elsif not num_expected_kiva_instances[File.basename(hpxml_path)].nil?
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
      wall_id = wall.id.upcase

      if wall.is_adiabatic
        # Adiabatic surfaces have their "BaseSurfaceIndex" as their "ExtBoundCond" in "Surfaces" table in SQL simulation results
        query_base_surf_idx = "SELECT BaseSurfaceIndex FROM Surfaces WHERE SurfaceName='#{wall_id}'"
        query_ext_bound = "SELECT ExtBoundCond FROM Surfaces WHERE SurfaceName='#{wall_id}'"
        sql_value_base_surf_idx = sqlFile.execAndReturnFirstDouble(query_base_surf_idx).get
        sql_value_ext_bound_cond = sqlFile.execAndReturnFirstDouble(query_ext_bound).get
        assert_equal(sql_value_base_surf_idx, sql_value_ext_bound_cond)
      end

      if wall.is_exterior
        table_name = 'Opaque Exterior'
      else
        table_name = 'Opaque Interior'
      end

      # R-value
      if (not wall.insulation_assembly_r_value.nil?) && (not hpxml_path.include? 'base-foundation-unconditioned-basement-assembly-r.xml') # This file uses Foundation:Kiva for insulation, so skip it
        hpxml_value = wall.insulation_assembly_r_value
        if hpxml_path.include? 'ASHRAE_Standard_140'
          # Compare R-value w/o film
          hpxml_value -= Material.AirFilmVerticalASHRAE140.rvalue
          if wall.is_exterior
            hpxml_value -= Material.AirFilmOutsideASHRAE140.rvalue
          else
            hpxml_value -= Material.AirFilmVerticalASHRAE140.rvalue
          end
          query = "SELECT AVG(Value) FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='#{table_name}' AND (RowName='#{wall_id}' OR RowName LIKE '#{wall_id}:%') AND ColumnName='U-Factor no Film' AND Units='W/m2-K'"
        elsif wall.is_interior
          # Compare R-value w/o film
          hpxml_value -= Material.AirFilmVertical.rvalue
          hpxml_value -= Material.AirFilmVertical.rvalue
          query = "SELECT AVG(Value) FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='#{table_name}' AND (RowName='#{wall_id}' OR RowName LIKE '#{wall_id}:%') AND ColumnName='U-Factor no Film' AND Units='W/m2-K'"
        else
          # Compare R-value w/ film
          query = "SELECT AVG(Value) FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='#{table_name}' AND (RowName='#{wall_id}' OR RowName LIKE '#{wall_id}:%') AND ColumnName='U-Factor with Film' AND Units='W/m2-K'"
        end
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
      if (hpxml.foundation_walls.include? wall) && (not wall.is_exterior)
        # interzonal foundation walls: only above-grade portion modeled
        hpxml_value *= (wall.height - wall.depth_below_grade) / wall.height
      end
      if wall.is_exterior
        query = "SELECT SUM(Value) FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='#{table_name}' AND (RowName='#{wall_id}' OR RowName LIKE '#{wall_id}:%' OR RowName LIKE '#{wall_id} %') AND ColumnName='Net Area' AND Units='m2'"
      else
        query = "SELECT SUM(Value) FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='#{table_name}' AND (RowName='#{wall_id}' OR RowName LIKE '#{wall_id}:%') AND ColumnName='Net Area' AND Units='m2'"
      end
      sql_value = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, 'm^2', 'ft^2')
      assert_operator(sql_value, :>, 0.01)
      assert_in_epsilon(hpxml_value, sql_value, 0.01)

      # Solar absorptance
      if wall.respond_to? :solar_absorptance
        hpxml_value = wall.solar_absorptance
        query = "SELECT AVG(Value) FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='#{table_name}' AND (RowName='#{wall_id}' OR RowName LIKE '#{wall_id}:%') AND ColumnName='Reflectance'"
        sql_value = 1.0 - sqlFile.execAndReturnFirstDouble(query).get
        assert_in_epsilon(hpxml_value, sql_value, 0.01)
      end

      # Tilt
      query = "SELECT AVG(Value) FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='#{table_name}' AND (RowName='#{wall_id}' OR RowName LIKE '#{wall_id}:%') AND ColumnName='Tilt' AND Units='deg'"
      sql_value = sqlFile.execAndReturnFirstDouble(query).get
      assert_in_epsilon(90.0, sql_value, 0.01)

      # Azimuth
      next if wall.azimuth.nil?

      hpxml_value = wall.azimuth
      query = "SELECT AVG(Value) FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='#{table_name}' AND (RowName='#{wall_id}' OR RowName LIKE '#{wall_id}:%') AND ColumnName='Azimuth' AND Units='deg'"
      sql_value = sqlFile.execAndReturnFirstDouble(query).get
      assert_in_epsilon(hpxml_value, sql_value, 0.01)
    end

    # Enclosure FrameFloors
    hpxml.frame_floors.each do |frame_floor|
      frame_floor_id = frame_floor.id.upcase

      if frame_floor.is_adiabatic
        # Adiabatic surfaces have their "BaseSurfaceIndex" as their "ExtBoundCond" in "Surfaces" table in SQL simulation results
        query_base_surf_idx = "SELECT BaseSurfaceIndex FROM Surfaces WHERE SurfaceName='#{frame_floor_id}'"
        query_ext_bound = "SELECT ExtBoundCond FROM Surfaces WHERE SurfaceName='#{frame_floor_id}'"
        sql_value_base_surf_idx = sqlFile.execAndReturnFirstDouble(query_base_surf_idx).get
        sql_value_ext_bound_cond = sqlFile.execAndReturnFirstDouble(query_ext_bound).get
        assert_equal(sql_value_base_surf_idx, sql_value_ext_bound_cond)
      end

      if frame_floor.is_exterior
        table_name = 'Opaque Exterior'
      else
        table_name = 'Opaque Interior'
      end

      # R-value
      hpxml_value = frame_floor.insulation_assembly_r_value
      if hpxml_path.include? 'ASHRAE_Standard_140'
        # Compare R-value w/o film
        if frame_floor.is_exterior # Raised floor
          hpxml_value -= Material.AirFilmFloorASHRAE140.rvalue
          hpxml_value -= Material.AirFilmFloorZeroWindASHRAE140.rvalue
        elsif frame_floor.is_ceiling # Attic floor
          hpxml_value -= Material.AirFilmFloorASHRAE140.rvalue
          hpxml_value -= Material.AirFilmFloorASHRAE140.rvalue
        end
        query = "SELECT AVG(Value) FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='#{table_name}' AND RowName='#{frame_floor_id}' AND ColumnName='U-Factor no Film' AND Units='W/m2-K'"
      elsif frame_floor.is_interior
        # Compare R-value w/o film
        if frame_floor.is_ceiling
          hpxml_value -= Material.AirFilmFloorAverage.rvalue
          hpxml_value -= Material.AirFilmFloorAverage.rvalue
        else
          hpxml_value -= Material.AirFilmFloorReduced.rvalue
          hpxml_value -= Material.AirFilmFloorReduced.rvalue
        end
        query = "SELECT AVG(Value) FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='#{table_name}' AND RowName='#{frame_floor_id}' AND ColumnName='U-Factor no Film' AND Units='W/m2-K'"
      else
        # Compare R-value w/ film
        query = "SELECT AVG(Value) FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='#{table_name}' AND RowName='#{frame_floor_id}' AND ColumnName='U-Factor with Film' AND Units='W/m2-K'"
      end
      sql_value = 1.0 / UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, 'W/(m^2*K)', 'Btu/(hr*ft^2*F)')
      assert_in_epsilon(hpxml_value, sql_value, 0.03)

      # Area
      hpxml_value = frame_floor.area
      query = "SELECT SUM(Value) FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='#{table_name}' AND RowName='#{frame_floor_id}' AND ColumnName='Net Area' AND Units='m2'"
      sql_value = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, 'm^2', 'ft^2')
      assert_operator(sql_value, :>, 0.01)
      assert_in_epsilon(hpxml_value, sql_value, 0.01)

      # Tilt
      if frame_floor.is_ceiling
        hpxml_value = 0
      else
        hpxml_value = 180
      end
      query = "SELECT AVG(Value) FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='#{table_name}' AND RowName='#{frame_floor_id}' AND ColumnName='Tilt' AND Units='deg'"
      sql_value = sqlFile.execAndReturnFirstDouble(query).get
      assert_in_epsilon(hpxml_value, sql_value, 0.01)
    end

    # Enclosure Windows/Skylights
    (hpxml.windows + hpxml.skylights).each do |subsurface|
      subsurface_id = subsurface.id.upcase

      if subsurface.is_exterior
        table_name = 'Exterior Fenestration'
      else
        table_name = 'Interior Door'
      end

      # Area
      if subsurface.is_exterior
        col_name = 'Area of Multiplied Openings'
      else
        col_name = 'Gross Area'
      end
      hpxml_value = subsurface.area
      query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='#{table_name}' AND RowName='#{subsurface_id}' AND ColumnName='#{col_name}' AND Units='m2'"
      sql_value = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, 'm^2', 'ft^2')
      assert_operator(sql_value, :>, 0.01)
      assert_in_epsilon(hpxml_value, sql_value, 0.02)

      # U-Factor
      if subsurface.is_exterior
        col_name = 'Glass U-Factor'
      else
        col_name = 'U-Factor no Film'
      end
      hpxml_value = subsurface.ufactor
      if subsurface.is_interior
        hpxml_value = 1.0 / (1.0 / hpxml_value - Material.AirFilmVertical.rvalue)
        hpxml_value = 1.0 / (1.0 / hpxml_value - Material.AirFilmVertical.rvalue)
      end
      query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='#{table_name}' AND RowName='#{subsurface_id}' AND ColumnName='#{col_name}' AND Units='W/m2-K'"
      sql_value = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, 'W/(m^2*K)', 'Btu/(hr*ft^2*F)')
      if subsurface.is_a? HPXML::Skylight
        sql_value *= 1.2 # Convert back from vertical position to NFRC 20-degree slope
      end
      assert_in_epsilon(hpxml_value, sql_value, 0.02)

      next unless subsurface.is_exterior

      # SHGC
      hpxml_value = subsurface.shgc
      query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='#{table_name}' AND RowName='#{subsurface_id}' AND ColumnName='Glass SHGC'"
      sql_value = sqlFile.execAndReturnFirstDouble(query).get
      assert_in_delta(hpxml_value, sql_value, 0.01)

      # Azimuth
      hpxml_value = subsurface.azimuth
      query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='#{table_name}' AND RowName='#{subsurface_id}' AND ColumnName='Azimuth' AND Units='deg'"
      sql_value = sqlFile.execAndReturnFirstDouble(query).get
      assert_in_epsilon(hpxml_value, sql_value, 0.01)

      # Tilt
      if subsurface.respond_to? :wall_idref
        query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='#{table_name}' AND RowName='#{subsurface_id}' AND ColumnName='Tilt' AND Units='deg'"
        sql_value = sqlFile.execAndReturnFirstDouble(query).get
        assert_in_epsilon(90.0, sql_value, 0.01)
      elsif subsurface.respond_to? :roof_idref
        hpxml_value = nil
        hpxml.roofs.each do |roof|
          next if roof.id != subsurface.roof_idref

          hpxml_value = UnitConversions.convert(Math.atan(roof.pitch / 12.0), 'rad', 'deg')
        end
        query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='#{table_name}' AND RowName='#{subsurface_id}' AND ColumnName='Tilt' AND Units='deg'"
        sql_value = sqlFile.execAndReturnFirstDouble(query).get
        assert_in_epsilon(hpxml_value, sql_value, 0.01)
      else
        flunk "Subsurface '#{subsurface_id}' should have either AttachedToWall or AttachedToRoof element."
      end
    end

    # Enclosure Doors
    hpxml.doors.each do |door|
      door_id = door.id.upcase

      if door.wall.is_exterior
        table_name = 'Exterior Door'
      else
        table_name = 'Interior Door'
      end

      # Area
      if not door.area.nil?
        hpxml_value = door.area
        query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='#{table_name}' AND RowName='#{door_id}' AND ColumnName='Gross Area' AND Units='m2'"
        sql_value = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, 'm^2', 'ft^2')
        assert_operator(sql_value, :>, 0.01)
        assert_in_epsilon(hpxml_value, sql_value, 0.01)
      end

      # R-Value
      next if door.r_value.nil?

      if door.is_exterior
        col_name = 'U-Factor with Film'
      else
        col_name = 'U-Factor no Film'
      end
      hpxml_value = door.r_value
      if door.is_interior
        hpxml_value -= Material.AirFilmVertical.rvalue
        hpxml_value -= Material.AirFilmVertical.rvalue
      end
      query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='#{table_name}' AND RowName='#{door_id}' AND ColumnName='#{col_name}' AND Units='W/m2-K'"
      sql_value = 1.0 / UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, 'W/(m^2*K)', 'Btu/(hr*ft^2*F)')
      assert_in_epsilon(hpxml_value, sql_value, 0.02)
    end

    # HVAC Heating Systems
    num_htg_sys = hpxml.heating_systems.size
    hpxml.heating_systems.each do |heating_system|
      htg_sys_type = heating_system.heating_system_type
      htg_sys_fuel = heating_system.heating_system_fuel

      next unless heating_system.fraction_heat_load_served > 0

      # Electric Auxiliary Energy
      # For now, skip if multiple equipment
      next unless (num_htg_sys == 1) && [HPXML::HVACTypeFurnace, HPXML::HVACTypeBoiler, HPXML::HVACTypeWallFurnace, HPXML::HVACTypeFloorFurnace, HPXML::HVACTypeStove].include?(htg_sys_type) && (htg_sys_fuel != HPXML::FuelTypeElectricity)

      if not heating_system.electric_auxiliary_energy.nil?
        hpxml_value = heating_system.electric_auxiliary_energy / 2.08
      else
        furnace_capacity_kbtuh = nil
        if htg_sys_type == HPXML::HVACTypeFurnace
          furnace_capacity_kbtuh = UnitConversions.convert(results['Capacity: Heating (W)'], 'W', 'kBtu/hr')
        end
        hpxml_value = HVAC.get_electric_auxiliary_energy(heating_system, furnace_capacity_kbtuh) / 2.08
      end

      if htg_sys_type == HPXML::HVACTypeBoiler
        next if hpxml.water_heating_systems.select { |wh| [HPXML::WaterHeaterTypeCombiStorage, HPXML::WaterHeaterTypeCombiTankless].include? wh.water_heater_type }.size > 0 # Skip combi systems

        # Compare pump power from timeseries output
        query = "SELECT VariableValue FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex IN (SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE VariableType='Avg' AND VariableName='Boiler Part Load Ratio' AND ReportingFrequency='Run Period')"
        avg_plr = sqlFile.execAndReturnFirstDouble(query).get
        query = "SELECT VariableValue FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex IN (SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE VariableType='Avg' AND VariableName='Pump Electricity Rate' AND ReportingFrequency='Run Period')"
        avg_w = sqlFile.execAndReturnFirstDouble(query).get
        sql_value = avg_w / avg_plr
        assert_in_epsilon(sql_value, hpxml_value, 0.05)
      else
        next if hpxml.cooling_systems.size + hpxml.heat_pumps.size > 0 # Skip if other system types (which could result in A) multiple supply fans or B) different supply fan power consumption in the cooling season)

        # Compare fan power from timeseries output
        query = "SELECT VariableValue FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex IN (SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE VariableType='Avg' AND VariableName='Fan Runtime Fraction' and KeyValue LIKE '% SUPPLY FAN' AND ReportingFrequency='Run Period')"
        avg_rtf = sqlFile.execAndReturnFirstDouble(query).get
        query = "SELECT VariableValue FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex IN (SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE VariableType='Avg' AND VariableName='Fan Electricity Rate' and KeyValue LIKE '% SUPPLY FAN' AND ReportingFrequency='Run Period')"
        avg_w = sqlFile.execAndReturnFirstDouble(query).get
        sql_value = avg_w / avg_rtf
        assert_in_epsilon(sql_value, hpxml_value, 0.05)
      end
    end

    # HVAC Heat Pumps
    num_hps = hpxml.heat_pumps.size
    hpxml.heat_pumps.each do |heat_pump|
      next unless heat_pump.fraction_heat_load_served > 0
      next unless (num_hps == 1) && heat_pump.heat_pump_type == HPXML::HVACTypeHeatPumpGroundToAir

      # Compare pump power from timeseries output
      hpxml_value = heat_pump.pump_watts_per_ton * UnitConversions.convert(results['Capacity: Cooling (W)'], 'W', 'ton')
      query = "SELECT VariableValue FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex IN (SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE VariableType='Avg' AND VariableName='Unitary System Part Load Ratio' AND ReportingFrequency='Run Period')"
      avg_plr = sqlFile.execAndReturnFirstDouble(query).get
      query = "SELECT VariableValue FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex IN (SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE VariableType='Avg' AND VariableName='Pump Electricity Rate' AND ReportingFrequency='Run Period')"
      avg_w = sqlFile.execAndReturnFirstDouble(query).get
      sql_value = avg_w / avg_plr
      assert_in_epsilon(sql_value, hpxml_value, 0.05)
    end

    # HVAC Capacities
    htg_cap = nil
    clg_cap = nil
    hpxml.heating_systems.each do |heating_system|
      htg_sys_cap = heating_system.heating_capacity.to_f
      if htg_sys_cap > 0
        htg_cap = 0 if htg_cap.nil?
        htg_cap += htg_sys_cap
      end
    end
    hpxml.cooling_systems.each do |cooling_system|
      clg_sys_cap = cooling_system.cooling_capacity.to_f
      clg_cap_mult = 1.0
      if cooling_system.cooling_system_type == HPXML::HVACTypeMiniSplitAirConditioner
        # TODO: Generalize this
        clg_cap_mult = 1.20
      end
      if clg_sys_cap > 0
        clg_cap = 0 if clg_cap.nil?
        clg_cap += (clg_sys_cap * clg_cap_mult)
      end
    end
    hpxml.heat_pumps.each do |heat_pump|
      hp_cap_clg = heat_pump.cooling_capacity.to_f
      hp_cap_htg = heat_pump.heating_capacity.to_f
      clg_cap_mult = 1.0
      htg_cap_mult = 1.0
      if heat_pump.heat_pump_type == HPXML::HVACTypeHeatPumpMiniSplit
        # TODO: Generalize this
        clg_cap_mult = 1.20
        htg_cap_mult = 1.20
      elsif (heat_pump.heat_pump_type == HPXML::HVACTypeHeatPumpAirToAir) && (heat_pump.cooling_efficiency_seer > 21)
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
        if hpxml.header.allow_increased_fixed_capacities
          assert_operator(sql_value, :>=, clg_cap)
        else
          assert_in_epsilon(clg_cap, sql_value, 0.01)
        end
      else # autosized
        assert_operator(sql_value, :>, 1)
      end
    end
    if not htg_cap.nil?
      sql_value = UnitConversions.convert(results['Capacity: Heating (W)'], 'W', 'Btu/hr')
      if htg_cap == 0
        assert_operator(sql_value, :<, 1)
      elsif htg_cap > 0
        if hpxml.header.allow_increased_fixed_capacities
          assert_operator(sql_value, :>=, htg_cap)
        else
          assert_in_epsilon(htg_cap, sql_value, 0.01)
        end
      else # autosized
        assert_operator(sql_value, :>, 1)
      end
    end

    # HVAC Load Fractions
    if not hpxml_path.include? 'location-miami'
      htg_energy = results.select { |k, v| (k.include?(': Heating (MBtu)') || k.include?(': Heating Fans/Pumps (MBtu)')) && !k.include?('Load') }.map { |k, v| v }.sum(0.0)
      assert_equal(hpxml.total_fraction_heat_load_served > 0, htg_energy > 0)
    end
    clg_energy = results.select { |k, v| (k.include?(': Cooling (MBtu)') || k.include?(': Cooling Fans/Pumps (MBtu)')) && !k.include?('Load') }.map { |k, v| v }.sum(0.0)
    assert_equal(hpxml.total_fraction_cool_load_served > 0, clg_energy > 0)

    # Water Heater
    if hpxml.water_heating_systems.select { |wh| [HPXML::WaterHeaterTypeCombiStorage, HPXML::WaterHeaterTypeCombiTankless].include? wh.water_heater_type }.size > 0
      query = "SELECT SUM(ABS(VariableValue)/1000000000) FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex IN (SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE VariableType='Sum' AND VariableName='Fluid Heat Exchanger Heat Transfer Energy' AND ReportingFrequency='Run Period' AND VariableUnits='J')"
      combi_hx_load = sqlFile.execAndReturnFirstDouble(query).get.round(2)
      query = "SELECT SUM(ABS(VariableValue)/1000000000) FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex IN (SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE VariableType='Sum' AND VariableName='Boiler Heating Energy' AND ReportingFrequency='Run Period' AND VariableUnits='J')"
      combi_htg_load = sqlFile.execAndReturnFirstDouble(query).get.round(2)

      # Check combi system energy balance
      query = "SELECT SUM(ABS(VariableValue)/1000000000) FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex IN (SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE VariableType='Sum' AND VariableName='Water Heater Source Side Heat Transfer Energy' AND VariableUnits='J')"
      combi_tank_source_load = sqlFile.execAndReturnFirstDouble(query).get.round(2)
      assert_in_epsilon(combi_hx_load, combi_tank_source_load, 0.02)

      # Check boiler, hx, pump, heating coil energy balance
      query = "SELECT SUM(ABS(VariableValue)/1000000000) FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex IN (SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE VariableType='Sum' AND VariableName='Baseboard Total Heating Energy' AND VariableUnits='J')"
      boiler_space_heating_load = sqlFile.execAndReturnFirstDouble(query).get.round(2)
      assert_in_epsilon(combi_hx_load + boiler_space_heating_load, combi_htg_load, 0.02)
    end

    # Mechanical Ventilation
    fan_cfis = hpxml.ventilation_fans.select { |vent_mech| vent_mech.used_for_whole_building_ventilation && (vent_mech.fan_type == HPXML::MechVentTypeCFIS) }
    fan_sup = hpxml.ventilation_fans.select { |vent_mech| vent_mech.used_for_whole_building_ventilation && (vent_mech.fan_type == HPXML::MechVentTypeSupply) }
    fan_exh = hpxml.ventilation_fans.select { |vent_mech| vent_mech.used_for_whole_building_ventilation && (vent_mech.fan_type == HPXML::MechVentTypeExhaust) }
    fan_bal = hpxml.ventilation_fans.select { |vent_mech| vent_mech.used_for_whole_building_ventilation && [HPXML::MechVentTypeBalanced, HPXML::MechVentTypeERV, HPXML::MechVentTypeHRV].include?(vent_mech.fan_type) }
    vent_fan_kitchen = hpxml.ventilation_fans.select { |vent_mech| vent_mech.used_for_local_ventilation && (vent_mech.fan_location == HPXML::LocationKitchen) }
    vent_fan_bath = hpxml.ventilation_fans.select { |vent_mech| vent_mech.used_for_local_ventilation && (vent_mech.fan_location == HPXML::LocationBath) }

    if not (fan_cfis + fan_sup + fan_exh + fan_bal + vent_fan_kitchen + vent_fan_bath).empty?
      mv_energy = UnitConversions.convert(results['Electricity: Mech Vent (MBtu)'], 'MBtu', 'GJ')

      if not fan_cfis.empty?
        # CFIS, check for positive mech vent energy that is less than the energy if it had run 24/7
        # CFIS Fan energy
        query = "SELECT SUM(ABS(VariableValue)/1000000000) FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex IN (SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE VariableType='Sum' AND KeyValue LIKE '#{Constants.ObjectNameMechanicalVentilationHouseFanCFIS.upcase}%' AND VariableName='Electric Equipment Electricity Energy' AND ReportingFrequency='Run Period' AND VariableUnits='J')"
        cfis_energy = sqlFile.execAndReturnFirstDouble(query).get
        fan_gj = fan_cfis.map { |vent_mech| UnitConversions.convert(vent_mech.unit_fan_power * vent_mech.hours_in_operation * 365.0, 'Wh', 'GJ') }.sum(0.0)
        if fan_gj > 0
          assert_operator(cfis_energy, :>, 0)
          assert_operator(cfis_energy, :<, fan_gj)
        else
          assert_equal(cfis_energy, 0.0)
        end

        mv_energy -= cfis_energy
      end

      # Supply, exhaust, ERV, HRV, etc., check for appropriate mech vent energy
      fan_gj = 0
      if not fan_sup.empty?
        fan_gj += fan_sup.map { |vent_mech| UnitConversions.convert(vent_mech.unit_fan_power * vent_mech.hours_in_operation * 365.0, 'Wh', 'GJ') }.sum(0.0)
      end
      if not fan_exh.empty?
        fan_gj += fan_exh.map { |vent_mech| UnitConversions.convert(vent_mech.unit_fan_power * vent_mech.hours_in_operation * 365.0, 'Wh', 'GJ') }.sum(0.0)
      end
      if not fan_bal.empty?
        fan_gj += fan_bal.map { |vent_mech| UnitConversions.convert(vent_mech.unit_fan_power * vent_mech.hours_in_operation * 365.0, 'Wh', 'GJ') }.sum(0.0)
      end
      if not vent_fan_kitchen.empty?
        fan_gj += vent_fan_kitchen.map { |vent_kitchen| UnitConversions.convert(vent_kitchen.unit_fan_power * vent_kitchen.hours_in_operation * vent_kitchen.quantity * 365.0, 'Wh', 'GJ') }.sum(0.0)
      end
      if not vent_fan_bath.empty?
        fan_gj += vent_fan_bath.map { |vent_bath| UnitConversions.convert(vent_bath.unit_fan_power * vent_bath.hours_in_operation * vent_bath.quantity * 365.0, 'Wh', 'GJ') }.sum(0.0)
      end
      # Maximum error that can be caused by rounding
      assert_in_delta(mv_energy, fan_gj, 0.006)
    end

    # Clothes Washer
    if (hpxml.clothes_washers.size > 0) && (hpxml.water_heating_systems.size > 0)
      # Location
      hpxml_value = hpxml.clothes_washers[0].location
      if hpxml_value.nil? || [HPXML::LocationBasementConditioned, HPXML::LocationOtherHousingUnit, HPXML::LocationOtherHeatedSpace, HPXML::LocationOtherMultifamilyBufferSpace, HPXML::LocationOtherNonFreezingSpace].include?(hpxml_value)
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
      if hpxml_value.nil? || [HPXML::LocationBasementConditioned, HPXML::LocationOtherHousingUnit, HPXML::LocationOtherHeatedSpace, HPXML::LocationOtherMultifamilyBufferSpace, HPXML::LocationOtherNonFreezingSpace].include?(hpxml_value)
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
      if hpxml_value.nil? || [HPXML::LocationBasementConditioned, HPXML::LocationOtherHousingUnit, HPXML::LocationOtherHeatedSpace, HPXML::LocationOtherMultifamilyBufferSpace, HPXML::LocationOtherNonFreezingSpace].include?(hpxml_value)
        hpxml_value = HPXML::LocationLivingSpace
      end
      query = "SELECT Value FROM TabularDataWithStrings WHERE TableName='ElectricEquipment Internal Gains Nominal' AND ColumnName='Zone Name' AND RowName=(SELECT RowName FROM TabularDataWithStrings WHERE TableName='ElectricEquipment Internal Gains Nominal' AND ColumnName='Name' AND Value='#{Constants.ObjectNameRefrigerator.upcase}')"
      sql_value = sqlFile.execAndReturnFirstString(query).get
      assert_equal(hpxml_value.upcase, sql_value)
    end

    # DishWasher
    if (hpxml.dishwashers.size > 0) && (hpxml.water_heating_systems.size > 0)
      # Location
      hpxml_value = hpxml.dishwashers[0].location
      if hpxml_value.nil? || [HPXML::LocationBasementConditioned, HPXML::LocationOtherHousingUnit, HPXML::LocationOtherHeatedSpace, HPXML::LocationOtherMultifamilyBufferSpace, HPXML::LocationOtherNonFreezingSpace].include?(hpxml_value)
        hpxml_value = HPXML::LocationLivingSpace
      end
      query = "SELECT Value FROM TabularDataWithStrings WHERE TableName='ElectricEquipment Internal Gains Nominal' AND ColumnName='Zone Name' AND RowName=(SELECT RowName FROM TabularDataWithStrings WHERE TableName='ElectricEquipment Internal Gains Nominal' AND ColumnName='Name' AND Value='#{Constants.ObjectNameDishwasher.upcase}')"
      sql_value = sqlFile.execAndReturnFirstString(query).get
      assert_equal(hpxml_value.upcase, sql_value)
    end

    # Cooking Range
    if hpxml.cooking_ranges.size > 0
      # Location
      hpxml_value = hpxml.cooking_ranges[0].location
      if hpxml_value.nil? || [HPXML::LocationBasementConditioned, HPXML::LocationOtherHousingUnit, HPXML::LocationOtherHeatedSpace, HPXML::LocationOtherMultifamilyBufferSpace, HPXML::LocationOtherNonFreezingSpace].include?(hpxml_value)
        hpxml_value = HPXML::LocationLivingSpace
      end
      query = "SELECT Value FROM TabularDataWithStrings WHERE TableName='ElectricEquipment Internal Gains Nominal' AND ColumnName='Zone Name' AND RowName=(SELECT RowName FROM TabularDataWithStrings WHERE TableName='ElectricEquipment Internal Gains Nominal' AND ColumnName='Name' AND Value='#{Constants.ObjectNameCookingRange.upcase}')"
      sql_value = sqlFile.execAndReturnFirstString(query).get
      assert_equal(hpxml_value.upcase, sql_value)
    end

    # Lighting
    ltg_energy = results.select { |k, v| k.include? 'Electricity: Lighting' }.map { |k, v| v }.sum(0.0)
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
     HPXML::FuelTypeKerosene,
     HPXML::FuelTypePropane,
     HPXML::FuelTypeWoodCord,
     HPXML::FuelTypeWoodPellets,
     HPXML::FuelTypeCoal].each do |fuel|
      fuel_name = fuel.split.map(&:capitalize).join(' ')
      fuel_name += ' Cord' if fuel_name == 'Wood'
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

  def _write_and_check_ashrae_140_results(results_dir, all_results, ashrae_140_dir)
    require 'csv'
    csv_out = File.join(results_dir, 'results_ashrae_140.csv')

    htg_loads = {}
    clg_loads = {}
    CSV.open(csv_out, 'w') do |csv|
      csv << ['Test Case', 'Annual Heating Load [MMBtu]', 'Annual Cooling Load [MMBtu]']
      all_results.sort.each do |xml, xml_results|
        next unless xml.include? ashrae_140_dir
        next unless xml.include? 'C.xml'

        htg_load = xml_results['Load: Heating (MBtu)'].round(2)
        csv << [File.basename(xml), htg_load, 'N/A']
        test_name = File.basename(xml, File.extname(xml))
        htg_loads[test_name] = htg_load
      end
      all_results.sort.each do |xml, xml_results|
        next unless xml.include? ashrae_140_dir
        next unless xml.include? 'L.xml'

        clg_load = xml_results['Load: Cooling (MBtu)'].round(2)
        csv << [File.basename(xml), 'N/A', clg_load]
        test_name = File.basename(xml, File.extname(xml))
        clg_loads[test_name] = clg_load
      end
    end

    puts "Wrote ASHRAE 140 results to #{csv_out}."

    # TODO: Add updated HERS acceptance criteria once the E+ simple
    # window model bugfix is available.
    # FUTURE: Switch to stringent HERS acceptance criteria once it's based on
    # TMY3.
  end

  def _display_result_epsilon(xml, result1, result2, key)
    epsilon = (result1 - result2).abs / [result1, result2].min
    puts "#{xml}: epsilon=#{epsilon.round(5)} [#{key}]"
  end

  def _display_result_delta(xml, result1, result2, key)
    delta = (result1 - result2).abs
    puts "#{xml}: delta=#{delta.round(5)} [#{key}]"
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
