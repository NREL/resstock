# TODO: Need to handle vacations

# Annual schedule defined by 12 24-hour values for weekdays and weekends.
class HourlyByMonthSchedule

    # weekday_month_by_hour_values must be a 12-element array of 24-element arrays of numbers.
    # weekend_month_by_hour_values must be a 12-element array of 24-element arrays of numbers.
    def initialize(model, runner, sch_name, weekday_month_by_hour_values, weekend_month_by_hour_values, 
                   normalize_values=true, create_sch_object=true)
        @validated = true
        @model = model
        @runner = runner
        @sch_name = sch_name
        @schedule = nil
        @weekday_month_by_hour_values = validateValues(weekday_month_by_hour_values, 12, 24)
        @weekend_month_by_hour_values = validateValues(weekend_month_by_hour_values, 12, 24)
        if not @validated
            return
        end
        if normalize_values
            @maxval = calcMaxval()
        else
            @maxval = 1.0
        end
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
            return [@weekday_month_by_hour_values.flatten.max, @weekend_month_by_hour_values.flatten.max].max
        end
        
        def createSchedule()
            wkdy = []
            wknd = []
            day_endm = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365]
            day_startm = [0, 1, 32, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335]
            
            time = []
            for h in 1..24
                time[h] = OpenStudio::Time.new(0,h,0,0)
            end

            schedule = OpenStudio::Model::ScheduleRuleset.new(@model)
            schedule.setName(@sch_name)
            
            for m in 1..12
                date_s = OpenStudio::Date::fromDayOfYear(day_startm[m])
                date_e = OpenStudio::Date::fromDayOfYear(day_endm[m])
                
                wkdy_vals = []
                wknd_vals = []
                for h in 1..24
                    wkdy_vals[h] = (@weekday_month_by_hour_values[m-1][h-1].to_f)/@maxval
                    wknd_vals[h] = (@weekend_month_by_hour_values[m-1][h-1].to_f)/@maxval
                end
                
                if wkdy_vals == wknd_vals
                    # Alldays
                    wkdy_rule = OpenStudio::Model::ScheduleRule.new(schedule)
                    wkdy_rule.setName(@sch_name + " #{Schedule.allday_name} ruleset#{m}")
                    wkdy[m] = wkdy_rule.daySchedule
                    wkdy[m].setName(@sch_name + " #{Schedule.allday_name}#{m}")
                    for h in 1..24
                        wkdy[m].addValue(time[h],wkdy_vals[h])
                    end
                    wkdy_rule.setApplySunday(true)
                    wkdy_rule.setApplyMonday(true)
                    wkdy_rule.setApplyTuesday(true)
                    wkdy_rule.setApplyWednesday(true)
                    wkdy_rule.setApplyThursday(true)
                    wkdy_rule.setApplyFriday(true)
                    wkdy_rule.setApplySaturday(true)
                    wkdy_rule.setStartDate(date_s)
                    wkdy_rule.setEndDate(date_e)
                else
                    # Weekdays
                    wkdy_rule = OpenStudio::Model::ScheduleRule.new(schedule)
                    wkdy_rule.setName(@sch_name + " #{Schedule.weekday_name} ruleset#{m}")
                    wkdy[m] = wkdy_rule.daySchedule
                    wkdy[m].setName(@sch_name + " #{Schedule.weekday_name}#{m}")
                    for h in 1..24
                        wkdy[m].addValue(time[h],wkdy_vals[h])
                    end
                    wkdy_rule.setApplySunday(false)
                    wkdy_rule.setApplyMonday(true)
                    wkdy_rule.setApplyTuesday(true)
                    wkdy_rule.setApplyWednesday(true)
                    wkdy_rule.setApplyThursday(true)
                    wkdy_rule.setApplyFriday(true)
                    wkdy_rule.setApplySaturday(false)
                    wkdy_rule.setStartDate(date_s)
                    wkdy_rule.setEndDate(date_e)
                    
                    # Weekends
                    wknd_rule = OpenStudio::Model::ScheduleRule.new(schedule)
                    wknd_rule.setName(@sch_name + " #{Schedule.weekend_name} ruleset#{m}")
                    wknd[m] = wknd_rule.daySchedule
                    wknd[m].setName(@sch_name + " #{Schedule.weekend_name}#{m}")
                    for h in 1..24
                        wknd[m].addValue(time[h],wknd_vals[h])
                    end
                    wknd_rule.setApplySunday(true)
                    wknd_rule.setApplyMonday(false)
                    wknd_rule.setApplyTuesday(false)
                    wknd_rule.setApplyWednesday(false)
                    wknd_rule.setApplyThursday(false)
                    wknd_rule.setApplyFriday(false)
                    wknd_rule.setApplySaturday(true)
                    wknd_rule.setStartDate(date_s)
                    wknd_rule.setEndDate(date_e)
                end
            end
            
            return schedule
        end
    
