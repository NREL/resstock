require_relative "schedules"
require_relative "geometry"
require_relative "unit_conversions"

class Lighting
  def self.get_lighting_sch(model, runner, weather, sch_option_type, monthly_sch)
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

    return lighting_sch
  end

  def self.apply_interior(model, unit, runner, weather, sch, interior_ann, sch_option_type, monthly_sch)
    lighting_sch = get_lighting_sch(model, runner, weather, sch_option_type, monthly_sch)
    return false unless lighting_sch

    # Get unit ffa and finished spaces
    unit_finished_spaces = Geometry.get_finished_spaces(unit.spaces)
    ffa = Geometry.get_finished_floor_area_from_spaces(unit.spaces, runner)
    if ffa.nil?
      return false
    end

    # Design day schedules used when autosizing
    winter_design_day_sch = OpenStudio::Model::ScheduleDay.new(model)
    winter_design_day_sch.addValue(OpenStudio::Time.new(0, 24, 0, 0), 0)
    summer_design_day_sch = OpenStudio::Model::ScheduleDay.new(model)
    summer_design_day_sch.addValue(OpenStudio::Time.new(0, 24, 0, 0), 1)

    # Finished spaces for the unit
    unit_finished_spaces.each do |space|
      space_obj_name = "#{Constants.ObjectNameLightingInterior(unit.name.to_s)} #{space.name.to_s}"

      if sch.nil?
        # Create schedule
        sch = HourlyByMonthSchedule.new(model, runner, Constants.ObjectNameLightingInterior, lighting_sch, lighting_sch, normalize_values = true, create_sch_object = true, winter_design_day_sch = winter_design_day_sch, summer_design_day_sch = summer_design_day_sch, schedule_type_limits_name = Constants.ScheduleTypeLimitsFraction)
        if not sch.validated?
          return false
        end
      end

      if unit_finished_spaces.include?(space)
        space_ltg_ann = interior_ann * UnitConversions.convert(space.floorArea, "m^2", "ft^2") / ffa
      end
      space_design_level = sch.calcDesignLevel(sch.maxval * space_ltg_ann)

      # Add lighting
      ltg_def = OpenStudio::Model::LightsDefinition.new(model)
      ltg = OpenStudio::Model::Lights.new(ltg_def)
      ltg.setName(space_obj_name)
      ltg.setSpace(space)
      ltg_def.setName(space_obj_name)
      ltg_def.setLightingLevel(space_design_level)
      ltg_def.setFractionRadiant(0.6)
      ltg_def.setFractionVisible(0.2)
      ltg_def.setReturnAirFraction(0.0)
      ltg.setSchedule(sch.schedule)
      ltg.setEndUseSubcategory(space_obj_name)
    end

    return true, sch
  end

  def self.apply_garage(model, runner, weather, sch, garage_ann, sch_option_type, weekday_sch, weekend_sch, monthly_sch)
    lighting_sch = nil
    if sch_option_type == Constants.OptionTypeLightingScheduleCalculated
      lighting_sch = get_lighting_sch(model, runner, weather, sch_option_type, monthly_sch)
    end

    # Design day schedules used when autosizing
    winter_design_day_sch = OpenStudio::Model::ScheduleDay.new(model)
    winter_design_day_sch.addValue(OpenStudio::Time.new(0, 24, 0, 0), 0)
    summer_design_day_sch = OpenStudio::Model::ScheduleDay.new(model)
    summer_design_day_sch.addValue(OpenStudio::Time.new(0, 24, 0, 0), 1)

    year_description = model.getYearDescription
    num_days_in_year = Constants.NumDaysInYear(year_description.isLeapYear)

    garage_spaces = Geometry.get_garage_spaces(model.getSpaces)
    gfa = Geometry.get_floor_area_from_spaces(garage_spaces)
    garage_spaces.each do |garage_space|
      space_obj_name = "#{Constants.ObjectNameLightingGarage} #{garage_space.name.to_s}"
      space_ltg_ann = garage_ann * UnitConversions.convert(garage_space.floorArea, "m^2", "ft^2") / gfa

      if sch.nil?
        # Create schedule
        if lighting_sch.nil?
          sch = MonthWeekdayWeekendSchedule.new(model, runner, Constants.ObjectNameLightingGarage, weekday_sch, weekend_sch, monthly_sch, mult_weekday = 1.0, mult_weekend = 1.0, normalize_values = true, create_sch_object = true, winter_design_day_sch, summer_design_day_sch)
        else
          sch = HourlyByMonthSchedule.new(model, runner, Constants.ObjectNameLightingGarage, lighting_sch, lighting_sch, normalize_values = true, create_sch_object = true, winter_design_day_sch, summer_design_day_sch)
        end
        if not sch.validated?
          return false
        end
      end

      space_design_level = nil
      if sch_option_type == Constants.OptionTypeLightingScheduleCalculated
        space_design_level = sch.calcDesignLevel(sch.maxval * space_ltg_ann)
      elsif sch_option_type == Constants.OptionTypeLightingScheduleUserSpecified
        space_design_level = sch.calcDesignLevelFromDailykWh(space_ltg_ann / num_days_in_year)
      end

      # Add lighting
      ltg_def = OpenStudio::Model::LightsDefinition.new(model)
      ltg = OpenStudio::Model::Lights.new(ltg_def)
      ltg.setName(space_obj_name)
      ltg.setSpace(garage_space)
      ltg_def.setName(space_obj_name)
      ltg_def.setLightingLevel(space_design_level)
      ltg_def.setFractionRadiant(0.6)
      ltg_def.setFractionVisible(0.2)
      ltg_def.setReturnAirFraction(0.0)
      ltg.setSchedule(sch.schedule)
      ltg.setEndUseSubcategory(space_obj_name)
    end

    return true
  end

  def self.apply_exterior(model, runner, weather, sch, exterior_ann, sch_option_type, weekday_sch, weekend_sch, monthly_sch)
    lighting_sch = nil
    if sch_option_type == Constants.OptionTypeLightingScheduleCalculated
      lighting_sch = get_lighting_sch(model, runner, weather, sch_option_type, monthly_sch)
    end

    # Design day schedules used when autosizing
    winter_design_day_sch = OpenStudio::Model::ScheduleDay.new(model)
    winter_design_day_sch.addValue(OpenStudio::Time.new(0, 24, 0, 0), 0)
    summer_design_day_sch = OpenStudio::Model::ScheduleDay.new(model)
    summer_design_day_sch.addValue(OpenStudio::Time.new(0, 24, 0, 0), 1)

    year_description = model.getYearDescription
    num_days_in_year = Constants.NumDaysInYear(year_description.isLeapYear)

    obj_name = Constants.ObjectNameLightingExterior

    if sch.nil?
      # Create schedule
      if lighting_sch.nil?
        sch = MonthWeekdayWeekendSchedule.new(model, runner, obj_name, weekday_sch, weekend_sch, monthly_sch, mult_weekday = 1.0, mult_weekend = 1.0, normalize_values = true, create_sch_object = true, winter_design_day_sch, summer_design_day_sch)
      else
        sch = HourlyByMonthSchedule.new(model, runner, obj_name, lighting_sch, lighting_sch, normalize_values = true, create_sch_object = true, winter_design_day_sch, summer_design_day_sch)
      end
      if not sch.validated?
        return false
      end
    end

    design_level = nil
    if sch_option_type == Constants.OptionTypeLightingScheduleCalculated
      design_level = sch.calcDesignLevel(sch.maxval * exterior_ann)
    elsif sch_option_type == Constants.OptionTypeLightingScheduleUserSpecified
      design_level = sch.calcDesignLevelFromDailykWh(exterior_ann / num_days_in_year)
    end

    # Add exterior lighting
    ltg_def = OpenStudio::Model::ExteriorLightsDefinition.new(model)
    ltg = OpenStudio::Model::ExteriorLights.new(ltg_def)
    ltg.setName(obj_name)
    ltg_def.setName(obj_name)
    ltg_def.setDesignLevel(design_level)
    ltg.setSchedule(sch.schedule)
    ltg.setEndUseSubcategory(obj_name)

    return true
  end

  def self.apply_exterior_holiday(model, runner, daily_exterior_ann, holiday_periods, holiday_sch)
    vals = holiday_sch.split(",")
    vals.each do |val|
      begin Float(val)
      rescue
        runner.registerError("A comma-separated string of 24 numbers must be entered for the holiday schedule.")
        return false
      end
    end
    holiday_sch = vals.map { |i| i.to_f }
    if holiday_sch.length != 24
      runner.registerError("A comma-separated string of 24 numbers must be entered for the holiday schedule.")
      return false
    end

    # Design day schedules used when autosizing
    winter_design_day_sch = OpenStudio::Model::ScheduleDay.new(model)
    winter_design_day_sch.addValue(OpenStudio::Time.new(0, 24, 0, 0), 0)
    summer_design_day_sch = OpenStudio::Model::ScheduleDay.new(model)
    summer_design_day_sch.addValue(OpenStudio::Time.new(0, 24, 0, 0), 1)

    obj_name = Constants.ObjectNameLightingExteriorHoliday

    sch = OpenStudio::Model::ScheduleRuleset.new(model, 0)
    sch.setName(obj_name)

    sch.setWinterDesignDaySchedule(winter_design_day_sch)
    sch.winterDesignDaySchedule.setName("#{sch.name} winter design")
    sch.setSummerDesignDaySchedule(summer_design_day_sch)
    sch.summerDesignDaySchedule.setName("#{sch.name} summer design")

    holiday_periods.each do |holiday_period|
      holiday_start_date, holiday_end_date = holiday_period

      holiday_rule = OpenStudio::Model::ScheduleRule.new(sch)
      holiday_day = holiday_rule.daySchedule

      (0..23).each do |hour|
        holiday_day.addValue(OpenStudio::Time.new(0, hour + 1, 0, 0), holiday_sch[hour] / holiday_sch.max)
      end

      holiday_rule.setApplySunday(true)
      holiday_rule.setApplyMonday(true)
      holiday_rule.setApplyTuesday(true)
      holiday_rule.setApplyWednesday(true)
      holiday_rule.setApplyThursday(true)
      holiday_rule.setApplyFriday(true)
      holiday_rule.setApplySaturday(true)
      holiday_rule.setStartDate(holiday_start_date)
      holiday_rule.setEndDate(holiday_end_date)
    end

    design_level = daily_exterior_ann * holiday_sch.max * 1000

    # Add exterior lighting
    ltg_def = OpenStudio::Model::ExteriorLightsDefinition.new(model)
    ltg = OpenStudio::Model::ExteriorLights.new(ltg_def)
    ltg.setName(obj_name)
    ltg_def.setName(obj_name)
    ltg_def.setDesignLevel(design_level)
    ltg.setSchedule(sch)
    ltg.setEndUseSubcategory(obj_name)

    return true
  end

  def self.remove_interior(model, runner)
    objects_to_remove = []
    model.getLightss.each do |light|
      next unless Geometry.space_is_finished(light.space.get)

      objects_to_remove << light
      objects_to_remove << light.lightsDefinition
      if light.schedule.is_initialized
        objects_to_remove << light.schedule.get
      end
    end
    if objects_to_remove.size > 0
      runner.registerInfo("Removed existing interior lighting from the model.")
    end
    objects_to_remove.uniq.each do |object|
      begin
        object.remove
      rescue
        # no op
      end
    end
  end

  def self.remove_other(model, runner)
    objects_to_remove = []
    model.getExteriorLightss.each do |exterior_light|
      objects_to_remove << exterior_light
      objects_to_remove << exterior_light.exteriorLightsDefinition
      if exterior_light.schedule.is_initialized
        objects_to_remove << exterior_light.schedule.get
      end
    end
    model.getLightss.each do |light|
      next if Geometry.space_is_finished(light.space.get)

      objects_to_remove << light
      objects_to_remove << light.lightsDefinition
      if light.schedule.is_initialized
        objects_to_remove << light.schedule.get
      end
    end
    if objects_to_remove.size > 0
      runner.registerInfo("Removed existing garage/exterior lighting from the model.")
    end
    objects_to_remove.uniq.each do |object|
      begin
        object.remove
      rescue
        # no op
      end
    end
  end

  def self.get_reference_fractions()
    fFI_int = 0.10
    fFI_ext = 0.0
    fFI_grg = 0.0
    fFII_int = 0.0
    fFII_ext = 0.0
    fFII_grg = 0.0
    return fFI_int, fFI_ext, fFI_grg, fFII_int, fFII_ext, fFII_grg
  end

  def self.get_iad_fractions()
    fFI_int = 0.75
    fFI_ext = 0.75
    fFI_grg = 0.75
    fFII_int = 0.0
    fFII_ext = 0.0
    fFII_grg = 0.0
    return fFI_int, fFI_ext, fFI_grg, fFII_int, fFII_ext, fFII_grg
  end

  def self.calc_lighting_energy(eri_version, cfa, garage_present, fFI_int, fFI_ext, fFI_grg, fFII_int, fFII_ext, fFII_grg)
    if eri_version.include? "G"
      # ANSI/RESNET/ICC 301-2014 Addendum G-2018, Solid State Lighting
      int_kwh = 0.9 / 0.925 * (455.0 + 0.8 * cfa) * ((1.0 - fFII_int - fFI_int) + fFI_int * 15.0 / 60.0 + fFII_int * 15.0 / 90.0) + 0.1 * (455.0 + 0.8 * cfa) # Eq 4.2-2)
      ext_kwh = (100.0 + 0.05 * cfa) * (1.0 - fFI_ext - fFII_ext) + 15.0 / 60.0 * (100.0 + 0.05 * cfa) * fFI_ext + 15.0 / 90.0 * (100.0 + 0.05 * cfa) * fFII_ext # Eq 4.2-3
      grg_kwh = 0.0
      if garage_present
        grg_kwh = 100.0 * ((1.0 - fFI_grg - fFII_grg) + 15.0 / 60.0 * fFI_grg + 15.0 / 90.0 * fFII_grg) # Eq 4.2-4
      end
    else
      int_kwh = 0.8 * ((4.0 - 3.0 * (fFI_int + fFII_int)) / 3.7) * (455.0 + 0.8 * cfa) + 0.2 * (455.0 + 0.8 * cfa) # Eq 4.2-2
      ext_kwh = (100.0 + 0.05 * cfa) * (1.0 - (fFI_ext + fFII_ext)) + 0.25 * (100.0 + 0.05 * cfa) * (fFI_ext + fFII_ext) # Eq 4.2-3
      grg_kwh = 0.0
      if garage_present
        grg_kwh = 100.0 * (1.0 - (fFI_grg + fFII_grg)) + 25.0 * (fFI_grg + fFII_grg) # Eq 4.2-4
      end
    end
    return int_kwh, ext_kwh, grg_kwh
  end
end
