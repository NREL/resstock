# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/measures/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"
require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/unit_conversions"

#start the measure
class ProcessCentralAirConditioner < OpenStudio::Ruleset::ModelUserScript

  class AirConditioner
    def initialize(acCoolingInstalledSEER, acNumberSpeeds, acRatedAirFlowRate, acFanspeedRatio, acCapacityRatio, acCoolingEER, acSupplyFanPowerInstalled, acSupplyFanPowerRated, acSHRRated, acCondenserType, acCrankcase, acCrankcaseMaxT, acEERCapacityDerateFactor)
      @acCoolingInstalledSEER = acCoolingInstalledSEER
      @acNumberSpeeds = acNumberSpeeds
      @acRatedAirFlowRate = acRatedAirFlowRate
      @acFanspeedRatio = acFanspeedRatio
      @acCapacityRatio = acCapacityRatio
      @acCoolingEER = acCoolingEER
      @acSupplyFanPowerInstalled = acSupplyFanPowerInstalled
      @acSupplyFanPowerRated = acSupplyFanPowerRated
      @acSHRRated = acSHRRated
      @acCondenserType = acCondenserType
      @acCrankcase = acCrankcase
      @acCrankcaseMaxT = acCrankcaseMaxT
      @acEERCapacityDerateFactor = acEERCapacityDerateFactor
    end

    attr_accessor(:hasIdealAC)

    def ACCoolingInstalledSEER
      return @acCoolingInstalledSEER
    end

    def ACNumberSpeeds
      return @acNumberSpeeds
    end

    def ACRatedAirFlowRate
      return @acRatedAirFlowRate
    end

    def ACFanspeedRatio
      return @acFanspeedRatio
    end

    def ACCapacityRatio
      return @acCapacityRatio
    end

    def ACCoolingEER
      return @acCoolingEER
    end

    def ACSupplyFanPowerInstalled
      return @acSupplyFanPowerInstalled
    end

    def ACSupplyFanPowerRated
      return @acSupplyFanPowerRated
    end

    def ACSHRRated
      return @acSHRRated
    end

    def ACCondenserType
      return @acCondenserType
    end

    def ACCrankcase
      return @acCrankcase
    end

    def ACCrankcaseMaxT
      return @acCrankcaseMaxT
    end

    def ACEERCapacityDerateFactor
      return @acEERCapacityDerateFactor
    end
  end

  class Supply
    def initialize
    end
    attr_accessor(:static, :cfm_ton, :HPCoolingOversizingFactor, :SpaceConditionedMult, :fan_power, :fan_power_rated, :eff, :min_flow_ratio, :FAN_EIR_FPLR_SPEC_coefficients, :max_temp, :Heat_Capacity, :compressor_speeds, :Zone_Water_Remove_Cap_Ft_DB_RH_Coefficients, :Zone_Energy_Factor_Ft_DB_RH_Coefficients, :Zone_DXDH_PLF_F_PLR_Coefficients, :Number_Speeds, :fanspeed_ratio, :CFM_TON_Rated, :COOL_CAP_FT_SPEC_coefficients, :COOL_EIR_FT_SPEC_coefficients, :COOL_CAP_FFLOW_SPEC_coefficients, :COOL_EIR_FFLOW_SPEC_coefficients, :CoolingEIR, :SHR_Rated, :COOL_CLOSS_FPLR_SPEC_coefficients, :Capacity_Ratio_Cooling, :CondenserType, :Crankcase, :Crankcase_MaxT, :EER_CapacityDerateFactor)
  end

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Residential Central Air Conditioner"
  end
  
  def description
    return "This measure removes any existing HVAC cooling components from the building and adds a central air conditioner along with an on/off supply fan to a unitary air loop."
  end
  
  def modeler_description
    return "This measure parses the OSM for the #{Constants.ObjectNameCoolingSeason}. Any cooling components are removed from any existing air loops or zones. Any existing air loops are also removed. A cooling DX coil and an on/off supply fan are added to a unitary air loop. The unitary air loop is added to the supply inlet node of the air loop. This air loop is added to a branch for the living zone. A diffuser is added to the branch for the living zone as well as for the finished basement if it exists."
  end   
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new
  
    #make a double argument for central ac cooling rated seer
    acCoolingInstalledSEER = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("acCoolingInstalledSEER", true)
    acCoolingInstalledSEER.setDisplayName("Rated SEER")
    acCoolingInstalledSEER.setUnits("Btu/W-h")
    acCoolingInstalledSEER.setDescription("Seasonal Energy Efficiency Ratio (SEER) is a measure of equipment energy efficiency over the cooling season.")
    acCoolingInstalledSEER.setDefaultValue(13.0)
    args << acCoolingInstalledSEER

    #make a double argument for central ac number of speeds
    acNumberSpeeds = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("acNumberSpeeds", true)
    acNumberSpeeds.setDisplayName("Number of Speeds")
    acNumberSpeeds.setUnits("frac")
    acNumberSpeeds.setDescription("Number of speeds of the compressor.")
    acNumberSpeeds.setDefaultValue(1.0)
    args << acNumberSpeeds
    
    #make a double argument for central ac eer
    acCoolingEER = OpenStudio::Ruleset::OSArgument::makeStringArgument("acCoolingEER", true)
    acCoolingEER.setDisplayName("EER")
    acCoolingEER.setUnits("kBtu/kWh")
    acCoolingEER.setDescription("EER (net) from the A test (95 ODB/80 EDB/67 EWB) for each of the compressor speeds.")
    acCoolingEER.setDefaultValue("11.1")
    args << acCoolingEER

    #make a double argument for central ac rated shr
    acSHRRated = OpenStudio::Ruleset::OSArgument::makeStringArgument("acSHRRated", true)
    acSHRRated.setDisplayName("Rated SHR")
    acSHRRated.setDescription("The sensible heat ratio (ratio of the sensible portion of the load to the total load) at the nominal rated capacity for each of the compressor speeds.")
    acSHRRated.setDefaultValue("0.73")
    args << acSHRRated 
    
    #make a double argument for central ac capacity ratio
    acCapacityRatio = OpenStudio::Ruleset::OSArgument::makeStringArgument("acCapacityRatio", true)
    acCapacityRatio.setDisplayName("Capacity Ratio")
    acCapacityRatio.setDescription("Capacity divided by rated capacity for each of the compressor speeds.")
    acCapacityRatio.setDefaultValue("1.0")
    args << acCapacityRatio
    
    #make a double argument for central ac rated air flow rate
    acRatedAirFlowRate = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("acRatedAirFlowRate", true)
    acRatedAirFlowRate.setDisplayName("Rated Air Flow Rate")
    acRatedAirFlowRate.setUnits("cfm/ton")
    acRatedAirFlowRate.setDescription("Air flow rate (cfm) per ton of rated capacity.")
    acRatedAirFlowRate.setDefaultValue(386.1)
    args << acRatedAirFlowRate
    
    #make a double argument for central ac fan speed ratio
    acFanspeedRatio = OpenStudio::Ruleset::OSArgument::makeStringArgument("acFanspeedRatio", true)
    acFanspeedRatio.setDisplayName("Fan Speed Ratio")
    acFanspeedRatio.setDescription("Fan speed divided by fan speed at the compressor speed for which Capacity Ratio = 1.0 for each of the compressor speeds.")
    acFanspeedRatio.setDefaultValue("1.0")
    args << acFanspeedRatio
    
    #make a double argument for central ac rated supply fan power
    acSupplyFanPowerRated = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("acSupplyFanPowerRated", true)
    acSupplyFanPowerRated.setDisplayName("Rated Supply Fan Power")
    acSupplyFanPowerRated.setUnits("W/cfm")
    acSupplyFanPowerRated.setDescription("Fan power (in W) per delivered airflow rate (in cfm) of the outdoor fan under conditions prescribed by AHRI Standard 210/240 for SEER testing.")
    acSupplyFanPowerRated.setDefaultValue(0.365)
    args << acSupplyFanPowerRated
    
    #make a double argument for central ac installed supply fan power
    acSupplyFanPowerInstalled = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("acSupplyFanPowerInstalled", true)
    acSupplyFanPowerInstalled.setDisplayName("Installed Supply Fan Power")
    acSupplyFanPowerInstalled.setUnits("W/cfm")
    acSupplyFanPowerInstalled.setDescription("Fan power (in W) per delivered airflow rate (in cfm) of the outdoor fan for the maximum fan speed under actual operating conditions.")
    acSupplyFanPowerInstalled.setDefaultValue(0.5)
    args << acSupplyFanPowerInstalled
    
    #make a double argument for central ac condenser type
    acCondenserType = OpenStudio::Ruleset::OSArgument::makeStringArgument("acCondenserType", true)
    acCondenserType.setDisplayName("Condenser Type")
    acCondenserType.setDescription("For evaporatively cooled units, the performance curves are a function of outdoor wetbulb (not drybulb) and entering wetbulb.")
    acCondenserType.setDefaultValue("aircooled")
    args << acCondenserType    
  
    #make a double argument for central ac crankcase
    acCrankcase = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("acCrankcase", true)
    acCrankcase.setDisplayName("Crankcase")
    acCrankcase.setUnits("kW")
    acCrankcase.setDescription("Capacity of the crankcase heater for the compressor.")
    acCrankcase.setDefaultValue(0.0)
    args << acCrankcase

    #make a double argument for central ac crankcase max t
    acCrankcaseMaxT = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("acCrankcaseMaxT", true)
    acCrankcaseMaxT.setDisplayName("Crankcase Max Temp")
    acCrankcaseMaxT.setUnits("degrees F")
    acCrankcaseMaxT.setDescription("Outdoor dry-bulb temperature above which compressor crankcase heating is disabled.")
    acCrankcaseMaxT.setDefaultValue(55.0)
    args << acCrankcaseMaxT
    
    #make a double argument for central ac 1.5 ton eer capacity derate
    acEERCapacityDerateFactor1ton = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("acEERCapacityDerateFactor1ton", true)
    acEERCapacityDerateFactor1ton.setDisplayName("1.5 Ton EER Capacity Derate")
    acEERCapacityDerateFactor1ton.setDescription("EER multiplier for 1.5 ton air-conditioners.")
    acEERCapacityDerateFactor1ton.setDefaultValue(1.0)
    args << acEERCapacityDerateFactor1ton
    
    #make a double argument for central ac 2 ton eer capacity derate
    acEERCapacityDerateFactor2ton = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("acEERCapacityDerateFactor2ton", true)
    acEERCapacityDerateFactor2ton.setDisplayName("2 Ton EER Capacity Derate")
    acEERCapacityDerateFactor2ton.setDescription("EER multiplier for 2 ton air-conditioners.")
    acEERCapacityDerateFactor2ton.setDefaultValue(1.0)
    args << acEERCapacityDerateFactor2ton

    #make a double argument for central ac 3 ton eer capacity derate
    acEERCapacityDerateFactor3ton = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("acEERCapacityDerateFactor3ton", true)
    acEERCapacityDerateFactor3ton.setDisplayName("3 Ton EER Capacity Derate")
    acEERCapacityDerateFactor3ton.setDescription("EER multiplier for 3 ton air-conditioners.")
    acEERCapacityDerateFactor3ton.setDefaultValue(1.0)
    args << acEERCapacityDerateFactor3ton

    #make a double argument for central ac 4 ton eer capacity derate
    acEERCapacityDerateFactor4ton = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("acEERCapacityDerateFactor4ton", true)
    acEERCapacityDerateFactor4ton.setDisplayName("4 Ton EER Capacity Derate")
    acEERCapacityDerateFactor4ton.setDescription("EER multiplier for 4 ton air-conditioners.")
    acEERCapacityDerateFactor4ton.setDefaultValue(1.0)
    args << acEERCapacityDerateFactor4ton

    #make a double argument for central ac 5 ton eer capacity derate
    acEERCapacityDerateFactor5ton = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("acEERCapacityDerateFactor5ton", true)
    acEERCapacityDerateFactor5ton.setDisplayName("5 Ton EER Capacity Derate")
    acEERCapacityDerateFactor5ton.setDescription("EER multiplier for 5 ton air-conditioners.")
    acEERCapacityDerateFactor5ton.setDefaultValue(1.0)
    args << acEERCapacityDerateFactor5ton
    
    #make a choice argument for central air cooling output capacity
    cap_display_names = OpenStudio::StringVector.new
    cap_display_names << Constants.SizingAuto
    (0.5..10.0).step(0.5) do |tons|
      cap_display_names << "#{tons} tons"
    end

    #make a string argument for central air cooling output capacity
    acCoolingOutputCapacity = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("acCoolingOutputCapacity", cap_display_names, true)
    acCoolingOutputCapacity.setDisplayName("Cooling Output Capacity")
    acCoolingOutputCapacity.setDefaultValue(Constants.SizingAuto)
    args << acCoolingOutputCapacity    
    
    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end
	  
    acCoolingInstalledSEER = runner.getDoubleArgumentValue("acCoolingInstalledSEER",user_arguments)
    acNumberSpeeds = runner.getDoubleArgumentValue("acNumberSpeeds",user_arguments)
    acCoolingEER = runner.getStringArgumentValue("acCoolingEER",user_arguments).split(",").map {|i| i.to_f}
    acSHRRated = runner.getStringArgumentValue("acSHRRated",user_arguments).split(",").map {|i| i.to_f}
    acCapacityRatio = runner.getStringArgumentValue("acCapacityRatio",user_arguments).split(",").map {|i| i.to_f}
    acRatedAirFlowRate = runner.getDoubleArgumentValue("acRatedAirFlowRate",user_arguments)
    acFanspeedRatio = runner.getStringArgumentValue("acFanspeedRatio",user_arguments).split(",").map {|i| i.to_f}
    acSupplyFanPowerRated = runner.getDoubleArgumentValue("acSupplyFanPowerRated",user_arguments)
    acSupplyFanPowerInstalled = runner.getDoubleArgumentValue("acSupplyFanPowerInstalled",user_arguments)
    acCondenserType = runner.getStringArgumentValue("acCondenserType",user_arguments)
    acCrankcase = runner.getDoubleArgumentValue("acCrankcase",user_arguments)
    acCrankcaseMaxT = runner.getDoubleArgumentValue("acCrankcaseMaxT",user_arguments)
    acEERCapacityDerateFactor1ton = runner.getDoubleArgumentValue("acEERCapacityDerateFactor1ton",user_arguments)
    acEERCapacityDerateFactor2ton = runner.getDoubleArgumentValue("acEERCapacityDerateFactor2ton",user_arguments)
    acEERCapacityDerateFactor3ton = runner.getDoubleArgumentValue("acEERCapacityDerateFactor3ton",user_arguments)
    acEERCapacityDerateFactor4ton = runner.getDoubleArgumentValue("acEERCapacityDerateFactor4ton",user_arguments)
    acEERCapacityDerateFactor5ton = runner.getDoubleArgumentValue("acEERCapacityDerateFactor5ton",user_arguments)
    acEERCapacityDerateFactor = [acEERCapacityDerateFactor1ton, acEERCapacityDerateFactor2ton, acEERCapacityDerateFactor3ton, acEERCapacityDerateFactor4ton, acEERCapacityDerateFactor5ton]
    acOutputCapacity = runner.getStringArgumentValue("acCoolingOutputCapacity",user_arguments)
    unless acOutputCapacity == Constants.SizingAuto
      acOutputCapacity = OpenStudio::convert(acOutputCapacity.split(" ")[0].to_f,"ton","Btu/h").get
    end

    # error checking
    unless [1, 2, 4].include? acNumberSpeeds
      runner.registerError("Invalid number of compressor speeds entered.")
      return false
    end
    unless ( acNumberSpeeds == acCoolingEER.length and acNumberSpeeds == acSHRRated.length and acNumberSpeeds == acCapacityRatio.length and acNumberSpeeds == acFanspeedRatio.length )
      runner.registerError("Entered wrong length for EER, Rated SHR, Capacity Ratio, or Fan Speed Ratio given the Number of Speeds.")
      return false
    end   
    
    # Create the material class instances
    air_conditioner = AirConditioner.new(acCoolingInstalledSEER, acNumberSpeeds, acRatedAirFlowRate, acFanspeedRatio, acCapacityRatio, acCoolingEER, acSupplyFanPowerInstalled, acSupplyFanPowerRated, acSHRRated, acCondenserType, acCrankcase, acCrankcaseMaxT, acEERCapacityDerateFactor)
    supply = Supply.new

    # _processAirSystem
    
    if air_conditioner.ACCoolingInstalledSEER == 999
      air_conditioner.hasIdealAC = true
    else
      air_conditioner.hasIdealAC = false
    end

    supply.static = UnitConversion.inH2O2Pa(0.5) # Pascal

    # Flow rate through AC units - hardcoded assumption of 400 cfm/ton
    supply.cfm_ton = 400 # cfm / ton

    supply.HPCoolingOversizingFactor = 1 # Default to a value of 1 (currently only used for MSHPs)
    supply.SpaceConditionedMult = 1 # Default used for central equipment    
        
    # Cooling Coil
    if air_conditioner.hasIdealAC
      supply = HVAC.get_cooling_coefficients(runner, air_conditioner.ACNumberSpeeds, true, false, supply)
    else
      supply = HVAC.get_cooling_coefficients(runner, air_conditioner.ACNumberSpeeds, false, false, supply)
    end
    supply.CFM_TON_Rated = HVAC.calc_cfm_ton_rated(air_conditioner.ACRatedAirFlowRate, air_conditioner.ACFanspeedRatio, air_conditioner.ACCapacityRatio)
    supply = HVAC._processAirSystemCoolingCoil(air_conditioner.ACNumberSpeeds, air_conditioner.ACCoolingEER, air_conditioner.ACCoolingInstalledSEER, air_conditioner.ACSupplyFanPowerInstalled, air_conditioner.ACSupplyFanPowerRated, air_conditioner.ACSHRRated, air_conditioner.ACCapacityRatio, air_conditioner.ACFanspeedRatio, air_conditioner.ACCondenserType, air_conditioner.ACCrankcase, air_conditioner.ACCrankcaseMaxT, air_conditioner.ACEERCapacityDerateFactor, air_conditioner, supply, false)
        
    # Determine if the compressor is multi-speed (in our case 2 speed).
    # If the minimum flow ratio is less than 1, then the fan and
    # compressors can operate at lower speeds.
    if supply.min_flow_ratio == 1.0
      supply.compressor_speeds = 1.0
    else
      supply.compressor_speeds = supply.Number_Speeds
    end
    
    control_slave_zones_hash = Geometry.get_control_and_slave_zones(model)
    control_slave_zones_hash.each do |control_zone, slave_zones|
    
      # Remove existing equipment
      htg_coil = HelperMethods.remove_existing_hvac_equipment(model, runner, "Central Air Conditioner", control_zone)
    
      # _processCurvesDXCooling
      
      clg_coil_stage_data = HVAC._processCurvesDXCooling(model, supply, acOutputCapacity)

      # _processSystemCoolingCoil
      
      if supply.compressor_speeds == 1.0

        clg_coil = OpenStudio::Model::CoilCoolingDXSingleSpeed.new(model, model.alwaysOnDiscreteSchedule, clg_coil_stage_data[0].totalCoolingCapacityFunctionofTemperatureCurve, clg_coil_stage_data[0].totalCoolingCapacityFunctionofFlowFractionCurve, clg_coil_stage_data[0].energyInputRatioFunctionofTemperatureCurve, clg_coil_stage_data[0].energyInputRatioFunctionofFlowFractionCurve, clg_coil_stage_data[0].partLoadFractionCorrelationCurve)
        clg_coil.setName("DX Cooling Coil")
        if acOutputCapacity != Constants.SizingAuto
          clg_coil.setRatedTotalCoolingCapacity(OpenStudio::convert(acOutputCapacity,"Btu/h","W").get)
        end
        if air_conditioner.hasIdealAC
          if acOutputCapacity != Constants.SizingAuto
            clg_coil.setRatedSensibleHeatRatio(0.8)
            clg_coil.setRatedAirFlowRate(supply.CFM_TON_Rated[0] * acOutputCapacity * OpenStudio::convert(1.0,"Btu/h","ton").get * OpenStudio::convert(1.0,"cfm","m^3/s").get)
          end
          clg_coil.setRatedCOP(OpenStudio::OptionalDouble.new(1.0))
        else
          if acOutputCapacity != Constants.SizingAuto
            clg_coil.setRatedSensibleHeatRatio(supply.SHR_Rated[0])
            clg_coil.setRatedAirFlowRate(supply.CFM_TON_Rated[0] * acOutputCapacity * OpenStudio::convert(1.0,"Btu/h","ton").get * OpenStudio::convert(1.0,"cfm","m^3/s").get)
          end
          clg_coil.setRatedCOP(OpenStudio::OptionalDouble.new(1.0 / supply.CoolingEIR[0]))
        end
        clg_coil.setRatedEvaporatorFanPowerPerVolumeFlowRate(OpenStudio::OptionalDouble.new(supply.fan_power_rated / OpenStudio::convert(1.0,"cfm","m^3/s").get))

        if air_conditioner.hasIdealAC
          clg_coil.setNominalTimeForCondensateRemovalToBegin(OpenStudio::OptionalDouble.new(0))
          clg_coil.setRatioOfInitialMoistureEvaporationRateAndSteadyStateLatentCapacity(OpenStudio::OptionalDouble.new(0))
          clg_coil.setMaximumCyclingRate(OpenStudio::OptionalDouble.new(0))
          clg_coil.setLatentCapacityTimeConstant(OpenStudio::OptionalDouble.new(0))
        else
          clg_coil.setNominalTimeForCondensateRemovalToBegin(OpenStudio::OptionalDouble.new(1000.0))
          clg_coil.setRatioOfInitialMoistureEvaporationRateAndSteadyStateLatentCapacity(OpenStudio::OptionalDouble.new(1.5))
          clg_coil.setMaximumCyclingRate(OpenStudio::OptionalDouble.new(3.0))
          clg_coil.setLatentCapacityTimeConstant(OpenStudio::OptionalDouble.new(45.0))
        end

        if supply.CondenserType == Constants.CondenserTypeAir
          clg_coil.setCondenserType("AirCooled")
        else
          clg_coil.setCondenserType("EvaporativelyCooled")
          clg_coil.setEvaporativeCondenserEffectiveness(OpenStudio::OptionalDouble.new(1))
          clg_coil.setEvaporativeCondenserAirFlowRate(OpenStudio::OptionalDouble.new(OpenStudio::convert(850.0,"cfm","m^3/s").get * sizing.cooling_cap))
          clg_coil.setEvaporativeCondenserPumpRatePowerConsumption(OpenStudio::OptionalDouble.new(0))
        end

        clg_coil.setCrankcaseHeaterCapacity(OpenStudio::OptionalDouble.new(OpenStudio::convert(supply.Crankcase,"kW","W").get))
        clg_coil.setMaximumOutdoorDryBulbTemperatureForCrankcaseHeaterOperation(OpenStudio::OptionalDouble.new(OpenStudio::convert(supply.Crankcase_MaxT,"F","C").get))

      else

        clg_coil = OpenStudio::Model::CoilCoolingDXMultiSpeed.new(model)
        clg_coil.setName("DX Cooling Coil")
        clg_coil.setCondenserType(supply.CondenserType)
        clg_coil.setApplyPartLoadFractiontoSpeedsGreaterthan1(false)
        clg_coil.setApplyLatentDegradationtoSpeedsGreaterthan1(false)
        clg_coil.setCrankcaseHeaterCapacity(OpenStudio::convert(supply.Crankcase,"kW","W").get)
        clg_coil.setMaximumOutdoorDryBulbTemperatureforCrankcaseHeaterOperation(OpenStudio::convert(supply.Crankcase_MaxT,"F","C").get)
        
        clg_coil.setFuelType("Electricity")
             
        clg_coil_stage_data.each do |i|
            clg_coil.addStage(i)
        end  

      end
        
      # _processSystemFan
      
      supply_fan_availability = OpenStudio::Model::ScheduleConstant.new(model)
      supply_fan_availability.setName("SupplyFanAvailability")
      supply_fan_availability.setValue(1)

      fan = OpenStudio::Model::FanOnOff.new(model, supply_fan_availability)
      fan.setName("Supply Fan")
      fan.setEndUseSubcategory("HVACFan")
      fan.setFanEfficiency(supply.eff)
      fan.setPressureRise(supply.static)
      fan.setMotorEfficiency(1)
      fan.setMotorInAirstreamFraction(1)

      supply_fan_operation = OpenStudio::Model::ScheduleConstant.new(model)
      supply_fan_operation.setName("SupplyFanOperation")
      supply_fan_operation.setValue(0)    
    
      # _processSystemAir
      
      if supply.compressor_speeds == 1
      
        air_loop_unitary = OpenStudio::Model::AirLoopHVACUnitarySystem.new(model)
        air_loop_unitary.setName("Forced Air System")
        air_loop_unitary.setAvailabilitySchedule(model.alwaysOnDiscreteSchedule)
        air_loop_unitary.setCoolingCoil(clg_coil)
        air_loop_unitary.setSupplyAirFanOperatingModeSchedule(supply_fan_operation)
        air_loop_unitary.setMaximumSupplyAirTemperature(OpenStudio::convert(120.0,"F","C").get)
        air_loop_unitary.setSupplyAirFlowRateWhenNoCoolingorHeatingisRequired(0.0)
        air_loop_unitary.setSupplyFan(fan)
        air_loop_unitary.setFanPlacement("BlowThrough")
        if not htg_coil.nil?
          # Add the existing furnace back in
          air_loop_unitary.setHeatingCoil(htg_coil)
        else
          air_loop_unitary.setSupplyAirFlowRateDuringHeatingOperation(0.0000001) # this is when there is no heating present
        end
      
      elsif supply.compressor_speeds > 1
      
        supp_htg_coil = OpenStudio::Model::CoilHeatingElectric.new(model, model.alwaysOffDiscreteSchedule)
        supp_htg_coil.setName("Furnace Heating Coil")
        supp_htg_coil.setEfficiency(1)
        supp_htg_coil.setNominalCapacity(0.001)
        
        new_htg_coil = OpenStudio::Model::CoilHeatingDXMultiSpeed.new(model)
        new_htg_coil.setName("DX Heating Coil")
        new_htg_coil.setMinimumOutdoorDryBulbTemperatureforCompressorOperation(-20)
        new_htg_coil.setCrankcaseHeaterCapacity(OpenStudio::convert(supply.Crankcase,"kW","W").get)
        new_htg_coil.setMaximumOutdoorDryBulbTemperatureforCrankcaseHeaterOperation(OpenStudio::convert(supply.Crankcase_MaxT,"F","C").get)
        new_htg_coil.setMaximumOutdoorDryBulbTemperatureforDefrostOperation(0)
        new_htg_coil.setDefrostStrategy("Resistive")
        new_htg_coil.setDefrostControl("Timed")
        new_htg_coil.setDefrostTimePeriodFraction(0)
        new_htg_coil.setResistiveDefrostHeaterCapacity(0)
        new_htg_coil.setApplyPartLoadFractiontoSpeedsGreaterthan1(false)
        if htg_coil.nil?
          new_htg_coil.setAvailabilitySchedule(model.alwaysOffDiscreteSchedule)
          new_htg_coil.setFuelType("Electricity")
          htg_coil_stage_data = _processCurvesFurnaceForMultiSpeedAC(model, supply, 1.0, 1.0)
        else
          # TODO: figure out how to handle the EMS with adding back in the furnace with multispeed ACs
          new_htg_coil.setAvailabilitySchedule(htg_coil.availabilitySchedule)
          if htg_coil.to_CoilHeatingGas.is_initialized
            new_htg_coil.setFuelType("NaturalGas")
            nominalCapacity = htg_coil.nominalCapacity
            if nominalCapacity.is_initialized
              nominalCapacity = nominalCapacity.get
            else
              nominalCapacity = Constants.SizingAuto
            end
            htg_coil_stage_data = _processCurvesFurnaceForMultiSpeedAC(model, supply, nominalCapacity, htg_coil.gasBurnerEfficiency)
          elsif htg_coil.to_CoilHeatingElectric.is_initialized
            new_htg_coil.setFuelType("Electricity")
            nominalCapacity = htg_coil.nominalCapacity
            if nominalCapacity.is_initialized
              nominalCapacity = nominalCapacity.get
            else
              nominalCapacity = Constants.SizingAuto
            end
            htg_coil_stage_data = _processCurvesFurnaceForMultiSpeedAC(model, supply, nominalCapacity, htg_coil.efficiency)
          end                
          htg_coil.remove
        end
        (0...supply.Number_Speeds).each do |i|
            new_htg_coil.addStage(htg_coil_stage_data[0])    
        end
        
        air_loop_unitary = OpenStudio::Model::AirLoopHVACUnitaryHeatPumpAirToAirMultiSpeed.new(model, fan, new_htg_coil, clg_coil, supp_htg_coil)
        air_loop_unitary.setName("Forced Air System")
        air_loop_unitary.setAvailabilitySchedule(model.alwaysOnDiscreteSchedule)
        air_loop_unitary.setSupplyAirFanPlacement("BlowThrough")
        air_loop_unitary.setSupplyAirFanOperatingModeSchedule(supply_fan_operation)
        air_loop_unitary.setMinimumOutdoorDryBulbTemperatureforCompressorOperation(-20)
        air_loop_unitary.setMaximumSupplyAirTemperaturefromSupplementalHeater(OpenStudio::convert(120.0,"F","C").get)
        air_loop_unitary.setMaximumOutdoorDryBulbTemperatureforSupplementalHeaterOperation(21)
        air_loop_unitary.setAuxiliaryOnCycleElectricPower(0)
        air_loop_unitary.setAuxiliaryOffCycleElectricPower(0)
        air_loop_unitary.setSupplyAirFlowRateWhenNoCoolingorHeatingisNeeded(0)
        air_loop_unitary.setNumberofSpeedsforHeating(supply.Number_Speeds.to_i)
        air_loop_unitary.setNumberofSpeedsforCooling(supply.Number_Speeds.to_i)
      
      end

      air_loop = OpenStudio::Model::AirLoopHVAC.new(model)
      air_loop.setName("Central Air System")
      air_supply_inlet_node = air_loop.supplyInletNode
      air_supply_outlet_node = air_loop.supplyOutletNode
      air_demand_inlet_node = air_loop.demandInletNode
      air_demand_outlet_node = air_loop.demandOutletNode    
      
      air_loop_unitary.addToNode(air_supply_inlet_node)
      
      runner.registerInfo("Added on/off fan '#{fan.name}' to branch '#{air_loop_unitary.name}' of air loop '#{air_loop.name}'")
      runner.registerInfo("Added DX cooling coil '#{clg_coil.name}' to branch '#{air_loop_unitary.name}' of air loop '#{air_loop.name}'")
      unless htg_coil.nil?
        runner.registerInfo("Added heating coil '#{htg_coil.name}' to branch '#{air_loop_unitary.name}' of air loop '#{air_loop.name}'")
      end
      
      air_loop_unitary.setControllingZoneorThermostatLocation(control_zone)
      
      # _processSystemDemandSideAir
      # Demand Side

      # Supply Air
      zone_splitter = air_loop.zoneSplitter
      zone_splitter.setName("Zone Splitter")

      diffuser_living = OpenStudio::Model::AirTerminalSingleDuctUncontrolled.new(model, model.alwaysOnDiscreteSchedule)
      diffuser_living.setName("Living Zone Direct Air")
      # diffuser_living.setMaximumAirFlowRate(OpenStudio::convert(supply.Living_AirFlowRate,"cfm","m^3/s").get)
      air_loop.addBranchForZone(control_zone, diffuser_living.to_StraightComponent)

      air_loop.addBranchForZone(control_zone)
      runner.registerInfo("Added air loop '#{air_loop.name}' to thermal zone '#{control_zone.name}'")

      slave_zones.each do |slave_zone|

          diffuser_fbsmt = OpenStudio::Model::AirTerminalSingleDuctUncontrolled.new(model, model.alwaysOnDiscreteSchedule)
          diffuser_fbsmt.setName("FBsmt Zone Direct Air")
          # diffuser_fbsmt.setMaximumAirFlowRate(OpenStudio::convert(supply.Living_AirFlowRate,"cfm","m^3/s").get)
          air_loop.addBranchForZone(slave_zone, diffuser_fbsmt.to_StraightComponent)

          air_loop.addBranchForZone(slave_zone)
          runner.registerInfo("Added air loop '#{air_loop.name}' to thermal zone '#{slave_zone.name}'")

      end    
    
    end
	
    return true
 
  end #end the run method
  
  def _processCurvesFurnaceForMultiSpeedAC(model, supply, outputCapacity, efficiency)
    # Simulate the furnace using a heat pump for multi-speed AC simulations.
    # This object gets created in all situations when a 2 speed
    # AC is used (w/ furnace, boiler, or no heat).  
    htg_coil_stage_data = []
    (0...1).to_a.each do |speed|
    
      hp_heat_cap_ft = OpenStudio::Model::CurveBiquadratic.new(model)
      hp_heat_cap_ft.setName("HP_Heat-Cap-fT")
      hp_heat_cap_ft.setCoefficient1Constant(1)
      hp_heat_cap_ft.setCoefficient2x(0)
      hp_heat_cap_ft.setCoefficient3xPOW2(0)
      hp_heat_cap_ft.setCoefficient4y(0)
      hp_heat_cap_ft.setCoefficient5yPOW2(0)
      hp_heat_cap_ft.setCoefficient6xTIMESY(0)
      hp_heat_cap_ft.setMinimumValueofx(-100)
      hp_heat_cap_ft.setMaximumValueofx(100)
      hp_heat_cap_ft.setMinimumValueofy(-100)
      hp_heat_cap_ft.setMaximumValueofy(100)

      hp_heat_eir_ft = OpenStudio::Model::CurveBiquadratic.new(model)
      hp_heat_eir_ft.setName("HP_Heat-EIR-fT")
      hp_heat_eir_ft.setCoefficient1Constant(1)
      hp_heat_eir_ft.setCoefficient2x(0)
      hp_heat_eir_ft.setCoefficient3xPOW2(0)
      hp_heat_eir_ft.setCoefficient4y(0)
      hp_heat_eir_ft.setCoefficient5yPOW2(0)
      hp_heat_eir_ft.setCoefficient6xTIMESY(0)
      hp_heat_eir_ft.setMinimumValueofx(-100)
      hp_heat_eir_ft.setMaximumValueofx(100)
      hp_heat_eir_ft.setMinimumValueofy(-100)
      hp_heat_eir_ft.setMaximumValueofy(100)

      const_cubic = OpenStudio::Model::CurveCubic.new(model)
      const_cubic.setName("ConstantCubic")
      const_cubic.setCoefficient1Constant(1)
      const_cubic.setCoefficient2x(0)
      const_cubic.setCoefficient3xPOW2(0)
      const_cubic.setCoefficient4xPOW3(0)
      const_cubic.setMinimumValueofx(0)
      const_cubic.setMaximumValueofx(1)
      const_cubic.setMinimumCurveOutput(0.7)
      const_cubic.setMaximumCurveOutput(1)

      stage_data = OpenStudio::Model::CoilHeatingDXMultiSpeedStageData.new(model, hp_heat_cap_ft, const_cubic, hp_heat_eir_ft, const_cubic, const_cubic, HVAC._processCurvesSupplyFan(model))
      if outputCapacity != Constants.SizingAuto
        stage_data.setGrossRatedHeatingCapacity(outputCapacity)
        stage_data.setRatedAirFlowRate(outputCapacity * 0.00005)
      end
      stage_data.setGrossRatedHeatingCOP(efficiency)
      stage_data.setRatedWasteHeatFractionofPowerInput(0.00000001)
      htg_coil_stage_data[speed] = stage_data
    end
    return htg_coil_stage_data
  end  
  
end #end the measure

#this allows the measure to be use by the application
ProcessCentralAirConditioner.new.registerWithApplication