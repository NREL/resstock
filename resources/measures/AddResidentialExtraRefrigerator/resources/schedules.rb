# TODO: Need to handle vacations

# Annual schedule defined by 12 24-hour values for weekdays and weekends.
class HourlyByMonthSchedule

    # weekday_month_by_hour_values must be a 12-element array of 24-element arrays of numbers.
    # weekend_month_by_hour_values must be a 12-element array of 24-element arrays of numbers.
    def initialize(model, runner, sch_name, weekday_month_by_hour_values, weekend_month_by_hour_values, 
                   normalize_values=true)
        @validated = true
        @model = model
        @runner = runner
        @sch_name = sch_name
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
        @schedule = createSchedule()
    end
    
    def validated?
        return @validated
    end
    
    def calcDesignLevel(val)
        return val * 1000
    end

    def setSchedule(obj)
        # Helper method to set (or replace) the object's schedule
        if obj.is_a? OpenStudio::Model::ThermostatSetpointDualSetpoint
            if @schedule.name.to_s.downcase.include? "heating"
              unless obj.heatingSetpointTemperatureSchedule.empty?
                  sch = obj.heatingSetpointTemperatureSchedule.get
                  sch.remove
              end
              obj.setHeatingSetpointTemperatureSchedule(@schedule)
            end
            if @schedule.name.to_s.downcase.include? "cooling"
              unless obj.coolingSetpointTemperatureSchedule.empty?
                  sch = obj.coolingSetpointTemperatureSchedule.get
                  sch.remove
              end
              obj.setCoolingSetpointTemperatureSchedule(@schedule)
            end
        else
          unless obj.schedule.empty?
              sch = obj.schedule.get
              sch.remove
          end
          obj.setSchedule(@schedule)
        end
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
                for w in 1..2
                    if w == 1
                        wkdy_rule = OpenStudio::Model::ScheduleRule.new(schedule)
                        wkdy_rule.setName(@sch_name + " weekday ruleset#{m}")
                        wkdy[m] = wkdy_rule.daySchedule
                        wkdy[m].setName(@sch_name + " weekday#{m}")
                        for h in 1..24
                            val = (@weekday_month_by_hour_values[m-1][h-1].to_f)/@maxval
                            wkdy[m].addValue(time[h],val)
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
                    elsif w == 2
                        wknd_rule = OpenStudio::Model::ScheduleRule.new(schedule)
                        wknd_rule.setName(@sch_name + " weekend ruleset#{m}")
                        wknd[m] = wknd_rule.daySchedule
                        wknd[m].setName(@sch_name + " weekend#{m}")
                        for h in 1..24
                            val = (@weekend_month_by_hour_values[m-1][h-1].to_f)/@maxval
                            wknd[m].addValue(time[h],val)
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
            end
            
            sumDesSch = wkdy[6] # TODO: Where did this come from?
            sumDesSch.setName(@sch_name + " summer")
            winDesSch = wkdy[1] # TODO: Where did this come from?
            winDesSch.setName(@sch_name + " winter")
            schedule.setSummerDesignDaySchedule(sumDesSch)
            schedule.setWinterDesignDaySchedule(winDesSch)
            
            return schedule
        end
    
end

