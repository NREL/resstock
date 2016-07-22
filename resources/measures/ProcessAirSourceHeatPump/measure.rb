#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"
require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/unit_conversions"

#start the measure
class ProcessAirSourceHeatPump < OpenStudio::Ruleset::ModelUserScript

  class HeatPump
    def initialize(hpNumberSpeeds, hpCoolingEER, hpCoolingInstalledSEER, hpSupplyFanPowerInstalled, hpSupplyFanPowerRated, hpSHRRated, hpCapacityRatio, hpFanspeedRatioCooling, hpCondenserType, hpCrankcase, hpCrankcaseMaxT, hpEERCapacityDerateFactor, hpHeatingCOP, hpHeatingInstalledHSPF, hpFanspeedRatioHeating, hpMinT, hpCOPCapacityDerateFactor, hpRatedAirFlowRateCooling, hpRatedAirFlowRateHeating)
      @hpNumberSpeeds = hpNumberSpeeds
      @hpCoolingEER = hpCoolingEER
      @hpCoolingInstalledSEER = hpCoolingInstalledSEER
      @hpSupplyFanPowerInstalled = hpSupplyFanPowerInstalled
      @hpSupplyFanPowerRated = hpSupplyFanPowerRated
      @hpSHRRated = hpSHRRated
      @hpCapacityRatio = hpCapacityRatio
      @hpFanspeedRatioCooling = hpFanspeedRatioCooling
      @hpCondenserType = hpCondenserType
      @hpCrankcase = hpCrankcase
      @hpCrankcaseMaxT = hpCrankcaseMaxT
      @hpEERCapacityDerateFactor = hpEERCapacityDerateFactor
      @hpHeatingCOP = hpHeatingCOP
      @hpHeatingInstalledHSPF = hpHeatingInstalledHSPF
      @hpFanspeedRatioHeating = hpFanspeedRatioHeating
      @hpMinT = hpMinT
      @hpCOPCapacityDerateFactor = hpCOPCapacityDerateFactor
      @hpRatedAirFlowRateCooling = hpRatedAirFlowRateCooling
      @hpRatedAirFlowRateHeating = hpRatedAirFlowRateHeating
    end

    def HPNumberSpeeds
      return @hpNumberSpeeds
    end

    def HPCoolingEER
      return @hpCoolingEER
    end

    def HPCoolingInstalledSEER
      return @hpCoolingInstalledSEER
    end

    def HPSupplyFanPowerInstalled
      return @hpSupplyFanPowerInstalled
    end

    def HPSupplyFanPowerRated
      return @hpSupplyFanPowerRated
    end

    def HPSHRRated
      return @hpSHRRated
    end

    def HPCapacityRatio
      return @hpCapacityRatio
    end

    def HPFanspeedRatioCooling
      return @hpFanspeedRatioCooling
    end

    def HPCondenserType
      return @hpCondenserType
    end

    def HPCrankcase
      return @hpCrankcase
    end

    def HPCrankcaseMaxT
      return @hpCrankcaseMaxT
    end

    def HPEERCapacityDerateFactor
      return @hpEERCapacityDerateFactor
    end

    def HPHeatingCOP
      return @hpHeatingCOP
    end

    def HPHeatingInstalledHSPF
      return @hpHeatingInstalledHSPF
    end

    def HPFanspeedRatioHeating
      return @hpFanspeedRatioHeating
    end

    def HPMinT
      return @hpMinT
    end

    def HPCOPCapacityDerateFactor
      return @hpCOPCapacityDerateFactor
    end

    def HPRatedAirFlowRateCooling
      return @hpRatedAirFlowRateCooling
    end

    def HPRatedAirFlowRateHeating
      return @hpRatedAirFlowRateHeating
    end
  end

  class AirConditioner
    def initialize(acCoolingInstalledSEER)
      @acCoolingInstalledSEER = acCoolingInstalledSEER
    end

    attr_accessor(:hasIdealAC)

    def ACCoolingInstalledSEER
      return @acCoolingInstalledSEER
    end
  end

  class Supply
    def initialize
    end
    attr_accessor(:static, :cfm_ton, :HPCoolingOversizingFactor, :SpaceConditionedMult, :fan_power, :eff, :min_flow_ratio, :FAN_EIR_FPLR_SPEC_coefficients, :max_temp, :Heat_Capacity, :compressor_speeds, :Zone_Water_Remove_Cap_Ft_DB_RH_Coefficients, :Zone_Energy_Factor_Ft_DB_RH_Coefficients, :Zone_DXDH_PLF_F_PLR_Coefficients, :Number_Speeds, :fanspeed_ratio, :CFM_TON_Rated, :COOL_CAP_FT_SPEC_coefficients, :COOL_EIR_FT_SPEC_coefficients, :COOL_CAP_FFLOW_SPEC_coefficients, :COOL_EIR_FFLOW_SPEC_coefficients, :CoolingEIR, :SHR_Rated, :COOL_CLOSS_FPLR_SPEC_coefficients, :Capacity_Ratio_Cooling, :CondenserType, :Crankcase, :Crankcase_MaxT, :EER_CapacityDerateFactor, :HEAT_CAP_FT_SPEC_coefficients, :HEAT_EIR_FT_SPEC_coefficients, :HEAT_CAP_FFLOW_SPEC_coefficients, :HEAT_EIR_FFLOW_SPEC_coefficients, :CFM_TON_Rated_Heat, :HeatingEIR, :HEAT_CLOSS_FPLR_SPEC_coefficients, :Capacity_Ratio_Heating, :fanspeed_ratio_heating, :min_hp_temp, :max_defrost_temp, :COP_CapacityDerateFactor, :fan_power_rated, :htg_supply_air_temp, :supp_htg_max_supply_temp, :supp_htg_max_outdoor_temp)
  end

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Residential Air Source Heat Pump"
  end
  
  def description
    return "This measure removes any existing HVAC components from the building and adds an air source heat pump along with an on/off supply fan to a unitary air loop."
  end
  
  def modeler_description
    return "Any supply components or baseboard convective electrics/waters are removed from any existing air/plant loops or zones. Any existing air/plant loops are also removed. A heating DX coil, cooling DX coil, electric supplemental heating coil, and an on/off supply fan are added to a unitary air loop. The unitary air loop is added to the supply inlet node of the air loop. This air loop is added to a branch for the living zone. A diffuser is added to the branch for the living zone as well as for the finished basement if it exists."
  end   
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make a string argument for ashp installed seer
    ashpInstalledSEER = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("ashpInstalledSEER", true)
    ashpInstalledSEER.setDisplayName("Installed SEER")
	ashpInstalledSEER.setUnits("Btu/W-h")
	ashpInstalledSEER.setDescription("The installed Seasonal Energy Efficiency Ratio (SEER) of the heat pump, and the installed Heating Seasonal Performance Factor (HSPF) of the heat pump.")
    ashpInstalledSEER.setDefaultValue(13.0)
    args << ashpInstalledSEER
    
    #make a string argument for ashp installed hspf
    ashpInstalledHSPF = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("ashpInstalledHSPF", true)
    ashpInstalledHSPF.setDisplayName("Installed HSPF")
	ashpInstalledHSPF.setUnits("Btu/W-h")
	ashpInstalledHSPF.setDescription("The installed Seasonal Energy Efficiency Ratio (SEER) of the heat pump, and the installed Heating Seasonal Performance Factor (HSPF) of the heat pump.")
    ashpInstalledHSPF.setDefaultValue(7.7)
    args << ashpInstalledHSPF
    
    #make a double argument for ashp number of speeds
    ashpNumberSpeeds = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("ashpNumberSpeeds", true)
    ashpNumberSpeeds.setDisplayName("Number of Speeds")
    ashpNumberSpeeds.setUnits("frac")
    ashpNumberSpeeds.setDescription("Number of speeds of the compressor.")
    ashpNumberSpeeds.setDefaultValue(1.0)
    args << ashpNumberSpeeds

    #make a double argument for ashp eer
    ashpEER = OpenStudio::Ruleset::OSArgument::makeStringArgument("ashpEER", true)
    ashpEER.setDisplayName("EER")
    ashpEER.setUnits("kBtu/kWh")
    ashpEER.setDescription("EER (net) from the A test (95 ODB/80 EDB/67 EWB) for each of the compressor speeds.")
    ashpEER.setDefaultValue("11.4")
    args << ashpEER
    
    #make a double argument for ashp cop
    ashpCOP = OpenStudio::Ruleset::OSArgument::makeStringArgument("ashpCOP", true)
    ashpCOP.setDisplayName("COP")
    ashpCOP.setUnits("Wh/Wh")
    ashpCOP.setDescription("COP (net) at 47 ODB/70 EDB/60 EWB (AHRI rated conditions) for each of the compressor speeds.")
    ashpCOP.setDefaultValue("3.05")
    args << ashpCOP    
    
    #make a double argument for ashp rated shr
    ashpSHRRated = OpenStudio::Ruleset::OSArgument::makeStringArgument("ashpSHRRated", true)
    ashpSHRRated.setDisplayName("Rated SHR")
    ashpSHRRated.setDescription("The sensible heat ratio (ratio of the sensible portion of the load to the total load) at the nominal rated capacity for each of the compressor speeds.")
    ashpSHRRated.setDefaultValue("0.73")
    args << ashpSHRRated

    #make a double argument for ashp capacity ratio
    ashpCapacityRatio = OpenStudio::Ruleset::OSArgument::makeStringArgument("ashpCapacityRatio", true)
    ashpCapacityRatio.setDisplayName("Capacity Ratio")
    ashpCapacityRatio.setDescription("Capacity divided by rated capacity for each of the compressor speeds.")
    ashpCapacityRatio.setDefaultValue("1.0")
    args << ashpCapacityRatio

    #make a double argument for ashp rated air flow rate cooling
    ashpRatedAirFlowRateCooling = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("ashpRatedAirFlowRateCooling", true)
    ashpRatedAirFlowRateCooling.setDisplayName("Rated Air Flow Rate, Cooling")
    ashpRatedAirFlowRateCooling.setUnits("cfm/ton")
    ashpRatedAirFlowRateCooling.setDescription("Air flow rate (cfm) per ton of rated capacity, in cooling mode.")
    ashpRatedAirFlowRateCooling.setDefaultValue(394.2)
    args << ashpRatedAirFlowRateCooling    
    
    #make a double argument for ashp rated air flow rate heating
    ashpRatedAirFlowRateHeating = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("ashpRatedAirFlowRateHeating", true)
    ashpRatedAirFlowRateHeating.setDisplayName("Rated Air Flow Rate, Heating")
    ashpRatedAirFlowRateHeating.setUnits("cfm/ton")
    ashpRatedAirFlowRateHeating.setDescription("Air flow rate (cfm) per ton of rated capacity, in heating mode.")
    ashpRatedAirFlowRateHeating.setDefaultValue(384.1)
    args << ashpRatedAirFlowRateHeating

    #make a double argument for ashp fan speed ratio cooling
    ashpFanspeedRatioCooling = OpenStudio::Ruleset::OSArgument::makeStringArgument("ashpFanspeedRatioCooling", true)
    ashpFanspeedRatioCooling.setDisplayName("Fan Speed Ratio Cooling")
    ashpFanspeedRatioCooling.setDescription("Cooling fan speed divided by fan speed at the compressor speed for which Capacity Ratio = 1.0 for each of the compressor speeds.")
    ashpFanspeedRatioCooling.setDefaultValue("1.0")
    args << ashpFanspeedRatioCooling
    
    #make a double argument for ashp fan speed ratio heating
    ashpFanspeedRatioHeating = OpenStudio::Ruleset::OSArgument::makeStringArgument("ashpFanspeedRatioHeating", true)
    ashpFanspeedRatioHeating.setDisplayName("Fan Speed Ratio Heating")
    ashpFanspeedRatioHeating.setDescription("Heating fan speed divided by fan speed at the compressor speed for which Capacity Ratio = 1.0 for each of the compressor speeds.")
    ashpFanspeedRatioHeating.setDefaultValue("1.0")
    args << ashpFanspeedRatioHeating    

    #make a double argument for ashp rated supply fan power
    ashpSupplyFanPowerRated = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("ashpSupplyFanPowerRated", true)
    ashpSupplyFanPowerRated.setDisplayName("Rated Supply Fan Power")
    ashpSupplyFanPowerRated.setUnits("W/cfm")
    ashpSupplyFanPowerRated.setDescription("Fan power (in W) per delivered airflow rate (in cfm) of the outdoor fan under conditions prescribed by AHRI Standard 210/240 for SEER testing.")
    ashpSupplyFanPowerRated.setDefaultValue(0.365)
    args << ashpSupplyFanPowerRated
    
    #make a double argument for ashp installed supply fan power
    ashpSupplyFanPowerInstalled = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("ashpSupplyFanPowerInstalled", true)
    ashpSupplyFanPowerInstalled.setDisplayName("Installed Supply Fan Power")
    ashpSupplyFanPowerInstalled.setUnits("W/cfm")
    ashpSupplyFanPowerInstalled.setDescription("Fan power (in W) per delivered airflow rate (in cfm) of the outdoor fan for the maximum fan speed under actual operating conditions.")
    ashpSupplyFanPowerInstalled.setDefaultValue(0.5)
    args << ashpSupplyFanPowerInstalled    
    
    #make a double argument for ashp condenser type
    ashpCondenserType = OpenStudio::Ruleset::OSArgument::makeStringArgument("ashpCondenserType", true)
    ashpCondenserType.setDisplayName("Condenser Type")
    ashpCondenserType.setDescription("For evaporatively cooled units, the performance curves are a function of outdoor wetbulb (not drybulb) and entering wetbulb.")
    ashpCondenserType.setDefaultValue("aircooled")
    args << ashpCondenserType    
  
    #make a double argument for ashp min t
    ashpMinTemp = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("ashpMinTemp", true)
    ashpMinTemp.setDisplayName("Min Temp")
    ashpMinTemp.setUnits("degrees F")
    ashpMinTemp.setDescription("Outdoor dry-bulb temperature below which compressor turns off.")
    ashpMinTemp.setDefaultValue(0.0)
    args << ashpMinTemp  
  
    #make a double argument for central ac crankcase
    ashpCrankcase = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("ashpCrankcase", true)
    ashpCrankcase.setDisplayName("Crankcase")
    ashpCrankcase.setUnits("kW")
    ashpCrankcase.setDescription("Capacity of the crankcase heater for the compressor.")
    ashpCrankcase.setDefaultValue(0.02)
    args << ashpCrankcase

    #make a double argument for ashp crankcase max t
    ashpCrankcaseMaxT = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("ashpCrankcaseMaxT", true)
    ashpCrankcaseMaxT.setDisplayName("Crankcase Max Temp")
    ashpCrankcaseMaxT.setUnits("degrees F")
    ashpCrankcaseMaxT.setDescription("Outdoor dry-bulb temperature above which compressor crankcase heating is disabled.")
    ashpCrankcaseMaxT.setDefaultValue(55.0)
    args << ashpCrankcaseMaxT
    
    #make a double argument for ashp 1.5 ton eer capacity derate
    ashpEERCapacityDerateFactor1ton = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("ashpEERCapacityDerateFactor1ton", true)
    ashpEERCapacityDerateFactor1ton.setDisplayName("1.5 Ton EER Capacity Derate")
    ashpEERCapacityDerateFactor1ton.setDescription("EER multiplier for 1.5 ton air-conditioners.")
    ashpEERCapacityDerateFactor1ton.setDefaultValue(1.0)
    args << ashpEERCapacityDerateFactor1ton
    
    #make a double argument for central ac 2 ton eer capacity derate
    ashpEERCapacityDerateFactor2ton = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("ashpEERCapacityDerateFactor2ton", true)
    ashpEERCapacityDerateFactor2ton.setDisplayName("2 Ton EER Capacity Derate")
    ashpEERCapacityDerateFactor2ton.setDescription("EER multiplier for 2 ton air-conditioners.")
    ashpEERCapacityDerateFactor2ton.setDefaultValue(1.0)
    args << ashpEERCapacityDerateFactor2ton

    #make a double argument for central ac 3 ton eer capacity derate
    ashpEERCapacityDerateFactor3ton = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("ashpEERCapacityDerateFactor3ton", true)
    ashpEERCapacityDerateFactor3ton.setDisplayName("3 Ton EER Capacity Derate")
    ashpEERCapacityDerateFactor3ton.setDescription("EER multiplier for 3 ton air-conditioners.")
    ashpEERCapacityDerateFactor3ton.setDefaultValue(1.0)
    args << ashpEERCapacityDerateFactor3ton

    #make a double argument for central ac 4 ton eer capacity derate
    ashpEERCapacityDerateFactor4ton = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("ashpEERCapacityDerateFactor4ton", true)
    ashpEERCapacityDerateFactor4ton.setDisplayName("4 Ton EER Capacity Derate")
    ashpEERCapacityDerateFactor4ton.setDescription("EER multiplier for 4 ton air-conditioners.")
    ashpEERCapacityDerateFactor4ton.setDefaultValue(1.0)
    args << ashpEERCapacityDerateFactor4ton

    #make a double argument for central ac 5 ton eer capacity derate
    ashpEERCapacityDerateFactor5ton = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("ashpEERCapacityDerateFactor5ton", true)
    ashpEERCapacityDerateFactor5ton.setDisplayName("5 Ton EER Capacity Derate")
    ashpEERCapacityDerateFactor5ton.setDescription("EER multiplier for 5 ton air-conditioners.")
    ashpEERCapacityDerateFactor5ton.setDefaultValue(1.0)
    args << ashpEERCapacityDerateFactor5ton
    
    #make a double argument for ashp 1.5 ton cop capacity derate
    ashpCOPCapacityDerateFactor1ton = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("ashpCOPCapacityDerateFactor1ton", true)
    ashpCOPCapacityDerateFactor1ton.setDisplayName("1.5 Ton COP Capacity Derate")
    ashpCOPCapacityDerateFactor1ton.setDescription("COP multiplier for 1.5 ton air-conditioners.")
    ashpCOPCapacityDerateFactor1ton.setDefaultValue(1.0)
    args << ashpCOPCapacityDerateFactor1ton
    
    #make a double argument for ashp 2 ton cop capacity derate
    ashpCOPCapacityDerateFactor2ton = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("ashpCOPCapacityDerateFactor2ton", true)
    ashpCOPCapacityDerateFactor2ton.setDisplayName("2 Ton COP Capacity Derate")
    ashpCOPCapacityDerateFactor2ton.setDescription("COP multiplier for 2 ton air-conditioners.")
    ashpCOPCapacityDerateFactor2ton.setDefaultValue(1.0)
    args << ashpCOPCapacityDerateFactor2ton

    #make a double argument for ashp 3 ton cop capacity derate
    ashpCOPCapacityDerateFactor3ton = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("ashpCOPCapacityDerateFactor3ton", true)
    ashpCOPCapacityDerateFactor3ton.setDisplayName("3 Ton COP Capacity Derate")
    ashpCOPCapacityDerateFactor3ton.setDescription("COP multiplier for 3 ton air-conditioners.")
    ashpCOPCapacityDerateFactor3ton.setDefaultValue(1.0)
    args << ashpCOPCapacityDerateFactor3ton

    #make a double argument for ashp 4 ton cop capacity derate
    ashpCOPCapacityDerateFactor4ton = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("ashpCOPCapacityDerateFactor4ton", true)
    ashpCOPCapacityDerateFactor4ton.setDisplayName("4 Ton COP Capacity Derate")
    ashpCOPCapacityDerateFactor4ton.setDescription("COP multiplier for 4 ton air-conditioners.")
    ashpCOPCapacityDerateFactor4ton.setDefaultValue(1.0)
    args << ashpCOPCapacityDerateFactor4ton

    #make a double argument for ashp 5 ton cop capacity derate
    ashpCOPCapacityDerateFactor5ton = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("ashpCOPCapacityDerateFactor5ton", true)
    ashpCOPCapacityDerateFactor5ton.setDisplayName("5 Ton COP Capacity Derate")
    ashpCOPCapacityDerateFactor5ton.setDescription("COP multiplier for 5 ton air-conditioners.")
    ashpCOPCapacityDerateFactor5ton.setDefaultValue(1.0)
    args << ashpCOPCapacityDerateFactor5ton    
    
    #make a bool argument for whether the ashp is cold climate
    ashpIsColdClimate = OpenStudio::Ruleset::OSArgument::makeBoolArgument("ashpIsColdClimate", true)
    ashpIsColdClimate.setDisplayName("Is Cold Climate")
    ashpIsColdClimate.setDescription("Specifies whether the heat pump is a so called 'cold climate heat pump'.")
    ashpIsColdClimate.setDefaultValue(false)
    args << ashpIsColdClimate  
    
    #make a choice argument for ashp cooling/heating output capacity
    cap_display_names = OpenStudio::StringVector.new
    cap_display_names << Constants.SizingAuto
    (0.5..10.0).step(0.5) do |tons|
      cap_display_names << "#{tons} tons"
    end

    #make a string argument for ashp cooling/heating output capacity
    selected_hpcap = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedhpcap", cap_display_names, true)
    selected_hpcap.setDisplayName("Cooling/Heating Output Capacity")
    selected_hpcap.setDefaultValue(Constants.SizingAuto)
    args << selected_hpcap

    #make a choice argument for supplemental heating output capacity
    cap_display_names = OpenStudio::StringVector.new
    cap_display_names << Constants.SizingAuto
    (5..150).step(5) do |kbtu|
      cap_display_names << "#{kbtu} kBtu/hr"
    end

    #make a string argument for supplemental heating output capacity
    selected_supcap = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedsupcap", cap_display_names, true)
    selected_supcap.setDisplayName("Supplemental Heating Output Capacity")
    selected_supcap.setDefaultValue(Constants.SizingAuto)
    args << selected_supcap 
    
    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    hpCoolingInstalledSEER = runner.getDoubleArgumentValue("ashpInstalledSEER",user_arguments)
    hpHeatingInstalledHSPF = runner.getDoubleArgumentValue("ashpInstalledHSPF",user_arguments)
    hpNumberSpeeds = runner.getDoubleArgumentValue("ashpNumberSpeeds",user_arguments)
    hpCoolingEER = runner.getStringArgumentValue("ashpEER",user_arguments).split(",").map {|i| i.to_f}
    hpHeatingCOP = runner.getStringArgumentValue("ashpCOP",user_arguments).split(",").map {|i| i.to_f}
    hpSHRRated = runner.getStringArgumentValue("ashpSHRRated",user_arguments).split(",").map {|i| i.to_f}
    hpCapacityRatio = runner.getStringArgumentValue("ashpCapacityRatio",user_arguments).split(",").map {|i| i.to_f}
    hpRatedAirFlowRateCooling = runner.getDoubleArgumentValue("ashpRatedAirFlowRateCooling",user_arguments)
    hpRatedAirFlowRateHeating = runner.getDoubleArgumentValue("ashpRatedAirFlowRateHeating",user_arguments)
    hpFanspeedRatioCooling = runner.getStringArgumentValue("ashpFanspeedRatioCooling",user_arguments).split(",").map {|i| i.to_f}
    hpFanspeedRatioHeating = runner.getStringArgumentValue("ashpFanspeedRatioHeating",user_arguments).split(",").map {|i| i.to_f}
    hpSupplyFanPowerRated = runner.getDoubleArgumentValue("ashpSupplyFanPowerRated",user_arguments)
    hpSupplyFanPowerInstalled = runner.getDoubleArgumentValue("ashpSupplyFanPowerInstalled",user_arguments)
    hpCondenserType = runner.getStringArgumentValue("ashpCondenserType",user_arguments)
    hpMinT = runner.getDoubleArgumentValue("ashpMinTemp",user_arguments)
    hpCrankcase = runner.getDoubleArgumentValue("ashpCrankcase",user_arguments)
    hpCrankcaseMaxT = runner.getDoubleArgumentValue("ashpCrankcaseMaxT",user_arguments)
    hpEERCapacityDerateFactor1ton = runner.getDoubleArgumentValue("ashpEERCapacityDerateFactor1ton",user_arguments)
    hpEERCapacityDerateFactor2ton = runner.getDoubleArgumentValue("ashpEERCapacityDerateFactor2ton",user_arguments)
    hpEERCapacityDerateFactor3ton = runner.getDoubleArgumentValue("ashpEERCapacityDerateFactor3ton",user_arguments)
    hpEERCapacityDerateFactor4ton = runner.getDoubleArgumentValue("ashpEERCapacityDerateFactor4ton",user_arguments)
    hpEERCapacityDerateFactor5ton = runner.getDoubleArgumentValue("ashpEERCapacityDerateFactor5ton",user_arguments)
    hpEERCapacityDerateFactor = [hpEERCapacityDerateFactor1ton, hpEERCapacityDerateFactor2ton, hpEERCapacityDerateFactor3ton, hpEERCapacityDerateFactor4ton, hpEERCapacityDerateFactor5ton]
    hpCOPCapacityDerateFactor1ton = runner.getDoubleArgumentValue("ashpCOPCapacityDerateFactor1ton",user_arguments)
    hpCOPCapacityDerateFactor2ton = runner.getDoubleArgumentValue("ashpCOPCapacityDerateFactor2ton",user_arguments)
    hpCOPCapacityDerateFactor3ton = runner.getDoubleArgumentValue("ashpCOPCapacityDerateFactor3ton",user_arguments)
    hpCOPCapacityDerateFactor4ton = runner.getDoubleArgumentValue("ashpCOPCapacityDerateFactor4ton",user_arguments)
    hpCOPCapacityDerateFactor5ton = runner.getDoubleArgumentValue("ashpCOPCapacityDerateFactor5ton",user_arguments)
    hpCOPCapacityDerateFactor = [hpCOPCapacityDerateFactor1ton, hpCOPCapacityDerateFactor2ton, hpCOPCapacityDerateFactor3ton, hpCOPCapacityDerateFactor4ton, hpCOPCapacityDerateFactor5ton]
    hpIsColdClimate = runner.getBoolArgumentValue("ashpIsColdClimate",user_arguments)    
    hpOutputCapacity = runner.getStringArgumentValue("selectedhpcap",user_arguments)
    unless hpOutputCapacity == Constants.SizingAuto
      hpOutputCapacity = OpenStudio::convert(hpOutputCapacity.split(" ")[0].to_f,"ton","Btu/h").get
    end
    supplementalOutputCapacity = runner.getStringArgumentValue("selectedsupcap",user_arguments)
    unless supplementalOutputCapacity == Constants.SizingAuto
      supplementalOutputCapacity = OpenStudio::convert(supplementalOutputCapacity.split(" ")[0].to_f,"kBtu/h","Btu/h").get
    end   

    # error checking
    unless [1, 2, 4].include? hpNumberSpeeds
      runner.registerError("Invalid number of compressor speeds entered.")
      return false
    end
    unless ( hpNumberSpeeds == hpCoolingEER.length and hpNumberSpeeds == hpHeatingCOP.length and hpNumberSpeeds == hpSHRRated.length and hpNumberSpeeds == hpCapacityRatio.length and hpNumberSpeeds == hpFanspeedRatioCooling.length and hpNumberSpeeds == hpFanspeedRatioHeating.length )
      runner.registerError("Entered wrong length for EER, COP, Rated SHR, Capacity Ratio, or Fan Speed Ratio given the Number of Speeds.")
      return false
    end
    
    # Create the material class instances
    air_conditioner = AirConditioner.new(nil)
    heat_pump = HeatPump.new(hpNumberSpeeds, hpCoolingEER, hpCoolingInstalledSEER, hpSupplyFanPowerInstalled, hpSupplyFanPowerRated, hpSHRRated, hpCapacityRatio, hpFanspeedRatioCooling, hpCondenserType, hpCrankcase, hpCrankcaseMaxT, hpEERCapacityDerateFactor, hpHeatingCOP, hpHeatingInstalledHSPF, hpFanspeedRatioHeating, hpMinT, hpCOPCapacityDerateFactor, hpRatedAirFlowRateCooling, hpRatedAirFlowRateHeating)
    supply = Supply.new

    # _processAirSystem
    
    if air_conditioner.ACCoolingInstalledSEER == 999
      air_conditioner.hasIdealAC = true
    else
      air_conditioner.hasIdealAC = false
    end

    supply.static = UnitConversion.inH2O2Pa(0.5) # Pascal

    # Flow rate through AC units - hardcoded assumption of 400 cfm/ton
    supply.cfm_ton = 400 # cfm / ton

    supply.HPCoolingOversizingFactor = 1 # Default to a value of 1 (currently only used for MSHPs)
    supply.SpaceConditionedMult = 1 # Default used for central equipment    
    
    # Cooling Coil
    supply = HVAC.get_cooling_coefficients(runner, heat_pump.HPNumberSpeeds, false, true, supply)
    supply.CFM_TON_Rated = HVAC.calc_cfm_ton_rated(heat_pump.HPRatedAirFlowRateCooling, heat_pump.HPFanspeedRatioCooling, heat_pump.HPCapacityRatio)
    supply = HVAC._processAirSystemCoolingCoil(runner, heat_pump.HPNumberSpeeds, heat_pump.HPCoolingEER, heat_pump.HPCoolingInstalledSEER, heat_pump.HPSupplyFanPowerInstalled, heat_pump.HPSupplyFanPowerRated, heat_pump.HPSHRRated, heat_pump.HPCapacityRatio, heat_pump.HPFanspeedRatioCooling, heat_pump.HPCondenserType, heat_pump.HPCrankcase, heat_pump.HPCrankcaseMaxT, heat_pump.HPEERCapacityDerateFactor, air_conditioner, supply, true)

    # Heating Coil
    has_cchp = hpIsColdClimate
    supply = HVAC.get_heating_coefficients(runner, supply.Number_Speeds, false, supply, heat_pump.HPMinT)
    supply.CFM_TON_Rated_Heat = HVAC.calc_cfm_ton_rated(heat_pump.HPRatedAirFlowRateHeating, heat_pump.HPFanspeedRatioHeating, heat_pump.HPCapacityRatio)
    supply = HVAC._processAirSystemHeatingCoil(heat_pump.HPHeatingCOP, heat_pump.HPHeatingInstalledHSPF, heat_pump.HPSupplyFanPowerRated, heat_pump.HPCapacityRatio, heat_pump.HPFanspeedRatioHeating, heat_pump.HPMinT, heat_pump.HPCOPCapacityDerateFactor, supply)    

    # Determine if the compressor is multi-speed (in our case 2 speed).
    # If the minimum flow ratio is less than 1, then the fan and
    # compressors can operate at lower speeds.
    if supply.min_flow_ratio == 1.0
      supply.compressor_speeds = 1.0
    else
      supply.compressor_speeds = supply.Number_Speeds
    end
    
    htg_coil_stage_data = HVAC._processCurvesDXHeating(model, supply, hpOutputCapacity)
    
    # Heating defrost curve for reverse cycle
    defrost_eir = OpenStudio::Model::CurveBiquadratic.new(model)
    defrost_eir.setName("DefrostEIR")
    defrost_eir.setCoefficient1Constant(0.1528)
    defrost_eir.setCoefficient2x(0)
    defrost_eir.setCoefficient3xPOW2(0)
    defrost_eir.setCoefficient4y(0)
    defrost_eir.setCoefficient5yPOW2(0)
    defrost_eir.setCoefficient6xTIMESY(0)
    defrost_eir.setMinimumValueofx(-100)
    defrost_eir.setMaximumValueofx(100)
    defrost_eir.setMinimumValueofy(-100)
    defrost_eir.setMaximumValueofy(100)    
    
    # _processCurvesDXCooling

    clg_coil_stage_data = HVAC._processCurvesDXCooling(model, supply, hpOutputCapacity)

    # Check if has equipment
    HelperMethods.remove_hot_water_loop(model, runner)    
    
    control_slave_zones_hash = Geometry.get_control_and_slave_zones(model)
    control_slave_zones_hash.each do |control_zone, slave_zones|
    
      # Remove existing equipment
      HelperMethods.remove_existing_hvac_equipment(model, runner, "Air Source Heat Pump", control_zone)    
    
      # _processSystemHeatingCoil
      
      if supply.compressor_speeds == 1.0

        htg_coil = OpenStudio::Model::CoilHeatingDXSingleSpeed.new(model, model.alwaysOnDiscreteSchedule, htg_coil_stage_data[0].heatingCapacityFunctionofTemperatureCurve, htg_coil_stage_data[0].heatingCapacityFunctionofFlowFractionCurve, htg_coil_stage_data[0].energyInputRatioFunctionofTemperatureCurve, htg_coil_stage_data[0].energyInputRatioFunctionofFlowFractionCurve, htg_coil_stage_data[0].partLoadFractionCorrelationCurve)
        htg_coil.setName("DX Heating Coil")
        if hpOutputCapacity != Constants.SizingAuto
          htg_coil.setRatedTotalHeatingCapacity(OpenStudio::convert(hpOutputCapacity,"Btu/h","W").get)
        end
        htg_coil.setRatedCOP(1.0 / supply.HeatingEIR[0])
        # self.addline(units.cfm2m3_s(sim.supply.Heat_AirFlowRate),'Rated Air Flow Rate {m^3/s}')
        htg_coil.setRatedSupplyFanPowerPerVolumeFlowRate(supply.fan_power_rated / OpenStudio::convert(1.0,"cfm","m^3/s").get)
        htg_coil.setDefrostEnergyInputRatioFunctionofTemperatureCurve(defrost_eir)
        htg_coil.setMinimumOutdoorDryBulbTemperatureforCompressorOperation(OpenStudio::convert(supply.min_hp_temp,"F","C").get)
        htg_coil.setMaximumOutdoorDryBulbTemperatureforDefrostOperation(OpenStudio::convert(supply.max_defrost_temp,"F","C").get)
        htg_coil.setCrankcaseHeaterCapacity(OpenStudio::convert(supply.Crankcase,"kW","W").get)
        htg_coil.setMaximumOutdoorDryBulbTemperatureforCrankcaseHeaterOperation(OpenStudio::convert(supply.Crankcase_MaxT,"F","C").get)
        htg_coil.setDefrostStrategy("ReverseCycle")
        htg_coil.setDefrostControl("OnDemand")

      else # Multi-speed compressors

        htg_coil = OpenStudio::Model::CoilHeatingDXMultiSpeed.new(model)
        htg_coil.setName("DX Heating Coil")
        htg_coil.setMinimumOutdoorDryBulbTemperatureforCompressorOperation(OpenStudio::convert(supply.min_hp_temp,"F","C").get)
        htg_coil.setCrankcaseHeaterCapacity(OpenStudio::convert(supply.Crankcase,"kW","W").get)
        htg_coil.setMaximumOutdoorDryBulbTemperatureforCrankcaseHeaterOperation(OpenStudio::convert(supply.Crankcase_MaxT,"F","C").get)
        htg_coil.setDefrostEnergyInputRatioFunctionofTemperatureCurve(defrost_eir)
        htg_coil.setMaximumOutdoorDryBulbTemperatureforDefrostOperation(OpenStudio::convert(supply.max_defrost_temp,"F","C").get)
        htg_coil.setDefrostStrategy("ReverseCryle")
        htg_coil.setDefrostControl("OnDemand")
        htg_coil.setApplyPartLoadFractiontoSpeedsGreaterthan1(false)
        htg_coil.setFuelType("Electricity")
        
        htg_coil_stage_data.each do |i|
            htg_coil.addStage(i)
        end

      end
      
      supp_htg_coil = OpenStudio::Model::CoilHeatingElectric.new(model, model.alwaysOnDiscreteSchedule)
      supp_htg_coil.setName("HeatPump Supp Heater")
      supp_htg_coil.setEfficiency(1)
      if supplementalOutputCapacity != Constants.SizingAuto
        supp_htg_coil.setNominalCapacity(OpenStudio::convert(supplementalOutputCapacity,"Btu/h","W").get)
      end
      
      # _processSystemCoolingCoil
      
      if supply.compressor_speeds == 1.0

        clg_coil = OpenStudio::Model::CoilCoolingDXSingleSpeed.new(model, model.alwaysOnDiscreteSchedule, clg_coil_stage_data[0].totalCoolingCapacityFunctionofTemperatureCurve, clg_coil_stage_data[0].totalCoolingCapacityFunctionofFlowFractionCurve, clg_coil_stage_data[0].energyInputRatioFunctionofTemperatureCurve, clg_coil_stage_data[0].energyInputRatioFunctionofFlowFractionCurve, clg_coil_stage_data[0].partLoadFractionCorrelationCurve)
        clg_coil.setName("DX Cooling Coil")
        if hpOutputCapacity != Constants.SizingAuto
          clg_coil.setRatedTotalCoolingCapacity(OpenStudio::convert(hpOutputCapacity,"Btu/h","W").get)
        end
        if air_conditioner.hasIdealAC
          if hpOutputCapacity != Constants.SizingAuto
            clg_coil.setRatedSensibleHeatRatio(0.8)
            clg_coil.setRatedAirFlowRate(supply.CFM_TON_Rated[0] * hpOutputCapacity * OpenStudio::convert(1.0,"Btu/h","ton").get * OpenStudio::convert(1.0,"cfm","m^3/s").get)
          end
          clg_coil.setRatedCOP(OpenStudio::OptionalDouble.new(1.0))
        else
          if hpOutputCapacity != Constants.SizingAuto
            clg_coil.setRatedSensibleHeatRatio(supply.SHR_Rated[0])
            clg_coil.setRatedAirFlowRate(supply.CFM_TON_Rated[0] * hpOutputCapacity * OpenStudio::convert(1.0,"Btu/h","ton").get * OpenStudio::convert(1.0,"cfm","m^3/s").get)
          end
          clg_coil.setRatedCOP(OpenStudio::OptionalDouble.new(1.0 / supply.CoolingEIR[0]))
        end
        clg_coil.setRatedEvaporatorFanPowerPerVolumeFlowRate(OpenStudio::OptionalDouble.new(supply.fan_power_rated / OpenStudio::convert(1.0,"cfm","m^3/s").get))

        if air_conditioner.hasIdealAC
          clg_coil.setNominalTimeForCondensateRemovalToBegin(OpenStudio::OptionalDouble.new(0))
          clg_coil.setRatioOfInitialMoistureEvaporationRateAndSteadyStateLatentCapacity(OpenStudio::OptionalDouble.new(0))
          clg_coil.setMaximumCyclingRate(OpenStudio::OptionalDouble.new(0))
          clg_coil.setLatentCapacityTimeConstant(OpenStudio::OptionalDouble.new(0))
        else
          clg_coil.setNominalTimeForCondensateRemovalToBegin(OpenStudio::OptionalDouble.new(1000.0))
          clg_coil.setRatioOfInitialMoistureEvaporationRateAndSteadyStateLatentCapacity(OpenStudio::OptionalDouble.new(1.5))
          clg_coil.setMaximumCyclingRate(OpenStudio::OptionalDouble.new(3.0))
          clg_coil.setLatentCapacityTimeConstant(OpenStudio::OptionalDouble.new(45.0))
        end

        if supply.CondenserType == Constants.CondenserTypeAir
          clg_coil.setCondenserType("AirCooled")
        else
          clg_coil.setCondenserType("EvaporativelyCooled")
          clg_coil.setEvaporativeCondenserEffectiveness(OpenStudio::OptionalDouble.new(1))
          clg_coil.setEvaporativeCondenserAirFlowRate(OpenStudio::OptionalDouble.new(OpenStudio::convert(850.0,"cfm","m^3/s").get * hpOutputCapacity))
          clg_coil.setEvaporativeCondenserPumpRatedPowerConsumption(OpenStudio::OptionalDouble.new(0))
        end

      else

        clg_coil = OpenStudio::Model::CoilCoolingDXMultiSpeed.new(model)
        clg_coil.setName("DX Cooling Coil")
        clg_coil.setCondenserType(supply.CondenserType)
        clg_coil.setApplyPartLoadFractiontoSpeedsGreaterthan1(false)
        clg_coil.setApplyLatentDegradationtoSpeedsGreaterthan1(false)        
        clg_coil.setFuelType("Electricity")
             
        clg_coil_stage_data.each do |i|
            clg_coil.addStage(i)
        end  

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

      if supply.compressor_speeds == 1

        air_loop_unitary = OpenStudio::Model::AirLoopHVACUnitarySystem.new(model)
        air_loop_unitary.setName("Forced Air System")
        air_loop_unitary.setAvailabilitySchedule(model.alwaysOnDiscreteSchedule)
        air_loop_unitary.setSupplyFan(fan)
        air_loop_unitary.setHeatingCoil(htg_coil)
        air_loop_unitary.setCoolingCoil(clg_coil)
        air_loop_unitary.setSupplementalHeatingCoil(supp_htg_coil)
        air_loop_unitary.setSupplyAirFlowRateWhenNoCoolingorHeatingisRequired(0)
        air_loop_unitary.setMaximumSupplyAirTemperature(OpenStudio::convert(supply.supp_htg_max_supply_temp,"F","C").get)
        air_loop_unitary.setMaximumOutdoorDryBulbTemperatureforSupplementalHeaterOperation(OpenStudio::convert(supply.supp_htg_max_outdoor_temp,"F","C").get)      
        air_loop_unitary.setFanPlacement("BlowThrough")
        air_loop_unitary.setSupplyAirFanOperatingModeSchedule(supply_fan_operation)
        
      elsif supply.compressor_speeds > 1
      
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
        air_loop_unitary.setNumberofSpeedsforHeating(supply.Number_Speeds.to_i)
        air_loop_unitary.setNumberofSpeedsforCooling(supply.Number_Speeds.to_i)      
        
      end

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
 
  end #end the run method
  
end #end the measure

#this allows the measure to be use by the application
ProcessAirSourceHeatPump.new.registerWithApplication