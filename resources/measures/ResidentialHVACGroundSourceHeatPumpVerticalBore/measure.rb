# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"
require "#{File.dirname(__FILE__)}/resources/hvac"
require "#{File.dirname(__FILE__)}/resources/weather"

# start the measure
class ProcessGroundSourceHeatPumpVerticalBore < OpenStudio::Measure::ModelMeasure

  # human readable name
  def name
    return "Set Residential Ground Source Heat Pump Vertical Bore"
  end

  # human readable description
  def description
    return "This measure removes any existing HVAC components from the building and adds a ground heat exchanger along with variable speed pump and water to air heat pump coils to a condenser plant loop. For multifamily buildings, the supply components on the plant loop can be set for all units of the building.#{Constants.WorkflowDescription}"
  end

  # human readable description of modeling approach
  def modeler_description
    return "Any supply components or baseboard convective electrics/waters are removed from any existing air/plant loops or zones. A ground heat exchanger along with variable speed pump and water to air heat pump coils are added to a condenser plant loop."
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    #make a double argument for gshp vert bore cop
    cop = OpenStudio::Measure::OSArgument::makeDoubleArgument("cop", true)
    cop.setDisplayName("COP")
    cop.setUnits("W/W")
    cop.setDescription("User can use AHRI/ASHRAE ISO 13556-1 rated EER value and convert it to EIR here.")
    cop.setDefaultValue(3.6)
    args << cop
    
    #make a double argument for gshp vert bore eer
    eer = OpenStudio::Measure::OSArgument::makeDoubleArgument("eer", true)
    eer.setDisplayName("EER")
    eer.setUnits("Btu/W-h")
    eer.setDescription("This is a measure of the instantaneous energy efficiency of cooling equipment.")
    eer.setDefaultValue(16.6)
    args << eer
    
    #make a double argument for gshp vert bore rated shr
    shr = OpenStudio::Measure::OSArgument::makeDoubleArgument("shr", true)
    shr.setDisplayName("Rated SHR")
    shr.setDescription("The sensible heat ratio (ratio of the sensible portion of the load to the total load) at the nominal rated capacity.")
    shr.setDefaultValue(0.732)
    args << shr
    
    #make a double argument for gshp vert bore ground conductivity
    ground_conductivity = OpenStudio::Measure::OSArgument::makeDoubleArgument("ground_conductivity", true)
    ground_conductivity.setDisplayName("Ground Conductivity")
    ground_conductivity.setUnits("Btu/hr-ft-R")
    ground_conductivity.setDescription("Conductivity of the ground into which the ground heat exchangers are installed.")
    ground_conductivity.setDefaultValue(0.6)
    args << ground_conductivity
    
    #make a double argument for gshp vert bore grout conductivity
    grout_conductivity = OpenStudio::Measure::OSArgument::makeDoubleArgument("grout_conductivity", true)
    grout_conductivity.setDisplayName("Grout Conductivity")
    grout_conductivity.setUnits("Btu/hr-ft-R")
    grout_conductivity.setDescription("Grout is used to enhance heat transfer between the pipe and the ground.")
    grout_conductivity.setDefaultValue(0.4)
    args << grout_conductivity
    
    #make a string argument for gshp vert bore configuration
    config_display_names = OpenStudio::StringVector.new
    config_display_names << Constants.SizingAuto
    config_display_names << Constants.BoreConfigSingle
    config_display_names << Constants.BoreConfigLine
    config_display_names << Constants.BoreConfigRectangle
    config_display_names << Constants.BoreConfigLconfig
    config_display_names << Constants.BoreConfigL2config
    config_display_names << Constants.BoreConfigUconfig
    bore_config = OpenStudio::Measure::OSArgument::makeChoiceArgument("bore_config", config_display_names, true)
    bore_config.setDisplayName("Bore Configuration")
    bore_config.setDescription("Different types of vertical bore configuration results in different G-functions which captures the thermal response of a bore field.")
    bore_config.setDefaultValue(Constants.SizingAuto)
    args << bore_config
    
    #make a string argument for gshp vert bore holes
    holes_display_names = OpenStudio::StringVector.new
    holes_display_names << Constants.SizingAuto
    (1..10).to_a.each do |holes|
      holes_display_names << "#{holes}"
    end 
    bore_holes = OpenStudio::Measure::OSArgument::makeChoiceArgument("bore_holes", holes_display_names, true)
    bore_holes.setDisplayName("Number of Bore Holes")
    bore_holes.setDescription("Number of vertical bores.")
    bore_holes.setDefaultValue(Constants.SizingAuto)
    args << bore_holes

    #make a string argument for gshp bore depth
    bore_depth = OpenStudio::Measure::OSArgument::makeStringArgument("bore_depth", true)
    bore_depth.setDisplayName("Bore Depth")
    bore_depth.setUnits("ft")
    bore_depth.setDescription("Vertical well bore depth typically range from 150 to 300 feet deep.")
    bore_depth.setDefaultValue(Constants.SizingAuto)
    args << bore_depth    
    
    #make a double argument for gshp vert bore spacing
    bore_spacing = OpenStudio::Measure::OSArgument::makeDoubleArgument("bore_spacing", true)
    bore_spacing.setDisplayName("Bore Spacing")
    bore_spacing.setUnits("ft")
    bore_spacing.setDescription("Bore holes are typically spaced 15 to 20 feet apart.")
    bore_spacing.setDefaultValue(20.0)
    args << bore_spacing
    
    #make a double argument for gshp vert bore diameter
    bore_diameter = OpenStudio::Measure::OSArgument::makeDoubleArgument("bore_diameter", true)
    bore_diameter.setDisplayName("Bore Diameter")
    bore_diameter.setUnits("in")
    bore_diameter.setDescription("Bore hole diameter.")
    bore_diameter.setDefaultValue(5.0)
    args << bore_diameter
    
    #make a double argument for gshp vert bore nominal pipe size
    pipe_size = OpenStudio::Measure::OSArgument::makeDoubleArgument("pipe_size", true)
    pipe_size.setDisplayName("Nominal Pipe Size")
    pipe_size.setUnits("in")
    pipe_size.setDescription("Pipe nominal size.")
    pipe_size.setDefaultValue(0.75)
    args << pipe_size
    
    #make a double argument for gshp vert bore ground diffusivity
    ground_diffusivity = OpenStudio::Measure::OSArgument::makeDoubleArgument("ground_diffusivity", true)
    ground_diffusivity.setDisplayName("Ground Diffusivity")
    ground_diffusivity.setUnits("ft^2/hr")
    ground_diffusivity.setDescription("A measure of thermal inertia, the ground diffusivity is the thermal conductivity divided by density and specific heat capacity.")
    ground_diffusivity.setDefaultValue(0.0208)
    args << ground_diffusivity

    #make a string argument for gshp bore fluid type
    fluid_display_names = OpenStudio::StringVector.new
    fluid_display_names << Constants.FluidPropyleneGlycol
    fluid_display_names << Constants.FluidEthyleneGlycol
    fluid_type = OpenStudio::Measure::OSArgument::makeChoiceArgument("fluid_type", fluid_display_names, true)
    fluid_type.setDisplayName("Heat Exchanger Fluid Type")
    fluid_type.setDescription("Fluid type.")
    fluid_type.setDefaultValue(Constants.FluidPropyleneGlycol)
    args << fluid_type
    
    #make a double argument for gshp vert bore frac glycol
    frac_glycol = OpenStudio::Measure::OSArgument::makeDoubleArgument("frac_glycol", true)
    frac_glycol.setDisplayName("Fraction Glycol")
    frac_glycol.setUnits("frac")
    frac_glycol.setDescription("Fraction of glycol, 0 indicates water.")
    frac_glycol.setDefaultValue(0.3)
    args << frac_glycol
    
    #make a double argument for gshp vert bore ground loop design delta temp
    design_delta_t = OpenStudio::Measure::OSArgument::makeDoubleArgument("design_delta_t", true)
    design_delta_t.setDisplayName("Ground Loop Design Delta Temp")
    design_delta_t.setUnits("deg F")
    design_delta_t.setDescription("Ground loop design temperature difference.")
    design_delta_t.setDefaultValue(10.0)
    args << design_delta_t
    
    #make a double argument for gshp vert bore pump head
    pump_head = OpenStudio::Measure::OSArgument::makeDoubleArgument("pump_head", true)
    pump_head.setDisplayName("Pump Head")
    pump_head.setUnits("ft of water")
    pump_head.setDescription("Feet of water column.")
    pump_head.setDefaultValue(50.0)
    args << pump_head
    
    #make a double argument for gshp vert bore u tube leg sep
    u_tube_leg_spacing = OpenStudio::Measure::OSArgument::makeDoubleArgument("u_tube_leg_spacing", true)
    u_tube_leg_spacing.setDisplayName("U Tube Leg Separation")
    u_tube_leg_spacing.setUnits("in")
    u_tube_leg_spacing.setDescription("U-tube leg spacing.")
    u_tube_leg_spacing.setDefaultValue(0.9661)
    args << u_tube_leg_spacing
    
    #make a choice argument for gshp vert bore u tube spacing type
    spacing_type_names = OpenStudio::StringVector.new
    spacing_type_names << "as"
    spacing_type_names << "b"
    spacing_type_names << "c"
    u_tube_spacing_type = OpenStudio::Measure::OSArgument::makeChoiceArgument("u_tube_spacing_type", spacing_type_names, true)
    u_tube_spacing_type.setDisplayName("U Tube Spacing Type")
    u_tube_spacing_type.setDescription("U-tube shank spacing type. Type B, for 5\" bore is equivalent to 0.9661\" shank spacing. Type C is the type where the U tube legs are furthest apart.")
    u_tube_spacing_type.setDefaultValue("b")
    args << u_tube_spacing_type
    
    #make a double argument for gshp vert bore supply fan power
    fan_power = OpenStudio::Measure::OSArgument::makeDoubleArgument("fan_power", true)
    fan_power.setDisplayName("Supply Fan Power")
    fan_power.setUnits("W/cfm")
    fan_power.setDescription("Fan power (in W) per delivered airflow rate (in cfm) of the indoor fan.")
    fan_power.setDefaultValue(0.5)
    args << fan_power    
    
    #make a string argument for gshp heating/cooling output capacity
    heat_pump_capacity = OpenStudio::Measure::OSArgument::makeStringArgument("heat_pump_capacity", true)
    heat_pump_capacity.setDisplayName("Heat Pump Capacity")
    heat_pump_capacity.setDescription("The output heating/cooling capacity of the heat pump.")
    heat_pump_capacity.setUnits("tons")
    heat_pump_capacity.setDefaultValue(Constants.SizingAuto)
    args << heat_pump_capacity    
    
    #make an argument for entering supplemental efficiency
    supplemental_efficiency = OpenStudio::Measure::OSArgument::makeDoubleArgument("supplemental_efficiency",true)
    supplemental_efficiency.setDisplayName("Supplemental Efficiency")
    supplemental_efficiency.setUnits("Btu/Btu")
    supplemental_efficiency.setDescription("The efficiency of the supplemental electric coil.")
    supplemental_efficiency.setDefaultValue(1.0)
    args << supplemental_efficiency
    
    #make a string argument for supplemental heating output capacity
    supplemental_capacity = OpenStudio::Measure::OSArgument::makeStringArgument("supplemental_capacity", true)
    supplemental_capacity.setDisplayName("Supplemental Heating Capacity")
    supplemental_capacity.setDescription("The output heating capacity of the supplemental heater.")
    supplemental_capacity.setUnits("kBtu/hr")
    supplemental_capacity.setDefaultValue(Constants.SizingAuto)
    args << supplemental_capacity   

    #make a string argument for distribution system efficiency
    dse = OpenStudio::Measure::OSArgument::makeStringArgument("dse", true)
    dse.setDisplayName("Distribution System Efficiency")
    dse.setDescription("Defines the energy losses associated with the delivery of energy from the equipment to the source of the load.")
    dse.setDefaultValue("NA")
    args << dse        
    
    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    cop = runner.getDoubleArgumentValue("cop",user_arguments)
    eer = runner.getDoubleArgumentValue("eer",user_arguments)
    shr = runner.getDoubleArgumentValue("shr",user_arguments)
    ground_conductivity = runner.getDoubleArgumentValue("ground_conductivity",user_arguments)
    grout_conductivity = runner.getDoubleArgumentValue("grout_conductivity",user_arguments)
    bore_config = runner.getStringArgumentValue("bore_config",user_arguments)
    bore_holes = runner.getStringArgumentValue("bore_holes",user_arguments)
    bore_depth = runner.getStringArgumentValue("bore_depth",user_arguments)
    bore_spacing = runner.getDoubleArgumentValue("bore_spacing",user_arguments)
    bore_diameter = runner.getDoubleArgumentValue("bore_diameter",user_arguments)
    pipe_size = runner.getDoubleArgumentValue("pipe_size",user_arguments)
    ground_diffusivity = runner.getDoubleArgumentValue("ground_diffusivity",user_arguments)
    fluid_type = runner.getStringArgumentValue("fluid_type",user_arguments)
    frac_glycol = runner.getDoubleArgumentValue("frac_glycol",user_arguments)
    design_delta_t = runner.getDoubleArgumentValue("design_delta_t",user_arguments)
    pump_head = UnitConversions.convert(UnitConversions.convert(runner.getDoubleArgumentValue("pump_head",user_arguments),"ft","in"),"inH2O","Pa") # convert from ft H20 to Pascal
    u_tube_leg_spacing = runner.getDoubleArgumentValue("u_tube_leg_spacing",user_arguments)
    u_tube_spacing_type = runner.getStringArgumentValue("u_tube_spacing_type",user_arguments)
    fan_power = runner.getDoubleArgumentValue("fan_power",user_arguments)
    heat_pump_capacity = runner.getStringArgumentValue("heat_pump_capacity",user_arguments)
    unless heat_pump_capacity == Constants.SizingAuto
      heat_pump_capacity = UnitConversions.convert(heat_pump_capacity.to_f,"ton","Btu/hr")
    end
    supplemental_efficiency = runner.getDoubleArgumentValue("supplemental_efficiency",user_arguments)
    supplemental_capacity = runner.getStringArgumentValue("supplemental_capacity",user_arguments)
    unless supplemental_capacity == Constants.SizingAuto
      supplemental_capacity = UnitConversions.convert(supplemental_capacity.to_f,"kBtu/hr","Btu/hr")
    end
    dse = runner.getStringArgumentValue("dse",user_arguments)
    if dse.to_f > 0
      dse = dse.to_f
    else
      dse = 1.0
    end
    
    # Ground Loop And Loop Pump
    weather = WeatherProcess.new(model, runner, File.dirname(__FILE__))
    if weather.error?
      return false
    end    
    
