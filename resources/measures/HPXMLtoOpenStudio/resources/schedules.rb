# TODO: Need to handle vacations
require_relative "unit_conversions"
require "csv"

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
          if min > value then
            min = value
          end
        end
        if max.nil?
          max = value
        else
          if max < value then
            max = value
          end
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

class ScheduleGenerator
  def initialize(runner:,
                 model:,
                 weather:,
                 building_id: nil,
                 num_occupants:,
                 schedules_path:,
                 **remainder)

    @runner = runner
    @model = model
    @weather = weather
    @building_id = building_id
    @num_occupants = num_occupants
    @schedules_path = schedules_path
  end

  def create
    @num_occupants = @num_occupants.to_i
    minutes_per_steps = 10
    if @model.getSimulationControl.timestep.is_initialized
      minutes_per_steps = 60 / @model.getSimulationControl.timestep.get.numberOfTimestepsPerHour
      # minutes_per_steps = 1
    else
      minutes_per_steps = 1
    end
    steps_in_day = 24 * 60 / minutes_per_steps
    @model.getYearDescription.isLeapYear ? total_days_in_year = 366 : total_days_in_year = 365

    if @building_id.nil?
      building_id = @model.getBuilding.additionalProperties.getFeatureAsInteger("Building ID") # this becomes the seed
      if building_id.is_initialized
        building_id = building_id.get
      else
        @runner.registerWarning("Unable to retrieve the Building ID (seed for schedule generator); setting it to 1.")
        building_id = 1
      end
    else
      building_id = @building_id
    end

    # initialize a random number generator using building_id
    prng = Random.new(building_id)

    occupancy_cluster_types_tsv_path = @schedules_path + "/Occupancy_Types.tsv"
    occ_types_dist = CSV.read(occupancy_cluster_types_tsv_path, { :col_sep => "\t" })
    occ_types = occ_types_dist[0].map { |i| i.split('=')[1] }
    occ_prob = occ_types_dist[1].map { |i| i.to_f }

    all_simulated_values = []
    (1..@num_occupants).each do |i|
      num_states = 7
      num_ts_per_day = 96

      occ_type_id = weighted_random(prng, occ_prob)
      occ_type = occ_types[occ_type_id]
      init_prob_file_weekday = @schedules_path + "/weekday/mkv_chain_initial_prob_cluster_#{occ_type_id}.csv"
      initial_prob_weekday = CSV.read(init_prob_file_weekday)
      initial_prob_weekday = initial_prob_weekday.map { |x| x[0].to_f }
      init_prob_file_weekend = @schedules_path + "/weekend/mkv_chain_initial_prob_cluster_#{occ_type_id}.csv"
      initial_prob_weekend = CSV.read(init_prob_file_weekend)
      initial_prob_weekend = initial_prob_weekend.map { |x| x[0].to_f }

      transition_matrix_file_weekday = @schedules_path + "/weekday/mkv_chain_transition_prob_cluster_#{occ_type_id}.csv"
      transition_matrix_weekday = CSV.read(transition_matrix_file_weekday)
      transition_matrix_weekday = transition_matrix_weekday.map { |x| x.map { |y| y.to_f } }
      transition_matrix_file_weekend = @schedules_path + "/weekend/mkv_chain_transition_prob_cluster_#{occ_type_id}.csv"
      transition_matrix_weekend = CSV.read(transition_matrix_file_weekend)
      transition_matrix_weekend = transition_matrix_weekend.map { |x| x.map { |y| y.to_f } }

      simulated_values = []
      sim_year = @model.getYearDescription.calendarYear.get
      start_day = DateTime.new(sim_year, 1, 1)
      total_days_in_year.times do |day|
        today = start_day + day
        day_of_week = today.wday
        if [0, 6].include?(day_of_week)
          # Weekend
          day_type = "weekend"
          initial_prob = initial_prob_weekend
          transition_matrix = transition_matrix_weekend
        else
          # weekday
          day_type = "weekday"
          initial_prob = initial_prob_weekday
          transition_matrix = transition_matrix_weekday
        end
        j = 0
        state_prob = initial_prob
        while j < (num_ts_per_day) do
          active_state = weighted_random(prng, state_prob)
          state_vector = [0] * num_states
          state_vector[active_state] = 1
          activity_duration = sample_activity_duration(prng, occ_type_id, active_state, day_type, j / 4)
          activity_duration.times do |repeat_activity_count|
            # repeat the same activity for the duration times
            simulated_values << state_vector
            j += 1
            if j >= num_ts_per_day then break end # break as soon as we have filled for the day
          end
          if j >= num_ts_per_day then break end # break as soon as we have filled for the day

          transition_probs = transition_matrix[(j - 1) * 7...(j) * 7]
          transition_probs_matrix = Matrix[*transition_probs]
          current_state_vec = Matrix.row_vector(state_vector)
          state_prob = current_state_vec * transition_probs_matrix
          state_prob = state_prob.to_a[0]
        end
      end
      simulated_values = simulated_values.rotate(-4 * 4) # 4am shifting
      all_simulated_values << Matrix[*simulated_values]
      # States are: 'sleeping','shower','laundry','cooking', 'dishwashing', 'absent', 'nothingAtHome'
    end

    # shape of all_simulated_values is [2, 35040, 7] i.e. (num_occupants, period_in_a_year, number_of_states)
    plugload_sch = CSV.read(@schedules_path + "/plugload_sch.csv")
    lighting_sch = CSV.read(@schedules_path + "/lighting_sch.csv")
    ceiling_fan_sch = CSV.read(@schedules_path + "/ceiling_fan_sch.csv")
    # "occupants", "cooking_range", "plug_loads", lighting_interior", "lighting_exterior", "lighting_garage", "clothes_washer", "clothes_dryer", "dishwasher", "baths", "showers", "sinks", "ceiling_fan", "clothes_dryer_exhaust"

    weekday_lighting_schedule = lighting_sch[0].map { |x| x.to_f }
    weekend_lighting_schedule = lighting_sch[1].map { |x| x.to_f }
    monthly_lighting_schedule = lighting_sch[2].map { |x| x.to_f }
    holiday_lighting_schedule = lighting_sch[3].map { |x| x.to_f }

    sch_option_type = Constants.OptionTypeLightingScheduleCalculated
    interior_lighting_schedule = get_interior_lighting_sch(@model, @runner, @weather, sch_option_type,
                                                           monthly_lighting_schedule)
    sch_option_type = Constants.OptionTypeLightingScheduleUserSpecified
    other_lighting_schedule = get_other_lighting_sch(@model, @runner, @weather, sch_option_type,
                                                     weekday_lighting_schedule, weekend_lighting_schedule,
                                                     monthly_lighting_schedule)
    holiday_lighting_schedule = get_holiday_lighting_sch(@model, @runner, holiday_lighting_schedule)

    @plugload_schedule = []
    @lighting_interior_schedule = []
    @lighting_exterior_schedule = []
    @lighting_garage_schedule = []
    @lighting_holiday_schedule = []
    @ceiling_fan_schedule = []
    @sink_schedule = []
    @bath_schedule = []
    @clothes_dryer_exhaust_schedule = []

    @shower_schedule = []
    @clothes_washer_schedule = []
    @clothes_dryer_schedule = []
    @dish_washer_schedule = []
    @cooking_schedule = []
    @away_schedule = []
    idle_schedule = []
    @sleeping_schedule = []

    sim_year = @model.getYearDescription.calendarYear.get
    start_day = DateTime.new(sim_year, 1, 1)
    total_days_in_year.times do |day|
      today = start_day + day
      month = today.month
      day_of_week = today.wday
      [0, 6].include?(day_of_week) ? is_weekday = false : is_weekday = true

      pending_shower = 0
      pending_clothes_washer = 0
      steps_in_day.times do |step|
        minute = day * 1440 + step * minutes_per_steps
        index_15 = (minute / 15).to_i
        index_hour = (minute / 60).to_i
        step_per_hour = 60 / minutes_per_steps

        # the schedule is set as the sum of values of individual occupants
        @sleeping_schedule << sum_across_occupants(all_simulated_values, 0, index_15).to_f / @num_occupants

        @shower_schedule << sum_across_occupants(all_simulated_values, 1, index_15).to_f / @num_occupants

        # clothes washer
        clothes_washing_count = sum_across_occupants(all_simulated_values, 2, index_15)
        if clothes_washing_count > 0
          pending_clothes_washer += clothes_washing_count - 1
          clothes_washing = 1
        elsif pending_clothes_washer > 0
          pending_clothes_washer -= 1
          clothes_washing = 1
        else
          clothes_washing = 0
        end
        @clothes_washer_schedule << clothes_washing
        hour_before_washer = @clothes_washer_schedule[-step_per_hour]
        if hour_before_washer.nil?
          @clothes_dryer_schedule << 0
        else
          @clothes_dryer_schedule << hour_before_washer
        end
        @cooking_schedule << sum_across_occupants(all_simulated_values, 3, index_15, max_clip = 1)
        @dish_washer_schedule << sum_across_occupants(all_simulated_values, 4, index_15, max_clip = 1)
        @away_schedule << sum_across_occupants(all_simulated_values, 5, index_15).to_f / @num_occupants
        idle_schedule << sum_across_occupants(all_simulated_values, 6, index_15).to_f / @num_occupants

        active_occupancy_percentage = 1 - (@away_schedule[-1] + @sleeping_schedule[-1])
        @plugload_schedule << get_value_from_daily_sch(plugload_sch, month, is_weekday, minute, active_occupancy_percentage)
        @lighting_interior_schedule << scale_lighting_by_occupancy(interior_lighting_schedule, minute, active_occupancy_percentage)
        @lighting_exterior_schedule << get_value_from_daily_sch(lighting_sch, month, is_weekday, minute, 1)
        @lighting_garage_schedule << get_value_from_daily_sch(lighting_sch, month, is_weekday, minute, 1)
        @lighting_holiday_schedule << scale_lighting_by_occupancy(holiday_lighting_schedule, minute, 1)
        @ceiling_fan_schedule << get_value_from_daily_sch(ceiling_fan_sch, month, is_weekday, minute, active_occupancy_percentage)
        @bath_schedule << @shower_schedule[-1]
      end
    end
    @plugload_schedule = normalize(@plugload_schedule)
    @lighting_interior_schedule = normalize(@lighting_interior_schedule)
    @lighting_exterior_schedule = normalize(@lighting_exterior_schedule)
    @lighting_garage_schedule = normalize(@lighting_garage_schedule)
    @lighting_holiday_schedule = normalize(@lighting_holiday_schedule)
    @ceiling_fan_schedule = normalize(@ceiling_fan_schedule)

    # Generate the Sink Schedule
    # 1. Find indexes (minutes) when no one is active and add to invalid_index.
    #    This are removed from possible start time for sink
    # 2. Determine number of cluster per day
    # 3. For each cluster
    #   a. sample for number_of_events
    #   b. Re-normalize onset probability by removing invalid indexes
    #   b. Determine the start of the first event based on onset probability.
    #   c. For each event in number_of_events
    #      i. Sample the duration, and the flow rate for that duration
    #      ii. Add the time occupied by event to invalid_index
    #      ii. if more events, Offset by fixed wait time and goto c
    #   d. if more cluster, go to 3.

    mins_in_year = 1440 * total_days_in_year
    sink_activtiy_probable_mins = [0] * mins_in_year # 0 indicates sink activity cannot happen at that time
    sink_activity_sch = [0] * mins_in_year
    # mark minutes when at least one occupant is doing nothing at home as possible sink activity time
    mins_in_year.times do |min|
      step = min / minutes_per_steps
      all_simulated_values.size.times do |i| # accross occupants
        if not (all_simulated_values[i][step, 0] == 1 or all_simulated_values[i][step, 5] == 1) # if 'nothingathome' then sink can occur here
          sink_activtiy_probable_mins[min] = 1 # if at least one occupant can have sink activity; household can
        end
      end
    end

    sink_duration_probs = [0.901242, 0.076572, 0.01722, 0.003798, 0.000944, 0.000154, 4.6e-05, 2.2e-05, 2e-06]
    events_per_cluster_probs = [0.62458, 0.18693, 0.08011, 0.04330, 0.02178, 0.01504, 0.00830, 0.00467, 0.00570, 0.00285, 0.00181,
                                0.00233, 0.00130, 0.00104, 0.00026]
    hourly_onset_prob = [0.007, 0.018, 0.042, 0.062, 0.066, 0.062, 0.054, 0.050, 0.049, 0.045, 0.041, 0.043, 0.048, 0.065, 0.075,
                         0.069, 0.057, 0.048, 0.040, 0.027, 0.014, 0.007, 0.005, 0.005]
    total_clusters = 6000
    sink_between_event_gap = 2
    cluster_per_day = total_clusters / total_days_in_year
    sink_flow_rate_mean = 1.14
    sink_flow_rate_std = 0.61
    sink_flow_rate = gaussian_rand(prng, sink_flow_rate_mean, sink_flow_rate_std, 0.1)
    total_days_in_year.times do |day|
      cluster_per_day.times do |cluster_count|
        todays_probable_mins = sink_activtiy_probable_mins[(day) * 1440...((day + 1) * 1440)]
        todays_probablities = todays_probable_mins.map.with_index { |p, i| p * hourly_onset_prob[i / 60] }
        prob_sum = todays_probablities.reduce(0, :+)
        normalized_probabilities = todays_probablities.map { |p| p * 1 / prob_sum }
        cluster_start_index = weighted_random(prng, normalized_probabilities)
        num_events = weighted_random(prng, events_per_cluster_probs) + 1
        s = (day * 1440) + cluster_start_index
        num_events.times do |event_count|
          duration = weighted_random(prng, sink_duration_probs) + 1
          if cluster_start_index + duration > 1440 then duration = (1440 - cluster_start_index) + 1 end
          sink_activity_sch[s...(s + duration)] = [sink_flow_rate] * duration
          sink_activtiy_probable_mins[s...(s + duration)] = [0] * duration # Make those slots unavailable for another cluster
          s += duration + sink_between_event_gap # Two minutes gap between sink activity
          if s > 1440 then break end
        end
      end
    end
    # Generate minute level schedule for shower and bath
    # 1. For identify the shower time slots from the mkc schedule. This corresponds to personal hygiene time
    # 2. Determine if the personal hygiene is to be bath/shower using bath_ratio probability
    # 3. If it is shower
    #   a. Determine the number of events in the shower cluster (there can be multiple showers)
    #   b. For each event, sample the shower duration, and flow rate
    #   c. Fill in the time period of personal hygiene using that many events of corresponding duration.
    #      If there is room in the mkc personal hygiene slot, shift uniform randomly
    # 4. If it is bath
    #   a. Sample the bath duration and flow rate
    #   b. Fill in the mkc personal hygiene slot with the bath duration and flow rate.
    #     If there is room in the mkc personal hygiene slot, shift uniform randomly
    shower_between_event_gap = (0.51 * 60).to_i
    shower_flow_rate_mean = 2.25
    shower_flow_rate_std = 0.68
    bath_ratio = 2884.0 / 36579
    bath_duration_mean = 5.65
    bath_duration_std = 2.09
    bath_flow_rate_mean = 4.4
    bath_flow_rate_std = 1.17
    m = 0
    shower_activity_sch = [0] * mins_in_year
    bath_activity_sch = [0] * mins_in_year
    bath_flow_rate = gaussian_rand(prng, bath_flow_rate_mean, bath_flow_rate_std, 0.1)
    shower_flow_rate = gaussian_rand(prng, shower_flow_rate_mean, shower_flow_rate_std, 0.1)
    while m < mins_in_year
      if @shower_schedule[m / minutes_per_steps] > 0
        # TODO Also take into account the fractional shower_schedule means multiple occupants taking shower
        r = prng.rand
        if r <= bath_ratio
          # fill in bath for this time
          duration = gaussian_rand(prng, bath_duration_mean, bath_duration_std, 0.1)
          int_duration = duration.ceil
          flow_rate = bath_flow_rate * duration / int_duration
          # since we are rounding duration to integer minute, we compensate by scaling flow rate
          int_duration.times do
            bath_activity_sch[m] = flow_rate
            m += 1
            if m >= mins_in_year then break end
          end
          if m >= mins_in_year then break end

          while @shower_schedule[m / minutes_per_steps] > 0 and m < mins_in_year
            # skip till the end of this slot
            m += 1
          end
        else
          # fill in the shower
          num_events = sample_activity_cluster_size(prng, "shower")
          num_events.times do
            duration = sample_event_duration(prng, "shower")
            int_duration = duration.ceil
            flow_rate = shower_flow_rate * duration / int_duration
            # since we are rounding duration to integer minute, we compensate by scaling flow rate
            int_duration.times do
              shower_activity_sch[m] = flow_rate
              m += 1
              if m >= mins_in_year then break end
            end
            shower_between_event_gap.times do
              shower_activity_sch[m] = 0 # fill in the gap between events
              m += 1
              if m >= mins_in_year then break end
            end
            if m >= mins_in_year then break end
          end
          while @shower_schedule[m / minutes_per_steps] > 0 and m < mins_in_year
            # skip till the end of this slot
            m += 1
          end
        end
      else
        m += 1
      end
    end

    # Generate minute level schedule for dishwasher and clothes washer
    # 1. Identify the dishwasher/clothes washer time slots from the mkc schedule.
    # 2. Determine the number of events in the dishwasher/clothes washer cluster
    #    (it's typically composed of multiple water draw events)
    # 3. For each event, sample the event duration, and flow rate
    # 4. Fill in the dishwasher/clothes washer time slot using those water draw events

    dw_flow_rate_mean = 1.39
    dw_flow_rate_std = 0.2
    dw_event_interval = (0.16 * 60).to_i
    dw_activity_sch = [0] * mins_in_year
    m = 0
    dw_flow_rate = gaussian_rand(prng, dw_flow_rate_mean, dw_flow_rate_std, 0)
    while m < mins_in_year
      if @dish_washer_schedule[m / minutes_per_steps] > 0
        num_events = sample_activity_cluster_size(prng, "dishwasher")
        num_events.times do
          duration = sample_event_duration(prng, "dishwasher")
          int_duration = duration.ceil
          flow_rate = dw_flow_rate * duration / int_duration
          int_duration.times do
            dw_activity_sch[m] = flow_rate
            m += 1
            if m >= mins_in_year then break end
          end
          dw_event_interval.times do
            dw_activity_sch[m] = 0 # fill in the gap between events
            m += 1
            if m >= mins_in_year then break end
          end
          if m >= mins_in_year then break end
        end
        while @dish_washer_schedule[m / minutes_per_steps] > 0 and m < mins_in_year
          # skip till the end of this slot
          m += 1
        end
      else
        m += 1
      end
    end

    cw_flow_rate_mean = 2.2
    cw_flow_rate_std = 0.62
    cw_event_interval = (0.08 * 60).to_i
    cw_activity_sch = [0] * mins_in_year
    cw_load_size_probability = [0.682926829, 0.227642276, 0.056910569, 0.032520325]
    m = 0
    cw_flow_rate = gaussian_rand(prng, cw_flow_rate_mean, cw_flow_rate_std, 0)
    while m < mins_in_year
      if @clothes_washer_schedule[m / minutes_per_steps] > 0
        num_loads = weighted_random(prng, cw_load_size_probability) + 1
        num_loads.times do
          num_events = sample_activity_cluster_size(prng, "clothes_washer")
          num_events.times do
            duration = sample_event_duration(prng, "clothes_washer")
            int_duration = duration.ceil
            flow_rate = cw_flow_rate * duration.to_f / int_duration
            int_duration.times do
              cw_activity_sch[m] = flow_rate
              m += 1
              if m >= mins_in_year then break end
            end
            cw_event_interval.times do
              cw_activity_sch[m] = 0 # fill in the gap between events
              m += 1
              if m >= mins_in_year then break end
            end
            if m >= mins_in_year then break end
          end
        end
        while @clothes_washer_schedule[m / minutes_per_steps] > 0 and m < mins_in_year
          # skip till the end of this slot
          m += 1
        end
      else
        m += 1
      end
    end
    sink_activity_sch = sink_activity_sch.rotate(-4 * 60) # 4 am shifting
    sink_activity_sch = aggregate_array(sink_activity_sch, minutes_per_steps)
    sink_max_flow_rate = sink_activity_sch.max
    @sink_schedule = sink_activity_sch.map { |flow| flow / sink_max_flow_rate }

    dw_activity_sch = aggregate_array(dw_activity_sch, minutes_per_steps)
    dishwasher_max_flow_rate = dw_activity_sch.max
    @dish_washer_schedule = dw_activity_sch.map { |flow| flow / dishwasher_max_flow_rate }
    # dishwasher_max_flow_rate = 2.8186 # gal/min # FIXME: calculate this from unnormalized schedule
    @model.getBuilding.additionalProperties.setFeature("Dishwasher Max Flow Rate", dishwasher_max_flow_rate)

    cw_activity_sch = aggregate_array(cw_activity_sch, minutes_per_steps)
    clothes_washer_max_flow_rate = cw_activity_sch.max
    @clothes_washer_schedule = cw_activity_sch.map { |flow| flow / clothes_washer_max_flow_rate }
    # clothes_washer_max_flow_rate = 5.0354 # gal/min # FIXME: calculate this from unnormalized schedule
    @model.getBuilding.additionalProperties.setFeature("Clothes Washer Max Flow Rate", clothes_washer_max_flow_rate)

    shower_activity_sch = aggregate_array(shower_activity_sch, minutes_per_steps)
    shower_max_flow_rate = shower_activity_sch.max
    @shower_schedule = shower_activity_sch.map { |flow| flow / shower_max_flow_rate }
    # shower_max_flow_rate = 4.079 # gal/min # FIXME: calculate this from unnormalized schedule
    @model.getBuilding.additionalProperties.setFeature("Shower Max Flow Rate", shower_max_flow_rate)

    @model.getBuilding.additionalProperties.setFeature("Sink Max Flow Rate", sink_max_flow_rate)

    bath_activity_sch = aggregate_array(bath_activity_sch, minutes_per_steps)
    bath_max_flow_rate = bath_activity_sch.max
    @bath_schedule = bath_activity_sch.map { |flow| flow / bath_max_flow_rate }
    # bath_max_flow_rate = 7.0312 # gal/min # FIXME: calculate this from unnormalized schedule
    @model.getBuilding.additionalProperties.setFeature("Bath Max Flow Rate", bath_max_flow_rate)
    @clothes_dryer_exhaust_schedule = @clothes_dryer_schedule

    return true
  end

  def aggregate_array(array, group_size)
    new_array_size = array.size / group_size
    new_array = [0] * new_array_size
    new_array_size.times do |j|
      new_array[j] = array[(j * group_size)...(j + 1) * group_size].reduce(0, :+)
    end
    return new_array
  end

  def sample_activity_cluster_size(prng, activity_type_name)
    cluster_size_file = @schedules_path + "/#{activity_type_name}_cluster_size_probability.csv"
    cluster_size_probabilities = CSV.read(cluster_size_file)
    cluster_size_probabilities = cluster_size_probabilities.map { |entry| entry[0].to_f }
    return weighted_random(prng, cluster_size_probabilities) + 1
  end

  def sample_event_duration(prng, event_type)
    duration_file = @schedules_path + "/#{event_type}_event_duration_probability.csv"
    duration_probabilities = CSV.read(duration_file)
    durations = duration_probabilities.map { |entry| (entry[0].to_f) / 60 } # convert to minute
    probabilities = duration_probabilities.map { |entry| entry[1].to_f }
    return durations[weighted_random(prng, probabilities)]
  end

  def sample_activity_duration(prng, occ_type_id, activity, day_type, hour)
    # States are: 'sleeping','shower','laundry','cooking', 'dishwashing', 'absent', 'nothingAtHome'
    if hour < 8
      time_of_day = "morning"
    elsif hour < 16
      time_of_day = "midday"
    else
      time_of_day = "evening"
    end

    if activity == 1
      activity_name = "shower"
    elsif activity == 2
      activity_name = "laundry"
    elsif activity == 3
      activity_name = "cooking"
    elsif activity == 4
      activity_name = "dishwashing"
    else
      return 1 # all other activity will span only one timestep
    end
    duration_file = @schedules_path + "/#{day_type}/duration_probability/"\
                    "cluster_#{occ_type_id}_#{activity_name}_#{time_of_day}_duration_probability.csv"
    duration_probabilities = CSV.read(duration_file)
    durations = duration_probabilities.map { |entry| entry[0].to_i }
    probabilities = duration_probabilities.map { |entry| entry[1].to_f }
    return durations[weighted_random(prng, probabilities)]
  end

  def export(output_path:)
    CSV.open(output_path, "w") do |csv|
      csv << [
        "occupants",
        "cooking_range",
        "plug_loads",
        "lighting_interior",
        "lighting_exterior",
        "lighting_garage",
        "lighting_exterior_holiday",
        "clothes_washer",
        "clothes_dryer",
        "dishwasher",
        "baths",
        "showers",
        "sinks",
        "ceiling_fan",
        "clothes_dryer_exhaust",
        "sleep"
      ]
      @shower_schedule.size.times do |i|
        csv << [
          (1 - @away_schedule[i]),
          @cooking_schedule[i],
          @plugload_schedule[i],
          @lighting_interior_schedule[i],
          @lighting_exterior_schedule[i],
          @lighting_garage_schedule[i],
          @lighting_holiday_schedule[i],
          @clothes_washer_schedule[i],
          @clothes_dryer_schedule[i],
          @dish_washer_schedule[i],
          @bath_schedule[i],
          @shower_schedule[i],
          @sink_schedule[i],
          @ceiling_fan_schedule[i],
          @clothes_dryer_exhaust_schedule[i],
          @sleeping_schedule[i]
        ]
      end
    end

    return true
  end

  def gaussian_rand(prng, mean, std, min = nil, max = nil)
    t = 2 * Math::PI * prng.rand
    r = Math.sqrt(-2 * Math.log(1 - prng.rand))
    scale = std * r
    x = mean + scale * Math.cos(t)
    if not min.nil? and x < min then x = min end
    if not max.nil? and x > max then x = max end
    # y = mean + scale * Math.sin(t)
    return x
  end

  def sum_across_occupants(all_simulated_values, activity_index, time_index, max_clip = nil)
    sum = 0
    all_simulated_values.size.times do |i|
      sum += all_simulated_values[i][time_index, activity_index]
    end
    if not max_clip.nil? and sum > max_clip
      sum = max_clip
    end
    return sum
  end

  def normalize(arr)
    m = arr.max
    arr = arr.map { |a| a / m }
    return arr
  end

  def scale_lighting_by_occupancy(lighting_sch, minute, active_occupant_percentage)
    day_start = minute / 1440
    day_sch = lighting_sch[day_start * 24, 24]
    current_val = lighting_sch[minute / 60]
    return day_sch.min + (current_val - day_sch.min) * active_occupant_percentage
  end

  def get_value_from_daily_sch(daily_sch, month, is_weekday, minute, active_occupant_percentage)
    is_weekday ? sch = daily_sch[0] : sch = daily_sch[1]
    sch = sch.map { |x| x.to_f }
    full_occupancy_current_val = sch[((minute % 1440) / 60).to_i].to_f * daily_sch[2][month - 1].to_f
    return sch.min + (full_occupancy_current_val - sch.min) * active_occupant_percentage
  end

  def weighted_random(prng, weights)
    n = prng.rand
    cum_weights = 0
    weights.each_with_index do |w, index|
      cum_weights += w
      if n <= cum_weights
        return index
      end
    end
    return weights.size - 1 # If the prob weight don't sum to n, return last index
  end

  def get_holiday_lighting_sch(model, runner, holiday_sch)
    holiday_start_day = 332 # November 27
    holiday_end_day = 6 # Jan 6
    @model.getYearDescription.isLeapYear ? total_days_in_year = 366 : total_days_in_year = 365
    sch = [0] * 24 * total_days_in_year
    final_days = total_days_in_year - holiday_start_day + 1
    beginning_days = holiday_end_day
    sch[0...(holiday_end_day) * 24] = holiday_sch * beginning_days
    sch[(holiday_start_day - 1) * 24..-1] = holiday_sch * final_days
    m = sch.max
    sch = sch.map { |s| s / m }
    return sch
  end

  def get_other_lighting_sch(model, runner, weather, sch_option_type, weekday_sch, weekend_sch, monthly_sch)
    # TODO fix this to return 24*num_of_days_in_year values
    lighting_sch = nil
    if sch_option_type == Constants.OptionTypeLightingScheduleCalculated
      lighting_sch = get_interior_lighting_sch(model, runner, weather, sch_option_type, monthly_sch)
    end

    # Design day schedules used when autosizing
    winter_design_day_sch = OpenStudio::Model::ScheduleDay.new(model)
    winter_design_day_sch.addValue(OpenStudio::Time.new(0, 24, 0, 0), 0)
    summer_design_day_sch = OpenStudio::Model::ScheduleDay.new(model)
    summer_design_day_sch.addValue(OpenStudio::Time.new(0, 24, 0, 0), 1)
    # Create schedule
    if lighting_sch.nil?
      sch = MonthWeekdayWeekendSchedule.new(model, runner, Constants.ObjectNameLightingGarage, weekday_sch,
                                            weekend_sch, monthly_sch, mult_weekday = 1.0, mult_weekend = 1.0,
                                            normalize_values = true, create_sch_object = true,
                                            winter_design_day_sch, summer_design_day_sch)
    else
      sch = HourlyByMonthSchedule.new(model, runner, Constants.ObjectNameLightingGarage,
                                      lighting_sch, lighting_sch, normalize_values = true, create_sch_object = true,
                                      winter_design_day_sch, summer_design_day_sch)
    end
    return sch
  end

  def get_interior_lighting_sch(model, runner, weather, sch_option_type, monthly_sch)
    lat = weather.header.Latitude
    long = weather.header.Longitude
    tz = weather.header.Timezone
    std_long = -tz * 15
    pi = Math::PI

    # Get number of days in months/year
    year_description = model.getYearDescription
    num_days_in_months = Constants.NumDaysInMonths(year_description.isLeapYear)
    num_days_in_year = Constants.NumDaysInYear(year_description.isLeapYear)

    # Sunrise and sunset hours
    sunrise_hour = []
    sunset_hour = []
    normalized_hourly_lighting = [[1..24], [1..24], [1..24], [1..24], [1..24], [1..24], [1..24], [1..24], [1..24], [1..24], [1..24], [1..24]]
    for month in 0..11
      if lat < 51.49
        m_num = month + 1
        jul_day = m_num * 30 - 15
        if not (m_num < 4 or m_num > 10)
          offset = 1
        else
          offset = 0
        end
        declination = 23.45 * Math.sin(0.9863 * (284 + jul_day) * 0.01745329)
        deg_rad = pi / 180
        rad_deg = 1 / deg_rad
        b = (jul_day - 1) * 0.9863
        equation_of_time = (0.01667 * (0.01719 + 0.42815 * Math.cos(deg_rad * b) - 7.35205 * Math.sin(deg_rad * b) - 3.34976 * Math.cos(deg_rad * (2 * b)) - 9.37199 * Math.sin(deg_rad * (2 * b))))
        sunset_hour_angle = rad_deg * (Math.acos(-1 * Math.tan(deg_rad * lat) * Math.tan(deg_rad * declination)))
        sunrise_hour[month] = offset + (12.0 - 1 * sunset_hour_angle / 15.0) - equation_of_time - (std_long + long) / 15
        sunset_hour[month] = offset + (12.0 + 1 * sunset_hour_angle / 15.0) - equation_of_time - (std_long + long) / 15
      else
        sunrise_hour = [8.125726064, 7.449258072, 6.388688653, 6.232405257, 5.27722936, 4.84705384, 5.127512162, 5.860163988, 6.684378904, 7.521267411, 7.390441945, 8.080667697]
        sunset_hour = [16.22214058, 17.08642353, 17.98324493, 19.83547864, 20.65149672, 21.20662992, 21.12124777, 20.37458274, 19.25834757, 18.08155615, 16.14359164, 15.75571306]
      end
    end

    dec_kws = [0.075, 0.055, 0.040, 0.035, 0.030, 0.025, 0.025, 0.025, 0.025, 0.025, 0.025, 0.030, 0.045, 0.075, 0.130, 0.160, 0.140, 0.100, 0.075, 0.065, 0.060, 0.050, 0.045, 0.045, 0.045, 0.045, 0.045, 0.045, 0.050, 0.060, 0.080, 0.130, 0.190, 0.230, 0.250, 0.260, 0.260, 0.250, 0.240, 0.225, 0.225, 0.220, 0.210, 0.200, 0.180, 0.155, 0.125, 0.100]
    june_kws = [0.060, 0.040, 0.035, 0.025, 0.020, 0.020, 0.020, 0.020, 0.020, 0.020, 0.020, 0.020, 0.020, 0.025, 0.030, 0.030, 0.025, 0.020, 0.015, 0.015, 0.015, 0.015, 0.015, 0.015, 0.015, 0.015, 0.015, 0.015, 0.015, 0.015, 0.015, 0.015, 0.020, 0.020, 0.020, 0.025, 0.025, 0.030, 0.030, 0.035, 0.045, 0.060, 0.085, 0.125, 0.145, 0.130, 0.105, 0.080]
    lighting_seasonal_multiplier =   [1.075, 1.064951905, 1.0375, 1.0, 0.9625, 0.935048095, 0.925, 0.935048095, 0.9625, 1.0, 1.0375, 1.064951905]
    amplConst1 = 0.929707907917098
    sunsetLag1 = 2.45016230615269
    stdDevCons1 = 1.58679810983444
    amplConst2 = 1.1372291802273
    sunsetLag2 = 20.1501965859073
    stdDevCons2 = 2.36567663279954

    monthly_kwh_per_day = []
    wtd_avg_monthly_kwh_per_day = 0
    for monthNum in 1..12
      month = monthNum - 1
      monthHalfHourKWHs = [0]
      for hourNum in 0..9
        monthHalfHourKWHs[hourNum] = june_kws[hourNum]
      end
      for hourNum in 9..17
        hour = (hourNum + 1.0) * 0.5
        monthHalfHourKWHs[hourNum] = (monthHalfHourKWHs[8] - (0.15 / (2 * pi)) * Math.sin((2 * pi) * (hour - 4.5) / 3.5) + (0.15 / 3.5) * (hour - 4.5)) * lighting_seasonal_multiplier[month]
      end
      for hourNum in 17..29
        hour = (hourNum + 1.0) * 0.5
        monthHalfHourKWHs[hourNum] = (monthHalfHourKWHs[16] - (-0.02 / (2 * pi)) * Math.sin((2 * pi) * (hour - 8.5) / 5.5) + (-0.02 / 5.5) * (hour - 8.5)) * lighting_seasonal_multiplier[month]
      end
      for hourNum in 29..45
        hour = (hourNum + 1.0) * 0.5
        monthHalfHourKWHs[hourNum] = (monthHalfHourKWHs[28] + amplConst1 * Math.exp((-1.0 * (hour - (sunset_hour[month] + sunsetLag1))**2) / (2.0 * ((25.5 / ((6.5 - monthNum).abs + 20.0)) * stdDevCons1)**2)) / ((25.5 / ((6.5 - monthNum).abs + 20.0)) * stdDevCons1 * (2.0 * pi)**0.5))
      end
      for hourNum in 45..46
        hour = (hourNum + 1.0) * 0.5
        temp1 = (monthHalfHourKWHs[44] + amplConst1 * Math.exp((-1.0 * (hour - (sunset_hour[month] + sunsetLag1))**2) / (2.0 * ((25.5 / ((6.5 - monthNum).abs + 20.0)) * stdDevCons1)**2)) / ((25.5 / ((6.5 - monthNum).abs + 20.0)) * stdDevCons1 * (2.0 * pi)**0.5))
        temp2 = (0.04 + amplConst2 * Math.exp((-1.0 * (hour - (sunsetLag2))**2) / (2.0 * (stdDevCons2)**2)) / (stdDevCons2 * (2.0 * pi)**0.5))
        if sunsetLag2 < sunset_hour[month] + sunsetLag1
          monthHalfHourKWHs[hourNum] = [temp1, temp2].min
        else
          monthHalfHourKWHs[hourNum] = [temp1, temp2].max
        end
      end
      for hourNum in 46..47
        hour = (hourNum + 1) * 0.5
        monthHalfHourKWHs[hourNum] = (0.04 + amplConst2 * Math.exp((-1.0 * (hour - (sunsetLag2))**2) / (2.0 * (stdDevCons2)**2)) / (stdDevCons2 * (2.0 * pi)**0.5))
      end

      sum_kWh = 0.0
      for timenum in 0..47
        sum_kWh = sum_kWh + monthHalfHourKWHs[timenum]
      end
      for hour in 0..23
        ltg_hour = (monthHalfHourKWHs[hour * 2] + monthHalfHourKWHs[hour * 2 + 1]).to_f
        normalized_hourly_lighting[month][hour] = ltg_hour / sum_kWh
        monthly_kwh_per_day[month] = sum_kWh / 2.0
      end
      wtd_avg_monthly_kwh_per_day = wtd_avg_monthly_kwh_per_day + monthly_kwh_per_day[month] * num_days_in_months[month] / num_days_in_year
    end

    # Get the seasonal multipliers
    seasonal_multiplier = []
    if sch_option_type == Constants.OptionTypeLightingScheduleCalculated
      for month in 0..11
        seasonal_multiplier[month] = (monthly_kwh_per_day[month] / wtd_avg_monthly_kwh_per_day)
      end
    elsif sch_option_type == Constants.OptionTypeLightingScheduleUserSpecified
      vals = monthly_sch.split(",")
      vals.each do |val|
        begin Float(val)
        rescue
          runner.registerError("A comma-separated string of 12 numbers must be entered for the monthly schedule.")
          return false
        end
      end
      seasonal_multiplier = vals.map { |i| i.to_f }
      if seasonal_multiplier.length != 12
        runner.registerError("A comma-separated string of 12 numbers must be entered for the monthly schedule.")
        return false
      end
    end

    # Calculate normalized monthly lighting fractions
    sumproduct_seasonal_multiplier = 0
    for month in 0..11
      sumproduct_seasonal_multiplier += seasonal_multiplier[month] * num_days_in_months[month]
    end

    normalized_monthly_lighting = seasonal_multiplier
    for month in 0..11
      normalized_monthly_lighting[month] = seasonal_multiplier[month] * num_days_in_months[month] / sumproduct_seasonal_multiplier
    end

    # Calc schedule values
    lighting_sch = [[], [], [], [], [], [], [], [], [], [], [], []]
    for month in 0..11
      for hour in 0..23
        lighting_sch[month][hour] = normalized_monthly_lighting[month] * normalized_hourly_lighting[month][hour] / num_days_in_months[month]
      end
    end
    sch = []
    for month in 0..11
      sch << lighting_sch[month] * num_days_in_months[month]
    end
    sch = sch.flatten
    m = sch.max
    sch = sch.map { |s| s / m }
    return sch
  end
