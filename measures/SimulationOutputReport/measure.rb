require 'openstudio'

#start the measure
class SimulationOutputReport < OpenStudio::Measure::ReportingMeasure

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Simulation Output Report"
  end
  
  def description
    return "Reports simulation outputs of interest."
  end

  #define the arguments that the user will input
  def arguments()
    args = OpenStudio::Ruleset::OSArgumentVector.new

    return args
  end #end the arguments method
  
  def outputs
    buildstock_outputs = [
                          "total_site_energy_mbtu",
                          "total_site_electricity_kwh",
                          "total_site_natural_gas_therm",
                          "total_site_other_fuel_mbtu",
                          "net_site_energy_mbtu", # Incorporates PV
                          "net_site_electricity_kwh", # Incorporates PV
                          "electricity_heating_kwh",
                          "electricity_cooling_kwh",
                          "electricity_interior_lighting_kwh",
                          "electricity_exterior_lighting_kwh",
                          "electricity_interior_equipment_kwh",
                          "electricity_fans_kwh",
                          "electricity_pumps_kwh",
                          "electricity_water_systems_kwh",
                          "electricity_pv_kwh",
                          "natural_gas_heating_therm",
                          "natural_gas_interior_equipment_therm",
                          "natural_gas_water_systems_therm",
                          "other_fuel_heating_mbtu",
                          "other_fuel_interior_equipment_mbtu",
                          "other_fuel_water_systems_mbtu",
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

  #define what happens when the measure is run
  def run(runner, user_arguments)
    super(runner, user_arguments)

    #use the built-in error checking
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
    
    # Get PV electricity produced
    pv_query = "SELECT -1*Value FROM TabularDataWithStrings WHERE ReportName='AnnualBuildingUtilityPerformanceSummary' AND ReportForString='Entire Facility' AND TableName='Electric Loads Satisfied' AND RowName='Total On-Site Electric Sources' AND ColumnName='Electricity' AND Units='GJ'"
    pv_val = sqlFile.execAndReturnFirstDouble(pv_query)
           
    # TOTAL
    
    report_sim_output(runner, "total_site_energy_mbtu", [sqlFile.totalSiteEnergy], "GJ", total_site_units)
    report_sim_output(runner, "net_site_energy_mbtu", [sqlFile.totalSiteEnergy, pv_val], "GJ", total_site_units)
    
    # ELECTRICITY
    
    report_sim_output(runner, "total_site_electricity_kwh", [sqlFile.electricityTotalEndUses], "GJ", elec_site_units)
    report_sim_output(runner, "net_site_electricity_kwh", [sqlFile.electricityTotalEndUses, pv_val], "GJ", elec_site_units)
    report_sim_output(runner, "electricity_heating_kwh", [sqlFile.electricityHeating], "GJ", elec_site_units)
    report_sim_output(runner, "electricity_cooling_kwh", [sqlFile.electricityCooling], "GJ", elec_site_units)
    report_sim_output(runner, "electricity_interior_lighting_kwh", [sqlFile.electricityInteriorLighting], "GJ", elec_site_units)
    report_sim_output(runner, "electricity_exterior_lighting_kwh", [sqlFile.electricityExteriorLighting], "GJ", elec_site_units)
    report_sim_output(runner, "electricity_interior_equipment_kwh", [sqlFile.electricityInteriorEquipment], "GJ", elec_site_units)
    report_sim_output(runner, "electricity_fans_kwh", [sqlFile.electricityFans], "GJ", elec_site_units)
    report_sim_output(runner, "electricity_pumps_kwh", [sqlFile.electricityPumps], "GJ", elec_site_units)
    report_sim_output(runner, "electricity_water_systems_kwh", [sqlFile.electricityWaterSystems], "GJ", elec_site_units)
    report_sim_output(runner, "electricity_pv_kwh", [pv_val], "GJ", elec_site_units)
    
    # NATURAL GAS
    
    report_sim_output(runner, "total_site_natural_gas_therm", [sqlFile.naturalGasTotalEndUses], "GJ", gas_site_units)
    report_sim_output(runner, "natural_gas_heating_therm", [sqlFile.naturalGasHeating], "GJ", gas_site_units)
    report_sim_output(runner, "natural_gas_interior_equipment_therm", [sqlFile.naturalGasInteriorEquipment], "GJ", gas_site_units)
    report_sim_output(runner, "natural_gas_water_systems_therm", [sqlFile.naturalGasWaterSystems], "GJ", gas_site_units)
    
    # OTHER FUEL
    
    report_sim_output(runner, "total_site_other_fuel_mbtu", [sqlFile.otherFuelTotalEndUses], "GJ", other_fuel_site_units)
    report_sim_output(runner, "other_fuel_heating_mbtu", [sqlFile.otherFuelHeating], "GJ", other_fuel_site_units)
    report_sim_output(runner, "other_fuel_interior_equipment_mbtu", [sqlFile.otherFuelInteriorEquipment], "GJ", other_fuel_site_units)
    report_sim_output(runner, "other_fuel_water_systems_mbtu", [sqlFile.otherFuelWaterSystems], "GJ", other_fuel_site_units)
    
    # LOADS NOT MET
    
    report_sim_output(runner, "hours_heating_setpoint_not_met", [sqlFile.hoursHeatingSetpointNotMet], nil, nil)
    report_sim_output(runner, "hours_cooling_setpoint_not_met", [sqlFile.hoursCoolingSetpointNotMet], nil, nil)
    
    # HVAC CAPACITIES
    
    conditioned_zones = get_conditioned_zones(model)
    hvac_cooling_capacity_kbtuh = get_cost_multiplier("Size, Cooling System (kBtu/h)", model, runner, conditioned_zones)
    return false if hvac_cooling_capacity_kbtuh.nil?
    report_sim_output(runner, "hvac_cooling_capacity_w", [OpenStudio::OptionalDouble.new(hvac_cooling_capacity_kbtuh)], "kBtu/h", "W")
    hvac_heating_capacity_kbtuh = get_cost_multiplier("Size, Heating System (kBtu/h)", model, runner, conditioned_zones)
    return false if hvac_heating_capacity_kbtuh.nil?
    report_sim_output(runner, "hvac_heating_capacity_w", [OpenStudio::OptionalDouble.new(hvac_heating_capacity_kbtuh)], "kBtu/h", "W")
    hvac_heating_supp_capacity_kbtuh = get_cost_multiplier("Size, Heating Supplemental System (kBtu/h)", model, runner, conditioned_zones)
    return false if hvac_heating_supp_capacity_kbtuh.nil?
    report_sim_output(runner, "hvac_heating_supp_capacity_w", [OpenStudio::OptionalDouble.new(hvac_heating_supp_capacity_kbtuh)], "kBtu/h", "W")
    
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

  end #end the run method

  def report_sim_output(runner, name, vals, os_units, desired_units, percent_of_val=1.0)
    total_val = 0.0
    vals.each do |val|
        next if val.empty?
        total_val += val.get * percent_of_val
    end
    if os_units.nil? or desired_units.nil? or os_units == desired_units
        valInUnits = total_val
    else
        valInUnits = OpenStudio::convert(total_val, os_units, desired_units).get
    end
    runner.registerValue(name,valInUnits)
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
                cost_mult += OpenStudio::convert(surface.grossArea,"m^2","ft^2").get
            elsif !adjacent_space.nil? and not is_space_conditioned(adjacent_space, conditioned_zones)
                cost_mult += OpenStudio::convert(surface.grossArea,"m^2","ft^2").get
            end
        end
        
    elsif cost_mult_type == "Wall Area, Above-Grade, Exterior (ft^2)"
        # Walls adjacent to outdoors
        model.getSurfaces.each do |surface|
            next if surface.surfaceType.downcase != "wall"
            next if surface.outsideBoundaryCondition.downcase != "outdoors"
            cost_mult += OpenStudio::convert(surface.grossArea,"m^2","ft^2").get
        end
        
    elsif cost_mult_type == "Wall Area, Below-Grade (ft^2)"
        # Walls adjacent to ground
        model.getSurfaces.each do |surface|
            next if surface.surfaceType.downcase != "wall"
            next if surface.outsideBoundaryCondition.downcase != "ground" and surface.outsideBoundaryCondition.downcase != "foundation"
            cost_mult += OpenStudio::convert(surface.grossArea,"m^2","ft^2").get
        end
        
    elsif cost_mult_type == "Floor Area, Conditioned (ft^2)"
        # Floors of conditioned zone
        model.getSurfaces.each do |surface|
            next if surface.surfaceType.downcase != "floor"
            next if not surface.space.is_initialized
            next if not is_space_conditioned(surface.space.get, conditioned_zones)
            cost_mult += OpenStudio::convert(surface.grossArea,"m^2","ft^2").get
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
            cost_mult += OpenStudio::convert(surface.grossArea,"m^2","ft^2").get
        end
        
    elsif cost_mult_type == "Floor Area, Lighting (ft^2)"
        # Floors with lighting objects
        model.getSurfaces.each do |surface|
            next if surface.surfaceType.downcase != "floor"
            next if not surface.space.is_initialized
            next if surface.space.get.lights.size == 0
            cost_mult += OpenStudio::convert(surface.grossArea,"m^2","ft^2").get
        end
        
    elsif cost_mult_type == "Roof Area (ft^2)"
        # Roofs adjacent to outdoors
        model.getSurfaces.each do |surface|
            next if surface.surfaceType.downcase != "roofceiling"
            next if surface.outsideBoundaryCondition.downcase != "outdoors"
            cost_mult += OpenStudio::convert(surface.grossArea,"m^2","ft^2").get
        end
        
    elsif cost_mult_type == "Window Area (ft^2)"
        # Window subsurfaces
        model.getSurfaces.each do |surface|
            next if surface.surfaceType.downcase != "wall"
            surface.subSurfaces.each do |sub_surface|
                next if not sub_surface.subSurfaceType.downcase.include? "window"
                cost_mult += OpenStudio::convert(sub_surface.grossArea,"m^2","ft^2").get
            end
        end
        
    elsif cost_mult_type == "Door Area (ft^2)"
        # Door subsurfaces
        model.getSurfaces.each do |surface|
            next if surface.surfaceType.downcase != "wall"
            surface.subSurfaces.each do |sub_surface|
                next if not sub_surface.subSurfaceType.downcase.include? "door"
                cost_mult += OpenStudio::convert(sub_surface.grossArea,"m^2","ft^2").get
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

        component = nil

        # Unit heater?
        if component.nil?
            model.getThermalZones.each do |zone|
                zone.equipment.each do |equipment|
                    next unless equipment.to_AirLoopHVACUnitarySystem.is_initialized
                    sys = equipment.to_AirLoopHVACUnitarySystem.get
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
                        stage = coil.stages[coil.stages.size-1]
                        capacity_ratio = get_highest_stage_capacity_ratio(model, "SizingInfoHVACCapacityRatioCooling")
                        if stage.grossRatedHeatingCapacity.is_initialized
                            cost_mult += OpenStudio::convert(stage.grossRatedHeatingCapacity.get/capacity_ratio, "W", "kBtu/h").get
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
        
        # VRF?
        if component.nil?
            sum_value = 0.0
            model.getZoneHVACTerminalUnitVariableRefrigerantFlows.each do |sys|
                component = sys.heatingCoil
                if component.is_a? OpenStudio::Model::OptionalCoilHeatingDXVariableRefrigerantFlow
                    component = component.get
                end
                next if not component.ratedTotalHeatingCapacity.is_initialized
                sum_value += component.ratedTotalHeatingCapacity.get
            end
            capacity_ratio = get_highest_stage_capacity_ratio(model, "SizingInfoHVACCapacityRatioHeating")
            cost_mult += OpenStudio::convert(sum_value/capacity_ratio, "W", "kBtu/h").get
        end
        
        # Electric baseboard?
        if component.nil?
            max_value = 0.0
            model.getZoneHVACBaseboardConvectiveElectrics.each do |sys|
                component = sys
                next if not component.nominalCapacity.is_initialized
                next if component.nominalCapacity.get <= max_value
                max_value = component.nominalCapacity.get
            end
            cost_mult += OpenStudio::convert(max_value, "W", "kBtu/h").get
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
        
    elsif cost_mult_type == "Size, Heating Supplemental System (kBtu/h)"
        # Supplemental heating system capacity

        component = nil

        # Unitary system?
        if component.nil?
            model.getAirLoopHVACUnitarySystems.each do |sys|
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
        
        # VRF?
        if component.nil?
            sum_value = 0.0
            model.getZoneHVACTerminalUnitVariableRefrigerantFlows.each do |sys|
                component = sys.heatingCoil
            end
            if not component.nil?
              max_value = 0.0
              model.getZoneHVACBaseboardConvectiveElectrics.each do |sys|
                next if not sys.nominalCapacity.is_initialized
                next if sys.nominalCapacity.get <= max_value
                max_value = sys.nominalCapacity.get
              end
              cost_mult += OpenStudio::convert(max_value, "W", "kBtu/h").get
            end
        end
    
    elsif cost_mult_type == "Size, Cooling System (kBtu/h)"
        # Cooling system capacity

        component = nil

        # Unitary system or PTAC?
        model.getAirLoopHVACUnitarySystems.each do |sys|
            next if not sys.coolingCoil.is_initialized
            if not component.nil?
                runner.registerError("Multiple cooling systems found. This code should be reevaluated for correctness.")
                return nil
            end
            component = sys.coolingCoil.get
        end
        model.getZoneHVACPackagedTerminalAirConditioners.each do |sys|
            if not component.nil?
                runner.registerError("Multiple cooling systems found. This code should be reevaluated for correctness.")
                return nil
            end
            component = sys.coolingCoil
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
                    stage = coil.stages[coil.stages.size-1]
                    capacity_ratio = get_highest_stage_capacity_ratio(model, "SizingInfoHVACCapacityRatioCooling")
                    if stage.grossRatedTotalCoolingCapacity.is_initialized
                        cost_mult += OpenStudio::convert(stage.grossRatedTotalCoolingCapacity.get/capacity_ratio, "W", "kBtu/h").get
                    end
                end
            elsif component.to_CoilCoolingWaterToAirHeatPumpEquationFit.is_initialized
                coil = component.to_CoilCoolingWaterToAirHeatPumpEquationFit.get
                if coil.ratedTotalCoolingCapacity.is_initialized
                    cost_mult += OpenStudio::convert(coil.ratedTotalCoolingCapacity.get, "W", "kBtu/h").get
                end
            end
        end
        
        # VRF?
        if component.nil?
            sum_value = 0.0
            model.getZoneHVACTerminalUnitVariableRefrigerantFlows.each do |sys|
                component = sys.coolingCoil
                if component.is_a? OpenStudio::Model::OptionalCoilCoolingDXVariableRefrigerantFlow
                    component = component.get
                end
                next if not component.ratedTotalCoolingCapacity.is_initialized
                sum_value += component.ratedTotalCoolingCapacity.get
            end
            capacity_ratio = get_highest_stage_capacity_ratio(model, "SizingInfoHVACCapacityRatioCooling")
            cost_mult += OpenStudio::convert(sum_value/capacity_ratio, "W", "kBtu/h").get
        end
        
    elsif cost_mult_type == "Size, Water Heater (gal)"
        # Water heater tank volume
        wh_tank = nil
        model.getWaterHeaterMixeds.each do |wh|
            if not wh_tank.nil?
                runner.registerError("Multiple water heaters found. This code should be reevaluated for correctness.")
                return nil
            end
            wh_tank = wh
        end
        model.getWaterHeaterHeatPumpWrappedCondensers.each do |wh|
            if not wh_tank.nil?
                runner.registerError("Multiple water heaters found. This code should be reevaluated for correctness.")
                return nil
            end
            wh_tank = wh.tank.to_WaterHeaterStratified.get
        end
        if wh_tank.tankVolume.is_initialized
            volume = OpenStudio::convert(wh_tank.tankVolume.get, "m^3", "gal").get
            if volume >= 1.0 # skip tankless
                # FIXME: Remove actual->nominal size logic by storing nominal size in the OSM
                if wh_tank.heaterFuelType.downcase == "electricity"
                    cost_mult += volume / 0.9
                else
                    cost_mult += volume / 0.95
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
  
  def get_highest_stage_capacity_ratio(model, capacity_ratio_str)
    capacity_ratio = 1.0
    
    # Override capacity ratio for residential multispeed systems
    model.getBuildingUnits.each do |unit|
        next if unit.spaces.size == 0
        capacity_ratio_str = unit.getFeatureAsString(capacity_ratio_str)
        next if not capacity_ratio_str.is_initialized
        capacity_ratio = capacity_ratio_str.get.split(",").map(&:to_f)[-1]
    end
    
    return capacity_ratio
  end
  
end #end the measure

#this allows the measure to be use by the application
SimulationOutputReport.new.registerWithApplication