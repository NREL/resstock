# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require 'erb'
require 'csv'
require 'matrix'
require "#{File.dirname(__FILE__)}/resources/unit_conversions"

#start the measure
class UtilityBillCalculations < OpenStudio::Measure::ReportingMeasure

  # human readable name
  def name
    return "Utility Bill Calculations"
  end

  # human readable description
  def description
    return "Calls SAM SDK."
  end

  # human readable description of modeling approach
  def modeler_description
    return "Calls SAM SDK."
  end 
  
  def fuel_types
    fuel_types = [  
      'Electricity',
      'Gas',
      'FuelOil#1',
      'Propane',
      'ElectricityProduced'
    ]
    
    return fuel_types
  end
  
  def end_uses
    end_uses = [
      'Facility'
    ]
    
    return end_uses
  end
  
  # define the arguments that the user will input
  def arguments()
    args = OpenStudio::Measure::OSArgumentVector.new
    
    arg = OpenStudio::Measure::OSArgument.makeStringArgument("run_dir", true)
    arg.setDisplayName("Run Directory")
    arg.setDescription("Relative path of the run directory.")
    arg.setDefaultValue("..")
    args << arg    
    
    arg = OpenStudio::Measure::OSArgument::makeStringArgument("api_key", false)
    arg.setDisplayName("API Key")
    arg.setDescription("Call the API and pull JSON tariff file(s) with EIA ID corresponding to the EPW region.")
    args << arg
    
    arg = OpenStudio::Measure::OSArgument::makeStringArgument("tariff_directory", false)
    arg.setDisplayName("Tariff Directory")
    arg.setDescription("Absolute (or relative) directory to tariff files.")
    args << arg
    
    arg = OpenStudio::Measure::OSArgument::makeStringArgument("tariff_file_name", false)
    arg.setDisplayName("Tariff File Name")
    arg.setDescription("Name of the JSON tariff file. Leave blank if pulling JSON tariff file(s) with EIA ID corresponding to the EPW region.")
    args << arg
    
    arg = OpenStudio::Measure::OSArgument::makeStringArgument("elec_fixed", false)
    arg.setDisplayName("Electricity Fixed Cost")
    arg.setUnits("$")
    arg.setDescription("Annual fixed cost of electricity.")
    args << arg
    
    arg = OpenStudio::Measure::OSArgument::makeStringArgument("elec_rate", false)
    arg.setDisplayName("Electricity Unit Cost")
    arg.setUnits("$/kWh")
    arg.setDescription("Price per kilowatt-hour for electricity.")
    args << arg
    
    arg = OpenStudio::Measure::OSArgument::makeStringArgument("ng_fixed", false)
    arg.setDisplayName("Natural Gas Fixed Cost")
    arg.setUnits("$")
    arg.setDescription("Annual fixed cost of natural gas.")
    args << arg
    
    arg = OpenStudio::Measure::OSArgument::makeStringArgument("ng_rate", false)
    arg.setDisplayName("Natural Gas Unit Cost")
    arg.setUnits("$/therm")
    arg.setDescription("Price per therm for natural gas.")
    args << arg
    
    arg = OpenStudio::Measure::OSArgument::makeStringArgument("oil_rate", false)
    arg.setDisplayName("Fuel Oil Unit Cost")
    arg.setUnits("$/gal")
    arg.setDescription("Price per gallon for fuel oil.")
    args << arg
    
    arg = OpenStudio::Measure::OSArgument::makeStringArgument("prop_rate", false)
    arg.setDisplayName("Propane Unit Cost")
    arg.setUnits("$/gal")
    arg.setDescription("Price per gallon for propane.")
    args << arg
    
    arg = OpenStudio::Measure::OSArgument::makeBoolArgument("avg_rates", true)
    arg.setDisplayName("Average Residential Rates")
    arg.setDescription("Average across residential rates in a given EIA ID.")
    arg.setDefaultValue(false)
    args << arg

    return args
  end
  
  # return a vector of IdfObject's to request EnergyPlus objects needed by the run method
  def energyPlusOutputRequests(runner, user_arguments)
    super(runner, user_arguments)
    
    result = OpenStudio::IdfObjectVector.new

    # Request the output for each end use/fuel type combination
    end_uses.each do |end_use|
      fuel_types.each do |fuel_type|
        variable_name = if end_use == 'Facility'
                  "#{fuel_type}:#{end_use}"
                else
                  "#{end_use}:#{fuel_type}"
                end
        result << OpenStudio::IdfObject.load("Output:Meter,#{variable_name},Hourly;").get
      end
    end

    return result
  end
  
  def outputs
    result = OpenStudio::Measure::OSOutputVector.new
    result << OpenStudio::Measure::OSOutput.makeStringOutput("electricity")
    buildstock_outputs = [
                          "natural_gas",
                          "propane",
                          "fuel_oil"
                         ]    
    buildstock_outputs.each do |output|
        result << OpenStudio::Measure::OSOutput.makeDoubleOutput(output)
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

    if !File.directory? "#{File.dirname(__FILE__)}/resources/sam-sdk-2017-1-17-r1"
      unzip_file = OpenStudio::UnzipFile.new("#{File.dirname(__FILE__)}/resources/sam-sdk-2017-1-17-r1.zip")
      unzip_file.extractAllFiles(OpenStudio::toPath("#{File.dirname(__FILE__)}/resources/sam-sdk-2017-1-17-r1"))
    end

    require "#{File.dirname(__FILE__)}/resources/ssc_api"
    
    # Assign the user inputs to variables
    run_dir = runner.getStringArgumentValue("run_dir", user_arguments)
    api_key = runner.getOptionalStringArgumentValue("api_key", user_arguments)
    api_key.is_initialized ? api_key = api_key.get : api_key = nil
    tariff_directory = runner.getOptionalStringArgumentValue("tariff_directory", user_arguments)
    tariff_directory.is_initialized ? tariff_directory = tariff_directory.get : tariff_directory = nil
    tariff_file_name = runner.getOptionalStringArgumentValue("tariff_file_name", user_arguments)
    tariff_file_name.is_initialized ? tariff_file_name = tariff_file_name.get : tariff_file_name = nil
    elec_fixed = runner.getOptionalStringArgumentValue("elec_fixed", user_arguments)
    elec_fixed.is_initialized ? elec_fixed = elec_fixed.get : elec_fixed = 0
    elec_rate = runner.getOptionalStringArgumentValue("elec_rate", user_arguments)
    elec_rate.is_initialized ? elec_rate = elec_rate.get : elec_rate = nil
    ng_fixed = runner.getOptionalStringArgumentValue("ng_fixed", user_arguments)
    ng_fixed.is_initialized ? ng_fixed = ng_fixed.get : ng_fixed = 0
    ng_rate = runner.getOptionalStringArgumentValue("ng_rate", user_arguments)
    ng_rate.is_initialized ? ng_rate = ng_rate.get : ng_rate = nil
    oil_rate = runner.getOptionalStringArgumentValue("oil_rate", user_arguments)
    oil_rate.is_initialized ? oil_rate = oil_rate.get : oil_rate = nil
    prop_rate = runner.getOptionalStringArgumentValue("prop_rate", user_arguments)
    prop_rate.is_initialized ? prop_rate = prop_rate.get : prop_rate = nil
    avg_rates = runner.getBoolArgumentValue("avg_rates", user_arguments)

    if tariff_directory == "./resources/tariffs" and elec_fixed == 0 and elec_rate.nil?
      if !File.directory? "#{File.dirname(__FILE__)}/resources/tariffs"
        unzip_file = OpenStudio::UnzipFile.new("#{File.dirname(__FILE__)}/resources/tariffs.zip")
        unzip_file.extractAllFiles(OpenStudio::toPath("#{File.dirname(__FILE__)}/resources/tariffs"))
      end
    end

    if not tariff_directory.nil?
    
      unless (Pathname.new tariff_directory).absolute?
        tariff_directory = File.expand_path(File.join(File.dirname(__FILE__), tariff_directory))
      end
      
      unless tariff_file_name.nil?
        tariff_file_name = File.join(tariff_directory, tariff_file_name)
        unless File.exists?(tariff_file_name) and tariff_file_name.downcase.end_with? ".json"
          runner.registerError("'#{tariff_file_name}' does not exist or is not a JSON file.")
          return false
        end
      end

      if !File.exist?(tariff_directory)
        FileUtils.mkdir_p(tariff_directory)
      end
      
    end
    
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
    
    timeseries = {}
    end_uses.each do |end_use|
      fuel_types.each do |fuel_type|
      
        var_name = "#{fuel_type}:#{end_use}"

        y_timeseries = sql.timeSeries(ann_env_pd, "Hourly", var_name, '')
        if y_timeseries.empty?
          runner.registerWarning("No data found for Hourly #{var_name}.")
          next
        else
          y_timeseries = y_timeseries.get
        end
        y_vals = y_timeseries.values
                    
        values = []
        y_timeseries.dateTimes.each_with_index do |date_time, i|
          values << y_vals[i]
        end

        next if values.all? {|x| x.abs < 0.000000001}
                    
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
                    
        values.each do |value|
          if timeseries.keys.include? var_name
            timeseries[var_name] << UnitConversions.convert(value, old_units, new_units)
          else
            timeseries[var_name] = [UnitConversions.convert(value, old_units, new_units)]
          end
        end
        
      end
    end

    if timeseries["ElectricityProduced:Facility"].nil?
      timeseries["ElectricityProduced:Facility"] = Array.new(timeseries["Electricity:Facility"].length, 0)
    end
    
    cols = CSV.read("#{File.dirname(__FILE__)}/resources/by_nsrdb.csv").transpose
    weather_file = model.getSite.weatherFile.get
    
    # tariffs
    tariffs = []
    rate_ids = {}

    if not tariff_file_name.nil?
      
      if File.exists?(tariff_file_name)
        tariff = JSON.parse(File.read(tariff_file_name), :symbolize_names=>true)[:items][0]
      end
      
      utility_id, getpage = File.basename(tariff_file_name).split("_")
      rate_ids[tariff[:eiaid].to_s] = [tariff[:label].to_s]
      
      ids = cols[4].collect { |i| i.to_s }
      indexes = ids.each_index.select{|i| ids[i] == tariff[:eiaid].to_s}
      utility_ids = {}
      indexes.each do |ix|
        if utility_ids.keys.include? cols[4][ix]
          utility_ids[cols[4][ix]] << cols[0][ix]
        else
          utility_ids[cols[4][ix]] = [cols[0][ix]]
        end
      end
      
    elsif not tariff_directory.nil?
    
      closest_usaf = closest_usaf_to_epw(weather_file.latitude, weather_file.longitude, cols.transpose) # minimize distance to resstock epw
      runner.registerInfo("Nearest ResStock usaf to #{File.basename(weather_file.url.get)}: #{closest_usaf}")
      
      usafs = cols[1].collect { |i| i.to_s }
      indexes = usafs.each_index.select{|i| usafs[i] == closest_usaf}
      utility_ids = {}
      indexes.each do |ix|
        next if cols[4][ix].nil?
        cols[4][ix].split("|").each do |utility_id|
          next if utility_id == "no data"
          if utility_ids.keys.include? utility_id
            utility_ids[utility_id] << cols[0][ix]
          else
            utility_ids[utility_id] = [cols[0][ix]]
          end
        end
      end

      cols = CSV.read("#{File.dirname(__FILE__)}/resources/utilities.csv", {:encoding=>'ISO-8859-1'}).transpose
      cols.each do |col|
        next unless col[0].include? "eiaid"
        utility_ids.keys.each do |utility_id|
          utility_ixs = col.each_index.select{|i| col[i] == utility_id}
          utility_ixs.each do |utility_ix|
            if rate_ids.keys.include? utility_id
              rate_ids[utility_id] << cols[3][utility_ix]
            else
              rate_ids[utility_id] = [cols[3][utility_ix]]
            end
          end
        end
      end
    
    end

    rate_ids.each do |utility_id, getpages|
      getpages.each do |getpage|
    
        runner.registerInfo("Searching cached dir on #{utility_id}_#{getpage}.json.")
        unless (Pathname.new tariff_directory).absolute?
          tariff_directory = File.expand_path(File.join(File.dirname(__FILE__), tariff_directory))
        end
        tariff_file_name = File.join(tariff_directory, "#{utility_id}_#{getpage}.json")

        if File.exists?(tariff_file_name)

          tariff = JSON.parse(File.read(tariff_file_name), :symbolize_names=>true)[:items][0]
          tariffs << tariff

        else
        
          runner.registerInfo("Could not find #{utility_id}_#{getpage}.json in cached dir.")

          if not api_key.nil?
            
            tariff = make_api_request(api_key, tariff_file_name, runner)
            if tariff.nil?
              next
            end
            tariffs << tariff

          else
          
            runner.registerInfo("Did not supply an API Key, skipping #{utility_id}_#{getpage}.")
          
          end
          
        end
        
      end
    end

    electricity_bills = []
    tariffs.each do |tariff|
    
      utility_bills = []
    
      if timeseries["Electricity:Facility"].length > 8760 # SAM can't accommodate this length

        unless tariff[:fixedmonthlycharge].nil?
          elec_fixed = 12.0 * tariff[:fixedmonthlycharge] # $
        end
        tariff[:energyratestructure].each_with_index do |period, i|
          period.each_with_index do |tier, j|
            unless tier[:adj].nil?
              elec_rate = tier[:rate] + tier[:adj]
            else
              elec_rate = tier[:rate]
            end
          end
        end
        total_val = 0
        timeseries["Electricity:Facility"].each_with_index do |val, i|
          total_val += timeseries["ElectricityProduced:Facility"][i] - timeseries["ElectricityProduced:Facility"][i] # http://bigladdersoftware.com/epx/docs/8-7/input-output-reference/input-for-output.html
        end      
        utility_bills = [total_val * elec_rate + elec_fixed]

      else    
    
        begin
      
          # utilityrate3
          p_data = SscApi.create_data_object
          SscApi.set_number(p_data, 'analysis_period', 1)
          SscApi.set_array(p_data, 'degradation', [0])
          SscApi.set_array(p_data, 'gen', timeseries["ElectricityProduced:Facility"]) # kW
          SscApi.set_array(p_data, 'load', timeseries["Electricity:Facility"]) # kW
          SscApi.set_number(p_data, 'system_use_lifetime_output', 0) # TODO: what should this be?
          SscApi.set_number(p_data, 'inflation_rate', 0) # TODO: assume what?
          SscApi.set_number(p_data, 'ur_flat_buy_rate', 0) # TODO: how to get this from list of energyratestructure rates?
          unless tariff[:fixedmonthlycharge].nil?
            SscApi.set_number(p_data, 'ur_monthly_fixed_charge', tariff[:fixedmonthlycharge]) # $
          end
          unless tariff[:demandratestructure].nil?
            SscApi.set_matrix(p_data, 'ur_dc_sched_weekday', Matrix.rows(tariff[:demandweekdayschedule]))
            SscApi.set_matrix(p_data, 'ur_dc_sched_weekend', Matrix.rows(tariff[:demandweekendschedule]))
            SscApi.set_number(p_data, 'ur_dc_enable', 1)
            tariff[:demandratestructure].each_with_index do |period, i|
              period.each_with_index do |tier, j|
                unless tier[:adj].nil?
                  SscApi.set_number(p_data, "ur_dc_p#{i+1}_t#{j+1}_dc", tier[:rate] + tier[:adj])
                else
                  SscApi.set_number(p_data, "ur_dc_p#{i+1}_t#{j+1}_dc", tier[:rate])
                end
                unless tier[:max].nil?
                  SscApi.set_number(p_data, "ur_dc_p#{i+1}_t#{j+1}_ub", tier[:max])
                else
                  SscApi.set_number(p_data, "ur_dc_p#{i+1}_t#{j+1}_ub", 1000000000.0)
                end
              end
            end
          end
          SscApi.set_number(p_data, 'ur_ec_enable', 1)
          SscApi.set_matrix(p_data, 'ur_ec_sched_weekday', Matrix.rows(tariff[:energyweekdayschedule]))
          SscApi.set_matrix(p_data, 'ur_ec_sched_weekend', Matrix.rows(tariff[:energyweekendschedule]))
          tariff[:energyratestructure].each_with_index do |period, i|
            period.each_with_index do |tier, j|
              unless tier[:adj].nil?
                SscApi.set_number(p_data, "ur_ec_p#{i+1}_t#{j+1}_br", tier[:rate] + tier[:adj])
              else
                SscApi.set_number(p_data, "ur_ec_p#{i+1}_t#{j+1}_br", tier[:rate])
              end
              unless tier[:sell].nil?
                SscApi.set_number(p_data, "ur_ec_p#{i+1}_t#{j+1}_sr", tier[:sell])
              end
              unless tier[:max].nil?
                SscApi.set_number(p_data, "ur_ec_p#{i+1}_t#{j+1}_ub", tier[:max])
              else
                SscApi.set_number(p_data, "ur_ec_p#{i+1}_t#{j+1}_ub", 1000000000.0)
              end        
            end
          end
          
          p_mod = SscApi.create_module("utilityrate3")
          SscApi.execute_module(p_mod, p_data)
          
          demand_charges_fixed = SscApi.get_array(p_data, 'charge_w_sys_dc_fixed')[1]
          demand_charges_tou = SscApi.get_array(p_data, 'charge_w_sys_dc_tou')[1]
          energy_charges_flat = SscApi.get_array(p_data, 'charge_w_sys_ec_flat')[1]
          energy_charges_tou = SscApi.get_array(p_data, 'charge_w_sys_ec')[1]

          utility_bills = SscApi.get_array(p_data, 'year1_monthly_utility_bill_w_sys')          
          
        rescue => error
        
          runner.registerWarning("#{error.backtrace}.")
          
        end
        
      end
      
      unless utility_bills.empty?
        electricity_bills << "#{tariff[:eiaid]}_#{tariff[:label]}=#{(utility_bills.inject(0){ |sum, x| sum + x }).round(2)}"
      end
      
    end

    unless electricity_bills.empty?
      runner.registerInfo("Registering electricity bills, calculated based on rate(s) in the URDB.")
      if not avg_rates
        runner.registerValue("electricity", electricity_bills.join("|"))
      else
        eiaids = {}
        electricity_bills.each do |electricity_bill|
          eiaid = electricity_bill.split("_")[0]
          cost = electricity_bill.split("=")[1].to_f
          if not eiaids.keys.include? eiaid
            eiaids[eiaid] = [cost]
          else
            eiaids[eiaid] << cost
          end
        end
        bills = []
        eiaids.each do |eiaid, costs|
          average = costs.inject(0){ |sum, x| sum + x } / costs.size
          stdev = Math.sqrt(costs.inject(0){ |var, x| var += (x - average) ** 2 } / (costs.size - 1))
          bills << "#{eiaid}:c=#{costs.length};m=#{average};s=#{stdev}"
        end
        runner.registerValue("electricity", bills.join("|"))
      end
    end

    timeseries["Electricity:Facility"].each_with_index do |val, i|
      timeseries["Electricity:Facility"][i] -= timeseries["ElectricityProduced:Facility"][i] # http://bigladdersoftware.com/epx/docs/8-7/input-output-reference/input-for-output.html
    end
    
    fuels = ["Electricity", "Natural gas", "Oil", "Propane"]
    fuels.each do |fuel|
      cols = CSV.read("#{File.dirname(__FILE__)}/resources/#{fuel}.csv", {:encoding=>'ISO-8859-1'})[3..-1].transpose
      cols[0].each_with_index do |rate_state, i|
        weather_file_state = weather_file.stateProvinceRegion
        if state_name_to_code.keys.include? weather_file_state
          weather_file_state = state_name_to_code[weather_file_state]
        end
        next unless rate_state == weather_file_state
        if fuel == "Electricity" and not timeseries["Electricity:Facility"].nil? and electricity_bills.empty?
          rate = elec_rate
          if elec_rate.nil?
            rate = cols[1][i]
          end
          report_output(runner, fuel.downcase, timeseries["Electricity:Facility"], "kWh", "kWh", rate, elec_fixed)
        elsif fuel == "Natural gas" and not timeseries["Gas:Facility"].nil?
          rate = ng_rate
          if ng_rate.nil?
            rate = cols[1][i]
          end
          report_output(runner, fuel.downcase, timeseries["Gas:Facility"], "kBtu", "therm", rate, ng_fixed)
        elsif fuel == "Oil" and not timeseries["FuelOil#1:Facility"].nil?
          rate = oil_rate
          if oil_rate.nil?
            rate = cols[1][i]
          end
          report_output(runner, fuel.downcase, timeseries["FuelOil#1:Facility"], "kBtu", "gal", rate)
        elsif fuel == "Propane" and not timeseries["Propane:Facility"].nil?
          rate = prop_rate
          if prop_rate.nil?
            rate = cols[1][i]
          end
          report_output(runner, fuel.downcase, timeseries["Propane:Facility"], "kBtu", "gal", rate)
        end
        break
      end
    end

    FileUtils.rm_rf("#{File.dirname(__FILE__)}/resources/tariffs")
    
    return true
 
  end
  
  def make_api_request(api_key, tariff_file_name, runner)
    utility_id, getpage = File.basename(tariff_file_name).split("_")
    runner.registerInfo("Making api request on getpage=#{getpage}.")
    params = {'version':3, 'format':'json', 'detail':'full', 'getpage':getpage, 'api_key':api_key}
    uri = URI('https://api.openei.org/utility_rates?')
    uri.query = URI.encode_www_form(params)
    request = Net::HTTP::Get.new(uri.request_uri)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    response = http.request(request)
    response = JSON.parse(response.body, :symbolize_names=>true)
    if response.keys.include? :error
      runner.registerError(response[:error][:message])
      return nil
    else
      File.open(tariff_file_name, "w") do |f|
        f.write(response.to_json)
      end
    end
    return response[:items][0]
  end
  
  def state_name_to_code
    return {"Alabama"=>"AL", "Alaska"=>"AK", "Arizona"=>"AZ", "Arkansas"=>"AR","California"=>"CA","Colorado"=>"CO", "Connecticut"=>"CT", "Delaware"=>"DE", "District of Columbia"=>"DC",
            "Florida"=>"FL", "Georgia"=>"GA", "Hawaii"=>"HI", "Idaho"=>"ID", "Illinois"=>"IL","Indiana"=>"IN", "Iowa"=>"IA","Kansas"=>"KS", "Kentucky"=>"KY", "Louisiana"=>"LA",
            "Maine"=>"ME","Maryland"=>"MD", "Massachusetts"=>"MA", "Michigan"=>"MI", "Minnesota"=>"MN","Mississippi"=>"MS", "Missouri"=>"MO", "Montana"=>"MT","Nebraska"=>"NE", "Nevada"=>"NV",
            "New Hampshire"=>"NH", "NewJersey"=>"NJ", "New Mexico"=>"NM", "New York"=>"NY","North Carolina"=>"NC", "North Dakota"=>"ND", "Ohio"=>"OH", "Oklahoma"=>"OK",
            "Oregon"=>"OR", "Pennsylvania"=>"PA", "Puerto Rico"=>"PR", "Rhode Island"=>"RI","South Carolina"=>"SC", "South Dakota"=>"SD", "Tennessee"=>"TN", "Texas"=>"TX",
            "Utah"=>"UT", "Vermont"=>"VT", "Virginia"=>"VA", "Washington"=>"WA", "West Virginia"=>"WV","Wisconsin"=>"WI", "Wyoming"=>"WY"}
  end
  
  def report_output(runner, name, vals, os_units, desired_units, rate, fixed=0)
    total_val = 0.0
    vals.each do |val|
      total_val += val.to_f
    end
    unless desired_units == "gal"
      runner.registerValue(name, (UnitConversions.convert(total_val, os_units, desired_units) * rate.to_f + fixed.to_f).round(2))
    else
      if name.include? "oil"
        runner.registerValue("fuel_oil", (total_val * 1000.0 / 139000 * rate.to_f + fixed.to_f).round(2))
      elsif name.include? "propane"
        runner.registerValue(name, (total_val * 1000.0 / 91600 * rate.to_f + fixed.to_f).round(2))
      end
    end
    runner.registerInfo("Registering #{name} utility bills, calculated based on the average state rate.")
  end
  
  def closest_usaf_to_epw(bldg_lat, bldg_lon, usafs)    
    distances = [1000000]
    usafs.each do |usaf|
      if (bldg_lat.to_f - usaf[3].to_f).abs > 1 and (bldg_lon.to_f - usaf[2].to_f).abs > 1 # reduce the set to save some time
        distances << 100000
        next
      end
      km = haversine(bldg_lat.to_f, bldg_lon.to_f, usaf[3].to_f, usaf[2].to_f)
      distances << km
    end    
    return usafs[distances.index(distances.min)][1]    
  end

  def haversine(lat1, lon1, lat2, lon2)
    # convert decimal degrees to radians
    [lon1, lat1, lon2, lat2].each do |l|
      l = UnitConversions.convert(l,"deg","rad")
    end
    # haversine formula 
    dlon = lon2 - lon1 
    dlat = lat2 - lat1 
    a = Math.sin(dlat/2)**2 + Math.cos(lat1) * Math.cos(lat2) * Math.sin(dlon/2)**2
    c = 2 * Math.asin(Math.sqrt(a)) 
    km = 6367 * c
    return km
  end
  
end

# register the measure to be used by the application
UtilityBillCalculations.new.registerWithApplication