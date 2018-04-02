# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/measures/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"
require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/unit_conversions"
require "#{File.dirname(__FILE__)}/resources/hvac"

#start the measure
class ProcessSingleSpeedCentralAirConditioner < OpenStudio::Measure::ModelMeasure

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Residential Single-Speed Central Air Conditioner"
  end
  
  def description
    return "This measure removes any existing HVAC cooling components from the building and adds a single-speed central air conditioner along with an on/off supply fan to a unitary air loop. For multifamily buildings, the single-speed central air conditioner can be set for all units of the building.#{Constants.WorkflowDescription}"
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
    acCoolingInstalledSEER.setDefaultValue(13.0)
    args << acCoolingInstalledSEER
    
    #make a double argument for central ac eer
    acCoolingEER = OpenStudio::Measure::OSArgument::makeDoubleArgument("eer", true)
    acCoolingEER.setDisplayName("EER")
    acCoolingEER.setUnits("kBtu/kWh")
    acCoolingEER.setDescription("EER (net) from the A test (95 ODB/80 EDB/67 EWB).")
    acCoolingEER.setDefaultValue(11.1)
    args << acCoolingEER

    #make a double argument for central ac rated shr
    acSHRRated = OpenStudio::Measure::OSArgument::makeDoubleArgument("shr", true)
    acSHRRated.setDisplayName("Rated SHR")
    acSHRRated.setDescription("The sensible heat ratio (ratio of the sensible portion of the load to the total load) at the nominal rated capacity.")
    acSHRRated.setDefaultValue(0.73)
    args << acSHRRated 
    
    #make a double argument for central ac rated supply fan power
    acSupplyFanPowerRated = OpenStudio::Measure::OSArgument::makeDoubleArgument("fan_power_rated", true)
    acSupplyFanPowerRated.setDisplayName("Rated Supply Fan Power")
    acSupplyFanPowerRated.setUnits("W/cfm")
    acSupplyFanPowerRated.setDescription("Fan power (in W) per delivered airflow rate (in cfm) of the outdoor fan under conditions prescribed by AHRI Standard 210/240 for SEER testing.")
    acSupplyFanPowerRated.setDefaultValue(0.365)
    args << acSupplyFanPowerRated
    
    #make a double argument for central ac installed supply fan power
    acSupplyFanPowerInstalled = OpenStudio::Measure::OSArgument::makeDoubleArgument("fan_power_installed", true)
    acSupplyFanPowerInstalled.setDisplayName("Installed Supply Fan Power")
    acSupplyFanPowerInstalled.setUnits("W/cfm")
    acSupplyFanPowerInstalled.setDescription("Fan power (in W) per delivered airflow rate (in cfm) of the outdoor fan for the maximum fan speed under actual operating conditions.")
    acSupplyFanPowerInstalled.setDefaultValue(0.5)
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
    acCoolingOutputCapacity = OpenStudio::Measure::OSArgument::makeStringArgument("capacity", true)
    acCoolingOutputCapacity.setDisplayName("Cooling Capacity")
    acCoolingOutputCapacity.setDescription("The output cooling capacity of the air conditioner. If using '#{Constants.SizingAuto}', the autosizing algorithm will use ACCA Manual S to set the capacity.")
    acCoolingOutputCapacity.setUnits("tons")
    acCoolingOutputCapacity.setDefaultValue(Constants.SizingAuto)
    args << acCoolingOutputCapacity    
    
    #make a string argument for distribution system efficiency
    dist_system_eff = OpenStudio::Measure::OSArgument::makeStringArgument("dse", true)
    dist_system_eff.setDisplayName("Distribution System Efficiency")
    dist_system_eff.setDescription("Defines the energy losses associated with the delivery of energy from the equipment to the source of the load.")
    dist_system_eff.setDefaultValue("NA")
    args << dist_system_eff  
    
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
    acCoolingEER = [runner.getDoubleArgumentValue("eer",user_arguments)]
    acSHRRated = [runner.getDoubleArgumentValue("shr",user_arguments)]
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
      acOutputCapacity = UnitConversions.convert(acOutputCapacity.to_f,"ton","Btu/hr")
    end 
    dse = runner.getStringArgumentValue("dse",user_arguments)
    if dse.to_f > 0
      dse = dse.to_f
    else
      dse = 1.0
    end    
    
    # Performance curves
    number_Speeds = 1

    # NOTE: These coefficients are in IP UNITS
    cOOL_CAP_FT_SPEC = [[3.670270705, -0.098652414, 0.000955906, 0.006552414, -0.0000156, -0.000131877]]
    cOOL_EIR_FT_SPEC = [[-3.302695861, 0.137871531, -0.001056996, -0.012573945, 0.000214638, -0.000145054]]
    cOOL_CAP_FFLOW_SPEC = [[0.718605468, 0.410099989, -0.128705457]]
    cOOL_EIR_FFLOW_SPEC = [[1.32299905, -0.477711207, 0.154712157]]
    
    static = UnitConversions.convert(0.5,"inH2O","Pa") # Pascal

    acCapacityRatio = [1.0]
    acFanspeedRatio = [1.0]
    
    # Cooling Coil
    acRatedAirFlowRate = 386.1 # cfm
    cFM_TON_Rated = HVAC.calc_cfm_ton_rated(acRatedAirFlowRate, acFanspeedRatio, acCapacityRatio)
    coolingEIR = HVAC.calc_cooling_eir(number_Speeds, acCoolingEER, acSupplyFanPowerRated)
    sHR_Rated_Gross = HVAC.calc_shr_rated_gross(number_Speeds, acSHRRated, acSupplyFanPowerRated, cFM_TON_Rated)
    cOOL_CLOSS_FPLR_SPEC = [HVAC.calc_plr_coefficients_cooling(number_Speeds, acCoolingInstalledSEER)]
    
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
        htg_coil, _perf = HVAC.remove_existing_hvac_equipment(model, runner, Constants.ObjectNameCentralAirConditioner, control_zone, false, unit)

        # _processCurvesDXCooling
        
        clg_coil_stage_data = HVAC.calc_coil_stage_data_cooling(model, acOutputCapacity, number_Speeds, coolingEIR, sHR_Rated_Gross, cOOL_CAP_FT_SPEC, cOOL_EIR_FT_SPEC, cOOL_CLOSS_FPLR_SPEC, cOOL_CAP_FFLOW_SPEC, cOOL_EIR_FFLOW_SPEC, dse)

        # _processSystemCoolingCoil
        
        clg_coil = OpenStudio::Model::CoilCoolingDXSingleSpeed.new(model, model.alwaysOnDiscreteSchedule, clg_coil_stage_data[0].totalCoolingCapacityFunctionofTemperatureCurve, clg_coil_stage_data[0].totalCoolingCapacityFunctionofFlowFractionCurve, clg_coil_stage_data[0].energyInputRatioFunctionofTemperatureCurve, clg_coil_stage_data[0].energyInputRatioFunctionofFlowFractionCurve, clg_coil_stage_data[0].partLoadFractionCorrelationCurve)
        clg_coil_stage_data[0].remove
        clg_coil.setName(obj_name + " cooling coil")
        if acOutputCapacity != Constants.SizingAuto
          clg_coil.setRatedTotalCoolingCapacity(UnitConversions.convert(acOutputCapacity,"Btu/hr","W")) # Used by HVACSizing measure
        end
        clg_coil.setRatedSensibleHeatRatio(sHR_Rated_Gross[0])
        clg_coil.setRatedCOP(OpenStudio::OptionalDouble.new(dse / coolingEIR[0]))
        clg_coil.setRatedEvaporatorFanPowerPerVolumeFlowRate(OpenStudio::OptionalDouble.new(acSupplyFanPowerRated / UnitConversions.convert(1.0,"cfm","m^3/s")))

        clg_coil.setNominalTimeForCondensateRemovalToBegin(OpenStudio::OptionalDouble.new(1000.0))
        clg_coil.setRatioOfInitialMoistureEvaporationRateAndSteadyStateLatentCapacity(OpenStudio::OptionalDouble.new(1.5))
        clg_coil.setMaximumCyclingRate(OpenStudio::OptionalDouble.new(3.0))
        clg_coil.setLatentCapacityTimeConstant(OpenStudio::OptionalDouble.new(45.0))

        clg_coil.setCondenserType("AirCooled")
        clg_coil.setCrankcaseHeaterCapacity(OpenStudio::OptionalDouble.new(UnitConversions.convert(acCrankcase,"kW","W")))
        clg_coil.setMaximumOutdoorDryBulbTemperatureForCrankcaseHeaterOperation(OpenStudio::OptionalDouble.new(UnitConversions.convert(acCrankcaseMaxT,"F","C")))
          
        # _processSystemFan
        if not htg_coil.nil?
          begin
            furnaceFuelType = HelperMethods.reverse_eplus_fuel_map(htg_coil.fuelType)
          rescue
            furnaceFuelType = Constants.FuelTypeElectric
          end
          obj_name = Constants.ObjectNameFurnaceAndCentralAirConditioner(furnaceFuelType, unit.name.to_s)
        end
        
        fan = OpenStudio::Model::FanOnOff.new(model, model.alwaysOnDiscreteSchedule)
        fan.setName(obj_name + " supply fan")
        fan.setEndUseSubcategory(Constants.EndUseHVACFan)
        fan.setFanEfficiency(dse * HVAC.calculate_fan_efficiency(static, acSupplyFanPowerInstalled))
        fan.setPressureRise(static)
        fan.setMotorEfficiency(dse * 1.0)
        fan.setMotorInAirstreamFraction(1.0) 
      
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
        air_loop_unitary.setMaximumSupplyAirTemperature(UnitConversions.convert(120.0,"F","C"))
        air_loop_unitary.setSupplyAirFlowRateWhenNoCoolingorHeatingisRequired(0)    
        
        air_loop = OpenStudio::Model::AirLoopHVAC.new(model)
        air_loop.setName(obj_name + " central air system")
        air_supply_inlet_node = air_loop.supplyInletNode
        air_supply_outlet_node = air_loop.supplyOutletNode
        air_demand_inlet_node = air_loop.demandInletNode
        air_demand_outlet_node = air_loop.demandOutletNode    
        
        air_loop_unitary.addToNode(air_supply_inlet_node)
        
        runner.registerInfo("Added '#{fan.name}' to '#{air_loop_unitary.name}' of '#{air_loop.name}'")
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

        HVAC.prioritize_zone_hvac(model, runner, control_zone)
        
        slave_zones.each do |slave_zone|

          # Remove existing equipment
          HVAC.remove_existing_hvac_equipment(model, runner, Constants.ObjectNameCentralAirConditioner, slave_zone, false, unit)
      
          diffuser_fbsmt = OpenStudio::Model::AirTerminalSingleDuctUncontrolled.new(model, model.alwaysOnDiscreteSchedule)
          diffuser_fbsmt.setName(obj_name + " #{slave_zone.name} direct air")
          air_loop.addBranchForZone(slave_zone, diffuser_fbsmt.to_StraightComponent)

          air_loop.addBranchForZone(slave_zone)
          runner.registerInfo("Added '#{air_loop.name}' to '#{slave_zone.name}' of #{unit.name}")

          HVAC.prioritize_zone_hvac(model, runner, slave_zone)
          
        end # slave_zone
      
      end # control_zone
      
      # Store info for HVAC Sizing measure
      unit.setFeature(Constants.SizingInfoHVACCapacityDerateFactorEER, acEERCapacityDerateFactor.join(","))
      unit.setFeature(Constants.SizingInfoHVACRatedCFMperTonCooling, cFM_TON_Rated.join(","))
      
    end # unit

    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ProcessSingleSpeedCentralAirConditioner.new.registerWithApplication