<<<<<<< HEAD
    chw_design = get_gshp_HXCHWDesign(weather)
    hw_design = get_gshp_HXHWDesign(weather, fluid_type)

    # Cooling Coil
    cOOL_CAP_FT_SPEC = [0.39039063, 0.01382596, 0.00000000, -0.00445738, 0.00000000, 0.00000000]
    cOOL_SH_FT_SPEC = [4.27136253, -0.04678521, 0.00000000, -0.00219031, 0.00000000, 0.00000000]
    cOOL_POWER_FT_SPEC = [0.01717338, 0.00316077, 0.00000000, 0.01043792, 0.00000000, 0.00000000]
    cOIL_BF_FT_SPEC = [1.21005458, -0.00664200, 0.00000000, 0.00348246, 0.00000000, 0.00000000]
    coilBF = 0.08060000
    
    # Heating Coil
    hEAT_CAP_FT_SEC = [0.67104926, -0.00210834, 0.00000000, 0.01491424, 0.00000000, 0.00000000]
    hEAT_POWER_FT_SPEC = [-0.46308105, 0.02008988, 0.00000000, 0.00300222, 0.00000000, 0.00000000]
    
    fanKW_Adjust = get_gshp_FanKW_Adjust(UnitConversions.convert(400.0,"Btu/hr","ton"))
    pumpKW_Adjust = get_gshp_PumpKW_Adjust(UnitConversions.convert(3.0,"Btu/hr","ton"))
    coolingEIR = get_gshp_cooling_eir(eer, fanKW_Adjust, pumpKW_Adjust)
    
    # Supply Fan
    static = UnitConversions.convert(0.5,"inH2O","Pa")
    
    # Heating Coil
    heatingEIR = get_gshp_heating_eir(cop, fanKW_Adjust, pumpKW_Adjust)
    min_hp_temp = -30.0
    
