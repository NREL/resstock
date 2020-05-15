# frozen_string_literal: true

class Location
  def self.apply(model, runner, weather_file_path, weather_cache_path, dst_start_date, dst_end_date)
    weather, epw_file = apply_weather_file(model, runner, weather_file_path, weather_cache_path)
    apply_year(model, epw_file)
    apply_site(model, epw_file)
    apply_climate_zones(model, epw_file)
    apply_dst(model, dst_start_date, dst_end_date)
    return weather
  end

  private

  def self.apply_weather_file(model, runner, weather_file_path, weather_cache_path)
    if File.exist?(weather_file_path) && weather_file_path.downcase.end_with?('.epw')
      epw_file = OpenStudio::EpwFile.new(weather_file_path)
    else
      fail "'#{weather_file_path}' does not exist or is not an .epw file."
    end

    OpenStudio::Model::WeatherFile.setWeatherFile(model, epw_file).get

    # Obtain weather object
    # Load from cache .csv file if exists, as this is faster and doesn't require
    # parsing the weather file.
    if File.exist? weather_cache_path
      weather = WeatherProcess.new(nil, nil, weather_cache_path)
    else
      weather = WeatherProcess.new(model, runner)
    end

    return weather, epw_file
  end

  def self.apply_site(model, epw_file)
    site = model.getSite
    site.setName("#{epw_file.city}_#{epw_file.stateProvinceRegion}_#{epw_file.country}")
    site.setLatitude(epw_file.latitude)
    site.setLongitude(epw_file.longitude)
    site.setTimeZone(epw_file.timeZone)
    site.setElevation(epw_file.elevation)
  end

  def self.apply_climate_zones(model, epw_file)
    ba_zone = get_climate_zone_ba(epw_file.wmoNumber)
    return if ba_zone.nil?

    climateZones = model.getClimateZones
    climateZones.setClimateZone(Constants.BuildingAmericaClimateZone, ba_zone)
  end

  def self.apply_year(model, epw_file)
    year_description = model.getYearDescription
    if epw_file.startDateActualYear.is_initialized # AMY
      year_description.setCalendarYear(epw_file.startDateActualYear.get)
    else # TMY
      year_description.setDayofWeekforStartDay('Monday') # For consistency with SAM utility bill calculations
    end
  end

  def self.apply_dst(model, dst_start_date, dst_end_date)
    if not ((dst_start_date.downcase == 'na') && (dst_end_date.downcase == 'na'))
      begin
        dst_start_date_month = OpenStudio::monthOfYear(dst_start_date.split[0])
        dst_start_date_day = dst_start_date.split[1].to_i
        dst_end_date_month = OpenStudio::monthOfYear(dst_end_date.split[0])
        dst_end_date_day = dst_end_date.split[1].to_i

        dst = model.getRunPeriodControlDaylightSavingTime
        dst.setStartDate(dst_start_date_month, dst_start_date_day)
        dst.setEndDate(dst_end_date_month, dst_end_date_day)
      rescue
        fail 'Invalid daylight saving date specified.'
      end
    end
  end

  def self.get_climate_zone_ba(wmo)
    ba_zone = nil
    zones_csv = File.join(File.dirname(__FILE__), 'climate_zones.csv')
    if not File.exist?(zones_csv)
      fail 'Could not find climate_zones.csv'
    end

    require 'csv'
    CSV.foreach(zones_csv) do |row|
      if row[0].to_s == wmo.to_s
        ba_zone = row[5].to_s
        break
      end
    end

    return ba_zone
  end
end
