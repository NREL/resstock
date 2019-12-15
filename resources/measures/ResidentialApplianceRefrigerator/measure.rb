resources_path = File.absolute_path(File.join(File.dirname(__FILE__), "../HPXMLtoOpenStudio/resources"))
unless File.exists? resources_path
  resources_path = File.join(OpenStudio::BCLMeasure::userMeasuresDir.to_s, "HPXMLtoOpenStudio/resources") # Hack to run measures in the OS App since applied measures are copied off into a temporary directory
end
require File.join(resources_path, "constants")
require File.join(resources_path, "geometry")
require File.join(resources_path, "appliances")

# start the measure
class ResidentialRefrigerator < OpenStudio::Measure::ModelMeasure
  def name
    return "Set Residential Refrigerator"
  end

  def description
    return "Adds (or replaces) a residential refrigerator with the specified efficiency, operation, and schedule. For multifamily buildings, the refrigerator can be set for all units of the building.#{Constants.WorkflowDescription}"
  end

  def modeler_description
    return "Since there is no Refrigerator object in OpenStudio/EnergyPlus, we look for an ElectricEquipment object with the name that denotes it is a residential refrigerator. If one is found, it is replaced with the specified properties. Otherwise, a new such object is added to the model."
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # make a double argument for user defined fridge options
    rated_annual_energy = OpenStudio::Measure::OSArgument::makeDoubleArgument("rated_annual_energy", true)
    rated_annual_energy.setDisplayName("Rated Annual Consumption")
    rated_annual_energy.setUnits("kWh/yr")
    rated_annual_energy.setDescription("The EnergyGuide rated annual energy consumption for a refrigerator.")
    rated_annual_energy.setDefaultValue(434)
    args << rated_annual_energy

    # make a double argument for Occupancy Energy Multiplier
    mult = OpenStudio::Measure::OSArgument::makeDoubleArgument("mult")
    mult.setDisplayName("Occupancy Energy Multiplier")
    mult.setDescription("Appliance energy use is multiplied by this factor to account for occupancy usage that differs from the national average.")
    mult.setDefaultValue(1)
    args << mult

    # make a choice argument for location
    location_args = OpenStudio::StringVector.new
    location_args << Constants.Auto
    Geometry.get_model_locations(model).each do |loc|
      location_args << loc
    end
    location = OpenStudio::Measure::OSArgument::makeChoiceArgument("location", location_args, true, true)
    location.setDisplayName("Location")
    location.setDescription("The space type for the location. '#{Constants.Auto}' will automatically choose a space type based on the space types found in the model.")
    location.setDefaultValue(Constants.Auto)
    args << location

    return args
  end # end the arguments method

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # assign the user inputs to variables
    rated_annual_energy = runner.getDoubleArgumentValue("rated_annual_energy", user_arguments)
    mult = runner.getDoubleArgumentValue("mult", user_arguments)
    location = runner.getStringArgumentValue("location", user_arguments)

    # Get building units
    units = Geometry.get_building_units(model, runner)
    if units.nil?
      return false
    end

    # Remove all existing objects
    obj_name = Constants.ObjectNameRefrigerator
    model.getSpaces.each do |space|
      Refrigerator.remove(runner, space, obj_name)
    end

    location_hierarchy = [Constants.SpaceTypeKitchen,
                          Constants.SpaceTypeLiving,
                          Constants.SpaceTypeGarage,
                          Constants.SpaceTypeLiving,
                          Constants.SpaceTypeUnfinishedBasement]

    # FIXME: temporary until we have the generated schedules.csv of appropriate length
    sch_path = File.join(File.dirname(__FILE__), "../HPXMLtoOpenStudio/resources/schedules_TMY_60min.csv")
    case model.getYearDescription.calendarYear.get
    when 2012
      sch_path = File.join(File.dirname(__FILE__), "../HPXMLtoOpenStudio/resources/schedules_AMY2012_60min.csv")
    when 2014
      sch_path = File.join(File.dirname(__FILE__), "../HPXMLtoOpenStudio/resources/schedules_AMY2014_60min.csv")
    end
    schedule_file = SchedulesFile.new(runner: runner, model: model, schedules_output_path: sch_path)
    if not schedule_file.validated?
      return false
    end

    tot_ann_e = 0
    msgs = []
    sch = nil
    units.each_with_index do |unit, unit_index|
      # Get space
      space = Geometry.get_space_from_location(unit, location, location_hierarchy)
      next if space.nil?

      success, ann_e, sch = Refrigerator.apply(model, unit, runner, rated_annual_energy, mult, sch, space, schedule_file)

      if not success
        return false
      end

      if ann_e > 0
        msgs << "A refrigerator with #{ann_e.round} kWhs annual energy consumption has been assigned to space '#{space.name.to_s}'."
      end

      tot_ann_e += ann_e
    end

    # Reporting
    if msgs.size > 1
      msgs.each do |msg|
        runner.registerInfo(msg)
      end
      runner.registerFinalCondition("The building has been assigned refrigerators totaling #{tot_ann_e.round} kWhs annual energy consumption across #{units.size} units.")
    elsif msgs.size == 1
      runner.registerFinalCondition(msgs[0])
    else
      runner.registerFinalCondition("No refrigerator has been assigned.")
    end

    return true
  end # end the run method
end # end the measure

# this allows the measure to be use by the application
ResidentialRefrigerator.new.registerWithApplication
