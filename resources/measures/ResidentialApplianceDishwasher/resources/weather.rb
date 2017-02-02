require "#{File.dirname(__FILE__)}/psychrometrics"
require "#{File.dirname(__FILE__)}/constants"

class WeatherHeader
  def initialize
  end
  attr_accessor(:City, :State, :Country, :DataSource, :Station, :Latitude, :Longitude, :Timezone, :Altitude, :LocalPressure)
end

class WeatherData
  def initialize
  end
  attr_accessor(:AnnualAvgDrybulb, :AnnualMinDrybulb, :AnnualMaxDrybulb, :CDD50F, :CDD65F, :HDD50F, :HDD65F, :DailyAvgDrybulbs, :DailyMaxDrybulbs, :DailyMinDrybulbs, :AnnualAvgWindspeed, :MonthlyAvgDrybulbs, :MainsDailyTemps, :MainsMonthlyTemps, :MainsAvgTemp, :GroundMonthlyTemps, :WSF, :MonthlyAvgDailyHighDrybulbs, :MonthlyAvgDailyLowDrybulbs)
end

class WeatherDesign
  def initialize
  end
  attr_accessor(:HeatingDrybulb, :HeatingWindspeed, :CoolingDrybulb, :CoolingWetbulb, :CoolingHumidityRatio, :CoolingWindspeed, :DailyTemperatureRange, :DehumidDrybulb, :DehumidHumidityRatio, :CoolingDirectNormal, :CoolingDiffuseHorizontal)
end

