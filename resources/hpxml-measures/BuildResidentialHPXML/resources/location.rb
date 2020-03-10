class Location
  def self.get_climate_zones
    zones_csv = File.join(File.dirname(__FILE__), "climate_zones.csv")
    if not File.exists?(zones_csv)
      return nil
    end

    return zones_csv
  end

  def self.get_climate_zone_iecc(wmo)
    zones_csv = get_climate_zones
    return nil if zones_csv.nil?

    require "csv"
    CSV.foreach(zones_csv) do |row|
      return row[6].to_s if row[0].to_s == wmo.to_s
    end

    return nil
  end
end
