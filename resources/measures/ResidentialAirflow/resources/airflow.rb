require "#{File.dirname(__FILE__)}/constants"
require "#{File.dirname(__FILE__)}/unit_conversions"
require "#{File.dirname(__FILE__)}/schedules"
require "#{File.dirname(__FILE__)}/weather"
require "#{File.dirname(__FILE__)}/util"
require "#{File.dirname(__FILE__)}/psychrometrics"
require "#{File.dirname(__FILE__)}/unit_conversions"
require "#{File.dirname(__FILE__)}/hvac"

class Airflow

  def self.apply(model, runner, infil, mech_vent, nat_vent, ducts, measure_dir)
  
    @measure_dir = measure_dir
  
    weather = WeatherProcess.new(model, runner, File.dirname(__FILE__))
    if weather.error?
      return false
    end
    
    @infMethodRes = 'RESIDENTIAL'
    @infMethodASHRAE = 'ASHRAE-ENHANCED'
    @infMethodSG = 'SHERMAN-GRIMSRUD'

    # Get building units
    units = Geometry.get_building_units(model, runner)
    if units.nil?
      return false
    end
    
    model_spaces = model.getSpaces
    
    # Populate building object
    building = Building.new
    spaces = []
    model_spaces.each do |space|
      next if Geometry.space_is_below_grade(space)
      spaces << space
    end
    building.building_height = Geometry.get_height_of_spaces(spaces)
    unless model.getBuilding.standardsNumberOfAboveGroundStories.is_initialized
      runner.registerError("Cannot determine the number of above grade stories.")
      return false
    end
    building.stories = model.getBuilding.standardsNumberOfAboveGroundStories.get
    building.above_grade_volume = Geometry.get_above_grade_finished_volume(model, true)
    building.ag_ext_wall_area = Geometry.calculate_above_grade_exterior_wall_area(model_spaces, false)
    model.getThermalZones.each do |thermal_zone|
      if Geometry.is_garage(thermal_zone)
        building.garage = ZoneInfo.new(thermal_zone, Geometry.get_height_of_spaces(thermal_zone.spaces), UnitConversions.convert(thermal_zone.floorArea,"m^2","ft^2"), Geometry.get_zone_volume(thermal_zone, false, runner), Geometry.get_z_origin_for_zone(thermal_zone), nil, nil)
      elsif Geometry.is_unfinished_basement(thermal_zone)
        building.unfinished_basement = ZoneInfo.new(thermal_zone, Geometry.get_height_of_spaces(thermal_zone.spaces), UnitConversions.convert(thermal_zone.floorArea,"m^2","ft^2"), Geometry.get_zone_volume(thermal_zone, false, runner), Geometry.get_z_origin_for_zone(thermal_zone), infil.unfinished_basement_ach, nil)
      elsif Geometry.is_crawl(thermal_zone)
        building.crawlspace = ZoneInfo.new(thermal_zone, Geometry.get_height_of_spaces(thermal_zone.spaces), UnitConversions.convert(thermal_zone.floorArea,"m^2","ft^2"), Geometry.get_zone_volume(thermal_zone, false, runner), Geometry.get_z_origin_for_zone(thermal_zone), infil.crawl_ach, nil)
      elsif Geometry.is_pier_beam(thermal_zone)
        building.pierbeam = ZoneInfo.new(thermal_zone, Geometry.get_height_of_spaces(thermal_zone.spaces), UnitConversions.convert(thermal_zone.floorArea,"m^2","ft^2"), Geometry.get_zone_volume(thermal_zone, false, runner), Geometry.get_z_origin_for_zone(thermal_zone), infil.pier_beam_ach, nil)
      elsif Geometry.is_unfinished_attic(thermal_zone)
        building.unfinished_attic = ZoneInfo.new(thermal_zone, Geometry.get_height_of_spaces(thermal_zone.spaces), UnitConversions.convert(thermal_zone.floorArea,"m^2","ft^2"), Geometry.get_zone_volume(thermal_zone, false, runner), Geometry.get_z_origin_for_zone(thermal_zone), nil, infil.unfinished_attic_sla)
      end
    end
    building.ffa = Geometry.get_finished_floor_area_from_spaces(model_spaces, true, runner)
    return false if building.ffa.nil?
    building.ag_ffa = Geometry.get_above_grade_finished_floor_area_from_spaces(model_spaces, true, runner)
    return false if building.ag_ffa.nil?

    wind_speed = process_wind_speed_correction(infil.terrain, infil.shelter_coef, Geometry.get_closest_neighbor_distance(model), building.building_height)
    if not process_infiltration(model, infil, wind_speed, building, weather)
      return false
    end
    
    # Output Variables

    output_vars = create_output_vars(model)
    
    # Global sensors
    
    pbar_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, output_vars["Site Outdoor Air Barometric Pressure"])
    pbar_sensor.setName("#{Constants.ObjectNameNaturalVentilation} pb s")

    vwind_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, output_vars["Site Wind Speed"])
    vwind_sensor.setName("#{Constants.ObjectNameAirflow} vw s")
    
    wout_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, output_vars["Site Outdoor Air Humidity Ratio"])
    wout_sensor.setName("#{Constants.ObjectNameNaturalVentilation} wt s")
    
    # Adiabatic construction for ducts
    
    adiabatic_mat = OpenStudio::Model::MasslessOpaqueMaterial.new(model, "Rough", 176.1)
    adiabatic_mat.setName("Adiabatic")
    adiabatic_const = OpenStudio::Model::Construction.new(model)
    adiabatic_const.setName("AdiabaticConst")
    adiabatic_const.insertLayer(0, adiabatic_mat)

    units.each_with_index do |unit, unit_index|

      obj_name_airflow = Constants.ObjectNameAirflow(unit.name.to_s.gsub("unit ", "")).gsub("|","_")
      obj_name_infil = Constants.ObjectNameInfiltration(unit.name.to_s.gsub("unit ", "")).gsub("|","_")
      obj_name_natvent = Constants.ObjectNameNaturalVentilation(unit.name.to_s.gsub("unit ", "")).gsub("|","_")
      obj_name_mech_vent = Constants.ObjectNameMechanicalVentilation(unit.name.to_s.gsub("unit ", "")).gsub("|","_")
      obj_name_ducts = Constants.ObjectNameDucts(unit.name.to_s.gsub("unit ", "")).gsub("|","_")

      nbeds, nbaths = Geometry.get_unit_beds_baths(model, unit, runner)
      if nbeds.nil? or nbaths.nil?
        return false
      end
      unit_ag_ext_wall_area = Geometry.calculate_above_grade_exterior_wall_area(unit.spaces, false)
      unit_ag_ffa = Geometry.get_above_grade_finished_floor_area_from_spaces(unit.spaces, false, runner)
      unit_ffa = Geometry.get_finished_floor_area_from_spaces(unit.spaces, false, runner)
      unit_window_area = Geometry.get_window_area_from_spaces(unit.spaces, false)
      
      sch_unit_index = Geometry.get_unit_dhw_sched_index(model, unit, runner)

      # Determine geometry for spaces and zones that are unit specific
      unit_living = nil
      unit_finished_basement = nil
      Geometry.get_thermal_zones_from_spaces(unit.spaces).each do |thermal_zone|
        if Geometry.is_finished_basement(thermal_zone)
          unit_finished_basement = ZoneInfo.new(thermal_zone, Geometry.get_height_of_spaces(thermal_zone.spaces), UnitConversions.convert(thermal_zone.floorArea,"m^2","ft^2"), Geometry.get_zone_volume(thermal_zone, false, runner), Geometry.get_z_origin_for_zone(thermal_zone), infil.finished_basement_ach, nil)
        elsif Geometry.is_living(thermal_zone)
          unit_living = ZoneInfo.new(thermal_zone, Geometry.get_height_of_spaces(thermal_zone.spaces), UnitConversions.convert(thermal_zone.floorArea,"m^2","ft^2"), Geometry.get_zone_volume(thermal_zone, false, runner), Geometry.get_z_origin_for_zone(thermal_zone), nil, nil)
        end
      end
      
      # Search for mini-split heat pump
      unit_has_mshp = HVAC.has_mshp(model, runner, unit_living.zone)
      
      # Determine if forced air equipment
      has_forced_air_equipment = false
      model.getAirLoopHVACs.each do |air_loop|
        next unless air_loop.thermalZones.include? unit_living.zone
        has_forced_air_equipment = true
      end
      if unit_has_mshp
        has_forced_air_equipment = true
      end

      success, infil_output = process_infiltration_for_unit(model, runner, obj_name_infil, infil, wind_speed, building, weather, unit_ag_ffa, unit_ag_ext_wall_area, unit_living, unit_finished_basement)
      return false if not success
      
      success, mv_output = process_mech_vent_for_unit(model, runner, obj_name_mech_vent, unit, infil.is_existing_home, infil_output.a_o, mech_vent, ducts, building, nbeds, nbaths, weather, unit_ffa, unit_living, units.size, has_forced_air_equipment)
      return false if not success
      
      sucess, nv_output = process_nat_vent_for_unit(model, runner, obj_name_natvent, nat_vent, wind_speed, infil, building, weather, unit_window_area, unit_living)
      return false if not success
      
      success, ducts_output = process_ducts_for_unit(model, runner, obj_name_ducts, ducts, building, unit, unit_index, unit_ffa, unit_has_mshp, unit_living, unit_finished_basement, has_forced_air_equipment)
      return false if not success
      
      # Common sensors

      tin_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, output_vars["Zone Mean Air Temperature"])
      tin_sensor.setName("#{obj_name_airflow} tin s")
      tin_sensor.setKeyName(unit_living.zone.name.to_s)

      tout_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, output_vars["Zone Outdoor Air Drybulb Temperature"])
      tout_sensor.setName("#{obj_name_airflow} tt s")
      tout_sensor.setKeyName(unit_living.zone.name.to_s)

      # Common global variables

      duct_lk_supply_fan_equiv_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "#{obj_name_ducts} lk sup fan equiv".gsub(" ","_"))
      duct_lk_return_fan_equiv_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "#{obj_name_ducts} lk ret fan equiv".gsub(" ","_"))
      
      # Update model
      
      nv_program = create_nat_vent_objects(model, runner, output_vars, obj_name_natvent, unit_living, nat_vent, nv_output, tin_sensor, tout_sensor, pbar_sensor, vwind_sensor, wout_sensor)
      
      duct_program, cfis_program, cfis_output = create_ducts_objects(model, runner, output_vars, obj_name_ducts, unit_living, unit_finished_basement, ducts, mech_vent, ducts_output, tin_sensor, pbar_sensor, duct_lk_supply_fan_equiv_var, duct_lk_return_fan_equiv_var, has_forced_air_equipment, unit_has_mshp, adiabatic_const)
      
      infil_program = create_infil_mech_vent_objects(model, runner, output_vars, obj_name_infil, obj_name_mech_vent, unit_living, infil, mech_vent, wind_speed, mv_output, infil_output, tin_sensor, tout_sensor, vwind_sensor, duct_lk_supply_fan_equiv_var, duct_lk_return_fan_equiv_var, cfis_output, sch_unit_index, nbeds)
      
      create_ems_program_managers(model, infil_program, nv_program, cfis_program, 
                                  duct_program, obj_name_airflow, obj_name_ducts)
                                  
      # Store info for HVAC Sizing measure
      if not unit_living.ELA.nil?
        unit.setFeature(Constants.SizingInfoZoneInfiltrationELA(unit_living.zone), unit_living.ELA.to_f)
        unit.setFeature(Constants.SizingInfoZoneInfiltrationCFM(unit_living.zone), unit_living.inf_flow.to_f)
      else
        unit.setFeature(Constants.SizingInfoZoneInfiltrationELA(unit_living.zone), 0.0)
        unit.setFeature(Constants.SizingInfoZoneInfiltrationCFM(unit_living.zone), 0.0)
      end
      unless unit_finished_basement.nil?
        unit.setFeature(Constants.SizingInfoZoneInfiltrationCFM(unit_finished_basement.zone), unit_finished_basement.inf_flow)
      end

    end # end unit loop

    # Store info for HVAC Sizing measure
    units.each do |unit|
      unless building.crawlspace.nil?
        unit.setFeature(Constants.SizingInfoZoneInfiltrationCFM(building.crawlspace.zone), building.crawlspace.inf_flow.to_f)
      end
      unless building.pierbeam.nil?
        unit.setFeature(Constants.SizingInfoZoneInfiltrationCFM(building.pierbeam.zone), building.pierbeam.inf_flow.to_f)
      end
      unless building.unfinished_basement.nil?
        unit.setFeature(Constants.SizingInfoZoneInfiltrationCFM(building.unfinished_basement.zone), building.unfinished_basement.inf_flow.to_f)
      end
      unless building.unfinished_attic.nil?
        unit.setFeature(Constants.SizingInfoZoneInfiltrationCFM(building.unfinished_attic.zone), building.unfinished_attic.inf_flow)
      end
    end

    terrain = {Constants.TerrainOcean=>"Ocean",      # Ocean, Bayou flat country
               Constants.TerrainPlains=>"Country",   # Flat, open country
               Constants.TerrainRural=>"Country",    # Flat, open country
               Constants.TerrainSuburban=>"Suburbs", # Rough, wooded country, suburbs
               Constants.TerrainCity=>"City"}        # Towns, city outskirts, center of large cities
    model.getSite.setTerrain(terrain[infil.terrain])

    model.getScheduleDays.each do |obj| # remove any orphaned day schedules
      next if obj.directUseCount > 0
      obj.remove
    end

  end
  
  def self.remove(model, obj_name_airflow, obj_name_natvent,
                  obj_name_infil, obj_name_ducts, obj_name_mech_vent)
  
      # Remove existing EMS

      obj_name_airflow_underscore = obj_name_airflow.gsub(" ","_")
      obj_name_natvent_underscore = obj_name_natvent.gsub(" ","_")
      obj_name_infil_underscore = obj_name_infil.gsub(" ","_")
      obj_name_ducts_underscore = obj_name_ducts.gsub(" ","_")

      model.getEnergyManagementSystemProgramCallingManagers.each do |pcm|
        if (pcm.name.to_s.start_with? obj_name_airflow or
            pcm.name.to_s.start_with? obj_name_natvent or
            pcm.name.to_s.start_with? obj_name_infil or
            pcm.name.to_s.start_with? obj_name_ducts)
          pcm.remove
        end
      end

      model.getEnergyManagementSystemSensors.each do |sensor|
        if (sensor.name.to_s.start_with? obj_name_airflow_underscore or
            sensor.name.to_s.start_with? obj_name_natvent_underscore or
            sensor.name.to_s.start_with? obj_name_infil_underscore or
            sensor.name.to_s.start_with? obj_name_ducts_underscore)
          sensor.remove
        end
      end

      model.getEnergyManagementSystemActuators.each do |actuator|
        if (actuator.name.to_s.start_with? obj_name_airflow_underscore or
            actuator.name.to_s.start_with? obj_name_natvent_underscore or
            actuator.name.to_s.start_with? obj_name_infil_underscore or
            actuator.name.to_s.start_with? obj_name_ducts_underscore)
          actuatedComponent = actuator.actuatedComponent
          if actuatedComponent.is_a? OpenStudio::Model::OptionalModelObject # 2.4.0 or higher
            actuatedComponent = actuatedComponent.get
          end
          if actuatedComponent.to_ElectricEquipment.is_initialized
            actuatedComponent.to_ElectricEquipment.get.electricEquipmentDefinition.remove
          elsif actuatedComponent.to_OtherEquipment.is_initialized
            actuatedComponent.to_OtherEquipment.get.otherEquipmentDefinition.remove
          else
            actuatedComponent.remove
          end
          actuator.remove
        end
      end

      model.getEnergyManagementSystemPrograms.each do |program|
        if (program.name.to_s.start_with? obj_name_airflow_underscore or
            program.name.to_s.start_with? obj_name_natvent_underscore or
            program.name.to_s.start_with? obj_name_infil_underscore or
            program.name.to_s.start_with? obj_name_ducts_underscore)
          program.remove
        end
      end

      model.getEnergyManagementSystemOutputVariables.each do |output_var|
        if (output_var.name.to_s.start_with? obj_name_airflow or
            output_var.name.to_s.start_with? obj_name_natvent or
            output_var.name.to_s.start_with? obj_name_infil or
            output_var.name.to_s.start_with? obj_name_ducts)
          output_var.remove
        end
      end

      model.getEnergyManagementSystemSubroutines.each do |subroutine|
        if (subroutine.name.to_s.start_with? obj_name_airflow_underscore or
            subroutine.name.to_s.start_with? obj_name_natvent_underscore or
            subroutine.name.to_s.start_with? obj_name_infil_underscore or
            subroutine.name.to_s.start_with? obj_name_ducts_underscore)
          subroutine.remove
        end
      end

      model.getEnergyManagementSystemGlobalVariables.each do |ems_global_var|
        if (ems_global_var.name.to_s.start_with? obj_name_airflow_underscore or
            ems_global_var.name.to_s.start_with? obj_name_natvent_underscore or
            ems_global_var.name.to_s.start_with? obj_name_infil_underscore or
            ems_global_var.name.to_s.start_with? obj_name_ducts_underscore)
          ems_global_var.remove
        end
      end

      model.getEnergyManagementSystemInternalVariables.each do |ems_internal_var|
        if (ems_internal_var.name.to_s.start_with? obj_name_airflow_underscore or
            ems_internal_var.name.to_s.start_with? obj_name_natvent_underscore or
            ems_internal_var.name.to_s.start_with? obj_name_infil_underscore or
            ems_internal_var.name.to_s.start_with? obj_name_ducts_underscore)
          ems_internal_var.remove
        end
      end

      # Remove existing infiltration

      model.getScheduleRulesets.each do |schedule|
        next unless schedule.name.to_s.start_with? obj_name_infil
        schedule.remove
      end
      
      model.getSpaces.each do |space|
        space.spaceInfiltrationEffectiveLeakageAreas.each do |leakage_area|
          next unless leakage_area.name.to_s.start_with? obj_name_infil
          leakage_area.remove
        end
        space.spaceInfiltrationDesignFlowRates.each do |flow_rate|
          next unless flow_rate.name.to_s.start_with? obj_name_infil
          flow_rate.remove
        end
      end

      # Remove existing natural ventilation

      model.getScheduleRulesets.each do |schedule|
        next unless schedule.name.to_s.start_with? obj_name_natvent
        schedule.remove
      end

      # Remove existing mechanical ventilation

      model.getZoneHVACEnergyRecoveryVentilators.each do |erv|
        next unless erv.name.to_s.start_with? obj_name_mech_vent
        erv.remove
      end

      model.getScheduleRulesets.each do |schedule|
        next unless schedule.name.to_s.start_with? obj_name_mech_vent
        schedule.remove
      end

      model.getScheduleFixedIntervals.each do |schedule|
        next unless schedule.name.to_s.start_with? obj_name_mech_vent
        schedule.remove
      end
      
      # Remove existing ducts

      model.getThermalZones.each do |thermal_zone|
        next unless thermal_zone.name.to_s.start_with? obj_name_ducts
        thermal_zone.spaces.each do |space|
          space.surfaces.each do |surface|
            if surface.surfacePropertyConvectionCoefficients.is_initialized
              surface.surfacePropertyConvectionCoefficients.get.remove
            end
          end
          space.remove
        end
        thermal_zone.removeReturnPlenum
        thermal_zone.remove
      end
      
      # Remove adiabatic construction/material
      
      model.getLayeredConstructions.each do |construction|
        next unless construction.name.to_s == "AdiabaticConst"
        construction.layers.each do |material|
          material.remove
        end
        construction.remove
      end
  
  end

  private
  
  def self.create_output_vars(model)
    output_vars = {}
    
    output_var_names = ["Zone Outdoor Air Drybulb Temperature", "Site Outdoor Air Barometric Pressure", "Zone Mean Air Temperature", "Zone Air Relative Humidity", "Site Outdoor Air Humidity Ratio", "Zone Mean Air Humidity Ratio", "Site Wind Speed", "Schedule Value", "System Node Mass Flow Rate", "Fan Runtime Fraction", "System Node Current Density Volume Flow Rate", "System Node Temperature", "System Node Humidity Ratio", "Zone Air Temperature"]
    model_output_vars = model.getOutputVariables
    
    output_var_names.each do |output_var_name|
      output_var = nil
      # Already exists?
      model_output_vars.each do |model_output_var|
        if model_output_var.name.to_s == output_var_name
          output_var = model_output_var
        end
      end
      if output_var.nil?
        # Create new
        output_var = OpenStudio::Model::OutputVariable.new(output_var_name, model)
        output_var.setName(output_var_name)
      end
      output_vars[output_var_name] = output_var
    end
    
    return output_vars
  end
  
  def self.process_wind_speed_correction(terrain, shelter_coef, neighbors_min_nonzero_offset, building_height)

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
      wind_speed.ashrae_site_terrain_thickness = 460 # Towns, city outskirs, center of large cities
      wind_speed.ashrae_site_terrain_exponent = 0.33 # Towns, city outskirs, center of large cities
    end

    # Local Shielding
    if shelter_coef == Constants.Auto
      if neighbors_min_nonzero_offset == 0
        # Typical shelter for isolated rural house
        wind_speed.S_wo = 0.90
      elsif neighbors_min_nonzero_offset > building_height
        # Typical shelter caused by other building across the street
        wind_speed.S_wo = 0.70
      else
        # Typical shelter for urban buildings where sheltering obstacles
        # are less than one building height away.
        # Recommended by C.Christensen.
        wind_speed.S_wo = 0.50
      end
    else
      wind_speed.S_wo = shelter_coef.to_f
    end

    # S-G Shielding Coefficients are roughly 1/3 of AIM2 Shelter Coefficients
    wind_speed.shielding_coef = wind_speed.S_wo / 3.0

    return wind_speed

  end

  def self.process_infiltration(model, infil, wind_speed, building, weather)

    spaces = []
    spaces << building.garage if not building.garage.nil?
    spaces << building.unfinished_basement if not building.unfinished_basement.nil?
    spaces << building.crawlspace if not building.crawlspace.nil?
    spaces << building.pierbeam if not building.pierbeam.nil?
    spaces << building.unfinished_attic if not building.unfinished_attic.nil?

    unless building.garage.nil?
      building.garage.inf_method = @infMethodSG
      building.garage.hor_lk_frac = 0.4 # DOE-2 Default
      building.garage.neutral_level = 0.5 # DOE-2 Default
      building.garage.SLA = Airflow.get_infiltration_SLA_from_ACH50(infil.garage_ach50, 0.67, building.garage.area, building.garage.volume)
      building.garage.ACH = Airflow.get_infiltration_ACH_from_SLA(building.garage.SLA, 1.0, weather)
      building.garage.inf_flow = building.garage.ACH / UnitConversions.convert(1.0,"hr","min") * building.garage.volume # cfm
    end

    unless building.unfinished_basement.nil?
      building.unfinished_basement.inf_method = @infMethodRes # Used for constant ACH
      building.unfinished_basement.inf_flow = building.unfinished_basement.ACH / UnitConversions.convert(1.0,"hr","min") * building.unfinished_basement.volume
    end

    unless building.crawlspace.nil?
      building.crawlspace.inf_method = @infMethodRes
      building.crawlspace.inf_flow = building.crawlspace.ACH / UnitConversions.convert(1.0,"hr","min") * building.crawlspace.volume
    end

    unless building.pierbeam.nil?
      building.pierbeam.inf_method = @infMethodRes
      building.pierbeam.inf_flow = building.pierbeam.ACH / UnitConversions.convert(1.0,"hr","min") * building.pierbeam.volume
    end

    unless building.unfinished_attic.nil?
      building.unfinished_attic.inf_method = @infMethodSG
      building.unfinished_attic.hor_lk_frac = 0.75 # Same as Energy Gauge USA Attic Model
      building.unfinished_attic.neutral_level = 0.5 # DOE-2 Default
      building.unfinished_attic.ACH = Airflow.get_infiltration_ACH_from_SLA(building.unfinished_attic.SLA, 1.0, weather)
      building.unfinished_attic.inf_flow = building.unfinished_attic.ACH / UnitConversions.convert(1.0,"hr","min") * building.unfinished_attic.volume
    end
    
    process_infiltration_for_spaces(model, spaces, wind_speed)

    return true
    
  end

  def self.process_infiltration_for_unit(model, runner, obj_name_infil, infil, wind_speed, building, weather, unit_ag_ffa, unit_ag_ext_wall_area, unit_living, unit_finished_basement)

    spaces = []
    spaces << unit_living
    spaces << unit_finished_basement if not unit_finished_basement.nil?

    outside_air_density = UnitConversions.convert(weather.header.LocalPressure,"atm","Btu/ft^3") / (Gas.Air.r * (weather.data.AnnualAvgDrybulb + 460.0))
    inf_conv_factor = 776.25 # [ft/min]/[inH2O^(1/2)*ft^(3/2)/lbm^(1/2)]
    delta_pref = 0.016 # inH2O

    if infil.living_ach50 > 0
      # Living Space Infiltration
      unit_living.inf_method = @infMethodASHRAE

      # Based on "Field Validation of Algebraic Equations for Stack and
      # Wind Driven Air Infiltration Calculations" by Walker and Wilson (1998)

      # Pressure Exponent
      n_i = 0.67

      # Calculate SLA for above-grade portion of the building
      building.SLA = Airflow.get_infiltration_SLA_from_ACH50(infil.living_ach50, n_i, building.ag_ffa, building.above_grade_volume)

      # Effective Leakage Area (ft^2)
      a_o = building.SLA * building.ag_ffa * (unit_ag_ext_wall_area/building.ag_ext_wall_area)

      # Calculate SLA for unit
      unit_living.SLA = a_o / unit_ag_ffa

      # Flow Coefficient (cfm/inH2O^n) (based on ASHRAE HoF)
      c_i = a_o * (2.0 / outside_air_density) ** 0.5 * delta_pref ** (0.5 - n_i) * inf_conv_factor

      if infil.has_flue_chimney
        y_i = 0.2 # Fraction of leakage through the flue; 0.2 is a "typical" value according to THE ALBERTA AIR INFIL1RATION MODEL, Walker and Wilson, 1990
        flue_height = building.building_height + 2.0 # ft
        s_wflue = 1.0 # Flue Shelter Coefficient
      else
        y_i = 0.0 # Fraction of leakage through the flu
        flue_height = 0.0 # ft
        s_wflue = 0.0 # Flue Shelter Coefficient
      end

      vented_crawl = false
      if (not building.crawlspace.nil? and building.crawlspace.ACH > 0) or (not building.pierbeam.nil? and building.pierbeam.ACH > 0)
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
      if leakkage_ceiling + leakage_walls + leakage_floor !=  1
        runner.registerError("Invalid air leakage distribution specified (#{leakkage_ceiling}, #{leakage_walls}, #{leakage_floor}); does not add up to 1.")
        return false
      end
      r_i = (leakkage_ceiling + leakage_floor)
      x_i = (leakkage_ceiling - leakage_floor)
      r_i = r_i * (1 - y_i)
      x_i = x_i * (1 - y_i)

      unit_living.hor_lk_frac = r_i
      z_f = flue_height / (unit_living.height + unit_living.coord_z)

      # Calculate Stack Coefficient
      m_o = (x_i + (2.0 * n_i + 1.0) * y_i) ** 2.0 / (2 - r_i)

      if m_o <=  1.0
        m_i = m_o # eq. 10
      else
        m_i = 1.0 # eq. 11
      end

      if infil.has_flue_chimney
        # Eq. 13
        x_c = r_i + (2.0 * (1.0 - r_i - y_i)) / (n_i + 1.0) - 2.0 * y_i * (z_f - 1.0) ** n_i
        # Additive flue function, Eq. 12
        f_i = n_i * y_i * (z_f - 1.0) ** ((3.0 * n_i - 1.0) / 3.0) * (1.0 - (3.0 * (x_c - x_i) ** 2.0 * r_i ** (1 - n_i)) / (2.0 * (z_f + 1.0)))
      else
        # Critical value of ceiling-floor leakage difference where the
        # neutral level is located at the ceiling (eq. 13)
        x_c = r_i + (2.0 * (1.0 - r_i - y_i)) / (n_i + 1.0)
        # Additive flue function (eq. 12)
        f_i = 0.0
      end

      f_s = ((1.0 + n_i * r_i) / (n_i + 1.0)) * (0.5 - 0.5 * m_i ** (1.2)) ** (n_i + 1.0) + f_i

      stack_coef = f_s * (UnitConversions.convert(outside_air_density * Constants.g * unit_living.height,"lbm/(ft*s^2)","inH2O") / (Constants.AssumedInsideTemp + 460.0)) ** n_i # inH2O^n/R^n

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
        x_x = 1.0 - (((x_i - x_s) / (2.0 - r_i)) ** 2.0) ** 0.75
        # Wind factor (eq. 20)
        f_w = 0.19 * (2.0 - n_i) * x_x * r_x * y_x

      else

        j_i = (x_i + r_i + 2.0 * y_i) / 2.0
        f_w = 0.19 * (2.0 - n_i) * (1.0 - ((x_i + r_i) / 2.0) ** (1.5 - y_i)) - y_i / 4.0 * (j_i - 2.0 * y_i * j_i ** 4.0)

      end

      wind_coef = f_w * UnitConversions.convert(outside_air_density / 2.0,"lbm/ft^3","inH2O/mph^2") ** n_i # inH2O^n/mph^2n

      unit_living.ACH = Airflow.get_infiltration_ACH_from_SLA(unit_living.SLA, building.stories, weather)

      # Convert living space ACH to cfm:
      unit_living.inf_flow = unit_living.ACH / UnitConversions.convert(1.0,"hr","min") * unit_living.volume # cfm

    end

    unless unit_finished_basement.nil?
      unit_finished_basement.inf_method = @infMethodRes # Used for constant ACH
      unit_finished_basement.inf_flow = unit_finished_basement.ACH / UnitConversions.convert(1.0,"hr","min") * unit_finished_basement.volume
    end
    
    process_infiltration_for_spaces(model, spaces, wind_speed)
    
    infil_output = InfiltrationOutput.new(a_o, c_i, n_i, stack_coef, wind_coef, y_i, s_wflue)
    return true, infil_output

  end
  
  def self.process_infiltration_for_spaces(model, spaces, wind_speed)
  
    spaces.each do |space|

      space.f_t_SG = wind_speed.site_terrain_multiplier * ((space.height + space.coord_z) / 32.8) ** wind_speed.site_terrain_exponent / (wind_speed.terrain_multiplier * (wind_speed.height / 32.8) ** wind_speed.terrain_exponent)

      if space.inf_method == @infMethodSG
        space.f_s_SG = 2.0 / 3.0 * (1 + space.hor_lk_frac / 2.0) * (2.0 * space.neutral_level * (1.0 - space.neutral_level)) ** 0.5 / (space.neutral_level ** 0.5 + (1.0 - space.neutral_level) ** 0.5)
        space.f_w_SG = wind_speed.shielding_coef * (1.0 - space.hor_lk_frac) ** (1.0 / 3.0) * space.f_t_SG
        space.C_s_SG = space.f_s_SG ** 2.0 * Constants.g * space.height / (Constants.AssumedInsideTemp + 460.0)
        space.C_w_SG = space.f_w_SG ** 2.0
        space.ELA = space.SLA * space.area # ft^2
      elsif space.inf_method == @infMethodASHRAE
        space.ELA = space.SLA * space.area # ft^2
      end
      
      space.zone.spaces.each do |s|
        obj_name = "#{Constants.ObjectNameInfiltration}|#{s.name}"
        if space.inf_method == @infMethodRes and space.ACH.to_f > 0
          flow_rate = OpenStudio::Model::SpaceInfiltrationDesignFlowRate.new(model)
          flow_rate.setName(obj_name)
          flow_rate.setSchedule(model.alwaysOnDiscreteSchedule)
          flow_rate.setAirChangesperHour(space.ACH)
          flow_rate.setSpace(s)
        elsif space.inf_method == @infMethodSG and space.ELA.to_f > 0
          leakage_area = OpenStudio::Model::SpaceInfiltrationEffectiveLeakageArea.new(model)
          leakage_area.setName(obj_name)
          leakage_area.setSchedule(model.alwaysOnDiscreteSchedule)
          leakage_area.setEffectiveAirLeakageArea(UnitConversions.convert(space.ELA,"ft^2","cm^2"))
          leakage_area.setStackCoefficient(UnitConversions.convert(space.C_s_SG,"ft^2/(s^2*R)","L^2/(s^2*cm^4*K)"))
          leakage_area.setWindCoefficient(space.C_w_SG*0.01)
          leakage_area.setSpace(s)
        elsif space.inf_method == @infMethodASHRAE
          # nop
        end
      end

    end
    
  end
  
  def self.process_mech_vent_for_unit(model, runner, obj_name_mech_vent, unit, is_existing_home, ela, mech_vent, ducts, building, nbeds, nbaths, weather, unit_ffa, unit_living, num_units, has_forced_air_equipment)

    if mech_vent.type == Constants.VentTypeCFIS
      if not has_forced_air_equipment
        runner.registerError("A CFIS ventilation system has been selected but the building does not have central, forced air equipment.")
        return false
      end
    end
    
    # Get ASHRAE 62.2 required ventilation rate (excluding infiltration credit)
    ashrae_mv_without_infil_credit = Airflow.get_mech_vent_whole_house_cfm(1, nbeds, unit_ffa, mech_vent.ashrae_std)

    # Determine mechanical ventilation infiltration credit (per ASHRAE 62.2)
    rate_credit = 0 # default to no credit
    if mech_vent.infil_credit
        if mech_vent.ashrae_std == '2010' and is_existing_home
            # ASHRAE Standard 62.2 2010
            # Only applies to existing buildings
            # 2 cfm per 100ft^2 of occupiable floor area
            default_rate = 2.0 * unit_ffa / 100.0 # cfm
            # Half the excess infiltration rate above the default rate is credited toward mech vent:
            rate_credit = [(unit_living.inf_flow - default_rate) / 2.0, 0].max
        elsif mech_vent.ashrae_std == '2013' and num_units == 1
            # ASHRAE Standard 62.2 2013
            # Only applies to single-family homes (Section 8.2.1: "The required mechanical ventilation
            # rate shall not be reduced as described in Section 4.1.3.").
            nl = 1000.0 * ela / unit_living.area * (unit_living.height / 8.2) ** 0.4 # Normalized leakage, eq. 4.4
            qinf = nl * weather.data.WSF * unit_living.area / 7.3 # Effective annual average infiltration rate, cfm, eq. 4.5a
            rate_credit = [(2.0 / 3.0) * ashrae_mv_without_infil_credit, qinf].min
        end
    end
    
    # Apply infiltration credit (if any)
    ashrae_vent_rate = [ashrae_mv_without_infil_credit - rate_credit, 0.0].max # cfm
    # Apply fraction of ASHRAE value
    whole_house_vent_rate = mech_vent.frac_62_2 * ashrae_vent_rate # cfm

    # Spot Ventilation
    bathroom_exhaust = 50.0 # cfm, per HSP
    range_hood_exhaust = 100.0 # cfm, per HSP
    spot_fan_power = 0.3 # W/cfm/fan, per HSP

    bath_exhaust_sch_operation = 60.0 # min/day, per HSP
    range_hood_exhaust_operation = 60.0 # min/day, per HSP

    # Fraction of fan heat that goes to the space
    if mech_vent.type == Constants.VentTypeExhaust
      frac_fan_heat = 0.0 # Fan heat does not enter space
    elsif mech_vent.type == Constants.VentTypeSupply or mech_vent.type == Constants.VentTypeCFIS
      frac_fan_heat = 1.0 # Fan heat does enter space
    elsif mech_vent.type == Constants.VentTypeBalanced
      frac_fan_heat = 0.5 # Assumes supply fan heat enters space
    else
      frac_fan_heat = 0.0
    end
    
    #Get the clothes washer so we can use the day shift for the clothes dryer
    if mech_vent.dryer_exhaust > 0
      cw_day_shift = 0.0
      model.getElectricEquipments.each do |ee|
        next if ee.name.to_s != Constants.ObjectNameClothesWasher(unit.name.to_s)
        cw_day_shift = unit.getFeatureAsDouble(Constants.ClothesWasherDayShift(ee)).get
        break
      end
      dryer_exhaust_day_shift = cw_day_shift + 1.0 / 24.0
    end
    
    # Search for clothes dryer
    has_dryer = false
    (model.getElectricEquipments + model.getOtherEquipments).each do |equip|
      next unless equip.name.to_s == Constants.ObjectNameClothesDryer(Constants.FuelTypeElectric, unit.name.to_s) or equip.name.to_s == Constants.ObjectNameClothesDryer(Constants.FuelTypeGas, unit.name.to_s) or equip.name.to_s == Constants.ObjectNameClothesDryer(Constants.FuelTypePropane, unit.name.to_s)
      has_dryer = true
      break
    end
    
    if not has_dryer and mech_vent.dryer_exhaust > 0
      runner.registerWarning("No clothes dryer object was found in #{unit.name.to_s} but the clothes dryer exhaust specified is non-zero. Overriding clothes dryer exhaust to be zero.")
    end
    
    bathroom_hour_avg_exhaust = bathroom_exhaust * nbaths * bath_exhaust_sch_operation / 60.0 # cfm
    range_hood_hour_avg_exhaust = range_hood_exhaust * range_hood_exhaust_operation / 60.0 # cfm

    #--- Calculate HRV/ERV effectiveness values. Calculated here for use in sizing routines.

    apparent_sensible_effectiveness = 0.0
    sensible_effectiveness = 0.0
    latent_effectiveness = 0.0

    if mech_vent.type == Constants.VentTypeBalanced and mech_vent.sensible_efficiency > 0 and whole_house_vent_rate > 0
      # Must assume an operating condition (HVI seems to use CSA 439)
      t_sup_in = 0
      w_sup_in = 0.0028
      t_exh_in = 22
      w_exh_in = 0.0065
      cp_a = 1006
      p_fan = whole_house_vent_rate * mech_vent.fan_power # Watts

      m_fan = UnitConversions.convert(whole_house_vent_rate,"cfm","m^3/s") * 16.02 * Psychrometrics.rhoD_fT_w_P(UnitConversions.convert(t_sup_in,"C","F"), w_sup_in, 14.7) # kg/s

      # The following is derived from (taken from CSA 439):
      #    E_SHR = (m_sup,fan * Cp * (Tsup,out - Tsup,in) - P_sup,fan) / (m_exh,fan * Cp * (Texh,in - Tsup,in) + P_exh,fan)
      t_sup_out = t_sup_in + (mech_vent.sensible_efficiency * (m_fan * cp_a * (t_exh_in - t_sup_in) + p_fan) + p_fan) / (m_fan * cp_a)

      # Calculate the apparent sensible effectiveness
      apparent_sensible_effectiveness = (t_sup_out - t_sup_in) / (t_exh_in - t_sup_in)

      # Calculate the supply temperature before the fan
      t_sup_out_gross = t_sup_out - p_fan / (m_fan * cp_a)

      # Sensible effectiveness of the HX only
      sensible_effectiveness = (t_sup_out_gross - t_sup_in) / (t_exh_in - t_sup_in)

      if (sensible_effectiveness < 0.0) or (sensible_effectiveness > 1.0)
        runner.registerError("The calculated ERV/HRV sensible effectiveness is #{sensible_effectiveness} but should be between 0 and 1. Please revise ERV/HRV efficiency values.")
        return false
      end

      # Use summer test condition to determine the latent effectiveness since TRE is generally specified under the summer condition
      if mech_vent.total_efficiency > 0

        t_sup_in = 35.0
        w_sup_in = 0.0178
        t_exh_in = 24.0
        w_exh_in = 0.0092

        m_fan = UnitConversions.convert(whole_house_vent_rate,"cfm","m^3/s") * UnitConversions.convert(Psychrometrics.rhoD_fT_w_P(UnitConversions.convert(t_sup_in,"C","F"), w_sup_in, 14.7),"lbm/ft^3","kg/m^3") # kg/s

        t_sup_out_gross = t_sup_in - sensible_effectiveness * (t_sup_in - t_exh_in)
        t_sup_out = t_sup_out_gross + p_fan / (m_fan * cp_a)

        h_sup_in = Psychrometrics.h_fT_w_SI(t_sup_in, w_sup_in)
        h_exh_in = Psychrometrics.h_fT_w_SI(t_exh_in, w_exh_in)
        h_sup_out = h_sup_in - (mech_vent.total_efficiency * (m_fan * (h_sup_in - h_exh_in) + p_fan) + p_fan) / m_fan

        w_sup_out = Psychrometrics.w_fT_h_SI(t_sup_out, h_sup_out)
        latent_effectiveness = [0.0, (w_sup_out - w_sup_in) / (w_exh_in - w_sup_in)].max

        if (latent_effectiveness < 0.0) or (latent_effectiveness > 1.0)
          runner.registerError("The calculated ERV/HRV latent effectiveness is #{latent_effectiveness} but should be between 0 and 1. Please revise ERV/HRV efficiency values.")
          return false
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
    unit.setFeature(Constants.SizingInfoMechVentType, mech_vent.type)
    unit.setFeature(Constants.SizingInfoMechVentTotalEfficiency, mech_vent.total_efficiency.to_f)
    unit.setFeature(Constants.SizingInfoMechVentLatentEffectiveness, latent_effectiveness.to_f)
    unit.setFeature(Constants.SizingInfoMechVentApparentSensibleEffectiveness, apparent_sensible_effectiveness.to_f)
    unit.setFeature(Constants.SizingInfoMechVentWholeHouseRate, whole_house_vent_rate.to_f)
    
    mv_output = MechanicalVentilationOutput.new(frac_fan_heat, whole_house_vent_rate, bathroom_hour_avg_exhaust, range_hood_hour_avg_exhaust, spot_fan_power, latent_effectiveness, sensible_effectiveness, dryer_exhaust_day_shift, has_dryer)
    return true, mv_output

  end

  def self.process_nat_vent_for_unit(model, runner, obj_name_natvent, nat_vent, wind_speed, infil, building, weather, unit_window_area, unit_living)

    thermostatsetpointdualsetpoint = unit_living.zone.thermostatSetpointDualSetpoint

    # Get heating setpoints
    heatingSetpointWeekday = Array.new(24, Constants.NoHeatingSetpoint)
    heatingSetpointWeekend = Array.new(24, Constants.NoHeatingSetpoint)
    if thermostatsetpointdualsetpoint.is_initialized
      thermostatsetpointdualsetpoint.get.heatingSetpointTemperatureSchedule.get.to_Schedule.get.to_ScheduleRuleset.get.scheduleRules.each do |rule|
        if rule.applyMonday and rule.applyTuesday and rule.applyWednesday and rule.applyThursday and rule.applyFriday
          rule.daySchedule.values.each_with_index do |value, hour|
            if value > heatingSetpointWeekday[hour]
              heatingSetpointWeekday[hour] = UnitConversions.convert(value,"C","F")
            end
          end
        end
        if rule.applySaturday and rule.applySunday
          rule.daySchedule.values.each_with_index do |value, hour|
            if value > heatingSetpointWeekend[hour]
              heatingSetpointWeekend[hour] = UnitConversions.convert(value,"C","F")
            end
          end
        end
      end
    end

    # Get cooling setpoints
    coolingSetpointWeekday = Array.new(24, Constants.NoCoolingSetpoint)
    coolingSetpointWeekend = Array.new(24, Constants.NoCoolingSetpoint)
    if thermostatsetpointdualsetpoint.is_initialized
      thermostatsetpointdualsetpoint.get.coolingSetpointTemperatureSchedule.get.to_Schedule.get.to_ScheduleRuleset.get.scheduleRules.each do |rule|
        if rule.applyMonday and rule.applyTuesday and rule.applyWednesday and rule.applyThursday and rule.applyFriday
          rule.daySchedule.values.each_with_index do |value, hour|
            if value < coolingSetpointWeekday[hour]
              coolingSetpointWeekday[hour] = UnitConversions.convert(value,"C","F")
            end
          end
        end
        if rule.applySaturday and rule.applySunday
          rule.daySchedule.values.each_with_index do |value, hour|
            if value < coolingSetpointWeekend[hour]
              coolingSetpointWeekend[hour] = UnitConversions.convert(value,"C","F")
            end
          end
        end
      end
    end

    if heatingSetpointWeekday.all? {|x| x == Constants.NoHeatingSetpoint}
      runner.registerWarning("No heating setpoint schedule found. Assuming #{Constants.DefaultHeatingSetpoint} F for natural ventilation calculations.")
      ovlp_ssn_hourly_temp = Array.new(24, UnitConversions.convert(Constants.DefaultHeatingSetpoint + nat_vent.ovlp_offset,"F","C"))
    else
      ovlp_ssn_hourly_temp = Array.new(24, UnitConversions.convert([heatingSetpointWeekday.max, heatingSetpointWeekend.max].max + nat_vent.ovlp_offset,"F","C"))
    end
    if coolingSetpointWeekday.all? {|x| x == Constants.NoCoolingSetpoint}
      runner.registerWarning("No cooling setpoint schedule found. Assuming #{Constants.DefaultCoolingSetpoint} F for natural ventilation calculations.")
    end
    ovlp_ssn_hourly_weekend_temp = ovlp_ssn_hourly_temp

    # Get heating and cooling seasons
    heating_season, cooling_season = HVAC.calc_heating_and_cooling_seasons(model, weather, runner)
    if heating_season.nil? or cooling_season.nil?
        return false
    end

    # Specify an array of hourly lower-temperature-limits for natural ventilation
    htg_ssn_hourly_temp = Array.new
    coolingSetpointWeekday.each do |x|
      if x == Constants.NoCoolingSetpoint
        htg_ssn_hourly_temp << UnitConversions.convert(Constants.DefaultCoolingSetpoint - nat_vent.htg_offset,"F","C")
      else
        htg_ssn_hourly_temp << UnitConversions.convert(x - nat_vent.htg_offset,"F","C")
      end
    end
    htg_ssn_hourly_weekend_temp = Array.new
    coolingSetpointWeekend.each do |x|
      if x == Constants.NoCoolingSetpoint
        htg_ssn_hourly_weekend_temp << UnitConversions.convert(Constants.DefaultCoolingSetpoint - nat_vent.htg_offset,"F","C")
      else
        htg_ssn_hourly_weekend_temp << UnitConversions.convert(x - nat_vent.htg_offset,"F","C")
      end
    end

    clg_ssn_hourly_temp = Array.new
    heatingSetpointWeekday.each do |x|
      if x == Constants.NoHeatingSetpoint
        clg_ssn_hourly_temp << UnitConversions.convert(Constants.DefaultHeatingSetpoint + nat_vent.clg_offset,"F","C")
      else
        clg_ssn_hourly_temp << UnitConversions.convert(x + nat_vent.clg_offset,"F","C")
      end
    end
    clg_ssn_hourly_weekend_temp = Array.new
    heatingSetpointWeekend.each do |x|
      if x == Constants.NoHeatingSetpoint
        clg_ssn_hourly_weekend_temp << UnitConversions.convert(Constants.DefaultHeatingSetpoint + nat_vent.clg_offset,"F","C")
      else
        clg_ssn_hourly_weekend_temp << UnitConversions.convert(x + nat_vent.clg_offset,"F","C")
      end
    end

    # Explanation for FRAC-VENT-AREA equation:
    # From DOE22 Vol2-Dictionary: For VENT-METHOD = S-G, this is 0.6 times
    # the open window area divided by the floor area.
    # According to 2010 BA Benchmark, 33% of the windows on any facade will
    # be open at any given time and can only be opened to 20% of their area.

    area = 0.6 * unit_window_area * nat_vent.frac_windows_open * nat_vent.frac_window_area_openable # ft^2 (For S-G, this is 0.6*(open window area))
    max_rate = 20.0 # Air Changes per hour
    max_flow_rate = max_rate * unit_living.volume / UnitConversions.convert(1.0,"hr","min")
    nv_neutral_level = 0.5
    hor_vent_frac = 0.0
    f_s_nv = 2.0 / 3.0 * (1.0 + hor_vent_frac / 2.0) * (2.0 * nv_neutral_level * (1 - nv_neutral_level)) ** 0.5 / (nv_neutral_level ** 0.5 + (1 - nv_neutral_level) ** 0.5)
    f_w_nv = wind_speed.shielding_coef * (1 - hor_vent_frac) ** (1.0 / 3.0) * unit_living.f_t_SG
    c_s = f_s_nv ** 2.0 * Constants.g * unit_living.height / (Constants.AssumedInsideTemp + 460.0)
    c_w = f_w_nv ** 2.0

    season_type = []
    (0..11).to_a.each do |month|
      if heating_season[month] == 1.0 and cooling_season[month] == 0.0
        season_type << Constants.SeasonHeating
      elsif heating_season[month] == 0.0 and cooling_season[month] == 1.0
        season_type << Constants.SeasonCooling
      elsif heating_season[month] == 1.0 and cooling_season[month] == 1.0
        season_type << Constants.SeasonOverlap
      else
        season_type << Constants.SeasonNone
      end
    end

    temp_hourly_wkdy = []
    temp_hourly_wked = []
    season_type.each_with_index do |ssn_type, month|
      if ssn_type == Constants.SeasonHeating
        ssn_schedule_wkdy = htg_ssn_hourly_temp
        ssn_schedule_wked = htg_ssn_hourly_weekend_temp
      elsif ssn_type == Constants.SeasonCooling
        ssn_schedule_wkdy = clg_ssn_hourly_temp
        ssn_schedule_wked = clg_ssn_hourly_weekend_temp
      else
        ssn_schedule_wkdy = ovlp_ssn_hourly_temp
        ssn_schedule_wked = ovlp_ssn_hourly_weekend_temp
      end
      temp_hourly_wkdy << ssn_schedule_wkdy
      temp_hourly_wked << ssn_schedule_wked
    end
    
    temp_sch = HourlyByMonthSchedule.new(model, runner, obj_name_natvent + " temp schedule", temp_hourly_wkdy, temp_hourly_wked, normalize_values = false)
    
    nv_output = NaturalVentilationOutput.new(area, max_flow_rate, temp_sch, c_s, c_w, season_type)
    return true, nv_output

  end

  def self.process_ducts_for_unit(model, runner, obj_name_ducts, ducts, building, unit, unit_index, unit_ffa, unit_has_mshp, unit_living, unit_finished_basement, has_forced_air_equipment)

    # Validate Inputs
    if ducts.total_leakage < 0
      runner.registerError("Ducts: Total Leakage must be greater than or equal to 0.")
      return false
    end
    if ducts.supply_frac < 0 or ducts.supply_frac > 1
      runner.registerError("Ducts: Supply Leakage Fraction of Total must be greater than or equal to 0 and less than or equal to 1.")
      return false
    end
    if ducts.return_frac < 0 or ducts.return_frac > 1
      runner.registerError("Ducts: Return Leakage Fraction of Total must be greater than or equal to 0 and less than or equal to 1.")
      return false
    end
    if ducts.ah_supply_frac < 0 or ducts.ah_supply_frac > 1
      runner.registerError("Ducts: Supply Air Handler Leakage Fraction of Total must be greater than or equal to 0 and less than or equal to 1.")
      return false
    end
    if ducts.ah_return_frac < 0 or ducts.ah_return_frac > 1
      runner.registerError("Ducts: Return Air Handler Leakage Fraction of Total must be greater than or equal to 0 and less than or equal to 1.")
      return false
    end
    if ducts.r < 0
      runner.registerError("Ducts: Insulation Nominal R-Value must be greater than or equal to 0.")
      return false
    end
    if ducts.supply_area_mult < 0
      runner.registerError("Ducts: Supply Surface Area Multiplier must be greater than or equal to 0.")
      return false
    end
    if ducts.return_area_mult < 0
      runner.registerError("Ducts: Return Surface Area Multiplier must be greater than or equal to 0.")
      return false
    end
    
    if unit_has_mshp # has mshp
      miniSplitHPIsDucted = HVAC.has_ducted_mshp(model, runner, unit_living.zone)
      if ducts.location != "none" and not miniSplitHPIsDucted # if not ducted but specified ducts, override
        runner.registerWarning("No ducted HVAC equipment was found but ducts were specified. Overriding duct specification.")
        ducts.location = "none"
      elsif ducts.location == "none" and miniSplitHPIsDucted # if ducted but specified no ducts, error
        runner.registerError("Ducted mini-split heat pump selected but no ducts were selected.")
        return false
      end
    end

    no_ducted_equip = !HVAC.has_ducted_equipment(model, runner, unit_living.zone)
    if ducts.location != "none" and no_ducted_equip
      runner.registerWarning("No ducted HVAC equipment was found but ducts were specified. Overriding duct specification.")
      ducts.location = "none"
    end

    location_zone, location_name = get_location(ducts.location, unit, unit_index)

    if location_name == "none"
      location_zone = unit_living.zone
      location_name = unit_living.zone.name.to_s
    end

    num_stories = building.stories
    unless unit_finished_basement.nil?
      num_stories +=  1
    end

    if ducts.norm_leakage_25pa.nil?
      # Normalize values in case user inadvertently entered values that add up to the total duct leakage,
      # as opposed to adding up to 1
      sumFractionOfTotal = (ducts.supply_frac + ducts.return_frac + ducts.ah_supply_frac + ducts.ah_return_frac)
      if sumFractionOfTotal > 0
        ducts.supply_frac = ducts.supply_frac / sumFractionOfTotal
        ducts.return_frac = ducts.return_frac / sumFractionOfTotal
        ducts.ah_supply_frac = ducts.ah_supply_frac / sumFractionOfTotal
        ducts.ah_return_frac = ducts.ah_return_frac / sumFractionOfTotal
      end
      # Calculate actual leakages from percentages
      supply_leakage = ducts.supply_frac * ducts.total_leakage
      return_leakage = ducts.return_frac * ducts.total_leakage
      ah_supply_leakage = ducts.ah_supply_frac * ducts.total_leakage
      ah_return_leakage = ducts.ah_return_frac * ducts.total_leakage
    end

    # Fraction of ducts in primary duct location (remaining ducts are in above-grade conditioned space).
    location_frac_leakage = Airflow.get_location_frac_leakage(ducts.location_frac, num_stories)

    location_frac_conduction = location_frac_leakage
    ducts.num_returns = Airflow.get_num_returns(ducts.num_returns, num_stories)
    supply_surface_area = Airflow.get_duct_supply_surface_area(ducts.supply_area_mult, unit_ffa, num_stories)
    return_surface_area = Airflow.get_return_surface_area(ducts.return_area_mult, unit_ffa, num_stories, ducts.num_returns)

    # Calculate Duct UA value
    if location_name != unit_living.zone.name.to_s
      unconditioned_duct_area = supply_surface_area * location_frac_conduction
      supply_r = Airflow.get_duct_insulation_rvalue(ducts.r, true)
      return_r = Airflow.get_duct_insulation_rvalue(ducts.r, false)
      unconditioned_ua = unconditioned_duct_area / supply_r
      return_ua = return_surface_area / return_r
    else
      location_frac_conduction = 0
      unconditioned_ua = 0
      return_ua = 0
      supply_r = 0
      return_r = 0
    end

    # Calculate Duct Volume
    if location_name != unit_living.zone.name.to_s
      # Assume ducts are 3 ft by 1 ft, (8 is the perimeter)
      supply_volume = (unconditioned_duct_area / 8.0) * 3.0
      return_volume = (return_surface_area / 8.0) * 3.0
    else
      supply_volume = 0
      return_volume = 0
    end

    # This can't be zero. A value of zero causes weird sizing issues in DOE-2.
    direct_oa_supply_loss = 0.000001

    # Only if using the Fractional Leakage Option Type:
    if ducts.norm_leakage_25pa.nil?
      supply_loss = (location_frac_leakage * (supply_leakage - direct_oa_supply_loss) + (ah_supply_leakage + direct_oa_supply_loss))
      return_loss = return_leakage + ah_return_leakage
    end

    unless ducts.norm_leakage_25pa.nil?
      fan_AirFlowRate = 1000.0 # TODO: what should fan_AirFlowRate be?
      ducts = calc_duct_leakage_from_test(ducts, unit_ffa, fan_AirFlowRate)
    end

    total_unbalance = (supply_loss - return_loss).abs

    if not location_name == unit_living.zone.name.to_s and not location_name == "none" and supply_loss > 0
      # Calculate d.frac_oa = fraction of unbalanced make-up air that is outside air
      if total_unbalance <=  0
        # Handle the exception for if there is no leakage unbalance.
        frac_oa = 0
      elsif not unit_finished_basement.nil? and unit_finished_basement.zone == location_zone
        frac_oa = direct_oa_supply_loss / total_unbalance
      elsif not building.unfinished_basement.nil? and building.unfinished_basement.zone == location_zone
        frac_oa = direct_oa_supply_loss / total_unbalance
      elsif not building.crawlspace.nil? and building.crawlspace.zone == location_zone and building.crawlspace.ACH == 0
        frac_oa = direct_oa_supply_loss / total_unbalance
      elsif not building.pierbeam.nil? and building.pierbeam.zone == location_zone and building.pierbeam.ACH == 0
        frac_oa = direct_oa_supply_loss / total_unbalance
      elsif not building.unfinished_attic.nil? and building.unfinished_attic.zone == location_zone and building.unfinished_attic.ACH == 0
        frac_oa = direct_oa_supply_loss / total_unbalance
      else
        # Assume that all of the unbalanced make-up air is driven infiltration from outdoors.
        # This assumes that the holes for attic ventilation are much larger than any attic bypasses.
        frac_oa = 1
      end
      # d.oa_duct_makeup =  fraction of the supply duct air loss that is made up by outside air (via return leakage)
      oa_duct_makeup = [frac_oa * total_unbalance / [supply_loss, return_loss].max, 1].min
    else
      frac_oa = 0
      oa_duct_makeup = 0
    end
    
    # Store info for HVAC Sizing measure
    unit.setFeature(Constants.SizingInfoDuctsSupplyRvalue, supply_r.to_f)
    unit.setFeature(Constants.SizingInfoDuctsReturnRvalue, return_r.to_f)
    unit.setFeature(Constants.SizingInfoDuctsSupplyLoss, supply_loss.to_f)
    unit.setFeature(Constants.SizingInfoDuctsReturnLoss, return_loss.to_f)
    unit.setFeature(Constants.SizingInfoDuctsSupplySurfaceArea, supply_surface_area.to_f)
    unit.setFeature(Constants.SizingInfoDuctsReturnSurfaceArea, return_surface_area.to_f)
    unit.setFeature(Constants.SizingInfoDuctsLocationZone, location_name)
    unit.setFeature(Constants.SizingInfoDuctsLocationFrac, location_frac_leakage.to_f)

    ducts_output = DuctsOutput.new(location_name, location_zone, return_volume, supply_loss, return_loss, frac_oa, total_unbalance, unconditioned_ua, return_ua)
    return true, ducts_output

  end

  def self.create_nat_vent_objects(model, runner, output_vars, obj_name_natvent, unit_living, nat_vent, nv_output, tin_sensor, tout_sensor, pbar_sensor, vwind_sensor, wout_sensor)
  
    avail_sch = OpenStudio::Model::ScheduleRuleset.new(model)
    avail_sch.setName(obj_name_natvent + " avail schedule")

    day_endm = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365]
    day_startm = [0, 1, 32, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335]

    time = []
    for h in 1..24
      time[h] = OpenStudio::Time.new(0,h,0,0)
    end

    (1..12).to_a.each do |m|

      date_s = OpenStudio::Date::fromDayOfYear(day_startm[m])
      date_e = OpenStudio::Date::fromDayOfYear(day_endm[m])

      if ((nv_output.season_type[m-1] == Constants.SeasonHeating and nat_vent.htg_season) or (nv_output.season_type[m-1] == Constants.SeasonCooling and nat_vent.clg_season) or (nv_output.season_type[m-1] == Constants.SeasonOverlap and nat_vent.ovlp_season)) and (nat_vent.num_weekdays + nat_vent.num_weekends !=  0)
        on_rule = OpenStudio::Model::ScheduleRule.new(avail_sch)
        on_rule.setName(obj_name_natvent + " availability schedule #{Schedule.allday_name} ruleset#{m} on")
        on_rule_day = on_rule.daySchedule
        on_rule_day.setName(obj_name_natvent + " availability schedule #{Schedule.allday_name}1 on")
        for h in 1..24
          on_rule_day.addValue(time[h],1)
        end
        if nat_vent.num_weekdays >= 1
          on_rule.setApplyMonday(true)
        end
        if nat_vent.num_weekdays >= 2
          on_rule.setApplyWednesday(true)
        end
        if nat_vent.num_weekdays >= 3
          on_rule.setApplyFriday(true)
        end
        if nat_vent.num_weekdays >= 4
          on_rule.setApplyTuesday(true)
        end
        if nat_vent.num_weekdays == 5
          on_rule.setApplyThursday(true)
        end
        if nat_vent.num_weekends >= 1
          on_rule.setApplySaturday(true)
        end
        if nat_vent.num_weekends == 2
          on_rule.setApplySunday(true)
        end
        on_rule.setStartDate(date_s)
        on_rule.setEndDate(date_e)
      else
        off_rule = OpenStudio::Model::ScheduleRule.new(avail_sch)
        off_rule.setName(obj_name_natvent + " availability schedule #{Schedule.allday_name} ruleset#{m} off")
        off_rule_day = off_rule.daySchedule
        off_rule_day.setName(obj_name_natvent + " availability schedule #{Schedule.allday_name}1 off")
        for h in 1..24
          off_rule_day.addValue(time[h],0)
        end
        off_rule.setApplyMonday(true)
        off_rule.setApplyTuesday(true)
        off_rule.setApplyWednesday(true)
        off_rule.setApplyThursday(true)
        off_rule.setApplyFriday(true)
        off_rule.setApplySaturday(true)
        off_rule.setApplySunday(true)
        off_rule.setStartDate(date_s)
        off_rule.setEndDate(date_e)
      end
    end
    
    # Sensors
    
    nvavail_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, output_vars["Schedule Value"])
    nvavail_sensor.setName("#{obj_name_natvent} nva s")
    nvavail_sensor.setKeyName(avail_sch.name.to_s)

    nvsp_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, output_vars["Schedule Value"])
    nvsp_sensor.setName("#{obj_name_natvent} sp s")
    nvsp_sensor.setKeyName(nv_output.temp_sch.schedule.name.to_s)
    
    # Actuator
    
    living_space = unit_living.zone.spaces[0]
    
    natvent_flow = OpenStudio::Model::SpaceInfiltrationDesignFlowRate.new(model)
    natvent_flow.setName(obj_name_natvent + " flow")
    natvent_flow.setSchedule(model.alwaysOnDiscreteSchedule)
    natvent_flow.setSpace(living_space)
    natvent_flow_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(natvent_flow, "Zone Infiltration", "Air Exchange Flow Rate")
    natvent_flow_actuator.setName("#{natvent_flow.name} act")
    
    # Program
    
    nv_program = OpenStudio::Model::EnergyManagementSystemProgram.new(model)
    nv_program.setName(obj_name_natvent + " program")
    nv_program.addLine("Set Tdiff = #{tin_sensor.name}-#{tout_sensor.name}")
    nv_program.addLine("Set dT = (@Abs Tdiff)")
    nv_program.addLine("Set pt = (@RhFnTdbWPb #{tout_sensor.name} #{wout_sensor.name} #{pbar_sensor.name})")
    nv_program.addLine("Set NVA = #{UnitConversions.convert(nv_output.area,"ft^2","cm^2")}")
    nv_program.addLine("Set Cs = #{UnitConversions.convert(nv_output.c_s,"ft^2/(s^2*R)","L^2/(s^2*cm^4*K)")}")
    nv_program.addLine("Set Cw = #{nv_output.c_w*0.01}")
    nv_program.addLine("Set MNV = #{UnitConversions.convert(nv_output.max_flow_rate,"cfm","m^3/s")}")
    nv_program.addLine("Set MHR = #{nat_vent.max_oa_hr}")
    nv_program.addLine("Set MRH = #{nat_vent.max_oa_rh}")
    nv_program.addLine("Set temp1 = (#{nvavail_sensor.name}*NVA)")
    nv_program.addLine("Set SGNV = temp1*((((Cs*dT)+(Cw*(#{vwind_sensor.name}^2)))^0.5)/1000)")
    nv_program.addLine("If (#{wout_sensor.name}<MHR) && (pt<MRH) && (#{tin_sensor.name}>#{nvsp_sensor.name})")
    nv_program.addLine("  Set temp2 = (#{tin_sensor.name}-#{nvsp_sensor.name})")
    nv_program.addLine("  Set NVadj1 = temp2/(#{tin_sensor.name}-#{tout_sensor.name})")
    nv_program.addLine("  Set NVadj2 = (@Min NVadj1 1)")
    nv_program.addLine("  Set NVadj3 = (@Max NVadj2 0)")
    nv_program.addLine("  Set NVadj = SGNV*NVadj3")
    nv_program.addLine("  Set #{natvent_flow_actuator.name} = (@Min NVadj MNV)")
    nv_program.addLine("Else")
    nv_program.addLine("  Set #{natvent_flow_actuator.name} = 0")
    nv_program.addLine("EndIf")
    
    return nv_program
    
  end

  def self.create_ducts_objects(model, runner, output_vars, obj_name_ducts, unit_living, unit_finished_basement, ducts, mech_vent, ducts_output, tin_sensor, pbar_sensor, duct_lk_supply_fan_equiv_var, duct_lk_return_fan_equiv_var, has_forced_air_equipment, unit_has_mshp, adiabatic_const)
    
    win_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, output_vars["Zone Mean Air Humidity Ratio"])
    win_sensor.setName("#{obj_name_ducts} win s")
    win_sensor.setKeyName(unit_living.zone.name.to_s)
      
    ra_duct_zone = OpenStudio::Model::ThermalZone.new(model)
    ra_duct_zone.setName(obj_name_ducts + " ret air zone")
    ra_duct_zone.setVolume(UnitConversions.convert(ducts_output.return_volume,"ft^3","m^3"))

    sw_point = OpenStudio::Point3d.new(0, 74, 0)
    nw_point = OpenStudio::Point3d.new(0, 75, 0)
    ne_point = OpenStudio::Point3d.new(1, 75, 0)
    se_point = OpenStudio::Point3d.new(1, 74, 0)
    ra_duct_polygon = Geometry.make_polygon(sw_point, nw_point, ne_point, se_point)

    ra_space = OpenStudio::Model::Space::fromFloorPrint(ra_duct_polygon, 1, model)
    ra_space = ra_space.get
    ra_space.setName(obj_name_ducts + " ret air space")
    ra_space.setThermalZone(ra_duct_zone)

    ra_space.surfaces.each do |surface|
      surface.setConstruction(adiabatic_const)
      surface.setOutsideBoundaryCondition("Adiabatic")
      surface.setSunExposure("NoSun")
      surface.setWindExposure("NoWind")
      surface_property_convection_coefficients = OpenStudio::Model::SurfacePropertyConvectionCoefficients.new(surface)
      surface_property_convection_coefficients.setConvectionCoefficient1Location("Inside")
      surface_property_convection_coefficients.setConvectionCoefficient1Type("Value")
      surface_property_convection_coefficients.setConvectionCoefficient1(999)
    end

    if has_forced_air_equipment

      air_demand_inlet_node = nil
      supply_fan = nil
      living_zone_return_air_node = nil

      model.getAirLoopHVACs.each do |air_loop|
        next unless air_loop.thermalZones.include? unit_living.zone # get the correct air loop for this unit
        air_demand_inlet_node = air_loop.demandInletNode
        air_loop.supplyComponents.each do |supply_component|
          next unless supply_component.to_AirLoopHVACUnitarySystem.is_initialized
          air_loop_unitary = supply_component.to_AirLoopHVACUnitarySystem.get
          supply_fan = air_loop_unitary.supplyFan.get
        end
        break
      end

      if air_demand_inlet_node.nil? and supply_fan.nil? # for mshp
        model.getZoneHVACTerminalUnitVariableRefrigerantFlows.each do |tu_vrf|
          air_demand_inlet_node = tu_vrf.outletNode.get
          supply_fan = tu_vrf.supplyAirFan
        end
      end

      unit_living.zone.setReturnPlenum(ra_duct_zone)
      unless unit_finished_basement.nil?
        unit_finished_basement.zone.setReturnPlenum(ra_duct_zone)
      end

      if unit_living.zone.returnAirModelObject.is_initialized
        living_zone_return_air_node = unit_living.zone.returnAirModelObject.get
      end

    end
    
    if not ducts_output.location_name == unit_living.zone.name.to_s and not ducts_output.location_name == "none" and has_forced_air_equipment

      # Other equipment objects to cancel out the supply air leakage directly into the return plenum
      
      living_space = unit_living.zone.spaces[0]

      other_equip_def = OpenStudio::Model::OtherEquipmentDefinition.new(model)
      other_equip_def.setName("#{obj_name_ducts} sup s lk to lv equip")
      other_equip = OpenStudio::Model::OtherEquipment.new(other_equip_def)
      other_equip.setName(other_equip_def.name.to_s)
      other_equip.setFuelType("None")
      other_equip.setSchedule(model.alwaysOnDiscreteSchedule)
      other_equip.setSpace(living_space)
      supply_sens_lkage_to_liv_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(other_equip, "OtherEquipment", "Power Level")
      supply_sens_lkage_to_liv_actuator.setName("#{other_equip.name} act")

      other_equip_def = OpenStudio::Model::OtherEquipmentDefinition.new(model)
      other_equip_def.setName("#{obj_name_ducts} sup lat lk to lv equip")
      other_equip = OpenStudio::Model::OtherEquipment.new(other_equip_def)
      other_equip.setName(other_equip_def.name.to_s)
      other_equip.setFuelType("None")
      other_equip.setSchedule(model.alwaysOnDiscreteSchedule)
      other_equip.setSpace(living_space)
      supply_lat_lkage_to_liv_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(other_equip, "OtherEquipment", "Power Level")
      supply_lat_lkage_to_liv_actuator.setName("#{other_equip.name} act")

      # Supply duct conduction load added to the living space
      other_equip_def = OpenStudio::Model::OtherEquipmentDefinition.new(model)
      other_equip_def.setName("#{obj_name_ducts} sup d cn to lv equip")
      other_equip = OpenStudio::Model::OtherEquipment.new(other_equip_def)
      other_equip.setName(other_equip_def.name.to_s)
      other_equip.setFuelType("None")
      other_equip.setSchedule(model.alwaysOnDiscreteSchedule)
      other_equip.setSpace(living_space)
      supply_duct_cond_to_liv_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(other_equip, "OtherEquipment", "Power Level")
      supply_duct_cond_to_liv_actuator.setName("#{other_equip.name} act")

      # Supply duct conduction impact on the air handler zone.
      other_equip_def = OpenStudio::Model::OtherEquipmentDefinition.new(model)
      other_equip_def.setName("#{obj_name_ducts} sup d cn to ah equip")
      other_equip = OpenStudio::Model::OtherEquipment.new(other_equip_def)
      other_equip.setName(other_equip_def.name.to_s)
      other_equip.setFuelType("None")
      other_equip.setSchedule(model.alwaysOnDiscreteSchedule)
      other_equip.setSpace(ducts_output.location_zone.spaces[0])
      supply_duct_cond_to_ah_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(other_equip, "OtherEquipment", "Power Level")
      supply_duct_cond_to_ah_actuator.setName("#{other_equip.name} act")

      # Return duct conduction load added to the return plenum zone
      other_equip_def = OpenStudio::Model::OtherEquipmentDefinition.new(model)
      other_equip_def.setName("#{obj_name_ducts} ret d cn to pl equip")
      other_equip = OpenStudio::Model::OtherEquipment.new(other_equip_def)
      other_equip.setName(other_equip_def.name.to_s)
      other_equip.setFuelType("None")
      other_equip.setSchedule(model.alwaysOnDiscreteSchedule)
      unit_has_mshp ? other_equip.setSpace(living_space) : other_equip.setSpace(ra_space) # mini-split returns to the living space
      return_duct_cond_to_plenum_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(other_equip, "OtherEquipment", "Power Level")
      return_duct_cond_to_plenum_actuator.setName("#{other_equip.name} act")

      # Return duct conduction impact on the air handler zone.
      other_equip_def = OpenStudio::Model::OtherEquipmentDefinition.new(model)
      other_equip_def.setName("#{obj_name_ducts} ret d cn to ah equip")
      other_equip = OpenStudio::Model::OtherEquipment.new(other_equip_def)
      other_equip.setName(other_equip_def.name.to_s)
      other_equip.setFuelType("None")
      other_equip.setSchedule(model.alwaysOnDiscreteSchedule)
      other_equip.setSpace(ducts_output.location_zone.spaces[0])
      return_duct_cond_to_ah_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(other_equip, "OtherEquipment", "Power Level")
      return_duct_cond_to_ah_actuator.setName("#{other_equip.name} act")

      # Supply duct sensible leakage impact on the air handler zone.
      other_equip_def = OpenStudio::Model::OtherEquipmentDefinition.new(model)
      other_equip_def.setName("#{obj_name_ducts} sup s lk to ah equip")
      other_equip = OpenStudio::Model::OtherEquipment.new(other_equip_def)
      other_equip.setName(other_equip_def.name.to_s)
      other_equip.setFuelType("None")
      other_equip.setSchedule(model.alwaysOnDiscreteSchedule)
      other_equip.setSpace(ducts_output.location_zone.spaces[0])
      supply_sens_lkage_to_ah_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(other_equip, "OtherEquipment", "Power Level")
      supply_sens_lkage_to_ah_actuator.setName("#{other_equip.name} act")

      # Supply duct latent leakage impact on the air handler zone.
      other_equip_def = OpenStudio::Model::OtherEquipmentDefinition.new(model)
      other_equip_def.setName("#{obj_name_ducts} sup lat lk to ah equip")
      other_equip = OpenStudio::Model::OtherEquipment.new(other_equip_def)
      other_equip.setName(other_equip_def.name.to_s)
      other_equip.setFuelType("None")
      other_equip.setSchedule(model.alwaysOnDiscreteSchedule)
      other_equip.setSpace(ducts_output.location_zone.spaces[0])
      supply_lat_lkage_to_ah_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(other_equip, "OtherEquipment", "Power Level")
      supply_lat_lkage_to_ah_actuator.setName("#{other_equip.name} act")

      # Return duct sensible leakage impact on the return plenum
      other_equip_def = OpenStudio::Model::OtherEquipmentDefinition.new(model)
      other_equip_def.setName("#{obj_name_ducts} ret s lk equip")
      other_equip = OpenStudio::Model::OtherEquipment.new(other_equip_def)
      other_equip.setName(other_equip_def.name.to_s)
      other_equip.setFuelType("None")
      other_equip.setSchedule(model.alwaysOnDiscreteSchedule)
      unit_has_mshp ? other_equip.setSpace(living_space) : other_equip.setSpace(ra_space) # mini-split returns to the living space
      return_sens_lkage_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(other_equip, "OtherEquipment", "Power Level")
      return_sens_lkage_actuator.setName("#{other_equip.name} act")

      # Return duct latent leakage impact on the return plenum
      other_equip_def = OpenStudio::Model::OtherEquipmentDefinition.new(model)
      other_equip_def.setName("#{obj_name_ducts} ret lat lk equip")
      other_equip = OpenStudio::Model::OtherEquipment.new(other_equip_def)
      other_equip.setName(other_equip_def.name.to_s)
      other_equip.setFuelType("None")
      other_equip.setSchedule(model.alwaysOnDiscreteSchedule)
      unit_has_mshp ? other_equip.setSpace(living_space) : other_equip.setSpace(ra_space) # mini-split returns to the living space
      return_lat_lkage_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(other_equip, "OtherEquipment", "Power Level")
      return_lat_lkage_actuator.setName("#{other_equip.name} act")

      # Two objects are required to model the air exchange between the air handler zone and the living space since
      # ZoneMixing objects can not account for direction of air flow (both are controlled by EMS)

      # Accounts for lks from the AH zone to the Living zone

      zone_mixing_ah_to_living = OpenStudio::Model::ZoneMixing.new(unit_living.zone)
      zone_mixing_ah_to_living.setName("#{obj_name_ducts} ah to liv mix")
      zone_mixing_ah_to_living.setSourceZone(ducts_output.location_zone)
      liv_to_ah_flow_rate_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(zone_mixing_ah_to_living, "ZoneMixing", "Air Exchange Flow Rate")
      liv_to_ah_flow_rate_actuator.setName("#{zone_mixing_ah_to_living.name} act")

      zone_mixing_living_to_ah = OpenStudio::Model::ZoneMixing.new(ducts_output.location_zone)
      zone_mixing_living_to_ah.setName("#{obj_name_ducts} liv to ah mix")
      zone_mixing_living_to_ah.setSourceZone(unit_living.zone)
      liv_to_ah_flow_rate_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(zone_mixing_living_to_ah, "ZoneMixing", "Air Exchange Flow Rate")
      liv_to_ah_flow_rate_actuator.setName("#{zone_mixing_living_to_ah.name} act")

      # Sensors

      ah_mfr_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, output_vars["System Node Mass Flow Rate"])
      ah_mfr_sensor.setName("#{obj_name_ducts} ah mfr s")
      ah_mfr_sensor.setKeyName(air_demand_inlet_node.name.to_s)

      fan_rtf_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, output_vars["Fan Runtime Fraction"])
      fan_rtf_sensor.setName("#{obj_name_ducts} fan rtf s")
      fan_rtf_sensor.setKeyName(supply_fan.name.to_s)

      ah_vfr_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, output_vars["System Node Current Density Volume Flow Rate"])
      ah_vfr_sensor.setName("#{obj_name_ducts} ah vfr s")
      ah_vfr_sensor.setKeyName(air_demand_inlet_node.name.to_s)

      ah_tout_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, output_vars["System Node Temperature"])
      ah_tout_sensor.setName("#{obj_name_ducts} ah tt s")
      ah_tout_sensor.setKeyName(air_demand_inlet_node.name.to_s)

      if not living_zone_return_air_node.nil?
        ra_t_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, output_vars["System Node Temperature"])
        ra_t_sensor.setName("#{obj_name_ducts} ra t s")
        ra_t_sensor.setKeyName(living_zone_return_air_node.name.to_s)
      else
        ra_t_sensor = tin_sensor
      end

      ah_wout_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, output_vars["System Node Humidity Ratio"])
      ah_wout_sensor.setName("#{obj_name_ducts} ah wt s")
      ah_wout_sensor.setKeyName(air_demand_inlet_node.name.to_s)

      if not living_zone_return_air_node.nil?
        ra_w_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, output_vars["System Node Humidity Ratio"])
        ra_w_sensor.setName("#{obj_name_ducts} ra w s")
        ra_w_sensor.setKeyName(living_zone_return_air_node.name.to_s)
      else
        ra_w_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, output_vars["Zone Mean Air Humidity Ratio"])
        ra_w_sensor.setName("#{obj_name_ducts} ra w s")
        ra_w_sensor.setKeyName(unit_living.zone.name.to_s)
      end

      ah_t_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, output_vars["Zone Air Temperature"])
      ah_t_sensor.setName("#{obj_name_ducts} ah t s")
      ah_t_sensor.setKeyName(ducts_output.location_name)

      ah_w_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, output_vars["Zone Mean Air Humidity Ratio"])
      ah_w_sensor.setName("#{obj_name_ducts} ah w s")
      ah_w_sensor.setKeyName(ducts_output.location_name)

      # Global Variables

      ah_mfr_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "#{obj_name_ducts} ah mfr".gsub(" ","_"))
      fan_rtf_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "#{obj_name_ducts} fan rtf".gsub(" ","_"))
      ah_vfr_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "#{obj_name_ducts} ah vfr".gsub(" ","_"))
      ah_tout_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "#{obj_name_ducts} ah tt".gsub(" ","_"))
      ra_t_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "#{obj_name_ducts} ra t".gsub(" ","_"))
      ah_wout_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "#{obj_name_ducts} ah wt".gsub(" ","_"))
      ra_w_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "#{obj_name_ducts} ra w".gsub(" ","_"))
      ah_t_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "#{obj_name_ducts} ah t".gsub(" ","_"))
      ah_w_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "#{obj_name_ducts} ah w".gsub(" ","_"))

      supply_sens_lkage_to_liv_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "#{obj_name_ducts} sup s lk to lv".gsub(" ","_"))
      supply_lat_lkage_to_liv_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "#{obj_name_ducts} sup lat lk to lv".gsub(" ","_"))
      supply_duct_cond_to_liv_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "#{obj_name_ducts} sup d cn to lv".gsub(" ","_"))
      supply_duct_cond_to_ah_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "#{obj_name_ducts} sup d cn to ah".gsub(" ","_"))
      return_duct_cond_to_plenum_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "#{obj_name_ducts} ret d cn to pl".gsub(" ","_"))
      return_duct_cond_to_ah_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "#{obj_name_ducts} ret d cn to ah".gsub(" ","_"))
      supply_sens_lkage_to_ah_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "#{obj_name_ducts} sup s lk to ah".gsub(" ","_"))
      supply_lat_lkage_to_ah_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "#{obj_name_ducts} sup lat lk to ah".gsub(" ","_"))
      return_sens_lkage_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "#{obj_name_ducts} ret s lk".gsub(" ","_"))
      return_lat_lkage_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "#{obj_name_ducts} ret lat lk".gsub(" ","_"))
      liv_to_ah_flow_rate_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "#{obj_name_ducts} liv to ah".gsub(" ","_"))
      ah_to_liv_flow_rate_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "#{obj_name_ducts} ah to liv".gsub(" ","_"))

      if mech_vent.type == Constants.VentTypeCFIS
        cfis_t_sum_open_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "#{obj_name_ducts} cfis t sum open".gsub(" ","_")) # Sums the time during an hour the CFIS damper has been open
        cfis_on_for_hour_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "#{obj_name_ducts} cfis on for hour".gsub(" ","_")) # Flag to open the CFIS damper for the remainder of the hour
        cfis_f_damper_open_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "#{obj_name_ducts} cfis_f_open".gsub(" ","_")) # Fraction of timestep the CFIS damper is open. Used by infiltration and duct leakage programs

        max_supply_fan_mfr = OpenStudio::Model::EnergyManagementSystemInternalVariable.new(model, "Fan Maximum Mass Flow Rate")
        max_supply_fan_mfr.setName("#{obj_name_ducts} max_supply_fan_mfr".gsub(" ","_"))
        max_supply_fan_mfr.setInternalDataIndexKeyName(supply_fan.name.to_s)
      end

      # Duct Subroutine

      duct_subroutine = OpenStudio::Model::EnergyManagementSystemSubroutine.new(model)
      duct_subroutine.setName("#{obj_name_ducts} lk subrout")
      duct_subroutine.addLine("Set f_sup = #{ducts_output.supply_loss}")
      duct_subroutine.addLine("Set f_ret = #{ducts_output.return_loss}")
      duct_subroutine.addLine("Set f_OA = #{ducts_output.frac_oa * ducts_output.total_unbalance}")
      duct_subroutine.addLine("Set oafrate = f_OA * #{ah_vfr_var.name}")
      duct_subroutine.addLine("Set suplkfrate = f_sup * #{ah_vfr_var.name}")
      duct_subroutine.addLine("Set retlkfrate = f_ret * #{ah_vfr_var.name}")

      if ducts_output.return_loss > ducts_output.supply_loss
        # Supply air flow rate is greater than return flow rate
        # Living zone is pressurized in this case
        duct_subroutine.addLine("Set #{liv_to_ah_flow_rate_var.name} = (@Abs (retlkfrate-suplkfrate-oafrate))")
        duct_subroutine.addLine("Set #{ah_to_liv_flow_rate_var.name} = 0")
        duct_subroutine.addLine("Set #{duct_lk_supply_fan_equiv_var.name} = oafrate")
        duct_subroutine.addLine("Set #{duct_lk_return_fan_equiv_var.name} = 0")
      else
        # Living zone is depressurized in this case
        duct_subroutine.addLine("Set #{ah_to_liv_flow_rate_var.name} = (@Abs (suplkfrate-retlkfrate-oafrate))")
        duct_subroutine.addLine("Set #{liv_to_ah_flow_rate_var.name} = 0")
        duct_subroutine.addLine("Set #{duct_lk_supply_fan_equiv_var.name} = 0")
        duct_subroutine.addLine("Set #{duct_lk_return_fan_equiv_var.name} = oafrate")
      end

      if ducts_output.location_name != unit_living.zone.name.to_s
        duct_subroutine.addLine("If #{ah_mfr_var.name}>0")
        duct_subroutine.addLine("  Set h_SA = (@HFnTdbW #{ah_tout_var.name} #{ah_wout_var.name})")
        duct_subroutine.addLine("  Set h_AHZone = (@HFnTdbW #{ah_t_var.name} #{ah_w_var.name})")
        duct_subroutine.addLine("  Set h_RA = (@HFnTdbW #{ra_t_var.name} #{ra_w_var.name})")
        duct_subroutine.addLine("  Set h_fg = (@HfgAirFnWTdb #{ah_wout_var.name} #{ah_tout_var.name})")
        duct_subroutine.addLine("  Set SALeakageQtot = f_sup * #{ah_mfr_var.name}*(h_RA - h_SA)")
        duct_subroutine.addLine("  Set temp1 = h_fg*(#{ra_w_var.name}-#{ah_wout_var.name})")
        duct_subroutine.addLine("  Set #{supply_lat_lkage_to_liv_var.name} = f_sup*#{ah_mfr_var.name}*temp1")
        duct_subroutine.addLine("  Set #{supply_sens_lkage_to_liv_var.name} = SALeakageQtot-#{supply_lat_lkage_to_liv_var.name}")
        duct_subroutine.addLine("  Set eTm = (#{fan_rtf_var.name}/(#{ah_mfr_var.name}*1006.0))*#{UnitConversions.convert(ducts_output.unconditioned_ua,"Btu/(hr*F)","W/K").round(3)}")
        duct_subroutine.addLine("  Set eTm = 0-eTm")
        duct_subroutine.addLine("  If eTm <= -20")
        duct_subroutine.addLine("    Set tsup = #{ah_t_var.name}")
        duct_subroutine.addLine("  Else")
        duct_subroutine.addLine("    Set temp4 = #{ah_t_var.name}")
        duct_subroutine.addLine("    Set tsup = temp4+((#{ah_tout_var.name}-#{ah_t_var.name})*(@Exp eTm))")
        duct_subroutine.addLine("  EndIf")
        duct_subroutine.addLine("  Set temp5 = tsup-#{ah_tout_var.name}")
        duct_subroutine.addLine("  Set #{supply_duct_cond_to_liv_var.name} = #{ah_mfr_var.name}*1006.0*temp5")
        duct_subroutine.addLine("  Set #{supply_duct_cond_to_ah_var.name} = 0-#{supply_duct_cond_to_liv_var.name}")
        duct_subroutine.addLine("  Set eTm = (#{fan_rtf_var.name}/(#{ah_mfr_var.name}*1006.0))*#{UnitConversions.convert(ducts_output.return_ua,"Btu/(hr*F)","W/K").round(3)}")
        duct_subroutine.addLine("  Set eTm = 0-eTm")
        duct_subroutine.addLine("  If eTm <= -20")
        duct_subroutine.addLine("    Set tret = #{ah_t_var.name}")
        duct_subroutine.addLine("  Else")
        duct_subroutine.addLine("    Set temp6 = #{ah_t_var.name}")
        duct_subroutine.addLine("    Set tret = temp6+((#{ra_t_var.name}-#{ah_t_var.name})*(@Exp eTm))")
        duct_subroutine.addLine("  EndIf")
        duct_subroutine.addLine("  Set temp7 = tret-#{ra_t_var.name}")
        duct_subroutine.addLine("  Set #{return_duct_cond_to_plenum_var.name} = #{ah_mfr_var.name}*1006.0*temp7")
        duct_subroutine.addLine("  Set #{return_duct_cond_to_ah_var.name} = 0-#{return_duct_cond_to_plenum_var.name}")
        duct_subroutine.addLine("  Set #{return_lat_lkage_var.name} = 0")
        duct_subroutine.addLine("  Set temp2 = (#{ah_t_var.name}-#{ra_t_var.name})")
        duct_subroutine.addLine("  Set #{return_sens_lkage_var.name} = f_ret*#{ah_mfr_var.name}*1006.0*temp2")
        duct_subroutine.addLine("  Set QtotLeakToAHZn = f_sup*#{ah_mfr_var.name}*(h_SA-h_AHZone)")
        duct_subroutine.addLine("  Set temp3 = (#{ah_wout_var.name}-#{ah_w_var.name})")
        duct_subroutine.addLine("  Set #{supply_lat_lkage_to_ah_var.name} = f_sup*#{ah_mfr_var.name}*h_fg*temp3")
        duct_subroutine.addLine("  Set #{supply_sens_lkage_to_ah_var.name} = QtotLeakToAHZn-#{supply_lat_lkage_to_ah_var.name}")
        duct_subroutine.addLine("Else")
        duct_subroutine.addLine("  Set #{supply_lat_lkage_to_liv_var.name} = 0")
        duct_subroutine.addLine("  Set #{supply_sens_lkage_to_liv_var.name} = 0")
        duct_subroutine.addLine("  Set #{supply_duct_cond_to_liv_var.name} = 0")
        duct_subroutine.addLine("  Set #{supply_duct_cond_to_ah_var.name} = 0")
        duct_subroutine.addLine("  Set #{return_duct_cond_to_plenum_var.name} = 0")
        duct_subroutine.addLine("  Set #{return_duct_cond_to_ah_var.name} = 0")
        duct_subroutine.addLine("  Set #{return_lat_lkage_var.name} = 0")
        duct_subroutine.addLine("  Set #{return_sens_lkage_var.name} = 0")
        duct_subroutine.addLine("  Set #{supply_lat_lkage_to_ah_var.name} = 0")
        duct_subroutine.addLine("  Set #{supply_sens_lkage_to_ah_var.name} = 0")
        duct_subroutine.addLine("EndIf")
      else
        duct_subroutine.addLine("Set #{supply_lat_lkage_to_liv_var.name} = 0")
        duct_subroutine.addLine("Set #{supply_sens_lkage_to_liv_var.name} = 0")
        duct_subroutine.addLine("Set #{supply_duct_cond_to_liv_var.name} = 0")
        duct_subroutine.addLine("Set #{supply_duct_cond_to_ah_var.name} = 0")
        duct_subroutine.addLine("Set #{return_duct_cond_to_plenum_var.name} = 0")
        duct_subroutine.addLine("Set #{return_duct_cond_to_ah_var.name} = 0")
        duct_subroutine.addLine("Set #{return_lat_lkage_var.name} = 0")
        duct_subroutine.addLine("Set #{return_sens_lkage_var.name} = 0")
        duct_subroutine.addLine("Set #{supply_lat_lkage_to_ah_var.name} = 0")
        duct_subroutine.addLine("Set #{supply_sens_lkage_to_ah_var.name} = 0")
      end

      # Duct Program

      duct_program = OpenStudio::Model::EnergyManagementSystemProgram.new(model)
      duct_program.setName(obj_name_ducts + " program")
      duct_program.addLine("Set #{ah_mfr_var.name} = #{ah_mfr_sensor.name}")
      duct_program.addLine("Set #{fan_rtf_var.name} = #{fan_rtf_sensor.name}")
      duct_program.addLine("Set #{ah_vfr_var.name} = #{ah_vfr_sensor.name}")
      duct_program.addLine("Set #{ah_tout_var.name} = #{ah_tout_sensor.name}")
      duct_program.addLine("Set #{ah_wout_var.name} = #{ah_wout_sensor.name}")
      duct_program.addLine("Set #{ra_t_var.name} = #{ra_t_sensor.name}")
      duct_program.addLine("Set #{ra_w_var.name} = #{ra_w_sensor.name}")
      duct_program.addLine("Set #{ah_t_var.name} = #{ah_t_sensor.name}")
      duct_program.addLine("Set #{ah_w_var.name} = #{ah_w_sensor.name}")
      duct_program.addLine("Run #{duct_subroutine.name}")

      if mech_vent.type != Constants.VentTypeCFIS
        duct_program.addLine("Set #{supply_sens_lkage_to_liv_actuator.name} = #{supply_sens_lkage_to_liv_var.name}")
        duct_program.addLine("Set #{supply_lat_lkage_to_liv_actuator.name} = #{supply_lat_lkage_to_liv_var.name}")
        duct_program.addLine("Set #{supply_duct_cond_to_liv_actuator.name} = #{supply_duct_cond_to_liv_var.name}")
        duct_program.addLine("Set #{supply_duct_cond_to_ah_actuator.name} = #{supply_duct_cond_to_ah_var.name}")
        duct_program.addLine("Set #{supply_sens_lkage_to_ah_actuator.name} = #{supply_sens_lkage_to_ah_var.name}")
        duct_program.addLine("Set #{supply_lat_lkage_to_ah_actuator.name} = #{supply_lat_lkage_to_ah_var.name}")
        duct_program.addLine("Set #{return_sens_lkage_actuator.name} = #{return_sens_lkage_var.name}")
        duct_program.addLine("Set #{return_lat_lkage_actuator.name} = #{return_lat_lkage_var.name}")
        duct_program.addLine("Set #{return_duct_cond_to_plenum_actuator.name} = #{return_duct_cond_to_plenum_var.name}")
        duct_program.addLine("Set #{return_duct_cond_to_ah_actuator.name} = #{return_duct_cond_to_ah_var.name}")
        duct_program.addLine("Set #{liv_to_ah_flow_rate_actuator.name} = #{ah_to_liv_flow_rate_var.name}")
        duct_program.addLine("Set #{liv_to_ah_flow_rate_actuator.name} = #{liv_to_ah_flow_rate_var.name}")
      else

        duct_program.addLine("Set dl_1 = #{supply_sens_lkage_to_liv_var.name}")
        duct_program.addLine("Set dl_2 = #{supply_lat_lkage_to_liv_var.name}")
        duct_program.addLine("Set dl_3 = #{supply_duct_cond_to_liv_var.name}")
        duct_program.addLine("Set dl_4 = #{supply_duct_cond_to_ah_var.name}")
        duct_program.addLine("Set dl_5 = #{supply_sens_lkage_to_ah_var.name}")
        duct_program.addLine("Set dl_6 = #{supply_lat_lkage_to_ah_var.name}")
        duct_program.addLine("Set dl_7 = #{return_sens_lkage_var.name}")
        duct_program.addLine("Set dl_8 = #{return_lat_lkage_var.name}")
        duct_program.addLine("Set dl_9 = #{return_duct_cond_to_plenum_var.name}")
        duct_program.addLine("Set dl_10 = #{return_duct_cond_to_ah_var.name}")
        duct_program.addLine("Set dl_11 = #{ah_to_liv_flow_rate_var.name}")
        duct_program.addLine("Set dl_12 = #{liv_to_ah_flow_rate_var.name}")

        duct_program.addLine("If #{cfis_on_for_hour_var.name}")
        duct_program.addLine("   Set cfis_m3s = (#{max_supply_fan_mfr.name} / 1.16097654) * #{mech_vent.cfis_airflow_frac}")      # Density of 1.16097654 was back calculated using E+ results
        duct_program.addLine("   Set #{ah_vfr_var.name} = (1.0 - #{fan_rtf_sensor.name})*#{cfis_f_damper_open_var.name}*cfis_m3s")
        duct_program.addLine("   Set rho_in = (@RhoAirFnPbTdbW #{tin_sensor.name} #{win_sensor.name} #{pbar_sensor.name})")
        duct_program.addLine("   Set #{ah_mfr_var.name} = #{ah_vfr_sensor.name} * rho_in")
        duct_program.addLine("   Set #{fan_rtf_var.name} = (1.0 - #{fan_rtf_sensor.name})*#{cfis_f_damper_open_var.name}")
        duct_program.addLine("   Set #{ah_tout_var.name} = #{ra_t_sensor.name}")
        duct_program.addLine("   Set #{ah_wout_var.name} = #{ra_w_sensor.name}")
        duct_program.addLine("   Set #{ra_t_var.name} = #{ra_t_sensor.name}")
        duct_program.addLine("   Set #{ra_w_var.name} = #{ra_w_sensor.name}")

        duct_program.addLine("   Run #{duct_subroutine.name}")

        duct_program.addLine("   Set #{supply_sens_lkage_to_liv_actuator.name} = #{supply_sens_lkage_to_liv_var.name} + dl_1")
        duct_program.addLine("   Set #{supply_lat_lkage_to_liv_actuator.name} = #{supply_lat_lkage_to_liv_var.name} + dl_2")
        duct_program.addLine("   Set #{supply_duct_cond_to_liv_actuator.name} = #{supply_duct_cond_to_liv_var.name} + dl_3")
        duct_program.addLine("   Set #{supply_duct_cond_to_ah_actuator.name} = #{supply_duct_cond_to_ah_var.name} + dl_4")
        duct_program.addLine("   Set #{supply_sens_lkage_to_ah_actuator.name} = #{supply_sens_lkage_to_ah_var.name} + dl_5")
        duct_program.addLine("   Set #{supply_lat_lkage_to_ah_actuator.name} = #{supply_lat_lkage_to_ah_var.name} + dl_6")
        duct_program.addLine("   Set #{return_sens_lkage_actuator.name} = #{return_sens_lkage_var.name} + dl_7")
        duct_program.addLine("   Set #{return_lat_lkage_actuator.name} = #{return_lat_lkage_var.name} + dl_8")
        duct_program.addLine("   Set #{return_duct_cond_to_plenum_actuator.name} = #{return_duct_cond_to_plenum_var.name} + dl_9")
        duct_program.addLine("   Set #{return_duct_cond_to_ah_actuator.name} = #{return_duct_cond_to_ah_var.name} + dl_10")
        duct_program.addLine("   Set #{liv_to_ah_flow_rate_actuator.name} = #{ah_to_liv_flow_rate_var.name} + dl_11")
        duct_program.addLine("   Set #{liv_to_ah_flow_rate_actuator.name} = #{liv_to_ah_flow_rate_var.name} + dl_12")

        duct_program.addLine("Else")
        duct_program.addLine("   Set #{supply_sens_lkage_to_liv_actuator.name} = dl_1")
        duct_program.addLine("   Set #{supply_lat_lkage_to_liv_actuator.name} = dl_2")
        duct_program.addLine("   Set #{supply_duct_cond_to_liv_actuator.name} = dl_3")
        duct_program.addLine("   Set #{supply_duct_cond_to_ah_actuator.name} = dl_4")
        duct_program.addLine("   Set #{supply_sens_lkage_to_ah_actuator.name} = dl_5")
        duct_program.addLine("   Set #{supply_lat_lkage_to_ah_actuator.name} = dl_6")
        duct_program.addLine("   Set #{return_sens_lkage_actuator.name} = dl_7")
        duct_program.addLine("   Set #{return_lat_lkage_actuator.name} = dl_8")
        duct_program.addLine("   Set #{return_duct_cond_to_plenum_actuator.name} = dl_9")
        duct_program.addLine("   Set #{return_duct_cond_to_ah_actuator.name} = dl_10")
        duct_program.addLine("   Set #{liv_to_ah_flow_rate_actuator.name} = dl_11")
        duct_program.addLine("   Set #{liv_to_ah_flow_rate_actuator.name} = dl_12")
        duct_program.addLine("EndIf")
      end

    else # no ducts

      # Duct Program

      duct_program = OpenStudio::Model::EnergyManagementSystemProgram.new(model)
      duct_program.setName(obj_name_ducts + " program")
      duct_program.addLine("Set #{duct_lk_supply_fan_equiv_var.name} = 0")
      duct_program.addLine("Set #{duct_lk_return_fan_equiv_var.name} = 0")

    end # end has ducts loop

    # CFIS Program
    
    cfis_program = nil
    if mech_vent.type == Constants.VentTypeCFIS
      cfis_program = OpenStudio::Model::EnergyManagementSystemProgram.new(model)
      cfis_program.setName(obj_name_ducts + " cfis init program")
      cfis_program.addLine("Set #{cfis_t_sum_open_var.name} = 0")
      cfis_program.addLine("Set #{cfis_on_for_hour_var.name} = 0")
      cfis_program.addLine("Set #{duct_lk_return_fan_equiv_var.name} = 0")
      cfis_program.addLine("Set #{cfis_f_damper_open_var.name} = 0")
    end
    
    cfis_output = CFISOutput.new(cfis_t_sum_open_var, cfis_on_for_hour_var, cfis_f_damper_open_var, max_supply_fan_mfr, fan_rtf_var, fan_rtf_sensor)
    return duct_program, cfis_program, cfis_output
    
  end
  
  def self.create_infil_mech_vent_objects(model, runner, output_vars, obj_name_infil, obj_name_mech_vent, unit_living, infil, mech_vent, wind_speed, mv_output, infil_output, tin_sensor, tout_sensor, vwind_sensor, duct_lk_supply_fan_equiv_var, duct_lk_return_fan_equiv_var, cfis_output, sch_unit_index, nbeds)

    # Sensors
  
    range_array = [0.0] * 24
    range_array[mech_vent.range_exhaust_hour - 1] = 1.0
    range_hood_sch = HourlyByMonthSchedule.new(model, runner, obj_name_mech_vent + " range exhaust schedule", [range_array] * 12, [range_array] * 12, normalize_values = false)
    range_sch_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, output_vars["Schedule Value"])
    range_sch_sensor.setName("#{obj_name_infil} range sch s")
    range_sch_sensor.setKeyName(range_hood_sch.schedule.name.to_s)

    bathroom_array = [0.0] * 24
    bathroom_array[mech_vent.bathroom_exhaust_hour - 1] = 1.0
    bath_exhaust_sch = HourlyByMonthSchedule.new(model, runner, obj_name_mech_vent + " bath exhaust schedule", [bathroom_array] * 12, [bathroom_array] * 12, normalize_values = false)
    bath_sch_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, output_vars["Schedule Value"])
    bath_sch_sensor.setName("#{obj_name_infil} bath sch s")
    bath_sch_sensor.setKeyName(bath_exhaust_sch.schedule.name.to_s)

    if mv_output.has_dryer and mech_vent.dryer_exhaust > 0
      dryer_exhaust_sch = HotWaterSchedule.new(model, runner, obj_name_mech_vent + " dryer exhaust schedule", obj_name_mech_vent + " dryer exhaust temperature schedule", nbeds, sch_unit_index, mv_output.dryer_exhaust_day_shift, "ClothesDryerExhaust", 0, @measure_dir)
      dryer_sch_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, output_vars["Schedule Value"])
      dryer_sch_sensor.setName("#{obj_name_infil} dryer sch s")
      dryer_sch_sensor.setKeyName(dryer_exhaust_sch.schedule.name.to_s)
    end
    
    wh_sch_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, output_vars["Schedule Value"])
    wh_sch_sensor.setName("#{obj_name_infil} wh sch s")
    wh_sch_sensor.setKeyName(model.alwaysOnDiscreteSchedule.name.to_s)
    
    if mech_vent.type == Constants.VentTypeBalanced

      balanced_flow_rate = [UnitConversions.convert(mv_output.whole_house_vent_rate,"cfm","m^3/s"),0.0000001].max

      supply_fan = OpenStudio::Model::FanOnOff.new(model)
      supply_fan.setName(obj_name_mech_vent + " erv supply fan")
      supply_fan.setFanEfficiency(UnitConversions.convert(300.0 / mech_vent.fan_power,"cfm","m^3/s"))
      supply_fan.setPressureRise(300.0)
      supply_fan.setMaximumFlowRate(balanced_flow_rate)
      supply_fan.setMotorEfficiency(1)
      supply_fan.setMotorInAirstreamFraction(1)
      supply_fan.setEndUseSubcategory(Constants.EndUseMechVentFan)

      exhaust_fan = OpenStudio::Model::FanOnOff.new(model)
      exhaust_fan.setName(obj_name_mech_vent + " erv exhaust fan")
      exhaust_fan.setFanEfficiency(UnitConversions.convert(300.0 / mech_vent.fan_power,"cfm","m^3/s"))
      exhaust_fan.setPressureRise(300.0)
      exhaust_fan.setMaximumFlowRate(balanced_flow_rate)
      exhaust_fan.setMotorEfficiency(1)
      exhaust_fan.setMotorInAirstreamFraction(0)
      exhaust_fan.setEndUseSubcategory(Constants.EndUseMechVentFan)

      erv_controller = OpenStudio::Model::ZoneHVACEnergyRecoveryVentilatorController.new(model)
      erv_controller.setName(obj_name_mech_vent + " erv controller")
      erv_controller.setExhaustAirTemperatureLimit("NoExhaustAirTemperatureLimit")
      erv_controller.setExhaustAirEnthalpyLimit("NoExhaustAirEnthalpyLimit")
      erv_controller.setTimeofDayEconomizerFlowControlSchedule(model.alwaysOffDiscreteSchedule)
      erv_controller.setHighHumidityControlFlag(false)

      heat_exchanger = OpenStudio::Model::HeatExchangerAirToAirSensibleAndLatent.new(model)
      heat_exchanger.setName(obj_name_mech_vent + " erv heat exchanger")
      heat_exchanger.setNominalSupplyAirFlowRate(balanced_flow_rate)
      heat_exchanger.setSensibleEffectivenessat100HeatingAirFlow(mv_output.sensible_effectiveness)
      heat_exchanger.setLatentEffectivenessat100HeatingAirFlow(mv_output.latent_effectiveness)
      heat_exchanger.setSensibleEffectivenessat75HeatingAirFlow(mv_output.sensible_effectiveness)
      heat_exchanger.setLatentEffectivenessat75HeatingAirFlow(mv_output.latent_effectiveness)
      heat_exchanger.setSensibleEffectivenessat100CoolingAirFlow(mv_output.sensible_effectiveness)
      heat_exchanger.setLatentEffectivenessat100CoolingAirFlow(mv_output.latent_effectiveness)
      heat_exchanger.setSensibleEffectivenessat75CoolingAirFlow(mv_output.sensible_effectiveness)
      heat_exchanger.setLatentEffectivenessat75CoolingAirFlow(mv_output.latent_effectiveness)

      zone_hvac = OpenStudio::Model::ZoneHVACEnergyRecoveryVentilator.new(model, heat_exchanger, supply_fan, exhaust_fan)
      zone_hvac.setName(obj_name_mech_vent + " erv")
      zone_hvac.setController(erv_controller)
      zone_hvac.setSupplyAirFlowRate(balanced_flow_rate)
      zone_hvac.setExhaustAirFlowRate(balanced_flow_rate)
      zone_hvac.setVentilationRateperUnitFloorArea(0)
      zone_hvac.setVentilationRateperOccupant(0)
      zone_hvac.addToThermalZone(unit_living.zone)

      HVAC.prioritize_zone_hvac(model, runner, unit_living.zone)

    end
    
    # Actuators
    
    living_space = unit_living.zone.spaces[0]
    
    equip_def = OpenStudio::Model::ElectricEquipmentDefinition.new(model)
    equip_def.setName(obj_name_infil + " house fan")
    equip = OpenStudio::Model::ElectricEquipment.new(equip_def)
    equip.setName(obj_name_infil + " house fan")
    equip.setSpace(living_space)
    equip_def.setFractionRadiant(0)
    equip_def.setFractionLatent(0)
    equip_def.setFractionLost(1.0 - mv_output.frac_fan_heat)
    equip.setSchedule(model.alwaysOnDiscreteSchedule)
    equip.setEndUseSubcategory(Constants.EndUseMechVentFan)
    whole_house_fan_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(equip, "ElectricEquipment", "Electric Power Level")
    whole_house_fan_actuator.setName("#{equip.name} act")

    equip_def = OpenStudio::Model::ElectricEquipmentDefinition.new(model)
    equip_def.setName(obj_name_infil + " range fan")
    equip = OpenStudio::Model::ElectricEquipment.new(equip_def)
    equip.setName(obj_name_infil + " range fan")
    equip.setSpace(living_space)
    equip_def.setFractionRadiant(0)
    equip_def.setFractionLatent(0)
    equip_def.setFractionLost(1)
    equip.setSchedule(model.alwaysOnDiscreteSchedule)
    equip.setEndUseSubcategory(Constants.EndUseMechVentFan)
    range_hood_fan_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(equip, "ElectricEquipment", "Electric Power Level")
    range_hood_fan_actuator.setName("#{equip.name} act")

    equip_def = OpenStudio::Model::ElectricEquipmentDefinition.new(model)
    equip_def.setName(obj_name_infil + " bath fan")
    equip = OpenStudio::Model::ElectricEquipment.new(equip_def)
    equip.setName(obj_name_infil + " bath fan")
    equip.setSpace(living_space)
    equip_def.setFractionRadiant(0)
    equip_def.setFractionLatent(0)
    equip_def.setFractionLost(1)
    equip.setSchedule(model.alwaysOnDiscreteSchedule)
    equip.setEndUseSubcategory(Constants.EndUseMechVentFan)
    bath_exhaust_sch_fan_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(equip, "ElectricEquipment", "Electric Power Level")
    bath_exhaust_sch_fan_actuator.setName("#{equip.name} act")
    
    infil_flow = OpenStudio::Model::SpaceInfiltrationDesignFlowRate.new(model)
    infil_flow.setName(obj_name_infil + " flow")
    infil_flow.setSchedule(model.alwaysOnDiscreteSchedule)
    infil_flow.setSpace(living_space)
    infil_flow_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(infil_flow, "Zone Infiltration", "Air Exchange Flow Rate")
    infil_flow_actuator.setName("#{infil_flow.name} act")
      
    # Program
    
    infil_program = OpenStudio::Model::EnergyManagementSystemProgram.new(model)
    infil_program.setName(obj_name_infil + " program")

    if unit_living.inf_method == @infMethodASHRAE
      if unit_living.SLA > 0
        infil_program.addLine("Set p_m = #{wind_speed.ashrae_terrain_exponent}")
        infil_program.addLine("Set p_s = #{wind_speed.ashrae_site_terrain_exponent}")
        infil_program.addLine("Set s_m = #{wind_speed.ashrae_terrain_thickness}")
        infil_program.addLine("Set s_s = #{wind_speed.ashrae_site_terrain_thickness}")
        infil_program.addLine("Set z_m = #{UnitConversions.convert(wind_speed.height,"ft","m")}")
        infil_program.addLine("Set z_s = #{UnitConversions.convert(unit_living.height,"ft","m")}")
        infil_program.addLine("Set f_t = (((s_m/z_m)^p_m)*((z_s/s_s)^p_s))")
        infil_program.addLine("Set Tdiff = #{tin_sensor.name}-#{tout_sensor.name}")
        infil_program.addLine("Set dT = @Abs Tdiff")
        infil_program.addLine("Set c = #{((UnitConversions.convert(infil_output.c_i,"cfm","m^3/s") / (UnitConversions.convert(1.0,"inH2O","Pa") ** infil_output.n_i))).round(4)}")
        infil_program.addLine("Set Cs = #{(infil_output.stack_coef * (UnitConversions.convert(1.0,"inH2O/R","Pa/K") ** infil_output.n_i)).round(4)}")
        infil_program.addLine("Set Cw = #{(infil_output.wind_coef * (UnitConversions.convert(1.0,"inH2O/mph^2","Pa*s^2/m^2") ** infil_output.n_i)).round(4)}")
        infil_program.addLine("Set n = #{infil_output.n_i}")
        infil_program.addLine("Set sft = (f_t*#{(((wind_speed.S_wo * (1.0 - infil_output.y_i)) + (infil_output.s_wflue * (1.5 * infil_output.y_i))))})")
        infil_program.addLine("Set temp1 = ((c*Cw)*((sft*#{vwind_sensor.name})^(2*n)))^2")
        infil_program.addLine("Set Qn = (((c*Cs*(dT^n))^2)+temp1)^0.5")
      else
        infil_program.addLine("Set Qn = 0")
      end
    elsif unit_living.inf_method == @infMethodRes
      infil_program.addLine("Set Qn = #{unit_living.ACH * UnitConversions.convert(unit_living.volume,"ft^3","m^3") / UnitConversions.convert(1.0,"hr","s")}")
    end

    infil_program.addLine("Set Tdiff = #{tin_sensor.name}-#{tout_sensor.name}")
    infil_program.addLine("Set dT = @Abs Tdiff")
    infil_program.addLine("Set QWHV = #{wh_sch_sensor.name}*#{UnitConversions.convert(mv_output.whole_house_vent_rate,"cfm","m^3/s").round(4)}")

    if mech_vent.type == Constants.VentTypeCFIS
      cfis_outdoor_airflow = 0.0
      if mech_vent.cfis_open_time > 0.0
        cfis_outdoor_airflow = mv_output.whole_house_vent_rate * (60.0 / mech_vent.cfis_open_time)
      end
      
      system, clg_coil, htg_coil, air_loop = HVAC.get_unitary_system_air_loop(model, runner, unit_living.zone)
      clg_coil = HVAC.get_coil_from_hvac_component(clg_coil)
      cfis_fan_power = clg_coil.ratedEvaporatorFanPowerPerVolumeFlowRate.get / UnitConversions.convert(1.0,"m^3/s","cfm") # W/cfm
      
      infil_program.addLine("Set #{cfis_output.fan_rtf_var.name} = #{cfis_output.fan_rtf_sensor.name}")

      infil_program.addLine("If @ABS(Minute - ZoneTimeStep*60) < 0.1")
      infil_program.addLine("  Set #{cfis_output.t_sum_open_var.name} = 0") # New hour, time on summation re-initializes to 0
      infil_program.addLine("  Set #{cfis_output.on_for_hour_var.name} = 0")
      infil_program.addLine("EndIf")

      infil_program.addLine("Set CFIS_t_min_hr_open = #{mech_vent.cfis_open_time}") # minutes per hour the CFIS damper is open
      infil_program.addLine("Set CFIS_Q_duct = #{UnitConversions.convert(cfis_outdoor_airflow, 'cfm', 'm^3/s')}")
      infil_program.addLine("Set #{cfis_output.f_damper_open_var.name} = 0") # fraction of the timestep the CFIS damper is open

      infil_program.addLine("If #{cfis_output.t_sum_open_var.name} < CFIS_t_min_hr_open")
      infil_program.addLine("  Set CFIS_t_fan_on = 60 - (CFIS_t_min_hr_open - #{cfis_output.t_sum_open_var.name})") # minute at which the blower needs to turn on to meet the ventilation requirements
      infil_program.addLine("  If ((Minute+0.00001) >= CFIS_t_fan_on) || #{cfis_output.on_for_hour_var.name}")

      # Supply fan needs to run for remainder of hour to achieve target minutes per hour of operation
      infil_program.addLine("    If #{cfis_output.on_for_hour_var.name}")
      infil_program.addLine("      Set #{cfis_output.f_damper_open_var.name} = 1")
      infil_program.addLine("    Else")
      infil_program.addLine("      Set #{cfis_output.f_damper_open_var.name} = (@Mod (60.0-CFIS_t_fan_on) (60.0*ZoneTimeStep)) / (60.0*ZoneTimeStep)") # calculates the portion of the current timestep the CFIS damper needs to be open
      infil_program.addLine("      Set #{cfis_output.on_for_hour_var.name} = 1") # CFIS damper will need to open for all the remaining timesteps in this hour
      infil_program.addLine("    EndIf")
      infil_program.addLine("    Set QWHV = #{cfis_output.f_damper_open_var.name}*CFIS_Q_duct")
      infil_program.addLine("    Set #{cfis_output.t_sum_open_var.name} = #{cfis_output.t_sum_open_var.name} + #{cfis_output.f_damper_open_var.name}*(ZoneTimeStep*60)")
      infil_program.addLine("    Set cfis_cfm = (#{cfis_output.max_supply_fan_mfr.name} / 1.16097654) * #{mech_vent.cfis_airflow_frac} * #{UnitConversions.convert(1.0,'m^3/s','cfm')}")      # Density of 1.16097654 was back calculated using E+ results
      infil_program.addLine("    Set #{whole_house_fan_actuator.name} = #{cfis_fan_power} * cfis_cfm * #{cfis_output.f_damper_open_var.name}*(1-#{cfis_output.fan_rtf_var.name})")
      infil_program.addLine("  Else")
      infil_program.addLine("    If (#{cfis_output.t_sum_open_var.name} + (#{cfis_output.fan_rtf_var.name}*ZoneTimeStep*60)) > CFIS_t_min_hr_open")
      # Damper is only open for a portion of this time step to achieve target minutes per hour
      infil_program.addLine("      Set #{cfis_output.f_damper_open_var.name} = (CFIS_t_min_hr_open-#{cfis_output.t_sum_open_var.name})/(ZoneTimeStep*60)")
      infil_program.addLine("      Set QWHV = #{cfis_output.f_damper_open_var.name}*CFIS_Q_duct")
      infil_program.addLine("      Set #{cfis_output.t_sum_open_var.name} = CFIS_t_min_hr_open")
      infil_program.addLine("    Else")
      # Damper is open and using call for heat/cool to supply fresh air
      infil_program.addLine("      Set #{cfis_output.t_sum_open_var.name} = #{cfis_output.t_sum_open_var.name} + (#{cfis_output.fan_rtf_var.name}*ZoneTimeStep*60)")
      infil_program.addLine("      Set #{cfis_output.f_damper_open_var.name} = 1")
      infil_program.addLine("      Set QWHV = #{cfis_output.fan_rtf_var.name}*CFIS_Q_duct")
      infil_program.addLine("    EndIf")
      # Fan power is metered under fan cooling and heating meters
      infil_program.addLine("    Set #{whole_house_fan_actuator.name} =  0")
      infil_program.addLine("  EndIf")
      infil_program.addLine("Else")
      # The ventilation requirement for the hour has been met
      infil_program.addLine("  Set QWHV = 0")
      infil_program.addLine("  Set #{whole_house_fan_actuator.name} =  0")
      infil_program.addLine("EndIf")
    end

    infil_program.addLine("Set Qrange = #{range_sch_sensor.name}*#{UnitConversions.convert(mv_output.range_hood_hour_avg_exhaust,"cfm","m^3/s").round(4)}")
    if mv_output.has_dryer and mech_vent.dryer_exhaust > 0
      infil_program.addLine("Set Qdryer = #{dryer_sch_sensor.name}*#{UnitConversions.convert(mech_vent.dryer_exhaust,"cfm","m^3/s").round(4)}")
    else
      infil_program.addLine("Set Qdryer = 0.0")
    end
    infil_program.addLine("Set Qbath = #{bath_sch_sensor.name}*#{UnitConversions.convert(mv_output.bathroom_hour_avg_exhaust,"cfm","m^3/s").round(4)}")
    infil_program.addLine("Set QhpwhOut = 0")
    infil_program.addLine("Set QhpwhIn = 0")
    infil_program.addLine("Set QductsOut = #{duct_lk_return_fan_equiv_var.name}")
    infil_program.addLine("Set QductsIn = #{duct_lk_supply_fan_equiv_var.name}")

    if mech_vent.type == Constants.VentTypeBalanced
      infil_program.addLine("Set Qout = Qrange+Qbath+Qdryer+QhpwhOut+QductsOut")
      infil_program.addLine("Set Qin = QhpwhIn+QductsIn")
      infil_program.addLine("Set Qu = (@Abs (Qout-Qin))")
      infil_program.addLine("Set Qb = QWHV + (@Min Qout Qin)")
      infil_program.addLine("Set #{whole_house_fan_actuator.name} = 0")
    else
      if mech_vent.type == Constants.VentTypeExhaust
        infil_program.addLine("Set Qout = QWHV+Qrange+Qbath+Qdryer+QhpwhOut+QductsOut")
        infil_program.addLine("Set Qin = QhpwhIn+QductsIn")
        infil_program.addLine("Set Qu = (@Abs (Qout-Qin))")
        infil_program.addLine("Set Qb = (@Min Qout Qin)")
      else # mech_vent.type == Constants.VentTypeSupply
        infil_program.addLine("Set Qout = Qrange+Qbath+Qdryer+QhpwhOut+QductsOut")
        infil_program.addLine("Set Qin = QWHV+QhpwhIn+QductsIn")
        infil_program.addLine("Set Qu = @Abs (Qout- Qin)")
        infil_program.addLine("Set Qb = (@Min Qout Qin)")
      end
      if mech_vent.type != Constants.VentTypeCFIS
        if mech_vent.fan_power !=  0
          infil_program.addLine("Set faneff_wh = #{UnitConversions.convert(300.0 / mech_vent.fan_power,"cfm","m^3/s")}")
        else
          infil_program.addLine("Set faneff_wh = 1")
        end
        infil_program.addLine("Set #{whole_house_fan_actuator.name} = (QWHV*300)/faneff_wh")
      end
    end

    if mv_output.spot_fan_power !=  0
      infil_program.addLine("Set faneff_sp = #{UnitConversions.convert(300.0 / mv_output.spot_fan_power,"cfm","m^3/s")}")
    else
      infil_program.addLine("Set faneff_sp = 1")
    end

    infil_program.addLine("Set #{range_hood_fan_actuator.name} = (Qrange*300)/faneff_sp")
    infil_program.addLine("Set #{bath_exhaust_sch_fan_actuator.name} = (Qbath*300)/faneff_sp")
    infil_program.addLine("Set Q_acctd_for_elsewhere = QhpwhOut+QhpwhIn+QductsOut+QductsIn")
    infil_program.addLine("Set #{infil_flow_actuator.name} = (((Qu^2)+(Qn^2))^0.5)-Q_acctd_for_elsewhere")
    infil_program.addLine("Set #{infil_flow_actuator.name} = (@Max #{infil_flow_actuator.name} 0)")

    return infil_program
    
  end

  def self.create_ems_program_managers(model, infil_program, nv_program, cfis_program, 
                                       duct_program, obj_name_airflow, obj_name_ducts)

    program_calling_manager = OpenStudio::Model::EnergyManagementSystemProgramCallingManager.new(model)
    program_calling_manager.setName(obj_name_airflow + " program calling manager")
    program_calling_manager.setCallingPoint("BeginTimestepBeforePredictor")
    program_calling_manager.addProgram(infil_program)
    program_calling_manager.addProgram(nv_program)

    if not cfis_program.nil?
      program_calling_manager = OpenStudio::Model::EnergyManagementSystemProgramCallingManager.new(model)
      program_calling_manager.setName(obj_name_ducts + " cfis init program 1 calling manager")
      program_calling_manager.setCallingPoint("BeginNewEnvironment")
      program_calling_manager.addProgram(cfis_program)

      program_calling_manager = OpenStudio::Model::EnergyManagementSystemProgramCallingManager.new(model)
      program_calling_manager.setName(obj_name_ducts + " cfis init program 2 calling manager")
      program_calling_manager.setCallingPoint("AfterNewEnvironmentWarmUpIsComplete")
      program_calling_manager.addProgram(cfis_program)
    end

    program_calling_manager = OpenStudio::Model::EnergyManagementSystemProgramCallingManager.new(model)
    program_calling_manager.setName(obj_name_ducts + " program calling manager")
    program_calling_manager.setCallingPoint("EndOfSystemTimestepAfterHVACReporting")
    program_calling_manager.addProgram(duct_program)
    
  end
  
  def self.get_location(location, unit, unit_index)
    location_zone = nil
    location_name = "none"

    location_hierarchy = [Constants.SpaceTypeFinishedBasement,
                          Constants.SpaceTypeUnfinishedBasement,
                          Constants.SpaceTypeCrawl,
                          Constants.SpaceTypePierBeam,
                          Constants.SpaceTypeUnfinishedAttic,
                          Constants.SpaceTypeGarage,
                          Constants.SpaceTypeLiving]

    # Get space
    space = Geometry.get_space_from_location(unit, location, location_hierarchy)
    return location_zone, location_name if space.nil?

    location_zone = space.thermalZone.get
    location_name = location_zone.name.to_s
    return location_zone, location_name
  end

  def self.calc_duct_leakage_from_test(ducts, ffa, fan_AirFlowRate)
    '''
    Calculates duct leakage inputs based on duct blaster type lkage measurements (cfm @ 25 Pa per 100 ft2 conditioned floor area).
    Requires assumptions about supply/return leakage split, air handler leakage, and duct plenum (de)pressurization.
    '''
    
    '''
    # Assumptions
    supply_duct_lkage_frac = 0.67 # 2013 RESNET Standards, Appendix A, p.A-28
    return_duct_lkage_frac = 0.33 # 2013 RESNET Standards, Appendix A, p.A-28
    ah_lkage = 0.025 # 2.5% of air handler flow at 25 P (Reference: ASHRAE Standard 152-2004, Annex C, p 33; Walker et al 2010. "Air Leakage of Furnaces and Air Handlers")
    ducts.ah_supply_frac = 0.20 # (Reference: Walker et al 2010. "Air Leakage of Furnaces and Air Handlers")
    ducts.ah_return_frac = 0.80 # (Reference: Walker et al 2010. "Air Leakage of Furnaces and Air Handlers")
    p_supply = 25.0 # Assume average operating pressure in ducts is 25 Pa,
    p_return = 25.0 # though it is likely lower (Reference: Pigg and Francisco 2008 "A Field Study of Exterior Duct Leakage in New Wisconsin Homes")

    # Conversion
    cfm25 = ducts.norm_leakage_25pa * ffa / 100.0 #denormalize leakage
    ah_cfm25 = ah_lkage * fan_AirFlowRate # air handler leakage flow rate at 25 Pa
    ah_supply_lk_cfm25 = [ah_cfm25 * ducts.ah_supply_frac, cfm25 * supply_duct_lkage_frac].min
    ah_return_lk_cfm25 = [ah_cfm25 * ducts.ah_return_frac, cfm25 * return_duct_lkage_frac].min
    supply_lk_cfm25 = [cfm25 * supply_duct_lkage_frac - ah_supply_lk_cfm25, 0].max
    return_lk_cfm25 = [cfm25 * return_duct_lkage_frac - ah_return_lk_cfm25, 0].max

    supply_lk_oper = Airflow.calc_duct_leakage_at_diff_pressure(supply_lk_cfm25, 25.0, p_supply) # cfm at operating pressure
    return_lk_oper = Airflow.calc_duct_leakage_at_diff_pressure(return_lk_cfm25, 25.0, p_return) # cfm at operating pressure
    ah_supply_lk_oper = Airflow.calc_duct_leakage_at_diff_pressure(ah_supply_lk_cfm25, 25.0, p_supply) # cfm at operating pressure
    ah_return_lk_oper = Airflow.calc_duct_leakage_at_diff_pressure(ah_return_lk_cfm25, 25.0, p_return) # cfm at operating pressure

    if fan_AirFlowRate == 0
        supply_leakage = 0
        return_leakage = 0
        ah_supply_leakage = 0
        ah_return_leakage = 0
    else
        supply_leakage = supply_lk_oper / fan_AirFlowRate
        return_leakage = return_lk_oper / fan_AirFlowRate
        ah_supply_leakage = ah_supply_lk_oper / fan_AirFlowRate
        ah_return_leakage = ah_return_lk_oper / fan_AirFlowRate
    end

    supply_loss = supply_leakage + ah_supply_leakage
    return_loss = return_leakage + ah_return_leakage

    # Leakage to outside was specified, so dont account for location fraction
    location_frac_leakage = 1
    '''
  end
  
  def self.get_location_frac_leakage(location_frac, stories)
    if location_frac == Constants.Auto
      # Duct location fraction per 2010 BA Benchmark
      if stories == 1
        location_frac_leakage = 1
      else
        location_frac_leakage = 0.65
      end
    else
      location_frac_leakage = location_frac.to_f
    end
    return location_frac_leakage
  end

  def self.get_infiltration_ACH_from_SLA(sla, numStories, weather)
    # Returns the infiltration annual average ACH given a SLA.
    w = calc_infiltration_w_factor(weather)

    # Equation from ASHRAE 119-1998 (using numStories for simplification)
    norm_lkage = 1000.0 * sla * numStories ** 0.3

    # Equation from ASHRAE 136-1993
    return norm_lkage * w
  end  
  
  def self.get_infiltration_SLA_from_ACH(ach, numStories, weather)
    # Returns the infiltration SLA given an annual average ACH.
    w = calc_infiltration_w_factor(weather)
    
    return ach/(w * 1000 * numStories**0.3) 
  end

  def self.get_infiltration_SLA_from_ACH50(ach50, n_i, conditionedFloorArea, conditionedVolume, pressure_difference_Pa=50)
    # Returns the infiltration SLA given a ACH50.
    return ((ach50 * 0.2835 * 4.0 ** n_i * conditionedVolume) / (conditionedFloorArea * UnitConversions.convert(1.0,"ft^2","in^2") * pressure_difference_Pa ** n_i * 60.0))
  end  
  
  def self.get_infiltration_ACH50_from_SLA(sla, n_i, conditionedFloorArea, conditionedVolume, pressure_difference_Pa=50)
    # Returns the infiltration ACH50 given a SLA.
    return ((sla * conditionedFloorArea * UnitConversions.convert(1.0,"ft^2","in^2") * pressure_difference_Pa ** n_i * 60.0)/(0.2835 * 4.0 ** n_i * conditionedVolume))
  end

  def self.calc_duct_leakage_at_diff_pressure(q_old, p_old, p_new)
    return q_old * (p_new / p_old) ** 0.6 # Derived from Equation C-1 (Annex C), p34, ASHRAE Standard 152-2004.
  end
  
  def self.get_duct_insulation_rvalue(nominalR, isSupply)
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
    if nominalR <=  0
      return 1.7
    end
    if isSupply
      return 2.2438 + 0.5619*nominalR
    else
      return 2.0388 + 0.7053*nominalR
    end
  end

  def self.get_duct_supply_surface_area(mult, ffa, num_stories)
    # Duct Surface Areas per 2010 BA Benchmark
    if num_stories == 1
      return 0.27 * ffa * mult # ft^2
    else
      return 0.2 * ffa * mult
    end
  end
  
  def self.get_return_surface_area(mult, ffa, num_stories, num_returns)
    # Duct Surface Areas per 2010 BA Benchmark
    if num_stories == 1
      return [0.05 * num_returns * ffa, 0.25 * ffa].min * mult
    else
      return [0.04 * num_returns * ffa, 0.19 * ffa].min * mult
    end
  end

  def self.get_num_returns(num_returns, num_stories)
    if num_returns.nil?
      return 0
    elsif num_returns == Constants.Auto
      # Duct Number Returns per 2010 BA Benchmark Addendum
      return 1 + num_stories
    end
    return num_returns.to_i
  end  

  def self.get_mech_vent_whole_house_cfm(frac622, num_beds, ffa, std)
    # Returns the ASHRAE 62.2 whole house mechanical ventilation rate, excluding any infiltration credit.
    if std == '2013'
      return frac622 * ((num_beds + 1.0) * 7.5 + 0.03 * ffa)
    end
    return frac622 * ((num_beds + 1.0) * 7.5 + 0.01 * ffa)
  end  
  
  def self.calc_infiltration_w_factor(weather)
    # Returns a w factor for infiltration calculations; see ticket #852 for derivation.
    hdd65f = weather.data.HDD65F
    ws = weather.data.AnnualAvgWindspeed
    a = 0.36250748
    b = 0.365317169
    c = 0.028902855
    d = 0.050181043
    e = 0.009596674
    f = -0.041567541
    # in ACH
    w = (a + b * hdd65f / 10000.0 + c * (hdd65f / 10000.0) ** 2.0 + d * ws + e * ws ** 2 + f * hdd65f / 10000.0 * ws)
    return w
  end

