# frozen_string_literal: true

require_relative 'resources/constants.rb'

# start the measure
class AddSharedWaterHeater < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    return 'AddSharedWaterHeater'
  end

  # human readable description
  def description
    return "Replace in-unit water heaters and boilers with shared '#{Constants.WaterHeaterTypeHeatPump}', '#{Constants.WaterHeaterTypeCombiHeatPump}', or '#{Constants.WaterHeaterTypeCombiBoiler}'. This measure assumes that water use connections (and optionally baseboards) already exist in the model."
  end

  # human readable description of modeling approach
  def modeler_description
    return 'Replace existing hot water loops and associated EMS objects. Add new supply loop(s) with water heating (and optionally space-heating) components on the supply side, and main storage and swing tanks (in series) on the demand side. Add new source (recirculation) loop with main storage and swing tanks on the supply side, and domestic hot water loop heat exchanger (and optionally space-heating loop heat exchanger) on the demand side. Add new domestic how water loop (and optionally space-heating loop) with heat exchanger(s) on the supply side, and water use connections (and optionally baseboards) on the demand side.'
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
    hpxml_path = File.expand_path('../home.xml') # this is the defaulted hpxml
    if File.exist?(hpxml_path)
      hpxml = HPXML.new(hpxml_path: hpxml_path)
    else
      runner.registerWarning("AddSharedWaterHeater: Could not find '#{hpxml_path}'.")
      return true
    end

    # Extension properties
    hpxml_bldg = hpxml.buildings[0]
    geometry_building_num_units = hpxml_bldg.header.extension_properties['geometry_building_num_units'].to_f
    num_stories = hpxml_bldg.header.extension_properties['geometry_num_floors_above_grade'].to_f
    has_double_loaded_corridor = hpxml_bldg.header.extension_properties['geometry_corridor_position']
    shared_water_heater_type = hpxml_bldg.header.extension_properties['shared_water_heater_type']
    shared_water_heater_fuel_type = hpxml_bldg.header.extension_properties['shared_water_heater_fuel_type']

    # Skip measure if no shared heating system
    if shared_water_heater_type == 'none'
      runner.registerAsNotApplicable('AddSharedWaterHeater: Building does not have shared water heater. Skipping...')
      return true
    end

    # TODO
    # 1: Remove any existing WHs and associated plant loops. Keep WaterUseEquipment objects.
    # 2: Add recirculation loop and piping. Use "Pipe:Indoor" objects, assume ~3 m of pipe per unit in the living zone of each.
    #    Each unit also needs a splitter: either to the next unit or this unit's WaterUseEquipment Objects. (this involves pipes in parallel/series. this may be handled in FT.)
    # 3: Add a recirculation pump (ConstantSpeed) to the loop. We'll use "AlwaysOn" logic, at least as a starting point.
    # 4: Add a new WaterHeater:Stratified object to represent the main storage tank.
    # 5: Add a swing tank in series: Ahead of the main WaterHeater:Stratified, another stratified tank model.
    #    This one includes an ER element to make up for loop losses.
    # 6: Add the GAHP(s). Will need to do some test runs when this is in to figure out how many units before we increase the # of HPs

    # Building -level information
    unit_multipliers = hpxml.buildings.collect { |hpxml_bldg| hpxml_bldg.building_construction.number_of_units }
    num_units = unit_multipliers.sum
    num_beds = hpxml.buildings.collect { |hpxml_bldg| hpxml_bldg.building_construction.number_of_units * hpxml_bldg.building_construction.number_of_bedrooms }.sum
    # FIXME: should these be relative to the number of MODELED units? i.e., hpxml.buildings.size? sounds like maybe no?
    # num_units = hpxml.buildings.size
    # num_beds = hpxml.buildings.collect { |hpxml_bldg| hpxml_bldg.building_construction.number_of_bedrooms }.sum

    # Calculate some size parameters: number of heat pumps, storage tank volume, number of tanks, swing tank volume
    # Sizing is based on CA code requirements: https://efiling.energy.ca.gov/GetDocument.aspx?tn=234434&DocumentContentId=67301
    # FIXME: How to adjust size when used for space heating?
    supply_count = ((0.037 * num_beds + 0.106 * num_units) * (154.0 / 123.5)).ceil # ratio is assumed capacity from code / nominal capacity from Robur spec sheet
    # supply_count *= 2 # FIXME
    if shared_water_heater_type.include?('space-heating')
      supply_count *= 4 # FIXME
    end

    # Storage tank volume
    # storage_tank_volume = 80.0 * supply_count
    # storage_tank_count = storage_tank_volume / 80.0 # TODO: Do we model these as x tanks in series or combine them into a single tank?
    storage_tank_volume = 80.0

    # Swing tank volume
    swing_tank_volume = 0.0
    if !shared_water_heater_type.include?('boiler')
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
    end

    # Setpoint Schedules
    dhw_loop_sp = 140.0
    dhw_loop_sp_schedule = OpenStudio::Model::ScheduleConstant.new(model)
    dhw_loop_sp_schedule.setValue(UnitConversions.convert(dhw_loop_sp, 'F', 'C'))

    other_loop_sp = 180.0 # FIXME: final setpoint? Should it vary if used for space heating?
    other_loop_sp_schedule = OpenStudio::Model::ScheduleConstant.new(model)
    other_loop_sp_schedule.setValue(UnitConversions.convert(other_loop_sp, 'F', 'C'))

    # Pipes
    supply_length, return_length = calc_recirc_supply_return_lengths(hpxml_bldg, num_units, num_stories, has_double_loaded_corridor)
    supply_pipe_ins_r_value = 6.0
    return_pipe_ins_r_value = 4.0

    # Pump Flow Rates
    supply_gpm = 13.6 # gal/min, nominal from Robur spec sheet
    dhw_gpm, swing_tank_capacity = calc_recirc_flow_rate(hpxml.buildings, supply_length, supply_pipe_ins_r_value)
    space_heating_gpm = 0.0
    source_gpm = dhw_gpm
    if shared_water_heater_type.include?('space-heating')
      space_heating_gpm = supply_gpm # FIXME
      source_gpm = supply_gpm # FIXME
    end

    # Add Loops
    # dhw_loop = add_loop(model, 'DHW Loop', dhw_loop_sp, 10.0, dhw_gpm)
    dhw_loop = add_loop(model, 'DHW Loop', dhw_loop_sp, 10.0, UnitConversions.convert(0.01, 'm^3/s', 'gal/min')) # 0.01 from OS-HPXML
    if shared_water_heater_type.include?('space-heating')
      space_heating_loop = add_loop(model, 'Space Heating Loop', other_loop_sp, 20.0, space_heating_gpm)
      # space_heating_loop = add_loop(model, 'Space Heating Loop', other_loop_sp, 20.0)
    end
    supply_loops = {}
    (1..supply_count).to_a.each do |i|
      # supply_loop = add_loop(model, "Supply Loop #{i}", other_loop_sp, 20.0, supply_gpm)
      supply_loop = add_loop(model, "Supply Loop #{i}", other_loop_sp, 20.0)
      supply_loops[supply_loop] = []
    end
    # source_loop = add_loop(model, 'Source Loop', other_loop_sp, 20.0, source_gpm)
    source_loop = add_loop(model, 'Source Loop', other_loop_sp, 20.0)

    # Add Adiabatic Pipes
    dhw_loop_demand_inlet, dhw_loop_demand_bypass = add_adiabatic_pipes(model, dhw_loop)
    if shared_water_heater_type.include?('space-heating')
      _space_heating_loop_demand_inlet, _space_heating_loop_demand_bypass = add_adiabatic_pipes(model, space_heating_loop)
    end
    supply_loops.each do |supply_loop, _|
      _heat_pump_loop_demand_inlet, _heat_pump_loop_demand_bypass = add_adiabatic_pipes(model, supply_loop)
    end
    _source_loop_demand_inlet, _source_loop_demand_bypass = add_adiabatic_pipes(model, source_loop)

    # Add Indoor Pipes
    add_indoor_pipes(model, dhw_loop_demand_inlet, dhw_loop_demand_bypass, supply_length, return_length, supply_pipe_ins_r_value, return_pipe_ins_r_value, num_units)

    # Add Pumps
    add_pump(model, dhw_loop, 'DHW Loop Pump', dhw_gpm)
    if shared_water_heater_type.include?('space-heating')
      add_pump(model, space_heating_loop, 'Space Heating Loop Pump', space_heating_gpm) # FIXME: need to re-consider the pump here
    end
    supply_loops.each do |supply_loop, _|
      add_pump(model, supply_loop, "#{supply_loop.name} Pump", supply_gpm)
    end
    add_pump(model, source_loop, 'Source Loop Pump', source_gpm)

    # Add Setpoint Managers
    add_setpoint_manager(model, dhw_loop, dhw_loop_sp_schedule, 'DHW Loop Setpoint Manager')
    if shared_water_heater_type.include?('space-heating')
      add_setpoint_manager(model, space_heating_loop, other_loop_sp_schedule, 'Space Heating Loop Setpoint Manager')
    end
    supply_loops.each do |supply_loop, _|
      add_setpoint_manager(model, supply_loop, other_loop_sp_schedule, "#{supply_loop.name} Setpoint Manager", 'Temperature')
    end
    add_setpoint_manager(model, source_loop, other_loop_sp_schedule, 'Source Loop Setpoint Manager', 'Temperature')

    # Add Tanks
    prev_storage_tank = nil
    supply_loops.each do |supply_loop, components|
      storage_tank = add_storage_tank(model, source_loop, supply_loop, storage_tank_volume, prev_storage_tank, "#{supply_loop.name} Main Storage Tank", shared_water_heater_fuel_type, dhw_loop_sp)
      storage_tank.additionalProperties.setFeature('ObjectType', Constants.ObjectNameSharedWaterHeater) # Used by reporting measure

      components << storage_tank
      prev_storage_tank = components[0]
    end
    swing_tank = add_swing_tank(model, prev_storage_tank, swing_tank_volume, swing_tank_capacity, 'Swing Tank', shared_water_heater_fuel_type, dhw_loop_sp)
    swing_tank.additionalProperties.setFeature('ObjectType', Constants.ObjectNameSharedWaterHeater) if !swing_tank.nil? # Used by reporting measure

    # Add Heat Exchangers
    add_heat_exchanger(model, dhw_loop, source_loop, 'DHW Heat Exchanger')
    if shared_water_heater_type.include?('space-heating')
      add_heat_exchanger(model, space_heating_loop, source_loop, 'Space Heating Heat Exchanger')
    end

    # Add Supply Components
    supply_loops.each do |supply_loop, components|
      components << add_component(model, shared_water_heater_type, shared_water_heater_fuel_type, supply_loop, "#{supply_loop.name} Water Heater")
    end

    # Add Availability Manager
    supply_loops.each do |supply_loop, components|
      storage_tank, component = components
      if component.to_BoilerHotWater.is_initialized || component.to_HeatPumpAirToWaterFuelFiredHeating.is_initialized
        hot_node = component.outletModelObject.get.to_Node.get
      elsif component.to_WaterHeaterStratified.is_initialized
        hot_node = component.supplyOutletModelObject.get.to_Node.get
      end
      cold_node = storage_tank.demandOutletModelObject.get.to_Node.get
      add_availability_manager(model, supply_loop, hot_node, cold_node)
    end

    # Re-connect WaterUseConections
    runner.registerValue('model.getWaterUseConnectionss.size', model.getWaterUseConnectionss.size)
    model.getWaterUseConnectionss.each do |wuc|
      wuc.setName("#{wuc.name}_reconnected")
      # wuc.additionalProperties.setFeature('ObjectType', Constants.ObjectNameSharedWaterHeater) # Used by reporting measure
      dhw_loop.addDemandBranchForComponent(wuc)
    end

    # Re-connect CoilHeatingWaterBaseboards
    runner.registerValue('model.getCoilHeatingWaterBaseboards.size', model.getCoilHeatingWaterBaseboards.size)
    if shared_water_heater_type.include?('space-heating')
      if model.getCoilHeatingWaterBaseboards.size > 0 # no existing baseboards(s)
        model.getCoilHeatingWaterBaseboards.each do |chwb|
          chwb.setName("#{chwb.name}_reconnected")
          chwb.additionalProperties.setFeature('ObjectType', Constants.ObjectNameSharedWaterHeater) # Used by reporting measure
          space_heating_loop.addDemandBranchForComponent(chwb)
        end

        # disaggregate_heating_vs_how_water(model, supply_loop, storage_tank) # FIXME: doesn't work if both distribution loops go through the source loop
      end
    end

    # Remove Existing
    remove_loops(runner, model, shared_water_heater_type)
    remove_ems(runner, model, shared_water_heater_type)

    # Register values
    runner.registerValue('geometry_building_num_units', geometry_building_num_units)
    runner.registerValue('geometry_building_num_units_modeled', hpxml.buildings.size)
    runner.registerValue('unit_multipliers', unit_multipliers.join(','))
    runner.registerValue('shared_water_heater_type', shared_water_heater_type)
    runner.registerValue('shared_water_heater_fuel_type', shared_water_heater_fuel_type)
    runner.registerValue('num_units', num_units)
    runner.registerValue('num_beds', num_beds)
    runner.registerValue('supply_count', supply_count)
    runner.registerValue('storage_tank_volume', storage_tank_volume)
    runner.registerValue('swing_tank_volume', swing_tank_volume)
    runner.registerValue('dhw_loop_sp_f', dhw_loop_sp)
    runner.registerValue('other_loop_sp_f', other_loop_sp)
    runner.registerValue('supply_length_ft', supply_length)
    runner.registerValue('return_length_ft', return_length)
    runner.registerValue('supply_gpm', supply_gpm)
    runner.registerValue('dhw_gpm', dhw_gpm)
    runner.registerValue('space_heating_gpm', space_heating_gpm)
    runner.registerValue('source_gpm', source_gpm)
    runner.registerValue('swing_tank_capacity', swing_tank_capacity)

    return true
  end

  def add_loop(model, name, design_temp, deltaF = 20.0, max_gpm = nil)
    loop = OpenStudio::Model::PlantLoop.new(model)
    loop.setName(name)
    loop.setMaximumLoopFlowRate(UnitConversions.convert(max_gpm, 'gal/min', 'm^3/s')) if !max_gpm.nil? # FIXME

    loop_sizing = loop.sizingPlant
    loop_sizing.setLoopType('Heating')
    loop_sizing.setDesignLoopExitTemperature(UnitConversions.convert(design_temp, 'F', 'C'))
    loop_sizing.setLoopDesignTemperatureDifference(UnitConversions.convert(deltaF, 'deltaF', 'deltaC'))

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

  def add_indoor_pipes(model, demand_inlet, demand_bypass, supply_length, return_length, supply_pipe_ins_r_value, return_pipe_ins_r_value, _n_units)
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
      next if thermal_zone.volume.is_initialized && thermal_zone.volume.get <= 1 # skip the return air plenum zone

      # Supply
      dhw_recirc_supply_pipe = OpenStudio::Model::PipeIndoor.new(model)
      dhw_recirc_supply_pipe.setName("Recirculation Supply Pipe - #{thermal_zone.name}")
      dhw_recirc_supply_pipe.setAmbientTemperatureZone(thermal_zone)
      dhw_recirc_supply_pipe.setConstruction(insulated_supply_pipe_construction)
      dhw_recirc_supply_pipe.setPipeInsideDiameter(UnitConversions.convert(supply_diameter, 'in', 'm'))
      # dhw_recirc_supply_pipe.setPipeLength(UnitConversions.convert(supply_length / n_units, 'ft', 'm')) # FIXME
      dhw_recirc_supply_pipe.setPipeLength(UnitConversions.convert(supply_length / thermal_zone.multiplier, 'ft', 'm'))

      dhw_recirc_supply_pipe.addToNode(demand_inlet.outletModelObject.get.to_Node.get) # FIXME: check IDF branches to make sure everything looks ok

      # Return
      dhw_recirc_return_pipe = OpenStudio::Model::PipeIndoor.new(model)
      dhw_recirc_return_pipe.setName("Recirculation Return Pipe - #{thermal_zone.name}")
      dhw_recirc_return_pipe.setAmbientTemperatureZone(thermal_zone)
      dhw_recirc_return_pipe.setConstruction(insulated_return_pipe_construction)
      dhw_recirc_return_pipe.setPipeInsideDiameter(UnitConversions.convert(return_diameter, 'in', 'm'))
      # dhw_recirc_return_pipe.setPipeLength(UnitConversions.convert(return_length / n_units, 'ft', 'm')) # FIXME
      dhw_recirc_return_pipe.setPipeLength(UnitConversions.convert(return_length / thermal_zone.multiplier, 'ft', 'm'))

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

  def calc_recirc_flow_rate(_hpxml_buildings, supply_length, supply_pipe_ins_r_value)
    # ASHRAE calculation of the recirculation loop flow rate
    # Based on Equation 9 on p50.7 in 2011 ASHRAE Handbook--HVAC Applications

    # avg_num_bath = 0
    # avg_ffa = 0
    len_ins = 0
    len_unins = 0
    # hpxml_buildings.each do |hpxml_bldg|
    # avg_num_bath += hpxml_bldg.building_construction.number_of_bathrooms / hpxml_buildings.size
    # avg_ffa += hpxml_bldg.building_construction.conditioned_floor_area / hpxml_buildings.size
    # end

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
    pump.additionalProperties.setFeature('ObjectType', Constants.ObjectNameSharedWaterHeater) # Used by reporting measure
  end

  def add_setpoint_manager(model, loop, schedule, name, control_variable = nil)
    manager = OpenStudio::Model::SetpointManagerScheduled.new(model, schedule)
    manager.setName(name)
    manager.setControlVariable(control_variable) if !control_variable.nil?
    manager.addToNode(loop.supplyOutletNode)
  end

  def add_storage_tank(model, source_loop, heat_pump_loop, volume, prev_storage_tank, name, fuel_type, setpoint)
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
    storage_tank.setTankVolume(UnitConversions.convert(volume, 'gal', 'm^3'))
    storage_tank.setHeater1Capacity(capacity)
    storage_tank.setHeater2Capacity(capacity)
    setpoint_schedule = OpenStudio::Model::ScheduleConstant.new(model)
    setpoint_schedule.setName("#{name} Temperature Schedule")
    setpoint_schedule.setValue(UnitConversions.convert(setpoint, 'F', 'C'))
    storage_tank.setHeater1SetpointTemperatureSchedule(setpoint_schedule)
    storage_tank.setHeater2SetpointTemperatureSchedule(setpoint_schedule)
    # storage_tank.setAmbientTemperatureZone # FIXME: What zone do we want to assume the tanks are in?
    storage_tank.setUniformSkinLossCoefficientperUnitAreatoAmbientTemperature(tank_u) # FIXME: typical loss values?
    storage_tank.setSourceSideInletHeight(h_source_in)
    storage_tank.setSourceSideOutletHeight(h_source_out)
    storage_tank.setOffCycleParasiticFuelConsumptionRate(0.0)
    storage_tank.setOnCycleParasiticFuelConsumptionRate(0.0)
    storage_tank.setNumberofNodes(6)
    storage_tank.setUseSideDesignFlowRate(UnitConversions.convert(volume, 'gal', 'm^3') / 60.1) # Sized to ensure that E+ never autosizes the design flow rate to be larger than the tank volume getting drawn out in a hour (60 minutes)
    # storage_tank.setSourceSideDesignFlowRate() # FIXME
    storage_tank.setEndUseSubcategory(name)
    storage_tank.setHeaterFuelType(EPlus.fuel_type(fuel_type))
    if heat_pump_loop.nil? # stratified tank on supply side of source loop (e.g., shared electric hpwh)
      storage_tank.setHeaterThermalEfficiency(1.0)
      storage_tank.setAdditionalDestratificationConductivity(0)
      storage_tank.setSourceSideDesignFlowRate(0)
      storage_tank.setSourceSideFlowControlMode('')
      storage_tank.setSourceSideInletHeight(0)
      storage_tank.setSourceSideOutletHeight(0)
    end

    if prev_storage_tank.nil?
      source_loop.addSupplyBranchForComponent(storage_tank) # first one is a new supply branch
    else
      storage_tank.addToNode(prev_storage_tank.useSideOutletModelObject.get.to_Node.get) # remaining are added in series
    end
    if !heat_pump_loop.nil?
      heat_pump_loop.addDemandBranchForComponent(storage_tank)
    end

    return storage_tank
  end

  def add_swing_tank(model, last_storage_tank, volume, capacity, name, fuel_type, setpoint)
    return if volume == 0

    # this would be in series with the main storage tanks, downstream of it
    # this does not go on the demand side of the supply loop, like the main storage tank does
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
    swing_tank.setTankVolume(UnitConversions.convert(volume, 'gal', 'm^3'))
    swing_tank.setHeaterPriorityControl('MasterSlave')
    swing_tank.setHeater1Capacity(capacity)
    swing_tank.setHeater1Height(h_ue)
    swing_tank.setHeater1DeadbandTemperatureDifference(5.56) # 10 F
    swing_tank.setHeater2Capacity(capacity)
    swing_tank.setHeater2Height(h_le)
    swing_tank.setHeater2DeadbandTemperatureDifference(5.56)
    setpoint_schedule = OpenStudio::Model::ScheduleConstant.new(model)
    setpoint_schedule.setName("#{name} Temperature Schedule")
    setpoint_schedule.setValue(UnitConversions.convert(setpoint, 'F', 'C'))
    swing_tank.setHeater1SetpointTemperatureSchedule(setpoint_schedule)
    swing_tank.setHeater2SetpointTemperatureSchedule(setpoint_schedule)
    # swing_tank.setAmbientTemperatureZone # FIXME: What zone do we want to assume the tanks are in?
    swing_tank.setUniformSkinLossCoefficientperUnitAreatoAmbientTemperature(tank_u) # FIXME: typical loss values?
    swing_tank.setSourceSideInletHeight(h_source_in)
    swing_tank.setSourceSideOutletHeight(h_source_out)
    swing_tank.setOffCycleParasiticFuelConsumptionRate(0.0)
    swing_tank.setOnCycleParasiticFuelConsumptionRate(0.0)
    swing_tank.setNumberofNodes(6)
    swing_tank.setUseSideDesignFlowRate(UnitConversions.convert(volume, 'gal', 'm^3') / 60.1) # Sized to ensure that E+ never autosizes the design flow rate to be larger than the tank volume getting drawn out in a hour (60 minutes)
    # swing_tank.setSourceSideDesignFlowRate() # FIXME
    swing_tank.setEndUseSubcategory(name)
    swing_tank.setHeaterFuelType(EPlus.fuel_type(fuel_type))

    swing_tank.addToNode(last_storage_tank.useSideOutletModelObject.get.to_Node.get) # in series
    # swing_tank.addToNode(source_loop.supplyOutletNode)

    return swing_tank
  end

  def add_heat_exchanger(model, dhw_loop, source_loop, name)
    hx = OpenStudio::Model::HeatExchangerFluidToFluid.new(model)
    # hx.setControlType('OperationSchemeModulated') # FIXME: this causes a bunch of zero rows for Fuel-fired Absorption HeatPump Electricity Energy: Supply Loop 1 Water Heater
    hx.setName(name)

    dhw_loop.addSupplyBranchForComponent(hx)
    source_loop.addDemandBranchForComponent(hx)
  end

  def add_component(model, system_type, fuel_type, supply_loop, name)
    if system_type.include?('boiler')
      component = OpenStudio::Model::BoilerHotWater.new(model)
      component.setName(name)
      component.setFuelType(EPlus.fuel_type(fuel_type))
      component.setMinimumPartLoadRatio(0.0)
      component.setMaximumPartLoadRatio(1.0)
      component.setBoilerFlowMode('LeavingSetpointModulated')
      component.setNominalCapacity(40000) # FIXME
      component.setOptimumPartLoadRatio(1.0)
      component.setWaterOutletUpperTemperatureLimit(99.9)
      component.setOnCycleParasiticElectricLoad(0)
      component.additionalProperties.setFeature('IsCombiBoiler', true) # Used by reporting measure
      # component.setDesignWaterFlowRate() # FIXME
      supply_loop.addSupplyBranchForComponent(component)
    elsif system_type.include?('heat pump water heater')
      if fuel_type == HPXML::FuelTypeElectricity
        component = OpenStudio::Model::WaterHeaterHeatPump.new(model)
        tank = add_storage_tank(model, supply_loop, nil, 80.0, nil, name, fuel_type)
        tank.additionalProperties.setFeature('IsCombiBoiler', true) # Used by reporting measure
        component.setTank(tank)
        fan = component.fan
        fan.additionalProperties.setFeature('ObjectType', Constants.ObjectNameWaterHeater) # Used by reporting measure
        component = tank
      else
        component = OpenStudio::Model::HeatPumpAirToWaterFuelFiredHeating.new(model)
        component.setName(name)
        component.setFuelType(EPlus.fuel_type(fuel_type))
        # component.setFlowMode('LeavingSetpointModulated') # FIXME: this almost zeros out Fuel-fired Absorption HeatPump Electricity Energy: Supply Loop 1 Water Heater
        component.setNominalHeatingCapacity(40000) # FIXME
        component.setNominalAuxiliaryElectricPower(0)
        component.setStandbyElectricPower(0)
        # if system_type.include?('space-heating')
        # component.additionalProperties.setFeature('IsCombiHP', true) # Used by reporting measure
        # end
        # component.setDesignFlowRate() # FIXME
        supply_loop.addSupplyBranchForComponent(component)
      end
    end

    return component
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

  def remove_loops(runner, model, shared_water_heater_type)
    plant_loop_to_remove = [
      'dhw loop',
      'solar hot water loop'
    ]
    plant_loop_to_remove += ['boiler hydronic heat loop'] if shared_water_heater_type.include?('space-heating')
    plant_loop_to_remove += plant_loop_to_remove.map { |p| p.gsub(' ', '_') }
    model.getPlantLoops.each do |plant_loop|
      next if plant_loop_to_remove.select { |p| plant_loop.name.to_s.include?(p) }.size == 0

      runner.registerInfo("#{plant_loop.class} '#{plant_loop.name}' removed.")
      plant_loop.remove
    end
  end

  def remove_ems(runner, model, shared_water_heater_type)
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
    ] if shared_water_heater_type.include?('space-heating')
    ems_pcm_to_remove += ems_pcm_to_remove.map { |e| e.gsub(' ', '_') }
    model.getEnergyManagementSystemProgramCallingManagers.each do |ems_pcm|
      next if ems_pcm_to_remove.select { |e| ems_pcm.name.to_s.include?(e) }.size == 0

      ems_pcm.programs.each do |program|
        runner.registerInfo("#{program.class} '#{program.name}' removed.")
        program.remove
      end
      runner.registerInfo("#{ems_pcm.class} '#{ems_pcm.name}' removed.")
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
    ] if shared_water_heater_type.include?('space-heating')
    ems_sensor_to_remove += ems_sensor_to_remove.map { |e| e.gsub(' ', '_') }
    model.getEnergyManagementSystemSensors.each do |ems_sensor|
      next if ems_sensor_to_remove.select { |e| ems_sensor.name.to_s.include?(e) }.size == 0

      runner.registerInfo("#{ems_sensor.class} '#{ems_sensor.name}' removed.")
      ems_sensor.remove
    end

    # Actuators
    ems_actuator_to_remove = []
    ems_actuator_to_remove += [
      'boiler hydronic pump'
    ] if shared_water_heater_type.include?('space-heating')
    ems_actuator_to_remove += ems_actuator_to_remove.map { |e| e.gsub(' ', '_') }
    model.getEnergyManagementSystemActuators.each do |ems_actuator|
      next if ems_actuator_to_remove.select { |e| ems_actuator.name.to_s.include?(e) }.size == 0

      runner.registerInfo("#{ems_actuator.class} '#{ems_actuator.name}' removed.")
      ems_actuator.remove
    end

    # OutputVariables
    ems_outvar_to_remove = []
    ems_outvar_to_remove += [
      'boiler hydronic pump disaggregate htg primary'
    ] if shared_water_heater_type.include?('space-heating')
    ems_outvar_to_remove += ems_outvar_to_remove.map { |e| e.gsub(' ', '_') } if !ems_outvar_to_remove.empty?
    model.getEnergyManagementSystemOutputVariables.each do |ems_output_variable|
      next if ems_outvar_to_remove.select { |e| ems_output_variable.name.to_s.include?(e) }.size == 0

      runner.registerInfo("#{ems_output_variable.class} '#{ems_output_variable.name}' removed.")
      ems_output_variable.remove
    end

    # InternalVariables
    ems_intvar_to_remove = []
    ems_intvar_to_remove += [
      'boiler hydronic pump rated mfr'
    ] if shared_water_heater_type.include?('space-heating')
    ems_intvar_to_remove += ems_intvar_to_remove.map { |e| e.gsub(' ', '_') } if !ems_intvar_to_remove.empty?
    model.getEnergyManagementSystemInternalVariables.each do |ems_internal_variable|
      next if ems_intvar_to_remove.select { |e| ems_internal_variable.name.to_s.include?(e) }.size == 0

      runner.registerInfo("#{ems_internal_variable.class} '#{ems_internal_variable.name}' removed.")
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
AddSharedWaterHeater.new.registerWithApplication
