require 'openstudio'
if File.exists? File.absolute_path(File.join(File.dirname(__FILE__), "../../lib/resources/measures/HPXMLtoOpenStudio/resources")) # Hack to run ResStock on AWS
  resources_path = File.absolute_path(File.join(File.dirname(__FILE__), "../../lib/resources/measures/HPXMLtoOpenStudio/resources"))
elsif File.exists? File.absolute_path(File.join(File.dirname(__FILE__), "../../resources/measures/HPXMLtoOpenStudio/resources")) # Hack to run ResStock unit tests locally
  resources_path = File.absolute_path(File.join(File.dirname(__FILE__), "../../resources/measures/HPXMLtoOpenStudio/resources"))
elsif File.exists? File.join(OpenStudio::BCLMeasure::userMeasuresDir.to_s, "HPXMLtoOpenStudio/resources") # Hack to run measures in the OS App since applied measures are copied off into a temporary directory
  resources_path = File.join(OpenStudio::BCLMeasure::userMeasuresDir.to_s, "HPXMLtoOpenStudio/resources")
else
  resources_path = File.absolute_path(File.join(File.dirname(__FILE__), "../HPXMLtoOpenStudio/resources"))
end
require File.join(resources_path, "unit_conversions")
require File.join(resources_path, "waterheater")

