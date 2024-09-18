# frozen_string_literal: true

# Collection of methods related to water heating systems.
module Waterheater
  # TODO
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param weather [WeatherFile] Weather object containing EPW information
  # @param spaces [Hash] Map of HPXML locations => OpenStudio Space objects
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param hpxml_header [HPXML::Header] HPXML Header object (one per HPXML file)
  # @param schedules_file [SchedulesFile] SchedulesFile wrapper class instance of detailed schedule files
  # @return [nil]
  def self.apply_dhw_appliances(runner, model, weather, spaces, hpxml_bldg, hpxml_header, schedules_file)
    unavailable_periods = Schedule.get_unavailable_periods(runner, SchedulesFile::Columns[:WaterHeater].name, hpxml_header.unavailable_periods)

    plantloop_map = {}
    hpxml_bldg.water_heating_systems.each do |dhw_system|
      if dhw_system.water_heater_type == HPXML::WaterHeaterTypeStorage
        apply_tank(model, runner, spaces, hpxml_bldg, hpxml_header, dhw_system, schedules_file, unavailable_periods, plantloop_map)
      elsif dhw_system.water_heater_type == HPXML::WaterHeaterTypeTankless
        apply_tankless(model, runner, spaces, hpxml_bldg, hpxml_header, dhw_system, schedules_file, unavailable_periods, plantloop_map)
      elsif dhw_system.water_heater_type == HPXML::WaterHeaterTypeHeatPump
        apply_heatpump(model, runner, spaces, hpxml_bldg, hpxml_header, dhw_system, schedules_file, unavailable_periods, plantloop_map)
      elsif [HPXML::WaterHeaterTypeCombiStorage, HPXML::WaterHeaterTypeCombiTankless].include? dhw_system.water_heater_type
        apply_combi(model, runner, spaces, hpxml_bldg, hpxml_header, dhw_system, schedules_file, unavailable_periods, plantloop_map)
      else
        fail "Unhandled water heater (#{dhw_system.water_heater_type})."
      end
    end

    HotWaterAndAppliances.apply(runner, model, weather, spaces, hpxml_bldg, hpxml_header, schedules_file, plantloop_map)

    apply_solar_thermal(model, spaces, hpxml_bldg, plantloop_map)

    # Add combi-system EMS program with water use equipment information
    apply_combi_system_EMS(model, hpxml_bldg.water_heating_systems, plantloop_map)
  end

  # TODO
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param spaces [Hash] Map of HPXML locations => OpenStudio Space objects
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param hpxml_header [HPXML::Header] HPXML Header object (one per HPXML file)
  # @param water_heating_system [TODO] TODO
  # @param schedules_file [SchedulesFile] SchedulesFile wrapper class instance of detailed schedule files
  # @param unavailable_periods [HPXML::UnavailablePeriods] Object that defines periods for, e.g., power outages or vacancies
  # @param plantloop_map [Hash] Map of HPXML System ID => OpenStudio PlantLoop objects
  # @return [nil]
  def self.apply_tank(model, runner, spaces, hpxml_bldg, hpxml_header, water_heating_system, schedules_file, unavailable_periods, plantloop_map)
    loc_space, loc_schedule = Geometry.get_space_or_schedule_from_location(water_heating_system.location, model, spaces)
    unit_multiplier = hpxml_bldg.building_construction.number_of_units
    solar_fraction = get_water_heater_solar_fraction(water_heating_system, hpxml_bldg)
    t_set_c = get_t_set_c(water_heating_system.temperature, water_heating_system.water_heater_type)
    loop = create_new_loop(model, t_set_c, hpxml_header.eri_calculation_version, unit_multiplier)

    act_vol = calc_storage_tank_actual_vol(water_heating_system.tank_volume, water_heating_system.fuel_type)
    u, ua, eta_c = calc_tank_UA(act_vol, water_heating_system, solar_fraction, hpxml_bldg.building_construction.number_of_bedrooms)
    new_heater = create_new_heater(name: Constants::ObjectTypeWaterHeater,
                                   water_heating_system: water_heating_system,
                                   act_vol: act_vol,
                                   t_set_c: t_set_c,
                                   loc_space: loc_space,
                                   loc_schedule: loc_schedule,
                                   model: model,
                                   runner: runner,
                                   u: u,
                                   ua: ua,
                                   eta_c: eta_c,
                                   schedules_file: schedules_file,
                                   unavailable_periods: unavailable_periods,
                                   unit_multiplier: unit_multiplier)
    loop.addSupplyBranchForComponent(new_heater)

    add_ec_adj(model, hpxml_bldg, new_heater, loc_space, water_heating_system, unit_multiplier)
    add_desuperheater(model, runner, water_heating_system, new_heater, loc_space, loc_schedule, loop, unit_multiplier)

    plantloop_map[water_heating_system.id] = loop
  end

  # TODO
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param spaces [Hash] Map of HPXML locations => OpenStudio Space objects
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param hpxml_header [HPXML::Header] HPXML Header object (one per HPXML file)
  # @param water_heating_system [TODO] TODO
  # @param schedules_file [SchedulesFile] SchedulesFile wrapper class instance of detailed schedule files
  # @param unavailable_periods [HPXML::UnavailablePeriods] Object that defines periods for, e.g., power outages or vacancies
  # @param plantloop_map [Hash] Map of HPXML System ID => OpenStudio PlantLoop objects
  # @return [nil]
  def self.apply_tankless(model, runner, spaces, hpxml_bldg, hpxml_header, water_heating_system, schedules_file, unavailable_periods, plantloop_map)
    loc_space, loc_schedule = Geometry.get_space_or_schedule_from_location(water_heating_system.location, model, spaces)
    unit_multiplier = hpxml_bldg.building_construction.number_of_units
    water_heating_system.heating_capacity = 100000000000.0 * unit_multiplier
    solar_fraction = get_water_heater_solar_fraction(water_heating_system, hpxml_bldg)
    t_set_c = get_t_set_c(water_heating_system.temperature, water_heating_system.water_heater_type)
    loop = create_new_loop(model, t_set_c, hpxml_header.eri_calculation_version, unit_multiplier)

    act_vol = 1.0 * unit_multiplier
    _u, ua, eta_c = calc_tank_UA(act_vol, water_heating_system, solar_fraction, hpxml_bldg.building_construction.number_of_bedrooms)
    new_heater = create_new_heater(name: Constants::ObjectTypeWaterHeater,
                                   water_heating_system: water_heating_system,
                                   act_vol: act_vol,
                                   t_set_c: t_set_c,
                                   loc_space: loc_space,
                                   loc_schedule: loc_schedule,
                                   model: model,
                                   runner: runner,
                                   ua: ua,
                                   eta_c: eta_c,
                                   schedules_file: schedules_file,
                                   unavailable_periods: unavailable_periods,
                                   unit_multiplier: unit_multiplier)

    loop.addSupplyBranchForComponent(new_heater)

    add_ec_adj(model, hpxml_bldg, new_heater, loc_space, water_heating_system, unit_multiplier)
    add_desuperheater(model, runner, water_heating_system, new_heater, loc_space, loc_schedule, loop, unit_multiplier)

    plantloop_map[water_heating_system.id] = loop
  end

  # TODO
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param spaces [Hash] Map of HPXML locations => OpenStudio Space objects
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param hpxml_header [HPXML::Header] HPXML Header object (one per HPXML file)
  # @param water_heating_system [TODO] TODO
  # @param schedules_file [SchedulesFile] SchedulesFile wrapper class instance of detailed schedule files
  # @param unavailable_periods [HPXML::UnavailablePeriods] Object that defines periods for, e.g., power outages or vacancies
  # @param plantloop_map [Hash] Map of HPXML System ID => OpenStudio PlantLoop objects
  # @return [nil]
  def self.apply_heatpump(model, runner, spaces, hpxml_bldg, hpxml_header, water_heating_system, schedules_file, unavailable_periods, plantloop_map)
    loc_space, loc_schedule = Geometry.get_space_or_schedule_from_location(water_heating_system.location, model, spaces)
    unit_multiplier = hpxml_bldg.building_construction.number_of_units
    obj_name_hpwh = Constants::ObjectTypeWaterHeater
    conditioned_zone = spaces[HPXML::LocationConditionedSpace].thermalZone.get
    solar_fraction = get_water_heater_solar_fraction(water_heating_system, hpxml_bldg)
    t_set_c = get_t_set_c(water_heating_system.temperature, water_heating_system.water_heater_type)
    loop = create_new_loop(model, t_set_c, hpxml_header.eri_calculation_version, unit_multiplier)

    h_tank = 0.0188 * water_heating_system.tank_volume + 0.0935 # Linear relationship that gets GE height at 50 gal and AO Smith height at 80 gal

    # Add in schedules for Tamb, RHamb, and the compressor
    hpwh_tamb = OpenStudio::Model::ScheduleConstant.new(model)
    hpwh_tamb.setName("#{obj_name_hpwh} Tamb act")
    hpwh_tamb.setValue(23)

    hpwh_rhamb = OpenStudio::Model::ScheduleConstant.new(model)
    hpwh_rhamb.setName("#{obj_name_hpwh} RHamb act")
    hpwh_rhamb.setValue(0.5)

    # Note: These get overwritten by EMS later, see HPWH Control program
    top_element_setpoint_schedule = OpenStudio::Model::ScheduleConstant.new(model)
    top_element_setpoint_schedule.setName("#{obj_name_hpwh} TopElementSetpoint")
    bottom_element_setpoint_schedule = OpenStudio::Model::ScheduleConstant.new(model)
    bottom_element_setpoint_schedule.setName("#{obj_name_hpwh} BottomElementSetpoint")

    setpoint_schedule = nil
    if not schedules_file.nil?
      # To handle variable setpoints, need one schedule that gets sensed and a new schedule that gets actuated
      # Sensed schedule
      setpoint_schedule = schedules_file.create_schedule_file(model, col_name: SchedulesFile::Columns[:WaterHeaterSetpoint].name)
      if not setpoint_schedule.nil?
        Schedule.set_schedule_type_limits(model, setpoint_schedule, EPlus::ScheduleTypeLimitsTemperature)

        # Actuated schedule
        control_setpoint_schedule = ScheduleConstant.new(model, "#{obj_name_hpwh} ControlSetpoint", 0.0, EPlus::ScheduleTypeLimitsTemperature, unavailable_periods: unavailable_periods)
        control_setpoint_schedule = control_setpoint_schedule.schedule
      end
    end
    if setpoint_schedule.nil?
      setpoint_schedule = ScheduleConstant.new(model, Constants::ObjectTypeWaterHeaterSetpoint, t_set_c, EPlus::ScheduleTypeLimitsTemperature, unavailable_periods: unavailable_periods)
      setpoint_schedule = setpoint_schedule.schedule

      control_setpoint_schedule = setpoint_schedule
    else
      runner.registerWarning("Both '#{SchedulesFile::Columns[:WaterHeaterSetpoint].name}' schedule file and setpoint temperature provided; the latter will be ignored.") if !t_set_c.nil?
    end

    airflow_rate = 181.0 # cfm
    min_temp = 42.0 # F
    max_temp = 120.0 # F

    # Coil:WaterHeating:AirToWaterHeatPump:Wrapped
    coil = setup_hpwh_dxcoil(model, runner, water_heating_system, hpxml_bldg.elevation, obj_name_hpwh, airflow_rate, unit_multiplier)

    # WaterHeater:Stratified
    tank = setup_hpwh_stratified_tank(model, water_heating_system, obj_name_hpwh, h_tank, solar_fraction, hpwh_tamb, bottom_element_setpoint_schedule, top_element_setpoint_schedule, unit_multiplier, hpxml_bldg.building_construction.number_of_bedrooms)
    loop.addSupplyBranchForComponent(tank)

    add_desuperheater(model, runner, water_heating_system, tank, loc_space, loc_schedule, loop, unit_multiplier)

    # Fan:SystemModel
    fan = setup_hpwh_fan(model, water_heating_system, obj_name_hpwh, airflow_rate, unit_multiplier)

    # WaterHeater:HeatPump:WrappedCondenser
    hpwh = setup_hpwh_wrapped_condenser(model, obj_name_hpwh, coil, tank, fan, h_tank, airflow_rate, hpwh_tamb, hpwh_rhamb, min_temp, max_temp, control_setpoint_schedule, unit_multiplier)

    # Amb temp & RH sensors, temp sensor shared across programs
    amb_temp_sensor, amb_rh_sensors = get_loc_temp_rh_sensors(model, obj_name_hpwh, loc_schedule, loc_space, conditioned_zone)
    hpwh_inlet_air_program = add_hpwh_inlet_air_and_zone_heat_gain_program(model, obj_name_hpwh, loc_space, hpwh_tamb, hpwh_rhamb, tank, coil, fan, amb_temp_sensor, amb_rh_sensors, unit_multiplier)

    # EMS for the HPWH control logic
    op_mode = water_heating_system.operating_mode
    hpwh_ctrl_program = add_hpwh_control_program(model, runner, obj_name_hpwh, amb_temp_sensor, top_element_setpoint_schedule, bottom_element_setpoint_schedule, min_temp, max_temp, op_mode, setpoint_schedule, control_setpoint_schedule, schedules_file)

    # ProgramCallingManagers
    program_calling_manager = OpenStudio::Model::EnergyManagementSystemProgramCallingManager.new(model)
    program_calling_manager.setName("#{obj_name_hpwh} ProgramManager")
    program_calling_manager.setCallingPoint('InsideHVACSystemIterationLoop')
    program_calling_manager.addProgram(hpwh_ctrl_program)
    program_calling_manager.addProgram(hpwh_inlet_air_program)

    add_ec_adj(model, hpxml_bldg, hpwh, loc_space, water_heating_system, unit_multiplier)

    plantloop_map[water_heating_system.id] = loop
  end

  # TODO
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param spaces [Hash] Map of HPXML locations => OpenStudio Space objects
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param hpxml_header [HPXML::Header] HPXML Header object (one per HPXML file)
  # @param water_heating_system [TODO] TODO
  # @param schedules_file [SchedulesFile] SchedulesFile wrapper class instance of detailed schedule files
  # @param unavailable_periods [HPXML::UnavailablePeriods] Object that defines periods for, e.g., power outages or vacancies
  # @param plantloop_map [Hash] Map of HPXML System ID => OpenStudio PlantLoop objects
  # @return [nil]
  def self.apply_combi(model, runner, spaces, hpxml_bldg, hpxml_header, water_heating_system, schedules_file, unavailable_periods, plantloop_map)
    loc_space, loc_schedule = Geometry.get_space_or_schedule_from_location(water_heating_system.location, model, spaces)
    unit_multiplier = hpxml_bldg.building_construction.number_of_units
    solar_fraction = get_water_heater_solar_fraction(water_heating_system, hpxml_bldg)

    boiler, boiler_plant_loop = get_combi_boiler_and_plant_loop(model, water_heating_system.related_hvac_idref)
    boiler.setName('combi boiler')
    boiler.additionalProperties.setFeature('HPXML_ID', water_heating_system.id) # Used by reporting measure
    boiler.additionalProperties.setFeature('IsCombiBoiler', true) # Used by reporting measure

    obj_name_combi = Constants::ObjectTypeWaterHeater

    if water_heating_system.water_heater_type == HPXML::WaterHeaterTypeCombiStorage
      if water_heating_system.standby_loss_value <= 0
        fail 'A negative indirect water heater standby loss was calculated, double check water heater inputs.'
      end

      act_vol = calc_storage_tank_actual_vol(water_heating_system.tank_volume, nil)
      a_side = calc_tank_areas(act_vol)[1]
      ua = calc_indirect_ua_with_standbyloss(act_vol, water_heating_system, a_side, solar_fraction, hpxml_bldg.building_construction.number_of_bedrooms)
    else
      ua = 0.0
      act_vol = 1.0
    end

    t_set_c = get_t_set_c(water_heating_system.temperature, water_heating_system.water_heater_type)
    loop = create_new_loop(model, t_set_c, hpxml_header.eri_calculation_version, unit_multiplier)

    # Create water heater
    new_heater = create_new_heater(name: obj_name_combi,
                                   water_heating_system: water_heating_system,
                                   act_vol: act_vol,
                                   t_set_c: t_set_c,
                                   loc_space: loc_space,
                                   loc_schedule: loc_schedule,
                                   model: model,
                                   runner: runner,
                                   ua: ua,
                                   is_combi: true,
                                   schedules_file: schedules_file,
                                   unavailable_periods: unavailable_periods,
                                   unit_multiplier: unit_multiplier)
    new_heater.setSourceSideDesignFlowRate(100 * unit_multiplier) # set one large number, override by EMS

    # Create alternate setpoint schedule for source side flow request
    alternate_stp_sch = new_heater.setpointTemperatureSchedule.get.clone(model).to_Schedule.get
    alternate_stp_sch.setName("#{obj_name_combi} Alt Spt")
    new_heater.setIndirectAlternateSetpointTemperatureSchedule(alternate_stp_sch)

    # Create setpoint schedule to specify source side temperature
    source_stp_sch = OpenStudio::Model::ScheduleConstant.new(model)
    source_stp_sch.setName("#{obj_name_combi} Source Spt")
    boiler_spt_mngr = model.getSetpointManagerScheduleds.find { |spt_mngr| spt_mngr.setpointNode.get == boiler_plant_loop.loopTemperatureSetpointNode }
    boiler_heating_spt = boiler_spt_mngr.to_SetpointManagerScheduled.get.schedule.to_ScheduleConstant.get.value
    # tank source side inlet temperature, degree C
    source_stp_sch.setValue(boiler_heating_spt)
    # reset dhw boiler setpoint
    boiler_spt_mngr.to_SetpointManagerScheduled.get.setSchedule(source_stp_sch)
    boiler_plant_loop.autosizeMaximumLoopFlowRate()

    # change loop equipment operation scheme to heating load
    scheme_dhw = OpenStudio::Model::PlantEquipmentOperationHeatingLoad.new(model)
    scheme_dhw.addEquipment(1000000000, new_heater)
    loop.setPrimaryPlantEquipmentOperationScheme(scheme_dhw)

    # Add dhw boiler to the load distribution scheme
    scheme = OpenStudio::Model::PlantEquipmentOperationHeatingLoad.new(model)
    scheme.addEquipment(1000000000, boiler)
    boiler_plant_loop.setPrimaryPlantEquipmentOperationScheme(scheme)
    boiler_plant_loop.addDemandBranchForComponent(new_heater)
    boiler_plant_loop.setPlantLoopVolume(0.001 * unit_multiplier) # Cannot be auto-calculated because of large default tank source side mfr(set to be overwritten by EMS)

    loop.addSupplyBranchForComponent(new_heater)

    add_ec_adj(model, hpxml_bldg, new_heater, loc_space, water_heating_system, unit_multiplier, boiler)

    plantloop_map[water_heating_system.id] = loop
  end

  # TODO
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param water_heating_system [TODO] TODO
  # @return [TODO] TODO
  def self.get_dist_energy_consumption_adjustment(hpxml_bldg, water_heating_system)
    if water_heating_system.fraction_dhw_load_served <= 0
      # No fixtures; not accounting for distribution system
      return 1.0
    end

    hot_water_distribution = hpxml_bldg.hot_water_distributions[0]

    has_uncond_bsmnt = hpxml_bldg.has_location(HPXML::LocationBasementUnconditioned)
    has_cond_bsmnt = hpxml_bldg.has_location(HPXML::LocationBasementConditioned)
    cfa = hpxml_bldg.building_construction.conditioned_floor_area
    ncfl = hpxml_bldg.building_construction.number_of_conditioned_floors

    # ANSI/RESNET 301-2014 Addendum A-2015
    # Amendment on Domestic Hot Water (DHW) Systems
    # Eq. 4.2-16
    ew_fact = get_dist_energy_waste_factor(hot_water_distribution)
    o_frac = 0.25 # fraction of hot water waste from standard operating conditions
    oew_fact = ew_fact * o_frac # standard operating condition portion of hot water energy waste
    ocd_eff = 0.0
    sew_fact = ew_fact - oew_fact
    ref_pipe_l = HotWaterAndAppliances.get_default_std_pipe_length(has_uncond_bsmnt, has_cond_bsmnt, cfa, ncfl)
    if hot_water_distribution.system_type == HPXML::DHWDistTypeStandard
      pe_ratio = hot_water_distribution.standard_piping_length / ref_pipe_l
    elsif hot_water_distribution.system_type == HPXML::DHWDistTypeRecirc
      ref_loop_l = HotWaterAndAppliances.get_default_recirc_loop_length(ref_pipe_l)
      pe_ratio = hot_water_distribution.recirculation_piping_loop_length / ref_loop_l
    end
    e_waste = oew_fact * (1.0 - ocd_eff) + sew_fact * pe_ratio
    return (e_waste + 128.0) / 160.0
  end

  # TODO
  #
  # @param hot_water_distribution [TODO] TODO
  # @return [TODO] TODO
  def self.get_dist_energy_waste_factor(hot_water_distribution)
    # ANSI/RESNET 301-2014 Addendum A-2015
    # Amendment on Domestic Hot Water (DHW) Systems
    # Table 4.2.2.5.2.11(6) Hot water distribution system relative annual energy waste factors
    if hot_water_distribution.system_type == HPXML::DHWDistTypeRecirc
      if (hot_water_distribution.recirculation_control_type == HPXML::DHWRecircControlTypeNone) ||
         (hot_water_distribution.recirculation_control_type == HPXML::DHWRecircControlTypeTimer)
        if hot_water_distribution.pipe_r_value < 3.0
          return 500.0
        else
          return 250.0
        end
      elsif hot_water_distribution.recirculation_control_type == HPXML::DHWRecircControlTypeTemperature
        if hot_water_distribution.pipe_r_value < 3.0
          return 375.0
        else
          return 187.5
        end
      elsif hot_water_distribution.recirculation_control_type == HPXML::DHWRecircControlTypeSensor
        if hot_water_distribution.pipe_r_value < 3.0
          return 64.8
        else
          return 43.2
        end
      elsif hot_water_distribution.recirculation_control_type == HPXML::DHWRecircControlTypeManual
        if hot_water_distribution.pipe_r_value < 3.0
          return 43.2
        else
          return 28.8
        end
      end
    elsif hot_water_distribution.system_type == HPXML::DHWDistTypeStandard
      if hot_water_distribution.pipe_r_value < 3.0
        return 32.0
      else
        return 28.8
      end
    end
    fail 'Unexpected hot water distribution system.'
  end

  # TODO
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param water_heating_systems [TODO] TODO
  # @param plantloop_map [TODO] TODO
  # @return [TODO] TODO
  def self.apply_combi_system_EMS(model, water_heating_systems, plantloop_map)
    water_heating_systems.select { |wh|
      [HPXML::WaterHeaterTypeCombiStorage,
       HPXML::WaterHeaterTypeCombiTankless].include? wh.water_heater_type
    }.each do |water_heating_system|
      combi_sys_id = water_heating_system.id

      # EMS for modulate source side mass flow rate
      # Initialization
      equipment_peaks = {}
      equipment_sch_sensors = {}
      equipment_target_temp_sensors = {}
      tank_volume, deadband, tank_source_temp = 0.0, 0.0, 0.0
      alt_spt_sch = nil
      tank_temp_sensor, tank_spt_sensor, tank_loss_energy_sensor = nil, nil, nil
      altsch_actuator, pump_actuator = nil, nil
      water_heater = nil

      # Create sensors and actuators
      plant_loop = plantloop_map[combi_sys_id]
      plant_loop.components.each do |c|
        next unless c.to_WaterHeaterMixed.is_initialized

        water_heater = c.to_WaterHeaterMixed.get
        tank_volume = water_heater.tankVolume.get
        deadband = water_heater.deadbandTemperatureDifference
        # Sensors and actuators related to OS water heater object
        tank_temp_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Water Heater Tank Temperature')
        tank_temp_sensor.setName("#{combi_sys_id} Tank Temp")
        tank_temp_sensor.setKeyName(water_heater.name.to_s)
        tank_loss_energy_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Water Heater Heat Loss Energy')
        tank_loss_energy_sensor.setName("#{combi_sys_id} Tank Loss Energy")
        tank_loss_energy_sensor.setKeyName(water_heater.name.to_s)
        tank_spt_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Schedule Value')
        tank_spt_sensor.setName("#{combi_sys_id} Setpoint Temperature")
        tank_spt_sensor.setKeyName(water_heater.setpointTemperatureSchedule.get.name.to_s)
        alt_spt_sch = water_heater.indirectAlternateSetpointTemperatureSchedule.get
        if alt_spt_sch.to_ScheduleConstant.is_initialized
          altsch_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(alt_spt_sch, *EPlus::EMSActuatorScheduleConstantValue)
        elsif alt_spt_sch.to_ScheduleRuleset.is_initialized
          altsch_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(alt_spt_sch, *EPlus::EMSActuatorScheduleYearValue)
        else
          altsch_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(alt_spt_sch, *EPlus::EMSActuatorScheduleFileValue)
        end
        altsch_actuator.setName("#{combi_sys_id} AltSchedOverride")
      end
      plant_loop.components.each do |c|
        next unless c.to_WaterUseConnections.is_initialized

        wuc = c.to_WaterUseConnections.get
        wuc.waterUseEquipment.each do |wu|
          # water use equipment peak mass flow rate
          wu_peak = wu.waterUseEquipmentDefinition.peakFlowRate
          equipment_peaks[wu.name.to_s] = wu_peak
          # mfr fraction schedule sensors
          wu_sch_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Schedule Value')
          wu_sch_sensor.setName("#{wu.name} sch value")
          wu_sch_sensor.setKeyName(wu.flowRateFractionSchedule.get.name.to_s)
          equipment_sch_sensors[wu.name.to_s] = wu_sch_sensor
          # water use equipment target temperature schedule sensors
          if wu.waterUseEquipmentDefinition.targetTemperatureSchedule.is_initialized
            target_temp_sch = wu.waterUseEquipmentDefinition.targetTemperatureSchedule.get
          else
            target_temp_sch = water_heater.setpointTemperatureSchedule.get
          end
          target_temp_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Schedule Value')
          target_temp_sensor.setName("#{wu.name} target temp")
          target_temp_sensor.setKeyName(target_temp_sch.name.to_s)
          equipment_target_temp_sensors[wu.name.to_s] = target_temp_sensor
        end
      end
      dhw_source_loop = model.getPlantLoops.find { |l| l.demandComponents.include? water_heater }
      dhw_source_loop.components.each do |c|
        next unless c.to_PumpVariableSpeed.is_initialized

        pump = c.to_PumpVariableSpeed.get
        pump_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(pump, *EPlus::EMSActuatorPumpMassFlowRate)
        pump_actuator.setName("#{combi_sys_id} Pump MFR")
      end
      dhw_source_loop.supplyOutletNode.setpointManagers.each do |setpoint_manager|
        if setpoint_manager.to_SetpointManagerScheduled.is_initialized
          tank_source_temp = setpoint_manager.to_SetpointManagerScheduled.get.schedule.to_ScheduleConstant.get.value
        end
      end

      mains_temp_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Site Mains Water Temperature')
      mains_temp_sensor.setName('Mains Temperature')
      mains_temp_sensor.setKeyName('Environment')

      # Program
      combi_ctrl_program = OpenStudio::Model::EnergyManagementSystemProgram.new(model)
      combi_ctrl_program.setName("#{combi_sys_id} Source MFR Control")
      combi_ctrl_program.addLine("Set Rho = @RhoH2O #{tank_temp_sensor.name}")
      combi_ctrl_program.addLine("Set Cp = @CpHW #{tank_temp_sensor.name}")
      combi_ctrl_program.addLine("Set Tank_Water_Mass = #{tank_volume} * Rho")
      combi_ctrl_program.addLine("Set DeltaT = #{tank_source_temp} - #{tank_spt_sensor.name}")
      combi_ctrl_program.addLine("Set WU_Hot_Temp = #{tank_temp_sensor.name}")
      combi_ctrl_program.addLine("Set WU_Cold_Temp = #{mains_temp_sensor.name}")
      combi_ctrl_program.addLine('Set Tank_Use_Total_MFR = 0.0')
      equipment_peaks.each do |wu_name, peak|
        wu_id = wu_name.gsub(' ', '_')
        combi_ctrl_program.addLine("Set #{wu_id}_Peak = #{peak}")
        combi_ctrl_program.addLine("Set #{wu_id}_MFR_Total = #{wu_id}_Peak * #{equipment_sch_sensors[wu_name].name} * Rho")
        combi_ctrl_program.addLine("If #{equipment_target_temp_sensors[wu_name].name} > WU_Hot_Temp")
        combi_ctrl_program.addLine("Set #{wu_id}_MFR_Hot = #{wu_id}_MFR_Total")
        combi_ctrl_program.addLine('Else')
        combi_ctrl_program.addLine("Set #{wu_id}_MFR_Hot = #{wu_id}_MFR_Total * (#{equipment_target_temp_sensors[wu_name].name} - WU_Cold_Temp)/(WU_Hot_Temp - WU_Cold_Temp)")
        combi_ctrl_program.addLine('EndIf')
        combi_ctrl_program.addLine("Set Tank_Use_Total_MFR = Tank_Use_Total_MFR + #{wu_id}_MFR_Hot")
      end
      combi_ctrl_program.addLine("Set WH_Loss = - #{tank_loss_energy_sensor.name}")
      combi_ctrl_program.addLine("Set WH_Use = Tank_Use_Total_MFR * Cp * (#{tank_temp_sensor.name} - #{mains_temp_sensor.name}) * ZoneTimeStep * 3600")
      combi_ctrl_program.addLine("Set WH_HeatToLowSetpoint = Tank_Water_Mass * Cp * (#{tank_temp_sensor.name} - #{tank_spt_sensor.name} + #{deadband})")
      combi_ctrl_program.addLine("Set WH_HeatToHighSetpoint = Tank_Water_Mass * Cp * (#{tank_temp_sensor.name} - #{tank_spt_sensor.name})")
      combi_ctrl_program.addLine('Set WH_Energy_Demand = WH_Use + WH_Loss - WH_HeatToLowSetpoint')
      combi_ctrl_program.addLine('Set WH_Energy_Heat = WH_Use + WH_Loss - WH_HeatToHighSetpoint')
      combi_ctrl_program.addLine('If WH_Energy_Demand > 0')
      combi_ctrl_program.addLine("Set #{pump_actuator.name} = WH_Energy_Heat / (Cp * DeltaT * 3600 * ZoneTimeStep)")
      combi_ctrl_program.addLine("Set #{altsch_actuator.name} = 100") # Set the alternate setpoint temperature to highest level to ensure maximum source side flow rate
      combi_ctrl_program.addLine('Else')
      combi_ctrl_program.addLine("Set #{pump_actuator.name} = 0")
      combi_ctrl_program.addLine("Set #{altsch_actuator.name} = NULL")
      combi_ctrl_program.addLine('EndIf')

      # ProgramCallingManagers
      program_calling_manager = OpenStudio::Model::EnergyManagementSystemProgramCallingManager.new(model)
      program_calling_manager.setName("#{combi_sys_id} ProgramManager")
      program_calling_manager.setCallingPoint('BeginZoneTimestepAfterInitHeatBalance')
      program_calling_manager.addProgram(combi_ctrl_program)
    end
  end

  # TODO
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param spaces [Hash] Map of HPXML locations => OpenStudio Space objects
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param plantloop_map [TODO] TODO
  # @return [nil]
  def self.apply_solar_thermal(model, spaces, hpxml_bldg, plantloop_map)
    return if hpxml_bldg.solar_thermal_systems.size == 0

    solar_thermal_system = hpxml_bldg.solar_thermal_systems[0]
    return if solar_thermal_system.collector_area.nil? # Return if simple (not detailed) solar water heater type

    if [HPXML::WaterHeaterTypeCombiStorage, HPXML::WaterHeaterTypeCombiTankless].include? solar_thermal_system.water_heating_system.water_heater_type
      fail "Water heating system '#{solar_thermal_system.water_heating_system.id}' connected to solar thermal system '#{solar_thermal_system.id}' cannot be a space-heating boiler."
    end
    if solar_thermal_system.water_heating_system.uses_desuperheater
      fail "Water heating system '#{solar_thermal_system.water_heating_system.id}' connected to solar thermal system '#{solar_thermal_system.id}' cannot be attached to a desuperheater."
    end

    loc_space, loc_schedule = Geometry.get_space_or_schedule_from_location(solar_thermal_system.water_heating_system.location, model, spaces)
    dhw_loop = plantloop_map[solar_thermal_system.water_heating_system.id]
    unit_multiplier = hpxml_bldg.building_construction.number_of_units

    obj_name = Constants::ObjectTypeSolarHotWater

    if [HPXML::SolarThermalCollectorTypeEvacuatedTube].include? solar_thermal_system.collector_type
      iam_coeff2 = 0.3023 # IAM coeff1=1 by definition, values based on a system listed by SRCC with values close to the average
      iam_coeff3 = -0.3057
    elsif [HPXML::SolarThermalCollectorTypeSingleGlazing, HPXML::SolarThermalCollectorTypeDoubleGlazing].include? solar_thermal_system.collector_type
      iam_coeff2 = 0.1
      iam_coeff3 = 0
    elsif [HPXML::SolarThermalCollectorTypeICS].include? solar_thermal_system.collector_type
      iam_coeff2 = 0.1
      iam_coeff3 = 0
    end

    if [HPXML::SolarThermalLoopTypeIndirect].include? solar_thermal_system.collector_loop_type
      fluid_type = EPlus::FluidPropyleneGlycol
      heat_ex_eff = 0.7
    elsif [HPXML::SolarThermalLoopTypeDirect, HPXML::SolarThermalLoopTypeThermosyphon].include? solar_thermal_system.collector_loop_type
      fluid_type = EPlus::FluidWater
      heat_ex_eff = 1.0
    end

    collector_area = solar_thermal_system.collector_area * unit_multiplier
    storage_volume = solar_thermal_system.storage_volume * unit_multiplier

    if solar_thermal_system.collector_loop_type == HPXML::SolarThermalLoopTypeThermosyphon
      pump_power = 0.0
    else
      pump_power = 0.8 * collector_area
    end

    test_flow = 55.0 / UnitConversions.convert(1.0, 'lbm/min', 'kg/hr') / Liquid.H2O_l.rho * UnitConversions.convert(1.0, 'ft^2', 'm^2') # cfm/ft^2
    coll_flow = test_flow * collector_area # cfm
    if fluid_type == EPlus::FluidWater # Direct, make the storage tank a dummy tank with 0 tank losses
      u_tank = 0.0
    else
      r_tank = 10.0 # Btu/(hr-ft2-F)
      u_tank = UnitConversions.convert(1.0 / r_tank, 'Btu/(hr*ft^2*F)', 'W/(m^2*K)') # W/m2-K
    end

    # Get water heater and setpoint temperature schedules from loop
    water_heater = nil
    setpoint_schedule_one = nil
    setpoint_schedule_two = nil
    dhw_loop.supplyComponents.each do |supply_component|
      if supply_component.to_WaterHeaterMixed.is_initialized
        water_heater = supply_component.to_WaterHeaterMixed.get
        setpoint_schedule_one = water_heater.setpointTemperatureSchedule.get
        setpoint_schedule_two = water_heater.setpointTemperatureSchedule.get
      elsif supply_component.to_WaterHeaterStratified.is_initialized
        water_heater = supply_component.to_WaterHeaterStratified.get
        setpoint_schedule_one = water_heater.heater1SetpointTemperatureSchedule
        setpoint_schedule_two = water_heater.heater2SetpointTemperatureSchedule
      end
    end

    dhw_setpoint_manager = nil
    dhw_loop.supplyOutletNode.setpointManagers.each do |setpoint_manager|
      if setpoint_manager.to_SetpointManagerScheduled.is_initialized
        dhw_setpoint_manager = setpoint_manager.to_SetpointManagerScheduled.get
      end
    end

    plant_loop = OpenStudio::Model::PlantLoop.new(model)
    plant_loop.setName('solar hot water loop')
    if fluid_type == EPlus::FluidWater
      plant_loop.setFluidType(EPlus::FluidWater)
    else
      plant_loop.setFluidType(EPlus::FluidPropyleneGlycol)
      plant_loop.setGlycolConcentration(50)
    end
    plant_loop.setMaximumLoopTemperature(100)
    plant_loop.setMinimumLoopTemperature(0)
    plant_loop.setMinimumLoopFlowRate(0)
    plant_loop.setLoadDistributionScheme('Optimal')
    plant_loop.setPlantEquipmentOperationHeatingLoadSchedule(model.alwaysOnDiscreteSchedule)

    sizing_plant = plant_loop.sizingPlant
    sizing_plant.setLoopType('Heating')
    sizing_plant.setDesignLoopExitTemperature(dhw_loop.sizingPlant.designLoopExitTemperature)
    sizing_plant.setLoopDesignTemperatureDifference(UnitConversions.convert(10.0, 'deltaF', 'deltaC'))

    setpoint_manager = OpenStudio::Model::SetpointManagerScheduled.new(model, dhw_setpoint_manager.schedule)
    setpoint_manager.setName(obj_name + ' setpoint mgr')
    setpoint_manager.setControlVariable('Temperature')

    pump = OpenStudio::Model::PumpConstantSpeed.new(model)
    pump.setName(obj_name + ' pump')
    pump.setRatedPumpHead(90000)
    pump.setRatedPowerConsumption(pump_power)
    pump.setMotorEfficiency(0.3)
    pump.setFractionofMotorInefficienciestoFluidStream(0.2)
    pump.setPumpControlType('Intermittent')
    pump.setRatedFlowRate(UnitConversions.convert(coll_flow, 'cfm', 'm^3/s'))
    pump.addToNode(plant_loop.supplyInletNode)
    pump.additionalProperties.setFeature('HPXML_ID', solar_thermal_system.water_heating_system.id) # Used by reporting measure
    pump.additionalProperties.setFeature('ObjectType', Constants::ObjectTypeSolarHotWater) # Used by reporting measure

    panel_length = UnitConversions.convert(collector_area, 'ft^2', 'm^2')**0.5
    run = Math::cos(solar_thermal_system.collector_tilt * Math::PI / 180) * panel_length

    offset = 1000.0 # prevent shading

    vertices = OpenStudio::Point3dVector.new
    vertices << OpenStudio::Point3d.new(offset, offset, 0)
    vertices << OpenStudio::Point3d.new(offset + panel_length, offset, 0)
    vertices << OpenStudio::Point3d.new(offset + panel_length, offset + run, (panel_length**2 - run**2)**0.5)
    vertices << OpenStudio::Point3d.new(offset, offset + run, (panel_length**2 - run**2)**0.5)

    m = OpenStudio::Matrix.new(4, 4, 0)
    azimuth = Float(solar_thermal_system.collector_azimuth)
    m[0, 0] = Math::cos((180 - azimuth) * Math::PI / 180)
    m[1, 1] = Math::cos((180 - azimuth) * Math::PI / 180)
    m[0, 1] = -Math::sin((180 - azimuth) * Math::PI / 180)
    m[1, 0] = Math::sin((180 - azimuth) * Math::PI / 180)
    m[2, 2] = 1
    m[3, 3] = 1
    transformation = OpenStudio::Transformation.new(m)
    vertices = transformation * vertices

    shading_surface_group = OpenStudio::Model::ShadingSurfaceGroup.new(model)
    shading_surface_group.setName(obj_name + ' shading group')

    shading_surface = OpenStudio::Model::ShadingSurface.new(vertices, model)
    shading_surface.setName(obj_name + ' shading surface')
    shading_surface.setShadingSurfaceGroup(shading_surface_group)

    if solar_thermal_system.collector_type == HPXML::SolarThermalCollectorTypeICS
      collector_plate = OpenStudio::Model::SolarCollectorIntegralCollectorStorage.new(model)
      collector_plate.setName(obj_name + ' coll plate')
      collector_plate.setSurface(shading_surface)
      collector_plate.setMaximumFlowRate(UnitConversions.convert(coll_flow, 'cfm', 'm^3/s'))

      ics_performance = collector_plate.solarCollectorPerformance
      # Values are based on spec sheet + OG-100 listing for Solarheart ICS collectors
      ics_performance.setName(obj_name + ' coll perf')
      ics_performance.setGrossArea(UnitConversions.convert(collector_area, 'ft^2', 'm^2'))
      ics_performance.setCollectorWaterVolume(UnitConversions.convert(storage_volume, 'gal', 'm^3'))
      ics_performance.setBottomHeatLossConductance(1.902) # Spec sheet
      ics_performance.setSideHeatLossConductance(1.268)
      ics_performance.setAspectRatio(0.721)
      ics_performance.setCollectorSideHeight(0.17272)
      ics_performance.setNumberOfCovers(1)
      ics_performance.setAbsorptanceOfAbsorberPlate(0.94)
      ics_performance.setEmissivityOfAbsorberPlate(0.56)
      collector_plate.setSolarCollectorPerformance(ics_performance)

    else
      collector_plate = OpenStudio::Model::SolarCollectorFlatPlateWater.new(model)
      collector_plate.setName(obj_name + ' coll plate')
      collector_plate.setSurface(shading_surface)
      collector_plate.setMaximumFlowRate(UnitConversions.convert(coll_flow, 'cfm', 'm^3/s'))
      collector_performance = collector_plate.solarCollectorPerformance
      collector_performance.setName(obj_name + ' coll perf')
      collector_performance.setGrossArea(UnitConversions.convert(collector_area, 'ft^2', 'm^2'))
      collector_performance.setTestFluid(EPlus::FluidWater)
      collector_performance.setTestFlowRate(UnitConversions.convert(coll_flow, 'cfm', 'm^3/s'))
      collector_performance.setTestCorrelationType('Inlet')
      collector_performance.setCoefficient1ofEfficiencyEquation(solar_thermal_system.collector_rated_optical_efficiency)
      collector_performance.setCoefficient2ofEfficiencyEquation(-UnitConversions.convert(solar_thermal_system.collector_rated_thermal_losses, 'Btu/(hr*ft^2*F)', 'W/(m^2*K)'))
      collector_performance.setCoefficient2ofIncidentAngleModifier(-iam_coeff2)
      collector_performance.setCoefficient3ofIncidentAngleModifier(iam_coeff3)

    end

    plant_loop.addSupplyBranchForComponent(collector_plate)

    pipe_supply_bypass = OpenStudio::Model::PipeAdiabatic.new(model)
    pipe_supply_outlet = OpenStudio::Model::PipeAdiabatic.new(model)
    pipe_demand_bypass = OpenStudio::Model::PipeAdiabatic.new(model)
    pipe_demand_inlet = OpenStudio::Model::PipeAdiabatic.new(model)
    pipe_demand_outlet = OpenStudio::Model::PipeAdiabatic.new(model)

    plant_loop.addSupplyBranchForComponent(pipe_supply_bypass)
    pump.addToNode(plant_loop.supplyInletNode)
    pipe_supply_outlet.addToNode(plant_loop.supplyOutletNode)
    setpoint_manager.addToNode(plant_loop.supplyOutletNode)
    plant_loop.addDemandBranchForComponent(pipe_demand_bypass)
    pipe_demand_inlet.addToNode(plant_loop.demandInletNode)
    pipe_demand_outlet.addToNode(plant_loop.demandOutletNode)

    storage_tank = OpenStudio::Model::WaterHeaterStratified.new(model)
    storage_tank.setName(obj_name + ' storage tank')
    storage_tank.setSourceSideEffectiveness(heat_ex_eff)
    storage_tank.setTankShape('VerticalCylinder')
    if (solar_thermal_system.collector_type == HPXML::SolarThermalCollectorTypeICS) || (fluid_type == EPlus::FluidWater) # Use a 60 gal tank dummy tank for direct systems, storage volume for ICS is assumed to be collector volume
      tank_volume = UnitConversions.convert(60 * unit_multiplier, 'gal', 'm^3')
    else
      tank_volume = UnitConversions.convert(storage_volume, 'gal', 'm^3')
    end
    tank_height = UnitConversions.convert(4.5, 'ft', 'm')
    storage_tank.setTankVolume(tank_volume)
    storage_tank.setTankHeight(tank_height)
    storage_tank.setUseSideOutletHeight(tank_height)
    storage_tank.setSourceSideInletHeight(tank_height / 3.0)
    storage_tank.setMaximumTemperatureLimit(99)
    storage_tank.heater1SetpointTemperatureSchedule.remove
    storage_tank.setHeater1SetpointTemperatureSchedule(setpoint_schedule_one)
    storage_tank.setHeater1Capacity(0)
    storage_tank.setHeater1Height(0)
    storage_tank.heater2SetpointTemperatureSchedule.remove
    storage_tank.setHeater2SetpointTemperatureSchedule(setpoint_schedule_two)
    storage_tank.setHeater2Capacity(0)
    storage_tank.setHeater2Height(0)
    storage_tank.setHeaterFuelType(EPlus::FuelTypeElectricity)
    storage_tank.setHeaterThermalEfficiency(1)
    storage_tank.ambientTemperatureSchedule.get.remove
    set_wh_ambient(loc_space, loc_schedule, storage_tank)
    storage_tank.setSkinLossFractiontoZone(1.0 / unit_multiplier) # Tank losses are multiplied by E+ zone multiplier, so need to compensate here
    storage_tank.setOffCycleFlueLossFractiontoZone(1.0 / unit_multiplier)
    storage_tank.setUseSideEffectiveness(1)
    storage_tank.setUseSideInletHeight(0)
    storage_tank.setSourceSideOutletHeight(0)
    storage_tank.setInletMode('Fixed')
    storage_tank.setIndirectWaterHeatingRecoveryTime(1.5)
    storage_tank.setNumberofNodes(8)
    storage_tank.setAdditionalDestratificationConductivity(0)
    storage_tank.setSourceSideDesignFlowRate(UnitConversions.convert(coll_flow, 'cfm', 'm^3/s'))
    storage_tank.setOnCycleParasiticFuelConsumptionRate(0)
    storage_tank.setOffCycleParasiticFuelConsumptionRate(0)
    storage_tank.setUseSideDesignFlowRate(UnitConversions.convert(storage_volume, 'gal', 'm^3') / 60.1) # Sized to ensure that E+ never autosizes the design flow rate to be larger than the tank volume getting drawn out in a hour (60 minutes)
    set_stratified_tank_ua(storage_tank, u_tank, unit_multiplier)
    storage_tank.additionalProperties.setFeature('HPXML_ID', solar_thermal_system.water_heating_system.id) # Used by reporting measure
    storage_tank.additionalProperties.setFeature('ObjectType', Constants::ObjectTypeSolarHotWater) # Used by reporting measure

    plant_loop.addDemandBranchForComponent(storage_tank)
    dhw_loop.addSupplyBranchForComponent(storage_tank)
    water_heater.addToNode(storage_tank.supplyOutletModelObject.get.to_Node.get)

    availability_manager = OpenStudio::Model::AvailabilityManagerDifferentialThermostat.new(model)
    availability_manager.setName(obj_name + ' useful energy')
    availability_manager.setHotNode(collector_plate.outletModelObject.get.to_Node.get)
    availability_manager.setColdNode(storage_tank.demandOutletModelObject.get.to_Node.get)
    availability_manager.setTemperatureDifferenceOnLimit(0)
    availability_manager.setTemperatureDifferenceOffLimit(0)
    plant_loop.addAvailabilityManager(availability_manager)

    # Add EMS code for SWH control (keeps the WH for the last hour if there's useful energy that can be delivered, E+ wouldn't always do this by default)
    # Sensors
    coll_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'System Node Temperature')
    coll_sensor.setName("#{obj_name} Collector Outlet")
    coll_sensor.setKeyName("#{collector_plate.outletModelObject.get.to_Node.get.name}")

    tank_source_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'System Node Temperature')
    tank_source_sensor.setName("#{obj_name} Tank Source Inlet")
    tank_source_sensor.setKeyName("#{storage_tank.demandOutletModelObject.get.to_Node.get.name}")

    # Actuators
    swh_pump_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(pump, *EPlus::EMSActuatorPumpMassFlowRate)
    swh_pump_actuator.setName("#{obj_name}_pump")

    # Program
    swh_program = OpenStudio::Model::EnergyManagementSystemProgram.new(model)
    swh_program.setName("#{obj_name} Controller")
    swh_program.addLine("If #{coll_sensor.name} > #{tank_source_sensor.name}")
    swh_program.addLine("Set #{swh_pump_actuator.name} = 100 * #{unit_multiplier}")
    swh_program.addLine('Else')
    swh_program.addLine("Set #{swh_pump_actuator.name} = 0")
    swh_program.addLine('EndIf')

    # ProgramCallingManager
    program_calling_manager = OpenStudio::Model::EnergyManagementSystemProgramCallingManager.new(model)
    program_calling_manager.setName("#{obj_name} Control")
    program_calling_manager.setCallingPoint('InsideHVACSystemIterationLoop')
    program_calling_manager.addProgram(swh_program)
  end

  # TODO
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param obj_name_hpwh [TODO] TODO
  # @param coil [TODO] TODO
  # @param tank [TODO] TODO
  # @param fan [TODO] TODO
  # @param h_tank [TODO] TODO
  # @param airflow_rate [TODO] TODO
  # @param hpwh_tamb [TODO] TODO
  # @param hpwh_rhamb [TODO] TODO
  # @param min_temp [TODO] TODO
  # @param max_temp [TODO] TODO
  # @param setpoint_schedule [TODO] TODO
  # @param unit_multiplier [Integer] Number of similar dwelling units
  # @return [TODO] TODO
  def self.setup_hpwh_wrapped_condenser(model, obj_name_hpwh, coil, tank, fan, h_tank, airflow_rate, hpwh_tamb, hpwh_rhamb, min_temp, max_temp, setpoint_schedule, unit_multiplier)
    h_condtop = (1.0 - (5.5 / 12.0)) * h_tank # in the 6th node of the tank (counting from top)
    h_condbot = 0.01 * unit_multiplier # bottom node
    h_hpctrl_up = (1.0 - (2.5 / 12.0)) * h_tank # in the 3rd node of the tank
    h_hpctrl_low = (1.0 - (8.5 / 12.0)) * h_tank # in the 9th node of the tank

    hpwh = OpenStudio::Model::WaterHeaterHeatPumpWrappedCondenser.new(model, coil, tank, fan, setpoint_schedule, model.alwaysOnDiscreteSchedule)
    hpwh.setName("#{obj_name_hpwh} hpwh")
    hpwh.setDeadBandTemperatureDifference(3.89)
    hpwh.setCondenserBottomLocation(h_condbot)
    hpwh.setCondenserTopLocation(h_condtop)
    hpwh.setEvaporatorAirFlowRate(UnitConversions.convert(airflow_rate * unit_multiplier, 'ft^3/min', 'm^3/s'))
    hpwh.setInletAirConfiguration('Schedule')
    hpwh.setInletAirTemperatureSchedule(hpwh_tamb)
    hpwh.setInletAirHumiditySchedule(hpwh_rhamb)
    hpwh.setMinimumInletAirTemperatureforCompressorOperation(UnitConversions.convert(min_temp, 'F', 'C'))
    hpwh.setMaximumInletAirTemperatureforCompressorOperation(UnitConversions.convert(max_temp, 'F', 'C'))
    hpwh.setCompressorLocation('Schedule')
    hpwh.setCompressorAmbientTemperatureSchedule(hpwh_tamb)
    hpwh.setFanPlacement('DrawThrough')
    hpwh.setOnCycleParasiticElectricLoad(0)
    hpwh.setOffCycleParasiticElectricLoad(0)
    hpwh.setParasiticHeatRejectionLocation('Outdoors')
    hpwh.setTankElementControlLogic('MutuallyExclusive')
    hpwh.setControlSensor1HeightInStratifiedTank(h_hpctrl_up)
    hpwh.setControlSensor1Weight(0.75)
    hpwh.setControlSensor2HeightInStratifiedTank(h_hpctrl_low)

    return hpwh
  end

  # TODO
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param water_heating_system [TODO] TODO
  # @param elevation [Double] Elevation of the building site (ft)
  # @param obj_name_hpwh [TODO] TODO
  # @param airflow_rate [TODO] TODO
  # @param unit_multiplier [Integer] Number of similar dwelling units
  # @return [TODO] TODO
  def self.setup_hpwh_dxcoil(model, runner, water_heating_system, elevation, obj_name_hpwh, airflow_rate, unit_multiplier)
    # Curves
    hpwh_cap = OpenStudio::Model::CurveBiquadratic.new(model)
    hpwh_cap.setName('HPWH-Cap-fT')
    hpwh_cap.setCoefficient1Constant(0.563)
    hpwh_cap.setCoefficient2x(0.0437)
    hpwh_cap.setCoefficient3xPOW2(0.000039)
    hpwh_cap.setCoefficient4y(0.0055)
    hpwh_cap.setCoefficient5yPOW2(-0.000148)
    hpwh_cap.setCoefficient6xTIMESY(-0.000145)
    hpwh_cap.setMinimumValueofx(0)
    hpwh_cap.setMaximumValueofx(100)
    hpwh_cap.setMinimumValueofy(0)
    hpwh_cap.setMaximumValueofy(100)

    hpwh_cop = OpenStudio::Model::CurveBiquadratic.new(model)
    hpwh_cop.setName('HPWH-COP-fT')
    hpwh_cop.setCoefficient1Constant(1.1332)
    hpwh_cop.setCoefficient2x(0.063)
    hpwh_cop.setCoefficient3xPOW2(-0.0000979)
    hpwh_cop.setCoefficient4y(-0.00972)
    hpwh_cop.setCoefficient5yPOW2(-0.0000214)
    hpwh_cop.setCoefficient6xTIMESY(-0.000686)
    hpwh_cop.setMinimumValueofx(0)
    hpwh_cop.setMaximumValueofx(100)
    hpwh_cop.setMinimumValueofy(0)
    hpwh_cop.setMaximumValueofy(100)

    # Assumptions and values
    cap = 0.5 * unit_multiplier # kW
    shr = 0.88 # unitless

    # Calculate an altitude adjusted rated evaporator wetbulb temperature
    rated_ewb_F = 56.4
    rated_edb_F = 67.5
    p_atm = UnitConversions.convert(1.0, 'atm', 'psi')
    rated_edb = UnitConversions.convert(rated_edb_F, 'F', 'C')
    w_rated = Psychrometrics.w_fT_Twb_P(rated_edb_F, rated_ewb_F, p_atm)
    dp_rated = Psychrometrics.Tdp_fP_w(p_atm, w_rated)
    p_atm = Psychrometrics.Pstd_fZ(elevation)
    w_adj = Psychrometrics.w_fT_Twb_P(dp_rated, dp_rated, p_atm)
    twb_adj = Psychrometrics.Twb_fT_w_P(runner, rated_edb_F, w_adj, p_atm)

    # Calculate the COP based on EF
    if not water_heating_system.energy_factor.nil?
      uef = (0.60522 + water_heating_system.energy_factor) / 1.2101
      cop = 1.174536058 * uef # Based on simulation of the UEF test procedure at varying COPs
    elsif not water_heating_system.uniform_energy_factor.nil?
      uef = water_heating_system.uniform_energy_factor
      if water_heating_system.usage_bin == HPXML::WaterHeaterUsageBinVerySmall
        fail 'It is unlikely that a heat pump water heater falls into the very small bin of the First Hour Rating (FHR) test. Double check input.'
      elsif water_heating_system.usage_bin == HPXML::WaterHeaterUsageBinLow
        cop = 1.0005 * uef - 0.0789
      elsif water_heating_system.usage_bin == HPXML::WaterHeaterUsageBinMedium
        cop = 1.0909 * uef - 0.0868
      elsif water_heating_system.usage_bin == HPXML::WaterHeaterUsageBinHigh
        cop = 1.1022 * uef - 0.0877
      end
    end

    coil = OpenStudio::Model::CoilWaterHeatingAirToWaterHeatPumpWrapped.new(model)
    coil.setName("#{obj_name_hpwh} coil")
    coil.setRatedHeatingCapacity(UnitConversions.convert(cap, 'kW', 'W') * cop)
    coil.setRatedCOP(cop)
    coil.setRatedSensibleHeatRatio(shr)
    coil.setRatedEvaporatorInletAirDryBulbTemperature(rated_edb)
    coil.setRatedEvaporatorInletAirWetBulbTemperature(UnitConversions.convert(twb_adj, 'F', 'C'))
    coil.setRatedCondenserWaterTemperature(48.89)
    coil.setRatedEvaporatorAirFlowRate(UnitConversions.convert(airflow_rate * unit_multiplier, 'ft^3/min', 'm^3/s'))
    coil.setEvaporatorFanPowerIncludedinRatedCOP(true)
    coil.setEvaporatorAirTemperatureTypeforCurveObjects('WetBulbTemperature')
    coil.setHeatingCapacityFunctionofTemperatureCurve(hpwh_cap)
    coil.setHeatingCOPFunctionofTemperatureCurve(hpwh_cop)
    coil.setMaximumAmbientTemperatureforCrankcaseHeaterOperation(0)
    coil.additionalProperties.setFeature('HPXML_ID', water_heating_system.id) # Used by reporting measure

    return coil
  end

  # TODO
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param water_heating_system [TODO] TODO
  # @param obj_name_hpwh [TODO] TODO
  # @param h_tank [TODO] TODO
  # @param solar_fraction [TODO] TODO
  # @param hpwh_tamb [TODO] TODO
  # @param hpwh_bottom_element_sp [TODO] TODO
  # @param hpwh_top_element_sp [TODO] TODO
  # @param unit_multiplier [Integer] Number of similar dwelling units
  # @param nbeds [Integer] Number of bedrooms in the dwelling unit
  # @return [TODO] TODO
  def self.setup_hpwh_stratified_tank(model, water_heating_system, obj_name_hpwh, h_tank, solar_fraction, hpwh_tamb, hpwh_bottom_element_sp, hpwh_top_element_sp, unit_multiplier, nbeds)
    # Calculate some geometry parameters for UA, the location of sensors and heat sources in the tank
    v_actual = calc_storage_tank_actual_vol(water_heating_system.tank_volume, water_heating_system.fuel_type) # gal
    a_tank, a_side = calc_tank_areas(v_actual, UnitConversions.convert(h_tank, 'm', 'ft')) # sqft

    e_cap = 4.5 # kW
    parasitics = 3.0 # W
    # Based on Ecotope lab testing of most recent AO Smith HPWHs (series HPTU)
    if water_heating_system.tank_volume <= 58.0
      tank_ua = 3.6 # Btu/h-R
    elsif water_heating_system.tank_volume <= 73.0
      tank_ua = 4.0 # Btu/h-R
    else
      tank_ua = 4.7 # Btu/h-R
    end
    tank_ua = apply_tank_jacket(water_heating_system, tank_ua, a_side)
    tank_ua = apply_shared_adjustment(water_heating_system, tank_ua, nbeds) # shared losses
    u_tank = ((5.678 * tank_ua) / a_tank) * (1.0 - solar_fraction)

    v_actual *= unit_multiplier
    e_cap *= unit_multiplier
    parasitics *= unit_multiplier

    h_UE = (1.0 - (3.5 / 12.0)) * h_tank # in the 3rd node of the tank (counting from top)
    h_LE = (1.0 - (9.5 / 12.0)) * h_tank # in the 10th node of the tank (counting from top)

    tank = OpenStudio::Model::WaterHeaterStratified.new(model)
    tank.setName("#{obj_name_hpwh} tank")
    tank.setEndUseSubcategory('Domestic Hot Water')
    tank.setTankVolume(UnitConversions.convert(v_actual, 'gal', 'm^3'))
    tank.setTankHeight(h_tank)
    tank.setMaximumTemperatureLimit(90)
    tank.setHeaterPriorityControl('MasterSlave')
    tank.heater1SetpointTemperatureSchedule.remove
    tank.setHeater1SetpointTemperatureSchedule(hpwh_top_element_sp)
    tank.setHeater1Capacity(UnitConversions.convert(e_cap, 'kW', 'W'))
    tank.setHeater1Height(h_UE)
    tank.setHeater1DeadbandTemperatureDifference(18.5)
    tank.heater2SetpointTemperatureSchedule.remove
    tank.setHeater2SetpointTemperatureSchedule(hpwh_bottom_element_sp)
    tank.setHeater2Capacity(UnitConversions.convert(e_cap, 'kW', 'W'))
    tank.setHeater2Height(h_LE)
    tank.setHeater2DeadbandTemperatureDifference(3.89)
    tank.setHeaterFuelType(EPlus::FuelTypeElectricity)
    tank.setHeaterThermalEfficiency(1.0)
    tank.setOffCycleParasiticFuelConsumptionRate(parasitics)
    tank.setOffCycleParasiticFuelType(EPlus::FuelTypeElectricity)
    tank.setOnCycleParasiticFuelConsumptionRate(parasitics)
    tank.setOnCycleParasiticFuelType(EPlus::FuelTypeElectricity)
    tank.ambientTemperatureSchedule.get.remove
    tank.setAmbientTemperatureSchedule(hpwh_tamb)
    tank.setNumberofNodes(6)
    tank.setAdditionalDestratificationConductivity(0)
    tank.setUseSideDesignFlowRate(UnitConversions.convert(v_actual, 'gal', 'm^3') / 60.1) # Sized to ensure that E+ never autosizes the design flow rate to be larger than the tank volume getting drawn out in a hour (60 minutes)
    tank.setSourceSideDesignFlowRate(0)
    tank.setSourceSideFlowControlMode('')
    tank.setSourceSideInletHeight(0)
    tank.setSourceSideOutletHeight(0)
    tank.setSkinLossFractiontoZone(1.0 / unit_multiplier) # Tank losses are multiplied by E+ zone multiplier, so need to compensate here
    tank.setOffCycleFlueLossFractiontoZone(1.0 / unit_multiplier)
    set_stratified_tank_ua(tank, u_tank, unit_multiplier)
    tank.additionalProperties.setFeature('HPXML_ID', water_heating_system.id) # Used by reporting measure

    return tank
  end

  # TODO
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param water_heating_system [TODO] TODO
  # @param obj_name_hpwh [TODO] TODO
  # @param airflow_rate [TODO] TODO
  # @param unit_multiplier [Integer] Number of similar dwelling units
  # @return [TODO] TODO
  def self.setup_hpwh_fan(model, water_heating_system, obj_name_hpwh, airflow_rate, unit_multiplier)
    fan_power = 0.0462 # W/cfm, Based on 1st gen AO Smith HPWH, could be updated but pretty minor impact
    fan = OpenStudio::Model::FanSystemModel.new(model)
    fan.setSpeedControlMethod('Discrete')
    fan.setDesignPowerSizingMethod('PowerPerFlow')
    fan.setElectricPowerPerUnitFlowRate(fan_power / UnitConversions.convert(1.0, 'cfm', 'm^3/s'))
    fan.setAvailabilitySchedule(model.alwaysOnDiscreteSchedule)
    fan.setName(obj_name_hpwh + ' fan')
    fan.setEndUseSubcategory('Domestic Hot Water')
    fan.setMotorEfficiency(1.0)
    fan.setMotorInAirStreamFraction(1.0)
    fan.setDesignMaximumAirFlowRate(UnitConversions.convert(airflow_rate * unit_multiplier, 'ft^3/min', 'm^3/s'))
    fan.additionalProperties.setFeature('HPXML_ID', water_heating_system.id) # Used by reporting measure
    fan.additionalProperties.setFeature('ObjectType', Constants::ObjectTypeWaterHeater) # Used by reporting measure

    return fan
  end

  # TODO
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param obj_name_hpwh [TODO] TODO
  # @param loc_schedule [TODO] TODO
  # @param loc_space [TODO] TODO
  # @param conditioned_zone [TODO] TODO
  # @return [TODO] TODO
  def self.get_loc_temp_rh_sensors(model, obj_name_hpwh, loc_schedule, loc_space, conditioned_zone)
    rh_sensors = []
    if not loc_schedule.nil?
      amb_temp_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Schedule Value')
      amb_temp_sensor.setName("#{obj_name_hpwh} amb temp")
      amb_temp_sensor.setKeyName(loc_schedule.name.to_s)

      if loc_schedule.name.get == HPXML::LocationOtherNonFreezingSpace
        amb_rh_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Site Outdoor Air Relative Humidity')
        amb_rh_sensor.setName("#{obj_name_hpwh} amb rh")
        amb_rh_sensor.setKeyName('Environment')
        rh_sensors << amb_rh_sensor
      elsif loc_schedule.name.get == HPXML::LocationOtherHousingUnit
        amb_rh_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Zone Air Relative Humidity')
        amb_rh_sensor.setName("#{obj_name_hpwh} amb rh")
        amb_rh_sensor.setKeyName(conditioned_zone.name.to_s)
        rh_sensors << amb_rh_sensor
      else
        amb_rh_sensor1 = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Site Outdoor Air Relative Humidity')
        amb_rh_sensor1.setName("#{obj_name_hpwh} amb1 rh")
        amb_rh_sensor1.setKeyName('Environment')
        amb_rh_sensor2 = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Zone Air Relative Humidity')
        amb_rh_sensor2.setName("#{obj_name_hpwh} amb2 rh")
        amb_rh_sensor2.setKeyName(conditioned_zone.name.to_s)
        rh_sensors << amb_rh_sensor1
        rh_sensors << amb_rh_sensor2
      end
    elsif not loc_space.nil?
      amb_temp_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Zone Mean Air Temperature')
      amb_temp_sensor.setName("#{obj_name_hpwh} amb temp")
      amb_temp_sensor.setKeyName(loc_space.thermalZone.get.name.to_s)

      amb_rh_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Zone Air Relative Humidity')
      amb_rh_sensor.setName("#{obj_name_hpwh} amb rh")
      amb_rh_sensor.setKeyName(loc_space.thermalZone.get.name.to_s)
      rh_sensors << amb_rh_sensor
    else # Located outside
      amb_temp_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Site Outdoor Air Drybulb Temperature')
      amb_temp_sensor.setName("#{obj_name_hpwh} amb temp")
      amb_temp_sensor.setKeyName('Environment')

      amb_rh_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Site Outdoor Air Relative Humidity')
      amb_rh_sensor.setName("#{obj_name_hpwh} amb rh")
      amb_rh_sensor.setKeyName('Environment')
      rh_sensors << amb_rh_sensor
    end
    return amb_temp_sensor, rh_sensors
  end

  # TODO
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param obj_name_hpwh [TODO] TODO
  # @param loc_space [TODO] TODO
  # @param hpwh_tamb [TODO] TODO
  # @param hpwh_rhamb [TODO] TODO
  # @param tank [TODO] TODO
  # @param coil [TODO] TODO
  # @param fan [TODO] TODO
  # @param amb_temp_sensor [TODO] TODO
  # @param amb_rh_sensors [TODO] TODO
  # @param unit_multiplier [Integer] Number of similar dwelling units
  # @return [TODO] TODO
  def self.add_hpwh_inlet_air_and_zone_heat_gain_program(model, obj_name_hpwh, loc_space, hpwh_tamb, hpwh_rhamb, tank, coil, fan, amb_temp_sensor, amb_rh_sensors, unit_multiplier)
    # EMS Actuators: Inlet T & RH, sensible and latent gains to the space
    tamb_act_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(hpwh_tamb, *EPlus::EMSActuatorScheduleConstantValue)
    tamb_act_actuator.setName("#{obj_name_hpwh} Tamb act")

    rhamb_act_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(hpwh_rhamb, *EPlus::EMSActuatorScheduleConstantValue)
    rhamb_act_actuator.setName("#{obj_name_hpwh} RHamb act")

    if not loc_space.nil? # If located in space
      # Add in other equipment objects for sensible/latent gains
      hpwh_sens_def = OpenStudio::Model::OtherEquipmentDefinition.new(model)
      hpwh_sens_def.setName("#{obj_name_hpwh} sens")
      hpwh_sens = OpenStudio::Model::OtherEquipment.new(hpwh_sens_def)
      hpwh_sens.setName(hpwh_sens_def.name.to_s)
      hpwh_sens.setSpace(loc_space)
      hpwh_sens_def.setDesignLevel(0)
      hpwh_sens_def.setFractionRadiant(0)
      hpwh_sens_def.setFractionLatent(0)
      hpwh_sens_def.setFractionLost(0)
      hpwh_sens.setSchedule(model.alwaysOnDiscreteSchedule)

      hpwh_lat_def = OpenStudio::Model::OtherEquipmentDefinition.new(model)
      hpwh_lat_def.setName("#{obj_name_hpwh} lat")
      hpwh_lat = OpenStudio::Model::OtherEquipment.new(hpwh_lat_def)
      hpwh_lat.setName(hpwh_lat_def.name.to_s)
      hpwh_lat.setSpace(loc_space)
      hpwh_lat_def.setDesignLevel(0)
      hpwh_lat_def.setFractionRadiant(0)
      hpwh_lat_def.setFractionLatent(1)
      hpwh_lat_def.setFractionLost(0)
      hpwh_lat.setSchedule(model.alwaysOnDiscreteSchedule)

      sens_act_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(hpwh_sens, *EPlus::EMSActuatorOtherEquipmentPower, hpwh_sens.space.get)
      sens_act_actuator.setName("#{hpwh_sens.name} act")

      lat_act_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(hpwh_lat, *EPlus::EMSActuatorOtherEquipmentPower, hpwh_lat.space.get)
      lat_act_actuator.setName("#{hpwh_lat.name} act")
    end

    # EMS Sensors: HP sens and latent loads, tank losses, fan power
    tl_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Water Heater Heat Loss Rate')
    tl_sensor.setName("#{obj_name_hpwh} tl")
    tl_sensor.setKeyName(tank.name.to_s)

    sens_cool_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Cooling Coil Sensible Cooling Rate')
    sens_cool_sensor.setName("#{obj_name_hpwh} sens cool")
    sens_cool_sensor.setKeyName(coil.name.to_s)

    lat_cool_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Cooling Coil Latent Cooling Rate')
    lat_cool_sensor.setName("#{obj_name_hpwh} lat cool")
    lat_cool_sensor.setKeyName(coil.name.to_s)

    fan_power_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, "Fan #{EPlus::FuelTypeElectricity} Rate")
    fan_power_sensor.setName("#{obj_name_hpwh} fan pwr")
    fan_power_sensor.setKeyName(fan.name.to_s)

    hpwh_inlet_air_program = OpenStudio::Model::EnergyManagementSystemProgram.new(model)
    hpwh_inlet_air_program.setName("#{obj_name_hpwh} InletAir")
    hpwh_inlet_air_program.addLine("Set #{tamb_act_actuator.name} = #{amb_temp_sensor.name}")
    # Average relative humidity for mf spaces: other multifamily buffer space & other heated space
    hpwh_inlet_air_program.addLine("Set #{rhamb_act_actuator.name} = 0")
    amb_rh_sensors.each do |amb_rh_sensor|
      hpwh_inlet_air_program.addLine("Set #{rhamb_act_actuator.name} = #{rhamb_act_actuator.name} + (#{amb_rh_sensor.name} / 100) / #{amb_rh_sensors.size}")
    end
    if not loc_space.nil?
      # Sensible/latent heat gain to the space
      # Tank losses are multiplied by E+ zone multiplier, so need to compensate here
      hpwh_inlet_air_program.addLine("Set #{sens_act_actuator.name} = (0 - #{sens_cool_sensor.name} - (#{tl_sensor.name} + #{fan_power_sensor.name})) / #{unit_multiplier}")
      hpwh_inlet_air_program.addLine("Set #{lat_act_actuator.name} = (0 - #{lat_cool_sensor.name}) / #{unit_multiplier}")
    end
    return hpwh_inlet_air_program
  end

  # TODO
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param obj_name_hpwh [TODO] TODO
  # @param amb_temp_sensor [TODO] TODO
  # @param hpwh_top_element_sp [TODO] TODO
  # @param hpwh_bottom_element_sp [TODO] TODO
  # @param min_temp [TODO] TODO
  # @param max_temp [TODO] TODO
  # @param op_mode [TODO] TODO
  # @param setpoint_schedule [TODO] TODO
  # @param control_setpoint_schedule [TODO] TODO
  # @param schedules_file [SchedulesFile] SchedulesFile wrapper class instance of detailed schedule files
  # @return [TODO] TODO
  def self.add_hpwh_control_program(model, runner, obj_name_hpwh, amb_temp_sensor, hpwh_top_element_sp, hpwh_bottom_element_sp, min_temp, max_temp, op_mode, setpoint_schedule, control_setpoint_schedule, schedules_file)
    # Lower element is enabled if the ambient air temperature prevents the HP from running
    leschedoverride_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(hpwh_bottom_element_sp, *EPlus::EMSActuatorScheduleConstantValue)
    leschedoverride_actuator.setName("#{obj_name_hpwh} LESchedOverride")

    # Upper element is enabled unless mode is HP_only
    ueschedoverride_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(hpwh_top_element_sp, *EPlus::EMSActuatorScheduleConstantValue)
    ueschedoverride_actuator.setName("#{obj_name_hpwh} UESchedOverride")

    # Actuator for setpoint schedule
    if control_setpoint_schedule.to_ScheduleConstant.is_initialized
      hpwhschedoverride_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(control_setpoint_schedule, *EPlus::EMSActuatorScheduleConstantValue)
    elsif control_setpoint_schedule.to_ScheduleRuleset.is_initialized
      hpwhschedoverride_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(control_setpoint_schedule, *EPlus::EMSActuatorScheduleYearValue)
    end
    hpwhschedoverride_actuator.setName("#{obj_name_hpwh} HPWHSchedOverride")

    # EMS for the HPWH control logic
    t_set_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Schedule Value')
    t_set_sensor.setName("#{obj_name_hpwh} T_set")
    t_set_sensor.setKeyName(setpoint_schedule.name.to_s)

    op_mode_schedule = nil
    if not schedules_file.nil?
      op_mode_schedule = schedules_file.create_schedule_file(model, col_name: SchedulesFile::Columns[:WaterHeaterOperatingMode].name)
    end

    # Sensor on op_mode_schedule
    if not op_mode_schedule.nil?
      Schedule.set_schedule_type_limits(model, op_mode_schedule, EPlus::ScheduleTypeLimitsFraction)

      op_mode_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Schedule Value')
      op_mode_sensor.setName("#{obj_name_hpwh} op_mode")
      op_mode_sensor.setKeyName(op_mode_schedule.name.to_s)

      runner.registerWarning("Both '#{SchedulesFile::Columns[:WaterHeaterOperatingMode].name}' schedule file and operating mode provided; the latter will be ignored.") if !op_mode.nil?
    end

    t_offset = 9.0 # C
    min_temp_c = UnitConversions.convert(min_temp, 'F', 'C').round(2)
    max_temp_c = UnitConversions.convert(max_temp, 'F', 'C').round(2)

    hpwh_ctrl_program = OpenStudio::Model::EnergyManagementSystemProgram.new(model)
    hpwh_ctrl_program.setName("#{obj_name_hpwh} Control")
    hpwh_ctrl_program.addLine("Set #{hpwhschedoverride_actuator.name} = #{t_set_sensor.name}")
    # If in HP only mode: still enable elements if ambient temperature is out of bounds, otherwise disable elements
    if op_mode == HPXML::WaterHeaterOperatingModeHeatPumpOnly
      hpwh_ctrl_program.addLine("If (#{amb_temp_sensor.name}<#{min_temp_c}) || (#{amb_temp_sensor.name}>#{max_temp_c})")
      hpwh_ctrl_program.addLine("Set #{leschedoverride_actuator.name} = #{t_set_sensor.name}")
      hpwh_ctrl_program.addLine("Set #{ueschedoverride_actuator.name} = #{t_set_sensor.name}")
      hpwh_ctrl_program.addLine('Else')
      hpwh_ctrl_program.addLine("Set #{leschedoverride_actuator.name} = 0")
      hpwh_ctrl_program.addLine("Set #{ueschedoverride_actuator.name} = 0")
      hpwh_ctrl_program.addLine('EndIf')
    else
      # First, check if ambient temperature is out of bounds for HP operation, if so enable lower element
      hpwh_ctrl_program.addLine("If (#{amb_temp_sensor.name}<#{min_temp_c}) || (#{amb_temp_sensor.name}>#{max_temp_c})")
      hpwh_ctrl_program.addLine("Set #{ueschedoverride_actuator.name} = #{t_set_sensor.name}")
      hpwh_ctrl_program.addLine("Set #{leschedoverride_actuator.name} = #{t_set_sensor.name}")
      hpwh_ctrl_program.addLine('Else')
      hpwh_ctrl_program.addLine("Set #{ueschedoverride_actuator.name} = #{t_set_sensor.name} - #{t_offset}")
      hpwh_ctrl_program.addLine("Set #{leschedoverride_actuator.name} = 0")
      hpwh_ctrl_program.addLine('EndIf')
      # Scheduled operating mode: if in HP only mode, disable both elements (this will override prior logic)
      if not op_mode_schedule.nil?
        hpwh_ctrl_program.addLine("If #{op_mode_sensor.name} == 1")
        hpwh_ctrl_program.addLine("Set #{ueschedoverride_actuator.name} = 0")
        hpwh_ctrl_program.addLine('Else')
        hpwh_ctrl_program.addLine("Set #{ueschedoverride_actuator.name} = #{t_set_sensor.name} - #{t_offset}")
        hpwh_ctrl_program.addLine('EndIf')
      end
    end
    return hpwh_ctrl_program
  end

  # TODO
  #
  # @param tank [TODO] TODO
  # @param u_tank [TODO] TODO
  # @param unit_multiplier [Integer] Number of similar dwelling units
  # @return [TODO] TODO
  def self.set_stratified_tank_ua(tank, u_tank, unit_multiplier)
    node_ua = [0] * 12 # Max number of nodes in E+ stratified tank model
    if unit_multiplier == 1
      tank.setUniformSkinLossCoefficientperUnitAreatoAmbientTemperature(u_tank)
    else
      tank.setUniformSkinLossCoefficientperUnitAreatoAmbientTemperature(0)

      # Calculate UA for each node; this is needed to accommodate unit multipliers where
      # the surface area for each node is not scaled proportionally.
      vol_tank = UnitConversions.convert(tank.tankVolume.get, 'm^3', 'gal')
      h_tank = UnitConversions.convert(tank.tankHeight.get, 'm', 'ft')

      # Calculate areas for tank w/o unit multiplier
      a_tank, a_side = calc_tank_areas(vol_tank / unit_multiplier, h_tank)
      a_top = (a_tank - a_side) / 2.0
      num_nodes = tank.numberofNodes

      # Calculate desired UA for each node
      for node_num in 0..num_nodes - 1
        # These node area calculations are based on the E+ WaterThermalTankData::SetupStratifiedNodes() method
        a_node = a_side / num_nodes
        if (node_num == 0) || (node_num == num_nodes - 1) # Top or bottom node
          a_node += a_top
        end
        node_ua[node_num] = u_tank.to_f * UnitConversions.convert(a_node, 'ft^2', 'm^2') * unit_multiplier
      end
    end

    tank.setNode1AdditionalLossCoefficient(node_ua[0])
    tank.setNode2AdditionalLossCoefficient(node_ua[1])
    tank.setNode3AdditionalLossCoefficient(node_ua[2])
    tank.setNode4AdditionalLossCoefficient(node_ua[3])
    tank.setNode5AdditionalLossCoefficient(node_ua[4])
    tank.setNode6AdditionalLossCoefficient(node_ua[5])
    tank.setNode7AdditionalLossCoefficient(node_ua[6])
    tank.setNode8AdditionalLossCoefficient(node_ua[7])
    tank.setNode9AdditionalLossCoefficient(node_ua[8])
    tank.setNode10AdditionalLossCoefficient(node_ua[9])
    tank.setNode11AdditionalLossCoefficient(node_ua[10])
    tank.setNode12AdditionalLossCoefficient(node_ua[11])
  end

  # TODO
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param heating_source_id [TODO] TODO
  # @return [TODO] TODO
  def self.get_combi_boiler_and_plant_loop(model, heating_source_id)
    # Search for the right boiler OS object
    boiler_hw = nil
    plant_loop_hw = nil
    model.getBoilerHotWaters.each do |bhw|
      sys_id = bhw.additionalProperties.getFeatureAsString('HPXML_ID')
      next unless sys_id.is_initialized && sys_id.get == heating_source_id

      plant_loop = bhw.plantLoop.get
      plant_loop_hw = plant_loop.clone(model).to_PlantLoop.get

      # set pump power for water heating to zero
      plant_loop_hw.supplyComponents.each do |comp|
        if comp.to_BoilerHotWater.is_initialized
          boiler_hw = comp.to_BoilerHotWater.get
        end
        next unless comp.to_PumpVariableSpeed.is_initialized

        pump_hw = comp.to_PumpVariableSpeed.get
        pump_hw.setRatedPowerConsumption(0.0)
      end
    end
    return boiler_hw, plant_loop_hw
  end

  # TODO
  #
  # @param water_heating_system [TODO] TODO
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @return [TODO] TODO
  def self.get_desuperheatercoil(water_heating_system, model)
    (model.getCoilCoolingDXSingleSpeeds +
     model.getCoilCoolingDXMultiSpeeds +
     model.getCoilCoolingWaterToAirHeatPumpEquationFits).each do |clg_coil|
      sys_id = clg_coil.additionalProperties.getFeatureAsString('HPXML_ID')
      if sys_id.is_initialized && sys_id.get == water_heating_system.related_hvac_idref
        return clg_coil
      end
    end
    fail "RelatedHVACSystem '#{water_heating_system.related_hvac_idref}' for water heating system '#{water_heating_system.id}' is not currently supported for desuperheaters."
  end

  # TODO
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param water_heating_system [TODO] TODO
  # @param tank [TODO] TODO
  # @param loc_space [TODO] TODO
  # @param loc_schedule [TODO] TODO
  # @param loop [TODO] TODO
  # @param unit_multiplier [Integer] Number of similar dwelling units
  # @return [TODO] TODO
  def self.add_desuperheater(model, runner, water_heating_system, tank, loc_space, loc_schedule, loop, unit_multiplier)
    return unless water_heating_system.uses_desuperheater

    desuperheater_clg_coil = get_desuperheatercoil(water_heating_system, model)
    reclaimed_efficiency = 0.25 # default
    desuperheater_name = "#{tank.name} desuperheater"

    # create a storage tank
    vol = 50.0
    storage_vol_actual = calc_storage_tank_actual_vol(vol, nil)
    assumed_ua = 6.0 # Btu/hr-F, tank ua calculated based on 1.0 standby_loss and 50gal nominal vol
    storage_tank_name = "#{tank.name} storage tank"
    # reduce tank setpoint to enable desuperheater setpoint at t_set
    if water_heating_system.temperature.nil?
      fail "Detailed setpoints for water heating system '#{water_heating_system.id}' is not currently supported for desuperheaters."
    else
      tank_setpoint = get_t_set_c(water_heating_system.temperature - 5.0, HPXML::WaterHeaterTypeStorage)
    end

    storage_tank = create_new_heater(name: storage_tank_name,
                                     act_vol: storage_vol_actual,
                                     t_set_c: tank_setpoint,
                                     loc_space: loc_space,
                                     loc_schedule: loc_schedule,
                                     model: model,
                                     runner: runner,
                                     ua: assumed_ua,
                                     is_dsh_storage: true,
                                     unit_multiplier: unit_multiplier)

    loop.addSupplyBranchForComponent(storage_tank)
    tank.addToNode(storage_tank.supplyOutletModelObject.get.to_Node.get)

    # Create a schedule for desuperheater
    new_schedule = OpenStudio::Model::ScheduleConstant.new(model)
    new_schedule.setName("#{desuperheater_name} setpoint schedule")
    # Preheat tank desuperheater setpoint set to be the same as main water heater
    dsh_setpoint = get_t_set_c(water_heating_system.temperature, HPXML::WaterHeaterTypeStorage)
    new_schedule.setValue(dsh_setpoint)

    # create a desuperheater object
    desuperheater = OpenStudio::Model::CoilWaterHeatingDesuperheater.new(model, new_schedule)
    desuperheater.setName(desuperheater_name)
    desuperheater.setMaximumInletWaterTemperatureforHeatReclaim(100)
    desuperheater.setDeadBandTemperatureDifference(0.2)
    desuperheater.setRatedHeatReclaimRecoveryEfficiency(reclaimed_efficiency)
    desuperheater.addToHeatRejectionTarget(storage_tank)
    # FUTURE: Desuperheater pump power?
    desuperheater.setWaterPumpPower(0)
    # attach to the clg coil source
    desuperheater.setHeatingSource(desuperheater_clg_coil)
    desuperheater.setWaterFlowRate(0.0001 * unit_multiplier)
    desuperheater.additionalProperties.setFeature('HPXML_ID', water_heating_system.id) # Used by reporting measure
  end

  # TODO
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param name [TODO] TODO
  # @return [TODO] TODO
  def self.create_new_hx(model, name)
    hx = OpenStudio::Model::HeatExchangerFluidToFluid.new(model)
    hx.setName(name)
    hx.setControlType('OperationSchemeModulated')

    return hx
  end

  # TODO
  #
  # @param fuel [TODO] TODO
  # @param num_beds [TODO] TODO
  # @param num_water_heaters [TODO] TODO
  # @param num_baths [TODO] TODO
  # @return [TODO] TODO
  def self.get_default_heating_capacity(fuel, num_beds, num_water_heaters, num_baths = nil)
    # Returns the capacity of the water heater based on the fuel type and number
    # of bedrooms and bathrooms in a home. Returns the capacity in kBtu/hr.
    # Source: Table 8. Benchmark DHW Storage and Burner Capacity in 2014 BA HSP

    if num_baths.nil?
      num_baths = get_default_num_bathrooms(num_beds)
    end

    # Adjust the heating capacity if there are multiple water heaters in the home
    num_baths /= num_water_heaters.to_f

    if fuel != HPXML::FuelTypeElectricity
      if num_beds <= 3
        cap_kbtuh = 36.0
      elsif num_beds == 4
        cap_kbtuh = 38.0
      elsif num_beds == 5
        cap_kbtuh = 48.0
      else
        cap_kbtuh = 50.0
      end
      return cap_kbtuh
    else
      if num_beds == 1
        cap_kw = 2.5
      elsif num_beds == 2
        if num_baths <= 1.5
          cap_kw = 3.5
        else
          cap_kw = 4.5
        end
      elsif num_beds == 3
        if num_baths <= 1.5
          cap_kw = 4.5
        else
          cap_kw = 5.5
        end
      else
        cap_kw = 5.5
      end
      return UnitConversions.convert(cap_kw, 'kW', 'kBtu/hr')
    end
  end

  # TODO
  #
  # @param fuel [TODO] TODO
  # @param num_beds [TODO] TODO
  # @param num_baths [TODO] TODO
  # @return [TODO] TODO
  def self.get_default_tank_volume(fuel, num_beds, num_baths)
    # Returns the volume of a water heater based on the BA HSP
    # Source: Table 8. Benchmark DHW Storage and Burner Capacity in 2014 BA HSP
    if fuel != HPXML::FuelTypeElectricity # Non-electric tank WHs
      if num_beds <= 2
        return 30.0
      elsif num_beds == 3
        if num_baths <= 1.5
          return 30.0
        else
          return 40.0
        end
      elsif num_beds == 4
        if num_baths <= 2.5
          return 40.0
        else
          return 50.0
        end
      else
        return 50.0
      end
    else
      if num_beds == 1
        return 30.0
      elsif num_beds == 2
        if num_baths <= 1.5
          return 30.0
        else
          return 40.0
        end
      elsif num_beds == 3
        if num_baths <= 1.5
          return 40.0
        else
          return 50.0
        end
      elsif num_beds == 4
        if num_baths <= 2.5
          return 50.0
        else
          return 66.0
        end
      elsif num_beds == 5
        return 66.0
      else
        return 80.0
      end
    end
  end

  # TODO
  #
  # @param water_heating_system [TODO] TODO
  # @return [TODO] TODO
  def self.get_default_recovery_efficiency(water_heating_system)
    # Water Heater Recovery Efficiency by fuel and energy factor
    if water_heating_system.fuel_type == HPXML::FuelTypeElectricity
      return 0.98
    else
      # FUTURE: Develop a separate algorithm specific to UEF.
      ef = water_heating_system.energy_factor
      if ef.nil?
        ef = calc_ef_from_uef(water_heating_system)
      end
      if ef >= 0.75
        re = 0.561 * ef + 0.439
      else
        re = 0.252 * ef + 0.608
      end
      return re
    end
  end

  # TODO
  #
  # @param water_heating_system [TODO] TODO
  # @return [TODO] TODO
  def self.calc_ef_from_uef(water_heating_system)
    # Interpretation on Water Heater UEF
    if water_heating_system.fuel_type == HPXML::FuelTypeElectricity
      if water_heating_system.water_heater_type == HPXML::WaterHeaterTypeStorage
        return [2.4029 * water_heating_system.uniform_energy_factor - 1.2844, 0.96].min
      elsif water_heating_system.water_heater_type == HPXML::WaterHeaterTypeTankless
        return water_heating_system.uniform_energy_factor
      elsif water_heating_system.water_heater_type == HPXML::WaterHeaterTypeHeatPump
        return 1.2101 * water_heating_system.uniform_energy_factor - 0.6052
      end
    else # Fuel
      if water_heating_system.water_heater_type == HPXML::WaterHeaterTypeStorage
        return 0.9066 * water_heating_system.uniform_energy_factor + 0.0711
      elsif water_heating_system.water_heater_type == HPXML::WaterHeaterTypeTankless
        return water_heating_system.uniform_energy_factor
      end
    end
    fail 'Unexpected water heater.'
  end

  # TODO
  #
  # @param act_vol [TODO] TODO
  # @param height [TODO] TODO
  # @return [TODO] TODO
  def self.calc_tank_areas(act_vol, height = nil)
    if height.nil?
      height = get_tank_height()
    end
    diameter = 2.0 * (UnitConversions.convert(act_vol, 'gal', 'ft^3') / (height * Math::PI))**0.5 # feet
    a_top = Math::PI * diameter**2.0 / 4.0 # sqft
    a_side = Math::PI * diameter * height # sqft
    surface_area = 2.0 * a_top + a_side # sqft

    return surface_area, a_side
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.get_tank_height()
    return 4.0 # feet, assumption from BEopt
  end

  # TODO
  #
  # @param act_vol [TODO] TODO
  # @param water_heating_system [TODO] TODO
  # @param a_side [TODO] TODO
  # @param solar_fraction [TODO] TODO
  # @param nbeds [Integer] Number of bedrooms in the dwelling unit
  # @return [TODO] TODO
  def self.calc_indirect_ua_with_standbyloss(act_vol, water_heating_system, a_side, solar_fraction, nbeds = nil)
    standby_loss_units = water_heating_system.standby_loss_units
    standby_loss_value = water_heating_system.standby_loss_value

    if not [HPXML::UnitsDegFPerHour].include? standby_loss_units
      fail "Unexpected standby loss units '#{standby_loss_units}' for indirect water heater. Should be '#{HPXML::UnitsDegFPerHour}'."
    end

    # Test conditions
    cp = 0.999 # Btu/lb-F
    rho = 8.216 # lb/gal
    t_amb = 70.0 # F
    t_tank_avg = 135.0 # F, Test begins at 137-138F stop at 133F

    # UA calculation
    q = standby_loss_value * cp * act_vol * rho # Btu/hr
    ua = q / (t_tank_avg - t_amb) # Btu/hr-F

    # jacket
    ua = apply_tank_jacket(water_heating_system, ua, a_side)

    # shared losses
    ua = apply_shared_adjustment(water_heating_system, ua, nbeds) if !nbeds.nil?

    ua *= (1.0 - solar_fraction)
    return ua
  end

  # TODO
  #
  # @param num_beds [TODO] TODO
  # @return [TODO] TODO
  def self.get_default_num_bathrooms(num_beds)
    # From BA HSP
    num_baths = num_beds / 2.0 + 0.5
    return num_baths
  end

  # TODO
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param heater [TODO] TODO
  # @param loc_space [TODO] TODO
  # @param water_heating_system [TODO] TODO
  # @param unit_multiplier [Integer] Number of similar dwelling units
  # @param combi_boiler [TODO] TODO
  # @return [TODO] TODO
  def self.add_ec_adj(model, hpxml_bldg, heater, loc_space, water_heating_system, unit_multiplier, combi_boiler = nil)
    ec_adj = get_dist_energy_consumption_adjustment(hpxml_bldg, water_heating_system)
    adjustment = ec_adj - 1.0

    if loc_space.nil? # WH is not in a zone, set the other equipment to be in a random space
      loc_space = model.getSpaces[0]
    end

    if water_heating_system.water_heater_type == HPXML::WaterHeaterTypeHeatPump
      tank = heater.tank
    else
      tank = heater
    end
    if [HPXML::WaterHeaterTypeCombiStorage, HPXML::WaterHeaterTypeCombiTankless].include? water_heating_system.water_heater_type
      fuel_type = water_heating_system.related_hvac_system.heating_system_fuel
    else
      fuel_type = water_heating_system.fuel_type
    end

    # Add an other equipment object for water heating that will get actuated, has a small initial load but gets overwritten by EMS
    cnt = model.getOtherEquipments.select { |e| e.endUseSubcategory.start_with? Constants::ObjectTypeWaterHeaterAdjustment }.size # Ensure unique meter for each water heater
    ec_adj_object = HotWaterAndAppliances.add_other_equipment(model, "#{Constants::ObjectTypeWaterHeaterAdjustment}#{cnt + 1}", loc_space, 0.01, 0, 0, model.alwaysOnDiscreteSchedule, fuel_type)
    ec_adj_object.additionalProperties.setFeature('HPXML_ID', water_heating_system.id) # Used by reporting measure

    # EMS for calculating the EC_adj

    # Sensors
    if [HPXML::WaterHeaterTypeCombiStorage, HPXML::WaterHeaterTypeCombiTankless].include? water_heating_system.water_heater_type
      ec_adj_sensor_boiler = OpenStudio::Model::EnergyManagementSystemSensor.new(model, "Boiler #{EPlus.fuel_type(fuel_type)} Rate")
      ec_adj_sensor_boiler.setName("#{combi_boiler.name} energy")
      ec_adj_sensor_boiler.setKeyName(combi_boiler.name.to_s)
    else
      ec_adj_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, "Water Heater #{EPlus.fuel_type(fuel_type)} Rate")
      ec_adj_sensor.setName("#{tank.name} energy")
      ec_adj_sensor.setKeyName(tank.name.to_s)
      if water_heating_system.water_heater_type == HPXML::WaterHeaterTypeHeatPump
        ec_adj_hp_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, "Cooling Coil Water Heating #{EPlus::FuelTypeElectricity} Rate")
        ec_adj_hp_sensor.setName("#{heater.dXCoil.name} energy")
        ec_adj_hp_sensor.setKeyName(heater.dXCoil.name.to_s)
        ec_adj_fan_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, "Fan #{EPlus::FuelTypeElectricity} Rate")
        ec_adj_fan_sensor.setName("#{heater.fan.name} energy")
        ec_adj_fan_sensor.setKeyName(heater.fan.name.to_s)
      end
    end

    ec_adj_oncyc_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, "Water Heater On Cycle Parasitic #{EPlus::FuelTypeElectricity} Rate")
    ec_adj_oncyc_sensor.setName("#{tank.name} on cycle parasitic")
    ec_adj_oncyc_sensor.setKeyName(tank.name.to_s)
    ec_adj_offcyc_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, "Water Heater Off Cycle Parasitic #{EPlus::FuelTypeElectricity} Rate")
    ec_adj_offcyc_sensor.setName("#{tank.name} off cycle parasitic")
    ec_adj_offcyc_sensor.setKeyName(tank.name.to_s)

    # Actuators
    ec_adj_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(ec_adj_object, *EPlus::EMSActuatorOtherEquipmentPower, loc_space)
    ec_adj_actuator.setName("#{heater.name} ec_adj_act")

    # Program
    ec_adj_program = OpenStudio::Model::EnergyManagementSystemProgram.new(model)
    ec_adj_program.setName("#{heater.name} EC_adj")
    ec_adj_program.addLine('If WarmupFlag == 0') # Prevent a non-zero adjustment in the first hour because of the warmup period
    if [HPXML::WaterHeaterTypeCombiStorage, HPXML::WaterHeaterTypeCombiTankless].include? water_heating_system.water_heater_type
      ec_adj_program.addLine("Set dhw_e_cons = #{ec_adj_oncyc_sensor.name} + #{ec_adj_offcyc_sensor.name}")
      ec_adj_program.addLine("If #{ec_adj_sensor_boiler.name} > 0")
      ec_adj_program.addLine("  Set dhw_e_cons = dhw_e_cons + #{ec_adj_sensor_boiler.name}")
      ec_adj_program.addLine('EndIf')
    elsif water_heating_system.water_heater_type == HPXML::WaterHeaterTypeHeatPump
      ec_adj_program.addLine("Set dhw_e_cons = #{ec_adj_sensor.name} + #{ec_adj_oncyc_sensor.name} + #{ec_adj_offcyc_sensor.name} + #{ec_adj_hp_sensor.name} + #{ec_adj_fan_sensor.name}")
    else
      ec_adj_program.addLine("Set dhw_e_cons = #{ec_adj_sensor.name} + #{ec_adj_oncyc_sensor.name} + #{ec_adj_offcyc_sensor.name}")
    end
    # Since the water heater has been multiplied by the unit_multiplier, and this OtherEquipment object will be adding
    # load to a thermal zone with an E+ multiplier, we would double-count the multiplier if we didn't divide by it here.
    ec_adj_program.addLine("Set #{ec_adj_actuator.name} = #{adjustment} * dhw_e_cons / #{unit_multiplier}")
    ec_adj_program.addLine('EndIf')

    # Program Calling Manager
    program_calling_manager = OpenStudio::Model::EnergyManagementSystemProgramCallingManager.new(model)
    program_calling_manager.setName("#{heater.name} EC_adj ProgramManager")
    program_calling_manager.setCallingPoint('EndOfSystemTimestepBeforeHVACReporting')
    program_calling_manager.addProgram(ec_adj_program)
  end

  # TODO
  #
  # @param eri_version [String] Version of the ANSI/RESNET/ICC 301 Standard to use for equations/assumptions
  # @return [TODO] TODO
  def self.get_default_hot_water_temperature(eri_version)
    # Returns hot water temperature in F
    if Constants::ERIVersions.index(eri_version) >= Constants::ERIVersions.index('2014A')
      # 2014 w/ Addendum A or newer
      return 125.0
    else
      return 120.0
    end
  end

  # TODO
  #
  # @param water_heating_system [TODO] TODO
  # @return [TODO] TODO
  def self.get_default_performance_adjustment(water_heating_system)
    return unless water_heating_system.water_heater_type == HPXML::WaterHeaterTypeTankless
    if not water_heating_system.energy_factor.nil?
      return 0.92 # Applies EF, updated per 301-2019
    elsif not water_heating_system.uniform_energy_factor.nil?
      return 0.94 # Applies UEF, updated per 301-2019
    end
  end

  # Returns the default location of the water heater based on the IECC climate zone.
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param iecc_zone [string] IECC climate zone
  # @return [string] Water heater location (HPXML::LocationXXX)
  def self.get_default_location(hpxml_bldg, iecc_zone = nil)
    # ANSI/RESNET/ICC 301-2022C
    if ['1A', '1B', '1C', '2A', '2B', '2C', '3A', '3B', '3C'].include? iecc_zone
      location_hierarchy = [HPXML::LocationGarage,
                            HPXML::LocationConditionedSpace]
    elsif ['4A', '4B', '4C', '5A', '5B', '5C', '6A', '6B', '6C', '7', '8'].include? iecc_zone
      location_hierarchy = [HPXML::LocationBasementUnconditioned,
                            HPXML::LocationBasementConditioned,
                            HPXML::LocationConditionedSpace]
    elsif iecc_zone.nil?
      location_hierarchy = [HPXML::LocationBasementConditioned,
                            HPXML::LocationBasementUnconditioned,
                            HPXML::LocationConditionedSpace]
    end
    location_hierarchy.each do |location|
      if hpxml_bldg.has_location(location)
        return location
      end
    end
  end

  # TODO
  #
  # @param collector_area [TODO] TODO
  # @return [TODO] TODO
  def self.calc_default_solar_thermal_system_storage_volume(collector_area)
    return 1.5 * collector_area # 1.5 gal for every sqft of collector area
  end

  # TODO
  #
  # @param wh_type [TODO] TODO
  # @return [TODO] TODO
  def self.deadband(wh_type)
    if [HPXML::WaterHeaterTypeStorage, HPXML::WaterHeaterTypeCombiStorage].include? wh_type
      return 2.0 # C
    else
      return 0.0 # C
    end
  end

  # TODO
  #
  # @param vol [TODO] TODO
  # @param fuel [TODO] TODO
  # @return [TODO] TODO
  def self.calc_storage_tank_actual_vol(vol, fuel)
    # Convert the nominal tank volume to an actual volume
    if fuel.nil?
      act_vol = 0.95 * vol # indirect tank
    else
      if fuel == HPXML::FuelTypeElectricity
        act_vol = 0.9 * vol
      else
        act_vol = 0.95 * vol
      end
    end
    return act_vol
  end

  # TODO
  #
  # @param act_vol [TODO] TODO
  # @param water_heating_system [TODO] TODO
  # @param solar_fraction [TODO] TODO
  # @param nbeds [Integer] Number of bedrooms in the dwelling unit
  # @return [TODO] TODO
  def self.calc_tank_UA(act_vol, water_heating_system, solar_fraction, nbeds)
    # If using EF:
    #   Calculates the U value, UA of the tank and conversion efficiency (eta_c)
    #   based on the Energy Factor and recovery efficiency of the tank
    #   Source: Burch and Erickson 2004 - http://www.nrel.gov/docs/gen/fy04/36035.pdf
    # IF using UEF:
    #   Calculates the U value, UA of the tank and conversion efficiency (eta_c)
    #   based on the Uniform Energy Factor, First Hour Rating, and Recovery Efficiency of the tank
    #   Source: Maguire and Roberts 2020 - https://www.ashrae.org/file%20library/conferences/specialty%20conferences/2020%20building%20performance/papers/d-bsc20-c039.pdf
    if water_heating_system.water_heater_type == HPXML::WaterHeaterTypeTankless
      if not water_heating_system.energy_factor.nil?
        eta_c = water_heating_system.energy_factor * water_heating_system.performance_adjustment
      elsif not water_heating_system.uniform_energy_factor.nil?
        eta_c = water_heating_system.uniform_energy_factor * water_heating_system.performance_adjustment
      end
      ua = 0.0
      surface_area = 1.0
    else
      density = 8.2938 # lb/gal
      cp = 1.0007 # Btu/lb-F
      t_in = 58.0 # F
      t_env = 67.5 # F

      if not water_heating_system.energy_factor.nil?
        t = 135.0 # F
        volume_drawn = 64.3 # gal/day
      elsif not water_heating_system.uniform_energy_factor.nil?
        t = 125.0 # F
        if water_heating_system.usage_bin == HPXML::WaterHeaterUsageBinVerySmall
          volume_drawn = 10.0 # gal
        elsif water_heating_system.usage_bin == HPXML::WaterHeaterUsageBinLow
          volume_drawn = 38.0 # gal
        elsif water_heating_system.usage_bin == HPXML::WaterHeaterUsageBinMedium
          volume_drawn = 55.0 # gal
        elsif water_heating_system.usage_bin == HPXML::WaterHeaterUsageBinHigh
          volume_drawn = 84.0 # gal
        end
      end

      draw_mass = volume_drawn * density # lb
      q_load = draw_mass * cp * (t - t_in) # Btu/day
      pow = water_heating_system.heating_capacity # Btu/h
      surface_area, a_side = calc_tank_areas(act_vol)
      if water_heating_system.fuel_type != HPXML::FuelTypeElectricity
        if not water_heating_system.energy_factor.nil?
          ua = (water_heating_system.recovery_efficiency / water_heating_system.energy_factor - 1.0) / ((t - t_env) * (24.0 / q_load - 1.0 / (pow * water_heating_system.energy_factor))) # Btu/hr-F
          eta_c = (water_heating_system.recovery_efficiency + ua * (t - t_env) / pow) # conversion efficiency is supposed to be calculated with initial tank ua
        elsif not water_heating_system.uniform_energy_factor.nil?
          ua = ((water_heating_system.recovery_efficiency / water_heating_system.uniform_energy_factor) - 1.0) / ((t - t_env) * (24.0 / q_load) - ((t - t_env) / (pow * water_heating_system.uniform_energy_factor))) # Btu/hr-F
          eta_c = water_heating_system.recovery_efficiency + ((ua * (t - t_env)) / pow) # conversion efficiency is slightly larger than recovery efficiency
        end
      else # is Electric
        if not water_heating_system.energy_factor.nil?
          ua = q_load * (1.0 / water_heating_system.energy_factor - 1.0) / ((t - t_env) * 24.0)
        elsif not water_heating_system.uniform_energy_factor.nil?
          ua = q_load * (1.0 / water_heating_system.uniform_energy_factor - 1.0) / ((24.0 * (t - t_env)) * (0.8 + 0.2 * ((t_in - t_env) / (t - t_env))))
        end
        eta_c = 1.0
      end
      ua = apply_tank_jacket(water_heating_system, ua, a_side)
    end
    ua *= (1.0 - solar_fraction)
    ua = apply_shared_adjustment(water_heating_system, ua, nbeds) # shared losses
    u = ua / surface_area # Btu/hr-ft^2-F
    if eta_c > 1.0
      fail 'A water heater heat source (either burner or element) efficiency of > 1 has been calculated, double check water heater inputs.'
    end
    if ua < 0.0
      fail 'A negative water heater standby loss coefficient (UA) was calculated, double check water heater inputs.'
    end

    return u, ua, eta_c
  end

  # TODO
  #
  # @param water_heating_system [TODO] TODO
  # @param ua_pre [TODO] TODO
  # @param a_side [TODO] TODO
  # @return [TODO] TODO
  def self.apply_tank_jacket(water_heating_system, ua_pre, a_side)
    if not water_heating_system.jacket_r_value.nil?
      skin_insulation_R = 5.0 # R5
      if water_heating_system.fuel_type.nil? # indirect water heater, etc. Assume 2 inch skin insulation
        skin_insulation_t = 2.0 # inch
      elsif water_heating_system.fuel_type != HPXML::FuelTypeElectricity
        ef = water_heating_system.energy_factor
        if ef.nil?
          ef = calc_ef_from_uef(water_heating_system)
        end
        if ef < 0.7
          skin_insulation_t = 1.0 # inch
        else
          skin_insulation_t = 2.0 # inch
        end
      else # electric
        skin_insulation_t = 2.0 # inch
      end
      # water heater wrap calculation based on:
      # Modeling Water Heat Wraps in BEopt DRAFT Technical Note
      # Authors:  Ben Polly and Jay Burch (NREL)
      u_pre_skin = 1.0 / (skin_insulation_t * skin_insulation_R + 1.0 / 1.3 + 1.0 / 52.8) # Btu/hr-ft^2-F = (1 / hout + kins / tins + t / hin)^-1
      ua = ua_pre - water_heating_system.jacket_r_value / (1.0 / u_pre_skin + water_heating_system.jacket_r_value) * u_pre_skin * a_side
    else
      ua = ua_pre
    end
    return ua
  end

  # TODO
  #
  # @param water_heating_system [TODO] TODO
  # @param ua [TODO] TODO
  # @param nbeds [Integer] Number of bedrooms in the dwelling unit
  # @return [TODO] TODO
  def self.apply_shared_adjustment(water_heating_system, ua, nbeds)
    if water_heating_system.is_shared_system
      # Apportion shared water heater energy use due to tank losses to the dwelling unit
      ua = ua * [nbeds.to_f, 1.0].max / water_heating_system.number_of_bedrooms_served.to_f
    end
    return ua
  end

  # TODO
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @return [TODO] TODO
  def self.create_new_pump(model)
    # Add a pump to the new DHW loop
    pump = OpenStudio::Model::PumpVariableSpeed.new(model)
    pump.setRatedFlowRate(0.01)
    pump.setFractionofMotorInefficienciestoFluidStream(0)
    pump.setMotorEfficiency(1)
    pump.setRatedPowerConsumption(0)
    pump.setRatedPumpHead(1)
    pump.setCoefficient1ofthePartLoadPerformanceCurve(0)
    pump.setCoefficient2ofthePartLoadPerformanceCurve(1)
    pump.setCoefficient3ofthePartLoadPerformanceCurve(0)
    pump.setCoefficient4ofthePartLoadPerformanceCurve(0)
    pump.setPumpControlType('Intermittent')
    return pump
  end

  # TODO
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param t_set_c [TODO] TODO
  # @return [TODO] TODO
  def self.create_new_schedule_manager(model, t_set_c)
    new_schedule = OpenStudio::Model::ScheduleConstant.new(model)
    new_schedule.setName('dhw temp')
    new_schedule.setValue(t_set_c)
    OpenStudio::Model::SetpointManagerScheduled.new(model, new_schedule)
  end

  # TODO
  #
  # @param name [TODO] TODO
  # @param act_vol [TODO] TODO
  # @param loc_space [TODO] TODO
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param ua [TODO] TODO
  # @param water_heating_system [TODO] TODO
  # @param t_set_c [TODO] TODO
  # @param loc_schedule [TODO] TODO
  # @param u [TODO] TODO
  # @param eta_c [TODO] TODO
  # @param is_dsh_storage [TODO] TODO
  # @param is_combi [TODO] TODO
  # @param schedules_file [SchedulesFile] SchedulesFile wrapper class instance of detailed schedule files
  # @param unavailable_periods [HPXML::UnavailablePeriods] Object that defines periods for, e.g., power outages or vacancies
  # @param unit_multiplier [Integer] Number of similar dwelling units
  # @return [TODO] TODO
  def self.create_new_heater(name:, water_heating_system: nil, act_vol:, t_set_c: nil, loc_space:, loc_schedule: nil, model:, runner:, u: nil, ua:, eta_c: nil, is_dsh_storage: false, is_combi: false, schedules_file: nil, unavailable_periods: [], unit_multiplier: 1.0)
    # storage tank doesn't require water_heating_system class argument being passed
    if is_dsh_storage || is_combi
      fuel = nil
      cap = 0.0
      if is_dsh_storage
        tank_type = HPXML::WaterHeaterTypeStorage
      else
        tank_type = water_heating_system.water_heater_type
      end
    else
      fuel = water_heating_system.fuel_type
      tank_type = water_heating_system.water_heater_type
      cap = water_heating_system.heating_capacity / 1000.0
      tank_model_type = water_heating_system.tank_model_type
    end

    ua *= unit_multiplier
    cap *= unit_multiplier
    act_vol *= unit_multiplier

    if tank_model_type == HPXML::WaterHeaterTankModelTypeStratified
      h_tank = get_tank_height() # ft

      # Add a WaterHeater:Stratified to the model
      new_heater = OpenStudio::Model::WaterHeaterStratified.new(model)
      new_heater.setEndUseSubcategory('Domestic Hot Water')
      new_heater.setTankVolume(UnitConversions.convert(act_vol, 'gal', 'm^3'))
      new_heater.setTankHeight(UnitConversions.convert(h_tank, 'ft', 'm'))
      new_heater.setMaximumTemperatureLimit(90)
      new_heater.setHeaterPriorityControl('MasterSlave')
      configure_stratified_tank_setpoint_schedules(new_heater, schedules_file, t_set_c, model, runner, unavailable_periods)
      new_heater.setHeater1Capacity(UnitConversions.convert(cap, 'kBtu/hr', 'W'))
      new_heater.setHeater1Height(UnitConversions.convert(h_tank * 0.733333333, 'ft', 'm')) # node 4; height of upper element based on TRNSYS assumptions for an ERWH
      new_heater.setHeater1DeadbandTemperatureDifference(5.556)
      new_heater.setHeater2Capacity(UnitConversions.convert(cap, 'kBtu/hr', 'W'))
      new_heater.setHeater2Height(UnitConversions.convert(h_tank * 0.733333333, 'ft', 'm')) # node 13; height of upper element based on TRNSYS assumptions for an ERWH
      new_heater.setHeater2DeadbandTemperatureDifference(5.556)
      new_heater.setHeaterThermalEfficiency(1.0)
      new_heater.setNumberofNodes(12)
      new_heater.setAdditionalDestratificationConductivity(0)
      new_heater.setUseSideDesignFlowRate(UnitConversions.convert(act_vol, 'gal', 'm^3') / 60.1)
      new_heater.setSourceSideDesignFlowRate(0)
      new_heater.setSourceSideFlowControlMode('')
      new_heater.setSourceSideInletHeight(0)
      new_heater.setSourceSideOutletHeight(0)
      new_heater.setSkinLossFractiontoZone(1.0 / unit_multiplier) # Tank losses are multiplied by E+ zone multiplier, so need to compensate here
      new_heater.setOffCycleFlueLossFractiontoZone(1.0 / unit_multiplier)
      set_stratified_tank_ua(new_heater, u, unit_multiplier)
    else
      new_heater = OpenStudio::Model::WaterHeaterMixed.new(model)
      new_heater.setTankVolume(UnitConversions.convert(act_vol, 'gal', 'm^3'))
      new_heater.setHeaterThermalEfficiency(eta_c) unless eta_c.nil?
      configure_mixed_tank_setpoint_schedule(new_heater, schedules_file, t_set_c, model, runner, unavailable_periods)
      new_heater.setMaximumTemperatureLimit(99.0)
      if [HPXML::WaterHeaterTypeTankless, HPXML::WaterHeaterTypeCombiTankless].include? tank_type
        new_heater.setHeaterControlType('Modulate')
      else
        new_heater.setHeaterControlType('Cycle')
      end
      new_heater.setDeadbandTemperatureDifference(deadband(tank_type))

      # Capacity, storage tank to be 0
      new_heater.setHeaterMaximumCapacity(UnitConversions.convert(cap, 'kBtu/hr', 'W'))
      new_heater.setHeaterMinimumCapacity(0.0)

      # Set fraction of heat loss from tank to ambient (vs out flue)
      # Based on lab testing done by LBNL
      skinlossfrac = 1.0
      if (not is_dsh_storage) && (water_heating_system.fuel_type != HPXML::FuelTypeElectricity) && (water_heating_system.water_heater_type == HPXML::WaterHeaterTypeStorage)
        # Fuel storage water heater
        # EF cutoffs derived from Figure 2 of http://title24stakeholders.com/wp-content/uploads/2017/10/2013_CASE-Report_High-efficiency-Water-Heater-Ready.pdf
        # FUTURE: Add an optional HPXML input for water heater type for a user to specify this (and default based on EF as below)
        ef = water_heating_system.energy_factor
        if ef.nil?
          ef = calc_ef_from_uef(water_heating_system)
        end
        if ef < 0.64
          skinlossfrac = 0.64 # Natural draft
        elsif ef < 0.77
          skinlossfrac = 0.91 # Power vent
        else
          skinlossfrac = 0.96 # Condensing
        end
      end
      new_heater.setOffCycleLossFractiontoThermalZone(skinlossfrac / unit_multiplier) # Tank losses are multiplied by E+ zone multiplier, so need to compensate here
      new_heater.setOnCycleLossFractiontoThermalZone(1.0 / unit_multiplier) # Tank losses are multiplied by E+ zone multiplier, so need to compensate here

      ua_w_k = UnitConversions.convert(ua, 'Btu/(hr*F)', 'W/K')
      new_heater.setOnCycleLossCoefficienttoAmbientTemperature(ua_w_k)
      new_heater.setOffCycleLossCoefficienttoAmbientTemperature(ua_w_k)
    end

    if not water_heating_system.nil?
      new_heater.additionalProperties.setFeature('HPXML_ID', water_heating_system.id) # Used by reporting measure
    end
    if is_combi
      new_heater.additionalProperties.setFeature('IsCombiBoiler', true) # Used by reporting measure
    end

    new_heater.setName(name)
    new_heater.setHeaterFuelType(EPlus.fuel_type(fuel)) unless fuel.nil?
    set_wh_ambient(loc_space, loc_schedule, new_heater)

    # FUTURE: These are always zero right now; develop smart defaults.
    new_heater.setOffCycleParasiticFuelType(EPlus::FuelTypeElectricity)
    new_heater.setOffCycleParasiticFuelConsumptionRate(0.0)
    new_heater.setOffCycleParasiticHeatFractiontoTank(0)
    new_heater.setOnCycleParasiticFuelType(EPlus::FuelTypeElectricity)
    new_heater.setOnCycleParasiticFuelConsumptionRate(0.0)
    new_heater.setOnCycleParasiticHeatFractiontoTank(0)

    return new_heater
  end

  # TODO
  #
  # @param loc_space [TODO] TODO
  # @param loc_schedule [TODO] TODO
  # @param wh_obj [TODO] TODO
  # @return [TODO] TODO
  def self.set_wh_ambient(loc_space, loc_schedule, wh_obj)
    if wh_obj.ambientTemperatureSchedule.is_initialized
      wh_obj.ambientTemperatureSchedule.get.remove
    end
    if not loc_schedule.nil? # Temperature schedule indicator
      wh_obj.setAmbientTemperatureSchedule(loc_schedule)
    elsif not loc_space.nil?
      wh_obj.setAmbientTemperatureIndicator('ThermalZone')
      wh_obj.setAmbientTemperatureThermalZone(loc_space.thermalZone.get)
    else # Located outside
      wh_obj.setAmbientTemperatureIndicator('Outdoors')
    end
  end

  # TODO
  #
  # @param new_heater [TODO] TODO
  # @param schedules_file [SchedulesFile] SchedulesFile wrapper class instance of detailed schedule files
  # @param t_set_c [TODO] TODO
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param unavailable_periods [HPXML::UnavailablePeriods] Object that defines periods for, e.g., power outages or vacancies
  # @return [TODO] TODO
  def self.configure_mixed_tank_setpoint_schedule(new_heater, schedules_file, t_set_c, model, runner, unavailable_periods)
    new_schedule = nil
    if not schedules_file.nil?
      new_schedule = schedules_file.create_schedule_file(model, col_name: SchedulesFile::Columns[:WaterHeaterSetpoint].name)
    end
    if new_schedule.nil? # constant
      new_schedule = ScheduleConstant.new(model, Constants::ObjectTypeWaterHeaterSetpoint, t_set_c, EPlus::ScheduleTypeLimitsTemperature, unavailable_periods: unavailable_periods)
      new_schedule = new_schedule.schedule
    else
      runner.registerWarning("Both '#{SchedulesFile::Columns[:WaterHeaterSetpoint].name}' schedule file and setpoint temperature provided; the latter will be ignored.") if !t_set_c.nil?
    end
    if new_heater.setpointTemperatureSchedule.is_initialized
      new_heater.setpointTemperatureSchedule.get.remove
    end
    new_heater.setSetpointTemperatureSchedule(new_schedule)
  end

  # TODO
  #
  # @param new_heater [TODO] TODO
  # @param schedules_file [SchedulesFile] SchedulesFile wrapper class instance of detailed schedule files
  # @param t_set_c [TODO] TODO
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param unavailable_periods [HPXML::UnavailablePeriods] Object that defines periods for, e.g., power outages or vacancies
  # @return [TODO] TODO
  def self.configure_stratified_tank_setpoint_schedules(new_heater, schedules_file, t_set_c, model, runner, unavailable_periods)
    new_schedule = nil
    if not schedules_file.nil?
      new_schedule = schedules_file.create_schedule_file(model, col_name: SchedulesFile::Columns[:WaterHeaterSetpoint].name)
    end
    if new_schedule.nil? # constant
      new_schedule = ScheduleConstant.new(model, Constants::ObjectTypeWaterHeaterSetpoint, t_set_c, EPlus::ScheduleTypeLimitsTemperature, unavailable_periods: unavailable_periods)
      new_schedule = new_schedule.schedule
    else
      runner.registerWarning("Both '#{SchedulesFile::Columns[:WaterHeaterSetpoint].name}' schedule file and setpoint temperature provided; the latter will be ignored.") if !t_set_c.nil?
    end
    new_heater.heater1SetpointTemperatureSchedule.remove
    new_heater.heater2SetpointTemperatureSchedule.remove
    new_heater.setHeater1SetpointTemperatureSchedule(new_schedule)
    new_heater.setHeater2SetpointTemperatureSchedule(new_schedule)
  end

  # TODO
  #
  # @param t_set [TODO] TODO
  # @param wh_type [TODO] TODO
  # @return [TODO] TODO
  def self.get_t_set_c(t_set, wh_type)
    return if t_set.nil?

    return UnitConversions.convert(t_set, 'F', 'C') + deadband(wh_type) / 2.0 # Half the deadband to account for E+ deadband
  end

  # TODO
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param t_set_c [TODO] TODO
  # @param eri_version [String] Version of the ANSI/RESNET/ICC 301 Standard to use for equations/assumptions
  # @param unit_multiplier [Integer] Number of similar dwelling units
  # @return [TODO] TODO
  def self.create_new_loop(model, t_set_c, eri_version, unit_multiplier)
    # Create a new plant loop for the water heater
    name = 'dhw loop'

    if t_set_c.nil?
      t_set_c = UnitConversions.convert(get_default_hot_water_temperature(eri_version), 'F', 'C')
    end

    loop = OpenStudio::Model::PlantLoop.new(model)
    loop.setName(name)
    loop.sizingPlant.setDesignLoopExitTemperature(t_set_c)
    loop.sizingPlant.setLoopDesignTemperatureDifference(UnitConversions.convert(10.0, 'deltaF', 'deltaC'))
    loop.setPlantLoopVolume(0.003 * unit_multiplier) # ~1 gal
    loop.setMaximumLoopFlowRate(0.01 * unit_multiplier) # This size represents the physical limitations to flow due to losses in the piping system. We assume that the pipes are always adequately sized.

    bypass_pipe = OpenStudio::Model::PipeAdiabatic.new(model)
    out_pipe = OpenStudio::Model::PipeAdiabatic.new(model)

    loop.addSupplyBranchForComponent(bypass_pipe)
    out_pipe.addToNode(loop.supplyOutletNode)

    new_pump = create_new_pump(model)
    new_pump.addToNode(loop.supplyInletNode)

    new_manager = create_new_schedule_manager(model, t_set_c)
    new_manager.addToNode(loop.supplyOutletNode)

    return loop
  end

  # TODO
  #
  # @param water_heating_system [TODO] TODO
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @return [TODO] TODO
  def self.get_water_heater_solar_fraction(water_heating_system, hpxml_bldg)
    return 0.0 if hpxml_bldg.solar_thermal_systems.size == 0

    solar_thermal_system = hpxml_bldg.solar_thermal_systems[0]

    if (solar_thermal_system.water_heating_system.nil? || (solar_thermal_system.water_heating_system.id == water_heating_system.id))
      solar_fraction = solar_thermal_system.solar_fraction
    end
    return solar_fraction.to_f
  end

  # TODO
  #
  # @param fhr [TODO] TODO
  # @return [TODO] TODO
  def self.get_usage_bin_from_first_hour_rating(fhr)
    if fhr < 18.0
      return HPXML::WaterHeaterUsageBinVerySmall
    elsif fhr < 51.0
      return HPXML::WaterHeaterUsageBinLow
    elsif fhr < 75.0
      return HPXML::WaterHeaterUsageBinMedium
    else
      return HPXML::WaterHeaterUsageBinHigh
    end
  end
end
