# TODO: Need to handle vacations
require_relative "unit_conversions"

# Annual schedule defined by 12 24-hour values for weekdays and weekends.
class HourlyByMonthSchedule
  # weekday_month_by_hour_values must be a 12-element array of 24-element arrays of numbers.
  # weekend_month_by_hour_values must be a 12-element array of 24-element arrays of numbers.
  def initialize(model, runner, sch_name, weekday_month_by_hour_values, weekend_month_by_hour_values,
                 normalize_values = true, create_sch_object = true,
                 winter_design_day_sch = nil, summer_design_day_sch = nil,
                 schedule_type_limits_name = nil)
    @validated = true
    @model = model
    @runner = runner
    @sch_name = sch_name
    @schedule = nil
    @weekday_month_by_hour_values = validateValues(weekday_month_by_hour_values, 12, 24)
    @weekend_month_by_hour_values = validateValues(weekend_month_by_hour_values, 12, 24)
    @schedule_type_limits_name = schedule_type_limits_name
    if not @validated
      return
    end

    if normalize_values
      @maxval = calcMaxval()
    else
      @maxval = 1.0
    end
    @winter_design_day_sch = winter_design_day_sch
    @summer_design_day_sch = summer_design_day_sch
    if create_sch_object
      @schedule = createSchedule()
    end
  end

  def validated?
    return @validated
  end

  def calcDesignLevel(val)
    return val * 1000
  end

  def schedule
    return @schedule
  end

  def maxval
    return @maxval
  end

  private

  def validateValues(vals, num_outter_values, num_inner_values)
    err_msg = "A #{num_outter_values.to_s}-element array with #{num_inner_values.to_s}-element arrays of numbers must be entered for the schedule."
    if not vals.is_a?(Array)
      @runner.registerError(err_msg)
      @validated = false
      return nil
    end
    begin
      if vals.length != num_outter_values
        @runner.registerError(err_msg)
        @validated = false
        return nil
      end
      vals.each do |val|
        if not val.is_a?(Array)
          @runner.registerError(err_msg)
          @validated = false
          return nil
        end
        if val.length != num_inner_values
          @runner.registerError(err_msg)
          @validated = false
          return nil
        end
      end
    rescue
      @runner.registerError(err_msg)
      @validated = false
      return nil
    end
    return vals
  end

  def calcMaxval()
    maxval = [@weekday_month_by_hour_values.flatten.max, @weekend_month_by_hour_values.flatten.max].max
    if maxval == 0.0
      maxval == 1.0 # Prevent divide by zero
    end
    return maxval
  end

  def createSchedule()
    wkdy = []
    wknd = []

    year_description = @model.getYearDescription
    assumed_year = year_description.assumedYear
    num_days_in_months = Constants.NumDaysInMonths(year_description.isLeapYear)

    time = []
    for h in 1..24
      time[h] = OpenStudio::Time.new(0, h, 0, 0)
    end

    schedule = OpenStudio::Model::ScheduleRuleset.new(@model)
    schedule.setName(@sch_name)

    for m in 1..12
      date_s = OpenStudio::Date.new(OpenStudio::MonthOfYear.new(m), 1, assumed_year)
      date_e = OpenStudio::Date.new(OpenStudio::MonthOfYear.new(m), num_days_in_months[m - 1], assumed_year)

      wkdy_vals = []
      wknd_vals = []
      for h in 1..24
        wkdy_vals[h] = (@weekday_month_by_hour_values[m - 1][h - 1]) / @maxval
        wknd_vals[h] = (@weekend_month_by_hour_values[m - 1][h - 1]) / @maxval
      end

      if wkdy_vals == wknd_vals
        # Alldays
        wkdy_rule = OpenStudio::Model::ScheduleRule.new(schedule)
        wkdy_rule.setName(@sch_name + " #{Schedule.allday_name} rule#{m}")
        wkdy[m] = wkdy_rule.daySchedule
        wkdy[m].setName(@sch_name + " #{Schedule.allday_name}#{m}")
        previous_value = wkdy_vals[1]
        for h in 1..24
          next if h != 24 and wkdy_vals[h + 1] == previous_value

          wkdy[m].addValue(time[h], previous_value)
          previous_value = wkdy_vals[h + 1]
        end
        Schedule.set_weekday_rule(wkdy_rule)
        Schedule.set_weekend_rule(wkdy_rule)
        wkdy_rule.setStartDate(date_s)
        wkdy_rule.setEndDate(date_e)
      else
        # Weekdays
        wkdy_rule = OpenStudio::Model::ScheduleRule.new(schedule)
        wkdy_rule.setName(@sch_name + " #{Schedule.weekday_name} rule#{m}")
        wkdy[m] = wkdy_rule.daySchedule
        wkdy[m].setName(@sch_name + " #{Schedule.weekday_name}#{m}")
        previous_value = wkdy_vals[1]
        for h in 1..24
          next if h != 24 and wkdy_vals[h + 1] == previous_value

          wkdy[m].addValue(time[h], previous_value)
          previous_value = wkdy_vals[h + 1]
        end
        Schedule.set_weekday_rule(wkdy_rule)
        wkdy_rule.setStartDate(date_s)
        wkdy_rule.setEndDate(date_e)

        # Weekends
        wknd_rule = OpenStudio::Model::ScheduleRule.new(schedule)
        wknd_rule.setName(@sch_name + " #{Schedule.weekend_name} rule#{m}")
        wknd[m] = wknd_rule.daySchedule
        wknd[m].setName(@sch_name + " #{Schedule.weekend_name}#{m}")
        previous_value = wknd_vals[1]
        for h in 1..24
          next if h != 24 and wknd_vals[h + 1] == previous_value

          wknd[m].addValue(time[h], previous_value)
          previous_value = wknd_vals[h + 1]
        end
        Schedule.set_weekend_rule(wknd_rule)
        wknd_rule.setStartDate(date_s)
        wknd_rule.setEndDate(date_e)
      end

    end

    unless @winter_design_day_sch.nil?
      schedule.setWinterDesignDaySchedule(@winter_design_day_sch)
      schedule.winterDesignDaySchedule.setName("#{@sch_name} winter design")
    end
    unless @summer_design_day_sch.nil?
      schedule.setSummerDesignDaySchedule(@summer_design_day_sch)
      schedule.summerDesignDaySchedule.setName("#{@sch_name} summer design")
    end

    Schedule.set_schedule_type_limits(@model, schedule, @schedule_type_limits_name)

    return schedule
  end
