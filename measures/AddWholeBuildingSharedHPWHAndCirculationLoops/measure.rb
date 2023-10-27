# frozen_string_literal: true

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

# start the measure
class AddWholeBuildingSharedHPWHAndCirculationLoops < OpenStudio::Measure::ModelMeasure
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

    # Get defaulted hpxml
    hpxml_path = File.expand_path('../existing.xml') # this is the defaulted hpxml
    if File.exist?(hpxml_path)
      hpxml = HPXML.new(hpxml_path: hpxml_path, building_id: 'ALL')
    else
      runner.registerWarning("ApplyUpgrade measure could not find '#{hpxml_path}'.")
      return true
    end

    if hpxml.buildings[0].header.extension_properties['has_ghpwh'] == 'false'
      runner.registerAsNotApplicable('Building does not have gHPWH. Skipping AddWholeBuildingSharedHpwhAndCirculationLoops measure ...')
      return true
    end

    # TODO
    #1 Remove any existing WHs and associated plant loops. Keep WaterUseEquipment objects.
    #2 Add recirculation loop  piping. Use "Pipe:Indoor" objects, assume ~3 m of pipe per unit in the living zone of each. Each unit also needs a splitter: either to the next unit or this unit's WaterUseEquipment Objects.
    #3 Add a recirculation pump to the loop. We'll use "AlwaysOn" logic, at least as a starting point. 
    #5 Add a new WaterHeater:Stratified object to represent the main storage tank. 
    #6 Add a swing tank in series: Ahead of the main WaterHeater:Stratified, another stratified tank model. This one includes an ER element to make up for loop losses.
    #7 Add the GAHP(s). Will need to do some test runs when this is in to figure out how many units before we increase the # of HPs


    puts "spaces: #{model.getSpaces.size}"
    puts "\t#{model.getSpaces[0].name}"
    puts "thermal zones: #{model.getThermalZones.size}"
    puts "\t#{model.getThermalZones[0].name}"
    puts "plant loops: #{model.getPlantLoops.size}"
    puts "\t#{model.getPlantLoops[0].name}"
    puts "wh mixeds: #{model.getWaterHeaterMixeds.size}"
    puts "\t#{model.getWaterHeaterMixeds[0].name}"

    return true
  end
end

# register the measure to be used by the application
AddWholeBuildingSharedHPWHAndCirculationLoops.new.registerWithApplication
