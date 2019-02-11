# see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

# see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

# see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

resources_path = File.absolute_path(File.join(File.dirname(__FILE__), "../HPXMLtoOpenStudio/resources"))
unless File.exists? resources_path
  resources_path = File.join(OpenStudio::BCLMeasure::userMeasuresDir.to_s, "HPXMLtoOpenStudio/resources") # Hack to run measures in the OS App since applied measures are copied off into a temporary directory
end
require File.join(resources_path, "constants")
require File.join(resources_path, "geometry")
require File.join(resources_path, "misc_loads")

# start the measure
class ResidentialMiscElectricLoads < OpenStudio::Measure::ModelMeasure
  # define the name that a user will see, this method may be deprecated as
  # the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Residential Plug Loads"
  end

  def description
    return "Adds (or replaces) residential plug loads with the specified efficiency and schedule in all finished spaces. For multifamily buildings, the plug loads can be set for all units of the building.#{Constants.WorkflowDescription}"
  end

  def modeler_description
    return "Since there is no Plug Loads object in OpenStudio/EnergyPlus, we look for an ElectricEquipment object with the name that denotes it is residential plug loads. If one is found, it is replaced with the specified properties. Otherwise, a new such object is added to the model. Note: This measure requires the number of bedrooms/bathrooms to have already been assigned."
  end

  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # TODO: New argument for demand response for mels (alternate schedules if automatic DR control is specified)

    # make a choice argument for option type
    choices = []
    choices << Constants.OptionTypePlugLoadsMultiplier
    choices << Constants.OptionTypePlugLoadsEnergyUse
    option_type = OpenStudio::Measure::OSArgument::makeChoiceArgument("option_type", choices, true)
    option_type.setDisplayName("Option Type")
    option_type.setDescription("Inputs are used/ignored below based on the option type specified.")
    option_type.setDefaultValue(Constants.OptionTypePlugLoadsMultiplier)
    args << option_type

    # make a double argument for BA Benchmark multiplier
    mult = OpenStudio::Measure::OSArgument::makeDoubleArgument("mult", true)
    mult.setDisplayName("#{Constants.OptionTypePlugLoadsMultiplier}")
    mult.setDefaultValue(1)
    mult.setDescription("A multiplier on the national average energy use, which is calculated as: (1108.1 + 180.2 * Nbeds + 0.2785 * FFA), where Nbeds is the number of bedrooms and FFA is the finished floor area in sqft.")
    args << mult

    # make a double argument for annual energy use
    energy_use = OpenStudio::Measure::OSArgument::makeDoubleArgument("energy_use", true)
    energy_use.setDisplayName("#{Constants.OptionTypePlugLoadsEnergyUse}")
    energy_use.setDefaultValue(2000)
    energy_use.setDescription("Annual energy use of the plug loads.")
    energy_use.setUnits("kWh/year")
    args << energy_use

    # Make a double argument for sensible fraction
    sens_frac = OpenStudio::Measure::OSArgument::makeDoubleArgument("sens_frac", true)
    sens_frac.setDisplayName("Sensible Fraction")
    sens_frac.setDescription("Fraction of internal gains that are sensible.")
    sens_frac.setDefaultValue(0.93)
    args << sens_frac

    # Make a double argument for latent fraction
    lat_frac = OpenStudio::Measure::OSArgument::makeDoubleArgument("lat_frac", true)
    lat_frac.setDisplayName("Latent Fraction")
    lat_frac.setDescription("Fraction of internal gains that are latent.")
    lat_frac.setDefaultValue(0.021)
    args << lat_frac

    # Make a string argument for 24 weekday schedule values
    weekday_sch = OpenStudio::Measure::OSArgument::makeStringArgument("weekday_sch", true)
    weekday_sch.setDisplayName("Weekday schedule")
    weekday_sch.setDescription("Specify the 24-hour weekday schedule.")
    weekday_sch.setDefaultValue("0.035, 0.033, 0.032, 0.031, 0.032, 0.033, 0.037, 0.042, 0.043, 0.043, 0.043, 0.044, 0.045, 0.045, 0.044, 0.046, 0.048, 0.052, 0.053, 0.05, 0.047, 0.045, 0.04, 0.036")
    args << weekday_sch

    # Make a string argument for 24 weekend schedule values
    weekend_sch = OpenStudio::Measure::OSArgument::makeStringArgument("weekend_sch", true)
    weekend_sch.setDisplayName("Weekend schedule")
    weekend_sch.setDescription("Specify the 24-hour weekend schedule.")
    weekend_sch.setDefaultValue("0.035, 0.033, 0.032, 0.031, 0.032, 0.033, 0.037, 0.042, 0.043, 0.043, 0.043, 0.044, 0.045, 0.045, 0.044, 0.046, 0.048, 0.052, 0.053, 0.05, 0.047, 0.045, 0.04, 0.036")
    args << weekend_sch

    # Make a string argument for 12 monthly schedule values
    monthly_sch = OpenStudio::Measure::OSArgument::makeStringArgument("monthly_sch", true)
    monthly_sch.setDisplayName("Month schedule")
    monthly_sch.setDescription("Specify the 12-month schedule.")
    monthly_sch.setDefaultValue("1.248, 1.257, 0.993, 0.989, 0.993, 0.827, 0.821, 0.821, 0.827, 0.99, 0.987, 1.248")
    args << monthly_sch

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
    option_type = runner.getStringArgumentValue("option_type", user_arguments)
    mult = runner.getDoubleArgumentValue("mult", user_arguments)
    energy_use = runner.getDoubleArgumentValue("energy_use", user_arguments)
    sens_frac = runner.getDoubleArgumentValue("sens_frac", user_arguments)
    lat_frac = runner.getDoubleArgumentValue("lat_frac", user_arguments)
    weekday_sch = runner.getStringArgumentValue("weekday_sch", user_arguments)
    weekend_sch = runner.getStringArgumentValue("weekend_sch", user_arguments)
    monthly_sch = runner.getStringArgumentValue("monthly_sch", user_arguments)

    # Get building units
    units = Geometry.get_building_units(model, runner)
    if units.nil?
      return false
    end

    # Remove all existing objects
    model.getSpaces.each do |space|
      MiscLoads.remove(runner, space, [Constants.ObjectNameMiscPlugLoads])
    end

    tot_mel_ann = 0
    msgs = []
    sch = nil
    units.each do |unit|
      # Calculate electric mel daily energy use
      if option_type == Constants.OptionTypePlugLoadsMultiplier
        # Get unit beds/baths
        nbeds, nbaths = Geometry.get_unit_beds_baths(model, unit, runner)
        if nbeds.nil? or nbaths.nil?
          return false
        end

        # Get unit ffa
        ffa = Geometry.get_finished_floor_area_from_spaces(unit.spaces, runner)
        if ffa.nil?
          return false
        end

        mel_ann = (1108.1 + 180.2 * nbeds + 0.2785 * ffa) * mult
      elsif option_type == Constants.OptionTypePlugLoadsEnergyUse
        mel_ann = energy_use
      end

      success, sch = MiscLoads.apply_plug(model, unit, runner, mel_ann,
                                          sens_frac, lat_frac, weekday_sch,
                                          weekend_sch, monthly_sch, sch)

      return false if not success

      if mel_ann > 0
        msgs << "Plug loads with #{mel_ann.round} kWhs annual energy consumption has been assigned to unit '#{unit.name.to_s}'."
        tot_mel_ann += mel_ann
      end
    end

    # Reporting
    if msgs.size > 1
      msgs.each do |msg|
        runner.registerInfo(msg)
      end
      runner.registerFinalCondition("The building has been assigned plug loads totaling #{tot_mel_ann.round} kWhs annual energy consumption across #{units.size} units.")
    elsif msgs.size == 1
      runner.registerFinalCondition(msgs[0])
    else
      runner.registerFinalCondition("No plug loads have been assigned.")
    end

    return true
  end # end the run method
end # end the measure

# this allows the measure to be use by the application
ResidentialMiscElectricLoads.new.registerWithApplication