end

class SchedulesFile
  def initialize(runner:,
                 model:,
                 schedules_path: nil,
                 **remainder)

    @validated = true
    @runner = runner
    @model = model
    @schedules_path = schedules_path
    if @schedules_path.nil?
      @schedules_path = get_schedules_path
    end
    @external_file = get_external_file
    @schedules = {}
  end

  def validated?
    return @validated
  end

  def schedules
    return @schedules
  end

  def get_col_index(col_name:)
    headers = CSV.open(@schedules_path, "r") { |csv| csv.first }
    col_num = headers.index(col_name)
    return col_num
  end

  def get_col_name(col_index:)
    headers = CSV.open(@schedules_path, "r") { |csv| csv.first }
    col_name = headers[col_index]
    return col_name
  end

  def create_schedule_file(col_name:,
                           rows_to_skip: 1)
    @model.getScheduleFiles.each do |schedule_file|
      next if schedule_file.name.to_s != col_name

      return schedule_file
    end

    import(col_name: col_name)

    if @schedules[col_name].nil?
      @runner.registerError("Could not find the '#{col_name}' schedule.")
      return false
    end

    col_index = get_col_index(col_name: col_name)
    year_description = @model.getYearDescription
    num_hrs_in_year = Constants.NumHoursInYear(year_description.isLeapYear)
    schedule_length = @schedules[col_name].length
    min_per_item = 60.0 / (schedule_length / num_hrs_in_year)

    schedule_file = OpenStudio::Model::ScheduleFile.new(@external_file)
    schedule_file.setName(col_name)
    schedule_file.setColumnNumber(col_index + 1)
    schedule_file.setRowstoSkipatTop(rows_to_skip)
    schedule_file.setNumberofHoursofData(num_hrs_in_year.to_i)
    schedule_file.setMinutesperItem("#{min_per_item.to_i}")

    return schedule_file
  end

  def annual_equivalent_full_load_hrs(col_name:)
    import(col_name: col_name)

    year_description = @model.getYearDescription
    num_hrs_in_year = Constants.NumHoursInYear(year_description.isLeapYear)
    schedule_length = @schedules[col_name].length
    min_per_item = 60.0 / (schedule_length / num_hrs_in_year)

    ann_equiv_full_load_hrs = @schedules[col_name].reduce(:+) / (60.0 / min_per_item)

    return ann_equiv_full_load_hrs
  end

  def calc_design_level_from_annual_kwh(col_name:,
                                        annual_kwh:)

    ann_equiv_full_load_hrs = annual_equivalent_full_load_hrs(col_name: col_name)
    design_level = annual_kwh * 1000.0 / ann_equiv_full_load_hrs # W

    return design_level
  end

  def calc_design_level_from_annual_therm(col_name:,
                                          annual_therm:)

    annual_kwh = UnitConversions.convert(annual_therm, "therm", "kWh")
    design_level = calc_design_level_from_annual_kwh(col_name: col_name, annual_kwh: annual_kwh)

    return design_level
  end

  def calc_design_level_from_daily_kwh(col_name:,
                                       daily_kwh:)

    full_load_hrs = annual_equivalent_full_load_hrs(col_name: col_name)
    year_description = @model.getYearDescription
    num_days_in_year = Constants.NumDaysInYear(year_description.isLeapYear)
    design_level = UnitConversions.convert(daily_kwh / (full_load_hrs / num_days_in_year), "kW", "W")

    return design_level
  end

  def calc_design_level_from_daily_therm(col_name:,
                                         daily_therm:)

    daily_kwh = UnitConversions.convert(daily_therm, "therm", "kWh")
    design_level = calc_design_level_from_daily_kwh(col_name: col_name, daily_kwh: daily_kwh)

    return design_level
  end

  def calc_peak_flow_from_daily_gpm(daily_water:)
    peak_flow = UnitConversions.convert(Constants.PeakFlowRate * daily_water, "gal/min", "m^3/s")

    return peak_flow
  end

  def calc_daily_gpm_from_peak_flow(peak_flow:)
    daily_water = UnitConversions.convert(peak_flow / Constants.PeakFlowRate, "m^3/s", "gal/min")

    return daily_water
  end

  def validate_schedule(col_name:,
                        values:)

    year_description = @model.getYearDescription
    num_hrs_in_year = Constants.NumHoursInYear(year_description.isLeapYear)
    schedule_length = values.length

    if values.max > 1
      @runner.registerError("The max value of schedule '#{col_name}' is greater than 1.")
      @validated = false
    end

    min_per_item = 60.0 / (schedule_length / num_hrs_in_year)
    unless [1, 2, 3, 4, 5, 6, 10, 12, 15, 20, 30, 60].include? min_per_item
      @runner.registerError("Calculated an invalid schedule min_per_item=#{min_per_item}.")
      @validated = false
    end
  end

  def external_file
    return @external_file
  end

  def get_external_file
    if File.exist? @schedules_path
      external_file = OpenStudio::Model::ExternalFile::getExternalFile(@model, @schedules_path)
      if external_file.is_initialized
        external_file = external_file.get
        external_file.setName(external_file.fileName)
      end
    end
    return external_file
  end

  def import(col_name:)
    return if @schedules.keys.include? col_name

    columns = CSV.read(@schedules_path).transpose
    columns.each do |col|
      next if col_name != col[0]

      values = col[1..-1].reject { |v| v.nil? }
      values = values.map { |v| v.to_f }
      validate_schedule(col_name: col_name, values: values)
      @schedules[col_name] = values
    end
  end

  def export
    return false if @schedules_path.nil?

    CSV.open(@schedules_path, "wb") do |csv|
      csv << @schedules.keys
      rows = @schedules.values.transpose
      rows.each do |row|
        csv << row
      end
    end

    return true
  end

  def get_schedules_path
    sch_path = @model.getBuilding.additionalProperties.getFeatureAsString("Schedules Path")
    if not sch_path.is_initialized # ResidentialScheduleGenerator not in workflow
      if @model.getYearDescription.isLeapYear
        sch_path = File.join(File.dirname(__FILE__), "../../../../files/8784.csv")
      else
        sch_path = File.join(File.dirname(__FILE__), "../../../../files/8760.csv")
      end
    else
      sch_path = sch_path.get
    end
    return sch_path
  end
end
