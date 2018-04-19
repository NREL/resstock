# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"
require "#{File.dirname(__FILE__)}/resources/hvac"

# start the measure
class ProcessVRFMinisplit < OpenStudio::Measure::ModelMeasure

  # human readable name
  def name
    return "Set Residential Mini-Split Heat Pump"
  end

  # human readable description
  def description
    return "This measure removes any existing HVAC components from the building and adds a mini-split heat pump. For multifamily buildings, the mini-split heat pump can be set for all units of the building.#{Constants.WorkflowDescription}"
  end

  # human readable description of modeling approach
  def modeler_description
    return "Any supply components or baseboard convective electrics/waters are removed from any existing air/plant loops or zones. Any existing air/plant loops are also removed. A heating DX coil, cooling DX coil, and an on/off supply fan are added to a variable refrigerant flow terminal unit."
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new
    
    #make a double argument for minisplit cooling rated seer
    seer = OpenStudio::Measure::OSArgument::makeDoubleArgument("seer", true)
    seer.setDisplayName("Rated SEER")
    seer.setUnits("Btu/W-h")
    seer.setDescription("Seasonal Energy Efficiency Ratio (SEER) is a measure of equipment energy efficiency over the cooling season.")
    seer.setDefaultValue(14.5)
    args << seer 
    
    #make a double argument for minisplit rated hspf
    hspf = OpenStudio::Measure::OSArgument::makeDoubleArgument("hspf", true)
    hspf.setDisplayName("Rated HSPF")
    hspf.setUnits("Btu/W-h")
    hspf.setDescription("The Heating Seasonal Performance Factor (HSPF) is a measure of a heat pump's energy efficiency over one heating season.")
    hspf.setDefaultValue(8.2)
    args << hspf
    
    #make a double argument for minisplit rated shr
    shr = OpenStudio::Measure::OSArgument::makeDoubleArgument("shr", true)
    shr.setDisplayName("Rated SHR")
    shr.setDescription("The sensible heat ratio (ratio of the sensible portion of the load to the total load) at the nominal rated capacity.")
    shr.setDefaultValue(0.73)
    args << shr        
    
    #make a double argument for minisplit cooling min capacity
    min_cooling_capacity = OpenStudio::Measure::OSArgument::makeDoubleArgument("min_cooling_capacity", true)
    min_cooling_capacity.setDisplayName("Minimum Cooling Capacity")
    min_cooling_capacity.setUnits("frac")
    min_cooling_capacity.setDescription("Minimum cooling capacity as a fraction of the nominal cooling capacity at rated conditions.")
    min_cooling_capacity.setDefaultValue(0.4)
    args << min_cooling_capacity     
    
    #make a double argument for minisplit cooling max capacity
    max_cooling_capacity = OpenStudio::Measure::OSArgument::makeDoubleArgument("max_cooling_capacity", true)
    max_cooling_capacity.setDisplayName("Maximum Cooling Capacity")
    max_cooling_capacity.setUnits("frac")
    max_cooling_capacity.setDescription("Maximum cooling capacity as a fraction of the nominal cooling capacity at rated conditions.")
    max_cooling_capacity.setDefaultValue(1.2)
    args << max_cooling_capacity    
    
    #make a double argument for minisplit cooling min airflow
    min_cooling_airflow_rate = OpenStudio::Measure::OSArgument::makeDoubleArgument("min_cooling_airflow_rate", true)
    min_cooling_airflow_rate.setDisplayName("Minimum Cooling Airflow")
    min_cooling_airflow_rate.setUnits("cfm/ton")
    min_cooling_airflow_rate.setDescription("Minimum cooling cfm divided by the nominal rated cooling capacity.")
    min_cooling_airflow_rate.setDefaultValue(200.0)
    args << min_cooling_airflow_rate      
    
    #make a double argument for minisplit cooling max airflow
    max_cooling_airflow_rate = OpenStudio::Measure::OSArgument::makeDoubleArgument("max_cooling_airflow_rate", true)
    max_cooling_airflow_rate.setDisplayName("Maximum Cooling Airflow")
    max_cooling_airflow_rate.setUnits("cfm/ton")
    max_cooling_airflow_rate.setDescription("Maximum cooling cfm divided by the nominal rated cooling capacity.")
    max_cooling_airflow_rate.setDefaultValue(425.0)
    args << max_cooling_airflow_rate     
    
    #make a double argument for minisplit heating min capacity
    min_heating_capacity = OpenStudio::Measure::OSArgument::makeDoubleArgument("min_heating_capacity", true)
    min_heating_capacity.setDisplayName("Minimum Heating Capacity")
    min_heating_capacity.setUnits("frac")
    min_heating_capacity.setDescription("Minimum heating capacity as a fraction of nominal heating capacity at rated conditions.")
    min_heating_capacity.setDefaultValue(0.3)
    args << min_heating_capacity     
    
    #make a double argument for minisplit heating max capacity
    max_heating_capacity = OpenStudio::Measure::OSArgument::makeDoubleArgument("max_heating_capacity", true)
    max_heating_capacity.setDisplayName("Maximum Heating Capacity")
    max_heating_capacity.setUnits("frac")
    max_heating_capacity.setDescription("Maximum heating capacity as a fraction of nominal heating capacity at rated conditions.")
    max_heating_capacity.setDefaultValue(1.2)
    args << max_heating_capacity        
    
    #make a double argument for minisplit heating min airflow
    min_heating_airflow_rate = OpenStudio::Measure::OSArgument::makeDoubleArgument("min_heating_airflow_rate", true)
    min_heating_airflow_rate.setDisplayName("Minimum Heating Airflow")
    min_heating_airflow_rate.setUnits("cfm/ton")
    min_heating_airflow_rate.setDescription("Minimum heating cfm divided by the nominal rated heating capacity.")
    min_heating_airflow_rate.setDefaultValue(200.0)
    args << min_heating_airflow_rate     
    
    #make a double argument for minisplit heating min airflow
    max_heating_airflow_rate = OpenStudio::Measure::OSArgument::makeDoubleArgument("max_heating_airflow_rate", true)
    max_heating_airflow_rate.setDisplayName("Maximum Heating Airflow")
    max_heating_airflow_rate.setUnits("cfm/ton")
    max_heating_airflow_rate.setDescription("Maximum heating cfm divided by the nominal rated heating capacity.")
    max_heating_airflow_rate.setDefaultValue(400.0)
    args << max_heating_airflow_rate         
    
    #make a double argument for minisplit heating capacity offset
    heating_capacity_offset = OpenStudio::Measure::OSArgument::makeDoubleArgument("heating_capacity_offset", true)
    heating_capacity_offset.setDisplayName("Heating Capacity Offset")
    heating_capacity_offset.setUnits("Btu/hr")
    heating_capacity_offset.setDescription("The difference between the nominal rated heating capacity and the nominal rated cooling capacity.")
    heating_capacity_offset.setDefaultValue(2300.0)
    args << heating_capacity_offset    
    
    #make a double argument for minisplit capacity retention fraction
    cap_retention_frac = OpenStudio::Measure::OSArgument::makeDoubleArgument("cap_retention_frac", true)
    cap_retention_frac.setDisplayName("Heating Capacity Retention Fraction")
    cap_retention_frac.setUnits("frac")
    cap_retention_frac.setDescription("The maximum heating capacity at X degrees divided by the maximum heating capacity at 47 degrees F.")
    cap_retention_frac.setDefaultValue(0.25)
    args << cap_retention_frac
    
    #make a double argument for minisplit capacity retention temperature
    cap_retention_temp = OpenStudio::Measure::OSArgument::makeDoubleArgument("cap_retention_temp", true)
    cap_retention_temp.setDisplayName("Heating Capacity Retention Temperature")
    cap_retention_temp.setUnits("degrees F")
    cap_retention_temp.setDescription("The outdoor drybulb temperature at which the heating capacity retention fraction is defined.")
    cap_retention_temp.setDefaultValue(-5.0)
    args << cap_retention_temp    
    
    #make a double argument for minisplit pan heater power
    pan_heater_power = OpenStudio::Measure::OSArgument::makeDoubleArgument("pan_heater_power", true)
    pan_heater_power.setDisplayName("Pan Heater")
    pan_heater_power.setUnits("W/unit")
    pan_heater_power.setDescription("Prevents ice build up from damaging the coil.")
    pan_heater_power.setDefaultValue(0.0)
    args << pan_heater_power    
    
    #make a double argument for minisplit supply fan power
    fan_power = OpenStudio::Measure::OSArgument::makeDoubleArgument("fan_power", true)
    fan_power.setDisplayName("Supply Fan Power")
    fan_power.setUnits("W/cfm")
    fan_power.setDescription("Fan power (in W) per delivered airflow rate (in cfm) of the fan.")
    fan_power.setDefaultValue(0.07)
    args << fan_power

    #make a bool argument for whether the minisplit is ducted or ductless
    is_ducted = OpenStudio::Measure::OSArgument::makeBoolArgument("is_ducted", true)
    is_ducted.setDisplayName("Is Ducted")
    is_ducted.setDescription("Specified whether the mini-split heat pump is ducted or ductless.")
    is_ducted.setDefaultValue(false)
    args << is_ducted
    
    #make a string argument for minisplit cooling output capacity
    heat_pump_capacity = OpenStudio::Measure::OSArgument::makeStringArgument("heat_pump_capacity", true)
    heat_pump_capacity.setDisplayName("Heat Pump Capacity")
    heat_pump_capacity.setDescription("The output cooling capacity of the heat pump. If using '#{Constants.SizingAuto}', the autosizing algorithm will use ACCA Manual S to set the heat pump capacity based on the cooling load, with up to 1.3x oversizing allowed for variable-speed equipment in colder climates when the heating load exceeds the cooling load. If using '#{Constants.SizingAutoMaxLoad}', the autosizing algorithm will override ACCA Manual S and use the maximum of the heating and cooling loads to set the heat pump capacity, based on the heating/cooling capacities under design conditions.")
    heat_pump_capacity.setUnits("tons")
    heat_pump_capacity.setDefaultValue(Constants.SizingAuto)
    args << heat_pump_capacity

    #make an argument for entering supplemental efficiency
    supplemental_efficiency = OpenStudio::Measure::OSArgument::makeDoubleArgument("supplemental_efficiency",true)
    supplemental_efficiency.setDisplayName("Supplemental Efficiency")
    supplemental_efficiency.setUnits("Btu/Btu")
    supplemental_efficiency.setDescription("The efficiency of the supplemental electric baseboard.")
    supplemental_efficiency.setDefaultValue(1.0)
    args << supplemental_efficiency

    #make a string argument for supplemental heating output capacity
    supplemental_capacity = OpenStudio::Measure::OSArgument::makeStringArgument("supplemental_capacity", true)
    supplemental_capacity.setDisplayName("Supplemental Heating Capacity")
    supplemental_capacity.setDescription("The output heating capacity of the supplemental electric baseboard. If using '#{Constants.SizingAuto}', the autosizing algorithm will use ACCA Manual S to set the supplemental heating capacity.")
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
    
    seer = runner.getDoubleArgumentValue("seer",user_arguments) 
    hspf = runner.getDoubleArgumentValue("hspf",user_arguments) 
    shr = runner.getDoubleArgumentValue("shr",user_arguments)    
    min_cooling_capacity = runner.getDoubleArgumentValue("min_cooling_capacity",user_arguments) 
    max_cooling_capacity = runner.getDoubleArgumentValue("max_cooling_capacity",user_arguments) 
    min_cooling_airflow_rate = runner.getDoubleArgumentValue("min_cooling_airflow_rate",user_arguments) 
    max_cooling_airflow_rate = runner.getDoubleArgumentValue("max_cooling_airflow_rate",user_arguments) 
    min_heating_capacity = runner.getDoubleArgumentValue("min_heating_capacity",user_arguments) 
    max_heating_capacity = runner.getDoubleArgumentValue("max_heating_capacity",user_arguments) 
    min_heating_airflow_rate = runner.getDoubleArgumentValue("min_heating_airflow_rate",user_arguments) 
    max_heating_airflow_rate = runner.getDoubleArgumentValue("max_heating_airflow_rate",user_arguments)
    heating_capacity_offset = runner.getDoubleArgumentValue("heating_capacity_offset",user_arguments) 
    cap_retention_frac = runner.getDoubleArgumentValue("cap_retention_frac",user_arguments)
    cap_retention_temp = runner.getDoubleArgumentValue("cap_retention_temp",user_arguments)
    pan_heater_power = runner.getDoubleArgumentValue("pan_heater_power",user_arguments)    
    fan_power = runner.getDoubleArgumentValue("fan_power",user_arguments)
    is_ducted = runner.getBoolArgumentValue("is_ducted",user_arguments)
    heat_pump_capacity = runner.getStringArgumentValue("heat_pump_capacity",user_arguments)
    unless heat_pump_capacity == Constants.SizingAuto or heat_pump_capacity == Constants.SizingAutoMaxLoad
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
    
