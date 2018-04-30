# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/geometry"

# start the measure
class ZoneMultipliers < OpenStudio::Measure::ModelMeasure

  # human readable name
  def name
    return "Apply Zone Multipliers"
  end

  # human readable description
  def description
    return "Model only one interior unit per floor with its thermal zone multiplier equal to the number of interior units per floor."
  end

  # human readable description of modeling approach
  def modeler_description
    return "Loop through building unit thermal zones and update multipliers based on location within the building and number of zones represented (removed from the model)."
  end

  # define the arguments that the user will input
  def arguments(model)
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
    
    runner.registerInitialCondition("Model started with #{model.getThermalZones.length} thermal zones.")

    units = Geometry.get_building_units(model, runner)
    if units.nil?
      return false
    end

    has_rear_units = Geometry.has_rear_units(model, runner, units)
    num_units = units.length

    unit_hash = {}
    units.each do |unit|
      unit_num = unit.name.to_s.gsub("unit ", "").to_i
      unit_hash[unit_num] = unit
    end

    if model.getBuilding.standardsBuildingType.is_initialized

      if model.getBuilding.standardsBuildingType.get == Constants.BuildingTypeSingleFamilyAttached

        if (num_units > 3 and not has_rear_units) or (num_units > 7 and has_rear_units)
          (2..num_units).to_a.each do |unit_num|

            if not has_rear_units

              zone_names_for_multiplier_adjustment = []
              space_names_to_remove = []
              unit_spaces = unit_hash[unit_num].spaces
              if unit_num == 2 # leftmost interior unit
                unit_spaces.each do |space|
                  thermal_zone = space.thermalZone.get
                  zone_names_for_multiplier_adjustment << thermal_zone.name.to_s
                end
                model.getThermalZones.each do |thermal_zone|
                  zone_names_for_multiplier_adjustment.each do |tz|
                    if thermal_zone.name.to_s == tz
                      thermal_zone.setMultiplier(num_units - 2)
                    end
                  end
                end
              elsif unit_num < num_units # interior units that get removed
                unit_spaces.each do |space|
                  space_names_to_remove << space.name.to_s
                end
                unit_hash[unit_num].remove
                model.getSpaces.each do |space|
                  space_names_to_remove.each do |s|
                    if space.name.to_s == s
                      if space.thermalZone.is_initialized
                        thermal_zone = space.thermalZone.get
                        thermal_zone.remove
                      end
                      space.remove
                    end
                  end
                end
              end

            else # has rear units
              next unless unit_num > 2

              zone_names_for_multiplier_adjustment = []
              space_names_to_remove = []
              unit_spaces = unit_hash[unit_num].spaces
              if unit_num == 3 or unit_num == 4 # leftmost interior units
                unit_spaces.each do |space|
                  thermal_zone = space.thermalZone.get
                  zone_names_for_multiplier_adjustment << thermal_zone.name.to_s
                end
                model.getThermalZones.each do |thermal_zone|
                  zone_names_for_multiplier_adjustment.each do |tz|
                    if thermal_zone.name.to_s == tz
                      thermal_zone.setMultiplier(num_units / 2 - 2)
                    end
                  end
                end
              elsif unit_num != num_units - 1 and unit_num != num_units # interior units that get removed
                unit_spaces.each do |space|
                  space_names_to_remove << space.name.to_s
                end
                unit_hash[unit_num].remove
                model.getSpaces.each do |space|
                  space_names_to_remove.each do |s|
                    if space.name.to_s == s
                      if space.thermalZone.is_initialized
                        thermal_zone = space.thermalZone.get
                        thermal_zone.remove
                      end
                      space.remove
                    end
                  end
                end
              end

            end

          end
        end
      
      elsif model.getBuilding.standardsBuildingType.get == Constants.BuildingTypeMultifamily
      
        num_floors = model.getBuilding.standardsNumberOfAboveGroundStories.get
        num_units_per_floor = num_units / num_floors

        # zone multipliers
        if (num_units_per_floor > 3 and not has_rear_units) or (num_units_per_floor > 7 and has_rear_units)

          (1..num_units_per_floor).to_a.each do |unit_num_per_floor|
            (1..num_floors).to_a.each do |building_floor|

              unit_num = unit_num_per_floor + (num_units_per_floor * (building_floor - 1))

              if not has_rear_units

                zone_names_for_multiplier_adjustment = []
                space_names_to_remove = []
                unit_spaces = unit_hash[unit_num].spaces
                if unit_num == 1 + (num_units_per_floor * (building_floor - 1)) # leftmost unit
                elsif unit_num == 2 + (num_units_per_floor * (building_floor - 1)) # leftmost interior unit
                  unit_spaces.each do |space|
                    thermal_zone = space.thermalZone.get
                    zone_names_for_multiplier_adjustment << thermal_zone.name.to_s
                  end
                  model.getThermalZones.each do |thermal_zone|
                    zone_names_for_multiplier_adjustment.each do |tz|
                      if thermal_zone.name.to_s == tz
                        thermal_zone.setMultiplier(num_units_per_floor - 2)
                      end
                    end
                  end
                elsif unit_num < building_floor * num_units_per_floor # interior units that get removed
                  unit_spaces.each do |space|
                    space_names_to_remove << space.name.to_s
                  end
                  unit_hash[unit_num].remove
                  model.getSpaces.each do |space|
                    space_names_to_remove.each do |s|
                      if space.name.to_s == s
                        if space.thermalZone.is_initialized
                          space.thermalZone.get.remove
                        end
                        space.remove
                      end
                    end
                  end
                end

              else # has rear units

                zone_names_for_multiplier_adjustment = []
                space_names_to_remove = []
                unit_spaces = unit_hash[unit_num].spaces
                if unit_num == 1 + (num_units_per_floor * (building_floor - 1)) or unit_num == 2 + (num_units_per_floor * (building_floor - 1)) # leftmost units
                elsif unit_num == 3 + (num_units_per_floor * (building_floor - 1)) or unit_num == 4 + (num_units_per_floor * (building_floor - 1)) # leftmost interior units
                  unit_spaces.each do |space|
                    thermal_zone = space.thermalZone.get
                    zone_names_for_multiplier_adjustment << thermal_zone.name.to_s
                  end
                  model.getThermalZones.each do |thermal_zone|
                    zone_names_for_multiplier_adjustment.each do |tz|
                      if thermal_zone.name.to_s == tz
                        thermal_zone.setMultiplier(num_units_per_floor / 2 - 2)
                      end
                    end
                  end
                elsif unit_num != (building_floor * num_units_per_floor) - 1 and unit_num != building_floor * num_units_per_floor # interior units that get removed
                  unit_spaces.each do |space|
                    space_names_to_remove << space.name.to_s
                  end
                  unit_hash[unit_num].remove
                  model.getSpaces.each do |space|
                    space_names_to_remove.each do |s|
                      if space.name.to_s == s
                        if space.thermalZone.is_initialized
                          space.thermalZone.get.remove
                        end
                        space.remove
                      end
                    end
                  end
                end

              end
            end # end building floor
          end # end unit per floor
        end # end zone mult

        # floor multipliers
        if num_floors > 3

          floor_zs = []
          model.getSurfaces.each do |surface|
            next unless surface.surfaceType.downcase == "floor"
            floor_zs << Geometry.getSurfaceZValues([surface])[0]
          end
          floor_zs = floor_zs.uniq.sort.select{|x| x >= 0}
          
          floor_zs[2..-2].each do |floor_z|
            units_to_remove = []
            Geometry.get_building_units(model, runner).each do |unit|
              unit.spaces.each do |space|
                next unless floor_z == Geometry.get_space_floor_z(space)
                next if units_to_remove.include? unit
                units_to_remove << unit
              end
            end
            units_to_remove.each do |unit|
              unit.spaces.each do |space|
                if space.thermalZone.is_initialized
                  space.thermalZone.get.remove
                end
                space.remove
              end
              unit.remove
            end
          end
          
          Geometry.get_building_units(model, runner).each do |unit|
            unit.spaces.each do |space|
              next unless floor_zs[1] == Geometry.get_space_floor_z(space)
              thermal_zone = space.thermalZone.get
              thermal_zone.setMultiplier(thermal_zone.multiplier * (num_floors - 2))
            end
          end
          
        end # end floor mult
      
      end

    end

    model.getSurfaces.each do |surface|
      next unless surface.outsideBoundaryCondition.downcase == "surface"
      next if surface.adjacentSurface.is_initialized
      surface.setOutsideBoundaryCondition("Adiabatic")
    end

    # remove orphaned air loops
    model.getAirLoopHVACs.each do |air_loop|
      next unless air_loop.thermalZones.empty?
      air_loop.remove
    end

    # remove orphaned plant loops
    plant_loops = []
    model.getPlantLoops.each do |plant_loop|
      plant_loop.supplyComponents.each do |supply_component|
        water_heater = nil
        if supply_component.to_WaterHeaterMixed.is_initialized
          water_heater = supply_component.to_WaterHeaterMixed.get
        elsif supply_component.to_WaterHeaterStratified.is_initialized
          water_heater = supply_component.to_WaterHeaterStratified.get
        end
        unless water_heater.nil?
          next if water_heater.ambientTemperatureThermalZone.is_initialized
          unless plant_loops.include? plant_loop
            plant_loops << plant_loop
          end
        end
      end
    end
    plant_loops.each do |plant_loop|
      plant_loop.remove
    end

    # remove orphaned ems actuators
    model.getEnergyManagementSystemActuators.each do |ems_actuator|
      next if ems_actuator.actuatedComponent.is_initialized
      ems_actuator.remove
    end

    # remove orphaned ems sensors and programs
    model.getEnergyManagementSystemSensors.each do |ems_sensor|
      next if ems_sensor.keyName.empty?
      remove_sensor = true
      (model.getAirLoopHVACs + model.getThermalZones + model.getScheduleRulesets + model.getFanOnOffs + model.getNodes + model.getScheduleConstants + model.getScheduleIntervals).each do |obj|
        if obj.to_AirLoopHVAC.is_initialized
          obj = obj.demandInletNode
        end
        next unless obj.name.to_s == ems_sensor.keyName.to_s
        remove_sensor = false
        break
      end
      next unless remove_sensor
      model.getEnergyManagementSystemProgramCallingManagers.each do |ems_program_calling_manager|
        ems_program_calling_manager.programs.each do |ems_program|
          remove_program = false
          ems_program.lines.each do |line|
            next unless line.include? ems_sensor.name.to_s
            remove_program = true
            break
          end
          next unless remove_program
          ems_program.remove
        end
      end
      ems_sensor.remove
    end
    
    # remove orphaned ems program calling managers
    model.getEnergyManagementSystemProgramCallingManagers.each do |ems_program_calling_manager|
      next unless ems_program_calling_manager.programs.empty?
      ems_program_calling_manager.remove
    end

    runner.registerFinalCondition("Model finished with #{model.getThermalZones.length} thermal zones.")

    return true

  end

end

# register the measure to be used by the application
ZoneMultipliers.new.registerWithApplication