end

# Annual schedule defined by 24 weekday hourly values, 24 weekend hourly values, and 12 monthly values
class MonthWeekdayWeekendSchedule

    # weekday_hourly_values can either be a comma-separated string of 24 numbers or a 24-element array of numbers.
    # weekend_hourly_values can either be a comma-separated string of 24 numbers or a 24-element array of numbers.
    # monthly_values can either be a comma-separated string of 12 numbers or a 12-element array of numbers.
    def initialize(model, runner, sch_name, weekday_hourly_values, weekend_hourly_values, monthly_values, 
                   mult_weekday=1.0, mult_weekend=1.0, normalize_values=true, create_sch_object=true)
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
        return calcDesignLevelFromDailykWh(OpenStudio.convert(daily_therm, "therm", "kWh").get)
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
                floats = values.map {|i| i.to_f}
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
                    floats = vals.map {|i| i.to_f}
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
            return values.map{|val| val/sum}
        end
        
        def normalizeAvgToOne(values)
            avg = values.reduce(:+).to_f/values.size
            return values.map{|val| val/avg}
        end

        def calcMaxval()
            if @weekday_hourly_values.max > @weekend_hourly_values.max
              return @monthly_values.max * @weekday_hourly_values.max * @mult_weekday
            else
              return @monthly_values.max * @weekend_hourly_values.max * @mult_weekend
            end
        end
        
        def calcSchadjust()
            #if sum != 1, normalize to get correct max val
            sum_wkdy = 0
            sum_wknd = 0
            @weekday_hourly_values.each do |v|
                sum_wkdy = sum_wkdy + v
            end
            @weekend_hourly_values.each do |v|
                sum_wknd = sum_wknd + v
            end
            if sum_wkdy < sum_wknd
                return 1/sum_wknd
            end
            return 1/sum_wkdy
        end
        
        def createSchedule()
            wkdy = []
            wknd = []
            day_endm = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365]
            day_startm = [0, 1, 32, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335]
            
            time = []
            for h in 1..24
                time[h] = OpenStudio::Time.new(0,h,0,0)
            end

            schedule = OpenStudio::Model::ScheduleRuleset.new(@model)
            schedule.setName(@sch_name)
            
            for m in 1..12
                date_s = OpenStudio::Date::fromDayOfYear(day_startm[m])
                date_e = OpenStudio::Date::fromDayOfYear(day_endm[m])
                
                wkdy_vals = []
                wknd_vals = []
                for h in 1..24
                    wkdy_vals[h] = (@monthly_values[m-1].to_f*@weekday_hourly_values[h-1].to_f*@mult_weekday)/@maxval
                    wknd_vals[h] = (@monthly_values[m-1].to_f*@weekend_hourly_values[h-1].to_f*@mult_weekend)/@maxval
                end
                
                if wkdy_vals == wknd_vals
                    # Alldays
                    wkdy_rule = OpenStudio::Model::ScheduleRule.new(schedule)
                    wkdy_rule.setName(@sch_name + " #{Schedule.allday_name} ruleset#{m}")
                    wkdy[m] = wkdy_rule.daySchedule
                    wkdy[m].setName(@sch_name + " #{Schedule.allday_name}#{m}")
                    for h in 1..24
                        wkdy[m].addValue(time[h],wkdy_vals[h])
                    end
                    wkdy_rule.setApplySunday(true)
                    wkdy_rule.setApplyMonday(true)
                    wkdy_rule.setApplyTuesday(true)
                    wkdy_rule.setApplyWednesday(true)
                    wkdy_rule.setApplyThursday(true)
                    wkdy_rule.setApplyFriday(true)
                    wkdy_rule.setApplySaturday(true)
                    wkdy_rule.setStartDate(date_s)
                    wkdy_rule.setEndDate(date_e)
                else
                    # Weekdays
                    wkdy_rule = OpenStudio::Model::ScheduleRule.new(schedule)
                    wkdy_rule.setName(@sch_name + " #{Schedule.weekday_name} ruleset#{m}")
                    wkdy[m] = wkdy_rule.daySchedule
                    wkdy[m].setName(@sch_name + " #{Schedule.weekday_name}#{m}")
                    for h in 1..24
                        wkdy[m].addValue(time[h],wkdy_vals[h])
                    end
                    wkdy_rule.setApplySunday(false)
                    wkdy_rule.setApplyMonday(true)
                    wkdy_rule.setApplyTuesday(true)
                    wkdy_rule.setApplyWednesday(true)
                    wkdy_rule.setApplyThursday(true)
                    wkdy_rule.setApplyFriday(true)
                    wkdy_rule.setApplySaturday(false)
                    wkdy_rule.setStartDate(date_s)
                    wkdy_rule.setEndDate(date_e)
                    
                    # Weekends
                    wknd_rule = OpenStudio::Model::ScheduleRule.new(schedule)
                    wknd_rule.setName(@sch_name + " #{Schedule.weekend_name} ruleset#{m}")
                    wknd[m] = wknd_rule.daySchedule
                    wknd[m].setName(@sch_name + " #{Schedule.weekend_name}#{m}")
                    for h in 1..24
                        wknd[m].addValue(time[h],wknd_vals[h])
                    end
                    wknd_rule.setApplySunday(true)
                    wknd_rule.setApplyMonday(false)
                    wknd_rule.setApplyTuesday(false)
                    wknd_rule.setApplyWednesday(false)
                    wknd_rule.setApplyThursday(false)
                    wknd_rule.setApplyFriday(false)
                    wknd_rule.setApplySaturday(true)
                    wknd_rule.setStartDate(date_s)
                    wknd_rule.setEndDate(date_e)
                end
            end
            
            return schedule
        end
    
