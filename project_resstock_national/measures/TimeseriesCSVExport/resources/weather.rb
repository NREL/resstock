require "#{File.dirname(__FILE__)}/psychrometrics"
require "#{File.dirname(__FILE__)}/constants"
require "#{File.dirname(__FILE__)}/unit_conversions"

class WeatherHeader
  def initialize
  end
  ATTRS ||= [:City, :State, :Country, :DataSource, :Station, :Latitude, :Longitude, :Timezone, :Altitude, :LocalPressure]
  attr_accessor(*ATTRS)
end

class WeatherData
  def initialize
  end
  ATTRS ||= [:AnnualAvgDrybulb, :AnnualMinDrybulb, :AnnualMaxDrybulb, :CDD50F, :CDD65F, :HDD50F, :HDD65F, :AnnualAvgWindspeed, :MonthlyAvgDrybulbs, :MainsDailyTemps, :MainsMonthlyTemps, :MainsAvgTemp, :GroundMonthlyTemps, :WSF, :MonthlyAvgDailyHighDrybulbs, :MonthlyAvgDailyLowDrybulbs]
  attr_accessor(*ATTRS)
end

class WeatherDesign
  def initialize
  end
  ATTRS ||= [:HeatingDrybulb, :HeatingWindspeed, :CoolingDrybulb, :CoolingWetbulb, :CoolingHumidityRatio, :CoolingWindspeed, :DailyTemperatureRange, :DehumidDrybulb, :DehumidHumidityRatio, :CoolingDirectNormal, :CoolingDiffuseHorizontal]
  attr_accessor(*ATTRS)
end

