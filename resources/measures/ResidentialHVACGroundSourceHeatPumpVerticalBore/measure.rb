# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"
require "#{File.dirname(__FILE__)}/resources/hvac"
require "#{File.dirname(__FILE__)}/resources/weather"
require "#{File.dirname(__FILE__)}/resources/unit_conversions"

# start the measure
class ProcessGroundSourceHeatPumpVerticalBore < OpenStudio::Measure::ModelMeasure

  # human readable name
  def name
    return "Set Residential Ground Source Heat Pump Vertical Bore"
  end

  # human readable description
  def description
    return "This measure removes any existing HVAC components from the building and adds a ground heat exchanger along with variable speed pump and water to air heat pump coils to a condenser plant loop. For multifamily buildings, the supply components on the plant loop can be set for all units of the building."
  end

  # human readable description of modeling approach
  def modeler_description
    return "Any supply components or baseboard convective electrics/waters are removed from any existing air/plant loops or zones. A ground heat exchanger along with variable speed pump and water to air heat pump coils are added to a condenser plant loop."
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    #make a double argument for gshp vert bore cop
    gshpVertBoreCOP = OpenStudio::Measure::OSArgument::makeDoubleArgument("cop", true)
    gshpVertBoreCOP.setDisplayName("COP")
    gshpVertBoreCOP.setUnits("W/W")
    gshpVertBoreCOP.setDescription("User can use AHRI/ASHRAE ISO 13556-1 rated EER value and convert it to EIR here.")
    gshpVertBoreCOP.setDefaultValue(3.6)
    args << gshpVertBoreCOP
    
    #make a double argument for gshp vert bore eer
    gshpVertBoreEER = OpenStudio::Measure::OSArgument::makeDoubleArgument("eer", true)
    gshpVertBoreEER.setDisplayName("EER")
    gshpVertBoreEER.setUnits("Btu/W-h")
    gshpVertBoreEER.setDescription("This is a measure of the instantaneous energy efficiency of cooling equipment.")
    gshpVertBoreEER.setDefaultValue(16.6)
    args << gshpVertBoreEER
    
    #make a double argument for gshp vert bore ground conductivity
    gshpVertBoreGroundCond = OpenStudio::Measure::OSArgument::makeDoubleArgument("ground_conductivity", true)
    gshpVertBoreGroundCond.setDisplayName("Ground Conductivity")
    gshpVertBoreGroundCond.setUnits("Btu/hr-ft-R")
    gshpVertBoreGroundCond.setDescription("Conductivity of the ground into which the ground heat exchangers are installed.")
    gshpVertBoreGroundCond.setDefaultValue(0.6)
    args << gshpVertBoreGroundCond
    
    #make a double argument for gshp vert bore grout conductivity
    gshpVertBoreGroutCond = OpenStudio::Measure::OSArgument::makeDoubleArgument("grout_conductivity", true)
    gshpVertBoreGroutCond.setDisplayName("Grout Conductivity")
    gshpVertBoreGroutCond.setUnits("Btu/hr-ft-R")
    gshpVertBoreGroutCond.setDescription("Grout is used to enhance heat transfer between the pipe and the ground.")
    gshpVertBoreGroutCond.setDefaultValue(0.4)
    args << gshpVertBoreGroutCond
    
    #make a string argument for gshp vert bore configuration
    config_display_names = OpenStudio::StringVector.new
    config_display_names << Constants.SizingAuto
    config_display_names << Constants.BoreConfigSingle
    config_display_names << Constants.BoreConfigLine
    config_display_names << Constants.BoreConfigRectangle
    config_display_names << Constants.BoreConfigLconfig
    config_display_names << Constants.BoreConfigL2config
    config_display_names << Constants.BoreConfigUconfig
    gshpVertBoreConfig = OpenStudio::Measure::OSArgument::makeChoiceArgument("bore_config", config_display_names, true)
    gshpVertBoreConfig.setDisplayName("Bore Configuration")
    gshpVertBoreConfig.setDescription("Different types of vertical bore configuration results in different G-functions which captures the thermal response of a bore field.")
    gshpVertBoreConfig.setDefaultValue(Constants.SizingAuto)
    args << gshpVertBoreConfig
    
    #make a string argument for gshp vert bore holes
    holes_display_names = OpenStudio::StringVector.new
    holes_display_names << Constants.SizingAuto
    (1..10).to_a.each do |holes|
      holes_display_names << "#{holes}"
    end 
    gshpVertBoreHoles = OpenStudio::Measure::OSArgument::makeChoiceArgument("bore_holes", holes_display_names, true)
    gshpVertBoreHoles.setDisplayName("Number of Bore Holes")
    gshpVertBoreHoles.setDescription("Number of vertical bores.")
    gshpVertBoreHoles.setDefaultValue(Constants.SizingAuto)
    args << gshpVertBoreHoles

    #make a string argument for gshp bore depth
    gshpVertBoreDepth = OpenStudio::Measure::OSArgument::makeStringArgument("bore_depth", true)
    gshpVertBoreDepth.setDisplayName("Bore Depth")
    gshpVertBoreDepth.setUnits("ft")
    gshpVertBoreDepth.setDescription("Vertical well bore depth typically range from 150 to 300 feet deep.")
    gshpVertBoreDepth.setDefaultValue(Constants.SizingAuto)
    args << gshpVertBoreDepth    
    
    #make a double argument for gshp vert bore spacing
    gshpVertBoreSpacing = OpenStudio::Measure::OSArgument::makeDoubleArgument("bore_spacing", true)
    gshpVertBoreSpacing.setDisplayName("Bore Spacing")
    gshpVertBoreSpacing.setUnits("ft")
    gshpVertBoreSpacing.setDescription("Bore holes are typically spaced 15 to 20 feet apart.")
    gshpVertBoreSpacing.setDefaultValue(20.0)
    args << gshpVertBoreSpacing
    
    #make a double argument for gshp vert bore diameter
    gshpVertBoreDia = OpenStudio::Measure::OSArgument::makeDoubleArgument("bore_diameter", true)
    gshpVertBoreDia.setDisplayName("Bore Diameter")
    gshpVertBoreDia.setUnits("in")
    gshpVertBoreDia.setDescription("Bore hole diameter.")
    gshpVertBoreDia.setDefaultValue(5.0)
    args << gshpVertBoreDia
    
    #make a double argument for gshp vert bore nominal pipe size
    gshpVertBorePipeSize = OpenStudio::Measure::OSArgument::makeDoubleArgument("pipe_size", true)
    gshpVertBorePipeSize.setDisplayName("Nominal Pipe Size")
    gshpVertBorePipeSize.setUnits("in")
    gshpVertBorePipeSize.setDescription("Pipe nominal size.")
    gshpVertBorePipeSize.setDefaultValue(0.75)
    args << gshpVertBorePipeSize
    
    #make a double argument for gshp vert bore ground diffusivity
    gshpVertBoreGroundDiff = OpenStudio::Measure::OSArgument::makeDoubleArgument("ground_diffusivity", true)
    gshpVertBoreGroundDiff.setDisplayName("Ground Diffusivity")
    gshpVertBoreGroundDiff.setUnits("ft^2/hr")
    gshpVertBoreGroundDiff.setDescription("A measure of thermal inertia, the ground diffusivity is the thermal conductivity divided by density and specific heat capacity.")
    gshpVertBoreGroundDiff.setDefaultValue(0.0208)
    args << gshpVertBoreGroundDiff

    #make a string argument for gshp bore fluid type
    fluid_display_names = OpenStudio::StringVector.new
    fluid_display_names << Constants.FluidPropyleneGlycol
    fluid_display_names << Constants.FluidEthyleneGlycol
    gshpVertBoreFluidType = OpenStudio::Measure::OSArgument::makeChoiceArgument("fluid_type", fluid_display_names, true)
    gshpVertBoreFluidType.setDisplayName("Heat Exchanger Fluid Type")
    gshpVertBoreFluidType.setDescription("Fluid type.")
    gshpVertBoreFluidType.setDefaultValue(Constants.FluidPropyleneGlycol)
    args << gshpVertBoreFluidType
    
    #make a double argument for gshp vert bore frac glycol
    gshpVertBoreFracGlycol = OpenStudio::Measure::OSArgument::makeDoubleArgument("frac_glycol", true)
    gshpVertBoreFracGlycol.setDisplayName("Fraction Glycol")
    gshpVertBoreFracGlycol.setUnits("frac")
    gshpVertBoreFracGlycol.setDescription("Fraction of glycol, 0 indicates water.")
    gshpVertBoreFracGlycol.setDefaultValue(0.3)
    args << gshpVertBoreFracGlycol
    
    #make a double argument for gshp vert bore ground loop design delta temp
    gshpVertBoreDTDesign = OpenStudio::Measure::OSArgument::makeDoubleArgument("design_delta_t", true)
    gshpVertBoreDTDesign.setDisplayName("Ground Loop Design Delta Temp")
    gshpVertBoreDTDesign.setUnits("deg F")
    gshpVertBoreDTDesign.setDescription("Ground loop design temperature difference.")
    gshpVertBoreDTDesign.setDefaultValue(10.0)
    args << gshpVertBoreDTDesign
    
    #make a double argument for gshp vert bore pump head
    gshpVertBorePumpHead = OpenStudio::Measure::OSArgument::makeDoubleArgument("pump_head", true)
    gshpVertBorePumpHead.setDisplayName("Pump Head")
    gshpVertBorePumpHead.setUnits("ft of water")
    gshpVertBorePumpHead.setDescription("Feet of water column.")
    gshpVertBorePumpHead.setDefaultValue(50.0)
    args << gshpVertBorePumpHead
    
    #make a double argument for gshp vert bore u tube leg sep
    gshpVertBoreUTubeLegSep = OpenStudio::Measure::OSArgument::makeDoubleArgument("u_tube_leg_spacing", true)
    gshpVertBoreUTubeLegSep.setDisplayName("U Tube Leg Separation")
    gshpVertBoreUTubeLegSep.setUnits("in")
    gshpVertBoreUTubeLegSep.setDescription("U-tube leg spacing.")
    gshpVertBoreUTubeLegSep.setDefaultValue(0.9661)
    args << gshpVertBoreUTubeLegSep
    
    #make a choice argument for gshp vert bore u tube spacing type
    spacing_type_names = OpenStudio::StringVector.new
    spacing_type_names << "as"
    spacing_type_names << "b"
    spacing_type_names << "c"
    gshpVertBoreUTubeSpacingType = OpenStudio::Measure::OSArgument::makeChoiceArgument("u_tube_spacing_type", spacing_type_names, true)
    gshpVertBoreUTubeSpacingType.setDisplayName("U Tube Spacing Type")
    gshpVertBoreUTubeSpacingType.setDescription("U-tube shank spacing type. Type B, for 5\" bore is equivalent to 0.9661\" shank spacing. Type C is the type where the U tube legs are furthest apart.")
    gshpVertBoreUTubeSpacingType.setDefaultValue("b")
    args << gshpVertBoreUTubeSpacingType
    
    #make a double argument for gshp vert bore rated shr
    gshpVertBoreRatedSHR = OpenStudio::Measure::OSArgument::makeDoubleArgument("rated_shr", true)
    gshpVertBoreRatedSHR.setDisplayName("Rated SHR")
    gshpVertBoreRatedSHR.setDescription("The sensible heat ratio (ratio of the sensible portion of the load to the total load) at the nominal rated capacity.")
    gshpVertBoreRatedSHR.setDefaultValue(0.732)
    args << gshpVertBoreRatedSHR
    
    #make a double argument for gshp vert bore supply fan power
    gshpVertBoreSupplyFanPower = OpenStudio::Measure::OSArgument::makeDoubleArgument("fan_power", true)
    gshpVertBoreSupplyFanPower.setDisplayName("Supply Fan Power")
    gshpVertBoreSupplyFanPower.setUnits("W/cfm")
    gshpVertBoreSupplyFanPower.setDescription("Fan power (in W) per delivered airflow rate (in cfm) of the indoor fan.")
    gshpVertBoreSupplyFanPower.setDefaultValue(0.5)
    args << gshpVertBoreSupplyFanPower    
    
    #make a string argument for gshp heating/cooling output capacity
    gshpOutputCapacity = OpenStudio::Measure::OSArgument::makeStringArgument("heat_pump_capacity", true)
    gshpOutputCapacity.setDisplayName("Heat Pump Capacity")
    gshpOutputCapacity.setDescription("The output heating/cooling capacity of the heat pump.")
    gshpOutputCapacity.setUnits("tons")
    gshpOutputCapacity.setDefaultValue(Constants.SizingAuto)
    args << gshpOutputCapacity    
    
    #make a string argument for supplemental heating output capacity
    supcap = OpenStudio::Measure::OSArgument::makeStringArgument("supplemental_capacity", true)
    supcap.setDisplayName("Supplemental Heating Capacity")
    supcap.setDescription("The output heating capacity of the supplemental heater.")
    supcap.setUnits("kBtu/hr")
    supcap.setDefaultValue(Constants.SizingAuto)
    args << supcap     
    
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
    ground_conductivity = runner.getDoubleArgumentValue("ground_conductivity",user_arguments)
    grout_conductivity = runner.getDoubleArgumentValue("grout_conductivity",user_arguments)
    bore_config = runner.getStringArgumentValue("bore_config",user_arguments)
    bore_holes = runner.getStringArgumentValue("bore_holes",user_arguments)
    bore_depth = runner.getStringArgumentValue("bore_depth",user_arguments)
    bore_spacing = runner.getDoubleArgumentValue("bore_spacing",user_arguments)
    bore_diameter = runner.getDoubleArgumentValue("bore_diameter",user_arguments)
    nom_pipe_size = runner.getDoubleArgumentValue("pipe_size",user_arguments)
    ground_diffusivity = runner.getDoubleArgumentValue("ground_diffusivity",user_arguments)
    fluid_type = runner.getStringArgumentValue("fluid_type",user_arguments)
    frac_glycol = runner.getDoubleArgumentValue("frac_glycol",user_arguments)
    design_delta_t = runner.getDoubleArgumentValue("design_delta_t",user_arguments)
    pump_head = UnitConversion.inH2O2Pa(OpenStudio::convert(runner.getDoubleArgumentValue("pump_head",user_arguments),"ft","in").get) # convert from ft H20 to Pascal
    leg_separation = runner.getDoubleArgumentValue("u_tube_leg_spacing",user_arguments)
    spacing_type = runner.getStringArgumentValue("u_tube_spacing_type",user_arguments)
    rated_shr = runner.getDoubleArgumentValue("rated_shr",user_arguments)
    supply_fan_power = runner.getDoubleArgumentValue("fan_power",user_arguments)
    gshp_capacity = runner.getStringArgumentValue("heat_pump_capacity",user_arguments)
    unless gshp_capacity == Constants.SizingAuto
      gshp_capacity = OpenStudio::convert(gshp_capacity.to_f,"ton","Btu/h").get
    end
    supp_capacity = runner.getStringArgumentValue("supplemental_capacity",user_arguments)
    unless supp_capacity == Constants.SizingAuto
      supp_capacity = OpenStudio::convert(supp_capacity.to_f,"kBtu/h","Btu/h").get
    end
    
    if frac_glycol == 0
      fluid_type = Constants.FluidWater
      runner.registerWarning("Specified #{Constants.FluidPropyleneGlycol} fluid type and 0 fraction of glycol, so assuming #{Constants.FluidWater} fluid type.")
    end
    
    # Ground Loop Heat Exchanger
    pipe_od, pipe_id = get_gshp_hx_pipe_diameters(nom_pipe_size)
    
    # Thermal Resistance of Pipe
    pipe_cond = 0.23 # Pipe thermal conductivity, default to high density polyethylene

    # Ground Loop And Loop Pump
    weather = WeatherProcess.new(model, runner, File.dirname(__FILE__))
    if weather.error?
      return false
    end    
    
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
    
    fanKW_Adjust = get_gshp_FanKW_Adjust(OpenStudio::convert(400.0,"Btu/hr","ton").get)
    pumpKW_Adjust = get_gshp_PumpKW_Adjust(OpenStudio::convert(3.0,"Btu/hr","ton").get)
    coolingEIR = get_gshp_cooling_eir(eer, fanKW_Adjust, pumpKW_Adjust)
    
    # Supply Fan
    static = UnitConversion.inH2O2Pa(0.5)
    
    # Heating Coil
    heatingEIR = get_gshp_heating_eir(cop, fanKW_Adjust, pumpKW_Adjust)
    min_hp_temp = -30.0
    
    # Remove ground heat exchanger condenser loop if it exists
    HVAC.remove_hot_water_loop(model, runner)
    
    ground_heat_exch_vert = OpenStudio::Model::GroundHeatExchangerVertical.new(model)
    ground_heat_exch_vert.setName(Constants.ObjectNameGroundSourceHeatPumpVerticalBore + " exchanger")
    ground_heat_exch_vert.setBoreHoleRadius(OpenStudio::convert(bore_diameter/2.0,"in","m").get)
    ground_heat_exch_vert.setGroundThermalConductivity(OpenStudio::convert(ground_conductivity,"Btu/hr*ft*R","W/m*K").get)
    ground_heat_exch_vert.setGroundThermalHeatCapacity(OpenStudio::convert(ground_conductivity / ground_diffusivity,"Btu/ft^3*F","J/m^3*K").get)
    ground_heat_exch_vert.setGroundTemperature(OpenStudio::convert(weather.data.AnnualAvgDrybulb,"F","C").get)
    ground_heat_exch_vert.setGroutThermalConductivity(OpenStudio::convert(grout_conductivity,"Btu/hr*ft*R","W/m*K").get)
    ground_heat_exch_vert.setPipeThermalConductivity(OpenStudio::convert(pipe_cond,"Btu/hr*ft*R","W/m*K").get)
    ground_heat_exch_vert.setPipeOutDiameter(OpenStudio::convert(pipe_od,"in","m").get)
    ground_heat_exch_vert.setUTubeDistance(OpenStudio::convert(leg_separation,"in","m").get)
    ground_heat_exch_vert.setPipeThickness(OpenStudio::convert((pipe_od - pipe_id)/2.0,"in","m").get)
    ground_heat_exch_vert.setMaximumLengthofSimulation(1)
    ground_heat_exch_vert.setGFunctionReferenceRatio(0.0005)
    
    plant_loop = OpenStudio::Model::PlantLoop.new(model)
    plant_loop.setName(Constants.ObjectNameGroundSourceHeatPumpVerticalBore + " condenser loop")
    if fluid_type == Constants.FluidWater
      plant_loop.setFluidType('Water')
    else
      runner.registerWarning("OpenStudio does not currently support glycol as a fluid type. Overriding to water.")
      plant_loop.setFluidType('Glycol') # TODO: openstudio changes this to Water since it's not an available fluid type option
    end
    plant_loop.setMaximumLoopTemperature(48.88889)
    plant_loop.setMinimumLoopTemperature(OpenStudio::convert(hw_design,"F","C").get)
    plant_loop.setMinimumLoopFlowRate(0)
    plant_loop.setLoadDistributionScheme('SequentialLoad')
    
    sizing_plant = plant_loop.sizingPlant
    sizing_plant.setLoopType('Condenser')
    sizing_plant.setDesignLoopExitTemperature(OpenStudio::convert(chw_design,"F","C").get)
    sizing_plant.setLoopDesignTemperatureDifference(OpenStudio::convert(design_delta_t,"R","K").get)
    
    setpoint_mgr_follow_ground_temp = OpenStudio::Model::SetpointManagerFollowGroundTemperature.new(model)
    setpoint_mgr_follow_ground_temp.setName(Constants.ObjectNameGroundSourceHeatPumpVerticalBore + " condenser loop temp")
    setpoint_mgr_follow_ground_temp.setControlVariable('Temperature')
    setpoint_mgr_follow_ground_temp.setMaximumSetpointTemperature(48.88889)
    setpoint_mgr_follow_ground_temp.setMinimumSetpointTemperature(OpenStudio::convert(hw_design,"F","C").get)    
    setpoint_mgr_follow_ground_temp.addToNode(plant_loop.supplyOutletNode)
    
    pump = OpenStudio::Model::PumpVariableSpeed.new(model)
    pump.setName(Constants.ObjectNameGroundSourceHeatPumpVerticalBore + " pump")
    pump.setRatedPumpHead(pump_head)
    pump.setMotorEfficiency(0.77 * 0.6)
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
    
    # Get building units
    units = Geometry.get_building_units(model, runner)
    if units.nil?
      return false
    end
    
    units.each do |unit|
    
      obj_name = Constants.ObjectNameGroundSourceHeatPumpVerticalBore(unit.name.to_s)
      
      thermal_zones = Geometry.get_thermal_zones_from_spaces(unit.spaces)
      
      control_slave_zones_hash = HVAC.get_control_and_slave_zones(thermal_zones)
      control_slave_zones_hash.each do |control_zone, slave_zones|
      
        # Remove existing equipment
        HVAC.remove_existing_hvac_equipment(model, runner, Constants.ObjectNameGroundSourceHeatPumpVerticalBore, control_zone) 

        gshp_HEAT_CAP_fT_coeff = HVAC.convert_curve_gshp(hEAT_CAP_FT_SEC, false)
        gshp_HEAT_POWER_fT_coeff = HVAC.convert_curve_gshp(hEAT_POWER_FT_SPEC, false)
        
        htg_coil = OpenStudio::Model::CoilHeatingWaterToAirHeatPumpEquationFit.new(model)
        htg_coil.setName(obj_name + " heating coil")
        if gshp_capacity != Constants.SizingAuto
          htg_coil.setRatedHeatingCapacity(OpenStudio::OptionalDouble.new(OpenStudio::convert(gshp_capacity,"Btu/h","W").get)) # Used by HVACSizing measure
        end
        htg_coil.setRatedHeatingCoefficientofPerformance(1.0 / heatingEIR)
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
        supp_htg_coil.setEfficiency(1)
        if supp_capacity != Constants.SizingAuto
          supp_htg_coil.setNominalCapacity(OpenStudio::convert(supp_capacity,"Btu/h","W").get) # Used by HVACSizing measure
        end        
        
        gshp_COOL_CAP_fT_coeff = HVAC.convert_curve_gshp(cOOL_CAP_FT_SPEC, false)
        gshp_COOL_POWER_fT_coeff = HVAC.convert_curve_gshp(cOOL_POWER_FT_SPEC, false)
        gshp_COOL_SH_fT_coeff = HVAC.convert_curve_gshp(cOOL_SH_FT_SPEC, false)
        
        clg_coil = OpenStudio::Model::CoilCoolingWaterToAirHeatPumpEquationFit.new(model)
        clg_coil.setName(obj_name + " cooling coil")
        if gshp_capacity != Constants.SizingAuto
          clg_coil.setRatedTotalCoolingCapacity(OpenStudio::convert(gshp_capacity,"Btu/h","W").get) # Used by HVACSizing measure
        end
        clg_coil.setRatedCoolingCoefficientofPerformance(1.0 / coolingEIR)
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
        fan.setFanEfficiency(HVAC.calculate_fan_efficiency(static, supply_fan_power))
        fan.setPressureRise(static)
        fan.setMotorEfficiency(1)
        fan.setMotorInAirstreamFraction(1)
          
        air_loop_unitary = OpenStudio::Model::AirLoopHVACUnitarySystem.new(model)
        air_loop_unitary.setName(obj_name + " unitary system")
        air_loop_unitary.setAvailabilitySchedule(model.alwaysOnDiscreteSchedule)
        air_loop_unitary.setSupplyFan(fan)
        air_loop_unitary.setHeatingCoil(htg_coil)
        air_loop_unitary.setCoolingCoil(clg_coil)
        air_loop_unitary.setSupplementalHeatingCoil(supp_htg_coil)
        air_loop_unitary.setFanPlacement("BlowThrough")
        air_loop_unitary.setSupplyAirFanOperatingModeSchedule(model.alwaysOffDiscreteSchedule)
        air_loop_unitary.setMaximumSupplyAirTemperature(OpenStudio::convert(170.0,"F","C").get) # higher temp for supplemental heat as to not severely limit its use, resulting in unmet hours.    
        air_loop_unitary.setMaximumOutdoorDryBulbTemperatureforSupplementalHeaterOperation(OpenStudio::convert(40.0,"F","C").get)
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
        runner.registerInfo("Added '#{htg_coil.name}' to '#{air_loop_unitary.name}' of '#{air_loop.name}'")
        runner.registerInfo("Added '#{supp_htg_coil.name}' to '#{air_loop_unitary.name}' of '#{air_loop.name}'")    
        
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

        HVAC.prioritize_zone_hvac(model, runner, control_zone).reverse.each do |object|
          control_zone.setCoolingPriority(object, 1)
          control_zone.setHeatingPriority(object, 1)
        end
        
        slave_zones.each do |slave_zone|

          # Remove existing equipment
          HVAC.remove_existing_hvac_equipment(model, runner, Constants.ObjectNameGroundSourceHeatPumpVerticalBore, slave_zone)
      
          diffuser_fbsmt = OpenStudio::Model::AirTerminalSingleDuctUncontrolled.new(model, model.alwaysOnDiscreteSchedule)
          diffuser_fbsmt.setName(obj_name + " #{slave_zone.name} direct air")
          air_loop.addBranchForZone(slave_zone, diffuser_fbsmt.to_StraightComponent)

          air_loop.addBranchForZone(slave_zone)
          runner.registerInfo("Added '#{air_loop.name}' to '#{slave_zone.name}' of #{unit.name}")

          HVAC.prioritize_zone_hvac(model, runner, slave_zone).reverse.each do |object|
            slave_zone.setCoolingPriority(object, 1)
            slave_zone.setHeatingPriority(object, 1)
          end
          
        end        
      
      end
      
      # Store info for HVAC Sizing measure
      unit.setFeature(Constants.SizingInfoHVACSHR, rated_shr.to_s)
      unit.setFeature(Constants.SizingInfoGSHPCoil_BF_FT_SPEC, cOIL_BF_FT_SPEC.join(","))
      unit.setFeature(Constants.SizingInfoGSHPCoilBF, coilBF)
      unit.setFeature(Constants.SizingInfoGSHPBoreSpacing, bore_spacing)
      unit.setFeature(Constants.SizingInfoGSHPBoreHoles, bore_holes)
      unit.setFeature(Constants.SizingInfoGSHPBoreDepth, bore_depth)
      unit.setFeature(Constants.SizingInfoGSHPBoreConfig, bore_config)
      unit.setFeature(Constants.SizingInfoGSHPUTubeSpacingType, spacing_type)
      
    end
    
    return true

  end
  
  def get_gshp_hx_pipe_diameters(nom_pipe_size)
    # Pipe norminal size convertion to pipe outside diameter and inside diameter, 
    # only pipe sizes <= 2" are used here with DR11 (dimension ratio),
    if nom_pipe_size == 0.75 # 3/4" pipe
      pipe_od = 1.050
      pipe_id = 0.859
    elsif nom_pipe_size == 1.0 # 1" pipe
      pipe_od = 1.315
      pipe_id = 1.076
    elsif nom_pipe_size == 1.25 # 1-1/4" pipe
      pipe_od = 1.660
      pipe_id = 1.358
    end
    return pipe_od, pipe_id      
  end
    
  def get_gshp_HXCHWDesign(weather)
    return [85.0, weather.design.CoolingDrybulb - 15.0, weather.data.AnnualAvgDrybulb + 10.0].max # Temperature of water entering indoor coil,use 85F as lower bound
  end
  
  def get_gshp_HXHWDesign(weather, fluid_type)
    if fluid_type == Constants.FluidWater
      return [45.0, weather.design.HeatingDrybulb + 35.0, weather.data.AnnualAvgDrybulb - 10.0].max # Temperature of fluid entering indoor coil, use 45F as lower bound for water
    else
      return [35.0, weather.design.HeatingDrybulb + 35.0, weather.data.AnnualAvgDrybulb - 10.0].min # Temperature of fluid entering indoor coil, use 35F as upper bound
    end
  end
  
  def get_gshp_cooling_eir(eer, fanKW_Adjust, pumpKW_Adjust)
    return OpenStudio::convert((1.0 - eer * (fanKW_Adjust + pumpKW_Adjust)) / (eer * (1 + OpenStudio::convert(fanKW_Adjust,"Wh","Btu").get)),"Wh","Btu").get
  end
  
  def get_gshp_heating_eir(cop, fanKW_Adjust, pumpKW_Adjust)
    return (1.0 - cop * (fanKW_Adjust + pumpKW_Adjust)) / (cop * (1 - fanKW_Adjust))
  end
  
  def get_gshp_FanKW_Adjust(cfm_btuh)
    return cfm_btuh * OpenStudio::convert(1.0,"cfm","m^3/s").get * 1000.0 * 0.35 * 249.0 / 300.0 # Adjustment per ISO 13256-1 Internal pressure drop across heat pump assumed to be 0.5 in. w.g.
  end
  
  def get_gshp_PumpKW_Adjust(gpm_btuh)
    return gpm_btuh * OpenStudio::convert(1.0,"gal/min","m^3/s").get * 1000.0 * 6.0 * 2990.0 / 3000.0 # Adjustment per ISO 13256-1 Internal Pressure drop across heat pump coil assumed to be 11ft w.g.
  end
      
end

# register the measure to be used by the application
ProcessGroundSourceHeatPumpVerticalBore.new.registerWithApplication
