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
    cap_display_names = OpenStudio::StringVector.new
    (0.5..10.0).step(0.5) do |tons|
      cap_display_names << tons.to_s
    end
    gshpOutputCapacity = OpenStudio::Measure::OSArgument::makeChoiceArgument("gshp_capacity", cap_display_names, true)
    gshpOutputCapacity.setDisplayName("Heat Pump Capacity")
    gshpOutputCapacity.setDescription("The output heating/cooling capacity of the heat pump.")
    gshpOutputCapacity.setUnits("tons")
    gshpOutputCapacity.setDefaultValue("3.0")
    args << gshpOutputCapacity    
    
    #make a string argument for supplemental heating output capacity
    cap_display_names = OpenStudio::StringVector.new
    cap_display_names << Constants.SizingAuto
    (5..150).step(5) do |kbtu|
      cap_display_names << kbtu.to_s
    end
    supcap = OpenStudio::Measure::OSArgument::makeChoiceArgument("supplemental_capacity", cap_display_names, true)
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
    rated_shr = runner.getDoubleArgumentValue("rated_shr",user_arguments)
    supply_fan_power = runner.getDoubleArgumentValue("fan_power",user_arguments)
    gshp_capacity = OpenStudio::convert(runner.getStringArgumentValue("gshp_capacity",user_arguments).to_f,"ton","Btu/h").get
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
    gSHPPipeCond = 0.23 # Pipe thermal conductivity, default to high density polyethylene
    pipe_r_value = get_gshp_hx_pipe_rvalue(pipe_od, pipe_id, gSHPPipeCond)    

    # Ground Loop And Loop Pump
    weather = WeatherProcess.new(model, runner, File.dirname(__FILE__))
    if weather.error?
      return false
    end    
    
    heat_design_db = weather.design.HeatingDrybulb
    cool_design_db = weather.design.CoolingDrybulb
    chw_design = get_gshp_HXCHWDesign(weather, cool_design_db)
    hw_design = get_gshp_HXHWDesign(weather, heat_design_db, fluid_type)
    
    # Cooling Coil
    cOOL_CAP_FT_SPEC = [0.39039063, 0.01382596, 0.00000000, -0.00445738, 0.00000000, 0.00000000]
    cOOL_SH_FT_SPEC = [4.27136253, -0.04678521, 0.00000000, -0.00219031, 0.00000000, 0.00000000]
    cOOL_POWER_FT_SPEC = [0.01717338, 0.00316077, 0.00000000, 0.01043792, 0.00000000, 0.00000000]
    
    fanKW_Adjust = get_gshp_FanKW_Adjust(OpenStudio::convert(400.0,"Btu/hr","ton").get)
    pumpKW_Adjust = get_gshp_PumpKW_Adjust(OpenStudio::convert(3.0,"Btu/hr","ton").get)
    coolingEIR = get_gshp_cooling_eir(eer, fanKW_Adjust, pumpKW_Adjust)
    
    # Supply Fan
    static = UnitConversion.inH2O2Pa(0.5)
    
    # Heating Coil
    heatingEIR = get_gshp_heating_eir(cop, fanKW_Adjust, pumpKW_Adjust)
    min_hp_temp = -30.0
    
    htd = 70.0 - heat_design_db
    ctd = cool_design_db - 75.0
    nom_length_heat, nom_length_cool = gshp_hxbore_ft_per_ton(weather, htd, ctd, bore_spacing, ground_conductivity, grout_conductivity, bore_diameter, pipe_od, pipe_r_value, heatingEIR[0], coolingEIR[0], chw_design, hw_design, design_delta_t)    
    
    bore_length_heat = nom_length_heat * gshp_capacity / OpenStudio::convert(1.0,"ton","Btu/h").get
    bore_length_cool = nom_length_cool * gshp_capacity / OpenStudio::convert(1.0,"ton","Btu/h").get
    
    # bore_length_mult = TODO
    bore_length = [bore_length_heat, bore_length_cool].max
    bore_length_mult = 1.0
    bore_length *= bore_length_mult
    
    loop_flow = [1.0, OpenStudio::convert(gshp_capacity,"Btu/h","ton").get].max.floor
    
    if bore_holes == Constants.SizingAuto and bore_depth == Constants.SizingAuto
      bore_holes = [1, (OpenStudio::convert(gshp_capacity,"Btu/h","ton").get + 0.5).floor].max
      bore_depth = (bore_length / bore_holes).floor
      min_bore_depth = 0.15 * bore_spacing # 0.15 is the maximum Spacing2DepthRatio defined for the G-function in EnergyPlus.bmi
      
      (0..4).to_a.each do |tmp|
        if bore_depth < min_bore_depth and bore_holes > 1
          bore_holes -= 1
          bore_depth = (bore_length / bore_holes).floor
        elsif bore_depth > 345
          bore_holes += 1
          bore_depth = (bore_length / bore_holes).floor
        end
      end
        
      bore_depth = (bore_length / bore_holes).floor + 5
      
    elsif bore_holes == Constants.SizingAuto and bore_depth != Constants.SizingAuto
      bore_holes = (bore_length / bore_depth.to_f + 0.5).floor
      bore_depth = bore_depth.to_f
    elsif bore_holes != Constants.SizingAuto and bore_depth == Constants.SizingAuto
      bore_holes = bore_holes.to_f
      bore_depth = (bore_length / bore_holes).floor + 5
    else
      runner.registerWarning("User is hard sizing the bore field, improper sizing may lead to unbalanced / unsteady ground loop temperature and erroneous prediction of system energy related cost.")
      bore_holes = bore_holes.to_f
      bore_depth = bore_depth.to_f
    end

    if bore_config == Constants.SizingAuto
      if bore_holes == 1
          bore_config = Constants.BoreConfigSingle
      elsif bore_holes == 2
          bore_config = Constants.BoreConfigLine
      elsif bore_holes == 3
          bore_config = Constants.BoreConfigLine
      elsif bore_holes == 4
          bore_config = Constants.BoreConfigRectangle
      elsif bore_holes == 5
          bore_config = Constants.BoreConfigUconfig
      elsif bore_holes > 5
          bore_config = Constants.BoreConfigLine
      end
    end
    
    # Test for valid GSHP bore field configurations
    valid_configs = {Constants.BoreConfigSingle=>[1], Constants.BoreConfigLine=>[2,3,4,5,6,7,8,9,10], Constants.BoreConfigLconfig=>[3,4,5,6], Constants.BoreConfigRectangle=>[2,4,6,8], Constants.BoreConfigUconfig=>[5,7,9], Constants.BoreConfigL2config=>[8], Constants.BoreConfigOpenRectangle=>[8]}
    valid_num_bores = valid_configs[bore_config]
    max_valid_configs = {Constants.BoreConfigLine=>10, Constants.BoreConfigLconfig=>6}
    unless valid_num_bores.include? bore_holes
      # Any configuration with a max_valid_configs value can accept any number of bores up to the maximum    
      if max_valid_configs.keys.include? bore_config
        max_bore_holes = max_valid_configs[bore_config]
        runner.registerWarning("Maximum number of bore holes for '#{bore_config}' bore configuration is #{max_bore_holes}. Overriding value of #{bore_holes} bore holes to #{max_bore_holes}.")
        bore_holes = max_bore_holes
      else
        # Search for first valid bore field
        new_bore_config = nil
        valid_field_found = false
        valid_configs.keys.each do |bore_config|
          if valid_configs[bore_config].include? bore_holes
            valid_field_found = true
            new_bore_config = bore_config
            break
          end
        end
        if valid_field_found
          runner.registerWarning("Bore field '#{bore_config}' with #{bore_holes.to_i} bore holes is an invalid configuration. Changing layout to '#{new_bore_config}' configuration.")
          bore_config = new_bore_config
        else
          runner.registerError("Could not construct a valid GSHP bore field configuration.")
          return false
        end
      end
    end
    
    spacing_to_depth_ratio = bore_spacing / bore_depth
    
    gfnc_coeff = get_gfnc_coeff(bore_config, bore_holes, spacing_to_depth_ratio)
    
    # Remove ground heat exchanger condenser loop if it exists
    HVAC.remove_hot_water_loop(model, runner)
    
    ground_heat_exch_vert = OpenStudio::Model::GroundHeatExchangerVertical.new(model)
    ground_heat_exch_vert.setName(Constants.ObjectNameGroundSourceHeatPumpVerticalBore + " exchanger")
    ground_heat_exch_vert.setDesignFlowRate(OpenStudio::convert(loop_flow,"gal/min","m^3/s").get)
    ground_heat_exch_vert.setNumberofBoreHoles(bore_holes.to_i)
    ground_heat_exch_vert.setBoreHoleLength(OpenStudio::convert(bore_depth,"ft","m").get)
    ground_heat_exch_vert.setBoreHoleRadius(OpenStudio::convert(bore_diameter/2.0,"in","m").get)
    ground_heat_exch_vert.setGroundThermalConductivity(OpenStudio::convert(ground_conductivity,"Btu/hr*ft*R","W/m*K").get)
    ground_heat_exch_vert.setGroundThermalHeatCapacity(OpenStudio::convert(ground_conductivity / ground_diffusivity,"Btu/ft^3*F","J/m^3*K").get)
    ground_heat_exch_vert.setGroundTemperature(OpenStudio::convert(weather.data.AnnualAvgDrybulb,"F","C").get)
    ground_heat_exch_vert.setGroutThermalConductivity(OpenStudio::convert(grout_conductivity,"Btu/hr*ft*R","W/m*K").get)
    ground_heat_exch_vert.setPipeThermalConductivity(OpenStudio::convert(gSHPPipeCond,"Btu/hr*ft*R","W/m*K").get)
    ground_heat_exch_vert.setPipeOutDiameter(OpenStudio::convert(pipe_od,"in","m").get)
    ground_heat_exch_vert.setUTubeDistance(OpenStudio::convert(leg_separation,"in","m").get)
    ground_heat_exch_vert.setPipeThickness(OpenStudio::convert((pipe_od - pipe_id)/2.0,"in","m").get)
    ground_heat_exch_vert.setMaximumLengthofSimulation(1)
    ground_heat_exch_vert.setGFunctionReferenceRatio(0.0005)
    
    lntts = [-8.5,-7.8,-7.2,-6.5,-5.9,-5.2,-4.5,-3.963,-3.27,-2.864,-2.577,-2.171,-1.884,-1.191,-0.497,-0.274,-0.051,0.196,0.419,0.642,0.873,1.112,1.335,1.679,2.028,2.275,3.003]

    ground_heat_exch_vert.removeAllGFunctions
    gfnc_coeff.each_with_index do |g_value, i|
      ground_heat_exch_vert.addGFunction(lntts[i], g_value)
    end
    
    plant_loop = OpenStudio::Model::PlantLoop.new(model)
    plant_loop.setName(Constants.ObjectNameGroundSourceHeatPumpVerticalBore + " condenser loop")
    if fluid_type == Constants.FluidWater
      plant_loop.setFluidType('Water')
    else
      plant_loop.setFluidType('Glycol') # TODO: openstudio changes this to Water since it's not an available fluid type option
    end
    plant_loop.setMaximumLoopTemperature(48.88889)
    plant_loop.setMinimumLoopTemperature(OpenStudio::convert(hw_design,"F","C").get)
    plant_loop.setMaximumLoopFlowRate(OpenStudio::convert(loop_flow,"gal/min","m^3/s").get)
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
    pump.setRatedFlowRate(OpenStudio::convert(loop_flow,"gal/min","m^3/s").get)
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

        c = [0.67104926, -0.00210834, 0.00000000, 0.01491424, 0.00000000, 0.00000000] # unit.gshp.GSHP_HEAT_CAP_FT_SPEC_coefficients
        gshp_Heat_CAP_fT_coeff = []
        gshp_Heat_CAP_fT_coeff << c[0]+(32-273.15*1.8)*(c[1] + c[3])
        gshp_Heat_CAP_fT_coeff << 283*1.8*c[1]
        gshp_Heat_CAP_fT_coeff << 283*1.8*c[3]
        gshp_Heat_CAP_fT_coeff << 0
        gshp_Heat_CAP_fT_coeff << 0

        c = [-0.46308105, 0.02008988, 0.00000000, 0.00300222, 0.00000000, 0.00000000] # unit.gshp.GSHP_HEAT_POWER_FT_SPEC_coefficients                     # Lingering comments from .bmi
        gshp_Heat_Power_fT_coeff = []
        gshp_Heat_Power_fT_coeff << c[0]+(32-273.15*1.8)*(c[1] + c[3])    # @GSHP_HEAT_EIR_FT_SPEC_coefficients[1]+(32-273.15*1.8)*(@GSHP_HEAT_EIR_FT_SPEC_coefficients[2] + @GSHP_HEAT_EIR_FT_SPEC_coefficients[4])
        gshp_Heat_Power_fT_coeff << 283*1.8*c[1]                          # 283*1.8*@GSHP_HEAT_EIR_FT_SPEC_coefficients[2]
        gshp_Heat_Power_fT_coeff << 283*1.8*c[3]                          # 283*1.8*@GSHP_HEAT_EIR_FT_SPEC_coefficients[4]
        gshp_Heat_Power_fT_coeff << 0
        gshp_Heat_Power_fT_coeff << 0        
        
        htg_coil = OpenStudio::Model::CoilHeatingWaterToAirHeatPumpEquationFit.new(model)
        htg_coil.setName(obj_name + " heating coil")
        htg_coil.setRatedWaterFlowRate(OpenStudio::OptionalDouble.new(OpenStudio::convert(loop_flow,"gal/min","m^3/s").get))
        htg_coil.setRatedHeatingCapacity(OpenStudio::OptionalDouble.new(OpenStudio::convert(gshp_capacity,"Btu/h","W").get))
        htg_coil.setRatedHeatingCoefficientofPerformance(1.0 / heatingEIR[0])
        htg_coil.setHeatingCapacityCoefficient1(gshp_Heat_CAP_fT_coeff[0])
        htg_coil.setHeatingCapacityCoefficient2(gshp_Heat_CAP_fT_coeff[1])
        htg_coil.setHeatingCapacityCoefficient3(gshp_Heat_CAP_fT_coeff[2])
        htg_coil.setHeatingCapacityCoefficient4(gshp_Heat_CAP_fT_coeff[3])
        htg_coil.setHeatingCapacityCoefficient5(gshp_Heat_CAP_fT_coeff[4])
        htg_coil.setHeatingPowerConsumptionCoefficient1(gshp_Heat_Power_fT_coeff[0])
        htg_coil.setHeatingPowerConsumptionCoefficient2(gshp_Heat_Power_fT_coeff[1])
        htg_coil.setHeatingPowerConsumptionCoefficient3(gshp_Heat_Power_fT_coeff[2])
        htg_coil.setHeatingPowerConsumptionCoefficient4(gshp_Heat_Power_fT_coeff[3])
        htg_coil.setHeatingPowerConsumptionCoefficient5(gshp_Heat_Power_fT_coeff[4])
        
        plant_loop.addDemandBranchForComponent(htg_coil)
        
        supp_htg_coil = OpenStudio::Model::CoilHeatingElectric.new(model, model.alwaysOnDiscreteSchedule)
        supp_htg_coil.setName(obj_name + " supp heater")
        supp_htg_coil.setEfficiency(1)
        if supp_capacity != Constants.SizingAuto
          supp_htg_coil.setNominalCapacity(OpenStudio::convert(supp_capacity,"Btu/h","W").get) # Used by HVACSizing measure
        end        
        
        c = cOOL_CAP_FT_SPEC
        gshp_Cool_CAP_fT_coeff = []
        gshp_Cool_CAP_fT_coeff << c[0] +(32-273.15*1.8)*(c[1] + c[3])
        gshp_Cool_CAP_fT_coeff << 283*1.8*c[1]
        gshp_Cool_CAP_fT_coeff << 283*1.8*c[3]
        gshp_Cool_CAP_fT_coeff << 0
        gshp_Cool_CAP_fT_coeff << 0

        c = cOOL_SH_FT_SPEC
        gshp_COOL_SH_fT_coeff = []
        gshp_COOL_SH_fT_coeff << c[0]+(32-273.15*1.8)*(c[1] + c[3])
        gshp_COOL_SH_fT_coeff << 0
        gshp_COOL_SH_fT_coeff << 283*1.8*c[1]
        gshp_COOL_SH_fT_coeff << 283*1.8*c[3]
        gshp_COOL_SH_fT_coeff << 0
        gshp_COOL_SH_fT_coeff << 0

        c = cOOL_POWER_FT_SPEC
        gshp_Cool_Power_fT_coeff = []
        gshp_Cool_Power_fT_coeff << c[0]+(32-273.15*1.8)*(c[1] + c[3])
        gshp_Cool_Power_fT_coeff << 283*1.8*c[1]
        gshp_Cool_Power_fT_coeff << 283*1.8*c[3]
        gshp_Cool_Power_fT_coeff << 0
        gshp_Cool_Power_fT_coeff << 0        
        
        clg_coil = OpenStudio::Model::CoilCoolingWaterToAirHeatPumpEquationFit.new(model)
        clg_coil.setName(obj_name + " cooling coil")
        clg_coil.setRatedWaterFlowRate(OpenStudio::convert(loop_flow,"gal/min","m^3/s").get)
        clg_coil.setRatedTotalCoolingCapacity(OpenStudio::convert(gshp_capacity,"Btu/h","W").get)
        clg_coil.setRatedSensibleCoolingCapacity(OpenStudio::convert(gshp_capacity,"Btu/h","W").get * rated_shr)
        clg_coil.setRatedCoolingCoefficientofPerformance(1.0 / coolingEIR[0])
        clg_coil.setTotalCoolingCapacityCoefficient1(gshp_Cool_CAP_fT_coeff[0])
        clg_coil.setTotalCoolingCapacityCoefficient2(gshp_Cool_CAP_fT_coeff[1])
        clg_coil.setTotalCoolingCapacityCoefficient3(gshp_Cool_CAP_fT_coeff[2])
        clg_coil.setTotalCoolingCapacityCoefficient4(gshp_Cool_CAP_fT_coeff[3])
        clg_coil.setTotalCoolingCapacityCoefficient5(gshp_Cool_CAP_fT_coeff[4])
        clg_coil.setSensibleCoolingCapacityCoefficient1(gshp_COOL_SH_fT_coeff[0])
        clg_coil.setSensibleCoolingCapacityCoefficient2(gshp_COOL_SH_fT_coeff[1])
        clg_coil.setSensibleCoolingCapacityCoefficient3(gshp_COOL_SH_fT_coeff[2])
        clg_coil.setSensibleCoolingCapacityCoefficient4(gshp_COOL_SH_fT_coeff[3])
        clg_coil.setSensibleCoolingCapacityCoefficient5(gshp_COOL_SH_fT_coeff[4])
        clg_coil.setCoolingPowerConsumptionCoefficient1(gshp_Cool_Power_fT_coeff[0])
        clg_coil.setCoolingPowerConsumptionCoefficient2(gshp_Cool_Power_fT_coeff[1])
        clg_coil.setCoolingPowerConsumptionCoefficient3(gshp_Cool_Power_fT_coeff[2])
        clg_coil.setCoolingPowerConsumptionCoefficient4(gshp_Cool_Power_fT_coeff[3])
        clg_coil.setCoolingPowerConsumptionCoefficient5(gshp_Cool_Power_fT_coeff[4])
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
  
  def get_gshp_hx_pipe_rvalue(pipe_od, pipe_id, pipe_cond)
    # Thermal Resistance of Pipe
    return Math.log(pipe_od / pipe_id) / 2.0 / Math::PI / pipe_cond
  end
  
  def get_gshp_HXCHWDesign(weather, cool_design_db)
    return [85.0, cool_design_db - 15.0, weather.data.AnnualAvgDrybulb + 10.0].max # Temperature of water entering indoor coil,use 85F as lower bound
  end
  
  def get_gshp_HXHWDesign(weather, heat_design_db, fluid_type)
    if fluid_type == Constants.FluidWater
      return [45.0, heat_design_db + 35.0, weather.data.AnnualAvgDrybulb - 10.0].max # Temperature of water entering indoor coil, use 45F as lower bound for water
    else
      return [35.0, heat_design_db + 35.0, weather.data.AnnualAvgDrybulb - 10.0].max # Temperature of water entering indoor coil, use 35F as upper bound
    end
  end
  
  def get_gshp_cooling_eir(eer, fanKW_Adjust, pumpKW_Adjust)
    return [OpenStudio::convert((1.0 - eer * (fanKW_Adjust + pumpKW_Adjust)) / (eer * (1 + OpenStudio::convert(fanKW_Adjust,"Wh","Btu").get)),"Wh","Btu").get]
  end
  
  def get_gshp_heating_eir(cop, fanKW_Adjust, pumpKW_Adjust)
    return [(1.0 - cop * (fanKW_Adjust + pumpKW_Adjust)) / (cop * (1 - fanKW_Adjust))]
  end
  
  def get_gshp_FanKW_Adjust(cfm_btuh)
    return cfm_btuh * OpenStudio::convert(1.0,"cfm","m^3/s").get * 1000.0 * 0.35 * 249.0 / 300.0 # Adjustment per ISO 13256-1 Internal pressure drop across heat pump assumed to be 0.5 in. w.g.
  end
  
  def get_gshp_PumpKW_Adjust(gpm_btuh)
    return gpm_btuh * OpenStudio::convert(1.0,"gal/min","m^3/s").get * 1000.0 * 6.0 * 2990.0 / 3000.0 # Adjustment per ISO 13256-1 Internal Pressure drop across heat pump coil assumed to be 11ft w.g.
  end
  
  def gshp_hxbore_ft_per_ton(weather, htd, ctd, bore_spacing, ground_conductivity, grout_conductivity, bore_diameter, pipe_od, pipe_r_value, heating_eir, cooling_eir, chw_design, hw_design, design_delta_t)
    beta_0 = 17.4427
    beta_1 = -0.6052
    
    r_value_ground = Math.log(bore_spacing / bore_diameter * 12.0) / 2.0 / Math::PI / ground_conductivity
    r_value_grout = 1.0 / grout_conductivity / beta_0 / ((bore_diameter / pipe_od) ** beta_1)
    r_value_bore = r_value_grout + pipe_r_value / 2.0 # Note: Convection resistance is negligible when calculated against Glhepro (Jeffrey D. Spitler, 2000)

    rtf_DesignMon_Heat = [0.25, (71.0 - weather.data.MonthlyAvgDrybulbs[0]) / htd].max
    rtf_DesignMon_Cool = [0.25, (weather.data.MonthlyAvgDrybulbs[6] - 76.0) / ctd].max

    nom_length_heat = (1.0 - heating_eir) * (r_value_bore + r_value_ground * rtf_DesignMon_Heat) / (weather.data.AnnualAvgDrybulb - (2.0 * hw_design - design_delta_t) / 2.0) * OpenStudio::convert(1.0,"ton","Btu/h").get
    nom_length_cool = (1.0 + cooling_eir) * (r_value_bore + r_value_ground * rtf_DesignMon_Cool) / ((2.0 * chw_design + design_delta_t) / 2.0 - weather.data.AnnualAvgDrybulb) * OpenStudio::convert(1.0,"ton","Btu/h").get
    
    return nom_length_heat, nom_length_cool
  end
  
  def get_gfnc_coeff(bore_config, num_bore_holes, spacing_to_depth_ratio)
    # Set GFNC coefficients
    if bore_config == Constants.BoreConfigSingle
      gfnc_coeff = 2.681,3.024,3.320,3.666,3.963,4.306,4.645,4.899,5.222,5.405,5.531,5.704,5.821,6.082,6.304,6.366,6.422,6.477,6.520,6.558,6.591,6.619,6.640,6.665,6.893,6.694,6.715
    elsif bore_config == Constants.BoreConfigLine
      if num_bore_holes == 2
        if spacing_to_depth_ratio <= 0.02
          gfnc_coeff = 2.681,3.043,3.397,3.9,4.387,5.005,5.644,6.137,6.77,7.131,7.381,7.722,7.953,8.462,8.9,9.022,9.13,9.238,9.323,9.396,9.46,9.515,9.556,9.604,9.636,9.652,9.678
        elsif spacing_to_depth_ratio <= 0.03
          gfnc_coeff = 2.679,3.024,3.332,3.734,4.143,4.691,5.29,5.756,6.383,6.741,6.988,7.326,7.557,8.058,8.5,8.622,8.731,8.839,8.923,8.997,9.061,9.115,9.156,9.203,9.236,9.252,9.277
        elsif spacing_to_depth_ratio <= 0.05
          gfnc_coeff = 2.679,3.023,3.319,3.668,3.988,4.416,4.921,5.323,5.925,6.27,6.512,6.844,7.073,7.574,8.015,8.137,8.247,8.354,8.439,8.511,8.575,8.629,8.67,8.718,8.75,8.765,8.791
        elsif spacing_to_depth_ratio <= 0.1
          gfnc_coeff = 2.679,3.023,3.318,3.664,3.961,4.31,4.672,4.919,5.406,5.711,5.932,6.246,6.465,6.945,7.396,7.52,7.636,7.746,7.831,7.905,7.969,8.024,8.066,8.113,8.146,8.161,8.187
        elsif spacing_to_depth_ratio <= 0.15
          gfnc_coeff = 2.679,3.023,3.318,3.664,3.961,4.306,4.648,4.835,5.232,5.489,5.682,5.964,6.166,6.65,7.087,7.208,7.32,7.433,7.52,7.595,7.661,7.717,7.758,7.806,7.839,7.855,7.88
        end
      elsif num_bore_holes == 3
        if spacing_to_depth_ratio <= 0.02
          gfnc_coeff = 2.682,3.05,3.425,3.992,4.575,5.366,6.24,6.939,7.86,8.39,8.759,9.263,9.605,10.358,11.006,11.185,11.345,11.503,11.628,11.736,11.831,11.911,11.971,12.041,12.089,12.112,12.151
        elsif spacing_to_depth_ratio <= 0.03
          gfnc_coeff = 2.679,3.025,3.336,3.758,4.21,4.855,5.616,6.243,7.124,7.639,7.999,8.493,8.833,9.568,10.22,10.399,10.56,10.718,10.841,10.949,11.043,11.122,11.182,11.252,11.299,11.322,11.36
        elsif spacing_to_depth_ratio <= 0.05
          gfnc_coeff = 2.679,3.023,3.319,3.67,3.997,4.454,5.029,5.517,6.298,6.768,7.106,7.578,7.907,8.629,9.274,9.452,9.612,9.769,9.893,9.999,10.092,10.171,10.231,10.3,10.347,10.37,10.407
        elsif spacing_to_depth_ratio <= 0.1
          gfnc_coeff = 2.679,3.023,3.318,3.664,3.962,4.311,4.681,4.942,5.484,5.844,6.116,6.518,6.807,7.453,8.091,8.269,8.435,8.595,8.719,8.826,8.919,8.999,9.06,9.128,9.175,9.198,9.235
        elsif spacing_to_depth_ratio <= 0.15
          gfnc_coeff = 2.679,3.023,3.318,3.664,3.961,4.306,4.649,4.836,5.25,5.53,5.746,6.076,6.321,6.924,7.509,7.678,7.836,7.997,8.121,8.229,8.325,8.405,8.465,8.535,8.582,8.605,8.642
        end      
      elsif num_bore_holes == 4
        if spacing_to_depth_ratio <= 0.02
          gfnc_coeff = 2.682,3.054,3.438,4.039,4.676,5.575,6.619,7.487,8.662,9.35,9.832,10.492,10.943,11.935,12.787,13.022,13.232,13.44,13.604,13.745,13.869,13.975,14.054,14.145,14.208,14.238,14.289
        elsif spacing_to_depth_ratio <= 0.03
          gfnc_coeff = 2.679,3.025,3.339,3.77,4.244,4.941,5.798,6.539,7.622,8.273,8.734,9.373,9.814,10.777,11.63,11.864,12.074,12.282,12.443,12.584,12.706,12.81,12.888,12.979,13.041,13.071,13.12
        elsif spacing_to_depth_ratio <= 0.05
          gfnc_coeff = 2.679,3.023,3.319,3.671,4.001,4.474,5.086,5.62,6.514,7.075,7.487,8.075,8.49,9.418,10.253,10.484,10.692,10.897,11.057,11.195,11.316,11.419,11.497,11.587,11.647,11.677,11.726
        elsif spacing_to_depth_ratio <= 0.1
          gfnc_coeff = 2.679,3.023,3.318,3.664,3.962,4.311,4.686,4.953,5.523,5.913,6.214,6.67,7.005,7.78,8.574,8.798,9.011,9.215,9.373,9.512,9.632,9.735,9.814,9.903,9.963,9.993,10.041
        elsif spacing_to_depth_ratio <= 0.15
          gfnc_coeff = 2.679,3.023,3.318,3.664,3.961,4.306,4.649,4.837,5.259,5.55,5.779,6.133,6.402,7.084,7.777,7.983,8.178,8.379,8.536,8.672,8.795,8.898,8.975,9.064,9.125,9.155,9.203
        end      
      elsif num_bore_holes == 5
        if spacing_to_depth_ratio <= 0.02
          gfnc_coeff = 2.683,3.056,3.446,4.067,4.737,5.709,6.877,7.879,9.272,10.103,10.69,11.499,12.053,13.278,14.329,14.618,14.878,15.134,15.336,15.51,15.663,15.792,15.89,16.002,16.079,16.117,16.179
        elsif spacing_to_depth_ratio <= 0.03
          gfnc_coeff = 2.679,3.025,3.34,3.777,4.265,4.993,5.913,6.735,7.974,8.737,9.285,10.054,10.591,11.768,12.815,13.103,13.361,13.616,13.814,13.987,14.137,14.264,14.36,14.471,14.548,14.584,14.645
        elsif spacing_to_depth_ratio <= 0.05
          gfnc_coeff = 2.679,3.023,3.319,3.671,4.004,4.485,5.12,5.683,6.653,7.279,7.747,8.427,8.914,10.024,11.035,11.316,11.571,11.82,12.016,12.185,12.332,12.458,12.553,12.663,12.737,12.773,12.833
        elsif spacing_to_depth_ratio <= 0.1
          gfnc_coeff = 2.679,3.023,3.318,3.664,3.962,4.312,4.688,4.96,5.547,5.955,6.274,6.764,7.132,8.002,8.921,9.186,9.439,9.683,9.873,10.041,10.186,10.311,10.406,10.514,10.588,10.624,10.683
        elsif spacing_to_depth_ratio <= 0.15
          gfnc_coeff = 2.679,3.023,3.318,3.664,3.961,4.306,4.65,4.837,5.264,5.562,5.798,6.168,6.452,7.186,7.956,8.191,8.415,8.649,8.834,8.995,9.141,9.265,9.357,9.465,9.539,9.575,9.634
        end      
      elsif num_bore_holes == 6
        if spacing_to_depth_ratio <= 0.02
          gfnc_coeff = 2.683,3.057,3.452,4.086,4.779,5.8,7.06,8.162,9.74,10.701,11.385,12.334,12.987,14.439,15.684,16.027,16.335,16.638,16.877,17.083,17.264,17.417,17.532,17.665,17.756,17.801,17.874
        elsif spacing_to_depth_ratio <= 0.03
          gfnc_coeff = 2.679,3.025,3.341,3.782,4.278,5.029,5.992,6.87,8.226,9.081,9.704,10.59,11.212,12.596,13.828,14.168,14.473,14.773,15.007,15.211,15.388,15.538,15.652,15.783,15.872,15.916,15.987
        elsif spacing_to_depth_ratio <= 0.05
          gfnc_coeff = 2.679,3.023,3.319,3.671,4.005,4.493,5.143,5.726,6.747,7.42, 7.93,8.681,9.227,10.5,11.672,12.001,12.299,12.591,12.821,13.019,13.192,13.34,13.452,13.581,13.668,13.71,13.78
        elsif spacing_to_depth_ratio <= 0.1
          gfnc_coeff = 2.679,3.023,3.318,3.664,3.962,4.312,4.69,4.964,5.563,5.983, 6.314,6.828,7.218,8.159,9.179,9.479,9.766,10.045,10.265,10.458,10.627,10.773,10.883,11.01,11.096,11.138,11.207
        elsif spacing_to_depth_ratio <= 0.15
          gfnc_coeff = 2.679,3.023,3.318,3.664,3.961,4.306,4.65,4.838,5.268,5.57,5.811,6.191,6.485,7.256,8.082,8.339,8.586,8.848,9.055,9.238,9.404,9.546,9.653,9.778,9.864,9.907,9.976
        end      
      elsif num_bore_holes == 7
        if spacing_to_depth_ratio <= 0.02
          gfnc_coeff = 2.683,3.058,3.456,4.1,4.809,5.867,7.195,8.38,10.114,11.189,11.961,13.04,13.786,15.456,16.89,17.286,17.64,17.989,18.264,18.501,18.709,18.886,19.019,19.172,19.276,19.328,19.412
        elsif spacing_to_depth_ratio <= 0.03
          gfnc_coeff = 2.679,3.025,3.342,3.785,4.288,5.054,6.05,6.969,8.418,9.349,10.036,11.023,11.724,13.296,14.706,15.096,15.446,15.791,16.059,16.293,16.497,16.668,16.799,16.949,17.052,17.102,17.183
        elsif spacing_to_depth_ratio <= 0.05
          gfnc_coeff = 2.679,3.023,3.319,3.672,4.007,4.499,5.159,5.756,6.816,7.524,8.066,8.874,9.469,10.881,12.2,12.573,12.912,13.245,13.508,13.734,13.932,14.1,14.228,14.376,14.475,14.524,14.604
        elsif spacing_to_depth_ratio <= 0.1
          gfnc_coeff = 2.679,3.023,3.318,3.664,3.962,4.312,4.691,4.967,5.574,6.003,6.343,6.874,7.28,8.276,9.377,9.706,10.022,10.333,10.578,10.795,10.985,11.15,11.276,11.419,11.518,11.565,11.644
        elsif spacing_to_depth_ratio <= 0.15
          gfnc_coeff = 2.679,3.023,3.318,3.664,3.961,4.306,4.65,4.838,5.27,5.576,5.821,6.208,6.509,7.307,8.175,8.449,8.715,8.998,9.224,9.426,9.61,9.768,9.887,10.028,10.126,10.174,10.252
        end      
      elsif num_bore_holes == 8
        if spacing_to_depth_ratio <= 0.02
          gfnc_coeff = 2.683,3.059,3.459,4.11,4.832,5.918,7.3,8.55,10.416,11.59,12.442,13.641,14.475,16.351,17.97,18.417,18.817,19.211,19.522,19.789,20.024,20.223,20.373,20.546,20.664,20.721,20.816
        elsif spacing_to_depth_ratio <= 0.03
          gfnc_coeff = 2.679,3.025,3.342,3.788,4.295,5.073,6.093,7.045,8.567,9.56,10.301,11.376,12.147,13.892,15.472,15.911,16.304,16.692,16.993,17.257,17.486,17.679,17.826,17.995,18.111,18.167,18.259
        elsif spacing_to_depth_ratio <= 0.05
          gfnc_coeff = 2.679,3.023,3.319,3.672,4.008,4.503,5.171,5.779,6.868,7.603,8.17,9.024,9.659,11.187,12.64,13.055,13.432,13.804,14.098,14.351,14.573,14.762,14.905,15.07,15.182,15.237,15.326
        elsif spacing_to_depth_ratio <= 0.1
          gfnc_coeff = 2.679,3.023,3.318,3.664,3.962,4.312,4.692,4.97,5.583,6.018,6.364,6.909,7.327,8.366,9.531,9.883,10.225,10.562,10.83,11.069,11.28,11.463,11.602,11.762,11.872,11.925,12.013
        elsif spacing_to_depth_ratio <= 0.15
          gfnc_coeff = 2.679,3.023,3.318,3.664,3.961,4.306,4.65,4.838,5.272,5.58,5.828,6.22,6.527,7.345,8.246,8.533,8.814,9.114,9.356,9.573,9.772,9.944,10.076,10.231,10.34,10.393,10.481
        end
      elsif num_bore_holes == 9
        if spacing_to_depth_ratio <= 0.02
          gfnc_coeff = 2.683,3.06,3.461,4.118,4.849,5.958,7.383,8.687,10.665,11.927,12.851,14.159,15.075,17.149,18.947,19.443,19.888,20.326,20.672,20.969,21.23,21.452,21.618,21.81,21.941,22.005,22.11
        elsif spacing_to_depth_ratio <= 0.03
          gfnc_coeff = 2.679,3.025,3.342,3.79,4.301,5.088,6.127,7.105,8.686,9.732, 10.519,11.671,12.504,14.408,16.149,16.633,17.069,17.499,17.833,18.125,18.379,18.593,18.756,18.943,19.071,19.133,19.235
        elsif spacing_to_depth_ratio <= 0.05
          gfnc_coeff = 2.679,3.023,3.319,3.672,4.008,4.506,5.181,5.797,6.909,7.665,8.253,9.144,9.813,11.441,13.015,13.468,13.881,14.29,14.613,14.892,15.136,15.345,15.503,15.686,15.809,15.87,15.969
        elsif spacing_to_depth_ratio <= 0.1
          gfnc_coeff = 2.679,3.023,3.318,3.664,3.962,4.312,4.693,4.972,5.589,6.03, 6.381,6.936,7.364,8.436,9.655,10.027,10.391,10.751,11.04,11.298,11.527,11.726,11.879,12.054,12.175,12.234,12.331
        elsif spacing_to_depth_ratio <= 0.15
          gfnc_coeff = 2.679,3.023,3.318,3.664,3.961,4.306,4.65,4.838,5.273,5.584,5.833,6.23,6.541,7.375,8.302,8.6,8.892,9.208,9.463,9.692,9.905,10.089,10.231,10.4,10.518,10.576,10.673
        end      
      elsif num_bore_holes == 10
        if spacing_to_depth_ratio <= 0.02
          gfnc_coeff = 2.683,3.06,3.463,4.125,4.863,5.99,7.45,8.799,10.872,12.211,13.197,14.605,15.598,17.863,19.834,20.379,20.867,21.348,21.728,22.055,22.342,22.585,22.767,22.978,23.122,23.192,23.307
        elsif spacing_to_depth_ratio <= 0.03
          gfnc_coeff = 2.679,3.026,3.343,3.792,4.306,5.1,6.154,7.153,8.784,9.873,10.699,11.918,12.805,14.857,16.749,17.278,17.755,18.225,18.591,18.91,19.189,19.423,19.601,19.807,19.947,20.015,20.126
        elsif spacing_to_depth_ratio <= 0.05
          gfnc_coeff = 2.679,3.023,3.319,3.672,4.009,4.509,5.189,5.812,6.942,7.716,8.32,9.242,9.939,11.654,13.336,13.824,14.271,14.714,15.065,15.368,15.635,15.863,16.036,16.235,16.37,16.435,16.544
        elsif spacing_to_depth_ratio <= 0.1
          gfnc_coeff = 2.679,3.023,3.318,3.664,3.962,4.312,4.694,4.973,5.595,6.039,6.395,6.958,7.394,8.493,9.757,10.146,10.528,10.909,11.215, 11.491,11.736,11.951,12.116,12.306,12.437,12.501,12.607
        elsif spacing_to_depth_ratio <= 0.15
          gfnc_coeff = 2.679,3.023,3.318,3.664,3.961,4.306,4.65,4.838,5.275,5.587,5.837,6.238,6.552,7.399,8.347,8.654,8.956,9.283,9.549,9.79,10.014,10.209,10.36,10.541,10.669,10.732,10.837
        end      
      end
    elsif bore_config == Constants.BoreConfigLconfig    
      if num_bore_holes == 3
        if spacing_to_depth_ratio <= 0.02
          gfnc_coeff = 2.682,3.052,3.435,4.036,4.668,5.519,6.435,7.155,8.091,8.626,8.997,9.504,9.847,10.605,11.256,11.434,11.596,11.755,11.88,11.988,12.083,12.163,12.224,12.294,12.342,12.365,12.405
        elsif spacing_to_depth_ratio <= 0.03
          gfnc_coeff = 2.679,3.025,3.337,3.767,4.242,4.937,5.754,6.419,7.33,7.856,8.221,8.721,9.063,9.818,10.463,10.641,10.801,10.959,11.084,11.191,11.285,11.365,11.425,11.495,11.542,11.565,11.603
        elsif spacing_to_depth_ratio <= 0.05
          gfnc_coeff = 2.679,3.023,3.319,3.67,3.999,4.472,5.089,5.615,6.449,6.942,7.292,7.777,8.111,8.847,9.497,9.674,9.836,9.993,10.117,10.224,10.317,10.397,10.457,10.525,10.573,10.595,10.633
        elsif spacing_to_depth_ratio <= 0.1
          gfnc_coeff = 2.679,3.023,3.318,3.664,3.962,4.311,4.684,4.95,5.525,5.915,6.209,6.64,6.946,7.645,8.289,8.466,8.63,8.787,8.912,9.018,9.112,9.192,9.251,9.32,9.367,9.39,9.427
        elsif spacing_to_depth_ratio <= 0.15
          gfnc_coeff = 2.679,3.023,3.318,3.664,3.961,4.306,4.649,4.836,5.255,5.547,5.777,6.132,6.397,7.069,7.673,7.848,8.005,8.161,8.29,8.397,8.492,8.571,8.631,8.7,8.748,8.771,8.808
        end      
      elsif num_bore_holes == 4
        if spacing_to_depth_ratio <= 0.02
          gfnc_coeff = 2.683,3.055,3.446,4.075,4.759,5.729,6.841,7.753,8.96,9.659,10.147,10.813,11.266,12.265,13.122,13.356,13.569,13.778,13.942,14.084,14.208,14.314,14.393,14.485,14.548,14.579,14.63
        elsif spacing_to_depth_ratio <= 0.03
          gfnc_coeff = 2.679,3.025,3.339,3.777,4.27,5.015,5.945,6.739,7.875,8.547,9.018,9.668,10.116,11.107,11.953,12.186,12.395,12.603,12.766,12.906,13.029,13.133,13.212,13.303,13.365,13.395,13.445
        elsif spacing_to_depth_ratio <= 0.05
          gfnc_coeff = 2.679,3.023,3.319,3.671,4.003,4.488,5.137,5.713,6.678,7.274,7.707,8.319,8.747,9.698,10.543,10.774,10.984,11.19,11.351,11.49,11.612,11.715,11.793,11.882,11.944,11.974,12.022
        elsif spacing_to_depth_ratio <= 0.1
          gfnc_coeff = 2.679,3.023,3.318,3.664,3.962,4.311,4.688,4.959,5.558,5.976,6.302,6.794,7.155,8.008,8.819,9.044,9.255,9.456,9.618,9.755,9.877,9.98,10.057,10.146,10.207,10.236,10.285
        elsif spacing_to_depth_ratio <= 0.15
          gfnc_coeff = 2.679,3.023,3.318,3.664,3.961,4.306,4.649,4.837,5.263,5.563,5.804,6.183,6.473,7.243,7.969,8.185,8.382,8.58,8.743,8.88,9.001,9.104,9.181,9.27,9.332,9.361,9.409
        end
      elsif num_bore_holes == 5
        if spacing_to_depth_ratio <= 0.02
          gfnc_coeff = 2.683,3.057,3.453,4.097,4.806,5.842,7.083,8.14,9.579,10.427,11.023,11.841,12.399,13.633,14.691,14.98,15.242,15.499,15.701,15.877,16.03,16.159,16.257,16.37,16.448,16.485,16.549
        elsif spacing_to_depth_ratio <= 0.03
          gfnc_coeff = 2.679,3.025,3.34,3.783,4.285,5.054,6.038,6.915,8.219,9.012,9.576,10.362,10.907,12.121,13.161,13.448,13.705,13.96,14.16,14.332,14.483,14.61,14.707,14.819,14.895,14.932,14.993
        elsif spacing_to_depth_ratio <= 0.05
          gfnc_coeff = 2.679,3.023,3.319,3.671,4.005,4.497,5.162,5.76,6.796,7.461,7.954,8.665,9.17,10.31,11.338,11.62,11.877,12.127,12.324,12.494,12.643,12.77,12.865,12.974,13.049,13.085,13.145
        elsif spacing_to_depth_ratio <= 0.1
          gfnc_coeff = 2.679,3.023,3.318,3.664,3.962,4.312,4.69,4.964,5.575,6.006,6.347,6.871,7.263,8.219,9.164,9.432,9.684,9.926,10.121,10.287,10.434,10.56,10.654,10.762,10.836,10.872,10.93
        elsif spacing_to_depth_ratio <= 0.15
          gfnc_coeff = 2.679,3.023,3.318,3.664,3.961,4.306,4.65,4.837,5.267,5.573,5.819,6.208,6.51,7.33,8.136,8.384,8.613,8.844,9.037,9.2,9.345,9.468,9.562,9.67,9.744,9.78,9.839           
        end      
      elsif num_bore_holes == 6
        if spacing_to_depth_ratio <= 0.02
          gfnc_coeff = 2.683,3.058,3.457,4.111,4.837,5.916,7.247,8.41,10.042,11.024,11.72,12.681,13.339,14.799,16.054,16.396,16.706,17.011,17.25,17.458,17.639,17.792,17.907,18.041,18.133,18.177,18.253
        elsif spacing_to_depth_ratio <= 0.03
          gfnc_coeff = 2.679,3.025,3.341,3.786,4.296,5.08,6.099,7.031,8.456,9.346,9.988,10.894,11.528,12.951,14.177,14.516,14.819,15.12,15.357,15.56,15.737,15.888,16.002,16.134,16.223,16.267,16.338
        elsif spacing_to_depth_ratio <= 0.05
          gfnc_coeff = 2.679,3.023,3.319,3.671,4.007,4.503,5.178,5.791,6.872,7.583,8.119,8.905,9.472,10.774,11.969,12.3,12.6,12.895,13.126,13.326,13.501,13.649,13.761,13.89,13.977,14.02,14.09
        elsif spacing_to_depth_ratio <= 0.1
          gfnc_coeff = 2.679,3.023,3.318,3.664,3.962,4.312,4.691,4.968,5.586,6.026,6.375,6.919,7.331,8.357,9.407,9.71,9.997,10.275,10.501,10.694,10.865,11.011,11.121,11.247,11.334,11.376,11.445
        elsif spacing_to_depth_ratio <= 0.15
          gfnc_coeff = 2.679,3.023,3.318,3.664,3.961,4.306,4.65,4.838,5.27,5.579,5.828,6.225,6.535,7.384,8.244,8.515,8.768,9.026,9.244,9.428,9.595,9.737,9.845,9.97,10.057,10.099,10.168
        end      
      end
    elsif bore_config == Constants.BoreConfigL2config
      if num_bore_holes == 8
        if spacing_to_depth_ratio <= 0.02
          gfnc_coeff = 2.685,3.078,3.547,4.438,5.521,7.194,9.237,10.973,13.311,14.677,15.634,16.942,17.831,19.791,21.462,21.917,22.329,22.734,23.052,23.328,23.568,23.772,23.925,24.102,24.224,24.283,24.384
        elsif spacing_to_depth_ratio <= 0.03
          gfnc_coeff = 2.679,3.027,3.354,3.866,4.534,5.682,7.271,8.709,10.845,12.134,13.046,14.308,15.177,17.106,18.741,19.19,19.592,19.989,20.303,20.57,20.805,21.004,21.155,21.328,21.446,21.504,21.598
        elsif spacing_to_depth_ratio <= 0.05
          gfnc_coeff = 2.679,3.023,3.319,3.676,4.034,4.639,5.587,6.514,8.195,9.283,10.09,11.244,12.058,13.88,15.491,15.931,16.328,16.716,17.02,17.282,17.511,17.706,17.852,18.019,18.134,18.19,18.281
        elsif spacing_to_depth_ratio <= 0.1
          gfnc_coeff = 2.679,3.023,3.318,3.664,3.962,4.315,4.72,5.041,5.874,6.525,7.06,7.904,8.541,10.093,11.598,12.018,12.41,12.784,13.084,13.338,13.562,13.753,13.895,14.058,14.169,14.223,14.312
        elsif spacing_to_depth_ratio <= 0.15
          gfnc_coeff = 2.679,3.023,3.318,3.664,3.961,4.307,4.653,4.842,5.325,5.717,6.058,6.635,7.104,8.419,9.714,10.108,10.471,10.834,11.135,11.387,11.61,11.798,11.94,12.103,12.215,12.268,12.356
        end      
      elsif num_bore_holes == 10
        if spacing_to_depth_ratio <= 0.02
          gfnc_coeff = 2.685,3.08,3.556,4.475,5.611,7.422,9.726,11.745,14.538,16.199,17.369,18.975,20.071,22.489,24.551,25.111,25.619,26.118,26.509,26.848,27.143,27.393,27.582,27.8,27.949,28.022,28.146
        elsif spacing_to_depth_ratio <= 0.03
          gfnc_coeff = 2.679,3.027,3.356,3.874,4.559,5.758,7.466,9.07,11.535,13.06,14.153,15.679,16.739,19.101,21.106,21.657,22.15,22.637,23.021,23.348,23.635,23.879,24.063,24.275,24.42,24.49,24.605
        elsif spacing_to_depth_ratio <= 0.05
          gfnc_coeff = 2.679,3.023,3.319,3.676,4.037,4.653,5.634,6.61,8.44,9.664,10.589,11.936,12.899,15.086,17.041,17.575,18.058,18.53,18.9,19.218,19.496,19.733,19.91,20.113,20.252,20.32,20.431
        elsif spacing_to_depth_ratio <= 0.1
          gfnc_coeff = 2.679,3.023,3.318,3.664,3.962,4.315,4.723,5.048,5.904,6.584,7.151,8.062,8.764,10.521,12.281,12.779,13.246,13.694,14.054,14.36,14.629,14.859,15.03,15.226,15.36,15.425,15.531
        elsif spacing_to_depth_ratio <= 0.15
          gfnc_coeff = 2.679,3.023,3.318,3.664,3.961,4.307,4.653,4.842,5.331,5.731,6.083,6.683,7.178,8.6,10.054,10.508,10.929,11.356,11.711,12.009,12.275,12.5,12.671,12.866,13,13.064,13.17
        end
      end
    elsif bore_config == Constants.BoreConfigUconfig
      if num_bore_holes == 5
        if spacing_to_depth_ratio <= 0.02
          gfnc_coeff = 2.683,3.057,3.46,4.134,4.902,6.038,7.383,8.503,9.995,10.861,11.467,12.294,12.857,14.098,15.16,15.449,15.712,15.97,16.173,16.349,16.503,16.633,16.731,16.844,16.922,16.96,17.024
        elsif spacing_to_depth_ratio <= 0.03
          gfnc_coeff = 2.679,3.025,3.341,3.789,4.31,5.136,6.219,7.172,8.56,9.387,9.97,10.774,11.328,12.556,13.601,13.889,14.147,14.403,14.604,14.777,14.927,15.056,15.153,15.265,15.341,15.378,15.439
        elsif spacing_to_depth_ratio <= 0.05
          gfnc_coeff = 2.679,3.023,3.319,3.671,4.007,4.51,5.213,5.864,6.998,7.717,8.244,8.993,9.518,10.69,11.73,12.015,12.273,12.525,12.723,12.893,13.043,13.17,13.265,13.374,13.449,13.486,13.546
        elsif spacing_to_depth_ratio <= 0.1
          gfnc_coeff = 2.679,3.023,3.318,3.664,3.962,4.312,4.692,4.969,5.607,6.072,6.444,7.018,7.446,8.474,9.462,9.737,9.995,10.241,10.438,10.606,10.754,10.88,10.975,11.083,11.157,11.193,11.252
        elsif spacing_to_depth_ratio <= 0.15
          gfnc_coeff = 2.679,3.023,3.318,3.664,3.961,4.306,4.65,4.838,5.27,5.585,5.843,6.26,6.588,7.486,8.353,8.614,8.854,9.095,9.294,9.46,9.608,9.733,9.828,9.936,10.011,10.047,10.106
        end
      elsif num_bore_holes == 7
        if spacing_to_depth_ratio <= 0.02
          gfnc_coeff = 2.683,3.059,3.467,4.164,4.994,6.319,8.011,9.482,11.494,12.679,13.511,14.651,15.427,17.139,18.601,18.999,19.359,19.714,19.992,20.233,20.443,20.621,20.755,20.91,21.017,21.069,21.156
        elsif spacing_to_depth_ratio <= 0.03
          gfnc_coeff = 2.679,3.025,3.342,3.795,4.329,5.214,6.465,7.635,9.435,10.54,11.327,12.421,13.178,14.861,16.292,16.685,17.038,17.386,17.661,17.896,18.101,18.276,18.408,18.56,18.663,18.714,18.797
        elsif spacing_to_depth_ratio <= 0.05
          gfnc_coeff = 2.679,3.023,3.319,3.672,4.009,4.519,5.253,5.965,7.304,8.204,8.882,9.866,10.566,12.145,13.555,13.941,14.29,14.631,14.899,15.129,15.331,15.502,15.631,15.778,15.879,15.928,16.009
        elsif spacing_to_depth_ratio <= 0.1
          gfnc_coeff = 2.679,3.023,3.318,3.664,3.962,4.312,4.694,4.975,5.629,6.127,6.54,7.207,7.723,9.019,10.314,10.68,11.023,11.352,11.617,11.842,12.04,12.209,12.335,12.48,12.579,12.627,12.705
        elsif spacing_to_depth_ratio <= 0.15
          gfnc_coeff = 2.679,3.023,3.318,3.664,3.961,4.306,4.65,4.838,5.275,5.595,5.861,6.304,6.665,7.709,8.785,9.121,9.434,9.749,10.013,10.233,10.43,10.597,10.723,10.868,10.967,11.015,11.094
        end
      elsif num_bore_holes == 9
        if spacing_to_depth_ratio <= 0.02
          gfnc_coeff = 2.683,3.061,3.47,4.178,5.039,6.472,8.405,10.147,12.609,14.086, 15.131,16.568,17.55,19.72,21.571,22.073,22.529,22.976,23.327,23.632,23.896,24.121,24.29,24.485,24.619,24.684,24.795
        elsif spacing_to_depth_ratio <= 0.03
          gfnc_coeff = 2.679,3.025,3.343,3.798,4.338,5.248,6.588,7.902,10.018,11.355,12.321,13.679,14.625,16.74,18.541,19.036,19.478,19.916,20.261,20.555,20.812,21.031,21.197,21.387,21.517,21.58,21.683
        elsif spacing_to_depth_ratio <= 0.05
          gfnc_coeff = 2.679,3.023,3.319,3.672,4.01,4.524,5.27,6.01,7.467,8.489,9.281,10.452,11.299,13.241,14.995,15.476,15.912,16.337,16.67,16.957,17.208,17.421,17.581,17.764,17.889,17.95,18.05
        elsif spacing_to_depth_ratio <= 0.1
          gfnc_coeff = 2.679,3.023,3.318,3.664,3.962,4.312,4.695,4.977,5.639,6.15,6.583,7.298,7.869,9.356,10.902,11.347,11.766,12.169,12.495,12.772,13.017,13.225,13.381,13.559,13.681,13.74,13.837
        elsif spacing_to_depth_ratio <= 0.15
          gfnc_coeff = 2.679,3.023,3.318,3.664,3.961,4.306,4.65,4.838,5.277,5.6,5.87,6.322,6.698,7.823,9.044,9.438,9.809,10.188,10.506,10.774,11.015,11.219,11.374,11.552,11.674,11.733,11.83
        end
      end
    elsif bore_config == Constants.BoreConfigOpenRectangle
      if num_bore_holes == 8
        if spacing_to_depth_ratio <= 0.02
          gfnc_coeff = 2.684,3.066,3.497,4.275,5.229,6.767,8.724,10.417,12.723,14.079,15.03,16.332,17.217,19.17,20.835,21.288,21.698,22.101,22.417,22.692,22.931,23.133,23.286,23.462,23.583,23.642,23.742
        elsif spacing_to_depth_ratio <= 0.03
          gfnc_coeff = 2.679,3.026,3.347,3.821,4.409,5.418,6.87,8.226,10.299,11.565,12.466,13.716,14.58,16.498,18.125,18.572,18.972,19.368,19.679,19.946,20.179,20.376,20.527,20.699,20.816,20.874,20.967
        elsif spacing_to_depth_ratio <= 0.05
          gfnc_coeff = 2.679,3.023,3.319,3.673,4.018,4.564,5.389,6.21,7.763,8.801,9.582,10.709,11.51,13.311,14.912,15.349,15.744,16.13,16.432,16.693,16.921,17.114,17.259,17.426,17.54,17.595,17.686
        elsif spacing_to_depth_ratio <= 0.1
          gfnc_coeff = 2.679,3.023,3.318,3.664,3.962,4.313,4.704,4.999,5.725,6.294,6.771,7.543,8.14,9.629,11.105,11.52,11.908,12.28,12.578,12.831,13.054,13.244,13.386,13.548,13.659,13.712,13.8
        elsif spacing_to_depth_ratio <= 0.15
          gfnc_coeff = 2.679,3.023,3.318,3.664,3.961,4.306,4.651,4.839,5.293,5.641,5.938,6.44,6.856,8.062,9.297,9.681,10.036,10.394,10.692,10.941,11.163,11.35,11.492,11.654,11.766,11.819,11.907
        end      
      elsif num_bore_holes == 10
        if spacing_to_depth_ratio <= 0.02
          gfnc_coeff = 2.684,3.066,3.494,4.262,5.213,6.81,8.965,10.906,13.643,15.283,16.443,18.038,19.126,21.532,23.581,24.138,24.642,25.137,25.525,25.862,26.155,26.403,26.59,26.806,26.955,27.027,27.149
        elsif spacing_to_depth_ratio <= 0.03
          gfnc_coeff = 2.679,3.026,3.346,3.818,4.399,5.4,6.889,8.358,10.713,12.198,13.27,14.776,15.824,18.167,20.158,20.704,21.194,21.677,22.057,22.382,22.666,22.907,23.09,23.3,23.443,23.513,23.627
        elsif spacing_to_depth_ratio <= 0.05
          gfnc_coeff = 2.679,3.023,3.319,3.673,4.018,4.559,5.374,6.193,7.814,8.951,9.831,11.13,12.069,14.219,16.154,16.684,17.164,17.631,17.998,18.314,18.59,18.824,19,19.201,19.338,19.405,19.515
        elsif spacing_to_depth_ratio <= 0.1
          gfnc_coeff = 2.679,3.023,3.318,3.664,3.962,4.313,4.703,4.996,5.712,6.275,6.755,7.549,8.183,9.832,11.54,12.029,12.49,12.933,13.29,13.594,13.862,14.09,14.26,14.455,14.588,14.652,14.758
        elsif spacing_to_depth_ratio <= 0.15
          gfnc_coeff = 2.679,3.023,3.318,3.664,3.961,4.306,4.651,4.839,5.292,5.636,5.928,6.425,6.841,8.089,9.44,9.875,10.284,10.7,11.05,11.344,11.608,11.831,12.001,12.196,12.329,12.393,12.499
        end      
      end      
    elsif bore_config == Constants.BoreConfigRectangle
      if num_bore_holes == 4
        if spacing_to_depth_ratio <= 0.02
          gfnc_coeff = 2.684,3.066,3.493,4.223,5.025,6.131,7.338,8.291,9.533,10.244,10.737,11.409,11.865,12.869,13.73,13.965,14.178,14.388,14.553,14.696,14.821,14.927,15.007,15.099,15.162,15.193,15.245
        elsif spacing_to_depth_ratio <= 0.03
          gfnc_coeff = 2.679,3.026,3.347,3.818,4.383,5.255,6.314,7.188,8.392,9.087,9.571,10.233,10.686,11.685,12.536,12.77,12.98,13.189,13.353,13.494,13.617,13.721,13.801,13.892,13.955,13.985,14.035
        elsif spacing_to_depth_ratio <= 0.05
          gfnc_coeff = 2.679,3.023,3.319,3.673,4.018,4.555,5.313,5.984,7.069,7.717,8.177,8.817,9.258,10.229,11.083,11.316,11.527,11.733,11.895,12.035,12.157,12.261,12.339,12.429,12.491,12.521,12.57
        elsif spacing_to_depth_ratio <= 0.1
          gfnc_coeff = 2.679,3.023,3.318,3.664,3.962,4.313,4.703,4.998,5.69,6.18,6.557,7.115,7.514,8.428,9.27,9.501,9.715,9.92,10.083,10.221,10.343,10.447,10.525,10.614,10.675,10.704,10.753
        elsif spacing_to_depth_ratio <= 0.15
          gfnc_coeff = 2.679,3.023,3.318,3.664,3.961,4.306,4.651,4.839,5.293,5.633,5.913,6.355,6.693,7.559,8.343,8.57,8.776,8.979,9.147,9.286,9.409,9.512,9.59,9.68,9.741,9.771,9.819
        end            
      elsif num_bore_holes == 6
        if spacing_to_depth_ratio <= 0.02
          gfnc_coeff = 2.684,3.074,3.526,4.349,5.308,6.719,8.363,9.72,11.52,12.562,13.289,14.282,14.956,16.441,17.711,18.057,18.371,18.679,18.921,19.132,19.315,19.47,19.587,19.722,19.815,19.861,19.937
        elsif spacing_to_depth_ratio <= 0.03
          gfnc_coeff = 2.679,3.026,3.351,3.847,4.472,5.499,6.844,8.016,9.702,10.701,11.403,12.369,13.032,14.502,15.749,16.093,16.4,16.705,16.945,17.15,17.329,17.482,17.598,17.731,17.822,17.866,17.938
        elsif spacing_to_depth_ratio <= 0.05
          gfnc_coeff = 2.679,3.023,3.319,3.675,4.028,4.605,5.471,6.283,7.688,8.567,9.207,10.112,10.744,12.149,13.389,13.727,14.033,14.332,14.567,14.769,14.946,15.096,15.21,15.339,15.428,15.471,15.542
        elsif spacing_to_depth_ratio <= 0.1
          gfnc_coeff = 2.679,3.023,3.318,3.664,3.962,4.314,4.714,5.024,5.798,6.378,6.841,7.553,8.079,9.327,10.512,10.84,11.145,11.437,11.671,11.869,12.044,12.192,12.303,12.431,12.518,12.56,12.629
        elsif spacing_to_depth_ratio <= 0.15
          gfnc_coeff = 2.679,3.023,3.318,3.664,3.961,4.307,4.652,4.841,5.313,5.684,5.999,6.517,6.927,8.034,9.087,9.401,9.688,9.974,10.21,10.408,10.583,10.73,10.841,10.969,11.056,11.098,11.167
        end            
      elsif num_bore_holes == 8
        if spacing_to_depth_ratio <= 0.02
          gfnc_coeff = 2.685,3.078,3.543,4.414,5.459,7.06,9.021,10.701,12.991,14.34,15.287,16.586,17.471,19.423,21.091,21.545,21.956,22.36,22.677,22.953,23.192,23.395,23.548,23.725,23.847,23.906,24.006
        elsif spacing_to_depth_ratio <= 0.03
          gfnc_coeff = 2.679,3.027,3.354,3.862,4.517,5.627,7.142,8.525,10.589,11.846,12.741,13.986,14.847,16.762,18.391,18.839,19.24,19.637,19.95,20.217,20.45,20.649,20.8,20.973,21.091,21.148,21.242
        elsif spacing_to_depth_ratio <= 0.05
          gfnc_coeff = 2.679,3.023,3.319,3.675,4.033,4.63,5.553,6.444,8.051,9.096,9.874,10.995,11.79,13.583,15.182,15.619,16.016,16.402,16.705,16.967,17.195,17.389,17.535,17.702,17.817,17.873,17.964
        elsif spacing_to_depth_ratio <= 0.1
          gfnc_coeff = 2.679,3.023,3.318,3.664,3.962,4.315,4.719,5.038,5.852,6.48,6.993,7.799,8.409,9.902,11.371,11.784,12.17,12.541,12.839,13.092,13.315,13.505,13.647,13.81,13.921,13.975,14.063
        elsif spacing_to_depth_ratio <= 0.15
          gfnc_coeff = 2.679,3.023,3.318,3.664,3.961,4.307,4.653,4.842,5.323,5.71,6.042,6.6,7.05,8.306,9.552,9.935,10.288,10.644,10.94,11.188,11.409,11.596,11.738,11.9,12.011,12.065,12.153
        end      
      elsif num_bore_holes == 9
        if spacing_to_depth_ratio <= 0.02
          gfnc_coeff = 2.685,3.082,3.561,4.49,5.635,7.436,9.672,11.59,14.193,15.721,16.791,18.256,19.252,21.447,23.318,23.826,24.287,24.74,25.095,25.404,25.672,25.899,26.071,26.269,26.405,26.471,26.583
        elsif spacing_to_depth_ratio <= 0.03
          gfnc_coeff = 2.679,3.027,3.357,3.879,4.57,5.781,7.488,9.052,11.408,12.84,13.855,15.263,16.235,18.39,20.216,20.717,21.166,21.61,21.959, 22.257,22.519,22.74,22.909,23.102,23.234,23.298,23.403
        elsif spacing_to_depth_ratio <= 0.05
          gfnc_coeff = 2.679,3.023,3.319,3.676,4.039,4.659,5.65,6.633,8.447,9.638,10.525,11.802,12.705,14.731,16.525,17.014,17.456,17.887,18.225,18.516,18.77,18.986,19.148,19.334,19.461,19.523,19.625
        elsif spacing_to_depth_ratio <= 0.1
          gfnc_coeff = 2.679,3.023,3.318,3.664,3.962,4.316,4.725,5.052,5.917,6.603,7.173,8.08,8.772,10.47,12.131,12.596,13.029,13.443,13.775,14.057,14.304,14.515,14.673,14.852,14.975,15.035,15.132
        elsif spacing_to_depth_ratio <= 0.15
          gfnc_coeff = 2.679,3.023,3.318,3.664,3.961,4.307,4.653,4.842,5.334,5.739,6.094,6.7,7.198,8.611,10.023,10.456,10.855,11.256,11.588,11.866,12.112,12.32,12.477,12.656,12.779,12.839,12.935
        end      
      elsif num_bore_holes == 10
        if spacing_to_depth_ratio <= 0.02
          gfnc_coeff = 2.685,3.08,3.553,4.453,5.552,7.282,9.472,11.405,14.111,15.737,16.888,18.476,19.562,21.966,24.021,24.579,25.086,25.583,25.973,26.311,26.606,26.855,27.043,27.26,27.409,27.482,27.605
        elsif spacing_to_depth_ratio <= 0.03
          gfnc_coeff = 2.679,3.027,3.355,3.871,4.545,5.706,7.332,8.863,11.218,12.688,13.749,15.242,16.284,18.618,20.613,21.161,21.652,22.138,22.521,22.847,23.133,23.376,23.56,23.771,23.915,23.985,24.1
        elsif spacing_to_depth_ratio <= 0.05
          gfnc_coeff = 2.679,3.023,3.319,3.676,4.036,4.645,5.603,6.543,8.285,9.449,10.332,11.623,12.553,14.682,16.613,17.143,17.624,18.094,18.462,18.78,19.057,19.293,19.47,19.673,19.811,19.879,19.989
        elsif spacing_to_depth_ratio <= 0.1
          gfnc_coeff = 2.679,3.023,3.318,3.664,3.962,4.315,4.722,5.045,5.885,6.543,7.086,7.954,8.621,10.291,11.988,12.473,12.931,13.371,13.727,14.03,14.299,14.527,14.698,14.894,15.027,15.092,15.199
        elsif spacing_to_depth_ratio <= 0.15
          gfnc_coeff = 2.679,3.023,3.318,3.664,3.961,4.307,4.653,4.842,5.329,5.725,6.069,6.651,7.126,8.478,9.863,10.298,10.704,11.117,11.463,11.755,12.016,12.239,12.407,12.602,12.735,12.8,12.906
        end         
      end
    end
    return gfnc_coeff
  end
  
end

# register the measure to be used by the application
ProcessGroundSourceHeatPumpVerticalBore.new.registerWithApplication
