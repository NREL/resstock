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

    results = OutputMeters.create_custom_building_unit_meters(model: model,
                                                              runner: runner,
                                                              reporting_frequency: "Timestep",
                                                              include_enduse_subcategories: false,
                                                              energy_or_power: "Power")
    return results
  end

  def seasons
    return {
      "winter" => [-1e9, 55],
      "summer" => [75, 1e9],
      "shoulder" => [55, 75]
    }
  end

  def annual_energy_use
    return ["average_annual_electricity_consumption_kwh"]
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
      output_names << "average_of_top_ten_highest_peaks_#{season}_kw"
    end
    return output_names
  end

  def top_ten_seasonal_timing_of_peak_by_season
    output_names = []
    seasons.each do |season, temperature_range|
      output_names << "average_of_top_ten_highest_peaks_#{season}_hour"
    end
    return output_names
  end

  def outputs
    output_names = []
    output_names += annual_energy_use
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

    sqlFile.close

    return true
  end

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
end

# register the measure to be used by the application
QOIReport.new.registerWithApplication
