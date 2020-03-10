require_relative 'xmlhelper'

'''

Example Usage:

-----------------
Reading from file
-----------------

hpxml = HPXML.new(hpxml_path: ...)

# Singleton elements
puts hpxml.building_construction.number_of_bedrooms

# Array elements
hpxml.walls.each do |wall|
  puts wall.area
end
puts hpxml.walls[0].area

---------------------
Creating from scratch
---------------------

hpxml = HPXML.new()

# Singleton elements
hpxml.set_clothes_washer(:id => "MyClothesWasher",
                         :modified_energy_factor => 0.83)
if not hpxml.clothes_washer.nil?
  puts hpxml.clothes_washer.to_s
end

# Array elements
hpxml.walls.add(:id => "WallNorth", :area => 500)
hpxml.walls.add(:id => "WallSouth", :area => 500)
hpxml.walls.delete_at(1)

'''

class HPXML < Object
  def initialize(hpxml_path: nil, collapse_enclosure: true)
    @doc = nil
    @hpxml_path = hpxml_path
    from_hpxml(hpxml_path)
    if collapse_enclosure
      _collapse_enclosure_surfaces()
    end
  end

  def set_header(**kwargs)
    @header = Header.new(**kwargs)
  end

  def set_site(**kwargs)
    @site = Site.new(**kwargs)
  end

  def set_building_occupancy(**kwargs)
    @building_occupancy = BuildingOccupancy.new(**kwargs)
  end

  def set_building_construction(**kwargs)
    @building_construction = BuildingConstruction.new(**kwargs)
  end

  def set_climate_and_risk_zones(**kwargs)
    @climate_and_risk_zones = ClimateandRiskZones.new(**kwargs)
  end

  def set_hvac_control(**kwargs)
    @hvac_control = HVACControl.new(**kwargs)
  end

  def set_hot_water_distribution(**kwargs)
    @hot_water_distribution = HotWaterDistribution.new(**kwargs)
  end

  def set_solar_thermal_system(**kwargs)
    @solar_thermal_system = SolarThermalSystem.new(**kwargs)
  end

  def set_clothes_washer(**kwargs)
    @clothes_washer = ClothesWasher.new(**kwargs)
  end

  def set_clothes_dryer(**kwargs)
    @clothes_dryer = ClothesDryer.new(**kwargs)
  end

  def set_dishwasher(**kwargs)
    @dishwasher = Dishwasher.new(**kwargs)
  end

  def set_refrigerator(**kwargs)
    @refrigerator = Refrigerator.new(**kwargs)
  end

  def set_cooking_range(**kwargs)
    @cooking_range = CookingRange.new(**kwargs)
  end

  def set_oven(**kwargs)
    @oven = Oven.new(**kwargs)
  end

  def set_lighting(**kwargs)
    @lighting = Lighting.new(**kwargs)
  end

  def set_misc_loads_schedule(**kwargs)
    @misc_loads_schedule = MiscLoadsSchedule.new(**kwargs)
  end

  def to_rexml()
    @doc = _create_rexml_document()
    @header.to_rexml(@doc)
    @site.to_rexml(@doc)
    @neighbor_buildings.to_rexml(@doc)
    @building_occupancy.to_rexml(@doc)
    @building_construction.to_rexml(@doc)
    @climate_and_risk_zones.to_rexml(@doc)
    @air_infiltration_measurements.to_rexml(@doc)
    @attics.to_rexml(@doc)
    @foundations.to_rexml(@doc)
    @roofs.to_rexml(@doc)
    @rim_joists.to_rexml(@doc)
    @walls.to_rexml(@doc)
    @foundation_walls.to_rexml(@doc)
    @frame_floors.to_rexml(@doc)
    @slabs.to_rexml(@doc)
    @windows.to_rexml(@doc)
    @skylights.to_rexml(@doc)
    @doors.to_rexml(@doc)
    @heating_systems.to_rexml(@doc)
    @cooling_systems.to_rexml(@doc)
    @heat_pumps.to_rexml(@doc)
    @hvac_control.to_rexml(@doc)
    @hvac_distributions.to_rexml(@doc)
    @ventilation_fans.to_rexml(@doc)
    @water_heating_systems.to_rexml(@doc)
    @hot_water_distribution.to_rexml(@doc)
    @water_fixtures.to_rexml(@doc)
    @solar_thermal_system.to_rexml(@doc)
    @pv_systems.to_rexml(@doc)
    @clothes_washer.to_rexml(@doc)
    @clothes_dryer.to_rexml(@doc)
    @dishwasher.to_rexml(@doc)
    @refrigerator.to_rexml(@doc)
    @cooking_range.to_rexml(@doc)
    @oven.to_rexml(@doc)
    @lighting.to_rexml(@doc)
    @ceiling_fans.to_rexml(@doc)
    @plug_loads.to_rexml(@doc)
    @misc_loads_schedule.to_rexml(@doc)
    return @doc
  end

  def from_hpxml(hpxml_path)
    hpxml = nil
    if not hpxml_path.nil?
      @doc = XMLHelper.parse_file(hpxml_path)
      hpxml = @doc.elements['/HPXML']
    end
    @header = Header.new(hpxml)
    @site = Site.new(hpxml)
    @neighbor_buildings = NeighborBuildings.new(hpxml)
    @building_occupancy = BuildingOccupancy.new(hpxml)
    @building_construction = BuildingConstruction.new(hpxml)
    @climate_and_risk_zones = ClimateandRiskZones.new(hpxml)
    @air_infiltration_measurements = AirInfiltrationMeasurements.new(hpxml)
    @attics = Attics.new(hpxml)
    @foundations = Foundations.new(hpxml)
    @roofs = Roofs.new(hpxml)
    @rim_joists = RimJoists.new(hpxml)
    @walls = Walls.new(hpxml)
    @foundation_walls = FoundationWalls.new(hpxml)
    @frame_floors = FrameFloors.new(hpxml)
    @slabs = Slabs.new(hpxml)
    @windows = Windows.new(hpxml)
    @skylights = Skylights.new(hpxml)
    @doors = Doors.new(hpxml)
    @heating_systems = HeatingSystems.new(hpxml)
    @cooling_systems = CoolingSystems.new(hpxml)
    @heat_pumps = HeatPumps.new(hpxml)
    @hvac_control = HVACControl.new(hpxml)
    @hvac_distributions = HVACDistributions.new(hpxml)
    @ventilation_fans = VentilationFans.new(hpxml)
    @water_heating_systems = WaterHeatingSystems.new(hpxml)
    @hot_water_distribution = HotWaterDistribution.new(hpxml)
    @water_fixtures = WaterFixtures.new(hpxml)
    @solar_thermal_system = SolarThermalSystem.new(hpxml)
    @pv_systems = PVSystems.new(hpxml)
    @clothes_washer = ClothesWasher.new(hpxml)
    @clothes_dryer = ClothesDryer.new(hpxml)
    @dishwasher = Dishwasher.new(hpxml)
    @refrigerator = Refrigerator.new(hpxml)
    @cooking_range = CookingRange.new(hpxml)
    @oven = Oven.new(hpxml)
    @lighting = Lighting.new(hpxml)
    @ceiling_fans = CeilingFans.new(hpxml)
    @plug_loads = PlugLoads.new(hpxml)
    @misc_loads_schedule = MiscLoadsSchedule.new(hpxml)
  end

  class BaseElement
    def initialize(hpxml_obj = nil, **kwargs)
      if not hpxml_obj.nil?
        # Set values from HPXML object
        from_hpxml(hpxml_obj)
      else
        # Set values from **kwargs
        kwargs.each do |k, v|
          self.send(k.to_s + "=", v)
        end
      end
    end

    def to_h
      h = {}
      self.class::ATTRS.each do |attribute|
        h[attribute] = self.send(attribute)
      end
      return h
    end

    def to_s
      return to_h.to_s
    end

    def nil?
      # Returns true if all attributes are nil
      to_h.each do |k, v|
        return false if not v.nil?
      end
      return true
    end
  end

  class BaseArrayElement < Array
    def initialize(hpxml_obj = nil)
      if not hpxml_obj.nil?
        # Set values from HPXML object
        from_hpxml(hpxml_obj)
      end
    end

    def to_rexml(doc)
      self.each do |child|
        child.to_rexml(doc)
      end
    end
  end

  class Header < BaseElement
    ATTRS = [:xml_type, :xml_generated_by, :created_date_and_time, :transaction,
             :software_program_used, :software_program_version, :eri_calculation_version,
             :eri_design, :timestep, :building_id, :event_type, :state_code]
    attr_accessor(*ATTRS)

    def to_rexml(doc)
      return if self.nil?

      hpxml = doc.elements["/HPXML"]
      header = XMLHelper.add_element(hpxml, "XMLTransactionHeaderInformation")
      XMLHelper.add_element(header, "XMLType", @xml_type)
      XMLHelper.add_element(header, "XMLGeneratedBy", @xml_generated_by)
      if not @created_date_and_time.nil?
        XMLHelper.add_element(header, "CreatedDateAndTime", @created_date_and_time)
      else
        XMLHelper.add_element(header, "CreatedDateAndTime", Time.now.strftime("%Y-%m-%dT%H:%M:%S%:z"))
      end
      XMLHelper.add_element(header, "Transaction", @transaction)

      software_info = XMLHelper.add_element(hpxml, "SoftwareInfo")
      XMLHelper.add_element(software_info, "SoftwareProgramUsed", @software_program_used) unless @software_program_used.nil?
      XMLHelper.add_element(software_info, "SoftwareProgramVersion", software_program_version) unless software_program_version.nil?
      _add_extension(parent: software_info,
                     extensions: { "ERICalculation/Version" => @eri_calculation_version,
                                   "ERICalculation/Design" => @eri_design,
                                   "SimulationControl/Timestep" => _to_integer_or_nil(@timestep) })

      building = XMLHelper.add_element(hpxml, "Building")
      building_building_id = XMLHelper.add_element(building, "BuildingID")
      XMLHelper.add_attribute(building_building_id, "id", @building_id)
      project_status = XMLHelper.add_element(building, "ProjectStatus")
      XMLHelper.add_element(project_status, "EventType", @event_type)
    end

    def from_hpxml(hpxml)
      return if hpxml.nil?

      @xml_type = XMLHelper.get_value(hpxml, "XMLTransactionHeaderInformation/XMLType")
      @xml_generated_by = XMLHelper.get_value(hpxml, "XMLTransactionHeaderInformation/XMLGeneratedBy")
      @created_date_and_time = XMLHelper.get_value(hpxml, "XMLTransactionHeaderInformation/CreatedDateAndTime")
      @transaction = XMLHelper.get_value(hpxml, "XMLTransactionHeaderInformation/Transaction")
      @software_program_used = XMLHelper.get_value(hpxml, "SoftwareInfo/SoftwareProgramUsed")
      @software_program_version = XMLHelper.get_value(hpxml, "SoftwareInfo/SoftwareProgramVersion")
      @eri_calculation_version = XMLHelper.get_value(hpxml, "SoftwareInfo/extension/ERICalculation/Version")
      @eri_design = XMLHelper.get_value(hpxml, "SoftwareInfo/extension/ERICalculation/Design")
      @timestep = _to_integer_or_nil(XMLHelper.get_value(hpxml, "SoftwareInfo/extension/SimulationControl/Timestep"))
      @building_id = _get_id(hpxml, "Building/BuildingID")
      @event_type = XMLHelper.get_value(hpxml, "Building/ProjectStatus/EventType")
      @state_code = XMLHelper.get_value(hpxml, "Building/Site/Address/StateCode")
    end
  end

  class Site < BaseElement
    ATTRS = [:surroundings, :orientation_of_front_of_home, :fuels, :shelter_coefficient]
    attr_accessor(*ATTRS)

    def to_rexml(doc)
      return if self.nil?

      site = XMLHelper.create_elements_as_needed(doc, ["HPXML", "Building", "BuildingDetails", "BuildingSummary", "Site"])
      if not @fuels.empty?
        fuel_types_available = XMLHelper.add_element(site, "FuelTypesAvailable")
        @fuels.each do |fuel|
          XMLHelper.add_element(fuel_types_available, "Fuel", fuel)
        end
      end
      _add_extension(parent: site,
                     extensions: { "ShelterCoefficient" => _to_float_or_nil(@shelter_coefficient) })
    end

    def from_hpxml(hpxml)
      return if hpxml.nil?

      site = hpxml.elements["Building/BuildingDetails/BuildingSummary/Site"]
      return if site.nil?

      @surroundings = XMLHelper.get_value(site, "Surroundings")
      @orientation_of_front_of_home = XMLHelper.get_value(site, "OrientationOfFrontOfHome")
      @fuels = XMLHelper.get_values(site, "FuelTypesAvailable/Fuel")
      @shelter_coefficient = _to_float_or_nil(XMLHelper.get_value(site, "extension/ShelterCoefficient"))
    end
  end

  class NeighborBuildings < BaseArrayElement
    def add(**kwargs)
      self << NeighborBuilding.new(**kwargs)
    end

    def from_hpxml(hpxml)
      return if hpxml.nil?

      hpxml.elements.each("Building/BuildingDetails/BuildingSummary/Site/extension/Neighbors/NeighborBuilding") do |neighbor_building|
        self << NeighborBuilding.new(neighbor_building)
      end
    end
  end

  class NeighborBuilding < BaseElement
    ATTRS = [:azimuth, :distance, :height]
    attr_accessor(*ATTRS)

    def to_rexml(doc)
      return if self.nil?

      neighbors = XMLHelper.create_elements_as_needed(doc, ["HPXML", "Building", "BuildingDetails", "BuildingSummary", "Site", "extension", "Neighbors"])
      neighbor_building = XMLHelper.add_element(neighbors, "NeighborBuilding")
      XMLHelper.add_element(neighbor_building, "Azimuth", Integer(@azimuth)) unless @azimuth.nil?
      XMLHelper.add_element(neighbor_building, "Distance", Float(@distance)) unless @distance.nil?
      XMLHelper.add_element(neighbor_building, "Height", Float(@height)) unless @height.nil?
    end

    def from_hpxml(neighbor_building)
      return if neighbor_building.nil?

      @azimuth = _to_integer_or_nil(XMLHelper.get_value(neighbor_building, "Azimuth"))
      @distance = _to_float_or_nil(XMLHelper.get_value(neighbor_building, "Distance"))
      @height = _to_float_or_nil(XMLHelper.get_value(neighbor_building, "Height"))
    end
  end

  class BuildingOccupancy < BaseElement
    ATTRS = [:number_of_residents, :schedules_output_path, :schedules_column_name]
    attr_accessor(*ATTRS)

    def to_rexml(doc)
      return if self.nil?

      building_occupancy = XMLHelper.create_elements_as_needed(doc, ["HPXML", "Building", "BuildingDetails", "BuildingSummary", "BuildingOccupancy"])
      XMLHelper.add_element(building_occupancy, "NumberofResidents", Float(@number_of_residents)) unless @number_of_residents.nil?
      _add_extension(parent: building_occupancy,
                     extensions: { "SchedulesOutputPath": schedules_output_path,
                                   "SchedulesColumnName": schedules_column_name })
    end

    def from_hpxml(hpxml)
      return if hpxml.nil?

      building_occupancy = hpxml.elements["Building/BuildingDetails/BuildingSummary/BuildingOccupancy"]
      return if building_occupancy.nil?

      @number_of_residents = _to_float_or_nil(XMLHelper.get_value(building_occupancy, "NumberofResidents"))
      @schedules_output_path = XMLHelper.get_value(building_occupancy, "extension/SchedulesOutputPath")
      @schedules_column_name = XMLHelper.get_value(building_occupancy, "extension/SchedulesColumnName")
    end
  end

  class BuildingConstruction < BaseElement
    ATTRS = [:year_built, :number_of_conditioned_floors, :number_of_conditioned_floors_above_grade,
             :average_ceiling_height, :number_of_bedrooms, :number_of_bathrooms,
             :conditioned_floor_area, :conditioned_building_volume, :use_only_ideal_air_system,
             :residential_facility_type, :fraction_of_operable_window_area]
    attr_accessor(*ATTRS)

    def to_rexml(doc)
      return if self.nil?

      building_construction = XMLHelper.create_elements_as_needed(doc, ["HPXML", "Building", "BuildingDetails", "BuildingSummary", "BuildingConstruction"])
      XMLHelper.add_element(building_construction, "NumberofConditionedFloors", Integer(@number_of_conditioned_floors)) unless @number_of_conditioned_floors.nil?
      XMLHelper.add_element(building_construction, "NumberofConditionedFloorsAboveGrade", Integer(@number_of_conditioned_floors_above_grade)) unless @number_of_conditioned_floors_above_grade.nil?
      XMLHelper.add_element(building_construction, "NumberofBedrooms", Integer(@number_of_bedrooms)) unless @number_of_bedrooms.nil?
      XMLHelper.add_element(building_construction, "NumberofBathrooms", Integer(@number_of_bathrooms)) unless @number_of_bathrooms.nil?
      XMLHelper.add_element(building_construction, "ConditionedFloorArea", Float(@conditioned_floor_area)) unless @conditioned_floor_area.nil?
      XMLHelper.add_element(building_construction, "ConditionedBuildingVolume", Float(@conditioned_building_volume)) unless @conditioned_building_volume.nil?
      _add_extension(parent: building_construction,
                     extensions: { "FractionofOperableWindowArea" => _to_float_or_nil(@fraction_of_operable_window_area),
                                   "UseOnlyIdealAirSystem" => _to_bool_or_nil(@use_only_ideal_air_system) })
    end

    def from_hpxml(hpxml)
      return if hpxml.nil?

      building_construction = hpxml.elements["Building/BuildingDetails/BuildingSummary/BuildingConstruction"]
      return if building_construction.nil?

      @year_built = _to_integer_or_nil(XMLHelper.get_value(building_construction, "YearBuilt"))
      @number_of_conditioned_floors = _to_integer_or_nil(XMLHelper.get_value(building_construction, "NumberofConditionedFloors"))
      @number_of_conditioned_floors_above_grade = _to_integer_or_nil(XMLHelper.get_value(building_construction, "NumberofConditionedFloorsAboveGrade"))
      @average_ceiling_height = _to_float_or_nil(XMLHelper.get_value(building_construction, "AverageCeilingHeight"))
      @number_of_bedrooms = _to_integer_or_nil(XMLHelper.get_value(building_construction, "NumberofBedrooms"))
      @number_of_bathrooms = _to_integer_or_nil(XMLHelper.get_value(building_construction, "NumberofBathrooms"))
      @conditioned_floor_area = _to_float_or_nil(XMLHelper.get_value(building_construction, "ConditionedFloorArea"))
      @conditioned_building_volume = _to_float_or_nil(XMLHelper.get_value(building_construction, "ConditionedBuildingVolume"))
      @use_only_ideal_air_system = _to_bool_or_nil(XMLHelper.get_value(building_construction, "extension/UseOnlyIdealAirSystem"))
      @residential_facility_type = XMLHelper.get_value(building_construction, "ResidentialFacilityType")
      @fraction_of_operable_window_area = _to_float_or_nil(XMLHelper.get_value(building_construction, "extension/FractionofOperableWindowArea"))
    end
  end

  class ClimateandRiskZones < BaseElement
    ATTRS = [:iecc2006, :iecc2012, :weather_station_id, :weather_station_name, :weather_station_wmo,
             :weather_station_epw_filename]
    attr_accessor(*ATTRS)

    def to_rexml(doc)
      return if self.nil?

      climate_and_risk_zones = XMLHelper.create_elements_as_needed(doc, ["HPXML", "Building", "BuildingDetails", "ClimateandRiskZones"])

      climate_zones = { 2006 => @iecc2006,
                        2012 => @iecc2012 }
      climate_zones.each do |year, zone|
        next if zone.nil?

        climate_zone_iecc = XMLHelper.add_element(climate_and_risk_zones, "ClimateZoneIECC")
        XMLHelper.add_element(climate_zone_iecc, "Year", Integer(year)) unless year.nil?
        XMLHelper.add_element(climate_zone_iecc, "ClimateZone", zone) unless zone.nil?
      end

      if not @weather_station_id.nil?
        weather_station = XMLHelper.add_element(climate_and_risk_zones, "WeatherStation")
        sys_id = XMLHelper.add_element(weather_station, "SystemIdentifier")
        XMLHelper.add_attribute(sys_id, "id", @weather_station_id)
        XMLHelper.add_element(weather_station, "Name", @weather_station_name) unless @weather_station_name.nil?
        XMLHelper.add_element(weather_station, "WMO", @weather_station_wmo) unless @weather_station_wmo.nil?
        _add_extension(parent: weather_station,
                       extensions: { "EPWFileName" => @weather_station_epw_filename })
      end
    end

    def from_hpxml(hpxml)
      return if hpxml.nil?

      climate_and_risk_zones = hpxml.elements["Building/BuildingDetails/ClimateandRiskZones"]
      return if climate_and_risk_zones.nil?

      @iecc2006 = XMLHelper.get_value(climate_and_risk_zones, "ClimateZoneIECC[Year=2006]/ClimateZone")
      @iecc2012 = XMLHelper.get_value(climate_and_risk_zones, "ClimateZoneIECC[Year=2012]/ClimateZone")
      weather_station = climate_and_risk_zones.elements["WeatherStation"]
      if not weather_station.nil?
        @weather_station_id = _get_id(weather_station)
        @weather_station_name = XMLHelper.get_value(weather_station, "Name")
        @weather_station_wmo = XMLHelper.get_value(weather_station, "WMO")
        @weather_station_epw_filename = XMLHelper.get_value(weather_station, "extension/EPWFileName")
      end
    end
  end

  class AirInfiltrationMeasurements < BaseArrayElement
    def add(**kwargs)
      self << AirInfiltrationMeasurement.new(**kwargs)
    end

    def from_hpxml(hpxml)
      return if hpxml.nil?

      hpxml.elements.each("Building/BuildingDetails/Enclosure/AirInfiltration/AirInfiltrationMeasurement") do |air_infiltration_measurement|
        self << AirInfiltrationMeasurement.new(air_infiltration_measurement)
      end
    end
  end

  class AirInfiltrationMeasurement < BaseElement
    ATTRS = [:id, :house_pressure, :unit_of_measure, :air_leakage, :effective_leakage_area,
             :infiltration_volume, :constant_ach_natural, :leakiness_description]
    attr_accessor(*ATTRS)

    def to_rexml(doc)
      return if self.nil?

      air_infiltration = XMLHelper.create_elements_as_needed(doc, ["HPXML", "Building", "BuildingDetails", "Enclosure", "AirInfiltration"])
      air_infiltration_measurement = XMLHelper.add_element(air_infiltration, "AirInfiltrationMeasurement")
      sys_id = XMLHelper.add_element(air_infiltration_measurement, "SystemIdentifier")
      XMLHelper.add_attribute(sys_id, "id", @id)
      XMLHelper.add_element(air_infiltration_measurement, "HousePressure", Float(@house_pressure)) unless @house_pressure.nil?
      if not @unit_of_measure.nil? and not @air_leakage.nil?
        building_air_leakage = XMLHelper.add_element(air_infiltration_measurement, "BuildingAirLeakage")
        XMLHelper.add_element(building_air_leakage, "UnitofMeasure", @unit_of_measure)
        XMLHelper.add_element(building_air_leakage, "AirLeakage", Float(@air_leakage))
      end
      XMLHelper.add_element(air_infiltration_measurement, "EffectiveLeakageArea", Float(@effective_leakage_area)) unless @effective_leakage_area.nil?
      XMLHelper.add_element(air_infiltration_measurement, "InfiltrationVolume", Float(@infiltration_volume)) unless @infiltration_volume.nil?
      _add_extension(parent: air_infiltration_measurement,
                     extensions: { "ConstantACHnatural" => _to_float_or_nil(@constant_ach_natural) })
    end

    def from_hpxml(air_infiltration_measurement)
      return if air_infiltration_measurement.nil?

      @id = _get_id(air_infiltration_measurement)
      @house_pressure = _to_float_or_nil(XMLHelper.get_value(air_infiltration_measurement, "HousePressure"))
      @unit_of_measure = XMLHelper.get_value(air_infiltration_measurement, "BuildingAirLeakage/UnitofMeasure")
      @air_leakage = _to_float_or_nil(XMLHelper.get_value(air_infiltration_measurement, "BuildingAirLeakage/AirLeakage"))
      @effective_leakage_area = _to_float_or_nil(XMLHelper.get_value(air_infiltration_measurement, "EffectiveLeakageArea"))
      @infiltration_volume = _to_float_or_nil(XMLHelper.get_value(air_infiltration_measurement, "InfiltrationVolume"))
      @constant_ach_natural = _to_float_or_nil(XMLHelper.get_value(air_infiltration_measurement, "extension/ConstantACHnatural"))
      @leakiness_description = XMLHelper.get_value(air_infiltration_measurement, "LeakinessDescription")
    end
  end

  class Attics < BaseArrayElement
    def add(**kwargs)
      self << Attic.new(**kwargs)
    end

    def from_hpxml(hpxml)
      return if hpxml.nil?

      hpxml.elements.each("Building/BuildingDetails/Enclosure/Attics/Attic") do |attic|
        self << Attic.new(attic)
      end
    end
  end

  class Attic < BaseElement
    ATTRS = [:id, :attic_type, :vented_attic_sla, :vented_attic_constant_ach,
             :attached_to_roofs, :attached_to_frame_floors]
    attr_accessor(*ATTRS)

    def to_rexml(doc)
      return if self.nil?

      attics = XMLHelper.create_elements_as_needed(doc, ["HPXML", "Building", "BuildingDetails", "Enclosure", "Attics"])
      attic = XMLHelper.add_element(attics, "Attic")
      sys_id = XMLHelper.add_element(attic, "SystemIdentifier")
      XMLHelper.add_attribute(sys_id, "id", @id)
      if not @attic_type.nil?
        attic_type_e = XMLHelper.add_element(attic, "AtticType")
        if @attic_type == "UnventedAttic"
          attic_type_attic = XMLHelper.add_element(attic_type_e, "Attic")
          XMLHelper.add_element(attic_type_attic, "Vented", false)
        elsif @attic_type == "VentedAttic"
          attic_type_attic = XMLHelper.add_element(attic_type_e, "Attic")
          XMLHelper.add_element(attic_type_attic, "Vented", true)
          if not @vented_attic_sla.nil?
            ventilation_rate = XMLHelper.add_element(attic, "VentilationRate")
            XMLHelper.add_element(ventilation_rate, "UnitofMeasure", "SLA")
            XMLHelper.add_element(ventilation_rate, "Value", Float(@vented_attic_sla))
          end
          if not @vented_attic_constant_ach.nil?
            XMLHelper.add_element(attic, "extension/ConstantACHnatural", Float(@vented_attic_constant_ach))
          end
        elsif @attic_type == "FlatRoof" or @attic_type == "CathedralCeiling"
          XMLHelper.add_element(attic_type_e, @attic_type)
        else
          fail "Unhandled attic type '#{@attic_type}'."
        end
      end
    end

    def from_hpxml(attic)
      return if attic.nil?

      @id = _get_id(attic)
      if XMLHelper.has_element(attic, "AtticType/Attic[Vented='false']")
        @attic_type = "UnventedAttic"
      elsif XMLHelper.has_element(attic, "AtticType/Attic[Vented='true']")
        @attic_type = "VentedAttic"
      elsif XMLHelper.has_element(attic, "AtticType/Attic[Conditioned='true']")
        @attic_type = "ConditionedAttic"
      elsif XMLHelper.has_element(attic, "AtticType/FlatRoof")
        @attic_type = "FlatRoof"
      elsif XMLHelper.has_element(attic, "AtticType/CathedralCeiling")
        @attic_type = "CathedralCeiling"
      end
      @vented_attic_sla = _to_float_or_nil(XMLHelper.get_value(attic, "[AtticType/Attic[Vented='true']]VentilationRate[UnitofMeasure='SLA']/Value"))
      @vented_attic_constant_ach = _to_float_or_nil(XMLHelper.get_value(attic, "[AtticType/Attic[Vented='true']]extension/ConstantACHnatural"))
      @attached_to_roofs = []
      attic.elements.each("AttachedToRoof") do |roof|
        @attached_to_roofs << _get_idref(roof)
      end
      @attached_to_frame_floors = []
      attic.elements.each("AttachedToFrameFloor") do |frame_floor|
        @attached_to_frame_floors << _get_idref(frame_floor)
      end
    end
  end

  class Foundations < BaseArrayElement
    def add(**kwargs)
      self << Foundation.new(**kwargs)
    end

    def from_hpxml(hpxml)
      return if hpxml.nil?

      hpxml.elements.each("Building/BuildingDetails/Enclosure/Foundations/Foundation") do |foundation|
        self << Foundation.new(foundation)
      end
    end
  end

  class Foundation < BaseElement
    ATTRS = [:id, :foundation_type, :vented_crawlspace_sla, :unconditioned_basement_thermal_boundary,
             :attached_to_slabs, :attached_to_frame_floors, :attached_to_foundation_walls]
    attr_accessor(*ATTRS)

    def to_rexml(doc)
      return if self.nil?

      foundations = XMLHelper.create_elements_as_needed(doc, ["HPXML", "Building", "BuildingDetails", "Enclosure", "Foundations"])
      foundation = XMLHelper.add_element(foundations, "Foundation")
      sys_id = XMLHelper.add_element(foundation, "SystemIdentifier")
      XMLHelper.add_attribute(sys_id, "id", @id)
      if not @foundation_type.nil?
        foundation_type_e = XMLHelper.add_element(foundation, "FoundationType")
        if ["SlabOnGrade", "Ambient"].include? @foundation_type
          XMLHelper.add_element(foundation_type_e, @foundation_type)
        elsif @foundation_type == "ConditionedBasement"
          basement = XMLHelper.add_element(foundation_type_e, "Basement")
          XMLHelper.add_element(basement, "Conditioned", true)
        elsif @foundation_type == "UnconditionedBasement"
          basement = XMLHelper.add_element(foundation_type_e, "Basement")
          XMLHelper.add_element(basement, "Conditioned", false)
          XMLHelper.add_element(foundation, "ThermalBoundary", @unconditioned_basement_thermal_boundary) unless @unconditioned_basement_thermal_boundary.nil?
        elsif @foundation_type == "VentedCrawlspace"
          crawlspace = XMLHelper.add_element(foundation_type_e, "Crawlspace")
          XMLHelper.add_element(crawlspace, "Vented", true)
          if not @vented_crawlspace_sla.nil?
            ventilation_rate = XMLHelper.add_element(foundation, "VentilationRate")
            XMLHelper.add_element(ventilation_rate, "UnitofMeasure", "SLA")
            XMLHelper.add_element(ventilation_rate, "Value", Float(@vented_crawlspace_sla))
          end
        elsif @foundation_type == "UnventedCrawlspace"
          crawlspace = XMLHelper.add_element(foundation_type_e, "Crawlspace")
          XMLHelper.add_element(crawlspace, "Vented", false)
        else
          fail "Unhandled foundation type '#{@foundation_type}'."
        end
      end
    end

    def from_hpxml(foundation)
      return if foundation.nil?

      @id = _get_id(foundation)
      if XMLHelper.has_element(foundation, "FoundationType/SlabOnGrade")
        @foundation_type = "SlabOnGrade"
      elsif XMLHelper.has_element(foundation, "FoundationType/Basement[Conditioned='false']")
        @foundation_type = "UnconditionedBasement"
      elsif XMLHelper.has_element(foundation, "FoundationType/Basement[Conditioned='true']")
        @foundation_type = "ConditionedBasement"
      elsif XMLHelper.has_element(foundation, "FoundationType/Crawlspace[Vented='false']")
        @foundation_type = "UnventedCrawlspace"
      elsif XMLHelper.has_element(foundation, "FoundationType/Crawlspace[Vented='true']")
        @foundation_type = "VentedCrawlspace"
      elsif XMLHelper.has_element(foundation, "FoundationType/Ambient")
        @foundation_type = "Ambient"
      end
      @vented_crawlspace_sla = _to_float_or_nil(XMLHelper.get_value(foundation, "[FoundationType/Crawlspace[Vented='true']]VentilationRate[UnitofMeasure='SLA']/Value"))
      @unconditioned_basement_thermal_boundary = XMLHelper.get_value(foundation, "[FoundationType/Basement[Conditioned='false']]ThermalBoundary")
      @attached_to_slabs = []
      foundation.elements.each("AttachedToSlab") do |slab|
        @attached_to_slabs << _get_idref(slab)
      end
      @attached_to_frame_floors = []
      foundation.elements.each("AttachedToFrameFloor") do |frame_floor|
        @attached_to_frame_floors << _get_idref(frame_floor)
      end
      @attached_to_foundation_walls = []
      foundation.elements.each("AttachedToFoundationWall") do |foundation_wall|
        @attached_to_foundation_walls << _get_idref(foundation_wall)
      end
    end
  end

  class Roofs < BaseArrayElement
    def add(**kwargs)
      self << Roof.new(**kwargs)
    end

    def from_hpxml(hpxml)
      return if hpxml.nil?

      hpxml.elements.each("Building/BuildingDetails/Enclosure/Roofs/Roof") do |roof|
        self << Roof.new(roof)
      end
    end
  end

  class Roof < BaseElement
    ATTRS = [:id, :exterior_adjacent_to, :interior_adjacent_to, :area, :azimuth, :roof_type,
             :roof_color, :solar_absorptance, :emittance, :pitch, :radiant_barrier,
             :insulation_id, :insulation_assembly_r_value, :insulation_cavity_r_value,
             :insulation_continuous_r_value]
    attr_accessor(*ATTRS)

    def to_rexml(doc)
      return if self.nil?

      roofs = XMLHelper.create_elements_as_needed(doc, ["HPXML", "Building", "BuildingDetails", "Enclosure", "Roofs"])
      roof = XMLHelper.add_element(roofs, "Roof")
      sys_id = XMLHelper.add_element(roof, "SystemIdentifier")
      XMLHelper.add_attribute(sys_id, "id", @id)
      XMLHelper.add_element(roof, "InteriorAdjacentTo", @interior_adjacent_to) unless @interior_adjacent_to.nil?
      XMLHelper.add_element(roof, "Area", Float(@area)) unless @area.nil?
      XMLHelper.add_element(roof, "Azimuth", Integer(@azimuth)) unless @azimuth.nil?
      XMLHelper.add_element(roof, "SolarAbsorptance", Float(@solar_absorptance)) unless @solar_absorptance.nil?
      XMLHelper.add_element(roof, "Emittance", Float(@emittance)) unless @emittance.nil?
      XMLHelper.add_element(roof, "Pitch", Float(@pitch)) unless @pitch.nil?
      XMLHelper.add_element(roof, "RadiantBarrier", Boolean(@radiant_barrier)) unless @radiant_barrier.nil?
      insulation = XMLHelper.add_element(roof, "Insulation")
      sys_id = XMLHelper.add_element(insulation, "SystemIdentifier")
      if not @insulation_id.nil?
        XMLHelper.add_attribute(sys_id, "id", @insulation_id)
      else
        XMLHelper.add_attribute(sys_id, "id", @id + "Insulation")
      end
      XMLHelper.add_element(insulation, "AssemblyEffectiveRValue", Float(@insulation_assembly_r_value)) unless @insulation_assembly_r_value.nil?
    end

    def from_hpxml(roof)
      return if roof.nil?

      @id = _get_id(roof)
      @interior_adjacent_to = XMLHelper.get_value(roof, "InteriorAdjacentTo")
      @area = _to_float_or_nil(XMLHelper.get_value(roof, "Area"))
      @azimuth = _to_integer_or_nil(XMLHelper.get_value(roof, "Azimuth"))
      @roof_type = XMLHelper.get_value(roof, "RoofType")
      @roof_color = XMLHelper.get_value(roof, "RoofColor")
      @solar_absorptance = _to_float_or_nil(XMLHelper.get_value(roof, "SolarAbsorptance"))
      @emittance = _to_float_or_nil(XMLHelper.get_value(roof, "Emittance"))
      @pitch = _to_float_or_nil(XMLHelper.get_value(roof, "Pitch"))
      @radiant_barrier = _to_bool_or_nil(XMLHelper.get_value(roof, "RadiantBarrier"))
      insulation = roof.elements["Insulation"]
      if not insulation.nil?
        insulation_id = _get_id(insulation)
        @insulation_assembly_r_value = _to_float_or_nil(XMLHelper.get_value(insulation, "AssemblyEffectiveRValue"))
        @insulation_cavity_r_value = _to_float_or_nil(XMLHelper.get_value(insulation, "Layer[InstallationType='cavity']/NominalRValue"))
        @insulation_continuous_r_value = _to_float_or_nil(XMLHelper.get_value(insulation, "Layer[InstallationType='continuous']/NominalRValue"))
      end
    end

    def exterior_adjacent_to
      return "outside"
    end
  end

  class RimJoists < BaseArrayElement
    def add(**kwargs)
      self << RimJoist.new(**kwargs)
    end

    def from_hpxml(hpxml)
      return if hpxml.nil?

      hpxml.elements.each("Building/BuildingDetails/Enclosure/RimJoists/RimJoist") do |rim_joist|
        self << RimJoist.new(rim_joist)
      end
    end
  end

  class RimJoist < BaseElement
    ATTRS = [:id, :exterior_adjacent_to, :interior_adjacent_to, :area, :azimuth, :solar_absorptance,
             :emittance, :insulation_id, :insulation_assembly_r_value]
    attr_accessor(*ATTRS)

    def to_rexml(doc)
      return if self.nil?

      rim_joists = XMLHelper.create_elements_as_needed(doc, ["HPXML", "Building", "BuildingDetails", "Enclosure", "RimJoists"])
      rim_joist = XMLHelper.add_element(rim_joists, "RimJoist")
      sys_id = XMLHelper.add_element(rim_joist, "SystemIdentifier")
      XMLHelper.add_attribute(sys_id, "id", @id)
      XMLHelper.add_element(rim_joist, "ExteriorAdjacentTo", @exterior_adjacent_to) unless @exterior_adjacent_to.nil?
      XMLHelper.add_element(rim_joist, "InteriorAdjacentTo", @interior_adjacent_to) unless @interior_adjacent_to.nil?
      XMLHelper.add_element(rim_joist, "Area", Float(@area)) unless @area.nil?
      XMLHelper.add_element(rim_joist, "Azimuth", Integer(@azimuth)) unless @azimuth.nil?
      XMLHelper.add_element(rim_joist, "SolarAbsorptance", Float(@solar_absorptance)) unless @solar_absorptance.nil?
      XMLHelper.add_element(rim_joist, "Emittance", Float(@emittance)) unless @emittance.nil?
      insulation = XMLHelper.add_element(rim_joist, "Insulation")
      sys_id = XMLHelper.add_element(insulation, "SystemIdentifier")
      if not @insulation_id.nil?
        XMLHelper.add_attribute(sys_id, "id", @insulation_id)
      else
        XMLHelper.add_attribute(sys_id, "id", @id + "Insulation")
      end
      XMLHelper.add_element(insulation, "AssemblyEffectiveRValue", Float(@insulation_assembly_r_value)) unless @insulation_assembly_r_value.nil?
    end

    def from_hpxml(rim_joist)
      return if rim_joist.nil?

      @id = _get_id(rim_joist)
      @exterior_adjacent_to = XMLHelper.get_value(rim_joist, "ExteriorAdjacentTo")
      @interior_adjacent_to = XMLHelper.get_value(rim_joist, "InteriorAdjacentTo")
      @area = _to_float_or_nil(XMLHelper.get_value(rim_joist, "Area"))
      @azimuth = _to_integer_or_nil(XMLHelper.get_value(rim_joist, "Azimuth"))
      @solar_absorptance = _to_float_or_nil(XMLHelper.get_value(rim_joist, "SolarAbsorptance"))
      @emittance = _to_float_or_nil(XMLHelper.get_value(rim_joist, "Emittance"))
      insulation = rim_joist.elements["Insulation"]
      if not insulation.nil?
        insulation_id = _get_id(insulation)
        @insulation_assembly_r_value = _to_float_or_nil(XMLHelper.get_value(insulation, "AssemblyEffectiveRValue"))
      end
    end
  end

  class Walls < BaseArrayElement
    def add(**kwargs)
      self << Wall.new(**kwargs)
    end

    def from_hpxml(hpxml)
      return if hpxml.nil?

      hpxml.elements.each("Building/BuildingDetails/Enclosure/Walls/Wall") do |wall|
        self << Wall.new(wall)
      end
    end
  end

  class Wall < BaseElement
    ATTRS = [:id, :exterior_adjacent_to, :interior_adjacent_to, :wall_type, :optimum_value_engineering,
             :area, :orientation, :azimuth, :siding, :solar_absorptance, :emittance, :insulation_id,
             :insulation_assembly_r_value, :insulation_cavity_r_value, :insulation_continuous_r_value]
    attr_accessor(*ATTRS)

    def to_rexml(doc)
      return if self.nil?

      walls = XMLHelper.create_elements_as_needed(doc, ["HPXML", "Building", "BuildingDetails", "Enclosure", "Walls"])
      wall = XMLHelper.add_element(walls, "Wall")
      sys_id = XMLHelper.add_element(wall, "SystemIdentifier")
      XMLHelper.add_attribute(sys_id, "id", @id)
      XMLHelper.add_element(wall, "ExteriorAdjacentTo", @exterior_adjacent_to) unless @exterior_adjacent_to.nil?
      XMLHelper.add_element(wall, "InteriorAdjacentTo", @interior_adjacent_to) unless @interior_adjacent_to.nil?
      if not @wall_type.nil?
        wall_type_e = XMLHelper.add_element(wall, "WallType")
        XMLHelper.add_element(wall_type_e, @wall_type)
      end
      XMLHelper.add_element(wall, "Area", Float(@area)) unless @area.nil?
      XMLHelper.add_element(wall, "Azimuth", Integer(@azimuth)) unless @azimuth.nil?
      XMLHelper.add_element(wall, "SolarAbsorptance", Float(@solar_absorptance)) unless @solar_absorptance.nil?
      XMLHelper.add_element(wall, "Emittance", Float(@emittance)) unless @emittance.nil?
      insulation = XMLHelper.add_element(wall, "Insulation")
      sys_id = XMLHelper.add_element(insulation, "SystemIdentifier")
      if not @insulation_id.nil?
        XMLHelper.add_attribute(sys_id, "id", @insulation_id)
      else
        XMLHelper.add_attribute(sys_id, "id", @id + "Insulation")
      end
      XMLHelper.add_element(insulation, "AssemblyEffectiveRValue", Float(@insulation_assembly_r_value))
    end

    def from_hpxml(wall)
      return if wall.nil?

      @id = _get_id(wall)
      @exterior_adjacent_to = XMLHelper.get_value(wall, "ExteriorAdjacentTo")
      @interior_adjacent_to = XMLHelper.get_value(wall, "InteriorAdjacentTo")
      @wall_type = XMLHelper.get_child_name(wall, "WallType")
      @optimum_value_engineering = _to_bool_or_nil(XMLHelper.get_value(wall, "WallType/WoodStud/OptimumValueEngineering"))
      @area = _to_float_or_nil(XMLHelper.get_value(wall, "Area"))
      @orientation = XMLHelper.get_value(wall, "Orientation")
      @azimuth = _to_integer_or_nil(XMLHelper.get_value(wall, "Azimuth"))
      @siding = XMLHelper.get_value(wall, "Siding")
      @solar_absorptance = _to_float_or_nil(XMLHelper.get_value(wall, "SolarAbsorptance"))
      @emittance = _to_float_or_nil(XMLHelper.get_value(wall, "Emittance"))
      insulation = wall.elements["Insulation"]
      if not insulation.nil?
        insulation_id = _get_id(insulation)
        @insulation_assembly_r_value = _to_float_or_nil(XMLHelper.get_value(insulation, "AssemblyEffectiveRValue"))
        @insulation_cavity_r_value = _to_float_or_nil(XMLHelper.get_value(insulation, "Layer[InstallationType='cavity']/NominalRValue"))
        @insulation_continuous_r_value = _to_float_or_nil(XMLHelper.get_value(insulation, "Layer[InstallationType='continuous']/NominalRValue"))
      end
    end
  end

  class FoundationWalls < BaseArrayElement
    def add(**kwargs)
      self << FoundationWall.new(**kwargs)
    end

    def from_hpxml(hpxml)
      return if hpxml.nil?

      hpxml.elements.each("Building/BuildingDetails/Enclosure/FoundationWalls/FoundationWall") do |foundation_wall|
        self << FoundationWall.new(foundation_wall)
      end
    end
  end

  class FoundationWall < BaseElement
    ATTRS = [:id, :exterior_adjacent_to, :interior_adjacent_to, :height, :area, :azimuth, :thickness,
             :depth_below_grade, :insulation_id, :insulation_r_value, :insulation_interior_r_value,
             :insulation_interior_distance_to_top, :insulation_interior_distance_to_bottom,
             :insulation_exterior_r_value, :insulation_exterior_distance_to_top,
             :insulation_exterior_distance_to_bottom, :insulation_assembly_r_value]
    attr_accessor(*ATTRS)

    def to_rexml(doc)
      return if self.nil?

      foundation_walls = XMLHelper.create_elements_as_needed(doc, ["HPXML", "Building", "BuildingDetails", "Enclosure", "FoundationWalls"])
      foundation_wall = XMLHelper.add_element(foundation_walls, "FoundationWall")
      sys_id = XMLHelper.add_element(foundation_wall, "SystemIdentifier")
      XMLHelper.add_attribute(sys_id, "id", @id)
      XMLHelper.add_element(foundation_wall, "ExteriorAdjacentTo", @exterior_adjacent_to) unless @exterior_adjacent_to.nil?
      XMLHelper.add_element(foundation_wall, "InteriorAdjacentTo", @interior_adjacent_to) unless @interior_adjacent_to.nil?
      XMLHelper.add_element(foundation_wall, "Height", Float(@height)) unless @height.nil?
      XMLHelper.add_element(foundation_wall, "Area", Float(@area)) unless @area.nil?
      XMLHelper.add_element(foundation_wall, "Azimuth", Integer(@azimuth)) unless @azimuth.nil?
      XMLHelper.add_element(foundation_wall, "Thickness", Float(@thickness)) unless @thickness.nil?
      XMLHelper.add_element(foundation_wall, "DepthBelowGrade", Float(@depth_below_grade)) unless @depth_below_grade.nil?
      insulation = XMLHelper.add_element(foundation_wall, "Insulation")
      sys_id = XMLHelper.add_element(insulation, "SystemIdentifier")
      if not @insulation_id.nil?
        XMLHelper.add_attribute(sys_id, "id", @insulation_id)
      else
        XMLHelper.add_attribute(sys_id, "id", @id + "Insulation")
      end
      XMLHelper.add_element(insulation, "AssemblyEffectiveRValue", Float(@insulation_assembly_r_value)) unless @insulation_assembly_r_value.nil?
      if not @insulation_exterior_r_value.nil?
        layer = XMLHelper.add_element(insulation, "Layer")
        XMLHelper.add_element(layer, "InstallationType", "continuous - exterior")
        XMLHelper.add_element(layer, "NominalRValue", Float(@insulation_exterior_r_value))
        _add_extension(parent: layer,
                       extensions: { "DistanceToTopOfInsulation" => _to_float_or_nil(@insulation_exterior_distance_to_top),
                                     "DistanceToBottomOfInsulation" => _to_float_or_nil(@insulation_exterior_distance_to_bottom) })
      end
      if not @insulation_interior_r_value.nil?
        layer = XMLHelper.add_element(insulation, "Layer")
        XMLHelper.add_element(layer, "InstallationType", "continuous - interior")
        XMLHelper.add_element(layer, "NominalRValue", Float(@insulation_interior_r_value))
        _add_extension(parent: layer,
                       extensions: { "DistanceToTopOfInsulation" => _to_float_or_nil(@insulation_interior_distance_to_top),
                                     "DistanceToBottomOfInsulation" => _to_float_or_nil(@insulation_interior_distance_to_bottom) })
      end
    end

    def from_hpxml(foundation_wall)
      return if foundation_wall.nil?

      @id = _get_id(foundation_wall)
      @exterior_adjacent_to = XMLHelper.get_value(foundation_wall, "ExteriorAdjacentTo")
      @interior_adjacent_to = XMLHelper.get_value(foundation_wall, "InteriorAdjacentTo")
      @height = _to_float_or_nil(XMLHelper.get_value(foundation_wall, "Height"))
      @area = _to_float_or_nil(XMLHelper.get_value(foundation_wall, "Area"))
      @azimuth = _to_integer_or_nil(XMLHelper.get_value(foundation_wall, "Azimuth"))
      @thickness = _to_float_or_nil(XMLHelper.get_value(foundation_wall, "Thickness"))
      @depth_below_grade = _to_float_or_nil(XMLHelper.get_value(foundation_wall, "DepthBelowGrade"))
      insulation = foundation_wall.elements["Insulation"]
      if not insulation.nil?
        insulation_id = _get_id(insulation)
        @insulation_r_value = _to_float_or_nil(XMLHelper.get_value(insulation, "Layer[InstallationType='continuous']/NominalRValue"))
        @insulation_interior_r_value = _to_float_or_nil(XMLHelper.get_value(insulation, "Layer[InstallationType='continuous - interior']/NominalRValue"))
        @insulation_interior_distance_to_top = _to_float_or_nil(XMLHelper.get_value(insulation, "Layer[InstallationType='continuous - interior']/extension/DistanceToTopOfInsulation"))
        @insulation_interior_distance_to_bottom = _to_float_or_nil(XMLHelper.get_value(insulation, "Layer[InstallationType='continuous - interior']/extension/DistanceToBottomOfInsulation"))
        @insulation_exterior_r_value = _to_float_or_nil(XMLHelper.get_value(insulation, "Layer[InstallationType='continuous - exterior']/NominalRValue"))
        @insulation_exterior_distance_to_top = _to_float_or_nil(XMLHelper.get_value(insulation, "Layer[InstallationType='continuous - exterior']/extension/DistanceToTopOfInsulation"))
        @insulation_exterior_distance_to_bottom = _to_float_or_nil(XMLHelper.get_value(insulation, "Layer[InstallationType='continuous - exterior']/extension/DistanceToBottomOfInsulation"))
        @insulation_assembly_r_value = _to_float_or_nil(XMLHelper.get_value(insulation, "AssemblyEffectiveRValue"))
      end
    end
  end

  class FrameFloors < BaseArrayElement
    def add(**kwargs)
      self << FrameFloor.new(**kwargs)
    end

    def from_hpxml(hpxml)
      return if hpxml.nil?

      hpxml.elements.each("Building/BuildingDetails/Enclosure/FrameFloors/FrameFloor") do |frame_floor|
        self << FrameFloor.new(frame_floor)
      end
    end
  end

  class FrameFloor < BaseElement
    ATTRS = [:id, :exterior_adjacent_to, :interior_adjacent_to, :area, :insulation_id,
             :insulation_assembly_r_value, :insulation_cavity_r_value, :insulation_continuous_r_value]
    attr_accessor(*ATTRS)

    def to_rexml(doc)
      return if self.nil?

      frame_floors = XMLHelper.create_elements_as_needed(doc, ["HPXML", "Building", "BuildingDetails", "Enclosure", "FrameFloors"])
      frame_floor = XMLHelper.add_element(frame_floors, "FrameFloor")
      sys_id = XMLHelper.add_element(frame_floor, "SystemIdentifier")
      XMLHelper.add_attribute(sys_id, "id", @id)
      XMLHelper.add_element(frame_floor, "ExteriorAdjacentTo", @exterior_adjacent_to) unless @exterior_adjacent_to.nil?
      XMLHelper.add_element(frame_floor, "InteriorAdjacentTo", @interior_adjacent_to) unless @interior_adjacent_to.nil?
      XMLHelper.add_element(frame_floor, "Area", Float(@area)) unless @area.nil?
      insulation = XMLHelper.add_element(frame_floor, "Insulation")
      sys_id = XMLHelper.add_element(insulation, "SystemIdentifier")
      if not @insulation_id.nil?
        XMLHelper.add_attribute(sys_id, "id", @insulation_id)
      else
        XMLHelper.add_attribute(sys_id, "id", @id + "Insulation")
      end
      XMLHelper.add_element(insulation, "AssemblyEffectiveRValue", Float(@insulation_assembly_r_value)) unless @insulation_assembly_r_value.nil?
    end

    def from_hpxml(frame_floor)
      return if frame_floor.nil?

      @id = _get_id(frame_floor)
      @exterior_adjacent_to = XMLHelper.get_value(frame_floor, "ExteriorAdjacentTo")
      @interior_adjacent_to = XMLHelper.get_value(frame_floor, "InteriorAdjacentTo")
      @area = _to_float_or_nil(XMLHelper.get_value(frame_floor, "Area"))
      insulation = frame_floor.elements["Insulation"]
      if not insulation.nil?
        insulation_id = _get_id(insulation)
        @insulation_assembly_r_value = _to_float_or_nil(XMLHelper.get_value(insulation, "AssemblyEffectiveRValue"))
        @insulation_cavity_r_value = _to_float_or_nil(XMLHelper.get_value(insulation, "Layer[InstallationType='cavity']/NominalRValue"))
        @insulation_continuous_r_value = _to_float_or_nil(XMLHelper.get_value(insulation, "Layer[InstallationType='continuous']/NominalRValue"))
      end
    end

    def is_ceiling
      if ["attic - vented", "attic - unvented"].include? @interior_adjacent_to
        return true
      elsif ["attic - vented", "attic - unvented", "other housing unit above"].include? @exterior_adjacent_to
        return true
      end

      return false
    end

    def is_floor
      !is_ceiling
    end
  end

  class Slabs < BaseArrayElement
    def add(**kwargs)
      self << Slab.new(**kwargs)
    end

    def from_hpxml(hpxml)
      return if hpxml.nil?

      hpxml.elements.each("Building/BuildingDetails/Enclosure/Slabs/Slab") do |slab|
        self << Slab.new(slab)
      end
    end
  end

  class Slab < BaseElement
    ATTRS = [:id, :interior_adjacent_to, :exterior_adjacent_to, :area, :thickness, :exposed_perimeter,
             :perimeter_insulation_depth, :under_slab_insulation_width,
             :under_slab_insulation_spans_entire_slab, :depth_below_grade, :carpet_fraction,
             :carpet_r_value, :perimeter_insulation_id, :perimeter_insulation_r_value,
             :under_slab_insulation_id, :under_slab_insulation_r_value]
    attr_accessor(*ATTRS)

    def to_rexml(doc)
      return if self.nil?

      slabs = XMLHelper.create_elements_as_needed(doc, ["HPXML", "Building", "BuildingDetails", "Enclosure", "Slabs"])
      slab = XMLHelper.add_element(slabs, "Slab")
      sys_id = XMLHelper.add_element(slab, "SystemIdentifier")
      XMLHelper.add_attribute(sys_id, "id", @id)
      XMLHelper.add_element(slab, "InteriorAdjacentTo", @interior_adjacent_to) unless @interior_adjacent_to.nil?
      XMLHelper.add_element(slab, "Area", Float(@area)) unless @area.nil?
      XMLHelper.add_element(slab, "Thickness", Float(@thickness)) unless @thickness.nil?
      XMLHelper.add_element(slab, "ExposedPerimeter", Float(@exposed_perimeter)) unless @exposed_perimeter.nil?
      XMLHelper.add_element(slab, "PerimeterInsulationDepth", Float(@perimeter_insulation_depth)) unless @perimeter_insulation_depth.nil?
      XMLHelper.add_element(slab, "UnderSlabInsulationWidth", Float(@under_slab_insulation_width)) unless @under_slab_insulation_width.nil?
      XMLHelper.add_element(slab, "UnderSlabInsulationSpansEntireSlab", Boolean(@under_slab_insulation_spans_entire_slab)) unless @under_slab_insulation_spans_entire_slab.nil?
      XMLHelper.add_element(slab, "DepthBelowGrade", Float(@depth_below_grade)) unless @depth_below_grade.nil?
      insulation = XMLHelper.add_element(slab, "PerimeterInsulation")
      sys_id = XMLHelper.add_element(insulation, "SystemIdentifier")
      if not @perimeter_insulation_id.nil?
        XMLHelper.add_attribute(sys_id, "id", @perimeter_insulation_id)
      else
        XMLHelper.add_attribute(sys_id, "id", @id + "PerimeterInsulation")
      end
      layer = XMLHelper.add_element(insulation, "Layer")
      XMLHelper.add_element(layer, "InstallationType", "continuous")
      XMLHelper.add_element(layer, "NominalRValue", Float(@perimeter_insulation_r_value)) unless @perimeter_insulation_r_value.nil?
      insulation = XMLHelper.add_element(slab, "UnderSlabInsulation")
      sys_id = XMLHelper.add_element(insulation, "SystemIdentifier")
      if not @under_slab_insulation_id.nil?
        XMLHelper.add_attribute(sys_id, "id", @under_slab_insulation_id)
      else
        XMLHelper.add_attribute(sys_id, "id", @id + "UnderSlabInsulation")
      end
      layer = XMLHelper.add_element(insulation, "Layer")
      XMLHelper.add_element(layer, "InstallationType", "continuous")
      XMLHelper.add_element(layer, "NominalRValue", Float(@under_slab_insulation_r_value)) unless @under_slab_insulation_r_value.nil?
      _add_extension(parent: slab,
                     extensions: { "CarpetFraction" => _to_float_or_nil(@carpet_fraction),
                                   "CarpetRValue" => _to_float_or_nil(@carpet_r_value) })
    end

    def from_hpxml(slab)
      return if slab.nil?

      @id = _get_id(slab)
      @interior_adjacent_to = XMLHelper.get_value(slab, "InteriorAdjacentTo")
      @area = _to_float_or_nil(XMLHelper.get_value(slab, "Area"))
      @thickness = _to_float_or_nil(XMLHelper.get_value(slab, "Thickness"))
      @exposed_perimeter = _to_float_or_nil(XMLHelper.get_value(slab, "ExposedPerimeter"))
      @perimeter_insulation_depth = _to_float_or_nil(XMLHelper.get_value(slab, "PerimeterInsulationDepth"))
      @under_slab_insulation_width = _to_float_or_nil(XMLHelper.get_value(slab, "UnderSlabInsulationWidth"))
      @under_slab_insulation_spans_entire_slab = _to_bool_or_nil(XMLHelper.get_value(slab, "UnderSlabInsulationSpansEntireSlab"))
      @depth_below_grade = _to_float_or_nil(XMLHelper.get_value(slab, "DepthBelowGrade"))
      @carpet_fraction = _to_float_or_nil(XMLHelper.get_value(slab, "extension/CarpetFraction"))
      @carpet_r_value = _to_float_or_nil(XMLHelper.get_value(slab, "extension/CarpetRValue"))
      perimeter_insulation = slab.elements["PerimeterInsulation"]
      if not perimeter_insulation.nil?
        perimeter_insulation_id = _get_id(perimeter_insulation)
        @perimeter_insulation_r_value = _to_float_or_nil(XMLHelper.get_value(perimeter_insulation, "Layer[InstallationType='continuous']/NominalRValue"))
      end
      under_slab_insulation = slab.elements["UnderSlabInsulation"]
      if not under_slab_insulation.nil?
        under_slab_insulation_id = _get_id(under_slab_insulation)
        @under_slab_insulation_r_value = _to_float_or_nil(XMLHelper.get_value(under_slab_insulation, "Layer[InstallationType='continuous']/NominalRValue"))
      end
    end

    def exterior_adjacent_to
      return "outside" # FIXME: Switch to ground?
    end
  end

  class Windows < BaseArrayElement
    def add(**kwargs)
      self << Window.new(**kwargs)
    end

    def from_hpxml(hpxml)
      return if hpxml.nil?

      hpxml.elements.each("Building/BuildingDetails/Enclosure/Windows/Window") do |window|
        self << Window.new(window)
      end
    end
  end

  class Window < BaseElement
    ATTRS = [:id, :area, :azimuth, :orientation, :frame_type, :aluminum_thermal_break, :glass_layers,
             :glass_type, :gas_fill, :ufactor, :shgc, :interior_shading_factor_summer,
             :interior_shading_factor_winter, :exterior_shading, :overhangs_depth,
             :overhangs_distance_to_top_of_window, :overhangs_distance_to_bottom_of_window,
             :wall_idref]
    attr_accessor(*ATTRS)

    def to_rexml(doc)
      return if self.nil?

      windows = XMLHelper.create_elements_as_needed(doc, ["HPXML", "Building", "BuildingDetails", "Enclosure", "Windows"])
      window = XMLHelper.add_element(windows, "Window")
      sys_id = XMLHelper.add_element(window, "SystemIdentifier")
      XMLHelper.add_attribute(sys_id, "id", @id)
      XMLHelper.add_element(window, "Area", Float(@area)) unless @area.nil?
      XMLHelper.add_element(window, "Azimuth", Integer(@azimuth)) unless @azimuth.nil?
      XMLHelper.add_element(window, "UFactor", Float(@ufactor)) unless @ufactor.nil?
      XMLHelper.add_element(window, "SHGC", Float(@shgc)) unless @shgc.nil?
      if not @interior_shading_factor_summer.nil? or not @interior_shading_factor_winter.nil?
        interior_shading = XMLHelper.add_element(window, "InteriorShading")
        sys_id = XMLHelper.add_element(interior_shading, "SystemIdentifier")
        XMLHelper.add_attribute(sys_id, "id", "#{id}InteriorShading")
        XMLHelper.add_element(interior_shading, "SummerShadingCoefficient", Float(@interior_shading_factor_summer)) unless @interior_shading_factor_summer.nil?
        XMLHelper.add_element(interior_shading, "WinterShadingCoefficient", Float(@interior_shading_factor_winter)) unless @interior_shading_factor_winter.nil?
      end
      if not @overhangs_depth.nil? or not @overhangs_distance_to_top_of_window.nil? or not @overhangs_distance_to_bottom_of_window.nil?
        overhangs = XMLHelper.add_element(window, "Overhangs")
        XMLHelper.add_element(overhangs, "Depth", Float(@overhangs_depth)) unless @overhangs_depth.nil?
        XMLHelper.add_element(overhangs, "DistanceToTopOfWindow", Float(@overhangs_distance_to_top_of_window)) unless @overhangs_distance_to_top_of_window.nil?
        XMLHelper.add_element(overhangs, "DistanceToBottomOfWindow", Float(@overhangs_distance_to_bottom_of_window)) unless @overhangs_distance_to_bottom_of_window.nil?
      end
      if not @wall_idref.nil?
        attached_to_wall = XMLHelper.add_element(window, "AttachedToWall")
        XMLHelper.add_attribute(attached_to_wall, "idref", @wall_idref)
      end
    end

    def from_hpxml(window)
      return if window.nil?

      @id = _get_id(window)
      @area = _to_float_or_nil(XMLHelper.get_value(window, "Area"))
      @azimuth = _to_integer_or_nil(XMLHelper.get_value(window, "Azimuth"))
      @orientation = XMLHelper.get_value(window, "Orientation")
      @frame_type = XMLHelper.get_child_name(window, "FrameType")
      @aluminum_thermal_break = _to_bool_or_nil(XMLHelper.get_value(window, "FrameType/Aluminum/ThermalBreak"))
      @glass_layers = XMLHelper.get_value(window, "GlassLayers")
      @glass_type = XMLHelper.get_value(window, "GlassType")
      @gas_fill = XMLHelper.get_value(window, "GasFill")
      @ufactor = _to_float_or_nil(XMLHelper.get_value(window, "UFactor"))
      @shgc = _to_float_or_nil(XMLHelper.get_value(window, "SHGC"))
      @interior_shading_factor_summer = _to_float_or_nil(XMLHelper.get_value(window, "InteriorShading/SummerShadingCoefficient"))
      @interior_shading_factor_winter = _to_float_or_nil(XMLHelper.get_value(window, "InteriorShading/WinterShadingCoefficient"))
      @exterior_shading = XMLHelper.get_value(window, "ExteriorShading/Type")
      @overhangs_depth = _to_float_or_nil(XMLHelper.get_value(window, "Overhangs/Depth"))
      @overhangs_distance_to_top_of_window = _to_float_or_nil(XMLHelper.get_value(window, "Overhangs/DistanceToTopOfWindow"))
      @overhangs_distance_to_bottom_of_window = _to_float_or_nil(XMLHelper.get_value(window, "Overhangs/DistanceToBottomOfWindow"))
      @wall_idref = _get_idref(window.elements["AttachedToWall"])
    end
  end

  class Skylights < BaseArrayElement
    def add(**kwargs)
      self << Skylight.new(**kwargs)
    end

    def from_hpxml(hpxml)
      return if hpxml.nil?

      hpxml.elements.each("Building/BuildingDetails/Enclosure/Skylights/Skylight") do |skylight|
        self << Skylight.new(skylight)
      end
    end
  end

  class Skylight < BaseElement
    ATTRS = [:id, :area, :azimuth, :orientation, :frame_type, :aluminum_thermal_break, :glass_layers,
             :glass_type, :gas_fill, :ufactor, :shgc, :exterior_shading, :roof_idref]
    attr_accessor(*ATTRS)

    def to_rexml(doc)
      return if self.nil?

      skylights = XMLHelper.create_elements_as_needed(doc, ["HPXML", "Building", "BuildingDetails", "Enclosure", "Skylights"])
      skylight = XMLHelper.add_element(skylights, "Skylight")
      sys_id = XMLHelper.add_element(skylight, "SystemIdentifier")
      XMLHelper.add_attribute(sys_id, "id", @id)
      XMLHelper.add_element(skylight, "Area", Float(@area)) unless @area.nil?
      XMLHelper.add_element(skylight, "Azimuth", Integer(@azimuth)) unless @azimuth.nil?
      XMLHelper.add_element(skylight, "UFactor", Float(@ufactor)) unless @ufactor.nil?
      XMLHelper.add_element(skylight, "SHGC", Float(@shgc)) unless @shgc.nil?
      if not @roof_idref.nil?
        attached_to_roof = XMLHelper.add_element(skylight, "AttachedToRoof")
        XMLHelper.add_attribute(attached_to_roof, "idref", @roof_idref)
      end
    end

    def from_hpxml(skylight)
      return if skylight.nil?

      @id = _get_id(skylight)
      @area = _to_float_or_nil(XMLHelper.get_value(skylight, "Area"))
      @azimuth = _to_integer_or_nil(XMLHelper.get_value(skylight, "Azimuth"))
      @orientation = XMLHelper.get_value(skylight, "Orientation")
      @frame_type = XMLHelper.get_child_name(skylight, "FrameType")
      @aluminum_thermal_break = _to_bool_or_nil(XMLHelper.get_value(skylight, "FrameType/Aluminum/ThermalBreak"))
      @glass_layers = XMLHelper.get_value(skylight, "GlassLayers")
      @glass_type = XMLHelper.get_value(skylight, "GlassType")
      @gas_fill = XMLHelper.get_value(skylight, "GasFill")
      @ufactor = _to_float_or_nil(XMLHelper.get_value(skylight, "UFactor"))
      @shgc = _to_float_or_nil(XMLHelper.get_value(skylight, "SHGC"))
      @exterior_shading = XMLHelper.get_value(skylight, "ExteriorShading/Type")
      @roof_idref = _get_idref(skylight.elements["AttachedToRoof"])
    end
  end

  class Doors < BaseArrayElement
    def add(**kwargs)
      self << Door.new(**kwargs)
    end

    def from_hpxml(hpxml)
      return if hpxml.nil?

      hpxml.elements.each("Building/BuildingDetails/Enclosure/Doors/Door") do |door|
        self << Door.new(door)
      end
    end
  end

  class Door < BaseElement
    ATTRS = [:id, :wall_idref, :area, :azimuth, :r_value]
    attr_accessor(*ATTRS)

    def to_rexml(doc)
      return if self.nil?

      doors = XMLHelper.create_elements_as_needed(doc, ["HPXML", "Building", "BuildingDetails", "Enclosure", "Doors"])
      door = XMLHelper.add_element(doors, "Door")
      sys_id = XMLHelper.add_element(door, "SystemIdentifier")
      XMLHelper.add_attribute(sys_id, "id", @id)
      if not @wall_idref.nil?
        attached_to_wall = XMLHelper.add_element(door, "AttachedToWall")
        XMLHelper.add_attribute(attached_to_wall, "idref", @wall_idref)
      end
      XMLHelper.add_element(door, "Area", Float(@area)) unless @area.nil?
      XMLHelper.add_element(door, "Azimuth", Integer(@azimuth)) unless @azimuth.nil?
      XMLHelper.add_element(door, "RValue", Float(@r_value)) unless @r_value.nil?
    end

    def from_hpxml(door)
      return if door.nil?

      @id = _get_id(door)
      @wall_idref = _get_idref(door.elements["AttachedToWall"])
      @area = _to_float_or_nil(XMLHelper.get_value(door, "Area"))
      @azimuth = _to_integer_or_nil(XMLHelper.get_value(door, "Azimuth"))
      @r_value = _to_float_or_nil(XMLHelper.get_value(door, "RValue"))
    end
  end

  class HeatingSystems < BaseArrayElement
    def add(**kwargs)
      self << HeatingSystem.new(**kwargs)
    end

    def from_hpxml(hpxml)
      return if hpxml.nil?

      hpxml.elements.each("Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem") do |heating_system|
        self << HeatingSystem.new(heating_system)
      end
    end
  end

  class HeatingSystem < BaseElement
    ATTRS = [:id, :distribution_system_idref, :year_installed, :heating_system_type,
             :heating_system_fuel, :heating_capacity, :heating_efficiency_afue,
             :heating_efficiency_percent, :fraction_heat_load_served, :electric_auxiliary_energy,
             :heating_cfm, :energy_star, :seed_id]
    attr_accessor(*ATTRS)

    def to_rexml(doc)
      return if self.nil?

      hvac_plant = XMLHelper.create_elements_as_needed(doc, ["HPXML", "Building", "BuildingDetails", "Systems", "HVAC", "HVACPlant"])
      heating_system = XMLHelper.add_element(hvac_plant, "HeatingSystem")
      sys_id = XMLHelper.add_element(heating_system, "SystemIdentifier")
      XMLHelper.add_attribute(sys_id, "id", @id)
      if not @distribution_system_idref.nil?
        distribution_system = XMLHelper.add_element(heating_system, "DistributionSystem")
        XMLHelper.add_attribute(distribution_system, "idref", @distribution_system_idref)
      end
      if not @heating_system_type.nil?
        heating_system_type_e = XMLHelper.add_element(heating_system, "HeatingSystemType")
        XMLHelper.add_element(heating_system_type_e, @heating_system_type)
      end
      XMLHelper.add_element(heating_system, "HeatingSystemFuel", @heating_system_fuel) unless @heating_system_fuel.nil?
      XMLHelper.add_element(heating_system, "HeatingCapacity", Float(@heating_capacity)) unless @heating_capacity.nil?

      efficiency_units = nil
      efficiency_value = nil
      if ["Furnace", "WallFurnace", "Boiler"].include? @heating_system_type
        efficiency_units = "AFUE"
        efficiency_value = @heating_efficiency_afue
      elsif ["ElectricResistance", "Stove", "PortableHeater"].include? @heating_system_type
        efficiency_units = "Percent"
        efficiency_value = @heating_efficiency_percent
      end
      if not efficiency_value.nil?
        annual_efficiency = XMLHelper.add_element(heating_system, "AnnualHeatingEfficiency")
        XMLHelper.add_element(annual_efficiency, "Units", efficiency_units)
        XMLHelper.add_element(annual_efficiency, "Value", Float(efficiency_value))
      end

      XMLHelper.add_element(heating_system, "FractionHeatLoadServed", Float(@fraction_heat_load_served)) unless @fraction_heat_load_served.nil?
      XMLHelper.add_element(heating_system, "ElectricAuxiliaryEnergy", Float(@electric_auxiliary_energy)) unless @electric_auxiliary_energy.nil?
      _add_extension(parent: heating_system,
                     extensions: { "HeatingFlowRate" => _to_float_or_nil(@heating_cfm),
                                   "SeedId" => @seed_id })
    end

    def from_hpxml(heating_system)
      return if heating_system.nil?

      @id = _get_id(heating_system)
      @distribution_system_idref = _get_idref(heating_system.elements["DistributionSystem"])
      @year_installed = _to_integer_or_nil(XMLHelper.get_value(heating_system, "YearInstalled"))
      @heating_system_type = XMLHelper.get_child_name(heating_system, "HeatingSystemType")
      @heating_system_fuel = XMLHelper.get_value(heating_system, "HeatingSystemFuel")
      @heating_capacity = _to_float_or_nil(XMLHelper.get_value(heating_system, "HeatingCapacity"))
      @heating_efficiency_afue = _to_float_or_nil(XMLHelper.get_value(heating_system, "[HeatingSystemType[Furnace | WallFurnace | Boiler]]AnnualHeatingEfficiency[Units='AFUE']/Value"))
      @heating_efficiency_percent = _to_float_or_nil(XMLHelper.get_value(heating_system, "[HeatingSystemType[ElectricResistance | Stove | PortableHeater]]AnnualHeatingEfficiency[Units='Percent']/Value"))
      @fraction_heat_load_served = _to_float_or_nil(XMLHelper.get_value(heating_system, "FractionHeatLoadServed"))
      @electric_auxiliary_energy = _to_float_or_nil(XMLHelper.get_value(heating_system, "ElectricAuxiliaryEnergy"))
      @heating_cfm = _to_float_or_nil(XMLHelper.get_value(heating_system, "extension/HeatingFlowRate"))
      @energy_star = XMLHelper.get_values(heating_system, "ThirdPartyCertification").include?("Energy Star")
      @seed_id = XMLHelper.get_value(heating_system, "extension/SeedId")
    end
  end

  class CoolingSystems < BaseArrayElement
    def add(**kwargs)
      self << CoolingSystem.new(**kwargs)
    end

    def from_hpxml(hpxml)
      return if hpxml.nil?

      hpxml.elements.each("Building/BuildingDetails/Systems/HVAC/HVACPlant/CoolingSystem") do |cooling_system|
        self << CoolingSystem.new(cooling_system)
      end
    end
  end

  class CoolingSystem < BaseElement
    ATTRS = [:id, :distribution_system_idref, :year_installed, :cooling_system_type,
             :cooling_system_fuel, :cooling_capacity, :compressor_type, :fraction_cool_load_served,
             :cooling_efficiency_seer, :cooling_efficiency_eer, :cooling_shr, :cooling_cfm,
             :energy_star, :seed_id]
    attr_accessor(*ATTRS)

    def to_rexml(doc)
      return if self.nil?

      hvac_plant = XMLHelper.create_elements_as_needed(doc, ["HPXML", "Building", "BuildingDetails", "Systems", "HVAC", "HVACPlant"])
      cooling_system = XMLHelper.add_element(hvac_plant, "CoolingSystem")
      sys_id = XMLHelper.add_element(cooling_system, "SystemIdentifier")
      XMLHelper.add_attribute(sys_id, "id", @id)
      if not @distribution_system_idref.nil?
        distribution_system = XMLHelper.add_element(cooling_system, "DistributionSystem")
        XMLHelper.add_attribute(distribution_system, "idref", @distribution_system_idref)
      end
      XMLHelper.add_element(cooling_system, "CoolingSystemType", @cooling_system_type) unless @cooling_system_type.nil?
      XMLHelper.add_element(cooling_system, "CoolingSystemFuel", @cooling_system_fuel) unless @cooling_system_fuel.nil?
      XMLHelper.add_element(cooling_system, "CoolingCapacity", Float(@cooling_capacity)) unless @cooling_capacity.nil?
      XMLHelper.add_element(cooling_system, "CompressorType", @compressor_type) unless @compressor_type.nil?
      XMLHelper.add_element(cooling_system, "FractionCoolLoadServed", Float(@fraction_cool_load_served)) unless @fraction_cool_load_served.nil?

      efficiency_units = nil
      efficiency_value = nil
      if ["central air conditioner"].include? @cooling_system_type
        efficiency_units = "SEER"
        efficiency_value = @cooling_efficiency_seer
      elsif ["room air conditioner"].include? @cooling_system_type
        efficiency_units = "EER"
        efficiency_value = @cooling_efficiency_eer
      end
      if not efficiency_value.nil?
        annual_efficiency = XMLHelper.add_element(cooling_system, "AnnualCoolingEfficiency")
        XMLHelper.add_element(annual_efficiency, "Units", efficiency_units)
        XMLHelper.add_element(annual_efficiency, "Value", Float(efficiency_value))
      end

      XMLHelper.add_element(cooling_system, "SensibleHeatFraction", Float(@cooling_shr)) unless @cooling_shr.nil?
      _add_extension(parent: cooling_system,
                     extensions: { "CoolingFlowRate" => _to_float_or_nil(@cooling_cfm),
                                   "SeedId" => @seed_id })
    end

    def from_hpxml(cooling_system)
      return if cooling_system.nil?

      @id = _get_id(cooling_system)
      @distribution_system_idref = _get_idref(cooling_system.elements["DistributionSystem"])
      @year_installed = _to_integer_or_nil(XMLHelper.get_value(cooling_system, "YearInstalled"))
      @cooling_system_type = XMLHelper.get_value(cooling_system, "CoolingSystemType")
      @cooling_system_fuel = XMLHelper.get_value(cooling_system, "CoolingSystemFuel")
      @cooling_capacity = _to_float_or_nil(XMLHelper.get_value(cooling_system, "CoolingCapacity"))
      @compressor_type = XMLHelper.get_value(cooling_system, "CompressorType")
      @fraction_cool_load_served = _to_float_or_nil(XMLHelper.get_value(cooling_system, "FractionCoolLoadServed"))
      @cooling_efficiency_seer = _to_float_or_nil(XMLHelper.get_value(cooling_system, "[CoolingSystemType='central air conditioner']AnnualCoolingEfficiency[Units='SEER']/Value"))
      @cooling_efficiency_eer = _to_float_or_nil(XMLHelper.get_value(cooling_system, "[CoolingSystemType='room air conditioner']AnnualCoolingEfficiency[Units='EER']/Value"))
      @cooling_shr = _to_float_or_nil(XMLHelper.get_value(cooling_system, "SensibleHeatFraction"))
      @cooling_cfm = _to_float_or_nil(XMLHelper.get_value(cooling_system, "extension/CoolingFlowRate"))
      @energy_star = XMLHelper.get_values(cooling_system, "ThirdPartyCertification").include?("Energy Star")
      @seed_id = XMLHelper.get_value(cooling_system, "extension/SeedId")
    end
  end

  class HeatPumps < BaseArrayElement
    def add(**kwargs)
      self << HeatPump.new(**kwargs)
    end

    def from_hpxml(hpxml)
      return if hpxml.nil?

      hpxml.elements.each("Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatPump") do |heat_pump|
        self << HeatPump.new(heat_pump)
      end
    end
  end

  class HeatPump < BaseElement
    ATTRS = [:id, :distribution_system_idref, :year_installed, :heat_pump_type, :heat_pump_fuel,
             :heating_capacity, :heating_capacity_17F, :cooling_capacity, :compressor_type,
             :cooling_shr, :backup_heating_fuel, :backup_heating_capacity,
             :backup_heating_efficiency_percent, :backup_heating_efficiency_afue,
             :backup_heating_switchover_temp, :fraction_heat_load_served, :fraction_cool_load_served,
             :cooling_efficiency_seer, :cooling_efficiency_eer, :heating_efficiency_hspf,
             :heating_efficiency_cop, :energy_star, :seed_id]
    attr_accessor(*ATTRS)

    def to_rexml(doc)
      return if self.nil?

      hvac_plant = XMLHelper.create_elements_as_needed(doc, ["HPXML", "Building", "BuildingDetails", "Systems", "HVAC", "HVACPlant"])
      heat_pump = XMLHelper.add_element(hvac_plant, "HeatPump")
      sys_id = XMLHelper.add_element(heat_pump, "SystemIdentifier")
      XMLHelper.add_attribute(sys_id, "id", @id)
      if not @distribution_system_idref.nil?
        distribution_system = XMLHelper.add_element(heat_pump, "DistributionSystem")
        XMLHelper.add_attribute(distribution_system, "idref", @distribution_system_idref)
      end
      XMLHelper.add_element(heat_pump, "HeatPumpType", @heat_pump_type) unless @heat_pump_type.nil?
      XMLHelper.add_element(heat_pump, "HeatPumpFuel", @heat_pump_fuel) unless @heat_pump_fuel.nil?
      XMLHelper.add_element(heat_pump, "HeatingCapacity", Float(@heating_capacity)) unless @heating_capacity.nil?
      XMLHelper.add_element(heat_pump, "HeatingCapacity17F", Float(@heating_capacity_17F)) unless @heating_capacity_17F.nil?
      XMLHelper.add_element(heat_pump, "CoolingCapacity", Float(@cooling_capacity)) unless @cooling_capacity.nil?
      XMLHelper.add_element(heat_pump, "CompressorType", @compressor_type) unless @compressor_type.nil?
      XMLHelper.add_element(heat_pump, "CoolingSensibleHeatFraction", Float(@cooling_shr)) unless @cooling_shr.nil?
      if not @backup_heating_fuel.nil?
        XMLHelper.add_element(heat_pump, "BackupSystemFuel", @backup_heating_fuel)
        efficiencies = { "Percent" => @backup_heating_efficiency_percent,
                         "AFUE" => @backup_heating_efficiency_afue }
        efficiencies.each do |units, value|
          next if value.nil?

          backup_eff = XMLHelper.add_element(heat_pump, "BackupAnnualHeatingEfficiency")
          XMLHelper.add_element(backup_eff, "Units", units)
          XMLHelper.add_element(backup_eff, "Value", Float(value))
        end
        XMLHelper.add_element(heat_pump, "BackupHeatingCapacity", Float(@backup_heating_capacity)) unless @backup_heating_capacity.nil?
        XMLHelper.add_element(heat_pump, "BackupHeatingSwitchoverTemperature", Float(@backup_heating_switchover_temp)) unless @backup_heating_switchover_temp.nil?
      end
      XMLHelper.add_element(heat_pump, "FractionHeatLoadServed", Float(@fraction_heat_load_served)) unless @fraction_heat_load_served.nil?
      XMLHelper.add_element(heat_pump, "FractionCoolLoadServed", Float(@fraction_cool_load_served)) unless @fraction_cool_load_served.nil?

      clg_efficiency_units = nil
      clg_efficiency_value = nil
      htg_efficiency_units = nil
      htg_efficiency_value = nil
      if ["air-to-air", "mini-split"].include? @heat_pump_type
        clg_efficiency_units = "SEER"
        clg_efficiency_value = @cooling_efficiency_seer
        htg_efficiency_units = "HSPF"
        htg_efficiency_value = @heating_efficiency_hspf
      elsif ["ground-to-air"].include? @heat_pump_type
        clg_efficiency_units = "EER"
        clg_efficiency_value = @cooling_efficiency_eer
        htg_efficiency_units = "COP"
        htg_efficiency_value = @heating_efficiency_cop
      end
      if not clg_efficiency_value.nil?
        annual_efficiency = XMLHelper.add_element(heat_pump, "AnnualCoolingEfficiency")
        XMLHelper.add_element(annual_efficiency, "Units", clg_efficiency_units)
        XMLHelper.add_element(annual_efficiency, "Value", Float(clg_efficiency_value))
      end
      if not htg_efficiency_value.nil?
        annual_efficiency = XMLHelper.add_element(heat_pump, "AnnualHeatingEfficiency")
        XMLHelper.add_element(annual_efficiency, "Units", htg_efficiency_units)
        XMLHelper.add_element(annual_efficiency, "Value", Float(htg_efficiency_value))
      end

      _add_extension(parent: heat_pump,
                     extensions: { "SeedId" => @seed_id })
    end

    def from_hpxml(heat_pump)
      return if heat_pump.nil?

      @id = _get_id(heat_pump)
      @distribution_system_idref = _get_idref(heat_pump.elements["DistributionSystem"])
      @year_installed = _to_integer_or_nil(XMLHelper.get_value(heat_pump, "YearInstalled"))
      @heat_pump_type = XMLHelper.get_value(heat_pump, "HeatPumpType")
      @heat_pump_fuel = XMLHelper.get_value(heat_pump, "HeatPumpFuel")
      @heating_capacity = _to_float_or_nil(XMLHelper.get_value(heat_pump, "HeatingCapacity"))
      @heating_capacity_17F = _to_float_or_nil(XMLHelper.get_value(heat_pump, "HeatingCapacity17F"))
      @cooling_capacity = _to_float_or_nil(XMLHelper.get_value(heat_pump, "CoolingCapacity"))
      @compressor_type = XMLHelper.get_value(heat_pump, "CompressorType")
      @cooling_shr = _to_float_or_nil(XMLHelper.get_value(heat_pump, "CoolingSensibleHeatFraction"))
      @backup_heating_fuel = XMLHelper.get_value(heat_pump, "BackupSystemFuel")
      @backup_heating_capacity = _to_float_or_nil(XMLHelper.get_value(heat_pump, "BackupHeatingCapacity"))
      @backup_heating_efficiency_percent = _to_float_or_nil(XMLHelper.get_value(heat_pump, "BackupAnnualHeatingEfficiency[Units='Percent']/Value"))
      @backup_heating_efficiency_afue = _to_float_or_nil(XMLHelper.get_value(heat_pump, "BackupAnnualHeatingEfficiency[Units='AFUE']/Value"))
      @backup_heating_switchover_temp = _to_float_or_nil(XMLHelper.get_value(heat_pump, "BackupHeatingSwitchoverTemperature"))
      @fraction_heat_load_served = _to_float_or_nil(XMLHelper.get_value(heat_pump, "FractionHeatLoadServed"))
      @fraction_cool_load_served = _to_float_or_nil(XMLHelper.get_value(heat_pump, "FractionCoolLoadServed"))
      @cooling_efficiency_seer = _to_float_or_nil(XMLHelper.get_value(heat_pump, "[HeatPumpType='air-to-air' or HeatPumpType='mini-split']AnnualCoolingEfficiency[Units='SEER']/Value"))
      @cooling_efficiency_eer = _to_float_or_nil(XMLHelper.get_value(heat_pump, "[HeatPumpType='ground-to-air']AnnualCoolingEfficiency[Units='EER']/Value"))
      @heating_efficiency_hspf = _to_float_or_nil(XMLHelper.get_value(heat_pump, "[HeatPumpType='air-to-air' or HeatPumpType='mini-split']AnnualHeatingEfficiency[Units='HSPF']/Value"))
      @heating_efficiency_cop = _to_float_or_nil(XMLHelper.get_value(heat_pump, "[HeatPumpType='ground-to-air']AnnualHeatingEfficiency[Units='COP']/Value"))
      @energy_star = XMLHelper.get_values(heat_pump, "ThirdPartyCertification").include?("Energy Star")
      @seed_id = XMLHelper.get_value(heat_pump, "extension/SeedId")
    end
  end

  class HVACControl < BaseElement
    ATTRS = [:id, :control_type, :heating_setpoint_temp, :heating_setback_temp,
             :heating_setback_hours_per_week, :heating_setback_start_hour, :cooling_setpoint_temp,
             :cooling_setup_temp, :cooling_setup_hours_per_week, :cooling_setup_start_hour,
             :ceiling_fan_cooling_setpoint_temp_offset]
    attr_accessor(*ATTRS)

    def to_rexml(doc)
      return if self.nil?

      hvac = XMLHelper.create_elements_as_needed(doc, ["HPXML", "Building", "BuildingDetails", "Systems", "HVAC"])
      hvac_control = XMLHelper.add_element(hvac, "HVACControl")
      sys_id = XMLHelper.add_element(hvac_control, "SystemIdentifier")
      XMLHelper.add_attribute(sys_id, "id", @id)
      XMLHelper.add_element(hvac_control, "ControlType", @control_type) unless @control_type.nil?
      XMLHelper.add_element(hvac_control, "SetpointTempHeatingSeason", Float(@heating_setpoint_temp)) unless @heating_setpoint_temp.nil?
      XMLHelper.add_element(hvac_control, "SetbackTempHeatingSeason", Float(@heating_setback_temp)) unless @heating_setback_temp.nil?
      XMLHelper.add_element(hvac_control, "TotalSetbackHoursperWeekHeating", Integer(@heating_setback_hours_per_week)) unless @heating_setback_hours_per_week.nil?
      XMLHelper.add_element(hvac_control, "SetupTempCoolingSeason", Float(@cooling_setup_temp)) unless @cooling_setup_temp.nil?
      XMLHelper.add_element(hvac_control, "SetpointTempCoolingSeason", Float(@cooling_setpoint_temp)) unless @cooling_setpoint_temp.nil?
      XMLHelper.add_element(hvac_control, "TotalSetupHoursperWeekCooling", Integer(@cooling_setup_hours_per_week)) unless @cooling_setup_hours_per_week.nil?
      _add_extension(parent: hvac_control,
                     extensions: { "SetbackStartHourHeating" => _to_integer_or_nil(@heating_setback_start_hour),
                                   "SetupStartHourCooling" => _to_integer_or_nil(@cooling_setup_start_hour),
                                   "CeilingFanSetpointTempCoolingSeasonOffset" => _to_float_or_nil(@ceiling_fan_cooling_setpoint_temp_offset) })
    end

    def from_hpxml(hpxml)
      return if hpxml.nil?

      hvac_control = hpxml.elements["Building/BuildingDetails/Systems/HVAC/HVACControl"]
      return if hvac_control.nil?

      @id = _get_id(hvac_control)
      @control_type = XMLHelper.get_value(hvac_control, "ControlType")
      @heating_setpoint_temp = _to_float_or_nil(XMLHelper.get_value(hvac_control, "SetpointTempHeatingSeason"))
      @heating_setback_temp = _to_float_or_nil(XMLHelper.get_value(hvac_control, "SetbackTempHeatingSeason"))
      @heating_setback_hours_per_week = _to_integer_or_nil(XMLHelper.get_value(hvac_control, "TotalSetbackHoursperWeekHeating"))
      @heating_setback_start_hour = _to_integer_or_nil(XMLHelper.get_value(hvac_control, "extension/SetbackStartHourHeating"))
      @cooling_setpoint_temp = _to_float_or_nil(XMLHelper.get_value(hvac_control, "SetpointTempCoolingSeason"))
      @cooling_setup_temp = _to_float_or_nil(XMLHelper.get_value(hvac_control, "SetupTempCoolingSeason"))
      @cooling_setup_hours_per_week = _to_integer_or_nil(XMLHelper.get_value(hvac_control, "TotalSetupHoursperWeekCooling"))
      @cooling_setup_start_hour = _to_integer_or_nil(XMLHelper.get_value(hvac_control, "extension/SetupStartHourCooling"))
      @ceiling_fan_cooling_setpoint_temp_offset = _to_float_or_nil(XMLHelper.get_value(hvac_control, "extension/CeilingFanSetpointTempCoolingSeasonOffset"))
    end
  end

  class HVACDistributions < BaseArrayElement
    def add(**kwargs)
      self << HVACDistribution.new(**kwargs)
    end

    def from_hpxml(hpxml)
      return if hpxml.nil?

      hpxml.elements.each("Building/BuildingDetails/Systems/HVAC/HVACDistribution") do |hvac_distribution|
        self << HVACDistribution.new(hvac_distribution)
      end
    end
  end

  class HVACDistribution < BaseElement
    def initialize(*args)
      @duct_leakage_measurements = DuctLeakageMeasurements.new if @duct_leakage_measurements.nil?
      @ducts = Ducts.new if @ducts.nil?
      super(*args)
    end
    ATTRS = [:id, :distribution_system_type, :distribution_system_type, :annual_heating_dse,
             :annual_cooling_dse, :duct_system_sealed]
    attr_accessor(*ATTRS)
    attr_reader(:duct_leakage_measurements, :ducts)

    def to_rexml(doc)
      return if self.nil?

      hvac = XMLHelper.create_elements_as_needed(doc, ["HPXML", "Building", "BuildingDetails", "Systems", "HVAC"])
      hvac_distribution = XMLHelper.add_element(hvac, "HVACDistribution")
      sys_id = XMLHelper.add_element(hvac_distribution, "SystemIdentifier")
      XMLHelper.add_attribute(sys_id, "id", @id)
      distribution_system_type_e = XMLHelper.add_element(hvac_distribution, "DistributionSystemType")
      if ["AirDistribution", "HydronicDistribution"].include? @distribution_system_type
        XMLHelper.add_element(distribution_system_type_e, @distribution_system_type)
      elsif ["DSE"].include? distribution_system_type
        XMLHelper.add_element(distribution_system_type_e, "Other", @distribution_system_type)
        XMLHelper.add_element(hvac_distribution, "AnnualHeatingDistributionSystemEfficiency", Float(@annual_heating_dse)) unless @annual_heating_dse.nil?
        XMLHelper.add_element(hvac_distribution, "AnnualCoolingDistributionSystemEfficiency", Float(@annual_cooling_dse)) unless @annual_cooling_dse.nil?
      else
        fail "Unexpected distribution_system_type '#{@distribution_system_type}'."
      end

      air_distribution = hvac_distribution.elements["DistributionSystemType/AirDistribution"]
      return if air_distribution.nil?

      @duct_leakage_measurements.to_rexml(air_distribution)
      @ducts.to_rexml(air_distribution)
    end

    def from_hpxml(hvac_distribution)
      return if hvac_distribution.nil?

      @id = _get_id(hvac_distribution)
      @distribution_system_type = XMLHelper.get_child_name(hvac_distribution, "DistributionSystemType")
      if @distribution_system_type == "Other"
        @distribution_system_type = XMLHelper.get_value(hvac_distribution.elements["DistributionSystemType"], "Other")
      end
      @annual_heating_dse = _to_float_or_nil(XMLHelper.get_value(hvac_distribution, "AnnualHeatingDistributionSystemEfficiency"))
      @annual_cooling_dse = _to_float_or_nil(XMLHelper.get_value(hvac_distribution, "AnnualCoolingDistributionSystemEfficiency"))
      @duct_system_sealed = _to_bool_or_nil(XMLHelper.get_value(hvac_distribution, "HVACDistributionImprovement/DuctSystemSealed"))

      @duct_leakage_measurements.from_hpxml(hvac_distribution)
      @ducts.from_hpxml(hvac_distribution)
    end
  end

  class DuctLeakageMeasurements < BaseArrayElement
    def add(**kwargs)
      self << DuctLeakageMeasurement.new(**kwargs)
    end

    def from_hpxml(hvac_distribution)
      return if hvac_distribution.nil?

      hvac_distribution.elements.each("DistributionSystemType/AirDistribution/DuctLeakageMeasurement") do |duct_leakage_measurement|
        self << DuctLeakageMeasurement.new(duct_leakage_measurement)
      end
    end
  end

  class DuctLeakageMeasurement < BaseElement
    ATTRS = [:duct_type, :duct_leakage_test_method, :duct_leakage_units, :duct_leakage_value,
             :duct_leakage_total_or_to_outside]
    attr_accessor(*ATTRS)

    def to_rexml(air_distribution)
      duct_leakage_measurement_el = XMLHelper.add_element(air_distribution, "DuctLeakageMeasurement")
      XMLHelper.add_element(duct_leakage_measurement_el, "DuctType", @duct_type)
      if not @duct_leakage_value.nil?
        duct_leakage_el = XMLHelper.add_element(duct_leakage_measurement_el, "DuctLeakage")
        XMLHelper.add_element(duct_leakage_el, "Units", @duct_leakage_units)
        XMLHelper.add_element(duct_leakage_el, "Value", Float(@duct_leakage_value))
        XMLHelper.add_element(duct_leakage_el, "TotalOrToOutside", "to outside")
      end
    end

    def from_hpxml(duct_leakage_measurement)
      return if duct_leakage_measurement.nil?

      @duct_type = XMLHelper.get_value(duct_leakage_measurement, "DuctType")
      @duct_leakage_test_method = XMLHelper.get_value(duct_leakage_measurement, "DuctLeakageTestMethod")
      @duct_leakage_units = XMLHelper.get_value(duct_leakage_measurement, "DuctLeakage/Units")
      @duct_leakage_value = _to_float_or_nil(XMLHelper.get_value(duct_leakage_measurement, "DuctLeakage/Value"))
      @duct_leakage_total_or_to_outside = XMLHelper.get_value(duct_leakage_measurement, "DuctLeakage/TotalOrToOutside")
    end
  end

  class Ducts < BaseArrayElement
    def add(**kwargs)
      self << Duct.new(**kwargs)
    end

    def from_hpxml(hvac_distribution)
      return if hvac_distribution.nil?

      hvac_distribution.elements.each("DistributionSystemType/AirDistribution/Ducts") do |duct|
        self << Duct.new(duct)
      end
    end
  end

  class Duct < BaseElement
    ATTRS = [:duct_type, :duct_insulation_r_value, :duct_insulation_material, :duct_location,
             :duct_fraction_area, :duct_surface_area]
    attr_accessor(*ATTRS)

    def to_rexml(air_distribution)
      ducts_el = XMLHelper.add_element(air_distribution, "Ducts")
      XMLHelper.add_element(ducts_el, "DuctType", @duct_type) unless @duct_type.nil?
      XMLHelper.add_element(ducts_el, "DuctInsulationRValue", Float(@duct_insulation_r_value)) unless @duct_insulation_r_value.nil?
      XMLHelper.add_element(ducts_el, "DuctLocation", @duct_location) unless @duct_location.nil?
      XMLHelper.add_element(ducts_el, "DuctSurfaceArea", Float(@duct_surface_area)) unless @duct_surface_area.nil?
    end

    def from_hpxml(duct)
      return if duct.nil?

      @duct_type = XMLHelper.get_value(duct, "DuctType")
      @duct_insulation_r_value = _to_float_or_nil(XMLHelper.get_value(duct, "DuctInsulationRValue"))
      @duct_insulation_material = XMLHelper.get_child_name(duct, "DuctInsulationMaterial")
      @duct_location = XMLHelper.get_value(duct, "DuctLocation")
      @duct_fraction_area = _to_float_or_nil(XMLHelper.get_value(duct, "FractionDuctArea"))
      @duct_surface_area = _to_float_or_nil(XMLHelper.get_value(duct, "DuctSurfaceArea"))
    end
  end

  class VentilationFans < BaseArrayElement
    def add(**kwargs)
      self << VentilationFan.new(**kwargs)
    end

    def from_hpxml(hpxml)
      return if hpxml.nil?

      hpxml.elements.each("Building/BuildingDetails/Systems/MechanicalVentilation/VentilationFans/VentilationFan") do |ventilation_fan|
        self << VentilationFan.new(ventilation_fan)
      end
    end
  end

  class VentilationFan < BaseElement
    ATTRS = [:id, :fan_type, :rated_flow_rate, :tested_flow_rate, :hours_in_operation,
             :used_for_whole_building_ventilation, :used_for_seasonal_cooling_load_reduction,
             :total_recovery_efficiency, :total_recovery_efficiency_adjusted,
             :sensible_recovery_efficiency, :sensible_recovery_efficiency_adjusted,
             :fan_power, :distribution_system_idref]
    attr_accessor(*ATTRS)

    def to_rexml(doc)
      return if self.nil?

      ventilation_fans = XMLHelper.create_elements_as_needed(doc, ["HPXML", "Building", "BuildingDetails", "Systems", "MechanicalVentilation", "VentilationFans"])
      ventilation_fan = XMLHelper.add_element(ventilation_fans, "VentilationFan")
      sys_id = XMLHelper.add_element(ventilation_fan, "SystemIdentifier")
      XMLHelper.add_attribute(sys_id, "id", @id)
      XMLHelper.add_element(ventilation_fan, "FanType", @fan_type) unless @fan_type.nil?
      XMLHelper.add_element(ventilation_fan, "RatedFlowRate", Float(@rated_flow_rate)) unless @rated_flow_rate.nil?
      XMLHelper.add_element(ventilation_fan, "TestedFlowRate", Float(@tested_flow_rate)) unless @tested_flow_rate.nil?
      XMLHelper.add_element(ventilation_fan, "HoursInOperation", Float(@hours_in_operation)) unless @hours_in_operation.nil?
      XMLHelper.add_element(ventilation_fan, "UsedForWholeBuildingVentilation", Boolean(@used_for_whole_building_ventilation)) unless @used_for_whole_building_ventilation.nil?
      XMLHelper.add_element(ventilation_fan, "UsedForSeasonalCoolingLoadReduction", Boolean(@used_for_seasonal_cooling_load_reduction)) unless @used_for_seasonal_cooling_load_reduction.nil?
      XMLHelper.add_element(ventilation_fan, "TotalRecoveryEfficiency", Float(@total_recovery_efficiency)) unless @total_recovery_efficiency.nil?
      XMLHelper.add_element(ventilation_fan, "SensibleRecoveryEfficiency", Float(@sensible_recovery_efficiency)) unless @sensible_recovery_efficiency.nil?
      XMLHelper.add_element(ventilation_fan, "AdjustedTotalRecoveryEfficiency", Float(@total_recovery_efficiency_adjusted)) unless @total_recovery_efficiency_adjusted.nil?
      XMLHelper.add_element(ventilation_fan, "AdjustedSensibleRecoveryEfficiency", Float(@sensible_recovery_efficiency_adjusted)) unless @sensible_recovery_efficiency_adjusted.nil?
      XMLHelper.add_element(ventilation_fan, "FanPower", Float(@fan_power)) unless @fan_power.nil?
      if not @distribution_system_idref.nil?
        attached_to_hvac_distribution_system = XMLHelper.add_element(ventilation_fan, "AttachedToHVACDistributionSystem")
        XMLHelper.add_attribute(attached_to_hvac_distribution_system, "idref", @distribution_system_idref)
      end
    end

    def from_hpxml(ventilation_fan)
      return if ventilation_fan.nil?

      @id = _get_id(ventilation_fan)
      @fan_type = XMLHelper.get_value(ventilation_fan, "FanType")
      @rated_flow_rate = _to_float_or_nil(XMLHelper.get_value(ventilation_fan, "RatedFlowRate"))
      @tested_flow_rate = _to_float_or_nil(XMLHelper.get_value(ventilation_fan, "TestedFlowRate"))
      @hours_in_operation = _to_float_or_nil(XMLHelper.get_value(ventilation_fan, "HoursInOperation"))
      @used_for_whole_building_ventilation = _to_bool_or_nil(XMLHelper.get_value(ventilation_fan, "UsedForWholeBuildingVentilation"))
      @used_for_seasonal_cooling_load_reduction = _to_bool_or_nil(XMLHelper.get_value(ventilation_fan, "UsedForSeasonalCoolingLoadReduction"))
      @total_recovery_efficiency = _to_float_or_nil(XMLHelper.get_value(ventilation_fan, "TotalRecoveryEfficiency"))
      @total_recovery_efficiency_adjusted = _to_float_or_nil(XMLHelper.get_value(ventilation_fan, "AdjustedTotalRecoveryEfficiency"))
      @sensible_recovery_efficiency = _to_float_or_nil(XMLHelper.get_value(ventilation_fan, "SensibleRecoveryEfficiency"))
      @sensible_recovery_efficiency_adjusted = _to_float_or_nil(XMLHelper.get_value(ventilation_fan, "AdjustedSensibleRecoveryEfficiency"))
      @fan_power = _to_float_or_nil(XMLHelper.get_value(ventilation_fan, "FanPower"))
      @distribution_system_idref = _get_idref(ventilation_fan.elements["AttachedToHVACDistributionSystem"])
    end
  end

  class WaterHeatingSystems < BaseArrayElement
    def add(**kwargs)
      self << WaterHeatingSystem.new(**kwargs)
    end

    def from_hpxml(hpxml)
      return if hpxml.nil?

      hpxml.elements.each("Building/BuildingDetails/Systems/WaterHeating/WaterHeatingSystem") do |water_heating_system|
        self << WaterHeatingSystem.new(water_heating_system)
      end
    end
  end

  class WaterHeatingSystem < BaseElement
    ATTRS = [:id, :year_installed, :fuel_type, :water_heater_type, :location, :performance_adjustment,
             :tank_volume, :fraction_dhw_load_served, :heating_capacity, :energy_factor,
             :uniform_energy_factor, :recovery_efficiency, :uses_desuperheater, :jacket_r_value,
             :related_hvac, :energy_star, :standby_loss, :temperature]
    attr_accessor(*ATTRS)

    def to_rexml(doc)
      return if self.nil?

      water_heating = XMLHelper.create_elements_as_needed(doc, ["HPXML", "Building", "BuildingDetails", "Systems", "WaterHeating"])
      water_heating_system = XMLHelper.add_element(water_heating, "WaterHeatingSystem")
      sys_id = XMLHelper.add_element(water_heating_system, "SystemIdentifier")
      XMLHelper.add_attribute(sys_id, "id", @id)
      XMLHelper.add_element(water_heating_system, "FuelType", @fuel_type) unless @fuel_type.nil?
      XMLHelper.add_element(water_heating_system, "WaterHeaterType", @water_heater_type) unless @water_heater_type.nil?
      XMLHelper.add_element(water_heating_system, "Location", @location) unless @location.nil?
      XMLHelper.add_element(water_heating_system, "PerformanceAdjustment", Float(@performance_adjustment)) unless @performance_adjustment.nil?
      XMLHelper.add_element(water_heating_system, "TankVolume", Float(@tank_volume)) unless @tank_volume.nil?
      XMLHelper.add_element(water_heating_system, "FractionDHWLoadServed", Float(@fraction_dhw_load_served)) unless @fraction_dhw_load_served.nil?
      XMLHelper.add_element(water_heating_system, "HeatingCapacity", Float(@heating_capacity)) unless @heating_capacity.nil?
      XMLHelper.add_element(water_heating_system, "EnergyFactor", Float(@energy_factor)) unless @energy_factor.nil?
      XMLHelper.add_element(water_heating_system, "UniformEnergyFactor", Float(@uniform_energy_factor)) unless @uniform_energy_factor.nil?
      XMLHelper.add_element(water_heating_system, "RecoveryEfficiency", Float(@recovery_efficiency)) unless @recovery_efficiency.nil?
      if not @jacket_r_value.nil?
        water_heater_insulation = XMLHelper.add_element(water_heating_system, "WaterHeaterInsulation")
        jacket = XMLHelper.add_element(water_heater_insulation, "Jacket")
        XMLHelper.add_element(jacket, "JacketRValue", @jacket_r_value)
      end
      XMLHelper.add_element(water_heating_system, "StandbyLoss", Float(@standby_loss)) unless @standby_loss.nil?
      XMLHelper.add_element(water_heating_system, "HotWaterTemperature", Float(@temperature)) unless @temperature.nil?
      XMLHelper.add_element(water_heating_system, "UsesDesuperheater", Boolean(@uses_desuperheater)) unless @uses_desuperheater.nil?
      if not @related_hvac.nil?
        related_hvac_el = XMLHelper.add_element(water_heating_system, "RelatedHVACSystem")
        XMLHelper.add_attribute(related_hvac_el, "idref", @related_hvac)
      end
    end

    def from_hpxml(water_heating_system)
      return if water_heating_system.nil?

      @id = _get_id(water_heating_system)
      @year_installed = _to_integer_or_nil(XMLHelper.get_value(water_heating_system, "YearInstalled"))
      @fuel_type = XMLHelper.get_value(water_heating_system, "FuelType")
      @water_heater_type = XMLHelper.get_value(water_heating_system, "WaterHeaterType")
      @location = XMLHelper.get_value(water_heating_system, "Location")
      @performance_adjustment = _to_float_or_nil(XMLHelper.get_value(water_heating_system, "PerformanceAdjustment"))
      @tank_volume = _to_float_or_nil(XMLHelper.get_value(water_heating_system, "TankVolume"))
      @fraction_dhw_load_served = _to_float_or_nil(XMLHelper.get_value(water_heating_system, "FractionDHWLoadServed"))
      @heating_capacity = _to_float_or_nil(XMLHelper.get_value(water_heating_system, "HeatingCapacity"))
      @energy_factor = _to_float_or_nil(XMLHelper.get_value(water_heating_system, "EnergyFactor"))
      @uniform_energy_factor = _to_float_or_nil(XMLHelper.get_value(water_heating_system, "UniformEnergyFactor"))
      @recovery_efficiency = _to_float_or_nil(XMLHelper.get_value(water_heating_system, "RecoveryEfficiency"))
      @uses_desuperheater = _to_bool_or_nil(XMLHelper.get_value(water_heating_system, "UsesDesuperheater"))
      @jacket_r_value = _to_float_or_nil(XMLHelper.get_value(water_heating_system, "WaterHeaterInsulation/Jacket/JacketRValue"))
      @related_hvac = _get_idref(water_heating_system.elements["RelatedHVACSystem"])
      @energy_star = XMLHelper.get_values(water_heating_system, "ThirdPartyCertification").include?("Energy Star")
      @standby_loss = _to_float_or_nil(XMLHelper.get_value(water_heating_system, "StandbyLoss"))
      @temperature = _to_float_or_nil(XMLHelper.get_value(water_heating_system, "HotWaterTemperature"))
    end
  end

  class HotWaterDistribution < BaseElement
    ATTRS = [:id, :system_type, :pipe_r_value, :standard_piping_length, :recirculation_control_type,
             :recirculation_piping_length, :recirculation_branch_piping_length,
             :recirculation_pump_power, :dwhr_facilities_connected, :dwhr_equal_flow,
             :dwhr_efficiency]
    attr_accessor(*ATTRS)

    def to_rexml(doc)
      return if self.nil?

      water_heating = XMLHelper.create_elements_as_needed(doc, ["HPXML", "Building", "BuildingDetails", "Systems", "WaterHeating"])
      hot_water_distribution = XMLHelper.add_element(water_heating, "HotWaterDistribution")
      sys_id = XMLHelper.add_element(hot_water_distribution, "SystemIdentifier")
      XMLHelper.add_attribute(sys_id, "id", @id)
      if not @system_type.nil?
        system_type_e = XMLHelper.add_element(hot_water_distribution, "SystemType")
        if @system_type == "Standard"
          standard = XMLHelper.add_element(system_type_e, @system_type)
          XMLHelper.add_element(standard, "PipingLength", Float(@standard_piping_length)) unless @standard_piping_length.nil?
        elsif system_type == "Recirculation"
          recirculation = XMLHelper.add_element(system_type_e, @system_type)
          XMLHelper.add_element(recirculation, "ControlType", @recirculation_control_type) unless @recirculation_control_type.nil?
          XMLHelper.add_element(recirculation, "RecirculationPipingLoopLength", Float(@recirculation_piping_length)) unless @recirculation_piping_length.nil?
          XMLHelper.add_element(recirculation, "BranchPipingLoopLength", Float(@recirculation_branch_piping_length)) unless @recirculation_branch_piping_length.nil?
          XMLHelper.add_element(recirculation, "PumpPower", Float(@recirculation_pump_power)) unless @recirculation_pump_power.nil?
        else
          fail "Unhandled hot water distribution type '#{@system_type}'."
        end
      end
      if not @pipe_r_value.nil?
        pipe_insulation = XMLHelper.add_element(hot_water_distribution, "PipeInsulation")
        XMLHelper.add_element(pipe_insulation, "PipeRValue", Float(@pipe_r_value))
      end
      if not @dwhr_facilities_connected.nil? or not @dwhr_equal_flow.nil? or not @dwhr_efficiency.nil?
        drain_water_heat_recovery = XMLHelper.add_element(hot_water_distribution, "DrainWaterHeatRecovery")
        XMLHelper.add_element(drain_water_heat_recovery, "FacilitiesConnected", @dwhr_facilities_connected) unless @dwhr_facilities_connected.nil?
        XMLHelper.add_element(drain_water_heat_recovery, "EqualFlow", Boolean(@dwhr_equal_flow)) unless @dwhr_equal_flow.nil?
        XMLHelper.add_element(drain_water_heat_recovery, "Efficiency", Float(@dwhr_efficiency)) unless @dwhr_efficiency.nil?
      end
    end

    def from_hpxml(hpxml)
      return if hpxml.nil?

      hot_water_distribution = hpxml.elements["Building/BuildingDetails/Systems/WaterHeating/HotWaterDistribution"]
      return if hot_water_distribution.nil?

      @id = _get_id(hot_water_distribution)
      @system_type = XMLHelper.get_child_name(hot_water_distribution, "SystemType")
      @pipe_r_value = _to_float_or_nil(XMLHelper.get_value(hot_water_distribution, "PipeInsulation/PipeRValue"))
      @standard_piping_length = _to_float_or_nil(XMLHelper.get_value(hot_water_distribution, "SystemType/Standard/PipingLength"))
      @recirculation_control_type = XMLHelper.get_value(hot_water_distribution, "SystemType/Recirculation/ControlType")
      @recirculation_piping_length = _to_float_or_nil(XMLHelper.get_value(hot_water_distribution, "SystemType/Recirculation/RecirculationPipingLoopLength"))
      @recirculation_branch_piping_length = _to_float_or_nil(XMLHelper.get_value(hot_water_distribution, "SystemType/Recirculation/BranchPipingLoopLength"))
      @recirculation_pump_power = _to_float_or_nil(XMLHelper.get_value(hot_water_distribution, "SystemType/Recirculation/PumpPower"))
      @dwhr_facilities_connected = XMLHelper.get_value(hot_water_distribution, "DrainWaterHeatRecovery/FacilitiesConnected")
      @dwhr_equal_flow = _to_bool_or_nil(XMLHelper.get_value(hot_water_distribution, "DrainWaterHeatRecovery/EqualFlow"))
      @dwhr_efficiency = _to_float_or_nil(XMLHelper.get_value(hot_water_distribution, "DrainWaterHeatRecovery/Efficiency"))
    end
  end

  class WaterFixtures < BaseArrayElement
    def add(**kwargs)
      self << WaterFixture.new(**kwargs)
    end

    def from_hpxml(hpxml)
      return if hpxml.nil?

      hpxml.elements.each("Building/BuildingDetails/Systems/WaterHeating/WaterFixture") do |water_fixture|
        self << WaterFixture.new(water_fixture)
      end
    end
  end

  class WaterFixture < BaseElement
    ATTRS = [:id, :water_fixture_type, :low_flow]
    attr_accessor(*ATTRS)

    def to_rexml(doc)
      return if self.nil?

      water_heating = XMLHelper.create_elements_as_needed(doc, ["HPXML", "Building", "BuildingDetails", "Systems", "WaterHeating"])
      water_fixture = XMLHelper.add_element(water_heating, "WaterFixture")
      sys_id = XMLHelper.add_element(water_fixture, "SystemIdentifier")
      XMLHelper.add_attribute(sys_id, "id", @id)
      XMLHelper.add_element(water_fixture, "WaterFixtureType", @water_fixture_type) unless @water_fixture_type.nil?
      XMLHelper.add_element(water_fixture, "LowFlow", Boolean(@low_flow)) unless @low_flow.nil?
    end

    def from_hpxml(water_fixture)
      return if water_fixture.nil?

      @id = _get_id(water_fixture)
      @water_fixture_type = XMLHelper.get_value(water_fixture, "WaterFixtureType")
      @low_flow = _to_bool_or_nil(XMLHelper.get_value(water_fixture, "LowFlow"))
    end
  end

  class SolarThermalSystem < BaseElement
    ATTRS = [:id, :system_type, :collector_area, :collector_loop_type, :collector_azimuth,
             :collector_type, :collector_tilt, :collector_frta, :collector_frul, :storage_volume,
             :water_heating_system_idref, :solar_fraction]
    attr_accessor(*ATTRS)

    def to_rexml(doc)
      return if self.nil?

      solar_thermal = XMLHelper.create_elements_as_needed(doc, ["HPXML", "Building", "BuildingDetails", "Systems", "SolarThermal"])
      solar_thermal_system = XMLHelper.add_element(solar_thermal, "SolarThermalSystem")
      sys_id = XMLHelper.add_element(solar_thermal_system, "SystemIdentifier")
      XMLHelper.add_attribute(sys_id, "id", @id)
      XMLHelper.add_element(solar_thermal_system, "SystemType", @system_type) unless @system_type.nil?
      XMLHelper.add_element(solar_thermal_system, "CollectorArea", Float(@collector_area)) unless @collector_area.nil?
      XMLHelper.add_element(solar_thermal_system, "CollectorLoopType", @collector_loop_type) unless @collector_loop_type.nil?
      XMLHelper.add_element(solar_thermal_system, "CollectorType", @collector_type) unless @collector_type.nil?
      XMLHelper.add_element(solar_thermal_system, "CollectorAzimuth", Integer(@collector_azimuth)) unless @collector_azimuth.nil?
      XMLHelper.add_element(solar_thermal_system, "CollectorTilt", Float(@collector_tilt)) unless @collector_tilt.nil?
      XMLHelper.add_element(solar_thermal_system, "CollectorRatedOpticalEfficiency", Float(@collector_frta)) unless @collector_frta.nil?
      XMLHelper.add_element(solar_thermal_system, "CollectorRatedThermalLosses", Float(@collector_frul)) unless @collector_frul.nil?
      XMLHelper.add_element(solar_thermal_system, "StorageVolume", Float(@storage_volume)) unless @storage_volume.nil?
      if not @water_heating_system_idref.nil?
        connected_to = XMLHelper.add_element(solar_thermal_system, "ConnectedTo")
        XMLHelper.add_attribute(connected_to, "idref", @water_heating_system_idref)
      end
      XMLHelper.add_element(solar_thermal_system, "SolarFraction", Float(@solar_fraction)) unless @solar_fraction.nil?
    end

    def from_hpxml(hpxml)
      return if hpxml.nil?

      solar_thermal_system = hpxml.elements["Building/BuildingDetails/Systems/SolarThermal/SolarThermalSystem"]
      return if solar_thermal_system.nil?

      @id = _get_id(solar_thermal_system)
      @system_type = XMLHelper.get_value(solar_thermal_system, "SystemType")
      @collector_area = _to_float_or_nil(XMLHelper.get_value(solar_thermal_system, "CollectorArea"))
      @collector_loop_type = XMLHelper.get_value(solar_thermal_system, "CollectorLoopType")
      @collector_azimuth = _to_integer_or_nil(XMLHelper.get_value(solar_thermal_system, "CollectorAzimuth"))
      @collector_type = XMLHelper.get_value(solar_thermal_system, "CollectorType")
      @collector_tilt = _to_float_or_nil(XMLHelper.get_value(solar_thermal_system, "CollectorTilt"))
      @collector_frta = _to_float_or_nil(XMLHelper.get_value(solar_thermal_system, "CollectorRatedOpticalEfficiency"))
      @collector_frul = _to_float_or_nil(XMLHelper.get_value(solar_thermal_system, "CollectorRatedThermalLosses"))
      @storage_volume = _to_float_or_nil(XMLHelper.get_value(solar_thermal_system, "StorageVolume"))
      @water_heating_system_idref = _get_idref(solar_thermal_system.elements["ConnectedTo"])
      @solar_fraction = _to_float_or_nil(XMLHelper.get_value(solar_thermal_system, "SolarFraction"))
    end
  end

  class PVSystems < BaseArrayElement
    def add(**kwargs)
      self << PVSystem.new(**kwargs)
    end

    def from_hpxml(hpxml)
      return if hpxml.nil?

      hpxml.elements.each("Building/BuildingDetails/Systems/Photovoltaics/PVSystem") do |pv_system|
        self << PVSystem.new(pv_system)
      end
    end
  end

  class PVSystem < BaseElement
    ATTRS = [:id, :location, :module_type, :tracking, :array_orientation, :array_azimuth, :array_tilt,
             :max_power_output, :inverter_efficiency, :system_losses_fraction, :number_of_panels,
             :year_modules_manufactured]
    attr_accessor(*ATTRS)

    def to_rexml(doc)
      return if self.nil?

      photovoltaics = XMLHelper.create_elements_as_needed(doc, ["HPXML", "Building", "BuildingDetails", "Systems", "Photovoltaics"])
      pv_system = XMLHelper.add_element(photovoltaics, "PVSystem")
      sys_id = XMLHelper.add_element(pv_system, "SystemIdentifier")
      XMLHelper.add_attribute(sys_id, "id", @id)
      XMLHelper.add_element(pv_system, "Location", @location) unless @location.nil?
      XMLHelper.add_element(pv_system, "ModuleType", @module_type) unless @module_type.nil?
      XMLHelper.add_element(pv_system, "Tracking", @tracking) unless @tracking.nil?
      XMLHelper.add_element(pv_system, "ArrayAzimuth", Integer(@array_azimuth)) unless @array_azimuth.nil?
      XMLHelper.add_element(pv_system, "ArrayTilt", Float(@array_tilt)) unless @array_tilt.nil?
      XMLHelper.add_element(pv_system, "MaxPowerOutput", Float(@max_power_output)) unless @max_power_output.nil?
      XMLHelper.add_element(pv_system, "InverterEfficiency", Float(@inverter_efficiency)) unless @inverter_efficiency.nil?
      XMLHelper.add_element(pv_system, "SystemLossesFraction", Float(@system_losses_fraction)) unless @system_losses_fraction.nil?
    end

    def from_hpxml(pv_system)
      return if pv_system.nil?

      @id = _get_id(pv_system)
      @location = XMLHelper.get_value(pv_system, "Location")
      @module_type = XMLHelper.get_value(pv_system, "ModuleType")
      @tracking = XMLHelper.get_value(pv_system, "Tracking")
      @array_orientation = XMLHelper.get_value(pv_system, "ArrayOrientation")
      @array_azimuth = _to_integer_or_nil(XMLHelper.get_value(pv_system, "ArrayAzimuth"))
      @array_tilt = _to_float_or_nil(XMLHelper.get_value(pv_system, "ArrayTilt"))
      @max_power_output = _to_float_or_nil(XMLHelper.get_value(pv_system, "MaxPowerOutput"))
      @inverter_efficiency = _to_float_or_nil(XMLHelper.get_value(pv_system, "InverterEfficiency"))
      @system_losses_fraction = _to_float_or_nil(XMLHelper.get_value(pv_system, "SystemLossesFraction"))
      @number_of_panels = _to_integer_or_nil(XMLHelper.get_value(pv_system, "NumberOfPanels"))
      @year_modules_manufactured = _to_integer_or_nil(XMLHelper.get_value(pv_system, "YearModulesManufactured"))
    end
  end

  class ClothesWasher < BaseElement
    ATTRS = [:id, :location, :modified_energy_factor, :integrated_modified_energy_factor,
             :rated_annual_kwh, :label_electric_rate, :label_gas_rate, :label_annual_gas_cost,
             :capacity]
    attr_accessor(*ATTRS)

    def to_rexml(doc)
      return if self.nil?

      appliances = XMLHelper.create_elements_as_needed(doc, ["HPXML", "Building", "BuildingDetails", "Appliances"])
      clothes_washer = XMLHelper.add_element(appliances, "ClothesWasher")
      sys_id = XMLHelper.add_element(clothes_washer, "SystemIdentifier")
      XMLHelper.add_attribute(sys_id, "id", @id)
      XMLHelper.add_element(clothes_washer, "Location", @location) unless @location.nil?
      XMLHelper.add_element(clothes_washer, "ModifiedEnergyFactor", Float(@modified_energy_factor)) unless @modified_energy_factor.nil?
      XMLHelper.add_element(clothes_washer, "IntegratedModifiedEnergyFactor", Float(@integrated_modified_energy_factor)) unless @integrated_modified_energy_factor.nil?
      XMLHelper.add_element(clothes_washer, "RatedAnnualkWh", Float(@rated_annual_kwh)) unless @rated_annual_kwh.nil?
      XMLHelper.add_element(clothes_washer, "LabelElectricRate", Float(@label_electric_rate)) unless @label_electric_rate.nil?
      XMLHelper.add_element(clothes_washer, "LabelGasRate", Float(@label_gas_rate)) unless @label_gas_rate.nil?
      XMLHelper.add_element(clothes_washer, "LabelAnnualGasCost", Float(@label_annual_gas_cost)) unless @label_annual_gas_cost.nil?
      XMLHelper.add_element(clothes_washer, "Capacity", Float(@capacity)) unless @capacity.nil?
    end

    def from_hpxml(hpxml)
      return if hpxml.nil?

      clothes_washer = hpxml.elements["Building/BuildingDetails/Appliances/ClothesWasher"]
      return if clothes_washer.nil?

      @id = _get_id(clothes_washer)
      @location = XMLHelper.get_value(clothes_washer, "Location")
      @modified_energy_factor = _to_float_or_nil(XMLHelper.get_value(clothes_washer, "ModifiedEnergyFactor"))
      @integrated_modified_energy_factor = _to_float_or_nil(XMLHelper.get_value(clothes_washer, "IntegratedModifiedEnergyFactor"))
      @rated_annual_kwh = _to_float_or_nil(XMLHelper.get_value(clothes_washer, "RatedAnnualkWh"))
      @label_electric_rate = _to_float_or_nil(XMLHelper.get_value(clothes_washer, "LabelElectricRate"))
      @label_gas_rate = _to_float_or_nil(XMLHelper.get_value(clothes_washer, "LabelGasRate"))
      @label_annual_gas_cost = _to_float_or_nil(XMLHelper.get_value(clothes_washer, "LabelAnnualGasCost"))
      @capacity = _to_float_or_nil(XMLHelper.get_value(clothes_washer, "Capacity"))
    end
  end

  class ClothesDryer < BaseElement
    ATTRS = [:id, :location, :fuel_type, :energy_factor, :combined_energy_factor, :control_type]
    attr_accessor(*ATTRS)

    def to_rexml(doc)
      return if self.nil?

      appliances = XMLHelper.create_elements_as_needed(doc, ["HPXML", "Building", "BuildingDetails", "Appliances"])
      clothes_dryer = XMLHelper.add_element(appliances, "ClothesDryer")
      sys_id = XMLHelper.add_element(clothes_dryer, "SystemIdentifier")
      XMLHelper.add_attribute(sys_id, "id", @id)
      XMLHelper.add_element(clothes_dryer, "Location", @location) unless @location.nil?
      XMLHelper.add_element(clothes_dryer, "FuelType", @fuel_type) unless @fuel_type.nil?
      XMLHelper.add_element(clothes_dryer, "EnergyFactor", Float(@energy_factor)) unless @energy_factor.nil?
      XMLHelper.add_element(clothes_dryer, "CombinedEnergyFactor", Float(@combined_energy_factor)) unless @combined_energy_factor.nil?
      XMLHelper.add_element(clothes_dryer, "ControlType", @control_type) unless @control_type.nil?
    end

    def from_hpxml(hpxml)
      return if hpxml.nil?

      clothes_dryer = hpxml.elements["Building/BuildingDetails/Appliances/ClothesDryer"]
      return if clothes_dryer.nil?

      @id = _get_id(clothes_dryer)
      @location = XMLHelper.get_value(clothes_dryer, "Location")
      @fuel_type = XMLHelper.get_value(clothes_dryer, "FuelType")
      @energy_factor = _to_float_or_nil(XMLHelper.get_value(clothes_dryer, "EnergyFactor"))
      @combined_energy_factor = _to_float_or_nil(XMLHelper.get_value(clothes_dryer, "CombinedEnergyFactor"))
      @control_type = XMLHelper.get_value(clothes_dryer, "ControlType")
    end
  end

  class Dishwasher < BaseElement
    ATTRS = [:id, :energy_factor, :rated_annual_kwh, :place_setting_capacity]
    attr_accessor(*ATTRS)

    def to_rexml(doc)
      return if self.nil?

      appliances = XMLHelper.create_elements_as_needed(doc, ["HPXML", "Building", "BuildingDetails", "Appliances"])
      dishwasher = XMLHelper.add_element(appliances, "Dishwasher")
      sys_id = XMLHelper.add_element(dishwasher, "SystemIdentifier")
      XMLHelper.add_attribute(sys_id, "id", @id)
      XMLHelper.add_element(dishwasher, "EnergyFactor", Float(@energy_factor)) unless @energy_factor.nil?
      XMLHelper.add_element(dishwasher, "RatedAnnualkWh", Float(@rated_annual_kwh)) unless @rated_annual_kwh.nil?
      XMLHelper.add_element(dishwasher, "PlaceSettingCapacity", Integer(@place_setting_capacity)) unless @place_setting_capacity.nil?
    end

    def from_hpxml(hpxml)
      return if hpxml.nil?

      dishwasher = hpxml.elements["Building/BuildingDetails/Appliances/Dishwasher"]
      return if dishwasher.nil?

      @id = _get_id(dishwasher)
      @energy_factor = _to_float_or_nil(XMLHelper.get_value(dishwasher, "EnergyFactor"))
      @rated_annual_kwh = _to_float_or_nil(XMLHelper.get_value(dishwasher, "RatedAnnualkWh"))
      @place_setting_capacity = _to_integer_or_nil(XMLHelper.get_value(dishwasher, "PlaceSettingCapacity"))
    end
  end

  class Refrigerator < BaseElement
    ATTRS = [:id, :location, :rated_annual_kwh, :adjusted_annual_kwh, :schedules_output_path, :schedules_column_name]
    attr_accessor(*ATTRS)

    def to_rexml(doc)
      return if self.nil?

      appliances = XMLHelper.create_elements_as_needed(doc, ["HPXML", "Building", "BuildingDetails", "Appliances"])
      refrigerator = XMLHelper.add_element(appliances, "Refrigerator")
      sys_id = XMLHelper.add_element(refrigerator, "SystemIdentifier")
      XMLHelper.add_attribute(sys_id, "id", @id)
      XMLHelper.add_element(refrigerator, "Location", @location) unless @location.nil?
      XMLHelper.add_element(refrigerator, "RatedAnnualkWh", Float(@rated_annual_kwh)) unless @rated_annual_kwh.nil?
      _add_extension(parent: refrigerator,
                     extensions: { "AdjustedAnnualkWh" => _to_float_or_nil(@adjusted_annual_kwh),
                                   "SchedulesOutputPath": schedules_output_path,
                                   "SchedulesColumnName": schedules_column_name })
    end

    def from_hpxml(hpxml)
      return if hpxml.nil?

      refrigerator = hpxml.elements["Building/BuildingDetails/Appliances/Refrigerator"]
      return if refrigerator.nil?

      @id = _get_id(refrigerator)
      @location = XMLHelper.get_value(refrigerator, "Location")
      @rated_annual_kwh = _to_float_or_nil(XMLHelper.get_value(refrigerator, "RatedAnnualkWh"))
      @adjusted_annual_kwh = _to_float_or_nil(XMLHelper.get_value(refrigerator, "extension/AdjustedAnnualkWh"))
      @schedules_output_path = XMLHelper.get_value(refrigerator, "extension/SchedulesOutputPath")
      @schedules_column_name = XMLHelper.get_value(refrigerator, "extension/SchedulesColumnName")
    end
  end

  class CookingRange < BaseElement
    ATTRS = [:id, :fuel_type, :is_induction]
    attr_accessor(*ATTRS)

    def to_rexml(doc)
      return if self.nil?

      appliances = XMLHelper.create_elements_as_needed(doc, ["HPXML", "Building", "BuildingDetails", "Appliances"])
      cooking_range = XMLHelper.add_element(appliances, "CookingRange")
      sys_id = XMLHelper.add_element(cooking_range, "SystemIdentifier")
      XMLHelper.add_attribute(sys_id, "id", @id)
      XMLHelper.add_element(cooking_range, "FuelType", @fuel_type) unless @fuel_type.nil?
      XMLHelper.add_element(cooking_range, "IsInduction", Boolean(@is_induction)) unless @is_induction.nil?
    end

    def from_hpxml(hpxml)
      return if hpxml.nil?

      cooking_range = hpxml.elements["Building/BuildingDetails/Appliances/CookingRange"]
      return if cooking_range.nil?

      @id = _get_id(cooking_range)
      @fuel_type = XMLHelper.get_value(cooking_range, "FuelType")
      @is_induction = _to_bool_or_nil(XMLHelper.get_value(cooking_range, "IsInduction"))
    end
  end

  class Oven < BaseElement
    ATTRS = [:id, :is_convection]
    attr_accessor(*ATTRS)

    def to_rexml(doc)
      return if self.nil?

      appliances = XMLHelper.create_elements_as_needed(doc, ["HPXML", "Building", "BuildingDetails", "Appliances"])
      oven = XMLHelper.add_element(appliances, "Oven")
      sys_id = XMLHelper.add_element(oven, "SystemIdentifier")
      XMLHelper.add_attribute(sys_id, "id", @id)
      XMLHelper.add_element(oven, "IsConvection", Boolean(@is_convection)) unless @is_convection.nil?
    end

    def from_hpxml(hpxml)
      return if hpxml.nil?

      oven = hpxml.elements["Building/BuildingDetails/Appliances/Oven"]
      return if oven.nil?

      @id = _get_id(oven)
      @is_convection = _to_bool_or_nil(XMLHelper.get_value(oven, "IsConvection"))
    end
  end

  class Lighting < BaseElement
    ATTRS = [:fraction_tier_i_interior, :fraction_tier_i_exterior, :fraction_tier_i_garage,
             :fraction_tier_ii_interior, :fraction_tier_ii_exterior, :fraction_tier_ii_garage]
    attr_accessor(*ATTRS)

    def to_rexml(doc)
      return if self.nil?

      if not @fraction_tier_i_interior.nil?
        lighting = XMLHelper.create_elements_as_needed(doc, ["HPXML", "Building", "BuildingDetails", "Lighting"])
        lighting_group = XMLHelper.add_element(lighting, "LightingGroup")
        sys_id = XMLHelper.add_element(lighting_group, "SystemIdentifier")
        XMLHelper.add_attribute(sys_id, "id", "Lighting_TierI_Interior")
        XMLHelper.add_element(lighting_group, "Location", "interior")
        XMLHelper.add_element(lighting_group, "FractionofUnitsInLocation", Float(@fraction_tier_i_interior))
        XMLHelper.add_element(lighting_group, "ThirdPartyCertification", "ERI Tier I")
      end

      if not @fraction_tier_i_exterior.nil?
        lighting = XMLHelper.create_elements_as_needed(doc, ["HPXML", "Building", "BuildingDetails", "Lighting"])
        lighting_group = XMLHelper.add_element(lighting, "LightingGroup")
        sys_id = XMLHelper.add_element(lighting_group, "SystemIdentifier")
        XMLHelper.add_attribute(sys_id, "id", "Lighting_TierI_Exterior")
        XMLHelper.add_element(lighting_group, "Location", "exterior")
        XMLHelper.add_element(lighting_group, "FractionofUnitsInLocation", Float(@fraction_tier_i_exterior))
        XMLHelper.add_element(lighting_group, "ThirdPartyCertification", "ERI Tier I")
      end

      if not @fraction_tier_i_garage.nil?
        lighting = XMLHelper.create_elements_as_needed(doc, ["HPXML", "Building", "BuildingDetails", "Lighting"])
        lighting_group = XMLHelper.add_element(lighting, "LightingGroup")
        sys_id = XMLHelper.add_element(lighting_group, "SystemIdentifier")
        XMLHelper.add_attribute(sys_id, "id", "Lighting_TierI_Garage")
        XMLHelper.add_element(lighting_group, "Location", "garage")
        XMLHelper.add_element(lighting_group, "FractionofUnitsInLocation", Float(@fraction_tier_i_garage))
        XMLHelper.add_element(lighting_group, "ThirdPartyCertification", "ERI Tier I")
      end

      if not @fraction_tier_ii_interior.nil?
        lighting = XMLHelper.create_elements_as_needed(doc, ["HPXML", "Building", "BuildingDetails", "Lighting"])
        lighting_group = XMLHelper.add_element(lighting, "LightingGroup")
        sys_id = XMLHelper.add_element(lighting_group, "SystemIdentifier")
        XMLHelper.add_attribute(sys_id, "id", "Lighting_TierII_Interior")
        XMLHelper.add_element(lighting_group, "Location", "interior")
        XMLHelper.add_element(lighting_group, "FractionofUnitsInLocation", Float(@fraction_tier_ii_interior))
        XMLHelper.add_element(lighting_group, "ThirdPartyCertification", "ERI Tier II")
      end

      if not @fraction_tier_ii_exterior.nil?
        lighting = XMLHelper.create_elements_as_needed(doc, ["HPXML", "Building", "BuildingDetails", "Lighting"])
        lighting_group = XMLHelper.add_element(lighting, "LightingGroup")
        sys_id = XMLHelper.add_element(lighting_group, "SystemIdentifier")
        XMLHelper.add_attribute(sys_id, "id", "Lighting_TierII_Exterior")
        XMLHelper.add_element(lighting_group, "Location", "exterior")
        XMLHelper.add_element(lighting_group, "FractionofUnitsInLocation", Float(@fraction_tier_ii_exterior))
        XMLHelper.add_element(lighting_group, "ThirdPartyCertification", "ERI Tier II")
      end

      if not @fraction_tier_ii_garage.nil?
        lighting = XMLHelper.create_elements_as_needed(doc, ["HPXML", "Building", "BuildingDetails", "Lighting"])
        lighting_group = XMLHelper.add_element(lighting, "LightingGroup")
        sys_id = XMLHelper.add_element(lighting_group, "SystemIdentifier")
        XMLHelper.add_attribute(sys_id, "id", "Lighting_TierII_Garage")
        XMLHelper.add_element(lighting_group, "Location", "garage")
        XMLHelper.add_element(lighting_group, "FractionofUnitsInLocation", Float(@fraction_tier_ii_garage))
        XMLHelper.add_element(lighting_group, "ThirdPartyCertification", "ERI Tier II")
      end
    end

    def from_hpxml(hpxml)
      return if hpxml.nil?

      lighting = hpxml.elements["Building/BuildingDetails/Lighting"]
      return if lighting.nil?

      @fraction_tier_i_interior = _to_float_or_nil(XMLHelper.get_value(lighting, "LightingGroup[ThirdPartyCertification='ERI Tier I' and Location='interior']/FractionofUnitsInLocation"))
      @fraction_tier_i_exterior = _to_float_or_nil(XMLHelper.get_value(lighting, "LightingGroup[ThirdPartyCertification='ERI Tier I' and Location='exterior']/FractionofUnitsInLocation"))
      @fraction_tier_i_garage = _to_float_or_nil(XMLHelper.get_value(lighting, "LightingGroup[ThirdPartyCertification='ERI Tier I' and Location='garage']/FractionofUnitsInLocation"))
      @fraction_tier_ii_interior = _to_float_or_nil(XMLHelper.get_value(lighting, "LightingGroup[ThirdPartyCertification='ERI Tier II' and Location='interior']/FractionofUnitsInLocation"))
      @fraction_tier_ii_exterior = _to_float_or_nil(XMLHelper.get_value(lighting, "LightingGroup[ThirdPartyCertification='ERI Tier II' and Location='exterior']/FractionofUnitsInLocation"))
      @fraction_tier_ii_garage = _to_float_or_nil(XMLHelper.get_value(lighting, "LightingGroup[ThirdPartyCertification='ERI Tier II' and Location='garage']/FractionofUnitsInLocation"))
    end
  end

  class CeilingFans < BaseArrayElement
    def add(**kwargs)
      self << CeilingFan.new(**kwargs)
    end

    def from_hpxml(hpxml)
      return if hpxml.nil?

      hpxml.elements.each("Building/BuildingDetails/Lighting/CeilingFan") do |ceiling_fan|
        self << CeilingFan.new(ceiling_fan)
      end
    end
  end

  class CeilingFan < BaseElement
    ATTRS = [:id, :efficiency, :quantity]
    attr_accessor(*ATTRS)

    def to_rexml(doc)
      return if self.nil?

      lighting = XMLHelper.create_elements_as_needed(doc, ["HPXML", "Building", "BuildingDetails", "Lighting"])
      ceiling_fan = XMLHelper.add_element(lighting, "CeilingFan")
      sys_id = XMLHelper.add_element(ceiling_fan, "SystemIdentifier")
      XMLHelper.add_attribute(sys_id, "id", @id)
      if not @efficiency.nil?
        airflow = XMLHelper.add_element(ceiling_fan, "Airflow")
        XMLHelper.add_element(airflow, "FanSpeed", "medium")
        XMLHelper.add_element(airflow, "Efficiency", Float(@efficiency))
      end
      XMLHelper.add_element(ceiling_fan, "Quantity", Integer(@quantity)) unless @quantity.nil?
    end

    def from_hpxml(ceiling_fan)
      @id = _get_id(ceiling_fan)
      @efficiency = _to_float_or_nil(XMLHelper.get_value(ceiling_fan, "Airflow[FanSpeed='medium']/Efficiency"))
      @quantity = _to_integer_or_nil(XMLHelper.get_value(ceiling_fan, "Quantity"))
    end
  end

  class PlugLoads < BaseArrayElement
    def add(**kwargs)
      self << PlugLoad.new(**kwargs)
    end

    def from_hpxml(hpxml)
      return if hpxml.nil?

      hpxml.elements.each("Building/BuildingDetails/MiscLoads/PlugLoad") do |plug_load|
        self << PlugLoad.new(plug_load)
      end
    end
  end

  class PlugLoad < BaseElement
    ATTRS = [:id, :plug_load_type, :kWh_per_year, :frac_sensible, :frac_latent]
    attr_accessor(*ATTRS)

    def to_rexml(doc)
      return if self.nil?

      misc_loads = XMLHelper.create_elements_as_needed(doc, ["HPXML", "Building", "BuildingDetails", "MiscLoads"])
      plug_load = XMLHelper.add_element(misc_loads, "PlugLoad")
      sys_id = XMLHelper.add_element(plug_load, "SystemIdentifier")
      XMLHelper.add_attribute(sys_id, "id", @id)
      XMLHelper.add_element(plug_load, "PlugLoadType", @plug_load_type) unless @plug_load_type.nil?
      if not @kWh_per_year.nil?
        load = XMLHelper.add_element(plug_load, "Load")
        XMLHelper.add_element(load, "Units", "kWh/year")
        XMLHelper.add_element(load, "Value", Float(@kWh_per_year))
      end
      _add_extension(parent: plug_load,
                     extensions: { "FracSensible" => _to_float_or_nil(@frac_sensible),
                                   "FracLatent" => _to_float_or_nil(@frac_latent) })
    end

    def from_hpxml(plug_load)
      @id = _get_id(plug_load)
      @plug_load_type = XMLHelper.get_value(plug_load, "PlugLoadType")
      @kWh_per_year = _to_float_or_nil(XMLHelper.get_value(plug_load, "Load[Units='kWh/year']/Value"))
      @frac_sensible = _to_float_or_nil(XMLHelper.get_value(plug_load, "extension/FracSensible"))
      @frac_latent = _to_float_or_nil(XMLHelper.get_value(plug_load, "extension/FracLatent"))
    end
  end

  class MiscLoadsSchedule < BaseElement
    ATTRS = [:weekday_fractions, :weekend_fractions, :monthly_multipliers]
    attr_accessor(*ATTRS)

    def to_rexml(doc)
      return if self.nil?

      misc_loads = XMLHelper.create_elements_as_needed(doc, ["HPXML", "Building", "BuildingDetails", "MiscLoads"])
      _add_extension(parent: misc_loads,
                     extensions: { "WeekdayScheduleFractions" => @weekday_fractions,
                                   "WeekendScheduleFractions" => @weekend_fractions,
                                   "MonthlyScheduleMultipliers" => @monthly_multipliers })
    end

    def from_hpxml(hpxml)
      return if hpxml.nil?

      misc_loads = hpxml.elements["Building/BuildingDetails/MiscLoads"]
      return if misc_loads.nil?

      @weekday_fractions = XMLHelper.get_value(misc_loads, "extension/WeekdayScheduleFractions")
      @weekend_fractions = XMLHelper.get_value(misc_loads, "extension/WeekendScheduleFractions")
      @monthly_multipliers = XMLHelper.get_value(misc_loads, "extension/MonthlyScheduleMultipliers")
    end
  end

  def _create_rexml_document()
    doc = XMLHelper.create_doc(version = "1.0", encoding = "UTF-8")
    hpxml = XMLHelper.add_element(doc, "HPXML")
    XMLHelper.add_attribute(hpxml, "xmlns", "http://hpxmlonline.com/2019/10")
    XMLHelper.add_attribute(hpxml, "xmlns:xsi", "http://www.w3.org/2001/XMLSchema-instance")
    XMLHelper.add_attribute(hpxml, "xsi:schemaLocation", "http://hpxmlonline.com/2019/10")
    XMLHelper.add_attribute(hpxml, "schemaVersion", "3.0")
    return doc
  end

  def _collapse_enclosure_surfaces()
    # Collapses like surfaces into a single surface with, e.g., aggregate surface area.
    # This can significantly speed up performance for HPXML files with lots of individual
    # surfaces (e.g., windows).

    surf_types = { :roofs => @roofs,
                   :walls => @walls,
                   :rim_joists => @rim_joists,
                   :foundation_walls => @foundation_walls,
                   :frame_floors => @frame_floors,
                   :slabs => @slabs,
                   :windows => @windows,
                   :skylights => @skylights,
                   :doors => @doors }

    attrs_to_ignore = [:id,
                       :insulation_id,
                       :perimeter_insulation_id,
                       :under_slab_insulation_id,
                       :area,
                       :exposed_perimeter]

    # Look for pairs of surfaces that can be collapsed
    surf_types.each do |surf_type, surfaces|
      for i in 0..surfaces.size - 1
        surf = surfaces[i]
        next if surf.nil?

        for j in (surfaces.size - 1).downto(i + 1)
          surf2 = surfaces[j]
          next if surf2.nil?

          match = true
          surf.class::ATTRS.each do |attribute|
            next if attrs_to_ignore.include? attribute
            next if surf_type == :foundation_walls and attribute == :azimuth # Azimuth of foundation walls is irrelevant
            next if surf.send(attribute) == surf2.send(attribute)

            match = false
          end
          next unless match

          # Update Area/ExposedPerimeter
          surf.area += surf2.area
          if surf_type == :slabs
            surf.exposed_perimeter += surf2.exposed_perimeter
          end

          # Update subsurface idrefs as appropriate
          if [:walls, :foundation_walls].include? surf_type
            [:windows, :doors].each do |subsurf_type|
              surf_types[subsurf_type].each do |subsurf, idx|
                next unless subsurf.wall_idref == surf2.id

                subsurf.wall_idref = surf.id
              end
            end
          elsif [:roofs].include? surf_type
            [:skylights].each do |subsurf_type|
              surf_types[subsurf_type].each do |subsurf|
                next unless subsurf.roof_idref == surf2.id

                subsurf.roof_idref = surf.id
              end
            end
          end

          # Remove old surface
          surfaces.delete_at(j)
        end
      end
    end
  end

  attr_reader(:header, :site, :neighbor_buildings, :building_occupancy, :building_construction,
              :climate_and_risk_zones, :air_infiltration_measurements, :attics, :foundations,
              :roofs, :rim_joists, :walls, :foundation_walls, :frame_floors, :slabs, :windows,
              :skylights, :doors, :heating_systems, :cooling_systems, :heat_pumps, :hvac_control,
              :hvac_distributions, :ventilation_fans, :water_heating_systems, :hot_water_distribution,
              :water_fixtures, :solar_thermal_system, :pv_systems, :clothes_washer, :clothes_dryer,
              :dishwasher, :refrigerator, :cooking_range, :oven, :lighting, :ceiling_fans,
              :plug_loads, :misc_loads_schedule, :doc)
end

# Helper methods

def _add_extension(parent:,
                   extensions: {})
  extension = nil
  if not extensions.empty?
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

def _get_id(parent, element_name = "SystemIdentifier")
  return parent.elements[element_name].attributes["id"]
end

def _get_idref(element)
  return if element.nil?

  return element.attributes["idref"]
end

def _to_float_or_nil(value)
  return nil if value.nil?

  return Float(value)
end

def _to_integer_or_nil(value)
  return nil if value.nil?

  return Integer(Float(value))
end

def _to_bool_or_nil(value)
  return nil if value.nil?

  return Boolean(value)
end

# TODO: Move into appropriate class above
def is_thermal_boundary(surface)
  def is_adjacent_to_conditioned(adjacent_to)
    if ["living space", "basement - conditioned"].include? adjacent_to
      return true
    end

    return false
  end

  if surface.exterior_adjacent_to.start_with? "other housing unit"
    return false # adiabatic
  end

  interior_conditioned = is_adjacent_to_conditioned(surface.interior_adjacent_to)
  exterior_conditioned = is_adjacent_to_conditioned(surface.exterior_adjacent_to)
  return (interior_conditioned != exterior_conditioned)
end
