# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/measures/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"
require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/unit_conversions"
require "#{File.dirname(__FILE__)}/resources/hvac"

#start the measure
class ProcessTwoSpeedCentralAirConditioner < OpenStudio::Ruleset::ModelUserScript

  class Supply
    def initialize
    end
    attr_accessor(:static, :cfm_ton, :HPCoolingOversizingFactor, :SpaceConditionedMult, :fan_power, :fan_power_rated, :eff, :min_flow_ratio, :FAN_EIR_FPLR_SPEC_coefficients, :max_temp, :Heat_Capacity, :Zone_Water_Remove_Cap_Ft_DB_RH_Coefficients, :Zone_Energy_Factor_Ft_DB_RH_Coefficients, :Zone_DXDH_PLF_F_PLR_Coefficients, :Number_Speeds, :fanspeed_ratio, :CFM_TON_Rated, :COOL_CAP_FT_SPEC_coefficients, :COOL_EIR_FT_SPEC_coefficients, :COOL_CAP_FFLOW_SPEC_coefficients, :COOL_EIR_FFLOW_SPEC_coefficients, :CoolingEIR, :SHR_Rated, :COOL_CLOSS_FPLR_SPEC_coefficients, :Capacity_Ratio_Cooling, :CondenserType, :Crankcase, :Crankcase_MaxT, :EER_CapacityDerateFactor)
  end

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Residential Two-Speed Central Air Conditioner"
  end
  
  def description
    return "This measure removes any existing HVAC cooling components from the building and adds a two-speed central air conditioner along with an on/off supply fan to a unitary air loop. For multifamily buildings, the two-speed central air conditioner can be set for all units of the building."
  end
  
  def modeler_description
    return "Any cooling components are removed from any existing air loops or zones. Any existing air loops are also removed. A cooling DX coil and an on/off supply fan are added to a unitary air loop. The unitary air loop is added to the supply inlet node of the air loop. This air loop is added to a branch for the living zone. A diffuser is added to the branch for the living zone as well as for the finished basement if it exists."
  end   
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new
  
    #make a double argument for central ac cooling rated seer
    acCoolingInstalledSEER = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("seer", true)
    acCoolingInstalledSEER.setDisplayName("Rated SEER")
    acCoolingInstalledSEER.setUnits("Btu/W-h")
    acCoolingInstalledSEER.setDescription("Seasonal Energy Efficiency Ratio (SEER) is a measure of equipment energy efficiency over the cooling season.")
    acCoolingInstalledSEER.setDefaultValue(16.0)
    args << acCoolingInstalledSEER
    
    #make a double argument for central ac eer
    acCoolingEER = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("eer", true)
    acCoolingEER.setDisplayName("EER")
    acCoolingEER.setUnits("kBtu/kWh")
    acCoolingEER.setDescription("EER (net) from the A test (95 ODB/80 EDB/67 EWB).")
    acCoolingEER.setDefaultValue(13.5)
    args << acCoolingEER

    #make a double argument for central ac eer 2
    acCoolingEER = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("eer2", true)
    acCoolingEER.setDisplayName("EER 2")
    acCoolingEER.setUnits("kBtu/kWh")
    acCoolingEER.setDescription("EER (net) from the A test (95 ODB/80 EDB/67 EWB) for the second speed.")
    acCoolingEER.setDefaultValue(12.4)
    args << acCoolingEER    
    
    #make a double argument for central ac rated shr
    acSHRRated = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("shr", true)
    acSHRRated.setDisplayName("Rated SHR")
    acSHRRated.setDescription("The sensible heat ratio (ratio of the sensible portion of the load to the total load) at the nominal rated capacity.")
    acSHRRated.setDefaultValue(0.71)
    args << acSHRRated
    
    #make a double argument for central ac rated shr 2
    acSHRRated = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("shr2", true)
    acSHRRated.setDisplayName("Rated SHR 2")
    acSHRRated.setDescription("The sensible heat ratio (ratio of the sensible portion of the load to the total load) at the nominal rated capacity for the second speed.")
    acSHRRated.setDefaultValue(0.73)
    args << acSHRRated    
    
    #make a double argument for central ac capacity ratio
    acCapacityRatio = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("capacity_ratio", true)
    acCapacityRatio.setDisplayName("Capacity Ratio")
    acCapacityRatio.setDescription("Capacity divided by rated capacity.")
    acCapacityRatio.setDefaultValue(0.72)
    args << acCapacityRatio
    
    #make a double argument for central ac capacity ratio 2
    acCapacityRatio = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("capacity_ratio2", true)
    acCapacityRatio.setDisplayName("Capacity Ratio 2")
    acCapacityRatio.setDescription("Capacity divided by rated capacity for the second speed.")
    acCapacityRatio.setDefaultValue(1.0)
    args << acCapacityRatio    
    
    #make a double argument for central ac rated air flow rate
    acRatedAirFlowRate = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("airflow_rate", true)
    acRatedAirFlowRate.setDisplayName("Rated Air Flow Rate")
    acRatedAirFlowRate.setUnits("cfm/ton")
    acRatedAirFlowRate.setDescription("Air flow rate (cfm) per ton of rated capacity.")
    acRatedAirFlowRate.setDefaultValue(355.2)
    args << acRatedAirFlowRate
    
    #make a double argument for central ac fan speed ratio
    acFanspeedRatio = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("fan_speed_ratio", true)
    acFanspeedRatio.setDisplayName("Fan Speed Ratio")
    acFanspeedRatio.setDescription("Fan speed divided by fan speed at the compressor speed for which Capacity Ratio = 1.0.")
    acFanspeedRatio.setDefaultValue(0.86)
    args << acFanspeedRatio
    
    #make a double argument for central ac fan speed ratio 2
    acFanspeedRatio = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("fan_speed_ratio2", true)
    acFanspeedRatio.setDisplayName("Fan Speed Ratio 2")
    acFanspeedRatio.setDescription("Fan speed divided by fan speed at the compressor speed for which Capacity Ratio = 1.0 for the second speed.")
    acFanspeedRatio.setDefaultValue(1.0)
    args << acFanspeedRatio    
    
    #make a double argument for central ac rated supply fan power
    acSupplyFanPowerRated = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("fan_power_rated", true)
    acSupplyFanPowerRated.setDisplayName("Rated Supply Fan Power")
    acSupplyFanPowerRated.setUnits("W/cfm")
    acSupplyFanPowerRated.setDescription("Fan power (in W) per delivered airflow rate (in cfm) of the outdoor fan under conditions prescribed by AHRI Standard 210/240 for SEER testing.")
    acSupplyFanPowerRated.setDefaultValue(0.14)
    args << acSupplyFanPowerRated
    
    #make a double argument for central ac installed supply fan power
    acSupplyFanPowerInstalled = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("fan_power_installed", true)
    acSupplyFanPowerInstalled.setDisplayName("Installed Supply Fan Power")
    acSupplyFanPowerInstalled.setUnits("W/cfm")
    acSupplyFanPowerInstalled.setDescription("Fan power (in W) per delivered airflow rate (in cfm) of the outdoor fan for the maximum fan speed under actual operating conditions.")
    acSupplyFanPowerInstalled.setDefaultValue(0.3)
    args << acSupplyFanPowerInstalled
    
    #make a double argument for central ac crankcase
    acCrankcase = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("crankcase_capacity", true)
    acCrankcase.setDisplayName("Crankcase")
    acCrankcase.setUnits("kW")
    acCrankcase.setDescription("Capacity of the crankcase heater for the compressor.")
    acCrankcase.setDefaultValue(0.0)
    args << acCrankcase

    #make a double argument for central ac crankcase max t
    acCrankcaseMaxT = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("crankcase_max_temp", true)
    acCrankcaseMaxT.setDisplayName("Crankcase Max Temp")
    acCrankcaseMaxT.setUnits("degrees F")
    acCrankcaseMaxT.setDescription("Outdoor dry-bulb temperature above which compressor crankcase heating is disabled.")
    acCrankcaseMaxT.setDefaultValue(55.0)
    args << acCrankcaseMaxT
    
    #make a double argument for central ac 1.5 ton eer capacity derate
    acEERCapacityDerateFactor1ton = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("eer_capacity_derate_1ton", true)
    acEERCapacityDerateFactor1ton.setDisplayName("1.5 Ton EER Capacity Derate")
    acEERCapacityDerateFactor1ton.setDescription("EER multiplier for 1.5 ton air-conditioners.")
    acEERCapacityDerateFactor1ton.setDefaultValue(1.0)
    args << acEERCapacityDerateFactor1ton
    
    #make a double argument for central ac 2 ton eer capacity derate
    acEERCapacityDerateFactor2ton = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("eer_capacity_derate_2ton", true)
    acEERCapacityDerateFactor2ton.setDisplayName("2 Ton EER Capacity Derate")
    acEERCapacityDerateFactor2ton.setDescription("EER multiplier for 2 ton air-conditioners.")
    acEERCapacityDerateFactor2ton.setDefaultValue(1.0)
    args << acEERCapacityDerateFactor2ton

    #make a double argument for central ac 3 ton eer capacity derate
    acEERCapacityDerateFactor3ton = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("eer_capacity_derate_3ton", true)
    acEERCapacityDerateFactor3ton.setDisplayName("3 Ton EER Capacity Derate")
    acEERCapacityDerateFactor3ton.setDescription("EER multiplier for 3 ton air-conditioners.")
    acEERCapacityDerateFactor3ton.setDefaultValue(1.0)
    args << acEERCapacityDerateFactor3ton

    #make a double argument for central ac 4 ton eer capacity derate
    acEERCapacityDerateFactor4ton = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("eer_capacity_derate_4ton", true)
    acEERCapacityDerateFactor4ton.setDisplayName("4 Ton EER Capacity Derate")
    acEERCapacityDerateFactor4ton.setDescription("EER multiplier for 4 ton air-conditioners.")
    acEERCapacityDerateFactor4ton.setDefaultValue(1.0)
    args << acEERCapacityDerateFactor4ton

    #make a double argument for central ac 5 ton eer capacity derate
    acEERCapacityDerateFactor5ton = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("eer_capacity_derate_5ton", true)
    acEERCapacityDerateFactor5ton.setDisplayName("5 Ton EER Capacity Derate")
    acEERCapacityDerateFactor5ton.setDescription("EER multiplier for 5 ton air-conditioners.")
    acEERCapacityDerateFactor5ton.setDefaultValue(1.0)
    args << acEERCapacityDerateFactor5ton
    
    #make a string argument for central air cooling output capacity
    cap_display_names = OpenStudio::StringVector.new
    cap_display_names << Constants.SizingAuto
    (0.5..10.0).step(0.5) do |tons|
      cap_display_names << "#{tons} tons"
    end
    acCoolingOutputCapacity = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("capacity", cap_display_names, true)
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
	  
    acCoolingInstalledSEER = runner.getDoubleArgumentValue("seer",user_arguments)
    acCoolingEER = [runner.getDoubleArgumentValue("eer",user_arguments), runner.getDoubleArgumentValue("eer2",user_arguments)]
    acSHRRated = [runner.getDoubleArgumentValue("shr",user_arguments), runner.getDoubleArgumentValue("shr2",user_arguments)]
    acCapacityRatio = [runner.getDoubleArgumentValue("capacity_ratio",user_arguments), runner.getDoubleArgumentValue("capacity_ratio2",user_arguments)]
    acRatedAirFlowRate = runner.getDoubleArgumentValue("airflow_rate",user_arguments)
    acFanspeedRatio = [runner.getDoubleArgumentValue("fan_speed_ratio",user_arguments), runner.getDoubleArgumentValue("fan_speed_ratio2",user_arguments)]
    acSupplyFanPowerRated = runner.getDoubleArgumentValue("fan_power_rated",user_arguments)
    acSupplyFanPowerInstalled = runner.getDoubleArgumentValue("fan_power_installed",user_arguments)
    acCrankcase = runner.getDoubleArgumentValue("crankcase_capacity",user_arguments)
    acCrankcaseMaxT = runner.getDoubleArgumentValue("crankcase_max_temp",user_arguments)
    acEERCapacityDerateFactor1ton = runner.getDoubleArgumentValue("eer_capacity_derate_1ton",user_arguments)
    acEERCapacityDerateFactor2ton = runner.getDoubleArgumentValue("eer_capacity_derate_2ton",user_arguments)
    acEERCapacityDerateFactor3ton = runner.getDoubleArgumentValue("eer_capacity_derate_3ton",user_arguments)
    acEERCapacityDerateFactor4ton = runner.getDoubleArgumentValue("eer_capacity_derate_4ton",user_arguments)
    acEERCapacityDerateFactor5ton = runner.getDoubleArgumentValue("eer_capacity_derate_5ton",user_arguments)
    acEERCapacityDerateFactor = [acEERCapacityDerateFactor1ton, acEERCapacityDerateFactor2ton, acEERCapacityDerateFactor3ton, acEERCapacityDerateFactor4ton, acEERCapacityDerateFactor5ton]
    acOutputCapacity = runner.getStringArgumentValue("capacity",user_arguments)
    unless acOutputCapacity == Constants.SizingAuto
      acOutputCapacity = OpenStudio::convert(acOutputCapacity.split(" ")[0].to_f,"ton","Btu/h").get
    end 
    
    # Create the material class instances
    supply = Supply.new

    # _processAirSystem
    
    supply.static = UnitConversion.inH2O2Pa(0.5) # Pascal

    # Flow rate through AC units - hardcoded assumption of 400 cfm/ton
    supply.cfm_ton = 400 # cfm / ton

    supply.HPCoolingOversizingFactor = 1 # Default to a value of 1 (currently only used for MSHPs)
    supply.SpaceConditionedMult = 1 # Default used for central equipment    
        
    # Cooling Coil
    supply = HVAC.get_cooling_coefficients(runner, 2, false, supply)
    supply.CFM_TON_Rated = HVAC.calc_cfm_ton_rated(acRatedAirFlowRate, acFanspeedRatio, acCapacityRatio)
    supply = HVAC._processAirSystemCoolingCoil(runner, 2, acCoolingEER, acCoolingInstalledSEER, acSupplyFanPowerInstalled, acSupplyFanPowerRated, acSHRRated, acCapacityRatio, acFanspeedRatio, acCrankcase, acCrankcaseMaxT, acEERCapacityDerateFactor, supply)
    
    # Get building units
    units = Geometry.get_building_units(model, runner)
    if units.nil?
        return false
    end
    
    units.each do |unit|
      unit_num = Geometry.get_unit_number(model, unit, runner)
      thermal_zones = Geometry.get_thermal_zones_from_spaces(unit.spaces)

      control_slave_zones_hash = HVAC.get_control_and_slave_zones(thermal_zones)
      control_slave_zones_hash.each do |control_zone, slave_zones|
    
        # Remove existing equipment
        htg_coil = HVAC.remove_existing_hvac_equipment(model, runner, "Central Air Conditioner", control_zone)

        # _processCurvesDXCooling
        
        clg_coil_stage_data = HVAC._processCurvesDXCooling(model, supply, acOutputCapacity)

        # _processSystemCoolingCoil
        
        clg_coil = OpenStudio::Model::CoilCoolingDXMultiSpeed.new(model)
        clg_coil.setName("DX Cooling Coil_#{unit_num}")
        clg_coil.setCondenserType("AirCooled")
        clg_coil.setApplyPartLoadFractiontoSpeedsGreaterthan1(false)
        clg_coil.setApplyLatentDegradationtoSpeedsGreaterthan1(false)
        clg_coil.setCrankcaseHeaterCapacity(OpenStudio::convert(supply.Crankcase,"kW","W").get)
        clg_coil.setMaximumOutdoorDryBulbTemperatureforCrankcaseHeaterOperation(OpenStudio::convert(supply.Crankcase_MaxT,"F","C").get)
        
        clg_coil.setFuelType("Electricity")
             
        clg_coil_stage_data.each do |i|
            clg_coil.addStage(i)
        end
          
        # _processSystemFan
        
        supply_fan_availability = OpenStudio::Model::ScheduleConstant.new(model)
        supply_fan_availability.setName("SupplyFanAvailability_#{unit_num}")
        supply_fan_availability.setValue(1)

        fan = OpenStudio::Model::FanOnOff.new(model, supply_fan_availability)
        fan.setName("Supply Fan_#{unit_num}")
        fan.setEndUseSubcategory(Constants.EndUseHVACFan)
        fan.setFanEfficiency(supply.eff)
        fan.setPressureRise(supply.static)
        fan.setMotorEfficiency(1)
        fan.setMotorInAirstreamFraction(1)

        supply_fan_operation = OpenStudio::Model::ScheduleConstant.new(model)
        supply_fan_operation.setName("SupplyFanOperation_#{unit_num}")
        supply_fan_operation.setValue(0)    
      
        # _processSystemAir
              
        air_loop_unitary = OpenStudio::Model::AirLoopHVACUnitarySystem.new(model)
        air_loop_unitary.setName("Forced Air System_#{unit_num}")
        air_loop_unitary.setAvailabilitySchedule(model.alwaysOnDiscreteSchedule)
        air_loop_unitary.setCoolingCoil(clg_coil)      
        if not htg_coil.nil?
          # Add the existing furnace back in
          air_loop_unitary.setHeatingCoil(htg_coil)
        else
          air_loop_unitary.setSupplyAirFlowRateDuringHeatingOperation(0.0000001) # this is when there is no heating present
        end
        air_loop_unitary.setSupplyFan(fan)
        air_loop_unitary.setFanPlacement("BlowThrough")
        air_loop_unitary.setSupplyAirFanOperatingModeSchedule(supply_fan_operation)
        air_loop_unitary.setMaximumSupplyAirTemperature(OpenStudio::convert(120.0,"F","C").get)
        air_loop_unitary.setSupplyAirFlowRateWhenNoCoolingorHeatingisRequired(0)    
        
        air_loop = OpenStudio::Model::AirLoopHVAC.new(model)
        air_loop.setName("Central Air System_#{unit_num}")
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
        zone_splitter.setName("Zone Splitter_#{unit_num}")
        
        zone_mixer = air_loop.zoneMixer
        zone_mixer.setName("Zone Mixer_#{unit_num}")

        diffuser_living = OpenStudio::Model::AirTerminalSingleDuctUncontrolled.new(model, model.alwaysOnDiscreteSchedule)
        diffuser_living.setName("#{control_zone.name} direct air_#{unit_num}")
        # diffuser_living.setMaximumAirFlowRate(OpenStudio::convert(supply.Living_AirFlowRate,"cfm","m^3/s").get)
        air_loop.addBranchForZone(control_zone, diffuser_living.to_StraightComponent)

        air_loop.addBranchForZone(control_zone)
        runner.registerInfo("Added air loop '#{air_loop.name}' to thermal zone '#{control_zone.name}' of #{unit.name.to_s}")

        slave_zones.each do |slave_zone|

          # Remove existing equipment
          HVAC.remove_existing_hvac_equipment(model, runner, "Central Air Conditioner", slave_zone)
      
          diffuser_fbsmt = OpenStudio::Model::AirTerminalSingleDuctUncontrolled.new(model, model.alwaysOnDiscreteSchedule)
          diffuser_fbsmt.setName("#{slave_zone.name} direct air_#{unit_num}")
          # diffuser_fbsmt.setMaximumAirFlowRate(OpenStudio::convert(supply.Living_AirFlowRate,"cfm","m^3/s").get)
          air_loop.addBranchForZone(slave_zone, diffuser_fbsmt.to_StraightComponent)

          air_loop.addBranchForZone(slave_zone)
          runner.registerInfo("Added air loop '#{air_loop.name}' to thermal zone '#{slave_zone.name}' of #{unit.name.to_s}")

        end    
      
      end
      
    end
	
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ProcessTwoSpeedCentralAirConditioner.new.registerWithApplication