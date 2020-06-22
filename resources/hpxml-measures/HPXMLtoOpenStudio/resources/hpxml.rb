# frozen_string_literal: true

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
  wall.windows.each do |window|
    puts window.area
  end
end

---------------------
Creating from scratch
---------------------

hpxml = HPXML.new()

# Singleton elements
hpxml.building_construction.number_of_bedrooms = 3
hpxml.building_construction.conditioned_floor_area = 2400

# Array elements
hpxml.walls.clear
hpxml.walls.add(id: "WallNorth", area: 500)
hpxml.walls.add(id: "WallSouth", area: 500)
hpxml.walls.add
hpxml.walls[-1].id = "WallEastWest"
hpxml.walls[-1].area = 1000

# Write file
XMLHelper.write_file(hpxml.to_oga, "out.xml")

'''

class HPXML < Object
  HPXML_ATTRS = [:header, :site, :neighbor_buildings, :building_occupancy, :building_construction,
                 :climate_and_risk_zones, :air_infiltration_measurements, :attics, :foundations,
                 :roofs, :rim_joists, :walls, :foundation_walls, :frame_floors, :slabs, :windows,
                 :skylights, :doors, :heating_systems, :cooling_systems, :heat_pumps, :hvac_controls,
                 :hvac_distributions, :ventilation_fans, :water_heating_systems, :hot_water_distributions,
                 :water_fixtures, :water_heating, :solar_thermal_systems, :pv_systems, :clothes_washers,
                 :clothes_dryers, :dishwashers, :refrigerators, :freezers, :dehumidifiers, :cooking_ranges, :ovens,
                 :lighting_groups, :lighting, :ceiling_fans, :pools, :hot_tubs, :plug_loads, :fuel_loads]
  attr_reader(*HPXML_ATTRS, :doc)

  # Constants
  AtticTypeCathedral = 'CathedralCeiling'
  AtticTypeConditioned = 'ConditionedAttic'
  AtticTypeFlatRoof = 'FlatRoof'
  AtticTypeUnvented = 'UnventedAttic'
  AtticTypeVented = 'VentedAttic'
  ClothesDryerControlTypeMoisture = 'moisture'
  ClothesDryerControlTypeTimer = 'timer'
  ColorDark = 'dark'
  ColorLight = 'light'
  ColorMedium = 'medium'
  ColorMediumDark = 'medium dark'
  ColorReflective = 'reflective'
  DHWRecirControlTypeManual = 'manual demand control'
  DHWRecirControlTypeNone = 'no control'
  DHWRecirControlTypeSensor = 'presence sensor demand control'
  DHWRecirControlTypeTemperature = 'temperature'
  DHWRecirControlTypeTimer = 'timer'
  DHWDistTypeRecirc = 'Recirculation'
  DHWDistTypeStandard = 'Standard'
  DuctInsulationMaterialUnknown = 'Unknown'
  DuctInsulationMaterialNone = 'None'
  DuctLeakageTotal = 'total'
  DuctLeakageToOutside = 'to outside'
  DuctTypeReturn = 'return'
  DuctTypeSupply = 'supply'
  DWHRFacilitiesConnectedAll = 'all'
  DWHRFacilitiesConnectedOne = 'one'
  FoundationThermalBoundaryFloor = 'frame floor'
  FoundationThermalBoundaryWall = 'foundation wall'
  FoundationTypeAmbient = 'Ambient'
  FoundationTypeBasementConditioned = 'ConditionedBasement'
  FoundationTypeBasementUnconditioned = 'UnconditionedBasement'
  FoundationTypeCrawlspaceUnvented = 'UnventedCrawlspace'
  FoundationTypeCrawlspaceVented = 'VentedCrawlspace'
  FoundationTypeSlab = 'SlabOnGrade'
  FrameFloorOtherSpaceAbove = 'above'
  FrameFloorOtherSpaceBelow = 'below'
  FuelLoadTypeGrill = 'grill'
  FuelLoadTypeLighting = 'lighting'
  FuelLoadTypeFireplace = 'fireplace'
  FuelTypeElectricity = 'electricity'
  FuelTypeNaturalGas = 'natural gas'
  FuelTypeOil = 'fuel oil'
  FuelTypePropane = 'propane'
  FuelTypeWood = 'wood'
  FuelTypeWoodPellets = 'wood pellets'
  HVACCompressorTypeSingleStage = 'single stage'
  HVACCompressorTypeTwoStage = 'two stage'
  HVACCompressorTypeVariableSpeed = 'variable speed'
  HVACControlTypeManual = 'manual thermostat'
  HVACControlTypeProgrammable = 'programmable thermostat'
  HVACDistributionTypeAir = 'AirDistribution'
  HVACDistributionTypeDSE = 'DSE'
  HVACDistributionTypeHydronic = 'HydronicDistribution'
  HVACTypeBoiler = 'Boiler'
  HVACTypeCentralAirConditioner = 'central air conditioner'
  HVACTypeElectricResistance = 'ElectricResistance'
  HVACTypeEvaporativeCooler = 'evaporative cooler'
  HVACTypeFireplace = 'Fireplace'
  HVACTypeFloorFurnace = 'FloorFurnace'
  HVACTypeFurnace = 'Furnace'
  HVACTypeHeatPumpAirToAir = 'air-to-air'
  HVACTypeHeatPumpGroundToAir = 'ground-to-air'
  HVACTypeHeatPumpMiniSplit = 'mini-split'
  HVACTypePortableHeater = 'PortableHeater'
  HVACTypeRoomAirConditioner = 'room air conditioner'
  HVACTypeStove = 'Stove'
  HVACTypeWallFurnace = 'WallFurnace'
  LeakinessTight = 'tight'
  LeakinessAverage = 'average'
  LightingTypeCFL = 'CompactFluorescent'
  LightingTypeLED = 'LightEmittingDiode'
  LightingTypeLFL = 'FluorescentTube'
  LocationAtticUnconditioned = 'attic - unconditioned'
  LocationAtticUnvented = 'attic - unvented'
  LocationAtticVented = 'attic - vented'
  LocationBasementConditioned = 'basement - conditioned'
  LocationBasementUnconditioned = 'basement - unconditioned'
  LocationBath = 'bath'
  LocationCrawlspaceUnvented = 'crawlspace - unvented'
  LocationCrawlspaceVented = 'crawlspace - vented'
  LocationExterior = 'exterior'
  LocationExteriorWall = 'exterior wall'
  LocationGarage = 'garage'
  LocationGround = 'ground'
  LocationInterior = 'interior'
  LocationKitchen = 'kitchen'
  LocationLivingSpace = 'living space'
  LocationOther = 'other'
  LocationOtherExterior = 'other exterior'
  LocationOtherHousingUnit = 'other housing unit'
  LocationOtherHeatedSpace = 'other heated space'
  LocationOtherMultifamilyBufferSpace = 'other multifamily buffer space'
  LocationOtherNonFreezingSpace = 'other non-freezing space'
  LocationOutside = 'outside'
  LocationRoof = 'roof'
  LocationRoofDeck = 'roof deck'
  LocationUnderSlab = 'under slab'
  MechVentTypeBalanced = 'balanced'
  MechVentTypeCFIS = 'central fan integrated supply'
  MechVentTypeERV = 'energy recovery ventilator'
  MechVentTypeExhaust = 'exhaust only'
  MechVentTypeHRV = 'heat recovery ventilator'
  MechVentTypeSupply = 'supply only'
  OrientationEast = 'east'
  OrientationNorth = 'north'
  OrientationNortheast = 'northeast'
  OrientationNorthwest = 'northwest'
  OrientationSouth = 'south'
  OrientationSoutheast = 'southeast'
  OrientationSouthwest = 'southwest'
  OrientationWest = 'west'
  PlugLoadTypeElectricVehicleCharging = 'electric vehicle charging'
  PlugLoadTypeOther = 'other'
  PlugLoadTypeTelevision = 'TV other'
  PlugLoadTypeWellPump = 'well pump'
  HeaterTypeElectricResistance = 'electric resistance'
  HeaterTypeGas = 'gas fired'
  HeaterTypeHeatPump = 'heat pump'
  PVModuleTypePremium = 'premium'
  PVModuleTypeStandard = 'standard'
  PVModuleTypeThinFilm = 'thin film'
  PVTrackingTypeFixed = 'fixed'
  PVTrackingType1Axis = '1-axis'
  PVTrackingType1AxisBacktracked = '1-axis backtracked'
  PVTrackingType2Axis = '2-axis'
  ResidentialTypeApartment = 'apartment unit'
  ResidentialTypeManufactured = 'manufactured home'
  ResidentialTypeMF = 'multi-family - uncategorized'
  ResidentialTypeSFA = 'single-family attached'
  ResidentialTypeSFD = 'single-family detached'
  RoofTypeAsphaltShingles = 'asphalt or fiberglass shingles'
  RoofTypeConcrete = 'concrete'
  RoofTypeClayTile = 'slate or tile shingles'
  RoofTypeMetal = 'metal surfacing'
  RoofTypePlasticRubber = 'plastic/rubber/synthetic sheeting'
  RoofTypeWoodShingles = 'wood shingles or shakes'
  SidingTypeAluminum = 'aluminum siding'
  SidingTypeBrick = 'brick veneer'
  SidingTypeFiberCement = 'fiber cement siding'
  SidingTypeStucco = 'stucco'
  SidingTypeVinyl = 'vinyl siding'
  SidingTypeWood = 'wood siding'
  SiteTypeUrban = 'urban'
  SiteTypeSuburban = 'suburban'
  SiteTypeRural = 'rural'
  SolarThermalLoopTypeDirect = 'liquid direct'
  SolarThermalLoopTypeIndirect = 'liquid indirect'
  SolarThermalLoopTypeThermosyphon = 'passive thermosyphon'
  SolarThermalTypeDoubleGlazing = 'double glazing black'
  SolarThermalTypeEvacuatedTube = 'evacuated tube'
  SolarThermalTypeICS = 'integrated collector storage'
  SolarThermalTypeSingleGlazing = 'single glazing black'
  UnitsACH = 'ACH'
  UnitsACHNatural = 'ACHnatural'
  UnitsCFM = 'CFM'
  UnitsCFM25 = 'CFM25'
  UnitsKwhPerYear = 'kWh/year'
  UnitsPercent = 'Percent'
  UnitsThermPerYear = 'therm/year'
  WallTypeBrick = 'StructuralBrick'
  WallTypeCMU = 'ConcreteMasonryUnit'
  WallTypeConcrete = 'SolidConcrete'
  WallTypeDoubleWoodStud = 'DoubleWoodStud'
  WallTypeICF = 'InsulatedConcreteForms'
  WallTypeLog = 'LogWall'
  WallTypeSIP = 'StructurallyInsulatedPanel'
  WallTypeSteelStud = 'SteelFrame'
  WallTypeStone = 'Stone'
  WallTypeStrawBale = 'StrawBale'
  WallTypeWoodStud = 'WoodStud'
  WaterFixtureTypeFaucet = 'faucet'
  WaterFixtureTypeShowerhead = 'shower head'
  WaterHeaterTypeCombiStorage = 'space-heating boiler with storage tank'
  WaterHeaterTypeCombiTankless = 'space-heating boiler with tankless coil'
  WaterHeaterTypeHeatPump = 'heat pump water heater'
  WaterHeaterTypeTankless = 'instantaneous water heater'
  WaterHeaterTypeStorage = 'storage water heater'
  WindowFrameTypeAluminum = 'Aluminum'
  WindowFrameTypeWood = 'Wood'
  WindowGasAir = 'air'
  WindowGasArgon = 'argon'
  WindowGlazingLowE = 'low-e'
  WindowGlazingReflective = 'reflective'
  WindowGlazingTintedReflective = 'tinted/reflective'
  WindowLayersDoublePane = 'double-pane'
  WindowLayersSinglePane = 'single-pane'
  WindowLayersTriplePane = 'triple-pane'

  def initialize(hpxml_path: nil, collapse_enclosure: true)
    @doc = nil
    @hpxml_path = hpxml_path

    # Create/populate child objects
    hpxml = nil
    if not hpxml_path.nil?
      @doc = XMLHelper.parse_file(hpxml_path)
      hpxml = XMLHelper.get_element(@doc, '/HPXML')
    end
    from_oga(hpxml)

    # Clean up
    delete_partition_surfaces()
    delete_tiny_surfaces()
    delete_adiabatic_subsurfaces()
    if collapse_enclosure
      collapse_enclosure_surfaces()
    end
  end

  def has_space_type(space_type)
    # Look for surfaces attached to this space type
    (@roofs + @rim_joists + @walls + @foundation_walls + @frame_floors + @slabs).each do |surface|
      return true if surface.interior_adjacent_to == space_type
      return true if surface.exterior_adjacent_to == space_type
    end
    return false
  end

  def has_fuel_access
    @site.fuels.each do |fuel|
      if fuel != FuelTypeElectricity
        return true
      end
    end
    return false
  end

  def predominant_heating_fuel
    fuel_fracs = {}
    @heating_systems.each do |heating_system|
      fuel = heating_system.heating_system_fuel
      fuel_fracs[fuel] = 0.0 if fuel_fracs[fuel].nil?
      fuel_fracs[fuel] += heating_system.fraction_heat_load_served
    end
    @heat_pumps.each do |heat_pump|
      fuel = heat_pump.heat_pump_fuel
      fuel_fracs[fuel] = 0.0 if fuel_fracs[fuel].nil?
      fuel_fracs[fuel] += heat_pump.fraction_heat_load_served
    end
    return FuelTypeElectricity if fuel_fracs.empty?

    return fuel_fracs.key(fuel_fracs.values.max)
  end

  def fraction_of_windows_operable()
    # Calculates the fraction of windows that are operable.
    # Since we don't have quantity available, we use area as an approximation.
    window_area_total = @windows.map { |w| w.area }.inject(0, :+)
    window_area_operable = @windows.map { |w| w.fraction_operable * w.area }.inject(0, :+)
    if window_area_total <= 0
      return 0.0
    end

    return window_area_operable / window_area_total
  end

  def has_walkout_basement()
    has_conditioned_basement = has_space_type(LocationBasementConditioned)
    ncfl = @building_construction.number_of_conditioned_floors
    ncfl_ag = @building_construction.number_of_conditioned_floors_above_grade
    return (has_conditioned_basement && (ncfl == ncfl_ag))
  end

  def thermal_boundary_wall_areas()
    above_grade_area = 0.0 # Thermal boundary walls not in contact with soil
    below_grade_area = 0.0 # Thermal boundary walls in contact with soil

    (@walls + @rim_joists).each do |wall|
      if wall.is_thermal_boundary
        above_grade_area += wall.area
      end
    end

    @foundation_walls.each do |foundation_wall|
      next unless foundation_wall.is_thermal_boundary

      height = foundation_wall.height
      bg_depth = foundation_wall.depth_below_grade
      above_grade_area += (height - bg_depth) / height * foundation_wall.area
      below_grade_area += bg_depth / height * foundation_wall.area
    end

    return above_grade_area, below_grade_area
  end

  def common_wall_area()
    # Wall area for walls adjacent to Unrated Conditioned Space, not including
    # foundation walls.
    area = 0.0

    (@walls + @rim_joists).each do |wall|
      if wall.exterior_adjacent_to == HPXML::LocationOtherHousingUnit
        area += wall.area
      end
    end

    return area
  end

  def compartmentalization_boundary_areas()
    # Returns the infiltration compartmentalization boundary areas
    total_area = 0.0 # Total surface area that bounds the Infiltration Volume
    exterior_area = 0.0 # Same as above excluding surfaces attached to garage or other housing units

    # Determine which spaces are within infiltration volume
    spaces_within_infil_volume = [LocationLivingSpace, LocationBasementConditioned]
    @attics.each do |attic|
      next unless [AtticTypeUnvented].include? attic.attic_type
      next unless attic.within_infiltration_volume

      spaces_within_infil_volume << attic.to_location
    end
    @foundations.each do |foundation|
      next unless [FoundationTypeBasementUnconditioned, FoundationTypeCrawlspaceUnvented].include? foundation.foundation_type
      next unless foundation.within_infiltration_volume

      spaces_within_infil_volume << foundation.to_location
    end

    # Get surfaces bounding infiltration volume
    spaces_within_infil_volume.each do |space_type|
      (@roofs + @rim_joists + @walls + @foundation_walls + @frame_floors + @slabs).each do |surface|
        next unless [surface.interior_adjacent_to, surface.exterior_adjacent_to].include? space_type

        # Exclude surfaces between two spaces that are both within infiltration volume
        next if spaces_within_infil_volume.include?(surface.interior_adjacent_to) && spaces_within_infil_volume.include?(surface.exterior_adjacent_to)

        # Update Compartmentalization Boundary areas
        total_area += surface.area
        if not [LocationGarage, LocationOtherHousingUnit, LocationOtherHeatedSpace,
                LocationOtherMultifamilyBufferSpace, LocationOtherNonFreezingSpace].include? surface.exterior_adjacent_to
          exterior_area += surface.area
        end
      end
    end

    return total_area, exterior_area
  end

  def inferred_infiltration_height(infil_volume)
    # Infiltration height: vertical distance between lowest and highest above-grade points within the pressure boundary.
    # Height is inferred from available HPXML properties.
    # The WithinInfiltrationVolume properties are intentionally ignored for now.
    # FUTURE: Move into AirInfiltrationMeasurement class?
    cfa = @building_construction.conditioned_floor_area
    ncfl = @building_construction.number_of_conditioned_floors
    ncfl_ag = @building_construction.number_of_conditioned_floors_above_grade
    if has_walkout_basement()
      infil_height = Float(ncfl_ag) * infil_volume / cfa
    else
      # Calculate maximum above-grade height of conditioned basement walls
      max_cond_bsmt_wall_height_ag = 0.0
      @foundation_walls.each do |foundation_wall|
        next unless foundation_wall.is_exterior && (foundation_wall.interior_adjacent_to == LocationBasementConditioned)

        height_ag = foundation_wall.height - foundation_wall.depth_below_grade
        next unless height_ag > max_cond_bsmt_wall_height_ag

        max_cond_bsmt_wall_height_ag = height_ag
      end
      # Add assumed rim joist height
      cond_bsmt_rim_joist_height = 0
      @rim_joists.each do |rim_joist|
        next unless rim_joist.is_exterior && (rim_joist.interior_adjacent_to == LocationBasementConditioned)

        cond_bsmt_rim_joist_height = UnitConversions.convert(9, 'in', 'ft')
      end
      infil_height = Float(ncfl_ag) * infil_volume / cfa + max_cond_bsmt_wall_height_ag + cond_bsmt_rim_joist_height
    end
    return infil_height
  end

  def to_oga()
    @doc = _create_oga_document()
    @header.to_oga(@doc)
    @site.to_oga(@doc)
    @neighbor_buildings.to_oga(@doc)
    @building_occupancy.to_oga(@doc)
    @building_construction.to_oga(@doc)
    @climate_and_risk_zones.to_oga(@doc)
    @air_infiltration_measurements.to_oga(@doc)
    @attics.to_oga(@doc)
    @foundations.to_oga(@doc)
    @roofs.to_oga(@doc)
    @rim_joists.to_oga(@doc)
    @walls.to_oga(@doc)
    @foundation_walls.to_oga(@doc)
    @frame_floors.to_oga(@doc)
    @slabs.to_oga(@doc)
    @windows.to_oga(@doc)
    @skylights.to_oga(@doc)
    @doors.to_oga(@doc)
    @heating_systems.to_oga(@doc)
    @cooling_systems.to_oga(@doc)
    @heat_pumps.to_oga(@doc)
    @hvac_controls.to_oga(@doc)
    @hvac_distributions.to_oga(@doc)
    @ventilation_fans.to_oga(@doc)
    @water_heating_systems.to_oga(@doc)
    @hot_water_distributions.to_oga(@doc)
    @water_fixtures.to_oga(@doc)
    @water_heating.to_oga(@doc)
    @solar_thermal_systems.to_oga(@doc)
    @pv_systems.to_oga(@doc)
    @clothes_washers.to_oga(@doc)
    @clothes_dryers.to_oga(@doc)
    @dishwashers.to_oga(@doc)
    @refrigerators.to_oga(@doc)
    @freezers.to_oga(@doc)
    @dehumidifiers.to_oga(@doc)
    @cooking_ranges.to_oga(@doc)
    @ovens.to_oga(@doc)
    @lighting_groups.to_oga(@doc)
    @lighting.to_oga(@doc)
    @ceiling_fans.to_oga(@doc)
    @pools.to_oga(@doc)
    @hot_tubs.to_oga(@doc)
    @plug_loads.to_oga(@doc)
    @fuel_loads.to_oga(@doc)
    return @doc
  end

  def from_oga(hpxml)
    @header = Header.new(self, hpxml)
    @site = Site.new(self, hpxml)
    @neighbor_buildings = NeighborBuildings.new(self, hpxml)
    @building_occupancy = BuildingOccupancy.new(self, hpxml)
    @building_construction = BuildingConstruction.new(self, hpxml)
    @climate_and_risk_zones = ClimateandRiskZones.new(self, hpxml)
    @air_infiltration_measurements = AirInfiltrationMeasurements.new(self, hpxml)
    @attics = Attics.new(self, hpxml)
    @foundations = Foundations.new(self, hpxml)
    @roofs = Roofs.new(self, hpxml)
    @rim_joists = RimJoists.new(self, hpxml)
    @walls = Walls.new(self, hpxml)
    @foundation_walls = FoundationWalls.new(self, hpxml)
    @frame_floors = FrameFloors.new(self, hpxml)
    @slabs = Slabs.new(self, hpxml)
    @windows = Windows.new(self, hpxml)
    @skylights = Skylights.new(self, hpxml)
    @doors = Doors.new(self, hpxml)
    @heating_systems = HeatingSystems.new(self, hpxml)
    @cooling_systems = CoolingSystems.new(self, hpxml)
    @heat_pumps = HeatPumps.new(self, hpxml)
    @hvac_controls = HVACControls.new(self, hpxml)
    @hvac_distributions = HVACDistributions.new(self, hpxml)
    @ventilation_fans = VentilationFans.new(self, hpxml)
    @water_heating_systems = WaterHeatingSystems.new(self, hpxml)
    @hot_water_distributions = HotWaterDistributions.new(self, hpxml)
    @water_fixtures = WaterFixtures.new(self, hpxml)
    @water_heating = WaterHeating.new(self, hpxml)
    @solar_thermal_systems = SolarThermalSystems.new(self, hpxml)
    @pv_systems = PVSystems.new(self, hpxml)
    @clothes_washers = ClothesWashers.new(self, hpxml)
    @clothes_dryers = ClothesDryers.new(self, hpxml)
    @dishwashers = Dishwashers.new(self, hpxml)
    @refrigerators = Refrigerators.new(self, hpxml)
    @freezers = Freezers.new(self, hpxml)
    @dehumidifiers = Dehumidifiers.new(self, hpxml)
    @cooking_ranges = CookingRanges.new(self, hpxml)
    @ovens = Ovens.new(self, hpxml)
    @lighting_groups = LightingGroups.new(self, hpxml)
    @lighting = Lighting.new(self, hpxml)
    @ceiling_fans = CeilingFans.new(self, hpxml)
    @pools = Pools.new(self, hpxml)
    @hot_tubs = HotTubs.new(self, hpxml)
    @plug_loads = PlugLoads.new(self, hpxml)
    @fuel_loads = FuelLoads.new(self, hpxml)
  end

  # Class to store additional properties on an HPXML object that are not intended
  # to end up in the HPXML file. For example, you can store the OpenStudio::Model::Space
  # object for an appliance.
  class AdditionalProperties < OpenStruct
    def method_missing(meth, *args)
      # Complain if no value has been set rather than just returning nil
      raise NoMethodError, "undefined method '#{meth}' for #{self}" unless meth.to_s.end_with?('=')
      super
    end
  end

  # HPXML Standard Element (e.g., Roof)
  class BaseElement
    attr_accessor(:hpxml_object, :additional_properties)

    def initialize(hpxml_object, oga_element = nil, **kwargs)
      @hpxml_object = hpxml_object
      @additional_properties = AdditionalProperties.new
      if not oga_element.nil?
        # Set values from HPXML Oga element
        from_oga(oga_element)
      else
        # Set values from **kwargs
        kwargs.each do |k, v|
          send(k.to_s + '=', v)
        end
      end
    end

    def to_h
      h = {}
      self.class::ATTRS.each do |attribute|
        h[attribute] = send(attribute)
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

  # HPXML Array Element (e.g., Roofs)
  class BaseArrayElement < Array
    attr_accessor(:hpxml_object, :additional_properties)

    def initialize(hpxml_object, oga_element = nil)
      @hpxml_object = hpxml_object
      @additional_properties = AdditionalProperties.new
      if not oga_element.nil?
        # Set values from HPXML Oga element
        from_oga(oga_element)
      end
    end

    def check_for_errors
      errors = []
      each do |child|
        if not child.respond_to? :check_for_errors
          fail "Need to add 'check_for_errors' method to #{child.class} class."
        end

        errors += child.check_for_errors
      end
      return errors
    end

    def to_oga(doc)
      each do |child|
        child.to_oga(doc)
      end
    end

    def to_s
      return map { |x| x.to_s }
    end
  end

  class Header < BaseElement
    ATTRS = [:xml_type, :xml_generated_by, :created_date_and_time, :transaction,
             :software_program_used, :software_program_version, :eri_calculation_version,
             :eri_design, :timestep, :building_id, :event_type, :state_code,
             :begin_month, :begin_day_of_month, :end_month, :end_day_of_month,
             :apply_ashrae140_assumptions]
    attr_accessor(*ATTRS)

    def check_for_errors
      errors = []

      if not @timestep.nil?
        valid_tsteps = [60, 30, 20, 15, 12, 10, 6, 5, 4, 3, 2, 1]
        if not valid_tsteps.include? @timestep
          fail "Timestep (#{@timestep}) must be one of: #{valid_tsteps.join(', ')}."
        end
      end

      if not @begin_month.nil?
        valid_months = (1..12).to_a
        if not valid_months.include? @begin_month
          fail "Begin Month (#{@begin_month}) must be one of: #{valid_months.join(', ')}."
        end
      end

      if not @end_month.nil?
        valid_months = (1..12).to_a
        if not valid_months.include? @end_month
          fail "End Month (#{@end_month}) must be one of: #{valid_months.join(', ')}."
        end
      end

      months_days = { [1, 3, 5, 7, 8, 10, 12] => (1..31).to_a, [4, 6, 9, 11] => (1..30).to_a, [2] => (1..28).to_a }
      months_days.each do |months, valid_days|
        if (not @begin_day_of_month.nil?) && (months.include? @begin_month)
          if not valid_days.include? @begin_day_of_month
            fail "Begin Day of Month (#{@begin_day_of_month}) must be one of: #{valid_days.join(', ')}."
          end
        end
        next unless (not @end_day_of_month.nil?) && (months.include? @end_month)
        if not valid_days.include? @end_day_of_month
          fail "End Day of Month (#{@end_day_of_month}) must be one of: #{valid_days.join(', ')}."
        end
      end

      if (not @begin_month.nil?) && (not @end_month.nil?)
        if @begin_month > @end_month
          fail "Begin Month (#{@begin_month}) cannot come after End Month (#{@end_month})."
        end

        if (not @begin_day_of_month.nil?) && (not @end_day_of_month.nil?)
          if @begin_month == @end_month
            if @begin_day_of_month > @end_day_of_month
              fail "Begin Day of Month (#{@begin_day_of_month}) cannot come after End Day of Month (#{@end_day_of_month}) for the same month (#{@begin_month})."
            end
          end
        end
      end

      return errors
    end

    def to_oga(doc)
      return if nil?

      hpxml = XMLHelper.get_element(doc, '/HPXML')
      header = XMLHelper.add_element(hpxml, 'XMLTransactionHeaderInformation')
      XMLHelper.add_element(header, 'XMLType', @xml_type)
      XMLHelper.add_element(header, 'XMLGeneratedBy', @xml_generated_by)
      if not @created_date_and_time.nil?
        XMLHelper.add_element(header, 'CreatedDateAndTime', @created_date_and_time)
      else
        XMLHelper.add_element(header, 'CreatedDateAndTime', Time.now.strftime('%Y-%m-%dT%H:%M:%S%:z'))
      end
      XMLHelper.add_element(header, 'Transaction', @transaction)

      software_info = XMLHelper.add_element(hpxml, 'SoftwareInfo')
      XMLHelper.add_element(software_info, 'SoftwareProgramUsed', @software_program_used) unless @software_program_used.nil?
      XMLHelper.add_element(software_info, 'SoftwareProgramVersion', software_program_version) unless software_program_version.nil?
      extension = XMLHelper.add_element(software_info, 'extension')
      XMLHelper.add_element(extension, 'ApplyASHRAE140Assumptions', to_bool_or_nil(@apply_ashrae140_assumptions)) unless @apply_ashrae140_assumptions.nil?
      if (not @eri_calculation_version.nil?) || (not @eri_design.nil?)
        eri_calculation = XMLHelper.add_element(extension, 'ERICalculation')
        XMLHelper.add_element(eri_calculation, 'Version', @eri_calculation_version) unless @eri_calculation_version.nil?
        XMLHelper.add_element(eri_calculation, 'Design', @eri_design) unless @eri_design.nil?
      end
      if (not @timestep.nil?) || (not @begin_month.nil?) || (not @begin_day_of_month.nil?) || (not @end_month.nil?) || (not @end_day_of_month.nil?)
        simulation_control = XMLHelper.add_element(extension, 'SimulationControl')
        XMLHelper.add_element(simulation_control, 'Timestep', to_integer_or_nil(@timestep)) unless @timestep.nil?
        XMLHelper.add_element(simulation_control, 'BeginMonth', to_integer_or_nil(@begin_month)) unless @begin_month.nil?
        XMLHelper.add_element(simulation_control, 'BeginDayOfMonth', to_integer_or_nil(@begin_day_of_month)) unless @begin_day_of_month.nil?
        XMLHelper.add_element(simulation_control, 'EndMonth', to_integer_or_nil(@end_month)) unless @end_month.nil?
        XMLHelper.add_element(simulation_control, 'EndDayOfMonth', to_integer_or_nil(@end_day_of_month)) unless @end_day_of_month.nil?
      end
      if XMLHelper.get_element(extension, 'ERICalculation').nil? && XMLHelper.get_element(extension, 'SimulationControl').nil? && @apply_ashrae140_assumptions.nil?
        extension.remove
      end

      building = XMLHelper.add_element(hpxml, 'Building')
      building_building_id = XMLHelper.add_element(building, 'BuildingID')
      XMLHelper.add_attribute(building_building_id, 'id', @building_id)
      if not @state_code.nil?
        site = XMLHelper.add_element(building, 'Site')
        site_id = XMLHelper.add_element(site, 'SiteID')
        XMLHelper.add_attribute(site_id, 'id', 'SiteID')
        address = XMLHelper.add_element(site, 'Address')
        XMLHelper.add_element(address, 'StateCode', @state_code)
      end
      project_status = XMLHelper.add_element(building, 'ProjectStatus')
      XMLHelper.add_element(project_status, 'EventType', @event_type)
    end

    def from_oga(hpxml)
      return if hpxml.nil?

      @xml_type = XMLHelper.get_value(hpxml, 'XMLTransactionHeaderInformation/XMLType')
      @xml_generated_by = XMLHelper.get_value(hpxml, 'XMLTransactionHeaderInformation/XMLGeneratedBy')
      @created_date_and_time = XMLHelper.get_value(hpxml, 'XMLTransactionHeaderInformation/CreatedDateAndTime')
      @transaction = XMLHelper.get_value(hpxml, 'XMLTransactionHeaderInformation/Transaction')
      @software_program_used = XMLHelper.get_value(hpxml, 'SoftwareInfo/SoftwareProgramUsed')
      @software_program_version = XMLHelper.get_value(hpxml, 'SoftwareInfo/SoftwareProgramVersion')
      @eri_calculation_version = XMLHelper.get_value(hpxml, 'SoftwareInfo/extension/ERICalculation/Version')
      @eri_design = XMLHelper.get_value(hpxml, 'SoftwareInfo/extension/ERICalculation/Design')
      @timestep = to_integer_or_nil(XMLHelper.get_value(hpxml, 'SoftwareInfo/extension/SimulationControl/Timestep'))
      @begin_month = to_integer_or_nil(XMLHelper.get_value(hpxml, 'SoftwareInfo/extension/SimulationControl/BeginMonth'))
      @begin_day_of_month = to_integer_or_nil(XMLHelper.get_value(hpxml, 'SoftwareInfo/extension/SimulationControl/BeginDayOfMonth'))
      @end_month = to_integer_or_nil(XMLHelper.get_value(hpxml, 'SoftwareInfo/extension/SimulationControl/EndMonth'))
      @end_day_of_month = to_integer_or_nil(XMLHelper.get_value(hpxml, 'SoftwareInfo/extension/SimulationControl/EndDayOfMonth'))
      @apply_ashrae140_assumptions = to_bool_or_nil(XMLHelper.get_value(hpxml, 'SoftwareInfo/extension/ApplyASHRAE140Assumptions'))
      @building_id = HPXML::get_id(hpxml, 'Building/BuildingID')
      @event_type = XMLHelper.get_value(hpxml, 'Building/ProjectStatus/EventType')
      @state_code = XMLHelper.get_value(hpxml, 'Building/Site/Address/StateCode')
    end
  end

  class Site < BaseElement
    ATTRS = [:site_type, :surroundings, :orientation_of_front_of_home, :fuels, :shelter_coefficient]
    attr_accessor(*ATTRS)

    def check_for_errors
      errors = []
      return errors
    end

    def to_oga(doc)
      return if nil?

      site = XMLHelper.create_elements_as_needed(doc, ['HPXML', 'Building', 'BuildingDetails', 'BuildingSummary', 'Site'])
      XMLHelper.add_element(site, 'SiteType', @site_type) unless @site_type.nil?
      XMLHelper.add_element(site, 'Surroundings', @surroundings) unless @surroundings.nil?
      XMLHelper.add_element(site, 'OrientationOfFrontOfHome', @orientation_of_front_of_home) unless @orientation_of_front_of_home.nil?
      if (not @fuels.nil?) && (not @fuels.empty?)
        fuel_types_available = XMLHelper.add_element(site, 'FuelTypesAvailable')
        @fuels.each do |fuel|
          XMLHelper.add_element(fuel_types_available, 'Fuel', fuel)
        end
      end
      HPXML::add_extension(parent: site,
                           extensions: { 'ShelterCoefficient' => to_float_or_nil(@shelter_coefficient) })
    end

    def from_oga(hpxml)
      return if hpxml.nil?

      site = XMLHelper.get_element(hpxml, 'Building/BuildingDetails/BuildingSummary/Site')
      return if site.nil?

      @site_type = XMLHelper.get_value(site, 'SiteType')
      @surroundings = XMLHelper.get_value(site, 'Surroundings')
      @orientation_of_front_of_home = XMLHelper.get_value(site, 'OrientationOfFrontOfHome')
      @fuels = XMLHelper.get_values(site, 'FuelTypesAvailable/Fuel')
      @shelter_coefficient = to_float_or_nil(XMLHelper.get_value(site, 'extension/ShelterCoefficient'))
    end
  end

  class NeighborBuildings < BaseArrayElement
    def add(**kwargs)
      self << NeighborBuilding.new(@hpxml_object, **kwargs)
    end

    def from_oga(hpxml)
      return if hpxml.nil?

      XMLHelper.get_elements(hpxml, 'Building/BuildingDetails/BuildingSummary/Site/extension/Neighbors/NeighborBuilding').each do |neighbor_building|
        self << NeighborBuilding.new(@hpxml_object, neighbor_building)
      end
    end
  end

  class NeighborBuilding < BaseElement
    ATTRS = [:azimuth, :distance, :height]
    attr_accessor(*ATTRS)

    def check_for_errors
      errors = []
      return errors
    end

    def to_oga(doc)
      return if nil?

      neighbors = XMLHelper.create_elements_as_needed(doc, ['HPXML', 'Building', 'BuildingDetails', 'BuildingSummary', 'Site', 'extension', 'Neighbors'])
      neighbor_building = XMLHelper.add_element(neighbors, 'NeighborBuilding')
      XMLHelper.add_element(neighbor_building, 'Azimuth', to_integer(@azimuth)) unless @azimuth.nil?
      XMLHelper.add_element(neighbor_building, 'Distance', to_float(@distance)) unless @distance.nil?
      XMLHelper.add_element(neighbor_building, 'Height', to_float(@height)) unless @height.nil?
    end

    def from_oga(neighbor_building)
      return if neighbor_building.nil?

      @azimuth = to_integer_or_nil(XMLHelper.get_value(neighbor_building, 'Azimuth'))
      @distance = to_float_or_nil(XMLHelper.get_value(neighbor_building, 'Distance'))
      @height = to_float_or_nil(XMLHelper.get_value(neighbor_building, 'Height'))
    end
  end

  class BuildingOccupancy < BaseElement
    ATTRS = [:number_of_residents, :schedules_output_path, :schedules_column_name]
    attr_accessor(*ATTRS)

    def check_for_errors
      errors = []
      return errors
    end

    def to_oga(doc)
      return if nil?

      building_occupancy = XMLHelper.create_elements_as_needed(doc, ['HPXML', 'Building', 'BuildingDetails', 'BuildingSummary', 'BuildingOccupancy'])
      XMLHelper.add_element(building_occupancy, 'NumberofResidents', to_float(@number_of_residents)) unless @number_of_residents.nil?
      HPXML::add_extension(parent: building_occupancy,
                           extensions: { 'SchedulesOutputPath' => schedules_output_path,
                                         'SchedulesColumnName' => schedules_column_name })
    end

    def from_oga(hpxml)
      return if hpxml.nil?

      building_occupancy = XMLHelper.get_element(hpxml, 'Building/BuildingDetails/BuildingSummary/BuildingOccupancy')
      return if building_occupancy.nil?

      @number_of_residents = to_float_or_nil(XMLHelper.get_value(building_occupancy, 'NumberofResidents'))
      @schedules_output_path = XMLHelper.get_value(building_occupancy, 'extension/SchedulesOutputPath')
      @schedules_column_name = XMLHelper.get_value(building_occupancy, 'extension/SchedulesColumnName')
    end
  end

  class BuildingConstruction < BaseElement
    ATTRS = [:year_built, :number_of_conditioned_floors, :number_of_conditioned_floors_above_grade,
             :average_ceiling_height, :number_of_bedrooms, :number_of_bathrooms,
             :conditioned_floor_area, :conditioned_building_volume, :use_only_ideal_air_system,
             :residential_facility_type]
    attr_accessor(*ATTRS)

    def check_for_errors
      errors = []
      return errors
    end

    def to_oga(doc)
      return if nil?

      building_construction = XMLHelper.create_elements_as_needed(doc, ['HPXML', 'Building', 'BuildingDetails', 'BuildingSummary', 'BuildingConstruction'])
      XMLHelper.add_element(building_construction, 'ResidentialFacilityType', @residential_facility_type) unless @residential_facility_type.nil?
      XMLHelper.add_element(building_construction, 'NumberofConditionedFloors', to_integer(@number_of_conditioned_floors)) unless @number_of_conditioned_floors.nil?
      XMLHelper.add_element(building_construction, 'NumberofConditionedFloorsAboveGrade', to_integer(@number_of_conditioned_floors_above_grade)) unless @number_of_conditioned_floors_above_grade.nil?
      XMLHelper.add_element(building_construction, 'AverageCeilingHeight', to_float(@average_ceiling_height)) unless @average_ceiling_height.nil?
      XMLHelper.add_element(building_construction, 'NumberofBedrooms', to_integer(@number_of_bedrooms)) unless @number_of_bedrooms.nil?
      XMLHelper.add_element(building_construction, 'NumberofBathrooms', to_integer(@number_of_bathrooms)) unless @number_of_bathrooms.nil?
      XMLHelper.add_element(building_construction, 'ConditionedFloorArea', to_float(@conditioned_floor_area)) unless @conditioned_floor_area.nil?
      XMLHelper.add_element(building_construction, 'ConditionedBuildingVolume', to_float(@conditioned_building_volume)) unless @conditioned_building_volume.nil?
      HPXML::add_extension(parent: building_construction,
                           extensions: { 'UseOnlyIdealAirSystem' => to_bool_or_nil(@use_only_ideal_air_system) })
    end

    def from_oga(hpxml)
      return if hpxml.nil?

      building_construction = XMLHelper.get_element(hpxml, 'Building/BuildingDetails/BuildingSummary/BuildingConstruction')
      return if building_construction.nil?

      @year_built = to_integer_or_nil(XMLHelper.get_value(building_construction, 'YearBuilt'))
      @number_of_conditioned_floors = to_integer_or_nil(XMLHelper.get_value(building_construction, 'NumberofConditionedFloors'))
      @number_of_conditioned_floors_above_grade = to_integer_or_nil(XMLHelper.get_value(building_construction, 'NumberofConditionedFloorsAboveGrade'))
      @average_ceiling_height = to_float_or_nil(XMLHelper.get_value(building_construction, 'AverageCeilingHeight'))
      @number_of_bedrooms = to_integer_or_nil(XMLHelper.get_value(building_construction, 'NumberofBedrooms'))
      @number_of_bathrooms = to_integer_or_nil(XMLHelper.get_value(building_construction, 'NumberofBathrooms'))
      @conditioned_floor_area = to_float_or_nil(XMLHelper.get_value(building_construction, 'ConditionedFloorArea'))
      @conditioned_building_volume = to_float_or_nil(XMLHelper.get_value(building_construction, 'ConditionedBuildingVolume'))
      @use_only_ideal_air_system = to_bool_or_nil(XMLHelper.get_value(building_construction, 'extension/UseOnlyIdealAirSystem'))
      @residential_facility_type = XMLHelper.get_value(building_construction, 'ResidentialFacilityType')
    end
  end

  class ClimateandRiskZones < BaseElement
    ATTRS = [:iecc_year, :iecc_zone, :weather_station_id, :weather_station_name, :weather_station_wmo,
             :weather_station_epw_filepath]
    attr_accessor(*ATTRS)

    def check_for_errors
      errors = []
      return errors
    end

    def to_oga(doc)
      return if nil?

      climate_and_risk_zones = XMLHelper.create_elements_as_needed(doc, ['HPXML', 'Building', 'BuildingDetails', 'ClimateandRiskZones'])

      if (not @iecc_year.nil?) && (not @iecc_zone.nil?)
        climate_zone_iecc = XMLHelper.add_element(climate_and_risk_zones, 'ClimateZoneIECC')
        XMLHelper.add_element(climate_zone_iecc, 'Year', to_integer(@iecc_year)) unless @iecc_year.nil?
        XMLHelper.add_element(climate_zone_iecc, 'ClimateZone', @iecc_zone) unless @iecc_zone.nil?
      end

      if not @weather_station_id.nil?
        weather_station = XMLHelper.add_element(climate_and_risk_zones, 'WeatherStation')
        sys_id = XMLHelper.add_element(weather_station, 'SystemIdentifier')
        XMLHelper.add_attribute(sys_id, 'id', @weather_station_id)
        XMLHelper.add_element(weather_station, 'Name', @weather_station_name) unless @weather_station_name.nil?
        XMLHelper.add_element(weather_station, 'WMO', @weather_station_wmo) unless @weather_station_wmo.nil?
        HPXML::add_extension(parent: weather_station,
                             extensions: { 'EPWFilePath' => @weather_station_epw_filepath })
      end
    end

    def from_oga(hpxml)
      return if hpxml.nil?

      climate_and_risk_zones = XMLHelper.get_element(hpxml, 'Building/BuildingDetails/ClimateandRiskZones')
      return if climate_and_risk_zones.nil?

      @iecc_year = XMLHelper.get_value(climate_and_risk_zones, 'ClimateZoneIECC/Year')
      @iecc_zone = XMLHelper.get_value(climate_and_risk_zones, 'ClimateZoneIECC/ClimateZone')
      weather_station = XMLHelper.get_element(climate_and_risk_zones, 'WeatherStation')
      if not weather_station.nil?
        @weather_station_id = HPXML::get_id(weather_station)
        @weather_station_name = XMLHelper.get_value(weather_station, 'Name')
        @weather_station_wmo = XMLHelper.get_value(weather_station, 'WMO')
        @weather_station_epw_filepath = XMLHelper.get_value(weather_station, 'extension/EPWFilePath')
      end
    end
  end

  class AirInfiltrationMeasurements < BaseArrayElement
    def add(**kwargs)
      self << AirInfiltrationMeasurement.new(@hpxml_object, **kwargs)
    end

    def from_oga(hpxml)
      return if hpxml.nil?

      XMLHelper.get_elements(hpxml, 'Building/BuildingDetails/Enclosure/AirInfiltration/AirInfiltrationMeasurement').each do |air_infiltration_measurement|
        self << AirInfiltrationMeasurement.new(@hpxml_object, air_infiltration_measurement)
      end
    end
  end

  class AirInfiltrationMeasurement < BaseElement
    ATTRS = [:id, :house_pressure, :unit_of_measure, :air_leakage, :effective_leakage_area,
             :infiltration_volume, :leakiness_description]
    attr_accessor(*ATTRS)

    def check_for_errors
      errors = []
      return errors
    end

    def to_oga(doc)
      return if nil?

      air_infiltration = XMLHelper.create_elements_as_needed(doc, ['HPXML', 'Building', 'BuildingDetails', 'Enclosure', 'AirInfiltration'])
      air_infiltration_measurement = XMLHelper.add_element(air_infiltration, 'AirInfiltrationMeasurement')
      sys_id = XMLHelper.add_element(air_infiltration_measurement, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_element(air_infiltration_measurement, 'HousePressure', to_float(@house_pressure)) unless @house_pressure.nil?
      if (not @unit_of_measure.nil?) && (not @air_leakage.nil?)
        building_air_leakage = XMLHelper.add_element(air_infiltration_measurement, 'BuildingAirLeakage')
        XMLHelper.add_element(building_air_leakage, 'UnitofMeasure', @unit_of_measure)
        XMLHelper.add_element(building_air_leakage, 'AirLeakage', to_float(@air_leakage))
      end
      XMLHelper.add_element(air_infiltration_measurement, 'EffectiveLeakageArea', to_float(@effective_leakage_area)) unless @effective_leakage_area.nil?
      XMLHelper.add_element(air_infiltration_measurement, 'InfiltrationVolume', to_float(@infiltration_volume)) unless @infiltration_volume.nil?
    end

    def from_oga(air_infiltration_measurement)
      return if air_infiltration_measurement.nil?

      @id = HPXML::get_id(air_infiltration_measurement)
      @house_pressure = to_float_or_nil(XMLHelper.get_value(air_infiltration_measurement, 'HousePressure'))
      @unit_of_measure = XMLHelper.get_value(air_infiltration_measurement, 'BuildingAirLeakage/UnitofMeasure')
      @air_leakage = to_float_or_nil(XMLHelper.get_value(air_infiltration_measurement, 'BuildingAirLeakage/AirLeakage'))
      @effective_leakage_area = to_float_or_nil(XMLHelper.get_value(air_infiltration_measurement, 'EffectiveLeakageArea'))
      @infiltration_volume = to_float_or_nil(XMLHelper.get_value(air_infiltration_measurement, 'InfiltrationVolume'))
      @leakiness_description = XMLHelper.get_value(air_infiltration_measurement, 'LeakinessDescription')
    end
  end

  class Attics < BaseArrayElement
    def add(**kwargs)
      self << Attic.new(@hpxml_object, **kwargs)
    end

    def from_oga(hpxml)
      return if hpxml.nil?

      XMLHelper.get_elements(hpxml, 'Building/BuildingDetails/Enclosure/Attics/Attic').each do |attic|
        self << Attic.new(@hpxml_object, attic)
      end
    end
  end

  class Attic < BaseElement
    ATTRS = [:id, :attic_type, :vented_attic_sla, :vented_attic_ach, :within_infiltration_volume,
             :attached_to_roof_idrefs, :attached_to_frame_floor_idrefs]
    attr_accessor(*ATTRS)

    def attached_roofs
      return [] if @attached_to_roof_idrefs.nil?

      list = @hpxml_object.roofs.select { |roof| @attached_to_roof_idrefs.include? roof.id }
      if @attached_to_roof_idrefs.size > list.size
        fail "Attached roof not found for attic '#{@id}'."
      end

      return list
    end

    def attached_frame_floors
      return [] if @attached_to_frame_floor_idrefs.nil?

      list = @hpxml_object.frame_floors.select { |frame_floor| @attached_to_frame_floor_idrefs.include? frame_floor.id }
      if @attached_to_frame_floor_idrefs.size > list.size
        fail "Attached frame floor not found for attic '#{@id}'."
      end

      return list
    end

    def to_location
      return if @attic_type.nil?

      if @attic_type == AtticTypeCathedral
        return LocationLivingSpace
      elsif @attic_type == AtticTypeConditioned
        return LocationLivingSpace
      elsif @attic_type == AtticTypeFlatRoof
        return LocationLivingSpace
      elsif @attic_type == AtticTypeUnvented
        return LocationAtticUnvented
      elsif @attic_type == AtticTypeVented
        return LocationAtticVented
      else
        fail "Unexpected attic type: '#{@attic_type}'."
      end
    end

    def check_for_errors
      errors = []
      begin; attached_roofs; rescue StandardError => e; errors << e.message; end
      begin; attached_frame_floors; rescue StandardError => e; errors << e.message; end
      begin; to_location; rescue StandardError => e; errors << e.message; end
      return errors
    end

    def to_oga(doc)
      return if nil?

      attics = XMLHelper.create_elements_as_needed(doc, ['HPXML', 'Building', 'BuildingDetails', 'Enclosure', 'Attics'])
      attic = XMLHelper.add_element(attics, 'Attic')
      sys_id = XMLHelper.add_element(attic, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      if not @attic_type.nil?
        attic_type_e = XMLHelper.add_element(attic, 'AtticType')
        if @attic_type == AtticTypeUnvented
          attic_type_attic = XMLHelper.add_element(attic_type_e, 'Attic')
          XMLHelper.add_element(attic_type_attic, 'Vented', false)
        elsif @attic_type == AtticTypeVented
          attic_type_attic = XMLHelper.add_element(attic_type_e, 'Attic')
          XMLHelper.add_element(attic_type_attic, 'Vented', true)
          if not @vented_attic_sla.nil?
            ventilation_rate = XMLHelper.add_element(attic, 'VentilationRate')
            XMLHelper.add_element(ventilation_rate, 'UnitofMeasure', 'SLA')
            XMLHelper.add_element(ventilation_rate, 'Value', to_float(@vented_attic_sla))
          elsif not @vented_attic_ach.nil?
            ventilation_rate = XMLHelper.add_element(attic, 'VentilationRate')
            XMLHelper.add_element(ventilation_rate, 'UnitofMeasure', 'ACHnatural')
            XMLHelper.add_element(ventilation_rate, 'Value', to_float(@vented_attic_ach))
          end
        elsif @attic_type == AtticTypeConditioned
          attic_type_attic = XMLHelper.add_element(attic_type_e, 'Attic')
          XMLHelper.add_element(attic_type_attic, 'Conditioned', true)
        elsif (@attic_type == AtticTypeFlatRoof) || (@attic_type == AtticTypeCathedral)
          XMLHelper.add_element(attic_type_e, @attic_type)
        else
          fail "Unhandled attic type '#{@attic_type}'."
        end
      end
      XMLHelper.add_element(attic, 'WithinInfiltrationVolume', to_boolean(@within_infiltration_volume)) unless @within_infiltration_volume.nil?
    end

    def from_oga(attic)
      return if attic.nil?

      @id = HPXML::get_id(attic)
      if XMLHelper.has_element(attic, "AtticType/Attic[Vented='false']")
        @attic_type = AtticTypeUnvented
      elsif XMLHelper.has_element(attic, "AtticType/Attic[Vented='true']")
        @attic_type = AtticTypeVented
      elsif XMLHelper.has_element(attic, "AtticType/Attic[Conditioned='true']")
        @attic_type = AtticTypeConditioned
      elsif XMLHelper.has_element(attic, 'AtticType/FlatRoof')
        @attic_type = AtticTypeFlatRoof
      elsif XMLHelper.has_element(attic, 'AtticType/CathedralCeiling')
        @attic_type = AtticTypeCathedral
      end
      if @attic_type == AtticTypeVented
        @vented_attic_sla = to_float_or_nil(XMLHelper.get_value(attic, "VentilationRate[UnitofMeasure='SLA']/Value"))
        @vented_attic_ach = to_float_or_nil(XMLHelper.get_value(attic, "VentilationRate[UnitofMeasure='ACHnatural']/Value"))
      end
      @within_infiltration_volume = to_bool_or_nil(XMLHelper.get_value(attic, 'WithinInfiltrationVolume'))
      @attached_to_roof_idrefs = []
      XMLHelper.get_elements(attic, 'AttachedToRoof').each do |roof|
        @attached_to_roof_idrefs << HPXML::get_idref(roof)
      end
      @attached_to_frame_floor_idrefs = []
      XMLHelper.get_elements(attic, 'AttachedToFrameFloor').each do |frame_floor|
        @attached_to_frame_floor_idrefs << HPXML::get_idref(frame_floor)
      end
    end
  end

  class Foundations < BaseArrayElement
    def add(**kwargs)
      self << Foundation.new(@hpxml_object, **kwargs)
    end

    def from_oga(hpxml)
      return if hpxml.nil?

      XMLHelper.get_elements(hpxml, 'Building/BuildingDetails/Enclosure/Foundations/Foundation').each do |foundation|
        self << Foundation.new(@hpxml_object, foundation)
      end
    end
  end

  class Foundation < BaseElement
    ATTRS = [:id, :foundation_type, :vented_crawlspace_sla, :unconditioned_basement_thermal_boundary, :within_infiltration_volume,
             :attached_to_slab_idrefs, :attached_to_frame_floor_idrefs, :attached_to_foundation_wall_idrefs]
    attr_accessor(*ATTRS)

    def attached_slabs
      return [] if @attached_to_slab_idrefs.nil?

      list = @hpxml_object.slabs.select { |slab| @attached_to_slab_idrefs.include? slab.id }
      if @attached_to_slab_idrefs.size > list.size
        fail "Attached slab not found for foundation '#{@id}'."
      end

      return list
    end

    def attached_frame_floors
      return [] if @attached_to_frame_floor_idrefs.nil?

      list = @hpxml_object.frame_floors.select { |frame_floor| @attached_to_frame_floor_idrefs.include? frame_floor.id }
      if @attached_to_frame_floor_idrefs.size > list.size
        fail "Attached frame floor not found for foundation '#{@id}'."
      end

      return list
    end

    def attached_foundation_walls
      return [] if @attached_to_foundation_wall_idrefs.nil?

      list = @hpxml_object.foundation_walls.select { |foundation_wall| @attached_to_foundation_wall_idrefs.include? foundation_wall.id }
      if @attached_to_foundation_wall_idrefs.size > list.size
        fail "Attached foundation wall not found for foundation '#{@id}'."
      end

      return list
    end

    def to_location
      return if @foundation_type.nil?

      if @foundation_type == FoundationTypeAmbient
        return LocationOutside
      elsif @foundation_type == FoundationTypeBasementConditioned
        return LocationBasementConditioned
      elsif @foundation_type == FoundationTypeBasementUnconditioned
        return LocationBasementUnconditioned
      elsif @foundation_type == FoundationTypeCrawlspaceUnvented
        return LocationCrawlspaceUnvented
      elsif @foundation_type == FoundationTypeCrawlspaceVented
        return LocationCrawlspaceVented
      elsif @foundation_type == FoundationTypeSlab
        return LocationLivingSpace
      else
        fail "Unexpected foundation type: '#{@foundation_type}'."
      end
    end

    def area
      sum_area = 0.0
      # Check Slabs first
      attached_slabs.each do |slab|
        sum_area += slab.area
      end
      if sum_area <= 0
        # Check FrameFloors next
        attached_frame_floors.each do |frame_floor|
          sum_area += frame_floor.area
        end
      end
      return sum_area
    end

    def check_for_errors
      errors = []
      begin; attached_slabs; rescue StandardError => e; errors << e.message; end
      begin; attached_frame_floors; rescue StandardError => e; errors << e.message; end
      begin; attached_foundation_walls; rescue StandardError => e; errors << e.message; end
      begin; to_location; rescue StandardError => e; errors << e.message; end
      return errors
    end

    def to_oga(doc)
      return if nil?

      foundations = XMLHelper.create_elements_as_needed(doc, ['HPXML', 'Building', 'BuildingDetails', 'Enclosure', 'Foundations'])
      foundation = XMLHelper.add_element(foundations, 'Foundation')
      sys_id = XMLHelper.add_element(foundation, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      if not @foundation_type.nil?
        foundation_type_e = XMLHelper.add_element(foundation, 'FoundationType')
        if [FoundationTypeSlab, FoundationTypeAmbient].include? @foundation_type
          XMLHelper.add_element(foundation_type_e, @foundation_type)
        elsif @foundation_type == FoundationTypeBasementConditioned
          basement = XMLHelper.add_element(foundation_type_e, 'Basement')
          XMLHelper.add_element(basement, 'Conditioned', true)
        elsif @foundation_type == FoundationTypeBasementUnconditioned
          basement = XMLHelper.add_element(foundation_type_e, 'Basement')
          XMLHelper.add_element(basement, 'Conditioned', false)
          XMLHelper.add_element(foundation, 'ThermalBoundary', @unconditioned_basement_thermal_boundary) unless @unconditioned_basement_thermal_boundary.nil?
        elsif @foundation_type == FoundationTypeCrawlspaceVented
          crawlspace = XMLHelper.add_element(foundation_type_e, 'Crawlspace')
          XMLHelper.add_element(crawlspace, 'Vented', true)
          if not @vented_crawlspace_sla.nil?
            ventilation_rate = XMLHelper.add_element(foundation, 'VentilationRate')
            XMLHelper.add_element(ventilation_rate, 'UnitofMeasure', 'SLA')
            XMLHelper.add_element(ventilation_rate, 'Value', to_float(@vented_crawlspace_sla))
          end
        elsif @foundation_type == FoundationTypeCrawlspaceUnvented
          crawlspace = XMLHelper.add_element(foundation_type_e, 'Crawlspace')
          XMLHelper.add_element(crawlspace, 'Vented', false)
        else
          fail "Unhandled foundation type '#{@foundation_type}'."
        end
      end
      XMLHelper.add_element(foundation, 'WithinInfiltrationVolume', to_boolean(@within_infiltration_volume)) unless @within_infiltration_volume.nil?
    end

    def from_oga(foundation)
      return if foundation.nil?

      @id = HPXML::get_id(foundation)
      if XMLHelper.has_element(foundation, 'FoundationType/SlabOnGrade')
        @foundation_type = FoundationTypeSlab
      elsif XMLHelper.has_element(foundation, "FoundationType/Basement[Conditioned='false']")
        @foundation_type = FoundationTypeBasementUnconditioned
      elsif XMLHelper.has_element(foundation, "FoundationType/Basement[Conditioned='true']")
        @foundation_type = FoundationTypeBasementConditioned
      elsif XMLHelper.has_element(foundation, "FoundationType/Crawlspace[Vented='false']")
        @foundation_type = FoundationTypeCrawlspaceUnvented
      elsif XMLHelper.has_element(foundation, "FoundationType/Crawlspace[Vented='true']")
        @foundation_type = FoundationTypeCrawlspaceVented
      elsif XMLHelper.has_element(foundation, 'FoundationType/Ambient')
        @foundation_type = FoundationTypeAmbient
      end
      if @foundation_type == FoundationTypeCrawlspaceVented
        @vented_crawlspace_sla = to_float_or_nil(XMLHelper.get_value(foundation, "VentilationRate[UnitofMeasure='SLA']/Value"))
      elsif @foundation_type == FoundationTypeBasementUnconditioned
        @unconditioned_basement_thermal_boundary = XMLHelper.get_value(foundation, 'ThermalBoundary')
      end
      @within_infiltration_volume = to_bool_or_nil(XMLHelper.get_value(foundation, 'WithinInfiltrationVolume'))
      @attached_to_slab_idrefs = []
      XMLHelper.get_elements(foundation, 'AttachedToSlab').each do |slab|
        @attached_to_slab_idrefs << HPXML::get_idref(slab)
      end
      @attached_to_frame_floor_idrefs = []
      XMLHelper.get_elements(foundation, 'AttachedToFrameFloor').each do |frame_floor|
        @attached_to_frame_floor_idrefs << HPXML::get_idref(frame_floor)
      end
      @attached_to_foundation_wall_idrefs = []
      XMLHelper.get_elements(foundation, 'AttachedToFoundationWall').each do |foundation_wall|
        @attached_to_foundation_wall_idrefs << HPXML::get_idref(foundation_wall)
      end
    end
  end

  class Roofs < BaseArrayElement
    def add(**kwargs)
      self << Roof.new(@hpxml_object, **kwargs)
    end

    def from_oga(hpxml)
      return if hpxml.nil?

      XMLHelper.get_elements(hpxml, 'Building/BuildingDetails/Enclosure/Roofs/Roof').each do |roof|
        self << Roof.new(@hpxml_object, roof)
      end
    end
  end

  class Roof < BaseElement
    ATTRS = [:id, :exterior_adjacent_to, :interior_adjacent_to, :area, :azimuth, :roof_type,
             :roof_color, :solar_absorptance, :emittance, :pitch, :radiant_barrier,
             :insulation_id, :insulation_assembly_r_value, :insulation_cavity_r_value,
             :insulation_continuous_r_value]
    attr_accessor(*ATTRS)

    def skylights
      return @hpxml_object.skylights.select { |skylight| skylight.roof_idref == @id }
    end

    def net_area
      return if nil?

      val = @area
      skylights.each do |skylight|
        val -= skylight.area
      end
      fail "Calculated a negative net surface area for surface '#{@id}'." if val < 0

      return val
    end

    def exterior_adjacent_to
      return LocationOutside
    end

    def is_exterior
      return true
    end

    def is_interior
      return !is_exterior
    end

    def is_thermal_boundary
      return HPXML::is_thermal_boundary(self)
    end

    def is_exterior_thermal_boundary
      return (is_exterior && is_thermal_boundary)
    end

    def delete
      @hpxml_object.roofs.delete(self)
      skylights.reverse_each do |skylight|
        skylight.delete
      end
      @hpxml_object.attics.each do |attic|
        attic.attached_to_roof_idrefs.delete(@id) unless attic.attached_to_roof_idrefs.nil?
      end
    end

    def check_for_errors
      errors = []
      begin; net_area; rescue StandardError => e; errors << e.message; end
      return errors
    end

    def to_oga(doc)
      return if nil?

      roofs = XMLHelper.create_elements_as_needed(doc, ['HPXML', 'Building', 'BuildingDetails', 'Enclosure', 'Roofs'])
      roof = XMLHelper.add_element(roofs, 'Roof')
      sys_id = XMLHelper.add_element(roof, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_element(roof, 'InteriorAdjacentTo', @interior_adjacent_to) unless @interior_adjacent_to.nil?
      XMLHelper.add_element(roof, 'Area', to_float(@area)) unless @area.nil?
      XMLHelper.add_element(roof, 'Azimuth', to_integer(@azimuth)) unless @azimuth.nil?
      XMLHelper.add_element(roof, 'RoofType', @roof_type) unless @roof_type.nil?
      XMLHelper.add_element(roof, 'RoofColor', @roof_color) unless @roof_color.nil?
      XMLHelper.add_element(roof, 'SolarAbsorptance', to_float(@solar_absorptance)) unless @solar_absorptance.nil?
      XMLHelper.add_element(roof, 'Emittance', to_float(@emittance)) unless @emittance.nil?
      XMLHelper.add_element(roof, 'Pitch', to_float(@pitch)) unless @pitch.nil?
      XMLHelper.add_element(roof, 'RadiantBarrier', to_boolean(@radiant_barrier)) unless @radiant_barrier.nil?
      insulation = XMLHelper.add_element(roof, 'Insulation')
      sys_id = XMLHelper.add_element(insulation, 'SystemIdentifier')
      if not @insulation_id.nil?
        XMLHelper.add_attribute(sys_id, 'id', @insulation_id)
      else
        XMLHelper.add_attribute(sys_id, 'id', @id + 'Insulation')
      end
      XMLHelper.add_element(insulation, 'AssemblyEffectiveRValue', to_float(@insulation_assembly_r_value)) unless @insulation_assembly_r_value.nil?
    end

    def from_oga(roof)
      return if roof.nil?

      @id = HPXML::get_id(roof)
      @interior_adjacent_to = XMLHelper.get_value(roof, 'InteriorAdjacentTo')
      @area = to_float_or_nil(XMLHelper.get_value(roof, 'Area'))
      @azimuth = to_integer_or_nil(XMLHelper.get_value(roof, 'Azimuth'))
      @roof_type = XMLHelper.get_value(roof, 'RoofType')
      @roof_color = XMLHelper.get_value(roof, 'RoofColor')
      @solar_absorptance = to_float_or_nil(XMLHelper.get_value(roof, 'SolarAbsorptance'))
      @emittance = to_float_or_nil(XMLHelper.get_value(roof, 'Emittance'))
      @pitch = to_float_or_nil(XMLHelper.get_value(roof, 'Pitch'))
      @radiant_barrier = to_bool_or_nil(XMLHelper.get_value(roof, 'RadiantBarrier'))
      insulation = XMLHelper.get_element(roof, 'Insulation')
      if not insulation.nil?
        @insulation_id = HPXML::get_id(insulation)
        @insulation_assembly_r_value = to_float_or_nil(XMLHelper.get_value(insulation, 'AssemblyEffectiveRValue'))
        @insulation_cavity_r_value = to_float_or_nil(XMLHelper.get_value(insulation, "Layer[InstallationType='cavity']/NominalRValue"))
        @insulation_continuous_r_value = to_float_or_nil(XMLHelper.get_value(insulation, "Layer[InstallationType='continuous']/NominalRValue"))
      end
    end
  end

  class RimJoists < BaseArrayElement
    def add(**kwargs)
      self << RimJoist.new(@hpxml_object, **kwargs)
    end

    def from_oga(hpxml)
      return if hpxml.nil?

      XMLHelper.get_elements(hpxml, 'Building/BuildingDetails/Enclosure/RimJoists/RimJoist').each do |rim_joist|
        self << RimJoist.new(@hpxml_object, rim_joist)
      end
    end
  end

  class RimJoist < BaseElement
    ATTRS = [:id, :exterior_adjacent_to, :interior_adjacent_to, :area, :azimuth, :siding, :color,
             :solar_absorptance, :emittance, :insulation_id, :insulation_assembly_r_value,
             :insulation_cavity_r_value, :insulation_continuous_r_value]
    attr_accessor(*ATTRS)

    def is_exterior
      if @exterior_adjacent_to == LocationOutside
        return true
      end

      return false
    end

    def is_interior
      return !is_exterior
    end

    def is_thermal_boundary
      HPXML::is_thermal_boundary(self)
    end

    def is_exterior_thermal_boundary
      return (is_exterior && is_thermal_boundary)
    end

    def delete
      @hpxml_object.rim_joists.delete(self)
    end

    def check_for_errors
      errors = []
      return errors
    end

    def to_oga(doc)
      return if nil?

      rim_joists = XMLHelper.create_elements_as_needed(doc, ['HPXML', 'Building', 'BuildingDetails', 'Enclosure', 'RimJoists'])
      rim_joist = XMLHelper.add_element(rim_joists, 'RimJoist')
      sys_id = XMLHelper.add_element(rim_joist, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_element(rim_joist, 'ExteriorAdjacentTo', @exterior_adjacent_to) unless @exterior_adjacent_to.nil?
      XMLHelper.add_element(rim_joist, 'InteriorAdjacentTo', @interior_adjacent_to) unless @interior_adjacent_to.nil?
      XMLHelper.add_element(rim_joist, 'Area', to_float(@area)) unless @area.nil?
      XMLHelper.add_element(rim_joist, 'Azimuth', to_integer(@azimuth)) unless @azimuth.nil?
      XMLHelper.add_element(rim_joist, 'Siding', @siding) unless @siding.nil?
      XMLHelper.add_element(rim_joist, 'Color', @color) unless @color.nil?
      XMLHelper.add_element(rim_joist, 'SolarAbsorptance', to_float(@solar_absorptance)) unless @solar_absorptance.nil?
      XMLHelper.add_element(rim_joist, 'Emittance', to_float(@emittance)) unless @emittance.nil?
      insulation = XMLHelper.add_element(rim_joist, 'Insulation')
      sys_id = XMLHelper.add_element(insulation, 'SystemIdentifier')
      if not @insulation_id.nil?
        XMLHelper.add_attribute(sys_id, 'id', @insulation_id)
      else
        XMLHelper.add_attribute(sys_id, 'id', @id + 'Insulation')
      end
      XMLHelper.add_element(insulation, 'AssemblyEffectiveRValue', to_float(@insulation_assembly_r_value)) unless @insulation_assembly_r_value.nil?
    end

    def from_oga(rim_joist)
      return if rim_joist.nil?

      @id = HPXML::get_id(rim_joist)
      @exterior_adjacent_to = XMLHelper.get_value(rim_joist, 'ExteriorAdjacentTo')
      @interior_adjacent_to = XMLHelper.get_value(rim_joist, 'InteriorAdjacentTo')
      @area = to_float_or_nil(XMLHelper.get_value(rim_joist, 'Area'))
      @azimuth = to_integer_or_nil(XMLHelper.get_value(rim_joist, 'Azimuth'))
      @siding = XMLHelper.get_value(rim_joist, 'Siding')
      @color = XMLHelper.get_value(rim_joist, 'Color')
      @solar_absorptance = to_float_or_nil(XMLHelper.get_value(rim_joist, 'SolarAbsorptance'))
      @emittance = to_float_or_nil(XMLHelper.get_value(rim_joist, 'Emittance'))
      insulation = XMLHelper.get_element(rim_joist, 'Insulation')
      if not insulation.nil?
        @insulation_id = HPXML::get_id(insulation)
        @insulation_assembly_r_value = to_float_or_nil(XMLHelper.get_value(insulation, 'AssemblyEffectiveRValue'))
        @insulation_cavity_r_value = to_float_or_nil(XMLHelper.get_value(insulation, "Layer[InstallationType='cavity']/NominalRValue"))
        @insulation_continuous_r_value = to_float_or_nil(XMLHelper.get_value(insulation, "Layer[InstallationType='continuous']/NominalRValue"))
      end
    end
  end

  class Walls < BaseArrayElement
    def add(**kwargs)
      self << Wall.new(@hpxml_object, **kwargs)
    end

    def from_oga(hpxml)
      return if hpxml.nil?

      XMLHelper.get_elements(hpxml, 'Building/BuildingDetails/Enclosure/Walls/Wall').each do |wall|
        self << Wall.new(@hpxml_object, wall)
      end
    end
  end

  class Wall < BaseElement
    ATTRS = [:id, :exterior_adjacent_to, :interior_adjacent_to, :wall_type, :optimum_value_engineering,
             :area, :orientation, :azimuth, :siding, :color, :solar_absorptance, :emittance, :insulation_id,
             :insulation_assembly_r_value, :insulation_cavity_r_value, :insulation_continuous_r_value]
    attr_accessor(*ATTRS)

    def windows
      return @hpxml_object.windows.select { |window| window.wall_idref == @id }
    end

    def doors
      return @hpxml_object.doors.select { |door| door.wall_idref == @id }
    end

    def net_area
      return if nil?

      val = @area
      (windows + doors).each do |subsurface|
        val -= subsurface.area
      end
      fail "Calculated a negative net surface area for surface '#{@id}'." if val < 0

      return val
    end

    def is_exterior
      if @exterior_adjacent_to == LocationOutside
        return true
      end

      return false
    end

    def is_interior
      return !is_exterior
    end

    def is_thermal_boundary
      HPXML::is_thermal_boundary(self)
    end

    def is_exterior_thermal_boundary
      return (is_exterior && is_thermal_boundary)
    end

    def delete
      @hpxml_object.walls.delete(self)
      windows.reverse_each do |window|
        window.delete
      end
      doors.reverse_each do |door|
        door.delete
      end
    end

    def check_for_errors
      errors = []
      begin; net_area; rescue StandardError => e; errors << e.message; end
      return errors
    end

    def to_oga(doc)
      return if nil?

      walls = XMLHelper.create_elements_as_needed(doc, ['HPXML', 'Building', 'BuildingDetails', 'Enclosure', 'Walls'])
      wall = XMLHelper.add_element(walls, 'Wall')
      sys_id = XMLHelper.add_element(wall, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_element(wall, 'ExteriorAdjacentTo', @exterior_adjacent_to) unless @exterior_adjacent_to.nil?
      XMLHelper.add_element(wall, 'InteriorAdjacentTo', @interior_adjacent_to) unless @interior_adjacent_to.nil?
      if not @wall_type.nil?
        wall_type_e = XMLHelper.add_element(wall, 'WallType')
        XMLHelper.add_element(wall_type_e, @wall_type)
      end
      XMLHelper.add_element(wall, 'Area', to_float(@area)) unless @area.nil?
      XMLHelper.add_element(wall, 'Azimuth', to_integer(@azimuth)) unless @azimuth.nil?
      XMLHelper.add_element(wall, 'Siding', @siding) unless @siding.nil?
      XMLHelper.add_element(wall, 'Color', @color) unless @color.nil?
      XMLHelper.add_element(wall, 'SolarAbsorptance', to_float(@solar_absorptance)) unless @solar_absorptance.nil?
      XMLHelper.add_element(wall, 'Emittance', to_float(@emittance)) unless @emittance.nil?
      insulation = XMLHelper.add_element(wall, 'Insulation')
      sys_id = XMLHelper.add_element(insulation, 'SystemIdentifier')
      if not @insulation_id.nil?
        XMLHelper.add_attribute(sys_id, 'id', @insulation_id)
      else
        XMLHelper.add_attribute(sys_id, 'id', @id + 'Insulation')
      end
      XMLHelper.add_element(insulation, 'AssemblyEffectiveRValue', to_float(@insulation_assembly_r_value)) unless @insulation_assembly_r_value.nil?
    end

    def from_oga(wall)
      return if wall.nil?

      @id = HPXML::get_id(wall)
      @exterior_adjacent_to = XMLHelper.get_value(wall, 'ExteriorAdjacentTo')
      @interior_adjacent_to = XMLHelper.get_value(wall, 'InteriorAdjacentTo')
      @wall_type = XMLHelper.get_child_name(wall, 'WallType')
      @optimum_value_engineering = to_bool_or_nil(XMLHelper.get_value(wall, 'WallType/WoodStud/OptimumValueEngineering'))
      @area = to_float_or_nil(XMLHelper.get_value(wall, 'Area'))
      @orientation = XMLHelper.get_value(wall, 'Orientation')
      @azimuth = to_integer_or_nil(XMLHelper.get_value(wall, 'Azimuth'))
      @siding = XMLHelper.get_value(wall, 'Siding')
      @color = XMLHelper.get_value(wall, 'Color')
      @solar_absorptance = to_float_or_nil(XMLHelper.get_value(wall, 'SolarAbsorptance'))
      @emittance = to_float_or_nil(XMLHelper.get_value(wall, 'Emittance'))
      insulation = XMLHelper.get_element(wall, 'Insulation')
      if not insulation.nil?
        @insulation_id = HPXML::get_id(insulation)
        @insulation_assembly_r_value = to_float_or_nil(XMLHelper.get_value(insulation, 'AssemblyEffectiveRValue'))
        @insulation_cavity_r_value = to_float_or_nil(XMLHelper.get_value(insulation, "Layer[InstallationType='cavity']/NominalRValue"))
        @insulation_continuous_r_value = to_float_or_nil(XMLHelper.get_value(insulation, "Layer[InstallationType='continuous']/NominalRValue"))
      end
    end
  end

  class FoundationWalls < BaseArrayElement
    def add(**kwargs)
      self << FoundationWall.new(@hpxml_object, **kwargs)
    end

    def from_oga(hpxml)
      return if hpxml.nil?

      XMLHelper.get_elements(hpxml, 'Building/BuildingDetails/Enclosure/FoundationWalls/FoundationWall').each do |foundation_wall|
        self << FoundationWall.new(@hpxml_object, foundation_wall)
      end
    end
  end

  class FoundationWall < BaseElement
    ATTRS = [:id, :exterior_adjacent_to, :interior_adjacent_to, :height, :area, :azimuth, :thickness,
             :depth_below_grade, :insulation_id, :insulation_r_value, :insulation_interior_r_value,
             :insulation_interior_distance_to_top, :insulation_interior_distance_to_bottom,
             :insulation_exterior_r_value, :insulation_exterior_distance_to_top,
             :insulation_exterior_distance_to_bottom, :insulation_assembly_r_value,
             :insulation_continuous_r_value]
    attr_accessor(*ATTRS)

    def windows
      return @hpxml_object.windows.select { |window| window.wall_idref == @id }
    end

    def doors
      return @hpxml_object.doors.select { |door| door.wall_idref == @id }
    end

    def net_area
      return if nil?

      val = @area
      (@hpxml_object.windows + @hpxml_object.doors).each do |subsurface|
        next unless subsurface.wall_idref == @id

        val -= subsurface.area
      end
      fail "Calculated a negative net surface area for surface '#{@id}'." if val < 0

      return val
    end

    def is_exterior
      if @exterior_adjacent_to == LocationGround
        return true
      end

      return false
    end

    def is_interior
      return !is_exterior
    end

    def is_thermal_boundary
      HPXML::is_thermal_boundary(self)
    end

    def is_exterior_thermal_boundary
      return (is_exterior && is_thermal_boundary)
    end

    def delete
      @hpxml_object.foundation_walls.delete(self)
      windows.reverse_each do |window|
        window.delete
      end
      doors.reverse_each do |door|
        door.delete
      end
      @hpxml_object.foundations.each do |foundation|
        foundation.attached_to_foundation_wall_idrefs.delete(@id) unless foundation.attached_to_foundation_wall_idrefs.nil?
      end
    end

    def check_for_errors
      errors = []
      begin; net_area; rescue StandardError => e; errors << e.message; end
      return errors
    end

    def to_oga(doc)
      return if nil?

      foundation_walls = XMLHelper.create_elements_as_needed(doc, ['HPXML', 'Building', 'BuildingDetails', 'Enclosure', 'FoundationWalls'])
      foundation_wall = XMLHelper.add_element(foundation_walls, 'FoundationWall')
      sys_id = XMLHelper.add_element(foundation_wall, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_element(foundation_wall, 'ExteriorAdjacentTo', @exterior_adjacent_to) unless @exterior_adjacent_to.nil?
      XMLHelper.add_element(foundation_wall, 'InteriorAdjacentTo', @interior_adjacent_to) unless @interior_adjacent_to.nil?
      XMLHelper.add_element(foundation_wall, 'Height', to_float(@height)) unless @height.nil?
      XMLHelper.add_element(foundation_wall, 'Area', to_float(@area)) unless @area.nil?
      XMLHelper.add_element(foundation_wall, 'Azimuth', to_integer(@azimuth)) unless @azimuth.nil?
      XMLHelper.add_element(foundation_wall, 'Thickness', to_float(@thickness)) unless @thickness.nil?
      XMLHelper.add_element(foundation_wall, 'DepthBelowGrade', to_float(@depth_below_grade)) unless @depth_below_grade.nil?
      insulation = XMLHelper.add_element(foundation_wall, 'Insulation')
      sys_id = XMLHelper.add_element(insulation, 'SystemIdentifier')
      if not @insulation_id.nil?
        XMLHelper.add_attribute(sys_id, 'id', @insulation_id)
      else
        XMLHelper.add_attribute(sys_id, 'id', @id + 'Insulation')
      end
      XMLHelper.add_element(insulation, 'AssemblyEffectiveRValue', to_float(@insulation_assembly_r_value)) unless @insulation_assembly_r_value.nil?
      if not @insulation_exterior_r_value.nil?
        layer = XMLHelper.add_element(insulation, 'Layer')
        XMLHelper.add_element(layer, 'InstallationType', 'continuous - exterior')
        XMLHelper.add_element(layer, 'NominalRValue', to_float(@insulation_exterior_r_value))
        HPXML::add_extension(parent: layer,
                             extensions: { 'DistanceToTopOfInsulation' => to_float_or_nil(@insulation_exterior_distance_to_top),
                                           'DistanceToBottomOfInsulation' => to_float_or_nil(@insulation_exterior_distance_to_bottom) })
      end
      if not @insulation_interior_r_value.nil?
        layer = XMLHelper.add_element(insulation, 'Layer')
        XMLHelper.add_element(layer, 'InstallationType', 'continuous - interior')
        XMLHelper.add_element(layer, 'NominalRValue', to_float(@insulation_interior_r_value))
        HPXML::add_extension(parent: layer,
                             extensions: { 'DistanceToTopOfInsulation' => to_float_or_nil(@insulation_interior_distance_to_top),
                                           'DistanceToBottomOfInsulation' => to_float_or_nil(@insulation_interior_distance_to_bottom) })
      end
    end

    def from_oga(foundation_wall)
      return if foundation_wall.nil?

      @id = HPXML::get_id(foundation_wall)
      @exterior_adjacent_to = XMLHelper.get_value(foundation_wall, 'ExteriorAdjacentTo')
      @interior_adjacent_to = XMLHelper.get_value(foundation_wall, 'InteriorAdjacentTo')
      @height = to_float_or_nil(XMLHelper.get_value(foundation_wall, 'Height'))
      @area = to_float_or_nil(XMLHelper.get_value(foundation_wall, 'Area'))
      @azimuth = to_integer_or_nil(XMLHelper.get_value(foundation_wall, 'Azimuth'))
      @thickness = to_float_or_nil(XMLHelper.get_value(foundation_wall, 'Thickness'))
      @depth_below_grade = to_float_or_nil(XMLHelper.get_value(foundation_wall, 'DepthBelowGrade'))
      insulation = XMLHelper.get_element(foundation_wall, 'Insulation')
      if not insulation.nil?
        @insulation_id = HPXML::get_id(insulation)
        @insulation_r_value = to_float_or_nil(XMLHelper.get_value(insulation, "Layer[InstallationType='continuous']/NominalRValue"))
        @insulation_interior_r_value = to_float_or_nil(XMLHelper.get_value(insulation, "Layer[InstallationType='continuous - interior']/NominalRValue"))
        @insulation_interior_distance_to_top = to_float_or_nil(XMLHelper.get_value(insulation, "Layer[InstallationType='continuous - interior']/extension/DistanceToTopOfInsulation"))
        @insulation_interior_distance_to_bottom = to_float_or_nil(XMLHelper.get_value(insulation, "Layer[InstallationType='continuous - interior']/extension/DistanceToBottomOfInsulation"))
        @insulation_exterior_r_value = to_float_or_nil(XMLHelper.get_value(insulation, "Layer[InstallationType='continuous - exterior']/NominalRValue"))
        @insulation_exterior_distance_to_top = to_float_or_nil(XMLHelper.get_value(insulation, "Layer[InstallationType='continuous - exterior']/extension/DistanceToTopOfInsulation"))
        @insulation_exterior_distance_to_bottom = to_float_or_nil(XMLHelper.get_value(insulation, "Layer[InstallationType='continuous - exterior']/extension/DistanceToBottomOfInsulation"))
        @insulation_continuous_r_value = to_float_or_nil(XMLHelper.get_value(insulation, "Layer[InstallationType='continuous']/NominalRValue"))
        @insulation_assembly_r_value = to_float_or_nil(XMLHelper.get_value(insulation, 'AssemblyEffectiveRValue'))
      end
    end
  end

  class FrameFloors < BaseArrayElement
    def add(**kwargs)
      self << FrameFloor.new(@hpxml_object, **kwargs)
    end

    def from_oga(hpxml)
      return if hpxml.nil?

      XMLHelper.get_elements(hpxml, 'Building/BuildingDetails/Enclosure/FrameFloors/FrameFloor').each do |frame_floor|
        self << FrameFloor.new(@hpxml_object, frame_floor)
      end
    end
  end

  class FrameFloor < BaseElement
    ATTRS = [:id, :exterior_adjacent_to, :interior_adjacent_to, :area, :insulation_id,
             :insulation_assembly_r_value, :insulation_cavity_r_value, :insulation_continuous_r_value,
             :other_space_above_or_below]
    attr_accessor(*ATTRS)

    def is_ceiling
      if [LocationAtticVented, LocationAtticUnvented].include? @interior_adjacent_to
        return true
      elsif [LocationAtticVented, LocationAtticUnvented].include? @exterior_adjacent_to
        return true
      elsif [LocationOtherHousingUnit, LocationOtherHeatedSpace, LocationOtherMultifamilyBufferSpace, LocationOtherNonFreezingSpace].include?(@exterior_adjacent_to) && (@other_space_above_or_below == FrameFloorOtherSpaceAbove)
        return true
      end

      return false
    end

    def is_floor
      !is_ceiling
    end

    def is_exterior
      if @exterior_adjacent_to == LocationOutside
        return true
      end

      return false
    end

    def is_interior
      return !is_exterior
    end

    def is_thermal_boundary
      HPXML::is_thermal_boundary(self)
    end

    def is_exterior_thermal_boundary
      return (is_exterior && is_thermal_boundary)
    end

    def delete
      @hpxml_object.frame_floors.delete(self)
      @hpxml_object.attics.each do |attic|
        attic.attached_to_frame_floor_idrefs.delete(@id) unless attic.attached_to_frame_floor_idrefs.nil?
      end
      @hpxml_object.foundations.each do |foundation|
        foundation.attached_to_frame_floor_idrefs.delete(@id) unless foundation.attached_to_frame_floor_idrefs.nil?
      end
    end

    def check_for_errors
      errors = []
      return errors
    end

    def to_oga(doc)
      return if nil?

      frame_floors = XMLHelper.create_elements_as_needed(doc, ['HPXML', 'Building', 'BuildingDetails', 'Enclosure', 'FrameFloors'])
      frame_floor = XMLHelper.add_element(frame_floors, 'FrameFloor')
      sys_id = XMLHelper.add_element(frame_floor, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_element(frame_floor, 'ExteriorAdjacentTo', @exterior_adjacent_to) unless @exterior_adjacent_to.nil?
      XMLHelper.add_element(frame_floor, 'InteriorAdjacentTo', @interior_adjacent_to) unless @interior_adjacent_to.nil?
      XMLHelper.add_element(frame_floor, 'Area', to_float(@area)) unless @area.nil?
      insulation = XMLHelper.add_element(frame_floor, 'Insulation')
      sys_id = XMLHelper.add_element(insulation, 'SystemIdentifier')
      if not @insulation_id.nil?
        XMLHelper.add_attribute(sys_id, 'id', @insulation_id)
      else
        XMLHelper.add_attribute(sys_id, 'id', @id + 'Insulation')
      end
      XMLHelper.add_element(insulation, 'AssemblyEffectiveRValue', to_float(@insulation_assembly_r_value)) unless @insulation_assembly_r_value.nil?
      HPXML::add_extension(parent: frame_floor,
                           extensions: { 'OtherSpaceAboveOrBelow' => @other_space_above_or_below })
    end

    def from_oga(frame_floor)
      return if frame_floor.nil?

      @id = HPXML::get_id(frame_floor)
      @exterior_adjacent_to = XMLHelper.get_value(frame_floor, 'ExteriorAdjacentTo')
      @interior_adjacent_to = XMLHelper.get_value(frame_floor, 'InteriorAdjacentTo')
      @area = to_float_or_nil(XMLHelper.get_value(frame_floor, 'Area'))
      insulation = XMLHelper.get_element(frame_floor, 'Insulation')
      if not insulation.nil?
        @insulation_id = HPXML::get_id(insulation)
        @insulation_assembly_r_value = to_float_or_nil(XMLHelper.get_value(insulation, 'AssemblyEffectiveRValue'))
        @insulation_cavity_r_value = to_float_or_nil(XMLHelper.get_value(insulation, "Layer[InstallationType='cavity']/NominalRValue"))
        @insulation_continuous_r_value = to_float_or_nil(XMLHelper.get_value(insulation, "Layer[InstallationType='continuous']/NominalRValue"))
      end
      @other_space_above_or_below = XMLHelper.get_value(frame_floor, 'extension/OtherSpaceAboveOrBelow')
    end
  end

  class Slabs < BaseArrayElement
    def add(**kwargs)
      self << Slab.new(@hpxml_object, **kwargs)
    end

    def from_oga(hpxml)
      return if hpxml.nil?

      XMLHelper.get_elements(hpxml, 'Building/BuildingDetails/Enclosure/Slabs/Slab').each do |slab|
        self << Slab.new(@hpxml_object, slab)
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

    def exterior_adjacent_to
      return LocationGround
    end

    def is_exterior
      return true
    end

    def is_interior
      return !is_exterior
    end

    def is_thermal_boundary
      HPXML::is_thermal_boundary(self)
    end

    def is_exterior_thermal_boundary
      return (is_exterior && is_thermal_boundary)
    end

    def delete
      @hpxml_object.slabs.delete(self)
      @hpxml_object.foundations.each do |foundation|
        foundation.attached_to_slab_idrefs.delete(@id) unless foundation.attached_to_slab_idrefs.nil?
      end
    end

    def check_for_errors
      errors = []

      if not @exposed_perimeter.nil?
        if @exposed_perimeter <= 0
          fail "Exposed perimeter for Slab '#{@id}' must be greater than zero."
        end
      end

      return errors
    end

    def to_oga(doc)
      return if nil?

      slabs = XMLHelper.create_elements_as_needed(doc, ['HPXML', 'Building', 'BuildingDetails', 'Enclosure', 'Slabs'])
      slab = XMLHelper.add_element(slabs, 'Slab')
      sys_id = XMLHelper.add_element(slab, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_element(slab, 'InteriorAdjacentTo', @interior_adjacent_to) unless @interior_adjacent_to.nil?
      XMLHelper.add_element(slab, 'Area', to_float(@area)) unless @area.nil?
      XMLHelper.add_element(slab, 'Thickness', to_float(@thickness)) unless @thickness.nil?
      XMLHelper.add_element(slab, 'ExposedPerimeter', to_float(@exposed_perimeter)) unless @exposed_perimeter.nil?
      XMLHelper.add_element(slab, 'PerimeterInsulationDepth', to_float(@perimeter_insulation_depth)) unless @perimeter_insulation_depth.nil?
      XMLHelper.add_element(slab, 'UnderSlabInsulationWidth', to_float(@under_slab_insulation_width)) unless @under_slab_insulation_width.nil?
      XMLHelper.add_element(slab, 'UnderSlabInsulationSpansEntireSlab', to_boolean(@under_slab_insulation_spans_entire_slab)) unless @under_slab_insulation_spans_entire_slab.nil?
      XMLHelper.add_element(slab, 'DepthBelowGrade', to_float(@depth_below_grade)) unless @depth_below_grade.nil?
      insulation = XMLHelper.add_element(slab, 'PerimeterInsulation')
      sys_id = XMLHelper.add_element(insulation, 'SystemIdentifier')
      if not @perimeter_insulation_id.nil?
        XMLHelper.add_attribute(sys_id, 'id', @perimeter_insulation_id)
      else
        XMLHelper.add_attribute(sys_id, 'id', @id + 'PerimeterInsulation')
      end
      layer = XMLHelper.add_element(insulation, 'Layer')
      XMLHelper.add_element(layer, 'InstallationType', 'continuous')
      XMLHelper.add_element(layer, 'NominalRValue', to_float(@perimeter_insulation_r_value)) unless @perimeter_insulation_r_value.nil?
      insulation = XMLHelper.add_element(slab, 'UnderSlabInsulation')
      sys_id = XMLHelper.add_element(insulation, 'SystemIdentifier')
      if not @under_slab_insulation_id.nil?
        XMLHelper.add_attribute(sys_id, 'id', @under_slab_insulation_id)
      else
        XMLHelper.add_attribute(sys_id, 'id', @id + 'UnderSlabInsulation')
      end
      layer = XMLHelper.add_element(insulation, 'Layer')
      XMLHelper.add_element(layer, 'InstallationType', 'continuous')
      XMLHelper.add_element(layer, 'NominalRValue', to_float(@under_slab_insulation_r_value)) unless @under_slab_insulation_r_value.nil?
      HPXML::add_extension(parent: slab,
                           extensions: { 'CarpetFraction' => to_float_or_nil(@carpet_fraction),
                                         'CarpetRValue' => to_float_or_nil(@carpet_r_value) })
    end

    def from_oga(slab)
      return if slab.nil?

      @id = HPXML::get_id(slab)
      @interior_adjacent_to = XMLHelper.get_value(slab, 'InteriorAdjacentTo')
      @area = to_float_or_nil(XMLHelper.get_value(slab, 'Area'))
      @thickness = to_float_or_nil(XMLHelper.get_value(slab, 'Thickness'))
      @exposed_perimeter = to_float_or_nil(XMLHelper.get_value(slab, 'ExposedPerimeter'))
      @perimeter_insulation_depth = to_float_or_nil(XMLHelper.get_value(slab, 'PerimeterInsulationDepth'))
      @under_slab_insulation_width = to_float_or_nil(XMLHelper.get_value(slab, 'UnderSlabInsulationWidth'))
      @under_slab_insulation_spans_entire_slab = to_bool_or_nil(XMLHelper.get_value(slab, 'UnderSlabInsulationSpansEntireSlab'))
      @depth_below_grade = to_float_or_nil(XMLHelper.get_value(slab, 'DepthBelowGrade'))
      @carpet_fraction = to_float_or_nil(XMLHelper.get_value(slab, 'extension/CarpetFraction'))
      @carpet_r_value = to_float_or_nil(XMLHelper.get_value(slab, 'extension/CarpetRValue'))
      perimeter_insulation = XMLHelper.get_element(slab, 'PerimeterInsulation')
      if not perimeter_insulation.nil?
        @perimeter_insulation_id = HPXML::get_id(perimeter_insulation)
        @perimeter_insulation_r_value = to_float_or_nil(XMLHelper.get_value(perimeter_insulation, "Layer[InstallationType='continuous']/NominalRValue"))
      end
      under_slab_insulation = XMLHelper.get_element(slab, 'UnderSlabInsulation')
      if not under_slab_insulation.nil?
        @under_slab_insulation_id = HPXML::get_id(under_slab_insulation)
        @under_slab_insulation_r_value = to_float_or_nil(XMLHelper.get_value(under_slab_insulation, "Layer[InstallationType='continuous']/NominalRValue"))
      end
    end
  end

  class Windows < BaseArrayElement
    def add(**kwargs)
      self << Window.new(@hpxml_object, **kwargs)
    end

    def from_oga(hpxml)
      return if hpxml.nil?

      XMLHelper.get_elements(hpxml, 'Building/BuildingDetails/Enclosure/Windows/Window').each do |window|
        self << Window.new(@hpxml_object, window)
      end
    end
  end

  class Window < BaseElement
    ATTRS = [:id, :area, :azimuth, :orientation, :frame_type, :aluminum_thermal_break, :glass_layers,
             :glass_type, :gas_fill, :ufactor, :shgc, :interior_shading_factor_summer,
             :interior_shading_factor_winter, :exterior_shading, :overhangs_depth,
             :overhangs_distance_to_top_of_window, :overhangs_distance_to_bottom_of_window,
             :fraction_operable, :wall_idref]
    attr_accessor(*ATTRS)

    def wall
      return if @wall_idref.nil?

      (@hpxml_object.walls + @hpxml_object.foundation_walls).each do |wall|
        next unless wall.id == @wall_idref

        return wall
      end
      fail "Attached wall '#{@wall_idref}' not found for window '#{@id}'."
    end

    def is_exterior
      return wall.is_exterior
    end

    def is_interior
      return !is_exterior
    end

    def is_thermal_boundary
      HPXML::is_thermal_boundary(wall)
    end

    def is_exterior_thermal_boundary
      return (is_exterior && is_thermal_boundary)
    end

    def delete
      @hpxml_object.windows.delete(self)
    end

    def check_for_errors
      errors = []
      begin; wall; rescue StandardError => e; errors << e.message; end
      if (not @overhangs_distance_to_top_of_window.nil?) && (not @overhangs_distance_to_bottom_of_window.nil?)
        if @overhangs_distance_to_bottom_of_window <= @overhangs_distance_to_top_of_window
          fail "For Window '#{@id}', overhangs distance to bottom (#{@overhangs_distance_to_bottom_of_window}) must be greater than distance to top (#{@overhangs_distance_to_top_of_window})."
        end
      end
      # TODO: Remove this error when we can support it w/ EnergyPlus
      if (not @interior_shading_factor_summer.nil?) && (not @interior_shading_factor_winter.nil?)
        if @interior_shading_factor_summer > @interior_shading_factor_winter
          fail "SummerShadingCoefficient (#{interior_shading_factor_summer}) must be less than or equal to WinterShadingCoefficient (#{interior_shading_factor_winter}) for window '#{@id}'."
        end
      end

      return errors
    end

    def to_oga(doc)
      return if nil?

      windows = XMLHelper.create_elements_as_needed(doc, ['HPXML', 'Building', 'BuildingDetails', 'Enclosure', 'Windows'])
      window = XMLHelper.add_element(windows, 'Window')
      sys_id = XMLHelper.add_element(window, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_element(window, 'Area', to_float(@area)) unless @area.nil?
      XMLHelper.add_element(window, 'Azimuth', to_integer(@azimuth)) unless @azimuth.nil?
      XMLHelper.add_element(window, 'UFactor', to_float(@ufactor)) unless @ufactor.nil?
      XMLHelper.add_element(window, 'SHGC', to_float(@shgc)) unless @shgc.nil?
      if (not @interior_shading_factor_summer.nil?) || (not @interior_shading_factor_winter.nil?)
        interior_shading = XMLHelper.add_element(window, 'InteriorShading')
        sys_id = XMLHelper.add_element(interior_shading, 'SystemIdentifier')
        XMLHelper.add_attribute(sys_id, 'id', "#{id}InteriorShading")
        XMLHelper.add_element(interior_shading, 'SummerShadingCoefficient', to_float(@interior_shading_factor_summer)) unless @interior_shading_factor_summer.nil?
        XMLHelper.add_element(interior_shading, 'WinterShadingCoefficient', to_float(@interior_shading_factor_winter)) unless @interior_shading_factor_winter.nil?
      end
      if (not @overhangs_depth.nil?) || (not @overhangs_distance_to_top_of_window.nil?) || (not @overhangs_distance_to_bottom_of_window.nil?)
        overhangs = XMLHelper.add_element(window, 'Overhangs')
        XMLHelper.add_element(overhangs, 'Depth', to_float(@overhangs_depth)) unless @overhangs_depth.nil?
        XMLHelper.add_element(overhangs, 'DistanceToTopOfWindow', to_float(@overhangs_distance_to_top_of_window)) unless @overhangs_distance_to_top_of_window.nil?
        XMLHelper.add_element(overhangs, 'DistanceToBottomOfWindow', to_float(@overhangs_distance_to_bottom_of_window)) unless @overhangs_distance_to_bottom_of_window.nil?
      end
      XMLHelper.add_element(window, 'FractionOperable', to_float(@fraction_operable)) unless @fraction_operable.nil?
      if not @wall_idref.nil?
        attached_to_wall = XMLHelper.add_element(window, 'AttachedToWall')
        XMLHelper.add_attribute(attached_to_wall, 'idref', @wall_idref)
      end
    end

    def from_oga(window)
      return if window.nil?

      @id = HPXML::get_id(window)
      @area = to_float_or_nil(XMLHelper.get_value(window, 'Area'))
      @azimuth = to_integer_or_nil(XMLHelper.get_value(window, 'Azimuth'))
      @orientation = XMLHelper.get_value(window, 'Orientation')
      @frame_type = XMLHelper.get_child_name(window, 'FrameType')
      @aluminum_thermal_break = to_bool_or_nil(XMLHelper.get_value(window, 'FrameType/Aluminum/ThermalBreak'))
      @glass_layers = XMLHelper.get_value(window, 'GlassLayers')
      @glass_type = XMLHelper.get_value(window, 'GlassType')
      @gas_fill = XMLHelper.get_value(window, 'GasFill')
      @ufactor = to_float_or_nil(XMLHelper.get_value(window, 'UFactor'))
      @shgc = to_float_or_nil(XMLHelper.get_value(window, 'SHGC'))
      @interior_shading_factor_summer = to_float_or_nil(XMLHelper.get_value(window, 'InteriorShading/SummerShadingCoefficient'))
      @interior_shading_factor_winter = to_float_or_nil(XMLHelper.get_value(window, 'InteriorShading/WinterShadingCoefficient'))
      @exterior_shading = XMLHelper.get_value(window, 'ExteriorShading/Type')
      @overhangs_depth = to_float_or_nil(XMLHelper.get_value(window, 'Overhangs/Depth'))
      @overhangs_distance_to_top_of_window = to_float_or_nil(XMLHelper.get_value(window, 'Overhangs/DistanceToTopOfWindow'))
      @overhangs_distance_to_bottom_of_window = to_float_or_nil(XMLHelper.get_value(window, 'Overhangs/DistanceToBottomOfWindow'))
      @fraction_operable = to_float_or_nil(XMLHelper.get_value(window, 'FractionOperable'))
      @wall_idref = HPXML::get_idref(XMLHelper.get_element(window, 'AttachedToWall'))
    end
  end

  class Skylights < BaseArrayElement
    def add(**kwargs)
      self << Skylight.new(@hpxml_object, **kwargs)
    end

    def from_oga(hpxml)
      return if hpxml.nil?

      XMLHelper.get_elements(hpxml, 'Building/BuildingDetails/Enclosure/Skylights/Skylight').each do |skylight|
        self << Skylight.new(@hpxml_object, skylight)
      end
    end
  end

  class Skylight < BaseElement
    ATTRS = [:id, :area, :azimuth, :orientation, :frame_type, :aluminum_thermal_break, :glass_layers,
             :glass_type, :gas_fill, :ufactor, :shgc, :interior_shading_factor_summer,
             :interior_shading_factor_winter, :exterior_shading, :roof_idref]
    attr_accessor(*ATTRS)

    def roof
      return if @roof_idref.nil?

      @hpxml_object.roofs.each do |roof|
        next unless roof.id == @roof_idref

        return roof
      end
      fail "Attached roof '#{@roof_idref}' not found for skylight '#{@id}'."
    end

    def is_exterior
      return roof.is_exterior
    end

    def is_interior
      return !is_exterior
    end

    def is_thermal_boundary
      HPXML::is_thermal_boundary(roof)
    end

    def is_exterior_thermal_boundary
      return (is_exterior && is_thermal_boundary)
    end

    def delete
      @hpxml_object.skylights.delete(self)
    end

    def check_for_errors
      errors = []
      begin; roof; rescue StandardError => e; errors << e.message; end
      return errors
    end

    def to_oga(doc)
      return if nil?

      skylights = XMLHelper.create_elements_as_needed(doc, ['HPXML', 'Building', 'BuildingDetails', 'Enclosure', 'Skylights'])
      skylight = XMLHelper.add_element(skylights, 'Skylight')
      sys_id = XMLHelper.add_element(skylight, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_element(skylight, 'Area', to_float(@area)) unless @area.nil?
      XMLHelper.add_element(skylight, 'Azimuth', to_integer(@azimuth)) unless @azimuth.nil?
      XMLHelper.add_element(skylight, 'UFactor', to_float(@ufactor)) unless @ufactor.nil?
      XMLHelper.add_element(skylight, 'SHGC', to_float(@shgc)) unless @shgc.nil?
      if (not @interior_shading_factor_summer.nil?) || (not @interior_shading_factor_winter.nil?)
        interior_shading = XMLHelper.add_element(skylight, 'InteriorShading')
        sys_id = XMLHelper.add_element(interior_shading, 'SystemIdentifier')
        XMLHelper.add_attribute(sys_id, 'id', "#{id}InteriorShading")
        XMLHelper.add_element(interior_shading, 'SummerShadingCoefficient', to_float(@interior_shading_factor_summer)) unless @interior_shading_factor_summer.nil?
        XMLHelper.add_element(interior_shading, 'WinterShadingCoefficient', to_float(@interior_shading_factor_winter)) unless @interior_shading_factor_winter.nil?
      end
      if not @roof_idref.nil?
        attached_to_roof = XMLHelper.add_element(skylight, 'AttachedToRoof')
        XMLHelper.add_attribute(attached_to_roof, 'idref', @roof_idref)
      end
    end

    def from_oga(skylight)
      return if skylight.nil?

      @id = HPXML::get_id(skylight)
      @area = to_float_or_nil(XMLHelper.get_value(skylight, 'Area'))
      @azimuth = to_integer_or_nil(XMLHelper.get_value(skylight, 'Azimuth'))
      @orientation = XMLHelper.get_value(skylight, 'Orientation')
      @frame_type = XMLHelper.get_child_name(skylight, 'FrameType')
      @aluminum_thermal_break = to_bool_or_nil(XMLHelper.get_value(skylight, 'FrameType/Aluminum/ThermalBreak'))
      @glass_layers = XMLHelper.get_value(skylight, 'GlassLayers')
      @glass_type = XMLHelper.get_value(skylight, 'GlassType')
      @gas_fill = XMLHelper.get_value(skylight, 'GasFill')
      @ufactor = to_float_or_nil(XMLHelper.get_value(skylight, 'UFactor'))
      @shgc = to_float_or_nil(XMLHelper.get_value(skylight, 'SHGC'))
      @interior_shading_factor_summer = to_float_or_nil(XMLHelper.get_value(skylight, 'InteriorShading/SummerShadingCoefficient'))
      @interior_shading_factor_winter = to_float_or_nil(XMLHelper.get_value(skylight, 'InteriorShading/WinterShadingCoefficient'))
      @exterior_shading = XMLHelper.get_value(skylight, 'ExteriorShading/Type')
      @roof_idref = HPXML::get_idref(XMLHelper.get_element(skylight, 'AttachedToRoof'))
    end
  end

  class Doors < BaseArrayElement
    def add(**kwargs)
      self << Door.new(@hpxml_object, **kwargs)
    end

    def from_oga(hpxml)
      return if hpxml.nil?

      XMLHelper.get_elements(hpxml, 'Building/BuildingDetails/Enclosure/Doors/Door').each do |door|
        self << Door.new(@hpxml_object, door)
      end
    end
  end

  class Door < BaseElement
    ATTRS = [:id, :wall_idref, :area, :azimuth, :r_value]
    attr_accessor(*ATTRS)

    def wall
      return if @wall_idref.nil?

      (@hpxml_object.walls + @hpxml_object.foundation_walls).each do |wall|
        next unless wall.id == @wall_idref

        return wall
      end
      fail "Attached wall '#{@wall_idref}' not found for door '#{@id}'."
    end

    def is_exterior
      return wall.is_exterior
    end

    def is_interior
      return !is_exterior
    end

    def is_thermal_boundary
      HPXML::is_thermal_boundary(wall)
    end

    def is_exterior_thermal_boundary
      return (is_exterior && is_thermal_boundary)
    end

    def delete
      @hpxml_object.doors.delete(self)
    end

    def check_for_errors
      errors = []
      begin; wall; rescue StandardError => e; errors << e.message; end
      return errors
    end

    def to_oga(doc)
      return if nil?

      doors = XMLHelper.create_elements_as_needed(doc, ['HPXML', 'Building', 'BuildingDetails', 'Enclosure', 'Doors'])
      door = XMLHelper.add_element(doors, 'Door')
      sys_id = XMLHelper.add_element(door, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      if not @wall_idref.nil?
        attached_to_wall = XMLHelper.add_element(door, 'AttachedToWall')
        XMLHelper.add_attribute(attached_to_wall, 'idref', @wall_idref)
      end
      XMLHelper.add_element(door, 'Area', to_float(@area)) unless @area.nil?
      XMLHelper.add_element(door, 'Azimuth', to_integer(@azimuth)) unless @azimuth.nil?
      XMLHelper.add_element(door, 'RValue', to_float(@r_value)) unless @r_value.nil?
    end

    def from_oga(door)
      return if door.nil?

      @id = HPXML::get_id(door)
      @wall_idref = HPXML::get_idref(XMLHelper.get_element(door, 'AttachedToWall'))
      @area = to_float_or_nil(XMLHelper.get_value(door, 'Area'))
      @azimuth = to_integer_or_nil(XMLHelper.get_value(door, 'Azimuth'))
      @r_value = to_float_or_nil(XMLHelper.get_value(door, 'RValue'))
    end
  end

  class HeatingSystems < BaseArrayElement
    def add(**kwargs)
      self << HeatingSystem.new(@hpxml_object, **kwargs)
    end

    def from_oga(hpxml)
      return if hpxml.nil?

      XMLHelper.get_elements(hpxml, 'Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem').each do |heating_system|
        self << HeatingSystem.new(@hpxml_object, heating_system)
      end
    end
  end

  class HeatingSystem < BaseElement
    ATTRS = [:id, :distribution_system_idref, :year_installed, :heating_system_type,
             :heating_system_fuel, :heating_capacity, :heating_efficiency_afue,
             :heating_efficiency_percent, :fraction_heat_load_served, :electric_auxiliary_energy,
             :heating_cfm, :energy_star, :seed_id]
    attr_accessor(*ATTRS)

    def distribution_system
      return if @distribution_system_idref.nil?

      @hpxml_object.hvac_distributions.each do |hvac_distribution|
        next unless hvac_distribution.id == @distribution_system_idref

        return hvac_distribution
      end
      fail "Attached HVAC distribution system '#{@distribution_system_idref}' not found for HVAC system '#{@id}'."
    end

    def attached_cooling_system
      return if distribution_system.nil?

      distribution_system.hvac_systems.each do |hvac_system|
        next if hvac_system.id == @id

        return hvac_system
      end
      return
    end

    def delete
      @hpxml_object.heating_systems.delete(self)
      @hpxml_object.water_heating_systems.each do |water_heating_system|
        next unless water_heating_system.related_hvac_idref == @id

        water_heating_system.related_hvac_idref = nil
      end
    end

    def check_for_errors
      errors = []
      begin; distribution_system; rescue StandardError => e; errors << e.message; end
      return errors
    end

    def to_oga(doc)
      return if nil?

      hvac_plant = XMLHelper.create_elements_as_needed(doc, ['HPXML', 'Building', 'BuildingDetails', 'Systems', 'HVAC', 'HVACPlant'])
      heating_system = XMLHelper.add_element(hvac_plant, 'HeatingSystem')
      sys_id = XMLHelper.add_element(heating_system, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      if not @distribution_system_idref.nil?
        distribution_system = XMLHelper.add_element(heating_system, 'DistributionSystem')
        XMLHelper.add_attribute(distribution_system, 'idref', @distribution_system_idref)
      end
      if not @heating_system_type.nil?
        heating_system_type_e = XMLHelper.add_element(heating_system, 'HeatingSystemType')
        XMLHelper.add_element(heating_system_type_e, @heating_system_type)
      end
      XMLHelper.add_element(heating_system, 'HeatingSystemFuel', @heating_system_fuel) unless @heating_system_fuel.nil?
      XMLHelper.add_element(heating_system, 'HeatingCapacity', to_float(@heating_capacity)) unless @heating_capacity.nil?

      efficiency_units = nil
      efficiency_value = nil
      if [HVACTypeFurnace, HVACTypeWallFurnace, HVACTypeFloorFurnace, HVACTypeBoiler].include? @heating_system_type
        efficiency_units = 'AFUE'
        efficiency_value = @heating_efficiency_afue
      elsif [HVACTypeElectricResistance, HVACTypeStove, HVACTypePortableHeater, HVACTypeFireplace].include? @heating_system_type
        efficiency_units = UnitsPercent
        efficiency_value = @heating_efficiency_percent
      end
      if not efficiency_value.nil?
        annual_efficiency = XMLHelper.add_element(heating_system, 'AnnualHeatingEfficiency')
        XMLHelper.add_element(annual_efficiency, 'Units', efficiency_units)
        XMLHelper.add_element(annual_efficiency, 'Value', to_float(efficiency_value))
      end

      XMLHelper.add_element(heating_system, 'FractionHeatLoadServed', to_float(@fraction_heat_load_served)) unless @fraction_heat_load_served.nil?
      XMLHelper.add_element(heating_system, 'ElectricAuxiliaryEnergy', to_float(@electric_auxiliary_energy)) unless @electric_auxiliary_energy.nil?
      HPXML::add_extension(parent: heating_system,
                           extensions: { 'HeatingFlowRate' => to_float_or_nil(@heating_cfm),
                                         'SeedId' => @seed_id })
    end

    def from_oga(heating_system)
      return if heating_system.nil?

      @id = HPXML::get_id(heating_system)
      @distribution_system_idref = HPXML::get_idref(XMLHelper.get_element(heating_system, 'DistributionSystem'))
      @year_installed = to_integer_or_nil(XMLHelper.get_value(heating_system, 'YearInstalled'))
      @heating_system_type = XMLHelper.get_child_name(heating_system, 'HeatingSystemType')
      @heating_system_fuel = XMLHelper.get_value(heating_system, 'HeatingSystemFuel')
      @heating_capacity = to_float_or_nil(XMLHelper.get_value(heating_system, 'HeatingCapacity'))
      if [HVACTypeFurnace, HVACTypeWallFurnace, HVACTypeFloorFurnace, HVACTypeBoiler].include? @heating_system_type
        @heating_efficiency_afue = to_float_or_nil(XMLHelper.get_value(heating_system, "AnnualHeatingEfficiency[Units='AFUE']/Value"))
      elsif [HVACTypeElectricResistance, HVACTypeStove, HVACTypePortableHeater, HVACTypeFireplace].include? @heating_system_type
        @heating_efficiency_percent = to_float_or_nil(XMLHelper.get_value(heating_system, "AnnualHeatingEfficiency[Units='Percent']/Value"))
      end
      @fraction_heat_load_served = to_float_or_nil(XMLHelper.get_value(heating_system, 'FractionHeatLoadServed'))
      @electric_auxiliary_energy = to_float_or_nil(XMLHelper.get_value(heating_system, 'ElectricAuxiliaryEnergy'))
      @heating_cfm = to_float_or_nil(XMLHelper.get_value(heating_system, 'extension/HeatingFlowRate'))
      @energy_star = XMLHelper.get_values(heating_system, 'ThirdPartyCertification').include?('Energy Star')
      @seed_id = XMLHelper.get_value(heating_system, 'extension/SeedId')
    end
  end

  class CoolingSystems < BaseArrayElement
    def add(**kwargs)
      self << CoolingSystem.new(@hpxml_object, **kwargs)
    end

    def from_oga(hpxml)
      return if hpxml.nil?

      XMLHelper.get_elements(hpxml, 'Building/BuildingDetails/Systems/HVAC/HVACPlant/CoolingSystem').each do |cooling_system|
        self << CoolingSystem.new(@hpxml_object, cooling_system)
      end
    end
  end

  class CoolingSystem < BaseElement
    ATTRS = [:id, :distribution_system_idref, :year_installed, :cooling_system_type,
             :cooling_system_fuel, :cooling_capacity, :compressor_type, :fraction_cool_load_served,
             :cooling_efficiency_seer, :cooling_efficiency_eer, :cooling_shr, :cooling_cfm,
             :energy_star, :seed_id]
    attr_accessor(*ATTRS)

    def distribution_system
      return if @distribution_system_idref.nil?

      @hpxml_object.hvac_distributions.each do |hvac_distribution|
        next unless hvac_distribution.id == @distribution_system_idref

        return hvac_distribution
      end
      fail "Attached HVAC distribution system '#{@distribution_system_idref}' not found for HVAC system '#{@id}'."
    end

    def attached_heating_system
      return if distribution_system.nil?

      distribution_system.hvac_systems.each do |hvac_system|
        next if hvac_system.id == @id

        return hvac_system
      end
      return
    end

    def delete
      @hpxml_object.cooling_systems.delete(self)
      @hpxml_object.water_heating_systems.each do |water_heating_system|
        next unless water_heating_system.related_hvac_idref == @id

        water_heating_system.related_hvac_idref = nil
      end
    end

    def check_for_errors
      errors = []
      begin; distribution_system; rescue StandardError => e; errors << e.message; end
      return errors
    end

    def to_oga(doc)
      return if nil?

      hvac_plant = XMLHelper.create_elements_as_needed(doc, ['HPXML', 'Building', 'BuildingDetails', 'Systems', 'HVAC', 'HVACPlant'])
      cooling_system = XMLHelper.add_element(hvac_plant, 'CoolingSystem')
      sys_id = XMLHelper.add_element(cooling_system, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      if not @distribution_system_idref.nil?
        distribution_system = XMLHelper.add_element(cooling_system, 'DistributionSystem')
        XMLHelper.add_attribute(distribution_system, 'idref', @distribution_system_idref)
      end
      XMLHelper.add_element(cooling_system, 'CoolingSystemType', @cooling_system_type) unless @cooling_system_type.nil?
      XMLHelper.add_element(cooling_system, 'CoolingSystemFuel', @cooling_system_fuel) unless @cooling_system_fuel.nil?
      XMLHelper.add_element(cooling_system, 'CoolingCapacity', to_float(@cooling_capacity)) unless @cooling_capacity.nil?
      XMLHelper.add_element(cooling_system, 'CompressorType', @compressor_type) unless @compressor_type.nil?
      XMLHelper.add_element(cooling_system, 'FractionCoolLoadServed', to_float(@fraction_cool_load_served)) unless @fraction_cool_load_served.nil?

      efficiency_units = nil
      efficiency_value = nil
      if [HVACTypeCentralAirConditioner].include? @cooling_system_type
        efficiency_units = 'SEER'
        efficiency_value = @cooling_efficiency_seer
      elsif [HVACTypeRoomAirConditioner].include? @cooling_system_type
        efficiency_units = 'EER'
        efficiency_value = @cooling_efficiency_eer
      end
      if not efficiency_value.nil?
        annual_efficiency = XMLHelper.add_element(cooling_system, 'AnnualCoolingEfficiency')
        XMLHelper.add_element(annual_efficiency, 'Units', efficiency_units)
        XMLHelper.add_element(annual_efficiency, 'Value', to_float(efficiency_value))
      end

      XMLHelper.add_element(cooling_system, 'SensibleHeatFraction', to_float(@cooling_shr)) unless @cooling_shr.nil?
      HPXML::add_extension(parent: cooling_system,
                           extensions: { 'CoolingFlowRate' => to_float_or_nil(@cooling_cfm),
                                         'SeedId' => @seed_id })
    end

    def from_oga(cooling_system)
      return if cooling_system.nil?

      @id = HPXML::get_id(cooling_system)
      @distribution_system_idref = HPXML::get_idref(XMLHelper.get_element(cooling_system, 'DistributionSystem'))
      @year_installed = to_integer_or_nil(XMLHelper.get_value(cooling_system, 'YearInstalled'))
      @cooling_system_type = XMLHelper.get_value(cooling_system, 'CoolingSystemType')
      @cooling_system_fuel = XMLHelper.get_value(cooling_system, 'CoolingSystemFuel')
      @cooling_capacity = to_float_or_nil(XMLHelper.get_value(cooling_system, 'CoolingCapacity'))
      @compressor_type = XMLHelper.get_value(cooling_system, 'CompressorType')
      @fraction_cool_load_served = to_float_or_nil(XMLHelper.get_value(cooling_system, 'FractionCoolLoadServed'))
      if [HVACTypeCentralAirConditioner].include? @cooling_system_type
        @cooling_efficiency_seer = to_float_or_nil(XMLHelper.get_value(cooling_system, "AnnualCoolingEfficiency[Units='SEER']/Value"))
      elsif [HVACTypeRoomAirConditioner].include? @cooling_system_type
        @cooling_efficiency_eer = to_float_or_nil(XMLHelper.get_value(cooling_system, "AnnualCoolingEfficiency[Units='EER']/Value"))
      end
      @cooling_shr = to_float_or_nil(XMLHelper.get_value(cooling_system, 'SensibleHeatFraction'))
      @cooling_cfm = to_float_or_nil(XMLHelper.get_value(cooling_system, 'extension/CoolingFlowRate'))
      @energy_star = XMLHelper.get_values(cooling_system, 'ThirdPartyCertification').include?('Energy Star')
      @seed_id = XMLHelper.get_value(cooling_system, 'extension/SeedId')
    end
  end

  class HeatPumps < BaseArrayElement
    def add(**kwargs)
      self << HeatPump.new(@hpxml_object, **kwargs)
    end

    def from_oga(hpxml)
      return if hpxml.nil?

      XMLHelper.get_elements(hpxml, 'Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatPump').each do |heat_pump|
        self << HeatPump.new(@hpxml_object, heat_pump)
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

    def distribution_system
      return if @distribution_system_idref.nil?

      @hpxml_object.hvac_distributions.each do |hvac_distribution|
        next unless hvac_distribution.id == @distribution_system_idref

        return hvac_distribution
      end
      fail "Attached HVAC distribution system '#{@distribution_system_idref}' not found for HVAC system '#{@id}'."
    end

    def delete
      @hpxml_object.heat_pumps.delete(self)
      @hpxml_object.water_heating_systems.each do |water_heating_system|
        next unless water_heating_system.related_hvac_idref == @id

        water_heating_system.related_hvac_idref = nil
      end
    end

    def check_for_errors
      errors = []
      begin; distribution_system; rescue StandardError => e; errors << e.message; end
      return errors
    end

    def to_oga(doc)
      return if nil?

      hvac_plant = XMLHelper.create_elements_as_needed(doc, ['HPXML', 'Building', 'BuildingDetails', 'Systems', 'HVAC', 'HVACPlant'])
      heat_pump = XMLHelper.add_element(hvac_plant, 'HeatPump')
      sys_id = XMLHelper.add_element(heat_pump, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      if not @distribution_system_idref.nil?
        distribution_system = XMLHelper.add_element(heat_pump, 'DistributionSystem')
        XMLHelper.add_attribute(distribution_system, 'idref', @distribution_system_idref)
      end
      XMLHelper.add_element(heat_pump, 'HeatPumpType', @heat_pump_type) unless @heat_pump_type.nil?
      XMLHelper.add_element(heat_pump, 'HeatPumpFuel', @heat_pump_fuel) unless @heat_pump_fuel.nil?
      XMLHelper.add_element(heat_pump, 'HeatingCapacity', to_float(@heating_capacity)) unless @heating_capacity.nil?
      XMLHelper.add_element(heat_pump, 'HeatingCapacity17F', to_float(@heating_capacity_17F)) unless @heating_capacity_17F.nil?
      XMLHelper.add_element(heat_pump, 'CoolingCapacity', to_float(@cooling_capacity)) unless @cooling_capacity.nil?
      XMLHelper.add_element(heat_pump, 'CompressorType', @compressor_type) unless @compressor_type.nil?
      XMLHelper.add_element(heat_pump, 'CoolingSensibleHeatFraction', to_float(@cooling_shr)) unless @cooling_shr.nil?
      if not @backup_heating_fuel.nil?
        XMLHelper.add_element(heat_pump, 'BackupSystemFuel', @backup_heating_fuel)
        efficiencies = { 'Percent' => @backup_heating_efficiency_percent,
                         'AFUE' => @backup_heating_efficiency_afue }
        efficiencies.each do |units, value|
          next if value.nil?

          backup_eff = XMLHelper.add_element(heat_pump, 'BackupAnnualHeatingEfficiency')
          XMLHelper.add_element(backup_eff, 'Units', units)
          XMLHelper.add_element(backup_eff, 'Value', to_float(value))
        end
        XMLHelper.add_element(heat_pump, 'BackupHeatingCapacity', to_float(@backup_heating_capacity)) unless @backup_heating_capacity.nil?
        XMLHelper.add_element(heat_pump, 'BackupHeatingSwitchoverTemperature', to_float(@backup_heating_switchover_temp)) unless @backup_heating_switchover_temp.nil?
      end
      XMLHelper.add_element(heat_pump, 'FractionHeatLoadServed', to_float(@fraction_heat_load_served)) unless @fraction_heat_load_served.nil?
      XMLHelper.add_element(heat_pump, 'FractionCoolLoadServed', to_float(@fraction_cool_load_served)) unless @fraction_cool_load_served.nil?

      clg_efficiency_units = nil
      clg_efficiency_value = nil
      htg_efficiency_units = nil
      htg_efficiency_value = nil
      if [HVACTypeHeatPumpAirToAir, HVACTypeHeatPumpMiniSplit].include? @heat_pump_type
        clg_efficiency_units = 'SEER'
        clg_efficiency_value = @cooling_efficiency_seer
        htg_efficiency_units = 'HSPF'
        htg_efficiency_value = @heating_efficiency_hspf
      elsif [HVACTypeHeatPumpGroundToAir].include? @heat_pump_type
        clg_efficiency_units = 'EER'
        clg_efficiency_value = @cooling_efficiency_eer
        htg_efficiency_units = 'COP'
        htg_efficiency_value = @heating_efficiency_cop
      end
      if not clg_efficiency_value.nil?
        annual_efficiency = XMLHelper.add_element(heat_pump, 'AnnualCoolingEfficiency')
        XMLHelper.add_element(annual_efficiency, 'Units', clg_efficiency_units)
        XMLHelper.add_element(annual_efficiency, 'Value', to_float(clg_efficiency_value))
      end
      if not htg_efficiency_value.nil?
        annual_efficiency = XMLHelper.add_element(heat_pump, 'AnnualHeatingEfficiency')
        XMLHelper.add_element(annual_efficiency, 'Units', htg_efficiency_units)
        XMLHelper.add_element(annual_efficiency, 'Value', to_float(htg_efficiency_value))
      end

      HPXML::add_extension(parent: heat_pump,
                           extensions: { 'SeedId' => @seed_id })
    end

    def from_oga(heat_pump)
      return if heat_pump.nil?

      @id = HPXML::get_id(heat_pump)
      @distribution_system_idref = HPXML::get_idref(XMLHelper.get_element(heat_pump, 'DistributionSystem'))
      @year_installed = to_integer_or_nil(XMLHelper.get_value(heat_pump, 'YearInstalled'))
      @heat_pump_type = XMLHelper.get_value(heat_pump, 'HeatPumpType')
      @heat_pump_fuel = XMLHelper.get_value(heat_pump, 'HeatPumpFuel')
      @heating_capacity = to_float_or_nil(XMLHelper.get_value(heat_pump, 'HeatingCapacity'))
      @heating_capacity_17F = to_float_or_nil(XMLHelper.get_value(heat_pump, 'HeatingCapacity17F'))
      @cooling_capacity = to_float_or_nil(XMLHelper.get_value(heat_pump, 'CoolingCapacity'))
      @compressor_type = XMLHelper.get_value(heat_pump, 'CompressorType')
      @cooling_shr = to_float_or_nil(XMLHelper.get_value(heat_pump, 'CoolingSensibleHeatFraction'))
      @backup_heating_fuel = XMLHelper.get_value(heat_pump, 'BackupSystemFuel')
      @backup_heating_capacity = to_float_or_nil(XMLHelper.get_value(heat_pump, 'BackupHeatingCapacity'))
      @backup_heating_efficiency_percent = to_float_or_nil(XMLHelper.get_value(heat_pump, "BackupAnnualHeatingEfficiency[Units='Percent']/Value"))
      @backup_heating_efficiency_afue = to_float_or_nil(XMLHelper.get_value(heat_pump, "BackupAnnualHeatingEfficiency[Units='AFUE']/Value"))
      @backup_heating_switchover_temp = to_float_or_nil(XMLHelper.get_value(heat_pump, 'BackupHeatingSwitchoverTemperature'))
      @fraction_heat_load_served = to_float_or_nil(XMLHelper.get_value(heat_pump, 'FractionHeatLoadServed'))
      @fraction_cool_load_served = to_float_or_nil(XMLHelper.get_value(heat_pump, 'FractionCoolLoadServed'))
      if [HVACTypeHeatPumpAirToAir, HVACTypeHeatPumpMiniSplit].include? @heat_pump_type
        @cooling_efficiency_seer = to_float_or_nil(XMLHelper.get_value(heat_pump, "AnnualCoolingEfficiency[Units='SEER']/Value"))
      elsif [HVACTypeHeatPumpGroundToAir].include? @heat_pump_type
        @cooling_efficiency_eer = to_float_or_nil(XMLHelper.get_value(heat_pump, "AnnualCoolingEfficiency[Units='EER']/Value"))
      end
      if [HVACTypeHeatPumpAirToAir, HVACTypeHeatPumpMiniSplit].include? @heat_pump_type
        @heating_efficiency_hspf = to_float_or_nil(XMLHelper.get_value(heat_pump, "AnnualHeatingEfficiency[Units='HSPF']/Value"))
      elsif [HVACTypeHeatPumpGroundToAir].include? @heat_pump_type
        @heating_efficiency_cop = to_float_or_nil(XMLHelper.get_value(heat_pump, "AnnualHeatingEfficiency[Units='COP']/Value"))
      end
      @energy_star = XMLHelper.get_values(heat_pump, 'ThirdPartyCertification').include?('Energy Star')
      @seed_id = XMLHelper.get_value(heat_pump, 'extension/SeedId')
    end
  end

  class HVACControls < BaseArrayElement
    def add(**kwargs)
      self << HVACControl.new(@hpxml_object, **kwargs)
    end

    def from_oga(hpxml)
      return if hpxml.nil?

      XMLHelper.get_elements(hpxml, 'Building/BuildingDetails/Systems/HVAC/HVACControl').each do |hvac_control|
        self << HVACControl.new(@hpxml_object, hvac_control)
      end
    end
  end

  class HVACControl < BaseElement
    ATTRS = [:id, :control_type, :heating_setpoint_temp, :heating_setback_temp,
             :heating_setback_hours_per_week, :heating_setback_start_hour, :cooling_setpoint_temp,
             :cooling_setup_temp, :cooling_setup_hours_per_week, :cooling_setup_start_hour,
             :ceiling_fan_cooling_setpoint_temp_offset]
    attr_accessor(*ATTRS)

    def delete
      @hpxml_object.hvac_controls.delete(self)
    end

    def check_for_errors
      errors = []
      return errors
    end

    def to_oga(doc)
      return if nil?

      hvac = XMLHelper.create_elements_as_needed(doc, ['HPXML', 'Building', 'BuildingDetails', 'Systems', 'HVAC'])
      hvac_control = XMLHelper.add_element(hvac, 'HVACControl')
      sys_id = XMLHelper.add_element(hvac_control, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_element(hvac_control, 'ControlType', @control_type) unless @control_type.nil?
      XMLHelper.add_element(hvac_control, 'SetpointTempHeatingSeason', to_float(@heating_setpoint_temp)) unless @heating_setpoint_temp.nil?
      XMLHelper.add_element(hvac_control, 'SetbackTempHeatingSeason', to_float(@heating_setback_temp)) unless @heating_setback_temp.nil?
      XMLHelper.add_element(hvac_control, 'TotalSetbackHoursperWeekHeating', to_integer(@heating_setback_hours_per_week)) unless @heating_setback_hours_per_week.nil?
      XMLHelper.add_element(hvac_control, 'SetupTempCoolingSeason', to_float(@cooling_setup_temp)) unless @cooling_setup_temp.nil?
      XMLHelper.add_element(hvac_control, 'SetpointTempCoolingSeason', to_float(@cooling_setpoint_temp)) unless @cooling_setpoint_temp.nil?
      XMLHelper.add_element(hvac_control, 'TotalSetupHoursperWeekCooling', to_integer(@cooling_setup_hours_per_week)) unless @cooling_setup_hours_per_week.nil?
      HPXML::add_extension(parent: hvac_control,
                           extensions: { 'SetbackStartHourHeating' => to_integer_or_nil(@heating_setback_start_hour),
                                         'SetupStartHourCooling' => to_integer_or_nil(@cooling_setup_start_hour),
                                         'CeilingFanSetpointTempCoolingSeasonOffset' => to_float_or_nil(@ceiling_fan_cooling_setpoint_temp_offset) })
    end

    def from_oga(hvac_control)
      return if hvac_control.nil?

      @id = HPXML::get_id(hvac_control)
      @control_type = XMLHelper.get_value(hvac_control, 'ControlType')
      @heating_setpoint_temp = to_float_or_nil(XMLHelper.get_value(hvac_control, 'SetpointTempHeatingSeason'))
      @heating_setback_temp = to_float_or_nil(XMLHelper.get_value(hvac_control, 'SetbackTempHeatingSeason'))
      @heating_setback_hours_per_week = to_integer_or_nil(XMLHelper.get_value(hvac_control, 'TotalSetbackHoursperWeekHeating'))
      @heating_setback_start_hour = to_integer_or_nil(XMLHelper.get_value(hvac_control, 'extension/SetbackStartHourHeating'))
      @cooling_setpoint_temp = to_float_or_nil(XMLHelper.get_value(hvac_control, 'SetpointTempCoolingSeason'))
      @cooling_setup_temp = to_float_or_nil(XMLHelper.get_value(hvac_control, 'SetupTempCoolingSeason'))
      @cooling_setup_hours_per_week = to_integer_or_nil(XMLHelper.get_value(hvac_control, 'TotalSetupHoursperWeekCooling'))
      @cooling_setup_start_hour = to_integer_or_nil(XMLHelper.get_value(hvac_control, 'extension/SetupStartHourCooling'))
      @ceiling_fan_cooling_setpoint_temp_offset = to_float_or_nil(XMLHelper.get_value(hvac_control, 'extension/CeilingFanSetpointTempCoolingSeasonOffset'))
    end
  end

  class HVACDistributions < BaseArrayElement
    def add(**kwargs)
      self << HVACDistribution.new(@hpxml_object, **kwargs)
    end

    def from_oga(hpxml)
      return if hpxml.nil?

      XMLHelper.get_elements(hpxml, 'Building/BuildingDetails/Systems/HVAC/HVACDistribution').each do |hvac_distribution|
        self << HVACDistribution.new(@hpxml_object, hvac_distribution)
      end
    end
  end

  class HVACDistribution < BaseElement
    def initialize(hpxml_object, *args)
      @duct_leakage_measurements = DuctLeakageMeasurements.new(hpxml_object)
      @ducts = Ducts.new(hpxml_object)
      super(hpxml_object, *args)
    end
    ATTRS = [:id, :distribution_system_type, :annual_heating_dse,
             :annual_cooling_dse, :duct_system_sealed, :duct_leakage_testing_exemption,
             :conditioned_floor_area_served, :number_of_return_registers]
    attr_accessor(*ATTRS)
    attr_reader(:duct_leakage_measurements, :ducts)

    def hvac_systems
      list = []
      (@hpxml_object.heating_systems + @hpxml_object.cooling_systems + @hpxml_object.heat_pumps).each do |hvac_system|
        next if hvac_system.distribution_system_idref.nil?
        next unless hvac_system.distribution_system_idref == @id

        list << hvac_system
      end

      if list.size == 0
        fail "Distribution system '#{@id}' found but no HVAC system attached to it."
      end

      num_htg = 0
      num_clg = 0
      list.each do |obj|
        if obj.respond_to? :fraction_heat_load_served
          num_htg += 1 if obj.fraction_heat_load_served > 0
        end
        if obj.respond_to? :fraction_cool_load_served
          num_clg += 1 if obj.fraction_cool_load_served > 0
        end
      end

      if num_clg > 1
        fail "Multiple cooling systems found attached to distribution system '#{@id}'."
      end
      if num_htg > 1
        fail "Multiple heating systems found attached to distribution system '#{@id}'."
      end

      return list
    end

    def delete
      @hpxml_object.hvac_distributions.delete(self)
      (@hpxml_object.heating_systems + @hpxml_object.cooling_systems + @hpxml_object.heat_pumps).each do |hvac|
        next unless hvac.distribution_system_idref == @id

        hvac.distribution_system_idref = nil
      end
      @hpxml_object.ventilation_fans.each do |ventilation_fan|
        next unless ventilation_fan.distribution_system_idref == @id

        ventilation_fan.distribution_system_idref = nil
      end
    end

    def check_for_errors
      errors = []
      begin; hvac_systems; rescue StandardError => e; errors << e.message; end
      errors += @duct_leakage_measurements.check_for_errors
      errors += @ducts.check_for_errors
      return errors
    end

    def to_oga(doc)
      return if nil?

      hvac = XMLHelper.create_elements_as_needed(doc, ['HPXML', 'Building', 'BuildingDetails', 'Systems', 'HVAC'])
      hvac_distribution = XMLHelper.add_element(hvac, 'HVACDistribution')
      sys_id = XMLHelper.add_element(hvac_distribution, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      distribution_system_type_e = XMLHelper.add_element(hvac_distribution, 'DistributionSystemType')
      if [HVACDistributionTypeAir, HVACDistributionTypeHydronic].include? @distribution_system_type
        XMLHelper.add_element(distribution_system_type_e, @distribution_system_type)
        XMLHelper.add_element(hvac_distribution, 'ConditionedFloorAreaServed', Float(@conditioned_floor_area_served)) unless @conditioned_floor_area_served.nil?
      elsif [HVACDistributionTypeDSE].include? @distribution_system_type
        XMLHelper.add_element(distribution_system_type_e, 'Other', @distribution_system_type)
        XMLHelper.add_element(hvac_distribution, 'AnnualHeatingDistributionSystemEfficiency', to_float(@annual_heating_dse)) unless @annual_heating_dse.nil?
        XMLHelper.add_element(hvac_distribution, 'AnnualCoolingDistributionSystemEfficiency', to_float(@annual_cooling_dse)) unless @annual_cooling_dse.nil?
      else
        fail "Unexpected distribution_system_type '#{@distribution_system_type}'."
      end

      air_distribution = XMLHelper.get_element(hvac_distribution, 'DistributionSystemType/AirDistribution')
      return if air_distribution.nil?

      @duct_leakage_measurements.to_oga(air_distribution)
      @ducts.to_oga(air_distribution)
      XMLHelper.add_element(air_distribution, 'NumberofReturnRegisters', Integer(@number_of_return_registers)) unless @number_of_return_registers.nil?

      HPXML::add_extension(parent: air_distribution,
                           extensions: { 'DuctLeakageTestingExemption' => to_bool_or_nil(@duct_leakage_testing_exemption) })
    end

    def from_oga(hvac_distribution)
      return if hvac_distribution.nil?

      @id = HPXML::get_id(hvac_distribution)
      @distribution_system_type = XMLHelper.get_child_name(hvac_distribution, 'DistributionSystemType')
      if @distribution_system_type == 'Other'
        @distribution_system_type = XMLHelper.get_value(XMLHelper.get_element(hvac_distribution, 'DistributionSystemType'), 'Other')
      end
      @annual_heating_dse = to_float_or_nil(XMLHelper.get_value(hvac_distribution, 'AnnualHeatingDistributionSystemEfficiency'))
      @annual_cooling_dse = to_float_or_nil(XMLHelper.get_value(hvac_distribution, 'AnnualCoolingDistributionSystemEfficiency'))
      @duct_system_sealed = to_bool_or_nil(XMLHelper.get_value(hvac_distribution, 'HVACDistributionImprovement/DuctSystemSealed'))
      @conditioned_floor_area_served = to_float_or_nil(XMLHelper.get_value(hvac_distribution, 'ConditionedFloorAreaServed'))
      @number_of_return_registers = to_integer_or_nil(XMLHelper.get_value(hvac_distribution, 'DistributionSystemType/AirDistribution/NumberofReturnRegisters'))
      @duct_leakage_testing_exemption = to_bool_or_nil(XMLHelper.get_value(hvac_distribution, 'DistributionSystemType/AirDistribution/extension/DuctLeakageTestingExemption'))

      @duct_leakage_measurements.from_oga(hvac_distribution)
      @ducts.from_oga(hvac_distribution)
    end
  end

  class DuctLeakageMeasurements < BaseArrayElement
    def add(**kwargs)
      self << DuctLeakageMeasurement.new(@hpxml_object, **kwargs)
    end

    def from_oga(hvac_distribution)
      return if hvac_distribution.nil?

      XMLHelper.get_elements(hvac_distribution, 'DistributionSystemType/AirDistribution/DuctLeakageMeasurement').each do |duct_leakage_measurement|
        self << DuctLeakageMeasurement.new(@hpxml_object, duct_leakage_measurement)
      end
    end
  end

  class DuctLeakageMeasurement < BaseElement
    ATTRS = [:duct_type, :duct_leakage_test_method, :duct_leakage_units, :duct_leakage_value,
             :duct_leakage_total_or_to_outside]
    attr_accessor(*ATTRS)

    def delete
      @hpxml_object.hvac_distributions.each do |hvac_distribution|
        next unless hvac_distribution.duct_leakage_measurements.include? self

        hvac_distribution.duct_leakage_measurements.delete(self)
      end
    end

    def check_for_errors
      errors = []
      return errors
    end

    def to_oga(air_distribution)
      duct_leakage_measurement_el = XMLHelper.add_element(air_distribution, 'DuctLeakageMeasurement')
      XMLHelper.add_element(duct_leakage_measurement_el, 'DuctType', @duct_type) unless @duct_type.nil?
      if not @duct_leakage_value.nil?
        duct_leakage_el = XMLHelper.add_element(duct_leakage_measurement_el, 'DuctLeakage')
        XMLHelper.add_element(duct_leakage_el, 'Units', @duct_leakage_units) unless @duct_leakage_units.nil?
        XMLHelper.add_element(duct_leakage_el, 'Value', to_float(@duct_leakage_value))
        XMLHelper.add_element(duct_leakage_el, 'TotalOrToOutside', @duct_leakage_total_or_to_outside) unless @duct_leakage_total_or_to_outside.nil?
      end
    end

    def from_oga(duct_leakage_measurement)
      return if duct_leakage_measurement.nil?

      @duct_type = XMLHelper.get_value(duct_leakage_measurement, 'DuctType')
      @duct_leakage_test_method = XMLHelper.get_value(duct_leakage_measurement, 'DuctLeakageTestMethod')
      @duct_leakage_units = XMLHelper.get_value(duct_leakage_measurement, 'DuctLeakage/Units')
      @duct_leakage_value = to_float_or_nil(XMLHelper.get_value(duct_leakage_measurement, 'DuctLeakage/Value'))
      @duct_leakage_total_or_to_outside = XMLHelper.get_value(duct_leakage_measurement, 'DuctLeakage/TotalOrToOutside')
    end
  end

  class Ducts < BaseArrayElement
    def add(**kwargs)
      self << Duct.new(@hpxml_object, **kwargs)
    end

    def from_oga(hvac_distribution)
      return if hvac_distribution.nil?

      XMLHelper.get_elements(hvac_distribution, 'DistributionSystemType/AirDistribution/Ducts').each do |duct|
        self << Duct.new(@hpxml_object, duct)
      end
    end
  end

  class Duct < BaseElement
    ATTRS = [:duct_type, :duct_insulation_r_value, :duct_insulation_material, :duct_location,
             :duct_fraction_area, :duct_surface_area]
    attr_accessor(*ATTRS)

    def delete
      @hpxml_object.hvac_distributions.each do |hvac_distribution|
        next unless hvac_distribution.ducts.include? self

        hvac_distribution.ducts.delete(self)
      end
    end

    def check_for_errors
      errors = []
      return errors
    end

    def to_oga(air_distribution)
      ducts_el = XMLHelper.add_element(air_distribution, 'Ducts')
      XMLHelper.add_element(ducts_el, 'DuctType', @duct_type) unless @duct_type.nil?
      XMLHelper.add_element(ducts_el, 'DuctInsulationRValue', to_float(@duct_insulation_r_value)) unless @duct_insulation_r_value.nil?
      XMLHelper.add_element(ducts_el, 'DuctLocation', @duct_location) unless @duct_location.nil?
      XMLHelper.add_element(ducts_el, 'DuctSurfaceArea', to_float(@duct_surface_area)) unless @duct_surface_area.nil?
    end

    def from_oga(duct)
      return if duct.nil?

      @duct_type = XMLHelper.get_value(duct, 'DuctType')
      @duct_insulation_r_value = to_float_or_nil(XMLHelper.get_value(duct, 'DuctInsulationRValue'))
      @duct_insulation_material = XMLHelper.get_child_name(duct, 'DuctInsulationMaterial')
      @duct_location = XMLHelper.get_value(duct, 'DuctLocation')
      @duct_fraction_area = to_float_or_nil(XMLHelper.get_value(duct, 'FractionDuctArea'))
      @duct_surface_area = to_float_or_nil(XMLHelper.get_value(duct, 'DuctSurfaceArea'))
    end
  end

  class VentilationFans < BaseArrayElement
    def add(**kwargs)
      self << VentilationFan.new(@hpxml_object, **kwargs)
    end

    def from_oga(hpxml)
      return if hpxml.nil?

      XMLHelper.get_elements(hpxml, 'Building/BuildingDetails/Systems/MechanicalVentilation/VentilationFans/VentilationFan').each do |ventilation_fan|
        self << VentilationFan.new(@hpxml_object, ventilation_fan)
      end
    end
  end

  class VentilationFan < BaseElement
    ATTRS = [:id, :fan_type, :rated_flow_rate, :tested_flow_rate, :hours_in_operation,
             :used_for_whole_building_ventilation, :used_for_seasonal_cooling_load_reduction,
             :used_for_local_ventilation, :total_recovery_efficiency, :total_recovery_efficiency_adjusted,
             :sensible_recovery_efficiency, :sensible_recovery_efficiency_adjusted,
             :fan_power, :quantity, :fan_location, :distribution_system_idref, :start_hour]
    attr_accessor(*ATTRS)

    def distribution_system
      return if @distribution_system_idref.nil?
      return unless @fan_type == MechVentTypeCFIS

      @hpxml_object.hvac_distributions.each do |hvac_distribution|
        next unless hvac_distribution.id == @distribution_system_idref

        if hvac_distribution.distribution_system_type == HVACDistributionTypeHydronic
          fail "Attached HVAC distribution system '#{@distribution_system_idref}' cannot be hydronic for ventilation fan '#{@id}'."
        end

        return hvac_distribution
      end
      fail "Attached HVAC distribution system '#{@distribution_system_idref}' not found for ventilation fan '#{@id}'."
    end

    def delete
      @hpxml_object.ventilation_fans.delete(self)
    end

    def check_for_errors
      errors = []
      begin; distribution_system; rescue StandardError => e; errors << e.message; end
      return errors
    end

    def to_oga(doc)
      return if nil?

      ventilation_fans = XMLHelper.create_elements_as_needed(doc, ['HPXML', 'Building', 'BuildingDetails', 'Systems', 'MechanicalVentilation', 'VentilationFans'])
      ventilation_fan = XMLHelper.add_element(ventilation_fans, 'VentilationFan')
      sys_id = XMLHelper.add_element(ventilation_fan, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_element(ventilation_fan, 'Quantity', to_integer(@quantity)) unless @quantity.nil?
      XMLHelper.add_element(ventilation_fan, 'FanType', @fan_type) unless @fan_type.nil?
      XMLHelper.add_element(ventilation_fan, 'RatedFlowRate', to_float(@rated_flow_rate)) unless @rated_flow_rate.nil?
      XMLHelper.add_element(ventilation_fan, 'TestedFlowRate', to_float(@tested_flow_rate)) unless @tested_flow_rate.nil?
      XMLHelper.add_element(ventilation_fan, 'HoursInOperation', to_float(@hours_in_operation)) unless @hours_in_operation.nil?
      XMLHelper.add_element(ventilation_fan, 'FanLocation', @fan_location) unless @fan_location.nil?
      XMLHelper.add_element(ventilation_fan, 'UsedForLocalVentilation', to_boolean(@used_for_local_ventilation)) unless @used_for_local_ventilation.nil?
      XMLHelper.add_element(ventilation_fan, 'UsedForWholeBuildingVentilation', to_boolean(@used_for_whole_building_ventilation)) unless @used_for_whole_building_ventilation.nil?
      XMLHelper.add_element(ventilation_fan, 'UsedForSeasonalCoolingLoadReduction', to_boolean(@used_for_seasonal_cooling_load_reduction)) unless @used_for_seasonal_cooling_load_reduction.nil?
      XMLHelper.add_element(ventilation_fan, 'TotalRecoveryEfficiency', to_float(@total_recovery_efficiency)) unless @total_recovery_efficiency.nil?
      XMLHelper.add_element(ventilation_fan, 'SensibleRecoveryEfficiency', to_float(@sensible_recovery_efficiency)) unless @sensible_recovery_efficiency.nil?
      XMLHelper.add_element(ventilation_fan, 'AdjustedTotalRecoveryEfficiency', to_float(@total_recovery_efficiency_adjusted)) unless @total_recovery_efficiency_adjusted.nil?
      XMLHelper.add_element(ventilation_fan, 'AdjustedSensibleRecoveryEfficiency', to_float(@sensible_recovery_efficiency_adjusted)) unless @sensible_recovery_efficiency_adjusted.nil?
      XMLHelper.add_element(ventilation_fan, 'FanPower', to_float(@fan_power)) unless @fan_power.nil?
      if not @distribution_system_idref.nil?
        attached_to_hvac_distribution_system = XMLHelper.add_element(ventilation_fan, 'AttachedToHVACDistributionSystem')
        XMLHelper.add_attribute(attached_to_hvac_distribution_system, 'idref', @distribution_system_idref)
      end
      HPXML::add_extension(parent: ventilation_fan,
                           extensions: { 'StartHour' => to_integer_or_nil(@start_hour) })
    end

    def from_oga(ventilation_fan)
      return if ventilation_fan.nil?

      @id = HPXML::get_id(ventilation_fan)
      @quantity = to_integer_or_nil(XMLHelper.get_value(ventilation_fan, 'Quantity'))
      @fan_type = XMLHelper.get_value(ventilation_fan, 'FanType')
      @rated_flow_rate = to_float_or_nil(XMLHelper.get_value(ventilation_fan, 'RatedFlowRate'))
      @tested_flow_rate = to_float_or_nil(XMLHelper.get_value(ventilation_fan, 'TestedFlowRate'))
      @hours_in_operation = to_float_or_nil(XMLHelper.get_value(ventilation_fan, 'HoursInOperation'))
      @fan_location = XMLHelper.get_value(ventilation_fan, 'FanLocation')
      @used_for_local_ventilation = to_bool_or_nil(XMLHelper.get_value(ventilation_fan, 'UsedForLocalVentilation'))
      @used_for_whole_building_ventilation = to_bool_or_nil(XMLHelper.get_value(ventilation_fan, 'UsedForWholeBuildingVentilation'))
      @used_for_seasonal_cooling_load_reduction = to_bool_or_nil(XMLHelper.get_value(ventilation_fan, 'UsedForSeasonalCoolingLoadReduction'))
      @total_recovery_efficiency = to_float_or_nil(XMLHelper.get_value(ventilation_fan, 'TotalRecoveryEfficiency'))
      @total_recovery_efficiency_adjusted = to_float_or_nil(XMLHelper.get_value(ventilation_fan, 'AdjustedTotalRecoveryEfficiency'))
      @sensible_recovery_efficiency = to_float_or_nil(XMLHelper.get_value(ventilation_fan, 'SensibleRecoveryEfficiency'))
      @sensible_recovery_efficiency_adjusted = to_float_or_nil(XMLHelper.get_value(ventilation_fan, 'AdjustedSensibleRecoveryEfficiency'))
      @fan_power = to_float_or_nil(XMLHelper.get_value(ventilation_fan, 'FanPower'))
      @distribution_system_idref = HPXML::get_idref(XMLHelper.get_element(ventilation_fan, 'AttachedToHVACDistributionSystem'))
      @start_hour = to_integer_or_nil(XMLHelper.get_value(ventilation_fan, 'extension/StartHour'))
    end
  end

  class WaterHeatingSystems < BaseArrayElement
    def add(**kwargs)
      self << WaterHeatingSystem.new(@hpxml_object, **kwargs)
    end

    def from_oga(hpxml)
      return if hpxml.nil?

      XMLHelper.get_elements(hpxml, 'Building/BuildingDetails/Systems/WaterHeating/WaterHeatingSystem').each do |water_heating_system|
        self << WaterHeatingSystem.new(@hpxml_object, water_heating_system)
      end
    end
  end

  class WaterHeatingSystem < BaseElement
    ATTRS = [:id, :year_installed, :fuel_type, :water_heater_type, :location, :performance_adjustment,
             :tank_volume, :fraction_dhw_load_served, :heating_capacity, :energy_factor,
             :uniform_energy_factor, :recovery_efficiency, :uses_desuperheater, :jacket_r_value,
             :related_hvac_idref, :energy_star, :standby_loss, :temperature]
    attr_accessor(*ATTRS)

    def related_hvac_system
      return if @related_hvac_idref.nil?

      (@hpxml_object.heating_systems + @hpxml_object.cooling_systems + @hpxml_object.heat_pumps).each do |hvac_system|
        next unless hvac_system.id == @related_hvac_idref

        return hvac_system
      end
      fail "RelatedHVACSystem '#{@related_hvac_idref}' not found for water heating system '#{@id}'."
    end

    def delete
      @hpxml_object.water_heating_systems.delete(self)
      @hpxml_object.solar_thermal_systems.each do |solar_thermal_system|
        next unless solar_thermal_system.water_heating_system_idref == @id

        solar_thermal_system.water_heating_system_idref = nil
      end
    end

    def check_for_errors
      errors = []
      begin; related_hvac_system; rescue StandardError => e; errors << e.message; end
      return errors
    end

    def to_oga(doc)
      return if nil?

      water_heating = XMLHelper.create_elements_as_needed(doc, ['HPXML', 'Building', 'BuildingDetails', 'Systems', 'WaterHeating'])
      water_heating_system = XMLHelper.add_element(water_heating, 'WaterHeatingSystem')
      sys_id = XMLHelper.add_element(water_heating_system, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_element(water_heating_system, 'FuelType', @fuel_type) unless @fuel_type.nil?
      XMLHelper.add_element(water_heating_system, 'WaterHeaterType', @water_heater_type) unless @water_heater_type.nil?
      XMLHelper.add_element(water_heating_system, 'Location', @location) unless @location.nil?
      XMLHelper.add_element(water_heating_system, 'PerformanceAdjustment', to_float(@performance_adjustment)) unless @performance_adjustment.nil?
      XMLHelper.add_element(water_heating_system, 'TankVolume', to_float(@tank_volume)) unless @tank_volume.nil?
      XMLHelper.add_element(water_heating_system, 'FractionDHWLoadServed', to_float(@fraction_dhw_load_served)) unless @fraction_dhw_load_served.nil?
      XMLHelper.add_element(water_heating_system, 'HeatingCapacity', to_float(@heating_capacity)) unless @heating_capacity.nil?
      XMLHelper.add_element(water_heating_system, 'EnergyFactor', to_float(@energy_factor)) unless @energy_factor.nil?
      XMLHelper.add_element(water_heating_system, 'UniformEnergyFactor', to_float(@uniform_energy_factor)) unless @uniform_energy_factor.nil?
      XMLHelper.add_element(water_heating_system, 'RecoveryEfficiency', to_float(@recovery_efficiency)) unless @recovery_efficiency.nil?
      if not @jacket_r_value.nil?
        water_heater_insulation = XMLHelper.add_element(water_heating_system, 'WaterHeaterInsulation')
        jacket = XMLHelper.add_element(water_heater_insulation, 'Jacket')
        XMLHelper.add_element(jacket, 'JacketRValue', @jacket_r_value)
      end
      XMLHelper.add_element(water_heating_system, 'StandbyLoss', to_float(@standby_loss)) unless @standby_loss.nil?
      XMLHelper.add_element(water_heating_system, 'HotWaterTemperature', to_float(@temperature)) unless @temperature.nil?
      XMLHelper.add_element(water_heating_system, 'UsesDesuperheater', to_boolean(@uses_desuperheater)) unless @uses_desuperheater.nil?
      if not @related_hvac_idref.nil?
        related_hvac_idref_el = XMLHelper.add_element(water_heating_system, 'RelatedHVACSystem')
        XMLHelper.add_attribute(related_hvac_idref_el, 'idref', @related_hvac_idref)
      end
    end

    def from_oga(water_heating_system)
      return if water_heating_system.nil?

      @id = HPXML::get_id(water_heating_system)
      @year_installed = to_integer_or_nil(XMLHelper.get_value(water_heating_system, 'YearInstalled'))
      @fuel_type = XMLHelper.get_value(water_heating_system, 'FuelType')
      @water_heater_type = XMLHelper.get_value(water_heating_system, 'WaterHeaterType')
      @location = XMLHelper.get_value(water_heating_system, 'Location')
      @performance_adjustment = to_float_or_nil(XMLHelper.get_value(water_heating_system, 'PerformanceAdjustment'))
      @tank_volume = to_float_or_nil(XMLHelper.get_value(water_heating_system, 'TankVolume'))
      @fraction_dhw_load_served = to_float_or_nil(XMLHelper.get_value(water_heating_system, 'FractionDHWLoadServed'))
      @heating_capacity = to_float_or_nil(XMLHelper.get_value(water_heating_system, 'HeatingCapacity'))
      @energy_factor = to_float_or_nil(XMLHelper.get_value(water_heating_system, 'EnergyFactor'))
      @uniform_energy_factor = to_float_or_nil(XMLHelper.get_value(water_heating_system, 'UniformEnergyFactor'))
      @recovery_efficiency = to_float_or_nil(XMLHelper.get_value(water_heating_system, 'RecoveryEfficiency'))
      @uses_desuperheater = to_bool_or_nil(XMLHelper.get_value(water_heating_system, 'UsesDesuperheater'))
      @jacket_r_value = to_float_or_nil(XMLHelper.get_value(water_heating_system, 'WaterHeaterInsulation/Jacket/JacketRValue'))
      @related_hvac_idref = HPXML::get_idref(XMLHelper.get_element(water_heating_system, 'RelatedHVACSystem'))
      @energy_star = XMLHelper.get_values(water_heating_system, 'ThirdPartyCertification').include?('Energy Star')
      @standby_loss = to_float_or_nil(XMLHelper.get_value(water_heating_system, 'StandbyLoss'))
      @temperature = to_float_or_nil(XMLHelper.get_value(water_heating_system, 'HotWaterTemperature'))
    end
  end

  class HotWaterDistributions < BaseArrayElement
    def add(**kwargs)
      self << HotWaterDistribution.new(@hpxml_object, **kwargs)
    end

    def from_oga(hpxml)
      return if hpxml.nil?

      XMLHelper.get_elements(hpxml, 'Building/BuildingDetails/Systems/WaterHeating/HotWaterDistribution').each do |hot_water_distribution|
        self << HotWaterDistribution.new(@hpxml_object, hot_water_distribution)
      end
    end
  end

  class HotWaterDistribution < BaseElement
    ATTRS = [:id, :system_type, :pipe_r_value, :standard_piping_length, :recirculation_control_type,
             :recirculation_piping_length, :recirculation_branch_piping_length,
             :recirculation_pump_power, :dwhr_facilities_connected, :dwhr_equal_flow,
             :dwhr_efficiency]
    attr_accessor(*ATTRS)

    def delete
      @hpxml_object.hot_water_distributions.delete(self)
    end

    def check_for_errors
      errors = []
      return errors
    end

    def to_oga(doc)
      return if nil?

      water_heating = XMLHelper.create_elements_as_needed(doc, ['HPXML', 'Building', 'BuildingDetails', 'Systems', 'WaterHeating'])
      hot_water_distribution = XMLHelper.add_element(water_heating, 'HotWaterDistribution')
      sys_id = XMLHelper.add_element(hot_water_distribution, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      if not @system_type.nil?
        system_type_e = XMLHelper.add_element(hot_water_distribution, 'SystemType')
        if @system_type == DHWDistTypeStandard
          standard = XMLHelper.add_element(system_type_e, @system_type)
          XMLHelper.add_element(standard, 'PipingLength', to_float(@standard_piping_length)) unless @standard_piping_length.nil?
        elsif system_type == DHWDistTypeRecirc
          recirculation = XMLHelper.add_element(system_type_e, @system_type)
          XMLHelper.add_element(recirculation, 'ControlType', @recirculation_control_type) unless @recirculation_control_type.nil?
          XMLHelper.add_element(recirculation, 'RecirculationPipingLoopLength', to_float(@recirculation_piping_length)) unless @recirculation_piping_length.nil?
          XMLHelper.add_element(recirculation, 'BranchPipingLoopLength', to_float(@recirculation_branch_piping_length)) unless @recirculation_branch_piping_length.nil?
          XMLHelper.add_element(recirculation, 'PumpPower', to_float(@recirculation_pump_power)) unless @recirculation_pump_power.nil?
        else
          fail "Unhandled hot water distribution type '#{@system_type}'."
        end
      end
      if not @pipe_r_value.nil?
        pipe_insulation = XMLHelper.add_element(hot_water_distribution, 'PipeInsulation')
        XMLHelper.add_element(pipe_insulation, 'PipeRValue', to_float(@pipe_r_value))
      end
      if (not @dwhr_facilities_connected.nil?) || (not @dwhr_equal_flow.nil?) || (not @dwhr_efficiency.nil?)
        drain_water_heat_recovery = XMLHelper.add_element(hot_water_distribution, 'DrainWaterHeatRecovery')
        XMLHelper.add_element(drain_water_heat_recovery, 'FacilitiesConnected', @dwhr_facilities_connected) unless @dwhr_facilities_connected.nil?
        XMLHelper.add_element(drain_water_heat_recovery, 'EqualFlow', to_boolean(@dwhr_equal_flow)) unless @dwhr_equal_flow.nil?
        XMLHelper.add_element(drain_water_heat_recovery, 'Efficiency', to_float(@dwhr_efficiency)) unless @dwhr_efficiency.nil?
      end
    end

    def from_oga(hot_water_distribution)
      return if hot_water_distribution.nil?

      @id = HPXML::get_id(hot_water_distribution)
      @system_type = XMLHelper.get_child_name(hot_water_distribution, 'SystemType')
      @pipe_r_value = to_float_or_nil(XMLHelper.get_value(hot_water_distribution, 'PipeInsulation/PipeRValue'))
      @standard_piping_length = to_float_or_nil(XMLHelper.get_value(hot_water_distribution, 'SystemType/Standard/PipingLength'))
      @recirculation_control_type = XMLHelper.get_value(hot_water_distribution, 'SystemType/Recirculation/ControlType')
      @recirculation_piping_length = to_float_or_nil(XMLHelper.get_value(hot_water_distribution, 'SystemType/Recirculation/RecirculationPipingLoopLength'))
      @recirculation_branch_piping_length = to_float_or_nil(XMLHelper.get_value(hot_water_distribution, 'SystemType/Recirculation/BranchPipingLoopLength'))
      @recirculation_pump_power = to_float_or_nil(XMLHelper.get_value(hot_water_distribution, 'SystemType/Recirculation/PumpPower'))
      @dwhr_facilities_connected = XMLHelper.get_value(hot_water_distribution, 'DrainWaterHeatRecovery/FacilitiesConnected')
      @dwhr_equal_flow = to_bool_or_nil(XMLHelper.get_value(hot_water_distribution, 'DrainWaterHeatRecovery/EqualFlow'))
      @dwhr_efficiency = to_float_or_nil(XMLHelper.get_value(hot_water_distribution, 'DrainWaterHeatRecovery/Efficiency'))
    end
  end

  class WaterFixtures < BaseArrayElement
    def add(**kwargs)
      self << WaterFixture.new(@hpxml_object, **kwargs)
    end

    def from_oga(hpxml)
      return if hpxml.nil?

      XMLHelper.get_elements(hpxml, 'Building/BuildingDetails/Systems/WaterHeating/WaterFixture').each do |water_fixture|
        self << WaterFixture.new(@hpxml_object, water_fixture)
      end
    end
  end

  class WaterFixture < BaseElement
    ATTRS = [:id, :water_fixture_type, :low_flow]
    attr_accessor(*ATTRS)

    def delete
      @hpxml_object.water_fixtures.delete(self)
    end

    def check_for_errors
      errors = []
      return errors
    end

    def to_oga(doc)
      return if nil?

      water_heating = XMLHelper.create_elements_as_needed(doc, ['HPXML', 'Building', 'BuildingDetails', 'Systems', 'WaterHeating'])
      water_fixture = XMLHelper.add_element(water_heating, 'WaterFixture')
      sys_id = XMLHelper.add_element(water_fixture, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_element(water_fixture, 'WaterFixtureType', @water_fixture_type) unless @water_fixture_type.nil?
      XMLHelper.add_element(water_fixture, 'LowFlow', to_boolean(@low_flow)) unless @low_flow.nil?
    end

    def from_oga(water_fixture)
      return if water_fixture.nil?

      @id = HPXML::get_id(water_fixture)
      @water_fixture_type = XMLHelper.get_value(water_fixture, 'WaterFixtureType')
      @low_flow = to_bool_or_nil(XMLHelper.get_value(water_fixture, 'LowFlow'))
    end
  end

  class WaterHeating < BaseElement
    ATTRS = [:water_fixtures_usage_multiplier]
    attr_accessor(*ATTRS)

    def check_for_errors
      errors = []
      return errors
    end

    def to_oga(doc)
      return if nil?

      water_heating = XMLHelper.create_elements_as_needed(doc, ['HPXML', 'Building', 'BuildingDetails', 'Systems', 'WaterHeating'])
      HPXML::add_extension(parent: water_heating,
                           extensions: { 'WaterFixturesUsageMultiplier' => to_float_or_nil(@water_fixtures_usage_multiplier) })
    end

    def from_oga(hpxml)
      return if hpxml.nil?

      water_heating = XMLHelper.get_element(hpxml, 'Building/BuildingDetails/Systems/WaterHeating')
      return if water_heating.nil?

      @water_fixtures_usage_multiplier = to_float_or_nil(XMLHelper.get_value(water_heating, 'extension/WaterFixturesUsageMultiplier'))
    end
  end

  class SolarThermalSystems < BaseArrayElement
    def add(**kwargs)
      self << SolarThermalSystem.new(@hpxml_object, **kwargs)
    end

    def from_oga(hpxml)
      return if hpxml.nil?

      XMLHelper.get_elements(hpxml, 'Building/BuildingDetails/Systems/SolarThermal/SolarThermalSystem').each do |solar_thermal_system|
        self << SolarThermalSystem.new(@hpxml_object, solar_thermal_system)
      end
    end
  end

  class SolarThermalSystem < BaseElement
    ATTRS = [:id, :system_type, :collector_area, :collector_loop_type, :collector_azimuth,
             :collector_type, :collector_tilt, :collector_frta, :collector_frul, :storage_volume,
             :water_heating_system_idref, :solar_fraction]
    attr_accessor(*ATTRS)

    def water_heating_system
      return if @water_heating_system_idref.nil?

      @hpxml_object.water_heating_systems.each do |water_heater|
        next unless water_heater.id == @water_heating_system_idref

        return water_heater
      end
      fail "Attached water heating system '#{@water_heating_system_idref}' not found for solar thermal system '#{@id}'."
    end

    def delete
      @hpxml_object.solar_thermal_systems.delete(self)
    end

    def check_for_errors
      errors = []
      begin; water_heating_system; rescue StandardError => e; errors << e.message; end
      return errors
    end

    def to_oga(doc)
      return if nil?

      solar_thermal = XMLHelper.create_elements_as_needed(doc, ['HPXML', 'Building', 'BuildingDetails', 'Systems', 'SolarThermal'])
      solar_thermal_system = XMLHelper.add_element(solar_thermal, 'SolarThermalSystem')
      sys_id = XMLHelper.add_element(solar_thermal_system, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_element(solar_thermal_system, 'SystemType', @system_type) unless @system_type.nil?
      XMLHelper.add_element(solar_thermal_system, 'CollectorArea', to_float(@collector_area)) unless @collector_area.nil?
      XMLHelper.add_element(solar_thermal_system, 'CollectorLoopType', @collector_loop_type) unless @collector_loop_type.nil?
      XMLHelper.add_element(solar_thermal_system, 'CollectorType', @collector_type) unless @collector_type.nil?
      XMLHelper.add_element(solar_thermal_system, 'CollectorAzimuth', to_integer(@collector_azimuth)) unless @collector_azimuth.nil?
      XMLHelper.add_element(solar_thermal_system, 'CollectorTilt', to_float(@collector_tilt)) unless @collector_tilt.nil?
      XMLHelper.add_element(solar_thermal_system, 'CollectorRatedOpticalEfficiency', to_float(@collector_frta)) unless @collector_frta.nil?
      XMLHelper.add_element(solar_thermal_system, 'CollectorRatedThermalLosses', to_float(@collector_frul)) unless @collector_frul.nil?
      XMLHelper.add_element(solar_thermal_system, 'StorageVolume', to_float(@storage_volume)) unless @storage_volume.nil?
      if not @water_heating_system_idref.nil?
        connected_to = XMLHelper.add_element(solar_thermal_system, 'ConnectedTo')
        XMLHelper.add_attribute(connected_to, 'idref', @water_heating_system_idref)
      end
      XMLHelper.add_element(solar_thermal_system, 'SolarFraction', to_float(@solar_fraction)) unless @solar_fraction.nil?
    end

    def from_oga(solar_thermal_system)
      return if solar_thermal_system.nil?

      @id = HPXML::get_id(solar_thermal_system)
      @system_type = XMLHelper.get_value(solar_thermal_system, 'SystemType')
      @collector_area = to_float_or_nil(XMLHelper.get_value(solar_thermal_system, 'CollectorArea'))
      @collector_loop_type = XMLHelper.get_value(solar_thermal_system, 'CollectorLoopType')
      @collector_azimuth = to_integer_or_nil(XMLHelper.get_value(solar_thermal_system, 'CollectorAzimuth'))
      @collector_type = XMLHelper.get_value(solar_thermal_system, 'CollectorType')
      @collector_tilt = to_float_or_nil(XMLHelper.get_value(solar_thermal_system, 'CollectorTilt'))
      @collector_frta = to_float_or_nil(XMLHelper.get_value(solar_thermal_system, 'CollectorRatedOpticalEfficiency'))
      @collector_frul = to_float_or_nil(XMLHelper.get_value(solar_thermal_system, 'CollectorRatedThermalLosses'))
      @storage_volume = to_float_or_nil(XMLHelper.get_value(solar_thermal_system, 'StorageVolume'))
      @water_heating_system_idref = HPXML::get_idref(XMLHelper.get_element(solar_thermal_system, 'ConnectedTo'))
      @solar_fraction = to_float_or_nil(XMLHelper.get_value(solar_thermal_system, 'SolarFraction'))
    end
  end

  class PVSystems < BaseArrayElement
    def add(**kwargs)
      self << PVSystem.new(@hpxml_object, **kwargs)
    end

    def from_oga(hpxml)
      return if hpxml.nil?

      XMLHelper.get_elements(hpxml, 'Building/BuildingDetails/Systems/Photovoltaics/PVSystem').each do |pv_system|
        self << PVSystem.new(@hpxml_object, pv_system)
      end
    end
  end

  class PVSystem < BaseElement
    ATTRS = [:id, :location, :module_type, :tracking, :array_orientation, :array_azimuth, :array_tilt,
             :max_power_output, :inverter_efficiency, :system_losses_fraction, :number_of_panels,
             :year_modules_manufactured]
    attr_accessor(*ATTRS)

    def delete
      @hpxml_object.pv_systems.delete(self)
    end

    def check_for_errors
      errors = []
      return errors
    end

    def to_oga(doc)
      return if nil?

      photovoltaics = XMLHelper.create_elements_as_needed(doc, ['HPXML', 'Building', 'BuildingDetails', 'Systems', 'Photovoltaics'])
      pv_system = XMLHelper.add_element(photovoltaics, 'PVSystem')
      sys_id = XMLHelper.add_element(pv_system, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_element(pv_system, 'Location', @location) unless @location.nil?
      XMLHelper.add_element(pv_system, 'ModuleType', @module_type) unless @module_type.nil?
      XMLHelper.add_element(pv_system, 'Tracking', @tracking) unless @tracking.nil?
      XMLHelper.add_element(pv_system, 'ArrayAzimuth', to_integer(@array_azimuth)) unless @array_azimuth.nil?
      XMLHelper.add_element(pv_system, 'ArrayTilt', to_float(@array_tilt)) unless @array_tilt.nil?
      XMLHelper.add_element(pv_system, 'MaxPowerOutput', to_float(@max_power_output)) unless @max_power_output.nil?
      XMLHelper.add_element(pv_system, 'InverterEfficiency', to_float(@inverter_efficiency)) unless @inverter_efficiency.nil?
      XMLHelper.add_element(pv_system, 'SystemLossesFraction', to_float(@system_losses_fraction)) unless @system_losses_fraction.nil?
      XMLHelper.add_element(pv_system, 'YearModulesManufactured', to_integer(@year_modules_manufactured)) unless @year_modules_manufactured.nil?
    end

    def from_oga(pv_system)
      return if pv_system.nil?

      @id = HPXML::get_id(pv_system)
      @location = XMLHelper.get_value(pv_system, 'Location')
      @module_type = XMLHelper.get_value(pv_system, 'ModuleType')
      @tracking = XMLHelper.get_value(pv_system, 'Tracking')
      @array_orientation = XMLHelper.get_value(pv_system, 'ArrayOrientation')
      @array_azimuth = to_integer_or_nil(XMLHelper.get_value(pv_system, 'ArrayAzimuth'))
      @array_tilt = to_float_or_nil(XMLHelper.get_value(pv_system, 'ArrayTilt'))
      @max_power_output = to_float_or_nil(XMLHelper.get_value(pv_system, 'MaxPowerOutput'))
      @inverter_efficiency = to_float_or_nil(XMLHelper.get_value(pv_system, 'InverterEfficiency'))
      @system_losses_fraction = to_float_or_nil(XMLHelper.get_value(pv_system, 'SystemLossesFraction'))
      @number_of_panels = to_integer_or_nil(XMLHelper.get_value(pv_system, 'NumberOfPanels'))
      @year_modules_manufactured = to_integer_or_nil(XMLHelper.get_value(pv_system, 'YearModulesManufactured'))
    end
  end

  class ClothesWashers < BaseArrayElement
    def add(**kwargs)
      self << ClothesWasher.new(@hpxml_object, **kwargs)
    end

    def from_oga(hpxml)
      return if hpxml.nil?

      XMLHelper.get_elements(hpxml, 'Building/BuildingDetails/Appliances/ClothesWasher').each do |clothes_washer|
        self << ClothesWasher.new(@hpxml_object, clothes_washer)
      end
    end
  end

  class ClothesWasher < BaseElement
    ATTRS = [:id, :location, :modified_energy_factor, :integrated_modified_energy_factor,
             :rated_annual_kwh, :label_electric_rate, :label_gas_rate, :label_annual_gas_cost,
             :capacity, :label_usage, :usage_multiplier]
    attr_accessor(*ATTRS)

    def delete
      @hpxml_object.clothes_washers.delete(self)
    end

    def check_for_errors
      errors = []
      return errors
    end

    def to_oga(doc)
      return if nil?

      appliances = XMLHelper.create_elements_as_needed(doc, ['HPXML', 'Building', 'BuildingDetails', 'Appliances'])
      clothes_washer = XMLHelper.add_element(appliances, 'ClothesWasher')
      sys_id = XMLHelper.add_element(clothes_washer, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_element(clothes_washer, 'Location', @location) unless @location.nil?
      XMLHelper.add_element(clothes_washer, 'ModifiedEnergyFactor', to_float(@modified_energy_factor)) unless @modified_energy_factor.nil?
      XMLHelper.add_element(clothes_washer, 'IntegratedModifiedEnergyFactor', to_float(@integrated_modified_energy_factor)) unless @integrated_modified_energy_factor.nil?
      XMLHelper.add_element(clothes_washer, 'RatedAnnualkWh', to_float(@rated_annual_kwh)) unless @rated_annual_kwh.nil?
      XMLHelper.add_element(clothes_washer, 'LabelElectricRate', to_float(@label_electric_rate)) unless @label_electric_rate.nil?
      XMLHelper.add_element(clothes_washer, 'LabelGasRate', to_float(@label_gas_rate)) unless @label_gas_rate.nil?
      XMLHelper.add_element(clothes_washer, 'LabelAnnualGasCost', to_float(@label_annual_gas_cost)) unless @label_annual_gas_cost.nil?
      XMLHelper.add_element(clothes_washer, 'LabelUsage', to_float(@label_usage)) unless @label_usage.nil?
      XMLHelper.add_element(clothes_washer, 'Capacity', to_float(@capacity)) unless @capacity.nil?
      HPXML::add_extension(parent: clothes_washer,
                           extensions: { 'UsageMultiplier' => to_float_or_nil(@usage_multiplier) })
    end

    def from_oga(clothes_washer)
      return if clothes_washer.nil?

      @id = HPXML::get_id(clothes_washer)
      @location = XMLHelper.get_value(clothes_washer, 'Location')
      @modified_energy_factor = to_float_or_nil(XMLHelper.get_value(clothes_washer, 'ModifiedEnergyFactor'))
      @integrated_modified_energy_factor = to_float_or_nil(XMLHelper.get_value(clothes_washer, 'IntegratedModifiedEnergyFactor'))
      @rated_annual_kwh = to_float_or_nil(XMLHelper.get_value(clothes_washer, 'RatedAnnualkWh'))
      @label_electric_rate = to_float_or_nil(XMLHelper.get_value(clothes_washer, 'LabelElectricRate'))
      @label_gas_rate = to_float_or_nil(XMLHelper.get_value(clothes_washer, 'LabelGasRate'))
      @label_annual_gas_cost = to_float_or_nil(XMLHelper.get_value(clothes_washer, 'LabelAnnualGasCost'))
      @label_usage = to_float_or_nil(XMLHelper.get_value(clothes_washer, 'LabelUsage'))
      @capacity = to_float_or_nil(XMLHelper.get_value(clothes_washer, 'Capacity'))
      @usage_multiplier = to_float_or_nil(XMLHelper.get_value(clothes_washer, 'extension/UsageMultiplier'))
    end
  end

  class ClothesDryers < BaseArrayElement
    def add(**kwargs)
      self << ClothesDryer.new(@hpxml_object, **kwargs)
    end

    def from_oga(hpxml)
      return if hpxml.nil?

      XMLHelper.get_elements(hpxml, 'Building/BuildingDetails/Appliances/ClothesDryer').each do |clothes_dryer|
        self << ClothesDryer.new(@hpxml_object, clothes_dryer)
      end
    end
  end

  class ClothesDryer < BaseElement
    ATTRS = [:id, :location, :fuel_type, :energy_factor, :combined_energy_factor, :control_type,
             :usage_multiplier]
    attr_accessor(*ATTRS)

    def delete
      @hpxml_object.clothes_dryers.delete(self)
    end

    def check_for_errors
      errors = []
      return errors
    end

    def to_oga(doc)
      return if nil?

      appliances = XMLHelper.create_elements_as_needed(doc, ['HPXML', 'Building', 'BuildingDetails', 'Appliances'])
      clothes_dryer = XMLHelper.add_element(appliances, 'ClothesDryer')
      sys_id = XMLHelper.add_element(clothes_dryer, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_element(clothes_dryer, 'Location', @location) unless @location.nil?
      XMLHelper.add_element(clothes_dryer, 'FuelType', @fuel_type) unless @fuel_type.nil?
      XMLHelper.add_element(clothes_dryer, 'EnergyFactor', to_float(@energy_factor)) unless @energy_factor.nil?
      XMLHelper.add_element(clothes_dryer, 'CombinedEnergyFactor', to_float(@combined_energy_factor)) unless @combined_energy_factor.nil?
      XMLHelper.add_element(clothes_dryer, 'ControlType', @control_type) unless @control_type.nil?
      HPXML::add_extension(parent: clothes_dryer,
                           extensions: { 'UsageMultiplier' => to_float_or_nil(@usage_multiplier) })
    end

    def from_oga(clothes_dryer)
      return if clothes_dryer.nil?

      @id = HPXML::get_id(clothes_dryer)
      @location = XMLHelper.get_value(clothes_dryer, 'Location')
      @fuel_type = XMLHelper.get_value(clothes_dryer, 'FuelType')
      @energy_factor = to_float_or_nil(XMLHelper.get_value(clothes_dryer, 'EnergyFactor'))
      @combined_energy_factor = to_float_or_nil(XMLHelper.get_value(clothes_dryer, 'CombinedEnergyFactor'))
      @control_type = XMLHelper.get_value(clothes_dryer, 'ControlType')
      @usage_multiplier = to_float_or_nil(XMLHelper.get_value(clothes_dryer, 'extension/UsageMultiplier'))
    end
  end

  class Dishwashers < BaseArrayElement
    def add(**kwargs)
      self << Dishwasher.new(@hpxml_object, **kwargs)
    end

    def from_oga(hpxml)
      return if hpxml.nil?

      XMLHelper.get_elements(hpxml, 'Building/BuildingDetails/Appliances/Dishwasher').each do |dishwasher|
        self << Dishwasher.new(@hpxml_object, dishwasher)
      end
    end
  end

  class Dishwasher < BaseElement
    ATTRS = [:id, :location, :energy_factor, :rated_annual_kwh, :place_setting_capacity,
             :label_electric_rate, :label_gas_rate, :label_annual_gas_cost,
             :label_usage, :usage_multiplier]
    attr_accessor(*ATTRS)

    def delete
      @hpxml_object.dishwashers.delete(self)
    end

    def check_for_errors
      errors = []
      return errors
    end

    def to_oga(doc)
      return if nil?

      appliances = XMLHelper.create_elements_as_needed(doc, ['HPXML', 'Building', 'BuildingDetails', 'Appliances'])
      dishwasher = XMLHelper.add_element(appliances, 'Dishwasher')
      sys_id = XMLHelper.add_element(dishwasher, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_element(dishwasher, 'Location', @location) unless @location.nil?
      XMLHelper.add_element(dishwasher, 'RatedAnnualkWh', to_float(@rated_annual_kwh)) unless @rated_annual_kwh.nil?
      XMLHelper.add_element(dishwasher, 'EnergyFactor', to_float(@energy_factor)) unless @energy_factor.nil?
      XMLHelper.add_element(dishwasher, 'PlaceSettingCapacity', to_integer(@place_setting_capacity)) unless @place_setting_capacity.nil?
      XMLHelper.add_element(dishwasher, 'LabelElectricRate', to_float(@label_electric_rate)) unless @label_electric_rate.nil?
      XMLHelper.add_element(dishwasher, 'LabelGasRate', to_float(@label_gas_rate)) unless @label_gas_rate.nil?
      XMLHelper.add_element(dishwasher, 'LabelAnnualGasCost', to_float(@label_annual_gas_cost)) unless @label_annual_gas_cost.nil?
      XMLHelper.add_element(dishwasher, 'LabelUsage', to_float(@label_usage)) unless @label_usage.nil?
      HPXML::add_extension(parent: dishwasher,
                           extensions: { 'UsageMultiplier' => to_float_or_nil(@usage_multiplier) })
    end

    def from_oga(dishwasher)
      return if dishwasher.nil?

      @id = HPXML::get_id(dishwasher)
      @location = XMLHelper.get_value(dishwasher, 'Location')
      @rated_annual_kwh = to_float_or_nil(XMLHelper.get_value(dishwasher, 'RatedAnnualkWh'))
      @energy_factor = to_float_or_nil(XMLHelper.get_value(dishwasher, 'EnergyFactor'))
      @place_setting_capacity = to_integer_or_nil(XMLHelper.get_value(dishwasher, 'PlaceSettingCapacity'))
      @label_electric_rate = to_float_or_nil(XMLHelper.get_value(dishwasher, 'LabelElectricRate'))
      @label_gas_rate = to_float_or_nil(XMLHelper.get_value(dishwasher, 'LabelGasRate'))
      @label_annual_gas_cost = to_float_or_nil(XMLHelper.get_value(dishwasher, 'LabelAnnualGasCost'))
      @label_usage = to_float_or_nil(XMLHelper.get_value(dishwasher, 'LabelUsage'))
      @usage_multiplier = to_float_or_nil(XMLHelper.get_value(dishwasher, 'extension/UsageMultiplier'))
    end
  end

  class Refrigerators < BaseArrayElement
    def add(**kwargs)
      self << Refrigerator.new(@hpxml_object, **kwargs)
    end

    def from_oga(hpxml)
      return if hpxml.nil?

      XMLHelper.get_elements(hpxml, 'Building/BuildingDetails/Appliances/Refrigerator').each do |refrigerator|
        self << Refrigerator.new(@hpxml_object, refrigerator)
      end
    end
  end

  class Refrigerator < BaseElement
    ATTRS = [:id, :location, :rated_annual_kwh, :adjusted_annual_kwh, :usage_multiplier, :primary_indicator,
             :weekday_fractions, :weekend_fractions, :monthly_multipliers,
             :schedules_output_path, :schedules_column_name]
    attr_accessor(*ATTRS)

    def delete
      @hpxml_object.refrigerators.delete(self)
    end

    def check_for_errors
      errors = []

      if @hpxml_object.refrigerators.size > 1
        primary_indicator = false
        @hpxml_object.refrigerators.each do |refrigerator|
          next unless not refrigerator.primary_indicator.nil?
          fail 'More than one refrigerator designated as the primary.' if refrigerator.primary_indicator && primary_indicator

          primary_indicator = true if refrigerator.primary_indicator
        end
        fail 'Could not find a primary refrigerator.' if not primary_indicator
      end

      return errors
    end

    def to_oga(doc)
      return if nil?

      appliances = XMLHelper.create_elements_as_needed(doc, ['HPXML', 'Building', 'BuildingDetails', 'Appliances'])
      refrigerator = XMLHelper.add_element(appliances, 'Refrigerator')
      sys_id = XMLHelper.add_element(refrigerator, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_element(refrigerator, 'Location', @location) unless @location.nil?
      XMLHelper.add_element(refrigerator, 'RatedAnnualkWh', to_float(@rated_annual_kwh)) unless @rated_annual_kwh.nil?
      XMLHelper.add_element(refrigerator, 'PrimaryIndicator', to_boolean(@primary_indicator)) unless @primary_indicator.nil?
      HPXML::add_extension(parent: refrigerator,
                           extensions: { 'AdjustedAnnualkWh' => to_float_or_nil(@adjusted_annual_kwh),
                                         'UsageMultiplier' => to_float_or_nil(@usage_multiplier),
                                         'WeekdayScheduleFractions' => @weekday_fractions,
                                         'WeekendScheduleFractions' => @weekend_fractions,
                                         'MonthlyScheduleMultipliers' => @monthly_multipliers,
                                         'SchedulesOutputPath' => @schedules_output_path,
                                         'SchedulesColumnName' => @schedules_column_name })
    end

    def from_oga(refrigerator)
      return if refrigerator.nil?

      @id = HPXML::get_id(refrigerator)
      @location = XMLHelper.get_value(refrigerator, 'Location')
      @rated_annual_kwh = to_float_or_nil(XMLHelper.get_value(refrigerator, 'RatedAnnualkWh'))
      @primary_indicator = to_bool_or_nil(XMLHelper.get_value(refrigerator, 'PrimaryIndicator'))
      @adjusted_annual_kwh = to_float_or_nil(XMLHelper.get_value(refrigerator, 'extension/AdjustedAnnualkWh'))
      @usage_multiplier = to_float_or_nil(XMLHelper.get_value(refrigerator, 'extension/UsageMultiplier'))
      @weekday_fractions = XMLHelper.get_value(refrigerator, 'extension/WeekdayScheduleFractions')
      @weekend_fractions = XMLHelper.get_value(refrigerator, 'extension/WeekendScheduleFractions')
      @monthly_multipliers = XMLHelper.get_value(refrigerator, 'extension/MonthlyScheduleMultipliers')
      @schedules_output_path = XMLHelper.get_value(refrigerator, 'extension/SchedulesOutputPath')
      @schedules_column_name = XMLHelper.get_value(refrigerator, 'extension/SchedulesColumnName')
    end
  end

  class Freezers < BaseArrayElement
    def add(**kwargs)
      self << Freezer.new(@hpxml_object, **kwargs)
    end

    def from_oga(hpxml)
      return if hpxml.nil?

      XMLHelper.get_elements(hpxml, 'Building/BuildingDetails/Appliances/Freezer').each do |freezer|
        self << Freezer.new(@hpxml_object, freezer)
      end
    end
  end

  class Freezer < BaseElement
    ATTRS = [:id, :location, :rated_annual_kwh, :adjusted_annual_kwh, :usage_multiplier,
             :weekday_fractions, :weekend_fractions, :monthly_multipliers]
    attr_accessor(*ATTRS)

    def delete
      @hpxml_object.freezers.delete(self)
    end

    def check_for_errors
      errors = []
      return errors
    end

    def to_oga(doc)
      return if nil?

      appliances = XMLHelper.create_elements_as_needed(doc, ['HPXML', 'Building', 'BuildingDetails', 'Appliances'])
      freezer = XMLHelper.add_element(appliances, 'Freezer')
      sys_id = XMLHelper.add_element(freezer, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_element(freezer, 'Location', @location) unless @location.nil?
      XMLHelper.add_element(freezer, 'RatedAnnualkWh', to_float(@rated_annual_kwh)) unless @rated_annual_kwh.nil?
      HPXML::add_extension(parent: freezer,
                           extensions: { 'AdjustedAnnualkWh' => to_float_or_nil(@adjusted_annual_kwh),
                                         'UsageMultiplier' => to_float_or_nil(@usage_multiplier),
                                         'WeekdayScheduleFractions' => @weekday_fractions,
                                         'WeekendScheduleFractions' => @weekend_fractions,
                                         'MonthlyScheduleMultipliers' => @monthly_multipliers })
    end

    def from_oga(freezer)
      return if freezer.nil?

      @id = HPXML::get_id(freezer)
      @location = XMLHelper.get_value(freezer, 'Location')
      @rated_annual_kwh = to_float_or_nil(XMLHelper.get_value(freezer, 'RatedAnnualkWh'))
      @adjusted_annual_kwh = to_float_or_nil(XMLHelper.get_value(freezer, 'extension/AdjustedAnnualkWh'))
      @usage_multiplier = to_float_or_nil(XMLHelper.get_value(freezer, 'extension/UsageMultiplier'))
      @weekday_fractions = XMLHelper.get_value(freezer, 'extension/WeekdayScheduleFractions')
      @weekend_fractions = XMLHelper.get_value(freezer, 'extension/WeekendScheduleFractions')
      @monthly_multipliers = XMLHelper.get_value(freezer, 'extension/MonthlyScheduleMultipliers')
    end
  end

  class Dehumidifiers < BaseArrayElement
    def add(**kwargs)
      self << Dehumidifier.new(@hpxml_object, **kwargs)
    end

    def from_oga(hpxml)
      return if hpxml.nil?

      XMLHelper.get_elements(hpxml, 'Building/BuildingDetails/Appliances/Dehumidifier').each do |dehumidifier|
        self << Dehumidifier.new(@hpxml_object, dehumidifier)
      end
    end
  end

  class Dehumidifier < BaseElement
    ATTRS = [:id, :capacity, :energy_factor, :integrated_energy_factor, :rh_setpoint, :fraction_served]
    attr_accessor(*ATTRS)

    def delete
      @hpxml_object.dehumidifiers.delete(self)
    end

    def check_for_errors
      errors = []
      return errors
    end

    def to_oga(doc)
      return if nil?

      appliances = XMLHelper.create_elements_as_needed(doc, ['HPXML', 'Building', 'BuildingDetails', 'Appliances'])
      dehumidifier = XMLHelper.add_element(appliances, 'Dehumidifier')
      sys_id = XMLHelper.add_element(dehumidifier, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_element(dehumidifier, 'Capacity', to_float(@capacity)) unless @capacity.nil?
      XMLHelper.add_element(dehumidifier, 'EnergyFactor', to_float(@energy_factor)) unless @energy_factor.nil?
      XMLHelper.add_element(dehumidifier, 'IntegratedEnergyFactor', to_float(@integrated_energy_factor)) unless @integrated_energy_factor.nil?
      XMLHelper.add_element(dehumidifier, 'DehumidistatSetpoint', to_float(@rh_setpoint)) unless @rh_setpoint.nil?
      XMLHelper.add_element(dehumidifier, 'FractionDehumidificationLoadServed', to_float(@fraction_served)) unless @fraction_served.nil?
    end

    def from_oga(dehumidifier)
      return if dehumidifier.nil?

      @id = HPXML::get_id(dehumidifier)
      @capacity = to_float_or_nil(XMLHelper.get_value(dehumidifier, 'Capacity'))
      @energy_factor = to_float_or_nil(XMLHelper.get_value(dehumidifier, 'EnergyFactor'))
      @integrated_energy_factor = to_float_or_nil(XMLHelper.get_value(dehumidifier, 'IntegratedEnergyFactor'))
      @rh_setpoint = to_float_or_nil(XMLHelper.get_value(dehumidifier, 'DehumidistatSetpoint'))
      @fraction_served = to_float_or_nil(XMLHelper.get_value(dehumidifier, 'FractionDehumidificationLoadServed'))
    end
  end

  class CookingRanges < BaseArrayElement
    def add(**kwargs)
      self << CookingRange.new(@hpxml_object, **kwargs)
    end

    def from_oga(hpxml)
      return if hpxml.nil?

      XMLHelper.get_elements(hpxml, 'Building/BuildingDetails/Appliances/CookingRange').each do |cooking_range|
        self << CookingRange.new(@hpxml_object, cooking_range)
      end
    end
  end

  class CookingRange < BaseElement
    ATTRS = [:id, :location, :fuel_type, :is_induction, :usage_multiplier,
             :weekday_fractions, :weekend_fractions, :monthly_multipliers]
    attr_accessor(*ATTRS)

    def delete
      @hpxml_object.cooking_ranges.delete(self)
    end

    def check_for_errors
      errors = []
      return errors
    end

    def to_oga(doc)
      return if nil?

      appliances = XMLHelper.create_elements_as_needed(doc, ['HPXML', 'Building', 'BuildingDetails', 'Appliances'])
      cooking_range = XMLHelper.add_element(appliances, 'CookingRange')
      sys_id = XMLHelper.add_element(cooking_range, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_element(cooking_range, 'Location', @location) unless @location.nil?
      XMLHelper.add_element(cooking_range, 'FuelType', @fuel_type) unless @fuel_type.nil?
      XMLHelper.add_element(cooking_range, 'IsInduction', to_boolean(@is_induction)) unless @is_induction.nil?
      HPXML::add_extension(parent: cooking_range,
                           extensions: { 'UsageMultiplier' => to_float_or_nil(@usage_multiplier),
                                         'WeekdayScheduleFractions' => @weekday_fractions,
                                         'WeekendScheduleFractions' => @weekend_fractions,
                                         'MonthlyScheduleMultipliers' => @monthly_multipliers })
    end

    def from_oga(cooking_range)
      return if cooking_range.nil?

      @id = HPXML::get_id(cooking_range)
      @location = XMLHelper.get_value(cooking_range, 'Location')
      @fuel_type = XMLHelper.get_value(cooking_range, 'FuelType')
      @is_induction = to_bool_or_nil(XMLHelper.get_value(cooking_range, 'IsInduction'))
      @usage_multiplier = to_float_or_nil(XMLHelper.get_value(cooking_range, 'extension/UsageMultiplier'))
      @weekday_fractions = XMLHelper.get_value(cooking_range, 'extension/WeekdayScheduleFractions')
      @weekend_fractions = XMLHelper.get_value(cooking_range, 'extension/WeekendScheduleFractions')
      @monthly_multipliers = XMLHelper.get_value(cooking_range, 'extension/MonthlyScheduleMultipliers')
    end
  end

  class Ovens < BaseArrayElement
    def add(**kwargs)
      self << Oven.new(@hpxml_object, **kwargs)
    end

    def from_oga(hpxml)
      return if hpxml.nil?

      XMLHelper.get_elements(hpxml, 'Building/BuildingDetails/Appliances/Oven').each do |oven|
        self << Oven.new(@hpxml_object, oven)
      end
    end
  end

  class Oven < BaseElement
    ATTRS = [:id, :is_convection]
    attr_accessor(*ATTRS)

    def delete
      @hpxml_object.ovens.delete(self)
    end

    def check_for_errors
      errors = []
      return errors
    end

    def to_oga(doc)
      return if nil?

      appliances = XMLHelper.create_elements_as_needed(doc, ['HPXML', 'Building', 'BuildingDetails', 'Appliances'])
      oven = XMLHelper.add_element(appliances, 'Oven')
      sys_id = XMLHelper.add_element(oven, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_element(oven, 'IsConvection', to_boolean(@is_convection)) unless @is_convection.nil?
    end

    def from_oga(oven)
      return if oven.nil?

      @id = HPXML::get_id(oven)
      @is_convection = to_bool_or_nil(XMLHelper.get_value(oven, 'IsConvection'))
    end
  end

  class LightingGroups < BaseArrayElement
    def add(**kwargs)
      self << LightingGroup.new(@hpxml_object, **kwargs)
    end

    def from_oga(hpxml)
      return if hpxml.nil?

      XMLHelper.get_elements(hpxml, 'Building/BuildingDetails/Lighting/LightingGroup').each do |lighting_group|
        self << LightingGroup.new(@hpxml_object, lighting_group)
      end
    end
  end

  class LightingGroup < BaseElement
    ATTRS = [:id, :location, :fraction_of_units_in_location, :lighting_type]
    attr_accessor(*ATTRS)

    def delete
      @hpxml_object.lighting_groups.delete(self)
    end

    def check_for_errors
      errors = []
      return errors
    end

    def to_oga(doc)
      return if nil?

      lighting = XMLHelper.create_elements_as_needed(doc, ['HPXML', 'Building', 'BuildingDetails', 'Lighting'])
      lighting_group = XMLHelper.add_element(lighting, 'LightingGroup')
      sys_id = XMLHelper.add_element(lighting_group, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_element(lighting_group, 'Location', @location) unless @location.nil?
      XMLHelper.add_element(lighting_group, 'FractionofUnitsInLocation', to_float(@fraction_of_units_in_location)) unless @fraction_of_units_in_location.nil?
      if not @lighting_type.nil?
        lighting_type = XMLHelper.add_element(lighting_group, 'LightingType')
        XMLHelper.add_element(lighting_type, @lighting_type)
      end
    end

    def from_oga(lighting_group)
      return if lighting_group.nil?

      @id = HPXML::get_id(lighting_group)
      @location = XMLHelper.get_value(lighting_group, 'Location')
      @fraction_of_units_in_location = to_float_or_nil(XMLHelper.get_value(lighting_group, 'FractionofUnitsInLocation'))
      @lighting_type = XMLHelper.get_child_name(lighting_group, 'LightingType')
    end
  end

  class Lighting < BaseElement
    ATTRS = [:usage_multiplier]
    attr_accessor(*ATTRS)

    def check_for_errors
      errors = []
      return errors
    end

    def to_oga(doc)
      return if nil?

      lighting = XMLHelper.create_elements_as_needed(doc, ['HPXML', 'Building', 'BuildingDetails', 'Lighting'])
      HPXML::add_extension(parent: lighting,
                           extensions: { 'UsageMultiplier' => to_float_or_nil(@usage_multiplier) })
    end

    def from_oga(hpxml)
      return if hpxml.nil?

      lighting = XMLHelper.get_element(hpxml, 'Building/BuildingDetails/Lighting')
      return if lighting.nil?

      @usage_multiplier = to_float_or_nil(XMLHelper.get_value(lighting, 'extension/UsageMultiplier'))
    end
  end

  class CeilingFans < BaseArrayElement
    def add(**kwargs)
      self << CeilingFan.new(@hpxml_object, **kwargs)
    end

    def from_oga(hpxml)
      return if hpxml.nil?

      XMLHelper.get_elements(hpxml, 'Building/BuildingDetails/Lighting/CeilingFan').each do |ceiling_fan|
        self << CeilingFan.new(@hpxml_object, ceiling_fan)
      end
    end
  end

  class CeilingFan < BaseElement
    ATTRS = [:id, :efficiency, :quantity]
    attr_accessor(*ATTRS)

    def delete
      @hpxml_object.ceiling_fans.delete(self)
    end

    def check_for_errors
      errors = []
      return errors
    end

    def to_oga(doc)
      return if nil?

      lighting = XMLHelper.create_elements_as_needed(doc, ['HPXML', 'Building', 'BuildingDetails', 'Lighting'])
      ceiling_fan = XMLHelper.add_element(lighting, 'CeilingFan')
      sys_id = XMLHelper.add_element(ceiling_fan, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      if not @efficiency.nil?
        airflow = XMLHelper.add_element(ceiling_fan, 'Airflow')
        XMLHelper.add_element(airflow, 'FanSpeed', 'medium')
        XMLHelper.add_element(airflow, 'Efficiency', to_float(@efficiency))
      end
      XMLHelper.add_element(ceiling_fan, 'Quantity', to_integer(@quantity)) unless @quantity.nil?
    end

    def from_oga(ceiling_fan)
      @id = HPXML::get_id(ceiling_fan)
      @efficiency = to_float_or_nil(XMLHelper.get_value(ceiling_fan, "Airflow[FanSpeed='medium']/Efficiency"))
      @quantity = to_integer_or_nil(XMLHelper.get_value(ceiling_fan, 'Quantity'))
    end
  end

  class Pools < BaseArrayElement
    def add(**kwargs)
      self << Pool.new(@hpxml_object, **kwargs)
    end

    def from_oga(hpxml)
      return if hpxml.nil?

      XMLHelper.get_elements(hpxml, 'Building/BuildingDetails/Pools/Pool').each do |pool|
        self << Pool.new(@hpxml_object, pool)
      end
    end
  end

  class Pool < BaseElement
    ATTRS = [:id, :heater_id, :heater_type, :heater_load_units, :heater_load_value, :heater_usage_multiplier,
             :pump_id, :pump_kwh_per_year, :pump_usage_multiplier,
             :heater_weekday_fractions, :heater_weekend_fractions, :heater_monthly_multipliers,
             :pump_weekday_fractions, :pump_weekend_fractions, :pump_monthly_multipliers]
    attr_accessor(*ATTRS)

    def delete
      @hpxml_object.pools.delete(self)
    end

    def check_for_errors
      errors = []
      return errors
    end

    def to_oga(doc)
      return if nil?

      pools = XMLHelper.create_elements_as_needed(doc, ['HPXML', 'Building', 'BuildingDetails', 'Pools'])
      pool = XMLHelper.add_element(pools, 'Pool')
      sys_id = XMLHelper.add_element(pool, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      pumps = XMLHelper.add_element(pool, 'PoolPumps')
      pool_pump = XMLHelper.add_element(pumps, 'PoolPump')
      sys_id = XMLHelper.add_element(pool_pump, 'SystemIdentifier')
      if not @pump_id.nil?
        XMLHelper.add_attribute(sys_id, 'id', @pump_id)
      else
        XMLHelper.add_attribute(sys_id, 'id', @id + 'Pump')
      end
      if not @pump_kwh_per_year.nil?
        load = XMLHelper.add_element(pool_pump, 'Load')
        XMLHelper.add_element(load, 'Units', UnitsKwhPerYear)
        XMLHelper.add_element(load, 'Value', to_float(@pump_kwh_per_year))
        HPXML::add_extension(parent: pool_pump,
                             extensions: { 'UsageMultiplier' => to_float_or_nil(@pump_usage_multiplier),
                                           'WeekdayScheduleFractions' => @pump_weekday_fractions,
                                           'WeekendScheduleFractions' => @pump_weekend_fractions,
                                           'MonthlyScheduleMultipliers' => @pump_monthly_multipliers })
      end
      if not @heater_type.nil?
        heater = XMLHelper.add_element(pool, 'Heater')
        sys_id = XMLHelper.add_element(heater, 'SystemIdentifier')
        if not @heater_id.nil?
          XMLHelper.add_attribute(sys_id, 'id', @heater_id)
        else
          XMLHelper.add_attribute(sys_id, 'id', @id + 'Heater')
        end
        XMLHelper.add_element(heater, 'Type', @heater_type)
        if (not @heater_load_units.nil?) && (not @heater_load_value.nil?)
          load = XMLHelper.add_element(heater, 'Load')
          XMLHelper.add_element(load, 'Units', @heater_load_units)
          XMLHelper.add_element(load, 'Value', to_float(@heater_load_value))
        end
        HPXML::add_extension(parent: heater,
                             extensions: { 'UsageMultiplier' => to_float_or_nil(@heater_usage_multiplier),
                                           'WeekdayScheduleFractions' => @heater_weekday_fractions,
                                           'WeekendScheduleFractions' => @heater_weekend_fractions,
                                           'MonthlyScheduleMultipliers' => @heater_monthly_multipliers })
      end
    end

    def from_oga(pool)
      @id = HPXML::get_id(pool)
      pool_pump = XMLHelper.get_element(pool, 'PoolPumps/PoolPump')
      @pump_id = HPXML::get_id(pool_pump)
      @pump_kwh_per_year = to_float_or_nil(XMLHelper.get_value(pool_pump, "Load[Units='#{UnitsKwhPerYear}']/Value"))
      @pump_usage_multiplier = to_float_or_nil(XMLHelper.get_value(pool_pump, 'extension/UsageMultiplier'))
      @pump_weekday_fractions = XMLHelper.get_value(pool_pump, 'extension/WeekdayScheduleFractions')
      @pump_weekend_fractions = XMLHelper.get_value(pool_pump, 'extension/WeekendScheduleFractions')
      @pump_monthly_multipliers = XMLHelper.get_value(pool_pump, 'extension/MonthlyScheduleMultipliers')
      heater = XMLHelper.get_element(pool, 'Heater')
      if not heater.nil?
        @heater_id = HPXML::get_id(heater)
        @heater_type = XMLHelper.get_value(heater, 'Type')
        @heater_load_units = XMLHelper.get_value(heater, 'Load/Units')
        @heater_load_value = to_float_or_nil(XMLHelper.get_value(heater, 'Load/Value'))
        @heater_usage_multiplier = to_float_or_nil(XMLHelper.get_value(heater, 'extension/UsageMultiplier'))
        @heater_weekday_fractions = XMLHelper.get_value(heater, 'extension/WeekdayScheduleFractions')
        @heater_weekend_fractions = XMLHelper.get_value(heater, 'extension/WeekendScheduleFractions')
        @heater_monthly_multipliers = XMLHelper.get_value(heater, 'extension/MonthlyScheduleMultipliers')
      end
    end
  end

  class HotTubs < BaseArrayElement
    def add(**kwargs)
      self << HotTub.new(@hpxml_object, **kwargs)
    end

    def from_oga(hpxml)
      return if hpxml.nil?

      XMLHelper.get_elements(hpxml, 'Building/BuildingDetails/HotTubs/HotTub').each do |hot_tub|
        self << HotTub.new(@hpxml_object, hot_tub)
      end
    end
  end

  class HotTub < BaseElement
    ATTRS = [:id, :heater_id, :heater_type, :heater_load_units, :heater_load_value, :heater_usage_multiplier,
             :pump_id, :pump_kwh_per_year, :pump_usage_multiplier,
             :heater_weekday_fractions, :heater_weekend_fractions, :heater_monthly_multipliers,
             :pump_weekday_fractions, :pump_weekend_fractions, :pump_monthly_multipliers]
    attr_accessor(*ATTRS)

    def delete
      @hpxml_object.hot_tubs.delete(self)
    end

    def check_for_errors
      errors = []
      return errors
    end

    def to_oga(doc)
      return if nil?

      hot_tubs = XMLHelper.create_elements_as_needed(doc, ['HPXML', 'Building', 'BuildingDetails', 'HotTubs'])
      hot_tub = XMLHelper.add_element(hot_tubs, 'HotTub')
      sys_id = XMLHelper.add_element(hot_tub, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      pumps = XMLHelper.add_element(hot_tub, 'HotTubPumps')
      hot_tub_pump = XMLHelper.add_element(pumps, 'HotTubPump')
      sys_id = XMLHelper.add_element(hot_tub_pump, 'SystemIdentifier')
      if not @pump_id.nil?
        XMLHelper.add_attribute(sys_id, 'id', @pump_id)
      else
        XMLHelper.add_attribute(sys_id, 'id', @id + 'Pump')
      end
      if not @pump_kwh_per_year.nil?
        load = XMLHelper.add_element(hot_tub_pump, 'Load')
        XMLHelper.add_element(load, 'Units', UnitsKwhPerYear)
        XMLHelper.add_element(load, 'Value', to_float(@pump_kwh_per_year))
        HPXML::add_extension(parent: hot_tub_pump,
                             extensions: { 'UsageMultiplier' => to_float_or_nil(@pump_usage_multiplier),
                                           'WeekdayScheduleFractions' => @pump_weekday_fractions,
                                           'WeekendScheduleFractions' => @pump_weekend_fractions,
                                           'MonthlyScheduleMultipliers' => @pump_monthly_multipliers })
      end
      if not @heater_type.nil?
        heater = XMLHelper.add_element(hot_tub, 'Heater')
        sys_id = XMLHelper.add_element(heater, 'SystemIdentifier')
        if not @heater_id.nil?
          XMLHelper.add_attribute(sys_id, 'id', @heater_id)
        else
          XMLHelper.add_attribute(sys_id, 'id', @id + 'Heater')
        end
        XMLHelper.add_element(heater, 'Type', @heater_type)
        if (not @heater_load_units.nil?) && (not @heater_load_value.nil?)
          load = XMLHelper.add_element(heater, 'Load')
          XMLHelper.add_element(load, 'Units', @heater_load_units)
          XMLHelper.add_element(load, 'Value', to_float(@heater_load_value))
        end
        HPXML::add_extension(parent: heater,
                             extensions: { 'UsageMultiplier' => to_float_or_nil(@heater_usage_multiplier),
                                           'WeekdayScheduleFractions' => @heater_weekday_fractions,
                                           'WeekendScheduleFractions' => @heater_weekend_fractions,
                                           'MonthlyScheduleMultipliers' => @heater_monthly_multipliers })
      end
    end

    def from_oga(hot_tub)
      @id = HPXML::get_id(hot_tub)
      hot_tub_pump = XMLHelper.get_element(hot_tub, 'HotTubPumps/HotTubPump')
      @pump_id = HPXML::get_id(hot_tub_pump)
      @pump_kwh_per_year = to_float_or_nil(XMLHelper.get_value(hot_tub_pump, "Load[Units='#{UnitsKwhPerYear}']/Value"))
      @pump_usage_multiplier = to_float_or_nil(XMLHelper.get_value(hot_tub_pump, 'extension/UsageMultiplier'))
      @pump_weekday_fractions = XMLHelper.get_value(hot_tub_pump, 'extension/WeekdayScheduleFractions')
      @pump_weekend_fractions = XMLHelper.get_value(hot_tub_pump, 'extension/WeekendScheduleFractions')
      @pump_monthly_multipliers = XMLHelper.get_value(hot_tub_pump, 'extension/MonthlyScheduleMultipliers')
      heater = XMLHelper.get_element(hot_tub, 'Heater')
      if not heater.nil?
        @heater_id = HPXML::get_id(heater)
        @heater_type = XMLHelper.get_value(heater, 'Type')
        @heater_load_units = XMLHelper.get_value(heater, 'Load/Units')
        @heater_load_value = to_float_or_nil(XMLHelper.get_value(heater, 'Load/Value'))
        @heater_usage_multiplier = to_float_or_nil(XMLHelper.get_value(heater, 'extension/UsageMultiplier'))
        @heater_weekday_fractions = XMLHelper.get_value(heater, 'extension/WeekdayScheduleFractions')
        @heater_weekend_fractions = XMLHelper.get_value(heater, 'extension/WeekendScheduleFractions')
        @heater_monthly_multipliers = XMLHelper.get_value(heater, 'extension/MonthlyScheduleMultipliers')
      end
    end
  end

  class PlugLoads < BaseArrayElement
    def add(**kwargs)
      self << PlugLoad.new(@hpxml_object, **kwargs)
    end

    def from_oga(hpxml)
      return if hpxml.nil?

      XMLHelper.get_elements(hpxml, 'Building/BuildingDetails/MiscLoads/PlugLoad').each do |plug_load|
        self << PlugLoad.new(@hpxml_object, plug_load)
      end
    end
  end

  class PlugLoad < BaseElement
    ATTRS = [:id, :plug_load_type, :kWh_per_year, :frac_sensible, :frac_latent, :usage_multiplier,
             :weekday_fractions, :weekend_fractions, :monthly_multipliers, :location]
    attr_accessor(*ATTRS)

    def delete
      @hpxml_object.plug_loads.delete(self)
    end

    def check_for_errors
      errors = []
      return errors
    end

    def to_oga(doc)
      return if nil?

      misc_loads = XMLHelper.create_elements_as_needed(doc, ['HPXML', 'Building', 'BuildingDetails', 'MiscLoads'])
      plug_load = XMLHelper.add_element(misc_loads, 'PlugLoad')
      sys_id = XMLHelper.add_element(plug_load, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_element(plug_load, 'PlugLoadType', @plug_load_type) unless @plug_load_type.nil?
      XMLHelper.add_element(plug_load, 'Location', @location) unless @location.nil?
      if not @kWh_per_year.nil?
        load = XMLHelper.add_element(plug_load, 'Load')
        XMLHelper.add_element(load, 'Units', UnitsKwhPerYear)
        XMLHelper.add_element(load, 'Value', to_float(@kWh_per_year))
      end
      HPXML::add_extension(parent: plug_load,
                           extensions: { 'FracSensible' => to_float_or_nil(@frac_sensible),
                                         'FracLatent' => to_float_or_nil(@frac_latent),
                                         'UsageMultiplier' => to_float_or_nil(@usage_multiplier),
                                         'WeekdayScheduleFractions' => @weekday_fractions,
                                         'WeekendScheduleFractions' => @weekend_fractions,
                                         'MonthlyScheduleMultipliers' => @monthly_multipliers })
    end

    def from_oga(plug_load)
      @id = HPXML::get_id(plug_load)
      @plug_load_type = XMLHelper.get_value(plug_load, 'PlugLoadType')
      @location = XMLHelper.get_value(plug_load, 'Location')
      @kWh_per_year = to_float_or_nil(XMLHelper.get_value(plug_load, "Load[Units='#{UnitsKwhPerYear}']/Value"))
      @frac_sensible = to_float_or_nil(XMLHelper.get_value(plug_load, 'extension/FracSensible'))
      @frac_latent = to_float_or_nil(XMLHelper.get_value(plug_load, 'extension/FracLatent'))
      @usage_multiplier = to_float_or_nil(XMLHelper.get_value(plug_load, 'extension/UsageMultiplier'))
      @weekday_fractions = XMLHelper.get_value(plug_load, 'extension/WeekdayScheduleFractions')
      @weekend_fractions = XMLHelper.get_value(plug_load, 'extension/WeekendScheduleFractions')
      @monthly_multipliers = XMLHelper.get_value(plug_load, 'extension/MonthlyScheduleMultipliers')
    end
  end

  class FuelLoads < BaseArrayElement
    def add(**kwargs)
      self << FuelLoad.new(@hpxml_object, **kwargs)
    end

    def from_oga(hpxml)
      return if hpxml.nil?

      XMLHelper.get_elements(hpxml, 'Building/BuildingDetails/MiscLoads/FuelLoad').each do |fuel_load|
        self << FuelLoad.new(@hpxml_object, fuel_load)
      end
    end
  end

  class FuelLoad < BaseElement
    ATTRS = [:id, :fuel_load_type, :fuel_type, :therm_per_year, :frac_sensible, :frac_latent, :usage_multiplier,
             :weekday_fractions, :weekend_fractions, :monthly_multipliers, :location]
    attr_accessor(*ATTRS)

    def delete
      @hpxml_object.fuel_loads.delete(self)
    end

    def check_for_errors
      errors = []
      return errors
    end

    def to_oga(doc)
      return if nil?

      misc_loads = XMLHelper.create_elements_as_needed(doc, ['HPXML', 'Building', 'BuildingDetails', 'MiscLoads'])
      fuel_load = XMLHelper.add_element(misc_loads, 'FuelLoad')
      sys_id = XMLHelper.add_element(fuel_load, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_element(fuel_load, 'FuelLoadType', @fuel_load_type) unless @fuel_load_type.nil?
      XMLHelper.add_element(fuel_load, 'Location', @location) unless @location.nil?
      if not @therm_per_year.nil?
        load = XMLHelper.add_element(fuel_load, 'Load')
        XMLHelper.add_element(load, 'Units', UnitsThermPerYear)
        XMLHelper.add_element(load, 'Value', to_float(@therm_per_year))
      end
      XMLHelper.add_element(fuel_load, 'FuelType', @fuel_type) unless @fuel_type.nil?
      HPXML::add_extension(parent: fuel_load,
                           extensions: { 'FracSensible' => to_float_or_nil(@frac_sensible),
                                         'FracLatent' => to_float_or_nil(@frac_latent),
                                         'UsageMultiplier' => to_float_or_nil(@usage_multiplier),
                                         'WeekdayScheduleFractions' => @weekday_fractions,
                                         'WeekendScheduleFractions' => @weekend_fractions,
                                         'MonthlyScheduleMultipliers' => @monthly_multipliers })
    end

    def from_oga(fuel_load)
      @id = HPXML::get_id(fuel_load)
      @fuel_load_type = XMLHelper.get_value(fuel_load, 'FuelLoadType')
      @location = XMLHelper.get_value(fuel_load, 'Location')
      @therm_per_year = to_float_or_nil(XMLHelper.get_value(fuel_load, "Load[Units='#{UnitsThermPerYear}']/Value"))
      @fuel_type = XMLHelper.get_value(fuel_load, 'FuelType')
      @frac_sensible = to_float_or_nil(XMLHelper.get_value(fuel_load, 'extension/FracSensible'))
      @frac_latent = to_float_or_nil(XMLHelper.get_value(fuel_load, 'extension/FracLatent'))
      @usage_multiplier = to_float_or_nil(XMLHelper.get_value(fuel_load, 'extension/UsageMultiplier'))
      @weekday_fractions = XMLHelper.get_value(fuel_load, 'extension/WeekdayScheduleFractions')
      @weekend_fractions = XMLHelper.get_value(fuel_load, 'extension/WeekendScheduleFractions')
      @monthly_multipliers = XMLHelper.get_value(fuel_load, 'extension/MonthlyScheduleMultipliers')
    end
  end

  def _create_oga_document()
    doc = XMLHelper.create_doc(version = '1.0', encoding = 'UTF-8')
    hpxml = XMLHelper.add_element(doc, 'HPXML')
    XMLHelper.add_attribute(hpxml, 'xmlns', 'http://hpxmlonline.com/2019/10')
    XMLHelper.add_attribute(hpxml, 'xmlns:xsi', 'http://www.w3.org/2001/XMLSchema-instance')
    XMLHelper.add_attribute(hpxml, 'xsi:schemaLocation', 'http://hpxmlonline.com/2019/10')
    XMLHelper.add_attribute(hpxml, 'schemaVersion', '3.0')
    return doc
  end

  def collapse_enclosure_surfaces()
    # Collapses like surfaces into a single surface with, e.g., aggregate surface area.
    # This can significantly speed up performance for HPXML files with lots of individual
    # surfaces (e.g., windows).

    surf_types = { roofs: @roofs,
                   walls: @walls,
                   rim_joists: @rim_joists,
                   foundation_walls: @foundation_walls,
                   frame_floors: @frame_floors,
                   slabs: @slabs,
                   windows: @windows,
                   skylights: @skylights,
                   doors: @doors }

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
            next if (surf_type == :foundation_walls) && (attribute == :azimuth) # Azimuth of foundation walls is irrelevant
            next if surf.send(attribute) == surf2.send(attribute)

            match = false
          end
          next unless match

          # Update values
          if (not surf.area.nil?) && (not surf2.area.nil?)
            surf.area += surf2.area
          end
          if (surf_type == :slabs) && (not surf.exposed_perimeter.nil?) && (not surf2.exposed_perimeter.nil?)
            surf.exposed_perimeter += surf2.exposed_perimeter
          end

          # Update subsurface idrefs as appropriate
          (@windows + @doors).each do |subsurf|
            next unless subsurf.wall_idref == surf2.id

            subsurf.wall_idref = surf.id
          end
          @skylights.each do |subsurf|
            next unless subsurf.roof_idref == surf2.id

            subsurf.roof_idref = surf.id
          end

          # Remove old surface
          surfaces[j].delete
        end
      end
    end
  end

  def delete_partition_surfaces()
    (@rim_joists + @walls + @foundation_walls + @frame_floors).reverse_each do |surface|
      next if surface.interior_adjacent_to.nil? || surface.exterior_adjacent_to.nil?

      if surface.interior_adjacent_to == surface.exterior_adjacent_to
        surface.delete
      elsif [surface.interior_adjacent_to, surface.exterior_adjacent_to].sort == [HPXML::LocationLivingSpace, HPXML::LocationBasementConditioned].sort
        surface.delete
      end
    end
  end

  def delete_tiny_surfaces()
    (@rim_joists + @walls + @foundation_walls + @frame_floors + @roofs + @windows + @skylights + @doors + @slabs).reverse_each do |surface|
      next if surface.area.nil? || (surface.area > 0.1)

      surface.delete
    end
  end

  def delete_adiabatic_subsurfaces()
    @doors.reverse_each do |door|
      next if door.wall.exterior_adjacent_to != HPXML::LocationOtherHousingUnit

      door.delete
    end
    @windows.reverse_each do |window|
      next if window.wall.exterior_adjacent_to != HPXML::LocationOtherHousingUnit

      window.delete
    end
  end

  def check_for_errors()
    errors = []

    # ------------------------------- #
    # Check for errors across objects #
    # ------------------------------- #

    # Check for globally unique SystemIdentifier IDs
    sys_ids = {}
    self.class::HPXML_ATTRS.each do |attribute|
      hpxml_obj = send(attribute)
      next unless hpxml_obj.is_a? HPXML::BaseArrayElement

      hpxml_obj.each do |obj|
        next unless obj.respond_to? :id

        sys_ids[obj.id] = 0 if sys_ids[obj.id].nil?
        sys_ids[obj.id] += 1
      end
    end
    sys_ids.each do |sys_id, cnt|
      errors << "Duplicate SystemIdentifier IDs detected for '#{sys_id}'." if cnt > 1
    end

    # Check sum of HVAC FractionCoolLoadServeds <= 1
    frac_cool_load = (@cooling_systems + @heat_pumps).map { |hvac| hvac.fraction_cool_load_served }.inject(0, :+)
    if frac_cool_load > 1.01 # Use 1.01 in case of rounding
      errors << "Expected FractionCoolLoadServed to sum to <= 1, but calculated sum is #{frac_cool_load.round(2)}."
    end

    # Check sum of HVAC FractionHeatLoadServeds <= 1
    frac_heat_load = (@heating_systems + @heat_pumps).map { |hvac| hvac.fraction_heat_load_served }.inject(0, :+)
    if frac_heat_load > 1.01 # Use 1.01 in case of rounding
      errors << "Expected FractionHeatLoadServed to sum to <= 1, but calculated sum is #{frac_heat_load.round(2)}."
    end

    # Check sum of HVAC FractionDHWLoadServed == 1
    frac_dhw_load = @water_heating_systems.map { |dhw| dhw.fraction_dhw_load_served }.inject(0, :+)
    if (frac_dhw_load > 0) && ((frac_dhw_load < 0.99) || (frac_dhw_load > 1.01)) # Use 0.99/1.01 in case of rounding
      errors << "Expected FractionDHWLoadServed to sum to 1, but calculated sum is #{frac_dhw_load.round(2)}."
    end

    # Check sum of lighting fractions in a location <= 1
    ltg_fracs = {}
    @lighting_groups.each do |lighting_group|
      next if lighting_group.location.nil? || lighting_group.fraction_of_units_in_location.nil?

      ltg_fracs[lighting_group.location] = 0 if ltg_fracs[lighting_group.location].nil?
      ltg_fracs[lighting_group.location] += lighting_group.fraction_of_units_in_location
    end
    ltg_fracs.each do |location, sum|
      next if sum <= 1

      fail "Sum of fractions of #{location} lighting (#{sum}) is greater than 1."
    end

    # Check for HVAC systems referenced by multiple water heating systems
    (@heating_systems + @cooling_systems + @heat_pumps).each do |hvac_system|
      num_attached = 0
      @water_heating_systems.each do |water_heating_system|
        next if water_heating_system.related_hvac_idref.nil?
        next unless hvac_system.id == water_heating_system.related_hvac_idref

        num_attached += 1
      end
      next if num_attached <= 1

      errors << "RelatedHVACSystem '#{hvac_system.id}' is attached to multiple water heating systems."
    end

    # Check for the sum of CFA served by distribution systems <= CFA
    air_distributions = @hvac_distributions.select { |dist| dist if dist.distribution_system_type == HPXML::HVACDistributionTypeAir }
    heating_dist = []
    cooling_dist = []
    air_distributions.each do |dist|
      heating_systems = dist.hvac_systems.select { |sys| sys if (sys.respond_to? :fraction_heat_load_served) && (sys.fraction_heat_load_served > 0) }
      cooling_systems = dist.hvac_systems.select { |sys| sys if (sys.respond_to? :fraction_cool_load_served) && (sys.fraction_cool_load_served > 0) }
      if heating_systems.size > 0
        heating_dist << dist
      end
      if cooling_systems.size > 0
        cooling_dist << dist
      end
    end
    heating_total_dist_cfa_served = heating_dist.map { |htg_dist| htg_dist.conditioned_floor_area_served.to_f }.inject(0, :+)
    cooling_total_dist_cfa_served = cooling_dist.map { |clg_dist| clg_dist.conditioned_floor_area_served.to_f }.inject(0, :+)
    if (heating_total_dist_cfa_served > @building_construction.conditioned_floor_area.to_f)
      errors << 'The total conditioned floor area served by the HVAC distribution system(s) for heating is larger than the conditioned floor area of the building.'
    end
    if (cooling_total_dist_cfa_served > @building_construction.conditioned_floor_area.to_f)
      errors << 'The total conditioned floor area served by the HVAC distribution system(s) for cooling is larger than the conditioned floor area of the building.'
    end

    # ------------------------------- #
    # Check for errors within objects #
    # ------------------------------- #

    # Ask objects to check for errors
    self.class::HPXML_ATTRS.each do |attribute|
      hpxml_obj = send(attribute)
      if not hpxml_obj.respond_to? :check_for_errors
        fail "Need to add 'check_for_errors' method to #{hpxml_obj.class} class."
      end

      errors += hpxml_obj.check_for_errors
    end

    return errors
  end

  def self.is_thermal_boundary(surface)
    # Returns true if the surface is between conditioned space and outside/ground/unconditioned space.
    # Note: Insulated foundation walls of, e.g., unconditioned spaces return false.
    def self.is_adjacent_to_conditioned(adjacent_to)
      if [HPXML::LocationLivingSpace,
          HPXML::LocationBasementConditioned].include? adjacent_to
        return true
      end

      return false
    end

    if surface.exterior_adjacent_to == HPXML::LocationOtherHousingUnit
      return false # adiabatic
    end

    interior_conditioned = is_adjacent_to_conditioned(surface.interior_adjacent_to)
    exterior_conditioned = is_adjacent_to_conditioned(surface.exterior_adjacent_to)
    return (interior_conditioned != exterior_conditioned)
  end

  def self.get_id(parent, element_name = 'SystemIdentifier')
    return XMLHelper.get_attribute_value(XMLHelper.get_element(parent, element_name), 'id')
  end

  def self.get_idref(element)
    return XMLHelper.get_attribute_value(element, 'idref')
  end

  def self.add_extension(parent:,
                         extensions: {})
    extension = nil
    if not extensions.empty?
      extensions.each do |name, value|
        next if value.nil?

        extension = XMLHelper.get_element(parent, 'extension')
        if extension.nil?
          extension = XMLHelper.add_element(parent, 'extension')
        end
        XMLHelper.add_element(extension, "#{name}", value) unless value.nil?
      end
    end

    return extension
  end
end

def to_float(value)
  begin
    return Float(value)
  rescue
    fail "Cannot convert '#{value}' to float."
  end
end

def to_integer(value)
  begin
    value = Float(value)
  rescue
    fail "Cannot convert '#{value}' to integer."
  end
  if value % 1 == 0
    return Integer(value)
  else
    fail "Cannot convert '#{value}' to integer."
  end
end

def to_boolean(value)
  if value.is_a? TrueClass
    return true
  elsif value.is_a? FalseClass
    return false
  elsif (value.downcase.to_s == 'true') || (value == '1') || (value == 1)
    return true
  elsif (value.downcase.to_s == 'false') || (value == '0') || (value == 0)
    return false
  end

  fail "Cannot convert '#{value}' to boolean."
end

def to_float_or_nil(value)
  return if value.nil?

  return to_float(value)
end

def to_integer_or_nil(value)
  return if value.nil?

  return to_integer(value)
end

def to_bool_or_nil(value)
  return if value.nil?

  return to_boolean(value)
end
