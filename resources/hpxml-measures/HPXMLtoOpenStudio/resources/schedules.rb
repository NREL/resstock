# frozen_string_literal: true

# Annual constant schedule
class ScheduleConstant
  def initialize(model, sch_name, val = 1.0, schedule_type_limits_name = nil, unavailable_periods: [])
    year = model.getYearDescription.assumedYear
    @schedule = create_schedule(model, sch_name, val, year, schedule_type_limits_name, unavailable_periods)
  end

  def schedule
    return @schedule
  end

  private

  def create_schedule(model, sch_name, val, year, schedule_type_limits_name, unavailable_periods)
    if unavailable_periods.empty?
      if val == 1.0 && (schedule_type_limits_name.nil? || schedule_type_limits_name == Constants.ScheduleTypeLimitsOnOff)
        schedule = model.alwaysOnDiscreteSchedule
      elsif val == 0.0 && (schedule_type_limits_name.nil? || schedule_type_limits_name == Constants.ScheduleTypeLimitsOnOff)
        schedule = model.alwaysOffDiscreteSchedule
      else
        schedule = OpenStudio::Model::ScheduleConstant.new(model)
        schedule.setName(sch_name)
        schedule.setValue(val)

        Schedule.set_schedule_type_limits(model, schedule, schedule_type_limits_name)
      end
    else
      schedule = OpenStudio::Model::ScheduleRuleset.new(model)
      schedule.setName(sch_name)
      schedule.defaultDaySchedule.setName(sch_name + ' default day')

      default_day_sch = schedule.defaultDaySchedule
      default_day_sch.clearValues
      default_day_sch.addValue(OpenStudio::Time.new(0, 24, 0, 0), val)

      Schedule.set_unavailable_periods(schedule, sch_name, unavailable_periods, year)

      Schedule.set_schedule_type_limits(model, schedule, schedule_type_limits_name)
    end

    return schedule
  end
end

# Annual schedule defined by 12 24-hour values for weekdays and weekends.
class HourlyByMonthSchedule
  # weekday_month_by_hour_values must be a 12-element array of 24-element arrays of numbers.
  # weekend_month_by_hour_values must be a 12-element array of 24-element arrays of numbers.
  def initialize(model, sch_name, weekday_month_by_hour_values, weekend_month_by_hour_values,
                 schedule_type_limits_name = nil, normalize_values = true, unavailable_periods: nil)
    year = model.getYearDescription.assumedYear
    @weekday_month_by_hour_values = validate_values(weekday_month_by_hour_values, 12, 24)
    @weekend_month_by_hour_values = validate_values(weekend_month_by_hour_values, 12, 24)
    if normalize_values
      @maxval = calc_max_val()
    else
      @maxval = 1.0
    end
    @schedule = create_schedule(model, sch_name, year, schedule_type_limits_name, unavailable_periods)
  end

  def calc_design_level(val)
    return val * 1000
  end

  def schedule
    return @schedule
  end

  def maxval
    return @maxval
  end

  private

  def validate_values(vals, num_outter_values, num_inner_values)
    err_msg = "A #{num_outter_values}-element array with #{num_inner_values}-element arrays of numbers must be entered for the schedule."
    if not vals.is_a?(Array)
      fail err_msg
    end

    begin
      if vals.length != num_outter_values
        fail err_msg
      end

      vals.each do |val|
        if not val.is_a?(Array)
          fail err_msg
        end
        if val.length != num_inner_values
          fail err_msg
        end
      end
    rescue
      fail err_msg
    end
    return vals
  end

  def calc_max_val()
    maxval = [@weekday_month_by_hour_values.flatten.max, @weekend_month_by_hour_values.flatten.max].max
    if maxval == 0.0
      maxval = 1.0 # Prevent divide by zero
    end
    return maxval
  end

  def create_schedule(model, sch_name, year, schedule_type_limits_name, unavailable_periods)
    day_startm = Schedule.day_start_months(year)
    day_endm = Schedule.day_end_months(year)

    time = []
    for h in 1..24
      time[h] = OpenStudio::Time.new(0, h, 0, 0)
    end

    schedule = OpenStudio::Model::ScheduleRuleset.new(model)
    schedule.setName(sch_name)
    schedule.defaultDaySchedule.setName(sch_name + ' default day')

    prev_wkdy_vals = nil
    prev_wkdy_rule = nil
    prev_wknd_vals = nil
    prev_wknd_rule = nil
    for m in 1..12
      date_s = OpenStudio::Date::fromDayOfYear(day_startm[m - 1], year)
      date_e = OpenStudio::Date::fromDayOfYear(day_endm[m - 1], year)

      wkdy_vals = []
      wknd_vals = []
      for h in 1..24
        wkdy_vals[h] = (@weekday_month_by_hour_values[m - 1][h - 1]) / @maxval
        wknd_vals[h] = (@weekend_month_by_hour_values[m - 1][h - 1]) / @maxval
      end

      if (wkdy_vals == prev_wkdy_vals) && (wknd_vals == prev_wknd_vals)
        # Extend end date of current rule(s)
        prev_wkdy_rule.setEndDate(date_e) unless prev_wkdy_rule.nil?
        prev_wknd_rule.setEndDate(date_e) unless prev_wknd_rule.nil?
      elsif wkdy_vals == wknd_vals
        # Alldays
        wkdy_rule = OpenStudio::Model::ScheduleRule.new(schedule)
        wkdy_rule.setName(sch_name + " #{Schedule.allday_name} ruleset#{m}")
        wkdy = wkdy_rule.daySchedule
        wkdy.setName(sch_name + " #{Schedule.allday_name}#{m}")
        previous_value = wkdy_vals[1]
        for h in 1..24
          next if (h != 24) && (wkdy_vals[h + 1] == previous_value)

          wkdy.addValue(time[h], previous_value)
          previous_value = wkdy_vals[h + 1]
        end
        Schedule.set_weekday_rule(wkdy_rule)
        Schedule.set_weekend_rule(wkdy_rule)
        wkdy_rule.setStartDate(date_s)
        wkdy_rule.setEndDate(date_e)
        prev_wkdy_rule = wkdy_rule
        prev_wknd_rule = nil
      else
        # Weekdays
        wkdy_rule = OpenStudio::Model::ScheduleRule.new(schedule)
        wkdy_rule.setName(sch_name + " #{Schedule.weekday_name} ruleset#{m}")
        wkdy = wkdy_rule.daySchedule
        wkdy.setName(sch_name + " #{Schedule.weekday_name}#{m}")
        previous_value = wkdy_vals[1]
        for h in 1..24
          next if (h != 24) && (wkdy_vals[h + 1] == previous_value)

          wkdy.addValue(time[h], previous_value)
          previous_value = wkdy_vals[h + 1]
        end
        Schedule.set_weekday_rule(wkdy_rule)
        wkdy_rule.setStartDate(date_s)
        wkdy_rule.setEndDate(date_e)
        prev_wkdy_rule = wkdy_rule

        # Weekends
        wknd_rule = OpenStudio::Model::ScheduleRule.new(schedule)
        wknd_rule.setName(sch_name + " #{Schedule.weekend_name} ruleset#{m}")
        wknd = wknd_rule.daySchedule
        wknd.setName(sch_name + " #{Schedule.weekend_name}#{m}")
        previous_value = wknd_vals[1]
        for h in 1..24
          next if (h != 24) && (wknd_vals[h + 1] == previous_value)

          wknd.addValue(time[h], previous_value)
          previous_value = wknd_vals[h + 1]
        end
        Schedule.set_weekend_rule(wknd_rule)
        wknd_rule.setStartDate(date_s)
        wknd_rule.setEndDate(date_e)
        prev_wknd_rule = wknd_rule
      end

      prev_wkdy_vals = wkdy_vals
      prev_wknd_vals = wknd_vals
    end

    Schedule.set_unavailable_periods(schedule, sch_name, unavailable_periods, year)

    Schedule.set_schedule_type_limits(model, schedule, schedule_type_limits_name)

    return schedule
  end
end

