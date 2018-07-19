# insert your copyright here

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require 'openstudio'

# start the measure
class ResilienceMetricsReport < OpenStudio::Measure::ReportingMeasure
  # human readable name
  def name
    # Measure name should be the title case of the class name.
    return 'Resilience Metrics Report'
  end

  # human readable description
  def description
    return 'Reports resilience metric(s) of interest.'
  end

  # define the arguments that the user will input
  def arguments
    args = OpenStudio::Measure::OSArgumentVector.new

    #make a double argument for minimum comfortable temperature
    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("min", true)
    arg.setDisplayName("Minimum Comfortable Temperature")
    arg.setUnits("deg F")
    arg.setDescription("TODO.")
    arg.setDefaultValue(65)
    args << arg

    #make a double argument for maximum comfortable temperature
    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("max", true)
    arg.setDisplayName("Maximum Comfortable Temperature")
    arg.setUnits("deg F")
    arg.setDescription("TODO.")
    arg.setDefaultValue(75)
    args << arg

    return args
  end
  
  def zones
    return ["living_zone", "finished_basement_zone"]
  end

  # define the outputs that the measure will create
  def outputs
    buildstock_outputs = []
    zones.each do |zone|
      buildstock_outputs << "#{zone}_zone_mean_air_temperature"
    end
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

    # use the built-in error checking
    if !runner.validateUserArguments(arguments, user_arguments)
      return result
    end

    request = OpenStudio::IdfObject.load('Output:Variable,*,Zone Mean Air Temperature,Hourly;').get
    result << request

    return result
  end

  # define what happens when the measure is run
  def run(runner, user_arguments)
    super(runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments, user_arguments)
      return false
    end

    # Assign the user inputs to variables
    mins = [runner.getDoubleArgumentValue("min", user_arguments)] * 8760
    maxs = [runner.getDoubleArgumentValue("max", user_arguments)] * 8760

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

    sql.availableKeyValues(ann_env_pd, "Hourly", "Zone Mean Air Temperature").each do |key_value|

      next unless zones.include? OpenStudio::toUnderscoreCase(key_value)

      resilience_metric = 0
      y_timeseries = sql.timeSeries(ann_env_pd, "Hourly", "Zone Mean Air Temperature", key_value)
      if y_timeseries.empty?
        runner.registerError("No data found for Hourly #{key_value} Zone Mean Air Temperature.")
        return false
      else
        y_timeseries = y_timeseries.get
        values = y_timeseries.values

        y_timeseries.dateTimes.each_with_index do |date_time, i|
          if UnitConversions.convert(values[i], "C", "F") < mins[i]
            resilience_metric += 1
          elsif UnitConversions.convert(values[i], "C", "F") > maxs[i]
            resilience_metric += 1
          end
        end
      end

      runner.registerInfo("Exporting Hourly #{key_value} Zone Mean Air Temperature resilience metric.")
      report_resilience_output(runner, "#{key_value} Zone Mean Air Temperature", [resilience_metric])

    end

    sql.close()

    return true
  end

  def report_resilience_output(runner, name, vals)
    total_val = 0.0
    vals.each do |val|
        total_val += val
    end
    runner.registerValue(name, total_val)
    runner.registerInfo("Registering #{total_val.round(2)} for #{name}.")
  end

end

# register the measure to be used by the application
ResilienceMetricsReport.new.registerWithApplication
