# frozen_string_literal: true

class EnergyPlusValidator
  def self.run_validator(hpxml_doc)
    # A hash of hashes that defines the XML elements used by the EnergyPlus HPXML Use Case.
    #
    # Example:
    #
    # use_case = {
    #     nil => {
    #         'floor_area' => one,            # 1 element required always
    #         'garage_area' => zero_or_one,   # 0 or 1 elements required always
    #         'walls' => one_or_more,         # 1 or more elements required always
    #     },
    #     '/walls' => {
    #         'rvalue' => one,                # 1 element required if /walls element exists (conditional)
    #         'windows' => zero_or_one,       # 0 or 1 elements required if /walls element exists (conditional)
    #         'layers' => one_or_more,        # 1 or more elements required if /walls element exists (conditional)
    #     }
    # }
    #

    zero = [0]
    zero_or_one = [0, 1]
    zero_or_two = [0, 2]
    zero_or_three = [0, 3]
    zero_or_four = [0, 4]
    zero_or_five = [0, 5]
    zero_or_six = [0, 6]
    zero_or_seven = [0, 7]
    zero_or_more = nil
    one = [1]
    one_or_more = []
    nine = [9]

    requirements = {

      # Root
      nil => {
        '/HPXML/XMLTransactionHeaderInformation/XMLType' => one, # Required by HPXML schema
        '/HPXML/XMLTransactionHeaderInformation/XMLGeneratedBy' => one, # Required by HPXML schema
        '/HPXML/XMLTransactionHeaderInformation/CreatedDateAndTime' => one, # Required by HPXML schema
        '/HPXML/XMLTransactionHeaderInformation/Transaction' => one, # Required by HPXML schema
        '/HPXML/SoftwareInfo/extension/SimulationControl' => zero_or_one, # See [SimulationControl]

        '/HPXML/Building' => one,
        '/HPXML/Building/BuildingID' => one, # Required by HPXML schema
        '/HPXML/Building/ProjectStatus/EventType' => one, # Required by HPXML schema

        '/HPXML/Building/BuildingDetails/BuildingSummary/Site' => zero_or_one, # See [Site]
        '/HPXML/Building/BuildingDetails/BuildingSummary/BuildingOccupancy' => zero_or_one, # See [BuildingOccupancy]
        '/HPXML/Building/BuildingDetails/BuildingSummary/BuildingConstruction' => one, # See [BuildingConstruction]

        '/HPXML/Building/BuildingDetails/ClimateandRiskZones/ClimateZoneIECC' => zero_or_one, # See [ClimateZone]
        '/HPXML/Building/BuildingDetails/ClimateandRiskZones/WeatherStation' => one, # See [WeatherStation]

        '/HPXML/Building/BuildingDetails/Enclosure/AirInfiltration/AirInfiltrationMeasurement[number(HousePressure)=50 and BuildingAirLeakage/UnitofMeasure[text()="ACH" or text()="CFM"]] | /HPXML/Building/BuildingDetails/Enclosure/AirInfiltration/AirInfiltrationMeasurement[BuildingAirLeakage/UnitofMeasure[text()="ACHnatural"]]' => one, # see [AirInfiltration]

        '/HPXML/Building/BuildingDetails/Enclosure/Roofs/Roof' => zero_or_more, # See [Roof]
        '/HPXML/Building/BuildingDetails/Enclosure/Walls/Wall' => one_or_more, # See [Wall]
        '/HPXML/Building/BuildingDetails/Enclosure/RimJoists/RimJoist' => zero_or_more, # See [RimJoist]
        '/HPXML/Building/BuildingDetails/Enclosure/FoundationWalls/FoundationWall' => zero_or_more, # See [FoundationWall]
        '/HPXML/Building/BuildingDetails/Enclosure/FrameFloors/FrameFloor' => zero_or_more, # See [FrameFloor]
        '/HPXML/Building/BuildingDetails/Enclosure/Slabs/Slab' => zero_or_more, # See [Slab]
        '/HPXML/Building/BuildingDetails/Enclosure/Windows/Window' => zero_or_more, # See [Window]
        '/HPXML/Building/BuildingDetails/Enclosure/Skylights/Skylight' => zero_or_more, # See [Skylight]
        '/HPXML/Building/BuildingDetails/Enclosure/Doors/Door' => zero_or_more, # See [Door]

        '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem' => zero_or_more, # See [HeatingSystem]
        '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/CoolingSystem' => zero_or_more, # See [CoolingSystem]
        '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatPump' => zero_or_more, # See [HeatPump]
        '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACControl' => zero_or_one, # See [HVACControl]
        '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution' => zero_or_more, # See [HVACDistribution]

        '/HPXML/Building/BuildingDetails/Systems/MechanicalVentilation/VentilationFans/VentilationFan[UsedForWholeBuildingVentilation="true"]' => zero_or_one, # See [MechanicalVentilation]
        '/HPXML/Building/BuildingDetails/Systems/MechanicalVentilation/VentilationFans/VentilationFan[UsedForLocalVentilation="true" and FanLocation="kitchen"]' => zero_or_one, # See [KitchenRangeFan]
        '/HPXML/Building/BuildingDetails/Systems/MechanicalVentilation/VentilationFans/VentilationFan[UsedForLocalVentilation="true" and FanLocation="bath"]' => zero_or_one, # See [BathFan]
        '/HPXML/Building/BuildingDetails/Systems/MechanicalVentilation/VentilationFans/VentilationFan[UsedForSeasonalCoolingLoadReduction="true"]' => zero_or_one, # See [WholeHouseFan]
        '/HPXML/Building/BuildingDetails/Systems/WaterHeating/WaterHeatingSystem' => zero_or_more, # See [WaterHeatingSystem]
        '/HPXML/Building/BuildingDetails/Systems/WaterHeating/HotWaterDistribution' => zero_or_one, # See [HotWaterDistribution]
        '/HPXML/Building/BuildingDetails/Systems/WaterHeating/WaterFixture' => zero_or_more, # See [WaterFixture]
        '/HPXML/Building/BuildingDetails/Systems/SolarThermal/SolarThermalSystem' => zero_or_one, # See [SolarThermalSystem]
        '/HPXML/Building/BuildingDetails/Systems/Photovoltaics/PVSystem' => zero_or_more, # See [PVSystem]

        '/HPXML/Building/BuildingDetails/Appliances/ClothesWasher' => zero_or_one, # See [ClothesWasher]
        '/HPXML/Building/BuildingDetails/Appliances/ClothesDryer' => zero_or_one, # See [ClothesDryer]
        '/HPXML/Building/BuildingDetails/Appliances/Dishwasher' => zero_or_one, # See [Dishwasher]
        '/HPXML/Building/BuildingDetails/Appliances/Refrigerator' => zero_or_more, # See [Refrigerator]
        '/HPXML/Building/BuildingDetails/Appliances/Freezer' => zero_or_more, # See [Freezer]
        '/HPXML/Building/BuildingDetails/Appliances/Dehumidifier' => zero_or_one, # See [Dehumidifier]
        '/HPXML/Building/BuildingDetails/Appliances/CookingRange' => zero_or_one, # See [CookingRange]
        '/HPXML/Building/BuildingDetails/Appliances/Oven' => zero_or_one, # See [Oven]

        '/HPXML/Building/BuildingDetails/Lighting' => zero_or_one, # See [Lighting]
        '/HPXML/Building/BuildingDetails/Lighting/CeilingFan' => zero_or_one, # See [CeilingFan]

        '/HPXML/Building/BuildingDetails/Pools/Pool' => zero_or_one, # See [Pool]
        '/HPXML/Building/BuildingDetails/HotTubs/HotTub' => zero_or_one, # See [HotTub]

        '/HPXML/Building/BuildingDetails/MiscLoads/PlugLoad[PlugLoadType="other"]' => zero_or_one, # See [PlugLoad]
        '/HPXML/Building/BuildingDetails/MiscLoads/PlugLoad[PlugLoadType="TV other"]' => zero_or_one, # See [PlugLoad]
        '/HPXML/Building/BuildingDetails/MiscLoads/PlugLoad[PlugLoadType="electric vehicle charging"]' => zero_or_one, # See [PlugLoad]
        '/HPXML/Building/BuildingDetails/MiscLoads/PlugLoad[PlugLoadType="well pump"]' => zero_or_one, # See [PlugLoad]

        '/HPXML/Building/BuildingDetails/MiscLoads/FuelLoad[FuelLoadType="grill"]' => zero_or_one, # See [FuelLoad]
        '/HPXML/Building/BuildingDetails/MiscLoads/FuelLoad[FuelLoadType="lighting"]' => zero_or_one, # See [FuelLoad]
        '/HPXML/Building/BuildingDetails/MiscLoads/FuelLoad[FuelLoadType="fireplace"]' => zero_or_one, # See [FuelLoad]
      },

      # [SimulationControl]
      '/HPXML/SoftwareInfo/extension/SimulationControl' => {
        'Timestep' => zero_or_one, # minutes; must be a divisor of 60
        'BeginMonth | BeginDayOfMonth' => zero_or_two, # integer
        'EndMonth | EndDayOfMonth' => zero_or_two, # integer
      },

      # [Site]
      '/HPXML/Building/BuildingDetails/BuildingSummary/Site' => {
        'SiteType[text()="urban" or text()="suburban" or text()="rural"]' => zero_or_one,
        'extension/ShelterCoefficient' => zero_or_one,
        'extension/Neighbors' => zero_or_one, # See [Neighbors]
      },

      ## [Neighbors]
      '/HPXML/Building/BuildingDetails/BuildingSummary/Site/extension/Neighbors' => {
        'NeighborBuilding' => one_or_more, # See [NeighborBuilding]
      },

      ## [NeighborBuilding]
      '/HPXML/Building/BuildingDetails/BuildingSummary/Site/extension/Neighbors/NeighborBuilding' => {
        'Azimuth' => one,
        'Distance' => one, # ft
        'Height' => zero_or_one # ft; if omitted, the neighbor is the same height as the main building
      },

      # [BuildingOccupancy]
      '/HPXML/Building/BuildingDetails/BuildingSummary/BuildingOccupancy' => {
        'NumberofResidents' => zero_or_one,
      },

      # [BuildingConstruction]
      '/HPXML/Building/BuildingDetails/BuildingSummary/BuildingConstruction' => {
        'NumberofConditionedFloors' => one,
        'NumberofConditionedFloorsAboveGrade' => one,
        'NumberofBedrooms' => one,
        'NumberofBathrooms' => zero_or_one,
        'ConditionedFloorArea' => one,
        'ConditionedBuildingVolume | AverageCeilingHeight' => one_or_more,
      },

      # [ClimateZone]
      '/HPXML/Building/BuildingDetails/ClimateandRiskZones/ClimateZoneIECC' => {
        'Year' => one,
        'ClimateZone[text()="1A" or text()="1B" or text()="1C" or text()="2A" or text()="2B" or text()="2C" or text()="3A" or text()="3B" or text()="3C" or text()="4A" or text()="4B" or text()="4C" or text()="5A" or text()="5B" or text()="5C" or text()="6A" or text()="6B" or text()="6C" or text()="7" or text()="8"]' => one,
      },

      # [WeatherStation]
      '/HPXML/Building/BuildingDetails/ClimateandRiskZones/WeatherStation' => {
        'SystemIdentifier' => one, # Required by HPXML schema
        'Name' => one, # Required by HPXML schema
        'WMO | extension/EPWFilePath' => one, # Reference weather/data.csv for the list of acceptable WMO station numbers
      },

      # [AirInfiltration]
      '/HPXML/Building/BuildingDetails/Enclosure/AirInfiltration/AirInfiltrationMeasurement[number(HousePressure)=50 and BuildingAirLeakage/UnitofMeasure[text()="ACH" or text()="CFM"]] | /HPXML/Building/BuildingDetails/Enclosure/AirInfiltration/AirInfiltrationMeasurement[BuildingAirLeakage/UnitofMeasure[text()="ACHnatural"]]' => {
        'SystemIdentifier' => one, # Required by HPXML schema
        'BuildingAirLeakage/AirLeakage' => one,
        'InfiltrationVolume' => zero_or_one,
      },

      # [Roof]
      '/HPXML/Building/BuildingDetails/Enclosure/Roofs/Roof' => {
        'SystemIdentifier' => one, # Required by HPXML schema
        'InteriorAdjacentTo[text()="attic - vented" or text()="attic - unvented" or text()="living space" or text()="garage"]' => one, # See [VentedAttic]
        'Area' => one,
        'Azimuth' => zero_or_one,
        '[not(RoofType)] | RoofType[text()="asphalt or fiberglass shingles" or text()="wood shingles or shakes" or text()="slate or tile shingles" or text()="metal surfacing"]' => one,
        'RoofColor | SolarAbsorptance' => one_or_more,
        'Emittance' => one,
        'Pitch' => one,
        'RadiantBarrier' => one,
        'Insulation/SystemIdentifier' => one, # Required by HPXML schema
        'Insulation/AssemblyEffectiveRValue' => one,
      },

      ## [VentedAttic]
      '/HPXML/Building/BuildingDetails/Enclosure/Roofs/Roof[InteriorAdjacentTo="attic - vented"]' => {
        '../../Attics/Attic[AtticType/Attic[Vented="true"]]/VentilationRate[UnitofMeasure="SLA" or UnitofMeasure="ACHnatural"]/Value' => zero_or_one,
      },

      # [Wall]
      '/HPXML/Building/BuildingDetails/Enclosure/Walls/Wall' => {
        'SystemIdentifier' => one, # Required by HPXML schema
        'ExteriorAdjacentTo[text()="outside" or text()="attic - vented" or text()="attic - unvented" or text()="basement - conditioned" or text()="basement - unconditioned" or text()="crawlspace - vented" or text()="crawlspace - unvented" or text()="garage" or text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space"]' => one,
        'InteriorAdjacentTo[text()="living space" or text()="attic - vented" or text()="attic - unvented" or text()="basement - conditioned" or text()="basement - unconditioned" or text()="crawlspace - vented" or text()="crawlspace - unvented" or text()="garage"]' => one,
        'WallType[WoodStud | DoubleWoodStud | ConcreteMasonryUnit | StructurallyInsulatedPanel | InsulatedConcreteForms | SteelFrame | SolidConcrete | StructuralBrick | StrawBale | Stone | LogWall]' => one,
        'Area' => one,
        'Azimuth' => zero_or_one,
        '[not(Siding)] | Siding[text()="wood siding" or text()="vinyl siding" or text()="stucco" or text()="fiber cement siding" or text()="brick veneer" or text()="aluminum siding"]' => one,
        'Color | SolarAbsorptance' => one_or_more,
        'Emittance' => one,
        'Insulation/SystemIdentifier' => one, # Required by HPXML schema
        'Insulation/AssemblyEffectiveRValue' => one,
      },

      # [RimJoist]
      '/HPXML/Building/BuildingDetails/Enclosure/RimJoists/RimJoist' => {
        'SystemIdentifier' => one, # Required by HPXML schema
        'ExteriorAdjacentTo[text()="outside" or text()="attic - vented" or text()="attic - unvented" or text()="basement - conditioned" or text()="basement - unconditioned" or text()="crawlspace - vented" or text()="crawlspace - unvented" or text()="garage" or text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space"]' => one,
        'InteriorAdjacentTo[text()="living space" or text()="attic - vented" or text()="attic - unvented" or text()="basement - conditioned" or text()="basement - unconditioned" or text()="crawlspace - vented" or text()="crawlspace - unvented" or text()="garage"]' => one,
        'Area' => one,
        'Azimuth' => zero_or_one,
        '[not(Siding)] | Siding[text()="wood siding" or text()="vinyl siding" or text()="stucco" or text()="fiber cement siding" or text()="brick veneer" or text()="aluminum siding"]' => one,
        'Color | SolarAbsorptance' => one_or_more,
        'Emittance' => one,
        'Insulation/SystemIdentifier' => one, # Required by HPXML schema
        'Insulation/AssemblyEffectiveRValue' => one,
      },

      # [FoundationWall]
      '/HPXML/Building/BuildingDetails/Enclosure/FoundationWalls/FoundationWall' => {
        'SystemIdentifier' => one, # Required by HPXML schema
        'ExteriorAdjacentTo[text()="ground" or text()="basement - conditioned" or text()="basement - unconditioned" or text()="crawlspace - vented" or text()="crawlspace - unvented" or text()="garage" or text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space"]' => one,
        'InteriorAdjacentTo[text()="basement - conditioned" or text()="basement - unconditioned" or text()="crawlspace - vented" or text()="crawlspace - unvented" or text()="garage"]' => one, # See [VentedCrawlspace]
        'Height' => one,
        'Area' => one,
        'Azimuth' => zero_or_one,
        'Thickness' => one,
        'DepthBelowGrade' => one,
        'Insulation/SystemIdentifier' => one, # Required by HPXML schema
        # Insulation: either specify interior and exterior layers OR assembly R-value:
        'Insulation/Layer[InstallationType="continuous - interior"] | Insulation/AssemblyEffectiveRValue' => one, # See [FoundationWallInsLayer]
        'Insulation/Layer[InstallationType="continuous - exterior"] | Insulation/AssemblyEffectiveRValue' => one, # See [FoundationWallInsLayer]
      },

      ## [VentedCrawlspace]
      '/HPXML/Building/BuildingDetails/Enclosure/FoundationWalls/FoundationWall[InteriorAdjacentTo="crawlspace - vented"]' => {
        '../../Foundations/Foundation[FoundationType/Crawlspace[Vented="true"]]/VentilationRate[UnitofMeasure="SLA"]/Value' => zero_or_one,
      },

      ## [FoundationWallInsLayer]
      '/HPXML/Building/BuildingDetails/Enclosure/FoundationWalls/FoundationWall/Insulation/Layer[InstallationType="continuous - exterior" or InstallationType="continuous - interior"]' => {
        'NominalRValue' => one,
        'extension/DistanceToTopOfInsulation' => one, # ft
        'extension/DistanceToBottomOfInsulation' => one, # ft
      },

      # [FrameFloor]
      '/HPXML/Building/BuildingDetails/Enclosure/FrameFloors/FrameFloor' => {
        'SystemIdentifier' => one, # Required by HPXML schema
        'ExteriorAdjacentTo[text()="outside" or text()="attic - vented" or text()="attic - unvented" or text()="basement - conditioned" or text()="basement - unconditioned" or text()="crawlspace - vented" or text()="crawlspace - unvented" or text()="garage" or text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space"]' => one, # See [FrameFloorAdjacentToOther]
        'InteriorAdjacentTo[text()="living space" or text()="attic - vented" or text()="attic - unvented" or text()="basement - conditioned" or text()="basement - unconditioned" or text()="crawlspace - vented" or text()="crawlspace - unvented" or text()="garage"]' => one,
        'Area' => one,
        'Insulation/SystemIdentifier' => one, # Required by HPXML schema
        'Insulation/AssemblyEffectiveRValue' => one,
      },

      ## [FrameFloorAdjacentToOther]
      '/HPXML/Building/BuildingDetails/Enclosure/FrameFloors/FrameFloor[ExteriorAdjacentTo[text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space"]]' => {
        'extension/OtherSpaceAboveOrBelow[text()="above" or text()="below"]' => one,
      },

      # [Slab]
      '/HPXML/Building/BuildingDetails/Enclosure/Slabs/Slab' => {
        'SystemIdentifier' => one, # Required by HPXML schema
        'InteriorAdjacentTo[text()="living space" or text()="basement - conditioned" or text()="basement - unconditioned" or text()="crawlspace - vented" or text()="crawlspace - unvented" or text()="garage"]' => one,
        'Area' => one,
        'Thickness' => one, # Use zero for dirt floor
        'ExposedPerimeter' => one,
        'PerimeterInsulationDepth' => one,
        'UnderSlabInsulationWidth | UnderSlabInsulationSpansEntireSlab[text()="true"]' => one,
        'DepthBelowGrade | InteriorAdjacentTo[text()!="living space" and text()!="garage"]' => one_or_more, # DepthBelowGrade only required when InteriorAdjacentTo is 'living space' or 'garage'
        'PerimeterInsulation/SystemIdentifier' => one, # Required by HPXML schema
        'PerimeterInsulation/Layer[InstallationType="continuous"]/NominalRValue' => one,
        'UnderSlabInsulation/SystemIdentifier' => one, # Required by HPXML schema
        'UnderSlabInsulation/Layer[InstallationType="continuous"]/NominalRValue' => one,
        'extension/CarpetFraction' => one, # 0 - 1
        'extension/CarpetRValue' => one,
      },

      # [Window]
      '/HPXML/Building/BuildingDetails/Enclosure/Windows/Window' => {
        'SystemIdentifier' => one, # Required by HPXML schema
        'Area' => one,
        'Azimuth' => one,
        'UFactor' => one,
        'SHGC' => one,
        'InteriorShading/SummerShadingCoefficient' => zero_or_one,
        'InteriorShading/WinterShadingCoefficient' => zero_or_one,
        'Overhangs' => zero_or_one, # See [WindowOverhang]
        'FractionOperable' => zero_or_one,
        'AttachedToWall' => one,
      },

      ## [WindowOverhang]
      '/HPXML/Building/BuildingDetails/Enclosure/Windows/Window/Overhangs' => {
        'Depth' => one,
        'DistanceToTopOfWindow' => one,
        'DistanceToBottomOfWindow' => one,
      },

      # [Skylight]
      '/HPXML/Building/BuildingDetails/Enclosure/Skylights/Skylight' => {
        'SystemIdentifier' => one, # Required by HPXML schema
        'Area' => one,
        'Azimuth' => one,
        'UFactor' => one,
        'SHGC' => one,
        'InteriorShading/SummerShadingCoefficient' => zero_or_one,
        'InteriorShading/WinterShadingCoefficient' => zero_or_one,
        'AttachedToRoof' => one,
      },

      # [Door]
      '/HPXML/Building/BuildingDetails/Enclosure/Doors/Door' => {
        'SystemIdentifier' => one, # Required by HPXML schema
        'AttachedToWall' => one,
        'Area' => one,
        'Azimuth' => one,
        'RValue' => one,
      },

      # [HeatingSystem]
      '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem' => {
        'SystemIdentifier' => one, # Required by HPXML schema
        '../../HVACControl' => one, # See [HVACControl]
        'HeatingSystemType[ElectricResistance | Furnace | WallFurnace | FloorFurnace | Boiler | Stove | PortableHeater | Fireplace]' => one, # See [HeatingType=Resistance] or [HeatingType=Furnace] or [HeatingType=WallFurnace] or [HeatingType=FloorFurnace] or [HeatingType=Boiler] or [HeatingType=Stove] or [HeatingType=PortableHeater] or [HeatingType=Fireplace]
        'HeatingCapacity' => zero_or_one,
        'FractionHeatLoadServed' => one, # Must sum to <= 1 across all HeatingSystems and HeatPumps
        'ElectricAuxiliaryEnergy' => zero_or_one, # If not provided, uses 301 defaults for fuel furnace/boiler and zero otherwise
      },

      ## [HeatingType=Resistance]
      '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem[HeatingSystemType/ElectricResistance]' => {
        'DistributionSystem' => zero,
        'HeatingSystemFuel[text()="electricity"]' => one,
        'AnnualHeatingEfficiency[Units="Percent"]/Value' => one,
      },

      ## [HeatingType=Furnace]
      '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem[HeatingSystemType/Furnace]' => {
        '../../HVACDistribution[DistributionSystemType/AirDistribution | DistributionSystemType[Other="DSE"]]' => one_or_more, # See [HVACDistribution]
        'DistributionSystem' => one,
        'HeatingSystemFuel[text()="natural gas" or text()="fuel oil" or text()="fuel oil 1" or text()="fuel oil 2" or text()="fuel oil 4" or text()="fuel oil 5/6" or text()="diesel" or text()="propane" or text()="kerosene" or text()="electricity" or text()="wood" or text()="wood pellets"]' => one,
        'AnnualHeatingEfficiency[Units="AFUE"]/Value' => one,
      },

      ## [HeatingType=WallFurnace]
      '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem[HeatingSystemType/WallFurnace]' => {
        'DistributionSystem' => zero,
        'HeatingSystemFuel[text()="natural gas" or text()="fuel oil" or text()="fuel oil 1" or text()="fuel oil 2" or text()="fuel oil 4" or text()="fuel oil 5/6" or text()="diesel" or text()="propane" or text()="kerosene" or text()="electricity" or text()="wood" or text()="wood pellets"]' => one,
        'AnnualHeatingEfficiency[Units="AFUE"]/Value' => one,
      },

      ## [HeatingType=FloorFurnace]
      '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem[HeatingSystemType/FloorFurnace]' => {
        'DistributionSystem' => zero,
        'HeatingSystemFuel[text()="natural gas" or text()="fuel oil" or text()="fuel oil 1" or text()="fuel oil 2" or text()="fuel oil 4" or text()="fuel oil 5/6" or text()="diesel" or text()="propane" or text()="kerosene" or text()="electricity" or text()="wood" or text()="wood pellets"]' => one,
        'AnnualHeatingEfficiency[Units="AFUE"]/Value' => one,
      },

      ## [HeatingType=Boiler]
      '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem[HeatingSystemType/Boiler]' => {
        '../../HVACDistribution[DistributionSystemType/HydronicDistribution | DistributionSystemType[Other="DSE"]]' => one_or_more, # See [HVACDistribution]
        'DistributionSystem' => one,
        'HeatingSystemFuel[text()="natural gas" or text()="fuel oil" or text()="fuel oil 1" or text()="fuel oil 2" or text()="fuel oil 4" or text()="fuel oil 5/6" or text()="diesel" or text()="propane" or text()="kerosene" or text()="coal" or text()="coke" or text()="bituminous coal" or text()="anthracite coal" or text()="electricity" or text()="wood" or text()="wood pellets"]' => one,
        'AnnualHeatingEfficiency[Units="AFUE"]/Value' => one,
      },

      ## [HeatingType=Stove]
      '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem[HeatingSystemType/Stove]' => {
        'DistributionSystem' => zero,
        'HeatingSystemFuel[text()="natural gas" or text()="fuel oil" or text()="fuel oil 1" or text()="fuel oil 2" or text()="fuel oil 4" or text()="fuel oil 5/6" or text()="diesel" or text()="propane" or text()="kerosene" or text()="electricity" or text()="wood" or text()="wood pellets"]' => one,
        'AnnualHeatingEfficiency[Units="Percent"]/Value' => one,
      },

      ## [HeatingType=PortableHeater]
      '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem[HeatingSystemType/PortableHeater]' => {
        'DistributionSystem' => zero,
        'HeatingSystemFuel[text()="natural gas" or text()="fuel oil" or text()="fuel oil 1" or text()="fuel oil 2" or text()="fuel oil 4" or text()="fuel oil 5/6" or text()="diesel" or text()="propane" or text()="kerosene" or text()="electricity" or text()="wood" or text()="wood pellets"]' => one,
        'AnnualHeatingEfficiency[Units="Percent"]/Value' => one,
      },

      ## [HeatingType=Fireplace]
      '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem[HeatingSystemType/Fireplace]' => {
        'DistributionSystem' => zero,
        'HeatingSystemFuel[text()="natural gas" or text()="fuel oil" or text()="fuel oil 1" or text()="fuel oil 2" or text()="fuel oil 4" or text()="fuel oil 5/6" or text()="diesel" or text()="propane" or text()="kerosene" or text()="electricity" or text()="wood" or text()="wood pellets"]' => one,
        'AnnualHeatingEfficiency[Units="Percent"]/Value' => one,
      },

      # [CoolingSystem]
      '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/CoolingSystem' => {
        'SystemIdentifier' => one, # Required by HPXML schema
        '../../HVACControl' => one, # See [HVACControl]
        'CoolingSystemType[text()="central air conditioner" or text()="room air conditioner" or text()="evaporative cooler"]' => one, # See [CoolingType=CentralAC] or [CoolingType=RoomAC] or [CoolingType=EvapCooler]
        'CoolingSystemFuel[text()="electricity"]' => one,
        'FractionCoolLoadServed' => one, # Must sum to <= 1 across all CoolingSystems and HeatPumps
      },

      ## [CoolingType=CentralAC]
      '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/CoolingSystem[CoolingSystemType="central air conditioner"]' => {
        '../../HVACDistribution[DistributionSystemType/AirDistribution | DistributionSystemType[Other="DSE"]]' => one_or_more, # See [HVACDistribution]
        'DistributionSystem' => one,
        'CoolingCapacity' => zero_or_one,
        '[not(CompressorType)] | CompressorType[text()="single stage" or text()="two stage" or text()="variable speed"]' => one,
        'AnnualCoolingEfficiency[Units="SEER"]/Value' => one,
        'SensibleHeatFraction' => zero_or_one,
      },

      ## [CoolingType=RoomAC]
      '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/CoolingSystem[CoolingSystemType="room air conditioner"]' => {
        'DistributionSystem' => zero,
        'CoolingCapacity' => zero_or_one,
        'AnnualCoolingEfficiency[Units="EER"]/Value' => one,
        'SensibleHeatFraction' => zero_or_one,
      },

      ## [CoolingType=EvapCooler]
      '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/CoolingSystem[CoolingSystemType="evaporative cooler"]' => {
        '../../HVACDistribution[DistributionSystemType/AirDistribution | DistributionSystemType[Other="DSE"]]' => zero_or_more, # See [HVACDistribution]
        'DistributionSystem' => zero_or_one,
        'CoolingCapacity' => zero,
      },

      # [HeatPump]
      '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatPump' => {
        'SystemIdentifier' => one, # Required by HPXML schema
        '../../HVACControl' => one, # See [HVACControl]
        'HeatPumpType[text()="air-to-air" or text()="mini-split" or text()="ground-to-air"]' => one, # See [HeatPumpType=ASHP] or [HeatPumpType=MSHP] or [HeatPumpType=GSHP]
        'HeatPumpFuel[text()="electricity"]' => one,
        'HeatingCapacity' => zero_or_one,
        'CoolingCapacity' => zero_or_one,
        'CoolingSensibleHeatFraction' => zero_or_one,
        '[not(BackupSystemFuel)] | BackupSystemFuel[text()="electricity" or text()="natural gas" or text()="fuel oil" or text()="fuel oil 1" or text()="fuel oil 2" or text()="fuel oil 4" or text()="fuel oil 5/6" or text()="diesel" or text()="propane" or text()="kerosene" or text()="wood" or text()="wood pellets"]' => one, # See [HeatPumpBackup]
        'FractionHeatLoadServed' => one, # Must sum to <= 1 across all HeatPumps and HeatingSystems
        'FractionCoolLoadServed' => one, # Must sum to <= 1 across all HeatPumps and CoolingSystems
      },

      ## [HeatPumpType=ASHP]
      '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatPump[HeatPumpType="air-to-air"]' => {
        '../../HVACDistribution[DistributionSystemType/AirDistribution | DistributionSystemType[Other="DSE"]]' => one_or_more, # See [HVACDistribution]
        'DistributionSystem' => one,
        '[not(CompressorType)] | CompressorType[text()="single stage" or text()="two stage" or text()="variable speed"]' => one,
        'AnnualCoolingEfficiency[Units="SEER"]/Value' => one,
        'AnnualHeatingEfficiency[Units="HSPF"]/Value' => one,
        'HeatingCapacity17F' => zero_or_one
      },

      ## [HeatPumpType=MSHP]
      '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatPump[HeatPumpType="mini-split"]' => {
        '../../HVACDistribution[DistributionSystemType/AirDistribution | DistributionSystemType[Other="DSE"]]' => zero_or_more, # See [HVACDistribution]
        'DistributionSystem' => zero_or_one,
        'AnnualCoolingEfficiency[Units="SEER"]/Value' => one,
        'AnnualHeatingEfficiency[Units="HSPF"]/Value' => one,
        'HeatingCapacity17F' => zero_or_one
      },

      ## [HeatPumpType=GSHP]
      '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatPump[HeatPumpType="ground-to-air"]' => {
        '../../HVACDistribution[DistributionSystemType/AirDistribution | DistributionSystemType[Other="DSE"]]' => one_or_more, # See [HVACDistribution]
        'DistributionSystem' => one,
        'BackupHeatingSwitchoverTemperature' => zero,
        'AnnualCoolingEfficiency[Units="EER"]/Value' => one,
        'AnnualHeatingEfficiency[Units="COP"]/Value' => one,
      },

      ## [HeatPumpBackup]
      '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatPump[BackupSystemFuel]' => {
        'BackupAnnualHeatingEfficiency[Units="Percent" or Units="AFUE"]/Value' => one,
        'BackupHeatingCapacity' => zero_or_one,
        'BackupHeatingSwitchoverTemperature' => zero_or_one, # Use if dual-fuel heat pump
      },

      # [HVACControl]
      '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACControl' => {
        'SystemIdentifier' => one, # Required by HPXML schema
        'SetpointTempHeatingSeason' => one,
        'SetbackTempHeatingSeason' => zero_or_one, # See [HVACControlType=HeatingSetback]
        'SetupTempCoolingSeason' => zero_or_one, # See [HVACControlType=CoolingSetup]
        'SetpointTempCoolingSeason' => one,
        'extension/CeilingFanSetpointTempCoolingSeasonOffset' => zero_or_one, # deg-F
      },

      ## [HVACControlType=HeatingSetback]
      '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACControl[SetbackTempHeatingSeason]' => {
        'TotalSetbackHoursperWeekHeating' => one,
        'extension/SetbackStartHourHeating' => one, # 0 = midnight. 12 = noon
      },

      ## [HVACControlType=CoolingSetup]
      '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACControl[SetupTempCoolingSeason]' => {
        'TotalSetupHoursperWeekCooling' => one,
        'extension/SetupStartHourCooling' => one, # 0 = midnight, 12 = noon
      },

      # [HVACDistribution]
      '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution' => {
        'SystemIdentifier' => one, # Required by HPXML schema
        'DistributionSystemType/AirDistribution | DistributionSystemType/HydronicDistribution | DistributionSystemType[Other="DSE"]' => one, # See [HVACDistType=Air] or [HVACDistType=DSE]
      },

      ## [HVACDistType=Air]
      '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution/DistributionSystemType/AirDistribution' => {
        '../../ConditionedFloorAreaServed' => one,
        'DuctLeakageMeasurement[DuctType="supply"]/DuctLeakage[(Units="CFM25" or Units="Percent") and TotalOrToOutside="to outside"]/Value' => one,
        'DuctLeakageMeasurement[DuctType="return"]/DuctLeakage[(Units="CFM25" or Units="Percent") and TotalOrToOutside="to outside"]/Value' => zero_or_one,
        'Ducts[DuctType="supply"]' => zero_or_more, # See [HVACDuct]
        'Ducts[DuctType="return"]' => zero_or_more, # See [HVACDuct]
        'NumberofReturnRegisters' => zero_or_one,
      },

      ## [HVACDistType=DSE]
      ## WARNING: These inputs are unused and EnergyPlus output will NOT reflect the specified DSE. To account for DSE, apply the value to the EnergyPlus output.
      '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution[DistributionSystemType[Other="DSE"]]' => {
        'AnnualHeatingDistributionSystemEfficiency | AnnualCoolingDistributionSystemEfficiency' => one_or_more,
      },

      ## [HVACDuct]
      '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution/DistributionSystemType/AirDistribution/Ducts[DuctType="supply" or DuctType="return"]' => {
        'DuctInsulationRValue' => one,
        'DuctSurfaceArea | DuctLocation[text()="living space" or text()="basement - conditioned" or text()="basement - unconditioned" or text()="crawlspace - vented" or text()="crawlspace - unvented" or text()="attic - vented" or text()="attic - unvented" or text()="garage" or text()="exterior wall" or text()="under slab" or text()="roof deck" or text()="outside" or text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space"]' => zero_or_two,
      },

      # [MechanicalVentilation]
      '/HPXML/Building/BuildingDetails/Systems/MechanicalVentilation/VentilationFans/VentilationFan[UsedForWholeBuildingVentilation="true"]' => {
        'SystemIdentifier' => one, # Required by HPXML schema
        'FanType[text()="energy recovery ventilator" or text()="heat recovery ventilator" or text()="exhaust only" or text()="supply only" or text()="balanced" or text()="central fan integrated supply"]' => one, # See [MechVentType=HRV] or [MechVentType=ERV] or [MechVentType=CFIS]
        'TestedFlowRate | RatedFlowRate' => one_or_more,
        'HoursInOperation' => one,
        'FanPower' => one,
      },

      ## [MechVentType=HRV]
      '/HPXML/Building/BuildingDetails/Systems/MechanicalVentilation/VentilationFans/VentilationFan[UsedForWholeBuildingVentilation="true" and FanType="heat recovery ventilator"]' => {
        'SensibleRecoveryEfficiency | AdjustedSensibleRecoveryEfficiency' => one,
      },

      ## [MechVentType=ERV]
      '/HPXML/Building/BuildingDetails/Systems/MechanicalVentilation/VentilationFans/VentilationFan[UsedForWholeBuildingVentilation="true" and FanType="energy recovery ventilator"]' => {
        'TotalRecoveryEfficiency | AdjustedTotalRecoveryEfficiency' => one,
        'SensibleRecoveryEfficiency | AdjustedSensibleRecoveryEfficiency' => one,
      },

      ## [MechVentType=CFIS]
      '/HPXML/Building/BuildingDetails/Systems/MechanicalVentilation/VentilationFans/VentilationFan[UsedForWholeBuildingVentilation="true" and FanType="central fan integrated supply"]' => {
        'AttachedToHVACDistributionSystem' => one,
      },

      # [KitchenRangeFan]
      '/HPXML/Building/BuildingDetails/Systems/MechanicalVentilation/VentilationFans/VentilationFan[UsedForLocalVentilation="true" and FanLocation="kitchen"]' => {
        'SystemIdentifier' => one, # Required by HPXML schema
        'RatedFlowRate' => zero_or_one,
        'HoursInOperation' => zero_or_one,
        'FanPower' => zero_or_one,
        'extension/StartHour' => zero_or_one, # 0 = midnight. 12 = noon
      },

      # [BathFan]
      '/HPXML/Building/BuildingDetails/Systems/MechanicalVentilation/VentilationFans/VentilationFan[UsedForLocalVentilation="true" and FanLocation="bath"]' => {
        'SystemIdentifier' => one, # Required by HPXML schema
        'Quantity' => zero_or_one,
        'RatedFlowRate' => zero_or_one,
        'HoursInOperation' => zero_or_one,
        'FanPower' => zero_or_one,
        'extension/StartHour' => zero_or_one, # 0 = midnight. 12 = noon
      },

      # [WholeHouseFan]
      '/HPXML/Building/BuildingDetails/Systems/MechanicalVentilation/VentilationFans/VentilationFan[UsedForSeasonalCoolingLoadReduction="true"]' => {
        'SystemIdentifier' => one, # Required by HPXML schema
        'RatedFlowRate' => one,
        'FanPower' => one,
      },

      # [WaterHeatingSystem]
      '/HPXML/Building/BuildingDetails/Systems/WaterHeating/WaterHeatingSystem' => {
        '../HotWaterDistribution' => one, # See [HotWaterDistribution]
        '../WaterFixture' => one_or_more, # See [WaterFixture]
        'SystemIdentifier' => one, # Required by HPXML schema
        'WaterHeaterType[text()="storage water heater" or text()="instantaneous water heater" or text()="heat pump water heater" or text()="space-heating boiler with storage tank" or text()="space-heating boiler with tankless coil"]' => one, # See [WHType=Tank] or [WHType=Tankless] or [WHType=HeatPump] or [WHType=Indirect] or [WHType=CombiTankless]
        '[not(Location)] | Location[text()="living space" or text()="basement - unconditioned" or text()="basement - conditioned" or text()="attic - unvented" or text()="attic - vented" or text()="garage" or text()="crawlspace - unvented" or text()="crawlspace - vented" or text()="other exterior" or text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space"]' => one,
        'FractionDHWLoadServed' => one,
        'HotWaterTemperature' => zero_or_one,
        'UsesDesuperheater' => zero_or_one, # See [Desuperheater]
      },

      ## [WHType=Tank]
      '/HPXML/Building/BuildingDetails/Systems/WaterHeating/WaterHeatingSystem[WaterHeaterType="storage water heater"]' => {
        'FuelType[text()="natural gas" or text()="fuel oil" or text()="fuel oil 1" or text()="fuel oil 2" or text()="fuel oil 4" or text()="fuel oil 5/6" or text()="diesel" or text()="propane" or text()="kerosene" or text()="coal" or text()="coke" or text()="bituminous coal" or text()="anthracite coal" or text()="electricity" or text()="wood" or text()="wood pellets"]' => one,
        'TankVolume' => zero_or_one,
        'HeatingCapacity' => zero_or_one,
        'EnergyFactor | UniformEnergyFactor' => one,
        'RecoveryEfficiency' => zero_or_one,
        'WaterHeaterInsulation/Jacket/JacketRValue' => zero_or_one, # Capable to model tank wrap insulation
      },

      ## [WHType=Tankless]
      '/HPXML/Building/BuildingDetails/Systems/WaterHeating/WaterHeatingSystem[WaterHeaterType="instantaneous water heater"]' => {
        'FuelType[text()="natural gas" or text()="fuel oil" or text()="fuel oil 1" or text()="fuel oil 2" or text()="fuel oil 4" or text()="fuel oil 5/6" or text()="diesel" or text()="propane" or text()="kerosene" or text()="coal" or text()="coke" or text()="bituminous coal" or text()="anthracite coal" or text()="electricity" or text()="wood" or text()="wood pellets"]' => one,
        'PerformanceAdjustment' => zero_or_one,
        'EnergyFactor | UniformEnergyFactor' => one,
      },

      ## [WHType=HeatPump]
      '/HPXML/Building/BuildingDetails/Systems/WaterHeating/WaterHeatingSystem[WaterHeaterType="heat pump water heater"]' => {
        'FuelType[text()="electricity"]' => one,
        'TankVolume' => one,
        'EnergyFactor | UniformEnergyFactor' => one,
        'WaterHeaterInsulation/Jacket/JacketRValue' => zero_or_one, # Capable to model tank wrap insulation
      },

      ## [WHType=Indirect]
      '/HPXML/Building/BuildingDetails/Systems/WaterHeating/WaterHeatingSystem[WaterHeaterType="space-heating boiler with storage tank"]' => {
        'RelatedHVACSystem' => one, # HeatingSystem (boiler)
        'TankVolume' => one,
        'WaterHeaterInsulation/Jacket/JacketRValue' => zero_or_one, # Capable to model tank wrap insulation
        'StandbyLoss' => zero_or_one, # Refer to https://www.ahridirectory.org/NewSearch?programId=28&searchTypeId=3
      },

      ## [WHType=CombiTankless]
      '/HPXML/Building/BuildingDetails/Systems/WaterHeating/WaterHeatingSystem[WaterHeaterType="space-heating boiler with tankless coil"]' => {
        'RelatedHVACSystem' => one, # HeatingSystem (boiler)
      },

      ## [Desuperheater]
      '/HPXML/Building/BuildingDetails/Systems/WaterHeating/WaterHeatingSystem[UsesDesuperheater="true"]' => {
        'WaterHeaterType[text()="storage water heater" or text()="instantaneous water heater" or text()="heat pump water heater"]' => one, # Desuperheater is supported with storage water heater, tankless water heater and heat pump water heater
        'RelatedHVACSystem' => one, # HeatPump or CoolingSystem
      },

      # [HotWaterDistribution]
      '/HPXML/Building/BuildingDetails/Systems/WaterHeating/HotWaterDistribution' => {
        'SystemIdentifier' => one, # Required by HPXML schema
        'SystemType/Standard | SystemType/Recirculation' => one, # See [HWDistType=Standard] or [HWDistType=Recirculation]
        'PipeInsulation/PipeRValue' => one,
        'DrainWaterHeatRecovery' => zero_or_one, # See [DrainWaterHeatRecovery]
      },

      ## [HWDistType=Standard]
      '/HPXML/Building/BuildingDetails/Systems/WaterHeating/HotWaterDistribution/SystemType/Standard' => {
        'PipingLength' => zero_or_one,
      },

      ## [HWDistType=Recirculation]
      '/HPXML/Building/BuildingDetails/Systems/WaterHeating/HotWaterDistribution/SystemType/Recirculation' => {
        'ControlType[text()="manual demand control" or text()="presence sensor demand control" or text()="temperature" or text()="timer" or text()="no control"]' => one,
        'RecirculationPipingLoopLength' => zero_or_one,
        'BranchPipingLoopLength' => zero_or_one,
        'PumpPower' => zero_or_one,
      },

      ## [DrainWaterHeatRecovery]
      '/HPXML/Building/BuildingDetails/Systems/WaterHeating/HotWaterDistribution/DrainWaterHeatRecovery' => {
        'FacilitiesConnected' => one,
        'EqualFlow' => one,
        'Efficiency' => one,
      },

      # [WaterFixture]
      '/HPXML/Building/BuildingDetails/Systems/WaterHeating/WaterFixture' => {
        'SystemIdentifier' => one, # Required by HPXML schema
        'WaterFixtureType[text()="shower head" or text()="faucet"]' => one, # Required by HPXML schema
        'LowFlow' => one,
        '../extension/WaterFixturesUsageMultiplier' => zero_or_one,
      },

      # [SolarThermalSystem]
      '/HPXML/Building/BuildingDetails/Systems/SolarThermal/SolarThermalSystem' => {
        'SystemIdentifier' => one, # Required by HPXML schema
        'SystemType[text()="hot water"]' => one,
        'CollectorArea | SolarFraction' => one, # See [SolarThermal=Detailed] or [SolarThermal=Simple]
      },

      ## [SolarThermal=Detailed]
      '/HPXML/Building/BuildingDetails/Systems/SolarThermal/SolarThermalSystem[CollectorArea]' => {
        'CollectorLoopType[text()="liquid indirect" or text()="liquid direct" or text()="passive thermosyphon"]' => one,
        'CollectorType[text()="single glazing black" or text()="double glazing black" or text()="evacuated tube" or text()="integrated collector storage"]' => one,
        'CollectorAzimuth' => one,
        'CollectorTilt' => one,
        'CollectorRatedOpticalEfficiency' => one,
        'CollectorRatedThermalLosses' => one,
        'StorageVolume' => zero_or_one,
        'ConnectedTo' => one, # WaterHeatingSystem (any type but space-heating boiler)
      },

      ## [SolarThermal=Simple]
      '/HPXML/Building/BuildingDetails/Systems/SolarThermal/SolarThermalSystem[SolarFraction]' => {
        'ConnectedTo' => zero_or_one, # WaterHeatingSystem (any type)
      },

      # [PVSystem]
      '/HPXML/Building/BuildingDetails/Systems/Photovoltaics/PVSystem' => {
        'SystemIdentifier' => one, # Required by HPXML schema
        'Location[text()="ground" or text()="roof"]' => one,
        'ModuleType[text()="standard" or text()="premium" or text()="thin film"]' => one,
        'Tracking[text()="fixed" or text()="1-axis" or text()="1-axis backtracked" or text()="2-axis"]' => one,
        'ArrayAzimuth' => one,
        'ArrayTilt' => one,
        'MaxPowerOutput' => one,
        'InverterEfficiency' => zero_or_one,
        'SystemLossesFraction | YearModulesManufactured' => zero_or_more,
      },

      # [ClothesWasher]
      '/HPXML/Building/BuildingDetails/Appliances/ClothesWasher' => {
        'SystemIdentifier' => one, # Required by HPXML schema
        '[not(Location)] | Location[text()="living space" or text()="basement - conditioned" or text()="basement - unconditioned" or text()="garage" or text()="other"]' => one,
        'ModifiedEnergyFactor | IntegratedModifiedEnergyFactor' => zero_or_one,
        'ModifiedEnergyFactor | IntegratedModifiedEnergyFactor | RatedAnnualkWh | LabelElectricRate | LabelGasRate | LabelAnnualGasCost | LabelUsage | Capacity' => zero_or_seven,
        'extension/UsageMultiplier' => zero_or_one,
      },

      # [ClothesDryer]
      '/HPXML/Building/BuildingDetails/Appliances/ClothesDryer' => {
        '../ClothesWasher' => one,
        'SystemIdentifier' => one, # Required by HPXML schema
        '[not(Location)] | Location[text()="living space" or text()="basement - conditioned" or text()="basement - unconditioned" or text()="garage" or text()="other"]' => one,
        'FuelType[text()="natural gas" or text()="fuel oil" or text()="fuel oil 1" or text()="fuel oil 2" or text()="fuel oil 4" or text()="fuel oil 5/6" or text()="diesel" or text()="propane" or text()="kerosene" or text()="coal" or text()="coke" or text()="bituminous coal" or text()="anthracite coal" or text()="electricity" or text()="wood" or text()="wood pellets"]' => one,
        'EnergyFactor | CombinedEnergyFactor' => zero_or_one,
        'EnergyFactor | CombinedEnergyFactor | ControlType' => zero_or_two,
        'extension/UsageMultiplier' => zero_or_one,
      },

      # [Dishwasher]
      '/HPXML/Building/BuildingDetails/Appliances/Dishwasher' => {
        'SystemIdentifier' => one, # Required by HPXML schema
        '[not(Location)] | Location[text()="living space" or text()="basement - conditioned" or text()="basement - unconditioned" or text()="garage" or text()="other"]' => one,
        'RatedAnnualkWh | EnergyFactor' => zero_or_one,
        'RatedAnnualkWh | EnergyFactor | LabelElectricRate | LabelGasRate | LabelAnnualGasCost | LabelUsage | PlaceSettingCapacity' => zero_or_six,
        'extension/UsageMultiplier' => zero_or_one,
      },

      # [Refrigerator]
      '/HPXML/Building/BuildingDetails/Appliances/Refrigerator' => {
        'SystemIdentifier' => one, # Required by HPXML schema
        '[not(Location)] | Location[text()="living space" or text()="basement - conditioned" or text()="basement - unconditioned" or text()="garage" or text()="other"]' => one,
        'RatedAnnualkWh | extension/AdjustedAnnualkWh' => zero_or_more,
        'PrimaryIndicator' => zero_or_one,
        'extension/UsageMultiplier' => zero_or_one,
        'extension/WeekdayScheduleFractions' => zero_or_one,
        'extension/WeekendScheduleFractions' => zero_or_one,
        'extension/MonthlyScheduleMultipliers' => zero_or_one,
      },

      # [Freezer]
      '/HPXML/Building/BuildingDetails/Appliances/Freezer' => {
        'SystemIdentifier' => one, # Required by HPXML schema
        '[not(Location)] | Location[text()="living space" or text()="basement - conditioned" or text()="basement - unconditioned" or text()="garage" or text()="other"]' => one,
        'RatedAnnualkWh | extension/AdjustedAnnualkWh' => zero_or_more,
        'extension/UsageMultiplier' => zero_or_one,
        'extension/WeekdayScheduleFractions' => zero_or_one,
        'extension/WeekendScheduleFractions' => zero_or_one,
        'extension/MonthlyScheduleMultipliers' => zero_or_one,
      },

      # [Dehumidifier]
      '/HPXML/Building/BuildingDetails/Appliances/Dehumidifier' => {
        'SystemIdentifier' => one, # Required by HPXML schema
        'Capacity' => one, # pints/day
        'EnergyFactor | IntegratedEnergyFactor' => one, # liters/kWh
        'DehumidistatSetpoint' => one, # RH, fraction
        'FractionDehumidificationLoadServed' => one,
      },

      # [CookingRange]
      '/HPXML/Building/BuildingDetails/Appliances/CookingRange' => {
        '../Oven' => one, # See [Oven]
        'SystemIdentifier' => one, # Required by HPXML schema
        '[not(Location)] | Location[text()="living space" or text()="basement - conditioned" or text()="basement - unconditioned" or text()="garage" or text()="other"]' => one,
        'FuelType[text()="natural gas" or text()="fuel oil" or text()="fuel oil 1" or text()="fuel oil 2" or text()="fuel oil 4" or text()="fuel oil 5/6" or text()="diesel" or text()="propane" or text()="kerosene" or text()="coal" or text()="coke" or text()="bituminous coal" or text()="anthracite coal" or text()="electricity" or text()="wood" or text()="wood pellets"]' => one,
        'IsInduction' => zero_or_one,
        'extension/UsageMultiplier' => zero_or_one,
        'extension/WeekdayScheduleFractions' => zero_or_one,
        'extension/WeekendScheduleFractions' => zero_or_one,
        'extension/MonthlyScheduleMultipliers' => zero_or_one,
      },

      # [Oven]
      '/HPXML/Building/BuildingDetails/Appliances/Oven' => {
        '../CookingRange' => one, # See [CookingRange]
        'SystemIdentifier' => one, # Required by HPXML schema
        'IsConvection' => zero_or_one,
      },

      # [Lighting]
      '/HPXML/Building/BuildingDetails/Lighting' => {
        'LightingGroup[LightingType[LightEmittingDiode | CompactFluorescent | FluorescentTube] and Location[text()="interior" or text()="exterior" or text()="garage"]]' => nine, # See [LightingGroup]
        'extension/UsageMultiplier' => zero_or_one,
      },

      ## [LightingGroup]
      'LightingGroup[LightingType[LightEmittingDiode | CompactFluorescent | FluorescentTube] and Location[text()="interior" or text()="exterior" or text()="garage"]]' => {
        'SystemIdentifier' => one, # Required by HPXML schema
        'FractionofUnitsInLocation' => one,
      },

      # [CeilingFan]
      '/HPXML/Building/BuildingDetails/Lighting/CeilingFan' => {
        'SystemIdentifier' => one, # Required by HPXML schema
        'Airflow[FanSpeed="medium"]/Efficiency' => zero_or_one,
        'Quantity' => zero_or_one,
      },

      # [Pool]
      '/HPXML/Building/BuildingDetails/Pools/Pool' => {
        'SystemIdentifier' => one, # Required by HPXML schema
        'PoolPumps/PoolPump' => one, # See [PoolPump]
        'Heater' => zero_or_one, # See [PoolHeater]
      },

      ## [PoolPump]
      '/HPXML/Building/BuildingDetails/Pools/Pool/PoolPumps/PoolPump' => {
        'SystemIdentifier' => one, # Required by HPXML schema
        'Load[Units="kWh/year"]/Value' => zero_or_one,
        'extension/UsageMultiplier' => zero_or_one,
        'extension/WeekdayScheduleFractions' => zero_or_one,
        'extension/WeekendScheduleFractions' => zero_or_one,
        'extension/MonthlyScheduleMultipliers' => zero_or_one,
      },

      ## [PoolHeater]
      '/HPXML/Building/BuildingDetails/Pools/Pool/Heater' => {
        'SystemIdentifier' => one, # Required by HPXML schema
        'Type[text()="gas fired" or text()="electric resistance" or text()="heat pump"]' => one,
        'Load[Units="kWh/year" or Units="therm/year"]/Value' => zero_or_one,
        'extension/UsageMultiplier' => zero_or_one,
        'extension/WeekdayScheduleFractions' => zero_or_one,
        'extension/WeekendScheduleFractions' => zero_or_one,
        'extension/MonthlyScheduleMultipliers' => zero_or_one,
      },

      # [HotTub]
      '/HPXML/Building/BuildingDetails/HotTubs/HotTub' => {
        'SystemIdentifier' => one, # Required by HPXML schema
        'HotTubPumps/HotTubPump' => one, # See [HotTubPump]
        'Heater' => zero_or_one, # See [HotTubHeater]
      },

      ## [HotTubPump]
      '/HPXML/Building/BuildingDetails/HotTubs/HotTub/HotTubPumps/HotTubPump' => {
        'SystemIdentifier' => one, # Required by HPXML schema
        'Load[Units="kWh/year"]/Value' => zero_or_one,
        'extension/UsageMultiplier' => zero_or_one,
        'extension/WeekdayScheduleFractions' => zero_or_one,
        'extension/WeekendScheduleFractions' => zero_or_one,
        'extension/MonthlyScheduleMultipliers' => zero_or_one,
      },

      ## [HotTubHeater]
      '/HPXML/Building/BuildingDetails/HotTubs/HotTub/Heater' => {
        'SystemIdentifier' => one, # Required by HPXML schema
        'Type[text()="gas fired" or text()="electric resistance" or text()="heat pump"]' => one,
        'Load[Units="kWh/year" or Units="therm/year"]/Value' => zero_or_one,
        'extension/UsageMultiplier' => zero_or_one,
        'extension/WeekdayScheduleFractions' => zero_or_one,
        'extension/WeekendScheduleFractions' => zero_or_one,
        'extension/MonthlyScheduleMultipliers' => zero_or_one,
      },

      # [PlugLoad]
      '/HPXML/Building/BuildingDetails/MiscLoads/PlugLoad[PlugLoadType="other" or PlugLoadType="TV other" or PlugLoadType="electric vehicle charging" or PlugLoadType="well pump"]' => {
        'SystemIdentifier' => one, # Required by HPXML schema
        'Location[text()="interior" or text()="exterior"]' => zero_or_one,
        'Load[Units="kWh/year"]/Value' => zero_or_one,
        'extension/FracSensible' => zero_or_one,
        'extension/FracLatent' => zero_or_one,
        'extension/UsageMultiplier' => zero_or_one,
        'extension/WeekdayScheduleFractions' => zero_or_one,
        'extension/WeekendScheduleFractions' => zero_or_one,
        'extension/MonthlyScheduleMultipliers' => zero_or_one,
      },

      # [FuelLoad]
      '/HPXML/Building/BuildingDetails/MiscLoads/FuelLoad[FuelLoadType="grill" or FuelLoadType="lighting" or FuelLoadType="fireplace"]' => {
        'SystemIdentifier' => one, # Required by HPXML schema
        'Location[text()="interior" or text()="exterior"]' => zero_or_one,
        'Load[Units="therm/year"]/Value' => zero_or_one,
        'FuelType[text()="natural gas" or text()="fuel oil" or text()="fuel oil 1" or text()="fuel oil 2" or text()="fuel oil 4" or text()="fuel oil 5/6" or text()="diesel" or text()="propane" or text()="kerosene" or text()="coal" or text()="coke" or text()="bituminous coal" or text()="anthracite coal" or text()="wood" or text()="wood pellets"]' => one,
        'extension/UsageMultiplier' => zero_or_one,
        'extension/WeekdayScheduleFractions' => zero_or_one,
        'extension/WeekendScheduleFractions' => zero_or_one,
        'extension/MonthlyScheduleMultipliers' => zero_or_one,
      },
    }

    errors = []
    requirements.each do |parent, requirement|
      if parent.nil? # Unconditional
        requirement.each do |child, expected_sizes|
          next if expected_sizes.nil?

          xpath = combine_into_xpath(parent, child)
          actual_size = hpxml_doc.xpath("#{child}").length
          check_number_of_elements(actual_size, expected_sizes, xpath, errors)
        end
      else # Conditional based on parent element existence
        next if hpxml_doc.xpath(parent).empty? # Skip if parent element doesn't exist

        hpxml_doc.xpath(parent).each do |parent_element|
          requirement.each do |child, expected_sizes|
            next if expected_sizes.nil?

            xpath = combine_into_xpath(parent, child)
            actual_size = parent_element.xpath("#{update_leading_predicates(child)}").length
            check_number_of_elements(actual_size, expected_sizes, xpath, errors)
          end
        end
      end
    end

    return errors
  end

  def self.check_number_of_elements(actual_size, expected_sizes, xpath, errors)
    if expected_sizes.size > 0
      return if expected_sizes.include?(actual_size)

      errors << "Expected #{expected_sizes} element(s) but found #{actual_size} element(s) for xpath: #{xpath}"
    else
      return if actual_size > 0

      errors << "Expected 1 or more element(s) but found 0 elements for xpath: #{xpath}"
    end
  end

  def self.combine_into_xpath(parent, child)
    if parent.nil?
      return child
    end

    return [parent, child].join(': ')
  end

  def self.update_leading_predicates(str)
    # Examples:
    #   "[foo='1' or foo='2']" => "(self::node()[foo='1' or foo='2'])"
    #   "[foo] | bar" => "(self::node()[foo]) | bar"

    add_str = '(self::node()'

    # First check beginning of str
    if str[0] == '['
      str = add_str + str
      # Find closing bracket match for ending parenthesis
      count = 0
      for i in add_str.size..str.size - 1
        if str[i] == '['
          count += 1
        elsif str[i] == ']'
          count -= 1
        end
        if count == 0
          str = str[0..i] + ')' + str[i + 1..str.size]
          break
        end
      end
    end

    return str
  end
end
