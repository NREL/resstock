# frozen_string_literal: true

require_relative 'constants'
require_relative 'unit_conversions'
require_relative 'schedules'
require_relative 'util'
require_relative 'psychrometrics'
require_relative 'hvac'

class Airflow
  def self.apply(model, runner, weather, infil, mech_vent, nat_vent, whf, duct_systems,
                 cfa, infil_volume, infil_height, nbeds, nbaths, ncfl_ag, window_area,
                 min_neighbor_distance, vent_fan_kitchen, vent_fan_bath)

    @runner = runner
    @infMethodConstantCFM = 'CONSTANT_CFM'
    @infMethodAIM2 = 'AIM2' # aka ASHRAE Enhanced
    @infMethodELA = 'ELA'

    model_spaces = model.getSpaces

    # Populate building object
    building = Building.new
    building.height = Geometry.get_max_z_of_spaces(model_spaces)
    model.getThermalZones.each do |thermal_zone|
      if Geometry.is_living(thermal_zone)
        building.living = ZoneInfo.new(thermal_zone, Geometry.get_height_of_spaces(thermal_zone.spaces), UnitConversions.convert(thermal_zone.floorArea, 'm^2', 'ft^2'), Geometry.get_zone_volume(thermal_zone), Geometry.get_z_origin_for_zone(thermal_zone), nil, nil)
      elsif Geometry.is_garage(thermal_zone)
        building.garage = ZoneInfo.new(thermal_zone, Geometry.get_height_of_spaces(thermal_zone.spaces), UnitConversions.convert(thermal_zone.floorArea, 'm^2', 'ft^2'), Geometry.get_zone_volume(thermal_zone), Geometry.get_z_origin_for_zone(thermal_zone), nil, nil)
      elsif Geometry.is_unconditioned_basement(thermal_zone)
        building.unconditioned_basement = ZoneInfo.new(thermal_zone, Geometry.get_height_of_spaces(thermal_zone.spaces), UnitConversions.convert(thermal_zone.floorArea, 'm^2', 'ft^2'), Geometry.get_zone_volume(thermal_zone), Geometry.get_z_origin_for_zone(thermal_zone), infil.unconditioned_basement_ach, nil)
      elsif Geometry.is_vented_crawl(thermal_zone)
        building.vented_crawlspace = ZoneInfo.new(thermal_zone, Geometry.get_height_of_spaces(thermal_zone.spaces), UnitConversions.convert(thermal_zone.floorArea, 'm^2', 'ft^2'), Geometry.get_zone_volume(thermal_zone), Geometry.get_z_origin_for_zone(thermal_zone), nil, infil.vented_crawl_sla)
      elsif Geometry.is_unvented_crawl(thermal_zone)
        building.unvented_crawlspace = ZoneInfo.new(thermal_zone, Geometry.get_height_of_spaces(thermal_zone.spaces), UnitConversions.convert(thermal_zone.floorArea, 'm^2', 'ft^2'), Geometry.get_zone_volume(thermal_zone), Geometry.get_z_origin_for_zone(thermal_zone), nil, infil.unvented_crawl_sla)
      elsif Geometry.is_vented_attic(thermal_zone)
        building.vented_attic = ZoneInfo.new(thermal_zone, Geometry.get_height_of_spaces(thermal_zone.spaces), UnitConversions.convert(thermal_zone.floorArea, 'm^2', 'ft^2'), Geometry.get_zone_volume(thermal_zone), Geometry.get_z_origin_for_zone(thermal_zone), infil.vented_attic_const_ach, infil.vented_attic_sla)
      elsif Geometry.is_unvented_attic(thermal_zone)
        building.unvented_attic = ZoneInfo.new(thermal_zone, Geometry.get_height_of_spaces(thermal_zone.spaces), UnitConversions.convert(thermal_zone.floorArea, 'm^2', 'ft^2'), Geometry.get_zone_volume(thermal_zone), Geometry.get_z_origin_for_zone(thermal_zone), nil, infil.unvented_attic_sla)
      end
    end
    building.cfa = cfa
    building.infilvolume = infil_volume
    building.infilheight = infil_height
    building.living.volume = building.infilvolume
    building.living.height = building.infilheight
    building.nbeds = nbeds
    building.nbaths = nbaths
    building.ncfl_ag = ncfl_ag
    building.window_area = window_area

    wind_speed = process_wind_speed_correction(infil.terrain, infil.shelter_coef, min_neighbor_distance, building.height)
    process_infiltration(model, infil, wind_speed, building, weather)

    # Global sensors

    pbar_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Site Outdoor Air Barometric Pressure')
    pbar_sensor.setName('out pb s')

    wout_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Site Outdoor Air Humidity Ratio')
    wout_sensor.setName('out wt s')

    vwind_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Site Wind Speed')
    vwind_sensor.setName('site vw s')

    # Adiabatic construction for ducts

    adiabatic_mat = OpenStudio::Model::MasslessOpaqueMaterial.new(model, 'Rough', 176.1)
    adiabatic_mat.setName('Adiabatic')
    adiabatic_const = OpenStudio::Model::Construction.new(model)
    adiabatic_const.setName('AdiabaticConst')
    adiabatic_const.insertLayer(0, adiabatic_mat)

    # Common sensors

    tin_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Zone Mean Air Temperature')
    tin_sensor.setName("#{Constants.ObjectNameAirflow} tin s")
    tin_sensor.setKeyName(building.living.zone.name.to_s)

    tout_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Zone Outdoor Air Drybulb Temperature')
    tout_sensor.setName("#{Constants.ObjectNameAirflow} tt s")
    tout_sensor.setKeyName(building.living.zone.name.to_s)

    # Update model

    air_loop_objects = create_air_loop_objects(model, model.getAirLoopHVACs, mech_vent, building)
    process_infiltration_for_conditioned_zones(model, infil, wind_speed, building, weather)
    process_mech_vent(model, mech_vent, building, weather, infil)

    if mech_vent.type == HPXML::MechVentTypeCFIS
      cfis_program = create_cfis_objects(model, building, mech_vent)
    end

    nv_and_whf_program = process_nat_vent_and_whole_house_fan(model, nat_vent, whf, tin_sensor, tout_sensor, pbar_sensor, vwind_sensor, wind_speed, infil, building, weather, wout_sensor)

    duct_programs = {}
    duct_lks = {}
    duct_systems.each do |ducts, air_loop|
      process_ducts(model, ducts, building, air_loop)
      create_ducts_objects(model, building, ducts, mech_vent, tin_sensor, pbar_sensor, adiabatic_const, air_loop, duct_programs, duct_lks, air_loop_objects)
    end

    infil_program = create_infil_mech_vent_objects(model, building, infil, mech_vent, vent_fan_kitchen, vent_fan_bath, wind_speed, tin_sensor, tout_sensor, vwind_sensor, duct_lks, wout_sensor, pbar_sensor)

    create_ems_program_managers(model, infil_program, nv_and_whf_program, cfis_program, duct_programs)

    # Store info for HVAC Sizing measure
    if not building.living.ELA.nil?
      building.living.zone.additionalProperties.setFeature(Constants.SizingInfoZoneInfiltrationELA, building.living.ELA.to_f)
      building.living.zone.additionalProperties.setFeature(Constants.SizingInfoZoneInfiltrationCFM, building.living.inf_flow.to_f)
      building.living.zone.additionalProperties.setFeature(Constants.SizingInfoZoneInfiltrationACH, building.living.ACH.to_f)
    else
      building.living.zone.additionalProperties.setFeature(Constants.SizingInfoZoneInfiltrationELA, 0.0)
      building.living.zone.additionalProperties.setFeature(Constants.SizingInfoZoneInfiltrationCFM, 0.0)
      building.living.zone.additionalProperties.setFeature(Constants.SizingInfoZoneInfiltrationACH, 0.0)
    end

    # Store info for HVAC Sizing measure
    unless building.vented_crawlspace.nil?
      building.vented_crawlspace.zone.additionalProperties.setFeature(Constants.SizingInfoZoneInfiltrationCFM, building.vented_crawlspace.inf_flow.to_f)
    end
    unless building.unvented_crawlspace.nil?
      building.unvented_crawlspace.zone.additionalProperties.setFeature(Constants.SizingInfoZoneInfiltrationCFM, building.unvented_crawlspace.inf_flow.to_f)
    end
    unless building.unconditioned_basement.nil?
      building.unconditioned_basement.zone.additionalProperties.setFeature(Constants.SizingInfoZoneInfiltrationCFM, building.unconditioned_basement.inf_flow.to_f)
    end
    unless building.vented_attic.nil?
      building.vented_attic.zone.additionalProperties.setFeature(Constants.SizingInfoZoneInfiltrationCFM, building.vented_attic.inf_flow)
    end
    unless building.unvented_attic.nil?
      building.unvented_attic.zone.additionalProperties.setFeature(Constants.SizingInfoZoneInfiltrationCFM, building.unvented_attic.inf_flow)
    end
    model.getAirLoopHVACs.each do |air_loop|
      has_ducts = air_loop.additionalProperties.getFeatureAsBoolean(Constants.SizingInfoDuctExist)
      next if has_ducts.is_initialized

      air_loop.additionalProperties.setFeature(Constants.SizingInfoDuctExist, false)
    end

    terrain = { Constants.TerrainOcean => 'Ocean',      # Ocean, Bayou flat country
                Constants.TerrainPlains => 'Country',   # Flat, open country
                Constants.TerrainRural => 'Country',    # Flat, open country
                Constants.TerrainSuburban => 'Suburbs', # Rough, wooded country, suburbs
                Constants.TerrainCity => 'City' }       # Towns, city outskirts, center of large cities
    model.getSite.setTerrain(terrain[infil.terrain])

    model.getScheduleDays.each do |obj| # remove any orphaned day schedules
      next if obj.directUseCount > 0

      obj.remove
    end
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

  def self.process_wind_speed_correction(terrain, shelter_coef, min_neighbor_distance, building_height)
    wind_speed = WindSpeed.new
    wind_speed.height = 32.8 # ft (Standard weather station height)

    # Open, Unrestricted at Weather Station
    wind_speed.terrain_multiplier = 1.0 # Used for DOE-2's correlation
    wind_speed.terrain_exponent = 0.15 # Used for DOE-2's correlation
    wind_speed.ashrae_terrain_thickness = 270
    wind_speed.ashrae_terrain_exponent = 0.14

    if terrain == Constants.TerrainOcean
      wind_speed.site_terrain_multiplier = 1.30 # Used for DOE-2's correlation
      wind_speed.site_terrain_exponent = 0.10 # Used for DOE-2's correlation
      wind_speed.ashrae_site_terrain_thickness = 210 # Ocean, Bayou flat country
      wind_speed.ashrae_site_terrain_exponent = 0.10 # Ocean, Bayou flat country
    elsif terrain == Constants.TerrainPlains
      wind_speed.site_terrain_multiplier = 1.00 # Used for DOE-2's correlation
      wind_speed.site_terrain_exponent = 0.15 # Used for DOE-2's correlation
      wind_speed.ashrae_site_terrain_thickness = 270 # Flat, open country
      wind_speed.ashrae_site_terrain_exponent = 0.14 # Flat, open country
    elsif terrain == Constants.TerrainRural
      wind_speed.site_terrain_multiplier = 0.85 # Used for DOE-2's correlation
      wind_speed.site_terrain_exponent = 0.20 # Used for DOE-2's correlation
      wind_speed.ashrae_site_terrain_thickness = 270 # Flat, open country
      wind_speed.ashrae_site_terrain_exponent = 0.14 # Flat, open country
    elsif terrain == Constants.TerrainSuburban
      wind_speed.site_terrain_multiplier = 0.67 # Used for DOE-2's correlation
      wind_speed.site_terrain_exponent = 0.25 # Used for DOE-2's correlation
      wind_speed.ashrae_site_terrain_thickness = 370 # Rough, wooded country, suburbs
      wind_speed.ashrae_site_terrain_exponent = 0.22 # Rough, wooded country, suburbs
    elsif terrain == Constants.TerrainCity
      wind_speed.site_terrain_multiplier = 0.47 # Used for DOE-2's correlation
      wind_speed.site_terrain_exponent = 0.35 # Used for DOE-2's correlation
      wind_speed.ashrae_site_terrain_thickness = 460 # Towns, city outskirts, center of large cities
      wind_speed.ashrae_site_terrain_exponent = 0.33 # Towns, city outskirts, center of large cities
    end

    # Local Shielding
    if shelter_coef == Constants.Auto
      if min_neighbor_distance.nil?
        # Typical shelter for isolated rural house
        wind_speed.S_wo = 0.90
      elsif min_neighbor_distance > building_height
        # Typical shelter caused by other building across the street
        wind_speed.S_wo = 0.70
      else
        # Typical shelter for urban buildings where sheltering obstacles
        # are less than one building height away.
        # Recommended by C.Christensen.
        wind_speed.S_wo = 0.50
      end
    else
      wind_speed.S_wo = Float(shelter_coef)
    end

    # S-G Shielding Coefficients are roughly 1/3 of AIM2 Shelter Coefficients
    wind_speed.shielding_coef = wind_speed.S_wo / 3.0

    return wind_speed
  end

  def self.process_infiltration(model, infil, wind_speed, building, weather)
    spaces = []
    spaces << building.garage if not building.garage.nil?
    spaces << building.unconditioned_basement if not building.unconditioned_basement.nil?
    spaces << building.vented_crawlspace if not building.vented_crawlspace.nil?
    spaces << building.unvented_crawlspace if not building.unvented_crawlspace.nil?
    spaces << building.vented_attic if not building.vented_attic.nil?
    spaces << building.unvented_attic if not building.unvented_attic.nil?

    unless building.garage.nil?
      building.garage.inf_method = @infMethodELA
      building.garage.hor_lk_frac = 0.4
      building.garage.neutral_level = 0.5
      building.garage.SLA = Airflow.get_infiltration_SLA_from_ACH50(infil.garage_ach50, 0.65, building.garage.area, building.garage.volume)
      building.garage.ACH = Airflow.get_infiltration_ACH_from_SLA(building.garage.SLA, 8.202, weather)
      building.garage.inf_flow = building.garage.ACH / UnitConversions.convert(1.0, 'hr', 'min') * building.garage.volume # cfm
    end

    unless building.unconditioned_basement.nil?
      building.unconditioned_basement.inf_method = @infMethodConstantCFM # Used for constant ACH
      building.unconditioned_basement.inf_flow = building.unconditioned_basement.ACH / UnitConversions.convert(1.0, 'hr', 'min') * building.unconditioned_basement.volume
    end

    unless building.vented_crawlspace.nil?
      building.vented_crawlspace.inf_method = @infMethodConstantCFM
      building.vented_crawlspace.ACH = Airflow.get_infiltration_ACH_from_SLA(building.vented_crawlspace.SLA, 8.202, weather)
      building.vented_crawlspace.inf_flow = building.vented_crawlspace.ACH / UnitConversions.convert(1.0, 'hr', 'min') * building.vented_crawlspace.volume
    end

    unless building.unvented_crawlspace.nil?
      building.unvented_crawlspace.inf_method = @infMethodConstantCFM
      building.unvented_crawlspace.ACH = Airflow.get_infiltration_ACH_from_SLA(building.unvented_crawlspace.SLA, 8.202, weather)
      building.unvented_crawlspace.inf_flow = building.unvented_crawlspace.ACH / UnitConversions.convert(1.0, 'hr', 'min') * building.unvented_crawlspace.volume
    end

    unless building.vented_attic.nil?
      if not building.vented_attic.SLA.nil?
        building.vented_attic.inf_method = @infMethodELA
        building.vented_attic.hor_lk_frac = 1.0
        building.vented_attic.neutral_level = 0.5
        building.vented_attic.ACH = Airflow.get_infiltration_ACH_from_SLA(building.vented_attic.SLA, 8.202, weather)
      elsif not building.vented_attic.ACH.nil?
        building.vented_attic.inf_method = @infMethodConstantCFM
      end
      building.vented_attic.inf_flow = building.vented_attic.ACH / UnitConversions.convert(1.0, 'hr', 'min') * building.vented_attic.volume
    end

    unless building.unvented_attic.nil?
      if not building.unvented_attic.SLA.nil?
        building.unvented_attic.inf_method = @infMethodELA
        building.unvented_attic.hor_lk_frac = 1.0
        building.unvented_attic.neutral_level = 0.5 # DOE-2 Default
        building.unvented_attic.ACH = Airflow.get_infiltration_ACH_from_SLA(building.unvented_attic.SLA, 8.202, weather)
      elsif not building.unvented_attic.ACH.nil?
        building.unvented_attic.inf_method = @infMethodConstantCFM
      end
      building.unvented_attic.inf_flow = building.unvented_attic.ACH / UnitConversions.convert(1.0, 'hr', 'min') * building.unvented_attic.volume
    end

    process_infiltration_for_spaces(model, spaces, wind_speed)
  end

  def self.create_air_loop_objects(model, air_loops, mech_vent, building)
    # Obtain data across all air loops (needed for ducts, CFIS w/ separate heating and cooling air loops)
    air_loop_objects = {}
    air_loops.each_with_index do |air_loop, air_loop_index|
      next unless building.living.zone.airLoopHVACs.include? air_loop # next if airloop doesn't serve this

      system = HVAC.get_unitary_system_from_air_loop_hvac(air_loop)
      if system.nil? # Evap cooler system stored information in airloopHVAC
        system = air_loop
      end
      next if system.nil?

      # Get the supply fan
      supply_fan = nil
      if air_loop.to_AirLoopHVAC.is_initialized
        supply_fan = system.supplyFan.get
      end

      # Supply fan runtime fraction
      fan_rtf_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "#{air_loop.name} Fan RTF".gsub(' ', '_'))
      if supply_fan.to_FanOnOff.is_initialized
        fan_rtf_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Fan Runtime Fraction')
        fan_rtf_sensor.setName("#{fan_rtf_var.name} s")
        fan_rtf_sensor.setKeyName(supply_fan.name.to_s)
      elsif supply_fan.to_FanVariableVolume.is_initialized
        fan_mfr_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Fan Air Mass Flow Rate')
        fan_mfr_sensor.setName("#{supply_fan.name} air MFR")
        fan_mfr_sensor.setKeyName("#{supply_fan.name}")
        fan_rtf_sensor = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "#{fan_rtf_var.name}_s")
      else
        fail "Unexpected fan: #{supply_fan.name}"
      end

      # Supply fan maximum mass flow rate
      fan_mfr_max_var = OpenStudio::Model::EnergyManagementSystemInternalVariable.new(model, 'Fan Maximum Mass Flow Rate')
      fan_mfr_max_var.setName("#{air_loop.name} max sup fan mfr")
      fan_mfr_max_var.setInternalDataIndexKeyName(supply_fan.name.to_s)

      air_loop_objects[air_loop] = { fan_rtf_var: fan_rtf_var,
                                     fan_rtf_sensor: fan_rtf_sensor,
                                     fan_mfr_max_var: fan_mfr_max_var,
                                     fan_mfr_sensor: fan_mfr_sensor }

      if (mech_vent.type == HPXML::MechVentTypeCFIS) && (air_loop == mech_vent.cfis_air_loop)
        mech_vent.cfis_fan_rtf_sensor = fan_rtf_sensor.name
        mech_vent.cfis_fan_mfr_max_var = fan_mfr_max_var.name
      end
    end

    return air_loop_objects
  end

  def self.process_infiltration_for_conditioned_zones(model, infil, wind_speed, building, weather)
    spaces = []
    spaces << building.living

    outside_air_density = UnitConversions.convert(weather.header.LocalPressure, 'atm', 'Btu/ft^3') / (Gas.Air.r * (weather.data.AnnualAvgDrybulb + 460.0))
    inf_conv_factor = 776.25 # [ft/min]/[inH2O^(1/2)*ft^(3/2)/lbm^(1/2)]
    delta_pref = 0.016 # inH2O

    # Living Space Infiltration
    if not infil.living_ach50.nil?
      building.living.inf_method = @infMethodAIM2

      # Based on "Field Validation of Algebraic Equations for Stack and
      # Wind Driven Air Infiltration Calculations" by Walker and Wilson (1998)

      # Pressure Exponent
      n_i = 0.65

      # Calculate SLA
      building.living.SLA = Airflow.get_infiltration_SLA_from_ACH50(infil.living_ach50, n_i, building.cfa, building.infilvolume)

      # Effective Leakage Area (ft^2)
      a_o = building.living.SLA * building.cfa

      # Flow Coefficient (cfm/inH2O^n) (based on ASHRAE HoF)
      c_i = a_o * (2.0 / outside_air_density)**0.5 * delta_pref**(0.5 - n_i) * inf_conv_factor

      if infil.has_flue_chimney
        y_i = 0.2 # Fraction of leakage through the flue; 0.2 is a "typical" value according to THE ALBERTA AIR INFIL1RATION MODEL, Walker and Wilson, 1990
        flue_height = building.height + 2.0 # ft
        s_wflue = 1.0 # Flue Shelter Coefficient
      else
        y_i = 0.0 # Fraction of leakage through the flu
        flue_height = 0.0 # ft
        s_wflue = 0.0 # Flue Shelter Coefficient
      end

      vented_crawl = false
      if not building.vented_crawlspace.nil?
        vented_crawl = true
      end

      # Leakage distributions per Iain Walker (LBL) recommendations
      if vented_crawl
        # 15% ceiling, 35% walls, 50% floor leakage distribution for vented crawl
        leakkage_ceiling = 0.15
        leakage_walls = 0.35
        leakage_floor = 0.50
      else
        # 25% ceiling, 50% walls, 25% floor leakage distribution for slab/basement/unvented crawl
        leakkage_ceiling = 0.25
        leakage_walls = 0.50
        leakage_floor = 0.25
      end
      if leakkage_ceiling + leakage_walls + leakage_floor != 1
        fail "Invalid air leakage distribution specified (#{leakkage_ceiling}, #{leakage_walls}, #{leakage_floor}); does not add up to 1."
      end

      r_i = (leakkage_ceiling + leakage_floor)
      x_i = (leakkage_ceiling - leakage_floor)
      r_i *= (1 - y_i)
      x_i *= (1 - y_i)

      building.living.hor_lk_frac = r_i
      z_f = flue_height / (building.infilheight + building.living.coord_z)

      # Calculate Stack Coefficient
      m_o = (x_i + (2.0 * n_i + 1.0) * y_i)**2.0 / (2 - r_i)

      if m_o <=  1.0
        m_i = m_o # eq. 10
      else
        m_i = 1.0 # eq. 11
      end

      if infil.has_flue_chimney
        # Eq. 13
        x_c = r_i + (2.0 * (1.0 - r_i - y_i)) / (n_i + 1.0) - 2.0 * y_i * (z_f - 1.0)**n_i
        # Additive flue function, Eq. 12
        f_i = n_i * y_i * (z_f - 1.0)**((3.0 * n_i - 1.0) / 3.0) * (1.0 - (3.0 * (x_c - x_i)**2.0 * r_i**(1 - n_i)) / (2.0 * (z_f + 1.0)))
      else
        # Critical value of ceiling-floor leakage difference where the
        # neutral level is located at the ceiling (eq. 13)
        x_c = r_i + (2.0 * (1.0 - r_i - y_i)) / (n_i + 1.0)
        # Additive flue function (eq. 12)
        f_i = 0.0
      end

      f_s = ((1.0 + n_i * r_i) / (n_i + 1.0)) * (0.5 - 0.5 * m_i**1.2)**(n_i + 1.0) + f_i

      stack_coef = f_s * (UnitConversions.convert(outside_air_density * Constants.g * building.infilheight, 'lbm/(ft*s^2)', 'inH2O') / (Constants.AssumedInsideTemp + 460.0))**n_i # inH2O^n/R^n

      # Calculate wind coefficient
      if vented_crawl

        if x_i > 1.0 - 2.0 * y_i
          # Critical floor to ceiling difference above which f_w does not change (eq. 25)
          x_i = 1.0 - 2.0 * y_i
        end

        # Redefined R for wind calculations for houses with crawlspaces (eq. 21)
        r_x = 1.0 - r_i * (n_i / 2.0 + 0.2)
        # Redefined Y for wind calculations for houses with crawlspaces (eq. 22)
        y_x = 1.0 - y_i / 4.0
        # Used to calculate X_x (eq.24)
        x_s = (1.0 - r_i) / 5.0 - 1.5 * y_i
        # Redefined X for wind calculations for houses with crawlspaces (eq. 23)
        x_x = 1.0 - (((x_i - x_s) / (2.0 - r_i))**2.0)**0.75
        # Wind factor (eq. 20)
        f_w = 0.19 * (2.0 - n_i) * x_x * r_x * y_x

      else

        j_i = (x_i + r_i + 2.0 * y_i) / 2.0
        f_w = 0.19 * (2.0 - n_i) * (1.0 - ((x_i + r_i) / 2.0)**(1.5 - y_i)) - y_i / 4.0 * (j_i - 2.0 * y_i * j_i**4.0)

      end

      wind_coef = f_w * UnitConversions.convert(outside_air_density / 2.0, 'lbm/ft^3', 'inH2O/mph^2')**n_i # inH2O^n/mph^2n

      building.living.ACH = Airflow.get_infiltration_ACH_from_SLA(building.living.SLA, building.infilheight, weather)

      # Convert living space ACH to cfm:
      building.living.inf_flow = building.living.ACH / UnitConversions.convert(1.0, 'hr', 'min') * building.infilvolume # cfm

    elsif not infil.living_constant_ach.nil?

      building.living.inf_method = @infMethodConstantCFM

      building.living.ACH = infil.living_constant_ach
      building.living.inf_flow = building.living.ACH / UnitConversions.convert(1.0, 'hr', 'min') * building.infilvolume # cfm

    end

    process_infiltration_for_spaces(model, spaces, wind_speed)

    infil.a_o = a_o
    infil.c_i = c_i
    infil.n_i = n_i
    infil.stack_coef = stack_coef
    infil.wind_coef = wind_coef
    infil.y_i = y_i
    infil.s_wflue = s_wflue
  end

  def self.process_infiltration_for_spaces(model, spaces, wind_speed)
    spaces.each do |space|
      space.f_t_SG = wind_speed.site_terrain_multiplier * ((space.height + space.coord_z) / 32.8)**wind_speed.site_terrain_exponent / (wind_speed.terrain_multiplier * (wind_speed.height / 32.8)**wind_speed.terrain_exponent)

      if space.inf_method == @infMethodELA
        space.f_s_SG = 2.0 / 3.0 * (1 + space.hor_lk_frac / 2.0) * (2.0 * space.neutral_level * (1.0 - space.neutral_level))**0.5 / (space.neutral_level**0.5 + (1.0 - space.neutral_level)**0.5)
        space.f_w_SG = wind_speed.shielding_coef * (1.0 - space.hor_lk_frac)**(1.0 / 3.0) * space.f_t_SG
        space.C_s_SG = space.f_s_SG**2.0 * Constants.g * space.height / (Constants.AssumedInsideTemp + 460.0)
        space.C_w_SG = space.f_w_SG**2.0
        space.ELA = space.SLA * space.area # ft^2
      elsif space.inf_method == @infMethodAIM2
        space.ELA = space.SLA * space.area # ft^2
      end

      space.zone.spaces.each do |s|
        next if Geometry.is_living(s)

        obj_name = "#{Constants.ObjectNameInfiltration}|#{s.name}"
        if (space.inf_method == @infMethodConstantCFM) && (space.ACH.to_f > 0)
          flow_rate = OpenStudio::Model::SpaceInfiltrationDesignFlowRate.new(model)
          flow_rate.setName(obj_name)
          flow_rate.setSchedule(model.alwaysOnDiscreteSchedule)
          flow_rate.setAirChangesperHour(space.ACH)
          flow_rate.setSpace(s)
          flow_rate.setConstantTermCoefficient(1)
          flow_rate.setTemperatureTermCoefficient(0)
          flow_rate.setVelocityTermCoefficient(0)
          flow_rate.setVelocitySquaredTermCoefficient(0)
        elsif (space.inf_method == @infMethodELA) && (space.ELA.to_f > 0)
          leakage_area = OpenStudio::Model::SpaceInfiltrationEffectiveLeakageArea.new(model)
          leakage_area.setName(obj_name)
          leakage_area.setSchedule(model.alwaysOnDiscreteSchedule)
          leakage_area.setEffectiveAirLeakageArea(UnitConversions.convert(space.ELA, 'ft^2', 'cm^2'))
          leakage_area.setStackCoefficient(UnitConversions.convert(space.C_s_SG, 'ft^2/(s^2*R)', 'L^2/(s^2*cm^4*K)'))
          leakage_area.setWindCoefficient(space.C_w_SG * 0.01)
          leakage_area.setSpace(s)
        elsif space.inf_method == @infMethodAIM2
          # nop
        end
      end
    end
  end

  def self.process_mech_vent(model, mech_vent, building, weather, infil)
    if mech_vent.type == HPXML::MechVentTypeCFIS
      if not HVAC.has_ducted_equipment(model, mech_vent.cfis_air_loop)
        fail 'A CFIS ventilation system has been specified but the building does not have central, forced air equipment.'
      end
    end

    # Fraction of fan heat that goes to the space
    if [HPXML::MechVentTypeExhaust].include? mech_vent.type
      frac_fan_heat = 0.0 # Fan heat does not enter space
    elsif [HPXML::MechVentTypeSupply, HPXML::MechVentTypeCFIS].include? mech_vent.type
      frac_fan_heat = 1.0 # Fan heat does enter space
    elsif [HPXML::MechVentTypeBalanced, HPXML::MechVentTypeERV, HPXML::MechVentTypeHRV].include? mech_vent.type
      frac_fan_heat = 0.5 # Assumes supply fan heat enters space
    else
      frac_fan_heat = 0.0
    end

    # Get the clothes washer so we can use the day shift for the clothes dryer
    if mech_vent.dryer_exhaust > 0
      cw_day_shift = 0.0
      model.getElectricEquipments.each do |ee|
        next if ee.name.to_s != Constants.ObjectNameClothesWasher

        cw_day_shift = ee.additionalProperties.getFeatureAsDouble(Constants.ClothesWasherDayShift).get
        break
      end
      dryer_exhaust_day_shift = cw_day_shift + 1.0 / 24.0
    end

    # Search for clothes dryer
    has_dryer = false
    (model.getElectricEquipments + model.getOtherEquipments).each do |equip|
      next unless equip.name.to_s == Constants.ObjectNameClothesDryer

      has_dryer = true
      break
    end

    if (not has_dryer) && (mech_vent.dryer_exhaust > 0)
      @runner.registerWarning('No clothes dryer object was found but the clothes dryer exhaust specified is non-zero. Overriding clothes dryer exhaust to be zero.')
    end

    #--- Calculate HRV/ERV effectiveness values. Calculated here for use in sizing routines.

    apparent_sensible_effectiveness = 0.0
    sensible_effectiveness = 0.0
    latent_effectiveness = 0.0

    if [HPXML::MechVentTypeERV, HPXML::MechVentTypeHRV].include?(mech_vent.type) && (mech_vent.cfm > 0)
      # Must assume an operating condition (HVI seems to use CSA 439)
      t_sup_in = 0.0
      w_sup_in = 0.0028
      t_exh_in = 22.0
      w_exh_in = 0.0065
      cp_a = 1006.0
      p_fan = mech_vent.fan_power_w # Watts

      m_fan = UnitConversions.convert(mech_vent.cfm, 'cfm', 'm^3/s') * 16.02 * Psychrometrics.rhoD_fT_w_P(UnitConversions.convert(t_sup_in, 'C', 'F'), w_sup_in, 14.7) # kg/s

      if mech_vent.sensible_efficiency > 0
        # The following is derived from CSA 439, Clause 9.3.3.1, Eq. 12:
        #    E_SHR = (m_sup,fan * Cp * (Tsup,out - Tsup,in) - P_sup,fan) / (m_exh,fan * Cp * (Texh,in - Tsup,in) + P_exh,fan)
        t_sup_out = t_sup_in + (mech_vent.sensible_efficiency * (m_fan * cp_a * (t_exh_in - t_sup_in) + p_fan) + p_fan) / (m_fan * cp_a)

        # Calculate the apparent sensible effectiveness
        apparent_sensible_effectiveness = (t_sup_out - t_sup_in) / (t_exh_in - t_sup_in)

      else
        # The following is derived from (taken from CSA 439, Clause 9.2.1, Eq. 7):
        t_sup_out = t_sup_in + (mech_vent.sensible_efficiency_adjusted * (t_exh_in - t_sup_in))

        apparent_sensible_effectiveness = mech_vent.sensible_efficiency_adjusted

      end

      # Calculate the supply temperature before the fan
      t_sup_out_gross = t_sup_out - p_fan / (m_fan * cp_a)

      # Sensible effectiveness of the HX only
      sensible_effectiveness = (t_sup_out_gross - t_sup_in) / (t_exh_in - t_sup_in)

      if (sensible_effectiveness < 0.0) || (sensible_effectiveness > 1.0)
        fail "The calculated ERV/HRV sensible effectiveness is #{sensible_effectiveness} but should be between 0 and 1. Please revise ERV/HRV efficiency values."
      end

      # Use summer test condition to determine the latent effectiveness since TRE is generally specified under the summer condition
      if ((mech_vent.total_efficiency > 0) || (mech_vent.total_efficiency_adjusted > 0))

        t_sup_in = 35.0
        w_sup_in = 0.0178
        t_exh_in = 24.0
        w_exh_in = 0.0092

        m_fan = UnitConversions.convert(mech_vent.cfm, 'cfm', 'm^3/s') * UnitConversions.convert(Psychrometrics.rhoD_fT_w_P(UnitConversions.convert(t_sup_in, 'C', 'F'), w_sup_in, 14.7), 'lbm/ft^3', 'kg/m^3') # kg/s

        t_sup_out_gross = t_sup_in - sensible_effectiveness * (t_sup_in - t_exh_in)
        t_sup_out = t_sup_out_gross + p_fan / (m_fan * cp_a)

        h_sup_in = Psychrometrics.h_fT_w_SI(t_sup_in, w_sup_in)
        h_exh_in = Psychrometrics.h_fT_w_SI(t_exh_in, w_exh_in)

        if mech_vent.total_efficiency > 0
          # The following is derived from CSA 439, Clause 9.3.3.2, Eq. 13:
          #    E_THR = (m_sup,fan * Cp * (h_sup,out - h_sup,in) - P_sup,fan) / (m_exh,fan * Cp * (h_exh,in - h_sup,in) + P_exh,fan)
          h_sup_out = h_sup_in - (mech_vent.total_efficiency * (m_fan * (h_sup_in - h_exh_in) + p_fan) + p_fan) / m_fan
        else
          # The following is derived from (taken from CSA 439, Clause 9.2.1, Eq. 7):
          h_sup_out = h_sup_in - (mech_vent.total_efficiency_adjusted * (h_sup_in - h_exh_in))
        end

        w_sup_out = Psychrometrics.w_fT_h_SI(t_sup_out, h_sup_out)
        latent_effectiveness = [0.0, (w_sup_out - w_sup_in) / (w_exh_in - w_sup_in)].max

        if (latent_effectiveness < 0.0) || (latent_effectiveness > 1.0)
          fail "The calculated ERV/HRV latent effectiveness is #{latent_effectiveness} but should be between 0 and 1. Please revise ERV/HRV efficiency values."
        end

      else
        latent_effectiveness = 0.0
      end
    else
      if mech_vent.total_efficiency > 0
        apparent_sensible_effectiveness = mech_vent.total_efficiency
        sensible_effectiveness = mech_vent.total_efficiency
        latent_effectiveness = mech_vent.total_efficiency
      end
    end

    # Store info for HVAC Sizing measure
    model.getBuilding.additionalProperties.setFeature(Constants.SizingInfoMechVentType, mech_vent.type.to_s)
    model.getBuilding.additionalProperties.setFeature(Constants.SizingInfoMechVentTotalEfficiency, mech_vent.total_efficiency.to_f)
    model.getBuilding.additionalProperties.setFeature(Constants.SizingInfoMechVentLatentEffectiveness, latent_effectiveness.to_f)
    model.getBuilding.additionalProperties.setFeature(Constants.SizingInfoMechVentApparentSensibleEffectiveness, apparent_sensible_effectiveness.to_f)
    model.getBuilding.additionalProperties.setFeature(Constants.SizingInfoMechVentWholeHouseRate, mech_vent.cfm.to_f)

    mech_vent.frac_fan_heat = frac_fan_heat
    mech_vent.latent_effectiveness = latent_effectiveness
    mech_vent.sensible_effectiveness = sensible_effectiveness
    mech_vent.dryer_exhaust_day_shift = dryer_exhaust_day_shift
    mech_vent.has_dryer = has_dryer
  end

  def self.process_ducts(model, ducts, building, air_loop)
    # Validate Inputs
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

    has_ducted_hvac = HVAC.has_ducted_equipment(model, air_loop)
    if (ducts.size > 0) && (not has_ducted_hvac)
      @runner.registerWarning('No ducted HVAC equipment was found but ducts were specified. Overriding duct specification.')
      ducts.clear
    elsif (ducts.size == 0) && has_ducted_hvac
      @runner.registerWarning('Ducted HVAC equipment was found but no ducts were specified. Proceeding without ducts.')
    end

    ducts.each do |duct|
      duct.rvalue = get_duct_insulation_rvalue(duct.rvalue, duct.side) # Convert from nominal to actual R-value
      if not duct.loc_schedule.nil?
        # Pass MF space temperature schedule name
        duct.location_handle = duct.loc_schedule.name.to_s
      elsif not duct.loc_space.nil?
        duct.zone = duct.loc_space.thermalZone.get
        duct.location_handle = duct.zone.handle.to_s
      else # Outside
        duct.zone = nil
        duct.location_handle = HPXML::LocationOutside
      end
    end

    if (ducts.size > 0) && building.living.zone.airLoopHVACs.include?(air_loop)
      # Store info for HVAC Sizing measure
      air_loop.additionalProperties.setFeature(Constants.SizingInfoDuctExist, true)
      air_loop.additionalProperties.setFeature(Constants.SizingInfoDuctSides, ducts.map { |duct| duct.side }.join(','))
      air_loop.additionalProperties.setFeature(Constants.SizingInfoDuctLocationHandles, ducts.map { |duct| duct.location_handle.to_s }.join(','))
      air_loop.additionalProperties.setFeature(Constants.SizingInfoDuctLeakageFracs, ducts.map { |duct| duct.leakage_frac.to_f }.join(','))
      air_loop.additionalProperties.setFeature(Constants.SizingInfoDuctLeakageCFM25s, ducts.map { |duct| duct.leakage_cfm25.to_f }.join(','))
      air_loop.additionalProperties.setFeature(Constants.SizingInfoDuctAreas, ducts.map { |duct| duct.area.to_f }.join(','))
      air_loop.additionalProperties.setFeature(Constants.SizingInfoDuctRvalues, ducts.map { |duct| duct.rvalue.to_f }.join(','))
    end
  end

  def self.process_nat_vent_and_whole_house_fan(model, nat_vent, whf, tin_sensor, tout_sensor, pbar_sensor, vwind_sensor, wind_speed, infil, building, weather, wout_sensor)
    # Availability Schedule
    aval_schs = {}
    { Constants.ObjectNameNaturalVentilation => nat_vent.nv_num_days_per_week,
      Constants.ObjectNameWholeHouseFan => whf.whf_num_days_per_week }.each do |obj_name, num_days_per_week|
      aval_schs[obj_name] = OpenStudio::Model::ScheduleRuleset.new(model)
      aval_schs[obj_name].setName("#{obj_name} avail schedule")
      Schedule.set_schedule_type_limits(model, aval_schs[obj_name], Constants.ScheduleTypeLimitsOnOff)
      on_rule = OpenStudio::Model::ScheduleRule.new(aval_schs[obj_name])
      on_rule.setName("#{obj_name} avail schedule rule")
      on_rule_day = on_rule.daySchedule
      on_rule_day.setName("#{obj_name} avail schedule day")
      on_rule_day.addValue(OpenStudio::Time.new(0, 24, 0, 0), 1)
      if num_days_per_week >= 1
        on_rule.setApplyMonday(true)
      end
      if num_days_per_week >= 2
        on_rule.setApplyWednesday(true)
      end
      if num_days_per_week >= 3
        on_rule.setApplyFriday(true)
      end
      if num_days_per_week >= 4
        on_rule.setApplySaturday(true)
      end
      if num_days_per_week >= 5
        on_rule.setApplyTuesday(true)
      end
      if num_days_per_week >= 6
        on_rule.setApplyThursday(true)
      end
      if num_days_per_week >= 7
        on_rule.setApplySunday(true)
      end
      on_rule.setStartDate(OpenStudio::Date::fromDayOfYear(1))
      on_rule.setEndDate(OpenStudio::Date::fromDayOfYear(365))
    end

    # Setpoint schedule (average of heating/cooling setpoints to minimize incurring additional heating energy)

    nv_weekday_setpoints = [[nil] * 24] * 12
    nv_weekend_setpoints = [[nil] * 24] * 12
    for month in 1..12
      for hr in 1..24
        nv_weekday_setpoints[month - 1][hr - 1] = UnitConversions.convert((nat_vent.htg_weekday_setpoints[month - 1][hr - 1] + nat_vent.clg_weekday_setpoints[month - 1][hr - 1]) / 2.0, 'F', 'C')
        nv_weekend_setpoints[month - 1][hr - 1] = UnitConversions.convert((nat_vent.htg_weekend_setpoints[month - 1][hr - 1] + nat_vent.clg_weekend_setpoints[month - 1][hr - 1]) / 2.0, 'F', 'C')
      end
    end
    temp_sch = HourlyByMonthSchedule.new(model, Constants.ObjectNameNaturalVentilation + ' temp schedule', nv_weekday_setpoints, nv_weekend_setpoints, false, true, Constants.ScheduleTypeLimitsTemperature)

    # Sensors
    nv_sp_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Schedule Value')
    nv_sp_sensor.setName('airflow sp s')
    nv_sp_sensor.setKeyName(temp_sch.schedule.name.to_s)

    nv_avail_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Schedule Value')
    nv_avail_sensor.setName("#{Constants.ObjectNameNaturalVentilation} nva s")
    nv_avail_sensor.setKeyName(aval_schs[Constants.ObjectNameNaturalVentilation].name.to_s)

    whf_avail_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Schedule Value')
    whf_avail_sensor.setName("#{Constants.ObjectNameWholeHouseFan} nva s")
    whf_avail_sensor.setKeyName(aval_schs[Constants.ObjectNameWholeHouseFan].name.to_s)

    # Actuators
    living_space = building.living.zone.spaces[0]

    nv_flow = OpenStudio::Model::SpaceInfiltrationDesignFlowRate.new(model)
    nv_flow.setName(Constants.ObjectNameNaturalVentilation + ' flow')
    nv_flow.setSchedule(model.alwaysOnDiscreteSchedule)
    nv_flow.setSpace(living_space)
    nv_flow_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(nv_flow, 'Zone Infiltration', 'Air Exchange Flow Rate')
    nv_flow_actuator.setName("#{nv_flow.name} act")

    whf_flow = OpenStudio::Model::SpaceInfiltrationDesignFlowRate.new(model)
    whf_flow.setName(Constants.ObjectNameWholeHouseFan + ' flow')
    whf_flow.setSchedule(model.alwaysOnDiscreteSchedule)
    whf_flow.setSpace(living_space)
    whf_flow_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(whf_flow, 'Zone Infiltration', 'Air Exchange Flow Rate')
    whf_flow_actuator.setName("#{whf_flow.name} act")

    # Assume located in attic floor if attic zone exists; otherwise assume it's through roof/wall.
    whf_zone = nil
    if not building.vented_attic.nil?
      whf_zone = building.vented_attic.zone
    elsif not building.unvented_attic.nil?
      whf_zone = building.unvented_attic.zone
    end
    if not whf_zone.nil?
      # Air from living to WHF zone (attic)
      zone_mixing = OpenStudio::Model::ZoneMixing.new(whf_zone)
      zone_mixing.setName("#{Constants.ObjectNameWholeHouseFan} mix")
      zone_mixing.setSourceZone(building.living.zone)
      liv_to_zone_flow_rate_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(zone_mixing, 'ZoneMixing', 'Air Exchange Flow Rate')
      liv_to_zone_flow_rate_actuator.setName("#{zone_mixing.name} act")
    end

    # Electric Equipment (for whole house fan electricity consumption)

    whf_equip_def = OpenStudio::Model::ElectricEquipmentDefinition.new(model)
    whf_equip_def.setName(Constants.ObjectNameWholeHouseFan)
    whf_equip = OpenStudio::Model::ElectricEquipment.new(whf_equip_def)
    whf_equip.setName(Constants.ObjectNameWholeHouseFan)
    whf_equip.setSpace(living_space)
    whf_equip_def.setFractionRadiant(0)
    whf_equip_def.setFractionLatent(0)
    whf_equip_def.setFractionLost(1)
    whf_equip.setSchedule(model.alwaysOnDiscreteSchedule)
    whf_equip.setEndUseSubcategory(Constants.ObjectNameWholeHouseFan)
    whf_elec_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(whf_equip, 'ElectricEquipment', 'Electric Power Level')
    whf_elec_actuator.setName("#{whf_equip.name} act")

    area = 0.6 * building.window_area * nat_vent.nv_frac_window_area_open # ft^2, For Sherman-Grimsrud, this is 0.6*(open window area)
    max_rate = 20.0 # Air Changes per hour
    max_flow_rate = max_rate * building.infilvolume / UnitConversions.convert(1.0, 'hr', 'min')
    neutral_level = 0.5
    hor_vent_frac = 0.0
    f_s_nv = 2.0 / 3.0 * (1.0 + hor_vent_frac / 2.0) * (2.0 * neutral_level * (1 - neutral_level))**0.5 / (neutral_level**0.5 + (1 - neutral_level)**0.5)
    f_w_nv = wind_speed.shielding_coef * (1 - hor_vent_frac)**(1.0 / 3.0) * building.living.f_t_SG
    c_s = f_s_nv**2.0 * Constants.g * building.infilheight / (Constants.AssumedInsideTemp + 460.0)
    c_w = f_w_nv**2.0

    # Program
    nv_and_whf_program = OpenStudio::Model::EnergyManagementSystemProgram.new(model)
    nv_and_whf_program.setName(Constants.ObjectNameNaturalVentilation + ' program')
    nv_and_whf_program.addLine("Set Tin = #{tin_sensor.name}")
    nv_and_whf_program.addLine("Set Tout = #{tout_sensor.name}")
    nv_and_whf_program.addLine("Set Wout = #{wout_sensor.name}")
    nv_and_whf_program.addLine("Set Pbar = #{pbar_sensor.name}")
    nv_and_whf_program.addLine('Set Phiout = (@RhFnTdbWPb Tout Wout Pbar)')
    nv_and_whf_program.addLine("Set MaxHR = #{nat_vent.max_oa_hr}")
    nv_and_whf_program.addLine("Set MaxRH = #{nat_vent.max_oa_rh}")
    nv_and_whf_program.addLine("Set Tnvsp = #{nv_sp_sensor.name}")
    nv_and_whf_program.addLine("Set NVavail = #{nv_avail_sensor.name}")
    nv_and_whf_program.addLine("Set WHFavail = #{whf_avail_sensor.name}")
    nv_and_whf_program.addLine("Set ClgSsnAvail = #{nat_vent.clg_ssn_sensor.name}")
    nv_and_whf_program.addLine('If (Wout < MaxHR) && (Phiout < MaxRH) && (Tin > Tout) && (Tin > Tnvsp) && (ClgSsnAvail > 0)')
    nv_and_whf_program.addLine("  Set WHF_Flow = #{UnitConversions.convert(whf.cfm, 'cfm', 'm^3/s')}")
    nv_and_whf_program.addLine('  Set Adj = (Tin-Tnvsp)/(Tin-Tout)')
    nv_and_whf_program.addLine('  Set Adj = (@Min Adj 1)')
    nv_and_whf_program.addLine('  Set Adj = (@Max Adj 0)')
    nv_and_whf_program.addLine('  If (WHFavail > 0) && (WHF_Flow > 0)') # If available, prioritize whole house fan
    nv_and_whf_program.addLine("    Set #{nv_flow_actuator.name} = 0")
    nv_and_whf_program.addLine("    Set #{whf_flow_actuator.name} = WHF_Flow*Adj")
    nv_and_whf_program.addLine("    Set #{liv_to_zone_flow_rate_actuator.name} = WHF_Flow*Adj") unless whf_zone.nil?
    nv_and_whf_program.addLine("    Set #{whf_elec_actuator.name} = #{whf.fan_power_w}*Adj")
    nv_and_whf_program.addLine('  ElseIf (NVavail > 0)') # Natural ventilation
    nv_and_whf_program.addLine("    Set NVArea = #{UnitConversions.convert(area, 'ft^2', 'cm^2')}")
    nv_and_whf_program.addLine("    Set Cs = #{UnitConversions.convert(c_s, 'ft^2/(s^2*R)', 'L^2/(s^2*cm^4*K)')}")
    nv_and_whf_program.addLine("    Set Cw = #{c_w * 0.01}")
    nv_and_whf_program.addLine('    Set Tdiff = Tin-Tout')
    nv_and_whf_program.addLine('    Set dT = (@Abs Tdiff)')
    nv_and_whf_program.addLine("    Set Vwind = #{vwind_sensor.name}")
    nv_and_whf_program.addLine('    Set SGNV = NVArea*Adj*((((Cs*dT)+(Cw*(Vwind^2)))^0.5)/1000)')
    nv_and_whf_program.addLine("    Set MaxNV = #{UnitConversions.convert(max_flow_rate, 'cfm', 'm^3/s')}")
    nv_and_whf_program.addLine("    Set #{nv_flow_actuator.name} = (@Min SGNV MaxNV)")
    nv_and_whf_program.addLine("    Set #{whf_flow_actuator.name} = 0")
    nv_and_whf_program.addLine("    Set #{liv_to_zone_flow_rate_actuator.name} = 0") unless whf_zone.nil?
    nv_and_whf_program.addLine("    Set #{whf_elec_actuator.name} = 0")
    nv_and_whf_program.addLine('  EndIf')
    nv_and_whf_program.addLine('Else')
    nv_and_whf_program.addLine("  Set #{nv_flow_actuator.name} = 0")
    nv_and_whf_program.addLine("  Set #{whf_flow_actuator.name} = 0")
    nv_and_whf_program.addLine("  Set #{liv_to_zone_flow_rate_actuator.name} = 0") unless whf_zone.nil?
    nv_and_whf_program.addLine("  Set #{whf_elec_actuator.name} = 0")
    nv_and_whf_program.addLine('EndIf')

    return nv_and_whf_program
  end

  def self.create_return_air_duct_zone(model, air_loop_name, adiabatic_const)
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
      surface.setConstruction(adiabatic_const)
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

  def self.create_ducts_objects(model, building, ducts, mech_vent, tin_sensor, pbar_sensor, adiabatic_const, air_loop, duct_programs, duct_lks, air_loop_objects)
    return if ducts.size == 0 # No ducts

    # get duct located zone or ambient temperature schedule objects
    duct_locations = ducts.map { |duct| if duct.zone.nil? then duct.loc_schedule else duct.zone end }.uniq
    living_space = building.living.zone.spaces[0]

    # All duct zones are in living space?
    all_ducts_conditioned = true
    duct_locations.each do |duct_zone|
      if duct_locations.is_a? OpenStudio::Model::ThermalZone
        next if Geometry.is_living(duct_zone)
      end

      all_ducts_conditioned = false
    end
    return if all_ducts_conditioned

    if building.living.zone.airLoopHVACs.include? air_loop # next if airloop doesn't serve this

      ra_duct_zone = create_return_air_duct_zone(model, air_loop.name.to_s, adiabatic_const)
      ra_duct_space = ra_duct_zone.spaces[0]

      # Get the air demand inlet node
      air_demand_inlet_node = nil
      if air_loop.to_AirLoopHVAC.is_initialized
        air_demand_inlet_node = air_loop.demandInletNode
      end

      # Set the return plenum
      if air_loop.to_AirLoopHVAC.is_initialized
        building.living.zone.setReturnPlenum(ra_duct_zone, air_loop)
        air_loop.demandComponents.each do |demand_component|
          next unless demand_component.to_AirLoopHVACReturnPlenum.is_initialized

          demand_component.setName("#{air_loop.name} return plenum")
        end
      end

      living_zone_return_air_node = nil
      building.living.zone.returnAirModelObjects.each do |return_air_model_obj|
        next if return_air_model_obj.to_Node.get.airLoopHVAC.get != air_loop

        living_zone_return_air_node = return_air_model_obj
      end

      # -- Sensors --

      # Air handler mass flow rate
      ah_mfr_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "#{air_loop.name} AH MFR".gsub(' ', '_'))
      ah_mfr_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'System Node Mass Flow Rate')
      ah_mfr_sensor.setName("#{ah_mfr_var.name} s")
      ah_mfr_sensor.setKeyName(air_demand_inlet_node.name.to_s)

      # Air handler volume flow rate
      ah_vfr_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "#{air_loop.name} AH VFR".gsub(' ', '_'))
      ah_vfr_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'System Node Current Density Volume Flow Rate')
      ah_vfr_sensor.setName("#{ah_vfr_var.name} s")
      ah_vfr_sensor.setKeyName(air_demand_inlet_node.name.to_s)

      # Air handler outlet temperature
      ah_tout_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "#{air_loop.name} AH Tout".gsub(' ', '_'))
      ah_tout_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'System Node Temperature')
      ah_tout_sensor.setName("#{ah_tout_var.name} s")
      ah_tout_sensor.setKeyName(air_demand_inlet_node.name.to_s)

      # Air handler outlet humidity ratio
      ah_wout_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "#{air_loop.name} AH Wout".gsub(' ', '_'))
      ah_wout_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'System Node Humidity Ratio')
      ah_wout_sensor.setName("#{ah_wout_var.name} s")
      ah_wout_sensor.setKeyName(air_demand_inlet_node.name.to_s)

      # Return air temperature
      ra_t_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "#{air_loop.name} RA T".gsub(' ', '_'))
      if not living_zone_return_air_node.nil?
        ra_t_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'System Node Temperature')
        ra_t_sensor.setName("#{ra_t_var.name} s")
        ra_t_sensor.setKeyName(living_zone_return_air_node.name.to_s)
      else
        ra_t_sensor = tin_sensor
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
        ra_w_sensor.setKeyName(building.living.zone.name.to_s)
      end

      # Living zone humidity ratio
      win_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Zone Mean Air Humidity Ratio')
      win_sensor.setName("#{air_loop.name} win s")
      win_sensor.setKeyName(building.living.zone.name.to_s)

      fan_mfr_max_var = air_loop_objects[air_loop][:fan_mfr_max_var]
      fan_rtf_sensor = air_loop_objects[air_loop][:fan_rtf_sensor]
      fan_mfr_sensor = air_loop_objects[air_loop][:fan_mfr_sensor]
      fan_rtf_var = air_loop_objects[air_loop][:fan_rtf_var]

      # Create one duct program for each duct location zone

      duct_locations.each_with_index do |duct_location, i|
        next if (not duct_location.nil?) && (duct_location.name.to_s == building.living.zone.name.to_s)

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
          if duct_location.name.get == HPXML::LocationOtherNonFreezingSpace
            dz_w_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Site Outdoor Air Humidity Ratio')
            dz_w_sensor.setName("#{dz_w_var.name} s")
            dz_w = "#{dz_w_sensor.name}"
          elsif duct_location.name.get == HPXML::LocationOtherHousingUnit
            dz_w_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Zone Mean Air Humidity Ratio')
            dz_w_sensor.setKeyName(building.living.zone.name.to_s)
            dz_w_sensor.setName("#{dz_w_var.name} s")
            dz_w = "#{dz_w_sensor.name}"
          else
            dz_w_sensor1 = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Site Outdoor Air Humidity Ratio')
            dz_w_sensor1.setName("#{dz_w_var.name} s 1")
            dz_w_sensor2 = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Zone Mean Air Humidity Ratio')
            dz_w_sensor2.setName("#{dz_w_var.name} s 2")
            dz_w_sensor2.setKeyName(building.living.zone.name.to_s)
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

        # Other equipment objects to cancel out the supply air leakage directly into the return plenum
        equip_act_infos << ['supply_sens_lk_to_liv', 'SupSensLkToLv', living_space, 0.0, 0.0]
        equip_act_infos << ['supply_lat_lk_to_liv', 'SupLatLkToLv', living_space, 1.0, 0.0]

        # Supply duct conduction load added to the living space
        equip_act_infos << ['supply_cond_to_liv', 'SupCondToLv', living_space, 0.0, 0.0]

        # Return duct conduction load added to the return plenum zone
        equip_act_infos << ['return_cond_to_rp', 'RetCondToRP', ra_duct_space, 0.0, 0.0]

        # Return duct sensible leakage impact on the return plenum
        equip_act_infos << ['return_sens_lk_to_rp', 'RetSensLkToRP', ra_duct_space, 0.0, 0.0]

        # Return duct latent leakage impact on the return plenum
        equip_act_infos << ['return_lat_lk_to_rp', 'RetLatLkToRP', ra_duct_space, 1.0, 0.0]

        # Supply duct conduction impact on the duct zone
        if not duct_location.is_a? OpenStudio::Model::ThermalZone # Outside or scheduled temperature
          equip_act_infos << ['supply_cond_to_dz', 'SupCondToDZ', living_space, 0.0, 1.0]
        else
          equip_act_infos << ['supply_cond_to_dz', 'SupCondToDZ', duct_location.spaces[0], 0.0, 0.0]
        end

        # Return duct conduction impact on the duct zone
        if not duct_location.is_a? OpenStudio::Model::ThermalZone # Outside or scheduled temperature
          equip_act_infos << ['return_cond_to_dz', 'RetCondToDZ', living_space, 0.0, 1.0]
        else
          equip_act_infos << ['return_cond_to_dz', 'RetCondToDZ', duct_location.spaces[0], 0.0, 0.0]
        end

        # Supply duct sensible leakage impact on the duct zone
        if not duct_location.is_a? OpenStudio::Model::ThermalZone # Outside or scheduled temperature
          equip_act_infos << ['supply_sens_lk_to_dz', 'SupSensLkToDZ', living_space, 0.0, 1.0]
        else
          equip_act_infos << ['supply_sens_lk_to_dz', 'SupSensLkToDZ', duct_location.spaces[0], 0.0, 0.0]
        end

        # Supply duct latent leakage impact on the duct zone
        if not duct_location.is_a? OpenStudio::Model::ThermalZone # Outside or scheduled temperature
          equip_act_infos << ['supply_lat_lk_to_dz', 'SupLatLkToDZ', living_space, 0.0, 1.0]
        else
          equip_act_infos << ['supply_lat_lk_to_dz', 'SupLatLkToDZ', duct_location.spaces[0], 1.0, 0.0]
        end

        duct_vars = {}
        duct_actuators = {}
        [false, true].each do |is_cfis|
          if is_cfis
            next unless ((mech_vent.type == HPXML::MechVentTypeCFIS) && (air_loop == mech_vent.cfis_air_loop))

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
              space = living_space
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
          mix_act_infos << ['dz_to_liv_flow_rate', 'ZoneMixDZToLv', building.living.zone, duct_location]
          # Accounts for leaks from the living zone to the duct zone
          mix_act_infos << ['liv_to_dz_flow_rate', 'ZoneMixLvToDZ', duct_location, building.living.zone]
        end

        [false, true].each do |is_cfis|
          if is_cfis
            next unless ((mech_vent.type == HPXML::MechVentTypeCFIS) && (air_loop == mech_vent.cfis_air_loop))

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

        duct_lk_supply_fan_equiv_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "#{air_loop_name_idx} LkSupFanEquiv".gsub(' ', '_'))
        duct_lk_exhaust_fan_equiv_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "#{air_loop_name_idx} LkExhFanEquiv".gsub(' ', '_'))
        duct_lks[air_loop_name_idx] = [duct_lk_supply_fan_equiv_var, duct_lk_exhaust_fan_equiv_var]

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
          if (not building.unconditioned_basement.nil?) && (building.unconditioned_basement.zone.name.to_s == duct_location.name.to_s)
            f_oa = 0.0
          elsif (not building.unvented_crawlspace.nil?) && (building.unvented_crawlspace.zone.name.to_s == duct_location.name.to_s)
            f_oa = 0.0
          elsif (not building.unvented_attic.nil?) && (building.unvented_attic.zone.name.to_s == duct_location.name.to_s)
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
        duct_subroutine.addLine("  Set Fan_RTF = #{fan_rtf_var.name}")
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
          duct_subroutine.addLine("  Set f_sup = #{UnitConversions.convert(leakage_cfm25s[HPXML::DuctTypeSupply], 'cfm', 'm^3/s').round(6)} / (#{fan_mfr_max_var.name} * 1.0135)") # frac
        else
          duct_subroutine.addLine('  Set f_sup = 0.0') # frac
        end
        if not leakage_fracs[HPXML::DuctTypeReturn].nil?
          duct_subroutine.addLine("  Set f_ret = #{leakage_fracs[HPXML::DuctTypeReturn]}") # frac
        elsif not leakage_cfm25s[HPXML::DuctTypeReturn].nil?
          duct_subroutine.addLine("  Set f_ret = #{UnitConversions.convert(leakage_cfm25s[HPXML::DuctTypeReturn], 'cfm', 'm^3/s').round(6)} / (#{fan_mfr_max_var.name} * 1.0135)") # frac
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
        supply_ua = UnitConversions.convert(ua_values[HPXML::DuctTypeSupply], 'Btu/(hr*F)', 'W/K')
        duct_subroutine.addLine("  Set eTm = (Fan_RTF/(AH_MFR*air_cp))*#{supply_ua.round(3)}")
        duct_subroutine.addLine('  Set eTm = 0-eTm')
        duct_subroutine.addLine('  Set t_sup = DZ_T+((AH_Tout-DZ_T)*(@Exp eTm))') # deg-C
        duct_subroutine.addLine('  Set SupCondToLv = AH_MFR*air_cp*(t_sup-AH_Tout)') # W
        duct_subroutine.addLine('  Set SupCondToDZ = 0-SupCondToLv') # W

        # Return conduction
        return_ua = UnitConversions.convert(ua_values[HPXML::DuctTypeReturn], 'Btu/(hr*F)', 'W/K')
        duct_subroutine.addLine("  Set eTm = (Fan_RTF/(AH_MFR*air_cp))*#{return_ua.round(3)}")
        duct_subroutine.addLine('  Set eTm = 0-eTm')
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

        # Calculate supply/exhaust fan equivalent
        duct_subroutine.addLine('  If oa_vfr > 0')
        duct_subroutine.addLine('    Set LkSupFanEquiv = 0') # m3/s, QductsIn
        duct_subroutine.addLine('    Set LkExhFanEquiv = oa_vfr') # m3/s, QductsOut
        duct_subroutine.addLine('  Else')
        duct_subroutine.addLine('    Set LkSupFanEquiv = 0-oa_vfr') # m3/s, QductsIn
        duct_subroutine.addLine('    Set LkExhFanEquiv = 0') # m3/s, QductsOut
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
        duct_subroutine.addLine('  Set LkSupFanEquiv = 0') # m3/s
        duct_subroutine.addLine('  Set LkExhFanEquiv = 0') # m3/s
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
        duct_subroutine.addLine("Set #{duct_lk_supply_fan_equiv_var.name} = LkSupFanEquiv")
        duct_subroutine.addLine("Set #{duct_lk_exhaust_fan_equiv_var.name} = LkExhFanEquiv")

        # Duct Program

        duct_program = OpenStudio::Model::EnergyManagementSystemProgram.new(model)
        duct_program.setName(air_loop_name_idx + ' duct program')
        duct_program.addLine("Set #{ah_mfr_var.name} = #{ah_mfr_sensor.name}")
        if fan_rtf_sensor.is_a? OpenStudio::Model::EnergyManagementSystemGlobalVariable
          duct_program.addLine("Set #{fan_rtf_sensor.name} = #{fan_mfr_sensor.name} / #{fan_mfr_max_var.name}")
        end
        duct_program.addLine("Set #{fan_rtf_var.name} = #{fan_rtf_sensor.name}")
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

        if (mech_vent.type == HPXML::MechVentTypeCFIS) && (air_loop == mech_vent.cfis_air_loop)

          # Calculate CFIS duct losses

          duct_program.addLine("If #{mech_vent.cfis_f_damper_extra_open_var.name} > 0")
          duct_program.addLine("  Set cfis_m3s = (#{mech_vent.cfis_fan_mfr_max_var} / 1.16097654) * #{mech_vent.cfis_airflow_frac}") # Density of 1.16097654 was back calculated using E+ results
          duct_program.addLine("  Set #{fan_rtf_var.name} = #{mech_vent.cfis_f_damper_extra_open_var.name}") # Need to use global vars to sync duct_program and infiltration program of different calling points
          duct_program.addLine("  Set #{ah_vfr_var.name} = #{fan_rtf_var.name}*cfis_m3s")
          duct_program.addLine("  Set rho_in = (@RhoAirFnPbTdbW #{pbar_sensor.name} #{tin_sensor.name} #{win_sensor.name})")
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

        duct_programs[air_loop_name_idx] = duct_program
      end
    end
  end

  def self.create_cfis_objects(model, building, mech_vent)
    if (mech_vent.cfis_airflow_frac < 0) || (mech_vent.cfis_airflow_frac > 1)
      fail 'Mechanical Ventilation: CFIS blower airflow rate must be greater than or equal to 0 and less than or equal to 1.'
    end

    mech_vent.cfis_t_sum_open_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "#{Constants.ObjectNameMechanicalVentilation.gsub(' ', '_')}_cfis_t_sum_open") # Sums the time during an hour the CFIS damper has been open
    mech_vent.cfis_f_damper_extra_open_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "#{Constants.ObjectNameMechanicalVentilation.gsub(' ', '_')}_cfis_f_extra_damper_open") # Fraction of timestep the CFIS blower is running while hvac is not operating. Used by infiltration and duct leakage programs

    if mech_vent.fan_power_w.nil?
      supply_fan = HVAC.get_unitary_system_from_air_loop_hvac(mech_vent.cfis_air_loop).supplyFan.get.to_FanOnOff.get

      mech_vent.cfis_fan_pressure_rise = OpenStudio::Model::EnergyManagementSystemInternalVariable.new(model, 'Fan Nominal Pressure Rise')
      mech_vent.cfis_fan_pressure_rise.setName("#{Constants.ObjectNameMechanicalVentilation} sup fan press".gsub(' ', '_'))
      mech_vent.cfis_fan_pressure_rise.setInternalDataIndexKeyName(supply_fan.name.to_s)

      mech_vent.cfis_fan_efficiency = OpenStudio::Model::EnergyManagementSystemInternalVariable.new(model, 'Fan Nominal Total Efficiency')
      mech_vent.cfis_fan_efficiency.setName("#{Constants.ObjectNameMechanicalVentilation} sup fan eff".gsub(' ', '_'))
      mech_vent.cfis_fan_efficiency.setInternalDataIndexKeyName(supply_fan.name.to_s)
    end

    # CFIS Program
    cfis_program = OpenStudio::Model::EnergyManagementSystemProgram.new(model)
    cfis_program.setName(Constants.ObjectNameMechanicalVentilation + ' cfis init program')
    cfis_program.addLine("Set #{mech_vent.cfis_t_sum_open_var.name} = 0")
    cfis_program.addLine("Set #{mech_vent.cfis_f_damper_extra_open_var.name} = 0")

    return cfis_program
  end

  def self.create_infil_mech_vent_objects(model, building, infil, mech_vent, vent_fan_kitchen, vent_fan_bath, wind_speed, tin_sensor, tout_sensor, vwind_sensor, duct_lks, wout_sensor, pbar_sensor)
    # Sensors

    range_array = [0.0] * 24
    if not vent_fan_kitchen.nil?
      remaining_hrs = vent_fan_kitchen.hours_in_operation
      for hr in 1..(vent_fan_kitchen.hours_in_operation.ceil)
        if remaining_hrs >= 1
          range_array[(vent_fan_kitchen.start_hour + hr - 1) % 24] = 1.0
        else
          range_array[(vent_fan_kitchen.start_hour + hr - 1) % 24] = remaining_hrs
        end
        remaining_hrs -= 1
      end
    end
    range_hood_sch = HourlyByMonthSchedule.new(model, Constants.ObjectNameMechanicalVentilation + ' range exhaust schedule', [range_array] * 12, [range_array] * 12, false, true, Constants.ScheduleTypeLimitsOnOff)
    range_sch_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Schedule Value')
    range_sch_sensor.setName("#{Constants.ObjectNameMechanicalVentilation} range sch s")
    range_sch_sensor.setKeyName(range_hood_sch.schedule.name.to_s)

    bathroom_array = [0.0] * 24
    if not vent_fan_bath.nil?
      remaining_hrs = vent_fan_bath.hours_in_operation
      for hr in 1..(vent_fan_bath.hours_in_operation.ceil)
        if remaining_hrs >= 1
          bathroom_array[(vent_fan_bath.start_hour + hr - 1) % 24] = 1.0
        else
          bathroom_array[(vent_fan_bath.start_hour + hr - 1) % 24] = remaining_hrs
        end
        remaining_hrs -= 1
      end
    end
    bath_exhaust_sch = HourlyByMonthSchedule.new(model, Constants.ObjectNameMechanicalVentilation + ' bath exhaust schedule', [bathroom_array] * 12, [bathroom_array] * 12, false, true, Constants.ScheduleTypeLimitsOnOff)
    bath_sch_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Schedule Value')
    bath_sch_sensor.setName("#{Constants.ObjectNameMechanicalVentilation} bath sch s")
    bath_sch_sensor.setKeyName(bath_exhaust_sch.schedule.name.to_s)

    if mech_vent.has_dryer && (mech_vent.dryer_exhaust > 0)
      dryer_exhaust_sch = HotWaterSchedule.new(model, Constants.ObjectNameMechanicalVentilation + ' dryer exhaust schedule', building.nbeds, 0, true)
      dryer_sch_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Schedule Value')
      dryer_sch_sensor.setName("#{Constants.ObjectNameMechanicalVentilation} dryer sch s")
      dryer_sch_sensor.setKeyName(dryer_exhaust_sch.schedule.name.to_s)
    end

    wh_sch_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Schedule Value')
    wh_sch_sensor.setName("#{Constants.ObjectNameMechanicalVentilation} wh sch s")
    wh_sch_sensor.setKeyName(model.alwaysOnDiscreteSchedule.name.to_s)

    # Actuators

    living_space = building.living.zone.spaces[0]

    equip_def = OpenStudio::Model::ElectricEquipmentDefinition.new(model)
    equip_def.setName(Constants.ObjectNameMechanicalVentilationHouseFan)
    equip = OpenStudio::Model::ElectricEquipment.new(equip_def)
    equip.setName(Constants.ObjectNameMechanicalVentilationHouseFan)
    equip.setSpace(living_space)
    equip_def.setFractionRadiant(0)
    equip_def.setFractionLatent(0)
    equip_def.setFractionLost(1.0 - mech_vent.frac_fan_heat)
    equip.setSchedule(model.alwaysOnDiscreteSchedule)
    equip.setEndUseSubcategory(Constants.ObjectNameMechanicalVentilation)
    mech_vent_fan_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(equip, 'ElectricEquipment', 'Electric Power Level')
    mech_vent_fan_actuator.setName("#{equip.name} act")

    equip_def = OpenStudio::Model::ElectricEquipmentDefinition.new(model)
    equip_def.setName(Constants.ObjectNameMechanicalVentilationRangeFan)
    equip = OpenStudio::Model::ElectricEquipment.new(equip_def)
    equip.setName(Constants.ObjectNameMechanicalVentilationRangeFan)
    equip.setSpace(living_space)
    if vent_fan_kitchen.nil?
      equip_def.setDesignLevel(0.0)
    else
      equip_def.setDesignLevel(vent_fan_kitchen.fan_power)
    end
    equip_def.setFractionRadiant(0)
    equip_def.setFractionLatent(0)
    equip_def.setFractionLost(1)
    equip.setSchedule(range_hood_sch.schedule)
    equip.setEndUseSubcategory(Constants.ObjectNameMechanicalVentilation)

    equip_def = OpenStudio::Model::ElectricEquipmentDefinition.new(model)
    equip_def.setName(Constants.ObjectNameMechanicalVentilationBathFan)
    equip = OpenStudio::Model::ElectricEquipment.new(equip_def)
    equip.setName(Constants.ObjectNameMechanicalVentilationBathFan)
    equip.setSpace(living_space)
    if vent_fan_bath.nil?
      equip_def.setDesignLevel(0.0)
    else
      equip_def.setDesignLevel(vent_fan_bath.fan_power)
    end
    equip_def.setFractionRadiant(0)
    equip_def.setFractionLatent(0)
    equip_def.setFractionLost(1)
    equip.setSchedule(bath_exhaust_sch.schedule)
    equip.setEndUseSubcategory(Constants.ObjectNameMechanicalVentilation)

    infil_flow = OpenStudio::Model::SpaceInfiltrationDesignFlowRate.new(model)
    infil_flow.setName(Constants.ObjectNameInfiltration + ' flow')
    infil_flow.setSchedule(model.alwaysOnDiscreteSchedule)
    infil_flow.setSpace(living_space)
    infil_flow_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(infil_flow, 'Zone Infiltration', 'Air Exchange Flow Rate')
    infil_flow_actuator.setName("#{infil_flow.name} act")

    imbal_ducts_flow = OpenStudio::Model::SpaceInfiltrationDesignFlowRate.new(model)
    imbal_ducts_flow.setName(Constants.ObjectNameDucts + ' flow')
    imbal_ducts_flow.setSchedule(model.alwaysOnDiscreteSchedule)
    imbal_ducts_flow.setSpace(living_space)
    imbal_ducts_flow_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(imbal_ducts_flow, 'Zone Infiltration', 'Air Exchange Flow Rate')
    imbal_ducts_flow_actuator.setName("#{imbal_ducts_flow.name} act")

    imbal_mechvent_flow = OpenStudio::Model::SpaceInfiltrationDesignFlowRate.new(model)
    imbal_mechvent_flow.setName(Constants.ObjectNameMechanicalVentilation + ' flow')
    imbal_mechvent_flow.setSchedule(model.alwaysOnDiscreteSchedule)
    imbal_mechvent_flow.setSpace(living_space)
    imbal_mechvent_flow_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(imbal_mechvent_flow, 'Zone Infiltration', 'Air Exchange Flow Rate')
    imbal_mechvent_flow_actuator.setName("#{imbal_mechvent_flow.name} act")

    # Program

    infil_program = OpenStudio::Model::EnergyManagementSystemProgram.new(model)
    infil_program.setName(Constants.ObjectNameInfiltration + ' program')
    if building.living.inf_method == @infMethodAIM2
      if building.living.SLA > 0
        infil_program.addLine("Set p_m = #{wind_speed.ashrae_terrain_exponent}")
        infil_program.addLine("Set p_s = #{wind_speed.ashrae_site_terrain_exponent}")
        infil_program.addLine("Set s_m = #{wind_speed.ashrae_terrain_thickness}")
        infil_program.addLine("Set s_s = #{wind_speed.ashrae_site_terrain_thickness}")
        infil_program.addLine("Set z_m = #{UnitConversions.convert(wind_speed.height, 'ft', 'm')}")
        infil_program.addLine("Set z_s = #{UnitConversions.convert(building.infilheight, 'ft', 'm')}")
        infil_program.addLine('Set f_t = (((s_m/z_m)^p_m)*((z_s/s_s)^p_s))')
        infil_program.addLine("Set Tdiff = #{tin_sensor.name}-#{tout_sensor.name}")
        infil_program.addLine('Set dT = @Abs Tdiff')
        infil_program.addLine("Set c = #{((UnitConversions.convert(infil.c_i, 'cfm', 'm^3/s') / (UnitConversions.convert(1.0, 'inH2O', 'Pa')**infil.n_i))).round(4)}")
        infil_program.addLine("Set Cs = #{(infil.stack_coef * (UnitConversions.convert(1.0, 'inH2O/R', 'Pa/K')**infil.n_i)).round(4)}")
        infil_program.addLine("Set Cw = #{(infil.wind_coef * (UnitConversions.convert(1.0, 'inH2O/mph^2', 'Pa*s^2/m^2')**infil.n_i)).round(4)}")
        infil_program.addLine("Set n = #{infil.n_i}")
        infil_program.addLine("Set sft = (f_t*#{(((wind_speed.S_wo * (1.0 - infil.y_i)) + (infil.s_wflue * (1.5 * infil.y_i))))})")
        infil_program.addLine("Set temp1 = ((c*Cw)*((sft*#{vwind_sensor.name})^(2*n)))^2")
        infil_program.addLine('Set Qn = (((c*Cs*(dT^n))^2)+temp1)^0.5')
      else
        infil_program.addLine('Set Qn = 0')
      end
    elsif building.living.inf_method == @infMethodConstantCFM
      infil_program.addLine("Set Qn = #{building.living.ACH * UnitConversions.convert(building.infilvolume, 'ft^3', 'm^3') / UnitConversions.convert(1.0, 'hr', 's')}")
    end

    if [HPXML::MechVentTypeBalanced, HPXML::MechVentTypeERV, HPXML::MechVentTypeHRV].include?(mech_vent.type) && (mech_vent.cfm > 0)
      # ERV/HRV/Balanced EMS load model
      # E+ ERV model is using standard density for MFR calculation, caused discrepancy with other system types.
      # E+ ERV model also does not meet setpoint perfectly.
      # Therefore ERV is modeled within EMS infiltration program

      # Sensors for ERV/HRV
      win_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Zone Air Humidity Ratio')
      win_sensor.setName("#{Constants.ObjectNameAirflow} win s")
      win_sensor.setKeyName(building.living.zone.name.to_s)

      # Actuators for ERV/HRV
      sens_name = "#{Constants.ObjectNameERVHRV} sensible load"
      erv_sens_load_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, sens_name.gsub(' ', '_'))
      erv_sens_load_actuator = create_sens_lat_load_actuator_and_equipment(model, sens_name, living_space, 0.0, 0.0)
      lat_name = "#{Constants.ObjectNameERVHRV} latent load"
      erv_lat_load_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, lat_name.gsub(' ', '_'))
      erv_lat_load_actuator = create_sens_lat_load_actuator_and_equipment(model, lat_name, living_space, 1.0, 0.0)

      # Air property at inlet nodes in two sides of ERV
      infil_program.addLine("Set ERVSupInPb = #{pbar_sensor.name}") # oa barometric pressure
      infil_program.addLine("Set ERVSupInTemp = #{tout_sensor.name}") # oa db temperature
      infil_program.addLine("Set ERVSupInW = #{wout_sensor.name}")   # oa humidity ratio
      infil_program.addLine('Set ERVSupRho = (@RhoAirFnPbTdbW ERVSupInPb ERVSupInTemp ERVSupInW)')
      infil_program.addLine('Set ERVSupCp = (@CpAirFnW ERVSupInW)')
      infil_program.addLine('Set ERVSupInEnth = (@HFnTdbW ERVSupInTemp ERVSupInW)')

      infil_program.addLine("Set ERVSecInTemp = #{tin_sensor.name}") # zone air temperature
      infil_program.addLine("Set ERVSecInW = #{win_sensor.name}") # zone air humidity ratio
      infil_program.addLine('Set ERVSecCp = (@CpAirFnW ERVSecInW)')
      infil_program.addLine('Set ERVSecInEnth = (@HFnTdbW ERVSecInTemp ERVSecInW)')

      # Calculate mass flow rate based on outdoor air density
      infil_program.addLine("Set balanced_mechvent_flow_rate = #{UnitConversions.convert(mech_vent.cfm, 'cfm', 'm^3/s')}")
      infil_program.addLine('Set ERV_MFR = balanced_mechvent_flow_rate * ERVSupRho')

      # Heat exchanger calculation
      infil_program.addLine('Set ERVCpMin = (@Min ERVSupCp ERVSecCp)')
      infil_program.addLine("Set ERVSupOutTemp = ERVSupInTemp + ERVCpMin/ERVSupCp * #{mech_vent.sensible_effectiveness} * (ERVSecInTemp - ERVSupInTemp)")
      infil_program.addLine("Set ERVSupOutW = ERVSupInW + ERVCpMin/ERVSupCp * #{mech_vent.latent_effectiveness} * (ERVSecInW - ERVSupInW)")
      infil_program.addLine('Set ERVSupOutEnth = (@HFnTdbW ERVSupOutTemp ERVSupOutW)')
      infil_program.addLine('Set ERVSensHeatTrans = ERV_MFR * ERVSupCp * (ERVSupOutTemp - ERVSupInTemp)')
      infil_program.addLine('Set ERVTotalHeatTrans = ERV_MFR * (ERVSupOutEnth - ERVSupInEnth)')
      infil_program.addLine('Set ERVLatHeatTrans = ERVTotalHeatTrans - ERVSensHeatTrans')

      # Load calculation
      infil_program.addLine('Set ERVTotalToLv = ERV_MFR * (ERVSupOutEnth - ERVSecInEnth)')
      infil_program.addLine('Set ERVSensToLv = ERV_MFR * ERVSecCp * (ERVSupOutTemp - ERVSecInTemp)')
      infil_program.addLine('Set ERVLatToLv = ERVTotalToLv - ERVSensToLv')

      # Actuator
      infil_program.addLine("Set #{erv_sens_load_actuator.name} = ERVSensToLv")
      infil_program.addLine("Set #{erv_lat_load_actuator.name} = ERVLatToLv")
    else
      infil_program.addLine('Set balanced_mechvent_flow_rate = 0')
    end

    if mech_vent.type == HPXML::MechVentTypeCFIS

      infil_program.addLine("Set fan_rtf_hvac = #{mech_vent.cfis_fan_rtf_sensor}")
      if mech_vent.fan_power_w.nil?
        # Use supply fan W/cfm
        infil_program.addLine("Set CFIS_fan_power = #{mech_vent.cfis_fan_pressure_rise.name} / #{mech_vent.cfis_fan_efficiency.name} * #{UnitConversions.convert(1.0, 'cfm', 'm^3/s').round(6)}") # W/cfm
      else
        # Use specified CFIS fan W
        infil_program.addLine("Set airloop_cfm = (#{mech_vent.cfis_fan_mfr_max_var} / 1.16097654) * #{UnitConversions.convert(1.0, 'm^3/s', 'cfm')}") # Density of 1.16097654 was back calculated using E+ results
        infil_program.addLine("Set CFIS_fan_w = #{mech_vent.fan_power_w}") # W
        infil_program.addLine('Set CFIS_fan_power = CFIS_fan_w / airloop_cfm') # W/cfm
      end

      infil_program.addLine('If @ABS(Minute - ZoneTimeStep*60) < 0.1')
      infil_program.addLine("  Set #{mech_vent.cfis_t_sum_open_var.name} = 0") # New hour, time on summation re-initializes to 0
      infil_program.addLine('EndIf')

      infil_program.addLine("Set CFIS_t_min_hr_open = #{mech_vent.cfis_open_time}") # minutes per hour the CFIS damper is open
      infil_program.addLine("Set CFIS_Q_duct = #{UnitConversions.convert(mech_vent.cfm, 'cfm', 'm^3/s')}")
      infil_program.addLine('Set cfis_f_damper_open = 0') # fraction of the timestep the CFIS damper is open
      infil_program.addLine("Set #{mech_vent.cfis_f_damper_extra_open_var.name} = 0") # additional runtime fraction to meet min/hr

      infil_program.addLine("If #{mech_vent.cfis_t_sum_open_var.name} < CFIS_t_min_hr_open")
      infil_program.addLine("  Set CFIS_t_fan_on = 60 - (CFIS_t_min_hr_open - #{mech_vent.cfis_t_sum_open_var.name})") # minute at which the blower needs to turn on to meet the ventilation requirements
      # Evaluate condition of if supply fan have to run to achieve target minutes per hour of operation
      infil_program.addLine('  If (Minute+0.00001) >= CFIS_t_fan_on')
      # Consider fan rtf read in current calling point (results of previous time step) + CFIS_t_fan_on based on min/hr requirement and previous EMS results.
      infil_program.addLine('    Set cfis_fan_runtime = @Max (@ABS(Minute - CFIS_t_fan_on)) (fan_rtf_hvac * ZoneTimeStep * 60)')
      # If fan_rtf_hvac, make sure it's not exceeding ventilation requirements
      infil_program.addLine("    Set cfis_fan_runtime = @Min cfis_fan_runtime (CFIS_t_min_hr_open - #{mech_vent.cfis_t_sum_open_var.name})")
      infil_program.addLine('    Set cfis_f_damper_open = cfis_fan_runtime/(60.0*ZoneTimeStep)') # calculates the portion of the current timestep the CFIS damper needs to be open
      infil_program.addLine('    Set QWHV = cfis_f_damper_open*CFIS_Q_duct')
      infil_program.addLine("    Set #{mech_vent.cfis_t_sum_open_var.name} = #{mech_vent.cfis_t_sum_open_var.name}+cfis_fan_runtime")
      infil_program.addLine("    Set cfis_cfm = airloop_cfm*#{mech_vent.cfis_airflow_frac}")
      infil_program.addLine("    Set #{mech_vent.cfis_f_damper_extra_open_var.name} = @Max (cfis_f_damper_open-fan_rtf_hvac) 0.0")
      infil_program.addLine("    Set #{mech_vent_fan_actuator.name} = CFIS_fan_power*cfis_cfm*#{mech_vent.cfis_f_damper_extra_open_var.name}")
      infil_program.addLine('  Else')
      # No need to turn on blower for extra ventilation
      infil_program.addLine('    Set cfis_fan_runtime = fan_rtf_hvac*ZoneTimeStep*60')
      infil_program.addLine("    If (#{mech_vent.cfis_t_sum_open_var.name}+cfis_fan_runtime) > CFIS_t_min_hr_open")
      # Damper is only open for a portion of this time step to achieve target minutes per hour
      infil_program.addLine("      Set cfis_fan_runtime = CFIS_t_min_hr_open-#{mech_vent.cfis_t_sum_open_var.name}")
      infil_program.addLine('      Set cfis_f_damper_open = cfis_fan_runtime/(ZoneTimeStep*60)')
      infil_program.addLine('      Set QWHV = cfis_f_damper_open*CFIS_Q_duct')
      infil_program.addLine("      Set #{mech_vent.cfis_t_sum_open_var.name} = CFIS_t_min_hr_open")
      infil_program.addLine('    Else')
      # Damper is open and using call for heat/cool to supply fresh air
      infil_program.addLine('      Set cfis_fan_runtime = fan_rtf_hvac*ZoneTimeStep*60')
      infil_program.addLine('      Set cfis_f_damper_open = fan_rtf_hvac')
      infil_program.addLine('      Set QWHV = cfis_f_damper_open * CFIS_Q_duct')
      infil_program.addLine("      Set #{mech_vent.cfis_t_sum_open_var.name} = #{mech_vent.cfis_t_sum_open_var.name}+cfis_fan_runtime")
      infil_program.addLine('    EndIf')
      # Fan power is metered under fan cooling and heating meters
      infil_program.addLine("    Set #{mech_vent_fan_actuator.name} = 0")
      infil_program.addLine('  EndIf')
      infil_program.addLine('Else')
      # The ventilation requirement for the hour has been met
      infil_program.addLine('  Set QWHV = 0')
      infil_program.addLine("  Set #{mech_vent_fan_actuator.name} = 0")
      infil_program.addLine('EndIf')

      # Create EMS output variables for CFIS tests

      ems_output_var = OpenStudio::Model::EnergyManagementSystemOutputVariable.new(model, 'CFIS_fan_w')
      ems_output_var.setName("#{Constants.ObjectNameMechanicalVentilation} cfis fan power".gsub(' ', '_'))
      ems_output_var.setTypeOfDataInVariable('Averaged')
      ems_output_var.setUpdateFrequency('ZoneTimestep')
      ems_output_var.setEMSProgramOrSubroutineName(infil_program)
      ems_output_var.setUnits('W')

      ems_output_var = OpenStudio::Model::EnergyManagementSystemOutputVariable.new(model, 'QWHV')
      ems_output_var.setName("#{Constants.ObjectNameMechanicalVentilation} cfis flow rate".gsub(' ', '_'))
      ems_output_var.setTypeOfDataInVariable('Averaged')
      ems_output_var.setUpdateFrequency('ZoneTimestep')
      ems_output_var.setEMSProgramOrSubroutineName(infil_program)
      ems_output_var.setUnits('m3/s')
    else
      infil_program.addLine("Set QWHV = #{wh_sch_sensor.name}*#{UnitConversions.convert(mech_vent.cfm, 'cfm', 'm^3/s').round(4)}")
    end

    if vent_fan_kitchen.nil?
      infil_program.addLine('Set Qrange = 0')
    else
      infil_program.addLine("Set Qrange = #{range_sch_sensor.name}*#{UnitConversions.convert(vent_fan_kitchen.rated_flow_rate, 'cfm', 'm^3/s').round(4)}")
    end
    if mech_vent.has_dryer && (mech_vent.dryer_exhaust > 0)
      infil_program.addLine("Set Qdryer = #{dryer_sch_sensor.name}*#{UnitConversions.convert(mech_vent.dryer_exhaust, 'cfm', 'm^3/s').round(4)}")
    else
      infil_program.addLine('Set Qdryer = 0.0')
    end
    if vent_fan_bath.nil?
      infil_program.addLine('Set Qbath = 0')
    else
      infil_program.addLine("Set Qbath = #{bath_sch_sensor.name}*#{UnitConversions.convert(vent_fan_bath.rated_flow_rate * vent_fan_bath.quantity, 'cfm', 'm^3/s').round(4)}")
    end
    infil_program.addLine('Set QductsOut = 0')
    infil_program.addLine('Set QductsIn = 0')
    # Disabling duct imbalance affect on infiltration for consistency with other software tools
    # Revisit this in the future.
    # duct_lks.each do |air_loop_name, value|
    #  duct_lk_supply_fan_equiv_var, duct_lk_exhaust_fan_equiv_var = value
    #  infil_program.addLine("Set QductsOut = QductsOut+#{duct_lk_exhaust_fan_equiv_var.name}")
    #  infil_program.addLine("Set QductsIn = QductsIn+#{duct_lk_supply_fan_equiv_var.name}")
    # end
    infil_program.addLine('Set Qout = Qrange+Qbath+Qdryer+QductsOut')
    infil_program.addLine('Set Qin = QductsIn')
    if mech_vent.type == HPXML::MechVentTypeExhaust
      infil_program.addLine('Set Qout = Qout+QWHV')
    elsif (mech_vent.type == HPXML::MechVentTypeSupply) || (mech_vent.type == HPXML::MechVentTypeCFIS)
      infil_program.addLine('Set Qin = Qin+QWHV')
    end
    infil_program.addLine('Set Qu = (@Abs (Qout-Qin))')
    if mech_vent.type != HPXML::MechVentTypeCFIS
      if mech_vent.cfm > 0
        infil_program.addLine("Set #{mech_vent_fan_actuator.name} = QWHV * #{mech_vent.fan_power_w} / #{UnitConversions.convert(mech_vent.cfm, 'cfm', 'm^3/s')}")
      else
        infil_program.addLine("Set #{mech_vent_fan_actuator.name} = #{mech_vent.fan_power_w}")
      end
    end

    infil_program.addLine('Set Q_tot_flow = (((Qu^2)+(Qn^2))^0.5)')
    infil_program.addLine('Set Q_tot_flow = (@Max Q_tot_flow 0)')

    # Assign total airflow to different component loads
    infil_program.addLine("Set #{imbal_mechvent_flow_actuator.name} = (@Abs ((Qout - QductsOut) - (Qin - QductsIn)))")
    infil_program.addLine("Set #{imbal_ducts_flow_actuator.name} = (@Abs (QductsOut - QductsIn))")
    # Assign the remainder to infiltration:
    infil_program.addLine("Set #{infil_flow_actuator.name} = Q_tot_flow - #{imbal_mechvent_flow_actuator.name} - #{imbal_ducts_flow_actuator.name}")
    infil_program.addLine("If #{infil_flow_actuator.name} < 0")
    infil_program.addLine("  Set #{infil_flow_actuator.name} = 0")
    infil_program.addLine('EndIf')

    return infil_program
  end

  def self.create_ems_program_managers(model, infil_program, nv_and_whf_program, cfis_program, duct_programs)
    program_calling_manager = OpenStudio::Model::EnergyManagementSystemProgramCallingManager.new(model)
    program_calling_manager.setName(Constants.ObjectNameAirflow + ' program calling manager')
    program_calling_manager.setCallingPoint('BeginTimestepBeforePredictor')
    program_calling_manager.addProgram(infil_program)
    program_calling_manager.addProgram(nv_and_whf_program)

    if not cfis_program.nil?
      program_calling_manager = OpenStudio::Model::EnergyManagementSystemProgramCallingManager.new(model)
      program_calling_manager.setName(Constants.ObjectNameMechanicalVentilation + ' cfis init program 1 calling manager')
      program_calling_manager.setCallingPoint('BeginNewEnvironment')
      program_calling_manager.addProgram(cfis_program)

      program_calling_manager = OpenStudio::Model::EnergyManagementSystemProgramCallingManager.new(model)
      program_calling_manager.setName(Constants.ObjectNameMechanicalVentilation + ' cfis init program 2 calling manager')
      program_calling_manager.setCallingPoint('AfterNewEnvironmentWarmUpIsComplete')
      program_calling_manager.addProgram(cfis_program)
    end

    duct_programs.each do |air_loop_name, duct_program|
      program_calling_manager = OpenStudio::Model::EnergyManagementSystemProgramCallingManager.new(model)
      program_calling_manager.setName(air_loop_name + ' program calling manager')
      program_calling_manager.setCallingPoint('EndOfSystemTimestepAfterHVACReporting')
      program_calling_manager.addProgram(duct_program)
    end
  end

  def self.calc_inferred_infiltration_height(cfa, ncfl, ncfl_ag, infil_volume, hpxml)
    # Infiltration height: vertical distance between lowest and highest above-grade points within the pressure boundary.
    # Height is inferred from available HPXML properties.
    has_walkout_basement = hpxml.has_walkout_basement()

    if has_walkout_basement
      infil_height = Float(ncfl_ag) * infil_volume / cfa
    else
      # Calculate maximum above-grade height of conditioned basement walls
      max_cond_bsmt_wall_height_ag = 0.0
      hpxml.foundation_walls.each do |foundation_wall|
        next unless foundation_wall.is_exterior_thermal_boundary

        height_ag = foundation_wall.height - foundation_wall.depth_below_grade
        next unless height_ag > max_cond_bsmt_wall_height_ag

        max_cond_bsmt_wall_height_ag = height_ag
      end
      infil_height = Float(ncfl_ag) * infil_volume / cfa + max_cond_bsmt_wall_height_ag
    end
    return infil_height
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
  attr_accessor(:side, :loc_space, :loc_schedule, :leakage_frac, :leakage_cfm25, :area, :rvalue, :zone, :location_handle)
