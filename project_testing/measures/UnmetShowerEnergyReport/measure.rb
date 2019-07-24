# insert your copyright here

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

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
require File.join(resources_path, "geometry")

# start the measure
class UnmetShowerEnergyReport < OpenStudio::Measure::ReportingMeasure
  # human readable name
  def name
    # Measure name should be the title case of the class name.
    return 'Unmet Shower Energy Report'
  end

  # human readable description
  def description
    return 'Reports unmet shower energy.'
  end

  def modeler_description
    return "Reports unmet shower energy."
  end

  # define the arguments that the user will input
  def arguments
    args = OpenStudio::Measure::OSArgumentVector.new

    return args
  end

  # define the outputs that the measure will create
  def outputs
    buildstock_outputs = ["unmet_shower_energy_kbtu", "unmet_shower_time_hr", "shower_draw_time_hr"]
    result = OpenStudio::Measure::OSOutputVector.new
    buildstock_outputs.each do |output|
      result << OpenStudio::Measure::OSOutput.makeDoubleOutput(output)
    end
    return result
  end

  # return a vector of IdfObject's to request EnergyPlus objects needed by the run method
  # Warning: Do not change the name of this method to be snake_case. The method must be lowerCamelCase.
  def energyPlusOutputRequests(runner, user_arguments)
    super(runner, user_arguments)

    result = OpenStudio::IdfObjectVector.new

    # Get the last model
    model = runner.lastOpenStudioModel
    if model.empty?
      runner.registerError("Cannot find last model.")
      return false
    end
    model = model.get

    units = Geometry.get_building_units(model, runner)
    units.each do |unit|
      requests = ["Unmet Shower Energy|#{unit.name}", "Unmet Shower Time|#{unit.name}", "Shower Draw Time|#{unit.name}"]
      requests.each do |request, units|
        result << OpenStudio::IdfObject.load("Output:Variable,*,#{request},Hourly;").get
      end
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

    # Get the last model
    model = runner.lastOpenStudioModel
    if model.empty?
      runner.registerError("Cannot find last model.")
      return false
    end
    model = model.get

    # Get the last sql file
    sql = runner.lastEnergyPlusSqlFile
    if sql.empty?
      runner.registerError("Cannot find last sql file.")
      return false
    end
    sql = sql.get
    model.setSqlFile(sql)

    # Get the weather file run period (as opposed to design day run period)
    ann_env_pd = nil
    sql.availableEnvPeriods.each do |env_pd|
      env_type = sql.environmentType(env_pd)
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

    totals = { "unmet_shower_energy" => 0, "unmet_shower_time" => 0, "shower_draw_time" => 0 }
    units = Geometry.get_building_units(model, runner)
    units.each do |unit|
      requests = { "Unmet Shower Energy|#{unit.name}" => "kBtu", "Unmet Shower Time|#{unit.name}" => "hr", "Shower Draw Time|#{unit.name}" => "hr" }
      requests.each do |request, units|
        sql.availableKeyValues(ann_env_pd, "Hourly", request).each do |key_value|
          total_val = get_timeseries(sql, ann_env_pd, request, key_value, units)
          request, unit = request.split("|")
          totals[OpenStudio::toUnderscoreCase(request)] += total_val
        end
      end
    end

    report_output(runner, "unmet_shower_energy", totals["unmet_shower_energy"], "kbtu")
    report_output(runner, "unmet_shower_time", totals["unmet_shower_time"], "hr")
    report_output(runner, "shower_draw_time", totals["shower_draw_time"], "hr")

    sql.close()

    return true
  end

  def get_timeseries(sql, ann_env_pd, request, key_value, units)
    timeseries = sql.timeSeries(ann_env_pd, "Hourly", request, key_value)
    values = timeseries.get.values
    total_val = 0
    (0...values.length).to_a.each do |i|
      total_val += values[i]
    end
    return UnitConversions.convert(total_val, timeseries.get.units, units)
  end

  def report_output(runner, name, val, units)
    runner.registerValue("#{name}_#{units}", val)
    runner.registerInfo("Registering #{val.round(2)} #{units} for #{name}.")
  end
end

# register the measure to be used by the application
UnmetShowerEnergyReport.new.registerWithApplication
