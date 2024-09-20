# frozen_string_literal: true

# TODO
module TE
  # Total Energy
  Total = 'Total'
  Net = 'Net'
end

# TODO
module FT
  # Fuel Types
  Elec = 'Electricity'
  Gas = 'Natural Gas'
  Oil = 'Fuel Oil'
  Propane = 'Propane'
  WoodCord = 'Wood Cord'
  WoodPellets = 'Wood Pellets'
  Coal = 'Coal'
end

# TODO
module EUT
  # End Use Types
  Heating = 'Heating'
  HeatingFanPump = 'Heating Fans/Pumps'
  HeatingHeatPumpBackup = 'Heating Heat Pump Backup'
  HeatingHeatPumpBackupFanPump = 'Heating Heat Pump Backup Fans/Pumps'
  Cooling = 'Cooling'
  CoolingFanPump = 'Cooling Fans/Pumps'
  HotWater = 'Hot Water'
  HotWaterRecircPump = 'Hot Water Recirc Pump'
  HotWaterSolarThermalPump = 'Hot Water Solar Thermal Pump'
  LightsInterior = 'Lighting Interior'
  LightsGarage = 'Lighting Garage'
  LightsExterior = 'Lighting Exterior'
  MechVent = 'Mech Vent'
  MechVentPreheat = 'Mech Vent Preheating'
  MechVentPrecool = 'Mech Vent Precooling'
  WholeHouseFan = 'Whole House Fan'
  Refrigerator = 'Refrigerator'
  Freezer = 'Freezer'
  Dehumidifier = 'Dehumidifier'
  Dishwasher = 'Dishwasher'
  ClothesWasher = 'Clothes Washer'
  ClothesDryer = 'Clothes Dryer'
  RangeOven = 'Range/Oven'
  CeilingFan = 'Ceiling Fan'
  Television = 'Television'
  PlugLoads = 'Plug Loads'
  Vehicle = 'Electric Vehicle Charging'
  WellPump = 'Well Pump'
  PoolHeater = 'Pool Heater'
  PoolPump = 'Pool Pump'
  PermanentSpaHeater = 'Permanent Spa Heater'
  PermanentSpaPump = 'Permanent Spa Pump'
  Grill = 'Grill'
  Lighting = 'Lighting'
  Fireplace = 'Fireplace'
  PV = 'PV'
  Generator = 'Generator'
  Battery = 'Battery'
end

# TODO
module HWT
  # Hot Water Types
  ClothesWasher = 'Clothes Washer'
  Dishwasher = 'Dishwasher'
  Fixtures = 'Fixtures'
  DistributionWaste = 'Distribution Waste'
end

# TODO
module LT
  # Load Types
  Heating = 'Heating: Delivered'
  HeatingHeatPumpBackup = 'Heating: Heat Pump Backup' # Needed for ERI calculation for dual-fuel heat pumps
  Cooling = 'Cooling: Delivered'
  HotWaterDelivered = 'Hot Water: Delivered'
  HotWaterTankLosses = 'Hot Water: Tank Losses'
  HotWaterDesuperheater = 'Hot Water: Desuperheater'
  HotWaterSolarThermal = 'Hot Water: Solar Thermal'
end

# TODO
module CLT
  # Component Load Types
  Roofs = 'Roofs'
  Ceilings = 'Ceilings'
  Walls = 'Walls'
  RimJoists = 'Rim Joists'
  FoundationWalls = 'Foundation Walls'
  Doors = 'Doors'
  WindowsConduction = 'Windows Conduction'
  WindowsSolar = 'Windows Solar'
  SkylightsConduction = 'Skylights Conduction'
  SkylightsSolar = 'Skylights Solar'
  Floors = 'Floors'
  Slabs = 'Slabs'
  InternalMass = 'Internal Mass'
  Infiltration = 'Infiltration'
  NaturalVentilation = 'Natural Ventilation'
  MechanicalVentilation = 'Mechanical Ventilation'
  WholeHouseFan = 'Whole House Fan'
  Ducts = 'Ducts'
  InternalGains = 'Internal Gains'
  Lighting = 'Lighting'
end

# TODO
module UHT
  # Unmet Hours Types
  Heating = 'Heating'
  Cooling = 'Cooling'
end

# TODO
module RT
  # Resilience Types
  Battery = 'Battery'
end

# TODO
module PLT
  # Peak Load Types
  Heating = 'Heating: Delivered'
  Cooling = 'Cooling: Delivered'
end

# TODO
module PFT
  # Peak Fuel Types
  Summer = 'Summer'
  Winter = 'Winter'
  Annual = 'Annual'
end

# TODO
module AFT
  # Airflow Types
  Infiltration = 'Infiltration'
  MechanicalVentilation = 'Mechanical Ventilation'
  NaturalVentilation = 'Natural Ventilation'
  WholeHouseFan = 'Whole House Fan'
end

# TODO
module WT
  # Weather Types
  DrybulbTemp = 'Drybulb Temperature'
  WetbulbTemp = 'Wetbulb Temperature'
  RelativeHumidity = 'Relative Humidity'
  WindSpeed = 'Wind Speed'
  DiffuseSolar = 'Diffuse Solar Radiation'
  DirectSolar = 'Direct Solar Radiation'
end

