require 'openstudio'

# start the measure
class SimulationOutputReport < OpenStudio::Measure::ReportingMeasure
  # define the name that a user will see, this method may be deprecated as
  # the display name in PAT comes from the name field in measure.xml
  def name
    return "Simulation Output Report"
  end

  def description
    return "Reports simulation outputs of interest."
  end

  # define the arguments that the user will input
  def arguments()
    args = OpenStudio::Ruleset::OSArgumentVector.new

    return args
  end # end the arguments method

  # return a vector of IdfObject's to request EnergyPlus objects needed by the run method
  def energyPlusOutputRequests(runner, user_arguments)
    super(runner, user_arguments)

    results = OpenStudio::IdfObjectVector.new

    # get the last model and sql file
    model = runner.lastOpenStudioModel
    if model.empty?
      runner.registerError("Cannot find last model.")
      return false
    end
    model = model.get

    # Get building units
    units = Geometry.get_building_units(model, runner)

    units.each do |unit|
      # Get all zones in unit
      thermal_zones = []
      unit.spaces.each do |space|
        thermal_zone = space.thermalZone.get
        unless thermal_zones.include? thermal_zone
          thermal_zones << thermal_zone
        end
      end

      # Electricity Heating
      electricity_heating = []
      central_electricity_heating = []
      thermal_zones.each do |thermal_zone|
        heating_equipment = HVAC.existing_heating_equipment(model, runner, thermal_zone)
        heating_equipment.each do |htg_equip|
          clg_coil, htg_coil, supp_htg_coil = HVAC.get_coils_from_hvac_equip(htg_equip)

          if htg_equip.is_a? OpenStudio::Model::AirLoopHVACUnitarySystem

            electricity_heating << ["#{htg_coil.name}", "Heating Coil Electric Energy"]
            electricity_heating << ["#{htg_equip.name}", "Unitary System Heating Ancillary Electric Energy"]

            unless htg_coil.is_a? OpenStudio::Model::CoilCoolingWaterToAirHeatPumpEquationFit
              electricity_heating << ["#{htg_coil.name}", "Heating Coil Defrost Electric Energy"]
              electricity_heating << ["#{htg_coil.name}", "Heating Coil Crankcase Heater Electric Energy"]
            end

            unless supp_htg_coil.nil?
              electricity_heating << ["#{supp_htg_coil.name}", "Heating Coil Electric Energy"]
            end

          elsif htg_equip.is_a? OpenStudio::Model::ZoneHVACBaseboardConvectiveWater

            model.getPlantLoops.each do |plant_loop|
              is_specified_zone = false
              units_served = []
              plant_loop.demandComponents.each do |demand_component|
                next unless demand_component.to_CoilHeatingWaterBaseboard.is_initialized

                demand_coil = demand_component.to_CoilHeatingWaterBaseboard.get
                thermal_zone_served = demand_coil.containingZoneHVACComponent.get.thermalZone.get
                thermal_zone_served.spaces.each do |space_served|
                  unit_served = space_served.buildingUnit.get
                  next if units_served.include? unit_served

                  units_served << unit_served
                end
                next if thermal_zone_served != thermal_zone

                is_specified_zone = true
              end
              next unless is_specified_zone

              plant_loop.supplyComponents.each do |supply_component|
                next unless supply_component.to_BoilerHotWater.is_initialized

                if units_served.length != 1 # this is a central system
                  central_electricity_heating << ["#{supply_component.name}", "Boiler Electric Energy"]
                  central_electricity_heating << ["#{supply_component.name}", "Boiler Ancillary Electric Energy"]
                else
                  electricity_heating << ["#{supply_component.name}", "Boiler Electric Energy"]
                  electricity_heating << ["#{supply_component.name}", "Boiler Ancillary Electric Energy"]
                end
              end
            end

          elsif htg_equip.is_a? OpenStudio::Model::ZoneHVACBaseboardConvectiveElectric

            electricity_heating << ["#{htg_equip.name}", "Baseboard Electric Energy"]

          elsif htg_equip.is_a? OpenStudio::Model::ZoneHVACFourPipeFanCoil or htg_equip.is_a? OpenStudio::Model::ZoneHVACPackagedTerminalAirConditioner

            model.getPlantLoops.each do |plant_loop|
              is_specified_zone = false
              units_served = []
              plant_loop.demandComponents.each do |demand_component|
                next unless demand_component.to_CoilHeatingWater.is_initialized

                demand_coil = demand_component.to_CoilHeatingWater.get
                thermal_zone_served = demand_coil.containingZoneHVACComponent.get.thermalZone.get
                thermal_zone_served.spaces.each do |space_served|
                  unit_served = space_served.buildingUnit.get
                  next if units_served.include? unit_served

                  units_served << unit_served
                end
                next if thermal_zone_served != thermal_zone

                is_specified_zone = true
              end
              next unless is_specified_zone

              plant_loop.supplyComponents.each do |supply_component|
                next unless supply_component.to_BoilerHotWater.is_initialized

                if units_served.length != 1 # this is a central system
                  central_electricity_heating << ["#{supply_component.name}", "Boiler Electric Energy"]
                  central_electricity_heating << ["#{supply_component.name}", "Boiler Ancillary Electric Energy"]
                else
                  electricity_heating << ["#{supply_component.name}", "Boiler Electric Energy"]
                  electricity_heating << ["#{supply_component.name}", "Boiler Ancillary Electric Energy"]
                end
              end
            end

          end
        end
      end

      results = create_custom_meter(results, "#{unit.name}:ElectricityHeating", electricity_heating)
      results = create_custom_meter(results, "Central:ElectricityHeating", central_electricity_heating)

      # Electricity Cooling
      electricity_cooling = []
      central_electricity_cooling = []
      thermal_zones.each do |thermal_zone|
        cooling_equipment = HVAC.existing_cooling_equipment(model, runner, thermal_zone)
        cooling_equipment.each do |clg_equip|
          clg_coil, htg_coil, supp_htg_coil = HVAC.get_coils_from_hvac_equip(clg_equip)

          if clg_equip.is_a? OpenStudio::Model::AirLoopHVACUnitarySystem

            electricity_cooling << ["#{clg_coil.name}", "Cooling Coil Electric Energy"]

            unless clg_coil.is_a? OpenStudio::Model::CoilCoolingWaterToAirHeatPumpEquationFit
              electricity_cooling << ["#{clg_coil.name}", "Cooling Coil Crankcase Heater Electric Energy"]
            end

          elsif clg_equip.is_a? OpenStudio::Model::ZoneHVACPackagedTerminalAirConditioner

            electricity_cooling << ["#{clg_coil.name}", "Cooling Coil Electric Energy"]

          elsif clg_equip.is_a? OpenStudio::Model::ZoneHVACFourPipeFanCoil

            model.getPlantLoops.each do |plant_loop|
              is_specified_zone = false
              units_served = []
              plant_loop.demandComponents.each do |demand_component|
                next unless demand_component.to_CoilCoolingWater.is_initialized

                demand_coil = demand_component.to_CoilCoolingWater.get
                thermal_zone_served = demand_coil.containingZoneHVACComponent.get.thermalZone.get
                thermal_zone_served.spaces.each do |space_served|
                  unit_served = space_served.buildingUnit.get
                  next if units_served.include? unit_served

                  units_served << unit_served
                end
                next if thermal_zone_served != thermal_zone

                is_specified_zone = true
              end
              next unless is_specified_zone

              plant_loop.supplyComponents.each do |supply_component|
                next unless supply_component.to_ChillerElectricEIR.is_initialized

                if units_served.length != 1 # this is a central system
                  central_electricity_cooling << ["#{supply_component.name}", "Chiller Electric Energy"]
                else
                  electricity_cooling << ["#{supply_component.name}", "Chiller Electric Energy"]
                end
              end
            end

          end
        end
      end

      results = create_custom_meter(results, "#{unit.name}:ElectricityCooling", electricity_cooling)
      results = create_custom_meter(results, "Central:ElectricityCooling", central_electricity_cooling)

      # Electricity Interior Lighting
      electricity_interior_lighting = []
      thermal_zones.each do |thermal_zone|
        electricity_interior_lighting << ["", "InteriorLights:Electricity:Zone:#{thermal_zone.name}"]
      end

      results = create_custom_meter(results, "#{unit.name}:ElectricityInteriorLighting", electricity_interior_lighting)

      # Electricity Fans Heating
      electricity_fans_heating = []
      thermal_zones.each do |thermal_zone|
        heating_equipment = HVAC.existing_heating_equipment(model, runner, thermal_zone)
        heating_equipment.each do |htg_equip|
          clg_coil, htg_coil, supp_htg_coil = HVAC.get_coils_from_hvac_equip(htg_equip)

          if htg_equip.is_a? OpenStudio::Model::AirLoopHVACUnitarySystem

            electricity_fans_heating << ["#{htg_equip.supplyFan.get.name}", "Fan Electric Energy"]

          end
        end
      end
      model.getPlantLoops.each do |plant_loop|
        if plant_loop.name.to_s == Constants.PlantLoopDomesticWater(unit.name.to_s)

          water_heater = Waterheater.get_water_heater(model, plant_loop, runner)

          if water_heater.is_a? OpenStudio::Model::WaterHeaterHeatPumpWrappedCondenser

            electricity_fans_heating << ["#{water_heater.fan.name}", "Fan Electric Energy"]

          end
        end
      end

      results = create_custom_meter(results, "#{unit.name}:ElectricityFansHeating", electricity_fans_heating)

      # Electricity Fans Cooling
      electricity_fans_cooling = []
      thermal_zones.each do |thermal_zone|
        cooling_equipment = HVAC.existing_cooling_equipment(model, runner, thermal_zone)
        cooling_equipment.each do |clg_equip|
          clg_coil, htg_coil, supp_htg_coil = HVAC.get_coils_from_hvac_equip(clg_equip)

          if clg_equip.is_a? OpenStudio::Model::AirLoopHVACUnitarySystem

            electricity_fans_cooling << ["#{clg_equip.supplyFan.get.name}", "Fan Electric Energy"]

          elsif clg_equip.is_a? OpenStudio::Model::ZoneHVACPackagedTerminalAirConditioner or clg_equip.is_a? OpenStudio::Model::ZoneHVACFourPipeFanCoil

            electricity_fans_cooling << ["#{clg_equip.supplyAirFan.name}", "Fan Electric Energy"] # FIXME: all fan coil fan energy is assigned to fan cooling

          end
        end
      end

      results = create_custom_meter(results, "#{unit.name}:ElectricityFansCooling", electricity_fans_cooling)

      # Electricity Pumps Heating
      electricity_pumps_heating = []
      central_electricity_pumps_heating = []
      model.getEnergyManagementSystemOutputVariables.each do |ems_output_var|
        if ems_output_var.name.to_s.include? "Central htg pump:Pumps:Electricity"

          central_electricity_pumps_heating << ["", "#{ems_output_var.name}"]

        elsif ems_output_var.name.to_s.include? "htg pump:Pumps:Electricity" and ems_output_var.emsVariableName.include? unit.name.to_s.gsub(" ", "_")

          electricity_pumps_heating << ["", "#{ems_output_var.name}"]

        end
      end

      results = create_custom_meter(results, "#{unit.name}:ElectricityPumpsHeating", electricity_pumps_heating)
      results = create_custom_meter(results, "Central:ElectricityPumpsHeating", central_electricity_pumps_heating)

      # Electricity Pumps Cooling
      electricity_pumps_cooling = []
      central_electricity_pumps_cooling = []
      model.getEnergyManagementSystemOutputVariables.each do |ems_output_var|
        if ems_output_var.name.to_s.include? "Central clg pump:Pumps:Electricity"

          central_electricity_pumps_cooling << ["", "#{ems_output_var.name}"]

        elsif ems_output_var.name.to_s.include? "clg pump:Pumps:Electricity" and ems_output_var.emsVariableName.include? unit.name.to_s.gsub(" ", "_")

          electricity_pumps_cooling << ["", "#{ems_output_var.name}"]

        end
      end

      results = create_custom_meter(results, "#{unit.name}:ElectricityPumpsCooling", electricity_pumps_cooling)
      results = create_custom_meter(results, "Central:ElectricityPumpsCooling", central_electricity_pumps_cooling)

      # Electricity Water Systems
      electricity_water_systems = []
      model.getPlantLoops.each do |plant_loop|
        if plant_loop.name.to_s == Constants.PlantLoopDomesticWater(unit.name.to_s)

          water_heater = Waterheater.get_water_heater(model, plant_loop, runner)

          if water_heater.is_a? OpenStudio::Model::WaterHeaterMixed

            electricity_water_systems << ["#{water_heater.name}", "Water Heater Off Cycle Parasitic Electric Energy"]
            electricity_water_systems << ["#{water_heater.name}", "Water Heater On Cycle Parasitic Electric Energy"]
            next if water_heater.heaterFuelType != "Electricity"

            electricity_water_systems << ["#{water_heater.name}", "Water Heater Electric Energy"]

          elsif water_heater.is_a? OpenStudio::Model::WaterHeaterHeatPumpWrappedCondenser

            electricity_water_systems << ["#{water_heater.name}", "Water Heater Off Cycle Ancillary Electric Energy"]
            electricity_water_systems << ["#{water_heater.name}", "Water Heater On Cycle Ancillary Electric Energy"]

            tank = water_heater.tank.to_WaterHeaterStratified.get
            electricity_water_systems << ["#{tank.name}", "Water Heater Electric Energy"]
            electricity_water_systems << ["#{tank.name}", "Water Heater Off Cycle Parasitic Electric Energy"]
            electricity_water_systems << ["#{tank.name}", "Water Heater On Cycle Parasitic Electric Energy"]

            coil = water_heater.dXCoil.to_CoilWaterHeatingAirToWaterHeatPumpWrapped.get
            electricity_water_systems << ["#{coil.name}", "Cooling Coil Crankcase Heater Electric Energy"]
            electricity_water_systems << ["#{coil.name}", "Cooling Coil Water Heating Electric Energy"]

          end

        end
      end
      shw_tank = Waterheater.get_shw_storage_tank(model, unit)
      unless shw_tank.nil?

        electricity_water_systems << ["#{shw_tank.name}", "Water Heater Electric Energy"]
        electricity_water_systems << ["#{shw_tank.name}", "Water Heater Off Cycle Parasitic Electric Energy"]
        electricity_water_systems << ["#{shw_tank.name}", "Water Heater On Cycle Parasitic Electric Energy"]

      end

      results = create_custom_meter(results, "#{unit.name}:ElectricityWaterSystems", electricity_water_systems)

      # Natural Gas Heating
      natural_gas_heating = []
      central_natural_gas_heating = []
      thermal_zones.each do |thermal_zone|
        heating_equipment = HVAC.existing_heating_equipment(model, runner, thermal_zone)
        heating_equipment.each do |htg_equip|
          clg_coil, htg_coil, supp_htg_coil = HVAC.get_coils_from_hvac_equip(htg_equip)

          if htg_equip.is_a? OpenStudio::Model::AirLoopHVACUnitarySystem

            natural_gas_heating << ["#{htg_coil.name}", "Heating Coil Gas Energy"]
            natural_gas_heating << ["#{htg_coil.name}", "Heating Coil Ancillary Gas Energy"]

          elsif htg_equip.is_a? OpenStudio::Model::ZoneHVACBaseboardConvectiveWater

            model.getPlantLoops.each do |plant_loop|
              is_specified_zone = false
              units_served = []
              plant_loop.demandComponents.each do |demand_component|
                next unless demand_component.to_CoilHeatingWaterBaseboard.is_initialized

                demand_coil = demand_component.to_CoilHeatingWaterBaseboard.get
                thermal_zone_served = demand_coil.containingZoneHVACComponent.get.thermalZone.get
                thermal_zone_served.spaces.each do |space_served|
                  unit_served = space_served.buildingUnit.get
                  next if units_served.include? unit_served

                  units_served << unit_served
                end
                next if thermal_zone_served != thermal_zone

                is_specified_zone = true
              end
              next unless is_specified_zone

              plant_loop.supplyComponents.each do |supply_component|
                next unless supply_component.to_BoilerHotWater.is_initialized
                next if supply_component.to_BoilerHotWater.get.fuelType != "NaturalGas"

                if units_served.length != 1 # this is a central system
                  central_natural_gas_heating << ["#{supply_component.name}", "Boiler Gas Energy"]
                else
                  natural_gas_heating << ["#{supply_component.name}", "Boiler Gas Energy"]
                end
              end
            end

          elsif htg_equip.is_a? OpenStudio::Model::ZoneHVACFourPipeFanCoil or htg_equip.is_a? OpenStudio::Model::ZoneHVACPackagedTerminalAirConditioner

            model.getPlantLoops.each do |plant_loop|
              is_specified_zone = false
              units_served = []
              plant_loop.demandComponents.each do |demand_component|
                next unless demand_component.to_CoilHeatingWater.is_initialized

                demand_coil = demand_component.to_CoilHeatingWater.get
                thermal_zone_served = demand_coil.containingZoneHVACComponent.get.thermalZone.get
                thermal_zone_served.spaces.each do |space_served|
                  unit_served = space_served.buildingUnit.get
                  next if units_served.include? unit_served

                  units_served << unit_served
                end
                next if thermal_zone_served != thermal_zone

                is_specified_zone = true
              end
              next unless is_specified_zone

              plant_loop.supplyComponents.each do |supply_component|
                next unless supply_component.to_BoilerHotWater.is_initialized

                if units_served.length != 1 # this is a central system
                  central_natural_gas_heating << ["#{supply_component.name}", "Boiler Gas Energy"]
                else
                  natural_gas_heating << ["#{supply_component.name}", "Boiler Gas Energy"]
                end
              end
            end

          end
        end
      end

      results = create_custom_meter(results, "#{unit.name}:NaturalGasHeating", natural_gas_heating, "NaturalGas")
      results = create_custom_meter(results, "Central:NaturalGasHeating", central_natural_gas_heating, "NaturalGas")

      # Natural Gas Water Systems
      natural_gas_water_systems = []
      model.getPlantLoops.each do |plant_loop|
        if plant_loop.name.to_s == Constants.PlantLoopDomesticWater(unit.name.to_s)

          water_heater = Waterheater.get_water_heater(model, plant_loop, runner)
          next unless water_heater.is_a? OpenStudio::Model::WaterHeaterMixed
          next if water_heater.heaterFuelType != "NaturalGas"

          natural_gas_water_systems << ["#{water_heater.name}", "Water Heater Gas Energy"]

        end
      end

      results = create_custom_meter(results, "#{unit.name}:NaturalGasWaterSystems", natural_gas_water_systems, "NaturalGas")

      # Fuel Oil Heating
      fuel_oil_heating = []
      central_fuel_oil_heating = []
      thermal_zones.each do |thermal_zone|
        heating_equipment = HVAC.existing_heating_equipment(model, runner, thermal_zone)
        heating_equipment.each do |htg_equip|
          clg_coil, htg_coil, supp_htg_coil = HVAC.get_coils_from_hvac_equip(htg_equip)

          if htg_equip.is_a? OpenStudio::Model::AirLoopHVACUnitarySystem

            fuel_oil_heating << ["#{htg_coil.name}", "Heating Coil FuelOil#1 Energy"]
            fuel_oil_heating << ["#{htg_coil.name}", "Heating Coil Ancillary FuelOil#1 Energy"]

          elsif htg_equip.is_a? OpenStudio::Model::ZoneHVACBaseboardConvectiveWater

            model.getPlantLoops.each do |plant_loop|
              is_specified_zone = false
              units_served = []
              plant_loop.demandComponents.each do |demand_component|
                next unless demand_component.to_CoilHeatingWaterBaseboard.is_initialized

                demand_coil = demand_component.to_CoilHeatingWaterBaseboard.get
                thermal_zone_served = demand_coil.containingZoneHVACComponent.get.thermalZone.get
                thermal_zone_served.spaces.each do |space_served|
                  unit_served = space_served.buildingUnit.get
                  next if units_served.include? unit_served

                  units_served << unit_served
                end
                next if thermal_zone_served != thermal_zone

                is_specified_zone = true
              end
              next unless is_specified_zone

              plant_loop.supplyComponents.each do |supply_component|
                next unless supply_component.to_BoilerHotWater.is_initialized
                next if supply_component.to_BoilerHotWater.get.fuelType != "FuelOil#1"

                if units_served.length != 1 # this is a central system
                  central_fuel_oil_heating << ["#{supply_component.name}", "Boiler FuelOil#1 Energy"]
                else
                  fuel_oil_heating << ["#{supply_component.name}", "Boiler FuelOil#1 Energy"]
                end
              end
            end

          elsif htg_equip.is_a? OpenStudio::Model::ZoneHVACFourPipeFanCoil or htg_equip.is_a? OpenStudio::Model::ZoneHVACPackagedTerminalAirConditioner

            model.getPlantLoops.each do |plant_loop|
              is_specified_zone = false
              units_served = []
              plant_loop.demandComponents.each do |demand_component|
                next unless demand_component.to_CoilHeatingWater.is_initialized

                demand_coil = demand_component.to_CoilHeatingWater.get
                thermal_zone_served = demand_coil.containingZoneHVACComponent.get.thermalZone.get
                thermal_zone_served.spaces.each do |space_served|
                  unit_served = space_served.buildingUnit.get
                  next if units_served.include? unit_served

                  units_served << unit_served
                end
                next if thermal_zone_served != thermal_zone

                is_specified_zone = true
              end
              next unless is_specified_zone

              plant_loop.supplyComponents.each do |supply_component|
                next unless supply_component.to_BoilerHotWater.is_initialized

                if units_served.length != 1 # this is a central system
                  central_fuel_oil_heating << ["#{supply_component.name}", "Boiler FuelOil#1 Energy"]
                else
                  fuel_oil_heating << ["#{supply_component.name}", "Boiler FuelOil#1 Energy"]
                end
              end
            end

          end
        end
      end

      results = create_custom_meter(results, "#{unit.name}:FuelOilHeating", fuel_oil_heating, "FuelOil#1")
      results = create_custom_meter(results, "Central:FuelOilHeating", central_fuel_oil_heating, "FuelOil#1")

      # Fuel Oil Interior Equipment
      fuel_oil_interior_equipment = []
      unit.spaces.each do |space|
        space.otherEquipment.each do |equip|
          next if equip.fuelType != "FuelOil#1"

          fuel_oil_interior_equipment << ["#{equip.name}", "Other Equipment FuelOil#1 Energy"]
        end
      end

      results = create_custom_meter(results, "#{unit.name}:FuelOilInteriorEquipment", fuel_oil_interior_equipment, "FuelOil#1")

      # Fuel Oil Water Systems
      fuel_oil_water_systems = []
      model.getPlantLoops.each do |plant_loop|
        if plant_loop.name.to_s == Constants.PlantLoopDomesticWater(unit.name.to_s)

          water_heater = Waterheater.get_water_heater(model, plant_loop, runner)
          next unless water_heater.is_a? OpenStudio::Model::WaterHeaterMixed
          next if water_heater.heaterFuelType != "FuelOil#1"

          fuel_oil_water_systems << ["#{water_heater.name}", "Water Heater FuelOil#1 Energy"]

        end
      end

      results = create_custom_meter(results, "#{unit.name}:FuelOilWaterSystems", fuel_oil_water_systems, "FuelOil#1")

      # Propane Heating
      propane_heating = []
      central_propane_heating = []
      thermal_zones.each do |thermal_zone|
        heating_equipment = HVAC.existing_heating_equipment(model, runner, thermal_zone)
        heating_equipment.each do |htg_equip|
          clg_coil, htg_coil, supp_htg_coil = HVAC.get_coils_from_hvac_equip(htg_equip)

          if htg_equip.is_a? OpenStudio::Model::AirLoopHVACUnitarySystem

            propane_heating << ["#{htg_coil.name}", "Heating Coil Propane Energy"]
            propane_heating << ["#{htg_coil.name}", "Heating Coil Ancillary Propane Energy"]

          elsif htg_equip.is_a? OpenStudio::Model::ZoneHVACBaseboardConvectiveWater

            model.getPlantLoops.each do |plant_loop|
              is_specified_zone = false
              units_served = []
              plant_loop.demandComponents.each do |demand_component|
                next unless demand_component.to_CoilHeatingWaterBaseboard.is_initialized

                demand_coil = demand_component.to_CoilHeatingWaterBaseboard.get
                thermal_zone_served = demand_coil.containingZoneHVACComponent.get.thermalZone.get
                thermal_zone_served.spaces.each do |space_served|
                  unit_served = space_served.buildingUnit.get
                  next if units_served.include? unit_served

                  units_served << unit_served
                end
                next if thermal_zone_served != thermal_zone

                is_specified_zone = true
              end
              next unless is_specified_zone

              plant_loop.supplyComponents.each do |supply_component|
                next unless supply_component.to_BoilerHotWater.is_initialized
                next if supply_component.to_BoilerHotWater.get.fuelType != "Propane"

                if units_served.length != 1 # this is a central system
                  central_propane_heating << ["#{supply_component.name}", "Boiler Propane Energy"]
                else
                  propane_heating << ["#{supply_component.name}", "Boiler Propane Energy"]
                end
              end
            end

          elsif htg_equip.is_a? OpenStudio::Model::ZoneHVACFourPipeFanCoil or htg_equip.is_a? OpenStudio::Model::ZoneHVACPackagedTerminalAirConditioner

            model.getPlantLoops.each do |plant_loop|
              is_specified_zone = false
              units_served = []
              plant_loop.demandComponents.each do |demand_component|
                next unless demand_component.to_CoilHeatingWater.is_initialized

                demand_coil = demand_component.to_CoilHeatingWater.get
                thermal_zone_served = demand_coil.containingZoneHVACComponent.get.thermalZone.get
                thermal_zone_served.spaces.each do |space_served|
                  unit_served = space_served.buildingUnit.get
                  next if units_served.include? unit_served

                  units_served << unit_served
                end
                next if thermal_zone_served != thermal_zone

                is_specified_zone = true
              end
              next unless is_specified_zone

              plant_loop.supplyComponents.each do |supply_component|
                next unless supply_component.to_BoilerHotWater.is_initialized

                if units_served.length != 1 # this is a central system
                  central_propane_heating << ["#{supply_component.name}", "Boiler Propane Energy"]
                else
                  propane_heating << ["#{supply_component.name}", "Boiler Propane Energy"]
                end
              end
            end

          end
        end
      end

      results = create_custom_meter(results, "#{unit.name}:PropaneHeating", propane_heating, "PropaneGas")
      results = create_custom_meter(results, "Central:PropaneHeating", central_propane_heating, "PropaneGas")

      # Propane Interior Equipment
      propane_interior_equipment = []
      unit.spaces.each do |space|
        space.otherEquipment.each do |equip|
          next if equip.fuelType != "PropaneGas"

          propane_interior_equipment << ["#{equip.name}", "Other Equipment Propane Energy"]
        end
      end

      results = create_custom_meter(results, "#{unit.name}:PropaneInteriorEquipment", propane_interior_equipment, "PropaneGas")

      # Propane Water Systems
      propane_water_systems = []
      model.getPlantLoops.each do |plant_loop|
        if plant_loop.name.to_s == Constants.PlantLoopDomesticWater(unit.name.to_s)

          water_heater = Waterheater.get_water_heater(model, plant_loop, runner)
          next unless water_heater.is_a? OpenStudio::Model::WaterHeaterMixed
          next if water_heater.heaterFuelType != "PropaneGas"

          propane_water_systems << ["#{water_heater.name}", "Water Heater Propane Energy"]

        end
      end

      results = create_custom_meter(results, "#{unit.name}:PropaneWaterSystems", propane_water_systems, "PropaneGas")
    end

    return results
  end

  def create_custom_meter(results, name, key_var_groups, fuel_type = "Electricity")
    unless key_var_groups.empty?
      meter_custom = "Meter:Custom,#{name},#{fuel_type}"
      key_var_groups.each do |key_var_group|
        key, var = key_var_group
        meter_custom += ",#{key},#{var}"
      end
      meter_custom += ";"
      results << OpenStudio::IdfObject.load(meter_custom).get
      results << OpenStudio::IdfObject.load("Output:Meter,#{name},Annual;").get
    end
    return results
  end

  def outputs
    buildstock_outputs = [
      "total_site_energy_mbtu",
      "total_site_electricity_kwh",
      "total_site_natural_gas_therm",
      "total_site_fuel_oil_mbtu",
      "total_site_propane_mbtu",
      "net_site_energy_mbtu", # Incorporates PV
      "net_site_electricity_kwh", # Incorporates PV
      "electricity_heating_kwh",
      "electricity_cooling_kwh",
      "electricity_interior_lighting_kwh",
      "electricity_exterior_lighting_kwh",
      "electricity_interior_equipment_kwh",
      "electricity_fans_heating_kwh",
      "electricity_fans_cooling_kwh",
      "electricity_pumps_heating_kwh",
      "electricity_pumps_cooling_kwh",
      "electricity_water_systems_kwh",
      "electricity_pv_kwh",
      "natural_gas_heating_therm",
      "natural_gas_interior_equipment_therm",
      "natural_gas_water_systems_therm",
      "fuel_oil_heating_mbtu",
      "fuel_oil_interior_equipment_mbtu",
      "fuel_oil_water_systems_mbtu",
      "propane_heating_mbtu",
      "propane_interior_equipment_mbtu",
      "propane_water_systems_mbtu",
      "hours_heating_setpoint_not_met",
      "hours_cooling_setpoint_not_met",
      "hvac_cooling_capacity_w",
      "hvac_heating_capacity_w",
      "hvac_heating_supp_capacity_w",
      "upgrade_name",
      "upgrade_cost_usd",
      "upgrade_option_01_cost_usd",
      "upgrade_option_01_lifetime_yrs",
      "upgrade_option_02_cost_usd",
      "upgrade_option_02_lifetime_yrs",
      "upgrade_option_03_cost_usd",
      "upgrade_option_03_lifetime_yrs",
      "upgrade_option_04_cost_usd",
      "upgrade_option_04_lifetime_yrs",
      "upgrade_option_05_cost_usd",
      "upgrade_option_05_lifetime_yrs",
      "upgrade_option_06_cost_usd",
      "upgrade_option_06_lifetime_yrs",
      "upgrade_option_07_cost_usd",
      "upgrade_option_07_lifetime_yrs",
      "upgrade_option_08_cost_usd",
      "upgrade_option_08_lifetime_yrs",
      "upgrade_option_09_cost_usd",
      "upgrade_option_09_lifetime_yrs",
      "upgrade_option_10_cost_usd",
      "upgrade_option_10_lifetime_yrs",
      "weight"
    ]
    result = OpenStudio::Measure::OSOutputVector.new
    buildstock_outputs.each do |output|
      result << OpenStudio::Measure::OSOutput.makeDoubleOutput(output)
    end
    return result
  end

  # define what happens when the measure is run
  def run(runner, user_arguments)
    super(runner, user_arguments)

    # use the built-in error checking
    if not runner.validateUserArguments(arguments(), user_arguments)
      return false
    end

    # get the last model and sql file
    model = runner.lastOpenStudioModel
    if model.empty?
      runner.registerError("Cannot find last model.")
      return false
    end
    model = model.get

    sqlFile = runner.lastEnergyPlusSqlFile
    if sqlFile.empty?
      runner.registerError("Cannot find last sql file.")
      return false
    end
    sqlFile = sqlFile.get
    model.setSqlFile(sqlFile)

    # Load buildstock_file
    resources_dir = File.absolute_path(File.join(File.dirname(__FILE__), "..", "..", "lib", "resources")) # Should have been uploaded per 'Other Library Files' in analysis spreadsheet
    buildstock_file = File.join(resources_dir, "buildstock.rb")
    require File.join(File.dirname(buildstock_file), File.basename(buildstock_file, File.extname(buildstock_file)))

    total_site_units = "MBtu"
    elec_site_units = "kWh"
    gas_site_units = "therm"
    other_fuel_site_units = "MBtu"

    # Get meters that aren't tied to units (i.e., get apportioned evenly across units)
    centralElectricityHeating = 0.0
    centralElectricityCooling = 0.0
    centralElectricityPumpsHeating = 0.0
    centralElectricityPumpsCooling = 0.0
    centralNaturalGasHeating = 0.0
    centralFuelOilHeating = 0.0
    centralPropaneHeating = 0.0
    centralElectricityExteriorLighting = 0.0
    centralElectricityInteriorEquipment = 0.0
    centralNaturalGasInteriorEquipment = 0.0

    central_electricity_heating_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('CENTRAL:ELECTRICITYHEATING') AND ReportingFrequency='Annual' AND VariableUnits='J')"
    unless sqlFile.execAndReturnFirstDouble(central_electricity_heating_query).empty?
      centralElectricityHeating = sqlFile.execAndReturnFirstDouble(central_electricity_heating_query).get
    end

    central_electricity_cooling_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('CENTRAL:ELECTRICITYCOOLING') AND ReportingFrequency='Annual' AND VariableUnits='J')"
    unless sqlFile.execAndReturnFirstDouble(central_electricity_cooling_query).empty?
      centralElectricityCooling = sqlFile.execAndReturnFirstDouble(central_electricity_cooling_query).get
    end

    central_electricity_pumps_heating_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('CENTRAL:ELECTRICITYPUMPSHEATING') AND ReportingFrequency='Annual' AND VariableUnits='J')"
    unless sqlFile.execAndReturnFirstDouble(central_electricity_pumps_heating_query).empty?
      centralElectricityPumpsHeating = sqlFile.execAndReturnFirstDouble(central_electricity_pumps_heating_query).get
    end

    central_electricity_pumps_cooling_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('CENTRAL:ELECTRICITYPUMPSCOOLING') AND ReportingFrequency='Annual' AND VariableUnits='J')"
    unless sqlFile.execAndReturnFirstDouble(central_electricity_pumps_cooling_query).empty?
      centralElectricityPumpsCooling = sqlFile.execAndReturnFirstDouble(central_electricity_pumps_cooling_query).get
    end

    central_natural_gas_heating_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('CENTRAL:NATURALGASHEATING') AND ReportingFrequency='Annual' AND VariableUnits='J')"
    unless sqlFile.execAndReturnFirstDouble(central_natural_gas_heating_query).empty?
      centralNaturalGasHeating = sqlFile.execAndReturnFirstDouble(central_natural_gas_heating_query).get
    end

    central_fuel_oil_heating_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('CENTRAL:FUELOILHEATING') AND ReportingFrequency='Annual' AND VariableUnits='J')"
    unless sqlFile.execAndReturnFirstDouble(central_fuel_oil_heating_query).empty?
      centralFuelOilHeating = sqlFile.execAndReturnFirstDouble(central_fuel_oil_heating_query).get
    end

    central_propane_heating_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('CENTRAL:PROPANEHEATING') AND ReportingFrequency='Annual' AND VariableUnits='J')"
    unless sqlFile.execAndReturnFirstDouble(central_propane_heating_query).empty?
      centralPropaneHeating = sqlFile.execAndReturnFirstDouble(central_propane_heating_query).get
    end

    central_electricity_exterior_lighting_query = "SELECT Value from tabulardatawithstrings where (reportname = 'AnnualBuildingUtilityPerformanceSummary') and (ReportForString = 'Entire Facility') and (TableName = 'End Uses'  ) and (ColumnName ='Electricity') and (RowName = 'Exterior Lighting') and (Units = 'GJ')"
    unless sqlFile.execAndReturnFirstDouble(central_electricity_exterior_lighting_query).empty?
      centralElectricityExteriorLighting = sqlFile.execAndReturnFirstDouble(central_electricity_exterior_lighting_query).get
    end

    central_electricity_interior_equipment_query = "SELECT Value from tabulardatawithstrings where (reportname = 'AnnualBuildingUtilityPerformanceSummary') and (ReportForString = 'Entire Facility') and (TableName = 'End Uses'  ) and (ColumnName ='Electricity') and (RowName = 'Interior Equipment') and (Units = 'GJ')"
    unless sqlFile.execAndReturnFirstDouble(central_electricity_interior_equipment_query).empty?
      centralElectricityInteriorEquipment = sqlFile.execAndReturnFirstDouble(central_electricity_interior_equipment_query).get
    end

    central_natural_gas_interior_equipment_query = "SELECT Value from tabulardatawithstrings where (reportname = 'AnnualBuildingUtilityPerformanceSummary') and (ReportForString = 'Entire Facility') and (TableName = 'End Uses'  ) and (ColumnName ='Natural Gas') and (RowName = 'Interior Equipment') and (Units = 'GJ')"
    unless sqlFile.execAndReturnFirstDouble(central_natural_gas_interior_equipment_query).empty?
      centralNaturalGasInteriorEquipment = sqlFile.execAndReturnFirstDouble(central_natural_gas_interior_equipment_query).get
    end

    # Get building units
    units = Geometry.get_building_units(model, runner)
    if units.nil?
      return false
    end

    electricityTotalEndUses = 0.0
    electricityHeating = 0.0
    electricityCooling = 0.0
    electricityInteriorLighting = 0.0
    electricityExteriorLighting = 0.0
    electricityInteriorEquipment = 0.0
    naturalGasInteriorEquipment = 0.0
    fuelOilInteriorEquipment = 0.0
    propaneInteriorEquipment = 0.0
    electricityFansHeating = 0.0
    electricityFansCooling = 0.0
    electricityPumpsHeating = 0.0
    electricityPumpsCooling = 0.0
    electricityWaterSystems = 0.0
    naturalGasTotalEndUses = 0.0
    naturalGasHeating = 0.0
    naturalGasInteriorEquipment = 0.0
    naturalGasWaterSystems = 0.0
    fuelOilTotalEndUses = 0.0
    fuelOilHeating = 0.0
    fuelOilInteriorEquipment = 0.0
    fuelOilWaterSystems = 0.0
    propaneTotalEndUses = 0.0
    propaneHeating = 0.0
    propaneInteriorEquipment = 0.0
    propaneWaterSystems = 0.0
    hoursHeatingSetpointNotMet = 0.0
    hoursCoolingSetpointNotMet = 0.0
    units.each do |unit|
      unit_name = unit.name.to_s.upcase

      thermal_zones = []
      unit.spaces.each do |space|
        thermal_zone = space.thermalZone.get
        unless thermal_zones.include? thermal_zone
          thermal_zones << thermal_zone
        end
      end

      units_represented = 1
      if unit.additionalProperties.getFeatureAsInteger("Units Represented").is_initialized
        units_represented = unit.additionalProperties.getFeatureAsInteger("Units Represented").get
      end

      electricity_heating_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:ELECTRICITYHEATING') AND ReportingFrequency='Annual' AND VariableUnits='J')"
      unless sqlFile.execAndReturnFirstDouble(electricity_heating_query).empty?
        electricityHeating += units_represented * sqlFile.execAndReturnFirstDouble(electricity_heating_query).get
      end
      electricityHeating += units_represented * (centralElectricityHeating / units.length)

      electricity_cooling_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:ELECTRICITYCOOLING') AND ReportingFrequency='Annual' AND VariableUnits='J')"
      unless sqlFile.execAndReturnFirstDouble(electricity_cooling_query).empty?
        electricityCooling += units_represented * sqlFile.execAndReturnFirstDouble(electricity_cooling_query).get
      end
      electricityCooling += units_represented * (centralElectricityCooling / units.length)

      electricity_interior_lighting_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:ELECTRICITYINTERIORLIGHTING') AND ReportingFrequency='Annual' AND VariableUnits='J')"
      unless sqlFile.execAndReturnFirstDouble(electricity_interior_lighting_query).empty?
        electricityInteriorLighting += units_represented * sqlFile.execAndReturnFirstDouble(electricity_interior_lighting_query).get
      end

      electricityExteriorLighting += units_represented * (centralElectricityExteriorLighting / units.length)

      electricityInteriorEquipment += units_represented * (centralElectricityInteriorEquipment / units.length)

      electricity_fans_heating_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:ELECTRICITYFANSHEATING') AND ReportingFrequency='Annual' AND VariableUnits='J')"
      unless sqlFile.execAndReturnFirstDouble(electricity_fans_heating_query).empty?
        electricityFansHeating += units_represented * sqlFile.execAndReturnFirstDouble(electricity_fans_heating_query).get
      end

      electricity_fans_cooling_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:ELECTRICITYFANSCOOLING') AND ReportingFrequency='Annual' AND VariableUnits='J')"
      unless sqlFile.execAndReturnFirstDouble(electricity_fans_cooling_query).empty?
        electricityFansCooling += units_represented * sqlFile.execAndReturnFirstDouble(electricity_fans_cooling_query).get
      end

      electricity_pumps_heating_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:ELECTRICITYPUMPSHEATING') AND ReportingFrequency='Annual' AND VariableUnits='J')"
      unless sqlFile.execAndReturnFirstDouble(electricity_pumps_heating_query).empty?
        electricityPumpsHeating += units_represented * sqlFile.execAndReturnFirstDouble(electricity_pumps_heating_query).get
      end
      electricityPumpsHeating += units_represented * (centralElectricityPumpsHeating / units.length)

      electricity_pumps_cooling_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:ELECTRICITYPUMPSCOOLING') AND ReportingFrequency='Annual' AND VariableUnits='J')"
      unless sqlFile.execAndReturnFirstDouble(electricity_pumps_cooling_query).empty?
        electricityPumpsCooling += units_represented * sqlFile.execAndReturnFirstDouble(electricity_pumps_cooling_query).get
      end
      electricityPumpsCooling += units_represented * (centralElectricityPumpsCooling / units.length)

      electricity_water_systems_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:ELECTRICITYWATERSYSTEMS') AND ReportingFrequency='Annual' AND VariableUnits='J')"
      unless sqlFile.execAndReturnFirstDouble(electricity_water_systems_query).empty?
        electricityWaterSystems += units_represented * sqlFile.execAndReturnFirstDouble(electricity_water_systems_query).get
      end

      natural_gas_heating_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:NATURALGASHEATING') AND ReportingFrequency='Annual' AND VariableUnits='J')"
      unless sqlFile.execAndReturnFirstDouble(natural_gas_heating_query).empty?
        naturalGasHeating += units_represented * sqlFile.execAndReturnFirstDouble(natural_gas_heating_query).get
      end
      naturalGasHeating += units_represented * (centralNaturalGasHeating / units.length)

      naturalGasInteriorEquipment += units_represented * (centralNaturalGasInteriorEquipment / units.length)

      natural_gas_water_systems_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:NATURALGASWATERSYSTEMS') AND ReportingFrequency='Annual' AND VariableUnits='J')"
      unless sqlFile.execAndReturnFirstDouble(natural_gas_water_systems_query).empty?
        naturalGasWaterSystems += units_represented * sqlFile.execAndReturnFirstDouble(natural_gas_water_systems_query).get
      end

      fuel_oil_heating_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:FUELOILHEATING') AND ReportingFrequency='Annual' AND VariableUnits='J')"
      unless sqlFile.execAndReturnFirstDouble(fuel_oil_heating_query).empty?
        fuelOilHeating += units_represented * sqlFile.execAndReturnFirstDouble(fuel_oil_heating_query).get
      end
      fuelOilHeating += units_represented * (centralFuelOilHeating / units.length)

      fuel_oil_interior_equipment_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:FUELOILINTERIOREQUIPMENT') AND ReportingFrequency='Annual' AND VariableUnits='J')"
      unless sqlFile.execAndReturnFirstDouble(fuel_oil_interior_equipment_query).empty?
        fuelOilInteriorEquipment += units_represented * sqlFile.execAndReturnFirstDouble(fuel_oil_interior_equipment_query).get
      end

      fuel_oil_water_systems_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:FUELOILWATERSYSTEMS') AND ReportingFrequency='Annual' AND VariableUnits='J')"
      unless sqlFile.execAndReturnFirstDouble(fuel_oil_water_systems_query).empty?
        fuelOilWaterSystems += units_represented * sqlFile.execAndReturnFirstDouble(fuel_oil_water_systems_query).get
      end

      propane_heating_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:PROPANEHEATING') AND ReportingFrequency='Annual' AND VariableUnits='J')"
      unless sqlFile.execAndReturnFirstDouble(propane_heating_query).empty?
        propaneHeating += units_represented * sqlFile.execAndReturnFirstDouble(propane_heating_query).get
      end
      propaneHeating += units_represented * (centralPropaneHeating / units.length)

      propane_interior_equipment_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:PROPANEINTERIOREQUIPMENT') AND ReportingFrequency='Annual' AND VariableUnits='J')"
      unless sqlFile.execAndReturnFirstDouble(propane_interior_equipment_query).empty?
        propaneInteriorEquipment += units_represented * sqlFile.execAndReturnFirstDouble(propane_interior_equipment_query).get
      end

      propane_water_systems_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:PROPANEWATERSYSTEMS') AND ReportingFrequency='Annual' AND VariableUnits='J')"
      unless sqlFile.execAndReturnFirstDouble(propane_water_systems_query).empty?
        propaneWaterSystems += units_represented * sqlFile.execAndReturnFirstDouble(propane_water_systems_query).get
      end

      thermal_zones.each do |thermal_zone|
        thermal_zone_name = thermal_zone.name.to_s.upcase
        hours_heating_setpoint_not_met_query = "SELECT Value FROM TabularDataWithStrings WHERE (ReportName='SystemSummary') AND (ReportForString='Entire Facility') AND (TableName='Time Setpoint Not Met') AND (RowName = '#{thermal_zone_name}') AND (ColumnName='During Heating') AND (Units = 'hr')"
        unless sqlFile.execAndReturnFirstDouble(hours_heating_setpoint_not_met_query).empty?
          hoursHeatingSetpointNotMet += units_represented * sqlFile.execAndReturnFirstDouble(hours_heating_setpoint_not_met_query).get
        end

        hours_cooling_setpoint_not_met_query = "SELECT Value FROM TabularDataWithStrings WHERE (ReportName='SystemSummary') AND (ReportForString='Entire Facility') AND (TableName='Time Setpoint Not Met') AND (RowName = '#{thermal_zone_name}') AND (ColumnName='During Cooling') AND (Units = 'hr')"
        unless sqlFile.execAndReturnFirstDouble(hours_cooling_setpoint_not_met_query).empty?
          hoursCoolingSetpointNotMet += units_represented * sqlFile.execAndReturnFirstDouble(hours_cooling_setpoint_not_met_query).get
        end
      end
    end

    # ELECTRICITY

    # Get PV electricity produced
    pv_query = "SELECT -1*Value FROM TabularDataWithStrings WHERE ReportName='AnnualBuildingUtilityPerformanceSummary' AND ReportForString='Entire Facility' AND TableName='Electric Loads Satisfied' AND RowName='Total On-Site Electric Sources' AND ColumnName='Electricity' AND Units='GJ'"
    pv_val = 0.0
    unless sqlFile.execAndReturnFirstDouble(pv_query).empty?
      pv_val = sqlFile.execAndReturnFirstDouble(pv_query).get
    end
    report_sim_output(runner, "electricity_pv_kwh", pv_val, "GJ", elec_site_units)

    electricityTotalEndUses = electricityHeating + electricityCooling + electricityInteriorLighting + electricityExteriorLighting + electricityInteriorEquipment + electricityFansHeating + electricityFansCooling + electricityPumpsHeating + electricityPumpsCooling + electricityWaterSystems

    report_sim_output(runner, "total_site_electricity_kwh", electricityTotalEndUses, "GJ", elec_site_units)
    report_sim_output(runner, "net_site_electricity_kwh", electricityTotalEndUses + pv_val, "GJ", elec_site_units)
    report_sim_output(runner, "electricity_heating_kwh", electricityHeating, "GJ", elec_site_units)
    report_sim_output(runner, "electricity_cooling_kwh", electricityCooling, "GJ", elec_site_units)
    report_sim_output(runner, "electricity_interior_lighting_kwh", electricityInteriorLighting, "GJ", elec_site_units)
    report_sim_output(runner, "electricity_exterior_lighting_kwh", electricityExteriorLighting, "GJ", elec_site_units)
    report_sim_output(runner, "electricity_interior_equipment_kwh", electricityInteriorEquipment, "GJ", elec_site_units)
    unless sqlFile.electricityFans.empty?
      unless (sqlFile.electricityFans.get - (electricityFansHeating + electricityFansCooling)).abs < 0.01
        runner.registerError("Disaggregated fan energy relative to building fan energy: #{((electricityFansHeating+electricityFansCooling)-sqlFile.electricityFans.get)*100.0/sqlFile.electricityFans.get}%.")
        return false
      end
    end
    report_sim_output(runner, "electricity_fans_heating_kwh", electricityFansHeating, "GJ", elec_site_units)
    report_sim_output(runner, "electricity_fans_cooling_kwh", electricityFansCooling, "GJ", elec_site_units)
    unless sqlFile.electricityPumps.empty?
      unless (sqlFile.electricityPumps.get - (electricityPumpsHeating + electricityPumpsCooling)).abs < 0.01
        runner.registerError("Disaggregated pump energy relative to building pump energy: #{((electricityPumpsHeating+electricityPumpsCooling)-sqlFile.electricityPumps.get)*100.0/sqlFile.electricityPumps.get}%.")
        return false
      end
    end
    report_sim_output(runner, "electricity_pumps_heating_kwh", electricityPumpsHeating, "GJ", elec_site_units)
    report_sim_output(runner, "electricity_pumps_cooling_kwh", electricityPumpsCooling, "GJ", elec_site_units)
    report_sim_output(runner, "electricity_water_systems_kwh", electricityWaterSystems, "GJ", elec_site_units)

    # NATURAL GAS

    naturalGasTotalEndUses = naturalGasHeating + naturalGasInteriorEquipment + naturalGasWaterSystems

    report_sim_output(runner, "total_site_natural_gas_therm", naturalGasTotalEndUses, "GJ", gas_site_units)
    report_sim_output(runner, "natural_gas_heating_therm", naturalGasHeating, "GJ", gas_site_units)
    report_sim_output(runner, "natural_gas_interior_equipment_therm", naturalGasInteriorEquipment, "GJ", gas_site_units)
    report_sim_output(runner, "natural_gas_water_systems_therm", naturalGasWaterSystems, "GJ", gas_site_units)

    # FUEL OIL

    fuelOilTotalEndUses = fuelOilHeating + fuelOilInteriorEquipment + fuelOilWaterSystems

    report_sim_output(runner, "total_site_fuel_oil_mbtu", fuelOilTotalEndUses, "GJ", other_fuel_site_units)
    report_sim_output(runner, "fuel_oil_heating_mbtu", fuelOilHeating, "GJ", other_fuel_site_units)
    report_sim_output(runner, "fuel_oil_interior_equipment_mbtu", fuelOilInteriorEquipment, "GJ", other_fuel_site_units)
    report_sim_output(runner, "fuel_oil_water_systems_mbtu", fuelOilWaterSystems, "GJ", other_fuel_site_units)

    # PROPANE

    propaneTotalEndUses = propaneHeating + propaneInteriorEquipment + propaneWaterSystems

    report_sim_output(runner, "total_site_propane_mbtu", propaneTotalEndUses, "GJ", other_fuel_site_units)
    report_sim_output(runner, "propane_heating_mbtu", propaneHeating, "GJ", other_fuel_site_units)
    report_sim_output(runner, "propane_interior_equipment_mbtu", propaneInteriorEquipment, "GJ", other_fuel_site_units)
    report_sim_output(runner, "propane_water_systems_mbtu", propaneWaterSystems, "GJ", other_fuel_site_units)

    # TOTAL

    totalSiteEnergy = electricityTotalEndUses + naturalGasTotalEndUses + fuelOilTotalEndUses + propaneTotalEndUses

    unless sqlFile.totalSiteEnergy.empty?
      unless (sqlFile.totalSiteEnergy.get - totalSiteEnergy).abs < 0.01
        runner.registerError("Disaggregated total site energy relative to building total site energy: #{(totalSiteEnergy-sqlFile.totalSiteEnergy.get)*100.0/sqlFile.totalSiteEnergy.get}%.")
        return false
      end
    end
    report_sim_output(runner, "total_site_energy_mbtu", totalSiteEnergy, "GJ", total_site_units)
    report_sim_output(runner, "net_site_energy_mbtu", totalSiteEnergy + pv_val, "GJ", total_site_units)

    # LOADS NOT MET

    report_sim_output(runner, "hours_heating_setpoint_not_met", hoursHeatingSetpointNotMet, nil, nil)
    report_sim_output(runner, "hours_cooling_setpoint_not_met", hoursCoolingSetpointNotMet, nil, nil)

    # HVAC CAPACITIES

    conditioned_zones = get_conditioned_zones(model)
    hvac_cooling_capacity_kbtuh = get_cost_multiplier("Size, Cooling System (kBtu/h)", model, runner, conditioned_zones)
    return false if hvac_cooling_capacity_kbtuh.nil?

    report_sim_output(runner, "hvac_cooling_capacity_w", hvac_cooling_capacity_kbtuh, "kBtu/h", "W")
    hvac_heating_capacity_kbtuh = get_cost_multiplier("Size, Heating System (kBtu/h)", model, runner, conditioned_zones)
    return false if hvac_heating_capacity_kbtuh.nil?

    report_sim_output(runner, "hvac_heating_capacity_w", hvac_heating_capacity_kbtuh, "kBtu/h", "W")
    hvac_heating_supp_capacity_kbtuh = get_cost_multiplier("Size, Heating Supplemental System (kBtu/h)", model, runner, conditioned_zones)
    return false if hvac_heating_supp_capacity_kbtuh.nil?

    report_sim_output(runner, "hvac_heating_supp_capacity_w", hvac_heating_supp_capacity_kbtuh, "kBtu/h", "W")

    sqlFile.close()

    # WEIGHT

    weight = get_value_from_runner_past_results(runner, "weight", "build_existing_model", false)
    if not weight.nil?
      runner.registerValue("weight", weight.to_f)
      runner.registerInfo("Registering #{weight} for weight.")
    end

    # UPGRADE NAME
    upgrade_name = get_value_from_runner_past_results(runner, "upgrade_name", "apply_upgrade", false)
    if upgrade_name.nil?
      upgrade_name = ""
    end
    runner.registerValue("upgrade_name", upgrade_name)
    runner.registerInfo("Registering #{upgrade_name} for upgrade_name.")

    # UPGRADE COSTS

    upgrade_cost_name = "upgrade_cost_usd"

    # Get upgrade cost value/multiplier pairs and lifetimes from the upgrade measure
    has_costs = false
    option_cost_pairs = {}
    option_lifetimes = {}
    for option_num in 1..10 # Sync with ApplyUpgrade measure
      option_cost_pairs[option_num] = []
      option_lifetimes[option_num] = nil
      for cost_num in 1..2 # Sync with ApplyUpgrade measure
        cost_value = get_value_from_runner_past_results(runner, "option_#{option_num}_cost_#{cost_num}_value_to_apply", "apply_upgrade", false)
        next if cost_value.nil?

        cost_mult_type = get_value_from_runner_past_results(runner, "option_#{option_num}_cost_#{cost_num}_multiplier_to_apply", "apply_upgrade", false)
        next if cost_mult_type.nil?

        has_costs = true
        option_cost_pairs[option_num] << [cost_value.to_f, cost_mult_type]
      end
      lifetime = get_value_from_runner_past_results(runner, "option_#{option_num}_lifetime_to_apply", "apply_upgrade", false)
      next if lifetime.nil?

      option_lifetimes[option_num] = lifetime.to_f
    end

    if not has_costs
      runner.registerValue(upgrade_cost_name, "")
      runner.registerInfo("Registering (blank) for #{upgrade_cost_name}.")
      return true
    end

    # Obtain cost multiplier values and calculate upgrade costs
    upgrade_cost = 0.0
    option_cost_pairs.keys.each do |option_num|
      option_cost = 0.0
      option_cost_pairs[option_num].each do |cost_value, cost_mult_type|
        cost_mult = get_cost_multiplier(cost_mult_type, model, runner, conditioned_zones)
        if cost_mult.nil?
          return false
        end

        total_cost = cost_value * cost_mult
        option_cost += total_cost
        runner.registerInfo("Upgrade cost addition: $#{cost_value} x #{cost_mult} [#{cost_mult_type}] = #{total_cost}.")
      end
      upgrade_cost += option_cost

      # Save option cost/lifetime to results.csv
      if option_cost != 0
        option_num_str = option_num.to_s.rjust(2, '0')
        option_cost_str = option_cost.round(2).to_s
        option_cost_name = "upgrade_option_#{option_num_str}_cost_usd"
        runner.registerValue(option_cost_name, option_cost_str)
        runner.registerInfo("Registering #{option_cost_str} for #{option_cost_name}.")
        if not option_lifetimes[option_num].nil? and option_lifetimes[option_num] != 0
          lifetime_str = option_lifetimes[option_num].round(2).to_s
          option_lifetime_name = "upgrade_option_#{option_num_str}_lifetime_yrs"
          runner.registerValue(option_lifetime_name, lifetime_str)
          runner.registerInfo("Registering #{lifetime_str} for #{option_lifetime_name}.")
        end
      end
    end
    upgrade_cost_str = upgrade_cost.round(2).to_s
    runner.registerValue(upgrade_cost_name, upgrade_cost_str)
    runner.registerInfo("Registering #{upgrade_cost_str} for #{upgrade_cost_name}.")

    runner.registerFinalCondition("Report generated successfully.")

    return true
  end # end the run method

  def report_sim_output(runner, name, total_val, os_units, desired_units, percent_of_val = 1.0)
    total_val = total_val * percent_of_val
    if os_units.nil? or desired_units.nil? or os_units == desired_units
      valInUnits = total_val
    else
      valInUnits = OpenStudio::convert(total_val, os_units, desired_units).get
    end
    runner.registerValue(name, valInUnits)
    runner.registerInfo("Registering #{valInUnits.round(2)} for #{name}.")
  end

  def get_cost_multiplier(cost_mult_type, model, runner, conditioned_zones)
    cost_mult = 0.0

    if cost_mult_type == "Fixed (1)"
      cost_mult = 1.0

    elsif cost_mult_type == "Wall Area, Above-Grade, Conditioned (ft^2)"
      # Walls between conditioned space and 1) outdoors or 2) unconditioned space
      model.getSurfaces.each do |surface|
        next if surface.surfaceType.downcase != "wall"
        next if not surface.space.is_initialized
        next if not is_space_conditioned(surface.space.get, conditioned_zones)

        adjacent_space = get_adjacent_space(surface)
        if surface.outsideBoundaryCondition.downcase == "outdoors"
          cost_mult += OpenStudio::convert(surface.grossArea, "m^2", "ft^2").get
        elsif !adjacent_space.nil? and not is_space_conditioned(adjacent_space, conditioned_zones)
          cost_mult += OpenStudio::convert(surface.grossArea, "m^2", "ft^2").get
        end
      end

    elsif cost_mult_type == "Wall Area, Above-Grade, Exterior (ft^2)"
      # Walls adjacent to outdoors
      model.getSurfaces.each do |surface|
        next if surface.surfaceType.downcase != "wall"
        next if surface.outsideBoundaryCondition.downcase != "outdoors"

        cost_mult += OpenStudio::convert(surface.grossArea, "m^2", "ft^2").get
      end

    elsif cost_mult_type == "Wall Area, Below-Grade (ft^2)"
      # Walls adjacent to ground
      model.getSurfaces.each do |surface|
        next if surface.surfaceType.downcase != "wall"
        next if surface.outsideBoundaryCondition.downcase != "ground" and surface.outsideBoundaryCondition.downcase != "foundation"

        cost_mult += OpenStudio::convert(surface.grossArea, "m^2", "ft^2").get
      end

    elsif cost_mult_type == "Floor Area, Conditioned (ft^2)"
      # Floors of conditioned zone
      model.getSurfaces.each do |surface|
        next if surface.surfaceType.downcase != "floor"
        next if not surface.space.is_initialized
        next if not is_space_conditioned(surface.space.get, conditioned_zones)

        cost_mult += OpenStudio::convert(surface.grossArea, "m^2", "ft^2").get
      end

    elsif cost_mult_type == "Floor Area, Attic (ft^2)"
      # Floors under sloped surfaces and above conditioned space
      model.getSurfaces.each do |surface|
        next if surface.surfaceType.downcase != "floor"
        next if not surface.space.is_initialized

        space = surface.space.get
        next if not has_sloped_roof_surfaces(space)

        adjacent_space = get_adjacent_space(surface)
        next if adjacent_space.nil?
        next if not is_space_conditioned(adjacent_space, conditioned_zones)

        cost_mult += OpenStudio::convert(surface.grossArea, "m^2", "ft^2").get
      end

    elsif cost_mult_type == "Floor Area, Lighting (ft^2)"
      # Floors with lighting objects
      model.getSurfaces.each do |surface|
        next if surface.surfaceType.downcase != "floor"
        next if not surface.space.is_initialized
        next if surface.space.get.lights.size == 0

        cost_mult += OpenStudio::convert(surface.grossArea, "m^2", "ft^2").get
      end

    elsif cost_mult_type == "Roof Area (ft^2)"
      # Roofs adjacent to outdoors
      model.getSurfaces.each do |surface|
        next if surface.surfaceType.downcase != "roofceiling"
        next if surface.outsideBoundaryCondition.downcase != "outdoors"

        cost_mult += OpenStudio::convert(surface.grossArea, "m^2", "ft^2").get
      end

    elsif cost_mult_type == "Window Area (ft^2)"
      # Window subsurfaces
      model.getSurfaces.each do |surface|
        next if surface.surfaceType.downcase != "wall"

        surface.subSurfaces.each do |sub_surface|
          next if not sub_surface.subSurfaceType.downcase.include? "window"

          cost_mult += OpenStudio::convert(sub_surface.grossArea, "m^2", "ft^2").get
        end
      end

    elsif cost_mult_type == "Door Area (ft^2)"
      # Door subsurfaces
      model.getSurfaces.each do |surface|
        next if surface.surfaceType.downcase != "wall"

        surface.subSurfaces.each do |sub_surface|
          next if not sub_surface.subSurfaceType.downcase.include? "door"

          cost_mult += OpenStudio::convert(sub_surface.grossArea, "m^2", "ft^2").get
        end
      end

    elsif cost_mult_type == "Duct Surface Area (ft^2)"
      # Duct supply+return surface area
      model.getBuildingUnits.each do |unit|
        next if unit.spaces.size == 0

        if cost_mult > 0
          runner.registerError("Multiple building units found. This code should be reevaluated for correctness.")
          return nil
        end
        supply_area = unit.getFeatureAsDouble("SizingInfoDuctsSupplySurfaceArea")
        if supply_area.is_initialized
          cost_mult += supply_area.get
        end
        return_area = unit.getFeatureAsDouble("SizingInfoDuctsReturnSurfaceArea")
        if return_area.is_initialized
          cost_mult += return_area.get
        end
      end

    elsif cost_mult_type == "Size, Heating System (kBtu/h)"
      # Heating system capacity

      all_conditioned_zones = conditioned_zones

      model.getBuildingUnits.each do |unit|
        next if unit.spaces.empty?

        conditioned_zones = []
        unit.spaces.each do |space|
          zone = space.thermalZone.get
          next unless all_conditioned_zones.include? zone
          next if conditioned_zones.include? zone

          conditioned_zones << zone
        end

        units_represented = 1
        if unit.additionalProperties.getFeatureAsInteger("Units Represented").is_initialized
          units_represented = unit.additionalProperties.getFeatureAsInteger("Units Represented").get
        end

        component = nil

        # Unit heater?
        if component.nil?
          conditioned_zones.each do |zone|
            zone.equipment.each do |equipment|
              next unless equipment.to_AirLoopHVACUnitarySystem.is_initialized

              sys = equipment.to_AirLoopHVACUnitarySystem.get
              next unless conditioned_zones.include? sys.controllingZoneorThermostatLocation.get
              next if not sys.heatingCoil.is_initialized

              component = sys.heatingCoil.get
              next if not component.to_CoilHeatingGas.is_initialized

              coil = component.to_CoilHeatingGas.get
              next if not coil.nominalCapacity.is_initialized

              cost_mult += OpenStudio::convert(coil.nominalCapacity.get, "W", "kBtu/h").get
            end
          end
        end

        # Unitary system?
        if component.nil?
          model.getAirLoopHVACUnitarySystems.each do |sys|
            next unless conditioned_zones.include? sys.controllingZoneorThermostatLocation.get
            next if not sys.heatingCoil.is_initialized

            if not component.nil?
              runner.registerError("Multiple heating systems found. This code should be reevaluated for correctness.")
              return nil
            end
            component = sys.heatingCoil.get
          end
          if not component.nil?
            if component.to_CoilHeatingDXSingleSpeed.is_initialized
              coil = component.to_CoilHeatingDXSingleSpeed.get
              if coil.ratedTotalHeatingCapacity.is_initialized
                cost_mult += OpenStudio::convert(coil.ratedTotalHeatingCapacity.get, "W", "kBtu/h").get
              end
            elsif component.to_CoilHeatingDXMultiSpeed.is_initialized
              coil = component.to_CoilHeatingDXMultiSpeed.get
              if coil.stages.size > 0
                stage = coil.stages[coil.stages.size - 1]
                capacity_ratio = get_highest_stage_capacity_ratio(model, "SizingInfoHVACCapacityRatioCooling")
                if stage.grossRatedHeatingCapacity.is_initialized
                  cost_mult += OpenStudio::convert(stage.grossRatedHeatingCapacity.get / capacity_ratio, "W", "kBtu/h").get
                end
              end
            elsif component.to_CoilHeatingGas.is_initialized
              coil = component.to_CoilHeatingGas.get
              if coil.nominalCapacity.is_initialized
                cost_mult += OpenStudio::convert(coil.nominalCapacity.get, "W", "kBtu/h").get
              end
            elsif component.to_CoilHeatingElectric.is_initialized
              coil = component.to_CoilHeatingElectric.get
              if coil.nominalCapacity.is_initialized
                cost_mult += OpenStudio::convert(coil.nominalCapacity.get, "W", "kBtu/h").get
              end
            elsif component.to_CoilHeatingWaterToAirHeatPumpEquationFit.is_initialized
              coil = component.to_CoilHeatingWaterToAirHeatPumpEquationFit.get
              if coil.ratedHeatingCapacity.is_initialized
                cost_mult += OpenStudio::convert(coil.ratedHeatingCapacity.get, "W", "kBtu/h").get
              end
            end
          end
        end

        # Electric baseboard?
        if component.nil?
          max_value = 0.0
          model.getZoneHVACBaseboardConvectiveElectrics.each do |sys|
            next unless conditioned_zones.include? sys.thermalZone.get

            component = sys
            next if not component.nominalCapacity.is_initialized

            cost_mult += OpenStudio::convert(component.nominalCapacity.get, "W", "kBtu/h").get
          end
        end

        # Boiler?
        if component.nil?
          max_value = 0.0
          model.getPlantLoops.each do |pl|
            pl.components.each do |plc|
              next if not plc.to_BoilerHotWater.is_initialized

              component = plc.to_BoilerHotWater.get
              next if not component.nominalCapacity.is_initialized
              next if component.nominalCapacity.get <= max_value

              max_value = component.nominalCapacity.get
            end
          end
          cost_mult += OpenStudio::convert(max_value, "W", "kBtu/h").get
        end

        cost_mult *= units_represented
      end

    elsif cost_mult_type == "Size, Heating Supplemental System (kBtu/h)"
      # Supplemental heating system capacity

      all_conditioned_zones = conditioned_zones

      model.getBuildingUnits.each do |unit|
        next if unit.spaces.empty?

        conditioned_zones = []
        unit.spaces.each do |space|
          zone = space.thermalZone.get
          next unless all_conditioned_zones.include? zone
          next if conditioned_zones.include? zone

          conditioned_zones << zone
        end

        units_represented = 1
        if unit.additionalProperties.getFeatureAsInteger("Units Represented").is_initialized
          units_represented = unit.additionalProperties.getFeatureAsInteger("Units Represented").get
        end

        component = nil

        # Unitary system?
        if component.nil?
          model.getAirLoopHVACUnitarySystems.each do |sys|
            next unless conditioned_zones.include? sys.controllingZoneorThermostatLocation.get
            next if not sys.supplementalHeatingCoil.is_initialized

            if not component.nil?
              runner.registerError("Multiple supplemental heating systems found. This code should be reevaluated for correctness.")
              return nil
            end
            component = sys.supplementalHeatingCoil.get
          end
          if not component.nil?
            if component.to_CoilHeatingElectric.is_initialized
              coil = component.to_CoilHeatingElectric.get
              if coil.nominalCapacity.is_initialized
                cost_mult += OpenStudio::convert(coil.nominalCapacity.get, "W", "kBtu/h").get
              end
            end
          end
        end

        cost_mult *= units_represented
      end

    elsif cost_mult_type == "Size, Cooling System (kBtu/h)"
      # Cooling system capacity

      all_conditioned_zones = conditioned_zones

      model.getBuildingUnits.each do |unit|
        next if unit.spaces.empty?

        conditioned_zones = []
        unit.spaces.each do |space|
          zone = space.thermalZone.get
          next unless all_conditioned_zones.include? zone
          next if conditioned_zones.include? zone

          conditioned_zones << zone
        end

        units_represented = 1
        if unit.additionalProperties.getFeatureAsInteger("Units Represented").is_initialized
          units_represented = unit.additionalProperties.getFeatureAsInteger("Units Represented").get
        end

        component = nil

        # Unitary system?
        if component.nil?
          model.getAirLoopHVACUnitarySystems.each do |sys|
            next unless conditioned_zones.include? sys.controllingZoneorThermostatLocation.get
            next if not sys.coolingCoil.is_initialized

            if not component.nil?
              runner.registerError("Multiple cooling systems found. This code should be reevaluated for correctness.")
              return nil
            end
            component = sys.coolingCoil.get
          end
          if not component.nil?
            if component.to_CoilCoolingDXSingleSpeed.is_initialized
              coil = component.to_CoilCoolingDXSingleSpeed.get
              if coil.ratedTotalCoolingCapacity.is_initialized
                cost_mult += OpenStudio::convert(coil.ratedTotalCoolingCapacity.get, "W", "kBtu/h").get
              end
            elsif component.to_CoilCoolingDXMultiSpeed.is_initialized
              coil = component.to_CoilCoolingDXMultiSpeed.get
              if coil.stages.size > 0
                stage = coil.stages[coil.stages.size - 1]
                capacity_ratio = get_highest_stage_capacity_ratio(model, "SizingInfoHVACCapacityRatioCooling")
                if stage.grossRatedTotalCoolingCapacity.is_initialized
                  cost_mult += OpenStudio::convert(stage.grossRatedTotalCoolingCapacity.get / capacity_ratio, "W", "kBtu/h").get
                end
              end
            elsif component.to_CoilCoolingWaterToAirHeatPumpEquationFit.is_initialized
              coil = component.to_CoilCoolingWaterToAirHeatPumpEquationFit.get
              if coil.ratedTotalCoolingCapacity.is_initialized
                cost_mult += OpenStudio::convert(coil.ratedTotalCoolingCapacity.get, "W", "kBtu/h").get
              end
            end
          end
        end

        # PTAC?
        if component.nil?
          model.getZoneHVACPackagedTerminalAirConditioners.each do |sys|
            next unless conditioned_zones.include? sys.thermalZone.get

            component = sys.coolingCoil
            if not component.nil?
              if component.to_CoilCoolingDXSingleSpeed.is_initialized
                coil = component.to_CoilCoolingDXSingleSpeed.get
                if coil.ratedTotalCoolingCapacity.is_initialized
                  cost_mult += OpenStudio::convert(coil.ratedTotalCoolingCapacity.get, "W", "kBtu/h").get
                end
              end
            end
          end
        end

        cost_mult *= units_represented
      end

    elsif cost_mult_type == "Size, Water Heater (gal)"
      # Water heater tank volume
      (model.getWaterHeaterMixeds + model.getWaterHeaterHeatPumpWrappedCondensers).each do |wh|
        if wh.to_WaterHeaterHeatPumpWrappedCondenser.is_initialized
          wh = wh.tank.to_WaterHeaterStratified.get
        end
        if wh.tankVolume.is_initialized
          volume = OpenStudio::convert(wh.tankVolume.get, "m^3", "gal").get
          if volume >= 1.0 # skip tankless
            # FIXME: Remove actual->nominal size logic by storing nominal size in the OSM
            if wh.heaterFuelType.downcase == "electricity"
              cost_mult += volume / 0.9
            else
              cost_mult += volume / 0.95
            end
          end
        end
      end

    elsif cost_mult_type != ""
      runner.registerError("Unhandled cost multiplier: #{cost_mult_type.to_s}. Aborting...")
      return nil
    end

    return cost_mult
  end

  def get_conditioned_zones(model)
    conditioned_zones = []
    model.getThermalZones.each do |zone|
      next if not zone.thermostat.is_initialized

      conditioned_zones << zone
    end
    return conditioned_zones
  end

  def get_adjacent_space(surface)
    return nil if not surface.adjacentSurface.is_initialized
    return nil if not surface.adjacentSurface.get.space.is_initialized

    return surface.adjacentSurface.get.space.get
  end

  def is_space_conditioned(adjacent_space, conditioned_zones)
    conditioned_zones.each do |zone|
      return true if zone.spaces.include? adjacent_space
    end
    return false
  end

  def has_sloped_roof_surfaces(space)
    space.surfaces.each do |surface|
      next if surface.surfaceType.downcase != "roofceiling"
      next if surface.outsideBoundaryCondition.downcase != "outdoors"
      next if surface.tilt == 0

      return true
    end
    return false
  end

  def get_highest_stage_capacity_ratio(model, property_str)
    capacity_ratio = 1.0

    # Override capacity ratio for residential multispeed systems
    model.getAirLoopHVACUnitarySystems.each do |sys|
      capacity_ratio_str = sys.additionalProperties.getFeatureAsString(property_str)
      next if not capacity_ratio_str.is_initialized

      capacity_ratio = capacity_ratio_str.get.split(",").map(&:to_f)[-1]
    end

    return capacity_ratio
  end
end # end the measure

# this allows the measure to be use by the application
SimulationOutputReport.new.registerWithApplication
