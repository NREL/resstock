# frozen_string_literal: true

require 'ostruct'

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
XMLHelper.write_file(hpxml.to_doc, "out.xml")

'''

# FUTURE: Remove all idref attributes, make object attributes instead
#         E.g., in class Window, :wall_idref => :wall

class HPXML < Object
  HPXML_ATTRS = [:header, :buildings]
  attr_reader(*HPXML_ATTRS, :doc, :errors, :warnings, :hpxml_path)

  NameSpace = 'http://hpxmlonline.com/2023/09'

  # Constants
  FuelElementNames = ['HeatingSystemFuel', 'CoolingSystemFuel', 'HeatPumpFuel', 'BackupSystemFuel', 'FuelType', 'IntegratedHeatingSystemFuel', 'Heater/Type']

  # FUTURE: Move some of these to within child classes (e.g., HPXML::Attic class)
  AirTypeFanCoil = 'fan coil'
  AirTypeGravity = 'gravity'
  AirTypeHighVelocity = 'high velocity'
  AirTypeRegularVelocity = 'regular velocity'
  AtticTypeBelowApartment = 'BelowApartment'
  AtticTypeCathedral = 'CathedralCeiling'
  AtticTypeConditioned = 'ConditionedAttic'
  AtticTypeFlatRoof = 'FlatRoof'
  AtticTypeUnvented = 'UnventedAttic'
  AtticTypeVented = 'VentedAttic'
  AtticWallTypeGable = 'gable'
  AtticWallTypeKneeWall = 'knee wall'
  BatteryTypeLithiumIon = 'Li-ion'
  BatteryLifetimeModelNone = 'None'
  BatteryLifetimeModelKandlerSmith = 'KandlerSmith'
  BuildingAmerica = 'BuildingAmerica'
  CapacityDescriptionMinimum = 'minimum'
  CapacityDescriptionMaximum = 'maximum'
  CertificationEnergyStar = 'Energy Star'
  ClothesDryerControlTypeMoisture = 'moisture'
  ClothesDryerControlTypeTimer = 'timer'
  CFISModeAirHandler = 'air handler fan'
  CFISModeNone = 'none'
  CFISModeSupplementalFan = 'supplemental fan'
  ColorDark = 'dark'
  ColorLight = 'light'
  ColorMedium = 'medium'
  ColorMediumDark = 'medium dark'
  ColorReflective = 'reflective'
  DehumidifierTypePortable = 'portable'
  DehumidifierTypeWholeHome = 'whole-home'
  DuctBuriedInsulationNone = 'not buried'
  DuctBuriedInsulationPartial = 'partially buried'
  DuctBuriedInsulationFull = 'fully buried'
  DuctBuriedInsulationDeep = 'deeply buried'
  DHWRecircControlTypeManual = 'manual demand control'
  DHWRecircControlTypeNone = 'no control'
  DHWRecircControlTypeSensor = 'presence sensor demand control'
  DHWRecircControlTypeTemperature = 'temperature'
  DHWRecircControlTypeTimer = 'timer'
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
  ExteriorShadingTypeSolarScreens = 'solar screens'
  FoundationTypeAboveApartment = 'AboveApartment'
  FoundationTypeAmbient = 'Ambient'
  FoundationTypeBasementConditioned = 'ConditionedBasement'
  FoundationTypeBasementUnconditioned = 'UnconditionedBasement'
  FoundationTypeCrawlspaceConditioned = 'ConditionedCrawlspace'
  FoundationTypeCrawlspaceUnvented = 'UnventedCrawlspace'
  FoundationTypeCrawlspaceVented = 'VentedCrawlspace'
  FoundationTypeBellyAndWing = 'BellyAndWing'
  FoundationTypeSlab = 'SlabOnGrade'
  FoundationWallTypeConcreteBlock = 'concrete block'
  FoundationWallTypeConcreteBlockFoamCore = 'concrete block foam core'
  FoundationWallTypeConcreteBlockPerliteCore = 'concrete block perlite core'
  FoundationWallTypeConcreteBlockSolidCore = 'concrete block solid core'
  FoundationWallTypeConcreteBlockVermiculiteCore = 'concrete block vermiculite core'
  FoundationWallTypeDoubleBrick = 'double brick'
  FoundationWallTypeSolidConcrete = 'solid concrete'
  FoundationWallTypeWood = 'wood'
  FloorOrCeilingCeiling = 'ceiling'
  FloorOrCeilingFloor = 'floor'
  FloorTypeWoodFrame = 'WoodFrame'
  FloorTypeSIP = 'StructuralInsulatedPanel'
  FloorTypeSteelFrame = 'SteelFrame'
  FloorTypeConcrete = 'SolidConcrete'
  FuelLoadTypeFireplace = 'fireplace'
  FuelLoadTypeGrill = 'grill'
  FuelLoadTypeLighting = 'lighting'
  FuelLoadTypeOther = 'other'
  FuelTypeCoal = 'coal'
  FuelTypeCoalAnthracite = 'anthracite coal'
  FuelTypeCoalBituminous = 'bituminous coal'
  FuelTypeCoke = 'coke'
  FuelTypeDiesel = 'diesel'
  FuelTypeElectricity = 'electricity'
  FuelTypeKerosene = 'kerosene'
  FuelTypeNaturalGas = 'natural gas'
  FuelTypeOil = 'fuel oil'
  FuelTypeOil1 = 'fuel oil 1'
  FuelTypeOil2 = 'fuel oil 2'
  FuelTypeOil4 = 'fuel oil 4'
  FuelTypeOil5or6 = 'fuel oil 5/6'
  FuelTypePropane = 'propane'
  FuelTypeWoodCord = 'wood'
  FuelTypeWoodPellets = 'wood pellets'
  FurnitureMassTypeLightWeight = 'light-weight'
  FurnitureMassTypeHeavyWeight = 'heavy-weight'
  GeothermalLoopBorefieldConfigurationRectangle = 'Rectangle'
  GeothermalLoopBorefieldConfigurationZonedRectangle = 'Zoned Rectangle'
  GeothermalLoopBorefieldConfigurationOpenRectangle = 'Open Rectangle'
  GeothermalLoopBorefieldConfigurationC = 'C'
  GeothermalLoopBorefieldConfigurationL = 'L'
  GeothermalLoopBorefieldConfigurationU = 'U'
  GeothermalLoopBorefieldConfigurationLopsidedU = 'Lopsided U'
  GeothermalLoopLoopConfigurationDiagonal = 'diagonal'
  GeothermalLoopLoopConfigurationHorizontal = 'horizontal'
  GeothermalLoopLoopConfigurationOther = 'other'
  GeothermalLoopLoopConfigurationVertical = 'vertical'
  GeothermalLoopGroutOrPipeTypeStandard = 'standard'
  GeothermalLoopGroutOrPipeTypeThermallyEnhanced = 'thermally enhanced'
  HeaterTypeElectricResistance = 'electric resistance'
  HeaterTypeGas = 'gas fired'
  HeaterTypeHeatPump = 'heat pump'
  HeatPumpBackupTypeIntegrated = 'integrated'
  HeatPumpBackupTypeSeparate = 'separate'
  HeatPumpSizingACCA = 'ACCA'
  HeatPumpSizingHERS = 'HERS'
  HeatPumpSizingMaxLoad = 'MaxLoad'
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
  HVACTypeChiller = 'chiller'
  HVACTypeCoolingTower = 'cooling tower'
  HVACTypeElectricResistance = 'ElectricResistance'
  HVACTypeEvaporativeCooler = 'evaporative cooler'
  HVACTypeFireplace = 'Fireplace'
  HVACTypeFloorFurnace = 'FloorFurnace'
  HVACTypeFurnace = 'Furnace'
  HVACTypeHeatPumpAirToAir = 'air-to-air'
  HVACTypeHeatPumpGroundToAir = 'ground-to-air'
  HVACTypeHeatPumpMiniSplit = 'mini-split'
  HVACTypeHeatPumpWaterLoopToAir = 'water-loop-to-air'
  HVACTypeHeatPumpPTHP = 'packaged terminal heat pump'
  HVACTypeHeatPumpRoom = 'room air conditioner with reverse cycle'
  HVACTypeMiniSplitAirConditioner = 'mini-split'
  HVACTypePTAC = 'packaged terminal air conditioner'
  HVACTypeRoomAirConditioner = 'room air conditioner'
  HVACTypeSpaceHeater = 'SpaceHeater'
  HVACTypeStove = 'Stove'
  HVACTypeWallFurnace = 'WallFurnace'
  HydronicTypeBaseboard = 'baseboard'
  HydronicTypeRadiantCeiling = 'radiant ceiling'
  HydronicTypeRadiantFloor = 'radiant floor'
  HydronicTypeRadiator = 'radiator'
  HydronicTypeWaterLoop = 'water loop'
  InteriorFinishGypsumBoard = 'gypsum board'
  InteriorFinishGypsumCompositeBoard = 'gypsum composite board'
  InteriorFinishNone = 'none'
  InteriorFinishPlaster = 'plaster'
  InteriorFinishWood = 'wood'
  InfiltrationTypeUnitTotal = 'unit total'
  InfiltrationTypeUnitExterior = 'unit exterior only'
  LeakinessTight = 'tight'
  LeakinessAverage = 'average'
  LightingTypeCFL = 'CompactFluorescent'
  LightingTypeLED = 'LightEmittingDiode'
  LightingTypeLFL = 'FluorescentTube'
  LocationAttic = 'attic'
  LocationAtticUnconditioned = 'attic - unconditioned'
  LocationAtticUnvented = 'attic - unvented'
  LocationAtticVented = 'attic - vented'
  LocationBasementConditioned = 'basement - conditioned'
  LocationBasementUnconditioned = 'basement - unconditioned'
  LocationBath = 'bath'
  LocationConditionedSpace = 'conditioned space'
  LocationCrawlspace = 'crawlspace'
  LocationCrawlspaceConditioned = 'crawlspace - conditioned'
  LocationCrawlspaceUnvented = 'crawlspace - unvented'
  LocationCrawlspaceVented = 'crawlspace - vented'
  LocationExterior = 'exterior'
  LocationExteriorWall = 'exterior wall'
  LocationGarage = 'garage'
  LocationGround = 'ground'
  LocationInterior = 'interior'
  LocationKitchen = 'kitchen'
  LocationManufacturedHomeBelly = 'manufactured home belly'
  LocationManufacturedHomeUnderBelly = 'manufactured home underbelly'
  LocationOtherExterior = 'other exterior'
  LocationOtherHousingUnit = 'other housing unit'
  LocationOtherHeatedSpace = 'other heated space'
  LocationOtherMultifamilyBufferSpace = 'other multifamily buffer space'
  LocationOtherNonFreezingSpace = 'other non-freezing space'
  LocationOutside = 'outside'
  LocationRoof = 'roof'
  LocationRoofDeck = 'roof deck'
  LocationUnconditionedSpace = 'unconditioned space'
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
  PlugLoadTypeAquarium = 'aquarium'
  PlugLoadTypeComputer = 'computer'
  PlugLoadTypeElectricVehicleCharging = 'electric vehicle charging'
  PlugLoadTypeOther = 'other'
  PlugLoadTypeSauna = 'sauna'
  PlugLoadTypeSpaceHeater = 'space heater'
  PlugLoadTypeTelevision = 'TV other'
  PlugLoadTypeTelevisionCRT = 'TV CRT'
  PlugLoadTypeTelevisionPlasma = 'TV plasma'
  PlugLoadTypeWaterBed = 'water bed'
  PlugLoadTypeWellPump = 'well pump'
  PVAnnualExcessSellbackRateTypeRetailElectricityCost = 'Retail Electricity Cost'
  PVAnnualExcessSellbackRateTypeUserSpecified = 'User-Specified'
  PVCompensationTypeFeedInTariff = 'FeedInTariff'
  PVCompensationTypeNetMetering = 'NetMetering'
  PVModuleTypePremium = 'premium'
  PVModuleTypeStandard = 'standard'
  PVModuleTypeThinFilm = 'thin film'
  PVTrackingTypeFixed = 'fixed'
  PVTrackingType1Axis = '1-axis'
  PVTrackingType1AxisBacktracked = '1-axis backtracked'
  PVTrackingType2Axis = '2-axis'
  RadiantBarrierLocationAtticRoofOnly = 'Attic roof only'
  RadiantBarrierLocationAtticRoofAndGableWalls = 'Attic roof and gable walls'
  RadiantBarrierLocationAtticFloor = 'Attic floor'
  ResidentialTypeApartment = 'apartment unit'
  ResidentialTypeManufactured = 'manufactured home'
  ResidentialTypeSFA = 'single-family attached'
  ResidentialTypeSFD = 'single-family detached'
  RoofTypeAsphaltShingles = 'asphalt or fiberglass shingles'
  RoofTypeConcrete = 'concrete'
  RoofTypeCool = 'cool roof'
  RoofTypeClayTile = 'slate or tile shingles'
  RoofTypeEPS = 'expanded polystyrene sheathing'
  RoofTypeMetal = 'metal surfacing'
  RoofTypePlasticRubber = 'plastic/rubber/synthetic sheeting'
  RoofTypeShingles = 'shingles'
  RoofTypeWoodShingles = 'wood shingles or shakes'
  ScheduleRegular = 'regular schedule'
  ScheduleAvailable = 'always available'
  ScheduleUnavailable = 'always unavailable'
  ShieldingExposed = 'exposed'
  ShieldingNormal = 'normal'
  ShieldingWellShielded = 'well-shielded'
  SidingTypeAluminum = 'aluminum siding'
  SidingTypeAsbestos = 'asbestos siding'
  SidingTypeBrick = 'brick veneer'
  SidingTypeCompositeShingle = 'composite shingle siding'
  SidingTypeFiberCement = 'fiber cement siding'
  SidingTypeMasonite = 'masonite siding'
  SidingTypeNone = 'none'
  SidingTypeStucco = 'stucco'
  SidingTypeSyntheticStucco = 'synthetic stucco'
  SidingTypeVinyl = 'vinyl siding'
  SidingTypeWood = 'wood siding'
  SiteSoilMoistureTypeDry = 'dry'
  SiteSoilMoistureTypeMixed = 'mixed'
  SiteSoilMoistureTypeWet = 'wet'
  SiteSoilTypeClay = 'clay'
  SiteSoilTypeGravel = 'gravel'
  SiteSoilTypeLoam = 'loam'
  SiteSoilTypeOther = 'other'
  SiteSoilTypeSand = 'sand'
  SiteSoilTypeSilt = 'silt'
  SiteSoilTypeUnknown = 'unknown'
  SiteTypeUrban = 'urban'
  SiteTypeSuburban = 'suburban'
  SiteTypeRural = 'rural'
  SolarThermalLoopTypeDirect = 'liquid direct'
  SolarThermalLoopTypeIndirect = 'liquid indirect'
  SolarThermalLoopTypeThermosyphon = 'passive thermosyphon'
  SolarThermalSystemType = 'hot water'
  SolarThermalTypeDoubleGlazing = 'double glazing black'
  SolarThermalTypeEvacuatedTube = 'evacuated tube'
  SolarThermalTypeICS = 'integrated collector storage'
  SolarThermalTypeSingleGlazing = 'single glazing black'
  SurroundingsOneSide = 'attached on one side'
  SurroundingsTwoSides = 'attached on two sides'
  SurroundingsThreeSides = 'attached on three sides'
  SurroundingsStandAlone = 'stand-alone'
  TypeNone = 'none'
  TypeUnknown = 'unknown'
  UnitsACH = 'ACH'
  UnitsACHNatural = 'ACHnatural'
  UnitsAFUE = 'AFUE'
  UnitsAh = 'Ah'
  UnitsBtuPerHour = 'Btu/hr'
  UnitsCFM = 'CFM'
  UnitsCFM25 = 'CFM25'
  UnitsCFM50 = 'CFM50'
  UnitsCFMNatural = 'CFMnatural'
  UnitsCOP = 'COP'
  UnitsDegFPerHour = 'F/hr'
  UnitsDollars = '$'
  UnitsDollarsPerkW = '$/kW'
  UnitsEER = 'EER'
  UnitsELA = 'EffectiveLeakageArea'
  UnitsCEER = 'CEER'
  UnitsHSPF = 'HSPF'
  UnitsHSPF2 = 'HSPF2'
  UnitsKwh = 'kWh'
  UnitsKwhPerYear = 'kWh/year'
  UnitsKwhPerDay = 'kWh/day'
  UnitsKwPerTon = 'kW/ton'
  UnitsPercent = 'Percent'
  UnitsPercentPerHour = '%/hr'
  UnitsSEER = 'SEER'
  UnitsSEER2 = 'SEER2'
  UnitsSLA = 'SLA'
  UnitsThermPerYear = 'therm/year'
  VerticalSurroundingsNoAboveOrBelow = 'no units above or below'
  VerticalSurroundingsAboveAndBelow = 'unit above and below'
  VerticalSurroundingsBelow = 'unit below'
  VerticalSurroundingsAbove = 'unit above'
  WallTypeAdobe = 'Adobe'
  WallTypeBrick = 'StructuralBrick'
  WallTypeCMU = 'ConcreteMasonryUnit'
  WallTypeConcrete = 'SolidConcrete'
  WallTypeDoubleWoodStud = 'DoubleWoodStud'
  WallTypeICF = 'InsulatedConcreteForms'
  WallTypeLog = 'LogWall'
  WallTypeSIP = 'StructuralInsulatedPanel'
  WallTypeSteelStud = 'SteelFrame'
  WallTypeStone = 'Stone'
  WallTypeStrawBale = 'StrawBale'
  WallTypeWoodStud = 'WoodStud'
  WaterFixtureTypeFaucet = 'faucet'
  WaterFixtureTypeShowerhead = 'shower head'
  WaterHeaterOperatingModeHybridAuto = 'hybrid/auto'
  WaterHeaterOperatingModeHeatPumpOnly = 'heat pump only'
  WaterHeaterTankModelTypeMixed = 'mixed'
  WaterHeaterTankModelTypeStratified = 'stratified'
  WaterHeaterTypeCombiStorage = 'space-heating boiler with storage tank'
  WaterHeaterTypeCombiTankless = 'space-heating boiler with tankless coil'
  WaterHeaterTypeHeatPump = 'heat pump water heater'
  WaterHeaterTypeTankless = 'instantaneous water heater'
  WaterHeaterTypeStorage = 'storage water heater'
  WaterHeaterUsageBinVerySmall = 'very small'
  WaterHeaterUsageBinLow = 'low'
  WaterHeaterUsageBinMedium = 'medium'
  WaterHeaterUsageBinHigh = 'high'
  WindowFrameTypeAluminum = 'Aluminum'
  WindowFrameTypeComposite = 'Composite'
  WindowFrameTypeFiberglass = 'Fiberglass'
  WindowFrameTypeMetal = 'Metal'
  WindowFrameTypeVinyl = 'Vinyl'
  WindowFrameTypeWood = 'Wood'
  WindowGasAir = 'air'
  WindowGasArgon = 'argon'
  WindowGasKrypton = 'krypton'
  WindowGasNitrogen = 'nitrogen'
  WindowGasOther = 'other'
  WindowGasXenon = 'xenon'
  WindowGlassTypeClear = 'clear'
  WindowGlassTypeLowE = 'low-e'
  WindowGlassTypeLowEHighSolarGain = 'low-e, high-solar-gain'
  WindowGlassTypeLowELowSolarGain = 'low-e, low-solar-gain'
  WindowGlassTypeReflective = 'reflective'
  WindowGlassTypeTinted = 'tinted'
  WindowGlassTypeTintedReflective = 'tinted/reflective'
  WindowLayersDoublePane = 'double-pane'
  WindowLayersGlassBlock = 'glass block'
  WindowLayersSinglePane = 'single-pane'
  WindowLayersTriplePane = 'triple-pane'
  WindowClassArchitectural = 'architectural'
  WindowClassCommercial = 'commercial'
  WindowClassHeavyCommercial = 'heavy commercial'
  WindowClassResidential = 'residential'
  WindowClassLightCommercial = 'light commercial'

  def initialize(hpxml_path: nil, schema_validator: nil, schematron_validator: nil, building_id: nil)
    @hpxml_path = hpxml_path
    @errors = []
    @warnings = []
    building_id = nil if building_id.to_s.empty?

    hpxml_doc = nil
    if not hpxml_path.nil?
      doc = XMLHelper.parse_file(hpxml_path)

      # Validate against XSD schema
      if not schema_validator.nil?
        xsd_errors, xsd_warnings = XMLValidator.validate_against_schema(hpxml_path, schema_validator)
        @errors += xsd_errors
        @warnings += xsd_warnings
        return unless @errors.empty?
      end

      # Check HPXML version
      hpxml_doc = XMLHelper.get_element(doc, '/HPXML')
      Version.check_hpxml_version(XMLHelper.get_attribute_value(hpxml_doc, 'schemaVersion'))

      # Get value of WholeSFAorMFBuildingSimulation element
      whole_sfa_or_mf_building_sim = XMLHelper.get_value(hpxml_doc, 'SoftwareInfo/extension/WholeSFAorMFBuildingSimulation', :boolean)
      whole_sfa_or_mf_building_sim = false if whole_sfa_or_mf_building_sim.nil?
      has_mult_building_elements = XMLHelper.get_elements(hpxml_doc, 'Building').size > 1
      if has_mult_building_elements
        if building_id.nil? && !whole_sfa_or_mf_building_sim
          @errors << 'Multiple Building elements defined in HPXML file; provide Building ID argument or set WholeSFAorMFBuildingSimulation=true.'
          return unless @errors.empty?
        elsif whole_sfa_or_mf_building_sim && (not building_id.nil?)
          @warnings << 'Multiple Building elements defined in HPXML file and WholeSFAorMFBuildingSimulation=true; Building ID argument will be ignored.'
          building_id = nil
        end
      end

      # Handle multiple buildings
      # Do this before schematron validation so that:
      # 1. We don't give schematron warnings for Building elements that are not of interest.
      # 2. The schematron validation occurs faster (as we're only validating one Building).
      if has_mult_building_elements && (not building_id.nil?)
        # Discard all Building elements except the one of interest
        XMLHelper.get_elements(hpxml_doc, 'Building').reverse_each do |building|
          next if XMLHelper.get_attribute_value(XMLHelper.get_element(building, 'BuildingID'), 'id') == building_id

          building.remove
        end
        if XMLHelper.get_elements(hpxml_doc, 'Building').size == 0
          @errors << "Could not find Building element with ID '#{building_id}'."
          return unless @errors.empty?
        end

        # Write new HPXML file with all other Building elements removed
        hpxml_path = Tempfile.new(['hpxml', '.xml']).path.to_s
        XMLHelper.write_file(hpxml_doc, hpxml_path)
      end

      # Validate against Schematron
      if not schematron_validator.nil?
        sct_errors, sct_warnings = XMLValidator.validate_against_schematron(hpxml_path, schematron_validator, hpxml_doc)
        @errors += sct_errors
        @warnings += sct_warnings
        return unless @errors.empty?
      end
    end

    # Create/populate child objects
    from_doc(hpxml_doc)

    # Check for additional errors (those hard to check via Schematron)
    @errors += header.check_for_errors
    @buildings.each do |_building|
      @errors += buildings.check_for_errors()
    end
    @errors.map! { |e| "#{hpxml_path}: #{e}" }
    return unless @errors.empty?
  end

  def to_doc()
    doc = _create_hpxml_document()
    @header.to_doc(doc)
    @buildings.to_doc(doc)
    return doc
  end

  def from_doc(hpxml)
    @header = Header.new(self, hpxml)
    @buildings = Buildings.new(self, hpxml)
  end

  def set_unique_hpxml_ids(hpxml_doc, last_building_only = false)
    buildings = XMLHelper.get_elements(hpxml_doc, '/HPXML/Building')

    # Make all IDs unique so the HPXML is valid
    buildings.each_with_index do |building, i|
      next if last_building_only && (i != buildings.size - 1)

      bldg_no = "_#{i + 1}"
      building.each_node do |node|
        next unless node.is_a?(Oga::XML::Element)

        if not XMLHelper.get_attribute_value(node, 'id').nil?
          XMLHelper.add_attribute(node, 'id', "#{XMLHelper.get_attribute_value(node, 'id')}#{bldg_no}")
        elsif not XMLHelper.get_attribute_value(node, 'idref').nil?
          XMLHelper.add_attribute(node, 'idref', "#{XMLHelper.get_attribute_value(node, 'idref')}#{bldg_no}")
        end
      end
    end
  end

  def has_fuels(fuels_array, hpxml_doc, building_id = nil)
    # Returns a hash with whether each fuel in fuels_array exists
    # across all the buildings
    has_fuels = {}
    fuels_array.each do |fuel|
      has_fuels[fuel] = false
      FuelElementNames.each do |fuel_element_name|
        if fuel_element_name == 'Heater/Type' && fuel == HPXML::FuelTypeNaturalGas
          fuel_element_value = HPXML::HeaterTypeGas
        else
          fuel_element_value = fuel
        end
        search_str = "/HPXML/Building[BuildingID/@id='#{building_id}']//#{fuel_element_name}[text() = '#{fuel_element_value}']"
        if building_id.nil?
          search_str = "/HPXML/Building//#{fuel_element_name}[text() = '#{fuel_element_value}']"
        end
        if XMLHelper.has_element(hpxml_doc, search_str)
          has_fuels[fuel] = true
          break
        end
      end
    end

    return has_fuels
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
    attr_accessor(:parent_object, :additional_properties)

    def initialize(parent_object, hpxml_element = nil, **kwargs)
      @parent_object = parent_object
      @additional_properties = AdditionalProperties.new

      # Automatically add :foo_isdefaulted attributes to class
      self.class::ATTRS.each do |attribute|
        next if attribute.to_s.end_with? '_isdefaulted'

        attr = "#{attribute}_isdefaulted".to_sym
        next if self.class::ATTRS.include? attr

        # Add attribute to ATTRS and class
        self.class::ATTRS << attr
        create_attr(attr.to_s) # From https://stackoverflow.com/a/4082937
      end

      if not hpxml_element.nil?
        # Set values from HPXML element
        from_doc(hpxml_element)
      else
        # Set values from **kwargs
        kwargs.each do |k, v|
          send(k.to_s + '=', v)
        end
      end
    end

    def create_method(name, &block)
      self.class.send(:define_method, name, &block)
    end

    def create_attr(name)
      create_method("#{name}=".to_sym) { |val| instance_variable_set('@' + name, val) }
      create_method(name.to_sym) { instance_variable_get('@' + name) }
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
        next if k.to_s.end_with? '_isdefaulted'
        return false if not v.nil?
      end
      return true
    end
  end

  # HPXML Array Element (e.g., Roofs)
  class BaseArrayElement < Array
    attr_accessor(:parent_object, :additional_properties)

    def initialize(parent_object, hpxml_element = nil)
      @parent_object = parent_object
      @additional_properties = AdditionalProperties.new

      if not hpxml_element.nil?
        # Set values from HPXML element
        from_doc(hpxml_element)
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

    def to_doc(doc)
      each do |child|
        child.to_doc(doc)
      end
    end

    def to_s
      return map { |x| x.to_s }
    end
  end

  class Header < BaseElement
    def initialize(hpxml_object, *args)
      @emissions_scenarios = EmissionsScenarios.new(hpxml_object)
      @utility_bill_scenarios = UtilityBillScenarios.new(hpxml_object)
      @unavailable_periods = UnavailablePeriods.new(hpxml_object)
      super(hpxml_object, *args)
    end
    ATTRS = [:xml_type, :xml_generated_by, :created_date_and_time, :transaction, :software_program_used,
             :software_program_version, :apply_ashrae140_assumptions, :temperature_capacitance_multiplier, :timestep,
             :sim_begin_month, :sim_begin_day, :sim_end_month, :sim_end_day, :sim_calendar_year,
             :eri_calculation_version, :co2index_calculation_version, :energystar_calculation_version,
             :iecc_eri_calculation_version, :zerh_calculation_version, :whole_sfa_or_mf_building_sim]
    attr_accessor(*ATTRS)
    attr_reader(:emissions_scenarios)
    attr_reader(:utility_bill_scenarios)
    attr_reader(:unavailable_periods)

    def check_for_errors
      errors = []

      errors += HPXML::check_dates('Run Period', @sim_begin_month, @sim_begin_day, @sim_end_month, @sim_end_day)

      if (not @sim_begin_month.nil?) && (not @sim_end_month.nil?)
        if @sim_begin_month > @sim_end_month
          errors << "Run Period Begin Month (#{@sim_begin_month}) cannot come after Run Period End Month (#{@sim_end_month})."
        end

        if (not @sim_begin_day.nil?) && (not @sim_end_day.nil?)
          if @sim_begin_month == @sim_end_month && @sim_begin_day > @sim_end_day
            errors << "Run Period Begin Day of Month (#{@sim_begin_day}) cannot come after Run Period End Day of Month (#{@sim_end_day}) for the same month (#{begin_month})."
          end
        end
      end

      errors += @emissions_scenarios.check_for_errors
      errors += @utility_bill_scenarios.check_for_errors
      errors += @unavailable_periods.check_for_errors

      return errors
    end

    def to_doc(doc)
      return if nil?

      hpxml = XMLHelper.get_element(doc, '/HPXML')
      header = XMLHelper.add_element(hpxml, 'XMLTransactionHeaderInformation')
      XMLHelper.add_element(header, 'XMLType', @xml_type, :string)
      XMLHelper.add_element(header, 'XMLGeneratedBy', @xml_generated_by, :string)
      if not @created_date_and_time.nil?
        XMLHelper.add_element(header, 'CreatedDateAndTime', @created_date_and_time, :string)
      else
        XMLHelper.add_element(header, 'CreatedDateAndTime', Time.now.strftime('%Y-%m-%dT%H:%M:%S%:z'), :string)
      end
      XMLHelper.add_element(header, 'Transaction', @transaction, :string)

      software_info = XMLHelper.add_element(hpxml, 'SoftwareInfo')
      XMLHelper.add_element(software_info, 'SoftwareProgramUsed', @software_program_used, :string) unless @software_program_used.nil?
      XMLHelper.add_element(software_info, 'SoftwareProgramVersion', @software_program_version, :string) unless @software_program_version.nil?
      XMLHelper.add_extension(software_info, 'ApplyASHRAE140Assumptions', @apply_ashrae140_assumptions, :boolean) unless @apply_ashrae140_assumptions.nil?
      XMLHelper.add_extension(software_info, 'WholeSFAorMFBuildingSimulation', @whole_sfa_or_mf_building_sim, :boolean) unless @whole_sfa_or_mf_building_sim.nil?
      { 'ERICalculation' => @eri_calculation_version,
        'CO2IndexCalculation' => @co2index_calculation_version,
        'EnergyStarCalculation' => @energystar_calculation_version,
        'IECCERICalculation' => @iecc_eri_calculation_version,
        'ZERHCalculation' => @zerh_calculation_version }.each do |element_name, calculation_version|
        next if calculation_version.nil?

        extension = XMLHelper.create_elements_as_needed(software_info, ['extension'])
        calculation = XMLHelper.add_element(extension, element_name)
        XMLHelper.add_element(calculation, 'Version', calculation_version, :string)
      end
      if (not @timestep.nil?) || (not @sim_begin_month.nil?) || (not @sim_begin_day.nil?) || (not @sim_end_month.nil?) || (not @sim_end_day.nil?) || (not @temperature_capacitance_multiplier.nil?)
        extension = XMLHelper.create_elements_as_needed(software_info, ['extension'])
        simulation_control = XMLHelper.add_element(extension, 'SimulationControl')
        XMLHelper.add_element(simulation_control, 'Timestep', @timestep, :integer, @timestep_isdefaulted) unless @timestep.nil?
        XMLHelper.add_element(simulation_control, 'BeginMonth', @sim_begin_month, :integer, @sim_begin_month_isdefaulted) unless @sim_begin_month.nil?
        XMLHelper.add_element(simulation_control, 'BeginDayOfMonth', @sim_begin_day, :integer, @sim_begin_day_isdefaulted) unless @sim_begin_day.nil?
        XMLHelper.add_element(simulation_control, 'EndMonth', @sim_end_month, :integer, @sim_end_month_isdefaulted) unless @sim_end_month.nil?
        XMLHelper.add_element(simulation_control, 'EndDayOfMonth', @sim_end_day, :integer, @sim_end_day_isdefaulted) unless @sim_end_day.nil?
        XMLHelper.add_element(simulation_control, 'CalendarYear', @sim_calendar_year, :integer, @sim_calendar_year_isdefaulted) unless @sim_calendar_year.nil?
        XMLHelper.add_element(simulation_control, 'TemperatureCapacitanceMultiplier', @temperature_capacitance_multiplier, :float, @temperature_capacitance_multiplier_isdefaulted) unless @temperature_capacitance_multiplier.nil?
      end
      @emissions_scenarios.to_doc(software_info)
      @utility_bill_scenarios.to_doc(software_info)
      @unavailable_periods.to_doc(software_info)
    end

    def from_doc(hpxml)
      return if hpxml.nil?

      @xml_type = XMLHelper.get_value(hpxml, 'XMLTransactionHeaderInformation/XMLType', :string)
      @xml_generated_by = XMLHelper.get_value(hpxml, 'XMLTransactionHeaderInformation/XMLGeneratedBy', :string)
      @created_date_and_time = XMLHelper.get_value(hpxml, 'XMLTransactionHeaderInformation/CreatedDateAndTime', :string)
      @transaction = XMLHelper.get_value(hpxml, 'XMLTransactionHeaderInformation/Transaction', :string)
      @software_program_used = XMLHelper.get_value(hpxml, 'SoftwareInfo/SoftwareProgramUsed', :string)
      @software_program_version = XMLHelper.get_value(hpxml, 'SoftwareInfo/SoftwareProgramVersion', :string)
      @eri_calculation_version = XMLHelper.get_value(hpxml, 'SoftwareInfo/extension/ERICalculation/Version', :string)
      @co2index_calculation_version = XMLHelper.get_value(hpxml, 'SoftwareInfo/extension/CO2IndexCalculation/Version', :string)
      @iecc_eri_calculation_version = XMLHelper.get_value(hpxml, 'SoftwareInfo/extension/IECCERICalculation/Version', :string)
      @energystar_calculation_version = XMLHelper.get_value(hpxml, 'SoftwareInfo/extension/EnergyStarCalculation/Version', :string)
      @zerh_calculation_version = XMLHelper.get_value(hpxml, 'SoftwareInfo/extension/ZERHCalculation/Version', :string)
      @timestep = XMLHelper.get_value(hpxml, 'SoftwareInfo/extension/SimulationControl/Timestep', :integer)
      @sim_begin_month = XMLHelper.get_value(hpxml, 'SoftwareInfo/extension/SimulationControl/BeginMonth', :integer)
      @sim_begin_day = XMLHelper.get_value(hpxml, 'SoftwareInfo/extension/SimulationControl/BeginDayOfMonth', :integer)
      @sim_end_month = XMLHelper.get_value(hpxml, 'SoftwareInfo/extension/SimulationControl/EndMonth', :integer)
      @sim_end_day = XMLHelper.get_value(hpxml, 'SoftwareInfo/extension/SimulationControl/EndDayOfMonth', :integer)
      @sim_calendar_year = XMLHelper.get_value(hpxml, 'SoftwareInfo/extension/SimulationControl/CalendarYear', :integer)
      @temperature_capacitance_multiplier = XMLHelper.get_value(hpxml, 'SoftwareInfo/extension/SimulationControl/TemperatureCapacitanceMultiplier', :float)
      @apply_ashrae140_assumptions = XMLHelper.get_value(hpxml, 'SoftwareInfo/extension/ApplyASHRAE140Assumptions', :boolean)
      @whole_sfa_or_mf_building_sim = XMLHelper.get_value(hpxml, 'SoftwareInfo/extension/WholeSFAorMFBuildingSimulation', :boolean)
      @emissions_scenarios.from_doc(XMLHelper.get_element(hpxml, 'SoftwareInfo'))
      @utility_bill_scenarios.from_doc(XMLHelper.get_element(hpxml, 'SoftwareInfo'))
      @unavailable_periods.from_doc(XMLHelper.get_element(hpxml, 'SoftwareInfo'))
    end
  end

  class EmissionsScenarios < BaseArrayElement
    def add(**kwargs)
      self << EmissionsScenario.new(@parent_object, **kwargs)
    end

    def from_doc(software_info)
      return if software_info.nil?

      XMLHelper.get_elements(software_info, 'extension/EmissionsScenarios/EmissionsScenario').each do |emissions_scenario|
        self << EmissionsScenario.new(@parent_object, emissions_scenario)
      end
    end
  end

  class EmissionsScenario < BaseElement
    UnitsKgPerMWh = 'kg/MWh'
    UnitsKgPerMBtu = 'kg/MBtu'
    UnitsLbPerMWh = 'lb/MWh'
    UnitsLbPerMBtu = 'lb/MBtu'

    ATTRS = [:name, :emissions_type, :elec_units, :elec_value, :elec_schedule_filepath,
             :elec_schedule_number_of_header_rows, :elec_schedule_column_number,
             :natural_gas_units, :natural_gas_value, :propane_units, :propane_value,
             :fuel_oil_units, :fuel_oil_value, :coal_units, :coal_value,
             :wood_units, :wood_value, :wood_pellets_units, :wood_pellets_value]
    attr_accessor(*ATTRS)

    def delete
      @parent_object.header.emissions_scenarios.delete(self)
    end

    def check_for_errors
      errors = []
      return errors
    end

    def to_doc(software_info)
      emissions_scenarios = XMLHelper.create_elements_as_needed(software_info, ['extension', 'EmissionsScenarios'])
      emissions_scenario = XMLHelper.add_element(emissions_scenarios, 'EmissionsScenario')
      XMLHelper.add_element(emissions_scenario, 'Name', @name, :string) unless @name.nil?
      XMLHelper.add_element(emissions_scenario, 'EmissionsType', @emissions_type, :string) unless @emissions_type.nil?
      if not @elec_schedule_filepath.nil?
        emissions_factor = XMLHelper.add_element(emissions_scenario, 'EmissionsFactor')
        XMLHelper.add_element(emissions_factor, 'FuelType', HPXML::FuelTypeElectricity, :string)
        XMLHelper.add_element(emissions_factor, 'Units', @elec_units, :string)
        XMLHelper.add_element(emissions_factor, 'ScheduleFilePath', @elec_schedule_filepath, :string)
        XMLHelper.add_element(emissions_factor, 'NumberofHeaderRows', @elec_schedule_number_of_header_rows, :integer, @elec_schedule_number_of_header_rows_isdefaulted) unless @elec_schedule_number_of_header_rows.nil?
        XMLHelper.add_element(emissions_factor, 'ColumnNumber', @elec_schedule_column_number, :integer, @elec_schedule_column_number_isdefaulted) unless @elec_schedule_column_number.nil?
      end
      { HPXML::FuelTypeElectricity => [@elec_units, @elec_units_isdefaulted,
                                       @elec_value, @elec_value_isdefaulted],
        HPXML::FuelTypeNaturalGas => [@natural_gas_units, @natural_gas_units_isdefaulted,
                                      @natural_gas_value, @natural_gas_value_isdefaulted],
        HPXML::FuelTypePropane => [@propane_units, @propane_units_isdefaulted,
                                   @propane_value, @propane_value_isdefaulted],
        HPXML::FuelTypeOil => [@fuel_oil_units, @fuel_oil_units_isdefaulted,
                               @fuel_oil_value, @fuel_oil_value_isdefaulted],
        HPXML::FuelTypeCoal => [@coal_units, @coal_units_isdefaulted,
                                @coal_value, @coal_value_isdefaulted],
        HPXML::FuelTypeWoodCord => [@wood_units, @wood_units_isdefaulted,
                                    @wood_value, @wood_value_isdefaulted],
        HPXML::FuelTypeWoodPellets => [@wood_pellets_units, @wood_pellets_units_isdefaulted,
                                       @wood_pellets_value, @wood_pellets_value_isdefaulted] }.each do |fuel, vals|
        units, units_isdefaulted, value, value_isdefaulted = vals
        next if value.nil?

        emissions_factor = XMLHelper.add_element(emissions_scenario, 'EmissionsFactor')
        XMLHelper.add_element(emissions_factor, 'FuelType', fuel, :string)
        XMLHelper.add_element(emissions_factor, 'Units', units, :string, units_isdefaulted)
        XMLHelper.add_element(emissions_factor, 'Value', value, :float, value_isdefaulted)
      end
    end

    def from_doc(emissions_scenario)
      return if emissions_scenario.nil?

      @name = XMLHelper.get_value(emissions_scenario, 'Name', :string)
      @emissions_type = XMLHelper.get_value(emissions_scenario, 'EmissionsType', :string)
      @elec_units = XMLHelper.get_value(emissions_scenario, "EmissionsFactor[FuelType='#{HPXML::FuelTypeElectricity}']/Units", :string)
      @elec_value = XMLHelper.get_value(emissions_scenario, "EmissionsFactor[FuelType='#{HPXML::FuelTypeElectricity}']/Value", :float)
      @elec_schedule_filepath = XMLHelper.get_value(emissions_scenario, "EmissionsFactor[FuelType='#{HPXML::FuelTypeElectricity}']/ScheduleFilePath", :string)
      @elec_schedule_number_of_header_rows = XMLHelper.get_value(emissions_scenario, "EmissionsFactor[FuelType='#{HPXML::FuelTypeElectricity}']/NumberofHeaderRows", :integer)
      @elec_schedule_column_number = XMLHelper.get_value(emissions_scenario, "EmissionsFactor[FuelType='#{HPXML::FuelTypeElectricity}']/ColumnNumber", :integer)
      @natural_gas_units = XMLHelper.get_value(emissions_scenario, "EmissionsFactor[FuelType='#{HPXML::FuelTypeNaturalGas}']/Units", :string)
      @natural_gas_value = XMLHelper.get_value(emissions_scenario, "EmissionsFactor[FuelType='#{HPXML::FuelTypeNaturalGas}']/Value", :float)
      @propane_units = XMLHelper.get_value(emissions_scenario, "EmissionsFactor[FuelType='#{HPXML::FuelTypePropane}']/Units", :string)
      @propane_value = XMLHelper.get_value(emissions_scenario, "EmissionsFactor[FuelType='#{HPXML::FuelTypePropane}']/Value", :float)
      @fuel_oil_units = XMLHelper.get_value(emissions_scenario, "EmissionsFactor[FuelType='#{HPXML::FuelTypeOil}']/Units", :string)
      @fuel_oil_value = XMLHelper.get_value(emissions_scenario, "EmissionsFactor[FuelType='#{HPXML::FuelTypeOil}']/Value", :float)
      @coal_units = XMLHelper.get_value(emissions_scenario, "EmissionsFactor[FuelType='#{HPXML::FuelTypeCoal}']/Units", :string)
      @coal_value = XMLHelper.get_value(emissions_scenario, "EmissionsFactor[FuelType='#{HPXML::FuelTypeCoal}']/Value", :float)
      @wood_units = XMLHelper.get_value(emissions_scenario, "EmissionsFactor[FuelType='#{HPXML::FuelTypeWoodCord}']/Units", :string)
      @wood_value = XMLHelper.get_value(emissions_scenario, "EmissionsFactor[FuelType='#{HPXML::FuelTypeWoodCord}']/Value", :float)
      @wood_pellets_units = XMLHelper.get_value(emissions_scenario, "EmissionsFactor[FuelType='#{HPXML::FuelTypeWoodPellets}']/Units", :string)
      @wood_pellets_value = XMLHelper.get_value(emissions_scenario, "EmissionsFactor[FuelType='#{HPXML::FuelTypeWoodPellets}']/Value", :float)
    end
  end

  class UtilityBillScenarios < BaseArrayElement
    def add(**kwargs)
      self << UtilityBillScenario.new(@parent_object, **kwargs)
    end

    def from_doc(software_info)
      return if software_info.nil?

      XMLHelper.get_elements(software_info, 'extension/UtilityBillScenarios/UtilityBillScenario').each do |utility_bill_scenario|
        self << UtilityBillScenario.new(@parent_object, utility_bill_scenario)
      end
    end

    def has_simple_electric_rates
      any? { |bill_scen| !bill_scen.elec_fixed_charge.nil? || !bill_scen.elec_marginal_rate.nil? }
    end

    def has_detailed_electric_rates
      any? { |bill_scen| !bill_scen.elec_tariff_filepath.nil? }
    end
  end

  class UtilityBillScenario < BaseElement
    ATTRS = [:name,
             :elec_tariff_filepath,
             :elec_fixed_charge, :natural_gas_fixed_charge, :propane_fixed_charge, :fuel_oil_fixed_charge,
             :coal_fixed_charge, :wood_fixed_charge, :wood_pellets_fixed_charge,
             :elec_marginal_rate, :natural_gas_marginal_rate, :propane_marginal_rate, :fuel_oil_marginal_rate,
             :coal_marginal_rate, :wood_marginal_rate, :wood_pellets_marginal_rate,
             :pv_compensation_type,
             :pv_net_metering_annual_excess_sellback_rate_type, :pv_net_metering_annual_excess_sellback_rate,
             :pv_feed_in_tariff_rate,
             :pv_monthly_grid_connection_fee_dollars_per_kw, :pv_monthly_grid_connection_fee_dollars]
    attr_accessor(*ATTRS)

    def delete
      @parent_object.header.utility_bill_scenarios.delete(self)
    end

    def check_for_errors
      errors = []
      return errors
    end

    def to_doc(software_info)
      utility_bill_scenarios = XMLHelper.create_elements_as_needed(software_info, ['extension', 'UtilityBillScenarios'])
      utility_bill_scenario = XMLHelper.add_element(utility_bill_scenarios, 'UtilityBillScenario')
      XMLHelper.add_element(utility_bill_scenario, 'Name', @name, :string) unless @name.nil?
      { HPXML::FuelTypeElectricity => [@elec_fixed_charge, @elec_fixed_charge_isdefaulted, @elec_marginal_rate, @elec_marginal_rate_isdefaulted, @elec_tariff_filepath],
        HPXML::FuelTypeNaturalGas => [@natural_gas_fixed_charge, @natural_gas_fixed_charge_isdefaulted, @natural_gas_marginal_rate, @natural_gas_marginal_rate_isdefaulted, nil],
        HPXML::FuelTypePropane => [@propane_fixed_charge, @propane_fixed_charge_isdefaulted, @propane_marginal_rate, @propane_marginal_rate_isdefaulted, nil],
        HPXML::FuelTypeOil => [@fuel_oil_fixed_charge, @fuel_oil_fixed_charge_isdefaulted, @fuel_oil_marginal_rate, @fuel_oil_marginal_rate_isdefaulted, nil],
        HPXML::FuelTypeCoal => [@coal_fixed_charge, @coal_fixed_charge_isdefaulted, @coal_marginal_rate, @coal_marginal_rate_isdefaulted, nil],
        HPXML::FuelTypeWoodCord => [@wood_fixed_charge, @wood_fixed_charge_isdefaulted, @wood_marginal_rate, @wood_marginal_rate_isdefaulted, nil],
        HPXML::FuelTypeWoodPellets => [@wood_pellets_fixed_charge, @wood_pellets_fixed_charge_isdefaulted, @wood_pellets_marginal_rate, @wood_pellets_marginal_rate_isdefaulted, nil] }.each do |fuel, vals|
        fixed_charge, fixed_charge_isdefaulted, marginal_rate, marginal_rate_isdefaulted, tariff_filepath = vals
        next if fixed_charge.nil? && marginal_rate.nil? && tariff_filepath.nil?

        utility_rate = XMLHelper.add_element(utility_bill_scenario, 'UtilityRate')
        XMLHelper.add_element(utility_rate, 'FuelType', fuel, :string)
        XMLHelper.add_element(utility_rate, 'TariffFilePath', tariff_filepath, :string) unless tariff_filepath.nil?
        XMLHelper.add_element(utility_rate, 'FixedCharge', fixed_charge, :float, fixed_charge_isdefaulted) unless fixed_charge.nil?
        XMLHelper.add_element(utility_rate, 'MarginalRate', marginal_rate, :float, marginal_rate_isdefaulted) unless marginal_rate.nil?
      end
      if not @pv_compensation_type.nil?
        pv = XMLHelper.add_element(utility_bill_scenario, 'PVCompensation')
        pc_compensation_type = XMLHelper.add_element(pv, 'CompensationType')
        pv_compensation_type_el = XMLHelper.add_element(pc_compensation_type, @pv_compensation_type, nil, nil, pv_compensation_type_isdefaulted)
        if @pv_compensation_type == HPXML::PVCompensationTypeNetMetering
          XMLHelper.add_element(pv_compensation_type_el, 'AnnualExcessSellbackRateType', @pv_net_metering_annual_excess_sellback_rate_type, :string, pv_net_metering_annual_excess_sellback_rate_type_isdefaulted) unless @pv_net_metering_annual_excess_sellback_rate_type.nil?
          if @pv_net_metering_annual_excess_sellback_rate_type == HPXML::PVAnnualExcessSellbackRateTypeUserSpecified
            XMLHelper.add_element(pv_compensation_type_el, 'AnnualExcessSellbackRate', @pv_net_metering_annual_excess_sellback_rate, :float, pv_net_metering_annual_excess_sellback_rate_isdefaulted) unless @pv_net_metering_annual_excess_sellback_rate.nil?
          end
        elsif @pv_compensation_type == HPXML::PVCompensationTypeFeedInTariff
          XMLHelper.add_element(pv_compensation_type_el, 'FeedInTariffRate', @pv_feed_in_tariff_rate, :float, pv_feed_in_tariff_rate_isdefaulted) unless @pv_feed_in_tariff_rate.nil?
        end
        if not @pv_monthly_grid_connection_fee_dollars_per_kw.nil?
          monthly_grid_connection_fee = XMLHelper.add_element(pv, 'MonthlyGridConnectionFee')
          XMLHelper.add_element(monthly_grid_connection_fee, 'Units', UnitsDollarsPerkW, :string)
          XMLHelper.add_element(monthly_grid_connection_fee, 'Value', @pv_monthly_grid_connection_fee_dollars_per_kw, :float, pv_monthly_grid_connection_fee_dollars_per_kw_isdefaulted)
        end
        if not @pv_monthly_grid_connection_fee_dollars.nil?
          monthly_grid_connection_fee = XMLHelper.add_element(pv, 'MonthlyGridConnectionFee')
          XMLHelper.add_element(monthly_grid_connection_fee, 'Units', UnitsDollars, :string)
          XMLHelper.add_element(monthly_grid_connection_fee, 'Value', @pv_monthly_grid_connection_fee_dollars, :float, pv_monthly_grid_connection_fee_dollars_isdefaulted)
        end
      end
    end

    def from_doc(utility_bill_scenario)
      return if utility_bill_scenario.nil?

      @name = XMLHelper.get_value(utility_bill_scenario, 'Name', :string)
      @elec_fixed_charge = XMLHelper.get_value(utility_bill_scenario, "UtilityRate[FuelType='#{HPXML::FuelTypeElectricity}']/FixedCharge", :float)
      @elec_marginal_rate = XMLHelper.get_value(utility_bill_scenario, "UtilityRate[FuelType='#{HPXML::FuelTypeElectricity}']/MarginalRate", :float)
      @elec_tariff_filepath = XMLHelper.get_value(utility_bill_scenario, "UtilityRate[FuelType='#{HPXML::FuelTypeElectricity}']/TariffFilePath", :string)
      @natural_gas_fixed_charge = XMLHelper.get_value(utility_bill_scenario, "UtilityRate[FuelType='#{HPXML::FuelTypeNaturalGas}']/FixedCharge", :float)
      @natural_gas_marginal_rate = XMLHelper.get_value(utility_bill_scenario, "UtilityRate[FuelType='#{HPXML::FuelTypeNaturalGas}']/MarginalRate", :float)
      @propane_fixed_charge = XMLHelper.get_value(utility_bill_scenario, "UtilityRate[FuelType='#{HPXML::FuelTypePropane}']/FixedCharge", :float)
      @propane_marginal_rate = XMLHelper.get_value(utility_bill_scenario, "UtilityRate[FuelType='#{HPXML::FuelTypePropane}']/MarginalRate", :float)
      @fuel_oil_fixed_charge = XMLHelper.get_value(utility_bill_scenario, "UtilityRate[FuelType='#{HPXML::FuelTypeOil}']/FixedCharge", :float)
      @fuel_oil_marginal_rate = XMLHelper.get_value(utility_bill_scenario, "UtilityRate[FuelType='#{HPXML::FuelTypeOil}']/MarginalRate", :float)
      @coal_fixed_charge = XMLHelper.get_value(utility_bill_scenario, "UtilityRate[FuelType='#{HPXML::FuelTypeCoal}']/FixedCharge", :float)
      @coal_marginal_rate = XMLHelper.get_value(utility_bill_scenario, "UtilityRate[FuelType='#{HPXML::FuelTypeCoal}']/MarginalRate", :float)
      @wood_fixed_charge = XMLHelper.get_value(utility_bill_scenario, "UtilityRate[FuelType='#{HPXML::FuelTypeWoodCord}']/FixedCharge", :float)
      @wood_marginal_rate = XMLHelper.get_value(utility_bill_scenario, "UtilityRate[FuelType='#{HPXML::FuelTypeWoodCord}']/MarginalRate", :float)
      @wood_pellets_fixed_charge = XMLHelper.get_value(utility_bill_scenario, "UtilityRate[FuelType='#{HPXML::FuelTypeWoodPellets}']/FixedCharge", :float)
      @wood_pellets_marginal_rate = XMLHelper.get_value(utility_bill_scenario, "UtilityRate[FuelType='#{HPXML::FuelTypeWoodPellets}']/MarginalRate", :float)
      @pv_compensation_type = XMLHelper.get_child_name(utility_bill_scenario, 'PVCompensation/CompensationType')
      if @pv_compensation_type == HPXML::PVCompensationTypeNetMetering
        @pv_net_metering_annual_excess_sellback_rate_type = XMLHelper.get_value(utility_bill_scenario, "PVCompensation/CompensationType/#{HPXML::PVCompensationTypeNetMetering}/AnnualExcessSellbackRateType", :string)
        if @pv_net_metering_annual_excess_sellback_rate_type == HPXML::PVAnnualExcessSellbackRateTypeUserSpecified
          @pv_net_metering_annual_excess_sellback_rate = XMLHelper.get_value(utility_bill_scenario, "PVCompensation/CompensationType/#{HPXML::PVCompensationTypeNetMetering}/AnnualExcessSellbackRate", :float)
        end
      elsif @pv_compensation_type == HPXML::PVCompensationTypeFeedInTariff
        @pv_feed_in_tariff_rate = XMLHelper.get_value(utility_bill_scenario, "PVCompensation/CompensationType/#{HPXML::PVCompensationTypeFeedInTariff}/FeedInTariffRate", :float)
      end
      @pv_monthly_grid_connection_fee_dollars_per_kw = XMLHelper.get_value(utility_bill_scenario, "PVCompensation/MonthlyGridConnectionFee[Units='#{UnitsDollarsPerkW}']/Value", :float)
      @pv_monthly_grid_connection_fee_dollars = XMLHelper.get_value(utility_bill_scenario, "PVCompensation/MonthlyGridConnectionFee[Units='#{UnitsDollars}']/Value", :float)
    end
  end

  class UnavailablePeriods < BaseArrayElement
    def add(**kwargs)
      self << UnavailablePeriod.new(@parent_object, **kwargs)
    end

    def from_doc(software_info)
      return if software_info.nil?

      XMLHelper.get_elements(software_info, 'extension/UnavailablePeriods/UnavailablePeriod').each do |unavailable_period|
        self << UnavailablePeriod.new(@parent_object, unavailable_period)
      end
    end
  end

  class UnavailablePeriod < BaseElement
    ATTRS = [:column_name, :begin_month, :begin_day, :begin_hour, :end_month, :end_day, :end_hour, :natvent_availability]
    attr_accessor(*ATTRS)

    def delete
      @parent_object.header.unavailable_periods.delete(self)
    end

    def check_for_errors
      errors = []
      errors += HPXML::check_dates('Unavailable Period', @begin_month, @begin_day, @end_month, @end_day)
      return errors
    end

    def to_doc(software_info)
      unavailable_periods = XMLHelper.create_elements_as_needed(software_info, ['extension', 'UnavailablePeriods'])
      unavailable_period = XMLHelper.add_element(unavailable_periods, 'UnavailablePeriod')
      XMLHelper.add_element(unavailable_period, 'ColumnName', @column_name, :string) unless @column_name.nil?
      XMLHelper.add_element(unavailable_period, 'BeginMonth', @begin_month, :integer, @begin_month_isdefaulted) unless @begin_month.nil?
      XMLHelper.add_element(unavailable_period, 'BeginDayOfMonth', @begin_day, :integer, @begin_day_isdefaulted) unless @begin_day.nil?
      XMLHelper.add_element(unavailable_period, 'BeginHourOfDay', @begin_hour, :integer, @begin_hour_isdefaulted) unless @begin_hour.nil?
      XMLHelper.add_element(unavailable_period, 'EndMonth', @end_month, :integer, @end_month_isdefaulted) unless @end_month.nil?
      XMLHelper.add_element(unavailable_period, 'EndDayOfMonth', @end_day, :integer, @end_day_isdefaulted) unless @end_day.nil?
      XMLHelper.add_element(unavailable_period, 'EndHourOfDay', @end_hour, :integer, @end_hour_isdefaulted) unless @end_hour.nil?
      XMLHelper.add_element(unavailable_period, 'NaturalVentilation', @natvent_availability, :string, @natvent_availability_isdefaulted) unless @natvent_availability.nil?
    end

    def from_doc(unavailable_period)
      return if unavailable_period.nil?

      @column_name = XMLHelper.get_value(unavailable_period, 'ColumnName', :string)
      @begin_month = XMLHelper.get_value(unavailable_period, 'BeginMonth', :integer)
      @begin_day = XMLHelper.get_value(unavailable_period, 'BeginDayOfMonth', :integer)
      @begin_hour = XMLHelper.get_value(unavailable_period, 'BeginHourOfDay', :integer)
      @end_month = XMLHelper.get_value(unavailable_period, 'EndMonth', :integer)
      @end_day = XMLHelper.get_value(unavailable_period, 'EndDayOfMonth', :integer)
      @end_hour = XMLHelper.get_value(unavailable_period, 'EndHourOfDay', :integer)
      @natvent_availability = XMLHelper.get_value(unavailable_period, 'NaturalVentilation', :string)
    end
  end

  class Buildings < BaseArrayElement
    def add(**kwargs)
      self << Building.new(@parent_object, **kwargs)
    end

    def from_doc(hpxml)
      return if hpxml.nil?

      XMLHelper.get_elements(hpxml, 'Building').each do |building|
        self << Building.new(@parent_object, building)
      end
    end
  end

  class Building < BaseElement
    CLASS_ATTRS = [:site, :neighbor_buildings, :building_occupancy, :building_construction, :header,
                   :climate_and_risk_zones, :air_infiltration, :air_infiltration_measurements, :attics,
                   :foundations, :roofs, :rim_joists, :walls, :foundation_walls, :floors, :slabs, :windows,
                   :skylights, :doors, :partition_wall_mass, :furniture_mass, :heating_systems,
                   :cooling_systems, :heat_pumps, :geothermal_loops, :hvac_plant, :hvac_controls, :hvac_distributions,
                   :ventilation_fans, :water_heating_systems, :hot_water_distributions, :water_fixtures,
                   :water_heating, :solar_thermal_systems, :pv_systems, :inverters, :generators,
                   :batteries, :clothes_washers, :clothes_dryers, :dishwashers, :refrigerators,
                   :freezers, :dehumidifiers, :cooking_ranges, :ovens, :lighting_groups, :lighting,
                   :ceiling_fans, :pools, :permanent_spas, :portable_spas, :plug_loads, :fuel_loads]
    ATTRS = [:building_id, :site_id, :state_code, :zip_code, :time_zone_utc_offset, :egrid_region,
             :egrid_subregion, :cambium_region_gea, :dst_enabled, :dst_begin_month,
             :dst_begin_day, :dst_end_month, :dst_end_day, :event_type]

    attr_accessor(*CLASS_ATTRS)
    attr_accessor(*ATTRS)

    def initialize(*args)
      from_doc(nil)
      super(*args)
    end

    def to_doc(doc)
      return if nil?

      hpxml = XMLHelper.create_elements_as_needed(doc, ['HPXML'])
      building = XMLHelper.add_element(hpxml, 'Building')
      building_building_id = XMLHelper.add_element(building, 'BuildingID')
      XMLHelper.add_attribute(building_building_id, 'id', @building_id)
      if (not @state_code.nil?) || (not @zip_code.nil?) || (not @time_zone_utc_offset.nil?) || (not @egrid_region.nil?) || (not @egrid_subregion.nil?) || (not @cambium_region_gea.nil?) || (not @dst_enabled.nil?) || (not @dst_begin_month.nil?) || (not @dst_begin_day.nil?) || (not @dst_end_month.nil?) || (not @dst_end_day.nil?)
        building_site = XMLHelper.add_element(building, 'Site')
        building_site_id = XMLHelper.add_element(building_site, 'SiteID')
        if @site_id.nil?
          bldg_idx = XMLHelper.get_elements(hpxml, 'Building').size
          if bldg_idx > 1
            XMLHelper.add_attribute(building_site_id, 'id', "SiteID_#{bldg_idx}")
          else
            XMLHelper.add_attribute(building_site_id, 'id', 'SiteID')
          end
        else
          XMLHelper.add_attribute(building_site_id, 'id', @site_id)
        end
        if (not @state_code.nil?) || (not @zip_code.nil?)
          address = XMLHelper.add_element(building_site, 'Address')
          XMLHelper.add_element(address, 'StateCode', @state_code, :string, @state_code_isdefaulted) unless @state_code.nil?
          XMLHelper.add_element(address, 'ZipCode', @zip_code, :string) unless @zip_code.nil?
        end
        if not @egrid_region.nil?
          XMLHelper.add_element(building_site, 'eGridRegion', @egrid_region, :string, @egrid_region_isdefaulted)
        end
        if not @egrid_subregion.nil?
          XMLHelper.add_element(building_site, 'eGridSubregion', @egrid_subregion, :string, @egrid_subregion_isdefaulted)
        end
        if not @cambium_region_gea.nil?
          XMLHelper.add_element(building_site, 'CambiumRegionGEA', @cambium_region_gea, :string, @cambium_region_gea_isdefaulted)
        end
        if (not @time_zone_utc_offset.nil?) || (not @dst_enabled.nil?) || (not @dst_begin_month.nil?) || (not @dst_begin_day.nil?) || (not @dst_end_month.nil?) || (not @dst_end_day.nil?)
          time_zone = XMLHelper.add_element(building_site, 'TimeZone')
          XMLHelper.add_element(time_zone, 'UTCOffset', @time_zone_utc_offset, :float, @time_zone_utc_offset_isdefaulted) unless @time_zone_utc_offset.nil?
          XMLHelper.add_element(time_zone, 'DSTObserved', @dst_enabled, :boolean, @dst_enabled_isdefaulted) unless @dst_enabled.nil?
          XMLHelper.add_extension(time_zone, 'DSTBeginMonth', @dst_begin_month, :integer, @dst_begin_month_isdefaulted) unless @dst_begin_month.nil?
          XMLHelper.add_extension(time_zone, 'DSTBeginDayOfMonth', @dst_begin_day, :integer, @dst_begin_day_isdefaulted) unless @dst_begin_day.nil?
          XMLHelper.add_extension(time_zone, 'DSTEndMonth', @dst_end_month, :integer, @dst_end_month_isdefaulted) unless @dst_end_month.nil?
          XMLHelper.add_extension(time_zone, 'DSTEndDayOfMonth', @dst_end_day, :integer, @dst_end_day_isdefaulted) unless @dst_end_day.nil?
        end
      end
      project_status = XMLHelper.add_element(building, 'ProjectStatus')
      XMLHelper.add_element(project_status, 'EventType', @event_type, :string)

      @site.to_doc(building)
      @neighbor_buildings.to_doc(building)
      @building_occupancy.to_doc(building)
      @building_construction.to_doc(building)
      @header.to_doc(building)
      @climate_and_risk_zones.to_doc(building)
      @air_infiltration_measurements.to_doc(building)
      @air_infiltration.to_doc(building)
      @attics.to_doc(building)
      @foundations.to_doc(building)
      @roofs.to_doc(building)
      @rim_joists.to_doc(building)
      @walls.to_doc(building)
      @foundation_walls.to_doc(building)
      @floors.to_doc(building)
      @slabs.to_doc(building)
      @windows.to_doc(building)
      @skylights.to_doc(building)
      @doors.to_doc(building)
      @partition_wall_mass.to_doc(building)
      @furniture_mass.to_doc(building)
      @heating_systems.to_doc(building)
      @cooling_systems.to_doc(building)
      @heat_pumps.to_doc(building)
      @geothermal_loops.to_doc(building)
      @hvac_plant.to_doc(building)
      @hvac_controls.to_doc(building)
      @hvac_distributions.to_doc(building)
      @ventilation_fans.to_doc(building)
      @water_heating_systems.to_doc(building)
      @hot_water_distributions.to_doc(building)
      @water_fixtures.to_doc(building)
      @water_heating.to_doc(building)
      @solar_thermal_systems.to_doc(building)
      @pv_systems.to_doc(building)
      @inverters.to_doc(building)
      @batteries.to_doc(building)
      @generators.to_doc(building)
      @clothes_washers.to_doc(building)
      @clothes_dryers.to_doc(building)
      @dishwashers.to_doc(building)
      @refrigerators.to_doc(building)
      @freezers.to_doc(building)
      @dehumidifiers.to_doc(building)
      @cooking_ranges.to_doc(building)
      @ovens.to_doc(building)
      @lighting_groups.to_doc(building)
      @ceiling_fans.to_doc(building)
      @lighting.to_doc(building)
      @pools.to_doc(building)
      @permanent_spas.to_doc(building)
      @portable_spas.to_doc(building)
      @plug_loads.to_doc(building)
      @fuel_loads.to_doc(building)
    end

    def from_doc(building)
      if not building.nil?
        @building_id = HPXML::get_id(building, 'BuildingID')
        @event_type = XMLHelper.get_value(building, 'ProjectStatus/EventType', :string)
        @site_id = HPXML::get_id(building, 'Site/SiteID')
        @state_code = XMLHelper.get_value(building, 'Site/Address/StateCode', :string)
        @zip_code = XMLHelper.get_value(building, 'Site/Address/ZipCode', :string)
        @egrid_region = XMLHelper.get_value(building, 'Site/eGridRegion', :string)
        @egrid_subregion = XMLHelper.get_value(building, 'Site/eGridSubregion', :string)
        @cambium_region_gea = XMLHelper.get_value(building, 'Site/CambiumRegionGEA', :string)
        @time_zone_utc_offset = XMLHelper.get_value(building, 'Site/TimeZone/UTCOffset', :float)
        @dst_enabled = XMLHelper.get_value(building, 'Site/TimeZone/DSTObserved', :boolean)
        @dst_begin_month = XMLHelper.get_value(building, 'Site/TimeZone/extension/DSTBeginMonth', :integer)
        @dst_begin_day = XMLHelper.get_value(building, 'Site/TimeZone/extension/DSTBeginDayOfMonth', :integer)
        @dst_end_month = XMLHelper.get_value(building, 'Site/TimeZone/extension/DSTEndMonth', :integer)
        @dst_end_day = XMLHelper.get_value(building, 'Site/TimeZone/extension/DSTEndDayOfMonth', :integer)
      end

      @site = Site.new(self, building)
      @neighbor_buildings = NeighborBuildings.new(self, building)
      @building_occupancy = BuildingOccupancy.new(self, building)
      @building_construction = BuildingConstruction.new(self, building)
      @header = BuildingHeader.new(self, building)
      @climate_and_risk_zones = ClimateandRiskZones.new(self, building)
      @air_infiltration_measurements = AirInfiltrationMeasurements.new(self, building)
      @air_infiltration = AirInfiltration.new(self, building)
      @attics = Attics.new(self, building)
      @foundations = Foundations.new(self, building)
      @roofs = Roofs.new(self, building)
      @rim_joists = RimJoists.new(self, building)
      @walls = Walls.new(self, building)
      @foundation_walls = FoundationWalls.new(self, building)
      @floors = Floors.new(self, building)
      @slabs = Slabs.new(self, building)
      @windows = Windows.new(self, building)
      @skylights = Skylights.new(self, building)
      @doors = Doors.new(self, building)
      @partition_wall_mass = PartitionWallMass.new(self, building)
      @furniture_mass = FurnitureMass.new(self, building)
      @heating_systems = HeatingSystems.new(self, building)
      @cooling_systems = CoolingSystems.new(self, building)
      @heat_pumps = HeatPumps.new(self, building)
      @geothermal_loops = GeothermalLoops.new(self, building)
      @hvac_plant = HVACPlant.new(self, building)
      @hvac_controls = HVACControls.new(self, building)
      @hvac_distributions = HVACDistributions.new(self, building)
      @ventilation_fans = VentilationFans.new(self, building)
      @water_heating_systems = WaterHeatingSystems.new(self, building)
      @hot_water_distributions = HotWaterDistributions.new(self, building)
      @water_fixtures = WaterFixtures.new(self, building)
      @water_heating = WaterHeating.new(self, building)
      @solar_thermal_systems = SolarThermalSystems.new(self, building)
      @pv_systems = PVSystems.new(self, building)
      @inverters = Inverters.new(self, building)
      @batteries = Batteries.new(self, building)
      @generators = Generators.new(self, building)
      @clothes_washers = ClothesWashers.new(self, building)
      @clothes_dryers = ClothesDryers.new(self, building)
      @dishwashers = Dishwashers.new(self, building)
      @refrigerators = Refrigerators.new(self, building)
      @freezers = Freezers.new(self, building)
      @dehumidifiers = Dehumidifiers.new(self, building)
      @cooking_ranges = CookingRanges.new(self, building)
      @ovens = Ovens.new(self, building)
      @lighting_groups = LightingGroups.new(self, building)
      @ceiling_fans = CeilingFans.new(self, building)
      @lighting = Lighting.new(self, building)
      @pools = Pools.new(self, building)
      @permanent_spas = PermanentSpas.new(self, building)
      @portable_spas = PortableSpas.new(self, building)
      @plug_loads = PlugLoads.new(self, building)
      @fuel_loads = FuelLoads.new(self, building)
    end

    def hvac_systems
      return (@heating_systems + @cooling_systems + @heat_pumps)
    end

    def has_location(location)
      # Search for surfaces attached to this location
      (@roofs + @rim_joists + @walls + @foundation_walls + @floors + @slabs).each do |surface|
        return true if surface.interior_adjacent_to == location
        return true if surface.exterior_adjacent_to == location
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

    def has_fuels(fuels_array, hpxml_doc)
      # Returns a hash with whether each fuel in fuels_array exists
      # in the HPXML Building
      has_fuels = @parent_object.has_fuels(fuels_array, hpxml_doc, @building_id)

      return has_fuels
    end

    def predominant_heating_fuel
      fuel_fracs = {}
      @heating_systems.each do |heating_system|
        fuel = heating_system.heating_system_fuel
        fuel_fracs[fuel] = 0.0 if fuel_fracs[fuel].nil?
        fuel_fracs[fuel] += heating_system.fraction_heat_load_served.to_f
      end
      @heat_pumps.each do |heat_pump|
        fuel = heat_pump.heat_pump_fuel
        fuel_fracs[fuel] = 0.0 if fuel_fracs[fuel].nil?
        fuel_fracs[fuel] += heat_pump.fraction_heat_load_served.to_f
      end
      return FuelTypeElectricity if fuel_fracs.empty?
      return FuelTypeElectricity if fuel_fracs[FuelTypeElectricity].to_f > 0.5

      # Choose fossil fuel
      fuel_fracs.delete FuelTypeElectricity
      return fuel_fracs.key(fuel_fracs.values.max)
    end

    def predominant_water_heating_fuel
      fuel_fracs = {}
      @water_heating_systems.each do |water_heating_system|
        fuel = water_heating_system.fuel_type
        if fuel.nil? # Combi boiler
          fuel = water_heating_system.related_hvac_system.heating_system_fuel
        end
        fuel_fracs[fuel] = 0.0 if fuel_fracs[fuel].nil?
        fuel_fracs[fuel] += water_heating_system.fraction_dhw_load_served
      end
      return FuelTypeElectricity if fuel_fracs.empty?
      return FuelTypeElectricity if fuel_fracs[FuelTypeElectricity].to_f > 0.5

      # Choose fossil fuel
      fuel_fracs.delete FuelTypeElectricity
      return fuel_fracs.key(fuel_fracs.values.max)
    end

    def fraction_of_windows_operable()
      # Calculates the fraction of windows that are operable.
      # Since we don't have count available, we use area as an approximation.
      window_area_total = @windows.map { |w| w.area }.sum(0.0)
      window_area_operable = @windows.map { |w| w.fraction_operable * w.area }.sum(0.0)
      if window_area_total <= 0
        return 0.0
      end

      return window_area_operable / window_area_total
    end

    def primary_hvac_systems()
      return hvac_systems.select { |h| h.primary_system }
    end

    def total_fraction_cool_load_served()
      return @cooling_systems.total_fraction_cool_load_served + @heat_pumps.total_fraction_cool_load_served
    end

    def total_fraction_heat_load_served()
      return @heating_systems.total_fraction_heat_load_served + @heat_pumps.total_fraction_heat_load_served + @cooling_systems.total_fraction_heat_load_served
    end

    def has_walkout_basement()
      has_conditioned_basement = has_location(LocationBasementConditioned)
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
        next unless HPXML::conditioned_locations_this_unit.include? wall.interior_adjacent_to

        if wall.exterior_adjacent_to == HPXML::LocationOtherHousingUnit
          area += wall.area
        elsif wall.exterior_adjacent_to == wall.interior_adjacent_to
          area += wall.area
        end
      end

      return area
    end

    def compartmentalization_boundary_areas()
      # Returns the infiltration compartmentalization boundary areas
      total_area = 0.0 # Total surface area that bounds the Infiltration Volume
      exterior_area = 0.0 # Same as above excluding surfaces attached to garage, other housing units, or other multifamily spaces (see 301-2019 Addendum B)

      # Determine which spaces are within infiltration volume
      spaces_within_infil_volume = HPXML::conditioned_locations_this_unit
      @attics.each do |attic|
        next unless [AtticTypeUnvented].include? attic.attic_type
        next unless attic.within_infiltration_volume

        spaces_within_infil_volume << attic.to_location
      end
      @foundations.each do |foundation|
        next unless [FoundationTypeBasementUnconditioned,
                     FoundationTypeCrawlspaceUnvented].include? foundation.foundation_type
        next unless foundation.within_infiltration_volume

        spaces_within_infil_volume << foundation.to_location
      end

      # Get surfaces bounding infiltration volume
      spaces_within_infil_volume.each do |location|
        (@roofs + @rim_joists + @walls + @foundation_walls + @floors + @slabs).each do |surface|
          is_adiabatic_surface = (surface.interior_adjacent_to == surface.exterior_adjacent_to)
          next unless [surface.interior_adjacent_to,
                       surface.exterior_adjacent_to].include? location

          if not is_adiabatic_surface
            # Exclude surfaces between two different spaces that are both within infiltration volume
            next if spaces_within_infil_volume.include?(surface.interior_adjacent_to) && spaces_within_infil_volume.include?(surface.exterior_adjacent_to)
          end

          # Update Compartmentalization Boundary areas
          total_area += surface.area
          next unless (not [LocationGarage,
                            LocationOtherHousingUnit,
                            LocationOtherHeatedSpace,
                            LocationOtherMultifamilyBufferSpace,
                            LocationOtherNonFreezingSpace].include? surface.exterior_adjacent_to) &&
                      (not is_adiabatic_surface)

          exterior_area += surface.area
        end
      end

      return total_area, exterior_area
    end

    def inferred_infiltration_height(infil_volume)
      # Infiltration height: vertical distance between lowest and highest above-grade points within the pressure boundary.
      # Height is inferred from available HPXML properties.
      # The WithinInfiltrationVolume properties are intentionally ignored for now.
      cfa = @building_construction.conditioned_floor_area

      ncfl_ag = @building_construction.number_of_conditioned_floors_above_grade
      if has_walkout_basement()
        infil_height = ncfl_ag * infil_volume / cfa
      else
        infil_volume -= inferred_conditioned_crawlspace_volume()

        # Calculate maximum above-grade height of conditioned foundation walls
        max_cond_fnd_wall_height_ag = 0.0
        @foundation_walls.each do |foundation_wall|
          next unless foundation_wall.is_exterior && HPXML::conditioned_below_grade_locations.include?(foundation_wall.interior_adjacent_to)

          height_ag = foundation_wall.height - foundation_wall.depth_below_grade
          next unless height_ag > max_cond_fnd_wall_height_ag

          max_cond_fnd_wall_height_ag = height_ag
        end

        # Add assumed rim joist height
        cond_fnd_rim_joist_height = 0
        @rim_joists.each do |rim_joist|
          next unless rim_joist.is_exterior && HPXML::conditioned_below_grade_locations.include?(rim_joist.interior_adjacent_to)

          cond_fnd_rim_joist_height = UnitConversions.convert(9, 'in', 'ft')
        end

        infil_height = ncfl_ag * infil_volume / cfa + max_cond_fnd_wall_height_ag + cond_fnd_rim_joist_height
      end
      return infil_height
    end

    def inferred_conditioned_crawlspace_volume
      if has_location(HPXML::LocationCrawlspaceConditioned)
        conditioned_crawl_area = @slabs.select { |s| s.interior_adjacent_to == HPXML::LocationCrawlspaceConditioned }.map { |s| s.area }.sum
        conditioned_crawl_height = @foundation_walls.select { |w| w.interior_adjacent_to == HPXML::LocationCrawlspaceConditioned }.map { |w| w.height }.max
        return conditioned_crawl_area * conditioned_crawl_height
      end
      return 0.0
    end

    def delete_adiabatic_subsurfaces()
      @doors.reverse_each do |door|
        next if door.wall.nil?
        next if door.wall.exterior_adjacent_to != HPXML::LocationOtherHousingUnit

        door.delete
      end
      @windows.reverse_each do |window|
        next if window.wall.nil?
        next if window.wall.exterior_adjacent_to != HPXML::LocationOtherHousingUnit

        window.delete
      end
    end

    def check_for_errors()
      errors = []

      errors += HPXML::check_dates('Daylight Saving', @dst_begin_month, @dst_begin_day, @dst_end_month, @dst_end_day)

      # ------------------------------- #
      # Check for errors within objects #
      # ------------------------------- #

      # Ask objects to check for errors
      self.class::CLASS_ATTRS.each do |attribute|
        hpxml_obj = send(attribute)
        if not hpxml_obj.respond_to? :check_for_errors
          fail "Need to add 'check_for_errors' method to #{hpxml_obj.class} class."
        end

        errors += hpxml_obj.check_for_errors
      end

      # ------------------------------- #
      # Check for errors across objects #
      # ------------------------------- #

      # Check for HVAC systems referenced by multiple water heating systems
      hvac_systems.each do |hvac_system|
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
      if not @building_construction.conditioned_floor_area.nil?
        air_distributions = @hvac_distributions.select { |dist| dist if HPXML::HVACDistributionTypeAir == dist.distribution_system_type }
        heating_dist = []
        cooling_dist = []
        air_distributions.each do |dist|
          heating_systems = dist.hvac_systems.select { |sys| sys if (sys.respond_to? :fraction_heat_load_served) && (sys.fraction_heat_load_served.to_f > 0) }
          cooling_systems = dist.hvac_systems.select { |sys| sys if (sys.respond_to? :fraction_cool_load_served) && (sys.fraction_cool_load_served.to_f > 0) }
          if heating_systems.size > 0
            heating_dist << dist
          end
          if cooling_systems.size > 0
            cooling_dist << dist
          end
        end
        heating_total_dist_cfa_served = heating_dist.map { |htg_dist| htg_dist.conditioned_floor_area_served.to_f }.sum(0.0)
        cooling_total_dist_cfa_served = cooling_dist.map { |clg_dist| clg_dist.conditioned_floor_area_served.to_f }.sum(0.0)
        if (heating_total_dist_cfa_served > @building_construction.conditioned_floor_area + 1.0) # Allow 1 ft2 of tolerance
          errors << 'The total conditioned floor area served by the HVAC distribution system(s) for heating is larger than the conditioned floor area of the building.'
        end
        if (cooling_total_dist_cfa_served > @building_construction.conditioned_floor_area + 1.0) # Allow 1 ft2 of tolerance
          errors << 'The total conditioned floor area served by the HVAC distribution system(s) for cooling is larger than the conditioned floor area of the building.'
        end
      end

      # Check for correct PrimaryIndicator values across all refrigerators
      if @refrigerators.size > 1
        primary_indicators = @refrigerators.select { |r| r.primary_indicator }.size
        if primary_indicators > 1
          errors << 'More than one refrigerator designated as the primary.'
        elsif primary_indicators == 0
          errors << 'Could not find a primary refrigerator.'
        end
      end

      # Check for correct PrimaryHeatingSystem values across all HVAC systems
      n_primary_heating = @heating_systems.select { |h| h.primary_system }.size +
                          @heat_pumps.select { |h| h.primary_heating_system }.size
      if n_primary_heating > 1
        errors << 'More than one heating system designated as the primary.'
      end

      # Check for correct PrimaryCoolingSystem values across all HVAC systems
      n_primary_cooling = @cooling_systems.select { |c| c.primary_system }.size +
                          @heat_pumps.select { |c| c.primary_cooling_system }.size
      if n_primary_cooling > 1
        errors << 'More than one cooling system designated as the primary.'
      end

      # Check for at most 1 shared heating system and 1 shared cooling system
      num_htg_shared = 0
      num_clg_shared = 0
      (@heating_systems + @heat_pumps).each do |hvac_system|
        next unless hvac_system.is_shared_system

        num_htg_shared += 1
      end
      (@cooling_systems + @heat_pumps).each do |hvac_system|
        next unless hvac_system.is_shared_system

        num_clg_shared += 1
      end
      if num_htg_shared > 1
        errors << 'More than one shared heating system found.'
      end
      if num_clg_shared > 1
        errors << 'More than one shared cooling system found.'
      end

      return errors
    end

    def collapse_enclosure_surfaces(surf_types_of_interest = nil)
      # Collapses like surfaces into a single surface with, e.g., aggregate surface area.
      # This can significantly speed up performance for HPXML files with lots of individual
      # surfaces (e.g., windows).

      surf_types = { roofs: @roofs,
                     walls: @walls,
                     rim_joists: @rim_joists,
                     foundation_walls: @foundation_walls,
                     floors: @floors,
                     slabs: @slabs,
                     windows: @windows,
                     skylights: @skylights,
                     doors: @doors }

      attrs_to_ignore = [:id,
                         :insulation_id,
                         :perimeter_insulation_id,
                         :under_slab_insulation_id,
                         :area,
                         :length,
                         :exposed_perimeter,
                         :interior_shading_id,
                         :exterior_shading_id]

      # Look for pairs of surfaces that can be collapsed
      like_foundation_walls = {}
      surf_types.each do |surf_type, surfaces|
        next unless surf_types_of_interest.nil? || surf_types_of_interest.include?(surf_type)

        for i in 0..surfaces.size - 1
          surf = surfaces[i]
          next if surf.nil?

          for j in (surfaces.size - 1).downto(i + 1)
            surf2 = surfaces[j]
            next if surf2.nil?

            match = true
            surf.class::ATTRS.each do |attribute|
              next if attribute.to_s.end_with? '_isdefaulted'
              next if attrs_to_ignore.include? attribute
              next if (surf_type == :foundation_walls) && ([:azimuth, :orientation].include? attribute) # Azimuth of foundation walls is irrelevant
              next if (surf_type == :foundation_walls) && (attribute == :depth_below_grade) # Ignore BG depth difference; we will later calculate an effective BG depth for the combined surface
              next if surf.send(attribute) == surf2.send(attribute)

              match = false
              break
            end
            next unless match

            if (surf_type == :foundation_walls) && (surf.depth_below_grade != surf2.depth_below_grade)
              if like_foundation_walls[surf].nil?
                like_foundation_walls[surf] = [{ bgdepth: surf.depth_below_grade, length: surf.area / surf.height }]
              end
              like_foundation_walls[surf] << { bgdepth: surf2.depth_below_grade, length: surf2.area / surf2.height }
            end

            # Update values
            if (not surf.area.nil?) && (not surf2.area.nil?)
              surf.area += surf2.area
            end
            if (surf_type == :slabs) && (not surf.exposed_perimeter.nil?) && (not surf2.exposed_perimeter.nil?)
              surf.exposed_perimeter += surf2.exposed_perimeter
            end
            if (surf_type == :foundation_walls) && (not surf.length.nil?) && (not surf2.length.nil?)
              surf.length += surf2.length
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

      like_foundation_walls.each do |foundation_wall, properties|
        # Calculate weighted-average (by length) below-grade depth
        foundation_wall.depth_below_grade = properties.map { |p| p[:bgdepth] * p[:length] }.sum(0.0) / properties.map { |p| p[:length] }.sum
      end
    end
  end

  class Site < BaseElement
    ATTRS = [:site_type, :surroundings, :vertical_surroundings, :shielding_of_home, :orientation_of_front_of_home, :azimuth_of_front_of_home, :fuels,
             :soil_type, :moisture_type, :ground_conductivity, :ground_diffusivity]
    attr_accessor(*ATTRS)

    def check_for_errors
      errors = []
      return errors
    end

    def to_doc(building)
      return if nil?

      site = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'BuildingSummary', 'Site'])
      XMLHelper.add_element(site, 'SiteType', @site_type, :string, @site_type_isdefaulted) unless @site_type.nil?
      XMLHelper.add_element(site, 'Surroundings', @surroundings, :string) unless @surroundings.nil?
      XMLHelper.add_element(site, 'VerticalSurroundings', @vertical_surroundings, :string) unless @vertical_surroundings.nil?
      XMLHelper.add_element(site, 'ShieldingofHome', @shielding_of_home, :string, @shielding_of_home_isdefaulted) unless @shielding_of_home.nil?
      XMLHelper.add_element(site, 'OrientationOfFrontOfHome', @orientation_of_front_of_home, :string) unless @orientation_of_front_of_home.nil?
      XMLHelper.add_element(site, 'AzimuthOfFrontOfHome', @azimuth_of_front_of_home, :integer) unless @azimuth_of_front_of_home.nil?
      if (not @fuels.nil?) && (not @fuels.empty?)
        fuel_types_available = XMLHelper.add_element(site, 'FuelTypesAvailable')
        @fuels.each do |fuel|
          XMLHelper.add_element(fuel_types_available, 'Fuel', fuel, :string)
        end
      end
      if (not @soil_type.nil?) || (not @moisture_type.nil?) || (not @ground_conductivity.nil?) || (not @ground_diffusivity.nil?)
        soil = XMLHelper.add_element(site, 'Soil')
        XMLHelper.add_element(soil, 'SoilType', @soil_type, :string, @soil_type_isdefaulted) unless @soil_type.nil?
        XMLHelper.add_element(soil, 'MoistureType', @moisture_type, :string, @moisture_type_isdefaulted) unless @moisture_type.nil?
        XMLHelper.add_element(soil, 'Conductivity', @ground_conductivity, :float, @ground_conductivity_isdefaulted) unless @ground_conductivity.nil?
        if not @ground_diffusivity.nil?
          extension = XMLHelper.create_elements_as_needed(soil, ['extension'])
          XMLHelper.add_element(extension, 'Diffusivity', @ground_diffusivity, :float, @ground_diffusivity_isdefaulted) unless @ground_diffusivity.nil?
        end
      end

      if site.children.size == 0
        bldg_summary = XMLHelper.get_element(doc, '/HPXML/Building/BuildingDetails/BuildingSummary')
        XMLHelper.delete_element(bldg_summary, 'Site')
      end
    end

    def from_doc(building)
      return if building.nil?

      site = XMLHelper.get_element(building, 'BuildingDetails/BuildingSummary/Site')
      return if site.nil?

      @site_type = XMLHelper.get_value(site, 'SiteType', :string)
      @surroundings = XMLHelper.get_value(site, 'Surroundings', :string)
      @vertical_surroundings = XMLHelper.get_value(site, 'VerticalSurroundings', :string)
      @shielding_of_home = XMLHelper.get_value(site, 'ShieldingofHome', :string)
      @orientation_of_front_of_home = XMLHelper.get_value(site, 'OrientationOfFrontOfHome', :string)
      @azimuth_of_front_of_home = XMLHelper.get_value(site, 'AzimuthOfFrontOfHome', :integer)
      @fuels = XMLHelper.get_values(site, 'FuelTypesAvailable/Fuel', :string)
      @soil_type = XMLHelper.get_value(site, 'Soil/SoilType', :string)
      @moisture_type = XMLHelper.get_value(site, 'Soil/MoistureType', :string)
      @ground_conductivity = XMLHelper.get_value(site, 'Soil/Conductivity', :float)
      @ground_diffusivity = XMLHelper.get_value(site, 'Soil/extension/Diffusivity', :float)
    end
  end

  class NeighborBuildings < BaseArrayElement
    def add(**kwargs)
      self << NeighborBuilding.new(@parent_object, **kwargs)
    end

    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/BuildingSummary/Site/extension/Neighbors/NeighborBuilding').each do |neighbor_building|
        self << NeighborBuilding.new(@parent_object, neighbor_building)
      end
    end
  end

  class NeighborBuilding < BaseElement
    ATTRS = [:azimuth, :orientation, :distance, :height]
    attr_accessor(*ATTRS)

    def check_for_errors
      errors = []
      return errors
    end

    def to_doc(building)
      return if nil?

      neighbors = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'BuildingSummary', 'Site', 'extension', 'Neighbors'])
      neighbor_building = XMLHelper.add_element(neighbors, 'NeighborBuilding')
      XMLHelper.add_element(neighbor_building, 'Orientation', @orientation, :string, @orientation_isdefaulted) unless @orientation.nil?
      XMLHelper.add_element(neighbor_building, 'Azimuth', @azimuth, :integer, @azimuth_isdefaulted) unless @azimuth.nil?
      XMLHelper.add_element(neighbor_building, 'Distance', @distance, :float) unless @distance.nil?
      XMLHelper.add_element(neighbor_building, 'Height', @height, :float) unless @height.nil?
    end

    def from_doc(neighbor_building)
      return if neighbor_building.nil?

      @orientation = XMLHelper.get_value(neighbor_building, 'Orientation', :string)
      @azimuth = XMLHelper.get_value(neighbor_building, 'Azimuth', :integer)
      @distance = XMLHelper.get_value(neighbor_building, 'Distance', :float)
      @height = XMLHelper.get_value(neighbor_building, 'Height', :float)
    end
  end

  class BuildingOccupancy < BaseElement
    ATTRS = [:number_of_residents, :weekday_fractions, :weekend_fractions, :monthly_multipliers, :general_water_use_usage_multiplier,
             :general_water_use_weekday_fractions, :general_water_use_weekend_fractions, :general_water_use_monthly_multipliers]
    attr_accessor(*ATTRS)

    def check_for_errors
      errors = []
      return errors
    end

    def to_doc(building)
      return if nil?

      building_occupancy = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'BuildingSummary', 'BuildingOccupancy'])
      XMLHelper.add_element(building_occupancy, 'NumberofResidents', @number_of_residents, :float, @number_of_residents_isdefaulted) unless @number_of_residents.nil?
      XMLHelper.add_extension(building_occupancy, 'WeekdayScheduleFractions', @weekday_fractions, :string, @weekday_fractions_isdefaulted) unless @weekday_fractions.nil?
      XMLHelper.add_extension(building_occupancy, 'WeekendScheduleFractions', @weekend_fractions, :string, @weekend_fractions_isdefaulted) unless @weekend_fractions.nil?
      XMLHelper.add_extension(building_occupancy, 'MonthlyScheduleMultipliers', @monthly_multipliers, :string, @monthly_multipliers_isdefaulted) unless @monthly_multipliers.nil?
      XMLHelper.add_extension(building_occupancy, 'GeneralWaterUseUsageMultiplier', @general_water_use_usage_multiplier, :float, @general_water_use_usage_multiplier_isdefaulted) unless @general_water_use_usage_multiplier.nil?
      XMLHelper.add_extension(building_occupancy, 'GeneralWaterUseWeekdayScheduleFractions', @general_water_use_weekday_fractions, :string, @general_water_use_weekday_fractions_isdefaulted) unless @general_water_use_weekday_fractions.nil?
      XMLHelper.add_extension(building_occupancy, 'GeneralWaterUseWeekendScheduleFractions', @general_water_use_weekend_fractions, :string, @general_water_use_weekend_fractions_isdefaulted) unless @general_water_use_weekend_fractions.nil?
      XMLHelper.add_extension(building_occupancy, 'GeneralWaterUseMonthlyScheduleMultipliers', @general_water_use_monthly_multipliers, :string, @general_water_use_monthly_multipliers_isdefaulted) unless @general_water_use_monthly_multipliers.nil?
    end

    def from_doc(building)
      return if building.nil?

      building_occupancy = XMLHelper.get_element(building, 'BuildingDetails/BuildingSummary/BuildingOccupancy')
      return if building_occupancy.nil?

      @number_of_residents = XMLHelper.get_value(building_occupancy, 'NumberofResidents', :float)
      @weekday_fractions = XMLHelper.get_value(building_occupancy, 'extension/WeekdayScheduleFractions', :string)
      @weekend_fractions = XMLHelper.get_value(building_occupancy, 'extension/WeekendScheduleFractions', :string)
      @monthly_multipliers = XMLHelper.get_value(building_occupancy, 'extension/MonthlyScheduleMultipliers', :string)
      @general_water_use_usage_multiplier = XMLHelper.get_value(building_occupancy, 'extension/GeneralWaterUseUsageMultiplier', :float)
      @general_water_use_weekday_fractions = XMLHelper.get_value(building_occupancy, 'extension/GeneralWaterUseWeekdayScheduleFractions', :string)
      @general_water_use_weekend_fractions = XMLHelper.get_value(building_occupancy, 'extension/GeneralWaterUseWeekendScheduleFractions', :string)
      @general_water_use_monthly_multipliers = XMLHelper.get_value(building_occupancy, 'extension/GeneralWaterUseMonthlyScheduleMultipliers', :string)
    end
  end

  class BuildingConstruction < BaseElement
    ATTRS = [:year_built, :number_of_conditioned_floors, :number_of_conditioned_floors_above_grade,
             :average_ceiling_height, :number_of_bedrooms, :number_of_bathrooms,
             :conditioned_floor_area, :conditioned_building_volume, :residential_facility_type,
             :building_footprint_area, :number_of_units, :number_of_units_in_building]
    attr_accessor(*ATTRS)

    def check_for_errors
      errors = []
      return errors
    end

    def to_doc(building)
      return if nil?

      building_construction = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'BuildingSummary', 'BuildingConstruction'])
      XMLHelper.add_element(building_construction, 'YearBuilt', @year_built, :integer) unless @year_built.nil?
      XMLHelper.add_element(building_construction, 'ResidentialFacilityType', @residential_facility_type, :string) unless @residential_facility_type.nil?
      XMLHelper.add_element(building_construction, 'NumberofUnits', @number_of_units, :integer, @number_of_units_isdefaulted) unless @number_of_units.nil?
      XMLHelper.add_element(building_construction, 'NumberofUnitsInBuilding', @number_of_units_in_building, :integer) unless @number_of_units_in_building.nil?
      XMLHelper.add_element(building_construction, 'NumberofConditionedFloors', @number_of_conditioned_floors, :float) unless @number_of_conditioned_floors.nil?
      XMLHelper.add_element(building_construction, 'NumberofConditionedFloorsAboveGrade', @number_of_conditioned_floors_above_grade, :float) unless @number_of_conditioned_floors_above_grade.nil?
      XMLHelper.add_element(building_construction, 'AverageCeilingHeight', @average_ceiling_height, :float, @average_ceiling_height_isdefaulted) unless @average_ceiling_height.nil?
      XMLHelper.add_element(building_construction, 'NumberofBedrooms', @number_of_bedrooms, :integer) unless @number_of_bedrooms.nil?
      XMLHelper.add_element(building_construction, 'NumberofBathrooms', @number_of_bathrooms, :integer, @number_of_bathrooms_isdefaulted) unless @number_of_bathrooms.nil?
      XMLHelper.add_element(building_construction, 'BuildingFootprintArea', @building_footprint_area, :float, @building_footprint_area_isdefaulted) unless @building_footprint_area.nil?
      XMLHelper.add_element(building_construction, 'ConditionedFloorArea', @conditioned_floor_area, :float) unless @conditioned_floor_area.nil?
      XMLHelper.add_element(building_construction, 'ConditionedBuildingVolume', @conditioned_building_volume, :float, @conditioned_building_volume_isdefaulted) unless @conditioned_building_volume.nil?
    end

    def from_doc(building)
      return if building.nil?

      building_construction = XMLHelper.get_element(building, 'BuildingDetails/BuildingSummary/BuildingConstruction')
      return if building_construction.nil?

      @year_built = XMLHelper.get_value(building_construction, 'YearBuilt', :integer)
      @residential_facility_type = XMLHelper.get_value(building_construction, 'ResidentialFacilityType', :string)
      @number_of_units = XMLHelper.get_value(building_construction, 'NumberofUnits', :integer)
      @number_of_units_in_building = XMLHelper.get_value(building_construction, 'NumberofUnitsInBuilding', :integer)
      @number_of_conditioned_floors = XMLHelper.get_value(building_construction, 'NumberofConditionedFloors', :float)
      @number_of_conditioned_floors_above_grade = XMLHelper.get_value(building_construction, 'NumberofConditionedFloorsAboveGrade', :float)
      @average_ceiling_height = XMLHelper.get_value(building_construction, 'AverageCeilingHeight', :float)
      @number_of_bedrooms = XMLHelper.get_value(building_construction, 'NumberofBedrooms', :integer)
      @number_of_bathrooms = XMLHelper.get_value(building_construction, 'NumberofBathrooms', :integer)
      @building_footprint_area = XMLHelper.get_value(building_construction, 'BuildingFootprintArea', :float)
      @conditioned_floor_area = XMLHelper.get_value(building_construction, 'ConditionedFloorArea', :float)
      @conditioned_building_volume = XMLHelper.get_value(building_construction, 'ConditionedBuildingVolume', :float)
    end
  end

  class BuildingHeader < BaseElement
    ATTRS = [:schedules_filepaths, :extension_properties, :natvent_days_per_week,
             :heat_pump_sizing_methodology, :allow_increased_fixed_capacities,
             :shading_summer_begin_month, :shading_summer_begin_day, :shading_summer_end_month,
             :shading_summer_end_day, :manualj_heating_design_temp, :manualj_cooling_design_temp,
             :manualj_heating_setpoint, :manualj_cooling_setpoint, :manualj_humidity_setpoint,
             :manualj_internal_loads_sensible, :manualj_internal_loads_latent, :manualj_num_occupants]
    attr_accessor(*ATTRS)

    def check_for_errors
      errors = []
      errors += HPXML::check_dates('Shading Summer Season', @shading_summer_begin_month, @shading_summer_begin_day, @shading_summer_end_month, @shading_summer_end_day)
      return errors
    end

    def to_doc(building)
      return if nil?

      building_summary = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'BuildingSummary'])
      if (not @heat_pump_sizing_methodology.nil?) || (not @allow_increased_fixed_capacities.nil?)
        hvac_sizing_control = XMLHelper.create_elements_as_needed(building_summary, ['extension', 'HVACSizingControl'])
        XMLHelper.add_element(hvac_sizing_control, 'HeatPumpSizingMethodology', @heat_pump_sizing_methodology, :string, @heat_pump_sizing_methodology_isdefaulted) unless @heat_pump_sizing_methodology.nil?
        XMLHelper.add_element(hvac_sizing_control, 'AllowIncreasedFixedCapacities', @allow_increased_fixed_capacities, :boolean, @allow_increased_fixed_capacities_isdefaulted) unless @allow_increased_fixed_capacities.nil?
      end
      if (not @manualj_heating_design_temp.nil?) || (not @manualj_cooling_design_temp.nil?) || (not @manualj_heating_setpoint.nil?) || (not @manualj_cooling_setpoint.nil?) || (not @manualj_humidity_setpoint.nil?) || (not @manualj_internal_loads_sensible.nil?) || (not @manualj_internal_loads_latent.nil?) || (not @manualj_num_occupants.nil?)
        manualj_sizing_inputs = XMLHelper.create_elements_as_needed(building_summary, ['extension', 'HVACSizingControl', 'ManualJInputs'])
        XMLHelper.add_element(manualj_sizing_inputs, 'HeatingDesignTemperature', @manualj_heating_design_temp, :float, @manualj_heating_design_temp_isdefaulted) unless @manualj_heating_design_temp.nil?
        XMLHelper.add_element(manualj_sizing_inputs, 'CoolingDesignTemperature', @manualj_cooling_design_temp, :float, @manualj_cooling_design_temp_isdefaulted) unless @manualj_cooling_design_temp.nil?
        XMLHelper.add_element(manualj_sizing_inputs, 'HeatingSetpoint', @manualj_heating_setpoint, :float, @manualj_heating_setpoint_isdefaulted) unless @manualj_heating_setpoint.nil?
        XMLHelper.add_element(manualj_sizing_inputs, 'CoolingSetpoint', @manualj_cooling_setpoint, :float, @manualj_cooling_setpoint_isdefaulted) unless @manualj_cooling_setpoint.nil?
        XMLHelper.add_element(manualj_sizing_inputs, 'HumiditySetpoint', @manualj_humidity_setpoint, :float, @manualj_humidity_setpoint_isdefaulted) unless @manualj_humidity_setpoint.nil?
        XMLHelper.add_element(manualj_sizing_inputs, 'InternalLoadsSensible', @manualj_internal_loads_sensible, :float, @manualj_internal_loads_sensible_isdefaulted) unless @manualj_internal_loads_sensible.nil?
        XMLHelper.add_element(manualj_sizing_inputs, 'InternalLoadsLatent', @manualj_internal_loads_latent, :float, @manualj_internal_loads_latent_isdefaulted) unless @manualj_internal_loads_latent.nil?
        XMLHelper.add_element(manualj_sizing_inputs, 'NumberofOccupants', @manualj_num_occupants, :integer, @manualj_num_occupants_isdefaulted) unless @manualj_num_occupants.nil?
      end
      XMLHelper.add_extension(building_summary, 'NaturalVentilationAvailabilityDaysperWeek', @natvent_days_per_week, :integer, @natvent_days_per_week_isdefaulted) unless @natvent_days_per_week.nil?
      if (not @schedules_filepaths.nil?) && (not @schedules_filepaths.empty?)
        @schedules_filepaths.each do |schedules_filepath|
          XMLHelper.add_extension(building_summary, 'SchedulesFilePath', schedules_filepath, :string)
        end
      end
      if (not @shading_summer_begin_month.nil?) || (not @shading_summer_begin_day.nil?) || (not @shading_summer_end_month.nil?) || (not @shading_summer_end_day.nil?)
        window_shading_season = XMLHelper.create_elements_as_needed(building_summary, ['extension', 'ShadingControl'])
        XMLHelper.add_element(window_shading_season, 'SummerBeginMonth', @shading_summer_begin_month, :integer, @shading_summer_begin_month_isdefaulted) unless @shading_summer_begin_month.nil?
        XMLHelper.add_element(window_shading_season, 'SummerBeginDayOfMonth', @shading_summer_begin_day, :integer, @shading_summer_begin_day_isdefaulted) unless @shading_summer_begin_day.nil?
        XMLHelper.add_element(window_shading_season, 'SummerEndMonth', @shading_summer_end_month, :integer, @shading_summer_end_month_isdefaulted) unless @shading_summer_end_month.nil?
        XMLHelper.add_element(window_shading_season, 'SummerEndDayOfMonth', @shading_summer_end_day, :integer, @shading_summer_end_day_isdefaulted) unless @shading_summer_end_day.nil?
      end
      if (not @extension_properties.nil?) && (not @extension_properties.empty?)
        properties = XMLHelper.create_elements_as_needed(building_summary, ['extension', 'AdditionalProperties'])
        @extension_properties.each do |key, value|
          XMLHelper.add_element(properties, key, value, :string)
        end
      end
    end

    def from_doc(building)
      return if building.nil?

      @schedules_filepaths = XMLHelper.get_values(building, 'BuildingDetails/BuildingSummary/extension/SchedulesFilePath', :string)
      @natvent_days_per_week = XMLHelper.get_value(building, 'BuildingDetails/BuildingSummary/extension/NaturalVentilationAvailabilityDaysperWeek', :integer)
      @shading_summer_begin_month = XMLHelper.get_value(building, 'BuildingDetails/BuildingSummary/extension/ShadingControl/SummerBeginMonth', :integer)
      @shading_summer_begin_day = XMLHelper.get_value(building, 'BuildingDetails/BuildingSummary/extension/ShadingControl/SummerBeginDayOfMonth', :integer)
      @shading_summer_end_month = XMLHelper.get_value(building, 'BuildingDetails/BuildingSummary/extension/ShadingControl/SummerEndMonth', :integer)
      @shading_summer_end_day = XMLHelper.get_value(building, 'BuildingDetails/BuildingSummary/extension/ShadingControl/SummerEndDayOfMonth', :integer)
      @heat_pump_sizing_methodology = XMLHelper.get_value(building, 'BuildingDetails/BuildingSummary/extension/HVACSizingControl/HeatPumpSizingMethodology', :string)
      @allow_increased_fixed_capacities = XMLHelper.get_value(building, 'BuildingDetails/BuildingSummary/extension/HVACSizingControl/AllowIncreasedFixedCapacities', :boolean)
      @manualj_heating_design_temp = XMLHelper.get_value(building, 'BuildingDetails/BuildingSummary/extension/HVACSizingControl/ManualJInputs/HeatingDesignTemperature', :float)
      @manualj_cooling_design_temp = XMLHelper.get_value(building, 'BuildingDetails/BuildingSummary/extension/HVACSizingControl/ManualJInputs/CoolingDesignTemperature', :float)
      @manualj_heating_setpoint = XMLHelper.get_value(building, 'BuildingDetails/BuildingSummary/extension/HVACSizingControl/ManualJInputs/HeatingSetpoint', :float)
      @manualj_cooling_setpoint = XMLHelper.get_value(building, 'BuildingDetails/BuildingSummary/extension/HVACSizingControl/ManualJInputs/CoolingSetpoint', :float)
      @manualj_humidity_setpoint = XMLHelper.get_value(building, 'BuildingDetails/BuildingSummary/extension/HVACSizingControl/ManualJInputs/HumiditySetpoint', :float)
      @manualj_internal_loads_sensible = XMLHelper.get_value(building, 'BuildingDetails/BuildingSummary/extension/HVACSizingControl/ManualJInputs/InternalLoadsSensible', :float)
      @manualj_internal_loads_latent = XMLHelper.get_value(building, 'BuildingDetails/BuildingSummary/extension/HVACSizingControl/ManualJInputs/InternalLoadsLatent', :float)
      @manualj_num_occupants = XMLHelper.get_value(building, 'BuildingDetails/BuildingSummary/extension/HVACSizingControl/ManualJInputs/NumberofOccupants', :integer)
      @extension_properties = {}
      XMLHelper.get_elements(building, 'BuildingDetails/BuildingSummary/extension/AdditionalProperties').each do |property|
        property.children.each do |child|
          next unless child.is_a? Oga::XML::Element

          @extension_properties[child.name] = child.text
          @extension_properties[child.name] = nil if @extension_properties[child.name].empty?
        end
      end
    end
  end

  class ClimateandRiskZones < BaseElement
    def initialize(hpxml_bldg, *args)
      @climate_zone_ieccs = ClimateZoneIECCs.new(hpxml_bldg)
      super(hpxml_bldg, *args)
    end
    ATTRS = [:weather_station_id, :weather_station_name, :weather_station_wmo, :weather_station_epw_filepath]
    attr_accessor(*ATTRS)
    attr_reader(:climate_zone_ieccs)

    def check_for_errors
      errors = []
      errors += @climate_zone_ieccs.check_for_errors
      return errors
    end

    def to_doc(building)
      return if nil?

      climate_and_risk_zones = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'ClimateandRiskZones'])

      @climate_zone_ieccs.to_doc(climate_and_risk_zones)

      if not @weather_station_id.nil?
        weather_station = XMLHelper.add_element(climate_and_risk_zones, 'WeatherStation')
        sys_id = XMLHelper.add_element(weather_station, 'SystemIdentifier')
        XMLHelper.add_attribute(sys_id, 'id', @weather_station_id)
        XMLHelper.add_element(weather_station, 'Name', @weather_station_name, :string) unless @weather_station_name.nil?
        XMLHelper.add_element(weather_station, 'WMO', @weather_station_wmo, :string) unless @weather_station_wmo.nil?
        XMLHelper.add_extension(weather_station, 'EPWFilePath', @weather_station_epw_filepath, :string) unless @weather_station_epw_filepath.nil?
      end
    end

    def from_doc(building)
      return if building.nil?

      climate_and_risk_zones = XMLHelper.get_element(building, 'BuildingDetails/ClimateandRiskZones')
      return if climate_and_risk_zones.nil?

      @climate_zone_ieccs.from_doc(climate_and_risk_zones)

      weather_station = XMLHelper.get_element(climate_and_risk_zones, 'WeatherStation')
      if not weather_station.nil?
        @weather_station_id = HPXML::get_id(weather_station)
        @weather_station_name = XMLHelper.get_value(weather_station, 'Name', :string)
        @weather_station_wmo = XMLHelper.get_value(weather_station, 'WMO', :string)
        @weather_station_epw_filepath = XMLHelper.get_value(weather_station, 'extension/EPWFilePath', :string)
      end
    end
  end

  class ClimateZoneIECCs < BaseArrayElement
    def add(**kwargs)
      self << ClimateZoneIECC.new(@parent_object, **kwargs)
    end

    def from_doc(climate_and_risk_zones)
      return if climate_and_risk_zones.nil?

      XMLHelper.get_elements(climate_and_risk_zones, 'ClimateZoneIECC').each do |climate_zone_iecc|
        self << ClimateZoneIECC.new(@parent_object, climate_zone_iecc)
      end
    end
  end

  class ClimateZoneIECC < BaseElement
    ATTRS = [:year, :zone]
    attr_accessor(*ATTRS)

    def delete
      @parent_object.climate_and_risk_zones.climate_zone_ieccs.delete(self)
    end

    def check_for_errors
      errors = []
      return errors
    end

    def to_doc(climate_and_risk_zones)
      climate_zone_iecc = XMLHelper.add_element(climate_and_risk_zones, 'ClimateZoneIECC')
      XMLHelper.add_element(climate_zone_iecc, 'Year', @year, :integer, @year_isdefaulted) unless @year.nil?
      XMLHelper.add_element(climate_zone_iecc, 'ClimateZone', @zone, :string, @zone_isdefaulted) unless @zone.nil?
    end

    def from_doc(climate_zone_iecc)
      return if climate_zone_iecc.nil?

      @year = XMLHelper.get_value(climate_zone_iecc, 'Year', :integer)
      @zone = XMLHelper.get_value(climate_zone_iecc, 'ClimateZone', :string)
    end
  end

  class AirInfiltration < BaseElement
    ATTRS = [:has_flue_or_chimney_in_conditioned_space]
    attr_accessor(*ATTRS)

    def check_for_errors
      errors = []
      return errors
    end

    def to_doc(building)
      return if nil?

      air_infiltration = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Enclosure', 'AirInfiltration'])
      XMLHelper.add_extension(air_infiltration, 'HasFlueOrChimneyInConditionedSpace', @has_flue_or_chimney_in_conditioned_space, :boolean, @has_flue_or_chimney_in_conditioned_space_isdefaulted) unless @has_flue_or_chimney_in_conditioned_space.nil?
    end

    def from_doc(building)
      return if building.nil?

      air_infiltration = XMLHelper.get_element(building, 'BuildingDetails/Enclosure/AirInfiltration')
      return if air_infiltration.nil?

      @has_flue_or_chimney_in_conditioned_space = XMLHelper.get_value(air_infiltration, 'extension/HasFlueOrChimneyInConditionedSpace', :boolean)
    end
  end

  class AirInfiltrationMeasurements < BaseArrayElement
    def add(**kwargs)
      self << AirInfiltrationMeasurement.new(@parent_object, **kwargs)
    end

    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/Enclosure/AirInfiltration/AirInfiltrationMeasurement').each do |air_infiltration_measurement|
        self << AirInfiltrationMeasurement.new(@parent_object, air_infiltration_measurement)
      end
    end
  end

  class AirInfiltrationMeasurement < BaseElement
    ATTRS = [:id, :house_pressure, :unit_of_measure, :air_leakage, :effective_leakage_area, :type_of_measurement,
             :infiltration_volume, :leakiness_description, :infiltration_height, :a_ext, :infiltration_type]
    attr_accessor(*ATTRS)

    def check_for_errors
      errors = []
      return errors
    end

    def to_doc(building)
      return if nil?

      air_infiltration = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Enclosure', 'AirInfiltration'])
      air_infiltration_measurement = XMLHelper.add_element(air_infiltration, 'AirInfiltrationMeasurement')
      sys_id = XMLHelper.add_element(air_infiltration_measurement, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_element(air_infiltration_measurement, 'TypeOfInfiltrationMeasurement', @type_of_measurement, :string) unless @type_of_measurement.nil?
      XMLHelper.add_element(air_infiltration_measurement, 'TypeOfInfiltrationLeakage', @infiltration_type, :string) unless @infiltration_type.nil?
      XMLHelper.add_element(air_infiltration_measurement, 'HousePressure', @house_pressure, :float) unless @house_pressure.nil?
      XMLHelper.add_element(air_infiltration_measurement, 'LeakinessDescription', @leakiness_description, :string) unless @leakiness_description.nil?
      if (not @unit_of_measure.nil?) && (not @air_leakage.nil?)
        building_air_leakage = XMLHelper.add_element(air_infiltration_measurement, 'BuildingAirLeakage')
        XMLHelper.add_element(building_air_leakage, 'UnitofMeasure', @unit_of_measure, :string)
        XMLHelper.add_element(building_air_leakage, 'AirLeakage', @air_leakage, :float)
      end
      XMLHelper.add_element(air_infiltration_measurement, 'EffectiveLeakageArea', @effective_leakage_area, :float) unless @effective_leakage_area.nil?
      XMLHelper.add_element(air_infiltration_measurement, 'InfiltrationVolume', @infiltration_volume, :float, @infiltration_volume_isdefaulted) unless @infiltration_volume.nil?
      XMLHelper.add_element(air_infiltration_measurement, 'InfiltrationHeight', @infiltration_height, :float, @infiltration_height_isdefaulted) unless @infiltration_height.nil?
      XMLHelper.add_extension(air_infiltration_measurement, 'Aext', @a_ext, :float, @a_ext_isdefaulted) unless @a_ext.nil?
    end

    def from_doc(air_infiltration_measurement)
      return if air_infiltration_measurement.nil?

      @id = HPXML::get_id(air_infiltration_measurement)
      @type_of_measurement = XMLHelper.get_value(air_infiltration_measurement, 'TypeOfInfiltrationMeasurement', :string)
      @infiltration_type = XMLHelper.get_value(air_infiltration_measurement, 'TypeOfInfiltrationLeakage', :string)
      @house_pressure = XMLHelper.get_value(air_infiltration_measurement, 'HousePressure', :float)
      @leakiness_description = XMLHelper.get_value(air_infiltration_measurement, 'LeakinessDescription', :string)
      @unit_of_measure = XMLHelper.get_value(air_infiltration_measurement, 'BuildingAirLeakage/UnitofMeasure', :string)
      @air_leakage = XMLHelper.get_value(air_infiltration_measurement, 'BuildingAirLeakage/AirLeakage', :float)
      @effective_leakage_area = XMLHelper.get_value(air_infiltration_measurement, 'EffectiveLeakageArea', :float)
      @infiltration_volume = XMLHelper.get_value(air_infiltration_measurement, 'InfiltrationVolume', :float)
      @infiltration_height = XMLHelper.get_value(air_infiltration_measurement, 'InfiltrationHeight', :float)
      @a_ext = XMLHelper.get_value(air_infiltration_measurement, 'extension/Aext', :float)
    end
  end

  class Attics < BaseArrayElement
    def add(**kwargs)
      self << Attic.new(@parent_object, **kwargs)
    end

    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/Enclosure/Attics/Attic').each do |attic|
        self << Attic.new(@parent_object, attic)
      end
    end
  end

  class Attic < BaseElement
    ATTRS = [:id, :attic_type, :vented_attic_sla, :vented_attic_ach, :within_infiltration_volume,
             :attached_to_roof_idrefs, :attached_to_wall_idrefs, :attached_to_floor_idrefs]
    attr_accessor(*ATTRS)

    def attached_roofs
      return [] if @attached_to_roof_idrefs.nil?

      list = @parent_object.roofs.select { |roof| @attached_to_roof_idrefs.include? roof.id }
      if @attached_to_roof_idrefs.size > list.size
        fail "Attached roof not found for attic '#{@id}'."
      end

      return list
    end

    def attached_walls
      return [] if @attached_to_wall_idrefs.nil?

      list = @parent_object.walls.select { |wall| @attached_to_wall_idrefs.include? wall.id }
      if @attached_to_wall_idrefs.size > list.size
        fail "Attached wall not found for attic '#{@id}'."
      end

      return list
    end

    def attached_floors
      return [] if @attached_to_floor_idrefs.nil?

      list = @parent_object.floors.select { |floor| @attached_to_floor_idrefs.include? floor.id }
      if @attached_to_floor_idrefs.size > list.size
        fail "Attached floor not found for attic '#{@id}'."
      end

      return list
    end

    def to_location
      return if @attic_type.nil?

      if [AtticTypeCathedral, AtticTypeConditioned, AtticTypeFlatRoof, AtticTypeBelowApartment].include? @attic_type
        return LocationConditionedSpace
      elsif [AtticTypeUnvented].include? @attic_type
        return LocationAtticUnvented
      elsif [AtticTypeVented].include? @attic_type
        return LocationAtticVented
      else
        fail "Unexpected attic type: '#{@attic_type}'."
      end
    end

    def delete
      @parent_object.attics.delete(self)
    end

    def check_for_errors
      errors = []
      begin; attached_roofs; rescue StandardError => e; errors << e.message; end
      begin; attached_walls; rescue StandardError => e; errors << e.message; end
      begin; attached_floors; rescue StandardError => e; errors << e.message; end
      begin; to_location; rescue StandardError => e; errors << e.message; end
      return errors
    end

    def to_doc(building)
      return if nil?

      attics = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Enclosure', 'Attics'])
      attic = XMLHelper.add_element(attics, 'Attic')
      sys_id = XMLHelper.add_element(attic, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      if not @attic_type.nil?
        attic_type_el = XMLHelper.add_element(attic, 'AtticType')
        if [AtticTypeFlatRoof, AtticTypeCathedral, AtticTypeBelowApartment].include? @attic_type
          XMLHelper.add_element(attic_type_el, @attic_type)
        elsif [AtticTypeUnvented].include? @attic_type
          attic_type_attic = XMLHelper.add_element(attic_type_el, 'Attic')
          XMLHelper.add_element(attic_type_attic, 'Vented', false, :boolean)
        elsif [AtticTypeVented].include? @attic_type
          attic_type_attic = XMLHelper.add_element(attic_type_el, 'Attic')
          XMLHelper.add_element(attic_type_attic, 'Vented', true, :boolean)
          if not @vented_attic_sla.nil?
            ventilation_rate = XMLHelper.add_element(attic, 'VentilationRate')
            XMLHelper.add_element(ventilation_rate, 'UnitofMeasure', UnitsSLA, :string)
            XMLHelper.add_element(ventilation_rate, 'Value', @vented_attic_sla, :float, @vented_attic_sla_isdefaulted)
          elsif not @vented_attic_ach.nil?
            ventilation_rate = XMLHelper.add_element(attic, 'VentilationRate')
            XMLHelper.add_element(ventilation_rate, 'UnitofMeasure', UnitsACHNatural, :string)
            XMLHelper.add_element(ventilation_rate, 'Value', @vented_attic_ach, :float)
          end
        elsif [AtticTypeConditioned].include? @attic_type
          attic_type_attic = XMLHelper.add_element(attic_type_el, 'Attic')
          XMLHelper.add_element(attic_type_attic, 'Conditioned', true, :boolean)
        else
          fail "Unhandled attic type '#{@attic_type}'."
        end
      end
      XMLHelper.add_element(attic, 'WithinInfiltrationVolume', within_infiltration_volume, :boolean) unless @within_infiltration_volume.nil?
      if not @attached_to_roof_idrefs.nil?
        @attached_to_roof_idrefs.each do |roof|
          roof_attached = XMLHelper.add_element(attic, 'AttachedToRoof')
          XMLHelper.add_attribute(roof_attached, 'idref', roof)
        end
      end
      if not @attached_to_wall_idrefs.nil?
        @attached_to_wall_idrefs.each do |wall|
          wall_attached = XMLHelper.add_element(attic, 'AttachedToWall')
          XMLHelper.add_attribute(wall_attached, 'idref', wall)
        end
      end
      if not @attached_to_floor_idrefs.nil?
        @attached_to_floor_idrefs.each do |floor|
          floor_attached = XMLHelper.add_element(attic, 'AttachedToFloor')
          XMLHelper.add_attribute(floor_attached, 'idref', floor)
        end
      end
    end

    def from_doc(attic)
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
      elsif XMLHelper.has_element(attic, 'AtticType/BelowApartment')
        @attic_type = AtticTypeBelowApartment
      end
      if @attic_type == AtticTypeVented
        @vented_attic_sla = XMLHelper.get_value(attic, "VentilationRate[UnitofMeasure='#{UnitsSLA}']/Value", :float)
        @vented_attic_ach = XMLHelper.get_value(attic, "VentilationRate[UnitofMeasure='#{UnitsACHNatural}']/Value", :float)
      end
      @within_infiltration_volume = XMLHelper.get_value(attic, 'WithinInfiltrationVolume', :boolean)
      @attached_to_roof_idrefs = []
      XMLHelper.get_elements(attic, 'AttachedToRoof').each do |roof|
        @attached_to_roof_idrefs << HPXML::get_idref(roof)
      end
      @attached_to_wall_idrefs = []
      XMLHelper.get_elements(attic, 'AttachedToWall').each do |wall|
        @attached_to_wall_idrefs << HPXML::get_idref(wall)
      end
      @attached_to_floor_idrefs = []
      XMLHelper.get_elements(attic, 'AttachedToFloor').each do |floor|
        @attached_to_floor_idrefs << HPXML::get_idref(floor)
      end
    end
  end

  class Foundations < BaseArrayElement
    def add(**kwargs)
      self << Foundation.new(@parent_object, **kwargs)
    end

    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/Enclosure/Foundations/Foundation').each do |foundation|
        self << Foundation.new(@parent_object, foundation)
      end
    end
  end

  class Foundation < BaseElement
    ATTRS = [:id, :foundation_type, :vented_crawlspace_sla, :within_infiltration_volume,
             :belly_wing_skirt_present, :attached_to_slab_idrefs, :attached_to_floor_idrefs,
             :attached_to_foundation_wall_idrefs, :attached_to_wall_idrefs,
             :attached_to_rim_joist_idrefs]
    attr_accessor(*ATTRS)

    def attached_slabs
      return [] if @attached_to_slab_idrefs.nil?

      list = @parent_object.slabs.select { |slab| @attached_to_slab_idrefs.include? slab.id }
      if @attached_to_slab_idrefs.size > list.size
        fail "Attached slab not found for foundation '#{@id}'."
      end

      return list
    end

    def attached_floors
      return [] if @attached_to_floor_idrefs.nil?

      list = @parent_object.floors.select { |floor| @attached_to_floor_idrefs.include? floor.id }
      if @attached_to_floor_idrefs.size > list.size
        fail "Attached floor not found for foundation '#{@id}'."
      end

      return list
    end

    def attached_foundation_walls
      return [] if @attached_to_foundation_wall_idrefs.nil?

      list = @parent_object.foundation_walls.select { |foundation_wall| @attached_to_foundation_wall_idrefs.include? foundation_wall.id }
      if @attached_to_foundation_wall_idrefs.size > list.size
        fail "Attached foundation wall not found for foundation '#{@id}'."
      end

      return list
    end

    def attached_walls
      return [] if @attached_to_wall_idrefs.nil?

      list = @parent_object.walls.select { |wall| @attached_to_wall_idrefs.include? wall.id }
      if @attached_to_wall_idrefs.size > list.size
        fail "Attached wall not found for foundation '#{@id}'."
      end

      return list
    end

    def attached_rim_joists
      return [] if @attached_to_rim_joist_idrefs.nil?

      list = @parent_object.rim_joists.select { |rim_joist| @attached_to_rim_joist_idrefs.include? rim_joist.id }
      if @attached_to_rim_joist_idrefs.size > list.size
        fail "Attached rim joist not found for foundation '#{@id}'."
      end

      return list
    end

    def to_location
      return if @foundation_type.nil?

      if [FoundationTypeSlab, FoundationTypeAboveApartment].include? @foundation_type
        return LocationConditionedSpace
      elsif [FoundationTypeAmbient].include? @foundation_type
        return LocationOutside
      elsif [FoundationTypeBasementConditioned].include? @foundation_type
        return LocationBasementConditioned
      elsif [FoundationTypeBasementUnconditioned].include? @foundation_type
        return LocationBasementUnconditioned
      elsif [FoundationTypeCrawlspaceUnvented].include? @foundation_type
        return LocationCrawlspaceUnvented
      elsif [FoundationTypeCrawlspaceVented].include? @foundation_type
        return LocationCrawlspaceVented
      elsif @foundation_type == FoundationTypeCrawlspaceConditioned
        return LocationCrawlspaceConditioned
      elsif @foundation_type == FoundationTypeSlab
        return LocationConditionedSpace
      elsif @foundation_type == FoundationTypeBellyAndWing
        return LocationManufacturedHomeUnderBelly
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
        # Check Floors next
        attached_floors.each do |floor|
          sum_area += floor.area
        end
      end
      return sum_area
    end

    def delete
      @parent_object.foundations.delete(self)
    end

    def check_for_errors
      errors = []
      begin; attached_slabs; rescue StandardError => e; errors << e.message; end
      begin; attached_floors; rescue StandardError => e; errors << e.message; end
      begin; attached_foundation_walls; rescue StandardError => e; errors << e.message; end
      begin; attached_walls; rescue StandardError => e; errors << e.message; end
      begin; attached_rim_joists; rescue StandardError => e; errors << e.message; end
      begin; to_location; rescue StandardError => e; errors << e.message; end
      return errors
    end

    def to_doc(building)
      return if nil?

      foundations = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Enclosure', 'Foundations'])
      foundation = XMLHelper.add_element(foundations, 'Foundation')
      sys_id = XMLHelper.add_element(foundation, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      if not @foundation_type.nil?
        foundation_type_el = XMLHelper.add_element(foundation, 'FoundationType')
        if [FoundationTypeSlab, FoundationTypeAmbient, FoundationTypeAboveApartment].include? @foundation_type
          XMLHelper.add_element(foundation_type_el, @foundation_type)
        elsif [FoundationTypeBasementConditioned].include? @foundation_type
          basement = XMLHelper.add_element(foundation_type_el, 'Basement')
          XMLHelper.add_element(basement, 'Conditioned', true, :boolean)
        elsif [FoundationTypeBasementUnconditioned].include? @foundation_type
          basement = XMLHelper.add_element(foundation_type_el, 'Basement')
          XMLHelper.add_element(basement, 'Conditioned', false, :boolean)
        elsif [FoundationTypeCrawlspaceVented].include? @foundation_type
          crawlspace = XMLHelper.add_element(foundation_type_el, 'Crawlspace')
          XMLHelper.add_element(crawlspace, 'Vented', true, :boolean)
          if not @vented_crawlspace_sla.nil?
            ventilation_rate = XMLHelper.add_element(foundation, 'VentilationRate')
            XMLHelper.add_element(ventilation_rate, 'UnitofMeasure', UnitsSLA, :string)
            XMLHelper.add_element(ventilation_rate, 'Value', @vented_crawlspace_sla, :float, @vented_crawlspace_sla_isdefaulted)
          end
        elsif [FoundationTypeCrawlspaceUnvented].include? @foundation_type
          crawlspace = XMLHelper.add_element(foundation_type_el, 'Crawlspace')
          XMLHelper.add_element(crawlspace, 'Vented', false, :boolean)
        elsif @foundation_type == FoundationTypeCrawlspaceConditioned
          crawlspace = XMLHelper.add_element(foundation_type_el, 'Crawlspace')
          XMLHelper.add_element(crawlspace, 'Conditioned', true, :boolean)
        elsif @foundation_type == FoundationTypeBellyAndWing
          belly_and_wing = XMLHelper.add_element(foundation_type_el, 'BellyAndWing')
          XMLHelper.add_element(belly_and_wing, 'SkirtPresent', @belly_wing_skirt_present, :boolean, @belly_wing_skirt_present_isdefaulted) unless @belly_wing_skirt_present.nil?
        else
          fail "Unhandled foundation type '#{@foundation_type}'."
        end
      end
      XMLHelper.add_element(foundation, 'WithinInfiltrationVolume', @within_infiltration_volume, :boolean) unless @within_infiltration_volume.nil?
      if not @attached_to_rim_joist_idrefs.nil?
        @attached_to_rim_joist_idrefs.each do |rim_joist|
          rim_joist_attached = XMLHelper.add_element(foundation, 'AttachedToRimJoist')
          XMLHelper.add_attribute(rim_joist_attached, 'idref', rim_joist)
        end
      end
      if not @attached_to_wall_idrefs.nil?
        @attached_to_wall_idrefs.each do |wall|
          wall_attached = XMLHelper.add_element(foundation, 'AttachedToWall')
          XMLHelper.add_attribute(wall_attached, 'idref', wall)
        end
      end
      if not @attached_to_foundation_wall_idrefs.nil?
        @attached_to_foundation_wall_idrefs.each do |foundation_wall|
          foundation_wall_attached = XMLHelper.add_element(foundation, 'AttachedToFoundationWall')
          XMLHelper.add_attribute(foundation_wall_attached, 'idref', foundation_wall)
        end
      end
      if not @attached_to_floor_idrefs.nil?
        @attached_to_floor_idrefs.each do |floor|
          floor_attached = XMLHelper.add_element(foundation, 'AttachedToFloor')
          XMLHelper.add_attribute(floor_attached, 'idref', floor)
        end
      end
      if not @attached_to_slab_idrefs.nil?
        @attached_to_slab_idrefs.each do |slab|
          slab_attached = XMLHelper.add_element(foundation, 'AttachedToSlab')
          XMLHelper.add_attribute(slab_attached, 'idref', slab)
        end
      end
    end

    def from_doc(foundation)
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
      elsif XMLHelper.has_element(foundation, "FoundationType/Crawlspace[Conditioned='true']")
        @foundation_type = FoundationTypeCrawlspaceConditioned
      elsif XMLHelper.has_element(foundation, 'FoundationType/Ambient')
        @foundation_type = FoundationTypeAmbient
      elsif XMLHelper.has_element(foundation, 'FoundationType/AboveApartment')
        @foundation_type = FoundationTypeAboveApartment
      elsif XMLHelper.has_element(foundation, 'FoundationType/BellyAndWing')
        @foundation_type = FoundationTypeBellyAndWing
        @belly_wing_skirt_present = XMLHelper.get_value(foundation, 'FoundationType/BellyAndWing/SkirtPresent', :boolean)
      end
      if @foundation_type == FoundationTypeCrawlspaceVented
        @vented_crawlspace_sla = XMLHelper.get_value(foundation, "VentilationRate[UnitofMeasure='#{UnitsSLA}']/Value", :float)
      end
      @within_infiltration_volume = XMLHelper.get_value(foundation, 'WithinInfiltrationVolume', :boolean)
      @attached_to_rim_joist_idrefs = []
      XMLHelper.get_elements(foundation, 'AttachedToRimJoist').each do |rim_joist|
        @attached_to_rim_joist_idrefs << HPXML::get_idref(rim_joist)
      end
      @attached_to_wall_idrefs = []
      XMLHelper.get_elements(foundation, 'AttachedToWall').each do |wall|
        @attached_to_wall_idrefs << HPXML::get_idref(wall)
      end
      @attached_to_slab_idrefs = []
      XMLHelper.get_elements(foundation, 'AttachedToSlab').each do |slab|
        @attached_to_slab_idrefs << HPXML::get_idref(slab)
      end
      @attached_to_floor_idrefs = []
      XMLHelper.get_elements(foundation, 'AttachedToFloor').each do |floor|
        @attached_to_floor_idrefs << HPXML::get_idref(floor)
      end
      @attached_to_foundation_wall_idrefs = []
      XMLHelper.get_elements(foundation, 'AttachedToFoundationWall').each do |foundation_wall|
        @attached_to_foundation_wall_idrefs << HPXML::get_idref(foundation_wall)
      end
    end
  end

  class Roofs < BaseArrayElement
    def add(**kwargs)
      self << Roof.new(@parent_object, **kwargs)
    end

    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/Enclosure/Roofs/Roof').each do |roof|
        self << Roof.new(@parent_object, roof)
      end
    end
  end

  class Roof < BaseElement
    ATTRS = [:id, :interior_adjacent_to, :area, :azimuth, :orientation, :roof_type,
             :roof_color, :solar_absorptance, :emittance, :pitch, :radiant_barrier,
             :insulation_id, :insulation_assembly_r_value, :insulation_cavity_r_value,
             :insulation_continuous_r_value, :radiant_barrier_grade, :insulation_grade,
             :interior_finish_type, :interior_finish_thickness, :framing_factor,
             :framing_size, :framing_spacing]
    attr_accessor(*ATTRS)

    def skylights
      return @parent_object.skylights.select { |skylight| skylight.roof_idref == @id }
    end

    def net_area
      return if nil?
      return if @area.nil?

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

    def is_conditioned
      return HPXML::is_conditioned(self)
    end

    def delete
      @parent_object.roofs.delete(self)
      skylights.reverse_each do |skylight|
        skylight.delete
      end
      @parent_object.attics.each do |attic|
        attic.attached_to_roof_idrefs.delete(@id) unless attic.attached_to_roof_idrefs.nil?
      end
    end

    def check_for_errors
      errors = []
      begin; net_area; rescue StandardError => e; errors << e.message; end
      return errors
    end

    def to_doc(building)
      return if nil?

      roofs = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Enclosure', 'Roofs'])
      roof = XMLHelper.add_element(roofs, 'Roof')
      sys_id = XMLHelper.add_element(roof, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_element(roof, 'InteriorAdjacentTo', @interior_adjacent_to, :string) unless @interior_adjacent_to.nil?
      XMLHelper.add_element(roof, 'Area', @area, :float) unless @area.nil?
      XMLHelper.add_element(roof, 'Orientation', @orientation, :string, @orientation_isdefaulted) unless @orientation.nil?
      XMLHelper.add_element(roof, 'Azimuth', @azimuth, :integer, @azimuth_isdefaulted) unless @azimuth.nil?
      XMLHelper.add_element(roof, 'RoofType', @roof_type, :string, @roof_type_isdefaulted) unless @roof_type.nil?
      XMLHelper.add_element(roof, 'RoofColor', @roof_color, :string, @roof_color_isdefaulted) unless @roof_color.nil?
      XMLHelper.add_element(roof, 'SolarAbsorptance', @solar_absorptance, :float, @solar_absorptance_isdefaulted) unless @solar_absorptance.nil?
      XMLHelper.add_element(roof, 'Emittance', @emittance, :float, @emittance_isdefaulted) unless @emittance.nil?
      if (not @interior_finish_type.nil?) || (not @interior_finish_thickness.nil?)
        interior_finish = XMLHelper.add_element(roof, 'InteriorFinish')
        XMLHelper.add_element(interior_finish, 'Type', @interior_finish_type, :string, @interior_finish_type_isdefaulted) unless @interior_finish_type.nil?
        XMLHelper.add_element(interior_finish, 'Thickness', @interior_finish_thickness, :float, @interior_finish_thickness_isdefaulted) unless @interior_finish_thickness.nil?
      end
      if (not @framing_factor.nil?) || (not @framing_size.nil?) || (not @framing_spacing.nil?)
        rafters = XMLHelper.add_element(roof, 'Rafters')
        XMLHelper.add_element(rafters, 'Size', @framing_size, :string) unless @framing_size.nil?
        XMLHelper.add_element(rafters, 'Spacing', @framing_spacing, :float) unless @framing_spacing.nil?
        XMLHelper.add_element(rafters, 'FramingFactor', @framing_factor, :float) unless @framing_factor.nil?
      end
      XMLHelper.add_element(roof, 'Pitch', @pitch, :float) unless @pitch.nil?
      XMLHelper.add_element(roof, 'RadiantBarrier', @radiant_barrier, :boolean, @radiant_barrier_isdefaulted) unless @radiant_barrier.nil?
      XMLHelper.add_element(roof, 'RadiantBarrierGrade', @radiant_barrier_grade, :integer, @radiant_barrier_grade_isdefaulted) unless @radiant_barrier_grade.nil?
      insulation = XMLHelper.add_element(roof, 'Insulation')
      sys_id = XMLHelper.add_element(insulation, 'SystemIdentifier')
      if not @insulation_id.nil?
        XMLHelper.add_attribute(sys_id, 'id', @insulation_id)
      else
        XMLHelper.add_attribute(sys_id, 'id', @id + 'Insulation')
      end
      XMLHelper.add_element(insulation, 'InsulationGrade', @insulation_grade, :integer) unless @insulation_grade.nil?
      XMLHelper.add_element(insulation, 'AssemblyEffectiveRValue', @insulation_assembly_r_value, :float) unless @insulation_assembly_r_value.nil?
      if not @insulation_cavity_r_value.nil?
        layer = XMLHelper.add_element(insulation, 'Layer')
        XMLHelper.add_element(layer, 'InstallationType', 'cavity', :string)
        XMLHelper.add_element(layer, 'NominalRValue', @insulation_cavity_r_value, :float)
      end
      if not @insulation_continuous_r_value.nil?
        layer = XMLHelper.add_element(insulation, 'Layer')
        XMLHelper.add_element(layer, 'InstallationType', 'continuous', :string)
        XMLHelper.add_element(layer, 'NominalRValue', @insulation_continuous_r_value, :float)
      end
    end

    def from_doc(roof)
      return if roof.nil?

      @id = HPXML::get_id(roof)
      @interior_adjacent_to = XMLHelper.get_value(roof, 'InteriorAdjacentTo', :string)
      @area = XMLHelper.get_value(roof, 'Area', :float)
      @orientation = XMLHelper.get_value(roof, 'Orientation', :string)
      @azimuth = XMLHelper.get_value(roof, 'Azimuth', :integer)
      @roof_type = XMLHelper.get_value(roof, 'RoofType', :string)
      @roof_color = XMLHelper.get_value(roof, 'RoofColor', :string)
      @solar_absorptance = XMLHelper.get_value(roof, 'SolarAbsorptance', :float)
      @emittance = XMLHelper.get_value(roof, 'Emittance', :float)
      interior_finish = XMLHelper.get_element(roof, 'InteriorFinish')
      if not interior_finish.nil?
        @interior_finish_type = XMLHelper.get_value(interior_finish, 'Type', :string)
        @interior_finish_thickness = XMLHelper.get_value(interior_finish, 'Thickness', :float)
      end
      @framing_factor = XMLHelper.get_value(roof, 'Rafters/FramingFactor', :float)
      @framing_size = XMLHelper.get_value(roof, 'Rafters/Size', :string)
      @framing_spacing = XMLHelper.get_value(roof, 'Rafters/Spacing', :float)
      @pitch = XMLHelper.get_value(roof, 'Pitch', :float)
      @radiant_barrier = XMLHelper.get_value(roof, 'RadiantBarrier', :boolean)
      @radiant_barrier_grade = XMLHelper.get_value(roof, 'RadiantBarrierGrade', :integer)
      insulation = XMLHelper.get_element(roof, 'Insulation')
      if not insulation.nil?
        @insulation_id = HPXML::get_id(insulation)
        @insulation_grade = XMLHelper.get_value(insulation, 'InsulationGrade', :integer)
        @insulation_assembly_r_value = XMLHelper.get_value(insulation, 'AssemblyEffectiveRValue', :float)
        @insulation_cavity_r_value = XMLHelper.get_value(insulation, "Layer[InstallationType='cavity']/NominalRValue", :float)
        @insulation_continuous_r_value = XMLHelper.get_value(insulation, "Layer[InstallationType='continuous']/NominalRValue", :float)
      end
    end
  end

  class RimJoists < BaseArrayElement
    def add(**kwargs)
      self << RimJoist.new(@parent_object, **kwargs)
    end

    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/Enclosure/RimJoists/RimJoist').each do |rim_joist|
        self << RimJoist.new(@parent_object, rim_joist)
      end
    end
  end

  class RimJoist < BaseElement
    ATTRS = [:id, :exterior_adjacent_to, :interior_adjacent_to, :area, :orientation, :azimuth, :siding,
             :color, :solar_absorptance, :emittance, :insulation_id, :insulation_assembly_r_value,
             :insulation_cavity_r_value, :insulation_continuous_r_value, :framing_size]
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

    def is_adiabatic
      return HPXML::is_adiabatic(self)
    end

    def is_thermal_boundary
      return HPXML::is_thermal_boundary(self)
    end

    def is_exterior_thermal_boundary
      return (is_exterior && is_thermal_boundary)
    end

    def is_conditioned
      return HPXML::is_conditioned(self)
    end

    def net_area
      return area
    end

    def delete
      @parent_object.rim_joists.delete(self)
      @parent_object.foundations.each do |foundation|
        foundation.attached_to_rim_joist_idrefs.delete(@id) unless foundation.attached_to_rim_joist_idrefs.nil?
      end
    end

    def check_for_errors
      errors = []
      return errors
    end

    def to_doc(building)
      return if nil?

      rim_joists = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Enclosure', 'RimJoists'])
      rim_joist = XMLHelper.add_element(rim_joists, 'RimJoist')
      sys_id = XMLHelper.add_element(rim_joist, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_element(rim_joist, 'ExteriorAdjacentTo', @exterior_adjacent_to, :string) unless @exterior_adjacent_to.nil?
      XMLHelper.add_element(rim_joist, 'InteriorAdjacentTo', @interior_adjacent_to, :string) unless @interior_adjacent_to.nil?
      XMLHelper.add_element(rim_joist, 'Area', @area, :float) unless @area.nil?
      XMLHelper.add_element(rim_joist, 'Orientation', @orientation, :string, @orientation_isdefaulted) unless @orientation.nil?
      XMLHelper.add_element(rim_joist, 'Azimuth', @azimuth, :integer, @azimuth_isdefaulted) unless @azimuth.nil?
      XMLHelper.add_element(rim_joist, 'Siding', @siding, :string, @siding_isdefaulted) unless @siding.nil?
      XMLHelper.add_element(rim_joist, 'Color', @color, :string, @color_isdefaulted) unless @color.nil?
      XMLHelper.add_element(rim_joist, 'SolarAbsorptance', @solar_absorptance, :float, @solar_absorptance_isdefaulted) unless @solar_absorptance.nil?
      XMLHelper.add_element(rim_joist, 'Emittance', @emittance, :float, @emittance_isdefaulted) unless @emittance.nil?
      insulation = XMLHelper.add_element(rim_joist, 'Insulation')
      sys_id = XMLHelper.add_element(insulation, 'SystemIdentifier')
      if not @insulation_id.nil?
        XMLHelper.add_attribute(sys_id, 'id', @insulation_id)
      else
        XMLHelper.add_attribute(sys_id, 'id', @id + 'Insulation')
      end
      XMLHelper.add_element(insulation, 'AssemblyEffectiveRValue', @insulation_assembly_r_value, :float) unless @insulation_assembly_r_value.nil?
      if not @insulation_cavity_r_value.nil?
        layer = XMLHelper.add_element(insulation, 'Layer')
        XMLHelper.add_element(layer, 'InstallationType', 'cavity', :string)
        XMLHelper.add_element(layer, 'NominalRValue', @insulation_cavity_r_value, :float)
      end
      if not @insulation_continuous_r_value.nil?
        layer = XMLHelper.add_element(insulation, 'Layer')
        XMLHelper.add_element(layer, 'InstallationType', 'continuous', :string)
        XMLHelper.add_element(layer, 'NominalRValue', @insulation_continuous_r_value, :float)
      end
      if not @framing_size.nil?
        floor_joists = XMLHelper.add_element(rim_joist, 'FloorJoists')
        XMLHelper.add_element(floor_joists, 'Size', @framing_size, :string) unless @framing_size.nil?
      end
    end

    def from_doc(rim_joist)
      return if rim_joist.nil?

      @id = HPXML::get_id(rim_joist)
      @exterior_adjacent_to = XMLHelper.get_value(rim_joist, 'ExteriorAdjacentTo', :string)
      @interior_adjacent_to = XMLHelper.get_value(rim_joist, 'InteriorAdjacentTo', :string)
      @area = XMLHelper.get_value(rim_joist, 'Area', :float)
      @orientation = XMLHelper.get_value(rim_joist, 'Orientation', :string)
      @azimuth = XMLHelper.get_value(rim_joist, 'Azimuth', :integer)
      @siding = XMLHelper.get_value(rim_joist, 'Siding', :string)
      @color = XMLHelper.get_value(rim_joist, 'Color', :string)
      @solar_absorptance = XMLHelper.get_value(rim_joist, 'SolarAbsorptance', :float)
      @emittance = XMLHelper.get_value(rim_joist, 'Emittance', :float)
      insulation = XMLHelper.get_element(rim_joist, 'Insulation')
      if not insulation.nil?
        @insulation_id = HPXML::get_id(insulation)
        @insulation_assembly_r_value = XMLHelper.get_value(insulation, 'AssemblyEffectiveRValue', :float)
        @insulation_cavity_r_value = XMLHelper.get_value(insulation, "Layer[InstallationType='cavity']/NominalRValue", :float)
        @insulation_continuous_r_value = XMLHelper.get_value(insulation, "Layer[InstallationType='continuous']/NominalRValue", :float)
      end
      @framing_size = XMLHelper.get_value(rim_joist, 'FloorJoists/Size', :string)
    end
  end

  class Walls < BaseArrayElement
    def add(**kwargs)
      self << Wall.new(@parent_object, **kwargs)
    end

    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/Enclosure/Walls/Wall').each do |wall|
        self << Wall.new(@parent_object, wall)
      end
    end
  end

  class Wall < BaseElement
    ATTRS = [:id, :exterior_adjacent_to, :interior_adjacent_to, :wall_type, :optimum_value_engineering,
             :area, :orientation, :azimuth, :siding, :color, :solar_absorptance, :emittance, :radiant_barrier, :radiant_barrier_grade, :insulation_id,
             :insulation_assembly_r_value, :insulation_cavity_r_value, :insulation_continuous_r_value,
             :interior_finish_type, :interior_finish_thickness, :attic_wall_type, :framing_factor,
             :framing_size, :framing_spacing, :insulation_grade]
    attr_accessor(*ATTRS)

    def windows
      return @parent_object.windows.select { |window| window.wall_idref == @id }
    end

    def doors
      return @parent_object.doors.select { |door| door.wall_idref == @id }
    end

    def net_area
      return if nil?
      return if @area.nil?

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

    def is_adiabatic
      return HPXML::is_adiabatic(self)
    end

    def is_thermal_boundary
      return HPXML::is_thermal_boundary(self)
    end

    def is_exterior_thermal_boundary
      return (is_exterior && is_thermal_boundary)
    end

    def is_conditioned
      return HPXML::is_conditioned(self)
    end

    def delete
      @parent_object.walls.delete(self)
      windows.reverse_each do |window|
        window.delete
      end
      doors.reverse_each do |door|
        door.delete
      end
      @parent_object.attics.each do |attic|
        attic.attached_to_wall_idrefs.delete(@id) unless attic.attached_to_wall_idrefs.nil?
      end
      @parent_object.foundations.each do |foundation|
        foundation.attached_to_wall_idrefs.delete(@id) unless foundation.attached_to_wall_idrefs.nil?
      end
    end

    def check_for_errors
      errors = []
      begin; net_area; rescue StandardError => e; errors << e.message; end
      return errors
    end

    def to_doc(building)
      return if nil?

      walls = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Enclosure', 'Walls'])
      wall = XMLHelper.add_element(walls, 'Wall')
      sys_id = XMLHelper.add_element(wall, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_element(wall, 'ExteriorAdjacentTo', @exterior_adjacent_to, :string) unless @exterior_adjacent_to.nil?
      XMLHelper.add_element(wall, 'InteriorAdjacentTo', @interior_adjacent_to, :string) unless @interior_adjacent_to.nil?
      XMLHelper.add_element(wall, 'AtticWallType', @attic_wall_type, :string) unless @attic_wall_type.nil?
      if not @wall_type.nil?
        wall_type_el = XMLHelper.add_element(wall, 'WallType')
        wall_type = XMLHelper.add_element(wall_type_el, @wall_type)
        if @wall_type == HPXML::WallTypeWoodStud
          XMLHelper.add_element(wall_type, 'OptimumValueEngineering', @optimum_value_engineering, :boolean) unless @optimum_value_engineering.nil?
        end
      end
      XMLHelper.add_element(wall, 'Area', @area, :float) unless @area.nil?
      XMLHelper.add_element(wall, 'Orientation', @orientation, :string, @orientation_isdefaulted) unless @orientation.nil?
      XMLHelper.add_element(wall, 'Azimuth', @azimuth, :integer, @azimuth_isdefaulted) unless @azimuth.nil?
      if (not @framing_factor.nil?) || (not @framing_size.nil?) || (not @framing_spacing.nil?)
        studs = XMLHelper.add_element(wall, 'Studs')
        XMLHelper.add_element(studs, 'Size', @framing_size, :string) unless @framing_size.nil?
        XMLHelper.add_element(studs, 'Spacing', @framing_spacing, :float) unless @framing_spacing.nil?
        XMLHelper.add_element(studs, 'FramingFactor', @framing_factor, :float) unless @framing_factor.nil?
      end
      XMLHelper.add_element(wall, 'Siding', @siding, :string, @siding_isdefaulted) unless @siding.nil?
      XMLHelper.add_element(wall, 'Color', @color, :string, @color_isdefaulted) unless @color.nil?
      XMLHelper.add_element(wall, 'SolarAbsorptance', @solar_absorptance, :float, @solar_absorptance_isdefaulted) unless @solar_absorptance.nil?
      XMLHelper.add_element(wall, 'Emittance', @emittance, :float, @emittance_isdefaulted) unless @emittance.nil?
      if (not @interior_finish_type.nil?) || (not @interior_finish_thickness.nil?)
        interior_finish = XMLHelper.add_element(wall, 'InteriorFinish')
        XMLHelper.add_element(interior_finish, 'Type', @interior_finish_type, :string, @interior_finish_type_isdefaulted) unless @interior_finish_type.nil?
        XMLHelper.add_element(interior_finish, 'Thickness', @interior_finish_thickness, :float, @interior_finish_thickness_isdefaulted) unless @interior_finish_thickness.nil?
      end
      XMLHelper.add_element(wall, 'RadiantBarrier', @radiant_barrier, :boolean, @radiant_barrier_isdefaulted) unless @radiant_barrier.nil?
      XMLHelper.add_element(wall, 'RadiantBarrierGrade', @radiant_barrier_grade, :integer, @radiant_barrier_grade_isdefaulted) unless @radiant_barrier_grade.nil?
      insulation = XMLHelper.add_element(wall, 'Insulation')
      sys_id = XMLHelper.add_element(insulation, 'SystemIdentifier')
      if not @insulation_id.nil?
        XMLHelper.add_attribute(sys_id, 'id', @insulation_id)
      else
        XMLHelper.add_attribute(sys_id, 'id', @id + 'Insulation')
      end
      XMLHelper.add_element(insulation, 'InsulationGrade', @insulation_grade, :integer) unless @insulation_grade.nil?
      XMLHelper.add_element(insulation, 'AssemblyEffectiveRValue', @insulation_assembly_r_value, :float) unless @insulation_assembly_r_value.nil?
      if not @insulation_cavity_r_value.nil?
        layer = XMLHelper.add_element(insulation, 'Layer')
        XMLHelper.add_element(layer, 'InstallationType', 'cavity', :string)
        XMLHelper.add_element(layer, 'NominalRValue', @insulation_cavity_r_value, :float)
      end
      if not @insulation_continuous_r_value.nil?
        layer = XMLHelper.add_element(insulation, 'Layer')
        XMLHelper.add_element(layer, 'InstallationType', 'continuous', :string)
        XMLHelper.add_element(layer, 'NominalRValue', @insulation_continuous_r_value, :float)
      end
    end

    def from_doc(wall)
      return if wall.nil?

      @id = HPXML::get_id(wall)
      @exterior_adjacent_to = XMLHelper.get_value(wall, 'ExteriorAdjacentTo', :string)
      @interior_adjacent_to = XMLHelper.get_value(wall, 'InteriorAdjacentTo', :string)
      @attic_wall_type = XMLHelper.get_value(wall, 'AtticWallType', :string)
      @wall_type = XMLHelper.get_child_name(wall, 'WallType')
      if @wall_type == HPXML::WallTypeWoodStud
        @optimum_value_engineering = XMLHelper.get_value(wall, 'WallType/WoodStud/OptimumValueEngineering', :boolean)
      end
      @area = XMLHelper.get_value(wall, 'Area', :float)
      @orientation = XMLHelper.get_value(wall, 'Orientation', :string)
      @azimuth = XMLHelper.get_value(wall, 'Azimuth', :integer)
      @framing_size = XMLHelper.get_value(wall, 'Studs/Size', :string)
      @framing_spacing = XMLHelper.get_value(wall, 'Studs/Spacing', :float)
      @framing_factor = XMLHelper.get_value(wall, 'Studs/FramingFactor', :float)
      @siding = XMLHelper.get_value(wall, 'Siding', :string)
      @color = XMLHelper.get_value(wall, 'Color', :string)
      @solar_absorptance = XMLHelper.get_value(wall, 'SolarAbsorptance', :float)
      @emittance = XMLHelper.get_value(wall, 'Emittance', :float)
      interior_finish = XMLHelper.get_element(wall, 'InteriorFinish')
      if not interior_finish.nil?
        @interior_finish_type = XMLHelper.get_value(interior_finish, 'Type', :string)
        @interior_finish_thickness = XMLHelper.get_value(interior_finish, 'Thickness', :float)
      end
      @radiant_barrier = XMLHelper.get_value(wall, 'RadiantBarrier', :boolean)
      @radiant_barrier_grade = XMLHelper.get_value(wall, 'RadiantBarrierGrade', :integer)
      insulation = XMLHelper.get_element(wall, 'Insulation')
      if not insulation.nil?
        @insulation_id = HPXML::get_id(insulation)
        @insulation_grade = XMLHelper.get_value(insulation, 'InsulationGrade', :integer)
        @insulation_assembly_r_value = XMLHelper.get_value(insulation, 'AssemblyEffectiveRValue', :float)
        @insulation_cavity_r_value = XMLHelper.get_value(insulation, "Layer[InstallationType='cavity']/NominalRValue", :float)
        @insulation_continuous_r_value = XMLHelper.get_value(insulation, "Layer[InstallationType='continuous']/NominalRValue", :float)
      end
    end
  end

  class FoundationWalls < BaseArrayElement
    def add(**kwargs)
      self << FoundationWall.new(@parent_object, **kwargs)
    end

    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/Enclosure/FoundationWalls/FoundationWall').each do |foundation_wall|
        self << FoundationWall.new(@parent_object, foundation_wall)
      end
    end
  end

  class FoundationWall < BaseElement
    ATTRS = [:id, :exterior_adjacent_to, :interior_adjacent_to, :length, :height, :area, :orientation,
             :type, :azimuth, :thickness, :depth_below_grade, :insulation_id, :insulation_interior_r_value,
             :insulation_interior_distance_to_top, :insulation_interior_distance_to_bottom,
             :insulation_exterior_r_value, :insulation_exterior_distance_to_top,
             :insulation_exterior_distance_to_bottom, :insulation_assembly_r_value,
             :insulation_continuous_r_value, :interior_finish_type, :interior_finish_thickness]
    attr_accessor(*ATTRS)

    def windows
      return @parent_object.windows.select { |window| window.wall_idref == @id }
    end

    def doors
      return @parent_object.doors.select { |door| door.wall_idref == @id }
    end

    def net_area
      return if nil?
      return if @area.nil?

      val = @area
      (@parent_object.windows + @parent_object.doors).each do |subsurface|
        next unless subsurface.wall_idref == @id

        val -= subsurface.area
      end
      fail "Calculated a negative net surface area for surface '#{@id}'." if val < 0

      return val
    end

    def connected_slabs
      return @parent_object.slabs.select { |s| s.connected_foundation_walls.include? self }
    end

    def exposed_fraction
      # Calculate total slab exposed perimeter
      slab_exposed_length = connected_slabs.select { |s| s.interior_adjacent_to == interior_adjacent_to }.map { |s| s.exposed_perimeter }.sum

      # Calculate total length of exterior foundation walls
      ext_adjacent_fnd_walls = connected_slabs.map { |s| s.connected_foundation_walls.select { |fw| fw.is_exterior } }.flatten.uniq
      wall_total_length = ext_adjacent_fnd_walls.map { |fw| fw.area / fw.height }.sum

      # Calculate exposed fraction
      if slab_exposed_length < wall_total_length
        return slab_exposed_length / wall_total_length
      end

      return 1.0
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

    def is_adiabatic
      return HPXML::is_adiabatic(self)
    end

    def is_thermal_boundary
      return HPXML::is_thermal_boundary(self)
    end

    def is_exterior_thermal_boundary
      return (is_exterior && is_thermal_boundary)
    end

    def is_conditioned
      return HPXML::is_conditioned(self)
    end

    def delete
      @parent_object.foundation_walls.delete(self)
      windows.reverse_each do |window|
        window.delete
      end
      doors.reverse_each do |door|
        door.delete
      end
      @parent_object.foundations.each do |foundation|
        foundation.attached_to_foundation_wall_idrefs.delete(@id) unless foundation.attached_to_foundation_wall_idrefs.nil?
      end
    end

    def check_for_errors
      errors = []
      begin; net_area; rescue StandardError => e; errors << e.message; end
      return errors
    end

    def to_doc(building)
      return if nil?

      foundation_walls = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Enclosure', 'FoundationWalls'])
      foundation_wall = XMLHelper.add_element(foundation_walls, 'FoundationWall')
      sys_id = XMLHelper.add_element(foundation_wall, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_element(foundation_wall, 'ExteriorAdjacentTo', @exterior_adjacent_to, :string) unless @exterior_adjacent_to.nil?
      XMLHelper.add_element(foundation_wall, 'InteriorAdjacentTo', @interior_adjacent_to, :string) unless @interior_adjacent_to.nil?
      XMLHelper.add_element(foundation_wall, 'Type', @type, :string, @type_isdefaulted) unless @type.nil?
      XMLHelper.add_element(foundation_wall, 'Length', @length, :float) unless @length.nil?
      XMLHelper.add_element(foundation_wall, 'Height', @height, :float) unless @height.nil?
      XMLHelper.add_element(foundation_wall, 'Area', @area, :float, @area_isdefaulted) unless @area.nil?
      XMLHelper.add_element(foundation_wall, 'Orientation', @orientation, :string, @orientation_isdefaulted) unless @orientation.nil?
      XMLHelper.add_element(foundation_wall, 'Azimuth', @azimuth, :integer, @azimuth_isdefaulted) unless @azimuth.nil?
      XMLHelper.add_element(foundation_wall, 'Thickness', @thickness, :float, @thickness_isdefaulted) unless @thickness.nil?
      XMLHelper.add_element(foundation_wall, 'DepthBelowGrade', @depth_below_grade, :float) unless @depth_below_grade.nil?
      if (not @interior_finish_type.nil?) || (not @interior_finish_thickness.nil?)
        interior_finish = XMLHelper.add_element(foundation_wall, 'InteriorFinish')
        XMLHelper.add_element(interior_finish, 'Type', @interior_finish_type, :string, @interior_finish_type_isdefaulted) unless @interior_finish_type.nil?
        XMLHelper.add_element(interior_finish, 'Thickness', @interior_finish_thickness, :float, @interior_finish_thickness_isdefaulted) unless @interior_finish_thickness.nil?
      end
      insulation = XMLHelper.add_element(foundation_wall, 'Insulation')
      sys_id = XMLHelper.add_element(insulation, 'SystemIdentifier')
      if not @insulation_id.nil?
        XMLHelper.add_attribute(sys_id, 'id', @insulation_id)
      else
        XMLHelper.add_attribute(sys_id, 'id', @id + 'Insulation')
      end
      XMLHelper.add_element(insulation, 'AssemblyEffectiveRValue', @insulation_assembly_r_value, :float) unless @insulation_assembly_r_value.nil?
      if not @insulation_exterior_r_value.nil?
        layer = XMLHelper.add_element(insulation, 'Layer')
        XMLHelper.add_element(layer, 'InstallationType', 'continuous - exterior', :string)
        XMLHelper.add_element(layer, 'NominalRValue', @insulation_exterior_r_value, :float)
        XMLHelper.add_element(layer, 'DistanceToTopOfInsulation', @insulation_exterior_distance_to_top, :float, @insulation_exterior_distance_to_top_isdefaulted) unless @insulation_exterior_distance_to_top.nil?
        XMLHelper.add_element(layer, 'DistanceToBottomOfInsulation', @insulation_exterior_distance_to_bottom, :float, @insulation_exterior_distance_to_bottom_isdefaulted) unless @insulation_exterior_distance_to_bottom.nil?
      end
      if not @insulation_interior_r_value.nil?
        layer = XMLHelper.add_element(insulation, 'Layer')
        XMLHelper.add_element(layer, 'InstallationType', 'continuous - interior', :string)
        XMLHelper.add_element(layer, 'NominalRValue', @insulation_interior_r_value, :float)
        XMLHelper.add_element(layer, 'DistanceToTopOfInsulation', @insulation_interior_distance_to_top, :float, @insulation_interior_distance_to_top_isdefaulted) unless @insulation_interior_distance_to_top.nil?
        XMLHelper.add_element(layer, 'DistanceToBottomOfInsulation', @insulation_interior_distance_to_bottom, :float, @insulation_interior_distance_to_bottom_isdefaulted) unless @insulation_interior_distance_to_bottom.nil?
      end
    end

    def from_doc(foundation_wall)
      return if foundation_wall.nil?

      @id = HPXML::get_id(foundation_wall)
      @exterior_adjacent_to = XMLHelper.get_value(foundation_wall, 'ExteriorAdjacentTo', :string)
      @interior_adjacent_to = XMLHelper.get_value(foundation_wall, 'InteriorAdjacentTo', :string)
      @type = XMLHelper.get_value(foundation_wall, 'Type', :string)
      @length = XMLHelper.get_value(foundation_wall, 'Length', :float)
      @height = XMLHelper.get_value(foundation_wall, 'Height', :float)
      @area = XMLHelper.get_value(foundation_wall, 'Area', :float)
      @orientation = XMLHelper.get_value(foundation_wall, 'Orientation', :string)
      @azimuth = XMLHelper.get_value(foundation_wall, 'Azimuth', :integer)
      @thickness = XMLHelper.get_value(foundation_wall, 'Thickness', :float)
      @depth_below_grade = XMLHelper.get_value(foundation_wall, 'DepthBelowGrade', :float)
      interior_finish = XMLHelper.get_element(foundation_wall, 'InteriorFinish')
      if not interior_finish.nil?
        @interior_finish_type = XMLHelper.get_value(interior_finish, 'Type', :string)
        @interior_finish_thickness = XMLHelper.get_value(interior_finish, 'Thickness', :float)
      end
      insulation = XMLHelper.get_element(foundation_wall, 'Insulation')
      if not insulation.nil?
        @insulation_id = HPXML::get_id(insulation)
        @insulation_assembly_r_value = XMLHelper.get_value(insulation, 'AssemblyEffectiveRValue', :float)
        @insulation_continuous_r_value = XMLHelper.get_value(insulation, "Layer[InstallationType='continuous']/NominalRValue", :float)
        @insulation_interior_r_value = XMLHelper.get_value(insulation, "Layer[InstallationType='continuous - interior']/NominalRValue", :float)
        @insulation_interior_distance_to_top = XMLHelper.get_value(insulation, "Layer[InstallationType='continuous - interior']/DistanceToTopOfInsulation", :float)
        @insulation_interior_distance_to_bottom = XMLHelper.get_value(insulation, "Layer[InstallationType='continuous - interior']/DistanceToBottomOfInsulation", :float)
        @insulation_exterior_r_value = XMLHelper.get_value(insulation, "Layer[InstallationType='continuous - exterior']/NominalRValue", :float)
        @insulation_exterior_distance_to_top = XMLHelper.get_value(insulation, "Layer[InstallationType='continuous - exterior']/DistanceToTopOfInsulation", :float)
        @insulation_exterior_distance_to_bottom = XMLHelper.get_value(insulation, "Layer[InstallationType='continuous - exterior']/DistanceToBottomOfInsulation", :float)
      end
    end
  end

  class Floors < BaseArrayElement
    def add(**kwargs)
      self << Floor.new(@parent_object, **kwargs)
    end

    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/Enclosure/Floors/Floor').each do |floor|
        self << Floor.new(@parent_object, floor)
      end
    end
  end

  class Floor < BaseElement
    ATTRS = [:id, :exterior_adjacent_to, :interior_adjacent_to, :floor_type, :area, :insulation_id,
             :insulation_assembly_r_value, :insulation_cavity_r_value, :insulation_continuous_r_value,
             :floor_or_ceiling, :interior_finish_type, :interior_finish_thickness, :insulation_grade,
             :framing_factor, :framing_size, :framing_spacing, :radiant_barrier, :radiant_barrier_grade]
    attr_accessor(*ATTRS)

    def is_ceiling
      # From the perspective of the conditioned space
      if @floor_or_ceiling.nil?
        ceiling_locations = [LocationAtticUnconditioned,
                             LocationAtticVented,
                             LocationAtticUnvented]
        if (ceiling_locations.include? @interior_adjacent_to) || (ceiling_locations.include? @exterior_adjacent_to)
          return true
        else # If we don't explicitly know that it's a ceiling, assume a floor
          return false
        end
      else
        return @floor_or_ceiling == FloorOrCeilingCeiling
      end
    end

    def is_floor
      return !is_ceiling
    end

    def is_exterior
      return [LocationOutside, LocationManufacturedHomeUnderBelly].include?(@exterior_adjacent_to)
    end

    def is_interior
      return !is_exterior
    end

    def is_adiabatic
      return HPXML::is_adiabatic(self)
    end

    def is_thermal_boundary
      return HPXML::is_thermal_boundary(self)
    end

    def is_exterior_thermal_boundary
      return (is_exterior && is_thermal_boundary)
    end

    def is_conditioned
      return HPXML::is_conditioned(self)
    end

    def delete
      @parent_object.floors.delete(self)
      @parent_object.attics.each do |attic|
        attic.attached_to_floor_idrefs.delete(@id) unless attic.attached_to_floor_idrefs.nil?
      end
      @parent_object.foundations.each do |foundation|
        foundation.attached_to_floor_idrefs.delete(@id) unless foundation.attached_to_floor_idrefs.nil?
      end
      @parent_object.attics.each do |attic|
        attic.attached_to_floor_idrefs.delete(@id) unless attic.attached_to_floor_idrefs.nil?
      end
    end

    def check_for_errors
      errors = []
      return errors
    end

    def to_doc(building)
      return if nil?

      floors = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Enclosure', 'Floors'])
      floor = XMLHelper.add_element(floors, 'Floor')
      sys_id = XMLHelper.add_element(floor, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_element(floor, 'ExteriorAdjacentTo', @exterior_adjacent_to, :string) unless @exterior_adjacent_to.nil?
      XMLHelper.add_element(floor, 'InteriorAdjacentTo', @interior_adjacent_to, :string) unless @interior_adjacent_to.nil?
      XMLHelper.add_element(floor, 'FloorOrCeiling', @floor_or_ceiling, :string, @floor_or_ceiling_isdefaulted) unless @floor_or_ceiling.nil?
      if not @floor_type.nil?
        floor_type_el = XMLHelper.add_element(floor, 'FloorType')
        XMLHelper.add_element(floor_type_el, @floor_type)
      end
      if (not @framing_factor.nil?) || (not @framing_size.nil?) || (not @framing_spacing.nil?)
        joists = XMLHelper.add_element(floor, 'FloorJoists')
        XMLHelper.add_element(joists, 'Size', @framing_size, :string) unless @framing_size.nil?
        XMLHelper.add_element(joists, 'Spacing', @framing_spacing, :float) unless @framing_spacing.nil?
        XMLHelper.add_element(joists, 'FramingFactor', @framing_factor, :float) unless @framing_factor.nil?
      end
      XMLHelper.add_element(floor, 'Area', @area, :float) unless @area.nil?
      if (not @interior_finish_type.nil?) || (not @interior_finish_thickness.nil?)
        interior_finish = XMLHelper.add_element(floor, 'InteriorFinish')
        XMLHelper.add_element(interior_finish, 'Type', @interior_finish_type, :string, @interior_finish_type_isdefaulted) unless @interior_finish_type.nil?
        XMLHelper.add_element(interior_finish, 'Thickness', @interior_finish_thickness, :float, @interior_finish_thickness_isdefaulted) unless @interior_finish_thickness.nil?
      end
      XMLHelper.add_element(floor, 'RadiantBarrier', @radiant_barrier, :boolean, @radiant_barrier_isdefaulted) unless @radiant_barrier.nil?
      XMLHelper.add_element(floor, 'RadiantBarrierGrade', @radiant_barrier_grade, :integer, @radiant_barrier_grade_isdefaulted) unless @radiant_barrier_grade.nil?
      insulation = XMLHelper.add_element(floor, 'Insulation')
      sys_id = XMLHelper.add_element(insulation, 'SystemIdentifier')
      if not @insulation_id.nil?
        XMLHelper.add_attribute(sys_id, 'id', @insulation_id)
      else
        XMLHelper.add_attribute(sys_id, 'id', @id + 'Insulation')
      end
      XMLHelper.add_element(insulation, 'InsulationGrade', @insulation_grade, :integer) unless @insulation_grade.nil?
      XMLHelper.add_element(insulation, 'AssemblyEffectiveRValue', @insulation_assembly_r_value, :float) unless @insulation_assembly_r_value.nil?
      if not @insulation_cavity_r_value.nil?
        layer = XMLHelper.add_element(insulation, 'Layer')
        XMLHelper.add_element(layer, 'InstallationType', 'cavity', :string)
        XMLHelper.add_element(layer, 'NominalRValue', @insulation_cavity_r_value, :float)
      end
      if not @insulation_continuous_r_value.nil?
        layer = XMLHelper.add_element(insulation, 'Layer')
        XMLHelper.add_element(layer, 'InstallationType', 'continuous', :string)
        XMLHelper.add_element(layer, 'NominalRValue', @insulation_continuous_r_value, :float)
      end
    end

    def from_doc(floor)
      return if floor.nil?

      @id = HPXML::get_id(floor)
      @exterior_adjacent_to = XMLHelper.get_value(floor, 'ExteriorAdjacentTo', :string)
      @interior_adjacent_to = XMLHelper.get_value(floor, 'InteriorAdjacentTo', :string)
      @floor_or_ceiling = XMLHelper.get_value(floor, 'FloorOrCeiling', :string)
      @floor_type = XMLHelper.get_child_name(floor, 'FloorType')
      @framing_size = XMLHelper.get_value(floor, 'FloorJoists/Size', :string)
      @framing_spacing = XMLHelper.get_value(floor, 'FloorJoists/Spacing', :float)
      @framing_factor = XMLHelper.get_value(floor, 'FloorJoists/FramingFactor', :float)
      @area = XMLHelper.get_value(floor, 'Area', :float)
      interior_finish = XMLHelper.get_element(floor, 'InteriorFinish')
      if not interior_finish.nil?
        @interior_finish_type = XMLHelper.get_value(interior_finish, 'Type', :string)
        @interior_finish_thickness = XMLHelper.get_value(interior_finish, 'Thickness', :float)
      end
      @radiant_barrier = XMLHelper.get_value(floor, 'RadiantBarrier', :boolean)
      @radiant_barrier_grade = XMLHelper.get_value(floor, 'RadiantBarrierGrade', :integer)
      insulation = XMLHelper.get_element(floor, 'Insulation')
      if not insulation.nil?
        @insulation_id = HPXML::get_id(insulation)
        @insulation_grade = XMLHelper.get_value(insulation, 'InsulationGrade', :float)
        @insulation_assembly_r_value = XMLHelper.get_value(insulation, 'AssemblyEffectiveRValue', :float)
        @insulation_cavity_r_value = XMLHelper.get_value(insulation, "Layer[InstallationType='cavity']/NominalRValue", :float)
        @insulation_continuous_r_value = XMLHelper.get_value(insulation, "Layer[InstallationType='continuous']/NominalRValue", :float)
      end
    end
  end

  class Slabs < BaseArrayElement
    def add(**kwargs)
      self << Slab.new(@parent_object, **kwargs)
    end

    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/Enclosure/Slabs/Slab').each do |slab|
        self << Slab.new(@parent_object, slab)
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
      return HPXML::is_thermal_boundary(self)
    end

    def is_exterior_thermal_boundary
      return (is_exterior && is_thermal_boundary)
    end

    def is_conditioned
      return HPXML::is_conditioned(self)
    end

    def connected_foundation_walls
      return @parent_object.foundation_walls.select { |fw| interior_adjacent_to == fw.interior_adjacent_to || interior_adjacent_to == fw.exterior_adjacent_to }
    end

    def delete
      @parent_object.slabs.delete(self)
      @parent_object.foundations.each do |foundation|
        foundation.attached_to_slab_idrefs.delete(@id) unless foundation.attached_to_slab_idrefs.nil?
      end
    end

    def check_for_errors
      errors = []
      return errors
    end

    def to_doc(building)
      return if nil?

      slabs = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Enclosure', 'Slabs'])
      slab = XMLHelper.add_element(slabs, 'Slab')
      sys_id = XMLHelper.add_element(slab, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_element(slab, 'InteriorAdjacentTo', @interior_adjacent_to, :string) unless @interior_adjacent_to.nil?
      XMLHelper.add_element(slab, 'Area', @area, :float) unless @area.nil?
      XMLHelper.add_element(slab, 'Thickness', @thickness, :float, @thickness_isdefaulted) unless @thickness.nil?
      XMLHelper.add_element(slab, 'ExposedPerimeter', @exposed_perimeter, :float) unless @exposed_perimeter.nil?
      XMLHelper.add_element(slab, 'DepthBelowGrade', @depth_below_grade, :float, @depth_below_grade_isdefaulted) unless @depth_below_grade.nil?
      insulation = XMLHelper.add_element(slab, 'PerimeterInsulation')
      sys_id = XMLHelper.add_element(insulation, 'SystemIdentifier')
      if not @perimeter_insulation_id.nil?
        XMLHelper.add_attribute(sys_id, 'id', @perimeter_insulation_id)
      else
        XMLHelper.add_attribute(sys_id, 'id', @id + 'PerimeterInsulation')
      end
      layer = XMLHelper.add_element(insulation, 'Layer')
      XMLHelper.add_element(layer, 'NominalRValue', @perimeter_insulation_r_value, :float) unless @perimeter_insulation_r_value.nil?
      XMLHelper.add_element(layer, 'InsulationDepth', @perimeter_insulation_depth, :float) unless @perimeter_insulation_depth.nil?
      insulation = XMLHelper.add_element(slab, 'UnderSlabInsulation')
      sys_id = XMLHelper.add_element(insulation, 'SystemIdentifier')
      if not @under_slab_insulation_id.nil?
        XMLHelper.add_attribute(sys_id, 'id', @under_slab_insulation_id)
      else
        XMLHelper.add_attribute(sys_id, 'id', @id + 'UnderSlabInsulation')
      end
      layer = XMLHelper.add_element(insulation, 'Layer')
      XMLHelper.add_element(layer, 'NominalRValue', @under_slab_insulation_r_value, :float) unless @under_slab_insulation_r_value.nil?
      XMLHelper.add_element(layer, 'InsulationWidth', @under_slab_insulation_width, :float) unless @under_slab_insulation_width.nil?
      XMLHelper.add_element(layer, 'InsulationSpansEntireSlab', @under_slab_insulation_spans_entire_slab, :boolean) unless @under_slab_insulation_spans_entire_slab.nil?
      XMLHelper.add_extension(slab, 'CarpetFraction', @carpet_fraction, :float, @carpet_fraction_isdefaulted) unless @carpet_fraction.nil?
      XMLHelper.add_extension(slab, 'CarpetRValue', @carpet_r_value, :float, @carpet_r_value_isdefaulted) unless @carpet_r_value.nil?
    end

    def from_doc(slab)
      return if slab.nil?

      @id = HPXML::get_id(slab)
      @interior_adjacent_to = XMLHelper.get_value(slab, 'InteriorAdjacentTo', :string)
      @area = XMLHelper.get_value(slab, 'Area', :float)
      @thickness = XMLHelper.get_value(slab, 'Thickness', :float)
      @exposed_perimeter = XMLHelper.get_value(slab, 'ExposedPerimeter', :float)
      @depth_below_grade = XMLHelper.get_value(slab, 'DepthBelowGrade', :float)
      perimeter_insulation = XMLHelper.get_element(slab, 'PerimeterInsulation')
      if not perimeter_insulation.nil?
        @perimeter_insulation_id = HPXML::get_id(perimeter_insulation)
        @perimeter_insulation_r_value = XMLHelper.get_value(perimeter_insulation, 'Layer/NominalRValue', :float)
        @perimeter_insulation_depth = XMLHelper.get_value(perimeter_insulation, 'Layer/InsulationDepth', :float)
      end
      under_slab_insulation = XMLHelper.get_element(slab, 'UnderSlabInsulation')
      if not under_slab_insulation.nil?
        @under_slab_insulation_id = HPXML::get_id(under_slab_insulation)
        @under_slab_insulation_r_value = XMLHelper.get_value(under_slab_insulation, 'Layer/NominalRValue', :float)
        @under_slab_insulation_width = XMLHelper.get_value(under_slab_insulation, 'Layer/InsulationWidth', :float)
        @under_slab_insulation_spans_entire_slab = XMLHelper.get_value(under_slab_insulation, 'Layer/InsulationSpansEntireSlab', :boolean)
      end
      @carpet_fraction = XMLHelper.get_value(slab, 'extension/CarpetFraction', :float)
      @carpet_r_value = XMLHelper.get_value(slab, 'extension/CarpetRValue', :float)
    end
  end

  class Windows < BaseArrayElement
    def add(**kwargs)
      self << Window.new(@parent_object, **kwargs)
    end

    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/Enclosure/Windows/Window').each do |window|
        self << Window.new(@parent_object, window)
      end
    end
  end

  class Window < BaseElement
    ATTRS = [:id, :area, :azimuth, :orientation, :frame_type, :thermal_break, :glass_layers,
             :glass_type, :gas_fill, :ufactor, :shgc, :interior_shading_factor_summer,
             :interior_shading_id, :interior_shading_factor_winter, :interior_shading_type, :exterior_shading_factor_summer,
             :exterior_shading_id, :exterior_shading_factor_winter, :exterior_shading_type, :storm_type, :overhangs_depth,
             :overhangs_distance_to_top_of_window, :overhangs_distance_to_bottom_of_window,
             :fraction_operable, :performance_class, :wall_idref]
    attr_accessor(*ATTRS)

    def wall
      return if @wall_idref.nil?

      (@parent_object.walls + @parent_object.foundation_walls).each do |wall|
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
      return HPXML::is_thermal_boundary(wall)
    end

    def is_exterior_thermal_boundary
      return (is_exterior && is_thermal_boundary)
    end

    def is_conditioned
      return HPXML::is_conditioned(self)
    end

    def delete
      @parent_object.windows.delete(self)
    end

    def check_for_errors
      errors = []
      begin; wall; rescue StandardError => e; errors << e.message; end
      return errors
    end

    def to_doc(building)
      return if nil?

      windows = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Enclosure', 'Windows'])
      window = XMLHelper.add_element(windows, 'Window')
      sys_id = XMLHelper.add_element(window, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_element(window, 'Area', @area, :float) unless @area.nil?
      XMLHelper.add_element(window, 'Azimuth', @azimuth, :integer, @azimuth_isdefaulted) unless @azimuth.nil?
      XMLHelper.add_element(window, 'Orientation', @orientation, :string, @orientation_isdefaulted) unless @orientation.nil?
      if not @frame_type.nil?
        frame_type_el = XMLHelper.add_element(window, 'FrameType')
        frame_type = XMLHelper.add_element(frame_type_el, @frame_type)
        if [HPXML::WindowFrameTypeAluminum, HPXML::WindowFrameTypeMetal].include? @frame_type
          XMLHelper.add_element(frame_type, 'ThermalBreak', @thermal_break, :boolean, @thermal_break_isdefaulted) unless @thermal_break.nil?
        end
      end
      XMLHelper.add_element(window, 'GlassLayers', @glass_layers, :string, @glass_layers_isdefaulted) unless @glass_layers.nil?
      XMLHelper.add_element(window, 'GlassType', @glass_type, :string, @glass_type_isdefaulted) unless @glass_type.nil?
      XMLHelper.add_element(window, 'GasFill', @gas_fill, :string, @gas_fill_isdefaulted) unless @gas_fill.nil?
      XMLHelper.add_element(window, 'UFactor', @ufactor, :float, @ufactor_isdefaulted) unless @ufactor.nil?
      XMLHelper.add_element(window, 'SHGC', @shgc, :float, @shgc_isdefaulted) unless @shgc.nil?
      if (not @exterior_shading_type.nil?) || (not @exterior_shading_factor_summer.nil?) || (not @exterior_shading_factor_winter.nil?)
        exterior_shading = XMLHelper.add_element(window, 'ExteriorShading')
        sys_id = XMLHelper.add_element(exterior_shading, 'SystemIdentifier')
        if @exterior_shading_id.nil?
          XMLHelper.add_attribute(sys_id, 'id', "#{id}ExteriorShading")
        else
          XMLHelper.add_attribute(sys_id, 'id', @exterior_shading_id)
        end
        XMLHelper.add_element(exterior_shading, 'Type', @exterior_shading_type, :string) unless @exterior_shading_type.nil?
        XMLHelper.add_element(exterior_shading, 'SummerShadingCoefficient', @exterior_shading_factor_summer, :float, @exterior_shading_factor_summer_isdefaulted) unless @exterior_shading_factor_summer.nil?
        XMLHelper.add_element(exterior_shading, 'WinterShadingCoefficient', @exterior_shading_factor_winter, :float, @exterior_shading_factor_winter_isdefaulted) unless @exterior_shading_factor_winter.nil?
      end
      if (not @interior_shading_type.nil?) || (not @interior_shading_factor_summer.nil?) || (not @interior_shading_factor_winter.nil?)
        interior_shading = XMLHelper.add_element(window, 'InteriorShading')
        sys_id = XMLHelper.add_element(interior_shading, 'SystemIdentifier')
        if @interior_shading_id.nil?
          XMLHelper.add_attribute(sys_id, 'id', "#{id}InteriorShading")
        else
          XMLHelper.add_attribute(sys_id, 'id', @interior_shading_id)
        end
        XMLHelper.add_element(interior_shading, 'Type', @interior_shading_type, :string) unless @interior_shading_type.nil?
        XMLHelper.add_element(interior_shading, 'SummerShadingCoefficient', @interior_shading_factor_summer, :float, @interior_shading_factor_summer_isdefaulted) unless @interior_shading_factor_summer.nil?
        XMLHelper.add_element(interior_shading, 'WinterShadingCoefficient', @interior_shading_factor_winter, :float, @interior_shading_factor_winter_isdefaulted) unless @interior_shading_factor_winter.nil?
      end
      if not @storm_type.nil?
        storm_window = XMLHelper.add_element(window, 'StormWindow')
        sys_id = XMLHelper.add_element(storm_window, 'SystemIdentifier')
        XMLHelper.add_attribute(sys_id, 'id', "#{id}StormWindow")
        XMLHelper.add_element(storm_window, 'GlassType', @storm_type, :string) unless @storm_type.nil?
      end
      if (not @overhangs_depth.nil?) || (not @overhangs_distance_to_top_of_window.nil?) || (not @overhangs_distance_to_bottom_of_window.nil?)
        overhangs = XMLHelper.add_element(window, 'Overhangs')
        XMLHelper.add_element(overhangs, 'Depth', @overhangs_depth, :float) unless @overhangs_depth.nil?
        XMLHelper.add_element(overhangs, 'DistanceToTopOfWindow', @overhangs_distance_to_top_of_window, :float) unless @overhangs_distance_to_top_of_window.nil?
        XMLHelper.add_element(overhangs, 'DistanceToBottomOfWindow', @overhangs_distance_to_bottom_of_window, :float) unless @overhangs_distance_to_bottom_of_window.nil?
      end
      XMLHelper.add_element(window, 'FractionOperable', @fraction_operable, :float, @fraction_operable_isdefaulted) unless @fraction_operable.nil?
      XMLHelper.add_element(window, 'PerformanceClass', @performance_class, :string, @performance_class_isdefaulted) unless @performance_class.nil?
      if not @wall_idref.nil?
        attached_to_wall = XMLHelper.add_element(window, 'AttachedToWall')
        XMLHelper.add_attribute(attached_to_wall, 'idref', @wall_idref)
      end
    end

    def from_doc(window)
      return if window.nil?

      @id = HPXML::get_id(window)
      @area = XMLHelper.get_value(window, 'Area', :float)
      @azimuth = XMLHelper.get_value(window, 'Azimuth', :integer)
      @orientation = XMLHelper.get_value(window, 'Orientation', :string)
      @frame_type = XMLHelper.get_child_name(window, 'FrameType')
      if @frame_type == HPXML::WindowFrameTypeAluminum
        @thermal_break = XMLHelper.get_value(window, 'FrameType/Aluminum/ThermalBreak', :boolean)
      elsif @frame_type == HPXML::WindowFrameTypeMetal
        @thermal_break = XMLHelper.get_value(window, 'FrameType/Metal/ThermalBreak', :boolean)
      end
      @glass_layers = XMLHelper.get_value(window, 'GlassLayers', :string)
      @glass_type = XMLHelper.get_value(window, 'GlassType', :string)
      @gas_fill = XMLHelper.get_value(window, 'GasFill', :string)
      @ufactor = XMLHelper.get_value(window, 'UFactor', :float)
      @shgc = XMLHelper.get_value(window, 'SHGC', :float)
      @exterior_shading_id = HPXML::get_id(window, 'ExteriorShading/SystemIdentifier')
      @exterior_shading_type = XMLHelper.get_value(window, 'ExteriorShading/Type', :string)
      @exterior_shading_factor_summer = XMLHelper.get_value(window, 'ExteriorShading/SummerShadingCoefficient', :float)
      @exterior_shading_factor_winter = XMLHelper.get_value(window, 'ExteriorShading/WinterShadingCoefficient', :float)
      @interior_shading_id = HPXML::get_id(window, 'InteriorShading/SystemIdentifier')
      @interior_shading_type = XMLHelper.get_value(window, 'InteriorShading/Type', :string)
      @interior_shading_factor_summer = XMLHelper.get_value(window, 'InteriorShading/SummerShadingCoefficient', :float)
      @interior_shading_factor_winter = XMLHelper.get_value(window, 'InteriorShading/WinterShadingCoefficient', :float)
      @overhangs_depth = XMLHelper.get_value(window, 'Overhangs/Depth', :float)
      @overhangs_distance_to_top_of_window = XMLHelper.get_value(window, 'Overhangs/DistanceToTopOfWindow', :float)
      @overhangs_distance_to_bottom_of_window = XMLHelper.get_value(window, 'Overhangs/DistanceToBottomOfWindow', :float)
      @fraction_operable = XMLHelper.get_value(window, 'FractionOperable', :float)
      @performance_class = XMLHelper.get_value(window, 'PerformanceClass', :string)
      @wall_idref = HPXML::get_idref(XMLHelper.get_element(window, 'AttachedToWall'))
      @storm_type = XMLHelper.get_value(window, 'StormWindow/GlassType', :string)
    end
  end

  class Skylights < BaseArrayElement
    def add(**kwargs)
      self << Skylight.new(@parent_object, **kwargs)
    end

    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/Enclosure/Skylights/Skylight').each do |skylight|
        self << Skylight.new(@parent_object, skylight)
      end
    end
  end

  class Skylight < BaseElement
    ATTRS = [:id, :area, :azimuth, :orientation, :frame_type, :thermal_break, :glass_layers,
             :glass_type, :gas_fill, :ufactor, :shgc, :interior_shading_factor_summer,
             :interior_shading_factor_winter, :interior_shading_type, :exterior_shading_factor_summer,
             :exterior_shading_factor_winter, :exterior_shading_type, :storm_type, :roof_idref]
    attr_accessor(*ATTRS)

    def roof
      return if @roof_idref.nil?

      @parent_object.roofs.each do |roof|
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
      return HPXML::is_thermal_boundary(roof)
    end

    def is_exterior_thermal_boundary
      return (is_exterior && is_thermal_boundary)
    end

    def is_conditioned
      return HPXML::is_conditioned(self)
    end

    def delete
      @parent_object.skylights.delete(self)
    end

    def check_for_errors
      errors = []
      begin; roof; rescue StandardError => e; errors << e.message; end
      return errors
    end

    def to_doc(building)
      return if nil?

      skylights = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Enclosure', 'Skylights'])
      skylight = XMLHelper.add_element(skylights, 'Skylight')
      sys_id = XMLHelper.add_element(skylight, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_element(skylight, 'Area', @area, :float) unless @area.nil?
      XMLHelper.add_element(skylight, 'Azimuth', @azimuth, :integer, @azimuth_isdefaulted) unless @azimuth.nil?
      XMLHelper.add_element(skylight, 'Orientation', @orientation, :string, @orientation_isdefaulted) unless @orientation.nil?
      if not @frame_type.nil?
        frame_type_el = XMLHelper.add_element(skylight, 'FrameType')
        frame_type = XMLHelper.add_element(frame_type_el, @frame_type)
        if [HPXML::WindowFrameTypeAluminum, HPXML::WindowFrameTypeMetal].include? @frame_type
          XMLHelper.add_element(frame_type, 'ThermalBreak', @thermal_break, :boolean, @thermal_break_isdefaulted) unless @thermal_break.nil?
        end
      end
      XMLHelper.add_element(skylight, 'GlassLayers', @glass_layers, :string, @glass_layers_isdefaulted) unless @glass_layers.nil?
      XMLHelper.add_element(skylight, 'GlassType', @glass_type, :string, @glass_type_isdefaulted) unless @glass_type.nil?
      XMLHelper.add_element(skylight, 'GasFill', @gas_fill, :string, @gas_fill_isdefaulted) unless @gas_fill.nil?
      XMLHelper.add_element(skylight, 'UFactor', @ufactor, :float, @ufactor_isdefaulted) unless @ufactor.nil?
      XMLHelper.add_element(skylight, 'SHGC', @shgc, :float, @shgc_isdefaulted) unless @shgc.nil?
      if (not @exterior_shading_type.nil?) || (not @exterior_shading_factor_summer.nil?) || (not @exterior_shading_factor_winter.nil?)
        exterior_shading = XMLHelper.add_element(skylight, 'ExteriorShading')
        sys_id = XMLHelper.add_element(exterior_shading, 'SystemIdentifier')
        XMLHelper.add_attribute(sys_id, 'id', "#{id}ExteriorShading")
        XMLHelper.add_element(exterior_shading, 'Type', @exterior_shading_type, :string) unless @exterior_shading_type.nil?
        XMLHelper.add_element(exterior_shading, 'SummerShadingCoefficient', @exterior_shading_factor_summer, :float, @exterior_shading_factor_summer_isdefaulted) unless @exterior_shading_factor_summer.nil?
        XMLHelper.add_element(exterior_shading, 'WinterShadingCoefficient', @exterior_shading_factor_winter, :float, @exterior_shading_factor_winter_isdefaulted) unless @exterior_shading_factor_winter.nil?
      end
      if (not @interior_shading_type.nil?) || (not @interior_shading_factor_summer.nil?) || (not @interior_shading_factor_winter.nil?)
        interior_shading = XMLHelper.add_element(skylight, 'InteriorShading')
        sys_id = XMLHelper.add_element(interior_shading, 'SystemIdentifier')
        XMLHelper.add_attribute(sys_id, 'id', "#{id}InteriorShading")
        XMLHelper.add_element(interior_shading, 'Type', @interior_shading_type, :string) unless @interior_shading_type.nil?
        XMLHelper.add_element(interior_shading, 'SummerShadingCoefficient', @interior_shading_factor_summer, :float, @interior_shading_factor_summer_isdefaulted) unless @interior_shading_factor_summer.nil?
        XMLHelper.add_element(interior_shading, 'WinterShadingCoefficient', @interior_shading_factor_winter, :float, @interior_shading_factor_winter_isdefaulted) unless @interior_shading_factor_winter.nil?
      end
      if not @storm_type.nil?
        storm_window = XMLHelper.add_element(skylight, 'StormWindow')
        sys_id = XMLHelper.add_element(storm_window, 'SystemIdentifier')
        XMLHelper.add_attribute(sys_id, 'id', "#{id}StormWindow")
        XMLHelper.add_element(storm_window, 'GlassType', @storm_type, :string) unless @storm_type.nil?
      end
      if not @roof_idref.nil?
        attached_to_roof = XMLHelper.add_element(skylight, 'AttachedToRoof')
        XMLHelper.add_attribute(attached_to_roof, 'idref', @roof_idref)
      end
    end

    def from_doc(skylight)
      return if skylight.nil?

      @id = HPXML::get_id(skylight)
      @area = XMLHelper.get_value(skylight, 'Area', :float)
      @azimuth = XMLHelper.get_value(skylight, 'Azimuth', :integer)
      @orientation = XMLHelper.get_value(skylight, 'Orientation', :string)
      @frame_type = XMLHelper.get_child_name(skylight, 'FrameType')
      if @frame_type == HPXML::WindowFrameTypeAluminum
        @thermal_break = XMLHelper.get_value(skylight, 'FrameType/Aluminum/ThermalBreak', :boolean)
      elsif @frame_type == HPXML::WindowFrameTypeMetal
        @thermal_break = XMLHelper.get_value(skylight, 'FrameType/Metal/ThermalBreak', :boolean)
      end
      @glass_layers = XMLHelper.get_value(skylight, 'GlassLayers', :string)
      @glass_type = XMLHelper.get_value(skylight, 'GlassType', :string)
      @gas_fill = XMLHelper.get_value(skylight, 'GasFill', :string)
      @ufactor = XMLHelper.get_value(skylight, 'UFactor', :float)
      @shgc = XMLHelper.get_value(skylight, 'SHGC', :float)
      @exterior_shading_type = XMLHelper.get_value(skylight, 'ExteriorShading/Type', :string)
      @exterior_shading_factor_summer = XMLHelper.get_value(skylight, 'ExteriorShading/SummerShadingCoefficient', :float)
      @exterior_shading_factor_winter = XMLHelper.get_value(skylight, 'ExteriorShading/WinterShadingCoefficient', :float)
      @interior_shading_type = XMLHelper.get_value(skylight, 'InteriorShading/Type', :string)
      @interior_shading_factor_summer = XMLHelper.get_value(skylight, 'InteriorShading/SummerShadingCoefficient', :float)
      @interior_shading_factor_winter = XMLHelper.get_value(skylight, 'InteriorShading/WinterShadingCoefficient', :float)
      @roof_idref = HPXML::get_idref(XMLHelper.get_element(skylight, 'AttachedToRoof'))
      @storm_type = XMLHelper.get_value(skylight, 'StormWindow/GlassType', :string)
    end
  end

  class Doors < BaseArrayElement
    def add(**kwargs)
      self << Door.new(@parent_object, **kwargs)
    end

    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/Enclosure/Doors/Door').each do |door|
        self << Door.new(@parent_object, door)
      end
    end
  end

  class Door < BaseElement
    ATTRS = [:id, :wall_idref, :area, :azimuth, :orientation, :r_value]
    attr_accessor(*ATTRS)

    def wall
      return if @wall_idref.nil?

      (@parent_object.walls + @parent_object.foundation_walls).each do |wall|
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
      return HPXML::is_thermal_boundary(wall)
    end

    def is_exterior_thermal_boundary
      return (is_exterior && is_thermal_boundary)
    end

    def is_conditioned
      return HPXML::is_conditioned(self)
    end

    def delete
      @parent_object.doors.delete(self)
    end

    def check_for_errors
      errors = []
      begin; wall; rescue StandardError => e; errors << e.message; end
      return errors
    end

    def to_doc(building)
      return if nil?

      doors = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Enclosure', 'Doors'])
      door = XMLHelper.add_element(doors, 'Door')
      sys_id = XMLHelper.add_element(door, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      if not @wall_idref.nil?
        attached_to_wall = XMLHelper.add_element(door, 'AttachedToWall')
        XMLHelper.add_attribute(attached_to_wall, 'idref', @wall_idref)
      end
      XMLHelper.add_element(door, 'Area', @area, :float) unless @area.nil?
      XMLHelper.add_element(door, 'Azimuth', @azimuth, :integer, @azimuth_isdefaulted) unless @azimuth.nil?
      XMLHelper.add_element(door, 'Orientation', @orientation, :string, @orientation_isdefaulted) unless @orientation.nil?
      XMLHelper.add_element(door, 'RValue', @r_value, :float) unless @r_value.nil?
    end

    def from_doc(door)
      return if door.nil?

      @id = HPXML::get_id(door)
      @wall_idref = HPXML::get_idref(XMLHelper.get_element(door, 'AttachedToWall'))
      @area = XMLHelper.get_value(door, 'Area', :float)
      @azimuth = XMLHelper.get_value(door, 'Azimuth', :integer)
      @orientation = XMLHelper.get_value(door, 'Orientation', :string)
      @r_value = XMLHelper.get_value(door, 'RValue', :float)
    end
  end

  class PartitionWallMass < BaseElement
    ATTRS = [:area_fraction, :interior_finish_type, :interior_finish_thickness]
    attr_accessor(*ATTRS)

    def check_for_errors
      errors = []
      return errors
    end

    def to_doc(building)
      return if nil?

      partition_wall_mass = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Enclosure', 'extension', 'PartitionWallMass'])
      XMLHelper.add_element(partition_wall_mass, 'AreaFraction', @area_fraction, :float, @area_fraction_isdefaulted) unless @area_fraction.nil?
      if (not @interior_finish_type.nil?) || (not @interior_finish_thickness.nil?)
        interior_finish = XMLHelper.add_element(partition_wall_mass, 'InteriorFinish')
        XMLHelper.add_element(interior_finish, 'Type', @interior_finish_type, :string, @interior_finish_type_isdefaulted) unless @interior_finish_type.nil?
        XMLHelper.add_element(interior_finish, 'Thickness', @interior_finish_thickness, :float, @interior_finish_thickness_isdefaulted) unless @interior_finish_thickness.nil?
      end
    end

    def from_doc(building)
      return if building.nil?

      partition_wall_mass = XMLHelper.get_element(building, 'BuildingDetails/Enclosure/extension/PartitionWallMass')
      return if partition_wall_mass.nil?

      @area_fraction = XMLHelper.get_value(partition_wall_mass, 'AreaFraction', :float)
      interior_finish = XMLHelper.get_element(partition_wall_mass, 'InteriorFinish')
      if not interior_finish.nil?
        @interior_finish_type = XMLHelper.get_value(interior_finish, 'Type', :string)
        @interior_finish_thickness = XMLHelper.get_value(interior_finish, 'Thickness', :float)
      end
    end
  end

  class FurnitureMass < BaseElement
    ATTRS = [:area_fraction, :type]
    attr_accessor(*ATTRS)

    def check_for_errors
      errors = []
      return errors
    end

    def to_doc(building)
      return if nil?

      furniture_mass = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Enclosure', 'extension', 'FurnitureMass'])
      XMLHelper.add_element(furniture_mass, 'AreaFraction', @area_fraction, :float, @area_fraction_isdefaulted) unless @area_fraction.nil?
      XMLHelper.add_element(furniture_mass, 'Type', @type, :string, @type_isdefaulted) unless @type.nil?
    end

    def from_doc(building)
      return if building.nil?

      furniture_mass = XMLHelper.get_element(building, 'BuildingDetails/Enclosure/extension/FurnitureMass')
      return if furniture_mass.nil?

      @area_fraction = XMLHelper.get_value(furniture_mass, 'AreaFraction', :float)
      @type = XMLHelper.get_value(furniture_mass, 'Type', :string)
    end
  end

  class HeatingSystems < BaseArrayElement
    def add(**kwargs)
      self << HeatingSystem.new(@parent_object, **kwargs)
    end

    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem').each do |heating_system|
        self << HeatingSystem.new(@parent_object, heating_system)
      end
    end

    def total_fraction_heat_load_served
      map { |htg_sys| htg_sys.fraction_heat_load_served.to_f }.sum(0.0)
    end
  end

  class HeatingSystem < BaseElement
    def initialize(hpxml_object, *args)
      @heating_detailed_performance_data = HeatingDetailedPerformanceData.new(hpxml_object)
      super(hpxml_object, *args)
    end
    ATTRS = [:id, :distribution_system_idref, :year_installed, :heating_system_type,
             :heating_system_fuel, :heating_capacity, :heating_efficiency_afue,
             :heating_efficiency_percent, :fraction_heat_load_served, :electric_auxiliary_energy,
             :third_party_certification, :htg_seed_id, :is_shared_system, :number_of_units_served,
             :shared_loop_watts, :shared_loop_motor_efficiency, :fan_coil_watts, :fan_watts_per_cfm,
             :airflow_defect_ratio, :fan_watts, :heating_airflow_cfm, :location, :primary_system,
             :pilot_light, :pilot_light_btuh]
    attr_accessor(*ATTRS)
    attr_reader(:heating_detailed_performance_data)

    def distribution_system
      return if @distribution_system_idref.nil?

      @parent_object.hvac_distributions.each do |hvac_distribution|
        next unless hvac_distribution.id == @distribution_system_idref

        return hvac_distribution
      end
      fail "Attached HVAC distribution system '#{@distribution_system_idref}' not found for HVAC system '#{@id}'."
    end

    def attached_cooling_system
      return if distribution_system.nil?

      # by distribution system
      distribution_system.hvac_systems.each do |hvac_system|
        next if hvac_system.id == @id

        return hvac_system
      end

      return
    end

    def related_water_heating_system
      @parent_object.water_heating_systems.each do |water_heating_system|
        next unless water_heating_system.related_hvac_idref == @id

        return water_heating_system
      end
      return
    end

    def primary_heat_pump
      # Returns the HP for which this heating system is backup
      @parent_object.heat_pumps.each do |heat_pump|
        next if heat_pump.backup_system_idref.nil?
        next if heat_pump.backup_system_idref != @id

        return heat_pump
      end
      return
    end

    def is_heat_pump_backup_system
      return !primary_heat_pump.nil?
    end

    def delete
      @parent_object.heating_systems.delete(self)
      @parent_object.water_heating_systems.each do |water_heating_system|
        next unless water_heating_system.related_hvac_idref == @id

        water_heating_system.related_hvac_idref = nil
      end
    end

    def check_for_errors
      errors = []
      begin; distribution_system; rescue StandardError => e; errors << e.message; end
      errors += @heating_detailed_performance_data.check_for_errors
      return errors
    end

    def to_doc(building)
      return if nil?

      hvac_plant = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Systems', 'HVAC', 'HVACPlant'])
      primary_systems = XMLHelper.create_elements_as_needed(hvac_plant, ['PrimarySystems']) unless @parent_object.primary_hvac_systems.empty?
      heating_system = XMLHelper.add_element(hvac_plant, 'HeatingSystem')
      sys_id = XMLHelper.add_element(heating_system, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_element(heating_system, 'UnitLocation', @location, :string, @location_isdefaulted) unless @location.nil?
      XMLHelper.add_element(heating_system, 'YearInstalled', @year_installed, :integer) unless @year_installed.nil?
      XMLHelper.add_element(heating_system, 'ThirdPartyCertification', @third_party_certification, :string) unless @third_party_certification.nil?
      if not @distribution_system_idref.nil?
        distribution_system = XMLHelper.add_element(heating_system, 'DistributionSystem')
        XMLHelper.add_attribute(distribution_system, 'idref', @distribution_system_idref)
      end
      XMLHelper.add_element(heating_system, 'IsSharedSystem', @is_shared_system, :boolean) unless @is_shared_system.nil?
      XMLHelper.add_element(heating_system, 'NumberofUnitsServed', @number_of_units_served, :integer) unless @number_of_units_served.nil?
      if not @heating_system_type.nil?
        heating_system_type_el = XMLHelper.add_element(heating_system, 'HeatingSystemType')
        type_el = XMLHelper.add_element(heating_system_type_el, @heating_system_type)
        if [HPXML::HVACTypeFurnace,
            HPXML::HVACTypeWallFurnace,
            HPXML::HVACTypeFloorFurnace,
            HPXML::HVACTypeFireplace,
            HPXML::HVACTypeStove,
            HPXML::HVACTypeBoiler].include? @heating_system_type
          XMLHelper.add_element(type_el, 'PilotLight', @pilot_light, :boolean, @pilot_light_isdefaulted) unless @pilot_light.nil?
          if @pilot_light
            XMLHelper.add_extension(type_el, 'PilotLightBtuh', @pilot_light_btuh, :float, @pilot_light_btuh_isdefaulted) unless @pilot_light_btuh.nil?
          end
        end
      end
      XMLHelper.add_element(heating_system, 'HeatingSystemFuel', @heating_system_fuel, :string) unless @heating_system_fuel.nil?
      XMLHelper.add_element(heating_system, 'HeatingCapacity', @heating_capacity, :float, @heating_capacity_isdefaulted) unless @heating_capacity.nil?
      if not @heating_efficiency_afue.nil?
        annual_efficiency = XMLHelper.add_element(heating_system, 'AnnualHeatingEfficiency')
        XMLHelper.add_element(annual_efficiency, 'Units', UnitsAFUE, :string)
        XMLHelper.add_element(annual_efficiency, 'Value', @heating_efficiency_afue, :float, @heating_efficiency_afue_isdefaulted)
      end
      if not @heating_efficiency_percent.nil?
        annual_efficiency = XMLHelper.add_element(heating_system, 'AnnualHeatingEfficiency')
        XMLHelper.add_element(annual_efficiency, 'Units', UnitsPercent, :string)
        XMLHelper.add_element(annual_efficiency, 'Value', @heating_efficiency_percent, :float, @heating_efficiency_percent_isdefaulted)
      end
      @heating_detailed_performance_data.to_doc(heating_system)
      XMLHelper.add_element(heating_system, 'FractionHeatLoadServed', @fraction_heat_load_served, :float, @fraction_heat_load_served_isdefaulted) unless @fraction_heat_load_served.nil?
      XMLHelper.add_element(heating_system, 'ElectricAuxiliaryEnergy', @electric_auxiliary_energy, :float, @electric_auxiliary_energy_isdefaulted) unless @electric_auxiliary_energy.nil?
      XMLHelper.add_extension(heating_system, 'SharedLoopWatts', @shared_loop_watts, :float) unless @shared_loop_watts.nil?
      XMLHelper.add_extension(heating_system, 'SharedLoopMotorEfficiency', @shared_loop_motor_efficiency, :float) unless @shared_loop_motor_efficiency.nil?
      XMLHelper.add_extension(heating_system, 'FanCoilWatts', @fan_coil_watts, :float) unless @fan_coil_watts.nil?
      XMLHelper.add_extension(heating_system, 'FanPowerWattsPerCFM', @fan_watts_per_cfm, :float, @fan_watts_per_cfm_isdefaulted) unless @fan_watts_per_cfm.nil?
      XMLHelper.add_extension(heating_system, 'FanPowerWatts', @fan_watts, :float, @fan_watts_isdefaulted) unless @fan_watts.nil?
      XMLHelper.add_extension(heating_system, 'AirflowDefectRatio', @airflow_defect_ratio, :float, @airflow_defect_ratio_isdefaulted) unless @airflow_defect_ratio.nil?
      XMLHelper.add_extension(heating_system, 'HeatingAirflowCFM', @heating_airflow_cfm, :float, @heating_airflow_cfm_isdefaulted) unless @heating_airflow_cfm.nil?
      XMLHelper.add_extension(heating_system, 'HeatingSeedId', @htg_seed_id, :string) unless @htg_seed_id.nil?
      if @primary_system
        primary_heating_system = XMLHelper.insert_element(primary_systems, 'PrimaryHeatingSystem')
        XMLHelper.add_attribute(primary_heating_system, 'idref', @id)
      end
    end

    def from_doc(heating_system)
      return if heating_system.nil?

      @id = HPXML::get_id(heating_system)
      @location = XMLHelper.get_value(heating_system, 'UnitLocation', :string)
      @year_installed = XMLHelper.get_value(heating_system, 'YearInstalled', :integer)
      @third_party_certification = XMLHelper.get_value(heating_system, 'ThirdPartyCertification', :string)
      @distribution_system_idref = HPXML::get_idref(XMLHelper.get_element(heating_system, 'DistributionSystem'))
      @is_shared_system = XMLHelper.get_value(heating_system, 'IsSharedSystem', :boolean)
      @number_of_units_served = XMLHelper.get_value(heating_system, 'NumberofUnitsServed', :integer)
      @heating_system_type = XMLHelper.get_child_name(heating_system, 'HeatingSystemType')
      @heating_system_fuel = XMLHelper.get_value(heating_system, 'HeatingSystemFuel', :string)
      @pilot_light = XMLHelper.get_value(heating_system, "HeatingSystemType/#{@heating_system_type}/PilotLight", :boolean)
      if @pilot_light
        @pilot_light_btuh = XMLHelper.get_value(heating_system, "HeatingSystemType/#{@heating_system_type}/extension/PilotLightBtuh", :float)
      end
      @heating_capacity = XMLHelper.get_value(heating_system, 'HeatingCapacity', :float)
      @heating_efficiency_afue = XMLHelper.get_value(heating_system, "AnnualHeatingEfficiency[Units='#{UnitsAFUE}']/Value", :float)
      @heating_efficiency_percent = XMLHelper.get_value(heating_system, "AnnualHeatingEfficiency[Units='Percent']/Value", :float)
      @heating_detailed_performance_data.from_doc(heating_system)
      @fraction_heat_load_served = XMLHelper.get_value(heating_system, 'FractionHeatLoadServed', :float)
      @electric_auxiliary_energy = XMLHelper.get_value(heating_system, 'ElectricAuxiliaryEnergy', :float)
      @shared_loop_watts = XMLHelper.get_value(heating_system, 'extension/SharedLoopWatts', :float)
      @shared_loop_motor_efficiency = XMLHelper.get_value(heating_system, 'extension/SharedLoopMotorEfficiency', :float)
      @fan_coil_watts = XMLHelper.get_value(heating_system, 'extension/FanCoilWatts', :float)
      @fan_watts_per_cfm = XMLHelper.get_value(heating_system, 'extension/FanPowerWattsPerCFM', :float)
      @fan_watts = XMLHelper.get_value(heating_system, 'extension/FanPowerWatts', :float)
      @airflow_defect_ratio = XMLHelper.get_value(heating_system, 'extension/AirflowDefectRatio', :float)
      @heating_airflow_cfm = XMLHelper.get_value(heating_system, 'extension/HeatingAirflowCFM', :float)
      @htg_seed_id = XMLHelper.get_value(heating_system, 'extension/HeatingSeedId', :string)
      primary_heating_system = HPXML::get_idref(XMLHelper.get_element(heating_system, '../PrimarySystems/PrimaryHeatingSystem'))
      if primary_heating_system == @id
        @primary_system = true
      else
        @primary_system = false
      end
    end
  end

  class CoolingSystems < BaseArrayElement
    def add(**kwargs)
      self << CoolingSystem.new(@parent_object, **kwargs)
    end

    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/Systems/HVAC/HVACPlant/CoolingSystem').each do |cooling_system|
        self << CoolingSystem.new(@parent_object, cooling_system)
      end
    end

    def total_fraction_cool_load_served
      map { |clg_sys| clg_sys.fraction_cool_load_served.to_f }.sum(0.0)
    end

    def total_fraction_heat_load_served
      map { |clg_sys| clg_sys.integrated_heating_system_fraction_heat_load_served.to_f }.sum(0.0)
    end
  end

  class CoolingSystem < BaseElement
    def initialize(hpxml_object, *args)
      @cooling_detailed_performance_data = CoolingDetailedPerformanceData.new(hpxml_object)
      super(hpxml_object, *args)
    end
    ATTRS = [:id, :distribution_system_idref, :year_installed, :cooling_system_type, :cooling_system_fuel,
             :cooling_capacity, :compressor_type, :fraction_cool_load_served, :cooling_efficiency_seer,
             :cooling_efficiency_seer2, :cooling_efficiency_eer, :cooling_efficiency_ceer, :cooling_efficiency_kw_per_ton,
             :cooling_shr, :third_party_certification, :clg_seed_id, :is_shared_system, :number_of_units_served,
             :shared_loop_watts, :shared_loop_motor_efficiency, :fan_coil_watts, :airflow_defect_ratio,
             :fan_watts_per_cfm, :charge_defect_ratio, :cooling_airflow_cfm, :location, :primary_system,
             :integrated_heating_system_fuel, :integrated_heating_system_capacity, :integrated_heating_system_efficiency_percent,
             :integrated_heating_system_fraction_heat_load_served, :integrated_heating_system_airflow_cfm, :htg_seed_id, :crankcase_heater_watts]
    attr_accessor(*ATTRS)
    attr_reader(:cooling_detailed_performance_data)

    def distribution_system
      return if @distribution_system_idref.nil?

      @parent_object.hvac_distributions.each do |hvac_distribution|
        next unless hvac_distribution.id == @distribution_system_idref

        return hvac_distribution
      end
      fail "Attached HVAC distribution system '#{@distribution_system_idref}' not found for HVAC system '#{@id}'."
    end

    def attached_heating_system
      # by distribution system
      return if distribution_system.nil?

      distribution_system.hvac_systems.each do |hvac_system|
        next if hvac_system.id == @id

        return hvac_system
      end
      return
    end

    def has_integrated_heating
      return false unless [HVACTypePTAC, HVACTypeRoomAirConditioner].include? @cooling_system_type
      return false if @integrated_heating_system_fuel.nil?

      return true
    end

    def delete
      @parent_object.cooling_systems.delete(self)
      @parent_object.water_heating_systems.each do |water_heating_system|
        next unless water_heating_system.related_hvac_idref == @id

        water_heating_system.related_hvac_idref = nil
      end
    end

    def check_for_errors
      errors = []
      begin; distribution_system; rescue StandardError => e; errors << e.message; end
      errors += @cooling_detailed_performance_data.check_for_errors
      return errors
    end

    def to_doc(building)
      return if nil?

      hvac_plant = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Systems', 'HVAC', 'HVACPlant'])
      primary_systems = XMLHelper.create_elements_as_needed(hvac_plant, ['PrimarySystems']) unless @parent_object.primary_hvac_systems.empty?
      cooling_system = XMLHelper.add_element(hvac_plant, 'CoolingSystem')
      sys_id = XMLHelper.add_element(cooling_system, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_element(cooling_system, 'UnitLocation', @location, :string, @location_isdefaulted) unless @location.nil?
      XMLHelper.add_element(cooling_system, 'YearInstalled', @year_installed, :integer) unless @year_installed.nil?
      XMLHelper.add_element(cooling_system, 'ThirdPartyCertification', @third_party_certification, :string) unless @third_party_certification.nil?
      if not @distribution_system_idref.nil?
        distribution_system = XMLHelper.add_element(cooling_system, 'DistributionSystem')
        XMLHelper.add_attribute(distribution_system, 'idref', @distribution_system_idref)
      end
      XMLHelper.add_element(cooling_system, 'IsSharedSystem', @is_shared_system, :boolean) unless @is_shared_system.nil?
      XMLHelper.add_element(cooling_system, 'NumberofUnitsServed', @number_of_units_served, :integer) unless @number_of_units_served.nil?
      XMLHelper.add_element(cooling_system, 'CoolingSystemType', @cooling_system_type, :string) unless @cooling_system_type.nil?
      XMLHelper.add_element(cooling_system, 'CoolingSystemFuel', @cooling_system_fuel, :string) unless @cooling_system_fuel.nil?
      XMLHelper.add_element(cooling_system, 'CoolingCapacity', @cooling_capacity, :float, @cooling_capacity_isdefaulted) unless @cooling_capacity.nil?
      XMLHelper.add_element(cooling_system, 'CompressorType', @compressor_type, :string, @compressor_type_isdefaulted) unless @compressor_type.nil?
      XMLHelper.add_element(cooling_system, 'FractionCoolLoadServed', @fraction_cool_load_served, :float, @fraction_cool_load_served_isdefaulted) unless @fraction_cool_load_served.nil?
      if not @cooling_efficiency_seer.nil?
        annual_efficiency = XMLHelper.add_element(cooling_system, 'AnnualCoolingEfficiency')
        XMLHelper.add_element(annual_efficiency, 'Units', UnitsSEER, :string)
        XMLHelper.add_element(annual_efficiency, 'Value', @cooling_efficiency_seer, :float, @cooling_efficiency_seer_isdefaulted)
      end
      if not @cooling_efficiency_seer2.nil?
        annual_efficiency = XMLHelper.add_element(cooling_system, 'AnnualCoolingEfficiency')
        XMLHelper.add_element(annual_efficiency, 'Units', UnitsSEER2, :string)
        XMLHelper.add_element(annual_efficiency, 'Value', @cooling_efficiency_seer2, :float, @cooling_efficiency_seer2_isdefaulted)
      end
      if not @cooling_efficiency_eer.nil?
        annual_efficiency = XMLHelper.add_element(cooling_system, 'AnnualCoolingEfficiency')
        XMLHelper.add_element(annual_efficiency, 'Units', UnitsEER, :string)
        XMLHelper.add_element(annual_efficiency, 'Value', @cooling_efficiency_eer, :float, @cooling_efficiency_eer_isdefaulted)
      end
      if not @cooling_efficiency_ceer.nil?
        annual_efficiency = XMLHelper.add_element(cooling_system, 'AnnualCoolingEfficiency')
        XMLHelper.add_element(annual_efficiency, 'Units', UnitsCEER, :string)
        XMLHelper.add_element(annual_efficiency, 'Value', @cooling_efficiency_ceer, :float, @cooling_efficiency_ceer_isdefaulted)
      end
      if not @cooling_efficiency_kw_per_ton.nil?
        annual_efficiency = XMLHelper.add_element(cooling_system, 'AnnualCoolingEfficiency')
        XMLHelper.add_element(annual_efficiency, 'Units', UnitsKwPerTon, :string)
        XMLHelper.add_element(annual_efficiency, 'Value', @cooling_efficiency_kw_per_ton, :float, @cooling_efficiency_kw_per_ton_isdefaulted)
      end
      XMLHelper.add_element(cooling_system, 'SensibleHeatFraction', @cooling_shr, :float, @cooling_shr_isdefaulted) unless @cooling_shr.nil?
      @cooling_detailed_performance_data.to_doc(cooling_system)
      XMLHelper.add_element(cooling_system, 'IntegratedHeatingSystemFuel', @integrated_heating_system_fuel, :string) unless @integrated_heating_system_fuel.nil?
      XMLHelper.add_element(cooling_system, 'IntegratedHeatingSystemCapacity', @integrated_heating_system_capacity, :float, @integrated_heating_system_capacity_isdefaulted) unless @integrated_heating_system_capacity.nil?
      if not @integrated_heating_system_efficiency_percent.nil?
        annual_efficiency = XMLHelper.add_element(cooling_system, 'IntegratedHeatingSystemAnnualEfficiency')
        XMLHelper.add_element(annual_efficiency, 'Units', UnitsPercent, :string)
        XMLHelper.add_element(annual_efficiency, 'Value', @integrated_heating_system_efficiency_percent, :float, @integrated_heating_system_efficiency_percent_isdefaulted)
      end
      XMLHelper.add_element(cooling_system, 'IntegratedHeatingSystemFractionHeatLoadServed', @integrated_heating_system_fraction_heat_load_served, :float) unless @integrated_heating_system_fraction_heat_load_served.nil?
      XMLHelper.add_extension(cooling_system, 'AirflowDefectRatio', @airflow_defect_ratio, :float, @airflow_defect_ratio_isdefaulted) unless @airflow_defect_ratio.nil?
      XMLHelper.add_extension(cooling_system, 'ChargeDefectRatio', @charge_defect_ratio, :float, @charge_defect_ratio_isdefaulted) unless @charge_defect_ratio.nil?
      XMLHelper.add_extension(cooling_system, 'FanPowerWattsPerCFM', @fan_watts_per_cfm, :float, @fan_watts_per_cfm_isdefaulted) unless @fan_watts_per_cfm.nil?
      XMLHelper.add_extension(cooling_system, 'CoolingAirflowCFM', @cooling_airflow_cfm, :float, @cooling_airflow_cfm_isdefaulted) unless @cooling_airflow_cfm.nil?
      XMLHelper.add_extension(cooling_system, 'HeatingAirflowCFM', @integrated_heating_system_airflow_cfm, :float, @integrated_heating_system_airflow_cfm_isdefaulted) unless @integrated_heating_system_airflow_cfm.nil?
      XMLHelper.add_extension(cooling_system, 'SharedLoopWatts', @shared_loop_watts, :float) unless @shared_loop_watts.nil?
      XMLHelper.add_extension(cooling_system, 'SharedLoopMotorEfficiency', @shared_loop_motor_efficiency, :float) unless @shared_loop_motor_efficiency.nil?
      XMLHelper.add_extension(cooling_system, 'FanCoilWatts', @fan_coil_watts, :float) unless @fan_coil_watts.nil?
      XMLHelper.add_extension(cooling_system, 'CrankcaseHeaterPowerWatts', @crankcase_heater_watts, :float, @crankcase_heater_watts_isdefaulted) unless @crankcase_heater_watts.nil?
      XMLHelper.add_extension(cooling_system, 'CoolingSeedId', @clg_seed_id, :string) unless @clg_seed_id.nil?
      XMLHelper.add_extension(cooling_system, 'HeatingSeedId', @htg_seed_id, :string) unless @htg_seed_id.nil?
      if @primary_system
        primary_cooling_system = XMLHelper.add_element(primary_systems, 'PrimaryCoolingSystem')
        XMLHelper.add_attribute(primary_cooling_system, 'idref', @id)
      end
    end

    def from_doc(cooling_system)
      return if cooling_system.nil?

      @id = HPXML::get_id(cooling_system)
      @location = XMLHelper.get_value(cooling_system, 'UnitLocation', :string)
      @year_installed = XMLHelper.get_value(cooling_system, 'YearInstalled', :integer)
      @third_party_certification = XMLHelper.get_value(cooling_system, 'ThirdPartyCertification', :string)
      @distribution_system_idref = HPXML::get_idref(XMLHelper.get_element(cooling_system, 'DistributionSystem'))
      @is_shared_system = XMLHelper.get_value(cooling_system, 'IsSharedSystem', :boolean)
      @number_of_units_served = XMLHelper.get_value(cooling_system, 'NumberofUnitsServed', :integer)
      @cooling_system_type = XMLHelper.get_value(cooling_system, 'CoolingSystemType', :string)
      @cooling_system_fuel = XMLHelper.get_value(cooling_system, 'CoolingSystemFuel', :string)
      @cooling_capacity = XMLHelper.get_value(cooling_system, 'CoolingCapacity', :float)
      @compressor_type = XMLHelper.get_value(cooling_system, 'CompressorType', :string)
      @fraction_cool_load_served = XMLHelper.get_value(cooling_system, 'FractionCoolLoadServed', :float)
      @cooling_efficiency_seer = XMLHelper.get_value(cooling_system, "AnnualCoolingEfficiency[Units='#{UnitsSEER}']/Value", :float)
      @cooling_efficiency_seer2 = XMLHelper.get_value(cooling_system, "AnnualCoolingEfficiency[Units='#{UnitsSEER2}']/Value", :float)
      @cooling_efficiency_eer = XMLHelper.get_value(cooling_system, "AnnualCoolingEfficiency[Units='#{UnitsEER}']/Value", :float)
      @cooling_efficiency_ceer = XMLHelper.get_value(cooling_system, "AnnualCoolingEfficiency[Units='#{UnitsCEER}']/Value", :float)
      @cooling_efficiency_kw_per_ton = XMLHelper.get_value(cooling_system, "AnnualCoolingEfficiency[Units='#{UnitsKwPerTon}']/Value", :float)
      @cooling_detailed_performance_data.from_doc(cooling_system)
      @cooling_shr = XMLHelper.get_value(cooling_system, 'SensibleHeatFraction', :float)
      @integrated_heating_system_fuel = XMLHelper.get_value(cooling_system, 'IntegratedHeatingSystemFuel', :string)
      @integrated_heating_system_capacity = XMLHelper.get_value(cooling_system, 'IntegratedHeatingSystemCapacity', :float)
      @integrated_heating_system_efficiency_percent = XMLHelper.get_value(cooling_system, "IntegratedHeatingSystemAnnualEfficiency[Units='#{UnitsPercent}']/Value", :float)
      @integrated_heating_system_fraction_heat_load_served = XMLHelper.get_value(cooling_system, 'IntegratedHeatingSystemFractionHeatLoadServed', :float)
      @airflow_defect_ratio = XMLHelper.get_value(cooling_system, 'extension/AirflowDefectRatio', :float)
      @charge_defect_ratio = XMLHelper.get_value(cooling_system, 'extension/ChargeDefectRatio', :float)
      @fan_watts_per_cfm = XMLHelper.get_value(cooling_system, 'extension/FanPowerWattsPerCFM', :float)
      @cooling_airflow_cfm = XMLHelper.get_value(cooling_system, 'extension/CoolingAirflowCFM', :float)
      @integrated_heating_system_airflow_cfm = XMLHelper.get_value(cooling_system, 'extension/HeatingAirflowCFM', :float)
      @shared_loop_watts = XMLHelper.get_value(cooling_system, 'extension/SharedLoopWatts', :float)
      @shared_loop_motor_efficiency = XMLHelper.get_value(cooling_system, 'extension/SharedLoopMotorEfficiency', :float)
      @fan_coil_watts = XMLHelper.get_value(cooling_system, 'extension/FanCoilWatts', :float)
      @crankcase_heater_watts = XMLHelper.get_value(cooling_system, 'extension/CrankcaseHeaterPowerWatts', :float)
      @clg_seed_id = XMLHelper.get_value(cooling_system, 'extension/CoolingSeedId', :string)
      @htg_seed_id = XMLHelper.get_value(cooling_system, 'extension/HeatingSeedId', :string)
      primary_cooling_system = HPXML::get_idref(XMLHelper.get_element(cooling_system, '../PrimarySystems/PrimaryCoolingSystem'))
      if primary_cooling_system == @id
        @primary_system = true
      else
        @primary_system = false
      end
    end
  end

  class GeothermalLoops < BaseArrayElement
    def add(**kwargs)
      self << GeothermalLoop.new(@parent_object, **kwargs)
    end

    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/Systems/HVAC/HVACPlant/GeothermalLoop').each do |geothermal_loop|
        self << GeothermalLoop.new(@parent_object, geothermal_loop)
      end
    end
  end

  class GeothermalLoop < BaseElement
    ATTRS = [:id, :loop_configuration, :loop_flow, :bore_config, :num_bore_holes, :bore_spacing,
             :bore_length, :bore_diameter, :grout_type, :grout_conductivity, :pipe_type,
             :pipe_conductivity, :pipe_diameter, :shank_spacing]
    attr_accessor(*ATTRS)

    def heat_pump
      list = []
      @parent_object.heat_pumps.each do |heat_pump|
        next if heat_pump.geothermal_loop_idref.nil?
        next unless heat_pump.geothermal_loop_idref == @id

        list << heat_pump
      end

      if list.size == 0
        fail "Geothermal loop '#{@id}' found but no heat pump attached to it."
      elsif list.size > 1
        fail "Multiple heat pumps found attached to geothermal loop '#{@id}'."
      end
    end

    def delete
      @parent_object.geothermal_loops.delete(self)
      @parent_object.heat_pumps.each do |heat_pump|
        next unless heat_pump.geothermal_loop_idref == @id

        heat_pump.geothermal_loop_idref = nil
      end
    end

    def check_for_errors
      errors = []
      begin; heat_pump; rescue StandardError => e; errors << e.message; end
      return errors
    end

    def to_doc(building)
      return if nil?

      hvac_plant = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Systems', 'HVAC', 'HVACPlant'])
      geothermal_loop = XMLHelper.add_element(hvac_plant, 'GeothermalLoop')
      sys_id = XMLHelper.add_element(geothermal_loop, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_element(geothermal_loop, 'LoopConfiguration', @loop_configuration, :string, @loop_configuration_isdefaulted) unless @loop_configuration.nil?
      XMLHelper.add_element(geothermal_loop, 'LoopFlow', @loop_flow, :float, @loop_flow_isdefaulted) unless @loop_flow.nil?
      if (not @num_bore_holes.nil?) || (not @bore_spacing.nil?) || (not @bore_length.nil?) || (not @bore_diameter.nil?)
        boreholes_or_trenches = XMLHelper.add_element(geothermal_loop, 'BoreholesOrTrenches')
        XMLHelper.add_element(boreholes_or_trenches, 'Count', @num_bore_holes, :integer, @num_bore_holes_isdefaulted) unless @num_bore_holes.nil?
        XMLHelper.add_element(boreholes_or_trenches, 'Length', @bore_length, :float, @bore_length_isdefaulted) unless @bore_length.nil?
        XMLHelper.add_element(boreholes_or_trenches, 'Spacing', @bore_spacing, :float, @bore_spacing_isdefaulted) unless @bore_spacing.nil?
        XMLHelper.add_element(boreholes_or_trenches, 'Diameter', @bore_diameter, :float, @bore_diameter_isdefaulted) unless @bore_diameter.nil?
      end
      if (not @grout_type.nil?) || (not @grout_conductivity.nil?)
        grout = XMLHelper.add_element(geothermal_loop, 'Grout')
        XMLHelper.add_element(grout, 'Type', @grout_type, :string, @grout_type_isdefaulted) unless @grout_type.nil?
        XMLHelper.add_element(grout, 'Conductivity', @grout_conductivity, :float, @grout_conductivity_isdefaulted) unless @grout_conductivity.nil?
      end
      if (not @pipe_type.nil?) || (not @pipe_conductivity.nil?) || (not @pipe_diameter.nil?) || (not @shank_spacing.nil?)
        pipe = XMLHelper.add_element(geothermal_loop, 'Pipe')
        XMLHelper.add_element(pipe, 'Type', @pipe_type, :string, @pipe_type_isdefaulted) unless @pipe_type.nil?
        XMLHelper.add_element(pipe, 'Conductivity', @pipe_conductivity, :float, @pipe_conductivity_isdefaulted) unless @pipe_conductivity.nil?
        XMLHelper.add_element(pipe, 'Diameter', @pipe_diameter, :float, @pipe_diameter_isdefaulted) unless @pipe_diameter.nil?
        XMLHelper.add_element(pipe, 'ShankSpacing', @shank_spacing, :float, @shank_spacing_isdefaulted) unless @shank_spacing.nil?
      end
      if not @bore_config.nil?
        extension = XMLHelper.create_elements_as_needed(geothermal_loop, ['extension'])
        XMLHelper.add_element(extension, 'BorefieldConfiguration', @bore_config, :string, @bore_config_isdefaulted) unless @bore_config.nil?
      end
    end

    def from_doc(geothermal_loop)
      return if geothermal_loop.nil?

      @id = HPXML::get_id(geothermal_loop)
      @loop_configuration = XMLHelper.get_value(geothermal_loop, 'LoopConfiguration', :string)
      @loop_flow = XMLHelper.get_value(geothermal_loop, 'LoopFlow', :float)
      @num_bore_holes = XMLHelper.get_value(geothermal_loop, 'BoreholesOrTrenches/Count', :integer)
      @bore_length = XMLHelper.get_value(geothermal_loop, 'BoreholesOrTrenches/Length', :float)
      @bore_spacing = XMLHelper.get_value(geothermal_loop, 'BoreholesOrTrenches/Spacing', :float)
      @bore_diameter = XMLHelper.get_value(geothermal_loop, 'BoreholesOrTrenches/Diameter', :float)
      @grout_type = XMLHelper.get_value(geothermal_loop, 'Grout/Type', :string)
      @grout_conductivity = XMLHelper.get_value(geothermal_loop, 'Grout/Conductivity', :float)
      @pipe_type = XMLHelper.get_value(geothermal_loop, 'Pipe/Type', :string)
      @pipe_conductivity = XMLHelper.get_value(geothermal_loop, 'Pipe/Conductivity', :float)
      @pipe_diameter = XMLHelper.get_value(geothermal_loop, 'Pipe/Diameter', :float)
      @shank_spacing = XMLHelper.get_value(geothermal_loop, 'Pipe/ShankSpacing', :float)
      @bore_config = XMLHelper.get_value(geothermal_loop, 'extension/BorefieldConfiguration', :string)
    end
  end

  class HeatPumps < BaseArrayElement
    def add(**kwargs)
      self << HeatPump.new(@parent_object, **kwargs)
    end

    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/Systems/HVAC/HVACPlant/HeatPump').each do |heat_pump|
        self << HeatPump.new(@parent_object, heat_pump)
      end
    end

    def total_fraction_heat_load_served
      map { |hp| hp.fraction_heat_load_served.to_f }.sum(0.0)
    end

    def total_fraction_cool_load_served
      map { |hp| hp.fraction_cool_load_served.to_f }.sum(0.0)
    end
  end

  class HeatPump < BaseElement
    def initialize(hpxml_object, *args)
      @cooling_detailed_performance_data = CoolingDetailedPerformanceData.new(hpxml_object)
      @heating_detailed_performance_data = HeatingDetailedPerformanceData.new(hpxml_object)
      super(hpxml_object, *args)
    end
    ATTRS = [:id, :distribution_system_idref, :year_installed, :heat_pump_type, :heat_pump_fuel,
             :heating_capacity, :heating_capacity_17F, :cooling_capacity, :compressor_type, :compressor_lockout_temp,
             :cooling_shr, :backup_type, :backup_system_idref, :backup_heating_fuel, :backup_heating_capacity,
             :backup_heating_efficiency_percent, :backup_heating_efficiency_afue, :backup_heating_lockout_temp,
             :backup_heating_switchover_temp, :fraction_heat_load_served, :fraction_cool_load_served, :cooling_efficiency_seer,
             :cooling_efficiency_seer2, :cooling_efficiency_eer, :cooling_efficiency_ceer, :heating_efficiency_hspf,
             :heating_efficiency_hspf2, :heating_efficiency_cop, :third_party_certification, :htg_seed_id, :clg_seed_id,
             :pump_watts_per_ton, :fan_watts_per_cfm, :is_shared_system, :number_of_units_served, :shared_loop_watts,
             :shared_loop_motor_efficiency, :airflow_defect_ratio, :charge_defect_ratio,
             :heating_airflow_cfm, :cooling_airflow_cfm, :location, :primary_heating_system, :primary_cooling_system,
             :heating_capacity_retention_fraction, :heating_capacity_retention_temp, :crankcase_heater_watts,
             :geothermal_loop_idref]
    attr_accessor(*ATTRS)
    attr_reader(:cooling_detailed_performance_data)
    attr_reader(:heating_detailed_performance_data)

    def distribution_system
      return if @distribution_system_idref.nil?

      @parent_object.hvac_distributions.each do |hvac_distribution|
        next unless hvac_distribution.id == @distribution_system_idref

        return hvac_distribution
      end
      fail "Attached HVAC distribution system '#{@distribution_system_idref}' not found for HVAC system '#{@id}'."
    end

    def geothermal_loop
      return if @geothermal_loop_idref.nil?

      @parent_object.geothermal_loops.each do |geothermal_loop|
        next unless geothermal_loop.id == @geothermal_loop_idref

        return geothermal_loop
      end
      fail "Attached geothermal loop '#{@geothermal_loop_idref}' not found for heat pump '#{@id}'."
    end

    def is_dual_fuel
      if backup_system.nil?
        if @backup_heating_fuel.nil?
          return false
        end
        if @backup_heating_fuel.to_s == @heat_pump_fuel.to_s
          return false
        end
      else
        if backup_system.heating_system_fuel.to_s == @heat_pump_fuel.to_s
          return false
        end
      end

      return true
    end

    def primary_system
      return true if @primary_heating_system || @primary_cooling_system

      return false
    end

    def backup_system
      return if @backup_system_idref.nil?

      @parent_object.heating_systems.each do |heating_system|
        next unless heating_system.id == @backup_system_idref

        return heating_system
      end
    end

    def delete
      @parent_object.heat_pumps.delete(self)
      @parent_object.water_heating_systems.each do |water_heating_system|
        next unless water_heating_system.related_hvac_idref == @id

        water_heating_system.related_hvac_idref = nil
      end
    end

    def check_for_errors
      errors = []
      begin; distribution_system; rescue StandardError => e; errors << e.message; end
      begin; geothermal_loop; rescue StandardError => e; errors << e.message; end
      errors += @cooling_detailed_performance_data.check_for_errors
      errors += @heating_detailed_performance_data.check_for_errors
      return errors
    end

    def to_doc(building)
      return if nil?

      hvac_plant = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Systems', 'HVAC', 'HVACPlant'])
      primary_systems = XMLHelper.create_elements_as_needed(hvac_plant, ['PrimarySystems']) unless @parent_object.primary_hvac_systems.empty?
      heat_pump = XMLHelper.add_element(hvac_plant, 'HeatPump')
      sys_id = XMLHelper.add_element(heat_pump, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_element(heat_pump, 'UnitLocation', @location, :string, @location_isdefaulted) unless @location.nil?
      XMLHelper.add_element(heat_pump, 'YearInstalled', @year_installed, :integer) unless @year_installed.nil?
      XMLHelper.add_element(heat_pump, 'ThirdPartyCertification', @third_party_certification, :string) unless @third_party_certification.nil?
      if not @distribution_system_idref.nil?
        distribution_system = XMLHelper.add_element(heat_pump, 'DistributionSystem')
        XMLHelper.add_attribute(distribution_system, 'idref', @distribution_system_idref)
      end
      XMLHelper.add_element(heat_pump, 'IsSharedSystem', @is_shared_system, :boolean) unless @is_shared_system.nil?
      XMLHelper.add_element(heat_pump, 'NumberofUnitsServed', @number_of_units_served, :integer) unless @number_of_units_served.nil?
      XMLHelper.add_element(heat_pump, 'HeatPumpType', @heat_pump_type, :string) unless @heat_pump_type.nil?
      XMLHelper.add_element(heat_pump, 'HeatPumpFuel', @heat_pump_fuel, :string) unless @heat_pump_fuel.nil?
      XMLHelper.add_element(heat_pump, 'HeatingCapacity', @heating_capacity, :float, @heating_capacity_isdefaulted) unless @heating_capacity.nil?
      XMLHelper.add_element(heat_pump, 'HeatingCapacity17F', @heating_capacity_17F, :float) unless @heating_capacity_17F.nil?
      XMLHelper.add_element(heat_pump, 'CoolingCapacity', @cooling_capacity, :float, @cooling_capacity_isdefaulted) unless @cooling_capacity.nil?
      XMLHelper.add_element(heat_pump, 'CompressorType', @compressor_type, :string, @compressor_type_isdefaulted) unless @compressor_type.nil?
      XMLHelper.add_element(heat_pump, 'CompressorLockoutTemperature', @compressor_lockout_temp, :float, @compressor_lockout_temp_isdefaulted) unless @compressor_lockout_temp.nil?
      XMLHelper.add_element(heat_pump, 'CoolingSensibleHeatFraction', @cooling_shr, :float, @cooling_shr_isdefaulted) unless @cooling_shr.nil?
      XMLHelper.add_element(heat_pump, 'BackupType', @backup_type, :string, @backup_type_isdefaulted) unless @backup_type.nil?
      if not @backup_system_idref.nil?
        backup_system = XMLHelper.add_element(heat_pump, 'BackupSystem')
        XMLHelper.add_attribute(backup_system, 'idref', @backup_system_idref)
      end
      XMLHelper.add_element(heat_pump, 'BackupSystemFuel', @backup_heating_fuel, :string, @backup_heating_fuel_isdefaulted) unless @backup_heating_fuel.nil?
      if not @backup_heating_efficiency_percent.nil?
        backup_eff = XMLHelper.add_element(heat_pump, 'BackupAnnualHeatingEfficiency')
        XMLHelper.add_element(backup_eff, 'Units', UnitsPercent, :string)
        XMLHelper.add_element(backup_eff, 'Value', @backup_heating_efficiency_percent, :float)
      end
      if not @backup_heating_efficiency_afue.nil?
        backup_eff = XMLHelper.add_element(heat_pump, 'BackupAnnualHeatingEfficiency')
        XMLHelper.add_element(backup_eff, 'Units', UnitsAFUE, :string)
        XMLHelper.add_element(backup_eff, 'Value', @backup_heating_efficiency_afue, :float)
      end
      XMLHelper.add_element(heat_pump, 'BackupHeatingCapacity', @backup_heating_capacity, :float, @backup_heating_capacity_isdefaulted) unless @backup_heating_capacity.nil?
      XMLHelper.add_element(heat_pump, 'BackupHeatingSwitchoverTemperature', @backup_heating_switchover_temp, :float, @backup_heating_switchover_temp_isdefaulted) unless @backup_heating_switchover_temp.nil?
      XMLHelper.add_element(heat_pump, 'BackupHeatingLockoutTemperature', @backup_heating_lockout_temp, :float, @backup_heating_lockout_temp_isdefaulted) unless @backup_heating_lockout_temp.nil?
      XMLHelper.add_element(heat_pump, 'FractionHeatLoadServed', @fraction_heat_load_served, :float, @fraction_heat_load_served_isdefaulted) unless @fraction_heat_load_served.nil?
      XMLHelper.add_element(heat_pump, 'FractionCoolLoadServed', @fraction_cool_load_served, :float, @fraction_cool_load_served_isdefaulted) unless @fraction_cool_load_served.nil?
      if not @cooling_efficiency_seer.nil?
        annual_efficiency = XMLHelper.add_element(heat_pump, 'AnnualCoolingEfficiency')
        XMLHelper.add_element(annual_efficiency, 'Units', UnitsSEER, :string)
        XMLHelper.add_element(annual_efficiency, 'Value', @cooling_efficiency_seer, :float, @cooling_efficiency_seer_isdefaulted)
      end
      if not @cooling_efficiency_seer2.nil?
        annual_efficiency = XMLHelper.add_element(heat_pump, 'AnnualCoolingEfficiency')
        XMLHelper.add_element(annual_efficiency, 'Units', UnitsSEER2, :string)
        XMLHelper.add_element(annual_efficiency, 'Value', @cooling_efficiency_seer2, :float, @cooling_efficiency_seer2_isdefaulted)
      end
      if not @cooling_efficiency_ceer.nil?
        annual_efficiency = XMLHelper.add_element(heat_pump, 'AnnualCoolingEfficiency')
        XMLHelper.add_element(annual_efficiency, 'Units', UnitsCEER, :string)
        XMLHelper.add_element(annual_efficiency, 'Value', @cooling_efficiency_ceer, :float, @cooling_efficiency_ceer_isdefaulted)
      end
      if not @cooling_efficiency_eer.nil?
        annual_efficiency = XMLHelper.add_element(heat_pump, 'AnnualCoolingEfficiency')
        XMLHelper.add_element(annual_efficiency, 'Units', UnitsEER, :string)
        XMLHelper.add_element(annual_efficiency, 'Value', @cooling_efficiency_eer, :float, @cooling_efficiency_eer_isdefaulted)
      end
      if not @heating_efficiency_hspf.nil?
        annual_efficiency = XMLHelper.add_element(heat_pump, 'AnnualHeatingEfficiency')
        XMLHelper.add_element(annual_efficiency, 'Units', UnitsHSPF, :string)
        XMLHelper.add_element(annual_efficiency, 'Value', @heating_efficiency_hspf, :float, @heating_efficiency_hspf_isdefaulted)
      end
      if not @heating_efficiency_hspf2.nil?
        annual_efficiency = XMLHelper.add_element(heat_pump, 'AnnualHeatingEfficiency')
        XMLHelper.add_element(annual_efficiency, 'Units', UnitsHSPF2, :string)
        XMLHelper.add_element(annual_efficiency, 'Value', @heating_efficiency_hspf2, :float, @heating_efficiency_hspf2_isdefaulted)
      end
      if not @heating_efficiency_cop.nil?
        annual_efficiency = XMLHelper.add_element(heat_pump, 'AnnualHeatingEfficiency')
        XMLHelper.add_element(annual_efficiency, 'Units', UnitsCOP, :string)
        XMLHelper.add_element(annual_efficiency, 'Value', @heating_efficiency_cop, :float, @heating_efficiency_cop_isdefaulted)
      end
      if not @geothermal_loop_idref.nil?
        attached_to_geothermal_loop = XMLHelper.add_element(heat_pump, 'AttachedToGeothermalLoop')
        XMLHelper.add_attribute(attached_to_geothermal_loop, 'idref', @geothermal_loop_idref)
      end
      @cooling_detailed_performance_data.to_doc(heat_pump)
      @heating_detailed_performance_data.to_doc(heat_pump)
      XMLHelper.add_extension(heat_pump, 'AirflowDefectRatio', @airflow_defect_ratio, :float, @airflow_defect_ratio_isdefaulted) unless @airflow_defect_ratio.nil?
      XMLHelper.add_extension(heat_pump, 'ChargeDefectRatio', @charge_defect_ratio, :float, @charge_defect_ratio_isdefaulted) unless @charge_defect_ratio.nil?
      XMLHelper.add_extension(heat_pump, 'FanPowerWattsPerCFM', @fan_watts_per_cfm, :float, @fan_watts_per_cfm_isdefaulted) unless @fan_watts_per_cfm.nil?
      XMLHelper.add_extension(heat_pump, 'HeatingAirflowCFM', @heating_airflow_cfm, :float, @heating_airflow_cfm_isdefaulted) unless @heating_airflow_cfm.nil?
      XMLHelper.add_extension(heat_pump, 'CoolingAirflowCFM', @cooling_airflow_cfm, :float, @cooling_airflow_cfm_isdefaulted) unless @cooling_airflow_cfm.nil?
      XMLHelper.add_extension(heat_pump, 'PumpPowerWattsPerTon', @pump_watts_per_ton, :float, @pump_watts_per_ton_isdefaulted) unless @pump_watts_per_ton.nil?
      XMLHelper.add_extension(heat_pump, 'SharedLoopWatts', @shared_loop_watts, :float) unless @shared_loop_watts.nil?
      XMLHelper.add_extension(heat_pump, 'SharedLoopMotorEfficiency', @shared_loop_motor_efficiency, :float) unless @shared_loop_motor_efficiency.nil?
      if (not @heating_capacity_retention_fraction.nil?) || (not @heating_capacity_retention_temp.nil?)
        htg_cap_retention = XMLHelper.add_extension(heat_pump, 'HeatingCapacityRetention')
        XMLHelper.add_element(htg_cap_retention, 'Fraction', @heating_capacity_retention_fraction, :float, @heating_capacity_retention_fraction_isdefaulted) unless @heating_capacity_retention_fraction.nil?
        XMLHelper.add_element(htg_cap_retention, 'Temperature', @heating_capacity_retention_temp, :float, @heating_capacity_retention_temp_isdefaulted) unless @heating_capacity_retention_temp.nil?
      end
      XMLHelper.add_extension(heat_pump, 'CrankcaseHeaterPowerWatts', @crankcase_heater_watts, :float, @crankcase_heater_watts_isdefaulted) unless @crankcase_heater_watts.nil?
      XMLHelper.add_extension(heat_pump, 'HeatingSeedId', @htg_seed_id, :string) unless @htg_seed_id.nil?
      XMLHelper.add_extension(heat_pump, 'CoolingSeedId', @clg_seed_id, :string) unless @clg_seed_id.nil?
      if @primary_heating_system
        primary_heating_system = XMLHelper.insert_element(primary_systems, 'PrimaryHeatingSystem')
        XMLHelper.add_attribute(primary_heating_system, 'idref', @id)
      end
      if @primary_cooling_system
        primary_cooling_system = XMLHelper.add_element(primary_systems, 'PrimaryCoolingSystem')
        XMLHelper.add_attribute(primary_cooling_system, 'idref', @id)
      end
    end

    def from_doc(heat_pump)
      return if heat_pump.nil?

      @id = HPXML::get_id(heat_pump)
      @location = XMLHelper.get_value(heat_pump, 'UnitLocation', :string)
      @year_installed = XMLHelper.get_value(heat_pump, 'YearInstalled', :integer)
      @third_party_certification = XMLHelper.get_value(heat_pump, 'ThirdPartyCertification', :string)
      @distribution_system_idref = HPXML::get_idref(XMLHelper.get_element(heat_pump, 'DistributionSystem'))
      @is_shared_system = XMLHelper.get_value(heat_pump, 'IsSharedSystem', :boolean)
      @number_of_units_served = XMLHelper.get_value(heat_pump, 'NumberofUnitsServed', :integer)
      @heat_pump_type = XMLHelper.get_value(heat_pump, 'HeatPumpType', :string)
      @heat_pump_fuel = XMLHelper.get_value(heat_pump, 'HeatPumpFuel', :string)
      @heating_capacity = XMLHelper.get_value(heat_pump, 'HeatingCapacity', :float)
      @heating_capacity_17F = XMLHelper.get_value(heat_pump, 'HeatingCapacity17F', :float)
      @cooling_capacity = XMLHelper.get_value(heat_pump, 'CoolingCapacity', :float)
      @compressor_type = XMLHelper.get_value(heat_pump, 'CompressorType', :string)
      @compressor_lockout_temp = XMLHelper.get_value(heat_pump, 'CompressorLockoutTemperature', :float)
      @cooling_shr = XMLHelper.get_value(heat_pump, 'CoolingSensibleHeatFraction', :float)
      @backup_type = XMLHelper.get_value(heat_pump, 'BackupType', :string)
      @backup_system_idref = HPXML::get_idref(XMLHelper.get_element(heat_pump, 'BackupSystem'))
      @backup_heating_fuel = XMLHelper.get_value(heat_pump, 'BackupSystemFuel', :string)
      @backup_heating_efficiency_percent = XMLHelper.get_value(heat_pump, "BackupAnnualHeatingEfficiency[Units='Percent']/Value", :float)
      @backup_heating_efficiency_afue = XMLHelper.get_value(heat_pump, "BackupAnnualHeatingEfficiency[Units='#{UnitsAFUE}']/Value", :float)
      @backup_heating_capacity = XMLHelper.get_value(heat_pump, 'BackupHeatingCapacity', :float)
      @backup_heating_switchover_temp = XMLHelper.get_value(heat_pump, 'BackupHeatingSwitchoverTemperature', :float)
      @backup_heating_lockout_temp = XMLHelper.get_value(heat_pump, 'BackupHeatingLockoutTemperature', :float)
      @fraction_heat_load_served = XMLHelper.get_value(heat_pump, 'FractionHeatLoadServed', :float)
      @fraction_cool_load_served = XMLHelper.get_value(heat_pump, 'FractionCoolLoadServed', :float)
      @cooling_efficiency_seer = XMLHelper.get_value(heat_pump, "AnnualCoolingEfficiency[Units='#{UnitsSEER}']/Value", :float)
      @cooling_efficiency_seer2 = XMLHelper.get_value(heat_pump, "AnnualCoolingEfficiency[Units='#{UnitsSEER2}']/Value", :float)
      @cooling_efficiency_ceer = XMLHelper.get_value(heat_pump, "AnnualCoolingEfficiency[Units='#{UnitsCEER}']/Value", :float)
      @cooling_efficiency_eer = XMLHelper.get_value(heat_pump, "AnnualCoolingEfficiency[Units='#{UnitsEER}']/Value", :float)
      @heating_efficiency_hspf = XMLHelper.get_value(heat_pump, "AnnualHeatingEfficiency[Units='#{UnitsHSPF}']/Value", :float)
      @heating_efficiency_hspf2 = XMLHelper.get_value(heat_pump, "AnnualHeatingEfficiency[Units='#{UnitsHSPF2}']/Value", :float)
      @heating_efficiency_cop = XMLHelper.get_value(heat_pump, "AnnualHeatingEfficiency[Units='#{UnitsCOP}']/Value", :float)
      @geothermal_loop_idref = HPXML::get_idref(XMLHelper.get_element(heat_pump, 'AttachedToGeothermalLoop'))
      @cooling_detailed_performance_data.from_doc(heat_pump)
      @heating_detailed_performance_data.from_doc(heat_pump)
      @airflow_defect_ratio = XMLHelper.get_value(heat_pump, 'extension/AirflowDefectRatio', :float)
      @charge_defect_ratio = XMLHelper.get_value(heat_pump, 'extension/ChargeDefectRatio', :float)
      @fan_watts_per_cfm = XMLHelper.get_value(heat_pump, 'extension/FanPowerWattsPerCFM', :float)
      @heating_airflow_cfm = XMLHelper.get_value(heat_pump, 'extension/HeatingAirflowCFM', :float)
      @cooling_airflow_cfm = XMLHelper.get_value(heat_pump, 'extension/CoolingAirflowCFM', :float)
      @pump_watts_per_ton = XMLHelper.get_value(heat_pump, 'extension/PumpPowerWattsPerTon', :float)
      @shared_loop_watts = XMLHelper.get_value(heat_pump, 'extension/SharedLoopWatts', :float)
      @shared_loop_motor_efficiency = XMLHelper.get_value(heat_pump, 'extension/SharedLoopMotorEfficiency', :float)
      @heating_capacity_retention_fraction = XMLHelper.get_value(heat_pump, 'extension/HeatingCapacityRetention/Fraction', :float)
      @heating_capacity_retention_temp = XMLHelper.get_value(heat_pump, 'extension/HeatingCapacityRetention/Temperature', :float)
      @crankcase_heater_watts = XMLHelper.get_value(heat_pump, 'extension/CrankcaseHeaterPowerWatts', :float)
      @htg_seed_id = XMLHelper.get_value(heat_pump, 'extension/HeatingSeedId', :string)
      @clg_seed_id = XMLHelper.get_value(heat_pump, 'extension/CoolingSeedId', :string)
      primary_heating_system = HPXML::get_idref(XMLHelper.get_element(heat_pump, '../PrimarySystems/PrimaryHeatingSystem'))
      if primary_heating_system == @id
        @primary_heating_system = true
      else
        @primary_heating_system = false
      end
      primary_cooling_system = HPXML::get_idref(XMLHelper.get_element(heat_pump, '../PrimarySystems/PrimaryCoolingSystem'))
      if primary_cooling_system == @id
        @primary_cooling_system = true
      else
        @primary_cooling_system = false
      end
    end
  end

  class HVACPlant < BaseElement
    HDL_ATTRS = { hdl_total: 'Total',
                  hdl_ducts: 'Ducts',
                  hdl_windows: 'Windows',
                  hdl_skylights: 'Skylights',
                  hdl_doors: 'Doors',
                  hdl_walls: 'Walls',
                  hdl_roofs: 'Roofs',
                  hdl_floors: 'Floors',
                  hdl_slabs: 'Slabs',
                  hdl_ceilings: 'Ceilings',
                  hdl_infilvent: 'InfilVent' }
    CDL_SENS_ATTRS = { cdl_sens_total: 'Total',
                       cdl_sens_ducts: 'Ducts',
                       cdl_sens_windows: 'Windows',
                       cdl_sens_skylights: 'Skylights',
                       cdl_sens_doors: 'Doors',
                       cdl_sens_walls: 'Walls',
                       cdl_sens_roofs: 'Roofs',
                       cdl_sens_floors: 'Floors',
                       cdl_sens_slabs: 'Slabs',
                       cdl_sens_ceilings: 'Ceilings',
                       cdl_sens_infilvent: 'InfilVent',
                       cdl_sens_intgains: 'InternalLoads' }
    CDL_LAT_ATTRS = { cdl_lat_total: 'Total',
                      cdl_lat_ducts: 'Ducts',
                      cdl_lat_infilvent: 'InfilVent',
                      cdl_lat_intgains: 'InternalLoads' }
    ATTRS = HDL_ATTRS.keys + CDL_SENS_ATTRS.keys + CDL_LAT_ATTRS.keys
    attr_accessor(*ATTRS)

    def check_for_errors
      errors = []
      return errors
    end

    def to_doc(building)
      return if nil?

      hvac_plant = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Systems', 'HVAC', 'HVACPlant'])
      if not @hdl_total.nil?
        dl_extension = XMLHelper.create_elements_as_needed(hvac_plant, ['extension', 'DesignLoads'])
        XMLHelper.add_attribute(dl_extension, 'dataSource', 'software')
        hdl = XMLHelper.add_element(dl_extension, 'Heating')
        HDL_ATTRS.each do |attr, element_name|
          XMLHelper.add_element(hdl, element_name, send(attr), :float)
        end
        cdl_sens = XMLHelper.add_element(dl_extension, 'CoolingSensible')
        CDL_SENS_ATTRS.each do |attr, element_name|
          XMLHelper.add_element(cdl_sens, element_name, send(attr), :float)
        end
        cdl_lat = XMLHelper.add_element(dl_extension, 'CoolingLatent')
        CDL_LAT_ATTRS.each do |attr, element_name|
          XMLHelper.add_element(cdl_lat, element_name, send(attr), :float)
        end
      end
    end

    def from_doc(building)
      return if building.nil?

      hvac_plant = XMLHelper.get_element(building, 'BuildingDetails/Systems/HVAC/HVACPlant')
      return if hvac_plant.nil?

      HDL_ATTRS.each do |attr, element_name|
        send("#{attr}=", XMLHelper.get_value(hvac_plant, "extension/DesignLoads/Heating/#{element_name}", :float))
      end
      CDL_SENS_ATTRS.each do |attr, element_name|
        send("#{attr}=", XMLHelper.get_value(hvac_plant, "extension/DesignLoads/CoolingSensible/#{element_name}", :float))
      end
      CDL_LAT_ATTRS.each do |attr, element_name|
        send("#{attr}=", XMLHelper.get_value(hvac_plant, "extension/DesignLoads/CoolingLatent/#{element_name}", :float))
      end
    end
  end

  class HVACControls < BaseArrayElement
    def add(**kwargs)
      self << HVACControl.new(@parent_object, **kwargs)
    end

    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/Systems/HVAC/HVACControl').each do |hvac_control|
        self << HVACControl.new(@parent_object, hvac_control)
      end
    end
  end

  class HVACControl < BaseElement
    ATTRS = [:id, :control_type, :heating_setpoint_temp, :heating_setback_temp,
             :heating_setback_hours_per_week, :heating_setback_start_hour, :cooling_setpoint_temp,
             :cooling_setup_temp, :cooling_setup_hours_per_week, :cooling_setup_start_hour,
             :ceiling_fan_cooling_setpoint_temp_offset,
             :weekday_heating_setpoints, :weekend_heating_setpoints,
             :weekday_cooling_setpoints, :weekend_cooling_setpoints,
             :seasons_heating_begin_month, :seasons_heating_begin_day, :seasons_heating_end_month, :seasons_heating_end_day,
             :seasons_cooling_begin_month, :seasons_cooling_begin_day, :seasons_cooling_end_month, :seasons_cooling_end_day]
    attr_accessor(*ATTRS)

    def delete
      @parent_object.hvac_controls.delete(self)
    end

    def check_for_errors
      errors = []

      errors += HPXML::check_dates('Heating Season', @seasons_heating_begin_month, @seasons_heating_begin_day, @seasons_heating_end_month, @seasons_heating_end_day)
      errors += HPXML::check_dates('Cooling Season', @seasons_cooling_begin_month, @seasons_cooling_begin_day, @seasons_cooling_end_month, @seasons_cooling_end_day)

      return errors
    end

    def to_doc(building)
      return if nil?

      hvac = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Systems', 'HVAC'])
      hvac_control = XMLHelper.add_element(hvac, 'HVACControl')
      sys_id = XMLHelper.add_element(hvac_control, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_element(hvac_control, 'ControlType', @control_type, :string) unless @control_type.nil?
      XMLHelper.add_element(hvac_control, 'SetpointTempHeatingSeason', @heating_setpoint_temp, :float, @heating_setpoint_temp_isdefaulted) unless @heating_setpoint_temp.nil?
      XMLHelper.add_element(hvac_control, 'SetbackTempHeatingSeason', @heating_setback_temp, :float) unless @heating_setback_temp.nil?
      XMLHelper.add_element(hvac_control, 'TotalSetbackHoursperWeekHeating', @heating_setback_hours_per_week, :integer) unless @heating_setback_hours_per_week.nil?
      XMLHelper.add_element(hvac_control, 'SetupTempCoolingSeason', @cooling_setup_temp, :float) unless @cooling_setup_temp.nil?
      XMLHelper.add_element(hvac_control, 'SetpointTempCoolingSeason', @cooling_setpoint_temp, :float, @cooling_setpoint_temp_isdefaulted) unless @cooling_setpoint_temp.nil?
      XMLHelper.add_element(hvac_control, 'TotalSetupHoursperWeekCooling', @cooling_setup_hours_per_week, :integer) unless @cooling_setup_hours_per_week.nil?
      if (not @seasons_heating_begin_month.nil?) || (not @seasons_heating_begin_day.nil?) || (not @seasons_heating_end_month.nil?) || (not @seasons_heating_end_day.nil?)
        heating_season = XMLHelper.add_element(hvac_control, 'HeatingSeason')
        XMLHelper.add_element(heating_season, 'BeginMonth', @seasons_heating_begin_month, :integer, @seasons_heating_begin_month_isdefaulted) unless @seasons_heating_begin_month.nil?
        XMLHelper.add_element(heating_season, 'BeginDayOfMonth', @seasons_heating_begin_day, :integer, @seasons_heating_begin_day_isdefaulted) unless @seasons_heating_begin_day.nil?
        XMLHelper.add_element(heating_season, 'EndMonth', @seasons_heating_end_month, :integer, @seasons_heating_end_month_isdefaulted) unless @seasons_heating_end_month.nil?
        XMLHelper.add_element(heating_season, 'EndDayOfMonth', @seasons_heating_end_day, :integer, @seasons_heating_end_day_isdefaulted) unless @seasons_heating_end_day.nil?
      end
      if (not @seasons_cooling_begin_month.nil?) || (not @seasons_cooling_begin_day.nil?) || (not @seasons_cooling_end_month.nil?) || (not @seasons_cooling_end_day.nil?)
        cooling_season = XMLHelper.add_element(hvac_control, 'CoolingSeason')
        XMLHelper.add_element(cooling_season, 'BeginMonth', @seasons_cooling_begin_month, :integer, @seasons_cooling_begin_month_isdefaulted) unless @seasons_cooling_begin_month.nil?
        XMLHelper.add_element(cooling_season, 'BeginDayOfMonth', @seasons_cooling_begin_day, :integer, @seasons_cooling_begin_day_isdefaulted) unless @seasons_cooling_begin_day.nil?
        XMLHelper.add_element(cooling_season, 'EndMonth', @seasons_cooling_end_month, :integer, @seasons_cooling_end_month_isdefaulted) unless @seasons_cooling_end_month.nil?
        XMLHelper.add_element(cooling_season, 'EndDayOfMonth', @seasons_cooling_end_day, :integer, @seasons_cooling_end_day_isdefaulted) unless @seasons_cooling_end_day.nil?
      end
      XMLHelper.add_extension(hvac_control, 'SetbackStartHourHeating', @heating_setback_start_hour, :integer, @heating_setback_start_hour_isdefaulted) unless @heating_setback_start_hour.nil?
      XMLHelper.add_extension(hvac_control, 'SetupStartHourCooling', @cooling_setup_start_hour, :integer, @cooling_setup_start_hour_isdefaulted) unless @cooling_setup_start_hour.nil?
      XMLHelper.add_extension(hvac_control, 'CeilingFanSetpointTempCoolingSeasonOffset', @ceiling_fan_cooling_setpoint_temp_offset, :float) unless @ceiling_fan_cooling_setpoint_temp_offset.nil?
      XMLHelper.add_extension(hvac_control, 'WeekdaySetpointTempsHeatingSeason', @weekday_heating_setpoints, :string) unless @weekday_heating_setpoints.nil?
      XMLHelper.add_extension(hvac_control, 'WeekendSetpointTempsHeatingSeason', @weekend_heating_setpoints, :string) unless @weekend_heating_setpoints.nil?
      XMLHelper.add_extension(hvac_control, 'WeekdaySetpointTempsCoolingSeason', @weekday_cooling_setpoints, :string) unless @weekday_cooling_setpoints.nil?
      XMLHelper.add_extension(hvac_control, 'WeekendSetpointTempsCoolingSeason', @weekend_cooling_setpoints, :string) unless @weekend_cooling_setpoints.nil?
    end

    def from_doc(hvac_control)
      return if hvac_control.nil?

      @id = HPXML::get_id(hvac_control)
      @control_type = XMLHelper.get_value(hvac_control, 'ControlType', :string)
      @heating_setpoint_temp = XMLHelper.get_value(hvac_control, 'SetpointTempHeatingSeason', :float)
      @heating_setback_temp = XMLHelper.get_value(hvac_control, 'SetbackTempHeatingSeason', :float)
      @heating_setback_hours_per_week = XMLHelper.get_value(hvac_control, 'TotalSetbackHoursperWeekHeating', :integer)
      @cooling_setup_temp = XMLHelper.get_value(hvac_control, 'SetupTempCoolingSeason', :float)
      @cooling_setpoint_temp = XMLHelper.get_value(hvac_control, 'SetpointTempCoolingSeason', :float)
      @cooling_setup_hours_per_week = XMLHelper.get_value(hvac_control, 'TotalSetupHoursperWeekCooling', :integer)
      @seasons_heating_begin_month = XMLHelper.get_value(hvac_control, 'HeatingSeason/BeginMonth', :integer)
      @seasons_heating_begin_day = XMLHelper.get_value(hvac_control, 'HeatingSeason/BeginDayOfMonth', :integer)
      @seasons_heating_end_month = XMLHelper.get_value(hvac_control, 'HeatingSeason/EndMonth', :integer)
      @seasons_heating_end_day = XMLHelper.get_value(hvac_control, 'HeatingSeason/EndDayOfMonth', :integer)
      @seasons_cooling_begin_month = XMLHelper.get_value(hvac_control, 'CoolingSeason/BeginMonth', :integer)
      @seasons_cooling_begin_day = XMLHelper.get_value(hvac_control, 'CoolingSeason/BeginDayOfMonth', :integer)
      @seasons_cooling_end_month = XMLHelper.get_value(hvac_control, 'CoolingSeason/EndMonth', :integer)
      @seasons_cooling_end_day = XMLHelper.get_value(hvac_control, 'CoolingSeason/EndDayOfMonth', :integer)
      @heating_setback_start_hour = XMLHelper.get_value(hvac_control, 'extension/SetbackStartHourHeating', :integer)
      @cooling_setup_start_hour = XMLHelper.get_value(hvac_control, 'extension/SetupStartHourCooling', :integer)
      @ceiling_fan_cooling_setpoint_temp_offset = XMLHelper.get_value(hvac_control, 'extension/CeilingFanSetpointTempCoolingSeasonOffset', :float)
      @weekday_heating_setpoints = XMLHelper.get_value(hvac_control, 'extension/WeekdaySetpointTempsHeatingSeason', :string)
      @weekend_heating_setpoints = XMLHelper.get_value(hvac_control, 'extension/WeekendSetpointTempsHeatingSeason', :string)
      @weekday_cooling_setpoints = XMLHelper.get_value(hvac_control, 'extension/WeekdaySetpointTempsCoolingSeason', :string)
      @weekend_cooling_setpoints = XMLHelper.get_value(hvac_control, 'extension/WeekendSetpointTempsCoolingSeason', :string)
    end
  end

  class HVACDistributions < BaseArrayElement
    def add(**kwargs)
      self << HVACDistribution.new(@parent_object, **kwargs)
    end

    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/Systems/HVAC/HVACDistribution').each do |hvac_distribution|
        self << HVACDistribution.new(@parent_object, hvac_distribution)
      end
    end
  end

  class HVACDistribution < BaseElement
    def initialize(hpxml_bldg, *args)
      @duct_leakage_measurements = DuctLeakageMeasurements.new(hpxml_bldg)
      @ducts = Ducts.new(hpxml_bldg)
      super(hpxml_bldg, *args)
    end
    ATTRS = [:id, :distribution_system_type, :annual_heating_dse, :annual_cooling_dse, :duct_system_sealed,
             :conditioned_floor_area_served, :number_of_return_registers, :air_type, :hydronic_type]
    attr_accessor(*ATTRS)
    attr_reader(:duct_leakage_measurements, :ducts)

    def hvac_systems
      list = []
      @parent_object.hvac_systems.each do |hvac_system|
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
          num_htg += 1 if obj.fraction_heat_load_served.to_f > 0
        end
        if obj.respond_to? :fraction_cool_load_served
          num_clg += 1 if obj.fraction_cool_load_served.to_f > 0
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
      @parent_object.hvac_distributions.delete(self)
      @parent_object.hvac_systems.each do |hvac_system|
        next if hvac_system.distribution_system_idref.nil?
        next unless hvac_system.distribution_system_idref == @id

        hvac_system.distribution_system_idref = nil
      end
      @parent_object.ventilation_fans.each do |ventilation_fan|
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

    def to_doc(building)
      return if nil?

      hvac = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Systems', 'HVAC'])
      hvac_distribution = XMLHelper.add_element(hvac, 'HVACDistribution')
      sys_id = XMLHelper.add_element(hvac_distribution, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      distribution_system_type_el = XMLHelper.add_element(hvac_distribution, 'DistributionSystemType')
      if [HVACDistributionTypeAir, HVACDistributionTypeHydronic].include? @distribution_system_type
        XMLHelper.add_element(distribution_system_type_el, @distribution_system_type)
        XMLHelper.add_element(hvac_distribution, 'ConditionedFloorAreaServed', @conditioned_floor_area_served, :float) unless @conditioned_floor_area_served.nil?
      elsif [HVACDistributionTypeDSE].include? @distribution_system_type
        XMLHelper.add_element(distribution_system_type_el, 'Other', @distribution_system_type, :string)
        XMLHelper.add_element(hvac_distribution, 'AnnualHeatingDistributionSystemEfficiency', @annual_heating_dse, :float) unless @annual_heating_dse.nil?
        XMLHelper.add_element(hvac_distribution, 'AnnualCoolingDistributionSystemEfficiency', @annual_cooling_dse, :float) unless @annual_cooling_dse.nil?
      else
        fail "Unexpected distribution_system_type '#{@distribution_system_type}'."
      end

      if [HPXML::HVACDistributionTypeHydronic].include? @distribution_system_type
        distribution = XMLHelper.get_element(hvac_distribution, 'DistributionSystemType/HydronicDistribution')
        XMLHelper.add_element(distribution, 'HydronicDistributionType', @hydronic_type, :string) unless @hydronic_type.nil?
      end
      if [HPXML::HVACDistributionTypeAir].include? @distribution_system_type
        distribution = XMLHelper.get_element(hvac_distribution, 'DistributionSystemType/AirDistribution')
        XMLHelper.add_element(distribution, 'AirDistributionType', @air_type, :string) unless @air_type.nil?
        @duct_leakage_measurements.to_doc(distribution)
        @ducts.to_doc(distribution)
        XMLHelper.add_element(distribution, 'NumberofReturnRegisters', @number_of_return_registers, :integer, @number_of_return_registers_isdefaulted) unless @number_of_return_registers.nil?
      end

      if not @duct_system_sealed.nil?
        dist_impr_el = XMLHelper.add_element(hvac_distribution, 'HVACDistributionImprovement')
        XMLHelper.add_element(dist_impr_el, 'DuctSystemSealed', @duct_system_sealed, :boolean)
      end
    end

    def from_doc(hvac_distribution)
      return if hvac_distribution.nil?

      @id = HPXML::get_id(hvac_distribution)
      @distribution_system_type = XMLHelper.get_child_name(hvac_distribution, 'DistributionSystemType')
      if @distribution_system_type == 'Other'
        @distribution_system_type = XMLHelper.get_value(XMLHelper.get_element(hvac_distribution, 'DistributionSystemType'), 'Other', :string)
      end
      @annual_heating_dse = XMLHelper.get_value(hvac_distribution, 'AnnualHeatingDistributionSystemEfficiency', :float)
      @annual_cooling_dse = XMLHelper.get_value(hvac_distribution, 'AnnualCoolingDistributionSystemEfficiency', :float)
      @duct_system_sealed = XMLHelper.get_value(hvac_distribution, 'HVACDistributionImprovement/DuctSystemSealed', :boolean)
      @conditioned_floor_area_served = XMLHelper.get_value(hvac_distribution, 'ConditionedFloorAreaServed', :float)

      air_distribution = XMLHelper.get_element(hvac_distribution, 'DistributionSystemType/AirDistribution')
      hydronic_distribution = XMLHelper.get_element(hvac_distribution, 'DistributionSystemType/HydronicDistribution')

      if not hydronic_distribution.nil?
        @hydronic_type = XMLHelper.get_value(hydronic_distribution, 'HydronicDistributionType', :string)
      end
      if not air_distribution.nil?
        @air_type = XMLHelper.get_value(air_distribution, 'AirDistributionType', :string)
        @number_of_return_registers = XMLHelper.get_value(air_distribution, 'NumberofReturnRegisters', :integer)
        @duct_leakage_measurements.from_doc(air_distribution)
        @ducts.from_doc(air_distribution)
      end
    end
  end

  class DuctLeakageMeasurements < BaseArrayElement
    def add(**kwargs)
      self << DuctLeakageMeasurement.new(@parent_object, **kwargs)
    end

    def from_doc(hvac_distribution)
      return if hvac_distribution.nil?

      XMLHelper.get_elements(hvac_distribution, 'DuctLeakageMeasurement').each do |duct_leakage_measurement|
        self << DuctLeakageMeasurement.new(@parent_object, duct_leakage_measurement)
      end
    end
  end

  class DuctLeakageMeasurement < BaseElement
    ATTRS = [:duct_type, :duct_leakage_test_method, :duct_leakage_units, :duct_leakage_value,
             :duct_leakage_total_or_to_outside]
    attr_accessor(*ATTRS)

    def delete
      @parent_object.hvac_distributions.each do |hvac_distribution|
        next unless hvac_distribution.duct_leakage_measurements.include? self

        hvac_distribution.duct_leakage_measurements.delete(self)
      end
    end

    def check_for_errors
      errors = []
      return errors
    end

    def to_doc(air_distribution)
      duct_leakage_measurement_el = XMLHelper.add_element(air_distribution, 'DuctLeakageMeasurement')
      XMLHelper.add_element(duct_leakage_measurement_el, 'DuctType', @duct_type, :string) unless @duct_type.nil?
      XMLHelper.add_element(duct_leakage_measurement_el, 'DuctLeakageTestMethod', @duct_leakage_test_method, :string) unless @duct_leakage_test_method.nil?
      if not @duct_leakage_value.nil?
        duct_leakage_el = XMLHelper.add_element(duct_leakage_measurement_el, 'DuctLeakage')
        XMLHelper.add_element(duct_leakage_el, 'Units', @duct_leakage_units, :string) unless @duct_leakage_units.nil?
        XMLHelper.add_element(duct_leakage_el, 'Value', @duct_leakage_value, :float)
        XMLHelper.add_element(duct_leakage_el, 'TotalOrToOutside', @duct_leakage_total_or_to_outside, :string) unless @duct_leakage_total_or_to_outside.nil?
      end
    end

    def from_doc(duct_leakage_measurement)
      return if duct_leakage_measurement.nil?

      @duct_type = XMLHelper.get_value(duct_leakage_measurement, 'DuctType', :string)
      @duct_leakage_test_method = XMLHelper.get_value(duct_leakage_measurement, 'DuctLeakageTestMethod', :string)
      @duct_leakage_units = XMLHelper.get_value(duct_leakage_measurement, 'DuctLeakage/Units', :string)
      @duct_leakage_value = XMLHelper.get_value(duct_leakage_measurement, 'DuctLeakage/Value', :float)
      @duct_leakage_total_or_to_outside = XMLHelper.get_value(duct_leakage_measurement, 'DuctLeakage/TotalOrToOutside', :string)
    end
  end

  class Ducts < BaseArrayElement
    def add(**kwargs)
      self << Duct.new(@parent_object, **kwargs)
    end

    def from_doc(hvac_distribution)
      return if hvac_distribution.nil?

      XMLHelper.get_elements(hvac_distribution, 'Ducts').each do |duct|
        self << Duct.new(@parent_object, duct)
      end
    end
  end

  class Duct < BaseElement
    ATTRS = [:id, :duct_type, :duct_insulation_r_value, :duct_insulation_material, :duct_location,
             :duct_fraction_area, :duct_surface_area, :duct_surface_area_multiplier,
             :duct_buried_insulation_level, :duct_effective_r_value]
    attr_accessor(*ATTRS)

    def delete
      @parent_object.hvac_distributions.each do |hvac_distribution|
        next unless hvac_distribution.ducts.include? self

        hvac_distribution.ducts.delete(self)
      end
    end

    def check_for_errors
      errors = []
      return errors
    end

    def to_doc(air_distribution)
      ducts_el = XMLHelper.add_element(air_distribution, 'Ducts')
      sys_id = XMLHelper.add_element(ducts_el, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_element(ducts_el, 'DuctType', @duct_type, :string) unless @duct_type.nil?
      if not @duct_insulation_material.nil?
        ins_material_el = XMLHelper.add_element(ducts_el, 'DuctInsulationMaterial')
        XMLHelper.add_element(ins_material_el, @duct_insulation_material)
      end
      XMLHelper.add_element(ducts_el, 'DuctInsulationRValue', @duct_insulation_r_value, :float) unless @duct_insulation_r_value.nil?
      XMLHelper.add_element(ducts_el, 'DuctBuriedInsulationLevel', @duct_buried_insulation_level, :string, @duct_buried_insulation_level_isdefaulted) unless @duct_buried_insulation_level.nil?
      XMLHelper.add_element(ducts_el, 'DuctEffectiveRValue', @duct_effective_r_value, :float, @duct_effective_r_value_isdefaulted) unless @duct_effective_r_value.nil?
      XMLHelper.add_element(ducts_el, 'DuctLocation', @duct_location, :string, @duct_location_isdefaulted) unless @duct_location.nil?
      XMLHelper.add_element(ducts_el, 'FractionDuctArea', @duct_fraction_area, :float, @duct_fraction_area_isdefaulted) unless @duct_fraction_area.nil?
      XMLHelper.add_element(ducts_el, 'DuctSurfaceArea', @duct_surface_area, :float, @duct_surface_area_isdefaulted) unless @duct_surface_area.nil?
      XMLHelper.add_extension(ducts_el, 'DuctSurfaceAreaMultiplier', @duct_surface_area_multiplier, :float, @duct_surface_area_multiplier_isdefaulted) unless @duct_surface_area_multiplier.nil?
    end

    def from_doc(duct)
      return if duct.nil?

      @id = HPXML::get_id(duct)
      @duct_type = XMLHelper.get_value(duct, 'DuctType', :string)
      @duct_insulation_material = XMLHelper.get_child_name(duct, 'DuctInsulationMaterial')
      @duct_insulation_r_value = XMLHelper.get_value(duct, 'DuctInsulationRValue', :float)
      @duct_buried_insulation_level = XMLHelper.get_value(duct, 'DuctBuriedInsulationLevel', :string)
      @duct_effective_r_value = XMLHelper.get_value(duct, 'DuctEffectiveRValue', :float)
      @duct_location = XMLHelper.get_value(duct, 'DuctLocation', :string)
      @duct_fraction_area = XMLHelper.get_value(duct, 'FractionDuctArea', :float)
      @duct_surface_area = XMLHelper.get_value(duct, 'DuctSurfaceArea', :float)
      @duct_surface_area_multiplier = XMLHelper.get_value(duct, 'extension/DuctSurfaceAreaMultiplier', :float)
    end
  end

  class VentilationFans < BaseArrayElement
    def add(**kwargs)
      self << VentilationFan.new(@parent_object, **kwargs)
    end

    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/Systems/MechanicalVentilation/VentilationFans/VentilationFan').each do |ventilation_fan|
        self << VentilationFan.new(@parent_object, ventilation_fan)
      end
    end
  end

  class VentilationFan < BaseElement
    ATTRS = [:id, :fan_type, :rated_flow_rate, :tested_flow_rate, :hours_in_operation, :flow_rate_not_tested,
             :used_for_whole_building_ventilation, :used_for_seasonal_cooling_load_reduction,
             :used_for_local_ventilation, :total_recovery_efficiency, :total_recovery_efficiency_adjusted,
             :sensible_recovery_efficiency, :sensible_recovery_efficiency_adjusted,
             :fan_power, :fan_power_defaulted, :count, :fan_location, :distribution_system_idref, :start_hour,
             :is_shared_system, :in_unit_flow_rate, :fraction_recirculation, :used_for_garage_ventilation,
             :preheating_fuel, :preheating_efficiency_cop, :preheating_fraction_load_served, :precooling_fuel,
             :precooling_efficiency_cop, :precooling_fraction_load_served, :calculated_flow_rate,
             :delivered_ventilation, :cfis_vent_mode_airflow_fraction, :cfis_addtl_runtime_operating_mode,
             :cfis_supplemental_fan_idref]
    attr_accessor(*ATTRS)

    def distribution_system
      return if @distribution_system_idref.nil?
      return unless @fan_type == MechVentTypeCFIS

      @parent_object.hvac_distributions.each do |hvac_distribution|
        next unless hvac_distribution.id == @distribution_system_idref

        if hvac_distribution.distribution_system_type == HVACDistributionTypeHydronic
          fail "Attached HVAC distribution system '#{@distribution_system_idref}' cannot be hydronic for ventilation fan '#{@id}'."
        end

        return hvac_distribution
      end
      fail "Attached HVAC distribution system '#{@distribution_system_idref}' not found for ventilation fan '#{@id}'."
    end

    def flow_rate
      [@tested_flow_rate, @delivered_ventilation, @calculated_flow_rate, @rated_flow_rate].each do |fr|
        return fr unless fr.nil?
      end
      return
    end

    def total_unit_flow_rate
      if not @is_shared_system
        return flow_rate
      else
        return @in_unit_flow_rate
      end
    end

    def oa_unit_flow_rate
      return if total_unit_flow_rate.nil?
      if not @is_shared_system
        return total_unit_flow_rate
      else
        if @fan_type == HPXML::MechVentTypeExhaust && @fraction_recirculation > 0.0
          fail "Exhaust fan '#{@id}' must have the fraction recirculation set to zero."
        else
          return total_unit_flow_rate * (1 - @fraction_recirculation)
        end
      end
    end

    def average_oa_unit_flow_rate
      # Daily-average outdoor air (cfm) associated with the unit
      return if oa_unit_flow_rate.nil?
      return if @hours_in_operation.nil?

      return oa_unit_flow_rate * (@hours_in_operation / 24.0)
    end

    def average_total_unit_flow_rate
      # Daily-average total air (cfm) associated with the unit
      return if total_unit_flow_rate.nil?
      return if @hours_in_operation.nil?

      return total_unit_flow_rate * (@hours_in_operation / 24.0)
    end

    def unit_flow_rate_ratio
      return 1.0 unless @is_shared_system
      return if @in_unit_flow_rate.nil?

      if not flow_rate.nil?
        ratio = @in_unit_flow_rate / flow_rate
      end
      return ratio
    end

    def unit_fan_power
      return if @fan_power.nil?

      if @is_shared_system
        return if unit_flow_rate_ratio.nil?

        return @fan_power * unit_flow_rate_ratio
      else
        return @fan_power
      end
    end

    def average_unit_fan_power
      return if unit_fan_power.nil?
      return if @hours_in_operation.nil?

      return unit_fan_power * (@hours_in_operation / 24.0)
    end

    def includes_supply_air?
      if [MechVentTypeSupply, MechVentTypeCFIS, MechVentTypeBalanced, MechVentTypeERV, MechVentTypeHRV].include? @fan_type
        return true
      end

      return false
    end

    def includes_exhaust_air?
      if [MechVentTypeExhaust, MechVentTypeBalanced, MechVentTypeERV, MechVentTypeHRV].include? @fan_type
        return true
      end

      return false
    end

    def is_balanced?
      if includes_supply_air? && includes_exhaust_air?
        return true
      end

      return false
    end

    def cfis_supplemental_fan
      return if @cfis_supplemental_fan_idref.nil?
      return unless @fan_type == MechVentTypeCFIS

      @parent_object.ventilation_fans.each do |ventilation_fan|
        next unless ventilation_fan.id == @cfis_supplemental_fan_idref

        if not [MechVentTypeSupply, MechVentTypeExhaust].include? ventilation_fan.fan_type
          fail "CFIS supplemental fan '#{ventilation_fan.id}' must be of type '#{MechVentTypeSupply}' or '#{MechVentTypeExhaust}'."
        end
        if not ventilation_fan.used_for_whole_building_ventilation
          fail "CFIS supplemental fan '#{ventilation_fan.id}' must be set as used for whole building ventilation."
        end
        if ventilation_fan.is_shared_system
          fail "CFIS supplemental fan '#{ventilation_fan.id}' cannot be a shared system."
        end
        if not ventilation_fan.hours_in_operation.nil?
          fail "CFIS supplemental fan '#{ventilation_fan.id}' cannot have HoursInOperation specified."
        end

        return ventilation_fan
      end
      fail "CFIS Supplemental Fan '#{@cfis_supplemental_fan_idref}' not found for ventilation fan '#{@id}'."
    end

    def is_cfis_supplemental_fan?
      @parent_object.ventilation_fans.each do |ventilation_fan|
        next unless ventilation_fan.fan_type == MechVentTypeCFIS
        next unless ventilation_fan.cfis_supplemental_fan_idref == @id

        return true
      end
      return false
    end

    def delete
      @parent_object.ventilation_fans.delete(self)
    end

    def check_for_errors
      errors = []
      begin; distribution_system; rescue StandardError => e; errors << e.message; end
      begin; oa_unit_flow_rate; rescue StandardError => e; errors << e.message; end
      begin; unit_flow_rate_ratio; rescue StandardError => e; errors << e.message; end
      begin; cfis_supplemental_fan; rescue StandardError => e; errors << e.message; end
      return errors
    end

    def to_doc(building)
      return if nil?

      ventilation_fans = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Systems', 'MechanicalVentilation', 'VentilationFans'])
      ventilation_fan = XMLHelper.add_element(ventilation_fans, 'VentilationFan')
      sys_id = XMLHelper.add_element(ventilation_fan, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_element(ventilation_fan, 'Count', @count, :integer, @count_isdefaulted) unless @count.nil?
      XMLHelper.add_element(ventilation_fan, 'FanType', @fan_type, :string) unless @fan_type.nil?
      if (not @cfis_addtl_runtime_operating_mode.nil?) || (not @cfis_supplemental_fan_idref.nil?)
        cfis_controls = XMLHelper.add_element(ventilation_fan, 'CFISControls')
        XMLHelper.add_element(cfis_controls, 'AdditionalRuntimeOperatingMode', @cfis_addtl_runtime_operating_mode, :string, @cfis_addtl_runtime_operating_mode_isdefaulted) unless @cfis_addtl_runtime_operating_mode.nil?
        if not @cfis_supplemental_fan_idref.nil?
          supplemental_fan = XMLHelper.add_element(cfis_controls, 'SupplementalFan')
          XMLHelper.add_attribute(supplemental_fan, 'idref', @cfis_supplemental_fan_idref)
        end
      end
      XMLHelper.add_element(ventilation_fan, 'RatedFlowRate', @rated_flow_rate, :float, @rated_flow_rate_isdefaulted) unless @rated_flow_rate.nil?
      XMLHelper.add_element(ventilation_fan, 'CalculatedFlowRate', @calculated_flow_rate, :float, @calculated_flow_rate_isdefaulted) unless @calculated_flow_rate.nil?
      XMLHelper.add_element(ventilation_fan, 'TestedFlowRate', @tested_flow_rate, :float, @tested_flow_rate_isdefaulted) unless @tested_flow_rate.nil?
      XMLHelper.add_element(ventilation_fan, 'HoursInOperation', @hours_in_operation, :float, @hours_in_operation_isdefaulted) unless @hours_in_operation.nil?
      XMLHelper.add_element(ventilation_fan, 'DeliveredVentilation', @delivered_ventilation, :float, @delivered_ventilation_isdefaulted) unless @delivered_ventilation.nil?
      XMLHelper.add_element(ventilation_fan, 'FanLocation', @fan_location, :string) unless @fan_location.nil?
      XMLHelper.add_element(ventilation_fan, 'UsedForLocalVentilation', @used_for_local_ventilation, :boolean) unless @used_for_local_ventilation.nil?
      XMLHelper.add_element(ventilation_fan, 'UsedForWholeBuildingVentilation', @used_for_whole_building_ventilation, :boolean) unless @used_for_whole_building_ventilation.nil?
      XMLHelper.add_element(ventilation_fan, 'UsedForSeasonalCoolingLoadReduction', @used_for_seasonal_cooling_load_reduction, :boolean) unless @used_for_seasonal_cooling_load_reduction.nil?
      XMLHelper.add_element(ventilation_fan, 'UsedForGarageVentilation', @used_for_garage_ventilation, :boolean) unless @used_for_garage_ventilation.nil?
      XMLHelper.add_element(ventilation_fan, 'IsSharedSystem', @is_shared_system, :boolean, @is_shared_system_isdefaulted) unless @is_shared_system.nil?
      XMLHelper.add_element(ventilation_fan, 'FractionRecirculation', @fraction_recirculation, :float) unless @fraction_recirculation.nil?
      XMLHelper.add_element(ventilation_fan, 'TotalRecoveryEfficiency', @total_recovery_efficiency, :float) unless @total_recovery_efficiency.nil?
      XMLHelper.add_element(ventilation_fan, 'SensibleRecoveryEfficiency', @sensible_recovery_efficiency, :float) unless @sensible_recovery_efficiency.nil?
      XMLHelper.add_element(ventilation_fan, 'AdjustedTotalRecoveryEfficiency', @total_recovery_efficiency_adjusted, :float) unless @total_recovery_efficiency_adjusted.nil?
      XMLHelper.add_element(ventilation_fan, 'AdjustedSensibleRecoveryEfficiency', @sensible_recovery_efficiency_adjusted, :float) unless @sensible_recovery_efficiency_adjusted.nil?
      XMLHelper.add_element(ventilation_fan, 'FanPower', @fan_power, :float, @fan_power_isdefaulted) unless @fan_power.nil?
      if not @distribution_system_idref.nil?
        attached_to_hvac_distribution_system = XMLHelper.add_element(ventilation_fan, 'AttachedToHVACDistributionSystem')
        XMLHelper.add_attribute(attached_to_hvac_distribution_system, 'idref', @distribution_system_idref)
      end
      XMLHelper.add_extension(ventilation_fan, 'StartHour', @start_hour, :integer, @start_hour_isdefaulted) unless @start_hour.nil?
      XMLHelper.add_extension(ventilation_fan, 'InUnitFlowRate', @in_unit_flow_rate, :float) unless @in_unit_flow_rate.nil?
      if (not @preheating_fuel.nil?) && (not @preheating_efficiency_cop.nil?)
        precond_htg = XMLHelper.create_elements_as_needed(ventilation_fan, ['extension', 'PreHeating'])
        XMLHelper.add_element(precond_htg, 'Fuel', @preheating_fuel, :string) unless @preheating_fuel.nil?
        eff = XMLHelper.add_element(precond_htg, 'AnnualHeatingEfficiency') unless @preheating_efficiency_cop.nil?
        XMLHelper.add_element(eff, 'Value', @preheating_efficiency_cop, :float) unless eff.nil?
        XMLHelper.add_element(eff, 'Units', UnitsCOP, :string) unless eff.nil?
        XMLHelper.add_element(precond_htg, 'FractionVentilationHeatLoadServed', @preheating_fraction_load_served, :float) unless @preheating_fraction_load_served.nil?
      end
      if (not @precooling_fuel.nil?) && (not @precooling_efficiency_cop.nil?)
        precond_clg = XMLHelper.create_elements_as_needed(ventilation_fan, ['extension', 'PreCooling'])
        XMLHelper.add_element(precond_clg, 'Fuel', @precooling_fuel, :string) unless @precooling_fuel.nil?
        eff = XMLHelper.add_element(precond_clg, 'AnnualCoolingEfficiency') unless @precooling_efficiency_cop.nil?
        XMLHelper.add_element(eff, 'Value', @precooling_efficiency_cop, :float) unless eff.nil?
        XMLHelper.add_element(eff, 'Units', UnitsCOP, :string) unless eff.nil?
        XMLHelper.add_element(precond_clg, 'FractionVentilationCoolLoadServed', @precooling_fraction_load_served, :float) unless @precooling_fraction_load_served.nil?
      end
      XMLHelper.add_extension(ventilation_fan, 'FlowRateNotTested', @flow_rate_not_tested, :boolean) unless @flow_rate_not_tested.nil?
      XMLHelper.add_extension(ventilation_fan, 'FanPowerDefaulted', @fan_power_defaulted, :boolean) unless @fan_power_defaulted.nil?
      XMLHelper.add_extension(ventilation_fan, 'VentilationOnlyModeAirflowFraction', @cfis_vent_mode_airflow_fraction, :float, @cfis_vent_mode_airflow_fraction_isdefaulted) unless @cfis_vent_mode_airflow_fraction.nil?
    end

    def from_doc(ventilation_fan)
      return if ventilation_fan.nil?

      @id = HPXML::get_id(ventilation_fan)
      @count = XMLHelper.get_value(ventilation_fan, 'Count', :integer)
      @fan_type = XMLHelper.get_value(ventilation_fan, 'FanType', :string)
      @rated_flow_rate = XMLHelper.get_value(ventilation_fan, 'RatedFlowRate', :float)
      @calculated_flow_rate = XMLHelper.get_value(ventilation_fan, 'CalculatedFlowRate', :float)
      @tested_flow_rate = XMLHelper.get_value(ventilation_fan, 'TestedFlowRate', :float)
      @hours_in_operation = XMLHelper.get_value(ventilation_fan, 'HoursInOperation', :float)
      @delivered_ventilation = XMLHelper.get_value(ventilation_fan, 'DeliveredVentilation', :float)
      @fan_location = XMLHelper.get_value(ventilation_fan, 'FanLocation', :string)
      @used_for_local_ventilation = XMLHelper.get_value(ventilation_fan, 'UsedForLocalVentilation', :boolean)
      @used_for_whole_building_ventilation = XMLHelper.get_value(ventilation_fan, 'UsedForWholeBuildingVentilation', :boolean)
      @used_for_seasonal_cooling_load_reduction = XMLHelper.get_value(ventilation_fan, 'UsedForSeasonalCoolingLoadReduction', :boolean)
      @used_for_garage_ventilation = XMLHelper.get_value(ventilation_fan, 'UsedForGarageVentilation', :boolean)
      @is_shared_system = XMLHelper.get_value(ventilation_fan, 'IsSharedSystem', :boolean)
      @fraction_recirculation = XMLHelper.get_value(ventilation_fan, 'FractionRecirculation', :float)
      @total_recovery_efficiency = XMLHelper.get_value(ventilation_fan, 'TotalRecoveryEfficiency', :float)
      @sensible_recovery_efficiency = XMLHelper.get_value(ventilation_fan, 'SensibleRecoveryEfficiency', :float)
      @total_recovery_efficiency_adjusted = XMLHelper.get_value(ventilation_fan, 'AdjustedTotalRecoveryEfficiency', :float)
      @sensible_recovery_efficiency_adjusted = XMLHelper.get_value(ventilation_fan, 'AdjustedSensibleRecoveryEfficiency', :float)
      @fan_power = XMLHelper.get_value(ventilation_fan, 'FanPower', :float)
      @distribution_system_idref = HPXML::get_idref(XMLHelper.get_element(ventilation_fan, 'AttachedToHVACDistributionSystem'))
      @start_hour = XMLHelper.get_value(ventilation_fan, 'extension/StartHour', :integer)
      @in_unit_flow_rate = XMLHelper.get_value(ventilation_fan, 'extension/InUnitFlowRate', :float)
      @preheating_fuel = XMLHelper.get_value(ventilation_fan, 'extension/PreHeating/Fuel', :string)
      @preheating_efficiency_cop = XMLHelper.get_value(ventilation_fan, "extension/PreHeating/AnnualHeatingEfficiency[Units='#{UnitsCOP}']/Value", :float)
      @preheating_fraction_load_served = XMLHelper.get_value(ventilation_fan, 'extension/PreHeating/FractionVentilationHeatLoadServed', :float)
      @precooling_fuel = XMLHelper.get_value(ventilation_fan, 'extension/PreCooling/Fuel', :string)
      @precooling_efficiency_cop = XMLHelper.get_value(ventilation_fan, "extension/PreCooling/AnnualCoolingEfficiency[Units='#{UnitsCOP}']/Value", :float)
      @precooling_fraction_load_served = XMLHelper.get_value(ventilation_fan, 'extension/PreCooling/FractionVentilationCoolLoadServed', :float)
      @flow_rate_not_tested = XMLHelper.get_value(ventilation_fan, 'extension/FlowRateNotTested', :boolean)
      @fan_power_defaulted = XMLHelper.get_value(ventilation_fan, 'extension/FanPowerDefaulted', :boolean)
      @cfis_vent_mode_airflow_fraction = XMLHelper.get_value(ventilation_fan, 'extension/VentilationOnlyModeAirflowFraction', :float)
      @cfis_addtl_runtime_operating_mode = XMLHelper.get_value(ventilation_fan, 'CFISControls/AdditionalRuntimeOperatingMode', :string)
      @cfis_supplemental_fan_idref = HPXML::get_idref(XMLHelper.get_element(ventilation_fan, 'CFISControls/SupplementalFan'))
    end
  end

  class WaterHeatingSystems < BaseArrayElement
    def add(**kwargs)
      self << WaterHeatingSystem.new(@parent_object, **kwargs)
    end

    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/Systems/WaterHeating/WaterHeatingSystem').each do |water_heating_system|
        self << WaterHeatingSystem.new(@parent_object, water_heating_system)
      end
    end
  end

  class WaterHeatingSystem < BaseElement
    ATTRS = [:id, :year_installed, :fuel_type, :water_heater_type, :location, :performance_adjustment,
             :tank_volume, :fraction_dhw_load_served, :heating_capacity, :energy_factor, :usage_bin,
             :uniform_energy_factor, :first_hour_rating, :recovery_efficiency, :uses_desuperheater, :jacket_r_value,
             :related_hvac_idref, :third_party_certification, :standby_loss_units, :standby_loss_value,
             :temperature, :is_shared_system, :number_of_units_served, :tank_model_type, :operating_mode]
    attr_accessor(*ATTRS)

    def related_hvac_system
      return if @related_hvac_idref.nil?

      @parent_object.hvac_systems.each do |hvac_system|
        next unless hvac_system.id == @related_hvac_idref

        return hvac_system
      end
      fail "RelatedHVACSystem '#{@related_hvac_idref}' not found for water heating system '#{@id}'."
    end

    def delete
      @parent_object.water_heating_systems.delete(self)
      @parent_object.solar_thermal_systems.each do |solar_thermal_system|
        next unless solar_thermal_system.water_heating_system_idref == @id

        solar_thermal_system.water_heating_system_idref = nil
      end
      @parent_object.clothes_washers.each do |clothes_washer|
        next unless clothes_washer.water_heating_system_idref == @id

        clothes_washer.water_heating_system_idref = nil
      end
      @parent_object.dishwashers.each do |dishwasher|
        next unless dishwasher.water_heating_system_idref == @id

        dishwasher.water_heating_system_idref = nil
      end
    end

    def check_for_errors
      errors = []
      begin; related_hvac_system; rescue StandardError => e; errors << e.message; end
      return errors
    end

    def to_doc(building)
      return if nil?

      water_heating = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Systems', 'WaterHeating'])
      water_heating_system = XMLHelper.add_element(water_heating, 'WaterHeatingSystem')
      sys_id = XMLHelper.add_element(water_heating_system, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_element(water_heating_system, 'FuelType', @fuel_type, :string) unless @fuel_type.nil?
      XMLHelper.add_element(water_heating_system, 'WaterHeaterType', @water_heater_type, :string) unless @water_heater_type.nil?
      XMLHelper.add_element(water_heating_system, 'Location', @location, :string, @location_isdefaulted) unless @location.nil?
      XMLHelper.add_element(water_heating_system, 'YearInstalled', @year_installed, :integer) unless @year_installed.nil?
      XMLHelper.add_element(water_heating_system, 'IsSharedSystem', @is_shared_system, :boolean, @is_shared_system_isdefaulted) unless @is_shared_system.nil?
      XMLHelper.add_element(water_heating_system, 'NumberofUnitsServed', @number_of_units_served, :integer) unless @number_of_units_served.nil?
      XMLHelper.add_element(water_heating_system, 'PerformanceAdjustment', @performance_adjustment, :float, @performance_adjustment_isdefaulted) unless @performance_adjustment.nil?
      XMLHelper.add_element(water_heating_system, 'ThirdPartyCertification', @third_party_certification, :string) unless @third_party_certification.nil?
      XMLHelper.add_element(water_heating_system, 'TankVolume', @tank_volume, :float, @tank_volume_isdefaulted) unless @tank_volume.nil?
      XMLHelper.add_element(water_heating_system, 'FractionDHWLoadServed', @fraction_dhw_load_served, :float) unless @fraction_dhw_load_served.nil?
      XMLHelper.add_element(water_heating_system, 'HeatingCapacity', @heating_capacity, :float, @heating_capacity_isdefaulted) unless @heating_capacity.nil?
      XMLHelper.add_element(water_heating_system, 'EnergyFactor', @energy_factor, :float, @energy_factor_isdefaulted) unless @energy_factor.nil?
      XMLHelper.add_element(water_heating_system, 'UniformEnergyFactor', @uniform_energy_factor, :float) unless @uniform_energy_factor.nil?
      XMLHelper.add_element(water_heating_system, 'HPWHOperatingMode', @operating_mode, :string, @operating_mode_isdefaulted) unless @operating_mode.nil?
      XMLHelper.add_element(water_heating_system, 'FirstHourRating', @first_hour_rating, :float) unless @first_hour_rating.nil?
      XMLHelper.add_element(water_heating_system, 'UsageBin', @usage_bin, :string, @usage_bin_isdefaulted) unless @usage_bin.nil?
      XMLHelper.add_element(water_heating_system, 'RecoveryEfficiency', @recovery_efficiency, :float, @recovery_efficiency_isdefaulted) unless @recovery_efficiency.nil?
      if not @jacket_r_value.nil?
        water_heater_insulation = XMLHelper.add_element(water_heating_system, 'WaterHeaterInsulation')
        jacket = XMLHelper.add_element(water_heater_insulation, 'Jacket')
        XMLHelper.add_element(jacket, 'JacketRValue', @jacket_r_value, :float)
      end
      if (not @standby_loss_units.nil?) && (not @standby_loss_value.nil?)
        standby_loss = XMLHelper.add_element(water_heating_system, 'StandbyLoss')
        XMLHelper.add_element(standby_loss, 'Units', @standby_loss_units, :string, @standby_loss_units_isdefaulted)
        XMLHelper.add_element(standby_loss, 'Value', @standby_loss_value, :float, @standby_loss_value_isdefaulted)
      end
      XMLHelper.add_element(water_heating_system, 'HotWaterTemperature', @temperature, :float, @temperature_isdefaulted) unless @temperature.nil?
      XMLHelper.add_element(water_heating_system, 'UsesDesuperheater', @uses_desuperheater, :boolean) unless @uses_desuperheater.nil?
      if not @related_hvac_idref.nil?
        related_hvac_idref_el = XMLHelper.add_element(water_heating_system, 'RelatedHVACSystem')
        XMLHelper.add_attribute(related_hvac_idref_el, 'idref', @related_hvac_idref)
      end
      if not @tank_model_type.nil?
        extension = XMLHelper.create_elements_as_needed(water_heating_system, ['extension'])
        XMLHelper.add_element(extension, 'TankModelType', @tank_model_type, :string, @tank_model_type_isdefaulted) unless @tank_model_type.nil?
      end
    end

    def from_doc(water_heating_system)
      return if water_heating_system.nil?

      @id = HPXML::get_id(water_heating_system)
      @fuel_type = XMLHelper.get_value(water_heating_system, 'FuelType', :string)
      @water_heater_type = XMLHelper.get_value(water_heating_system, 'WaterHeaterType', :string)
      @location = XMLHelper.get_value(water_heating_system, 'Location', :string)
      @year_installed = XMLHelper.get_value(water_heating_system, 'YearInstalled', :integer)
      @is_shared_system = XMLHelper.get_value(water_heating_system, 'IsSharedSystem', :boolean)
      @number_of_units_served = XMLHelper.get_value(water_heating_system, 'NumberofUnitsServed', :integer)
      @performance_adjustment = XMLHelper.get_value(water_heating_system, 'PerformanceAdjustment', :float)
      @third_party_certification = XMLHelper.get_value(water_heating_system, 'ThirdPartyCertification', :string)
      @tank_volume = XMLHelper.get_value(water_heating_system, 'TankVolume', :float)
      @fraction_dhw_load_served = XMLHelper.get_value(water_heating_system, 'FractionDHWLoadServed', :float)
      @heating_capacity = XMLHelper.get_value(water_heating_system, 'HeatingCapacity', :float)
      @energy_factor = XMLHelper.get_value(water_heating_system, 'EnergyFactor', :float)
      @uniform_energy_factor = XMLHelper.get_value(water_heating_system, 'UniformEnergyFactor', :float)
      @operating_mode = XMLHelper.get_value(water_heating_system, 'HPWHOperatingMode', :string)
      @first_hour_rating = XMLHelper.get_value(water_heating_system, 'FirstHourRating', :float)
      @usage_bin = XMLHelper.get_value(water_heating_system, 'UsageBin', :string)
      @recovery_efficiency = XMLHelper.get_value(water_heating_system, 'RecoveryEfficiency', :float)
      @jacket_r_value = XMLHelper.get_value(water_heating_system, 'WaterHeaterInsulation/Jacket/JacketRValue', :float)
      @standby_loss_units = XMLHelper.get_value(water_heating_system, 'StandbyLoss/Units', :string)
      @standby_loss_value = XMLHelper.get_value(water_heating_system, 'StandbyLoss/Value', :float)
      @temperature = XMLHelper.get_value(water_heating_system, 'HotWaterTemperature', :float)
      @uses_desuperheater = XMLHelper.get_value(water_heating_system, 'UsesDesuperheater', :boolean)
      @related_hvac_idref = HPXML::get_idref(XMLHelper.get_element(water_heating_system, 'RelatedHVACSystem'))
      @tank_model_type = XMLHelper.get_value(water_heating_system, 'extension/TankModelType', :string)
    end
  end

  class HotWaterDistributions < BaseArrayElement
    def add(**kwargs)
      self << HotWaterDistribution.new(@parent_object, **kwargs)
    end

    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/Systems/WaterHeating/HotWaterDistribution').each do |hot_water_distribution|
        self << HotWaterDistribution.new(@parent_object, hot_water_distribution)
      end
    end
  end

  class HotWaterDistribution < BaseElement
    ATTRS = [:id, :system_type, :pipe_r_value, :standard_piping_length, :recirculation_control_type,
             :recirculation_piping_length, :recirculation_branch_piping_length,
             :recirculation_pump_power, :dwhr_facilities_connected, :dwhr_equal_flow,
             :dwhr_efficiency, :has_shared_recirculation, :shared_recirculation_number_of_units_served,
             :shared_recirculation_pump_power, :shared_recirculation_control_type,
             :shared_recirculation_motor_efficiency,
             :recirculation_pump_weekday_fractions, :recirculation_pump_weekend_fractions, :recirculation_pump_monthly_multipliers]
    attr_accessor(*ATTRS)

    def delete
      @parent_object.hot_water_distributions.delete(self)
    end

    def check_for_errors
      errors = []
      return errors
    end

    def to_doc(building)
      return if nil?

      water_heating = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Systems', 'WaterHeating'])
      hot_water_distribution = XMLHelper.add_element(water_heating, 'HotWaterDistribution')
      sys_id = XMLHelper.add_element(hot_water_distribution, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      if not @system_type.nil?
        system_type_el = XMLHelper.add_element(hot_water_distribution, 'SystemType')
        if @system_type == DHWDistTypeStandard
          standard = XMLHelper.add_element(system_type_el, @system_type)
          XMLHelper.add_element(standard, 'PipingLength', @standard_piping_length, :float, @standard_piping_length_isdefaulted) unless @standard_piping_length.nil?
        elsif system_type == DHWDistTypeRecirc
          recirculation = XMLHelper.add_element(system_type_el, @system_type)
          XMLHelper.add_element(recirculation, 'ControlType', @recirculation_control_type, :string) unless @recirculation_control_type.nil?
          XMLHelper.add_element(recirculation, 'RecirculationPipingLoopLength', @recirculation_piping_length, :float, @recirculation_piping_length_isdefaulted) unless @recirculation_piping_length.nil?
          XMLHelper.add_element(recirculation, 'BranchPipingLength', @recirculation_branch_piping_length, :float, @recirculation_branch_piping_length_isdefaulted) unless @recirculation_branch_piping_length.nil?
          XMLHelper.add_element(recirculation, 'PumpPower', @recirculation_pump_power, :float, @recirculation_pump_power_isdefaulted) unless @recirculation_pump_power.nil?
        else
          fail "Unhandled hot water distribution type '#{@system_type}'."
        end
      end
      if not @pipe_r_value.nil?
        pipe_insulation = XMLHelper.add_element(hot_water_distribution, 'PipeInsulation')
        XMLHelper.add_element(pipe_insulation, 'PipeRValue', @pipe_r_value, :float, @pipe_r_value_isdefaulted)
      end
      if (not @dwhr_facilities_connected.nil?) || (not @dwhr_equal_flow.nil?) || (not @dwhr_efficiency.nil?)
        drain_water_heat_recovery = XMLHelper.add_element(hot_water_distribution, 'DrainWaterHeatRecovery')
        XMLHelper.add_element(drain_water_heat_recovery, 'FacilitiesConnected', @dwhr_facilities_connected, :string) unless @dwhr_facilities_connected.nil?
        XMLHelper.add_element(drain_water_heat_recovery, 'EqualFlow', @dwhr_equal_flow, :boolean) unless @dwhr_equal_flow.nil?
        XMLHelper.add_element(drain_water_heat_recovery, 'Efficiency', @dwhr_efficiency, :float) unless @dwhr_efficiency.nil?
      end
      if @has_shared_recirculation
        extension = XMLHelper.create_elements_as_needed(hot_water_distribution, ['extension'])
        shared_recirculation = XMLHelper.add_element(extension, 'SharedRecirculation')
        XMLHelper.add_element(shared_recirculation, 'NumberofUnitsServed', @shared_recirculation_number_of_units_served, :integer) unless @shared_recirculation_number_of_units_served.nil?
        XMLHelper.add_element(shared_recirculation, 'PumpPower', @shared_recirculation_pump_power, :float, @shared_recirculation_pump_power_isdefaulted) unless @shared_recirculation_pump_power.nil?
        XMLHelper.add_element(shared_recirculation, 'MotorEfficiency', @shared_recirculation_motor_efficiency, :float) unless @shared_recirculation_motor_efficiency.nil?
        XMLHelper.add_element(shared_recirculation, 'ControlType', @shared_recirculation_control_type, :string) unless @shared_recirculation_control_type.nil?
      end
      XMLHelper.add_extension(hot_water_distribution, 'RecirculationPumpWeekdayScheduleFractions', @recirculation_pump_weekday_fractions, :string, @recirculation_pump_weekday_fractions_isdefaulted) unless @recirculation_pump_weekday_fractions.nil?
      XMLHelper.add_extension(hot_water_distribution, 'RecirculationPumpWeekendScheduleFractions', @recirculation_pump_weekend_fractions, :string, @recirculation_pump_weekend_fractions_isdefaulted) unless @recirculation_pump_weekend_fractions.nil?
      XMLHelper.add_extension(hot_water_distribution, 'RecirculationPumpMonthlyScheduleMultipliers', @recirculation_pump_monthly_multipliers, :string, @recirculation_pump_monthly_multipliers_isdefaulted) unless @recirculation_pump_monthly_multipliers.nil?
    end

    def from_doc(hot_water_distribution)
      return if hot_water_distribution.nil?

      @id = HPXML::get_id(hot_water_distribution)
      @system_type = XMLHelper.get_child_name(hot_water_distribution, 'SystemType')
      if @system_type == 'Standard'
        @standard_piping_length = XMLHelper.get_value(hot_water_distribution, 'SystemType/Standard/PipingLength', :float)
      elsif @system_type == 'Recirculation'
        @recirculation_control_type = XMLHelper.get_value(hot_water_distribution, 'SystemType/Recirculation/ControlType', :string)
        @recirculation_piping_length = XMLHelper.get_value(hot_water_distribution, 'SystemType/Recirculation/RecirculationPipingLoopLength', :float)
        @recirculation_branch_piping_length = XMLHelper.get_value(hot_water_distribution, 'SystemType/Recirculation/BranchPipingLength', :float)
        @recirculation_pump_power = XMLHelper.get_value(hot_water_distribution, 'SystemType/Recirculation/PumpPower', :float)
      end
      @pipe_r_value = XMLHelper.get_value(hot_water_distribution, 'PipeInsulation/PipeRValue', :float)
      @dwhr_facilities_connected = XMLHelper.get_value(hot_water_distribution, 'DrainWaterHeatRecovery/FacilitiesConnected', :string)
      @dwhr_equal_flow = XMLHelper.get_value(hot_water_distribution, 'DrainWaterHeatRecovery/EqualFlow', :boolean)
      @dwhr_efficiency = XMLHelper.get_value(hot_water_distribution, 'DrainWaterHeatRecovery/Efficiency', :float)
      @has_shared_recirculation = XMLHelper.has_element(hot_water_distribution, 'extension/SharedRecirculation')
      if @has_shared_recirculation
        @shared_recirculation_number_of_units_served = XMLHelper.get_value(hot_water_distribution, 'extension/SharedRecirculation/NumberofUnitsServed', :integer)
        @shared_recirculation_pump_power = XMLHelper.get_value(hot_water_distribution, 'extension/SharedRecirculation/PumpPower', :float)
        @shared_recirculation_motor_efficiency = XMLHelper.get_value(hot_water_distribution, 'extension/SharedRecirculation/MotorEfficiency', :float)
        @shared_recirculation_control_type = XMLHelper.get_value(hot_water_distribution, 'extension/SharedRecirculation/ControlType', :string)
      end
      @recirculation_pump_weekday_fractions = XMLHelper.get_value(hot_water_distribution, 'extension/RecirculationPumpWeekdayScheduleFractions', :string)
      @recirculation_pump_weekend_fractions = XMLHelper.get_value(hot_water_distribution, 'extension/RecirculationPumpWeekendScheduleFractions', :string)
      @recirculation_pump_monthly_multipliers = XMLHelper.get_value(hot_water_distribution, 'extension/RecirculationPumpMonthlyScheduleMultipliers', :string)
    end
  end

  class WaterFixtures < BaseArrayElement
    def add(**kwargs)
      self << WaterFixture.new(@parent_object, **kwargs)
    end

    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/Systems/WaterHeating/WaterFixture').each do |water_fixture|
        self << WaterFixture.new(@parent_object, water_fixture)
      end
    end
  end

  class WaterFixture < BaseElement
    ATTRS = [:id, :water_fixture_type, :low_flow, :flow_rate, :count]
    attr_accessor(*ATTRS)

    def delete
      @parent_object.water_fixtures.delete(self)
    end

    def check_for_errors
      errors = []
      return errors
    end

    def to_doc(building)
      return if nil?

      water_heating = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Systems', 'WaterHeating'])
      water_fixture = XMLHelper.add_element(water_heating, 'WaterFixture')
      sys_id = XMLHelper.add_element(water_fixture, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_element(water_fixture, 'WaterFixtureType', @water_fixture_type, :string) unless @water_fixture_type.nil?
      XMLHelper.add_element(water_fixture, 'Count', @count, :integer, @count_isdefaulted) unless @count.nil?
      XMLHelper.add_element(water_fixture, 'FlowRate', @flow_rate, :float, @flow_rate_isdefaulted) unless @flow_rate.nil?
      XMLHelper.add_element(water_fixture, 'LowFlow', @low_flow, :boolean, @low_flow_isdefaulted) unless @low_flow.nil?
    end

    def from_doc(water_fixture)
      return if water_fixture.nil?

      @id = HPXML::get_id(water_fixture)
      @water_fixture_type = XMLHelper.get_value(water_fixture, 'WaterFixtureType', :string)
      @count = XMLHelper.get_value(water_fixture, 'Count', :integer)
      @flow_rate = XMLHelper.get_value(water_fixture, 'FlowRate', :float)
      @low_flow = XMLHelper.get_value(water_fixture, 'LowFlow', :boolean)
    end
  end

  class WaterHeating < BaseElement
    ATTRS = [:water_fixtures_usage_multiplier, :water_fixtures_weekday_fractions, :water_fixtures_weekend_fractions,
             :water_fixtures_monthly_multipliers]
    attr_accessor(*ATTRS)

    def check_for_errors
      errors = []
      return errors
    end

    def to_doc(building)
      return if nil?

      water_heating = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Systems', 'WaterHeating'])
      XMLHelper.add_extension(water_heating, 'WaterFixturesUsageMultiplier', @water_fixtures_usage_multiplier, :float, @water_fixtures_usage_multiplier_isdefaulted) unless @water_fixtures_usage_multiplier.nil?
      XMLHelper.add_extension(water_heating, 'WaterFixturesWeekdayScheduleFractions', @water_fixtures_weekday_fractions, :string, @water_fixtures_weekday_fractions_isdefaulted) unless @water_fixtures_weekday_fractions.nil?
      XMLHelper.add_extension(water_heating, 'WaterFixturesWeekendScheduleFractions', @water_fixtures_weekend_fractions, :string, @water_fixtures_weekend_fractions_isdefaulted) unless @water_fixtures_weekend_fractions.nil?
      XMLHelper.add_extension(water_heating, 'WaterFixturesMonthlyScheduleMultipliers', @water_fixtures_monthly_multipliers, :string, @water_fixtures_monthly_multipliers_isdefaulted) unless @water_fixtures_monthly_multipliers.nil?
    end

    def from_doc(building)
      return if building.nil?

      water_heating = XMLHelper.get_element(building, 'BuildingDetails/Systems/WaterHeating')
      return if water_heating.nil?

      @water_fixtures_usage_multiplier = XMLHelper.get_value(water_heating, 'extension/WaterFixturesUsageMultiplier', :float)
      @water_fixtures_weekday_fractions = XMLHelper.get_value(water_heating, 'extension/WaterFixturesWeekdayScheduleFractions', :string)
      @water_fixtures_weekend_fractions = XMLHelper.get_value(water_heating, 'extension/WaterFixturesWeekendScheduleFractions', :string)
      @water_fixtures_monthly_multipliers = XMLHelper.get_value(water_heating, 'extension/WaterFixturesMonthlyScheduleMultipliers', :string)
    end
  end

  class SolarThermalSystems < BaseArrayElement
    def add(**kwargs)
      self << SolarThermalSystem.new(@parent_object, **kwargs)
    end

    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/Systems/SolarThermal/SolarThermalSystem').each do |solar_thermal_system|
        self << SolarThermalSystem.new(@parent_object, solar_thermal_system)
      end
    end
  end

  class SolarThermalSystem < BaseElement
    ATTRS = [:id, :system_type, :collector_area, :collector_loop_type, :collector_orientation, :collector_azimuth,
             :collector_type, :collector_tilt, :collector_frta, :collector_frul, :storage_volume,
             :water_heating_system_idref, :solar_fraction]
    attr_accessor(*ATTRS)

    def water_heating_system
      return if @water_heating_system_idref.nil?

      @parent_object.water_heating_systems.each do |water_heater|
        next unless water_heater.id == @water_heating_system_idref

        return water_heater
      end
      fail "Attached water heating system '#{@water_heating_system_idref}' not found for solar thermal system '#{@id}'."
    end

    def delete
      @parent_object.solar_thermal_systems.delete(self)
    end

    def check_for_errors
      errors = []
      begin; water_heating_system; rescue StandardError => e; errors << e.message; end
      return errors
    end

    def to_doc(building)
      return if nil?

      solar_thermal = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Systems', 'SolarThermal'])
      solar_thermal_system = XMLHelper.add_element(solar_thermal, 'SolarThermalSystem')
      sys_id = XMLHelper.add_element(solar_thermal_system, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_element(solar_thermal_system, 'SystemType', @system_type, :string) unless @system_type.nil?
      XMLHelper.add_element(solar_thermal_system, 'CollectorArea', @collector_area, :float) unless @collector_area.nil?
      XMLHelper.add_element(solar_thermal_system, 'CollectorLoopType', @collector_loop_type, :string) unless @collector_loop_type.nil?
      XMLHelper.add_element(solar_thermal_system, 'CollectorType', @collector_type, :string) unless @collector_type.nil?
      XMLHelper.add_element(solar_thermal_system, 'CollectorOrientation', @collector_orientation, :string, @collector_orientation_isdefaulted) unless @collector_orientation.nil?
      XMLHelper.add_element(solar_thermal_system, 'CollectorAzimuth', @collector_azimuth, :integer, @collector_azimuth_isdefaulted) unless @collector_azimuth.nil?
      XMLHelper.add_element(solar_thermal_system, 'CollectorTilt', @collector_tilt, :float) unless @collector_tilt.nil?
      XMLHelper.add_element(solar_thermal_system, 'CollectorRatedOpticalEfficiency', @collector_frta, :float) unless @collector_frta.nil?
      XMLHelper.add_element(solar_thermal_system, 'CollectorRatedThermalLosses', @collector_frul, :float) unless @collector_frul.nil?
      XMLHelper.add_element(solar_thermal_system, 'StorageVolume', @storage_volume, :float, @storage_volume_isdefaulted) unless @storage_volume.nil?
      if not @water_heating_system_idref.nil?
        connected_to = XMLHelper.add_element(solar_thermal_system, 'ConnectedTo')
        XMLHelper.add_attribute(connected_to, 'idref', @water_heating_system_idref)
      end
      XMLHelper.add_element(solar_thermal_system, 'SolarFraction', @solar_fraction, :float) unless @solar_fraction.nil?
    end

    def from_doc(solar_thermal_system)
      return if solar_thermal_system.nil?

      @id = HPXML::get_id(solar_thermal_system)
      @system_type = XMLHelper.get_value(solar_thermal_system, 'SystemType', :string)
      @collector_area = XMLHelper.get_value(solar_thermal_system, 'CollectorArea', :float)
      @collector_loop_type = XMLHelper.get_value(solar_thermal_system, 'CollectorLoopType', :string)
      @collector_type = XMLHelper.get_value(solar_thermal_system, 'CollectorType', :string)
      @collector_orientation = XMLHelper.get_value(solar_thermal_system, 'CollectorOrientation', :string)
      @collector_azimuth = XMLHelper.get_value(solar_thermal_system, 'CollectorAzimuth', :integer)
      @collector_tilt = XMLHelper.get_value(solar_thermal_system, 'CollectorTilt', :float)
      @collector_frta = XMLHelper.get_value(solar_thermal_system, 'CollectorRatedOpticalEfficiency', :float)
      @collector_frul = XMLHelper.get_value(solar_thermal_system, 'CollectorRatedThermalLosses', :float)
      @storage_volume = XMLHelper.get_value(solar_thermal_system, 'StorageVolume', :float)
      @water_heating_system_idref = HPXML::get_idref(XMLHelper.get_element(solar_thermal_system, 'ConnectedTo'))
      @solar_fraction = XMLHelper.get_value(solar_thermal_system, 'SolarFraction', :float)
    end
  end

  class PVSystems < BaseArrayElement
    def add(**kwargs)
      self << PVSystem.new(@parent_object, **kwargs)
    end

    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/Systems/Photovoltaics/PVSystem').each do |pv_system|
        self << PVSystem.new(@parent_object, pv_system)
      end
    end
  end

  class PVSystem < BaseElement
    ATTRS = [:id, :location, :module_type, :tracking, :array_orientation, :array_azimuth, :array_tilt,
             :max_power_output, :inverter_idref, :system_losses_fraction, :number_of_panels,
             :year_modules_manufactured, :is_shared_system, :number_of_bedrooms_served]
    attr_accessor(*ATTRS)

    def inverter
      return if @inverter_idref.nil?

      @parent_object.inverters.each do |inv|
        next unless inv.id == @inverter_idref

        return inv
      end
      fail "Attached inverter '#{@inverter_idref}' not found for pv system '#{@id}'."
    end

    def delete
      @parent_object.pv_systems.delete(self)
    end

    def check_for_errors
      errors = []
      begin; inverter; rescue StandardError => e; errors << e.message; end
      return errors
    end

    def to_doc(building)
      return if nil?

      photovoltaics = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Systems', 'Photovoltaics'])
      pv_system = XMLHelper.add_element(photovoltaics, 'PVSystem')
      sys_id = XMLHelper.add_element(pv_system, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_element(pv_system, 'IsSharedSystem', @is_shared_system, :boolean, @is_shared_system_isdefaulted) unless @is_shared_system.nil?
      XMLHelper.add_element(pv_system, 'Location', @location, :string, @location_isdefaulted) unless @location.nil?
      XMLHelper.add_element(pv_system, 'ModuleType', @module_type, :string, @module_type_isdefaulted) unless @module_type.nil?
      XMLHelper.add_element(pv_system, 'Tracking', @tracking, :string, @tracking_isdefaulted) unless @tracking.nil?
      XMLHelper.add_element(pv_system, 'ArrayOrientation', @array_orientation, :string, @array_orientation_isdefaulted) unless @array_orientation.nil?
      XMLHelper.add_element(pv_system, 'ArrayAzimuth', @array_azimuth, :integer, @array_azimuth_isdefaulted) unless @array_azimuth.nil?
      XMLHelper.add_element(pv_system, 'ArrayTilt', @array_tilt, :float) unless @array_tilt.nil?
      XMLHelper.add_element(pv_system, 'MaxPowerOutput', @max_power_output, :float) unless @max_power_output.nil?
      XMLHelper.add_element(pv_system, 'NumberOfPanels', @number_of_panels, :integer) unless @number_of_panels.nil?
      XMLHelper.add_element(pv_system, 'SystemLossesFraction', @system_losses_fraction, :float, @system_losses_fraction_isdefaulted) unless @system_losses_fraction.nil?
      XMLHelper.add_element(pv_system, 'YearModulesManufactured', @year_modules_manufactured, :integer) unless @year_modules_manufactured.nil?
      if not @inverter_idref.nil?
        attached_to_inverter = XMLHelper.add_element(pv_system, 'AttachedToInverter')
        XMLHelper.add_attribute(attached_to_inverter, 'idref', @inverter_idref)
      end
      XMLHelper.add_extension(pv_system, 'NumberofBedroomsServed', @number_of_bedrooms_served, :integer) unless @number_of_bedrooms_served.nil?
    end

    def from_doc(pv_system)
      return if pv_system.nil?

      @id = HPXML::get_id(pv_system)
      @is_shared_system = XMLHelper.get_value(pv_system, 'IsSharedSystem', :boolean)
      @location = XMLHelper.get_value(pv_system, 'Location', :string)
      @module_type = XMLHelper.get_value(pv_system, 'ModuleType', :string)
      @tracking = XMLHelper.get_value(pv_system, 'Tracking', :string)
      @array_orientation = XMLHelper.get_value(pv_system, 'ArrayOrientation', :string)
      @array_azimuth = XMLHelper.get_value(pv_system, 'ArrayAzimuth', :integer)
      @array_tilt = XMLHelper.get_value(pv_system, 'ArrayTilt', :float)
      @max_power_output = XMLHelper.get_value(pv_system, 'MaxPowerOutput', :float)
      @number_of_panels = XMLHelper.get_value(pv_system, 'NumberOfPanels', :integer)
      @system_losses_fraction = XMLHelper.get_value(pv_system, 'SystemLossesFraction', :float)
      @year_modules_manufactured = XMLHelper.get_value(pv_system, 'YearModulesManufactured', :integer)
      @inverter_idref = HPXML::get_idref(XMLHelper.get_element(pv_system, 'AttachedToInverter'))
      @number_of_bedrooms_served = XMLHelper.get_value(pv_system, 'extension/NumberofBedroomsServed', :integer)
    end
  end

  class Inverters < BaseArrayElement
    def add(**kwargs)
      self << Inverter.new(@parent_object, **kwargs)
    end

    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/Systems/Photovoltaics/Inverter').each do |inverter|
        self << Inverter.new(@parent_object, inverter)
      end
    end
  end

  class Inverter < BaseElement
    ATTRS = [:id, :inverter_efficiency]
    attr_accessor(*ATTRS)

    def pv_system
      return if @id.nil?

      @parent_object.pv_systems.each do |pv|
        next unless @id == pv.inverter_idref

        return pv
      end
    end

    def delete
      @parent_object.inverters.delete(self)
    end

    def check_for_errors
      errors = []
      begin; pv_system; rescue StandardError => e; errors << e.message; end
      return errors
    end

    def to_doc(building)
      return if nil?

      photovoltaics = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Systems', 'Photovoltaics'])
      inverter = XMLHelper.add_element(photovoltaics, 'Inverter')
      sys_id = XMLHelper.add_element(inverter, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_element(inverter, 'InverterEfficiency', @inverter_efficiency, :float, @inverter_efficiency_isdefaulted) unless @inverter_efficiency.nil?
    end

    def from_doc(inverter)
      return if inverter.nil?

      @id = HPXML::get_id(inverter)
      @inverter_efficiency = XMLHelper.get_value(inverter, 'InverterEfficiency', :float)
    end
  end

  class Generators < BaseArrayElement
    def add(**kwargs)
      self << Generator.new(@parent_object, **kwargs)
    end

    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/Systems/extension/Generators/Generator').each do |generator|
        self << Generator.new(@parent_object, generator)
      end
    end
  end

  class Generator < BaseElement
    ATTRS = [:id, :fuel_type, :annual_consumption_kbtu, :annual_output_kwh, :is_shared_system, :number_of_bedrooms_served]
    attr_accessor(*ATTRS)

    def delete
      @parent_object.generators.delete(self)
    end

    def check_for_errors
      errors = []
      return errors
    end

    def to_doc(building)
      return if nil?

      generators = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Systems', 'extension', 'Generators'])
      generator = XMLHelper.add_element(generators, 'Generator')
      sys_id = XMLHelper.add_element(generator, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_element(generator, 'IsSharedSystem', @is_shared_system, :boolean, @is_shared_system_isdefaulted) unless @is_shared_system.nil?
      XMLHelper.add_element(generator, 'FuelType', @fuel_type, :string) unless @fuel_type.nil?
      XMLHelper.add_element(generator, 'AnnualConsumptionkBtu', @annual_consumption_kbtu, :float) unless @annual_consumption_kbtu.nil?
      XMLHelper.add_element(generator, 'AnnualOutputkWh', @annual_output_kwh, :float) unless @annual_output_kwh.nil?
      XMLHelper.add_element(generator, 'NumberofBedroomsServed', @number_of_bedrooms_served, :integer) unless @number_of_bedrooms_served.nil?
    end

    def from_doc(generator)
      return if generator.nil?

      @id = HPXML::get_id(generator)
      @is_shared_system = XMLHelper.get_value(generator, 'IsSharedSystem', :boolean)
      @fuel_type = XMLHelper.get_value(generator, 'FuelType', :string)
      @annual_consumption_kbtu = XMLHelper.get_value(generator, 'AnnualConsumptionkBtu', :float)
      @annual_output_kwh = XMLHelper.get_value(generator, 'AnnualOutputkWh', :float)
      @number_of_bedrooms_served = XMLHelper.get_value(generator, 'NumberofBedroomsServed', :integer)
    end
  end

  class Batteries < BaseArrayElement
    def add(**kwargs)
      self << Battery.new(@parent_object, **kwargs)
    end

    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/Systems/Batteries/Battery').each do |battery|
        self << Battery.new(@parent_object, battery)
      end
    end
  end

  class Battery < BaseElement
    ATTRS = [:id, :type, :location, :lifetime_model, :rated_power_output, :nominal_capacity_kwh, :nominal_capacity_ah,
             :nominal_voltage, :round_trip_efficiency, :usable_capacity_kwh, :usable_capacity_ah, :is_shared_system,
             :number_of_bedrooms_served]
    attr_accessor(*ATTRS)

    def delete
      @parent_object.batteries.delete(self)
    end

    def check_for_errors
      errors = []
      return errors
    end

    def to_doc(building)
      return if nil?

      batteries = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Systems', 'Batteries'])
      battery = XMLHelper.add_element(batteries, 'Battery')
      sys_id = XMLHelper.add_element(battery, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_element(battery, 'IsSharedSystem', @is_shared_system, :boolean, @is_shared_system_isdefaulted) unless @is_shared_system.nil?
      XMLHelper.add_element(battery, 'Location', @location, :string, @location_isdefaulted) unless @location.nil?
      XMLHelper.add_element(battery, 'BatteryType', @type, :string) unless @type.nil?
      if not @nominal_capacity_kwh.nil?
        nominal_capacity = XMLHelper.add_element(battery, 'NominalCapacity')
        XMLHelper.add_element(nominal_capacity, 'Units', UnitsKwh, :string)
        XMLHelper.add_element(nominal_capacity, 'Value', @nominal_capacity_kwh, :float, @nominal_capacity_kwh_isdefaulted)
      end
      if not @nominal_capacity_ah.nil?
        nominal_capacity = XMLHelper.add_element(battery, 'NominalCapacity')
        XMLHelper.add_element(nominal_capacity, 'Units', UnitsAh, :string)
        XMLHelper.add_element(nominal_capacity, 'Value', @nominal_capacity_ah, :float, @nominal_capacity_ah_isdefaulted)
      end
      if not @usable_capacity_kwh.nil?
        nominal_capacity = XMLHelper.add_element(battery, 'UsableCapacity')
        XMLHelper.add_element(nominal_capacity, 'Units', UnitsKwh, :string)
        XMLHelper.add_element(nominal_capacity, 'Value', @usable_capacity_kwh, :float, @usable_capacity_kwh_isdefaulted)
      end
      if not @usable_capacity_ah.nil?
        nominal_capacity = XMLHelper.add_element(battery, 'UsableCapacity')
        XMLHelper.add_element(nominal_capacity, 'Units', UnitsAh, :string)
        XMLHelper.add_element(nominal_capacity, 'Value', @usable_capacity_ah, :float, @usable_capacity_ah_isdefaulted)
      end
      XMLHelper.add_element(battery, 'RatedPowerOutput', @rated_power_output, :float, @rated_power_output_isdefaulted) unless @rated_power_output.nil?
      XMLHelper.add_element(battery, 'NominalVoltage', @nominal_voltage, :float, @nominal_voltage_isdefaulted) unless @nominal_voltage.nil?
      XMLHelper.add_element(battery, 'RoundTripEfficiency', @round_trip_efficiency, :float, @round_trip_efficiency_isdefaulted) unless @round_trip_efficiency.nil?
      XMLHelper.add_extension(battery, 'LifetimeModel', @lifetime_model, :string, @lifetime_model_isdefaulted) unless @lifetime_model.nil?
      XMLHelper.add_extension(battery, 'NumberofBedroomsServed', @number_of_bedrooms_served, :integer) unless @number_of_bedrooms_served.nil?
    end

    def from_doc(battery)
      return if battery.nil?

      @id = HPXML::get_id(battery)
      @is_shared_system = XMLHelper.get_value(battery, 'IsSharedSystem', :boolean)
      @location = XMLHelper.get_value(battery, 'Location', :string)
      @type = XMLHelper.get_value(battery, 'BatteryType', :string)
      @nominal_capacity_kwh = XMLHelper.get_value(battery, "NominalCapacity[Units='#{UnitsKwh}']/Value", :float)
      @nominal_capacity_ah = XMLHelper.get_value(battery, "NominalCapacity[Units='#{UnitsAh}']/Value", :float)
      @usable_capacity_kwh = XMLHelper.get_value(battery, "UsableCapacity[Units='#{UnitsKwh}']/Value", :float)
      @usable_capacity_ah = XMLHelper.get_value(battery, "UsableCapacity[Units='#{UnitsAh}']/Value", :float)
      @rated_power_output = XMLHelper.get_value(battery, 'RatedPowerOutput', :float)
      @nominal_voltage = XMLHelper.get_value(battery, 'NominalVoltage', :float)
      @round_trip_efficiency = XMLHelper.get_value(battery, 'RoundTripEFficiency', :float)
      @lifetime_model = XMLHelper.get_value(battery, 'extension/LifetimeModel', :string)
      @number_of_bedrooms_served = XMLHelper.get_value(battery, 'extension/NumberofBedroomsServed', :integer)
    end
  end

  class ClothesWashers < BaseArrayElement
    def add(**kwargs)
      self << ClothesWasher.new(@parent_object, **kwargs)
    end

    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/Appliances/ClothesWasher').each do |clothes_washer|
        self << ClothesWasher.new(@parent_object, clothes_washer)
      end
    end
  end

  class ClothesWasher < BaseElement
    ATTRS = [:id, :location, :modified_energy_factor, :integrated_modified_energy_factor,
             :rated_annual_kwh, :label_electric_rate, :label_gas_rate, :label_annual_gas_cost,
             :capacity, :label_usage, :usage_multiplier, :is_shared_appliance, :count,
             :number_of_units_served, :water_heating_system_idref, :hot_water_distribution_idref,
             :weekday_fractions, :weekend_fractions, :monthly_multipliers]

    attr_accessor(*ATTRS)

    def water_heating_system
      return if @water_heating_system_idref.nil?

      @parent_object.water_heating_systems.each do |water_heater|
        next unless water_heater.id == @water_heating_system_idref

        return water_heater
      end
      fail "Attached water heating system '#{@water_heating_system_idref}' not found for clothes washer '#{@id}'."
    end

    def hot_water_distribution
      return if @hot_water_distribution_idref.nil?

      @parent_object.hot_water_distributions.each do |hot_water_distribution|
        next unless hot_water_distribution.id == @hot_water_distribution_idref

        return hot_water_distribution
      end
      fail "Attached hot water distribution '#{@hot_water_distribution_idref}' not found for clothes washer '#{@id}'."
    end

    def delete
      @parent_object.clothes_washers.delete(self)
    end

    def check_for_errors
      errors = []
      begin; water_heating_system; rescue StandardError => e; errors << e.message; end
      begin; hot_water_distribution; rescue StandardError => e; errors << e.message; end
      return errors
    end

    def to_doc(building)
      return if nil?

      appliances = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Appliances'])
      clothes_washer = XMLHelper.add_element(appliances, 'ClothesWasher')
      sys_id = XMLHelper.add_element(clothes_washer, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_element(clothes_washer, 'Count', @count, :integer) unless @count.nil?
      XMLHelper.add_element(clothes_washer, 'IsSharedAppliance', @is_shared_appliance, :boolean, @is_shared_appliance_isdefaulted) unless @is_shared_appliance.nil?
      XMLHelper.add_element(clothes_washer, 'NumberofUnitsServed', @number_of_units_served, :integer) unless @number_of_units_served.nil?
      if not @water_heating_system_idref.nil?
        attached_water_heater = XMLHelper.add_element(clothes_washer, 'AttachedToWaterHeatingSystem')
        XMLHelper.add_attribute(attached_water_heater, 'idref', @water_heating_system_idref)
      elsif not @hot_water_distribution_idref.nil?
        attached_hot_water_dist = XMLHelper.add_element(clothes_washer, 'AttachedToHotWaterDistribution')
        XMLHelper.add_attribute(attached_hot_water_dist, 'idref', @hot_water_distribution_idref)
      end
      XMLHelper.add_element(clothes_washer, 'Location', @location, :string, @location_isdefaulted) unless @location.nil?
      XMLHelper.add_element(clothes_washer, 'ModifiedEnergyFactor', @modified_energy_factor, :float) unless @modified_energy_factor.nil?
      XMLHelper.add_element(clothes_washer, 'IntegratedModifiedEnergyFactor', @integrated_modified_energy_factor, :float, @integrated_modified_energy_factor_isdefaulted) unless @integrated_modified_energy_factor.nil?
      XMLHelper.add_element(clothes_washer, 'RatedAnnualkWh', @rated_annual_kwh, :float, @rated_annual_kwh_isdefaulted) unless @rated_annual_kwh.nil?
      XMLHelper.add_element(clothes_washer, 'LabelElectricRate', @label_electric_rate, :float, @label_electric_rate_isdefaulted) unless @label_electric_rate.nil?
      XMLHelper.add_element(clothes_washer, 'LabelGasRate', @label_gas_rate, :float, @label_gas_rate_isdefaulted) unless @label_gas_rate.nil?
      XMLHelper.add_element(clothes_washer, 'LabelAnnualGasCost', @label_annual_gas_cost, :float, @label_annual_gas_cost_isdefaulted) unless @label_annual_gas_cost.nil?
      XMLHelper.add_element(clothes_washer, 'LabelUsage', @label_usage, :float, @label_usage_isdefaulted) unless @label_usage.nil?
      XMLHelper.add_element(clothes_washer, 'Capacity', @capacity, :float, @capacity_isdefaulted) unless @capacity.nil?
      XMLHelper.add_extension(clothes_washer, 'UsageMultiplier', @usage_multiplier, :float, @usage_multiplier_isdefaulted) unless @usage_multiplier.nil?
      XMLHelper.add_extension(clothes_washer, 'WeekdayScheduleFractions', @weekday_fractions, :string, @weekday_fractions_isdefaulted) unless @weekday_fractions.nil?
      XMLHelper.add_extension(clothes_washer, 'WeekendScheduleFractions', @weekend_fractions, :string, @weekend_fractions_isdefaulted) unless @weekend_fractions.nil?
      XMLHelper.add_extension(clothes_washer, 'MonthlyScheduleMultipliers', @monthly_multipliers, :string, @monthly_multipliers_isdefaulted) unless @monthly_multipliers.nil?
    end

    def from_doc(clothes_washer)
      return if clothes_washer.nil?

      @id = HPXML::get_id(clothes_washer)
      @count = XMLHelper.get_value(clothes_washer, 'Count', :integer)
      @is_shared_appliance = XMLHelper.get_value(clothes_washer, 'IsSharedAppliance', :boolean)
      @number_of_units_served = XMLHelper.get_value(clothes_washer, 'NumberofUnitsServed', :integer)
      @water_heating_system_idref = HPXML::get_idref(XMLHelper.get_element(clothes_washer, 'AttachedToWaterHeatingSystem'))
      @hot_water_distribution_idref = HPXML::get_idref(XMLHelper.get_element(clothes_washer, 'AttachedToHotWaterDistribution'))
      @location = XMLHelper.get_value(clothes_washer, 'Location', :string)
      @modified_energy_factor = XMLHelper.get_value(clothes_washer, 'ModifiedEnergyFactor', :float)
      @integrated_modified_energy_factor = XMLHelper.get_value(clothes_washer, 'IntegratedModifiedEnergyFactor', :float)
      @rated_annual_kwh = XMLHelper.get_value(clothes_washer, 'RatedAnnualkWh', :float)
      @label_electric_rate = XMLHelper.get_value(clothes_washer, 'LabelElectricRate', :float)
      @label_gas_rate = XMLHelper.get_value(clothes_washer, 'LabelGasRate', :float)
      @label_annual_gas_cost = XMLHelper.get_value(clothes_washer, 'LabelAnnualGasCost', :float)
      @label_usage = XMLHelper.get_value(clothes_washer, 'LabelUsage', :float)
      @capacity = XMLHelper.get_value(clothes_washer, 'Capacity', :float)
      @usage_multiplier = XMLHelper.get_value(clothes_washer, 'extension/UsageMultiplier', :float)
      @weekday_fractions = XMLHelper.get_value(clothes_washer, 'extension/WeekdayScheduleFractions', :string)
      @weekend_fractions = XMLHelper.get_value(clothes_washer, 'extension/WeekendScheduleFractions', :string)
      @monthly_multipliers = XMLHelper.get_value(clothes_washer, 'extension/MonthlyScheduleMultipliers', :string)
    end
  end

  class ClothesDryers < BaseArrayElement
    def add(**kwargs)
      self << ClothesDryer.new(@parent_object, **kwargs)
    end

    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/Appliances/ClothesDryer').each do |clothes_dryer|
        self << ClothesDryer.new(@parent_object, clothes_dryer)
      end
    end
  end

  class ClothesDryer < BaseElement
    ATTRS = [:id, :location, :fuel_type, :energy_factor, :combined_energy_factor, :control_type,
             :usage_multiplier, :is_shared_appliance, :count, :number_of_units_served,
             :is_vented, :vented_flow_rate, :weekday_fractions, :weekend_fractions,
             :monthly_multipliers]
    attr_accessor(*ATTRS)

    def delete
      @parent_object.clothes_dryers.delete(self)
    end

    def check_for_errors
      errors = []
      return errors
    end

    def to_doc(building)
      return if nil?

      appliances = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Appliances'])
      clothes_dryer = XMLHelper.add_element(appliances, 'ClothesDryer')
      sys_id = XMLHelper.add_element(clothes_dryer, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_element(clothes_dryer, 'Count', @count, :integer) unless @count.nil?
      XMLHelper.add_element(clothes_dryer, 'IsSharedAppliance', @is_shared_appliance, :boolean, @is_shared_appliance_isdefaulted) unless @is_shared_appliance.nil?
      XMLHelper.add_element(clothes_dryer, 'NumberofUnitsServed', @number_of_units_served, :integer) unless @number_of_units_served.nil?
      XMLHelper.add_element(clothes_dryer, 'Location', @location, :string, @location_isdefaulted) unless @location.nil?
      XMLHelper.add_element(clothes_dryer, 'FuelType', @fuel_type, :string) unless @fuel_type.nil?
      XMLHelper.add_element(clothes_dryer, 'EnergyFactor', @energy_factor, :float) unless @energy_factor.nil?
      XMLHelper.add_element(clothes_dryer, 'CombinedEnergyFactor', @combined_energy_factor, :float, @combined_energy_factor_isdefaulted) unless @combined_energy_factor.nil?
      XMLHelper.add_element(clothes_dryer, 'ControlType', @control_type, :string, @control_type_isdefaulted) unless @control_type.nil?
      XMLHelper.add_element(clothes_dryer, 'Vented', @is_vented, :boolean, @is_vented_isdefaulted) unless @is_vented.nil?
      XMLHelper.add_element(clothes_dryer, 'VentedFlowRate', @vented_flow_rate, :float, @vented_flow_rate_isdefaulted) unless @vented_flow_rate.nil?
      XMLHelper.add_extension(clothes_dryer, 'UsageMultiplier', @usage_multiplier, :float, @usage_multiplier_isdefaulted) unless @usage_multiplier.nil?
      XMLHelper.add_extension(clothes_dryer, 'WeekdayScheduleFractions', @weekday_fractions, :string, @weekday_fractions_isdefaulted) unless @weekday_fractions.nil?
      XMLHelper.add_extension(clothes_dryer, 'WeekendScheduleFractions', @weekend_fractions, :string, @weekend_fractions_isdefaulted) unless @weekend_fractions.nil?
      XMLHelper.add_extension(clothes_dryer, 'MonthlyScheduleMultipliers', @monthly_multipliers, :string, @monthly_multipliers_isdefaulted) unless @monthly_multipliers.nil?
    end

    def from_doc(clothes_dryer)
      return if clothes_dryer.nil?

      @id = HPXML::get_id(clothes_dryer)
      @count = XMLHelper.get_value(clothes_dryer, 'Count', :integer)
      @is_shared_appliance = XMLHelper.get_value(clothes_dryer, 'IsSharedAppliance', :boolean)
      @number_of_units_served = XMLHelper.get_value(clothes_dryer, 'NumberofUnitsServed', :integer)
      @location = XMLHelper.get_value(clothes_dryer, 'Location', :string)
      @fuel_type = XMLHelper.get_value(clothes_dryer, 'FuelType', :string)
      @energy_factor = XMLHelper.get_value(clothes_dryer, 'EnergyFactor', :float)
      @combined_energy_factor = XMLHelper.get_value(clothes_dryer, 'CombinedEnergyFactor', :float)
      @control_type = XMLHelper.get_value(clothes_dryer, 'ControlType', :string)
      @is_vented = XMLHelper.get_value(clothes_dryer, 'Vented', :boolean)
      @vented_flow_rate = XMLHelper.get_value(clothes_dryer, 'VentedFlowRate', :float)
      @usage_multiplier = XMLHelper.get_value(clothes_dryer, 'extension/UsageMultiplier', :float)
      @weekday_fractions = XMLHelper.get_value(clothes_dryer, 'extension/WeekdayScheduleFractions', :string)
      @weekend_fractions = XMLHelper.get_value(clothes_dryer, 'extension/WeekendScheduleFractions', :string)
      @monthly_multipliers = XMLHelper.get_value(clothes_dryer, 'extension/MonthlyScheduleMultipliers', :string)
    end
  end

  class Dishwashers < BaseArrayElement
    def add(**kwargs)
      self << Dishwasher.new(@parent_object, **kwargs)
    end

    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/Appliances/Dishwasher').each do |dishwasher|
        self << Dishwasher.new(@parent_object, dishwasher)
      end
    end
  end

  class Dishwasher < BaseElement
    ATTRS = [:id, :location, :energy_factor, :rated_annual_kwh, :place_setting_capacity,
             :label_electric_rate, :label_gas_rate, :label_annual_gas_cost, :label_usage,
             :usage_multiplier, :is_shared_appliance, :water_heating_system_idref,
             :hot_water_distribution_idref, :weekday_fractions, :weekend_fractions, :monthly_multipliers]
    attr_accessor(*ATTRS)

    def water_heating_system
      return if @water_heating_system_idref.nil?

      @parent_object.water_heating_systems.each do |water_heater|
        next unless water_heater.id == @water_heating_system_idref

        return water_heater
      end
      fail "Attached water heating system '#{@water_heating_system_idref}' not found for dishwasher '#{@id}'."
    end

    def hot_water_distribution
      return if @hot_water_distribution_idref.nil?

      @parent_object.hot_water_distributions.each do |hot_water_distribution|
        next unless hot_water_distribution.id == @hot_water_distribution_idref

        return hot_water_distribution
      end
      fail "Attached hot water distribution '#{@hot_water_distribution_idref}' not found for dishwasher '#{@id}'."
    end

    def delete
      @parent_object.dishwashers.delete(self)
    end

    def check_for_errors
      errors = []
      begin; water_heating_system; rescue StandardError => e; errors << e.message; end
      begin; hot_water_distribution; rescue StandardError => e; errors << e.message; end
      return errors
    end

    def to_doc(building)
      return if nil?

      appliances = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Appliances'])
      dishwasher = XMLHelper.add_element(appliances, 'Dishwasher')
      sys_id = XMLHelper.add_element(dishwasher, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_element(dishwasher, 'IsSharedAppliance', @is_shared_appliance, :boolean, @is_shared_appliance_isdefaulted) unless @is_shared_appliance.nil?
      if not @water_heating_system_idref.nil?
        attached_water_heater = XMLHelper.add_element(dishwasher, 'AttachedToWaterHeatingSystem')
        XMLHelper.add_attribute(attached_water_heater, 'idref', @water_heating_system_idref)
      elsif not @hot_water_distribution_idref.nil?
        attached_hot_water_dist = XMLHelper.add_element(dishwasher, 'AttachedToHotWaterDistribution')
        XMLHelper.add_attribute(attached_hot_water_dist, 'idref', @hot_water_distribution_idref)
      end
      XMLHelper.add_element(dishwasher, 'Location', @location, :string, @location_isdefaulted) unless @location.nil?
      XMLHelper.add_element(dishwasher, 'RatedAnnualkWh', @rated_annual_kwh, :float, @rated_annual_kwh_isdefaulted) unless @rated_annual_kwh.nil?
      XMLHelper.add_element(dishwasher, 'EnergyFactor', @energy_factor, :float) unless @energy_factor.nil?
      XMLHelper.add_element(dishwasher, 'PlaceSettingCapacity', @place_setting_capacity, :integer, @place_setting_capacity_isdefaulted) unless @place_setting_capacity.nil?
      XMLHelper.add_element(dishwasher, 'LabelElectricRate', @label_electric_rate, :float, @label_electric_rate_isdefaulted) unless @label_electric_rate.nil?
      XMLHelper.add_element(dishwasher, 'LabelGasRate', @label_gas_rate, :float, @label_gas_rate_isdefaulted) unless @label_gas_rate.nil?
      XMLHelper.add_element(dishwasher, 'LabelAnnualGasCost', @label_annual_gas_cost, :float, @label_annual_gas_cost_isdefaulted) unless @label_annual_gas_cost.nil?
      XMLHelper.add_element(dishwasher, 'LabelUsage', @label_usage, :float, @label_usage_isdefaulted) unless @label_usage.nil?
      XMLHelper.add_extension(dishwasher, 'UsageMultiplier', @usage_multiplier, :float, @usage_multiplier_isdefaulted) unless @usage_multiplier.nil?
      XMLHelper.add_extension(dishwasher, 'WeekdayScheduleFractions', @weekday_fractions, :string, @weekday_fractions_isdefaulted) unless @weekday_fractions.nil?
      XMLHelper.add_extension(dishwasher, 'WeekendScheduleFractions', @weekend_fractions, :string, @weekend_fractions_isdefaulted) unless @weekend_fractions.nil?
      XMLHelper.add_extension(dishwasher, 'MonthlyScheduleMultipliers', @monthly_multipliers, :string, @monthly_multipliers_isdefaulted) unless @monthly_multipliers.nil?
    end

    def from_doc(dishwasher)
      return if dishwasher.nil?

      @id = HPXML::get_id(dishwasher)
      @is_shared_appliance = XMLHelper.get_value(dishwasher, 'IsSharedAppliance', :boolean)
      @water_heating_system_idref = HPXML::get_idref(XMLHelper.get_element(dishwasher, 'AttachedToWaterHeatingSystem'))
      @hot_water_distribution_idref = HPXML::get_idref(XMLHelper.get_element(dishwasher, 'AttachedToHotWaterDistribution'))
      @location = XMLHelper.get_value(dishwasher, 'Location', :string)
      @rated_annual_kwh = XMLHelper.get_value(dishwasher, 'RatedAnnualkWh', :float)
      @energy_factor = XMLHelper.get_value(dishwasher, 'EnergyFactor', :float)
      @place_setting_capacity = XMLHelper.get_value(dishwasher, 'PlaceSettingCapacity', :integer)
      @label_electric_rate = XMLHelper.get_value(dishwasher, 'LabelElectricRate', :float)
      @label_gas_rate = XMLHelper.get_value(dishwasher, 'LabelGasRate', :float)
      @label_annual_gas_cost = XMLHelper.get_value(dishwasher, 'LabelAnnualGasCost', :float)
      @label_usage = XMLHelper.get_value(dishwasher, 'LabelUsage', :float)
      @usage_multiplier = XMLHelper.get_value(dishwasher, 'extension/UsageMultiplier', :float)
      @weekday_fractions = XMLHelper.get_value(dishwasher, 'extension/WeekdayScheduleFractions', :string)
      @weekend_fractions = XMLHelper.get_value(dishwasher, 'extension/WeekendScheduleFractions', :string)
      @monthly_multipliers = XMLHelper.get_value(dishwasher, 'extension/MonthlyScheduleMultipliers', :string)
    end
  end

  class Refrigerators < BaseArrayElement
    def add(**kwargs)
      self << Refrigerator.new(@parent_object, **kwargs)
    end

    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/Appliances/Refrigerator').each do |refrigerator|
        self << Refrigerator.new(@parent_object, refrigerator)
      end
    end
  end

  class Refrigerator < BaseElement
    ATTRS = [:id, :location, :rated_annual_kwh, :usage_multiplier, :primary_indicator,
             :weekday_fractions, :weekend_fractions, :monthly_multipliers,
             :constant_coefficients, :temperature_coefficients]
    attr_accessor(*ATTRS)

    def delete
      @parent_object.refrigerators.delete(self)
    end

    def check_for_errors
      errors = []
      return errors
    end

    def to_doc(building)
      return if nil?

      appliances = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Appliances'])
      refrigerator = XMLHelper.add_element(appliances, 'Refrigerator')
      sys_id = XMLHelper.add_element(refrigerator, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_element(refrigerator, 'Location', @location, :string, @location_isdefaulted) unless @location.nil?
      XMLHelper.add_element(refrigerator, 'RatedAnnualkWh', @rated_annual_kwh, :float, @rated_annual_kwh_isdefaulted) unless @rated_annual_kwh.nil?
      XMLHelper.add_element(refrigerator, 'PrimaryIndicator', @primary_indicator, :boolean, @primary_indicator_isdefaulted) unless @primary_indicator.nil?
      XMLHelper.add_extension(refrigerator, 'UsageMultiplier', @usage_multiplier, :float, @usage_multiplier_isdefaulted) unless @usage_multiplier.nil?
      XMLHelper.add_extension(refrigerator, 'WeekdayScheduleFractions', @weekday_fractions, :string, @weekday_fractions_isdefaulted) unless @weekday_fractions.nil?
      XMLHelper.add_extension(refrigerator, 'WeekendScheduleFractions', @weekend_fractions, :string, @weekend_fractions_isdefaulted) unless @weekend_fractions.nil?
      XMLHelper.add_extension(refrigerator, 'MonthlyScheduleMultipliers', @monthly_multipliers, :string, @monthly_multipliers_isdefaulted) unless @monthly_multipliers.nil?
      XMLHelper.add_extension(refrigerator, 'ConstantScheduleCoefficients', @constant_coefficients, :string, @constant_coefficients_isdefaulted) unless @constant_coefficients.nil?
      XMLHelper.add_extension(refrigerator, 'TemperatureScheduleCoefficients', @temperature_coefficients, :string, @temperature_coefficients_isdefaulted) unless @temperature_coefficients.nil?
    end

    def from_doc(refrigerator)
      return if refrigerator.nil?

      @id = HPXML::get_id(refrigerator)
      @location = XMLHelper.get_value(refrigerator, 'Location', :string)
      @rated_annual_kwh = XMLHelper.get_value(refrigerator, 'RatedAnnualkWh', :float)
      @primary_indicator = XMLHelper.get_value(refrigerator, 'PrimaryIndicator', :boolean)
      @usage_multiplier = XMLHelper.get_value(refrigerator, 'extension/UsageMultiplier', :float)
      @weekday_fractions = XMLHelper.get_value(refrigerator, 'extension/WeekdayScheduleFractions', :string)
      @weekend_fractions = XMLHelper.get_value(refrigerator, 'extension/WeekendScheduleFractions', :string)
      @monthly_multipliers = XMLHelper.get_value(refrigerator, 'extension/MonthlyScheduleMultipliers', :string)
      @constant_coefficients = XMLHelper.get_value(refrigerator, 'extension/ConstantScheduleCoefficients', :string)
      @temperature_coefficients = XMLHelper.get_value(refrigerator, 'extension/TemperatureScheduleCoefficients', :string)
    end
  end

  class Freezers < BaseArrayElement
    def add(**kwargs)
      self << Freezer.new(@parent_object, **kwargs)
    end

    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/Appliances/Freezer').each do |freezer|
        self << Freezer.new(@parent_object, freezer)
      end
    end
  end

  class Freezer < BaseElement
    ATTRS = [:id, :location, :rated_annual_kwh, :usage_multiplier,
             :weekday_fractions, :weekend_fractions, :monthly_multipliers,
             :constant_coefficients, :temperature_coefficients]
    attr_accessor(*ATTRS)

    def delete
      @parent_object.freezers.delete(self)
    end

    def check_for_errors
      errors = []
      return errors
    end

    def to_doc(building)
      return if nil?

      appliances = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Appliances'])
      freezer = XMLHelper.add_element(appliances, 'Freezer')
      sys_id = XMLHelper.add_element(freezer, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_element(freezer, 'Location', @location, :string, @location_isdefaulted) unless @location.nil?
      XMLHelper.add_element(freezer, 'RatedAnnualkWh', @rated_annual_kwh, :float, @rated_annual_kwh_isdefaulted) unless @rated_annual_kwh.nil?
      XMLHelper.add_extension(freezer, 'UsageMultiplier', @usage_multiplier, :float, @usage_multiplier_isdefaulted) unless @usage_multiplier.nil?
      XMLHelper.add_extension(freezer, 'WeekdayScheduleFractions', @weekday_fractions, :string, @weekday_fractions_isdefaulted) unless @weekday_fractions.nil?
      XMLHelper.add_extension(freezer, 'WeekendScheduleFractions', @weekend_fractions, :string, @weekend_fractions_isdefaulted) unless @weekend_fractions.nil?
      XMLHelper.add_extension(freezer, 'MonthlyScheduleMultipliers', @monthly_multipliers, :string, @monthly_multipliers_isdefaulted) unless @monthly_multipliers.nil?
      XMLHelper.add_extension(freezer, 'ConstantScheduleCoefficients', @constant_coefficients, :string, @constant_coefficients_isdefaulted) unless @constant_coefficients.nil?
      XMLHelper.add_extension(freezer, 'TemperatureScheduleCoefficients', @temperature_coefficients, :string, @temperature_coefficients_isdefaulted) unless @temperature_coefficients.nil?
    end

    def from_doc(freezer)
      return if freezer.nil?

      @id = HPXML::get_id(freezer)
      @location = XMLHelper.get_value(freezer, 'Location', :string)
      @rated_annual_kwh = XMLHelper.get_value(freezer, 'RatedAnnualkWh', :float)
      @usage_multiplier = XMLHelper.get_value(freezer, 'extension/UsageMultiplier', :float)
      @weekday_fractions = XMLHelper.get_value(freezer, 'extension/WeekdayScheduleFractions', :string)
      @weekend_fractions = XMLHelper.get_value(freezer, 'extension/WeekendScheduleFractions', :string)
      @monthly_multipliers = XMLHelper.get_value(freezer, 'extension/MonthlyScheduleMultipliers', :string)
      @constant_coefficients = XMLHelper.get_value(freezer, 'extension/ConstantScheduleCoefficients', :string)
      @temperature_coefficients = XMLHelper.get_value(freezer, 'extension/TemperatureScheduleCoefficients', :string)
    end
  end

  class Dehumidifiers < BaseArrayElement
    def add(**kwargs)
      self << Dehumidifier.new(@parent_object, **kwargs)
    end

    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/Appliances/Dehumidifier').each do |dehumidifier|
        self << Dehumidifier.new(@parent_object, dehumidifier)
      end
    end
  end

  class Dehumidifier < BaseElement
    ATTRS = [:id, :type, :capacity, :energy_factor, :integrated_energy_factor, :rh_setpoint, :fraction_served,
             :location]
    attr_accessor(*ATTRS)

    def delete
      @parent_object.dehumidifiers.delete(self)
    end

    def check_for_errors
      errors = []
      return errors
    end

    def to_doc(building)
      return if nil?

      appliances = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Appliances'])
      dehumidifier = XMLHelper.add_element(appliances, 'Dehumidifier')
      sys_id = XMLHelper.add_element(dehumidifier, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_element(dehumidifier, 'Type', @type, :string) unless @type.nil?
      XMLHelper.add_element(dehumidifier, 'Location', @location, :string) unless @location.nil?
      XMLHelper.add_element(dehumidifier, 'Capacity', @capacity, :float) unless @capacity.nil?
      XMLHelper.add_element(dehumidifier, 'EnergyFactor', @energy_factor, :float) unless @energy_factor.nil?
      XMLHelper.add_element(dehumidifier, 'IntegratedEnergyFactor', @integrated_energy_factor, :float) unless @integrated_energy_factor.nil?
      XMLHelper.add_element(dehumidifier, 'DehumidistatSetpoint', @rh_setpoint, :float) unless @rh_setpoint.nil?
      XMLHelper.add_element(dehumidifier, 'FractionDehumidificationLoadServed', @fraction_served, :float) unless @fraction_served.nil?
    end

    def from_doc(dehumidifier)
      return if dehumidifier.nil?

      @id = HPXML::get_id(dehumidifier)
      @type = XMLHelper.get_value(dehumidifier, 'Type', :string)
      @location = XMLHelper.get_value(dehumidifier, 'Location', :string)
      @capacity = XMLHelper.get_value(dehumidifier, 'Capacity', :float)
      @energy_factor = XMLHelper.get_value(dehumidifier, 'EnergyFactor', :float)
      @integrated_energy_factor = XMLHelper.get_value(dehumidifier, 'IntegratedEnergyFactor', :float)
      @rh_setpoint = XMLHelper.get_value(dehumidifier, 'DehumidistatSetpoint', :float)
      @fraction_served = XMLHelper.get_value(dehumidifier, 'FractionDehumidificationLoadServed', :float)
    end
  end

  class CookingRanges < BaseArrayElement
    def add(**kwargs)
      self << CookingRange.new(@parent_object, **kwargs)
    end

    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/Appliances/CookingRange').each do |cooking_range|
        self << CookingRange.new(@parent_object, cooking_range)
      end
    end
  end

  class CookingRange < BaseElement
    ATTRS = [:id, :location, :fuel_type, :is_induction, :usage_multiplier,
             :weekday_fractions, :weekend_fractions, :monthly_multipliers]
    attr_accessor(*ATTRS)

    def delete
      @parent_object.cooking_ranges.delete(self)
    end

    def check_for_errors
      errors = []
      return errors
    end

    def to_doc(building)
      return if nil?

      appliances = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Appliances'])
      cooking_range = XMLHelper.add_element(appliances, 'CookingRange')
      sys_id = XMLHelper.add_element(cooking_range, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_element(cooking_range, 'Location', @location, :string, @location_isdefaulted) unless @location.nil?
      XMLHelper.add_element(cooking_range, 'FuelType', @fuel_type, :string) unless @fuel_type.nil?
      XMLHelper.add_element(cooking_range, 'IsInduction', @is_induction, :boolean, @is_induction_isdefaulted) unless @is_induction.nil?
      XMLHelper.add_extension(cooking_range, 'UsageMultiplier', @usage_multiplier, :float, @usage_multiplier_isdefaulted) unless @usage_multiplier.nil?
      XMLHelper.add_extension(cooking_range, 'WeekdayScheduleFractions', @weekday_fractions, :string, @weekday_fractions_isdefaulted) unless @weekday_fractions.nil?
      XMLHelper.add_extension(cooking_range, 'WeekendScheduleFractions', @weekend_fractions, :string, @weekend_fractions_isdefaulted) unless @weekend_fractions.nil?
      XMLHelper.add_extension(cooking_range, 'MonthlyScheduleMultipliers', @monthly_multipliers, :string, @monthly_multipliers_isdefaulted) unless @monthly_multipliers.nil?
    end

    def from_doc(cooking_range)
      return if cooking_range.nil?

      @id = HPXML::get_id(cooking_range)
      @location = XMLHelper.get_value(cooking_range, 'Location', :string)
      @fuel_type = XMLHelper.get_value(cooking_range, 'FuelType', :string)
      @is_induction = XMLHelper.get_value(cooking_range, 'IsInduction', :boolean)
      @usage_multiplier = XMLHelper.get_value(cooking_range, 'extension/UsageMultiplier', :float)
      @weekday_fractions = XMLHelper.get_value(cooking_range, 'extension/WeekdayScheduleFractions', :string)
      @weekend_fractions = XMLHelper.get_value(cooking_range, 'extension/WeekendScheduleFractions', :string)
      @monthly_multipliers = XMLHelper.get_value(cooking_range, 'extension/MonthlyScheduleMultipliers', :string)
    end
  end

  class Ovens < BaseArrayElement
    def add(**kwargs)
      self << Oven.new(@parent_object, **kwargs)
    end

    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/Appliances/Oven').each do |oven|
        self << Oven.new(@parent_object, oven)
      end
    end
  end

  class Oven < BaseElement
    ATTRS = [:id, :is_convection]
    attr_accessor(*ATTRS)

    def delete
      @parent_object.ovens.delete(self)
    end

    def check_for_errors
      errors = []
      return errors
    end

    def to_doc(building)
      return if nil?

      appliances = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Appliances'])
      oven = XMLHelper.add_element(appliances, 'Oven')
      sys_id = XMLHelper.add_element(oven, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_element(oven, 'IsConvection', @is_convection, :boolean, @is_convection_isdefaulted) unless @is_convection.nil?
    end

    def from_doc(oven)
      return if oven.nil?

      @id = HPXML::get_id(oven)
      @is_convection = XMLHelper.get_value(oven, 'IsConvection', :boolean)
    end
  end

  class LightingGroups < BaseArrayElement
    def add(**kwargs)
      self << LightingGroup.new(@parent_object, **kwargs)
    end

    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/Lighting/LightingGroup').each do |lighting_group|
        self << LightingGroup.new(@parent_object, lighting_group)
      end
    end
  end

  class LightingGroup < BaseElement
    ATTRS = [:id, :location, :fraction_of_units_in_location, :lighting_type, :kwh_per_year]
    attr_accessor(*ATTRS)

    def delete
      @parent_object.lighting_groups.delete(self)
    end

    def check_for_errors
      errors = []
      return errors
    end

    def to_doc(building)
      return if nil?

      lighting = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Lighting'])
      lighting_group = XMLHelper.add_element(lighting, 'LightingGroup')
      sys_id = XMLHelper.add_element(lighting_group, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_element(lighting_group, 'Location', @location, :string) unless @location.nil?
      XMLHelper.add_element(lighting_group, 'FractionofUnitsInLocation', @fraction_of_units_in_location, :float) unless @fraction_of_units_in_location.nil?
      if not @lighting_type.nil?
        lighting_type = XMLHelper.add_element(lighting_group, 'LightingType')
        XMLHelper.add_element(lighting_type, @lighting_type)
      end
      if not @kwh_per_year.nil?
        lighting_load = XMLHelper.add_element(lighting_group, 'Load')
        XMLHelper.add_element(lighting_load, 'Units', UnitsKwhPerYear, :string)
        XMLHelper.add_element(lighting_load, 'Value', @kwh_per_year, :float, @kwh_per_year_isdefaulted)
      end
    end

    def from_doc(lighting_group)
      return if lighting_group.nil?

      @id = HPXML::get_id(lighting_group)
      @location = XMLHelper.get_value(lighting_group, 'Location', :string)
      @fraction_of_units_in_location = XMLHelper.get_value(lighting_group, 'FractionofUnitsInLocation', :float)
      @lighting_type = XMLHelper.get_child_name(lighting_group, 'LightingType')
      @kwh_per_year = XMLHelper.get_value(lighting_group, "Load[Units='#{UnitsKwhPerYear}']/Value", :float)
    end
  end

  class Lighting < BaseElement
    ATTRS = [:interior_usage_multiplier, :garage_usage_multiplier, :exterior_usage_multiplier,
             :interior_weekday_fractions, :interior_weekend_fractions, :interior_monthly_multipliers,
             :garage_weekday_fractions, :garage_weekend_fractions, :garage_monthly_multipliers,
             :exterior_weekday_fractions, :exterior_weekend_fractions, :exterior_monthly_multipliers,
             :holiday_exists, :holiday_kwh_per_day, :holiday_period_begin_month, :holiday_period_begin_day,
             :holiday_period_end_month, :holiday_period_end_day, :holiday_weekday_fractions, :holiday_weekend_fractions]
    attr_accessor(*ATTRS)

    def check_for_errors
      errors = []

      errors += HPXML::check_dates('Exterior Holiday Lighting', @holiday_period_begin_month, @holiday_period_begin_day, @holiday_period_end_month, @holiday_period_end_day)

      return errors
    end

    def to_doc(building)
      return if nil?

      lighting = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Lighting'])
      XMLHelper.add_extension(lighting, 'InteriorUsageMultiplier', @interior_usage_multiplier, :float, @interior_usage_multiplier_isdefaulted) unless @interior_usage_multiplier.nil?
      XMLHelper.add_extension(lighting, 'GarageUsageMultiplier', @garage_usage_multiplier, :float, @garage_usage_multiplier_isdefaulted) unless @garage_usage_multiplier.nil?
      XMLHelper.add_extension(lighting, 'ExteriorUsageMultiplier', @exterior_usage_multiplier, :float, @exterior_usage_multiplier_isdefaulted) unless @exterior_usage_multiplier.nil?
      XMLHelper.add_extension(lighting, 'InteriorWeekdayScheduleFractions', @interior_weekday_fractions, :string, @interior_weekday_fractions_isdefaulted) unless @interior_weekday_fractions.nil?
      XMLHelper.add_extension(lighting, 'InteriorWeekendScheduleFractions', @interior_weekend_fractions, :string, @interior_weekend_fractions_isdefaulted) unless @interior_weekend_fractions.nil?
      XMLHelper.add_extension(lighting, 'InteriorMonthlyScheduleMultipliers', @interior_monthly_multipliers, :string, @interior_monthly_multipliers_isdefaulted) unless @interior_monthly_multipliers.nil?
      XMLHelper.add_extension(lighting, 'GarageWeekdayScheduleFractions', @garage_weekday_fractions, :string, @garage_weekday_fractions_isdefaulted) unless @garage_weekday_fractions.nil?
      XMLHelper.add_extension(lighting, 'GarageWeekendScheduleFractions', @garage_weekend_fractions, :string, @garage_weekend_fractions_isdefaulted) unless @garage_weekend_fractions.nil?
      XMLHelper.add_extension(lighting, 'GarageMonthlyScheduleMultipliers', @garage_monthly_multipliers, :string, @garage_monthly_multipliers_isdefaulted) unless @garage_monthly_multipliers.nil?
      XMLHelper.add_extension(lighting, 'ExteriorWeekdayScheduleFractions', @exterior_weekday_fractions, :string, @exterior_weekday_fractions_isdefaulted) unless @exterior_weekday_fractions.nil?
      XMLHelper.add_extension(lighting, 'ExteriorWeekendScheduleFractions', @exterior_weekend_fractions, :string, @exterior_weekend_fractions_isdefaulted) unless @exterior_weekend_fractions.nil?
      XMLHelper.add_extension(lighting, 'ExteriorMonthlyScheduleMultipliers', @exterior_monthly_multipliers, :string, @exterior_monthly_multipliers_isdefaulted) unless @exterior_monthly_multipliers.nil?
      if @holiday_exists
        exterior_holiday_lighting = XMLHelper.create_elements_as_needed(lighting, ['extension', 'ExteriorHolidayLighting'])
        if not @holiday_kwh_per_day.nil?
          holiday_lighting_load = XMLHelper.add_element(exterior_holiday_lighting, 'Load')
          XMLHelper.add_element(holiday_lighting_load, 'Units', UnitsKwhPerDay, :string)
          XMLHelper.add_element(holiday_lighting_load, 'Value', @holiday_kwh_per_day, :float, @holiday_kwh_per_day_isdefaulted)
        end
        XMLHelper.add_element(exterior_holiday_lighting, 'PeriodBeginMonth', @holiday_period_begin_month, :integer, @holiday_period_begin_month_isdefaulted) unless @holiday_period_begin_month.nil?
        XMLHelper.add_element(exterior_holiday_lighting, 'PeriodBeginDayOfMonth', @holiday_period_begin_day, :integer, @holiday_period_begin_day_isdefaulted) unless @holiday_period_begin_day.nil?
        XMLHelper.add_element(exterior_holiday_lighting, 'PeriodEndMonth', @holiday_period_end_month, :integer, @holiday_period_end_month_isdefaulted) unless @holiday_period_end_month.nil?
        XMLHelper.add_element(exterior_holiday_lighting, 'PeriodEndDayOfMonth', @holiday_period_end_day, :integer, @holiday_period_end_day_isdefaulted) unless @holiday_period_end_day.nil?
        XMLHelper.add_element(exterior_holiday_lighting, 'WeekdayScheduleFractions', @holiday_weekday_fractions, :string, @holiday_weekday_fractions_isdefaulted) unless @holiday_weekday_fractions.nil?
        XMLHelper.add_element(exterior_holiday_lighting, 'WeekendScheduleFractions', @holiday_weekend_fractions, :string, @holiday_weekend_fractions_isdefaulted) unless @holiday_weekend_fractions.nil?
      end
    end

    def from_doc(building)
      return if building.nil?

      lighting = XMLHelper.get_element(building, 'BuildingDetails/Lighting')
      return if lighting.nil?

      @interior_usage_multiplier = XMLHelper.get_value(lighting, 'extension/InteriorUsageMultiplier', :float)
      @garage_usage_multiplier = XMLHelper.get_value(lighting, 'extension/GarageUsageMultiplier', :float)
      @exterior_usage_multiplier = XMLHelper.get_value(lighting, 'extension/ExteriorUsageMultiplier', :float)
      @interior_weekday_fractions = XMLHelper.get_value(lighting, 'extension/InteriorWeekdayScheduleFractions', :string)
      @interior_weekend_fractions = XMLHelper.get_value(lighting, 'extension/InteriorWeekendScheduleFractions', :string)
      @interior_monthly_multipliers = XMLHelper.get_value(lighting, 'extension/InteriorMonthlyScheduleMultipliers', :string)
      @garage_weekday_fractions = XMLHelper.get_value(lighting, 'extension/GarageWeekdayScheduleFractions', :string)
      @garage_weekend_fractions = XMLHelper.get_value(lighting, 'extension/GarageWeekendScheduleFractions', :string)
      @garage_monthly_multipliers = XMLHelper.get_value(lighting, 'extension/GarageMonthlyScheduleMultipliers', :string)
      @exterior_weekday_fractions = XMLHelper.get_value(lighting, 'extension/ExteriorWeekdayScheduleFractions', :string)
      @exterior_weekend_fractions = XMLHelper.get_value(lighting, 'extension/ExteriorWeekendScheduleFractions', :string)
      @exterior_monthly_multipliers = XMLHelper.get_value(lighting, 'extension/ExteriorMonthlyScheduleMultipliers', :string)
      if not XMLHelper.get_element(building, 'BuildingDetails/Lighting/extension/ExteriorHolidayLighting').nil?
        @holiday_exists = true
        @holiday_kwh_per_day = XMLHelper.get_value(lighting, "extension/ExteriorHolidayLighting/Load[Units='#{UnitsKwhPerDay}']/Value", :float)
        @holiday_period_begin_month = XMLHelper.get_value(lighting, 'extension/ExteriorHolidayLighting/PeriodBeginMonth', :integer)
        @holiday_period_begin_day = XMLHelper.get_value(lighting, 'extension/ExteriorHolidayLighting/PeriodBeginDayOfMonth', :integer)
        @holiday_period_end_month = XMLHelper.get_value(lighting, 'extension/ExteriorHolidayLighting/PeriodEndMonth', :integer)
        @holiday_period_end_day = XMLHelper.get_value(lighting, 'extension/ExteriorHolidayLighting/PeriodEndDayOfMonth', :integer)
        @holiday_weekday_fractions = XMLHelper.get_value(lighting, 'extension/ExteriorHolidayLighting/WeekdayScheduleFractions', :string)
        @holiday_weekend_fractions = XMLHelper.get_value(lighting, 'extension/ExteriorHolidayLighting/WeekendScheduleFractions', :string)
      else
        @holiday_exists = false
      end
    end
  end

  class CeilingFans < BaseArrayElement
    def add(**kwargs)
      self << CeilingFan.new(@parent_object, **kwargs)
    end

    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/Lighting/CeilingFan').each do |ceiling_fan|
        self << CeilingFan.new(@parent_object, ceiling_fan)
      end
    end
  end

  class CeilingFan < BaseElement
    ATTRS = [:id, :efficiency, :count, :weekday_fractions, :weekend_fractions, :monthly_multipliers]
    attr_accessor(*ATTRS)

    def delete
      @parent_object.ceiling_fans.delete(self)
    end

    def check_for_errors
      errors = []
      return errors
    end

    def to_doc(building)
      return if nil?

      lighting = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Lighting'])
      ceiling_fan = XMLHelper.add_element(lighting, 'CeilingFan')
      sys_id = XMLHelper.add_element(ceiling_fan, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      if not @efficiency.nil?
        airflow = XMLHelper.add_element(ceiling_fan, 'Airflow')
        XMLHelper.add_element(airflow, 'FanSpeed', 'medium', :string)
        XMLHelper.add_element(airflow, 'Efficiency', @efficiency, :float, @efficiency_isdefaulted)
      end
      XMLHelper.add_element(ceiling_fan, 'Count', @count, :integer, @count_isdefaulted) unless @count.nil?
      XMLHelper.add_extension(ceiling_fan, 'WeekdayScheduleFractions', @weekday_fractions, :string, @weekday_fractions_isdefaulted) unless @weekday_fractions.nil?
      XMLHelper.add_extension(ceiling_fan, 'WeekendScheduleFractions', @weekend_fractions, :string, @weekend_fractions_isdefaulted) unless @weekend_fractions.nil?
      XMLHelper.add_extension(ceiling_fan, 'MonthlyScheduleMultipliers', @monthly_multipliers, :string, @monthly_multipliers_isdefaulted) unless @monthly_multipliers.nil?
    end

    def from_doc(ceiling_fan)
      @id = HPXML::get_id(ceiling_fan)
      @efficiency = XMLHelper.get_value(ceiling_fan, "Airflow[FanSpeed='medium']/Efficiency", :float)
      @count = XMLHelper.get_value(ceiling_fan, 'Count', :integer)
      @weekday_fractions = XMLHelper.get_value(ceiling_fan, 'extension/WeekdayScheduleFractions', :string)
      @weekend_fractions = XMLHelper.get_value(ceiling_fan, 'extension/WeekendScheduleFractions', :string)
      @monthly_multipliers = XMLHelper.get_value(ceiling_fan, 'extension/MonthlyScheduleMultipliers', :string)
    end
  end

  class Pools < BaseArrayElement
    def add(**kwargs)
      self << Pool.new(@parent_object, **kwargs)
    end

    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/Pools/Pool').each do |pool|
        self << Pool.new(@parent_object, pool)
      end
    end
  end

  class Pool < BaseElement
    ATTRS = [:id, :type, :heater_id, :heater_type, :heater_load_units, :heater_load_value, :heater_usage_multiplier,
             :pump_id, :pump_type, :pump_kwh_per_year, :pump_usage_multiplier,
             :heater_weekday_fractions, :heater_weekend_fractions, :heater_monthly_multipliers,
             :pump_weekday_fractions, :pump_weekend_fractions, :pump_monthly_multipliers]
    attr_accessor(*ATTRS)

    def delete
      @parent_object.pools.delete(self)
    end

    def check_for_errors
      errors = []
      return errors
    end

    def to_doc(building)
      return if nil?

      pools = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Pools'])
      pool = XMLHelper.add_element(pools, 'Pool')
      sys_id = XMLHelper.add_element(pool, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_element(pool, 'Type', @type, :string) unless @type.nil?
      if @type != HPXML::TypeNone
        pumps = XMLHelper.add_element(pool, 'Pumps')
        pool_pump = XMLHelper.add_element(pumps, 'Pump')
        sys_id = XMLHelper.add_element(pool_pump, 'SystemIdentifier')
        if not @pump_id.nil?
          XMLHelper.add_attribute(sys_id, 'id', @pump_id)
        else
          XMLHelper.add_attribute(sys_id, 'id', @id + 'Pump')
        end
        XMLHelper.add_element(pool_pump, 'Type', @pump_type, :string)
        if @pump_type != HPXML::TypeNone
          if not @pump_kwh_per_year.nil?
            load = XMLHelper.add_element(pool_pump, 'Load')
            XMLHelper.add_element(load, 'Units', UnitsKwhPerYear, :string)
            XMLHelper.add_element(load, 'Value', @pump_kwh_per_year, :float, @pump_kwh_per_year_isdefaulted)
          end
          XMLHelper.add_extension(pool_pump, 'UsageMultiplier', @pump_usage_multiplier, :float, @pump_usage_multiplier_isdefaulted) unless @pump_usage_multiplier.nil?
          XMLHelper.add_extension(pool_pump, 'WeekdayScheduleFractions', @pump_weekday_fractions, :string, @pump_weekday_fractions_isdefaulted) unless @pump_weekday_fractions.nil?
          XMLHelper.add_extension(pool_pump, 'WeekendScheduleFractions', @pump_weekend_fractions, :string, @pump_weekend_fractions_isdefaulted) unless @pump_weekend_fractions.nil?
          XMLHelper.add_extension(pool_pump, 'MonthlyScheduleMultipliers', @pump_monthly_multipliers, :string, @pump_monthly_multipliers_isdefaulted) unless @pump_monthly_multipliers.nil?
        end
        heater = XMLHelper.add_element(pool, 'Heater')
        sys_id = XMLHelper.add_element(heater, 'SystemIdentifier')
        if not @heater_id.nil?
          XMLHelper.add_attribute(sys_id, 'id', @heater_id)
        else
          XMLHelper.add_attribute(sys_id, 'id', @id + 'Heater')
        end
        XMLHelper.add_element(heater, 'Type', @heater_type, :string)
        if @heater_type != HPXML::TypeNone
          if (not @heater_load_units.nil?) && (not @heater_load_value.nil?)
            load = XMLHelper.add_element(heater, 'Load')
            XMLHelper.add_element(load, 'Units', @heater_load_units, :string)
            XMLHelper.add_element(load, 'Value', @heater_load_value, :float, @heater_load_value_isdefaulted)
          end
          XMLHelper.add_extension(heater, 'UsageMultiplier', @heater_usage_multiplier, :float, @heater_usage_multiplier_isdefaulted) unless @heater_usage_multiplier.nil?
          XMLHelper.add_extension(heater, 'WeekdayScheduleFractions', @heater_weekday_fractions, :string, @heater_weekday_fractions_isdefaulted) unless @heater_weekday_fractions.nil?
          XMLHelper.add_extension(heater, 'WeekendScheduleFractions', @heater_weekend_fractions, :string, @heater_weekend_fractions_isdefaulted) unless @heater_weekend_fractions.nil?
          XMLHelper.add_extension(heater, 'MonthlyScheduleMultipliers', @heater_monthly_multipliers, :string, @heater_monthly_multipliers_isdefaulted) unless @heater_monthly_multipliers.nil?
        end
      end
    end

    def from_doc(pool)
      @id = HPXML::get_id(pool)
      @type = XMLHelper.get_value(pool, 'Type', :string)
      pool_pump = XMLHelper.get_element(pool, 'Pumps/Pump')
      if not pool_pump.nil?
        @pump_id = HPXML::get_id(pool_pump)
        @pump_type = XMLHelper.get_value(pool_pump, 'Type', :string)
        @pump_kwh_per_year = XMLHelper.get_value(pool_pump, "Load[Units='#{UnitsKwhPerYear}']/Value", :float)
        @pump_usage_multiplier = XMLHelper.get_value(pool_pump, 'extension/UsageMultiplier', :float)
        @pump_weekday_fractions = XMLHelper.get_value(pool_pump, 'extension/WeekdayScheduleFractions', :string)
        @pump_weekend_fractions = XMLHelper.get_value(pool_pump, 'extension/WeekendScheduleFractions', :string)
        @pump_monthly_multipliers = XMLHelper.get_value(pool_pump, 'extension/MonthlyScheduleMultipliers', :string)
      end
      heater = XMLHelper.get_element(pool, 'Heater')
      if not heater.nil?
        @heater_id = HPXML::get_id(heater)
        @heater_type = XMLHelper.get_value(heater, 'Type', :string)
        @heater_load_units = XMLHelper.get_value(heater, 'Load/Units', :string)
        @heater_load_value = XMLHelper.get_value(heater, 'Load/Value', :float)
        @heater_usage_multiplier = XMLHelper.get_value(heater, 'extension/UsageMultiplier', :float)
        @heater_weekday_fractions = XMLHelper.get_value(heater, 'extension/WeekdayScheduleFractions', :string)
        @heater_weekend_fractions = XMLHelper.get_value(heater, 'extension/WeekendScheduleFractions', :string)
        @heater_monthly_multipliers = XMLHelper.get_value(heater, 'extension/MonthlyScheduleMultipliers', :string)
      end
    end
  end

  class PermanentSpas < BaseArrayElement
    def add(**kwargs)
      self << PermanentSpa.new(@parent_object, **kwargs)
    end

    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/Spas/PermanentSpa').each do |spa|
        self << PermanentSpa.new(@parent_object, spa)
      end
    end
  end

  class PermanentSpa < BaseElement
    ATTRS = [:id, :type, :heater_id, :heater_type, :heater_load_units, :heater_load_value, :heater_usage_multiplier,
             :pump_id, :pump_type, :pump_kwh_per_year, :pump_usage_multiplier,
             :heater_weekday_fractions, :heater_weekend_fractions, :heater_monthly_multipliers,
             :pump_weekday_fractions, :pump_weekend_fractions, :pump_monthly_multipliers]
    attr_accessor(*ATTRS)

    def delete
      @parent_object.permanent_spas.delete(self)
    end

    def check_for_errors
      errors = []
      return errors
    end

    def to_doc(building)
      return if nil?

      spas = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Spas'])
      spa = XMLHelper.add_element(spas, 'PermanentSpa')
      sys_id = XMLHelper.add_element(spa, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_element(spa, 'Type', @type, :string) unless @type.nil?
      if @type != HPXML::TypeNone
        pumps = XMLHelper.add_element(spa, 'Pumps')
        spa_pump = XMLHelper.add_element(pumps, 'Pump')
        sys_id = XMLHelper.add_element(spa_pump, 'SystemIdentifier')
        if not @pump_id.nil?
          XMLHelper.add_attribute(sys_id, 'id', @pump_id)
        else
          XMLHelper.add_attribute(sys_id, 'id', @id + 'Pump')
        end
        XMLHelper.add_element(spa_pump, 'Type', @pump_type, :string)
        if @pump_type != HPXML::TypeNone
          if not @pump_kwh_per_year.nil?
            load = XMLHelper.add_element(spa_pump, 'Load')
            XMLHelper.add_element(load, 'Units', UnitsKwhPerYear, :string)
            XMLHelper.add_element(load, 'Value', @pump_kwh_per_year, :float, @pump_kwh_per_year_isdefaulted)
          end
          XMLHelper.add_extension(spa_pump, 'UsageMultiplier', @pump_usage_multiplier, :float, @pump_usage_multiplier_isdefaulted) unless @pump_usage_multiplier.nil?
          XMLHelper.add_extension(spa_pump, 'WeekdayScheduleFractions', @pump_weekday_fractions, :string, @pump_weekday_fractions_isdefaulted) unless @pump_weekday_fractions.nil?
          XMLHelper.add_extension(spa_pump, 'WeekendScheduleFractions', @pump_weekend_fractions, :string, @pump_weekend_fractions_isdefaulted) unless @pump_weekend_fractions.nil?
          XMLHelper.add_extension(spa_pump, 'MonthlyScheduleMultipliers', @pump_monthly_multipliers, :string, @pump_monthly_multipliers_isdefaulted) unless @pump_monthly_multipliers.nil?
        end
        heater = XMLHelper.add_element(spa, 'Heater')
        sys_id = XMLHelper.add_element(heater, 'SystemIdentifier')
        if not @heater_id.nil?
          XMLHelper.add_attribute(sys_id, 'id', @heater_id)
        else
          XMLHelper.add_attribute(sys_id, 'id', @id + 'Heater')
        end
        XMLHelper.add_element(heater, 'Type', @heater_type, :string)
        if @heater_type != HPXML::TypeNone
          if (not @heater_load_units.nil?) && (not @heater_load_value.nil?)
            load = XMLHelper.add_element(heater, 'Load')
            XMLHelper.add_element(load, 'Units', @heater_load_units, :string)
            XMLHelper.add_element(load, 'Value', @heater_load_value, :float, @heater_load_value_isdefaulted)
          end
          XMLHelper.add_extension(heater, 'UsageMultiplier', @heater_usage_multiplier, :float, @heater_usage_multiplier_isdefaulted) unless @heater_usage_multiplier.nil?
          XMLHelper.add_extension(heater, 'WeekdayScheduleFractions', @heater_weekday_fractions, :string, @heater_weekday_fractions_isdefaulted) unless @heater_weekday_fractions.nil?
          XMLHelper.add_extension(heater, 'WeekendScheduleFractions', @heater_weekend_fractions, :string, @heater_weekend_fractions_isdefaulted) unless @heater_weekend_fractions.nil?
          XMLHelper.add_extension(heater, 'MonthlyScheduleMultipliers', @heater_monthly_multipliers, :string, @heater_monthly_multipliers_isdefaulted) unless @heater_monthly_multipliers.nil?
        end
      end
    end

    def from_doc(spa)
      @id = HPXML::get_id(spa)
      @type = XMLHelper.get_value(spa, 'Type', :string)
      spa_pump = XMLHelper.get_element(spa, 'Pumps/Pump')
      if not spa_pump.nil?
        @pump_id = HPXML::get_id(spa_pump)
        @pump_type = XMLHelper.get_value(spa_pump, 'Type', :string)
        @pump_kwh_per_year = XMLHelper.get_value(spa_pump, "Load[Units='#{UnitsKwhPerYear}']/Value", :float)
        @pump_usage_multiplier = XMLHelper.get_value(spa_pump, 'extension/UsageMultiplier', :float)
        @pump_weekday_fractions = XMLHelper.get_value(spa_pump, 'extension/WeekdayScheduleFractions', :string)
        @pump_weekend_fractions = XMLHelper.get_value(spa_pump, 'extension/WeekendScheduleFractions', :string)
        @pump_monthly_multipliers = XMLHelper.get_value(spa_pump, 'extension/MonthlyScheduleMultipliers', :string)
      end
      heater = XMLHelper.get_element(spa, 'Heater')
      if not heater.nil?
        @heater_id = HPXML::get_id(heater)
        @heater_type = XMLHelper.get_value(heater, 'Type', :string)
        @heater_load_units = XMLHelper.get_value(heater, 'Load/Units', :string)
        @heater_load_value = XMLHelper.get_value(heater, 'Load/Value', :float)
        @heater_usage_multiplier = XMLHelper.get_value(heater, 'extension/UsageMultiplier', :float)
        @heater_weekday_fractions = XMLHelper.get_value(heater, 'extension/WeekdayScheduleFractions', :string)
        @heater_weekend_fractions = XMLHelper.get_value(heater, 'extension/WeekendScheduleFractions', :string)
        @heater_monthly_multipliers = XMLHelper.get_value(heater, 'extension/MonthlyScheduleMultipliers', :string)
      end
    end
  end

  class PortableSpas < BaseArrayElement
    def add(**kwargs)
      self << PortableSpa.new(@parent_object, **kwargs)
    end

    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/Spas/PortableSpa').each do |spa|
        self << PortableSpa.new(@parent_object, spa)
      end
    end
  end

  class PortableSpa < BaseElement
    ATTRS = [:id]
    attr_accessor(*ATTRS)

    def delete
      @parent_object.portable_spas.delete(self)
    end

    def check_for_errors
      errors = []
      return errors
    end

    def to_doc(building)
      return if nil?

      spas = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Spas'])
      spa = XMLHelper.add_element(spas, 'PortableSpa')
      sys_id = XMLHelper.add_element(spa, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
    end

    def from_doc(spa)
      @id = HPXML::get_id(spa)
    end
  end

  class PlugLoads < BaseArrayElement
    def add(**kwargs)
      self << PlugLoad.new(@parent_object, **kwargs)
    end

    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/MiscLoads/PlugLoad').each do |plug_load|
        self << PlugLoad.new(@parent_object, plug_load)
      end
    end
  end

  class PlugLoad < BaseElement
    ATTRS = [:id, :plug_load_type, :kwh_per_year, :frac_sensible, :frac_latent, :usage_multiplier,
             :weekday_fractions, :weekend_fractions, :monthly_multipliers]
    attr_accessor(*ATTRS)

    def delete
      @parent_object.plug_loads.delete(self)
    end

    def check_for_errors
      errors = []
      return errors
    end

    def to_doc(building)
      return if nil?

      misc_loads = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'MiscLoads'])
      plug_load = XMLHelper.add_element(misc_loads, 'PlugLoad')
      sys_id = XMLHelper.add_element(plug_load, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_element(plug_load, 'PlugLoadType', @plug_load_type, :string) unless @plug_load_type.nil?
      if not @kwh_per_year.nil?
        load = XMLHelper.add_element(plug_load, 'Load')
        XMLHelper.add_element(load, 'Units', UnitsKwhPerYear, :string)
        XMLHelper.add_element(load, 'Value', @kwh_per_year, :float, @kwh_per_year_isdefaulted)
      end
      XMLHelper.add_extension(plug_load, 'FracSensible', @frac_sensible, :float, @frac_sensible_isdefaulted) unless @frac_sensible.nil?
      XMLHelper.add_extension(plug_load, 'FracLatent', @frac_latent, :float, @frac_latent_isdefaulted) unless @frac_latent.nil?
      XMLHelper.add_extension(plug_load, 'UsageMultiplier', @usage_multiplier, :float, @usage_multiplier_isdefaulted) unless @usage_multiplier.nil?
      XMLHelper.add_extension(plug_load, 'WeekdayScheduleFractions', @weekday_fractions, :string, @weekday_fractions_isdefaulted) unless @weekday_fractions.nil?
      XMLHelper.add_extension(plug_load, 'WeekendScheduleFractions', @weekend_fractions, :string, @weekend_fractions_isdefaulted) unless @weekend_fractions.nil?
      XMLHelper.add_extension(plug_load, 'MonthlyScheduleMultipliers', @monthly_multipliers, :string, @monthly_multipliers_isdefaulted) unless @monthly_multipliers.nil?
    end

    def from_doc(plug_load)
      @id = HPXML::get_id(plug_load)
      @plug_load_type = XMLHelper.get_value(plug_load, 'PlugLoadType', :string)
      @kwh_per_year = XMLHelper.get_value(plug_load, "Load[Units='#{UnitsKwhPerYear}']/Value", :float)
      @frac_sensible = XMLHelper.get_value(plug_load, 'extension/FracSensible', :float)
      @frac_latent = XMLHelper.get_value(plug_load, 'extension/FracLatent', :float)
      @usage_multiplier = XMLHelper.get_value(plug_load, 'extension/UsageMultiplier', :float)
      @weekday_fractions = XMLHelper.get_value(plug_load, 'extension/WeekdayScheduleFractions', :string)
      @weekend_fractions = XMLHelper.get_value(plug_load, 'extension/WeekendScheduleFractions', :string)
      @monthly_multipliers = XMLHelper.get_value(plug_load, 'extension/MonthlyScheduleMultipliers', :string)
    end
  end

  class FuelLoads < BaseArrayElement
    def add(**kwargs)
      self << FuelLoad.new(@parent_object, **kwargs)
    end

    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/MiscLoads/FuelLoad').each do |fuel_load|
        self << FuelLoad.new(@parent_object, fuel_load)
      end
    end
  end

  class FuelLoad < BaseElement
    ATTRS = [:id, :fuel_load_type, :fuel_type, :therm_per_year, :frac_sensible, :frac_latent, :usage_multiplier,
             :weekday_fractions, :weekend_fractions, :monthly_multipliers]
    attr_accessor(*ATTRS)

    def delete
      @parent_object.fuel_loads.delete(self)
    end

    def check_for_errors
      errors = []
      return errors
    end

    def to_doc(building)
      return if nil?

      misc_loads = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'MiscLoads'])
      fuel_load = XMLHelper.add_element(misc_loads, 'FuelLoad')
      sys_id = XMLHelper.add_element(fuel_load, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_element(fuel_load, 'FuelLoadType', @fuel_load_type, :string) unless @fuel_load_type.nil?
      if not @therm_per_year.nil?
        load = XMLHelper.add_element(fuel_load, 'Load')
        XMLHelper.add_element(load, 'Units', UnitsThermPerYear, :string)
        XMLHelper.add_element(load, 'Value', @therm_per_year, :float, @therm_per_year_isdefaulted)
      end
      XMLHelper.add_element(fuel_load, 'FuelType', @fuel_type, :string) unless @fuel_type.nil?
      XMLHelper.add_extension(fuel_load, 'FracSensible', @frac_sensible, :float, @frac_sensible_isdefaulted) unless @frac_sensible.nil?
      XMLHelper.add_extension(fuel_load, 'FracLatent', @frac_latent, :float, @frac_latent_isdefaulted) unless @frac_latent.nil?
      XMLHelper.add_extension(fuel_load, 'UsageMultiplier', @usage_multiplier, :float, @usage_multiplier_isdefaulted) unless @usage_multiplier.nil?
      XMLHelper.add_extension(fuel_load, 'WeekdayScheduleFractions', @weekday_fractions, :string, @weekday_fractions_isdefaulted) unless @weekday_fractions.nil?
      XMLHelper.add_extension(fuel_load, 'WeekendScheduleFractions', @weekend_fractions, :string, @weekend_fractions_isdefaulted) unless @weekend_fractions.nil?
      XMLHelper.add_extension(fuel_load, 'MonthlyScheduleMultipliers', @monthly_multipliers, :string, @monthly_multipliers_isdefaulted) unless @monthly_multipliers.nil?
    end

    def from_doc(fuel_load)
      @id = HPXML::get_id(fuel_load)
      @fuel_load_type = XMLHelper.get_value(fuel_load, 'FuelLoadType', :string)
      @therm_per_year = XMLHelper.get_value(fuel_load, "Load[Units='#{UnitsThermPerYear}']/Value", :float)
      @fuel_type = XMLHelper.get_value(fuel_load, 'FuelType', :string)
      @frac_sensible = XMLHelper.get_value(fuel_load, 'extension/FracSensible', :float)
      @frac_latent = XMLHelper.get_value(fuel_load, 'extension/FracLatent', :float)
      @usage_multiplier = XMLHelper.get_value(fuel_load, 'extension/UsageMultiplier', :float)
      @weekday_fractions = XMLHelper.get_value(fuel_load, 'extension/WeekdayScheduleFractions', :string)
      @weekend_fractions = XMLHelper.get_value(fuel_load, 'extension/WeekendScheduleFractions', :string)
      @monthly_multipliers = XMLHelper.get_value(fuel_load, 'extension/MonthlyScheduleMultipliers', :string)
    end
  end

  class CoolingDetailedPerformanceData < BaseArrayElement
    def add(**kwargs)
      self << CoolingPerformanceDataPoint.new(@parent_object, **kwargs)
    end

    def check_for_errors
      errors = []
      # For every unique outdoor temperature, check we have exactly one minimum and one maximum datapoint
      outdoor_temps = self.select { |dp| [HPXML::CapacityDescriptionMinimum, HPXML::CapacityDescriptionMaximum].include? dp.capacity_description }.map { |dp| dp.outdoor_temperature }.uniq
      outdoor_temps.each do |outdoor_temp|
        num_min = self.select { |dp| dp.capacity_description == HPXML::CapacityDescriptionMinimum && dp.outdoor_temperature == outdoor_temp }.size
        num_max = self.select { |dp| dp.capacity_description == HPXML::CapacityDescriptionMaximum && dp.outdoor_temperature == outdoor_temp }.size
        if (num_min != 1) || (num_max != 1)
          errors << "Cooling detailed performance data for outdoor temperature = #{outdoor_temp} is incomplete; there must be exactly one minimum and one maximum capacity datapoint."
        end
      end
      return errors
    end

    def from_doc(hvac_system)
      return if hvac_system.nil?

      XMLHelper.get_elements(hvac_system, 'CoolingDetailedPerformanceData/PerformanceDataPoint').each do |performance_data_point|
        self << CoolingPerformanceDataPoint.new(@parent_object, performance_data_point)
      end
    end
  end

  class CoolingPerformanceDataPoint < BaseElement
    ATTRS = [:outdoor_temperature, :indoor_temperature, :indoor_wetbulb, :capacity, :capacity_fraction_of_nominal,
             :capacity_description, :efficiency_cop, :gross_capacity, :gross_efficiency_cop, :isdefaulted]
    attr_accessor(*ATTRS)

    def delete
      (@parent_object.cooling_systems + @parent_object.heat_pumps).each do |cooling_system|
        cooling_system.cooling_detailed_performance_data.delete(self)
      end
    end

    def check_for_errors
      errors = []
      return errors
    end

    def to_doc(hvac_system)
      detailed_performance_data = XMLHelper.create_elements_as_needed(hvac_system, ['CoolingDetailedPerformanceData'])
      performance_data_point = XMLHelper.add_element(detailed_performance_data, 'PerformanceDataPoint')
      XMLHelper.add_attribute(performance_data_point, 'dataSource', 'software') if @isdefaulted
      XMLHelper.add_element(performance_data_point, 'OutdoorTemperature', @outdoor_temperature, :float, @outdoor_temperature_isdefaulted) unless @outdoor_temperature.nil?
      XMLHelper.add_element(performance_data_point, 'IndoorTemperature', @indoor_temperature, :float, @indoor_temperature_isdefaulted) unless @indoor_temperature.nil?
      XMLHelper.add_element(performance_data_point, 'IndoorWetbulbTemperature', @indoor_wetbulb, :float, @indoor_wetbulb_isdefaulted) unless @indoor_wetbulb.nil?
      XMLHelper.add_element(performance_data_point, 'Capacity', @capacity, :float, @capacity_isdefaulted) unless @capacity.nil?
      XMLHelper.add_element(performance_data_point, 'CapacityFractionOfNominal', @capacity_fraction_of_nominal, :float, @capacity_fraction_of_nominal_isdefaulted) unless @capacity_fraction_of_nominal.nil?
      XMLHelper.add_element(performance_data_point, 'CapacityDescription', @capacity_description, :string, @capacity_description_isdefaulted) unless @capacity_description.nil?
      if not @efficiency_cop.nil?
        efficiency = XMLHelper.add_element(performance_data_point, 'Efficiency')
        XMLHelper.add_element(efficiency, 'Units', UnitsCOP, :string)
        XMLHelper.add_element(efficiency, 'Value', @efficiency_cop, :float)
      end
    end

    def from_doc(performance_data_point)
      return if performance_data_point.nil?

      @outdoor_temperature = XMLHelper.get_value(performance_data_point, 'OutdoorTemperature', :float)
      @indoor_temperature = XMLHelper.get_value(performance_data_point, 'IndoorTemperature', :float)
      @indoor_wetbulb = XMLHelper.get_value(performance_data_point, 'IndoorWetbulbTemperature', :float)
      @capacity = XMLHelper.get_value(performance_data_point, 'Capacity', :float)
      @capacity_fraction_of_nominal = XMLHelper.get_value(performance_data_point, 'CapacityFractionOfNominal', :float)
      @capacity_description = XMLHelper.get_value(performance_data_point, 'CapacityDescription', :string)
      @efficiency_cop = XMLHelper.get_value(performance_data_point, "Efficiency[Units='#{UnitsCOP}']/Value", :float)
    end
  end

  class HeatingDetailedPerformanceData < BaseArrayElement
    def add(**kwargs)
      self << HeatingPerformanceDataPoint.new(@parent_object, **kwargs)
    end

    def check_for_errors
      errors = []
      # For every unique outdoor temperature, check we have exactly one minimum and one maximum datapoint
      outdoor_temps = self.select { |dp| [HPXML::CapacityDescriptionMinimum, HPXML::CapacityDescriptionMaximum].include? dp.capacity_description }.map { |dp| dp.outdoor_temperature }.uniq
      outdoor_temps.each do |outdoor_temp|
        num_min = self.select { |dp| dp.capacity_description == HPXML::CapacityDescriptionMinimum && dp.outdoor_temperature == outdoor_temp }.size
        num_max = self.select { |dp| dp.capacity_description == HPXML::CapacityDescriptionMaximum && dp.outdoor_temperature == outdoor_temp }.size
        if (num_min != 1) || (num_max != 1)
          errors << "Heating detailed performance data for outdoor temperature = #{outdoor_temp} is incomplete; there must be exactly one minimum and one maximum capacity datapoint."
        end
      end
      return errors
    end

    def from_doc(hvac_system)
      return if hvac_system.nil?

      XMLHelper.get_elements(hvac_system, 'HeatingDetailedPerformanceData/PerformanceDataPoint').each do |performance_data_point|
        self << HeatingPerformanceDataPoint.new(@parent_object, performance_data_point)
      end
    end
  end

  class HeatingPerformanceDataPoint < BaseElement
    ATTRS = [:outdoor_temperature, :indoor_temperature, :capacity, :capacity_fraction_of_nominal,
             :capacity_description, :efficiency_cop, :gross_capacity, :gross_efficiency_cop,
             :isdefaulted]
    attr_accessor(*ATTRS)

    def delete
      (@parent_object.heating_systems + @parent_object.heat_pumps).each do |heating_system|
        heating_system.cooling_detailed_performance_data.delete(self)
      end
    end

    def check_for_errors
      errors = []
      return errors
    end

    def to_doc(hvac_system)
      detailed_performance_data = XMLHelper.create_elements_as_needed(hvac_system, ['HeatingDetailedPerformanceData'])
      performance_data_point = XMLHelper.add_element(detailed_performance_data, 'PerformanceDataPoint')
      XMLHelper.add_attribute(performance_data_point, 'dataSource', 'software') if @isdefaulted
      XMLHelper.add_element(performance_data_point, 'OutdoorTemperature', @outdoor_temperature, :float, @outdoor_temperature_isdefaulted) unless @outdoor_temperature.nil?
      XMLHelper.add_element(performance_data_point, 'IndoorTemperature', @indoor_temperature, :float, @indoor_temperature_isdefaulted) unless @indoor_temperature.nil?
      XMLHelper.add_element(performance_data_point, 'Capacity', @capacity, :float, @capacity_isdefaulted) unless @capacity.nil?
      XMLHelper.add_element(performance_data_point, 'CapacityFractionOfNominal', @capacity_fraction_of_nominal, :float, @capacity_fraction_of_nominal_isdefaulted) unless @capacity_fraction_of_nominal.nil?
      XMLHelper.add_element(performance_data_point, 'CapacityDescription', @capacity_description, :string, @capacity_description_isdefaulted) unless @capacity_description.nil?
      if not @efficiency_cop.nil?
        efficiency = XMLHelper.add_element(performance_data_point, 'Efficiency')
        XMLHelper.add_element(efficiency, 'Units', UnitsCOP, :string)
        XMLHelper.add_element(efficiency, 'Value', @efficiency_cop, :float)
      end
    end

    def from_doc(performance_data_point)
      return if performance_data_point.nil?

      @outdoor_temperature = XMLHelper.get_value(performance_data_point, 'OutdoorTemperature', :float)
      @indoor_temperature = XMLHelper.get_value(performance_data_point, 'IndoorTemperature', :float)
      @capacity = XMLHelper.get_value(performance_data_point, 'Capacity', :float)
      @capacity_fraction_of_nominal = XMLHelper.get_value(performance_data_point, 'CapacityFractionOfNominal', :float)
      @capacity_description = XMLHelper.get_value(performance_data_point, 'CapacityDescription', :string)
      @efficiency_cop = XMLHelper.get_value(performance_data_point, "Efficiency[Units='#{UnitsCOP}']/Value", :float)
    end
  end

  def _create_hpxml_document()
    doc = XMLHelper.create_doc('1.0', 'UTF-8')
    hpxml = XMLHelper.add_element(doc, 'HPXML')
    XMLHelper.add_attribute(hpxml, 'xmlns', NameSpace)
    XMLHelper.add_attribute(hpxml, 'schemaVersion', Version::HPXML_Version)
    return doc
  end

  def self.conditioned_locations
    return [HPXML::LocationConditionedSpace,
            HPXML::LocationBasementConditioned,
            HPXML::LocationCrawlspaceConditioned,
            HPXML::LocationOtherHousingUnit]
  end

  def self.conditioned_locations_this_unit
    return [HPXML::LocationConditionedSpace,
            HPXML::LocationBasementConditioned,
            HPXML::LocationCrawlspaceConditioned]
  end

  def self.conditioned_finished_locations
    return [HPXML::LocationConditionedSpace,
            HPXML::LocationBasementConditioned]
  end

  def self.conditioned_below_grade_locations
    return [HPXML::LocationBasementConditioned,
            HPXML::LocationCrawlspaceConditioned]
  end

  def self.is_conditioned(surface)
    return conditioned_locations.include?(surface.interior_adjacent_to)
  end

  def self.is_adiabatic(surface)
    if surface.exterior_adjacent_to == surface.interior_adjacent_to
      # E.g., wall between unit crawlspace and neighboring unit crawlspace
      return true
    elsif conditioned_locations.include?(surface.interior_adjacent_to) &&
          conditioned_locations.include?(surface.exterior_adjacent_to)
      # E.g., floor between conditioned space and conditioned basement, or
      # wall between conditioned space and "other housing unit"
      return true
    end

    return false
  end

  def self.is_thermal_boundary(surface)
    # Returns true if the surface is between conditioned space and outside/ground/unconditioned space.
    # Note: The location of insulation is not considered here, so an insulated foundation wall of an
    # unconditioned basement, for example, returns false.
    interior_conditioned = conditioned_locations.include? surface.interior_adjacent_to
    exterior_conditioned = conditioned_locations.include? surface.exterior_adjacent_to
    return (interior_conditioned != exterior_conditioned)
  end

  def self.get_id(parent, element_name = 'SystemIdentifier')
    return XMLHelper.get_attribute_value(XMLHelper.get_element(parent, element_name), 'id')
  end

  def self.get_idref(element)
    return XMLHelper.get_attribute_value(element, 'idref')
  end

  def self.check_dates(str, begin_month, begin_day, end_month, end_day)
    errors = []

    # Check for valid months
    valid_months = (1..12).to_a

    if not begin_month.nil?
      if not valid_months.include? begin_month
        errors << "#{str} Begin Month (#{begin_month}) must be one of: #{valid_months.join(', ')}."
      end
    end

    if not end_month.nil?
      if not valid_months.include? end_month
        errors << "#{str} End Month (#{end_month}) must be one of: #{valid_months.join(', ')}."
      end
    end

    # Check for valid days
    months_days = { [1, 3, 5, 7, 8, 10, 12] => (1..31).to_a, [4, 6, 9, 11] => (1..30).to_a, [2] => (1..28).to_a }
    months_days.each do |months, valid_days|
      if (not begin_day.nil?) && (months.include? begin_month)
        if not valid_days.include? begin_day
          errors << "#{str} Begin Day of Month (#{begin_day}) must be one of: #{valid_days.join(', ')}."
        end
      end
      next unless (not end_day.nil?) && (months.include? end_month)

      if not valid_days.include? end_day
        errors << "#{str} End Day of Month (#{end_day}) must be one of: #{valid_days.join(', ')}."
      end
    end

    return errors
  end
end
