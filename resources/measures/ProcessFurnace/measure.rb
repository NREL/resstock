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
class ProcessFurnace < OpenStudio::Ruleset::ModelUserScript

  class Furnace
    def initialize(furnaceInstalledAFUE, furnaceMaxSupplyTemp, furnaceFuelType, furnaceInstalledSupplyFanPower)
      @furnaceInstalledAFUE = furnaceInstalledAFUE
      @furnaceMaxSupplyTemp = furnaceMaxSupplyTemp
      @furnaceFuelType = furnaceFuelType
      @furnaceInstalledSupplyFanPower = furnaceInstalledSupplyFanPower
    end

    attr_accessor(:hir, :aux_elec)

    def FurnaceInstalledAFUE
      return @furnaceInstalledAFUE
    end

    def FurnaceMaxSupplyTemp
      return @furnaceMaxSupplyTemp
    end

    def FurnaceFuelType
      return @furnaceFuelType
    end
	
    def FurnaceSupplyFanPowerInstalled
      return @furnaceInstalledSupplyFanPower
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
    attr_accessor(:static, :cfm_ton, :HPCoolingOversizingFactor, :SpaceConditionedMult, :fan_power, :eff, :min_flow_ratio, :FAN_EIR_FPLR_SPEC_coefficients, :Heat_Capacity, :compressor_speeds, :Zone_Water_Remove_Cap_Ft_DB_RH_Coefficients, :Zone_Energy_Factor_Ft_DB_RH_Coefficients, :Zone_DXDH_PLF_F_PLR_Coefficients, :Number_Speeds, :fanspeed_ratio, :Heat_AirFlowRate, :Cool_AirFlowRate, :Fan_AirFlowRate, :htg_supply_air_temp)
  end

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Residential Furnace"
  end
  
  def description
    return "This measure removes any existing HVAC heating components from the building and adds a furnace along with an on/off supply fan to a unitary air loop."
  end
  
  def modeler_description
    return "Any heating components or baseboard convective electrics/waters are removed from any existing air/plant loops or zones. Any existing air/plant loops are also removed. An electric or gas heating coil and an on/off supply fan are added to a unitary air loop. The unitary air loop is added to the supply inlet node of the air loop. This air loop is added to a branch for the living zone. A diffuser is added to the branch for the living zone as well as for the finished basement if it exists."
  end   
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make a choice argument for furnace fuel type
    fuel_display_names = OpenStudio::StringVector.new
    fuel_display_names << Constants.FuelTypeGas
    fuel_display_names << Constants.FuelTypeElectric

    #make a string argument for furnace fuel type
    selected_furnacefuel = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedfurnacefuel", fuel_display_names, true)
    selected_furnacefuel.setDisplayName("Fuel Type")
    selected_furnacefuel.setDescription("Type of fuel used for heating.")
    selected_furnacefuel.setDefaultValue(Constants.FuelTypeGas)
    args << selected_furnacefuel
	
    #make an argument for entering furnace installed afue
    userdefined_afue = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedafue",true)
    userdefined_afue.setDisplayName("Installed AFUE")
    userdefined_afue.setUnits("Btu/Btu")
    userdefined_afue.setDescription("The installed Annual Fuel Utilization Efficiency (AFUE) of the furnace, which can be used to account for performance derating or degradation relative to the rated value.")
    userdefined_afue.setDefaultValue(0.78)
    args << userdefined_afue

    #make a choice argument for furnace heating output capacity
    cap_display_names = OpenStudio::StringVector.new
    cap_display_names << Constants.SizingAuto
    (5..150).step(5) do |kbtu|
      cap_display_names << "#{kbtu} kBtu/hr"
    end

    #make a string argument for furnace heating output capacity
    selected_furnacecap = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedfurnacecap", cap_display_names, true)
    selected_furnacecap.setDisplayName("Heating Output Capacity")
    selected_furnacecap.setDefaultValue(Constants.SizingAuto)
    args << selected_furnacecap

    #make an argument for entering furnace max supply temp
    userdefined_maxtemp = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedmaxtemp",true)
    userdefined_maxtemp.setDisplayName("Max Supply Temp")
	  userdefined_maxtemp.setUnits("F")
	  userdefined_maxtemp.setDescription("Maximum supply air temperature.")
    userdefined_maxtemp.setDefaultValue(120.0)
    args << userdefined_maxtemp

    #make an argument for entering furnace installed supply fan power
    userdefined_fanpower = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedfanpower",true)
    userdefined_fanpower.setDisplayName("Installed Supply Fan Power")
    userdefined_fanpower.setUnits("W/cfm")
    userdefined_fanpower.setDescription("Fan power (in W) per delivered airflow rate (in cfm) of the indoor fan for the maximum fan speed under actual operating conditions.")
    userdefined_fanpower.setDefaultValue(0.5)
    args << userdefined_fanpower	
	
    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end
	
    furnaceFuelType = runner.getStringArgumentValue("selectedfurnacefuel",user_arguments)
    furnaceInstalledAFUE = runner.getDoubleArgumentValue("userdefinedafue",user_arguments)
    furnaceOutputCapacity = runner.getStringArgumentValue("selectedfurnacecap",user_arguments)
    if not furnaceOutputCapacity == Constants.SizingAuto
      furnaceOutputCapacity = OpenStudio::convert(furnaceOutputCapacity.split(" ")[0].to_f,"kBtu/h","Btu/h").get
    end
    furnaceMaxSupplyTemp = runner.getDoubleArgumentValue("userdefinedmaxtemp",user_arguments)
    furnaceInstalledSupplyFanPower = runner.getDoubleArgumentValue("userdefinedfanpower",user_arguments) 
    
    # Create the material class instances
    furnace = Furnace.new(furnaceInstalledAFUE, furnaceMaxSupplyTemp, furnaceFuelType, furnaceInstalledSupplyFanPower)
    air_conditioner = AirConditioner.new(nil)
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

    # Before we allowed systems with no cooling equipment, the system
    # fan was defined by the cooling equipment option. For systems
    # with only a furnace, the system fan is (for the time being) hard
    # coded here.

    supply.fan_power = furnace.FurnaceSupplyFanPowerInstalled # Based on 2010 BA Benchmark
    supply.eff = OpenStudio::convert(supply.static / supply.fan_power,"cfm","m^3/s").get # Overall Efficiency of the Supply Fan, Motor and Drive
    # self.supply.delta_t = 0.00055000 / units.Btu2kWh(1.0) / (self.mat.air.inside_air_dens * self.mat.air.inside_air_sh * units.hr2min(1.0))
    supply.min_flow_ratio = 1.00000000
    supply.FAN_EIR_FPLR_SPEC_coefficients = [0.00000000, 1.00000000, 0.00000000, 0.00000000]

    supply.htg_supply_air_temp = furnace.FurnaceMaxSupplyTemp

    furnace.hir = get_furnace_hir(furnace.FurnaceInstalledAFUE)

    # Parasitic Electricity (Source: DOE. (2007). Technical Support Document: Energy Efficiency Program for Consumer Products: "Energy Conservation Standards for Residential Furnaces and Boilers". www.eere.energy.gov/buildings/appliance_standards/residential/furnaces_boilers.html)
    #             FurnaceParasiticElecDict = {Constants.FuelTypeGas     :  76, # W during operation
    #                                         Constants.FuelTypeOil     : 220}
    #             f.aux_elec = FurnaceParasiticElecDict[f.FurnaceFuelType]
    furnace.aux_elec = 0.0 # set to zero until we figure out a way to distribute to the correct end uses (DOE-2 limitation?)    

    supply.compressor_speeds = nil   
    
    # Check if has equipment
    HelperMethods.remove_hot_water_loop(model, runner)    

    control_slave_zones_hash = Geometry.get_control_and_slave_zones(model)
    control_slave_zones_hash.each do |control_zone, slave_zones|
    
      # Remove existing equipment
      clg_coil = HelperMethods.remove_existing_hvac_equipment(model, runner, "Furnace", control_zone)
    
      # _processSystemHeatingCoil
      
      if furnace.FurnaceFuelType == Constants.FuelTypeElectric

        htg_coil = OpenStudio::Model::CoilHeatingElectric.new(model)
        htg_coil.setName("Furnace Heating Coil")
        htg_coil.setEfficiency(1.0 / furnace.hir)
        if furnaceOutputCapacity != Constants.SizingAuto
          htg_coil.setNominalCapacity(OpenStudio::convert(furnaceOutputCapacity,"Btu/h","W").get)
        end

      elsif furnace.FurnaceFuelType != Constants.FuelTypeElectric

        htg_coil = OpenStudio::Model::CoilHeatingGas.new(model)
        htg_coil.setName("Furnace Heating Coil")
        htg_coil.setGasBurnerEfficiency(1.0 / furnace.hir)
        if furnaceOutputCapacity != Constants.SizingAuto
          htg_coil.setNominalCapacity(OpenStudio::convert(furnaceOutputCapacity,"Btu/h","W").get)
        end

        htg_coil.setParasiticElectricLoad(furnace.aux_elec) # set to zero until we figure out a way to distribute to the correct end uses (DOE-2 limitation?)
        htg_coil.setParasiticGasLoad(0)

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
      
      air_loop_unitary = OpenStudio::Model::AirLoopHVACUnitarySystem.new(model)
      air_loop_unitary.setName("Forced Air System")
      air_loop_unitary.setAvailabilitySchedule(model.alwaysOnDiscreteSchedule)
      air_loop_unitary.setHeatingCoil(htg_coil)
      if not clg_coil.nil?
        # Add the existing DX central air back in
        air_loop_unitary.setCoolingCoil(clg_coil)
      else
        air_loop_unitary.setSupplyAirFlowRateDuringCoolingOperation(0.0000001) # this is when there is no cooling present
      end
      air_loop_unitary.setSupplyFan(fan)
      air_loop_unitary.setFanPlacement("BlowThrough")
      air_loop_unitary.setSupplyAirFanOperatingModeSchedule(supply_fan_operation)
      air_loop_unitary.setMaximumSupplyAirTemperature(OpenStudio::convert(supply.htg_supply_air_temp,"F","C").get)      
      air_loop_unitary.setSupplyAirFlowRateWhenNoCoolingorHeatingisRequired(0)      

      air_loop = OpenStudio::Model::AirLoopHVAC.new(model)
      air_loop.setName("Central Air System")
      air_supply_inlet_node = air_loop.supplyInletNode
      air_supply_outlet_node = air_loop.supplyOutletNode
      air_demand_inlet_node = air_loop.demandInletNode
      air_demand_outlet_node = air_loop.demandOutletNode

      air_loop_unitary.addToNode(air_supply_inlet_node)

      runner.registerInfo("Added on/off fan '#{fan.name}' to branch '#{air_loop_unitary.name}' of air loop '#{air_loop.name}'")
      runner.registerInfo("Added heating coil '#{htg_coil.name}' to branch '#{air_loop_unitary.name}' of air loop '#{air_loop.name}'")
      unless clg_coil.nil?
        runner.registerInfo("Added cooling coil '#{clg_coil.name}' to branch '#{air_loop_unitary.name}' of air loop '#{air_loop.name}'")
      end

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
      
        # Remove existing equipment
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

  def get_furnace_hir(furnaceInstalledAFUE)
    # Based on DOE2 Volume 5 Compliance Analysis manual.
    # This is not used until we have a better way of disaggregating AFUE
    # if FurnaceInstalledAFUE <= 0.835:
    #     hir = 1 / (0.2907 * FurnaceInstalledAFUE + 0.5787)
    # else:
    #     hir = 1 / (1.1116 * FurnaceInstalledAFUE - 0.098185)

    hir = 1.0 / furnaceInstalledAFUE
    return hir
  end  
  
end #end the measure

#this allows the measure to be use by the application
ProcessFurnace.new.registerWithApplication