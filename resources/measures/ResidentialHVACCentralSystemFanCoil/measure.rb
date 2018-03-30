# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/unit_conversions"
require "#{File.dirname(__FILE__)}/resources/geometry"

# start the measure
class ProcessCentralSystemFanCoil < OpenStudio::Measure::ModelMeasure

  # human readable name
  def name
    return "ResidentialHVACCentralSystemFanCoil"
  end

  # human readable description
  def description
    return "Description"
  end

  # human readable description of modeling approach
  def modeler_description
    return "Modeler Description"
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

    #make a string argument for central boiler system type
    central_boiler_system_type_names = OpenStudio::StringVector.new
    central_boiler_system_type_names << Constants.BoilerTypeForcedDraft
    central_boiler_system_type_names << Constants.BoilerTypeSteam
    central_boiler_system_type = OpenStudio::Measure::OSArgument::makeChoiceArgument("central_boiler_system_type", central_boiler_system_type_names, true)
    central_boiler_system_type.setDisplayName("Central Boiler System Type")
    central_boiler_system_type.setDescription("The system type of the central boiler.")
    central_boiler_system_type.setDefaultValue(Constants.BoilerTypeForcedDraft)
    args << central_boiler_system_type
    
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
    central_boiler_system_type = runner.getStringArgumentValue("central_boiler_system_type",user_arguments)
    central_boiler_fuel_type = {Constants.FuelTypeElectric=>"Electricity", Constants.FuelTypeGas=>"NaturalGas", Constants.FuelTypeOil=>"FuelOil#1", Constants.FuelTypePropane=>"PropaneGas"}[runner.getStringArgumentValue("central_boiler_fuel_type",user_arguments)]

    std = Standard.build("90.1-2013")

    if not fan_coil_heating and not fan_coil_cooling
      runner.registerError("Must specify at least heating or cooling.")
      return false
    end

    if fan_coil_heating and fan_coil_cooling
      hot_water_loop = std.model_get_or_add_hot_water_loop(model, central_boiler_fuel_type)
      chilled_water_loop = std.model_get_or_add_chilled_water_loop(model, "Electricity", air_cooled=true)
      msg = "heating/cooling fan coil unit"
    elsif fan_coil_cooling # TODO: manually add strip heat or gas wall furnace, or is there another standards method to do this?
      hot_water_loop = nil
      chilled_water_loop = std.model_get_or_add_chilled_water_loop(model, "Electricity", air_cooled=true)
      msg = "cooling-only fan coil unit"
    elsif fan_coil_heating
      hot_water_loop = std.model_get_or_add_hot_water_loop(model, central_boiler_fuel_type)
      msg = "central zone hvac unit heaters"
    end

    thermal_zones = []
    model.getThermalZones.each do |thermal_zone|
      next unless Geometry.zone_is_of_type(thermal_zone, Constants.SpaceTypeLiving) or Geometry.zone_is_of_type(thermal_zone, Constants.SpaceTypeFinishedBasement)
      thermal_zones << thermal_zone
    end
    # story_groups = std.model_group_zones_by_story(model, model.getThermalZones) # TODO: need to write our own "zones by stories" method since we don't use BuildingStory
    story_groups = [thermal_zones]
    story_groups.each do |zones|

      if fan_coil_heating and not fan_coil_cooling
        std.model_add_unitheater(model, sys_name=nil, zones, hvac_op_sch=nil, fan_control_type="ConstantVolume", fan_pressure_rise=OpenStudio.convert(0.2, "inH_{2}O", "Pa").get, "DistrictHeating", hot_water_loop)
      else
        std.model_add_four_pipe_fan_coil(model, hot_water_loop, chilled_water_loop, zones)
      end
      
      if fan_coil_heating
        if central_boiler_system_type == Constants.BoilerTypeSteam
          plant_loop = model.getPlantLoopByName("Hot Water Loop").get
          plant_loop.supplyComponents.each do |supply_component|
            next unless supply_component.to_PumpVariableSpeed.is_initialized
            pump = supply_component.to_PumpVariableSpeed.get
            # TODO: how to zero out the pumping energy?
          end
        end
      end

    end

    runner.registerInfo("Added #{msg} to the building.")

    return true

  end

end

# register the measure to be used by the application
ProcessCentralSystemFanCoil.new.registerWithApplication