# TODO
module Outputs
  # TODO
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param hpxml_osm_map [Hash] Map of HPXML::Building objects => OpenStudio Model objects for each dwelling unit
  # @param hpxml_header [HPXML::Header] HPXML Header object (one per HPXML file)
  # @param add_component_loads [Boolean] Whether to calculate component loads (since it incurs a runtime speed penalty)
  # @return [nil]
  def self.apply_ems_programs(model, hpxml_osm_map, hpxml_header, add_component_loads)
    season_day_nums = Outputs.apply_unmet_hours_ems_program(model, hpxml_osm_map, hpxml_header)
    loads_data = Outputs.apply_total_loads_ems_program(model, hpxml_osm_map, hpxml_header)
    if add_component_loads
      Outputs.apply_component_loads_ems_program(model, hpxml_osm_map, loads_data, season_day_nums)
    end
    Outputs.apply_total_airflows_ems_program(model, hpxml_osm_map)
  end

  # We do our own unmet hours calculation via EMS so that we can incorporate,
  # e.g., heating/cooling seasons into the logic. The calculation layers on top
  # of the built-in EnergyPlus unmet hours output.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param hpxml_osm_map [Hash] Map of HPXML::Building objects => OpenStudio Model objects for each dwelling unit
  # @param hpxml_header [HPXML::Header] HPXML Header object (one per HPXML file)
  # @return [Hash] TODO
  def self.apply_unmet_hours_ems_program(model, hpxml_osm_map, hpxml_header)
    # Create sensors and gather data
    htg_sensors, clg_sensors = {}, {}
    zone_air_temp_sensors, htg_spt_sensors, clg_spt_sensors = {}, {}, {}
    total_heat_load_serveds, total_cool_load_serveds = {}, {}
    season_day_nums = {}
    onoff_deadbands = hpxml_header.hvac_onoff_thermostat_deadband.to_f
    hpxml_osm_map.each_with_index do |(hpxml_bldg, unit_model), unit|
      conditioned_zone = unit_model.getThermalZones.find { |z| z.additionalProperties.getFeatureAsString('ObjectType').to_s == HPXML::LocationConditionedSpace }
      conditioned_zone_name = conditioned_zone.name.to_s

      # EMS sensors
      htg_sensors[unit] = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Zone Heating Setpoint Not Met Time')
      htg_sensors[unit].setName("#{conditioned_zone_name} htg unmet s")
      htg_sensors[unit].setKeyName(conditioned_zone_name)

      clg_sensors[unit] = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Zone Cooling Setpoint Not Met Time')
      clg_sensors[unit].setName("#{conditioned_zone_name} clg unmet s")
      clg_sensors[unit].setKeyName(conditioned_zone_name)

      total_heat_load_serveds[unit] = hpxml_bldg.total_fraction_heat_load_served
      total_cool_load_serveds[unit] = hpxml_bldg.total_fraction_cool_load_served

      hvac_control = hpxml_bldg.hvac_controls[0]
      next if hvac_control.nil?

      if (onoff_deadbands > 0)
        zone_air_temp_sensors[unit] = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Zone Air Temperature')
        zone_air_temp_sensors[unit].setName("#{conditioned_zone_name} space temp")
        zone_air_temp_sensors[unit].setKeyName(conditioned_zone_name)

        htg_sch = conditioned_zone.thermostatSetpointDualSetpoint.get.heatingSetpointTemperatureSchedule.get
        htg_spt_sensors[unit] = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Schedule Value')
        htg_spt_sensors[unit].setName("#{htg_sch.name} sch value")
        htg_spt_sensors[unit].setKeyName(htg_sch.name.to_s)

        clg_sch = conditioned_zone.thermostatSetpointDualSetpoint.get.coolingSetpointTemperatureSchedule.get
        clg_spt_sensors[unit] = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Schedule Value')
        clg_spt_sensors[unit].setName("#{clg_sch.name} sch value")
        clg_spt_sensors[unit].setKeyName(clg_sch.name.to_s)
      end

      sim_year = hpxml_header.sim_calendar_year
      season_day_nums[unit] = {
        htg_start: Calendar.get_day_num_from_month_day(sim_year, hvac_control.seasons_heating_begin_month, hvac_control.seasons_heating_begin_day),
        htg_end: Calendar.get_day_num_from_month_day(sim_year, hvac_control.seasons_heating_end_month, hvac_control.seasons_heating_end_day),
        clg_start: Calendar.get_day_num_from_month_day(sim_year, hvac_control.seasons_cooling_begin_month, hvac_control.seasons_cooling_begin_day),
        clg_end: Calendar.get_day_num_from_month_day(sim_year, hvac_control.seasons_cooling_end_month, hvac_control.seasons_cooling_end_day)
      }
    end

    hvac_availability_sensor = model.getEnergyManagementSystemSensors.find { |s| s.additionalProperties.getFeatureAsString('ObjectType').to_s == Constants::ObjectTypeHVACAvailabilitySensor }

    # EMS program
    clg_hrs = 'clg_unmet_hours'
    htg_hrs = 'htg_unmet_hours'
    unit_clg_hrs = 'unit_clg_unmet_hours'
    unit_htg_hrs = 'unit_htg_unmet_hours'
    program = OpenStudio::Model::EnergyManagementSystemProgram.new(model)
    program.setName('unmet hours program')
    program.additionalProperties.setFeature('ObjectType', Constants::ObjectTypeUnmetHoursProgram)
    program.addLine("Set #{htg_hrs} = 0")
    program.addLine("Set #{clg_hrs} = 0")
    for unit in 0..hpxml_osm_map.size - 1
      if total_heat_load_serveds[unit] > 0
        program.addLine("Set #{unit_htg_hrs} = 0")
        if season_day_nums[unit][:htg_end] >= season_day_nums[unit][:htg_start]
          line = "If ((DayOfYear >= #{season_day_nums[unit][:htg_start]}) && (DayOfYear <= #{season_day_nums[unit][:htg_end]}))"
        else
          line = "If ((DayOfYear >= #{season_day_nums[unit][:htg_start]}) || (DayOfYear <= #{season_day_nums[unit][:htg_end]}))"
        end
        line += " && (#{hvac_availability_sensor.name} == 1)" if not hvac_availability_sensor.nil?
        program.addLine(line)
        if zone_air_temp_sensors.keys.include? unit # on off deadband
          program.addLine("  If #{zone_air_temp_sensors[unit].name} < (#{htg_spt_sensors[unit].name} - #{UnitConversions.convert(onoff_deadbands, 'deltaF', 'deltaC')})")
          program.addLine("    Set #{unit_htg_hrs} = #{unit_htg_hrs} + #{htg_sensors[unit].name}")
          program.addLine('  EndIf')
        else
          program.addLine("  Set #{unit_htg_hrs} = #{unit_htg_hrs} + #{htg_sensors[unit].name}")
        end
        program.addLine("  If #{unit_htg_hrs} > #{htg_hrs}") # Use max hourly value across all units
        program.addLine("    Set #{htg_hrs} = #{unit_htg_hrs}")
        program.addLine('  EndIf')
        program.addLine('EndIf')
      end
      next unless total_cool_load_serveds[unit] > 0

      program.addLine("Set #{unit_clg_hrs} = 0")
      if season_day_nums[unit][:clg_end] >= season_day_nums[unit][:clg_start]
        line = "If ((DayOfYear >= #{season_day_nums[unit][:clg_start]}) && (DayOfYear <= #{season_day_nums[unit][:clg_end]}))"
      else
        line = "If ((DayOfYear >= #{season_day_nums[unit][:clg_start]}) || (DayOfYear <= #{season_day_nums[unit][:clg_end]}))"
      end
      line += " && (#{hvac_availability_sensor.name} == 1)" if not hvac_availability_sensor.nil?
      program.addLine(line)
      if zone_air_temp_sensors.keys.include? unit # on off deadband
        program.addLine("  If #{zone_air_temp_sensors[unit].name} > (#{clg_spt_sensors[unit].name} + #{UnitConversions.convert(onoff_deadbands, 'deltaF', 'deltaC')})")
        program.addLine("    Set #{unit_clg_hrs} = #{unit_clg_hrs} + #{clg_sensors[unit].name}")
        program.addLine('  EndIf')
      else
        program.addLine("  Set #{unit_clg_hrs} = #{unit_clg_hrs} + #{clg_sensors[unit].name}")
      end
      program.addLine("  If #{unit_clg_hrs} > #{clg_hrs}") # Use max hourly value across all units
      program.addLine("    Set #{clg_hrs} = #{unit_clg_hrs}")
      program.addLine('  EndIf')
      program.addLine('EndIf')
    end

    # EMS calling manager
    program_calling_manager = OpenStudio::Model::EnergyManagementSystemProgramCallingManager.new(model)
    program_calling_manager.setName("#{program.name} calling manager")
    program_calling_manager.setCallingPoint('EndOfZoneTimestepBeforeZoneReporting')
    program_calling_manager.addProgram(program)

    return season_day_nums
  end

  # TODO
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param hpxml_osm_map [Hash] Map of HPXML::Building objects => OpenStudio Model objects for each dwelling unit
  # @param hpxml_header [HPXML::Header] HPXML Header object (one per HPXML file)
  # @return [TODO] TODO
  def self.apply_total_loads_ems_program(model, hpxml_osm_map, hpxml_header)
    # Create sensors and gather data
    htg_cond_load_sensors, clg_cond_load_sensors = {}, {}
    htg_duct_load_sensors, clg_duct_load_sensors = {}, {}
    total_heat_load_serveds, total_cool_load_serveds = {}, {}
    dehumidifier_global_vars, dehumidifier_sensors = {}, {}

    hpxml_osm_map.each_with_index do |(hpxml_bldg, unit_model), unit|
      # Retrieve objects
      conditioned_zone_name = unit_model.getThermalZones.find { |z| z.additionalProperties.getFeatureAsString('ObjectType').to_s == HPXML::LocationConditionedSpace }.name.to_s
      duct_zone_names = unit_model.getThermalZones.select { |z| z.isPlenum }.map { |z| z.name.to_s }
      dehumidifier = unit_model.getZoneHVACDehumidifierDXs
      dehumidifier_name = dehumidifier[0].name.to_s unless dehumidifier.empty?

      # Fraction heat/cool load served
      if hpxml_header.apply_ashrae140_assumptions
        total_heat_load_serveds[unit] = 1.0
        total_cool_load_serveds[unit] = 1.0
      else
        total_heat_load_serveds[unit] = hpxml_bldg.total_fraction_heat_load_served
        total_cool_load_serveds[unit] = hpxml_bldg.total_fraction_cool_load_served
      end

      # Energy transferred in conditioned zone, used for determining heating (winter) vs cooling (summer)
      htg_cond_load_sensors[unit] = OpenStudio::Model::EnergyManagementSystemSensor.new(model, "Heating:EnergyTransfer:Zone:#{conditioned_zone_name.upcase}")
      htg_cond_load_sensors[unit].setName('htg_load_cond')
      clg_cond_load_sensors[unit] = OpenStudio::Model::EnergyManagementSystemSensor.new(model, "Cooling:EnergyTransfer:Zone:#{conditioned_zone_name.upcase}")
      clg_cond_load_sensors[unit].setName('clg_load_cond')

      # Energy transferred in duct zone(s)
      htg_duct_load_sensors[unit] = []
      clg_duct_load_sensors[unit] = []
      duct_zone_names.each do |duct_zone_name|
        htg_duct_load_sensors[unit] << OpenStudio::Model::EnergyManagementSystemSensor.new(model, "Heating:EnergyTransfer:Zone:#{duct_zone_name.upcase}")
        htg_duct_load_sensors[unit][-1].setName('htg_load_duct')
        clg_duct_load_sensors[unit] << OpenStudio::Model::EnergyManagementSystemSensor.new(model, "Cooling:EnergyTransfer:Zone:#{duct_zone_name.upcase}")
        clg_duct_load_sensors[unit][-1].setName('clg_load_duct')
      end

      next if dehumidifier_name.nil?

      # Need to adjust E+ EnergyTransfer meters for dehumidifier internal gains.
      # We also offset the dehumidifier load by one timestep so that it aligns with the EnergyTransfer meters.

      # Global Variable
      dehumidifier_global_vars[unit] = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "prev_#{dehumidifier_name}")

      # Initialization Program
      timestep_offset_program = OpenStudio::Model::EnergyManagementSystemProgram.new(model)
      timestep_offset_program.setName("#{dehumidifier_name} timestep offset init program")
      timestep_offset_program.addLine("Set #{dehumidifier_global_vars[unit].name} = 0")

      # calling managers
      manager = OpenStudio::Model::EnergyManagementSystemProgramCallingManager.new(model)
      manager.setName("#{timestep_offset_program.name} calling manager")
      manager.setCallingPoint('BeginNewEnvironment')
      manager.addProgram(timestep_offset_program)
      manager = OpenStudio::Model::EnergyManagementSystemProgramCallingManager.new(model)
      manager.setName("#{timestep_offset_program.name} calling manager2")
      manager.setCallingPoint('AfterNewEnvironmentWarmUpIsComplete')
      manager.addProgram(timestep_offset_program)

      dehumidifier_sensors[unit] = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Zone Dehumidifier Sensible Heating Energy')
      dehumidifier_sensors[unit].setName('ig_dehumidifier')
      dehumidifier_sensors[unit].setKeyName(dehumidifier_name)
    end

    # EMS program
    program = OpenStudio::Model::EnergyManagementSystemProgram.new(model)
    program.setName('total loads program')
    program.additionalProperties.setFeature('ObjectType', Constants::ObjectTypeTotalLoadsProgram)
    program.addLine('Set loads_htg_tot = 0')
    program.addLine('Set loads_clg_tot = 0')
    for unit in 0..hpxml_osm_map.size - 1
      program.addLine("If #{htg_cond_load_sensors[unit].name} > 0")
      program.addLine("  Set loads_htg_tot = loads_htg_tot + (#{htg_cond_load_sensors[unit].name} - #{clg_cond_load_sensors[unit].name}) * #{total_heat_load_serveds[unit]}")
      for i in 0..htg_duct_load_sensors[unit].size - 1
        program.addLine("  Set loads_htg_tot = loads_htg_tot + (#{htg_duct_load_sensors[unit][i].name} - #{clg_duct_load_sensors[unit][i].name}) * #{total_heat_load_serveds[unit]}")
      end
      if not dehumidifier_global_vars[unit].nil?
        program.addLine("  Set loads_htg_tot = loads_htg_tot - #{dehumidifier_global_vars[unit].name}")
      end
      program.addLine('EndIf')
    end
    program.addLine('Set loads_htg_tot = (@Max loads_htg_tot 0)')
    for unit in 0..hpxml_osm_map.size - 1
      program.addLine("If #{clg_cond_load_sensors[unit].name} > 0")
      program.addLine("  Set loads_clg_tot = loads_clg_tot + (#{clg_cond_load_sensors[unit].name} - #{htg_cond_load_sensors[unit].name}) * #{total_cool_load_serveds[unit]}")
      for i in 0..clg_duct_load_sensors[unit].size - 1
        program.addLine("  Set loads_clg_tot = loads_clg_tot + (#{clg_duct_load_sensors[unit][i].name} - #{htg_duct_load_sensors[unit][i].name}) * #{total_cool_load_serveds[unit]}")
      end
      if not dehumidifier_global_vars[unit].nil?
        program.addLine("  Set loads_clg_tot = loads_clg_tot + #{dehumidifier_global_vars[unit].name}")
      end
      program.addLine('EndIf')
    end
    program.addLine('Set loads_clg_tot = (@Max loads_clg_tot 0)')
    for unit in 0..hpxml_osm_map.size - 1
      if not dehumidifier_global_vars[unit].nil?
        # Store dehumidifier internal gain, will be used in EMS program next timestep
        program.addLine("Set #{dehumidifier_global_vars[unit].name} = #{dehumidifier_sensors[unit].name}")
      end
    end

    # EMS calling manager
    program_calling_manager = OpenStudio::Model::EnergyManagementSystemProgramCallingManager.new(model)
    program_calling_manager.setName("#{program.name} calling manager")
    program_calling_manager.setCallingPoint('EndOfZoneTimestepAfterZoneReporting')
    program_calling_manager.addProgram(program)

    return htg_cond_load_sensors, clg_cond_load_sensors, total_heat_load_serveds, total_cool_load_serveds, dehumidifier_sensors
  end

  # TODO
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param hpxml_osm_map [Hash] Map of HPXML::Building objects => OpenStudio Model objects for each dwelling unit
  # @param loads_data [TODO] TODO
  # @param season_day_nums [TODO] TODO
  # @return [nil]
  def self.apply_component_loads_ems_program(model, hpxml_osm_map, loads_data, season_day_nums)
    htg_cond_load_sensors, clg_cond_load_sensors, total_heat_load_serveds, total_cool_load_serveds, dehumidifier_sensors = loads_data

    # Output diagnostics needed for some output variables used below
    output_diagnostics = model.getOutputDiagnostics
    output_diagnostics.addKey('DisplayAdvancedReportVariables')

    area_tolerance = UnitConversions.convert(1.0, 'ft^2', 'm^2')

    nonsurf_names = ['intgains', 'lighting', 'infil', 'mechvent', 'natvent', 'whf', 'ducts']
    surf_names = ['walls', 'rim_joists', 'foundation_walls', 'floors', 'slabs', 'ceilings',
                  'roofs', 'windows_conduction', 'windows_solar', 'doors', 'skylights_conduction',
                  'skylights_solar', 'internal_mass']

    # EMS program
    program = OpenStudio::Model::EnergyManagementSystemProgram.new(model)
    program.setName('component loads program')
    program.additionalProperties.setFeature('ObjectType', Constants::ObjectTypeComponentLoadsProgram)

    # Initialize
    [:htg, :clg].each do |mode|
      surf_names.each do |surf_name|
        program.addLine("Set loads_#{mode}_#{surf_name} = 0")
      end
      nonsurf_names.each do |nonsurf_name|
        program.addLine("Set loads_#{mode}_#{nonsurf_name} = 0")
      end
    end

    hpxml_osm_map.each_with_index do |(hpxml_bldg, unit_model), unit|
      conditioned_zone = unit_model.getThermalZones.find { |z| z.additionalProperties.getFeatureAsString('ObjectType').to_s == HPXML::LocationConditionedSpace }

      # Prevent certain objects (e.g., OtherEquipment) from being counted towards both, e.g., ducts and internal gains
      objects_already_processed = []

      # EMS Sensors: Surfaces, SubSurfaces, InternalMass
      surfaces_sensors = {}
      surf_names.each do |surf_name|
        surfaces_sensors[surf_name.to_sym] = []
      end

      unit_model.getSurfaces.sort.each do |s|
        next unless s.space.get.thermalZone.get.name.to_s == conditioned_zone.name.to_s

        surface_type = s.additionalProperties.getFeatureAsString('SurfaceType')
        if not surface_type.is_initialized
          fail "Could not identify surface type for surface: '#{s.name}'."
        end

        surface_type = surface_type.get

        s.subSurfaces.each do |ss|
          # Conduction (windows, skylights, doors)
          key = { 'Window' => :windows_conduction,
                  'Door' => :doors,
                  'Skylight' => :skylights_conduction }[surface_type]
          fail "Unexpected subsurface for component loads: '#{ss.name}'." if key.nil?

          if (surface_type == 'Window') || (surface_type == 'Skylight')
            vars = { 'Surface Inside Face Convection Heat Gain Energy' => 'ss_conv',
                     'Surface Inside Face Internal Gains Radiation Heat Gain Energy' => 'ss_ig',
                     'Surface Inside Face Net Surface Thermal Radiation Heat Gain Energy' => 'ss_surf' }
          else
            vars = { 'Surface Inside Face Solar Radiation Heat Gain Energy' => 'ss_sol',
                     'Surface Inside Face Lights Radiation Heat Gain Energy' => 'ss_lgt',
                     'Surface Inside Face Convection Heat Gain Energy' => 'ss_conv',
                     'Surface Inside Face Internal Gains Radiation Heat Gain Energy' => 'ss_ig',
                     'Surface Inside Face Net Surface Thermal Radiation Heat Gain Energy' => 'ss_surf' }
          end

          vars.each do |var, name|
            surfaces_sensors[key] << []
            sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, var)
            sensor.setName(name)
            sensor.setKeyName(ss.name.to_s)
            surfaces_sensors[key][-1] << sensor
          end

          # Solar (windows, skylights)
          next unless (surface_type == 'Window') || (surface_type == 'Skylight')

          key = { 'Window' => :windows_solar,
                  'Skylight' => :skylights_solar }[surface_type]
          vars = { 'Surface Window Transmitted Solar Radiation Energy' => 'ss_trans_in',
                   'Surface Window Shortwave from Zone Back Out Window Heat Transfer Rate' => 'ss_back_out',
                   'Surface Window Total Glazing Layers Absorbed Shortwave Radiation Rate' => 'ss_sw_abs',
                   'Surface Window Total Glazing Layers Absorbed Solar Radiation Energy' => 'ss_sol_abs',
                   'Surface Inside Face Initial Transmitted Diffuse Transmitted Out Window Solar Radiation Rate' => 'ss_trans_out' }

          surfaces_sensors[key] << []
          vars.each do |var, name|
            sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, var)
            sensor.setName(name)
            sensor.setKeyName(ss.name.to_s)
            surfaces_sensors[key][-1] << sensor
          end
        end

        next if s.netArea < area_tolerance # Skip parent surfaces (of subsurfaces) that have near zero net area

        key = { 'FoundationWall' => :foundation_walls,
                'RimJoist' => :rim_joists,
                'Wall' => :walls,
                'Slab' => :slabs,
                'Floor' => :floors,
                'Ceiling' => :ceilings,
                'Roof' => :roofs,
                'Skylight' => :skylights_conduction, # Skylight curb/shaft
                'InferredCeiling' => :internal_mass,
                'InferredFloor' => :internal_mass }[surface_type]
        fail "Unexpected surface for component loads: '#{s.name}'." if key.nil?

        surfaces_sensors[key] << []
        { 'Surface Inside Face Convection Heat Gain Energy' => 's_conv',
          'Surface Inside Face Internal Gains Radiation Heat Gain Energy' => 's_ig',
          'Surface Inside Face Solar Radiation Heat Gain Energy' => 's_sol',
          'Surface Inside Face Lights Radiation Heat Gain Energy' => 's_lgt',
          'Surface Inside Face Net Surface Thermal Radiation Heat Gain Energy' => 's_surf' }.each do |var, name|
          sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, var)
          sensor.setName(name)
          sensor.setKeyName(s.name.to_s)
          surfaces_sensors[key][-1] << sensor
        end
      end

      unit_model.getInternalMasss.sort.each do |m|
        next unless m.space.get.thermalZone.get.name.to_s == conditioned_zone.name.to_s

        surfaces_sensors[:internal_mass] << []
        { 'Surface Inside Face Convection Heat Gain Energy' => 'im_conv',
          'Surface Inside Face Internal Gains Radiation Heat Gain Energy' => 'im_ig',
          'Surface Inside Face Solar Radiation Heat Gain Energy' => 'im_sol',
          'Surface Inside Face Lights Radiation Heat Gain Energy' => 'im_lgt',
          'Surface Inside Face Net Surface Thermal Radiation Heat Gain Energy' => 'im_surf' }.each do |var, name|
          sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, var)
          sensor.setName(name)
          sensor.setKeyName(m.name.to_s)
          surfaces_sensors[:internal_mass][-1] << sensor
        end
      end

      # EMS Sensors: Infiltration, Natural Ventilation, Whole House Fan
      infil_sensors, natvent_sensors, whf_sensors = [], [], []
      unit_model.getSpaceInfiltrationDesignFlowRates.sort.each do |i|
        next unless i.space.get.thermalZone.get.name.to_s == conditioned_zone.name.to_s

        object_type = i.additionalProperties.getFeatureAsString('ObjectType').get

        { 'Infiltration Sensible Heat Gain Energy' => 'airflow_gain',
          'Infiltration Sensible Heat Loss Energy' => 'airflow_loss' }.each do |var, name|
          airflow_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, var)
          airflow_sensor.setName(name)
          airflow_sensor.setKeyName(i.name.to_s)
          if object_type == Constants::ObjectTypeInfiltration
            infil_sensors << airflow_sensor
          elsif object_type == Constants::ObjectTypeNaturalVentilation
            natvent_sensors << airflow_sensor
          elsif object_type == Constants::ObjectTypeWholeHouseFan
            whf_sensors << airflow_sensor
          end
        end
      end

      # EMS Sensors: Mechanical Ventilation
      mechvents_sensors = []
      unit_model.getElectricEquipments.sort.each do |o|
        next unless o.endUseSubcategory == Constants::ObjectTypeMechanicalVentilation

        objects_already_processed << o
        { 'Electric Equipment Convective Heating Energy' => 'mv_conv',
          'Electric Equipment Radiant Heating Energy' => 'mv_rad' }.each do |var, name|
          mechvent_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, var)
          mechvent_sensor.setName(name)
          mechvent_sensor.setKeyName(o.name.to_s)
          mechvents_sensors << mechvent_sensor
        end
      end
      unit_model.getOtherEquipments.sort.each do |o|
        next unless o.endUseSubcategory == Constants::ObjectTypeMechanicalVentilationHouseFan

        objects_already_processed << o
        { 'Other Equipment Convective Heating Energy' => 'mv_conv',
          'Other Equipment Radiant Heating Energy' => 'mv_rad' }.each do |var, name|
          mechvent_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, var)
          mechvent_sensor.setName(name)
          mechvent_sensor.setKeyName(o.name.to_s)
          mechvents_sensors << mechvent_sensor
        end
      end

      # EMS Sensors: Ducts
      ducts_sensors = []
      ducts_mix_gain_sensor = nil
      ducts_mix_loss_sensor = nil
      conditioned_zone.zoneMixing.each do |zone_mix|
        object_type = zone_mix.additionalProperties.getFeatureAsString('ObjectType').to_s
        next unless object_type == Constants::ObjectTypeDuctLoad

        ducts_mix_gain_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Zone Mixing Sensible Heat Gain Energy')
        ducts_mix_gain_sensor.setName('duct_mix_gain')
        ducts_mix_gain_sensor.setKeyName(conditioned_zone.name.to_s)

        ducts_mix_loss_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Zone Mixing Sensible Heat Loss Energy')
        ducts_mix_loss_sensor.setName('duct_mix_loss')
        ducts_mix_loss_sensor.setKeyName(conditioned_zone.name.to_s)
      end
      unit_model.getOtherEquipments.sort.each do |o|
        next if objects_already_processed.include? o
        next unless o.endUseSubcategory == Constants::ObjectTypeDuctLoad

        objects_already_processed << o
        { 'Other Equipment Convective Heating Energy' => 'ducts_conv',
          'Other Equipment Radiant Heating Energy' => 'ducts_rad' }.each do |var, name|
          ducts_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, var)
          ducts_sensor.setName(name)
          ducts_sensor.setKeyName(o.name.to_s)
          ducts_sensors << ducts_sensor
        end
      end

      # EMS Sensors: Lighting
      lightings_sensors = []
      unit_model.getLightss.sort.each do |e|
        next unless e.space.get.thermalZone.get.name.to_s == conditioned_zone.name.to_s

        { 'Lights Convective Heating Energy' => 'ig_lgt_conv',
          'Lights Radiant Heating Energy' => 'ig_lgt_rad',
          'Lights Visible Radiation Heating Energy' => 'ig_lgt_vis' }.each do |var, name|
          intgains_lights_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, var)
          intgains_lights_sensor.setName(name)
          intgains_lights_sensor.setKeyName(e.name.to_s)
          lightings_sensors << intgains_lights_sensor
        end
      end

      # EMS Sensors: Internal Gains
      intgains_sensors = []
      unit_model.getElectricEquipments.sort.each do |o|
        next if objects_already_processed.include? o
        next unless o.space.get.thermalZone.get.name.to_s == conditioned_zone.name.to_s

        { 'Electric Equipment Convective Heating Energy' => 'ig_ee_conv',
          'Electric Equipment Radiant Heating Energy' => 'ig_ee_rad' }.each do |var, name|
          intgains_elec_equip_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, var)
          intgains_elec_equip_sensor.setName(name)
          intgains_elec_equip_sensor.setKeyName(o.name.to_s)
          intgains_sensors << intgains_elec_equip_sensor
        end
      end

      unit_model.getOtherEquipments.sort.each do |o|
        next if objects_already_processed.include? o
        next unless o.space.get.thermalZone.get.name.to_s == conditioned_zone.name.to_s

        { 'Other Equipment Convective Heating Energy' => 'ig_oe_conv',
          'Other Equipment Radiant Heating Energy' => 'ig_oe_rad' }.each do |var, name|
          intgains_other_equip_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, var)
          intgains_other_equip_sensor.setName(name)
          intgains_other_equip_sensor.setKeyName(o.name.to_s)
          intgains_sensors << intgains_other_equip_sensor
        end
      end

      unit_model.getPeoples.sort.each do |e|
        next unless e.space.get.thermalZone.get.name.to_s == conditioned_zone.name.to_s

        { 'People Convective Heating Energy' => 'ig_ppl_conv',
          'People Radiant Heating Energy' => 'ig_ppl_rad' }.each do |var, name|
          intgains_people = OpenStudio::Model::EnergyManagementSystemSensor.new(model, var)
          intgains_people.setName(name)
          intgains_people.setKeyName(e.name.to_s)
          intgains_sensors << intgains_people
        end
      end

      if not dehumidifier_sensors[unit].nil?
        intgains_sensors << dehumidifier_sensors[unit]
      end

      intgains_dhw_sensors = {}

      (unit_model.getWaterHeaterMixeds + unit_model.getWaterHeaterStratifieds).sort.each do |wh|
        next unless wh.ambientTemperatureThermalZone.is_initialized
        next unless wh.ambientTemperatureThermalZone.get.name.to_s == conditioned_zone.name.to_s

        dhw_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Water Heater Heat Loss Energy')
        dhw_sensor.setName('dhw_loss')
        dhw_sensor.setKeyName(wh.name.to_s)

        if wh.is_a? OpenStudio::Model::WaterHeaterMixed
          oncycle_loss = wh.onCycleLossFractiontoThermalZone
          offcycle_loss = wh.offCycleLossFractiontoThermalZone
        else
          oncycle_loss = wh.skinLossFractiontoZone
          offcycle_loss = wh.offCycleFlueLossFractiontoZone
        end

        dhw_rtf_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Water Heater Runtime Fraction')
        dhw_rtf_sensor.setName('dhw_rtf')
        dhw_rtf_sensor.setKeyName(wh.name.to_s)

        intgains_dhw_sensors[dhw_sensor] = [offcycle_loss, oncycle_loss, dhw_rtf_sensor]
      end

      # EMS program: Surfaces
      surfaces_sensors.each do |k, surface_sensors|
        program.addLine("Set hr_#{k} = 0")
        surface_sensors.each do |sensors|
          s = "Set hr_#{k} = hr_#{k}"
          sensors.each do |sensor|
            # remove ss_net if switch
            if sensor.name.to_s.start_with?('ss_net', 'ss_sol_abs', 'ss_trans_in')
              s += " - #{sensor.name}"
            elsif sensor.name.to_s.start_with?('ss_sw_abs', 'ss_trans_out', 'ss_back_out')
              s += " + #{sensor.name} * ZoneTimestep * 3600"
            else
              s += " + #{sensor.name}"
            end
          end
          program.addLine(s) if sensors.size > 0
        end
      end

      # EMS program: Internal Gains, Lighting, Infiltration, Natural Ventilation, Mechanical Ventilation, Ducts
      { 'intgains' => intgains_sensors,
        'lighting' => lightings_sensors,
        'infil' => infil_sensors,
        'natvent' => natvent_sensors,
        'whf' => whf_sensors,
        'mechvent' => mechvents_sensors,
        'ducts' => ducts_sensors }.each do |loadtype, sensors|
        program.addLine("Set hr_#{loadtype} = 0")
        next if sensors.empty?

        s = "Set hr_#{loadtype} = hr_#{loadtype}"
        sensors.each do |sensor|
          if ['intgains', 'lighting', 'mechvent', 'ducts'].include? loadtype
            s += " - #{sensor.name}"
          elsif sensor.name.to_s.include? 'gain'
            s += " - #{sensor.name}"
          elsif sensor.name.to_s.include? 'loss'
            s += " + #{sensor.name}"
          end
        end
        program.addLine(s)
      end
      intgains_dhw_sensors.each do |sensor, vals|
        off_loss, on_loss, rtf_sensor = vals
        program.addLine("Set hr_intgains = hr_intgains + #{sensor.name} * (#{off_loss}*(1-#{rtf_sensor.name}) + #{on_loss}*#{rtf_sensor.name})") # Water heater tank losses to zone
      end
      if (not ducts_mix_loss_sensor.nil?) && (not ducts_mix_gain_sensor.nil?)
        program.addLine("Set hr_ducts = hr_ducts + (#{ducts_mix_loss_sensor.name} - #{ducts_mix_gain_sensor.name})")
      end

      # EMS Sensors: Indoor temperature, setpoints
      tin_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Zone Mean Air Temperature')
      tin_sensor.setName('tin s')
      tin_sensor.setKeyName(conditioned_zone.name.to_s)
      thermostat = nil
      if conditioned_zone.thermostatSetpointDualSetpoint.is_initialized
        thermostat = conditioned_zone.thermostatSetpointDualSetpoint.get

        htg_sp_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Schedule Value')
        htg_sp_sensor.setName('htg sp s')
        htg_sp_sensor.setKeyName(thermostat.heatingSetpointTemperatureSchedule.get.name.to_s)

        clg_sp_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Schedule Value')
        clg_sp_sensor.setName('clg sp s')
        clg_sp_sensor.setKeyName(thermostat.coolingSetpointTemperatureSchedule.get.name.to_s)
      end

      # EMS program: Heating vs Cooling logic
      program.addLine('Set htg_mode = 0')
      program.addLine('Set clg_mode = 0')
      program.addLine("If (#{htg_cond_load_sensors[unit].name} > 0)") # Assign hour to heating if heating load
      program.addLine("  Set htg_mode = #{total_heat_load_serveds[unit]}")
      program.addLine("ElseIf (#{clg_cond_load_sensors[unit].name} > 0)") # Assign hour to cooling if cooling load
      program.addLine("  Set clg_mode = #{total_cool_load_serveds[unit]}")
      program.addLine('Else')
      program.addLine('  Set htg_season = 0')
      program.addLine('  Set clg_season = 0')
      if not season_day_nums[unit].nil?
        # Determine whether we're in the heating and/or cooling season
        if season_day_nums[unit][:clg_end] >= season_day_nums[unit][:clg_start]
          program.addLine("  If ((DayOfYear >= #{season_day_nums[unit][:clg_start]}) && (DayOfYear <= #{season_day_nums[unit][:clg_end]}))")
        else
          program.addLine("  If ((DayOfYear >= #{season_day_nums[unit][:clg_start]}) || (DayOfYear <= #{season_day_nums[unit][:clg_end]}))")
        end
        program.addLine('    Set clg_season = 1')
        program.addLine('  EndIf')
        if season_day_nums[unit][:htg_end] >= season_day_nums[unit][:htg_start]
          program.addLine("  If ((DayOfYear >= #{season_day_nums[unit][:htg_start]}) && (DayOfYear <= #{season_day_nums[unit][:htg_end]}))")
        else
          program.addLine("  If ((DayOfYear >= #{season_day_nums[unit][:htg_start]}) || (DayOfYear <= #{season_day_nums[unit][:htg_end]}))")
        end
        program.addLine('    Set htg_season = 1')
        program.addLine('  EndIf')
      end
      program.addLine("  If ((#{natvent_sensors[0].name} <> 0) || (#{natvent_sensors[1].name} <> 0)) && (clg_season == 1)") # Assign hour to cooling if natural ventilation is operating
      program.addLine("    Set clg_mode = #{total_cool_load_serveds[unit]}")
      program.addLine("  ElseIf ((#{whf_sensors[0].name} <> 0) || (#{whf_sensors[1].name} <> 0)) && (clg_season == 1)") # Assign hour to cooling if whole house fan is operating
      program.addLine("    Set clg_mode = #{total_cool_load_serveds[unit]}")
      if not thermostat.nil?
        program.addLine('  Else') # Indoor temperature floating between setpoints; determine assignment by comparing to average of heating/cooling setpoints
        program.addLine("    Set Tmid_setpoint = (#{htg_sp_sensor.name} + #{clg_sp_sensor.name}) / 2")
        program.addLine("    If (#{tin_sensor.name} > Tmid_setpoint) && (clg_season == 1)")
        program.addLine("      Set clg_mode = #{total_cool_load_serveds[unit]}")
        program.addLine("    ElseIf (#{tin_sensor.name} < Tmid_setpoint) && (htg_season == 1)")
        program.addLine("      Set htg_mode = #{total_heat_load_serveds[unit]}")
        program.addLine('    EndIf')
      end
      program.addLine('  EndIf')
      program.addLine('EndIf')

      unit_multiplier = hpxml_bldg.building_construction.number_of_units
      [:htg, :clg].each do |mode|
        if mode == :htg
          sign = ''
        else
          sign = '-'
        end
        surf_names.each do |surf_name|
          program.addLine("Set loads_#{mode}_#{surf_name} = loads_#{mode}_#{surf_name} + (#{sign}hr_#{surf_name} * #{mode}_mode * #{unit_multiplier})")
        end
        nonsurf_names.each do |nonsurf_name|
          program.addLine("Set loads_#{mode}_#{nonsurf_name} = loads_#{mode}_#{nonsurf_name} + (#{sign}hr_#{nonsurf_name} * #{mode}_mode * #{unit_multiplier})")
        end
      end
    end

    # EMS calling manager
    program_calling_manager = OpenStudio::Model::EnergyManagementSystemProgramCallingManager.new(model)
    program_calling_manager.setName("#{program.name} calling manager")
    program_calling_manager.setCallingPoint('EndOfZoneTimestepAfterZoneReporting')
    program_calling_manager.addProgram(program)
  end

  # Creates airflow outputs (for infiltration, ventilation, etc.) that sum across all individual dwelling
  # units for output reporting.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param hpxml_osm_map [Hash] Map of HPXML::Building objects => OpenStudio Model objects for each dwelling unit
  # @return [nil]
  def self.apply_total_airflows_ems_program(model, hpxml_osm_map)
    # Retrieve objects
    infil_vars = []
    mechvent_vars = []
    natvent_vars = []
    whf_vars = []
    unit_multipliers = []
    hpxml_osm_map.each do |hpxml_bldg, unit_model|
      infil_vars << unit_model.getEnergyManagementSystemGlobalVariables.find { |v| v.additionalProperties.getFeatureAsString('ObjectType').to_s == Constants::ObjectTypeInfiltration }
      mechvent_vars << unit_model.getEnergyManagementSystemGlobalVariables.find { |v| v.additionalProperties.getFeatureAsString('ObjectType').to_s == Constants::ObjectTypeMechanicalVentilation }
      natvent_vars << unit_model.getEnergyManagementSystemGlobalVariables.find { |v| v.additionalProperties.getFeatureAsString('ObjectType').to_s == Constants::ObjectTypeNaturalVentilation }
      whf_vars << unit_model.getEnergyManagementSystemGlobalVariables.find { |v| v.additionalProperties.getFeatureAsString('ObjectType').to_s == Constants::ObjectTypeWholeHouseFan }
      unit_multipliers << hpxml_bldg.building_construction.number_of_units
    end

    # EMS program
    program = OpenStudio::Model::EnergyManagementSystemProgram.new(model)
    program.setName('total airflows program')
    program.additionalProperties.setFeature('ObjectType', Constants::ObjectTypeTotalAirflowsProgram)
    program.addLine('Set total_infil_flow_rate = 0')
    program.addLine('Set total_mechvent_flow_rate = 0')
    program.addLine('Set total_natvent_flow_rate = 0')
    program.addLine('Set total_whf_flow_rate = 0')
    infil_vars.each_with_index do |infil_var, i|
      program.addLine("Set total_infil_flow_rate = total_infil_flow_rate + (#{infil_var.name} * #{unit_multipliers[i]})")
    end
    mechvent_vars.each_with_index do |mechvent_var, i|
      program.addLine("Set total_mechvent_flow_rate = total_mechvent_flow_rate + (#{mechvent_var.name} * #{unit_multipliers[i]})")
    end
    natvent_vars.each_with_index do |natvent_var, i|
      program.addLine("Set total_natvent_flow_rate = total_natvent_flow_rate + (#{natvent_var.name} * #{unit_multipliers[i]})")
    end
    whf_vars.each_with_index do |whf_var, i|
      program.addLine("Set total_whf_flow_rate = total_whf_flow_rate + (#{whf_var.name} * #{unit_multipliers[i]})")
    end

    # EMS calling manager
    program_calling_manager = OpenStudio::Model::EnergyManagementSystemProgramCallingManager.new(model)
    program_calling_manager.setName("#{program.name} calling manager")
    program_calling_manager.setCallingPoint('EndOfZoneTimestepAfterZoneReporting')
    program_calling_manager.addProgram(program)
  end

  # Populate fields of both unique OpenStudio objects OutputJSON and OutputControlFiles based on the debug argument.
  # Always request MessagePack output.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param debug [Boolean] If true,  writes in.osm, generates additional log output, and creates all E+ output files
  # @return [nil]
  def self.apply_output_file_controls(model, debug)
    oj = model.getOutputJSON
    oj.setOptionType('TimeSeriesAndTabular')
    oj.setOutputJSON(debug)
    oj.setOutputMessagePack(true) # Used by ReportSimulationOutput reporting measure

    ocf = model.getOutputControlFiles
    ocf.setOutputAUDIT(debug)
    ocf.setOutputCSV(debug)
    ocf.setOutputBND(debug)
    ocf.setOutputEIO(debug)
    ocf.setOutputESO(debug)
    ocf.setOutputMDD(debug)
    ocf.setOutputMTD(debug)
    ocf.setOutputMTR(debug)
    ocf.setOutputRDD(debug)
    ocf.setOutputSHD(debug)
    ocf.setOutputCSV(debug)
    ocf.setOutputSQLite(debug)
    ocf.setOutputPerfLog(debug)
  end

  # Store some data for use in reporting measure.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param hpxml [HPXML] HPXML object
  # @param hpxml_osm_map [Hash] Map of HPXML::Building objects => OpenStudio Model objects for each dwelling unit
  # @param hpxml_path [String] Path to the HPXML file
  # @param building_id [String] HPXML Building ID
  # @param hpxml_defaults_path [TODO] TODO
  # @return [nil]
  def self.apply_additional_properties(model, hpxml, hpxml_osm_map, hpxml_path, building_id, hpxml_defaults_path)
    additionalProperties = model.getBuilding.additionalProperties
    additionalProperties.setFeature('hpxml_path', hpxml_path)
    additionalProperties.setFeature('hpxml_defaults_path', hpxml_defaults_path)
    additionalProperties.setFeature('building_id', building_id.to_s)
    additionalProperties.setFeature('emissions_scenario_names', hpxml.header.emissions_scenarios.map { |s| s.name }.to_s)
    additionalProperties.setFeature('emissions_scenario_types', hpxml.header.emissions_scenarios.map { |s| s.emissions_type }.to_s)
    heated_zones, cooled_zones = [], []
    hpxml_osm_map.each do |hpxml_bldg, unit_model|
      conditioned_zone_name = unit_model.getThermalZones.find { |z| z.additionalProperties.getFeatureAsString('ObjectType').to_s == HPXML::LocationConditionedSpace }.name.to_s

      heated_zones << conditioned_zone_name if hpxml_bldg.total_fraction_heat_load_served > 0
      cooled_zones << conditioned_zone_name if hpxml_bldg.total_fraction_cool_load_served > 0
    end
    additionalProperties.setFeature('heated_zones', heated_zones.to_s)
    additionalProperties.setFeature('cooled_zones', cooled_zones.to_s)
    additionalProperties.setFeature('is_southern_hemisphere', hpxml_osm_map.keys[0].latitude < 0)
  end

  # TODO
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @return [nil]
  def self.apply_ems_debug_output(model)
    oems = model.getOutputEnergyManagementSystem
    oems.setActuatorAvailabilityDictionaryReporting('Verbose')
    oems.setInternalVariableAvailabilityDictionaryReporting('Verbose')
    oems.setEMSRuntimeLanguageDebugOutputLevel('Verbose')
  end

  # TODO
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param debug [Boolean] If true, writes the OSM/EPW files to the output dir
  # @param output_dir [String] Path of the output files directory
  # @param epw_path [String] Path to the EPW weather file
  # @return [nil]
  def self.write_debug_files(runner, model, debug, output_dir, epw_path)
    return unless debug

    # Write OSM file to run dir
    osm_output_path = File.join(output_dir, 'in.osm')
    File.write(osm_output_path, model.to_s)
    runner.registerInfo("Wrote file: #{osm_output_path}")

    # Copy EPW file to run dir
    epw_output_path = File.join(output_dir, 'in.epw')
    FileUtils.cp(epw_path, epw_output_path)
  end

  # TODO
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @return [TODO] TODO
  def self.get_total_hvac_capacities(hpxml_bldg)
    htg_cap, clg_cap, hp_backup_cap = 0.0, 0.0, 0.0
    unit_multiplier = hpxml_bldg.building_construction.number_of_units
    hpxml_bldg.hvac_systems.each do |hvac_system|
      if hvac_system.is_a? HPXML::HeatingSystem
        next if hvac_system.is_heat_pump_backup_system

        htg_cap += hvac_system.heating_capacity.to_f * unit_multiplier
      elsif hvac_system.is_a? HPXML::CoolingSystem
        clg_cap += hvac_system.cooling_capacity.to_f * unit_multiplier
        if hvac_system.has_integrated_heating
          htg_cap += hvac_system.integrated_heating_system_capacity.to_f * unit_multiplier
        end
      elsif hvac_system.is_a? HPXML::HeatPump
        htg_cap += hvac_system.heating_capacity.to_f * unit_multiplier
        clg_cap += hvac_system.cooling_capacity.to_f * unit_multiplier
        if hvac_system.backup_type == HPXML::HeatPumpBackupTypeIntegrated
          hp_backup_cap += hvac_system.backup_heating_capacity.to_f * unit_multiplier
        elsif hvac_system.backup_type == HPXML::HeatPumpBackupTypeSeparate
          hp_backup_cap += hvac_system.backup_system.heating_capacity.to_f * unit_multiplier
        end
      end
    end
    return htg_cap, clg_cap, hp_backup_cap
  end

  # TODO
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @return [TODO] TODO
  def self.get_total_hvac_airflows(hpxml_bldg)
    htg_cfm, clg_cfm = 0.0, 0.0
    unit_multiplier = hpxml_bldg.building_construction.number_of_units
    hpxml_bldg.hvac_systems.each do |hvac_system|
      if hvac_system.is_a? HPXML::HeatingSystem
        htg_cfm += hvac_system.heating_airflow_cfm.to_f * unit_multiplier
      elsif hvac_system.is_a? HPXML::CoolingSystem
        clg_cfm += hvac_system.cooling_airflow_cfm.to_f * unit_multiplier
        if hvac_system.has_integrated_heating
          htg_cfm += hvac_system.integrated_heating_system_airflow_cfm.to_f * unit_multiplier
        end
      elsif hvac_system.is_a? HPXML::HeatPump
        htg_cfm += hvac_system.heating_airflow_cfm.to_f * unit_multiplier
        clg_cfm += hvac_system.cooling_airflow_cfm.to_f * unit_multiplier
      end
    end
    return htg_cfm, clg_cfm
  end

  # TODO
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param results_out [TODO] TODO
  # @return [TODO] TODO
  def self.append_sizing_results(hpxml_bldgs, results_out)
    line_break = nil

    # Summary HVAC capacities
    results_out << ['HVAC Capacity: Heating (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| Outputs.get_total_hvac_capacities(hpxml_bldg)[0] }.sum(0.0).round(1)]
    results_out << ['HVAC Capacity: Cooling (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| Outputs.get_total_hvac_capacities(hpxml_bldg)[1] }.sum(0.0).round(1)]
    results_out << ['HVAC Capacity: Heat Pump Backup (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| Outputs.get_total_hvac_capacities(hpxml_bldg)[2] }.sum(0.0).round(1)]

    # HVAC design temperatures
    results_out << [line_break]
    results_out << ['HVAC Design Temperature: Heating (F)', (hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.header.manualj_heating_design_temp }.sum(0.0) / hpxml_bldgs.size).round(2)]
    results_out << ['HVAC Design Temperature: Cooling (F)', (hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.header.manualj_cooling_design_temp }.sum(0.0) / hpxml_bldgs.size).round(2)]

    # HVAC Building design loads
    results_out << [line_break]
    results_out << ['HVAC Design Load: Heating: Total (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.hdl_total * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Heating: Ducts (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.hdl_ducts * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Heating: Windows (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.hdl_windows * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Heating: Skylights (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.hdl_skylights * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Heating: Doors (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.hdl_doors * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Heating: Walls (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.hdl_walls * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Heating: Roofs (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.hdl_roofs * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Heating: Floors (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.hdl_floors * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Heating: Slabs (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.hdl_slabs * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Heating: Ceilings (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.hdl_ceilings * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Heating: Infiltration (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.hdl_infil * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Heating: Ventilation (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.hdl_vent * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Heating: Piping (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.hdl_piping * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Cooling Sensible: Total (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.cdl_sens_total * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Cooling Sensible: Ducts (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.cdl_sens_ducts * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Cooling Sensible: Windows (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.cdl_sens_windows * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Cooling Sensible: Skylights (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.cdl_sens_skylights * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Cooling Sensible: Doors (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.cdl_sens_doors * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Cooling Sensible: Walls (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.cdl_sens_walls * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Cooling Sensible: Roofs (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.cdl_sens_roofs * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Cooling Sensible: Floors (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.cdl_sens_floors * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Cooling Sensible: Slabs (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.cdl_sens_slabs * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Cooling Sensible: Ceilings (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.cdl_sens_ceilings * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Cooling Sensible: Infiltration (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.cdl_sens_infil * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Cooling Sensible: Ventilation (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.cdl_sens_vent * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Cooling Sensible: Internal Gains (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.cdl_sens_intgains * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Cooling Sensible: Blower Heat (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.cdl_sens_blowerheat * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Cooling Sensible: AED Excursion (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.cdl_sens_aedexcursion * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Cooling Latent: Total (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.cdl_lat_total * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Cooling Latent: Ducts (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.cdl_lat_ducts * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Cooling Latent: Infiltration (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.cdl_lat_infil * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Cooling Latent: Ventilation (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.cdl_lat_vent * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Cooling Latent: Internal Gains (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.cdl_lat_intgains * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]

    # HVAC Zone design loads
    hpxml_bldgs.each do |hpxml_bldg|
      hpxml_bldg.conditioned_zones.each do |zone|
        next if zone.id.start_with? Constants::AutomaticallyAdded

        results_out << [line_break]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Heating: Total (Btu/h)", zone.hdl_total.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Heating: Ducts (Btu/h)", zone.hdl_ducts.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Heating: Windows (Btu/h)", zone.hdl_windows.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Heating: Skylights (Btu/h)", zone.hdl_skylights.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Heating: Doors (Btu/h)", zone.hdl_doors.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Heating: Walls (Btu/h)", zone.hdl_walls.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Heating: Roofs (Btu/h)", zone.hdl_roofs.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Heating: Floors (Btu/h)", zone.hdl_floors.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Heating: Slabs (Btu/h)", zone.hdl_slabs.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Heating: Ceilings (Btu/h)", zone.hdl_ceilings.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Heating: Infiltration (Btu/h)", zone.hdl_infil.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Heating: Ventilation (Btu/h)", zone.hdl_vent.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Heating: Piping (Btu/h)", zone.hdl_piping.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Cooling Sensible: Total (Btu/h)", zone.cdl_sens_total.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Cooling Sensible: Ducts (Btu/h)", zone.cdl_sens_ducts.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Cooling Sensible: Windows (Btu/h)", zone.cdl_sens_windows.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Cooling Sensible: Skylights (Btu/h)", zone.cdl_sens_skylights.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Cooling Sensible: Doors (Btu/h)", zone.cdl_sens_doors.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Cooling Sensible: Walls (Btu/h)", zone.cdl_sens_walls.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Cooling Sensible: Roofs (Btu/h)", zone.cdl_sens_roofs.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Cooling Sensible: Floors (Btu/h)", zone.cdl_sens_floors.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Cooling Sensible: Slabs (Btu/h)", zone.cdl_sens_slabs.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Cooling Sensible: Ceilings (Btu/h)", zone.cdl_sens_ceilings.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Cooling Sensible: Infiltration (Btu/h)", zone.cdl_sens_infil.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Cooling Sensible: Ventilation (Btu/h)", zone.cdl_sens_vent.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Cooling Sensible: Internal Gains (Btu/h)", zone.cdl_sens_intgains.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Cooling Sensible: Blower Heat (Btu/h)", zone.cdl_sens_blowerheat.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Cooling Sensible: AED Excursion (Btu/h)", zone.cdl_sens_aedexcursion.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Cooling Latent: Total (Btu/h)", zone.cdl_lat_total.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Cooling Latent: Ducts (Btu/h)", zone.cdl_lat_ducts.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Cooling Latent: Infiltration (Btu/h)", zone.cdl_lat_infil.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Cooling Latent: Ventilation (Btu/h)", zone.cdl_lat_vent.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Cooling Latent: Internal Gains (Btu/h)", zone.cdl_lat_intgains.round(1)]
      end
    end

    # HVAC Space design loads
    hpxml_bldgs.each do |hpxml_bldg|
      hpxml_bldg.conditioned_spaces.each do |space|
        results_out << [line_break]
        # Note: Latent loads are not calculated for spaces
        results_out << ["HVAC Space Design Load: #{space.id}: Heating: Total (Btu/h)", space.hdl_total.round(1)]
        results_out << ["HVAC Space Design Load: #{space.id}: Heating: Ducts (Btu/h)", space.hdl_ducts.round(1)]
        results_out << ["HVAC Space Design Load: #{space.id}: Heating: Windows (Btu/h)", space.hdl_windows.round(1)]
        results_out << ["HVAC Space Design Load: #{space.id}: Heating: Skylights (Btu/h)", space.hdl_skylights.round(1)]
        results_out << ["HVAC Space Design Load: #{space.id}: Heating: Doors (Btu/h)", space.hdl_doors.round(1)]
        results_out << ["HVAC Space Design Load: #{space.id}: Heating: Walls (Btu/h)", space.hdl_walls.round(1)]
        results_out << ["HVAC Space Design Load: #{space.id}: Heating: Roofs (Btu/h)", space.hdl_roofs.round(1)]
        results_out << ["HVAC Space Design Load: #{space.id}: Heating: Floors (Btu/h)", space.hdl_floors.round(1)]
        results_out << ["HVAC Space Design Load: #{space.id}: Heating: Slabs (Btu/h)", space.hdl_slabs.round(1)]
        results_out << ["HVAC Space Design Load: #{space.id}: Heating: Ceilings (Btu/h)", space.hdl_ceilings.round(1)]
        results_out << ["HVAC Space Design Load: #{space.id}: Heating: Infiltration (Btu/h)", space.hdl_infil.round(1)]
        results_out << ["HVAC Space Design Load: #{space.id}: Cooling Sensible: Total (Btu/h)", space.cdl_sens_total.round(1)]
        results_out << ["HVAC Space Design Load: #{space.id}: Cooling Sensible: Ducts (Btu/h)", space.cdl_sens_ducts.round(1)]
        results_out << ["HVAC Space Design Load: #{space.id}: Cooling Sensible: Windows (Btu/h)", space.cdl_sens_windows.round(1)]
        results_out << ["HVAC Space Design Load: #{space.id}: Cooling Sensible: Skylights (Btu/h)", space.cdl_sens_skylights.round(1)]
        results_out << ["HVAC Space Design Load: #{space.id}: Cooling Sensible: Doors (Btu/h)", space.cdl_sens_doors.round(1)]
        results_out << ["HVAC Space Design Load: #{space.id}: Cooling Sensible: Walls (Btu/h)", space.cdl_sens_walls.round(1)]
        results_out << ["HVAC Space Design Load: #{space.id}: Cooling Sensible: Roofs (Btu/h)", space.cdl_sens_roofs.round(1)]
        results_out << ["HVAC Space Design Load: #{space.id}: Cooling Sensible: Floors (Btu/h)", space.cdl_sens_floors.round(1)]
        results_out << ["HVAC Space Design Load: #{space.id}: Cooling Sensible: Slabs (Btu/h)", space.cdl_sens_slabs.round(1)]
        results_out << ["HVAC Space Design Load: #{space.id}: Cooling Sensible: Ceilings (Btu/h)", space.cdl_sens_ceilings.round(1)]
        results_out << ["HVAC Space Design Load: #{space.id}: Cooling Sensible: Infiltration (Btu/h)", space.cdl_sens_infil.round(1)]
        results_out << ["HVAC Space Design Load: #{space.id}: Cooling Sensible: Internal Gains (Btu/h)", space.cdl_sens_intgains.round(1)]
        results_out << ["HVAC Space Design Load: #{space.id}: Cooling Sensible: AED Excursion (Btu/h)", space.cdl_sens_aedexcursion.round(1)]
      end
    end

    # Geothermal loop
    results_out << [line_break]
    geothermal_loops = hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.geothermal_loops }.flatten
    num_boreholes = geothermal_loops.map { |loop| loop.num_bore_holes }.sum(0)
    total_length = geothermal_loops.map { |loop| loop.bore_length * loop.num_bore_holes }.sum(0.0)
    results_out << ['HVAC Geothermal Loop: Borehole/Trench Count', num_boreholes]
    results_out << ['HVAC Geothermal Loop: Borehole/Trench Length (ft)', (total_length / [num_boreholes, 1].max).round(1)] # [num_boreholes, 1].max to prevent divide by zero

    return results_out
  end

  # TODO
  #
  # @param results_out [TODO] TODO
  # @param output_format [TODO] TODO
  # @param output_file_path [TODO] TODO
  # @param mode [TODO] TODO
  # @return [TODO] TODO
  def self.write_results_out_to_file(results_out, output_format, output_file_path, mode = 'w')
    line_break = nil
    if ['csv'].include? output_format
      CSV.open(output_file_path, mode) { |csv| results_out.to_a.each { |elem| csv << elem } }
    elsif ['json', 'msgpack'].include? output_format
      h = {}
      results_out.each do |out|
        next if out == [line_break]

        if out[0].include? ':'
          grp, name = out[0].split(':', 2)
          h[grp] = {} if h[grp].nil?
          h[grp][name.strip] = out[1]
        else
          h[out[0]] = out[1]
        end
      end

      if output_format == 'json'
        require 'json'
        File.open(output_file_path, mode) { |json| json.write(JSON.pretty_generate(h)) }
      elsif output_format == 'msgpack'
        require 'msgpack'
        File.open(output_file_path, "#{mode}b") { |json| h.to_msgpack(json) }
      end
    end
  end
end
