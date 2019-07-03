# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require 'csv'
if File.exists? File.absolute_path(File.join(File.dirname(__FILE__), "../../lib/resources/measures/HPXMLtoOpenStudio/resources")) # Hack to run ResStock on AWS
  resources_path = File.absolute_path(File.join(File.dirname(__FILE__), "../../lib/resources/measures/HPXMLtoOpenStudio/resources"))
elsif File.exists? File.absolute_path(File.join(File.dirname(__FILE__), "../../resources/measures/HPXMLtoOpenStudio/resources")) # Hack to run ResStock unit tests locally
  resources_path = File.absolute_path(File.join(File.dirname(__FILE__), "../../resources/measures/HPXMLtoOpenStudio/resources"))
elsif File.exists? File.join(OpenStudio::BCLMeasure::userMeasuresDir.to_s, "HPXMLtoOpenStudio/resources") # Hack to run measures in the OS App since applied measures are copied off into a temporary directory
  resources_path = File.join(OpenStudio::BCLMeasure::userMeasuresDir.to_s, "HPXMLtoOpenStudio/resources")
else
  resources_path = File.absolute_path(File.join(File.dirname(__FILE__), "../HPXMLtoOpenStudio/resources"))
end
require File.join(resources_path, "weather")
require File.join(resources_path, "unit_conversions")
require File.join(resources_path, "geometry")
require File.join(resources_path, "hvac")
require File.join(resources_path, "waterheater")