end

class Ducts
  def initialize(total_leakage, norm_leakage_25pa, supply_area_mult, return_area_mult, r, supply_frac, return_frac, ah_supply_frac, ah_return_frac, location_frac, num_returns, location)
    @total_leakage = total_leakage
    @norm_leakage_25pa = norm_leakage_25pa
    @supply_area_mult = supply_area_mult
    @return_area_mult = return_area_mult
    @r = r
    @supply_frac = supply_frac
    @return_frac = return_frac
    @ah_supply_frac = ah_supply_frac
    @ah_return_frac = ah_return_frac
    @location_frac = location_frac
    @num_returns = num_returns
    @location = location
  end
  attr_accessor(:total_leakage, :norm_leakage_25pa, :supply_area_mult, :return_area_mult, :r, :supply_frac, :return_frac, :ah_supply_frac, :ah_return_frac, :location_frac, :num_returns, :location)
end

class DuctsOutput
  def initialize(location_name, location_zone, return_volume, supply_loss, return_loss, frac_oa, total_unbalance, unconditioned_ua, return_ua)
    @location_name = location_name
    @location_zone = location_zone
    @return_volume = return_volume
    @supply_loss = supply_loss
    @return_loss = return_loss
    @frac_oa = frac_oa
    @total_unbalance = total_unbalance
    @unconditioned_ua = unconditioned_ua
    @return_ua = return_ua
  end
  attr_accessor(:location_name, :location_zone, :return_volume, :supply_loss, :return_loss, :frac_oa, :total_unbalance, :unconditioned_ua, :return_ua)
