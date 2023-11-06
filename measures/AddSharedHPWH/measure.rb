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

    # Add Adiabatic Pipes
    add_adiabatic_pipes(model, recirculation_loop)
    add_adiabatic_pipes(model, heat_pump_loop)

    # Add Pumps
    add_pump(model, recirculation_loop, 'Recirculation Loop Pump')
    add_pump(model, heat_pump_loop, 'Heat Pump Loop Pump')

    # Add Indoor Pipes
    add_indoor_pipes(model, recirculation_loop)

    # Add Setpoint Managers
    add_setpoint_manager(model, recirculation_loop, schedule, 'Recirculation Loop Setpoint Manager')
    add_setpoint_manager(model, heat_pump_loop, schedule, 'Heat Pump Loop Setpoint Manager', 'Temperature')

    # Add Tanks
    storage_tank = add_storage_tank(model, recirculation_loop, heat_pump_loop, 'Main Storage Tank')
    add_swing_tank(model, recirculation_loop, 'Swing Tank')

    # Add Heat Pump
    heat_pump = add_heat_pump(model, shared_hpwh, heat_pump_loop, 'Heat Pump Water Heater')

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

  def add_adiabatic_pipes(model, loop)
    supply_bypass = OpenStudio::Model::PipeAdiabatic.new(model)
    supply_outlet = OpenStudio::Model::PipeAdiabatic.new(model)

    loop.addSupplyBranchForComponent(supply_bypass)
    supply_outlet.addToNode(loop.supplyOutletNode)

    demand_bypass = OpenStudio::Model::PipeAdiabatic.new(model)
    demand_inlet = OpenStudio::Model::PipeAdiabatic.new(model)
    demand_outlet = OpenStudio::Model::PipeAdiabatic.new(model)

    loop.addDemandBranchForComponent(demand_bypass)
    demand_inlet.addToNode(loop.demandInletNode)
    demand_outlet.addToNode(loop.demandOutletNode)
  end

  def add_indoor_pipes(model, loop)
    materials = []

    supply_pipe_insulation_material = OpenStudio::Model::StandardOpaqueMaterial.new(model, 'VeryRough', 0.0306179506914235, 0.05193, 63.66, 1297.66)
    supply_pipe_insulation_material.setName('Supply Pipe Insulation')
    supply_pipe_insulation_material.setThermalAbsorptance(0.9)
    supply_pipe_insulation_material.setSolarAbsorptance(0.5)
    supply_pipe_insulation_material.setVisibleAbsorptance(0.5)
    materials << supply_pipe_insulation_material

    supply_pipe_material = OpenStudio::Model::StandardOpaqueMaterial.new(model, 'Smooth', 0.003, 401, 8940, 390)
    supply_pipe_material.setName('Supply Pipe')
    supply_pipe_material.setThermalAbsorptance(0.9)
    supply_pipe_material.setSolarAbsorptance(0.5)
    supply_pipe_material.setVisibleAbsorptance(0.5)
    materials << supply_pipe_material

    insulated_supply_pipe_construction = OpenStudio::Model::Construction.new(model)
    insulated_supply_pipe_construction.setName('Insulated Supply Pipe')
    insulated_supply_pipe_construction.setLayers(materials)

    model.getThermalZones.each do |thermal_zone|
      dhw_recirc_supply_pipe = OpenStudio::Model::PipeIndoor.new(model)
      dhw_recirc_supply_pipe.setName("DHW Recirc Supply Pipe - #{thermal_zone.name}")
      dhw_recirc_supply_pipe.setAmbientTemperatureZone(thermal_zone)
      dhw_recirc_supply_pipe.setConstruction(insulated_supply_pipe_construction)
      dhw_recirc_supply_pipe.setPipeInsideDiameter(0.0508)
      dhw_recirc_supply_pipe.setPipeLength(3)

      dhw_recirc_supply_pipe.addToNode(loop.demandInletNode)
    end
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

    capacity = 0
    storage_tank.setHeater1Capacity(capacity)
    storage_tank.setHeater2Capacity(capacity)

    recirculation_loop.addSupplyBranchForComponent(storage_tank)
    heat_pump_loop.addDemandBranchForComponent(storage_tank)

    return storage_tank
  end

  def add_swing_tank(model, loop, name)
    # TODO: this would be in series with main storage, downstream of it
    # this does not go on the demand side of the heat pump loop, like the main storage tank does
    swing_tank = OpenStudio::Model::WaterHeaterStratified.new(model)
    swing_tank.setName(name)

    capacity = 0
    swing_tank.setHeater1Capacity(capacity)
    swing_tank.setHeater2Capacity(capacity)

    swing_tank.addToNode(loop.supplyOutletNode)
  end

  def add_heat_pump(model, fuel_type, loop, name)
    if fuel_type == HPXML::FuelTypeElectricity
      heat_pump = OpenStudio::Model::WaterHeaterHeatPump.new(model)
    elsif fuel_type == HPXML::FuelTypeNaturalGas
      heat_pump = OpenStudio::Model::HeatPumpAirToWaterFuelFiredHeating.new(model)
      heat_pump.setFuelType(EPlus.fuel_type(fuel_type))
      heat_pump.setEndUseSubcategory('GHP 1')
      heat_pump.setNominalAuxiliaryElectricPower(0)
      heat_pump.setStandbyElectricPower(0)
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
    ems_pcm_to_remove = [
      'EC_adj',
      'solar hot water',
      'water_heater',
      'solar_hot_water'
    ]
    model.getEnergyManagementSystemProgramCallingManagers.each do |ems_pcm|
      if ems_pcm_to_remove.select { |e| ems_pcm.name.to_s.include?(e) }.size == 0
        next
      end

      ems_pcm.programs.each do |program|
        program.remove
      end
      ems_pcm.remove
    end

    ems_sensor_to_remove = [
      'water_heater',
      'solar_hot_water'
    ]
    model.getEnergyManagementSystemSensors.each do |ems_sensor|
      if ems_sensor_to_remove.select { |e| ems_sensor.name.to_s.include?(e) }.size == 0
        next
      end

      ems_sensor.remove
    end
  end
end

# register the measure to be used by the application
AddSharedHPWH.new.registerWithApplication