# start the measure
class TimeseriesCSVExport < OpenStudio::Measure::ReportingMeasure
  # human readable name
  def name
    return "Timeseries CSV Export"
  end

  # human readable description
  def description
    return "Exports timeseries output data to csv."
  end

  def reporting_frequency_map # idf => osm
    return { "Timestep" => "Zone Timestep", "Hourly" => "Hourly", "Daily" => "Daily", "Monthly" => "Monthly", "Runperiod" => "Run Period" }
  end

  # define the arguments that the user will input
  def arguments()
    args = OpenStudio::Measure::OSArgumentVector.new

    # make an argument for the frequency
    reporting_frequency_chs = OpenStudio::StringVector.new
    reporting_frequency_map.keys.each do |reporting_frequency_ch|
      reporting_frequency_chs << reporting_frequency_ch
    end
    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument("reporting_frequency", reporting_frequency_chs, true)
    arg.setDisplayName("Reporting Frequency")
    arg.setDescription("The frequency at which to report timeseries output data.")
    arg.setDefaultValue("Hourly")
    args << arg

    # make an argument for including optional end use subcategories
    arg = OpenStudio::Measure::OSArgument::makeBoolArgument("include_enduse_subcategories", true)
    arg.setDisplayName("Include End Use Subcategories")
    arg.setDescription("Whether to report end use subcategories: appliances, plug loads, fans, large uncommon loads.")
    arg.setDefaultValue(false)
    args << arg

    # make an argument for optional output variables
    arg = OpenStudio::Measure::OSArgument::makeStringArgument("output_variables", false)
    arg.setDisplayName("Output Variables")
    arg.setDescription("Specify a comma-separated list of output variables to report. (See EnergyPlus's rdd file for available output variables.)")
    args << arg

    return args
  end

  # return a vector of IdfObject's to request EnergyPlus objects needed by the run method
  def energyPlusOutputRequests(runner, user_arguments)
    super(runner, user_arguments)

    reporting_frequency = runner.getStringArgumentValue("reporting_frequency", user_arguments)
    include_enduse_subcategories = runner.getBoolArgumentValue("include_enduse_subcategories", user_arguments)
    output_variables = runner.getOptionalStringArgumentValue("output_variables", user_arguments)
    output_vars = []
    if output_variables.is_initialized
      output_vars = output_variables.get
      output_vars = output_vars.split(",")
      output_vars = output_vars.collect { |x| x.strip }
    end

    # get the last model and sql file
    model = runner.lastOpenStudioModel
    if model.empty?
      runner.registerError("Cannot find last model.")
      return false
    end
    model = model.get

    results = OutputMeters.create_custom_building_unit_meters(model, runner, reporting_frequency, include_enduse_subcategories)
    output_vars.each do |output_var|
      results << OpenStudio::IdfObject.load("Output:Variable,*,#{output_var},#{reporting_frequency};").get
    end
    results << OpenStudio::IdfObject.load("Output:Meter,Electricity:Facility,#{reporting_frequency};").get

    return results
  end

  # define what happens when the measure is run
  def run(runner, user_arguments)
    super(runner, user_arguments)

    # use the built-in error checking
    if not runner.validateUserArguments(arguments(), user_arguments)
      return false
    end

    # Assign the user inputs to variables
    reporting_frequency = runner.getStringArgumentValue("reporting_frequency", user_arguments)
    include_enduse_subcategories = runner.getBoolArgumentValue("include_enduse_subcategories", user_arguments)
    output_variables = runner.getOptionalStringArgumentValue("output_variables", user_arguments)
    output_vars = []
    if output_variables.is_initialized
      output_vars = output_variables.get
      output_vars = output_vars.split(",")
      output_vars = output_vars.collect { |x| x.strip }
    end

    # Get the last model and sql file
    model = runner.lastOpenStudioModel
    if model.empty?
      runner.registerError("Cannot find last model.")
      return false
    end
    model = model.get

    sqlFile = runner.lastEnergyPlusSqlFile
    if sqlFile.empty?
      runner.registerError("Cannot find last sql file.")
      return false
    end
    sqlFile = sqlFile.get
    model.setSqlFile(sqlFile)

    # Get datetimes
    ann_env_pd = nil
    sqlFile.availableEnvPeriods.each do |env_pd|
      env_type = sqlFile.environmentType(env_pd)
      if env_type.is_initialized
        if env_type.get == OpenStudio::EnvironmentType.new("WeatherRunPeriod")
          ann_env_pd = env_pd
        end
      end
    end
    if ann_env_pd == false
      runner.registerError("Can't find a weather runperiod, make sure you ran an annual simulation, not just the design days.")
      return false
    end

    env_period_ix_query = "SELECT EnvironmentPeriodIndex FROM EnvironmentPeriods WHERE EnvironmentName='#{ann_env_pd}'"
    env_period_ix = sqlFile.execAndReturnFirstInt(env_period_ix_query).get

    datetimes = []
    timeseries = sqlFile.timeSeries(ann_env_pd, reporting_frequency_map[reporting_frequency], "Electricity:Facility", "").get # assume every house consumes some electricity
    timeseries.dateTimes.each do |datetime|
      datetimes << format_datetime(datetime.to_s)
    end
    num_ts = datetimes.length

    total_site_units = "MBtu"
    elec_site_units = "kWh"
    gas_site_units = "therm"
    other_fuel_site_units = "MBtu"

    # Get meters that aren't tied to units (i.e., are metered at the building level)
    modeledCentralElectricityHeating = [0] * num_ts
    modeledCentralElectricityCooling = [0] * num_ts
    modeledCentralElectricityExteriorLighting = [0] * num_ts
    modeledCentralElectricityExteriorHolidayLighting = [0] * num_ts
    modeledCentralElectricityPumpsHeating = [0] * num_ts
    modeledCentralElectricityPumpsCooling = [0] * num_ts
    modeledCentralElectricityInteriorEquipment = [0] * num_ts
    modeledCentralElectricityPhotovoltaics = [0] * num_ts
    modeledCentralElectricityExtraRefrigerator = [0] * num_ts
    modeledCentralElectricityFreezer = [0] * num_ts
    modeledCentralElectricityGarageLighting = [0] * num_ts
    modeledCentralNaturalGasHeating = [0] * num_ts
    modeledCentralNaturalGasInteriorEquipment = [0] * num_ts
    modeledCentralNaturalGasGrill = [0] * num_ts
    modeledCentralNaturalGasLighting = [0] * num_ts
    modeledCentralNaturalGasFireplace = [0] * num_ts
    modeledCentralFuelOilHeating = [0] * num_ts
    modeledCentralPropaneHeating = [0] * num_ts

    central_electricity_heating_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('CENTRAL:ELECTRICITYHEATING') AND ReportingFrequency='#{reporting_frequency_map[reporting_frequency]}' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
    unless sqlFile.execAndReturnVectorOfDouble(central_electricity_heating_query).get.empty?
      modeledCentralElectricityHeating = sqlFile.execAndReturnVectorOfDouble(central_electricity_heating_query).get
    end

    central_electricity_cooling_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('CENTRAL:ELECTRICITYCOOLING') AND ReportingFrequency='#{reporting_frequency_map[reporting_frequency]}' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
    unless sqlFile.execAndReturnVectorOfDouble(central_electricity_cooling_query).get.empty?
      modeledCentralElectricityCooling = sqlFile.execAndReturnVectorOfDouble(central_electricity_cooling_query).get
    end

    central_electricity_exterior_lighting_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('CENTRAL:ELECTRICITYEXTERIORLIGHTING') AND ReportingFrequency='#{reporting_frequency_map[reporting_frequency]}' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
    unless sqlFile.execAndReturnVectorOfDouble(central_electricity_exterior_lighting_query).get.empty?
      modeledCentralElectricityExteriorLighting = sqlFile.execAndReturnVectorOfDouble(central_electricity_exterior_lighting_query).get
    end

    central_electricity_exterior_holiday_lighting_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('CENTRAL:ELECTRICITYEXTERIORHOLIDAYLIGHTING') AND ReportingFrequency='#{reporting_frequency_map[reporting_frequency]}' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
    unless sqlFile.execAndReturnVectorOfDouble(central_electricity_exterior_holiday_lighting_query).get.empty?
      modeledCentralElectricityExteriorHolidayLighting = sqlFile.execAndReturnVectorOfDouble(central_electricity_exterior_holiday_lighting_query).get
    end

    central_electricity_pumps_heating_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('CENTRAL:ELECTRICITYPUMPSHEATING') AND ReportingFrequency='#{reporting_frequency_map[reporting_frequency]}' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
    unless sqlFile.execAndReturnVectorOfDouble(central_electricity_pumps_heating_query).get.empty?
      modeledCentralElectricityPumpsHeating = sqlFile.execAndReturnVectorOfDouble(central_electricity_pumps_heating_query).get
    end

    central_electricity_pumps_cooling_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('CENTRAL:ELECTRICITYPUMPSCOOLING') AND ReportingFrequency='#{reporting_frequency_map[reporting_frequency]}' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
    unless sqlFile.execAndReturnVectorOfDouble(central_electricity_pumps_cooling_query).get.empty?
      modeledCentralElectricityPumpsCooling = sqlFile.execAndReturnVectorOfDouble(central_electricity_pumps_cooling_query).get
    end

    central_electricity_interior_equipment_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('CENTRAL:ELECTRICITYINTERIOREQUIPMENT') AND ReportingFrequency='#{reporting_frequency_map[reporting_frequency]}' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
    unless sqlFile.execAndReturnVectorOfDouble(central_electricity_interior_equipment_query).get.empty?
      modeledCentralElectricityInteriorEquipment = sqlFile.execAndReturnVectorOfDouble(central_electricity_interior_equipment_query).get
    end

    central_electricity_photovoltaics_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('CENTRAL:ELECTRICITYPHOTOVOLTAICS') AND ReportingFrequency='#{reporting_frequency_map[reporting_frequency]}' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
    unless sqlFile.execAndReturnVectorOfDouble(central_electricity_photovoltaics_query).get.empty?
      modeledCentralElectricityPhotovoltaics = sqlFile.execAndReturnVectorOfDouble(central_electricity_photovoltaics_query).get
    end

    central_electricity_extra_refrigerator_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('CENTRAL:ELECTRICITYEXTRAREFRIGERATOR') AND ReportingFrequency='#{reporting_frequency_map[reporting_frequency]}' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
    unless sqlFile.execAndReturnVectorOfDouble(central_electricity_extra_refrigerator_query).get.empty?
      modeledCentralElectricityExtraRefrigerator = sqlFile.execAndReturnVectorOfDouble(central_electricity_extra_refrigerator_query).get
    end

    central_electricity_freezer_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('CENTRAL:ELECTRICITYFREEZER') AND ReportingFrequency='#{reporting_frequency_map[reporting_frequency]}' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
    unless sqlFile.execAndReturnVectorOfDouble(central_electricity_freezer_query).get.empty?
      modeledCentralElectricityFreezer = sqlFile.execAndReturnVectorOfDouble(central_electricity_freezer_query).get
    end

    central_electricity_garage_lighting_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('CENTRAL:ELECTRICITYGARAGELIGHTING') AND ReportingFrequency='#{reporting_frequency_map[reporting_frequency]}' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
    unless sqlFile.execAndReturnVectorOfDouble(central_electricity_garage_lighting_query).get.empty?
      modeledCentralElectricityGarageLighting = sqlFile.execAndReturnVectorOfDouble(central_electricity_garage_lighting_query).get
    end

    central_natural_gas_heating_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('CENTRAL:NATURALGASHEATING') AND ReportingFrequency='#{reporting_frequency_map[reporting_frequency]}' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
    unless sqlFile.execAndReturnVectorOfDouble(central_natural_gas_heating_query).get.empty?
      modeledCentralNaturalGasHeating = sqlFile.execAndReturnVectorOfDouble(central_natural_gas_heating_query).get
    end

    central_natural_gas_interior_equipment_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('CENTRAL:NATURALGASINTERIOREQUIPMENT') AND ReportingFrequency='#{reporting_frequency_map[reporting_frequency]}' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
    unless sqlFile.execAndReturnVectorOfDouble(central_natural_gas_interior_equipment_query).get.empty?
      modeledCentralNaturalGasInteriorEquipment = sqlFile.execAndReturnVectorOfDouble(central_natural_gas_interior_equipment_query).get
    end

    central_natural_gas_grill_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('CENTRAL:NATURALGASGRILL') AND ReportingFrequency='#{reporting_frequency_map[reporting_frequency]}' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
    unless sqlFile.execAndReturnVectorOfDouble(central_natural_gas_grill_query).get.empty?
      modeledCentralNaturalGasGrill = sqlFile.execAndReturnVectorOfDouble(central_natural_gas_grill_query).get
    end

    central_natural_gas_lighting_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('CENTRAL:NATURALGASLIGHTING') AND ReportingFrequency='#{reporting_frequency_map[reporting_frequency]}' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
    unless sqlFile.execAndReturnVectorOfDouble(central_natural_gas_lighting_query).get.empty?
      modeledCentralNaturalGasLighting = sqlFile.execAndReturnVectorOfDouble(central_natural_gas_lighting_query).get
    end

    central_natural_gas_fireplace_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('CENTRAL:NATURALGASFIREPLACE') AND ReportingFrequency='#{reporting_frequency_map[reporting_frequency]}' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
    unless sqlFile.execAndReturnVectorOfDouble(central_natural_gas_fireplace_query).get.empty?
      modeledCentralNaturalGasFireplace = sqlFile.execAndReturnVectorOfDouble(central_natural_gas_fireplace_query).get
    end

    central_fuel_oil_heating_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('CENTRAL:FUELOILHEATING') AND ReportingFrequency='#{reporting_frequency_map[reporting_frequency]}' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
    unless sqlFile.execAndReturnVectorOfDouble(central_fuel_oil_heating_query).get.empty?
      modeledCentralFuelOilHeating = sqlFile.execAndReturnVectorOfDouble(central_fuel_oil_heating_query).get
    end

    central_propane_heating_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('CENTRAL:PROPANEHEATING') AND ReportingFrequency='#{reporting_frequency_map[reporting_frequency]}' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
    unless sqlFile.execAndReturnVectorOfDouble(central_propane_heating_query).get.empty?
      modeledCentralPropaneHeating = sqlFile.execAndReturnVectorOfDouble(central_propane_heating_query).get
    end

    # Separate these from non central systems
    centralElectricityHeating = [0] * num_ts
    centralElectricityCooling = [0] * num_ts
    centralElectricityPumpsHeating = [0] * num_ts
    centralElectricityPumpsCooling = [0] * num_ts
    centralNaturalGasHeating = [0] * num_ts
    centralFuelOilHeating = [0] * num_ts
    centralPropaneHeating = [0] * num_ts

    # Get meters that are tied to units, and apportion building level meters to these
    electricityTotalEndUses = [0] * num_ts
    electricityHeating = [0] * num_ts
    electricityCooling = [0] * num_ts
    electricityInteriorLighting = [0] * num_ts
    electricityExteriorLighting = [0] * num_ts
    electricityExteriorHolidayLighting = modeledCentralElectricityExteriorHolidayLighting
    electricityInteriorEquipment = [0] * num_ts
    electricityFansHeating = [0] * num_ts
    electricityFansCooling = [0] * num_ts
    electricityPumpsHeating = [0] * num_ts
    electricityPumpsCooling = [0] * num_ts
    electricityWaterSystems = [0] * num_ts
    electricityPhotovoltaics = [0] * num_ts
    naturalGasTotalEndUses = [0] * num_ts
    naturalGasHeating = [0] * num_ts
    naturalGasInteriorEquipment = [0] * num_ts
    naturalGasWaterSystems = [0] * num_ts
    fuelOilTotalEndUses = [0] * num_ts
    fuelOilHeating = [0] * num_ts
    fuelOilInteriorEquipment = [0] * num_ts
    fuelOilWaterSystems = [0] * num_ts
    propaneTotalEndUses = [0] * num_ts
    propaneHeating = [0] * num_ts
    propaneInteriorEquipment = [0] * num_ts
    propaneWaterSystems = [0] * num_ts
    electricityRefrigerator = [0] * num_ts
    electricityClothesWasher = [0] * num_ts
    electricityClothesDryer = [0] * num_ts
    naturalGasClothesDryer = [0] * num_ts
    propaneClothesDryer = [0] * num_ts
    electricityCookingRange = [0] * num_ts
    naturalGasCookingRange = [0] * num_ts
    propaneCookingRange = [0] * num_ts
    electricityDishwasher = [0] * num_ts
    electricityPlugLoads = [0] * num_ts
    electricityHouseFan = [0] * num_ts
    electricityRangeFan = [0] * num_ts
    electricityBathFan = [0] * num_ts
    electricityCeilingFan = [0] * num_ts
    electricityExtraRefrigerator = [0] * num_ts
    electricityFreezer = [0] * num_ts
    electricityPoolHeater = [0] * num_ts
    naturalGasPoolHeater = [0] * num_ts
    electricityPoolPump = [0] * num_ts
    electricityHotTubHeater = [0] * num_ts
    naturalGasHotTubHeater = [0] * num_ts
    electricityHotTubPump = [0] * num_ts
    electricityWellPump = [0] * num_ts
    electricityGarageLighting = [0] * num_ts
    naturalGasGrill = [0] * num_ts
    naturalGasLighting = [0] * num_ts
    naturalGasFireplace = [0] * num_ts

    # Get building units
    units = Geometry.get_building_units(model, runner)
    if units.nil?
      return false
    end

    units.each do |unit|
      unit_name = unit.name.to_s.upcase

      units_represented = 1
      if unit.additionalProperties.getFeatureAsInteger("Units Represented").is_initialized
        units_represented = unit.additionalProperties.getFeatureAsInteger("Units Represented").get
      end

      electricity_heating_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:ELECTRICITYHEATING') AND ReportingFrequency='#{reporting_frequency_map[reporting_frequency]}' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
      unless sqlFile.execAndReturnVectorOfDouble(electricity_heating_query).get.empty?
        electricityHeating = array_sum(electricityHeating, sqlFile.execAndReturnVectorOfDouble(electricity_heating_query).get, units_represented)
      end

      centralElectricityHeating = array_sum(centralElectricityHeating, modeledCentralElectricityHeating, units_represented, units.length)

      electricity_cooling_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:ELECTRICITYCOOLING') AND ReportingFrequency='#{reporting_frequency_map[reporting_frequency]}' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
      unless sqlFile.execAndReturnVectorOfDouble(electricity_cooling_query).get.empty?
        electricityCooling = array_sum(electricityCooling, sqlFile.execAndReturnVectorOfDouble(electricity_cooling_query).get, units_represented)
      end

      centralElectricityCooling = array_sum(centralElectricityCooling, modeledCentralElectricityCooling, units_represented, units.length)

      electricity_interior_lighting_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:ELECTRICITYINTERIORLIGHTING') AND ReportingFrequency='#{reporting_frequency_map[reporting_frequency]}' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
      unless sqlFile.execAndReturnVectorOfDouble(electricity_interior_lighting_query).get.empty?
        electricityInteriorLighting = array_sum(electricityInteriorLighting, sqlFile.execAndReturnVectorOfDouble(electricity_interior_lighting_query).get, units_represented)
      end

      electricityExteriorLighting = array_sum(electricityExteriorLighting, modeledCentralElectricityExteriorLighting, units_represented, units.length)

      electricity_interior_equipment_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:ELECTRICITYINTERIOREQUIPMENT') AND ReportingFrequency='#{reporting_frequency_map[reporting_frequency]}' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
      unless sqlFile.execAndReturnVectorOfDouble(electricity_interior_equipment_query).get.empty?
        electricityInteriorEquipment = array_sum(electricityInteriorEquipment, sqlFile.execAndReturnVectorOfDouble(electricity_interior_equipment_query).get, units_represented)
      end
      electricityInteriorEquipment = array_sum(electricityInteriorEquipment, modeledCentralElectricityInteriorEquipment, units_represented, units.length)

      electricity_fans_heating_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:ELECTRICITYFANSHEATING') AND ReportingFrequency='#{reporting_frequency_map[reporting_frequency]}' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
      unless sqlFile.execAndReturnVectorOfDouble(electricity_fans_heating_query).get.empty?
        electricityFansHeating = array_sum(electricityFansHeating, sqlFile.execAndReturnVectorOfDouble(electricity_fans_heating_query).get, units_represented)
      end

      electricity_fans_cooling_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:ELECTRICITYFANSCOOLING') AND ReportingFrequency='#{reporting_frequency_map[reporting_frequency]}' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
      unless sqlFile.execAndReturnVectorOfDouble(electricity_fans_cooling_query).get.empty?
        electricityFansCooling = array_sum(electricityFansCooling, sqlFile.execAndReturnVectorOfDouble(electricity_fans_cooling_query).get, units_represented)
      end

      electricity_pumps_heating_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:ELECTRICITYPUMPSHEATING') AND ReportingFrequency='#{reporting_frequency_map[reporting_frequency]}' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
      unless sqlFile.execAndReturnVectorOfDouble(electricity_pumps_heating_query).get.empty?
        electricityPumpsHeating = array_sum(electricityPumpsHeating, sqlFile.execAndReturnVectorOfDouble(electricity_pumps_heating_query).get, units_represented)
      end

      centralElectricityPumpsHeating = array_sum(centralElectricityPumpsHeating, modeledCentralElectricityPumpsHeating, units_represented, units.length)

      electricity_pumps_cooling_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:ELECTRICITYPUMPSCOOLING') AND ReportingFrequency='#{reporting_frequency_map[reporting_frequency]}' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
      unless sqlFile.execAndReturnVectorOfDouble(electricity_pumps_cooling_query).get.empty?
        electricityPumpsCooling = array_sum(electricityPumpsCooling, sqlFile.execAndReturnVectorOfDouble(electricity_pumps_cooling_query).get, units_represented)
      end

      centralElectricityPumpsCooling = array_sum(centralElectricityPumpsCooling, modeledCentralElectricityPumpsCooling, units_represented, units.length)

      electricity_water_systems_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:ELECTRICITYWATERSYSTEMS') AND ReportingFrequency='#{reporting_frequency_map[reporting_frequency]}' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
      unless sqlFile.execAndReturnVectorOfDouble(electricity_water_systems_query).get.empty?
        electricityWaterSystems = array_sum(electricityWaterSystems, sqlFile.execAndReturnVectorOfDouble(electricity_water_systems_query).get, units_represented)
      end

      natural_gas_heating_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:NATURALGASHEATING') AND ReportingFrequency='#{reporting_frequency_map[reporting_frequency]}' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
      unless sqlFile.execAndReturnVectorOfDouble(natural_gas_heating_query).get.empty?
        naturalGasHeating = array_sum(naturalGasHeating, sqlFile.execAndReturnVectorOfDouble(natural_gas_heating_query).get, units_represented)
      end

      centralNaturalGasHeating = array_sum(centralNaturalGasHeating, modeledCentralNaturalGasHeating, units_represented, units.length)

      natural_gas_interior_equipment_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:NATURALGASINTERIOREQUIPMENT') AND ReportingFrequency='#{reporting_frequency_map[reporting_frequency]}' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
      unless sqlFile.execAndReturnVectorOfDouble(natural_gas_interior_equipment_query).get.empty?
        naturalGasInteriorEquipment = array_sum(naturalGasInteriorEquipment, sqlFile.execAndReturnVectorOfDouble(natural_gas_interior_equipment_query).get, units_represented)
      end
      naturalGasInteriorEquipment = array_sum(naturalGasInteriorEquipment, modeledCentralNaturalGasInteriorEquipment, units_represented, units.length)

      natural_gas_water_systems_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:NATURALGASWATERSYSTEMS') AND ReportingFrequency='#{reporting_frequency_map[reporting_frequency]}' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
      unless sqlFile.execAndReturnVectorOfDouble(natural_gas_water_systems_query).get.empty?
        naturalGasWaterSystems = array_sum(naturalGasWaterSystems, sqlFile.execAndReturnVectorOfDouble(natural_gas_water_systems_query).get, units_represented)
      end

      fuel_oil_heating_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:FUELOILHEATING') AND ReportingFrequency='#{reporting_frequency_map[reporting_frequency]}' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
      unless sqlFile.execAndReturnVectorOfDouble(fuel_oil_heating_query).get.empty?
        fuelOilHeating = array_sum(fuelOilHeating, sqlFile.execAndReturnVectorOfDouble(fuel_oil_heating_query).get, units_represented)
      end

      centralFuelOilHeating = array_sum(centralFuelOilHeating, modeledCentralFuelOilHeating, units_represented, units.length)

      fuel_oil_interior_equipment_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:FUELOILINTERIOREQUIPMENT') AND ReportingFrequency='#{reporting_frequency_map[reporting_frequency]}' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
      unless sqlFile.execAndReturnVectorOfDouble(fuel_oil_interior_equipment_query).get.empty?
        fuelOilInteriorEquipment = array_sum(fuelOilInteriorEquipment, sqlFile.execAndReturnVectorOfDouble(fuel_oil_interior_equipment_query).get, units_represented)
      end

      fuel_oil_water_systems_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:FUELOILWATERSYSTEMS') AND ReportingFrequency='#{reporting_frequency_map[reporting_frequency]}' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
      unless sqlFile.execAndReturnVectorOfDouble(fuel_oil_water_systems_query).get.empty?
        fuelOilWaterSystems = array_sum(fuelOilWaterSystems, sqlFile.execAndReturnVectorOfDouble(fuel_oil_water_systems_query).get, units_represented)
      end

      propane_heating_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:PROPANEHEATING') AND ReportingFrequency='#{reporting_frequency_map[reporting_frequency]}' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
      unless sqlFile.execAndReturnVectorOfDouble(propane_heating_query).get.empty?
        propaneHeating = array_sum(propaneHeating, sqlFile.execAndReturnVectorOfDouble(propane_heating_query).get, units_represented)
      end

      centralPropaneHeating = array_sum(centralPropaneHeating, modeledCentralPropaneHeating, units_represented, units.length)

      propane_interior_equipment_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:PROPANEINTERIOREQUIPMENT') AND ReportingFrequency='#{reporting_frequency_map[reporting_frequency]}' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
      unless sqlFile.execAndReturnVectorOfDouble(propane_interior_equipment_query).get.empty?
        propaneInteriorEquipment = array_sum(propaneInteriorEquipment, sqlFile.execAndReturnVectorOfDouble(propane_interior_equipment_query).get, units_represented)
      end

      propane_water_systems_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:PROPANEWATERSYSTEMS') AND ReportingFrequency='#{reporting_frequency_map[reporting_frequency]}' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
      unless sqlFile.execAndReturnVectorOfDouble(propane_water_systems_query).get.empty?
        propaneWaterSystems = array_sum(propaneWaterSystems, sqlFile.execAndReturnVectorOfDouble(propane_water_systems_query).get, units_represented)
      end

      if include_enduse_subcategories
        electricity_refrgerator_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:ELECTRICITYREFRIGERATOR') AND ReportingFrequency='#{reporting_frequency_map[reporting_frequency]}' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
        unless sqlFile.execAndReturnVectorOfDouble(electricity_refrgerator_query).get.empty?
          electricityRefrigerator = array_sum(electricityRefrigerator, sqlFile.execAndReturnVectorOfDouble(electricity_refrgerator_query).get, units_represented)
        end

        electricity_clothes_washer_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:ELECTRICITYCLOTHESWASHER') AND ReportingFrequency='#{reporting_frequency_map[reporting_frequency]}' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
        unless sqlFile.execAndReturnVectorOfDouble(electricity_clothes_washer_query).get.empty?
          electricityClothesWasher = array_sum(electricityClothesWasher, sqlFile.execAndReturnVectorOfDouble(electricity_clothes_washer_query).get, units_represented)
        end

        electricity_clothes_dryer_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:ELECTRICITYCLOTHESDRYER') AND ReportingFrequency='#{reporting_frequency_map[reporting_frequency]}' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
        unless sqlFile.execAndReturnVectorOfDouble(electricity_clothes_dryer_query).get.empty?
          electricityClothesDryer = array_sum(electricityClothesDryer, sqlFile.execAndReturnVectorOfDouble(electricity_clothes_dryer_query).get, units_represented)
        end

        natural_gas_clothes_dryer_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:NATURALGASCLOTHESDRYER') AND ReportingFrequency='#{reporting_frequency_map[reporting_frequency]}' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
        unless sqlFile.execAndReturnVectorOfDouble(natural_gas_clothes_dryer_query).get.empty?
          naturalGasClothesDryer = array_sum(naturalGasClothesDryer, sqlFile.execAndReturnVectorOfDouble(natural_gas_clothes_dryer_query).get, units_represented)
        end

        propane_clothes_dryer_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:PROPANECLOTHESDRYER') AND ReportingFrequency='#{reporting_frequency_map[reporting_frequency]}' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
        unless sqlFile.execAndReturnVectorOfDouble(propane_clothes_dryer_query).get.empty?
          propaneClothesDryer = array_sum(propaneClothesDryer, sqlFile.execAndReturnVectorOfDouble(propane_clothes_dryer_query).get, units_represented)
        end

        electricity_cooking_range_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:ELECTRICITYCOOKINGRANGE') AND ReportingFrequency='#{reporting_frequency_map[reporting_frequency]}' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
        unless sqlFile.execAndReturnVectorOfDouble(electricity_cooking_range_query).get.empty?
          electricityCookingRange = array_sum(electricityCookingRange, sqlFile.execAndReturnVectorOfDouble(electricity_cooking_range_query).get, units_represented)
        end

        natural_gas_cooking_range_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:NATURALGASCOOKINGRANGE') AND ReportingFrequency='#{reporting_frequency_map[reporting_frequency]}' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
        unless sqlFile.execAndReturnVectorOfDouble(natural_gas_cooking_range_query).get.empty?
          naturalGasCookingRange = array_sum(naturalGasCookingRange, sqlFile.execAndReturnVectorOfDouble(natural_gas_cooking_range_query).get, units_represented)
        end

        propane_cooking_range_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:PROPANECOOKINGRANGE') AND ReportingFrequency='#{reporting_frequency_map[reporting_frequency]}' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
        unless sqlFile.execAndReturnVectorOfDouble(propane_cooking_range_query).get.empty?
          propaneCookingRange = array_sum(propaneCookingRange, sqlFile.execAndReturnVectorOfDouble(propane_cooking_range_query).get, units_represented)
        end

        electricity_dishwasher_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:ELECTRICITYDISHWASHER') AND ReportingFrequency='#{reporting_frequency_map[reporting_frequency]}' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
        unless sqlFile.execAndReturnVectorOfDouble(electricity_dishwasher_query).get.empty?
          electricityDishwasher = array_sum(electricityDishwasher, sqlFile.execAndReturnVectorOfDouble(electricity_dishwasher_query).get, units_represented)
        end

        electricity_plug_loads_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:ELECTRICITYPLUGLOADS') AND ReportingFrequency='#{reporting_frequency_map[reporting_frequency]}' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
        unless sqlFile.execAndReturnVectorOfDouble(electricity_plug_loads_query).get.empty?
          electricityPlugLoads = array_sum(electricityPlugLoads, sqlFile.execAndReturnVectorOfDouble(electricity_plug_loads_query).get, units_represented)
        end

        electricity_house_fan_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:ELECTRICITYHOUSEFAN') AND ReportingFrequency='#{reporting_frequency_map[reporting_frequency]}' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
        unless sqlFile.execAndReturnVectorOfDouble(electricity_house_fan_query).get.empty?
          electricityHouseFan = array_sum(electricityHouseFan, sqlFile.execAndReturnVectorOfDouble(electricity_house_fan_query).get, units_represented)
        end

        electricity_range_fan_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:ELECTRICITYRANGEFAN') AND ReportingFrequency='#{reporting_frequency_map[reporting_frequency]}' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
        unless sqlFile.execAndReturnVectorOfDouble(electricity_range_fan_query).get.empty?
          electricityRangeFan = array_sum(electricityRangeFan, sqlFile.execAndReturnVectorOfDouble(electricity_range_fan_query).get, units_represented)
        end

        electricity_bath_fan_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:ELECTRICITYBATHFAN') AND ReportingFrequency='#{reporting_frequency_map[reporting_frequency]}' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
        unless sqlFile.execAndReturnVectorOfDouble(electricity_bath_fan_query).get.empty?
          electricityBathFan = array_sum(electricityBathFan, sqlFile.execAndReturnVectorOfDouble(electricity_bath_fan_query).get, units_represented)
        end

        electricity_ceiling_fan_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:ELECTRICITYCEILINGFAN') AND ReportingFrequency='#{reporting_frequency_map[reporting_frequency]}' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
        unless sqlFile.execAndReturnVectorOfDouble(electricity_ceiling_fan_query).get.empty?
          electricityCeilingFan = array_sum(electricityCeilingFan, sqlFile.execAndReturnVectorOfDouble(electricity_ceiling_fan_query).get, units_represented)
        end

        electricity_extra_refrigerator_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:ELECTRICITYEXTRAREFRIGERATOR') AND ReportingFrequency='#{reporting_frequency_map[reporting_frequency]}' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
        unless sqlFile.execAndReturnVectorOfDouble(electricity_extra_refrigerator_query).get.empty?
          electricityExtraRefrigerator = array_sum(electricityExtraRefrigerator, sqlFile.execAndReturnVectorOfDouble(electricity_extra_refrigerator_query).get, units_represented)
        end
        electricityExtraRefrigerator = array_sum(electricityExtraRefrigerator, modeledCentralElectricityExtraRefrigerator, units_represented, units.length)

        electricity_freezer_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:ELECTRICITYFREEZER') AND ReportingFrequency='#{reporting_frequency_map[reporting_frequency]}' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
        unless sqlFile.execAndReturnVectorOfDouble(electricity_freezer_query).get.empty?
          electricityFreezer = array_sum(electricityFreezer, sqlFile.execAndReturnVectorOfDouble(electricity_freezer_query).get, units_represented)
        end
        electricityFreezer = array_sum(electricityFreezer, modeledCentralElectricityFreezer, units_represented, units.length)

        electricity_pool_heater_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:ELECTRICITYPOOLHEATER') AND ReportingFrequency='#{reporting_frequency_map[reporting_frequency]}' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
        unless sqlFile.execAndReturnVectorOfDouble(electricity_pool_heater_query).get.empty?
          electricityPoolHeater = array_sum(electricityPoolHeater, sqlFile.execAndReturnVectorOfDouble(electricity_pool_heater_query).get, units_represented)
        end

        electricity_pool_pump_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:ELECTRICITYPOOLPUMP') AND ReportingFrequency='#{reporting_frequency_map[reporting_frequency]}' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
        unless sqlFile.execAndReturnVectorOfDouble(electricity_pool_pump_query).get.empty?
          electricityPoolPump = array_sum(electricityPoolPump, sqlFile.execAndReturnVectorOfDouble(electricity_pool_pump_query).get, units_represented)
        end

        electricity_hot_tub_heater_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:ELECTRICITYHOTTUBHEATER') AND ReportingFrequency='#{reporting_frequency_map[reporting_frequency]}' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
        unless sqlFile.execAndReturnVectorOfDouble(electricity_hot_tub_heater_query).get.empty?
          electricityHotTubHeater = array_sum(electricityHotTubHeater, sqlFile.execAndReturnVectorOfDouble(electricity_hot_tub_heater_query).get, units_represented)
        end

        electricity_hot_tub_pump_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:ELECTRICITYHOTTUBPUMP') AND ReportingFrequency='#{reporting_frequency_map[reporting_frequency]}' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
        unless sqlFile.execAndReturnVectorOfDouble(electricity_hot_tub_pump_query).get.empty?
          electricityHotTubPump = array_sum(electricityHotTubPump, sqlFile.execAndReturnVectorOfDouble(electricity_hot_tub_pump_query).get, units_represented)
        end

        electricity_well_pump_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:ELECTRICITYWELLPUMP') AND ReportingFrequency='#{reporting_frequency_map[reporting_frequency]}' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
        unless sqlFile.execAndReturnVectorOfDouble(electricity_well_pump_query).get.empty?
          electricityWellPump = array_sum(electricityWellPump, sqlFile.execAndReturnVectorOfDouble(electricity_well_pump_query).get, units_represented)
        end

        electricityGarageLighting = array_sum(electricityGarageLighting, modeledCentralElectricityGarageLighting, units_represented, units.length)

        natural_gas_pool_heater_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:NATURALGASPOOLHEATER') AND ReportingFrequency='#{reporting_frequency_map[reporting_frequency]}' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
        unless sqlFile.execAndReturnVectorOfDouble(natural_gas_pool_heater_query).get.empty?
          naturalGasPoolHeater = array_sum(naturalGasPoolHeater, sqlFile.execAndReturnVectorOfDouble(natural_gas_pool_heater_query).get, units_represented)
        end

        natural_gas_hot_tub_heater_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:NATURALGASHOTTUBHEATER') AND ReportingFrequency='#{reporting_frequency_map[reporting_frequency]}' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
        unless sqlFile.execAndReturnVectorOfDouble(natural_gas_hot_tub_heater_query).get.empty?
          naturalGasHotTubHeater = array_sum(naturalGasHotTubHeater, sqlFile.execAndReturnVectorOfDouble(natural_gas_hot_tub_heater_query).get, units_represented)
        end

        natural_gas_grill_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:NATURALGASGRILL') AND ReportingFrequency='#{reporting_frequency_map[reporting_frequency]}' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
        unless sqlFile.execAndReturnVectorOfDouble(natural_gas_grill_query).get.empty?
          naturalGasGrill = array_sum(naturalGasGrill, sqlFile.execAndReturnVectorOfDouble(natural_gas_grill_query).get, units_represented)
        end
        naturalGasGrill = array_sum(naturalGasGrill, modeledCentralNaturalGasGrill, units_represented, units.length)

        natural_gas_lighting_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:NATURALGASLIGHTING') AND ReportingFrequency='#{reporting_frequency_map[reporting_frequency]}' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
        unless sqlFile.execAndReturnVectorOfDouble(natural_gas_lighting_query).get.empty?
          naturalGasLighting = array_sum(naturalGasLighting, sqlFile.execAndReturnVectorOfDouble(natural_gas_lighting_query).get, units_represented)
        end
        naturalGasLighting = array_sum(naturalGasLighting, modeledCentralNaturalGasLighting, units_represented, units.length)

        natural_gas_fireplace_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:NATURALGASFIREPLACE') AND ReportingFrequency='#{reporting_frequency_map[reporting_frequency]}' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
        unless sqlFile.execAndReturnVectorOfDouble(natural_gas_fireplace_query).get.empty?
          naturalGasFireplace = array_sum(naturalGasFireplace, sqlFile.execAndReturnVectorOfDouble(natural_gas_fireplace_query).get, units_represented)
        end
        naturalGasFireplace = array_sum(naturalGasFireplace, modeledCentralNaturalGasFireplace, units_represented, units.length)
      end
    end

    # Get the timestamps for actual year epw file, and the number of intervals per hour
    weather = WeatherProcess.new(model, runner)
    if weather.error?
      return false
    end

    actual_year_timestamps = weather.actual_year_timestamps(reporting_frequency)

    # Initialize timeseries hash which will be exported to csv
    timeseries = {}
    timeseries["Time"] = datetimes # timestamps from the sqlfile (TMY)
    unless actual_year_timestamps.empty?
      timeseries["Time"] = actual_year_timestamps # timestamps constructed using run period and Time class (AMY)
    end
    if timeseries["Time"].length != num_ts
      runner.registerError("The timestamps array length does not equal that of the sqlfile timeseries. You may be ignoring leap days in your AMY weather file.")
      return false
    end

    # ELECTRICITY

    electricityTotalEndUses = [electricityHeating, centralElectricityHeating, electricityCooling, centralElectricityCooling, electricityInteriorLighting, electricityExteriorLighting, electricityExteriorHolidayLighting, electricityInteriorEquipment, electricityFansHeating, electricityFansCooling, electricityPumpsHeating, centralElectricityPumpsHeating, electricityPumpsCooling, centralElectricityPumpsCooling, electricityWaterSystems].transpose.map { |e| e.reduce(:+) }

    report_ts_output(runner, timeseries, "total_site_electricity_kwh", electricityTotalEndUses, "GJ", elec_site_units)
    report_ts_output(runner, timeseries, "net_site_electricity_kwh", [electricityTotalEndUses, modeledCentralElectricityPhotovoltaics].transpose.collect { |e1, e2| e1 - e2 }, "GJ", elec_site_units)
    report_ts_output(runner, timeseries, "electricity_heating_kwh", electricityHeating, "GJ", elec_site_units)
    report_ts_output(runner, timeseries, "electricity_central_system_heating_kwh", centralElectricityHeating, "GJ", elec_site_units)
    report_ts_output(runner, timeseries, "electricity_cooling_kwh", electricityCooling, "GJ", elec_site_units)
    report_ts_output(runner, timeseries, "electricity_central_system_cooling_kwh", centralElectricityCooling, "GJ", elec_site_units)
    report_ts_output(runner, timeseries, "electricity_interior_lighting_kwh", electricityInteriorLighting, "GJ", elec_site_units)
    report_ts_output(runner, timeseries, "electricity_exterior_lighting_kwh", [electricityExteriorLighting, electricityExteriorHolidayLighting].transpose.map { |e| e.reduce(:+) }, "GJ", elec_site_units)
    report_ts_output(runner, timeseries, "electricity_interior_equipment_kwh", electricityInteriorEquipment, "GJ", elec_site_units)
    report_ts_output(runner, timeseries, "electricity_fans_heating_kwh", electricityFansHeating, "GJ", elec_site_units)
    report_ts_output(runner, timeseries, "electricity_fans_cooling_kwh", electricityFansCooling, "GJ", elec_site_units)
    report_ts_output(runner, timeseries, "electricity_pumps_heating_kwh", electricityPumpsHeating, "GJ", elec_site_units)
    report_ts_output(runner, timeseries, "electricity_central_system_pumps_heating_kwh", centralElectricityPumpsHeating, "GJ", elec_site_units)
    report_ts_output(runner, timeseries, "electricity_pumps_cooling_kwh", electricityPumpsCooling, "GJ", elec_site_units)
    report_ts_output(runner, timeseries, "electricity_central_system_pumps_cooling_kwh", centralElectricityPumpsCooling, "GJ", elec_site_units)
    report_ts_output(runner, timeseries, "electricity_water_systems_kwh", electricityWaterSystems, "GJ", elec_site_units)
    report_ts_output(runner, timeseries, "electricity_pv_kwh", modeledCentralElectricityPhotovoltaics, "GJ", elec_site_units)

    # NATURAL GAS

    naturalGasTotalEndUses = [naturalGasHeating, centralNaturalGasHeating, naturalGasInteriorEquipment, naturalGasWaterSystems].transpose.map { |n| n.reduce(:+) }

    report_ts_output(runner, timeseries, "total_site_natural_gas_therm", naturalGasTotalEndUses, "GJ", gas_site_units)
    report_ts_output(runner, timeseries, "natural_gas_heating_therm", naturalGasHeating, "GJ", gas_site_units)
    report_ts_output(runner, timeseries, "natural_gas_central_system_heating_therm", centralNaturalGasHeating, "GJ", gas_site_units)
    report_ts_output(runner, timeseries, "natural_gas_interior_equipment_therm", naturalGasInteriorEquipment, "GJ", gas_site_units)
    report_ts_output(runner, timeseries, "natural_gas_water_systems_therm", naturalGasWaterSystems, "GJ", gas_site_units)

    # FUEL OIL

    fuelOilTotalEndUses = [fuelOilHeating, centralFuelOilHeating, fuelOilInteriorEquipment, fuelOilWaterSystems].transpose.map { |f| f.reduce(:+) }

    report_ts_output(runner, timeseries, "total_site_fuel_oil_mbtu", fuelOilTotalEndUses, "GJ", other_fuel_site_units)
    report_ts_output(runner, timeseries, "fuel_oil_heating_mbtu", fuelOilHeating, "GJ", other_fuel_site_units)
    report_ts_output(runner, timeseries, "fuel_oil_central_system_heating_mbtu", centralFuelOilHeating, "GJ", other_fuel_site_units)
    report_ts_output(runner, timeseries, "fuel_oil_interior_equipment_mbtu", fuelOilInteriorEquipment, "GJ", other_fuel_site_units)
    report_ts_output(runner, timeseries, "fuel_oil_water_systems_mbtu", fuelOilWaterSystems, "GJ", other_fuel_site_units)

    # PROPANE

    propaneTotalEndUses = [propaneHeating, centralPropaneHeating, propaneInteriorEquipment, propaneWaterSystems].transpose.map { |p| p.reduce(:+) }

    report_ts_output(runner, timeseries, "total_site_propane_mbtu", propaneTotalEndUses, "GJ", other_fuel_site_units)
    report_ts_output(runner, timeseries, "propane_heating_mbtu", propaneHeating, "GJ", other_fuel_site_units)
    report_ts_output(runner, timeseries, "propane_central_system_heating_mbtu", centralPropaneHeating, "GJ", other_fuel_site_units)
    report_ts_output(runner, timeseries, "propane_interior_equipment_mbtu", propaneInteriorEquipment, "GJ", other_fuel_site_units)
    report_ts_output(runner, timeseries, "propane_water_systems_mbtu", propaneWaterSystems, "GJ", other_fuel_site_units)

    # TOTAL

    totalSiteEnergy = [electricityTotalEndUses, naturalGasTotalEndUses, fuelOilTotalEndUses, propaneTotalEndUses].transpose.map { |t| t.reduce(:+) }

    report_ts_output(runner, timeseries, "total_site_energy_mbtu", totalSiteEnergy, "GJ", total_site_units)
    report_ts_output(runner, timeseries, "net_site_energy_mbtu", [totalSiteEnergy, modeledCentralElectricityPhotovoltaics].transpose.collect { |e1, e2| e1 - e2 }, "GJ", total_site_units)

    # END USE SUBCATEGORIES

    if include_enduse_subcategories
      report_ts_output(runner, timeseries, "electricity_refrigerator_kwh", electricityRefrigerator, "GJ", elec_site_units)
      report_ts_output(runner, timeseries, "electricity_clothes_washer_kwh", electricityClothesWasher, "GJ", elec_site_units)
      report_ts_output(runner, timeseries, "electricity_clothes_dryer_kwh", electricityClothesDryer, "GJ", elec_site_units)
      report_ts_output(runner, timeseries, "natural_gas_clothes_dryer_therm", naturalGasClothesDryer, "GJ", gas_site_units)
      report_ts_output(runner, timeseries, "propane_clothes_dryer_mbtu", propaneClothesDryer, "GJ", other_fuel_site_units)
      report_ts_output(runner, timeseries, "electricity_cooking_range_kwh", electricityCookingRange, "GJ", elec_site_units)
      report_ts_output(runner, timeseries, "natural_gas_cooking_range_therm", naturalGasCookingRange, "GJ", gas_site_units)
      report_ts_output(runner, timeseries, "propane_cooking_range_mbtu", propaneCookingRange, "GJ", other_fuel_site_units)
      report_ts_output(runner, timeseries, "electricity_dishwasher_kwh", electricityDishwasher, "GJ", elec_site_units)
      report_ts_output(runner, timeseries, "electricity_plug_loads_kwh", electricityPlugLoads, "GJ", elec_site_units)
      report_ts_output(runner, timeseries, "electricity_house_fan_kwh", electricityHouseFan, "GJ", elec_site_units)
      report_ts_output(runner, timeseries, "electricity_range_fan_kwh", electricityRangeFan, "GJ", elec_site_units)
      report_ts_output(runner, timeseries, "electricity_bath_fan_kwh", electricityBathFan, "GJ", elec_site_units)
      report_ts_output(runner, timeseries, "electricity_ceiling_fan_kwh", electricityCeilingFan, "GJ", elec_site_units)
      report_ts_output(runner, timeseries, "electricity_extra_refrigerator_kwh", electricityExtraRefrigerator, "GJ", elec_site_units)
      report_ts_output(runner, timeseries, "electricity_freezer_kwh", electricityFreezer, "GJ", elec_site_units)
      report_ts_output(runner, timeseries, "electricity_pool_heater_kwh", electricityPoolHeater, "GJ", elec_site_units)
      report_ts_output(runner, timeseries, "natural_gas_pool_heater_therm", naturalGasPoolHeater, "GJ", gas_site_units)
      report_ts_output(runner, timeseries, "electricity_pool_pump_kwh", electricityPoolPump, "GJ", elec_site_units)
      report_ts_output(runner, timeseries, "electricity_hot_tub_heater_kwh", electricityHotTubHeater, "GJ", elec_site_units)
      report_ts_output(runner, timeseries, "natural_gas_hot_tub_heater_therm", naturalGasHotTubHeater, "GJ", gas_site_units)
      report_ts_output(runner, timeseries, "electricity_hot_tub_pump_kwh", electricityHotTubPump, "GJ", elec_site_units)
      report_ts_output(runner, timeseries, "natural_gas_grill_therm", naturalGasGrill, "GJ", gas_site_units)
      report_ts_output(runner, timeseries, "natural_gas_lighting_therm", naturalGasLighting, "GJ", gas_site_units)
      report_ts_output(runner, timeseries, "natural_gas_fireplace_therm", naturalGasFireplace, "GJ", gas_site_units)
      report_ts_output(runner, timeseries, "electricity_well_pump_kwh", electricityWellPump, "GJ", elec_site_units)
      report_ts_output(runner, timeseries, "electricity_garage_lighting_kwh", electricityGarageLighting, "GJ", elec_site_units)
      report_ts_output(runner, timeseries, "electricity_exterior_holiday_lighting_kwh", electricityExteriorHolidayLighting, "GJ", elec_site_units)
    end

    output_vars.each do |output_var|
      sqlFile.availableKeyValues(ann_env_pd, reporting_frequency_map[reporting_frequency], output_var).each do |key_value|
        request = sqlFile.timeSeries(ann_env_pd, reporting_frequency_map[reporting_frequency], output_var, key_value)
        next if request.empty?

        request = request.get
        vals = request.values
        old_units = request.units
        new_units = old_units
        if old_units == "C"
          new_units = "F"
        end
        name = "#{output_var.upcase} (#{key_value})"
        unless new_units.empty?
          name += " [#{new_units}]"
        end
        report_ts_output(runner, timeseries, name, vals, old_units, new_units)
      end
    end

    sqlFile.close()

    csv_path = File.expand_path("../enduse_timeseries.csv")
    CSV.open(csv_path, "wb") do |csv|
      csv << timeseries.keys
      rows = timeseries.values.transpose
      rows.each do |row|
        csv << row
      end
    end

    return true
  end # end the run method

  def report_ts_output(runner, timeseries, name, vals, os_units, desired_units)
    timeseries[name] = []
    timeseries["Time"].each_with_index do |ts, i|
      timeseries[name] << UnitConversions.convert(vals[i], os_units, desired_units)
    end
    runner.registerInfo("Exporting #{name}.")
  end

  def format_datetime(date_time)
    date_time.gsub!("-", "/")
    date_time.gsub!("Jan", "01")
    date_time.gsub!("Feb", "02")
    date_time.gsub!("Mar", "03")
    date_time.gsub!("Apr", "04")
    date_time.gsub!("May", "05")
    date_time.gsub!("Jun", "06")
    date_time.gsub!("Jul", "07")
    date_time.gsub!("Aug", "08")
    date_time.gsub!("Sep", "09")
    date_time.gsub!("Oct", "10")
    date_time.gsub!("Nov", "11")
    date_time.gsub!("Dec", "12")
    return date_time
  end

  def array_sum(array1, array2, units_represented = 1, num_units = 1)
    array = [array1, array2].transpose.collect { |a1, a2| a1 + units_represented * (a2 / num_units) }
    return array
  end
end

# register the measure to be used by the application
TimeseriesCSVExport.new.registerWithApplication
