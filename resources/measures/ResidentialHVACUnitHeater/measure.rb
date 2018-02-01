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
class ProcessUnitHeater < OpenStudio::Measure::ModelMeasure

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Residential Unit Heater"
  end
  
  def description
    return "This measure removes any existing HVAC heating components from the building and adds a unit heater along with an optional on/off fan. For multifamily buildings, the unit heater can be set for all units of the building.#{Constants.WorkflowDescription}"
  end
  
  def modeler_description
    return "Any heating components or baseboard convective electrics/waters are removed from any existing air/plant loops or zones. Any existing air/plant loops are also removed. A unitary system with a fuel heating coil and an optional on/off fan are added to each zone."
  end   
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new
    
    #make a string argument for heater fuel type
    fuel_display_names = OpenStudio::StringVector.new
    fuel_display_names << Constants.FuelTypeGas
    fuel_display_names << Constants.FuelTypeOil
    fuel_display_names << Constants.FuelTypePropane
    fuel_display_names << Constants.FuelTypeWood
    fueltype = OpenStudio::Measure::OSArgument::makeChoiceArgument("fuel_type", fuel_display_names, true)
    fueltype.setDisplayName("Fuel Type")
    fueltype.setDescription("Type of fuel used for heating.")
    fueltype.setDefaultValue(Constants.FuelTypeGas)
    args << fueltype  
    
    #make an argument for entering efficiency
    heatereff = OpenStudio::Measure::OSArgument::makeDoubleArgument("efficiency",true)
    heatereff.setDisplayName("Efficiency")
    heatereff.setUnits("Btu/Btu")
    heatereff.setDescription("The efficiency of the heater.")
    heatereff.setDefaultValue(0.78)
    args << heatereff

    #make an argument for entering fan power
    fanpower = OpenStudio::Measure::OSArgument::makeDoubleArgument("fan_power",true)
    fanpower.setDisplayName("Fan Power")
    fanpower.setUnits("W/cfm")
    fanpower.setDescription("Fan power (in W) per delivered airflow rate (in cfm) of the fan. A value of 0 implies there is no fan.")
    fanpower.setDefaultValue(0.0)
    args << fanpower    
    
    #make an argument for entering airflow rate
    airflow = OpenStudio::Measure::OSArgument::makeDoubleArgument("airflow",true)
    airflow.setDisplayName("Airflow Rate")
    airflow.setUnits("cfm/ton")
    airflow.setDescription("Fan airflow rate as a function of heating capacity. A value of 0 implies there is no fan.")
    airflow.setDefaultValue(0.0)
    args << airflow    
    
    #make a string argument for heating output capacity
    heatercap = OpenStudio::Measure::OSArgument::makeStringArgument("capacity", true)
    heatercap.setDisplayName("Heating Capacity")
    heatercap.setDescription("The output heating capacity of the heater. If using '#{Constants.SizingAuto}', the autosizing algorithm will use ACCA Manual S to set the capacity.")
    heatercap.setUnits("kBtu/hr")
    heatercap.setDefaultValue(Constants.SizingAuto)
    args << heatercap
    
    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end
    
    heaterFuelType = runner.getStringArgumentValue("fuel_type",user_arguments)
    heaterEfficiency = runner.getDoubleArgumentValue("efficiency",user_arguments)
    heaterOutputCapacity = runner.getStringArgumentValue("capacity",user_arguments)
    if not heaterOutputCapacity == Constants.SizingAuto
      heaterOutputCapacity = UnitConversions.convert(heaterOutputCapacity.to_f,"kBtu/hr","Btu/hr")
    end
    heaterFanPower = runner.getDoubleArgumentValue("fan_power",user_arguments)
    heaterAirflow = runner.getDoubleArgumentValue("airflow",user_arguments)
    
    if heaterFanPower > 0 and heaterAirflow == 0
      runner.registerError("If Fan Power > 0, then Airflow Rate cannot be zero.")
      return false
    end
    
    # _processAirSystem
    
    static = UnitConversions.convert(0.5,"inH2O","Pa") # Pascal

    # Remove boiler hot water loop if it exists
    HVAC.remove_boiler_and_gshp_loops(model, runner)    

    # Get building units
    units = Geometry.get_building_units(model, runner)
    if units.nil?
        return false
    end
    
    units.each do |unit|
    
      obj_name = Constants.ObjectNameUnitHeater(heaterFuelType, unit.name.to_s)
    
      thermal_zones = Geometry.get_thermal_zones_from_spaces(unit.spaces)

      control_slave_zones_hash = HVAC.get_control_and_slave_zones(thermal_zones)
      control_slave_zones_hash.each do |control_zone, slave_zones|
      
        ([control_zone] + slave_zones).each do |zone|
      
          # Remove existing equipment
          HVAC.remove_existing_hvac_equipment(model, runner, Constants.ObjectNameUnitHeater, zone, true, unit)
          
          # _processSystemHeatingCoil

          htg_coil = OpenStudio::Model::CoilHeatingGas.new(model)
          htg_coil.setName(obj_name + " heating coil")
          htg_coil.setGasBurnerEfficiency(heaterEfficiency)
          if heaterOutputCapacity != Constants.SizingAuto
            htg_coil.setNominalCapacity(UnitConversions.convert(heaterOutputCapacity,"Btu/hr","W")) # Used by HVACSizing measure
          end
          htg_coil.setParasiticElectricLoad(0.0)
          htg_coil.setParasiticGasLoad(0)
          htg_coil.setFuelType(HelperMethods.eplus_fuel_map(heaterFuelType))
          
          
          fan = OpenStudio::Model::FanOnOff.new(model, model.alwaysOnDiscreteSchedule)
          fan.setName(obj_name + " fan")
          fan.setEndUseSubcategory(Constants.EndUseHVACFan)
          if heaterFanPower > 0
            fan.setFanEfficiency(UnitConversions.convert(static / heaterFanPower,"cfm","m^3/s")) # Overall Efficiency of the Fan, Motor and Drive
            fan.setPressureRise(static)
            fan.setMotorEfficiency(1.0)
            fan.setMotorInAirstreamFraction(1.0)  
          else
            fan.setFanEfficiency(1) # Overall Efficiency of the Fan, Motor and Drive
            fan.setPressureRise(0)
            fan.setMotorEfficiency(1.0)
            fan.setMotorInAirstreamFraction(1.0)  
          end
          
        
          # _processSystemAir
          
          unitary_system = OpenStudio::Model::AirLoopHVACUnitarySystem.new(model)
          unitary_system.setName(obj_name + " unitary system")
          unitary_system.setAvailabilitySchedule(model.alwaysOnDiscreteSchedule)
          unitary_system.setHeatingCoil(htg_coil)
          unitary_system.setSupplyAirFlowRateMethodDuringCoolingOperation("SupplyAirFlowRate")
          unitary_system.setSupplyAirFlowRateDuringCoolingOperation(0.00001)
          unitary_system.setSupplyFan(fan)
          unitary_system.setFanPlacement("BlowThrough")
          unitary_system.setSupplyAirFanOperatingModeSchedule(model.alwaysOffDiscreteSchedule)
          unitary_system.setMaximumSupplyAirTemperature(UnitConversions.convert(120.0,"F","C"))      
          unitary_system.setSupplyAirFlowRateWhenNoCoolingorHeatingisRequired(0)

          #unitary_system.addToNode(air_supply_inlet_node)

          runner.registerInfo("Added '#{fan.name}' to '#{unitary_system.name}''")
          runner.registerInfo("Added '#{htg_coil.name}' to '#{unitary_system.name}'")

          unitary_system.setControllingZoneorThermostatLocation(zone)
          unitary_system.addToThermalZone(zone)

          HVAC.prioritize_zone_hvac(model, runner, zone)
          
        end
      
      end
      
      unit.setFeature(Constants.SizingInfoHVACRatedCFMperTonHeating, heaterAirflow.to_s)
      
    end
    
    return true
 
  end #end the run method  
  
end #end the measure

#this allows the measure to be use by the application
ProcessUnitHeater.new.registerWithApplication