<<<<<<< HEAD
    number_Speeds = 10
    max_defrost_temp = 40.0 # F
    min_hp_temp = -30.0 # F; Minimum temperature for Heat Pump operation
    static = UnitConversions.convert(0.1,"inH2O","Pa") # Pascal
        
    # Performance curves
    
    # NOTE: These coefficients are in SI UNITS
    cOOL_CAP_FT_SPEC = [[1.008993521905866, 0.006512749025457, 0.0, 0.003917565735935, -0.000222646705889, 0.0]] * number_Speeds
    cOOL_EIR_FT_SPEC = [[0.429214441601141, -0.003604841598515, 0.000045783162727, 0.026490875804937, -0.000159212286878, -0.000159062656483]] * number_Speeds                
    cOOL_CAP_FFLOW_SPEC = [[1, 0, 0]] * number_Speeds
    
    # Mini-Split Heat Pump Heating Curve Coefficients
    # Derive coefficients from user input for capacity retention at outdoor drybulb temperature X [C].
    # Biquadratic: capacity multiplier = a + b*IAT + c*IAT^2 + d*OAT + e*OAT^2 + f*IAT*OAT
    x_A = UnitConversions.convert(miniSplitHPCapacityRetentionTemperature,"F", "C")
    y_A = miniSplitHPCapacityRetentionFraction
    x_B = UnitConversions.convert(47.0,"F","C") # 47F is the rating point
    y_B = 1.0 # Maximum capacity factor is 1 at the rating point, by definition (this is maximum capacity, not nominal capacity)
    oat_slope = (y_B - y_A) / (x_B - x_A)
    oat_intercept = y_A - (x_A*oat_slope)
    
    # Coefficients for the indoor temperature relationship are retained from the BEoptDefault curve (Daikin lab data).
    iat_slope = -0.010386676170938
    iat_intercept = 0.219274275 
    
    a = oat_intercept + iat_intercept
    b = iat_slope
    c = 0
    d = oat_slope
    e = 0
    f = 0
    hEAT_CAP_FT_SPEC = [[a, b, c, d, e, f]] * number_Speeds         
    
    # COP/EIR as a function of temperature
    # Generic "BEoptDefault" curves (=Daikin from lab data)            
    hEAT_EIR_FT_SPEC = [[0.966475472847719, 0.005914950101249, 0.000191201688297, -0.012965668198361, 0.000042253229429, -0.000524002558712]] * number_Speeds
    
    mshp_indices = [1,3,5,9]
    
    # Cooling Coil
    c_d_cooling = 0.25
    cOOL_CLOSS_FPLR_SPEC = HVAC.calc_plr_coefficients_cooling(number_Speeds, miniSplitHPCoolingRatedSEER, c_d_cooling)
    dB_rated = 80.0
    wB_rated = 67.0
    coolingCFMs, capacity_Ratio_Cooling, sHR_Rated = calc_cfm_ton_cooling(miniSplitHPCoolingMinCapacity, miniSplitHPCoolingMaxCapacity, miniSplitHPCoolingMinAirflow, miniSplitHPCoolingMaxAirflow, number_Speeds, dB_rated, wB_rated, miniSplitHPRatedSHR)
    coolingEIR = calc_cooling_eir(runner, miniSplitHPCoolingRatedSEER, miniSplitHPSupplyFanPower, c_d_cooling, number_Speeds, capacity_Ratio_Cooling, coolingCFMs, cOOL_EIR_FT_SPEC, cOOL_CAP_FT_SPEC)

    # Heating Coil
    c_d_heating = 0.40
    hEAT_CLOSS_FPLR_SPEC = HVAC.calc_plr_coefficients_heating(number_Speeds, miniSplitHPHeatingRatedHSPF, c_d_heating)
    heatingCFMs, capacity_Ratio_Heating = calc_cfm_ton_heating(miniSplitHPHeatingMinCapacity, miniSplitHPHeatingMaxCapacity, miniSplitHPHeatingMinAirflow, miniSplitHPHeatingMaxAirflow, number_Speeds)
    heatingEIR = calc_heating_eir(runner, miniSplitHPHeatingRatedHSPF, miniSplitHPSupplyFanPower, miniSplitHPCapacityRetentionFraction, miniSplitHPCapacityRetentionTemperature, min_hp_temp, c_d_heating, coolingCFMs, number_Speeds, capacity_Ratio_Heating, heatingCFMs, hEAT_EIR_FT_SPEC, hEAT_CAP_FT_SPEC)
        
    min_plr_heat = capacity_Ratio_Heating[mshp_indices.min] / capacity_Ratio_Heating[mshp_indices.max]
    min_plr_cool = capacity_Ratio_Cooling[mshp_indices.min] / capacity_Ratio_Cooling[mshp_indices.max]
        
    # Curves
    curve_index = mshp_indices[-1]+1
    cool_cap_ft_curve = HVAC.create_curve_biquadratic(model, cOOL_CAP_FT_SPEC[-1], "Cool-CAP-fT#{curve_index}", 13.88, 23.88, 18.33, 51.66)
    cool_eir_ft_curve = HVAC.create_curve_biquadratic(model, cOOL_EIR_FT_SPEC[-1], "Cool-EIR-fT#{curve_index}", 13.88, 23.88, 18.33, 51.66)
    cool_eir_fplr_curve = HVAC.create_curve_quadratic(model, [0.100754583, -0.131544809, 1.030916234], "Cool-EIR-fPLR#{curve_index}", min_plr_cool, 1, nil, nil, true)
    cool_plf_fplr_curve = HVAC.create_curve_quadratic(model, cOOL_CLOSS_FPLR_SPEC, "Cool-PLF-fPLR#{curve_index}", 0, 1, 0.7, 1)
    heat_cap_ft_curve = HVAC.create_curve_biquadratic(model, hEAT_CAP_FT_SPEC[-1], "Heat-CAP-fT#{curve_index}", -100, 100, -100, 100)
    heat_eir_ft_curve = HVAC.create_curve_biquadratic(model, hEAT_EIR_FT_SPEC[-1], "Heat-EIR-fT#{curve_index}", -100, 100, -100, 100)
    heat_eir_fplr_curve = HVAC.create_curve_quadratic(model, [-0.169542039, 1.167269914, 0.0], "Heat-EIR-fPLR#{curve_index}", min_plr_heat, 1, nil, nil, true)
    heat_plf_fplr_curve = HVAC.create_curve_quadratic(model, hEAT_CLOSS_FPLR_SPEC, "Heat-PLF-fPLR#{curve_index}", 0, 1, 0.7, 1)
    constant_cubic_curve = HVAC.create_curve_cubic_constant(model)
    defrost_eir_curve = HVAC.create_curve_biquadratic(model, [0.1528, 0, 0, 0, 0, 0], "DefrostEIR", -100, 100, -100, 100)
    
