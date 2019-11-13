require_relative 'xmlhelper'

class HPXML
  def self.create_hpxml(xml_type:,
                        xml_generated_by:,
                        transaction:,
                        software_program_used: nil,
                        software_program_version: nil,
                        eri_calculation_version:,
                        building_id:,
                        event_type:,
                        **remainder)
    doc = XMLHelper.create_doc(version = "1.0", encoding = "UTF-8")
    hpxml = XMLHelper.add_element(doc, "HPXML")
    XMLHelper.add_attribute(hpxml, "xmlns", "http://hpxmlonline.com/2019/10")
    XMLHelper.add_attribute(hpxml, "xmlns:xsi", "http://www.w3.org/2001/XMLSchema-instance")
    XMLHelper.add_attribute(hpxml, "xsi:schemaLocation", "http://hpxmlonline.com/2019/10")
    XMLHelper.add_attribute(hpxml, "schemaVersion", "3.0")

    header = XMLHelper.add_element(hpxml, "XMLTransactionHeaderInformation")
    XMLHelper.add_element(header, "XMLType", xml_type)
    XMLHelper.add_element(header, "XMLGeneratedBy", xml_generated_by)
    XMLHelper.add_element(header, "CreatedDateAndTime", Time.now.strftime("%Y-%m-%dT%H:%M:%S%:z"))
    XMLHelper.add_element(header, "Transaction", transaction)

    software_info = XMLHelper.add_element(hpxml, "SoftwareInfo")
    XMLHelper.add_element(software_info, "SoftwareProgramUsed", software_program_used) unless software_program_used.nil?
    XMLHelper.add_element(software_info, "SoftwareProgramVersion", software_program_version) unless software_program_version.nil?
    eri_calculation = XMLHelper.add_element(software_info, "extension/ERICalculation")
    XMLHelper.add_element(eri_calculation, "Version", eri_calculation_version)

    building = XMLHelper.add_element(hpxml, "Building")
    building_building_id = XMLHelper.add_element(building, "BuildingID")
    XMLHelper.add_attribute(building_building_id, "id", building_id)
    project_status = XMLHelper.add_element(building, "ProjectStatus")
    XMLHelper.add_element(project_status, "EventType", event_type)

    return doc
  end

  def self.get_hpxml_values(hpxml:)
    return nil if hpxml.nil?

    return { :schema_version => hpxml.attributes["schemaVersion"],
             :xml_type => XMLHelper.get_value(hpxml, "XMLTransactionHeaderInformation/XMLType"),
             :xml_generated_by => XMLHelper.get_value(hpxml, "XMLTransactionHeaderInformation/XMLGeneratedBy"),
             :created_date_and_time => XMLHelper.get_value(hpxml, "XMLTransactionHeaderInformation/CreatedDateAndTime"),
             :transaction => XMLHelper.get_value(hpxml, "XMLTransactionHeaderInformation/Transaction"),
             :software_program_used => XMLHelper.get_value(hpxml, "SoftwareInfo/SoftwareProgramUsed"),
             :software_program_version => XMLHelper.get_value(hpxml, "SoftwareInfo/SoftwareProgramVersion"),
             :eri_calculation_version => XMLHelper.get_value(hpxml, "SoftwareInfo/extension/ERICalculation/Version"),
             :building_id => HPXML.get_id(hpxml, "Building/BuildingID"),
             :event_type => XMLHelper.get_value(hpxml, "Building/ProjectStatus/EventType") }
  end

  def self.add_site(hpxml:,
                    fuels: [],
                    shelter_coefficient: nil,
                    disable_natural_ventilation: nil,
                    **remainder)
    site = XMLHelper.create_elements_as_needed(hpxml, ["Building", "BuildingDetails", "BuildingSummary", "Site"])
    unless fuels.empty?
      fuel_types_available = XMLHelper.add_element(site, "FuelTypesAvailable")
      fuels.each do |fuel|
        XMLHelper.add_element(fuel_types_available, "Fuel", fuel)
      end
    end
    HPXML.add_extension(parent: site,
                        extensions: { "ShelterCoefficient": to_float_or_nil(shelter_coefficient),
                                      "DisableNaturalVentilation": to_bool_or_nil(disable_natural_ventilation) })

    return site
  end

  def self.get_site_values(site:)
    return nil if site.nil?

    return { :surroundings => XMLHelper.get_value(site, "Surroundings"),
             :orientation_of_front_of_home => XMLHelper.get_value(site, "OrientationOfFrontOfHome"),
             :fuels => XMLHelper.get_values(site, "FuelTypesAvailable/Fuel"),
             :shelter_coefficient => to_float_or_nil(XMLHelper.get_value(site, "extension/ShelterCoefficient")),
             :disable_natural_ventilation => to_bool_or_nil(XMLHelper.get_value(site, "extension/DisableNaturalVentilation")) }
  end

  def self.add_site_neighbor(hpxml:,
                             azimuth:,
                             distance:,
                             height: nil,
                             **remainder)
    neighbors = XMLHelper.create_elements_as_needed(hpxml, ["Building", "BuildingDetails", "BuildingSummary", "Site", "extension", "Neighbors"])
    neighbor_building = XMLHelper.add_element(neighbors, "NeighborBuilding")
    XMLHelper.add_element(neighbor_building, "Azimuth", Integer(azimuth))
    XMLHelper.add_element(neighbor_building, "Distance", Float(distance))
    XMLHelper.add_element(neighbor_building, "Height", Float(height)) unless height.nil?

    return neighbor_building
  end

  def self.get_neighbor_building_values(neighbor_building:)
    return nil if neighbor_building.nil?

    return { :azimuth => to_integer_or_nil(XMLHelper.get_value(neighbor_building, "Azimuth")),
             :distance => to_float_or_nil(XMLHelper.get_value(neighbor_building, "Distance")),
             :height => to_float_or_nil(XMLHelper.get_value(neighbor_building, "Height")) }
  end

  def self.add_building_occupancy(hpxml:,
                                  number_of_residents: nil,
                                  **remainder)
    building_occupancy = XMLHelper.create_elements_as_needed(hpxml, ["Building", "BuildingDetails", "BuildingSummary", "BuildingOccupancy"])
    XMLHelper.add_element(building_occupancy, "NumberofResidents", Float(number_of_residents)) unless number_of_residents.nil?

    return building_occupancy
  end

  def self.get_building_occupancy_values(building_occupancy:)
    return nil if building_occupancy.nil?

    return { :number_of_residents => to_float_or_nil(XMLHelper.get_value(building_occupancy, "NumberofResidents")) }
  end

  def self.add_building_construction(hpxml:,
                                     number_of_conditioned_floors:,
                                     number_of_conditioned_floors_above_grade:,
                                     number_of_bedrooms:,
                                     number_of_bathrooms: nil,
                                     conditioned_floor_area:,
                                     conditioned_building_volume:,
                                     use_only_ideal_air_system: nil,
                                     **remainder)
    building_construction = XMLHelper.create_elements_as_needed(hpxml, ["Building", "BuildingDetails", "BuildingSummary", "BuildingConstruction"])
    XMLHelper.add_element(building_construction, "NumberofConditionedFloors", Integer(number_of_conditioned_floors))
    XMLHelper.add_element(building_construction, "NumberofConditionedFloorsAboveGrade", Integer(number_of_conditioned_floors_above_grade))
    XMLHelper.add_element(building_construction, "NumberofBedrooms", Integer(number_of_bedrooms))
    XMLHelper.add_element(building_construction, "NumberofBathrooms", Integer(number_of_bathrooms)) unless number_of_bathrooms.nil?
    XMLHelper.add_element(building_construction, "ConditionedFloorArea", Float(conditioned_floor_area))
    XMLHelper.add_element(building_construction, "ConditionedBuildingVolume", Float(conditioned_building_volume))
    HPXML.add_extension(parent: building_construction,
                        extensions: { "UseOnlyIdealAirSystem": to_bool_or_nil(use_only_ideal_air_system) })

    return building_construction
  end

  def self.get_building_construction_values(building_construction:)
    return nil if building_construction.nil?

    return { :year_built => to_integer_or_nil(XMLHelper.get_value(building_construction, "YearBuilt")),
             :number_of_conditioned_floors => to_integer_or_nil(XMLHelper.get_value(building_construction, "NumberofConditionedFloors")),
             :number_of_conditioned_floors_above_grade => to_integer_or_nil(XMLHelper.get_value(building_construction, "NumberofConditionedFloorsAboveGrade")),
             :average_ceiling_height => to_float_or_nil(XMLHelper.get_value(building_construction, "AverageCeilingHeight")),
             :number_of_bedrooms => to_integer_or_nil(XMLHelper.get_value(building_construction, "NumberofBedrooms")),
             :number_of_bathrooms => to_integer_or_nil(XMLHelper.get_value(building_construction, "NumberofBathrooms")),
             :conditioned_floor_area => to_float_or_nil(XMLHelper.get_value(building_construction, "ConditionedFloorArea")),
             :conditioned_building_volume => to_float_or_nil(XMLHelper.get_value(building_construction, "ConditionedBuildingVolume")),
             :use_only_ideal_air_system => to_bool_or_nil(XMLHelper.get_value(building_construction, "extension/UseOnlyIdealAirSystem")),
             :residential_facility_type => XMLHelper.get_value(building_construction, "ResidentialFacilityType") }
  end

  def self.add_climate_and_risk_zones(hpxml:,
                                      iecc2003: nil,
                                      iecc2006: nil,
                                      iecc2009: nil,
                                      iecc2012: nil,
                                      iecc2015: nil,
                                      iecc2018: nil,
                                      weather_station_id:,
                                      weather_station_name:,
                                      weather_station_wmo:,
                                      **remainder)
    climate_and_risk_zones = XMLHelper.create_elements_as_needed(hpxml, ["Building", "BuildingDetails", "ClimateandRiskZones"])

    climate_zones = { 2003 => iecc2003,
                      2006 => iecc2006,
                      2009 => iecc2009,
                      2012 => iecc2012,
                      2015 => iecc2015,
                      2018 => iecc2018 }
    climate_zones.each do |year, zone|
      next if zone.nil?

      climate_zone_iecc = XMLHelper.add_element(climate_and_risk_zones, "ClimateZoneIECC")
      XMLHelper.add_element(climate_zone_iecc, "Year", Integer(year)) unless year.nil?
      XMLHelper.add_element(climate_zone_iecc, "ClimateZone", zone) unless zone.nil?
    end

    weather_station = XMLHelper.add_element(climate_and_risk_zones, "WeatherStation")
    sys_id = XMLHelper.add_element(weather_station, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", weather_station_id)
    XMLHelper.add_element(weather_station, "Name", weather_station_name)
    XMLHelper.add_element(weather_station, "WMO", weather_station_wmo)

    return climate_and_risk_zones
  end

  def self.get_climate_and_risk_zones_values(climate_and_risk_zones:)
    return nil if climate_and_risk_zones.nil?

    weather_station = climate_and_risk_zones.elements["WeatherStation"]

    return { :iecc2003 => XMLHelper.get_value(climate_and_risk_zones, "ClimateZoneIECC[Year=2003]/ClimateZone"),
             :iecc2006 => XMLHelper.get_value(climate_and_risk_zones, "ClimateZoneIECC[Year=2006]/ClimateZone"),
             :iecc2009 => XMLHelper.get_value(climate_and_risk_zones, "ClimateZoneIECC[Year=2009]/ClimateZone"),
             :iecc2012 => XMLHelper.get_value(climate_and_risk_zones, "ClimateZoneIECC[Year=2012]/ClimateZone"),
             :iecc2015 => XMLHelper.get_value(climate_and_risk_zones, "ClimateZoneIECC[Year=2015]/ClimateZone"),
             :iecc2018 => XMLHelper.get_value(climate_and_risk_zones, "ClimateZoneIECC[Year=2018]/ClimateZone"),
             :weather_station_id => HPXML.get_id(weather_station),
             :weather_station_name => XMLHelper.get_value(weather_station, "Name"),
             :weather_station_wmo => XMLHelper.get_value(weather_station, "WMO") }
  end

  def self.collapse_enclosure(enclosure)
    # Collapses like surfaces into a single surface with, e.g., aggregate surface area.
    # This can significantly speed up performance for HPXML files with lots of individual
    # surfaces (e.g., windows).

    surf_types = ['Roof',
                  'Wall',
                  'RimJoist',
                  'FoundationWall',
                  'FrameFloor',
                  'Slab',
                  'Window',
                  'Skylight',
                  'Door']

    keys_to_ignore = [:id,
                      :insulation_id,
                      :perimeter_insulation_id,
                      :under_slab_insulation_id,
                      :area,
                      :exposed_perimeter]

    # Populate surf_type_values
    surf_type_values = {} # Surface values (hashes)
    surfs = {} # Surface objects
    surf_types.each do |surf_type|
      surf_type_values[surf_type] = []
      enclosure.elements.each("#{surf_type}s/#{surf_type}") do |surf|
        if surf_type == 'Roof'
          surf_type_values[surf_type] << HPXML.get_roof_values(roof: surf)
        elsif surf_type == 'Wall'
          surf_type_values[surf_type] << HPXML.get_wall_values(wall: surf)
        elsif surf_type == 'RimJoist'
          surf_type_values[surf_type] << HPXML.get_rim_joist_values(rim_joist: surf)
        elsif surf_type == 'FoundationWall'
          surf_type_values[surf_type] << HPXML.get_foundation_wall_values(foundation_wall: surf)
        elsif surf_type == 'FrameFloor'
          surf_type_values[surf_type] << HPXML.get_framefloor_values(framefloor: surf)
        elsif surf_type == 'Slab'
          surf_type_values[surf_type] << HPXML.get_slab_values(slab: surf)
        elsif surf_type == 'Window'
          surf_type_values[surf_type] << HPXML.get_window_values(window: surf)
        elsif surf_type == 'Skylight'
          surf_type_values[surf_type] << HPXML.get_skylight_values(skylight: surf)
        elsif surf_type == 'Door'
          surf_type_values[surf_type] << HPXML.get_door_values(door: surf)
        end

        surfs[surf_type_values[surf_type][-1][:id]] = surf
      end
    end

    # Look for pairs of surfaces that can be collapsed
    area_adjustments = {}
    exposed_perimeter_adjustments = {}
    surf_types.each do |surf_type|
      for i in 0..surf_type_values[surf_type].size - 1
        surf_values = surf_type_values[surf_type][i]
        next if surf_values.nil?

        area_adjustments[surf_values[:id]] = 0
        exposed_perimeter_adjustments[surf_values[:id]] = 0

        for j in (surf_type_values[surf_type].size - 1).downto(i + 1)
          surf_values2 = surf_type_values[surf_type][j]
          next if surf_values2.nil?
          next unless surf_values.keys.sort == surf_values2.keys.sort

          match = true
          surf_values.keys.each do |key|
            next if keys_to_ignore.include? key
            next if surf_type == 'FoundationWall' and key == :azimuth # Azimuth of foundation walls is irrelevant
            next if surf_values[key] == surf_values2[key]

            match = false
          end
          next unless match

          # Update Area/ExposedPerimeter
          area_adjustments[surf_values[:id]] += surf_values2[:area]
          if not surf_values[:exposed_perimeter].nil?
            exposed_perimeter_adjustments[surf_values[:id]] += surf_values2[:exposed_perimeter]
          end

          # Update subsurface idrefs as appropriate
          if ['Wall', 'FoundationWall'].include? surf_type
            ['Window', 'Door'].each do |subsurf_type|
              surf_type_values[subsurf_type].each do |subsurf_values|
                subsurf = surfs[subsurf_values[:id]]
                next unless subsurf_values[:wall_idref] == surf_values2[:id]

                subsurf_values[:wall_idref] = surf_values[:id]
                subsurf.elements["AttachedToWall"].attributes["idref"] = surf_values[:id]
              end
            end
          elsif ['Roof'].include? surf_type
            ['Skylight'].each do |subsurf_type|
              surf_type_values[subsurf_type].each do |subsurf_values|
                subsurf = surfs[subsurf_values[:id]]
                next unless subsurf_values[:roof_idref] == surf_values2[:id]

                subsurf_values[:roof_idref] = surf_values[:id]
                subsurf.elements["AttachedToRoof"].attributes["idref"] = surf_values[:id]
              end
            end
          end

          # Remove old surface
          surf2 = surfs[surf_values2[:id]]
          surf2.parent.elements.delete surf2
          surf_type_values[surf_type].delete_at(j)
        end
      end
    end

    area_adjustments.each do |surf_id, area_adjustment|
      next unless area_adjustment > 0

      surf = surfs[surf_id]
      surf.elements["Area"].text = Float(surf.elements["Area"].text) + area_adjustment
    end
    exposed_perimeter_adjustments.each do |surf_id, exposed_perimeter_adjustment|
      next unless exposed_perimeter_adjustment > 0

      surf = surfs[surf_id]
      surf.elements["ExposedPerimeter"].text = Float(surf.elements["ExposedPerimeter"].text) + exposed_perimeter_adjustment
    end

    return true
  end

  def self.add_air_infiltration_measurement(hpxml:,
                                            id:,
                                            house_pressure: nil,
                                            unit_of_measure: nil,
                                            air_leakage: nil,
                                            effective_leakage_area: nil,
                                            constant_ach_natural: nil,
                                            infiltration_volume: nil,
                                            **remainder)
    air_infiltration = XMLHelper.create_elements_as_needed(hpxml, ["Building", "BuildingDetails", "Enclosure", "AirInfiltration"])
    air_infiltration_measurement = XMLHelper.add_element(air_infiltration, "AirInfiltrationMeasurement")
    sys_id = XMLHelper.add_element(air_infiltration_measurement, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", id)
    XMLHelper.add_element(air_infiltration_measurement, "HousePressure", Float(house_pressure)) unless house_pressure.nil?
    if not unit_of_measure.nil? and not air_leakage.nil?
      building_air_leakage = XMLHelper.add_element(air_infiltration_measurement, "BuildingAirLeakage")
      XMLHelper.add_element(building_air_leakage, "UnitofMeasure", unit_of_measure)
      XMLHelper.add_element(building_air_leakage, "AirLeakage", Float(air_leakage))
    end
    XMLHelper.add_element(air_infiltration_measurement, "EffectiveLeakageArea", Float(effective_leakage_area)) unless effective_leakage_area.nil?
    XMLHelper.add_element(air_infiltration_measurement, "InfiltrationVolume", Float(infiltration_volume)) unless infiltration_volume.nil?
    HPXML.add_extension(parent: air_infiltration_measurement,
                        extensions: { "ConstantACHnatural": to_float_or_nil(constant_ach_natural) })

    return air_infiltration_measurement
  end

  def self.get_air_infiltration_measurement_values(air_infiltration_measurement:)
    return nil if air_infiltration_measurement.nil?

    return { :id => HPXML.get_id(air_infiltration_measurement),
             :house_pressure => to_float_or_nil(XMLHelper.get_value(air_infiltration_measurement, "HousePressure")),
             :unit_of_measure => XMLHelper.get_value(air_infiltration_measurement, "BuildingAirLeakage/UnitofMeasure"),
             :air_leakage => to_float_or_nil(XMLHelper.get_value(air_infiltration_measurement, "BuildingAirLeakage/AirLeakage")),
             :effective_leakage_area => to_float_or_nil(XMLHelper.get_value(air_infiltration_measurement, "EffectiveLeakageArea")),
             :infiltration_volume => to_float_or_nil(XMLHelper.get_value(air_infiltration_measurement, "InfiltrationVolume")),
             :constant_ach_natural => to_float_or_nil(XMLHelper.get_value(air_infiltration_measurement, "extension/ConstantACHnatural")),
             :leakiness_description => XMLHelper.get_value(air_infiltration_measurement, "LeakinessDescription") }
  end

  def self.add_attic(hpxml:,
                     id:,
                     attic_type:,
                     vented_attic_sla: nil,
                     vented_attic_constant_ach: nil,
                     **remainder)
    attics = XMLHelper.create_elements_as_needed(hpxml, ["Building", "BuildingDetails", "Enclosure", "Attics"])
    attic = XMLHelper.add_element(attics, "Attic")
    sys_id = XMLHelper.add_element(attic, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", id)
    unless attic_type.nil?
      attic_type_e = XMLHelper.add_element(attic, "AtticType")
      if attic_type == "UnventedAttic"
        attic_type_attic = XMLHelper.add_element(attic_type_e, "Attic")
        XMLHelper.add_element(attic_type_attic, "Vented", false)
      elsif attic_type == "VentedAttic"
        attic_type_attic = XMLHelper.add_element(attic_type_e, "Attic")
        XMLHelper.add_element(attic_type_attic, "Vented", true)
        if not vented_attic_sla.nil?
          ventilation_rate = XMLHelper.add_element(attic, "VentilationRate")
          XMLHelper.add_element(ventilation_rate, "UnitofMeasure", "SLA")
          XMLHelper.add_element(ventilation_rate, "Value", Float(vented_attic_sla))
        elsif not vented_attic_constant_ach.nil?
          XMLHelper.add_element(attic, "extension/ConstantACHnatural", Float(vented_attic_constant_ach))
        end
      elsif attic_type == "FlatRoof" or attic_type == "CathedralCeiling"
        XMLHelper.add_element(attic_type_e, attic_type)
      else
        fail "Unhandled attic type '#{attic_type}'."
      end
    end

    return attic
  end

  def self.get_attic_values(attic:)
    return nil if attic.nil?

    attic_type = nil
    vented_attic_sla = nil
    vented_attic_constant_ach = nil
    if XMLHelper.has_element(attic, "AtticType/Attic[Vented='false']")
      attic_type = "UnventedAttic"
    elsif XMLHelper.has_element(attic, "AtticType/Attic[Vented='true']")
      attic_type = "VentedAttic"
      vented_attic_sla = to_float_or_nil(XMLHelper.get_value(attic, "VentilationRate[UnitofMeasure='SLA']/Value"))
      vented_attic_constant_ach = to_float_or_nil(XMLHelper.get_value(attic, "extension/ConstantACHnatural"))
    elsif XMLHelper.has_element(attic, "AtticType/Attic[Conditioned='true']")
      attic_type = "ConditionedAttic"
    elsif XMLHelper.has_element(attic, "AtticType/FlatRoof")
      attic_type = "FlatRoof"
    elsif XMLHelper.has_element(attic, "AtticType/CathedralCeiling")
      attic_type = "CathedralCeiling"
    end

    return { :id => HPXML.get_id(attic),
             :attic_type => attic_type,
             :vented_attic_sla => vented_attic_sla,
             :vented_attic_constant_ach => vented_attic_constant_ach }
  end

  def self.add_foundation(hpxml:,
                          id:,
                          foundation_type:,
                          vented_crawlspace_sla: nil,
                          **remainder)
    foundations = XMLHelper.create_elements_as_needed(hpxml, ["Building", "BuildingDetails", "Enclosure", "Foundations"])
    foundation = XMLHelper.add_element(foundations, "Foundation")
    sys_id = XMLHelper.add_element(foundation, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", id)
    unless foundation_type.nil?
      foundation_type_e = XMLHelper.add_element(foundation, "FoundationType")
      if ["SlabOnGrade", "Ambient"].include? foundation_type
        XMLHelper.add_element(foundation_type_e, foundation_type)
      elsif foundation_type == "ConditionedBasement"
        basement = XMLHelper.add_element(foundation_type_e, "Basement")
        XMLHelper.add_element(basement, "Conditioned", true)
      elsif foundation_type == "UnconditionedBasement"
        basement = XMLHelper.add_element(foundation_type_e, "Basement")
        XMLHelper.add_element(basement, "Conditioned", false)
      elsif foundation_type == "VentedCrawlspace"
        crawlspace = XMLHelper.add_element(foundation_type_e, "Crawlspace")
        XMLHelper.add_element(crawlspace, "Vented", true)
        if not vented_crawlspace_sla.nil?
          ventilation_rate = XMLHelper.add_element(foundation, "VentilationRate")
          XMLHelper.add_element(ventilation_rate, "UnitofMeasure", "SLA")
          XMLHelper.add_element(ventilation_rate, "Value", Float(vented_crawlspace_sla))
        end
      elsif foundation_type == "UnventedCrawlspace"
        crawlspace = XMLHelper.add_element(foundation_type_e, "Crawlspace")
        XMLHelper.add_element(crawlspace, "Vented", false)
      else
        fail "Unhandled foundation type '#{foundation_type}'."
      end
    end

    return foundation
  end

  def self.get_foundation_values(foundation:)
    return nil if foundation.nil?

    foundation_type = nil
    vented_crawlspace_sla = nil
    if XMLHelper.has_element(foundation, "FoundationType/SlabOnGrade")
      foundation_type = "SlabOnGrade"
    elsif XMLHelper.has_element(foundation, "FoundationType/Basement[Conditioned='false']")
      foundation_type = "UnconditionedBasement"
    elsif XMLHelper.has_element(foundation, "FoundationType/Basement[Conditioned='true']")
      foundation_type = "ConditionedBasement"
    elsif XMLHelper.has_element(foundation, "FoundationType/Crawlspace[Vented='false']")
      foundation_type = "UnventedCrawlspace"
    elsif XMLHelper.has_element(foundation, "FoundationType/Crawlspace[Vented='true']")
      foundation_type = "VentedCrawlspace"
      vented_crawlspace_sla = to_float_or_nil(XMLHelper.get_value(foundation, "VentilationRate[UnitofMeasure='SLA']/Value"))
    elsif XMLHelper.has_element(foundation, "FoundationType/Ambient")
      foundation_type = "Ambient"
    end

    return { :id => HPXML.get_id(foundation),
             :foundation_type => foundation_type,
             :vented_crawlspace_sla => vented_crawlspace_sla }
  end

  def self.add_roof(hpxml:,
                    id:,
                    interior_adjacent_to:,
                    area:,
                    azimuth: nil,
                    solar_absorptance:,
                    emittance:,
                    pitch:,
                    radiant_barrier:,
                    insulation_id: nil,
                    insulation_assembly_r_value:,
                    **remainder)
    roofs = XMLHelper.create_elements_as_needed(hpxml, ["Building", "BuildingDetails", "Enclosure", "Roofs"])
    roof = XMLHelper.add_element(roofs, "Roof")
    sys_id = XMLHelper.add_element(roof, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", id)
    XMLHelper.add_element(roof, "InteriorAdjacentTo", interior_adjacent_to)
    XMLHelper.add_element(roof, "Area", Float(area))
    XMLHelper.add_element(roof, "Azimuth", Integer(azimuth)) unless azimuth.nil?
    XMLHelper.add_element(roof, "SolarAbsorptance", Float(solar_absorptance))
    XMLHelper.add_element(roof, "Emittance", Float(emittance))
    XMLHelper.add_element(roof, "Pitch", Float(pitch))
    XMLHelper.add_element(roof, "RadiantBarrier", Boolean(radiant_barrier))
    add_assembly_insulation(parent: roof,
                            id: insulation_id,
                            assembly_r_value: Float(insulation_assembly_r_value))

    return roof
  end

  def self.get_roof_values(roof:)
    return nil if roof.nil?

    insulation_values = get_assembly_insulation_values(insulation: roof.elements["Insulation"])
    insulation_layer_values = get_layer_insulation_values(insulation: roof.elements["Insulation"])

    return { :id => HPXML.get_id(roof),
             :exterior_adjacent_to => "outside",
             :interior_adjacent_to => XMLHelper.get_value(roof, "InteriorAdjacentTo"),
             :area => to_float_or_nil(XMLHelper.get_value(roof, "Area")),
             :azimuth => to_integer_or_nil(XMLHelper.get_value(roof, "Azimuth")),
             :roof_type => XMLHelper.get_value(roof, "RoofType"),
             :roof_color => XMLHelper.get_value(roof, "RoofColor"),
             :solar_absorptance => to_float_or_nil(XMLHelper.get_value(roof, "SolarAbsorptance")),
             :emittance => to_float_or_nil(XMLHelper.get_value(roof, "Emittance")),
             :pitch => to_float_or_nil(XMLHelper.get_value(roof, "Pitch")),
             :radiant_barrier => to_bool_or_nil(XMLHelper.get_value(roof, "RadiantBarrier")),
             :insulation_id => insulation_values[:id],
             :insulation_assembly_r_value => to_float_or_nil(insulation_values[:assembly_r_value]),
             :insulation_cavity_r_value => to_float_or_nil(insulation_layer_values[:cavity_nominal_r_value]),
             :insulation_continuous_r_value => to_float_or_nil(insulation_layer_values[:continuous_nominal_r_value]) }
  end

  def self.add_rim_joist(hpxml:,
                         id:,
                         exterior_adjacent_to:,
                         interior_adjacent_to:,
                         area:,
                         azimuth: nil,
                         solar_absorptance:,
                         emittance:,
                         insulation_id: nil,
                         insulation_assembly_r_value:,
                         **remainder)
    rim_joists = XMLHelper.create_elements_as_needed(hpxml, ["Building", "BuildingDetails", "Enclosure", "RimJoists"])
    rim_joist = XMLHelper.add_element(rim_joists, "RimJoist")
    sys_id = XMLHelper.add_element(rim_joist, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", id)
    XMLHelper.add_element(rim_joist, "ExteriorAdjacentTo", exterior_adjacent_to)
    XMLHelper.add_element(rim_joist, "InteriorAdjacentTo", interior_adjacent_to)
    XMLHelper.add_element(rim_joist, "Area", Float(area))
    XMLHelper.add_element(rim_joist, "Azimuth", Integer(azimuth)) unless azimuth.nil?
    XMLHelper.add_element(rim_joist, "SolarAbsorptance", Float(solar_absorptance))
    XMLHelper.add_element(rim_joist, "Emittance", Float(emittance))
    add_assembly_insulation(parent: rim_joist,
                            id: insulation_id,
                            assembly_r_value: Float(insulation_assembly_r_value))

    return rim_joist
  end

  def self.get_rim_joist_values(rim_joist:)
    return nil if rim_joist.nil?

    insulation_values = get_assembly_insulation_values(insulation: rim_joist.elements["Insulation"])

    return { :id => HPXML.get_id(rim_joist),
             :exterior_adjacent_to => XMLHelper.get_value(rim_joist, "ExteriorAdjacentTo"),
             :interior_adjacent_to => XMLHelper.get_value(rim_joist, "InteriorAdjacentTo"),
             :area => to_float_or_nil(XMLHelper.get_value(rim_joist, "Area")),
             :azimuth => to_integer_or_nil(XMLHelper.get_value(rim_joist, "Azimuth")),
             :solar_absorptance => to_float_or_nil(XMLHelper.get_value(rim_joist, "SolarAbsorptance")),
             :emittance => to_float_or_nil(XMLHelper.get_value(rim_joist, "Emittance")),
             :insulation_id => insulation_values[:id],
             :insulation_assembly_r_value => to_float_or_nil(insulation_values[:assembly_r_value]) }
  end

  def self.add_wall(hpxml:,
                    id:,
                    exterior_adjacent_to:,
                    interior_adjacent_to:,
                    wall_type:,
                    area:,
                    azimuth: nil,
                    solar_absorptance:,
                    emittance:,
                    insulation_id: nil,
                    insulation_assembly_r_value:,
                    **remainder)
    walls = XMLHelper.create_elements_as_needed(hpxml, ["Building", "BuildingDetails", "Enclosure", "Walls"])
    wall = XMLHelper.add_element(walls, "Wall")
    sys_id = XMLHelper.add_element(wall, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", id)
    XMLHelper.add_element(wall, "ExteriorAdjacentTo", exterior_adjacent_to)
    XMLHelper.add_element(wall, "InteriorAdjacentTo", interior_adjacent_to)
    wall_type_e = XMLHelper.add_element(wall, "WallType")
    XMLHelper.add_element(wall_type_e, wall_type)
    XMLHelper.add_element(wall, "Area", Float(area))
    XMLHelper.add_element(wall, "Azimuth", Integer(azimuth)) unless azimuth.nil?
    XMLHelper.add_element(wall, "SolarAbsorptance", Float(solar_absorptance))
    XMLHelper.add_element(wall, "Emittance", Float(emittance))
    add_assembly_insulation(parent: wall,
                            id: insulation_id,
                            assembly_r_value: Float(insulation_assembly_r_value))

    return wall
  end

  def self.get_wall_values(wall:)
    return nil if wall.nil?

    insulation_values = get_assembly_insulation_values(insulation: wall.elements["Insulation"])
    insulation_layer_values = get_layer_insulation_values(insulation: wall.elements["Insulation"])

    return { :id => HPXML.get_id(wall),
             :exterior_adjacent_to => XMLHelper.get_value(wall, "ExteriorAdjacentTo"),
             :interior_adjacent_to => XMLHelper.get_value(wall, "InteriorAdjacentTo"),
             :wall_type => XMLHelper.get_child_name(wall, "WallType"),
             :optimum_value_engineering => to_bool_or_nil(XMLHelper.get_value(wall, "WallType/WoodStud/OptimumValueEngineering")),
             :area => to_float_or_nil(XMLHelper.get_value(wall, "Area")),
             :orientation => XMLHelper.get_value(wall, "Orientation"),
             :azimuth => to_integer_or_nil(XMLHelper.get_value(wall, "Azimuth")),
             :siding => XMLHelper.get_value(wall, "Siding"),
             :solar_absorptance => to_float_or_nil(XMLHelper.get_value(wall, "SolarAbsorptance")),
             :emittance => to_float_or_nil(XMLHelper.get_value(wall, "Emittance")),
             :insulation_id => insulation_values[:id],
             :insulation_assembly_r_value => to_float_or_nil(insulation_values[:assembly_r_value]),
             :insulation_cavity_r_value => to_float_or_nil(insulation_layer_values[:cavity_nominal_r_value]),
             :insulation_continuous_r_value => to_float_or_nil(insulation_layer_values[:continuous_nominal_r_value]) }
  end

  def self.add_foundation_wall(hpxml:,
                               id:,
                               exterior_adjacent_to:,
                               interior_adjacent_to:,
                               height:,
                               area:,
                               azimuth: nil,
                               thickness:,
                               depth_below_grade:,
                               insulation_distance_to_bottom: nil,
                               insulation_id: nil,
                               insulation_r_value: nil,
                               insulation_assembly_r_value: nil,
                               **remainder)
    foundation_walls = XMLHelper.create_elements_as_needed(hpxml, ["Building", "BuildingDetails", "Enclosure", "FoundationWalls"])
    foundation_wall = XMLHelper.add_element(foundation_walls, "FoundationWall")
    sys_id = XMLHelper.add_element(foundation_wall, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", id)
    XMLHelper.add_element(foundation_wall, "ExteriorAdjacentTo", exterior_adjacent_to)
    XMLHelper.add_element(foundation_wall, "InteriorAdjacentTo", interior_adjacent_to)
    XMLHelper.add_element(foundation_wall, "Height", Float(height))
    XMLHelper.add_element(foundation_wall, "Area", Float(area))
    XMLHelper.add_element(foundation_wall, "Azimuth", Integer(azimuth)) unless azimuth.nil?
    XMLHelper.add_element(foundation_wall, "Thickness", Float(thickness))
    XMLHelper.add_element(foundation_wall, "DepthBelowGrade", Float(depth_below_grade))
    if not insulation_assembly_r_value.nil?
      add_assembly_insulation(parent: foundation_wall,
                              id: insulation_id,
                              assembly_r_value: Float(insulation_assembly_r_value))
    else
      XMLHelper.add_element(foundation_wall, "DistanceToBottomOfInsulation", Float(insulation_distance_to_bottom))
      add_layer_insulation(parent: foundation_wall,
                           element_name: "Insulation",
                           id: insulation_id,
                           continuous_nominal_r_value: Float(insulation_r_value))
    end

    return foundation_wall
  end

  def self.get_foundation_wall_values(foundation_wall:)
    return nil if foundation_wall.nil?

    insulation_values = get_assembly_insulation_values(insulation: foundation_wall.elements["Insulation"])
    insulation_layer_values = get_layer_insulation_values(insulation: foundation_wall.elements["Insulation"])

    return { :id => HPXML.get_id(foundation_wall),
             :exterior_adjacent_to => XMLHelper.get_value(foundation_wall, "ExteriorAdjacentTo"),
             :interior_adjacent_to => XMLHelper.get_value(foundation_wall, "InteriorAdjacentTo"),
             :height => to_float_or_nil(XMLHelper.get_value(foundation_wall, "Height")),
             :area => to_float_or_nil(XMLHelper.get_value(foundation_wall, "Area")),
             :azimuth => to_integer_or_nil(XMLHelper.get_value(foundation_wall, "Azimuth")),
             :thickness => to_float_or_nil(XMLHelper.get_value(foundation_wall, "Thickness")),
             :depth_below_grade => to_float_or_nil(XMLHelper.get_value(foundation_wall, "DepthBelowGrade")),
             :insulation_distance_to_bottom => to_float_or_nil(XMLHelper.get_value(foundation_wall, "DistanceToBottomOfInsulation")),
             :insulation_id => insulation_layer_values[:id],
             :insulation_r_value => to_float_or_nil(insulation_layer_values[:continuous_nominal_r_value]),
             :insulation_assembly_r_value => to_float_or_nil(insulation_values[:assembly_r_value]) }
  end

  def self.add_framefloor(hpxml:,
                          id:,
                          exterior_adjacent_to:,
                          interior_adjacent_to:,
                          area:,
                          insulation_id: nil,
                          insulation_assembly_r_value:,
                          **remainder)
    framefloors = XMLHelper.create_elements_as_needed(hpxml, ["Building", "BuildingDetails", "Enclosure", "FrameFloors"])
    framefloor = XMLHelper.add_element(framefloors, "FrameFloor")
    sys_id = XMLHelper.add_element(framefloor, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", id)
    XMLHelper.add_element(framefloor, "ExteriorAdjacentTo", exterior_adjacent_to)
    XMLHelper.add_element(framefloor, "InteriorAdjacentTo", interior_adjacent_to)
    XMLHelper.add_element(framefloor, "Area", Float(area))
    add_assembly_insulation(parent: framefloor,
                            id: insulation_id,
                            assembly_r_value: Float(insulation_assembly_r_value))

    return framefloor
  end

  def self.get_framefloor_values(framefloor:)
    return nil if framefloor.nil?

    insulation_values = get_assembly_insulation_values(insulation: framefloor.elements["Insulation"])
    insulation_layer_values = get_layer_insulation_values(insulation: framefloor.elements["Insulation"])

    return { :id => HPXML.get_id(framefloor),
             :exterior_adjacent_to => XMLHelper.get_value(framefloor, "ExteriorAdjacentTo"),
             :interior_adjacent_to => XMLHelper.get_value(framefloor, "InteriorAdjacentTo"),
             :area => to_float_or_nil(XMLHelper.get_value(framefloor, "Area")),
             :insulation_id => insulation_values[:id],
             :insulation_assembly_r_value => to_float_or_nil(insulation_values[:assembly_r_value]),
             :insulation_cavity_r_value => to_float_or_nil(insulation_layer_values[:cavity_nominal_r_value]),
             :insulation_continuous_r_value => to_float_or_nil(insulation_layer_values[:continuous_nominal_r_value]) }
  end

  def self.add_slab(hpxml:,
                    id:,
                    interior_adjacent_to:,
                    area:,
                    thickness:,
                    exposed_perimeter:,
                    perimeter_insulation_depth:,
                    under_slab_insulation_width: nil,
                    under_slab_insulation_spans_entire_slab: nil,
                    depth_below_grade: nil,
                    carpet_fraction:,
                    carpet_r_value:,
                    perimeter_insulation_id: nil,
                    perimeter_insulation_r_value:,
                    under_slab_insulation_id: nil,
                    under_slab_insulation_r_value:,
                    **remainder)
    slabs = foundation_walls = XMLHelper.create_elements_as_needed(hpxml, ["Building", "BuildingDetails", "Enclosure", "Slabs"])
    slab = XMLHelper.add_element(slabs, "Slab")
    sys_id = XMLHelper.add_element(slab, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", id)
    XMLHelper.add_element(slab, "InteriorAdjacentTo", interior_adjacent_to)
    XMLHelper.add_element(slab, "Area", Float(area))
    XMLHelper.add_element(slab, "Thickness", Float(thickness))
    XMLHelper.add_element(slab, "ExposedPerimeter", Float(exposed_perimeter))
    XMLHelper.add_element(slab, "PerimeterInsulationDepth", Float(perimeter_insulation_depth))
    XMLHelper.add_element(slab, "UnderSlabInsulationWidth", Float(under_slab_insulation_width)) unless under_slab_insulation_width.nil?
    XMLHelper.add_element(slab, "UnderSlabInsulationSpansEntireSlab", Boolean(under_slab_insulation_spans_entire_slab)) unless under_slab_insulation_spans_entire_slab.nil?
    XMLHelper.add_element(slab, "DepthBelowGrade", Float(depth_below_grade)) unless depth_below_grade.nil?
    add_layer_insulation(parent: slab,
                         element_name: "PerimeterInsulation",
                         id: perimeter_insulation_id,
                         continuous_nominal_r_value: Float(perimeter_insulation_r_value))
    add_layer_insulation(parent: slab,
                         element_name: "UnderSlabInsulation",
                         id: under_slab_insulation_id,
                         continuous_nominal_r_value: Float(under_slab_insulation_r_value))
    HPXML.add_extension(parent: slab,
                        extensions: { "CarpetFraction": to_float_or_nil(carpet_fraction),
                                      "CarpetRValue": to_float_or_nil(carpet_r_value) })

    return slab
  end

  def self.get_slab_values(slab:)
    return nil if slab.nil?

    perimeter_insulation_values = get_layer_insulation_values(insulation: slab.elements["PerimeterInsulation"])
    under_slab_insulation_values = get_layer_insulation_values(insulation: slab.elements["UnderSlabInsulation"])

    return { :id => HPXML.get_id(slab),
             :interior_adjacent_to => XMLHelper.get_value(slab, "InteriorAdjacentTo"),
             :exterior_adjacent_to => "outside",
             :area => to_float_or_nil(XMLHelper.get_value(slab, "Area")),
             :thickness => to_float_or_nil(XMLHelper.get_value(slab, "Thickness")),
             :exposed_perimeter => to_float_or_nil(XMLHelper.get_value(slab, "ExposedPerimeter")),
             :perimeter_insulation_depth => to_float_or_nil(XMLHelper.get_value(slab, "PerimeterInsulationDepth")),
             :under_slab_insulation_width => to_float_or_nil(XMLHelper.get_value(slab, "UnderSlabInsulationWidth")),
             :under_slab_insulation_spans_entire_slab => to_bool_or_nil(XMLHelper.get_value(slab, "UnderSlabInsulationSpansEntireSlab")),
             :depth_below_grade => to_float_or_nil(XMLHelper.get_value(slab, "DepthBelowGrade")),
             :carpet_fraction => to_float_or_nil(XMLHelper.get_value(slab, "extension/CarpetFraction")),
             :carpet_r_value => to_float_or_nil(XMLHelper.get_value(slab, "extension/CarpetRValue")),
             :perimeter_insulation_id => perimeter_insulation_values[:id],
             :perimeter_insulation_r_value => to_float_or_nil(perimeter_insulation_values[:continuous_nominal_r_value]),
             :under_slab_insulation_id => under_slab_insulation_values[:id],
             :under_slab_insulation_r_value => to_float_or_nil(under_slab_insulation_values[:continuous_nominal_r_value]) }
  end

  def self.add_window(hpxml:,
                      id:,
                      area:,
                      azimuth:,
                      ufactor:,
                      shgc:,
                      overhangs_depth: nil,
                      overhangs_distance_to_top_of_window: nil,
                      overhangs_distance_to_bottom_of_window: nil,
                      wall_idref:,
                      interior_shading_factor_summer: nil,
                      interior_shading_factor_winter: nil,
                      **remainder)
    windows = XMLHelper.create_elements_as_needed(hpxml, ["Building", "BuildingDetails", "Enclosure", "Windows"])
    window = XMLHelper.add_element(windows, "Window")
    sys_id = XMLHelper.add_element(window, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", id)
    XMLHelper.add_element(window, "Area", Float(area))
    XMLHelper.add_element(window, "Azimuth", Integer(azimuth))
    XMLHelper.add_element(window, "UFactor", Float(ufactor))
    XMLHelper.add_element(window, "SHGC", Float(shgc))
    if not interior_shading_factor_summer.nil? or not interior_shading_factor_winter.nil?
      interior_shading = XMLHelper.add_element(window, "InteriorShading")
      sys_id = XMLHelper.add_element(interior_shading, "SystemIdentifier")
      XMLHelper.add_attribute(sys_id, "id", "#{id}InteriorShading")
      XMLHelper.add_element(interior_shading, "SummerShadingCoefficient", Float(interior_shading_factor_summer)) unless interior_shading_factor_summer.nil?
      XMLHelper.add_element(interior_shading, "WinterShadingCoefficient", Float(interior_shading_factor_winter)) unless interior_shading_factor_winter.nil?
    end
    if not overhangs_depth.nil? or not overhangs_distance_to_top_of_window.nil? or not overhangs_distance_to_bottom_of_window.nil?
      overhangs = XMLHelper.add_element(window, "Overhangs")
      XMLHelper.add_element(overhangs, "Depth", Float(overhangs_depth))
      XMLHelper.add_element(overhangs, "DistanceToTopOfWindow", Float(overhangs_distance_to_top_of_window))
      XMLHelper.add_element(overhangs, "DistanceToBottomOfWindow", Float(overhangs_distance_to_bottom_of_window))
    end
    attached_to_wall = XMLHelper.add_element(window, "AttachedToWall")
    XMLHelper.add_attribute(attached_to_wall, "idref", wall_idref)

    return window
  end

  def self.get_window_values(window:)
    return nil if window.nil?

    frame_type = window.elements["FrameType"]
    unless frame_type.nil?
      frame_type = XMLHelper.get_child_name(window, "FrameType")
    end

    return { :id => HPXML.get_id(window),
             :area => to_float_or_nil(XMLHelper.get_value(window, "Area")),
             :azimuth => to_integer_or_nil(XMLHelper.get_value(window, "Azimuth")),
             :orientation => XMLHelper.get_value(window, "Orientation"),
             :frame_type => frame_type,
             :aluminum_thermal_break => to_bool_or_nil(XMLHelper.get_value(window, "FrameType/Aluminum/ThermalBreak")),
             :glass_layers => XMLHelper.get_value(window, "GlassLayers"),
             :glass_type => XMLHelper.get_value(window, "GlassType"),
             :gas_fill => XMLHelper.get_value(window, "GasFill"),
             :ufactor => to_float_or_nil(XMLHelper.get_value(window, "UFactor")),
             :shgc => to_float_or_nil(XMLHelper.get_value(window, "SHGC")),
             :interior_shading_factor_summer => to_float_or_nil(XMLHelper.get_value(window, "InteriorShading/SummerShadingCoefficient")),
             :interior_shading_factor_winter => to_float_or_nil(XMLHelper.get_value(window, "InteriorShading/WinterShadingCoefficient")),
             :exterior_shading => XMLHelper.get_value(window, "ExteriorShading/Type"),
             :overhangs_depth => to_float_or_nil(XMLHelper.get_value(window, "Overhangs/Depth")),
             :overhangs_distance_to_top_of_window => to_float_or_nil(XMLHelper.get_value(window, "Overhangs/DistanceToTopOfWindow")),
             :overhangs_distance_to_bottom_of_window => to_float_or_nil(XMLHelper.get_value(window, "Overhangs/DistanceToBottomOfWindow")),
             :wall_idref => HPXML.get_idref(window, "AttachedToWall") }
  end

  def self.add_skylight(hpxml:,
                        id:,
                        area:,
                        azimuth:,
                        ufactor:,
                        shgc:,
                        roof_idref:,
                        **remainder)
    skylights = XMLHelper.create_elements_as_needed(hpxml, ["Building", "BuildingDetails", "Enclosure", "Skylights"])
    skylight = XMLHelper.add_element(skylights, "Skylight")
    sys_id = XMLHelper.add_element(skylight, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", id)
    XMLHelper.add_element(skylight, "Area", Float(area))
    XMLHelper.add_element(skylight, "Azimuth", Integer(azimuth))
    XMLHelper.add_element(skylight, "UFactor", Float(ufactor))
    XMLHelper.add_element(skylight, "SHGC", Float(shgc))
    attached_to_roof = XMLHelper.add_element(skylight, "AttachedToRoof")
    XMLHelper.add_attribute(attached_to_roof, "idref", roof_idref)

    return skylight
  end

  def self.get_skylight_values(skylight:)
    return nil if skylight.nil?

    frame_type = skylight.elements["FrameType"]
    unless frame_type.nil?
      frame_type = XMLHelper.get_child_name(skylight, "FrameType")
    end

    return { :id => HPXML.get_id(skylight),
             :area => to_float_or_nil(XMLHelper.get_value(skylight, "Area")),
             :azimuth => to_integer_or_nil(XMLHelper.get_value(skylight, "Azimuth")),
             :orientation => XMLHelper.get_value(skylight, "Orientation"),
             :frame_type => frame_type,
             :aluminum_thermal_break => to_bool_or_nil(XMLHelper.get_value(skylight, "FrameType/Aluminum/ThermalBreak")),
             :glass_layers => XMLHelper.get_value(skylight, "GlassLayers"),
             :glass_type => XMLHelper.get_value(skylight, "GlassType"),
             :gas_fill => XMLHelper.get_value(skylight, "GasFill"),
             :ufactor => to_float_or_nil(XMLHelper.get_value(skylight, "UFactor")),
             :shgc => to_float_or_nil(XMLHelper.get_value(skylight, "SHGC")),
             :exterior_shading => XMLHelper.get_value(skylight, "ExteriorShading/Type"),
             :roof_idref => HPXML.get_idref(skylight, "AttachedToRoof") }
  end

  def self.add_door(hpxml:,
                    id:,
                    wall_idref:,
                    area:,
                    azimuth:,
                    r_value:,
                    **remainder)
    doors = XMLHelper.create_elements_as_needed(hpxml, ["Building", "BuildingDetails", "Enclosure", "Doors"])
    door = XMLHelper.add_element(doors, "Door")
    sys_id = XMLHelper.add_element(door, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", id)
    attached_to_wall = XMLHelper.add_element(door, "AttachedToWall")
    XMLHelper.add_attribute(attached_to_wall, "idref", wall_idref)
    XMLHelper.add_element(door, "Area", Float(area))
    XMLHelper.add_element(door, "Azimuth", Integer(azimuth))
    XMLHelper.add_element(door, "RValue", Float(r_value))

    return door
  end

  def self.get_door_values(door:)
    return nil if door.nil?

    return { :id => HPXML.get_id(door),
             :wall_idref => HPXML.get_idref(door, "AttachedToWall"),
             :area => to_float_or_nil(XMLHelper.get_value(door, "Area")),
             :azimuth => to_integer_or_nil(XMLHelper.get_value(door, "Azimuth")),
             :r_value => to_float_or_nil(XMLHelper.get_value(door, "RValue")) }
  end

  def self.add_heating_system(hpxml:,
                              id:,
                              distribution_system_idref: nil,
                              heating_system_type:,
                              heating_system_fuel:,
                              heating_capacity:,
                              heating_efficiency_percent: nil,
                              heating_efficiency_afue: nil,
                              heating_efficiency_cop: nil,
                              heating_efficiency_hspf: nil,
                              fraction_heat_load_served:,
                              electric_auxiliary_energy: nil,
                              **remainder)
    hvac_plant = XMLHelper.create_elements_as_needed(hpxml, ["Building", "BuildingDetails", "Systems", "HVAC", "HVACPlant"])
    heating_system = XMLHelper.add_element(hvac_plant, "HeatingSystem")
    sys_id = XMLHelper.add_element(heating_system, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", id)
    unless distribution_system_idref.nil?
      distribution_system = XMLHelper.add_element(heating_system, "DistributionSystem")
      XMLHelper.add_attribute(distribution_system, "idref", distribution_system_idref)
    end
    heating_system_type_e = XMLHelper.add_element(heating_system, "HeatingSystemType")
    XMLHelper.add_element(heating_system_type_e, heating_system_type)
    XMLHelper.add_element(heating_system, "HeatingSystemFuel", heating_system_fuel)
    XMLHelper.add_element(heating_system, "HeatingCapacity", Float(heating_capacity))
    efficiencies = { "Percent" => heating_efficiency_percent,
                     "AFUE" => heating_efficiency_afue,
                     "COP" => heating_efficiency_cop,
                     "HSPF" => heating_efficiency_hspf }
    efficiencies.each do |units, value|
      next if value.nil?

      annual_efficiency = XMLHelper.add_element(heating_system, "AnnualHeatingEfficiency")
      XMLHelper.add_element(annual_efficiency, "Units", units)
      XMLHelper.add_element(annual_efficiency, "Value", Float(value))
    end
    XMLHelper.add_element(heating_system, "FractionHeatLoadServed", Float(fraction_heat_load_served))
    XMLHelper.add_element(heating_system, "ElectricAuxiliaryEnergy", Float(electric_auxiliary_energy)) unless electric_auxiliary_energy.nil?

    return heating_system
  end

  def self.get_heating_system_values(heating_system:)
    return nil if heating_system.nil?

    return { :id => HPXML.get_id(heating_system),
             :distribution_system_idref => HPXML.get_idref(heating_system, "DistributionSystem"),
             :year_installed => to_integer_or_nil(XMLHelper.get_value(heating_system, "YearInstalled")),
             :heating_system_type => XMLHelper.get_child_name(heating_system, "HeatingSystemType"),
             :heating_system_fuel => XMLHelper.get_value(heating_system, "HeatingSystemFuel"),
             :heating_capacity => to_float_or_nil(XMLHelper.get_value(heating_system, "HeatingCapacity")),
             :heating_efficiency_percent => to_float_or_nil(XMLHelper.get_value(heating_system, "AnnualHeatingEfficiency[Units='Percent']/Value")),
             :heating_efficiency_afue => to_float_or_nil(XMLHelper.get_value(heating_system, "AnnualHeatingEfficiency[Units='AFUE']/Value")),
             :heating_efficiency_cop => to_float_or_nil(XMLHelper.get_value(heating_system, "AnnualHeatingEfficiency[Units='COP']/Value")),
             :heating_efficiency_hspf => to_float_or_nil(XMLHelper.get_value(heating_system, "AnnualHeatingEfficiency[Units='HSPF']/Value")),
             :fraction_heat_load_served => to_float_or_nil(XMLHelper.get_value(heating_system, "FractionHeatLoadServed")),
             :electric_auxiliary_energy => to_float_or_nil(XMLHelper.get_value(heating_system, "ElectricAuxiliaryEnergy")),
             :energy_star => XMLHelper.get_values(heating_system, "ThirdPartyCertification").include?("Energy Star") }
  end

  def self.add_cooling_system(hpxml:,
                              id:,
                              distribution_system_idref: nil,
                              cooling_system_type:,
                              cooling_system_fuel:,
                              cooling_capacity:,
                              fraction_cool_load_served:,
                              cooling_efficiency_kw_per_ton: nil,
                              cooling_efficiency_cop: nil,
                              cooling_efficiency_eer: nil,
                              cooling_efficiency_seer: nil,
                              cooling_shr: nil,
                              **remainder)
    hvac_plant = XMLHelper.create_elements_as_needed(hpxml, ["Building", "BuildingDetails", "Systems", "HVAC", "HVACPlant"])
    cooling_system = XMLHelper.add_element(hvac_plant, "CoolingSystem")
    sys_id = XMLHelper.add_element(cooling_system, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", id)
    unless distribution_system_idref.nil?
      distribution_system = XMLHelper.add_element(cooling_system, "DistributionSystem")
      XMLHelper.add_attribute(distribution_system, "idref", distribution_system_idref)
    end
    XMLHelper.add_element(cooling_system, "CoolingSystemType", cooling_system_type)
    XMLHelper.add_element(cooling_system, "CoolingSystemFuel", cooling_system_fuel)
    XMLHelper.add_element(cooling_system, "CoolingCapacity", Float(cooling_capacity))
    XMLHelper.add_element(cooling_system, "FractionCoolLoadServed", Float(fraction_cool_load_served))
    efficiencies = { "kW/ton" => cooling_efficiency_kw_per_ton,
                     "COP" => cooling_efficiency_cop,
                     "EER" => cooling_efficiency_eer,
                     "SEER" => cooling_efficiency_seer }
    efficiencies.each do |units, value|
      next if value.nil?

      annual_efficiency = XMLHelper.add_element(cooling_system, "AnnualCoolingEfficiency")
      XMLHelper.add_element(annual_efficiency, "Units", units)
      XMLHelper.add_element(annual_efficiency, "Value", Float(value))
    end
    XMLHelper.add_element(cooling_system, "SensibleHeatFraction", Float(cooling_shr)) unless cooling_shr.nil?

    return cooling_system
  end

  def self.get_cooling_system_values(cooling_system:)
    return nil if cooling_system.nil?

    return { :id => HPXML.get_id(cooling_system),
             :distribution_system_idref => HPXML.get_idref(cooling_system, "DistributionSystem"),
             :year_installed => to_integer_or_nil(XMLHelper.get_value(cooling_system, "YearInstalled")),
             :cooling_system_type => XMLHelper.get_value(cooling_system, "CoolingSystemType"),
             :cooling_system_fuel => XMLHelper.get_value(cooling_system, "CoolingSystemFuel"),
             :cooling_capacity => to_float_or_nil(XMLHelper.get_value(cooling_system, "CoolingCapacity")),
             :fraction_cool_load_served => to_float_or_nil(XMLHelper.get_value(cooling_system, "FractionCoolLoadServed")),
             :cooling_efficiency_kw_per_ton => to_float_or_nil(XMLHelper.get_value(cooling_system, "AnnualCoolingEfficiency[Units='kW/ton']/Value")),
             :cooling_efficiency_cop => to_float_or_nil(XMLHelper.get_value(cooling_system, "AnnualCoolingEfficiency[Units='COP']/Value")),
             :cooling_efficiency_eer => to_float_or_nil(XMLHelper.get_value(cooling_system, "AnnualCoolingEfficiency[Units='EER']/Value")),
             :cooling_efficiency_seer => to_float_or_nil(XMLHelper.get_value(cooling_system, "AnnualCoolingEfficiency[Units='SEER']/Value")),
             :cooling_shr => to_float_or_nil(XMLHelper.get_value(cooling_system, "SensibleHeatFraction")),
             :energy_star => XMLHelper.get_values(cooling_system, "ThirdPartyCertification").include?("Energy Star") }
  end

  def self.add_heat_pump(hpxml:,
                         id:,
                         distribution_system_idref: nil,
                         heat_pump_type:,
                         heat_pump_fuel:,
                         heating_capacity: nil,
                         heating_capacity_17F: nil,
                         cooling_capacity:,
                         cooling_shr: nil,
                         backup_heating_fuel: nil,
                         backup_heating_capacity: nil,
                         backup_heating_efficiency_percent: nil,
                         fraction_heat_load_served:,
                         fraction_cool_load_served:,
                         heating_efficiency_percent: nil,
                         heating_efficiency_afue: nil,
                         heating_efficiency_cop: nil,
                         heating_efficiency_hspf: nil,
                         cooling_efficiency_kw_per_ton: nil,
                         cooling_efficiency_cop: nil,
                         cooling_efficiency_eer: nil,
                         cooling_efficiency_seer: nil,
                         **remainder)
    hvac_plant = XMLHelper.create_elements_as_needed(hpxml, ["Building", "BuildingDetails", "Systems", "HVAC", "HVACPlant"])
    heat_pump = XMLHelper.add_element(hvac_plant, "HeatPump")
    sys_id = XMLHelper.add_element(heat_pump, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", id)
    unless distribution_system_idref.nil?
      distribution_system = XMLHelper.add_element(heat_pump, "DistributionSystem")
      XMLHelper.add_attribute(distribution_system, "idref", distribution_system_idref)
    end
    XMLHelper.add_element(heat_pump, "HeatPumpType", heat_pump_type)
    XMLHelper.add_element(heat_pump, "HeatPumpFuel", heat_pump_fuel)
    XMLHelper.add_element(heat_pump, "HeatingCapacity", Float(heating_capacity)) unless heating_capacity.nil?
    XMLHelper.add_element(heat_pump, "HeatingCapacity17F", Float(heating_capacity_17F)) unless heating_capacity_17F.nil?
    XMLHelper.add_element(heat_pump, "CoolingCapacity", Float(cooling_capacity))
    XMLHelper.add_element(heat_pump, "CoolingSensibleHeatFraction", Float(cooling_shr)) unless cooling_shr.nil?
    if not backup_heating_fuel.nil?
      XMLHelper.add_element(heat_pump, "BackupSystemFuel", backup_heating_fuel)
      backup_eff = XMLHelper.add_element(heat_pump, "BackupAnnualHeatingEfficiency")
      XMLHelper.add_element(backup_eff, "Units", "Percent")
      XMLHelper.add_element(backup_eff, "Value", Float(backup_heating_efficiency_percent))
      XMLHelper.add_element(heat_pump, "BackupHeatingCapacity", Float(backup_heating_capacity))
    end
    XMLHelper.add_element(heat_pump, "FractionHeatLoadServed", Float(fraction_heat_load_served))
    XMLHelper.add_element(heat_pump, "FractionCoolLoadServed", Float(fraction_cool_load_served))
    efficiencies = { "kW/ton" => cooling_efficiency_kw_per_ton,
                     "COP" => cooling_efficiency_cop,
                     "EER" => cooling_efficiency_eer,
                     "SEER" => cooling_efficiency_seer }
    efficiencies.each do |units, value|
      next if value.nil?

      annual_efficiency = XMLHelper.add_element(heat_pump, "AnnualCoolingEfficiency")
      XMLHelper.add_element(annual_efficiency, "Units", units)
      XMLHelper.add_element(annual_efficiency, "Value", Float(value))
    end
    efficiencies = { "Percent" => heating_efficiency_percent,
                     "AFUE" => heating_efficiency_afue,
                     "COP" => heating_efficiency_cop,
                     "HSPF" => heating_efficiency_hspf }
    efficiencies.each do |units, value|
      next if value.nil?

      annual_efficiency = XMLHelper.add_element(heat_pump, "AnnualHeatingEfficiency")
      XMLHelper.add_element(annual_efficiency, "Units", units)
      XMLHelper.add_element(annual_efficiency, "Value", Float(value))
    end

    return heat_pump
  end

  def self.get_heat_pump_values(heat_pump:)
    return nil if heat_pump.nil?

    return { :id => HPXML.get_id(heat_pump),
             :distribution_system_idref => HPXML.get_idref(heat_pump, "DistributionSystem"),
             :year_installed => to_integer_or_nil(XMLHelper.get_value(heat_pump, "YearInstalled")),
             :heat_pump_type => XMLHelper.get_value(heat_pump, "HeatPumpType"),
             :heat_pump_fuel => XMLHelper.get_value(heat_pump, "HeatPumpFuel"),
             :heating_capacity => to_float_or_nil(XMLHelper.get_value(heat_pump, "HeatingCapacity")),
             :heating_capacity_17F => to_float_or_nil(XMLHelper.get_value(heat_pump, "HeatingCapacity17F")),
             :cooling_capacity => to_float_or_nil(XMLHelper.get_value(heat_pump, "CoolingCapacity")),
             :cooling_shr => to_float_or_nil(XMLHelper.get_value(heat_pump, "CoolingSensibleHeatFraction")),
             :backup_heating_fuel => XMLHelper.get_value(heat_pump, "BackupSystemFuel"),
             :backup_heating_capacity => to_float_or_nil(XMLHelper.get_value(heat_pump, "BackupHeatingCapacity")),
             :backup_heating_efficiency_percent => to_float_or_nil(XMLHelper.get_value(heat_pump, "BackupAnnualHeatingEfficiency[Units='Percent']/Value")),
             :fraction_heat_load_served => to_float_or_nil(XMLHelper.get_value(heat_pump, "FractionHeatLoadServed")),
             :fraction_cool_load_served => to_float_or_nil(XMLHelper.get_value(heat_pump, "FractionCoolLoadServed")),
             :heating_efficiency_percent => to_float_or_nil(XMLHelper.get_value(heat_pump, "AnnualHeatingEfficiency[Units='Percent']/Value")),
             :heating_efficiency_afue => to_float_or_nil(XMLHelper.get_value(heat_pump, "AnnualHeatingEfficiency[Units='AFUE']/Value")),
             :heating_efficiency_cop => to_float_or_nil(XMLHelper.get_value(heat_pump, "AnnualHeatingEfficiency[Units='COP']/Value")),
             :heating_efficiency_hspf => to_float_or_nil(XMLHelper.get_value(heat_pump, "AnnualHeatingEfficiency[Units='HSPF']/Value")),
             :cooling_efficiency_kw_per_ton => to_float_or_nil(XMLHelper.get_value(heat_pump, "AnnualCoolingEfficiency[Units='kW/ton']/Value")),
             :cooling_efficiency_cop => to_float_or_nil(XMLHelper.get_value(heat_pump, "AnnualCoolingEfficiency[Units='COP']/Value")),
             :cooling_efficiency_eer => to_float_or_nil(XMLHelper.get_value(heat_pump, "AnnualCoolingEfficiency[Units='EER']/Value")),
             :cooling_efficiency_seer => to_float_or_nil(XMLHelper.get_value(heat_pump, "AnnualCoolingEfficiency[Units='SEER']/Value")),
             :energy_star => XMLHelper.get_values(heat_pump, "ThirdPartyCertification").include?("Energy Star") }
  end

  def self.add_hvac_control(hpxml:,
                            id:,
                            control_type: nil,
                            heating_setpoint_temp: nil,
                            heating_setback_temp: nil,
                            heating_setback_hours_per_week: nil,
                            heating_setback_start_hour: nil,
                            cooling_setpoint_temp: nil,
                            cooling_setup_temp: nil,
                            cooling_setup_hours_per_week: nil,
                            cooling_setup_start_hour: nil,
                            ceiling_fan_cooling_setpoint_temp_offset: nil,
                            **remainder)
    hvac = XMLHelper.create_elements_as_needed(hpxml, ["Building", "BuildingDetails", "Systems", "HVAC"])
    hvac_control = XMLHelper.add_element(hvac, "HVACControl")
    sys_id = XMLHelper.add_element(hvac_control, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", id)
    XMLHelper.add_element(hvac_control, "ControlType", control_type) unless control_type.nil?
    XMLHelper.add_element(hvac_control, "SetpointTempHeatingSeason", Float(heating_setpoint_temp)) unless heating_setpoint_temp.nil?
    XMLHelper.add_element(hvac_control, "SetbackTempHeatingSeason", Float(heating_setback_temp)) unless heating_setback_temp.nil?
    XMLHelper.add_element(hvac_control, "TotalSetbackHoursperWeekHeating", Integer(heating_setback_hours_per_week)) unless heating_setback_hours_per_week.nil?
    XMLHelper.add_element(hvac_control, "SetupTempCoolingSeason", Float(cooling_setup_temp)) unless cooling_setup_temp.nil?
    XMLHelper.add_element(hvac_control, "SetpointTempCoolingSeason", Float(cooling_setpoint_temp)) unless cooling_setpoint_temp.nil?
    XMLHelper.add_element(hvac_control, "TotalSetupHoursperWeekCooling", Integer(cooling_setup_hours_per_week)) unless cooling_setup_hours_per_week.nil?
    HPXML.add_extension(parent: hvac_control,
                        extensions: { "SetbackStartHourHeating": to_integer_or_nil(heating_setback_start_hour),
                                      "SetupStartHourCooling": to_integer_or_nil(cooling_setup_start_hour),
                                      "CeilingFanSetpointTempCoolingSeasonOffset": to_float_or_nil(ceiling_fan_cooling_setpoint_temp_offset) })

    return hvac_control
  end

  def self.get_hvac_control_values(hvac_control:)
    return nil if hvac_control.nil?

    return { :id => HPXML.get_id(hvac_control),
             :control_type => XMLHelper.get_value(hvac_control, "ControlType"),
             :heating_setpoint_temp => to_float_or_nil(XMLHelper.get_value(hvac_control, "SetpointTempHeatingSeason")),
             :heating_setback_temp => to_float_or_nil(XMLHelper.get_value(hvac_control, "SetbackTempHeatingSeason")),
             :heating_setback_hours_per_week => to_integer_or_nil(XMLHelper.get_value(hvac_control, "TotalSetbackHoursperWeekHeating")),
             :heating_setback_start_hour => to_integer_or_nil(XMLHelper.get_value(hvac_control, "extension/SetbackStartHourHeating")),
             :cooling_setpoint_temp => to_float_or_nil(XMLHelper.get_value(hvac_control, "SetpointTempCoolingSeason")),
             :cooling_setup_temp => to_float_or_nil(XMLHelper.get_value(hvac_control, "SetupTempCoolingSeason")),
             :cooling_setup_hours_per_week => to_integer_or_nil(XMLHelper.get_value(hvac_control, "TotalSetupHoursperWeekCooling")),
             :cooling_setup_start_hour => to_integer_or_nil(XMLHelper.get_value(hvac_control, "extension/SetupStartHourCooling")),
             :ceiling_fan_cooling_setpoint_temp_offset => to_float_or_nil(XMLHelper.get_value(hvac_control, "extension/CeilingFanSetpointTempCoolingSeasonOffset")) }
  end

  def self.add_hvac_distribution(hpxml:,
                                 id:,
                                 distribution_system_type:,
                                 annual_heating_dse: nil,
                                 annual_cooling_dse: nil,
                                 **remainder)
    hvac = XMLHelper.create_elements_as_needed(hpxml, ["Building", "BuildingDetails", "Systems", "HVAC"])
    hvac_distribution = XMLHelper.add_element(hvac, "HVACDistribution")
    sys_id = XMLHelper.add_element(hvac_distribution, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", id)
    distribution_system_type_e = XMLHelper.add_element(hvac_distribution, "DistributionSystemType")
    if ["AirDistribution", "HydronicDistribution"].include? distribution_system_type
      XMLHelper.add_element(distribution_system_type_e, distribution_system_type)
    elsif ["DSE"].include? distribution_system_type
      XMLHelper.add_element(distribution_system_type_e, "Other", distribution_system_type)
      XMLHelper.add_element(hvac_distribution, "AnnualHeatingDistributionSystemEfficiency", Float(annual_heating_dse)) unless annual_heating_dse.nil?
      XMLHelper.add_element(hvac_distribution, "AnnualCoolingDistributionSystemEfficiency", Float(annual_cooling_dse)) unless annual_cooling_dse.nil?
    else
      fail "Unexpected distribution_system_type '#{distribution_system_type}'."
    end

    return hvac_distribution
  end

  def self.get_hvac_distribution_values(hvac_distribution:)
    return nil if hvac_distribution.nil?

    distribution_system_type = XMLHelper.get_child_name(hvac_distribution, "DistributionSystemType")
    if distribution_system_type == "Other"
      distribution_system_type = XMLHelper.get_value(hvac_distribution.elements["DistributionSystemType"], "Other")
    end

    return { :id => HPXML.get_id(hvac_distribution),
             :distribution_system_type => distribution_system_type,
             :annual_heating_dse => to_float_or_nil(XMLHelper.get_value(hvac_distribution, "AnnualHeatingDistributionSystemEfficiency")),
             :annual_cooling_dse => to_float_or_nil(XMLHelper.get_value(hvac_distribution, "AnnualCoolingDistributionSystemEfficiency")),
             :duct_system_sealed => to_bool_or_nil(XMLHelper.get_value(hvac_distribution, "HVACDistributionImprovement/DuctSystemSealed")) }
  end

  def self.add_duct_leakage_measurement(air_distribution:,
                                        duct_type:,
                                        duct_leakage_units:,
                                        duct_leakage_value:,
                                        **remainder)
    duct_leakage_measurement = XMLHelper.add_element(air_distribution, "DuctLeakageMeasurement")
    XMLHelper.add_element(duct_leakage_measurement, "DuctType", duct_type)
    duct_leakage = XMLHelper.add_element(duct_leakage_measurement, "DuctLeakage")
    XMLHelper.add_element(duct_leakage, "Units", duct_leakage_units)
    XMLHelper.add_element(duct_leakage, "Value", Float(duct_leakage_value))
    XMLHelper.add_element(duct_leakage, "TotalOrToOutside", "to outside")

    return duct_leakage_measurement
  end

  def self.get_duct_leakage_measurement_values(duct_leakage_measurement:)
    return nil if duct_leakage_measurement.nil?

    return { :duct_type => XMLHelper.get_value(duct_leakage_measurement, "DuctType"),
             :duct_leakage_test_method => XMLHelper.get_value(duct_leakage_measurement, "DuctLeakageTestMethod"),
             :duct_leakage_units => XMLHelper.get_value(duct_leakage_measurement, "DuctLeakage/Units"),
             :duct_leakage_value => to_float_or_nil(XMLHelper.get_value(duct_leakage_measurement, "DuctLeakage/Value")),
             :duct_leakage_total_or_to_outside => XMLHelper.get_value(duct_leakage_measurement, "DuctLeakage/TotalOrToOutside") }
  end

  def self.add_ducts(air_distribution:,
                     duct_type:,
                     duct_insulation_r_value:,
                     duct_location:,
                     duct_surface_area:,
                     **remainder)
    ducts = XMLHelper.add_element(air_distribution, "Ducts")
    XMLHelper.add_element(ducts, "DuctType", duct_type)
    XMLHelper.add_element(ducts, "DuctInsulationRValue", Float(duct_insulation_r_value))
    XMLHelper.add_element(ducts, "DuctLocation", duct_location)
    XMLHelper.add_element(ducts, "DuctSurfaceArea", Float(duct_surface_area))

    return ducts
  end

  def self.get_ducts_values(ducts:)
    return nil if ducts.nil?

    return { :duct_type => XMLHelper.get_value(ducts, "DuctType"),
             :duct_insulation_r_value => to_float_or_nil(XMLHelper.get_value(ducts, "DuctInsulationRValue")),
             :duct_insulation_material => XMLHelper.get_value(ducts, "DuctInsulationMaterial"),
             :duct_location => XMLHelper.get_value(ducts, "DuctLocation"),
             :duct_fraction_area => to_float_or_nil(XMLHelper.get_value(ducts, "FractionDuctArea")),
             :duct_surface_area => to_float_or_nil(XMLHelper.get_value(ducts, "DuctSurfaceArea")) }
  end

  def self.add_ventilation_fan(hpxml:,
                               id:,
                               fan_type:,
                               rated_flow_rate: nil,
                               tested_flow_rate: nil,
                               hours_in_operation:,
                               total_recovery_efficiency: nil,
                               total_recovery_efficiency_adjusted: nil,
                               sensible_recovery_efficiency: nil,
                               sensible_recovery_efficiency_adjusted: nil,
                               fan_power: nil,
                               distribution_system_idref: nil,
                               **remainder)
    ventilation_fans = XMLHelper.create_elements_as_needed(hpxml, ["Building", "BuildingDetails", "Systems", "MechanicalVentilation", "VentilationFans"])
    ventilation_fan = XMLHelper.add_element(ventilation_fans, "VentilationFan")
    sys_id = XMLHelper.add_element(ventilation_fan, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", id)
    XMLHelper.add_element(ventilation_fan, "FanType", fan_type)
    XMLHelper.add_element(ventilation_fan, "RatedFlowRate", Float(rated_flow_rate)) unless rated_flow_rate.nil?
    XMLHelper.add_element(ventilation_fan, "TestedFlowRate", Float(tested_flow_rate)) unless tested_flow_rate.nil?
    XMLHelper.add_element(ventilation_fan, "HoursInOperation", Float(hours_in_operation))
    XMLHelper.add_element(ventilation_fan, "UsedForWholeBuildingVentilation", true)
    XMLHelper.add_element(ventilation_fan, "TotalRecoveryEfficiency", Float(total_recovery_efficiency)) unless total_recovery_efficiency.nil?
    XMLHelper.add_element(ventilation_fan, "SensibleRecoveryEfficiency", Float(sensible_recovery_efficiency)) unless sensible_recovery_efficiency.nil?
    XMLHelper.add_element(ventilation_fan, "AdjustedTotalRecoveryEfficiency", Float(total_recovery_efficiency_adjusted)) unless total_recovery_efficiency_adjusted.nil?
    XMLHelper.add_element(ventilation_fan, "AdjustedSensibleRecoveryEfficiency", Float(sensible_recovery_efficiency_adjusted)) unless sensible_recovery_efficiency_adjusted.nil?
    XMLHelper.add_element(ventilation_fan, "FanPower", Float(fan_power)) unless fan_power.nil?
    unless distribution_system_idref.nil?
      attached_to_hvac_distribution_system = XMLHelper.add_element(ventilation_fan, "AttachedToHVACDistributionSystem")
      XMLHelper.add_attribute(attached_to_hvac_distribution_system, "idref", distribution_system_idref)
    end

    return ventilation_fan
  end

  def self.get_ventilation_fan_values(ventilation_fan:)
    return nil if ventilation_fan.nil?

    return { :id => HPXML.get_id(ventilation_fan),
             :fan_type => XMLHelper.get_value(ventilation_fan, "FanType"),
             :rated_flow_rate => to_float_or_nil(XMLHelper.get_value(ventilation_fan, "RatedFlowRate")),
             :tested_flow_rate => to_float_or_nil(XMLHelper.get_value(ventilation_fan, "TestedFlowRate")),
             :hours_in_operation => to_float_or_nil(XMLHelper.get_value(ventilation_fan, "HoursInOperation")),
             :total_recovery_efficiency => to_float_or_nil(XMLHelper.get_value(ventilation_fan, "TotalRecoveryEfficiency")),
             :total_recovery_efficiency_adjusted => to_float_or_nil(XMLHelper.get_value(ventilation_fan, "AdjustedTotalRecoveryEfficiency")),
             :sensible_recovery_efficiency => to_float_or_nil(XMLHelper.get_value(ventilation_fan, "SensibleRecoveryEfficiency")),
             :sensible_recovery_efficiency_adjusted => to_float_or_nil(XMLHelper.get_value(ventilation_fan, "AdjustedSensibleRecoveryEfficiency")),
             :fan_power => to_float_or_nil(XMLHelper.get_value(ventilation_fan, "FanPower")),
             :distribution_system_idref => HPXML.get_idref(ventilation_fan, "AttachedToHVACDistributionSystem") }
  end

  def self.add_water_heating_system(hpxml:,
                                    id:,
                                    fuel_type: nil,
                                    water_heater_type:,
                                    location:,
                                    performance_adjustment: nil,
                                    tank_volume: nil,
                                    fraction_dhw_load_served:,
                                    heating_capacity: nil,
                                    energy_factor: nil,
                                    uniform_energy_factor: nil,
                                    recovery_efficiency: nil,
                                    uses_desuperheater: nil,
                                    jacket_r_value: nil,
                                    related_hvac: nil,
                                    **remainder)
    water_heating = XMLHelper.create_elements_as_needed(hpxml, ["Building", "BuildingDetails", "Systems", "WaterHeating"])
    water_heating_system = XMLHelper.add_element(water_heating, "WaterHeatingSystem")
    sys_id = XMLHelper.add_element(water_heating_system, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", id)
    XMLHelper.add_element(water_heating_system, "FuelType", fuel_type) unless fuel_type.nil?
    XMLHelper.add_element(water_heating_system, "WaterHeaterType", water_heater_type)
    XMLHelper.add_element(water_heating_system, "Location", location)
    XMLHelper.add_element(water_heating_system, "PerformanceAdjustment", Float(performance_adjustment)) unless performance_adjustment.nil?
    XMLHelper.add_element(water_heating_system, "TankVolume", Float(tank_volume)) unless tank_volume.nil?
    XMLHelper.add_element(water_heating_system, "FractionDHWLoadServed", Float(fraction_dhw_load_served))
    XMLHelper.add_element(water_heating_system, "HeatingCapacity", Float(heating_capacity)) unless heating_capacity.nil?
    XMLHelper.add_element(water_heating_system, "EnergyFactor", Float(energy_factor)) unless energy_factor.nil?
    XMLHelper.add_element(water_heating_system, "UniformEnergyFactor", Float(uniform_energy_factor)) unless uniform_energy_factor.nil?
    XMLHelper.add_element(water_heating_system, "RecoveryEfficiency", Float(recovery_efficiency)) unless recovery_efficiency.nil?
    unless jacket_r_value.nil?
      water_heater_insulation = XMLHelper.add_element(water_heating_system, "WaterHeaterInsulation")
      jacket = XMLHelper.add_element(water_heater_insulation, "Jacket")
      XMLHelper.add_element(jacket, "JacketRValue", jacket_r_value)
    end
    XMLHelper.add_element(water_heating_system, "UsesDesuperheater", Boolean(uses_desuperheater)) unless uses_desuperheater.nil?
    unless related_hvac.nil?
      related_hvac_el = XMLHelper.add_element(water_heating_system, "RelatedHVACSystem")
      XMLHelper.add_attribute(related_hvac_el, "idref", related_hvac)
    end

    return water_heating_system
  end

  def self.get_water_heating_system_values(water_heating_system:)
    return nil if water_heating_system.nil?

    return { :id => HPXML.get_id(water_heating_system),
             :year_installed => to_integer_or_nil(XMLHelper.get_value(water_heating_system, "YearInstalled")),
             :fuel_type => XMLHelper.get_value(water_heating_system, "FuelType"),
             :water_heater_type => XMLHelper.get_value(water_heating_system, "WaterHeaterType"),
             :location => XMLHelper.get_value(water_heating_system, "Location"),
             :performance_adjustment => to_float_or_nil(XMLHelper.get_value(water_heating_system, "PerformanceAdjustment")),
             :tank_volume => to_float_or_nil(XMLHelper.get_value(water_heating_system, "TankVolume")),
             :fraction_dhw_load_served => to_float_or_nil(XMLHelper.get_value(water_heating_system, "FractionDHWLoadServed")),
             :heating_capacity => to_float_or_nil(XMLHelper.get_value(water_heating_system, "HeatingCapacity")),
             :energy_factor => to_float_or_nil(XMLHelper.get_value(water_heating_system, "EnergyFactor")),
             :uniform_energy_factor => to_float_or_nil(XMLHelper.get_value(water_heating_system, "UniformEnergyFactor")),
             :recovery_efficiency => to_float_or_nil(XMLHelper.get_value(water_heating_system, "RecoveryEfficiency")),
             :uses_desuperheater => to_bool_or_nil(XMLHelper.get_value(water_heating_system, "UsesDesuperheater")),
             :jacket_r_value => to_float_or_nil(XMLHelper.get_value(water_heating_system, "WaterHeaterInsulation/Jacket/JacketRValue")),
             :related_hvac => HPXML.get_idref(water_heating_system, "RelatedHVACSystem"),
             :energy_star => XMLHelper.get_values(water_heating_system, "ThirdPartyCertification").include?("Energy Star") }
  end

  def self.add_hot_water_distribution(hpxml:,
                                      id:,
                                      system_type:,
                                      pipe_r_value:,
                                      standard_piping_length: nil,
                                      recirculation_control_type: nil,
                                      recirculation_piping_length: nil,
                                      recirculation_branch_piping_length: nil,
                                      recirculation_pump_power: nil,
                                      dwhr_facilities_connected: nil,
                                      dwhr_equal_flow: nil,
                                      dwhr_efficiency: nil,
                                      **remainder)
    water_heating = XMLHelper.create_elements_as_needed(hpxml, ["Building", "BuildingDetails", "Systems", "WaterHeating"])
    hot_water_distribution = XMLHelper.add_element(water_heating, "HotWaterDistribution")
    sys_id = XMLHelper.add_element(hot_water_distribution, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", id)
    system_type_e = XMLHelper.add_element(hot_water_distribution, "SystemType")
    if system_type == "Standard"
      standard = XMLHelper.add_element(system_type_e, system_type)
      XMLHelper.add_element(standard, "PipingLength", Float(standard_piping_length))
    elsif system_type == "Recirculation"
      recirculation = XMLHelper.add_element(system_type_e, system_type)
      XMLHelper.add_element(recirculation, "ControlType", recirculation_control_type)
      XMLHelper.add_element(recirculation, "RecirculationPipingLoopLength", Float(recirculation_piping_length))
      XMLHelper.add_element(recirculation, "BranchPipingLoopLength", Float(recirculation_branch_piping_length))
      XMLHelper.add_element(recirculation, "PumpPower", Float(recirculation_pump_power))
    else
      fail "Unhandled hot water distribution type '#{system_type}'."
    end
    pipe_insulation = XMLHelper.add_element(hot_water_distribution, "PipeInsulation")
    XMLHelper.add_element(pipe_insulation, "PipeRValue", Float(pipe_r_value))
    if not dwhr_facilities_connected.nil? or not dwhr_equal_flow.nil? or not dwhr_efficiency.nil?
      drain_water_heat_recovery = XMLHelper.add_element(hot_water_distribution, "DrainWaterHeatRecovery")
      XMLHelper.add_element(drain_water_heat_recovery, "FacilitiesConnected", dwhr_facilities_connected)
      XMLHelper.add_element(drain_water_heat_recovery, "EqualFlow", Boolean(dwhr_equal_flow))
      XMLHelper.add_element(drain_water_heat_recovery, "Efficiency", Float(dwhr_efficiency))
    end

    return hot_water_distribution
  end

  def self.get_hot_water_distribution_values(hot_water_distribution:)
    return nil if hot_water_distribution.nil?

    return { :id => HPXML.get_id(hot_water_distribution),
             :system_type => XMLHelper.get_child_name(hot_water_distribution, "SystemType"),
             :pipe_r_value => to_float_or_nil(XMLHelper.get_value(hot_water_distribution, "PipeInsulation/PipeRValue")),
             :standard_piping_length => to_float_or_nil(XMLHelper.get_value(hot_water_distribution, "SystemType/Standard/PipingLength")),
             :recirculation_control_type => XMLHelper.get_value(hot_water_distribution, "SystemType/Recirculation/ControlType"),
             :recirculation_piping_length => to_float_or_nil(XMLHelper.get_value(hot_water_distribution, "SystemType/Recirculation/RecirculationPipingLoopLength")),
             :recirculation_branch_piping_length => to_float_or_nil(XMLHelper.get_value(hot_water_distribution, "SystemType/Recirculation/BranchPipingLoopLength")),
             :recirculation_pump_power => to_float_or_nil(XMLHelper.get_value(hot_water_distribution, "SystemType/Recirculation/PumpPower")),
             :dwhr_facilities_connected => XMLHelper.get_value(hot_water_distribution, "DrainWaterHeatRecovery/FacilitiesConnected"),
             :dwhr_equal_flow => to_bool_or_nil(XMLHelper.get_value(hot_water_distribution, "DrainWaterHeatRecovery/EqualFlow")),
             :dwhr_efficiency => to_float_or_nil(XMLHelper.get_value(hot_water_distribution, "DrainWaterHeatRecovery/Efficiency")) }
  end

  def self.add_water_fixture(hpxml:,
                             id:,
                             water_fixture_type:,
                             low_flow:,
                             **remainder)
    water_heating = XMLHelper.create_elements_as_needed(hpxml, ["Building", "BuildingDetails", "Systems", "WaterHeating"])
    water_fixture = XMLHelper.add_element(water_heating, "WaterFixture")
    sys_id = XMLHelper.add_element(water_fixture, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", id)
    XMLHelper.add_element(water_fixture, "WaterFixtureType", water_fixture_type)
    XMLHelper.add_element(water_fixture, "LowFlow", Boolean(low_flow))

    return water_fixture
  end

  def self.get_water_fixture_values(water_fixture:)
    return nil if water_fixture.nil?

    return { :id => HPXML.get_id(water_fixture),
             :water_fixture_type => XMLHelper.get_value(water_fixture, "WaterFixtureType"),
             :low_flow => to_bool_or_nil(XMLHelper.get_value(water_fixture, "LowFlow")) }
  end

  def self.add_pv_system(hpxml:,
                         id:,
                         location:,
                         module_type:,
                         tracking:,
                         array_azimuth:,
                         array_tilt:,
                         max_power_output:,
                         inverter_efficiency:,
                         system_losses_fraction:,
                         **remainder)
    photovoltaics = XMLHelper.create_elements_as_needed(hpxml, ["Building", "BuildingDetails", "Systems", "Photovoltaics"])
    pv_system = XMLHelper.add_element(photovoltaics, "PVSystem")
    sys_id = XMLHelper.add_element(pv_system, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", id)
    XMLHelper.add_element(pv_system, "Location", location)
    XMLHelper.add_element(pv_system, "ModuleType", module_type)
    XMLHelper.add_element(pv_system, "Tracking", tracking)
    XMLHelper.add_element(pv_system, "ArrayAzimuth", Integer(array_azimuth))
    XMLHelper.add_element(pv_system, "ArrayTilt", Float(array_tilt))
    XMLHelper.add_element(pv_system, "MaxPowerOutput", Float(max_power_output))
    XMLHelper.add_element(pv_system, "InverterEfficiency", Float(inverter_efficiency))
    XMLHelper.add_element(pv_system, "SystemLossesFraction", Float(system_losses_fraction))

    return pv_system
  end

  def self.get_pv_system_values(pv_system:)
    return nil if pv_system.nil?

    return { :id => HPXML.get_id(pv_system),
             :location => XMLHelper.get_value(pv_system, "Location"),
             :module_type => XMLHelper.get_value(pv_system, "ModuleType"),
             :tracking => XMLHelper.get_value(pv_system, "Tracking"),
             :array_orientation => XMLHelper.get_value(pv_system, "ArrayOrientation"),
             :array_azimuth => to_integer_or_nil(XMLHelper.get_value(pv_system, "ArrayAzimuth")),
             :array_tilt => to_float_or_nil(XMLHelper.get_value(pv_system, "ArrayTilt")),
             :max_power_output => to_float_or_nil(XMLHelper.get_value(pv_system, "MaxPowerOutput")),
             :inverter_efficiency => to_float_or_nil(XMLHelper.get_value(pv_system, "InverterEfficiency")),
             :system_losses_fraction => to_float_or_nil(XMLHelper.get_value(pv_system, "SystemLossesFraction")),
             :number_of_panels => to_integer_or_nil(XMLHelper.get_value(pv_system, "NumberOfPanels")),
             :year_modules_manufactured => to_integer_or_nil(XMLHelper.get_value(pv_system, "YearModulesManufactured")) }
  end

  def self.add_clothes_washer(hpxml:,
                              id:,
                              location:,
                              modified_energy_factor: nil,
                              integrated_modified_energy_factor: nil,
                              rated_annual_kwh:,
                              label_electric_rate:,
                              label_gas_rate:,
                              label_annual_gas_cost:,
                              capacity:,
                              **remainder)
    appliances = XMLHelper.create_elements_as_needed(hpxml, ["Building", "BuildingDetails", "Appliances"])
    clothes_washer = XMLHelper.add_element(appliances, "ClothesWasher")
    sys_id = XMLHelper.add_element(clothes_washer, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", id)
    XMLHelper.add_element(clothes_washer, "Location", location)
    if not modified_energy_factor.nil?
      XMLHelper.add_element(clothes_washer, "ModifiedEnergyFactor", Float(modified_energy_factor))
    elsif not integrated_modified_energy_factor.nil?
      XMLHelper.add_element(clothes_washer, "IntegratedModifiedEnergyFactor", Float(integrated_modified_energy_factor))
    else
      fail "Either modified_energy_factor or integrated_modified_energy_factor must be provided."
    end
    XMLHelper.add_element(clothes_washer, "RatedAnnualkWh", Float(rated_annual_kwh))
    XMLHelper.add_element(clothes_washer, "LabelElectricRate", Float(label_electric_rate))
    XMLHelper.add_element(clothes_washer, "LabelGasRate", Float(label_gas_rate))
    XMLHelper.add_element(clothes_washer, "LabelAnnualGasCost", Float(label_annual_gas_cost))
    XMLHelper.add_element(clothes_washer, "Capacity", Float(capacity))

    return clothes_washer
  end

  def self.get_clothes_washer_values(clothes_washer:)
    return nil if clothes_washer.nil?

    return { :id => HPXML.get_id(clothes_washer),
             :location => XMLHelper.get_value(clothes_washer, "Location"),
             :modified_energy_factor => to_float_or_nil(XMLHelper.get_value(clothes_washer, "ModifiedEnergyFactor")),
             :integrated_modified_energy_factor => to_float_or_nil(XMLHelper.get_value(clothes_washer, "IntegratedModifiedEnergyFactor")),
             :rated_annual_kwh => to_float_or_nil(XMLHelper.get_value(clothes_washer, "RatedAnnualkWh")),
             :label_electric_rate => to_float_or_nil(XMLHelper.get_value(clothes_washer, "LabelElectricRate")),
             :label_gas_rate => to_float_or_nil(XMLHelper.get_value(clothes_washer, "LabelGasRate")),
             :label_annual_gas_cost => to_float_or_nil(XMLHelper.get_value(clothes_washer, "LabelAnnualGasCost")),
             :capacity => to_float_or_nil(XMLHelper.get_value(clothes_washer, "Capacity")) }
  end

  def self.add_clothes_dryer(hpxml:,
                             id:,
                             location:,
                             fuel_type:,
                             energy_factor: nil,
                             combined_energy_factor: nil,
                             control_type:,
                             **remainder)
    appliances = XMLHelper.create_elements_as_needed(hpxml, ["Building", "BuildingDetails", "Appliances"])
    clothes_dryer = XMLHelper.add_element(appliances, "ClothesDryer")
    sys_id = XMLHelper.add_element(clothes_dryer, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", id)
    XMLHelper.add_element(clothes_dryer, "Location", location)
    XMLHelper.add_element(clothes_dryer, "FuelType", fuel_type)
    if not energy_factor.nil?
      XMLHelper.add_element(clothes_dryer, "EnergyFactor", Float(energy_factor))
    elsif not combined_energy_factor.nil?
      XMLHelper.add_element(clothes_dryer, "CombinedEnergyFactor", Float(combined_energy_factor))
    else
      fail "Either energy_factor or combined_energy_factor must be provided."
    end
    XMLHelper.add_element(clothes_dryer, "ControlType", control_type)

    return clothes_dryer
  end

  def self.get_clothes_dryer_values(clothes_dryer:)
    return nil if clothes_dryer.nil?

    return { :id => HPXML.get_id(clothes_dryer),
             :location => XMLHelper.get_value(clothes_dryer, "Location"),
             :fuel_type => XMLHelper.get_value(clothes_dryer, "FuelType"),
             :energy_factor => to_float_or_nil(XMLHelper.get_value(clothes_dryer, "EnergyFactor")),
             :combined_energy_factor => to_float_or_nil(XMLHelper.get_value(clothes_dryer, "CombinedEnergyFactor")),
             :control_type => XMLHelper.get_value(clothes_dryer, "ControlType") }
  end

  def self.add_dishwasher(hpxml:,
                          id:,
                          energy_factor: nil,
                          rated_annual_kwh: nil,
                          place_setting_capacity:,
                          **remainder)
    appliances = XMLHelper.create_elements_as_needed(hpxml, ["Building", "BuildingDetails", "Appliances"])
    dishwasher = XMLHelper.add_element(appliances, "Dishwasher")
    sys_id = XMLHelper.add_element(dishwasher, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", id)
    if not energy_factor.nil?
      XMLHelper.add_element(dishwasher, "EnergyFactor", Float(energy_factor))
    elsif not rated_annual_kwh.nil?
      XMLHelper.add_element(dishwasher, "RatedAnnualkWh", Float(rated_annual_kwh))
    else
      fail "Either energy_factor or rated_annual_kwh must be provided."
    end
    XMLHelper.add_element(dishwasher, "PlaceSettingCapacity", Integer(place_setting_capacity)) unless place_setting_capacity.nil?

    return dishwasher
  end

  def self.get_dishwasher_values(dishwasher:)
    return nil if dishwasher.nil?

    return { :id => HPXML.get_id(dishwasher),
             :energy_factor => to_float_or_nil(XMLHelper.get_value(dishwasher, "EnergyFactor")),
             :rated_annual_kwh => to_float_or_nil(XMLHelper.get_value(dishwasher, "RatedAnnualkWh")),
             :place_setting_capacity => to_integer_or_nil(XMLHelper.get_value(dishwasher, "PlaceSettingCapacity")) }
  end

  def self.add_refrigerator(hpxml:,
                            id:,
                            location:,
                            rated_annual_kwh: nil,
                            adjusted_annual_kwh: nil,
                            **remainder)
    appliances = XMLHelper.create_elements_as_needed(hpxml, ["Building", "BuildingDetails", "Appliances"])
    refrigerator = XMLHelper.add_element(appliances, "Refrigerator")
    sys_id = XMLHelper.add_element(refrigerator, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", id)
    XMLHelper.add_element(refrigerator, "Location", location)
    XMLHelper.add_element(refrigerator, "RatedAnnualkWh", Float(rated_annual_kwh)) unless rated_annual_kwh.nil?
    HPXML.add_extension(parent: refrigerator,
                        extensions: { "AdjustedAnnualkWh": to_float_or_nil(adjusted_annual_kwh) })

    return refrigerator
  end

  def self.get_refrigerator_values(refrigerator:)
    return nil if refrigerator.nil?

    return { :id => HPXML.get_id(refrigerator),
             :location => XMLHelper.get_value(refrigerator, "Location"),
             :rated_annual_kwh => to_float_or_nil(XMLHelper.get_value(refrigerator, "RatedAnnualkWh")),
             :adjusted_annual_kwh => to_float_or_nil(XMLHelper.get_value(refrigerator, "extension/AdjustedAnnualkWh")) }
  end

  def self.add_cooking_range(hpxml:,
                             id:,
                             fuel_type:,
                             is_induction:,
                             **remainder)
    appliances = XMLHelper.create_elements_as_needed(hpxml, ["Building", "BuildingDetails", "Appliances"])
    cooking_range = XMLHelper.add_element(appliances, "CookingRange")
    sys_id = XMLHelper.add_element(cooking_range, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", id)
    XMLHelper.add_element(cooking_range, "FuelType", fuel_type)
    XMLHelper.add_element(cooking_range, "IsInduction", Boolean(is_induction))

    return cooking_range
  end

  def self.get_cooking_range_values(cooking_range:)
    return nil if cooking_range.nil?

    return { :id => HPXML.get_id(cooking_range),
             :fuel_type => XMLHelper.get_value(cooking_range, "FuelType"),
             :is_induction => to_bool_or_nil(XMLHelper.get_value(cooking_range, "IsInduction")) }
  end

  def self.add_oven(hpxml:,
                    id:,
                    is_convection:,
                    **remainder)
    appliances = XMLHelper.create_elements_as_needed(hpxml, ["Building", "BuildingDetails", "Appliances"])
    oven = XMLHelper.add_element(appliances, "Oven")
    sys_id = XMLHelper.add_element(oven, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", id)
    XMLHelper.add_element(oven, "IsConvection", Boolean(is_convection))

    return oven
  end

  def self.get_oven_values(oven:)
    return nil if oven.nil?

    return { :id => HPXML.get_id(oven),
             :is_convection => to_bool_or_nil(XMLHelper.get_value(oven, "IsConvection")) }
  end

  def self.add_lighting(hpxml:,
                        fraction_tier_i_interior:,
                        fraction_tier_i_exterior:,
                        fraction_tier_i_garage:,
                        fraction_tier_ii_interior:,
                        fraction_tier_ii_exterior:,
                        fraction_tier_ii_garage:,
                        **remainder)
    lighting = XMLHelper.create_elements_as_needed(hpxml, ["Building", "BuildingDetails", "Lighting"])

    lighting_group = XMLHelper.add_element(lighting, "LightingGroup")
    sys_id = XMLHelper.add_element(lighting_group, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "Lighting_TierI_Interior")
    XMLHelper.add_element(lighting_group, "Location", "interior")
    XMLHelper.add_element(lighting_group, "FractionofUnitsInLocation", Float(fraction_tier_i_interior))
    XMLHelper.add_element(lighting_group, "ThirdPartyCertification", "ERI Tier I")

    lighting_group = XMLHelper.add_element(lighting, "LightingGroup")
    sys_id = XMLHelper.add_element(lighting_group, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "Lighting_TierI_Exterior")
    XMLHelper.add_element(lighting_group, "Location", "exterior")
    XMLHelper.add_element(lighting_group, "FractionofUnitsInLocation", Float(fraction_tier_i_exterior))
    XMLHelper.add_element(lighting_group, "ThirdPartyCertification", "ERI Tier I")

    lighting_group = XMLHelper.add_element(lighting, "LightingGroup")
    sys_id = XMLHelper.add_element(lighting_group, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "Lighting_TierI_Garage")
    XMLHelper.add_element(lighting_group, "Location", "garage")
    XMLHelper.add_element(lighting_group, "FractionofUnitsInLocation", Float(fraction_tier_i_garage))
    XMLHelper.add_element(lighting_group, "ThirdPartyCertification", "ERI Tier I")

    lighting_group = XMLHelper.add_element(lighting, "LightingGroup")
    sys_id = XMLHelper.add_element(lighting_group, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "Lighting_TierII_Interior")
    XMLHelper.add_element(lighting_group, "Location", "interior")
    XMLHelper.add_element(lighting_group, "FractionofUnitsInLocation", Float(fraction_tier_ii_interior))
    XMLHelper.add_element(lighting_group, "ThirdPartyCertification", "ERI Tier II")

    lighting_group = XMLHelper.add_element(lighting, "LightingGroup")
    sys_id = XMLHelper.add_element(lighting_group, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "Lighting_TierII_Exterior")
    XMLHelper.add_element(lighting_group, "Location", "exterior")
    XMLHelper.add_element(lighting_group, "FractionofUnitsInLocation", Float(fraction_tier_ii_exterior))
    XMLHelper.add_element(lighting_group, "ThirdPartyCertification", "ERI Tier II")

    lighting_group = XMLHelper.add_element(lighting, "LightingGroup")
    sys_id = XMLHelper.add_element(lighting_group, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "Lighting_TierII_Garage")
    XMLHelper.add_element(lighting_group, "Location", "garage")
    XMLHelper.add_element(lighting_group, "FractionofUnitsInLocation", Float(fraction_tier_ii_garage))
    XMLHelper.add_element(lighting_group, "ThirdPartyCertification", "ERI Tier II")

    return lighting_group
  end

  def self.get_lighting_values(lighting:)
    return nil if lighting.nil?

    return { :fraction_tier_i_interior => to_float_or_nil(XMLHelper.get_value(lighting, "LightingGroup[ThirdPartyCertification='ERI Tier I' and Location='interior']/FractionofUnitsInLocation")),
             :fraction_tier_i_exterior => to_float_or_nil(XMLHelper.get_value(lighting, "LightingGroup[ThirdPartyCertification='ERI Tier I' and Location='exterior']/FractionofUnitsInLocation")),
             :fraction_tier_i_garage => to_float_or_nil(XMLHelper.get_value(lighting, "LightingGroup[ThirdPartyCertification='ERI Tier I' and Location='garage']/FractionofUnitsInLocation")),
             :fraction_tier_ii_interior => to_float_or_nil(XMLHelper.get_value(lighting, "LightingGroup[ThirdPartyCertification='ERI Tier II' and Location='interior']/FractionofUnitsInLocation")),
             :fraction_tier_ii_exterior => to_float_or_nil(XMLHelper.get_value(lighting, "LightingGroup[ThirdPartyCertification='ERI Tier II' and Location='exterior']/FractionofUnitsInLocation")),
             :fraction_tier_ii_garage => to_float_or_nil(XMLHelper.get_value(lighting, "LightingGroup[ThirdPartyCertification='ERI Tier II' and Location='garage']/FractionofUnitsInLocation")) }
  end

  def self.add_ceiling_fan(hpxml:,
                           id:,
                           efficiency: nil,
                           quantity: nil,
                           **remainder)
    lighting = XMLHelper.create_elements_as_needed(hpxml, ["Building", "BuildingDetails", "Lighting"])
    ceiling_fan = XMLHelper.add_element(lighting, "CeilingFan")
    sys_id = XMLHelper.add_element(ceiling_fan, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", id)
    if not efficiency.nil?
      airflow = XMLHelper.add_element(ceiling_fan, "Airflow")
      XMLHelper.add_element(airflow, "FanSpeed", "medium")
      XMLHelper.add_element(airflow, "Efficiency", Float(efficiency))
    end
    XMLHelper.add_element(ceiling_fan, "Quantity", Integer(quantity)) unless quantity.nil?

    return ceiling_fan
  end

  def self.get_ceiling_fan_values(ceiling_fan:)
    return nil if ceiling_fan.nil?

    return { :id => HPXML.get_id(ceiling_fan),
             :efficiency => to_float_or_nil(XMLHelper.get_value(ceiling_fan, "Airflow[FanSpeed='medium']/Efficiency")),
             :quantity => to_integer_or_nil(XMLHelper.get_value(ceiling_fan, "Quantity")) }
  end

  def self.add_plug_load(hpxml:,
                         id:,
                         plug_load_type: nil,
                         kWh_per_year: nil,
                         frac_sensible: nil,
                         frac_latent: nil,
                         **remainder)
    misc_loads = XMLHelper.create_elements_as_needed(hpxml, ["Building", "BuildingDetails", "MiscLoads"])
    plug_load = XMLHelper.add_element(misc_loads, "PlugLoad")
    sys_id = XMLHelper.add_element(plug_load, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", id)
    XMLHelper.add_element(plug_load, "PlugLoadType", plug_load_type) unless plug_load_type.nil?
    if not kWh_per_year.nil?
      load = XMLHelper.add_element(plug_load, "Load")
      XMLHelper.add_element(load, "Units", "kWh/year")
      XMLHelper.add_element(load, "Value", Float(kWh_per_year))
    end
    HPXML.add_extension(parent: plug_load,
                        extensions: { "FracSensible": to_float_or_nil(frac_sensible),
                                      "FracLatent": to_float_or_nil(frac_latent) })

    return plug_load
  end

  def self.get_plug_load_values(plug_load:)
    return nil if plug_load.nil?

    return { :id => HPXML.get_id(plug_load),
             :plug_load_type => XMLHelper.get_value(plug_load, "PlugLoadType"),
             :kWh_per_year => to_float_or_nil(XMLHelper.get_value(plug_load, "Load[Units='kWh/year']/Value")),
             :frac_sensible => to_float_or_nil(XMLHelper.get_value(plug_load, "extension/FracSensible")),
             :frac_latent => to_float_or_nil(XMLHelper.get_value(plug_load, "extension/FracLatent")) }
  end

  def self.add_misc_loads_schedule(hpxml:,
                                   weekday_fractions: nil,
                                   weekend_fractions: nil,
                                   monthly_multipliers: nil,
                                   **remainder)
    misc_loads = XMLHelper.create_elements_as_needed(hpxml, ["Building", "BuildingDetails", "MiscLoads"])
    HPXML.add_extension(parent: misc_loads,
                        extensions: { "WeekdayScheduleFractions": weekday_fractions,
                                      "WeekendScheduleFractions": weekend_fractions,
                                      "MonthlyScheduleMultipliers": monthly_multipliers })

    return misc_loads
  end

  def self.get_misc_loads_schedule_values(misc_loads:)
    return nil if misc_loads.nil?

    return { :weekday_fractions => XMLHelper.get_value(misc_loads, "extension/WeekdayScheduleFractions"),
             :weekend_fractions => XMLHelper.get_value(misc_loads, "extension/WeekendScheduleFractions"),
             :monthly_multipliers => XMLHelper.get_value(misc_loads, "extension/MonthlyScheduleMultipliers") }
  end

  def self.add_assembly_insulation(parent:,
                                   id: nil,
                                   assembly_r_value: nil,
                                   **remainder)
    insulation = XMLHelper.add_element(parent, "Insulation")
    sys_id = XMLHelper.add_element(insulation, "SystemIdentifier")
    unless id.nil?
      XMLHelper.add_attribute(sys_id, "id", id)
    else
      XMLHelper.add_attribute(sys_id, "id", HPXML.get_id(parent) + "Insulation")
    end
    XMLHelper.add_element(insulation, "AssemblyEffectiveRValue", Float(assembly_r_value)) unless assembly_r_value.nil?

    return insulation
  end

  def self.get_assembly_insulation_values(insulation:)
    return {} if insulation.nil?

    return { :id => HPXML.get_id(insulation),
             :assembly_r_value => to_float_or_nil(XMLHelper.get_value(insulation, "AssemblyEffectiveRValue")) }
  end

  def self.add_layer_insulation(parent:,
                                element_name:,
                                id: nil,
                                cavity_nominal_r_value: nil,
                                continuous_nominal_r_value: nil,
                                **remainder)
    insulation = XMLHelper.add_element(parent, element_name)
    sys_id = XMLHelper.add_element(insulation, "SystemIdentifier")
    unless id.nil?
      XMLHelper.add_attribute(sys_id, "id", id)
    else
      XMLHelper.add_attribute(sys_id, "id", HPXML.get_id(parent) + element_name)
    end
    unless cavity_nominal_r_value.nil?
      layer = XMLHelper.add_element(insulation, "Layer")
      XMLHelper.add_element(layer, "InstallationType", "cavity")
      XMLHelper.add_element(layer, "NominalRValue", Float(cavity_nominal_r_value)) unless cavity_nominal_r_value.nil?
    end
    unless continuous_nominal_r_value.nil?
      layer = XMLHelper.add_element(insulation, "Layer")
      XMLHelper.add_element(layer, "InstallationType", "continuous")
      XMLHelper.add_element(layer, "NominalRValue", Float(continuous_nominal_r_value)) unless continuous_nominal_r_value.nil?
    end

    return insulation
  end

  def self.get_layer_insulation_values(insulation:)
    return {} if insulation.nil?

    return { :id => HPXML.get_id(insulation),
             :cavity_nominal_r_value => to_float_or_nil(XMLHelper.get_value(insulation, "Layer[InstallationType='cavity']/NominalRValue")),
             :continuous_nominal_r_value => to_float_or_nil(XMLHelper.get_value(insulation, "Layer[InstallationType='continuous']/NominalRValue")) }
  end

  def self.add_extension(parent:,
                         extensions: {})
    extension = nil
    unless extensions.empty?
      extensions.each do |name, value|
        next if value.nil?

        extension = parent.elements["extension"]
        if extension.nil?
          extension = XMLHelper.add_element(parent, "extension")
        end
        XMLHelper.add_element(extension, "#{name}", value) unless value.nil?
      end
    end

    return extension
  end

  private

  def self.get_id(parent, element_name = "SystemIdentifier")
    return parent.elements[element_name].attributes["id"]
  end

  def self.get_idref(parent, element_name)
    element = parent.elements[element_name]
    return if element.nil?

    return element.attributes["idref"]
  end

  def self.to_float_or_nil(value)
    return nil if value.nil?

    return Float(value)
  end

  def self.to_integer_or_nil(value)
    return nil if value.nil?

    return Integer(Float(value))
  end

  def self.to_bool_or_nil(value)
    return nil if value.nil?

    return Boolean(value)
  end
end
