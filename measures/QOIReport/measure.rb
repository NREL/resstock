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
require "enumerator"

# start the measure
class QOIReport < OpenStudio::Measure::ReportingMeasure
  # human readable name
  def name
    return "QOI Report"
  end

  # human readable description
  def description
    return "TODO"
  end

  # define the arguments that the user will input
  def arguments
    args = OpenStudio::Measure::OSArgumentVector.new

    return args
  end

  # return a vector of IdfObject's to request EnergyPlus objects needed by the run method
  # Warning: Do not change the name of this method to be snake_case. The method must be lowerCamelCase.
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

    results = OutputMeters.create_custom_building_unit_meters(model, runner, "Hourly")
    results << OpenStudio::IdfObject.load("Output:Meter,Electricity:Facility,Hourly;").get
    results << OpenStudio::IdfObject.load("Output:Variable,*,Site Outdoor Air Drybulb Temperature,Hourly;").get
    return results
  end

  def seasons
    return {
      "winter" => [-1e9, 55],
      "summer" => [70, 1e9],
      "shoulder" => [55, 70]
    }
  end

  def average_daily_base_magnitude_by_season
    output_names = []
    seasons.each do |season, temperature_range|
      output_names << "average_minimum_daily_use_#{season}_kw"
    end
    return output_names
  end

  def average_daily_peak_magnitude_by_season
    output_names = []
    seasons.each do |season, temperature_range|
      output_names << "average_maximum_daily_use_#{season}_kw"
    end
    return output_names
  end

  def average_daily_peak_timing_by_season
    output_names = []
    seasons.each do |season, temperature_range|
      output_names << "average_daily_peak_timing_#{season}_hour"
    end
    return output_names
  end

  def top_ten_daily_seasonal_peak_magnitude_by_season
    output_names = []
    seasons.each do |season, temperature_range|
      next if season == "shoulder"

      output_names << "average_of_top_ten_highest_peaks_#{season}_kw"
    end
    return output_names
  end

  def top_ten_seasonal_timing_of_peak_by_season
    output_names = []
    seasons.each do |season, temperature_range|
      next if season == "shoulder"

      output_names << "average_of_top_ten_highest_peaks_#{season}_hour"
    end
    return output_names
  end

  def outputs
    output_names = []
    output_names += average_daily_base_magnitude_by_season
    output_names += average_daily_peak_magnitude_by_season
    output_names += average_daily_peak_timing_by_season
    output_names += top_ten_daily_seasonal_peak_magnitude_by_season
    output_names += top_ten_seasonal_timing_of_peak_by_season

    result = OpenStudio::Measure::OSOutputVector.new
    output_names.each do |output|
      result << OpenStudio::Measure::OSOutput.makeDoubleOutput(output)
    end

    return result
  end

  # define what happens when the measure is run
  def run(runner, user_arguments)
    super(runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments, user_arguments)
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

    steps_per_hour = 6 # default OpenStudio timestep if none specified
    if model.getSimulationControl.timestep.is_initialized
      steps_per_hour = model.getSimulationControl.timestep.get.numberOfTimestepsPerHour
    end

    datetimes = []
    timeseries = sqlFile.timeSeries(ann_env_pd, "Hourly", "Electricity:Facility", "").get # assume every house consumes some electricity
    timeseries.dateTimes.each_with_index do |datetime, i|
      datetimes << format_datetime(datetime.to_s)
    end
    num_ts = datetimes.length

    temperature_query = "SELECT VariableValue FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex IN (SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE VariableType='Avg' AND VariableName IN ('Site Outdoor Air Drybulb Temperature') AND ReportingFrequency='Hourly' AND VariableUnits='C') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
    unless sqlFile.execAndReturnVectorOfDouble(temperature_query).get.empty?
      temperatures_c = sqlFile.execAndReturnVectorOfDouble(temperature_query).get
      temperatures = []
      temperatures_c.each do |val|
        temperatures << UnitConversions.convert(val, "C", "F")
      end
    end

    # Get the timestamps for actual year epw file, and the number of intervals per hour
    weather = WeatherProcess.new(model, runner)
    if weather.error?
      return false
    end

    actual_year_timestamps = weather.actual_year_timestamps("Hourly")

    # Initialize timeseries hash which will be exported to csv
    timeseries = { "Temperature" => temperatures }
    timeseries["Time"] = datetimes # timestamps from the sqlfile (TMY)
    unless actual_year_timestamps.empty?
      timeseries["Time"] = actual_year_timestamps # timestamps constructed using run period and Time class (AMY)
    end
    if timeseries["Time"].length != num_ts
      runner.registerError("The timestamps array length does not equal that of the sqlfile timeseries. You may be ignoring leap days in your AMY weather file.")
      return false
    end

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

    central_electricity_heating_query = "SELECT VariableValue FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('CENTRAL:ELECTRICITYHEATING') AND ReportingFrequency='Hourly' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
    unless sqlFile.execAndReturnVectorOfDouble(central_electricity_heating_query).get.empty?
      modeledCentralElectricityHeating = sqlFile.execAndReturnVectorOfDouble(central_electricity_heating_query).get
    end

    central_electricity_cooling_query = "SELECT VariableValue FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('CENTRAL:ELECTRICITYCOOLING') AND ReportingFrequency='Hourly' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
    unless sqlFile.execAndReturnVectorOfDouble(central_electricity_cooling_query).get.empty?
      modeledCentralElectricityCooling = sqlFile.execAndReturnVectorOfDouble(central_electricity_cooling_query).get
    end

    central_electricity_exterior_lighting_query = "SELECT VariableValue FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('CENTRAL:ELECTRICITYEXTERIORLIGHTING') AND ReportingFrequency='Hourly' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
    unless sqlFile.execAndReturnVectorOfDouble(central_electricity_exterior_lighting_query).get.empty?
      modeledCentralElectricityExteriorLighting = sqlFile.execAndReturnVectorOfDouble(central_electricity_exterior_lighting_query).get
    end

    central_electricity_exterior_holiday_lighting_query = "SELECT VariableValue FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('CENTRAL:ELECTRICITYEXTERIORHOLIDAYLIGHTING') AND ReportingFrequency='Hourly' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
    unless sqlFile.execAndReturnVectorOfDouble(central_electricity_exterior_holiday_lighting_query).get.empty?
      modeledCentralElectricityExteriorHolidayLighting = sqlFile.execAndReturnVectorOfDouble(central_electricity_exterior_holiday_lighting_query).get
    end

    central_electricity_pumps_heating_query = "SELECT VariableValue FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('CENTRAL:ELECTRICITYPUMPSHEATING') AND ReportingFrequency='Hourly' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
    unless sqlFile.execAndReturnVectorOfDouble(central_electricity_pumps_heating_query).get.empty?
      modeledCentralElectricityPumpsHeating = sqlFile.execAndReturnVectorOfDouble(central_electricity_pumps_heating_query).get
    end

    central_electricity_pumps_cooling_query = "SELECT VariableValue FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('CENTRAL:ELECTRICITYPUMPSCOOLING') AND ReportingFrequency='Hourly' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
    unless sqlFile.execAndReturnVectorOfDouble(central_electricity_pumps_cooling_query).get.empty?
      modeledCentralElectricityPumpsCooling = sqlFile.execAndReturnVectorOfDouble(central_electricity_pumps_cooling_query).get
    end

    central_electricity_interior_equipment_query = "SELECT VariableValue FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('CENTRAL:ELECTRICITYINTERIOREQUIPMENT') AND ReportingFrequency='Hourly' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
    unless sqlFile.execAndReturnVectorOfDouble(central_electricity_interior_equipment_query).get.empty?
      modeledCentralElectricityInteriorEquipment = sqlFile.execAndReturnVectorOfDouble(central_electricity_interior_equipment_query).get
    end

    central_electricity_photovoltaics_query = "SELECT VariableValue FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('CENTRAL:ELECTRICITYPHOTOVOLTAICS') AND ReportingFrequency='Hourly' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
    unless sqlFile.execAndReturnVectorOfDouble(central_electricity_photovoltaics_query).get.empty?
      modeledCentralElectricityPhotovoltaics = sqlFile.execAndReturnVectorOfDouble(central_electricity_photovoltaics_query).get
    end

    central_electricity_extra_refrigerator_query = "SELECT VariableValue FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('CENTRAL:ELECTRICITYEXTRAREFRIGERATOR') AND ReportingFrequency='Hourly' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
    unless sqlFile.execAndReturnVectorOfDouble(central_electricity_extra_refrigerator_query).get.empty?
      modeledCentralElectricityExtraRefrigerator = sqlFile.execAndReturnVectorOfDouble(central_electricity_extra_refrigerator_query).get
    end

    central_electricity_freezer_query = "SELECT VariableValue FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('CENTRAL:ELECTRICITYFREEZER') AND ReportingFrequency='Hourly' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
    unless sqlFile.execAndReturnVectorOfDouble(central_electricity_freezer_query).get.empty?
      modeledCentralElectricityFreezer = sqlFile.execAndReturnVectorOfDouble(central_electricity_freezer_query).get
    end

    central_electricity_garage_lighting_query = "SELECT VariableValue FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('CENTRAL:ELECTRICITYGARAGELIGHTING') AND ReportingFrequency='Hourly' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
    unless sqlFile.execAndReturnVectorOfDouble(central_electricity_garage_lighting_query).get.empty?
      modeledCentralElectricityGarageLighting = sqlFile.execAndReturnVectorOfDouble(central_electricity_garage_lighting_query).get
    end

    centralElectricityHeating = [0] * num_ts
    centralElectricityCooling = [0] * num_ts
    centralElectricityPumpsHeating = [0] * num_ts
    centralElectricityPumpsCooling = [0] * num_ts

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

      electricity_heating_query = "SELECT VariableValue FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:ELECTRICITYHEATING') AND ReportingFrequency='Hourly' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
      unless sqlFile.execAndReturnVectorOfDouble(electricity_heating_query).get.empty?
        electricityHeating = array_sum(electricityHeating, sqlFile.execAndReturnVectorOfDouble(electricity_heating_query).get, units_represented)
      end

      centralElectricityHeating = array_sum(centralElectricityHeating, modeledCentralElectricityHeating, units_represented, units.length)

      electricity_cooling_query = "SELECT VariableValue FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:ELECTRICITYCOOLING') AND ReportingFrequency='Hourly' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
      unless sqlFile.execAndReturnVectorOfDouble(electricity_cooling_query).get.empty?
        electricityCooling = array_sum(electricityCooling, sqlFile.execAndReturnVectorOfDouble(electricity_cooling_query).get, units_represented)
      end

      centralElectricityCooling = array_sum(centralElectricityCooling, modeledCentralElectricityCooling, units_represented, units.length)

      electricity_interior_lighting_query = "SELECT VariableValue FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:ELECTRICITYINTERIORLIGHTING') AND ReportingFrequency='Hourly' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
      unless sqlFile.execAndReturnVectorOfDouble(electricity_interior_lighting_query).get.empty?
        electricityInteriorLighting = array_sum(electricityInteriorLighting, sqlFile.execAndReturnVectorOfDouble(electricity_interior_lighting_query).get, units_represented)
      end

      electricityExteriorLighting = array_sum(electricityExteriorLighting, modeledCentralElectricityExteriorLighting, units_represented, units.length)

      electricity_interior_equipment_query = "SELECT VariableValue FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:ELECTRICITYINTERIOREQUIPMENT') AND ReportingFrequency='Hourly' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
      unless sqlFile.execAndReturnVectorOfDouble(electricity_interior_equipment_query).get.empty?
        electricityInteriorEquipment = array_sum(electricityInteriorEquipment, sqlFile.execAndReturnVectorOfDouble(electricity_interior_equipment_query).get, units_represented)
      end
      electricityInteriorEquipment = array_sum(electricityInteriorEquipment, modeledCentralElectricityInteriorEquipment, units_represented, units.length)

      electricity_fans_heating_query = "SELECT VariableValue FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:ELECTRICITYFANSHEATING') AND ReportingFrequency='Hourly' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
      unless sqlFile.execAndReturnVectorOfDouble(electricity_fans_heating_query).get.empty?
        electricityFansHeating = array_sum(electricityFansHeating, sqlFile.execAndReturnVectorOfDouble(electricity_fans_heating_query).get, units_represented)
      end

      electricity_fans_cooling_query = "SELECT VariableValue FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:ELECTRICITYFANSCOOLING') AND ReportingFrequency='Hourly' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
      unless sqlFile.execAndReturnVectorOfDouble(electricity_fans_cooling_query).get.empty?
        electricityFansCooling = array_sum(electricityFansCooling, sqlFile.execAndReturnVectorOfDouble(electricity_fans_cooling_query).get, units_represented)
      end

      electricity_pumps_heating_query = "SELECT VariableValue FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:ELECTRICITYPUMPSHEATING') AND ReportingFrequency='Hourly' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
      unless sqlFile.execAndReturnVectorOfDouble(electricity_pumps_heating_query).get.empty?
        electricityPumpsHeating = array_sum(electricityPumpsHeating, sqlFile.execAndReturnVectorOfDouble(electricity_pumps_heating_query).get, units_represented)
      end

      centralElectricityPumpsHeating = array_sum(centralElectricityPumpsHeating, modeledCentralElectricityPumpsHeating, units_represented, units.length)

      electricity_pumps_cooling_query = "SELECT VariableValue FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:ELECTRICITYPUMPSCOOLING') AND ReportingFrequency='Hourly' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
      unless sqlFile.execAndReturnVectorOfDouble(electricity_pumps_cooling_query).get.empty?
        electricityPumpsCooling = array_sum(electricityPumpsCooling, sqlFile.execAndReturnVectorOfDouble(electricity_pumps_cooling_query).get, units_represented)
      end

      centralElectricityPumpsCooling = array_sum(centralElectricityPumpsCooling, modeledCentralElectricityPumpsCooling, units_represented, units.length)

      electricity_water_systems_query = "SELECT VariableValue FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:ELECTRICITYWATERSYSTEMS') AND ReportingFrequency='Hourly' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
      unless sqlFile.execAndReturnVectorOfDouble(electricity_water_systems_query).get.empty?
        electricityWaterSystems = array_sum(electricityWaterSystems, sqlFile.execAndReturnVectorOfDouble(electricity_water_systems_query).get, units_represented)
      end
    end

    # ELECTRICITY

    electricityTotalEndUses = [electricityHeating, centralElectricityHeating, electricityCooling, centralElectricityCooling, electricityInteriorLighting, electricityExteriorLighting, electricityExteriorHolidayLighting, electricityInteriorEquipment, electricityFansHeating, electricityFansCooling, electricityPumpsHeating, centralElectricityPumpsHeating, electricityPumpsCooling, centralElectricityPumpsCooling, electricityWaterSystems].transpose.map { |e| e.reduce(:+) }

    timeseries["total_site_electricity_kw"] = []
    timeseries["Time"].each_with_index do |ts, i|
      timeseries["total_site_electricity_kw"] << convert_J_to_kW(electricityTotalEndUses[i], steps_per_hour)
    end

    seasons.each do |season, temperature_range|
      report_sim_output(runner, "average_minimum_daily_use_#{season}_kw", average_daily_use(timeseries, temperature_range, "min"), "", "")
    end

    seasons.each do |season, temperature_range|
      report_sim_output(runner, "average_maximum_daily_use_#{season}_kw", average_daily_use(timeseries, temperature_range, "max"), "", "")
    end

    sqlFile.close

    return true
  end

  def average_daily_use(timeseries, temperature_range, min_or_max)
    daily_vals = []
    timeseries["total_site_electricity_kw"].each_slice(24).with_index do |kws, i|
      temps = timeseries["Temperature"][(24 * i)...(24 * i + 24)]
      avg_temp = temps.inject { |sum, el| sum + el }.to_f / temps.size
      if avg_temp > temperature_range[0] and avg_temp < temperature_range[1] # day is in this season
        if min_or_max == "min"
          daily_vals << kws.min
        elsif min_or_max == "max"
          daily_vals << kws.max
        end
      end
    end
    return daily_vals.inject { |sum, el| sum + el }.to_f / daily_vals.size
  end

  def convert_J_to_kW(j, steps_per_hour)
    seconds_in_interval = 3600.0 / steps_per_hour
    kw = j / (1000.0 * seconds_in_interval)
    return kw
  end

  def array_sum(array1, array2, units_represented = 1, num_units = 1)
    array = [array1, array2].transpose.collect { |a1, a2| a1 + units_represented * (a2 / num_units) }
    return array
  end

  def report_sim_output(runner, name, total_val, os_units, desired_units, percent_of_val = 1.0)
    total_val = total_val * percent_of_val
    if os_units.nil? or desired_units.nil? or os_units == desired_units
      valInUnits = total_val
    else
      valInUnits = UnitConversions.convert(total_val, os_units, desired_units)
    end
    puts "#{name} #{valInUnits}"
    runner.registerValue(name, valInUnits)
    runner.registerInfo("Registering #{valInUnits.round(2)} for #{name}.")
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
end

# register the measure to be used by the application
QOIReport.new.registerWithApplication
