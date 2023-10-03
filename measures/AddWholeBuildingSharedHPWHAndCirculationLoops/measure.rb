# frozen_string_literal: true

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

# start the measure
class AddWholeBuildingSharedHpwhAndCirculationLoops < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    # Measure name should be the title case of the class name.
    return 'AddWholeBuildingSharedHPWHAndCirculationLoops'
  end

  # human readable description
  def description
    return 'TODO'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'TODO'
  end

  # define the arguments that the user will input
  def arguments(model) # rubocop:disable Lint/UnusedMethodArgument
    args = OpenStudio::Measure::OSArgumentVector.new

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    hpxml_path = File.expand_path('../existing.xml')
    hpxml = HPXML.new(hpxml_path: hpxml_path, building_id: 'ALL') if File.exist?(hpxml_path)

    if hpxml.buildings[0].header.extension_properties['has_ghpwh'] == 'false'
      runner.registerAsNotApplicable('Building does not have gHPWH. Skipping AddWholeBuildingSharedHpwhAndCirculationLoops measure ...')
      return true
    end

    # TODO

    return true
  end
end

# register the measure to be used by the application
AddWholeBuildingSharedHpwhAndCirculationLoops.new.registerWithApplication