=======
>>>>>>> master
    # Get building units
    units = Geometry.get_building_units(model, runner)
    if units.nil?
      return false
    end
    
    units.each do |unit|
    
<<<<<<< HEAD
      obj_name = Constants.ObjectNameGroundSourceHeatPumpVerticalBore(unit.name.to_s)
      
      ground_heat_exch_vert = OpenStudio::Model::GroundHeatExchangerVertical.new(model)
      ground_heat_exch_vert.setName(obj_name + " exchanger")
      ground_heat_exch_vert.setBoreHoleRadius(UnitConversions.convert(bore_diameter/2.0,"in","m"))
      ground_heat_exch_vert.setGroundThermalConductivity(UnitConversions.convert(ground_conductivity,"Btu/(hr*ft*R)","W/(m*K)"))
      ground_heat_exch_vert.setGroundThermalHeatCapacity(UnitConversions.convert(ground_conductivity / ground_diffusivity,"Btu/(ft^3*F)","J/(m^3*K)"))
      ground_heat_exch_vert.setGroundTemperature(UnitConversions.convert(weather.data.AnnualAvgDrybulb,"F","C"))
      ground_heat_exch_vert.setGroutThermalConductivity(UnitConversions.convert(grout_conductivity,"Btu/(hr*ft*R)","W/(m*K)"))
      ground_heat_exch_vert.setPipeThermalConductivity(UnitConversions.convert(pipe_cond,"Btu/(hr*ft*R)","W/(m*K)"))
      ground_heat_exch_vert.setPipeOutDiameter(UnitConversions.convert(pipe_od,"in","m"))
      ground_heat_exch_vert.setUTubeDistance(UnitConversions.convert(leg_separation,"in","m"))
      ground_heat_exch_vert.setPipeThickness(UnitConversions.convert((pipe_od - pipe_id)/2.0,"in","m"))
      ground_heat_exch_vert.setMaximumLengthofSimulation(1)
      ground_heat_exch_vert.setGFunctionReferenceRatio(0.0005)
      
      plant_loop = OpenStudio::Model::PlantLoop.new(model)
      plant_loop.setName(obj_name + " condenser loop")
      if fluid_type == Constants.FluidWater
        plant_loop.setFluidType('Water')
      else
        plant_loop.setFluidType({Constants.FluidPropyleneGlycol=>'PropyleneGlycol', Constants.FluidEthyleneGlycol=>'EthyleneGlycol'}[fluid_type])
        plant_loop.setGlycolConcentration((frac_glycol * 100).to_i)
      end
      plant_loop.setMaximumLoopTemperature(48.88889)
      plant_loop.setMinimumLoopTemperature(UnitConversions.convert(hw_design,"F","C"))
      plant_loop.setMinimumLoopFlowRate(0)
      plant_loop.setLoadDistributionScheme('SequentialLoad')
      runner.registerInfo("Added '#{plant_loop.name}' to model.")
      
      sizing_plant = plant_loop.sizingPlant
      sizing_plant.setLoopType('Condenser')
      sizing_plant.setDesignLoopExitTemperature(UnitConversions.convert(chw_design,"F","C"))
      sizing_plant.setLoopDesignTemperatureDifference(UnitConversions.convert(design_delta_t,"R","K"))
      
      setpoint_mgr_follow_ground_temp = OpenStudio::Model::SetpointManagerFollowGroundTemperature.new(model)
      setpoint_mgr_follow_ground_temp.setName(obj_name + " condenser loop temp")
      setpoint_mgr_follow_ground_temp.setControlVariable('Temperature')
      setpoint_mgr_follow_ground_temp.setMaximumSetpointTemperature(48.88889)
      setpoint_mgr_follow_ground_temp.setMinimumSetpointTemperature(UnitConversions.convert(hw_design,"F","C"))
      setpoint_mgr_follow_ground_temp.setReferenceGroundTemperatureObjectType('Site:GroundTemperature:Deep')
      setpoint_mgr_follow_ground_temp.addToNode(plant_loop.supplyOutletNode)
      
      pump = OpenStudio::Model::PumpVariableSpeed.new(model)
      pump.setName(obj_name + " pump")
      pump.setRatedPumpHead(pump_head)
      pump.setMotorEfficiency(dse * 0.77 * 0.6)
      pump.setFractionofMotorInefficienciestoFluidStream(0)
      pump.setCoefficient1ofthePartLoadPerformanceCurve(0)
      pump.setCoefficient2ofthePartLoadPerformanceCurve(1)
      pump.setCoefficient3ofthePartLoadPerformanceCurve(0)
      pump.setCoefficient4ofthePartLoadPerformanceCurve(0)
      pump.setMinimumFlowRate(0)
      pump.setPumpControlType('Intermittent')
      pump.addToNode(plant_loop.supplyInletNode)
      
      plant_loop.addSupplyBranchForComponent(ground_heat_exch_vert)
      
      chiller_bypass_pipe = OpenStudio::Model::PipeAdiabatic.new(model)
      plant_loop.addSupplyBranchForComponent(chiller_bypass_pipe)
      coil_bypass_pipe = OpenStudio::Model::PipeAdiabatic.new(model)
      plant_loop.addDemandBranchForComponent(coil_bypass_pipe)
      supply_outlet_pipe = OpenStudio::Model::PipeAdiabatic.new(model)
      supply_outlet_pipe.addToNode(plant_loop.supplyOutletNode)    
      demand_inlet_pipe = OpenStudio::Model::PipeAdiabatic.new(model)
      demand_inlet_pipe.addToNode(plant_loop.demandInletNode) 
      demand_outlet_pipe = OpenStudio::Model::PipeAdiabatic.new(model)
      demand_outlet_pipe.addToNode(plant_loop.demandOutletNode)
    
