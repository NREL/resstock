# frozen_string_literal: true

class Lighting
  def self.apply(runner, model, epw_file, spaces, lighting_groups, lighting, eri_version, schedules_file, cfa, unavailable_periods)
    ltg_locns = [HPXML::LocationInterior, HPXML::LocationExterior, HPXML::LocationGarage]
    ltg_types = [HPXML::LightingTypeCFL, HPXML::LightingTypeLFL, HPXML::LightingTypeLED]

    kwhs_per_year = {}
    fractions = {}
    lighting_groups.each do |lg|
      if ltg_locns.include?(lg.location) && (not lg.kwh_per_year.nil?)
        kwhs_per_year[lg.location] = lg.kwh_per_year
      elsif ltg_locns.include?(lg.location) && ltg_types.include?(lg.lighting_type) && (not lg.fraction_of_units_in_location.nil?)
        fractions[[lg.location, lg.lighting_type]] = lg.fraction_of_units_in_location
      end
    end

    # Calculate interior lighting kWh/yr
    int_kwh = kwhs_per_year[HPXML::LocationInterior]
    if int_kwh.nil?
      int_kwh = calc_interior_energy(eri_version, cfa,
                                     fractions[[HPXML::LocationInterior, HPXML::LightingTypeCFL]],
                                     fractions[[HPXML::LocationInterior, HPXML::LightingTypeLFL]],
                                     fractions[[HPXML::LocationInterior, HPXML::LightingTypeLED]],
                                     lighting.interior_usage_multiplier)
    end
    int_kwh = 0.0 if int_kwh.nil?

    # Calculate exterior lighting kWh/yr
    ext_kwh = kwhs_per_year[HPXML::LocationExterior]
    if ext_kwh.nil?
      ext_kwh = calc_exterior_energy(eri_version, cfa,
                                     fractions[[HPXML::LocationExterior, HPXML::LightingTypeCFL]],
                                     fractions[[HPXML::LocationExterior, HPXML::LightingTypeLFL]],
                                     fractions[[HPXML::LocationExterior, HPXML::LightingTypeLED]],
                                     lighting.exterior_usage_multiplier)
    end
    ext_kwh = 0.0 if ext_kwh.nil?

    # Calculate garage lighting kWh/yr
    grg_kwh = kwhs_per_year[HPXML::LocationGarage]
    if grg_kwh.nil?
      gfa = 0 # Garage floor area
      if spaces.keys.include? HPXML::LocationGarage
        gfa = UnitConversions.convert(spaces[HPXML::LocationGarage].floorArea, 'm^2', 'ft^2')
      end

      grg_kwh = calc_garage_energy(eri_version, gfa,
                                   fractions[[HPXML::LocationGarage, HPXML::LightingTypeCFL]],
                                   fractions[[HPXML::LocationGarage, HPXML::LightingTypeLFL]],
                                   fractions[[HPXML::LocationGarage, HPXML::LightingTypeLED]],
                                   lighting.garage_usage_multiplier)
    end
    grg_kwh = 0.0 if grg_kwh.nil?

    # Add lighting to conditioned space
    if int_kwh > 0

      # Create schedule
      interior_sch = nil
      interior_col_name = SchedulesFile::ColumnLightingInterior
      if not schedules_file.nil?
        design_level = schedules_file.calc_design_level_from_annual_kwh(col_name: interior_col_name, annual_kwh: int_kwh)
        interior_sch = schedules_file.create_schedule_file(col_name: interior_col_name)
      end
      if interior_sch.nil?
        interior_unavailable_periods = Schedule.get_unavailable_periods(runner, interior_col_name, unavailable_periods)
        if not lighting.interior_weekday_fractions.nil?
          interior_sch = MonthWeekdayWeekendSchedule.new(model, Constants.ObjectNameInteriorLighting + ' schedule', lighting.interior_weekday_fractions, lighting.interior_weekend_fractions, lighting.interior_monthly_multipliers, Constants.ScheduleTypeLimitsFraction, unavailable_periods: interior_unavailable_periods)
        else
          lighting_sch = get_schedule(epw_file)
          interior_sch = HourlyByMonthSchedule.new(model, 'lighting schedule', lighting_sch, lighting_sch, Constants.ScheduleTypeLimitsFraction, unavailable_periods: interior_unavailable_periods)
        end

        if lighting.interior_weekday_fractions.nil?
          design_level = interior_sch.calc_design_level(interior_sch.maxval * int_kwh)
        else
          design_level = interior_sch.calc_design_level_from_daily_kwh(int_kwh / 365.0)
        end
        interior_sch = interior_sch.schedule
      else
        runner.registerWarning("Both '#{interior_col_name}' schedule file and weekday fractions provided; the latter will be ignored.") if !lighting.interior_weekday_fractions.nil?
        runner.registerWarning("Both '#{interior_col_name}' schedule file and weekend fractions provided; the latter will be ignored.") if !lighting.interior_weekend_fractions.nil?
        runner.registerWarning("Both '#{interior_col_name}' schedule file and monthly multipliers provided; the latter will be ignored.") if !lighting.interior_monthly_multipliers.nil?
      end

      # Add lighting
      ltg_def = OpenStudio::Model::LightsDefinition.new(model)
      ltg = OpenStudio::Model::Lights.new(ltg_def)
      ltg.setName(Constants.ObjectNameInteriorLighting)
      ltg.setSpace(spaces[HPXML::LocationLivingSpace])
      ltg.setEndUseSubcategory(Constants.ObjectNameInteriorLighting)
      ltg_def.setName(Constants.ObjectNameInteriorLighting)
      ltg_def.setLightingLevel(design_level)
      ltg_def.setFractionRadiant(0.6)
      ltg_def.setFractionVisible(0.2)
      ltg_def.setReturnAirFraction(0.0)
      ltg.setSchedule(interior_sch)
    end

    # Add lighting to garage space
    if grg_kwh > 0

      # Create schedule
      garage_sch = nil
      garage_col_name = SchedulesFile::ColumnLightingGarage
      if not schedules_file.nil?
        design_level = schedules_file.calc_design_level_from_annual_kwh(col_name: garage_col_name, annual_kwh: grg_kwh)
        garage_sch = schedules_file.create_schedule_file(col_name: garage_col_name)
      end
      if garage_sch.nil?
        garage_unavailable_periods = Schedule.get_unavailable_periods(runner, garage_col_name, unavailable_periods)
        garage_sch = MonthWeekdayWeekendSchedule.new(model, Constants.ObjectNameGarageLighting + ' schedule', lighting.garage_weekday_fractions, lighting.garage_weekend_fractions, lighting.garage_monthly_multipliers, Constants.ScheduleTypeLimitsFraction, unavailable_periods: garage_unavailable_periods)
        design_level = garage_sch.calc_design_level_from_daily_kwh(grg_kwh / 365.0)
        garage_sch = garage_sch.schedule
      else
        runner.registerWarning("Both '#{garage_col_name}' schedule file and weekday fractions provided; the latter will be ignored.") if !lighting.garage_weekday_fractions.nil?
        runner.registerWarning("Both '#{garage_col_name}' schedule file and weekend fractions provided; the latter will be ignored.") if !lighting.garage_weekend_fractions.nil?
        runner.registerWarning("Both '#{garage_col_name}' schedule file and monthly multipliers provided; the latter will be ignored.") if !lighting.garage_monthly_multipliers.nil?
      end

      # Add lighting
      ltg_def = OpenStudio::Model::LightsDefinition.new(model)
      ltg = OpenStudio::Model::Lights.new(ltg_def)
      ltg.setName(Constants.ObjectNameGarageLighting)
      ltg.setSpace(spaces[HPXML::LocationGarage])
      ltg.setEndUseSubcategory(Constants.ObjectNameGarageLighting)
      ltg_def.setName(Constants.ObjectNameGarageLighting)
      ltg_def.setLightingLevel(design_level)
      ltg_def.setFractionRadiant(0.6)
      ltg_def.setFractionVisible(0.2)
      ltg_def.setReturnAirFraction(0.0)
      ltg.setSchedule(garage_sch)
    end

    # Add exterior lighting
    if ext_kwh > 0

      # Create schedule
      exterior_sch = nil
      exterior_col_name = SchedulesFile::ColumnLightingExterior
      if not schedules_file.nil?
        design_level = schedules_file.calc_design_level_from_annual_kwh(col_name: exterior_col_name, annual_kwh: ext_kwh)
        exterior_sch = schedules_file.create_schedule_file(col_name: exterior_col_name)
      end
      if exterior_sch.nil?
        exterior_unavailable_periods = Schedule.get_unavailable_periods(runner, exterior_col_name, unavailable_periods)
        exterior_sch = MonthWeekdayWeekendSchedule.new(model, Constants.ObjectNameExteriorLighting + ' schedule', lighting.exterior_weekday_fractions, lighting.exterior_weekend_fractions, lighting.exterior_monthly_multipliers, Constants.ScheduleTypeLimitsFraction, unavailable_periods: exterior_unavailable_periods)
        design_level = exterior_sch.calc_design_level_from_daily_kwh(ext_kwh / 365.0)
        exterior_sch = exterior_sch.schedule
      else
        runner.registerWarning("Both '#{exterior_col_name}' schedule file and weekday fractions provided; the latter will be ignored.") if !lighting.exterior_weekday_fractions.nil?
        runner.registerWarning("Both '#{exterior_col_name}' schedule file and weekend fractions provided; the latter will be ignored.") if !lighting.exterior_weekend_fractions.nil?
        runner.registerWarning("Both '#{exterior_col_name}' schedule file and monthly multipliers provided; the latter will be ignored.") if !lighting.exterior_monthly_multipliers.nil?
      end

      # Add exterior lighting
      ltg_def = OpenStudio::Model::ExteriorLightsDefinition.new(model)
      ltg = OpenStudio::Model::ExteriorLights.new(ltg_def)
      ltg.setName(Constants.ObjectNameExteriorLighting)
      ltg.setEndUseSubcategory(Constants.ObjectNameExteriorLighting)
      ltg_def.setName(Constants.ObjectNameExteriorLighting)
      ltg_def.setDesignLevel(design_level)
      ltg.setSchedule(exterior_sch)
    end

    # Add exterior holiday lighting
    if not lighting.holiday_kwh_per_day.nil?

      # Create schedule
      exterior_holiday_sch = nil
      exterior_holiday_col_name = SchedulesFile::ColumnLightingExteriorHoliday
      if not schedules_file.nil?
        design_level = schedules_file.calc_design_level_from_daily_kwh(col_name: exterior_holiday_col_name, daily_kwh: lighting.holiday_kwh_per_day)
        exterior_holiday_sch = schedules_file.create_schedule_file(col_name: exterior_holiday_col_name)
      end
      if exterior_holiday_sch.nil?
        exterior_holiday_unavailable_periods = Schedule.get_unavailable_periods(runner, exterior_holiday_col_name, unavailable_periods)
        exterior_holiday_sch = MonthWeekdayWeekendSchedule.new(model, Constants.ObjectNameLightingExteriorHoliday + ' schedule', lighting.holiday_weekday_fractions, lighting.holiday_weekend_fractions, lighting.exterior_monthly_multipliers, Constants.ScheduleTypeLimitsFraction, true, lighting.holiday_period_begin_month, lighting.holiday_period_begin_day, lighting.holiday_period_end_month, lighting.holiday_period_end_day, unavailable_periods: exterior_holiday_unavailable_periods)
        design_level = exterior_holiday_sch.calc_design_level_from_daily_kwh(lighting.holiday_kwh_per_day)
        exterior_holiday_sch = exterior_holiday_sch.schedule
      else
        runner.registerWarning("Both '#{exterior_holiday_col_name}' schedule file and weekday fractions provided; the latter will be ignored.") if !lighting.holiday_weekday_fractions.nil?
        runner.registerWarning("Both '#{exterior_holiday_col_name}' schedule file and weekend fractions provided; the latter will be ignored.") if !lighting.holiday_weekend_fractions.nil?
        runner.registerWarning("Both '#{exterior_holiday_col_name}' schedule file and monthly multipliers provided; the latter will be ignored.") if !lighting.exterior_monthly_multipliers.nil?
      end

      # Add exterior holiday lighting
      ltg_def = OpenStudio::Model::ExteriorLightsDefinition.new(model)
      ltg = OpenStudio::Model::ExteriorLights.new(ltg_def)
      ltg.setName(Constants.ObjectNameLightingExteriorHoliday)
      ltg.setEndUseSubcategory(Constants.ObjectNameLightingExteriorHoliday)
      ltg_def.setName(Constants.ObjectNameLightingExteriorHoliday)
      ltg_def.setDesignLevel(design_level)
      ltg.setSchedule(exterior_holiday_sch)
    end
  end

  def self.get_default_fractions()
    ltg_fracs = {}
    [HPXML::LocationInterior, HPXML::LocationExterior, HPXML::LocationGarage].each do |location|
      [HPXML::LightingTypeCFL, HPXML::LightingTypeLFL, HPXML::LightingTypeLED].each do |lighting_type|
        if (location == HPXML::LocationInterior) && (lighting_type == HPXML::LightingTypeCFL)
          ltg_fracs[[location, lighting_type]] = 0.1
        else
          ltg_fracs[[location, lighting_type]] = 0
        end
      end
    end
    return ltg_fracs
  end

  private

  def self.calc_interior_energy(eri_version, cfa, f_int_cfl, f_int_lfl, f_int_led, interior_usage_multiplier = 1.0)
    return if f_int_cfl.nil? || f_int_lfl.nil? || f_int_led.nil?

    if Constants.ERIVersions.index(eri_version) >= Constants.ERIVersions.index('2014AEG')
      # Calculate fluorescent (CFL + LFL) fraction
      f_int_fl = f_int_cfl + f_int_lfl

      # Calculate incandescent fraction
      f_int_inc = 1.0 - f_int_fl - f_int_led

      # Efficacies (lm/W)
      eff_inc = 15.0
      eff_fl = 60.0
      eff_led = 90.0

      # Efficacy ratios
      eff_ratio_inc = eff_inc / eff_inc
      eff_ratio_fl = eff_inc / eff_fl
      eff_ratio_led = eff_inc / eff_led

      # Efficiency lighting adjustment
      int_adj = (f_int_inc * eff_ratio_inc) + (f_int_fl * eff_ratio_fl) + (f_int_led * eff_ratio_led)

      # Calculate energy use
      int_kwh = (0.9 / 0.925 * (455.0 + 0.8 * cfa) * int_adj) + (0.1 * (455.0 + 0.8 * cfa))
    else
      # Calculate efficient lighting fraction
      fF_int = f_int_cfl + f_int_lfl + f_int_led

      # Calculate energy use
      int_kwh = 0.8 * ((4.0 - 3.0 * fF_int) / 3.7) * (455.0 + 0.8 * cfa) + 0.2 * (455.0 + 0.8 * cfa)
    end

    int_kwh *= interior_usage_multiplier

    return int_kwh
  end

  def self.calc_exterior_energy(eri_version, cfa, f_ext_cfl, f_ext_lfl, f_ext_led, exterior_usage_multiplier = 1.0)
    return if f_ext_cfl.nil? || f_ext_lfl.nil? || f_ext_led.nil?

    if Constants.ERIVersions.index(eri_version) >= Constants.ERIVersions.index('2014AEG')
      # Calculate fluorescent (CFL + LFL) fraction
      f_ext_fl = f_ext_cfl + f_ext_lfl

      # Calculate incandescent fraction
      f_ext_inc = 1.0 - f_ext_fl - f_ext_led

      # Efficacies (lm/W)
      eff_inc = 15.0
      eff_fl = 60.0
      eff_led = 90.0

      # Efficacy ratios
      eff_ratio_inc = eff_inc / eff_inc
      eff_ratio_fl = eff_inc / eff_fl
      eff_ratio_led = eff_inc / eff_led

      # Efficiency lighting adjustment
      ext_adj = (f_ext_inc * eff_ratio_inc) + (f_ext_fl * eff_ratio_fl) + (f_ext_led * eff_ratio_led)

      # Calculate energy use
      ext_kwh = (100.0 + 0.05 * cfa) * ext_adj
    else
      # Calculate efficient lighting fraction
      fF_ext = f_ext_cfl + f_ext_lfl + f_ext_led

      # Calculate energy use
      ext_kwh = (100.0 + 0.05 * cfa) * (1.0 - fF_ext) + 0.25 * (100.0 + 0.05 * cfa) * fF_ext
    end

    ext_kwh *= exterior_usage_multiplier

    return ext_kwh
  end

  def self.calc_garage_energy(eri_version, gfa, f_grg_cfl, f_grg_lfl, f_grg_led, garage_usage_multiplier = 1.0)
    return if f_grg_cfl.nil? || f_grg_lfl.nil? || f_grg_led.nil?

    if Constants.ERIVersions.index(eri_version) >= Constants.ERIVersions.index('2014AEG')
      # Calculate fluorescent (CFL + LFL) fraction
      f_grg_fl = f_grg_cfl + f_grg_lfl

      # Calculate incandescent fraction
      f_grg_inc = 1.0 - f_grg_fl - f_grg_led

      # Efficacies (lm/W)
      eff_inc = 15.0
      eff_fl = 60.0
      eff_led = 90.0

      # Efficacy ratios
      eff_ratio_inc = eff_inc / eff_inc
      eff_ratio_fl = eff_inc / eff_fl
      eff_ratio_led = eff_inc / eff_led

      # Efficiency lighting adjustment
      grg_adj = (f_grg_inc * eff_ratio_inc) + (f_grg_fl * eff_ratio_fl) + (f_grg_led * eff_ratio_led)

      # Calculate energy use
      grg_kwh = 0.0
      if gfa > 0
        grg_kwh = 100.0 * grg_adj
      end
    else
      # Calculate efficient lighting fraction
      fF_grg = f_grg_cfl + f_grg_lfl + f_grg_led

      # Calculate energy use
      grg_kwh = 0.0
      if gfa > 0
        grg_kwh = 100.0 * (1.0 - fF_grg) + 25.0 * fF_grg
      end
    end

    grg_kwh *= garage_usage_multiplier

    return grg_kwh
  end

  def self.get_schedule(epw_file)
    # Sunrise and sunset hours
    sunrise_hour = []
    sunset_hour = []
    std_long = -epw_file.timeZone * 15
    normalized_hourly_lighting = [[1..24], [1..24], [1..24], [1..24], [1..24], [1..24], [1..24], [1..24], [1..24], [1..24], [1..24], [1..24]]
    for month in 0..11
      if epw_file.latitude < 51.49
        m_num = month + 1
        jul_day = m_num * 30 - 15
        if not ((m_num < 4) || (m_num > 10))
          offset = 1
        else
          offset = 0
        end
        declination = 23.45 * Math.sin(0.9863 * (284 + jul_day) * 0.01745329)
        deg_rad = Math::PI / 180
        rad_deg = 1 / deg_rad
        b = (jul_day - 1) * 0.9863
        equation_of_time = (0.01667 * (0.01719 + 0.42815 * Math.cos(deg_rad * b) - 7.35205 * Math.sin(deg_rad * b) - 3.34976 * Math.cos(deg_rad * (2 * b)) - 9.37199 * Math.sin(deg_rad * (2 * b))))
        sunset_hour_angle = rad_deg * Math.acos(-1 * Math.tan(deg_rad * epw_file.latitude) * Math.tan(deg_rad * declination))
        sunrise_hour[month] = offset + (12.0 - 1 * sunset_hour_angle / 15.0) - equation_of_time - (std_long + epw_file.longitude) / 15
        sunset_hour[month] = offset + (12.0 + 1 * sunset_hour_angle / 15.0) - equation_of_time - (std_long + epw_file.longitude) / 15
      else
        sunrise_hour = [8.125726064, 7.449258072, 6.388688653, 6.232405257, 5.27722936, 4.84705384, 5.127512162, 5.860163988, 6.684378904, 7.521267411, 7.390441945, 8.080667697]
        sunset_hour = [16.22214058, 17.08642353, 17.98324493, 19.83547864, 20.65149672, 21.20662992, 21.12124777, 20.37458274, 19.25834757, 18.08155615, 16.14359164, 15.75571306]
      end
    end

    june_kws = [0.060, 0.040, 0.035, 0.025, 0.020, 0.020, 0.020, 0.020, 0.020, 0.020, 0.020, 0.020, 0.020, 0.025, 0.030, 0.030, 0.025, 0.020, 0.015, 0.015, 0.015, 0.015, 0.015, 0.015, 0.015, 0.015, 0.015, 0.015, 0.015, 0.015, 0.015, 0.015, 0.020, 0.020, 0.020, 0.025, 0.025, 0.030, 0.030, 0.035, 0.045, 0.060, 0.085, 0.125, 0.145, 0.130, 0.105, 0.080]
    lighting_seasonal_multiplier =   [1.075, 1.064951905, 1.0375, 1.0, 0.9625, 0.935048095, 0.925, 0.935048095, 0.9625, 1.0, 1.0375, 1.064951905]
    amplConst1 = 0.929707907917098
    sunsetLag1 = 2.45016230615269
    stdDevCons1 = 1.58679810983444
    amplConst2 = 1.1372291802273
    sunsetLag2 = 20.1501965859073
    stdDevCons2 = 2.36567663279954

    monthly_kwh_per_day = []
    days_m = Constants.NumDaysInMonths(1999) # Intentionally excluding leap year designation
    wtd_avg_monthly_kwh_per_day = 0
    for monthNum in 1..12
      month = monthNum - 1
      monthHalfHourKWHs = [0]
      for hourNum in 0..9
        monthHalfHourKWHs[hourNum] = june_kws[hourNum]
      end
      for hourNum in 9..17
        hour = (hourNum + 1.0) * 0.5
        monthHalfHourKWHs[hourNum] = (monthHalfHourKWHs[8] - (0.15 / (2 * Math::PI)) * Math.sin((2 * Math::PI) * (hour - 4.5) / 3.5) + (0.15 / 3.5) * (hour - 4.5)) * lighting_seasonal_multiplier[month]
      end
      for hourNum in 17..29
        hour = (hourNum + 1.0) * 0.5
        monthHalfHourKWHs[hourNum] = (monthHalfHourKWHs[16] - (-0.02 / (2 * Math::PI)) * Math.sin((2 * Math::PI) * (hour - 8.5) / 5.5) + (-0.02 / 5.5) * (hour - 8.5)) * lighting_seasonal_multiplier[month]
      end
      for hourNum in 29..45
        hour = (hourNum + 1.0) * 0.5
        monthHalfHourKWHs[hourNum] = (monthHalfHourKWHs[28] + amplConst1 * Math.exp((-1.0 * (hour - (sunset_hour[month] + sunsetLag1))**2) / (2.0 * ((25.5 / ((6.5 - monthNum).abs + 20.0)) * stdDevCons1)**2)) / ((25.5 / ((6.5 - monthNum).abs + 20.0)) * stdDevCons1 * (2.0 * Math::PI)**0.5))
      end
      for hourNum in 45..46
        hour = (hourNum + 1.0) * 0.5
        temp1 = (monthHalfHourKWHs[44] + amplConst1 * Math.exp((-1.0 * (hour - (sunset_hour[month] + sunsetLag1))**2) / (2.0 * ((25.5 / ((6.5 - monthNum).abs + 20.0)) * stdDevCons1)**2)) / ((25.5 / ((6.5 - monthNum).abs + 20.0)) * stdDevCons1 * (2.0 * Math::PI)**0.5))
        temp2 = (0.04 + amplConst2 * Math.exp((-1.0 * (hour - sunsetLag2)**2) / (2.0 * stdDevCons2**2)) / (stdDevCons2 * (2.0 * Math::PI)**0.5))
        if sunsetLag2 < sunset_hour[month] + sunsetLag1
          monthHalfHourKWHs[hourNum] = [temp1, temp2].min
        else
          monthHalfHourKWHs[hourNum] = [temp1, temp2].max
        end
      end
      for hourNum in 46..47
        hour = (hourNum + 1) * 0.5
        monthHalfHourKWHs[hourNum] = (0.04 + amplConst2 * Math.exp((-1.0 * (hour - sunsetLag2)**2) / (2.0 * stdDevCons2**2)) / (stdDevCons2 * (2.0 * Math::PI)**0.5))
      end

      sum_kWh = 0.0
      for timenum in 0..47
        sum_kWh += monthHalfHourKWHs[timenum]
      end
      for hour in 0..23
        ltg_hour = (monthHalfHourKWHs[hour * 2] + monthHalfHourKWHs[hour * 2 + 1]).to_f
        normalized_hourly_lighting[month][hour] = ltg_hour / sum_kWh
        monthly_kwh_per_day[month] = sum_kWh / 2.0
      end
      wtd_avg_monthly_kwh_per_day += monthly_kwh_per_day[month] * days_m[month] / 365.0
    end

    # Calculate normalized monthly lighting fractions
    seasonal_multiplier = []
    sumproduct_seasonal_multiplier = 0
    normalized_monthly_lighting = seasonal_multiplier
    for month in 0..11
      seasonal_multiplier[month] = (monthly_kwh_per_day[month] / wtd_avg_monthly_kwh_per_day)
      sumproduct_seasonal_multiplier += seasonal_multiplier[month] * days_m[month]
    end

    for month in 0..11
      normalized_monthly_lighting[month] = seasonal_multiplier[month] * days_m[month] / sumproduct_seasonal_multiplier
    end

    # Calculate schedule values
    lighting_sch = [[], [], [], [], [], [], [], [], [], [], [], []]
    for month in 0..11
      for hour in 0..23
        lighting_sch[month][hour] = normalized_monthly_lighting[month] * normalized_hourly_lighting[month][hour] / days_m[month]
      end
    end

    return lighting_sch
  end
end
