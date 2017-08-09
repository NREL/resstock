# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"
require "#{File.dirname(__FILE__)}/resources/hvac"

# start the measure
class ProcessBoilerElectric < OpenStudio::Measure::ModelMeasure

  # human readable name
  def name
    return "Set Residential Boiler Electric"
  end

  # human readable description
  def description
    return "This measure removes any existing HVAC heating components from the building and adds a boiler along with constant speed pump and water baseboard coils to a hot water plant loop. For multifamily buildings, the supply components on the plant loop can be set for all units of the building.#{Constants.WorkflowDescription}"
  end

  # human readable description of modeling approach
  def modeler_description
    return "Any heating components or baseboard convective electrics/waters are removed from any existing air/plant loops or zones. A boiler along with constant speed pump and water baseboard coils are added to a hot water plant loop."
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new
    
    #make a string argument for boiler system type
    boiler_display_names = OpenStudio::StringVector.new
    boiler_display_names << Constants.BoilerTypeForcedDraft
    boiler_display_names << Constants.BoilerTypeCondensing
    boiler_display_names << Constants.BoilerTypeNaturalDraft
    boiler_display_names << Constants.BoilerTypeSteam
    boilerType = OpenStudio::Measure::OSArgument::makeChoiceArgument("system_type", boiler_display_names, true)
    boilerType.setDisplayName("System Type")
    boilerType.setDescription("The system type of the boiler.")
    boilerType.setDefaultValue(Constants.BoilerTypeForcedDraft)
    args << boilerType
    
    #make an argument for entering boiler installed afue
    boilerInstalledAFUE = OpenStudio::Measure::OSArgument::makeDoubleArgument("afue",true)
    boilerInstalledAFUE.setDisplayName("Installed AFUE")
    boilerInstalledAFUE.setUnits("Btu/Btu")
    boilerInstalledAFUE.setDescription("The installed Annual Fuel Utilization Efficiency (AFUE) of the boiler, which can be used to account for performance derating or degradation relative to the rated value.")
    boilerInstalledAFUE.setDefaultValue(1.0)
    args << boilerInstalledAFUE
    
    #make a bool argument for whether the boiler OAT enabled
    boilerOATResetEnabled = OpenStudio::Measure::OSArgument::makeBoolArgument("oat_reset_enabled", true)
    boilerOATResetEnabled.setDisplayName("Outside Air Reset Enabled")
    boilerOATResetEnabled.setDescription("Outside Air Reset Enabled on Hot Water Supply Temperature.")
    boilerOATResetEnabled.setDefaultValue(false)
    args << boilerOATResetEnabled    
    
    #make an argument for entering boiler OAT high
    boilerOATHigh = OpenStudio::Measure::OSArgument::makeDoubleArgument("oat_high",false)
    boilerOATHigh.setDisplayName("High Outside Air Temp")
    boilerOATHigh.setUnits("degrees F")
    boilerOATHigh.setDescription("High Outside Air Temperature.")
    args << boilerOATHigh    
    
    #make an argument for entering boiler OAT low
    boilerOATLow = OpenStudio::Measure::OSArgument::makeDoubleArgument("oat_low",false)
    boilerOATLow.setDisplayName("Low Outside Air Temp")
    boilerOATLow.setUnits("degrees F")
    boilerOATLow.setDescription("Low Outside Air Temperature.")
    args << boilerOATLow
    
    #make an argument for entering boiler OAT high HWST
    boilerOATHighHWST = OpenStudio::Measure::OSArgument::makeDoubleArgument("oat_hwst_high",false)
    boilerOATHighHWST.setDisplayName("Hot Water Supply Temp High Outside Air")
    boilerOATHighHWST.setUnits("degrees F")
    boilerOATHighHWST.setDescription("Hot Water Supply Temperature corresponding to High Outside Air Temperature.")
    args << boilerOATHighHWST
    
    #make an argument for entering boiler OAT low HWST
    boilerOATLowHWST = OpenStudio::Measure::OSArgument::makeDoubleArgument("oat_hwst_low",false)
    boilerOATLowHWST.setDisplayName("Hot Water Supply Temp Low Outside Air")
    boilerOATLowHWST.setUnits("degrees F")
    boilerOATLowHWST.setDescription("Hot Water Supply Temperature corresponding to Low Outside Air Temperature.")
    args << boilerOATLowHWST        
    
    #make an argument for entering boiler design temp
    boilerDesignTemp = OpenStudio::Measure::OSArgument::makeDoubleArgument("design_temp",false)
    boilerDesignTemp.setDisplayName("Design Temperature")
    boilerDesignTemp.setUnits("degrees F")
    boilerDesignTemp.setDescription("Temperature of the outlet water.")
    boilerDesignTemp.setDefaultValue(180.0)
    args << boilerDesignTemp     
    
    #make a string argument for furnace heating output capacity
    boilerOutputCapacity = OpenStudio::Measure::OSArgument::makeStringArgument("capacity", true)
    boilerOutputCapacity.setDisplayName("Heating Capacity")
    boilerOutputCapacity.setDescription("The output heating capacity of the boiler. If using '#{Constants.SizingAuto}', the autosizing algorithm will use ACCA Manual S to set the capacity.")
    boilerOutputCapacity.setUnits("kBtu/hr")
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
    
    boilerType = runner.getStringArgumentValue("system_type",user_arguments)
    boilerInstalledAFUE = runner.getDoubleArgumentValue("afue",user_arguments)
    boilerOATResetEnabled = runner.getBoolArgumentValue("oat_reset_enabled",user_arguments)    
    boilerOATHigh = runner.getOptionalDoubleArgumentValue("oat_high", user_arguments)
    boilerOATHigh.is_initialized ? boilerOATHigh = boilerOATHigh.get : boilerOATHigh = nil    
    boilerOATLow = runner.getOptionalDoubleArgumentValue("oat_low", user_arguments)
    boilerOATLow.is_initialized ? boilerOATLow = boilerOATLow.get : boilerOATLow = nil     
    boilerOATHighHWST = runner.getOptionalDoubleArgumentValue("oat_hwst_high", user_arguments)
    boilerOATHighHWST.is_initialized ? boilerOATHighHWST = boilerOATHighHWST.get : boilerOATHighHWST = nil
    boilerOATLowHWST = runner.getOptionalDoubleArgumentValue("oat_hwst_low", user_arguments)
    boilerOATLowHWST.is_initialized ? boilerOATLowHWST = boilerOATLowHWST.get : boilerOATLowHWST = nil      
    boilerOutputCapacity = runner.getStringArgumentValue("capacity",user_arguments)
    if not boilerOutputCapacity == Constants.SizingAuto
      boilerOutputCapacity = OpenStudio::convert(boilerOutputCapacity.to_f,"kBtu/h","Btu/h").get
    end
    boilerDesignTemp = runner.getDoubleArgumentValue("design_temp",user_arguments)
    
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
    boiler_aux = 0.0 # W during operation
    
    # _processCurvesBoiler
    
    boiler_eff_curve = HVAC.get_boiler_curve(model, hasBoilerCondensing)
    
    # Remove boiler hot water loop if it exists
    HVAC.remove_boiler_and_gshp_loops(model, runner)
    
    # _processSystemHydronic
    
    plant_loop = OpenStudio::Model::PlantLoop.new(model)
    plant_loop.setName(Constants.ObjectNameBoiler(Constants.FuelTypeElectric) + " hydronic heat loop")
    plant_loop.setFluidType("Water")
    plant_loop.setMaximumLoopTemperature(100)
    plant_loop.setMinimumLoopTemperature(0)
    plant_loop.setMinimumLoopFlowRate(0)
    plant_loop.autocalculatePlantLoopVolume()
    
    loop_sizing = plant_loop.sizingPlant
    loop_sizing.setLoopType("Heating")
    loop_sizing.setDesignLoopExitTemperature(OpenStudio::convert(boilerDesignTemp - 32.0,"R","K").get)
    loop_sizing.setLoopDesignTemperatureDifference(OpenStudio::convert(20.0,"R","K").get)
    
    pump = OpenStudio::Model::PumpVariableSpeed.new(model)
    pump.setName(Constants.ObjectNameBoiler(Constants.FuelTypeElectric) + " hydronic pump")
    pump.setRatedPumpHead(179352)
    pump.setMotorEfficiency(0.9)
    pump.setFractionofMotorInefficienciestoFluidStream(0)
    pump.setCoefficient1ofthePartLoadPerformanceCurve(0)
    pump.setCoefficient2ofthePartLoadPerformanceCurve(1)
    pump.setCoefficient3ofthePartLoadPerformanceCurve(0)
    pump.setCoefficient4ofthePartLoadPerformanceCurve(0)
    pump.setPumpControlType("Intermittent")
        
    boiler = OpenStudio::Model::BoilerHotWater.new(model)
    boiler.setName(Constants.ObjectNameBoiler(Constants.FuelTypeElectric))
    boiler.setFuelType(HelperMethods.eplus_fuel_map(Constants.FuelTypeElectric))
    if boilerOutputCapacity != Constants.SizingAuto
      boiler.setNominalCapacity(OpenStudio::convert(boilerOutputCapacity,"Btu/h","W").get) # Used by HVACSizing measure
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
      setpoint_manager_oar.setName(Constants.ObjectNameBoiler(Constants.FuelTypeElectric) + " outdoor reset")
      setpoint_manager_oar.setControlVariable("Temperature")
      setpoint_manager_oar.setSetpointatOutdoorLowTemperature(OpenStudio::convert(boilerOATLowHWST,"F","C").get)
      setpoint_manager_oar.setOutdoorLowTemperature(OpenStudio::convert(boilerOATLow,"F","C").get)
      setpoint_manager_oar.setSetpointatOutdoorHighTemperature(OpenStudio::convert(boilerOATHighHWST,"F","C").get)
      setpoint_manager_oar.setOutdoorHighTemperature(OpenStudio::convert(boilerOATHigh,"F","C").get)
      setpoint_manager_oar.addToNode(plant_loop.supplyOutletNode)      
    end
    
    hydronic_heat_supply_setpoint = OpenStudio::Model::ScheduleConstant.new(model)
    hydronic_heat_supply_setpoint.setName(Constants.ObjectNameBoiler(Constants.FuelTypeElectric) + " hydronic heat supply setpoint")
    hydronic_heat_supply_setpoint.setValue(OpenStudio::convert(boilerDesignTemp,"F","C").get)    
    
    setpoint_manager_scheduled = OpenStudio::Model::SetpointManagerScheduled.new(model, hydronic_heat_supply_setpoint)
    setpoint_manager_scheduled.setName(Constants.ObjectNameBoiler(Constants.FuelTypeElectric) + " hydronic heat loop setpoint manager")
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
    
    # Get building units
    units = Geometry.get_building_units(model, runner)
    if units.nil?
        return false
    end
    
    units.each do |unit|
      
      obj_name = Constants.ObjectNameBoiler(Constants.FuelTypeElectric, unit.name.to_s)

      thermal_zones = Geometry.get_thermal_zones_from_spaces(unit.spaces)

      control_slave_zones_hash = HVAC.get_control_and_slave_zones(thermal_zones)
      control_slave_zones_hash.each do |control_zone, slave_zones|

        # Remove existing equipment
        HVAC.remove_existing_hvac_equipment(model, runner, Constants.ObjectNameBoiler, control_zone)
      
        baseboard_coil = OpenStudio::Model::CoilHeatingWaterBaseboard.new(model)
        baseboard_coil.setName(obj_name + " #{control_zone.name} heating coil")
        if boilerOutputCapacity != Constants.SizingAuto
          baseboard_coil.setHeatingDesignCapacity(OpenStudio::convert(boilerOutputCapacity,"Btu/h","W").get) # Used by HVACSizing measure
        end
        baseboard_coil.setConvergenceTolerance(0.001)
        
        living_baseboard_heater = OpenStudio::Model::ZoneHVACBaseboardConvectiveWater.new(model, model.alwaysOnDiscreteSchedule, baseboard_coil)
        living_baseboard_heater.setName(obj_name + " #{control_zone.name} convective water")
        living_baseboard_heater.addToThermalZone(control_zone)
        runner.registerInfo("Added '#{living_baseboard_heater.name}' to '#{control_zone.name}' of #{unit.name}")
        
        HVAC.prioritize_zone_hvac(model, runner, control_zone).reverse.each do |object|
          control_zone.setCoolingPriority(object, 1)
          control_zone.setHeatingPriority(object, 1)
        end
        
        plant_loop.addDemandBranchForComponent(baseboard_coil)
        
        slave_zones.each do |slave_zone|

          # Remove existing equipment
          HVAC.remove_existing_hvac_equipment(model, runner, Constants.ObjectNameBoiler, slave_zone)       
        
          baseboard_coil = OpenStudio::Model::CoilHeatingWaterBaseboard.new(model)
          baseboard_coil.setName(obj_name + " #{slave_zone.name} heating coil")
          if boilerOutputCapacity != Constants.SizingAuto
            baseboard_coil.setHeatingDesignCapacity(OpenStudio::convert(boilerOutputCapacity,"Btu/h","W").get) # Used by HVACSizing measure
          end
          baseboard_coil.setConvergenceTolerance(0.001)
        
          fbasement_baseboard_heater = OpenStudio::Model::ZoneHVACBaseboardConvectiveWater.new(model, model.alwaysOnDiscreteSchedule, baseboard_coil)
          fbasement_baseboard_heater.setName(obj_name + " #{slave_zone.name} convective water")
          fbasement_baseboard_heater.addToThermalZone(slave_zone)
          runner.registerInfo("Added '#{fbasement_baseboard_heater.name}' to '#{slave_zone.name}' of #{unit.name}")
          
          HVAC.prioritize_zone_hvac(model, runner, slave_zone).reverse.each do |object|
            slave_zone.setCoolingPriority(object, 1)
            slave_zone.setHeatingPriority(object, 1)
          end          
          
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
  
end

# register the measure to be used by the application
ProcessBoilerElectric.new.registerWithApplication