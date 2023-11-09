# frozen_string_literal: true

class Location
  def self.apply(model, weather, epw_file, hpxml_header, hpxml_bldg)
    apply_year(model, hpxml_header, epw_file)
    apply_site(model, epw_file)
    apply_dst(model, hpxml_bldg)
    apply_ground_temps(model, weather, hpxml_bldg)
  end

  private

  def self.apply_site(model, epw_file)
    site = model.getSite
    site.setName("#{epw_file.city}_#{epw_file.stateProvinceRegion}_#{epw_file.country}")
    site.setLatitude(epw_file.latitude)
    site.setLongitude(epw_file.longitude)
    site.setTimeZone(epw_file.timeZone)
    site.setElevation(epw_file.elevation)
  end

  def self.apply_year(model, hpxml_header, epw_file)
    if Date.leap?(hpxml_header.sim_calendar_year)
      n_hours = epw_file.data.size
      if n_hours != 8784
        fail "Specified a leap year (#{hpxml_header.sim_calendar_year}) but weather data has #{n_hours} hours."
      end
    end

    year_description = model.getYearDescription
    year_description.setCalendarYear(hpxml_header.sim_calendar_year)
  end

  def self.apply_dst(model, hpxml_bldg)
    return unless hpxml_bldg.dst_enabled

    month_names = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
    dst_start_date = "#{month_names[hpxml_bldg.dst_begin_month - 1]} #{hpxml_bldg.dst_begin_day}"
    dst_end_date = "#{month_names[hpxml_bldg.dst_end_month - 1]} #{hpxml_bldg.dst_end_day}"

    run_period_control_daylight_saving_time = model.getRunPeriodControlDaylightSavingTime
    run_period_control_daylight_saving_time.setStartDate(dst_start_date)
    run_period_control_daylight_saving_time.setEndDate(dst_end_date)
  end

  def self.apply_ground_temps(model, weather, hpxml_bldg)
    # Shallow ground temperatures only currently used for ducts located under slab
    sgts = model.getSiteGroundTemperatureShallow
    sgts.resetAllMonths
    sgts.setAllMonthlyTemperatures(weather.data.ShallowGroundMonthlyTemps.map { |t| UnitConversions.convert(t, 'F', 'C') })

    if hpxml_bldg.heat_pumps.select { |h| h.heat_pump_type == HPXML::HVACTypeHeatPumpGroundToAir }.size > 0
      # Deep ground temperatures used by GSHP setpoint manager
      dgts = model.getSiteGroundTemperatureDeep
      dgts.resetAllMonths
      dgts.setAllMonthlyTemperatures([UnitConversions.convert(weather.data.DeepGroundAnnualTemp, 'F', 'C')] * 12)
    end
  end

  def self.get_climate_zones
    zones_csv = File.join(File.dirname(__FILE__), 'data', 'climate_zones.csv')
    if not File.exist?(zones_csv)
      fail 'Could not find climate_zones.csv'
    end

    return zones_csv
  end

  def self.get_climate_zone_iecc(wmo)
    zones_csv = get_climate_zones

    require 'csv'
    CSV.foreach(zones_csv) do |row|
      return row[6].to_s if row[0].to_s == wmo.to_s
    end

    return
  end

  def self.get_epw_path(hpxml_bldg, hpxml_path)
    epw_filepath = hpxml_bldg.climate_and_risk_zones.weather_station_epw_filepath
    abs_epw_path = File.absolute_path(epw_filepath)

    if not File.exist? abs_epw_path
      # Check path relative to HPXML file
      abs_epw_path = File.absolute_path(File.join(File.dirname(hpxml_path), epw_filepath))
    end
    if not File.exist? abs_epw_path
      # Check for weather path relative to the HPXML file
      for level_deep in 1..3
        level = (['..'] * level_deep).join('/')
        abs_epw_path = File.absolute_path(File.join(File.dirname(hpxml_path), level, 'weather', epw_filepath))
        break if File.exist? abs_epw_path
      end
    end
    if not File.exist? abs_epw_path
      # Check for weather path relative to this file
      for level_deep in 1..3
        level = (['..'] * level_deep).join('/')
        abs_epw_path = File.absolute_path(File.join(File.dirname(__FILE__), level, 'weather', epw_filepath))
        break if File.exist? abs_epw_path
      end
    end
    if not File.exist? abs_epw_path
      fail "'#{epw_filepath}' could not be found."
    end

    return abs_epw_path
  end

  def self.get_sim_calendar_year(sim_calendar_year, epw_file)
    if (not epw_file.nil?) && epw_file.startDateActualYear.is_initialized # AMY
      sim_calendar_year = epw_file.startDateActualYear.get
    end
    if sim_calendar_year.nil?
      sim_calendar_year = 2007 # For consistency with SAM utility bill calculations
    end
    return sim_calendar_year
  end
end
