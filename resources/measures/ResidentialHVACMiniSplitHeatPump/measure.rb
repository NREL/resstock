# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/psychrometrics"
require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/unit_conversions"
require "#{File.dirname(__FILE__)}/resources/geometry"
require "#{File.dirname(__FILE__)}/resources/hvac"

# start the measure
class ProcessVRFMinisplit < OpenStudio::Ruleset::ModelUserScript

  class Supply
    def initialize
    end
    attr_accessor(:SpaceConditionedMult, :CoolingEIR, :Capacity_Ratio_Cooling, :CoolingCFMs, :SHR_Rated, :fanspeed_ratio, :min_flow_ratio, :static, :fan_power, :eff, :HeatingEIR, :Capacity_Ratio_Heating, :HeatingCFMs, :htg_supply_air_temp, :supp_htg_max_supply_temp, :min_hp_temp, :supp_htg_max_outdoor_temp, :max_defrost_temp)
  end
  
  class Curves
    def initialize
    end
    attr_accessor(:mshp_indices, :COOL_CAP_FT_SPEC_coefficients, :COOL_EIR_FT_SPEC_coefficients, :COOL_CAP_FFLOW_SPEC_coefficients, :COOL_CLOSS_FPLR_SPEC_coefficients, :COOL_EIR_FFLOW_SPEC_coefficients, :HEAT_CAP_FT_SPEC_coefficients, :HEAT_EIR_FT_SPEC_coefficients, :HEAT_CAP_FFLOW_SPEC_coefficients, :HEAT_CLOSS_FPLR_SPEC_coefficients, :HEAT_EIR_FFLOW_SPEC_coefficients, :Number_Speeds)
  end

  # human readable name
  def name
    return "Set Residential Mini-Split Heat Pump"
  end

  # human readable description
  def description
    return "This measure removes any existing HVAC components from the building and adds a mini-split heat pump. For multifamily buildings, the mini-split heat pump can be set for all units of the building."
  end

  # human readable description of modeling approach
  def modeler_description
    return "Any supply components or baseboard convective electrics/waters are removed from any existing air/plant loops or zones. Any existing air/plant loops are also removed. A heating DX coil, cooling DX coil, and an on/off supply fan are added to a variable refrigerant flow terminal unit."
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new
    
    #make a double argument for minisplit cooling rated seer
    miniSplitHPCoolingRatedSEER = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("seer", true)
    miniSplitHPCoolingRatedSEER.setDisplayName("Rated SEER")
    miniSplitHPCoolingRatedSEER.setUnits("Btu/W-h")
    miniSplitHPCoolingRatedSEER.setDescription("Seasonal Energy Efficiency Ratio (SEER) is a measure of equipment energy efficiency over the cooling season.")
    miniSplitHPCoolingRatedSEER.setDefaultValue(14.5)
    args << miniSplitHPCoolingRatedSEER 
    
    #make a double argument for minisplit cooling min capacity
    miniSplitHPCoolingMinCapacity = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("min_cooling_capacity", true)
    miniSplitHPCoolingMinCapacity.setDisplayName("Minimum Cooling Capacity")
    miniSplitHPCoolingMinCapacity.setUnits("frac")
    miniSplitHPCoolingMinCapacity.setDescription("Minimum cooling capacity as a fraction of the nominal cooling capacity at rated conditions.")
    miniSplitHPCoolingMinCapacity.setDefaultValue(0.4)
    args << miniSplitHPCoolingMinCapacity     
    
    #make a double argument for minisplit cooling max capacity
    miniSplitHPCoolingMaxCapacity = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("max_cooling_capacity", true)
    miniSplitHPCoolingMaxCapacity.setDisplayName("Maximum Cooling Capacity")
    miniSplitHPCoolingMaxCapacity.setUnits("frac")
    miniSplitHPCoolingMaxCapacity.setDescription("Maximum cooling capacity as a fraction of the nominal cooling capacity at rated conditions.")
    miniSplitHPCoolingMaxCapacity.setDefaultValue(1.2)
    args << miniSplitHPCoolingMaxCapacity    
    
    #make a double argument for minisplit rated shr
    miniSplitHPRatedSHR = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("shr", true)
    miniSplitHPRatedSHR.setDisplayName("Rated SHR")
    miniSplitHPRatedSHR.setDescription("The sensible heat ratio (ratio of the sensible portion of the load to the total load) at the nominal rated capacity.")
    miniSplitHPRatedSHR.setDefaultValue(0.73)
    args << miniSplitHPRatedSHR        
    
    #make a double argument for minisplit cooling min airflow
    miniSplitHPCoolingMinAirflow = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("min_cooling_airflow_rate", true)
    miniSplitHPCoolingMinAirflow.setDisplayName("Minimum Cooling Airflow")
    miniSplitHPCoolingMinAirflow.setUnits("cfm/ton")
    miniSplitHPCoolingMinAirflow.setDescription("Minimum cooling cfm divided by the nominal rated cooling capacity.")
    miniSplitHPCoolingMinAirflow.setDefaultValue(200.0)
    args << miniSplitHPCoolingMinAirflow      
    
    #make a double argument for minisplit cooling max airflow
    miniSplitHPCoolingMaxAirflow = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("max_cooling_airflow_rate", true)
    miniSplitHPCoolingMaxAirflow.setDisplayName("Maximum Cooling Airflow")
    miniSplitHPCoolingMaxAirflow.setUnits("cfm/ton")
    miniSplitHPCoolingMaxAirflow.setDescription("Maximum cooling cfm divided by the nominal rated cooling capacity.")
    miniSplitHPCoolingMaxAirflow.setDefaultValue(425.0)
    args << miniSplitHPCoolingMaxAirflow     
    
    #make a double argument for minisplit rated hspf
    miniSplitHPHeatingRatedHSPF = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("hspf", true)
    miniSplitHPHeatingRatedHSPF.setDisplayName("Rated HSPF")
    miniSplitHPHeatingRatedHSPF.setUnits("Btu/W-h")
    miniSplitHPHeatingRatedHSPF.setDescription("The Heating Seasonal Performance Factor (HSPF) is a measure of a heat pump's energy efficiency over one heating season.")
    miniSplitHPHeatingRatedHSPF.setDefaultValue(8.2)
    args << miniSplitHPHeatingRatedHSPF
    
    #make a double argument for minisplit heating capacity offset
    miniSplitHPHeatingCapacityOffset = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("heating_capacity_offset", true)
    miniSplitHPHeatingCapacityOffset.setDisplayName("Heating Capacity Offset")
    miniSplitHPHeatingCapacityOffset.setUnits("Btu/h")
    miniSplitHPHeatingCapacityOffset.setDescription("The difference between the nominal rated heating capacity and the nominal rated cooling capacity.")
    miniSplitHPHeatingCapacityOffset.setDefaultValue(2300.0)
    args << miniSplitHPHeatingCapacityOffset    
    
    #make a double argument for minisplit heating min capacity
    miniSplitHPHeatingMinCapacity = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("min_heating_capacity", true)
    miniSplitHPHeatingMinCapacity.setDisplayName("Minimum Heating Capacity")
    miniSplitHPHeatingMinCapacity.setUnits("frac")
    miniSplitHPHeatingMinCapacity.setDescription("Minimum heating capacity as a fraction of nominal heating capacity at rated conditions.")
    miniSplitHPHeatingMinCapacity.setDefaultValue(0.3)
    args << miniSplitHPHeatingMinCapacity     
    
    #make a double argument for minisplit heating max capacity
    miniSplitHPHeatingMaxCapacity = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("max_heating_capacity", true)
    miniSplitHPHeatingMaxCapacity.setDisplayName("Maximum Heating Capacity")
    miniSplitHPHeatingMaxCapacity.setUnits("frac")
    miniSplitHPHeatingMaxCapacity.setDescription("Maximum heating capacity as a fraction of nominal heating capacity at rated conditions.")
    miniSplitHPHeatingMaxCapacity.setDefaultValue(1.2)
    args << miniSplitHPHeatingMaxCapacity        
    
    #make a double argument for minisplit heating min airflow
    miniSplitHPHeatingMinAirflow = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("min_heating_airflow_rate", true)
    miniSplitHPHeatingMinAirflow.setDisplayName("Minimum Heating Airflow")
    miniSplitHPHeatingMinAirflow.setUnits("cfm/ton")
    miniSplitHPHeatingMinAirflow.setDescription("Minimum heating cfm divided by the nominal rated heating capacity.")
    miniSplitHPHeatingMinAirflow.setDefaultValue(200.0)
    args << miniSplitHPHeatingMinAirflow     
    
    #make a double argument for minisplit heating min airflow
    miniSplitHPHeatingMaxAirflow = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("max_heating_airflow_rate", true)
    miniSplitHPHeatingMaxAirflow.setDisplayName("Maximum Heating Airflow")
    miniSplitHPHeatingMaxAirflow.setUnits("cfm/ton")
    miniSplitHPHeatingMaxAirflow.setDescription("Maximum heating cfm divided by the nominal rated heating capacity.")
    miniSplitHPHeatingMaxAirflow.setDefaultValue(400.0)
    args << miniSplitHPHeatingMaxAirflow         
    
    #make a double argument for minisplit capacity retention fraction
    miniSplitHPCapacityRetentionFraction = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("cap_retention_frac", true)
    miniSplitHPCapacityRetentionFraction.setDisplayName("Heating Capacity Retention Fraction")
    miniSplitHPCapacityRetentionFraction.setUnits("frac")
    miniSplitHPCapacityRetentionFraction.setDescription("The maximum heating capacity at X degrees divided by the maximum heating capacity at 47 degrees F.")
    miniSplitHPCapacityRetentionFraction.setDefaultValue(0.25)
    args << miniSplitHPCapacityRetentionFraction
    
    #make a double argument for minisplit capacity retention temperature
    miniSplitHPCapacityRetentionTemperature = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("cap_retention_temp", true)
    miniSplitHPCapacityRetentionTemperature.setDisplayName("Heating Capacity Retention Temperature")
    miniSplitHPCapacityRetentionTemperature.setUnits("degrees F")
    miniSplitHPCapacityRetentionTemperature.setDescription("The outdoor drybulb temperature at which the heating capacity retention fraction is defined.")
    miniSplitHPCapacityRetentionTemperature.setDefaultValue(-5.0)
    args << miniSplitHPCapacityRetentionTemperature    
    
    #make a double argument for minisplit pan heater power
    miniSplitHPPanHeaterPowerPerUnit = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("pan_heater_power", true)
    miniSplitHPPanHeaterPowerPerUnit.setDisplayName("Pan Heater")
    miniSplitHPPanHeaterPowerPerUnit.setUnits("W/unit")
    miniSplitHPPanHeaterPowerPerUnit.setDescription("Prevents ice build up from damaging the coil.")
    miniSplitHPPanHeaterPowerPerUnit.setDefaultValue(0.0)
    args << miniSplitHPPanHeaterPowerPerUnit    
    
    #make a double argument for minisplit supply fan power
    miniSplitHPSupplyFanPower = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("fan_power", true)
    miniSplitHPSupplyFanPower.setDisplayName("Supply Fan Power")
    miniSplitHPSupplyFanPower.setUnits("W/cfm")
    miniSplitHPSupplyFanPower.setDescription("Fan power (in W) per delivered airflow rate (in cfm) of the fan.")
    miniSplitHPSupplyFanPower.setDefaultValue(0.07)
    args << miniSplitHPSupplyFanPower
    
    #make a string argument for minisplit cooling output capacity
    cap_display_names = OpenStudio::StringVector.new
    cap_display_names << Constants.SizingAuto
    (0.5..10.0).step(0.5) do |tons|
      cap_display_names << tons.to_s
    end
    miniSplitCoolingOutputCapacity = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("heat_pump_capacity", cap_display_names, true)
    miniSplitCoolingOutputCapacity.setDisplayName("Heat Pump Capacity")
    miniSplitCoolingOutputCapacity.setDescription("The output heating/cooling capacity of the heat pump.")
    miniSplitCoolingOutputCapacity.setUnits("tons")
    miniSplitCoolingOutputCapacity.setDefaultValue(Constants.SizingAuto)
    args << miniSplitCoolingOutputCapacity

    #make an argument for entering supplemental efficiency
    baseboardeff = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("supplemental_efficiency",true)
    baseboardeff.setDisplayName("Supplemental Efficiency")
    baseboardeff.setUnits("Btu/Btu")
    baseboardeff.setDescription("The efficiency of the supplemental electric baseboard.")
    baseboardeff.setDefaultValue(1.0)
    args << baseboardeff

    #make a string argument for supplemental heating output capacity
    cap_display_names = OpenStudio::StringVector.new
    cap_display_names << "NO SUPP HEAT"
    cap_display_names << Constants.SizingAuto
    (5..150).step(5) do |kbtu|
      cap_display_names << kbtu.to_s
    end  
    baseboardcap = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("supplemental_capacity", cap_display_names, true)
    baseboardcap.setDisplayName("Supplemental Heating Capacity")
    baseboardcap.setDescription("The output heating capacity of the supplemental electric baseboard.")
    baseboardcap.setUnits("kBtu/hr")
    baseboardcap.setDefaultValue(Constants.SizingAuto)
    args << baseboardcap  
    
    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end    
    
    curves = Curves.new
    supply = Supply.new
    
    miniSplitHPCoolingRatedSEER = runner.getDoubleArgumentValue("seer",user_arguments) 
    miniSplitHPCoolingMinCapacity = runner.getDoubleArgumentValue("min_cooling_capacity",user_arguments) 
    miniSplitHPCoolingMaxCapacity = runner.getDoubleArgumentValue("max_cooling_capacity",user_arguments) 
    miniSplitHPCoolingMinAirflow = runner.getDoubleArgumentValue("min_cooling_airflow_rate",user_arguments) 
    miniSplitHPCoolingMaxAirflow = runner.getDoubleArgumentValue("max_cooling_airflow_rate",user_arguments) 
    miniSplitHPRatedSHR = runner.getDoubleArgumentValue("shr",user_arguments)    
    miniSplitHPHeatingCapacityOffset = runner.getDoubleArgumentValue("heating_capacity_offset",user_arguments) 
    miniSplitHPHeatingRatedHSPF = runner.getDoubleArgumentValue("hspf",user_arguments) 
    miniSplitHPHeatingMinCapacity = runner.getDoubleArgumentValue("min_heating_capacity",user_arguments) 
    miniSplitHPHeatingMaxCapacity = runner.getDoubleArgumentValue("max_heating_capacity",user_arguments) 
    miniSplitHPHeatingMinAirflow = runner.getDoubleArgumentValue("min_heating_airflow_rate",user_arguments) 
    miniSplitHPHeatingMaxAirflow = runner.getDoubleArgumentValue("max_heating_airflow_rate",user_arguments)
    miniSplitHPCapacityRetentionFraction = runner.getDoubleArgumentValue("cap_retention_frac",user_arguments)
    miniSplitHPCapacityRetentionTemperature = runner.getDoubleArgumentValue("cap_retention_temp",user_arguments)
    miniSplitHPPanHeaterPowerPerUnit = runner.getDoubleArgumentValue("pan_heater_power",user_arguments)    
    miniSplitHPSupplyFanPower = runner.getDoubleArgumentValue("fan_power",user_arguments)
    miniSplitCoolingOutputCapacity = runner.getStringArgumentValue("heat_pump_capacity",user_arguments)
    unless miniSplitCoolingOutputCapacity == Constants.SizingAuto
      miniSplitCoolingOutputCapacity = OpenStudio::convert(miniSplitCoolingOutputCapacity.to_f,"ton","Btu/h").get
      miniSplitHeatingOutputCapacity = miniSplitCoolingOutputCapacity + miniSplitHPHeatingCapacityOffset
    end
    baseboardEfficiency = runner.getDoubleArgumentValue("supplemental_efficiency",user_arguments)
    baseboardOutputCapacity = runner.getStringArgumentValue("supplemental_capacity",user_arguments)
    unless baseboardOutputCapacity == Constants.SizingAuto or baseboardOutputCapacity == "NO SUPP HEAT"
      baseboardOutputCapacity = OpenStudio::convert(baseboardOutputCapacity.to_f,"kBtu/h","Btu/h").get
    end    
        
    # Performance curves
    
    # NOTE: These coefficients are in SI UNITS
    curves.COOL_CAP_FT_SPEC_coefficients = [[1.008993521905866, 0.006512749025457, 0.0, 0.003917565735935, -0.000222646705889, 0.0]] * Constants.Num_Speeds_MSHP
    curves.COOL_EIR_FT_SPEC_coefficients = [[0.429214441601141, -0.003604841598515, 0.000045783162727, 0.026490875804937, -0.000159212286878, -0.000159062656483]] * Constants.Num_Speeds_MSHP                
    curves.COOL_CAP_FFLOW_SPEC_coefficients = [[1, 0, 0]] * Constants.Num_Speeds_MSHP
    curves.COOL_EIR_FFLOW_SPEC_coefficients = [[1, 0, 0]] * Constants.Num_Speeds_MSHP
    
    # Mini-Split Heat Pump Heating Curve Coefficients
    # Derive coefficients from user input for capacity retention at outdoor drybulb temperature X [C].
    # Biquadratic: capacity multiplier = a + b*IAT + c*IAT^2 + d*OAT + e*OAT^2 + f*IAT*OAT
    x_A = OpenStudio::convert(miniSplitHPCapacityRetentionTemperature,"F", "C").get
    y_A = miniSplitHPCapacityRetentionFraction
    x_B = OpenStudio::convert(47.0,"F","C").get # 47F is the rating point
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
    curves.HEAT_CAP_FT_SPEC_coefficients = [[a, b, c, d, e, f]] * Constants.Num_Speeds_MSHP         
    
    # COP/EIR as a function of temperature
    # Generic "BEoptDefault" curves (=Daikin from lab data)            
    curves.HEAT_EIR_FT_SPEC_coefficients = [[0.966475472847719, 0.005914950101249, 0.000191201688297, -0.012965668198361, 0.000042253229429, -0.000524002558712]] * Constants.Num_Speeds_MSHP
    
    curves.HEAT_CAP_FFLOW_SPEC_coefficients = [[1, 0, 0]] * Constants.Num_Speeds_MSHP
    curves.HEAT_EIR_FFLOW_SPEC_coefficients = [[1, 0, 0]] * Constants.Num_Speeds_MSHP
    
    curves.mshp_indices = [1,3,5,9]
    
    # Cooling Coil
    curves, supply = _processAirSystemMiniSplitCooling(runner, miniSplitHPCoolingRatedSEER, miniSplitHPCoolingMinCapacity, miniSplitHPCoolingMaxCapacity, miniSplitHPCoolingMinAirflow, miniSplitHPCoolingMaxAirflow, miniSplitHPRatedSHR, miniSplitHPSupplyFanPower, curves, supply)

    # Heating Coil
    curves, supply = _processAirSystemMiniSplitHeating(runner, miniSplitHPHeatingRatedHSPF, miniSplitHPHeatingMinCapacity, miniSplitHPHeatingMaxCapacity, miniSplitHPHeatingMinAirflow, miniSplitHPHeatingMaxAirflow, miniSplitHPSupplyFanPower, miniSplitHPCapacityRetentionFraction, miniSplitHPCapacityRetentionTemperature, curves, supply)
        
    # Remove boiler hot water loop if it exists
    HVAC.remove_hot_water_loop(model, runner)    
    
    min_plr_heat = supply.Capacity_Ratio_Heating[curves.mshp_indices.min] / supply.Capacity_Ratio_Heating[curves.mshp_indices.max]
    min_plr_cool = supply.Capacity_Ratio_Cooling[curves.mshp_indices.min] / supply.Capacity_Ratio_Cooling[curves.mshp_indices.max]
        
    cool_cap_ft, cool_eir_ft, cool_eir_fplr, cool_plf_fplr, heat_cap_ft, heat_eir_ft, heat_eir_fplr, heat_plf_fplr, constant_cubic, defrosteir = _processCurvesMiniSplitHP(model, curves, min_plr_cool, min_plr_heat)
    
    # Get building units
    units = Geometry.get_building_units(model, runner)
    if units.nil?
      return false
    end
    
    model.getOutputVariables.each do |output_var|
      next unless output_var.name.to_s == Constants.ObjectNameMiniSplitHeatPump + " vrf heat energy output var"
      output_var.remove
    end
    model.getOutputVariables.each do |output_var|
      next unless output_var.name.to_s == Constants.ObjectNameMiniSplitHeatPump + " zone outdoor air drybulb temp output var"
      output_var.remove
    end    
    if miniSplitHPPanHeaterPowerPerUnit > 0    
      vrf_heating_output_var = OpenStudio::Model::OutputVariable.new("VRF Heat Pump Heating Electric Energy", model)
      vrf_heating_output_var.setName(Constants.ObjectNameMiniSplitHeatPump + " vrf heat energy output var")
      zone_outdoor_air_drybulb_temp_output_var = OpenStudio::Model::OutputVariable.new("Zone Outdoor Air Drybulb Temperature", model)
      zone_outdoor_air_drybulb_temp_output_var.setName(Constants.ObjectNameMiniSplitHeatPump + " zone outdoor air drybulb temp output var")
    end
    
    units.each do |unit|
    
      obj_name = Constants.ObjectNameMiniSplitHeatPump(unit.name.to_s)

      # Remove existing mini-split heat pump pan heater
      model.getEnergyManagementSystemSensors.each do |sensor|
        next unless sensor.name.to_s == "#{obj_name} vrf energy sensor".gsub(" ","_").gsub("|","_")
        sensor.remove
      end
      model.getEnergyManagementSystemSensors.each do |sensor|
        next unless sensor.name.to_s == "#{obj_name} vrf fbsmt energy sensor".gsub(" ","_").gsub("|","_")
        sensor.remove
      end
      model.getEnergyManagementSystemSensors.each do |sensor|
        next unless sensor.name.to_s == "#{obj_name} tout sensor".gsub(" ","_").gsub("|","_")
        sensor.remove
      end
      model.getEnergyManagementSystemActuators.each do |actuator|
        next unless actuator.name.to_s == "#{obj_name} pan heater actuator".gsub(" ","_").gsub("|","_")
        actuator.remove
      end
      model.getEnergyManagementSystemPrograms.each do |program|
        next unless program.name.to_s == "#{obj_name} pan heater program".gsub(" ","_")
        program.remove
      end          
      model.getEnergyManagementSystemProgramCallingManagers.each do |program_calling_manager|
        next unless program_calling_manager.name.to_s == obj_name + " pan heater program calling manager"
        program_calling_manager.remove
      end
    
      thermal_zones = Geometry.get_thermal_zones_from_spaces(unit.spaces)
      
      control_slave_zones_hash = HVAC.get_control_and_slave_zones(thermal_zones)
      control_slave_zones_hash.each do |control_zone, slave_zones|
      
        control_zone.spaces.each do |space|
          space.electricEquipment.each do |equip|
            next unless equip.name.to_s == obj_name + " pan heater equip"
            equip.electricEquipmentDefinition.remove
          end
        end
      
        total_slave_zone_floor_area = 0
        slave_zones.each do |slave_zone|
          total_slave_zone_floor_area += slave_zone.floorArea
        end
      
        fbsmt_frac = 0.0
        unless slave_zones.empty?
          fbsmt_frac = total_slave_zone_floor_area / (control_zone.floorArea + total_slave_zone_floor_area)
        end

        # Remove existing equipment
        HVAC.remove_existing_hvac_equipment(model, runner, Constants.ObjectNameMiniSplitHeatPump, control_zone)
      
        # _processSystemHeatingCoil
        
        htg_coil = OpenStudio::Model::CoilHeatingDXVariableRefrigerantFlow.new(model)
        htg_coil.setName(obj_name + " #{control_zone.name} heating coil")
        if miniSplitCoolingOutputCapacity != Constants.SizingAuto
          htg_coil.setRatedTotalHeatingCapacity(OpenStudio::convert(miniSplitHeatingOutputCapacity,"Btu/h","W").get * supply.Capacity_Ratio_Heating[curves.mshp_indices[-1]] * (1.0 - fbsmt_frac))
          htg_coil.setRatedAirFlowRate(supply.HeatingCFMs[curves.mshp_indices[-1]] * miniSplitHeatingOutputCapacity * OpenStudio::convert(1.0,"Btu/h","ton").get * OpenStudio::convert(1.0,"cfm","m^3/s").get * (1.0 - fbsmt_frac))
        end        
        htg_coil.setHeatingCapacityRatioModifierFunctionofTemperatureCurve(constant_cubic)
        htg_coil.setHeatingCapacityModifierFunctionofFlowFractionCurve(constant_cubic)        
      
        # _processSystemCoolingCoil
        
        clg_coil = OpenStudio::Model::CoilCoolingDXVariableRefrigerantFlow.new(model)
        clg_coil.setName(obj_name + " #{control_zone.name} cooling coil")
        if miniSplitCoolingOutputCapacity != Constants.SizingAuto
          clg_coil.setRatedTotalCoolingCapacity(OpenStudio::convert(miniSplitCoolingOutputCapacity,"Btu/h","W").get * supply.Capacity_Ratio_Cooling[curves.mshp_indices[-1]] * (1.0 - fbsmt_frac))
          clg_coil.setRatedSensibleHeatRatio(supply.SHR_Rated[curves.mshp_indices[-1]])
          clg_coil.setRatedAirFlowRate(supply.CoolingCFMs[curves.mshp_indices[-1]]* miniSplitCoolingOutputCapacity * OpenStudio::convert(1.0,"Btu/h","ton").get * OpenStudio::convert(1.0,"cfm","m^3/s").get * (1.0 - fbsmt_frac))
        end
        clg_coil.setCoolingCapacityRatioModifierFunctionofTemperatureCurve(constant_cubic)
        clg_coil.setCoolingCapacityModifierCurveFunctionofFlowFraction(constant_cubic)
      
        # _processSystemAir
        
        vrf = OpenStudio::Model::AirConditionerVariableRefrigerantFlow.new(model)
        vrf.setName(obj_name + " #{control_zone.name} ac vrf")
        vrf.setAvailabilitySchedule(model.alwaysOnDiscreteSchedule)
        if miniSplitCoolingOutputCapacity != Constants.SizingAuto
          vrf.setRatedTotalCoolingCapacity(OpenStudio::convert(miniSplitCoolingOutputCapacity,"Btu/h","W").get * supply.Capacity_Ratio_Cooling[curves.mshp_indices[-1]] * (1.0 - fbsmt_frac))
          vrf.setRatedTotalHeatingCapacity(OpenStudio::convert(miniSplitHeatingOutputCapacity,"Btu/h","W").get * supply.Capacity_Ratio_Heating[curves.mshp_indices[-1]] * (1.0 - fbsmt_frac))
        end
        vrf.setRatedCoolingCOP(1.0 / supply.CoolingEIR[-1])
        vrf.setMinimumOutdoorTemperatureinCoolingMode(-6)
        vrf.setMaximumOutdoorTemperatureinCoolingMode(60)
        vrf.setCoolingCapacityRatioModifierFunctionofLowTemperatureCurve(cool_cap_ft)    
        vrf.setCoolingEnergyInputRatioModifierFunctionofLowTemperatureCurve(cool_eir_ft)
        vrf.setCoolingEnergyInputRatioModifierFunctionofLowPartLoadRatioCurve(cool_eir_fplr)
        vrf.setCoolingPartLoadFractionCorrelationCurve(cool_plf_fplr)
        vrf.setRatedTotalHeatingCapacitySizingRatio(1)
        vrf.setRatedHeatingCOP(1.0 / supply.HeatingEIR[-1])
        vrf.setMinimumOutdoorTemperatureinHeatingMode(OpenStudio::convert(supply.min_hp_temp,"F","C").get)
        vrf.setMaximumOutdoorTemperatureinHeatingMode(40)
        vrf.setHeatingCapacityRatioModifierFunctionofLowTemperatureCurve(heat_cap_ft)
        vrf.setHeatingEnergyInputRatioModifierFunctionofLowTemperatureCurve(heat_eir_ft)
        vrf.setHeatingPerformanceCurveOutdoorTemperatureType("DryBulbTemperature")   
        vrf.setHeatingEnergyInputRatioModifierFunctionofLowPartLoadRatioCurve(heat_eir_fplr)
        vrf.setHeatingPartLoadFractionCorrelationCurve(heat_plf_fplr)        
        vrf.setMinimumHeatPumpPartLoadRatio([min_plr_heat, min_plr_cool].min)
        vrf.setZoneforMasterThermostatLocation(control_zone)
        vrf.setMasterThermostatPriorityControlType("LoadPriority")
        vrf.setHeatPumpWasteHeatRecovery(false)
        vrf.setCrankcaseHeaterPowerperCompressor(0)
        vrf.setNumberofCompressors(1)
        vrf.setRatioofCompressorSizetoTotalCompressorCapacity(1)
        vrf.setDefrostStrategy("ReverseCycle")
        vrf.setDefrostControl("OnDemand")
        vrf.setDefrostEnergyInputRatioModifierFunctionofTemperatureCurve(defrosteir)        
        vrf.setMaximumOutdoorDrybulbTemperatureforDefrostOperation(OpenStudio::convert(supply.max_defrost_temp,"F","C").get)
        vrf.setFuelType("Electricity")
        vrf.setEquivalentPipingLengthusedforPipingCorrectionFactorinCoolingMode(0)
        vrf.setVerticalHeightusedforPipingCorrectionFactor(0)
        vrf.setPipingCorrectionFactorforHeightinCoolingModeCoefficient(0)
        vrf.setEquivalentPipingLengthusedforPipingCorrectionFactorinHeatingMode(0)

        # _processSystemFan

        fan = OpenStudio::Model::FanOnOff.new(model, model.alwaysOnDiscreteSchedule)
        fan.setName(obj_name + " #{control_zone.name} supply fan")
        fan.setEndUseSubcategory(Constants.EndUseHVACFan)
        fan.setFanEfficiency(supply.eff)
        fan.setPressureRise(supply.static)
        fan.setMotorEfficiency(1)
        fan.setMotorInAirstreamFraction(1)       
        
        # _processSystemDemandSideAir
        
        tu_vrf = OpenStudio::Model::ZoneHVACTerminalUnitVariableRefrigerantFlow.new(model, clg_coil, htg_coil, fan)
        tu_vrf.setName(obj_name + " #{control_zone.name} zone vrf")
        tu_vrf.setTerminalUnitAvailabilityschedule(model.alwaysOnDiscreteSchedule)
        tu_vrf.setSupplyAirFanOperatingModeSchedule(model.alwaysOffDiscreteSchedule)
        tu_vrf.setZoneTerminalUnitOnParasiticElectricEnergyUse(0)
        tu_vrf.setZoneTerminalUnitOffParasiticElectricEnergyUse(0)
        tu_vrf.setRatedTotalHeatingCapacitySizingRatio(1)
        tu_vrf.addToThermalZone(control_zone)
        vrf.addTerminal(tu_vrf)
        runner.registerInfo("Added '#{tu_vrf.name}' to '#{control_zone.name}' of #{unit.name}")        
        
        # Supplemental heat
        unless baseboardOutputCapacity == "NO SUPP HEAT"
          supp_htg_coil = OpenStudio::Model::ZoneHVACBaseboardConvectiveElectric.new(model)
          supp_htg_coil.setName(obj_name + " #{control_zone.name} supp heater")
          if baseboardOutputCapacity != Constants.SizingAuto
            supp_htg_coil.setNominalCapacity(OpenStudio::convert(baseboardOutputCapacity,"Btu/h","W").get)
          end
          supp_htg_coil.setEfficiency(baseboardEfficiency)
          supp_htg_coil.addToThermalZone(control_zone)
          runner.registerInfo("Added '#{supp_htg_coil.name}' to '#{control_zone.name}' of #{unit.name}")     
        end
        
        vrf_fbsmt_sensor = nil
        slave_zones.each do |slave_zone|

          # Remove existing equipment
          HVAC.remove_existing_hvac_equipment(model, runner, Constants.ObjectNameMiniSplitHeatPump, slave_zone)
          
          htg_coil = OpenStudio::Model::CoilHeatingDXVariableRefrigerantFlow.new(model)
          htg_coil.setName(obj_name + " #{slave_zone.name} heating coil")
          if miniSplitCoolingOutputCapacity != Constants.SizingAuto
            htg_coil.setRatedTotalHeatingCapacity(OpenStudio::convert(miniSplitHeatingOutputCapacity,"Btu/h","W").get * supply.Capacity_Ratio_Heating[curves.mshp_indices[-1]] * fbsmt_frac)
            htg_coil.setRatedAirFlowRate(supply.HeatingCFMs[curves.mshp_indices[-1]]* miniSplitHeatingOutputCapacity * OpenStudio::convert(1.0,"Btu/h","ton").get * OpenStudio::convert(1.0,"cfm","m^3/s").get * fbsmt_frac)
          end
          htg_coil.setHeatingCapacityRatioModifierFunctionofTemperatureCurve(constant_cubic)
          htg_coil.setHeatingCapacityModifierFunctionofFlowFractionCurve(constant_cubic)        
                  
          clg_coil = OpenStudio::Model::CoilCoolingDXVariableRefrigerantFlow.new(model)
          clg_coil.setName(obj_name + " #{slave_zone.name} cooling coil")
          if miniSplitCoolingOutputCapacity != Constants.SizingAuto
            clg_coil.setRatedTotalCoolingCapacity(OpenStudio::convert(miniSplitCoolingOutputCapacity,"Btu/h","W").get * supply.Capacity_Ratio_Cooling[curves.mshp_indices[-1]] * fbsmt_frac)
            clg_coil.setRatedSensibleHeatRatio(supply.SHR_Rated[curves.mshp_indices[-1]])
            clg_coil.setRatedAirFlowRate(supply.CoolingCFMs[curves.mshp_indices[-1]]* miniSplitCoolingOutputCapacity * OpenStudio::convert(1.0,"Btu/h","ton").get * OpenStudio::convert(1.0,"cfm","m^3/s").get * fbsmt_frac)
          end          
          clg_coil.setCoolingCapacityRatioModifierFunctionofTemperatureCurve(constant_cubic)
          clg_coil.setCoolingCapacityModifierCurveFunctionofFlowFraction(constant_cubic)
                
          vrf = OpenStudio::Model::AirConditionerVariableRefrigerantFlow.new(model)
          vrf.setName(obj_name + " #{slave_zone.name} ac vrf")
          vrf.setAvailabilitySchedule(model.alwaysOnDiscreteSchedule)          
          if miniSplitCoolingOutputCapacity != Constants.SizingAuto
            vrf.setRatedTotalCoolingCapacity(OpenStudio::convert(miniSplitCoolingOutputCapacity,"Btu/h","W").get * supply.Capacity_Ratio_Cooling[curves.mshp_indices[-1]] * fbsmt_frac)
            vrf.setRatedTotalHeatingCapacity(OpenStudio::convert(miniSplitHeatingOutputCapacity,"Btu/h","W").get * supply.Capacity_Ratio_Heating[curves.mshp_indices[-1]] * fbsmt_frac)
          end
          vrf.setRatedCoolingCOP(1.0 / supply.CoolingEIR[-1])
          vrf.setMinimumOutdoorTemperatureinCoolingMode(-6)
          vrf.setMaximumOutdoorTemperatureinCoolingMode(60)          
          vrf.setCoolingCapacityRatioModifierFunctionofLowTemperatureCurve(cool_cap_ft)   
          vrf.setCoolingEnergyInputRatioModifierFunctionofLowTemperatureCurve(cool_eir_ft)
          vrf.setCoolingEnergyInputRatioModifierFunctionofLowPartLoadRatioCurve(cool_eir_fplr)
          vrf.setCoolingPartLoadFractionCorrelationCurve(cool_plf_fplr)
          vrf.setRatedTotalHeatingCapacitySizingRatio(1)
          vrf.setRatedHeatingCOP(1.0 / supply.HeatingEIR[-1])
          vrf.setMinimumOutdoorTemperatureinHeatingMode(OpenStudio::convert(supply.min_hp_temp,"F","C").get)
          vrf.setMaximumOutdoorTemperatureinHeatingMode(40)
          vrf.setHeatingCapacityRatioModifierFunctionofLowTemperatureCurve(heat_cap_ft)
          vrf.setHeatingEnergyInputRatioModifierFunctionofLowTemperatureCurve(heat_eir_ft)
          vrf.setHeatingPerformanceCurveOutdoorTemperatureType("DryBulbTemperature")       
          vrf.setHeatingEnergyInputRatioModifierFunctionofLowPartLoadRatioCurve(heat_eir_fplr)
          vrf.setHeatingPartLoadFractionCorrelationCurve(heat_plf_fplr)          
          vrf.setMinimumHeatPumpPartLoadRatio([min_plr_heat, min_plr_cool].min)
          vrf.setZoneforMasterThermostatLocation(control_zone)
          vrf.setMasterThermostatPriorityControlType("LoadPriority")
          vrf.setHeatPumpWasteHeatRecovery(false)
          vrf.setCrankcaseHeaterPowerperCompressor(0)
          vrf.setNumberofCompressors(1)
          vrf.setRatioofCompressorSizetoTotalCompressorCapacity(1)
          vrf.setDefrostStrategy("ReverseCycle")
          vrf.setDefrostControl("OnDemand")           
          vrf.setDefrostEnergyInputRatioModifierFunctionofTemperatureCurve(defrosteir)          
          vrf.setMaximumOutdoorDrybulbTemperatureforDefrostOperation(OpenStudio::convert(supply.max_defrost_temp,"F","C").get)
          vrf.setFuelType("Electricity")
          vrf.setEquivalentPipingLengthusedforPipingCorrectionFactorinCoolingMode(0)
          vrf.setVerticalHeightusedforPipingCorrectionFactor(0)
          vrf.setPipingCorrectionFactorforHeightinCoolingModeCoefficient(0)
          vrf.setEquivalentPipingLengthusedforPipingCorrectionFactorinHeatingMode(0)     

          fan = OpenStudio::Model::FanOnOff.new(model, model.alwaysOnDiscreteSchedule)
          fan.setName(obj_name + " #{slave_zone.name} supply fan")
          fan.setEndUseSubcategory(Constants.EndUseHVACFan)
          fan.setFanEfficiency(supply.eff)
          fan.setPressureRise(supply.static)
          fan.setMotorEfficiency(1)
          fan.setMotorInAirstreamFraction(1)
                    
          tu_vrf = OpenStudio::Model::ZoneHVACTerminalUnitVariableRefrigerantFlow.new(model, clg_coil, htg_coil, fan)
          tu_vrf.setName(obj_name + " #{slave_zone.name} zone vrf")
          tu_vrf.setTerminalUnitAvailabilityschedule(model.alwaysOnDiscreteSchedule)
          tu_vrf.setSupplyAirFanOperatingModeSchedule(model.alwaysOffDiscreteSchedule)
          tu_vrf.setZoneTerminalUnitOnParasiticElectricEnergyUse(0)
          tu_vrf.setZoneTerminalUnitOffParasiticElectricEnergyUse(0)
          tu_vrf.setRatedTotalHeatingCapacitySizingRatio(1)
          tu_vrf.addToThermalZone(slave_zone)
          vrf.addTerminal(tu_vrf)
          runner.registerInfo("Added '#{tu_vrf.name}' to '#{slave_zone.name}' of #{unit.name}") 
          
          unless baseboardOutputCapacity == "NO SUPP HEAT"
            supp_htg_coil = OpenStudio::Model::ZoneHVACBaseboardConvectiveElectric.new(model)
            supp_htg_coil.setName(obj_name + " #{slave_zone.name} supp heater")
            if baseboardOutputCapacity != Constants.SizingAuto
              supp_htg_coil.setNominalCapacity(OpenStudio::convert(baseboardOutputCapacity,"Btu/h","W").get)
            end
            supp_htg_coil.setEfficiency(baseboardEfficiency)
            supp_htg_coil.addToThermalZone(slave_zone)
            runner.registerInfo("Added '#{supp_htg_coil.name}' to '#{slave_zone.name}' of #{unit.name}")
          end
          
          if miniSplitHPPanHeaterPowerPerUnit > 0            
            vrf_fbsmt_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, vrf_heating_output_var)
            vrf_fbsmt_sensor.setName("#{obj_name} vrf fbsmt energy sensor".gsub("|","_"))
            vrf_fbsmt_sensor.setKeyName(obj_name + " #{slave_zone.name} ac vrf")
          end
            
        end
      
        if miniSplitHPPanHeaterPowerPerUnit > 0

          vrf_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, vrf_heating_output_var)
          vrf_sensor.setName("#{obj_name} vrf energy sensor".gsub("|","_"))
          vrf_sensor.setKeyName(obj_name + " #{control_zone.name} ac vrf")
     
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
            if thermal_zone.name.to_s.start_with? Constants.LivingZone
              tout_sensor.setKeyName(thermal_zone.name.to_s)
              break
            end
          end

          program = OpenStudio::Model::EnergyManagementSystemProgram.new(model)
          program.setName(obj_name + " pan heater program")
          if miniSplitCoolingOutputCapacity != Constants.SizingAuto
            num_outdoor_units = (OpenStudio::convert(miniSplitCoolingOutputCapacity,"Btu/h","ton").get / 1.5).ceil # Assume 1.5 tons max per outdoor unit
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
          program.addLine("If #{tout_sensor.name} <= #{OpenStudio::convert(32.0,"F","C").get.round(3)}")
          program.addLine("Set #{pan_heater_actuator.name} = #{pan_heater_power}")
          program.addLine("EndIf")
          program.addLine("EndIf")
         
          program_calling_manager = OpenStudio::Model::EnergyManagementSystemProgramCallingManager.new(model)
          program_calling_manager.setName(obj_name + " pan heater program calling manager")
          program_calling_manager.setCallingPoint("BeginTimestepBeforePredictor")
          program_calling_manager.addProgram(program)
          
        end
      
      end
      
    end

    return true

  end
  
  def _processCurvesMiniSplitHP(model, curves, min_plr_cool, min_plr_heat)
  
    cool_cap_ft = OpenStudio::Model::CurveBiquadratic.new(model)
    cool_cap_ft.setName("Cool-Cap-fT#{curves.mshp_indices[-1]+1}")
    cool_cap_ft.setCoefficient1Constant(curves.COOL_CAP_FT_SPEC_coefficients[-1][0])
    cool_cap_ft.setCoefficient2x(curves.COOL_CAP_FT_SPEC_coefficients[-1][1])
    cool_cap_ft.setCoefficient3xPOW2(curves.COOL_CAP_FT_SPEC_coefficients[-1][2])
    cool_cap_ft.setCoefficient4y(curves.COOL_CAP_FT_SPEC_coefficients[-1][3])
    cool_cap_ft.setCoefficient5yPOW2(curves.COOL_CAP_FT_SPEC_coefficients[-1][4])
    cool_cap_ft.setCoefficient6xTIMESY(curves.COOL_CAP_FT_SPEC_coefficients[-1][5])
    cool_cap_ft.setMinimumValueofx(13.88)
    cool_cap_ft.setMaximumValueofx(23.88)
    cool_cap_ft.setMinimumValueofy(18.33)
    cool_cap_ft.setMaximumValueofy(51.66)

    cool_eir_ft = OpenStudio::Model::CurveBiquadratic.new(model)
    cool_eir_ft.setName("Cool-EIR-fT#{curves.mshp_indices[-1]+1}")
    cool_eir_ft.setCoefficient1Constant(curves.COOL_EIR_FT_SPEC_coefficients[-1][0])
    cool_eir_ft.setCoefficient2x(curves.COOL_EIR_FT_SPEC_coefficients[-1][1])
    cool_eir_ft.setCoefficient3xPOW2(curves.COOL_EIR_FT_SPEC_coefficients[-1][2])
    cool_eir_ft.setCoefficient4y(curves.COOL_EIR_FT_SPEC_coefficients[-1][3])
    cool_eir_ft.setCoefficient5yPOW2(curves.COOL_EIR_FT_SPEC_coefficients[-1][4])
    cool_eir_ft.setCoefficient6xTIMESY(curves.COOL_EIR_FT_SPEC_coefficients[-1][5])
    cool_eir_ft.setMinimumValueofx(13.88)
    cool_eir_ft.setMaximumValueofx(23.88)
    cool_eir_ft.setMinimumValueofy(18.33)
    cool_eir_ft.setMaximumValueofy(51.66)     
    
    cool_eir_fplr = OpenStudio::Model::CurveQuadratic.new(model)
    cool_eir_fplr.setName("Cool-EIR-fPLR#{curves.mshp_indices[-1]+1}")
    cool_eir_fplr.setCoefficient1Constant(0.100754583)
    cool_eir_fplr.setCoefficient2x(-0.131544809)
    cool_eir_fplr.setCoefficient3xPOW2(1.030916234)
    cool_eir_fplr.setMinimumValueofx(min_plr_cool)
    cool_eir_fplr.setMaximumValueofx(1)
    cool_eir_fplr.setInputUnitTypeforX("Dimensionless")
    cool_eir_fplr.setOutputUnitType("Dimensionless")        
    
    cool_plf_fplr = OpenStudio::Model::CurveQuadratic.new(model)
    cool_plf_fplr.setName("Cool-PLF-fPLR#{curves.mshp_indices[-1]+1}")
    cool_plf_fplr.setCoefficient1Constant(curves.COOL_CLOSS_FPLR_SPEC_coefficients[0])
    cool_plf_fplr.setCoefficient2x(curves.COOL_CLOSS_FPLR_SPEC_coefficients[1])
    cool_plf_fplr.setCoefficient3xPOW2(curves.COOL_CLOSS_FPLR_SPEC_coefficients[2])
    cool_plf_fplr.setMinimumValueofx(0)
    cool_plf_fplr.setMaximumValueofx(1)
    cool_plf_fplr.setMinimumCurveOutput(0.7)
    cool_plf_fplr.setMaximumCurveOutput(1)       

    heat_cap_ft = OpenStudio::Model::CurveBiquadratic.new(model)
    heat_cap_ft.setName("Heat-Cap-fT#{curves.mshp_indices[-1]+1}")
    heat_cap_ft.setCoefficient1Constant(curves.HEAT_CAP_FT_SPEC_coefficients[-1][0])
    heat_cap_ft.setCoefficient2x(curves.HEAT_CAP_FT_SPEC_coefficients[-1][1])
    heat_cap_ft.setCoefficient3xPOW2(curves.HEAT_CAP_FT_SPEC_coefficients[-1][2])
    heat_cap_ft.setCoefficient4y(curves.HEAT_CAP_FT_SPEC_coefficients[-1][3])
    heat_cap_ft.setCoefficient5yPOW2(curves.HEAT_CAP_FT_SPEC_coefficients[-1][4])
    heat_cap_ft.setCoefficient6xTIMESY(curves.HEAT_CAP_FT_SPEC_coefficients[-1][5])
    heat_cap_ft.setMinimumValueofx(-100)
    heat_cap_ft.setMaximumValueofx(100)
    heat_cap_ft.setMinimumValueofy(-100)
    heat_cap_ft.setMaximumValueofy(100)     

    heat_eir_ft = OpenStudio::Model::CurveBiquadratic.new(model)
    heat_eir_ft.setName("Heat-EIR-fT#{curves.mshp_indices[-1]+1}")
    heat_eir_ft.setCoefficient1Constant(curves.HEAT_EIR_FT_SPEC_coefficients[-1][0])
    heat_eir_ft.setCoefficient2x(curves.HEAT_EIR_FT_SPEC_coefficients[-1][1])
    heat_eir_ft.setCoefficient3xPOW2(curves.HEAT_EIR_FT_SPEC_coefficients[-1][2])
    heat_eir_ft.setCoefficient4y(curves.HEAT_EIR_FT_SPEC_coefficients[-1][3])
    heat_eir_ft.setCoefficient5yPOW2(curves.HEAT_EIR_FT_SPEC_coefficients[-1][4])
    heat_eir_ft.setCoefficient6xTIMESY(curves.HEAT_EIR_FT_SPEC_coefficients[-1][5])
    heat_eir_ft.setMinimumValueofx(-100)
    heat_eir_ft.setMaximumValueofx(100)
    heat_eir_ft.setMinimumValueofy(-100)
    heat_eir_ft.setMaximumValueofy(100)        

    heat_eir_fplr = OpenStudio::Model::CurveQuadratic.new(model)
    heat_eir_fplr.setName("Heat-EIR-fPLR#{curves.mshp_indices[-1]+1}")
    heat_eir_fplr.setCoefficient1Constant(-0.169542039)
    heat_eir_fplr.setCoefficient2x(1.167269914)
    heat_eir_fplr.setCoefficient3xPOW2(0.0)
    heat_eir_fplr.setMinimumValueofx(min_plr_heat)
    heat_eir_fplr.setMaximumValueofx(1)
    heat_eir_fplr.setInputUnitTypeforX("Dimensionless")
    heat_eir_fplr.setOutputUnitType("Dimensionless")       

    heat_plf_fplr = OpenStudio::Model::CurveQuadratic.new(model)
    heat_plf_fplr.setName("Heat-PLF-fPLR#{curves.mshp_indices[-1]+1}")
    heat_plf_fplr.setCoefficient1Constant(curves.HEAT_CLOSS_FPLR_SPEC_coefficients[0])
    heat_plf_fplr.setCoefficient2x(curves.HEAT_CLOSS_FPLR_SPEC_coefficients[1])
    heat_plf_fplr.setCoefficient3xPOW2(curves.HEAT_CLOSS_FPLR_SPEC_coefficients[2])
    heat_plf_fplr.setMinimumValueofx(0)
    heat_plf_fplr.setMaximumValueofx(1)
    heat_plf_fplr.setMinimumCurveOutput(0.7)
    heat_plf_fplr.setMaximumCurveOutput(1)

    constant_cubic = OpenStudio::Model::CurveCubic.new(model)
    constant_cubic.setName("ConstantCubic")
    constant_cubic.setCoefficient1Constant(1)
    constant_cubic.setCoefficient2x(0)
    constant_cubic.setCoefficient3xPOW2(0)
    constant_cubic.setCoefficient4xPOW3(0)
    constant_cubic.setMinimumValueofx(-100)
    constant_cubic.setMaximumValueofx(100)    
    
    defrosteir = OpenStudio::Model::CurveBiquadratic.new(model)
    defrosteir.setName("DefrostEIR")
    defrosteir.setCoefficient1Constant(0.1528)
    defrosteir.setCoefficient2x(0)
    defrosteir.setCoefficient3xPOW2(0)
    defrosteir.setCoefficient4y(0)
    defrosteir.setCoefficient5yPOW2(0)
    defrosteir.setCoefficient6xTIMESY(0)
    defrosteir.setMinimumValueofx(-100)
    defrosteir.setMaximumValueofx(100)
    defrosteir.setMinimumValueofy(-100)
    defrosteir.setMaximumValueofy(100)       
    
    return cool_cap_ft, cool_eir_ft, cool_eir_fplr, cool_plf_fplr, heat_cap_ft, heat_eir_ft, heat_eir_fplr, heat_plf_fplr, constant_cubic, defrosteir
  
  end
  
  def _processAirSystemMiniSplitCooling(runner, coolingSEER, cap_min_per, cap_max_per, cfm_ton_min, cfm_ton_max, shr, supplyFanPower, curves, supply)
        
    curves.Number_Speeds = Constants.Num_Speeds_MSHP
    c_d = Constants.MSHP_Cd_Cooling
    cops_Norm = [1.901, 1.859, 1.746, 1.609, 1.474, 1.353, 1.247, 1.156, 1.079, 1.0]
    fanPows_Norm = [0.604, 0.634, 0.670, 0.711, 0.754, 0.800, 0.848, 0.898, 0.948, 1.0]
    
    dB_rated = 80.0      
    wB_rated = 67.0
    
    cap_nom_per = cap_max_per
    cfm_ton_nom = ((cfm_ton_max - cfm_ton_min)/(cap_max_per - cap_min_per)) * (cap_nom_per - cap_min_per) + cfm_ton_min
    ao = Psychrometrics.CoilAoFactor(dB_rated, wB_rated, Constants.Patm, OpenStudio::convert(1,"ton","kBtu/h").get, cfm_ton_nom, shr)
    
    supply.CoolingEIR = [0.0] * Constants.Num_Speeds_MSHP
    supply.Capacity_Ratio_Cooling = [0.0] * Constants.Num_Speeds_MSHP
    supply.CoolingCFMs = [0.0] * Constants.Num_Speeds_MSHP
    supply.SHR_Rated = [0.0] * Constants.Num_Speeds_MSHP
    
    fanPowsRated = [0.0] * Constants.Num_Speeds_MSHP
    eers_Rated = [0.0] * Constants.Num_Speeds_MSHP
    
    cop_maxSpeed = 3.5  # 3.5 is an initial guess, final value solved for below
    
    (0...Constants.Num_Speeds_MSHP).each do |i|
        supply.Capacity_Ratio_Cooling[i] = cap_min_per + i*(cap_max_per - cap_min_per)/(cops_Norm.length-1)
        supply.CoolingCFMs[i]= cfm_ton_min + i*(cfm_ton_max - cfm_ton_min)/(cops_Norm.length-1)
        
        # Calculate the SHR for each speed. Use minimum value of 0.98 to prevent E+ bypass factor calculation errors
        supply.SHR_Rated[i] = [Psychrometrics.CalculateSHR(dB_rated, wB_rated, Constants.Patm, 
                                                                   OpenStudio::convert(supply.Capacity_Ratio_Cooling[i],"ton","kBtu/h").get, 
                                                                   supply.CoolingCFMs[i], ao), 0.98].min
        
        fanPowsRated[i] = supplyFanPower * fanPows_Norm[i] 
        eers_Rated[i] = OpenStudio::convert(cop_maxSpeed,"W","Btu/h").get * cops_Norm[i]   
    end 
        
    cop_maxSpeed_1 = cop_maxSpeed
    cop_maxSpeed_2 = cop_maxSpeed                
    error = coolingSEER - calc_SEER_VariableSpeed(runner, eers_Rated, c_d, supply.Capacity_Ratio_Cooling, supply.CoolingCFMs, fanPowsRated, true, curves.Number_Speeds, curves)                                                            
    error1 = error
    error2 = error
    
    itmax = 50  # maximum iterations
    cvg = false
    final_n = nil
    
    (1...itmax+1).each do |n|
        final_n = n
        (0...Constants.Num_Speeds_MSHP).each do |i|
            eers_Rated[i] = OpenStudio::convert(cop_maxSpeed,"W","Btu/h").get * cops_Norm[i]
        end
        
        error = coolingSEER - calc_SEER_VariableSpeed(runner, eers_Rated, c_d, supply.Capacity_Ratio_Cooling, supply.CoolingCFMs, fanPowsRated, 
                                                     true, curves.Number_Speeds, curves)
        
        cop_maxSpeed,cvg,cop_maxSpeed_1,error1,cop_maxSpeed_2,error2 = MathTools.Iterate(cop_maxSpeed,error,cop_maxSpeed_1,error1,cop_maxSpeed_2,error2,n,cvg)
    
        if cvg 
            break
        end
    end

    if not cvg or final_n > itmax
        cop_maxSpeed = OpenStudio::convert(0.547*coolingSEER - 0.104,"Btu/h","W").get  # Correlation developed from JonW's MatLab scripts. Only used is an EER cannot be found.   
        runner.registerWarning('Mini-split heat pump COP iteration failed to converge. Setting to default value.')
    end
        
    (0...Constants.Num_Speeds_MSHP).each do |i|
        supply.CoolingEIR[i] = HVAC.calc_EIR_from_EER(OpenStudio::convert(cop_maxSpeed,"W","Btu/h").get * cops_Norm[i], fanPowsRated[i])
    end

    curves.COOL_CLOSS_FPLR_SPEC_coefficients = [(1 - c_d), c_d, 0]    # Linear part load model

    supply.fanspeed_ratio = [1]
    supply.min_flow_ratio = supply.CoolingCFMs.min / supply.CoolingCFMs.max

    # Supply Fan
    supply.static = UnitConversion.inH2O2Pa(0.1) # Pascal
    supply.fan_power = supplyFanPower
    supply.eff = OpenStudio::convert(supply.static / supply.fan_power,"cfm","m^3/s").get  # Overall Efficiency of the Supply Fan, Motor and Drive
    
    return curves, supply

  end
  
  def calc_SEER_VariableSpeed(runner, eer_A, c_d, capacityRatio, cfm_Tons, supplyFanPower_Rated, isHeatPump, num_speeds, curves)
    
    n_max = (eer_A.length-1.0)-3.0 # Don't use max speed
    n_min = 0.0
    n_int = (n_min + (n_max-n_min)/3.0).ceil.to_i

    wBin = 67.0
    tout_B = 82.0
    tout_E = 87.0
    tout_F = 67.0
    if num_speeds == Constants.Num_Speeds_MSHP
        wBin = OpenStudio::convert(wBin,"F","C").get
        tout_B = OpenStudio::convert(tout_B,"F","C").get
        tout_E = OpenStudio::convert(tout_E,"F","C").get
        tout_F = OpenStudio::convert(tout_F,"F","C").get
    end

    eir_A2 = HVAC.calc_EIR_from_EER(eer_A[n_max], supplyFanPower_Rated[n_max])    
    eir_B2 = eir_A2 * MathTools.biquadratic(wBin, tout_B, curves.COOL_EIR_FT_SPEC_coefficients[n_max]) 
    
    eir_Av = HVAC.calc_EIR_from_EER(eer_A[n_int], supplyFanPower_Rated[n_int])    
    eir_Ev = eir_Av * MathTools.biquadratic(wBin, tout_E, curves.COOL_EIR_FT_SPEC_coefficients[n_int])
    
    eir_A1 = HVAC.calc_EIR_from_EER(eer_A[n_min], supplyFanPower_Rated[n_min])
    eir_B1 = eir_A1 * MathTools.biquadratic(wBin, tout_B, curves.COOL_EIR_FT_SPEC_coefficients[n_min]) 
    eir_F1 = eir_A1 * MathTools.biquadratic(wBin, tout_F, curves.COOL_EIR_FT_SPEC_coefficients[n_min])
    
    q_A2 = capacityRatio[n_max]
    q_B2 = q_A2 * MathTools.biquadratic(wBin, tout_B, curves.COOL_CAP_FT_SPEC_coefficients[n_max])    
    q_Ev = capacityRatio[n_int] * MathTools.biquadratic(wBin, tout_E, curves.COOL_CAP_FT_SPEC_coefficients[n_int])            
    q_B1 = capacityRatio[n_min] * MathTools.biquadratic(wBin, tout_B, curves.COOL_CAP_FT_SPEC_coefficients[n_min])
    q_F1 = capacityRatio[n_min] * MathTools.biquadratic(wBin, tout_F, curves.COOL_CAP_FT_SPEC_coefficients[n_min])
            
    q_A2_net = q_A2 - supplyFanPower_Rated[n_max] * OpenStudio::convert(1,"W","Btu/h").get * cfm_Tons[n_max] / OpenStudio::convert(1,"ton","Btu/h").get
    q_B2_net = q_B2 - supplyFanPower_Rated[n_max] * OpenStudio::convert(1,"W","Btu/h").get * cfm_Tons[n_max] / OpenStudio::convert(1,"ton","Btu/h").get       
    q_Ev_net = q_Ev - supplyFanPower_Rated[n_int] * OpenStudio::convert(1,"W","Btu/h").get * cfm_Tons[n_int] / OpenStudio::convert(1,"ton","Btu/h").get
    q_B1_net = q_B1 - supplyFanPower_Rated[n_min] * OpenStudio::convert(1,"W","Btu/h").get * cfm_Tons[n_min] / OpenStudio::convert(1,"ton","Btu/h").get
    q_F1_net = q_F1 - supplyFanPower_Rated[n_min] * OpenStudio::convert(1,"W","Btu/h").get * cfm_Tons[n_min] / OpenStudio::convert(1,"ton","Btu/h").get
    
    p_A2 = OpenStudio::convert(q_A2 * eir_A2,"Btu","W*h").get + supplyFanPower_Rated[n_max] * cfm_Tons[n_max] / OpenStudio::convert(1,"ton","Btu/h").get
    p_B2 = OpenStudio::convert(q_B2 * eir_B2,"Btu","W*h").get + supplyFanPower_Rated[n_max] * cfm_Tons[n_max] / OpenStudio::convert(1,"ton","Btu/h").get
    p_Ev = OpenStudio::convert(q_Ev * eir_Ev,"Btu","W*h").get + supplyFanPower_Rated[n_int] * cfm_Tons[n_int] / OpenStudio::convert(1,"ton","Btu/h").get
    p_B1 = OpenStudio::convert(q_B1 * eir_B1,"Btu","W*h").get + supplyFanPower_Rated[n_min] * cfm_Tons[n_min] / OpenStudio::convert(1,"ton","Btu/h").get
    p_F1 = OpenStudio::convert(q_F1 * eir_F1,"Btu","W*h").get + supplyFanPower_Rated[n_min] * cfm_Tons[n_min] / OpenStudio::convert(1,"ton","Btu/h").get
    
    q_k1_87 = q_F1_net + (q_B1_net - q_F1_net) / (82.0 - 67.0) * (87 - 67.0)
    q_k2_87 = q_B2_net + (q_A2_net - q_B2_net) / (95.0 - 82.0) * (87.0 - 82.0)
    n_Q = (q_Ev_net - q_k1_87) / (q_k2_87 - q_k1_87)
    m_Q = (q_B1_net - q_F1_net) / (82.0 - 67.0) * (1.0 - n_Q) + (q_A2_net - q_B2_net) / (95.0 - 82.0) * n_Q    
    p_k1_87 = p_F1 + (p_B1 - p_F1) / (82.0 - 67.0) * (87.0 - 67.0)
    p_k2_87 = p_B2 + (p_A2 - p_B2) / (95.0 - 82.0) * (87.0 - 82.0)
    n_E = (p_Ev - p_k1_87) / (p_k2_87 - p_k1_87)
    m_E = (p_B1 - p_F1) / (82.0 - 67.0) * (1.0 - n_E) + (p_A2 - p_B2) / (95.0 - 82.0) * n_E
    
    c_T_1_1 = q_A2_net / (1.1 * (95.0 - 65.0))
    c_T_1_2 = q_F1_net
    c_T_1_3 = (q_B1_net - q_F1_net) / (82.0 - 67.0)
    t_1 = (c_T_1_2 - 67.0*c_T_1_3 + 65.0*c_T_1_1) / (c_T_1_1 - c_T_1_3)
    q_T_1 = q_F1_net + (q_B1_net - q_F1_net) / (82.0 - 67.0) * (t_1 - 67.0)
    p_T_1 = p_F1 + (p_B1 - p_F1) / (82.0 - 67.0) * (t_1 - 67.0)
    eer_T_1 = q_T_1 / p_T_1 
     
    t_v = (q_Ev_net - 87.0*m_Q + 65.0*c_T_1_1) / (c_T_1_1 - m_Q)
    q_T_v = q_Ev_net + m_Q * (t_v - 87.0)
    p_T_v = p_Ev + m_E * (t_v - 87.0)
    eer_T_v = q_T_v / p_T_v
    
    c_T_2_1 = c_T_1_1
    c_T_2_2 = q_B2_net
    c_T_2_3 = (q_A2_net - q_B2_net) / (95.0 - 82.0)
    t_2 = (c_T_2_2 - 82.0*c_T_2_3 + 65.0*c_T_2_1) / (c_T_2_1 - c_T_2_3)
    q_T_2 = q_B2_net + (q_A2_net - q_B2_net) / (95.0 - 82.0) * (t_2 - 82.0)
    p_T_2 = p_B2 + (p_A2 - p_B2) / (95.0 - 82.0) * (t_2 - 82.0)
    eer_T_2 = q_T_2 / p_T_2 
    
    d = (t_2**2 - t_1**2) / (t_v**2 - t_1**2)
    b = (eer_T_1 - eer_T_2 - d * (eer_T_1 - eer_T_v)) / (t_1 - t_2 - d * (t_1 - t_v))
    c = (eer_T_1 - eer_T_2 - b * (t_1 - t_2)) / (t_1**2 - t_2**2)
    a = eer_T_2 - b * t_2 - c * t_2**2
    
    e_tot = 0
    q_tot = 0    
    t_bins = [67.0,72.0,77.0,82.0,87.0,92.0,97.0,102.0]
    frac_hours = [0.214,0.231,0.216,0.161,0.104,0.052,0.018,0.004]    
    
    (0...8).each do |_i|
        bL = ((t_bins[_i] - 65.0) / (95.0 - 65.0)) * (q_A2_net / 1.1)
        q_k1 = q_F1_net + (q_B1_net - q_F1_net) / (82.0 - 67.0) * (t_bins[_i] - 67.0)
        p_k1 = p_F1 + (p_B1 - p_F1) / (82.0 - 67.0) * (t_bins[_i] - 67)                                
        q_k2 = q_B2_net + (q_A2_net - q_B2_net) / (95.0 - 82.0) * (t_bins[_i] - 82.0)
        p_k2 = p_B2 + (p_A2 - p_B2) / (95.0 - 82.0) * (t_bins[_i] - 82.0)
                
        if bL <= q_k1
            x_k1 = bL / q_k1        
            q_Tj_N = x_k1 * q_k1 * frac_hours[_i]
            e_Tj_N = x_k1 * p_k1 * frac_hours[_i] / (1 - c_d * (1 - x_k1))
        elsif q_k1 < bL and bL <= q_k2
            q_Tj_N = bL * frac_hours[_i]
            eer_T_j = a + b * t_bins[_i] + c * t_bins[_i]**2
            e_Tj_N = q_Tj_N / eer_T_j
        else
            q_Tj_N = frac_hours[_i] * q_k2
            e_Tj_N = frac_hours[_i] * p_k2
        end
         
        q_tot = q_tot + q_Tj_N
        e_tot = e_tot + e_Tj_N   
    end

    seer = q_tot / e_tot
    return seer
  end
  
  def _processAirSystemMiniSplitHeating(runner, heatingHSPF, cap_min_per, cap_max_per, cfm_ton_min, cfm_ton_max, supplyFanPower, mshp_capacity_retention_fraction, mshp_capacity_retention_temperature, curves, supply)
        
    curves.Number_Speeds = Constants.Num_Speeds_MSHP        
    c_d = Constants.MSHP_Cd_Heating
    min_T = Constants.MSHP_Min_T
    
    #COPs_Norm = [1.636, 1.757, 1.388, 1.240, 1.162, 1.119, 1.084, 1.062, 1.044, 1] #Report Avg
    #COPs_Norm = [1.792, 1.502, 1.308, 1.207, 1.145, 1.105, 1.077, 1.056, 1.041, 1] #BEopt Default
    
    cops_Norm = [1.792, 1.502, 1.308, 1.207, 1.145, 1.105, 1.077, 1.056, 1.041, 1] #BEopt Default    
    fanPows_Norm = [0.577, 0.625, 0.673, 0.720, 0.768, 0.814, 0.861, 0.907, 0.954, 1]

    supply.HeatingEIR = [0.0] * Constants.Num_Speeds_MSHP
    supply.Capacity_Ratio_Heating = [0.0] * Constants.Num_Speeds_MSHP
    supply.HeatingCFMs = [0.0] * Constants.Num_Speeds_MSHP      
    
    fanPowsRated = [0.0] * Constants.Num_Speeds_MSHP
    cops_Rated = [0.0] * Constants.Num_Speeds_MSHP
    
    cop_maxSpeed = 3.25  # 3.35 is an initial guess, final value solved for below
    
    (0...Constants.Num_Speeds_MSHP).each do |i|        
        supply.Capacity_Ratio_Heating[i] = cap_min_per + i*(cap_max_per - cap_min_per)/(cops_Norm.length-1)
        supply.HeatingCFMs[i] = cfm_ton_min + i*(cfm_ton_max - cfm_ton_min)/(cops_Norm.length-1)
        
        fanPowsRated[i] = supplyFanPower * fanPows_Norm[i] 
        cops_Rated[i] = cop_maxSpeed * cops_Norm[i]
    end
        
    cop_maxSpeed_1 = cop_maxSpeed
    cop_maxSpeed_2 = cop_maxSpeed                
    error = heatingHSPF - calc_HSPF_VariableSpeed(runner, cops_Rated, c_d, supply.Capacity_Ratio_Heating, supply.HeatingCFMs, fanPowsRated, min_T, curves.Number_Speeds, mshp_capacity_retention_fraction, mshp_capacity_retention_temperature, curves)                                                            
    
    error1 = error
    error2 = error
    
    itmax = 50  # maximum iterations
    cvg = false
    final_n = nil
    
    (1...itmax+1).each do |n|
        final_n = n
        (0...Constants.Num_Speeds_MSHP).each do |i|          
            cops_Rated[i] = cop_maxSpeed * cops_Norm[i]
        end
        
        error = heatingHSPF - calc_HSPF_VariableSpeed(runner, cops_Rated, c_d, supply.Capacity_Ratio_Heating, supply.CoolingCFMs, fanPowsRated, min_T, curves.Number_Speeds, mshp_capacity_retention_fraction, mshp_capacity_retention_temperature, curves)  

        cop_maxSpeed,cvg,cop_maxSpeed_1,error1,cop_maxSpeed_2,error2 = MathTools.Iterate(cop_maxSpeed,error,cop_maxSpeed_1,error1,cop_maxSpeed_2,error2,n,cvg)
    
        if cvg
            break
        end
    end
    
    if not cvg or final_n > itmax
        cop_maxSpeed = OpenStudio::convert(0.4174*heatingHSPF - 1.1134,"Btu/h","W").get  # Correlation developed from JonW's MatLab scripts. Only used is a COP cannot be found.   
        runner.registerWarning('Mini-split heat pump COP iteration failed to converge. Setting to default value.')
    end

    (0...Constants.Num_Speeds_MSHP).each do |i|
        supply.HeatingEIR[i] = HVAC.calc_EIR_from_COP(cop_maxSpeed * cops_Norm[i], fanPowsRated[i])
    end

    curves.HEAT_CLOSS_FPLR_SPEC_coefficients = [(1 - c_d), c_d, 0]    # Linear part load model
            
    # Supply Air Temperatures     
    supply.htg_supply_air_temp = 105.0 # used for sizing heating flow rate
    supply.supp_htg_max_supply_temp = 200.0 # Setting to 200F since MSHPs use electric baseboard for backup, which shouldn't be limited by a supply air temperature limit
    supply.min_hp_temp = min_T          # Minimum temperature for Heat Pump operation
    supply.supp_htg_max_outdoor_temp = 40.0   # Moved from DOE-2. DOE-2 Default
    supply.max_defrost_temp = 40.0        # Moved from DOE-2. DOE-2 Default

    return curves, supply
    
  end  
  
  def calc_HSPF_VariableSpeed(runner, cop_47, c_d, capacityRatio, cfm_Tons, supplyFanPower_Rated, min_temp, num_speeds, mshp_capacity_retention_fraction, mshp_capacity_retention_temperature, curves)
    
    n_max = (cop_47.length-1.0)#-3 # Don't use max speed
    n_min = 0
    n_int = (n_min + (n_max-n_min)/3.0).ceil.to_i

    tin = 70.0
    tout_3 = 17.0
    tout_2 = 35.0
    tout_0 = 62.0
    if num_speeds == Constants.Num_Speeds_MSHP
        tin = OpenStudio::convert(tin,"F","C").get
        tout_3 = OpenStudio::convert(tout_3,"F","C").get
        tout_2 = OpenStudio::convert(tout_2,"F","C").get
        tout_0 = OpenStudio::convert(tout_0,"F","C").get
    end
    
    eir_H1_2 = HVAC.calc_EIR_from_COP(cop_47[n_max], supplyFanPower_Rated[n_max])    
    eir_H3_2 = eir_H1_2 * MathTools.biquadratic(tin, tout_3, curves.HEAT_EIR_FT_SPEC_coefficients[n_max])

    eir_adjv = HVAC.calc_EIR_from_COP(cop_47[n_int], supplyFanPower_Rated[n_int])    
    eir_H2_v = eir_adjv * MathTools.biquadratic(tin, tout_2, curves.HEAT_EIR_FT_SPEC_coefficients[n_int])
        
    eir_H1_1 = HVAC.calc_EIR_from_COP(cop_47[n_min], supplyFanPower_Rated[n_min])
    eir_H0_1 = eir_H1_1 * MathTools.biquadratic(tin, tout_0, curves.HEAT_EIR_FT_SPEC_coefficients[n_min])
        
    q_H1_2 = capacityRatio[n_max]
    q_H3_2 = q_H1_2 * MathTools.biquadratic(tin, tout_3, curves.HEAT_CAP_FT_SPEC_coefficients[n_max])    
        
    q_H2_v = capacityRatio[n_int] * MathTools.biquadratic(tin, tout_2, curves.HEAT_CAP_FT_SPEC_coefficients[n_int])
    
    q_H1_1 = capacityRatio[n_min]
    q_H0_1 = q_H1_1 * MathTools.biquadratic(tin, tout_0, curves.HEAT_CAP_FT_SPEC_coefficients[n_min])
                                  
    q_H1_2_net = q_H1_2 + supplyFanPower_Rated[n_max] * OpenStudio::convert(1,"W","Btu/h").get * cfm_Tons[n_max] / OpenStudio::convert(1,"ton","Btu/h").get
    q_H3_2_net = q_H3_2 + supplyFanPower_Rated[n_max] * OpenStudio::convert(1,"W","Btu/h").get * cfm_Tons[n_max] / OpenStudio::convert(1,"ton","Btu/h").get
    q_H2_v_net = q_H2_v + supplyFanPower_Rated[n_int] * OpenStudio::convert(1,"W","Btu/h").get * cfm_Tons[n_int] / OpenStudio::convert(1,"ton","Btu/h").get
    q_H1_1_net = q_H1_1 + supplyFanPower_Rated[n_min] * OpenStudio::convert(1,"W","Btu/h").get * cfm_Tons[n_min] / OpenStudio::convert(1,"ton","Btu/h").get
    q_H0_1_net = q_H0_1 + supplyFanPower_Rated[n_min] * OpenStudio::convert(1,"W","Btu/h").get * cfm_Tons[n_min] / OpenStudio::convert(1,"ton","Btu/h").get
                                 
    p_H1_2 = q_H1_2 * eir_H1_2 + supplyFanPower_Rated[n_max] * OpenStudio::convert(1,"W","Btu/h").get * cfm_Tons[n_max] / OpenStudio::convert(1,"ton","Btu/h").get
    p_H3_2 = q_H3_2 * eir_H3_2 + supplyFanPower_Rated[n_max] * OpenStudio::convert(1,"W","Btu/h").get * cfm_Tons[n_max] / OpenStudio::convert(1,"ton","Btu/h").get
    p_H2_v = q_H2_v * eir_H2_v + supplyFanPower_Rated[n_int] * OpenStudio::convert(1,"W","Btu/h").get * cfm_Tons[n_int] / OpenStudio::convert(1,"ton","Btu/h").get
    p_H1_1 = q_H1_1 * eir_H1_1 + supplyFanPower_Rated[n_min] * OpenStudio::convert(1,"W","Btu/h").get * cfm_Tons[n_min] / OpenStudio::convert(1,"ton","Btu/h").get
    p_H0_1 = q_H0_1 * eir_H0_1 + supplyFanPower_Rated[n_min] * OpenStudio::convert(1,"W","Btu/h").get * cfm_Tons[n_min] / OpenStudio::convert(1,"ton","Btu/h").get
        
    q_H35_2 = 0.9 * (q_H3_2_net + 0.6 * (q_H1_2_net - q_H3_2_net))
    p_H35_2 = 0.985 * (p_H3_2 + 0.6 * (p_H1_2 - p_H3_2))
    q_H35_1 = q_H1_1_net + (q_H0_1_net - q_H1_1_net) / (62.0 - 47.0) * (35.0 - 47.0)
    p_H35_1 = p_H1_1 + (p_H0_1 - p_H1_1) / (62.0 - 47.0) * (35.0 - 47.0)
    n_Q = (q_H2_v_net - q_H35_1) / (q_H35_2 - q_H35_1)
    m_Q = (q_H0_1_net - q_H1_1_net) / (62.0 - 47.0) * (1 - n_Q) + n_Q * (q_H35_2 - q_H3_2_net) / (35.0 - 17.0)
    n_E = (p_H2_v - p_H35_1) / (p_H35_2 - p_H35_1)
    m_E = (p_H0_1 - p_H1_1) / (62.0 - 47.0) * (1.0 - n_E) + n_E * (p_H35_2 - p_H3_2) / (35.0 - 17.0)    
    
    t_OD = 5.0
    dHR = q_H1_2_net * (65.0 - t_OD) / 60.0
    
    c_T_3_1 = q_H1_1_net
    c_T_3_2 = (q_H0_1_net - q_H1_1_net) / (62.0 - 47.0)
    c_T_3_3 = 0.77 * dHR / (65.0 - t_OD)
    t_3 = (47.0 * c_T_3_2 + 65.0 * c_T_3_3 - c_T_3_1) / (c_T_3_2 + c_T_3_3)
    q_HT3_1 = q_H1_1_net + (q_H0_1_net - q_H1_1_net) / (62.0 - 47.0) * (t_3 - 47.0)
    p_HT3_1 = p_H1_1 + (p_H0_1 - p_H1_1) / (62.0 - 47.0) * (t_3 - 47.0)
    cop_T3_1 = q_HT3_1 / p_HT3_1
    
    c_T_v_1 = q_H2_v_net
    c_T_v_3 = c_T_3_3
    t_v = (35.0 * m_Q + 65.0 * c_T_v_3 - c_T_v_1) / (m_Q + c_T_v_3)
    q_HTv_v = q_H2_v_net + m_Q * (t_v - 35.0)
    p_HTv_v = p_H2_v + m_E * (t_v - 35.0)
    cop_Tv_v = q_HTv_v / p_HTv_v
    
    c_T_4_1 = q_H3_2_net
    c_T_4_2 = (q_H35_2 - q_H3_2_net) / (35.0 - 17.0)
    c_T_4_3 = c_T_v_3
    t_4 = (17.0 * c_T_4_2 + 65.0 * c_T_4_3 - c_T_4_1) / (c_T_4_2 + c_T_4_3)
    q_HT4_2 = q_H3_2_net + (q_H35_2 - q_H3_2_net) / (35.0 - 17.0) * (t_4 - 17.0)
    p_HT4_2 = p_H3_2 + (p_H35_2 - p_H3_2) / (35.0 - 17.0) * (t_4 - 17.0)
    cop_T4_2 = q_HT4_2 / p_HT4_2
    
    d = (t_3**2 - t_4**2) / (t_v**2 - t_4**2)
    b = (cop_T4_2 - cop_T3_1 - d * (cop_T4_2 - cop_Tv_v)) / (t_4 - t_3 - d * (t_4 - t_v))
    c = (cop_T4_2 - cop_T3_1 - b * (t_4 - t_3)) / (t_4**2 - t_3**2)
    a = cop_T4_2 - b * t_4 - c * t_4**2
    
    t_bins = [62.0,57.0,52.0,47.0,42.0,37.0,32.0,27.0,22.0,17.0,12.0,7.0,2.0,-3.0,-8.0]
    frac_hours = [0.132,0.111,0.103,0.093,0.100,0.109,0.126,0.087,0.055,0.036,0.026,0.013,0.006,0.002,0.001]
        
    # T_off = min_temp
    t_off = 10.0
    t_on = t_off + 4.0
    etot = 0        
    bLtot = 0    
    
    (0...15).each do |_i|
        
        bL = ((65.0 - t_bins[_i]) / (65.0 - t_OD)) * 0.77 * dHR
        
        q_1 = q_H1_1_net + (q_H0_1_net - q_H1_1_net) / (62.0 - 47.0) * (t_bins[_i] - 47.0)
        p_1 = p_H1_1 + (p_H0_1 - p_H1_1) / (62.0 - 47.0) * (t_bins[_i] - 47.0)
        
        if t_bins[_i] <= 17.0 or t_bins[_i] >=45.0
            q_2 = q_H3_2_net + (q_H1_2_net - q_H3_2_net) * (t_bins[_i] - 17.0) / (47.0 - 17.0)
            p_2 = p_H3_2 + (p_H1_2 - p_H3_2) * (t_bins[_i] - 17.0) / (47.0 - 17.0)
        else
            q_2 = q_H3_2_net + (q_H35_2 - q_H3_2_net) * (t_bins[_i] - 17) / (35.0 - 17.0)
            p_2 = p_H3_2 + (p_H35_2 - p_H3_2) * (t_bins[_i] - 17.0) / (35.0 - 17.0)
        end
                
        if t_bins[_i] <= t_off
            delta = 0
        elsif t_bins[_i] >= t_on
            delta = 1.0
        else
            delta = 0.5        
        end
        
        if bL <= q_1
            x_1 = bL / q_1
            e_Tj_n = delta * x_1 * p_1 * frac_hours[_i] / (1.0 - c_d * (1.0 - x_1))
        elsif q_1 < bL and bL <= q_2
            cop_T_j = a + b * t_bins[_i] + c * t_bins[_i]**2
            e_Tj_n = delta * frac_hours[_i] * bL / cop_T_j + (1.0 - delta) * bL * (frac_hours[_i])
        else
            e_Tj_n = delta * frac_hours[_i] * p_2 + frac_hours[_i] * (bL - delta *  q_2)
        end
                
        bLtot = bLtot + frac_hours[_i] * bL
        etot = etot + e_Tj_n
    end

    hspf = bLtot / OpenStudio::convert(etot,"Btu/h","W").get    
    return hspf
  end    
  
end

# register the measure to be used by the application
ProcessVRFMinisplit.new.registerWithApplication
