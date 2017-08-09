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
class ProcessFurnaceElectric < OpenStudio::Measure::ModelMeasure

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Residential Furnace Electric"
  end
  
  def description
    return "This measure removes any existing HVAC heating components from the building and adds a furnace along with an on/off supply fan to a unitary air loop. For multifamily buildings, the furnace can be set for all units of the building.#{Constants.WorkflowDescription}"
  end
  
  def modeler_description
    return "Any heating components or baseboard convective electrics/waters are removed from any existing air/plant loops or zones. Any existing air/plant loops are also removed. An electric heating coil and an on/off supply fan are added to a unitary air loop. The unitary air loop is added to the supply inlet node of the air loop. This air loop is added to a branch for the living zone. A diffuser is added to the branch for the living zone as well as for the finished basement if it exists."
  end   
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new
    
    #make an argument for entering furnace installed afue
    afue = OpenStudio::Measure::OSArgument::makeDoubleArgument("afue",true)
    afue.setDisplayName("Installed AFUE")
    afue.setUnits("Btu/Btu")
    afue.setDescription("The installed Annual Fuel Utilization Efficiency (AFUE) of the furnace, which can be used to account for performance derating or degradation relative to the rated value.")
    afue.setDefaultValue(1.0)
    args << afue

    #make an argument for entering furnace installed supply fan power
    fanpower = OpenStudio::Measure::OSArgument::makeDoubleArgument("fan_power_installed",true)
    fanpower.setDisplayName("Installed Supply Fan Power")
    fanpower.setUnits("W/cfm")
    fanpower.setDescription("Fan power (in W) per delivered airflow rate (in cfm) of the indoor fan for the maximum fan speed under actual operating conditions.")
    fanpower.setDefaultValue(0.5)
    args << fanpower    
    
    #make a string argument for furnace heating output capacity
    furnacecap = OpenStudio::Measure::OSArgument::makeStringArgument("capacity", true)
    furnacecap.setDisplayName("Heating Capacity")
    furnacecap.setDescription("The output heating capacity of the furnace. If using '#{Constants.SizingAuto}', the autosizing algorithm will use ACCA Manual S to set the capacity.")
    furnacecap.setUnits("kBtu/hr")
    furnacecap.setDefaultValue(Constants.SizingAuto)
    args << furnacecap
    
    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end
    
    furnaceInstalledAFUE = runner.getDoubleArgumentValue("afue",user_arguments)
    furnaceOutputCapacity = runner.getStringArgumentValue("capacity",user_arguments)
    if not furnaceOutputCapacity == Constants.SizingAuto
      furnaceOutputCapacity = OpenStudio::convert(furnaceOutputCapacity.to_f,"kBtu/h","Btu/h").get
    end
    furnaceInstalledSupplyFanPower = runner.getDoubleArgumentValue("fan_power_installed",user_arguments)
    
    # _processAirSystem
    
    static = UnitConversion.inH2O2Pa(0.5) # Pascal

    hir = HVAC.get_furnace_hir(furnaceInstalledAFUE)

    # Parasitic Electricity (Source: DOE. (2007). Technical Support Document: Energy Efficiency Program for Consumer Products: "Energy Conservation Standards for Residential Furnaces and Boilers". www.eere.energy.gov/buildings/appliance_standards/residential/furnaces_boilers.html)
    #             FurnaceParasiticElecDict = {Constants.FuelTypeGas     :  76, # W during operation
    #                                         Constants.FuelTypeOil     : 220}
    #             aux_elec = FurnaceParasiticElecDict[furnaceFuelType]
    aux_elec = 0.0 # set to zero until we figure out a way to distribute to the correct end uses (DOE-2 limitation?)    

    # Remove boiler hot water loop if it exists
    HVAC.remove_boiler_and_gshp_loops(model, runner)    

    # Get building units
    units = Geometry.get_building_units(model, runner)
    if units.nil?
        return false
    end
    
    units.each do |unit|
      
      obj_name = Constants.ObjectNameFurnace(Constants.FuelTypeElectric, unit.name.to_s)
      
      thermal_zones = Geometry.get_thermal_zones_from_spaces(unit.spaces)

      control_slave_zones_hash = HVAC.get_control_and_slave_zones(thermal_zones)
      control_slave_zones_hash.each do |control_zone, slave_zones|
      
        # Remove existing equipment
        clg_coil, perf = HVAC.remove_existing_hvac_equipment(model, runner, Constants.ObjectNameFurnace, control_zone, true)
        
        # _processSystemHeatingCoil
        
        htg_coil = OpenStudio::Model::CoilHeatingElectric.new(model)
        htg_coil.setName(obj_name + " heating coil")
        htg_coil.setEfficiency(1.0 / hir)
        if furnaceOutputCapacity != Constants.SizingAuto
          htg_coil.setNominalCapacity(OpenStudio::convert(furnaceOutputCapacity,"Btu/h","W").get) # Used by HVACSizing measure
        end
        
        # _processSystemFan
        if not clg_coil.nil?
          obj_name = Constants.ObjectNameFurnaceAndCentralAirConditioner(Constants.FuelTypeElectric, unit.name.to_s)
        end
        
        fan = OpenStudio::Model::FanOnOff.new(model, model.alwaysOnDiscreteSchedule)
        fan.setName(obj_name + " supply fan")
        fan.setEndUseSubcategory(Constants.EndUseHVACFan)
        fan.setFanEfficiency(OpenStudio::convert(static / furnaceInstalledSupplyFanPower,"cfm","m^3/s").get) # Overall Efficiency of the Supply Fan, Motor and Drive
        fan.setPressureRise(static)
        fan.setMotorEfficiency(1)
        fan.setMotorInAirstreamFraction(1)
      
        # _processSystemAir
        
        air_loop_unitary = OpenStudio::Model::AirLoopHVACUnitarySystem.new(model)
        air_loop_unitary.setName(obj_name + " unitary system")
        air_loop_unitary.setAvailabilitySchedule(model.alwaysOnDiscreteSchedule)
        air_loop_unitary.setHeatingCoil(htg_coil)
        if not clg_coil.nil?
          # Add the existing DX central air back in
          air_loop_unitary.setCoolingCoil(clg_coil)
        else
          air_loop_unitary.setSupplyAirFlowRateDuringCoolingOperation(0.0000001) # this is when there is no cooling present
        end
        if not perf.nil?
          air_loop_unitary.setDesignSpecificationMultispeedObject(perf)
        end
        air_loop_unitary.setSupplyFan(fan)
        air_loop_unitary.setFanPlacement("BlowThrough")
        air_loop_unitary.setSupplyAirFanOperatingModeSchedule(model.alwaysOffDiscreteSchedule)
        air_loop_unitary.setMaximumSupplyAirTemperature(OpenStudio::convert(120.0,"F","C").get)      
        air_loop_unitary.setSupplyAirFlowRateWhenNoCoolingorHeatingisRequired(0)

        air_loop = OpenStudio::Model::AirLoopHVAC.new(model)
        air_loop.setName(obj_name + " central air system")
        air_supply_inlet_node = air_loop.supplyInletNode
        air_supply_outlet_node = air_loop.supplyOutletNode
        air_demand_inlet_node = air_loop.demandInletNode
        air_demand_outlet_node = air_loop.demandOutletNode

        air_loop_unitary.addToNode(air_supply_inlet_node)

        runner.registerInfo("Added '#{fan.name}' to '#{air_loop_unitary.name}' of '#{air_loop.name}'")
        runner.registerInfo("Added '#{htg_coil.name}' to '#{air_loop_unitary.name}' of '#{air_loop.name}'")
        unless clg_coil.nil?
          runner.registerInfo("Added '#{clg_coil.name}' to '#{air_loop_unitary.name}' of '#{air_loop.name}'")
        end

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
          HVAC.remove_existing_hvac_equipment(model, runner, Constants.ObjectNameFurnace, slave_zone)        
        
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
 
  end #end the run method  
  
end #end the measure

#this allows the measure to be use by the application
ProcessFurnaceElectric.new.registerWithApplication