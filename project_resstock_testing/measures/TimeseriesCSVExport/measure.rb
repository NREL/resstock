# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require 'erb'
require 'csv'

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
      'Propane'
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
      'Generators',
      'Facility'
    ]
    
    return end_uses
  end
  
  def output_vars
    output_vars = [
      'Zone Mean Air Temperature',
      'Zone Mean Air Humidity Ratio',
      'Fan Runtime Fraction'
    ]
    
    return output_vars
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
    reporting_frequency = OpenStudio::Measure::OSArgument::makeChoiceArgument('reporting_frequency', reporting_frequency_chs, true)
    reporting_frequency.setDisplayName("Reporting Frequency")
    reporting_frequency.setDefaultValue("Hourly")
    args << reporting_frequency
    
    # TODO: argument for subset of output meters
    
    #make an argument for including optional output variables
    inc_output_variables = OpenStudio::Measure::OSArgument::makeBoolArgument("inc_output_variables", true)
    inc_output_variables.setDisplayName("Include Output Variables")
    inc_output_variables.setDefaultValue(false)
    args << inc_output_variables    
    
    return args
  end 
  
  # return a vector of IdfObject's to request EnergyPlus objects needed by the run method
  def energyPlusOutputRequests(runner, user_arguments)
    super(runner, user_arguments)
    
    result = OpenStudio::IdfObjectVector.new

    reporting_frequency = runner.getStringArgumentValue("reporting_frequency",user_arguments)
    inc_output_variables = runner.getBoolArgumentValue("inc_output_variables",user_arguments)

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
    
    # Request the output for each variable
    if inc_output_variables
      output_vars.each do |output_var|
        result << OpenStudio::IdfObject.load("Output:Variable,#{output_var},#{reporting_frequency},*;").get
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
    inc_output_variables = runner.getBoolArgumentValue("inc_output_variables",user_arguments)
    
    # get the last model and sql file
    model = runner.lastOpenStudioModel
    if model.empty?
      runner.registerError("Cannot find last model.")
      return false
    end
    model = model.get
    epw_file = OpenStudio::EpwFile.new(File.expand_path(model.getWeatherFile.path.get.to_s))

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
    
    # Method to translate from OpenStudio's time formatting
    # to Javascript time formatting
    # OpenStudio time
    # 2009-May-14 00:10:00   Raw string
    # Javascript time
    # 2009/07/12 12:34:56
    def to_JSTime(os_time, year_description)
      js_time = os_time.to_s
      # Replace the '-' with '/'
      js_time = js_time.gsub('-','/')
      # Replace month abbreviations with numbers
      js_time = js_time.gsub('Jan','01')
      js_time = js_time.gsub('Feb','02')
      js_time = js_time.gsub('Mar','03')
      js_time = js_time.gsub('Apr','04')
      js_time = js_time.gsub('May','05')
      js_time = js_time.gsub('Jun','06')
      js_time = js_time.gsub('Jul','07')
      js_time = js_time.gsub('Aug','08')
      js_time = js_time.gsub('Sep','09')
      js_time = js_time.gsub('Oct','10')
      js_time = js_time.gsub('Nov','11')
      js_time = js_time.gsub('Dec','12')

      # manually shift timestamps for leap years
      if year_description.isLeapYear
        date, time = js_time.split(" ")
        year, month, day = date.split("/")
        year = year.to_f
        month = month.to_f
        day = day.to_f
        if not ( month == 1 and year == 2009 ) and not ( month == 2 and year == 2009 )
          day -= 1
          if day == 0
            month -= 1
            if month == 0
              month = 12
              day = 31              
            elsif month == 1
              day = 31
            elsif month == 2
              day = 29
            elsif month == 3
              day = 31
            elsif month == 4
              day = 28
            elsif month == 5
              day = 31
            elsif month == 6
              day = 30
            elsif month == 7
              day = 31
            elsif month == 8
              day = 31
            elsif month == 9
              day = 30
            elsif month == 10
              day = 31
            elsif month == 11
              day = 30
            end
          end
        end
        js_time = "#{year.to_i}/#{month.to_i.to_s.rjust(2, "0")}/#{day.to_i.to_s.rjust(2, "0")} #{time}"
        offset = 0
        if month == 1 and year == 2010
          offset = 1
        end
      end

      unless year_description.calendarYear.empty?
        js_time[0..3] = (year_description.calendarYear.get + offset).to_i.to_s
      end

      return js_time

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
    if inc_output_variables
      output_vars.each do |output_var|
        sql.availableKeyValues(ann_env_pd, reporting_frequency, output_var).each do |key_value|
          variables_to_graph << [output_var, reporting_frequency, key_value]
          runner.registerInfo("Exporting #{key_value} #{output_var}")
        end
      end
    end

    # Create a new series like this
    # for each condition series we want to plot
    # {"name" : "series 1",
    # "color" : "purple",
    # "data" :[{ "x": 20, "y": 0.015, "time": "2009/07/12 12:34:56"},
            # { "x": 25, "y": 0.008, "time": "2009/07/12 12:34:56"},
            # { "x": 30, "y": 0.005, "time": "2009/07/12 12:34:56"}]
    # }
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

      # Convert time stamp format to be more readable      
      year_description = model.getYearDescription
      unless epw_file.startDateActualYear.empty?
        year_description.setCalendarYear(epw_file.startDateActualYear.get)
      end

      js_date_times = []
      y_timeseries.dateTimes.each do |date_time|
        js_date_times << to_JSTime(date_time, year_description)
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
      series["data"] = data
      all_series << series        
        
      # increment color selection
      j += 1  
        
    end
        
    # Transform the data to CSV
    cols = []
    all_series.each_with_index do |series, k|
      data = series['data']
      units = series['units']
      # Record the timestamps and units on the first pass only
      if k == 0
        time_col = ['Time']
        #time_col << "#{reporting_frequency}"
        data.each do |entry|
          time_col << entry['time']
        end
        cols << time_col
      end
      # Record the data
      col_name = "#{series['type']} #{series['name']} [#{series['units']}]"
      data_col = [col_name]
      #data_col << units
      data.each do |entry|
        data_col << entry['y'].round(3)
      end
      cols << data_col
    end
    rows = cols.transpose
    
    # Write the rows out to CSV
    csv_path = File.expand_path("../enduse_timeseries.csv")
    CSV.open(csv_path, "wb") do |csv|
      rows.each do |row|
        csv << row
      end
    end    
    csv_path = File.absolute_path(csv_path)
    runner.registerFinalCondition("CSV file saved to <a href='file:///#{csv_path}'>enduse_timeseries.csv</a>.")

    # # Convert all_series to JSON.
    # # This JSON will be substituted
    # # into the HTML file.
    # require 'json'
    # all_series = all_series.to_json
    
    # # read in template
    # html_in_path = "#{File.dirname(__FILE__)}/resources/report.html.erb"
    # if File.exist?(html_in_path)
      # html_in_path = html_in_path
    # else
      # html_in_path = "#{File.dirname(__FILE__)}/report.html.erb"
    # end
    # html_in = ""
    # File.open(html_in_path, 'r') do |file|
      # html_in = file.read
    # end

    # # configure template with variable values
    # renderer = ERB.new(html_in)
    # html_out = renderer.result(binding)
    
    # # write html file
    # html_out_path = "./report.html"
    # File.open(html_out_path, 'w') do |file|
      # file << html_out
      # # make sure data is written to the disk one way or the other
      # begin
        # file.fsync
      # rescue
        # file.flush
      # end
    # end
    
    # close the sql file
    sql.close()
    
    return true
 
  end

end

# register the measure to be used by the application
TimeseriesCSVExport.new.registerWithApplication