# Annual schedule defined by 365 24-hour values for weekdays and weekends.
class HourlyByDaySchedule
  # weekday_day_by_hour_values must be a 365-element array of 24-element arrays of numbers.
  # weekend_day_by_hour_values must be a 365-element array of 24-element arrays of numbers.
  def initialize(model, sch_name, weekday_day_by_hour_values, weekend_day_by_hour_values,
                 schedule_type_limits_name = nil, normalize_values = true, unavailable_periods: nil)
    year = model.getYearDescription.assumedYear
    num_days = Constants.NumDaysInYear(year)
    @weekday_day_by_hour_values = validate_values(weekday_day_by_hour_values, num_days, 24)
    @weekend_day_by_hour_values = validate_values(weekend_day_by_hour_values, num_days, 24)
    if normalize_values
      @maxval = calc_max_val()
    else
      @maxval = 1.0
    end
    @schedule = create_schedule(model, sch_name, year, num_days, schedule_type_limits_name, unavailable_periods)
  end

  def calc_design_level(val)
    return val * 1000
  end

  def schedule
    return @schedule
  end

  def maxval
    return @maxval
  end

  private

  def validate_values(vals, num_outter_values, num_inner_values)
    err_msg = "A #{num_outter_values}-element array with #{num_inner_values}-element arrays of numbers must be entered for the schedule."
    if not vals.is_a?(Array)
      fail err_msg
    end

    begin
      if vals.length != num_outter_values
        fail err_msg
      end

      vals.each do |val|
        if not val.is_a?(Array)
          fail err_msg
        end
        if val.length != num_inner_values
          fail err_msg
        end
      end
    rescue
      fail err_msg
    end
    return vals
  end

  def calc_max_val()
    maxval = [@weekday_day_by_hour_values.flatten.max, @weekend_day_by_hour_values.flatten.max].max
    if maxval == 0.0
      maxval = 1.0 # Prevent divide by zero
    end
    return maxval
  end

  def create_schedule(model, sch_name, year, num_days, schedule_type_limits_name, unavailable_periods)
    time = []
    for h in 1..24
      time[h] = OpenStudio::Time.new(0, h, 0, 0)
    end

    schedule = OpenStudio::Model::ScheduleRuleset.new(model)
    schedule.setName(sch_name)
    schedule.defaultDaySchedule.setName(sch_name + ' default day')

    prev_wkdy_vals = nil
    prev_wkdy_rule = nil
    prev_wknd_vals = nil
    prev_wknd_rule = nil
    for d in 1..num_days
      date_s = OpenStudio::Date::fromDayOfYear(d, year)
      date_e = OpenStudio::Date::fromDayOfYear(d, year)

      wkdy_vals = []
      wknd_vals = []
      for h in 1..24
        wkdy_vals[h] = (@weekday_day_by_hour_values[d - 1][h - 1]) / @maxval
        wknd_vals[h] = (@weekend_day_by_hour_values[d - 1][h - 1]) / @maxval
      end

      if (wkdy_vals == prev_wkdy_vals) && (wknd_vals == prev_wknd_vals)
        # Extend end date of current rule(s)
        prev_wkdy_rule.setEndDate(date_e) unless prev_wkdy_rule.nil?
        prev_wknd_rule.setEndDate(date_e) unless prev_wknd_rule.nil?
      elsif wkdy_vals == wknd_vals
        # Alldays
        wkdy_rule = OpenStudio::Model::ScheduleRule.new(schedule)
        wkdy_rule.setName(sch_name + " #{Schedule.allday_name} ruleset#{d}")
        wkdy = wkdy_rule.daySchedule
        wkdy.setName(sch_name + " #{Schedule.allday_name}#{d}")
        previous_value = wkdy_vals[1]
        for h in 1..24
          next if (h != 24) && (wkdy_vals[h + 1] == previous_value)

          wkdy.addValue(time[h], previous_value)
          previous_value = wkdy_vals[h + 1]
        end
        Schedule.set_weekday_rule(wkdy_rule)
        Schedule.set_weekend_rule(wkdy_rule)
        wkdy_rule.setStartDate(date_s)
        wkdy_rule.setEndDate(date_e)
        prev_wkdy_rule = wkdy_rule
        prev_wknd_rule = nil
      else
        # Weekdays
        wkdy_rule = OpenStudio::Model::ScheduleRule.new(schedule)
        wkdy_rule.setName(sch_name + " #{Schedule.weekday_name} ruleset#{d}")
        wkdy = wkdy_rule.daySchedule
        wkdy.setName(sch_name + " #{Schedule.weekday_name}#{d}")
        previous_value = wkdy_vals[1]
        for h in 1..24
          next if (h != 24) && (wkdy_vals[h + 1] == previous_value)

          wkdy.addValue(time[h], previous_value)
          previous_value = wkdy_vals[h + 1]
        end
        Schedule.set_weekday_rule(wkdy_rule)
        wkdy_rule.setStartDate(date_s)
        wkdy_rule.setEndDate(date_e)
        prev_wkdy_rule = wkdy_rule

        # Weekends
        wknd_rule = OpenStudio::Model::ScheduleRule.new(schedule)
        wknd_rule.setName(sch_name + " #{Schedule.weekend_name} ruleset#{d}")
        wknd = wknd_rule.daySchedule
        wknd.setName(sch_name + " #{Schedule.weekend_name}#{d}")
        previous_value = wknd_vals[1]
        for h in 1..24
          next if (h != 24) && (wknd_vals[h + 1] == previous_value)

          wknd.addValue(time[h], previous_value)
          previous_value = wknd_vals[h + 1]
        end
        Schedule.set_weekend_rule(wknd_rule)
        wknd_rule.setStartDate(date_s)
        wknd_rule.setEndDate(date_e)
        prev_wknd_rule = wknd_rule
      end

      prev_wkdy_vals = wkdy_vals
      prev_wknd_vals = wknd_vals
    end

    Schedule.set_unavailable_periods(schedule, sch_name, unavailable_periods, year)

    Schedule.set_schedule_type_limits(model, schedule, schedule_type_limits_name)

    return schedule
  end
end

