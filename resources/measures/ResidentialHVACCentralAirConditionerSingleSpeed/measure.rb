# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/measures/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"
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
    seer = OpenStudio::Measure::OSArgument::makeDoubleArgument("seer", true)
    seer.setDisplayName("Rated SEER")
    seer.setUnits("Btu/W-h")
    seer.setDescription("Seasonal Energy Efficiency Ratio (SEER) is a measure of equipment energy efficiency over the cooling season.")
    seer.setDefaultValue(13.0)
    args << seer
    
    #make a double argument for central ac eer
    eer = OpenStudio::Measure::OSArgument::makeDoubleArgument("eer", true)
    eer.setDisplayName("EER")
    eer.setUnits("kBtu/kWh")
    eer.setDescription("EER (net) from the A test (95 ODB/80 EDB/67 EWB).")
    eer.setDefaultValue(11.1)
    args << eer

    #make a double argument for central ac rated shr
    shr = OpenStudio::Measure::OSArgument::makeDoubleArgument("shr", true)
    shr.setDisplayName("Rated SHR")
    shr.setDescription("The sensible heat ratio (ratio of the sensible portion of the load to the total load) at the nominal rated capacity.")
    shr.setDefaultValue(0.73)
    args << shr 
    
    #make a double argument for central ac rated supply fan power
    fan_power_rated = OpenStudio::Measure::OSArgument::makeDoubleArgument("fan_power_rated", true)
    fan_power_rated.setDisplayName("Rated Supply Fan Power")
    fan_power_rated.setUnits("W/cfm")
    fan_power_rated.setDescription("Fan power (in W) per delivered airflow rate (in cfm) of the outdoor fan under conditions prescribed by AHRI Standard 210/240 for SEER testing.")
    fan_power_rated.setDefaultValue(0.365)
    args << fan_power_rated
    
    #make a double argument for central ac installed supply fan power
    fan_power_installed = OpenStudio::Measure::OSArgument::makeDoubleArgument("fan_power_installed", true)
    fan_power_installed.setDisplayName("Installed Supply Fan Power")
    fan_power_installed.setUnits("W/cfm")
    fan_power_installed.setDescription("Fan power (in W) per delivered airflow rate (in cfm) of the outdoor fan for the maximum fan speed under actual operating conditions.")
    fan_power_installed.setDefaultValue(0.5)
    args << fan_power_installed
    
    #make a double argument for central ac crankcase
    crankcase_capacity = OpenStudio::Measure::OSArgument::makeDoubleArgument("crankcase_capacity", true)
    crankcase_capacity.setDisplayName("Crankcase")
    crankcase_capacity.setUnits("kW")
    crankcase_capacity.setDescription("Capacity of the crankcase heater for the compressor.")
    crankcase_capacity.setDefaultValue(0.0)
    args << crankcase_capacity

    #make a double argument for central ac crankcase max t
    crankcase_temp = OpenStudio::Measure::OSArgument::makeDoubleArgument("crankcase_temp", true)
    crankcase_temp.setDisplayName("Crankcase Max Temp")
    crankcase_temp.setUnits("degrees F")
    crankcase_temp.setDescription("Outdoor dry-bulb temperature above which compressor crankcase heating is disabled.")
    crankcase_temp.setDefaultValue(55.0)
    args << crankcase_temp
    
    #make a double argument for central ac 1.5 ton eer capacity derate
    eer_capacity_derate_1ton = OpenStudio::Measure::OSArgument::makeDoubleArgument("eer_capacity_derate_1ton", true)
    eer_capacity_derate_1ton.setDisplayName("1.5 Ton EER Capacity Derate")
    eer_capacity_derate_1ton.setDescription("EER multiplier for 1.5 ton air-conditioners.")
    eer_capacity_derate_1ton.setDefaultValue(1.0)
    args << eer_capacity_derate_1ton
    
    #make a double argument for central ac 2 ton eer capacity derate
    eer_capacity_derate_2ton = OpenStudio::Measure::OSArgument::makeDoubleArgument("eer_capacity_derate_2ton", true)
    eer_capacity_derate_2ton.setDisplayName("2 Ton EER Capacity Derate")
    eer_capacity_derate_2ton.setDescription("EER multiplier for 2 ton air-conditioners.")
    eer_capacity_derate_2ton.setDefaultValue(1.0)
    args << eer_capacity_derate_2ton

    #make a double argument for central ac 3 ton eer capacity derate
    eer_capacity_derate_3ton = OpenStudio::Measure::OSArgument::makeDoubleArgument("eer_capacity_derate_3ton", true)
    eer_capacity_derate_3ton.setDisplayName("3 Ton EER Capacity Derate")
    eer_capacity_derate_3ton.setDescription("EER multiplier for 3 ton air-conditioners.")
    eer_capacity_derate_3ton.setDefaultValue(1.0)
    args << eer_capacity_derate_3ton

    #make a double argument for central ac 4 ton eer capacity derate
    eer_capacity_derate_4ton = OpenStudio::Measure::OSArgument::makeDoubleArgument("eer_capacity_derate_4ton", true)
    eer_capacity_derate_4ton.setDisplayName("4 Ton EER Capacity Derate")
    eer_capacity_derate_4ton.setDescription("EER multiplier for 4 ton air-conditioners.")
    eer_capacity_derate_4ton.setDefaultValue(1.0)
    args << eer_capacity_derate_4ton

    #make a double argument for central ac 5 ton eer capacity derate
    eer_capacity_derate_5ton = OpenStudio::Measure::OSArgument::makeDoubleArgument("eer_capacity_derate_5ton", true)
    eer_capacity_derate_5ton.setDisplayName("5 Ton EER Capacity Derate")
    eer_capacity_derate_5ton.setDescription("EER multiplier for 5 ton air-conditioners.")
    eer_capacity_derate_5ton.setDefaultValue(1.0)
    args << eer_capacity_derate_5ton
    
    #make a string argument for central air cooling output capacity
    capacity = OpenStudio::Measure::OSArgument::makeStringArgument("capacity", true)
    capacity.setDisplayName("Cooling Capacity")
    capacity.setDescription("The output cooling capacity of the air conditioner. If using '#{Constants.SizingAuto}', the autosizing algorithm will use ACCA Manual S to set the capacity.")
    capacity.setUnits("tons")
    capacity.setDefaultValue(Constants.SizingAuto)
    args << capacity    
    
    #make a string argument for distribution system efficiency
    dse = OpenStudio::Measure::OSArgument::makeStringArgument("dse", true)
    dse.setDisplayName("Distribution System Efficiency")
    dse.setDescription("Defines the energy losses associated with the delivery of energy from the equipment to the source of the load.")
    dse.setDefaultValue("NA")
    args << dse  
    
    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end
  
    seer = runner.getDoubleArgumentValue("seer",user_arguments)
    eers = [runner.getDoubleArgumentValue("eer",user_arguments)]
    shrs = [runner.getDoubleArgumentValue("shr",user_arguments)]
    fan_power_rated = runner.getDoubleArgumentValue("fan_power_rated",user_arguments)
    fan_power_installed = runner.getDoubleArgumentValue("fan_power_installed",user_arguments)
    crankcase_capacity = runner.getDoubleArgumentValue("crankcase_capacity",user_arguments)
    crankcase_temp = runner.getDoubleArgumentValue("crankcase_temp",user_arguments)
    eer_capacity_derate_1ton = runner.getDoubleArgumentValue("eer_capacity_derate_1ton",user_arguments)
    eer_capacity_derate_2ton = runner.getDoubleArgumentValue("eer_capacity_derate_2ton",user_arguments)
    eer_capacity_derate_3ton = runner.getDoubleArgumentValue("eer_capacity_derate_3ton",user_arguments)
    eer_capacity_derate_4ton = runner.getDoubleArgumentValue("eer_capacity_derate_4ton",user_arguments)
    eer_capacity_derate_5ton = runner.getDoubleArgumentValue("eer_capacity_derate_5ton",user_arguments)
    eer_capacity_derates = [eer_capacity_derate_1ton, eer_capacity_derate_2ton, eer_capacity_derate_3ton, eer_capacity_derate_4ton, eer_capacity_derate_5ton]
    capacity = runner.getStringArgumentValue("capacity",user_arguments)
    unless capacity == Constants.SizingAuto
      capacity = UnitConversions.convert(capacity.to_f,"ton","Btu/hr")
    end 
    dse = runner.getStringArgumentValue("dse",user_arguments)
    if dse.to_f > 0
      dse = dse.to_f
    else
      dse = 1.0
    end
    
    # Get building units
    units = Geometry.get_building_units(model, runner)
    if units.nil?
      return false
    end 
    
    units.each do |unit|
    
<<<<<<< HEAD
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
=======
      existing_objects = {}
      thermal_zones = Geometry.get_thermal_zones_from_spaces(unit.spaces)
      HVAC.get_control_and_slave_zones(thermal_zones).each do |control_zone, slave_zones|
        ([control_zone] + slave_zones).each do |zone|
          existing_objects[zone] = HVAC.remove_hvac_equipment(model, runner, zone, unit,
                                                              Constants.ObjectNameCentralAirConditioner)
        end
      end
    
      success = HVAC.apply_central_ac_1speed(model, unit, runner, seer, eers, shrs,
                                             fan_power_rated, fan_power_installed,
                                             crankcase_capacity, crankcase_temp,
                                             eer_capacity_derates, capacity, dse,
                                             existing_objects)
      return false if not success
>>>>>>> master
      
    end # unit

    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ProcessSingleSpeedCentralAirConditioner.new.registerWithApplication