end

# Annual schedule defined by 24 weekday hourly values, 24 weekend hourly values, and 12 monthly values
class MonthWeekdayWeekendSchedule
  # weekday_hourly_values can either be a comma-separated string of 24 numbers or a 24-element array of numbers.
  # weekend_hourly_values can either be a comma-separated string of 24 numbers or a 24-element array of numbers.
  # monthly_values can either be a comma-separated string of 12 numbers or a 12-element array of numbers.
  def initialize(model, runner, sch_name, weekday_hourly_values, weekend_hourly_values, monthly_values,
                 mult_weekday = 1.0, mult_weekend = 1.0, normalize_values = true, create_sch_object = true,
                 winter_design_day_sch = nil, summer_design_day_sch = nil,
                 schedule_type_limits_name = nil)
    @validated = true
    @model = model
    @runner = runner
    @sch_name = sch_name
    @schedule = nil
    @mult_weekday = mult_weekday
    @mult_weekend = mult_weekend
    @weekday_hourly_values = validateValues(weekday_hourly_values, 24, "weekday")
    @weekend_hourly_values = validateValues(weekend_hourly_values, 24, "weekend")
    @monthly_values = validateValues(monthly_values, 12, "monthly")
    @schedule_type_limits_name = schedule_type_limits_name
    if not @validated
      return
    end

    if normalize_values
      @weekday_hourly_values = normalizeSumToOne(@weekday_hourly_values)
      @weekend_hourly_values = normalizeSumToOne(@weekend_hourly_values)
      @monthly_values = normalizeAvgToOne(@monthly_values)
      @maxval = calcMaxval()
      @schadjust = calcSchadjust()
    else
      @maxval = 1.0
      @schadjust = 1.0
    end
    @winter_design_day_sch = winter_design_day_sch
    @summer_design_day_sch = summer_design_day_sch
    if create_sch_object
      @schedule = createSchedule()
    end
  end

  def validated?
    return @validated
  end

  def calcDesignLevelFromDailykWh(daily_kwh)
    return daily_kwh * @maxval * 1000 * @schadjust
  end

  def calcDesignLevelFromDailyTherm(daily_therm)
    return calcDesignLevelFromDailykWh(UnitConversions.convert(daily_therm, "therm", "kWh"))
  end

  def schedule
    return @schedule
  end

  private

  def validateValues(values, num_values, sch_name)
    err_msg = "A comma-separated string of #{num_values.to_s} numbers must be entered for the #{sch_name} schedule."
    if values.is_a?(Array)
      if values.length != num_values
        @runner.registerError(err_msg)
        @validated = false
        return nil
      end
      values.each do |val|
        if not valid_float?(val)
          @runner.registerError(err_msg)
          @validated = false
          return nil
        end
      end
      floats = values.map { |i| i.to_f }
    elsif values.is_a?(String)
      begin
        vals = values.split(",")
        vals.each do |val|
          if not valid_float?(val)
            @runner.registerError(err_msg)
            @validated = false
            return nil
          end
        end
        floats = vals.map { |i| i.to_f }
        if floats.length != num_values
          @runner.registerError(err_msg)
          @validated = false
          return nil
        end
      rescue
        @runner.registerError(err_msg)
        @validated = false
        return nil
      end
    else
      @runner.registerError(err_msg)
      @validated = false
      return nil
    end
    return floats
  end

  def valid_float?(str)
    !!Float(str) rescue false
  end

  def normalizeSumToOne(values)
    sum = values.reduce(:+).to_f
    if sum == 0.0
      return values
    end

    return values.map { |val| val / sum }
  end

  def normalizeAvgToOne(values)
    avg = values.reduce(:+).to_f / values.size
    if avg == 0.0
      return values
    end

    return values.map { |val| val / avg }
  end

  def calcMaxval()
    if @weekday_hourly_values.max > @weekend_hourly_values.max
      maxval = @monthly_values.max * @weekday_hourly_values.max * @mult_weekday
    else
      maxval = @monthly_values.max * @weekend_hourly_values.max * @mult_weekend
    end
    if maxval == 0.0
      maxval == 1.0 # Prevent divide by zero
    end
    return maxval
  end

  def calcSchadjust()
    # if sum != 1, normalize to get correct max val
    sum_wkdy = 0
    sum_wknd = 0
    @weekday_hourly_values.each do |v|
      sum_wkdy = sum_wkdy + v
    end
    @weekend_hourly_values.each do |v|
      sum_wknd = sum_wknd + v
    end
    if sum_wkdy < sum_wknd
      return 1 / sum_wknd
    end

    return 1 / sum_wkdy
  end

  def createSchedule()
    wkdy = []
    wknd = []

    year_description = @model.getYearDescription
    assumed_year = year_description.assumedYear
    num_days_in_months = Constants.NumDaysInMonths(year_description.isLeapYear)

    time = []
    for h in 1..24
      time[h] = OpenStudio::Time.new(0, h, 0, 0)
    end

    schedule = OpenStudio::Model::ScheduleRuleset.new(@model)
    schedule.setName(@sch_name)

    for m in 1..12
      date_s = OpenStudio::Date.new(OpenStudio::MonthOfYear.new(m), 1, assumed_year)
      date_e = OpenStudio::Date.new(OpenStudio::MonthOfYear.new(m), num_days_in_months[m - 1], assumed_year)

      wkdy_vals = []
      wknd_vals = []

      for h in 1..24
        wkdy_vals[h] = (@monthly_values[m - 1] * @weekday_hourly_values[h - 1] * @mult_weekday) / @maxval
        wknd_vals[h] = (@monthly_values[m - 1] * @weekend_hourly_values[h - 1] * @mult_weekend) / @maxval
      end

      if wkdy_vals == wknd_vals
        # Alldays
        wkdy_rule = OpenStudio::Model::ScheduleRule.new(schedule)
        wkdy_rule.setName(@sch_name + " #{Schedule.allday_name} rule#{m}")
        wkdy[m] = wkdy_rule.daySchedule
        wkdy[m].setName(@sch_name + " #{Schedule.allday_name}#{m}")
        previous_value = wkdy_vals[1]
        for h in 1..24
          next if h != 24 and wkdy_vals[h + 1] == previous_value

          wkdy[m].addValue(time[h], previous_value)
          previous_value = wkdy_vals[h + 1]
        end
        Schedule.set_weekday_rule(wkdy_rule)
        Schedule.set_weekend_rule(wkdy_rule)
        wkdy_rule.setStartDate(date_s)
        wkdy_rule.setEndDate(date_e)
      else
        # Weekdays
        wkdy_rule = OpenStudio::Model::ScheduleRule.new(schedule)
        wkdy_rule.setName(@sch_name + " #{Schedule.weekday_name} rule#{m}")
        wkdy[m] = wkdy_rule.daySchedule
        wkdy[m].setName(@sch_name + " #{Schedule.weekday_name}#{m}")
        previous_value = wkdy_vals[1]
        for h in 1..24
          next if h != 24 and wkdy_vals[h + 1] == previous_value

          wkdy[m].addValue(time[h], previous_value)
          previous_value = wkdy_vals[h + 1]
        end
        Schedule.set_weekday_rule(wkdy_rule)
        wkdy_rule.setStartDate(date_s)
        wkdy_rule.setEndDate(date_e)

        # Weekends
        wknd_rule = OpenStudio::Model::ScheduleRule.new(schedule)
        wknd_rule.setName(@sch_name + " #{Schedule.weekend_name} rule#{m}")
        wknd[m] = wknd_rule.daySchedule
        wknd[m].setName(@sch_name + " #{Schedule.weekend_name}#{m}")
        previous_value = wknd_vals[1]
        for h in 1..24
          next if h != 24 and wknd_vals[h + 1] == previous_value

          wknd[m].addValue(time[h], previous_value)
          previous_value = wknd_vals[h + 1]
        end
        Schedule.set_weekend_rule(wknd_rule)
        wknd_rule.setStartDate(date_s)
        wknd_rule.setEndDate(date_e)
      end

    end

    unless @winter_design_day_sch.nil?
      schedule.setWinterDesignDaySchedule(@winter_design_day_sch)
      schedule.winterDesignDaySchedule.setName("#{@sch_name} winter design")
    end
    unless @summer_design_day_sch.nil?
      schedule.setSummerDesignDaySchedule(@summer_design_day_sch)
      schedule.summerDesignDaySchedule.setName("#{@sch_name} summer design")
    end

    Schedule.set_schedule_type_limits(@model, schedule, @schedule_type_limits_name)

    return schedule
  end