end

class Infiltration
  def initialize(living_ach50, shelter_coef, garage_ach50, crawl_ach, unfinished_attic_sla, unfinished_basement_ach, finished_basement_ach, pier_beam_ach, has_flue_chimney, is_existing_home, terrain)
    @living_ach50 = living_ach50
    @shelter_coef = shelter_coef
    @garage_ach50 = garage_ach50
    @crawl_ach = crawl_ach
    @unfinished_attic_sla = unfinished_attic_sla
    @unfinished_basement_ach = unfinished_basement_ach
    @finished_basement_ach = finished_basement_ach
    @pier_beam_ach = pier_beam_ach
    @has_flue_chimney = has_flue_chimney
    @is_existing_home = is_existing_home
    @terrain = terrain
  end
  attr_accessor(:living_ach50, :shelter_coef, :garage_ach50, :crawl_ach, :unfinished_attic_sla, :unfinished_basement_ach, :finished_basement_ach, :pier_beam_ach, :has_flue_chimney, :is_existing_home, :terrain)
end

class InfiltrationOutput
  def initialize(a_o, c_i, n_i, stack_coef, wind_coef, y_i, s_wflue)
    @a_o = a_o
    @c_i = c_i
    @n_i = n_i
    @stack_coef = stack_coef
    @wind_coef = wind_coef
    @y_i = y_i
    @s_wflue = s_wflue
  end
  attr_accessor(:a_o, :c_i, :n_i, :stack_coef, :wind_coef, :y_i, :s_wflue)
