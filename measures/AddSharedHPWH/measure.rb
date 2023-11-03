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

    shared_hpwh = hpxml.buildings[0].header.extension_properties['SharedHPWH']
    if shared_hpwh == 'none'
      runner.registerAsNotApplicable('Building does not have shared HPWH. Skipping AddSharedHPWH measure ...')
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
    # bypass_pipe.setAmbientTemperatureZone(zone) # TODO: jeff?
    # bypass_pipe.setConstruction(pipe_const) # TODO: jeff?
    # bypass_pipe.setPipeLength(3) # TODO: jeff?
    bypass_pipe = OpenStudio::Model::PipeAdiabatic.new(model)

    # out_pipe = OpenStudio::Model::PipeIndoor.new(model)
    # out_pipe.setAmbientTemperatureZone(zone)
    # out_pipe.setConstruction(pipe_const)
    # out_pipe.setPipeLength(3)
    out_pipe = OpenStudio::Model::PipeAdiabatic.new(model)

    recirculation_loop.addSupplyBranchForComponent(bypass_pipe)
    out_pipe.addToNode(recirculation_loop.supplyOutletNode)

    pump = OpenStudio::Model::PumpConstantSpeed.new(model)
    pump.setName('Recirculation Loop Pump')

    schedule = OpenStudio::Model::ScheduleConstant.new(model)
    schedule.setValue(UnitConversions.convert(125.0, 'F', 'C'))

    manager = OpenStudio::Model::SetpointManagerScheduled.new(model, schedule)
    manager.setName('Recirculation Loop Setpoint Manager')
    manager.addToNode(recirculation_loop.supplyOutletNode)

    storage_tank = OpenStudio::Model::WaterHeaterStratified.new(model)
    storage_tank.setName('Main Storage Tank')

    # TODO: this would be in series with main storage, downstream of it
    # this does not go on the demand side of the heat pump loop, like the main storage tank does
    swing_tank = OpenStudio::Model::WaterHeaterStratified.new(model)
    swing_tank.setName('Swing Tank')
    swing_tank.addToNode(recirculation_loop.supplyOutletNode)

    recirculation_loop.addSupplyBranchForComponent(storage_tank)
    pump.addToNode(recirculation_loop.supplyInletNode)

    heat_pump_loop = OpenStudio::Model::PlantLoop.new(model)
    heat_pump_loop.setName('Heat Pump Loop')

    pipe_supply_bypass = OpenStudio::Model::PipeAdiabatic.new(model)
    pipe_supply_outlet = OpenStudio::Model::PipeAdiabatic.new(model)
    pipe_demand_bypass = OpenStudio::Model::PipeAdiabatic.new(model)
    pipe_demand_inlet = OpenStudio::Model::PipeAdiabatic.new(model)
    pipe_demand_outlet = OpenStudio::Model::PipeAdiabatic.new(model)

    dhw_setpoint_manager = nil
    recirculation_loop.supplyOutletNode.setpointManagers.each do |setpoint_manager|
      if setpoint_manager.to_SetpointManagerScheduled.is_initialized
        dhw_setpoint_manager = setpoint_manager.to_SetpointManagerScheduled.get
      end
    end

    manager = OpenStudio::Model::SetpointManagerScheduled.new(model, dhw_setpoint_manager.schedule)
    manager.setName('Heat Pump Loop Setpoint Manager')
    manager.setControlVariable('Temperature')
    manager.addToNode(heat_pump_loop.supplyOutletNode)

    pump = OpenStudio::Model::PumpConstantSpeed.new(model)
    pump.setName('Heat Pump Loop Pump')
    pump.addToNode(heat_pump_loop.supplyInletNode)

    heat_pump_loop.addSupplyBranchForComponent(pipe_supply_bypass)
    pipe_supply_outlet.addToNode(heat_pump_loop.supplyOutletNode)
    heat_pump_loop.addDemandBranchForComponent(pipe_demand_bypass)
    pipe_demand_inlet.addToNode(heat_pump_loop.demandInletNode)
    pipe_demand_outlet.addToNode(heat_pump_loop.demandOutletNode)

    heat_pump_loop.addDemandBranchForComponent(storage_tank)

    if shared_hpwh == HPXML::FuelTypeElectricity
      # heat_pump = OpenStudio::Model::HeatPumpPlantLoopEIRHeating.new(model)
      # heat_pump.setEndUseSubcategory('EHP 1')
    elsif shared_hpwh == HPXML::FuelTypeNaturalGas
      heat_pump = OpenStudio::Model::HeatPumpAirToWaterFuelFiredHeating.new(model)
      heat_pump.setEndUseSubcategory('GHP 1')
      # TODO: update defaulted setters
    end
    heat_pump_loop.addSupplyBranchForComponent(heat_pump)

    availability_manager = OpenStudio::Model::AvailabilityManagerDifferentialThermostat.new(model)
    availability_manager.setHotNode(heat_pump.outletModelObject.get.to_Node.get)
    availability_manager.setColdNode(storage_tank.demandOutletModelObject.get.to_Node.get)
    availability_manager.setTemperatureDifferenceOnLimit(0)
    availability_manager.setTemperatureDifferenceOffLimit(0)
    heat_pump_loop.addAvailabilityManager(availability_manager)

    model.getWaterUseConnectionss.each do |wuc|
      recirculation_loop.addDemandBranchForComponent(wuc)
    end

    model.getPlantLoops.each do |plant_loop|
      next unless plant_loop.name.to_s.include?('dhw_loop')

      plant_loop.remove
    end

    # placeholder to get things to simulate, otherwise orphaned objects
    # TODO: jeff to look into EC_adj
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