class WeatherProcess

  def initialize(model, runner, measure_dir, header_only=false)
    @model = model
    @runner = runner
    @measure_dir = measure_dir
    if model.weatherFile.is_initialized
      # OpenStudio measures
      wf = model.weatherFile.get
      # Sometimes path is available, sometimes just url. Should be improved in OS 2.0.
      if wf.path.is_initialized
        epw_path = wf.path.get.to_s
      else
        epw_path = wf.url.to_s.sub("file:///","").sub("file://","").sub("file:","")
      end
      if not File.exist? epw_path # Handle relative paths for unit tests
        epw_path = File.join(measure_dir, "resources", epw_path)
      end
      @header, @data, @design = process_epw(epw_path, header_only)
    else
      runner.registerError("Model has not been assigned a weather file.")
      @error = true
    end
  end

  def error?
    return @error
  end
  
  attr_accessor(:header, :data, :design)
  
  private
  
      def process_epw(epw_path, header_only)
        if not File.exist?(epw_path)
          @runner.registerError("Cannot find weather file at #{epw_path}.")
          @error = true
          return nil, nil
        end

        epw_file = OpenStudio::EpwFile.new(epw_path, !header_only)

        # Header info:
        header = WeatherHeader.new
        header.City = epw_file.city
        header.State = epw_file.stateProvinceRegion
        header.Country = epw_file.country
        header.DataSource = epw_file.dataSource
        header.Station = epw_file.wmoNumber
        header.Latitude = epw_file.latitude
        header.Longitude = epw_file.longitude
        header.Timezone = epw_file.timeZone
        header.Altitude = OpenStudio::convert(epw_file.elevation,"m","ft").get
        header.LocalPressure = Math::exp(-0.0000368 * header.Altitude) # atm
        
        if header_only
          return header, nil, nil
        end
        
        design = WeatherDesign.new
        ddy_path = epw_path.gsub(".epw",".ddy")
        epwHasDesignData = false
        if File.exist?(ddy_path)
          epwHasDesignData = true
          design = get_design_info_from_ddy(design, ddy_path, header.Altitude)
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
          hourdict['db'] = epwdata.dryBulbTemperature.get
          hourdict['dp'] = epwdata.dewPointTemperature.get
          hourdict['rh'] = epwdata.relativeHumidity.get / 100.0
          hourdict['ethoriz'] = epwdata.extraterrestrialHorizontalRadiation.get
          hourdict['ghoriz'] = epwdata.globalHorizontalRadiation.get
          hourdict['dirnormal'] = epwdata.directNormalRadiation.get # W/m^2
          hourdict['diffhoriz'] = epwdata.diffuseHorizontalRadiation.get # W/m^2
          hourdict['ws'] = epwdata.windSpeed.get
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

        data = WeatherData.new
        data = calc_annual_drybulbs(data, hourdata)
        data = calc_monthly_drybulbs(data, hourdata)
        data = calc_heat_cool_degree_days(data, hourdata, dailydbs)
        data = calc_avg_highs_lows(data, dailyhighdbs, dailylowdbs)
        data = calc_avg_windspeed(data, hourdata)
        data = calc_mains_temperature(data, header)
        data = calc_ground_temperatures(data)
        data.WSF = get_ashrae_622_wsf(header.Station)
        
        if not epwHasDesignData
          @runner.registerWarning("No DDY file found; calculating design conditions from EPW weather data.")
          design = calc_design_info(design, hourdata, header.Altitude)
          design.DailyTemperatureRange = data.MonthlyAvgDailyHighDrybulbs[7] - data.MonthlyAvgDailyLowDrybulbs[7]
        end
        
        design = calc_design_solar_radiation(design, hourdata)
        
        return header, data, design

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

        data.AnnualAvgDrybulb = OpenStudio::convert(db.inject{ |sum, n| sum + n } / 8760.0,"C","F").get

        # Peak temperatures:
        data.AnnualMinDrybulb = OpenStudio::convert(mindict['db'],"C","F").get
        data.AnnualMaxDrybulb = OpenStudio::convert(maxdict['db'],"C","F").get

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
          data.MonthlyAvgDrybulbs << OpenStudio::convert(month_dbtotal / month_hours,"C","F").get
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
        #data.HDD50F = calc_degree_days(dailydbs, 50, true)
        #data.CDD65F = calc_degree_days(dailydbs, 65, false)
        #data.CDD50F = calc_degree_days(dailydbs, 50, false)

        return data

      end

      def calc_degree_days(daily_dbs, base_temp_f, is_heating)
        # Calculates and returns degree days from a base temperature for either heating or cooling
        base_temp_c = OpenStudio::convert(base_temp_f,"F","C").get

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
          data.MonthlyAvgDailyHighDrybulbs << OpenStudio::convert(avg_high,"C","F").get
          data.MonthlyAvgDailyLowDrybulbs << OpenStudio::convert(avg_low,"C","F").get
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
        
        avgOAT = OpenStudio.convert(waterMainsTemperature.annualAverageOutdoorAirTemperature.get, "C", "F").get
        maxDiffMonthlyAvgOAT = OpenStudio.convert(waterMainsTemperature.maximumDifferenceInMonthlyAverageOutdoorAirTemperatures.get, "K", "R").get
        
        return self._calculate_mains_temperature(avgOAT, maxDiffMonthlyAvgOAT, latitude)
      end
      
      def get_ashrae_622_wsf(wmo)
        # Looks up the ASHRAE 62.2 weather and shielding factor from ASHRAE622WSF
        # for the specified WMO station number. If not found, uses the average value 
        # in the file.
            
        # Sets the WSF value.
        
        ashrae_csv = File.join(@measure_dir, "resources", 'ASHRAE622WSF.csv')
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
            design.HeatingDrybulb = OpenStudio::convert(designDay.maximumDryBulbTemperature,"C","F").get
          elsif d.name.get.include?("Ann Htg Wind 99% Condns WS=>MCDB")
            # FIXME: Is this correct? Or should be wind speed coincident with heating drybulb?
            design.HeatingWindspeed = designDay.windSpeed
          elsif d.name.get.include?("Ann Clg 1% Condns DB=>MWB")
            design.CoolingDrybulb = OpenStudio::convert(designDay.maximumDryBulbTemperature,"C","F").get
            design.CoolingWetbulb = OpenStudio::convert(designDay.humidityIndicatingConditionsAtMaximumDryBulb,"C","F").get
            design.CoolingWindspeed = designDay.windSpeed
            design.DailyTemperatureRange = OpenStudio::convert(designDay.dailyDryBulbTemperatureRange,"K","R").get
          elsif d.name.get.include?("Ann Clg 2% Condns DP=>MDB")
            design.DehumidDrybulb = OpenStudio::convert(designDay.maximumDryBulbTemperature,"C","F").get
            dehum02per_dp = OpenStudio::convert(designDay.humidityIndicatingConditionsAtMaximumDryBulb,"C","F").get
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
            wb = Psychrometrics.Twb_fT_R_P(OpenStudio::convert(annual_hd_sorted_by_db[i]['db'],"C","F").get, annual_hd_sorted_by_db[i]['rh'], std_press)
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
        

        design.CoolingDrybulb = OpenStudio::convert(cool01per_db,"C","F").get
        design.CoolingWetbulb = cool_design_wb
        design.CoolingHumidityRatio = Psychrometrics.w_fT_Twb_P(design.CoolingDrybulb, design.CoolingWetbulb, std_press)
        design.CoolingWindspeed = cool_windspeed.inject{ |sum, n| sum + n } / cool_windspeed.size
        
        design.HeatingDrybulb = OpenStudio::convert(heat99per_db,"C","F").get
        design.HeatingWindspeed = heat_windspeed.inject{ |sum, n| sum + n } / heat_windspeed.size
        
        design.DehumidDrybulb = OpenStudio::convert(dehum_design_db,"C","F").get
        design.DehumidHumidityRatio = Psychrometrics.w_fT_Twb_P(OpenStudio::convert(dehum02per_dp,"C","F").get, OpenStudio::convert(dehum02per_dp,"C","F").get, std_press)
        
        return design
        
      end
      
      def calc_ground_temperatures(data)
        # Return monthly ground temperatures.

        amon = [15.0, 46.0, 74.0, 95.0, 135.0, 166.0, 196.0, 227.0, 258.0, 288.0, 319.0, 349.0]
        po = 0.6
        dif = 0.025
        p = OpenStudio::convert(1.0,"yr","hr").get

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
          data.GroundMonthlyTemps << OpenStudio::convert(data.AnnualAvgDrybulb - bo * Math::cos(2.0 * Math::PI / p * theta - po - phi) * gm + 460.0,"R","F").get
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