# Annual schedule defined by 24 weekday hourly values, 24 weekend hourly values, and 12 monthly values
class MonthWeekdayWeekendSchedule

    # weekday_hourly_values can either be a comma-separated string of 24 numbers or a 24-element array of numbers.
    # weekend_hourly_values can either be a comma-separated string of 24 numbers or a 24-element array of numbers.
    # monthly_values can either be a comma-separated string of 12 numbers or a 12-element array of numbers.
    def initialize(model, runner, sch_name, weekday_hourly_values, weekend_hourly_values, monthly_values, 
                   mult_weekday=1.0, mult_weekend=1.0, normalize_values=true)
        @validated = true
        @model = model
        @runner = runner
        @sch_name = sch_name
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
        @schedule = createSchedule()
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

    def setSchedule(obj)
        # Helper method to set (or replace) the object's schedule
        if obj.is_a? OpenStudio::Model::People
            unless obj.numberofPeopleSchedule.empty?
                sch = obj.numberofPeopleSchedule.get
                sch.remove
            end
            obj.setNumberofPeopleSchedule(@schedule)
        elsif obj.is_a? OpenStudio::Model::ThermostatSetpointDualSetpoint
            if @schedule.name.to_s.downcase.include? "heating"
              unless obj.heatingSetpointTemperatureSchedule.empty?
                  sch = obj.heatingSetpointTemperatureSchedule.get
                  sch.remove
              end
              obj.setHeatingSetpointTemperatureSchedule(@schedule)
            end
            if @schedule.name.to_s.downcase.include? "cooling"
              unless obj.coolingSetpointTemperatureSchedule.empty?
                  sch = obj.coolingSetpointTemperatureSchedule.get
                  sch.remove
              end
              obj.setCoolingSetpointTemperatureSchedule(@schedule)
            end
        elsif obj.is_a? OpenStudio::Model::CoilHeatingGas or obj.is_a? OpenStudio::Model::CoilHeatingElectric or obj.is_a? OpenStudio::Model::CoilCoolingDXSingleSpeed or obj.is_a? OpenStudio::Model::CoilCoolingDXMultiSpeed or obj.is_a? OpenStudio::Model::ZoneHVACBaseboardConvectiveWater or obj.is_a? OpenStudio::Model::ZoneHVACPackagedTerminalAirConditioner or obj.is_a? OpenStudio::Model::ZoneHVACBaseboardConvectiveElectric or obj.is_a? OpenStudio::Model::CoilHeatingDXSingleSpeed or obj.is_a? OpenStudio::Model::CoilHeatingDXMultiSpeed
            obj.setAvailabilitySchedule(@schedule)
        else
            unless obj.schedule.empty?
                sch = obj.schedule.get
                sch.remove
            end
            obj.setSchedule(@schedule)
        end
    end
    
    private 
    
        def validateValues(values, num_values, sch_name)
            err_msg = "Either a comma-separated string of #{num_values.to_s} numbers or an array of #{num_values.to_s} numbers must be entered for the #{sch_name} schedule."
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
                for w in 1..2
                    if w == 1
                        wkdy_rule = OpenStudio::Model::ScheduleRule.new(schedule)
                        wkdy_rule.setName(@sch_name + " weekday ruleset#{m}")
                        wkdy[m] = wkdy_rule.daySchedule
                        wkdy[m].setName(@sch_name + " weekday#{m}")
                        for h in 1..24
                            val = (@monthly_values[m-1].to_f*@weekday_hourly_values[h-1].to_f*@mult_weekday)/@maxval
                            wkdy[m].addValue(time[h],val)
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
                        
                    elsif w == 2
                        wknd_rule = OpenStudio::Model::ScheduleRule.new(schedule)
                        wknd_rule.setName(@sch_name + " weekend ruleset#{m}")
                        wknd[m] = wknd_rule.daySchedule
                        wknd[m].setName(@sch_name + " weekend#{m}")
                        for h in 1..24
                            val = (@monthly_values[m-1].to_f*@weekend_hourly_values[h-1].to_f*@mult_weekend)/@maxval
                            wknd[m].addValue(time[h],val)
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
            end
            
            sumDesSch = wkdy[6] # TODO: Where did this come from?
            sumDesSch.setName(@sch_name + " summer")
            winDesSch = wkdy[1] # TODO: Where did this come from?
            winDesSch.setName(@sch_name + " winter")
            schedule.setSummerDesignDaySchedule(sumDesSch)
            schedule.setWinterDesignDaySchedule(winDesSch)
            
            return schedule
        end
    
end

