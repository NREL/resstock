# frozen_string_literal: true

class Airflow
  def self.apply(model, runner, weather, spaces, air_infils, vent_fans,
                 duct_systems, infil_volume, infil_height, open_window_area,
                 nv_clg_ssn_sensor, min_neighbor_distance, vented_attic, vented_crawl,
                 site_type, shelter_coef, has_flue_chimney, hvac_map, eri_version,
                 apply_ashrae140_assumptions)

    # Global variables

    @runner = runner
    @spaces = spaces
    @building_height = Geometry.get_max_z_of_spaces(model.getSpaces)
    @infil_volume = infil_volume
    @infil_height = infil_height
    @living_space = spaces[HPXML::LocationLivingSpace]
    @living_zone = @living_space.thermalZone.get
    @eri_version = eri_version
    @apply_ashrae140_assumptions = apply_ashrae140_assumptions
    @cfa = UnitConversions.convert(@living_space.floorArea, 'm^2', 'ft^2')

    # Global sensors

    @pbar_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Site Outdoor Air Barometric Pressure')
    @pbar_sensor.setName('out pb s')

    @wout_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Site Outdoor Air Humidity Ratio')
    @wout_sensor.setName('out wt s')

    @win_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Zone Air Humidity Ratio')
    @win_sensor.setName("#{Constants.ObjectNameAirflow} win s")
    @win_sensor.setKeyName(@living_zone.name.to_s)

    @vwind_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Site Wind Speed')
    @vwind_sensor.setName('site vw s')

    @tin_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Zone Mean Air Temperature')
    @tin_sensor.setName("#{Constants.ObjectNameAirflow} tin s")
    @tin_sensor.setKeyName(@living_zone.name.to_s)

    @tout_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Zone Outdoor Air Drybulb Temperature')
    @tout_sensor.setName("#{Constants.ObjectNameAirflow} tt s")
    @tout_sensor.setKeyName(@living_zone.name.to_s)

    # Adiabatic construction for duct plenum

    adiabatic_mat = OpenStudio::Model::MasslessOpaqueMaterial.new(model, 'Rough', 176.1)
    adiabatic_mat.setName('Adiabatic')
    @adiabatic_const = OpenStudio::Model::Construction.new(model)
    @adiabatic_const.setName('AdiabaticConst')
    @adiabatic_const.insertLayer(0, adiabatic_mat)

    # Ventilation fans
    vent_fans_mech = []
    vent_fans_kitchen = []
    vent_fans_bath = []
    vent_fans_whf = []
    vent_fans.each do |vent_fan|
      if vent_fan.used_for_whole_building_ventilation
        vent_fans_mech << vent_fan
      elsif vent_fan.used_for_seasonal_cooling_load_reduction
        vent_fans_whf << vent_fan
      elsif vent_fan.used_for_local_ventilation && vent_fan.fan_location == HPXML::LocationKitchen
        vent_fans_kitchen << vent_fan
      elsif vent_fan.used_for_local_ventilation && vent_fan.fan_location == HPXML::LocationBath
        vent_fans_bath << vent_fan
      else
        @runner.registerWarning("Unexpected ventilation fan '#{vent_fan.id}'. The fan will not be modeled.")
      end
    end

    # Initialization
    initialize_cfis(model, vent_fans_mech, hvac_map)
    model.getAirLoopHVACs.each do |air_loop|
      initialize_air_loop_objects(model, air_loop)
    end

    # Apply ducts

    duct_systems.each do |ducts, air_loop|
      apply_ducts(model, ducts, air_loop)
    end

    # Apply infiltration/ventilation

    @wind_speed = set_wind_speed_correction(model, site_type, shelter_coef, min_neighbor_distance)
    apply_natural_ventilation_and_whole_house_fan(model, weather, vent_fans_whf, open_window_area, nv_clg_ssn_sensor)
    apply_infiltration_and_ventilation_fans(model, weather, vent_fans_mech, vent_fans_kitchen, vent_fans_bath, has_flue_chimney, air_infils, vented_attic, vented_crawl)
  end

  def self.get_default_shelter_coefficient()
    return 0.5 # Table 4.2.2(1)(g)
  end

  def self.get_default_fraction_of_windows_operable()
    # Combining the value below with the assumption that 50% of
    # the area of an operable window can be open produces the
    # Building America assumption that "Thirty-three percent of
    # the window area ... can be opened for natural ventilation"
    return 0.67 # 67%
  end

  def self.get_default_vented_attic_sla()
    return 1.0 / 300.0 # Table 4.2.2(1) - Attics
  end

  def self.get_default_vented_crawl_sla()
    return 1.0 / 150.0 # Table 4.2.2(1) - Crawlspaces
  end

  def self.get_default_mech_vent_fan_power(fan_type)
    # 301-2019: Table 4.2.2(1b)
    # Returns fan power in W/cfm
    if (fan_type == HPXML::MechVentTypeSupply) || (fan_type == HPXML::MechVentTypeExhaust)
      return 0.35
    elsif fan_type == HPXML::MechVentTypeBalanced
      return 0.70
    elsif (fan_type == HPXML::MechVentTypeERV) || (fan_type == HPXML::MechVentTypeHRV)
      return 1.00
    elsif fan_type == HPXML::MechVentTypeCFIS
      return 0.50
    else
      fail "Unexpected fan_type: '#{fan_type}'."
    end
  end

  private

  def self.set_wind_speed_correction(model, site_type, shelter_coef, min_neighbor_distance)
    site_map = { HPXML::SiteTypeRural => 'Country',    # Flat, open country
                 HPXML::SiteTypeSuburban => 'Suburbs', # Rough, wooded country, suburbs
                 HPXML::SiteTypeUrban => 'City' }      # Towns, city outskirts, center of large cities
    model.getSite.setTerrain(site_map[site_type])

    wind_speed = WindSpeed.new
    wind_speed.height = 32.8 # ft (Standard weather station height)

    # Open, Unrestricted at Weather Station
    wind_speed.terrain_multiplier = 1.0
    wind_speed.terrain_exponent = 0.15
    wind_speed.ashrae_terrain_thickness = 270
    wind_speed.ashrae_terrain_exponent = 0.14

    if site_type == HPXML::SiteTypeRural
      wind_speed.site_terrain_multiplier = 0.85
      wind_speed.site_terrain_exponent = 0.20
      wind_speed.ashrae_site_terrain_thickness = 270 # Flat, open country
      wind_speed.ashrae_site_terrain_exponent = 0.14 # Flat, open country
    elsif site_type == HPXML::SiteTypeSuburban
      wind_speed.site_terrain_multiplier = 0.67
      wind_speed.site_terrain_exponent = 0.25
      wind_speed.ashrae_site_terrain_thickness = 370 # Rough, wooded country, suburbs
      wind_speed.ashrae_site_terrain_exponent = 0.22 # Rough, wooded country, suburbs
    elsif site_type == HPXML::SiteTypeUrban
      wind_speed.site_terrain_multiplier = 0.47
      wind_speed.site_terrain_exponent = 0.35
      wind_speed.ashrae_site_terrain_thickness = 460 # Towns, city outskirts, center of large cities
      wind_speed.ashrae_site_terrain_exponent = 0.33 # Towns, city outskirts, center of large cities
    end

    # Local Shielding
    if shelter_coef.nil?
      # FIXME: Move into HPXML defaults
      if min_neighbor_distance.nil?
        # Typical shelter for isolated rural house
        wind_speed.S_wo = 0.90
      elsif min_neighbor_distance > @building_height
        # Typical shelter caused by other building across the street
        wind_speed.S_wo = 0.70
      else
        # Typical shelter for urban buildings where sheltering obstacles
        # are less than one building height away.
        wind_speed.S_wo = 0.50
      end
    else
      wind_speed.S_wo = Float(shelter_coef)
    end

    # S-G Shielding Coefficients are roughly 1/3 of AIM2 Shelter Coefficients
    wind_speed.shielding_coef = wind_speed.S_wo / 3.0

    return wind_speed
  end

  def self.apply_infiltration_to_unconditioned_space(model, space, ach = nil, ela = nil, c_w_SG = nil, c_s_SG = nil)
    if ach.to_f > 0
      # Model ACH as constant infiltration/ventilation
      # This is typically used for below-grade spaces where wind is zero
      flow_rate = OpenStudio::Model::SpaceInfiltrationDesignFlowRate.new(model)
      flow_rate.setName("#{Constants.ObjectNameInfiltration}|#{space.name}")
      flow_rate.setSchedule(model.alwaysOnDiscreteSchedule)
      flow_rate.setAirChangesperHour(ach)
      flow_rate.setSpace(space)
      flow_rate.setConstantTermCoefficient(1)
      flow_rate.setTemperatureTermCoefficient(0)
      flow_rate.setVelocityTermCoefficient(0)
      flow_rate.setVelocitySquaredTermCoefficient(0)
    elsif ela.to_f > 0
      # Model ELA with stack/wind coefficients
      leakage_area = OpenStudio::Model::SpaceInfiltrationEffectiveLeakageArea.new(model)
      leakage_area.setName("#{Constants.ObjectNameInfiltration}|#{space.name}")
      leakage_area.setSchedule(model.alwaysOnDiscreteSchedule)
      leakage_area.setEffectiveAirLeakageArea(UnitConversions.convert(ela, 'ft^2', 'cm^2'))
      leakage_area.setStackCoefficient(UnitConversions.convert(c_s_SG, 'ft^2/(s^2*R)', 'L^2/(s^2*cm^4*K)'))
      leakage_area.setWindCoefficient(c_w_SG * 0.01)
      leakage_area.setSpace(space)
    end
  end

  def self.apply_natural_ventilation_and_whole_house_fan(model, weather, vent_fans_whf, open_window_area, nv_clg_ssn_sensor)
    if @living_zone.thermostatSetpointDualSetpoint.is_initialized
      thermostat = @living_zone.thermostatSetpointDualSetpoint.get
      htg_sch = thermostat.heatingSetpointTemperatureSchedule.get
      clg_sch = thermostat.coolingSetpointTemperatureSchedule.get
    end

    # NV Availability Schedule
    nv_num_days_per_week = 7 # FUTURE: Expose via HPXML?
    nv_avail_sch = create_nv_and_whf_avail_sch(model, Constants.ObjectNameNaturalVentilation, nv_num_days_per_week)

    nv_avail_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Schedule Value')
    nv_avail_sensor.setName("#{Constants.ObjectNameNaturalVentilation} avail s")
    nv_avail_sensor.setKeyName(nv_avail_sch.name.to_s)

    # Availability Schedules paired with vent fan class
    # If whf_num_days_per_week is exposed, can handle multiple fans with different days of operation
    whf_avail_sensors = {}
    vent_fans_whf.each_with_index do |vent_whf, index|
      whf_num_days_per_week = 7 # FUTURE: Expose via HPXML?
      obj_name = "#{Constants.ObjectNameWholeHouseFan} #{index}"
      whf_avail_sch = create_nv_and_whf_avail_sch(model, obj_name, whf_num_days_per_week)

      whf_avail_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Schedule Value')
      whf_avail_sensor.setName("#{obj_name} avail s")
      whf_avail_sensor.setKeyName(whf_avail_sch.name.to_s)
      whf_avail_sensors[vent_whf.id] = whf_avail_sensor
    end

    # Sensors
    if not htg_sch.nil?
      htg_sp_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Schedule Value')
      htg_sp_sensor.setName('htg sp s')
      htg_sp_sensor.setKeyName(htg_sch.name.to_s)
    end

    if not clg_sch.nil?
      clg_sp_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Schedule Value')
      clg_sp_sensor.setName('clg sp s')
      clg_sp_sensor.setKeyName(clg_sch.name.to_s)
    end

    # Actuators
    nv_flow = OpenStudio::Model::SpaceInfiltrationDesignFlowRate.new(model)
    nv_flow.setName(Constants.ObjectNameNaturalVentilation + ' flow')
    nv_flow.setSchedule(model.alwaysOnDiscreteSchedule)
    nv_flow.setSpace(@living_space)
    nv_flow_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(nv_flow, 'Zone Infiltration', 'Air Exchange Flow Rate')
    nv_flow_actuator.setName("#{nv_flow.name} act")

    whf_flow = OpenStudio::Model::SpaceInfiltrationDesignFlowRate.new(model)
    whf_flow.setName(Constants.ObjectNameWholeHouseFan + ' flow')
    whf_flow.setSchedule(model.alwaysOnDiscreteSchedule)
    whf_flow.setSpace(@living_space)
    whf_flow_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(whf_flow, 'Zone Infiltration', 'Air Exchange Flow Rate')
    whf_flow_actuator.setName("#{whf_flow.name} act")

    # Electric Equipment (for whole house fan electricity consumption)
    whf_equip_def = OpenStudio::Model::ElectricEquipmentDefinition.new(model)
    whf_equip_def.setName(Constants.ObjectNameWholeHouseFan)
    whf_equip = OpenStudio::Model::ElectricEquipment.new(whf_equip_def)
    whf_equip.setName(Constants.ObjectNameWholeHouseFan)
    whf_equip.setSpace(@living_space)
    whf_equip_def.setFractionRadiant(0)
    whf_equip_def.setFractionLatent(0)
    whf_equip_def.setFractionLost(1)
    whf_equip.setSchedule(model.alwaysOnDiscreteSchedule)
    whf_equip.setEndUseSubcategory(Constants.ObjectNameWholeHouseFan)
    whf_elec_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(whf_equip, 'ElectricEquipment', 'Electric Power Level')
    whf_elec_actuator.setName("#{whf_equip.name} act")

    # Assume located in attic floor if attic zone exists; otherwise assume it's through roof/wall.
    whf_zone = nil
    if not @spaces[HPXML::LocationAtticVented].nil?
      whf_zone = @spaces[HPXML::LocationAtticVented].thermalZone.get
    elsif not @spaces[HPXML::LocationAtticUnvented].nil?
      whf_zone = @spaces[HPXML::LocationAtticUnvented].thermalZone.get
    end
    if not whf_zone.nil?
      # Air from living to WHF zone (attic)
      zone_mixing = OpenStudio::Model::ZoneMixing.new(whf_zone)
      zone_mixing.setName("#{Constants.ObjectNameWholeHouseFan} mix")
      zone_mixing.setSourceZone(@living_zone)
      liv_to_zone_flow_rate_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(zone_mixing, 'ZoneMixing', 'Air Exchange Flow Rate')
      liv_to_zone_flow_rate_actuator.setName("#{zone_mixing.name} act")
    end

    area = 0.6 * open_window_area # ft^2, for Sherman-Grimsrud
    max_rate = 20.0 # Air Changes per hour
    max_flow_rate = max_rate * @infil_volume / UnitConversions.convert(1.0, 'hr', 'min')
    neutral_level = 0.5
    hor_lk_frac = 0.0
    c_w, c_s = calc_wind_stack_coeffs(hor_lk_frac, neutral_level, @living_space, @infil_height)
    max_oa_hr = 0.0115 # From BA HSP
    max_oa_rh = 0.7 # From BA HSP

    # Program
    vent_program = OpenStudio::Model::EnergyManagementSystemProgram.new(model)
    vent_program.setName(Constants.ObjectNameNaturalVentilation + ' program')
    vent_program.addLine("Set Tin = #{@tin_sensor.name}")
    vent_program.addLine("Set Tout = #{@tout_sensor.name}")
    vent_program.addLine("Set Wout = #{@wout_sensor.name}")
    vent_program.addLine("Set Pbar = #{@pbar_sensor.name}")
    vent_program.addLine('Set Phiout = (@RhFnTdbWPb Tout Wout Pbar)')
    vent_program.addLine("Set MaxHR = #{max_oa_hr}")
    vent_program.addLine("Set MaxRH = #{max_oa_rh}")
    if (not htg_sp_sensor.nil?) && (not clg_sp_sensor.nil?)
      vent_program.addLine("Set Tnvsp = (#{htg_sp_sensor.name} + #{clg_sp_sensor.name}) / 2") # Average of heating/cooling setpoints to minimize incurring additional heating energy
    else
      vent_program.addLine("Set Tnvsp = #{UnitConversions.convert(73.0, 'F', 'C')}") # Assumption when no HVAC system
    end
    vent_program.addLine("Set NVavail = #{nv_avail_sensor.name}")
    vent_program.addLine("Set ClgSsnAvail = #{nv_clg_ssn_sensor.name}")
    vent_program.addLine('If (Wout < MaxHR) && (Phiout < MaxRH) && (Tin > Tout) && (Tin > Tnvsp) && (ClgSsnAvail > 0)')
    vent_program.addLine('  Set WHF_Flow = 0')
    vent_fans_whf.each do |vent_whf|
      vent_program.addLine("  Set WHF_Flow = WHF_Flow + #{UnitConversions.convert(vent_whf.rated_flow_rate, 'cfm', 'm^3/s')} * #{whf_avail_sensors[vent_whf.id].name}")
    end
    vent_program.addLine('  Set Adj = (Tin-Tnvsp)/(Tin-Tout)')
    vent_program.addLine('  Set Adj = (@Min Adj 1)')
    vent_program.addLine('  Set Adj = (@Max Adj 0)')
    vent_program.addLine('  If (WHF_Flow > 0)') # If available, prioritize whole house fan
    vent_program.addLine("    Set #{nv_flow_actuator.name} = 0")
    vent_program.addLine("    Set #{whf_flow_actuator.name} = WHF_Flow*Adj")
    vent_program.addLine("    Set #{liv_to_zone_flow_rate_actuator.name} = WHF_Flow*Adj") unless whf_zone.nil?
    vent_program.addLine('    Set WHF_W = 0')
    vent_fans_whf.each do |vent_whf|
      vent_program.addLine("    Set WHF_W = WHF_W + #{vent_whf.fan_power} * #{whf_avail_sensors[vent_whf.id].name}")
    end
    vent_program.addLine("    Set #{whf_elec_actuator.name} = WHF_W*Adj")
    vent_program.addLine('  ElseIf (NVavail > 0)') # Natural ventilation
    vent_program.addLine("    Set NVArea = #{UnitConversions.convert(area, 'ft^2', 'cm^2')}")
    vent_program.addLine("    Set Cs = #{UnitConversions.convert(c_s, 'ft^2/(s^2*R)', 'L^2/(s^2*cm^4*K)')}")
    vent_program.addLine("    Set Cw = #{c_w * 0.01}")
    vent_program.addLine('    Set Tdiff = Tin-Tout')
    vent_program.addLine('    Set dT = (@Abs Tdiff)')
    vent_program.addLine("    Set Vwind = #{@vwind_sensor.name}")
    vent_program.addLine('    Set SGNV = NVArea*Adj*((((Cs*dT)+(Cw*(Vwind^2)))^0.5)/1000)')
    vent_program.addLine("    Set MaxNV = #{UnitConversions.convert(max_flow_rate, 'cfm', 'm^3/s')}")
    vent_program.addLine("    Set #{nv_flow_actuator.name} = (@Min SGNV MaxNV)")
    vent_program.addLine("    Set #{whf_flow_actuator.name} = 0")
    vent_program.addLine("    Set #{liv_to_zone_flow_rate_actuator.name} = 0") unless whf_zone.nil?
    vent_program.addLine("    Set #{whf_elec_actuator.name} = 0")
    vent_program.addLine('  EndIf')
    vent_program.addLine('Else')
    vent_program.addLine("  Set #{nv_flow_actuator.name} = 0")
    vent_program.addLine("  Set #{whf_flow_actuator.name} = 0")
    vent_program.addLine("  Set #{liv_to_zone_flow_rate_actuator.name} = 0") unless whf_zone.nil?
    vent_program.addLine("  Set #{whf_elec_actuator.name} = 0")
    vent_program.addLine('EndIf')

    manager = OpenStudio::Model::EnergyManagementSystemProgramCallingManager.new(model)
    manager.setName("#{vent_program.name} calling manager")
    manager.setCallingPoint('BeginTimestepBeforePredictor')
    manager.addProgram(vent_program)
  end

  def self.create_nv_and_whf_avail_sch(model, obj_name, num_days_per_week)
    avail_sch = OpenStudio::Model::ScheduleRuleset.new(model)
    avail_sch.setName("#{obj_name} avail schedule")
    Schedule.set_schedule_type_limits(model, avail_sch, Constants.ScheduleTypeLimitsOnOff)
    on_rule = OpenStudio::Model::ScheduleRule.new(avail_sch)
    on_rule.setName("#{obj_name} avail schedule rule")
    on_rule_day = on_rule.daySchedule
    on_rule_day.setName("#{obj_name} avail schedule day")
    on_rule_day.addValue(OpenStudio::Time.new(0, 24, 0, 0), 1)
    method_array = ['setApplyMonday', 'setApplyWednesday', 'setApplyFriday', 'setApplySaturday', 'setApplyTuesday', 'setApplyThursday', 'setApplySunday']
    for i in 1..7 do
      if num_days_per_week >= i
        on_rule.public_send(method_array[i - 1], true)
      end
    end
    on_rule.setStartDate(OpenStudio::Date::fromDayOfYear(1))
    on_rule.setEndDate(OpenStudio::Date::fromDayOfYear(365))
    return avail_sch
  end

  def self.create_return_air_duct_zone(model, air_loop_name)
    # Create the return air plenum zone, space
    ra_duct_zone = OpenStudio::Model::ThermalZone.new(model)
    ra_duct_zone.setName(air_loop_name + ' ret air zone')
    ra_duct_zone.setVolume(1.0)

    ra_duct_polygon = OpenStudio::Point3dVector.new
    ra_duct_polygon << OpenStudio::Point3d.new(0, 0, 0)
    ra_duct_polygon << OpenStudio::Point3d.new(0, 1.0, 0)
    ra_duct_polygon << OpenStudio::Point3d.new(1.0, 1.0, 0)
    ra_duct_polygon << OpenStudio::Point3d.new(1.0, 0, 0)

    ra_space = OpenStudio::Model::Space::fromFloorPrint(ra_duct_polygon, 1, model)
    ra_space = ra_space.get
    ra_space.setName(air_loop_name + ' ret air space')
    ra_space.setThermalZone(ra_duct_zone)

    ra_space.surfaces.each do |surface|
      surface.setConstruction(@adiabatic_const)
      surface.setOutsideBoundaryCondition('Adiabatic')
      surface.setSunExposure('NoSun')
      surface.setWindExposure('NoWind')
      surface_property_convection_coefficients = OpenStudio::Model::SurfacePropertyConvectionCoefficients.new(surface)
      surface_property_convection_coefficients.setConvectionCoefficient1Location('Inside')
      surface_property_convection_coefficients.setConvectionCoefficient1Type('Value')
      surface_property_convection_coefficients.setConvectionCoefficient1(30)
    end

    return ra_duct_zone
  end

  def self.create_sens_lat_load_actuator_and_equipment(model, name, space, frac_lat, frac_lost)
    other_equip_def = OpenStudio::Model::OtherEquipmentDefinition.new(model)
    other_equip_def.setName("#{name} equip")
    other_equip = OpenStudio::Model::OtherEquipment.new(other_equip_def)
    other_equip.setName(other_equip_def.name.to_s)
    other_equip.setFuelType('None')
    other_equip.setSchedule(model.alwaysOnDiscreteSchedule)
    other_equip.setSpace(space)
    other_equip_def.setFractionLost(frac_lost)
    other_equip_def.setFractionLatent(frac_lat)
    other_equip_def.setFractionRadiant(0.0)
    actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(other_equip, 'OtherEquipment', 'Power Level')
    actuator.setName("#{other_equip.name} act")
    return actuator
  end

  def self.initialize_cfis(model, vent_fans_mech, hvac_map)
    # Get AirLoop associated with CFIS
    @cfis_airloop = {}
    @cfis_t_sum_open_var = {}
    @cfis_f_damper_extra_open_var = {}
    return if vent_fans_mech.empty?

    index = 0

    vent_fans_mech.each do |vent_mech|
      next unless (vent_mech.fan_type == HPXML::MechVentTypeCFIS)

      cfis_sys_ids = vent_mech.distribution_system.hvac_systems.map { |system| system.id }
      # Get AirLoopHVACs associated with these HVAC systems
      hvac_map.each do |sys_id, hvacs|
        next unless cfis_sys_ids.include? sys_id

        hvacs.each do |loop|
          next unless loop.is_a? OpenStudio::Model::AirLoopHVAC
          next if (not @cfis_airloop[vent_mech.id].nil?) && (@cfis_airloop[vent_mech.id] == loop) # already assigned

          fail 'Two airloops found for CFIS.' unless @cfis_airloop[vent_mech.id].nil?

          @cfis_airloop[vent_mech.id] = loop
        end
      end

      @cfis_t_sum_open_var[vent_mech.id] = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "#{Constants.ObjectNameMechanicalVentilation.gsub(' ', '_')}_cfis_t_sum_open_#{index}") # Sums the time during an hour the CFIS damper has been open
      @cfis_f_damper_extra_open_var[vent_mech.id] = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "#{Constants.ObjectNameMechanicalVentilation.gsub(' ', '_')}_cfis_f_extra_damper_open_#{index}") # Fraction of timestep the CFIS blower is running while hvac is not operating. Used by infiltration and duct leakage programs

      # CFIS Initialization Program
      cfis_program = OpenStudio::Model::EnergyManagementSystemProgram.new(model)
      cfis_program.setName(Constants.ObjectNameMechanicalVentilation + " cfis init program #{index}")
      cfis_program.addLine("Set #{@cfis_t_sum_open_var[vent_mech.id].name} = 0")
      cfis_program.addLine("Set #{@cfis_f_damper_extra_open_var[vent_mech.id].name} = 0")

      manager = OpenStudio::Model::EnergyManagementSystemProgramCallingManager.new(model)
      manager.setName("#{cfis_program.name} calling manager")
      manager.setCallingPoint('BeginNewEnvironment')
      manager.addProgram(cfis_program)

      manager = OpenStudio::Model::EnergyManagementSystemProgramCallingManager.new(model)
      manager.setName("#{cfis_program.name} calling manager2")
      manager.setCallingPoint('AfterNewEnvironmentWarmUpIsComplete')
      manager.addProgram(cfis_program)

      index += 1
    end
  end

  def self.initialize_air_loop_objects(model, air_loop)
    @supply_fans = {} if @supply_fans.nil?
    @fan_rtf_var = {} if @fan_rtf_var.nil?
    @fan_mfr_max_var = {} if @fan_mfr_max_var.nil?
    @fan_rtf_sensor = {} if @fan_rtf_sensor.nil?
    @fan_mfr_sensor = {} if @fan_mfr_sensor.nil?

    # Get the supply fan
    system = HVAC.get_unitary_system_from_air_loop_hvac(air_loop)
    if system.nil? # Evaporative cooler supply fan directly on air loop
      @supply_fans[air_loop] = air_loop.supplyFan.get
    else
      @supply_fans[air_loop] = system.supplyFan.get
    end

    @fan_rtf_var[air_loop] = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "#{air_loop.name} Fan RTF".gsub(' ', '_'))

    # Supply fan maximum mass flow rate
    @fan_mfr_max_var[air_loop] = OpenStudio::Model::EnergyManagementSystemInternalVariable.new(model, 'Fan Maximum Mass Flow Rate')
    @fan_mfr_max_var[air_loop].setName("#{air_loop.name} max sup fan mfr")
    @fan_mfr_max_var[air_loop].setInternalDataIndexKeyName(@supply_fans[air_loop].name.to_s)

    if @supply_fans[air_loop].to_FanOnOff.is_initialized
      @fan_rtf_sensor[air_loop] = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Fan Runtime Fraction')
      @fan_rtf_sensor[air_loop].setName("#{@fan_rtf_var[air_loop].name} s")
      @fan_rtf_sensor[air_loop].setKeyName(@supply_fans[air_loop].name.to_s)
    elsif @supply_fans[air_loop].to_FanVariableVolume.is_initialized # Evaporative cooler
      @fan_mfr_sensor[air_loop] = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Fan Air Mass Flow Rate')
      @fan_mfr_sensor[air_loop].setName("#{@supply_fans[air_loop].name} air MFR")
      @fan_mfr_sensor[air_loop].setKeyName("#{@supply_fans[air_loop].name}")
      @fan_rtf_sensor[air_loop] = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "#{@fan_rtf_var[air_loop].name}_s")
    else
      fail "Unexpected fan: #{@supply_fans[air_loop].name}"
    end
  end

  def self.apply_ducts(model, ducts, air_loop)
    ducts.each do |duct|
      if duct.leakage_frac.nil? == duct.leakage_cfm25.nil?
        fail 'Ducts: Must provide either leakage fraction or cfm25, but not both.'
      end
      if (not duct.leakage_frac.nil?) && ((duct.leakage_frac < 0) || (duct.leakage_frac > 1))
        fail 'Ducts: Leakage Fraction must be greater than or equal to 0 and less than or equal to 1.'
      end
      if (not duct.leakage_cfm25.nil?) && (duct.leakage_cfm25 < 0)
        fail 'Ducts: Leakage CFM25 must be greater than or equal to 0.'
      end
      if duct.rvalue < 0
        fail 'Ducts: Insulation Nominal R-Value must be greater than or equal to 0.'
      end
      if duct.area < 0
        fail 'Ducts: Surface Area must be greater than or equal to 0.'
      end
    end

    ducts.each do |duct|
      duct.rvalue = get_duct_insulation_rvalue(duct.rvalue, duct.side) # Convert from nominal to actual R-value
      if not duct.loc_schedule.nil?
        # Pass MF space temperature schedule name
        duct.location = duct.loc_schedule.name.to_s
      elsif not duct.loc_space.nil?
        duct.location = duct.loc_space.name.to_s
        duct.zone = duct.loc_space.thermalZone.get
      else # Outside/RoofDeck
        duct.location = HPXML::LocationOutside
        duct.zone = nil
      end
    end

    if ducts.size > 0
      # Store info for HVAC Sizing measure
      air_loop.additionalProperties.setFeature(Constants.SizingInfoDuctExist, true)
      air_loop.additionalProperties.setFeature(Constants.SizingInfoDuctSides, ducts.map { |duct| duct.side }.join(','))
      air_loop.additionalProperties.setFeature(Constants.SizingInfoDuctLocations, ducts.map { |duct| duct.location.to_s }.join(','))
      air_loop.additionalProperties.setFeature(Constants.SizingInfoDuctLeakageFracs, ducts.map { |duct| duct.leakage_frac.to_f }.join(','))
      air_loop.additionalProperties.setFeature(Constants.SizingInfoDuctLeakageCFM25s, ducts.map { |duct| duct.leakage_cfm25.to_f }.join(','))
      air_loop.additionalProperties.setFeature(Constants.SizingInfoDuctAreas, ducts.map { |duct| duct.area.to_f }.join(','))
      air_loop.additionalProperties.setFeature(Constants.SizingInfoDuctRvalues, ducts.map { |duct| duct.rvalue.to_f }.join(','))
    end

    return if ducts.size == 0 # No ducts

    # get duct located zone or ambient temperature schedule objects
    duct_locations = ducts.map { |duct| if duct.zone.nil? then duct.loc_schedule else duct.zone end }.uniq

    # All duct zones are in living space?
    all_ducts_conditioned = true
    duct_locations.each do |duct_zone|
      if duct_locations.is_a? OpenStudio::Model::ThermalZone
        next if Geometry.is_living(duct_zone)
      end

      all_ducts_conditioned = false
    end
    return if all_ducts_conditioned

    # Set the return plenum
    ra_duct_zone = create_return_air_duct_zone(model, air_loop.name.to_s)
    ra_duct_space = ra_duct_zone.spaces[0]
    @living_zone.setReturnPlenum(ra_duct_zone, air_loop)

    # -- Sensors --

    # Air handler mass flow rate
    ah_mfr_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "#{air_loop.name} AH MFR".gsub(' ', '_'))
    ah_mfr_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'System Node Mass Flow Rate')
    ah_mfr_sensor.setName("#{ah_mfr_var.name} s")
    ah_mfr_sensor.setKeyName(air_loop.demandInletNode.name.to_s)

    # Air handler volume flow rate
    ah_vfr_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "#{air_loop.name} AH VFR".gsub(' ', '_'))
    ah_vfr_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'System Node Current Density Volume Flow Rate')
    ah_vfr_sensor.setName("#{ah_vfr_var.name} s")
    ah_vfr_sensor.setKeyName(air_loop.demandInletNode.name.to_s)

    # Air handler outlet temperature
    ah_tout_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "#{air_loop.name} AH Tout".gsub(' ', '_'))
    ah_tout_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'System Node Temperature')
    ah_tout_sensor.setName("#{ah_tout_var.name} s")
    ah_tout_sensor.setKeyName(air_loop.demandInletNode.name.to_s)

    # Air handler outlet humidity ratio
    ah_wout_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "#{air_loop.name} AH Wout".gsub(' ', '_'))
    ah_wout_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'System Node Humidity Ratio')
    ah_wout_sensor.setName("#{ah_wout_var.name} s")
    ah_wout_sensor.setKeyName(air_loop.demandInletNode.name.to_s)

    living_zone_return_air_node = nil
    @living_zone.returnAirModelObjects.each do |return_air_model_obj|
      next if return_air_model_obj.to_Node.get.airLoopHVAC.get != air_loop

      living_zone_return_air_node = return_air_model_obj
    end

    # Return air temperature
    ra_t_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "#{air_loop.name} RA T".gsub(' ', '_'))
    if not living_zone_return_air_node.nil?
      ra_t_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'System Node Temperature')
      ra_t_sensor.setName("#{ra_t_var.name} s")
      ra_t_sensor.setKeyName(living_zone_return_air_node.name.to_s)
    else
      ra_t_sensor = @tin_sensor
    end

    # Return air humidity ratio
    ra_w_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "#{air_loop.name} Ra W".gsub(' ', '_'))
    if not living_zone_return_air_node.nil?
      ra_w_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'System Node Humidity Ratio')
      ra_w_sensor.setName("#{ra_w_var.name} s")
      ra_w_sensor.setKeyName(living_zone_return_air_node.name.to_s)
    else
      ra_w_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Zone Mean Air Humidity Ratio')
      ra_w_sensor.setName("#{ra_w_var.name} s")
      ra_w_sensor.setKeyName(@living_zone.name.to_s)
    end

    # Create one duct program for each duct location zone
    duct_locations.each_with_index do |duct_location, i|
      next if (not duct_location.nil?) && (duct_location.name.to_s == @living_zone.name.to_s)

      air_loop_name_idx = "#{air_loop.name}_#{i}"

      # -- Sensors --

      # Duct zone temperature
      dz_t_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "#{air_loop_name_idx} DZ T".gsub(' ', '_'))
      if duct_location.is_a? OpenStudio::Model::ThermalZone
        dz_t_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Zone Air Temperature')
        dz_t_sensor.setKeyName(duct_location.name.to_s)
      elsif duct_location.is_a? OpenStudio::Model::ScheduleConstant
        dz_t_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Schedule Value')
        dz_t_sensor.setKeyName(duct_location.name.to_s)
      elsif duct_location.nil? # Outside
        dz_t_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Site Outdoor Air Drybulb Temperature')
        dz_t_sensor.setKeyName('Environment')
      else # shouldn't get here, should only have schedule/thermal zone/nil assigned
        fail 'Unexpected duct zone type passed'
      end
      dz_t_sensor.setName("#{dz_t_var.name} s")

      # Duct zone humidity ratio
      dz_w_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "#{air_loop_name_idx} DZ W".gsub(' ', '_'))
      if duct_location.is_a? OpenStudio::Model::ThermalZone
        dz_w_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Zone Mean Air Humidity Ratio')
        dz_w_sensor.setKeyName(duct_location.name.to_s)
        dz_w_sensor.setName("#{dz_w_var.name} s")
        dz_w = "#{dz_w_sensor.name}"
      elsif duct_location.is_a? OpenStudio::Model::ScheduleConstant # Outside or scheduled temperature
        if duct_location.name.to_s == HPXML::LocationOtherNonFreezingSpace
          dz_w_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Site Outdoor Air Humidity Ratio')
          dz_w_sensor.setName("#{dz_w_var.name} s")
          dz_w = "#{dz_w_sensor.name}"
        elsif duct_location.name.to_s == HPXML::LocationOtherHousingUnit
          dz_w_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Zone Mean Air Humidity Ratio')
          dz_w_sensor.setKeyName(@living_zone.name.to_s)
          dz_w_sensor.setName("#{dz_w_var.name} s")
          dz_w = "#{dz_w_sensor.name}"
        else
          dz_w_sensor1 = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Site Outdoor Air Humidity Ratio')
          dz_w_sensor1.setName("#{dz_w_var.name} s 1")
          dz_w_sensor2 = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Zone Mean Air Humidity Ratio')
          dz_w_sensor2.setName("#{dz_w_var.name} s 2")
          dz_w_sensor2.setKeyName(@living_zone.name.to_s)
          dz_w = "(#{dz_w_sensor1.name} + #{dz_w_sensor2.name}) / 2"
        end
      else
        dz_w_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Site Outdoor Air Humidity Ratio')
        dz_w_sensor.setName("#{dz_w_var.name} s")
        dz_w = "#{dz_w_sensor.name}"
      end

      # -- Actuators --

      # List of: [Var name, object name, space, frac load latent, frac load outside]
      equip_act_infos = []

      if duct_location.is_a? OpenStudio::Model::ScheduleConstant
        space_values = Geometry.get_temperature_scheduled_space_values(duct_location.name.to_s)
        f_regain = space_values[:f_regain]
      else
        f_regain = 0.0
      end

      # Other equipment objects to cancel out the supply air leakage directly into the return plenum
      equip_act_infos << ['supply_sens_lk_to_liv', 'SupSensLkToLv', @living_space, 0.0, f_regain]
      equip_act_infos << ['supply_lat_lk_to_liv', 'SupLatLkToLv', @living_space, 1.0 - f_regain, f_regain]

      # Supply duct conduction load added to the living space
      equip_act_infos << ['supply_cond_to_liv', 'SupCondToLv', @living_space, 0.0, f_regain]

      # Return duct conduction load added to the return plenum zone
      equip_act_infos << ['return_cond_to_rp', 'RetCondToRP', ra_duct_space, 0.0, f_regain]

      # Return duct sensible leakage impact on the return plenum
      equip_act_infos << ['return_sens_lk_to_rp', 'RetSensLkToRP', ra_duct_space, 0.0, f_regain]

      # Return duct latent leakage impact on the return plenum
      equip_act_infos << ['return_lat_lk_to_rp', 'RetLatLkToRP', ra_duct_space, 1.0 - f_regain, f_regain]

      # Supply duct conduction impact on the duct zone
      if not duct_location.is_a? OpenStudio::Model::ThermalZone # Outside or scheduled temperature
        equip_act_infos << ['supply_cond_to_dz', 'SupCondToDZ', @living_space, 0.0, 1.0] # Arbitrary space, all heat lost
      else
        equip_act_infos << ['supply_cond_to_dz', 'SupCondToDZ', duct_location.spaces[0], 0.0, 0.0]
      end

      # Return duct conduction impact on the duct zone
      if not duct_location.is_a? OpenStudio::Model::ThermalZone # Outside or scheduled temperature
        equip_act_infos << ['return_cond_to_dz', 'RetCondToDZ', @living_space, 0.0, 1.0] # Arbitrary space, all heat lost
      else
        equip_act_infos << ['return_cond_to_dz', 'RetCondToDZ', duct_location.spaces[0], 0.0, 0.0]
      end

      # Supply duct sensible leakage impact on the duct zone
      if not duct_location.is_a? OpenStudio::Model::ThermalZone # Outside or scheduled temperature
        equip_act_infos << ['supply_sens_lk_to_dz', 'SupSensLkToDZ', @living_space, 0.0, 1.0] # Arbitrary space, all heat lost
      else
        equip_act_infos << ['supply_sens_lk_to_dz', 'SupSensLkToDZ', duct_location.spaces[0], 0.0, 0.0]
      end

      # Supply duct latent leakage impact on the duct zone
      if not duct_location.is_a? OpenStudio::Model::ThermalZone # Outside or scheduled temperature
        equip_act_infos << ['supply_lat_lk_to_dz', 'SupLatLkToDZ', @living_space, 0.0, 1.0] # Arbitrary space, all heat lost
      else
        equip_act_infos << ['supply_lat_lk_to_dz', 'SupLatLkToDZ', duct_location.spaces[0], 1.0, 0.0]
      end

      duct_vars = {}
      duct_actuators = {}
      [false, true].each do |is_cfis|
        if is_cfis
          next unless @cfis_airloop.values.include? air_loop

          prefix = 'cfis_'
        else
          prefix = ''
        end
        equip_act_infos.each do |act_info|
          var_name = "#{prefix}#{act_info[0]}"
          object_name = "#{air_loop_name_idx} #{prefix}#{act_info[1]}".gsub(' ', '_')
          space = act_info[2]
          if is_cfis && (space == ra_duct_space)
            # Move all CFIS return duct losses to the conditioned space so as to avoid extreme plenum temperatures
            # due to mismatch between return plenum duct loads and airloop airflow rate (which does not actually
            # increase due to the presence of CFIS).
            space = @living_space
          end
          frac_lat = act_info[3]
          frac_lost = act_info[4]
          if not is_cfis
            duct_vars[var_name] = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, object_name)
          end
          duct_actuators[var_name] = create_sens_lat_load_actuator_and_equipment(model, object_name, space, frac_lat, frac_lost)
        end
      end

      # Two objects are required to model the air exchange between the duct zone and the living space since
      # ZoneMixing objects can not account for direction of air flow (both are controlled by EMS)

      # List of: [Var name, object name, space, frac load latent, frac load outside]
      mix_act_infos = []

      if duct_location.is_a? OpenStudio::Model::ThermalZone
        # Accounts for leaks from the duct zone to the living zone
        mix_act_infos << ['dz_to_liv_flow_rate', 'ZoneMixDZToLv', @living_zone, duct_location]
        # Accounts for leaks from the living zone to the duct zone
        mix_act_infos << ['liv_to_dz_flow_rate', 'ZoneMixLvToDZ', duct_location, @living_zone]
      end

      [false, true].each do |is_cfis|
        if is_cfis
          next unless @cfis_airloop.values.include? air_loop

          prefix = 'cfis_'
        else
          prefix = ''
        end
        mix_act_infos.each do |act_info|
          var_name = "#{prefix}#{act_info[0]}"
          object_name = "#{air_loop_name_idx} #{prefix}#{act_info[1]}".gsub(' ', '_')
          dest_zone = act_info[2]
          source_zone = act_info[3]

          if not is_cfis
            duct_vars[var_name] = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, object_name)
          end
          zone_mixing = OpenStudio::Model::ZoneMixing.new(dest_zone)
          zone_mixing.setName("#{object_name} mix")
          zone_mixing.setSourceZone(source_zone)
          duct_actuators[var_name] = OpenStudio::Model::EnergyManagementSystemActuator.new(zone_mixing, 'ZoneMixing', 'Air Exchange Flow Rate')
          duct_actuators[var_name].setName("#{zone_mixing.name} act")
        end
      end

      # -- Global Variables --

      # Obtain aggregate values for all ducts in the current duct location
      leakage_fracs = { HPXML::DuctTypeSupply => nil, HPXML::DuctTypeReturn => nil }
      leakage_cfm25s = { HPXML::DuctTypeSupply => nil, HPXML::DuctTypeReturn => nil }
      ua_values = { HPXML::DuctTypeSupply => 0, HPXML::DuctTypeReturn => 0 }
      ducts.each do |duct|
        next unless (duct_location.nil? && duct.zone.nil?) ||
                    (!duct_location.nil? && !duct.zone.nil? && (duct.zone.name.to_s == duct_location.name.to_s)) ||
                    (!duct_location.nil? && !duct.loc_schedule.nil? && (duct.loc_schedule.name.to_s == duct_location.name.to_s))

        if not duct.leakage_frac.nil?
          leakage_fracs[duct.side] = 0 if leakage_fracs[duct.side].nil?
          leakage_fracs[duct.side] += duct.leakage_frac
        elsif not duct.leakage_cfm25.nil?
          leakage_cfm25s[duct.side] = 0 if leakage_cfm25s[duct.side].nil?
          leakage_cfm25s[duct.side] += duct.leakage_cfm25
        end
        ua_values[duct.side] += duct.area / duct.rvalue
      end

      # Calculate fraction of outside air specific to this duct location
      f_oa = 1.0
      if duct_location.is_a? OpenStudio::Model::ThermalZone # in a space
        if (not @spaces[HPXML::LocationBasementUnconditioned].nil?) && (@spaces[HPXML::LocationBasementUnconditioned].thermalZone.get.name.to_s == duct_location.name.to_s)
          f_oa = 0.0
        elsif (not @spaces[HPXML::LocationCrawlspaceUnvented].nil?) && (@spaces[HPXML::LocationCrawlspaceUnvented].thermalZone.get.name.to_s == duct_location.name.to_s)
          f_oa = 0.0
        elsif (not @spaces[HPXML::LocationAtticUnvented].nil?) && (@spaces[HPXML::LocationAtticUnvented].thermalZone.get.name.to_s == duct_location.name.to_s)
          f_oa = 0.0
        end
      end

      # Duct Subroutine

      duct_subroutine = OpenStudio::Model::EnergyManagementSystemSubroutine.new(model)
      duct_subroutine.setName("#{air_loop_name_idx} duct subroutine")
      duct_subroutine.addLine("Set AH_MFR = #{ah_mfr_var.name}")
      duct_subroutine.addLine('If AH_MFR>0')
      duct_subroutine.addLine("  Set AH_Tout = #{ah_tout_var.name}")
      duct_subroutine.addLine("  Set AH_Wout = #{ah_wout_var.name}")
      duct_subroutine.addLine("  Set RA_T = #{ra_t_var.name}")
      duct_subroutine.addLine("  Set RA_W = #{ra_w_var.name}")
      duct_subroutine.addLine("  Set Fan_RTF = #{@fan_rtf_var[air_loop].name}")
      duct_subroutine.addLine("  Set DZ_T = #{dz_t_var.name}")
      duct_subroutine.addLine("  Set DZ_W = #{dz_w_var.name}")
      duct_subroutine.addLine("  Set AH_VFR = #{ah_vfr_var.name}")
      duct_subroutine.addLine('  Set h_SA = (@HFnTdbW AH_Tout AH_Wout)') # J/kg
      duct_subroutine.addLine('  Set h_RA = (@HFnTdbW RA_T RA_W)') # J/kg
      duct_subroutine.addLine('  Set h_fg = (@HfgAirFnWTdb AH_Wout AH_Tout)') # J/kg
      duct_subroutine.addLine('  Set h_DZ = (@HFnTdbW DZ_T DZ_W)') # J/kg
      duct_subroutine.addLine('  Set air_cp = 1006.0') # J/kg-C

      if not leakage_fracs[HPXML::DuctTypeSupply].nil?
        duct_subroutine.addLine("  Set f_sup = #{leakage_fracs[HPXML::DuctTypeSupply]}") # frac
      elsif not leakage_cfm25s[HPXML::DuctTypeSupply].nil?
        duct_subroutine.addLine("  Set f_sup = #{UnitConversions.convert(leakage_cfm25s[HPXML::DuctTypeSupply], 'cfm', 'm^3/s').round(6)} / (#{@fan_mfr_max_var[air_loop].name} * 1.0135)") # frac
      else
        duct_subroutine.addLine('  Set f_sup = 0.0') # frac
      end
      if not leakage_fracs[HPXML::DuctTypeReturn].nil?
        duct_subroutine.addLine("  Set f_ret = #{leakage_fracs[HPXML::DuctTypeReturn]}") # frac
      elsif not leakage_cfm25s[HPXML::DuctTypeReturn].nil?
        duct_subroutine.addLine("  Set f_ret = #{UnitConversions.convert(leakage_cfm25s[HPXML::DuctTypeReturn], 'cfm', 'm^3/s').round(6)} / (#{@fan_mfr_max_var[air_loop].name} * 1.0135)") # frac
      else
        duct_subroutine.addLine('  Set f_ret = 0.0') # frac
      end
      duct_subroutine.addLine('  Set sup_lk_mfr = f_sup * AH_MFR') # kg/s
      duct_subroutine.addLine('  Set ret_lk_mfr = f_ret * AH_MFR') # kg/s

      # Supply leakage to living
      duct_subroutine.addLine('  Set SupTotLkToLiv = sup_lk_mfr*(h_RA - h_SA)') # W
      duct_subroutine.addLine('  Set SupLatLkToLv = sup_lk_mfr*h_fg*(RA_W-AH_Wout)') # W
      duct_subroutine.addLine('  Set SupSensLkToLv = SupTotLkToLiv-SupLatLkToLv') # W

      # Supply conduction
      duct_subroutine.addLine("  Set supply_ua = #{UnitConversions.convert(ua_values[HPXML::DuctTypeSupply], 'Btu/(hr*F)', 'W/K').round(3)}")
      duct_subroutine.addLine('  Set eTm = 0-((Fan_RTF/(AH_MFR*air_cp))*supply_ua)')
      duct_subroutine.addLine('  Set t_sup = DZ_T+((AH_Tout-DZ_T)*(@Exp eTm))') # deg-C
      duct_subroutine.addLine('  Set SupCondToLv = AH_MFR*air_cp*(t_sup-AH_Tout)') # W
      duct_subroutine.addLine('  Set SupCondToDZ = 0-SupCondToLv') # W

      # Return conduction
      duct_subroutine.addLine("  Set return_ua = #{UnitConversions.convert(ua_values[HPXML::DuctTypeReturn], 'Btu/(hr*F)', 'W/K').round(3)}")
      duct_subroutine.addLine('  Set eTm = 0-((Fan_RTF/(AH_MFR*air_cp))*return_ua)')
      duct_subroutine.addLine('  Set t_ret = DZ_T+((RA_T-DZ_T)*(@Exp eTm))') # deg-C
      duct_subroutine.addLine('  Set RetCondToRP = AH_MFR*air_cp*(t_ret-RA_T)') # W
      duct_subroutine.addLine('  Set RetCondToDZ = 0-RetCondToRP') # W

      # Return leakage to return plenum
      duct_subroutine.addLine('  Set RetLatLkToRP = 0') # W
      duct_subroutine.addLine('  Set RetSensLkToRP = ret_lk_mfr*air_cp*(DZ_T-RA_T)') # W

      # Supply leakage to duct zone
      # The below terms are not the same as SupLatLkToLv and SupSensLkToLv.
      # To understand why, suppose the AHzone temperature equals the supply air temperature. In this case, the terms below
      # should be zero while SupLatLkToLv and SupSensLkToLv should still be non-zero.
      duct_subroutine.addLine('  Set SupTotLkToDZ = sup_lk_mfr*(h_SA-h_DZ)') # W
      duct_subroutine.addLine('  Set SupLatLkToDZ = sup_lk_mfr*h_fg*(AH_Wout-DZ_W)') # W
      duct_subroutine.addLine('  Set SupSensLkToDZ = SupTotLkToDZ-SupLatLkToDZ') # W

      duct_subroutine.addLine('  Set f_imbalance = f_sup-f_ret') # frac
      duct_subroutine.addLine("  Set oa_vfr = #{f_oa} * f_imbalance * AH_VFR") # m3/s
      duct_subroutine.addLine('  Set sup_lk_vfr = f_sup * AH_VFR') # m3/s
      duct_subroutine.addLine('  Set ret_lk_vfr = f_ret * AH_VFR') # m3/s
      duct_subroutine.addLine('  If f_sup > f_ret') # Living zone is depressurized relative to duct zone
      duct_subroutine.addLine('    Set ZoneMixLvToDZ = 0') # m3/s
      duct_subroutine.addLine('    Set ZoneMixDZToLv = (sup_lk_vfr-ret_lk_vfr)-oa_vfr') # m3/s
      duct_subroutine.addLine('  Else') # Living zone is pressurized relative to duct zone
      duct_subroutine.addLine('    Set ZoneMixLvToDZ = (ret_lk_vfr-sup_lk_vfr)+oa_vfr') # m3/s
      duct_subroutine.addLine('    Set ZoneMixDZToLv = 0') # m3/s
      duct_subroutine.addLine('  EndIf')
      duct_subroutine.addLine('Else') # No air handler flow rate
      duct_subroutine.addLine('  Set SupLatLkToLv = 0')
      duct_subroutine.addLine('  Set SupSensLkToLv = 0')
      duct_subroutine.addLine('  Set SupCondToLv = 0')
      duct_subroutine.addLine('  Set RetCondToRP = 0')
      duct_subroutine.addLine('  Set RetLatLkToRP = 0')
      duct_subroutine.addLine('  Set RetSensLkToRP = 0')
      duct_subroutine.addLine('  Set RetCondToDZ = 0')
      duct_subroutine.addLine('  Set SupCondToDZ = 0')
      duct_subroutine.addLine('  Set SupLatLkToDZ = 0')
      duct_subroutine.addLine('  Set SupSensLkToDZ = 0')
      duct_subroutine.addLine('  Set ZoneMixLvToDZ = 0') # m3/s
      duct_subroutine.addLine('  Set ZoneMixDZToLv = 0') # m3/s
      duct_subroutine.addLine('EndIf')
      duct_subroutine.addLine("Set #{duct_vars['supply_lat_lk_to_liv'].name} = SupLatLkToLv")
      duct_subroutine.addLine("Set #{duct_vars['supply_sens_lk_to_liv'].name} = SupSensLkToLv")
      duct_subroutine.addLine("Set #{duct_vars['supply_cond_to_liv'].name} = SupCondToLv")
      duct_subroutine.addLine("Set #{duct_vars['return_cond_to_rp'].name} = RetCondToRP")
      duct_subroutine.addLine("Set #{duct_vars['return_lat_lk_to_rp'].name} = RetLatLkToRP")
      duct_subroutine.addLine("Set #{duct_vars['return_sens_lk_to_rp'].name} = RetSensLkToRP")
      duct_subroutine.addLine("Set #{duct_vars['return_cond_to_dz'].name} = RetCondToDZ")
      duct_subroutine.addLine("Set #{duct_vars['supply_cond_to_dz'].name} = SupCondToDZ")
      duct_subroutine.addLine("Set #{duct_vars['supply_lat_lk_to_dz'].name} = SupLatLkToDZ")
      duct_subroutine.addLine("Set #{duct_vars['supply_sens_lk_to_dz'].name} = SupSensLkToDZ")
      if not duct_actuators['liv_to_dz_flow_rate'].nil?
        duct_subroutine.addLine("Set #{duct_vars['liv_to_dz_flow_rate'].name} = ZoneMixLvToDZ")
      end
      if not duct_actuators['dz_to_liv_flow_rate'].nil?
        duct_subroutine.addLine("Set #{duct_vars['dz_to_liv_flow_rate'].name} = ZoneMixDZToLv")
      end

      # Duct Program

      duct_program = OpenStudio::Model::EnergyManagementSystemProgram.new(model)
      duct_program.setName(air_loop_name_idx + ' duct program')
      duct_program.addLine("Set #{ah_mfr_var.name} = #{ah_mfr_sensor.name}")
      if @fan_rtf_sensor[air_loop].is_a? OpenStudio::Model::EnergyManagementSystemGlobalVariable
        duct_program.addLine("Set #{@fan_rtf_sensor[air_loop].name} = #{@fan_mfr_sensor[air_loop].name} / #{@fan_mfr_max_var[air_loop].name}")
      end
      duct_program.addLine("Set #{@fan_rtf_var[air_loop].name} = #{@fan_rtf_sensor[air_loop].name}")
      duct_program.addLine("Set #{ah_vfr_var.name} = #{ah_vfr_sensor.name}")
      duct_program.addLine("Set #{ah_tout_var.name} = #{ah_tout_sensor.name}")
      duct_program.addLine("Set #{ah_wout_var.name} = #{ah_wout_sensor.name}")
      duct_program.addLine("Set #{ra_t_var.name} = #{ra_t_sensor.name}")
      duct_program.addLine("Set #{ra_w_var.name} = #{ra_w_sensor.name}")
      duct_program.addLine("Set #{dz_t_var.name} = #{dz_t_sensor.name}")
      duct_program.addLine("Set #{dz_w_var.name} = #{dz_w}")
      duct_program.addLine("Run #{duct_subroutine.name}")
      duct_program.addLine("Set #{duct_actuators['supply_sens_lk_to_liv'].name} = #{duct_vars['supply_sens_lk_to_liv'].name}")
      duct_program.addLine("Set #{duct_actuators['supply_lat_lk_to_liv'].name} = #{duct_vars['supply_lat_lk_to_liv'].name}")
      duct_program.addLine("Set #{duct_actuators['supply_cond_to_liv'].name} = #{duct_vars['supply_cond_to_liv'].name}")
      duct_program.addLine("Set #{duct_actuators['return_sens_lk_to_rp'].name} = #{duct_vars['return_sens_lk_to_rp'].name}")
      duct_program.addLine("Set #{duct_actuators['return_lat_lk_to_rp'].name} = #{duct_vars['return_lat_lk_to_rp'].name}")
      duct_program.addLine("Set #{duct_actuators['return_cond_to_rp'].name} = #{duct_vars['return_cond_to_rp'].name}")
      duct_program.addLine("Set #{duct_actuators['return_cond_to_dz'].name} = #{duct_vars['return_cond_to_dz'].name}")
      duct_program.addLine("Set #{duct_actuators['supply_cond_to_dz'].name} = #{duct_vars['supply_cond_to_dz'].name}")
      duct_program.addLine("Set #{duct_actuators['supply_sens_lk_to_dz'].name} = #{duct_vars['supply_sens_lk_to_dz'].name}")
      duct_program.addLine("Set #{duct_actuators['supply_lat_lk_to_dz'].name} = #{duct_vars['supply_lat_lk_to_dz'].name}")
      if not duct_actuators['dz_to_liv_flow_rate'].nil?
        duct_program.addLine("Set #{duct_actuators['dz_to_liv_flow_rate'].name} = #{duct_vars['dz_to_liv_flow_rate'].name}")
      end
      if not duct_actuators['liv_to_dz_flow_rate'].nil?
        duct_program.addLine("Set #{duct_actuators['liv_to_dz_flow_rate'].name} = #{duct_vars['liv_to_dz_flow_rate'].name}")
      end

      if @cfis_airloop.values.include? air_loop

        # Calculate CFIS duct losses
        cfis_id = @cfis_airloop.key(air_loop)
        duct_program.addLine("If #{@cfis_f_damper_extra_open_var[cfis_id].name} > 0")
        duct_program.addLine("  Set cfis_m3s = (#{@fan_mfr_max_var[air_loop].name} / 1.16097654)") # Density of 1.16097654 was back calculated using E+ results
        duct_program.addLine("  Set #{@fan_rtf_var[air_loop].name} = #{@cfis_f_damper_extra_open_var[cfis_id].name}") # Need to use global vars to sync duct_program and infiltration program of different calling points
        duct_program.addLine("  Set #{ah_vfr_var.name} = #{@fan_rtf_var[air_loop].name}*cfis_m3s")
        duct_program.addLine("  Set rho_in = (@RhoAirFnPbTdbW #{@pbar_sensor.name} #{@tin_sensor.name} #{@win_sensor.name})")
        duct_program.addLine("  Set #{ah_mfr_var.name} = #{ah_vfr_var.name} * rho_in")
        duct_program.addLine("  Set #{ah_tout_var.name} = #{ra_t_sensor.name}")
        duct_program.addLine("  Set #{ah_wout_var.name} = #{ra_w_sensor.name}")
        duct_program.addLine("  Set #{ra_t_var.name} = #{ra_t_sensor.name}")
        duct_program.addLine("  Set #{ra_w_var.name} = #{ra_w_sensor.name}")
        duct_program.addLine("  Run #{duct_subroutine.name}")
        duct_program.addLine("  Set #{duct_actuators['cfis_supply_sens_lk_to_liv'].name} = #{duct_vars['supply_sens_lk_to_liv'].name}")
        duct_program.addLine("  Set #{duct_actuators['cfis_supply_lat_lk_to_liv'].name} = #{duct_vars['supply_lat_lk_to_liv'].name}")
        duct_program.addLine("  Set #{duct_actuators['cfis_supply_cond_to_liv'].name} = #{duct_vars['supply_cond_to_liv'].name}")
        duct_program.addLine("  Set #{duct_actuators['cfis_return_sens_lk_to_rp'].name} = #{duct_vars['return_sens_lk_to_rp'].name}")
        duct_program.addLine("  Set #{duct_actuators['cfis_return_lat_lk_to_rp'].name} = #{duct_vars['return_lat_lk_to_rp'].name}")
        duct_program.addLine("  Set #{duct_actuators['cfis_return_cond_to_rp'].name} = #{duct_vars['return_cond_to_rp'].name}")
        duct_program.addLine("  Set #{duct_actuators['cfis_return_cond_to_dz'].name} = #{duct_vars['return_cond_to_dz'].name}")
        duct_program.addLine("  Set #{duct_actuators['cfis_supply_cond_to_dz'].name} = #{duct_vars['supply_cond_to_dz'].name}")
        duct_program.addLine("  Set #{duct_actuators['cfis_supply_sens_lk_to_dz'].name} = #{duct_vars['supply_sens_lk_to_dz'].name}")
        duct_program.addLine("  Set #{duct_actuators['cfis_supply_lat_lk_to_dz'].name} = #{duct_vars['supply_lat_lk_to_dz'].name}")
        if not duct_actuators['dz_to_liv_flow_rate'].nil?
          duct_program.addLine("  Set #{duct_actuators['cfis_dz_to_liv_flow_rate'].name} = #{duct_vars['dz_to_liv_flow_rate'].name}")
        end
        if not duct_actuators['liv_to_dz_flow_rate'].nil?
          duct_program.addLine("  Set #{duct_actuators['cfis_liv_to_dz_flow_rate'].name} = #{duct_vars['liv_to_dz_flow_rate'].name}")
        end
        duct_program.addLine('Else')
        duct_program.addLine("  Set #{duct_actuators['cfis_supply_sens_lk_to_liv'].name} = 0")
        duct_program.addLine("  Set #{duct_actuators['cfis_supply_lat_lk_to_liv'].name} = 0")
        duct_program.addLine("  Set #{duct_actuators['cfis_supply_cond_to_liv'].name} = 0")
        duct_program.addLine("  Set #{duct_actuators['cfis_return_sens_lk_to_rp'].name} = 0")
        duct_program.addLine("  Set #{duct_actuators['cfis_return_lat_lk_to_rp'].name} = 0")
        duct_program.addLine("  Set #{duct_actuators['cfis_return_cond_to_rp'].name} = 0")
        duct_program.addLine("  Set #{duct_actuators['cfis_return_cond_to_dz'].name} = 0")
        duct_program.addLine("  Set #{duct_actuators['cfis_supply_cond_to_dz'].name} = 0")
        duct_program.addLine("  Set #{duct_actuators['cfis_supply_sens_lk_to_dz'].name} = 0")
        duct_program.addLine("  Set #{duct_actuators['cfis_supply_lat_lk_to_dz'].name} = 0")
        if not duct_actuators['dz_to_liv_flow_rate'].nil?
          duct_program.addLine("  Set #{duct_actuators['cfis_dz_to_liv_flow_rate'].name} = 0")
        end
        if not duct_actuators['liv_to_dz_flow_rate'].nil?
          duct_program.addLine("  Set #{duct_actuators['cfis_liv_to_dz_flow_rate'].name} = 0")
        end
        duct_program.addLine('EndIf')

      end

      manager = OpenStudio::Model::EnergyManagementSystemProgramCallingManager.new(model)
      manager.setName("#{duct_program.name} calling manager")
      manager.setCallingPoint('EndOfSystemTimestepAfterHVACReporting')
      manager.addProgram(duct_program)
    end
  end

  def self.apply_infiltration_to_garage(model, weather, ach50)
    return if @spaces[HPXML::LocationGarage].nil?

    space = @spaces[HPXML::LocationGarage]
    area = UnitConversions.convert(space.floorArea, 'm^2', 'ft^2')
    volume = UnitConversions.convert(space.volume, 'm^3', 'ft^3')
    hor_lk_frac = 0.4
    neutral_level = 0.5
    sla = get_infiltration_SLA_from_ACH50(ach50, 0.65, area, volume)
    ela = sla * area
    ach = get_infiltration_ACH_from_SLA(sla, 8.202, weather)
    cfm = ach / UnitConversions.convert(1.0, 'hr', 'min') * volume
    c_w_SG, c_s_SG = calc_wind_stack_coeffs(hor_lk_frac, neutral_level, space)
    apply_infiltration_to_unconditioned_space(model, space, nil, ela, c_w_SG, c_s_SG)
  end

  def self.apply_infiltration_to_unconditioned_basement(model, weather)
    return if @spaces[HPXML::LocationBasementUnconditioned].nil?

    space = @spaces[HPXML::LocationBasementUnconditioned]
    volume = UnitConversions.convert(space.volume, 'm^3', 'ft^3')
    ach = 0.1 # Assumption
    cfm = ach / UnitConversions.convert(1.0, 'hr', 'min') * volume
    apply_infiltration_to_unconditioned_space(model, space, ach, nil, nil, nil)

    # Store info for HVAC Sizing measure
    space.thermalZone.get.additionalProperties.setFeature(Constants.SizingInfoZoneInfiltrationCFM, cfm.to_f)
  end

  def self.apply_infiltration_to_vented_crawlspace(model, weather, vented_crawl)
    return if @spaces[HPXML::LocationCrawlspaceVented].nil?

    space = @spaces[HPXML::LocationCrawlspaceVented]
    volume = UnitConversions.convert(space.volume, 'm^3', 'ft^3')
    sla = vented_crawl.vented_crawlspace_sla
    ach = get_infiltration_ACH_from_SLA(sla, 8.202, weather)
    cfm = ach / UnitConversions.convert(1.0, 'hr', 'min') * volume
    apply_infiltration_to_unconditioned_space(model, space, ach, nil, nil, nil)

    # Store info for HVAC Sizing measure
    space.thermalZone.get.additionalProperties.setFeature(Constants.SizingInfoZoneInfiltrationCFM, cfm.to_f)
  end

  def self.apply_infiltration_to_unvented_crawlspace(model, weather)
    return if @spaces[HPXML::LocationCrawlspaceUnvented].nil?

    space = @spaces[HPXML::LocationCrawlspaceUnvented]
    volume = UnitConversions.convert(space.volume, 'm^3', 'ft^3')
    sla = 0 # Assumption
    ach = get_infiltration_ACH_from_SLA(sla, 8.202, weather)
    cfm = ach / UnitConversions.convert(1.0, 'hr', 'min') * volume
    apply_infiltration_to_unconditioned_space(model, space, ach, nil, nil, nil)

    # Store info for HVAC Sizing measure
    space.thermalZone.get.additionalProperties.setFeature(Constants.SizingInfoZoneInfiltrationCFM, cfm.to_f)
  end

  def self.apply_infiltration_to_vented_attic(model, weather, vented_attic)
    return if @spaces[HPXML::LocationAtticVented].nil?

    if not vented_attic.vented_attic_sla.nil?
      vented_attic_sla = vented_attic.vented_attic_sla
    elsif not vented_attic.vented_attic_ach.nil?
      if @apply_ashrae140_assumptions
        vented_attic_const_ach = vented_attic.vented_attic_ach
      else
        vented_attic_sla = get_infiltration_SLA_from_ACH(vented_attic.vented_attic_ach, 8.202, weather)
      end
    end

    space = @spaces[HPXML::LocationAtticVented]
    volume = UnitConversions.convert(space.volume, 'm^3', 'ft^3')
    if not vented_attic_sla.nil?
      vented_attic_area = UnitConversions.convert(space.floorArea, 'm^2', 'ft^2')
      hor_lk_frac = 0.75
      neutral_level = 0.5
      sla = vented_attic_sla
      ach = get_infiltration_ACH_from_SLA(sla, 8.202, weather)
      ela = sla * vented_attic_area
      cfm = ach / UnitConversions.convert(1.0, 'hr', 'min') * volume
      c_w_SG, c_s_SG = calc_wind_stack_coeffs(hor_lk_frac, neutral_level, space)
      apply_infiltration_to_unconditioned_space(model, space, nil, ela, c_w_SG, c_s_SG)
    elsif not vented_attic_const_ach.nil?
      ach = vented_attic_const_ach
      cfm = ach / UnitConversions.convert(1.0, 'hr', 'min') * volume
      apply_infiltration_to_unconditioned_space(model, space, ach, nil, nil, nil)
    end

    # Store info for HVAC Sizing measure
    space.thermalZone.get.additionalProperties.setFeature(Constants.SizingInfoZoneInfiltrationCFM, cfm.to_f)
  end

  def self.apply_infiltration_to_unvented_attic(model, weather)
    return if @spaces[HPXML::LocationAtticUnvented].nil?

    space = @spaces[HPXML::LocationAtticUnvented]
    area = UnitConversions.convert(space.floorArea, 'm^2', 'ft^2')
    volume = UnitConversions.convert(space.volume, 'm^3', 'ft^3')
    hor_lk_frac = 0.75
    neutral_level = 0.5
    sla = 0 # Assumption
    ach = get_infiltration_ACH_from_SLA(sla, 8.202, weather)
    ela = sla * area
    cfm = ach / UnitConversions.convert(1.0, 'hr', 'min') * volume
    c_w_SG, c_s_SG = calc_wind_stack_coeffs(hor_lk_frac, neutral_level, space)
    apply_infiltration_to_unconditioned_space(model, space, nil, ela, c_w_SG, c_s_SG)

    # Store info for HVAC Sizing measure
    space.thermalZone.get.additionalProperties.setFeature(Constants.SizingInfoZoneInfiltrationCFM, cfm.to_f)
  end

  def self.apply_local_ventilation(model, vent_object_array, obj_type_name)
    obj_sch_sensors = {}
    vent_object_array.each_with_index do |vent_object, index|
      daily_sch = [0.0] * 24
      obj_name = "#{obj_type_name} #{index}"
      remaining_hrs = vent_object.hours_in_operation
      for hr in 1..(vent_object.hours_in_operation.ceil)
        if remaining_hrs >= 1
          daily_sch[(vent_object.start_hour + hr - 1) % 24] = 1.0
        else
          daily_sch[(vent_object.start_hour + hr - 1) % 24] = remaining_hrs
        end
        remaining_hrs -= 1
      end
      obj_sch = HourlyByMonthSchedule.new(model, "#{obj_name} schedule", [daily_sch] * 12, [daily_sch] * 12, false, true, Constants.ScheduleTypeLimitsFraction)
      obj_sch_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Schedule Value')
      obj_sch_sensor.setName("#{obj_name} sch s")
      obj_sch_sensor.setKeyName(obj_sch.schedule.name.to_s)
      obj_sch_sensors[vent_object.id] = obj_sch_sensor

      equip_def = OpenStudio::Model::ElectricEquipmentDefinition.new(model)
      equip_def.setName(obj_name)
      equip = OpenStudio::Model::ElectricEquipment.new(equip_def)
      equip.setName(obj_name)
      equip.setSpace(@living_space)
      equip_def.setDesignLevel(vent_object.fan_power * vent_object.quantity)
      equip_def.setFractionRadiant(0)
      equip_def.setFractionLatent(0)
      equip_def.setFractionLost(1)
      equip.setSchedule(obj_sch.schedule)
      equip.setEndUseSubcategory(Constants.ObjectNameMechanicalVentilation)
    end

    return obj_sch_sensors
  end

  def self.calc_hrv_erv_effectiveness(vent_mech)
    vent_mech_cfm = vent_mech.average_flow_rate
    if (vent_mech_cfm > 0)
      # Must assume an operating condition (HVI seems to use CSA 439)
      t_sup_in = 0.0
      w_sup_in = 0.0028
      t_exh_in = 22.0
      w_exh_in = 0.0065
      cp_a = 1006.0
      p_fan = vent_mech.average_fan_power # Watts

      m_fan = UnitConversions.convert(vent_mech_cfm, 'cfm', 'm^3/s') * 16.02 * Psychrometrics.rhoD_fT_w_P(UnitConversions.convert(t_sup_in, 'C', 'F'), w_sup_in, 14.7) # kg/s

      if not vent_mech.sensible_recovery_efficiency.nil?
        # The following is derived from CSA 439, Clause 9.3.3.1, Eq. 12:
        #    E_SHR = (m_sup,fan * Cp * (Tsup,out - Tsup,in) - P_sup,fan) / (m_exh,fan * Cp * (Texh,in - Tsup,in) + P_exh,fan)
        t_sup_out = t_sup_in + (vent_mech.sensible_recovery_efficiency * (m_fan * cp_a * (t_exh_in - t_sup_in) + p_fan) + p_fan) / (m_fan * cp_a)

        # Calculate the apparent sensible effectiveness
        vent_mech_apparent_sens_eff = (t_sup_out - t_sup_in) / (t_exh_in - t_sup_in)

      else
        # The following is derived from (taken from CSA 439, Clause 9.2.1, Eq. 7):
        t_sup_out = t_sup_in + (vent_mech.sensible_recovery_efficiency_adjusted * (t_exh_in - t_sup_in))

        vent_mech_apparent_sens_eff = vent_mech.sensible_recovery_efficiency_adjusted

      end

      # Calculate the supply temperature before the fan
      t_sup_out_gross = t_sup_out - p_fan / (m_fan * cp_a)

      # Sensible effectiveness of the HX only
      vent_mech_sens_eff = (t_sup_out_gross - t_sup_in) / (t_exh_in - t_sup_in)

      if (vent_mech_sens_eff < 0.0) || (vent_mech_sens_eff > 1.0)
        fail "The calculated ERV/HRV sensible effectiveness is #{vent_mech_sens_eff} but should be between 0 and 1. Please revise ERV/HRV efficiency values."
      end

      # Use summer test condition to determine the latent effectiveness since TRE is generally specified under the summer condition
      if (not vent_mech.total_recovery_efficiency.nil?) || (not vent_mech.total_recovery_efficiency_adjusted.nil?)

        t_sup_in = 35.0
        w_sup_in = 0.0178
        t_exh_in = 24.0
        w_exh_in = 0.0092

        m_fan = UnitConversions.convert(vent_mech_cfm, 'cfm', 'm^3/s') * UnitConversions.convert(Psychrometrics.rhoD_fT_w_P(UnitConversions.convert(t_sup_in, 'C', 'F'), w_sup_in, 14.7), 'lbm/ft^3', 'kg/m^3') # kg/s

        t_sup_out_gross = t_sup_in - vent_mech_sens_eff * (t_sup_in - t_exh_in)
        t_sup_out = t_sup_out_gross + p_fan / (m_fan * cp_a)

        h_sup_in = Psychrometrics.h_fT_w_SI(t_sup_in, w_sup_in)
        h_exh_in = Psychrometrics.h_fT_w_SI(t_exh_in, w_exh_in)

        if not vent_mech.total_recovery_efficiency.nil?
          # The following is derived from CSA 439, Clause 9.3.3.2, Eq. 13:
          #    E_THR = (m_sup,fan * Cp * (h_sup,out - h_sup,in) - P_sup,fan) / (m_exh,fan * Cp * (h_exh,in - h_sup,in) + P_exh,fan)
          h_sup_out = h_sup_in - (vent_mech.total_recovery_efficiency * (m_fan * (h_sup_in - h_exh_in) + p_fan) + p_fan) / m_fan
        else
          # The following is derived from (taken from CSA 439, Clause 9.2.1, Eq. 7):
          h_sup_out = h_sup_in - (vent_mech.total_recovery_efficiency_adjusted * (h_sup_in - h_exh_in))
        end

        w_sup_out = Psychrometrics.w_fT_h_SI(t_sup_out, h_sup_out)
        vent_mech_lat_eff = [0.0, (w_sup_out - w_sup_in) / (w_exh_in - w_sup_in)].max

        if (vent_mech_lat_eff < 0.0) || (vent_mech_lat_eff > 1.0)
          fail "The calculated ERV/HRV latent effectiveness is #{vent_mech_lat_eff} but should be between 0 and 1. Please revise ERV/HRV efficiency values."
        end

      else
        vent_mech_lat_eff = 0.0
      end
    else
      vent_mech_apparent_sens_eff = 0.0
      vent_mech_sens_eff = 0.0
      vent_mech_lat_eff = 0.0
    end

    return vent_mech_sens_eff, vent_mech_lat_eff, vent_mech_apparent_sens_eff
  end

  def self.apply_cfis_to_infil_program(infil_program, vent_mech, cfis_fan_actuator)
    infil_program.addLine("Set fan_rtf_hvac = #{@fan_rtf_sensor[@cfis_airloop[vent_mech.id]].name}")
    infil_program.addLine("Set CFIS_fan_w = #{vent_mech.fan_power}") # W

    infil_program.addLine('If @ABS(Minute - ZoneTimeStep*60) < 0.1')
    infil_program.addLine("  Set #{@cfis_t_sum_open_var[vent_mech.id].name} = 0") # New hour, time on summation re-initializes to 0
    infil_program.addLine('EndIf')

    cfis_open_time = [vent_mech.hours_in_operation / 24.0 * 60.0, 59.999].min # Minimum open time in minutes
    infil_program.addLine("Set CFIS_t_min_hr_open = #{cfis_open_time}") # minutes per hour the CFIS damper is open
    infil_program.addLine("Set CFIS_Q_duct = #{UnitConversions.convert(vent_mech.flow_rate, 'cfm', 'm^3/s')}")
    infil_program.addLine('Set cfis_f_damper_open = 0') # fraction of the timestep the CFIS damper is open
    infil_program.addLine("Set #{@cfis_f_damper_extra_open_var[vent_mech.id].name} = 0") # additional runtime fraction to meet min/hr

    infil_program.addLine("If #{@cfis_t_sum_open_var[vent_mech.id].name} < CFIS_t_min_hr_open")
    infil_program.addLine("  Set CFIS_t_fan_on = 60 - (CFIS_t_min_hr_open - #{@cfis_t_sum_open_var[vent_mech.id].name})") # minute at which the blower needs to turn on to meet the ventilation requirements
    # Evaluate condition of whether supply fan has to run to achieve target minutes per hour of operation
    infil_program.addLine('  If (Minute+0.00001) >= CFIS_t_fan_on')
    # Consider fan rtf read in current calling point (results of previous time step) + CFIS_t_fan_on based on min/hr requirement and previous EMS results.
    infil_program.addLine('    Set cfis_fan_runtime = @Max (@ABS(Minute - CFIS_t_fan_on)) (fan_rtf_hvac * ZoneTimeStep * 60)')
    # If fan_rtf_hvac, make sure it's not exceeding ventilation requirements
    infil_program.addLine("    Set cfis_fan_runtime = @Min cfis_fan_runtime (CFIS_t_min_hr_open - #{@cfis_t_sum_open_var[vent_mech.id].name})")
    infil_program.addLine('    Set cfis_f_damper_open = cfis_fan_runtime/(60.0*ZoneTimeStep)') # calculates the portion of the current timestep the CFIS damper needs to be open
    infil_program.addLine('    Set QWHV_cfis = QWHV_cfis + cfis_f_damper_open*CFIS_Q_duct')
    infil_program.addLine("    Set #{@cfis_t_sum_open_var[vent_mech.id].name} = #{@cfis_t_sum_open_var[vent_mech.id].name}+cfis_fan_runtime")
    infil_program.addLine("    Set #{@cfis_f_damper_extra_open_var[vent_mech.id].name} = @Max (cfis_f_damper_open-fan_rtf_hvac) 0.0")
    infil_program.addLine("    Set #{cfis_fan_actuator.name} = #{cfis_fan_actuator.name} + CFIS_fan_w*#{@cfis_f_damper_extra_open_var[vent_mech.id].name}")
    infil_program.addLine('  Else')
    # No need to turn on blower for extra ventilation
    infil_program.addLine('    Set cfis_fan_runtime = fan_rtf_hvac*ZoneTimeStep*60')
    infil_program.addLine("    If (#{@cfis_t_sum_open_var[vent_mech.id].name}+cfis_fan_runtime) > CFIS_t_min_hr_open")
    # Damper is only open for a portion of this time step to achieve target minutes per hour
    infil_program.addLine("      Set cfis_fan_runtime = CFIS_t_min_hr_open-#{@cfis_t_sum_open_var[vent_mech.id].name}")
    infil_program.addLine('      Set cfis_f_damper_open = cfis_fan_runtime/(ZoneTimeStep*60)')
    infil_program.addLine('      Set QWHV_cfis = QWHV_cfis + cfis_f_damper_open*CFIS_Q_duct')
    infil_program.addLine("      Set #{@cfis_t_sum_open_var[vent_mech.id].name} = CFIS_t_min_hr_open")
    infil_program.addLine('    Else')
    # Damper is open and using call for heat/cool to supply fresh air
    infil_program.addLine('      Set cfis_fan_runtime = fan_rtf_hvac*ZoneTimeStep*60')
    infil_program.addLine('      Set cfis_f_damper_open = fan_rtf_hvac')
    infil_program.addLine('      Set QWHV_cfis = QWHV_cfis + cfis_f_damper_open * CFIS_Q_duct')
    infil_program.addLine("      Set #{@cfis_t_sum_open_var[vent_mech.id].name} = #{@cfis_t_sum_open_var[vent_mech.id].name}+cfis_fan_runtime")
    infil_program.addLine('    EndIf')
    # Fan power is metered under fan cooling and heating meters
    infil_program.addLine('  EndIf')
    infil_program.addLine('EndIf')

    return infil_program
  end

  def self.add_ee_for_vent_fan_power(model, obj_name, frac_lost, is_cfis, pow = 0.0)
    equip_def = OpenStudio::Model::ElectricEquipmentDefinition.new(model)
    equip_def.setName(obj_name)
    equip = OpenStudio::Model::ElectricEquipment.new(equip_def)
    equip.setName(obj_name)
    equip.setSpace(@living_space)
    equip_def.setFractionRadiant(0)
    equip_def.setFractionLatent(0)
    equip.setSchedule(model.alwaysOnDiscreteSchedule)
    equip.setEndUseSubcategory(Constants.ObjectNameMechanicalVentilation)
    equip_def.setFractionLost(frac_lost)
    vent_mech_fan_actuator = nil
    if is_cfis # actuate its power level in EMS
      equip_def.setFractionLost(0.0) # Fan heat does enter space
      vent_mech_fan_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(equip, 'ElectricEquipment', 'Electric Power Level')
      vent_mech_fan_actuator.setName("#{equip.name} act")
    else
      equip_def.setDesignLevel(pow)
    end

    return vent_mech_fan_actuator
  end

  def self.apply_erv_hrv_load_to_infil_program(model, infil_program, vent_mech_cfm, vent_mech_sens_eff, vent_mech_lat_eff, erv_sens_load_actuator, erv_lat_load_actuator)
    # Calculate mass flow rate based on outdoor air density
    infil_program.addLine("Set balanced_flow_rate = #{UnitConversions.convert(vent_mech_cfm, 'cfm', 'm^3/s')}")
    infil_program.addLine('Set ERV_MFR = balanced_flow_rate * ERVSupRho')

    # Heat exchanger calculation
    infil_program.addLine('Set ERVCpMin = (@Min ERVSupCp ERVSecCp)')
    infil_program.addLine("Set ERVSupOutTemp = ERVSupInTemp + ERVCpMin/ERVSupCp * #{vent_mech_sens_eff} * (ERVSecInTemp - ERVSupInTemp)")
    infil_program.addLine("Set ERVSupOutW = ERVSupInW + ERVCpMin/ERVSupCp * #{vent_mech_lat_eff} * (ERVSecInW - ERVSupInW)")
    infil_program.addLine('Set ERVSupOutEnth = (@HFnTdbW ERVSupOutTemp ERVSupOutW)')
    infil_program.addLine('Set ERVSensHeatTrans = ERV_MFR * ERVSupCp * (ERVSupOutTemp - ERVSupInTemp)')
    infil_program.addLine('Set ERVTotalHeatTrans = ERV_MFR * (ERVSupOutEnth - ERVSupInEnth)')
    infil_program.addLine('Set ERVLatHeatTrans = ERVTotalHeatTrans - ERVSensHeatTrans')

    # Load calculation
    infil_program.addLine('Set ERVTotalToLv = ERV_MFR * (ERVSupOutEnth - ERVSecInEnth)')
    infil_program.addLine('Set ERVSensToLv = ERV_MFR * ERVSecCp * (ERVSupOutTemp - ERVSecInTemp)')
    infil_program.addLine('Set ERVLatToLv = ERVTotalToLv - ERVSensToLv')

    # Actuator
    infil_program.addLine("Set #{erv_sens_load_actuator.name} = #{erv_sens_load_actuator.name} + ERVSensToLv")
    infil_program.addLine("Set #{erv_lat_load_actuator.name} = #{erv_lat_load_actuator.name} + ERVLatToLv")
    infil_program.addLine("Set QWHV_ervhrv = QWHV_ervhrv + #{UnitConversions.convert(vent_mech_cfm, 'cfm', 'm^3/s')}")

    return infil_program
  end

  def self.apply_infiltration_and_ventilation_fans(model, weather, vent_fans_mech, vent_fans_kitchen, vent_fans_bath, has_flue_chimney, air_infils, vented_attic, vented_crawl)
    # Get living space infiltration
    living_ach50 = nil
    living_const_ach = nil
    air_infils.each do |air_infil|
      if (air_infil.unit_of_measure == HPXML::UnitsACH) && (air_infil.house_pressure == 50)
        living_ach50 = air_infil.air_leakage
      elsif (air_infil.unit_of_measure == HPXML::UnitsCFM) && (air_infil.house_pressure == 50)
        living_ach50 = air_infil.air_leakage * 60.0 / @infil_volume # Convert CFM50 to ACH50
      elsif air_infil.unit_of_measure == HPXML::UnitsACHNatural
        if @apply_ashrae140_assumptions
          living_const_ach = air_infil.air_leakage
        else
          sla = get_infiltration_SLA_from_ACH(air_infil.air_leakage, @infil_height, weather)
          living_ach50 = get_infiltration_ACH50_from_SLA(sla, 0.65, @cfa, @infil_volume)
        end
      end
    end

    # Infiltration for unconditioned spaces
    apply_infiltration_to_garage(model, weather, living_ach50)
    apply_infiltration_to_unconditioned_basement(model, weather)
    apply_infiltration_to_vented_crawlspace(model, weather, vented_crawl)
    apply_infiltration_to_unvented_crawlspace(model, weather)
    apply_infiltration_to_vented_attic(model, weather, vented_attic)
    apply_infiltration_to_unvented_attic(model, weather)

    # Local ventilation
    range_sch_sensors_map = apply_local_ventilation(model, vent_fans_kitchen, Constants.ObjectNameMechanicalVentilationRangeFan)
    bath_sch_sensors_map = apply_local_ventilation(model, vent_fans_bath, Constants.ObjectNameMechanicalVentilationBathFan)

    # Get mechanical ventilation
    vent_mech_sup = vent_fans_mech.select { |vent_mech| vent_mech.fan_type == HPXML::MechVentTypeSupply }
    vent_mech_exh = vent_fans_mech.select { |vent_mech| vent_mech.fan_type == HPXML::MechVentTypeExhaust }
    vent_mech_cfis = vent_fans_mech.select { |vent_mech| vent_mech.fan_type == HPXML::MechVentTypeCFIS }
    vent_mech_bal = vent_fans_mech.select { |vent_mech| vent_mech.fan_type == HPXML::MechVentTypeBalanced }
    vent_mech_erv_hrv = vent_fans_mech.select { |vent_mech| [HPXML::MechVentTypeERV, HPXML::MechVentTypeHRV].include? vent_mech.fan_type }

    sup_vent_mech_fan_w = vent_mech_sup.map { |vent_mech| vent_mech.average_fan_power }.sum(0.0)
    exh_vent_mech_fan_w = vent_mech_exh.map { |vent_mech| vent_mech.average_fan_power }.sum(0.0)
    # ERV/HRV and balanced system fan power combined altogether
    bal_vent_mech_fan_w = (vent_mech_bal + vent_mech_erv_hrv).map { |vent_mech| vent_mech.average_fan_power }.sum(0.0)
    total_sup_exh_bal_w = sup_vent_mech_fan_w + exh_vent_mech_fan_w + bal_vent_mech_fan_w
    # 1.0: Fan heat does not enter space, 0.0: Fan heat does enter space, 0.5: Supply fan heat enters space
    if total_sup_exh_bal_w > 0.0
      fan_heat_lost_fraction = (1.0 * exh_vent_mech_fan_w + 0.0 * sup_vent_mech_fan_w + 0.5 * bal_vent_mech_fan_w) / total_sup_exh_bal_w
    else
      fan_heat_lost_fraction = 1.0
    end
    add_ee_for_vent_fan_power(model, Constants.ObjectNameMechanicalVentilationHouseFan, fan_heat_lost_fraction, false, total_sup_exh_bal_w)

    # get cfms
    sup_cfm = vent_mech_sup.map { |vent_mech| vent_mech.average_flow_rate }.sum(0.0)
    exh_cfm = vent_mech_exh.map { |vent_mech| vent_mech.average_flow_rate }.sum(0.0)
    bal_cfm = vent_mech_bal.map { |vent_mech| vent_mech.average_flow_rate }.sum(0.0)
    erv_hrv_cfm = vent_mech_erv_hrv.map { |vent_mech| vent_mech.average_flow_rate }.sum(0.0)
    cfis_cfm = vent_mech_cfis.map { |vent_mech| vent_mech.average_flow_rate }.sum(0.0)

    # Balanced and unbalanced airflow calculated for hvac sizing
    tot_sup_cfm = sup_cfm + bal_cfm + erv_hrv_cfm + cfis_cfm
    tot_exh_cfm = exh_cfm + bal_cfm + erv_hrv_cfm
    tot_bal_cfm = [tot_sup_cfm, tot_exh_cfm].min
    tot_unbal_cfm = (tot_sup_cfm - tot_exh_cfm).abs

    # Store info for HVAC Sizing measure
    model.getBuilding.additionalProperties.setFeature(Constants.SizingInfoMechVentWholeHouseRateBalanced, tot_bal_cfm)
    model.getBuilding.additionalProperties.setFeature(Constants.SizingInfoMechVentWholeHouseRateUnbalanced, tot_unbal_cfm)
    model.getBuilding.additionalProperties.setFeature(Constants.SizingInfoMechVentExist, (not vent_fans_mech.empty?))

    # Fan Actuators
    cfis_fan_actuator = add_ee_for_vent_fan_power(model, Constants.ObjectNameMechanicalVentilationHouseFanCFIS, 0.0, true)

    infil_flow = OpenStudio::Model::SpaceInfiltrationDesignFlowRate.new(model)
    infil_flow.setName(Constants.ObjectNameInfiltration + ' flow')
    infil_flow.setSchedule(model.alwaysOnDiscreteSchedule)
    infil_flow.setSpace(@living_space)
    infil_flow_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(infil_flow, 'Zone Infiltration', 'Air Exchange Flow Rate')
    infil_flow_actuator.setName("#{infil_flow.name} act")

    mechvent_flow = OpenStudio::Model::SpaceInfiltrationDesignFlowRate.new(model)
    mechvent_flow.setName(Constants.ObjectNameMechanicalVentilation + ' flow')
    mechvent_flow.setSchedule(model.alwaysOnDiscreteSchedule)
    mechvent_flow.setSpace(@living_space)
    mechvent_flow_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(mechvent_flow, 'Zone Infiltration', 'Air Exchange Flow Rate')
    mechvent_flow_actuator.setName("#{mechvent_flow.name} act")

    # Living Space Infiltration Calculation/Program
    infil_program = OpenStudio::Model::EnergyManagementSystemProgram.new(model)
    infil_program.setName(Constants.ObjectNameInfiltration + ' program')

    infil_program = apply_infiltration_to_living(living_ach50, living_const_ach, infil_program, weather, has_flue_chimney)

    infil_program.addLine('Set QWHV_ervhrv = 0.0')
    if not vent_mech_erv_hrv.empty?
      # Actuators for ERV/HRV
      sens_name = "#{Constants.ObjectNameERVHRV} sensible load"
      erv_sens_load_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, sens_name.gsub(' ', '_'))
      erv_sens_load_actuator = create_sens_lat_load_actuator_and_equipment(model, sens_name, @living_space, 0.0, 0.0)
      lat_name = "#{Constants.ObjectNameERVHRV} latent load"
      erv_lat_load_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, lat_name.gsub(' ', '_'))
      erv_lat_load_actuator = create_sens_lat_load_actuator_and_equipment(model, lat_name, @living_space, 1.0, 0.0)

      infil_program.addLine("Set #{erv_sens_load_actuator.name} = 0.0")
      infil_program.addLine("Set #{erv_lat_load_actuator.name} = 0.0")

      # ERV/HRV EMS load model
      # E+ ERV model is using standard density for MFR calculation, caused discrepancy with other system types.
      # Therefore ERV is modeled within EMS infiltration program

      # Air property at inlet nodes in two sides of ERV
      # Common part across multiple erv/hrv programs, create only once
      infil_program.addLine("Set ERVSupInPb = #{@pbar_sensor.name}") # oa barometric pressure
      infil_program.addLine("Set ERVSupInTemp = #{@tout_sensor.name}") # oa db temperature
      infil_program.addLine("Set ERVSupInW = #{@wout_sensor.name}")   # oa humidity ratio
      infil_program.addLine('Set ERVSupRho = (@RhoAirFnPbTdbW ERVSupInPb ERVSupInTemp ERVSupInW)')
      infil_program.addLine('Set ERVSupCp = (@CpAirFnW ERVSupInW)')
      infil_program.addLine('Set ERVSupInEnth = (@HFnTdbW ERVSupInTemp ERVSupInW)')

      infil_program.addLine("Set ERVSecInTemp = #{@tin_sensor.name}") # zone air temperature
      infil_program.addLine("Set ERVSecInW = #{@win_sensor.name}") # zone air humidity ratio
      infil_program.addLine('Set ERVSecCp = (@CpAirFnW ERVSecInW)')
      infil_program.addLine('Set ERVSecInEnth = (@HFnTdbW ERVSecInTemp ERVSecInW)')
    end

    # Calculate cfm weighted average effectiveness for hvac sizing
    # Please review this, and its integration with hvac_sizing
    weighted_vent_mech_lat_eff = 0.0
    weighted_vent_mech_apparent_sens_eff = 0.0

    # Apply ERV/HRV mechanical ventilation
    vent_mech_erv_hrv.each do |vent_mech|
      vent_mech_sens_eff, vent_mech_lat_eff, vent_mech_apparent_sens_eff = calc_hrv_erv_effectiveness(vent_mech)
      # No need to add balanced system here to average because their effectivenesses are all 0.0
      weighted_vent_mech_lat_eff += vent_mech.average_flow_rate / tot_bal_cfm * vent_mech_lat_eff
      weighted_vent_mech_apparent_sens_eff += vent_mech.average_flow_rate / tot_bal_cfm * vent_mech_apparent_sens_eff

      infil_program = apply_erv_hrv_load_to_infil_program(model, infil_program, vent_mech.average_flow_rate, vent_mech_sens_eff, vent_mech_lat_eff, erv_sens_load_actuator, erv_lat_load_actuator)
    end

    model.getBuilding.additionalProperties.setFeature(Constants.SizingInfoMechVentLatentEffectiveness, weighted_vent_mech_lat_eff)
    model.getBuilding.additionalProperties.setFeature(Constants.SizingInfoMechVentApparentSensibleEffectiveness, weighted_vent_mech_apparent_sens_eff)

    # Apply CFIS
    infil_program.addLine('Set QWHV_cfis = 0.0')
    infil_program.addLine("Set #{cfis_fan_actuator.name} = 0.0")

    vent_mech_cfis.each do |vent_mech|
      infil_program = apply_cfis_to_infil_program(infil_program, vent_mech, cfis_fan_actuator)
    end

    infil_program.addLine('Set Qrange = 0')
    vent_fans_kitchen.each do |vent_kitchen|
      infil_program.addLine("Set Qrange = Qrange + #{UnitConversions.convert(vent_kitchen.rated_flow_rate * vent_kitchen.quantity, 'cfm', 'm^3/s').round(4)} * #{range_sch_sensors_map[vent_kitchen.id].name}")
    end

    infil_program.addLine('Set Qbath = 0')
    vent_fans_bath.each do |vent_bath|
      infil_program.addLine("Set Qbath = Qbath + #{UnitConversions.convert(vent_bath.rated_flow_rate * vent_bath.quantity, 'cfm', 'm^3/s').round(4)} * #{bath_sch_sensors_map[vent_bath.id].name}")
    end

    infil_program.addLine('Set Qexhaust = Qrange+Qbath')
    infil_program.addLine('Set Qsupply = 0')
    infil_program.addLine("Set QWHV_sup = #{UnitConversions.convert(sup_cfm, 'cfm', 'm^3/s').round(4)}")
    infil_program.addLine("Set QWHV_exh = #{UnitConversions.convert(exh_cfm, 'cfm', 'm^3/s').round(4)}")
    infil_program.addLine("Set QWHV_bal = #{UnitConversions.convert(bal_cfm, 'cfm', 'm^3/s').round(4)}")

    infil_program.addLine('Set Qexhaust = Qexhaust + QWHV_exh + QWHV_bal + QWHV_ervhrv')
    infil_program.addLine('Set Qsupply = Qsupply + QWHV_sup + QWHV_bal + QWHV_cfis + QWHV_ervhrv')

    # Calculate adjusted infiltration based on mechanical ventilation system
    infil_program.addLine('Set Qfan = (@Max Qexhaust Qsupply)')
    if Constants.ERIVersions.index(@eri_version) >= Constants.ERIVersions.index('2019')
      # Follow ASHRAE 62.2-2016, Normative Appendix C equations for time-varying total airflow
      infil_program.addLine('If Qfan > 0')
      # Balanced system if the total supply airflow and total exhaust airflow are within 10% of their average.
      infil_program.addLine('  Set Qavg = ((Qexhaust + Qsupply) / 2.0)')
      infil_program.addLine('  If ((@Abs (Qexhaust - Qavg)) / Qavg) <= 0.1') # Only need to check Qexhaust, Qsupply will give same result
      infil_program.addLine('    Set phi = 1')
      infil_program.addLine('  Else')
      infil_program.addLine('    Set phi = (Qinf / (Qinf + Qfan))')
      infil_program.addLine('  EndIf')
      infil_program.addLine('  Set Qinf_adj = phi * Qinf')
      infil_program.addLine('Else')
      infil_program.addLine('  Set Qinf_adj = Qinf')
      infil_program.addLine('EndIf')
    else
      infil_program.addLine('Set Qu = (@Abs (Qexhaust - Qsupply))') # Unbalanced flow
      infil_program.addLine('Set Qb = Qfan - Qu') # Balanced flow
      infil_program.addLine('Set Qtot = (((Qu^2) + (Qinf^2)) ^ 0.5) + Qb')
      infil_program.addLine('Set Qinf_adj = Qtot - Qu - Qb')
    end
    infil_program.addLine("Set #{mechvent_flow_actuator.name} = Qfan - QWHV_ervhrv") # QWHV load captured by ERV/HRV program
    infil_program.addLine("Set #{infil_flow_actuator.name} = Qinf_adj")

    program_calling_manager = OpenStudio::Model::EnergyManagementSystemProgramCallingManager.new(model)
    program_calling_manager.setName("#{infil_program.name} calling manager")
    program_calling_manager.setCallingPoint('BeginTimestepBeforePredictor')
    program_calling_manager.addProgram(infil_program)
  end

  def self.apply_infiltration_to_living(living_ach50, living_const_ach, infil_program, weather, has_flue_chimney)
    if living_ach50.to_f > 0
      # Based on "Field Validation of Algebraic Equations for Stack and
      # Wind Driven Air Infiltration Calculations" by Walker and Wilson (1998)

      outside_air_density = UnitConversions.convert(weather.header.LocalPressure, 'atm', 'Btu/ft^3') / (Gas.Air.r * (weather.data.AnnualAvgDrybulb + 460.0))

      n_i = 0.65 # Pressure Exponent
      living_sla = get_infiltration_SLA_from_ACH50(living_ach50, n_i, @cfa, @infil_volume) # Calculate SLA
      a_o = living_sla * @cfa # Effective Leakage Area (ft^2)

      # Flow Coefficient (cfm/inH2O^n) (based on ASHRAE HoF)
      inf_conv_factor = 776.25 # [ft/min]/[inH2O^(1/2)*ft^(3/2)/lbm^(1/2)]
      delta_pref = 0.016 # inH2O
      c_i = a_o * (2.0 / outside_air_density)**0.5 * delta_pref**(0.5 - n_i) * inf_conv_factor

      if has_flue_chimney
        y_i = 0.2 # Fraction of leakage through the flue; 0.2 is a "typical" value according to THE ALBERTA AIR INFIL1RATION MODEL, Walker and Wilson, 1990
        flue_height = @building_height + 2.0 # ft
        s_wflue = 1.0 # Flue Shelter Coefficient
      else
        y_i = 0.0 # Fraction of leakage through the flu
        flue_height = 0.0 # ft
        s_wflue = 0.0 # Flue Shelter Coefficient
      end

      # Leakage distributions per Iain Walker (LBL) recommendations
      if not @spaces[HPXML::LocationCrawlspaceVented].nil?
        # 15% ceiling, 35% walls, 50% floor leakage distribution for vented crawl
        leakage_ceiling = 0.15
        leakage_walls = 0.35
        leakage_floor = 0.50
      else
        # 25% ceiling, 50% walls, 25% floor leakage distribution for slab/basement/unvented crawl
        leakage_ceiling = 0.25
        leakage_walls = 0.50
        leakage_floor = 0.25
      end

      r_i = (leakage_ceiling + leakage_floor)
      x_i = (leakage_ceiling - leakage_floor)
      r_i *= (1 - y_i)
      x_i *= (1 - y_i)
      z_f = flue_height / (@infil_height + Geometry.get_z_origin_for_zone(@living_zone))

      # Calculate Stack Coefficient
      m_o = (x_i + (2.0 * n_i + 1.0) * y_i)**2.0 / (2 - r_i)
      if m_o <=  1.0
        m_i = m_o # eq. 10
      else
        m_i = 1.0 # eq. 11
      end
      if has_flue_chimney
        x_c = r_i + (2.0 * (1.0 - r_i - y_i)) / (n_i + 1.0) - 2.0 * y_i * (z_f - 1.0)**n_i # Eq. 13
        f_i = n_i * y_i * (z_f - 1.0)**((3.0 * n_i - 1.0) / 3.0) * (1.0 - (3.0 * (x_c - x_i)**2.0 * r_i**(1 - n_i)) / (2.0 * (z_f + 1.0))) # Additive flue function, Eq. 12
      else
        x_c = r_i + (2.0 * (1.0 - r_i - y_i)) / (n_i + 1.0) # Critical value of ceiling-floor leakage difference where the neutral level is located at the ceiling (eq. 13)
        f_i = 0.0 # Additive flue function (eq. 12)
      end
      f_s = ((1.0 + n_i * r_i) / (n_i + 1.0)) * (0.5 - 0.5 * m_i**1.2)**(n_i + 1.0) + f_i
      stack_coef = f_s * (UnitConversions.convert(outside_air_density * Constants.g * @infil_height, 'lbm/(ft*s^2)', 'inH2O') / (Constants.AssumedInsideTemp + 460.0))**n_i # inH2O^n/R^n

      # Calculate wind coefficient
      if not @spaces[HPXML::LocationCrawlspaceVented].nil?
        if x_i > 1.0 - 2.0 * y_i
          # Critical floor to ceiling difference above which f_w does not change (eq. 25)
          x_i = 1.0 - 2.0 * y_i
        end
        r_x = 1.0 - r_i * (n_i / 2.0 + 0.2) # Redefined R for wind calculations for houses with crawlspaces (eq. 21)
        y_x = 1.0 - y_i / 4.0 # Redefined Y for wind calculations for houses with crawlspaces (eq. 22)
        x_s = (1.0 - r_i) / 5.0 - 1.5 * y_i # Used to calculate X_x (eq.24)
        x_x = 1.0 - (((x_i - x_s) / (2.0 - r_i))**2.0)**0.75 # Redefined X for wind calculations for houses with crawlspaces (eq. 23)
        f_w = 0.19 * (2.0 - n_i) * x_x * r_x * y_x # Wind factor (eq. 20)
      else
        j_i = (x_i + r_i + 2.0 * y_i) / 2.0
        f_w = 0.19 * (2.0 - n_i) * (1.0 - ((x_i + r_i) / 2.0)**(1.5 - y_i)) - y_i / 4.0 * (j_i - 2.0 * y_i * j_i**4.0)
      end
      wind_coef = f_w * UnitConversions.convert(outside_air_density / 2.0, 'lbm/ft^3', 'inH2O/mph^2')**n_i # inH2O^n/mph^2n

      living_ach = get_infiltration_ACH_from_SLA(living_sla, @infil_height, weather)
      living_cfm = living_ach / UnitConversions.convert(1.0, 'hr', 'min') * @infil_volume

      infil_program.addLine("Set p_m = #{@wind_speed.ashrae_terrain_exponent}")
      infil_program.addLine("Set p_s = #{@wind_speed.ashrae_site_terrain_exponent}")
      infil_program.addLine("Set s_m = #{@wind_speed.ashrae_terrain_thickness}")
      infil_program.addLine("Set s_s = #{@wind_speed.ashrae_site_terrain_thickness}")
      infil_program.addLine("Set z_m = #{UnitConversions.convert(@wind_speed.height, 'ft', 'm')}")
      infil_program.addLine("Set z_s = #{UnitConversions.convert(@infil_height, 'ft', 'm')}")
      infil_program.addLine('Set f_t = (((s_m/z_m)^p_m)*((z_s/s_s)^p_s))')
      infil_program.addLine("Set Tdiff = #{@tin_sensor.name}-#{@tout_sensor.name}")
      infil_program.addLine('Set dT = @Abs Tdiff')
      infil_program.addLine("Set c = #{((UnitConversions.convert(c_i, 'cfm', 'm^3/s') / (UnitConversions.convert(1.0, 'inH2O', 'Pa')**n_i))).round(4)}")
      infil_program.addLine("Set Cs = #{(stack_coef * (UnitConversions.convert(1.0, 'inH2O/R', 'Pa/K')**n_i)).round(4)}")
      infil_program.addLine("Set Cw = #{(wind_coef * (UnitConversions.convert(1.0, 'inH2O/mph^2', 'Pa*s^2/m^2')**n_i)).round(4)}")
      infil_program.addLine("Set n = #{n_i}")
      infil_program.addLine("Set sft = (f_t*#{(((@wind_speed.S_wo * (1.0 - y_i)) + (s_wflue * (1.5 * y_i))))})")
      infil_program.addLine("Set temp1 = ((c*Cw)*((sft*#{@vwind_sensor.name})^(2*n)))^2")
      infil_program.addLine('Set Qinf = (((c*Cs*(dT^n))^2)+temp1)^0.5')
      infil_program.addLine('Set Qinf = (@Max Qinf 0)')

    elsif living_const_ach.to_f > 0

      living_ach = living_const_ach
      living_cfm = living_ach / UnitConversions.convert(1.0, 'hr', 'min') * @infil_volume

      infil_program.addLine("Set Qinf = #{living_ach * UnitConversions.convert(@infil_volume, 'ft^3', 'm^3') / UnitConversions.convert(1.0, 'hr', 's')}")
    else
      infil_program.addLine('Set Qinf = 0')
    end

    # Store info for HVAC Sizing measure
    @living_zone.additionalProperties.setFeature(Constants.SizingInfoZoneInfiltrationCFM, living_cfm.to_f)
    @living_zone.additionalProperties.setFeature(Constants.SizingInfoZoneInfiltrationACH, living_ach.to_f)

    return infil_program
  end

  def self.calc_wind_stack_coeffs(hor_lk_frac, neutral_level, space, space_height = nil)
    if space_height.nil?
      space_height = Geometry.get_height_of_spaces([space])
    end
    coord_z = Geometry.get_z_origin_for_zone(space.thermalZone.get)
    f_t_SG = @wind_speed.site_terrain_multiplier * ((space_height + coord_z) / 32.8)**@wind_speed.site_terrain_exponent / (@wind_speed.terrain_multiplier * (@wind_speed.height / 32.8)**@wind_speed.terrain_exponent)
    f_s_SG = 2.0 / 3.0 * (1 + hor_lk_frac / 2.0) * (2.0 * neutral_level * (1.0 - neutral_level))**0.5 / (neutral_level**0.5 + (1.0 - neutral_level)**0.5)
    f_w_SG = @wind_speed.shielding_coef * (1.0 - hor_lk_frac)**(1.0 / 3.0) * f_t_SG
    c_s_SG = f_s_SG**2.0 * Constants.g * space_height / (Constants.AssumedInsideTemp + 460.0)
    c_w_SG = f_w_SG**2.0
    return c_w_SG, c_s_SG
  end

  def self.get_infiltration_NL_from_SLA(sla, infil_height)
    # Returns infiltration normalized leakage given SLA.
    return 1000.0 * sla * (infil_height / 8.202)**0.4
  end

  def self.get_infiltration_ACH_from_SLA(sla, infil_height, weather)
    # Returns the infiltration annual average ACH given a SLA.
    # Equation from RESNET 380-2016 Equation 9
    norm_leakage = get_infiltration_NL_from_SLA(sla, infil_height)

    # Equation from ASHRAE 136-1993
    return norm_leakage * weather.data.WSF
  end

  def self.get_infiltration_SLA_from_ACH(ach, infil_height, weather)
    # Returns the infiltration SLA given an annual average ACH.
    return ach / (weather.data.WSF * 1000 * (infil_height / 8.202)**0.4)
  end

  def self.get_infiltration_SLA_from_ACH50(ach50, n_i, conditionedFloorArea, conditionedVolume, pressure_difference_Pa = 50)
    # Returns the infiltration SLA given a ACH50.
    return ((ach50 * 0.283316478 * 4.0**n_i * conditionedVolume) / (conditionedFloorArea * UnitConversions.convert(1.0, 'ft^2', 'in^2') * pressure_difference_Pa**n_i * 60.0))
  end

  def self.get_infiltration_ACH50_from_SLA(sla, n_i, conditionedFloorArea, conditionedVolume, pressure_difference_Pa = 50)
    # Returns the infiltration ACH50 given a SLA.
    return ((sla * conditionedFloorArea * UnitConversions.convert(1.0, 'ft^2', 'in^2') * pressure_difference_Pa**n_i * 60.0) / (0.283316478 * 4.0**n_i * conditionedVolume))
  end

  def self.calc_duct_leakage_at_diff_pressure(q_old, p_old, p_new)
    return q_old * (p_new / p_old)**0.6 # Derived from Equation C-1 (Annex C), p34, ASHRAE Standard 152-2004.
  end

  def self.get_duct_insulation_rvalue(nominal_rvalue, side)
    # Insulated duct values based on "True R-Values of Round Residential Ductwork"
    # by Palmiter & Kruse 2006. Linear extrapolation from SEEM's "DuctTrueRValues"
    # worksheet in, e.g., ExistingResidentialSingleFamily_SEEMRuns_v05.xlsm.
    #
    # Nominal | 4.2 | 6.0 | 8.0 | 11.0
    # --------|-----|-----|-----|----
    # Supply  | 4.5 | 5.7 | 6.8 | 8.4
    # Return  | 4.9 | 6.3 | 7.8 | 9.7
    #
    # Uninsulated ducts are set to R-1.7 based on ASHRAE HOF and the above paper.
    if nominal_rvalue <= 0
      return 1.7
    end
    if side == HPXML::DuctTypeSupply
      return 2.2438 + 0.5619 * nominal_rvalue
    elsif side == HPXML::DuctTypeReturn
      return 2.0388 + 0.7053 * nominal_rvalue
    end
  end

  def self.get_mech_vent_whole_house_cfm(frac622, num_beds, cfa, std)
    # Returns the ASHRAE 62.2 whole house mechanical ventilation rate, excluding any infiltration credit.
    if std == '2013'
      return frac622 * ((num_beds + 1.0) * 7.5 + 0.03 * cfa)
    end

    return frac622 * ((num_beds + 1.0) * 7.5 + 0.01 * cfa)
  end
end

class Duct
  def initialize(side, loc_space, loc_schedule, leakage_frac, leakage_cfm25, area, rvalue)
    @side = side
    @loc_space = loc_space
    @loc_schedule = loc_schedule
    @leakage_frac = leakage_frac
    @leakage_cfm25 = leakage_cfm25
    @area = area
    @rvalue = rvalue
  end
  attr_accessor(:side, :loc_space, :loc_schedule, :leakage_frac, :leakage_cfm25, :area, :rvalue, :zone, :location)
end

class WindSpeed
  def initialize
  end
  attr_accessor(:height, :terrain_multiplier, :terrain_exponent, :ashrae_terrain_thickness, :ashrae_terrain_exponent, :site_terrain_multiplier, :site_terrain_exponent, :ashrae_site_terrain_thickness, :ashrae_site_terrain_exponent, :S_wo, :shielding_coef)
end
