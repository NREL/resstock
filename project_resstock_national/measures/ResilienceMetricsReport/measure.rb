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
    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("min_temp", true)
    arg.setDisplayName("Minimum Comfortable Temperature")
    arg.setUnits("deg F")
    arg.setDescription("The minimum temperature for which someone is comfortable.")
    arg.setDefaultValue(60)
    args << arg

    #make a double argument for maximum comfortable temperature
    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("max_temp", true)
    arg.setDisplayName("Maximum Comfortable Temperature")
    arg.setUnits("deg F")
    arg.setDescription("The maximum temperature for which someone is comfortable.")
    arg.setDefaultValue(80)
    args << arg

    #make a double argument for minimum comfortable relative humidity
    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("min_hum", true)
    arg.setDisplayName("Minimum Comfortable Relative Humidity")
    arg.setUnits("%")
    arg.setDescription("The minimum relative humidity for which someone is comfortable.")
    arg.setDefaultValue(10)
    args << arg

    #make a double argument for maximum comfortable relative humidity
    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("max_hum", true)
    arg.setDisplayName("Maximum Comfortable Relative Humidity")
    arg.setUnits("%")
    arg.setDescription("The maximum relative humidity for which someone is comfortable.")
    arg.setDefaultValue(60)
    args << arg

    return args
  end
  
  def zones
    return ["Living Zone", "Finished Basement Zone"]
  end

  def output_vars
    return ["Zone Mean Air Temperature", "Zone Air Relative Humidity"]
  end

  # define the outputs that the measure will create
  def outputs
    buildstock_outputs = []
    output_vars.each do |output_var|
      zones.each do |zone|
        buildstock_outputs << "#{OpenStudio::toUnderscoreCase(zone)}_#{OpenStudio::toUnderscoreCase(output_var)}"
      end
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

    output_vars.each do |output_var|
      result << OpenStudio::IdfObject.load("Output:Variable,*,#{output_var},Hourly;").get
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

    # Assign the user inputs to variables
    min_temp = runner.getDoubleArgumentValue("min_temp", user_arguments)
    max_temp = runner.getDoubleArgumentValue("max_temp", user_arguments)
    min_hum = runner.getDoubleArgumentValue("min_hum", user_arguments)
    max_hum = runner.getDoubleArgumentValue("max_hum", user_arguments)

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

    output_vars.each do |output_var|
      sql.availableKeyValues(ann_env_pd, "Hourly", output_var).each do |key_value|

        next unless zones.any? { |zone| zone.casecmp(key_value) == 0 }

        resilience_metric = 0
        timeseries = sql.timeSeries(ann_env_pd, "Hourly", output_var, key_value)
        if timeseries.empty?
          runner.registerError("No data found for Hourly #{key_value} #{output_var}.")
          return false
        else
          timeseries = timeseries.get
          values = timeseries.values

          timeseries.dateTimes.each_with_index do |date_time, i|
            case output_var
            when "Zone Mean Air Temperature"
              if UnitConversions.convert(values[i], "C", "F") < min_temp or UnitConversions.convert(values[i], "C", "F") > max_temp
                resilience_metric += 1 # hours
              end
            when "Zone Air Relative Humidity"
              if values[i] < min_hum or values[i] > max_hum
                resilience_metric += 1 # hours
              end
            end
          end
        end

        report_output(runner, "#{key_value} #{output_var}", resilience_metric)

      end
    end

    sql.close()

    return true
  end

  def report_output(runner, name, val)
    runner.registerValue(name, val)
    runner.registerInfo("Registering #{val} for #{name}.")
  end

end

# register the measure to be used by the application
ResilienceMetricsReport.new.registerWithApplication