=======
>>>>>>> master
      thermal_zones = Geometry.get_thermal_zones_from_spaces(unit.spaces)
      HVAC.get_control_and_slave_zones(thermal_zones).each do |control_zone, slave_zones|
        ([control_zone] + slave_zones).each do |zone|
          HVAC.remove_hvac_equipment(model, runner, zone, unit,
                                     Constants.ObjectNameGroundSourceHeatPumpVerticalBore)
        end
<<<<<<< HEAD
        htg_coil.setRatedHeatingCoefficientofPerformance(dse / heatingEIR)
        htg_coil.setHeatingCapacityCoefficient1(gshp_HEAT_CAP_fT_coeff[0])
        htg_coil.setHeatingCapacityCoefficient2(gshp_HEAT_CAP_fT_coeff[1])
        htg_coil.setHeatingCapacityCoefficient3(gshp_HEAT_CAP_fT_coeff[2])
        htg_coil.setHeatingCapacityCoefficient4(gshp_HEAT_CAP_fT_coeff[3])
        htg_coil.setHeatingCapacityCoefficient5(gshp_HEAT_CAP_fT_coeff[4])
        htg_coil.setHeatingPowerConsumptionCoefficient1(gshp_HEAT_POWER_fT_coeff[0])
        htg_coil.setHeatingPowerConsumptionCoefficient2(gshp_HEAT_POWER_fT_coeff[1])
        htg_coil.setHeatingPowerConsumptionCoefficient3(gshp_HEAT_POWER_fT_coeff[2])
        htg_coil.setHeatingPowerConsumptionCoefficient4(gshp_HEAT_POWER_fT_coeff[3])
        htg_coil.setHeatingPowerConsumptionCoefficient5(gshp_HEAT_POWER_fT_coeff[4])
        
        plant_loop.addDemandBranchForComponent(htg_coil)
        
        supp_htg_coil = OpenStudio::Model::CoilHeatingElectric.new(model, model.alwaysOnDiscreteSchedule)
        supp_htg_coil.setName(obj_name + " supp heater")
        supp_htg_coil.setEfficiency(dse * supp_eff)
        if supp_capacity != Constants.SizingAuto
          supp_htg_coil.setNominalCapacity(UnitConversions.convert(supp_capacity,"Btu/hr","W")) # Used by HVACSizing measure
        end        
        
        gshp_COOL_CAP_fT_coeff = HVAC.convert_curve_gshp(cOOL_CAP_FT_SPEC, false)
        gshp_COOL_POWER_fT_coeff = HVAC.convert_curve_gshp(cOOL_POWER_FT_SPEC, false)
        gshp_COOL_SH_fT_coeff = HVAC.convert_curve_gshp(cOOL_SH_FT_SPEC, false)
        
        clg_coil = OpenStudio::Model::CoilCoolingWaterToAirHeatPumpEquationFit.new(model)
        clg_coil.setName(obj_name + " cooling coil")
        if gshp_capacity != Constants.SizingAuto
          clg_coil.setRatedTotalCoolingCapacity(UnitConversions.convert(gshp_capacity,"Btu/hr","W")) # Used by HVACSizing measure
        end
        clg_coil.setRatedCoolingCoefficientofPerformance(dse / coolingEIR)
        clg_coil.setTotalCoolingCapacityCoefficient1(gshp_COOL_CAP_fT_coeff[0])
        clg_coil.setTotalCoolingCapacityCoefficient2(gshp_COOL_CAP_fT_coeff[1])
        clg_coil.setTotalCoolingCapacityCoefficient3(gshp_COOL_CAP_fT_coeff[2])
        clg_coil.setTotalCoolingCapacityCoefficient4(gshp_COOL_CAP_fT_coeff[3])
        clg_coil.setTotalCoolingCapacityCoefficient5(gshp_COOL_CAP_fT_coeff[4])
        clg_coil.setSensibleCoolingCapacityCoefficient1(gshp_COOL_SH_fT_coeff[0])
        clg_coil.setSensibleCoolingCapacityCoefficient2(0)
        clg_coil.setSensibleCoolingCapacityCoefficient3(gshp_COOL_SH_fT_coeff[1])
        clg_coil.setSensibleCoolingCapacityCoefficient4(gshp_COOL_SH_fT_coeff[2])
        clg_coil.setSensibleCoolingCapacityCoefficient5(gshp_COOL_SH_fT_coeff[3])
        clg_coil.setSensibleCoolingCapacityCoefficient6(gshp_COOL_SH_fT_coeff[4])
        clg_coil.setCoolingPowerConsumptionCoefficient1(gshp_COOL_POWER_fT_coeff[0])
        clg_coil.setCoolingPowerConsumptionCoefficient2(gshp_COOL_POWER_fT_coeff[1])
        clg_coil.setCoolingPowerConsumptionCoefficient3(gshp_COOL_POWER_fT_coeff[2])
        clg_coil.setCoolingPowerConsumptionCoefficient4(gshp_COOL_POWER_fT_coeff[3])
        clg_coil.setCoolingPowerConsumptionCoefficient5(gshp_COOL_POWER_fT_coeff[4])
        clg_coil.setNominalTimeforCondensateRemovaltoBegin(1000)
        clg_coil.setRatioofInitialMoistureEvaporationRateandSteadyStateLatentCapacity(1.5)
          
        plant_loop.addDemandBranchForComponent(clg_coil)

        fan = OpenStudio::Model::FanOnOff.new(model, model.alwaysOnDiscreteSchedule)
        fan.setName(obj_name + " #{control_zone.name} supply fan")
        fan.setEndUseSubcategory(Constants.EndUseHVACFan)
        fan.setFanEfficiency(dse * HVAC.calculate_fan_efficiency(static, supply_fan_power))
        fan.setPressureRise(static)
        fan.setMotorEfficiency(dse * 1.0)
        fan.setMotorInAirstreamFraction(1.0)
          
        air_loop_unitary = OpenStudio::Model::AirLoopHVACUnitarySystem.new(model)
        air_loop_unitary.setName(obj_name + " unitary system")
        air_loop_unitary.setAvailabilitySchedule(model.alwaysOnDiscreteSchedule)
        air_loop_unitary.setSupplyFan(fan)
        air_loop_unitary.setHeatingCoil(htg_coil)
        air_loop_unitary.setCoolingCoil(clg_coil)
        air_loop_unitary.setSupplementalHeatingCoil(supp_htg_coil)
        air_loop_unitary.setFanPlacement("BlowThrough")
        air_loop_unitary.setSupplyAirFanOperatingModeSchedule(model.alwaysOffDiscreteSchedule)
        air_loop_unitary.setMaximumSupplyAirTemperature(UnitConversions.convert(170.0,"F","C")) # higher temp for supplemental heat as to not severely limit its use, resulting in unmet hours.    
        air_loop_unitary.setMaximumOutdoorDryBulbTemperatureforSupplementalHeaterOperation(UnitConversions.convert(40.0,"F","C"))
        air_loop_unitary.setSupplyAirFlowRateWhenNoCoolingorHeatingisRequired(0)          
          
        air_loop = OpenStudio::Model::AirLoopHVAC.new(model)
        air_loop.setName(obj_name + " central air system")
        air_supply_inlet_node = air_loop.supplyInletNode
        air_supply_outlet_node = air_loop.supplyOutletNode
        air_demand_inlet_node = air_loop.demandInletNode
        air_demand_outlet_node = air_loop.demandOutletNode    
        
        air_loop_unitary.addToNode(air_supply_inlet_node)
        
        runner.registerInfo("Added '#{clg_coil.name}' and '#{htg_coil.name}' to '#{air_loop_unitary.name}' of '#{air_loop.name}'")
        
        air_loop_unitary.setControllingZoneorThermostatLocation(control_zone)
        
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
          HVAC.remove_existing_hvac_equipment(model, runner, Constants.ObjectNameGroundSourceHeatPumpVerticalBore, slave_zone, false, unit)
      
          diffuser_fbsmt = OpenStudio::Model::AirTerminalSingleDuctUncontrolled.new(model, model.alwaysOnDiscreteSchedule)
          diffuser_fbsmt.setName(obj_name + " #{slave_zone.name} direct air")
          air_loop.addBranchForZone(slave_zone, diffuser_fbsmt.to_StraightComponent)

          air_loop.addBranchForZone(slave_zone)
          runner.registerInfo("Added '#{air_loop.name}' to '#{slave_zone.name}' of #{unit.name}")

          HVAC.prioritize_zone_hvac(model, runner, slave_zone)
          
        end        
      
=======
>>>>>>> master
      end
      
      success = HVAC.apply_gshp(model, unit, runner, weather, cop, eer, shr,
                                ground_conductivity, grout_conductivity,
                                bore_config, bore_holes, bore_depth,
                                bore_spacing, bore_diameter, pipe_size,
                                ground_diffusivity, fluid_type, frac_glycol,
                                design_delta_t, pump_head,
                                u_tube_leg_spacing, u_tube_spacing_type,
                                fan_power, heat_pump_capacity, supplemental_efficiency,
                                supplemental_capacity, dse)
      return false if not success
      
    end
    
    return true

  end
  
end

# register the measure to be used by the application
ProcessGroundSourceHeatPumpVerticalBore.new.registerWithApplication
