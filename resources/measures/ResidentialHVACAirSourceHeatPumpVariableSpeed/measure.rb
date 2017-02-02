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
require "#{File.dirname(__FILE__)}/resources/hvac"

#start the measure
class ProcessVariableSpeedAirSourceHeatPump < OpenStudio::Ruleset::ModelUserScript

  class Supply
    def initialize
    end
    attr_accessor(:static, :cfm_ton, :HPCoolingOversizingFactor, :SpaceConditionedMult, :fan_power, :eff, :min_flow_ratio, :FAN_EIR_FPLR_SPEC_coefficients, :max_temp, :Heat_Capacity, :Zone_Water_Remove_Cap_Ft_DB_RH_Coefficients, :Zone_Energy_Factor_Ft_DB_RH_Coefficients, :Zone_DXDH_PLF_F_PLR_Coefficients, :Number_Speeds, :fanspeed_ratio, :CFM_TON_Rated, :COOL_CAP_FT_SPEC_coefficients, :COOL_EIR_FT_SPEC_coefficients, :COOL_CAP_FFLOW_SPEC_coefficients, :COOL_EIR_FFLOW_SPEC_coefficients, :CoolingEIR, :SHR_Rated, :COOL_CLOSS_FPLR_SPEC_coefficients, :Capacity_Ratio_Cooling, :CondenserType, :Crankcase, :Crankcase_MaxT, :EER_CapacityDerateFactor, :HEAT_CAP_FT_SPEC_coefficients, :HEAT_EIR_FT_SPEC_coefficients, :HEAT_CAP_FFLOW_SPEC_coefficients, :HEAT_EIR_FFLOW_SPEC_coefficients, :CFM_TON_Rated_Heat, :HeatingEIR, :HEAT_CLOSS_FPLR_SPEC_coefficients, :Capacity_Ratio_Heating, :fanspeed_ratio_heating, :min_hp_temp, :max_defrost_temp, :COP_CapacityDerateFactor, :fan_power_rated, :htg_supply_air_temp, :supp_htg_max_supply_temp, :supp_htg_max_outdoor_temp)
  end

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Residential Variable-Speed Air Source Heat Pump"
  end
  
  def description
    return "This measure removes any existing HVAC components from the building and adds a variable-speed air source heat pump along with an on/off supply fan to a unitary air loop. For multifamily buildings, the variable-speed air source heat pump can be set for all units of the building."
  end
  
  def modeler_description
    return "Any supply components or baseboard convective electrics/waters are removed from any existing air/plant loops or zones. Any existing air/plant loops are also removed. A heating DX coil, cooling DX coil, electric supplemental heating coil, and an on/off supply fan are added to a unitary air loop. The unitary air loop is added to the supply inlet node of the air loop. This air loop is added to a branch for the living zone. A diffuser is added to the branch for the living zone as well as for the finished basement if it exists."
  end   
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make a string argument for ashp installed seer
    ashpInstalledSEER = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("seer", true)
    ashpInstalledSEER.setDisplayName("Installed SEER")
    ashpInstalledSEER.setUnits("Btu/W-h")
    ashpInstalledSEER.setDescription("The installed Seasonal Energy Efficiency Ratio (SEER) of the heat pump.")
    ashpInstalledSEER.setDefaultValue(22.0)
    args << ashpInstalledSEER
    
    #make a string argument for ashp installed hspf
    ashpInstalledHSPF = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("hspf", true)
    ashpInstalledHSPF.setDisplayName("Installed HSPF")
    ashpInstalledHSPF.setUnits("Btu/W-h")
    ashpInstalledHSPF.setDescription("The installed Heating Seasonal Performance Factor (HSPF) of the heat pump.")
    ashpInstalledHSPF.setDefaultValue(10.0)
    args << ashpInstalledHSPF

    #make a double argument for ashp eer
    ashpEER = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("eer", true)
    ashpEER.setDisplayName("EER")
    ashpEER.setUnits("kBtu/kWh")
    ashpEER.setDescription("EER (net) from the A test (95 ODB/80 EDB/67 EWB).")
    ashpEER.setDefaultValue(17.4)
    args << ashpEER
    
    #make a double argument for ashp eer 2
    ashpEER = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("eer2", true)
    ashpEER.setDisplayName("EER 2")
    ashpEER.setUnits("kBtu/kWh")
    ashpEER.setDescription("EER (net) from the A test (95 ODB/80 EDB/67 EWB) for the second speed.")
    ashpEER.setDefaultValue(16.8)
    args << ashpEER    
    
    #make a double argument for ashp eer 3
    ashpEER = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("eer3", true)
    ashpEER.setDisplayName("EER 3")
    ashpEER.setUnits("kBtu/kWh")
    ashpEER.setDescription("EER (net) from the A test (95 ODB/80 EDB/67 EWB) for the third speed.")
    ashpEER.setDefaultValue(14.3)
    args << ashpEER
    
    #make a double argument for ashp eer 4
    ashpEER = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("eer4", true)
    ashpEER.setDisplayName("EER 4")
    ashpEER.setUnits("kBtu/kWh")
    ashpEER.setDescription("EER (net) from the A test (95 ODB/80 EDB/67 EWB) for the fourth speed.")
    ashpEER.setDefaultValue(13.0)
    args << ashpEER    
    
    #make a double argument for ashp cop
    ashpCOP = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("cop", true)
    ashpCOP.setDisplayName("COP")
    ashpCOP.setUnits("Wh/Wh")
    ashpCOP.setDescription("COP (net) at 47 ODB/70 EDB/60 EWB (AHRI rated conditions).")
    ashpCOP.setDefaultValue(4.82)
    args << ashpCOP
    
    #make a double argument for ashp cop 2
    ashpCOP = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("cop2", true)
    ashpCOP.setDisplayName("COP 2")
    ashpCOP.setUnits("Wh/Wh")
    ashpCOP.setDescription("COP (net) at 47 ODB/70 EDB/60 EWB (AHRI rated conditions) for the second speed.")
    ashpCOP.setDefaultValue(4.56)
    args << ashpCOP
    
    #make a double argument for ashp cop 3
    ashpCOP = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("cop3", true)
    ashpCOP.setDisplayName("COP 3")
    ashpCOP.setUnits("Wh/Wh")
    ashpCOP.setDescription("COP (net) at 47 ODB/70 EDB/60 EWB (AHRI rated conditions) for the third speed.")
    ashpCOP.setDefaultValue(3.89)
    args << ashpCOP
    
    #make a double argument for ashp cop 4
    ashpCOP = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("cop4", true)
    ashpCOP.setDisplayName("COP 4")
    ashpCOP.setUnits("Wh/Wh")
    ashpCOP.setDescription("COP (net) at 47 ODB/70 EDB/60 EWB (AHRI rated conditions) for the fourth speed.")
    ashpCOP.setDefaultValue(3.92)
    args << ashpCOP
    
    #make a double argument for ashp rated shr
    ashpSHRRated = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("shr", true)
    ashpSHRRated.setDisplayName("Rated SHR")
    ashpSHRRated.setDescription("The sensible heat ratio (ratio of the sensible portion of the load to the total load) at the nominal rated capacity.")
    ashpSHRRated.setDefaultValue(0.84)
    args << ashpSHRRated
    
    #make a double argument for ashp rated shr 2
    ashpSHRRated = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("shr2", true)
    ashpSHRRated.setDisplayName("Rated SHR 2")
    ashpSHRRated.setDescription("The sensible heat ratio (ratio of the sensible portion of the load to the total load) at the nominal rated capacity for the second speed.")
    ashpSHRRated.setDefaultValue(0.79)
    args << ashpSHRRated
    
    #make a double argument for ashp rated shr 3
    ashpSHRRated = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("shr3", true)
    ashpSHRRated.setDisplayName("Rated SHR 3")
    ashpSHRRated.setDescription("The sensible heat ratio (ratio of the sensible portion of the load to the total load) at the nominal rated capacity for the third speed.")
    ashpSHRRated.setDefaultValue(0.76)
    args << ashpSHRRated

    #make a double argument for ashp rated shr 4
    ashpSHRRated = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("shr4", true)
    ashpSHRRated.setDisplayName("Rated SHR 4")
    ashpSHRRated.setDescription("The sensible heat ratio (ratio of the sensible portion of the load to the total load) at the nominal rated capacity for the fourth speed.")
    ashpSHRRated.setDefaultValue(0.77)
    args << ashpSHRRated    

    #make a double argument for ashp capacity ratio
    ashpCapacityRatio = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("capacity_ratio", true)
    ashpCapacityRatio.setDisplayName("Capacity Ratio")
    ashpCapacityRatio.setDescription("Capacity divided by rated capacity.")
    ashpCapacityRatio.setDefaultValue(0.49)
    args << ashpCapacityRatio

    #make a double argument for ashp capacity ratio 2
    ashpCapacityRatio = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("capacity_ratio2", true)
    ashpCapacityRatio.setDisplayName("Capacity Ratio 2")
    ashpCapacityRatio.setDescription("Capacity divided by rated capacity for the second speed.")
    ashpCapacityRatio.setDefaultValue(0.67)
    args << ashpCapacityRatio    
    
    #make a double argument for ashp capacity ratio 3
    ashpCapacityRatio = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("capacity_ratio3", true)
    ashpCapacityRatio.setDisplayName("Capacity Ratio 3")
    ashpCapacityRatio.setDescription("Capacity divided by rated capacity for the third speed.")
    ashpCapacityRatio.setDefaultValue(1.0)
    args << ashpCapacityRatio

    #make a double argument for ashp capacity ratio 4
    ashpCapacityRatio = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("capacity_ratio4", true)
    ashpCapacityRatio.setDisplayName("Capacity Ratio 4")
    ashpCapacityRatio.setDescription("Capacity divided by rated capacity for the fourth speed.")
    ashpCapacityRatio.setDefaultValue(1.2)
    args << ashpCapacityRatio    
    
    #make a double argument for ashp rated air flow rate cooling
    ashpRatedAirFlowRateCooling = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("airflow_rate_cooling", true)
    ashpRatedAirFlowRateCooling.setDisplayName("Rated Air Flow Rate, Cooling")
    ashpRatedAirFlowRateCooling.setUnits("cfm/ton")
    ashpRatedAirFlowRateCooling.setDescription("Air flow rate (cfm) per ton of rated capacity, in cooling mode.")
    ashpRatedAirFlowRateCooling.setDefaultValue(315.8)
    args << ashpRatedAirFlowRateCooling    
    
    #make a double argument for ashp rated air flow rate heating
    ashpRatedAirFlowRateHeating = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("airflow_rate_heating", true)
    ashpRatedAirFlowRateHeating.setDisplayName("Rated Air Flow Rate, Heating")
    ashpRatedAirFlowRateHeating.setUnits("cfm/ton")
    ashpRatedAirFlowRateHeating.setDescription("Air flow rate (cfm) per ton of rated capacity, in heating mode.")
    ashpRatedAirFlowRateHeating.setDefaultValue(296.9)
    args << ashpRatedAirFlowRateHeating

    #make a double argument for ashp fan speed ratio cooling
    ashpFanspeedRatioCooling = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("fan_speed_ratio_cooling", true)
    ashpFanspeedRatioCooling.setDisplayName("Fan Speed Ratio Cooling")
    ashpFanspeedRatioCooling.setDescription("Cooling fan speed divided by fan speed at the compressor speed for which Capacity Ratio = 1.0.")
    ashpFanspeedRatioCooling.setDefaultValue(0.7)
    args << ashpFanspeedRatioCooling
    
    #make a double argument for ashp fan speed ratio cooling 2
    ashpFanspeedRatioCooling = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("fan_speed_ratio_cooling2", true)
    ashpFanspeedRatioCooling.setDisplayName("Fan Speed Ratio Cooling 2")
    ashpFanspeedRatioCooling.setDescription("Cooling fan speed divided by fan speed at the compressor speed for which Capacity Ratio = 1.0 for the second speed.")
    ashpFanspeedRatioCooling.setDefaultValue(0.9)
    args << ashpFanspeedRatioCooling
    
    #make a double argument for ashp fan speed ratio cooling 3
    ashpFanspeedRatioCooling = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("fan_speed_ratio_cooling3", true)
    ashpFanspeedRatioCooling.setDisplayName("Fan Speed Ratio Cooling 3")
    ashpFanspeedRatioCooling.setDescription("Cooling fan speed divided by fan speed at the compressor speed for which Capacity Ratio = 1.0 for the third speed.")
    ashpFanspeedRatioCooling.setDefaultValue(1.0)
    args << ashpFanspeedRatioCooling
    
    #make a double argument for ashp fan speed ratio cooling 4
    ashpFanspeedRatioCooling = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("fan_speed_ratio_cooling4", true)
    ashpFanspeedRatioCooling.setDisplayName("Fan Speed Ratio Cooling 4")
    ashpFanspeedRatioCooling.setDescription("Cooling fan speed divided by fan speed at the compressor speed for which Capacity Ratio = 1.0 for the fourth speed.")
    ashpFanspeedRatioCooling.setDefaultValue(1.26)
    args << ashpFanspeedRatioCooling
    
    #make a double argument for ashp fan speed ratio heating
    ashpFanspeedRatioHeating = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("fan_speed_ratio_heating", true)
    ashpFanspeedRatioHeating.setDisplayName("Fan Speed Ratio Heating")
    ashpFanspeedRatioHeating.setDescription("Heating fan speed divided by fan speed at the compressor speed for which Capacity Ratio = 1.0.")
    ashpFanspeedRatioHeating.setDefaultValue(0.74)
    args << ashpFanspeedRatioHeating
    
    #make a double argument for ashp fan speed ratio heating 2
    ashpFanspeedRatioHeating = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("fan_speed_ratio_heating2", true)
    ashpFanspeedRatioHeating.setDisplayName("Fan Speed Ratio Heating 2")
    ashpFanspeedRatioHeating.setDescription("Heating fan speed divided by fan speed at the compressor speed for which Capacity Ratio = 1.0 for the second speed.")
    ashpFanspeedRatioHeating.setDefaultValue(0.92)
    args << ashpFanspeedRatioHeating

    #make a double argument for ashp fan speed ratio heating 3
    ashpFanspeedRatioHeating = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("fan_speed_ratio_heating3", true)
    ashpFanspeedRatioHeating.setDisplayName("Fan Speed Ratio Heating 3")
    ashpFanspeedRatioHeating.setDescription("Heating fan speed divided by fan speed at the compressor speed for which Capacity Ratio = 1.0 for the third speed.")
    ashpFanspeedRatioHeating.setDefaultValue(1.0)
    args << ashpFanspeedRatioHeating
    
    #make a double argument for ashp fan speed ratio heating 4
    ashpFanspeedRatioHeating = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("fan_speed_ratio_heating4", true)
    ashpFanspeedRatioHeating.setDisplayName("Fan Speed Ratio Heating 4")
    ashpFanspeedRatioHeating.setDescription("Heating fan speed divided by fan speed at the compressor speed for which Capacity Ratio = 1.0 for the fourth speed.")
    ashpFanspeedRatioHeating.setDefaultValue(1.22)
    args << ashpFanspeedRatioHeating
    
    #make a double argument for ashp rated supply fan power
    ashpSupplyFanPowerRated = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("fan_power_rated", true)
    ashpSupplyFanPowerRated.setDisplayName("Rated Supply Fan Power")
    ashpSupplyFanPowerRated.setUnits("W/cfm")
    ashpSupplyFanPowerRated.setDescription("Fan power (in W) per delivered airflow rate (in cfm) of the outdoor fan under conditions prescribed by AHRI Standard 210/240 for SEER testing.")
    ashpSupplyFanPowerRated.setDefaultValue(0.14)
    args << ashpSupplyFanPowerRated
    
    #make a double argument for ashp installed supply fan power
    ashpSupplyFanPowerInstalled = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("fan_power_installed", true)
    ashpSupplyFanPowerInstalled.setDisplayName("Installed Supply Fan Power")
    ashpSupplyFanPowerInstalled.setUnits("W/cfm")
    ashpSupplyFanPowerInstalled.setDescription("Fan power (in W) per delivered airflow rate (in cfm) of the outdoor fan for the maximum fan speed under actual operating conditions.")
    ashpSupplyFanPowerInstalled.setDefaultValue(0.3)
    args << ashpSupplyFanPowerInstalled    
    
    #make a double argument for ashp min t
    ashpMinTemp = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("min_temp", true)
    ashpMinTemp.setDisplayName("Min Temp")
    ashpMinTemp.setUnits("degrees F")
    ashpMinTemp.setDescription("Outdoor dry-bulb temperature below which compressor turns off.")
    ashpMinTemp.setDefaultValue(0.0)
    args << ashpMinTemp  
  
    #make a double argument for central ac crankcase
    ashpCrankcase = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("crankcase_capacity", true)
    ashpCrankcase.setDisplayName("Crankcase")
    ashpCrankcase.setUnits("kW")
    ashpCrankcase.setDescription("Capacity of the crankcase heater for the compressor.")
    ashpCrankcase.setDefaultValue(0.02)
    args << ashpCrankcase

    #make a double argument for ashp crankcase max t
    ashpCrankcaseMaxT = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("crankcase_max_temp", true)
    ashpCrankcaseMaxT.setDisplayName("Crankcase Max Temp")
    ashpCrankcaseMaxT.setUnits("degrees F")
    ashpCrankcaseMaxT.setDescription("Outdoor dry-bulb temperature above which compressor crankcase heating is disabled.")
    ashpCrankcaseMaxT.setDefaultValue(55.0)
    args << ashpCrankcaseMaxT
    
    #make a double argument for ashp 1.5 ton eer capacity derate
    ashpEERCapacityDerateFactor1ton = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("eer_capacity_derate_1ton", true)
    ashpEERCapacityDerateFactor1ton.setDisplayName("1.5 Ton EER Capacity Derate")
    ashpEERCapacityDerateFactor1ton.setDescription("EER multiplier for 1.5 ton air-conditioners.")
    ashpEERCapacityDerateFactor1ton.setDefaultValue(1.0)
    args << ashpEERCapacityDerateFactor1ton
    
    #make a double argument for central ac 2 ton eer capacity derate
    ashpEERCapacityDerateFactor2ton = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("eer_capacity_derate_2ton", true)
    ashpEERCapacityDerateFactor2ton.setDisplayName("2 Ton EER Capacity Derate")
    ashpEERCapacityDerateFactor2ton.setDescription("EER multiplier for 2 ton air-conditioners.")
    ashpEERCapacityDerateFactor2ton.setDefaultValue(1.0)
    args << ashpEERCapacityDerateFactor2ton

    #make a double argument for central ac 3 ton eer capacity derate
    ashpEERCapacityDerateFactor3ton = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("eer_capacity_derate_3ton", true)
    ashpEERCapacityDerateFactor3ton.setDisplayName("3 Ton EER Capacity Derate")
    ashpEERCapacityDerateFactor3ton.setDescription("EER multiplier for 3 ton air-conditioners.")
    ashpEERCapacityDerateFactor3ton.setDefaultValue(0.95)
    args << ashpEERCapacityDerateFactor3ton

    #make a double argument for central ac 4 ton eer capacity derate
    ashpEERCapacityDerateFactor4ton = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("eer_capacity_derate_4ton", true)
    ashpEERCapacityDerateFactor4ton.setDisplayName("4 Ton EER Capacity Derate")
    ashpEERCapacityDerateFactor4ton.setDescription("EER multiplier for 4 ton air-conditioners.")
    ashpEERCapacityDerateFactor4ton.setDefaultValue(0.95)
    args << ashpEERCapacityDerateFactor4ton

    #make a double argument for central ac 5 ton eer capacity derate
    ashpEERCapacityDerateFactor5ton = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("eer_capacity_derate_5ton", true)
    ashpEERCapacityDerateFactor5ton.setDisplayName("5 Ton EER Capacity Derate")
    ashpEERCapacityDerateFactor5ton.setDescription("EER multiplier for 5 ton air-conditioners.")
    ashpEERCapacityDerateFactor5ton.setDefaultValue(0.95)
    args << ashpEERCapacityDerateFactor5ton
    
    #make a double argument for ashp 1.5 ton cop capacity derate
    ashpCOPCapacityDerateFactor1ton = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("cop_capacity_derate_1ton", true)
    ashpCOPCapacityDerateFactor1ton.setDisplayName("1.5 Ton COP Capacity Derate")
    ashpCOPCapacityDerateFactor1ton.setDescription("COP multiplier for 1.5 ton air-conditioners.")
    ashpCOPCapacityDerateFactor1ton.setDefaultValue(1.0)
    args << ashpCOPCapacityDerateFactor1ton
    
    #make a double argument for ashp 2 ton cop capacity derate
    ashpCOPCapacityDerateFactor2ton = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("cop_capacity_derate_2ton", true)
    ashpCOPCapacityDerateFactor2ton.setDisplayName("2 Ton COP Capacity Derate")
    ashpCOPCapacityDerateFactor2ton.setDescription("COP multiplier for 2 ton air-conditioners.")
    ashpCOPCapacityDerateFactor2ton.setDefaultValue(1.0)
    args << ashpCOPCapacityDerateFactor2ton

    #make a double argument for ashp 3 ton cop capacity derate
    ashpCOPCapacityDerateFactor3ton = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("cop_capacity_derate_3ton", true)
    ashpCOPCapacityDerateFactor3ton.setDisplayName("3 Ton COP Capacity Derate")
    ashpCOPCapacityDerateFactor3ton.setDescription("COP multiplier for 3 ton air-conditioners.")
    ashpCOPCapacityDerateFactor3ton.setDefaultValue(1.0)
    args << ashpCOPCapacityDerateFactor3ton

    #make a double argument for ashp 4 ton cop capacity derate
    ashpCOPCapacityDerateFactor4ton = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("cop_capacity_derate_4ton", true)
    ashpCOPCapacityDerateFactor4ton.setDisplayName("4 Ton COP Capacity Derate")
    ashpCOPCapacityDerateFactor4ton.setDescription("COP multiplier for 4 ton air-conditioners.")
    ashpCOPCapacityDerateFactor4ton.setDefaultValue(1.0)
    args << ashpCOPCapacityDerateFactor4ton

    #make a double argument for ashp 5 ton cop capacity derate
    ashpCOPCapacityDerateFactor5ton = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("cop_capacity_derate_5ton", true)
    ashpCOPCapacityDerateFactor5ton.setDisplayName("5 Ton COP Capacity Derate")
    ashpCOPCapacityDerateFactor5ton.setDescription("COP multiplier for 5 ton air-conditioners.")
    ashpCOPCapacityDerateFactor5ton.setDefaultValue(1.0)
    args << ashpCOPCapacityDerateFactor5ton    
    
    #make a string argument for ashp cooling/heating output capacity
    cap_display_names = OpenStudio::StringVector.new
    cap_display_names << Constants.SizingAuto
    (0.5..10.0).step(0.5) do |tons|
      cap_display_names << tons.to_s
    end
    hpcap = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("heat_pump_capacity", cap_display_names, true)
    hpcap.setDisplayName("Heat Pump Capacity")
    hpcap.setDescription("The output heating/cooling capacity of the heat pump.")
    hpcap.setUnits("tons")
    hpcap.setDefaultValue(Constants.SizingAuto)
    args << hpcap

    #make a string argument for supplemental heating output capacity
    cap_display_names = OpenStudio::StringVector.new
    cap_display_names << Constants.SizingAuto
    (5..150).step(5) do |kbtu|
      cap_display_names << kbtu.to_s
    end
    supcap = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("supplemental_capacity", cap_display_names, true)
    supcap.setDisplayName("Supplemental Heating Capacity")
    supcap.setDescription("The output heating capacity of the supplemental heater.")
    supcap.setUnits("kBtu/hr")
    supcap.setDefaultValue(Constants.SizingAuto)
    args << supcap 
    
    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    hpCoolingInstalledSEER = runner.getDoubleArgumentValue("seer",user_arguments)
    hpHeatingInstalledHSPF = runner.getDoubleArgumentValue("hspf",user_arguments)
    hpCoolingEER = [runner.getDoubleArgumentValue("eer",user_arguments), runner.getDoubleArgumentValue("eer2",user_arguments), runner.getDoubleArgumentValue("eer3",user_arguments), runner.getDoubleArgumentValue("eer4",user_arguments)]
    hpHeatingCOP = [runner.getDoubleArgumentValue("cop",user_arguments), runner.getDoubleArgumentValue("cop2",user_arguments), runner.getDoubleArgumentValue("cop3",user_arguments), runner.getDoubleArgumentValue("cop4",user_arguments)]
    hpSHRRated = [runner.getDoubleArgumentValue("shr",user_arguments), runner.getDoubleArgumentValue("shr2",user_arguments), runner.getDoubleArgumentValue("shr3",user_arguments), runner.getDoubleArgumentValue("shr4",user_arguments)]
    hpCapacityRatio = [runner.getDoubleArgumentValue("capacity_ratio",user_arguments), runner.getDoubleArgumentValue("capacity_ratio2",user_arguments), runner.getDoubleArgumentValue("capacity_ratio3",user_arguments), runner.getDoubleArgumentValue("capacity_ratio4",user_arguments)]
    hpRatedAirFlowRateCooling = runner.getDoubleArgumentValue("airflow_rate_cooling",user_arguments)
    hpRatedAirFlowRateHeating = runner.getDoubleArgumentValue("airflow_rate_heating",user_arguments)
    hpFanspeedRatioCooling = [runner.getDoubleArgumentValue("fan_speed_ratio_cooling",user_arguments), runner.getDoubleArgumentValue("fan_speed_ratio_cooling2",user_arguments), runner.getDoubleArgumentValue("fan_speed_ratio_cooling3",user_arguments), runner.getDoubleArgumentValue("fan_speed_ratio_cooling4",user_arguments)]
    hpFanspeedRatioHeating = [runner.getDoubleArgumentValue("fan_speed_ratio_heating",user_arguments), runner.getDoubleArgumentValue("fan_speed_ratio_heating2",user_arguments), runner.getDoubleArgumentValue("fan_speed_ratio_heating3",user_arguments), runner.getDoubleArgumentValue("fan_speed_ratio_heating4",user_arguments)]
    hpSupplyFanPowerRated = runner.getDoubleArgumentValue("fan_power_rated",user_arguments)
    hpSupplyFanPowerInstalled = runner.getDoubleArgumentValue("fan_power_installed",user_arguments)
    hpMinT = runner.getDoubleArgumentValue("min_temp",user_arguments)
    hpCrankcase = runner.getDoubleArgumentValue("crankcase_capacity",user_arguments)
    hpCrankcaseMaxT = runner.getDoubleArgumentValue("crankcase_max_temp",user_arguments)
    hpEERCapacityDerateFactor1ton = runner.getDoubleArgumentValue("eer_capacity_derate_1ton",user_arguments)
    hpEERCapacityDerateFactor2ton = runner.getDoubleArgumentValue("eer_capacity_derate_2ton",user_arguments)
    hpEERCapacityDerateFactor3ton = runner.getDoubleArgumentValue("eer_capacity_derate_3ton",user_arguments)
    hpEERCapacityDerateFactor4ton = runner.getDoubleArgumentValue("eer_capacity_derate_4ton",user_arguments)
    hpEERCapacityDerateFactor5ton = runner.getDoubleArgumentValue("eer_capacity_derate_5ton",user_arguments)
    hpEERCapacityDerateFactor = [hpEERCapacityDerateFactor1ton, hpEERCapacityDerateFactor2ton, hpEERCapacityDerateFactor3ton, hpEERCapacityDerateFactor4ton, hpEERCapacityDerateFactor5ton]
    hpCOPCapacityDerateFactor1ton = runner.getDoubleArgumentValue("cop_capacity_derate_1ton",user_arguments)
    hpCOPCapacityDerateFactor2ton = runner.getDoubleArgumentValue("cop_capacity_derate_2ton",user_arguments)
    hpCOPCapacityDerateFactor3ton = runner.getDoubleArgumentValue("cop_capacity_derate_3ton",user_arguments)
    hpCOPCapacityDerateFactor4ton = runner.getDoubleArgumentValue("cop_capacity_derate_4ton",user_arguments)
    hpCOPCapacityDerateFactor5ton = runner.getDoubleArgumentValue("cop_capacity_derate_5ton",user_arguments)
    hpCOPCapacityDerateFactor = [hpCOPCapacityDerateFactor1ton, hpCOPCapacityDerateFactor2ton, hpCOPCapacityDerateFactor3ton, hpCOPCapacityDerateFactor4ton, hpCOPCapacityDerateFactor5ton]
    hpOutputCapacity = runner.getStringArgumentValue("heat_pump_capacity",user_arguments)
    unless hpOutputCapacity == Constants.SizingAuto
      hpOutputCapacity = OpenStudio::convert(hpOutputCapacity.to_f,"ton","Btu/h").get
    end
    supplementalOutputCapacity = runner.getStringArgumentValue("supplemental_capacity",user_arguments)
    unless supplementalOutputCapacity == Constants.SizingAuto
      supplementalOutputCapacity = OpenStudio::convert(supplementalOutputCapacity.to_f,"kBtu/h","Btu/h").get
    end
    
    supply = Supply.new
    
    # Performance curves
    
    # NOTE: These coefficients are in IP UNITS
    supply.COOL_CAP_FT_SPEC_coefficients = [[3.63396857, -0.093606786, 0.000918114, 0.011852512, -0.0000318307, -0.000206446],
                                            [1.808745668, -0.041963484, 0.000545263, 0.011346539, -0.000023838, -0.000205162],
                                            [0.112814745, 0.005638646, 0.000203427, 0.011981545, -0.0000207957, -0.000212379],
                                            [1.141506147, -0.023973142, 0.000420763, 0.01038334, -0.0000174633, -0.000197092]]
    supply.COOL_EIR_FT_SPEC_coefficients = [[-1.380674217, 0.083176919, -0.000676029, -0.028120348, 0.000320593, -0.0000616147],
                                            [4.817787321, -0.100122768, 0.000673499, -0.026889359, 0.00029445, -0.0000390331],
                                            [-1.502227232, 0.05896401, -0.000439349, 0.002198465, 0.000148486, -0.000159553],
                                            [-3.443078025, 0.115186164, -0.000852001, 0.004678056, 0.000134319, -0.000171976]]
    supply.COOL_CAP_FFLOW_SPEC_coefficients = [[1, 0, 0]] * 4
    supply.COOL_EIR_FFLOW_SPEC_coefficients = [[1, 0, 0]] * 4
    supply.HEAT_CAP_FT_SPEC_coefficients = [[0.304192655, -0.003972566, 0.0000196432, 0.024471251, -0.000000774126, -0.0000841323],
                                            [0.496381324, -0.00144792, 0.0, 0.016020855, 0.0000203447, -0.0000584118],
                                            [0.697171186, -0.006189599, 0.0000337077, 0.014291981, 0.0000105633, -0.0000387956],
                                            [0.555513805, -0.001337363, -0.00000265117, 0.014328826, 0.0000163849, -0.0000480711]]
    supply.HEAT_EIR_FT_SPEC_coefficients = [[0.708311527, 0.020732093, 0.000391479, -0.037640031, 0.000979937, -0.001079042],
                                            [0.025480155, 0.020169585, 0.000121341, -0.004429789, 0.000166472, -0.00036447],
                                            [0.379003189, 0.014195012, 0.0000821046, -0.008894061, 0.000151519, -0.000210299],
                                            [0.690404655, 0.00616619, 0.000137643, -0.009350199, 0.000153427, -0.000213258]]
    supply.HEAT_CAP_FFLOW_SPEC_coefficients = [[1, 0, 0]] * 4
    supply.HEAT_EIR_FFLOW_SPEC_coefficients = [[1, 0, 0]] * 4

    supply.static = UnitConversion.inH2O2Pa(0.5) # Pascal

    # Flow rate through AC units - hardcoded assumption of 400 cfm/ton
    supply.cfm_ton = 400 # cfm / ton

    supply.HPCoolingOversizingFactor = 1 # Default to a value of 1 (currently only used for MSHPs)
    supply.SpaceConditionedMult = 1 # Default used for central equipment    
    
    # Cooling Coil
    supply.CFM_TON_Rated = HVAC.calc_cfm_ton_rated(hpRatedAirFlowRateCooling, hpFanspeedRatioCooling, hpCapacityRatio)
    supply = HVAC._processAirSystemCoolingCoil(runner, 4, hpCoolingEER, hpCoolingInstalledSEER, hpSupplyFanPowerInstalled, hpSupplyFanPowerRated, hpSHRRated, hpCapacityRatio, hpFanspeedRatioCooling, hpCrankcase, hpCrankcaseMaxT, hpEERCapacityDerateFactor, supply)

    # Heating Coil
    supply.CFM_TON_Rated_Heat = HVAC.calc_cfm_ton_rated(hpRatedAirFlowRateHeating, hpFanspeedRatioHeating, hpCapacityRatio)
    supply = HVAC._processAirSystemHeatingCoil(hpHeatingCOP, hpHeatingInstalledHSPF, hpSupplyFanPowerRated, hpCapacityRatio, hpFanspeedRatioHeating, hpMinT, hpCOPCapacityDerateFactor, supply)
    
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
    
    # Remove boiler hot water loop if it exists
    HVAC.remove_hot_water_loop(model, runner)    
    
    # Get building units
    units = Geometry.get_building_units(model, runner)
    if units.nil?
        return false
    end
    
    units.each do |unit|
      
      obj_name = Constants.ObjectNameAirSourceHeatPump(unit.name.to_s)
      
      thermal_zones = Geometry.get_thermal_zones_from_spaces(unit.spaces)

      control_slave_zones_hash = HVAC.get_control_and_slave_zones(thermal_zones)
      control_slave_zones_hash.each do |control_zone, slave_zones|
    
        # Remove existing equipment
        HVAC.remove_existing_hvac_equipment(model, runner, Constants.ObjectNameAirSourceHeatPump, control_zone)    
      
        # _processCurvesDXHeating
        htg_coil_stage_data = HVAC._processCurvesDXHeating(model, supply, hpOutputCapacity)
      
        # _processSystemHeatingCoil        

        htg_coil = OpenStudio::Model::CoilHeatingDXMultiSpeed.new(model)
        htg_coil.setName(obj_name + " heating coil")
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
        
        supp_htg_coil = OpenStudio::Model::CoilHeatingElectric.new(model, model.alwaysOnDiscreteSchedule)
        supp_htg_coil.setName(obj_name + " supp heater")
        supp_htg_coil.setEfficiency(1)
        if supplementalOutputCapacity != Constants.SizingAuto
          supp_htg_coil.setNominalCapacity(OpenStudio::convert(supplementalOutputCapacity,"Btu/h","W").get)
        end
        
        # _processCurvesDXCooling

        clg_coil_stage_data = HVAC._processCurvesDXCooling(model, supply, hpOutputCapacity)        
        
        # _processSystemCoolingCoil
        
        clg_coil = OpenStudio::Model::CoilCoolingDXMultiSpeed.new(model)
        clg_coil.setName(obj_name + " cooling coil")
        clg_coil.setCondenserType("AirCooled")
        clg_coil.setApplyPartLoadFractiontoSpeedsGreaterthan1(false)
        clg_coil.setApplyLatentDegradationtoSpeedsGreaterthan1(false)        
        clg_coil.setFuelType("Electricity")
             
        clg_coil_stage_data.each do |i|
            clg_coil.addStage(i)
        end   
        
        # _processSystemFan
        
        fan = OpenStudio::Model::FanOnOff.new(model, model.alwaysOnDiscreteSchedule)
        fan.setName(obj_name + " supply fan")
        fan.setEndUseSubcategory(Constants.EndUseHVACFan)
        fan.setFanEfficiency(supply.eff)
        fan.setPressureRise(supply.static)
        fan.setMotorEfficiency(1)
        fan.setMotorInAirstreamFraction(1)    
        
        # _processSystemAir
                 
        air_loop_unitary = OpenStudio::Model::AirLoopHVACUnitarySystem.new(model)
        air_loop_unitary.setName(obj_name + " unitary system")
        air_loop_unitary.setAvailabilitySchedule(model.alwaysOnDiscreteSchedule)
        air_loop_unitary.setSupplyFan(fan)
        air_loop_unitary.setHeatingCoil(htg_coil)
        air_loop_unitary.setCoolingCoil(clg_coil)
        air_loop_unitary.setSupplementalHeatingCoil(supp_htg_coil)
        air_loop_unitary.setFanPlacement("BlowThrough")
        air_loop_unitary.setSupplyAirFanOperatingModeSchedule(model.alwaysOffDiscreteSchedule)
        air_loop_unitary.setMaximumSupplyAirTemperature(OpenStudio::convert(supply.supp_htg_max_supply_temp,"F","C").get)
        air_loop_unitary.setMaximumOutdoorDryBulbTemperatureforSupplementalHeaterOperation(OpenStudio::convert(supply.supp_htg_max_outdoor_temp,"F","C").get)
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

        slave_zones.each do |slave_zone|

          # Remove existing equipment
          HVAC.remove_existing_hvac_equipment(model, runner, Constants.ObjectNameAirSourceHeatPump, slave_zone)
      
          diffuser_fbsmt = OpenStudio::Model::AirTerminalSingleDuctUncontrolled.new(model, model.alwaysOnDiscreteSchedule)
          diffuser_fbsmt.setName(obj_name + " #{slave_zone.name} direct air")
          air_loop.addBranchForZone(slave_zone, diffuser_fbsmt.to_StraightComponent)

          air_loop.addBranchForZone(slave_zone)
          runner.registerInfo("Added '#{air_loop.name}' to '#{slave_zone.name}' of #{unit.name}")

        end    
      
      end
      
    end
	
    return true
 
  end #end the run method
  
end #end the measure

#this allows the measure to be use by the application
ProcessVariableSpeedAirSourceHeatPump.new.registerWithApplication