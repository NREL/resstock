# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require_relative '../HPXMLtoOpenStudio/resources/constants'
require_relative '../HPXMLtoOpenStudio/resources/constructions'

# start the measure
class ProcessConstructionsFacadesShared < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    return 'ResidentialConstructionsFacadesShared'
  end

  # human readable description
  def description
    return 'Used to indicate whether specified multifamily building facade(s) are shared with other multifamily building(s).'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'Shared walls are assigned adiabatic constructions.'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # make a choice argument for model objects
    building_facades = OpenStudio::StringVector.new
    building_facades << Constants.FacadeNone
    building_facades << Constants.FacadeBack
    building_facades << Constants.FacadeLeft
    building_facades << Constants.FacadeRight
    building_facades << "#{Constants.FacadeLeft}, #{Constants.FacadeRight}"
    building_facades << "#{Constants.FacadeLeft}, #{Constants.FacadeBack}"
    building_facades << "#{Constants.FacadeBack}, #{Constants.FacadeRight}"
    building_facades << "#{Constants.FacadeLeft}, #{Constants.FacadeRight}, #{Constants.FacadeBack}"

    # make an argument for shared building facade
    shared_building_facades = OpenStudio::Measure::OSArgument::makeChoiceArgument('shared_building_facades', building_facades, true)
    shared_building_facades.setDisplayName('Shared Building Facade(s)')
    shared_building_facades.setDescription('The facade(s) of the building that are shared. Surfaces on these facades become adiabatic.')
    shared_building_facades.setDefaultValue("#{Constants.FacadeNone}")
    args << shared_building_facades

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    shared_building_facades = runner.getStringArgumentValue('shared_building_facades', user_arguments)

    return true if shared_building_facades == Constants.FacadeNone

    if not WallConstructions.apply_adiabatic(runner, model, shared_building_facades)
      return false
    end

    return true
  end
end

# register the measure to be used by the application
ProcessConstructionsFacadesShared.new.registerWithApplication
