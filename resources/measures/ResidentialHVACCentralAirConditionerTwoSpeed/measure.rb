# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/measures/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"
require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/unit_conversions"
require "#{File.dirname(__FILE__)}/resources/hvac"

#start the measure
class ProcessTwoSpeedCentralAirConditioner < OpenStudio::Measure::ModelMeasure

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
    args = OpenStudio::Measure::OSArgumentVector.new
  
    #make a double argument for central ac cooling rated seer
    acCoolingInstalledSEER = OpenStudio::Measure::OSArgument::makeDoubleArgument("seer", true)
    acCoolingInstalledSEER.setDisplayName("Rated SEER")
    acCoolingInstalledSEER.setUnits("Btu/W-h")
    acCoolingInstalledSEER.setDescription("Seasonal Energy Efficiency Ratio (SEER) is a measure of equipment energy efficiency over the cooling season.")
    acCoolingInstalledSEER.setDefaultValue(16.0)
    args << acCoolingInstalledSEER
    
    #make a double argument for central ac eer
    acCoolingEER = OpenStudio::Measure::OSArgument::makeDoubleArgument("eer", true)
    acCoolingEER.setDisplayName("EER")
    acCoolingEER.setUnits("kBtu/kWh")
    acCoolingEER.setDescription("EER (net) from the A test (95 ODB/80 EDB/67 EWB).")
    acCoolingEER.setDefaultValue(13.5)
    args << acCoolingEER

    #make a double argument for central ac eer 2
    acCoolingEER = OpenStudio::Measure::OSArgument::makeDoubleArgument("eer2", true)
    acCoolingEER.setDisplayName("EER 2")
    acCoolingEER.setUnits("kBtu/kWh")
    acCoolingEER.setDescription("EER (net) from the A test (95 ODB/80 EDB/67 EWB) for the second speed.")
    acCoolingEER.setDefaultValue(12.4)
    args << acCoolingEER    
    
    #make a double argument for central ac rated shr
    acSHRRated = OpenStudio::Measure::OSArgument::makeDoubleArgument("shr", true)
    acSHRRated.setDisplayName("Rated SHR")
    acSHRRated.setDescription("The sensible heat ratio (ratio of the sensible portion of the load to the total load) at the nominal rated capacity.")
    acSHRRated.setDefaultValue(0.71)
    args << acSHRRated
    
    #make a double argument for central ac rated shr 2
    acSHRRated = OpenStudio::Measure::OSArgument::makeDoubleArgument("shr2", true)
    acSHRRated.setDisplayName("Rated SHR 2")
    acSHRRated.setDescription("The sensible heat ratio (ratio of the sensible portion of the load to the total load) at the nominal rated capacity for the second speed.")
    acSHRRated.setDefaultValue(0.73)
    args << acSHRRated    
    
    #make a double argument for central ac capacity ratio
    acCapacityRatio = OpenStudio::Measure::OSArgument::makeDoubleArgument("capacity_ratio", true)
    acCapacityRatio.setDisplayName("Capacity Ratio")
    acCapacityRatio.setDescription("Capacity divided by rated capacity.")
    acCapacityRatio.setDefaultValue(0.72)
    args << acCapacityRatio
    
    #make a double argument for central ac capacity ratio 2
    acCapacityRatio = OpenStudio::Measure::OSArgument::makeDoubleArgument("capacity_ratio2", true)
    acCapacityRatio.setDisplayName("Capacity Ratio 2")
    acCapacityRatio.setDescription("Capacity divided by rated capacity for the second speed.")
    acCapacityRatio.setDefaultValue(1.0)
    args << acCapacityRatio    
    
    #make a double argument for central ac fan speed ratio
    acFanspeedRatio = OpenStudio::Measure::OSArgument::makeDoubleArgument("fan_speed_ratio", true)
    acFanspeedRatio.setDisplayName("Fan Speed Ratio")
    acFanspeedRatio.setDescription("Fan speed divided by fan speed at the compressor speed for which Capacity Ratio = 1.0.")
    acFanspeedRatio.setDefaultValue(0.86)
    args << acFanspeedRatio
    
    #make a double argument for central ac fan speed ratio 2
    acFanspeedRatio = OpenStudio::Measure::OSArgument::makeDoubleArgument("fan_speed_ratio2", true)
    acFanspeedRatio.setDisplayName("Fan Speed Ratio 2")
    acFanspeedRatio.setDescription("Fan speed divided by fan speed at the compressor speed for which Capacity Ratio = 1.0 for the second speed.")
    acFanspeedRatio.setDefaultValue(1.0)
    args << acFanspeedRatio    
    
    #make a double argument for central ac rated supply fan power
    acSupplyFanPowerRated = OpenStudio::Measure::OSArgument::makeDoubleArgument("fan_power_rated", true)
    acSupplyFanPowerRated.setDisplayName("Rated Supply Fan Power")
    acSupplyFanPowerRated.setUnits("W/cfm")
    acSupplyFanPowerRated.setDescription("Fan power (in W) per delivered airflow rate (in cfm) of the outdoor fan under conditions prescribed by AHRI Standard 210/240 for SEER testing.")
    acSupplyFanPowerRated.setDefaultValue(0.14)
    args << acSupplyFanPowerRated
    
    #make a double argument for central ac installed supply fan power
    acSupplyFanPowerInstalled = OpenStudio::Measure::OSArgument::makeDoubleArgument("fan_power_installed", true)
    acSupplyFanPowerInstalled.setDisplayName("Installed Supply Fan Power")
    acSupplyFanPowerInstalled.setUnits("W/cfm")
    acSupplyFanPowerInstalled.setDescription("Fan power (in W) per delivered airflow rate (in cfm) of the outdoor fan for the maximum fan speed under actual operating conditions.")
    acSupplyFanPowerInstalled.setDefaultValue(0.3)
    args << acSupplyFanPowerInstalled
    
    #make a double argument for central ac crankcase
    acCrankcase = OpenStudio::Measure::OSArgument::makeDoubleArgument("crankcase_capacity", true)
    acCrankcase.setDisplayName("Crankcase")
    acCrankcase.setUnits("kW")
    acCrankcase.setDescription("Capacity of the crankcase heater for the compressor.")
    acCrankcase.setDefaultValue(0.0)
    args << acCrankcase

    #make a double argument for central ac crankcase max t
    acCrankcaseMaxT = OpenStudio::Measure::OSArgument::makeDoubleArgument("crankcase_max_temp", true)
    acCrankcaseMaxT.setDisplayName("Crankcase Max Temp")
    acCrankcaseMaxT.setUnits("degrees F")
    acCrankcaseMaxT.setDescription("Outdoor dry-bulb temperature above which compressor crankcase heating is disabled.")
    acCrankcaseMaxT.setDefaultValue(55.0)
    args << acCrankcaseMaxT
    
    #make a double argument for central ac 1.5 ton eer capacity derate
    acEERCapacityDerateFactor1ton = OpenStudio::Measure::OSArgument::makeDoubleArgument("eer_capacity_derate_1ton", true)
    acEERCapacityDerateFactor1ton.setDisplayName("1.5 Ton EER Capacity Derate")
    acEERCapacityDerateFactor1ton.setDescription("EER multiplier for 1.5 ton air-conditioners.")
    acEERCapacityDerateFactor1ton.setDefaultValue(1.0)
    args << acEERCapacityDerateFactor1ton
    
    #make a double argument for central ac 2 ton eer capacity derate
    acEERCapacityDerateFactor2ton = OpenStudio::Measure::OSArgument::makeDoubleArgument("eer_capacity_derate_2ton", true)
    acEERCapacityDerateFactor2ton.setDisplayName("2 Ton EER Capacity Derate")
    acEERCapacityDerateFactor2ton.setDescription("EER multiplier for 2 ton air-conditioners.")
    acEERCapacityDerateFactor2ton.setDefaultValue(1.0)
    args << acEERCapacityDerateFactor2ton

    #make a double argument for central ac 3 ton eer capacity derate
    acEERCapacityDerateFactor3ton = OpenStudio::Measure::OSArgument::makeDoubleArgument("eer_capacity_derate_3ton", true)
    acEERCapacityDerateFactor3ton.setDisplayName("3 Ton EER Capacity Derate")
    acEERCapacityDerateFactor3ton.setDescription("EER multiplier for 3 ton air-conditioners.")
    acEERCapacityDerateFactor3ton.setDefaultValue(1.0)
    args << acEERCapacityDerateFactor3ton

    #make a double argument for central ac 4 ton eer capacity derate
    acEERCapacityDerateFactor4ton = OpenStudio::Measure::OSArgument::makeDoubleArgument("eer_capacity_derate_4ton", true)
    acEERCapacityDerateFactor4ton.setDisplayName("4 Ton EER Capacity Derate")
    acEERCapacityDerateFactor4ton.setDescription("EER multiplier for 4 ton air-conditioners.")
    acEERCapacityDerateFactor4ton.setDefaultValue(1.0)
    args << acEERCapacityDerateFactor4ton

    #make a double argument for central ac 5 ton eer capacity derate
    acEERCapacityDerateFactor5ton = OpenStudio::Measure::OSArgument::makeDoubleArgument("eer_capacity_derate_5ton", true)
    acEERCapacityDerateFactor5ton.setDisplayName("5 Ton EER Capacity Derate")
    acEERCapacityDerateFactor5ton.setDescription("EER multiplier for 5 ton air-conditioners.")
    acEERCapacityDerateFactor5ton.setDefaultValue(1.0)
    args << acEERCapacityDerateFactor5ton
    
    #make a string argument for central air cooling output capacity
    cap_display_names = OpenStudio::StringVector.new
    cap_display_names << Constants.SizingAuto
    (0.5..10.0).step(0.5) do |tons|
      cap_display_names << tons.to_s
    end
    acCoolingOutputCapacity = OpenStudio::Measure::OSArgument::makeChoiceArgument("capacity", cap_display_names, true)
    acCoolingOutputCapacity.setDisplayName("Cooling Capacity")
    acCoolingOutputCapacity.setDescription("The output cooling capacity of the air conditioner.")
    acCoolingOutputCapacity.setUnits("tons")
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
      acOutputCapacity = OpenStudio::convert(acOutputCapacity.to_f,"ton","Btu/h").get
    end 
    
    number_Speeds = 2
    
    # Performance curves

    # NOTE: These coefficients are in IP UNITS
    cOOL_CAP_FT_SPEC = [[3.940185508, -0.104723455, 0.001019298, 0.006471171, -0.00000953, -0.000161658],
                        [3.109456535, -0.085520461, 0.000863238, 0.00863049, -0.0000210, -0.000140186]]
    cOOL_EIR_FT_SPEC = [[-3.877526888, 0.164566276, -0.001272755, -0.019956043, 0.000256512, -0.000133539],
                        [-1.990708931, 0.093969249, -0.00073335, -0.009062553, 0.000165099, -0.0000997]]
    cOOL_CAP_FFLOW_SPEC = [[0.65673024, 0.516470835, -0.172887149], 
                           [0.690334551, 0.464383753, -0.154507638]]
    cOOL_EIR_FFLOW_SPEC = [[1.562945114, -0.791859997, 0.230030877], 
                           [1.31565404, -0.482467162, 0.166239001]]
    
    static = UnitConversion.inH2O2Pa(0.5) # Pascal

    # Cooling Coil
    acRatedAirFlowRate = 355.2 # cfm
    cFM_TON_Rated = HVAC.calc_cfm_ton_rated(acRatedAirFlowRate, acFanspeedRatio, acCapacityRatio)
    coolingEIR = HVAC.calc_cooling_eir(number_Speeds, acCoolingEER, acSupplyFanPowerRated)
    sHR_Rated_Gross = HVAC.calc_shr_rated_gross(number_Speeds, acSHRRated, acSupplyFanPowerRated, cFM_TON_Rated)
    cOOL_CLOSS_FPLR_SPEC = [HVAC.calc_plr_coefficients_cooling(number_Speeds, acCoolingInstalledSEER)] * number_Speeds
    
    # Get building units
    units = Geometry.get_building_units(model, runner)
    if units.nil?
        return false
    end
    
    units.each do |unit|
      
      obj_name = Constants.ObjectNameCentralAirConditioner(unit.name.to_s)
      
      thermal_zones = Geometry.get_thermal_zones_from_spaces(unit.spaces)

      control_slave_zones_hash = HVAC.get_control_and_slave_zones(thermal_zones)
      control_slave_zones_hash.each do |control_zone, slave_zones|
    
        # Remove existing equipment
        htg_coil = HVAC.remove_existing_hvac_equipment(model, runner, Constants.ObjectNameCentralAirConditioner, control_zone)

        # _processCurvesDXCooling
        
        clg_coil_stage_data = HVAC.calc_coil_stage_data_cooling(model, acOutputCapacity, number_Speeds, coolingEIR, sHR_Rated_Gross, cOOL_CAP_FT_SPEC, cOOL_EIR_FT_SPEC, cOOL_CLOSS_FPLR_SPEC, cOOL_CAP_FFLOW_SPEC, cOOL_EIR_FFLOW_SPEC)

        # _processSystemCoolingCoil
        
        clg_coil = OpenStudio::Model::CoilCoolingDXMultiSpeed.new(model)
        clg_coil.setName(obj_name + " cooling coil")
        clg_coil.setCondenserType("AirCooled")
        clg_coil.setApplyPartLoadFractiontoSpeedsGreaterthan1(false)
        clg_coil.setApplyLatentDegradationtoSpeedsGreaterthan1(false)
        clg_coil.setCrankcaseHeaterCapacity(OpenStudio::convert(acCrankcase,"kW","W").get)
        clg_coil.setMaximumOutdoorDryBulbTemperatureforCrankcaseHeaterOperation(OpenStudio::convert(acCrankcaseMaxT,"F","C").get)
        
        clg_coil.setFuelType("Electricity")
             
        clg_coil_stage_data.each do |stage|
            clg_coil.addStage(stage)
        end
          
        # _processSystemFan     
        if not htg_coil.nil?
          begin
            furnaceFuelType = HelperMethods.reverse_eplus_fuel_map(htg_coil.fuelType)
          rescue
            furnaceFuelType = Constants.FuelTypeElectric
          end
          obj_name = Constants.ObjectNameFurnaceAndCentralAirConditioner(furnaceFuelType, unit.name.to_s)
        end
        
        fan_power_curve = HVAC.create_curve_exponent(model, [0, 1, 3], obj_name + " fan power curve", -100, 100)        
        fan_eff_curve = HVAC.create_curve_cubic(model, [0, 1, 0, 0], obj_name + " fan eff curve", 0, 1, 0.01, 1)
        
        fan = OpenStudio::Model::FanOnOff.new(model, model.alwaysOnDiscreteSchedule, fan_power_curve, fan_eff_curve)
        fan.setName(obj_name + " supply fan")
        fan.setEndUseSubcategory(Constants.EndUseHVACFan)
        fan.setFanEfficiency(HVAC.calculate_fan_efficiency(static, acSupplyFanPowerInstalled))
        fan.setPressureRise(static)
        fan.setMotorEfficiency(1)
        fan.setMotorInAirstreamFraction(1)
      
        # _processSystemAir
              
        air_loop_unitary = OpenStudio::Model::AirLoopHVACUnitarySystem.new(model)
        air_loop_unitary.setName(obj_name + " unitary system")
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
        air_loop_unitary.setSupplyAirFanOperatingModeSchedule(model.alwaysOffDiscreteSchedule)
        air_loop_unitary.setMaximumSupplyAirTemperature(OpenStudio::convert(120.0,"F","C").get)
        air_loop_unitary.setSupplyAirFlowRateWhenNoCoolingorHeatingisRequired(0)    
        
        air_loop = OpenStudio::Model::AirLoopHVAC.new(model)
        air_loop.setName(obj_name + " central air system")
        air_supply_inlet_node = air_loop.supplyInletNode
        air_supply_outlet_node = air_loop.supplyOutletNode
        air_demand_inlet_node = air_loop.demandInletNode
        air_demand_outlet_node = air_loop.demandOutletNode    
        
        air_loop_unitary.addToNode(air_supply_inlet_node)
        
        runner.registerInfo("Added '#{fan.name}' to #{air_loop_unitary.name}' of '#{air_loop.name}'")
        runner.registerInfo("Added '#{clg_coil.name}' to '#{air_loop_unitary.name}' of '#{air_loop.name}'")
        unless htg_coil.nil?
          runner.registerInfo("Added '#{htg_coil.name}' to '#{air_loop_unitary.name}' of '#{air_loop.name}'")
        end
        
        air_loop_unitary.setControllingZoneorThermostatLocation(control_zone)
        
        # _processSystemDemandSideAir
        # Demand Side

        # Supply Air
        zone_splitter = air_loop.zoneSplitter
        zone_splitter.setName(obj_name + " zone splitter")
        
        zone_mixer = air_loop.zoneMixer
        zone_mixer.setName(obj_name + " zone mixer")

        diffuser_living = OpenStudio::Model::AirTerminalSingleDuctUncontrolled.new(model, model.alwaysOnDiscreteSchedule)
        diffuser_living.setName(obj_name + " #{control_zone.name} direct air")
        air_loop.addBranchForZone(control_zone, diffuser_living.to_StraightComponent)

        air_loop.addBranchForZone(control_zone)
        runner.registerInfo("Added '#{air_loop.name}' to '#{control_zone.name}' of #{unit.name}")

        HVAC.prioritize_zone_hvac(model, runner, control_zone).reverse.each do |object|
          control_zone.setCoolingPriority(object, 1)
          control_zone.setHeatingPriority(object, 1)
        end
        
        slave_zones.each do |slave_zone|

          # Remove existing equipment
          HVAC.remove_existing_hvac_equipment(model, runner, Constants.ObjectNameCentralAirConditioner, slave_zone)
      
          diffuser_fbsmt = OpenStudio::Model::AirTerminalSingleDuctUncontrolled.new(model, model.alwaysOnDiscreteSchedule)
          diffuser_fbsmt.setName(obj_name + " #{slave_zone.name} direct air")
          air_loop.addBranchForZone(slave_zone, diffuser_fbsmt.to_StraightComponent)

          air_loop.addBranchForZone(slave_zone)
          runner.registerInfo("Added '#{air_loop.name}' to '#{slave_zone.name}' of #{unit.name}")

          HVAC.prioritize_zone_hvac(model, runner, slave_zone).reverse.each do |object|
            slave_zone.setCoolingPriority(object, 1)
            slave_zone.setHeatingPriority(object, 1)
          end
          
        end # slave_zone
      
      end # control_zone
      
      # Store info for HVAC Sizing measure
      unit.setFeature(Constants.SizingInfoHVACFanspeedRatioCooling, acFanspeedRatio.join(","))
      unit.setFeature(Constants.SizingInfoHVACCapacityRatioCooling, acCapacityRatio.join(","))
      unit.setFeature(Constants.SizingInfoHVACCapacityDerateFactorEER, acEERCapacityDerateFactor.join(","))
      unit.setFeature(Constants.SizingInfoHVACRatedCFMperTonCooling, cFM_TON_Rated.join(","))
      
    end # unit
	
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ProcessTwoSpeedCentralAirConditioner.new.registerWithApplication