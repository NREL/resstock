require 'openstudio'
if File.exists? File.absolute_path(File.join(File.dirname(__FILE__), "../../lib/resources/measures/HPXMLtoOpenStudio/resources")) # Hack to run ResStock on AWS
  resources_path = File.absolute_path(File.join(File.dirname(__FILE__), "../../lib/resources/measures/HPXMLtoOpenStudio/resources"))
elsif File.exists? File.absolute_path(File.join(File.dirname(__FILE__), "../../resources/measures/HPXMLtoOpenStudio/resources")) # Hack to run ResStock unit tests locally
  resources_path = File.absolute_path(File.join(File.dirname(__FILE__), "../../resources/measures/HPXMLtoOpenStudio/resources"))
elsif File.exists? File.join(OpenStudio::BCLMeasure::userMeasuresDir.to_s, "HPXMLtoOpenStudio/resources") # Hack to run measures in the OS App since applied measures are copied off into a temporary directory
  resources_path = File.join(OpenStudio::BCLMeasure::userMeasuresDir.to_s, "HPXMLtoOpenStudio/resources")
else
  resources_path = File.absolute_path(File.join(File.dirname(__FILE__), "../HPXMLtoOpenStudio/resources"))
end
require File.join(resources_path, "unit_conversions")

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

    # Electricity Fans Heating / Cooling
    electricity_fans_heating = []
    electricity_fans_cooling = []
    units.each do |unit|
      # Get all zones in unit
      thermal_zones = []
      unit.spaces.each do |space|
        thermal_zone = space.thermalZone.get
        unless thermal_zones.include? thermal_zone
          thermal_zones << thermal_zone
        end
      end
      
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
      
      thermal_zones.each do |thermal_zone|
        cooling_equipment = HVAC.existing_cooling_equipment(model, runner, thermal_zone)
        cooling_equipment.each do |clg_equip|
          clg_coil, htg_coil, supp_htg_coil = HVAC.get_coils_from_hvac_equip(clg_equip)

          if clg_equip.is_a? OpenStudio::Model::AirLoopHVACUnitarySystem
            electricity_fans_cooling << ["#{clg_equip.supplyFan.get.name}", "Fan Electric Energy"]

          elsif clg_equip.is_a? OpenStudio::Model::ZoneHVACPackagedTerminalAirConditioner
            electricity_fans_cooling << ["#{clg_equip.supplyAirFan.name}", "Fan Electric Energy"]

          end
        end
      end
    end

    results = create_custom_meter(results, "ElectricityFansHeating", electricity_fans_heating)
    results = create_custom_meter(results, "ElectricityFansCooling", electricity_fans_cooling)

    # Electricity Pumps Heating / Cooling
    electricity_pumps_heating = []
    electricity_pumps_cooling = []
    model.getEnergyManagementSystemOutputVariables.each do |ems_output_var|
      if ems_output_var.name.to_s.include? "htg pump:Pumps:Electricity"
        electricity_pumps_heating << ["", "#{ems_output_var.name}"]

      elsif ems_output_var.name.to_s.include? "clg pump:Pumps:Electricity"
        electricity_pumps_cooling << ["", "#{ems_output_var.name}"]

      end
    end
    model.getPumpConstantSpeeds.each do |pump| # shw pump
      next unless pump.name.to_s.include? Constants.ObjectNameSolarHotWater

      electricity_pumps_heating << ["#{pump.name}", "Pump Electric Energy"]
    end

    results = create_custom_meter(results, "ElectricityPumpsHeating", electricity_pumps_heating)
    results = create_custom_meter(results, "ElectricityPumpsCooling", electricity_pumps_cooling)

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

    # Get the weather file run period (as opposed to design day run period)
    ann_env_pd = nil
    sqlFile.availableEnvPeriods.each do |env_pd|
      env_type = sqlFile.environmentType(env_pd)
      if env_type.is_initialized
        if env_type.get == OpenStudio::EnvironmentType.new("WeatherRunPeriod")
          ann_env_pd = env_pd
        end
      end
    end
    if ann_env_pd == false
      runner.registerError("Can't find a weather runperiod, make sure you ran an annual simulation, not just the design days.")
      return false
    end
    
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
    electricityFansHeating = 0.0
    electricity_fans_heating_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('ELECTRICITYFANSHEATING') AND ReportingFrequency='Annual' AND VariableUnits='J')"
    unless sqlFile.execAndReturnFirstDouble(electricity_fans_heating_query).empty?
      electricityFansHeating = sqlFile.execAndReturnFirstDouble(electricity_fans_heating_query).get.round(2)
    end
    electricityFansCooling = 0.0
    electricity_fans_cooling_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('ELECTRICITYFANSCOOLING') AND ReportingFrequency='Annual' AND VariableUnits='J')"
    unless sqlFile.execAndReturnFirstDouble(electricity_fans_cooling_query).empty?
      electricityFansCooling = sqlFile.execAndReturnFirstDouble(electricity_fans_cooling_query).get.round(2)
    end
    electricityFans = 0.0
    unless sqlFile.electricityFans.empty?
      electricityFans = sqlFile.electricityFans.get
    end
    err = (electricityFansHeating + electricityFansCooling) - electricityFans
    if err.abs > 0.2
      runner.registerError("Disaggregated fan energy (#{electricityFansHeating + electricityFansCooling} GJ) relative to building fan energy (#{electricityFans} GJ): #{err} GJ.")
      return false
    end
    report_sim_output(runner, "electricity_fans_heating_kwh", [OpenStudio::OptionalDouble.new(electricityFansHeating)], "GJ", elec_site_units)
    report_sim_output(runner, "electricity_fans_cooling_kwh", [OpenStudio::OptionalDouble.new(electricityFansCooling)], "GJ", elec_site_units)
    electricityPumpsHeating = 0.0
    electricity_pumps_heating_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('ELECTRICITYPUMPSHEATING') AND ReportingFrequency='Annual' AND VariableUnits='J')"
    unless sqlFile.execAndReturnFirstDouble(electricity_pumps_heating_query).empty?
      electricityPumpsHeating = sqlFile.execAndReturnFirstDouble(electricity_pumps_heating_query).get.round(2)
    end    
    electricityPumpsCooling = 0.0
    electricity_pumps_cooling_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('ELECTRICITYPUMPSCOOLING') AND ReportingFrequency='Annual' AND VariableUnits='J')"
    unless sqlFile.execAndReturnFirstDouble(electricity_pumps_cooling_query).empty?
      electricityPumpsCooling = sqlFile.execAndReturnFirstDouble(electricity_pumps_cooling_query).get.round(2)
    end
    electricityPumps = 0.0
    unless sqlFile.electricityPumps.empty?
      electricityPumps = sqlFile.electricityPumps.get
    end
    err = (electricityPumpsHeating + electricityPumpsCooling) - electricityPumps
    if err.abs > 0.2
      runner.registerError("Disaggregated pump energy (#{electricityPumpsHeating + electricityPumpsCooling} GJ) relative to building pump energy (#{electricityPumps} GJ): #{err} GJ.")
      return false
    end
    report_sim_output(runner, "electricity_pumps_heating_kwh", [OpenStudio::OptionalDouble.new(electricityPumpsHeating)], "GJ", elec_site_units)
    report_sim_output(runner, "electricity_pumps_cooling_kwh", [OpenStudio::OptionalDouble.new(electricityPumpsCooling)], "GJ", elec_site_units)
    report_sim_output(runner, "electricity_water_systems_kwh", [sqlFile.electricityWaterSystems], "GJ", elec_site_units)
    report_sim_output(runner, "electricity_pv_kwh", [pv_val], "GJ", elec_site_units)
    
    # NATURAL GAS
    
    report_sim_output(runner, "total_site_natural_gas_therm", [sqlFile.naturalGasTotalEndUses], "GJ", gas_site_units)
    report_sim_output(runner, "natural_gas_heating_therm", [sqlFile.naturalGasHeating], "GJ", gas_site_units)
    report_sim_output(runner, "natural_gas_interior_equipment_therm", [sqlFile.naturalGasInteriorEquipment], "GJ", gas_site_units)
    report_sim_output(runner, "natural_gas_water_systems_therm", [sqlFile.naturalGasWaterSystems], "GJ", gas_site_units)

    # FUEL OIL

    total_site_fuel_oil_query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnergyMeters' AND ReportForString='Entire Facility' AND TableName='Annual and Peak Values - Other' AND RowName='FuelOil#1:Facility' AND ColumnName='Annual Value' AND Units='GJ'"
    total_site_fuel_oil = sqlFile.execAndReturnFirstDouble(total_site_fuel_oil_query)
    fuel_oil_heating_query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnergyMeters' AND ReportForString='Entire Facility' AND TableName='Annual and Peak Values - Other' AND RowName='Heating:FuelOil#1' AND ColumnName='Annual Value' AND Units='GJ'"
    fuel_oil_heating = sqlFile.execAndReturnFirstDouble(fuel_oil_heating_query)
    fuel_oil_interior_equipment_query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnergyMeters' AND ReportForString='Entire Facility' AND TableName='Annual and Peak Values - Other' AND RowName='InteriorEquipment:FuelOil#1' AND ColumnName='Annual Value' AND Units='GJ'"
    fuel_oil_interior_equipment = sqlFile.execAndReturnFirstDouble(fuel_oil_interior_equipment_query)
    fuel_oil_water_systems_query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnergyMeters' AND ReportForString='Entire Facility' AND TableName='Annual and Peak Values - Other' AND RowName='WaterSystems:FuelOil#1' AND ColumnName='Annual Value' AND Units='GJ'"
    fuel_oil_water_systems = sqlFile.execAndReturnFirstDouble(fuel_oil_water_systems_query)
    report_sim_output(runner, "total_site_fuel_oil_mbtu", [total_site_fuel_oil], "GJ", other_fuel_site_units)
    report_sim_output(runner, "fuel_oil_heating_mbtu", [fuel_oil_heating], "GJ", other_fuel_site_units)
    report_sim_output(runner, "fuel_oil_interior_equipment_mbtu", [fuel_oil_interior_equipment], "GJ", other_fuel_site_units)
    report_sim_output(runner, "fuel_oil_water_systems_mbtu", [fuel_oil_water_systems], "GJ", other_fuel_site_units)

    # PROPANE

    total_site_propane_query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnergyMeters' AND ReportForString='Entire Facility' AND TableName='Annual and Peak Values - Other' AND RowName='Propane:Facility' AND ColumnName='Annual Value' AND Units='GJ'"
    total_site_propane = sqlFile.execAndReturnFirstDouble(total_site_propane_query)
    propane_heating_query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnergyMeters' AND ReportForString='Entire Facility' AND TableName='Annual and Peak Values - Other' AND RowName='Heating:Propane' AND ColumnName='Annual Value' AND Units='GJ'"
    propane_heating = sqlFile.execAndReturnFirstDouble(propane_heating_query)
    propane_interior_equipment_query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnergyMeters' AND ReportForString='Entire Facility' AND TableName='Annual and Peak Values - Other' AND RowName='InteriorEquipment:Propane' AND ColumnName='Annual Value' AND Units='GJ'"
    propane_interior_equipment = sqlFile.execAndReturnFirstDouble(propane_interior_equipment_query)
    propane_water_systems_query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnergyMeters' AND ReportForString='Entire Facility' AND TableName='Annual and Peak Values - Other' AND RowName='WaterSystems:Propane' AND ColumnName='Annual Value' AND Units='GJ'"
    propane_water_systems = sqlFile.execAndReturnFirstDouble(propane_water_systems_query)
    report_sim_output(runner, "total_site_propane_mbtu", [total_site_propane], "GJ", other_fuel_site_units)
    report_sim_output(runner, "propane_heating_mbtu", [propane_heating], "GJ", other_fuel_site_units)
    report_sim_output(runner, "propane_interior_equipment_mbtu", [propane_interior_equipment], "GJ", other_fuel_site_units)
    report_sim_output(runner, "propane_water_systems_mbtu", [propane_water_systems], "GJ", other_fuel_site_units)
    
    # LOADS NOT MET
    
    report_sim_output(runner, "hours_heating_setpoint_not_met", [sqlFile.hoursHeatingSetpointNotMet], nil, nil)
    report_sim_output(runner, "hours_cooling_setpoint_not_met", [sqlFile.hoursCoolingSetpointNotMet], nil, nil)
    
    # HVAC CAPACITIES
    
    conditioned_zones = get_conditioned_zones(model)
    hvac_cooling_capacity_kbtuh = get_cost_multiplier("Size, Cooling System (kBtu/h)", model, runner, conditioned_zones)
    return false if hvac_cooling_capacity_kbtuh.nil?
    report_sim_output(runner, "hvac_cooling_capacity_w", [OpenStudio::OptionalDouble.new(hvac_cooling_capacity_kbtuh)], "kBtu/hr", "W")
    hvac_heating_capacity_kbtuh = get_cost_multiplier("Size, Heating System (kBtu/h)", model, runner, conditioned_zones)
    return false if hvac_heating_capacity_kbtuh.nil?
    report_sim_output(runner, "hvac_heating_capacity_w", [OpenStudio::OptionalDouble.new(hvac_heating_capacity_kbtuh)], "kBtu/hr", "W")
    hvac_heating_supp_capacity_kbtuh = get_cost_multiplier("Size, Heating Supplemental System (kBtu/h)", model, runner, conditioned_zones)
    return false if hvac_heating_supp_capacity_kbtuh.nil?
    report_sim_output(runner, "hvac_heating_supp_capacity_w", [OpenStudio::OptionalDouble.new(hvac_heating_supp_capacity_kbtuh)], "kBtu/hr", "W")
    
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
        valInUnits = UnitConversions.convert(total_val, os_units, desired_units)
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
                cost_mult += UnitConversions.convert(surface.grossArea,"m^2","ft^2")
            elsif !adjacent_space.nil? and not is_space_conditioned(adjacent_space, conditioned_zones)
                cost_mult += UnitConversions.convert(surface.grossArea,"m^2","ft^2")
            end
        end
        
    elsif cost_mult_type == "Wall Area, Above-Grade, Exterior (ft^2)"
        # Walls adjacent to outdoors
        model.getSurfaces.each do |surface|
            next if surface.surfaceType.downcase != "wall"
            next if surface.outsideBoundaryCondition.downcase != "outdoors"
            cost_mult += UnitConversions.convert(surface.grossArea,"m^2","ft^2")
        end
        
    elsif cost_mult_type == "Wall Area, Below-Grade (ft^2)"
        # Walls adjacent to ground
        model.getSurfaces.each do |surface|
            next if surface.surfaceType.downcase != "wall"
            next if surface.outsideBoundaryCondition.downcase != "ground" and surface.outsideBoundaryCondition.downcase != "foundation"
            cost_mult += UnitConversions.convert(surface.grossArea,"m^2","ft^2")
        end
        
    elsif cost_mult_type == "Floor Area, Conditioned (ft^2)"
        # Floors of conditioned zone
        model.getSurfaces.each do |surface|
            next if surface.surfaceType.downcase != "floor"
            next if not surface.space.is_initialized
            next if not is_space_conditioned(surface.space.get, conditioned_zones)
            cost_mult += UnitConversions.convert(surface.grossArea,"m^2","ft^2")
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
            cost_mult += UnitConversions.convert(surface.grossArea,"m^2","ft^2")
        end
        
    elsif cost_mult_type == "Floor Area, Lighting (ft^2)"
        # Floors with lighting objects
        model.getSurfaces.each do |surface|
            next if surface.surfaceType.downcase != "floor"
            next if not surface.space.is_initialized
            next if surface.space.get.lights.size == 0
            cost_mult += UnitConversions.convert(surface.grossArea,"m^2","ft^2")
        end
        
    elsif cost_mult_type == "Roof Area (ft^2)"
        # Roofs adjacent to outdoors
        model.getSurfaces.each do |surface|
            next if surface.surfaceType.downcase != "roofceiling"
            next if surface.outsideBoundaryCondition.downcase != "outdoors"
            cost_mult += UnitConversions.convert(surface.grossArea,"m^2","ft^2")
        end
        
    elsif cost_mult_type == "Window Area (ft^2)"
        # Window subsurfaces
        model.getSurfaces.each do |surface|
            next if surface.surfaceType.downcase != "wall"
            surface.subSurfaces.each do |sub_surface|
                next if not sub_surface.subSurfaceType.downcase.include? "window"
                cost_mult += UnitConversions.convert(sub_surface.grossArea,"m^2","ft^2")
            end
        end
        
    elsif cost_mult_type == "Door Area (ft^2)"
        # Door subsurfaces
        model.getSurfaces.each do |surface|
            next if surface.surfaceType.downcase != "wall"
            surface.subSurfaces.each do |sub_surface|
                next if not sub_surface.subSurfaceType.downcase.include? "door"
                cost_mult += UnitConversions.convert(sub_surface.grossArea,"m^2","ft^2")
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
                    cost_mult += UnitConversions.convert(coil.nominalCapacity.get, "W", "kBtu/hr")
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
                        cost_mult += UnitConversions.convert(coil.ratedTotalHeatingCapacity.get, "W", "kBtu/hr")
                    end
                elsif component.to_CoilHeatingDXMultiSpeed.is_initialized
                    coil = component.to_CoilHeatingDXMultiSpeed.get
                    if coil.stages.size > 0
                        stage = coil.stages[coil.stages.size-1]
                        capacity_ratio = get_highest_stage_capacity_ratio(model, "SizingInfoHVACCapacityRatioCooling")
                        if stage.grossRatedHeatingCapacity.is_initialized
                            cost_mult += UnitConversions.convert(stage.grossRatedHeatingCapacity.get/capacity_ratio, "W", "kBtu/hr")
                        end
                    end
                elsif component.to_CoilHeatingGas.is_initialized
                    coil = component.to_CoilHeatingGas.get
                    if coil.nominalCapacity.is_initialized
                        cost_mult += UnitConversions.convert(coil.nominalCapacity.get, "W", "kBtu/hr")
                    end
                elsif component.to_CoilHeatingElectric.is_initialized
                    coil = component.to_CoilHeatingElectric.get
                    if coil.nominalCapacity.is_initialized
                        cost_mult += UnitConversions.convert(coil.nominalCapacity.get, "W", "kBtu/hr")
                    end
                elsif component.to_CoilHeatingWaterToAirHeatPumpEquationFit.is_initialized
                    coil = component.to_CoilHeatingWaterToAirHeatPumpEquationFit.get
                    if coil.ratedHeatingCapacity.is_initialized
                        cost_mult += UnitConversions.convert(coil.ratedHeatingCapacity.get, "W", "kBtu/hr")
                    end
                end
            end
        end
        
        # Electric baseboard?
        if component.nil?
            model.getZoneHVACBaseboardConvectiveElectrics.each do |sys|
                component = sys
                next if not component.nominalCapacity.is_initialized
                cost_mult += UnitConversions.convert(component.nominalCapacity.get, "W", "kBtu/hr")
            end
        end
        
        # Boiler?
        if component.nil?
            model.getPlantLoops.each do |pl|
                pl.components.each do |plc|
                    next if not plc.to_BoilerHotWater.is_initialized
                    component = plc.to_BoilerHotWater.get
                    next if not component.nominalCapacity.is_initialized
                    cost_mult += UnitConversions.convert(component.nominalCapacity.get, "W", "kBtu/hr")
                end
            end
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
                        cost_mult += UnitConversions.convert(coil.nominalCapacity.get, "W", "kBtu/hr")
                    end
                end
            end
        end
    
    elsif cost_mult_type == "Size, Cooling System (kBtu/h)"
        # Cooling system capacity

        components = []

        # Unitary system or PTAC?
        model.getAirLoopHVACUnitarySystems.each do |sys|
            next if not sys.coolingCoil.is_initialized
            components << sys.coolingCoil.get
        end
        model.getZoneHVACPackagedTerminalAirConditioners.each do |sys|
            components << sys.coolingCoil
        end
        components.each do |component|
            if component.to_CoilCoolingDXSingleSpeed.is_initialized
                coil = component.to_CoilCoolingDXSingleSpeed.get
                if coil.ratedTotalCoolingCapacity.is_initialized
                    cost_mult += UnitConversions.convert(coil.ratedTotalCoolingCapacity.get, "W", "kBtu/hr")
                end
            elsif component.to_CoilCoolingDXMultiSpeed.is_initialized
                coil = component.to_CoilCoolingDXMultiSpeed.get
                if coil.stages.size > 0
                    stage = coil.stages[coil.stages.size-1]
                    capacity_ratio = get_highest_stage_capacity_ratio(model, "SizingInfoHVACCapacityRatioCooling")
                    if stage.grossRatedTotalCoolingCapacity.is_initialized
                        cost_mult += UnitConversions.convert(stage.grossRatedTotalCoolingCapacity.get/capacity_ratio, "W", "kBtu/hr")
                    end
                end
            elsif component.to_CoilCoolingWaterToAirHeatPumpEquationFit.is_initialized
                coil = component.to_CoilCoolingWaterToAirHeatPumpEquationFit.get
                if coil.ratedTotalCoolingCapacity.is_initialized
                    cost_mult += UnitConversions.convert(coil.ratedTotalCoolingCapacity.get, "W", "kBtu/hr")
                end
            end
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
            volume = UnitConversions.convert(wh_tank.tankVolume.get, "m^3", "gal")
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
  
end #end the measure

#this allows the measure to be use by the application
SimulationOutputReport.new.registerWithApplication