# Annual schedule defined by 24 weekday hourly values, 24 weekend hourly values, and 12 monthly values
class MonthWeekdayWeekendSchedule
  # weekday_hourly_values can either be a comma-separated string of 24 numbers or a 24-element array of numbers.
  # weekend_hourly_values can either be a comma-separated string of 24 numbers or a 24-element array of numbers.
  # monthly_values can either be a comma-separated string of 12 numbers or a 12-element array of numbers.
  def initialize(model, sch_name, weekday_hourly_values, weekend_hourly_values, monthly_values,
                 schedule_type_limits_name = nil, normalize_values = true, begin_month = 1,
                 begin_day = 1, end_month = 12, end_day = 31, unavailable_periods: nil)
    year = model.getYearDescription.assumedYear
    @weekday_hourly_values = Schedule.validate_values(weekday_hourly_values, 24, 'weekday')
    @weekend_hourly_values = Schedule.validate_values(weekend_hourly_values, 24, 'weekend')
    @monthly_values = Schedule.validate_values(monthly_values, 12, 'monthly')
    if normalize_values
      @weekday_hourly_values = normalize_sum_to_one(@weekday_hourly_values)
      @weekend_hourly_values = normalize_sum_to_one(@weekend_hourly_values)
      @monthly_values = normalize_avg_to_one(@monthly_values)
      @maxval = calc_max_val()
      @schadjust = calc_sch_adjust()
    else
      @maxval = 1.0
      @schadjust = 1.0
    end
    @schedule = create_schedule(model, sch_name, year, begin_month, begin_day, end_month, end_day,
                                schedule_type_limits_name, unavailable_periods)
  end

  def calc_design_level_from_daily_kwh(daily_kwh)
    design_level_kw = daily_kwh * @maxval * @schadjust
    return UnitConversions.convert(design_level_kw, 'kW', 'W')
  end

  def calc_design_level_from_daily_therm(daily_therm)
    return calc_design_level_from_daily_kwh(UnitConversions.convert(daily_therm, 'therm', 'kWh'))
  end

  def calc_design_level_from_daily_gpm(daily_water)
    water_gpm = daily_water * @maxval * @schadjust / 60.0
    return UnitConversions.convert(water_gpm, 'gal/min', 'm^3/s')
  end

  def schedule
    return @schedule
  end

  private

  def normalize_sum_to_one(values)
    sum = values.reduce(:+).to_f
    if sum == 0.0
      return values
    end

    return values.map { |val| val / sum }
  end

  def normalize_avg_to_one(values)
    avg = values.reduce(:+).to_f / values.size
    if avg == 0.0
      return values
    end

    return values.map { |val| val / avg }
  end

  def calc_max_val()
    if @weekday_hourly_values.max > @weekend_hourly_values.max
      maxval = @monthly_values.max * @weekday_hourly_values.max
    else
      maxval = @monthly_values.max * @weekend_hourly_values.max
    end
    if maxval == 0.0
      maxval = 1.0 # Prevent divide by zero
    end
    return maxval
  end

  def calc_sch_adjust()
    # if sum != 1, normalize to get correct max val
    sum_wkdy = 0
    sum_wknd = 0
    @weekday_hourly_values.each do |v|
      sum_wkdy += v
    end
    @weekend_hourly_values.each do |v|
      sum_wknd += v
    end
    if sum_wkdy < sum_wknd
      return 1 / sum_wknd
    end

    return 1 / sum_wkdy
  end

  def create_schedule(model, sch_name, year, begin_month, begin_day, end_month, end_day,
                      schedule_type_limits_name, unavailable_periods)
    month_num_days = Constants.NumDaysInMonths(year)
    month_num_days[end_month - 1] = end_day

    day_startm = Schedule.day_start_months(year)
    day_startm[begin_month - 1] += begin_day - 1
    day_endm = [Schedule.day_start_months(year), month_num_days].transpose.map { |i| i.reduce(:+) - 1 }

    time = []
    for h in 1..24
      time[h] = OpenStudio::Time.new(0, h, 0, 0)
    end

    schedule = OpenStudio::Model::ScheduleRuleset.new(model)
    schedule.setName(sch_name)
    schedule.defaultDaySchedule.setName(sch_name + ' default day')

    prev_wkdy_vals = nil
    prev_wkdy_rule = nil
    prev_wknd_vals = nil
    prev_wknd_rule = nil
    periods = []
    if begin_month <= end_month # contiguous period
      periods << [begin_month, end_month]
    else # non-contiguous period
      periods << [1, end_month]
      periods << [begin_month, 12]
    end

    periods.each do |period|
      for m in period[0]..period[1]
        date_s = OpenStudio::Date::fromDayOfYear(day_startm[m - 1], year)
        date_e = OpenStudio::Date::fromDayOfYear(day_endm[m - 1], year)

        wkdy_vals = []
        wknd_vals = []
        for h in 1..24
          wkdy_vals[h] = (@monthly_values[m - 1] * @weekday_hourly_values[h - 1]) / @maxval
          wknd_vals[h] = (@monthly_values[m - 1] * @weekend_hourly_values[h - 1]) / @maxval
        end

        if (wkdy_vals == prev_wkdy_vals) && (wknd_vals == prev_wknd_vals)
          # Extend end date of current rule(s)
          prev_wkdy_rule.setEndDate(date_e) unless prev_wkdy_rule.nil?
          prev_wknd_rule.setEndDate(date_e) unless prev_wknd_rule.nil?
        elsif wkdy_vals == wknd_vals
          # Alldays
          wkdy_rule = OpenStudio::Model::ScheduleRule.new(schedule)
          wkdy_rule.setName(sch_name + " #{Schedule.allday_name} ruleset#{m}")
          wkdy = wkdy_rule.daySchedule
          wkdy.setName(sch_name + " #{Schedule.allday_name}#{m}")
          previous_value = wkdy_vals[1]
          for h in 1..24
            next if (h != 24) && (wkdy_vals[h + 1] == previous_value)

            wkdy.addValue(time[h], previous_value)
            previous_value = wkdy_vals[h + 1]
          end
          Schedule.set_weekday_rule(wkdy_rule)
          Schedule.set_weekend_rule(wkdy_rule)
          wkdy_rule.setStartDate(date_s)
          wkdy_rule.setEndDate(date_e)
          prev_wkdy_rule = wkdy_rule
          prev_wknd_rule = nil
        else
          # Weekdays
          wkdy_rule = OpenStudio::Model::ScheduleRule.new(schedule)
          wkdy_rule.setName(sch_name + " #{Schedule.weekday_name} ruleset#{m}")
          wkdy = wkdy_rule.daySchedule
          wkdy.setName(sch_name + " #{Schedule.weekday_name}#{m}")
          previous_value = wkdy_vals[1]
          for h in 1..24
            next if (h != 24) && (wkdy_vals[h + 1] == previous_value)

            wkdy.addValue(time[h], previous_value)
            previous_value = wkdy_vals[h + 1]
          end
          Schedule.set_weekday_rule(wkdy_rule)
          wkdy_rule.setStartDate(date_s)
          wkdy_rule.setEndDate(date_e)
          prev_wkdy_rule = wkdy_rule

          # Weekends
          wknd_rule = OpenStudio::Model::ScheduleRule.new(schedule)
          wknd_rule.setName(sch_name + " #{Schedule.weekend_name} ruleset#{m}")
          wknd = wknd_rule.daySchedule
          wknd.setName(sch_name + " #{Schedule.weekend_name}#{m}")
          previous_value = wknd_vals[1]
          for h in 1..24
            next if (h != 24) && (wknd_vals[h + 1] == previous_value)

            wknd.addValue(time[h], previous_value)
            previous_value = wknd_vals[h + 1]
          end
          Schedule.set_weekend_rule(wknd_rule)
          wknd_rule.setStartDate(date_s)
          wknd_rule.setEndDate(date_e)
          prev_wknd_rule = wknd_rule
        end

        prev_wkdy_vals = wkdy_vals
        prev_wknd_vals = wknd_vals
      end
    end

    Schedule.set_unavailable_periods(schedule, sch_name, unavailable_periods, year)

    Schedule.set_schedule_type_limits(model, schedule, schedule_type_limits_name)

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

  # return [Double] The total number of full load hours for this schedule.
  def self.annual_equivalent_full_load_hrs(modelYear, schedule)
    if schedule.to_ScheduleInterval.is_initialized
      timeSeries = schedule.to_ScheduleInterval.get.timeSeries
      annual_flh = timeSeries.averageValue * 8760
      return annual_flh
    end

    if not schedule.to_ScheduleRuleset.is_initialized
      return
    end

    schedule = schedule.to_ScheduleRuleset.get

    # Define the start and end date
    year_start_date = OpenStudio::Date.new(OpenStudio::MonthOfYear.new('January'), 1, modelYear)
    year_end_date = OpenStudio::Date.new(OpenStudio::MonthOfYear.new('December'), 31, modelYear)

    # Get the ordered list of all the day schedules
    # that are used by this schedule ruleset
    day_schs = schedule.getDaySchedules(year_start_date, year_end_date)

    # Get a 365-value array of which schedule is used on each day of the year,
    day_schs_used_each_day = schedule.getActiveRuleIndices(year_start_date, year_end_date)
    if !day_schs_used_each_day.length == 365
      OpenStudio::logFree(OpenStudio::Error, 'openstudio.standards.ScheduleRuleset', "#{schedule.name} does not have 365 daily schedules accounted for, cannot accurately calculate annual EFLH.")
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
      OpenStudio::logFree(OpenStudio::Warn, 'openstudio.standards.ScheduleRuleset', "#{schedule.name} has more than 24 EFLH in one day schedule, indicating that it is not a fractional schedule.")
    end

    return annual_flh
  end

  def self.set_schedule_type_limits(model, schedule, schedule_type_limits_name)
    return if schedule_type_limits_name.nil?

    schedule_type_limits = model.getScheduleTypeLimitss.find { |stl| stl.name.to_s == schedule_type_limits_name }
    if schedule_type_limits.nil?
      schedule_type_limits = OpenStudio::Model::ScheduleTypeLimits.new(model)
      schedule_type_limits.setName(schedule_type_limits_name)
      if schedule_type_limits_name == Constants.ScheduleTypeLimitsFraction
        schedule_type_limits.setLowerLimitValue(0)
        schedule_type_limits.setUpperLimitValue(1)
        schedule_type_limits.setNumericType('Continuous')
      elsif schedule_type_limits_name == Constants.ScheduleTypeLimitsOnOff
        schedule_type_limits.setLowerLimitValue(0)
        schedule_type_limits.setUpperLimitValue(1)
        schedule_type_limits.setNumericType('Discrete')
      elsif schedule_type_limits_name == Constants.ScheduleTypeLimitsTemperature
        schedule_type_limits.setNumericType('Continuous')
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

  def self.get_unavailable_periods(runner, schedule_name, unavailable_periods)
    return unavailable_periods.select { |p| Schedule.unavailable_period_applies(runner, schedule_name, p.column_name) }
  end

  def self.set_unavailable_periods(schedule, sch_name, unavailable_periods, year)
    return if unavailable_periods.nil?

    # Add off rule(s), will override previous rules
    unavailable_periods.each_with_index do |period, i|
      # Special Values
      # FUTURE: Assign an object type to the schedules and use that to determine what
      # kind of schedule each is, rather than looking at object names. That would
      # be more robust. See https://github.com/NREL/OpenStudio-HPXML/issues/1450.
      if sch_name.include? Constants.ObjectNameWaterHeaterSetpoint
        # Water heater setpoint
        # Temperature of tank < 2C indicates of possibility of freeze.
        value = 2.0
      elsif sch_name.include? Constants.ObjectNameNaturalVentilation
        if period.natvent_availability == HPXML::ScheduleRegular
          next # don't change the natural ventilation availability schedule
        elsif period.natvent_availability == HPXML::ScheduleAvailable
          value = 1.0
        elsif period.natvent_availability == HPXML::ScheduleUnavailable
          value = 0.0
        end
      else
        value = 0.0
      end

      day_s = Schedule.get_day_num_from_month_day(year, period.begin_month, period.begin_day)
      day_e = Schedule.get_day_num_from_month_day(year, period.end_month, period.end_day)

      date_s = OpenStudio::Date::fromDayOfYear(day_s, year)
      date_e = OpenStudio::Date::fromDayOfYear(day_e, year)

      begin_day_schedule = schedule.getDaySchedules(date_s, date_s)[0]
      end_day_schedule = schedule.getDaySchedules(date_e, date_e)[0]

      outage_days = day_e - day_s
      if outage_days == 0 # outage is less than 1 calendar day (need 1 outage rule)
        out = Schedule.create_unavailable_period_rule(schedule, sch_name, i, date_s, date_e)
        Schedule.set_unavailable_period_values(out, begin_day_schedule, period.begin_hour, period.end_hour, value)
      else # outage is at least 1 calendar day
        if period.begin_hour == 0 && period.end_hour == 24 # 1 outage rule
          out = Schedule.create_unavailable_period_rule(schedule, sch_name, i, date_s, date_e)
          out.addValue(OpenStudio::Time.new(0, 24, 0, 0), value)
        elsif (period.begin_hour == 0 && period.end_hour != 24) || (period.begin_hour != 0 && period.end_hour == 24) # 2 outage rules
          if period.begin_hour == 0 && period.end_hour != 24
            # last day
            out = Schedule.create_unavailable_period_rule(schedule, sch_name, i, date_e, date_e)
            Schedule.set_unavailable_period_values(out, end_day_schedule, 0, period.end_hour, value)

            # all other days
            date_e2 = OpenStudio::Date::fromDayOfYear(day_e - 1, year)
            out = Schedule.create_unavailable_period_rule(schedule, sch_name, i, date_s, date_e2)
            out.addValue(OpenStudio::Time.new(0, 24, 0, 0), value)
          elsif period.begin_hour != 0 && period.end_hour == 24
            # first day
            out = Schedule.create_unavailable_period_rule(schedule, sch_name, i, date_s, date_s)
            Schedule.set_unavailable_period_values(out, begin_day_schedule, period.begin_hour, 24, value)

            # all other days
            date_s2 = OpenStudio::Date::fromDayOfYear(day_s + 1, year)
            out = Schedule.create_unavailable_period_rule(schedule, sch_name, i, date_s2, date_e)
            out.addValue(OpenStudio::Time.new(0, 24, 0, 0), value)
          end
        else # 3 outage rules
          # first day
          out = Schedule.create_unavailable_period_rule(schedule, sch_name, i, date_s, date_s)
          Schedule.set_unavailable_period_values(out, begin_day_schedule, period.begin_hour, 24, value)

          # all other days
          date_s2 = OpenStudio::Date::fromDayOfYear(day_s + 1, year)
          date_e2 = OpenStudio::Date::fromDayOfYear(day_e - 1, year)
          out = Schedule.create_unavailable_period_rule(schedule, sch_name, i, date_s2, date_e2)
          out.addValue(OpenStudio::Time.new(0, 24, 0, 0), value)

          # last day
          out = Schedule.create_unavailable_period_rule(schedule, sch_name, i, date_e, date_e)
          Schedule.set_unavailable_period_values(out, end_day_schedule, 0, period.end_hour, value)
        end
      end
    end
  end

  def self.create_unavailable_period_rule(schedule, sch_name, i, date_s, date_e)
    out_rule = OpenStudio::Model::ScheduleRule.new(schedule)
    out_rule.setName(sch_name + " unavailable period ruleset#{i}")
    out_sch = out_rule.daySchedule
    out_sch.setName(sch_name + " unavailable period#{i}")
    out_rule.setStartDate(date_s)
    out_rule.setEndDate(date_e)
    Schedule.set_weekday_rule(out_rule)
    Schedule.set_weekend_rule(out_rule)
    return out_sch
  end

  def self.set_unavailable_period_values(out, day_schedule, begin_hour, end_hour, value)
    for h in 0..23
      time = OpenStudio::Time.new(0, h + 1, 0, 0)
      if (h < begin_hour) || (h >= end_hour)
        out.addValue(time, day_schedule.getValue(time))
      else
        out.addValue(time, value)
      end
    end
  end

  def self.OccupantsWeekdayFractions
    return '0.061, 0.061, 0.061, 0.061, 0.061, 0.061, 0.061, 0.053, 0.025, 0.015, 0.015, 0.015, 0.015, 0.015, 0.015, 0.015, 0.018, 0.033, 0.054, 0.054, 0.054, 0.061, 0.061, 0.061'
  end

  def self.OccupantsWeekendFractions
    return '0.061, 0.061, 0.061, 0.061, 0.061, 0.061, 0.061, 0.053, 0.025, 0.015, 0.015, 0.015, 0.015, 0.015, 0.015, 0.015, 0.018, 0.033, 0.054, 0.054, 0.054, 0.061, 0.061, 0.061'
  end

  def self.OccupantsMonthlyMultipliers
    return '1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0'
  end

  def self.LightingExteriorWeekdayFractions
    # Schedules from T24 2016 Residential ACM Appendix C Table 8 Exterior Lighting Hourly Multiplier (Weekdays and weekends)
    return '0.046, 0.046, 0.046, 0.046, 0.046, 0.037, 0.035, 0.034, 0.033, 0.028, 0.022, 0.015, 0.012, 0.011, 0.011, 0.012, 0.019, 0.037, 0.049, 0.065, 0.091, 0.105, 0.091, 0.063'
  end

  def self.LightingExteriorWeekendFractions
    return '0.046, 0.046, 0.045, 0.045, 0.046, 0.045, 0.044, 0.041, 0.036, 0.03, 0.024, 0.016, 0.012, 0.011, 0.011, 0.012, 0.019, 0.038, 0.048, 0.06, 0.083, 0.098, 0.085, 0.059'
  end

  def self.LightingExteriorMonthlyMultipliers
    return '1.248, 1.257, 0.993, 0.989, 0.993, 0.827, 0.821, 0.821, 0.827, 0.99, 0.987, 1.248'
  end

  def self.LightingExteriorHolidayWeekdayFractions
    return '0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.008, 0.098, 0.168, 0.194, 0.284, 0.192, 0.037, 0.019'
  end

  def self.LightingExteriorHolidayWeekendFractions
    return '0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.008, 0.098, 0.168, 0.194, 0.284, 0.192, 0.037, 0.019'
  end

  def self.LightingExteriorHolidayMonthlyMultipliers
    return '1.248, 1.257, 0.993, 0.989, 0.993, 0.827, 0.821, 0.821, 0.827, 0.99, 0.987, 1.248'
  end

  def self.CookingRangeWeekdayFractions
    return '0.007, 0.007, 0.004, 0.004, 0.007, 0.011, 0.025, 0.042, 0.046, 0.048, 0.042, 0.050, 0.057, 0.046, 0.057, 0.044, 0.092, 0.150, 0.117, 0.060, 0.035, 0.025, 0.016, 0.011'
  end

  def self.CookingRangeWeekendFractions
    return '0.007, 0.007, 0.004, 0.004, 0.007, 0.011, 0.025, 0.042, 0.046, 0.048, 0.042, 0.050, 0.057, 0.046, 0.057, 0.044, 0.092, 0.150, 0.117, 0.060, 0.035, 0.025, 0.016, 0.011'
  end

  def self.CookingRangeMonthlyMultipliers
    return '1.097, 1.097, 0.991, 0.987, 0.991, 0.890, 0.896, 0.896, 0.890, 1.085, 1.085, 1.097'
  end

  def self.DishwasherWeekdayFractions
    return '0.015, 0.007, 0.005, 0.003, 0.003, 0.010, 0.020, 0.031, 0.058, 0.065, 0.056, 0.048, 0.041, 0.046, 0.036, 0.038, 0.038, 0.049, 0.087, 0.111, 0.090, 0.067, 0.044, 0.031'
  end

  def self.DishwasherWeekendFractions
    return '0.015, 0.007, 0.005, 0.003, 0.003, 0.010, 0.020, 0.031, 0.058, 0.065, 0.056, 0.048, 0.041, 0.046, 0.036, 0.038, 0.038, 0.049, 0.087, 0.111, 0.090, 0.067, 0.044, 0.031'
  end

  def self.DishwasherMonthlyMultipliers
    return '1.097, 1.097, 0.991, 0.987, 0.991, 0.890, 0.896, 0.896, 0.890, 1.085, 1.085, 1.097'
  end

  def self.ClothesWasherWeekdayFractions
    return '0.009, 0.007, 0.004, 0.004, 0.007, 0.011, 0.022, 0.049, 0.073, 0.086, 0.084, 0.075, 0.067, 0.060, 0.049, 0.052, 0.050, 0.049, 0.049, 0.049, 0.049, 0.047, 0.032, 0.017'
  end

  def self.ClothesWasherWeekendFractions
    return '0.009, 0.007, 0.004, 0.004, 0.007, 0.011, 0.022, 0.049, 0.073, 0.086, 0.084, 0.075, 0.067, 0.060, 0.049, 0.052, 0.050, 0.049, 0.049, 0.049, 0.049, 0.047, 0.032, 0.017'
  end

  def self.ClothesWasherMonthlyMultipliers
    return '1.011, 1.002, 1.022, 1.020, 1.022, 0.996, 0.999, 0.999, 0.996, 0.964, 0.959, 1.011'
  end

  def self.ClothesDryerWeekdayFractions
    return '0.010, 0.006, 0.004, 0.002, 0.004, 0.006, 0.016, 0.032, 0.048, 0.068, 0.078, 0.081, 0.074, 0.067, 0.057, 0.061, 0.055, 0.054, 0.051, 0.051, 0.052, 0.054, 0.044, 0.024'
  end

  def self.ClothesDryerWeekendFractions
    return '0.010, 0.006, 0.004, 0.002, 0.004, 0.006, 0.016, 0.032, 0.048, 0.068, 0.078, 0.081, 0.074, 0.067, 0.057, 0.061, 0.055, 0.054, 0.051, 0.051, 0.052, 0.054, 0.044, 0.024'
  end

  def self.ClothesDryerMonthlyMultipliers
    return '1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0'
  end

  def self.FixturesWeekdayFractions
    return '0.012, 0.006, 0.004, 0.005, 0.010, 0.034, 0.078, 0.087, 0.080, 0.067, 0.056, 0.047, 0.040, 0.035, 0.033, 0.031, 0.039, 0.051, 0.060, 0.060, 0.055, 0.048, 0.038, 0.026'
  end

  def self.FixturesWeekendFractions
    return '0.012, 0.006, 0.004, 0.005, 0.010, 0.034, 0.078, 0.087, 0.080, 0.067, 0.056, 0.047, 0.040, 0.035, 0.033, 0.031, 0.039, 0.051, 0.060, 0.060, 0.055, 0.048, 0.038, 0.026'
  end

  def self.FixturesMonthlyMultipliers
    return '1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0'
  end

  def self.RefrigeratorWeekdayFractions
    return '0.040, 0.039, 0.038, 0.037, 0.036, 0.036, 0.038, 0.040, 0.041, 0.041, 0.040, 0.040, 0.042, 0.042, 0.042, 0.041, 0.044, 0.048, 0.050, 0.048, 0.047, 0.046, 0.044, 0.041'
  end

  def self.RefrigeratorWeekendFractions
    return '0.040, 0.039, 0.038, 0.037, 0.036, 0.036, 0.038, 0.040, 0.041, 0.041, 0.040, 0.040, 0.042, 0.042, 0.042, 0.041, 0.044, 0.048, 0.050, 0.048, 0.047, 0.046, 0.044, 0.041'
  end

  def self.RefrigeratorMonthlyMultipliers
    return '0.837, 0.835, 1.084, 1.084, 1.084, 1.096, 1.096, 1.096, 1.096, 0.931, 0.925, 0.837'
  end

  def self.ExtraRefrigeratorWeekdayFractions
    return '0.040, 0.039, 0.038, 0.037, 0.036, 0.036, 0.038, 0.040, 0.041, 0.041, 0.040, 0.040, 0.042, 0.042, 0.042, 0.041, 0.044, 0.048, 0.050, 0.048, 0.047, 0.046, 0.044, 0.041'
  end

  def self.ExtraRefrigeratorWeekendFractions
    return '0.040, 0.039, 0.038, 0.037, 0.036, 0.036, 0.038, 0.040, 0.041, 0.041, 0.040, 0.040, 0.042, 0.042, 0.042, 0.041, 0.044, 0.048, 0.050, 0.048, 0.047, 0.046, 0.044, 0.041'
  end

  def self.ExtraRefrigeratorMonthlyMultipliers
    return '0.837, 0.835, 1.084, 1.084, 1.084, 1.096, 1.096, 1.096, 1.096, 0.931, 0.925, 0.837'
  end

  def self.FreezerWeekdayFractions
    return '0.040, 0.039, 0.038, 0.037, 0.036, 0.036, 0.038, 0.040, 0.041, 0.041, 0.040, 0.040, 0.042, 0.042, 0.042, 0.041, 0.044, 0.048, 0.050, 0.048, 0.047, 0.046, 0.044, 0.041'
  end

  def self.FreezerWeekendFractions
    return '0.040, 0.039, 0.038, 0.037, 0.036, 0.036, 0.038, 0.040, 0.041, 0.041, 0.040, 0.040, 0.042, 0.042, 0.042, 0.041, 0.044, 0.048, 0.050, 0.048, 0.047, 0.046, 0.044, 0.041'
  end

  def self.FreezerMonthlyMultipliers
    return '0.837, 0.835, 1.084, 1.084, 1.084, 1.096, 1.096, 1.096, 1.096, 0.931, 0.925, 0.837'
  end

  def self.CeilingFanWeekdayFractions
    return '0.057, 0.057, 0.057, 0.057, 0.057, 0.057, 0.057, 0.024, 0.024, 0.024, 0.024, 0.024, 0.024, 0.024, 0.024, 0.024, 0.024, 0.024, 0.057, 0.057, 0.057, 0.057, 0.057, 0.057'
  end

  def self.CeilingFanWeekendFractions
    return '0.057, 0.057, 0.057, 0.057, 0.057, 0.057, 0.057, 0.024, 0.024, 0.024, 0.024, 0.024, 0.024, 0.024, 0.024, 0.024, 0.024, 0.024, 0.057, 0.057, 0.057, 0.057, 0.057, 0.057'
  end

  def self.CeilingFanMonthlyMultipliers(weather:)
    return HVAC.get_default_ceiling_fan_months(weather).join(', ')
  end

  def self.PlugLoadsOtherWeekdayFractions
    return '0.035, 0.033, 0.032, 0.031, 0.032, 0.033, 0.037, 0.042, 0.043, 0.043, 0.043, 0.044, 0.045, 0.045, 0.044, 0.046, 0.048, 0.052, 0.053, 0.05, 0.047, 0.045, 0.04, 0.036'
  end

  def self.PlugLoadsOtherWeekendFractions
    return '0.035, 0.033, 0.032, 0.031, 0.032, 0.033, 0.037, 0.042, 0.043, 0.043, 0.043, 0.044, 0.045, 0.045, 0.044, 0.046, 0.048, 0.052, 0.053, 0.05, 0.047, 0.045, 0.04, 0.036'
  end

  def self.PlugLoadsOtherMonthlyMultipliers
    return '1.248, 1.257, 0.993, 0.989, 0.993, 0.827, 0.821, 0.821, 0.827, 0.99, 0.987, 1.248'
  end

  def self.PlugLoadsTVWeekdayFractions
    return '0.037, 0.018, 0.009, 0.007, 0.011, 0.018, 0.029, 0.040, 0.049, 0.058, 0.065, 0.072, 0.076, 0.086, 0.091, 0.102, 0.127, 0.156, 0.210, 0.294, 0.363, 0.344, 0.208, 0.090'
  end

  def self.PlugLoadsTVWeekendFractions
    return '0.044, 0.022, 0.012, 0.008, 0.011, 0.014, 0.024, 0.043, 0.071, 0.094, 0.112, 0.123, 0.132, 0.156, 0.178, 0.196, 0.206, 0.213, 0.251, 0.330, 0.388, 0.358, 0.226, 0.103'
  end

  def self.PlugLoadsTVMonthlyMultipliers
    return '1.137, 1.129, 0.961, 0.969, 0.961, 0.993, 0.996, 0.96, 0.993, 0.867, 0.86, 1.137'
  end

  def self.PlugLoadsVehicleWeekdayFractions
    return '0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042'
  end

  def self.PlugLoadsVehicleWeekendFractions
    return '0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042'
  end

  def self.PlugLoadsVehicleMonthlyMultipliers
    return '1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0'
  end

  def self.PlugLoadsWellPumpWeekdayFractions
    return '0.044, 0.023, 0.019, 0.015, 0.016, 0.018, 0.026, 0.033, 0.033, 0.032, 0.033, 0.033, 0.032, 0.032, 0.032, 0.033, 0.045, 0.057, 0.066, 0.076, 0.081, 0.086, 0.075, 0.065'
  end

  def self.PlugLoadsWellPumpWeekendFractions
    return '0.044, 0.023, 0.019, 0.015, 0.016, 0.018, 0.026, 0.033, 0.033, 0.032, 0.033, 0.033, 0.032, 0.032, 0.032, 0.033, 0.045, 0.057, 0.066, 0.076, 0.081, 0.086, 0.075, 0.065'
  end

  def self.PlugLoadsWellPumpMonthlyMultipliers
    return '1.154, 1.161, 1.013, 1.010, 1.013, 0.888, 0.883, 0.883, 0.888, 0.978, 0.974, 1.154'
  end

  def self.FuelLoadsGrillWeekdayFractions
    return '0.004, 0.001, 0.001, 0.002, 0.007, 0.012, 0.029, 0.046, 0.044, 0.041, 0.044, 0.046, 0.042, 0.038, 0.049, 0.059, 0.110, 0.161, 0.115, 0.070, 0.044, 0.019, 0.013, 0.007'
  end

  def self.FuelLoadsGrillWeekendFractions
    return '0.004, 0.001, 0.001, 0.002, 0.007, 0.012, 0.029, 0.046, 0.044, 0.041, 0.044, 0.046, 0.042, 0.038, 0.049, 0.059, 0.110, 0.161, 0.115, 0.070, 0.044, 0.019, 0.013, 0.007'
  end

  def self.FuelLoadsGrillMonthlyMultipliers
    return '1.097, 1.097, 0.991, 0.987, 0.991, 0.890, 0.896, 0.896, 0.890, 1.085, 1.085, 1.097'
  end

  def self.FuelLoadsLightingWeekdayFractions
    return '0.044, 0.023, 0.019, 0.015, 0.016, 0.018, 0.026, 0.033, 0.033, 0.032, 0.033, 0.033, 0.032, 0.032, 0.032, 0.033, 0.045, 0.057, 0.066, 0.076, 0.081, 0.086, 0.075, 0.065'
  end

  def self.FuelLoadsLightingWeekendFractions
    return '0.044, 0.023, 0.019, 0.015, 0.016, 0.018, 0.026, 0.033, 0.033, 0.032, 0.033, 0.033, 0.032, 0.032, 0.032, 0.033, 0.045, 0.057, 0.066, 0.076, 0.081, 0.086, 0.075, 0.065'
  end

  def self.FuelLoadsLightingMonthlyMultipliers
    return '1.154, 1.161, 1.013, 1.010, 1.013, 0.888, 0.883, 0.883, 0.888, 0.978, 0.974, 1.154'
  end

  def self.FuelLoadsFireplaceWeekdayFractions
    return '0.044, 0.023, 0.019, 0.015, 0.016, 0.018, 0.026, 0.033, 0.033, 0.032, 0.033, 0.033, 0.032, 0.032, 0.032, 0.033, 0.045, 0.057, 0.066, 0.076, 0.081, 0.086, 0.075, 0.065'
  end

  def self.FuelLoadsFireplaceWeekendFractions
    return '0.044, 0.023, 0.019, 0.015, 0.016, 0.018, 0.026, 0.033, 0.033, 0.032, 0.033, 0.033, 0.032, 0.032, 0.032, 0.033, 0.045, 0.057, 0.066, 0.076, 0.081, 0.086, 0.075, 0.065'
  end

  def self.FuelLoadsFireplaceMonthlyMultipliers
    return '1.154, 1.161, 1.013, 1.010, 1.013, 0.888, 0.883, 0.883, 0.888, 0.978, 0.974, 1.154'
  end

  def self.PoolPumpWeekdayFractions
    return '0.003, 0.003, 0.003, 0.004, 0.008, 0.015, 0.026, 0.044, 0.084, 0.121, 0.127, 0.121, 0.120, 0.090, 0.075, 0.061, 0.037, 0.023, 0.013, 0.008, 0.004, 0.003, 0.003, 0.003'
  end

  def self.PoolPumpWeekendFractions
    return '0.003, 0.003, 0.003, 0.004, 0.008, 0.015, 0.026, 0.044, 0.084, 0.121, 0.127, 0.121, 0.120, 0.090, 0.075, 0.061, 0.037, 0.023, 0.013, 0.008, 0.004, 0.003, 0.003, 0.003'
  end

  def self.PoolPumpMonthlyMultipliers
    return '1.154, 1.161, 1.013, 1.010, 1.013, 0.888, 0.883, 0.883, 0.888, 0.978, 0.974, 1.154'
  end

  def self.PoolHeaterWeekdayFractions
    return '0.003, 0.003, 0.003, 0.004, 0.008, 0.015, 0.026, 0.044, 0.084, 0.121, 0.127, 0.121, 0.120, 0.090, 0.075, 0.061, 0.037, 0.023, 0.013, 0.008, 0.004, 0.003, 0.003, 0.003'
  end

  def self.PoolHeaterWeekendFractions
    return '0.003, 0.003, 0.003, 0.004, 0.008, 0.015, 0.026, 0.044, 0.084, 0.121, 0.127, 0.121, 0.120, 0.090, 0.075, 0.061, 0.037, 0.023, 0.013, 0.008, 0.004, 0.003, 0.003, 0.003'
  end

  def self.PoolHeaterMonthlyMultipliers
    return '1.154, 1.161, 1.013, 1.010, 1.013, 0.888, 0.883, 0.883, 0.888, 0.978, 0.974, 1.154'
  end

  def self.PermanentSpaPumpWeekdayFractions
    return '0.024, 0.029, 0.024, 0.029, 0.047, 0.067, 0.057, 0.024, 0.024, 0.019, 0.015, 0.014, 0.014, 0.014, 0.024, 0.058, 0.126, 0.122, 0.068, 0.061, 0.051, 0.043, 0.024, 0.024'
  end

  def self.PermanentSpaPumpWeekendFractions
    return '0.024, 0.029, 0.024, 0.029, 0.047, 0.067, 0.057, 0.024, 0.024, 0.019, 0.015, 0.014, 0.014, 0.014, 0.024, 0.058, 0.126, 0.122, 0.068, 0.061, 0.051, 0.043, 0.024, 0.024'
  end

  def self.PermanentSpaPumpMonthlyMultipliers
    return '0.921, 0.928, 0.921, 0.915, 0.921, 1.160, 1.158, 1.158, 1.160, 0.921, 0.915, 0.921'
  end

  def self.PermanentSpaHeaterWeekdayFractions
    return '0.024, 0.029, 0.024, 0.029, 0.047, 0.067, 0.057, 0.024, 0.024, 0.019, 0.015, 0.014, 0.014, 0.014, 0.024, 0.058, 0.126, 0.122, 0.068, 0.061, 0.051, 0.043, 0.024, 0.024'
  end

  def self.PermanentSpaHeaterWeekendFractions
    return '0.024, 0.029, 0.024, 0.029, 0.047, 0.067, 0.057, 0.024, 0.024, 0.019, 0.015, 0.014, 0.014, 0.014, 0.024, 0.058, 0.126, 0.122, 0.068, 0.061, 0.051, 0.043, 0.024, 0.024'
  end

  def self.PermanentSpaHeaterMonthlyMultipliers
    return '0.837, 0.835, 1.084, 1.084, 1.084, 1.096, 1.096, 1.096, 1.096, 0.931, 0.925, 0.837'
  end

  def self.get_day_num_from_month_day(year, month, day)
    # Returns a value between 1 and 365 (or 366 for a leap year)
    # Returns e.g. 32 for month=2 and day=1 (Feb 1)
    month_num_days = Constants.NumDaysInMonths(year)
    day_num = day
    for m in 0..month - 2
      day_num += month_num_days[m]
    end
    return day_num
  end

  def self.get_daily_season(year, start_month, start_day, end_month, end_day)
    start_day_num = get_day_num_from_month_day(year, start_month, start_day)
    end_day_num = get_day_num_from_month_day(year, end_month, end_day)

    season = Array.new(Constants.NumDaysInYear(year), 0)
    if end_day_num >= start_day_num
      season.fill(1, start_day_num - 1, end_day_num - start_day_num + 1) # Fill between start/end days
    else # Wrap around year
      season.fill(1, start_day_num - 1) # Fill between start day and end of year
      season.fill(1, 0, end_day_num) # Fill between start of year and end day
    end
    return season
  end

  def self.months_to_days(year, months)
    month_num_days = Constants.NumDaysInMonths(year)
    days = []
    for m in 0..11
      days.concat([months[m]] * month_num_days[m])
    end
    return days
  end

  def self.day_start_months(year)
    month_num_days = Constants.NumDaysInMonths(year)
    return month_num_days.each_with_index.map { |_n, i| get_day_num_from_month_day(year, i + 1, 1) }
  end

  def self.day_end_months(year)
    month_num_days = Constants.NumDaysInMonths(year)
    return month_num_days.each_with_index.map { |n, i| get_day_num_from_month_day(year, i + 1, n) }
  end

  def self.create_ruleset_from_daily_season(model, values)
    s = OpenStudio::Model::ScheduleRuleset.new(model)
    year = model.getYearDescription.assumedYear
    start_value = values[0]
    start_date = OpenStudio::Date::fromDayOfYear(1, year)
    values.each_with_index do |value, i|
      i += 1
      next unless value != start_value || i == values.length

      rule = OpenStudio::Model::ScheduleRule.new(s)
      set_weekday_rule(rule)
      set_weekend_rule(rule)
      i += 1 if i == values.length
      end_date = OpenStudio::Date::fromDayOfYear(i - 1, year)
      rule.setStartDate(start_date)
      rule.setEndDate(end_date)
      day_schedule = rule.daySchedule
      day_schedule.addValue(OpenStudio::Time.new(0, 24, 0, 0), start_value)
      break if i == values.length + 1

      start_date = OpenStudio::Date::fromDayOfYear(i, year)
      start_value = value
    end
    return s
  end

  def self.parse_date_time_range(date_time_range)
    begin_end_dates = date_time_range.split('-').map { |v| v.strip }
    if begin_end_dates.size != 2
      fail "Invalid date format specified for '#{date_time_range}'."
    end

    begin_values = begin_end_dates[0].split(' ').map { |v| v.strip }
    end_values = begin_end_dates[1].split(' ').map { |v| v.strip }

    if !(begin_values.size == 2 || begin_values.size == 3) || !(end_values.size == 2 || end_values.size == 3)
      fail "Invalid date format specified for '#{date_time_range}'."
    end

    require 'date'
    begin_month = Date::ABBR_MONTHNAMES.index(begin_values[0].capitalize)
    end_month = Date::ABBR_MONTHNAMES.index(end_values[0].capitalize)
    begin_day = begin_values[1].to_i
    end_day = end_values[1].to_i
    if begin_values.size == 3
      begin_hour = begin_values[2].to_i
    end
    if end_values.size == 3
      end_hour = end_values[2].to_i
    end
    if begin_month.nil? || end_month.nil? || begin_day == 0 || end_day == 0
      fail "Invalid date format specified for '#{date_time_range}'."
    end

    return begin_month, begin_day, begin_hour, end_month, end_day, end_hour
  end

  def self.get_begin_and_end_dates_from_monthly_array(months, year)
    num_days_in_month = Constants.NumDaysInMonths(year)

    if months.uniq.size == 1 && months[0] == 1 # Year-round
      return 1, 1, 12, num_days_in_month[11]
    elsif months.uniq.size == 1 && months[0] == 0 # Never
      return
    elsif months[0] == 1 && months[11] == 1 # Wrap around year
      begin_month = 12 - months.reverse.index(0) + 1
      end_month = months.index(0)
    else
      begin_month = months.index(1) + 1
      end_month = 12 - months.reverse.index(1)
    end

    begin_day = 1
    end_day = num_days_in_month[end_month - 1]

    return begin_month, begin_day, end_month, end_day
  end

  def self.get_unavailable_periods_csv_data
    unavailable_periods_csv = File.join(File.dirname(__FILE__), 'data', 'unavailable_periods.csv')
    if not File.exist?(unavailable_periods_csv)
      fail 'Could not find unavailable_periods.csv'
    end

    require 'csv'
    unavailable_periods_csv_data = CSV.open(unavailable_periods_csv, headers: :first_row).map(&:to_h)

    return unavailable_periods_csv_data
  end

  def self.unavailable_period_applies(runner, schedule_name, col_name)
    if @unavailable_periods_csv_data.nil?
      @unavailable_periods_csv_data = get_unavailable_periods_csv_data

    end
    @unavailable_periods_csv_data.each do |csv_row|
      next if csv_row['Schedule Name'] != schedule_name

      if not csv_row.keys.include? col_name
        fail "Could not find column='#{col_name}' in unavailable_periods.csv."
      end

      begin
        applies = Integer(csv_row[col_name])
      rescue
        fail "Value is not a valid integer for row='#{schedule_name}' and column='#{col_name}' in unavailable_periods.csv."
      end
      if applies == 1
        if not runner.nil?
          if schedule_name == SchedulesFile::ColumnHVAC
            runner.registerWarning('It is not possible to eliminate all HVAC energy use (e.g. crankcase/defrost energy) in EnergyPlus during an unavailable period.')
          elsif schedule_name == SchedulesFile::ColumnWaterHeater
            runner.registerWarning('It is not possible to eliminate all water heater energy use (e.g. parasitics) in EnergyPlus during an unavailable period.')
          end
        end
        return true
      elsif applies == 0
        return false
      end
    end

    fail "Could not find row='#{schedule_name}' in unavailable_periods.csv"
  end

  def self.validate_values(values, num_values, sch_name)
    err_msg = "A comma-separated string of #{num_values} numbers must be entered for the #{sch_name} schedule."
    if values.is_a?(Array)
      if values.length != num_values
        fail err_msg
      end

      values.each do |val|
        if not valid_float?(val)
          fail err_msg
        end
      end
      floats = values.map { |i| i.to_f }
    elsif values.is_a?(String)
      begin
        vals = values.split(',')
        vals.each do |val|
          if not valid_float?(val)
            fail err_msg
          end
        end
        floats = vals.map { |i| i.to_f }
        if floats.length != num_values
          fail err_msg
        end
      rescue
        fail err_msg
      end
    else
      fail err_msg
    end
    return floats
  end

  def self.valid_float?(str)
    !!Float(str) rescue false
  end
