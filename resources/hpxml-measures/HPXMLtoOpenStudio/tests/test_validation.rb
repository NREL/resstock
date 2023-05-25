# frozen_string_literal: true

require_relative '../resources/minitest_helper'
require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'fileutils'
require_relative '../measure.rb'
require 'csv'
require_relative '../resources/xmlhelper.rb'
require_relative '../resources/xmlvalidator.rb'

class HPXMLtoOpenStudioValidationTest < MiniTest::Test
  def setup
    OpenStudio::Logger.instance.standardOutLogger.setLogLevel(OpenStudio::Fatal)

    @root_path = File.absolute_path(File.join(File.dirname(__FILE__), '..', '..'))
    @sample_files_path = File.join(@root_path, 'workflow', 'sample_files')
    schema_path = File.absolute_path(File.join(@root_path, 'HPXMLtoOpenStudio', 'resources', 'hpxml_schema', 'HPXML.xsd'))
    @schema_validator = XMLValidator.get_schema_validator(schema_path)
    @schematron_path = File.join(@root_path, 'HPXMLtoOpenStudio', 'resources', 'hpxml_schematron', 'EPvalidator.xml')
    @schematron_validator = XMLValidator.get_schematron_validator(@schematron_path)

    @tmp_hpxml_path = File.join(@sample_files_path, 'tmp.xml')
    @tmp_csv_path = File.join(@sample_files_path, 'tmp.csv')
    @tmp_output_path = File.join(@sample_files_path, 'tmp_output')
    FileUtils.mkdir_p(@tmp_output_path)
  end

  def teardown
    File.delete(@tmp_hpxml_path) if File.exist? @tmp_hpxml_path
    File.delete(@tmp_csv_path) if File.exist? @tmp_csv_path
    FileUtils.rm_rf(@tmp_output_path)
  end

  def test_validation_of_schematron_doc
    # Check that the schematron file is valid
    schematron_schema_path = File.absolute_path(File.join(@root_path, 'HPXMLtoOpenStudio', 'resources', 'hpxml_schematron', 'iso-schematron.xsd'))
    schematron_schema_validator = XMLValidator.get_schema_validator(schematron_schema_path)
    _test_schema_validation(@schematron_path, schematron_schema_validator)
  end

  def test_role_attributes_in_schematron_doc
    # Test for consistent use of errors/warnings
    puts
    puts 'Checking for correct role attributes...'

    schematron_doc = XMLHelper.parse_file(@schematron_path)

    # check that every assert element has a role attribute
    XMLHelper.get_elements(schematron_doc, '/sch:schema/sch:pattern/sch:rule/sch:assert').each do |assert_element|
      assert_test = XMLHelper.get_attribute_value(assert_element, 'test').gsub('h:', '')
      role_attribute = XMLHelper.get_attribute_value(assert_element, 'role')
      if role_attribute.nil?
        fail "No attribute \"role='ERROR'\" found for assertion test: #{assert_test}"
      end

      assert_equal('ERROR', role_attribute)
    end

    # check that every report element has a role attribute
    XMLHelper.get_elements(schematron_doc, '/sch:schema/sch:pattern/sch:rule/sch:report').each do |report_element|
      report_test = XMLHelper.get_attribute_value(report_element, 'test').gsub('h:', '')
      role_attribute = XMLHelper.get_attribute_value(report_element, 'role')
      if role_attribute.nil?
        fail "No attribute \"role='WARN'\" found for report test: #{report_test}"
      end

      assert_equal('WARN', role_attribute)
    end
  end

  def test_schema_schematron_error_messages
    OpenStudio::Logger.instance.standardOutLogger.setLogLevel(OpenStudio::Fatal)
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
                            'duct-leakage-cfm25' => ['Expected Value to be greater than or equal to 0 [context: /HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution/DistributionSystemType/AirDistribution/DuctLeakageMeasurement/DuctLeakage[Units="CFM25" or Units="CFM50"], id: "HVACDistribution1"]'],
                            'duct-leakage-cfm50' => ['Expected Value to be greater than or equal to 0 [context: /HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution/DistributionSystemType/AirDistribution/DuctLeakageMeasurement/DuctLeakage[Units="CFM25" or Units="CFM50"], id: "HVACDistribution1"]'],
                            'duct-leakage-percent' => ['Expected Value to be less than 1 [context: /HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution/DistributionSystemType/AirDistribution/DuctLeakageMeasurement/DuctLeakage[Units="Percent"], id: "HVACDistribution1"]'],
                            'duct-location' => ['A location is specified as "garage" but no surfaces were found adjacent to this space type.'],
                            'duct-location-unconditioned-space' => ["Expected DuctLocation to be 'living space' or 'basement - conditioned' or 'basement - unconditioned' or 'crawlspace - vented' or 'crawlspace - unvented' or 'crawlspace - conditioned' or 'attic - vented' or 'attic - unvented' or 'garage' or 'exterior wall' or 'under slab' or 'roof deck' or 'outside' or 'other housing unit' or 'other heated space' or 'other multifamily buffer space' or 'other non-freezing space' [context: /HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution/DistributionSystemType/AirDistribution/Ducts, id: \"Ducts1\"]",
                                                                    "Expected DuctLocation to be 'living space' or 'basement - conditioned' or 'basement - unconditioned' or 'crawlspace - vented' or 'crawlspace - unvented' or 'crawlspace - conditioned' or 'attic - vented' or 'attic - unvented' or 'garage' or 'exterior wall' or 'under slab' or 'roof deck' or 'outside' or 'other housing unit' or 'other heated space' or 'other multifamily buffer space' or 'other non-freezing space' [context: /HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution/DistributionSystemType/AirDistribution/Ducts, id: \"Ducts2\"]"],
                            'emissions-electricity-schedule' => ['Expected NumberofHeaderRows to be greater than or equal to 0',
                                                                 'Expected ColumnNumber to be greater than or equal to 1'],
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
                            'heat-pump-capacity-17f' => ['Expected HeatingCapacity17F to be less than or equal to HeatingCapacity'],
                            'heat-pump-lockout-temperatures' => ['Expected CompressorLockoutTemperature to be less than BackupHeatingLockoutTemperature'],
                            'heat-pump-multiple-backup-systems' => ['Expected 0 or 1 element(s) for xpath: HeatPump/BackupSystem [context: /HPXML/Building/BuildingDetails]'],
                            'hvac-distribution-return-duct-leakage-missing' => ['Expected 1 element(s) for xpath: DuctLeakageMeasurement[DuctType="return"]/DuctLeakage[(Units="CFM25" or Units="CFM50" or Units="Percent") and TotalOrToOutside="to outside"] [context: /HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution/DistributionSystemType/AirDistribution[AirDistributionType[text()="regular velocity" or text()="gravity"]], id: "HVACDistribution1"]'],
                            'hvac-frac-load-served' => ['Expected sum(FractionHeatLoadServed) to be less than or equal to 1 [context: /HPXML/Building/BuildingDetails]',
                                                        'Expected sum(FractionCoolLoadServed) to be less than or equal to 1 [context: /HPXML/Building/BuildingDetails]'],
                            'hvac-location-heating-system' => ['A location is specified as "basement - unconditioned" but no surfaces were found adjacent to this space type.'],
                            'hvac-location-cooling-system' => ['A location is specified as "basement - unconditioned" but no surfaces were found adjacent to this space type.'],
                            'hvac-location-heat-pump' => ['A location is specified as "basement - unconditioned" but no surfaces were found adjacent to this space type.'],
                            'hvac-sizing-humidity-setpoint' => ['Expected ManualJInputs/HumiditySetpoint to be less than 1'],
                            'hvac-negative-crankcase-heater-watts' => ['Expected extension/CrankcaseHeaterPowerWatts to be greater than or equal to 0.0.'],
                            'incomplete-integrated-heating' => ['Expected 1 element(s) for xpath: IntegratedHeatingSystemFractionHeatLoadServed'],
                            'invalid-airflow-defect-ratio' => ['Expected extension/AirflowDefectRatio to be 0'],
                            'invalid-assembly-effective-rvalue' => ["Element 'AssemblyEffectiveRValue': [facet 'minExclusive'] The value '0.0' must be greater than '0'."],
                            'invalid-battery-capacities-ah' => ['Expected UsableCapacity to be less than NominalCapacity'],
                            'invalid-battery-capacities-kwh' => ['Expected UsableCapacity to be less than NominalCapacity'],
                            'invalid-calendar-year-low' => ['Expected CalendarYear to be greater than or equal to 1600'],
                            'invalid-calendar-year-high' => ['Expected CalendarYear to be less than or equal to 9999'],
                            'invalid-duct-area-fractions' => ['Expected sum(Ducts/FractionDuctArea) for DuctType="supply" to be 1 [context: /HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution/DistributionSystemType/AirDistribution, id: "HVACDistribution1"]',
                                                              'Expected sum(Ducts/FractionDuctArea) for DuctType="return" to be 1 [context: /HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution/DistributionSystemType/AirDistribution, id: "HVACDistribution1"]'],
                            'invalid-facility-type' => ['Expected 1 element(s) for xpath: ../../../BuildingSummary/BuildingConstruction[ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]] [context: /HPXML/Building/BuildingDetails/Systems/WaterHeating/WaterHeatingSystem[IsSharedSystem="true"], id: "WaterHeatingSystem1"]',
                                                        'Expected 1 element(s) for xpath: ../../BuildingSummary/BuildingConstruction[ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]] [context: /HPXML/Building/BuildingDetails/Appliances/ClothesWasher[IsSharedAppliance="true"], id: "ClothesWasher1"]',
                                                        'Expected 1 element(s) for xpath: ../../BuildingSummary/BuildingConstruction[ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]] [context: /HPXML/Building/BuildingDetails/Appliances/ClothesDryer[IsSharedAppliance="true"], id: "ClothesDryer1"]',
                                                        'Expected 1 element(s) for xpath: ../../BuildingSummary/BuildingConstruction[ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]] [context: /HPXML/Building/BuildingDetails/Appliances/Dishwasher[IsSharedAppliance="true"], id: "Dishwasher1"]',
                                                        'There are references to "other housing unit" but ResidentialFacilityType is not "single-family attached" or "apartment unit".',
                                                        'There are references to "other heated space" but ResidentialFacilityType is not "single-family attached" or "apartment unit".'],
                            'invalid-foundation-wall-properties' => ['Expected DepthBelowGrade to be less than or equal to Height [context: /HPXML/Building/BuildingDetails/Enclosure/FoundationWalls/FoundationWall, id: "FoundationWall1"]',
                                                                     'Expected DistanceToBottomOfInsulation to be greater than or equal to DistanceToTopOfInsulation [context: /HPXML/Building/BuildingDetails/Enclosure/FoundationWalls/FoundationWall/Insulation/Layer[InstallationType="continuous - exterior" or InstallationType="continuous - interior"], id: "FoundationWall1Insulation"]',
                                                                     'Expected DistanceToBottomOfInsulation to be less than or equal to ../../Height [context: /HPXML/Building/BuildingDetails/Enclosure/FoundationWalls/FoundationWall/Insulation/Layer[InstallationType="continuous - exterior" or InstallationType="continuous - interior"], id: "FoundationWall1Insulation"]'],
                            'invalid-ground-conductivity' => ['Expected extension/GroundConductivity to be greater than 0'],
                            'invalid-heat-pump-capacity-retention' => ['Expected Fraction to be less than 1',
                                                                       'Expected Temperature to be less than or equal to 17'],
                            'invalid-heat-pump-capacity-retention2' => ['Expected Fraction to be greater than or equal to 0'],
                            'invalid-hvac-installation-quality' => ['Expected extension/AirflowDefectRatio to be greater than or equal to -0.9 [context: /HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatPump[HeatPumpType="air-to-air"], id: "HeatPump1"]',
                                                                    'Expected extension/ChargeDefectRatio to be greater than or equal to -0.9 [context: /HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatPump[HeatPumpType="air-to-air"], id: "HeatPump1"]'],
                            'invalid-hvac-installation-quality2' => ['Expected extension/AirflowDefectRatio to be less than or equal to 9 [context: /HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatPump[HeatPumpType="air-to-air"], id: "HeatPump1"]',
                                                                     'Expected extension/ChargeDefectRatio to be less than or equal to 9 [context: /HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatPump[HeatPumpType="air-to-air"], id: "HeatPump1"]'],
                            'invalid-id2' => ["Element 'SystemIdentifier': The attribute 'id' is required but missing."],
                            'invalid-input-parameters' => ["Element 'Transaction': [facet 'enumeration'] The value 'modify' is not an element of the set {'create', 'update'}.",
                                                           "Element 'SiteType': [facet 'enumeration'] The value 'mountain' is not an element of the set {'rural', 'suburban', 'urban'}.",
                                                           "Element 'Year': [facet 'enumeration'] The value '2020' is not an element of the set {'2021', '2018', '2015', '2012', '2009', '2006', '2003'}.",
                                                           "Element 'Azimuth': [facet 'maxExclusive'] The value '365' must be less than '360'.",
                                                           "Element 'RadiantBarrierGrade': [facet 'maxInclusive'] The value '4' is greater than the maximum value allowed ('3').",
                                                           "Element 'EnergyFactor': [facet 'maxInclusive'] The value '5.1' is greater than the maximum value allowed ('5')."],
                            'invalid-insulation-top' => ["Element 'DistanceToTopOfInsulation': [facet 'minInclusive'] The value '-0.5' is less than the minimum value allowed ('0')."],
                            'invalid-integrated-heating' => ['Expected 0 element(s) for xpath: IntegratedHeatingSystemFuel'],
                            'invalid-lighting-groups' => ['Expected 1 element(s) for xpath: ../LightingGroup[LightingType[CompactFluorescent] and Location="interior"]/FractionofUnitsInLocation | Load[Units="kWh/year"]/Value',
                                                          'Expected 1 element(s) for xpath: ../LightingGroup[LightingType[CompactFluorescent] and Location="interior"]/FractionofUnitsInLocation | Load[Units="kWh/year"]/Value',
                                                          'Expected 1 element(s) for xpath: ../LightingGroup[LightingType[CompactFluorescent] and Location="exterior"]/FractionofUnitsInLocation | Load[Units="kWh/year"]/Value',
                                                          'Expected 1 element(s) for xpath: ../LightingGroup[LightingType[CompactFluorescent] and Location="exterior"]/FractionofUnitsInLocation | Load[Units="kWh/year"]/Value',
                                                          'Expected 1 element(s) for xpath: ../LightingGroup[LightingType[CompactFluorescent] and Location="garage"]/FractionofUnitsInLocation | Load[Units="kWh/year"]/Value',
                                                          'Expected 1 element(s) for xpath: ../LightingGroup[LightingType[CompactFluorescent] and Location="garage"]/FractionofUnitsInLocation | Load[Units="kWh/year"]/Value'],
                            'invalid-lighting-groups2' => ['Expected 1 element(s) for xpath: ../LightingGroup[LightingType[CompactFluorescent] and Location="interior"]/FractionofUnitsInLocation | Load[Units="kWh/year"]/Value',
                                                           'Expected 1 element(s) for xpath: ../LightingGroup[LightingType[CompactFluorescent] and Location="interior"]/FractionofUnitsInLocation | Load[Units="kWh/year"]/Value',
                                                           'Expected 1 element(s) for xpath: ../LightingGroup[LightingType[CompactFluorescent] and Location="interior"]/FractionofUnitsInLocation | Load[Units="kWh/year"]/Value',
                                                           'Expected 1 element(s) for xpath: ../LightingGroup[LightingType[CompactFluorescent] and Location="interior"]/FractionofUnitsInLocation | Load[Units="kWh/year"]/Value',
                                                           'Expected 1 element(s) for xpath: ../LightingGroup[LightingType[CompactFluorescent] and Location="exterior"]/FractionofUnitsInLocation | Load[Units="kWh/year"]/Value',
                                                           'Expected 1 element(s) for xpath: ../LightingGroup[LightingType[CompactFluorescent] and Location="exterior"]/FractionofUnitsInLocation | Load[Units="kWh/year"]/Value',
                                                           'Expected 1 element(s) for xpath: ../LightingGroup[LightingType[CompactFluorescent] and Location="exterior"]/FractionofUnitsInLocation | Load[Units="kWh/year"]/Value',
                                                           'Expected 1 element(s) for xpath: ../LightingGroup[LightingType[CompactFluorescent] and Location="exterior"]/FractionofUnitsInLocation | Load[Units="kWh/year"]/Value',
                                                           'Expected 1 element(s) for xpath: ../LightingGroup[LightingType[CompactFluorescent] and Location="garage"]/FractionofUnitsInLocation | Load[Units="kWh/year"]/Value',
                                                           'Expected 1 element(s) for xpath: ../LightingGroup[LightingType[CompactFluorescent] and Location="garage"]/FractionofUnitsInLocation | Load[Units="kWh/year"]/Value',
                                                           'Expected 1 element(s) for xpath: ../LightingGroup[LightingType[CompactFluorescent] and Location="garage"]/FractionofUnitsInLocation | Load[Units="kWh/year"]/Value',
                                                           'Expected 1 element(s) for xpath: ../LightingGroup[LightingType[CompactFluorescent] and Location="garage"]/FractionofUnitsInLocation | Load[Units="kWh/year"]/Value'],
                            'invalid-natvent-availability' => ['Expected extension/NaturalVentilationAvailabilityDaysperWeek to be less than or equal to 7'],
                            'invalid-natvent-availability2' => ['Expected extension/NaturalVentilationAvailabilityDaysperWeek to be greater than or equal to 0'],
                            'invalid-number-of-bedrooms-served' => ['Expected extension/NumberofBedroomsServed to be greater than ../../../BuildingSummary/BuildingConstruction/NumberofBedrooms [context: /HPXML/Building/BuildingDetails/Systems/Photovoltaics/PVSystem[IsSharedSystem="true"], id: "PVSystem1"]'],
                            'invalid-number-of-conditioned-floors' => ['Expected NumberofConditionedFloors to be greater than or equal to NumberofConditionedFloorsAboveGrade [context: /HPXML/Building/BuildingDetails/BuildingSummary/BuildingConstruction]'],
                            'invalid-number-of-units-served' => ['Expected NumberofUnitsServed to be greater than 1 [context: /HPXML/Building/BuildingDetails/Systems/WaterHeating/WaterHeatingSystem[IsSharedSystem="true"], id: "WaterHeatingSystem1"]'],
                            'invalid-pilot-light-heating-system' => ['Expected 1 element(s) for xpath: ../../HeatingSystemFuel[text()!="electricity"]'],
                            'invalid-shared-vent-in-unit-flowrate' => ['Expected RatedFlowRate to be greater than extension/InUnitFlowRate [context: /HPXML/Building/BuildingDetails/Systems/MechanicalVentilation/VentilationFans/VentilationFan[UsedForWholeBuildingVentilation="true" and IsSharedSystem="true"], id: "VentilationFan1"]'],
                            'invalid-timestep' => ['Expected Timestep to be 60, 30, 20, 15, 12, 10, 6, 5, 4, 3, 2, or 1'],
                            'invalid-timezone-utcoffset-low' => ["Element 'UTCOffset': [facet 'minInclusive'] The value '-13.0' is less than the minimum value allowed ('-12')."],
                            'invalid-timezone-utcoffset-high' => ["Element 'UTCOffset': [facet 'maxInclusive'] The value '15.0' is greater than the maximum value allowed ('14')."],
                            'invalid-ventilation-fan' => ['Expected 1 element(s) for xpath: UsedForWholeBuildingVentilation[text()="true"] | UsedForLocalVentilation[text()="true"] | UsedForSeasonalCoolingLoadReduction[text()="true"] | UsedForGarageVentilation[text()="true"]'],
                            'invalid-ventilation-recovery' => ['Expected 0 element(s) for xpath: TotalRecoveryEfficiency | AdjustedTotalRecoveryEfficiency',
                                                               'Expected 0 element(s) for xpath: SensibleRecoveryEfficiency | AdjustedSensibleRecoveryEfficiency'],
                            'invalid-window-height' => ['Expected DistanceToBottomOfWindow to be greater than DistanceToTopOfWindow [context: /HPXML/Building/BuildingDetails/Enclosure/Windows/Window/Overhangs[number(Depth) > 0], id: "Window2"]'],
                            'lighting-fractions' => ['Expected sum(LightingGroup/FractionofUnitsInLocation) for Location="interior" to be less than or equal to 1 [context: /HPXML/Building/BuildingDetails/Lighting]'],
                            'missing-cfis-supplemental-fan' => ['Expected 1 element(s) for xpath: SupplementalFan'],
                            'missing-distribution-cfa-served' => ['Expected 1 element(s) for xpath: ../../../ConditionedFloorAreaServed [context: /HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution/DistributionSystemType/AirDistribution/Ducts[not(DuctSurfaceArea)], id: "Ducts2"]'],
                            'missing-duct-area' => ['Expected 1 or more element(s) for xpath: FractionDuctArea | DuctSurfaceArea [context: /HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution/DistributionSystemType/AirDistribution/Ducts[DuctLocation], id: "Ducts2"]'],
                            'missing-duct-location' => ['Expected 0 element(s) for xpath: FractionDuctArea | DuctSurfaceArea [context: /HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution/DistributionSystemType/AirDistribution/Ducts[not(DuctLocation)], id: "Ducts2"]'],
                            'missing-elements' => ['Expected 1 element(s) for xpath: NumberofConditionedFloors [context: /HPXML/Building/BuildingDetails/BuildingSummary/BuildingConstruction]',
                                                   'Expected 1 element(s) for xpath: ConditionedFloorArea [context: /HPXML/Building/BuildingDetails/BuildingSummary/BuildingConstruction]'],
                            'multifamily-reference-appliance' => ['There are references to "other housing unit" but ResidentialFacilityType is not "single-family attached" or "apartment unit".'],
                            'multifamily-reference-duct' => ['There are references to "other multifamily buffer space" but ResidentialFacilityType is not "single-family attached" or "apartment unit".'],
                            'multifamily-reference-surface' => ['There are references to "other heated space" but ResidentialFacilityType is not "single-family attached" or "apartment unit".'],
                            'multifamily-reference-water-heater' => ['There are references to "other non-freezing space" but ResidentialFacilityType is not "single-family attached" or "apartment unit".'],
                            'refrigerator-location' => ['A location is specified as "garage" but no surfaces were found adjacent to this space type.'],
                            'solar-fraction-one' => ['Expected SolarFraction to be less than 1 [context: /HPXML/Building/BuildingDetails/Systems/SolarThermal/SolarThermalSystem, id: "SolarThermalSystem1"]'],
                            'water-heater-location' => ['A location is specified as "crawlspace - vented" but no surfaces were found adjacent to this space type.'],
                            'water-heater-location-other' => ["Expected Location to be 'living space' or 'basement - unconditioned' or 'basement - conditioned' or 'attic - unvented' or 'attic - vented' or 'garage' or 'crawlspace - unvented' or 'crawlspace - vented' or 'crawlspace - conditioned' or 'other exterior' or 'other housing unit' or 'other heated space' or 'other multifamily buffer space' or 'other non-freezing space' [context: /HPXML/Building/BuildingDetails/Systems/WaterHeating/WaterHeatingSystem, id: \"WaterHeatingSystem1\"]"],
                            'water-heater-recovery-efficiency' => ['Expected RecoveryEfficiency to be greater than EnergyFactor'] }

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
      elsif ['duct-leakage-cfm50'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-hvac-ducts-leakage-cfm50.xml'))
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
      elsif ['emissions-electricity-schedule'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-misc-emissions.xml'))
        hpxml.header.emissions_scenarios[0].elec_schedule_number_of_header_rows = -1
        hpxml.header.emissions_scenarios[0].elec_schedule_column_number = 0
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
        hpxml.floors.select { |w|
          w.interior_adjacent_to == HPXML::LocationGarage &&
            w.exterior_adjacent_to == HPXML::LocationAtticUnvented
        }.reverse_each do |floor|
          floor.delete
        end
      elsif ['enclosure-garage-missing-slab'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-enclosure-garage.xml'))
        hpxml.slabs.select { |w| w.interior_adjacent_to == HPXML::LocationGarage }.reverse_each do |slab|
          slab.delete
        end
      elsif ['enclosure-living-missing-ceiling-roof'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.floors.reverse_each do |floor|
          floor.delete
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
      elsif ['heat-pump-capacity-17f'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-hvac-air-to-air-heat-pump-1-speed.xml'))
        hpxml.heat_pumps[0].heating_capacity_17F = hpxml.heat_pumps[0].heating_capacity + 1000.0
        hpxml.heat_pumps[0].heating_capacity_retention_fraction = nil
        hpxml.heat_pumps[0].heating_capacity_retention_temp = nil
      elsif ['heat-pump-lockout-temperatures'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-hvac-air-to-air-heat-pump-1-speed-lockout-temperatures.xml'))
        hpxml.heat_pumps[0].compressor_lockout_temp = hpxml.heat_pumps[0].backup_heating_lockout_temp + 1
      elsif ['heat-pump-multiple-backup-systems'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-hvac-air-to-air-heat-pump-var-speed-backup-boiler.xml'))
        hpxml.heating_systems << hpxml.heating_systems[0].dup
        hpxml.heating_systems[-1].id = 'HeatingSystem2'
        hpxml.heat_pumps[0].fraction_heat_load_served = 0.5
        hpxml.heat_pumps[0].fraction_cool_load_served = 0.5
        hpxml.heat_pumps << hpxml.heat_pumps[0].dup
        hpxml.heat_pumps[-1].id = 'HeatPump2'
        hpxml.heat_pumps[-1].primary_heating_system = false
        hpxml.heat_pumps[-1].primary_cooling_system = false
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
      elsif ['hvac-location-heating-system'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-hvac-boiler-oil-only.xml'))
        hpxml.heating_systems[0].location = HPXML::LocationBasementUnconditioned
      elsif ['hvac-location-cooling-system'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-hvac-central-ac-only-1-speed.xml'))
        hpxml.cooling_systems[0].location = HPXML::LocationBasementUnconditioned
      elsif ['hvac-location-heat-pump'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-hvac-air-to-air-heat-pump-1-speed.xml'))
        hpxml.heat_pumps[0].location = HPXML::LocationBasementUnconditioned
      elsif ['hvac-sizing-humidity-setpoint'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.header.manualj_humidity_setpoint = 50
      elsif ['hvac-negative-crankcase-heater-watts'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.cooling_systems[0].crankcase_heater_watts = -10
      elsif ['incomplete-integrated-heating'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-hvac-ptac-with-heating-electricity.xml'))
        hpxml.cooling_systems[0].integrated_heating_system_fraction_heat_load_served = nil
      elsif ['invalid-airflow-defect-ratio'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-hvac-mini-split-heat-pump-ductless.xml'))
        hpxml.heat_pumps[0].airflow_defect_ratio = -0.25
      elsif ['invalid-assembly-effective-rvalue'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.walls[0].insulation_assembly_r_value = 0.0
      elsif ['invalid-battery-capacities-ah'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-pv-battery-ah.xml'))
        hpxml.batteries[0].usable_capacity_ah = hpxml.batteries[0].nominal_capacity_ah
      elsif ['invalid-battery-capacities-kwh'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-pv-battery.xml'))
        hpxml.batteries[0].usable_capacity_kwh = hpxml.batteries[0].nominal_capacity_kwh
      elsif ['invalid-calendar-year-low'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.header.sim_calendar_year = 1575
      elsif ['invalid-calendar-year-high'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.header.sim_calendar_year = 20000
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
      elsif ['invalid-facility-type'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-bldgtype-multifamily-shared-laundry-room.xml'))
        hpxml.building_construction.residential_facility_type = HPXML::ResidentialTypeSFD
      elsif ['invalid-foundation-wall-properties'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-foundation-unconditioned-basement-wall-insulation.xml'))
        hpxml.foundation_walls[0].depth_below_grade = 9.0
        hpxml.foundation_walls[0].insulation_interior_distance_to_top = 12.0
        hpxml.foundation_walls[0].insulation_interior_distance_to_bottom = 10.0
      elsif ['invalid-ground-conductivity'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.site.ground_conductivity = 0.0
      elsif ['invalid-heat-pump-capacity-retention'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-hvac-air-to-air-heat-pump-1-speed.xml'))
        hpxml.heat_pumps[0].heating_capacity_17F = nil
        hpxml.heat_pumps[0].heating_capacity_retention_fraction = 1.5
        hpxml.heat_pumps[0].heating_capacity_retention_temp = 30
      elsif ['invalid-heat-pump-capacity-retention2'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-hvac-air-to-air-heat-pump-1-speed.xml'))
        hpxml.heat_pumps[0].heating_capacity_17F = nil
        hpxml.heat_pumps[0].heating_capacity_retention_fraction = -1
        hpxml.heat_pumps[0].heating_capacity_retention_temp = 5
      elsif ['invalid-hvac-installation-quality'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-hvac-air-to-air-heat-pump-1-speed.xml'))
        hpxml.heat_pumps[0].airflow_defect_ratio = -99
        hpxml.heat_pumps[0].charge_defect_ratio = -99
      elsif ['invalid-hvac-installation-quality2'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-hvac-air-to-air-heat-pump-1-speed.xml'))
        hpxml.heat_pumps[0].airflow_defect_ratio = 99
        hpxml.heat_pumps[0].charge_defect_ratio = 99
      elsif ['invalid-id2'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-enclosure-skylights.xml'))
      elsif ['invalid-input-parameters'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.header.transaction = 'modify'
        hpxml.site.site_type = 'mountain'
        hpxml.climate_and_risk_zones.climate_zone_ieccs[0].year = 2020
        hpxml.roofs.each do |roof|
          roof.radiant_barrier_grade = 4
        end
        hpxml.roofs[0].azimuth = 365
        hpxml.dishwashers[0].rated_annual_kwh = nil
        hpxml.dishwashers[0].energy_factor = 5.1
      elsif ['invalid-insulation-top'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.foundation_walls[0].insulation_interior_distance_to_top = -0.5
      elsif ['invalid-integrated-heating'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-hvac-central-ac-only-1-speed.xml'))
        hpxml.cooling_systems[0].integrated_heating_system_fuel = HPXML::FuelTypeElectricity
        hpxml.cooling_systems[0].integrated_heating_system_efficiency_percent = 0.98
        hpxml.cooling_systems[0].integrated_heating_system_fraction_heat_load_served = 1.0
      elsif ['invalid-lighting-groups'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-enclosure-garage.xml'))
        [HPXML::LocationInterior, HPXML::LocationExterior, HPXML::LocationGarage].each do |ltg_loc|
          hpxml.lighting_groups.each do |lg|
            next unless lg.location == ltg_loc

            lg.delete
            break
          end
        end
      elsif ['invalid-lighting-groups2'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-enclosure-garage.xml'))
        [HPXML::LocationInterior, HPXML::LocationExterior, HPXML::LocationGarage].each do |ltg_loc|
          hpxml.lighting_groups.each do |lg|
            next unless lg.location == ltg_loc

            hpxml.lighting_groups << lg.dup
            hpxml.lighting_groups[-1].id = "LightingGroup#{hpxml.lighting_groups.size}"
            hpxml.lighting_groups[-1].fraction_of_units_in_location = 0.0
            break
          end
        end
      elsif ['invalid-natvent-availability'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.header.natvent_days_per_week = 8
      elsif ['invalid-natvent-availability2'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.header.natvent_days_per_week = -1
      elsif ['invalid-number-of-bedrooms-served'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-bldgtype-multifamily-shared-pv.xml'))
        hpxml.pv_systems[0].number_of_bedrooms_served = 3
      elsif ['invalid-number-of-conditioned-floors'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.building_construction.number_of_conditioned_floors_above_grade = 3
      elsif ['invalid-number-of-units-served'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-bldgtype-multifamily-shared-water-heater.xml'))
        hpxml.water_heating_systems[0].number_of_units_served = 1
      elsif ['invalid-pilot-light-heating-system'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-hvac-floor-furnace-propane-only-pilot-light.xml'))
        hpxml.heating_systems[0].heating_system_fuel = HPXML::FuelTypeElectricity
      elsif ['invalid-shared-vent-in-unit-flowrate'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-bldgtype-multifamily-shared-mechvent.xml'))
        hpxml.ventilation_fans[0].rated_flow_rate = 80
      elsif ['invalid-timestep'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.header.timestep = 45
      elsif ['invalid-timezone-utcoffset-low'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.header.time_zone_utc_offset = -13
      elsif ['invalid-timezone-utcoffset-high'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.header.time_zone_utc_offset = 15
      elsif ['invalid-ventilation-fan'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-mechvent-exhaust.xml'))
        hpxml.ventilation_fans[0].used_for_garage_ventilation = true
      elsif ['invalid-ventilation-recovery'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-mechvent-exhaust.xml'))
        hpxml.ventilation_fans[0].sensible_recovery_efficiency = 0.72
        hpxml.ventilation_fans[0].total_recovery_efficiency = 0.48
      elsif ['invalid-window-height'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-enclosure-overhangs.xml'))
        hpxml.windows[1].overhangs_distance_to_bottom_of_window = 1.0
      elsif ['lighting-fractions'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        int_cfl = hpxml.lighting_groups.find { |lg| lg.location == HPXML::LocationInterior && lg.lighting_type == HPXML::LightingTypeCFL }
        int_cfl.fraction_of_units_in_location = 0.8
      elsif ['missing-cfis-supplemental-fan'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-mechvent-cfis.xml'))
        hpxml.ventilation_fans[0].cfis_addtl_runtime_operating_mode = HPXML::CFISModeSupplementalFan
      elsif ['missing-distribution-cfa-served'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.hvac_distributions[0].ducts[1].duct_surface_area = nil
        hpxml.hvac_distributions[0].ducts[1].duct_location = nil
      elsif ['missing-duct-area'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.hvac_distributions[0].conditioned_floor_area_served = hpxml.building_construction.conditioned_floor_area
        hpxml.hvac_distributions[0].ducts[1].duct_surface_area = nil
      elsif ['missing-duct-location'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.hvac_distributions[0].ducts[1].duct_location = nil
      elsif ['missing-elements'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.building_construction.number_of_conditioned_floors = nil
        hpxml.building_construction.conditioned_floor_area = nil
      elsif ['multifamily-reference-appliance'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.clothes_washers[0].location = HPXML::LocationOtherHousingUnit
      elsif ['multifamily-reference-duct'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.hvac_distributions[0].ducts[0].duct_location = HPXML::LocationOtherMultifamilyBufferSpace
      elsif ['multifamily-reference-surface'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.floors << hpxml.floors[0].dup
        hpxml.floors[1].id = "Floor#{hpxml.floors.size}"
        hpxml.floors[1].insulation_id = "FloorInsulation#{hpxml.floors.size}"
        hpxml.floors[1].exterior_adjacent_to = HPXML::LocationOtherHeatedSpace
        hpxml.floors[1].floor_or_ceiling = HPXML::FloorOrCeilingCeiling
      elsif ['multifamily-reference-water-heater'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.water_heating_systems[0].location = HPXML::LocationOtherNonFreezingSpace
      elsif ['refrigerator-location'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.refrigerators[0].location = HPXML::LocationGarage
      elsif ['solar-fraction-one'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-dhw-solar-fraction.xml'))
        hpxml.solar_thermal_systems[0].solar_fraction = 1.0
      elsif ['water-heater-location'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.water_heating_systems[0].location = HPXML::LocationCrawlspaceVented
      elsif ['water-heater-location-other'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.water_heating_systems[0].location = HPXML::LocationUnconditionedSpace
      elsif ['water-heater-recovery-efficiency'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-dhw-tank-gas.xml'))
        hpxml.water_heating_systems[0].recovery_efficiency = hpxml.water_heating_systems[0].energy_factor
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
      XMLHelper.write_file(hpxml_doc, @tmp_hpxml_path)
      _test_schema_and_schematron_validation(@tmp_hpxml_path, hpxml_doc, expected_errors: expected_errors)
    end
  end

  def test_schema_schematron_warning_messages
    OpenStudio::Logger.instance.standardOutLogger.setLogLevel(OpenStudio::Fatal)
    # Test case => Warning message
    all_expected_warnings = { 'battery-pv-output-power-low' => ['Max power output should typically be greater than or equal to 500 W.',
                                                                'Max power output should typically be greater than or equal to 500 W.',
                                                                'Rated power output should typically be greater than or equal to 1000 W.'],
                              'dhw-capacities-low' => ['Heating capacity should typically be greater than or equal to 1000 Btu/hr.',
                                                       'Heating capacity should typically be greater than or equal to 1000 Btu/hr.',
                                                       'No space cooling specified, the model will not include space cooling energy use.'],
                              'dhw-efficiencies-low' => ['EnergyFactor should typically be greater than or equal to 0.45.',
                                                         'EnergyFactor should typically be greater than or equal to 0.45.',
                                                         'EnergyFactor should typically be greater than or equal to 0.45.',
                                                         'EnergyFactor should typically be greater than or equal to 0.45.',
                                                         'No space cooling specified, the model will not include space cooling energy use.'],
                              'dhw-setpoint-low' => ['Hot water setpoint should typically be greater than or equal to 110 deg-F.'],
                              'erv-atre-low' => ['Adjusted total recovery efficiency should typically be at least half of the adjusted sensible recovery efficiency.'],
                              'erv-tre-low' => ['Total recovery efficiency should typically be at least half of the sensible recovery efficiency.'],
                              'garage-ventilation' => ['Ventilation fans for the garage are not currently modeled.'],
                              'heat-pump-low-backup-switchover-temp' => ['BackupHeatingSwitchoverTemperature is below 30 deg-F; this may result in significant unmet hours if the heat pump does not have sufficient capacity.'],
                              'heat-pump-low-backup-lockout-temp' => ['BackupHeatingLockoutTemperature is below 30 deg-F; this may result in significant unmet hours if the heat pump does not have sufficient capacity.'],
                              'hvac-dse-low' => ['Heating DSE should typically be greater than or equal to 0.5.',
                                                 'Cooling DSE should typically be greater than or equal to 0.5.'],
                              'hvac-capacities-low' => ['Heating capacity should typically be greater than or equal to 1000 Btu/hr.',
                                                        'Heating capacity should typically be greater than or equal to 1000 Btu/hr.',
                                                        'Heating capacity should typically be greater than or equal to 1000 Btu/hr.',
                                                        'Heating capacity should typically be greater than or equal to 1000 Btu/hr.',
                                                        'Heating capacity should typically be greater than or equal to 1000 Btu/hr.',
                                                        'Heating capacity should typically be greater than or equal to 1000 Btu/hr.',
                                                        'Heating capacity should typically be greater than or equal to 1000 Btu/hr.',
                                                        'Cooling capacity should typically be greater than or equal to 1000 Btu/hr.',
                                                        'Cooling capacity should typically be greater than or equal to 1000 Btu/hr.',
                                                        'Cooling capacity should typically be greater than or equal to 1000 Btu/hr.',
                                                        'Heating capacity should typically be greater than or equal to 1000 Btu/hr.',
                                                        'Cooling capacity should typically be greater than or equal to 1000 Btu/hr.',
                                                        'Heating capacity should typically be greater than or equal to 1000 Btu/hr.',
                                                        'Cooling capacity should typically be greater than or equal to 1000 Btu/hr.',
                                                        'Heating capacity should typically be greater than or equal to 1000 Btu/hr.',
                                                        'Cooling capacity should typically be greater than or equal to 1000 Btu/hr.',
                                                        'Backup heating capacity should typically be greater than or equal to 1000 Btu/hr.',
                                                        'Backup heating capacity should typically be greater than or equal to 1000 Btu/hr.',
                                                        'Backup heating capacity should typically be greater than or equal to 1000 Btu/hr.'],
                              'hvac-efficiencies-low' => ['Percent efficiency should typically be greater than or equal to 0.95.',
                                                          'AFUE should typically be greater than or equal to 0.5.',
                                                          'AFUE should typically be greater than or equal to 0.5.',
                                                          'AFUE should typically be greater than or equal to 0.5.',
                                                          'AFUE should typically be greater than or equal to 0.5.',
                                                          'AFUE should typically be greater than or equal to 0.5.',
                                                          'Percent efficiency should typically be greater than or equal to 0.5.',
                                                          'SEER should typically be greater than or equal to 8.',
                                                          'EER should typically be greater than or equal to 8.',
                                                          'SEER should typically be greater than or equal to 8.',
                                                          'HSPF should typically be greater than or equal to 6.',
                                                          'SEER should typically be greater than or equal to 8.',
                                                          'HSPF should typically be greater than or equal to 6.',
                                                          'EER should typically be greater than or equal to 8.',
                                                          'COP should typically be greater than or equal to 2.'],
                              'hvac-setpoints-high' => ['Heating setpoint should typically be less than or equal to 76 deg-F.',
                                                        'Cooling setpoint should typically be less than or equal to 86 deg-F.'],
                              'hvac-setpoints-low' => ['Heating setpoint should typically be greater than or equal to 58 deg-F.',
                                                       'Cooling setpoint should typically be greater than or equal to 68 deg-F.'],
                              'integrated-heating-efficiency-low' => ['Percent efficiency should typically be greater than or equal to 0.5.'],
                              'lighting-groups-missing' => ['No interior lighting specified, the model will not include interior lighting energy use.',
                                                            'No exterior lighting specified, the model will not include exterior lighting energy use.',
                                                            'No garage lighting specified, the model will not include garage lighting energy use.'],
                              'missing-attached-surfaces' => ['ResidentialFacilityType is single-family attached or apartment unit, but no attached surfaces were found. This may result in erroneous results (e.g., for infiltration).'],
                              'slab-zero-exposed-perimeter' => ['Slab has zero exposed perimeter, this may indicate an input error.'],
                              'wrong-units' => ['Thickness is greater than 12 inches; this may indicate incorrect units.',
                                                'Thickness is less than 1 inch; this may indicate incorrect units.',
                                                'Depth is greater than 72 feet; this may indicate incorrect units.',
                                                'DistanceToTopOfWindow is greater than 12 feet; this may indicate incorrect units.'] }

    all_expected_warnings.each_with_index do |(warning_case, expected_warnings), i|
      puts "[#{i + 1}/#{all_expected_warnings.size}] Testing #{warning_case}..."
      # Create HPXML object
      if ['battery-pv-output-power-low'].include? warning_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-pv-battery.xml'))
        hpxml.batteries[0].rated_power_output = 0.1
        hpxml.pv_systems[0].max_power_output = 0.1
        hpxml.pv_systems[1].max_power_output = 0.1
      elsif ['dhw-capacities-low'].include? warning_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-dhw-multiple.xml'))
        hpxml.water_heating_systems.each do |water_heating_system|
          if [HPXML::WaterHeaterTypeStorage].include? water_heating_system.water_heater_type
            water_heating_system.heating_capacity = 0.1
          end
        end
      elsif ['dhw-efficiencies-low'].include? warning_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-dhw-multiple.xml'))
        hpxml.water_heating_systems.each do |water_heating_system|
          if [HPXML::WaterHeaterTypeStorage,
              HPXML::WaterHeaterTypeTankless].include? water_heating_system.water_heater_type
            water_heating_system.energy_factor = 0.1
          end
        end
      elsif ['dhw-setpoint-low'].include? warning_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.water_heating_systems[0].temperature = 100
      elsif ['erv-atre-low'].include? warning_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-mechvent-erv-atre-asre.xml'))
        hpxml.ventilation_fans[0].total_recovery_efficiency_adjusted = 0.1
      elsif ['erv-tre-low'].include? warning_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-mechvent-erv.xml'))
        hpxml.ventilation_fans[0].total_recovery_efficiency = 0.1
      elsif ['garage-ventilation'].include? warning_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.ventilation_fans.add(id: 'VentilationFan1',
                                   used_for_garage_ventilation: true)
      elsif ['heat-pump-low-backup-switchover-temp'].include? warning_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-hvac-dual-fuel-air-to-air-heat-pump-1-speed.xml'))
        hpxml.heat_pumps[0].backup_heating_switchover_temp = 25.0
      elsif ['heat-pump-low-backup-lockout-temp'].include? warning_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-hvac-air-to-air-heat-pump-1-speed-lockout-temperatures.xml'))
        hpxml.heat_pumps[0].backup_heating_lockout_temp = 25.0
      elsif ['hvac-dse-low'].include? warning_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-hvac-dse.xml'))
        hpxml.hvac_distributions[0].annual_heating_dse = 0.1
        hpxml.hvac_distributions[0].annual_cooling_dse = 0.1
      elsif ['hvac-capacities-low'].include? warning_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-hvac-multiple.xml'))
        hpxml.hvac_systems.each do |hvac_system|
          if hvac_system.is_a? HPXML::HeatingSystem
            hvac_system.heating_capacity = 0.1
          elsif hvac_system.is_a? HPXML::CoolingSystem
            hvac_system.cooling_capacity = 0.1
          elsif hvac_system.is_a? HPXML::HeatPump
            hvac_system.heating_capacity = 0.1
            hvac_system.cooling_capacity = 0.1
            hvac_system.backup_heating_capacity = 0.1
          end
        end
      elsif ['hvac-efficiencies-low'].include? warning_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-hvac-multiple.xml'))
        hpxml.hvac_systems.each do |hvac_system|
          if hvac_system.is_a? HPXML::HeatingSystem
            if [HPXML::HVACTypeElectricResistance,
                HPXML::HVACTypeStove].include? hvac_system.heating_system_type
              hvac_system.heating_efficiency_percent = 0.1
            elsif [HPXML::HVACTypeFurnace,
                   HPXML::HVACTypeWallFurnace,
                   HPXML::HVACTypeBoiler].include? hvac_system.heating_system_type
              hvac_system.heating_efficiency_afue = 0.1
            end
          elsif hvac_system.is_a? HPXML::CoolingSystem
            if [HPXML::HVACTypeCentralAirConditioner].include? hvac_system.cooling_system_type
              hvac_system.cooling_efficiency_seer = 0.1
            elsif [HPXML::HVACTypeRoomAirConditioner].include? hvac_system.cooling_system_type
              hvac_system.cooling_efficiency_eer = 0.1
            end
          elsif hvac_system.is_a? HPXML::HeatPump
            if [HPXML::HVACTypeHeatPumpAirToAir,
                HPXML::HVACTypeHeatPumpMiniSplit].include? hvac_system.heat_pump_type
              hvac_system.cooling_efficiency_seer = 0.1
              hvac_system.heating_efficiency_hspf = 0.1
            elsif [HPXML::HVACTypeHeatPumpGroundToAir].include? hvac_system.heat_pump_type
              hvac_system.cooling_efficiency_eer = 0.1
              hvac_system.heating_efficiency_cop = 0.1
            end
          end
        end
      elsif ['hvac-setpoints-high'].include? warning_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.hvac_controls[0].heating_setpoint_temp = 100
        hpxml.hvac_controls[0].cooling_setpoint_temp = 100
      elsif ['hvac-setpoints-low'].include? warning_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.hvac_controls[0].heating_setpoint_temp = 0
        hpxml.hvac_controls[0].cooling_setpoint_temp = 0
      elsif ['integrated-heating-efficiency-low'].include? warning_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-hvac-ptac-with-heating-electricity.xml'))
        hpxml.cooling_systems[0].integrated_heating_system_efficiency_percent = 0.4
      elsif ['lighting-groups-missing'].include? warning_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-enclosure-garage.xml'))
        hpxml.lighting_groups.reverse_each do |lg|
          lg.delete
        end
      elsif ['missing-attached-surfaces'].include? warning_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.building_construction.residential_facility_type = HPXML::ResidentialTypeSFA
        hpxml.air_infiltration_measurements[0].infiltration_type = HPXML::InfiltrationTypeUnitExterior
      elsif ['slab-zero-exposed-perimeter'].include? warning_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.slabs[0].exposed_perimeter = 0
      elsif ['wrong-units'].include? warning_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-enclosure-overhangs.xml'))
        hpxml.slabs[0].thickness = 0.5
        hpxml.foundation_walls[0].thickness = 72.0
        hpxml.windows[0].overhangs_depth = 120.0
        hpxml.windows[0].overhangs_distance_to_top_of_window = 24.0
        hpxml.windows[0].overhangs_distance_to_bottom_of_window = 48.0
      else
        fail "Unhandled case: #{warning_case}."
      end

      hpxml_doc = hpxml.to_oga()

      # Test against schematron
      XMLHelper.write_file(hpxml_doc, @tmp_hpxml_path)
      _test_schema_and_schematron_validation(@tmp_hpxml_path, hpxml_doc, expected_warnings: expected_warnings)
    end
  end

  def test_ruby_error_messages
    # Test case => Error message
    all_expected_errors = { 'battery-bad-values-max-not-one' => ["Schedule max value for column 'battery' must be 1."],
                            'battery-bad-values-min-not-neg-one' => ["Schedule min value for column 'battery' must be -1."],
                            'cfis-with-hydronic-distribution' => ["Attached HVAC distribution system 'HVACDistribution1' cannot be hydronic for ventilation fan 'VentilationFan1'."],
                            'cfis-invalid-supplemental-fan' => ["CFIS supplemental fan 'VentilationFan2' must be of type 'supply only' or 'exhaust only'."],
                            'cfis-invalid-supplemental-fan2' => ["CFIS supplemental fan 'VentilationFan2' must be set as used for whole building ventilation."],
                            'cfis-invalid-supplemental-fan3' => ["CFIS supplemental fan 'VentilationFan2' cannot be a shared system."],
                            'cfis-invalid-supplemental-fan4' => ["CFIS supplemental fan 'VentilationFan2' cannot have HoursInOperation specified."],
                            'dehumidifier-setpoints' => ['All dehumidifiers must have the same setpoint but multiple setpoints were specified.'],
                            'desuperheater-with-detailed-setpoints' => ["Detailed setpoints for water heating system 'WaterHeatingSystem1' is not currently supported for desuperheaters."],
                            'duplicate-id' => ["Element 'SystemIdentifier', attribute 'id': 'PlugLoad1' is not a valid value of the atomic type 'xs:ID'."],
                            'emissions-duplicate-names' => ['Found multiple Emissions Scenarios with the Scenario Name='],
                            'emissions-wrong-columns' => ['Emissions File has too few columns. Cannot find column number'],
                            'emissions-wrong-filename' => ["Emissions File file path 'invalid-wrong-filename.csv' does not exist."],
                            'emissions-wrong-rows' => ['Emissions File has invalid number of rows'],
                            'heat-pump-backup-system-load-fraction' => ['Heat pump backup system cannot have a fraction heat load served specified.'],
                            'heat-pump-switchover-temp-elec-backup' => ['Switchover temperature should not be used for a heat pump with electric backup; use compressor lockout temperature instead.'],
                            'hvac-distribution-multiple-attached-cooling' => ["Multiple cooling systems found attached to distribution system 'HVACDistribution2'."],
                            'hvac-distribution-multiple-attached-heating' => ["Multiple heating systems found attached to distribution system 'HVACDistribution1'."],
                            'hvac-dse-multiple-attached-cooling' => ["Multiple cooling systems found attached to distribution system 'HVACDistribution1'."],
                            'hvac-dse-multiple-attached-heating' => ["Multiple heating systems found attached to distribution system 'HVACDistribution1'."],
                            'hvac-inconsistent-fan-powers' => ["Fan powers for heating system 'HeatingSystem1' and cooling system 'CoolingSystem1' are attached to a single distribution system and therefore must be the same."],
                            'hvac-invalid-distribution-system-type' => ["Incorrect HVAC distribution system type for HVAC type: 'Furnace'. Should be one of: ["],
                            'hvac-shared-boiler-multiple' => ['More than one shared heating system found.'],
                            'hvac-shared-chiller-multiple' => ['More than one shared cooling system found.'],
                            'hvac-shared-chiller-negative-seer-eq' => ["Negative SEER equivalent calculated for cooling system 'CoolingSystem1', double check inputs."],
                            'invalid-battery-capacity-units' => ["UsableCapacity and NominalCapacity for Battery 'Battery1' must be in the same units."],
                            'invalid-battery-capacity-units2' => ["UsableCapacity and NominalCapacity for Battery 'Battery1' must be in the same units."],
                            'invalid-datatype-boolean' => ["Element 'RadiantBarrier': 'FOOBAR' is not a valid value of the atomic type 'xs:boolean'"],
                            'invalid-datatype-integer' => ["Element 'NumberofBedrooms': '2.5' is not a valid value of the atomic type 'IntegerGreaterThanOrEqualToZero_simple'."],
                            'invalid-datatype-float' => ["Cannot convert 'FOOBAR' to float for Slab/extension/CarpetFraction."],
                            'invalid-daylight-saving' => ['Daylight Saving End Day of Month (31) must be one of: 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30.'],
                            'invalid-distribution-cfa-served' => ['The total conditioned floor area served by the HVAC distribution system(s) for heating is larger than the conditioned floor area of the building.',
                                                                  'The total conditioned floor area served by the HVAC distribution system(s) for cooling is larger than the conditioned floor area of the building.'],
                            'invalid-epw-filepath' => ["foo.epw' could not be found."],
                            'invalid-id' => ["Element 'SystemIdentifier', attribute 'id': '' is not a valid value of the atomic type 'xs:ID'."],
                            'invalid-neighbor-shading-azimuth' => ['A neighbor building has an azimuth (145) not equal to the azimuth of any wall.'],
                            'invalid-relatedhvac-dhw-indirect' => ["RelatedHVACSystem 'HeatingSystem_bad' not found for water heating system 'WaterHeatingSystem1'"],
                            'invalid-relatedhvac-desuperheater' => ["RelatedHVACSystem 'CoolingSystem_bad' not found for water heating system 'WaterHeatingSystem1'."],
                            'invalid-schema-version' => ["Element 'HPXML', attribute 'schemaVersion'"],
                            'invalid-skylights-physical-properties' => ["Could not lookup UFactor and SHGC for skylight 'Skylight2'."],
                            'invalid-runperiod' => ['Run Period End Day of Month (31) must be one of: 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30.'],
                            'invalid-shading-season' => ['Shading Summer Season End Day of Month (31) must be one of: 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30.'],
                            'invalid-unavailable-period' => ['Unavailable Period End Day of Month (31) must be one of: 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30.'],
                            'invalid-windows-physical-properties' => ["Could not lookup UFactor and SHGC for window 'Window3'."],
                            'inverter-unequal-efficiencies' => ['Expected all InverterEfficiency values to be equal.'],
                            'leap-year-TMY' => ['Specified a leap year (2008) but weather data has 8760 hours.'],
                            'net-area-negative-wall' => ["Calculated a negative net surface area for surface 'Wall1'."],
                            'net-area-negative-roof' => ["Calculated a negative net surface area for surface 'Roof1'."],
                            'orphaned-hvac-distribution' => ["Distribution system 'HVACDistribution1' found but no HVAC system attached to it."],
                            'refrigerators-multiple-primary' => ['More than one refrigerator designated as the primary.'],
                            'refrigerators-no-primary' => ['Could not find a primary refrigerator.'],
                            'repeated-relatedhvac-dhw-indirect' => ["RelatedHVACSystem 'HeatingSystem1' is attached to multiple water heating systems."],
                            'repeated-relatedhvac-desuperheater' => ["RelatedHVACSystem 'CoolingSystem1' is attached to multiple water heating systems."],
                            'schedule-detailed-bad-values-max-not-one' => ["Schedule max value for column 'lighting_interior' must be 1."],
                            'schedule-detailed-bad-values-negative' => ["Schedule min value for column 'lighting_interior' must be non-negative."],
                            'schedule-detailed-bad-values-non-numeric' => ["Schedule value must be numeric for column 'lighting_interior'."],
                            'schedule-detailed-bad-values-mode-negative' => ["Schedule value for column 'water_heater_operating_mode' must be either 0 or 1."],
                            'schedule-detailed-duplicate-columns' => ["Schedule column name 'occupants' is duplicated."],
                            'schedule-detailed-wrong-filename' => ["Schedules file path 'invalid-wrong-filename.csv' does not exist."],
                            'schedule-detailed-wrong-rows' => ["Schedule has invalid number of rows (8759) for column 'occupants'. Must be one of: 8760, 17520, 26280, 35040, 43800, 52560, 87600, 105120, 131400, 175200, 262800, 525600."],
                            'solar-thermal-system-with-combi-tankless' => ["Water heating system 'WaterHeatingSystem1' connected to solar thermal system 'SolarThermalSystem1' cannot be a space-heating boiler."],
                            'solar-thermal-system-with-desuperheater' => ["Water heating system 'WaterHeatingSystem1' connected to solar thermal system 'SolarThermalSystem1' cannot be attached to a desuperheater."],
                            'solar-thermal-system-with-dhw-indirect' => ["Water heating system 'WaterHeatingSystem1' connected to solar thermal system 'SolarThermalSystem1' cannot be a space-heating boiler."],
                            'storm-windows-unexpected-window-ufactor' => ['Unexpected base window U-Factor (0.33) for a storm window.'],
                            'unattached-cfis' => ["Attached HVAC distribution system 'foobar' not found for ventilation fan 'VentilationFan1'."],
                            'unattached-door' => ["Attached wall 'foobar' not found for door 'Door1'."],
                            'unattached-hvac-distribution' => ["Attached HVAC distribution system 'foobar' not found for HVAC system 'HeatingSystem1'."],
                            'unattached-pv-system' => ["Attached inverter 'foobar' not found for pv system 'PVSystem1'."],
                            'unattached-skylight' => ["Attached roof 'foobar' not found for skylight 'Skylight1'."],
                            'unattached-solar-thermal-system' => ["Attached water heating system 'foobar' not found for solar thermal system 'SolarThermalSystem1'."],
                            'unattached-shared-clothes-washer-dhw-distribution' => ["Attached hot water distribution 'foobar' not found for clothes washer"],
                            'unattached-shared-clothes-washer-water-heater' => ["Attached water heating system 'foobar' not found for clothes washer"],
                            'unattached-shared-dishwasher-dhw-distribution' => ["Attached hot water distribution 'foobar' not found for dishwasher"],
                            'unattached-shared-dishwasher-water-heater' => ["Attached water heating system 'foobar' not found for dishwasher"],
                            'unattached-window' => ["Attached wall 'foobar' not found for window 'Window1'."],
                            'unavailable-period-missing-column' => ["Could not find column='foobar' in unavailable_periods.csv."] }

    all_expected_errors.each_with_index do |(error_case, expected_errors), i|
      puts "[#{i + 1}/#{all_expected_errors.size}] Testing #{error_case}..."
      # Create HPXML object
      if ['battery-bad-values-max-not-one'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-battery-scheduled.xml'))
        csv_data = CSV.read(File.join(File.dirname(hpxml.hpxml_path), hpxml.header.schedules_filepaths[0]))
        csv_data[1][0] = 1.1
        File.write(@tmp_csv_path, csv_data.map(&:to_csv).join)
        hpxml.header.schedules_filepaths = [@tmp_csv_path]
      elsif ['battery-bad-values-min-not-neg-one'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-battery-scheduled.xml'))
        csv_data = CSV.read(File.join(File.dirname(hpxml.hpxml_path), hpxml.header.schedules_filepaths[0]))
        csv_data[1][0] = -1.1
        File.write(@tmp_csv_path, csv_data.map(&:to_csv).join)
        hpxml.header.schedules_filepaths = [@tmp_csv_path]
      elsif ['cfis-with-hydronic-distribution'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-hvac-boiler-gas-only.xml'))
        hpxml.ventilation_fans.add(id: "VentilationFan#{hpxml.ventilation_fans.size + 1}",
                                   fan_type: HPXML::MechVentTypeCFIS,
                                   used_for_whole_building_ventilation: true,
                                   distribution_system_idref: hpxml.hvac_distributions[0].id)
      elsif ['cfis-invalid-supplemental-fan'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-mechvent-cfis-supplemental-fan-exhaust.xml'))
        suppl_fan = hpxml.ventilation_fans.find { |f| f.is_cfis_supplemental_fan? }
        suppl_fan.fan_type = HPXML::MechVentTypeBalanced
      elsif ['cfis-invalid-supplemental-fan2'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-mechvent-cfis-supplemental-fan-exhaust.xml'))
        suppl_fan = hpxml.ventilation_fans.find { |f| f.is_cfis_supplemental_fan? }
        suppl_fan.used_for_whole_building_ventilation = false
        suppl_fan.used_for_garage_ventilation = true
      elsif ['cfis-invalid-supplemental-fan3'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-mechvent-cfis-supplemental-fan-exhaust.xml'))
        suppl_fan = hpxml.ventilation_fans.find { |f| f.is_cfis_supplemental_fan? }
        suppl_fan.is_shared_system = true
        suppl_fan.fraction_recirculation = 0.0
        suppl_fan.in_unit_flow_rate = suppl_fan.tested_flow_rate / 2.0
      elsif ['cfis-invalid-supplemental-fan4'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-mechvent-cfis-supplemental-fan-exhaust.xml'))
        suppl_fan = hpxml.ventilation_fans.find { |f| f.is_cfis_supplemental_fan? }
        suppl_fan.hours_in_operation = 12.0
      elsif ['dehumidifier-setpoints'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-appliances-dehumidifier-multiple.xml'))
        hpxml.dehumidifiers[-1].rh_setpoint = 0.55
      elsif ['desuperheater-with-detailed-setpoints'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-dhw-tank-detailed-setpoints.xml'))
        hpxml.water_heating_systems[0].uses_desuperheater = true
        hpxml.water_heating_systems[0].related_hvac_idref = hpxml.cooling_systems[0].id
      elsif ['duplicate-id'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.plug_loads[-1].id = hpxml.plug_loads[0].id
      elsif ['emissions-duplicate-names'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-misc-emissions.xml'))
        hpxml.header.emissions_scenarios << hpxml.header.emissions_scenarios[0].dup
      elsif ['emissions-wrong-columns'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-misc-emissions.xml'))
        scenario = hpxml.header.emissions_scenarios[1]
        csv_data = CSV.read(File.join(File.dirname(hpxml.hpxml_path), scenario.elec_schedule_filepath))
        csv_data[10] = [431.0] * (scenario.elec_schedule_column_number - 1)
        File.write(@tmp_csv_path, csv_data.map(&:to_csv).join)
        hpxml.header.emissions_scenarios[1].elec_schedule_filepath = @tmp_csv_path
      elsif ['emissions-wrong-filename'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-misc-emissions.xml'))
        hpxml.header.emissions_scenarios[1].elec_schedule_filepath = 'invalid-wrong-filename.csv'
      elsif ['emissions-wrong-rows'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-misc-emissions.xml'))
        scenario = hpxml.header.emissions_scenarios[1]
        csv_data = CSV.read(File.join(File.dirname(hpxml.hpxml_path), scenario.elec_schedule_filepath))
        File.write(@tmp_csv_path, csv_data[0..-2].map(&:to_csv).join)
        hpxml.header.emissions_scenarios[1].elec_schedule_filepath = @tmp_csv_path
      elsif ['heat-pump-backup-system-load-fraction'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-hvac-air-to-air-heat-pump-var-speed-backup-boiler.xml'))
        hpxml.heating_systems[0].fraction_heat_load_served = 0.5
        hpxml.heat_pumps[0].fraction_heat_load_served = 0.5
      elsif ['heat-pump-switchover-temp-elec-backup'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-hvac-air-to-air-heat-pump-1-speed.xml'))
        hpxml.heat_pumps[0].backup_heating_switchover_temp = 35.0
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
      elsif ['invalid-battery-capacity-units'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-pv-battery.xml'))
        hpxml.batteries[0].usable_capacity_kwh = nil
        hpxml.batteries[0].usable_capacity_ah = 200.0
      elsif ['invalid-battery-capacity-units2'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-pv-battery-ah.xml'))
        hpxml.batteries[0].usable_capacity_kwh = 10.0
        hpxml.batteries[0].usable_capacity_ah = nil
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
      elsif ['invalid-shading-season'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.header.shading_summer_begin_month = 3
        hpxml.header.shading_summer_begin_day = 10
        hpxml.header.shading_summer_end_month = 4
        hpxml.header.shading_summer_end_day = 31
      elsif ['invalid-unavailable-period'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.header.unavailable_periods.add(column_name: 'Power Outage',
                                             begin_month: 3,
                                             begin_day: 10,
                                             end_month: 4,
                                             end_day: 31)
      elsif ['invalid-schema-version'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
      elsif ['invalid-skylights-physical-properties'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-enclosure-skylights-physical-properties.xml'))
        hpxml.skylights[1].thermal_break = false
      elsif ['invalid-windows-physical-properties'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-enclosure-windows-physical-properties.xml'))
        hpxml.windows[2].thermal_break = false
      elsif ['inverter-unequal-efficiencies'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-pv.xml'))
        hpxml.inverters.add(id: 'Inverter2',
                            inverter_efficiency: 0.5)
        hpxml.pv_systems[1].inverter_idref = hpxml.inverters[-1].id
      elsif ['leap-year-TMY'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-simcontrol-calendar-year-custom.xml'))
        hpxml.header.sim_calendar_year = 2008
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
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-schedules-detailed-occupancy-stochastic.xml'))
        csv_data = CSV.read(File.join(File.dirname(hpxml.hpxml_path), hpxml.header.schedules_filepaths[0]))
        csv_data[1][1] = 1.1
        File.write(@tmp_csv_path, csv_data.map(&:to_csv).join)
        hpxml.header.schedules_filepaths = [@tmp_csv_path]
      elsif ['schedule-detailed-bad-values-negative'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-schedules-detailed-occupancy-stochastic.xml'))
        csv_data = CSV.read(File.join(File.dirname(hpxml.hpxml_path), hpxml.header.schedules_filepaths[0]))
        csv_data[1][1] = -0.5
        File.write(@tmp_csv_path, csv_data.map(&:to_csv).join)
        hpxml.header.schedules_filepaths = [@tmp_csv_path]
      elsif ['schedule-detailed-bad-values-non-numeric'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-schedules-detailed-occupancy-stochastic.xml'))
        csv_data = CSV.read(File.join(File.dirname(hpxml.hpxml_path), hpxml.header.schedules_filepaths[0]))
        csv_data[1][1] = 'NA'
        File.write(@tmp_csv_path, csv_data.map(&:to_csv).join)
        hpxml.header.schedules_filepaths = [@tmp_csv_path]
      elsif ['schedule-detailed-bad-values-mode-negative'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-dhw-tank-heat-pump-detailed-schedules.xml'))
        csv_data = CSV.read(File.join(File.dirname(hpxml.hpxml_path), hpxml.header.schedules_filepaths[1]))
        csv_data[1][0] = -0.5
        File.write(@tmp_csv_path, csv_data.map(&:to_csv).join)
        hpxml.header.schedules_filepaths = [@tmp_csv_path]
      elsif ['schedule-detailed-duplicate-columns'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-schedules-detailed-occupancy-stochastic.xml'))
        csv_data = CSV.read(File.join(File.dirname(hpxml.hpxml_path), hpxml.header.schedules_filepaths[0]))
        File.write(@tmp_csv_path, csv_data.map(&:to_csv).join)
        hpxml.header.schedules_filepaths = []
        hpxml.header.schedules_filepaths << @tmp_csv_path
        hpxml.header.schedules_filepaths << @tmp_csv_path
      elsif ['schedule-detailed-wrong-filename'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.header.schedules_filepaths << 'invalid-wrong-filename.csv'
      elsif ['schedule-detailed-wrong-rows'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-schedules-detailed-occupancy-stochastic.xml'))
        csv_data = CSV.read(File.join(File.dirname(hpxml.hpxml_path), hpxml.header.schedules_filepaths[0]))
        File.write(@tmp_csv_path, csv_data[0..-2].map(&:to_csv).join)
        hpxml.header.schedules_filepaths = [@tmp_csv_path]
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
      elsif ['storm-windows-unexpected-window-ufactor'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.windows[0].storm_type = 'clear'
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
      elsif ['unattached-pv-system'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-pv.xml'))
        hpxml.pv_systems[0].inverter_idref = 'foobar'
      elsif ['unattached-skylight'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-enclosure-skylights.xml'))
        hpxml.skylights[0].roof_idref = 'foobar'
      elsif ['unattached-solar-thermal-system'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-dhw-solar-indirect-flat-plate.xml'))
        hpxml.solar_thermal_systems[0].water_heating_system_idref = 'foobar'
      elsif ['unattached-shared-clothes-washer-dhw-distribution'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-bldgtype-multifamily-shared-laundry-room.xml'))
        hpxml.clothes_washers[0].water_heating_system_idref = nil
        hpxml.clothes_washers[0].hot_water_distribution_idref = 'foobar'
      elsif ['unattached-shared-clothes-washer-water-heater'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-bldgtype-multifamily-shared-laundry-room.xml'))
        hpxml.clothes_washers[0].water_heating_system_idref = 'foobar'
      elsif ['unattached-shared-dishwasher-dhw-distribution'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-bldgtype-multifamily-shared-laundry-room.xml'))
        hpxml.dishwashers[0].water_heating_system_idref = nil
        hpxml.dishwashers[0].hot_water_distribution_idref = 'foobar'
      elsif ['unattached-shared-dishwasher-water-heater'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-bldgtype-multifamily-shared-laundry-room.xml'))
        hpxml.dishwashers[0].water_heating_system_idref = 'foobar'
      elsif ['unattached-window'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.windows[0].wall_idref = 'foobar'
      elsif ['unavailable-period-missing-column'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-schedules-simple-vacancy.xml'))
        hpxml.header.unavailable_periods[0].column_name = 'foobar'
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
      _test_measure('error', expected_errors)
    end
  end

  def test_ruby_warning_messages
    # Test case => Error message
    all_expected_warnings = { 'cfis-undersized-supplemental-fan' => ["CFIS supplemental fan 'VentilationFan2' is undersized (90.0 cfm) compared to the target hourly ventilation rate (110.0 cfm)."],
                              'hvac-setpoint-adjustments' => ['HVAC setpoints have been automatically adjusted to prevent periods where the heating setpoint is greater than the cooling setpoint.'],
                              'hvac-setpoint-adjustments-daily-setbacks' => ['HVAC setpoints have been automatically adjusted to prevent periods where the heating setpoint is greater than the cooling setpoint.'],
                              'hvac-setpoint-adjustments-daily-schedules' => ['HVAC setpoints have been automatically adjusted to prevent periods where the heating setpoint is greater than the cooling setpoint.'],
                              'power-outage' => ['It is not possible to eliminate all HVAC energy use (e.g. crankcase/defrost energy) in EnergyPlus during an unavailable period.',
                                                 'It is not possible to eliminate all water heater energy use (e.g. parasitics) in EnergyPlus during an unavailable period.'],
                              'schedule-file-and-weekday-weekend-multipliers' => ["Both 'occupants' schedule file and weekday fractions provided; the latter will be ignored.",
                                                                                  "Both 'occupants' schedule file and weekend fractions provided; the latter will be ignored.",
                                                                                  "Both 'occupants' schedule file and monthly multipliers provided; the latter will be ignored.",
                                                                                  "Both 'clothes_washer' schedule file and weekday fractions provided; the latter will be ignored.",
                                                                                  "Both 'clothes_washer' schedule file and weekend fractions provided; the latter will be ignored.",
                                                                                  "Both 'clothes_washer' schedule file and monthly multipliers provided; the latter will be ignored.",
                                                                                  "Both 'clothes_dryer' schedule file and weekday fractions provided; the latter will be ignored.",
                                                                                  "Both 'clothes_dryer' schedule file and weekend fractions provided; the latter will be ignored.",
                                                                                  "Both 'clothes_dryer' schedule file and monthly multipliers provided; the latter will be ignored.",
                                                                                  "Both 'dishwasher' schedule file and weekday fractions provided; the latter will be ignored.",
                                                                                  "Both 'dishwasher' schedule file and weekend fractions provided; the latter will be ignored.",
                                                                                  "Both 'dishwasher' schedule file and monthly multipliers provided; the latter will be ignored.",
                                                                                  "Both 'refrigerator' schedule file and weekday fractions provided; the latter will be ignored.",
                                                                                  "Both 'refrigerator' schedule file and weekend fractions provided; the latter will be ignored.",
                                                                                  "Both 'refrigerator' schedule file and monthly multipliers provided; the latter will be ignored.",
                                                                                  "Both 'extra_refrigerator' schedule file and weekday fractions provided; the latter will be ignored.",
                                                                                  "Both 'extra_refrigerator' schedule file and weekend fractions provided; the latter will be ignored.",
                                                                                  "Both 'extra_refrigerator' schedule file and monthly multipliers provided; the latter will be ignored.",
                                                                                  "Both 'freezer' schedule file and weekday fractions provided; the latter will be ignored.",
                                                                                  "Both 'freezer' schedule file and weekend fractions provided; the latter will be ignored.",
                                                                                  "Both 'freezer' schedule file and monthly multipliers provided; the latter will be ignored.",
                                                                                  "Both 'cooking_range' schedule file and weekday fractions provided; the latter will be ignored.",
                                                                                  "Both 'cooking_range' schedule file and weekend fractions provided; the latter will be ignored.",
                                                                                  "Both 'cooking_range' schedule file and monthly multipliers provided; the latter will be ignored.",
                                                                                  "Both 'hot_water_fixtures' schedule file and weekday fractions provided; the latter will be ignored.",
                                                                                  "Both 'hot_water_fixtures' schedule file and weekend fractions provided; the latter will be ignored.",
                                                                                  "Both 'hot_water_fixtures' schedule file and monthly multipliers provided; the latter will be ignored.",
                                                                                  "Both 'plug_loads_tv' schedule file and weekday fractions provided; the latter will be ignored.",
                                                                                  "Both 'plug_loads_tv' schedule file and weekend fractions provided; the latter will be ignored.",
                                                                                  "Both 'plug_loads_tv' schedule file and monthly multipliers provided; the latter will be ignored.",
                                                                                  "Both 'plug_loads_other' schedule file and weekday fractions provided; the latter will be ignored.",
                                                                                  "Both 'plug_loads_other' schedule file and weekend fractions provided; the latter will be ignored.",
                                                                                  "Both 'plug_loads_other' schedule file and monthly multipliers provided; the latter will be ignored.",
                                                                                  "Both 'plug_loads_vehicle' schedule file and weekday fractions provided; the latter will be ignored.",
                                                                                  "Both 'plug_loads_vehicle' schedule file and weekend fractions provided; the latter will be ignored.",
                                                                                  "Both 'plug_loads_vehicle' schedule file and monthly multipliers provided; the latter will be ignored.",
                                                                                  "Both 'plug_loads_well_pump' schedule file and weekday fractions provided; the latter will be ignored.",
                                                                                  "Both 'plug_loads_well_pump' schedule file and weekend fractions provided; the latter will be ignored.",
                                                                                  "Both 'plug_loads_well_pump' schedule file and monthly multipliers provided; the latter will be ignored.",
                                                                                  "Both 'fuel_loads_grill' schedule file and weekday fractions provided; the latter will be ignored.",
                                                                                  "Both 'fuel_loads_grill' schedule file and weekend fractions provided; the latter will be ignored.",
                                                                                  "Both 'fuel_loads_grill' schedule file and monthly multipliers provided; the latter will be ignored.",
                                                                                  "Both 'fuel_loads_lighting' schedule file and weekday fractions provided; the latter will be ignored.",
                                                                                  "Both 'fuel_loads_lighting' schedule file and weekend fractions provided; the latter will be ignored.",
                                                                                  "Both 'fuel_loads_lighting' schedule file and monthly multipliers provided; the latter will be ignored.",
                                                                                  "Both 'fuel_loads_fireplace' schedule file and weekday fractions provided; the latter will be ignored.",
                                                                                  "Both 'fuel_loads_fireplace' schedule file and weekend fractions provided; the latter will be ignored.",
                                                                                  "Both 'fuel_loads_fireplace' schedule file and monthly multipliers provided; the latter will be ignored.",
                                                                                  "Both 'lighting_interior' schedule file and weekday fractions provided; the latter will be ignored.",
                                                                                  "Both 'lighting_interior' schedule file and weekend fractions provided; the latter will be ignored.",
                                                                                  "Both 'lighting_interior' schedule file and monthly multipliers provided; the latter will be ignored.",
                                                                                  "Both 'lighting_exterior' schedule file and weekday fractions provided; the latter will be ignored.",
                                                                                  "Both 'lighting_exterior' schedule file and weekend fractions provided; the latter will be ignored.",
                                                                                  "Both 'lighting_exterior' schedule file and monthly multipliers provided; the latter will be ignored.",
                                                                                  "Both 'pool_pump' schedule file and weekday fractions provided; the latter will be ignored.",
                                                                                  "Both 'pool_pump' schedule file and weekend fractions provided; the latter will be ignored.",
                                                                                  "Both 'pool_pump' schedule file and monthly multipliers provided; the latter will be ignored.",
                                                                                  "Both 'pool_heater' schedule file and weekday fractions provided; the latter will be ignored.",
                                                                                  "Both 'pool_heater' schedule file and weekend fractions provided; the latter will be ignored.",
                                                                                  "Both 'pool_heater' schedule file and monthly multipliers provided; the latter will be ignored.",
                                                                                  "Both 'hot_tub_pump' schedule file and weekday fractions provided; the latter will be ignored.",
                                                                                  "Both 'hot_tub_pump' schedule file and weekend fractions provided; the latter will be ignored.",
                                                                                  "Both 'hot_tub_pump' schedule file and monthly multipliers provided; the latter will be ignored.",
                                                                                  "Both 'hot_tub_heater' schedule file and weekday fractions provided; the latter will be ignored.",
                                                                                  "Both 'hot_tub_heater' schedule file and weekend fractions provided; the latter will be ignored.",
                                                                                  "Both 'hot_tub_heater' schedule file and monthly multipliers provided; the latter will be ignored."],
                              'schedule-file-and-setpoints' => ["Both 'heating_setpoint' schedule file and heating setpoint temperature provided; the latter will be ignored.",
                                                                "Both 'cooling_setpoint' schedule file and cooling setpoint temperature provided; the latter will be ignored.",
                                                                "Both 'water_heater_setpoint' schedule file and setpoint temperature provided; the latter will be ignored."],
                              'schedule-file-and-operating-mode' => ["Both 'water_heater_operating_mode' schedule file and operating mode provided; the latter will be ignored."] }

    all_expected_warnings.each_with_index do |(warning_case, expected_warnings), i|
      puts "[#{i + 1}/#{all_expected_warnings.size}] Testing #{warning_case}..."
      # Create HPXML object
      if ['cfis-undersized-supplemental-fan'].include? warning_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-mechvent-cfis-supplemental-fan-exhaust.xml'))
        suppl_fan = hpxml.ventilation_fans.find { |f| f.is_cfis_supplemental_fan? }
        suppl_fan.tested_flow_rate = 90.0
      elsif ['hvac-setpoint-adjustments'].include? warning_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.hvac_controls[0].heating_setpoint_temp = 76.0
        hpxml.hvac_controls[0].cooling_setpoint_temp = 75.0
      elsif ['hvac-setpoint-adjustments-daily-setbacks'].include? warning_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-hvac-setpoints-daily-setbacks.xml'))
        hpxml.hvac_controls[0].heating_setback_temp = 76.0
        hpxml.hvac_controls[0].cooling_setpoint_temp = 75.0
      elsif ['hvac-setpoint-adjustments-daily-schedules'].include? warning_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-hvac-setpoints-daily-schedules.xml'))
        hpxml.hvac_controls[0].weekday_heating_setpoints = '64, 64, 64, 64, 64, 64, 64, 76, 70, 66, 66, 66, 66, 66, 66, 66, 66, 68, 68, 68, 68, 68, 64, 64'
      elsif ['power-outage'].include? warning_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-schedules-simple-power-outage.xml'))
      elsif ['schedule-file-and-weekday-weekend-multipliers'].include? warning_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-misc-loads-large-uncommon.xml'))
        hpxml.header.utility_bill_scenarios.clear # we don't want the propane warning
        hpxml.header.schedules_filepaths << File.join(File.dirname(__FILE__), '../resources/schedule_files/occupancy-stochastic.csv')
        hpxml.header.schedules_filepaths << File.join(File.dirname(__FILE__), '../resources/schedule_files/occupancy-non-stochastic.csv')
      elsif ['schedule-file-and-setpoints'].include? warning_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.header.schedules_filepaths << File.join(File.dirname(__FILE__), '../resources/schedule_files/setpoints.csv')
        hpxml.header.schedules_filepaths << File.join(File.dirname(__FILE__), '../resources/schedule_files/water-heater-setpoints.csv')
      elsif ['schedule-file-and-operating-mode'].include? warning_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-dhw-tank-heat-pump-operating-mode-heat-pump-only.xml'))
        hpxml.header.schedules_filepaths << File.join(File.dirname(__FILE__), '../resources/schedule_files/water-heater-operating-modes.csv')
      else
        fail "Unhandled case: #{warning_case}."
      end

      hpxml_doc = hpxml.to_oga()

      XMLHelper.write_file(hpxml_doc, @tmp_hpxml_path)
      _test_measure('warning', expected_warnings)
    end
  end

  private

  def _test_schema_validation(hpxml_path, schematron_schema_validator)
    errors, _warnings = XMLValidator.validate_against_schema(hpxml_path, schematron_schema_validator)
    if errors.size > 0
      flunk "#{hpxml_path}: #{errors}"
    end
  end

  def _test_schema_and_schematron_validation(hpxml_path, hpxml_doc, expected_errors: nil, expected_warnings: nil)
    sct_errors, sct_warnings = XMLValidator.validate_against_schematron(hpxml_path, @schematron_validator, hpxml_doc)
    xsd_errors, xsd_warnings = XMLValidator.validate_against_schema(hpxml_path, @schema_validator)
    if not expected_errors.nil?
      _compare_errors_or_warnings('error', sct_errors + xsd_errors, expected_errors)
    end
    if not expected_warnings.nil?
      _compare_errors_or_warnings('warning', sct_warnings + xsd_warnings, expected_warnings)
    end
  end

  def _test_measure(error_or_warning, expected_errors_or_warnings)
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

    actual_errors_or_warnings = []
    if error_or_warning == 'error'
      assert_equal('Fail', result.value.valueName)

      result.stepErrors.each do |s|
        actual_errors_or_warnings << s
      end
    elsif error_or_warning == 'warning'
      # show the output
      show_output(result) unless result.value.valueName == 'Success'

      assert_equal('Success', result.value.valueName)

      result.stepWarnings.each do |s|
        actual_errors_or_warnings << s
      end
    end

    _compare_errors_or_warnings(error_or_warning, actual_errors_or_warnings, expected_errors_or_warnings)
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
