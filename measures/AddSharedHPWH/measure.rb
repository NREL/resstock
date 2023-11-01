# frozen_string_literal: true

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

# start the measure
class AddSharedHPWH < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    # Measure name should be the title case of the class name.
    return 'AddSharedHPWH'
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
      runner.registerAsNotApplicable('Building does not have gHPWH. Skipping AddSharedHPWH measure ...')
      return true
    end

    # TODO
    # 1 Remove any existing WHs and associated plant loops. Keep WaterUseEquipment objects.
    # 2 Add recirculation loop and piping. Use "Pipe:Indoor" objects, assume ~3 m of pipe per unit in the living zone of each.
    #  Each unit also needs a splitter: either to the next unit or this unit's WaterUseEquipment Objects. (this involves pipes in parallel/series. this may be handled in FT.)
    # 3 Add a recirculation pump (ConstantSpeed) to the loop. We'll use "AlwaysOn" logic, at least as a starting point.
    # 5 Add a new WaterHeater:Stratified object to represent the main storage tank.
    # 6 Add a swing tank in series: Ahead of the main WaterHeater:Stratified, another stratified tank model.
    #  This one includes an ER element to make up for loop losses.
    # 7 Add the GAHP(s). Will need to do some test runs when this is in to figure out how many units before we increase the # of HPs
    #  HeatExchangerFluidToFluid

    recirculation_loop = OpenStudio::Model::PlantLoop.new(model)
    recirculation_loop.setName('Recirculation Loop')

    # pipe_mat = OpenStudio::Model::StandardOpaqueMaterial.new(model, 'Smooth', 3.00E-03, 45.31, 7833.0, 500.0)
    # pipe_const = OpenStudio::Model::Construction.new(model)
    # pipe_const.insertLayer(0, pipe_mat)

    # bypass_pipe = OpenStudio::Model::PipeIndoor.new(model)
    # bypass_pipe.setAmbientTemperatureZone(zone)
    # bypass_pipe.setConstruction(pipe_const)
    # bypass_pipe.setPipeLength(3)
    bypass_pipe = OpenStudio::Model::PipeAdiabatic.new(model)

    # out_pipe = OpenStudio::Model::PipeIndoor.new(model)
    # out_pipe.setAmbientTemperatureZone(zone)
    # out_pipe.setConstruction(pipe_const)
    # out_pipe.setPipeLength(3)
    out_pipe = OpenStudio::Model::PipeAdiabatic.new(model)

    recirculation_loop.addSupplyBranchForComponent(bypass_pipe)
    out_pipe.addToNode(recirculation_loop.supplyOutletNode)

    pump = OpenStudio::Model::PumpConstantSpeed.new(model)
    pump.setName('Recirulation Pump')

    schedule = OpenStudio::Model::ScheduleConstant.new(model)
    schedule.setValue(UnitConversions.convert(125.0, 'F', 'C'))
    manager = OpenStudio::Model::SetpointManagerScheduled.new(model, schedule)
    manager.setName('Recirculation Loop Setpoint Manager')
    manager.addToNode(recirculation_loop.supplyOutletNode)

    storage_tank = OpenStudio::Model::WaterHeaterStratified.new(model)
    storage_tank.setName('Main Storage Tank')

    # swing_tank = OpenStudio::Model::WaterHeaterStratified.new(model)
    # swing_tank.setName('Swing Tank')

    hx = OpenStudio::Model::HeatExchangerFluidToFluid.new(model)
    hx.setName('Heat Exchanger')
    recirculation_loop.addSupplyBranchForComponent(hx)

    recirculation_loop.addSupplyBranchForComponent(storage_tank)
    # swing_tank.addToNode(recirculation_loop.supplyInletNode)
    pump.addToNode(recirculation_loop.supplyInletNode)

    condenser_loop = OpenStudio::Model::PlantLoop.new(model)
    condenser_loop.setName('Condenser Loop')
    manager = OpenStudio::Model::SetpointManagerScheduled.new(model, schedule)
    manager.setName('Condenser Loop Setpoint Manager')
    manager.addToNode(condenser_loop.supplyOutletNode)

    pump = OpenStudio::Model::PumpConstantSpeed.new(model)
    pump.addToNode(condenser_loop.supplyInletNode)
    condenser_loop.addDemandBranchForComponent(hx)

    fuel_fired_heating = OpenStudio::Model::HeatPumpAirToWaterFuelFiredHeating.new(model)
    fuel_fired_heating.setEndUseSubcategory('fuel_fired_heating')
    condenser_loop.addSupplyBranchForComponent(fuel_fired_heating)

    fuel_fired_heating = OpenStudio::Model::HeatPumpAirToWaterFuelFiredHeating.new(model)
    fuel_fired_heating.setEndUseSubcategory('fuel_fired_heating_2')
    condenser_loop.addSupplyBranchForComponent(fuel_fired_heating)

    model.getWaterUseConnectionss.each do |wuc|
      recirculation_loop.addDemandBranchForComponent(wuc)
    end

    model.getPlantLoops.each do |plant_loop|
      next unless plant_loop.name.to_s.include?('dhw_loop')

      plant_loop.remove
    end

    model.getEnergyManagementSystemProgramCallingManagers.each do |ems_pcm|
      next unless ems_pcm.name.to_s.include?('EC_adj')

      ems_pcm.programs.each do |program|
        program.remove
      end
      ems_pcm.remove
    end

    model.getEnergyManagementSystemSensors.each do |ems_sensor|
      next unless ems_sensor.name.to_s.include?('water_heater')

      ems_sensor.remove
    end

    puts "getPlantLoops #{model.getPlantLoops.collect { |o| o.name.to_s }}"
    puts "getWaterHeaterMixeds #{model.getWaterHeaterMixeds.collect { |o| o.name.to_s }}"
    puts "getWaterHeaterStratifieds #{model.getWaterHeaterStratifieds.collect { |o| o.name.to_s }}"
    puts "getPumpVariableSpeeds #{model.getPumpVariableSpeeds.collect { |o| o.name.to_s }}"
    puts "getPumpConstantSpeeds #{model.getPumpConstantSpeeds.collect { |o| o.name.to_s }}"
    puts "getWaterUseConnectionss #{model.getWaterUseConnectionss.collect { |o| o.name.to_s }}"
    puts "getWaterUseEquipments #{model.getWaterUseEquipments.collect { |o| o.name.to_s }}"

    return true
  end
end

# register the measure to be used by the application
AddSharedHPWH.new.registerWithApplication
