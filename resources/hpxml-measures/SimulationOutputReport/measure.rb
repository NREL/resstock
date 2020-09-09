# frozen_string_literal: true

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require_relative 'resources/constants.rb'
require_relative '../HPXMLtoOpenStudio/resources/constants.rb'
require_relative '../HPXMLtoOpenStudio/resources/hpxml.rb'
require_relative '../HPXMLtoOpenStudio/resources/unit_conversions.rb'

# start the measure
class SimulationOutputReport < OpenStudio::Measure::ReportingMeasure
  # human readable name
  def name
    # Measure name should be the title case of the class name.
    return 'HPXML Simulation Output Report'
  end

  # human readable description
  def description
    return 'Reports simulation outputs for residential HPXML-based models.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'Processes EnergyPlus simulation outputs in order to generate an annual output CSV file and an optional timeseries output CSV file.'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    timeseries_frequency_chs = OpenStudio::StringVector.new
    timeseries_frequency_chs << 'none'
    reporting_frequency_map.keys.each do |freq|
      timeseries_frequency_chs << freq
    end
    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('timeseries_frequency', timeseries_frequency_chs, true)
    arg.setDisplayName('Timeseries Reporting Frequency')
    arg.setDescription("The frequency at which to report timeseries output data. Using 'none' will disable timeseries outputs.")
    arg.setDefaultValue('none')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('include_timeseries_fuel_consumptions', true)
    arg.setDisplayName('Generate Timeseries Output: Fuel Consumptions')
    arg.setDescription('Generates timeseries energy consumptions for each fuel type.')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('include_timeseries_end_use_consumptions', true)
    arg.setDisplayName('Generate Timeseries Output: End Use Consumptions')
    arg.setDescription('Generates timeseries energy consumptions for each end use.')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('include_timeseries_hot_water_uses', true)
    arg.setDisplayName('Generate Timeseries Output: Hot Water Uses')
    arg.setDescription('Generates timeseries hot water usages for each end use.')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('include_timeseries_total_loads', true)
    arg.setDisplayName('Generate Timeseries Output: Total Loads')
    arg.setDescription('Generates timeseries heating/cooling loads.')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('include_timeseries_component_loads', true)
    arg.setDisplayName('Generate Timeseries Output: Component Loads')
    arg.setDescription('Generates timeseries heating/cooling loads disaggregated by component type.')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('include_timeseries_zone_temperatures', true)
    arg.setDisplayName('Generate Timeseries Output: Zone Temperatures')
    arg.setDescription('Generates timeseries temperatures for each thermal zone.')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('include_timeseries_airflows', true)
    arg.setDisplayName('Generate Timeseries Output: Airflows')
    arg.setDescription('Generates timeseries airflows.')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('include_timeseries_weather', true)
    arg.setDisplayName('Generate Timeseries Output: Weather')
    arg.setDescription('Generates timeseries weather data.')
    arg.setDefaultValue(false)
    args << arg

    return args
  end

  # define the outputs that the measure will create
  def outputs
    outs = OpenStudio::Measure::OSOutputVector.new

    setup_outputs

    output_names = []
    @fuels.each do |fuel_type, fuel|
      output_names << get_runner_output_name(fuel)
    end
    @end_uses.each do |key, end_use|
      output_names << get_runner_output_name(end_use)
    end

    output_names.each do |output_name|
      outs << OpenStudio::Measure::OSOutput.makeDoubleOutput(output_name)
    end

    return outs
  end

  # return a vector of IdfObject's to request EnergyPlus objects needed by the run method
  def energyPlusOutputRequests(runner, user_arguments)
    super(runner, user_arguments)

    result = OpenStudio::IdfObjectVector.new

    model = runner.lastOpenStudioModel
    if model.empty?
      runner.registerError('Cannot find last model.')
      return false
    end
    model = model.get

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return result
    end

    # get the last model and sql file
    @model = runner.lastOpenStudioModel.get

    setup_outputs

    # Get a few things from the model
    get_object_maps()

    loads_program = @model.getModelObjectByName(Constants.ObjectNameComponentLoadsProgram.gsub(' ', '_')).get.to_EnergyManagementSystemProgram.get

    # Annual outputs

    # Add meters to increase precision of outputs relative to, e.g., ABUPS report
    meters = []
    @fuels.each do |fuel_type, fuel|
      meters << fuel.meter
    end
    @end_uses.each do |key, end_use|
      meters << end_use.meter
    end
    meters.each do |meter|
      next if meter.nil?

      result << OpenStudio::IdfObject.load("Output:Meter,#{meter},runperiod;").get
    end

    # Add hot water use outputs
    @hot_water_uses.each do |hot_water_type, hot_water|
      result << OpenStudio::IdfObject.load("Output:Variable,*,#{hot_water.variable},runperiod;").get
      break
    end

    # Add unmet load outputs
    @unmet_loads.each do |load_type, unmet_load|
      result << OpenStudio::IdfObject.load("Output:Variable,#{unmet_load.key},#{unmet_load.variable},runperiod;").get
    end

    # Add ideal air system load outputs
    @ideal_system_loads.each do |load_type, ideal_load|
      result << OpenStudio::IdfObject.load("Output:Variable,#{ideal_load.key},#{ideal_load.variable},runperiod;").get
    end

    # Add peak electricity outputs
    @peak_fuels.each do |key, peak_fuel|
      result << OpenStudio::IdfObject.load("Output:Table:Monthly,#{peak_fuel.report},2,#{peak_fuel.meter},HoursPositive,Electricity:Facility,MaximumDuringHoursShown;").get
    end

    # Add component load outputs
    @component_loads.each do |key, comp_load|
      result << OpenStudio::IdfObject.load("EnergyManagementSystem:OutputVariable,#{comp_load.ems_variable}_annual_outvar,#{comp_load.ems_variable},Summed,ZoneTimestep,#{loads_program.name},J;").get
      result << OpenStudio::IdfObject.load("Output:Variable,*,#{comp_load.ems_variable}_annual_outvar,runperiod;").get
    end
    @loads.each do |load_type, load|
      next if load.ems_variable.nil?

      result << OpenStudio::IdfObject.load("EnergyManagementSystem:OutputVariable,#{load.ems_variable}_annual_outvar,#{load.ems_variable},Summed,ZoneTimestep,#{loads_program.name},J;").get
      result << OpenStudio::IdfObject.load("Output:Variable,*,#{load.ems_variable}_annual_outvar,runperiod;").get
    end

    # Add individual HVAC/DHW system variables
    add_object_output_variables('runperiod').each do |outvar|
      result << outvar
    end

    # Timeseries outputs

    timeseries_frequency = runner.getStringArgumentValue('timeseries_frequency', user_arguments)
    if timeseries_frequency != 'none'
      include_timeseries_fuel_consumptions = runner.getBoolArgumentValue('include_timeseries_fuel_consumptions', user_arguments)
      include_timeseries_end_use_consumptions = runner.getBoolArgumentValue('include_timeseries_end_use_consumptions', user_arguments)
      include_timeseries_hot_water_uses = runner.getBoolArgumentValue('include_timeseries_hot_water_uses', user_arguments)
      include_timeseries_total_loads = runner.getBoolArgumentValue('include_timeseries_total_loads', user_arguments)
      include_timeseries_component_loads = runner.getBoolArgumentValue('include_timeseries_component_loads', user_arguments)
      include_timeseries_zone_temperatures = runner.getBoolArgumentValue('include_timeseries_zone_temperatures', user_arguments)
      include_timeseries_airflows = runner.getBoolArgumentValue('include_timeseries_airflows', user_arguments)
      include_timeseries_weather = runner.getBoolArgumentValue('include_timeseries_weather', user_arguments)
    end

    if include_timeseries_fuel_consumptions
      # If fuel uses are selected, we also need to select end uses because
      # fuels may be adjusted by DSE.
      # TODO: This could be removed if we could account for DSE in E+ or used EMS.
      include_timeseries_end_use_consumptions = true
    end

    if include_timeseries_zone_temperatures
      result << OpenStudio::IdfObject.load("Output:Variable,*,Zone Mean Air Temperature,#{timeseries_frequency};").get
      # For reporting temperature-scheduled spaces timeseries temperatures.
      keys = [HPXML::LocationOtherHeatedSpace, HPXML::LocationOtherMultifamilyBufferSpace, HPXML::LocationOtherNonFreezingSpace,
              HPXML::LocationOtherHousingUnit, HPXML::LocationExteriorWall, HPXML::LocationUnderSlab]
      keys.each do |key|
        result << OpenStudio::IdfObject.load("Output:Variable,#{key},Schedule Value,#{timeseries_frequency};").get
      end
    end

    if include_timeseries_airflows
      @airflows.each do |airflow_type, airflow|
        ems_program = @model.getModelObjectByName(airflow.ems_program.gsub(' ', '_')).get.to_EnergyManagementSystemProgram.get
        airflow.ems_variables.each do |ems_variable|
          result << OpenStudio::IdfObject.load("EnergyManagementSystem:OutputVariable,#{ems_variable}_timeseries_outvar,#{ems_variable},Summed,ZoneTimestep,#{ems_program.name},m^3/s;").get
          result << OpenStudio::IdfObject.load("Output:Variable,*,#{ems_variable}_timeseries_outvar,#{timeseries_frequency};").get
        end
      end
    end

    if include_timeseries_weather
      @weather.each do |weather_type, weather_data|
        result << OpenStudio::IdfObject.load("Output:Variable,*,#{weather_data.variable},#{timeseries_frequency};").get
      end
    end

    if include_timeseries_fuel_consumptions
      @fuels.each do |fuel_type, fuel|
        result << OpenStudio::IdfObject.load("Output:Meter,#{fuel.meter},#{timeseries_frequency};").get
      end
    end

    if include_timeseries_end_use_consumptions
      @end_uses.each do |key, end_use|
        next if end_use.meter.nil?

        result << OpenStudio::IdfObject.load("Output:Meter,#{end_use.meter},#{timeseries_frequency};").get
      end
      # Add output variables for individual HVAC/DHW systems
      add_object_output_variables(timeseries_frequency).each do |outvar|
        result << outvar
      end
    end

    if include_timeseries_hot_water_uses
      result << OpenStudio::IdfObject.load("Output:Variable,*,Water Use Equipment Hot Water Volume,#{timeseries_frequency};").get
    end

    if include_timeseries_total_loads
      @loads.each do |load_type, load|
        next if load.ems_variable.nil?

        result << OpenStudio::IdfObject.load("EnergyManagementSystem:OutputVariable,#{load.ems_variable}_timeseries_outvar,#{load.ems_variable},Summed,ZoneTimestep,#{loads_program.name},J;").get
        result << OpenStudio::IdfObject.load("Output:Variable,*,#{load.ems_variable}_timeseries_outvar,#{timeseries_frequency};").get
      end
    end

    if include_timeseries_component_loads
      @component_loads.each do |key, comp_load|
        result << OpenStudio::IdfObject.load("EnergyManagementSystem:OutputVariable,#{comp_load.ems_variable}_timeseries_outvar,#{comp_load.ems_variable},Summed,ZoneTimestep,#{loads_program.name},J;").get
        result << OpenStudio::IdfObject.load("Output:Variable,*,#{comp_load.ems_variable}_timeseries_outvar,#{timeseries_frequency};").get
      end
    end

    return result
  end

  # define what happens when the measure is run
  def run(runner, user_arguments)
    super(runner, user_arguments)

    model = runner.lastOpenStudioModel
    if model.empty?
      runner.registerError('Cannot find OpenStudio model.')
      return false
    end
    @model = model.get

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(@model), user_arguments)
      return false
    end

    timeseries_frequency = runner.getStringArgumentValue('timeseries_frequency', user_arguments)
    if timeseries_frequency != 'none'
      include_timeseries_fuel_consumptions = runner.getBoolArgumentValue('include_timeseries_fuel_consumptions', user_arguments)
      include_timeseries_end_use_consumptions = runner.getBoolArgumentValue('include_timeseries_end_use_consumptions', user_arguments)
      include_timeseries_hot_water_uses = runner.getBoolArgumentValue('include_timeseries_hot_water_uses', user_arguments)
      include_timeseries_total_loads = runner.getBoolArgumentValue('include_timeseries_total_loads', user_arguments)
      include_timeseries_component_loads = runner.getBoolArgumentValue('include_timeseries_component_loads', user_arguments)
      include_timeseries_zone_temperatures = runner.getBoolArgumentValue('include_timeseries_zone_temperatures', user_arguments)
      include_timeseries_airflows = runner.getBoolArgumentValue('include_timeseries_airflows', user_arguments)
      include_timeseries_weather = runner.getBoolArgumentValue('include_timeseries_weather', user_arguments)
    end

    sqlFile = runner.lastEnergyPlusSqlFile
    if sqlFile.empty?
      runner.registerError('Cannot find EnergyPlus sql file.')
      return false
    end
    @sqlFile = sqlFile.get
    if not @sqlFile.connectionOpen
      runner.registerError('EnergyPlus simulation failed.')
      return false
    end
    @model.setSqlFile(@sqlFile)

    hpxml_path = @model.getBuilding.additionalProperties.getFeatureAsString('hpxml_path').get
    @hpxml = HPXML.new(hpxml_path: hpxml_path)
    HVAC.apply_shared_systems(@hpxml)
    get_object_maps()
    @eri_design = @hpxml.header.eri_design

    setup_outputs

    # Set paths
    if not @eri_design.nil?
      # ERI run, store files in a particular location
      output_dir = File.dirname(hpxml_path)
      design_name = @eri_design.gsub(' ', '')
      annual_output_csv_path = File.join(output_dir, "#{design_name}.csv")
      eri_output_csv_path = File.join(output_dir, "#{design_name}_ERI.csv")
      timeseries_output_csv_path = File.join(output_dir, "#{design_name}_#{timeseries_frequency.capitalize}.csv")
    else
      output_dir = File.dirname(@sqlFile.path.to_s)
      annual_output_csv_path = File.join(output_dir, 'results_annual.csv')
      eri_output_csv_path = nil
      timeseries_output_csv_path = File.join(output_dir, 'results_timeseries.csv')
    end

    @timestamps = get_timestamps(timeseries_frequency)

    # Retrieve outputs
    outputs = get_outputs(timeseries_frequency,
                          include_timeseries_fuel_consumptions,
                          include_timeseries_end_use_consumptions,
                          include_timeseries_hot_water_uses,
                          include_timeseries_total_loads,
                          include_timeseries_component_loads,
                          include_timeseries_zone_temperatures,
                          include_timeseries_airflows,
                          include_timeseries_weather)
    if not check_for_errors(runner, outputs)
      return false
    end

    # Write/report results
    write_annual_output_results(runner, outputs, annual_output_csv_path)
    report_sim_outputs(outputs, runner)
    write_eri_output_results(outputs, eri_output_csv_path)
    write_timeseries_output_results(runner, timeseries_output_csv_path, timeseries_frequency,
                                    include_timeseries_fuel_consumptions,
                                    include_timeseries_end_use_consumptions,
                                    include_timeseries_hot_water_uses,
                                    include_timeseries_total_loads,
                                    include_timeseries_component_loads,
                                    include_timeseries_zone_temperatures,
                                    include_timeseries_airflows,
                                    include_timeseries_weather)

    @sqlFile.close()

    return true
  end

  def get_timestamps(timeseries_frequency)
    if timeseries_frequency == 'hourly'
      interval_type = 1
    elsif timeseries_frequency == 'daily'
      interval_type = 2
    elsif timeseries_frequency == 'monthly'
      interval_type = 3
    elsif timeseries_frequency == 'timestep'
      interval_type = -1
    end

    query = "SELECT Year || ' ' || Month || ' ' || Day || ' ' || Hour || ' ' || Minute As Timestamp FROM Time WHERE IntervalType='#{interval_type}'"
    values = @sqlFile.execAndReturnVectorOfString(query)
    fail "Query error: #{query}" unless values.is_initialized

    timestamps = []
    values.get.each do |value|
      year, month, day, hour, minute = value.split(' ')
      ts = ts = Time.new(year, month, day, hour, minute)
      timestamps << ts.strftime('%Y/%m/%d %H:%M:00')
    end

    return timestamps
  end

  def get_outputs(timeseries_frequency,
                  include_timeseries_fuel_consumptions,
                  include_timeseries_end_use_consumptions,
                  include_timeseries_hot_water_uses,
                  include_timeseries_total_loads,
                  include_timeseries_component_loads,
                  include_timeseries_zone_temperatures,
                  include_timeseries_airflows,
                  include_timeseries_weather)
    outputs = {}

    if include_timeseries_fuel_consumptions
      # If fuel uses are selected, we also need to select end uses because
      # fuels may be adjusted by DSE.
      # TODO: This could be removed if we could account for DSE in E+ or used EMS.
      include_timeseries_end_use_consumptions = true
    end

    # HPXML Summary
    outputs[:hpxml_cfa] = @hpxml.building_construction.conditioned_floor_area
    outputs[:hpxml_nbr] = @hpxml.building_construction.number_of_bedrooms
    outputs[:hpxml_nst] = @hpxml.building_construction.number_of_conditioned_floors_above_grade

    # HPXML Systems
    if not @eri_design.nil?
      outputs[:hpxml_eec_heats] = get_hpxml_eec_heats()
      outputs[:hpxml_eec_cools] = get_hpxml_eec_cools()
      outputs[:hpxml_eec_dhws] = get_hpxml_eec_dhws()
    end
    outputs[:hpxml_heat_sys_ids] = get_hpxml_heat_sys_ids()
    outputs[:hpxml_cool_sys_ids] = get_hpxml_cool_sys_ids()
    outputs[:hpxml_dehumidifier_id] = @hpxml.dehumidifiers[0].id if @hpxml.dehumidifiers.size > 0
    outputs[:hpxml_dhw_sys_ids] = get_hpxml_dhw_sys_ids()
    outputs[:hpxml_dse_heats] = get_hpxml_dse_heats(outputs[:hpxml_heat_sys_ids])
    outputs[:hpxml_dse_cools] = get_hpxml_dse_cools(outputs[:hpxml_cool_sys_ids])
    outputs[:hpxml_heat_fuels] = get_hpxml_heat_fuels()
    outputs[:hpxml_dwh_fuels] = get_hpxml_dhw_fuels()

    # Fuel Uses
    @fuels.each do |fuel_type, fuel|
      fuel.annual_output = get_report_meter_data_annual(fuel.meter)
      if include_timeseries_fuel_consumptions
        fuel.timeseries_output = get_report_meter_data_timeseries('', fuel.meter, UnitConversions.convert(1.0, 'J', fuel.timeseries_units), 0, timeseries_frequency)
      end
    end

    # Peak Electricity Consumption
    @peak_fuels.each do |key, peak_fuel|
      peak_fuel.annual_output = get_tabular_data_value(peak_fuel.report.upcase, 'Meter', 'Custom Monthly Report', 'Maximum of Months', 'ELECTRICITY:FACILITY {MAX FOR HOURS SHOWN', peak_fuel.annual_units)
    end

    # Total loads
    @loads.each do |load_type, load|
      next if load.ems_variable.nil?

      load.annual_output = get_report_variable_data_annual(['EMS'], ["#{load.ems_variable}_annual_outvar"])
      if include_timeseries_total_loads
        load.timeseries_output = get_report_variable_data_timeseries(['EMS'], ["#{load.ems_variable}_timeseries_outvar"], UnitConversions.convert(1.0, 'J', load.timeseries_units), 0, timeseries_frequency)
      end
    end

    # Component Loads
    @component_loads.each do |key, comp_load|
      comp_load.annual_output = get_report_variable_data_annual(['EMS'], ["#{comp_load.ems_variable}_annual_outvar"])
      if include_timeseries_component_loads
        comp_load.timeseries_output = get_report_variable_data_timeseries(['EMS'], ["#{comp_load.ems_variable}_timeseries_outvar"], UnitConversions.convert(1.0, 'J', comp_load.timeseries_units), 0, timeseries_frequency)
      end
    end

    # Unmet loads (heating/cooling energy delivered by backup ideal air system)
    @unmet_loads.each do |load_type, unmet_load|
      unmet_load.annual_output = get_report_variable_data_annual([unmet_load.key.upcase], [unmet_load.variable])
    end

    # Ideal system loads (expected fraction of loads that are not met by HVAC)
    @ideal_system_loads.each do |load_type, ideal_load|
      ideal_load.annual_output = get_report_variable_data_annual([ideal_load.key.upcase], [ideal_load.variable])
    end

    # Peak Building Space Heating/Cooling Loads (total heating/cooling energy delivered including backup ideal air system)
    @peak_loads.each do |load_type, peak_load|
      peak_load.annual_output = UnitConversions.convert(get_tabular_data_value('EnergyMeters', 'Entire Facility', 'Annual and Peak Values - Other', peak_load.meter, 'Maximum Value', 'W'), 'Wh', peak_load.annual_units)
    end

    # End Uses (derived from meters)
    @end_uses.each do |key, end_use|
      next if end_use.meter.nil?

      fuel_type, end_use_type = key
      end_use.annual_output = get_report_meter_data_annual(end_use.meter)
      if (end_use_type == EUT::PV) && (@end_uses[key].annual_output > 0)
        end_use.annual_output *= -1.0
      end
      next unless include_timeseries_end_use_consumptions

      timeseries_unit_conv = UnitConversions.convert(1.0, 'J', end_use.timeseries_units)
      if end_use_type == EUT::PV
        timeseries_unit_conv *= -1.0
      end
      end_use.timeseries_output = get_report_meter_data_timeseries('', end_use.meter, timeseries_unit_conv, 0, timeseries_frequency)
    end

    # Hot Water Uses
    @hot_water_uses.each do |hot_water_type, hot_water|
      keys = @model.getWaterUseEquipments.select { |wue| wue.waterUseEquipmentDefinition.endUseSubcategory == hot_water.subcat }.map { |d| d.name.to_s.upcase }
      hot_water.annual_output = get_report_variable_data_annual(keys, [hot_water.variable], UnitConversions.convert(1.0, 'm^3', hot_water.annual_units))
      if include_timeseries_hot_water_uses
        hot_water.timeseries_output = get_report_variable_data_timeseries(keys, [hot_water.variable], UnitConversions.convert(1.0, 'm^3', hot_water.timeseries_units), 0, timeseries_frequency)
      end
    end

    # Space Heating (by System)
    dfhp_loads = get_dfhp_loads(outputs) # Calculate dual-fuel heat pump load
    outputs[:hpxml_heat_sys_ids].each do |sys_id|
      ep_output_names, dfhp_primary, dfhp_backup = get_ep_output_names_for_hvac_heating(sys_id)
      keys = ep_output_names.map(&:upcase)

      # End Use
      @fuels.each do |fuel_type, fuel|
        end_use = @end_uses[[fuel_type, EUT::Heating]]
        vars = get_all_var_keys(end_use.variable)
        end_use.annual_output_by_system[sys_id] = get_report_variable_data_annual(keys, vars)
        if include_timeseries_end_use_consumptions
          end_use.timeseries_output_by_system[sys_id] = get_report_variable_data_timeseries(keys, vars, UnitConversions.convert(1.0, 'J', end_use.timeseries_units), 0, timeseries_frequency)
        end
      end

      # Disaggregated Fan/Pump Energy Use
      end_use = @end_uses[[FT::Elec, EUT::HeatingFanPump]]
      end_use.annual_output_by_system[sys_id] = get_report_variable_data_annual(['EMS'], ep_output_names.select { |name| name.end_with?(Constants.ObjectNameFanPumpDisaggregatePrimaryHeat) || name.end_with?(Constants.ObjectNameFanPumpDisaggregateBackupHeat) })
      if include_timeseries_end_use_consumptions
        end_use.timeseries_output_by_system[sys_id] = get_report_variable_data_timeseries(['EMS'], ep_output_names.select { |name| name.end_with?(Constants.ObjectNameFanPumpDisaggregatePrimaryHeat) || name.end_with?(Constants.ObjectNameFanPumpDisaggregateBackupHeat) }, UnitConversions.convert(1.0, 'J', end_use.timeseries_units), 0, timeseries_frequency)
      end

      # Reference Load
      if [Constants.CalcTypeERIReferenceHome, Constants.CalcTypeERIIndexAdjustmentReferenceHome].include? @eri_design
        @loads[LT::Heating].annual_output_by_system[sys_id] = split_htg_load_to_system_by_fraction(sys_id, @loads[LT::Heating].annual_output, dfhp_loads)
      end
    end

    # Space Cooling (by System)
    outputs[:hpxml_cool_sys_ids].each do |sys_id|
      ep_output_names = get_ep_output_names_for_hvac_cooling(sys_id)
      keys = ep_output_names.map(&:upcase)

      # End Uses
      end_use = @end_uses[[FT::Elec, EUT::Cooling]]
      vars = get_all_var_keys(end_use.variable)
      end_use.annual_output_by_system[sys_id] = get_report_variable_data_annual(keys, vars)
      if include_timeseries_end_use_consumptions
        end_use.timeseries_output_by_system[sys_id] = get_report_variable_data_timeseries(keys, vars, UnitConversions.convert(1.0, 'J', end_use.timeseries_units), 0, timeseries_frequency)
      end

      # Disaggregated Fan/Pump Energy Use
      end_use = @end_uses[[FT::Elec, EUT::CoolingFanPump]]
      end_use.annual_output_by_system[sys_id] = get_report_variable_data_annual(['EMS'], ep_output_names.select { |name| name.end_with? Constants.ObjectNameFanPumpDisaggregateCool })
      if include_timeseries_end_use_consumptions
        end_use.timeseries_output_by_system[sys_id] = get_report_variable_data_timeseries(['EMS'], ep_output_names.select { |name| name.end_with? Constants.ObjectNameFanPumpDisaggregateCool }, UnitConversions.convert(1.0, 'J', end_use.timeseries_units), 0, timeseries_frequency)
      end

      # Reference Load
      if [Constants.CalcTypeERIReferenceHome, Constants.CalcTypeERIIndexAdjustmentReferenceHome].include? @eri_design
        @loads[LT::Cooling].annual_output_by_system[sys_id] = split_clg_load_to_system_by_fraction(sys_id, @loads[LT::Cooling].annual_output)
      end
    end

    # Dehumidifier
    end_use = @end_uses[[FT::Elec, EUT::Dehumidifier]]
    vars = get_all_var_keys(end_use.variable)
    ep_output_name = @hvac_map[outputs[:hpxml_dehumidifier_id]]
    if not ep_output_name.nil?
      keys = ep_output_name.map(&:upcase)
      end_use.annual_output = get_report_variable_data_annual(keys, vars)
      if include_timeseries_end_use_consumptions
        end_use.timeseries_output = get_report_variable_data_timeseries(keys, vars, UnitConversions.convert(1.0, 'J', end_use.timeseries_units), 0, timeseries_frequency)
      end
    else
      end_use.annual_output = 0
      end_use.timeseries_output = [0.0] * @timestamps.size
    end

    # Water Heating (by System)
    solar_keys = []
    dsh_keys = []
    outputs[:hpxml_dhw_sys_ids].each do |sys_id|
      ep_output_names = get_ep_output_names_for_water_heating(sys_id)
      keys = ep_output_names.map(&:upcase)

      # End Use
      @fuels.each do |fuel_type, fuel|
        [EUT::HotWater, EUT::HotWaterRecircPump, EUT::HotWaterSolarThermalPump].each do |end_use_type|
          end_use = @end_uses[[fuel_type, end_use_type]]
          next if end_use.nil?

          vars = get_all_var_keys(end_use.variable)

          end_use.annual_output_by_system[sys_id] = get_report_variable_data_annual(keys, vars)
          if include_timeseries_end_use_consumptions
            end_use.timeseries_output_by_system[sys_id] = get_report_variable_data_timeseries(keys, vars, UnitConversions.convert(1.0, 'J', end_use.timeseries_units), 0, timeseries_frequency)
          end
        end
      end

      # Loads
      @loads[LT::HotWaterDelivered].annual_output_by_system[sys_id] = get_report_variable_data_annual(keys, get_all_var_keys(@loads[LT::HotWaterDelivered].variable))

      # Combi boiler water system
      hvac_id = get_combi_hvac_id(sys_id)
      if not hvac_id.nil?
        @fuels.keys.reverse.each do |fuel_type| # Reverse so that FT::Elec is considered last
          htg_end_use = @end_uses[[fuel_type, EUT::Heating]]
          next unless htg_end_use.annual_output_by_system[hvac_id] > 0

          hw_end_use = @end_uses[[fuel_type, EUT::HotWater]]
          fuel = @fuels[fuel_type]

          combi_hw_vars = ep_output_names.select { |name| name.include? Constants.ObjectNameCombiWaterHeatingEnergy(nil) }

          hw_energy = get_report_variable_data_annual(['EMS'], combi_hw_vars)
          hw_end_use.annual_output_by_system[sys_id] += hw_energy
          htg_end_use.annual_output_by_system[hvac_id] -= hw_energy
          if include_timeseries_end_use_consumptions
            hw_energy_timeseries = get_report_variable_data_timeseries(['EMS'], combi_hw_vars, UnitConversions.convert(1.0, 'J', hw_end_use.timeseries_units), 0, timeseries_frequency)
            hw_end_use.timeseries_output_by_system[sys_id] = hw_end_use.timeseries_output_by_system[sys_id].zip(hw_energy_timeseries).map { |x, y| x + y }
            htg_end_use.timeseries_output_by_system[hvac_id] = htg_end_use.timeseries_output_by_system[hvac_id].zip(hw_energy_timeseries).map { |x, y| x - y }
          end
          break # only apply once
        end
      end

      # Adjust water heater/appliances energy consumptions
      @fuels.keys.reverse.each do |fuel_type| # Reverse so that FT::Elec is considered last
        end_use = @end_uses[[fuel_type, EUT::HotWater]]
        next if end_use.nil?
        next if end_use.variable.nil?
        next unless end_use.annual_output_by_system[sys_id] > 0

        ec_vars = ep_output_names.select { |name| name.include? Constants.ObjectNameWaterHeaterAdjustment(nil) }

        ec_adj = get_report_variable_data_annual(['EMS'], ec_vars)
        break if ec_adj == 0 # No adjustment

        end_use.annual_output_by_system[sys_id] += ec_adj
        if include_timeseries_end_use_consumptions
          ec_adj_timeseries = get_report_variable_data_timeseries(['EMS'], ec_vars, UnitConversions.convert(1.0, 'J', end_use.timeseries_units), 0, timeseries_frequency)
          end_use.timeseries_output_by_system[sys_id] = end_use.timeseries_output_by_system[sys_id].zip(ec_adj_timeseries).map { |x, y| x + y }
        end
        break # only apply once
      end

      # Can only be one solar thermal system
      if solar_keys.empty?
        solar_keys = ep_output_names.select { |name| name.include? Constants.ObjectNameSolarHotWater }.map(&:upcase)
      end
      dsh_keys << ep_output_names.select { |name| name.include? Constants.ObjectNameDesuperheater(nil) }.map(&:upcase)
    end

    # Apply Heating/Cooling DSEs
    outputs[:hpxml_heat_sys_ids].each do |sys_id|
      @fuels.each do |fuel_type, fuel|
        [EUT::Heating, EUT::HeatingFanPump].each do |end_use_type|
          end_use = @end_uses[[fuel_type, end_use_type]]
          next if end_use.nil?

          apply_multiplier_to_output(end_use, fuel, sys_id, 1.0 / outputs[:hpxml_dse_heats][sys_id])
        end
      end
    end
    outputs[:hpxml_cool_sys_ids].each do |sys_id|
      @fuels.each do |fuel_type, fuel|
        [EUT::Cooling, EUT::CoolingFanPump].each do |end_use_type|
          end_use = @end_uses[[fuel_type, end_use_type]]
          next if end_use.nil?

          apply_multiplier_to_output(end_use, fuel, sys_id, 1.0 / outputs[:hpxml_dse_cools][sys_id])
        end
      end
    end

    # Hot Water Load - Solar Thermal
    @loads[LT::HotWaterSolarThermal].annual_output = get_report_variable_data_annual(solar_keys, get_all_var_keys(OutputVars.WaterHeaterLoadSolarThermal))
    @loads[LT::HotWaterSolarThermal].annual_output *= -1 if @loads[LT::HotWaterSolarThermal].annual_output != 0

    # Hot Water Load - Desuperheater
    @loads[LT::HotWaterDesuperheater].annual_output = get_report_variable_data_annual(dsh_keys, get_all_var_keys(@loads[LT::HotWaterDesuperheater].variable))

    # Hot Water Load - Tank Losses (excluding solar storage tank)
    @loads[LT::HotWaterTankLosses].annual_output = get_report_variable_data_annual(solar_keys, ['Water Heater Heat Loss Energy'], not_key: true)
    @loads[LT::HotWaterTankLosses].annual_output *= -1.0 if @loads[LT::HotWaterTankLosses].annual_output < 0

    # Apply solar fraction to load for simple solar water heating systems
    outputs[:hpxml_dhw_sys_ids].each do |sys_id|
      solar_fraction = get_dhw_solar_fraction(sys_id)
      if solar_fraction > 0
        apply_multiplier_to_output(@loads[LT::HotWaterDelivered], @loads[LT::HotWaterSolarThermal], sys_id, 1.0 / (1.0 - solar_fraction))
      end
    end

    # Calculate aggregated values from per-system values as needed
    (@end_uses.values + @loads.values).each do |obj|
      if obj.annual_output.nil?
        if not obj.annual_output_by_system.empty?
          obj.annual_output = obj.annual_output_by_system.values.sum(0.0)
        else
          obj.annual_output = 0.0
        end
      end
      next unless obj.timeseries_output.empty? && (not obj.timeseries_output_by_system.empty?)

      obj.timeseries_output = obj.timeseries_output_by_system.values[0]
      obj.timeseries_output_by_system.values[1..-1].each do |values|
        obj.timeseries_output = obj.timeseries_output.zip(values).map { |x, y| x + y }
      end
    end

    # Get zone temperatures
    if include_timeseries_zone_temperatures
      zone_names = []
      scheduled_temperature_names = []
      @model.getThermalZones.each do |zone|
        if zone.floorArea > 1
          zone_names << zone.name.to_s.upcase
        end
      end
      @model.getScheduleConstants.each do |schedule|
        next unless [HPXML::LocationOtherHeatedSpace, HPXML::LocationOtherMultifamilyBufferSpace, HPXML::LocationOtherNonFreezingSpace,
                     HPXML::LocationOtherHousingUnit, HPXML::LocationExteriorWall, HPXML::LocationUnderSlab].include? schedule.name.to_s

        scheduled_temperature_names << schedule.name.to_s.upcase
      end
      zone_names.sort.each do |zone_name|
        @zone_temps[zone_name] = ZoneTemp.new
        @zone_temps[zone_name].name = "Temperature: #{zone_name.split.map(&:capitalize).join(' ')}"
        @zone_temps[zone_name].timeseries_units = 'F'
        @zone_temps[zone_name].timeseries_output = get_report_variable_data_timeseries([zone_name], ['Zone Mean Air Temperature'], 9.0 / 5.0, 32.0, timeseries_frequency)
      end
      scheduled_temperature_names.sort.each do |scheduled_temperature_name|
        @zone_temps[scheduled_temperature_name] = ZoneTemp.new
        @zone_temps[scheduled_temperature_name].name = "Temperature: #{scheduled_temperature_name.split.map(&:capitalize).join(' ')}"
        @zone_temps[scheduled_temperature_name].timeseries_units = 'F'
        @zone_temps[scheduled_temperature_name].timeseries_output = get_report_variable_data_timeseries([scheduled_temperature_name], ['Schedule Value'], 9.0 / 5.0, 32.0, timeseries_frequency)
      end
    end

    if include_timeseries_airflows
      @airflows.each do |airflow_type, airflow|
        airflow.timeseries_output = get_report_variable_data_timeseries(['EMS'], airflow.ems_variables.map { |var| "#{var}_timeseries_outvar" }, UnitConversions.convert(1.0, 'm^3/s', 'cfm'), 0, timeseries_frequency)
      end
    end

    if include_timeseries_weather
      @weather.each do |weather_type, weather_data|
        if weather_data.timeseries_units == 'F'
          unit_conv = 9.0 / 5.0
          unit_adder = 32.0
        else
          unit_conv = UnitConversions.convert(1.0, weather_data.variable_units, weather_data.timeseries_units)
          unit_adder = 0
        end
        weather_data.timeseries_output = get_report_variable_data_timeseries(['Environment'], [weather_data.variable], unit_conv, unit_adder, timeseries_frequency)
      end
    end

    return outputs
  end

  def check_for_errors(runner, outputs)
    all_total = @fuels.values.map { |x| x.annual_output }.sum(0.0)
    all_total += @unmet_loads.values.map { |x| x.annual_output }.sum(0.0)
    all_total += @ideal_system_loads.values.map { |x| x.annual_output }.sum(0.0)
    if all_total == 0
      runner.registerError('Simulation unsuccessful.')
      return false
    end

    # Check sum of end use outputs match fuel outputs
    @fuels.keys.each do |fuel_type|
      sum_categories = @end_uses.select { |k, eu| k[0] == fuel_type }.map { |k, eu| eu.annual_output }.sum(0.0)
      fuel_total = @fuels[fuel_type].annual_output
      fuel_total += @end_uses[[FT::Elec, EUT::PV]].annual_output if fuel_type == FT::Elec
      if (fuel_total - sum_categories).abs > 0.1
        runner.registerError("#{fuel_type} category end uses (#{sum_categories}) do not sum to total (#{fuel_total}).")
        return false
      end
    end

    # Check sum of timeseries outputs match annual outputs
    { @end_uses => 'End Use',
      @fuels => 'Fuel',
      @loads => 'Load',
      @component_loads => 'Component Load' }.each do |outputs, output_type|
      outputs.each do |key, obj|
        next if obj.timeseries_output.empty?

        sum_timeseries = UnitConversions.convert(obj.timeseries_output.sum(0.0), obj.timeseries_units, obj.annual_units)
        annual_total = obj.annual_output
        if (annual_total - sum_timeseries).abs > 0.1
          runner.registerError("Timeseries outputs (#{sum_timeseries}) do not sum to annual output (#{annual_total}) for #{output_type}: #{key}.")
          return false
        end
      end
    end

    return true
  end

  def write_annual_output_results(runner, outputs, csv_path)
    line_break = nil
    pv_end_use = @end_uses[[FT::Elec, EUT::PV]]

    results_out = []
    @fuels.each do |fuel_type, fuel|
      results_out << ["#{fuel.name} (#{fuel.annual_units})", fuel.annual_output.round(2)]
      if fuel_type == FT::Elec
        results_out << ['Electricity: Net (MBtu)', (fuel.annual_output + pv_end_use.annual_output).round(2)]
      end
    end
    results_out << [line_break]
    @end_uses.each do |key, end_use|
      results_out << ["#{end_use.name} (#{end_use.annual_units})", end_use.annual_output.round(2)]
    end
    results_out << [line_break]
    @loads.each do |load_type, load|
      results_out << ["#{load.name} (#{load.annual_units})", load.annual_output.round(2)]
    end
    results_out << [line_break]
    @unmet_loads.each do |load_type, unmet_load|
      results_out << ["#{unmet_load.name} (#{unmet_load.annual_units})", unmet_load.annual_output.round(2)]
    end
    results_out << [line_break]
    @peak_fuels.each do |key, peak_fuel|
      results_out << ["#{peak_fuel.name} (#{peak_fuel.annual_units})", peak_fuel.annual_output.round(2)]
    end
    results_out << [line_break]
    @peak_loads.each do |load_type, peak_load|
      results_out << ["#{peak_load.name} (#{peak_load.annual_units})", peak_load.annual_output.round(2)]
    end
    results_out << [line_break]
    @component_loads.each do |load_type, load|
      results_out << ["#{load.name} (#{load.annual_units})", load.annual_output.round(2)]
    end
    results_out << [line_break]
    @hot_water_uses.each do |hot_water_type, hot_water|
      results_out << ["#{hot_water.name} (#{hot_water.annual_units})", hot_water.annual_output.round(2)]
    end

    CSV.open(csv_path, 'wb') { |csv| results_out.to_a.each { |elem| csv << elem } }
    runner.registerInfo("Wrote annual output results to #{csv_path}.")
  end

  def report_sim_outputs(outputs, runner)
    @fuels.each do |fuel_type, fuel|
      output_name = get_runner_output_name(fuel)
      runner.registerValue(output_name, fuel.annual_output.round(2))
      runner.registerInfo("Registering #{fuel.annual_output.round(2)} for #{output_name}.")
    end
    @end_uses.each do |key, end_use|
      output_name = get_runner_output_name(end_use)
      runner.registerValue(output_name, end_use.annual_output.round(2))
      runner.registerInfo("Registering #{end_use.annual_output.round(2)} for #{output_name}.")
    end
  end

  def get_runner_output_name(obj)
    return "#{obj.name} #{obj.annual_units}"
  end

  def write_eri_output_results(outputs, csv_path)
    return true if csv_path.nil?

    line_break = nil

    def sanitize_string(s)
      [' ', ':', '/'].each do |c|
        next unless s.include? c

        s = s.gsub(c, '')
      end
      return s
    end

    def ordered_values(hash, sys_ids)
      vals = []
      sys_ids.each do |sys_id|
        vals << hash[sys_id]
        fail 'Could not look up data.' if vals[-1].nil?
      end
      return vals
    end

    def get_sys_ids(type, heat_sys_ids, cool_sys_ids, dhw_sys_ids)
      if type.downcase.include? 'hot water'
        return dhw_sys_ids
      elsif type.downcase.include? 'heating'
        return heat_sys_ids
      elsif type.downcase.include? 'cooling'
        return cool_sys_ids
      end

      fail "Unhandled type: '#{type}'."
    end

    results_out = []

    heat_sys_ids = outputs[:hpxml_heat_sys_ids]
    cool_sys_ids = outputs[:hpxml_cool_sys_ids]
    dhw_sys_ids = outputs[:hpxml_dhw_sys_ids]

    # Sys IDS
    results_out << ['hpxml_heat_sys_ids', heat_sys_ids.to_s]
    results_out << ['hpxml_cool_sys_ids', cool_sys_ids.to_s]
    results_out << ['hpxml_dhw_sys_ids', dhw_sys_ids.to_s]
    results_out << [line_break]

    # EECs
    results_out << ['hpxml_eec_heats', ordered_values(outputs[:hpxml_eec_heats], heat_sys_ids).to_s]
    results_out << ['hpxml_eec_cools', ordered_values(outputs[:hpxml_eec_cools], cool_sys_ids).to_s]
    results_out << ['hpxml_eec_dhws', ordered_values(outputs[:hpxml_eec_dhws], dhw_sys_ids).to_s]
    results_out << [line_break]

    # Fuel types
    results_out << ['hpxml_heat_fuels', ordered_values(outputs[:hpxml_heat_fuels], heat_sys_ids).to_s]
    results_out << ['hpxml_dwh_fuels', ordered_values(outputs[:hpxml_dwh_fuels], dhw_sys_ids).to_s]
    results_out << [line_break]

    # Fuel uses
    @fuels.each do |fuel_type, fuel|
      key_name = sanitize_string("fuel#{fuel_type}")
      results_out << [key_name, fuel.annual_output.to_s]
    end
    results_out << [line_break]

    # End Uses
    @end_uses.each do |key, end_use|
      fuel_type, end_use_type = key
      key_name = sanitize_string("enduse#{fuel_type}#{end_use_type}")
      if not end_use.annual_output_by_system.empty?
        sys_ids = get_sys_ids(end_use_type, heat_sys_ids, cool_sys_ids, dhw_sys_ids)
        results_out << [key_name, ordered_values(end_use.annual_output_by_system, sys_ids).to_s]
      else
        results_out << [key_name, end_use.annual_output.to_s]
      end
    end
    results_out << [line_break]

    # Loads by System
    @loads.each do |load_type, load|
      key_name = sanitize_string("load#{load_type}")
      if not load.annual_output_by_system.empty?
        sys_ids = get_sys_ids(load_type, heat_sys_ids, cool_sys_ids, dhw_sys_ids)
        results_out << [key_name, ordered_values(load.annual_output_by_system, sys_ids).to_s]
      end
    end
    results_out << [line_break]

    # Misc
    results_out << ['hpxml_cfa', outputs[:hpxml_cfa].to_s]
    results_out << ['hpxml_nbr', outputs[:hpxml_nbr].to_s]
    results_out << ['hpxml_nst', outputs[:hpxml_nst].to_s]

    CSV.open(csv_path, 'wb') { |csv| results_out.to_a.each { |elem| csv << elem } }
  end

  def write_timeseries_output_results(runner, csv_path, timeseries_frequency,
                                      include_timeseries_fuel_consumptions,
                                      include_timeseries_end_use_consumptions,
                                      include_timeseries_hot_water_uses,
                                      include_timeseries_total_loads,
                                      include_timeseries_component_loads,
                                      include_timeseries_zone_temperatures,
                                      include_timeseries_airflows,
                                      include_timeseries_weather)
    return if timeseries_frequency == 'none'

    # Time column
    if ['timestep', 'hourly', 'daily', 'monthly'].include? timeseries_frequency
      data = ['Time', nil]
    else
      fail "Unexpected timeseries_frequency: #{timeseries_frequency}."
    end
    @timestamps.each do |timestamp|
      data << timestamp
    end

    if include_timeseries_fuel_consumptions
      fuel_data = @fuels.values.select { |x| !x.timeseries_output.empty? }.map { |x| [x.name, x.timeseries_units] + x.timeseries_output.map { |v| v.round(2) } }
    else
      fuel_data = []
    end
    if include_timeseries_end_use_consumptions
      end_use_data = @end_uses.values.select { |x| !x.timeseries_output.empty? }.map { |x| [x.name, x.timeseries_units] + x.timeseries_output.map { |v| v.round(2) } }
    else
      end_use_data = []
    end
    if include_timeseries_hot_water_uses
      hot_water_use_data = @hot_water_uses.values.select { |x| !x.timeseries_output.empty? }.map { |x| [x.name, x.timeseries_units] + x.timeseries_output.map { |v| v.round(2) } }
    else
      hot_water_use_data = []
    end
    if include_timeseries_total_loads
      total_loads_data = @loads.values.select { |x| !x.timeseries_output.empty? }.map { |x| [x.name, x.timeseries_units] + x.timeseries_output.map { |v| v.round(2) } }
    else
      total_loads_data = {}
    end
    if include_timeseries_component_loads
      comp_loads_data = @component_loads.values.select { |x| !x.timeseries_output.empty? }.map { |x| [x.name, x.timeseries_units] + x.timeseries_output.map { |v| v.round(2) } }
    else
      comp_loads_data = []
    end
    if include_timeseries_zone_temperatures
      zone_temps_data = @zone_temps.values.select { |x| !x.timeseries_output.empty? }.map { |x| [x.name, x.timeseries_units] + x.timeseries_output.map { |v| v.round(2) } }
    else
      zone_temps_data = []
    end
    if include_timeseries_airflows
      airflows_data = @airflows.values.select { |x| !x.timeseries_output.empty? }.map { |x| [x.name, x.timeseries_units] + x.timeseries_output.map { |v| v.round(2) } }
    else
      airflows_data = []
    end
    if include_timeseries_weather
      weather_data = @weather.values.select { |x| !x.timeseries_output.empty? }.map { |x| [x.name, x.timeseries_units] + x.timeseries_output.map { |v| v.round(2) } }
    else
      weather_data = []
    end

    return if fuel_data.size + end_use_data.size + hot_water_use_data.size + total_loads_data.size + comp_loads_data.size + zone_temps_data.size + airflows_data.size + weather_data.size == 0

    fail 'Unable to obtain timestamps.' if @timestamps.empty?

    # Assemble data
    data = data.zip(*fuel_data, *end_use_data, *hot_water_use_data, *total_loads_data, *comp_loads_data, *zone_temps_data, *airflows_data, *weather_data)

    # Error-check
    n_elements = []
    data.each do |data_array|
      n_elements << data_array.size
    end
    if n_elements.uniq.size > 1
      fail "Inconsistent number of array elements: #{n_elements.uniq}."
    end

    # Write file
    CSV.open(csv_path, 'wb') { |csv| data.to_a.each { |elem| csv << elem } }
    runner.registerInfo("Wrote timeseries output results to #{csv_path}.")
  end

  def get_hpxml_dse_heats(heat_sys_ids)
    dse_heats = {}

    heat_sys_ids.each do |sys_id|
      dse_heats[sys_id] = 1.0 # Init
    end

    @hpxml.hvac_distributions.each do |hvac_dist|
      dist_id = hvac_dist.id
      next if hvac_dist.annual_heating_dse.nil?

      dse_heat = hvac_dist.annual_heating_dse

      # Get all HVAC systems attached to it
      @hpxml.heating_systems.each do |htg_system|
        next unless htg_system.fraction_heat_load_served > 0
        next if htg_system.distribution_system_idref.nil?
        next unless dist_id == htg_system.distribution_system_idref

        sys_id = get_system_or_seed_id(htg_system)
        dse_heats[sys_id] = dse_heat
      end
      @hpxml.heat_pumps.each do |heat_pump|
        next unless heat_pump.fraction_heat_load_served > 0
        next if heat_pump.distribution_system_idref.nil?
        next unless dist_id == heat_pump.distribution_system_idref

        sys_id = get_system_or_seed_id(heat_pump)
        dse_heats[sys_id] = dse_heat

        if is_dfhp(heat_pump)
          # Also apply to dual-fuel heat pump backup system
          dse_heats[dfhp_backup_sys_id(sys_id)] = dse_heat
        end
      end
    end

    return dse_heats
  end

  def get_hpxml_dse_cools(cool_sys_ids)
    dse_cools = {}

    # Init
    cool_sys_ids.each do |sys_id|
      dse_cools[sys_id] = 1.0
    end

    @hpxml.hvac_distributions.each do |hvac_dist|
      dist_id = hvac_dist.id
      next if hvac_dist.annual_cooling_dse.nil?

      dse_cool = hvac_dist.annual_cooling_dse

      # Get all HVAC systems attached to it
      @hpxml.cooling_systems.each do |clg_system|
        next unless clg_system.fraction_cool_load_served > 0
        next if clg_system.distribution_system_idref.nil?
        next unless dist_id == clg_system.distribution_system_idref

        sys_id = get_system_or_seed_id(clg_system)
        dse_cools[sys_id] = dse_cool
      end
      @hpxml.heat_pumps.each do |heat_pump|
        next unless heat_pump.fraction_cool_load_served > 0
        next if heat_pump.distribution_system_idref.nil?
        next unless dist_id == heat_pump.distribution_system_idref

        sys_id = get_system_or_seed_id(heat_pump)
        dse_cools[sys_id] = dse_cool
      end
    end

    return dse_cools
  end

  def get_hpxml_heat_fuels()
    heat_fuels = {}

    @hpxml.heating_systems.each do |htg_system|
      next unless htg_system.fraction_heat_load_served > 0

      sys_id = get_system_or_seed_id(htg_system)
      heat_fuels[sys_id] = htg_system.heating_system_fuel
    end
    @hpxml.heat_pumps.each do |heat_pump|
      next unless heat_pump.fraction_heat_load_served > 0

      sys_id = get_system_or_seed_id(heat_pump)
      heat_fuels[sys_id] = heat_pump.heat_pump_fuel
      if is_dfhp(heat_pump)
        heat_fuels[dfhp_backup_sys_id(sys_id)] = heat_pump.backup_heating_fuel
      end
    end

    return heat_fuels
  end

  def get_hpxml_dhw_fuels()
    dhw_fuels = {}

    @hpxml.water_heating_systems.each do |dhw_system|
      sys_id = dhw_system.id
      if [HPXML::WaterHeaterTypeCombiTankless, HPXML::WaterHeaterTypeCombiStorage].include? dhw_system.water_heater_type
        @hpxml.heating_systems.each do |heating_system|
          next unless dhw_system.related_hvac_idref == heating_system.id

          dhw_fuels[sys_id] = heating_system.heating_system_fuel
        end
      else
        dhw_fuels[sys_id] = dhw_system.fuel_type
      end
    end

    return dhw_fuels
  end

  def get_hpxml_heat_sys_ids()
    sys_ids = []

    @hpxml.heating_systems.each do |htg_system|
      next unless htg_system.fraction_heat_load_served > 0

      sys_ids << get_system_or_seed_id(htg_system)
    end
    @hpxml.heat_pumps.each do |heat_pump|
      next unless heat_pump.fraction_heat_load_served > 0

      sys_ids << get_system_or_seed_id(heat_pump)
      if is_dfhp(heat_pump)
        sys_ids << dfhp_backup_sys_id(sys_ids[-1])
      end
    end

    return sys_ids
  end

  def get_hpxml_cool_sys_ids()
    sys_ids = []

    @hpxml.cooling_systems.each do |clg_system|
      next unless clg_system.fraction_cool_load_served > 0

      sys_ids << get_system_or_seed_id(clg_system)
    end
    @hpxml.heat_pumps.each do |heat_pump|
      next unless heat_pump.fraction_cool_load_served > 0

      sys_ids << get_system_or_seed_id(heat_pump)
    end

    return sys_ids
  end

  def get_hpxml_dhw_sys_ids()
    sys_ids = []

    @hpxml.water_heating_systems.each do |dhw_system|
      sys_ids << dhw_system.id
    end

    return sys_ids
  end

  def get_hpxml_eec_heats()
    eec_heats = {}

    @hpxml.heating_systems.each do |htg_system|
      next unless htg_system.fraction_heat_load_served > 0

      sys_id = get_system_or_seed_id(htg_system)
      if not htg_system.heating_efficiency_afue.nil?
        eec_heats[sys_id] = get_eri_eec_value_numerator('AFUE') / htg_system.heating_efficiency_afue
      elsif not htg_system.heating_efficiency_percent.nil?
        eec_heats[sys_id] = get_eri_eec_value_numerator('Percent') / htg_system.heating_efficiency_percent
      end
    end
    @hpxml.heat_pumps.each do |heat_pump|
      next unless heat_pump.fraction_heat_load_served > 0

      sys_id = get_system_or_seed_id(heat_pump)
      if not heat_pump.heating_efficiency_hspf.nil?
        eec_heats[sys_id] = get_eri_eec_value_numerator('HSPF') / heat_pump.heating_efficiency_hspf
      elsif not heat_pump.heating_efficiency_cop.nil?
        eec_heats[sys_id] = get_eri_eec_value_numerator('COP') / heat_pump.heating_efficiency_cop
      end
      if is_dfhp(heat_pump)
        if not heat_pump.backup_heating_efficiency_afue.nil?
          eec_heats[dfhp_backup_sys_id(sys_id)] = get_eri_eec_value_numerator('AFUE') / heat_pump.backup_heating_efficiency_afue
        elsif not heat_pump.backup_heating_efficiency_percent.nil?
          eec_heats[dfhp_backup_sys_id(sys_id)] = get_eri_eec_value_numerator('Percent') / heat_pump.backup_heating_efficiency_percent
        end
      end
    end

    return eec_heats
  end

  def get_hpxml_eec_cools()
    eec_cools = {}

    @hpxml.cooling_systems.each do |clg_system|
      next unless clg_system.fraction_cool_load_served > 0

      sys_id = get_system_or_seed_id(clg_system)
      if not clg_system.cooling_efficiency_seer.nil?
        eec_cools[sys_id] = get_eri_eec_value_numerator('SEER') / clg_system.cooling_efficiency_seer
      elsif not clg_system.cooling_efficiency_eer.nil?
        eec_cools[sys_id] = get_eri_eec_value_numerator('EER') / clg_system.cooling_efficiency_eer
      end

      if clg_system.cooling_system_type == HPXML::HVACTypeEvaporativeCooler
        eec_cools[sys_id] = get_eri_eec_value_numerator('SEER') / 15.0 # Arbitrary
      end
    end
    @hpxml.heat_pumps.each do |heat_pump|
      next unless heat_pump.fraction_cool_load_served > 0

      sys_id = get_system_or_seed_id(heat_pump)
      if not heat_pump.cooling_efficiency_seer.nil?
        eec_cools[sys_id] = get_eri_eec_value_numerator('SEER') / heat_pump.cooling_efficiency_seer
      elsif not heat_pump.cooling_efficiency_eer.nil?
        eec_cools[sys_id] = get_eri_eec_value_numerator('EER') / heat_pump.cooling_efficiency_eer
      end
    end

    return eec_cools
  end

  def get_hpxml_eec_dhws()
    eec_dhws = {}

    @hpxml.water_heating_systems.each do |dhw_system|
      sys_id = dhw_system.id
      value = dhw_system.energy_factor
      wh_type = dhw_system.water_heater_type
      if wh_type == HPXML::WaterHeaterTypeTankless
        value_adj = dhw_system.performance_adjustment
      else
        value_adj = 1.0
      end

      if value.nil?
        @model.getWaterHeaterMixeds.each do |wh|
          next unless @dhw_map[sys_id].include? wh.name.to_s

          value = wh.additionalProperties.getFeatureAsDouble('EnergyFactor').get
        end
      end

      if (not value.nil?) && (not value_adj.nil?)
        eec_dhws[sys_id] = get_eri_eec_value_numerator('EF') / (Float(value) * Float(value_adj))
      end
    end

    return eec_dhws
  end

  def get_eri_eec_value_numerator(unit)
    if ['HSPF', 'SEER', 'EER'].include? unit
      return 3.413
    elsif ['AFUE', 'COP', 'Percent', 'EF'].include? unit
      return 1.0
    end
  end

  def get_system_or_seed_id(sys)
    if not sys.seed_id.nil?
      return sys.seed_id
    end

    return sys.id
  end

  def get_report_meter_data_annual(variable, unit_conv = UnitConversions.convert(1.0, 'J', 'MBtu'))
    query = "SELECT SUM(VariableValue*#{unit_conv}) FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableName='#{variable}' AND ReportingFrequency='Run Period' AND VariableUnits='J')"
    value = @sqlFile.execAndReturnFirstDouble(query)
    fail "Query error: #{query}" unless value.is_initialized

    return value.get
  end

  def get_report_variable_data_annual(key_values_list, variable_names_list, unit_conv = UnitConversions.convert(1.0, 'J', 'MBtu'), not_key: false)
    keys = "'" + key_values_list.join("','") + "'"
    vars = "'" + variable_names_list.join("','") + "'"
    if not_key
      s_not = 'NOT '
    else
      s_not = ''
    end
    query = "SELECT SUM(VariableValue*#{unit_conv}) FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex IN (SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE KeyValue #{s_not}IN (#{keys}) AND VariableName IN (#{vars}) AND ReportingFrequency='Run Period')"
    value = @sqlFile.execAndReturnFirstDouble(query)
    fail "Query error: #{query}" unless value.is_initialized

    return value.get
  end

  def get_report_meter_data_timeseries(key_value, variable_name, unit_conv, unit_adder, timeseries_frequency)
    query = "SELECT SUM(VariableValue*#{unit_conv}+#{unit_adder}) FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE KeyValue='#{key_value}' AND VariableName='#{variable_name}' AND ReportingFrequency='#{reporting_frequency_map[timeseries_frequency]}' AND VariableUnits='J') GROUP BY TimeIndex ORDER BY TimeIndex"
    values = @sqlFile.execAndReturnVectorOfDouble(query)
    fail "Query error: #{query}" unless values.is_initialized

    values = values.get
    values += [0.0] * @timestamps.size if values.size == 0
    return values
  end

  def get_report_variable_data_timeseries(key_values_list, variable_names_list, unit_conv, unit_adder, timeseries_frequency)
    keys = "'" + key_values_list.join("','") + "'"
    vars = "'" + variable_names_list.join("','") + "'"
    query = "SELECT SUM(VariableValue*#{unit_conv}+#{unit_adder}) FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex IN (SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE KeyValue IN (#{keys}) AND VariableName IN (#{vars}) AND ReportingFrequency='#{reporting_frequency_map[timeseries_frequency]}') GROUP BY TimeIndex ORDER BY TimeIndex"
    values = @sqlFile.execAndReturnVectorOfDouble(query)
    fail "Query error: #{query}" unless values.is_initialized

    values = values.get
    values += [0.0] * @timestamps.size if values.size == 0

    if (key_values_list.size == 1) && (key_values_list[0] == 'EMS')
      if (timeseries_frequency.downcase == 'timestep' || (timeseries_frequency.downcase == 'hourly' && @model.getTimestep.numberOfTimestepsPerHour == 1))
        # Shift all values by 1 timestep due to EMS reporting lag
        return values[1..-1] + [values[-1]]
      end
    end

    return values
  end

  def get_tabular_data_value(report_name, report_for_string, table_name, row_name, col_name, units)
    query = "SELECT SUM(Value) FROM TabularDataWithStrings WHERE ReportName='#{report_name}' AND ReportForString='#{report_for_string}' AND TableName='#{table_name}' AND RowName='#{row_name}' AND ColumnName='#{col_name}' AND Units='#{units}'"
    result = @sqlFile.execAndReturnFirstDouble(query)
    return result.get
  end

  def apply_multiplier_to_output(obj, sync_obj, sys_id, mult)
    # Annual
    orig_value = obj.annual_output_by_system[sys_id]
    obj.annual_output_by_system[sys_id] = orig_value * mult
    sync_obj.annual_output += (orig_value * mult - orig_value)

    # Timeseries
    if not obj.timeseries_output_by_system.empty?
      orig_values = obj.timeseries_output_by_system[sys_id]
      obj.timeseries_output_by_system[sys_id] = obj.timeseries_output_by_system[sys_id].map { |x| x * mult }
      diffs = obj.timeseries_output_by_system[sys_id].zip(orig_values).map { |x, y| x - y }
      sync_obj.timeseries_output = sync_obj.timeseries_output.zip(diffs).map { |x, y| x + y }
    end
  end

  def get_combi_hvac_id(sys_id)
    @hpxml.water_heating_systems.each do |dhw_system|
      next unless sys_id == dhw_system.id
      next unless [HPXML::WaterHeaterTypeCombiTankless, HPXML::WaterHeaterTypeCombiStorage].include? dhw_system.water_heater_type

      return dhw_system.related_hvac_idref
    end

    return
  end

  def get_combi_water_system_ec(hx_load, htg_load, htg_energy)
    water_sys_frac = hx_load / htg_load
    return htg_energy * water_sys_frac
  end

  def get_dfhp_loads(outputs)
    dfhp_loads = {}
    outputs[:hpxml_heat_sys_ids].each do |sys_id|
      ep_output_names, dfhp_primary, dfhp_backup = get_ep_output_names_for_hvac_heating(sys_id)
      keys = ep_output_names.map(&:upcase)
      next unless dfhp_primary || dfhp_backup

      if dfhp_primary
        vars = get_all_var_keys(OutputVars.SpaceHeatingDFHPPrimaryLoad)
      else
        vars = get_all_var_keys(OutputVars.SpaceHeatingDFHPBackupLoad)
        sys_id = dfhp_primary_sys_id(sys_id)
      end
      dfhp_loads[[sys_id, dfhp_primary]] = get_report_variable_data_annual(keys, vars)
    end
    return dfhp_loads
  end

  def split_htg_load_to_system_by_fraction(sys_id, bldg_load, dfhp_loads)
    @hpxml.heating_systems.each do |htg_system|
      next unless htg_system.fraction_heat_load_served > 0
      next unless get_system_or_seed_id(htg_system) == sys_id

      return bldg_load * htg_system.fraction_heat_load_served
    end
    @hpxml.heat_pumps.each do |heat_pump|
      next unless heat_pump.fraction_heat_load_served > 0

      load_fraction = 1.0
      if is_dfhp(heat_pump)
        if dfhp_primary_sys_id(sys_id) == sys_id
          load_fraction = dfhp_loads[[sys_id, true]] / (dfhp_loads[[sys_id, true]] + dfhp_loads[[sys_id, false]]) unless dfhp_loads[[sys_id, true]].nil?
        else
          sys_id = dfhp_primary_sys_id(sys_id)
          load_fraction = dfhp_loads[[sys_id, false]] / (dfhp_loads[[sys_id, true]] + dfhp_loads[[sys_id, false]]) unless dfhp_loads[[sys_id, true]].nil?
        end
        load_fraction = 1.0 if load_fraction.nan?
      end
      next unless get_system_or_seed_id(heat_pump) == sys_id

      return bldg_load * heat_pump.fraction_heat_load_served * load_fraction
    end
  end

  def split_clg_load_to_system_by_fraction(sys_id, bldg_load)
    @hpxml.cooling_systems.each do |clg_system|
      next unless clg_system.fraction_cool_load_served > 0
      next unless get_system_or_seed_id(clg_system) == sys_id

      return bldg_load * clg_system.fraction_cool_load_served
    end
    @hpxml.heat_pumps.each do |heat_pump|
      next unless heat_pump.fraction_cool_load_served > 0
      next unless get_system_or_seed_id(heat_pump) == sys_id

      return bldg_load * heat_pump.fraction_cool_load_served
    end
  end

  def dfhp_backup_sys_id(primary_sys_id)
    return primary_sys_id + '_dfhp_backup_system'
  end

  def dfhp_primary_sys_id(backup_sys_id)
    return backup_sys_id.gsub('_dfhp_backup_system', '')
  end

  def is_dfhp(system)
    if system.class != HPXML::HeatPump
      return false
    end
    if (not system.backup_heating_switchover_temp.nil?) && (system.backup_heating_fuel != HPXML::FuelTypeElectricity)
      return true
    end

    return false
  end

  def get_all_var_keys(var)
    var_keys = []
    var.keys.each do |key|
      var[key].each do |var_key|
        var_keys << var_key
      end
    end
    return var_keys
  end

  def get_dhw_solar_fraction(sys_id)
    solar_fraction = 0.0
    if @hpxml.solar_thermal_systems.size > 0
      solar_thermal_system = @hpxml.solar_thermal_systems[0]
      water_heater_idref = solar_thermal_system.water_heating_system_idref
      if water_heater_idref.nil? || (water_heater_idref == sys_id)
        solar_fraction = solar_thermal_system.solar_fraction.to_f
      end
    end
    return solar_fraction
  end

  def get_ep_output_names_for_hvac_heating(sys_id)
    dfhp_primary = false
    dfhp_backup = false
    (@hpxml.heating_systems + @hpxml.heat_pumps).each do |system|
      # This is super ugly. Can we simplify it?
      if is_dfhp(system)
        if (dfhp_primary_sys_id(sys_id) == sys_id) && [system.seed_id, system.id].include?(sys_id)
          dfhp_primary = true
        elsif [system.seed_id, system.id].include? dfhp_primary_sys_id(sys_id)
          dfhp_backup = true
          sys_id = dfhp_primary_sys_id(sys_id)
        end
      end
      next unless system.seed_id == sys_id

      sys_id = system.id
      break
    end

    fail 'Unexpected result.' if dfhp_primary && dfhp_backup

    output_names = @hvac_map[sys_id].dup

    if dfhp_primary || dfhp_backup
      # Exclude output names associated with primary/backup system as appropriate
      output_names.reverse.each do |o|
        is_backup_obj = (o.include?(Constants.ObjectNameFanPumpDisaggregateBackupHeat) || o.include?(Constants.ObjectNameBackupHeatingCoil))
        if dfhp_primary && is_backup_obj
          output_names.delete(o)
        elsif dfhp_backup && (not is_backup_obj)
          output_names.delete(o)
        end
      end
    end

    return output_names, dfhp_primary, dfhp_backup
  end

  def get_ep_output_names_for_hvac_cooling(sys_id)
    (@hpxml.cooling_systems + @hpxml.heat_pumps).each do |system|
      next unless system.seed_id == sys_id

      sys_id = system.id
      break
    end

    return @hvac_map[sys_id]
  end

  def get_ep_output_names_for_water_heating(sys_id)
    return @dhw_map[sys_id]
  end

  def get_object_maps()
    # Retrieve HPXML->E+ object name maps
    @hvac_map = eval(@model.getBuilding.additionalProperties.getFeatureAsString('hvac_map').get)
    @dhw_map = eval(@model.getBuilding.additionalProperties.getFeatureAsString('dhw_map').get)
  end

  def add_object_output_variables(timeseries_frequency)
    hvac_output_vars = [OutputVars.SpaceHeatingElectricity,
                        OutputVars.SpaceHeatingFuel(EPlus::FuelTypeNaturalGas),
                        OutputVars.SpaceHeatingFuel(EPlus::FuelTypeOil),
                        OutputVars.SpaceHeatingFuel(EPlus::FuelTypePropane),
                        OutputVars.SpaceHeatingFuel(EPlus::FuelTypeWoodCord),
                        OutputVars.SpaceHeatingFuel(EPlus::FuelTypeWoodPellets),
                        OutputVars.SpaceHeatingFuel(EPlus::FuelTypeCoal),
                        OutputVars.SpaceHeatingDFHPPrimaryLoad,
                        OutputVars.SpaceHeatingDFHPBackupLoad,
                        OutputVars.SpaceCoolingElectricity,
                        OutputVars.DehumidifierElectricity]

    dhw_output_vars = [OutputVars.WaterHeatingElectricity,
                       OutputVars.WaterHeatingElectricityRecircPump,
                       OutputVars.WaterHeatingElectricitySolarThermalPump,
                       OutputVars.WaterHeatingFuel(EPlus::FuelTypeNaturalGas),
                       OutputVars.WaterHeatingFuel(EPlus::FuelTypeOil),
                       OutputVars.WaterHeatingFuel(EPlus::FuelTypePropane),
                       OutputVars.WaterHeatingFuel(EPlus::FuelTypeWoodCord),
                       OutputVars.WaterHeatingFuel(EPlus::FuelTypeWoodPellets),
                       OutputVars.WaterHeatingFuel(EPlus::FuelTypeCoal),
                       OutputVars.WaterHeatingLoad,
                       OutputVars.WaterHeatingLoadTankLosses,
                       OutputVars.WaterHeaterLoadDesuperheater,
                       OutputVars.WaterHeaterLoadSolarThermal]

    names_to_objs = {}
    [@hvac_map, @dhw_map].each do |map|
      map.each do |sys_id, object_names|
        object_names.each do |object_name|
          names_to_objs[object_name] = @model.getModelObjectsByName(object_name, true)
        end
      end
    end

    # Remove objects that are not referenced by output vars and are not
    # EMS output vars.
    { @hvac_map => hvac_output_vars,
      @dhw_map => dhw_output_vars }.each do |map, vars|
      all_vars = vars.reduce({}, :merge)
      map.each do |sys_id, object_names|
        objects_to_delete = []
        object_names.each do |object_name|
          names_to_objs[object_name].each do |object|
            next if object.to_EnergyManagementSystemOutputVariable.is_initialized
            next unless all_vars[object.class.to_s].nil? # Referenced?

            objects_to_delete << object
          end
        end
        objects_to_delete.uniq.each do |object|
          map[sys_id].delete object
        end
      end
    end

    def add_output_variables(vars, object, timeseries_frequency)
      if object.to_EnergyManagementSystemOutputVariable.is_initialized
        return [OpenStudio::IdfObject.load("Output:Variable,*,#{object.name},#{timeseries_frequency};").get]
      else
        obj_class = nil
        vars.keys.each do |k|
          method_name = "to_#{k.gsub('OpenStudio::Model::', '')}"
          tmp = object.public_send(method_name) if object.respond_to? method_name
          if (not tmp.nil?) && tmp.is_initialized
            obj_class = tmp.get.class.to_s
          end
        end
        return [] if vars[obj_class].nil?

        results = []
        vars[obj_class].each do |object_var|
          results << OpenStudio::IdfObject.load("Output:Variable,#{object.name},#{object_var},#{timeseries_frequency};").get
        end
        return results
      end
    end

    results = []

    # Add output variables to model
    ems_objects = []
    @hvac_map.each do |sys_id, hvac_names|
      hvac_names.each do |hvac_name|
        names_to_objs[hvac_name].each do |hvac_object|
          if hvac_object.to_EnergyManagementSystemOutputVariable.is_initialized
            ems_objects << hvac_object
          else
            hvac_output_vars.each do |hvac_output_var|
              add_output_variables(hvac_output_var, hvac_object, timeseries_frequency).each do |outvar|
                results << outvar
              end
            end
          end
        end
      end
    end
    @dhw_map.each do |sys_id, dhw_names|
      dhw_names.each do |dhw_name|
        names_to_objs[dhw_name].each do |dhw_object|
          if dhw_object.to_EnergyManagementSystemOutputVariable.is_initialized
            ems_objects << dhw_object
          else
            dhw_output_vars.each do |dhw_output_var|
              add_output_variables(dhw_output_var, dhw_object, timeseries_frequency).each do |outvar|
                results << outvar
              end
            end
          end
        end
      end
    end

    # Add EMS output variables to model
    ems_objects.uniq.each do |ems_object|
      add_output_variables(nil, ems_object, timeseries_frequency).each do |outvar|
        results << outvar
      end
    end

    return results
  end

  class BaseOutput
    def initialize()
      @timeseries_output = []
    end
    attr_accessor(:name, :annual_output, :timeseries_output, :annual_units, :timeseries_units)
  end

  class Fuel < BaseOutput
    def initialize(meter: nil)
      super()
      @meter = meter
      @timeseries_output_by_system = {}
    end
    attr_accessor(:meter, :timeseries_output_by_system)
  end

  class EndUse < BaseOutput
    def initialize(meter: nil, variable: nil)
      super()
      @meter = meter
      @variable = variable
      @timeseries_output_by_system = {}
      @annual_output_by_system = {}
    end
    attr_accessor(:meter, :variable, :annual_output_by_system, :timeseries_output_by_system)
  end

  class HotWater < BaseOutput
    def initialize(subcat:)
      super()
      @subcat = subcat
    end
    attr_accessor(:subcat, :keys, :variable)
  end

  class PeakFuel < BaseOutput
    def initialize(meter:, report:)
      super()
      @meter = meter
      @report = report
    end
    attr_accessor(:meter, :report)
  end

  class Load < BaseOutput
    def initialize(variable: nil, ems_variable: nil)
      super()
      @variable = variable
      @ems_variable = ems_variable
      @timeseries_output_by_system = {}
      @annual_output_by_system = {}
    end
    attr_accessor(:variable, :ems_variable, :annual_output_by_system, :timeseries_output_by_system)
  end

  class ComponentLoad < BaseOutput
    def initialize(ems_variable:)
      super()
      @ems_variable = ems_variable
    end
    attr_accessor(:ems_variable)
  end

  class UnmetLoad < BaseOutput
    def initialize(key:, variable:)
      super()
      @key = key
      @variable = variable
    end
    attr_accessor(:key, :variable)
  end

  class PeakLoad < BaseOutput
    def initialize(meter:)
      super()
      @meter = meter
    end
    attr_accessor(:meter)
  end

  class ZoneTemp < BaseOutput
    def initialize
      super()
    end
    attr_accessor()
  end

  class Airflow < BaseOutput
    def initialize(ems_program:, ems_variables:)
      super()
      @ems_program = ems_program
      @ems_variables = ems_variables
    end
    attr_accessor(:ems_program, :ems_variables)
  end

  class Weather < BaseOutput
    def initialize(variable:, variable_units:, timeseries_units:)
      super()
      @variable = variable
      @variable_units = variable_units
      @timeseries_units = timeseries_units
    end
    attr_accessor(:variable, :variable_units)
  end

  def setup_outputs
    def get_timeseries_units_from_fuel_type(fuel_type)
      if fuel_type == FT::Elec
        return 'kWh'
      end

      return 'kBtu'
    end

    ep_fuel_names = { FT::Gas => EPlus.output_fuel_map(EPlus::FuelTypeNaturalGas),
                      FT::Oil => EPlus.output_fuel_map(EPlus::FuelTypeOil),
                      FT::Propane => EPlus.output_fuel_map(EPlus::FuelTypePropane),
                      FT::WoodCord => EPlus.output_fuel_map(EPlus::FuelTypeWoodCord),
                      FT::WoodPellets => EPlus.output_fuel_map(EPlus::FuelTypeWoodPellets),
                      FT::Coal => EPlus.output_fuel_map(EPlus::FuelTypeCoal) }

    # Fuels

    @fuels = {}
    @fuels[FT::Elec] = Fuel.new(meter: 'Electricity:Facility')
    @fuels[FT::Gas] = Fuel.new(meter: "#{ep_fuel_names[FT::Gas]}:Facility")
    @fuels[FT::Oil] = Fuel.new(meter: "#{ep_fuel_names[FT::Oil]}:Facility")
    @fuels[FT::Propane] = Fuel.new(meter: "#{ep_fuel_names[FT::Propane]}:Facility")
    @fuels[FT::WoodCord] = Fuel.new(meter: "#{ep_fuel_names[FT::WoodCord]}:Facility")
    @fuels[FT::WoodPellets] = Fuel.new(meter: "#{ep_fuel_names[FT::WoodPellets]}:Facility")
    @fuels[FT::Coal] = Fuel.new(meter: "#{ep_fuel_names[FT::Coal]}:Facility")

    @fuels.each do |fuel_type, fuel|
      fuel.name = "#{fuel_type}: Total"
      fuel.annual_units = 'MBtu'
      fuel.timeseries_units = get_timeseries_units_from_fuel_type(fuel_type)
    end

    # End Uses

    # NOTE: Some end uses are obtained from meters, others are rolled up from
    # output variables so that we can have more control.
    @end_uses = {}
    @end_uses[[FT::Elec, EUT::Heating]] = EndUse.new(variable: OutputVars.SpaceHeatingElectricity)
    @end_uses[[FT::Elec, EUT::HeatingFanPump]] = EndUse.new()
    @end_uses[[FT::Elec, EUT::Cooling]] = EndUse.new(variable: OutputVars.SpaceCoolingElectricity)
    @end_uses[[FT::Elec, EUT::CoolingFanPump]] = EndUse.new()
    @end_uses[[FT::Elec, EUT::HotWater]] = EndUse.new(variable: OutputVars.WaterHeatingElectricity)
    @end_uses[[FT::Elec, EUT::HotWaterRecircPump]] = EndUse.new(variable: OutputVars.WaterHeatingElectricityRecircPump)
    @end_uses[[FT::Elec, EUT::HotWaterSolarThermalPump]] = EndUse.new(variable: OutputVars.WaterHeatingElectricitySolarThermalPump)
    @end_uses[[FT::Elec, EUT::LightsInterior]] = EndUse.new(meter: "#{Constants.ObjectNameInteriorLighting}:InteriorLights:Electricity")
    @end_uses[[FT::Elec, EUT::LightsGarage]] = EndUse.new(meter: "#{Constants.ObjectNameGarageLighting}:InteriorLights:Electricity")
    @end_uses[[FT::Elec, EUT::LightsExterior]] = EndUse.new(meter: 'ExteriorLights:Electricity')
    @end_uses[[FT::Elec, EUT::MechVent]] = EndUse.new(meter: "#{Constants.ObjectNameMechanicalVentilation}:InteriorEquipment:Electricity")
    @end_uses[[FT::Elec, EUT::WholeHouseFan]] = EndUse.new(meter: "#{Constants.ObjectNameWholeHouseFan}:InteriorEquipment:Electricity")
    @end_uses[[FT::Elec, EUT::Refrigerator]] = EndUse.new(meter: "#{Constants.ObjectNameRefrigerator}:InteriorEquipment:Electricity")
    if @eri_design.nil? # Skip end uses not used by ERI
      @end_uses[[FT::Elec, EUT::Freezer]] = EndUse.new(meter: "#{Constants.ObjectNameFreezer}:InteriorEquipment:Electricity")
    end
    @end_uses[[FT::Elec, EUT::Dehumidifier]] = EndUse.new(variable: OutputVars.DehumidifierElectricity)
    @end_uses[[FT::Elec, EUT::Dishwasher]] = EndUse.new(meter: "#{Constants.ObjectNameDishwasher}:InteriorEquipment:Electricity")
    @end_uses[[FT::Elec, EUT::ClothesWasher]] = EndUse.new(meter: "#{Constants.ObjectNameClothesWasher}:InteriorEquipment:Electricity")
    @end_uses[[FT::Elec, EUT::ClothesDryer]] = EndUse.new(meter: "#{Constants.ObjectNameClothesDryer}:InteriorEquipment:Electricity")
    @end_uses[[FT::Elec, EUT::RangeOven]] = EndUse.new(meter: "#{Constants.ObjectNameCookingRange}:InteriorEquipment:Electricity")
    @end_uses[[FT::Elec, EUT::CeilingFan]] = EndUse.new(meter: "#{Constants.ObjectNameCeilingFan}:InteriorEquipment:Electricity")
    @end_uses[[FT::Elec, EUT::Television]] = EndUse.new(meter: "#{Constants.ObjectNameMiscTelevision}:InteriorEquipment:Electricity")
    @end_uses[[FT::Elec, EUT::PlugLoads]] = EndUse.new(meter: "#{Constants.ObjectNameMiscPlugLoads}:InteriorEquipment:Electricity")
    if @eri_design.nil? # Skip end uses not used by ERI
      @end_uses[[FT::Elec, EUT::Vehicle]] = EndUse.new(meter: "#{Constants.ObjectNameMiscElectricVehicleCharging}:InteriorEquipment:Electricity")
      @end_uses[[FT::Elec, EUT::WellPump]] = EndUse.new(meter: "#{Constants.ObjectNameMiscWellPump}:InteriorEquipment:Electricity")
      @end_uses[[FT::Elec, EUT::PoolHeater]] = EndUse.new(meter: "#{Constants.ObjectNameMiscPoolHeater}:InteriorEquipment:Electricity")
      @end_uses[[FT::Elec, EUT::PoolPump]] = EndUse.new(meter: "#{Constants.ObjectNameMiscPoolPump}:InteriorEquipment:Electricity")
      @end_uses[[FT::Elec, EUT::HotTubHeater]] = EndUse.new(meter: "#{Constants.ObjectNameMiscHotTubHeater}:InteriorEquipment:Electricity")
      @end_uses[[FT::Elec, EUT::HotTubPump]] = EndUse.new(meter: "#{Constants.ObjectNameMiscHotTubPump}:InteriorEquipment:Electricity")
    end
    @end_uses[[FT::Elec, EUT::PV]] = EndUse.new(meter: 'ElectricityProduced:Facility')
    @end_uses[[FT::Gas, EUT::Heating]] = EndUse.new(variable: OutputVars.SpaceHeatingFuel(EPlus::FuelTypeNaturalGas))
    @end_uses[[FT::Gas, EUT::HotWater]] = EndUse.new(variable: OutputVars.WaterHeatingFuel(EPlus::FuelTypeNaturalGas))
    @end_uses[[FT::Gas, EUT::ClothesDryer]] = EndUse.new(meter: "#{Constants.ObjectNameClothesDryer}:InteriorEquipment:#{ep_fuel_names[FT::Gas]}")
    @end_uses[[FT::Gas, EUT::RangeOven]] = EndUse.new(meter: "#{Constants.ObjectNameCookingRange}:InteriorEquipment:#{ep_fuel_names[FT::Gas]}")
    if @eri_design.nil? # Skip end uses not used by ERI
      @end_uses[[FT::Gas, EUT::PoolHeater]] = EndUse.new(meter: "#{Constants.ObjectNameMiscPoolHeater}:InteriorEquipment:#{ep_fuel_names[FT::Gas]}")
      @end_uses[[FT::Gas, EUT::HotTubHeater]] = EndUse.new(meter: "#{Constants.ObjectNameMiscHotTubHeater}:InteriorEquipment:#{ep_fuel_names[FT::Gas]}")
      @end_uses[[FT::Gas, EUT::Grill]] = EndUse.new(meter: "#{Constants.ObjectNameMiscGrill}:InteriorEquipment:#{ep_fuel_names[FT::Gas]}")
      @end_uses[[FT::Gas, EUT::Lighting]] = EndUse.new(meter: "#{Constants.ObjectNameMiscLighting}:InteriorEquipment:#{ep_fuel_names[FT::Gas]}")
      @end_uses[[FT::Gas, EUT::Fireplace]] = EndUse.new(meter: "#{Constants.ObjectNameMiscFireplace}:InteriorEquipment:#{ep_fuel_names[FT::Gas]}")
    end
    @end_uses[[FT::Oil, EUT::Heating]] = EndUse.new(variable: OutputVars.SpaceHeatingFuel(EPlus::FuelTypeOil))
    @end_uses[[FT::Oil, EUT::HotWater]] = EndUse.new(variable: OutputVars.WaterHeatingFuel(EPlus::FuelTypeOil))
    @end_uses[[FT::Oil, EUT::ClothesDryer]] = EndUse.new(meter: "#{Constants.ObjectNameClothesDryer}:InteriorEquipment:#{ep_fuel_names[FT::Oil]}")
    @end_uses[[FT::Oil, EUT::RangeOven]] = EndUse.new(meter: "#{Constants.ObjectNameCookingRange}:InteriorEquipment:#{ep_fuel_names[FT::Oil]}")
    if @eri_design.nil? # Skip end uses not used by ERI
      @end_uses[[FT::Oil, EUT::Grill]] = EndUse.new(meter: "#{Constants.ObjectNameMiscGrill}:InteriorEquipment:#{ep_fuel_names[FT::Oil]}")
      @end_uses[[FT::Oil, EUT::Lighting]] = EndUse.new(meter: "#{Constants.ObjectNameMiscLighting}:InteriorEquipment:#{ep_fuel_names[FT::Oil]}")
      @end_uses[[FT::Oil, EUT::Fireplace]] = EndUse.new(meter: "#{Constants.ObjectNameMiscFireplace}:InteriorEquipment:#{ep_fuel_names[FT::Oil]}")
    end
    @end_uses[[FT::Propane, EUT::Heating]] = EndUse.new(variable: OutputVars.SpaceHeatingFuel(EPlus::FuelTypePropane))
    @end_uses[[FT::Propane, EUT::HotWater]] = EndUse.new(variable: OutputVars.WaterHeatingFuel(EPlus::FuelTypePropane))
    @end_uses[[FT::Propane, EUT::ClothesDryer]] = EndUse.new(meter: "#{Constants.ObjectNameClothesDryer}:InteriorEquipment:#{ep_fuel_names[FT::Propane]}")
    @end_uses[[FT::Propane, EUT::RangeOven]] = EndUse.new(meter: "#{Constants.ObjectNameCookingRange}:InteriorEquipment:#{ep_fuel_names[FT::Propane]}")
    if @eri_design.nil? # Skip end uses not used by ERI
      @end_uses[[FT::Propane, EUT::Grill]] = EndUse.new(meter: "#{Constants.ObjectNameMiscGrill}:InteriorEquipment:#{ep_fuel_names[FT::Propane]}")
      @end_uses[[FT::Propane, EUT::Lighting]] = EndUse.new(meter: "#{Constants.ObjectNameMiscLighting}:InteriorEquipment:#{ep_fuel_names[FT::Propane]}")
      @end_uses[[FT::Propane, EUT::Fireplace]] = EndUse.new(meter: "#{Constants.ObjectNameMiscFireplace}:InteriorEquipment:#{ep_fuel_names[FT::Propane]}")
    end
    @end_uses[[FT::WoodCord, EUT::Heating]] = EndUse.new(variable: OutputVars.SpaceHeatingFuel(EPlus::FuelTypeWoodCord))
    @end_uses[[FT::WoodCord, EUT::HotWater]] = EndUse.new(variable: OutputVars.WaterHeatingFuel(EPlus::FuelTypeWoodCord))
    @end_uses[[FT::WoodCord, EUT::ClothesDryer]] = EndUse.new(meter: "#{Constants.ObjectNameClothesDryer}:InteriorEquipment:#{ep_fuel_names[FT::WoodCord]}")
    @end_uses[[FT::WoodCord, EUT::RangeOven]] = EndUse.new(meter: "#{Constants.ObjectNameCookingRange}:InteriorEquipment:#{ep_fuel_names[FT::WoodCord]}")
    if @eri_design.nil? # Skip end uses not used by ERI
      @end_uses[[FT::WoodCord, EUT::Grill]] = EndUse.new(meter: "#{Constants.ObjectNameMiscGrill}:InteriorEquipment:#{ep_fuel_names[FT::WoodCord]}")
      @end_uses[[FT::WoodCord, EUT::Lighting]] = EndUse.new(meter: "#{Constants.ObjectNameMiscLighting}:InteriorEquipment:#{ep_fuel_names[FT::WoodCord]}")
      @end_uses[[FT::WoodCord, EUT::Fireplace]] = EndUse.new(meter: "#{Constants.ObjectNameMiscFireplace}:InteriorEquipment:#{ep_fuel_names[FT::WoodCord]}")
    end
    @end_uses[[FT::WoodPellets, EUT::Heating]] = EndUse.new(variable: OutputVars.SpaceHeatingFuel(EPlus::FuelTypeWoodPellets))
    @end_uses[[FT::WoodPellets, EUT::HotWater]] = EndUse.new(variable: OutputVars.WaterHeatingFuel(EPlus::FuelTypeWoodPellets))
    @end_uses[[FT::WoodPellets, EUT::ClothesDryer]] = EndUse.new(meter: "#{Constants.ObjectNameClothesDryer}:InteriorEquipment:#{ep_fuel_names[FT::WoodPellets]}")
    @end_uses[[FT::WoodPellets, EUT::RangeOven]] = EndUse.new(meter: "#{Constants.ObjectNameCookingRange}:InteriorEquipment:#{ep_fuel_names[FT::WoodPellets]}")
    if @eri_design.nil? # Skip end uses not used by ERI
      @end_uses[[FT::WoodPellets, EUT::Grill]] = EndUse.new(meter: "#{Constants.ObjectNameMiscGrill}:InteriorEquipment:#{ep_fuel_names[FT::WoodPellets]}")
      @end_uses[[FT::WoodPellets, EUT::Lighting]] = EndUse.new(meter: "#{Constants.ObjectNameMiscLighting}:InteriorEquipment:#{ep_fuel_names[FT::WoodPellets]}")
      @end_uses[[FT::WoodPellets, EUT::Fireplace]] = EndUse.new(meter: "#{Constants.ObjectNameMiscFireplace}:InteriorEquipment:#{ep_fuel_names[FT::WoodPellets]}")
    end
    @end_uses[[FT::Coal, EUT::Heating]] = EndUse.new(variable: OutputVars.SpaceHeatingFuel(EPlus::FuelTypeCoal))
    @end_uses[[FT::Coal, EUT::HotWater]] = EndUse.new(variable: OutputVars.WaterHeatingFuel(EPlus::FuelTypeCoal))
    @end_uses[[FT::Coal, EUT::ClothesDryer]] = EndUse.new(meter: "#{Constants.ObjectNameClothesDryer}:InteriorEquipment:#{ep_fuel_names[FT::Coal]}")
    @end_uses[[FT::Coal, EUT::RangeOven]] = EndUse.new(meter: "#{Constants.ObjectNameCookingRange}:InteriorEquipment:#{ep_fuel_names[FT::Coal]}")
    if @eri_design.nil? # Skip end uses not used by ERI
      @end_uses[[FT::Coal, EUT::Grill]] = EndUse.new(meter: "#{Constants.ObjectNameMiscGrill}:InteriorEquipment:#{ep_fuel_names[FT::Coal]}")
      @end_uses[[FT::Coal, EUT::Lighting]] = EndUse.new(meter: "#{Constants.ObjectNameMiscLighting}:InteriorEquipment:#{ep_fuel_names[FT::Coal]}")
      @end_uses[[FT::Coal, EUT::Fireplace]] = EndUse.new(meter: "#{Constants.ObjectNameMiscFireplace}:InteriorEquipment:#{ep_fuel_names[FT::Coal]}")
    end

    @end_uses.each do |key, end_use|
      fuel_type, end_use_type = key
      end_use.name = "#{fuel_type}: #{end_use_type}"
      end_use.annual_units = 'MBtu'
      end_use.timeseries_units = get_timeseries_units_from_fuel_type(fuel_type)
    end

    # Hot Water Uses
    @hot_water_uses = {}
    @hot_water_uses[HWT::ClothesWasher] = HotWater.new(subcat: Constants.ObjectNameClothesWasher)
    @hot_water_uses[HWT::Dishwasher] = HotWater.new(subcat: Constants.ObjectNameDishwasher)
    @hot_water_uses[HWT::Fixtures] = HotWater.new(subcat: Constants.ObjectNameFixtures)
    @hot_water_uses[HWT::DistributionWaste] = HotWater.new(subcat: Constants.ObjectNameDistributionWaste)

    @hot_water_uses.each do |hot_water_type, hot_water|
      hot_water.variable = 'Water Use Equipment Hot Water Volume'
      hot_water.name = "Hot Water: #{hot_water_type}"
      hot_water.annual_units = 'gal'
      hot_water.timeseries_units = 'gal'
    end

    # Peak Fuels
    @peak_fuels = {}
    @peak_fuels[[FT::Elec, PFT::Winter]] = PeakFuel.new(meter: 'Heating:EnergyTransfer', report: 'Peak Electricity Winter Total')
    @peak_fuels[[FT::Elec, PFT::Summer]] = PeakFuel.new(meter: 'Cooling:EnergyTransfer', report: 'Peak Electricity Summer Total')

    @peak_fuels.each do |key, peak_fuel|
      fuel_type, peak_fuel_type = key
      peak_fuel.name = "Peak #{fuel_type}: #{peak_fuel_type} Total"
      peak_fuel.annual_units = 'W'
    end

    # Loads

    @loads = {}
    @loads[LT::Heating] = Load.new(ems_variable: 'loads_htg_tot')
    @loads[LT::Cooling] = Load.new(ems_variable: 'loads_clg_tot')
    @loads[LT::HotWaterDelivered] = Load.new(variable: OutputVars.WaterHeatingLoad)
    @loads[LT::HotWaterTankLosses] = Load.new()
    @loads[LT::HotWaterDesuperheater] = Load.new(variable: OutputVars.WaterHeaterLoadDesuperheater)
    @loads[LT::HotWaterSolarThermal] = Load.new()

    @loads.each do |load_type, load|
      load.name = "Load: #{load_type}"
      load.annual_units = 'MBtu'
      load.timeseries_units = 'kBtu'
    end

    # Component Loads

    @component_loads = {}
    @component_loads[[LT::Heating, CLT::Roofs]] = ComponentLoad.new(ems_variable: 'loads_htg_roofs')
    @component_loads[[LT::Heating, CLT::Ceilings]] = ComponentLoad.new(ems_variable: 'loads_htg_ceilings')
    @component_loads[[LT::Heating, CLT::Walls]] = ComponentLoad.new(ems_variable: 'loads_htg_walls')
    @component_loads[[LT::Heating, CLT::RimJoists]] = ComponentLoad.new(ems_variable: 'loads_htg_rim_joists')
    @component_loads[[LT::Heating, CLT::FoundationWalls]] = ComponentLoad.new(ems_variable: 'loads_htg_foundation_walls')
    @component_loads[[LT::Heating, CLT::Doors]] = ComponentLoad.new(ems_variable: 'loads_htg_doors')
    @component_loads[[LT::Heating, CLT::Windows]] = ComponentLoad.new(ems_variable: 'loads_htg_windows')
    @component_loads[[LT::Heating, CLT::Skylights]] = ComponentLoad.new(ems_variable: 'loads_htg_skylights')
    @component_loads[[LT::Heating, CLT::Floors]] = ComponentLoad.new(ems_variable: 'loads_htg_floors')
    @component_loads[[LT::Heating, CLT::Slabs]] = ComponentLoad.new(ems_variable: 'loads_htg_slabs')
    @component_loads[[LT::Heating, CLT::InternalMass]] = ComponentLoad.new(ems_variable: 'loads_htg_internal_mass')
    @component_loads[[LT::Heating, CLT::Infiltration]] = ComponentLoad.new(ems_variable: 'loads_htg_infil')
    @component_loads[[LT::Heating, CLT::NaturalVentilation]] = ComponentLoad.new(ems_variable: 'loads_htg_natvent')
    @component_loads[[LT::Heating, CLT::MechanicalVentilation]] = ComponentLoad.new(ems_variable: 'loads_htg_mechvent')
    @component_loads[[LT::Heating, CLT::WholeHouseFan]] = ComponentLoad.new(ems_variable: 'loads_htg_whf')
    @component_loads[[LT::Heating, CLT::Ducts]] = ComponentLoad.new(ems_variable: 'loads_htg_ducts')
    @component_loads[[LT::Heating, CLT::InternalGains]] = ComponentLoad.new(ems_variable: 'loads_htg_intgains')
    @component_loads[[LT::Cooling, CLT::Roofs]] = ComponentLoad.new(ems_variable: 'loads_clg_roofs')
    @component_loads[[LT::Cooling, CLT::Ceilings]] = ComponentLoad.new(ems_variable: 'loads_clg_ceilings')
    @component_loads[[LT::Cooling, CLT::Walls]] = ComponentLoad.new(ems_variable: 'loads_clg_walls')
    @component_loads[[LT::Cooling, CLT::RimJoists]] = ComponentLoad.new(ems_variable: 'loads_clg_rim_joists')
    @component_loads[[LT::Cooling, CLT::FoundationWalls]] = ComponentLoad.new(ems_variable: 'loads_clg_foundation_walls')
    @component_loads[[LT::Cooling, CLT::Doors]] = ComponentLoad.new(ems_variable: 'loads_clg_doors')
    @component_loads[[LT::Cooling, CLT::Windows]] = ComponentLoad.new(ems_variable: 'loads_clg_windows')
    @component_loads[[LT::Cooling, CLT::Skylights]] = ComponentLoad.new(ems_variable: 'loads_clg_skylights')
    @component_loads[[LT::Cooling, CLT::Floors]] = ComponentLoad.new(ems_variable: 'loads_clg_floors')
    @component_loads[[LT::Cooling, CLT::Slabs]] = ComponentLoad.new(ems_variable: 'loads_clg_slabs')
    @component_loads[[LT::Cooling, CLT::InternalMass]] = ComponentLoad.new(ems_variable: 'loads_clg_internal_mass')
    @component_loads[[LT::Cooling, CLT::Infiltration]] = ComponentLoad.new(ems_variable: 'loads_clg_infil')
    @component_loads[[LT::Cooling, CLT::NaturalVentilation]] = ComponentLoad.new(ems_variable: 'loads_clg_natvent')
    @component_loads[[LT::Cooling, CLT::MechanicalVentilation]] = ComponentLoad.new(ems_variable: 'loads_clg_mechvent')
    @component_loads[[LT::Cooling, CLT::WholeHouseFan]] = ComponentLoad.new(ems_variable: 'loads_clg_whf')
    @component_loads[[LT::Cooling, CLT::Ducts]] = ComponentLoad.new(ems_variable: 'loads_clg_ducts')
    @component_loads[[LT::Cooling, CLT::InternalGains]] = ComponentLoad.new(ems_variable: 'loads_clg_intgains')

    @component_loads.each do |key, comp_load|
      load_type, comp_load_type = key
      comp_load.name = "Component Load: #{load_type}: #{comp_load_type}"
      comp_load.annual_units = 'MBtu'
      comp_load.timeseries_units = 'kBtu'
    end

    # Unmet Loads (unexpected load that should have been met by HVAC)
    @unmet_loads = {}
    @unmet_loads[LT::Heating] = UnmetLoad.new(key: Constants.ObjectNameIdealAirSystemResidual, variable: 'Zone Ideal Loads Zone Sensible Heating Energy')
    @unmet_loads[LT::Cooling] = UnmetLoad.new(key: Constants.ObjectNameIdealAirSystemResidual, variable: 'Zone Ideal Loads Zone Sensible Cooling Energy')

    @unmet_loads.each do |load_type, unmet_load|
      unmet_load.name = "Unmet Load: #{load_type}"
      unmet_load.annual_units = 'MBtu'
    end

    # Ideal System Loads (expected load that is not met by HVAC)
    @ideal_system_loads = {}
    @ideal_system_loads[LT::Heating] = UnmetLoad.new(key: Constants.ObjectNameIdealAirSystem, variable: 'Zone Ideal Loads Zone Sensible Heating Energy')
    @ideal_system_loads[LT::Cooling] = UnmetLoad.new(key: Constants.ObjectNameIdealAirSystem, variable: 'Zone Ideal Loads Zone Sensible Cooling Energy')

    @ideal_system_loads.each do |load_type, ideal_load|
      ideal_load.name = "Ideal System Load: #{load_type}"
      ideal_load.annual_units = 'MBtu'
    end

    # Peak Loads
    @peak_loads = {}
    @peak_loads[LT::Heating] = PeakLoad.new(meter: 'Heating:EnergyTransfer')
    @peak_loads[LT::Cooling] = PeakLoad.new(meter: 'Cooling:EnergyTransfer')

    @peak_loads.each do |load_type, peak_load|
      peak_load.name = "Peak Load: #{load_type}"
      peak_load.annual_units = 'kBtu'
    end

    # Zone Temperatures

    @zone_temps = {}

    # Airflows
    @airflows = {}
    @airflows[AFT::Infiltration] = Airflow.new(ems_program: Constants.ObjectNameInfiltration + ' program', ems_variables: [(Constants.ObjectNameInfiltration + ' flow act').gsub(' ', '_')])
    @airflows[AFT::MechanicalVentilation] = Airflow.new(ems_program: Constants.ObjectNameInfiltration + ' program', ems_variables: [(Constants.ObjectNameMechanicalVentilation + ' flow act').gsub(' ', '_'), 'QWHV_ervhrv'])
    @airflows[AFT::NaturalVentilation] = Airflow.new(ems_program: Constants.ObjectNameNaturalVentilation + ' program', ems_variables: [(Constants.ObjectNameNaturalVentilation + ' flow act').gsub(' ', '_')])
    @airflows[AFT::WholeHouseFan] = Airflow.new(ems_program: Constants.ObjectNameNaturalVentilation + ' program', ems_variables: [(Constants.ObjectNameWholeHouseFan + ' flow act').gsub(' ', '_')])

    @airflows.each do |airflow_type, airflow|
      airflow.name = "Airflow: #{airflow_type}"
      airflow.timeseries_units = 'cfm'
    end

    # Weather
    @weather = {}
    @weather[WT::DrybulbTemp] = Weather.new(variable: 'Site Outdoor Air Drybulb Temperature', variable_units: 'C', timeseries_units: 'F')
    @weather[WT::WetbulbTemp] = Weather.new(variable: 'Site Outdoor Air Wetbulb Temperature', variable_units: 'C', timeseries_units: 'F')
    @weather[WT::RelativeHumidity] = Weather.new(variable: 'Site Outdoor Air Relative Humidity', variable_units: '%', timeseries_units: '%')
    @weather[WT::WindSpeed] = Weather.new(variable: 'Site Wind Speed', variable_units: 'm/s', timeseries_units: 'mph')
    @weather[WT::DiffuseSolar] = Weather.new(variable: 'Site Diffuse Solar Radiation Rate per Area', variable_units: 'W/m^2', timeseries_units: 'Btu/(hr*ft^2)')
    @weather[WT::DirectSolar] = Weather.new(variable: 'Site Direct Solar Radiation Rate per Area', variable_units: 'W/m^2', timeseries_units: 'Btu/(hr*ft^2)')

    @weather.each do |weather_type, weather_data|
      weather_data.name = "Weather: #{weather_type}"
    end
  end

  def reporting_frequency_map
    return {
      'timestep' => 'Zone Timestep',
      'hourly' => 'Hourly',
      'daily' => 'Daily',
      'monthly' => 'Monthly',
    }
  end

  class OutputVars
    def self.SpaceHeatingElectricity
      return { 'OpenStudio::Model::AirLoopHVACUnitarySystem' => ['Unitary System Heating Ancillary Electric Energy'],
               'OpenStudio::Model::CoilHeatingDXSingleSpeed' => ['Heating Coil Electric Energy', 'Heating Coil Crankcase Heater Electric Energy', 'Heating Coil Defrost Electric Energy'],
               'OpenStudio::Model::CoilHeatingDXMultiSpeed' => ['Heating Coil Electric Energy', 'Heating Coil Crankcase Heater Electric Energy', 'Heating Coil Defrost Electric Energy'],
               'OpenStudio::Model::CoilHeatingElectric' => ['Heating Coil Electric Energy', 'Heating Coil Crankcase Heater Electric Energy', 'Heating Coil Defrost Electric Energy'],
               'OpenStudio::Model::CoilHeatingWaterToAirHeatPumpEquationFit' => ['Heating Coil Electric Energy', 'Heating Coil Crankcase Heater Electric Energy', 'Heating Coil Defrost Electric Energy'],
               'OpenStudio::Model::ZoneHVACBaseboardConvectiveElectric' => ['Baseboard Electric Energy'],
               'OpenStudio::Model::BoilerHotWater' => ['Boiler Electric Energy'] }
    end

    def self.SpaceHeatingFuel(fuel)
      fuel = EPlus.output_fuel_map(fuel)
      return { 'OpenStudio::Model::CoilHeatingGas' => ["Heating Coil #{fuel} Energy"],
               'OpenStudio::Model::ZoneHVACBaseboardConvectiveElectric' => ["Baseboard #{fuel} Energy"],
               'OpenStudio::Model::BoilerHotWater' => ["Boiler #{fuel} Energy"] }
    end

    def self.SpaceHeatingDFHPPrimaryLoad
      return { 'OpenStudio::Model::CoilHeatingDXSingleSpeed' => ['Heating Coil Heating Energy'],
               'OpenStudio::Model::CoilHeatingDXMultiSpeed' => ['Heating Coil Heating Energy'] }
    end

    def self.SpaceHeatingDFHPBackupLoad
      return { 'OpenStudio::Model::CoilHeatingElectric' => ['Heating Coil Heating Energy'],
               'OpenStudio::Model::CoilHeatingGas' => ['Heating Coil Heating Energy'] }
    end

    def self.SpaceCoolingElectricity
      return { 'OpenStudio::Model::CoilCoolingDXSingleSpeed' => ['Cooling Coil Electric Energy', 'Cooling Coil Crankcase Heater Electric Energy'],
               'OpenStudio::Model::CoilCoolingDXMultiSpeed' => ['Cooling Coil Electric Energy', 'Cooling Coil Crankcase Heater Electric Energy'],
               'OpenStudio::Model::CoilCoolingWaterToAirHeatPumpEquationFit' => ['Cooling Coil Electric Energy', 'Cooling Coil Crankcase Heater Electric Energy'],
               'OpenStudio::Model::EvaporativeCoolerDirectResearchSpecial' => ['Evaporative Cooler Electric Energy'] }
    end

    def self.DehumidifierElectricity
      return { 'OpenStudio::Model::ZoneHVACDehumidifierDX' => ['Zone Dehumidifier Electric Energy'] }
    end

    def self.WaterHeatingElectricity
      return { 'OpenStudio::Model::WaterHeaterMixed' => ['Water Heater Electric Energy', 'Water Heater Off Cycle Parasitic Electric Energy', 'Water Heater On Cycle Parasitic Electric Energy'],
               'OpenStudio::Model::WaterHeaterStratified' => ['Water Heater Electric Energy', 'Water Heater Off Cycle Parasitic Electric Energy', 'Water Heater On Cycle Parasitic Electric Energy'],
               'OpenStudio::Model::CoilWaterHeatingAirToWaterHeatPumpWrapped' => ['Cooling Coil Water Heating Electric Energy'] }
    end

    def self.WaterHeatingElectricitySolarThermalPump
      return { 'OpenStudio::Model::PumpConstantSpeed' => ['Pump Electric Energy'] }
    end

    def self.WaterHeatingElectricityRecircPump
      return { 'OpenStudio::Model::ElectricEquipment' => ['Electric Equipment Electric Energy'] }
    end

    def self.WaterHeatingFuel(fuel)
      fuel = EPlus.output_fuel_map(fuel)
      return { 'OpenStudio::Model::WaterHeaterMixed' => ["Water Heater #{fuel} Energy"],
               'OpenStudio::Model::WaterHeaterStratified' => ["Water Heater #{fuel} Energy"] }
    end

    def self.WaterHeatingLoad
      return { 'OpenStudio::Model::WaterUseConnections' => ['Water Use Connections Plant Hot Water Energy'] }
    end

    def self.WaterHeatingLoadTankLosses
      return { 'OpenStudio::Model::WaterHeaterMixed' => ['Water Heater Heat Loss Energy'],
               'OpenStudio::Model::WaterHeaterStratified' => ['Water Heater Heat Loss Energy'] }
    end

    def self.WaterHeaterLoadDesuperheater
      return { 'OpenStudio::Model::CoilWaterHeatingDesuperheater' => ['Water Heater Heating Energy'] }
    end

    def self.WaterHeaterLoadSolarThermal
      return { 'OpenStudio::Model::WaterHeaterStratified' => ['Water Heater Use Side Heat Transfer Energy'] }
    end
  end
end

# register the measure to be used by the application
SimulationOutputReport.new.registerWithApplication