end

# Generic class for handling an hourly schedule (saved as a csv) with 8760 values. Currently used by water heater models.
class HourlySchedule
  def initialize(model, runner, sch_name, file, offset, convert_temp, validation_values)
    @validated = true
    @model = model
    @runner = runner
    @sch_name = sch_name
    @schedule = nil
    @offset = offset
    @convert_temp = convert_temp
    @validation_values = validation_values
    @schedule, @schedule_array = createHourlyScheduleFromFile(runner, file, offset, convert_temp, validation_values)

    if @schedule.nil?
      @validated = false
      return
    end
    schedule = @schedule
  end

  def validated?
    return @validated
  end

  def schedule
    return @schedule
  end

  def schedule_array
    return @schedule_array
  end

  private

  def createHourlyScheduleFromFile(runner, file, offset, convert_temp, validation_values)
    data = []

    # Get appropriate file
    hourly_schedule = "#{file}"
    if not File.file?(hourly_schedule)
      @runner.registerError("Unable to find file: #{hourly_schedule}")
      return nil
    end

    # Read data into hourly array
    hour = 0
    data = [] # Generalize for any length
    File.open(file).each do |line|
      linedata = line.strip.split(',')
      if validation_values.empty?
        if convert_temp == true
          value = UnitConversions.convert((linedata[0].to_f + offset), "F", "C")
        else
          value = linedata[0].to_f + offset
        end
        data[hour] = value
      else
        if validation_values.include? linedata[0]
          value = validation_values.find_index(linedata[0]).to_f / (validation_values.length.to_f - 1.0)
          data[hour] = value
        else
          runner.registerError("Invalid value included in the hourly schedule file. The invalid data occurs at hour #{hour}")
        end
      end
      hour += 1
    end

    year_description = @model.getYearDescription
    start_date = year_description.makeDate(1, 1)
    interval = OpenStudio::Time.new(0, 1, 0, 0)

    time_series = OpenStudio::TimeSeries.new(start_date, interval, OpenStudio::createVector(data), "")

    schedule = OpenStudio::Model::ScheduleFixedInterval.fromTimeSeries(time_series, @model).get
    schedule.setName(@sch_name)

    return schedule, data
  end
