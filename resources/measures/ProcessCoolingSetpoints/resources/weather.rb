require "#{File.dirname(__FILE__)}/psychrometrics"

class WeatherHeader
  def initialize
  end
  attr_accessor(:City, :State, :Country, :DataSource, :Station, :Latitude, :Longitude, :Timezone, :Altitude, :LocalPressure)
end

class WeatherData
  def initialize
  end
  attr_accessor(:AnnualAvgDrybulb, :AnnualMinDrybulb, :AnnualMaxDrybulb, :CDD50F, :CDD65F, :HDD50F, :HDD65F, :DailyAvgDrybulbs, :DailyMaxDrybulbs, :DailyMinDrybulbs, :AnnualAvgWindspeed, :MonthlyAvgDrybulbs, :MainsDailyTemps, :MainsMonthlyTemps, :MainsAvgTemp, :GroundMonthlyTemps, :WSF)
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
      @header, @data = process_epw(epw_path, header_only)
    else
      runner.registerError("Model has not been assigned a weather file.")
      @error = true
    end
  end

  def error?
    return @error
  end
  
  attr_accessor(:header, :data)
  
  private
  
      def process_epw(epw_path, header_only)
        if not File.exist?(epw_path)
            @runner.registerError("Cannot find weather file at #{epw_path}.")
            @error = true
            return nil, nil
        end

        epw_file = OpenStudio::EpwFile.new(epw_path, !header_only)
        epw_file_data = epw_file.data

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
            return header, nil
        end

        # Timeseries data:
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
        data = calc_avg_windspeed(data, hourdata)
        data = calc_mains_temperature(data, header)
        data = calc_ground_temperatures(data)
        data.WSF = get_ashrae_622_wsf(header.Station)
        
        return header, data

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

      def calc_mains_temperature(data, header)
        #Calculates and returns the annual average, daily, and monthly mains water temperature
        avgOAT = data.AnnualAvgDrybulb
        monthlyOAT = data.MonthlyAvgDrybulbs
        
        min_temp = monthlyOAT.min
        max_temp = monthlyOAT.max

        pi = Math::PI
        deg_rad = pi/180
        data.MainsDailyTemps = Array.new(365, 0)
        data.MainsMonthlyTemps = Array.new(12, 0)
        data.MainsAvgTemp = 0

        tmains_ratio = 0.4 + 0.01*(avgOAT - 44)
        tmains_lag = 35 - (avgOAT - 44)
        lat = header.Latitude
        if lat < 0
            sign = 1
        else
            sign = -1
        end
        
        #Calculate daily and annual
        for d in 1..365
            data.MainsDailyTemps[d-1] = avgOAT + 6 + tmains_ratio * (max_temp - min_temp) / 2 * Math.sin(deg_rad * (0.986 * (d - 15 - tmains_lag) + sign * 90))
            data.MainsAvgTemp += data.MainsDailyTemps[d-1] / 365.0
        end
        #Calculate monthly
        for m in 1..12
            data.MainsMonthlyTemps[m-1] = avgOAT + 6 + tmains_ratio * (max_temp - min_temp) / 2 * Math.sin(deg_rad * (0.986 * ((m * 30 - 15) - 15 - tmains_lag) + sign * 90))
        end
        
        return data
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
  
end