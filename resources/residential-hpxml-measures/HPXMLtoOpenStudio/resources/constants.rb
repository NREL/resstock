class Constants
  # Numbers --------------------

  def self.AssumedInsideTemp
    return 73.5 # deg-F
  end

  def self.DefaultFramingFactorInterior
    return 0.16
  end

  def self.DefaultHumiditySetpoint
    return 0.60
  end

  def self.g
    return 32.174 # gravity (ft/s2)
  end

  def self.MonthNumDays
    return [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
  end

  def self.Patm
    return 14.696 # standard atmospheric pressure (psia)
  end

  def self.small
    return 1e-9
  end

  # Strings --------------------

  def self.AirFilm
    return 'AirFilm'
  end

  def self.Auto
    return 'auto'
  end

  def self.ColorWhite
    return 'white'
  end

  def self.ColorLight
    return 'light'
  end

  def self.ColorMedium
    return 'medium'
  end

  def self.ColorDark
    return 'dark'
  end

  def self.BoilerTypeCondensing
    return 'hot water, condensing'
  end

  def self.BoilerTypeNaturalDraft
    return 'hot water, natural draft'
  end

  def self.BoilerTypeForcedDraft
    return 'hot water, forced draft'
  end

  def self.BoilerTypeSteam
    return 'steam'
  end

  def self.BoreConfigSingle
    return 'single'
  end

  def self.BoreConfigLine
    return 'line'
  end

  def self.BoreConfigOpenRectangle
    return 'open-rectangle'
  end

  def self.BoreConfigRectangle
    return 'rectangle'
  end

  def self.BoreConfigLconfig
    return 'l-config'
  end

  def self.BoreConfigL2config
    return 'l2-config'
  end

  def self.BoreConfigUconfig
    return 'u-config'
  end

  def self.BuildingAmericaClimateZone
    return 'Building America'
  end

  def self.CalcTypeERIRatedHome
    return 'ERI Rated Home'
  end

  def self.CalcTypeERIReferenceHome
    return 'ERI Reference Home'
  end

  def self.CalcTypeERIIndexAdjustmentDesign
    return 'ERI Index Adjustment Design'
  end

  def self.CalcTypeERIIndexAdjustmentReferenceHome
    return 'ERI Index Adjustment Reference Home'
  end

  def self.DuctSideReturn
    return 'return'
  end

  def self.DuctSideSupply
    return 'supply'
  end

  def self.OptionallyDuctedSystemIsDucted
    return __method__.to_s
  end

  def self.FacadeFront
    return 'front'
  end

  def self.FacadeBack
    return 'back'
  end

  def self.FacadeLeft
    return 'left'
  end

  def self.FacadeRight
    return 'right'
  end

  def self.FluidWater
    return 'water'
  end

  def self.FluidPropyleneGlycol
    return 'propylene-glycol'
  end

  def self.FluidEthyleneGlycol
    return 'ethylene-glycol'
  end

  def self.MaterialGypcrete
    return 'crete'
  end

  def self.MaterialGypsum
    return 'gyp'
  end

  def self.MaterialOSB
    return 'osb'
  end

  def self.MonthNames
    return ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
  end

  def self.ObjectNameAirflow
    return "airflow"
  end

  def self.ObjectNameAirSourceHeatPump
    return "ashp"
  end

  def self.ObjectNameBackupHeatingCoil
    return "backup htg coil"
  end

  def self.ObjectNameBath
    return "res baths"
  end

  def self.ObjectNameBoiler
    return "boiler"
  end

  def self.ObjectNameCeilingFan
    return "ceiling fan"
  end

  def self.ObjectNameCentralAirConditioner
    return "central ac"
  end

  def self.ObjectNameCentralAirConditionerAndFurnace
    return "central ac and furnace"
  end

  def self.ObjectNameClothesWasher
    return "clothes washer"
  end

  def self.ObjectNameClothesDryer
    return "clothes dryer"
  end

  def self.ObjectNameCookingRange
    return "cooking range"
  end

  def self.ObjectNameCoolingSeason
    return 'cooling season'
  end

  def self.ObjectNameCoolingSetpoint
    return 'cooling setpoint'
  end

  def self.ObjectNameDehumidifier
    return "dehumidifier"
  end

  def self.ObjectNameDishwasher
    return "dishwasher"
  end

  def self.ObjectNameElectricBaseboard
    return "baseboard"
  end

  def self.ObjectNameEvaporativeCooler
    return "evap cooler"
  end

  def self.ObjectNameFanPumpDisaggregateCool(fan_or_pump_name = "")
    return "#{fan_or_pump_name} clg disaggregate"
  end

  def self.ObjectNameFanPumpDisaggregatePrimaryHeat(fan_or_pump_name = "")
    return "#{fan_or_pump_name} htg primary disaggregate"
  end

  def self.ObjectNameFanPumpDisaggregateBackupHeat(fan_or_pump_name = "")
    return "#{fan_or_pump_name} htg backup disaggregate"
  end

  def self.ObjectNameFixtures
    return "dhw fixtures"
  end

  def self.ObjectNameFurnace
    return "furnace"
  end

  def self.ObjectNameFurniture
    return "furniture"
  end

  def self.ObjectNameGroundSourceHeatPump
    return "gshp"
  end

  def self.ObjectNameHeatingSeason
    return 'heating season'
  end

  def self.ObjectNameHeatingSetpoint
    return 'heating setpoint'
  end

  def self.ObjectNameHotWaterRecircPump
    return "dhw recirc pump"
  end

  def self.ObjectNameIdealAirSystem
    return "ideal"
  end

  def self.ObjectNameInfiltration
    return "infil"
  end

  def self.ObjectNameERVHRV
    return "erv or hrv"
  end

  def self.ObjectNameExteriorLighting
    return "exterior lighting"
  end

  def self.ObjectNameGarageLighting
    return "garage lighting"
  end

  def self.ObjectNameInteriorLighting
    return "interior lighting"
  end

  def self.ObjectNameMechanicalVentilation
    return "mech vent"
  end

  def self.ObjectNameMiniSplitHeatPump
    return "mshp"
  end

  def self.ObjectNameMiscPlugLoads
    return "misc plug loads"
  end

  def self.ObjectNameMiscTelevision
    return "misc tv"
  end

  def self.ObjectNameNaturalVentilation
    return "natural vent"
  end

  def self.ObjectNameNeighbors
    return "neighbors"
  end

  def self.ObjectNameOccupants
    return "occupants"
  end

  def self.ObjectNameOverhangs
    return "overhangs"
  end

  def self.ObjectNameRefrigerator
    return "fridge"
  end

  def self.ObjectNameRelativeHumiditySetpoint
    return "rh setpoint"
  end

  def self.ObjectNameRoomAirConditioner
    return "room ac"
  end

  def self.ObjectNameShower
    return "res showers"
  end

  def self.ObjectNameSink
    return "res sinks"
  end

  def self.ObjectNameSolarHotWater
    return "solar hot water"
  end

  def self.ObjectNameUnitHeater
    return "unit heater"
  end

  def self.ObjectNameWaterHeater
    return "water heater"
  end

  def self.ObjectNameWaterHeaterAdjustment(water_heater_name)
    return "#{water_heater_name} EC adjustment"
  end

  def self.ObjectNameDesuperheater(water_heater_name)
    return "#{water_heater_name} Desuperheater"
  end

  def self.ObjectNameDesuperheaterEnergy(water_heater_name)
    return "#{water_heater_name} Desuperheater energy"
  end

  def self.ObjectNameDesuperheaterLoad(water_heater_name)
    return "#{water_heater_name} Desuperheater load"
  end

  def self.ObjectNameTankHX
    return "dhw source hx"
  end

  def self.PlantLoopDomesticWater
    return "dhw loop"
  end

  def self.PlantLoopSolarHotWater
    return "solar hot water loop"
  end

  def self.RoofMaterialAsphaltShingles
    return 'asphalt shingles'
  end

  def self.RoofMaterialMembrane
    return 'membrane'
  end

  def self.RoofMaterialMetal
    return 'metal'
  end

  def self.RoofMaterialTarGravel
    return 'tar gravel'
  end

  def self.RoofMaterialTile
    return 'tile'
  end

  def self.RoofMaterialWoodShakes
    return 'wood shakes'
  end

  def self.ScheduleTypeLimitsFraction
    return 'Fractional'
  end

  def self.ScheduleTypeLimitsOnOff
    return 'OnOff'
  end

  def self.ScheduleTypeLimitsTemperature
    return 'Temperature'
  end

  def self.SeasonHeating
    return 'Heating'
  end

  def self.SeasonCooling
    return 'Cooling'
  end

  def self.SeasonOverlap
    return 'Overlap'
  end

  def self.SeasonNone
    return 'None'
  end

  def self.SizingAuto
    return 'autosize'
  end

  def self.SizingInfoCMUWallFurringInsRvalue
    return __method__.to_s
  end

  def self.SizingInfoDuctExist
    return __method__.to_s
  end

  def self.SizingInfoDuctSides
    return __method__.to_s
  end

  def self.SizingInfoDuctLocationZones
    return __method__.to_s
  end

  def self.SizingInfoDuctLeakageFracs
    return __method__.to_s
  end

  def self.SizingInfoDuctLeakageCFM25s
    return __method__.to_s
  end

  def self.SizingInfoDuctAreas
    return __method__.to_s
  end

  def self.SizingInfoDuctRvalues
    return __method__.to_s
  end

  def self.SizingInfoHVACFracHeatLoadServed
    return __method__.to_s
  end

  def self.SizingInfoHVACFracCoolLoadServed
    return __method__.to_s
  end

  def self.SizingInfoHVACCoolType
    return __method__.to_s
  end

  def self.SizingInfoHVACHeatType
    return __method__.to_s
  end

  def self.SizingInfoGSHPBoreConfig
    return __method__.to_s
  end

  def self.SizingInfoGSHPBoreDepth
    return __method__.to_s
  end

  def self.SizingInfoGSHPBoreHoles
    return __method__.to_s
  end

  def self.SizingInfoGSHPBoreSpacing
    return __method__.to_s
  end

  def self.SizingInfoGSHPCoil_BF_FT_SPEC
    return __method__.to_s
  end

  def self.SizingInfoGSHPCoilBF
    return __method__.to_s
  end

  def self.SizingInfoGSHPUTubeSpacingType
    return __method__.to_s
  end

  def self.SizingInfoHVACCapacityRatioCooling
    return __method__.to_s
  end

  def self.SizingInfoHVACCapacityRatioHeating
    return __method__.to_s
  end

  def self.SizingInfoHVACCoolingCFMs
    return __method__.to_s
  end

  def self.SizingInfoHVACHeatingCapacityOffset
    return __method__.to_s
  end

  def self.SizingInfoHVACHeatingCFMs
    return __method__.to_s
  end

  def self.SizingInfoHVACRatedCFMperTonHeating
    return __method__.to_s
  end

  def self.SizingInfoHVACRatedCFMperTonCooling
    return __method__.to_s
  end

  def self.SizingInfoHVACSHR
    return __method__.to_s
  end

  def self.SizingInfoMechVentType
    return __method__.to_s
  end

  def self.SizingInfoMechVentApparentSensibleEffectiveness
    return __method__.to_s
  end

  def self.SizingInfoMechVentLatentEffectiveness
    return __method__.to_s
  end

  def self.SizingInfoMechVentTotalEfficiency
    return __method__.to_s
  end

  def self.SizingInfoMechVentWholeHouseRate
    return __method__.to_s
  end

  def self.SizingInfoRoofCavityRvalue
    return __method__.to_s
  end

  def self.SizingInfoRoofColor
    return __method__.to_s
  end

  def self.SizingInfoRoofHasRadiantBarrier
    return __method__.to_s
  end

  def self.SizingInfoRoofMaterial
    return __method__.to_s
  end

  def self.SizingInfoRoofRigidInsRvalue
    return __method__.to_s
  end

  def self.SizingInfoSIPWallInsThickness
    return __method__.to_s
  end

  def self.SizingInfoSlabRvalue
    return __method__.to_s
  end

  def self.SizingInfoStudWallCavityRvalue
    return __method__.to_s
  end

  def self.SizingInfoWallType
    return __method__.to_s
  end

  def self.SizingInfoWallRigidInsRvalue
    return __method__.to_s
  end

  def self.SizingInfoWallRigidInsThickness
    return __method__.to_s
  end

  def self.SizingInfoWindowOverhangDepth
    return __method__.to_s
  end

  def self.SizingInfoWindowOverhangOffset
    return __method__.to_s
  end

  def self.SizingInfoZoneInfiltrationACH
    return __method__.to_s
  end

  def self.SizingInfoZoneInfiltrationCFM
    return __method__.to_s
  end

  def self.SizingInfoZoneInfiltrationELA
    return __method__.to_s
  end

  def self.TerrainOcean
    return 'ocean'
  end

  def self.TerrainPlains
    return 'plains'
  end

  def self.TerrainRural
    return 'rural'
  end

  def self.TerrainSuburban
    return 'suburban'
  end

  def self.TerrainCity
    return 'city'
  end
end

class OutputVars
  def self.SpaceHeatingElectricity
    return { 'OpenStudio::Model::CoilHeatingDXSingleSpeed' => ['Heating Coil Electric Energy', 'Heating Coil Crankcase Heater Electric Energy', 'Heating Coil Defrost Electric Energy'],
             'OpenStudio::Model::CoilHeatingDXMultiSpeed' => ['Heating Coil Electric Energy', 'Heating Coil Crankcase Heater Electric Energy', 'Heating Coil Defrost Electric Energy'],
             'OpenStudio::Model::CoilHeatingElectric' => ['Heating Coil Electric Energy', 'Heating Coil Crankcase Heater Electric Energy', 'Heating Coil Defrost Electric Energy'],
             'OpenStudio::Model::CoilHeatingWaterToAirHeatPumpEquationFit' => ['Heating Coil Electric Energy', 'Heating Coil Crankcase Heater Electric Energy', 'Heating Coil Defrost Electric Energy'],
             'OpenStudio::Model::ZoneHVACBaseboardConvectiveElectric' => ['Baseboard Electric Energy'],
             'OpenStudio::Model::BoilerHotWater' => ['Boiler Electric Energy'] }
  end

  def self.SpaceHeatingNaturalGas
    return { 'OpenStudio::Model::CoilHeatingGas' => ['Heating Coil Gas Energy'],
             'OpenStudio::Model::ZoneHVACBaseboardConvectiveElectric' => ['Baseboard Gas Energy'],
             'OpenStudio::Model::BoilerHotWater' => ['Boiler Gas Energy'] }
  end

  def self.SpaceHeatingFuelOil
    return { 'OpenStudio::Model::CoilHeatingGas' => ['Heating Coil FuelOil#1 Energy'],
             'OpenStudio::Model::ZoneHVACBaseboardConvectiveElectric' => ['Baseboard FuelOil#1 Energy'],
             'OpenStudio::Model::BoilerHotWater' => ['Boiler FuelOil#1 Energy'] }
  end

  def self.SpaceHeatingPropane
    return { 'OpenStudio::Model::CoilHeatingGas' => ['Heating Coil Propane Energy'],
             'OpenStudio::Model::ZoneHVACBaseboardConvectiveElectric' => ['Baseboard Propane Energy'],
             'OpenStudio::Model::BoilerHotWater' => ['Boiler Propane Energy'] }
  end

  def self.SpaceHeatingDFHPPrimaryLoad
    return { 'OpenStudio::Model::CoilHeatingDXSingleSpeed' => ['Heating Coil Heating Energy'],
             'OpenStudio::Model::CoilHeatingDXMultiSpeed' => ['Heating Coil Heating Energy'] }
  end

  def self.SpaceHeatingDFHPBackupLoad
    return { 'OpenStudio::Model::CoilHeatingElectric' => ['Heating Coil Heating Energy'],
             'OpenStudio::Model::CoilHeatingGas' => ['Heating Coil Heating Energy'] }
  end

  def self.SpaceCoolingElectricity
    return { 'OpenStudio::Model::CoilCoolingDXSingleSpeed' => ['Cooling Coil Electric Energy', 'Cooling Coil Crankcase Heater Electric Energy'],
             'OpenStudio::Model::CoilCoolingDXMultiSpeed' => ['Cooling Coil Electric Energy', 'Cooling Coil Crankcase Heater Electric Energy'],
             'OpenStudio::Model::CoilCoolingWaterToAirHeatPumpEquationFit' => ['Cooling Coil Electric Energy', 'Cooling Coil Crankcase Heater Electric Energy'],
             'OpenStudio::Model::EvaporativeCoolerDirectResearchSpecial' => ['Evaporative Cooler Electric Energy'] }
  end

  def self.WaterHeatingElectricity
    return { 'OpenStudio::Model::WaterHeaterMixed' => ['Water Heater Electric Energy', 'Water Heater Off Cycle Parasitic Electric Energy', 'Water Heater On Cycle Parasitic Electric Energy'],
             'OpenStudio::Model::WaterHeaterStratified' => ['Water Heater Electric Energy', 'Water Heater Off Cycle Parasitic Electric Energy', 'Water Heater On Cycle Parasitic Electric Energy'],
             'OpenStudio::Model::CoilWaterHeatingAirToWaterHeatPumpWrapped' => ['Cooling Coil Water Heating Electric Energy'] }
  end

  def self.WaterHeatingElectricitySolarThermalPump
    return { 'OpenStudio::Model::PumpConstantSpeed' => ['Pump Electric Energy'] }
  end

  def self.WaterHeatingElectricityRecircPump
    return { 'OpenStudio::Model::ElectricEquipment' => ['Electric Equipment Electric Energy'] }
  end

  def self.WaterHeatingCombiBoilerHeatExchanger
    return { 'OpenStudio::Model::HeatExchangerFluidToFluid' => ['Fluid Heat Exchanger Heat Transfer Energy'] }
  end

  def self.WaterHeatingCombiBoiler
    return { 'OpenStudio::Model::BoilerHotWater' => ['Boiler Heating Energy'] }
  end

  def self.WaterHeatingNaturalGas
    return { 'OpenStudio::Model::WaterHeaterMixed' => ['Water Heater Gas Energy'],
             'OpenStudio::Model::WaterHeaterStratified' => ['Water Heater Gas Energy'] }
  end

  def self.WaterHeatingFuelOil
    return { 'OpenStudio::Model::WaterHeaterMixed' => ['Water Heater FuelOil#1 Energy'],
             'OpenStudio::Model::WaterHeaterStratified' => ['Water Heater FuelOil#1 Energy'] }
  end

  def self.WaterHeatingPropane
    return { 'OpenStudio::Model::WaterHeaterMixed' => ['Water Heater Propane Energy'],
             'OpenStudio::Model::WaterHeaterStratified' => ['Water Heater Propane Energy'] }
  end

  def self.WaterHeatingLoad
    return { 'OpenStudio::Model::WaterUseConnections' => ['Water Use Connections Plant Hot Water Energy'] }
  end

  def self.WaterHeatingLoadTankLosses
    return { 'OpenStudio::Model::WaterHeaterMixed' => ['Water Heater Heat Loss Energy'],
             'OpenStudio::Model::WaterHeaterStratified' => ['Water Heater Heat Loss Energy'] }
  end

  def self.WaterHeaterLoadDesuperheater
    return { 'OpenStudio::Model::CoilWaterHeatingDesuperheater' => ['Water Heater Heating Energy'] }
  end

  def self.WaterHeaterLoadSolarThermal
    return { 'OpenStudio::Model::WaterHeaterStratified' => ['Water Heater Use Side Heat Transfer Energy'] }
  end
end