end

class Infiltration
  def initialize(living_ach50, living_constant_ach, shelter_coef, garage_ach50, vented_crawl_sla, unvented_crawl_sla, vented_attic_sla, unvented_attic_sla,
                 vented_attic_const_ach, unconditioned_basement_ach, has_flue_chimney, terrain)
    @living_ach50 = living_ach50
    @living_constant_ach = living_constant_ach
    @shelter_coef = shelter_coef
    @garage_ach50 = garage_ach50
    @vented_crawl_sla = vented_crawl_sla
    @unvented_crawl_sla = unvented_crawl_sla
    @vented_attic_sla = vented_attic_sla
    @unvented_attic_sla = unvented_attic_sla
    @vented_attic_const_ach = vented_attic_const_ach
    @unconditioned_basement_ach = unconditioned_basement_ach
    @has_flue_chimney = has_flue_chimney
    @terrain = terrain
  end
  attr_accessor(:living_ach50, :living_constant_ach, :shelter_coef, :garage_ach50, :vented_crawl_sla, :unvented_crawl_sla, :vented_attic_sla, :unvented_attic_sla, :vented_attic_const_ach,
                :unconditioned_basement_ach, :has_flue_chimney, :terrain, :a_o, :c_i, :n_i, :stack_coef, :wind_coef, :y_i, :s_wflue)