end

class SchedulesFile
  # Constants
  ColumnOccupants = 'occupants'
  ColumnLightingInterior = 'lighting_interior'
  ColumnLightingExterior = 'lighting_exterior'
  ColumnLightingGarage = 'lighting_garage'
  ColumnLightingExteriorHoliday = 'lighting_exterior_holiday'
  ColumnCookingRange = 'cooking_range'
  ColumnRefrigerator = 'refrigerator'
  ColumnExtraRefrigerator = 'extra_refrigerator'
  ColumnFreezer = 'freezer'
  ColumnDishwasher = 'dishwasher'
  ColumnClothesWasher = 'clothes_washer'
  ColumnClothesDryer = 'clothes_dryer'
  ColumnCeilingFan = 'ceiling_fan'
  ColumnPlugLoadsOther = 'plug_loads_other'
  ColumnPlugLoadsTV = 'plug_loads_tv'
  ColumnPlugLoadsVehicle = 'plug_loads_vehicle'
  ColumnPlugLoadsWellPump = 'plug_loads_well_pump'
  ColumnFuelLoadsGrill = 'fuel_loads_grill'
  ColumnFuelLoadsLighting = 'fuel_loads_lighting'
  ColumnFuelLoadsFireplace = 'fuel_loads_fireplace'
  ColumnPoolPump = 'pool_pump'
  ColumnPoolHeater = 'pool_heater'
  ColumnPermanentSpaPump = 'permanent_spa_pump'
  ColumnPermanentSpaHeater = 'permanent_spa_heater'
  ColumnHotWaterDishwasher = 'hot_water_dishwasher'
  ColumnHotWaterClothesWasher = 'hot_water_clothes_washer'
  ColumnHotWaterFixtures = 'hot_water_fixtures'
  ColumnSleeping = 'sleeping'
  ColumnHeatingSetpoint = 'heating_setpoint'
  ColumnCoolingSetpoint = 'cooling_setpoint'
  ColumnWaterHeaterSetpoint = 'water_heater_setpoint'
  ColumnWaterHeaterOperatingMode = 'water_heater_operating_mode'
  ColumnBattery = 'battery'
  ColumnBatteryCharging = 'battery_charging'
  ColumnBatteryDischarging = 'battery_discharging'
  ColumnHVAC = 'hvac'
  ColumnWaterHeater = 'water_heater'
  ColumnDehumidifier = 'dehumidifier'
  ColumnKitchenFan = 'kitchen_fan'
  ColumnBathFan = 'bath_fan'
  ColumnHouseFan = 'house_fan'
  ColumnWholeHouseFan = 'whole_house_fan'

  def initialize(runner: nil,
                 schedules_paths:,
                 year:,
                 unavailable_periods: [],
                 output_path:)
    return if schedules_paths.empty?

    @year = year
    import(schedules_paths)
    battery_schedules
    expand_schedules
    @tmp_schedules = Marshal.load(Marshal.dump(@schedules))
    set_unavailable_periods(runner, unavailable_periods)
    convert_setpoints
    @output_schedules_path = output_path
    export()
  end

  def nil?
    if @schedules.nil?
      return true
    end

    return false
  end

  def includes_col_name(col_name)
    if @schedules.keys.include?(col_name)
      return true
    end

    return false
  end

  def import(schedules_paths)
    num_hrs_in_year = Constants.NumHoursInYear(@year)
    @schedules = {}
    schedules_paths.each do |schedules_path|
      columns = CSV.read(schedules_path).transpose
      columns.each do |col|
        col_name = col[0]

        values = col[1..-1].reject { |v| v.nil? }

        begin
          values = values.map { |v| Float(v) }
        rescue ArgumentError
          fail "Schedule value must be numeric for column '#{col_name}'. [context: #{schedules_path}]"
        end

        if @schedules.keys.include? col_name
          fail "Schedule column name '#{col_name}' is duplicated. [context: #{schedules_path}]"
        end

        if max_value_one[col_name]
          if values.max > 1
            fail "Schedule max value for column '#{col_name}' must be 1. [context: #{schedules_path}]"
          end
        end

        if min_value_zero[col_name]
          if values.min < 0
            fail "Schedule min value for column '#{col_name}' must be non-negative. [context: #{schedules_path}]"
          end
        end

        if min_value_neg_one[col_name]
          if values.min < -1
            fail "Schedule min value for column '#{col_name}' must be -1. [context: #{schedules_path}]"
          end
        end

        if only_zeros_and_ones[col_name]
          if values.any? { |v| v != 0 && v != 1 }
            fail "Schedule value for column '#{col_name}' must be either 0 or 1. [context: #{schedules_path}]"
          end
        end

        valid_minutes_per_item = [1, 2, 3, 4, 5, 6, 10, 12, 15, 20, 30, 60]
        valid_num_rows = valid_minutes_per_item.map { |min_per_item| (60.0 * num_hrs_in_year / min_per_item).to_i }
        unless valid_num_rows.include? values.length
          fail "Schedule has invalid number of rows (#{values.length}) for column '#{col_name}'. Must be one of: #{valid_num_rows.reverse.join(', ')}. [context: #{@schedules_path}]"
        end

        @schedules[col_name] = values
      end
    end
  end

  def export()
    return false if @output_schedules_path.nil?

    CSV.open(@output_schedules_path, 'wb') do |csv|
      csv << @tmp_schedules.keys
      rows = @tmp_schedules.values.transpose
      rows.each do |row|
        csv << row
      end
    end

    return true
  end

  def schedules
    return @schedules
  end

  def tmp_schedules
    return @tmp_schedules
  end

  def get_col_index(col_name:)
    headers = @tmp_schedules.keys

    col_num = headers.index(col_name)
    return col_num
  end

  def create_schedule_file(model, col_name:, rows_to_skip: 1,
                           schedule_type_limits_name: nil)
    model.getScheduleFiles.each do |schedule_file|
      next if schedule_file.name.to_s != col_name

      return schedule_file
    end

    if @schedules[col_name].nil?
      return
    end

    col_index = get_col_index(col_name: col_name)
    num_hrs_in_year = Constants.NumHoursInYear(@year)
    schedule_length = @schedules[col_name].length
    min_per_item = 60.0 / (schedule_length / num_hrs_in_year)

    file_path = File.dirname(@output_schedules_path)
    workflow_json = model.workflowJSON
    file_paths = workflow_json.filePaths.map(&:to_s)
    workflow_json.addFilePath(file_path) unless file_paths.include?(file_path)

    schedule_file = OpenStudio::Model::ScheduleFile.new(model, File.basename(@output_schedules_path))
    schedule_file.setName(col_name)
    schedule_file.setColumnNumber(col_index + 1)
    schedule_file.setRowstoSkipatTop(rows_to_skip)
    schedule_file.setNumberofHoursofData(num_hrs_in_year.to_i)
    schedule_file.setMinutesperItem(min_per_item.to_i)
    schedule_file.setTranslateFileWithRelativePath(true)

    Schedule.set_schedule_type_limits(model, schedule_file, schedule_type_limits_name)

    return schedule_file
  end

  # the equivalent number of hours in the year, if the schedule was at full load (1.0)
  def annual_equivalent_full_load_hrs(col_name:,
                                      schedules: nil)
    if schedules.nil?
      schedules = @schedules # the schedules before vacancy is applied
    end

    if schedules[col_name].nil?
      return
    end

    num_hrs_in_year = Constants.NumHoursInYear(@year)
    schedule_length = schedules[col_name].length
    min_per_item = 60.0 / (schedule_length / num_hrs_in_year)
    ann_equiv_full_load_hrs = schedules[col_name].reduce(:+) / (60.0 / min_per_item)

    return ann_equiv_full_load_hrs
  end

  # the power in watts the equipment needs to consume so that, if it were to run annual_equivalent_full_load_hrs hours,
  # it would consume the annual_kwh energy in the year. Essentially, returns the watts for the equipment when schedule
  # is at 1.0, so that, for the given schedule values, the equipment will consume annual_kwh energy in a year.
  def calc_design_level_from_annual_kwh(col_name:,
                                        annual_kwh:)
    if @schedules[col_name].nil?
      return
    end

    ann_equiv_full_load_hrs = annual_equivalent_full_load_hrs(col_name: col_name)
    return 0 if ann_equiv_full_load_hrs == 0

    design_level = annual_kwh * 1000.0 / ann_equiv_full_load_hrs # W

    return design_level
  end

  # Similar to ann_equiv_full_load_hrs, but for thermal energy
  def calc_design_level_from_annual_therm(col_name:,
                                          annual_therm:)
    if @schedules[col_name].nil?
      return
    end

    annual_kwh = UnitConversions.convert(annual_therm, 'therm', 'kWh')
    design_level = calc_design_level_from_annual_kwh(col_name: col_name, annual_kwh: annual_kwh)

    return design_level
  end

  # similar to the calc_design_level_from_annual_kwh, but use daily_kwh instead of annual_kwh to calculate the design
  # level
  def calc_design_level_from_daily_kwh(col_name:,
                                       daily_kwh:)
    if @schedules[col_name].nil?
      return
    end

    full_load_hrs = annual_equivalent_full_load_hrs(col_name: col_name)
    return 0 if full_load_hrs == 0

    num_days_in_year = Constants.NumDaysInYear(@year)
    daily_full_load_hrs = full_load_hrs / num_days_in_year
    design_level = UnitConversions.convert(daily_kwh / daily_full_load_hrs, 'kW', 'W')

    return design_level
  end

  # similar to calc_design_level_from_daily_kwh but for water usage
  def calc_peak_flow_from_daily_gpm(col_name:,
                                    daily_water:)
    if @schedules[col_name].nil?
      return
    end

    ann_equiv_full_load_hrs = annual_equivalent_full_load_hrs(col_name: col_name)
    return 0 if ann_equiv_full_load_hrs == 0

    num_days_in_year = Constants.NumDaysInYear(@year)
    daily_full_load_hrs = ann_equiv_full_load_hrs / num_days_in_year
    peak_flow = daily_water / daily_full_load_hrs # gallons_per_hour
    peak_flow /= 60 # convert to gallons per minute
    peak_flow = UnitConversions.convert(peak_flow, 'gal/min', 'm^3/s') # convert to m^3/s
    return peak_flow
  end

  def create_column_values_from_periods(col_name, periods)
    # Create a column of zeroes or ones for, e.g., vacancy periods or power outage periods
    n_steps = @tmp_schedules[@tmp_schedules.keys[0]].length
    num_days_in_year = Constants.NumDaysInYear(@year)
    steps_in_day = n_steps / num_days_in_year
    steps_in_hour = steps_in_day / 24

    if @tmp_schedules[col_name].nil?
      @tmp_schedules[col_name] = Array.new(n_steps, 0)
    end

    periods.each do |period|
      begin_day_num = Schedule.get_day_num_from_month_day(@year, period.begin_month, period.begin_day)
      end_day_num = Schedule.get_day_num_from_month_day(@year, period.end_month, period.end_day)

      begin_hour = 0
      end_hour = 24

      begin_hour = period.begin_hour if not period.begin_hour.nil?
      end_hour = period.end_hour if not period.end_hour.nil?

      if end_day_num >= begin_day_num
        @tmp_schedules[col_name].fill(1.0, (begin_day_num - 1) * steps_in_day + (begin_hour * steps_in_hour), (end_day_num - begin_day_num + 1) * steps_in_day - ((24 - end_hour + begin_hour) * steps_in_hour)) # Fill between begin/end days
      else # Wrap around year
        @tmp_schedules[col_name].fill(1.0, (begin_day_num - 1) * steps_in_day + (begin_hour * steps_in_hour)) # Fill between begin day and end of year
        @tmp_schedules[col_name].fill(1.0, 0, (end_day_num - 1) * steps_in_day + (end_hour * steps_in_hour)) # Fill between begin of year and end day
      end
    end
  end

  def expand_schedules
    # Expand schedules with fewer elements such that all the schedules have the same number of elements
    max_size = @schedules.map { |_k, v| v.size }.uniq.max
    @schedules.each do |col, values|
      if values.size < max_size
        @schedules[col] = values.map { |v| [v] * (max_size / values.size) }.flatten
      end
    end
  end

  def set_unavailable_periods(runner, unavailable_periods)
    if @unavailable_periods_csv_data.nil?
      @unavailable_periods_csv_data = Schedule.get_unavailable_periods_csv_data
    end
    column_names = @unavailable_periods_csv_data[0].keys[1..-1]
    column_names.each do |column_name|
      create_column_values_from_periods(column_name, unavailable_periods.select { |p| p.column_name == column_name })
      next if @tmp_schedules[column_name].all? { |i| i == 0 }

      @tmp_schedules.keys.each do |schedule_name|
        next if column_names.include? schedule_name
        next if SchedulesFile.OperatingModeColumnNames.include?(schedule_name)
        next if SchedulesFile.BatteryColumnNames.include?(schedule_name)

        schedule_name2 = schedule_name
        if [SchedulesFile::ColumnHotWaterDishwasher].include?(schedule_name)
          schedule_name2 = SchedulesFile::ColumnDishwasher
        elsif [SchedulesFile::ColumnHotWaterClothesWasher].include?(schedule_name)
          schedule_name2 = SchedulesFile::ColumnClothesWasher
        elsif [SchedulesFile::ColumnHeatingSetpoint, SchedulesFile::ColumnCoolingSetpoint].include?(schedule_name)
          schedule_name2 = SchedulesFile::ColumnHVAC
        elsif [SchedulesFile::ColumnWaterHeaterSetpoint].include?(schedule_name)
          schedule_name2 = SchedulesFile::ColumnWaterHeater
        end

        # Skip those unaffected
        next unless Schedule.unavailable_period_applies(runner, schedule_name2, column_name)

        @tmp_schedules[column_name].each_with_index do |_ts, i|
          if schedule_name == ColumnWaterHeaterSetpoint
            # Temperature of tank < 2C indicates of possibility of freeze.
            @tmp_schedules[schedule_name][i] = UnitConversions.convert(2.0, 'C', 'F') if @tmp_schedules[column_name][i] == 1.0
          elsif ![SchedulesFile::ColumnHeatingSetpoint, SchedulesFile::ColumnCoolingSetpoint].include?(schedule_name)
            @tmp_schedules[schedule_name][i] *= (1.0 - @tmp_schedules[column_name][i])
          end
        end
      end
    end
  end

  def convert_setpoints
    return if @tmp_schedules.keys.none? { |k| SchedulesFile.SetpointColumnNames.include?(k) }

    col_names = @tmp_schedules.keys

    @tmp_schedules[col_names[0]].each_with_index do |_ts, i|
      SchedulesFile.SetpointColumnNames.each do |setpoint_col_name|
        next unless col_names.include?(setpoint_col_name)

        @tmp_schedules[setpoint_col_name][i] = UnitConversions.convert(@tmp_schedules[setpoint_col_name][i], 'f', 'c').round(4)
      end
    end
  end

  def battery_schedules
    return if !@schedules.keys.include?(SchedulesFile::ColumnBattery)

    @schedules[SchedulesFile::ColumnBatteryCharging] = Array.new(@schedules[SchedulesFile::ColumnBattery].size, 0)
    @schedules[SchedulesFile::ColumnBatteryDischarging] = Array.new(@schedules[SchedulesFile::ColumnBattery].size, 0)
    @schedules[SchedulesFile::ColumnBattery].each_with_index do |_ts, i|
      if @schedules[SchedulesFile::ColumnBattery][i] > 0
        @schedules[SchedulesFile::ColumnBatteryCharging][i] = @schedules[SchedulesFile::ColumnBattery][i]
      elsif @schedules[SchedulesFile::ColumnBattery][i] < 0
        @schedules[SchedulesFile::ColumnBatteryDischarging][i] = -1 * @schedules[SchedulesFile::ColumnBattery][i]
      end
    end
    @schedules.delete(SchedulesFile::ColumnBattery)
  end

  def self.ColumnNames
    return SchedulesFile.OccupancyColumnNames + SchedulesFile.HVACSetpointColumnNames + SchedulesFile.WaterHeaterColumnNames + SchedulesFile.BatteryColumnNames
  end

  def self.OccupancyColumnNames
    return [
      ColumnOccupants,
      ColumnLightingInterior,
      ColumnLightingExterior,
      ColumnLightingGarage,
      ColumnLightingExteriorHoliday,
      ColumnCookingRange,
      ColumnRefrigerator,
      ColumnExtraRefrigerator,
      ColumnFreezer,
      ColumnDishwasher,
      ColumnClothesWasher,
      ColumnClothesDryer,
      ColumnCeilingFan,
      ColumnPlugLoadsOther,
      ColumnPlugLoadsTV,
      ColumnPlugLoadsVehicle,
      ColumnPlugLoadsWellPump,
      ColumnFuelLoadsGrill,
      ColumnFuelLoadsLighting,
      ColumnFuelLoadsFireplace,
      ColumnPoolPump,
      ColumnPoolHeater,
      ColumnPermanentSpaPump,
      ColumnPermanentSpaHeater,
      ColumnHotWaterDishwasher,
      ColumnHotWaterClothesWasher,
      ColumnHotWaterFixtures
    ]
  end

  def self.HVACSetpointColumnNames
    return [
      ColumnHeatingSetpoint,
      ColumnCoolingSetpoint
    ]
  end

  def self.WaterHeaterColumnNames
    return [
      ColumnWaterHeaterSetpoint,
      ColumnWaterHeaterOperatingMode
    ]
  end

  def self.SetpointColumnNames
    return [
      ColumnHeatingSetpoint,
      ColumnCoolingSetpoint,
      ColumnWaterHeaterSetpoint
    ]
  end

  def self.OperatingModeColumnNames
    return [
      ColumnWaterHeaterOperatingMode
    ]
  end

  def self.BatteryColumnNames
    return [
      ColumnBattery,
      ColumnBatteryCharging,
      ColumnBatteryDischarging
    ]
  end

  def max_value_one
    max_value_one = {}
    column_names = SchedulesFile.ColumnNames
    column_names.each do |column_name|
      max_value_one[column_name] = true
      if SchedulesFile.SetpointColumnNames.include?(column_name) || SchedulesFile.OperatingModeColumnNames.include?(column_name)
        max_value_one[column_name] = false
      end
    end
    return max_value_one
  end

  def min_value_zero
    min_value_zero = {}
    column_names = SchedulesFile.ColumnNames
    column_names.each do |column_name|
      min_value_zero[column_name] = true
      if SchedulesFile.SetpointColumnNames.include?(column_name) || SchedulesFile.OperatingModeColumnNames.include?(column_name) || SchedulesFile.BatteryColumnNames.include?(column_name)
        min_value_zero[column_name] = false
      end
    end
    return min_value_zero
  end

  def min_value_neg_one
    min_value_neg_one = {}
    column_names = SchedulesFile.ColumnNames
    column_names.each do |column_name|
      min_value_neg_one[column_name] = false
      if column_name == SchedulesFile::ColumnBattery
        min_value_neg_one[column_name] = true
      end
    end
    return min_value_neg_one
  end

  def only_zeros_and_ones
    only_zeros_and_ones = {}
    column_names = SchedulesFile.ColumnNames
    column_names.each do |column_name|
      only_zeros_and_ones[column_name] = false
      if SchedulesFile.OperatingModeColumnNames.include?(column_name)
        only_zeros_and_ones[column_name] = true
      end
    end
    return only_zeros_and_ones
  end
end
