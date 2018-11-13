# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require_relative "../HPXMLtoOpenStudio/resources/unit_conversions"
require_relative "../HPXMLtoOpenStudio/resources/geometry"
require_relative "../HPXMLtoOpenStudio/resources/util"
require_relative "../HPXMLtoOpenStudio/resources/hvac"

# start the measure
class ProcessCentralSystemFanCoil < OpenStudio::Measure::ModelMeasure

  # human readable name
  def name
    return "ResidentialHVACCentralSystemFanCoil"
  end

  # human readable description
  def description
    return "Adds either: (1) a central boiler/chiller with fan coil units to the model, (2) a central chiller with cooling-only fan coil units to the model, or (3) a central boiler with heating-only unit heaters to the model."
  end

  # human readable description of modeling approach
  def modeler_description
    return "Adds either: (1) hot water boiler and electric chiller with variable-speed pumps to two plant loops, along with coil heating/cooling water objects on zone hvac four pipe fan coil objects, (2) an electric chiller with variable-speed pump to a single plant loop, along with coil cooling water objects on cooling-only zone hvac four pipe fan coil objects, or (3) a hot water boiler with variable-speed pump to a single plant loop, along with coil heating water objects on heating-only zone hvac unit heater objects."
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    #make a bool argument for whether there is heating
    fan_coil_heating = OpenStudio::Measure::OSArgument::makeBoolArgument("fan_coil_heating", true)
    fan_coil_heating.setDisplayName("Fan Coil Provides Heating")
    fan_coil_heating.setDescription("When the fan coil provides heating in addition to cooling, a four pipe fan coil system is modeled.")
    fan_coil_heating.setDefaultValue(true)
    args << fan_coil_heating
    
    #make a bool argument for whether there is cooling
    fan_coil_cooling = OpenStudio::Measure::OSArgument::makeBoolArgument("fan_coil_cooling", true)
    fan_coil_cooling.setDisplayName("Fan Coil Provides Cooling")
    fan_coil_cooling.setDescription("When the fan coil provides cooling in addition to heating, a four pipe fan coil system is modeled.")
    fan_coil_cooling.setDefaultValue(true)
    args << fan_coil_cooling
    
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

    fan_coil_heating = runner.getBoolArgumentValue("fan_coil_heating",user_arguments)
    fan_coil_cooling = runner.getBoolArgumentValue("fan_coil_cooling",user_arguments)
    central_boiler_fuel_type = HelperMethods.eplus_fuel_map(runner.getStringArgumentValue("central_boiler_fuel_type",user_arguments))

    if not fan_coil_heating and not fan_coil_cooling
      runner.registerError("Must specify at least heating or cooling.")
      return false
    end

    std = Standard.build("90.1-2013")

    # Get building units
    units = Geometry.get_building_units(model, runner)
    if units.nil?
      return false
    end

    hot_water_loop = nil
    chilled_water_loop = nil
    units.each do |unit|
      thermal_zones = Geometry.get_thermal_zones_from_spaces(unit.spaces)
      HVAC.get_control_and_slave_zones(thermal_zones).each do |control_zone, slave_zones|
        ([control_zone] + slave_zones).each do |zone|
          HVAC.remove_hvac_equipment(model, runner, zone, unit, 
                                     Constants.ObjectNameCentralSystemFanCoil, fan_coil_heating, fan_coil_cooling)
                
        end
      end

      if fan_coil_heating
        if hot_water_loop.nil?
          hot_water_loop = std.model_get_or_add_hot_water_loop(model, central_boiler_fuel_type)
          runner.registerInfo("Added '#{hot_water_loop.name}' to model.")
        end
      end
      
      if fan_coil_cooling
        if chilled_water_loop.nil?
          chilled_water_loop = std.model_get_or_add_chilled_water_loop(model, "Electricity", chilled_water_loop_cooling_type: "AirCooled")
          runner.registerInfo("Added '#{chilled_water_loop.name}' to model.")
        end
      end

      success = HVAC.apply_central_system_fan_coil(model, unit, runner, std, fan_coil_heating, fan_coil_cooling, hot_water_loop, chilled_water_loop)      

      return false if not success

    end # unit

    simulation_control = model.getSimulationControl
    simulation_control.setRunSimulationforSizingPeriods(true) # indicate e+ autosizing

    return true

  end

end

# register the measure to be used by the application
ProcessCentralSystemFanCoil.new.registerWithApplication
