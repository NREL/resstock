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

require File.join(resources_path, "geometry")

require "#{File.dirname(__FILE__)}/resources/os_lib_heat_transfer"
require "#{File.dirname(__FILE__)}/resources/os_lib_reporting_envelope_and_internal_loads_breakdown"

# start the measure
class ScoutInputReport < OpenStudio::Measure::ReportingMeasure
  # define the name that a user will see, this method may be deprecated as
  # the display name in PAT comes from the name field in measure.xml
  def name
    # Measure name should be the title case of the class name.
    return "Scout Input Report"
  end

  def description
    return "Create Scout inputs from ResStock outputs."
  end

  # define the arguments that the user will input
  def arguments
    args = OpenStudio::Measure::OSArgumentVector.new

    return args
  end # end the arguments method

  # return a vector of IdfObject's to request EnergyPlus objects needed by the run method
  def energyPlusOutputRequests(runner, user_arguments)
    
    super(runner, user_arguments)

    return OpenStudio::IdfObjectVector.new if runner.halted

    # get the last model and sql file
    model = runner.lastOpenStudioModel
    if model.empty?
      runner.registerError("Cannot find last model.")
      return false
    end
    model = model.get

    # Initialize custom meter hash containing meter names and key/var groups
    custom_meter_infos = {}

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
      
      OutputMeters.electricity_refrigerator(custom_meter_infos, model, runner, unit, thermal_zones)
      OutputMeters.electricity_clothes_washer(custom_meter_infos, model, runner, unit, thermal_zones)
      OutputMeters.electricity_clothes_dryer(custom_meter_infos, model, runner, unit, thermal_zones)
      OutputMeters.natural_gas_clothes_dryer(custom_meter_infos, model, runner, unit, thermal_zones)
      OutputMeters.propane_clothes_dryer(custom_meter_infos, model, runner, unit, thermal_zones)
      OutputMeters.electricity_dishwasher(custom_meter_infos, model, runner, unit, thermal_zones)
      OutputMeters.electricity_extra_refrigerator(custom_meter_infos, model, runner, unit, thermal_zones)
    end

    results = OpenStudio::IdfObjectVector.new
    custom_meter_infos.each do |meter_name, custom_meter_info|
      next if custom_meter_info["key_var_groups"].empty?

      custom_meter = OutputMeters.create_custom_meter(meter_name: meter_name,
                                                      fuel_type: custom_meter_info["fuel_type"],
                                                      key_var_groups: custom_meter_info["key_var_groups"])
      results << OpenStudio::IdfObject.load(custom_meter).get
      results << OpenStudio::IdfObject.load("Output:Meter,#{meter_name},RunPeriod;").get
    end

    # heat transfer outputs
    OsLib_HeatTransfer.heat_transfer_outputs.each do |output|
      results << OpenStudio::IdfObject.load("Output:Variable,,#{output},Timestep;").get
    end

    # supply outputs
    results << OpenStudio::IdfObject.load("Output:Variable,,Zone Air System Sensible Heating Energy,RunPeriod;").get
    results << OpenStudio::IdfObject.load("Output:Variable,,Zone Air System Sensible Cooling Energy,RunPeriod;").get

    return results
  end

  def demand_outputs
    demands = []
    gains = ["conv", "infiltration", "people", "equipment", "solar_windows", "cond_windows", "cond_doors", "ventilation", "lighting"]
    supplies = ["heating", "cooling"]
    surfaces = ["walls", "fwalls", "roof", "floor", "ground", "ceiling", "other"]
    gains.each do |gain|
      supplies.each do |supply|
        if gain == "conv"
          surfaces.each do |surface|
            demands << "#{gain}_#{surface}_#{supply}"
          end
        else
          demands << "#{gain}_#{supply}"
        end
      end
    end
    return demands
  end

  def supply_outputs
    return ["heating_supply",
            "cooling_supply"]
  end

  def load_outputs
    loads = []
    load_categories = ["lighting",
                       "electricity_water_systems",
                       "natural_gas_water_systems",
                       "fuel_oil_water_systems",
                       "propane_water_systems",
                       "electricity_refrigerator",
                       "electricity_clothes_washer",
                       "electricity_clothes_dryer",
                       "natural_gas_clothes_dryer",
                       "propane_clothes_dryer",
                       "electricity_dishwasher",
                       "electricity_extra_refrigerator"]
    load_categories.each do |load|
      loads << "#{load}_energy"
    end
    return loads
  end

  def outputs
    output_names = []
    output_names += demand_outputs
    output_names += supply_outputs
    output_names += load_outputs
    output_names += ["internal_gains_gain_error"]
    output_names += ["internal_gains_loss_error"]
    output_names += ["outdoor_air_gains_gain_error"]
    output_names += ["outdoor_air_gains_loss_error"]
    output_names += ["surface_convection_gain_error"]
    output_names += ["surface_convection_loss_error"]
    output_names += ["total_energy_balance_gain_error"]
    output_names += ["total_energy_balance_loss_error"]
    output_names += ["heating_demand_error"]
    output_names += ["cooling_demand_error"]

    result = OpenStudio::Measure::OSOutputVector.new
    output_names.each do |output|
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

    # Get sql and model
    setup = OsLib_ReportingHeatGainLoss.setup(runner)
    return false unless setup

    model = setup[:model]
    sqlFile = setup[:sqlFile]

    @ann_env_pd = nil
    sqlFile.availableEnvPeriods.each do |env_pd|
      env_type = sqlFile.environmentType(env_pd)
      if env_type.is_initialized
        if env_type.get == OpenStudio::EnvironmentType.new("WeatherRunPeriod")
          @ann_env_pd = env_pd
        end
      end
    end
    if @ann_env_pd == false
      runner.registerError("Can't find a weather runperiod, make sure you ran an annual simulation, not just the design days.")
      return false
    end

    env_period_ix_query = "SELECT EnvironmentPeriodIndex FROM EnvironmentPeriods WHERE EnvironmentName='#{@ann_env_pd}'"
    env_period_ix = sqlFile.execAndReturnFirstInt(env_period_ix_query).get

    # Load buildstock_file
    resources_dir = File.absolute_path(File.join(File.dirname(__FILE__), "..", "..", "lib", "resources")) # Should have been uploaded per 'Other Library Files' in analysis spreadsheet
    buildstock_file = File.join(resources_dir, "buildstock.rb")
    require File.join(File.dirname(buildstock_file), File.basename(buildstock_file, File.extname(buildstock_file)))

    total_site_units = "MBtu"
    elec_site_units = "kWh"
    gas_site_units = "therm"
    other_fuel_site_units = "MBtu"

    # Get building units
    units = Geometry.get_building_units(model, runner)
    if units.nil?
      return false
    end

    # LOAD ENERGY

    # Lighting
    lighting_vars = ["electricity_interior_lighting_kwh",
                     "electricity_exterior_lighting_kwh"]
    lighting_energy = 0.0
    lighting_vars.each do |var_name|
      lighting_energy += get_value_from_runner_past_results(runner, var_name, "simulation_output_report", error_if_missing = true)
    end
    report_sim_output(runner, "lighting_energy", lighting_energy, elec_site_units, total_site_units)

    # Water Systems
    electricity_water_systems = get_value_from_runner_past_results(runner, "electricity_water_systems_kwh", "simulation_output_report", error_if_missing = true)
    report_sim_output(runner, "electricity_water_systems_energy", electricity_water_systems, elec_site_units, total_site_units)

    natural_gas_water_systems = get_value_from_runner_past_results(runner, "natural_gas_water_systems_therm", "simulation_output_report", error_if_missing = true)
    report_sim_output(runner, "natural_gas_water_systems_energy", natural_gas_water_systems, gas_site_units, total_site_units)

    fuel_oil_water_systems = get_value_from_runner_past_results(runner, "fuel_oil_water_systems_mbtu", "simulation_output_report", error_if_missing = true)
    report_sim_output(runner, "fuel_oil_water_systems_energy", fuel_oil_water_systems, other_fuel_site_units, total_site_units)

    propane_water_systems = get_value_from_runner_past_results(runner, "propane_water_systems_mbtu", "simulation_output_report", error_if_missing = true)
    report_sim_output(runner, "propane_water_systems_energy", propane_water_systems, other_fuel_site_units, total_site_units)

    # Appliances
    electricityRefrigerator = 0.0
    electricityClothesWasher = 0.0
    electricityClothesDryer = 0.0
    naturalGasClothesDryer = 0.0
    propaneClothesDryer = 0.0
    electricityDishwasher = 0.0
    electricityExtraRefrigerator = 0.0

    units.each do |unit|
      unit_name = unit.name.to_s.upcase

      units_represented = 1
      if unit.additionalProperties.getFeatureAsInteger("Units Represented").is_initialized
        units_represented = unit.additionalProperties.getFeatureAsInteger("Units Represented").get
      end

      electricity_refrgerator_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:ELECTRICITYREFRIGERATOR') AND ReportingFrequency='Run Period' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
      unless sqlFile.execAndReturnVectorOfDouble(electricity_refrgerator_query).get.empty?
        electricityRefrigerator += units_represented * sqlFile.execAndReturnFirstDouble(electricity_refrgerator_query).get
      end

      electricity_clothes_washer_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:ELECTRICITYCLOTHESWASHER') AND ReportingFrequency='Run Period' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
      unless sqlFile.execAndReturnVectorOfDouble(electricity_clothes_washer_query).get.empty?
        electricityClothesWasher += units_represented * sqlFile.execAndReturnFirstDouble(electricity_clothes_washer_query).get
      end

      electricity_clothes_dryer_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:ELECTRICITYCLOTHESDRYER') AND ReportingFrequency='Run Period' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
      unless sqlFile.execAndReturnVectorOfDouble(electricity_clothes_dryer_query).get.empty?
        electricityClothesDryer += units_represented * sqlFile.execAndReturnFirstDouble(electricity_clothes_dryer_query).get
      end

      natural_gas_clothes_dryer_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:NATURALGASCLOTHESDRYER') AND ReportingFrequency='Run Period' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
      unless sqlFile.execAndReturnVectorOfDouble(natural_gas_clothes_dryer_query).get.empty?
        naturalGasClothesDryer += units_represented * sqlFile.execAndReturnFirstDouble(natural_gas_clothes_dryer_query).get
      end

      propane_clothes_dryer_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:PROPANECLOTHESDRYER') AND ReportingFrequency='Run Period' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
      unless sqlFile.execAndReturnVectorOfDouble(propane_clothes_dryer_query).get.empty?
        propaneClothesDryer += units_represented * sqlFile.execAndReturnFirstDouble(propane_clothes_dryer_query).get
      end

      electricity_dishwasher_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:ELECTRICITYDISHWASHER') AND ReportingFrequency='Run Period' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
      unless sqlFile.execAndReturnVectorOfDouble(electricity_dishwasher_query).get.empty?
        electricityDishwasher += units_represented * sqlFile.execAndReturnFirstDouble(electricity_dishwasher_query).get
      end

      electricity_extra_refrigerator_query = "SELECT VariableValue/1000000000 FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableType='Sum' AND VariableName IN ('#{unit_name}:ELECTRICITYEXTRAREFRIGERATOR') AND ReportingFrequency='Run Period' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
      unless sqlFile.execAndReturnVectorOfDouble(electricity_extra_refrigerator_query).get.empty?
        electricityExtraRefrigerator += units_represented * sqlFile.execAndReturnFirstDouble(electricity_extra_refrigerator_query).get
      end
    end

    report_sim_output(runner, "electricity_refrigerator_energy", electricityRefrigerator, "GJ", total_site_units)
    report_sim_output(runner, "electricity_clothes_washer_energy", electricityClothesWasher, "GJ", total_site_units)
    report_sim_output(runner, "electricity_clothes_dryer_energy", electricityClothesDryer, "GJ", total_site_units)
    report_sim_output(runner, "natural_gas_clothes_dryer_energy", naturalGasClothesDryer, "GJ", total_site_units)
    report_sim_output(runner, "propane_clothes_dryer_energy", propaneClothesDryer, "GJ", total_site_units)
    report_sim_output(runner, "electricity_dishwasher_energy", electricityDishwasher, "GJ", total_site_units)
    report_sim_output(runner, "electricity_extra_refrigerator_energy", electricityExtraRefrigerator, "GJ", total_site_units)

    # DEMAND ENERGY
    # Set the frequency for analysis.
    # Must match frequency requested in energyPlusOutputRequests.
    heating_demand = Hash.new(0.0)
    cooling_demand = Hash.new(0.0)
    internal_gains_gain_error = 0.0
    internal_gains_loss_error = 0.0
    outdoor_air_gains_gain_error = 0.0
    outdoor_air_gains_loss_error = 0.0
    surface_convection_gain_error = 0.0
    surface_convection_loss_error = 0.0
    total_energy_balance_gain_error = 0.0
    total_energy_balance_loss_error = 0.0
    cooling_error = 0.0
    heating_error = 0.0

    freq = 'Zone Timestep'

    bldg_heat_transfer_vectors = []
    units.each do |unit|
      unit_name = unit.name.to_s.upcase

      units_represented = 1
      if unit.additionalProperties.getFeatureAsInteger("Units Represented").is_initialized
        units_represented = unit.additionalProperties.getFeatureAsInteger("Units Represented").get
      end

      thermal_zones = []
      unit.spaces.each do |space|
        thermal_zone = space.thermalZone.get
        unless thermal_zones.include? thermal_zone
          thermal_zones << thermal_zone
        end
      end

      thermal_zones.each do |zone|
        zone_name = zone.name.get.to_s

        # Get the heat transfer broken out by compoonent
        heat_transfer_vectors = OsLib_HeatTransfer.thermal_zone_heat_transfer_vectors(runner, zone, sqlFile, freq)

        # Scout heating/cooling demand breakdown
        hvac_transfer_vals = heat_transfer_vectors['All HVAC Heat Transfer Energy'].to_a
        hvac_transfer_vals.each_with_index do |hvac_energy_transfer, i|
          if hvac_energy_transfer > 0 # heating
            # during heating, all heat gains are "reducing" the heating that the HVAC needs to provide, so reverse sign
            heating_demand['windows conduction'] -= units_represented * heat_transfer_vectors['Zone Window Convection Heat Transfer Energy'].to_a[i]
            heating_demand['doors conduction'] -= units_represented * heat_transfer_vectors['Zone Door Convection Heat Transfer Energy'].to_a[i]
            heating_demand['windows solar'] -= units_represented * heat_transfer_vectors['Zone Window Radiation Heat Transfer Energy'].to_a[i]
            heating_demand['wall'] -= units_represented * heat_transfer_vectors['Zone Wall Convection Heat Transfer Energy'].to_a[i]
            heating_demand['foundation wall'] -= units_represented * heat_transfer_vectors['Zone Foundation Wall Convection Heat Transfer Energy'].to_a[i]
            heating_demand['ceiling'] -= units_represented * heat_transfer_vectors['Zone Ceiling Convection Heat Transfer Energy'].to_a[i]
            heating_demand['roof'] -= units_represented * heat_transfer_vectors['Zone Roof Convection Heat Transfer Energy'].to_a[i]
            heating_demand['ground'] -= units_represented * heat_transfer_vectors['Zone Ground Convection Heat Transfer Energy'].to_a[i]
            heating_demand['floor'] -= units_represented * heat_transfer_vectors['Zone Floor Convection Heat Transfer Energy'].to_a[i]
            heating_demand['infiltration'] -= units_represented * heat_transfer_vectors['Zone Infiltration Gains'].to_a[i]
            heating_demand['ventilation'] -= units_represented * heat_transfer_vectors['Zone Ventilation Gains'].to_a[i]
            heating_demand['people gain'] -= units_represented * heat_transfer_vectors['Zone People Convective Heating Energy'].to_a[i]
            heating_demand['equipment gain'] -= units_represented * heat_transfer_vectors['Zone Equipment Internal Gains'].to_a[i]
            heating_demand['lighting gain'] -= units_represented * heat_transfer_vectors['Zone Lights Convective Heating Energy'].to_a[i]
            heating_demand['other gain'] -= units_represented * heat_transfer_vectors['Zone Other Convection Heat Transfer Energy'].to_a[i]
          elsif hvac_energy_transfer < 0 # cooling
            # during cooling, all heat gains are "increasing" the cooling that the HVAC needs to provide, so sign matches convention
            cooling_demand['windows conduction'] += units_represented * heat_transfer_vectors['Zone Window Convection Heat Transfer Energy'].to_a[i]
            cooling_demand['doors conduction'] += units_represented * heat_transfer_vectors['Zone Door Convection Heat Transfer Energy'].to_a[i]
            cooling_demand['windows solar'] += units_represented * heat_transfer_vectors['Zone Window Radiation Heat Transfer Energy'].to_a[i]
            cooling_demand['wall'] += units_represented * heat_transfer_vectors['Zone Wall Convection Heat Transfer Energy'].to_a[i]
            cooling_demand['foundation wall'] += units_represented * heat_transfer_vectors['Zone Foundation Wall Convection Heat Transfer Energy'].to_a[i]
            cooling_demand['ceiling'] += units_represented * heat_transfer_vectors['Zone Ceiling Convection Heat Transfer Energy'].to_a[i]
            cooling_demand['roof'] += units_represented * heat_transfer_vectors['Zone Roof Convection Heat Transfer Energy'].to_a[i]
            cooling_demand['ground'] += units_represented * heat_transfer_vectors['Zone Ground Convection Heat Transfer Energy'].to_a[i]
            cooling_demand['floor'] += units_represented * heat_transfer_vectors['Zone Floor Convection Heat Transfer Energy'].to_a[i]
            cooling_demand['infiltration'] += units_represented * heat_transfer_vectors['Zone Infiltration Gains'].to_a[i]
            cooling_demand['ventilation'] += units_represented * heat_transfer_vectors['Zone Ventilation Gains'].to_a[i]
            cooling_demand['people gain'] += units_represented * heat_transfer_vectors['Zone People Convective Heating Energy'].to_a[i]
            cooling_demand['equipment gain'] += units_represented * heat_transfer_vectors['Zone Equipment Internal Gains'].to_a[i]
            cooling_demand['lighting gain'] += units_represented * heat_transfer_vectors['Zone Lights Convective Heating Energy'].to_a[i]
            cooling_demand['other gain'] += units_represented * heat_transfer_vectors['Zone Other Convection Heat Transfer Energy'].to_a[i]
          end
        end
        internal_gains_gain_error += heat_transfer_vectors["#{zone_name}: Annual Gain Error in Internal Gains"].abs
        internal_gains_loss_error += heat_transfer_vectors["#{zone_name}: Annual Loss Error in Internal Gains"].abs
        outdoor_air_gains_gain_error += heat_transfer_vectors["#{zone_name}: Annual Gain Error in Outdoor Air Gains"].abs
        outdoor_air_gains_loss_error += heat_transfer_vectors["#{zone_name}: Annual Loss Error in Outdoor Air Gains"].abs
        surface_convection_gain_error += heat_transfer_vectors["#{zone_name}: Annual Gain Error in Surface Convection"].abs
        surface_convection_loss_error += heat_transfer_vectors["#{zone_name}: Annual Loss Error in Surface Convection"].abs
        total_energy_balance_gain_error += heat_transfer_vectors["#{zone_name}: Annual Gain Error in Total Energy Balance"].abs
        total_energy_balance_loss_error += heat_transfer_vectors["#{zone_name}: Annual Loss Error in Total Energy Balance"].abs
      end
    end

    report_sim_output(runner, "cond_windows_heating", heating_demand['windows conduction'], "J", total_site_units)
    report_sim_output(runner, "solar_windows_heating", heating_demand['windows solar'], "J", total_site_units)
    report_sim_output(runner, "cond_doors_heating", heating_demand['doors conduction'], "J", total_site_units)
    report_sim_output(runner, "conv_walls_heating", heating_demand['wall'], "J", total_site_units)
    report_sim_output(runner, "conv_ceiling_heating", heating_demand['ceiling'], "J", total_site_units)
    report_sim_output(runner, "conv_roof_heating", heating_demand['roof'], "J", total_site_units)
    report_sim_output(runner, "conv_fwalls_heating", heating_demand['foundation wall'], "J", total_site_units)
    report_sim_output(runner, "conv_ground_heating", heating_demand['ground'], "J", total_site_units)
    report_sim_output(runner, "conv_floor_heating", heating_demand['floor'], "J", total_site_units)
    report_sim_output(runner, "infiltration_heating", heating_demand['infiltration'], "J", total_site_units)
    report_sim_output(runner, "people_heating", heating_demand['people gain'], "J", total_site_units)
    report_sim_output(runner, "equipment_heating", heating_demand['equipment gain'], "J", total_site_units)
    report_sim_output(runner, "lighting_heating", heating_demand['lighting gain'], "J", total_site_units)
    report_sim_output(runner, "ventilation_heating", heating_demand['ventilation'], "J", total_site_units)
    report_sim_output(runner, "conv_other_heating", heating_demand['other gain'], "J", total_site_units)
    report_sim_output(runner, "cond_windows_cooling", cooling_demand['windows conduction'], "J", total_site_units)
    report_sim_output(runner, "solar_windows_cooling", cooling_demand['windows solar'], "J", total_site_units)    
    report_sim_output(runner, "cond_doors_cooling", cooling_demand['doors conduction'], "J", total_site_units)
    report_sim_output(runner, "conv_walls_cooling", cooling_demand['wall'], "J", total_site_units)
    report_sim_output(runner, "conv_ceiling_cooling", cooling_demand['ceiling'], "J", total_site_units)
    report_sim_output(runner, "conv_roof_cooling", cooling_demand['roof'], "J", total_site_units)
    report_sim_output(runner, "conv_fwalls_cooling", cooling_demand['foundation wall'], "J", total_site_units)
    report_sim_output(runner, "conv_ground_cooling", cooling_demand['ground'], "J", total_site_units)
    report_sim_output(runner, "conv_floor_cooling", cooling_demand['floor'], "J", total_site_units)
    report_sim_output(runner, "infiltration_cooling", cooling_demand['infiltration'], "J", total_site_units)
    report_sim_output(runner, "people_cooling", cooling_demand['people gain'], "J", total_site_units)
    report_sim_output(runner, "equipment_cooling", cooling_demand['equipment gain'], "J", total_site_units)
    report_sim_output(runner, "lighting_cooling", cooling_demand['lighting gain'], "J", total_site_units)
    report_sim_output(runner, "ventilation_cooling", cooling_demand['ventilation'], "J", total_site_units)
    report_sim_output(runner, "conv_other_cooling", cooling_demand['other gain'], "J", total_site_units)

    hd = heating_demand['wall']
    hd += heating_demand['foundation wall']
    hd += heating_demand['roof']
    hd += heating_demand['ground']
    hd += heating_demand['floor']
    hd += heating_demand['ceiling']
    hd += heating_demand['infiltration']
    hd += heating_demand['people gain']
    hd += heating_demand['equipment gain']
    hd += heating_demand['ventilation']
    hd += heating_demand['lighting gain']
    hd += heating_demand['windows solar']
    hd += heating_demand['windows conduction']
    hd += heating_demand['doors conduction']
    hd += heating_demand['other gain']
    cd = cooling_demand['wall']
    cd += cooling_demand['foundation wall']
    cd += cooling_demand['roof']
    cd += cooling_demand['ground']
    cd += cooling_demand['floor']
    cd += cooling_demand['ceiling']
    cd += cooling_demand['infiltration']
    cd += cooling_demand['people gain']
    cd += cooling_demand['equipment gain']
    cd += cooling_demand['ventilation']
    cd += cooling_demand['lighting gain']
    cd += cooling_demand['windows solar']
    cd += cooling_demand['windows conduction']
    cd += cooling_demand['doors conduction']
    cd += cooling_demand['other gain']
    report_sim_output(runner, "heating_demand", hd, "J", total_site_units)
    report_sim_output(runner, "cooling_demand", cd, "J", total_site_units)

    report_sim_output(runner, "internal_gains_gain_error", internal_gains_gain_error, "", "")
    report_sim_output(runner, "internal_gains_loss_error", internal_gains_loss_error, "", "")
    report_sim_output(runner, "outdoor_air_gains_gain_error", outdoor_air_gains_gain_error, "", "")
    report_sim_output(runner, "outdoor_air_gains_loss_error", outdoor_air_gains_loss_error, "", "")
    report_sim_output(runner, "surface_convection_gain_error", surface_convection_gain_error, "", "")
    report_sim_output(runner, "surface_convection_loss_error", surface_convection_loss_error, "", "")
    report_sim_output(runner, "total_energy_balance_gain_error", total_energy_balance_gain_error, "", "")
    report_sim_output(runner, "total_energy_balance_loss_error", total_energy_balance_loss_error, "", "")

    # SUPPLY ENERGY
    heatingSupply = 0.0
    coolingSupply = 0.0

    units.each do |unit|
      unit_name = unit.name.to_s.upcase

      units_represented = 1
      if unit.additionalProperties.getFeatureAsInteger("Units Represented").is_initialized
        units_represented = unit.additionalProperties.getFeatureAsInteger("Units Represented").get
      end

      thermal_zones = []
      unit.spaces.each do |space|
        thermal_zone = space.thermalZone.get
        unless thermal_zones.include? thermal_zone
          thermal_zones << thermal_zone
        end
      end

      thermal_zones.each do |thermal_zone|
        key_value = thermal_zone.name.to_s.upcase

        heating_supply_query = "SELECT VariableValue/1000000000 FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex IN (SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE VariableType='Sum' AND KeyValue='#{key_value}' AND VariableName IN ('Zone Air System Sensible Heating Energy') AND ReportingFrequency='Run Period' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
        unless sqlFile.execAndReturnVectorOfDouble(heating_supply_query).get.empty?
          heatingSupply += units_represented * sqlFile.execAndReturnFirstDouble(heating_supply_query).get
        end

        cooling_supply_query = "SELECT VariableValue/1000000000 FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex IN (SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE VariableType='Sum' AND KeyValue='#{key_value}' AND VariableName IN ('Zone Air System Sensible Cooling Energy') AND ReportingFrequency='Run Period' AND VariableUnits='J') AND TimeIndex IN (SELECT TimeIndex FROM Time WHERE EnvironmentPeriodIndex='#{env_period_ix}')"
        unless sqlFile.execAndReturnVectorOfDouble(cooling_supply_query).get.empty?
          coolingSupply += units_represented * sqlFile.execAndReturnFirstDouble(cooling_supply_query).get
        end
      end
    end

    report_sim_output(runner, "heating_supply", heatingSupply, "GJ", total_site_units)
    report_sim_output(runner, "cooling_supply", coolingSupply, "GJ", total_site_units)

    # SUPPLY / DEMAND ERROR
    hd = UnitConversions.convert(hd, "J", total_site_units)
    cd = UnitConversions.convert(cd, "J", total_site_units)
    hs = UnitConversions.convert(heatingSupply, "GJ", total_site_units)
    cs = UnitConversions.convert(coolingSupply, "GJ", total_site_units)
    report_sim_output(runner, "heating_demand_error", hs - hd, "", "")
    report_sim_output(runner, "cooling_demand_error", cs - cd, "", "")

    if hs != 0
      report_sim_output(runner, "heating_demand_error_percent", 100*(hs - hd) / hs, "", "")
    else
      report_sim_output(runner, "heating_demand_error_percent", 0, "", "")
    end
    if cs != 0
      report_sim_output(runner, "cooling_demand_error_percent", 100*(cs - cd) / cs, "", "")
    else
      report_sim_output(runner, "cooling_demand_error_percent", 0, "", "")
    end

    # close the sql file
    sqlFile.close

    return true
  end # end the run method

  def report_sim_output(runner, name, total_val, os_units, desired_units, percent_of_val = 1.0)
    total_val = total_val * percent_of_val
    if os_units.nil? or desired_units.nil? or os_units == desired_units
      valInUnits = total_val
    else
      valInUnits = UnitConversions.convert(total_val, os_units, desired_units)
    end
    runner.registerValue(name, valInUnits)
    runner.registerInfo("Registering #{valInUnits.round(2)} for #{name}.")
  end
end

# register the measure to be used by the application
ScoutInputReport.new.registerWithApplication
