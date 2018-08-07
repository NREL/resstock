# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

# require 'ruby-prof'
require 'erb'
require 'csv'
require "#{File.dirname(__FILE__)}/resources/weather"
require "#{File.dirname(__FILE__)}/resources/unit_conversions"

#start the measure
class TimeseriesCSVExport < OpenStudio::Measure::ReportingMeasure

  # human readable name
  def name
    return "Timeseries CSV Export"
  end

  # human readable description
  def description
    return "Exports all available hourly timeseries enduses to csv."
  end

  # human readable description of modeling approach
  def modeler_description
    return "Exports all available hourly timeseries enduses to csv."
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

  # define the arguments that the user will input
  def arguments()
    args = OpenStudio::Measure::OSArgumentVector.new

    #make an argument for the frequency
    reporting_frequency_chs = OpenStudio::StringVector.new
    reporting_frequency_chs << "Detailed"
    reporting_frequency_chs << "Timestep"
    reporting_frequency_chs << "Hourly"
    reporting_frequency_chs << "Daily"
    reporting_frequency_chs << "Monthly"
    reporting_frequency_chs << "Runperiod"
    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument("reporting_frequency", reporting_frequency_chs, true)
    arg.setDisplayName("Reporting Frequency")
    arg.setDefaultValue("Hourly")
    args << arg

    #make an argument for including optional end use subcategories
    arg = OpenStudio::Measure::OSArgument::makeBoolArgument("inc_end_use_subcategories", true)
    arg.setDisplayName("Include End Use Subcategories")
    arg.setDefaultValue(false)
    args << arg

    #make an argument for including optional output variables
    arg = OpenStudio::Measure::OSArgument::makeBoolArgument("inc_output_variables", true)
    arg.setDisplayName("Include Output Variables")
    arg.setDefaultValue(false)
    args << arg

    #make an argument for optional output variables
    arg = OpenStudio::Measure::OSArgument::makeStringArgument("output_variables", true)
    arg.setDisplayName("Output Variables")
    arg.setDefaultValue("Zone Mean Air Temperature, Zone Mean Air Humidity Ratio, Fan Runtime Fraction")
    args << arg

    return args
  end

  # return a vector of IdfObject's to request EnergyPlus objects needed by the run method
  def energyPlusOutputRequests(runner, user_arguments)
    super(runner, user_arguments)
    
    result = OpenStudio::IdfObjectVector.new

    reporting_frequency = runner.getStringArgumentValue("reporting_frequency",user_arguments)
    inc_end_use_subcategories = runner.getBoolArgumentValue("inc_end_use_subcategories",user_arguments)
    inc_output_variables = runner.getBoolArgumentValue("inc_output_variables",user_arguments)
    output_vars = runner.getStringArgumentValue("output_variables",user_arguments).split(",")

    # Request the output for each end use/fuel type combination
    end_uses.each do |end_use|
      fuel_types.each do |fuel_type|
        variable_name = if end_use == "Facility"
            "#{fuel_type}:#{end_use}"
          else
            "#{end_use}:#{fuel_type}"
          end
        result << OpenStudio::IdfObject.load("Output:Meter,#{variable_name},#{reporting_frequency};").get
      end
    end
    
    # Request the output for each electric equipment object
    if inc_end_use_subcategories
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
    if inc_output_variables
      output_vars.each do |output_var|
        result << OpenStudio::IdfObject.load("Output:Variable,*,#{output_var.strip},#{reporting_frequency};").get
      end
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
    reporting_frequency = runner.getStringArgumentValue("reporting_frequency",user_arguments)
    inc_end_use_subcategories = runner.getBoolArgumentValue("inc_end_use_subcategories",user_arguments)
    inc_output_variables = runner.getBoolArgumentValue("inc_output_variables",user_arguments)
    output_vars = runner.getStringArgumentValue("output_variables",user_arguments).split(",")
    
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
    variables_to_graph = []
    end_uses.each do |end_use|
      fuel_types.each do |fuel_type|
        variable_name = if end_use == "Facility"
          "#{fuel_type}:#{end_use}"
        else
          "#{end_use}:#{fuel_type}"
        end
        variables_to_graph << [variable_name, reporting_frequency, ""]
        runner.registerInfo("Exporting #{variable_name}")
      end
    end
    if inc_end_use_subcategories
      end_use_subcategories(model).each do |variable_name|
        variables_to_graph << [variable_name, reporting_frequency, ""]
        runner.registerInfo("Exporting #{variable_name}")
      end
    end
    if inc_output_variables
      output_vars.each do |output_var|
        sql.availableKeyValues(ann_env_pd, reporting_frequency, output_var.strip).each do |key_value|
          variables_to_graph << [output_var.strip, reporting_frequency, key_value]
          runner.registerInfo("Exporting #{key_value} #{output_var.strip}")
        end
      end
    end

    # Get the timestamps for actual year epw file
    actual_timestamps = WeatherProcess.actual_timestamps(model, runner, File.dirname(__FILE__))
    
    date_times = []
    cols = []
    variables_to_graph.each_with_index do |var_to_graph, j|

      var_name = var_to_graph[0]
      freq = var_to_graph[1]
      kv = var_to_graph[2]

      # Get the y axis values
      y_timeseries = sql.timeSeries(ann_env_pd, freq, var_name, kv)
      if y_timeseries.empty?
        runner.registerWarning("No data found for #{freq} #{var_name} #{kv}.")
        next
      else
        y_timeseries = y_timeseries.get
        values = y_timeseries.values
      end

      old_units = y_timeseries.units      
      new_units = case old_units
                  when "J"
                    if var_name.include?("Electricity")
                      "kWh"
                    else
                      "kBtu"
                    end
                  when "m3"
                    old_units = "m^3"
                    "gal"
                  when "C"
                    "F"
                  else
                    old_units
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
        if date_times.empty?
          date_times << "Time"
        end
        if cols.empty?
          if reporting_frequency == "Hourly"
            if actual_timestamps.empty?
              date_times << format_datetime(date_time.to_s) # timestamps from the sqlfile (TMY)
            else
              date_times << actual_timestamps[i] # timestamps from the epw (AMY)
            end
          else
            date_times << i+1
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

      if cols.empty?
        cols << date_times
      end      
      cols << y_vals

    end

    # Write the rows out to csv
    rows = cols.transpose
    csv_path = File.expand_path("../enduse_timeseries.csv")
    CSV.open(csv_path, "wb") do |csv|
      rows.each do |row|
        csv << row
      end
    end
    csv_path = File.absolute_path(csv_path)
    runner.registerFinalCondition("CSV file saved to <a href='file:///#{csv_path}'>enduse_timeseries.csv</a>.")

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