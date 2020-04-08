class Location
  def self.get_climate_zones
    zones_csv = File.join(File.dirname(__FILE__), '../../HPXMLtoOpenStudio/resources/climate_zones.csv')
    if not File.exist?(zones_csv)
      return
    end

    return zones_csv
  end

  def self.get_climate_zone_iecc(wmo)
    zones_csv = get_climate_zones
    return if zones_csv.nil?

    require 'csv'
    CSV.foreach(zones_csv) do |row|
      return row[6].to_s if row[0].to_s == wmo.to_s
    end

    return
  end
end
