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
    one = [1]
    zero_or_one = [0, 1]
    zero_or_two = [0, 2]
    zero_or_more = nil
    one_or_more = []
    zero_or_two = [0, 2]
    zero_or_six = [0, 6]

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

        '/HPXML/Building/BuildingDetails/BuildingSummary/Site/extension/ShelterCoefficient' => zero_or_one, # Uses ERI assumption if not provided
        '/HPXML/Building/BuildingDetails/BuildingSummary/BuildingOccupancy/NumberofResidents' => zero_or_one, # Uses ERI assumption if not provided
        '/HPXML/Building/BuildingDetails/BuildingSummary/BuildingConstruction' => one, # See [BuildingConstruction]
        '/HPXML/Building/BuildingDetails/BuildingSummary/Site/extension/Neighbors' => zero_or_one, # See [Neighbors]

        '/HPXML/Building/BuildingDetails/ClimateandRiskZones/WeatherStation' => one, # See [WeatherStation]

        '/HPXML/Building/BuildingDetails/Enclosure/AirInfiltration/AirInfiltrationMeasurement[HousePressure=50]/BuildingAirLeakage[UnitofMeasure="ACH" or UnitofMeasure="CFM"]/AirLeakage | /HPXML/Building/BuildingDetails/Enclosure/AirInfiltration/AirInfiltrationMeasurement/extension/ConstantACHnatural' => one, # see [AirInfiltration]

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
        '/HPXML/Building/BuildingDetails/Systems/MechanicalVentilation/VentilationFans/VentilationFan[UsedForSeasonalCoolingLoadReduction="true"]' => zero_or_one, # See [WholeHouseFan]
        '/HPXML/Building/BuildingDetails/Systems/WaterHeating/WaterHeatingSystem' => zero_or_more, # See [WaterHeatingSystem]
        '/HPXML/Building/BuildingDetails/Systems/WaterHeating/HotWaterDistribution' => zero_or_one, # See [HotWaterDistribution]
        '/HPXML/Building/BuildingDetails/Systems/WaterHeating/WaterFixture' => zero_or_more, # See [WaterFixture]
        '/HPXML/Building/BuildingDetails/Systems/SolarThermal/SolarThermalSystem' => zero_or_one, # See [SolarThermalSystem]
        '/HPXML/Building/BuildingDetails/Systems/Photovoltaics/PVSystem' => zero_or_more, # See [PVSystem]

        '/HPXML/Building/BuildingDetails/Appliances/ClothesWasher' => zero_or_one, # See [ClothesWasher]
        '/HPXML/Building/BuildingDetails/Appliances/ClothesDryer' => zero_or_one, # See [ClothesDryer]
        '/HPXML/Building/BuildingDetails/Appliances/Dishwasher' => zero_or_one, # See [Dishwasher]
        '/HPXML/Building/BuildingDetails/Appliances/Refrigerator' => zero_or_one, # See [Refrigerator]
        '/HPXML/Building/BuildingDetails/Appliances/CookingRange' => zero_or_one, # See [CookingRange]

        '/HPXML/Building/BuildingDetails/Lighting' => zero_or_one, # See [Lighting]
        '/HPXML/Building/BuildingDetails/Lighting/CeilingFan' => zero_or_one, # See [CeilingFan]

        '/HPXML/Building/BuildingDetails/MiscLoads/PlugLoad[PlugLoadType="other"]' => zero_or_one, # See [PlugLoads]
        '/HPXML/Building/BuildingDetails/MiscLoads/PlugLoad[PlugLoadType="TV other"]' => zero_or_one, # See [Television]
      },

      # [SimulationControl]
      '/HPXML/SoftwareInfo/extension/SimulationControl' => {
        'Timestep' => zero_or_one, # minutes; must be a divisor of 60
        'BeginMonth | BeginDayOfMonth' => zero_or_two, # integer
        'EndMonth | EndDayOfMonth' => zero_or_two, # integer
      },

      # [BuildingConstruction]
      '/HPXML/Building/BuildingDetails/BuildingSummary/BuildingConstruction' => {
        'NumberofConditionedFloors' => one,
        'NumberofConditionedFloorsAboveGrade' => one,
        'NumberofBedrooms' => one,
        'ConditionedFloorArea' => one,
        'ConditionedBuildingVolume | AverageCeilingHeight' => one_or_more,
      },

      # [Neighbors]
      '/HPXML/Building/BuildingDetails/BuildingSummary/Site/extension/Neighbors' => {
        'NeighborBuilding' => one_or_more, # See [NeighborBuilding]
      },

      # [NeighborBuilding]
      '/HPXML/Building/BuildingDetails/BuildingSummary/Site/extension/Neighbors/NeighborBuilding' => {
        'Azimuth' => one,
        'Distance' => one, # ft
        'Height' => zero_or_one # ft; if omitted, the neighbor is the same height as the main building
      },

      # [WeatherStation]
      '/HPXML/Building/BuildingDetails/ClimateandRiskZones/WeatherStation' => {
        'SystemIdentifier' => one, # Required by HPXML schema
        'Name' => one, # Required by HPXML schema
        'WMO | extension/EPWFileName' => one, # Reference weather/data.csv for the list of acceptable WMO station numbers
      },

      # [AirInfiltration]
      '/HPXML/Building/BuildingDetails/Enclosure/AirInfiltration/AirInfiltrationMeasurement[(HousePressure=50 and BuildingAirLeakage[UnitofMeasure="ACH" or UnitofMeasure="CFM"]/AirLeakage) | extension/ConstantACHnatural]' => {
        'SystemIdentifier' => one, # Required by HPXML schema
        'InfiltrationVolume' => zero_or_one, # Assumes InfiltrationVolume = ConditionedVolume if not provided
      },

      # [Roof]
      '/HPXML/Building/BuildingDetails/Enclosure/Roofs/Roof' => {
        'SystemIdentifier' => one, # Required by HPXML schema
        '[InteriorAdjacentTo="attic - vented" or InteriorAdjacentTo="attic - unvented" or InteriorAdjacentTo="living space" or InteriorAdjacentTo="garage"]' => one, # See [VentedAttic]
        'Area' => one,
        'Azimuth' => zero_or_one,
        'SolarAbsorptance' => one,
        'Emittance' => one,
        'Pitch' => one,
        'RadiantBarrier' => one,
        'Insulation/SystemIdentifier' => one, # Required by HPXML schema
        'Insulation/AssemblyEffectiveRValue' => one,
      },

      ## [VentedAttic]
      '/HPXML/Building/BuildingDetails/Enclosure/Roofs/Roof[InteriorAdjacentTo="attic - vented"]' => {
        '../../Attics/Attic[AtticType/Attic[Vented="true"]]/VentilationRate[UnitofMeasure="SLA"]/Value | ../../Attics/Attic[AtticType/Attic[Vented="true"]]/extension/ConstantACHnatural' => zero_or_one,
      },

      # [Wall]
      '/HPXML/Building/BuildingDetails/Enclosure/Walls/Wall' => {
        'SystemIdentifier' => one, # Required by HPXML schema
        '[ExteriorAdjacentTo="outside" or ExteriorAdjacentTo="attic - vented" or ExteriorAdjacentTo="attic - unvented" or ExteriorAdjacentTo="basement - conditioned" or ExteriorAdjacentTo="basement - unconditioned" or ExteriorAdjacentTo="crawlspace - vented" or ExteriorAdjacentTo="crawlspace - unvented" or ExteriorAdjacentTo="garage" or ExteriorAdjacentTo="other housing unit"]' => one,
        '[InteriorAdjacentTo="living space" or InteriorAdjacentTo="attic - vented" or InteriorAdjacentTo="attic - unvented" or InteriorAdjacentTo="basement - conditioned" or InteriorAdjacentTo="basement - unconditioned" or InteriorAdjacentTo="crawlspace - vented" or InteriorAdjacentTo="crawlspace - unvented" or InteriorAdjacentTo="garage"]' => one,
        'WallType[WoodStud | DoubleWoodStud | ConcreteMasonryUnit | StructurallyInsulatedPanel | InsulatedConcreteForms | SteelFrame | SolidConcrete | StructuralBrick | StrawBale | Stone | LogWall]' => one,
        'Area' => one,
        'Azimuth' => zero_or_one,
        'SolarAbsorptance' => one,
        'Emittance' => one,
        'Insulation/SystemIdentifier' => one, # Required by HPXML schema
        'Insulation/AssemblyEffectiveRValue' => one,
      },

      # [RimJoist]
      '/HPXML/Building/BuildingDetails/Enclosure/RimJoists/RimJoist' => {
        'SystemIdentifier' => one, # Required by HPXML schema
        '[ExteriorAdjacentTo="outside" or ExteriorAdjacentTo="attic - vented" or ExteriorAdjacentTo="attic - unvented" or ExteriorAdjacentTo="basement - conditioned" or ExteriorAdjacentTo="basement - unconditioned" or ExteriorAdjacentTo="crawlspace - vented" or ExteriorAdjacentTo="crawlspace - unvented" or ExteriorAdjacentTo="garage" or ExteriorAdjacentTo="other housing unit"]' => one,
        '[InteriorAdjacentTo="living space" or InteriorAdjacentTo="attic - vented" or InteriorAdjacentTo="attic - unvented" or InteriorAdjacentTo="basement - conditioned" or InteriorAdjacentTo="basement - unconditioned" or InteriorAdjacentTo="crawlspace - vented" or InteriorAdjacentTo="crawlspace - unvented" or InteriorAdjacentTo="garage"]' => one,
        'Area' => one,
        'Azimuth' => zero_or_one,
        'SolarAbsorptance' => one,
        'Emittance' => one,
        'Insulation/SystemIdentifier' => one, # Required by HPXML schema
        'Insulation/AssemblyEffectiveRValue' => one,
      },

      # [FoundationWall]
      '/HPXML/Building/BuildingDetails/Enclosure/FoundationWalls/FoundationWall' => {
        'SystemIdentifier' => one, # Required by HPXML schema
        '[ExteriorAdjacentTo="ground" or ExteriorAdjacentTo="basement - conditioned" or ExteriorAdjacentTo="basement - unconditioned" or ExteriorAdjacentTo="crawlspace - vented" or ExteriorAdjacentTo="crawlspace - unvented" or ExteriorAdjacentTo="garage" or ExteriorAdjacentTo="other housing unit"]' => one,
        '[InteriorAdjacentTo="basement - conditioned" or InteriorAdjacentTo="basement - unconditioned" or InteriorAdjacentTo="crawlspace - vented" or InteriorAdjacentTo="crawlspace - unvented" or InteriorAdjacentTo="garage"]' => one, # See [VentedCrawlspace]
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
        '[ExteriorAdjacentTo="outside" or ExteriorAdjacentTo="attic - vented" or ExteriorAdjacentTo="attic - unvented" or ExteriorAdjacentTo="basement - conditioned" or ExteriorAdjacentTo="basement - unconditioned" or ExteriorAdjacentTo="crawlspace - vented" or ExteriorAdjacentTo="crawlspace - unvented" or ExteriorAdjacentTo="garage" or ExteriorAdjacentTo="other housing unit above" or ExteriorAdjacentTo="other housing unit below"]' => one,
        '[InteriorAdjacentTo="living space" or InteriorAdjacentTo="attic - vented" or InteriorAdjacentTo="attic - unvented" or InteriorAdjacentTo="basement - conditioned" or InteriorAdjacentTo="basement - unconditioned" or InteriorAdjacentTo="crawlspace - vented" or InteriorAdjacentTo="crawlspace - unvented" or InteriorAdjacentTo="garage"]' => one,
        'Area' => one,
        'Insulation/SystemIdentifier' => one, # Required by HPXML schema
        'Insulation/AssemblyEffectiveRValue' => one,
      },

      # [Slab]
      '/HPXML/Building/BuildingDetails/Enclosure/Slabs/Slab' => {
        'SystemIdentifier' => one, # Required by HPXML schema
        '[InteriorAdjacentTo="living space" or InteriorAdjacentTo="basement - conditioned" or InteriorAdjacentTo="basement - unconditioned" or InteriorAdjacentTo="crawlspace - vented" or InteriorAdjacentTo="crawlspace - unvented" or InteriorAdjacentTo="garage"]' => one,
        'Area' => one,
        'Thickness' => one, # Use zero for dirt floor
        'ExposedPerimeter' => one,
        'PerimeterInsulationDepth' => one,
        'UnderSlabInsulationWidth | [UnderSlabInsulationSpansEntireSlab="true"]' => one,
        'DepthBelowGrade | [InteriorAdjacentTo!="living space" and InteriorAdjacentTo!="garage"]' => one_or_more, # DepthBelowGrade only required when InteriorAdjacentTo is 'living space' or 'garage'
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
        'InteriorShading/SummerShadingCoefficient' => zero_or_one, # Uses ERI assumption if not provided
        'InteriorShading/WinterShadingCoefficient' => zero_or_one, # Uses ERI assumption if not provided
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
        'HeatingSystemType[ElectricResistance | Furnace | WallFurnace | Boiler | Stove | PortableHeater]' => one, # See [HeatingType=Resistance] or [HeatingType=Furnace] or [HeatingType=WallFurnace] or [HeatingType=Boiler] or [HeatingType=Stove] or [HeatingType=PortableHeater]
        'HeatingCapacity' => one, # Use -1 for autosizing
        'FractionHeatLoadServed' => one, # Must sum to <= 1 across all HeatingSystems and HeatPumps
        'ElectricAuxiliaryEnergy' => zero_or_one, # If not provided, uses 301 defaults for fuel furnace/boiler and zero otherwise
      },

      ## [HeatingType=Resistance]
      '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem[HeatingSystemType/ElectricResistance]' => {
        'DistributionSystem' => zero,
        '[HeatingSystemFuel="electricity"]' => one,
        'AnnualHeatingEfficiency[Units="Percent"]/Value' => one,
      },

      ## [HeatingType=Furnace]
      '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem[HeatingSystemType/Furnace]' => {
        '../../HVACDistribution[DistributionSystemType/AirDistribution | DistributionSystemType[Other="DSE"]]' => one_or_more, # See [HVACDistribution]
        'DistributionSystem' => one,
        '[HeatingSystemFuel="natural gas" or HeatingSystemFuel="fuel oil" or HeatingSystemFuel="propane" or HeatingSystemFuel="electricity" or HeatingSystemFuel="wood"]' => one, # See [HeatingType=FuelEquipment] if not electricity
        'AnnualHeatingEfficiency[Units="AFUE"]/Value' => one,
      },

      ## [HeatingType=WallFurnace]
      '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem[HeatingSystemType/WallFurnace]' => {
        'DistributionSystem' => zero,
        '[HeatingSystemFuel="natural gas" or HeatingSystemFuel="fuel oil" or HeatingSystemFuel="propane" or HeatingSystemFuel="electricity" or HeatingSystemFuel="wood"]' => one, # See [HeatingType=FuelEquipment] if not electricity
        'AnnualHeatingEfficiency[Units="AFUE"]/Value' => one,
      },

      ## [HeatingType=Boiler]
      '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem[HeatingSystemType/Boiler]' => {
        '../../HVACDistribution[DistributionSystemType/HydronicDistribution | DistributionSystemType[Other="DSE"]]' => one_or_more, # See [HVACDistribution]
        'DistributionSystem' => one,
        '[HeatingSystemFuel="natural gas" or HeatingSystemFuel="fuel oil" or HeatingSystemFuel="propane" or HeatingSystemFuel="electricity" or HeatingSystemFuel="wood"]' => one, # See [HeatingType=FuelEquipment] if not electricity
        'AnnualHeatingEfficiency[Units="AFUE"]/Value' => one,
      },

      ## [HeatingType=Stove]
      '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem[HeatingSystemType/Stove]' => {
        'DistributionSystem' => zero,
        '[HeatingSystemFuel="natural gas" or HeatingSystemFuel="fuel oil" or HeatingSystemFuel="propane" or HeatingSystemFuel="electricity" or HeatingSystemFuel="wood" or HeatingSystemFuel="wood pellets"]' => one, # See [HeatingType=FuelEquipment] if not electricity
        'AnnualHeatingEfficiency[Units="Percent"]/Value' => one,
      },

      ## [HeatingType=PortableHeater]
      '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem[HeatingSystemType/PortableHeater]' => {
        'DistributionSystem' => zero,
        '[HeatingSystemFuel="natural gas" or HeatingSystemFuel="fuel oil" or HeatingSystemFuel="propane" or HeatingSystemFuel="electricity" or HeatingSystemFuel="wood" or HeatingSystemFuel="wood pellets"]' => one, # See [HeatingType=FuelEquipment] if not electricity
        'AnnualHeatingEfficiency[Units="Percent"]/Value' => one,
      },

      # [CoolingSystem]
      '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/CoolingSystem' => {
        'SystemIdentifier' => one, # Required by HPXML schema
        '../../HVACControl' => one, # See [HVACControl]
        '[CoolingSystemType="central air conditioner" or CoolingSystemType="room air conditioner" or CoolingSystemType="evaporative cooler"]' => one, # See [CoolingType=CentralAC] or [CoolingType=RoomAC] or [CoolingType=EvapCooler]
        '[CoolingSystemFuel="electricity"]' => one,
        'FractionCoolLoadServed' => one, # Must sum to <= 1 across all CoolingSystems and HeatPumps
      },

      ## [CoolingType=CentralAC]
      '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/CoolingSystem[CoolingSystemType="central air conditioner"]' => {
        '../../HVACDistribution[DistributionSystemType/AirDistribution | DistributionSystemType[Other="DSE"]]' => one_or_more, # See [HVACDistribution]
        'DistributionSystem' => one,
        'CoolingCapacity' => one, # Use -1 for autosizing
        '[not(CompressorType) or CompressorType="single stage" or CompressorType="two stage" or CompressorType="variable speed"]' => one,
        'AnnualCoolingEfficiency[Units="SEER"]/Value' => one,
        'SensibleHeatFraction' => zero_or_one,
      },

      ## [CoolingType=RoomAC]
      '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/CoolingSystem[CoolingSystemType="room air conditioner"]' => {
        'DistributionSystem' => zero,
        'CoolingCapacity' => one, # Use -1 for autosizing
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
        '[HeatPumpType="air-to-air" or HeatPumpType="mini-split" or HeatPumpType="ground-to-air"]' => one, # See [HeatPumpType=ASHP] or [HeatPumpType=MSHP] or [HeatPumpType=GSHP]
        '[HeatPumpFuel="electricity"]' => one,
        'HeatingCapacity' => one, # Use -1 for autosizing
        'CoolingCapacity' => one, # Use -1 for autosizing
        'CoolingSensibleHeatFraction' => zero_or_one,
        '[not(BackupSystemFuel) or BackupSystemFuel="electricity" or BackupSystemFuel="natural gas" or BackupSystemFuel="fuel oil" or BackupSystemFuel="propane"]' => one, # See [HeatPumpBackup]
        'FractionHeatLoadServed' => one, # Must sum to <= 1 across all HeatPumps and HeatingSystems
        'FractionCoolLoadServed' => one, # Must sum to <= 1 across all HeatPumps and CoolingSystems
      },

      ## [HeatPumpType=ASHP]
      '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatPump[HeatPumpType="air-to-air"]' => {
        '../../HVACDistribution[DistributionSystemType/AirDistribution | DistributionSystemType[Other="DSE"]]' => one_or_more, # See [HVACDistribution]
        'DistributionSystem' => one,
        '[not(CompressorType) or CompressorType="single stage" or CompressorType="two stage" or CompressorType="variable speed"]' => one,
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
        'BackupHeatingCapacity' => one, # Use -1 for autosizing
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
        'DuctLeakageMeasurement[DuctType="supply"]/DuctLeakage[Units="CFM25" or Units="Percent"][TotalOrToOutside="to outside"]/Value' => one,
        'DuctLeakageMeasurement[DuctType="return"]/DuctLeakage[Units="CFM25" or Units="Percent"][TotalOrToOutside="to outside"]/Value' => zero_or_one,
        'Ducts[DuctType="supply"]' => zero_or_more, # See [HVACDuct]
        'Ducts[DuctType="return"]' => zero_or_more, # See [HVACDuct]
      },

      ## [HVACDistType=DSE]
      ## WARNING: These inputs are unused and EnergyPlus output will NOT reflect the specified DSE. To account for DSE, apply the value to the EnergyPlus output.
      '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution[DistributionSystemType[Other="DSE"]]' => {
        'AnnualHeatingDistributionSystemEfficiency | AnnualCoolingDistributionSystemEfficiency' => one_or_more,
      },

      ## [HVACDuct]
      '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution/DistributionSystemType/AirDistribution/Ducts[DuctType="supply" or DuctType="return"]' => {
        'DuctInsulationRValue' => one,
        '[DuctLocation="living space" or DuctLocation="basement - conditioned" or DuctLocation="basement - unconditioned" or DuctLocation="crawlspace - vented" or DuctLocation="crawlspace - unvented" or DuctLocation="attic - vented" or DuctLocation="attic - unvented" or DuctLocation="garage" or DuctLocation="outside"]' => one,
        'DuctSurfaceArea' => one,
      },

      # [MechanicalVentilation]
      '/HPXML/Building/BuildingDetails/Systems/MechanicalVentilation/VentilationFans/VentilationFan[UsedForWholeBuildingVentilation="true"]' => {
        'SystemIdentifier' => one, # Required by HPXML schema
        '[FanType="energy recovery ventilator" or FanType="heat recovery ventilator" or FanType="exhaust only" or FanType="supply only" or FanType="balanced" or FanType="central fan integrated supply"]' => one, # See [MechVentType=HRV] or [MechVentType=ERV] or [MechVentType=CFIS]
        'TestedFlowRate | RatedFlowRate' => one_or_more,
        'HoursInOperation' => one,
        'FanPower' => one,
      },

      ## [MechVentType=HRV]
      '/HPXML/Building/BuildingDetails/Systems/MechanicalVentilation/VentilationFans/VentilationFan[UsedForWholeBuildingVentilation="true"][FanType="heat recovery ventilator"]' => {
        'SensibleRecoveryEfficiency | AdjustedSensibleRecoveryEfficiency' => one,
      },

      ## [MechVentType=ERV]
      '/HPXML/Building/BuildingDetails/Systems/MechanicalVentilation/VentilationFans/VentilationFan[UsedForWholeBuildingVentilation="true"][FanType="energy recovery ventilator"]' => {
        'TotalRecoveryEfficiency | AdjustedTotalRecoveryEfficiency' => one,
        'SensibleRecoveryEfficiency | AdjustedSensibleRecoveryEfficiency' => one,
      },

      ## [MechVentType=CFIS]
      '/HPXML/Building/BuildingDetails/Systems/MechanicalVentilation/VentilationFans/VentilationFan[UsedForWholeBuildingVentilation="true"][FanType="central fan integrated supply"]' => {
        'AttachedToHVACDistributionSystem' => one,
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
        '[WaterHeaterType="storage water heater" or WaterHeaterType="instantaneous water heater" or WaterHeaterType="heat pump water heater" or WaterHeaterType="space-heating boiler with storage tank" or WaterHeaterType="space-heating boiler with tankless coil"]' => one, # See [WHType=Tank] or [WHType=Tankless] or [WHType=HeatPump] or [WHType=Indirect] or [WHType=CombiTankless]
        '[not(Location) or Location="living space" or Location="basement - unconditioned" or Location="basement - conditioned" or Location="attic - unvented" or Location="attic - vented" or Location="garage" or Location="crawlspace - unvented" or Location="crawlspace - vented" or Location="other exterior"]' => one,
        'FractionDHWLoadServed' => one,
        'HotWaterTemperature' => zero_or_one,
        'UsesDesuperheater' => zero_or_one, # See [Desuperheater]
      },

      ## [WHType=Tank]
      '/HPXML/Building/BuildingDetails/Systems/WaterHeating/WaterHeatingSystem[WaterHeaterType="storage water heater"]' => {
        '[FuelType="natural gas" or FuelType="fuel oil" or FuelType="propane" or FuelType="electricity" or FuelType="wood"]' => one, # If not electricity, see [WHType=FuelTank]
        'TankVolume' => one,
        'HeatingCapacity' => one,
        'EnergyFactor | UniformEnergyFactor' => one,
        'WaterHeaterInsulation/Jacket/JacketRValue' => zero_or_one, # Capable to model tank wrap insulation
      },

      ## [WHType=FuelTank]
      '/HPXML/Building/BuildingDetails/Systems/WaterHeating/WaterHeatingSystem[WaterHeaterType="storage water heater" and FuelType!="electricity"]' => {
        'RecoveryEfficiency' => one,
      },

      ## [WHType=Tankless]
      '/HPXML/Building/BuildingDetails/Systems/WaterHeating/WaterHeatingSystem[WaterHeaterType="instantaneous water heater"]' => {
        '[FuelType="natural gas" or FuelType="fuel oil" or FuelType="propane" or FuelType="electricity" or FuelType="wood"]' => one,
        'PerformanceAdjustment' => zero_or_one, # Uses ERI assumption for tankless cycling derate if not provided
        'EnergyFactor | UniformEnergyFactor' => one,
      },

      ## [WHType=HeatPump]
      '/HPXML/Building/BuildingDetails/Systems/WaterHeating/WaterHeatingSystem[WaterHeaterType="heat pump water heater"]' => {
        '[FuelType="electricity"]' => one,
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
        '[WaterHeaterType="storage water heater" or WaterHeaterType="instantaneous water heater"]' => one, # Desuperheater is only supported with storage/tankless water heater
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
        '[ControlType="manual demand control" or ControlType="presence sensor demand control" or ControlType="temperature" or ControlType="timer" or ControlType="no control"]' => one,
        'RecirculationPipingLoopLength' => one,
        'BranchPipingLoopLength' => one,
        'PumpPower' => one,
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
        '[WaterFixtureType="shower head" or WaterFixtureType="faucet"]' => one, # Required by HPXML schema
        'LowFlow' => one,
      },

      # [SolarThermalSystem]
      '/HPXML/Building/BuildingDetails/Systems/SolarThermal/SolarThermalSystem' => {
        'SystemIdentifier' => one, # Required by HPXML schema
        '[SystemType="hot water"]' => one,
        'CollectorArea | SolarFraction' => one, # See [SolarThermal=Detailed] if CollectorArea provided
        'ConnectedTo' => one, # WaterHeatingSystem (any type but space-heating boiler)
      },

      ## [SolarThermal=Detailed]
      '/HPXML/Building/BuildingDetails/Systems/SolarThermal/SolarThermalSystem[CollectorArea]' => {
        '[CollectorLoopType="liquid indirect" or CollectorLoopType="liquid direct" or CollectorLoopType="passive thermosyphon"]' => one,
        '[CollectorType="single glazing black" or CollectorType="double glazing black" or CollectorType="evacuated tube" or CollectorType="integrated collector storage"]' => one,
        'CollectorAzimuth' => one,
        'CollectorTilt' => one,
        'CollectorRatedOpticalEfficiency' => one,
        'CollectorRatedThermalLosses' => one,
        'StorageVolume' => one,
      },

      # [PVSystem]
      '/HPXML/Building/BuildingDetails/Systems/Photovoltaics/PVSystem' => {
        'SystemIdentifier' => one, # Required by HPXML schema
        '[Location="ground" or Location="roof"]' => one,
        '[ModuleType="standard" or ModuleType="premium" or ModuleType="thin film"]' => one,
        '[Tracking="fixed" or Tracking="1-axis" or Tracking="1-axis backtracked" or Tracking="2-axis"]' => one,
        'ArrayAzimuth' => one,
        'ArrayTilt' => one,
        'MaxPowerOutput' => one,
        'InverterEfficiency' => zero_or_one,
        'SystemLossesFraction | YearModulesManufactured' => zero_or_more,
      },

      # [ClothesWasher]
      '/HPXML/Building/BuildingDetails/Appliances/ClothesWasher' => {
        'SystemIdentifier' => one, # Required by HPXML schema
        '[not(Location) or Location="living space" or Location="basement - conditioned" or Location="basement - unconditioned" or Location="garage"]' => one,
        '[ModifiedEnergyFactor | IntegratedModifiedEnergyFactor] | RatedAnnualkWh | LabelElectricRate | LabelGasRate | LabelAnnualGasCost | Capacity' => zero_or_six,
      },

      # [ClothesDryer]
      '/HPXML/Building/BuildingDetails/Appliances/ClothesDryer' => {
        'SystemIdentifier' => one, # Required by HPXML schema
        '[not(Location) or Location="living space" or Location="basement - conditioned" or Location="basement - unconditioned" or Location="garage"]' => one,
        '[FuelType="natural gas" or FuelType="fuel oil" or FuelType="propane" or FuelType="electricity" or FuelType="wood"]' => one,
        '[EnergyFactor | CombinedEnergyFactor] | ControlType' => zero_or_two,
      },

      # [Dishwasher]
      '/HPXML/Building/BuildingDetails/Appliances/Dishwasher' => {
        'SystemIdentifier' => one, # Required by HPXML schema
        '[EnergyFactor | RatedAnnualkWh] | PlaceSettingCapacity' => zero_or_two,
      },

      # [Refrigerator]
      '/HPXML/Building/BuildingDetails/Appliances/Refrigerator' => {
        'SystemIdentifier' => one, # Required by HPXML schema
        '[not(Location) or Location="living space" or Location="basement - conditioned" or Location="basement - unconditioned" or Location="garage"]' => one,
        'RatedAnnualkWh | extension/AdjustedAnnualkWh' => zero_or_more,
      },

      # [CookingRange]
      '/HPXML/Building/BuildingDetails/Appliances/CookingRange' => {
        'SystemIdentifier' => one, # Required by HPXML schema
        '[FuelType="natural gas" or FuelType="fuel oil" or FuelType="propane" or FuelType="electricity" or FuelType="wood"]' => one,
        'IsInduction' => zero_or_one,
        '../Oven/IsConvection' => zero_or_one,
      },

      # [Lighting]
      '/HPXML/Building/BuildingDetails/Lighting' => {
        'LightingGroup[(ThirdPartyCertification="ERI Tier I" or ThirdPartyCertification="ERI Tier II") and (Location="interior" or Location="exterior" or Location="garage")]' => zero_or_six, # See [LightingGroup]
      },

      ## [LightingGroup]
      '/HPXML/Building/BuildingDetails/Lighting/LightingGroup[(ThirdPartyCertification="ERI Tier I" or ThirdPartyCertification="ERI Tier II") and (Location="interior" or Location="exterior" or Location="garage")]' => {
        'SystemIdentifier' => one, # Required by HPXML schema
        'FractionofUnitsInLocation' => one,
      },

      # [CeilingFan]
      '/HPXML/Building/BuildingDetails/Lighting/CeilingFan' => {
        'SystemIdentifier' => one, # Required by HPXML schema
        'Airflow[FanSpeed="medium"]/Efficiency' => zero_or_one, # Uses Reference Home if not provided
        'Quantity' => zero_or_one, # Uses Reference Home if not provided
      },

      # [PlugLoads]
      '/HPXML/Building/BuildingDetails/MiscLoads/PlugLoad[PlugLoadType="other"]' => {
        'SystemIdentifier' => one, # Required by HPXML schema
        'Load[Units="kWh/year"]/Value' => zero_or_one, # Uses ERI Reference Home if not provided
        'extension/FracSensible' => zero_or_one, # Uses ERI Reference Home if not provided
        'extension/FracLatent' => zero_or_one, # Uses ERI Reference Home if not provided
        '../extension/WeekdayScheduleFractions' => zero_or_one, # Uses ERI Reference Home if not provided
        '../extension/WeekendScheduleFractions' => zero_or_one, # Uses ERI Reference Home if not provided
        '../extension/MonthlyScheduleMultipliers' => zero_or_one, # Uses ERI Reference Home if not provided
      },

      # [Television]
      '/HPXML/Building/BuildingDetails/MiscLoads/PlugLoad[PlugLoadType="TV other"]' => {
        'SystemIdentifier' => one, # Required by HPXML schema
        'Load[Units="kWh/year"]/Value' => zero_or_one, # Uses ERI Reference Home if not provided
        '../extension/WeekdayScheduleFractions' => zero_or_one, # Uses ERI Reference Home if not provided
        '../extension/WeekendScheduleFractions' => zero_or_one, # Uses ERI Reference Home if not provided
        '../extension/MonthlyScheduleMultipliers' => zero_or_one, # Uses ERI Reference Home if not provided
      },

    }

    errors = []
    requirements.each do |parent, requirement|
      if parent.nil? # Unconditional
        requirement.each do |child, expected_sizes|
          next if expected_sizes.nil?

          xpath = combine_into_xpath(parent, child)
          actual_size = REXML::XPath.first(hpxml_doc, "count(#{xpath})")
          check_number_of_elements(actual_size, expected_sizes, xpath, errors)
        end
      else # Conditional based on parent element existence
        next if hpxml_doc.elements[parent].nil? # Skip if parent element doesn't exist

        hpxml_doc.elements.each(parent) do |parent_element|
          requirement.each do |child, expected_sizes|
            next if expected_sizes.nil?

            xpath = combine_into_xpath(parent, child)
            actual_size = REXML::XPath.first(parent_element, "count(#{child})")
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
    elsif child.start_with?('[')
      return [parent, child].join('')
    end

    return [parent, child].join('/')
  end
end
