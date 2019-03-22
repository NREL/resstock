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
    arg.setDescription("Whether to report end use subcategories: refrigerator, clothes dryer, plug loads, etc.")
    arg.setDefaultValue(false)
    args << arg

    return args
  end

  # return a vector of IdfObject's to request EnergyPlus objects needed by the run method
  def energyPlusOutputRequests(runner, user_arguments)
    super(runner, user_arguments)

    reporting_frequency = runner.getStringArgumentValue("reporting_frequency", user_arguments)
    include_enduse_subcategories = runner.getBoolArgumentValue("include_enduse_subcategories", user_arguments)

    # get the last model and sql file
    model = runner.lastOpenStudioModel
    if model.empty?
      runner.registerError("Cannot find last model.")
      return false
    end
    model = model.get

    results = OutputMeters.create_custom_building_unit_meters(model, runner, reporting_frequency, include_enduse_subcategories)
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

    # Get meters that aren't tied to units (i.e., get apportioned evenly across units)
    centralElectricityHeating = [0] * num_ts
    centralElectricityCooling = [0] * num_ts
    centralElectricityExteriorLighting = [0] * num_ts
    centralElectricityPumpsHeating = [0] * num_ts
    centralElectricityPumpsCooling = [0] * num_ts
    centralElectricityInteriorEquipment = [0] * num_ts
    centralElectricityPhotovoltaics = [0] * num_ts
    centralNaturalGasHeating = [0] * num_ts
    centralFuelOilHeating = [0] * num_ts
    centralPropaneHeating = [0] * num_ts

    central_electricity_heating_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('CENTRAL:ELECTRICITYHEATING') AND ReportingFrequency='#{reporting_frequency_map[reporting_frequency]}' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
    unless sqlFile.execAndReturnVectorOfDouble(central_electricity_heating_query).get.empty?
      centralElectricityHeating = sqlFile.execAndReturnVectorOfDouble(central_electricity_heating_query).get
    end

    central_electricity_cooling_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('CENTRAL:ELECTRICITYCOOLING') AND ReportingFrequency='#{reporting_frequency_map[reporting_frequency]}' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
    unless sqlFile.execAndReturnVectorOfDouble(central_electricity_cooling_query).get.empty?
      centralElectricityCooling = sqlFile.execAndReturnVectorOfDouble(central_electricity_cooling_query).get
    end

    central_electricity_exterior_lighting_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('CENTRAL:ELECTRICITYEXTERIORLIGHTING') AND ReportingFrequency='#{reporting_frequency_map[reporting_frequency]}' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
    unless sqlFile.execAndReturnVectorOfDouble(central_electricity_exterior_lighting_query).get.empty?
      centralElectricityExteriorLighting = sqlFile.execAndReturnVectorOfDouble(central_electricity_exterior_lighting_query).get
    end

    central_electricity_pumps_heating_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('CENTRAL:ELECTRICITYPUMPSHEATING') AND ReportingFrequency='#{reporting_frequency_map[reporting_frequency]}' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
    unless sqlFile.execAndReturnVectorOfDouble(central_electricity_pumps_heating_query).get.empty?
      centralElectricityPumpsHeating = sqlFile.execAndReturnVectorOfDouble(central_electricity_pumps_heating_query).get
    end

    central_electricity_pumps_cooling_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('CENTRAL:ELECTRICITYPUMPSCOOLING') AND ReportingFrequency='#{reporting_frequency_map[reporting_frequency]}' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
    unless sqlFile.execAndReturnVectorOfDouble(central_electricity_pumps_cooling_query).get.empty?
      centralElectricityPumpsCooling = sqlFile.execAndReturnVectorOfDouble(central_electricity_pumps_cooling_query).get
    end

    central_electricity_interior_equipment_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('CENTRAL:ELECTRICITYINTERIOREQUIPMENT') AND ReportingFrequency='#{reporting_frequency_map[reporting_frequency]}' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
    unless sqlFile.execAndReturnVectorOfDouble(central_electricity_interior_equipment_query).get.empty?
      centralElectricityInteriorEquipment = sqlFile.execAndReturnVectorOfDouble(central_electricity_interior_equipment_query).get
    end

    central_electricity_photovoltaics_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('CENTRAL:ELECTRICITYPHOTOVOLTAICS') AND ReportingFrequency='#{reporting_frequency_map[reporting_frequency]}' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
    unless sqlFile.execAndReturnVectorOfDouble(central_electricity_photovoltaics_query).get.empty?
      centralElectricityPhotovoltaics = sqlFile.execAndReturnVectorOfDouble(central_electricity_photovoltaics_query).get
    end

    central_natural_gas_heating_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('CENTRAL:NATURALGASHEATING') AND ReportingFrequency='#{reporting_frequency_map[reporting_frequency]}' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
    unless sqlFile.execAndReturnVectorOfDouble(central_natural_gas_heating_query).get.empty?
      centralNaturalGasHeating = sqlFile.execAndReturnVectorOfDouble(central_natural_gas_heating_query).get
    end

    central_fuel_oil_heating_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('CENTRAL:FUELOILHEATING') AND ReportingFrequency='#{reporting_frequency_map[reporting_frequency]}' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
    unless sqlFile.execAndReturnVectorOfDouble(central_fuel_oil_heating_query).get.empty?
      centralFuelOilHeating = sqlFile.execAndReturnVectorOfDouble(central_fuel_oil_heating_query).get
    end

    central_propane_heating_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('CENTRAL:PROPANEHEATING') AND ReportingFrequency='#{reporting_frequency_map[reporting_frequency]}' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
    unless sqlFile.execAndReturnVectorOfDouble(central_propane_heating_query).get.empty?
      centralPropaneHeating = sqlFile.execAndReturnVectorOfDouble(central_propane_heating_query).get
    end

    # Get meters that are tied to units
    electricityTotalEndUses = [0] * num_ts
    electricityHeating = [0] * num_ts
    electricityCooling = [0] * num_ts
    electricityInteriorLighting = [0] * num_ts
    electricityExteriorLighting = [0] * num_ts
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

    # Get building units
    units = Geometry.get_building_units(model, runner)
    if units.nil?
      return false
    end

    total_units_represented = 0
    units.each do |unit|
      unit_name = unit.name.to_s.upcase

      thermal_zones = []
      unit.spaces.each do |space|
        thermal_zone = space.thermalZone.get
        unless thermal_zones.include? thermal_zone
          thermal_zones << thermal_zone
        end
      end

      units_represented = 1
      if unit.additionalProperties.getFeatureAsInteger("Units Represented").is_initialized
        units_represented = unit.additionalProperties.getFeatureAsInteger("Units Represented").get
      end
      total_units_represented += units_represented

      electricity_heating_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:ELECTRICITYHEATING') AND ReportingFrequency='#{reporting_frequency_map[reporting_frequency]}' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
      unless sqlFile.execAndReturnVectorOfDouble(electricity_heating_query).get.empty?
        electricityHeating = array_sum(electricityHeating, sqlFile.execAndReturnVectorOfDouble(electricity_heating_query).get, units_represented)
      end
      electricityHeating = array_sum(electricityHeating, centralElectricityHeating, units_represented, units.length)

      electricity_cooling_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:ELECTRICITYCOOLING') AND ReportingFrequency='#{reporting_frequency_map[reporting_frequency]}' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
      unless sqlFile.execAndReturnVectorOfDouble(electricity_cooling_query).get.empty?
        electricityCooling = array_sum(electricityCooling, sqlFile.execAndReturnVectorOfDouble(electricity_cooling_query).get, units_represented)
      end
      electricityCooling = array_sum(electricityCooling, centralElectricityCooling, units_represented, units.length)

      electricity_interior_lighting_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:ELECTRICITYINTERIORLIGHTING') AND ReportingFrequency='#{reporting_frequency_map[reporting_frequency]}' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
      unless sqlFile.execAndReturnVectorOfDouble(electricity_interior_lighting_query).get.empty?
        electricityInteriorLighting = array_sum(electricityInteriorLighting, sqlFile.execAndReturnVectorOfDouble(electricity_interior_lighting_query).get, units_represented)
      end

      electricityExteriorLighting = array_sum(electricityExteriorLighting, centralElectricityExteriorLighting, units_represented, units.length)

      electricity_interior_equipment_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:ELECTRICITYINTERIOREQUIPMENT') AND ReportingFrequency='#{reporting_frequency_map[reporting_frequency]}' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
      unless sqlFile.execAndReturnVectorOfDouble(electricity_interior_equipment_query).get.empty?
        electricityInteriorEquipment = array_sum(electricityInteriorEquipment, sqlFile.execAndReturnVectorOfDouble(electricity_interior_equipment_query).get, units_represented)
      end
      electricityInteriorEquipment = array_sum(electricityInteriorEquipment, centralElectricityInteriorEquipment, units_represented, units.length)

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
      electricityPumpsHeating = array_sum(electricityPumpsHeating, centralElectricityPumpsHeating, units_represented, units.length)

      electricity_pumps_cooling_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:ELECTRICITYPUMPSCOOLING') AND ReportingFrequency='#{reporting_frequency_map[reporting_frequency]}' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
      unless sqlFile.execAndReturnVectorOfDouble(electricity_pumps_cooling_query).get.empty?
        electricityPumpsCooling = array_sum(electricityPumpsCooling, sqlFile.execAndReturnVectorOfDouble(electricity_pumps_cooling_query).get, units_represented)
      end
      electricityPumpsCooling = array_sum(electricityPumpsCooling, centralElectricityPumpsCooling, units_represented, units.length)

      electricity_water_systems_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:ELECTRICITYWATERSYSTEMS') AND ReportingFrequency='#{reporting_frequency_map[reporting_frequency]}' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
      unless sqlFile.execAndReturnVectorOfDouble(electricity_water_systems_query).get.empty?
        electricityWaterSystems = array_sum(electricityWaterSystems, sqlFile.execAndReturnVectorOfDouble(electricity_water_systems_query).get, units_represented)
      end

      natural_gas_heating_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:NATURALGASHEATING') AND ReportingFrequency='#{reporting_frequency_map[reporting_frequency]}' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
      unless sqlFile.execAndReturnVectorOfDouble(natural_gas_heating_query).get.empty?
        naturalGasHeating = array_sum(naturalGasHeating, sqlFile.execAndReturnVectorOfDouble(natural_gas_heating_query).get, units_represented)
      end
      naturalGasHeating = array_sum(naturalGasHeating, centralNaturalGasHeating, units_represented, units.length)

      natural_gas_interior_equipment_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:NATURALGASINTERIOREQUIPMENT') AND ReportingFrequency='#{reporting_frequency_map[reporting_frequency]}' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
      unless sqlFile.execAndReturnVectorOfDouble(natural_gas_interior_equipment_query).get.empty?
        naturalGasInteriorEquipment = array_sum(naturalGasInteriorEquipment, sqlFile.execAndReturnVectorOfDouble(natural_gas_interior_equipment_query).get, units_represented)
      end

      natural_gas_water_systems_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:NATURALGASWATERSYSTEMS') AND ReportingFrequency='#{reporting_frequency_map[reporting_frequency]}' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
      unless sqlFile.execAndReturnVectorOfDouble(natural_gas_water_systems_query).get.empty?
        naturalGasWaterSystems = array_sum(naturalGasWaterSystems, sqlFile.execAndReturnVectorOfDouble(natural_gas_water_systems_query).get, units_represented)
      end

      fuel_oil_heating_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:FUELOILHEATING') AND ReportingFrequency='#{reporting_frequency_map[reporting_frequency]}' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
      unless sqlFile.execAndReturnVectorOfDouble(fuel_oil_heating_query).get.empty?
        fuelOilHeating = array_sum(fuelOilHeating, sqlFile.execAndReturnVectorOfDouble(fuel_oil_heating_query).get, units_represented)
      end
      fuelOilHeating = array_sum(fuelOilHeating, centralFuelOilHeating, units_represented, units.length)

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
      propaneHeating = array_sum(propaneHeating, centralPropaneHeating, units_represented, units.length)

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

    # ELECTRICITY

    electricityTotalEndUses = [electricityHeating, electricityCooling, electricityInteriorLighting, electricityExteriorLighting, electricityInteriorEquipment, electricityFansHeating, electricityFansCooling, electricityPumpsHeating, electricityPumpsCooling, electricityWaterSystems].transpose.collect { |e1, e2, e3, e4, e5, e6, e7, e8, e9, e10| e1 + e2 + e3 + e4 + e5 + e6 + e7 + e8 + e9 + e10 }

    report_ts_output(runner, timeseries, "total_site_electricity_kwh", electricityTotalEndUses, "GJ", elec_site_units)
    report_ts_output(runner, timeseries, "net_site_electricity_kwh", [electricityTotalEndUses, centralElectricityPhotovoltaics].transpose.collect { |e1, e2| e1 - e2 }, "GJ", elec_site_units)
    report_ts_output(runner, timeseries, "electricity_heating_kwh", electricityHeating, "GJ", elec_site_units)
    report_ts_output(runner, timeseries, "electricity_cooling_kwh", electricityCooling, "GJ", elec_site_units)
    report_ts_output(runner, timeseries, "electricity_interior_lighting_kwh", electricityInteriorLighting, "GJ", elec_site_units)
    report_ts_output(runner, timeseries, "electricity_exterior_lighting_kwh", electricityExteriorLighting, "GJ", elec_site_units)
    report_ts_output(runner, timeseries, "electricity_interior_equipment_kwh", electricityInteriorEquipment, "GJ", elec_site_units)
    report_ts_output(runner, timeseries, "electricity_fans_heating_kwh", electricityFansHeating, "GJ", elec_site_units)
    report_ts_output(runner, timeseries, "electricity_fans_cooling_kwh", electricityFansCooling, "GJ", elec_site_units)
    report_ts_output(runner, timeseries, "electricity_pumps_heating_kwh", electricityPumpsHeating, "GJ", elec_site_units)
    report_ts_output(runner, timeseries, "electricity_pumps_cooling_kwh", electricityPumpsCooling, "GJ", elec_site_units)
    report_ts_output(runner, timeseries, "electricity_water_systems_kwh", electricityWaterSystems, "GJ", elec_site_units)
    report_ts_output(runner, timeseries, "electricity_pv_kwh", centralElectricityPhotovoltaics, "GJ", elec_site_units)

    # NATURAL GAS

    naturalGasTotalEndUses = [naturalGasHeating, naturalGasInteriorEquipment, naturalGasWaterSystems].transpose.collect { |n1, n2, n3| n1 + n2 + n3 }

    report_ts_output(runner, timeseries, "total_site_natural_gas_therm", naturalGasTotalEndUses, "GJ", gas_site_units)
    report_ts_output(runner, timeseries, "natural_gas_heating_therm", naturalGasHeating, "GJ", gas_site_units)
    report_ts_output(runner, timeseries, "natural_gas_interior_equipment_therm", naturalGasInteriorEquipment, "GJ", gas_site_units)
    report_ts_output(runner, timeseries, "natural_gas_water_systems_therm", naturalGasWaterSystems, "GJ", gas_site_units)

    # FUEL OIL

    fuelOilTotalEndUses = [fuelOilHeating, fuelOilInteriorEquipment, fuelOilWaterSystems].transpose.collect { |f1, f2, f3| f1 + f2 + f3 }

    report_ts_output(runner, timeseries, "total_site_fuel_oil_mbtu", fuelOilTotalEndUses, "GJ", other_fuel_site_units)
    report_ts_output(runner, timeseries, "fuel_oil_heating_mbtu", fuelOilHeating, "GJ", other_fuel_site_units)
    report_ts_output(runner, timeseries, "fuel_oil_interior_equipment_mbtu", fuelOilInteriorEquipment, "GJ", other_fuel_site_units)
    report_ts_output(runner, timeseries, "fuel_oil_water_systems_mbtu", fuelOilWaterSystems, "GJ", other_fuel_site_units)

    # PROPANE

    propaneTotalEndUses = [propaneHeating, propaneInteriorEquipment, propaneWaterSystems].transpose.collect { |p1, p2, p3| p1 + p2 + p3 }

    report_ts_output(runner, timeseries, "total_site_propane_mbtu", propaneTotalEndUses, "GJ", other_fuel_site_units)
    report_ts_output(runner, timeseries, "propane_heating_mbtu", propaneHeating, "GJ", other_fuel_site_units)
    report_ts_output(runner, timeseries, "propane_interior_equipment_mbtu", propaneInteriorEquipment, "GJ", other_fuel_site_units)
    report_ts_output(runner, timeseries, "propane_water_systems_mbtu", propaneWaterSystems, "GJ", other_fuel_site_units)

    # TOTAL

    totalSiteEnergy = [electricityTotalEndUses, naturalGasTotalEndUses, fuelOilTotalEndUses, propaneTotalEndUses].transpose.collect { |t1, t2, t3, t4| t1 + t2 + t3 + t4 }

    report_ts_output(runner, timeseries, "total_site_energy_mbtu", totalSiteEnergy, "GJ", total_site_units)
    report_ts_output(runner, timeseries, "net_site_energy_mbtu", [totalSiteEnergy, centralElectricityPhotovoltaics].transpose.collect { |e1, e2| e1 - e2 }, "GJ", total_site_units)

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
    vals.each do |val|
      timeseries[name] << UnitConversions.convert(val, os_units, desired_units)
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
