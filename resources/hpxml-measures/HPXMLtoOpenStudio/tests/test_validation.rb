# frozen_string_literal: true

require_relative '../resources/minitest_helper'
require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'fileutils'
require_relative '../measure.rb'

class HPXMLtoOpenStudioValidationTest < MiniTest::Test
  def setup
    @root_path = File.absolute_path(File.join(File.dirname(__FILE__), '..', '..'))
    @sample_files_path = File.join(@root_path, 'workflow', 'sample_files')
    @epvalidator_stron_path = File.join(@root_path, 'HPXMLtoOpenStudio', 'resources', 'EPvalidator.xml')
    @hpxml_stron_path = File.join(@root_path, 'HPXMLtoOpenStudio', 'resources', 'HPXMLvalidator.xml')

    @tmp_hpxml_path = File.join(@sample_files_path, 'tmp.xml')
    @tmp_output_path = File.join(@sample_files_path, 'tmp_output')
    FileUtils.mkdir_p(@tmp_output_path)
  end

  def teardown
    File.delete(@tmp_hpxml_path) if File.exist? @tmp_hpxml_path
    FileUtils.rm_rf(@tmp_output_path)
  end

  def test_validation_of_sample_files
    xmls = []
    Dir["#{@root_path}/workflow/**/*.xml"].sort.each do |xml|
      next if xml.split('/').include? 'run'

      xmls << xml
    end

    xmls.each_with_index do |xml, i|
      puts "[#{i + 1}/#{xmls.size}] Testing #{File.basename(xml)}..."

      # Test validation
      hpxml_doc = HPXML.new(hpxml_path: xml, building_id: 'MyBuilding').to_oga()
      _test_schema_validation(hpxml_doc, xml)
      _test_schematron_validation(hpxml_doc, expected_errors: []) # Ensure no errors
    end
    puts
  end

  def test_validation_of_schematron_doc
    # Check that the schematron file is valid

    begin
      require 'schematron-nokogiri'

      [@epvalidator_stron_path, @hpxml_stron_path].each do |s_path|
        xml_doc = Nokogiri::XML(File.open(s_path)) do |config|
          config.options = Nokogiri::XML::ParseOptions::STRICT
        end
        stron_doc = SchematronNokogiri::Schema.new(xml_doc)
      end
    rescue LoadError
    end
  end

  def test_role_attributes_in_schematron_doc
    # Test for consistent use of errors/warnings
    puts
    puts 'Checking for correct role attributes...'

    epvalidator_stron_doc = XMLHelper.parse_file(@epvalidator_stron_path)

    # check that every assert element has a role attribute
    XMLHelper.get_elements(epvalidator_stron_doc, '/sch:schema/sch:pattern/sch:rule/sch:assert').each do |assert_element|
      assert_test = XMLHelper.get_attribute_value(assert_element, 'test').gsub('h:', '')
      role_attribute = XMLHelper.get_attribute_value(assert_element, 'role')
      if role_attribute.nil?
        fail "No attribute \"role='ERROR'\" found for assertion test: #{assert_test}"
      end

      assert_equal('ERROR', role_attribute)
    end

    # check that every report element has a role attribute
    XMLHelper.get_elements(epvalidator_stron_doc, '/sch:schema/sch:pattern/sch:rule/sch:report').each do |report_element|
      report_test = XMLHelper.get_attribute_value(report_element, 'test').gsub('h:', '')
      role_attribute = XMLHelper.get_attribute_value(report_element, 'role')
      if role_attribute.nil?
        fail "No attribute \"role='WARN'\" found for report test: #{report_test}"
      end

      assert_equal('WARN', role_attribute)
    end
  end

  def test_schematron_error_messages
    # Test case => Error message
    all_expected_errors = { 'boiler-invalid-afue' => ['Expected AnnualHeatingEfficiency[Units="AFUE"]/Value to be less than or equal to 1'],
                            'clothes-dryer-location' => ['A location is specified as "garage" but no surfaces were found adjacent to this space type.'],
                            'clothes-washer-location' => ['A location is specified as "garage" but no surfaces were found adjacent to this space type.'],
                            'cooking-range-location' => ['A location is specified as "garage" but no surfaces were found adjacent to this space type.'],
                            'dehumidifier-fraction-served' => ['Expected sum(FractionDehumidificationLoadServed) to be less than or equal to 1 [context: /HPXML/Building/BuildingDetails]'],
                            'dhw-frac-load-served' => ['Expected sum(FractionDHWLoadServed) to be 1 [context: /HPXML/Building/BuildingDetails]'],
                            'dhw-invalid-ef-tank' => ['Expected EnergyFactor to be less than 1 [context: /HPXML/Building/BuildingDetails/Systems/WaterHeating/WaterHeatingSystem[WaterHeaterType="storage water heater"], id: "WaterHeatingSystem1"]'],
                            'dhw-invalid-uef-tank-heat-pump' => ['Expected UniformEnergyFactor to be greater than 1 [context: /HPXML/Building/BuildingDetails/Systems/WaterHeating/WaterHeatingSystem[WaterHeaterType="heat pump water heater"], id: "WaterHeatingSystem1"]'],
                            'dishwasher-location' => ['A location is specified as "garage" but no surfaces were found adjacent to this space type.'],
                            'duct-leakage-cfm25' => ['Expected Value to be greater than or equal to 0 [context: /HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution/DistributionSystemType/AirDistribution/DuctLeakageMeasurement/DuctLeakage[Units="CFM25"], id: "HVACDistribution1"]'],
                            'duct-leakage-percent' => ['Expected Value to be less than 1 [context: /HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution/DistributionSystemType/AirDistribution/DuctLeakageMeasurement/DuctLeakage[Units="Percent"], id: "HVACDistribution1"]'],
                            'duct-location' => ['A location is specified as "garage" but no surfaces were found adjacent to this space type.'],
                            'duct-location-unconditioned-space' => ["Expected DuctLocation to be 'living space' or 'basement - conditioned' or 'basement - unconditioned' or 'crawlspace - vented' or 'crawlspace - unvented' or 'attic - vented' or 'attic - unvented' or 'garage' or 'exterior wall' or 'under slab' or 'roof deck' or 'outside' or 'other housing unit' or 'other heated space' or 'other multifamily buffer space' or 'other non-freezing space' [context: /HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution/DistributionSystemType/AirDistribution/Ducts, id: \"HVACDistribution1\"]"],
                            'enclosure-attic-missing-roof' => ['There must be at least one roof adjacent to "attic - unvented". [context: /HPXML/Building/BuildingDetails/Enclosure[*/*[InteriorAdjacentTo="attic - unvented" or ExteriorAdjacentTo="attic - unvented"]]]'],
                            'enclosure-basement-missing-exterior-foundation-wall' => ['There must be at least one exterior foundation wall adjacent to "basement - unconditioned". [context: /HPXML/Building/BuildingDetails/Enclosure[*/*[InteriorAdjacentTo="basement - unconditioned" or ExteriorAdjacentTo="basement - unconditioned"]]]'],
                            'enclosure-basement-missing-slab' => ['There must be at least one slab adjacent to "basement - unconditioned". [context: /HPXML/Building/BuildingDetails/Enclosure[*/*[InteriorAdjacentTo="basement - unconditioned" or ExteriorAdjacentTo="basement - unconditioned"]]]'],
                            'enclosure-floor-area-exceeds-cfa' => ['Expected ConditionedFloorArea to be greater than or equal to the sum of conditioned slab/floor areas. [context: /HPXML/Building/BuildingDetails/BuildingSummary/BuildingConstruction]'],
                            'enclosure-floor-area-exceeds-cfa2' => ['Expected ConditionedFloorArea to be greater than or equal to the sum of conditioned slab/floor areas. [context: /HPXML/Building/BuildingDetails/BuildingSummary/BuildingConstruction]'],
                            'enclosure-garage-missing-exterior-wall' => ['There must be at least one exterior wall/foundation wall adjacent to "garage". [context: /HPXML/Building/BuildingDetails/Enclosure[*/*[InteriorAdjacentTo="garage" or ExteriorAdjacentTo="garage"]]]'],
                            'enclosure-garage-missing-roof-ceiling' => ['There must be at least one roof/ceiling adjacent to "garage". [context: /HPXML/Building/BuildingDetails/Enclosure[*/*[InteriorAdjacentTo="garage" or ExteriorAdjacentTo="garage"]]]'],
                            'enclosure-garage-missing-slab' => ['There must be at least one slab adjacent to "garage". [context: /HPXML/Building/BuildingDetails/Enclosure[*/*[InteriorAdjacentTo="garage" or ExteriorAdjacentTo="garage"]]]'],
                            'enclosure-living-missing-ceiling-roof' => ['There must be at least one ceiling/roof adjacent to conditioned space. [context: /HPXML/Building/BuildingDetails/Enclosure[*/*[InteriorAdjacentTo="living space"]]]',
                                                                        'There must be at least one floor adjacent to "attic - unvented". [context: /HPXML/Building/BuildingDetails/Enclosure[*/*[InteriorAdjacentTo="attic - unvented" or ExteriorAdjacentTo="attic - unvented"]]]'],
                            'enclosure-living-missing-exterior-wall' => ['There must be at least one exterior wall adjacent to conditioned space. [context: /HPXML/Building/BuildingDetails/Enclosure[*/*[InteriorAdjacentTo="living space"]]]'],
                            'enclosure-living-missing-floor-slab' => ['There must be at least one floor/slab adjacent to conditioned space. [context: /HPXML/Building/BuildingDetails/Enclosure[*/*[InteriorAdjacentTo="living space"]]]'],
                            'frac-sensible-fuel-load' => ['Expected extension/FracSensible to be greater than or equal to 0 [context: /HPXML/Building/BuildingDetails/MiscLoads/FuelLoad[FuelLoadType="grill" or FuelLoadType="lighting" or FuelLoadType="fireplace"], id: "FuelLoad1"]'],
                            'frac-sensible-plug-load' => ['Expected extension/FracSensible to be greater than or equal to 0 [context: /HPXML/Building/BuildingDetails/MiscLoads/PlugLoad[PlugLoadType="other" or PlugLoadType="TV other" or PlugLoadType="electric vehicle charging" or PlugLoadType="well pump"], id: "PlugLoad1"]'],
                            'frac-total-fuel-load' => ['Expected sum of extension/FracSensible and extension/FracLatent to be less than or equal to 1 [context: /HPXML/Building/BuildingDetails/MiscLoads/FuelLoad[FuelLoadType="grill" or FuelLoadType="lighting" or FuelLoadType="fireplace"], id: "FuelLoad1"]'],
                            'frac-total-plug-load' => ['Expected sum of extension/FracSensible and extension/FracLatent to be less than or equal to 1 [context: /HPXML/Building/BuildingDetails/MiscLoads/PlugLoad[PlugLoadType="other" or PlugLoadType="TV other" or PlugLoadType="electric vehicle charging" or PlugLoadType="well pump"], id: "PlugLoad2"]'],
                            'furnace-invalid-afue' => ['Expected AnnualHeatingEfficiency[Units="AFUE"]/Value to be less than or equal to 1'],
                            'generator-number-of-bedrooms-served' => ['Expected NumberofBedroomsServed to be greater than ../../../../BuildingSummary/BuildingConstruction/NumberofBedrooms [context: /HPXML/Building/BuildingDetails/Systems/extension/Generators/Generator[IsSharedSystem="true"], id: "Generator1"]'],
                            'generator-output-greater-than-consumption' => ['Expected AnnualConsumptionkBtu to be greater than AnnualOutputkWh*3412 [context: /HPXML/Building/BuildingDetails/Systems/extension/Generators/Generator, id: "Generator1"]'],
                            'heat-pump-mixed-fixed-and-autosize-capacities' => ['Expected 0 or 2 element(s) for xpath: HeatingCapacity | BackupHeatingCapacity [context: /HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatPump[BackupSystemFuel], id: "HeatPump1"]'],
                            'hvac-distribution-return-duct-leakage-missing' => ['Expected 1 element(s) for xpath: DuctLeakageMeasurement[DuctType="return"]/DuctLeakage[(Units="CFM25" or Units="Percent") and TotalOrToOutside="to outside"] [context: /HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution/DistributionSystemType/AirDistribution[AirDistributionType[text()="regular velocity" or text()="gravity"]], id: "HVACDistribution1"]'],
                            'hvac-frac-load-served' => ['Expected sum(FractionHeatLoadServed) to be less than or equal to 1 [context: /HPXML/Building/BuildingDetails]',
                                                        'Expected sum(FractionCoolLoadServed) to be less than or equal to 1 [context: /HPXML/Building/BuildingDetails]'],
                            'invalid-assembly-effective-rvalue' => ['Expected AssemblyEffectiveRValue to be greater than 0 [context: /HPXML/Building/BuildingDetails/Enclosure/Walls/Wall/Insulation, id: "Wall1Insulation"]'],
                            'invalid-duct-area-fractions' => ['Expected sum(Ducts/FractionDuctArea) for DuctType="supply" to be 1 [context: /HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution/DistributionSystemType/AirDistribution, id: "HVACDistribution1"]',
                                                              'Expected sum(Ducts/FractionDuctArea) for DuctType="return" to be 1 [context: /HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution/DistributionSystemType/AirDistribution, id: "HVACDistribution1"]'],
                            'invalid-facility-type-equipment' => ['Expected 1 element(s) for xpath: ../../../BuildingSummary/BuildingConstruction[ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]] [context: /HPXML/Building/BuildingDetails/Systems/WaterHeating/WaterHeatingSystem[IsSharedSystem="true"], id: "WaterHeatingSystem1"]',
                                                                  'Expected 1 element(s) for xpath: ../../BuildingSummary/BuildingConstruction[ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]] [context: /HPXML/Building/BuildingDetails/Appliances/ClothesWasher[IsSharedAppliance="true"], id: "ClothesWasher1"]',
                                                                  'Expected 1 element(s) for xpath: ../../BuildingSummary/BuildingConstruction[ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]] [context: /HPXML/Building/BuildingDetails/Appliances/ClothesDryer[IsSharedAppliance="true"], id: "ClothesDryer1"]',
                                                                  'Expected 1 element(s) for xpath: ../../BuildingSummary/BuildingConstruction[ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]] [context: /HPXML/Building/BuildingDetails/Appliances/Dishwasher[IsSharedAppliance="true"], id: "Dishwasher1"]'],
                            'invalid-foundation-wall-properties' => ['Expected DepthBelowGrade to be less than or equal to Height [context: /HPXML/Building/BuildingDetails/Enclosure/FoundationWalls/FoundationWall, id: "FoundationWall1"]',
                                                                     'Expected extension/DistanceToBottomOfInsulation to be greater than or equal to extension/DistanceToTopOfInsulation [context: /HPXML/Building/BuildingDetails/Enclosure/FoundationWalls/FoundationWall/Insulation/Layer[InstallationType="continuous - exterior" or InstallationType="continuous - interior"], id: "FoundationWall1Insulation"]',
                                                                     'Expected extension/DistanceToBottomOfInsulation to be less than or equal to ../../Height [context: /HPXML/Building/BuildingDetails/Enclosure/FoundationWalls/FoundationWall/Insulation/Layer[InstallationType="continuous - exterior" or InstallationType="continuous - interior"], id: "FoundationWall1Insulation"]'],
                            'invalid-id2' => ['Expected id attribute for SystemIdentifier [context: /HPXML/Building/BuildingDetails/Enclosure/Skylights/Skylight]'],
                            'invalid-infiltration-volume' => ['Expected InfiltrationVolume to be greater than or equal to ../../../BuildingSummary/BuildingConstruction/ConditionedBuildingVolume [context: /HPXML/Building/BuildingDetails/Enclosure/AirInfiltration/AirInfiltrationMeasurement[BuildingAirLeakage/UnitofMeasure[text()="ACH" or text()="CFM"]], id: "AirInfiltrationMeasurement1"]'],
                            'invalid-input-parameters' => ["Expected Transaction to be 'create' or 'update' [context: /HPXML/XMLTransactionHeaderInformation]",
                                                           "Expected SiteType to be 'rural' or 'suburban' or 'urban' [context: /HPXML/Building/BuildingDetails/BuildingSummary/Site]",
                                                           "Expected Year to be '2021' or '2018' or '2015' or '2012' or '2009' or '2006' or '2003' [context: /HPXML/Building/BuildingDetails/ClimateandRiskZones/ClimateZoneIECC]",
                                                           'Expected Azimuth to be less than 360 [context: /HPXML/Building/BuildingDetails/Enclosure/Roofs/Roof, id: "Roof1"]',
                                                           'Expected RadiantBarrierGrade to be less than or equal to 3 [context: /HPXML/Building/BuildingDetails/Enclosure/Roofs/Roof, id: "Roof1"]',
                                                           'Expected EnergyFactor to be less than or equal to 5 [context: /HPXML/Building/BuildingDetails/Appliances/Dishwasher, id: "Dishwasher1"]'],
                            'invalid-insulation-top' => ['Expected extension/DistanceToTopOfInsulation to be greater than or equal to 0 [context: /HPXML/Building/BuildingDetails/Enclosure/FoundationWalls/FoundationWall/Insulation/Layer[InstallationType="continuous - exterior" or InstallationType="continuous - interior"], id: "FoundationWall1Insulation"]'],
                            'invalid-number-of-bedrooms-served' => ['Expected extension/NumberofBedroomsServed to be greater than ../../../BuildingSummary/BuildingConstruction/NumberofBedrooms [context: /HPXML/Building/BuildingDetails/Systems/Photovoltaics/PVSystem[IsSharedSystem="true"], id: "PVSystem1"]'],
                            'invalid-number-of-conditioned-floors' => ['Expected NumberofConditionedFloors to be greater than or equal to NumberofConditionedFloorsAboveGrade [context: /HPXML/Building/BuildingDetails/BuildingSummary/BuildingConstruction]'],
                            'invalid-number-of-units-served' => ['Expected NumberofUnitsServed to be greater than 1 [context: /HPXML/Building/BuildingDetails/Systems/WaterHeating/WaterHeatingSystem[IsSharedSystem="true"], id: "WaterHeatingSystem1"]'],
                            'invalid-shared-vent-in-unit-flowrate' => ['Expected RatedFlowRate to be greater than extension/InUnitFlowRate [context: /HPXML/Building/BuildingDetails/Systems/MechanicalVentilation/VentilationFans/VentilationFan[UsedForWholeBuildingVentilation="true" and IsSharedSystem="true"], id: "VentilationFan1"]'],
                            'invalid-window-height' => ['Expected DistanceToBottomOfWindow to be greater than DistanceToTopOfWindow [context: /HPXML/Building/BuildingDetails/Enclosure/Windows/Window/Overhangs[number(Depth) > 0], id: "Window2"]'],
                            'lighting-fractions' => ['Expected sum(LightingGroup/FractionofUnitsInLocation) for Location="interior" to be less than or equal to 1 [context: /HPXML/Building/BuildingDetails/Lighting]'],
                            'missing-duct-area' => ['Expected 1 or more element(s) for xpath: FractionDuctArea | DuctSurfaceArea [context: /HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution/DistributionSystemType/AirDistribution/Ducts[DuctLocation], id: "HVACDistribution1"]',
                                                    'Expected 1 or more element(s) for xpath: FractionDuctArea | DuctSurfaceArea [context: /HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution/DistributionSystemType/AirDistribution/Ducts[DuctLocation], id: "HVACDistribution2"]',
                                                    'Expected 1 or more element(s) for xpath: FractionDuctArea | DuctSurfaceArea [context: /HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution/DistributionSystemType/AirDistribution/Ducts[DuctLocation], id: "HVACDistribution5"]',
                                                    'Expected 1 or more element(s) for xpath: FractionDuctArea | DuctSurfaceArea [context: /HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution/DistributionSystemType/AirDistribution/Ducts[DuctLocation], id: "HVACDistribution6"]'],
                            'missing-duct-location' => ['Expected 0 element(s) for xpath: FractionDuctArea | DuctSurfaceArea [context: /HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution/DistributionSystemType/AirDistribution/Ducts[not(DuctLocation)], id: "HVACDistribution1"]',
                                                        'Expected 0 element(s) for xpath: FractionDuctArea | DuctSurfaceArea [context: /HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution/DistributionSystemType/AirDistribution/Ducts[not(DuctLocation)], id: "HVACDistribution2"]',
                                                        'Expected 0 element(s) for xpath: FractionDuctArea | DuctSurfaceArea [context: /HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution/DistributionSystemType/AirDistribution/Ducts[not(DuctLocation)], id: "HVACDistribution5"]',
                                                        'Expected 0 element(s) for xpath: FractionDuctArea | DuctSurfaceArea [context: /HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution/DistributionSystemType/AirDistribution/Ducts[not(DuctLocation)], id: "HVACDistribution6"]'],
                            'missing-elements' => ['Expected 1 element(s) for xpath: NumberofConditionedFloors [context: /HPXML/Building/BuildingDetails/BuildingSummary/BuildingConstruction]',
                                                   'Expected 1 element(s) for xpath: ConditionedFloorArea [context: /HPXML/Building/BuildingDetails/BuildingSummary/BuildingConstruction]'],
                            'refrigerator-location' => ['A location is specified as "garage" but no surfaces were found adjacent to this space type.'],
                            'schedule-extra-inputs' => ['Expected 0 or 1 element(s) for xpath: extension/WeekdayScheduleFractions | /HPXML/SoftwareInfo/extension/SchedulesFilePath [context: /HPXML/Building/BuildingDetails/BuildingSummary/BuildingOccupancy]',
                                                        'Expected 0 or 1 element(s) for xpath: extension/WeekendScheduleFractions | /HPXML/SoftwareInfo/extension/SchedulesFilePath [context: /HPXML/Building/BuildingDetails/BuildingSummary/BuildingOccupancy]',
                                                        'Expected 0 or 1 element(s) for xpath: extension/MonthlyScheduleMultipliers | /HPXML/SoftwareInfo/extension/SchedulesFilePath [context: /HPXML/Building/BuildingDetails/BuildingSummary/BuildingOccupancy]',
                                                        'Expected 0 or 1 element(s) for xpath: ../extension/WaterFixturesWeekdayScheduleFractions | /HPXML/SoftwareInfo/extension/SchedulesFilePath [context: /HPXML/Building/BuildingDetails/Systems/WaterHeating/WaterFixture, id: "WaterFixture1"]',
                                                        'Expected 0 or 1 element(s) for xpath: ../extension/WaterFixturesWeekdayScheduleFractions | /HPXML/SoftwareInfo/extension/SchedulesFilePath [context: /HPXML/Building/BuildingDetails/Systems/WaterHeating/WaterFixture, id: "WaterFixture2"]',
                                                        'Expected 0 or 1 element(s) for xpath: ../extension/WaterFixturesWeekendScheduleFractions | /HPXML/SoftwareInfo/extension/SchedulesFilePath [context: /HPXML/Building/BuildingDetails/Systems/WaterHeating/WaterFixture, id: "WaterFixture1"]',
                                                        'Expected 0 or 1 element(s) for xpath: ../extension/WaterFixturesWeekendScheduleFractions | /HPXML/SoftwareInfo/extension/SchedulesFilePath [context: /HPXML/Building/BuildingDetails/Systems/WaterHeating/WaterFixture, id: "WaterFixture2"]',
                                                        'Expected 0 or 1 element(s) for xpath: ../extension/WaterFixturesMonthlyScheduleMultipliers | /HPXML/SoftwareInfo/extension/SchedulesFilePath [context: /HPXML/Building/BuildingDetails/Systems/WaterHeating/WaterFixture, id: "WaterFixture1"]',
                                                        'Expected 0 or 1 element(s) for xpath: ../extension/WaterFixturesMonthlyScheduleMultipliers | /HPXML/SoftwareInfo/extension/SchedulesFilePath [context: /HPXML/Building/BuildingDetails/Systems/WaterHeating/WaterFixture, id: "WaterFixture2"]',
                                                        'Expected 0 or 1 element(s) for xpath: extension/WeekdayScheduleFractions | /HPXML/SoftwareInfo/extension/SchedulesFilePath [context: /HPXML/Building/BuildingDetails/Appliances/ClothesWasher, id: "ClothesWasher1"]',
                                                        'Expected 0 or 1 element(s) for xpath: extension/WeekendScheduleFractions | /HPXML/SoftwareInfo/extension/SchedulesFilePath [context: /HPXML/Building/BuildingDetails/Appliances/ClothesWasher, id: "ClothesWasher1"]',
                                                        'Expected 0 or 1 element(s) for xpath: extension/MonthlyScheduleMultipliers | /HPXML/SoftwareInfo/extension/SchedulesFilePath [context: /HPXML/Building/BuildingDetails/Appliances/ClothesWasher, id: "ClothesWasher1"]',
                                                        'Expected 0 or 1 element(s) for xpath: extension/WeekdayScheduleFractions | /HPXML/SoftwareInfo/extension/SchedulesFilePath [context: /HPXML/Building/BuildingDetails/Appliances/ClothesDryer, id: "ClothesDryer1"]',
                                                        'Expected 0 or 1 element(s) for xpath: extension/WeekendScheduleFractions | /HPXML/SoftwareInfo/extension/SchedulesFilePath [context: /HPXML/Building/BuildingDetails/Appliances/ClothesDryer, id: "ClothesDryer1"]',
                                                        'Expected 0 or 1 element(s) for xpath: extension/MonthlyScheduleMultipliers | /HPXML/SoftwareInfo/extension/SchedulesFilePath [context: /HPXML/Building/BuildingDetails/Appliances/ClothesDryer, id: "ClothesDryer1"]',
                                                        'Expected 0 or 1 element(s) for xpath: extension/WeekdayScheduleFractions | /HPXML/SoftwareInfo/extension/SchedulesFilePath [context: /HPXML/Building/BuildingDetails/Appliances/Dishwasher, id: "Dishwasher1"]',
                                                        'Expected 0 or 1 element(s) for xpath: extension/WeekendScheduleFractions | /HPXML/SoftwareInfo/extension/SchedulesFilePath [context: /HPXML/Building/BuildingDetails/Appliances/Dishwasher, id: "Dishwasher1"]',
                                                        'Expected 0 or 1 element(s) for xpath: extension/MonthlyScheduleMultipliers | /HPXML/SoftwareInfo/extension/SchedulesFilePath [context: /HPXML/Building/BuildingDetails/Appliances/Dishwasher, id: "Dishwasher1"]',
                                                        'Expected 0 or 1 element(s) for xpath: extension/WeekdayScheduleFractions | /HPXML/SoftwareInfo/extension/SchedulesFilePath [context: /HPXML/Building/BuildingDetails/Appliances/Refrigerator, id: "Refrigerator1"]',
                                                        'Expected 0 or 1 element(s) for xpath: extension/WeekendScheduleFractions | /HPXML/SoftwareInfo/extension/SchedulesFilePath [context: /HPXML/Building/BuildingDetails/Appliances/Refrigerator, id: "Refrigerator1"]',
                                                        'Expected 0 or 1 element(s) for xpath: extension/MonthlyScheduleMultipliers | /HPXML/SoftwareInfo/extension/SchedulesFilePath [context: /HPXML/Building/BuildingDetails/Appliances/Refrigerator, id: "Refrigerator1"]',
                                                        'Expected 0 or 1 element(s) for xpath: extension/WeekdayScheduleFractions | /HPXML/SoftwareInfo/extension/SchedulesFilePath [context: /HPXML/Building/BuildingDetails/Appliances/CookingRange, id: "CookingRange1"]',
                                                        'Expected 0 or 1 element(s) for xpath: extension/WeekendScheduleFractions | /HPXML/SoftwareInfo/extension/SchedulesFilePath [context: /HPXML/Building/BuildingDetails/Appliances/CookingRange, id: "CookingRange1"]',
                                                        'Expected 0 or 1 element(s) for xpath: extension/MonthlyScheduleMultipliers | /HPXML/SoftwareInfo/extension/SchedulesFilePath [context: /HPXML/Building/BuildingDetails/Appliances/CookingRange, id: "CookingRange1"]',
                                                        'Expected 0 or 1 element(s) for xpath: extension/InteriorWeekdayScheduleFractions | /HPXML/SoftwareInfo/extension/SchedulesFilePath [context: /HPXML/Building/BuildingDetails/Lighting]',
                                                        'Expected 0 or 1 element(s) for xpath: extension/InteriorWeekendScheduleFractions | /HPXML/SoftwareInfo/extension/SchedulesFilePath [context: /HPXML/Building/BuildingDetails/Lighting]',
                                                        'Expected 0 or 1 element(s) for xpath: extension/InteriorMonthlyScheduleMultipliers | /HPXML/SoftwareInfo/extension/SchedulesFilePath [context: /HPXML/Building/BuildingDetails/Lighting]',
                                                        'Expected 0 or 1 element(s) for xpath: extension/GarageWeekdayScheduleFractions | /HPXML/SoftwareInfo/extension/SchedulesFilePath [context: /HPXML/Building/BuildingDetails/Lighting]',
                                                        'Expected 0 or 1 element(s) for xpath: extension/GarageWeekendScheduleFractions | /HPXML/SoftwareInfo/extension/SchedulesFilePath [context: /HPXML/Building/BuildingDetails/Lighting]',
                                                        'Expected 0 or 1 element(s) for xpath: extension/GarageMonthlyScheduleMultipliers | /HPXML/SoftwareInfo/extension/SchedulesFilePath [context: /HPXML/Building/BuildingDetails/Lighting]',
                                                        'Expected 0 or 1 element(s) for xpath: extension/ExteriorWeekdayScheduleFractions | /HPXML/SoftwareInfo/extension/SchedulesFilePath [context: /HPXML/Building/BuildingDetails/Lighting]',
                                                        'Expected 0 or 1 element(s) for xpath: extension/ExteriorWeekendScheduleFractions | /HPXML/SoftwareInfo/extension/SchedulesFilePath [context: /HPXML/Building/BuildingDetails/Lighting]',
                                                        'Expected 0 or 1 element(s) for xpath: extension/ExteriorMonthlyScheduleMultipliers | /HPXML/SoftwareInfo/extension/SchedulesFilePath [context: /HPXML/Building/BuildingDetails/Lighting]',
                                                        'Expected 0 or 1 element(s) for xpath: extension/WeekdayScheduleFractions | /HPXML/SoftwareInfo/extension/SchedulesFilePath [context: /HPXML/Building/BuildingDetails/MiscLoads/PlugLoad[PlugLoadType="other" or PlugLoadType="TV other" or PlugLoadType="electric vehicle charging" or PlugLoadType="well pump"], id: "PlugLoad1"]',
                                                        'Expected 0 or 1 element(s) for xpath: extension/WeekdayScheduleFractions | /HPXML/SoftwareInfo/extension/SchedulesFilePath [context: /HPXML/Building/BuildingDetails/MiscLoads/PlugLoad[PlugLoadType="other" or PlugLoadType="TV other" or PlugLoadType="electric vehicle charging" or PlugLoadType="well pump"], id: "PlugLoad2"]',
                                                        'Expected 0 or 1 element(s) for xpath: extension/WeekendScheduleFractions | /HPXML/SoftwareInfo/extension/SchedulesFilePath [context: /HPXML/Building/BuildingDetails/MiscLoads/PlugLoad[PlugLoadType="other" or PlugLoadType="TV other" or PlugLoadType="electric vehicle charging" or PlugLoadType="well pump"], id: "PlugLoad1"]',
                                                        'Expected 0 or 1 element(s) for xpath: extension/WeekendScheduleFractions | /HPXML/SoftwareInfo/extension/SchedulesFilePath [context: /HPXML/Building/BuildingDetails/MiscLoads/PlugLoad[PlugLoadType="other" or PlugLoadType="TV other" or PlugLoadType="electric vehicle charging" or PlugLoadType="well pump"], id: "PlugLoad2"]',
                                                        'Expected 0 or 1 element(s) for xpath: extension/MonthlyScheduleMultipliers | /HPXML/SoftwareInfo/extension/SchedulesFilePath [context: /HPXML/Building/BuildingDetails/MiscLoads/PlugLoad[PlugLoadType="other" or PlugLoadType="TV other" or PlugLoadType="electric vehicle charging" or PlugLoadType="well pump"], id: "PlugLoad1"]',
                                                        'Expected 0 or 1 element(s) for xpath: extension/MonthlyScheduleMultipliers | /HPXML/SoftwareInfo/extension/SchedulesFilePath [context: /HPXML/Building/BuildingDetails/MiscLoads/PlugLoad[PlugLoadType="other" or PlugLoadType="TV other" or PlugLoadType="electric vehicle charging" or PlugLoadType="well pump"], id: "PlugLoad2"]'],
                            'solar-fraction-one' => ['Expected SolarFraction to be less than 1 [context: /HPXML/Building/BuildingDetails/Systems/SolarThermal/SolarThermalSystem, id: "SolarThermalSystem1"]'],
                            'water-heater-location' => ['A location is specified as "crawlspace - vented" but no surfaces were found adjacent to this space type.'],
                            'water-heater-location-other' => ["Expected Location to be 'living space' or 'basement - unconditioned' or 'basement - conditioned' or 'attic - unvented' or 'attic - vented' or 'garage' or 'crawlspace - unvented' or 'crawlspace - vented' or 'other exterior' or 'other housing unit' or 'other heated space' or 'other multifamily buffer space' or 'other non-freezing space' [context: /HPXML/Building/BuildingDetails/Systems/WaterHeating/WaterHeatingSystem, id: \"WaterHeatingSystem1\"]"] }

    all_expected_errors.each_with_index do |(error_case, expected_errors), i|
      puts "[#{i + 1}/#{all_expected_errors.size}] Testing #{error_case}..."
      # Create HPXML object
      if ['boiler-invalid-afue'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-hvac-boiler-oil-only.xml'))
        hpxml.heating_systems[0].heating_efficiency_afue *= 100.0
      elsif ['clothes-dryer-location'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.clothes_dryers[0].location = HPXML::LocationGarage
      elsif ['clothes-washer-location'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.clothes_washers[0].location = HPXML::LocationGarage
      elsif ['cooking-range-location'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.cooking_ranges[0].location = HPXML::LocationGarage
      elsif ['dehumidifier-fraction-served'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-appliances-dehumidifier-multiple.xml'))
        hpxml.dehumidifiers[-1].fraction_served = 0.6
      elsif ['dhw-frac-load-served'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-dhw-multiple.xml'))
        hpxml.water_heating_systems[0].fraction_dhw_load_served = 0.35
      elsif ['dhw-invalid-ef-tank'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.water_heating_systems[0].energy_factor = 1.0
      elsif ['dhw-invalid-uef-tank-heat-pump'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-dhw-tank-heat-pump-uef.xml'))
        hpxml.water_heating_systems[0].uniform_energy_factor = 1.0
      elsif ['dishwasher-location'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.dishwashers[0].location = HPXML::LocationGarage
      elsif ['duct-leakage-cfm25'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.hvac_distributions[0].duct_leakage_measurements[0].duct_leakage_value = -2
        hpxml.hvac_distributions[0].duct_leakage_measurements[1].duct_leakage_value = -2
      elsif ['duct-leakage-percent'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.hvac_distributions[0].duct_leakage_measurements[0].duct_leakage_units = HPXML::UnitsPercent
        hpxml.hvac_distributions[0].duct_leakage_measurements[1].duct_leakage_units = HPXML::UnitsPercent
      elsif ['duct-location'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.hvac_distributions[0].ducts[0].duct_location = HPXML::LocationGarage
        hpxml.hvac_distributions[0].ducts[1].duct_location = HPXML::LocationGarage
      elsif ['duct-location-unconditioned-space'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.hvac_distributions[0].ducts[0].duct_location = HPXML::LocationUnconditionedSpace
        hpxml.hvac_distributions[0].ducts[1].duct_location = HPXML::LocationUnconditionedSpace
      elsif ['enclosure-attic-missing-roof'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.roofs.reverse_each do |roof|
          roof.delete
        end
      elsif ['enclosure-basement-missing-exterior-foundation-wall'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-foundation-unconditioned-basement.xml'))
        hpxml.foundation_walls.reverse_each do |foundation_wall|
          foundation_wall.delete
        end
      elsif ['enclosure-basement-missing-slab'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-foundation-unconditioned-basement.xml'))
        hpxml.slabs.reverse_each do |slab|
          slab.delete
        end
      elsif ['enclosure-floor-area-exceeds-cfa'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.building_construction.conditioned_floor_area = 1348.8
      elsif ['enclosure-floor-area-exceeds-cfa2'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-bldgtype-multifamily.xml'))
        hpxml.building_construction.conditioned_floor_area = 898.8
      elsif ['enclosure-garage-missing-exterior-wall'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-enclosure-garage.xml'))
        hpxml.walls.select { |w|
          w.interior_adjacent_to == HPXML::LocationGarage &&
            w.exterior_adjacent_to == HPXML::LocationOutside
        }.reverse_each do |wall|
          wall.delete
        end
      elsif ['enclosure-garage-missing-roof-ceiling'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-enclosure-garage.xml'))
        hpxml.frame_floors.select { |w|
          w.interior_adjacent_to == HPXML::LocationGarage &&
            w.exterior_adjacent_to == HPXML::LocationAtticUnvented
        }.reverse_each do |frame_floor|
          frame_floor.delete
        end
      elsif ['enclosure-garage-missing-slab'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-enclosure-garage.xml'))
        hpxml.slabs.select { |w| w.interior_adjacent_to == HPXML::LocationGarage }.reverse_each do |slab|
          slab.delete
        end
      elsif ['enclosure-living-missing-ceiling-roof'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.frame_floors.reverse_each do |frame_floor|
          frame_floor.delete
        end
      elsif ['enclosure-living-missing-exterior-wall'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.walls.reverse_each do |wall|
          next unless wall.interior_adjacent_to == HPXML::LocationLivingSpace

          wall.delete
        end
      elsif ['enclosure-living-missing-floor-slab'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-foundation-slab.xml'))
        hpxml.slabs[0].delete
      elsif ['frac-sensible-fuel-load'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-misc-loads-large-uncommon.xml'))
        hpxml.fuel_loads[0].frac_sensible = -0.1
      elsif ['frac-sensible-plug-load'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-misc-loads-large-uncommon.xml'))
        hpxml.plug_loads[0].frac_sensible = -0.1
      elsif ['frac-total-fuel-load'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-misc-loads-large-uncommon.xml'))
        hpxml.fuel_loads[0].frac_sensible = 0.8
        hpxml.fuel_loads[0].frac_latent = 0.3
      elsif ['frac-total-plug-load'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-misc-loads-large-uncommon.xml'))
        hpxml.plug_loads[1].frac_latent = 0.245
      elsif ['furnace-invalid-afue'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.heating_systems[0].heating_efficiency_afue *= 100.0
      elsif ['generator-number-of-bedrooms-served'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-bldgtype-multifamily-shared-generator.xml'))
        hpxml.generators[0].number_of_bedrooms_served = 3
      elsif ['generator-output-greater-than-consumption'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-misc-generators.xml'))
        hpxml.generators[0].annual_consumption_kbtu = 1500
      elsif ['heat-pump-mixed-fixed-and-autosize-capacities'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-hvac-air-to-air-heat-pump-1-speed.xml'))
        hpxml.heat_pumps[0].heating_capacity = nil
        hpxml.heat_pumps[0].cooling_capacity = nil
        hpxml.heat_pumps[0].heating_capacity_17F = 25000.0
      elsif ['hvac-distribution-return-duct-leakage-missing'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-hvac-evap-cooler-only-ducted.xml'))
        hpxml.hvac_distributions[0].duct_leakage_measurements[-1].delete
      elsif ['hvac-frac-load-served'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-hvac-multiple.xml'))
        hpxml.heating_systems[0].fraction_heat_load_served += 0.1
        hpxml.cooling_systems[0].fraction_cool_load_served += 0.2
        hpxml.heating_systems[0].primary_system = true
        hpxml.cooling_systems[0].primary_system = true
        hpxml.heat_pumps[-1].primary_heating_system = false
        hpxml.heat_pumps[-1].primary_cooling_system = false
      elsif ['invalid-assembly-effective-rvalue'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.walls[0].insulation_assembly_r_value = 0.0
      elsif ['invalid-duct-area-fractions'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-hvac-ducts-area-fractions.xml'))
        hpxml.hvac_distributions[0].ducts[0].duct_surface_area = nil
        hpxml.hvac_distributions[0].ducts[1].duct_surface_area = nil
        hpxml.hvac_distributions[0].ducts[2].duct_surface_area = nil
        hpxml.hvac_distributions[0].ducts[3].duct_surface_area = nil
        hpxml.hvac_distributions[0].ducts[0].duct_fraction_area = 0.65
        hpxml.hvac_distributions[0].ducts[1].duct_fraction_area = 0.65
        hpxml.hvac_distributions[0].ducts[2].duct_fraction_area = 0.15
        hpxml.hvac_distributions[0].ducts[3].duct_fraction_area = 0.15
      elsif ['invalid-facility-type-equipment'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-bldgtype-multifamily-shared-laundry-room.xml'))
        hpxml.building_construction.residential_facility_type = HPXML::ResidentialTypeSFD
      elsif ['invalid-foundation-wall-properties'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-foundation-unconditioned-basement-wall-insulation.xml'))
        hpxml.foundation_walls[0].depth_below_grade = 9.0
        hpxml.foundation_walls[0].insulation_interior_distance_to_top = 12.0
        hpxml.foundation_walls[0].insulation_interior_distance_to_bottom = 10.0
      elsif ['invalid-id2'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-enclosure-skylights.xml'))
      elsif ['invalid-infiltration-volume'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.air_infiltration_measurements[0].infiltration_volume = 5400
      elsif ['invalid-input-parameters'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.header.transaction = 'modify'
        hpxml.site.site_type = 'mountain'
        hpxml.climate_and_risk_zones.iecc_year = 2020
        hpxml.roofs.each do |roof|
          roof.radiant_barrier_grade = 4
        end
        hpxml.roofs[0].azimuth = 365
        hpxml.dishwashers[0].rated_annual_kwh = nil
        hpxml.dishwashers[0].energy_factor = 5.1
      elsif ['invalid-insulation-top'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.foundation_walls[0].insulation_interior_distance_to_top = -0.5
      elsif ['invalid-number-of-bedrooms-served'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-bldgtype-multifamily-shared-pv.xml'))
        hpxml.pv_systems[0].number_of_bedrooms_served = 3
      elsif ['invalid-number-of-conditioned-floors'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.building_construction.number_of_conditioned_floors_above_grade = 3
      elsif ['invalid-number-of-units-served'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-bldgtype-multifamily-shared-water-heater.xml'))
        hpxml.water_heating_systems[0].number_of_units_served = 1
      elsif ['invalid-shared-vent-in-unit-flowrate'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-bldgtype-multifamily-shared-mechvent.xml'))
        hpxml.ventilation_fans[0].rated_flow_rate = 80
      elsif ['invalid-window-height'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-enclosure-overhangs.xml'))
        hpxml.windows[1].overhangs_distance_to_bottom_of_window = 1.0
      elsif ['lighting-fractions'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        int_cfl = hpxml.lighting_groups.select { |lg| lg.location == HPXML::LocationInterior && lg.lighting_type == HPXML::LightingTypeCFL }[0]
        int_cfl.fraction_of_units_in_location = 0.8
      elsif ['missing-duct-area'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-hvac-multiple.xml'))
        hpxml.hvac_distributions.each do |hvac_distribution|
          next unless hvac_distribution.distribution_system_type == HPXML::HVACDistributionTypeAir

          hvac_distribution.ducts[1].duct_surface_area = nil
        end
      elsif ['missing-duct-location'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-hvac-multiple.xml'))
        hpxml.hvac_distributions.each do |hvac_distribution|
          next unless hvac_distribution.distribution_system_type == HPXML::HVACDistributionTypeAir

          hvac_distribution.ducts[1].duct_location = nil
        end
      elsif ['missing-elements'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.building_construction.number_of_conditioned_floors = nil
        hpxml.building_construction.conditioned_floor_area = nil
      elsif ['refrigerator-location'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.refrigerators[0].location = HPXML::LocationGarage
      elsif ['schedule-extra-inputs'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-schedules-simple.xml'))
        hpxml.header.schedules_filepath = 'HPXMLtoOpenStudio/resources/schedule_files/smooth.csv'
      elsif ['solar-fraction-one'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-dhw-solar-fraction.xml'))
        hpxml.solar_thermal_systems[0].solar_fraction = 1.0
      elsif ['water-heater-location'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.water_heating_systems[0].location = HPXML::LocationCrawlspaceVented
      elsif ['water-heater-location-other'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.water_heating_systems[0].location = HPXML::LocationUnconditionedSpace
      else
        fail "Unhandled case: #{error_case}."
      end

      hpxml_doc = hpxml.to_oga()

      # Perform additional raw XML manipulation
      if ['invalid-id2'].include? error_case
        element = XMLHelper.get_element(hpxml_doc, '/HPXML/Building/BuildingDetails/Enclosure/Skylights/Skylight/SystemIdentifier')
        XMLHelper.delete_attribute(element, 'id')
      end

      # Test against schematron
      _test_schematron_validation(hpxml_doc, expected_errors: expected_errors)
    end
  end

  def test_schematron_warning_messages
    # Test case => Warning message
    all_expected_warnings = { 'dhw-efficiencies-low' => ['EnergyFactor should typically be greater than or equal to 0.45.',
                                                         'EnergyFactor should typically be greater than or equal to 0.45.',
                                                         'No space cooling specified, the model will not include space cooling energy use.'],
                              'dhw-setpoint-low' => ['Hot water setpoint should typically be greater than or equal to 110 deg-F.'],
                              'hvac-dse-low' => ['Heating DSE should typically be greater than or equal to 0.5.',
                                                 'Cooling DSE should typically be greater than or equal to 0.5.'],
                              'hvac-efficiencies-low' => ['Percent efficiency should typically be greater than or equal to 0.95.',
                                                          'AFUE should typically be greater than or equal to 0.72.',
                                                          'AFUE should typically be greater than or equal to 0.6.',
                                                          'AFUE should typically be greater than or equal to 0.6.',
                                                          'Percent efficiency should typically be greater than or equal to 0.6.',
                                                          'SEER should typically be greater than or equal to 9.',
                                                          'EER should typically be greater than or equal to 8.',
                                                          'SEER should typically be greater than or equal to 9.',
                                                          'HSPF should typically be greater than or equal to 6.5.',
                                                          'SEER should typically be greater than or equal to 9.',
                                                          'HSPF should typically be greater than or equal to 6.5.',
                                                          'EER should typically be greater than or equal to 8.',
                                                          'COP should typically be greater than or equal to 2.'],
                              'hvac-setpoints-high' => ['Heating setpoint should typically be less than or equal to 76 deg-F.',
                                                        'Cooling setpoint should typically be less than or equal to 86 deg-F.'],
                              'hvac-setpoints-low' => ['Heating setpoint should typically be greater than or equal to 58 deg-F.',
                                                       'Cooling setpoint should typically be greater than or equal to 68 deg-F.'],
                              'slab-zero-exposed-perimeter' => ['Slab has zero exposed perimeter, this may indicate an input error.'] }

    all_expected_warnings.each_with_index do |(warning_case, expected_warnings), i|
      puts "[#{i + 1}/#{all_expected_warnings.size}] Testing #{warning_case}..."
      # Create HPXML object
      if ['dhw-efficiencies-low'].include? warning_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-dhw-multiple.xml'))
        hpxml.water_heating_systems.select { |w| w.water_heater_type == HPXML::WaterHeaterTypeStorage }[0].energy_factor = 0.1
        hpxml.water_heating_systems.select { |w| w.water_heater_type == HPXML::WaterHeaterTypeTankless }[0].energy_factor = 0.1
      elsif ['dhw-setpoint-low'].include? warning_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.water_heating_systems[0].temperature = 100
      elsif ['hvac-dse-low'].include? warning_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-hvac-dse.xml'))
        hpxml.hvac_distributions[0].annual_heating_dse = 0.1
        hpxml.hvac_distributions[0].annual_cooling_dse = 0.1
      elsif ['hvac-efficiencies-low'].include? warning_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-hvac-multiple.xml'))
        hpxml.heating_systems.select { |h| h.heating_system_type == HPXML::HVACTypeElectricResistance }[0].heating_efficiency_percent = 0.1
        hpxml.heating_systems.select { |h| h.heating_system_type == HPXML::HVACTypeFurnace }[0].heating_efficiency_afue = 0.1
        hpxml.heating_systems.select { |h| h.heating_system_type == HPXML::HVACTypeWallFurnace }[0].heating_efficiency_afue = 0.1
        hpxml.heating_systems.select { |h| h.heating_system_type == HPXML::HVACTypeBoiler }[0].heating_efficiency_afue = 0.1
        hpxml.heating_systems.select { |h| h.heating_system_type == HPXML::HVACTypeStove }[0].heating_efficiency_percent = 0.1
        hpxml.cooling_systems.select { |c| c.cooling_system_type == HPXML::HVACTypeCentralAirConditioner }[0].cooling_efficiency_seer = 0.1
        hpxml.cooling_systems.select { |c| c.cooling_system_type == HPXML::HVACTypeRoomAirConditioner }[0].cooling_efficiency_eer = 0.1
        hpxml.heat_pumps.select { |hp| hp.heat_pump_type == HPXML::HVACTypeHeatPumpAirToAir }[0].cooling_efficiency_seer = 0.1
        hpxml.heat_pumps.select { |hp| hp.heat_pump_type == HPXML::HVACTypeHeatPumpAirToAir }[0].heating_efficiency_hspf = 0.1
        hpxml.heat_pumps.select { |hp| hp.heat_pump_type == HPXML::HVACTypeHeatPumpMiniSplit }[0].cooling_efficiency_seer = 0.1
        hpxml.heat_pumps.select { |hp| hp.heat_pump_type == HPXML::HVACTypeHeatPumpMiniSplit }[0].heating_efficiency_hspf = 0.1
        hpxml.heat_pumps.select { |hp| hp.heat_pump_type == HPXML::HVACTypeHeatPumpGroundToAir }[0].cooling_efficiency_eer = 0.1
        hpxml.heat_pumps.select { |hp| hp.heat_pump_type == HPXML::HVACTypeHeatPumpGroundToAir }[0].heating_efficiency_cop = 0.1
      elsif ['hvac-setpoints-high'].include? warning_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.hvac_controls[0].heating_setpoint_temp = 100
        hpxml.hvac_controls[0].cooling_setpoint_temp = 100
      elsif ['hvac-setpoints-low'].include? warning_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.hvac_controls[0].heating_setpoint_temp = 0
        hpxml.hvac_controls[0].cooling_setpoint_temp = 0
      elsif ['slab-zero-exposed-perimeter'].include? warning_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.slabs[0].exposed_perimeter = 0
      else
        fail "Unhandled case: #{warning_case}."
      end

      hpxml_doc = hpxml.to_oga()

      # Test against schematron
      _test_schematron_validation(hpxml_doc, expected_warnings: expected_warnings)
    end
  end

  def test_measure_error_messages
    # Test case => Error message
    all_expected_errors = { 'cfis-with-hydronic-distribution' => ["Attached HVAC distribution system 'HVACDistribution1' cannot be hydronic for ventilation fan 'VentilationFan1'."],
                            'dehumidifier-setpoints' => ['All dehumidifiers must have the same setpoint but multiple setpoints were specified.'],
                            'duplicate-id' => ["Duplicate SystemIdentifier IDs detected for 'Window1'."],
                            'hvac-distribution-multiple-attached-cooling' => ["Multiple cooling systems found attached to distribution system 'HVACDistribution2'."],
                            'hvac-distribution-multiple-attached-heating' => ["Multiple heating systems found attached to distribution system 'HVACDistribution1'."],
                            'hvac-dse-multiple-attached-cooling' => ["Multiple cooling systems found attached to distribution system 'HVACDistribution1'."],
                            'hvac-dse-multiple-attached-heating' => ["Multiple heating systems found attached to distribution system 'HVACDistribution1'."],
                            'hvac-inconsistent-fan-powers' => ["Fan powers for heating system 'HeatingSystem1' and cooling system 'CoolingSystem1' are attached to a single distribution system and therefore must be the same."],
                            'hvac-invalid-distribution-system-type' => ["Incorrect HVAC distribution system type for HVAC type: 'Furnace'. Should be one of: ["],
                            'hvac-seasons-less-than-a-year' => ['HeatingSeason and CoolingSeason, when combined, must span the entire year.'],
                            'hvac-shared-boiler-multiple' => ['More than one shared heating system found.'],
                            'hvac-shared-chiller-multiple' => ['More than one shared cooling system found.'],
                            'hvac-shared-chiller-negative-seer-eq' => ["Negative SEER equivalent calculated for cooling system 'CoolingSystem1', double check inputs."],
                            'invalid-datatype-boolean' => ["Cannot convert 'FOOBAR' to boolean for Roof/RadiantBarrier."],
                            'invalid-datatype-integer' => ["Cannot convert '2.5' to integer for BuildingConstruction/NumberofBedrooms."],
                            'invalid-datatype-float' => ["Cannot convert 'FOOBAR' to float for Slab/extension/CarpetFraction."],
                            'invalid-daylight-saving' => ['Daylight Saving End Day of Month (31) must be one of: 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30.'],
                            'invalid-distribution-cfa-served' => ['The total conditioned floor area served by the HVAC distribution system(s) for heating is larger than the conditioned floor area of the building.',
                                                                  'The total conditioned floor area served by the HVAC distribution system(s) for cooling is larger than the conditioned floor area of the building.'],
                            'invalid-epw-filepath' => ["foo.epw' could not be found."],
                            'invalid-facility-type-surfaces' => ["The building is of type 'single-family detached' but the surface 'RimJoist2' is adjacent to Attached/Multifamily space 'other housing unit'.",
                                                                 "The building is of type 'single-family detached' but the surface 'Wall3' is adjacent to Attached/Multifamily space 'other housing unit'.",
                                                                 "The building is of type 'single-family detached' but the surface 'FoundationWall2' is adjacent to Attached/Multifamily space 'other housing unit'.",
                                                                 "The building is of type 'single-family detached' but the surface 'FrameFloor2' is adjacent to Attached/Multifamily space 'other housing unit'.",
                                                                 "The building is of type 'single-family detached' but the surface 'FrameFloor3' is adjacent to Attached/Multifamily space 'other housing unit'."],
                            'invalid-id' => ["Empty SystemIdentifier ID ('') detected for skylights."],
                            'invalid-neighbor-shading-azimuth' => ['A neighbor building has an azimuth (145) not equal to the azimuth of any wall.'],
                            'invalid-relatedhvac-dhw-indirect' => ["RelatedHVACSystem 'HeatingSystem_bad' not found for water heating system 'WaterHeatingSystem1'"],
                            'invalid-relatedhvac-desuperheater' => ["RelatedHVACSystem 'CoolingSystem_bad' not found for water heating system 'WaterHeatingSystem1'."],
                            'invalid-schema-version' => ['HPXML version 3.0 is required.'],
                            'invalid-skylights-physical-properties' => ["Could not lookup UFactor and SHGC for skylight 'Skylight2'."],
                            'invalid-timestep' => ['Timestep (45) must be one of: 60, 30, 20, 15, 12, 10, 6, 5, 4, 3, 2, 1.'],
                            'invalid-runperiod' => ['Run Period End Day of Month (31) must be one of: 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30.'],
                            'invalid-windows-physical-properties' => ["Could not lookup UFactor and SHGC for window 'Window3'."],
                            'multifamily-reference-appliance' => ["The building is of type 'single-family detached' but"],
                            'multifamily-reference-duct' => ["The building is of type 'single-family detached' but"],
                            'multifamily-reference-surface' => ["The building is of type 'single-family detached' but"],
                            'multifamily-reference-water-heater' => ["The building is of type 'single-family detached' but"],
                            'net-area-negative-wall' => ["Calculated a negative net surface area for surface 'Wall1'."],
                            'net-area-negative-roof' => ["Calculated a negative net surface area for surface 'Roof1'."],
                            'orphaned-hvac-distribution' => ["Distribution system 'HVACDistribution1' found but no HVAC system attached to it."],
                            'refrigerators-multiple-primary' => ['More than one refrigerator designated as the primary.'],
                            'refrigerators-no-primary' => ['Could not find a primary refrigerator.'],
                            'repeated-relatedhvac-dhw-indirect' => ["RelatedHVACSystem 'HeatingSystem1' is attached to multiple water heating systems."],
                            'repeated-relatedhvac-desuperheater' => ["RelatedHVACSystem 'CoolingSystem1' is attached to multiple water heating systems."],
                            'schedule-detailed-bad-values-max-not-one' => ["Schedule max value for column 'plug_loads_vehicle' must be 1. [context: HPXMLtoOpenStudio/resources/schedule_files/invalid-bad-values-max-not-one.csv]"],
                            'schedule-detailed-bad-values-negative' => ["Schedule min value for column 'plug_loads_well_pump' must be non-negative. [context: HPXMLtoOpenStudio/resources/schedule_files/invalid-bad-values-negative.csv]"],
                            'schedule-detailed-bad-values-non-numeric' => ["Schedule value must be numeric for column 'hot_water_fixtures'. [context: HPXMLtoOpenStudio/resources/schedule_files/invalid-bad-values-non-numeric.csv]"],
                            'schedule-detailed-wrong-columns' => ["Schedule column name 'lighting' is invalid. [context: HPXMLtoOpenStudio/resources/schedule_files/invalid-wrong-columns.csv]"],
                            'schedule-detailed-wrong-filename' => ["Schedules file path 'HPXMLtoOpenStudio/resources/schedule_files/invalid-wrong-filename.csv' does not exist."],
                            'schedule-detailed-wrong-rows' => ["Schedule has invalid number of rows (8759) for column 'refrigerator'. Must be one of: 8760, 17520, 26280, 35040, 43800, 52560, 87600, 105120, 131400, 175200, 262800, 525600. [context: HPXMLtoOpenStudio/resources/schedule_files/invalid-wrong-rows.csv]"],
                            'solar-thermal-system-with-combi-tankless' => ["Water heating system 'WaterHeatingSystem1' connected to solar thermal system 'SolarThermalSystem1' cannot be a space-heating boiler."],
                            'solar-thermal-system-with-desuperheater' => ["Water heating system 'WaterHeatingSystem1' connected to solar thermal system 'SolarThermalSystem1' cannot be attached to a desuperheater."],
                            'solar-thermal-system-with-dhw-indirect' => ["Water heating system 'WaterHeatingSystem1' connected to solar thermal system 'SolarThermalSystem1' cannot be a space-heating boiler."],
                            'unattached-cfis' => ["Attached HVAC distribution system 'foobar' not found for ventilation fan 'VentilationFan1'."],
                            'unattached-door' => ["Attached wall 'foobar' not found for door 'Door1'."],
                            'unattached-hvac-distribution' => ["Attached HVAC distribution system 'foobar' not found for HVAC system 'HeatingSystem1'."],
                            'unattached-skylight' => ["Attached roof 'foobar' not found for skylight 'Skylight1'."],
                            'unattached-solar-thermal-system' => ["Attached water heating system 'foobar' not found for solar thermal system 'SolarThermalSystem1'."],
                            'unattached-shared-clothes-washer-water-heater' => ["Attached water heating system 'foobar' not found for clothes washer"],
                            'unattached-shared-dishwasher-water-heater' => ["Attached water heating system 'foobar' not found for dishwasher"],
                            'unattached-window' => ["Attached wall 'foobar' not found for window 'Window1'."] }

    all_expected_errors.each_with_index do |(error_case, expected_errors), i|
      puts "[#{i + 1}/#{all_expected_errors.size}] Testing #{error_case}..."
      # Create HPXML object
      if ['cfis-with-hydronic-distribution'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-hvac-boiler-gas-only.xml'))
        hpxml.ventilation_fans.add(id: "VentilationFan#{hpxml.ventilation_fans.size + 1}",
                                   fan_type: HPXML::MechVentTypeCFIS,
                                   used_for_whole_building_ventilation: true,
                                   distribution_system_idref: hpxml.hvac_distributions[0].id)
      elsif ['dehumidifier-setpoints'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-appliances-dehumidifier-multiple.xml'))
        hpxml.dehumidifiers[-1].rh_setpoint = 0.55
      elsif ['duplicate-id'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.windows[-1].id = hpxml.windows[0].id
      elsif ['hvac-invalid-distribution-system-type'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.hvac_distributions.add(id: "HVACDistribution#{hpxml.hvac_distributions.size + 1}",
                                     distribution_system_type: HPXML::HVACDistributionTypeHydronic,
                                     hydronic_type: HPXML::HydronicTypeBaseboard)
        hpxml.heating_systems[-1].distribution_system_idref = hpxml.hvac_distributions[-1].id
      elsif ['hvac-distribution-multiple-attached-cooling'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-hvac-multiple.xml'))
        hpxml.heat_pumps[0].distribution_system_idref = 'HVACDistribution2'
      elsif ['hvac-distribution-multiple-attached-heating'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-hvac-multiple.xml'))
        hpxml.heat_pumps[0].distribution_system_idref = 'HVACDistribution1'
      elsif ['hvac-dse-multiple-attached-cooling'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-hvac-dse.xml'))
        hpxml.cooling_systems[0].fraction_cool_load_served = 0.5
        hpxml.cooling_systems << hpxml.cooling_systems[0].dup
        hpxml.cooling_systems[1].id = "CoolingSystem#{hpxml.cooling_systems.size}"
        hpxml.cooling_systems[0].primary_system = false
      elsif ['hvac-dse-multiple-attached-heating'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-hvac-dse.xml'))
        hpxml.heating_systems[0].fraction_heat_load_served = 0.5
        hpxml.heating_systems << hpxml.heating_systems[0].dup
        hpxml.heating_systems[1].id = "HeatingSystem#{hpxml.heating_systems.size}"
        hpxml.heating_systems[0].primary_system = false
      elsif ['hvac-inconsistent-fan-powers'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.cooling_systems[0].fan_watts_per_cfm = 0.55
        hpxml.heating_systems[0].fan_watts_per_cfm = 0.45
      elsif ['hvac-seasons-less-than-a-year'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.hvac_controls[0].seasons_heating_begin_month = 10
        hpxml.hvac_controls[0].seasons_heating_begin_day = 1
        hpxml.hvac_controls[0].seasons_heating_end_month = 5
        hpxml.hvac_controls[0].seasons_heating_end_day = 31
        hpxml.hvac_controls[0].seasons_cooling_begin_month = 7
        hpxml.hvac_controls[0].seasons_cooling_begin_day = 1
        hpxml.hvac_controls[0].seasons_cooling_end_month = 9
        hpxml.hvac_controls[0].seasons_cooling_end_day = 30
      elsif ['hvac-shared-boiler-multiple'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-bldgtype-multifamily-shared-boiler-only-baseboard.xml'))
        hpxml.hvac_distributions << hpxml.hvac_distributions[0].dup
        hpxml.hvac_distributions[-1].id = "HVACDistribution#{hpxml.hvac_distributions.size}"
        hpxml.heating_systems[0].fraction_heat_load_served = 0.5
        hpxml.heating_systems[0].primary_system = false
        hpxml.heating_systems << hpxml.heating_systems[0].dup
        hpxml.heating_systems[1].id = "HeatingSystem#{hpxml.heating_systems.size}"
        hpxml.heating_systems[1].distribution_system_idref = hpxml.hvac_distributions[-1].id
        hpxml.heating_systems[1].primary_system = true
      elsif ['hvac-shared-chiller-multiple'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-bldgtype-multifamily-shared-chiller-only-baseboard.xml'))
        hpxml.hvac_distributions << hpxml.hvac_distributions[0].dup
        hpxml.hvac_distributions[-1].id = "HVACDistribution#{hpxml.hvac_distributions.size}"
        hpxml.cooling_systems[0].fraction_cool_load_served = 0.5
        hpxml.cooling_systems[0].primary_system = false
        hpxml.cooling_systems << hpxml.cooling_systems[0].dup
        hpxml.cooling_systems[1].id = "CoolingSystem#{hpxml.cooling_systems.size}"
        hpxml.cooling_systems[1].distribution_system_idref = hpxml.hvac_distributions[-1].id
        hpxml.cooling_systems[1].primary_system = true
      elsif ['hvac-shared-chiller-negative-seer-eq'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-bldgtype-multifamily-shared-chiller-only-baseboard.xml'))
        hpxml.cooling_systems[0].shared_loop_watts *= 100.0
      elsif ['invalid-datatype-boolean'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
      elsif ['invalid-datatype-integer'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
      elsif ['invalid-datatype-float'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
      elsif ['invalid-daylight-saving'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-simcontrol-daylight-saving-custom.xml'))
        hpxml.header.dst_begin_month = 3
        hpxml.header.dst_begin_day = 10
        hpxml.header.dst_end_month = 4
        hpxml.header.dst_end_day = 31
      elsif ['invalid-distribution-cfa-served'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.hvac_distributions[-1].conditioned_floor_area_served = 2701.1
      elsif ['invalid-epw-filepath'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'foo.epw'
      elsif ['invalid-facility-type-surfaces'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.building_construction.residential_facility_type = HPXML::ResidentialTypeSFD
        hpxml.rim_joists.add(id: "RimJoist#{hpxml.rim_joists.size + 1}",
                             exterior_adjacent_to: HPXML::LocationOtherHousingUnit,
                             interior_adjacent_to: HPXML::LocationLivingSpace,
                             area: 116,
                             insulation_assembly_r_value: 23.0)
        hpxml.walls.add(id: "Wall#{hpxml.walls.size + 1}",
                        exterior_adjacent_to: HPXML::LocationOtherHousingUnit,
                        interior_adjacent_to: HPXML::LocationLivingSpace,
                        wall_type: HPXML::WallTypeWoodStud,
                        area: 294,
                        interior_finish_type: HPXML::InteriorFinishGypsumBoard,
                        insulation_assembly_r_value: 4.0)
        hpxml.foundation_walls.add(id: "FoundationWall#{hpxml.foundation_walls.size + 1}",
                                   exterior_adjacent_to: HPXML::LocationOtherHousingUnit,
                                   interior_adjacent_to: HPXML::LocationBasementConditioned,
                                   height: 8,
                                   area: 294,
                                   depth_below_grade: 7,
                                   interior_finish_type: HPXML::InteriorFinishGypsumBoard,
                                   insulation_interior_r_value: 0,
                                   insulation_exterior_r_value: 0)
        hpxml.frame_floors.add(id: "FrameFloor#{hpxml.frame_floors.size + 1}",
                               exterior_adjacent_to: HPXML::LocationOtherHousingUnit,
                               interior_adjacent_to: HPXML::LocationLivingSpace,
                               area: 900,
                               insulation_assembly_r_value: 2.1,
                               other_space_above_or_below: HPXML::FrameFloorOtherSpaceBelow)
        hpxml.frame_floors.add(id: "FrameFloor#{hpxml.frame_floors.size + 1}",
                               exterior_adjacent_to: HPXML::LocationOtherHousingUnit,
                               interior_adjacent_to: HPXML::LocationLivingSpace,
                               area: 900,
                               interior_finish_type: HPXML::InteriorFinishGypsumBoard,
                               insulation_assembly_r_value: 2.1,
                               other_space_above_or_below: HPXML::FrameFloorOtherSpaceAbove)
      elsif ['invalid-id'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-enclosure-skylights.xml'))
        hpxml.skylights[0].id = ''
      elsif ['invalid-neighbor-shading-azimuth'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-misc-neighbor-shading.xml'))
        hpxml.neighbor_buildings[0].azimuth = 145
      elsif ['invalid-relatedhvac-dhw-indirect'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-dhw-indirect.xml'))
        hpxml.water_heating_systems[0].related_hvac_idref = 'HeatingSystem_bad'
      elsif ['invalid-relatedhvac-desuperheater'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-hvac-central-ac-only-1-speed.xml'))
        hpxml.water_heating_systems[0].uses_desuperheater = true
        hpxml.water_heating_systems[0].related_hvac_idref = 'CoolingSystem_bad'
      elsif ['invalid-runperiod'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.header.sim_begin_month = 3
        hpxml.header.sim_begin_day = 10
        hpxml.header.sim_end_month = 4
        hpxml.header.sim_end_day = 31
      elsif ['invalid-schema-version'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
      elsif ['invalid-skylights-physical-properties'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-enclosure-skylights-physical-properties.xml'))
        hpxml.skylights[1].thermal_break = false
      elsif ['invalid-timestep'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.header.timestep = 45
      elsif ['invalid-windows-physical-properties'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-enclosure-windows-physical-properties.xml'))
        hpxml.windows[2].thermal_break = false
      elsif ['multifamily-reference-appliance'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.clothes_washers[0].location = HPXML::LocationOtherHousingUnit
      elsif ['multifamily-reference-duct'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.hvac_distributions[0].ducts[0].duct_location = HPXML::LocationOtherMultifamilyBufferSpace
      elsif ['multifamily-reference-surface'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.frame_floors << hpxml.frame_floors[0].dup
        hpxml.frame_floors[1].id = "FrameFloor#{hpxml.frame_floors.size}"
        hpxml.frame_floors[1].exterior_adjacent_to = HPXML::LocationOtherHeatedSpace
        hpxml.frame_floors[1].other_space_above_or_below = HPXML::FrameFloorOtherSpaceAbove
      elsif ['multifamily-reference-water-heater'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.water_heating_systems[0].location = HPXML::LocationOtherNonFreezingSpace
      elsif ['net-area-negative-roof'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-enclosure-skylights.xml'))
        hpxml.skylights[0].area = 4000
      elsif ['net-area-negative-wall'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.windows[0].area = 1000
      elsif ['orphaned-hvac-distribution'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-hvac-furnace-gas-room-ac.xml'))
        hpxml.heating_systems[0].delete
        hpxml.hvac_controls[0].heating_setpoint_temp = nil
      elsif ['refrigerators-multiple-primary'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-misc-loads-large-uncommon.xml'))
        hpxml.refrigerators[1].primary_indicator = true
      elsif ['refrigerators-no-primary'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-misc-loads-large-uncommon.xml'))
        hpxml.refrigerators[0].primary_indicator = false
      elsif ['repeated-relatedhvac-dhw-indirect'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-dhw-indirect.xml'))
        hpxml.water_heating_systems[0].fraction_dhw_load_served = 0.5
        hpxml.water_heating_systems << hpxml.water_heating_systems[0].dup
        hpxml.water_heating_systems[1].id = "WaterHeatingSystem#{hpxml.water_heating_systems.size}"
      elsif ['repeated-relatedhvac-desuperheater'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-hvac-central-ac-only-1-speed.xml'))
        hpxml.water_heating_systems[0].fraction_dhw_load_served = 0.5
        hpxml.water_heating_systems[0].uses_desuperheater = true
        hpxml.water_heating_systems[0].related_hvac_idref = 'CoolingSystem1'
        hpxml.water_heating_systems << hpxml.water_heating_systems[0].dup
        hpxml.water_heating_systems[1].id = "WaterHeatingSystem#{hpxml.water_heating_systems.size}"
      elsif ['schedule-detailed-bad-values-max-not-one'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.header.schedules_filepath = 'HPXMLtoOpenStudio/resources/schedule_files/invalid-bad-values-max-not-one.csv'
      elsif ['schedule-detailed-bad-values-negative'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.header.schedules_filepath = 'HPXMLtoOpenStudio/resources/schedule_files/invalid-bad-values-negative.csv'
      elsif ['schedule-detailed-bad-values-non-numeric'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.header.schedules_filepath = 'HPXMLtoOpenStudio/resources/schedule_files/invalid-bad-values-non-numeric.csv'
      elsif ['schedule-detailed-wrong-columns'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.header.schedules_filepath = 'HPXMLtoOpenStudio/resources/schedule_files/invalid-wrong-columns.csv'
      elsif ['schedule-detailed-wrong-filename'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.header.schedules_filepath = 'HPXMLtoOpenStudio/resources/schedule_files/invalid-wrong-filename.csv'
      elsif ['schedule-detailed-wrong-rows'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.header.schedules_filepath = 'HPXMLtoOpenStudio/resources/schedule_files/invalid-wrong-rows.csv'
      elsif ['solar-thermal-system-with-combi-tankless'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-dhw-combi-tankless.xml'))
        hpxml.solar_thermal_systems.add(id: "SolarThermalSystem#{hpxml.solar_thermal_systems.size + 1}",
                                        system_type: HPXML::SolarThermalSystemType,
                                        collector_area: 40,
                                        collector_type: HPXML::SolarThermalTypeSingleGlazing,
                                        collector_loop_type: HPXML::SolarThermalLoopTypeIndirect,
                                        collector_azimuth: 180,
                                        collector_tilt: 20,
                                        collector_frta: 0.77,
                                        collector_frul: 0.793,
                                        water_heating_system_idref: 'WaterHeatingSystem1')
      elsif ['solar-thermal-system-with-desuperheater'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-dhw-desuperheater.xml'))
        hpxml.solar_thermal_systems.add(id: "SolarThermalSystem#{hpxml.solar_thermal_systems.size + 1}",
                                        system_type: HPXML::SolarThermalSystemType,
                                        collector_area: 40,
                                        collector_type: HPXML::SolarThermalTypeSingleGlazing,
                                        collector_loop_type: HPXML::SolarThermalLoopTypeIndirect,
                                        collector_azimuth: 180,
                                        collector_tilt: 20,
                                        collector_frta: 0.77,
                                        collector_frul: 0.793,
                                        water_heating_system_idref: 'WaterHeatingSystem1')
      elsif ['solar-thermal-system-with-dhw-indirect'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-dhw-combi-tankless.xml'))
        hpxml.solar_thermal_systems.add(id: "SolarThermalSystem#{hpxml.solar_thermal_systems.size + 1}",
                                        system_type: HPXML::SolarThermalSystemType,
                                        collector_area: 40,
                                        collector_type: HPXML::SolarThermalTypeSingleGlazing,
                                        collector_loop_type: HPXML::SolarThermalLoopTypeIndirect,
                                        collector_azimuth: 180,
                                        collector_tilt: 20,
                                        collector_frta: 0.77,
                                        collector_frul: 0.793,
                                        water_heating_system_idref: 'WaterHeatingSystem1')
      elsif ['unattached-cfis'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.ventilation_fans.add(id: "VentilationFan#{hpxml.ventilation_fans.size + 1}",
                                   fan_type: HPXML::MechVentTypeCFIS,
                                   used_for_whole_building_ventilation: true,
                                   distribution_system_idref: hpxml.hvac_distributions[0].id)
        hpxml.ventilation_fans[0].distribution_system_idref = 'foobar'
      elsif ['unattached-door'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.doors[0].wall_idref = 'foobar'
      elsif ['unattached-hvac-distribution'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.heating_systems[0].distribution_system_idref = 'foobar'
      elsif ['unattached-skylight'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-enclosure-skylights.xml'))
        hpxml.skylights[0].roof_idref = 'foobar'
      elsif ['unattached-solar-thermal-system'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-dhw-solar-indirect-flat-plate.xml'))
        hpxml.solar_thermal_systems[0].water_heating_system_idref = 'foobar'
      elsif ['unattached-shared-clothes-washer-water-heater'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-bldgtype-multifamily-shared-laundry-room.xml'))
        hpxml.clothes_washers[0].water_heating_system_idref = 'foobar'
      elsif ['unattached-shared-dishwasher-water-heater'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-bldgtype-multifamily-shared-laundry-room.xml'))
        hpxml.dishwashers[0].water_heating_system_idref = 'foobar'
      elsif ['unattached-window'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.windows[0].wall_idref = 'foobar'
      else
        fail "Unhandled case: #{error_case}."
      end

      hpxml_doc = hpxml.to_oga()

      # Perform additional raw XML manipulation
      if ['invalid-datatype-boolean'].include? error_case
        XMLHelper.get_element(hpxml_doc, '/HPXML/Building/BuildingDetails/Enclosure/Roofs/Roof/RadiantBarrier').inner_text = 'FOOBAR'
      elsif ['invalid-datatype-integer'].include? error_case
        XMLHelper.get_element(hpxml_doc, '/HPXML/Building/BuildingDetails/BuildingSummary/BuildingConstruction/NumberofBedrooms').inner_text = '2.5'
      elsif ['invalid-datatype-float'].include? error_case
        XMLHelper.get_element(hpxml_doc, '/HPXML/Building/BuildingDetails/Enclosure/Slabs/Slab/extension/CarpetFraction').inner_text = 'FOOBAR'
      elsif ['invalid-schema-version'].include? error_case
        root = XMLHelper.get_element(hpxml_doc, '/HPXML')
        XMLHelper.add_attribute(root, 'schemaVersion', '2.3')
      end

      XMLHelper.write_file(hpxml_doc, @tmp_hpxml_path)
      model, hpxml = _test_measure(error_case, expected_errors)
    end
  end

  private

  def _test_schematron_validation(hpxml_doc, expected_errors: nil, expected_warnings: nil)
    # Validate via validator.rb
    errors, warnings = Validator.run_validators(hpxml_doc, [@epvalidator_stron_path, @hpxml_stron_path])
    if not expected_errors.nil?
      _compare_errors_or_warnings('error', errors, expected_errors)
    end
    if not expected_warnings.nil?
      _compare_errors_or_warnings('warning', warnings, expected_warnings)
    end
  end

  def _test_schema_validation(hpxml_doc, xml)
    # TODO: Remove this when schema validation is included with CLI calls
    schemas_dir = File.absolute_path(File.join(@root_path, 'HPXMLtoOpenStudio', 'resources'))
    errors = XMLHelper.validate(hpxml_doc.to_xml, File.join(schemas_dir, 'HPXML.xsd'), nil)
    if errors.size > 0
      flunk "#{xml}: #{errors}"
    end
  end

  def _test_measure(error_case, expected_errors)
    # create an instance of the measure
    measure = HPXMLtoOpenStudio.new

    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    model = OpenStudio::Model::Model.new

    # get arguments
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(@tmp_hpxml_path)
    args_hash['debug'] = true
    args_hash['output_dir'] = File.absolute_path(@tmp_output_path)
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

    assert_equal('Fail', result.value.valueName)

    errors = []
    result.stepErrors.each do |s|
      errors << s
    end
    _compare_errors_or_warnings('error', errors, expected_errors)
  end

  def _compare_errors_or_warnings(type, actual_msgs, expected_msgs)
    if expected_msgs.empty?
      if actual_msgs.size > 0
        flunk "Found unexpected #{type} messages:\n#{actual_msgs}"
      end
    else
      expected_msgs.each do |expected_msg|
        found_msg = false
        actual_msgs.each do |actual_msg|
          next unless actual_msg.include? expected_msg

          found_msg = true
          actual_msgs.delete(actual_msg)
          break
        end

        if not found_msg
          flunk "Did not find expected #{type} message\n'#{expected_msg}'\nin\n#{actual_msgs}"
        end
      end
      if actual_msgs.size > 0
        flunk "Found extra #{type} messages:\n#{actual_msgs}"
      end
    end
  end
end
