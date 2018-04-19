#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"
require "#{File.dirname(__FILE__)}/resources/hvac"

#start the measure
class ProcessVariableSpeedAirSourceHeatPump < OpenStudio::Measure::ModelMeasure

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Residential Variable-Speed Air Source Heat Pump"
  end
  
  def description
    return "This measure removes any existing HVAC components from the building and adds a variable-speed air source heat pump along with an on/off supply fan to a unitary air loop. For multifamily buildings, the variable-speed air source heat pump can be set for all units of the building.#{Constants.WorkflowDescription}"
  end
  
  def modeler_description
    return "Any supply components or baseboard convective electrics/waters are removed from any existing air/plant loops or zones. Any existing air/plant loops are also removed. A heating DX coil, cooling DX coil, electric supplemental heating coil, and an on/off supply fan are added to a unitary air loop. The unitary air loop is added to the supply inlet node of the air loop. This air loop is added to a branch for the living zone. A diffuser is added to the branch for the living zone as well as for the finished basement if it exists."
  end   
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    #make a string argument for ashp installed seer
    seer = OpenStudio::Measure::OSArgument::makeDoubleArgument("seer", true)
    seer.setDisplayName("Installed SEER")
    seer.setUnits("Btu/W-h")
    seer.setDescription("The installed Seasonal Energy Efficiency Ratio (SEER) of the heat pump.")
    seer.setDefaultValue(22.0)
    args << seer
    
    #make a string argument for ashp installed hspf
    hspf = OpenStudio::Measure::OSArgument::makeDoubleArgument("hspf", true)
    hspf.setDisplayName("Installed HSPF")
    hspf.setUnits("Btu/W-h")
    hspf.setDescription("The installed Heating Seasonal Performance Factor (HSPF) of the heat pump.")
    hspf.setDefaultValue(10.0)
    args << hspf

    #make a double argument for ashp eer
    eer = OpenStudio::Measure::OSArgument::makeDoubleArgument("eer", true)
    eer.setDisplayName("EER")
    eer.setUnits("kBtu/kWh")
    eer.setDescription("EER (net) from the A test (95 ODB/80 EDB/67 EWB).")
    eer.setDefaultValue(17.4)
    args << eer
    
    #make a double argument for ashp eer 2
    eer2 = OpenStudio::Measure::OSArgument::makeDoubleArgument("eer2", true)
    eer2.setDisplayName("EER 2")
    eer2.setUnits("kBtu/kWh")
    eer2.setDescription("EER (net) from the A test (95 ODB/80 EDB/67 EWB) for the second speed.")
    eer2.setDefaultValue(16.8)
    args << eer2    
    
    #make a double argument for ashp eer 3
    eer3 = OpenStudio::Measure::OSArgument::makeDoubleArgument("eer3", true)
    eer3.setDisplayName("EER 3")
    eer3.setUnits("kBtu/kWh")
    eer3.setDescription("EER (net) from the A test (95 ODB/80 EDB/67 EWB) for the third speed.")
    eer3.setDefaultValue(14.3)
    args << eer3
    
    #make a double argument for ashp eer 4
    eer4 = OpenStudio::Measure::OSArgument::makeDoubleArgument("eer4", true)
    eer4.setDisplayName("EER 4")
    eer4.setUnits("kBtu/kWh")
    eer4.setDescription("EER (net) from the A test (95 ODB/80 EDB/67 EWB) for the fourth speed.")
    eer4.setDefaultValue(13.0)
    args << eer4    
    
    #make a double argument for ashp cop
    cop = OpenStudio::Measure::OSArgument::makeDoubleArgument("cop", true)
    cop.setDisplayName("COP")
    cop.setUnits("Wh/Wh")
    cop.setDescription("COP (net) at 47 ODB/70 EDB/60 EWB (AHRI rated conditions).")
    cop.setDefaultValue(4.82)
    args << cop
    
    #make a double argument for ashp cop 2
    cop2 = OpenStudio::Measure::OSArgument::makeDoubleArgument("cop2", true)
    cop2.setDisplayName("COP 2")
    cop2.setUnits("Wh/Wh")
    cop2.setDescription("COP (net) at 47 ODB/70 EDB/60 EWB (AHRI rated conditions) for the second speed.")
    cop2.setDefaultValue(4.56)
    args << cop2
    
    #make a double argument for ashp cop 3
    cop3 = OpenStudio::Measure::OSArgument::makeDoubleArgument("cop3", true)
    cop3.setDisplayName("COP 3")
    cop3.setUnits("Wh/Wh")
    cop3.setDescription("COP (net) at 47 ODB/70 EDB/60 EWB (AHRI rated conditions) for the third speed.")
    cop3.setDefaultValue(3.89)
    args << cop3
    
    #make a double argument for ashp cop 4
    cop4 = OpenStudio::Measure::OSArgument::makeDoubleArgument("cop4", true)
    cop4.setDisplayName("COP 4")
    cop4.setUnits("Wh/Wh")
    cop4.setDescription("COP (net) at 47 ODB/70 EDB/60 EWB (AHRI rated conditions) for the fourth speed.")
    cop4.setDefaultValue(3.92)
    args << cop4
    
    #make a double argument for ashp rated shr
    shr = OpenStudio::Measure::OSArgument::makeDoubleArgument("shr", true)
    shr.setDisplayName("Rated SHR")
    shr.setDescription("The sensible heat ratio (ratio of the sensible portion of the load to the total load) at the nominal rated capacity.")
    shr.setDefaultValue(0.84)
    args << shr
    
    #make a double argument for ashp rated shr 2
    shr2 = OpenStudio::Measure::OSArgument::makeDoubleArgument("shr2", true)
    shr2.setDisplayName("Rated SHR 2")
    shr2.setDescription("The sensible heat ratio (ratio of the sensible portion of the load to the total load) at the nominal rated capacity for the second speed.")
    shr2.setDefaultValue(0.79)
    args << shr2
    
    #make a double argument for ashp rated shr 3
    shr3 = OpenStudio::Measure::OSArgument::makeDoubleArgument("shr3", true)
    shr3.setDisplayName("Rated SHR 3")
    shr3.setDescription("The sensible heat ratio (ratio of the sensible portion of the load to the total load) at the nominal rated capacity for the third speed.")
    shr3.setDefaultValue(0.76)
    args << shr3

    #make a double argument for ashp rated shr 4
    shr4 = OpenStudio::Measure::OSArgument::makeDoubleArgument("shr4", true)
    shr4.setDisplayName("Rated SHR 4")
    shr4.setDescription("The sensible heat ratio (ratio of the sensible portion of the load to the total load) at the nominal rated capacity for the fourth speed.")
    shr4.setDefaultValue(0.77)
    args << shr4    

    #make a double argument for ashp capacity ratio
    capacity_ratio = OpenStudio::Measure::OSArgument::makeDoubleArgument("capacity_ratio", true)
    capacity_ratio.setDisplayName("Capacity Ratio")
    capacity_ratio.setDescription("Capacity divided by rated capacity.")
    capacity_ratio.setDefaultValue(0.49)
    args << capacity_ratio

    #make a double argument for ashp capacity ratio 2
    capacity_ratio2 = OpenStudio::Measure::OSArgument::makeDoubleArgument("capacity_ratio2", true)
    capacity_ratio2.setDisplayName("Capacity Ratio 2")
    capacity_ratio2.setDescription("Capacity divided by rated capacity for the second speed.")
    capacity_ratio2.setDefaultValue(0.67)
    args << capacity_ratio2    
    
    #make a double argument for ashp capacity ratio 3
    capacity_ratio3 = OpenStudio::Measure::OSArgument::makeDoubleArgument("capacity_ratio3", true)
    capacity_ratio3.setDisplayName("Capacity Ratio 3")
    capacity_ratio3.setDescription("Capacity divided by rated capacity for the third speed.")
    capacity_ratio3.setDefaultValue(1.0)
    args << capacity_ratio3

    #make a double argument for ashp capacity ratio 4
    capacity_ratio4 = OpenStudio::Measure::OSArgument::makeDoubleArgument("capacity_ratio4", true)
    capacity_ratio4.setDisplayName("Capacity Ratio 4")
    capacity_ratio4.setDescription("Capacity divided by rated capacity for the fourth speed.")
    capacity_ratio4.setDefaultValue(1.2)
    args << capacity_ratio4    
    
    #make a double argument for ashp fan speed ratio cooling
    fan_speed_ratio_cooling = OpenStudio::Measure::OSArgument::makeDoubleArgument("fan_speed_ratio_cooling", true)
    fan_speed_ratio_cooling.setDisplayName("Fan Speed Ratio Cooling")
    fan_speed_ratio_cooling.setDescription("Cooling fan speed divided by fan speed at the compressor speed for which Capacity Ratio = 1.0.")
    fan_speed_ratio_cooling.setDefaultValue(0.7)
    args << fan_speed_ratio_cooling
    
    #make a double argument for ashp fan speed ratio cooling 2
    fan_speed_ratio_cooling2 = OpenStudio::Measure::OSArgument::makeDoubleArgument("fan_speed_ratio_cooling2", true)
    fan_speed_ratio_cooling2.setDisplayName("Fan Speed Ratio Cooling 2")
    fan_speed_ratio_cooling2.setDescription("Cooling fan speed divided by fan speed at the compressor speed for which Capacity Ratio = 1.0 for the second speed.")
    fan_speed_ratio_cooling2.setDefaultValue(0.9)
    args << fan_speed_ratio_cooling2
    
    #make a double argument for ashp fan speed ratio cooling 3
    fan_speed_ratio_cooling3 = OpenStudio::Measure::OSArgument::makeDoubleArgument("fan_speed_ratio_cooling3", true)
    fan_speed_ratio_cooling3.setDisplayName("Fan Speed Ratio Cooling 3")
    fan_speed_ratio_cooling3.setDescription("Cooling fan speed divided by fan speed at the compressor speed for which Capacity Ratio = 1.0 for the third speed.")
    fan_speed_ratio_cooling3.setDefaultValue(1.0)
    args << fan_speed_ratio_cooling3
    
    #make a double argument for ashp fan speed ratio cooling 4
    fan_speed_ratio_cooling4 = OpenStudio::Measure::OSArgument::makeDoubleArgument("fan_speed_ratio_cooling4", true)
    fan_speed_ratio_cooling4.setDisplayName("Fan Speed Ratio Cooling 4")
    fan_speed_ratio_cooling4.setDescription("Cooling fan speed divided by fan speed at the compressor speed for which Capacity Ratio = 1.0 for the fourth speed.")
    fan_speed_ratio_cooling4.setDefaultValue(1.26)
    args << fan_speed_ratio_cooling4
    
    #make a double argument for ashp fan speed ratio heating
    fan_speed_ratio_heating = OpenStudio::Measure::OSArgument::makeDoubleArgument("fan_speed_ratio_heating", true)
    fan_speed_ratio_heating.setDisplayName("Fan Speed Ratio Heating")
    fan_speed_ratio_heating.setDescription("Heating fan speed divided by fan speed at the compressor speed for which Capacity Ratio = 1.0.")
    fan_speed_ratio_heating.setDefaultValue(0.74)
    args << fan_speed_ratio_heating
    
    #make a double argument for ashp fan speed ratio heating 2
    fan_speed_ratio_heating2 = OpenStudio::Measure::OSArgument::makeDoubleArgument("fan_speed_ratio_heating2", true)
    fan_speed_ratio_heating2.setDisplayName("Fan Speed Ratio Heating 2")
    fan_speed_ratio_heating2.setDescription("Heating fan speed divided by fan speed at the compressor speed for which Capacity Ratio = 1.0 for the second speed.")
    fan_speed_ratio_heating2.setDefaultValue(0.92)
    args << fan_speed_ratio_heating2

    #make a double argument for ashp fan speed ratio heating 3
    fan_speed_ratio_heating3 = OpenStudio::Measure::OSArgument::makeDoubleArgument("fan_speed_ratio_heating3", true)
    fan_speed_ratio_heating3.setDisplayName("Fan Speed Ratio Heating 3")
    fan_speed_ratio_heating3.setDescription("Heating fan speed divided by fan speed at the compressor speed for which Capacity Ratio = 1.0 for the third speed.")
    fan_speed_ratio_heating3.setDefaultValue(1.0)
    args << fan_speed_ratio_heating3
    
    #make a double argument for ashp fan speed ratio heating 4
    fan_speed_ratio_heating4 = OpenStudio::Measure::OSArgument::makeDoubleArgument("fan_speed_ratio_heating4", true)
    fan_speed_ratio_heating4.setDisplayName("Fan Speed Ratio Heating 4")
    fan_speed_ratio_heating4.setDescription("Heating fan speed divided by fan speed at the compressor speed for which Capacity Ratio = 1.0 for the fourth speed.")
    fan_speed_ratio_heating4.setDefaultValue(1.22)
    args << fan_speed_ratio_heating4
    
    #make a double argument for ashp rated supply fan power
    fan_power_rated = OpenStudio::Measure::OSArgument::makeDoubleArgument("fan_power_rated", true)
    fan_power_rated.setDisplayName("Rated Supply Fan Power")
    fan_power_rated.setUnits("W/cfm")
    fan_power_rated.setDescription("Fan power (in W) per delivered airflow rate (in cfm) of the outdoor fan under conditions prescribed by AHRI Standard 210/240 for SEER testing.")
    fan_power_rated.setDefaultValue(0.14)
    args << fan_power_rated
    
    #make a double argument for ashp installed supply fan power
    fan_power_installed = OpenStudio::Measure::OSArgument::makeDoubleArgument("fan_power_installed", true)
    fan_power_installed.setDisplayName("Installed Supply Fan Power")
    fan_power_installed.setUnits("W/cfm")
    fan_power_installed.setDescription("Fan power (in W) per delivered airflow rate (in cfm) of the outdoor fan for the maximum fan speed under actual operating conditions.")
    fan_power_installed.setDefaultValue(0.3)
    args << fan_power_installed    
    
    #make a double argument for ashp min t
    min_temp = OpenStudio::Measure::OSArgument::makeDoubleArgument("min_temp", true)
    min_temp.setDisplayName("Min Temp")
    min_temp.setUnits("degrees F")
    min_temp.setDescription("Outdoor dry-bulb temperature below which compressor turns off.")
    min_temp.setDefaultValue(0.0)
    args << min_temp  
  
    #make a double argument for central ac crankcase
    crankcase_capacity = OpenStudio::Measure::OSArgument::makeDoubleArgument("crankcase_capacity", true)
    crankcase_capacity.setDisplayName("Crankcase")
    crankcase_capacity.setUnits("kW")
    crankcase_capacity.setDescription("Capacity of the crankcase heater for the compressor.")
    crankcase_capacity.setDefaultValue(0.02)
    args << crankcase_capacity

    #make a double argument for ashp crankcase max t
    crankcase_temp = OpenStudio::Measure::OSArgument::makeDoubleArgument("crankcase_temp", true)
    crankcase_temp.setDisplayName("Crankcase Max Temp")
    crankcase_temp.setUnits("degrees F")
    crankcase_temp.setDescription("Outdoor dry-bulb temperature above which compressor crankcase heating is disabled.")
    crankcase_temp.setDefaultValue(55.0)
    args << crankcase_temp
    
    #make a double argument for ashp 1.5 ton eer capacity derate
    seer_capacity_derate_1ton = OpenStudio::Measure::OSArgument::makeDoubleArgument("eer_capacity_derate_1ton", true)
    seer_capacity_derate_1ton.setDisplayName("1.5 Ton EER Capacity Derate")
    seer_capacity_derate_1ton.setDescription("EER multiplier for 1.5 ton air-conditioners.")
    seer_capacity_derate_1ton.setDefaultValue(1.0)
    args << seer_capacity_derate_1ton
    
    #make a double argument for central ac 2 ton eer capacity derate
    seer_capacity_derate_2ton = OpenStudio::Measure::OSArgument::makeDoubleArgument("eer_capacity_derate_2ton", true)
    seer_capacity_derate_2ton.setDisplayName("2 Ton EER Capacity Derate")
    seer_capacity_derate_2ton.setDescription("EER multiplier for 2 ton air-conditioners.")
    seer_capacity_derate_2ton.setDefaultValue(1.0)
    args << seer_capacity_derate_2ton

    #make a double argument for central ac 3 ton eer capacity derate
    seer_capacity_derate_3ton = OpenStudio::Measure::OSArgument::makeDoubleArgument("eer_capacity_derate_3ton", true)
    seer_capacity_derate_3ton.setDisplayName("3 Ton EER Capacity Derate")
    seer_capacity_derate_3ton.setDescription("EER multiplier for 3 ton air-conditioners.")
    seer_capacity_derate_3ton.setDefaultValue(0.95)
    args << seer_capacity_derate_3ton

    #make a double argument for central ac 4 ton eer capacity derate
    seer_capacity_derate_4ton = OpenStudio::Measure::OSArgument::makeDoubleArgument("eer_capacity_derate_4ton", true)
    seer_capacity_derate_4ton.setDisplayName("4 Ton EER Capacity Derate")
    seer_capacity_derate_4ton.setDescription("EER multiplier for 4 ton air-conditioners.")
    seer_capacity_derate_4ton.setDefaultValue(0.95)
    args << seer_capacity_derate_4ton

    #make a double argument for central ac 5 ton eer capacity derate
    seer_capacity_derate_5ton = OpenStudio::Measure::OSArgument::makeDoubleArgument("eer_capacity_derate_5ton", true)
    seer_capacity_derate_5ton.setDisplayName("5 Ton EER Capacity Derate")
    seer_capacity_derate_5ton.setDescription("EER multiplier for 5 ton air-conditioners.")
    seer_capacity_derate_5ton.setDefaultValue(0.95)
    args << seer_capacity_derate_5ton
    
    #make a double argument for ashp 1.5 ton cop capacity derate
    cop_capacity_derate_1ton = OpenStudio::Measure::OSArgument::makeDoubleArgument("cop_capacity_derate_1ton", true)
    cop_capacity_derate_1ton.setDisplayName("1.5 Ton COP Capacity Derate")
    cop_capacity_derate_1ton.setDescription("COP multiplier for 1.5 ton air-conditioners.")
    cop_capacity_derate_1ton.setDefaultValue(1.0)
    args << cop_capacity_derate_1ton
    
    #make a double argument for ashp 2 ton cop capacity derate
    cop_capacity_derate_2ton = OpenStudio::Measure::OSArgument::makeDoubleArgument("cop_capacity_derate_2ton", true)
    cop_capacity_derate_2ton.setDisplayName("2 Ton COP Capacity Derate")
    cop_capacity_derate_2ton.setDescription("COP multiplier for 2 ton air-conditioners.")
    cop_capacity_derate_2ton.setDefaultValue(1.0)
    args << cop_capacity_derate_2ton

    #make a double argument for ashp 3 ton cop capacity derate
    cop_capacity_derate_3ton = OpenStudio::Measure::OSArgument::makeDoubleArgument("cop_capacity_derate_3ton", true)
    cop_capacity_derate_3ton.setDisplayName("3 Ton COP Capacity Derate")
    cop_capacity_derate_3ton.setDescription("COP multiplier for 3 ton air-conditioners.")
    cop_capacity_derate_3ton.setDefaultValue(1.0)
    args << cop_capacity_derate_3ton

    #make a double argument for ashp 4 ton cop capacity derate
    cop_capacity_derate_4ton = OpenStudio::Measure::OSArgument::makeDoubleArgument("cop_capacity_derate_4ton", true)
    cop_capacity_derate_4ton.setDisplayName("4 Ton COP Capacity Derate")
    cop_capacity_derate_4ton.setDescription("COP multiplier for 4 ton air-conditioners.")
    cop_capacity_derate_4ton.setDefaultValue(1.0)
    args << cop_capacity_derate_4ton

    #make a double argument for ashp 5 ton cop capacity derate
    cop_capacity_derate_5ton = OpenStudio::Measure::OSArgument::makeDoubleArgument("cop_capacity_derate_5ton", true)
    cop_capacity_derate_5ton.setDisplayName("5 Ton COP Capacity Derate")
    cop_capacity_derate_5ton.setDescription("COP multiplier for 5 ton air-conditioners.")
    cop_capacity_derate_5ton.setDefaultValue(1.0)
    args << cop_capacity_derate_5ton    
    
    #make a string argument for ashp cooling/heating output capacity
    heat_pump_capacity = OpenStudio::Measure::OSArgument::makeStringArgument("heat_pump_capacity", true)
    heat_pump_capacity.setDisplayName("Heat Pump Capacity")
    heat_pump_capacity.setDescription("The output heating/cooling capacity of the heat pump. If using '#{Constants.SizingAuto}', the autosizing algorithm will use ACCA Manual S to set the heat pump capacity based on the cooling load, with up to 1.3x oversizing allowed for variable-speed equipment in colder climates when the heating load exceeds the cooling load. If using '#{Constants.SizingAutoMaxLoad}', the autosizing algorithm will override ACCA Manual S and use the maximum of the heating and cooling loads to set the heat pump capacity, based on the heating/cooling capacities under design conditions.")
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
    supplemental_capacity.setDescription("The output heating capacity of the supplemental heater. If using '#{Constants.SizingAuto}', the autosizing algorithm will use ACCA Manual S to set the heat pump supplemental heating capacity.")
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
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    seer = runner.getDoubleArgumentValue("seer",user_arguments)
    hspf = runner.getDoubleArgumentValue("hspf",user_arguments)
    eers = [runner.getDoubleArgumentValue("eer",user_arguments), runner.getDoubleArgumentValue("eer2",user_arguments), runner.getDoubleArgumentValue("eer3",user_arguments), runner.getDoubleArgumentValue("eer4",user_arguments)]
    cops = [runner.getDoubleArgumentValue("cop",user_arguments), runner.getDoubleArgumentValue("cop2",user_arguments), runner.getDoubleArgumentValue("cop3",user_arguments), runner.getDoubleArgumentValue("cop4",user_arguments)]
    shrs = [runner.getDoubleArgumentValue("shr",user_arguments), runner.getDoubleArgumentValue("shr2",user_arguments), runner.getDoubleArgumentValue("shr3",user_arguments), runner.getDoubleArgumentValue("shr4",user_arguments)]
    capacity_ratios = [runner.getDoubleArgumentValue("capacity_ratio",user_arguments), runner.getDoubleArgumentValue("capacity_ratio2",user_arguments), runner.getDoubleArgumentValue("capacity_ratio3",user_arguments), runner.getDoubleArgumentValue("capacity_ratio4",user_arguments)]
    fan_speed_ratios_cooling = [runner.getDoubleArgumentValue("fan_speed_ratio_cooling",user_arguments), runner.getDoubleArgumentValue("fan_speed_ratio_cooling2",user_arguments), runner.getDoubleArgumentValue("fan_speed_ratio_cooling3",user_arguments), runner.getDoubleArgumentValue("fan_speed_ratio_cooling4",user_arguments)]
    fan_speed_ratios_heating = [runner.getDoubleArgumentValue("fan_speed_ratio_heating",user_arguments), runner.getDoubleArgumentValue("fan_speed_ratio_heating2",user_arguments), runner.getDoubleArgumentValue("fan_speed_ratio_heating3",user_arguments), runner.getDoubleArgumentValue("fan_speed_ratio_heating4",user_arguments)]
    fan_power_rated = runner.getDoubleArgumentValue("fan_power_rated",user_arguments)
    fan_power_installed = runner.getDoubleArgumentValue("fan_power_installed",user_arguments)
    min_temp = runner.getDoubleArgumentValue("min_temp",user_arguments)
    crankcase_capacity = runner.getDoubleArgumentValue("crankcase_capacity",user_arguments)
    crankcase_temp = runner.getDoubleArgumentValue("crankcase_temp",user_arguments)
    eer_capacity_derate_1ton = runner.getDoubleArgumentValue("eer_capacity_derate_1ton",user_arguments)
    eer_capacity_derate_2ton = runner.getDoubleArgumentValue("eer_capacity_derate_2ton",user_arguments)
    eer_capacity_derate_3ton = runner.getDoubleArgumentValue("eer_capacity_derate_3ton",user_arguments)
    eer_capacity_derate_4ton = runner.getDoubleArgumentValue("eer_capacity_derate_4ton",user_arguments)
    eer_capacity_derate_5ton = runner.getDoubleArgumentValue("eer_capacity_derate_5ton",user_arguments)
    eer_capacity_derates = [eer_capacity_derate_1ton, eer_capacity_derate_2ton, eer_capacity_derate_3ton, eer_capacity_derate_4ton, eer_capacity_derate_5ton]
    cop_capacity_derate_1ton = runner.getDoubleArgumentValue("cop_capacity_derate_1ton",user_arguments)
    cop_capacity_derate_2ton = runner.getDoubleArgumentValue("cop_capacity_derate_2ton",user_arguments)
    cop_capacity_derate_3ton = runner.getDoubleArgumentValue("cop_capacity_derate_3ton",user_arguments)
    cop_capacity_derate_4ton = runner.getDoubleArgumentValue("cop_capacity_derate_4ton",user_arguments)
    cop_capacity_derate_5ton = runner.getDoubleArgumentValue("cop_capacity_derate_5ton",user_arguments)
    cop_capacity_derates = [cop_capacity_derate_1ton, cop_capacity_derate_2ton, cop_capacity_derate_3ton, cop_capacity_derate_4ton, cop_capacity_derate_5ton]
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
    number_Speeds = 4
    
    # Performance curves
    
    # NOTE: These coefficients are in IP UNITS
    cOOL_CAP_FT_SPEC = [[3.63396857, -0.093606786, 0.000918114, 0.011852512, -0.0000318307, -0.000206446],
                        [1.808745668, -0.041963484, 0.000545263, 0.011346539, -0.000023838, -0.000205162],
                        [0.112814745, 0.005638646, 0.000203427, 0.011981545, -0.0000207957, -0.000212379],
                        [1.141506147, -0.023973142, 0.000420763, 0.01038334, -0.0000174633, -0.000197092]]
    cOOL_EIR_FT_SPEC = [[-1.380674217, 0.083176919, -0.000676029, -0.028120348, 0.000320593, -0.0000616147],
                        [4.817787321, -0.100122768, 0.000673499, -0.026889359, 0.00029445, -0.0000390331],
                        [-1.502227232, 0.05896401, -0.000439349, 0.002198465, 0.000148486, -0.000159553],
                        [-3.443078025, 0.115186164, -0.000852001, 0.004678056, 0.000134319, -0.000171976]]
    cOOL_CAP_FFLOW_SPEC = [[1, 0, 0]] * number_Speeds
    cOOL_EIR_FFLOW_SPEC = [[1, 0, 0]] * number_Speeds
    hEAT_CAP_FT_SPEC = [[0.304192655, -0.003972566, 0.0000196432, 0.024471251, -0.000000774126, -0.0000841323],
                        [0.496381324, -0.00144792, 0.0, 0.016020855, 0.0000203447, -0.0000584118],
                        [0.697171186, -0.006189599, 0.0000337077, 0.014291981, 0.0000105633, -0.0000387956],
                        [0.555513805, -0.001337363, -0.00000265117, 0.014328826, 0.0000163849, -0.0000480711]]
    hEAT_EIR_FT_SPEC = [[0.708311527, 0.020732093, 0.000391479, -0.037640031, 0.000979937, -0.001079042],
                        [0.025480155, 0.020169585, 0.000121341, -0.004429789, 0.000166472, -0.00036447],
                        [0.379003189, 0.014195012, 0.0000821046, -0.008894061, 0.000151519, -0.000210299],
                        [0.690404655, 0.00616619, 0.000137643, -0.009350199, 0.000153427, -0.000213258]]
    hEAT_CAP_FFLOW_SPEC = [[1, 0, 0]] * number_Speeds
    hEAT_EIR_FFLOW_SPEC = [[1, 0, 0]] * number_Speeds

    static = UnitConversions.convert(0.5,"inH2O","Pa") # Pascal

    # Cooling Coil
    hpRatedAirFlowRateCooling = 315.8 # cfm
    cFM_TON_Rated = HVAC.calc_cfm_ton_rated(hpRatedAirFlowRateCooling, hpFanspeedRatioCooling, hpCapacityRatio)
    coolingEIR = HVAC.calc_cooling_eir(number_Speeds, hpCoolingEER, hpSupplyFanPowerRated)
    sHR_Rated_Gross = HVAC.calc_shr_rated_gross(number_Speeds, hpSHRRated, hpSupplyFanPowerRated, cFM_TON_Rated)
    cOOL_CLOSS_FPLR_SPEC = [HVAC.calc_plr_coefficients_cooling(number_Speeds, hpCoolingInstalledSEER)] * number_Speeds

    # Heating Coil
    hpRatedAirFlowRateHeating = 296.9 # cfm
    cFM_TON_Rated_Heat = HVAC.calc_cfm_ton_rated(hpRatedAirFlowRateHeating, hpFanspeedRatioHeating, hpCapacityRatio)
    heatingEIR = HVAC.calc_heating_eir(number_Speeds, hpHeatingCOP, hpSupplyFanPowerRated)
    hEAT_CLOSS_FPLR_SPEC = [HVAC.calc_plr_coefficients_heating(number_Speeds, hpHeatingInstalledHSPF)] * number_Speeds
    
    # Heating defrost curve for reverse cycle
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
      HVAC.get_control_and_slave_zones(thermal_zones).each do |control_zone, slave_zones|
        ([control_zone] + slave_zones).each do |zone|
          HVAC.remove_hvac_equipment(model, runner, zone, unit,
                                     Constants.ObjectNameAirSourceHeatPump)
        end
