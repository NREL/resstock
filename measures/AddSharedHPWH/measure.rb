# frozen_string_literal: true

Dir["#{File.dirname(__FILE__)}/resources/*.rb"].each do |resource_file|
  require resource_file
end

# start the measure
class AddSharedHPWH < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    # Measure name should be the title case of the class name.
    return 'AddSharedHPWH'
  end

  # human readable description
  def description
    return 'Replace in-unit water heaters and boilers with shared heat pump water heater.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'Remove all existing domestic/solar/boiler hot water loops and associated EMS objects. Add new recirculation loop with main storage and swing tanks on the supply side, and existing water use connections on the demand side. Add new heat pump loop with main storage tank on the demand side along with any space-heating baseboards, and heat pump water heater on the supply side.'
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

    # Extension properties
    hpxml_bldg = hpxml.buildings[0]

    shared_hpwh_type = hpxml_bldg.header.extension_properties['shared_hpwh_type']
    if shared_hpwh_type == 'none'
      runner.registerAsNotApplicable('Building does not have shared HPWH. Skipping AddSharedHPWH measure ...')
      return true
    end

    shared_hpwh_fuel_type = hpxml_bldg.header.extension_properties['shared_hpwh_fuel_type']
    num_stories = hpxml_bldg.header.extension_properties['geometry_num_floors_above_grade'].to_f
    has_double_loaded_corridor = hpxml_bldg.header.extension_properties['geometry_corridor_position']

    # TODO
    # 1 Remove any existing WHs and associated plant loops. Keep WaterUseEquipment objects.
    # 2 Add recirculation loop and piping. Use "Pipe:Indoor" objects, assume ~3 m of pipe per unit in the living zone of each.
    #  Each unit also needs a splitter: either to the next unit or this unit's WaterUseEquipment Objects. (this involves pipes in parallel/series. this may be handled in FT.)
    # 3 Add a recirculation pump (ConstantSpeed) to the loop. We'll use "AlwaysOn" logic, at least as a starting point.
    # 5 Add a new WaterHeater:Stratified object to represent the main storage tank.
    # 6 Add a swing tank in series: Ahead of the main WaterHeater:Stratified, another stratified tank model.
    #  This one includes an ER element to make up for loop losses.
    # 7 Add the GAHP(s). Will need to do some test runs when this is in to figure out how many units before we increase the # of HPs

    # Building -level information
    # num_units = hpxml.buildings.collect { |hpxml_bldg| hpxml_bldg.building_construction.number_of_units }.sum
    # num_beds = hpxml.buildings.collect { |hpxml_bldg| hpxml_bldg.building_construction.number_of_units * hpxml_bldg.building_construction.number_of_bedrooms }.sum
    # FIXME: should this be hpxml.buildings.size? sounds like maybe the actual number of units
    num_units = hpxml.buildings.size
    num_beds = hpxml.buildings.collect { |hpxml_bldg| hpxml_bldg.building_construction.number_of_bedrooms }.sum

    # Calculate some size parameters: number of heat pumps, storage tank volume, number of tanks, swing tank volume
    # Sizing is based on CA code requirements: https://efiling.energy.ca.gov/GetDocument.aspx?tn=234434&DocumentContentId=67301
    # FIXME: How to adjust size when used for space heating?
    heat_pump_count = ((0.037 * num_beds + 0.106 * num_units) * (154.0 / 123.5)).ceil # ratio is assumed capacity from code / nominal capacity from Robur spec sheet
    # storage_tank_volume = 80.0 * heat_pump_count
    # storage_tank_count = storage_tank_volume / 80.0 # TODO: Do we model these as x tanks in series or combine them into a single tank?
    storage_tank_volume = 80.0

    if num_units < 8
      swing_tank_volume = 40.0
    elsif num_units < 12
      swing_tank_volume = 80.0
    elsif num_units < 24
      swing_tank_volume = 96.0
    elsif num_units < 48
      swing_tank_volume = 168.0
    elsif num_units < 96
      swing_tank_volume = 288.0
    else
      swing_tank_volume = 480.0
    end

    # Setpoint Schedules
    storage_sp_schedule = OpenStudio::Model::ScheduleConstant.new(model)
    storage_sp_schedule.setValue(UnitConversions.convert(150.0, 'F', 'C')) # FIXME: final setpoint? Should it vary if used for space heating?

    loop_sp_schedule = OpenStudio::Model::ScheduleConstant.new(model)
    loop_sp_schedule.setValue(UnitConversions.convert(125.0, 'F', 'C')) # FIXME: final setpoint? Should it vary if used for space heating?

    # Add Loops
    dhw_loop = add_loop(model, 'DHW Loop')
    heat_pump_loops = {}
    (1..heat_pump_count).to_a.each do |i|
      heat_pump_loop = add_loop(model, "Heat Pump Loop #{i}")
      heat_pump_loops[heat_pump_loop] = []
    end
    source_loop = add_loop(model, 'Source Loop')
    if shared_hpwh_type == 'space-heating hpwh'
      space_heating_loop = add_loop(model, 'Space Heating Loop')
    end

    # Add Adiabatic Pipes
    dhw_loop_demand_inlet, dhw_loop_demand_bypass = add_adiabatic_pipes(model, dhw_loop)
    heat_pump_loops.each do |heat_pump_loop, _|
      _heat_pump_loop_demand_inlet, _heat_pump_loop_demand_bypass = add_adiabatic_pipes(model, heat_pump_loop)
    end
    _source_loop_demand_inlet, _source_loop_demand_bypass = add_adiabatic_pipes(model, source_loop)

    # Pipe Lengths
    supply_length, return_length = calc_recirc_supply_return_lengths(hpxml_bldg, num_units, num_stories, has_double_loaded_corridor)

    # Add Indoor Pipes
    supply_pipe_ins_r_value = 6.0
    return_pipe_ins_r_value = 4.0
    add_indoor_pipes(model, dhw_loop_demand_inlet, dhw_loop_demand_bypass, supply_length, return_length, supply_pipe_ins_r_value, return_pipe_ins_r_value, num_units)

    # Pump Flow Rate
    pump_gpm, swing_tank_capacity = calc_recirc_flow_rate(hpxml.buildings, supply_length, supply_pipe_ins_r_value)

    # Add Pumps
    hp_loop_gpm = 13.6 # gal/min, nominal from Robur spec sheet
    add_pump(model, dhw_loop, 'DHW Loop Pump', pump_gpm)
    heat_pump_loops.each do |heat_pump_loop, _|
      add_pump(model, heat_pump_loop, "#{heat_pump_loop.name} Pump", hp_loop_gpm)
    end
    add_pump(model, source_loop, 'Source Loop Pump', pump_gpm)
    if shared_hpwh_type == 'space-heating hpwh'
      add_pump(model, space_heating_loop, 'Space Heating Loop Pump', pump_gpm) # FIXME: need to re-consider the pump here
    end

    # Add Setpoint Managers
    add_setpoint_manager(model, dhw_loop, loop_sp_schedule, 'DHW Loop Setpoint Manager')
    heat_pump_loops.each do |heat_pump_loop, _|
      add_setpoint_manager(model, heat_pump_loop, storage_sp_schedule, "#{heat_pump_loop.name} Setpoint Manager", 'Temperature')
    end
    add_setpoint_manager(model, source_loop, storage_sp_schedule, 'Source Loop Setpoint Manager', 'Temperature')
    if shared_hpwh_type == 'space-heating hpwh'
      add_setpoint_manager(model, space_heating_loop, storage_sp_schedule, 'Space Heating Loop Setpoint Manager')
    end

    # Add Tanks
    prev_storage_tank = nil
    heat_pump_loops.each do |heat_pump_loop, components|
      components << add_storage_tank(model, source_loop, heat_pump_loop, storage_tank_volume, prev_storage_tank, "#{heat_pump_loop.name} Main Storage Tank")
      prev_storage_tank = components[0]
    end
    add_swing_tank(model, source_loop, swing_tank_volume, swing_tank_capacity, 'Swing Tank')

    # Add Heat Exchangers
    add_heat_exchanger(model, dhw_loop, source_loop, 'DHW Heat Exchanger')
    if shared_hpwh_type == 'space-heating hpwh'
      add_heat_exchanger(model, space_heating_loop, source_loop, 'Space Heating Heat Exchanger')
    end

    # Add Heat Pump
    heat_pump_loops.each do |heat_pump_loop, components|
      components << add_heat_pump(model, shared_hpwh_fuel_type, heat_pump_loop, "#{heat_pump_loop.name} Heat Pump Water Heater")
    end

    # HPWH provides space heating
    if shared_hpwh_type == 'space-heating hpwh'
      if model.getCoilHeatingWaterBaseboards.size == 0 # no existing baseboards(s)
        # TODO: create the baseboards? or should space-heating hpwh only be available if existing baseboards?
      end

      # Re-connect CoilHeatingWaterBaseboards
      model.getCoilHeatingWaterBaseboards.each do |chwb|
        space_heating_loop.addDemandBranchForComponent(chwb)
      end

      # disaggregate_heating_vs_how_water(model, heat_pump_loop, storage_tank) # FIXME: doesn't work if both distribution loops go through the source loop
    end

    # Add Availability Manager
    heat_pump_loops.each do |heat_pump_loop, components|
      storage_tank, heat_pump = components
      hot_node = heat_pump.outletModelObject.get.to_Node.get
      cold_node = storage_tank.demandOutletModelObject.get.to_Node.get
      add_availability_manager(model, heat_pump_loop, hot_node, cold_node)
    end

    # Re-connect WaterUseConections
    model.getWaterUseConnectionss.each do |wuc|
      dhw_loop.addDemandBranchForComponent(wuc)
    end

    # Remove Existing
    remove_loops(model, shared_hpwh_type)
    remove_ems(model, shared_hpwh_type)

    return true
  end

  def add_loop(model, name)
    loop = OpenStudio::Model::PlantLoop.new(model)
    loop.setName(name)

    return loop
  end

  def add_adiabatic_pipes(model, loop)
    # Supply
    supply_bypass = OpenStudio::Model::PipeAdiabatic.new(model)
    supply_bypass.setName('Supply Bypass Pipe')
    supply_outlet = OpenStudio::Model::PipeAdiabatic.new(model)
    supply_outlet.setName('Supply Outlet Pipe')

    loop.addSupplyBranchForComponent(supply_bypass)
    supply_outlet.addToNode(loop.supplyOutletNode)

    # Demand
    demand_inlet = OpenStudio::Model::PipeAdiabatic.new(model)
    demand_inlet.setName('Demand Inlet Pipe')
    demand_bypass = OpenStudio::Model::PipeAdiabatic.new(model)
    demand_bypass.setName('Demand Bypass Pipe')
    demand_outlet = OpenStudio::Model::PipeAdiabatic.new(model)
    demand_outlet.setName('Demand Outlet Pipe')

    demand_inlet.addToNode(loop.demandInletNode)
    loop.addDemandBranchForComponent(demand_bypass)
    demand_outlet.addToNode(loop.demandOutletNode)

    return demand_inlet, demand_bypass
  end

  def add_indoor_pipes(model, demand_inlet, demand_bypass, supply_length, return_length, supply_pipe_ins_r_value, return_pipe_ins_r_value, n_units)
    # Copper Pipe
    roughness = 'Smooth'
    thickness = 0.003
    conductivity = 401
    density = 8940
    specific_heat = 390

    copper_pipe_material = OpenStudio::Model::StandardOpaqueMaterial.new(model, roughness, thickness, conductivity, density, specific_heat)
    copper_pipe_material.setName('Return Pipe')
    copper_pipe_material.setThermalAbsorptance(0.9)
    copper_pipe_material.setSolarAbsorptance(0.5)
    copper_pipe_material.setVisibleAbsorptance(0.5)

    # Pipe Diameters
    supply_diameter, return_diameter = calc_recirc_supply_return_diameters()

    # Pipe Insulation
    roughness = 'VeryRough'
    conductivity = 0.021
    density = 63.66
    specific_heat = 1297.66

    supply_thickness, return_thickness = calc_recirc_pipe_ins_thicknesses(supply_pipe_ins_r_value, return_pipe_ins_r_value, supply_diameter, return_diameter, conductivity)

    pipe_ins_r_value_derate = 0.3
    effective_pipe_ins_conductivity = conductivity / (1.0 - pipe_ins_r_value_derate)

    # Supply
    supply_pipe_materials = []

    supply_pipe_insulation_material = OpenStudio::Model::StandardOpaqueMaterial.new(model, roughness, supply_thickness, effective_pipe_ins_conductivity, density, specific_heat) # R-6
    supply_pipe_insulation_material.setName('Supply Pipe Insulation')
    supply_pipe_insulation_material.setThermalAbsorptance(0.9)
    supply_pipe_insulation_material.setSolarAbsorptance(0.5)
    supply_pipe_insulation_material.setVisibleAbsorptance(0.5)

    supply_pipe_materials << supply_pipe_insulation_material
    supply_pipe_materials << copper_pipe_material

    insulated_supply_pipe_construction = OpenStudio::Model::Construction.new(model)
    insulated_supply_pipe_construction.setName('Insulated Supply Pipe')
    insulated_supply_pipe_construction.setLayers(supply_pipe_materials)

    # Return
    return_pipe_materials = []

    return_pipe_insulation_material = OpenStudio::Model::StandardOpaqueMaterial.new(model, roughness, return_thickness, effective_pipe_ins_conductivity, density, specific_heat) # R-4
    return_pipe_insulation_material.setName('Return Pipe Insulation')
    return_pipe_insulation_material.setThermalAbsorptance(0.9)
    return_pipe_insulation_material.setSolarAbsorptance(0.5)
    return_pipe_insulation_material.setVisibleAbsorptance(0.5)

    return_pipe_materials << return_pipe_insulation_material
    return_pipe_materials << copper_pipe_material

    insulated_return_pipe_construction = OpenStudio::Model::Construction.new(model)
    insulated_return_pipe_construction.setName('Insulated Return Pipe')
    insulated_return_pipe_construction.setLayers(return_pipe_materials)

    # Thermal Zones
    model.getThermalZones.each do |thermal_zone|
      # Supply
      dhw_recirc_supply_pipe = OpenStudio::Model::PipeIndoor.new(model)
      dhw_recirc_supply_pipe.setName("Recirculation Supply Pipe - #{thermal_zone.name}")
      dhw_recirc_supply_pipe.setAmbientTemperatureZone(thermal_zone)
      dhw_recirc_supply_pipe.setConstruction(insulated_supply_pipe_construction)
      dhw_recirc_supply_pipe.setPipeInsideDiameter(UnitConversions.convert(supply_diameter, 'in', 'm'))
      dhw_recirc_supply_pipe.setPipeLength(UnitConversions.convert(supply_length / n_units, 'ft', 'm'))

      dhw_recirc_supply_pipe.addToNode(demand_inlet.outletModelObject.get.to_Node.get) # FIXME: check IDF branches to make sure everything looks ok

      # Return
      dhw_recirc_return_pipe = OpenStudio::Model::PipeIndoor.new(model)
      dhw_recirc_return_pipe.setName("Recirculation Return Pipe - #{thermal_zone.name}")
      dhw_recirc_return_pipe.setAmbientTemperatureZone(thermal_zone)
      dhw_recirc_return_pipe.setConstruction(insulated_return_pipe_construction)
      dhw_recirc_return_pipe.setPipeInsideDiameter(UnitConversions.convert(return_diameter, 'in', 'm'))
      dhw_recirc_return_pipe.setPipeLength(UnitConversions.convert(return_length / n_units, 'ft', 'm'))

      dhw_recirc_return_pipe.addToNode(demand_bypass.outletModelObject.get.to_Node.get)
    end
  end

  def calc_recirc_supply_return_lengths(hpxml_bldg, n_units, n_stories, has_double_loaded_corridor)
    l_mech = 8 # ft, Horizontal pipe length in mech room (Per T-24 ACM: 2013 Residential Alternative Calculation Method Reference Manual, June 2013, CEC-400-2013-003-CMF-REV)
    unit_type = hpxml_bldg.building_construction.residential_facility_type
    footprint = hpxml_bldg.building_construction.conditioned_floor_area
    h_floor = hpxml_bldg.building_construction.average_ceiling_height

    n_units_per_floor = n_units / n_stories
    if [HPXML::ResidentialTypeSFD, HPXML::ResidentialTypeManufactured].include?(unit_type)
      aspect_ratio = 1.8
    elsif [HPXML::ResidentialTypeSFA, HPXML::ResidentialTypeApartment].include?(unit_type)
      aspect_ratio = 0.5556
    end
    fb = Math.sqrt(footprint * aspect_ratio)
    lr = footprint / fb
    l_bldg = [fb, lr].max * n_units_per_floor

    supply_length = (l_mech + h_floor * (n_stories / 2.0).ceil + l_bldg) # ft

    if has_double_loaded_corridor
      return_length = (l_mech + h_floor * (n_stories / 2.0).ceil) # ft
    else
      return_length = supply_length
    end

    return supply_length, return_length
  end

  def calc_recirc_supply_return_diameters()
    # supply_diameter = ((-7.525e-9 * n_units**4 + 2.82e-6 * n_units**3 + -4.207e-4 * n_units**2 + 0.04378 * n_units + 1.232) / 0.5 + 1).round * 0.5 # in    Diameter of supply recirc pipe (Per T-24 ACM* which is based on 2009 UPC pipe sizing)
    supply_diameter = 2.0 # in
    return_diameter = 0.75 # in

    return supply_diameter, return_diameter
  end

  def calc_recirc_pipe_ins_thicknesses(supply_pipe_ins_r_value, return_pipe_ins_r_value, supply_diameter, return_diameter, conductivity)
    # Calculate thickness (in.) from nominal R-value, pipe outer diamter (in.), and insulation conductivity

    r1 = supply_diameter
    t_eq = supply_pipe_ins_r_value * conductivity * 12 # (hr-ft2-F / Btu) *  (Btu/ht-ft-F) * (in/ft)
    supply_thickness = r1 * (Math.exp(lambert(t_eq / r1)) - 1) # http://www.wolframalpha.com/input/?i=solve+%28r%2Bt%29*ln%28%28r%2Bt%29%2Fr%29%3DL+for+t%2C+L%3E0%2C+t%3E0%2C+r%3E0

    r1 = return_diameter
    t_eq = return_pipe_ins_r_value * conductivity * 12 # (hr-ft2-F / Btu) *  (Btu/ht-ft-F) * (in/ft)
    return_thickness = r1 * (Math.exp(lambert(t_eq / r1)) - 1) # http://www.wolframalpha.com/input/?i=solve+%28r%2Bt%29*ln%28%28r%2Bt%29%2Fr%29%3DL+for+t%2C+L%3E0%2C+t%3E0%2C+r%3E0

    return UnitConversions.convert(supply_thickness, 'in', 'm'), UnitConversions.convert(return_thickness, 'in', 'm')
  end

  def calc_recirc_flow_rate(hpxml_buildings, supply_length, supply_pipe_ins_r_value)
    # ASHRAE calculation of the recirculation loop flow rate
    # Based on Equation 9 on p50.7 in 2011 ASHRAE Handbook--HVAC Applications

    avg_num_bath = 0
    avg_ffa = 0
    len_ins = 0
    len_unins = 0
    hpxml_buildings.each do |hpxml_bldg|
      avg_num_bath += hpxml_bldg.building_construction.number_of_bathrooms / hpxml_buildings.size
      avg_ffa += hpxml_bldg.building_construction.conditioned_floor_area / hpxml_buildings.size
    end

    if supply_pipe_ins_r_value > 0
      len_ins += supply_length
    else
      len_unins += supply_length
    end

    q_loss = 30 * len_ins + 60 * len_unins

    # Assume a 5 degree temperature drop is acceptable
    delta_T = 5 # degrees F

    return q_loss / (60 * 8.25 * delta_T), q_loss
  end

  def add_pump(model, loop, name, pump_gpm)
    return if loop.nil?

    pump = OpenStudio::Model::PumpConstantSpeed.new(model)
    pump.setName(name)
    pump.setRatedFlowRate(UnitConversions.convert(pump_gpm, 'gal/min', 'm^3/s')) # FIXME: correct setter?
    pump.addToNode(loop.supplyInletNode)
    pump.additionalProperties.setFeature('ObjectType', Constants.ObjectNameSharedHotWater) # Used by reporting measure
  end

  def add_setpoint_manager(model, loop, schedule, name, control_variable = nil)
    manager = OpenStudio::Model::SetpointManagerScheduled.new(model, schedule)
    manager.setName(name)
    manager.setControlVariable(control_variable) if !control_variable.nil?
    manager.addToNode(loop.supplyOutletNode)
  end

  def add_storage_tank(model, recirculation_loop, heat_pump_loop, volume, prev_storage_tank, name)
    h_tank = 2.0 # m, assumed
    h_source_in = 0.01 * h_tank
    h_source_out = 0.99 * h_tank

    tank_r = UnitConversions.convert(22.0, 'hr*ft^2*f/btu', 'm^2*k/w') # From code
    tank_u = 1.0 / tank_r

    storage_tank = OpenStudio::Model::WaterHeaterStratified.new(model)
    storage_tank.setName(name)

    # TODO: set volume, height, deadband, control
    capacity = 0
    storage_tank.setTankHeight(h_tank)
    storage_tank.setHeater1Capacity(capacity)
    storage_tank.setHeater2Capacity(capacity)
    storage_tank.setTankVolume(UnitConversions.convert(volume, 'gal', 'm^3'))
    # storage_tank.setAmbientTemperatureZone # FIXME: What zone do we want to assume the tanks are in?
    storage_tank.setUniformSkinLossCoefficientperUnitAreatoAmbientTemperature(tank_u) # FIXME: typical loss values?
    storage_tank.setSourceSideInletHeight(h_source_in)
    storage_tank.setSourceSideOutletHeight(h_source_out)
    storage_tank.setOffCycleParasiticFuelConsumptionRate(0.0)
    storage_tank.setOnCycleParasiticFuelConsumptionRate(0.0)
    storage_tank.setNumberofNodes(6)
    storage_tank.setEndUseSubcategory(name)

    if prev_storage_tank.nil?
      recirculation_loop.addSupplyBranchForComponent(storage_tank) # first one is a new supply branch
    else
      storage_tank.addToNode(prev_storage_tank.outletModelObject.get.to_Node.get) # remaining are added in series
    end
    heat_pump_loop.addDemandBranchForComponent(storage_tank)

    return storage_tank
  end

  def add_swing_tank(model, recirculation_loop, volume, capacity, name)
    # this would be in series with the main storage tanks, downstream of it
    # this does not go on the demand side of the heat pump loop, like the main storage tank does
    swing_tank = OpenStudio::Model::WaterHeaterStratified.new(model)
    swing_tank.setName(name)

    tank_r = UnitConversions.convert(22.0, 'hr*ft^2*f/btu', 'm^2*k/w') # From code
    tank_u = 1.0 / tank_r
    h_tank = 2.0 # m
    h_ue = 0.8 * h_tank
    h_le = 0.2 * h_tank
    h_source_in = 0.01 * h_tank
    h_source_out = 0.99 * h_tank

    swing_tank.setTankHeight(h_tank)
    swing_tank.setHeaterPriorityControl('MasterSlave')
    swing_tank.setHeater1Capacity(capacity)
    swing_tank.setHeater1Height(h_ue) 
    swing_tank.setHeater1DeadbandTemperatureDifference(5.56) # 10 F
    swing_tank.setHeater2Capacity(capacity)
    swing_tank.setHeater2Height(h_le)
    swing_tank.setHeater2DeadbandTemperatureDifference(5.56)
    swing_tank.setTankVolume(UnitConversions.convert(volume, 'gal', 'm^3'))
    # swing_tank.setAmbientTemperatureZone # FIXME: What zone do we want to assume the tanks are in?
    swing_tank.setUniformSkinLossCoefficientperUnitAreatoAmbientTemperature(tank_u) # FIXME: typical loss values?
    swing_tank.setSourceSideInletHeight(h_source_in)
    swing_tank.setSourceSideOutletHeight(h_source_out)
    swing_tank.setOffCycleParasiticFuelConsumptionRate(0.0)
    swing_tank.setOnCycleParasiticFuelConsumptionRate(0.0)
    swing_tank.setNumberofNodes(6)
    swing_tank.setEndUseSubcategory(name)

    swing_tank.addToNode(recirculation_loop.supplyOutletNode)
  end

  def add_heat_exchanger(model, dhw_loop, source_loop, name)
    hx = OpenStudio::Model::HeatExchangerFluidToFluid.new(model)
    hx.setName(name)

    dhw_loop.addSupplyBranchForComponent(hx)
    source_loop.addDemandBranchForComponent(hx)
  end

  def add_heat_pump(model, fuel_type, heat_pump_loop, name)
    if fuel_type == HPXML::FuelTypeElectricity
      heat_pump = OpenStudio::Model::WaterHeaterHeatPump.new(model) # FIXME: this may not be simulating succesfully currently
    elsif fuel_type == HPXML::FuelTypeNaturalGas
      heat_pump = OpenStudio::Model::HeatPumpAirToWaterFuelFiredHeating.new(model)
      heat_pump.setFuelType(EPlus.fuel_type(fuel_type))
      heat_pump.setEndUseSubcategory(name)
      heat_pump.setNominalAuxiliaryElectricPower(0)
      heat_pump.setStandbyElectricPower(0)
    end

    heat_pump.setName(name)
    heat_pump_loop.addSupplyBranchForComponent(heat_pump)

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

  def disaggregate_heating_vs_how_water(model, heat_pump_loop, storage_tank)
    # Clone the heat pump loop
    # Zero out the pump (?)
    # The storage tank goes on the demand side of this (cloned) loop
    # What about all the apply_combi_system_EMS stuff?

    heat_pump_loop_hw = heat_pump_loop.clone(model).to_PlantLoop.get
    heat_pump_loop_hw.setName('Heat Pump Loop HW')

    heat_pump_hw = nil
    heat_pump_loop_hw.supplyComponents.each do |supply_component|
      if supply_component.to_HeatPumpAirToWaterFuelFiredHeating.is_initialized
        heat_pump_hw = supply_component.to_HeatPumpAirToWaterFuelFiredHeating.get
        heat_pump_hw.setName('Heat Pump Water Heater HW')
        heat_pump_hw.additionalProperties.setFeature('IsCombiHP', true) # Used by reporting measure
      end
      next unless supply_component.to_PumpConstantSpeed.is_initialized

      pump_hw = supply_component.to_PumpConstantSpeed.get
      pump_hw.setRatedPowerConsumption(0.0)
    end

    heat_pump_loop_hw.addDemandBranchForComponent(storage_tank)
  end

  def remove_loops(model, shared_hpwh_type)
    plant_loop_to_remove = [
      'dhw loop',
      'solar hot water loop'
    ]
    plant_loop_to_remove += ['boiler hydronic heat loop'] if shared_hpwh_type == 'space-heating hpwh'
    plant_loop_to_remove += plant_loop_to_remove.map { |p| p.gsub(' ', '_') }
    model.getPlantLoops.each do |plant_loop|
      if plant_loop_to_remove.select { |p| plant_loop.name.to_s.include?(p) }.size == 0
        next
      end

      plant_loop.remove
    end
  end

  def remove_ems(model, shared_hpwh_type)
    # ProgramCallingManagers / Programs
    ems_pcm_to_remove = [
      'water heater EC_adj ProgramManager',
      'water heater ProgramManager',
      'water heater hpwh EC_adj ProgramManager',
      'solar hot water Control' # FIXME: this may be a nonfactor if GAHP is only applied (sampled) for buildings without solar hw
    ]
    ems_pcm_to_remove += [
      'boiler hydronic pump power program calling manager',
      'boiler hydronic pump disaggregate program calling manager'
    ] if shared_hpwh_type == 'space-heating hpwh'
    ems_pcm_to_remove += ems_pcm_to_remove.map { |e| e.gsub(' ', '_') }
    model.getEnergyManagementSystemProgramCallingManagers.each do |ems_pcm|
      if ems_pcm_to_remove.select { |e| ems_pcm.name.to_s.include?(e) }.size == 0
        next
      end

      ems_pcm.programs.each do |program|
        program.remove
      end
      ems_pcm.remove
    end

    # Sensors
    ems_sensor_to_remove = [
      'water heater energy',
      'water heater fan',
      'water heater off cycle',
      'water heater on cycle',
      'water heater tank',
      'water heater lat',
      'water heater sens',
      'water heater coil',
      'water heater tl',
      'water heater hpwh',
      'solar hot water Collector',
      'solar hot water Tank'
    ]
    ems_sensor_to_remove += [
      'boiler hydronic pump',
      'boiler plr'
    ] if shared_hpwh_type == 'space-heating hpwh'
    ems_sensor_to_remove += ems_sensor_to_remove.map { |e| e.gsub(' ', '_') }
    model.getEnergyManagementSystemSensors.each do |ems_sensor|
      if ems_sensor_to_remove.select { |e| ems_sensor.name.to_s.include?(e) }.size == 0
        next
      end

      ems_sensor.remove
    end

    # OutputVariables
    ems_outvar_to_remove = []
    ems_outvar_to_remove += [
      'boiler hydronic pump disaggregate htg primary'
    ] if shared_hpwh_type == 'space-heating hpwh'
    ems_outvar_to_remove += ems_outvar_to_remove.map { |e| e.gsub(' ', '_') } if !ems_outvar_to_remove.empty?
    model.getEnergyManagementSystemOutputVariables.each do |ems_output_variable|
      if ems_outvar_to_remove.select { |e| ems_output_variable.name.to_s.include?(e) }.size == 0
        next
      end

      ems_output_variable.remove
    end

    # InternalVariables
    ems_intvar_to_remove = []
    ems_intvar_to_remove += [
      'boiler hydronic pump rated mfr'
    ] if shared_hpwh_type == 'space-heating hpwh'
    ems_intvar_to_remove += ems_intvar_to_remove.map { |e| e.gsub(' ', '_') } if !ems_intvar_to_remove.empty?
    model.getEnergyManagementSystemInternalVariables.each do |ems_internal_variable|
      if ems_intvar_to_remove.select { |e| ems_internal_variable.name.to_s.include?(e) }.size == 0
        next
      end

      ems_internal_variable.remove
    end
  end

  def lambert(x)
    # Lambert W function using Newton's method
    eps = 0.00000001 # max error allowed
    w = x
    while true
      ew = Math.exp(w)
      wNew = w - (w * ew - x) / (w * ew + ew)
      break if (w - wNew).abs <= eps

      w = wNew
    end
    return x
  end
end

# register the measure to be used by the application
AddSharedHPWH.new.registerWithApplication
