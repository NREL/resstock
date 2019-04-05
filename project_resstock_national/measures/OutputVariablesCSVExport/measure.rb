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

# start the measure
class OutputVariablesCSVExport < OpenStudio::Measure::ReportingMeasure
  # human readable name
  def name
    # Measure name should be the title case of the class name.
    return 'Output Variables CSV Export'
  end

  # human readable description
  def description
    return 'Exports output variables data to csv.'
  end

  def reporting_frequency_map # idf => osm
    return { "Timestep" => "Zone Timestep", "Hourly" => "Hourly", "Daily" => "Daily", "Monthly" => "Monthly", "Runperiod" => "Run Period" }
  end

  # define the arguments that the user will input
  def arguments
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

    # make an argument for optional output variables
    arg = OpenStudio::Measure::OSArgument::makeStringArgument("output_variables", false)
    arg.setDisplayName("Output Variables")
    arg.setDescription("Specify a comma-separated list of output variables to report. (See EnergyPlus's rdd file for available output variables.)")
    args << arg

    return args
  end

  # return a vector of IdfObject's to request EnergyPlus objects needed by the run method
  # Warning: Do not change the name of this method to be snake_case. The method must be lowerCamelCase.
  def energyPlusOutputRequests(runner, user_arguments)
    super(runner, user_arguments)

    results = OpenStudio::IdfObjectVector.new

    reporting_frequency = runner.getStringArgumentValue("reporting_frequency", user_arguments)
    output_vars = runner.getOptionalStringArgumentValue("output_variables", user_arguments)
    if output_vars.is_initialized
      output_vars = output_vars.get
      output_vars = output_vars.split(",")
      output_vars = output_vars.collect { |x| x.strip }
    else
      output_vars = []
    end

    # Request the output for each output variable
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
    if !runner.validateUserArguments(arguments, user_arguments)
      return false
    end

    # Assign the user inputs to variables
    reporting_frequency = runner.getStringArgumentValue("reporting_frequency", user_arguments)
    output_vars = runner.getOptionalStringArgumentValue("output_variables", user_arguments)
    if output_vars.is_initialized
      output_vars = output_vars.get
      output_vars = output_vars.split(",")
      output_vars = output_vars.collect { |x| x.strip }
    else
      output_vars = []
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

    csv_path = File.expand_path("../output_variables.csv")
    CSV.open(csv_path, "wb") do |csv|
      csv << timeseries.keys
      rows = timeseries.values.transpose
      rows.each do |row|
        csv << row
      end
    end

    return true
  end

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
end

# register the measure to be used by the application
OutputVariablesCSVExport.new.registerWithApplication
