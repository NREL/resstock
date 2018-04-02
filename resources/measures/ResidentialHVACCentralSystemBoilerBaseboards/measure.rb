# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/unit_conversions"
require "#{File.dirname(__FILE__)}/resources/geometry"

# start the measure
class ProcessCentralSystemBoilerBaseboards < OpenStudio::Measure::ModelMeasure

  # human readable name
  def name
    return "ResidentialHVACCentralSystemBoilerBaseboards"
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

    central_boiler_system_type = runner.getStringArgumentValue("central_boiler_system_type",user_arguments)
    central_boiler_fuel_type = {Constants.FuelTypeElectric=>"Electricity", Constants.FuelTypeGas=>"NaturalGas", Constants.FuelTypeOil=>"FuelOil#1", Constants.FuelTypePropane=>"PropaneGas"}[runner.getStringArgumentValue("central_boiler_fuel_type",user_arguments)]

    std = Standard.build("90.1-2013")
    # std = Standard.build("DOE Ref Pre-1980")
    # std = Standard.build("DOE Ref 1980-2004")
    # std = Standard.build("90.1-2010")
    # std = Standard.build("90.1-2007")
    # std = Standard.build("90.1-2004")
    # std = Standard.build("90.1-2004_MidriseApartment") # with template

    thermal_zones = []
    model.getThermalZones.each do |thermal_zone|
      next unless Geometry.zone_is_of_type(thermal_zone, Constants.SpaceTypeLiving) or Geometry.zone_is_of_type(thermal_zone, Constants.SpaceTypeFinishedBasement)
      thermal_zones << thermal_zone
    end
    # story_groups = std.model_group_zones_by_story(model, model.getThermalZones) # TODO: need to write our own "zones by stories" method since we don't use BuildingStory
    story_groups = [thermal_zones]
    story_groups.each do |zones|

      hot_water_loop = std.model_get_or_add_hot_water_loop(model, central_boiler_fuel_type)
      std.model_add_baseboard(model, hot_water_loop, zones)
      
      if central_boiler_system_type == Constants.BoilerTypeSteam
        plant_loop = model.getPlantLoopByName("Hot Water Loop").get
        plant_loop.supplyComponents.each do |supply_component|
          next unless supply_component.to_PumpVariableSpeed.is_initialized
          pump = supply_component.to_PumpVariableSpeed.get
          # TODO: how to zero out the pumping energy?
        end
      end

    end

    runner.registerInfo("Added #{central_boiler_system_type} central boiler and baseboards to the building.")
    
    return true

  end

end

# register the measure to be used by the application
ProcessCentralSystemBoilerBaseboards.new.registerWithApplication