class WeatherProcess

  def initialize(model, runner, measure_dir)
  
    @error = false
    
    @model = model
    @runner = runner
    @measure_dir = measure_dir
    
    @header = WeatherHeader.new
    @data = WeatherData.new
    @design = WeatherDesign.new
    
    @epw_path = WeatherProcess.get_epw_path(model, runner, measure_dir)
    if @epw_path.nil?
      @error = true
      return
    end
    
    unit = get_weather_building_unit(model)
  
    cached = get_cached_weather(unit)
    return if cached or @error
    
    process_epw(@epw_path)
    return if @error
    
    cache_weather(unit)
      
  end

  def epw_path
    return @epw_path
  end
  
  def self.actual_timestamps(model, runner, measure_dir)
    epw_path = get_epw_path(model, runner, measure_dir)
    epw_file = OpenStudio::EpwFile.new(epw_path)
    if epw_file.startDateActualYear.is_initialized
      actual_timestamps = []
      epw_file.data.each do |epw_data_row|
        year = epw_data_row.year
        month = epw_data_row.month.to_s.rjust(2, "0")
        day = epw_data_row.day.to_s.rjust(2, "0")
        hour = epw_data_row.hour.to_s.rjust(2, "0")
        minute = epw_data_row.minute.to_s.rjust(2, "0")
        second = "00"
        actual_timestamps << "#{year}/#{month}/#{day} #{hour}:#{minute}:#{second}"
      end
      return actual_timestamps
    end
    return []
  end
  
  def error?
    return @error
  end
  
  attr_accessor(:header, :data, :design)
  
  private
  
      def self.get_epw_path(model, runner, measure_dir)
        if model.weatherFile.is_initialized
        
          wf = model.weatherFile.get
          # Sometimes path is available, sometimes just url. Should be improved in OS 2.0.
          if wf.path.is_initialized
            epw_path = wf.path.get.to_s
          else
            epw_path = wf.url.to_s.sub("file:///","").sub("file://","").sub("file:","")
          end
          if not File.exist? epw_path # Handle relative paths for unit tests
            epw_path2 = File.join(measure_dir, "resources", epw_path)
            if File.exist? epw_path2
                epw_path = epw_path2
            end
          end
          return epw_path
        end
        
        runner.registerError("Model has not been assigned a weather file.")
        return nil
      end
  
      def get_weather_building_unit(model)
        unit_name = "EPWWeatherInfo"
        
        # Look for existing unit with weather data
        unit = nil
        model.getBuildingUnits.each do |u|
          next if u.name.to_s != unit_name
          unit = u
        end
        
        if unit.nil?
          # Create new unit to store weather data
          unit = OpenStudio::Model::BuildingUnit.new(model)
          unit.setBuildingUnitType("Residential")
          unit.setName(unit_name)
        end
        
        return unit
        
      end
      
      def cache_weather(unit)
        
        # Header
        WeatherHeader::ATTRS.each do |k|
          k = k.to_s
          # string
          if ['City','State','Country','DataSource','Station'].include? k
            unit.setFeature("EPWHeader#{k}", @header.send(k).to_s)
          # double
          elsif ['Latitude','Longitude','Timezone','Altitude','LocalPressure'].include? k
            unit.setFeature("EPWHeader#{k}", @header.send(k).to_f)
          else
            @runner.registerError("Weather header key #{k} not handled.")
            @error = true
            return false
          end
        end
        
        # Data
        WeatherData::ATTRS.each do |k|
          k = k.to_s
          # double
          if ['AnnualAvgDrybulb','AnnualMinDrybulb','AnnualMaxDrybulb','CDD50F','CDD65F',
                 'HDD50F','HDD65F','AnnualAvgWindspeed','MainsAvgTemp','WSF'].include? k
            unit.setFeature("EPWData#{k}", @data.send(k).to_f)
          # array
          elsif ['MonthlyAvgDrybulbs','MainsDailyTemps','MainsMonthlyTemps','GroundMonthlyTemps',
                 'MonthlyAvgDailyHighDrybulbs','MonthlyAvgDailyLowDrybulbs'].include? k
            unit.setFeature("EPWData#{k}", @data.send(k).join(","))
          else
            @runner.registerError("Weather data key #{k} not handled.")
            @error = true
            return false
          end
        end
        
        # Design
        WeatherDesign::ATTRS.each do |k|
          k = k.to_s
          # double
          unit.setFeature("EPWDesign#{k}", @design.send(k).to_f)
        end
        
      end
  
      def get_cached_weather(unit)
        
        # Header
        WeatherHeader::ATTRS.each do |k|
          k = k.to_s
          # string
          if ['City','State','Country','DataSource','Station'].include? k
            @header.send(k+"=", unit.getFeatureAsString("EPWHeader#{k}"))
            return false if !@header.send(k).is_initialized
            @header.send(k+"=", @header.send(k).get)
          # double
          elsif ['Latitude','Longitude','Timezone','Altitude','LocalPressure'].include? k
            @header.send(k+"=", unit.getFeatureAsDouble("EPWHeader#{k}"))
            return false if !@header.send(k).is_initialized
            @header.send(k+"=", @header.send(k).get)
          else
            @runner.registerError("Weather header key #{k} not handled.")
            @error = true
            return false
          end
        end
        
        # Data
        WeatherData::ATTRS.each do |k|
          k = k.to_s
          # double
          if ['AnnualAvgDrybulb','AnnualMinDrybulb','AnnualMaxDrybulb','CDD50F','CDD65F',
                 'HDD50F','HDD65F','AnnualAvgWindspeed','MainsAvgTemp','WSF'].include? k
            @data.send(k+"=", unit.getFeatureAsDouble("EPWData#{k}"))
            return false if !@data.send(k).is_initialized
            @data.send(k+"=", @data.send(k).get)
          # array
          elsif ['MonthlyAvgDrybulbs','MainsDailyTemps','MainsMonthlyTemps','GroundMonthlyTemps',
                 'MonthlyAvgDailyHighDrybulbs','MonthlyAvgDailyLowDrybulbs'].include? k
            @data.send(k+"=", unit.getFeatureAsString("EPWData#{k}"))
            return false if !@data.send(k).is_initialized
            @data.send(k+"=", @data.send(k).get.split(",").map(&:to_f))
          else
            @runner.registerError("Weather data key #{k} not handled.")
            @error = true
            return false
          end
        end
        
        # Design
        WeatherDesign::ATTRS.each do |k|
          k = k.to_s
          # double
          @design.send(k+"=", unit.getFeatureAsDouble("EPWDesign#{k}"))
          return false if !@design.send(k).is_initialized
          @design.send(k+"=", @design.send(k).get)
        end
        
        return true
      end
  
      def process_epw(epw_path)
        if not File.exist?(epw_path)
          @runner.registerError("Cannot find weather file at #{epw_path}.")
          @error = true
          return
        end

        epw_file = OpenStudio::EpwFile.new(epw_path, true)

        # Header info:
        @header.City = epw_file.city
        @header.State = epw_file.stateProvinceRegion
        @header.Country = epw_file.country
        @header.DataSource = epw_file.dataSource
        @header.Station = epw_file.wmoNumber
        @header.Latitude = epw_file.latitude
        @header.Longitude = epw_file.longitude
        @header.Timezone = epw_file.timeZone
        @header.Altitude = UnitConversions.convert(epw_file.elevation,"m","ft")
        @header.LocalPressure = Math::exp(-0.0000368 * @header.Altitude) # atm
        
        ddy_path = epw_path.gsub(".epw",".ddy")
        epwHasDesignData = false
        if File.exist?(ddy_path)
          epwHasDesignData = true
          @design = get_design_info_from_ddy(@design, ddy_path, @header.Altitude)
        end
        
        # Timeseries data:
        epw_file_data = epw_file.data
        hourdata = []
        dailydbs = []
        dailyhighdbs = []
        dailylowdbs = []
        epw_file_data.each_with_index do |epwdata, hournum|

          hourdict = {}
          hourdict['month'] = epwdata.month
          hourdict['day'] = epwdata.day
          hourdict['hour'] = epwdata.hour
          if epwdata.dryBulbTemperature.is_initialized
            hourdict['db'] = epwdata.dryBulbTemperature.get
          else
            @runner.registerError("Cannot retrieve dryBulbTemperature from the EPW for hour #{hournum+1}.")
            @error = true
          end
          if epwdata.dewPointTemperature.is_initialized
            hourdict['dp'] = epwdata.dewPointTemperature.get
          else
            @runner.registerError("Cannot retrieve dewPointTemperature from the EPW for hour #{hournum+1}.")
            @error = true
          end
          if epwdata.relativeHumidity.is_initialized
            hourdict['rh'] = epwdata.relativeHumidity.get / 100.0
          else
            @runner.registerError("Cannot retrieve relativeHumidity from the EPW for hour #{hournum+1}.")
            @error = true
          end
          #if epwdata.extraterrestrialHorizontalRadiation.is_initialized
          #  hourdict['ethoriz'] = epwdata.extraterrestrialHorizontalRadiation.get
          #else
          #  @runner.registerError("Cannot retrieve extraterrestrialHorizontalRadiation from the EPW for hour #{hournum+1}.")
          #  @error = true
          #end
          #if epwdata.globalHorizontalRadiation.is_initialized
          #  hourdict['ghoriz'] = epwdata.globalHorizontalRadiation.get
          #else
          #  @runner.registerError("Cannot retrieve globalHorizontalRadiation from the EPW for hour #{hournum+1}.")
          #  @error = true
          #end
          if epwdata.directNormalRadiation.is_initialized
            hourdict['dirnormal'] = epwdata.directNormalRadiation.get # W/m^2
          else
            @runner.registerError("Cannot retrieve directNormalRadiation from the EPW for hour #{hournum+1}.")
            @error = true
          end
          if epwdata.diffuseHorizontalRadiation.is_initialized
            hourdict['diffhoriz'] = epwdata.diffuseHorizontalRadiation.get # W/m^2
          else
            @runner.registerError("Cannot retrieve diffuseHorizontalRadiation from the EPW for hour #{hournum+1}.")
            @error = true
          end
          if epwdata.windSpeed.is_initialized
            hourdict['ws'] = epwdata.windSpeed.get
          else
            @runner.registerError("Cannot retrieve windSpeed from the EPW for hour #{hournum+1}.")
            @error = true
          end
          if @error
            return
          end
          hourdata << hourdict

          if (hournum + 1) % 24 == 0

            db = []
            maxdb = hourdata[hourdata.length - 24]['db']
            mindb = hourdata[hourdata.length - 24]['db']
            hourdata[hourdata.length - 24..-1].each do |x|
              if x['db'] > maxdb
                maxdb = x['db']
              end
              if x['db'] < mindb
                mindb = x['db']
              end
              db << x['db']
            end

            dailydbs << db.inject{ |sum, n| sum + n } / 24.0
            dailyhighdbs << maxdb
            dailylowdbs << mindb

          end

        end

        @data = calc_annual_drybulbs(@data, hourdata)
        @data = calc_monthly_drybulbs(@data, hourdata)
        @data = calc_heat_cool_degree_days(@data, hourdata, dailydbs)
        @data = calc_avg_highs_lows(@data, dailyhighdbs, dailylowdbs)
        @data = calc_avg_windspeed(@data, hourdata)
        @data = calc_mains_temperature(@data, @header)
        @data = calc_ground_temperatures(@data)
        @data.WSF = get_ashrae_622_wsf(@header.Station)
        
        if not epwHasDesignData
          @runner.registerWarning("No DDY file found; calculating design conditions from EPW weather data.")
          @design = calc_design_info(@design, hourdata, @header.Altitude)
          @design.DailyTemperatureRange = @data.MonthlyAvgDailyHighDrybulbs[7] - @data.MonthlyAvgDailyLowDrybulbs[7]
        end
        
        @design = calc_design_solar_radiation(@design, hourdata)

      end

      def calc_annual_drybulbs(data, hd)
        # Calculates and stores annual average, minimum, and maximum drybulbs
        db = []
        mindict = hd[0]
        maxdict = hd[0]
        hd.each do |x|
          if x['db'] > maxdict['db']
            maxdict = x
          end
          if x['db'] < mindict['db']
            mindict = x
          end
          db << x['db']
        end

        data.AnnualAvgDrybulb = UnitConversions.convert(db.inject{ |sum, n| sum + n } / 8760.0,"C","F")

        # Peak temperatures:
        data.AnnualMinDrybulb = UnitConversions.convert(mindict['db'],"C","F")
        data.AnnualMaxDrybulb = UnitConversions.convert(maxdict['db'],"C","F")

        return data

      end

      def calc_monthly_drybulbs(data, hd)
        # Calculates and stores monthly average drybulbs
        data.MonthlyAvgDrybulbs = []
        (1...13).to_a.each do |month|
          y = []
          hd.each do |x|
            if x['month'] == month
              y << x['db']
            end
          end
          month_dbtotal = y.inject{ |sum, n| sum + n }
          month_hours = y.length
          data.MonthlyAvgDrybulbs << UnitConversions.convert(month_dbtotal / month_hours,"C","F")
        end

        return data
      end

      def calc_avg_windspeed(data, hd)
        # Calculates and stores annual average windspeed
        ws = []
        hd.each do |x|
          ws << x['ws']
        end
        avgws = ws.inject{ |sum, n| sum + n } / 8760.0
        data.AnnualAvgWindspeed = avgws
        return data
      end

      def calc_heat_cool_degree_days(data, hd, dailydbs)
        # Calculates and stores heating/cooling degree days
        data.HDD65F = calc_degree_days(dailydbs, 65, true)
        data.HDD50F = calc_degree_days(dailydbs, 50, true)
        data.CDD65F = calc_degree_days(dailydbs, 65, false)
        data.CDD50F = calc_degree_days(dailydbs, 50, false)

        return data

      end

      def calc_degree_days(daily_dbs, base_temp_f, is_heating)
        # Calculates and returns degree days from a base temperature for either heating or cooling
        base_temp_c = UnitConversions.convert(base_temp_f,"F","C")

        deg_days = []
        if is_heating
          daily_dbs.each do |x|
            if x < base_temp_c
              deg_days << base_temp_c - x
            end
          end
        else
          daily_dbs.each do |x|
            if x > base_temp_c
              deg_days << x - base_temp_c
            end
          end
        end
        if deg_days.size == 0
          return 0.0
        end
        deg_days = deg_days.inject{ |sum, n| sum + n }
        return 1.8 * deg_days

      end
      
      def calc_avg_highs_lows(data, daily_high_dbs, daily_low_dbs)
        # Calculates and stores avg daily highs and lows for each month
        data.MonthlyAvgDailyHighDrybulbs = []
        data.MonthlyAvgDailyLowDrybulbs = []
        
        first_day = 0
        for month in 1..12
          ndays = Constants.MonthNumDays[month-1]  # Number of days in current month
          if month > 1
            first_day += Constants.MonthNumDays[month-2]  # Number of days in previous month
          end
          avg_high = daily_high_dbs[first_day, ndays].inject{ |sum, n| sum + n } / ndays.to_f
          avg_low = daily_low_dbs[first_day, ndays].inject{ |sum, n| sum + n } / ndays.to_f
          data.MonthlyAvgDailyHighDrybulbs << UnitConversions.convert(avg_high,"C","F")
          data.MonthlyAvgDailyLowDrybulbs << UnitConversions.convert(avg_low,"C","F")
        end
        return data
      end
      
      def calc_design_solar_radiation(design, hourdata)
        # Calculate cooling design day info, for roof surface sol air temperature, which is used for attic temperature calculation for Manual J/ASHRAE Std 152: 
        # Max summer direct normal solar radiation
        # Diffuse horizontal solar radiation during hour with max direct normal
        summer_hourdata = []
        months = [6,7,8,9]
        for hr in 0..(hourdata.size - 1)
            next if not months.include?(hourdata[hr]['month'])
            summer_hourdata << hourdata[hr]
        end
        
        r_d = (1 + Math::cos(26.565052 * Math::PI / 180 ))/2 # Correct diffuse horizontal for tilt. Assume 6:12 roof pitch for this calculation.
        max_solar_radiation_hour = summer_hourdata[0]
        for hr in 1..(summer_hourdata.size - 1)
            next if summer_hourdata[hr]['dirnormal'] + summer_hourdata[hr]['diffhoriz'] * r_d < max_solar_radiation_hour['dirnormal'] + max_solar_radiation_hour['diffhoriz'] * r_d
            max_solar_radiation_hour = summer_hourdata[hr]
        end
        
        design.CoolingDirectNormal = max_solar_radiation_hour['dirnormal']
        design.CoolingDiffuseHorizontal = max_solar_radiation_hour['diffhoriz']
        return design
      end

      def calc_mains_temperature(data, header)
        #Calculates and returns the annual average, daily, and monthly mains water temperature
        #Only use this method if no OS:Site:WaterMainsTemperature object exists.
        
        avgOAT = data.AnnualAvgDrybulb
        maxDiffMonthlyAvgOAT = data.MonthlyAvgDrybulbs.max - data.MonthlyAvgDrybulbs.min

        data.MainsAvgTemp, data.MainsMonthlyTemps, data.MainsDailyTemps = WeatherProcess._calculate_mains_temperature(avgOAT, maxDiffMonthlyAvgOAT, header.Latitude)
        
        return data
      end
      
      def self.get_mains_temperature(waterMainsTemperature, latitude)
        #Use this static method if OS:Site:WaterMainsTemperature object exists.
        if waterMainsTemperature.calculationMethod == 'Schedule'
          # We only currently support the Correlation method
          return nil, nil, nil
        end
        
        avgOAT = UnitConversions.convert(waterMainsTemperature.annualAverageOutdoorAirTemperature.get, "C", "F")
        maxDiffMonthlyAvgOAT = UnitConversions.convert(waterMainsTemperature.maximumDifferenceInMonthlyAverageOutdoorAirTemperatures.get, "K", "R")
        
        return self._calculate_mains_temperature(avgOAT, maxDiffMonthlyAvgOAT, latitude)
      end
      
      def get_ashrae_622_wsf(wmo)
        # Looks up the ASHRAE 62.2 weather and shielding factor from ASHRAE622WSF
        # for the specified WMO station number. If not found, uses the average value 
        # in the file.
            
        # Sets the WSF value.
        
        ashrae_csv = File.join(@measure_dir, 'ASHRAE622WSF.csv')
        if not File.exists?(ashrae_csv)
          return nil
        end
        
        ashrae_csvlines = []
        File.open(ashrae_csv) do |file|
          # if not os.path.exists(ashrae_csv):
          #    raise IOError("Cannot find file " + ashrae_csv)
          file.each do |line|
            line = line.strip.chomp.chomp(',').chomp # remove RHS whitespace and extra comma
            ashrae_csvlines << line
          end
        end
        
        keys = ashrae_csvlines.delete_at(0).split(',')
        ashrae_dict = []
        ashrae_csvlines.each do |line|
          line = line.split(',')
          ashrae_dict << Hash[keys.zip(line)]
        end
          
        wsfs = []
        ashrae_dict.each do |adict|
          if adict['TMY3'] == wmo
            return adict['wsf'].to_f
          end
          wsfs << adict['wsf'].to_f
        end
        
        # Value not found, use average
        wsf_avg = wsfs.inject{ |sum, n| sum + n } / wsfs.length
        @runner.registerWarning("ASHRAE 62.2 WSF not found for station number #{wmo.to_s}, using the national average value of #{wsf_avg.round(3).to_s} instead.")
        return wsf_avg
            
      end
      
      def get_design_info_from_ddy(design, ddy_path, altitude)
        ddy_model = OpenStudio::EnergyPlus.loadAndTranslateIdf(ddy_path).get
        dehum02per_dp = nil
        ddy_model.getObjectsByType("OS:SizingPeriod:DesignDay".to_IddObjectType).each do |d|
          designDay = d.to_DesignDay.get
          if d.name.get.include?("Ann Htg 99% Condns DB")
            design.HeatingDrybulb = UnitConversions.convert(designDay.maximumDryBulbTemperature,"C","F")
          elsif d.name.get.include?("Ann Htg Wind 99% Condns WS=>MCDB")
            # FIXME: Is this correct? Or should be wind speed coincident with heating drybulb?
            design.HeatingWindspeed = designDay.windSpeed
          elsif d.name.get.include?("Ann Clg 1% Condns DB=>MWB")
            design.CoolingDrybulb = UnitConversions.convert(designDay.maximumDryBulbTemperature,"C","F")
            design.CoolingWetbulb = UnitConversions.convert(designDay.humidityIndicatingConditionsAtMaximumDryBulb,"C","F")
            design.CoolingWindspeed = designDay.windSpeed
            design.DailyTemperatureRange = UnitConversions.convert(designDay.dailyDryBulbTemperatureRange,"K","R")
          elsif d.name.get.include?("Ann Clg 2% Condns DP=>MDB")
            design.DehumidDrybulb = UnitConversions.convert(designDay.maximumDryBulbTemperature,"C","F")
            dehum02per_dp = UnitConversions.convert(designDay.humidityIndicatingConditionsAtMaximumDryBulb,"C","F")
          end
        end
        std_press = Psychrometrics.Pstd_fZ(altitude)
        design.CoolingHumidityRatio = Psychrometrics.w_fT_Twb_P(design.CoolingDrybulb, design.CoolingWetbulb, std_press)
        design.DehumidHumidityRatio = Psychrometrics.w_fT_Twb_P(dehum02per_dp, dehum02per_dp, std_press)
        return design
      end
      
      def calc_design_info(design, hourdata, altitude)
        # Calculate design day info: 
        # - Heating 99% drybulb
        # - Heating mean coincident windspeed 
        # - Cooling 99% drybulb
        # - Cooling mean coincident windspeed
        # - Cooling mean coincident wetbulb
        # - Cooling mean coincident humidity ratio
        
        std_press = Psychrometrics.Pstd_fZ(altitude)
        annual_hd_sorted_by_db = hourdata.sort_by { |x| x['db'] }
        annual_hd_sorted_by_dp = hourdata.sort_by { |x| x['dp'] }
        
        # 1%/99%/2% values
        heat99per_db = annual_hd_sorted_by_db[88]['db']
        cool01per_db = annual_hd_sorted_by_db[8673]['db']
        dehum02per_dp = annual_hd_sorted_by_dp[8584]['dp']
        
        # Mean coincident values for cooling
        cool_windspeed = []
        cool_wetbulb = []
        for i in 0..(annual_hd_sorted_by_db.size - 1)
          if (annual_hd_sorted_by_db[i]['db'] > cool01per_db - 0.5) and (annual_hd_sorted_by_db[i]['db'] < cool01per_db + 0.5)
            cool_windspeed << annual_hd_sorted_by_db[i]['ws']
            wb = Psychrometrics.Twb_fT_R_P(UnitConversions.convert(annual_hd_sorted_by_db[i]['db'],"C","F"), annual_hd_sorted_by_db[i]['rh'], std_press)
            cool_wetbulb << wb
          end
        end
        cool_design_wb = cool_wetbulb.inject{ |sum, n| sum + n } / cool_wetbulb.size
        
        # Mean coincident values for heating
        heat_windspeed = []
        for i in 0..(annual_hd_sorted_by_db.size - 1)
          if (annual_hd_sorted_by_db[i]['db'] > heat99per_db - 0.5) and (annual_hd_sorted_by_db[i]['db'] < heat99per_db + 0.5)
            heat_windspeed << annual_hd_sorted_by_db[i]['ws']
          end
        end
        
        # Mean coincident values for dehumidification
        dehum_drybulb = []
        for i in 0..(annual_hd_sorted_by_dp.size - 1)
          if (annual_hd_sorted_by_dp[i]['dp'] > dehum02per_dp - 0.5) and (annual_hd_sorted_by_dp[i]['dp'] < dehum02per_dp + 0.5)
            dehum_drybulb << annual_hd_sorted_by_dp[i]['db']
          end
        end
        dehum_design_db = dehum_drybulb.inject{ |sum, n| sum + n } / dehum_drybulb.size
        

        design.CoolingDrybulb = UnitConversions.convert(cool01per_db,"C","F")
        design.CoolingWetbulb = cool_design_wb
        design.CoolingHumidityRatio = Psychrometrics.w_fT_Twb_P(design.CoolingDrybulb, design.CoolingWetbulb, std_press)
        design.CoolingWindspeed = cool_windspeed.inject{ |sum, n| sum + n } / cool_windspeed.size
        
        design.HeatingDrybulb = UnitConversions.convert(heat99per_db,"C","F")
        design.HeatingWindspeed = heat_windspeed.inject{ |sum, n| sum + n } / heat_windspeed.size
        
        design.DehumidDrybulb = UnitConversions.convert(dehum_design_db,"C","F")
        design.DehumidHumidityRatio = Psychrometrics.w_fT_Twb_P(UnitConversions.convert(dehum02per_dp,"C","F"), UnitConversions.convert(dehum02per_dp,"C","F"), std_press)
        
        return design
        
      end
      
      def calc_ground_temperatures(data)
        # Return monthly ground temperatures.

        amon = [15.0, 46.0, 74.0, 95.0, 135.0, 166.0, 196.0, 227.0, 258.0, 288.0, 319.0, 349.0]
        po = 0.6
        dif = 0.025
        p = UnitConversions.convert(1.0,"yr","hr")

        beta = Math::sqrt(Math::PI / (p * dif)) * 10.0
        x = Math::exp(-beta)
        x2 = x * x
        s = Math::sin(beta)
        c = Math::cos(beta)
        y = (x2 - 2.0 * x * c + 1.0) / (2.0 * beta ** 2.0)
        gm = Math::sqrt(y)
        z = (1.0 - x * (c + s)) / (1.0 - x * (c - s))
        phi = Math::atan(z)
        bo = (data.MonthlyAvgDrybulbs.max - data.MonthlyAvgDrybulbs.min) * 0.5

        data.GroundMonthlyTemps = []
        (0...12).to_a.each do |i|
          theta = amon[i] * 24.0
          data.GroundMonthlyTemps << UnitConversions.convert(data.AnnualAvgDrybulb - bo * Math::cos(2.0 * Math::PI / p * theta - po - phi) * gm + 460.0,"R","F")
        end

        return data

      end
      
      private
      
      def self._calculate_mains_temperature(avgOAT, maxDiffMonthlyAvgOAT, latitude)
        pi = Math::PI
        deg_rad = pi/180
        mainsDailyTemps = Array.new(365, 0)
        mainsMonthlyTemps = Array.new(12, 0)
        mainsAvgTemp = 0

        tmains_ratio = 0.4 + 0.01*(avgOAT - 44)
        tmains_lag = 35 - (avgOAT - 44)
        if latitude < 0
          sign = 1
        else
          sign = -1
        end
        
        #Calculate daily and annual
        for d in 1..365
          mainsDailyTemps[d-1] = avgOAT + 6 + tmains_ratio * maxDiffMonthlyAvgOAT / 2 * Math.sin(deg_rad * (0.986 * (d - 15 - tmains_lag) + sign * 90))
          mainsAvgTemp += mainsDailyTemps[d-1] / 365.0
        end
        #Calculate monthly
        for m in 1..12
          mainsMonthlyTemps[m-1] = avgOAT + 6 + tmains_ratio * maxDiffMonthlyAvgOAT / 2 * Math.sin(deg_rad * (0.986 * ((m * 30 - 15) - 15 - tmains_lag) + sign * 90))
        end
        return mainsAvgTemp, mainsMonthlyTemps, mainsDailyTemps
      end
  
end