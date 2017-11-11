# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require 'erb'
require 'csv'
require "#{File.dirname(__FILE__)}/resources/weather"

#start the measure
class TimeseriesCSVExport < OpenStudio::Measure::ReportingMeasure

  # human readable name
  def name
    return "Timeseries CSV Export"
  end

  # human readable description
  def description
    return "Exports all available hourly timeseries enduses to csv, and uses them for utility bill calculations."
  end

  # human readable description of modeling approach
  def modeler_description
    return "Exports all available hourly timeseries enduses to csv, and uses them for utility bill calculations."
  end

  def fuel_types
    fuel_types = [  
      'Electricity',
      'Gas',
      'DistrictCooling',
      'DistrictHeating',
      'Water',
      'FuelOil#1',
      'Propane',
      'ElectricityProduced'
    ]    
    return fuel_types
  end
  
  def end_uses
    end_uses = [
      'Heating',
      'Cooling',
      'InteriorLights',
      'ExteriorLights',
      'InteriorEquipment',
      'ExteriorEquipment',
      'Fans',
      'Pumps',
      'HeatRejection',
      'Humidifier',
      'HeatRecovery',
      'WaterSystems',
      'Refrigeration',
      'Facility'
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
        variable_name = if end_use == 'Facility'
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
        result << OpenStudio::IdfObject.load("Output:Variable,#{output_var.strip},#{reporting_frequency};").get
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
    
    # get the last model and sql file
    model = runner.lastOpenStudioModel
    if model.empty?
      runner.registerError("Cannot find last model.")
      return false
    end
    model = model.get
    
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
        variable_name = if end_use == 'Facility'
            "#{fuel_type}:#{end_use}"
          else
            "#{end_use}:#{fuel_type}"
          end
        variables_to_graph << [variable_name, reporting_frequency, '']
        runner.registerInfo("Exporting #{variable_name}")
      end
    end
    if inc_end_use_subcategories
      end_use_subcategories(model).each do |variable_name|
        variables_to_graph << [variable_name, reporting_frequency, '']
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

    epw_timestamps = WeatherProcess.epw_timestamps(model, runner, File.dirname(__FILE__))

    all_series = []
    # Sort by fuel, putting the total (Facility) column at the end of the fuel.
    variables_to_graph.sort_by! do |i| 
      fuel_type = if i[0].include?('Facility')
                    i[0].gsub(/:Facility/, '')
                  else
                    i[0].gsub(/.*:/, '')
                  end
      end_use = if i[0].include?('Facility')
                  'ZZZ' # so it will be last
                else
                  i[0].gsub(/:.*/, '')
                end
      sort_key = "#{fuel_type}#{end_use}"
    end
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
      end
      y_vals = y_timeseries.values

      js_date_times = []
      y_timeseries.dateTimes.each_with_index do |date_time, i|
        if reporting_frequency == "Hourly"
          js_date_times << epw_timestamps[i]
        else
          js_date_times << i+1
        end
      end
      
      # Store the timeseries data to hash for later
      # export to the HTML file
      series = {}
      series["name"] = "#{kv}"
      series["type"] = "#{var_name}"
      # Unit conversion
      old_units = y_timeseries.units
      new_units = case old_units
                  when "J"
                    if var_name.include?('Electricity')
                      "kWh"
                    else
                      "kBtu"
                    end
                  when "m3"
                    old_units = "m^3"
                    "gal"
                  else
                    old_units
                  end
      series["units"] = new_units
      data = []
      for i in 0..(js_date_times.size - 1)
        point = {}
        val_i = y_vals[i]
        # Unit conversion
        unless new_units == old_units
          val_i = OpenStudio.convert(val_i, old_units, new_units).get
        end
        time_i = js_date_times[i]
        point["y"] = val_i
        point["time"] = time_i
        data << point
      end
      next if data.all? {|x| x["y"].abs < 0.000000001}
      series["data"] = data
      all_series << series
        
    end
        
    # Transform the data to CSV
    cols = []
    all_series.each_with_index do |series, k|
      data = series['data']
      units = series['units']
      # Record the timestamps and units on the first pass only
      if k == 0
        time_col = ['Time']
        data.each do |entry|
          time_col << entry['time']
        end
        cols << time_col
      end
      # Record the data
      col_name = "#{series['type']} #{series['name']} [#{series['units']}]"
      data_col = [col_name]
      data.each do |entry|
        data_col << entry['y'].round(2)
      end
      cols << data_col
    end
    rows = cols.transpose
    
    # Get the rows into sequential order based on the timestamps    
    rows = [rows[0]] + rows[1..-1].sort {|a, b| a[0] <=> b[0]}
    
    # Write the rows out to CSV
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

end

# register the measure to be used by the application
TimeseriesCSVExport.new.registerWithApplication
