# frozen_string_literal: true

class Constants
  # Numbers --------------------

  def self.AssumedInsideTemp
    return 73.5 # deg-F
  end

  def self.g
    return 32.174 # gravity (ft/s2)
  end

  def self.MonthNumDays
    return [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
  end

  def self.small
    return 1e-9
  end

  # Strings --------------------

  def self.AirFilm
    return 'AirFilm'
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

  def self.ERIVersions
    return ['2014', '2014A', '2014AD', '2014ADE', '2014ADEG', '2014ADEGL', '2019', '2019A']
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

  def self.ObjectNameAirflow
    return 'airflow'
  end

  def self.ObjectNameAirSourceHeatPump
    return 'ashp'
  end

  def self.ObjectNameBackupHeatingCoil
    return 'backup htg coil'
  end

  def self.ObjectNameBath
    return 'baths'
  end

  def self.ObjectNameBoiler
    return 'boiler'
  end

  def self.ObjectNameCeilingFan
    return 'ceiling fan'
  end

  def self.ObjectNameCentralAirConditioner
    return 'central ac'
  end

  def self.ObjectNameCentralAirConditionerAndFurnace
    return 'central ac and furnace'
  end

  def self.ObjectNameClothesWasher
    return 'clothes washer'
  end

  def self.ObjectNameClothesDryer
    return 'clothes dryer'
  end

  def self.ObjectNameCombiWaterHeatingEnergy(water_heater_name)
    return "#{water_heater_name} dhw energy"
  end

  def self.ObjectNameComponentLoadsProgram
    return 'component loads program'
  end

  def self.ObjectNameCookingRange
    return 'cooking range'
  end

  def self.ObjectNameCoolingSeason
    return 'cooling season'
  end

  def self.ObjectNameCoolingSetpoint
    return 'cooling setpoint'
  end

  def self.ObjectNameDehumidifier
    return 'dehumidifier'
  end

  def self.ObjectNameDesuperheater(water_heater_name)
    return "#{water_heater_name} Desuperheater"
  end

  def self.ObjectNameDishwasher
    return 'dishwasher'
  end

  def self.ObjectNameDistributionWaste
    return 'dhw distribution waste'
  end

  def self.ObjectNameDucts
    return 'ducts'
  end

  def self.ObjectNameElectricBaseboard
    return 'baseboard'
  end

  def self.ObjectNameERVHRV
    return 'erv or hrv'
  end

  def self.ObjectNameEvaporativeCooler
    return 'evap cooler'
  end

  def self.ObjectNameExteriorLighting
    return 'exterior lighting'
  end

  def self.ObjectNameFanPumpDisaggregateCool(fan_or_pump_name = '')
    return "#{fan_or_pump_name} clg disaggregate"
  end

  def self.ObjectNameFanPumpDisaggregatePrimaryHeat(fan_or_pump_name = '')
    return "#{fan_or_pump_name} htg primary disaggregate"
  end

  def self.ObjectNameFanPumpDisaggregateBackupHeat(fan_or_pump_name = '')
    return "#{fan_or_pump_name} htg backup disaggregate"
  end

  def self.ObjectNameFixtures
    return 'dhw fixtures'
  end

  def self.ObjectNameFreezer
    return 'freezer'
  end

  def self.ObjectNameFurnace
    return 'furnace'
  end

  def self.ObjectNameFurniture
    return 'furniture'
  end

  def self.ObjectNameGarageLighting
    return 'garage lighting'
  end

  def self.ObjectNameGroundSourceHeatPump
    return 'gshp'
  end

  def self.ObjectNameHeatingSeason
    return 'heating season'
  end

  def self.ObjectNameHeatingSetpoint
    return 'heating setpoint'
  end

  def self.ObjectNameHotWaterRecircPump
    return 'dhw recirc pump'
  end

  def self.ObjectNameIdealAirSystem
    return 'ideal'
  end

  def self.ObjectNameIdealAirSystemResidual
    return 'ideal residual'
  end

  def self.ObjectNameInfiltration
    return 'infil'
  end

  def self.ObjectNameInteriorLighting
    return 'interior lighting'
  end

  def self.ObjectNameLightingExteriorHoliday
    return 'exterior holiday lighting'
  end

  def self.ObjectNameMechanicalVentilation
    return 'mech vent'
  end

  def self.ObjectNameMechanicalVentilationHouseFan
    return 'mech vent house fan'
  end

  def self.ObjectNameMechanicalVentilationHouseFanCFIS
    return 'mech vent house fan cfis'
  end

  def self.ObjectNameMechanicalVentilationBathFan
    return 'mech vent bath fan'
  end

  def self.ObjectNameMechanicalVentilationRangeFan
    return 'mech vent range fan'
  end

  def self.ObjectNameMiniSplitHeatPump
    return 'mshp'
  end

  def self.ObjectNameMiscGrill
    return 'misc grill'
  end

  def self.ObjectNameMiscLighting
    return 'misc lighting'
  end

  def self.ObjectNameMiscFireplace
    return 'misc fireplace'
  end

  def self.ObjectNameMiscPoolHeater
    return 'misc pool heater'
  end

  def self.ObjectNameMiscPoolPump
    return 'misc pool pump'
  end

  def self.ObjectNameMiscHotTubHeater
    return 'misc hot tub heater'
  end

  def self.ObjectNameMiscHotTubPump
    return 'misc hot tub pump'
  end

  def self.ObjectNameMiscPlugLoads
    return 'misc plug loads'
  end

  def self.ObjectNameMiscTelevision
    return 'misc tv'
  end

  def self.ObjectNameMiscElectricVehicleCharging
    return 'misc electric vehicle charging'
  end

  def self.ObjectNameMiscWellPump
    return 'misc well pump'
  end

  def self.ObjectNameNaturalVentilation
    return 'natural vent'
  end

  def self.ObjectNameNeighbors
    return 'neighbors'
  end

  def self.ObjectNameOccupants
    return 'occupants'
  end

  def self.ObjectNameOverhangs
    return 'overhangs'
  end

  def self.ObjectNamePlantLoopDHW
    return 'dhw loop'
  end

  def self.ObjectNamePlantLoopSHW
    return 'solar hot water loop'
  end

  def self.ObjectNameRefrigerator
    return 'fridge'
  end

  def self.ObjectNameRelativeHumiditySetpoint
    return 'rh setpoint'
  end

  def self.ObjectNameRoomAirConditioner
    return 'room ac'
  end

  def self.ObjectNameShower
    return 'showers'
  end

  def self.ObjectNameSink
    return 'sinks'
  end

  def self.ObjectNameSolarHotWater
    return 'solar hot water'
  end

  def self.ObjectNameTankHX
    return 'dhw source hx'
  end

  def self.ObjectNameUnitHeater
    return 'unit heater'
  end

  def self.ObjectNameWater
    return 'water'
  end

  def self.ObjectNameWaterHeater
    return 'water heater'
  end

  def self.ObjectNameWaterHeaterAdjustment(water_heater_name)
    return "#{water_heater_name} EC adjustment"
  end

  def self.ObjectNameWholeHouseFan
    return 'whole house fan'
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

  def self.SizingInfoDuctExist
    return __method__.to_s
  end

  def self.SizingInfoDuctSides
    return __method__.to_s
  end

  def self.SizingInfoDuctLocations
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

  def self.SizingInfoHVACSystemIsDucted # Only needed for optionally ducted systems
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

  def self.SizingInfoMechVentExist
    return __method__.to_s
  end

  def self.SizingInfoMechVentApparentSensibleEffectiveness
    return __method__.to_s
  end

  def self.SizingInfoMechVentLatentEffectiveness
    return __method__.to_s
  end

  def self.SizingInfoMechVentWholeHouseRateBalanced
    return __method__.to_s
  end

  def self.SizingInfoMechVentWholeHouseRateUnbalanced
    return __method__.to_s
  end

  def self.SizingInfoSIPWallInsThickness
    return __method__.to_s
  end

  def self.SizingInfoZoneInfiltrationACH
    return __method__.to_s
  end

  def self.SizingInfoZoneInfiltrationCFM
    return __method__.to_s
  end
end
