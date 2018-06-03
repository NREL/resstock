# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/unit_conversions"
require "#{File.dirname(__FILE__)}/resources/geometry"
require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/hvac"

# start the measure
class ProcessCentralSystemPTAC < OpenStudio::Measure::ModelMeasure

  # human readable name
  def name
    return "ResidentialHVACCentralSystemPTAC"
  end

  # human readable description
  def description
    return "Adds a central hot water boiler to the model connected to zones through PTAC units."
  end

  # human readable description of modeling approach
  def modeler_description
    return "Adds a hot water boiler with variable-speed pump to a single plant loop. Also adds zone hvac packaged terminal air conditioner objects with coil heating water and single-speed coil dx objects to each zone in the model."
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new
    
    #make a string argument for central boiler fuel type
    central_boiler_fuel_type_names = OpenStudio::StringVector.new
    central_boiler_fuel_type_names << Constants.FuelTypeElectric
    central_boiler_fuel_type_names << Constants.FuelTypeGas
    central_boiler_fuel_type_names << Constants.FuelTypeOil
    central_boiler_fuel_type_names << Constants.FuelTypePropane
    central_boiler_fuel_type = OpenStudio::Measure::OSArgument::makeChoiceArgument("central_boiler_fuel_type", central_boiler_fuel_type_names, true)
    central_boiler_fuel_type.setDisplayName("Central Boiler Fuel Type")
    central_boiler_fuel_type.setDescription("The fuel type of the central boiler used for heating.")
    central_boiler_fuel_type.setDefaultValue(Constants.FuelTypeGas)
    args << central_boiler_fuel_type
    
    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    require "openstudio-standards"

    central_boiler_fuel_type = HelperMethods.eplus_fuel_map(runner.getStringArgumentValue("central_boiler_fuel_type",user_arguments))

    std = Standard.build("90.1-2013")

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
                                     Constants.ObjectNameCentralSystemPTAC)
        end
      end
    end

    hot_water_loop = std.model_get_or_add_hot_water_loop(model, central_boiler_fuel_type)

    units.each do |unit|
    
      thermal_zones = []
      unit.spaces.each do |space|
        thermal_zone = space.thermalZone.get
        next if thermal_zones.include? thermal_zone
        thermal_zones << thermal_zone
      end
    
      std.model_add_ptac(model, sys_name=nil, hot_water_loop, thermal_zones, fan_type="ConstantVolume", "Water", cooling_type="Single Speed DX AC")
    
    end

    simulation_control = model.getSimulationControl
    simulation_control.setRunSimulationforSizingPeriods(true)

    runner.registerInfo("Added PTAC to the building.")

    return true

  end

end

# register the measure to be used by the application
ProcessCentralSystemPTAC.new.registerWithApplication