end

class HotWaterSchedule
  def initialize(model, runner, sch_name, temperature_sch_name, num_bedrooms, days_shift,
                 file_prefix, target_water_temperature, create_sch_object = true,
                 schedule_type_limits_name = nil)
    @validated = true
    @model = model
    @runner = runner
    @sch_name = sch_name
    @schedule = nil
    @temperature_sch_name = temperature_sch_name
    @nbeds = num_bedrooms.to_i
    if @nbeds > 5
      @nbeds = 5
    elsif @nbeds < 1
      @nbeds = 1
    end
    @target_water_temperature = UnitConversions.convert(target_water_temperature, "F", "C")
    @schedule_type_limits_name = schedule_type_limits_name
    if file_prefix == "ClothesDryer"
      @file_prefix = "ClothesWasher"
    else
      @file_prefix = file_prefix
    end

    timestep_minutes = (60 / @model.getTimestep.numberOfTimestepsPerHour).to_i
    weeks = 1 # use a single week that repeats

    data = loadMinuteDrawProfileFromFile(timestep_minutes, days_shift, weeks)
    @totflow, @maxflow, @ontime = loadDrawProfileStatsFromFile()
    if data.nil? or @totflow.nil? or @maxflow.nil? or @ontime.nil?
      @validated = false
      return
    end
    if create_sch_object
      @schedule = createSchedule(data, timestep_minutes, weeks)
    end
  end

  def validated?
    return @validated
  end

  def calcDesignLevelFromDailykWh(daily_kWh)
    return UnitConversions.convert(daily_kWh * Constants.NumDaysInYear(@model.getYearDescription.isLeapYear) * 60 / (Constants.NumDaysInYear(@model.getYearDescription.isLeapYear) * @totflow / @maxflow), "kW", "W")
  end

  def calcPeakFlowFromDailygpm(daily_water)
    return UnitConversions.convert(@maxflow * daily_water / @totflow, "gal/min", "m^3/s")
  end

  def calcDailyGpmFromPeakFlow(peak_flow)
    return UnitConversions.convert(@totflow * peak_flow / @maxflow, "m^3/s", "gal/min")
  end

  def calcDesignLevelFromDailyTherm(daily_therm)
    return calcDesignLevelFromDailykWh(UnitConversions.convert(daily_therm, "therm", "kWh"))
  end

  def schedule
    return @schedule
  end

  def temperatureSchedule
    temperature_sch = OpenStudio::Model::ScheduleConstant.new(@model)
    temperature_sch.setValue(@target_water_temperature)
    temperature_sch.setName(@temperature_sch_name)
    Schedule.set_schedule_type_limits(@model, temperature_sch, Constants.ScheduleTypeLimitsTemperature)
    return temperature_sch
  end

  def getOntimeFraction
    return @ontime
  end

  private

  def loadMinuteDrawProfileFromFile(timestep_minutes, days_shift, weeks)
    data = []
    if @file_prefix.nil?
      return data
    end

    # Get appropriate file
    minute_draw_profile = File.join(File.dirname(__FILE__), "HotWater#{@file_prefix}Schedule_#{@nbeds}bed.csv")
    if not File.file?(minute_draw_profile)
      @runner.registerError("Unable to find file: #{minute_draw_profile}")
      return nil
    end

    minutes_in_year = 8760 * 60
    weeks_in_minutes = weeks * 7 * 24 * 60

    # Read data into minute array
    skippedheader = false
    min_shift = 24 * 60 * (days_shift % 365) # For MF homes, shift each unit by an additional week
    items = [0] * minutes_in_year
    File.open(minute_draw_profile).each do |line|
      linedata = line.strip.split(',')
      if not skippedheader
        skippedheader = true
        next
      end
      shifted_minute = linedata[0].to_i - min_shift
      if shifted_minute < 0
        stored_minute = shifted_minute + minutes_in_year
      else
        stored_minute = shifted_minute
      end
      value = linedata[1].to_f
      items[stored_minute.to_i] = value
      if shifted_minute >= weeks_in_minutes
        break # no need to process more data
      end
    end

    # Aggregate minute schedule up to the timestep level to reduce the size
    # and speed of processing.
    for tstep in 0..(minutes_in_year / timestep_minutes).to_i - 1
      timestep_items = items[tstep * timestep_minutes, timestep_minutes]
      avgitem = timestep_items.reduce(:+).to_f / timestep_items.size
      data.push(avgitem)
      if (tstep + 1) * timestep_minutes > weeks_in_minutes
        break # no need to process more data
      end
    end

    return data
  end

  def loadDrawProfileStatsFromFile()
    totflow = 0 # daily gal/day
    maxflow = 0
    ontime = 0

    column_header = @file_prefix

    totflow_column_header = "#{column_header} Sum"
    maxflow_column_header = "#{column_header} Max"
    ontime_column_header = "On-time Fraction"

    draw_file = File.join(File.dirname(__FILE__), "HotWaterMinuteDrawProfilesMaxFlows.csv")

    datafound = false
    skippedheader = false
    totflow_col_num = nil
    maxflow_col_num = nil
    ontime_col_num = nil
    File.open(draw_file).each do |line|
      linedata = line.strip.split(',')
      if not skippedheader
        skippedheader = true
        # Which columns to read?
        totflow_col_num = linedata.index(totflow_column_header)
        maxflow_col_num = linedata.index(maxflow_column_header)
        ontime_col_num = linedata.index(ontime_column_header)
        next
      end
      if linedata[0].to_i == @nbeds
        datafound = true
        if not totflow_col_num.nil?
          totflow = linedata[totflow_col_num].to_f
        end
        if not maxflow_col_num.nil?
          maxflow = linedata[maxflow_col_num].to_f
        end
        if not ontime_col_num.nil?
          ontime = linedata[ontime_col_num].to_f
        end
        break
      end
    end

    if not datafound
      @runner.registerError("Unable to find data for bedrooms = #{@nbeds}.")
      return nil, nil, nil
    end
    return totflow, maxflow, ontime
  end

  def createSchedule(data, timestep_minutes, weeks)
    if data.size == 0
      return nil
    end

    year_description = @model.getYearDescription
    assumed_year = year_description.assumedYear
    num_days_in_year = Constants.NumDaysInYear(year_description.isLeapYear)

    time = []
    (timestep_minutes..24 * 60).step(timestep_minutes).to_a.each_with_index do |m, i|
      time[i] = OpenStudio::Time.new(0, 0, m, 0)
    end

    schedule = OpenStudio::Model::ScheduleRuleset.new(@model)
    schedule.setName(@sch_name)

    schedule_rules = []
    for d in 1..7 * weeks # how many unique day schedules
      next if d > num_days_in_year

      rule = OpenStudio::Model::ScheduleRule.new(schedule)
      rule.setName(@sch_name + " #{Schedule.allday_name} ruleset#{d}")
      day_schedule = rule.daySchedule
      day_schedule.setName(@sch_name + " #{Schedule.allday_name}#{d}")
      previous_value = data[(d - 1) * 24 * 60 / timestep_minutes]
      time.each_with_index do |m, i|
        if i != time.length - 1
          next if data[i + 1 + (d - 1) * 24 * 60 / timestep_minutes] == previous_value
        end
        day_schedule.addValue(m, previous_value)
        previous_value = data[i + 1 + (d - 1) * 24 * 60 / timestep_minutes]
      end
      Schedule.set_weekday_rule(rule)
      Schedule.set_weekend_rule(rule)
      for w in 0..52 # max num of weeks
        next if d + (w * 7 * weeks) > num_days_in_year

        date_s = OpenStudio::Date::fromDayOfYear(d + (w * 7 * weeks), assumed_year)
        rule.addSpecificDate(date_s)
      end
    end

    Schedule.set_schedule_type_limits(@model, schedule, @schedule_type_limits_name)

    return schedule
  end