end

class HotWaterSchedule

    def initialize(model, runner, sch_name, temperature_sch_name, num_bedrooms, unit_index, days_shift, file_prefix, target_water_temperature, measure_dir, create_sch_object=true)
        @validated = true
        @model = model
        @runner = runner
        @sch_name = sch_name
        @schedule = nil
        @temperature_sch_name = temperature_sch_name
        @days_shift = days_shift
        @nbeds = ([num_bedrooms, 5].min).to_i
        @file_prefix = file_prefix
        @target_water_temperature = OpenStudio.convert(target_water_temperature, "F", "C").get
        
        timestep_minutes = (60/@model.getTimestep.numberOfTimestepsPerHour).to_i
        
        data = loadMinuteDrawProfileFromFile(timestep_minutes, unit_index, days_shift, measure_dir)
        @totflow, @maxflow, @ontime = loadDrawProfileStatsFromFile(measure_dir)
        if data.nil? or @totflow.nil? or @maxflow.nil? or @ontime.nil?
            @validated = false
            return
        end
        if create_sch_object
            @schedule = createSchedule(data, timestep_minutes)
        end
    end

    def validated?
        return @validated
    end
    
    def calcDesignLevelFromDailykWh(daily_kWh)
        return OpenStudio.convert(daily_kWh * 365 * 60 / (365 * @totflow / @maxflow), "kW", "W").get
    end
    
    def calcPeakFlowFromDailygpm(daily_water)
        return OpenStudio.convert(@maxflow * daily_water / @totflow, "gal/min", "m^3/s").get
    end
    
    def calcDailyGpmFromPeakFlow(peak_flow)
        return OpenStudio.convert(@totflow * peak_flow / @maxflow, "m^3/s", "gal/min").get 
    end
    
    def schedule
        return @schedule
    end
    
    def temperatureSchedule
        temperature_sch = OpenStudio::Model::ScheduleConstant.new(@model)
        temperature_sch.setValue(@target_water_temperature)
        temperature_sch.setName(@temperature_sch_name)
        return temperature_sch
    end

    def getOntimeFraction
        return @ontime
    end
    
    private
    
        def loadMinuteDrawProfileFromFile(timestep_minutes, unit_index, days_shift, measure_dir)
            data = []
            if @file_prefix.nil?
                return data
            end

            # Get appropriate file
            minute_draw_profile = "#{measure_dir}/resources/#{@file_prefix}Schedule_#{@nbeds}bed.csv"
            if not File.file?(minute_draw_profile)
                @runner.registerError("Unable to find file: #{minute_draw_profile}")
                return nil
            end
            
            #For MF homes, shift each unit by an additional week
            days_shift = (days_shift + 7 * unit_index) % 365
            minutes_in_year = 8760 * 60
            
            # Read data into minute array
            skippedheader = false
            min_shift = 24 * 60 * days_shift
            items = [0]*minutes_in_year
            File.open(minute_draw_profile).each do |line|
                linedata = line.strip.split(',')
                if not skippedheader
                    skippedheader = true
                    next
                end
                minute = linedata[0].to_i
                shifted_min = minute + min_shift
                if shifted_min > minutes_in_year
                    shifted_min = shifted_min - minutes_in_year
                end
                value = linedata[1].to_f
                items[shifted_min] = value
            end
            
            # Aggregate minute schedule up to the timestep level to reduce the size 
            # and speed of processing.
            for tstep in 0..(minutes_in_year/timestep_minutes).to_i-1
                timestep_items = items[tstep*timestep_minutes,timestep_minutes]
                avgitem = timestep_items.reduce(:+).to_f/timestep_items.size
                data.push(avgitem)
            end
            
            return data
        end
        
        def loadDrawProfileStatsFromFile(measure_dir)
            totflow = 0 # daily gal/day
            maxflow = 0
            ontime = 0
            
            column_header = @file_prefix
            
            totflow_column_header = "#{column_header} Sum"
            maxflow_column_header = "#{column_header} Max"
            ontime_column_header = "On-time Fraction"
            
            draw_file = "#{measure_dir}/resources/MinuteDrawProfilesMaxFlows.csv"
            
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
    
        def createSchedule(data, timestep_minutes)
            # OpenStudio does not yet support ScheduleFile. So we use ScheduleInterval instead.
            # See https://unmethours.com/question/2877/has-anyone-used-the-variable-interval-schedule-sets-in-os-16/
            # for an example.
            if data.size == 0
                return nil
            end
            
            yd = @model.getYearDescription
            start_date = yd.makeDate(1,1)
            interval = OpenStudio::Time.new(0, 0, timestep_minutes)
            
            time_series = OpenStudio::TimeSeries.new(start_date, interval, OpenStudio::createVector(data), "")
            
            schedule = OpenStudio::Model::ScheduleInterval.fromTimeSeries(time_series, @model).get
            schedule.setName(@sch_name)
            
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
  def self.annual_equivalent_full_load_hrs(modelYear, schedule)

    if schedule.to_ScheduleInterval.is_initialized
        timeSeries = schedule.to_ScheduleInterval.get.timeSeries
        annual_flh = timeSeries.averageValue * 8760
        return annual_flh
    end

    if not schedule.to_ScheduleRuleset.is_initialized
      return nil
    end
    
    schedule = schedule.to_ScheduleRuleset.get

    # Define the start and end date
    year_start_date = OpenStudio::Date.new(OpenStudio::MonthOfYear.new("January"),1,modelYear)
    year_end_date = OpenStudio::Date.new(OpenStudio::MonthOfYear.new("December"),31,modelYear)

    # Get the ordered list of all the day schedules
    # that are used by this schedule ruleset
    day_schs = schedule.getDaySchedules(year_start_date, year_end_date)
    
    # Get a 365-value array of which schedule is used on each day of the year,
    day_schs_used_each_day = schedule.getActiveRuleIndices(year_start_date, year_end_date)
    if !day_schs_used_each_day.length == 365
      OpenStudio::logFree(OpenStudio::Error, "openstudio.standards.ScheduleRuleset", "#{schedule.name} does not have 365 daily schedules accounted for, cannot accurately calculate annual EFLH.")
      return 0
    end
    
    # Create a map that shows how many days each schedule is used
    day_sch_freq = day_schs_used_each_day.group_by { |n| n }
    
    # Build a hash that maps schedule day index to schedule day
    schedule_index_to_day = {}
    for i in 0..(day_schs.length-1)
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
        time_decimal = (time_days*24) + time_hours + (time_minutes/60) + (time_seconds/3600)
        duration_of_value = time_decimal - previous_time_decimal
        daily_flh += values[i]*duration_of_value
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
  
end