end

class NaturalVentilation
  def initialize(nv_frac_window_area_open, max_oa_hr, max_oa_rh, nv_num_days_per_week,
                 htg_weekday_setpoints, htg_weekend_setpoints, clg_weekday_setpoints, clg_weekend_setpoints, clg_ssn_sensor)
    @nv_frac_window_area_open = nv_frac_window_area_open
    @max_oa_hr = max_oa_hr
    @max_oa_rh = max_oa_rh
    @nv_num_days_per_week = nv_num_days_per_week
    @htg_weekday_setpoints = htg_weekday_setpoints
    @htg_weekend_setpoints = htg_weekend_setpoints
    @clg_weekday_setpoints = clg_weekday_setpoints
    @clg_weekend_setpoints = clg_weekend_setpoints
    @clg_ssn_sensor = clg_ssn_sensor
  end
  attr_accessor(:nv_frac_window_area_open, :max_oa_hr, :max_oa_rh, :nv_num_days_per_week,
                :htg_weekday_setpoints, :htg_weekend_setpoints, :clg_weekday_setpoints, :clg_weekend_setpoints, :clg_ssn_sensor)
end

class WholeHouseFan
  def initialize(cfm, fan_power_w, whf_num_days_per_week)
    @cfm = cfm
    @fan_power_w = fan_power_w
    @whf_num_days_per_week = whf_num_days_per_week
  end
  attr_accessor(:cfm, :fan_power_w, :whf_num_days_per_week)
