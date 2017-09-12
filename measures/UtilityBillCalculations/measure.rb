# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require 'erb'
require 'csv'
require 'matrix'

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
  
  # define the arguments that the user will input
  def arguments()
    args = OpenStudio::Measure::OSArgumentVector.new
    
    arg = OpenStudio::Measure::OSArgument.makeStringArgument("run_dir", true)
    arg.setDisplayName("Run Directory")
    arg.setDescription("Relative path of the run directory.")
    arg.setDefaultValue("..")
    args << arg    
    
    arg = OpenStudio::Measure::OSArgument::makeStringArgument("api_key", false)
    arg.setDisplayName("EIA API Key")
    arg.setDescription("Call the API and find EIA ID(s) matching the epw.")
    args << arg
    
    arg = OpenStudio::Measure::OSArgument::makeStringArgument("json_file_path", false)
    arg.setDisplayName("JSON File Path")
    arg.setDescription("Provide this instead of calling the API.")
    args << arg
    
    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("analysis_period", false)
    arg.setDisplayName("Analysis Period")
    arg.setUnits("yrs")
    arg.setDefaultValue(1)
    args << arg
    
    return args
  end
  
  def outputs
    result = OpenStudio::Measure::OSOutputVector.new
    result << OpenStudio::Measure::OSOutput.makeStringOutput("grid_cells")
    result << OpenStudio::Measure::OSOutput.makeStringOutput("total_electricity")
    buildstock_outputs = [
                          "total_natural_gas",
                          "total_propane",
                          "total_fuel_oil"
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
    json_file_path = runner.getOptionalStringArgumentValue("json_file_path", user_arguments)
    json_file_path.is_initialized ? json_file_path = json_file_path.get : json_file_path = nil
    analysis_period = runner.getDoubleArgumentValue("analysis_period",user_arguments)
    
    unless json_file_path.nil?
      unless (Pathname.new json_file_path).absolute?
        json_file_path = File.expand_path(File.join(File.dirname(__FILE__), json_file_path))
      end 
      unless File.exists?(json_file_path) and json_file_path.downcase.end_with? ".json"
        runner.registerError("'#{json_file_path}' does not exist or is not a .json file.")
        return false
      end
    end
    
    # load profile
    cols = CSV.read(File.expand_path(File.join(run_dir, "enduse_timeseries.csv"))).transpose
    elec_load = nil
    elec_generated = nil
    gas_load = nil
    cols.each do |col|
      if col[0].include? "Electricity:Facility"
        elec_load = col[1..-1]
      elsif col[0].include? "PV:Electricity"
        elec_generated = col[1..-1]
      elsif col[0].include? "Gas:Facility"
        gas_load = col[1..-1]
      end
    end
    
    if elec_generated.nil?
      elec_generated = Array.new(elec_load.length, 0)
    end
    
    cols = CSV.read("#{File.dirname(__FILE__)}/resources/by_nsrdb.csv").transpose
    weather_file = runner.lastOpenStudioModel.get.getSite.weatherFile.get
    
    # tariffs
    tariffs = {}
    if not json_file_path.nil?

      tariff = JSON.parse(File.read(json_file_path), :symbolize_names=>true)[:items][0]
      tariffs[tariff[:label]] = [tariff[:eiaid].to_s, tariff]
      
      ids = cols[20].collect { |i| i.to_s }
      indexes = ids.each_index.select{|i| ids[i] == tariff[:eiaid].to_s}
      utility_ids = {}
      indexes.each do |ix|
        if utility_ids.keys.include? cols[20][ix]
          utility_ids[cols[20][ix]] << cols[0][ix]
        else
           utility_ids[cols[20][ix]] = [cols[0][ix]]
        end
      end
      
    elsif not api_key.nil?
      
      closest_usaf = closest_usaf_to_epw(weather_file.latitude, weather_file.longitude, cols.transpose) # minimize distance to resstock epw
      runner.registerInfo("Nearest ResStock usaf to #{File.basename(weather_file.url.get)}: #{closest_usaf}")
      
      usafs = cols[1].collect { |i| i.to_s }
      indexes = usafs.each_index.select{|i| usafs[i] == closest_usaf}
      utility_ids = {}
      indexes.each do |ix|
        next if cols[20][ix].nil?
        cols[20][ix].split("|").each do |utility_id|        
          if utility_ids.keys.include? utility_id
            utility_ids[utility_id] << cols[0][ix]
          else
             utility_ids[utility_id] = [cols[0][ix]]
          end
        end
      end
    
      utility_ixs = []
      cols = CSV.read("#{File.dirname(__FILE__)}/resources/utilities.csv", {:encoding=>'ISO-8859-1'}).transpose
      cols.each do |col|
        unless col[0].nil?
          if col[0].include? "eiaid"
            eia_ids = col.collect { |i| i.to_i.to_s }            
            utility_ids.keys.each do |utility_id|
              utility_ix = col.index(utility_id)
              if utility_ix.nil?
                runner.registerWarning("Could not find EIA Utility ID: #{utility_id}.")
              else
                utility_ixs << [utility_id, utility_ix]
              end
            end
          end
        end
      end
      
      utility_ixs.each do |utility_id, utility_ix|
        getpage = cols[3][utility_ix]
        runner.registerInfo("Processing api request on getpage=#{getpage}.")
        uri = URI('http://api.openei.org/utility_rates?')
        params = {'version':3, 'format':'json', 'detail':'full', 'getpage':getpage, 'api_key':api_key}
        uri.query = URI.encode_www_form(params)
        response = Net::HTTP.get_response(uri)
        response = JSON.parse(response.body, :symbolize_names=>true)
        if response.keys.include? :error
          runner.registerError(response[:error][:message])
          return false
        end
        tariffs[getpage] = [utility_id, response[:items][0]]
      end
      
    else
      runner.registerError("Did not supply an API Key or a JSON File Path.")
      return false
    end
    
    grid_cells = []
    electricity_bills = []
    tariffs.each do |getpage, tariff|
    
      # utilityrate3
      p_data = SscApi.create_data_object
      SscApi.set_number(p_data, 'analysis_period', 1)
      SscApi.set_array(p_data, 'degradation', [0])
      SscApi.set_array(p_data, 'gen', elec_generated) # kW
      SscApi.set_array(p_data, 'load', elec_load) # kW
      SscApi.set_number(p_data, 'system_use_lifetime_output', 0) # TODO: what should this be?
      SscApi.set_number(p_data, 'inflation_rate', 0) # TODO: assume what?
      SscApi.set_number(p_data, 'ur_flat_buy_rate', 0) # TODO: how to get this from list of energyratestructure rates?
      next if tariff[1][:fixedmonthlycharge].nil?
      SscApi.set_number(p_data, 'ur_monthly_fixed_charge', tariff[1][:fixedmonthlycharge]) # $
      unless tariff[1][:demandratestructure].nil?
        SscApi.set_matrix(p_data, 'ur_dc_sched_weekday', Matrix.rows(tariff[1][:demandweekdayschedule]))
        SscApi.set_matrix(p_data, 'ur_dc_sched_weekend', Matrix.rows(tariff[1][:demandweekendschedule]))
        SscApi.set_number(p_data, 'ur_dc_enable', 1)
        tariff[1][:demandratestructure].each_with_index do |period, i|
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
      SscApi.set_matrix(p_data, 'ur_ec_sched_weekday', Matrix.rows(tariff[1][:energyweekdayschedule]))
      SscApi.set_matrix(p_data, 'ur_ec_sched_weekend', Matrix.rows(tariff[1][:energyweekendschedule]))
      tariff[1][:energyratestructure].each_with_index do |period, i|
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
      # SscApi.set_print(false)
      SscApi.execute_module(p_mod, p_data)
      
      # demand charges fixed
      demand_charges_fixed = SscApi.get_array(p_data, 'charge_w_sys_dc_fixed')[1]
      # runner.registerInfo("Registering $#{demand_charges_fixed} for fixed annual demand charges.")    
      
      # demand charges tou
      demand_charges_tou = SscApi.get_array(p_data, 'charge_w_sys_dc_tou')[1]
      # runner.registerInfo("Registering $#{demand_charges_tou} for tou annual demand charges.")
      
      # demand charges
      # runner.registerValue("Annual Demand Charge", demand_charges_tou + demand_charges_fixed)
      
      # energy charges flat
      energy_charges_flat = SscApi.get_array(p_data, 'charge_w_sys_ec_flat')[1]
      # runner.registerInfo("Registering $#{energy_charges_flat} for flat annual energy charges.")    
      
      # energy charges tou
      energy_charges_tou = SscApi.get_array(p_data, 'charge_w_sys_ec')[1]
      # runner.registerInfo("Registering $#{energy_charges_tou} for tou annual energy charges.")
      
      # energy charges
      # runner.registerValue("Annual Energy Charge", energy_charges_tou + energy_charges_flat)
      
      # annual bill
      utility_bills = SscApi.get_array(p_data, 'year1_monthly_utility_bill_w_sys')
      
      # puts "annual demand charges: $#{(demand_charges_tou + demand_charges_fixed).round(2)}"
      # puts "annual energy charges: $#{(energy_charges_tou + energy_charges_flat).round(2)}"
      # puts "annual utility bill: $#{(utility_bills.inject(0){ |sum, x| sum + x }).round(2)}"

      grid_cells << utility_ids[tariff[0]] * ";"
      electricity_bills << "#{tariff[0]}=#{(utility_bills.inject(0){ |sum, x| sum + x }).round(2)}"
      
    end
    
    runner.registerValue("grid_cells", grid_cells.join("|"))
    runner.registerValue("total_electricity", electricity_bills.join("|"))
    runner.registerInfo("Registering electricity bills.")
    
    fuels = ["Natural gas"]
    fuels.each do |fuel|
      cols = CSV.read("#{File.dirname(__FILE__)}/resources/#{fuel}.csv", {:encoding=>'ISO-8859-1'})[3..-1].transpose
      cols[0].each_with_index do |state, i|
        next unless state == weather_file.stateProvinceRegion
        report_output(runner, "total_#{fuel.downcase}", gas_load, "kBtu", "therm", cols[1][i], fuel)
        break
      end
    end

    return true
 
  end
  
  def report_output(runner, name, vals, os_units, desired_units, rate, fuel)
    total_val = 0.0
    vals.each do |val|
        total_val += val.to_f
    end
    runner.registerValue(name, (OpenStudio::convert(total_val, os_units, desired_units).get * rate.to_f).round(2))
    runner.registerInfo("Registering #{fuel.downcase} utility bills.")
  end
  
  def closest_usaf_to_epw(bldg_lat, bldg_lon, usafs)
    distances = [1000000]
    usafs.each do |usaf|
      if (bldg_lat.to_f - usaf[19].to_f).abs > 1 and (bldg_lon.to_f - usaf[18].to_f).abs > 1 # reduce the set to save some time
        distances << 100000
        next
      end
      km = haversine(bldg_lat.to_f, bldg_lon.to_f, usaf[19].to_f, usaf[18].to_f)
      distances << km
    end    
    return usafs[distances.index(distances.min)][1]    
  end

  def haversine(lat1, lon1, lat2, lon2)
    # convert decimal degrees to radians
    [lon1, lat1, lon2, lat2].each do |l|
      l = OpenStudio.convert(l,"deg","rad").get
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