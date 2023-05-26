# frozen_string_literal: true

class WeatherHeader
  def initialize
  end
  ATTRS ||= [:City, :State, :Country, :DataSource, :Station, :Latitude, :Longitude, :Timezone, :Altitude, :LocalPressure, :RecordsPerHour]
  attr_accessor(*ATTRS)
end

class WeatherData
  def initialize
  end
  ATTRS ||= [:AnnualAvgDrybulb, :CDD50F, :CDD65F, :HDD50F, :HDD65F, :MonthlyAvgDrybulbs, :GroundMonthlyTemps, :WSF, :MonthlyAvgDailyHighDrybulbs, :MonthlyAvgDailyLowDrybulbs]
  attr_accessor(*ATTRS)
end

class WeatherDesign
  def initialize
  end
  ATTRS ||= [:HeatingDrybulb, :CoolingDrybulb, :CoolingWetbulb, :CoolingHumidityRatio, :DailyTemperatureRange]
  attr_accessor(*ATTRS)
end

class WeatherProcess
  def initialize(epw_path:, runner:)
    @header = WeatherHeader.new
    @data = WeatherData.new
    @design = WeatherDesign.new

    if not File.exist?(epw_path)
      fail "Cannot find weather file at #{epw_path}."
    end

    epw_file = OpenStudio::EpwFile.new(epw_path, true)

    process_epw(runner, epw_file)
  end

  attr_accessor(:header, :data, :design)

  private

  def process_epw(runner, epw_file)
    # Header info:
    @header.City = epw_file.city
    @header.State = epw_file.stateProvinceRegion
    @header.Country = epw_file.country
    @header.DataSource = epw_file.dataSource
    @header.Station = epw_file.wmoNumber
    @header.Latitude = epw_file.latitude
    @header.Longitude = epw_file.longitude
    @header.Timezone = epw_file.timeZone
    @header.Altitude = UnitConversions.convert(epw_file.elevation, 'm', 'ft')
    @header.LocalPressure = Math::exp(-0.0000368 * @header.Altitude) # atm
    @header.RecordsPerHour = epw_file.recordsPerHour
    if @header.RecordsPerHour != 1
      fail "Unexpected records per hour: #{@header.RecordsPerHour}."
    end

    epw_file_data = epw_file.data

    epwHasDesignData = get_design_info_from_epw(epw_file)

    # Timeseries data:
    rowdata = []
    dailydbs = []
    dailyhighdbs = []
    dailylowdbs = []
    monthdbs = []
    epw_file_data.each_with_index do |epwdata, rownum|
      rowdict = {}
      rowdict['month'] = epwdata.month
      rowdict['day'] = epwdata.day
      rowdict['hour'] = epwdata.hour
      begin
        rowdict['db'] = epwdata.dryBulbTemperature.get
      rescue
        fail "Cannot retrieve dryBulbTemperature from the EPW for hour #{rownum + 1}."
      end
      begin
        rowdict['rh'] = epwdata.relativeHumidity.get / 100.0
      rescue
        fail "Cannot retrieve relativeHumidity from the EPW for hour #{rownum + 1}."
      end
      begin
        rowdict['ws'] = epwdata.windSpeed.get
      rescue
        fail "Cannot retrieve windSpeed from the EPW for hour #{rownum + 1}."
      end
      monthdbs << [] if rowdict['day'] == 1
      monthdbs[rowdict['month'] - 1] << rowdict['db']

      rowdata << rowdict

      next unless (rownum + 1) % (24 * @header.RecordsPerHour) == 0

      db = []
      maxdb = rowdata[rowdata.length - (24 * @header.RecordsPerHour)]['db']
      mindb = rowdata[rowdata.length - (24 * @header.RecordsPerHour)]['db']
      rowdata[rowdata.length - (24 * @header.RecordsPerHour)..-1].each do |x|
        if x['db'] > maxdb
          maxdb = x['db']
        end
        if x['db'] < mindb
          mindb = x['db']
        end
        db << x['db']
      end

      dailydbs << db.sum(0.0) / (24.0 * @header.RecordsPerHour)
      dailyhighdbs << maxdb
      dailylowdbs << mindb
    end

    @data.AnnualAvgDrybulb = UnitConversions.convert(rowdata.map { |x| x['db'] }.sum(0.0) / rowdata.length, 'C', 'F')
    @data.MonthlyAvgDrybulbs = []
    for i in 1..12
      @data.MonthlyAvgDrybulbs << UnitConversions.convert(monthdbs[i - 1].sum / monthdbs[i - 1].length, 'C', 'F')
    end

    calc_heat_cool_degree_days(dailydbs)
    calc_avg_monthly_highs_lows(dailyhighdbs, dailylowdbs)
    calc_ground_temperatures
    @data.WSF = calc_ashrae_622_wsf(rowdata)

    if not epwHasDesignData
      if not runner.nil?
        runner.registerWarning('No design condition info found; calculating design conditions from EPW weather data.')
      end
      calc_design_info(runner, rowdata)
      @design.DailyTemperatureRange = @data.MonthlyAvgDailyHighDrybulbs[7] - @data.MonthlyAvgDailyLowDrybulbs[7]
    end
  end

  def calc_heat_cool_degree_days(dailydbs)
    # Calculates and stores heating/cooling degree days
    @data.HDD65F = calc_degree_days(dailydbs, 65, true)
    @data.HDD50F = calc_degree_days(dailydbs, 50, true)
    @data.CDD65F = calc_degree_days(dailydbs, 65, false)
    @data.CDD50F = calc_degree_days(dailydbs, 50, false)
  end

  def calc_degree_days(daily_dbs, base_temp_f, is_heating)
    # Calculates and returns degree days from a base temperature for either heating or cooling
    base_temp_c = UnitConversions.convert(base_temp_f, 'F', 'C')

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

    deg_days = deg_days.sum(0.0)
    return 1.8 * deg_days
  end

  def calc_avg_monthly_highs_lows(daily_high_dbs, daily_low_dbs)
    # Calculates and stores avg daily highs and lows for each month
    @data.MonthlyAvgDailyHighDrybulbs = []
    @data.MonthlyAvgDailyLowDrybulbs = []

    if daily_high_dbs.size == 365 # standard year
      month_num_days = Constants.NumDaysInMonths(1999)
    elsif daily_high_dbs.size == 366 # leap year
      month_num_days = Constants.NumDaysInMonths(2000)
    else
      fail "Unexpected number of days: #{daily_high_dbs.size}."
    end

    first_day = 0
    for month in 1..12
      ndays = month_num_days[month - 1] # Number of days in current month
      if month > 1
        first_day += month_num_days[month - 2] # Number of days in previous month
      end
      avg_high = daily_high_dbs[first_day, ndays].sum(0.0) / ndays.to_f
      avg_low = daily_low_dbs[first_day, ndays].sum(0.0) / ndays.to_f
      @data.MonthlyAvgDailyHighDrybulbs << UnitConversions.convert(avg_high, 'C', 'F')
      @data.MonthlyAvgDailyLowDrybulbs << UnitConversions.convert(avg_low, 'C', 'F')
    end
  end

  def calc_ashrae_622_wsf(rowdata)
    require 'csv'
    ashrae_csv = File.join(File.dirname(__FILE__), 'data', 'ashrae_622_wsf.csv')

    wsf = nil
    CSV.read(ashrae_csv, headers: false).each do |data|
      next unless data[0] == @header.Station

      wsf = Float(data[1]).round(2)
    end
    return wsf unless wsf.nil?

    # If not available in ashrae_622_wsf.csv...
    # Calculates the wSF value per report LBNL-5795E "Infiltration as Ventilation: Weather-Induced Dilution"

    # Constants
    c_d = 1.0       # unitless, discharge coefficient for ELA (at 4 Pa)
    t_indoor = 22.0 # C, indoor setpoint year-round
    n = 0.67        # unitless, pressure exponent
    s = 0.7         # unitless, shelter class 4 for 1-story with flue, enhanced model
    delta_p = 4.0   # Pa, pressure difference indoor-outdoor
    u_min = 1.0     # m/s, minimum windspeed per hour
    ela = 0.074     # m^2, effective leakage area (assumed)
    cfa = 185.0     # m^2, conditioned floor area
    h = 2.5         # m, single story height
    g = 0.48        # unitless, wind speed multiplier for 1-story, enhanced model
    c_s = 0.069     # (Pa/K)^n, stack coefficient, 1-story with flue, enhanced model
    c_w = 0.142     # (Pa*s^2/m^2)^n, wind coefficient, bsmt slab 1-story with flue, enhanced model
    roe = 1.2       # kg/m^3, air density (assumed at sea level)

    c = c_d * ela * (2 / roe)**0.5 * delta_p**(0.5 - n) # m^3/(s*Pa^n), flow coefficient

    taus = []
    prev_tau = 0.0
    for hr in 0..rowdata.size - 1
      q_s = c * c_s * (t_indoor - rowdata[hr]['db']).abs**n
      q_w = c * c_w * (s * g * [rowdata[hr]['ws'], u_min].max)**(2 * n)
      q_tot = (q_s**2 + q_w**2)**0.5
      ach = 3600.0 * q_tot / (h * cfa)
      taus << (1 - Math.exp(-ach)) / ach + prev_tau * Math.exp(-ach)
      prev_tau = taus[-1]
    end

    tau = taus.sum(0.0) / taus.size.to_f # Mean annual turnover time (hours)
    wsf = (cfa / ela) / (1000.0 * tau)

    return wsf.round(2)
  end

  def get_design_info_from_epw(epw_file)
    epw_design_conditions = epw_file.designConditions
    epwHasDesignData = false
    if epw_design_conditions.length > 0
      epwHasDesignData = true
      epw_design_conditions = epw_design_conditions[0]
      @design.HeatingDrybulb = UnitConversions.convert(epw_design_conditions.heatingDryBulb99, 'C', 'F')
      @design.CoolingDrybulb = UnitConversions.convert(epw_design_conditions.coolingDryBulb1, 'C', 'F')
      @design.CoolingWetbulb = UnitConversions.convert(epw_design_conditions.coolingMeanCoincidentWetBulb1, 'C', 'F')
      @design.DailyTemperatureRange = UnitConversions.convert(epw_design_conditions.coolingDryBulbRange, 'deltaC', 'deltaF')
      std_press = Psychrometrics.Pstd_fZ(@header.Altitude)
      @design.CoolingHumidityRatio = Psychrometrics.w_fT_Twb_P(design.CoolingDrybulb, design.CoolingWetbulb, std_press)
    end
    return epwHasDesignData
  end

  def calc_design_info(runner, rowdata)
    # Calculate design day info:
    # - Heating 99% drybulb
    # - Cooling 99% drybulb
    # - Cooling mean coincident wetbulb
    # - Cooling mean coincident humidity ratio

    std_press = Psychrometrics.Pstd_fZ(@header.Altitude)
    annual_hd_sorted_by_db = rowdata.sort_by { |x| x['db'] }

    # 1%/99%/2% values
    heat99per_db = annual_hd_sorted_by_db[88 * @header.RecordsPerHour]['db']
    cool01per_db = annual_hd_sorted_by_db[8673 * @header.RecordsPerHour]['db']

    # Mean coincident values for cooling
    cool_wetbulb = []
    for i in 0..(annual_hd_sorted_by_db.size - 1)
      next unless (annual_hd_sorted_by_db[i]['db'] > cool01per_db - 0.5) && (annual_hd_sorted_by_db[i]['db'] < cool01per_db + 0.5)

      wb = Psychrometrics.Twb_fT_R_P(runner, UnitConversions.convert(annual_hd_sorted_by_db[i]['db'], 'C', 'F'), annual_hd_sorted_by_db[i]['rh'], std_press)
      cool_wetbulb << wb
    end
    cool_design_wb = cool_wetbulb.sum(0.0) / cool_wetbulb.size

    @design.CoolingDrybulb = UnitConversions.convert(cool01per_db, 'C', 'F')
    @design.CoolingWetbulb = cool_design_wb
    @design.CoolingHumidityRatio = Psychrometrics.w_fT_Twb_P(design.CoolingDrybulb, design.CoolingWetbulb, std_press)

    @design.HeatingDrybulb = UnitConversions.convert(heat99per_db, 'C', 'F')
  end

  def calc_ground_temperatures
    # Return monthly ground temperatures.

    amon = [15.0, 46.0, 74.0, 95.0, 135.0, 166.0, 196.0, 227.0, 258.0, 288.0, 319.0, 349.0]
    po = 0.6
    dif = 0.025
    p = UnitConversions.convert(1.0, 'yr', 'hr')

    beta = Math::sqrt(Math::PI / (p * dif)) * 10.0
    x = Math::exp(-beta)
    x2 = x * x
    s = Math::sin(beta)
    c = Math::cos(beta)
    y = (x2 - 2.0 * x * c + 1.0) / (2.0 * beta**2.0)
    gm = Math::sqrt(y)
    z = (1.0 - x * (c + s)) / (1.0 - x * (c - s))
    phi = Math::atan(z)
    bo = (data.MonthlyAvgDrybulbs.max - data.MonthlyAvgDrybulbs.min) * 0.5

    @data.GroundMonthlyTemps = []
    for i in 0..11
      theta = amon[i] * 24.0
      @data.GroundMonthlyTemps << UnitConversions.convert(data.AnnualAvgDrybulb - bo * Math::cos(2.0 * Math::PI / p * theta - po - phi) * gm + 460.0, 'R', 'F')
    end
  end

  def self.calc_mains_temperatures(avgOAT, maxDiffMonthlyAvgOAT, latitude, year)
    n_days = Constants.NumDaysInYear(year)
    pi = Math::PI
    deg_rad = pi / 180
    mainsDailyTemps = Array.new(n_days, 0)
    mainsMonthlyTemps = Array.new(12, 0)
    mainsAvgTemp = 0

    tmains_ratio = 0.4 + 0.01 * (avgOAT - 44)
    tmains_lag = 35 - (avgOAT - 44)
    if latitude < 0
      sign = 1 # southern hemisphere
    else
      sign = -1
    end

    # Calculate daily and annual
    for d in 1..n_days
      mainsDailyTemps[d - 1] = avgOAT + 6 + tmains_ratio * maxDiffMonthlyAvgOAT / 2 * Math.sin(deg_rad * (0.986 * (d - 15 - tmains_lag) + sign * 90))
      mainsAvgTemp += mainsDailyTemps[d - 1] / Float(n_days)
    end
    # Calculate monthly
    for m in 1..12
      mainsMonthlyTemps[m - 1] = avgOAT + 6 + tmains_ratio * maxDiffMonthlyAvgOAT / 2 * Math.sin(deg_rad * (0.986 * ((m * 30 - 15) - 15 - tmains_lag) + sign * 90))
    end
    return mainsAvgTemp, mainsMonthlyTemps, mainsDailyTemps
  end
end