end

class NaturalVentilation
  def initialize(htg_offset, clg_offset, ovlp_offset, htg_season, clg_season, ovlp_season, num_weekdays, num_weekends, frac_windows_open, frac_window_area_openable, max_oa_hr, max_oa_rh)
    @htg_offset = htg_offset
    @clg_offset = clg_offset
    @ovlp_offset = ovlp_offset
    @htg_season = htg_season
    @clg_season = clg_season
    @ovlp_season = ovlp_season
    @num_weekdays = num_weekdays
    @num_weekends = num_weekends
    @frac_windows_open = frac_windows_open
    @frac_window_area_openable = frac_window_area_openable
    @max_oa_hr = max_oa_hr
    @max_oa_rh = max_oa_rh
  end
  attr_accessor(:htg_offset, :clg_offset, :ovlp_offset, :htg_season, :clg_season, :ovlp_season, :num_weekdays, :num_weekends, :frac_windows_open, :frac_window_area_openable, :max_oa_hr, :max_oa_rh)
end

class NaturalVentilationOutput
  def initialize(area, max_flow_rate, temp_sch, c_s, c_w, season_type)
    @area = area
    @max_flow_rate = max_flow_rate
    @temp_sch = temp_sch
    @c_s = c_s
    @c_w = c_w
    @season_type = season_type
  end
  attr_accessor(:area, :max_flow_rate, :temp_sch, :c_s, :c_w, :season_type)
