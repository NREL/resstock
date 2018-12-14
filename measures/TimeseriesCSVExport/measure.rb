# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

# require 'ruby-prof'
require 'erb'
require 'csv'
resstock_aws_path = "../../lib/resources/measures/HPXMLtoOpenStudio/resources"
resstock_local_path = "../../resources/measures/HPXMLtoOpenStudio/resources"
if File.exists? File.absolute_path(File.join(File.dirname(__FILE__), resstock_aws_path)) # Hack to run ResStock on AWS
  resources_path = resstock_aws_path
elsif File.exists? File.absolute_path(File.join(File.dirname(__FILE__), resstock_local_path)) # Hack to run ResStock unit tests locally
  resources_path = resstock_local_path
else
  resources_path = "../HPXMLtoOpenStudio/resources"
end
require_relative File.join(resources_path, "weather")
require_relative File.join(resources_path, "unit_conversions")

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

  # human readable description of modeling approach
  def modeler_description
    return "Exports all available timeseries enduses, subcategories, and output variables to csv file(s)."
  end

  def fuel_types
    fuel_types = [
      "Electricity",
      "Gas",
      "DistrictCooling",
      "DistrictHeating",
      "Water",
      "FuelOil#1",
      "Propane",
      "ElectricityProduced"
    ]
    return fuel_types
  end

  def end_uses
    end_uses = [
      "Heating",
      "Cooling",
      "InteriorLights",
      "ExteriorLights",
      "InteriorEquipment",
      "ExteriorEquipment",
      "Fans",
      "Pumps",
      "HeatRejection",
      "Humidifier",
      "HeatRecovery",
      "WaterSystems",
      "Refrigeration",
      "Facility"
    ]
    return end_uses
  end

  def end_use_subcategories(model)
    end_use_subcategories = []
    model.getElectricEquipments.each do |equip|
      next if equip.endUseSubcategory.empty?

      end_uses.each do |end_use|
        next if end_use_subcategories.include? "#{equip.endUseSubcategory}:#{end_use}:Electricity"

        end_use_subcategories << "#{equip.endUseSubcategory}:#{end_use}:Electricity"
      end
    end
    model.getGasEquipments.each do |equip|
      next if equip.endUseSubcategory.empty?

      end_uses.each do |end_use|
        next if end_use_subcategories.include? "#{equip.endUseSubcategory}:#{end_use}:Gas"

        end_use_subcategories << "#{equip.endUseSubcategory}:#{end_use}:Gas"
      end
    end
    model.getOtherEquipments.each do |equip|
      next if equip.endUseSubcategory.empty?
      next if equip.fuelType.empty? or equip.fuelType == "None"

      end_uses.each do |end_use|
        variable_name = "#{equip.endUseSubcategory}:#{end_use}:#{equip.fuelType}"
        variable_name = variable_name.gsub("NaturalGas", "Gas").gsub("PropaneGas", "Propane")
        next if end_use_subcategories.include? variable_name

        end_use_subcategories << variable_name
      end
    end
    return end_use_subcategories
  end

  def reporting_frequency_map # idf => osm
    return { "Detailed" => "HVAC System Timestep", "Timestep" => "Zone Timestep", "Hourly" => "Hourly", "Daily" => "Daily", "Monthly" => "Monthly", "Runperiod" => "Run Period" }
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
    arg.setDescription("Whether to report appliance-level enduses: refrigerator, clothes dryer, plug loads, etc.")
    arg.setDefaultValue(false)
    args << arg

    # make an argument for optional output variables
    arg = OpenStudio::Measure::OSArgument::makeStringArgument("output_variables", true)
    arg.setDisplayName("Output Variables")
    arg.setDescription("Specify a comma-separated list of output variables to report. (See EnergyPlus's rdd file for available output variables.)")
    arg.setDefaultValue("")
    args << arg

    return args
  end

  # return a vector of IdfObject's to request EnergyPlus objects needed by the run method
  def energyPlusOutputRequests(runner, user_arguments)
    super(runner, user_arguments)

    result = OpenStudio::IdfObjectVector.new

    reporting_frequency = runner.getStringArgumentValue("reporting_frequency", user_arguments)
    include_enduse_subcategories = runner.getBoolArgumentValue("include_enduse_subcategories", user_arguments)
    output_vars = runner.getStringArgumentValue("output_variables", user_arguments).split(",")

    # Request the output for each enduse/fuel type combination
    end_uses.each do |end_use|
      fuel_types.each do |fuel_type|
        variable_name = "#{end_use}:#{fuel_type}"
        if end_use == "Facility"
          variable_name = "#{fuel_type}:#{end_use}"
        end
        if reporting_frequency == "Detailed"
          result << OpenStudio::IdfObject.load("Output:Meter,#{variable_name},Timestep;").get
        else
          result << OpenStudio::IdfObject.load("Output:Meter,#{variable_name},#{reporting_frequency};").get
        end
      end
    end

    # Request the output for each electric equipment object
    if include_enduse_subcategories
      # get the last model and sql file
      model = runner.lastOpenStudioModel
      if model.empty?
        runner.registerError("Cannot find last model.")
        return false
      end
      model = model.get
      end_use_subcategories(model).each do |variable_name|
        result << OpenStudio::IdfObject.load("Output:Meter,#{variable_name},#{reporting_frequency};").get
      end
    end

    # Request the output for each output variable
    output_vars.each do |output_var|
      result << OpenStudio::IdfObject.load("Output:Variable,*,#{output_var.strip},#{reporting_frequency};").get
    end

    return result
  end

  # define what happens when the measure is run
  def run(runner, user_arguments)
    super(runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(), user_arguments)
      return false
    end

    # Assign the user inputs to variables
    reporting_frequency = runner.getStringArgumentValue("reporting_frequency", user_arguments)
    include_enduse_subcategories = runner.getBoolArgumentValue("include_enduse_subcategories", user_arguments)
    output_variables = runner.getStringArgumentValue("output_variables", user_arguments)

    # Clean output variables
    output_vars = []
    output_variables.split(",").each do |output_var|
      output_vars << output_var.strip
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

    # Create an array of arrays of variables
    variables_to_report = []
    end_uses.each do |end_use|
      fuel_types.each do |fuel_type|
        if end_use == "Facility"
          variable_name = "#{fuel_type}:#{end_use}"
        else
          variable_name = "#{end_use}:#{fuel_type}"
        end
        variables_to_report << [variable_name, reporting_frequency_map[reporting_frequency], ""]
      end
    end
    if include_enduse_subcategories
      end_use_subcategories(model).each do |variable_name|
        variables_to_report << [variable_name, reporting_frequency_map[reporting_frequency], ""]
      end
    end
    output_vars.each do |output_var|
      sql.availableKeyValues(ann_env_pd, reporting_frequency_map[reporting_frequency], output_var.strip).each do |key_value|
        variables_to_report << [output_var.strip, reporting_frequency[reporting_frequency], key_value]
      end
    end

    # Get the timestamps for actual year epw file, and the number of intervals per hour
    weather = WeatherProcess.new(model, runner)
    if weather.error?
      return false
    end

    actual_year_timestamps = weather.actual_year_timestamps
    records_per_hour = weather.header.RecordsPerHour

    enduse_date_times = []
    enduse_timeseries = []
    output_vars_date_times = []
    output_vars_timeseries = []
    variables_to_report.each_with_index do |var_to_report, j|
      var_name = var_to_report[0]
      freq = var_to_report[1]
      kv = var_to_report[2]

      # Get the y axis values
      if not output_vars.include? var_name and freq == "HVAC System Timestep"
        freq = "Zone Timestep"
      end
      y_timeseries = sql.timeSeries(ann_env_pd, freq, var_name, kv)
      if y_timeseries.empty?
        next
      else
        runner.registerInfo("Exporting #{freq} #{var_name} #{kv}.")
        y_timeseries = y_timeseries.get
        values = y_timeseries.values
      end

      old_units = y_timeseries.units
      new_units = old_units
      case old_units
      when "J"
        new_units = "kBtu"
        if var_name.include? "Electricity"
          new_units = "kWh"
        end
      when "m3"
        old_units = "m^3"
        new_units = "gal"
      when "C"
        new_units = "F"
      end
      unit_conv = nil
      if ["J", "m^3"].include? old_units
        unit_conv = UnitConversions.convert(1.0, old_units, new_units)
      elsif not (old_units == "C" and new_units == "F")
        unless old_units.empty?
          runner.registerInfo("Have not yet defined a conversion from #{old_units} to other units.")
        end
      end

      y_vals = ["#{var_name} #{kv} [#{new_units}]"]
      y_timeseries.dateTimes.each_with_index do |date_time, i|
        if output_vars.include? var_name
          if output_vars_date_times.empty?
            output_vars_date_times << "Time"
          end
          if output_vars_timeseries.empty?
            if actual_year_timestamps.empty? # weather file is a TMY (i.e., year is always 2009)
              output_vars_date_times << format_datetime(date_time.to_s) # timestamps from the sqlfile (TMY)
            else
              if (freq == "Hourly" and records_per_hour == 1) or (freq == "Zone Timestep" and records_per_hour != 1)
                output_vars_date_times << actual_year_timestamps[i] # timestamps from the epw (AMY)
              else
                output_vars_date_times << i + 1 # TODO: change from reporting integers to appropriate timestamps
              end
            end
          end
        else # not an output variable
          if enduse_date_times.empty?
            enduse_date_times << "Time"
          end
          if enduse_timeseries.empty?
            if actual_year_timestamps.empty? # weather file is a TMY (i.e., year is always 2009)
              enduse_date_times << format_datetime(date_time.to_s) # timestamps from the sqlfile (TMY)
            else
              if (freq == "Hourly" and records_per_hour == 1) or (freq == "Zone Timestep" and records_per_hour != 1)
                enduse_date_times << actual_year_timestamps[i] # timestamps from the epw (AMY)
              else
                enduse_date_times << i + 1 # TODO: change from reporting integers to appropriate timestamps
              end
            end
          end
        end
        y_val = values[i]
        if unit_conv.nil? # these unit conversions are not scalars
          if old_units == "C" and new_units == "F"
            y_val = UnitConversions.convert(y_val, "C", "F") # convert C to F
          end
        else # these are scalars
          y_val *= unit_conv
        end
        y_vals << y_val.round(3)
      end

      if output_vars.include? var_name
        if output_vars_timeseries.empty?
          output_vars_timeseries << output_vars_date_times
        end
        if y_vals.length == output_vars_timeseries[0].length
          output_vars_timeseries << y_vals
        else
          runner.registerWarning("The length of #{y_vals[0]} is not #{output_vars_timeseries[0].length}. Not reporting this.")
        end
      else # not an output variable
        if enduse_timeseries.empty?
          enduse_timeseries << enduse_date_times
        end
        if y_vals.length == enduse_timeseries[0].length
          enduse_timeseries << y_vals
        else
          runner.registerWarning("The length of #{y_vals[0]} is not #{enduse_timeseries[0].length}. Not reporting this.")
        end
      end
    end

    # Write the enduse timeseries rows out to csv
    unless enduse_timeseries.empty?
      rows = enduse_timeseries.transpose
      csv_path = File.expand_path("../enduse_timeseries.csv")
      CSV.open(csv_path, "wb") do |csv|
        rows.each do |row|
          csv << row
        end
      end
    end

    # Write the output vars timeseries rows out to csv
    unless output_vars_timeseries.empty?
      rows = output_vars_timeseries.transpose
      csv_path = File.expand_path("../output_variables.csv")
      CSV.open(csv_path, "wb") do |csv|
        rows.each do |row|
          csv << row
        end
      end
    end

    # close the sql file
    sql.close()

    return true
  end

  def format_datetime(date_time)
    date_time = date_time.gsub("-", "/")
    date_time = date_time.gsub("Jan", "01")
    date_time = date_time.gsub("Feb", "02")
    date_time = date_time.gsub("Mar", "03")
    date_time = date_time.gsub("Apr", "04")
    date_time = date_time.gsub("May", "05")
    date_time = date_time.gsub("Jun", "06")
    date_time = date_time.gsub("Jul", "07")
    date_time = date_time.gsub("Aug", "08")
    date_time = date_time.gsub("Sep", "09")
    date_time = date_time.gsub("Oct", "10")
    date_time = date_time.gsub("Nov", "11")
    date_time = date_time.gsub("Dec", "12")
    return date_time
  end
end

# register the measure to be used by the application
TimeseriesCSVExport.new.registerWithApplication
