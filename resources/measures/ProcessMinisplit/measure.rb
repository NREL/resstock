# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/psychrometrics"
require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/unit_conversions"
require "#{File.dirname(__FILE__)}/resources/geometry"

# start the measure
class ProcessMinisplit < OpenStudio::Ruleset::ModelUserScript

  class Supply
    def initialize
    end
    attr_accessor(:HPCoolingOversizingFactor, :SpaceConditionedMult, :CoolingEIR, :Capacity_Ratio_Cooling, :CoolingCFMs, :SHR_Rated, :fanspeed_ratio, :min_flow_ratio, :static, :fan_power, :eff, :HeatingEIR, :Capacity_Ratio_Heating, :HeatingCFMs, :htg_supply_air_temp, :supp_htg_max_supply_temp, :min_hp_temp, :supp_htg_max_outdoor_temp, :max_defrost_temp)
  end
  
  class Curves
    def initialize
    end
    attr_accessor(:mshp_indices, :COOL_CAP_FT_SPEC_coefficients, :COOL_EIR_FT_SPEC_coefficients, :COOL_CAP_FFLOW_SPEC_coefficients, :COOL_EIR_FFLOW_SPEC_coefficients, :Number_Speeds, :HEAT_CAP_FT_SPEC_coefficients, :HEAT_EIR_FT_SPEC_coefficients, :HEAT_CAP_FFLOW_SPEC_coefficients, :HEAT_EIR_FFLOW_SPEC_coefficients, :COOL_CLOSS_FPLR_SPEC_coefficients, :HEAT_CLOSS_FPLR_SPEC_coefficients)
  end

  # human readable name
  def name
    return "Set Residential Mini-Split Heat Pump"
  end

  # human readable description
  def description
    return "This measure removes any existing HVAC cooling components (except electric baseboard) from the building and adds a mini-split heat pump."
  end

  # human readable description of modeling approach
  def modeler_description
    return "Any supply components or baseboard convective electrics/waters are removed from any existing air/plant loops or zones. Any existing air/plant loops are also removed. A heating DX coil, cooling DX coil, electric supplemental heating coil, and an on/off supply fan are added to a unitary air loop. The unitary air loop is added to the supply inlet node of the air loop. This air loop is added to a branch for the living zone. A diffuser is added to the branch for the living zone as well as for the finished basement if it exists."
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new
    
    #make a double argument for minisplit cooling rated seer
    miniSplitHPCoolingRatedSEER = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("miniSplitHPCoolingRatedSEER", true)
    miniSplitHPCoolingRatedSEER.setDisplayName("Rated SEER")
    miniSplitHPCoolingRatedSEER.setUnits("Btu/W-h")
    miniSplitHPCoolingRatedSEER.setDescription("Seasonal Energy Efficiency Ratio (SEER) is a measure of equipment energy efficiency over the cooling season.")
    miniSplitHPCoolingRatedSEER.setDefaultValue(14.5)
    args << miniSplitHPCoolingRatedSEER
    
    #make a double argument for minisplit cooling oversize factor
    miniSplitHPCoolingOversizeFactor = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("miniSplitHPCoolingOversizeFactor", true)
    miniSplitHPCoolingOversizeFactor.setDisplayName("Oversize Factor")
    miniSplitHPCoolingOversizeFactor.setUnits("frac")
    miniSplitHPCoolingOversizeFactor.setDescription("Used to scale the auto-sized cooling capacity.")
    miniSplitHPCoolingOversizeFactor.setDefaultValue(1.0)
    args << miniSplitHPCoolingOversizeFactor    
    
    #make a double argument for minisplit cooling min capacity
    miniSplitHPCoolingMinCapacity = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("miniSplitHPCoolingMinCapacity", true)
    miniSplitHPCoolingMinCapacity.setDisplayName("Minimum Cooling Capacity")
    miniSplitHPCoolingMinCapacity.setUnits("frac")
    miniSplitHPCoolingMinCapacity.setDescription("Minimum cooling capacity as a fraction of the nominal cooling capacity at rated conditions.")
    miniSplitHPCoolingMinCapacity.setDefaultValue(0.4)
    args << miniSplitHPCoolingMinCapacity     
    
    #make a double argument for minisplit cooling max capacity
    miniSplitHPCoolingMaxCapacity = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("miniSplitHPCoolingMaxCapacity", true)
    miniSplitHPCoolingMaxCapacity.setDisplayName("Maximum Cooling Capacity")
    miniSplitHPCoolingMaxCapacity.setUnits("frac")
    miniSplitHPCoolingMaxCapacity.setDescription("Maximum cooling capacity as a fraction of the nominal cooling capacity at rated conditions.")
    miniSplitHPCoolingMaxCapacity.setDefaultValue(1.2)
    args << miniSplitHPCoolingMaxCapacity    
    
    #make a double argument for minisplit rated shr
    miniSplitHPRatedSHR = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("miniSplitHPRatedSHR", true)
    miniSplitHPRatedSHR.setDisplayName("Rated SHR")
    miniSplitHPRatedSHR.setDescription("The sensible heat ratio (ratio of the sensible portion of the load to the total load) at the nominal rated capacity.")
    miniSplitHPRatedSHR.setDefaultValue(0.73)
    args << miniSplitHPRatedSHR        
    
    #make a double argument for minisplit cooling min airflow
    miniSplitHPCoolingMinAirflow = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("miniSplitHPCoolingMinAirflow", true)
    miniSplitHPCoolingMinAirflow.setDisplayName("Minimum Cooling Airflow")
    miniSplitHPCoolingMinAirflow.setUnits("cfm/ton")
    miniSplitHPCoolingMinAirflow.setDescription("Minimum cooling cfm divided by the nominal rated cooling capacity.")
    miniSplitHPCoolingMinAirflow.setDefaultValue(200.0)
    args << miniSplitHPCoolingMinAirflow      
    
    #make a double argument for minisplit cooling max airflow
    miniSplitHPCoolingMaxAirflow = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("miniSplitHPCoolingMaxAirflow", true)
    miniSplitHPCoolingMaxAirflow.setDisplayName("Maximum Cooling Airflow")
    miniSplitHPCoolingMaxAirflow.setUnits("cfm/ton")
    miniSplitHPCoolingMaxAirflow.setDescription("Maximum cooling cfm divided by the nominal rated cooling capacity.")
    miniSplitHPCoolingMaxAirflow.setDefaultValue(425.0)
    args << miniSplitHPCoolingMaxAirflow     
    
    #make a double argument for minisplit rated hspf
    miniSplitHPHeatingRatedHSPF = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("miniSplitHPHeatingRatedHSPF", true)
    miniSplitHPHeatingRatedHSPF.setDisplayName("Rated HSPF")
    miniSplitHPHeatingRatedHSPF.setUnits("Btu/W-h")
    miniSplitHPHeatingRatedHSPF.setDescription("The Heating Seasonal Performance Factor (HSPF) is a measure of a heat pump's energy efficiency over one heating season.")
    miniSplitHPHeatingRatedHSPF.setDefaultValue(8.2)
    args << miniSplitHPHeatingRatedHSPF
    
    #make a double argument for minisplit heating capacity offset
    miniSplitHPHeatingCapacityOffset = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("miniSplitHPHeatingCapacityOffset", true)
    miniSplitHPHeatingCapacityOffset.setDisplayName("Heating Capacity Offset")
    miniSplitHPHeatingCapacityOffset.setUnits("Btu/h")
    miniSplitHPHeatingCapacityOffset.setDescription("The difference between the nominal rated heating capacity and the nominal rated cooling capacity.")
    miniSplitHPHeatingCapacityOffset.setDefaultValue(2300.0)
    args << miniSplitHPHeatingCapacityOffset    
    
    #make a double argument for minisplit heating min capacity
    miniSplitHPHeatingMinCapacity = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("miniSplitHPHeatingMinCapacity", true)
    miniSplitHPHeatingMinCapacity.setDisplayName("Minimum Heating Capacity")
    miniSplitHPHeatingMinCapacity.setUnits("frac")
    miniSplitHPHeatingMinCapacity.setDescription("Minimum heating capacity as a fraction of nominal heating capacity at rated conditions.")
    miniSplitHPHeatingMinCapacity.setDefaultValue(0.3)
    args << miniSplitHPHeatingMinCapacity     
    
    #make a double argument for minisplit heating max capacity
    miniSplitHPHeatingMaxCapacity = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("miniSplitHPHeatingMaxCapacity", true)
    miniSplitHPHeatingMaxCapacity.setDisplayName("Maximum Heating Capacity")
    miniSplitHPHeatingMaxCapacity.setUnits("frac")
    miniSplitHPHeatingMaxCapacity.setDescription("Maximum heating capacity as a fraction of nominal heating capacity at rated conditions.")
    miniSplitHPHeatingMaxCapacity.setDefaultValue(1.2)
    args << miniSplitHPHeatingMaxCapacity        
    
    #make a double argument for minisplit heating min airflow
    miniSplitHPHeatingMinAirflow = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("miniSplitHPHeatingMinAirflow", true)
    miniSplitHPHeatingMinAirflow.setDisplayName("Minimum Heating Airflow")
    miniSplitHPHeatingMinAirflow.setUnits("cfm/ton")
    miniSplitHPHeatingMinAirflow.setDescription("Minimum heating cfm divided by the nominal rated heating capacity.")
    miniSplitHPHeatingMinAirflow.setDefaultValue(200.0)
    args << miniSplitHPHeatingMinAirflow     
    
    #make a double argument for minisplit heating min airflow
    miniSplitHPHeatingMaxAirflow = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("miniSplitHPHeatingMaxAirflow", true)
    miniSplitHPHeatingMaxAirflow.setDisplayName("Maximum Heating Airflow")
    miniSplitHPHeatingMaxAirflow.setUnits("cfm/ton")
    miniSplitHPHeatingMaxAirflow.setDescription("Maximum heating cfm divided by the nominal rated heating capacity.")
    miniSplitHPHeatingMaxAirflow.setDefaultValue(400.0)
    args << miniSplitHPHeatingMaxAirflow         
    
    #make a double argument for minisplit supply fan power
    miniSplitHPSupplyFanPower = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("miniSplitHPSupplyFanPower", true)
    miniSplitHPSupplyFanPower.setDisplayName("Supply Fan Power")
    miniSplitHPSupplyFanPower.setUnits("W/cfm")
    miniSplitHPSupplyFanPower.setDescription("Fan power (in W) per delivered airflow rate (in cfm) of the fan.")
    miniSplitHPSupplyFanPower.setDefaultValue(0.07)
    args << miniSplitHPSupplyFanPower     
    
    #make a double argument for minisplit min temp
    miniSplitHPMinT = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("miniSplitHPMinT", true)
    miniSplitHPMinT.setDisplayName("Min Temp")
    miniSplitHPMinT.setUnits("degrees F")
    miniSplitHPMinT.setDescription("Outdoor dry-bulb temperature below which compressor turns off.")
    miniSplitHPMinT.setDefaultValue(5.0)
    args << miniSplitHPMinT
    
    #make a bool argument for whether the minisplit is cold climate
    miniSplitHPIsColdClimate = OpenStudio::Ruleset::OSArgument::makeBoolArgument("miniSplitHPIsColdClimate", true)
    miniSplitHPIsColdClimate.setDisplayName("Is Cold Climate")
    miniSplitHPIsColdClimate.setDescription("Specifies whether the heat pump is a so called 'cold climate heat pump'.")
    miniSplitHPIsColdClimate.setDefaultValue(false)
    args << miniSplitHPIsColdClimate
    
    #make a choice argument for minisplit cooling output capacity
    cap_display_names = OpenStudio::StringVector.new
    cap_display_names << Constants.SizingAuto
    (0.5..10.0).step(0.5) do |tons|
      cap_display_names << "#{tons} tons"
    end

    #make a string argument for minisplit cooling output capacity
    miniSplitCoolingOutputCapacity = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("miniSplitCoolingOutputCapacity", cap_display_names, true)
    miniSplitCoolingOutputCapacity.setDisplayName("Cooling Output Capacity")
    miniSplitCoolingOutputCapacity.setDefaultValue(Constants.SizingAuto)
    args << miniSplitCoolingOutputCapacity

    #make a choice argument for supplemental heating output capacity
    cap_display_names = OpenStudio::StringVector.new
    cap_display_names << "NO SUPP HEAT"
    cap_display_names << Constants.SizingAuto
    (5..150).step(5) do |kbtu|
      cap_display_names << "#{kbtu} kBtu/hr"
    end
    
    #make a string argument for minisplit supplemental heating output capacity
    miniSplitSupplementalHeatingOutputCapacity = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("miniSplitSupplementalHeatingOutputCapacity", cap_display_names, true)
    miniSplitSupplementalHeatingOutputCapacity.setDisplayName("Supplemental Heating Output Capacity")
    miniSplitSupplementalHeatingOutputCapacity.setDefaultValue(Constants.SizingAuto)
    args << miniSplitSupplementalHeatingOutputCapacity    
    
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
    
    miniSplitHPCoolingRatedSEER = runner.getDoubleArgumentValue("miniSplitHPCoolingRatedSEER",user_arguments) 
    miniSplitHPCoolingMinCapacity = runner.getDoubleArgumentValue("miniSplitHPCoolingMinCapacity",user_arguments) 
    miniSplitHPCoolingMaxCapacity = runner.getDoubleArgumentValue("miniSplitHPCoolingMaxCapacity",user_arguments) 
    miniSplitHPCoolingMinAirflow = runner.getDoubleArgumentValue("miniSplitHPCoolingMinAirflow",user_arguments) 
    miniSplitHPCoolingMaxAirflow = runner.getDoubleArgumentValue("miniSplitHPCoolingMaxAirflow",user_arguments) 
    miniSplitHPRatedSHR = runner.getDoubleArgumentValue("miniSplitHPRatedSHR",user_arguments) 
    miniSplitHPSupplyFanPower = runner.getDoubleArgumentValue("miniSplitHPSupplyFanPower",user_arguments) 
    miniSplitHPCoolingOversizeFactor = runner.getDoubleArgumentValue("miniSplitHPCoolingOversizeFactor",user_arguments) 
    miniSplitHPHeatingCapacityOffset = runner.getDoubleArgumentValue("miniSplitHPHeatingCapacityOffset",user_arguments) 
    miniSplitHPHeatingRatedHSPF = runner.getDoubleArgumentValue("miniSplitHPHeatingRatedHSPF",user_arguments) 
    miniSplitHPHeatingMinCapacity = runner.getDoubleArgumentValue("miniSplitHPHeatingMinCapacity",user_arguments) 
    miniSplitHPHeatingMaxCapacity = runner.getDoubleArgumentValue("miniSplitHPHeatingMaxCapacity",user_arguments) 
    miniSplitHPHeatingMinAirflow = runner.getDoubleArgumentValue("miniSplitHPHeatingMinAirflow",user_arguments) 
    miniSplitHPHeatingMaxAirflow = runner.getDoubleArgumentValue("miniSplitHPHeatingMaxAirflow",user_arguments) 
    miniSplitHPMinT = runner.getDoubleArgumentValue("miniSplitHPMinT",user_arguments) 
    miniSplitHPIsColdClimate = runner.getBoolArgumentValue("miniSplitHPIsColdClimate",user_arguments)    
    miniSplitCoolingOutputCapacity = runner.getStringArgumentValue("miniSplitCoolingOutputCapacity",user_arguments)
    unless miniSplitCoolingOutputCapacity == Constants.SizingAuto
      miniSplitCoolingOutputCapacity = OpenStudio::convert(miniSplitCoolingOutputCapacity.split(" ")[0].to_f,"ton","Btu/h").get
      miniSplitHeatingOutputCapacity = miniSplitCoolingOutputCapacity + miniSplitHPHeatingCapacityOffset
    end
    miniSplitSupplementalHeatingOutputCapacity = runner.getStringArgumentValue("miniSplitSupplementalHeatingOutputCapacity",user_arguments)
    if not miniSplitSupplementalHeatingOutputCapacity == Constants.SizingAuto and not miniSplitSupplementalHeatingOutputCapacity == "NO SUPP HEAT"
      miniSplitSupplementalHeatingOutputCapacity = OpenStudio::convert(miniSplitSupplementalHeatingOutputCapacity.split(" ")[0].to_f,"kBtu/h","Btu/h").get
    end
        
    # _processAirSystem       
        
    has_cchp = miniSplitHPIsColdClimate
    
    curves.mshp_indices = [1,3,5,9]
    
    # Cooling Coil
    curves = HVAC.get_cooling_coefficients(runner, Constants.Num_Speeds_MSHP, false, true, curves)

    curves, supply = _processAirSystemMiniSplitCooling(runner, miniSplitHPCoolingRatedSEER, miniSplitHPCoolingMinCapacity, miniSplitHPCoolingMaxCapacity, miniSplitHPCoolingMinAirflow, miniSplitHPCoolingMaxAirflow, miniSplitHPRatedSHR, miniSplitHPSupplyFanPower, curves, supply)
                                           
    supply.HPCoolingOversizingFactor = miniSplitHPCoolingOversizeFactor
    
    # Heating Coil
    curves = HVAC.get_heating_coefficients(runner, Constants.Num_Speeds_MSHP, false, curves, miniSplitHPMinT)
                                                    
    curves, supply = _processAirSystemMiniSplitHeating(runner, miniSplitHPHeatingRatedHSPF, miniSplitHPHeatingMinCapacity, miniSplitHPHeatingMaxCapacity, miniSplitHPHeatingMinAirflow, miniSplitHPHeatingMaxAirflow, miniSplitHPSupplyFanPower, miniSplitHPMinT, curves, supply)    
    
    # _processCurvesSupplyFan
    
    const_biquadratic = OpenStudio::Model::CurveBiquadratic.new(model)
    const_biquadratic.setName("ConstantBiquadratic")
    const_biquadratic.setCoefficient1Constant(1)
    const_biquadratic.setCoefficient2x(0)
    const_biquadratic.setCoefficient3xPOW2(0)
    const_biquadratic.setCoefficient4y(0)
    const_biquadratic.setCoefficient5yPOW2(0)
    const_biquadratic.setCoefficient6xTIMESY(0)
    const_biquadratic.setMinimumValueofx(-100)
    const_biquadratic.setMaximumValueofx(100)
    const_biquadratic.setMinimumValueofy(-100)
    const_biquadratic.setMaximumValueofy(100)    
    
    # _processCurvesMiniSplitHP
    
    htg_coil_stage_data = []
    curves.mshp_indices.each do |i|
        # Heating Capacity f(T). These curves were designed for E+ and do not require unit conversion
        hp_heat_cap_ft = OpenStudio::Model::CurveBiquadratic.new(model)
        hp_heat_cap_ft.setName("HP_Heat-Cap-fT#{i+1}")
        hp_heat_cap_ft.setCoefficient1Constant(curves.HEAT_CAP_FT_SPEC_coefficients[i][0])
        hp_heat_cap_ft.setCoefficient2x(curves.HEAT_CAP_FT_SPEC_coefficients[i][1])
        hp_heat_cap_ft.setCoefficient3xPOW2(curves.HEAT_CAP_FT_SPEC_coefficients[i][2])
        hp_heat_cap_ft.setCoefficient4y(curves.HEAT_CAP_FT_SPEC_coefficients[i][3])
        hp_heat_cap_ft.setCoefficient5yPOW2(curves.HEAT_CAP_FT_SPEC_coefficients[i][4])
        hp_heat_cap_ft.setCoefficient6xTIMESY(curves.HEAT_CAP_FT_SPEC_coefficients[i][5])
        hp_heat_cap_ft.setMinimumValueofx(-100)
        hp_heat_cap_ft.setMaximumValueofx(100)
        hp_heat_cap_ft.setMinimumValueofy(-100)
        hp_heat_cap_ft.setMaximumValueofy(100)
    
        # Heating EIR f(T). These curves were designed for E+ and do not require unit conversion
        hp_heat_eir_ft = OpenStudio::Model::CurveBiquadratic.new(model)
        hp_heat_eir_ft.setName("HP_Heat-EIR-fT#{i+1}")
        hp_heat_eir_ft.setCoefficient1Constant(curves.HEAT_EIR_FT_SPEC_coefficients[i][0])
        hp_heat_eir_ft.setCoefficient2x(curves.HEAT_EIR_FT_SPEC_coefficients[i][1])
        hp_heat_eir_ft.setCoefficient3xPOW2(curves.HEAT_EIR_FT_SPEC_coefficients[i][2])
        hp_heat_eir_ft.setCoefficient4y(curves.HEAT_EIR_FT_SPEC_coefficients[i][3])
        hp_heat_eir_ft.setCoefficient5yPOW2(curves.HEAT_EIR_FT_SPEC_coefficients[i][4])
        hp_heat_eir_ft.setCoefficient6xTIMESY(curves.HEAT_EIR_FT_SPEC_coefficients[i][5])
        hp_heat_eir_ft.setMinimumValueofx(-100)
        hp_heat_eir_ft.setMaximumValueofx(100)
        hp_heat_eir_ft.setMinimumValueofy(-100)
        hp_heat_eir_ft.setMaximumValueofy(100)

        hp_heat_cap_fff = OpenStudio::Model::CurveQuadratic.new(model)
        hp_heat_cap_fff.setName("HP_Heat-Cap-fFF#{i+1}")
        hp_heat_cap_fff.setCoefficient1Constant(curves.HEAT_CAP_FFLOW_SPEC_coefficients[i][0])
        hp_heat_cap_fff.setCoefficient2x(curves.HEAT_CAP_FFLOW_SPEC_coefficients[i][1])
        hp_heat_cap_fff.setCoefficient3xPOW2(curves.HEAT_CAP_FFLOW_SPEC_coefficients[i][2])
        hp_heat_cap_fff.setMinimumValueofx(0)
        hp_heat_cap_fff.setMaximumValueofx(2)
        hp_heat_cap_fff.setMinimumCurveOutput(0)
        hp_heat_cap_fff.setMaximumCurveOutput(2)

        hp_heat_eir_fff = OpenStudio::Model::CurveQuadratic.new(model)
        hp_heat_eir_fff.setName("HP_Heat-EIR-fFF#{i+1}")
        hp_heat_eir_fff.setCoefficient1Constant(curves.HEAT_EIR_FFLOW_SPEC_coefficients[i][0])
        hp_heat_eir_fff.setCoefficient2x(curves.HEAT_EIR_FFLOW_SPEC_coefficients[i][1])
        hp_heat_eir_fff.setCoefficient3xPOW2(curves.HEAT_EIR_FFLOW_SPEC_coefficients[i][2])
        hp_heat_eir_fff.setMinimumValueofx(0)
        hp_heat_eir_fff.setMaximumValueofx(2)
        hp_heat_eir_fff.setMinimumCurveOutput(0)
        hp_heat_eir_fff.setMaximumCurveOutput(2)
        
        hp_heat_plf_fplr = OpenStudio::Model::CurveQuadratic.new(model)
        hp_heat_plf_fplr.setName("HP_Heat-PLF-fPLR#{i+1}")
        hp_heat_plf_fplr.setCoefficient1Constant(curves.HEAT_CLOSS_FPLR_SPEC_coefficients[0])
        hp_heat_plf_fplr.setCoefficient2x(curves.HEAT_CLOSS_FPLR_SPEC_coefficients[1])
        hp_heat_plf_fplr.setCoefficient3xPOW2(curves.HEAT_CLOSS_FPLR_SPEC_coefficients[2])
        hp_heat_plf_fplr.setMinimumValueofx(0)
        hp_heat_plf_fplr.setMaximumValueofx(1)
        hp_heat_plf_fplr.setMinimumCurveOutput(0.7)
        hp_heat_plf_fplr.setMaximumCurveOutput(1)        
        
        stage_data = OpenStudio::Model::CoilHeatingDXMultiSpeedStageData.new(model, hp_heat_cap_ft, hp_heat_cap_fff, hp_heat_eir_ft, hp_heat_eir_fff, hp_heat_plf_fplr, const_biquadratic)
        if miniSplitCoolingOutputCapacity != Constants.SizingAuto
          stage_data.setGrossRatedHeatingCapacity(OpenStudio::convert(miniSplitHeatingOutputCapacity,"Btu/h","W").get * supply.Capacity_Ratio_Heating[i])
          stage_data.setRatedAirFlowRate(OpenStudio::convert(supply.HeatingCFMs[i] * OpenStudio::convert(miniSplitHeatingOutputCapacity,"Btu/h","ton").get,"cfm","m^3/s").get)
        end
        stage_data.setGrossRatedHeatingCOP(1.0 / supply.HeatingEIR[i])
        stage_data.setRatedWasteHeatFractionofPowerInput(0.2)
        htg_coil_stage_data[i] = stage_data
    end 
    
    clg_coil_stage_data = []
    curves.mshp_indices.each do |i|
        # Cooling Capacity f(T). These curves were designed for E+ and do not require unit conversion
        cool_cap_ft = OpenStudio::Model::CurveBiquadratic.new(model)
        cool_cap_ft.setName("Cool-Cap-fT#{i+1}")
        cool_cap_ft.setCoefficient1Constant(curves.COOL_CAP_FT_SPEC_coefficients[i][0])
        cool_cap_ft.setCoefficient2x(curves.COOL_CAP_FT_SPEC_coefficients[i][1])
        cool_cap_ft.setCoefficient3xPOW2(curves.COOL_CAP_FT_SPEC_coefficients[i][2])
        cool_cap_ft.setCoefficient4y(curves.COOL_CAP_FT_SPEC_coefficients[i][3])
        cool_cap_ft.setCoefficient5yPOW2(curves.COOL_CAP_FT_SPEC_coefficients[i][4])
        cool_cap_ft.setCoefficient6xTIMESY(curves.COOL_CAP_FT_SPEC_coefficients[i][5])
        cool_cap_ft.setMinimumValueofx(13.88)
        cool_cap_ft.setMaximumValueofx(23.88)
        cool_cap_ft.setMinimumValueofy(18.33)
        cool_cap_ft.setMaximumValueofy(51.66)

        # Cooling EIR f(T). These curves were designed for E+ and do not require unit conversion
        cool_eir_ft = OpenStudio::Model::CurveBiquadratic.new(model)
        cool_eir_ft.setName("Cool-EIR-fT#{i+1}")
        cool_eir_ft.setCoefficient1Constant(curves.COOL_EIR_FT_SPEC_coefficients[i][0])
        cool_eir_ft.setCoefficient2x(curves.COOL_EIR_FT_SPEC_coefficients[i][1])
        cool_eir_ft.setCoefficient3xPOW2(curves.COOL_EIR_FT_SPEC_coefficients[i][2])
        cool_eir_ft.setCoefficient4y(curves.COOL_EIR_FT_SPEC_coefficients[i][3])
        cool_eir_ft.setCoefficient5yPOW2(curves.COOL_EIR_FT_SPEC_coefficients[i][4])
        cool_eir_ft.setCoefficient6xTIMESY(curves.COOL_EIR_FT_SPEC_coefficients[i][5])
        cool_eir_ft.setMinimumValueofx(13.88)
        cool_eir_ft.setMaximumValueofx(23.88)
        cool_eir_ft.setMinimumValueofy(18.33)
        cool_eir_ft.setMaximumValueofy(51.66)        
    
        cool_cap_fff = OpenStudio::Model::CurveQuadratic.new(model)
        cool_cap_fff.setName("Cool-Cap-fFF#{i+1}")
        cool_cap_fff.setCoefficient1Constant(curves.COOL_CAP_FFLOW_SPEC_coefficients[i][0])
        cool_cap_fff.setCoefficient2x(curves.COOL_CAP_FFLOW_SPEC_coefficients[i][1])
        cool_cap_fff.setCoefficient3xPOW2(curves.COOL_CAP_FFLOW_SPEC_coefficients[i][2])
        cool_cap_fff.setMinimumValueofx(0)
        cool_cap_fff.setMaximumValueofx(2)
        cool_cap_fff.setMinimumCurveOutput(0)
        cool_cap_fff.setMaximumCurveOutput(2)          

        cool_eir_fff = OpenStudio::Model::CurveQuadratic.new(model)
        cool_eir_fff.setName("Cool-EIR-fFF#{i+1}")
        cool_eir_fff.setCoefficient1Constant(curves.COOL_EIR_FFLOW_SPEC_coefficients[i][0])
        cool_eir_fff.setCoefficient2x(curves.COOL_EIR_FFLOW_SPEC_coefficients[i][1])
        cool_eir_fff.setCoefficient3xPOW2(curves.COOL_EIR_FFLOW_SPEC_coefficients[i][2])
        cool_eir_fff.setMinimumValueofx(0)
        cool_eir_fff.setMaximumValueofx(2)
        cool_eir_fff.setMinimumCurveOutput(0)
        cool_eir_fff.setMaximumCurveOutput(2)        
    
        cool_plf_fplr = OpenStudio::Model::CurveQuadratic.new(model)
        cool_plf_fplr.setName("Cool-PLF-fPLR#{i+1}")
        cool_plf_fplr.setCoefficient1Constant(curves.COOL_CLOSS_FPLR_SPEC_coefficients[0])
        cool_plf_fplr.setCoefficient2x(curves.COOL_CLOSS_FPLR_SPEC_coefficients[1])
        cool_plf_fplr.setCoefficient3xPOW2(curves.COOL_CLOSS_FPLR_SPEC_coefficients[2])
        cool_plf_fplr.setMinimumValueofx(0)
        cool_plf_fplr.setMaximumValueofx(1)
        cool_plf_fplr.setMinimumCurveOutput(0.7)
        cool_plf_fplr.setMaximumCurveOutput(1)        
        
        stage_data = OpenStudio::Model::CoilCoolingDXMultiSpeedStageData.new(model, cool_cap_ft, cool_cap_fff, cool_eir_ft, cool_eir_fff, cool_plf_fplr, const_biquadratic)
        if miniSplitCoolingOutputCapacity != Constants.SizingAuto
          stage_data.setGrossRatedTotalCoolingCapacity(OpenStudio::convert(miniSplitCoolingOutputCapacity,"Btu/h","W").get * supply.Capacity_Ratio_Cooling[i])
          stage_data.setRatedAirFlowRate(OpenStudio::convert(supply.CoolingCFMs[i] * OpenStudio::convert(miniSplitCoolingOutputCapacity,"Btu/h","ton").get,"cfm","m^3/s").get)
          stage_data.setGrossRatedSensibleHeatRatio(supply.SHR_Rated[i])
        end
        stage_data.setGrossRatedCoolingCOP(1.0 / supply.CoolingEIR[i])
        stage_data.setNominalTimeforCondensateRemovaltoBegin(1000)
        stage_data.setRatioofInitialMoistureEvaporationRateandSteadyStateLatentCapacity(1.5)
        stage_data.setMaximumCyclingRate(3)
        stage_data.setLatentCapacityTimeConstant(45)
        stage_data.setRatedWasteHeatFractionofPowerInput(0.2)
        clg_coil_stage_data[i] = stage_data    
    end
    
    # Heating defrost curve for reverse cycle
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
    
    # Check if has equipment
    HelperMethods.remove_hot_water_loop(model, runner)    
    
    control_slave_zones_hash = Geometry.get_control_and_slave_zones(model)
    control_slave_zones_hash.each do |control_zone, slave_zones|

      # Remove existing equipment
      HelperMethods.remove_existing_hvac_equipment(model, runner, "Mini-Split Heat Pump", control_zone)
    
      # _processSystemHeatingCoil
      
      htg_coil = OpenStudio::Model::CoilHeatingDXMultiSpeed.new(model)
      htg_coil.setName("DX Heating Coil")
      htg_coil.setMinimumOutdoorDryBulbTemperatureforCompressorOperation(OpenStudio::convert(supply.min_hp_temp,"F","C").get)
      htg_coil.setCrankcaseHeaterCapacity(0)
      htg_coil.setDefrostEnergyInputRatioFunctionofTemperatureCurve(defrosteir)
      htg_coil.setMaximumOutdoorDryBulbTemperatureforDefrostOperation(OpenStudio::convert(supply.max_defrost_temp,"F","C").get)
      htg_coil.setDefrostStrategy("ReverseCycle")
      htg_coil.setDefrostControl("OnDemand")
      htg_coil.setApplyPartLoadFractiontoSpeedsGreaterthan1(false)
      htg_coil.setFuelType("Electricity")
      
      heating_indices = curves.mshp_indices
      heating_indices.each do |i|
          htg_coil.addStage(htg_coil_stage_data[i])    
      end
     
      supp_htg_coil = OpenStudio::Model::CoilHeatingElectric.new(model, model.alwaysOnDiscreteSchedule)
      supp_htg_coil.setName("HeatPump Supp Heater")
      supp_htg_coil.setEfficiency(1)
      if miniSplitSupplementalHeatingOutputCapacity == "NO SUPP HEAT"
        supp_htg_coil.setNominalCapacity(0)
      elsif miniSplitSupplementalHeatingOutputCapacity != Constants.SizingAuto
        supp_htg_coil.setNominalCapacity(OpenStudio::convert(miniSplitSupplementalHeatingOutputCapacity,"Btu/h","W").get)
      end
     
      # _processSystemCoolingCoil
      
      clg_coil = OpenStudio::Model::CoilCoolingDXMultiSpeed.new(model)
      clg_coil.setName("DX Cooling Coil")
      clg_coil.setCondenserType("AirCooled")
      clg_coil.setApplyPartLoadFractiontoSpeedsGreaterthan1(false)
      clg_coil.setApplyLatentDegradationtoSpeedsGreaterthan1(false)
      clg_coil.setCrankcaseHeaterCapacity(0)
      clg_coil.setFuelType("Electricity")
    
      cooling_indices = curves.mshp_indices
      cooling_indices.each do |i|
          clg_coil.addStage(clg_coil_stage_data[i])
      end   
      
      # _processSystemFan
      
      supply_fan_availability = OpenStudio::Model::ScheduleConstant.new(model)
      supply_fan_availability.setName("SupplyFanAvailability")
      supply_fan_availability.setValue(1)

      fan = OpenStudio::Model::FanOnOff.new(model, supply_fan_availability)
      fan.setName("Supply Fan")
      fan.setEndUseSubcategory("HVACFan")
      fan.setFanEfficiency(supply.eff)
      fan.setPressureRise(supply.static)
      fan.setMotorEfficiency(1)
      fan.setMotorInAirstreamFraction(1)

      supply_fan_operation = OpenStudio::Model::ScheduleConstant.new(model)
      supply_fan_operation.setName("SupplyFanOperation")
      supply_fan_operation.setValue(0)    
      
      # _processSystemAir
      
      air_loop_unitary = OpenStudio::Model::AirLoopHVACUnitaryHeatPumpAirToAirMultiSpeed.new(model, fan, htg_coil, clg_coil, supp_htg_coil)
      air_loop_unitary.setName("Forced Air System")
      air_loop_unitary.setAvailabilitySchedule(model.alwaysOnDiscreteSchedule)
      air_loop_unitary.setSupplyAirFanPlacement("BlowThrough")
      air_loop_unitary.setSupplyAirFanOperatingModeSchedule(supply_fan_operation)
      air_loop_unitary.setMinimumOutdoorDryBulbTemperatureforCompressorOperation(OpenStudio::convert(supply.min_hp_temp,"F","C").get)
      air_loop_unitary.setMaximumSupplyAirTemperaturefromSupplementalHeater(OpenStudio::convert(supply.supp_htg_max_supply_temp,"F","C").get)
      air_loop_unitary.setMaximumOutdoorDryBulbTemperatureforSupplementalHeaterOperation(OpenStudio::convert(supply.supp_htg_max_outdoor_temp,"F","C").get)
      air_loop_unitary.setAuxiliaryOnCycleElectricPower(0)
      air_loop_unitary.setAuxiliaryOffCycleElectricPower(0)
      air_loop_unitary.setSupplyAirFlowRateWhenNoCoolingorHeatingisNeeded(0)
      air_loop_unitary.setNumberofSpeedsforHeating(4)
      air_loop_unitary.setNumberofSpeedsforCooling(4)
      
      air_loop = OpenStudio::Model::AirLoopHVAC.new(model)
      air_loop.setName("Central Air System")
      air_supply_inlet_node = air_loop.supplyInletNode
      air_supply_outlet_node = air_loop.supplyOutletNode
      air_demand_inlet_node = air_loop.demandInletNode
      air_demand_outlet_node = air_loop.demandOutletNode    
      
      air_loop_unitary.addToNode(air_supply_inlet_node)

      runner.registerInfo("Added on/off fan '#{fan.name}' to branch '#{air_loop_unitary.name}' of air loop '#{air_loop.name}'")
      runner.registerInfo("Added DX cooling coil '#{clg_coil.name}' to branch '#{air_loop_unitary.name}' of air loop '#{air_loop.name}'")
      runner.registerInfo("Added DX heating coil '#{htg_coil.name}' to branch '#{air_loop_unitary.name}' of air loop '#{air_loop.name}'")
      runner.registerInfo("Added electric heating coil '#{supp_htg_coil.name}' to branch '#{air_loop_unitary.name}' of air loop '#{air_loop.name}'")

      air_loop_unitary.setControllingZoneorThermostatLocation(control_zone)    
      
      # _processSystemDemandSideAir
      # Demand Side

      # Supply Air
      zone_splitter = air_loop.zoneSplitter
      zone_splitter.setName("Zone Splitter")

      diffuser_living = OpenStudio::Model::AirTerminalSingleDuctUncontrolled.new(model, model.alwaysOnDiscreteSchedule)
      diffuser_living.setName("Living Zone Direct Air")
      # diffuser_living.setMaximumAirFlowRate(OpenStudio::convert(supply.Living_AirFlowRate,"cfm","m^3/s").get)
      air_loop.addBranchForZone(control_zone, diffuser_living.to_StraightComponent)

      air_loop.addBranchForZone(control_zone)
      runner.registerInfo("Added air loop '#{air_loop.name}' to thermal zone '#{control_zone.name}'")

      slave_zones.each do |slave_zone|

        HelperMethods.has_boiler(model, runner, slave_zone, true)
        HelperMethods.has_electric_baseboard(model, runner, slave_zone, true)
    
        diffuser_fbsmt = OpenStudio::Model::AirTerminalSingleDuctUncontrolled.new(model, model.alwaysOnDiscreteSchedule)
        diffuser_fbsmt.setName("FBsmt Zone Direct Air")
        # diffuser_fbsmt.setMaximumAirFlowRate(OpenStudio::convert(supply.Living_AirFlowRate,"cfm","m^3/s").get)
        air_loop.addBranchForZone(slave_zone, diffuser_fbsmt.to_StraightComponent)

        air_loop.addBranchForZone(slave_zone)
        runner.registerInfo("Added air loop '#{air_loop.name}' to thermal zone '#{slave_zone.name}'")

      end    
    
    end
    
    return true

  end
  
  def _processAirSystemMiniSplitCooling(runner, coolingSEER, cap_min_per, cap_max_per, cfm_ton_min, cfm_ton_max, shr, supplyFanPower, curves, supply)
        
    curves.Number_Speeds = Constants.Num_Speeds_MSHP
    c_d = Constants.MSHP_Cd_Cooling
    cops_Norm = [1.901, 1.859, 1.746, 1.609, 1.474, 1.353, 1.247, 1.156, 1.079, 1.0]
    fanPows_Norm = [0.604, 0.634, 0.670, 0.711, 0.754, 0.800, 0.848, 0.898, 0.948, 1.0]
    
    dB_rated = 80.0      
    wB_rated = 67.0
    
    cap_nom_per = 1.0
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
        
        # Calculate the SHR for each speed. Use mimnimum value of 0.98 to prevent E+ bypass factor calculation errors
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
        
        cop_maxSpeed,cvg,cop_maxSpeed_1,error1,cop_maxSpeed_2,error2 = HelperMethods.Iterate(cop_maxSpeed,error,cop_maxSpeed_1,error1,cop_maxSpeed_2,error2,n,cvg)
    
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
    
    #Note: Make sure this method still works for BEopt central, variable speed units, which have 4 speeds (if needed in future)
    
    curves = HVAC.get_cooling_coefficients(runner, num_speeds, false, isHeatPump, curves)

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
    eir_B2 = eir_A2 * HelperMethods.biquadratic(wBin, tout_B, curves.COOL_EIR_FT_SPEC_coefficients[n_max]) 
    
    eir_Av = HVAC.calc_EIR_from_EER(eer_A[n_int], supplyFanPower_Rated[n_int])    
    eir_Ev = eir_Av * HelperMethods.biquadratic(wBin, tout_E, curves.COOL_EIR_FT_SPEC_coefficients[n_int])
    
    eir_A1 = HVAC.calc_EIR_from_EER(eer_A[n_min], supplyFanPower_Rated[n_min])
    eir_B1 = eir_A1 * HelperMethods.biquadratic(wBin, tout_B, curves.COOL_EIR_FT_SPEC_coefficients[n_min]) 
    eir_F1 = eir_A1 * HelperMethods.biquadratic(wBin, tout_F, curves.COOL_EIR_FT_SPEC_coefficients[n_min])
    
    q_A2 = capacityRatio[n_max]
    q_B2 = q_A2 * HelperMethods.biquadratic(wBin, tout_B, curves.COOL_CAP_FT_SPEC_coefficients[n_max])    
    q_Ev = capacityRatio[n_int] * HelperMethods.biquadratic(wBin, tout_E, curves.COOL_CAP_FT_SPEC_coefficients[n_int])            
    q_B1 = capacityRatio[n_min] * HelperMethods.biquadratic(wBin, tout_B, curves.COOL_CAP_FT_SPEC_coefficients[n_min])
    q_F1 = capacityRatio[n_min] * HelperMethods.biquadratic(wBin, tout_F, curves.COOL_CAP_FT_SPEC_coefficients[n_min])
            
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
  
  def _processAirSystemMiniSplitHeating(runner, heatingHSPF, cap_min_per, cap_max_per, cfm_ton_min, cfm_ton_max, supplyFanPower, min_T, curves, supply)
        
    curves.Number_Speeds = Constants.Num_Speeds_MSHP        
    c_d = Constants.MSHP_Cd_Heating        
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
    error = heatingHSPF - calc_HSPF_VariableSpeed(runner, cops_Rated, c_d, supply.Capacity_Ratio_Heating, supply.HeatingCFMs, 
                                                  fanPowsRated, min_T, curves.Number_Speeds, curves)                                                            
    
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
        
        error = heatingHSPF - calc_HSPF_VariableSpeed(runner, cops_Rated, c_d, supply.Capacity_Ratio_Heating, supply.CoolingCFMs, 
                                                      fanPowsRated, min_T, curves.Number_Speeds, curves)  

        cop_maxSpeed,cvg,cop_maxSpeed_1,error1,cop_maxSpeed_2,error2 = \
                HelperMethods.Iterate(cop_maxSpeed,error,cop_maxSpeed_1,error1,cop_maxSpeed_2,error2,n,cvg)
    
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
            
    # Supply Air Tempteratures     
    supply.htg_supply_air_temp = 105.0 # used for sizing heating flow rate
    supply.supp_htg_max_supply_temp = 200.0 # Setting to 200F since MSHPs use electric baseboard for backup, which shouldn't be limited by a supply air temperature limit
    supply.min_hp_temp = min_T          # Minimum temperature for Heat Pump operation
    supply.supp_htg_max_outdoor_temp = 40.0   # Moved from DOE-2. DOE-2 Default
    supply.max_defrost_temp = 40.0        # Moved from DOE-2. DOE-2 Default

    return curves, supply
    
  end
  
  
  def calc_HSPF_VariableSpeed(runner, cop_47, c_d, capacityRatio, cfm_Tons, supplyFanPower_Rated, min_temp, num_speeds, curves)
    
    #TODO: Make sure this method still works for BEopt central, variable speed units, which have 4 speeds, if needed in future
    
    curves = HVAC.get_heating_coefficients(runner, 10, false, curves, min_temp)
    
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
    eir_H3_2 = eir_H1_2 * HelperMethods.biquadratic(tin, tout_3, curves.HEAT_EIR_FT_SPEC_coefficients[n_max])

    eir_adjv = HVAC.calc_EIR_from_COP(cop_47[n_int], supplyFanPower_Rated[n_int])    
    eir_H2_v = eir_adjv * HelperMethods.biquadratic(tin, tout_2, curves.HEAT_EIR_FT_SPEC_coefficients[n_int])
        
    eir_H1_1 = HVAC.calc_EIR_from_COP(cop_47[n_min], supplyFanPower_Rated[n_min])
    eir_H0_1 = eir_H1_1 * HelperMethods.biquadratic(tin, tout_0, curves.HEAT_EIR_FT_SPEC_coefficients[n_min])
        
    q_H1_2 = capacityRatio[n_max]
    q_H3_2 = q_H1_2 * HelperMethods.biquadratic(tin, tout_3, curves.HEAT_CAP_FT_SPEC_coefficients[n_max])    
        
    q_H2_v = capacityRatio[n_int] * HelperMethods.biquadratic(tin, tout_2, curves.HEAT_CAP_FT_SPEC_coefficients[n_int])
    
    q_H1_1 = capacityRatio[n_min]
    q_H0_1 = q_H1_1 * HelperMethods.biquadratic(tin, tout_0, curves.HEAT_CAP_FT_SPEC_coefficients[n_min])
                                  
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
ProcessMinisplit.new.registerWithApplication
