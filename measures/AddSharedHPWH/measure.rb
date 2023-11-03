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
    return 'Replace in-unit water heaters with shared heat pump water heater.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'Remove all existing domestic/solar hot water loops and associated EMS objects. Add new recirculation loop with main storage and swing tanks on the supply side, and existing water use connections on the demand side. Add new heat pump loop with main storage tank on the demand side, and heat pump water heater on the supply side.'
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

    # Setpoint Schedule
    schedule = OpenStudio::Model::ScheduleConstant.new(model)
    schedule.setValue(UnitConversions.convert(125.0, 'F', 'C'))

    # Add Loops
    recirculation_loop = add_loop(model, 'Recirculation Loop')
    heat_pump_loop = add_loop(model, 'Heat Pump Loop')

    # Add Pipes
    add_pipes(model, recirculation_loop, true, false)
    add_pipes(model, heat_pump_loop, true, true)

    # Add Pumps
    add_pump(model, recirculation_loop, 'Recirculation Loop Pump')
    add_pump(model, heat_pump_loop, 'Heat Pump Loop Pump')

    # Add Setpoint Managers
    add_setpoint_manager(model, recirculation_loop, schedule, 'Recirculation Loop Setpoint Manager')
    add_setpoint_manager(model, heat_pump_loop, schedule, 'Heat Pump Loop Setpoint Manager', 'Temperature')

    # Add Tanks
    storage_tank = add_storage_tank(model, recirculation_loop, heat_pump_loop, 'Main Storage Tank')
    add_swing_tank(model, recirculation_loop, 'Swing Tank')

    # Add Heat Pump
    heat_pump = add_heat_pump(model, shared_hpwh, heat_pump_loop, name)

    # Add Availability Manager
    hot_node = heat_pump.outletModelObject.get.to_Node.get
    cold_node = storage_tank.demandOutletModelObject.get.to_Node.get
    add_availability_manager(model, heat_pump_loop, hot_node, cold_node)

    # Re-connect WaterUseConections
    model.getWaterUseConnectionss.each do |wuc|
      recirculation_loop.addDemandBranchForComponent(wuc)
    end

    # Remove Existing
    remove_loops(model)
    remove_ems(model)

    return true
  end

  def add_loop(model, name)
    loop = OpenStudio::Model::PlantLoop.new(model)
    loop.setName(name)

    return loop
  end

  def add_pipes(model, loop, supply = false, demand = false)
    if supply
      supply_bypass = OpenStudio::Model::PipeAdiabatic.new(model)
      supply_outlet = OpenStudio::Model::PipeAdiabatic.new(model)

      loop.addSupplyBranchForComponent(supply_bypass)
      supply_outlet.addToNode(loop.supplyOutletNode)
    end

    if demand
      demand_bypass = OpenStudio::Model::PipeAdiabatic.new(model)
      demand_inlet = OpenStudio::Model::PipeAdiabatic.new(model)
      demand_outlet = OpenStudio::Model::PipeAdiabatic.new(model)

      loop.addDemandBranchForComponent(demand_bypass)
      demand_inlet.addToNode(loop.demandInletNode)
      demand_outlet.addToNode(loop.demandOutletNode)
    end

    # pipe_mat = OpenStudio::Model::StandardOpaqueMaterial.new(model, 'Smooth', 3.00E-03, 45.31, 7833.0, 500.0)
    # pipe_const = OpenStudio::Model::Construction.new(model)
    # pipe_const.insertLayer(0, pipe_mat)

    # bypass_pipe = OpenStudio::Model::PipeIndoor.new(model)
    # bypass_pipe.setAmbientTemperatureZone(zone) # TODO: jeff?
    # bypass_pipe.setConstruction(pipe_const) # TODO: jeff?
    # bypass_pipe.setPipeLength(3) # TODO: jeff?
  end

  def add_pump(model, loop, name)
    pump = OpenStudio::Model::PumpConstantSpeed.new(model)
    pump.setName(name)
    pump.addToNode(loop.supplyInletNode)
  end

  def add_setpoint_manager(model, loop, schedule, name, control_variable = nil)
    manager = OpenStudio::Model::SetpointManagerScheduled.new(model, schedule)
    manager.setName(name)
    manager.setControlVariable(control_variable) if !control_variable.nil?
    manager.addToNode(loop.supplyOutletNode)
  end

  def add_storage_tank(model, recirculation_loop, heat_pump_loop, name)
    storage_tank = OpenStudio::Model::WaterHeaterStratified.new(model)
    storage_tank.setName(name)

    recirculation_loop.addSupplyBranchForComponent(storage_tank)
    heat_pump_loop.addDemandBranchForComponent(storage_tank)

    return storage_tank
  end

  def add_swing_tank(model, loop, name)
    # TODO: this would be in series with main storage, downstream of it
    # this does not go on the demand side of the heat pump loop, like the main storage tank does
    swing_tank = OpenStudio::Model::WaterHeaterStratified.new(model)
    swing_tank.setName(name)
    swing_tank.addToNode(loop.supplyOutletNode)
  end

  def add_heat_pump(model, fuel_type, loop, name)
    if fuel_type == HPXML::FuelTypeElectricity
      heat_pump = OpenStudio::Model::WaterHeaterHeatPump.new(model)
      # heat_pump.setEndUseSubcategory('EHP 1')
    elsif fuel_type == HPXML::FuelTypeNaturalGas
      heat_pump = OpenStudio::Model::HeatPumpAirToWaterFuelFiredHeating.new(model)
      heat_pump.setEndUseSubcategory('GHP 1')
      # TODO: update defaulted setters
    end
    heat_pump.setName(name)
    loop.addSupplyBranchForComponent(heat_pump)

    return heat_pump
  end

  def add_availability_manager(model, loop, hot_node, cold_node)
    availability_manager = OpenStudio::Model::AvailabilityManagerDifferentialThermostat.new(model)
    availability_manager.setHotNode(hot_node)
    availability_manager.setColdNode(cold_node)
    availability_manager.setTemperatureDifferenceOnLimit(0)
    availability_manager.setTemperatureDifferenceOffLimit(0)
    loop.addAvailabilityManager(availability_manager)
  end

  def remove_loops(model)
    model.getPlantLoops.each do |plant_loop|
      plant_loop.remove if plant_loop.name.to_s.include?('dhw_loop')
      plant_loop.remove if plant_loop.name.to_s.include?('solar_hot_water_loop')
    end
  end

  def remove_ems(model)
    # TODO: jeff to look into EC_adj
    model.getEnergyManagementSystemProgramCallingManagers.each do |ems_pcm|
      if !ems_pcm.name.to_s.include?('EC_adj') && !ems_pcm.name.to_s.include?('solar_hot_water') && !ems_pcm.name.to_s.include?('water_heater')
        next
      end

      ems_pcm.programs.each do |program|
        program.remove
      end
      ems_pcm.remove
    end

    model.getEnergyManagementSystemSensors.each do |ems_sensor|
      if !ems_sensor.name.to_s.include?('water_heater') && !ems_sensor.name.to_s.include?('solar_hot_water')
        next
      end

      ems_sensor.remove
    end
  end
end

# register the measure to be used by the application
AddSharedHPWH.new.registerWithApplication