=======
>>>>>>> master
    # Get building units
    units = Geometry.get_building_units(model, runner)
    if units.nil?
      return false
    end

    units.each do |unit|
    
      thermal_zones = Geometry.get_thermal_zones_from_spaces(unit.spaces)
<<<<<<< HEAD
      
      control_slave_zones_hash = HVAC.get_control_and_slave_zones(thermal_zones)
      control_slave_zones_hash.each do |control_zone, slave_zones|
      
        ([control_zone] + slave_zones).each do |zone|
        
            # Remove existing equipment
            HVAC.remove_existing_hvac_equipment(model, runner, Constants.ObjectNameMiniSplitHeatPump, zone, false, unit)
          
            # _processSystemHeatingCoil
            
            htg_coil = OpenStudio::Model::CoilHeatingDXVariableRefrigerantFlow.new(model)
            htg_coil.setName(obj_name + " #{zone.name} heating coil")
            htg_coil.setHeatingCapacityRatioModifierFunctionofTemperatureCurve(constant_cubic_curve)
            htg_coil.setHeatingCapacityModifierFunctionofFlowFractionCurve(constant_cubic_curve)        
          
            # _processSystemCoolingCoil
            
            clg_coil = OpenStudio::Model::CoilCoolingDXVariableRefrigerantFlow.new(model)
            clg_coil.setName(obj_name + " #{zone.name} cooling coil")
            if miniSplitCoolingOutputCapacity != Constants.SizingAuto and miniSplitCoolingOutputCapacity != Constants.SizingAutoMaxLoad
              clg_coil.setRatedTotalCoolingCapacity(UnitConversions.convert(miniSplitCoolingOutputCapacity,"Btu/hr","W")) # Used by HVACSizing measure
            end
            clg_coil.setRatedSensibleHeatRatio(sHR_Rated[mshp_indices[-1]])
            clg_coil.setCoolingCapacityRatioModifierFunctionofTemperatureCurve(constant_cubic_curve)
            clg_coil.setCoolingCapacityModifierCurveFunctionofFlowFraction(constant_cubic_curve)
          
            # _processSystemAir
            
            vrf = OpenStudio::Model::AirConditionerVariableRefrigerantFlow.new(model)
            vrf.setName(obj_name + " #{zone.name} ac vrf")
            vrf.setAvailabilitySchedule(model.alwaysOnDiscreteSchedule)
            vrf.setRatedCoolingCOP(dse / coolingEIR[-1])
            vrf.setMinimumOutdoorTemperatureinCoolingMode(-6)
            vrf.setMaximumOutdoorTemperatureinCoolingMode(60)
            vrf.setCoolingCapacityRatioModifierFunctionofLowTemperatureCurve(cool_cap_ft_curve)    
            vrf.setCoolingEnergyInputRatioModifierFunctionofLowTemperatureCurve(cool_eir_ft_curve)
            vrf.setCoolingEnergyInputRatioModifierFunctionofLowPartLoadRatioCurve(cool_eir_fplr_curve)
            vrf.setCoolingPartLoadFractionCorrelationCurve(cool_plf_fplr_curve)
            vrf.setRatedTotalHeatingCapacitySizingRatio(1)
            vrf.setRatedHeatingCOP(dse / heatingEIR[-1])
            vrf.setMinimumOutdoorTemperatureinHeatingMode(UnitConversions.convert(min_hp_temp,"F","C"))
            vrf.setMaximumOutdoorTemperatureinHeatingMode(40)
            vrf.setHeatingCapacityRatioModifierFunctionofLowTemperatureCurve(heat_cap_ft_curve)
            vrf.setHeatingEnergyInputRatioModifierFunctionofLowTemperatureCurve(heat_eir_ft_curve)
            vrf.setHeatingPerformanceCurveOutdoorTemperatureType("DryBulbTemperature")   
            vrf.setHeatingEnergyInputRatioModifierFunctionofLowPartLoadRatioCurve(heat_eir_fplr_curve)
            vrf.setHeatingPartLoadFractionCorrelationCurve(heat_plf_fplr_curve)        
            vrf.setMinimumHeatPumpPartLoadRatio([min_plr_heat, min_plr_cool].min)
            vrf.setZoneforMasterThermostatLocation(zone)
            vrf.setMasterThermostatPriorityControlType("LoadPriority")
            vrf.setHeatPumpWasteHeatRecovery(false)
            vrf.setCrankcaseHeaterPowerperCompressor(0)
            vrf.setNumberofCompressors(1)
            vrf.setRatioofCompressorSizetoTotalCompressorCapacity(1)
            vrf.setDefrostStrategy("ReverseCycle")
            vrf.setDefrostControl("OnDemand")
            vrf.setDefrostEnergyInputRatioModifierFunctionofTemperatureCurve(defrost_eir_curve)        
            vrf.setMaximumOutdoorDrybulbTemperatureforDefrostOperation(UnitConversions.convert(max_defrost_temp,"F","C"))
            vrf.setFuelType("Electricity")
            vrf.setEquivalentPipingLengthusedforPipingCorrectionFactorinCoolingMode(0)
            vrf.setVerticalHeightusedforPipingCorrectionFactor(0)
            vrf.setPipingCorrectionFactorforHeightinCoolingModeCoefficient(0)
            vrf.setEquivalentPipingLengthusedforPipingCorrectionFactorinHeatingMode(0)

            # _processSystemFan

            fan = OpenStudio::Model::FanOnOff.new(model, model.alwaysOnDiscreteSchedule)
            fan.setName(obj_name + " #{zone.name} supply fan")
            fan.setEndUseSubcategory(Constants.EndUseHVACFan)
            fan.setFanEfficiency(dse * HVAC.calculate_fan_efficiency(static, miniSplitHPSupplyFanPower))
            fan.setPressureRise(static)
            fan.setMotorEfficiency(dse * 1.0)
            fan.setMotorInAirstreamFraction(1.0)       
            
            # _processSystemDemandSideAir
            
            tu_vrf = OpenStudio::Model::ZoneHVACTerminalUnitVariableRefrigerantFlow.new(model, clg_coil, htg_coil, fan)
            tu_vrf.setName(obj_name + " #{zone.name} zone vrf")
            tu_vrf.setTerminalUnitAvailabilityschedule(model.alwaysOnDiscreteSchedule)
            tu_vrf.setSupplyAirFanOperatingModeSchedule(model.alwaysOffDiscreteSchedule)
            tu_vrf.setZoneTerminalUnitOnParasiticElectricEnergyUse(0)
            tu_vrf.setZoneTerminalUnitOffParasiticElectricEnergyUse(0)
            tu_vrf.setRatedTotalHeatingCapacitySizingRatio(1)
            tu_vrf.addToThermalZone(zone)
            vrf.addTerminal(tu_vrf)
            runner.registerInfo("Added '#{tu_vrf.name}' to '#{zone.name}' of #{unit.name}")        
            
            HVAC.prioritize_zone_hvac(model, runner, zone)
            
            # Supplemental heat
            unless baseboardOutputCapacity == 0.0
              supp_htg_coil = OpenStudio::Model::ZoneHVACBaseboardConvectiveElectric.new(model)
              supp_htg_coil.setName(obj_name + " #{zone.name} supp heater")
              if baseboardOutputCapacity != Constants.SizingAuto
                supp_htg_coil.setNominalCapacity(UnitConversions.convert(baseboardOutputCapacity,"Btu/hr","W")) # Used by HVACSizing measure
              end
              supp_htg_coil.setEfficiency(baseboardEfficiency)
              supp_htg_coil.addToThermalZone(zone)
              runner.registerInfo("Added '#{supp_htg_coil.name}' to '#{zone.name}' of #{unit.name}")     
            end
        
        end
        
        if miniSplitHPPanHeaterPowerPerUnit > 0

          vrf_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, vrf_heating_output_var)
          vrf_sensor.setName("#{obj_name} vrf energy sensor".gsub("|","_"))
          vrf_sensor.setKeyName(obj_name + " #{control_zone.name} ac vrf")
          
          vrf_fbsmt_sensor = nil
          slave_zones.each do |slave_zone|
            vrf_fbsmt_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, vrf_heating_output_var)
            vrf_fbsmt_sensor.setName("#{obj_name} vrf fbsmt energy sensor".gsub("|","_"))
            vrf_fbsmt_sensor.setKeyName(obj_name + " #{slave_zone.name} ac vrf")
          end
     
          equip_def = OpenStudio::Model::ElectricEquipmentDefinition.new(model)
          equip_def.setName(obj_name + " pan heater equip")
          equip = OpenStudio::Model::ElectricEquipment.new(equip_def)
          equip.setName(equip_def.name.to_s)
          equip.setSpace(control_zone.spaces[0])
          equip_def.setFractionRadiant(0)
          equip_def.setFractionLatent(0)
          equip_def.setFractionLost(1)
          equip.setSchedule(model.alwaysOnDiscreteSchedule)

          pan_heater_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(equip, "ElectricEquipment", "Electric Power Level")
          pan_heater_actuator.setName("#{obj_name} pan heater actuator".gsub("|","_"))

          tout_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, zone_outdoor_air_drybulb_temp_output_var)
          tout_sensor.setName("#{obj_name} tout sensor".gsub("|","_"))
          thermal_zones.each do |thermal_zone|
            if Geometry.is_living(thermal_zone)
              tout_sensor.setKeyName(thermal_zone.name.to_s)
              break
            end
          end

          program = OpenStudio::Model::EnergyManagementSystemProgram.new(model)
          program.setName(obj_name + " pan heater program")
          if miniSplitCoolingOutputCapacity != Constants.SizingAuto and miniSplitCoolingOutputCapacity != Constants.SizingAutoMaxLoad
            num_outdoor_units = (UnitConversions.convert(miniSplitCoolingOutputCapacity,"Btu/hr","ton") / 1.5).ceil # Assume 1.5 tons max per outdoor unit
          else
            num_outdoor_units = 2
          end
          unless slave_zones.empty?
            num_outdoor_units = [num_outdoor_units, 2].max
          end
          pan_heater_power = miniSplitHPPanHeaterPowerPerUnit * num_outdoor_units # W
          program.addLine("Set #{pan_heater_actuator.name} = 0")
          if slave_zones.empty?
            program.addLine("Set vrf_fbsmt_sensor = 0")
            program.addLine("If #{vrf_sensor.name} > 0 || vrf_fbsmt_sensor > 0")
          else
            program.addLine("Set #{vrf_fbsmt_sensor.name} = 0")
            program.addLine("If #{vrf_sensor.name} > 0 || #{vrf_fbsmt_sensor.name} > 0")
          end          
          program.addLine("If #{tout_sensor.name} <= #{UnitConversions.convert(32.0,"F","C").round(3)}")
          program.addLine("Set #{pan_heater_actuator.name} = #{pan_heater_power}")
          program.addLine("EndIf")
          program.addLine("EndIf")
         
          program_calling_manager = OpenStudio::Model::EnergyManagementSystemProgramCallingManager.new(model)
          program_calling_manager.setName(obj_name + " pan heater program calling manager")
          program_calling_manager.setCallingPoint("BeginTimestepBeforePredictor")
          program_calling_manager.addProgram(program)
          
        end # slave_zone
      
      end # control_zone
      
      # Store miniSplitHPIsDucted bool
      unit.setFeature(Constants.DuctedInfoMiniSplitHeatPump, miniSplitHPIsDucted)
      
      # Store info for HVAC Sizing measure
      unit.setFeature(Constants.SizingInfoHVACCapacityRatioCooling, capacity_Ratio_Cooling.join(","))
      unit.setFeature(Constants.SizingInfoHVACCapacityRatioHeating, capacity_Ratio_Heating.join(","))
      unit.setFeature(Constants.SizingInfoHVACCoolingCFMs, coolingCFMs.join(","))
      unit.setFeature(Constants.SizingInfoHVACHeatingCFMs, heatingCFMs.join(","))
      unit.setFeature(Constants.SizingInfoHVACHeatingCapacityOffset, miniSplitHPHeatingCapacityOffset)
      unit.setFeature(Constants.SizingInfoHPSizedForMaxLoad, (miniSplitCoolingOutputCapacity == Constants.SizingAutoMaxLoad))
      unit.setFeature(Constants.SizingInfoHVACSHR, sHR_Rated.join(","))
      unit.setFeature(Constants.SizingInfoMSHPIndices, mshp_indices.join(","))
=======
      HVAC.get_control_and_slave_zones(thermal_zones).each do |control_zone, slave_zones|
        ([control_zone] + slave_zones).each do |zone|
          HVAC.remove_hvac_equipment(model, runner, zone, unit,
                                     Constants.ObjectNameMiniSplitHeatPump)
        end
      end
      
      success = HVAC.apply_mshp(model, unit, runner, seer, hspf, shr,
                                min_cooling_capacity, max_cooling_capacity,
                                min_cooling_airflow_rate, max_cooling_airflow_rate,
                                min_heating_capacity, max_heating_capacity,
                                min_heating_airflow_rate, max_heating_airflow_rate, 
                                heating_capacity_offset, cap_retention_frac,
                                cap_retention_temp, pan_heater_power, fan_power,
                                is_ducted, heat_pump_capacity,
                                supplemental_efficiency, supplemental_capacity,
                                dse)
      return false if not success
>>>>>>> master
      
    end # unit

    return true

  end
  
  
end

# register the measure to be used by the application
ProcessVRFMinisplit.new.registerWithApplication