end

class Schedule
  def self.allday_name
    return 'allday'
  end

  def self.weekday_name
    return 'weekday'
  end

  def self.weekend_name
    return 'weekend'
  end

  # find the maximum profile value for a schedule
  def self.getMinMaxAnnualProfileValue(model, schedule)
    if not schedule.to_ScheduleRuleset.is_initialized
      return nil
    end

    schedule = schedule.to_ScheduleRuleset.get

    # gather profiles
    profiles = []
    defaultProfile = schedule.to_ScheduleRuleset.get.defaultDaySchedule
    profiles << defaultProfile
    rules = schedule.scheduleRules
    rules.each do |rule|
      profiles << rule.daySchedule
    end

    # test profiles
    min = nil
    max = nil
    profiles.each do |profile|
      profile.values.each do |value|
        if min.nil?
          min = value
        else
          if min > value then min = value end
        end
        if max.nil?
          max = value
        else
          if max < value then max = value end
        end
      end
    end
    return { 'min' => min, 'max' => max } # this doesn't include summer and winter design day
  end

  # return [Double] The total number of full load hours for this schedule.
  def self.annual_equivalent_full_load_hrs(year_description, schedule)
    if schedule.to_ScheduleInterval.is_initialized
      timeSeries = schedule.to_ScheduleInterval.get.timeSeries
      annual_flh = timeSeries.averageValue * Constants.NumHoursInYear(year_description.isLeapYear)
      return annual_flh
    end

    if not schedule.to_ScheduleRuleset.is_initialized
      return nil
    end

    schedule = schedule.to_ScheduleRuleset.get

    # Define the start and end date
    assumed_year = year_description.assumedYear
    year_start_date = OpenStudio::Date.new(OpenStudio::MonthOfYear.new(1), 1, assumed_year)
    year_end_date = OpenStudio::Date.new(OpenStudio::MonthOfYear.new(12), 31, assumed_year)

    # Get the ordered list of all the day schedules
    # that are used by this schedule ruleset
    day_schs = schedule.getDaySchedules(year_start_date, year_end_date)

    # Get a 365/366-value array of which schedule is used on each day of the year,
    day_schs_used_each_day = schedule.getActiveRuleIndices(year_start_date, year_end_date)
    if ![365, 366].include? day_schs_used_each_day.length
      OpenStudio::logFree(OpenStudio::Error, "openstudio.standards.ScheduleRuleset", "#{schedule.name} does not have 365/366 daily schedules accounted for, cannot accurately calculate annual EFLH.")
      return 0
    end

    # Create a map that shows how many days each schedule is used
    day_sch_freq = day_schs_used_each_day.group_by { |n| n }

    # Build a hash that maps schedule day index to schedule day
    schedule_index_to_day = {}
    for i in 0..(day_schs.length - 1)
      schedule_index_to_day[day_schs_used_each_day[i]] = day_schs[i]
    end

    # Loop through each of the schedules that is used, figure out the
    # full load hours for that day, then multiply this by the number
    # of days that day schedule applies and add this to the total.
    annual_flh = 0
    max_daily_flh = 0
    default_day_sch = schedule.defaultDaySchedule
    day_sch_freq.each do |freq|
      sch_index = freq[0]
      number_of_days_sch_used = freq[1].size

      # Get the day schedule at this index
      day_sch = nil
      if sch_index == -1 # If index = -1, this day uses the default day schedule (not a rule)
        day_sch = default_day_sch
      else
        day_sch = schedule_index_to_day[sch_index]
      end

      # Determine the full load hours for just one day
      daily_flh = 0
      values = day_sch.values
      times = day_sch.times

      previous_time_decimal = 0
      for i in 0..(times.length - 1)
        time_days = times[i].days
        time_hours = times[i].hours
        time_minutes = times[i].minutes
        time_seconds = times[i].seconds
        time_decimal = (time_days * 24.0) + time_hours + (time_minutes / 60.0) + (time_seconds / 3600.0)
        duration_of_value = time_decimal - previous_time_decimal
        daily_flh += values[i] * duration_of_value
        previous_time_decimal = time_decimal
      end

      # Multiply the daily EFLH by the number
      # of days this schedule is used per year
      # and add this to the overall total
      annual_flh += daily_flh * number_of_days_sch_used
    end

    # Warn if the max daily EFLH is more than 24,
    # which would indicate that this isn't a
    # fractional schedule.
    if max_daily_flh > 24
      OpenStudio::logFree(OpenStudio::Warn, "openstudio.standards.ScheduleRuleset", "#{schedule.name} has more than 24 EFLH in one day schedule, indicating that it is not a fractional schedule.")
    end

    return annual_flh
  end

  def self.ruleset_from_fixedinterval(model, hrly_sched, sch_name, winter_design_day_sch, summer_design_day_sch)
    # Returns schedule rules from a fixed interval object (60 min interval only)
    year_description = model.getYearDescription
    assumed_year = year_description.assumedYear
    run_period = model.getRunPeriod
    run_period_start = Time.new(assumed_year, run_period.getBeginMonth, run_period.getBeginDayOfMonth)
    start_day = run_period_start.yday

    hrly_sched = hrly_sched.timeSeries.values
    hrs = hrly_sched.length
    days = hrs / 24
    time = []
    for h in 1..24
      time[h] = OpenStudio::Time.new(0, h, 0, 0)
    end

    schedule = OpenStudio::Model::ScheduleRuleset.new(model)
    schedule.setName(sch_name + " ruleset")
    previous_value = hrly_sched[0]
    day_rule_prev = OpenStudio::Model::ScheduleRule.new(schedule)
    day_rule_prev.setName("DUMMY")
    day_sched_prev = day_rule_prev.daySchedule
    day_sched_prev.setName("DUMMY")

    for day in start_day..start_day + days - 1
      day_rule = OpenStudio::Model::ScheduleRule.new(schedule)
      day_rule.setName("#{sch_name} rule day #{day}")
      day_sched = day_rule.daySchedule
      day_sched.setName("#{sch_name} day schedule")
      day_ct = day - start_day + 1
      previous_value = hrly_sched[(day_ct - 1) * 24]

      for h in 1..24
        hr = (day_ct - 1) * 24 + h - 1
        next if h != 24 and hrly_sched[hr + 1] == previous_value

        day_sched.addValue(time[h], previous_value)
        if hr != hrs - 1
          previous_value = hrly_sched[hr + 1]
        end
      end

      if (day_sched_prev.values != day_sched.values) or (day_sched_prev.times != day_sched.times)
        sdate = OpenStudio::Date.fromDayOfYear(day, assumed_year)
        edate = OpenStudio::Date.fromDayOfYear(day, assumed_year)
        day_rule.setStartDate(sdate)
        day_rule.setEndDate(edate)

        if day_ct == 1
          day_sched_prev.remove
          day_rule_prev.remove
        end
      else
        sdate = day_rule_prev.startDate.get
        edate = OpenStudio::Date.fromDayOfYear(day, assumed_year)
        day_rule.setStartDate(sdate)
        day_rule.setEndDate(edate)
        day_sched_prev.remove
        day_rule_prev.remove
      end

      day_rule.setApplySunday(true)
      day_rule.setApplyMonday(true)
      day_rule.setApplyTuesday(true)
      day_rule.setApplyWednesday(true)
      day_rule.setApplyThursday(true)
      day_rule.setApplyFriday(true)
      day_rule.setApplySaturday(true)

      day_sched_prev = day_sched
      day_rule_prev = day_rule
    end

    unless winter_design_day_sch.nil?
      schedule.setWinterDesignDaySchedule(winter_design_day_sch)
      schedule.winterDesignDaySchedule.setName("#{sch_name} winter design EDIT")
    end
    unless summer_design_day_sch.nil?
      schedule.setSummerDesignDaySchedule(summer_design_day_sch)
      schedule.summerDesignDaySchedule.setName("#{sch_name} summer design EDIT")
    end

    return schedule
  end

  def self.set_schedule_type_limits(model, schedule, schedule_type_limits_name)
    return if schedule_type_limits_name.nil?

    schedule_type_limits = nil
    model.getScheduleTypeLimitss.each do |stl|
      next if stl.name.to_s != schedule_type_limits_name

      schedule_type_limits = stl
      break
    end

    if schedule_type_limits.nil?
      schedule_type_limits = OpenStudio::Model::ScheduleTypeLimits.new(model)
      schedule_type_limits.setName(schedule_type_limits_name)
      if schedule_type_limits_name == Constants.ScheduleTypeLimitsFraction
        schedule_type_limits.setLowerLimitValue(0)
        schedule_type_limits.setUpperLimitValue(1)
        schedule_type_limits.setNumericType("Continuous")
      elsif schedule_type_limits_name == Constants.ScheduleTypeLimitsOnOff
        schedule_type_limits.setLowerLimitValue(0)
        schedule_type_limits.setUpperLimitValue(1)
        schedule_type_limits.setNumericType("Discrete")
      elsif schedule_type_limits_name == Constants.ScheduleTypeLimitsTemperature
        schedule_type_limits.setNumericType("Continuous")
      end
    end

    schedule.setScheduleTypeLimits(schedule_type_limits)
  end

  def self.set_weekday_rule(rule)
    rule.setApplyMonday(true)
    rule.setApplyTuesday(true)
    rule.setApplyWednesday(true)
    rule.setApplyThursday(true)
    rule.setApplyFriday(true)
  end

  def self.set_weekend_rule(rule)
    rule.setApplySaturday(true)
    rule.setApplySunday(true)
  end
end