end

class MechanicalVentilation
  def initialize(type, infil_credit, total_efficiency, frac_62_2, fan_power, sensible_efficiency, ashrae_std, cfis_open_time, cfis_airflow_frac, dryer_exhaust, range_exhaust_hour, bathroom_exhaust_hour)
    @type = type
    @infil_credit = infil_credit
    @total_efficiency = total_efficiency
    @frac_62_2 = frac_62_2
    @fan_power = fan_power
    @sensible_efficiency = sensible_efficiency
    @ashrae_std = ashrae_std
    @cfis_open_time = cfis_open_time
    @cfis_airflow_frac = cfis_airflow_frac
    @dryer_exhaust = dryer_exhaust
    @range_exhaust_hour = range_exhaust_hour
    @bathroom_exhaust_hour = bathroom_exhaust_hour
  end
  attr_accessor(:type, :infil_credit, :total_efficiency, :frac_62_2, :fan_power, :sensible_efficiency, :ashrae_std, :cfis_open_time, :cfis_airflow_frac, :dryer_exhaust, :range_exhaust_hour, :bathroom_exhaust_hour)
end

class MechanicalVentilationOutput
  def initialize(frac_fan_heat, whole_house_vent_rate, bathroom_hour_avg_exhaust, range_hood_hour_avg_exhaust, spot_fan_power, latent_effectiveness, sensible_effectiveness, dryer_exhaust_day_shift, has_dryer)
    @frac_fan_heat = frac_fan_heat
    @whole_house_vent_rate = whole_house_vent_rate
    @bathroom_hour_avg_exhaust = bathroom_hour_avg_exhaust
    @range_hood_hour_avg_exhaust = range_hood_hour_avg_exhaust
    @spot_fan_power = spot_fan_power
    @latent_effectiveness = latent_effectiveness
    @sensible_effectiveness = sensible_effectiveness
    @dryer_exhaust_day_shift = dryer_exhaust_day_shift
    @has_dryer = has_dryer
  end
  attr_accessor(:frac_fan_heat, :whole_house_vent_rate, :bathroom_hour_avg_exhaust, :range_hood_hour_avg_exhaust, :spot_fan_power, :latent_effectiveness, :sensible_effectiveness, :dryer_exhaust_day_shift, :has_dryer)
end

class CFISOutput
  def initialize(t_sum_open_var, on_for_hour_var, f_damper_open_var, max_supply_fan_mfr, fan_rtf_var, fan_rtf_sensor)
    @t_sum_open_var = t_sum_open_var
    @on_for_hour_var = on_for_hour_var
    @f_damper_open_var = f_damper_open_var
    @max_supply_fan_mfr = max_supply_fan_mfr
    @fan_rtf_var = fan_rtf_var
    @fan_rtf_sensor = fan_rtf_sensor
  end
  attr_accessor(:t_sum_open_var, :on_for_hour_var, :f_damper_open_var, :max_supply_fan_mfr, :fan_rtf_var, :fan_rtf_sensor)
end

class ZoneInfo
  def initialize(zone, height, area, volume, coord_z, ach=nil, sla=nil)
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
  attr_accessor(:ffa, :ag_ffa, :ag_ext_wall_area, :building_height, :stories, :above_grade_volume, :SLA, :garage, :unfinished_basement, :crawlspace, :pierbeam, :unfinished_attic)
end