class HotWaterSchedule

    def initialize(model, runner, sch_name, temperature_sch_name, num_bedrooms, unit_num, file_prefix, target_water_temperature, measure_dir)
        @validated = true
        @model = model
        @runner = runner
        @sch_name = sch_name
        @temperature_sch_name = temperature_sch_name
        @num_bedrooms = num_bedrooms.to_i
        @unit_index = unit_num % 10
        @file_prefix = file_prefix
        @target_water_temperature = OpenStudio.convert(target_water_temperature, "F", "C").get
        
        timestep_minutes = (60/@model.getTimestep.numberOfTimestepsPerHour).to_i
        
        data = loadMinuteDrawProfileFromFile(timestep_minutes, measure_dir)
        @totflow, @maxflow = loadDrawProfileStatsFromFile(measure_dir)
        if data.nil? or @totflow.nil? or @maxflow.nil?
            @validated = false
            return
        end
        @schedule = createSchedule(data, timestep_minutes)
    end

    def validated?
        return @validated
    end
    
    def calcDesignLevelFromDailykWh(daily_kWh)
        return OpenStudio.convert(daily_kWh*365*60/(365*@totflow/@maxflow), "kW", "W").get
    end
    
    def calcPeakFlowFromDailygpm(daily_water)
        return OpenStudio.convert(@maxflow * daily_water / @totflow, "gal/min", "m^3/s").get
    end

    def setSchedule(obj)
        # Helper method to set (or replace) the object's electric equipment schedule
        if not obj.schedule.empty?
            sch = obj.schedule.get
            sch.remove
        end
        obj.setSchedule(@schedule)
    end
    
    def setWaterSchedule(obj)
        # Helper method to set (or replace) the object's water use equipment schedule
        
        # Flow rate fraction schedule
        if not obj.flowRateFractionSchedule.empty?
            sch = obj.flowRateFractionSchedule.get
            sch.remove
        end
        obj.setFlowRateFractionSchedule(@schedule)
        
        if not obj.waterUseEquipmentDefinition.targetTemperatureSchedule.empty?
            sch = obj.waterUseEquipmentDefinition.targetTemperatureSchedule.get
            sch.remove
        end
        temperature_sch = OpenStudio::Model::ScheduleConstant.new(@model)
        temperature_sch.setValue(@target_water_temperature)
        temperature_sch.setName(@temperature_sch_name)
        obj.waterUseEquipmentDefinition.setTargetTemperatureSchedule(temperature_sch)
    end
    
    private
    
        def loadMinuteDrawProfileFromFile(timestep_minutes, measure_dir)
            data = []
            
            # Get appropriate file
            minute_draw_profile = "#{measure_dir}/resources/#{@file_prefix}Schedule_#{@num_bedrooms}bed_unit#{@unit_index}.csv"
            if not File.file?(minute_draw_profile)
                @runner.registerError("Unable to find file: #{minute_draw_profile}")
                return nil
            end
            
            minutes_in_year = 8760*60
            
            # Read data into minute array
            skippedheader = false
            items = [0]*minutes_in_year
            File.open(minute_draw_profile).each do |line|
                linedata = line.strip.split(',')
                if not skippedheader
                    skippedheader = true
                    next
                end
                minute = linedata[0].to_i
                value = linedata[1].to_f
                items[minute] = value
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
            
            column_header = @file_prefix
            
            totflow_column_header = "#{column_header} Sum"
            maxflow_column_header = "#{column_header} Max"
            
            draw_file = "#{measure_dir}/resources/MinuteDrawProfilesMaxFlows.csv"
            
            datafound = false
            skippedheader = false
            totflow_col_num = nil
            maxflow_col_num = nil
            File.open(draw_file).each do |line|
                linedata = line.strip.split(',')
                if not skippedheader
                    skippedheader = true
                    # Which columns to read?
                    totflow_col_num = linedata.index(totflow_column_header)
                    maxflow_col_num = linedata.index(maxflow_column_header)
                    next
                end
                if totflow_col_num.nil?
                    @runner.registerError("Unable to find column header: #{totflow_column_header}")
                    return nil, nil
                end
                if maxflow_col_num.nil?
                    @runner.registerError("Unable to find column header: #{maxflow_column_header}")
                    return nil, nil
                end
                if linedata[0].to_i == @num_bedrooms and linedata[1].to_i == @unit_index
                    datafound = true
                    totflow = linedata[totflow_col_num].to_f
                    maxflow = linedata[maxflow_col_num].to_f
                    break
                end
            end
            
            if not datafound
                @runner.registerError("Unable to find data for bedrooms = #{@num_bedrooms} and unit index = #{@unit_index}.")
                return nil, nil
            end
            return totflow, maxflow
            
        end
    
        def createSchedule(data, timestep_minutes)
            # OpenStudio does not yet support ScheduleFile. So we use ScheduleInterval instead.
            # See https://unmethours.com/question/2877/has-anyone-used-the-variable-interval-schedule-sets-in-os-16/
            # for an example.
            
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
  def self.annual_equivalent_full_load_hrs(model, schedule)

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
    year_start_date = OpenStudio::Date.new(OpenStudio::MonthOfYear.new("January"),1,2009)
    year_end_date = OpenStudio::Date.new(OpenStudio::MonthOfYear.new("December"),31,2009)

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