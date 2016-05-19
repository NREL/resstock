class Constants

  # Numbers --------------------
  
  def self.AssumedInsideTemp
    return 73.5 # deg-F
  end
  def self.DefaultFramingFactorCeiling
    return 0.11
  end
  def self.DefaultFramingFactorFloor
    return 0.13
  end
  def self.DefaultFramingFactorInterior
    return 0.16
  end
  def self.DefaultSolarAbsCeiling
    return 0.3
  end
  def self.DefaultSolarAbsFloor
    return 0.6
  end
  def self.DefaultSolarAbsWall
    return 0.5
  end
  def self.g
    return 32.174    # gravity (ft/s2)
  end
  def self.MinimumBasementHeight
    return 7 # ft
  end
  def self.MSHP_Cd_Cooling
    return 0.25
  end
  def self.MSHP_Cd_Heating
    return 0.40
  end
  def self.MonthNumDays
    return [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
  end
  def self.Num_Speeds_MSHP
    return 10
  end
  def self.Patm
    return 14.696 # standard atmospheric pressure (psia)
  end
  def self.small 
    return 1e-9
  end

  # Strings --------------------
  
  def self.AtticSpace
    return 'attic space'
  end
  def self.AtticZone
    return 'attic zone'
  end
  def self.Auto
    return 'auto'
  end
  def self.BasementSpace
    return 'basement space'
  end
  def self.BasementZone
    return 'basement zone'
  end
  def self.BAZoneCold
    return 'Cold'
  end
  def self.BAZoneHotDry
    return 'Hot-Dry'
  end
  def self.BAZoneSubarctic
    return 'Subarctic'
  end
  def self.BAZoneHotHumid
    return 'Hot-Humid'
  end
  def self.BAZoneMixedHumid
    return 'Mixed-Humid'
  end
  def self.BAZoneMixedDry
    return 'Mixed-Dry'
  end
  def self.BAZoneMarine
    return 'Marine'
  end
  def self.BAZoneVeryCold
    return 'Very Cold'
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
  def self.BoreConfigLconfig
    return 'l-config'
  end
  def self.BoreConfigRectangle
    return 'rectangle'
  end
  def self.BoreConfigUconfig
    return 'u-config'
  end
  def self.BoreConfigL2config
    return 'l2-config'
  end
  def self.BoreConfigOpenRectangle
    return 'open-rectangle'
  end
  def self.BoreTypeVertical
    return 'vertical bore'
  end
  def self.BuildingAmericaClimateZone
    return 'Building America'
  end
  def self.CollectorTypeClosedLoop
    return 'closed loop'
  end
  def self.CollectorTypeICS
    return 'ics'
  end
  def self.ColorWhite
    return 'white'
  end
  def self.ColorMedium
    return 'medium'
  end
  def self.ColorDark
    return 'dark'
  end
  def self.ColorLight
    return 'light'
  end
  def self.CoordRelative
    return 'relative'
  end
  def self.CoordAbsolute
    return 'absolute'
  end
  def self.CondenserTypeWater
    return 'watercooled'
  end
  def self.CondenserTypeAir
    return 'aircooled'
  end
  def self.CrawlSpace
    return 'crawl space'
  end
  def self.CrawlSpaceType
    return 'crawl space type'
  end
  def self.CrawlZone
    return 'crawl zone'
  end
  def self.DehumidDucted
    return 'ducted'
  end
  def self.DehumidStandalone
    return 'standalone'
  end
  def self.DayTypeWeekend
    return 'weekend'
  end
  def self.DayTypeWeekday
    return 'weekday'
  end
  def self.DayTypeVacation
    return 'vacation'
  end
  def self.DRControlAuto
    return 'automatic'
  end
  def self.DRControlManual
    return 'manual'
  end
  def self.DryerTerminationTimer
    return 'timer'
  end
  def self.DryerTerminationTemperature
    return 'temperature'
  end
  def self.DryerTerminationMoisture
    return 'moisture'
  end
  def self.FacadeFront
    return 'Front'
  end
  def self.FacadeBack
    return 'Back'
  end
  def self.FacadeLeft
    return 'Left'
  end
  def self.FacadeRight
    return 'Right'
  end
  def self.FanControlSmart
    return 'smart'
  end
  def self.FinishedAtticSpace
    return 'finished attic space'
  end
  def self.FinishedAtticZone
    return 'finished attic zone'
  end
  def self.FinishedAtticSpaceType
    return 'finished attic space type'
  end
  def self.FinishedBasementSpace
    return 'finished basement space'
  end
  def self.FinishedBasementSpaceType
    return 'finished basement space type'
  end
  def self.FinishedBasementZone
    return 'finished basement zone'
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
  def self.FoundationCalcSimple
    return 'simple'
  end
  def self.FoundationCalcPreProcess
    return 'preprocess'
  end
  def self.FuelTypeElectric
    return 'electric'
  end
  def self.FuelTypeGas
    return 'gas'
  end
  def self.FuelTypePropane
    return 'propane'
  end
  def self.FuelTypeOil
    return 'oil'
  end
  def self.FurnTypeLight
    return 'LIGHT'
  end
  def self.FurnTypeHeavy
    return 'HEAVY'
  end
  def self.GarageSpace
    return 'garage space'
  end
  def self.GarageSpaceType
    return 'garage space type'
  end
  def self.GarageZone
    return 'garage zone'
  end
  def self.HeatTransferMethodCTF
    return 'ctf'
  end
  def self.HeatTransferMethodCondFD
    return 'confd'
  end
  def self.HERSReference
    return 'ReferenceHome'
  end
  def self.HERSRated
    return 'RatedHome'
  end
  def self.InfMethodSG
    return 'S-G'
  end
  def self.InfMethodASHRAE
    return 'ASHRAE-ENHANCED'
  end
  def self.InfMethodRes
    return 'RESIDENTIAL'
  end
  def self.InsulationCellulose
    return 'cellulose'
  end
  def self.InsulationFiberglass
    return 'fiberglass'
  end
  def self.InsulationFiberglassBatt
    return 'fiberglass batt'
  end
  def self.InsulationPolyiso
    return 'polyiso'
  end
  def self.InsulationSIP
    return 'sip'
  end
  def self.InsulationClosedCellSprayFoam
    return 'closed cell spray foam'
  end
  def self.InsulationOpenCellSprayFoam
    return 'open cell spray foam'
  end
  def self.InsulationXPS
    return 'xps'
  end
  def self.LivingSpace(story)
      if story == 1
        return 'living space'
      end
    return 'living space ' + story.to_s
  end
  def self.LivingSpaceType
    return 'living space type'
  end
  def self.LivingZone
    return 'living zone'
  end
  def self.LocationInterior
    return 'interior'
  end
  def self.LocationExterior
    return 'exterior'
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
  def self.MaterialCeilingMass
    return 'ResCeilingMass1'
  end
  def self.MaterialCeilingMass2
    return 'ResCeilingMass2'
  end
  def self.MaterialFloorMass
    return 'ResFloorMass'
  end
  def self.MaterialFloorCovering
    return 'ResFloorCovering'
  end
  def self.MaterialFloorRigidIns
    return 'ResFloorRigidIns'
  end
  def self.MaterialFloorSheathing
    return 'ResFloorSheathing'
  end
  def self.MaterialRadiantBarrier
    return 'ResRadiantBarrier'
  end
  def self.MaterialRoofMaterial
    return 'ResRoofMaterial'
  end
  def self.MaterialRoofRigidIns
    return 'ResRoofRigidIns'
  end
  def self.MaterialRoofSheathing
    return 'ResRoofSheathing'
  end
  def self.MaterialWallExtFinish
    return 'ResExtFinish'
  end
  def self.MaterialWallMass
    return 'ResExtWallMass1'
  end
  def self.MaterialWallMass2
    return 'ResExtWallMass2'
  end
  def self.MaterialWallMassOtherSide
    return 'ResExtWallMassOtherSide1'
  end
  def self.MaterialWallMassOtherSide2
    return 'ResExtWallMassOtherSide2'
  end
  def self.MaterialWallRigidIns
    return 'ResExtWallRigidIns'
  end
  def self.MaterialWallSheathing
    return 'ResExtWallSheathing'
  end
  def self.MonthNames
    return ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
  end
  def self.ObjectNameClothesWasher
    return 'residential clothes washer'
  end
  def self.ObjectNameClothesDryer
    return 'residential clothes dryer'
  end
  def self.ObjectNameCookingRange
    return 'residential range'
  end
  def self.ObjectNameDishwasher
    return 'residential dishwasher'
  end
  def self.ObjectNameExtraRefrigerator
    return 'residential extra refrigerator'
  end
  def self.ObjectNameFreezer
    return 'residential freezer'
  end
  def self.ObjectNameGasFireplace
    return 'residential gas fireplace'
  end
  def self.ObjectNameGasGrill
    return 'residential gas grill'
  end
  def self.ObjectNameGasLighting
    return 'residential gas lighting'
  end
  def self.ObjectNameHotTubHeater
    return 'residential hot tub heater'
  end
  def self.ObjectNameHotTubPump
    return 'residential hot tub pump'
  end
  def self.ObjectNameLighting
    return 'residential lighting'
  end
  def self.ObjectNameMiscPlugLoads
    return 'residential misc plug loads'
  end
  def self.ObjectNameOccupants
    return 'residential occupants'
  end
  def self.ObjectNamePoolHeater
    return 'residential pool heater'
  end
  def self.ObjectNamePoolPump
    return 'residential pool pump'
  end
  def self.ObjectNameRefrigerator
    return 'residential refrigerator'
  end
  def self.ObjectNameWellPump
    return 'residential well pump'
  end
  def self.PierBeamSpace
    return 'pier and beam space'
  end
  def self.PierBeamZone
    return 'pier and beam zone'
  end
  def self.PierBeamSpaceType
    return 'pier and beam space type'
  end
  def self.PipeTypeTrunkBranch
    return 'trunkbranch'
  end
  def self.PipeTypeHomeRun
    return 'homerun'
  end
  def self.PCMtypeDistributed
    return 'distributed'
  end
  def self.PCMtypeConcentrated
    return 'concentrated'
  end
  def self.PlantLoopDomesticWater
    return 'Domestic Hot Water Loop'
  end
  def self.RADuctZone
    return 'RA Duct Zone'
  end
  def self.RecircTypeTimer
    return 'timer'
  end
  def self.RecircTypeDemand
    return 'demand' 
  end
  def self.ReportDeliveredHeating
    return 'Heating Delivered'
  end
  def self.ReportDeliveredCooling
    return 'Cooling Delivered'
  end
  def self.ReportDeliveredHotWater
    return 'Hot Water Delivered'
  end
  def self.ReportDeliveredHotWaterCommon
    return 'Common Hot Water Delivered'
  end
  def self.ReportCooling
    return 'Cooling Energy'
  end
  def self.ReportHeating
    return 'Heating Energy'
  end
  def self.ReportCoolFanPump
    return 'Cooling Fan Pump Energy'
  end
  def self.ReportHeatFanPump
    return 'Heating Fan Pump Energy'
  end
  def self.ReportHotWater
    return 'Hot Water Energy'
  end
  def self.ReportHotWaterSupp
    return 'Electric Element Usage'
  end
  def self.ReportLighting
    return 'Lighting Energy'
  end
  def self.ReportAppliances
    return 'Large Appliance Energy'
  end
  def self.ReportVentFans
    return 'Vent Fan Energy'
  end
  def self.ReportMisc
    return 'Misc Energy'
  end
  def self.ReportPV
    return 'PV Energy'
  end
  def self.RoofStructureRafter
    return 'rafter'
  end
  def self.RoofStructureTrussCantilever
    return 'truss, cantilever'
  end
  def self.RoofTypeFlat
    return 'flat'
  end
  def self.RoofTypeGable
    return 'gable'
  end
  def self.RoofTypeHip
    return 'hip'
  end
  def self.ScheduleTypeTemperature
    return 'TEMPERATURE'
  end
  def self.ScheduleTypeFraction
    return 'FRACTION'
  end
  def self.ScheduleTypeMultiplier
    return 'MULTIPLIER'
  end
  def self.ScheduleTypeFlag
    return 'FLAG'
  end
  def self.ScheduleTypeOnOff
    return 'ON/OFF'
  end
  def self.ScheduleTypeNumber
    return 'NUMBER'
  end
  def self.ScheduleTypeMonth
    return 'MONTH'
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
  def self.SlabSpace
    return 'slab space'
  end
  def self.SlabSpaceType
    return 'slab space type'
  end
  def self.TankTypeStratified
    return 'Stratified'
  end
  def self.TankTypeMixed
    return 'Mixed'
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
  def self.TestBldgMinimal
    return 'minimal'
  end
  def self.TestBldgTypical
    return 'typical'
  end
  def self.TestBldgExisting
    return 'existing'
  end
  def self.TestTypeStandard
    return 'standard'
  end
  def self.TestTypeSEEMValidation
    return 'seem'
  end
  def self.TestTypeTendrilValidation
    return 'tendril'
  end
  def self.TiltPitch
    return 'pitch'
  end
  def self.TiltLatitude
    return 'latitude'
  end
  def self.TubeSpacingB
    return 'b'
  end
  def self.TubeSpacingC
    return 'c'
  end
  def self.TubeSpacingAS
    return 'as'
  end
  def self.UnfinishedAtticSpace
    return 'unfinished attic space'
  end
  def self.UnfinishedAtticSpaceType
    return 'unfinished attic space type'
  end
  def self.UnfinishedAtticZone
    return 'unfinished attic zone'
  end
  def self.UnfinishedBasementSpace
    return 'unfinished basement space'
  end
  def self.UnfinishedBasementSpaceType
    return 'unfinished basement space type'
  end
  def self.UnfinishedBasementZone
    return 'unfinished basement zone'
  end
  def self.VentTypeExhaust
    return 'exhaust'
  end
  def self.VentTypeSupply
    return 'supply'
  end
  def self.VentTypeBalanced
    return 'balanced'
  end
  def self.WallTypeWoodStud
    return 'woodstud'
  end
  def self.WallTypeDoubleStud
    return 'doublestud'
  end
  def self.WallTypeSteelStud
    return 'steelstud'
  end
  def self.WallTypeCMU
    return 'cmus'
  end
  def self.WallTypeSIP
    return 'sips'
  end
  def self.WallTypeICF
    return 'icfs'
  end
  def self.WallTypeMisc
    return 'misc'
  end
  def self.WaterHeaterTypeTankless
    return 'tankless'
  end
  def self.WaterHeaterTypeTank
    return 'tank'
  end
  def self.WaterHeaterTypeHeatPump
    return 'heatpump'
  end
  def self.WaterHeaterTypeHeatPumpStratified
    return 'heatpump_strat'
  end
  def self.WindowClear
    return 'clear'
  end
  def self.WindowHighSHGCLowe
    return 'high-gain low-e'
  end
  def self.WindowLowSHGCLowe
    return 'low-gain low-e'
  end
  def self.WindowMedSHGCLowe
    return 'medium-gain low-e'
  end
  def self.WindowFrameInsulated
    return 'insulated'
  end
  def self.WindowFrameMTB
    return 'metal with thermal breaks'
  end
  def self.WindowFrameNonMetal
    return 'non-metal'
  end
  def self.WindowFrameMetal
    return 'metal'
  end
  def self.WindowTypeSingleCasement  
    return 'single casement'
  end
  def self.WindowTypeDoubleCasement  
    return 'double casement'
  end
  def self.WindowTypeHorizontalSlider
    return 'horizontal slider'
  end
  def self.WindowTypeVerticalSlider  
    return 'vertical slider'
  end
  def self.WindowTypeFixedPicture    
    return 'fixed'
  end
  def self.WindowTypeDoor            
    return 'door'
  end
    
end
