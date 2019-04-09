require_relative 'minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'
require 'json'
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
    hvac_dse_dir = File.absolute_path(File.join(this_dir, "hvac_dse"))
    hvac_multiple_dir = File.absolute_path(File.join(this_dir, "hvac_multiple"))
    hvac_partial_dir = File.absolute_path(File.join(this_dir, "hvac_partial"))
    hvac_load_fracs_dir = File.absolute_path(File.join(this_dir, "hvac_load_fracs"))
    water_heating_multiple_dir = File.absolute_path(File.join(this_dir, "water_heating_multiple"))
    autosize_dir = File.absolute_path(File.join(this_dir, "hvac_autosizing"))

    test_dirs = [this_dir,
                 cfis_dir,
                 hvac_dse_dir,
                 hvac_multiple_dir,
                 hvac_partial_dir,
                 hvac_load_fracs_dir,
                 water_heating_multiple_dir,
                 autosize_dir]

    xmls = []
    test_dirs.each do |test_dir|
      Dir["#{test_dir}/valid*.xml"].sort.each do |xml|
        next if File.basename(xml) == "valid-hvac-multiple.xml" # TODO: Remove when HVAC sizing has been updated

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
    _test_dse(xmls, hvac_dse_dir, all_results)
    _test_multiple_hvac(xmls, hvac_multiple_dir, all_results)
    _test_multiple_water_heaters(xmls, water_heating_multiple_dir, all_results)
    _test_partial_hvac(xmls, hvac_partial_dir, all_results)
  end

  def test_invalid
    this_dir = File.dirname(__FILE__)

    args = {}
    args['weather_dir'] = File.absolute_path(File.join(this_dir, "..", "weather"))
    args['skip_validation'] = false

    expected_error_msgs = { 'invalid-bad-wmo.xml' => ["Weather station WMO '999999' could not be found in weather/data.csv."],
                            'invalid-missing-elements.xml' => ["Expected [1] element(s) but found 0 element(s) for xpath: /HPXML/Building/BuildingDetails/BuildingSummary/BuildingConstruction/NumberofConditionedFloors",
                                                               "Expected [1] element(s) but found 0 element(s) for xpath: /HPXML/Building/BuildingDetails/BuildingSummary/BuildingConstruction/ConditionedFloorArea"],
                            'invalid-hvac-frac-load-served.xml' => ["Expected FractionCoolLoadServed to sum to 1, but calculated sum is 1.2.",
                                                                    "Expected FractionHeatLoadServed to sum to 1, but calculated sum is 1.1."],
                            'invalid-missing-surfaces.xml' => ["Thermal zone 'garage' must have at least one floor surface.",
                                                               "Thermal zone 'garage' must have at least one roof/ceiling surface.",
                                                               "Thermal zone 'garage' must have at least one surface adjacent to outside/ground."],
                            'invalid-net-area-negative-wall.xml' => ["Calculated a negative net surface area for Wall 'agwall-1'."],
                            'invalid-net-area-negative-roof.xml' => ["Calculated a negative net surface area for Roof 'attic-roof-1'."],
                            'invalid-unattached-window.xml' => ["Attached wall 'foobar' not found for window 'Window_ID1'."],
                            'invalid-unattached-door.xml' => ["Attached wall 'foobar' not found for door 'Door_ID1'."],
                            'invalid-unattached-skylight.xml' => ["Attached roof 'foobar' not found for skylight 'Skylight_ID1'."],
                            'invalid-unattached-hvac.xml' => ["TODO"],
                            'invalid-unattached-cfis.xml' => ["TODO"] }

    # Test simulations
    Dir["#{this_dir}/invalid*.xml"].sort.each do |xml|
      _run_xml(xml, this_dir, args.dup, true, expected_error_msgs[File.basename(xml)])
    end
  end

  def _run_xml(xml, this_dir, args, expect_error = false, expect_error_msgs = nil)
    print "Testing #{File.basename(xml)}...\n"
    rundir = File.join(this_dir, "run")
    args['epw_output_path'] = File.absolute_path(File.join(rundir, "in.epw"))
    args['osm_output_path'] = File.absolute_path(File.join(rundir, "in.osm"))
    args['hpxml_path'] = xml
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

    # Disaggregate any crankcase and defrost energy from results (for DSE tests)
    query = "SELECT SUM(Value)/1000000000 FROM ReportData WHERE ReportDataDictionaryIndex IN (SELECT ReportDataDictionaryIndex FROM ReportDataDictionary WHERE Name='Cooling Coil Crankcase Heater Electric Energy')"
    sql_value = sqlFile.execAndReturnFirstDouble(query)
    if sql_value.is_initialized
      cooling_crankcase = sql_value.get
      if cooling_crankcase > 0
        results[["Electricity", "Cooling", "General", "GJ"]] -= cooling_crankcase
        results[["Electricity", "Cooling", "Crankcase", "GJ"]] = cooling_crankcase
      end
    end
    query = "SELECT SUM(Value)/1000000000 FROM ReportData WHERE ReportDataDictionaryIndex IN (SELECT ReportDataDictionaryIndex FROM ReportDataDictionary WHERE Name='Heating Coil Crankcase Heater Electric Energy')"
    sql_value = sqlFile.execAndReturnFirstDouble(query)
    if sql_value.is_initialized
      heating_crankcase = sql_value.get
      if heating_crankcase > 0
        results[["Electricity", "Heating", "General", "GJ"]] -= heating_crankcase
        results[["Electricity", "Heating", "Crankcase", "GJ"]] = heating_crankcase
      end
    end
    query = "SELECT SUM(Value)/1000000000 FROM ReportData WHERE ReportDataDictionaryIndex IN (SELECT ReportDataDictionaryIndex FROM ReportDataDictionary WHERE Name='Heating Coil Defrost Electric Energy')"
    sql_value = sqlFile.execAndReturnFirstDouble(query)
    if sql_value.is_initialized
      heating_defrost = sql_value.get
      if heating_defrost > 0
        results[["Electricity", "Heating", "General", "GJ"]] -= heating_defrost
        results[["Electricity", "Heating", "Defrost", "GJ"]] = heating_defrost
      end
    end

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
    success = apply_measures(measures_dir, measures, runner, model, nil, nil, true)

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

    # Add output variables for crankcase and defrost energy (for DSE tests)
    vars = ["Cooling Coil Crankcase Heater Electric Energy",
            "Heating Coil Crankcase Heater Electric Energy",
            "Heating Coil Defrost Electric Energy"]
    vars.each do |var|
      output_var = OpenStudio::Model::OutputVariable.new(var, model)
      output_var.setReportingFrequency('runperiod')
      output_var.setKeyValue('*')
    end

    # Add output variable for CFIS fan power
    output_var = OpenStudio::Model::OutputVariable.new("res_mv_1_cfis_fan_power", model)
    output_var.setReportingFrequency('runperiod')
    output_var.setKeyValue('EMS')

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
    _verify_simulation_outputs(rundir, args['hpxml_path'], results)

    return results
  end

  def _verify_simulation_outputs(rundir, hpxml_path, results)
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
      assert_in_epsilon(hpxml_value, sql_value, 0.01)
    end

    # Enclosure Roofs
    bldg_details.elements.each('Enclosure/Attics/Attic/Roofs/Roof') do |roof|
      roof_id = roof.elements["SystemIdentifier"].attributes["id"].upcase

      # R-value
      hpxml_value = Float(XMLHelper.get_value(roof, 'Insulation/AssemblyEffectiveRValue'))
      query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='Opaque Exterior' AND RowName='#{roof_id}' AND ColumnName='U-Factor with Film' AND Units='W/m2-K'"
      sql_value = 1.0 / UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, 'W/(m^2*K)', 'Btu/(hr*ft^2*F)')
      assert_in_epsilon(hpxml_value, sql_value, 0.07) # TODO: Higher due to outside air film?

      # Net area
      hpxml_value = Float(XMLHelper.get_value(roof, 'Area'))
      bldg_details.elements.each('Enclosure/Skylights/Skylight') do |subsurface|
        next if subsurface.elements["AttachedToRoof"].attributes["idref"].upcase != roof_id

        hpxml_value -= Float(XMLHelper.get_value(subsurface, 'Area'))
      end
      query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='Opaque Exterior' AND RowName='#{roof_id}' AND ColumnName='Net Area' AND Units='m2'"
      sql_value = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, 'm^2', 'ft^2')
      assert_in_epsilon(hpxml_value, sql_value, 0.01)

      # Solar absorptance
      hpxml_value = Float(XMLHelper.get_value(roof, 'SolarAbsorptance'))
      query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='Opaque Exterior' AND RowName='#{roof_id}' AND ColumnName='Reflectance'"
      sql_value = 1.0 - sqlFile.execAndReturnFirstDouble(query).get
      assert_in_epsilon(hpxml_value, sql_value, 0.01)

      # Tilt
      hpxml_value = UnitConversions.convert(Math.atan(Float(XMLHelper.get_value(roof, "Pitch")) / 12.0), "rad", "deg")
      query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='Opaque Exterior' AND RowName='#{roof_id}' AND ColumnName='Tilt' AND Units='deg'"
      sql_value = sqlFile.execAndReturnFirstDouble(query).get
      assert_in_epsilon(hpxml_value, sql_value, 0.01)

      # Azimuth
      if XMLHelper.has_element(roof, 'Azimuth')
        hpxml_value = Float(XMLHelper.get_value(roof, 'Azimuth'))
        query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='Opaque Exterior' AND RowName='#{roof_id}' AND ColumnName='Azimuth' AND Units='deg'"
        sql_value = sqlFile.execAndReturnFirstDouble(query).get
        assert_in_epsilon(hpxml_value, sql_value, 0.01)
      end
    end

    # Enclosure Foundation Slabs
    bldg_details.elements.each('Enclosure/Foundations/Foundation/Slab') do |slab|
      slab_id = slab.elements["SystemIdentifier"].attributes["id"].upcase

      # Area
      hpxml_value = Float(XMLHelper.get_value(slab, 'Area'))
      query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='Opaque Exterior' AND RowName='#{slab_id}' AND ColumnName='Gross Area' AND Units='m2'"
      sql_value = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, 'm^2', 'ft^2')
      assert_in_epsilon(hpxml_value, sql_value, 0.01)

      # Tilt
      query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='Opaque Exterior' AND RowName='#{slab_id}' AND ColumnName='Tilt' AND Units='deg'"
      sql_value = sqlFile.execAndReturnFirstDouble(query).get
      assert_in_epsilon(180.0, sql_value, 0.01)
    end

    # Enclosure Foundations
    # Ensure the correct number of Kiva instances
    # TODO: Update for multiple foundations and garages.
    # TODO: Update for walkout basements, which use multiple Kiva instances.
    in_kiva_block = false
    num_kiva_instances = 0
    File.readlines(File.join(rundir, "eplusout.eio")).each do |eio_line|
      if eio_line.start_with? "! <Kiva Foundation Name>"
        in_kiva_block = true
        next
      elsif in_kiva_block
        if eio_line.start_with? "! "
          break # done reading
        end

        num_kiva_instances += 1
      end
    end
    if XMLHelper.has_element(bldg_details, "Enclosure/Foundations/Foundation/FoundationType/Ambient")
      assert_equal(0, num_kiva_instances)
    else
      assert_equal(1, num_kiva_instances)
    end

    # Enclosure Walls
    bldg_details.elements.each('Enclosure/Walls/Wall[extension[ExteriorAdjacentTo="outside"]] | Enclosure/Attics/Attic/Walls/Wall[extension[ExteriorAdjacentTo="outside"]]') do |wall|
      wall_id = wall.elements["SystemIdentifier"].attributes["id"].upcase

      # R-value
      hpxml_value = Float(XMLHelper.get_value(wall, 'Insulation/AssemblyEffectiveRValue'))
      query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='Opaque Exterior' AND RowName='#{wall_id}' AND ColumnName='U-Factor with Film' AND Units='W/m2-K'"
      sql_value = 1.0 / UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, 'W/(m^2*K)', 'Btu/(hr*ft^2*F)')
      assert_in_epsilon(hpxml_value, sql_value, 0.03)

      # Net area
      hpxml_value = Float(XMLHelper.get_value(wall, 'Area'))
      bldg_details.elements.each('Enclosure/Windows/Window | Enclosure/Doors/Door') do |subsurface|
        next if subsurface.elements["AttachedToWall"].attributes["idref"].upcase != wall_id

        hpxml_value -= Float(XMLHelper.get_value(subsurface, 'Area'))
      end
      query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='Opaque Exterior' AND RowName='#{wall_id}' AND ColumnName='Net Area' AND Units='m2'"
      sql_value = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, 'm^2', 'ft^2')
      assert_in_epsilon(hpxml_value, sql_value, 0.01)

      # Solar absorptance
      hpxml_value = Float(XMLHelper.get_value(wall, 'SolarAbsorptance'))
      query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='Opaque Exterior' AND RowName='#{wall_id}' AND ColumnName='Reflectance'"
      sql_value = 1.0 - sqlFile.execAndReturnFirstDouble(query).get
      assert_in_epsilon(hpxml_value, sql_value, 0.01)

      # Tilt
      query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='Opaque Exterior' AND RowName='#{wall_id}' AND ColumnName='Tilt' AND Units='deg'"
      sql_value = sqlFile.execAndReturnFirstDouble(query).get
      assert_in_epsilon(90.0, sql_value, 0.01)

      # Azimuth
      if XMLHelper.has_element(wall, 'Azimuth')
        hpxml_value = Float(XMLHelper.get_value(wall, 'Azimuth'))
        query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='Opaque Exterior' AND RowName='#{wall_id}' AND ColumnName='Azimuth' AND Units='deg'"
        sql_value = sqlFile.execAndReturnFirstDouble(query).get
        assert_in_epsilon(hpxml_value, sql_value, 0.01)
      end
    end

    # Enclosure Windows/Skylights
    bldg_details.elements.each('Enclosure/Windows/Window | Enclosure/Skylights/Skylight') do |subsurface|
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
        bldg_details.elements.each('Enclosure/Attics/Attic/Roofs/Roof') do |roof|
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
    bldg_details.elements.each('Enclosure/Doors/Door') do |door|
      door_id = door.elements["SystemIdentifier"].attributes["id"].upcase

      # Area
      hpxml_value = Float(XMLHelper.get_value(door, 'Area'))
      query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='Exterior Door' AND RowName='#{door_id}' AND ColumnName='Gross Area' AND Units='m2'"
      sql_value = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, 'm^2', 'ft^2')
      assert_in_epsilon(hpxml_value, sql_value, 0.01)

      # R-Value
      hpxml_value = Float(XMLHelper.get_value(door, 'RValue'))
      query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='Exterior Door' AND RowName='#{door_id}' AND ColumnName='U-Factor with Film' AND Units='W/m2-K'"
      sql_value = 1.0 / UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, 'W/(m^2*K)', 'Btu/(hr*ft^2*F)')
      assert_in_epsilon(hpxml_value, sql_value, 0.01)
    end

    # HVAC Heating Systems
    num_htg_sys = bldg_details.elements['count(Systems/HVAC/HVACPlant/HeatingSystem)']
    bldg_details.elements.each('Systems/HVAC/HVACPlant/HeatingSystem') do |htg_sys|
      htg_sys_id = htg_sys.elements["SystemIdentifier"].attributes["id"].upcase
      htg_sys_type = XMLHelper.get_child_name(htg_sys, 'HeatingSystemType')
      htg_sys_fuel = to_beopt_fuel(XMLHelper.get_value(htg_sys, 'HeatingSystemFuel'))
      htg_sys_cap = Float(XMLHelper.get_value(htg_sys, "HeatingCapacity"))
      htg_dse = XMLHelper.get_value(bldg_details, 'Systems/HVAC/HVACDistribution/AnnualHeatingDistributionSystemEfficiency')
      if htg_dse.nil?
        htg_dse = 1.0
      else
        htg_dse = Float(htg_dse)
      end
      htg_load_frac = Float(XMLHelper.get_value(htg_sys, "FractionHeatLoadServed"))

      if htg_load_frac <= 0

        # Heating Load Fraction
        # Check for zero heating energy
        found_htg_energy = false
        results.keys.each do |k|
          next unless k[1] == 'Heating'

          found_htg_energy = true
        end
        assert_equal(false, found_htg_energy)

      else

        # Heating Capacity
        # FIXME: For now, skip if multiple equipment
        if htg_sys_cap > 0 and num_htg_sys == 1
          hpxml_value = htg_sys_cap
          if htg_sys_type == 'Boiler'
            query = "SELECT SUM(Value) FROM TabularDataWithStrings WHERE ReportName='ComponentSizingSummary' AND ReportForString='Entire Facility' AND TableName='Boiler:HotWater' AND ColumnName='User-Specified Nominal Capacity' AND Units='W'"
          elsif htg_sys_type == 'ElectricResistance'
            query = "SELECT SUM(Value) FROM TabularDataWithStrings WHERE ReportName='ComponentSizingSummary' AND ReportForString='Entire Facility' AND TableName='ZONEHVAC:BASEBOARD:CONVECTIVE:ELECTRIC' AND ColumnName='User-Specified Heating Design Capacity' AND Units='W'"
          else
            query = "SELECT SUM(Value) FROM TabularDataWithStrings WHERE ReportName='ComponentSizingSummary' AND ReportForString='Entire Facility' AND TableName LIKE 'Coil:Heating:%' AND ColumnName='User-Specified Nominal Capacity' AND Units='W'"
          end
          sql_value = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, 'W', 'Btu/hr')
          assert_in_epsilon(hpxml_value, sql_value, 0.01)
        end

        # Electric Auxiliary Energy
        # FIXME: For now, skip if multiple equipment
        if num_htg_sys == 1 and ['Furnace', 'Boiler', 'WallFurnace', 'Stove'].include? htg_sys_type and htg_sys_fuel != Constants.FuelTypeElectric
          if XMLHelper.has_element(htg_sys, 'ElectricAuxiliaryEnergy')
            hpxml_value = Float(XMLHelper.get_value(htg_sys, 'ElectricAuxiliaryEnergy')) / (2.08 * htg_dse)
          else
            furnace_capacity_kbtuh = nil
            if htg_sys_type == 'Furnace'
              query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EquipmentSummary' AND ReportForString='Entire Facility' AND TableName='Heating Coils' AND RowName LIKE '%#{Constants.ObjectNameFurnace.upcase}%' AND ColumnName='Nominal Total Capacity' AND Units='W'"
              furnace_capacity_kbtuh = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, 'W', 'kBtu/hr')
            end
            hpxml_value = HVAC.get_default_eae(htg_sys_type == 'Boiler', htg_sys_type == 'Furnace', htg_sys_fuel, 1.0, furnace_capacity_kbtuh) / (2.08 * htg_dse)
          end

          if htg_sys_type == 'Boiler'
            query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EquipmentSummary' AND ReportForString='Entire Facility' AND TableName='Pumps' AND RowName LIKE '%#{Constants.ObjectNameBoiler.upcase}%' AND ColumnName='Electric Power' AND Units='W'"
            sql_value = sqlFile.execAndReturnFirstDouble(query).get
          elsif htg_sys_type == 'Furnace'
            # Ratio fan power based on heating airflow rate divided by fan airflow rate since the
            # fan be sized based on cooling.
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

          if htg_sys_type == 'Furnace'
            # Also check supply fan of cooling system as needed
            htg_dist = htg_sys.elements['DistributionSystem']
            bldg_details.elements.each('Systems/HVAC/HVACPlant/CoolingSystem[FractionCoolLoadServed > 0]') do |clg_sys|
              clg_dist = clg_sys.elements['DistributionSystem']
              next if htg_dist.nil? or clg_dist.nil?
              next if clg_dist.attributes['idref'] != htg_dist.attributes['idref']

              clg_sys_type = XMLHelper.get_value(clg_sys, 'CoolingSystemType')
              if clg_sys_type == 'central air conditioning'
                query_w = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EquipmentSummary' AND ReportForString='Entire Facility' AND TableName='Fans' AND RowName LIKE '%#{Constants.ObjectNameCentralAirConditioner.upcase}%' AND ColumnName='Rated Electric Power' AND Units='W'"
                sql_value_w = sqlFile.execAndReturnFirstDouble(query_w).get
                sql_value = sql_value_w * sql_value_htg_airflow / sql_value_fan_airflow
                assert_in_epsilon(hpxml_value, sql_value, 0.01)
              else
                flunk "Unexpected cooling system type: #{clg_sys_type}."
              end
            end
          end
        end

      end
    end

    # HVAC Cooling Systems
    num_clg_sys = bldg_details.elements['count(Systems/HVAC/HVACPlant/CoolingSystem)']
    bldg_details.elements.each('Systems/HVAC/HVACPlant/CoolingSystem') do |clg_sys|
      clg_sys_type = XMLHelper.get_value(clg_sys, "CoolingSystemType")
      clg_sys_cap = Float(XMLHelper.get_value(clg_sys, "CoolingCapacity"))
      clg_sys_seer = XMLHelper.get_value(clg_sys, "AnnualCoolingEfficiency[Units='SEER']/Value")
      clg_sys_seer = Float(clg_sys_seer) if not clg_sys_seer.nil?
      clg_load_frac = Float(XMLHelper.get_value(clg_sys, "FractionCoolLoadServed"))

      if clg_load_frac <= 0

        # Cooling Load Fraction
        # Check for zero cooling energy
        found_clg_energy = false
        results.keys.each do |k|
          next unless k[1] == 'Cooling'

          found_clg_energy = true
        end
        assert_equal(false, found_clg_energy)

      else

        # Cooling Capacity
        # FIXME: For now, skip if multiple equipment
        if clg_sys_cap > 0 and num_clg_sys == 1
          hpxml_value = clg_sys_cap
          query = "SELECT SUM(Value) FROM TabularDataWithStrings WHERE ReportName='ComponentSizingSummary' AND ReportForString='Entire Facility' AND TableName LIKE 'Coil:Cooling:%' AND ColumnName LIKE '%User-Specified%Total Cooling Capacity' AND Units='W'"
          sql_value = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, 'W', 'Btu/hr')
          if clg_sys_type == "central air conditioning" and get_ac_num_speeds(clg_sys_seer) == "Variable-Speed"
            cap_adj = 1.16 # TODO: Generalize this
          else
            cap_adj = 1.0
          end
          assert_in_epsilon(hpxml_value * cap_adj, sql_value, 0.01)
        end

      end
    end

    # HVAC Heat Pumps
    num_hp = bldg_details.elements['count(Systems/HVAC/HVACPlant/HeatPump)']
    bldg_details.elements.each('Systems/HVAC/HVACPlant/HeatPump') do |hp|
      hp_type = XMLHelper.get_value(hp, "HeatPumpType")
      hp_cap = Float(XMLHelper.get_value(hp, "CoolingCapacity"))
      hp_seer = XMLHelper.get_value(hp, "AnnualCoolingEfficiency[Units='SEER']/Value")
      hp_seer = Float(hp_seer) if not hp_seer.nil?
      hp_htg_load_frac = Float(XMLHelper.get_value(hp, "FractionHeatLoadServed"))
      hp_clg_load_frac = Float(XMLHelper.get_value(hp, "FractionCoolLoadServed"))

      if hp_htg_load_frac <= 0

        # Heating Load Fraction
        # Check for zero heating energy
        found_htg_energy = false
        results.keys.each do |k|
          next unless k[1] == 'Heating'

          found_htg_energy = true
        end
        assert_equal(false, found_htg_energy)

      end

      if hp_clg_load_frac <= 0

        # Cooling Load Fraction
        # Check for zero cooling energy
        found_clg_energy = false
        results.keys.each do |k|
          next unless k[1] == 'Cooling'

          found_clg_energy = true
        end
        assert_equal(false, found_clg_energy)

      else

        # Cooling Capacity
        # FIXME: For now, skip if multiple equipment
        if hp_cap > 0 and num_hp == 1
          hpxml_value = hp_cap
          query = "SELECT SUM(Value) FROM TabularDataWithStrings WHERE ReportName='ComponentSizingSummary' AND ReportForString='Entire Facility' AND TableName LIKE 'Coil:Cooling:%' AND ColumnName LIKE '%User-Specified%Total Cooling Capacity' AND Units='W'"
          sql_value = UnitConversions.convert(sqlFile.execAndReturnFirstDouble(query).get, 'W', 'Btu/hr')
          if hp_type == "mini-split" or (hp_type == "air-to-air" and get_ashp_num_speeds(hp_seer) == "Variable-Speed")
            cap_adj = 1.20 # TODO: Generalize this
          else
            cap_adj = 1.0
          end
          assert_in_epsilon(hpxml_value * cap_adj, sql_value, 0.01)
        end

      end
    end

    # HVAC fan power
    if bldg_details.elements['count(Systems/HVAC/HVACDistribution/DistributionSystemType/AirDistribution)'] == 1

      htg_fan_w_per_cfm = nil
      if bldg_details.elements['count(Systems/HVAC/HVACPlant/HeatingSystem[FractionHeatLoadServed > 0] | Systems/HVAC/HVACPlant/HeatPump[FractionHeatLoadServed > 0])'] == 1
        bldg_details.elements.each('Systems/HVAC/HVACPlant/HeatingSystem[FractionHeatLoadServed > 0] | Systems/HVAC/HVACPlant/HeatPump[FractionHeatLoadServed > 0]') do |htg_sys|
          next unless XMLHelper.has_element(htg_sys, "DistributionSystem")
          next unless htg_sys.elements["DistributionSystem"].attributes["idref"] == bldg_details.elements['Systems/HVAC/HVACDistribution[DistributionSystemType/AirDistribution]/SystemIdentifier'].attributes["id"]

          query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EquipmentSummary' AND ReportForString='Entire Facility' AND TableName='Fans' AND RowName LIKE '%HTG SUPPLY FAN%' AND ColumnName='Rated Power Per Max Air Flow Rate' AND Units='W-s/m3'"
          htg_fan_w_per_cfm = sqlFile.execAndReturnFirstDouble(query).get / UnitConversions.convert(1.0, "m^3/s", "cfm")
        end
      end

      clg_fan_w_per_cfm = nil
      if bldg_details.elements['count(Systems/HVAC/HVACPlant/CoolingSystem[FractionCoolLoadServed > 0] | Systems/HVAC/HVACPlant/HeatPump[FractionCoolLoadServed > 0])'] == 1
        bldg_details.elements.each('Systems/HVAC/HVACPlant/CoolingSystem[FractionCoolLoadServed > 0] | Systems/HVAC/HVACPlant/HeatPump[FractionCoolLoadServed > 0]') do |clg_sys|
          next unless XMLHelper.has_element(clg_sys, "DistributionSystem")
          next unless clg_sys.elements["DistributionSystem"].attributes["idref"] == bldg_details.elements['Systems/HVAC/HVACDistribution[DistributionSystemType/AirDistribution]/SystemIdentifier'].attributes["id"]

          query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EquipmentSummary' AND ReportForString='Entire Facility' AND TableName='Fans' AND RowName LIKE '%CLG SUPPLY FAN%' AND ColumnName='Rated Power Per Max Air Flow Rate' AND Units='W-s/m3'"
          clg_fan_w_per_cfm = sqlFile.execAndReturnFirstDouble(query).get / UnitConversions.convert(1.0, "m^3/s", "cfm")
        end
      end

      if not htg_fan_w_per_cfm.nil? and not clg_fan_w_per_cfm.nil?
        # Ensure associated heating & cooling systems have same fan power
        assert_equal(htg_fan_w_per_cfm, clg_fan_w_per_cfm)
      end

      # CFIS fan power
      cfis_fan_w_per_airflow = nil
      if XMLHelper.get_value(bldg_details, "Systems/MechanicalVentilation/VentilationFans/VentilationFan[UsedForWholeBuildingVentilation='true']/FanType") == "central fan integrated supply"
        query = "SELECT Value FROM ReportData WHERE ReportDataDictionaryIndex IN (SELECT ReportDataDictionaryIndex FROM ReportDataDictionary WHERE Name='res_mv_1_cfis_fan_power')"
        cfis_fan_w_per_cfm = sqlFile.execAndReturnFirstDouble(query).get
        # Ensure CFIS fan power equals heating/cooling fan power
        if not htg_fan_w_per_cfm.nil?
          assert_in_delta(htg_fan_w_per_cfm, cfis_fan_w_per_cfm, 0.001)
        else
          assert_in_delta(clg_fan_w_per_cfm, cfis_fan_w_per_cfm, 0.001)
        end
      end

    end

    # Water Heater
    wh = bldg_details.elements["Systems/WaterHeating"]

    # Mechanical Ventilation
    mv = bldg_details.elements["Systems/MechanicalVentilation/VentilationFans/VentilationFan[UsedForWholeBuildingVentilation='true']"]
    if not mv.nil?
      found_mv_energy = false
      results.keys.each do |k|
        next if k[0] != 'Electricity' or k[1] != 'Interior Equipment' or not k[2].start_with? Constants.ObjectNameMechanicalVentilation

        found_mv_energy = true
        if XMLHelper.has_element(mv, "AttachedToHVACDistributionSystem")
          # CFIS, check for positive mech vent energy
          assert_operator(results[k], :>, 0)
        else
          # Supply, exhaust, ERV, HRV, etc., check for appropriate mech vent energy
          fan_w = Float(XMLHelper.get_value(mv, "FanPower"))
          hrs_per_day = Float(XMLHelper.get_value(mv, "HoursInOperation"))
          fan_kwhs = UnitConversions.convert(fan_w * hrs_per_day * 365.0, 'Wh', 'GJ')
          assert_in_delta(fan_kwhs, results[k], 0.1)
        end
      end
      if not found_mv_energy
        flunk "Could not find mechanical ventilation energy for #{hpxml_path}."
      end
    end

    # Clothes Washer
    cw = bldg_details.elements["Appliances/ClothesWasher"]
    if not cw.nil? and not wh.nil?
      # Location
      location = XMLHelper.get_value(cw, "Location")
      hpxml_value = { nil => Constants.SpaceTypeLiving,
                      'living space' => Constants.SpaceTypeLiving,
                      'basement - conditioned' => Constants.SpaceTypeFinishedBasement,
                      'basement - unconditioned' => Constants.SpaceTypeUnfinishedBasement,
                      'garage' => Constants.SpaceTypeGarage }[location].upcase
      query = "SELECT Value FROM TabularDataWithStrings WHERE TableName='ElectricEquipment Internal Gains Nominal' AND ColumnName='Zone Name' AND RowName=(SELECT RowName FROM TabularDataWithStrings WHERE TableName='ElectricEquipment Internal Gains Nominal' AND ColumnName='Name' AND Value='#{Constants.ObjectNameClothesWasher.upcase}')"
      sql_value = sqlFile.execAndReturnFirstString(query).get
      assert_equal(hpxml_value, sql_value)
    end

    # Clothes Dryer
    cd = bldg_details.elements["Appliances/ClothesDryer"]
    if not cd.nil? and not wh.nil?
      # Location
      fuel = to_beopt_fuel(XMLHelper.get_value(cd, 'FuelType'))
      location = XMLHelper.get_value(cd, "Location")
      hpxml_value = { nil => Constants.SpaceTypeLiving,
                      'living space' => Constants.SpaceTypeLiving,
                      'basement - conditioned' => Constants.SpaceTypeFinishedBasement,
                      'basement - unconditioned' => Constants.SpaceTypeUnfinishedBasement,
                      'garage' => Constants.SpaceTypeGarage }[location].upcase
      query = "SELECT Value FROM TabularDataWithStrings WHERE TableName='ElectricEquipment Internal Gains Nominal' AND ColumnName='Zone Name' AND RowName=(SELECT RowName FROM TabularDataWithStrings WHERE TableName='ElectricEquipment Internal Gains Nominal' AND ColumnName='Name' AND Value='#{Constants.ObjectNameClothesDryer(fuel).upcase}')"
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
                      'basement - conditioned' => Constants.SpaceTypeFinishedBasement,
                      'basement - unconditioned' => Constants.SpaceTypeUnfinishedBasement,
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

  def _test_dse(xmls, hvac_dse_dir, all_results)
    # Compare 0.8 DSE heating/cooling results to 1.0 DSE results.
    xmls.sort.each do |xml|
      next if not xml.include? hvac_dse_dir
      next if not xml.include? "-dse-0.8"

      xml_dse80 = File.absolute_path(xml)
      xml_dse100 = xml_dse80.gsub("-dse-0.8", "-dse-1.0")

      results_dse80 = all_results[xml_dse80]
      results_dse100 = all_results[xml_dse100]
      next if results_dse100.nil?

      # Compare results
      puts "\nResults for #{File.basename(xml)}:"
      results_dse80.keys.each do |k|
        next if not ["Heating", "Cooling"].include? k[1]
        next if not ["General"].include? k[2] # Exclude crankcase/defrost

        result_dse80 = results_dse80[k].to_f
        result_dse100 = results_dse100[k].to_f
        next if result_dse80 == 0.0 and result_dse100 == 0.0

        dse_actual = result_dse100 / result_dse80
        dse_expect = 0.8
        if File.basename(xml) == "valid-hvac-furnace-gas-room-ac-dse-0.8.xml" and k[1] == "Cooling"
          dse_expect = 1.0 # TODO: Generalize this
        end
        puts "dse: #{dse_actual.round(2)} #{k}"
        assert_in_epsilon(dse_expect, dse_actual, 0.025)
      end
      puts "\n"
    end
  end

  def _test_multiple_hvac(xmls, multiple_hvac_dir, all_results)
    # Compare end use results for three of an HVAC system to results for one HVAC system.
    xmls.sort.each do |xml|
      next if not xml.include? multiple_hvac_dir

      xml_x3 = File.absolute_path(xml)
      xml_x1 = File.absolute_path(File.join(File.dirname(xml), "..", File.basename(xml.gsub("-x3", ""))))

      results_x3 = all_results[xml_x3]
      results_x1 = all_results[xml_x1]

      # Compare results
      puts "\nResults for #{xml}:"
      results_x3.keys.each do |k|
        next if [@simulation_runtime_key, @workflow_runtime_key].include? k

        result_x1 = results_x1[k].to_f
        result_x3 = results_x3[k].to_f
        next if result_x1 == 0.0 and result_x3 == 0.0

        puts "x1, x3: #{result_x1.round(2)}, #{result_x3.round(2)} #{k}"
        assert_in_delta(result_x1, result_x3, 0.1)
      end
      puts "\n"
    end
  end

  def _test_multiple_hvac(xmls, hvac_multiple_dir, all_results)
    # Compare end use results for three of an HVAC system to results for one HVAC system.
    xmls.sort.each do |xml|
      next if not xml.include? hvac_multiple_dir

      xml_x3 = File.absolute_path(xml)
      xml_x1 = File.absolute_path(File.join(File.dirname(xml), "..", File.basename(xml.gsub("-x3", ""))))

      results_x3 = all_results[xml_x3]
      results_x1 = all_results[xml_x1]
      next if results_x1.nil?

      # Compare results
      puts "\nResults for #{xml}:"
      results_x3.keys.each do |k|
        next if [@simulation_runtime_key, @workflow_runtime_key].include? k

        result_x1 = results_x1[k].to_f
        result_x3 = results_x3[k].to_f
        next if result_x1 == 0.0 and result_x3 == 0.0

        puts "x1, x3: #{result_x1.round(2)}, #{result_x3.round(2)} #{k}"

        # FIXME: Remove this code after the next E+ release
        # Skip ZoneHVAC tests on the CI that only pass if using an E+ bugfix version
        # See https://github.com/NREL/EnergyPlus/pull/7025
        if ENV['CI']
          skip_files_on_ci = ['valid-hvac-boiler-elec-only-x3.xml',
                              'valid-hvac-boiler-gas-only-x3.xml',
                              'valid-hvac-elec-resistance-only-x3.xml',
                              'valid-hvac-room-ac-only-x3.xml']
          next if skip_files_on_ci.include? File.basename(xml_x3)
        end

        assert_in_delta(result_x1, result_x3, 0.7) # TODO: Reduce tolerance
      end
      puts "\n"
    end
  end

  def _test_multiple_water_heaters(xmls, water_heating_multiple_dir, all_results)
    # Compare end use results for three tankless water heaters to results for one tankless water heater.
    xmls.sort.each do |xml|
      next if not xml.include? water_heating_multiple_dir

      xml_x3 = File.absolute_path(xml)
      xml_x1 = File.absolute_path(File.join(File.dirname(xml), "..", File.basename(xml.gsub("-x3", ""))))

      results_x3 = all_results[xml_x3]
      results_x1 = all_results[xml_x1]
      next if results_x1.nil?

      # Compare results
      puts "\nResults for #{xml}:"
      results_x3.keys.each do |k|
        next if [@simulation_runtime_key, @workflow_runtime_key].include? k

        result_x1 = results_x1[k].to_f
        result_x3 = results_x3[k].to_f
        next if result_x1 == 0.0 and result_x3 == 0.0

        puts "x1, x3: #{result_x1.round(2)}, #{result_x3.round(2)} #{k}"

        assert_in_delta(result_x1, result_x3, 0.2)
      end
      puts "\n"
    end
  end

  def _test_partial_hvac(xmls, hvac_partial_dir, all_results)
    # Compare end use results for a partial HVAC system to a full HVAC system.
    xmls.sort.each do |xml|
      next if not xml.include? hvac_partial_dir

      xml_50 = File.absolute_path(xml)
      xml_100 = File.absolute_path(File.join(File.dirname(xml), "..", File.basename(xml.gsub("-50percent", ""))))

      results_50 = all_results[xml_50]
      results_100 = all_results[xml_100]
      next if results_100.nil?

      # Compare results
      puts "\nResults for #{xml}:"
      results_50.keys.each do |k|
        next if not ["Heating", "Cooling"].include? k[1]
        next if not ["General"].include? k[2] # Exclude crankcase/defrost

        result_50 = results_50[k].to_f
        result_100 = results_100[k].to_f
        next if result_50 == 0.0 and result_100 == 0.0

        puts "50%, 100%: #{result_50.round(2)}, #{result_100.round(2)} #{k}"

        # FIXME: Remove this code after the next E+ release
        # Skip ZoneHVAC tests on the CI that only pass if using an E+ bugfix version
        # See https://github.com/NREL/EnergyPlus/pull/7025
        if ENV['CI']
          skip_files_on_ci = ['valid-hvac-boiler-elec-only-50percent.xml',
                              'valid-hvac-boiler-gas-only-50percent.xml',
                              'valid-hvac-elec-resistance-only-50percent.xml',
                              'valid-hvac-room-ac-only-50percent.xml',
                              'valid-hvac-stove-oil-only-50percent.xml',
                              'valid-hvac-wall-furnace-propane-only-50percent.xml']
          next if skip_files_on_ci.include? File.basename(xml_50)
        end

        assert_in_delta(result_50, result_100 / 2.0, 0.1)
      end
      puts "\n"
    end
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