<<<<<<< HEAD
        
        supp_htg_coil = OpenStudio::Model::CoilHeatingElectric.new(model, model.alwaysOnDiscreteSchedule)
        supp_htg_coil.setName(obj_name + " supp heater")
        supp_htg_coil.setEfficiency(dse * supplementalEfficiency)
        if supplementalOutputCapacity != Constants.SizingAuto
          supp_htg_coil.setNominalCapacity(UnitConversions.convert(supplementalOutputCapacity,"Btu/hr","W")) # Used by HVACSizing measure
        end
        
        # _processCurvesDXCooling

        clg_coil_stage_data = HVAC.calc_coil_stage_data_cooling(model, hpOutputCapacity, number_Speeds, coolingEIR, sHR_Rated_Gross, cOOL_CAP_FT_SPEC, cOOL_EIR_FT_SPEC, cOOL_CLOSS_FPLR_SPEC, cOOL_CAP_FFLOW_SPEC, cOOL_EIR_FFLOW_SPEC, dse)
        
        # _processSystemCoolingCoil
        
        clg_coil = OpenStudio::Model::CoilCoolingDXMultiSpeed.new(model)
        clg_coil.setName(obj_name + " cooling coil")
        clg_coil.setCondenserType("AirCooled")
        clg_coil.setApplyPartLoadFractiontoSpeedsGreaterthan1(false)
        clg_coil.setApplyLatentDegradationtoSpeedsGreaterthan1(false)        
        clg_coil.setFuelType("Electricity")
             
        clg_coil_stage_data.each do |stage|
            clg_coil.addStage(stage)
        end   
        
        # _processSystemFan
        
        fan_power_curve = HVAC.create_curve_exponent(model, [0, 1, 3], obj_name + " fan power curve", -100, 100)        
        fan_eff_curve = HVAC.create_curve_cubic(model, [0, 1, 0, 0], obj_name + " fan eff curve", 0, 1, 0.01, 1)
        
        fan = OpenStudio::Model::FanOnOff.new(model, model.alwaysOnDiscreteSchedule, fan_power_curve, fan_eff_curve)
        fan.setName(obj_name + " supply fan")
        fan.setEndUseSubcategory(Constants.EndUseHVACFan)
        fan.setFanEfficiency(dse * HVAC.calculate_fan_efficiency(static, hpSupplyFanPowerInstalled))
        fan.setPressureRise(static)
        fan.setMotorEfficiency(dse * 1.0)
        fan.setMotorInAirstreamFraction(1.0)    
        
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
        air_loop_unitary.setMaximumSupplyAirTemperature(UnitConversions.convert(170.0,"F","C")) # higher temp for supplemental heat as to not severely limit its use, resulting in unmet hours.
        air_loop_unitary.setMaximumOutdoorDryBulbTemperatureforSupplementalHeaterOperation(UnitConversions.convert(40.0,"F","C"))
        air_loop_unitary.setSupplyAirFlowRateWhenNoCoolingorHeatingisRequired(0)
          
        perf = OpenStudio::Model::UnitarySystemPerformanceMultispeed.new(model)
        air_loop_unitary.setDesignSpecificationMultispeedObject(perf)
        perf.setSingleModeOperation(false)
        for speed in 1..number_Speeds
          f = OpenStudio::Model::SupplyAirflowRatioField.new(hpFanspeedRatioHeating[speed-1], hpFanspeedRatioCooling[speed-1])
          perf.addSupplyAirflowRatioField(f)
        end
        
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

        HVAC.prioritize_zone_hvac(model, runner, control_zone)
        
        slave_zones.each do |slave_zone|

          # Remove existing equipment
          HVAC.remove_existing_hvac_equipment(model, runner, Constants.ObjectNameAirSourceHeatPump, slave_zone, false, unit)
      
          diffuser_fbsmt = OpenStudio::Model::AirTerminalSingleDuctUncontrolled.new(model, model.alwaysOnDiscreteSchedule)
          diffuser_fbsmt.setName(obj_name + " #{slave_zone.name} direct air")
          air_loop.addBranchForZone(slave_zone, diffuser_fbsmt.to_StraightComponent)

          air_loop.addBranchForZone(slave_zone)
          runner.registerInfo("Added '#{air_loop.name}' to '#{slave_zone.name}' of #{unit.name}")

          HVAC.prioritize_zone_hvac(model, runner, slave_zone)
          
        end # slave_zone
      
      end # control_zone
=======
      end
>>>>>>> master
      
      success = HVAC.apply_central_ashp_4speed(model, unit, runner, seer, hspf, eers, cops, shrs,
                                               capacity_ratios, fan_speed_ratios_cooling,
                                               fan_speed_ratios_heating,
                                               fan_power_rated, fan_power_installed, min_temp,
                                               crankcase_capacity, crankcase_temp,
                                               eer_capacity_derates, cop_capacity_derates,
                                               heat_pump_capacity, supplemental_efficiency,
                                               supplemental_capacity, dse)
      return false if not success
      
    end # unit

    return true
 
  end #end the run method
  
end #end the measure

#this allows the measure to be use by the application
ProcessVariableSpeedAirSourceHeatPump.new.registerWithApplication