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
class ProcessSingleSpeedAirSourceHeatPump < OpenStudio::Measure::ModelMeasure

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Residential Single-Speed Air Source Heat Pump"
  end
  
  def description
    return "This measure removes any existing HVAC components from the building and adds a single-speed air source heat pump along with an on/off supply fan to a unitary air loop. For multifamily buildings, the single-speed air source heat pump can be set for all units of the building.#{Constants.WorkflowDescription}"
  end
  
  def modeler_description
    return "Any supply components or baseboard convective electrics/waters are removed from any existing air/plant loops or zones. Any existing air/plant loops are also removed. A heating DX coil, cooling DX coil, electric supplemental heating coil, and an on/off supply fan are added to a unitary air loop. The unitary air loop is added to the supply inlet node of the air loop. This air loop is added to a branch for the living zone. A diffuser is added to the branch for the living zone as well as for the finished basement if it exists."
  end   
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    #make a string argument for ashp installed seer
    ashpInstalledSEER = OpenStudio::Measure::OSArgument::makeDoubleArgument("seer", true)
    ashpInstalledSEER.setDisplayName("Installed SEER")
    ashpInstalledSEER.setUnits("Btu/W-h")
    ashpInstalledSEER.setDescription("The installed Seasonal Energy Efficiency Ratio (SEER) of the heat pump.")
    ashpInstalledSEER.setDefaultValue(13.0)
    args << ashpInstalledSEER
    
    #make a string argument for ashp installed hspf
    ashpInstalledHSPF = OpenStudio::Measure::OSArgument::makeDoubleArgument("hspf", true)
    ashpInstalledHSPF.setDisplayName("Installed HSPF")
    ashpInstalledHSPF.setUnits("Btu/W-h")
    ashpInstalledHSPF.setDescription("The installed Heating Seasonal Performance Factor (HSPF) of the heat pump.")
    ashpInstalledHSPF.setDefaultValue(7.7)
    args << ashpInstalledHSPF

    #make a double argument for ashp eer
    ashpEER = OpenStudio::Measure::OSArgument::makeDoubleArgument("eer", true)
    ashpEER.setDisplayName("EER")
    ashpEER.setUnits("kBtu/kWh")
    ashpEER.setDescription("EER (net) from the A test (95 ODB/80 EDB/67 EWB).")
    ashpEER.setDefaultValue(11.4)
    args << ashpEER
    
    #make a double argument for ashp cop
    ashpCOP = OpenStudio::Measure::OSArgument::makeDoubleArgument("cop", true)
    ashpCOP.setDisplayName("COP")
    ashpCOP.setUnits("Wh/Wh")
    ashpCOP.setDescription("COP (net) at 47 ODB/70 EDB/60 EWB (AHRI rated conditions).")
    ashpCOP.setDefaultValue(3.05)
    args << ashpCOP    
    
    #make a double argument for ashp rated shr
    ashpSHRRated = OpenStudio::Measure::OSArgument::makeDoubleArgument("shr", true)
    ashpSHRRated.setDisplayName("Rated SHR")
    ashpSHRRated.setDescription("The sensible heat ratio (ratio of the sensible portion of the load to the total load) at the nominal rated capacity.")
    ashpSHRRated.setDefaultValue(0.73)
    args << ashpSHRRated

    #make a double argument for ashp rated supply fan power
    ashpSupplyFanPowerRated = OpenStudio::Measure::OSArgument::makeDoubleArgument("fan_power_rated", true)
    ashpSupplyFanPowerRated.setDisplayName("Rated Supply Fan Power")
    ashpSupplyFanPowerRated.setUnits("W/cfm")
    ashpSupplyFanPowerRated.setDescription("Fan power (in W) per delivered airflow rate (in cfm) of the outdoor fan under conditions prescribed by AHRI Standard 210/240 for SEER testing.")
    ashpSupplyFanPowerRated.setDefaultValue(0.365)
    args << ashpSupplyFanPowerRated
    
    #make a double argument for ashp installed supply fan power
    ashpSupplyFanPowerInstalled = OpenStudio::Measure::OSArgument::makeDoubleArgument("fan_power_installed", true)
    ashpSupplyFanPowerInstalled.setDisplayName("Installed Supply Fan Power")
    ashpSupplyFanPowerInstalled.setUnits("W/cfm")
    ashpSupplyFanPowerInstalled.setDescription("Fan power (in W) per delivered airflow rate (in cfm) of the outdoor fan for the maximum fan speed under actual operating conditions.")
    ashpSupplyFanPowerInstalled.setDefaultValue(0.5)
    args << ashpSupplyFanPowerInstalled    
    
    #make a double argument for ashp min t
    ashpMinTemp = OpenStudio::Measure::OSArgument::makeDoubleArgument("min_temp", true)
    ashpMinTemp.setDisplayName("Min Temp")
    ashpMinTemp.setUnits("degrees F")
    ashpMinTemp.setDescription("Outdoor dry-bulb temperature below which compressor turns off.")
    ashpMinTemp.setDefaultValue(0.0)
    args << ashpMinTemp  
  
    #make a double argument for central ac crankcase
    ashpCrankcase = OpenStudio::Measure::OSArgument::makeDoubleArgument("crankcase_capacity", true)
    ashpCrankcase.setDisplayName("Crankcase")
    ashpCrankcase.setUnits("kW")
    ashpCrankcase.setDescription("Capacity of the crankcase heater for the compressor.")
    ashpCrankcase.setDefaultValue(0.02)
    args << ashpCrankcase

    #make a double argument for ashp crankcase max t
    ashpCrankcaseMaxT = OpenStudio::Measure::OSArgument::makeDoubleArgument("crankcase_max_temp", true)
    ashpCrankcaseMaxT.setDisplayName("Crankcase Max Temp")
    ashpCrankcaseMaxT.setUnits("degrees F")
    ashpCrankcaseMaxT.setDescription("Outdoor dry-bulb temperature above which compressor crankcase heating is disabled.")
    ashpCrankcaseMaxT.setDefaultValue(55.0)
    args << ashpCrankcaseMaxT
    
    #make a double argument for ashp 1.5 ton eer capacity derate
    ashpEERCapacityDerateFactor1ton = OpenStudio::Measure::OSArgument::makeDoubleArgument("eer_capacity_derate_1ton", true)
    ashpEERCapacityDerateFactor1ton.setDisplayName("1.5 Ton EER Capacity Derate")
    ashpEERCapacityDerateFactor1ton.setDescription("EER multiplier for 1.5 ton air-conditioners.")
    ashpEERCapacityDerateFactor1ton.setDefaultValue(1.0)
    args << ashpEERCapacityDerateFactor1ton
    
    #make a double argument for central ac 2 ton eer capacity derate
    ashpEERCapacityDerateFactor2ton = OpenStudio::Measure::OSArgument::makeDoubleArgument("eer_capacity_derate_2ton", true)
    ashpEERCapacityDerateFactor2ton.setDisplayName("2 Ton EER Capacity Derate")
    ashpEERCapacityDerateFactor2ton.setDescription("EER multiplier for 2 ton air-conditioners.")
    ashpEERCapacityDerateFactor2ton.setDefaultValue(1.0)
    args << ashpEERCapacityDerateFactor2ton

    #make a double argument for central ac 3 ton eer capacity derate
    ashpEERCapacityDerateFactor3ton = OpenStudio::Measure::OSArgument::makeDoubleArgument("eer_capacity_derate_3ton", true)
    ashpEERCapacityDerateFactor3ton.setDisplayName("3 Ton EER Capacity Derate")
    ashpEERCapacityDerateFactor3ton.setDescription("EER multiplier for 3 ton air-conditioners.")
    ashpEERCapacityDerateFactor3ton.setDefaultValue(1.0)
    args << ashpEERCapacityDerateFactor3ton

    #make a double argument for central ac 4 ton eer capacity derate
    ashpEERCapacityDerateFactor4ton = OpenStudio::Measure::OSArgument::makeDoubleArgument("eer_capacity_derate_4ton", true)
    ashpEERCapacityDerateFactor4ton.setDisplayName("4 Ton EER Capacity Derate")
    ashpEERCapacityDerateFactor4ton.setDescription("EER multiplier for 4 ton air-conditioners.")
    ashpEERCapacityDerateFactor4ton.setDefaultValue(1.0)
    args << ashpEERCapacityDerateFactor4ton

    #make a double argument for central ac 5 ton eer capacity derate
    ashpEERCapacityDerateFactor5ton = OpenStudio::Measure::OSArgument::makeDoubleArgument("eer_capacity_derate_5ton", true)
    ashpEERCapacityDerateFactor5ton.setDisplayName("5 Ton EER Capacity Derate")
    ashpEERCapacityDerateFactor5ton.setDescription("EER multiplier for 5 ton air-conditioners.")
    ashpEERCapacityDerateFactor5ton.setDefaultValue(1.0)
    args << ashpEERCapacityDerateFactor5ton
    
    #make a double argument for ashp 1.5 ton cop capacity derate
    ashpCOPCapacityDerateFactor1ton = OpenStudio::Measure::OSArgument::makeDoubleArgument("cop_capacity_derate_1ton", true)
    ashpCOPCapacityDerateFactor1ton.setDisplayName("1.5 Ton COP Capacity Derate")
    ashpCOPCapacityDerateFactor1ton.setDescription("COP multiplier for 1.5 ton air-conditioners.")
    ashpCOPCapacityDerateFactor1ton.setDefaultValue(1.0)
    args << ashpCOPCapacityDerateFactor1ton
    
    #make a double argument for ashp 2 ton cop capacity derate
    ashpCOPCapacityDerateFactor2ton = OpenStudio::Measure::OSArgument::makeDoubleArgument("cop_capacity_derate_2ton", true)
    ashpCOPCapacityDerateFactor2ton.setDisplayName("2 Ton COP Capacity Derate")
    ashpCOPCapacityDerateFactor2ton.setDescription("COP multiplier for 2 ton air-conditioners.")
    ashpCOPCapacityDerateFactor2ton.setDefaultValue(1.0)
    args << ashpCOPCapacityDerateFactor2ton

    #make a double argument for ashp 3 ton cop capacity derate
    ashpCOPCapacityDerateFactor3ton = OpenStudio::Measure::OSArgument::makeDoubleArgument("cop_capacity_derate_3ton", true)
    ashpCOPCapacityDerateFactor3ton.setDisplayName("3 Ton COP Capacity Derate")
    ashpCOPCapacityDerateFactor3ton.setDescription("COP multiplier for 3 ton air-conditioners.")
    ashpCOPCapacityDerateFactor3ton.setDefaultValue(1.0)
    args << ashpCOPCapacityDerateFactor3ton

    #make a double argument for ashp 4 ton cop capacity derate
    ashpCOPCapacityDerateFactor4ton = OpenStudio::Measure::OSArgument::makeDoubleArgument("cop_capacity_derate_4ton", true)
    ashpCOPCapacityDerateFactor4ton.setDisplayName("4 Ton COP Capacity Derate")
    ashpCOPCapacityDerateFactor4ton.setDescription("COP multiplier for 4 ton air-conditioners.")
    ashpCOPCapacityDerateFactor4ton.setDefaultValue(1.0)
    args << ashpCOPCapacityDerateFactor4ton

    #make a double argument for ashp 5 ton cop capacity derate
    ashpCOPCapacityDerateFactor5ton = OpenStudio::Measure::OSArgument::makeDoubleArgument("cop_capacity_derate_5ton", true)
    ashpCOPCapacityDerateFactor5ton.setDisplayName("5 Ton COP Capacity Derate")
    ashpCOPCapacityDerateFactor5ton.setDescription("COP multiplier for 5 ton air-conditioners.")
    ashpCOPCapacityDerateFactor5ton.setDefaultValue(1.0)
    args << ashpCOPCapacityDerateFactor5ton    
    
    #make a string argument for ashp cooling/heating output capacity
    hpcap = OpenStudio::Measure::OSArgument::makeStringArgument("heat_pump_capacity", true)
    hpcap.setDisplayName("Heat Pump Capacity")
    hpcap.setDescription("The output heating/cooling capacity of the heat pump. If using '#{Constants.SizingAuto}', the autosizing algorithm will use ACCA Manual S to set the heat pump capacity based on the cooling load. If using '#{Constants.SizingAutoMaxLoad}', the autosizing algorithm will override ACCA Manual S and use the maximum of the heating and cooling loads to set the heat pump capacity, based on the heating/cooling capacities under design conditions.")
    hpcap.setUnits("tons")
    hpcap.setDefaultValue(Constants.SizingAuto)
    args << hpcap

    #make an argument for entering supplemental efficiency
    supp_eff = OpenStudio::Measure::OSArgument::makeDoubleArgument("supplemental_efficiency",true)
    supp_eff.setDisplayName("Supplemental Efficiency")
    supp_eff.setUnits("Btu/Btu")
    supp_eff.setDescription("The efficiency of the supplemental electric coil.")
    supp_eff.setDefaultValue(1.0)
    args << supp_eff
    
    #make a string argument for supplemental heating output capacity
    supcap = OpenStudio::Measure::OSArgument::makeStringArgument("supplemental_capacity", true)
    supcap.setDisplayName("Supplemental Heating Capacity")
    supcap.setDescription("The output heating capacity of the supplemental heater. If using '#{Constants.SizingAuto}', the autosizing algorithm will use ACCA Manual S to set the heat pump supplemental heating capacity.")
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
    hpCoolingEER = [runner.getDoubleArgumentValue("eer",user_arguments)]
    hpHeatingCOP = [runner.getDoubleArgumentValue("cop",user_arguments)]
    hpSHRRated = [runner.getDoubleArgumentValue("shr",user_arguments)]
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
    unless hpOutputCapacity == Constants.SizingAuto or hpOutputCapacity == Constants.SizingAutoMaxLoad
      hpOutputCapacity = OpenStudio::convert(hpOutputCapacity.to_f,"ton","Btu/h").get
    end
    supplementalEfficiency = runner.getDoubleArgumentValue("supplemental_efficiency",user_arguments)
    supplementalOutputCapacity = runner.getStringArgumentValue("supplemental_capacity",user_arguments)
    unless supplementalOutputCapacity == Constants.SizingAuto
      supplementalOutputCapacity = OpenStudio::convert(supplementalOutputCapacity.to_f,"kBtu/h","Btu/h").get
    end
    
    if hpOutputCapacity == Constants.SizingAutoMaxLoad
        runner.registerWarning("Using #{Constants.SizingAutoMaxLoad} is not recommended for single-speed heat pumps. When sized larger than the cooling load, this can lead to humidity concerns due to reduced dehumidification performance by the heat pump.")
    end
    
    number_Speeds = 1
    
    # Performance curves
    
    # NOTE: These coefficients are in IP UNITS
    cOOL_CAP_FT_SPEC = [[3.68637657, -0.098352478, 0.000956357, 0.005838141, -0.0000127, -0.000131702]]
    cOOL_EIR_FT_SPEC = [[-3.437356399, 0.136656369, -0.001049231, -0.0079378, 0.000185435, -0.0001441]]
    cOOL_CAP_FFLOW_SPEC = [[0.718664047, 0.41797409, -0.136638137]]
    cOOL_EIR_FFLOW_SPEC = [[1.143487507, -0.13943972, -0.004047787]]
    hEAT_CAP_FT_SPEC = [[0.566333415, -0.000744164, -0.0000103, 0.009414634, 0.0000506, -0.00000675]]
    hEAT_EIR_FT_SPEC = [[0.718398423, 0.003498178, 0.000142202, -0.005724331, 0.00014085, -0.000215321]]
    hEAT_CAP_FFLOW_SPEC = [[0.694045465, 0.474207981, -0.168253446]]
    hEAT_EIR_FFLOW_SPEC = [[2.185418751, -1.942827919, 0.757409168]]

    static = UnitConversion.inH2O2Pa(0.5) # Pascal

    hpCapacityRatio = [1.0]
    hpFanspeedRatioCooling = [1.0]
    hpFanspeedRatioHeating = [1.0]
    
    # Cooling Coil
    hpRatedAirFlowRateCooling = 394.2 # cfm
    cFM_TON_Rated = HVAC.calc_cfm_ton_rated(hpRatedAirFlowRateCooling, hpFanspeedRatioCooling, hpCapacityRatio)
    coolingEIR = HVAC.calc_cooling_eir(number_Speeds, hpCoolingEER, hpSupplyFanPowerRated)
    sHR_Rated_Gross = HVAC.calc_shr_rated_gross(number_Speeds, hpSHRRated, hpSupplyFanPowerRated, cFM_TON_Rated)
    cOOL_CLOSS_FPLR_SPEC = [HVAC.calc_plr_coefficients_cooling(number_Speeds, hpCoolingInstalledSEER)]

    # Heating Coil
    hpRatedAirFlowRateHeating = 384.1 # cfm
    cFM_TON_Rated_Heat = HVAC.calc_cfm_ton_rated(hpRatedAirFlowRateHeating, hpFanspeedRatioHeating, hpCapacityRatio)
    heatingEIR = HVAC.calc_heating_eir(number_Speeds, hpHeatingCOP, hpSupplyFanPowerRated)
    hEAT_CLOSS_FPLR_SPEC = [HVAC.calc_plr_coefficients_heating(number_Speeds, hpHeatingInstalledHSPF)]
    
    # Heating defrost curve for reverse cycle
    defrost_eir_curve = HVAC.create_curve_biquadratic(model, [0.1528, 0, 0, 0, 0, 0], "DefrostEIR", -100, 100, -100, 100)
    
    # Remove boiler hot water loop if it exists
    HVAC.remove_boiler_and_gshp_loops(model, runner)    
    
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
        HVAC.remove_existing_hvac_equipment(model, runner, Constants.ObjectNameAirSourceHeatPump, control_zone, false, unit)
      
        # _processCurvesDXHeating
        htg_coil_stage_data = HVAC.calc_coil_stage_data_heating(model, hpOutputCapacity, number_Speeds, heatingEIR, hEAT_CAP_FT_SPEC, hEAT_EIR_FT_SPEC, hEAT_CLOSS_FPLR_SPEC, hEAT_CAP_FFLOW_SPEC, hEAT_EIR_FFLOW_SPEC)
      
        # _processSystemHeatingCoil
        
        htg_coil = OpenStudio::Model::CoilHeatingDXSingleSpeed.new(model, model.alwaysOnDiscreteSchedule, htg_coil_stage_data[0].heatingCapacityFunctionofTemperatureCurve, htg_coil_stage_data[0].heatingCapacityFunctionofFlowFractionCurve, htg_coil_stage_data[0].energyInputRatioFunctionofTemperatureCurve, htg_coil_stage_data[0].energyInputRatioFunctionofFlowFractionCurve, htg_coil_stage_data[0].partLoadFractionCorrelationCurve)
        htg_coil_stage_data[0].remove
        htg_coil.setName(obj_name + " heating coil")
        if hpOutputCapacity != Constants.SizingAuto and hpOutputCapacity != Constants.SizingAutoMaxLoad
          htg_coil.setRatedTotalHeatingCapacity(OpenStudio::convert(hpOutputCapacity,"Btu/h","W").get) # Used by HVACSizing measure
        end
        htg_coil.setRatedCOP(1.0 / heatingEIR[0])
        htg_coil.setRatedSupplyFanPowerPerVolumeFlowRate(hpSupplyFanPowerRated / OpenStudio::convert(1.0,"cfm","m^3/s").get)
        htg_coil.setDefrostEnergyInputRatioFunctionofTemperatureCurve(defrost_eir_curve)
        htg_coil.setMinimumOutdoorDryBulbTemperatureforCompressorOperation(OpenStudio::convert(hpMinT,"F","C").get)
        htg_coil.setMaximumOutdoorDryBulbTemperatureforDefrostOperation(OpenStudio::convert(40.0,"F","C").get)
        htg_coil.setCrankcaseHeaterCapacity(OpenStudio::convert(hpCrankcase,"kW","W").get)
        htg_coil.setMaximumOutdoorDryBulbTemperatureforCrankcaseHeaterOperation(OpenStudio::convert(hpCrankcaseMaxT,"F","C").get)
        htg_coil.setDefrostStrategy("ReverseCycle")
        htg_coil.setDefrostControl("OnDemand")
        
        supp_htg_coil = OpenStudio::Model::CoilHeatingElectric.new(model, model.alwaysOnDiscreteSchedule)
        supp_htg_coil.setName(obj_name + " supp heater")
        supp_htg_coil.setEfficiency(supplementalEfficiency)
        if supplementalOutputCapacity != Constants.SizingAuto
          supp_htg_coil.setNominalCapacity(OpenStudio::convert(supplementalOutputCapacity,"Btu/h","W").get) # Used by HVACSizing measure
        end
        
        # _processCurvesDXCooling

        clg_coil_stage_data = HVAC.calc_coil_stage_data_cooling(model, hpOutputCapacity, number_Speeds, coolingEIR, sHR_Rated_Gross, cOOL_CAP_FT_SPEC, cOOL_EIR_FT_SPEC, cOOL_CLOSS_FPLR_SPEC, cOOL_CAP_FFLOW_SPEC, cOOL_EIR_FFLOW_SPEC)
        
        # _processSystemCoolingCoil
        
        clg_coil = OpenStudio::Model::CoilCoolingDXSingleSpeed.new(model, model.alwaysOnDiscreteSchedule, clg_coil_stage_data[0].totalCoolingCapacityFunctionofTemperatureCurve, clg_coil_stage_data[0].totalCoolingCapacityFunctionofFlowFractionCurve, clg_coil_stage_data[0].energyInputRatioFunctionofTemperatureCurve, clg_coil_stage_data[0].energyInputRatioFunctionofFlowFractionCurve, clg_coil_stage_data[0].partLoadFractionCorrelationCurve)
        clg_coil_stage_data[0].remove
        clg_coil.setName(obj_name + " cooling coil")
        if hpOutputCapacity != Constants.SizingAuto and hpOutputCapacity != Constants.SizingAutoMaxLoad
          clg_coil.setRatedTotalCoolingCapacity(OpenStudio::convert(hpOutputCapacity,"Btu/h","W").get) # Used by HVACSizing measure
        end
        clg_coil.setRatedSensibleHeatRatio(sHR_Rated_Gross[0])
        clg_coil.setRatedCOP(OpenStudio::OptionalDouble.new(1.0 / coolingEIR[0]))
        clg_coil.setRatedEvaporatorFanPowerPerVolumeFlowRate(OpenStudio::OptionalDouble.new(hpSupplyFanPowerRated / OpenStudio::convert(1.0,"cfm","m^3/s").get))
        clg_coil.setNominalTimeForCondensateRemovalToBegin(OpenStudio::OptionalDouble.new(1000.0))
        clg_coil.setRatioOfInitialMoistureEvaporationRateAndSteadyStateLatentCapacity(OpenStudio::OptionalDouble.new(1.5))
        clg_coil.setMaximumCyclingRate(OpenStudio::OptionalDouble.new(3.0))
        clg_coil.setLatentCapacityTimeConstant(OpenStudio::OptionalDouble.new(45.0))
        clg_coil.setCondenserType("AirCooled")   
        
        # _processSystemFan

        fan = OpenStudio::Model::FanOnOff.new(model, model.alwaysOnDiscreteSchedule)
        fan.setName(obj_name + " supply fan")
        fan.setEndUseSubcategory(Constants.EndUseHVACFan)
        fan.setFanEfficiency(HVAC.calculate_fan_efficiency(static, hpSupplyFanPowerInstalled))
        fan.setPressureRise(static)
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

        HVAC.prioritize_zone_hvac(model, runner, control_zone).reverse.each do |object|
          control_zone.setCoolingPriority(object, 1)
          control_zone.setHeatingPriority(object, 1)
        end
        
        slave_zones.each do |slave_zone|

          # Remove existing equipment
          HVAC.remove_existing_hvac_equipment(model, runner, Constants.ObjectNameAirSourceHeatPump, slave_zone, false, unit)
      
          diffuser_fbsmt = OpenStudio::Model::AirTerminalSingleDuctUncontrolled.new(model, model.alwaysOnDiscreteSchedule)
          diffuser_fbsmt.setName(obj_name + " #{slave_zone.name} direct air")
          air_loop.addBranchForZone(slave_zone, diffuser_fbsmt.to_StraightComponent)

          air_loop.addBranchForZone(slave_zone)
          runner.registerInfo("Added '#{air_loop.name}' to '#{slave_zone.name}' of #{unit.name}")

          HVAC.prioritize_zone_hvac(model, runner, slave_zone).reverse.each do |object|
            slave_zone.setCoolingPriority(object, 1)
            slave_zone.setHeatingPriority(object, 1)
          end
          
        end # slave_zone
      
      end # control_zone
      
      # Store info for HVAC Sizing measure
      unit.setFeature(Constants.SizingInfoHVACCapacityDerateFactorEER, hpEERCapacityDerateFactor.join(","))
      unit.setFeature(Constants.SizingInfoHVACCapacityDerateFactorCOP, hpCOPCapacityDerateFactor.join(","))
      unit.setFeature(Constants.SizingInfoHPSizedForMaxLoad, (hpOutputCapacity == Constants.SizingAutoMaxLoad))
      unit.setFeature(Constants.SizingInfoHVACRatedCFMperTonHeating, cFM_TON_Rated_Heat.join(","))
      unit.setFeature(Constants.SizingInfoHVACRatedCFMperTonCooling, cFM_TON_Rated.join(","))
    
    end # unit

    return true
 
  end #end the run method
  
end #end the measure

#this allows the measure to be use by the application
ProcessSingleSpeedAirSourceHeatPump.new.registerWithApplication