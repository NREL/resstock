# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"
require "#{File.dirname(__FILE__)}/resources/hvac"

# start the measure
class ProcessBoiler < OpenStudio::Ruleset::ModelUserScript

  # human readable name
  def name
    return "Set Residential Boiler"
  end

  # human readable description
  def description
    return "This measure removes any existing HVAC heating components from the building and adds a boiler along with constant speed pump and water baseboard coils to a hot water plant loop. For multifamily buildings, the boiler can be set for all units of the building."
  end

  # human readable description of modeling approach
  def modeler_description
    return "Any heating components or baseboard convective electrics/waters are removed from any existing air/plant loops or zones. A boiler along with constant speed pump and water baseboard coils are added to a hot water plant loop."
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make a choice argument for boiler fuel type
    fuel_display_names = OpenStudio::StringVector.new
    fuel_display_names << Constants.FuelTypeGas
    fuel_display_names << Constants.FuelTypeElectric
    fuel_display_names << Constants.FuelTypeOil
    fuel_display_names << Constants.FuelTypePropane

    #make a string argument for boiler fuel type
    boilerFuelType = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("boilerFuelType", fuel_display_names, true)
    boilerFuelType.setDisplayName("Fuel Type")
    boilerFuelType.setDescription("Type of fuel used for heating.")
    boilerFuelType.setDefaultValue(Constants.FuelTypeGas)
    args << boilerFuelType
    
    #make a choice argument for boiler system type
    boiler_display_names = OpenStudio::StringVector.new
    boiler_display_names << Constants.BoilerTypeForcedDraft
    boiler_display_names << Constants.BoilerTypeCondensing
    boiler_display_names << Constants.BoilerTypeNaturalDraft
    boiler_display_names << Constants.BoilerTypeSteam

    #make a string argument for boiler system type
    boilerType = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("boilerType", boiler_display_names, true)
    boilerType.setDisplayName("System Type")
    boilerType.setDescription("The system type of the boiler.")
    boilerType.setDefaultValue(Constants.BoilerTypeForcedDraft)
    args << boilerType
    
    #make an argument for entering boiler installed afue
    boilerInstalledAFUE = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("boilerInstalledAFUE",true)
    boilerInstalledAFUE.setDisplayName("Installed AFUE")
    boilerInstalledAFUE.setUnits("Btu/Btu")
    boilerInstalledAFUE.setDescription("The installed Annual Fuel Utilization Efficiency (AFUE) of the boiler, which can be used to account for performance derating or degradation relative to the rated value.")
    boilerInstalledAFUE.setDefaultValue(0.80)
    args << boilerInstalledAFUE
    
    #make a bool argument for whether the boiler OAT enabled
    boilerOATResetEnabled = OpenStudio::Ruleset::OSArgument::makeBoolArgument("boilerOATResetEnabled", true)
    boilerOATResetEnabled.setDisplayName("Outside Air Reset Enabled")
    boilerOATResetEnabled.setDescription("Outside Air Reset Enabled on Hot Water Supply Temperature.")
    boilerOATResetEnabled.setDefaultValue(false)
    args << boilerOATResetEnabled    
    
    #make an argument for entering boiler OAT high
    boilerOATHigh = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("boilerOATHigh",false)
    boilerOATHigh.setDisplayName("High Outside Air Temp")
    boilerOATHigh.setUnits("degrees F")
    boilerOATHigh.setDescription("High Outside Air Temperature.")
    args << boilerOATHigh    
    
    #make an argument for entering boiler OAT low
    boilerOATLow = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("boilerOATLow",false)
    boilerOATLow.setDisplayName("Low Outside Air Temp")
    boilerOATLow.setUnits("degrees F")
    boilerOATLow.setDescription("Low Outside Air Temperature.")
    args << boilerOATLow
    
    #make an argument for entering boiler OAT high HWST
    boilerOATHighHWST = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("boilerOATHighHWST",false)
    boilerOATHighHWST.setDisplayName("Hot Water Supply Temp High Outside Air")
    boilerOATHighHWST.setUnits("degrees F")
    boilerOATHighHWST.setDescription("Hot Water Supply Temperature corresponding to High Outside Air Temperature.")
    args << boilerOATHighHWST
    
    #make an argument for entering boiler OAT low HWST
    boilerOATLowHWST = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("boilerOATLowHWST",false)
    boilerOATLowHWST.setDisplayName("Hot Water Supply Temp Low Outside Air")
    boilerOATLowHWST.setUnits("degrees F")
    boilerOATLowHWST.setDescription("Hot Water Supply Temperature corresponding to Low Outside Air Temperature.")
    args << boilerOATLowHWST        
    
    #make an argument for entering boiler design temp
    boilerDesignTemp = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("boilerDesignTemp",false)
    boilerDesignTemp.setDisplayName("Design Temperature")
    boilerDesignTemp.setUnits("degrees F")
    boilerDesignTemp.setDescription("Temperature of the outlet water.")
    boilerDesignTemp.setDefaultValue(180.0)
    args << boilerDesignTemp     
    
    #make a choice argument for furnace heating output capacity
    cap_display_names = OpenStudio::StringVector.new
    cap_display_names << Constants.SizingAuto
    (5..150).step(5) do |kbtu|
      cap_display_names << "#{kbtu} kBtu/hr"
    end

    #make a string argument for furnace heating output capacity
    boilerOutputCapacity = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("boilerOutputCapacity", cap_display_names, true)
    boilerOutputCapacity.setDisplayName("Heating Output Capacity")
    boilerOutputCapacity.setDefaultValue(Constants.SizingAuto)
    args << boilerOutputCapacity  

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end
    
    boilerFuelType = runner.getStringArgumentValue("boilerFuelType",user_arguments)
    boilerType = runner.getStringArgumentValue("boilerType",user_arguments)
    boilerInstalledAFUE = runner.getDoubleArgumentValue("boilerInstalledAFUE",user_arguments)
    boilerOATResetEnabled = runner.getBoolArgumentValue("boilerOATResetEnabled",user_arguments)    
    boilerOATHigh = runner.getOptionalDoubleArgumentValue("boilerOATHigh", user_arguments)
    boilerOATHigh.is_initialized ? boilerOATHigh = boilerOATHigh.get : boilerOATHigh = nil    
    boilerOATLow = runner.getOptionalDoubleArgumentValue("boilerOATLow", user_arguments)
    boilerOATLow.is_initialized ? boilerOATLow = boilerOATLow.get : boilerOATLow = nil     
    boilerOATHighHWST = runner.getOptionalDoubleArgumentValue("boilerOATHighHWST", user_arguments)
    boilerOATHighHWST.is_initialized ? boilerOATHighHWST = boilerOATHighHWST.get : boilerOATHighHWST = nil
    boilerOATLowHWST = runner.getOptionalDoubleArgumentValue("boilerOATLowHWST", user_arguments)
    boilerOATLowHWST.is_initialized ? boilerOATLowHWST = boilerOATLowHWST.get : boilerOATLowHWST = nil      
    boilerOutputCapacity = runner.getStringArgumentValue("boilerOutputCapacity",user_arguments)
    if not boilerOutputCapacity == Constants.SizingAuto
      boilerOutputCapacity = OpenStudio::convert(boilerOutputCapacity.split(" ")[0].to_f,"kBtu/h","Btu/h").get
    end
    boilerDesignTemp = runner.getDoubleArgumentValue("boilerDesignTemp",user_arguments)
    
    hasBoilerCondensing = false
    if boilerType == Constants.BoilerTypeCondensing
      hasBoilerCondensing = true
    end
    
    # _processHydronicSystem
    
    if boilerType == Constants.BoilerTypeSteam
      runner.registerError("Cannot currently model steam boilers.")
      return false
    end
    
    # Installed equipment adjustments
    boiler_hir = get_boiler_hir(boilerInstalledAFUE)
    
    if boilerType == Constants.BoilerTypeCondensing
      # Efficiency curves are normalized using 80F return water temperature, at 0.254PLR
      condensingBlr_TE_FT_coefficients = [1.058343061, 0.052650153, 0.0087272, 0.001742217, 0.00000333715, 0.000513723]
    end
        
    if boilerOATResetEnabled
      if boilerOATHigh.nil? or boilerOATLow.nil? or boilerOATLowHWST.nil? or boilerOATHighHWST.nil?
        runner.registerWarning("Boiler outdoor air temperature (OAT) reset is enabled but no setpoints were specified so OAT reset is being disabled.")
        boilerOATResetEnabled = false
      end
    end
    
    # Parasitic Electricity (Source: DOE. (2007). Technical Support Document: Energy Efficiency Program for Consumer Products: "Energy Conservation Standards for Residential Furnaces and Boilers". www.eere.energy.gov/buildings/appliance_standards/residential/furnaces_boilers.html)
    boilerParasiticElecDict = {Constants.FuelTypeGas=>76.0, # W during operation
                               Constants.FuelTypePropane=>76.0,
                               Constants.FuelTypeOil=>220.0,
                               Constants.FuelTypeElectric=>0.0}
    boiler_aux = boilerParasiticElecDict[boilerFuelType]
    
    # _processCurvesBoiler
    
    boiler_eff_curve = _processCurvesBoiler(model, runner, hasBoilerCondensing)
    
    # Remove boiler hot water loop if it exists
    HVAC.remove_hot_water_loop(model, runner)
    
    # _processSystemHydronic
    
    plant_loop = OpenStudio::Model::PlantLoop.new(model)
    plant_loop.setName("Hydronic Heat Loop")
    plant_loop.setFluidType("Water")
    plant_loop.setMaximumLoopTemperature(100)
    plant_loop.setMinimumLoopTemperature(0)
    plant_loop.setMinimumLoopFlowRate(0)
    
    loop_sizing = plant_loop.sizingPlant
    loop_sizing.setLoopType("Heating")
    loop_sizing.setDesignLoopExitTemperature(OpenStudio::convert(boilerDesignTemp - 32.0,"R","K").get)
    loop_sizing.setLoopDesignTemperatureDifference(OpenStudio::convert(20.0,"R","K").get)
    
    pump = OpenStudio::Model::PumpConstantSpeed.new(model)
    pump.setName("HydronicPump")
    if boilerOutputCapacity != Constants.SizingAuto
      pump.setRatedFlowRate(OpenStudio::convert(boilerOutputCapacity/20.0/500.0,"gal/min","m^3/s").get)
    end
    pump.setRatedPumpHead(179352)
    pump.setMotorEfficiency(0.9)
    pump.setFractionofMotorInefficienciestoFluidStream(0)
    pump.setPumpControlType("Intermittent")
        
    boiler = OpenStudio::Model::BoilerHotWater.new(model)
    boiler.setName("Boiler")
    boiler.setFuelType(HelperMethods.eplus_fuel_map(boilerFuelType))
    if boilerOutputCapacity != Constants.SizingAuto
      boiler.setNominalCapacity(OpenStudio::convert(boilerOutputCapacity,"Btu/h","W").get)
    end
    if boilerType == Constants.BoilerTypeCondensing
      # Convert Rated Efficiency at 80F and 1.0PLR where the performance curves are derived from to Design condition as input
      boiler_RatedHWRT = OpenStudio::convert(80.0-32.0,"R","K").get
      plr_Rated = 1.0
      plr_Design = 1.0
      boiler_DesignHWRT = OpenStudio::convert(boilerDesignTemp - 20.0 - 32.0,"R","K").get
      condBlr_TE_Coeff = condensingBlr_TE_FT_coefficients   # The coefficients are normalized at 80F HWRT
      boilerEff_Norm = 1.0 / boiler_hir / (condBlr_TE_Coeff[0] - condBlr_TE_Coeff[1] * plr_Rated - condBlr_TE_Coeff[2] * plr_Rated**2 - condBlr_TE_Coeff[3] * boiler_RatedHWRT + condBlr_TE_Coeff[4] * boiler_RatedHWRT**2 + condBlr_TE_Coeff[5] * boiler_RatedHWRT * plr_Rated)
      boilerEff_Design = boilerEff_Norm * (condBlr_TE_Coeff[0] - condBlr_TE_Coeff[1] * plr_Design - condBlr_TE_Coeff[2] * plr_Design**2 - condBlr_TE_Coeff[3] * boiler_DesignHWRT + condBlr_TE_Coeff[4] * boiler_DesignHWRT**2 + condBlr_TE_Coeff[5] * boiler_DesignHWRT * plr_Design)
      boiler.setNominalThermalEfficiency(boilerEff_Design)
      boiler.setEfficiencyCurveTemperatureEvaluationVariable("EnteringBoiler")
      boiler.setNormalizedBoilerEfficiencyCurve(boiler_eff_curve)
      boiler.setDesignWaterOutletTemperature(OpenStudio::convert(boilerDesignTemp - 32.0,"R","K").get)
      boiler.setMinimumPartLoadRatio(0.0) 
      boiler.setMaximumPartLoadRatio(1.0)
    else
      boiler.setNominalThermalEfficiency(1.0 / boiler_hir)
      boiler.setEfficiencyCurveTemperatureEvaluationVariable("LeavingBoiler")
      boiler.setNormalizedBoilerEfficiencyCurve(boiler_eff_curve)
      boiler.setDesignWaterOutletTemperature(OpenStudio::convert(boilerDesignTemp - 32.0,"R","K").get)
      boiler.setMinimumPartLoadRatio(0.0) 
      boiler.setMaximumPartLoadRatio(1.1)
    end
    boiler.setOptimumPartLoadRatio(1.0)
    boiler.setWaterOutletUpperTemperatureLimit(99.9)
    boiler.setBoilerFlowMode("ConstantFlow")
    boiler.setParasiticElectricLoad(boiler_aux)
       
    if boilerType == Constants.BoilerTypeCondensing and boilerOATResetEnabled
      setpoint_manager_oar = OpenStudio::Model::SetpointManagerOutdoorAirReset.new(model)
      setpoint_manager_oar.setName("OutdoorReset")
      setpoint_manager_oar.setControlVariable("Temperature")
      setpoint_manager_oar.setSetpointatOutdoorLowTemperature(OpenStudio::convert(boilerOATLowHWST,"F","C").get)
      setpoint_manager_oar.setOutdoorLowTemperature(OpenStudio::convert(boilerOATLow,"F","C").get)
      setpoint_manager_oar.setSetpointatOutdoorHighTemperature(OpenStudio::convert(boilerOATHighHWST,"F","C").get)
      setpoint_manager_oar.setOutdoorHighTemperature(OpenStudio::convert(boilerOATHigh,"F","C").get)
      setpoint_manager_oar.addToNode(plant_loop.supplyOutletNode)      
    end
    
    hydronic_heat_supply_setpoint = OpenStudio::Model::ScheduleConstant.new(model)
    hydronic_heat_supply_setpoint.setName("Hydronic Heat Supply Setpoint")
    hydronic_heat_supply_setpoint.setValue(OpenStudio::convert(boilerDesignTemp,"F","C").get)    
    
    setpoint_manager_scheduled = OpenStudio::Model::SetpointManagerScheduled.new(model, hydronic_heat_supply_setpoint)
    setpoint_manager_scheduled.setName("Hydronic Heat Loop Setpoint Manager")
    setpoint_manager_scheduled.setControlVariable("Temperature")
    
    pipe_supply_bypass = OpenStudio::Model::PipeAdiabatic.new(model)
    pipe_supply_outlet = OpenStudio::Model::PipeAdiabatic.new(model)
    pipe_demand_bypass = OpenStudio::Model::PipeAdiabatic.new(model)
    pipe_demand_inlet = OpenStudio::Model::PipeAdiabatic.new(model)
    pipe_demand_outlet = OpenStudio::Model::PipeAdiabatic.new(model)    
    
    plant_loop.addSupplyBranchForComponent(boiler)
    plant_loop.addSupplyBranchForComponent(pipe_supply_bypass)
    pump.addToNode(plant_loop.supplyInletNode)
    pipe_supply_outlet.addToNode(plant_loop.supplyOutletNode)
    setpoint_manager_scheduled.addToNode(plant_loop.supplyOutletNode)
    plant_loop.addDemandBranchForComponent(pipe_demand_bypass)
    pipe_demand_inlet.addToNode(plant_loop.demandInletNode)
    pipe_demand_outlet.addToNode(plant_loop.demandOutletNode)
    
    num_units = Geometry.get_num_units(model, runner)
    if num_units.nil?
        return false
    end
    
    (1..num_units).to_a.each do |unit_num|
      _nbeds, _nbaths, unit_spaces = Geometry.get_unit_beds_baths_spaces(model, unit_num, runner)
      thermal_zones = Geometry.get_thermal_zones_from_spaces(unit_spaces)
      if thermal_zones.length > 1
        runner.registerInfo("Unit #{unit_num} spans more than one thermal zone.")
      end
      control_slave_zones_hash = HVAC.get_control_and_slave_zones(thermal_zones)
      control_slave_zones_hash.each do |control_zone, slave_zones|

        # Remove existing equipment
        HVAC.remove_existing_hvac_equipment(model, runner, "Boiler", control_zone)
      
        baseboard_coil = OpenStudio::Model::CoilHeatingWaterBaseboard.new(model)
        baseboard_coil.setName("Living Water Baseboard Coil")
        if boilerOutputCapacity != Constants.SizingAuto
          bb_UA = OpenStudio::convert(boilerOutputCapacity,"Btu/h","W").get / (OpenStudio::convert(boilerDesignTemp - 10.0 - 95.0,"R","K").get) * 3
          bb_max_flow = OpenStudio::convert(boilerOutputCapacity,"Btu/h","W").get / OpenStudio::convert(20.0,"R","K").get / 4.186 / 998.2 / 1000 * 2.0    
          baseboard_coil.setUFactorTimesAreaValue(bb_UA)
          baseboard_coil.setMaximumWaterFlowRate(bb_max_flow)      
        end
        baseboard_coil.setConvergenceTolerance(0.001)
        
        living_baseboard_heater = OpenStudio::Model::ZoneHVACBaseboardConvectiveWater.new(model, model.alwaysOnDiscreteSchedule, baseboard_coil)
        living_baseboard_heater.setName("Living Zone Baseboards")
        living_baseboard_heater.addToThermalZone(control_zone)
        runner.registerInfo("Added baseboard convective water '#{living_baseboard_heater.name}' to thermal zone '#{control_zone.name}' of unit #{unit_num}")
        
        plant_loop.addDemandBranchForComponent(baseboard_coil)
        
        slave_zones.each do |slave_zone|

          # Remove existing equipment
          HVAC.remove_existing_hvac_equipment(model, runner, "Boiler", slave_zone)       
        
          baseboard_coil = OpenStudio::Model::CoilHeatingWaterBaseboard.new(model)
          baseboard_coil.setName("FBsmt Water Baseboard Coil")
          if boilerOutputCapacity != Constants.SizingAuto
            bb_UA = OpenStudio::convert(boilerOutputCapacity,"Btu/h","W").get / (OpenStudio::convert(boilerDesignTemp - 10.0 - 95.0,"R","K").get) * 3
            bb_max_flow = OpenStudio::convert(boilerOutputCapacity,"Btu/h","W").get / OpenStudio::convert(20.0,"R","K").get / 4.186 / 998.2 / 1000 * 2.0    
            baseboard_coil.setUFactorTimesAreaValue(bb_UA)
            baseboard_coil.setMaximumWaterFlowRate(bb_max_flow)      
          end
          baseboard_coil.setConvergenceTolerance(0.001)
        
          fbasement_baseboard_heater = OpenStudio::Model::ZoneHVACBaseboardConvectiveWater.new(model, model.alwaysOnDiscreteSchedule, baseboard_coil)
          fbasement_baseboard_heater.setName("FBsmt Zone Baseboards")
          fbasement_baseboard_heater.addToThermalZone(slave_zone)
          runner.registerInfo("Added baseboard convective water '#{fbasement_baseboard_heater.name}' to thermal zone '#{slave_zone.name}' of unit #{unit_num}")
          
          plant_loop.addDemandBranchForComponent(baseboard_coil)

        end
      
      end
      
    end
    
    return true

  end
  
  def get_boiler_hir(boilerInstalledAFUE)
    # Based on DOE2 Volume 5 Compliance Analysis manual. 
    # This is not used until we have a better way of disaggregating AFUE
    # if BoilerInstalledAFUE < 0.8 and BoilerInstalledAFUE >= 0.75:
    #     hir = 1 / (0.1 * BoilerInstalledAFUE + 0.725)
    # elif BoilerInstalledAFUE >= 0.8:
    #     hir = 1 / (0.875 * BoilerInstalledAFUE + 0.105)
    # else:
    #     hir = 1 / BoilerInstalledAFUE
    hir = 1.0 / boilerInstalledAFUE
    return hir
  end
  
  def _processCurvesBoiler(model, runner, hasBoilerCondensing)
    if hasBoilerCondensing
      condensing_boiler_eff = OpenStudio::Model::CurveBiquadratic.new(model)
      condensing_boiler_eff.setName("CondensingBoilerEff")
      condensing_boiler_eff.setCoefficient1Constant(1.058343061)
      condensing_boiler_eff.setCoefficient2x(-0.052650153)
      condensing_boiler_eff.setCoefficient3xPOW2(-0.0087272)
      condensing_boiler_eff.setCoefficient4y(-0.001742217)
      condensing_boiler_eff.setCoefficient5yPOW2(0.00000333715)
      condensing_boiler_eff.setCoefficient6xTIMESY(0.000513723)
      condensing_boiler_eff.setMinimumValueofx(0.2)
      condensing_boiler_eff.setMaximumValueofx(1.0)
      condensing_boiler_eff.setMinimumValueofy(30.0)
      condensing_boiler_eff.setMaximumValueofy(85.0)
      return condensing_boiler_eff
    else
      non_condensing_boiler_eff = OpenStudio::Model::CurveBicubic.new(model)
      non_condensing_boiler_eff.setName("NonCondensingBoilerEff")
      non_condensing_boiler_eff.setCoefficient1Constant(1.111720116)
      non_condensing_boiler_eff.setCoefficient2x(0.078614078)
      non_condensing_boiler_eff.setCoefficient3xPOW2(-0.400425756)
      non_condensing_boiler_eff.setCoefficient4y(0.0)
      non_condensing_boiler_eff.setCoefficient5yPOW2(-0.000156783)
      non_condensing_boiler_eff.setCoefficient6xTIMESY(0.009384599)
      non_condensing_boiler_eff.setCoefficient7xPOW3(0.234257955)
      non_condensing_boiler_eff.setCoefficient8yPOW3(1.32927e-06)
      non_condensing_boiler_eff.setCoefficient9xPOW2TIMESY(-0.004446701)
      non_condensing_boiler_eff.setCoefficient10xTIMESYPOW2(-1.22498e-05)
      non_condensing_boiler_eff.setMinimumValueofx(0.1)
      non_condensing_boiler_eff.setMaximumValueofx(1.0)
      non_condensing_boiler_eff.setMinimumValueofy(20.0)
      non_condensing_boiler_eff.setMaximumValueofy(80.0)
      return non_condensing_boiler_eff
    end
    
  end
  
end

# register the measure to be used by the application
ProcessBoiler.new.registerWithApplication