end

class MechanicalVentilation
  def initialize(type, total_efficiency, total_efficiency_adjusted, cfm,
                 fan_power_w, sensible_efficiency, sensible_efficiency_adjusted,
                 dryer_exhaust, cfis_open_time, cfis_airflow_frac, cfis_air_loop)
    @type = type
    @total_efficiency = total_efficiency
    @total_efficiency_adjusted = total_efficiency_adjusted
    @cfm = cfm
    @fan_power_w = fan_power_w
    @sensible_efficiency = sensible_efficiency
    @sensible_efficiency_adjusted = sensible_efficiency_adjusted
    @dryer_exhaust = dryer_exhaust
    @cfis_open_time = cfis_open_time
    @cfis_airflow_frac = cfis_airflow_frac
    @cfis_air_loop = cfis_air_loop
  end
  attr_accessor(:type, :total_efficiency, :total_efficiency_adjusted, :cfm, :fan_power_w, :sensible_efficiency, :sensible_efficiency_adjusted,
                :dryer_exhaust, :cfis_open_time, :cfis_airflow_frac, :cfis_air_loop, :cfis_t_sum_open_var, :cfis_f_damper_extra_open_var,
                :cfis_fan_mfr_max_var, :cfis_fan_rtf_sensor, :cfis_fan_pressure_rise, :cfis_fan_efficiency,
                :frac_fan_heat, :latent_effectiveness, :sensible_effectiveness, :dryer_exhaust_day_shift, :has_dryer)
end

class ZoneInfo
  def initialize(zone, height, area, volume, coord_z, ach = nil, sla = nil)
    @zone = zone
    @height = height
    @area = area
    @volume = volume
    @coord_z = coord_z
    @ACH = ach
    @SLA = sla
  end
  attr_accessor(:zone, :height, :area, :volume, :coord_z, :inf_method, :SLA, :ACH, :inf_flow, :hor_lk_frac, :neutral_level, :f_t_SG, :f_s_SG, :f_w_SG, :C_s_SG, :C_w_SG, :ELA)
end

class WindSpeed
  def initialize
  end
  attr_accessor(:height, :terrain_multiplier, :terrain_exponent, :ashrae_terrain_thickness, :ashrae_terrain_exponent, :site_terrain_multiplier, :site_terrain_exponent, :ashrae_site_terrain_thickness, :ashrae_site_terrain_exponent, :S_wo, :shielding_coef)
end

class Building
  def initialize
  end
  attr_accessor(:cfa, :infilvolume, :infilheight, :nbeds, :nbaths, :ncfl_ag, :window_area, :height, :stories, :SLA, :living, :garage, :unconditioned_basement, :vented_crawlspace, :unvented_crawlspace, :vented_attic, :unvented_attic)
end