# start the measure
class SimulationOutputReport < OpenStudio::Measure::ReportingMeasure
  # define the name that a user will see, this method may be deprecated as
  # the display name in PAT comes from the name field in measure.xml
  def name
    return "Simulation Output Report"
  end

  def description
    return "Reports simulation outputs of interest."
  end

  def num_options
    return Constants.NumApplyUpgradeOptions # Synced with SimulationOutputReport measure
  end

  def num_costs_per_option
    return Constants.NumApplyUpgradesCostsPerOption # Synced with SimulationOutputReport measure
  end

  # define the arguments that the user will input
  def arguments
    args = OpenStudio::Ruleset::OSArgumentVector.new

    return args
  end # end the arguments method

  # return a vector of IdfObject's to request EnergyPlus objects needed by the run method
  def energyPlusOutputRequests(runner, user_arguments)
    super(runner, user_arguments)

    return OpenStudio::IdfObjectVector.new if runner.halted

    # get the last model and sql file
    model = runner.lastOpenStudioModel
    if model.empty?
      runner.registerError("Cannot find last model.")
      return false
    end
    model = model.get

    results = OutputMeters.create_custom_building_unit_meters(model, runner, "RunPeriod")
    return results
  end

  def outputs
    result = OpenStudio::Measure::OSOutputVector.new
    buildstock_outputs = [
      "total_site_energy_mbtu",
      "total_site_electricity_kwh",
      "total_site_natural_gas_therm",
      "total_site_fuel_oil_mbtu",
      "total_site_propane_mbtu",
      "net_site_energy_mbtu", # Incorporates PV
      "net_site_electricity_kwh", # Incorporates PV
      "electricity_heating_kwh",
      "electricity_central_system_heating_kwh",
      "electricity_cooling_kwh",
      "electricity_central_system_cooling_kwh",
      "electricity_interior_lighting_kwh",
      "electricity_exterior_lighting_kwh",
      "electricity_interior_equipment_kwh",
      "electricity_fans_heating_kwh",
      "electricity_fans_cooling_kwh",
      "electricity_pumps_heating_kwh",
      "electricity_central_system_pumps_heating_kwh",
      "electricity_pumps_cooling_kwh",
      "electricity_central_system_pumps_cooling_kwh",
      "electricity_water_systems_kwh",
      "electricity_pv_kwh",
      "natural_gas_heating_therm",
      "natural_gas_central_system_heating_therm",
      "natural_gas_interior_equipment_therm",
      "natural_gas_water_systems_therm",
      "fuel_oil_heating_mbtu",
      "fuel_oil_central_system_heating_mbtu",
      "fuel_oil_interior_equipment_mbtu",
      "fuel_oil_water_systems_mbtu",
      "propane_heating_mbtu",
      "propane_central_system_heating_mbtu",
      "propane_interior_equipment_mbtu",
      "propane_water_systems_mbtu",
      "hours_heating_setpoint_not_met",
      "hours_cooling_setpoint_not_met",
      "hvac_cooling_capacity_w",
      "hvac_heating_capacity_w",
      "hvac_heating_supp_capacity_w",
      "weight",
      "upgrade_cost_usd"
    ]
    buildstock_outputs += cost_mult_types.values
    for option_num in 1..num_options
      buildstock_outputs << "option_%02d_cost_usd" % option_num
      buildstock_outputs << "option_%02d_lifetime_yrs" % option_num
    end
    buildstock_outputs.each do |output|
      result << OpenStudio::Measure::OSOutput.makeDoubleOutput(output)
    end
    result << OpenStudio::Measure::OSOutput.makeStringOutput("upgrade_name")

    return result
  end

  def cost_mult_types
    return {
      "Wall Area, Above-Grade, Conditioned (ft^2)" => "wall_area_above_grade_conditioned_ft_2",
      "Wall Area, Above-Grade, Exterior (ft^2)" => "wall_area_above_grade_exterior_ft_2",
      "Wall Area, Below-Grade (ft^2)" => "wall_area_below_grade_ft_2",
      "Floor Area, Conditioned (ft^2)" => "floor_area_conditioned_ft_2",
      "Floor Area, Attic (ft^2)" => "floor_area_attic_ft_2",
      "Floor Area, Lighting (ft^2)" => "floor_area_lighting_ft_2",
      "Roof Area (ft^2)" => "roof_area_ft_2",
      "Window Area (ft^2)" => "window_area_ft_2",
      "Door Area (ft^2)" => "door_area_ft_2",
      "Duct Surface Area (ft^2)" => "duct_surface_area_ft_2",
      "Size, Heating System (kBtu/h)" => "size_heating_system_kbtu_h",
      "Size, Cooling System (kBtu/h)" => "size_cooling_system_kbtu_h",
      "Size, Water Heater (gal)" => "size_water_heater_gal"
    }
  end

  # define what happens when the measure is run
  def run(runner, user_arguments)
    super(runner, user_arguments)

    # use the built-in error checking
    if not runner.validateUserArguments(arguments(), user_arguments)
      return false
    end

    # get the last model and sql file
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

    # Load buildstock_file
    resources_dir = File.absolute_path(File.join(File.dirname(__FILE__), "..", "..", "lib", "resources")) # Should have been uploaded per 'Other Library Files' in analysis spreadsheet
    buildstock_file = File.join(resources_dir, "buildstock.rb")
    require File.join(File.dirname(buildstock_file), File.basename(buildstock_file, File.extname(buildstock_file)))

    total_site_units = "MBtu"
    elec_site_units = "kWh"
    gas_site_units = "therm"
    other_fuel_site_units = "MBtu"

    # Get meters that aren't tied to units (i.e., are metered at the building level)
    modeledCentralElectricityHeating = 0.0
    modeledCentralElectricityCooling = 0.0
    modeledCentralElectricityExteriorLighting = 0.0
    modeledCentralElectricityExteriorHolidayLighting = 0.0
    modeledCentralElectricityPumpsHeating = 0.0
    modeledCentralElectricityPumpsCooling = 0.0
    modeledCentralElectricityInteriorEquipment = 0.0
    modeledCentralNaturalGasHeating = 0.0
    modeledCentralNaturalGasInteriorEquipment = 0.0
    modeledCentralFuelOilHeating = 0.0
    modeledCentralFuelOilInteriorEquipment = 0.0
    modeledCentralPropaneHeating = 0.0
    modeledCentralPropaneInteriorEquipment = 0.0

    central_electricity_heating_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('CENTRAL:ELECTRICITYHEATING') AND ReportingFrequency='Run Period' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
    unless sqlFile.execAndReturnFirstDouble(central_electricity_heating_query).empty?
      modeledCentralElectricityHeating = sqlFile.execAndReturnFirstDouble(central_electricity_heating_query).get.round(2)
    end

    central_electricity_cooling_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('CENTRAL:ELECTRICITYCOOLING') AND ReportingFrequency='Run Period' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
    unless sqlFile.execAndReturnFirstDouble(central_electricity_cooling_query).empty?
      modeledCentralElectricityCooling = sqlFile.execAndReturnFirstDouble(central_electricity_cooling_query).get.round(2)
    end

    central_electricity_exterior_lighting_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('CENTRAL:ELECTRICITYEXTERIORLIGHTING') AND ReportingFrequency='Run Period' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
    unless sqlFile.execAndReturnFirstDouble(central_electricity_exterior_lighting_query).empty?
      modeledCentralElectricityExteriorLighting = sqlFile.execAndReturnFirstDouble(central_electricity_exterior_lighting_query).get.round(2)
    end

    central_electricity_exterior_holiday_lighting_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('CENTRAL:ELECTRICITYEXTERIORHOLIDAYLIGHTING') AND ReportingFrequency='Run Period' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
    unless sqlFile.execAndReturnFirstDouble(central_electricity_exterior_holiday_lighting_query).empty?
      modeledCentralElectricityExteriorHolidayLighting = sqlFile.execAndReturnFirstDouble(central_electricity_exterior_holiday_lighting_query).get.round(2)
    end

    central_electricity_pumps_heating_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('CENTRAL:ELECTRICITYPUMPSHEATING') AND ReportingFrequency='Run Period' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
    unless sqlFile.execAndReturnFirstDouble(central_electricity_pumps_heating_query).empty?
      modeledCentralElectricityPumpsHeating = sqlFile.execAndReturnFirstDouble(central_electricity_pumps_heating_query).get.round(2)
    end

    central_electricity_pumps_cooling_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('CENTRAL:ELECTRICITYPUMPSCOOLING') AND ReportingFrequency='Run Period' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
    unless sqlFile.execAndReturnFirstDouble(central_electricity_pumps_cooling_query).empty?
      modeledCentralElectricityPumpsCooling = sqlFile.execAndReturnFirstDouble(central_electricity_pumps_cooling_query).get.round(2)
    end

    central_electricity_interior_equipment_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('CENTRAL:ELECTRICITYINTERIOREQUIPMENT') AND ReportingFrequency='Run Period' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
    unless sqlFile.execAndReturnFirstDouble(central_electricity_interior_equipment_query).empty?
      modeledCentralElectricityInteriorEquipment = sqlFile.execAndReturnFirstDouble(central_electricity_interior_equipment_query).get.round(2)
    end

    central_natural_gas_heating_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('CENTRAL:NATURALGASHEATING') AND ReportingFrequency='Run Period' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
    unless sqlFile.execAndReturnFirstDouble(central_natural_gas_heating_query).empty?
      modeledCentralNaturalGasHeating = sqlFile.execAndReturnFirstDouble(central_natural_gas_heating_query).get.round(2)
    end

    central_natural_gas_interior_equipment_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('CENTRAL:NATURALGASINTERIOREQUIPMENT') AND ReportingFrequency='Run Period' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
    unless sqlFile.execAndReturnFirstDouble(central_natural_gas_interior_equipment_query).empty?
      modeledCentralNaturalGasInteriorEquipment = sqlFile.execAndReturnFirstDouble(central_natural_gas_interior_equipment_query).get.round(2)
    end

    central_fuel_oil_heating_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('CENTRAL:FUELOILHEATING') AND ReportingFrequency='Run Period' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
    unless sqlFile.execAndReturnFirstDouble(central_fuel_oil_heating_query).empty?
      modeledCentralFuelOilHeating = sqlFile.execAndReturnFirstDouble(central_fuel_oil_heating_query).get.round(2)
    end

    central_fuel_oil_interior_equipment_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('CENTRAL:FUELOILINTERIOREQUIPMENT') AND ReportingFrequency='Run Period' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
    unless sqlFile.execAndReturnFirstDouble(central_fuel_oil_interior_equipment_query).empty?
      modeledCentralFuelOilInteriorEquipment = sqlFile.execAndReturnFirstDouble(central_fuel_oil_interior_equipment_query).get.round(2)
    end

    central_propane_heating_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('CENTRAL:PROPANEHEATING') AND ReportingFrequency='Run Period' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
    unless sqlFile.execAndReturnFirstDouble(central_propane_heating_query).empty?
      modeledCentralPropaneHeating = sqlFile.execAndReturnFirstDouble(central_propane_heating_query).get.round(2)
    end

    central_propane_interior_equipment_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('CENTRAL:PROPANEINTERIOREQUIPMENT') AND ReportingFrequency='Run Period' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
    unless sqlFile.execAndReturnFirstDouble(central_propane_interior_equipment_query).empty?
      modeledCentralPropaneInteriorEquipment = sqlFile.execAndReturnFirstDouble(central_propane_interior_equipment_query).get.round(2)
    end

    # Initialize variables to check against sql file totals
    modeledElectricityFansHeating = 0.0
    modeledElectricityFansCooling = 0.0
    modeledElectricityPumpsHeating = modeledCentralElectricityPumpsHeating
    modeledElectricityPumpsCooling = modeledCentralElectricityPumpsCooling

    # Separate these from non central systems
    centralElectricityHeating = 0.0
    centralElectricityCooling = 0.0
    centralElectricityPumpsHeating = 0.0
    centralElectricityPumpsCooling = 0.0
    centralNaturalGasHeating = 0.0
    centralFuelOilHeating = 0.0
    centralPropaneHeating = 0.0

    # Get meters that are tied to units, and apportion building level meters to these
    electricityTotalEndUses = 0.0
    electricityHeating = 0.0
    electricityCooling = 0.0
    electricityInteriorLighting = 0.0
    electricityExteriorLighting = 0.0
    electricityExteriorHolidayLighting = modeledCentralElectricityExteriorHolidayLighting
    electricityInteriorEquipment = 0.0
    electricityFansHeating = 0.0
    electricityFansCooling = 0.0
    electricityPumpsHeating = 0.0
    electricityPumpsCooling = 0.0
    electricityWaterSystems = 0.0
    naturalGasTotalEndUses = 0.0
    naturalGasHeating = 0.0
    naturalGasInteriorEquipment = 0.0
    naturalGasWaterSystems = 0.0
    fuelOilTotalEndUses = 0.0
    fuelOilHeating = 0.0
    fuelOilInteriorEquipment = 0.0
    fuelOilWaterSystems = 0.0
    propaneTotalEndUses = 0.0
    propaneHeating = 0.0
    propaneInteriorEquipment = 0.0
    propaneWaterSystems = 0.0
    hoursHeatingSetpointNotMet = 0.0
    hoursCoolingSetpointNotMet = 0.0

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

      electricity_heating_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:ELECTRICITYHEATING') AND ReportingFrequency='Run Period' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
      unless sqlFile.execAndReturnFirstDouble(electricity_heating_query).empty?
        electricityHeating += units_represented * sqlFile.execAndReturnFirstDouble(electricity_heating_query).get.round(2)
      end

      centralElectricityHeating += units_represented * (modeledCentralElectricityHeating / units.length)

      electricity_cooling_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:ELECTRICITYCOOLING') AND ReportingFrequency='Run Period' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
      unless sqlFile.execAndReturnFirstDouble(electricity_cooling_query).empty?
        electricityCooling += units_represented * sqlFile.execAndReturnFirstDouble(electricity_cooling_query).get.round(2)
      end

      centralElectricityCooling += units_represented * (modeledCentralElectricityCooling / units.length)

      electricity_interior_lighting_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:ELECTRICITYINTERIORLIGHTING') AND ReportingFrequency='Run Period' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
      unless sqlFile.execAndReturnFirstDouble(electricity_interior_lighting_query).empty?
        electricityInteriorLighting += units_represented * sqlFile.execAndReturnFirstDouble(electricity_interior_lighting_query).get.round(2)
      end

      electricityExteriorLighting += units_represented * (modeledCentralElectricityExteriorLighting / units.length)

      electricity_interior_equipment_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:ELECTRICITYINTERIOREQUIPMENT') AND ReportingFrequency='Run Period' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
      unless sqlFile.execAndReturnFirstDouble(electricity_interior_equipment_query).empty?
        electricityInteriorEquipment += units_represented * sqlFile.execAndReturnFirstDouble(electricity_interior_equipment_query).get.round(2)
      end
      electricityInteriorEquipment += units_represented * (modeledCentralElectricityInteriorEquipment / units.length)

      electricity_fans_heating_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:ELECTRICITYFANSHEATING') AND ReportingFrequency='Run Period' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
      unless sqlFile.execAndReturnFirstDouble(electricity_fans_heating_query).empty?
        electricityFansHeating += units_represented * sqlFile.execAndReturnFirstDouble(electricity_fans_heating_query).get.round(2)
        modeledElectricityFansHeating += sqlFile.execAndReturnFirstDouble(electricity_fans_heating_query).get.round(2)
      end

      electricity_fans_cooling_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:ELECTRICITYFANSCOOLING') AND ReportingFrequency='Run Period' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
      unless sqlFile.execAndReturnFirstDouble(electricity_fans_cooling_query).empty?
        electricityFansCooling += units_represented * sqlFile.execAndReturnFirstDouble(electricity_fans_cooling_query).get.round(2)
        modeledElectricityFansCooling += sqlFile.execAndReturnFirstDouble(electricity_fans_cooling_query).get.round(2)
      end

      electricity_pumps_heating_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:ELECTRICITYPUMPSHEATING') AND ReportingFrequency='Run Period' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
      unless sqlFile.execAndReturnFirstDouble(electricity_pumps_heating_query).empty?
        electricityPumpsHeating += units_represented * sqlFile.execAndReturnFirstDouble(electricity_pumps_heating_query).get.round(2)
        modeledElectricityPumpsHeating += sqlFile.execAndReturnFirstDouble(electricity_pumps_heating_query).get.round(2)
      end

      centralElectricityPumpsHeating += units_represented * (modeledCentralElectricityPumpsHeating / units.length)

      electricity_pumps_cooling_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:ELECTRICITYPUMPSCOOLING') AND ReportingFrequency='Run Period' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
      unless sqlFile.execAndReturnFirstDouble(electricity_pumps_cooling_query).empty?
        electricityPumpsCooling += units_represented * sqlFile.execAndReturnFirstDouble(electricity_pumps_cooling_query).get.round(2)
        modeledElectricityPumpsCooling += sqlFile.execAndReturnFirstDouble(electricity_pumps_cooling_query).get.round(2)
      end

      centralElectricityPumpsCooling += units_represented * (modeledCentralElectricityPumpsCooling / units.length)

      electricity_water_systems_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:ELECTRICITYWATERSYSTEMS') AND ReportingFrequency='Run Period' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
      unless sqlFile.execAndReturnFirstDouble(electricity_water_systems_query).empty?
        electricityWaterSystems += units_represented * sqlFile.execAndReturnFirstDouble(electricity_water_systems_query).get.round(2)
      end

      natural_gas_heating_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:NATURALGASHEATING') AND ReportingFrequency='Run Period' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
      unless sqlFile.execAndReturnFirstDouble(natural_gas_heating_query).empty?
        naturalGasHeating += units_represented * sqlFile.execAndReturnFirstDouble(natural_gas_heating_query).get.round(2)
      end

      centralNaturalGasHeating += units_represented * (modeledCentralNaturalGasHeating / units.length)

      natural_gas_interior_equipment_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:NATURALGASINTERIOREQUIPMENT') AND ReportingFrequency='Run Period' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
      unless sqlFile.execAndReturnFirstDouble(natural_gas_interior_equipment_query).empty?
        naturalGasInteriorEquipment += units_represented * sqlFile.execAndReturnFirstDouble(natural_gas_interior_equipment_query).get.round(2)
      end
      naturalGasInteriorEquipment += units_represented * (modeledCentralNaturalGasInteriorEquipment / units.length)

      natural_gas_water_systems_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:NATURALGASWATERSYSTEMS') AND ReportingFrequency='Run Period' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
      unless sqlFile.execAndReturnFirstDouble(natural_gas_water_systems_query).empty?
        naturalGasWaterSystems += units_represented * sqlFile.execAndReturnFirstDouble(natural_gas_water_systems_query).get.round(2)
      end

      fuel_oil_heating_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:FUELOILHEATING') AND ReportingFrequency='Run Period' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
      unless sqlFile.execAndReturnFirstDouble(fuel_oil_heating_query).empty?
        fuelOilHeating += units_represented * sqlFile.execAndReturnFirstDouble(fuel_oil_heating_query).get.round(2)
      end

      centralFuelOilHeating += units_represented * (modeledCentralFuelOilHeating / units.length)

      fuel_oil_interior_equipment_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:FUELOILINTERIOREQUIPMENT') AND ReportingFrequency='Run Period' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
      unless sqlFile.execAndReturnFirstDouble(fuel_oil_interior_equipment_query).empty?
        fuelOilInteriorEquipment += units_represented * sqlFile.execAndReturnFirstDouble(fuel_oil_interior_equipment_query).get.round(2)
      end
      fuelOilInteriorEquipment += units_represented * (modeledCentralFuelOilInteriorEquipment / units.length)

      fuel_oil_water_systems_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:FUELOILWATERSYSTEMS') AND ReportingFrequency='Run Period' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
      unless sqlFile.execAndReturnFirstDouble(fuel_oil_water_systems_query).empty?
        fuelOilWaterSystems += units_represented * sqlFile.execAndReturnFirstDouble(fuel_oil_water_systems_query).get.round(2)
      end

      propane_heating_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:PROPANEHEATING') AND ReportingFrequency='Run Period' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
      unless sqlFile.execAndReturnFirstDouble(propane_heating_query).empty?
        propaneHeating += units_represented * sqlFile.execAndReturnFirstDouble(propane_heating_query).get.round(2)
      end

      centralPropaneHeating += units_represented * (modeledCentralPropaneHeating / units.length)

      propane_interior_equipment_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:PROPANEINTERIOREQUIPMENT') AND ReportingFrequency='Run Period' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
      unless sqlFile.execAndReturnFirstDouble(propane_interior_equipment_query).empty?
        propaneInteriorEquipment += units_represented * sqlFile.execAndReturnFirstDouble(propane_interior_equipment_query).get.round(2)
      end
      propaneInteriorEquipment += units_represented * (modeledCentralPropaneInteriorEquipment / units.length)

      propane_water_systems_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:PROPANEWATERSYSTEMS') AND ReportingFrequency='Run Period' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
      unless sqlFile.execAndReturnFirstDouble(propane_water_systems_query).empty?
        propaneWaterSystems += units_represented * sqlFile.execAndReturnFirstDouble(propane_water_systems_query).get.round(2)
      end

      thermal_zones.each do |thermal_zone|
        thermal_zone_name = thermal_zone.name.to_s.upcase
        hours_heating_setpoint_not_met_query = "SELECT Value FROM TabularDataWithStrings WHERE (ReportName='SystemSummary') AND (ReportForString='Entire Facility') AND (TableName='Time Setpoint Not Met') AND (RowName = '#{thermal_zone_name}') AND (ColumnName='During Heating') AND (Units = 'hr')"
        unless sqlFile.execAndReturnFirstDouble(hours_heating_setpoint_not_met_query).empty?
          hoursHeatingSetpointNotMet += units_represented * sqlFile.execAndReturnFirstDouble(hours_heating_setpoint_not_met_query).get
        end

        hours_cooling_setpoint_not_met_query = "SELECT Value FROM TabularDataWithStrings WHERE (ReportName='SystemSummary') AND (ReportForString='Entire Facility') AND (TableName='Time Setpoint Not Met') AND (RowName = '#{thermal_zone_name}') AND (ColumnName='During Cooling') AND (Units = 'hr')"
        unless sqlFile.execAndReturnFirstDouble(hours_cooling_setpoint_not_met_query).empty?
          hoursCoolingSetpointNotMet += units_represented * sqlFile.execAndReturnFirstDouble(hours_cooling_setpoint_not_met_query).get
        end
      end
    end

    # ELECTRICITY

    # Get PV electricity produced
    pv_query = "SELECT -1*Value FROM TabularDataWithStrings WHERE ReportName='AnnualBuildingUtilityPerformanceSummary' AND ReportForString='Entire Facility' AND TableName='Electric Loads Satisfied' AND RowName='Total On-Site Electric Sources' AND ColumnName='Electricity' AND Units='GJ'"
    pv_val = 0.0
    unless sqlFile.execAndReturnFirstDouble(pv_query).empty?
      pv_val = sqlFile.execAndReturnFirstDouble(pv_query).get
    end
    report_sim_output(runner, "electricity_pv_kwh", pv_val, "GJ", elec_site_units)

    electricityTotalEndUses = electricityHeating + centralElectricityHeating + electricityCooling + centralElectricityCooling + electricityInteriorLighting + electricityExteriorLighting + electricityExteriorHolidayLighting + electricityInteriorEquipment + electricityFansHeating + electricityFansCooling + electricityPumpsHeating + centralElectricityPumpsHeating + electricityPumpsCooling + centralElectricityPumpsCooling + electricityWaterSystems

    report_sim_output(runner, "total_site_electricity_kwh", electricityTotalEndUses, "GJ", elec_site_units)
    report_sim_output(runner, "net_site_electricity_kwh", electricityTotalEndUses + pv_val, "GJ", elec_site_units)
    report_sim_output(runner, "electricity_heating_kwh", electricityHeating, "GJ", elec_site_units)
    report_sim_output(runner, "electricity_central_system_heating_kwh", centralElectricityHeating, "GJ", elec_site_units)
    report_sim_output(runner, "electricity_cooling_kwh", electricityCooling, "GJ", elec_site_units)
    report_sim_output(runner, "electricity_central_system_cooling_kwh", centralElectricityCooling, "GJ", elec_site_units)
    report_sim_output(runner, "electricity_interior_lighting_kwh", electricityInteriorLighting, "GJ", elec_site_units)
    report_sim_output(runner, "electricity_exterior_lighting_kwh", electricityExteriorLighting + electricityExteriorHolidayLighting, "GJ", elec_site_units)
    report_sim_output(runner, "electricity_interior_equipment_kwh", electricityInteriorEquipment, "GJ", elec_site_units)
    electricityFans = 0.0
    unless sqlFile.electricityFans.empty?
      electricityFans = sqlFile.electricityFans.get
    end
    err = (modeledElectricityFansHeating + modeledElectricityFansCooling) - electricityFans
    if err.abs > 0.2
      runner.registerError("Disaggregated fan energy (#{modeledElectricityFansHeating + modeledElectricityFansCooling} GJ) relative to building fan energy (#{electricityFans} GJ): #{err} GJ.")
      return false
    end
    report_sim_output(runner, "electricity_fans_heating_kwh", electricityFansHeating, "GJ", elec_site_units)
    report_sim_output(runner, "electricity_fans_cooling_kwh", electricityFansCooling, "GJ", elec_site_units)
    electricityPumps = 0.0
    unless sqlFile.electricityPumps.empty?
      electricityPumps = sqlFile.electricityPumps.get
    end
    err = (modeledElectricityPumpsHeating + modeledElectricityPumpsCooling) - electricityPumps
    if err.abs > 0.2
      runner.registerError("Disaggregated pump energy (#{modeledElectricityPumpsHeating + modeledElectricityPumpsCooling} GJ) relative to building pump energy (#{electricityPumps} GJ): #{err} GJ.")
      return false
    end
    report_sim_output(runner, "electricity_pumps_heating_kwh", electricityPumpsHeating, "GJ", elec_site_units)
    report_sim_output(runner, "electricity_central_system_pumps_heating_kwh", centralElectricityPumpsHeating, "GJ", elec_site_units)
    report_sim_output(runner, "electricity_pumps_cooling_kwh", electricityPumpsCooling, "GJ", elec_site_units)
    report_sim_output(runner, "electricity_central_system_pumps_cooling_kwh", centralElectricityPumpsCooling, "GJ", elec_site_units)
    report_sim_output(runner, "electricity_water_systems_kwh", electricityWaterSystems, "GJ", elec_site_units)

    # NATURAL GAS

    naturalGasTotalEndUses = naturalGasHeating + centralNaturalGasHeating + naturalGasInteriorEquipment + naturalGasWaterSystems

    report_sim_output(runner, "total_site_natural_gas_therm", naturalGasTotalEndUses, "GJ", gas_site_units)
    report_sim_output(runner, "natural_gas_heating_therm", naturalGasHeating, "GJ", gas_site_units)
    report_sim_output(runner, "natural_gas_central_system_heating_therm", centralNaturalGasHeating, "GJ", gas_site_units)
    report_sim_output(runner, "natural_gas_interior_equipment_therm", naturalGasInteriorEquipment, "GJ", gas_site_units)
    report_sim_output(runner, "natural_gas_water_systems_therm", naturalGasWaterSystems, "GJ", gas_site_units)

    # FUEL OIL

    fuelOilTotalEndUses = fuelOilHeating + centralFuelOilHeating + fuelOilInteriorEquipment + fuelOilWaterSystems

    report_sim_output(runner, "total_site_fuel_oil_mbtu", fuelOilTotalEndUses, "GJ", other_fuel_site_units)
    report_sim_output(runner, "fuel_oil_heating_mbtu", fuelOilHeating, "GJ", other_fuel_site_units)
    report_sim_output(runner, "fuel_oil_central_system_heating_mbtu", centralFuelOilHeating, "GJ", other_fuel_site_units)
    report_sim_output(runner, "fuel_oil_interior_equipment_mbtu", fuelOilInteriorEquipment, "GJ", other_fuel_site_units)
    report_sim_output(runner, "fuel_oil_water_systems_mbtu", fuelOilWaterSystems, "GJ", other_fuel_site_units)

    # PROPANE

    propaneTotalEndUses = propaneHeating + centralPropaneHeating + propaneInteriorEquipment + propaneWaterSystems

    report_sim_output(runner, "total_site_propane_mbtu", propaneTotalEndUses, "GJ", other_fuel_site_units)
    report_sim_output(runner, "propane_heating_mbtu", propaneHeating, "GJ", other_fuel_site_units)
    report_sim_output(runner, "propane_central_system_heating_mbtu", centralPropaneHeating, "GJ", other_fuel_site_units)
    report_sim_output(runner, "propane_interior_equipment_mbtu", propaneInteriorEquipment, "GJ", other_fuel_site_units)
    report_sim_output(runner, "propane_water_systems_mbtu", propaneWaterSystems, "GJ", other_fuel_site_units)

    # TOTAL

    totalSiteEnergy = electricityTotalEndUses + naturalGasTotalEndUses + fuelOilTotalEndUses + propaneTotalEndUses

    if units.length == total_units_represented
      err = totalSiteEnergy - sqlFile.totalSiteEnergy.get
      if err.abs > 0.5
        runner.registerError("Disaggregated total site energy (#{totalSiteEnergy} GJ) relative to building total site energy (#{sqlFile.totalSiteEnergy.get} GJ): #{err} GJ.")
        return false
      end
    end
    report_sim_output(runner, "total_site_energy_mbtu", totalSiteEnergy, "GJ", total_site_units)
    report_sim_output(runner, "net_site_energy_mbtu", totalSiteEnergy + pv_val, "GJ", total_site_units)

    # LOADS NOT MET

    report_sim_output(runner, "hours_heating_setpoint_not_met", hoursHeatingSetpointNotMet, nil, nil)
    report_sim_output(runner, "hours_cooling_setpoint_not_met", hoursCoolingSetpointNotMet, nil, nil)

    # HVAC CAPACITIES

    hvac_cooling_capacity_kbtuh = get_cost_multiplier("Size, Cooling System (kBtu/h)", model, runner)
    return false if hvac_cooling_capacity_kbtuh.nil?

    report_sim_output(runner, "hvac_cooling_capacity_w", hvac_cooling_capacity_kbtuh, "kBtu/hr", "W")

    hvac_heating_capacity_kbtuh = get_cost_multiplier("Size, Heating System (kBtu/h)", model, runner)
    return false if hvac_heating_capacity_kbtuh.nil?

    report_sim_output(runner, "hvac_heating_capacity_w", hvac_heating_capacity_kbtuh, "kBtu/hr", "W")

    hvac_heating_supp_capacity_kbtuh = get_cost_multiplier("Size, Heating Supplemental System (kBtu/h)", model, runner)
    return false if hvac_heating_supp_capacity_kbtuh.nil?

    report_sim_output(runner, "hvac_heating_supp_capacity_w", hvac_heating_supp_capacity_kbtuh, "kBtu/hr", "W")

    sqlFile.close()

    # WEIGHT

    weight = get_value_from_runner_past_results(runner, "weight", "build_existing_model", false)
    if not weight.nil?
      register_value(runner, "weight", weight.to_f)
      runner.registerInfo("Registering #{weight} for weight.")
    end

    # Report cost multipliers
    cost_mult_types.each do |cost_mult_type, cost_mult_type_str|
      cost_mult = get_cost_multiplier(cost_mult_type, model, runner)
      cost_mult = cost_mult.round(2)
      register_value(runner, cost_mult_type_str, cost_mult)
    end

    # UPGRADE NAME
    upgrade_name = get_value_from_runner_past_results(runner, "upgrade_name", "apply_upgrade", false)
    if upgrade_name.nil?
      upgrade_name = "(blank)"
    end
    register_value(runner, "upgrade_name", upgrade_name)
    runner.registerInfo("Registering #{upgrade_name} for upgrade_name.")

    # UPGRADE COSTS

    upgrade_cost_name = "upgrade_cost_usd"

    # Get upgrade cost value/multiplier pairs and lifetimes from the upgrade measure
    has_costs = false
    option_cost_pairs = {}
    option_lifetimes = {}
    for option_num in 1..num_options # Sync with ApplyUpgrade measure
      option_cost_pairs[option_num] = []
      option_lifetimes[option_num] = nil
      for cost_num in 1..num_costs_per_option # Sync with ApplyUpgrade measure
        cost_value = get_value_from_runner_past_results(runner, "option_%02d_cost_#{cost_num}_value_to_apply" % option_num, "apply_upgrade", false)
        next if cost_value.nil?

        cost_mult_type = get_value_from_runner_past_results(runner, "option_%02d_cost_#{cost_num}_multiplier_to_apply" % option_num, "apply_upgrade", false)
        next if cost_mult_type.nil?

        has_costs = true
        option_cost_pairs[option_num] << [cost_value.to_f, cost_mult_type]
      end
      lifetime = get_value_from_runner_past_results(runner, "option_%02d_lifetime_to_apply" % option_num, "apply_upgrade", false)
      next if lifetime.nil?

      option_lifetimes[option_num] = lifetime.to_f
    end

    if not has_costs
      register_value(runner, upgrade_cost_name, "")
      runner.registerInfo("Registering (blank) for #{upgrade_cost_name}.")
      return true
    end

    # Obtain cost multiplier values and calculate upgrade costs
    upgrade_cost = 0.0
    option_cost_pairs.keys.each do |option_num|
      option_cost = 0.0
      option_cost_pairs[option_num].each do |cost_value, cost_mult_type|
        cost_mult = get_cost_multiplier(cost_mult_type, model, runner)
        total_cost = cost_value * cost_mult
        next if total_cost == 0

        option_cost += total_cost
        runner.registerInfo("Upgrade cost addition: $#{cost_value} x #{cost_mult} [#{cost_mult_type}] = #{total_cost}.")
      end
      upgrade_cost += option_cost

      # Save option cost/lifetime to results.csv
      if option_cost != 0
        option_cost = option_cost.round(2)
        option_cost_name = "option_%02d_cost_usd" % option_num
        register_value(runner, option_cost_name, option_cost)
        runner.registerInfo("Registering #{option_cost} for #{option_cost_name}.")
        if not option_lifetimes[option_num].nil? and option_lifetimes[option_num] != 0
          lifetime = option_lifetimes[option_num].round(2)
          option_lifetime_name = "option_%02d_lifetime_yrs" % option_num
          register_value(runner, option_lifetime_name, lifetime)
          runner.registerInfo("Registering #{lifetime} for #{option_lifetime_name}.")
        end
      end
    end
    upgrade_cost = upgrade_cost.round(2)
    register_value(runner, upgrade_cost_name, upgrade_cost)
    runner.registerInfo("Registering #{upgrade_cost} for #{upgrade_cost_name}.")

    runner.registerFinalCondition("Report generated successfully.")

    return true
  end # end the run method

  def report_sim_output(runner, name, total_val, os_units, desired_units, percent_of_val = 1.0)
    total_val = total_val * percent_of_val
    if os_units.nil? or desired_units.nil? or os_units == desired_units
      valInUnits = total_val
    else
      valInUnits = UnitConversions.convert(total_val, os_units, desired_units)
    end
    runner.registerValue(name, valInUnits)
    runner.registerInfo("Registering #{valInUnits.round(2)} for #{name}.")
  end

  def get_cost_multiplier(cost_mult_type, model, runner)
    # Get building units
    units = Geometry.get_building_units(model, runner)
    if units.nil?
      return false
    end

    total_cost_mult = 0.0
    units.each do |unit|
      next if unit.spaces.empty?

      units_represented = 1
      if unit.additionalProperties.getFeatureAsInteger("Units Represented").is_initialized
        units_represented = unit.additionalProperties.getFeatureAsInteger("Units Represented").get
      end

      cost_mult = 0.0
      if cost_mult_type == "Fixed (1)"
        cost_mult += 1.0

      elsif cost_mult_type == "Duct Surface Area (ft^2)"
        # Duct supply+return surface area
        supply_area = unit.getFeatureAsDouble("SizingInfoDuctsSupplySurfaceArea")
        if supply_area.is_initialized
          cost_mult += supply_area.get
        end
        return_area = unit.getFeatureAsDouble("SizingInfoDuctsReturnSurfaceArea")
        if return_area.is_initialized
          cost_mult += return_area.get
        end

      end

      zones = []
      unit.spaces.each do |space|
        zone = space.thermalZone.get
        next unless zone.thermostat.is_initialized

        unless zones.include? zone
          zones << zone
        end
      end

      components = []
      zones.each do |zone|
        if cost_mult_type == "Size, Heating System (kBtu/h)"
          # Heating system capacity

          # Unit heater?
          zone.equipment.each do |equipment|
            next unless equipment.to_AirLoopHVACUnitarySystem.is_initialized

            sys = equipment.to_AirLoopHVACUnitarySystem.get
            next if zone != sys.controllingZoneorThermostatLocation.get
            next if not sys.heatingCoil.is_initialized

            component = sys.heatingCoil.get
            next if components.include? component

            components << component

            next if not component.to_CoilHeatingGas.is_initialized

            coil = component.to_CoilHeatingGas.get
            next if not coil.nominalCapacity.is_initialized

            cost_mult += UnitConversions.convert(coil.nominalCapacity.get, "W", "kBtu/hr")
          end

          # Unitary system?
          model.getAirLoopHVACUnitarySystems.each do |sys|
            next if zone != sys.controllingZoneorThermostatLocation.get
            next if not sys.heatingCoil.is_initialized

            component = sys.heatingCoil.get
            next if components.include? component

            components << component

            if component.to_CoilHeatingDXSingleSpeed.is_initialized
              coil = component.to_CoilHeatingDXSingleSpeed.get
              if coil.ratedTotalHeatingCapacity.is_initialized
                cost_mult += UnitConversions.convert(coil.ratedTotalHeatingCapacity.get, "W", "kBtu/hr")
              end
            elsif component.to_CoilHeatingDXMultiSpeed.is_initialized
              coil = component.to_CoilHeatingDXMultiSpeed.get
              if coil.stages.size > 0
                stage = coil.stages[coil.stages.size - 1]
                capacity_ratio = get_highest_stage_capacity_ratio(model, "SizingInfoHVACCapacityRatioCooling")
                if stage.grossRatedHeatingCapacity.is_initialized
                  cost_mult += UnitConversions.convert(stage.grossRatedHeatingCapacity.get / capacity_ratio, "W", "kBtu/hr")
                end
              end
            elsif component.to_CoilHeatingGas.is_initialized
              coil = component.to_CoilHeatingGas.get
              if coil.nominalCapacity.is_initialized
                cost_mult += UnitConversions.convert(coil.nominalCapacity.get, "W", "kBtu/hr")
              end
            elsif component.to_CoilHeatingElectric.is_initialized
              coil = component.to_CoilHeatingElectric.get
              if coil.nominalCapacity.is_initialized
                cost_mult += UnitConversions.convert(coil.nominalCapacity.get, "W", "kBtu/hr")
              end
            elsif component.to_CoilHeatingWaterToAirHeatPumpEquationFit.is_initialized
              coil = component.to_CoilHeatingWaterToAirHeatPumpEquationFit.get
              if coil.ratedHeatingCapacity.is_initialized
                cost_mult += UnitConversions.convert(coil.ratedHeatingCapacity.get, "W", "kBtu/hr")
              end
            end
          end

          # Electric baseboard?
          max_value = 0.0
          model.getZoneHVACBaseboardConvectiveElectrics.each do |sys|
            next if zone != sys.thermalZone.get

            component = sys
            next if components.include? component

            components << component
            next if not component.nominalCapacity.is_initialized

            cost_mult += UnitConversions.convert(component.nominalCapacity.get, "W", "kBtu/hr")
          end

          # Boiler?
          max_value = 0.0
          model.getPlantLoops.each do |pl|
            pl.components.each do |plc|
              next if not plc.to_BoilerHotWater.is_initialized

              component = plc.to_BoilerHotWater.get
              next if components.include? component

              components << component
              next if not component.nominalCapacity.is_initialized
              next if component.nominalCapacity.get <= max_value

              max_value = component.nominalCapacity.get
              cost_mult += UnitConversions.convert(max_value, "W", "kBtu/hr")
            end
          end

        elsif cost_mult_type == "Size, Heating Supplemental System (kBtu/h)"
          # Supplemental heating system capacity

          # Unitary system?
          model.getAirLoopHVACUnitarySystems.each do |sys|
            next if zone != sys.controllingZoneorThermostatLocation.get
            next if not sys.supplementalHeatingCoil.is_initialized

            component = sys.supplementalHeatingCoil.get
            next if components.include? component

            components << component

            if component.to_CoilHeatingElectric.is_initialized
              coil = component.to_CoilHeatingElectric.get
              if coil.nominalCapacity.is_initialized
                cost_mult += UnitConversions.convert(coil.nominalCapacity.get, "W", "kBtu/hr")
              end
            end
          end

        elsif cost_mult_type == "Size, Cooling System (kBtu/h)"
          # Cooling system capacity

          # Unitary system?
          model.getAirLoopHVACUnitarySystems.each do |sys|
            next if zone != sys.controllingZoneorThermostatLocation.get
            next if not sys.coolingCoil.is_initialized

            component = sys.coolingCoil.get
            next if components.include? component

            components << component

            if component.to_CoilCoolingDXSingleSpeed.is_initialized
              coil = component.to_CoilCoolingDXSingleSpeed.get
              if coil.ratedTotalCoolingCapacity.is_initialized
                cost_mult += UnitConversions.convert(coil.ratedTotalCoolingCapacity.get, "W", "kBtu/hr")
              end
            elsif component.to_CoilCoolingDXMultiSpeed.is_initialized
              coil = component.to_CoilCoolingDXMultiSpeed.get
              if coil.stages.size > 0
                stage = coil.stages[coil.stages.size - 1]
                capacity_ratio = get_highest_stage_capacity_ratio(model, "SizingInfoHVACCapacityRatioCooling")
                if stage.grossRatedTotalCoolingCapacity.is_initialized
                  cost_mult += UnitConversions.convert(stage.grossRatedTotalCoolingCapacity.get / capacity_ratio, "W", "kBtu/hr")
                end
              end
            elsif component.to_CoilCoolingWaterToAirHeatPumpEquationFit.is_initialized
              coil = component.to_CoilCoolingWaterToAirHeatPumpEquationFit.get
              if coil.ratedTotalCoolingCapacity.is_initialized
                cost_mult += UnitConversions.convert(coil.ratedTotalCoolingCapacity.get, "W", "kBtu/hr")
              end
            end
          end

          # PTAC?
          model.getZoneHVACPackagedTerminalAirConditioners.each do |sys|
            next if zone != sys.thermalZone.get

            component = sys.coolingCoil
            next if components.include? component

            components << component

            if not component.nil?
              if component.to_CoilCoolingDXSingleSpeed.is_initialized
                coil = component.to_CoilCoolingDXSingleSpeed.get
                if coil.ratedTotalCoolingCapacity.is_initialized
                  cost_mult += UnitConversions.convert(coil.ratedTotalCoolingCapacity.get, "W", "kBtu/hr")
                end
              end
            end
          end

        elsif cost_mult_type == "Size, Water Heater (gal)"
          # Water heater tank volume
          model.getWaterHeaterMixeds.each do |wh|
            next if Constants.ObjectNameWaterHeater(unit.name.to_s) != wh.name.to_s

            if wh.tankVolume.is_initialized
              volume = UnitConversions.convert(wh.tankVolume.get, "m^3", "gal")
              if volume >= 1.0 # skip tankless
                next if components.include? wh

                components << wh
                # FIXME: Remove actual->nominal size logic by storing nominal size in the OSM
                if wh.heaterFuelType.downcase == "electricity"
                  cost_mult += volume / 0.9
                else
                  cost_mult += volume / 0.95
                end
              end
            end
          end

          model.getWaterHeaterHeatPumpWrappedCondensers.each do |wh|
            next if "#{Constants.ObjectNameWaterHeater(unit.name.to_s.gsub("unit ", "")).gsub("|", "_")} hpwh" != wh.name.to_s

            if wh.to_WaterHeaterHeatPumpWrappedCondenser.is_initialized
              wh = wh.tank.to_WaterHeaterStratified.get
            end
            if wh.tankVolume.is_initialized
              volume = UnitConversions.convert(wh.tankVolume.get, "m^3", "gal")
              if volume >= 1.0 # skip tankless
                next if components.include? wh

                components << wh
                # FIXME: Remove actual->nominal size logic by storing nominal size in the OSM
                if wh.heaterFuelType.downcase == "electricity"
                  cost_mult += volume / 0.9
                else
                  cost_mult += volume / 0.95
                end
              end
            end
          end

        end
      end # zones

      unit.spaces.each do |space|
        if cost_mult_type == "Wall Area, Above-Grade, Conditioned (ft^2)"
          # Walls between conditioned space and 1) outdoors or 2) unconditioned space
          space.surfaces.each do |surface|
            next if surface.surfaceType.downcase != "wall"
            next if not surface.space.is_initialized
            next if not is_space_conditioned(surface.space.get)

            adjacent_space = get_adjacent_space(surface)
            if surface.outsideBoundaryCondition.downcase == "outdoors"
              cost_mult += UnitConversions.convert(surface.grossArea, "m^2", "ft^2")
            elsif !adjacent_space.nil? and not is_space_conditioned(adjacent_space)
              cost_mult += UnitConversions.convert(surface.grossArea, "m^2", "ft^2")
            end
          end

        elsif cost_mult_type == "Wall Area, Above-Grade, Exterior (ft^2)"
          # Walls adjacent to outdoors
          space.surfaces.each do |surface|
            next if surface.surfaceType.downcase != "wall"
            next if surface.outsideBoundaryCondition.downcase != "outdoors"

            cost_mult += UnitConversions.convert(surface.grossArea, "m^2", "ft^2")
          end

        elsif cost_mult_type == "Wall Area, Below-Grade (ft^2)"
          # Walls adjacent to ground
          space.surfaces.each do |surface|
            next if surface.surfaceType.downcase != "wall"
            next if surface.outsideBoundaryCondition.downcase != "ground" and surface.outsideBoundaryCondition.downcase != "foundation"

            cost_mult += UnitConversions.convert(surface.grossArea, "m^2", "ft^2")
          end

        elsif cost_mult_type == "Floor Area, Conditioned (ft^2)"
          # Floors of conditioned zone
          space.surfaces.each do |surface|
            next if surface.surfaceType.downcase != "floor"
            next if not surface.space.is_initialized
            next if not is_space_conditioned(surface.space.get)

            cost_mult += UnitConversions.convert(surface.grossArea, "m^2", "ft^2")
          end

        elsif cost_mult_type == "Floor Area, Attic (ft^2)"
          # Floors under sloped surfaces and above conditioned space
          space.surfaces.each do |surface|
            next if surface.surfaceType.downcase != "floor"
            next if not surface.space.is_initialized

            space = surface.space.get
            next if not has_sloped_roof_surfaces(space)

            adjacent_space = get_adjacent_space(surface)
            next if adjacent_space.nil?
            next if not is_space_conditioned(adjacent_space)

            cost_mult += UnitConversions.convert(surface.grossArea, "m^2", "ft^2")
          end

        elsif cost_mult_type == "Floor Area, Lighting (ft^2)"
          # Floors with lighting objects
          space.surfaces.each do |surface|
            next if surface.surfaceType.downcase != "floor"
            next if not surface.space.is_initialized
            next if surface.space.get.lights.size == 0

            cost_mult += UnitConversions.convert(surface.grossArea, "m^2", "ft^2")
          end

        elsif cost_mult_type == "Roof Area (ft^2)"
          # Roofs adjacent to outdoors
          space.surfaces.each do |surface|
            next if surface.surfaceType.downcase != "roofceiling"
            next if surface.outsideBoundaryCondition.downcase != "outdoors"

            cost_mult += UnitConversions.convert(surface.grossArea, "m^2", "ft^2")
          end

        elsif cost_mult_type == "Window Area (ft^2)"
          # Window subsurfaces
          space.surfaces.each do |surface|
            next if surface.surfaceType.downcase != "wall"

            surface.subSurfaces.each do |sub_surface|
              next if not sub_surface.subSurfaceType.downcase.include? "window"

              cost_mult += UnitConversions.convert(sub_surface.grossArea, "m^2", "ft^2")
            end
          end

        elsif cost_mult_type == "Door Area (ft^2)"
          # Door subsurfaces
          space.surfaces.each do |surface|
            next if surface.surfaceType.downcase != "wall"

            surface.subSurfaces.each do |sub_surface|
              next if not sub_surface.subSurfaceType.downcase.include? "door"

              cost_mult += UnitConversions.convert(sub_surface.grossArea, "m^2", "ft^2")
            end
          end

        end
      end # spaces

      cost_mult *= units_represented
      total_cost_mult += cost_mult
    end # units
    cost_mult = total_cost_mult

    total_units_represented = 0
    units.each do |unit|
      units_represented = 1
      if unit.additionalProperties.getFeatureAsInteger("Units Represented").is_initialized
        units_represented = unit.additionalProperties.getFeatureAsInteger("Units Represented").get
      end
      total_units_represented += units_represented
    end

    collapsed_factor = Float(total_units_represented) / units.length

    if cost_mult_type == "Wall Area, Above-Grade, Conditioned (ft^2)"
      # Walls between conditioned space and 1) outdoors or 2) unconditioned space
      model.getSurfaces.each do |surface|
        space = surface.space.get
        next if space.buildingUnit.is_initialized
        next if surface.surfaceType.downcase != "wall"
        next if not surface.space.is_initialized
        next if not is_space_conditioned(surface.space.get)

        adjacent_space = get_adjacent_space(surface)
        if surface.outsideBoundaryCondition.downcase == "outdoors"
          cost_mult += UnitConversions.convert(surface.grossArea, "m^2", "ft^2")
        elsif !adjacent_space.nil? and not is_space_conditioned(adjacent_space)
          cost_mult += UnitConversions.convert(surface.grossArea, "m^2", "ft^2")
        end
      end

    elsif cost_mult_type == "Wall Area, Above-Grade, Exterior (ft^2)"
      # Walls adjacent to outdoors
      model.getSurfaces.each do |surface|
        space = surface.space.get
        next if space.buildingUnit.is_initialized
        next if surface.surfaceType.downcase != "wall"
        next if surface.outsideBoundaryCondition.downcase != "outdoors"

        cost_mult += UnitConversions.convert(surface.grossArea, "m^2", "ft^2")
      end

    elsif cost_mult_type == "Wall Area, Below-Grade (ft^2)"
      # Walls adjacent to ground
      model.getSurfaces.each do |surface|
        space = surface.space.get
        next if space.buildingUnit.is_initialized
        next if surface.surfaceType.downcase != "wall"
        next if surface.outsideBoundaryCondition.downcase != "ground" and surface.outsideBoundaryCondition.downcase != "foundation"

        cost_mult += UnitConversions.convert(surface.grossArea, "m^2", "ft^2") * collapsed_factor
      end

    elsif cost_mult_type == "Floor Area, Conditioned (ft^2)"
      # Floors of conditioned zone
      model.getSurfaces.each do |surface|
        space = surface.space.get
        next if space.buildingUnit.is_initialized
        next if surface.surfaceType.downcase != "floor"
        next if not surface.space.is_initialized
        next if not is_space_conditioned(surface.space.get)

        cost_mult += UnitConversions.convert(surface.grossArea, "m^2", "ft^2")
      end

    elsif cost_mult_type == "Floor Area, Attic (ft^2)"
      # Floors under sloped surfaces and above conditioned space
      model.getSurfaces.each do |surface|
        space = surface.space.get
        next if space.buildingUnit.is_initialized
        next if surface.surfaceType.downcase != "floor"
        next if not surface.space.is_initialized

        space = surface.space.get
        next if not has_sloped_roof_surfaces(space)

        adjacent_space = get_adjacent_space(surface)
        next if adjacent_space.nil?
        next if not is_space_conditioned(adjacent_space)

        cost_mult += UnitConversions.convert(surface.grossArea, "m^2", "ft^2") * collapsed_factor
      end

    elsif cost_mult_type == "Floor Area, Lighting (ft^2)"
      # Floors with lighting objects
      model.getSurfaces.each do |surface|
        space = surface.space.get
        next if space.buildingUnit.is_initialized
        next if surface.surfaceType.downcase != "floor"
        next if not surface.space.is_initialized
        next if surface.space.get.lights.size == 0

        cost_mult += UnitConversions.convert(surface.grossArea, "m^2", "ft^2")
      end

    elsif cost_mult_type == "Roof Area (ft^2)"
      # Roofs adjacent to outdoors
      model.getSurfaces.each do |surface|
        space = surface.space.get
        next if space.buildingUnit.is_initialized
        next if surface.surfaceType.downcase != "roofceiling"
        next if surface.outsideBoundaryCondition.downcase != "outdoors"

        cost_mult += UnitConversions.convert(surface.grossArea, "m^2", "ft^2") * collapsed_factor
      end

    elsif cost_mult_type == "Window Area (ft^2)"
      # Window subsurfaces
      model.getSurfaces.each do |surface|
        space = surface.space.get
        next if space.buildingUnit.is_initialized
        next if surface.surfaceType.downcase != "wall"

        surface.subSurfaces.each do |sub_surface|
          next if not sub_surface.subSurfaceType.downcase.include? "window"

          cost_mult += UnitConversions.convert(sub_surface.grossArea, "m^2", "ft^2")
        end
      end

    elsif cost_mult_type == "Door Area (ft^2)"
      # Door subsurfaces
      model.getSurfaces.each do |surface|
        space = surface.space.get
        next if space.buildingUnit.is_initialized
        next if surface.surfaceType.downcase != "wall"

        surface.subSurfaces.each do |sub_surface|
          next if not sub_surface.subSurfaceType.downcase.include? "door"

          cost_mult += UnitConversions.convert(sub_surface.grossArea, "m^2", "ft^2")
        end
      end

    end

    return cost_mult
  end

  def get_adjacent_space(surface)
    return nil if not surface.adjacentSurface.is_initialized
    return nil if not surface.adjacentSurface.get.space.is_initialized

    return surface.adjacentSurface.get.space.get
  end

  def is_space_conditioned(adjacent_space)
    zone = adjacent_space.thermalZone.get
    if zone.thermostat.is_initialized
      return true
    end

    return false
  end

  def has_sloped_roof_surfaces(space)
    space.surfaces.each do |surface|
      next if surface.surfaceType.downcase != "roofceiling"
      next if surface.outsideBoundaryCondition.downcase != "outdoors"
      next if surface.tilt == 0

      return true
    end
    return false
  end

  def get_highest_stage_capacity_ratio(model, property_str)
    capacity_ratio = 1.0

    # Override capacity ratio for residential multispeed systems
    model.getAirLoopHVACUnitarySystems.each do |sys|
      capacity_ratio_str = sys.additionalProperties.getFeatureAsString(property_str)
      next if not capacity_ratio_str.is_initialized

      capacity_ratio = capacity_ratio_str.get.split(",").map(&:to_f)[-1]
    end

    return capacity_ratio
  end
end # end the measure

# this allows the measure to be use by the application
SimulationOutputReport.new.registerWithApplication
