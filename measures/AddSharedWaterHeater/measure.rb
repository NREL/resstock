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
    return "Replace in-unit water heaters and boilers with shared '#{Constants.WaterHeaterTypeHeatPump}', '#{Constants.WaterHeaterTypeBoiler}', '#{Constants.WaterHeaterTypeCombiHeatPump}', or '#{Constants.WaterHeaterTypeCombiBoiler}'. This measure assumes that water use connections (and optionally baseboards) already exist in the model."
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
    num_stories = hpxml_bldg.header.extension_properties['geometry_num_floors_above_grade'].to_f
    has_double_loaded_corridor = hpxml_bldg.header.extension_properties['geometry_corridor_position']
    shared_water_heater_type = hpxml_bldg.header.extension_properties['shared_water_heater_type']
    shared_water_heater_fuel_type = hpxml_bldg.header.extension_properties['shared_water_heater_fuel_type']

    # Skip measure if no shared heating system
    if shared_water_heater_type == 'none'
      runner.registerAsNotApplicable('AddSharedWaterHeater: Building does not have shared water heater. Skipping...')
      return true
    end
    # return true

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

    # Storage tank volume
    # TODO: Do we model these as x tanks in series or combine them into a single tank?
    # Right now we have single tank for boiler and x 80 gal tanks in series for HP
    storage_tank_volume = 80.0

    # why is the inlet temp so high?
    # look at loop types in os-resources?
    # look at boiler vs gahp curves?
    # try removing the swing tank?
    # compare plant loop volumes
    # storage tank max temp limit

    # Get existing capacities
    water_heating_capacity = get_total_water_heating_capacity(model)
    space_heating_capacity = get_total_space_heating_capacity(model)
    water_heating_tank_volume = get_total_water_heating_tank_volume(model)
    boiler_efficiency_curve = get_boiler_efficiency_curve(model)

    if shared_water_heater_type == Constants.WaterHeaterTypeBoiler
      supply_count = 1
      supply_capacity = water_heating_capacity
      storage_tank_volume = water_heating_tank_volume
    elsif shared_water_heater_type == Constants.WaterHeaterTypeHeatPump
      # supply_count *= 2
      supply_capacity = 36194
    elsif shared_water_heater_type == Constants.WaterHeaterTypeCombiBoiler
      supply_count = 1
      supply_capacity = 3 * (water_heating_capacity + space_heating_capacity) # FIXME
      storage_tank_volume = 3 * water_heating_tank_volume # FIXME
    elsif shared_water_heater_type == Constants.WaterHeaterTypeCombiHeatPump
      supply_count *= 2 # FIXME
      supply_capacity = 36194
    end

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

    # Pipes
    supply_length, return_length = calc_recirc_supply_return_lengths(hpxml_bldg, num_units, num_stories, has_double_loaded_corridor)
    supply_pipe_ins_r_value = 6.0
    return_pipe_ins_r_value = 4.0

    # Flow Rates (gal/min)
    dhw_loop_gpm = UnitConversions.convert(0.01, 'm^3/s', 'gal/min') * num_units # OS-HPXML
    dhw_pump_gpm, swing_tank_capacity = calc_recirc_flow_rate(hpxml.buildings, supply_length, supply_pipe_ins_r_value, swing_tank_volume)

    pump_head = nil
    pump_w = nil
    if shared_water_heater_type == Constants.WaterHeaterTypeBoiler
      gpm = nil

      supply_loop_gpm = gpm
      source_loop_gpm = gpm

      supply_pump_gpm = gpm
      source_pump_gpm = gpm

      pump_head = 20000
      pump_w = 10
    elsif shared_water_heater_type == Constants.WaterHeaterTypeHeatPump
      # gpm = 13.6 # nominal from Robur spec sheet
      gpm = nil

      supply_loop_gpm = gpm
      source_loop_gpm = gpm

      supply_pump_gpm = gpm
      source_pump_gpm = gpm

      pump_head = 20000
      pump_w = 10
    elsif shared_water_heater_type == Constants.WaterHeaterTypeCombiBoiler
      gpm = nil

      supply_loop_gpm = gpm
      source_loop_gpm = gpm
      space_heating_loop_gpm = gpm

      supply_pump_gpm = gpm
      source_pump_gpm = gpm
      space_heating_pump_gpm = gpm

      pump_head = 20000
      pump_w = 150
    elsif shared_water_heater_type == Constants.WaterHeaterTypeCombiHeatPump
      # gpm = 13.6 # nominal from Robur spec sheet
      gpm = nil

      supply_loop_gpm = gpm
      source_loop_gpm = gpm
      space_heating_loop_gpm = gpm

      supply_pump_gpm = gpm
      source_pump_gpm = gpm
      space_heating_pump_gpm = gpm

      pump_head = 20000
      pump_w = 20
    end

    # Setpoints (deg-F)
    # dhw_loop_sp = 130.0
    # dhw_loop_sp = 135.0
    dhw_loop_sp = 140.0
    if shared_water_heater_type == Constants.WaterHeaterTypeBoiler
      supply_loop_sp = 180.0
      source_loop_sp = supply_loop_sp
      space_heating_loop_sp = nil
    elsif shared_water_heater_type == Constants.WaterHeaterTypeHeatPump
      supply_loop_sp = 140.0
      source_loop_sp = supply_loop_sp
      space_heating_loop_sp = nil
    elsif shared_water_heater_type == Constants.WaterHeaterTypeCombiBoiler
      supply_loop_sp = 180.0
      source_loop_sp = supply_loop_sp
      space_heating_loop_sp = 180.0
    elsif shared_water_heater_type == Constants.WaterHeaterTypeCombiHeatPump
      supply_loop_sp = 140.0
      source_loop_sp = supply_loop_sp
      space_heating_loop_sp = 180.0 # this has a boiler on it
    end

    supply_loop_sp_schedule = OpenStudio::Model::ScheduleConstant.new(model)
    supply_loop_sp_schedule.setValue(UnitConversions.convert(supply_loop_sp, 'F', 'C'))

    source_loop_sp_schedule = OpenStudio::Model::ScheduleConstant.new(model)
    source_loop_sp_schedule.setValue(UnitConversions.convert(source_loop_sp, 'F', 'C'))

    if !space_heating_loop_sp.nil?
      space_heating_loop_sp_schedule = OpenStudio::Model::ScheduleConstant.new(model)
      space_heating_loop_sp_schedule.setValue(UnitConversions.convert(space_heating_loop_sp, 'F', 'C'))
    end

    dhw_loop_sp_schedule = OpenStudio::Model::ScheduleConstant.new(model)
    dhw_loop_sp_schedule.setValue(UnitConversions.convert(dhw_loop_sp, 'F', 'C'))

    # Add Loops
    loop_temp_diff = 20.0
    dhw_loop = add_loop(model, 'DHW Loop', dhw_loop_sp, 10.0, dhw_loop_gpm, num_units)
    if shared_water_heater_type.include?('space-heating')
      space_heating_loop = add_loop(model, 'Space Heating Loop', space_heating_loop_sp, loop_temp_diff, space_heating_loop_gpm)
    end
    supply_loops = {}
    (1..supply_count).to_a.each do |i|
      supply_loop = add_loop(model, "Supply Loop #{i}", supply_loop_sp, loop_temp_diff, supply_loop_gpm)
      supply_loops[supply_loop] = []
    end
    source_loop = add_loop(model, 'Source Loop', source_loop_sp, loop_temp_diff, source_loop_gpm)

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
    add_pump(model, dhw_loop, dhw_loop_gpm, 1, 0)
    if shared_water_heater_type.include?('space-heating')
      # add_pump(model, space_heating_loop, space_heating_pump_gpm)
      add_pump(model, space_heating_loop, space_heating_pump_gpm, pump_head, pump_w)
    end
    supply_loops.each do |supply_loop, _|
      # add_pump(model, supply_loop, supply_pump_gpm)
      add_pump(model, supply_loop, supply_pump_gpm, pump_head, pump_w)
    end
    # add_pump(model, source_loop, source_pump_gpm)
    add_pump(model, source_loop, source_pump_gpm, pump_head, pump_w)

    # Add Setpoint Managers
    add_setpoint_manager(model, dhw_loop, dhw_loop_sp_schedule)
    if shared_water_heater_type.include?('space-heating')
      add_setpoint_manager(model, space_heating_loop, space_heating_loop_sp_schedule)
    end
    supply_loops.each do |supply_loop, _|
      add_setpoint_manager(model, supply_loop, supply_loop_sp_schedule)
    end
    add_setpoint_manager(model, source_loop, source_loop_sp_schedule)

    # Add Tanks
    prev_storage_tank = nil
    supply_loops.each do |supply_loop, components|
      storage_tank = add_storage_tank(model, source_loop, supply_loop, storage_tank_volume, prev_storage_tank, "#{supply_loop.name} Main Storage Tank", shared_water_heater_fuel_type, supply_loop_sp)
      storage_tank.additionalProperties.setFeature('ObjectType', Constants.ObjectNameSharedWaterHeater) # Used by reporting measure

      components << storage_tank
      prev_storage_tank = components[0]
    end
    swing_tank = add_swing_tank(model, prev_storage_tank, swing_tank_volume, swing_tank_capacity, 'Swing Tank', shared_water_heater_fuel_type, supply_loop_sp)
    swing_tank.additionalProperties.setFeature('ObjectType', Constants.ObjectNameSharedWaterHeater) if !swing_tank.nil? # Used by reporting measure

    # Add Heat Exchangers
    add_heat_exchanger(model, dhw_loop, source_loop, 'DHW Heat Exchanger')
    if shared_water_heater_type.include?('space-heating')
      space_heating_hx = add_heat_exchanger(model, space_heating_loop, source_loop, 'Space Heating Heat Exchanger')
    end

    # Add Space Heating Component
    if shared_water_heater_type == Constants.WaterHeaterTypeCombiHeatPump
      component = add_component(model, 'boiler', shared_water_heater_fuel_type, space_heating_loop, "#{space_heating_loop.name} Space Heater", space_heating_capacity, boiler_efficiency_curve)
      component.addToNode(space_heating_hx.supplyOutletModelObject.get.to_Node.get)
    end

    # Add Supply Components
    supply_loops.each do |supply_loop, components|
      component = add_component(model, shared_water_heater_type, shared_water_heater_fuel_type, supply_loop, "#{supply_loop.name} Water Heater", supply_capacity, boiler_efficiency_curve)

      # Curves
      if component.to_HeatPumpAirToWaterFuelFiredHeating.is_initialized
        # cap_func_temp, eir_func_temp, eir_func_plr, eir_defrost_adj, cycling_ratio_factor, aux_eir_func_temp, aux_eir_func_plr = get_heat_pump_air_to_water_fuel_fired_heating_curves(model, component)
        # component.setNormalizedCapacityFunctionofTemperatureCurve(cap_func_temp)
        # component.setFuelEnergyInputRatioFunctionofTemperatureCurve(eir_func_temp)
        # component.setFuelEnergyInputRatioFunctionofPLRCurve(eir_func_plr)
        # component.setFuelEnergyInputRatioDefrostAdjustmentCurve(eir_defrost_adj)
        # component.setCyclingRatioFactorCurve(cycling_ratio_factor)
        # component.setAuxiliaryElectricEnergyInputRatioFunctionofTemperatureCurve(aux_eir_func_temp)
        # component.setAuxiliaryElectricEnergyInputRatioFunctionofPLRCurve(aux_eir_func_plr)
      end

      components << component
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
    reconnected_water_heatings = 0
    model.getWaterUseConnectionss.each do |wuc|
      wuc.setName("#{wuc.name}_reconnected")
      dhw_loop.addDemandBranchForComponent(wuc)
      reconnected_water_heatings += 1
    end

    # Re-connect CoilHeatingWaterBaseboards
    reconnected_space_heatings = 0
    if shared_water_heater_type.include?('space-heating')
      coil_heating_water_baseboards = model.getCoilHeatingWaterBaseboards
      coil_heating_waters = model.getCoilHeatingWaters
      coil_cooling_waters = model.getCoilCoolingWaters

      coil_heating_water_baseboards.each do |chwb|
        chwb.setName("#{chwb.name}_reconnected")
        space_heating_loop.addDemandBranchForComponent(chwb)
        reconnected_space_heatings += 1
      end

      coil_heating_waters.each do |chw|
        chw.setName("#{chw.name}_reconnected")
        space_heating_loop.addDemandBranchForComponent(chw)
        reconnected_space_heatings += 1
      end

      coil_cooling_waters.each do |ccw|
        ccw.setName("#{ccw.name}_reconnected")
        space_heating_loop.addDemandBranchForComponent(ccw)
      end

      # if coil_heating_water_baseboards.size > 0 || coil_heating_waters.size > 0
      # disaggregate_heating_vs_how_water(model, supply_loop, storage_tank) # FIXME: doesn't work if both distribution loops go through the source loop
      # end
    end

    # Remove Existing
    remove_loops(runner, model, shared_water_heater_type)
    remove_ems(runner, model, shared_water_heater_type)
    remove_other(runner, model)

    # Register values
    runner.registerValue('shared_water_heater_type', shared_water_heater_type)
    runner.registerValue('shared_water_heater_fuel_type', shared_water_heater_fuel_type)
    runner.registerValue('unit_models', hpxml.buildings.size)
    runner.registerValue('unit_multipliers', unit_multipliers.join(','))
    runner.registerValue('num_units', num_units)
    runner.registerValue('num_beds', num_beds)
    runner.registerValue('supply_count', supply_count)
    runner.registerValue('length_ft_supply', supply_length)
    runner.registerValue('length_ft_return', return_length)
    runner.registerValue('loop_gpm_supply', supply_loop_gpm) if !supply_loop_gpm.nil?
    runner.registerValue('loop_gpm_source', source_loop_gpm) if !source_loop_gpm.nil?
    runner.registerValue('loop_gpm_dhw', dhw_loop_gpm) if !dhw_loop_gpm.nil?
    runner.registerValue('loop_gpm_space_heating', space_heating_loop_gpm) if !space_heating_loop_gpm.nil?
    runner.registerValue('loop_sp_supply', supply_loop_sp) if !supply_loop_sp.nil?
    runner.registerValue('loop_sp_source', source_loop_sp) if !source_loop_sp.nil?
    runner.registerValue('loop_sp_dhw', dhw_loop_sp) if !dhw_loop_sp.nil?
    runner.registerValue('loop_sp_space_heating', space_heating_loop_sp) if !space_heating_loop_sp.nil?
    runner.registerValue('tank_volume_storage', storage_tank_volume)
    runner.registerValue('tank_volume_swing', swing_tank_volume)
    runner.registerValue('tank_capacity_swing', swing_tank_capacity)
    runner.registerValue('reconnected_water_heatings', reconnected_water_heatings)
    runner.registerValue('reconnected_space_heatings', reconnected_space_heatings)

    return true
  end

  def add_loop(model, name, design_temp, deltaF, max_gpm, num_units = nil)
    loop = OpenStudio::Model::PlantLoop.new(model)
    loop.setName(name)
    # loop.setMaximumLoopTemperature(UnitConversions.convert(design_temp, 'F', 'C'))
    loop.setMaximumLoopFlowRate(UnitConversions.convert(max_gpm, 'gal/min', 'm^3/s')) if !max_gpm.nil?
    loop.setPlantLoopVolume(0.003 * num_units) if !num_units.nil? # ~1 gal

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

  def add_indoor_pipes(model, demand_inlet, demand_bypass, supply_length, return_length, supply_pipe_ins_r_value, return_pipe_ins_r_value, num_units)
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
      # dhw_recirc_supply_pipe.setPipeLength(UnitConversions.convert(supply_length / num_units, 'ft', 'm')) # FIXME: if unit multiplier DOES account for this
      dhw_recirc_supply_pipe.setPipeLength(UnitConversions.convert((supply_length / num_units) * thermal_zone.multiplier, 'ft', 'm')) # FIXME: if unit multiplier DOES NOT account for this

      dhw_recirc_supply_pipe.addToNode(demand_inlet.outletModelObject.get.to_Node.get) # FIXME: check IDF branches to make sure everything looks ok

      # Return
      dhw_recirc_return_pipe = OpenStudio::Model::PipeIndoor.new(model)
      dhw_recirc_return_pipe.setName("Recirculation Return Pipe - #{thermal_zone.name}")
      dhw_recirc_return_pipe.setAmbientTemperatureZone(thermal_zone)
      dhw_recirc_return_pipe.setConstruction(insulated_return_pipe_construction)
      dhw_recirc_return_pipe.setPipeInsideDiameter(UnitConversions.convert(return_diameter, 'in', 'm'))
      # dhw_recirc_return_pipe.setPipeLength(UnitConversions.convert(return_length / num_units, 'ft', 'm')) # FIXME: if unit multiplier DOES account for this
      dhw_recirc_return_pipe.setPipeLength(UnitConversions.convert((return_length / num_units) * thermal_zone.multiplier, 'ft', 'm')) # FIXME: if unit multiplier DOES NOT account for this

      dhw_recirc_return_pipe.addToNode(demand_bypass.outletModelObject.get.to_Node.get)
    end
  end

  def calc_recirc_supply_return_lengths(hpxml_bldg, num_units, num_stories, has_double_loaded_corridor)
    l_mech = 8 # ft, Horizontal pipe length in mech room (Per T-24 ACM: 2013 Residential Alternative Calculation Method Reference Manual, June 2013, CEC-400-2013-003-CMF-REV)
    unit_type = hpxml_bldg.building_construction.residential_facility_type
    footprint = hpxml_bldg.building_construction.conditioned_floor_area
    h_floor = hpxml_bldg.building_construction.average_ceiling_height

    n_units_per_floor = num_units / num_stories
    if [HPXML::ResidentialTypeSFD, HPXML::ResidentialTypeManufactured].include?(unit_type)
      aspect_ratio = 1.8
    elsif [HPXML::ResidentialTypeSFA, HPXML::ResidentialTypeApartment].include?(unit_type)
      aspect_ratio = 0.5556
    end
    fb = Math.sqrt(footprint * aspect_ratio)
    lr = footprint / fb
    l_bldg = [fb, lr].max * n_units_per_floor

    supply_length = (l_mech + h_floor * (num_stories / 2.0).ceil + l_bldg) # ft

    if has_double_loaded_corridor
      return_length = (l_mech + h_floor * (num_stories / 2.0).ceil) # ft
    else
      return_length = supply_length
    end

    # supply_length and return_length are per building (?)
    # therefore, we'd expect these lengths to not scale with num_units linearly
    # meaning, more building units equals less per unit distribution loss
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

  def calc_recirc_flow_rate(_hpxml_buildings, supply_length, supply_pipe_ins_r_value, volume)
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

    gpm = q_loss / (60 * 8.25 * delta_T)
    cap = q_loss

    cap = 0 if volume == 0

    return gpm, cap
  end

  def add_pump(model, loop, pump_gpm, pump_head, pump_w)
    return if loop.nil?

    pump_eff = 0.85

    pump = OpenStudio::Model::PumpConstantSpeed.new(model)
    pump.setName("#{loop.name} Pump")
    pump.setMotorEfficiency(pump_eff)
    pump.setRatedPowerConsumption(pump_w) if !pump_w.nil?
    pump.setRatedPumpHead(pump_head) if !pump_head.nil?
    if pump_gpm.nil?
      pump.setRatedFlowRate(pump_eff * pump_w / pump_head) if !pump_w.nil? && !pump_head.nil?
    else
      pump.setRatedFlowRate(UnitConversions.convert(pump_gpm, 'gal/min', 'm^3/s')) if !pump_gpm.nil?
    end
    pump.addToNode(loop.supplyInletNode)
    pump.additionalProperties.setFeature('ObjectType', Constants.ObjectNameSharedWaterHeater) # Used by reporting measure
  end

  def add_setpoint_manager(model, loop, schedule)
    manager = OpenStudio::Model::SetpointManagerScheduled.new(model, schedule)
    manager.setName("#{loop.name} Setpoint Manager #{UnitConversions.convert(schedule.value, 'C', 'F').round}F")
    manager.setControlVariable('Temperature')
    manager.addToNode(loop.supplyOutletNode)
  end

  def add_storage_tank(model, source_loop, supply_loop, volume, prev_storage_tank, name, fuel_type, setpoint)
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
    setpoint = 180.0 # FIXME
    setpoint_schedule = OpenStudio::Model::ScheduleConstant.new(model)
    setpoint_schedule.setName("#{name} Temperature #{setpoint.round}F")
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
    # storage_tank.setUseSideDesignFlowRate(UnitConversions.convert(volume, 'gal', 'm^3') / 60.1) # Sized to ensure that E+ never autosizes the design flow rate to be larger than the tank volume getting drawn out in a hour (60 minutes)
    # storage_tank.setSourceSideDesignFlowRate(UnitConversions.convert(13.6, 'gal/min', 'm^3/s')) # FIXME
    storage_tank.setEndUseSubcategory(name)
    storage_tank.setHeaterFuelType(EPlus.fuel_type(fuel_type))
    # storage_tank.setSkinLossFractiontoZone(1.0 / unit_multiplier) # Tank losses are multiplied by E+ zone multiplier, so need to compensate here
    # storage_tank.setOffCycleFlueLossFractiontoZone(1.0 / unit_multiplier)
    # storage_tank.setMaximumTemperatureLimit(UnitConversions.convert(setpoint, 'F', 'C')) # FIXME
    # storage_tank.setMaximumTemperatureLimit(UnitConversions.convert(140, 'F', 'C')) # FIXME
    if supply_loop.nil? # stratified tank on supply side of source loop (e.g., shared electric hpwh)
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
    if !supply_loop.nil?
      supply_loop.addDemandBranchForComponent(storage_tank)
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
    setpoint = 150.0 # FIXME
    setpoint_schedule = OpenStudio::Model::ScheduleConstant.new(model)
    setpoint_schedule.setName("#{name} Temperature #{setpoint.round}F")
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
    # swing_tank.setUseSideDesignFlowRate(UnitConversions.convert(volume, 'gal', 'm^3') / 60.1) # Sized to ensure that E+ never autosizes the design flow rate to be larger than the tank volume getting drawn out in a hour (60 minutes)
    # swing_tank.setSourceSideDesignFlowRate() # FIXME
    swing_tank.setEndUseSubcategory(name)
    swing_tank.setHeaterFuelType(EPlus.fuel_type(fuel_type))
    # swing_tank.setMaximumTemperatureLimit(UnitConversions.convert(setpoint, 'F', 'C')) # FIXME

    swing_tank.addToNode(last_storage_tank.useSideOutletModelObject.get.to_Node.get) # in series
    # swing_tank.addToNode(source_loop.supplyOutletNode)

    return swing_tank
  end

  def add_heat_exchanger(model, use_loop, source_loop, name)
    hx = OpenStudio::Model::HeatExchangerFluidToFluid.new(model)
    # hx.setControlType('OperationSchemeModulated') # FIXME: this causes a bunch of zero rows for Fuel-fired Absorption HeatPump Electricity Energy: Supply Loop 1 Water Heater
    hx.setName(name)

    use_loop.addSupplyBranchForComponent(hx)
    source_loop.addDemandBranchForComponent(hx)

    return hx
  end

  def add_component(model, system_type, fuel_type, supply_loop, name, capacity, boiler_eff_curve)
    if system_type.include?('boiler')
      component = OpenStudio::Model::BoilerHotWater.new(model)
      component.setName(name)
      component.setNominalThermalEfficiency(0.78)
      component.setNominalCapacity(capacity)
      component.setFuelType(EPlus.fuel_type(fuel_type))
      component.setMinimumPartLoadRatio(0.0)
      component.setMaximumPartLoadRatio(1.0)
      component.setOptimumPartLoadRatio(1.0)
      component.setBoilerFlowMode('LeavingSetpointModulated')
      component.setWaterOutletUpperTemperatureLimit(99.9)
      component.setOnCycleParasiticElectricLoad(0)
      # component.setDesignWaterFlowRate() # FIXME
      component.setEfficiencyCurveTemperatureEvaluationVariable('LeavingBoiler')
      component.setNormalizedBoilerEfficiencyCurve(boiler_eff_curve)
      component.additionalProperties.setFeature('IsCombiBoiler', true) # Used by reporting measure
      return component if system_type == Constants.WaterHeaterTypeCombiHeatPump

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
        # component.setEndUseSubcategory()
        component.setNominalHeatingCapacity(capacity)
        component.setNominalCOP(1.293)
        # component.setDesignFlowRate(0.005) # FIXME
        lift = UnitConversions.convert(20.0, 'deltaF', 'deltaC')
        component.setDesignTemperatureLift(lift)
        component.setDesignSupplyTemperature(60)
        # component.setDesignSupplyTemperature(60 - lift)
        # component.setFlowMode('LeavingSetpointModulated') # FIXME: this almost zeros out Fuel-fired Absorption HeatPump Electricity Energy: Supply Loop 1 Water Heater
        # component.setFlowMode('ConstantFlow')
        component.setMinimumPartLoadRatio(0.2)
        component.setMaximumPartLoadRatio(1.0)
        component.setDefrostControlType('OnDemand')
        component.setDefrostOperationTimeFraction(0.0)
        component.setResistiveDefrostHeaterCapacity(0.0)
        component.setMaximumOutdoorDrybulbTemperatureforDefrostOperation(3.0)
        component.setNominalAuxiliaryElectricPower(900)
        component.setStandbyElectricPower(20)

        # if system_type.include?('space-heating')
        # component.additionalProperties.setFeature('IsCombiHP', true) # Used by reporting measure
        # end

        supply_loop.addSupplyBranchForComponent(component)
      end
    end

    return component
  end

  def add_availability_manager(model, loop, hot_node, cold_node)
    availability_manager = OpenStudio::Model::AvailabilityManagerDifferentialThermostat.new(model)
    availability_manager.setName("#{loop.name} Availability Manager")
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
      'solar hot water Control'
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
    ems_actuator_to_remove = ['water heater ec adj']
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

  def remove_other(runner, model)
    other_equip_to_remove = [
      'water heater energy adjustment'
    ]
    other_equip_to_remove += other_equip_to_remove.map { |p| p.gsub(' ', '_') }
    model.getOtherEquipments.each do |other_equip|
      next if other_equip_to_remove.select { |e| other_equip.name.to_s.include?(e) }.size == 0

      runner.registerInfo("#{other_equip.class} '#{other_equip.name}' removed.")
      other_equip.remove
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

  def get_heat_pump_air_to_water_fuel_fired_heating_curves(model, component)
    cap_func_temp = component.normalizedCapacityFunctionofTemperatureCurve
    # cap_func_temp = OpenStudio::Model::CurveBicubic.new(model)
    cap_func_temp.setName('CapCurveFuncTemp')
    # cap_func_temp.setCoefficient1Constant(-53.99)
    # cap_func_temp.setCoefficient2x(1.541)
    # cap_func_temp.setCoefficient4y(-0.006523)
    # cap_func_temp.setCoefficient3xPOW2(-0.01438)
    # cap_func_temp.setCoefficient6xTIMESY(0.0002626)
    # cap_func_temp.setCoefficient5yPOW2(-0.00006042)
    # cap_func_temp.setCoefficient7xPOW3(0.0000444)
    # cap_func_temp.setCoefficient9xPOW2TIMESY(-0.000001052)
    # cap_func_temp.setCoefficient10xTIMESYPOW2(0.00000006212)
    # cap_func_temp.setCoefficient8yPOW3(0.00000002424)
    # cap_func_temp.setMinimumValueofx(5)
    # cap_func_temp.setMaximumValueofx(60)
    # cap_func_temp.setMinimumValueofy(5)
    # cap_func_temp.setMaximumValueofy(60)

    t_amb = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Site Outdoor Air Drybulb Temperature')
    t_amb.setName('Tamb')
    t_amb.setKeyName('*')

    t_ret = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Fuel-fired Absorption HeatPump Inlet Temperature')
    t_ret.setName('Tret')
    t_ret.setKeyName(component.name.to_s)

    actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(cap_func_temp, 'Curve', 'Curve Result')
    actuator.setName('CapOutput')

    program = OpenStudio::Model::EnergyManagementSystemProgram.new(model)
    program.setName('Cap_fT_fixed')
    program.addLine("Set Tret = #{t_ret.name}*(9.0/5.0)+32.0")
    program.addLine("Set Tamb = #{t_amb.name}*(9.0/5.0)+32.0")
    program.addLine('Set a1 = -53.99')
    program.addLine('Set b1 = 1.541*Tret')
    program.addLine('Set c1 = -0.006523*Tamb')
    program.addLine('Set d1 = -0.01438*(Tret^2)')
    program.addLine('Set e1 = 0.0002626*Tret*Tamb')
    program.addLine('Set f1 = -0.00006042*(Tamb^2)')
    program.addLine('Set g1 = 0.0000444*(Tret^3)')
    program.addLine('Set h1 = -0.000001052*(Tret^2)*Tamb')
    program.addLine('Set i1 = 0.00000006212*Tret*(Tamb^2)')
    program.addLine('Set j1 = 0.00000002424*(Tamb^3)')
    program.addLine("Set #{actuator.name} = a1 + b1 + c1 + d1 + e1 + f1 + g1 + h1 + i1 + j1")

    ems_output_var = OpenStudio::Model::EnergyManagementSystemOutputVariable.new(model, "#{actuator.name}")
    ems_output_var.setName("#{actuator.name}_outputvar")
    ems_output_var.setTypeOfDataInVariable('Averaged')
    ems_output_var.setUpdateFrequency('SystemTimestep')
    ems_output_var.setEMSProgramOrSubroutineName(program)

    program_cm = OpenStudio::Model::EnergyManagementSystemProgramCallingManager.new(model)
    program_cm.setName("#{program.name}_pcm")
    program_cm.setCallingPoint('InsideHVACSystemIterationLoop')
    program_cm.addProgram(program)

    eir_func_temp = component.fuelEnergyInputRatioFunctionofTemperatureCurve
    # eir_func_temp = OpenStudio::Model::CurveBiquadratic.new(model)
    eir_func_temp.setName('EIRCurveFuncTemp')
    # eir_func_temp.setCoefficient1Constant(0.5205)
    # eir_func_temp.setCoefficient2x(0.00004408)
    # eir_func_temp.setCoefficient3xPOW2(0.0000176)
    # eir_func_temp.setCoefficient4y(0.00699)
    # eir_func_temp.setCoefficient5yPOW2(-0.0001215)
    # eir_func_temp.setCoefficient6xTIMESY(0.0000005196)
    # eir_func_temp.setMinimumValueofx(5)
    # eir_func_temp.setMaximumValueofx(60)
    # eir_func_temp.setMinimumValueofy(5)
    # eir_func_temp.setMaximumValueofy(60)

    actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(eir_func_temp, 'Curve', 'Curve Result')
    actuator.setName('EirOutput')

    program = OpenStudio::Model::EnergyManagementSystemProgram.new(model)
    program.setName('Eir_fT_fixed')
    program.addLine("Set Tret = #{t_ret.name}*(9.0/5.0)+32.0")
    program.addLine("Set Tamb = #{t_amb.name}*(9.0/5.0)+32.0")
    program.addLine('Set a2 = 0.52')
    program.addLine('Set b2 = 0.00004408*Tamb')
    program.addLine('Set c2 = 0.0000176*Tamb^2')
    program.addLine('Set d2 = 0.00699*(Tret)')
    program.addLine('Set e2 = -0.0001215*Tamb*Tret')
    program.addLine('Set f2 = 0.0000005196*(Tamb^2)*Tret')
    program.addLine("Set #{actuator.name} = a2 + b2 + c2 + d2 + e2 + f2")

    ems_output_var = OpenStudio::Model::EnergyManagementSystemOutputVariable.new(model, "#{actuator.name}")
    ems_output_var.setName("#{actuator.name}_outputvar")
    ems_output_var.setTypeOfDataInVariable('Averaged')
    ems_output_var.setUpdateFrequency('SystemTimestep')
    ems_output_var.setEMSProgramOrSubroutineName(program)

    program_cm = OpenStudio::Model::EnergyManagementSystemProgramCallingManager.new(model)
    program_cm.setName("#{program.name}_pcm")
    program_cm.setCallingPoint('InsideHVACSystemIterationLoop')
    program_cm.addProgram(program)

    eir_func_plr = OpenStudio::Model::CurveExponent.new(model)
    eir_func_plr.setName('EIRCurveFuncPLR')
    eir_func_plr.setCoefficient1Constant(0)
    eir_func_plr.setCoefficient2Constant(0.9219)
    eir_func_plr.setCoefficient3Constant(-0.188)
    eir_func_plr.setMinimumValueofx(0)
    eir_func_plr.setMaximumValueofx(1)
    eir_func_plr.setMinimumCurveOutput(1)
    eir_func_plr.setMaximumCurveOutput(2.25)

    eir_defrost_adj = OpenStudio::Model::CurveQuadratic.new(model)
    eir_defrost_adj.setName('EIRDefrostFoTCurve')
    eir_defrost_adj.setCoefficient1Constant(1.0317)
    eir_defrost_adj.setCoefficient2x(-0.006)
    eir_defrost_adj.setCoefficient3xPOW2(-0.0011)
    eir_defrost_adj.setMinimumValueofx(-8.89)
    eir_defrost_adj.setMaximumValueofx(3.333)
    eir_defrost_adj.setMinimumCurveOutput(1.0)
    eir_defrost_adj.setMaximumCurveOutput(10.0)

    cycling_ratio_factor = OpenStudio::Model::CurveQuadratic.new(model)
    cycling_ratio_factor.setName('CRFCurve')
    cycling_ratio_factor.setCoefficient1Constant(1)
    cycling_ratio_factor.setCoefficient2x(0)
    cycling_ratio_factor.setCoefficient3xPOW2(0)
    cycling_ratio_factor.setMinimumValueofx(0)
    cycling_ratio_factor.setMaximumValueofx(100)
    cycling_ratio_factor.setMinimumCurveOutput(0)
    cycling_ratio_factor.setMaximumCurveOutput(10.0)

    aux_eir_func_temp = OpenStudio::Model::CurveBiquadratic.new(model)
    aux_eir_func_temp.setName('auxElecEIRCurveFuncTempCurve')
    aux_eir_func_temp.setCoefficient1Constant(1)
    aux_eir_func_temp.setCoefficient2x(0)
    aux_eir_func_temp.setCoefficient3xPOW2(0)
    aux_eir_func_temp.setCoefficient4y(0)
    aux_eir_func_temp.setCoefficient5yPOW2(0)
    aux_eir_func_temp.setCoefficient6xTIMESY(0)
    aux_eir_func_temp.setMinimumValueofx(-100)
    aux_eir_func_temp.setMaximumValueofx(100)
    aux_eir_func_temp.setMinimumValueofy(-100)
    aux_eir_func_temp.setMaximumValueofy(100)

    aux_eir_func_plr = OpenStudio::Model::CurveBiquadratic.new(model)
    aux_eir_func_plr.setName('auxElecEIRForPLRCurve')
    aux_eir_func_plr.setCoefficient1Constant(1.102)
    aux_eir_func_plr.setCoefficient2x(-0.0008714)
    aux_eir_func_plr.setCoefficient3xPOW2(-0.000009238)
    aux_eir_func_plr.setCoefficient4y(0.00000006487)
    aux_eir_func_plr.setCoefficient5yPOW2(0.0006447)
    aux_eir_func_plr.setCoefficient6xTIMESY(0.0000007846)
    aux_eir_func_plr.setMinimumValueofx(5)
    aux_eir_func_plr.setMaximumValueofx(60)
    aux_eir_func_plr.setMinimumValueofy(5)
    aux_eir_func_plr.setMaximumValueofy(60)

    return cap_func_temp, eir_func_temp, eir_func_plr, eir_defrost_adj, cycling_ratio_factor, aux_eir_func_temp, aux_eir_func_plr
  end

  def get_total_water_heating_capacity(model)
    # already accounts for unit multipliers
    total_water_heating_capacity = 0.0
    model.getWaterHeaterMixeds.each do |water_heater_mixed|
      total_water_heating_capacity += water_heater_mixed.heaterMaximumCapacity.get
    end
    return total_water_heating_capacity
  end

  def get_total_space_heating_capacity(model)
    # already accounts for unit multipliers
    total_space_heating_capacity = 0.0
    model.getBoilerHotWaters.each do |boiler_hot_water|
      total_space_heating_capacity += boiler_hot_water.nominalCapacity.get
    end
    return total_space_heating_capacity
  end

  def get_total_water_heating_tank_volume(model)
    # already accounts for unit multipliers
    total_water_heating_tank_volume = 0.0
    model.getWaterHeaterMixeds.each do |water_heater_mixed|
      total_water_heating_tank_volume += water_heater_mixed.tankVolume.get
    end
    return UnitConversions.convert(total_water_heating_tank_volume, 'm^3', 'gal')
  end

  def get_boiler_efficiency_curve(model)
    model.getBoilerHotWaters.each do |boiler|
      curve = boiler.normalizedBoilerEfficiencyCurve.get
      curve.setName('Non Condensing Boiler Efficiency Curve')
      return curve
    end
  end
end

# register the measure to be used by the application
AddSharedWaterHeater.new.registerWithApplication
