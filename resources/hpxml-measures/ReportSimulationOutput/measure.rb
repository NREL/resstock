# frozen_string_literal: true

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require_relative 'resources/constants.rb'
require_relative '../HPXMLtoOpenStudio/resources/constants.rb'
require_relative '../HPXMLtoOpenStudio/resources/energyplus.rb'
require_relative '../HPXMLtoOpenStudio/resources/hpxml.rb'
require_relative '../HPXMLtoOpenStudio/resources/unit_conversions.rb'

# start the measure
class ReportSimulationOutput < OpenStudio::Measure::ReportingMeasure
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
    return 'Processes EnergyPlus simulation outputs in order to generate an annual output file and an optional timeseries output file.'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    format_chs = OpenStudio::StringVector.new
    format_chs << 'csv'
    format_chs << 'json'
    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('output_format', format_chs, false)
    arg.setDisplayName('Output Format')
    arg.setDescription('The file format of the annual (and timeseries, if requested) outputs.')
    arg.setDefaultValue('csv')
    args << arg

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

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('include_timeseries_emissions', true)
    arg.setDisplayName('Generate Timeseries Output: Emissions')
    arg.setDescription('Generates timeseries emissions. Requires the appropriate HPXML inputs to be specified.')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('include_timeseries_hot_water_uses', true)
    arg.setDisplayName('Generate Timeseries Output: Hot Water Uses')
    arg.setDescription('Generates timeseries hot water usages for each end use.')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('include_timeseries_total_loads', true)
    arg.setDisplayName('Generate Timeseries Output: Total Loads')
    arg.setDescription('Generates timeseries total heating, cooling, and hot water loads.')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('include_timeseries_component_loads', true)
    arg.setDisplayName('Generate Timeseries Output: Component Loads')
    arg.setDescription('Generates timeseries heating and cooling loads disaggregated by component type.')
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

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('add_timeseries_dst_column', false)
    arg.setDisplayName('Generate Timeseries Output: Add TimeDST Column')
    arg.setDescription('Optionally add, in addition to the default local standard Time column, a local clock TimeDST column. Requires that daylight saving time is enabled.')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('add_timeseries_utc_column', false)
    arg.setDisplayName('Generate Timeseries Output: Add TimeUTC Column')
    arg.setDescription('Optionally add, in addition to the default local standard Time column, a local clock TimeUTC column. If the time zone UTC offset is not provided in the HPXML file, the time zone in the EPW header will be used.')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument('annual_output_file_name', false)
    arg.setDisplayName('Annual Output File Name')
    arg.setDescription("If not provided, defaults to 'results_annual.csv' (or 'results_annual.json').")
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument('timeseries_output_file_name', false)
    arg.setDisplayName('Timeseries Output File Name')
    arg.setDescription("If not provided, defaults to 'results_timeseries.csv' (or 'results_timeseries.json').")
    args << arg

    return args
  end

  # define the outputs that the measure will create
  def outputs
    outs = OpenStudio::Measure::OSOutputVector.new

    setup_outputs()

    all_outputs = []
    all_outputs << @fuels
    all_outputs << @end_uses
    all_outputs << @loads
    all_outputs << @unmet_hours
    all_outputs << @peak_fuels
    all_outputs << @peak_loads
    all_outputs << @component_loads
    all_outputs << @hot_water_uses

    output_names = []
    all_outputs.each do |outputs|
      outputs.each do |key, obj|
        output_names << get_runner_output_name(obj)
      end
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
    return result if runner.halted

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

    setup_outputs()

    total_loads_program = @model.getModelObjectByName(Constants.ObjectNameTotalLoadsProgram.gsub(' ', '_')).get.to_EnergyManagementSystemProgram.get
    comp_loads_program = @model.getModelObjectByName(Constants.ObjectNameComponentLoadsProgram.gsub(' ', '_'))
    if comp_loads_program.is_initialized
      comp_loads_program = comp_loads_program.get.to_EnergyManagementSystemProgram.get
    else
      comp_loads_program = nil
    end

    timeseries_frequency = runner.getStringArgumentValue('timeseries_frequency', user_arguments)
    if timeseries_frequency != 'none'
      include_timeseries_fuel_consumptions = runner.getBoolArgumentValue('include_timeseries_fuel_consumptions', user_arguments)
      include_timeseries_end_use_consumptions = runner.getBoolArgumentValue('include_timeseries_end_use_consumptions', user_arguments)
      include_timeseries_emissions = runner.getBoolArgumentValue('include_timeseries_emissions', user_arguments)
      include_timeseries_hot_water_uses = runner.getBoolArgumentValue('include_timeseries_hot_water_uses', user_arguments)
      include_timeseries_total_loads = runner.getBoolArgumentValue('include_timeseries_total_loads', user_arguments)
      include_timeseries_component_loads = runner.getBoolArgumentValue('include_timeseries_component_loads', user_arguments)
      include_timeseries_zone_temperatures = runner.getBoolArgumentValue('include_timeseries_zone_temperatures', user_arguments)
      include_timeseries_airflows = runner.getBoolArgumentValue('include_timeseries_airflows', user_arguments)
      include_timeseries_weather = runner.getBoolArgumentValue('include_timeseries_weather', user_arguments)
    end

    # To calculate timeseries emissions or timeseries fuel consumption, we also need to select timeseries
    # end use consumption because EnergyPlus results may be post-processed due to HVAC DSE.
    # TODO: This could be removed if we could account for DSE inside EnergyPlus.
    if not @emissions.empty?
      include_hourly_electric_end_use_consumptions = true # Need hourly electricity values for Cambium
      if include_timeseries_emissions
        include_timeseries_fuel_consumptions = true
      end
    end
    if include_timeseries_fuel_consumptions
      include_timeseries_end_use_consumptions = true
    end

    has_electricity_production = false
    if @end_uses.select { |key, end_use| end_use.is_negative && end_use.variables.size > 0 }.size > 0
      has_electricity_production = true
    end

    # Fuel outputs
    @fuels.each do |fuel_type, fuel|
      fuel.meters.each do |meter|
        result << OpenStudio::IdfObject.load("Output:Meter,#{meter},runperiod;").get
        if include_timeseries_fuel_consumptions
          result << OpenStudio::IdfObject.load("Output:Meter,#{meter},#{timeseries_frequency};").get
        end
      end
    end
    if has_electricity_production
      result << OpenStudio::IdfObject.load('Output:Meter,ElectricityProduced:Facility,runperiod;').get # Used for error checking
      if include_timeseries_fuel_consumptions
        result << OpenStudio::IdfObject.load("Output:Meter,ElectricityProduced:Facility,#{timeseries_frequency};").get
      end
    end

    # End Use/Hot Water Use/Ideal Load outputs
    { @end_uses => include_timeseries_end_use_consumptions,
      @hot_water_uses => include_timeseries_hot_water_uses,
      @ideal_system_loads => false }.each do |uses, include_timeseries|
      uses.each do |key, use|
        use.variables.each do |sys_id, varkey, var|
          result << OpenStudio::IdfObject.load("Output:Variable,#{varkey},#{var},runperiod;").get
          if include_timeseries
            result << OpenStudio::IdfObject.load("Output:Variable,#{varkey},#{var},#{timeseries_frequency};").get
          end
          next unless use.is_a?(EndUse)

          fuel_type, end_use = key
          if fuel_type == FT::Elec && include_hourly_electric_end_use_consumptions
            result << OpenStudio::IdfObject.load("Output:Variable,#{varkey},#{var},hourly;").get
          end
        end
      end
    end

    # Peak Fuel outputs (annual only)
    @peak_fuels.values.each do |peak_fuel|
      peak_fuel.meters.each do |meter|
        result << OpenStudio::IdfObject.load("Output:Table:Monthly,#{peak_fuel.report},2,#{meter},HoursPositive,Electricity:Facility,MaximumDuringHoursShown;").get
      end
    end

    # Peak Load outputs (annual only)
    @peak_loads.values.each do |peak_load|
      result << OpenStudio::IdfObject.load("EnergyManagementSystem:OutputVariable,#{peak_load.ems_variable}_peakload_outvar,#{peak_load.ems_variable},Summed,ZoneTimestep,#{total_loads_program.name},J;").get
      result << OpenStudio::IdfObject.load("Output:Table:Monthly,#{peak_load.report},2,#{peak_load.ems_variable}_peakload_outvar,Maximum;").get
    end

    # Component Load outputs
    @component_loads.values.each do |comp_load|
      next if comp_loads_program.nil?

      result << OpenStudio::IdfObject.load("EnergyManagementSystem:OutputVariable,#{comp_load.ems_variable}_annual_outvar,#{comp_load.ems_variable},Summed,ZoneTimestep,#{comp_loads_program.name},J;").get
      result << OpenStudio::IdfObject.load("Output:Variable,*,#{comp_load.ems_variable}_annual_outvar,runperiod;").get
      if include_timeseries_component_loads
        result << OpenStudio::IdfObject.load("EnergyManagementSystem:OutputVariable,#{comp_load.ems_variable}_timeseries_outvar,#{comp_load.ems_variable},Summed,ZoneTimestep,#{comp_loads_program.name},J;").get
        result << OpenStudio::IdfObject.load("Output:Variable,*,#{comp_load.ems_variable}_timeseries_outvar,#{timeseries_frequency};").get
      end
    end

    # Total Load outputs
    @loads.values.each do |load|
      if not load.ems_variable.nil?
        result << OpenStudio::IdfObject.load("EnergyManagementSystem:OutputVariable,#{load.ems_variable}_annual_outvar,#{load.ems_variable},Summed,ZoneTimestep,#{total_loads_program.name},J;").get
        result << OpenStudio::IdfObject.load("Output:Variable,*,#{load.ems_variable}_annual_outvar,runperiod;").get
        if include_timeseries_total_loads
          result << OpenStudio::IdfObject.load("EnergyManagementSystem:OutputVariable,#{load.ems_variable}_timeseries_outvar,#{load.ems_variable},Summed,ZoneTimestep,#{total_loads_program.name},J;").get
          result << OpenStudio::IdfObject.load("Output:Variable,*,#{load.ems_variable}_timeseries_outvar,#{timeseries_frequency};").get
        end
      end
      load.variables.each do |sys_id, varkey, var|
        result << OpenStudio::IdfObject.load("Output:Variable,#{varkey},#{var},runperiod;").get
        if include_timeseries_total_loads
          result << OpenStudio::IdfObject.load("Output:Variable,#{varkey},#{var},#{timeseries_frequency};").get
        end
      end
    end

    # Temperature outputs (timeseries only)
    if include_timeseries_zone_temperatures
      result << OpenStudio::IdfObject.load("Output:Variable,*,Zone Mean Air Temperature,#{timeseries_frequency};").get
      # For reporting temperature-scheduled spaces timeseries temperatures.
      keys = [HPXML::LocationOtherHeatedSpace,
              HPXML::LocationOtherMultifamilyBufferSpace,
              HPXML::LocationOtherNonFreezingSpace,
              HPXML::LocationOtherHousingUnit,
              HPXML::LocationExteriorWall,
              HPXML::LocationUnderSlab]
      keys.each do |key|
        next if @model.getScheduleConstants.select { |o| o.name.to_s == key }.size == 0

        result << OpenStudio::IdfObject.load("Output:Variable,#{key},Schedule Value,#{timeseries_frequency};").get
      end
    end

    # Airflow outputs (timeseries only)
    if include_timeseries_airflows
      @airflows.values.each do |airflow|
        ems_program = @model.getModelObjectByName(airflow.ems_program.gsub(' ', '_')).get.to_EnergyManagementSystemProgram.get
        airflow.ems_variables.each do |ems_variable|
          result << OpenStudio::IdfObject.load("EnergyManagementSystem:OutputVariable,#{ems_variable}_timeseries_outvar,#{ems_variable},Averaged,ZoneTimestep,#{ems_program.name},m^3/s;").get
          result << OpenStudio::IdfObject.load("Output:Variable,*,#{ems_variable}_timeseries_outvar,#{timeseries_frequency};").get
        end
      end
    end

    # Weather outputs (timeseries only)
    if include_timeseries_weather
      @weather.values.each do |weather_data|
        result << OpenStudio::IdfObject.load("Output:Variable,*,#{weather_data.variable},#{timeseries_frequency};").get
      end
    end

    # Dual-fuel heat pump loads
    if not @object_variables_by_key[[LT, LT::Heating]].nil?
      @object_variables_by_key[[LT, LT::Heating]].each do |vals|
        sys_id, key, var = vals
        result << OpenStudio::IdfObject.load("Output:Variable,#{key},#{var},runperiod;").get
      end
    end

    return result.uniq
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

    output_format = runner.getStringArgumentValue('output_format', user_arguments)
    timeseries_frequency = runner.getStringArgumentValue('timeseries_frequency', user_arguments)
    if timeseries_frequency != 'none'
      include_timeseries_fuel_consumptions = runner.getBoolArgumentValue('include_timeseries_fuel_consumptions', user_arguments)
      include_timeseries_end_use_consumptions = runner.getBoolArgumentValue('include_timeseries_end_use_consumptions', user_arguments)
      include_timeseries_emissions = runner.getBoolArgumentValue('include_timeseries_emissions', user_arguments)
      include_timeseries_hot_water_uses = runner.getBoolArgumentValue('include_timeseries_hot_water_uses', user_arguments)
      include_timeseries_total_loads = runner.getBoolArgumentValue('include_timeseries_total_loads', user_arguments)
      include_timeseries_component_loads = runner.getBoolArgumentValue('include_timeseries_component_loads', user_arguments)
      include_timeseries_zone_temperatures = runner.getBoolArgumentValue('include_timeseries_zone_temperatures', user_arguments)
      include_timeseries_airflows = runner.getBoolArgumentValue('include_timeseries_airflows', user_arguments)
      include_timeseries_weather = runner.getBoolArgumentValue('include_timeseries_weather', user_arguments)
      add_timeseries_dst_column = runner.getOptionalBoolArgumentValue('add_timeseries_dst_column', user_arguments)
      add_timeseries_utc_column = runner.getOptionalBoolArgumentValue('add_timeseries_utc_column', user_arguments)
    end
    annual_output_file_name = runner.getOptionalStringArgumentValue('annual_output_file_name', user_arguments)
    timeseries_output_file_name = runner.getOptionalStringArgumentValue('timeseries_output_file_name', user_arguments)

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
    hpxml_defaults_path = @model.getBuilding.additionalProperties.getFeatureAsString('hpxml_defaults_path').get
    building_id = @model.getBuilding.additionalProperties.getFeatureAsString('building_id').get
    @hpxml = HPXML.new(hpxml_path: hpxml_defaults_path, building_id: building_id)
    HVAC.apply_shared_systems(@hpxml) # Needed for ERI shared HVAC systems
    @eri_design = @hpxml.header.eri_design

    setup_outputs()

    # Set paths
    if not @eri_design.nil?
      # ERI run, store files in a particular location
      output_dir = File.dirname(hpxml_path)
      hpxml_name = File.basename(hpxml_path).gsub('.xml', '')
      annual_output_path = File.join(output_dir, "#{hpxml_name}.#{output_format}")
      timeseries_output_path = File.join(output_dir, "#{hpxml_name}_#{timeseries_frequency.capitalize}.#{output_format}")
      eri_output_path = File.join(output_dir, "#{hpxml_name}_ERI.csv")
    else
      output_dir = File.dirname(@sqlFile.path.to_s)
      if annual_output_file_name.is_initialized
        annual_output_path = File.join(output_dir, annual_output_file_name.get)
      else
        annual_output_path = File.join(output_dir, "results_annual.#{output_format}")
      end
      if timeseries_output_file_name.is_initialized
        timeseries_output_path = File.join(output_dir, timeseries_output_file_name.get)
      else
        timeseries_output_path = File.join(output_dir, "results_timeseries.#{output_format}")
      end
      eri_output_path = nil
    end

    @timestamps = get_timestamps(timeseries_frequency)
    if timeseries_frequency != 'none'
      if add_timeseries_dst_column.is_initialized
        timestamps_dst = get_timestamps(timeseries_frequency, 'DST') if add_timeseries_dst_column.get
      end
      if add_timeseries_utc_column.is_initialized
        timestamps_utc = get_timestamps(timeseries_frequency, 'UTC') if add_timeseries_utc_column.get
      end
    end

    # Retrieve outputs
    outputs = get_outputs(runner, timeseries_frequency,
                          include_timeseries_fuel_consumptions,
                          include_timeseries_end_use_consumptions,
                          include_timeseries_emissions,
                          include_timeseries_hot_water_uses,
                          include_timeseries_total_loads,
                          include_timeseries_component_loads,
                          include_timeseries_zone_temperatures,
                          include_timeseries_airflows,
                          include_timeseries_weather)

    if not check_for_errors(runner, outputs)
      teardown()
      return false
    end

    # Write/report results
    write_annual_output_results(runner, outputs, output_format, annual_output_path)
    report_sim_outputs(runner)
    write_eri_output_results(outputs, eri_output_path)
    write_timeseries_output_results(runner, outputs, output_format,
                                    timeseries_output_path,
                                    timeseries_frequency,
                                    include_timeseries_fuel_consumptions,
                                    include_timeseries_end_use_consumptions,
                                    include_timeseries_emissions,
                                    include_timeseries_hot_water_uses,
                                    include_timeseries_total_loads,
                                    include_timeseries_component_loads,
                                    include_timeseries_zone_temperatures,
                                    include_timeseries_airflows,
                                    include_timeseries_weather,
                                    timestamps_dst,
                                    timestamps_utc)

    teardown()
    return true
  end

  def teardown
    @sqlFile.close()

    # Ensure sql file is immediately freed; otherwise we can get
    # errors on Windows when trying to delete this file.
    GC.start()
  end

  def get_timestamps(timeseries_frequency, timestamps_local_time = nil)
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

    if timestamps_local_time == 'DST'
      dst_start_ts = Time.utc(@hpxml.header.sim_calendar_year, @hpxml.header.dst_begin_month, @hpxml.header.dst_begin_day, 2)
      dst_end_ts = Time.utc(@hpxml.header.sim_calendar_year, @hpxml.header.dst_end_month, @hpxml.header.dst_end_day, 1)
    elsif timestamps_local_time == 'UTC'
      utc_offset = @hpxml.header.time_zone_utc_offset
      utc_offset *= 3600 # seconds
    end

    timestamps = []
    values.get.each do |value|
      year, month, day, hour, minute = value.split(' ')
      ts = Time.utc(year, month, day, hour, minute)

      if timestamps_local_time == 'DST'
        if (ts >= dst_start_ts) && (ts < dst_end_ts)
          ts += 3600 # 1 hr shift forward
        end
      elsif timestamps_local_time == 'UTC'
        ts -= utc_offset
      end

      ts_iso8601 = ts.iso8601
      ts_iso8601 = ts_iso8601.delete('Z') if timestamps_local_time != 'UTC'
      timestamps << ts_iso8601
    end

    return timestamps
  end

  def get_outputs(runner, timeseries_frequency,
                  include_timeseries_fuel_consumptions,
                  include_timeseries_end_use_consumptions,
                  include_timeseries_emissions,
                  include_timeseries_hot_water_uses,
                  include_timeseries_total_loads,
                  include_timeseries_component_loads,
                  include_timeseries_zone_temperatures,
                  include_timeseries_airflows,
                  include_timeseries_weather)
    outputs = {}

    # To calculate timeseries emissions or timeseries fuel consumption, we also need to select timeseries
    # end use consumption because EnergyPlus results may be post-processed due to, e.g., HVAC DSE.
    # TODO: This could be removed if we could account for DSE inside EnergyPlus.
    if not @emissions.empty?
      include_hourly_electric_end_use_consumptions = true # For annual Cambium calculation
      if include_timeseries_emissions
        include_timeseries_fuel_consumptions = true
      end
    end
    if include_timeseries_fuel_consumptions
      include_timeseries_end_use_consumptions = true
    end

    # Fuel Uses
    @fuels.each do |fuel_type, fuel|
      fuel.annual_output = get_report_meter_data_annual(fuel.meters)
      if include_timeseries_fuel_consumptions
        fuel.timeseries_output = get_report_meter_data_timeseries(fuel.meters, UnitConversions.convert(1.0, 'J', fuel.timeseries_units), 0, timeseries_frequency)
      end
    end

    # Peak Electricity Consumption
    @peak_fuels.each do |key, peak_fuel|
      peak_fuel.annual_output = get_tabular_data_value(peak_fuel.report.upcase, 'Meter', 'Custom Monthly Report', ['Maximum of Months'], 'ELECTRICITY:FACILITY {MAX FOR HOURS SHOWN}', peak_fuel.annual_units)
    end

    # Total loads
    @loads.each do |load_type, load|
      if not load.ems_variable.nil?
        # Obtain from EMS output variable
        load.annual_output = get_report_variable_data_annual(['EMS'], ["#{load.ems_variable}_annual_outvar"])
        if include_timeseries_total_loads
          load.timeseries_output = get_report_variable_data_timeseries(['EMS'], ["#{load.ems_variable}_timeseries_outvar"], UnitConversions.convert(1.0, 'J', load.timeseries_units), 0, timeseries_frequency)
        end
      elsif load.variables.size > 0
        # Obtain from output variable
        load.variables.map { |v| v[0] }.each do |sys_id|
          keys = load.variables.select { |v| v[0] == sys_id }.map { |v| v[1] }
          vars = load.variables.select { |v| v[0] == sys_id }.map { |v| v[2] }

          load.annual_output_by_system[sys_id] = get_report_variable_data_annual(keys, vars, is_negative: load.is_negative)
          if include_timeseries_total_loads && (load_type == LT::HotWaterDelivered)
            load.timeseries_output_by_system[sys_id] = get_report_variable_data_timeseries(keys, vars, UnitConversions.convert(1.0, 'J', load.timeseries_units), 0, timeseries_frequency, is_negative: load.is_negative)
          end
        end
      end
    end

    # Component Loads
    @component_loads.each do |key, comp_load|
      comp_load.annual_output = get_report_variable_data_annual(['EMS'], ["#{comp_load.ems_variable}_annual_outvar"])
      if include_timeseries_component_loads
        comp_load.timeseries_output = get_report_variable_data_timeseries(['EMS'], ["#{comp_load.ems_variable}_timeseries_outvar"], UnitConversions.convert(1.0, 'J', comp_load.timeseries_units), 0, timeseries_frequency)
      end
    end

    # Unmet Hours
    @unmet_hours.each do |key, unmet_hour|
      if (key == UHT::Heating && @hpxml.total_fraction_heat_load_served <= 0) ||
         (key == UHT::Cooling && @hpxml.total_fraction_cool_load_served <= 0)
        next # Don't report unmet hours if there is no heating/cooling system
      end

      unmet_hour.annual_output = get_tabular_data_value('SystemSummary', 'Entire Facility', 'Time Setpoint Not Met', [HPXML::LocationLivingSpace.upcase], unmet_hour.col_name, unmet_hour.annual_units)
    end

    # Ideal system loads (expected fraction of loads that are not met by partial HVAC (e.g., room AC that meets 30% of load))
    @ideal_system_loads.each do |load_type, ideal_load|
      ideal_load.variables.map { |v| v[0] }.each do |sys_id|
        keys = ideal_load.variables.select { |v| v[0] == sys_id }.map { |v| v[1] }
        vars = ideal_load.variables.select { |v| v[0] == sys_id }.map { |v| v[2] }

        ideal_load.annual_output = get_report_variable_data_annual(keys, vars)
      end
    end

    # Peak Building Space Heating/Cooling Loads (total heating/cooling energy delivered including backup ideal air system)
    @peak_loads.each do |load_type, peak_load|
      peak_load.annual_output = UnitConversions.convert(get_tabular_data_value(peak_load.report.upcase, 'EMS', 'Custom Monthly Report', ['Maximum of Months'], "#{peak_load.ems_variable.upcase}_PEAKLOAD_OUTVAR {Maximum}", 'W'), 'Wh', peak_load.annual_units)
    end

    # End Uses
    @end_uses.each do |key, end_use|
      fuel_type, end_use_type = key

      end_use.variables.map { |v| v[0] }.each do |sys_id|
        keys = end_use.variables.select { |v| v[0] == sys_id }.map { |v| v[1] }
        vars = end_use.variables.select { |v| v[0] == sys_id }.map { |v| v[2] }

        end_use.annual_output_by_system[sys_id] = get_report_variable_data_annual(keys, vars, is_negative: end_use.is_negative)
        if include_timeseries_end_use_consumptions
          end_use.timeseries_output_by_system[sys_id] = get_report_variable_data_timeseries(keys, vars, UnitConversions.convert(1.0, 'J', end_use.timeseries_units), 0, timeseries_frequency, is_negative: end_use.is_negative)
        end
        if include_hourly_electric_end_use_consumptions && fuel_type == FT::Elec
          end_use.hourly_output_by_system[sys_id] = get_report_variable_data_timeseries(keys, vars, UnitConversions.convert(1.0, 'J', end_use.timeseries_units), 0, 'hourly', is_negative: end_use.is_negative)
        end
      end
    end

    # Hot Water Uses
    @hot_water_uses.each do |hot_water_type, hot_water|
      hot_water.variables.map { |v| v[0] }.each do |sys_id|
        keys = hot_water.variables.select { |v| v[0] == sys_id }.map { |v| v[1] }
        vars = hot_water.variables.select { |v| v[0] == sys_id }.map { |v| v[2] }

        hot_water.annual_output_by_system[sys_id] = get_report_variable_data_annual(keys, vars, UnitConversions.convert(1.0, 'm^3', hot_water.annual_units))
        if include_timeseries_hot_water_uses
          hot_water.timeseries_output_by_system[sys_id] = get_report_variable_data_timeseries(keys, vars, UnitConversions.convert(1.0, 'm^3', hot_water.timeseries_units), 0, timeseries_frequency)
        end
      end
    end

    # Apply Heating/Cooling DSEs
    (@hpxml.heating_systems + @hpxml.heat_pumps).each do |htg_system|
      next unless (htg_system.is_a?(HPXML::HeatingSystem) && htg_system.is_heat_pump_backup_system) || htg_system.fraction_heat_load_served > 0
      next if htg_system.distribution_system_idref.nil?
      next unless htg_system.distribution_system.distribution_system_type == HPXML::HVACDistributionTypeDSE
      next if htg_system.distribution_system.annual_heating_dse.nil?

      dse = htg_system.distribution_system.annual_heating_dse
      @fuels.each do |fuel_type, fuel|
        [EUT::Heating, EUT::HeatingFanPump].each do |end_use_type|
          end_use = @end_uses[[fuel_type, end_use_type]]
          next if end_use.nil?

          if not end_use.annual_output_by_system[htg_system.id].nil?
            apply_multiplier_to_output(end_use, fuel, htg_system.id, 1.0 / dse)
          end
          if not end_use.annual_output_by_system[htg_system.id + '_DFHPBackup'].nil?
            apply_multiplier_to_output(end_use, fuel, htg_system.id + '_DFHPBackup', 1.0 / dse)
          end
        end
      end
    end
    (@hpxml.cooling_systems + @hpxml.heat_pumps).each do |clg_system|
      next unless clg_system.fraction_cool_load_served > 0
      next if clg_system.distribution_system_idref.nil?
      next unless clg_system.distribution_system.distribution_system_type == HPXML::HVACDistributionTypeDSE
      next if clg_system.distribution_system.annual_cooling_dse.nil?

      dse = clg_system.distribution_system.annual_cooling_dse
      @fuels.each do |fuel_type, fuel|
        [EUT::Cooling, EUT::CoolingFanPump].each do |end_use_type|
          end_use = @end_uses[[fuel_type, end_use_type]]
          next if end_use.nil?
          next if end_use.annual_output_by_system[clg_system.id].nil?

          apply_multiplier_to_output(end_use, fuel, clg_system.id, 1.0 / dse)
        end
      end
    end

    # Apply solar fraction to load for simple solar water heating systems
    @hpxml.solar_thermal_systems.each do |solar_system|
      next if solar_system.solar_fraction.nil?

      @loads[LT::HotWaterSolarThermal].annual_output = 0.0 if @loads[LT::HotWaterSolarThermal].annual_output.nil?
      @loads[LT::HotWaterSolarThermal].timeseries_output = [0.0] * @timestamps.size if @loads[LT::HotWaterSolarThermal].timeseries_output.nil?

      if not solar_system.water_heating_system.nil?
        dhw_ids = [solar_system.water_heating_system.id]
      else # Apply to all water heating systems
        dhw_ids = @hpxml.water_heating_systems.map { |dhw| dhw.id }
      end
      dhw_ids.each do |dhw_id|
        apply_multiplier_to_output(@loads[LT::HotWaterDelivered], @loads[LT::HotWaterSolarThermal], dhw_id, 1.0 / (1.0 - solar_system.solar_fraction))
      end
    end

    # Calculate aggregated values from per-system values as needed
    (@end_uses.values + @loads.values + @hot_water_uses.values).each do |obj|
      # Annual
      if obj.annual_output.nil?
        if not obj.annual_output_by_system.empty?
          obj.annual_output = obj.annual_output_by_system.values.sum(0.0)
        else
          obj.annual_output = 0.0
        end
      end

      # Timeseries
      if obj.timeseries_output.empty? && (not obj.timeseries_output_by_system.empty?)
        obj.timeseries_output = obj.timeseries_output_by_system.values[0]
        obj.timeseries_output_by_system.values[1..-1].each do |values|
          obj.timeseries_output = obj.timeseries_output.zip(values).map { |x, y| x + y }
        end
      end

      # Hourly Electricity (for Cambium)
      next unless obj.is_a?(EndUse) && obj.hourly_output.empty? && (not obj.hourly_output_by_system.empty?)

      obj.hourly_output = obj.hourly_output_by_system.values[0]
      obj.hourly_output_by_system.values[1..-1].each do |values|
        obj.hourly_output = obj.hourly_output.zip(values).map { |x, y| x + y }
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
        airflow.timeseries_output = get_report_variable_data_timeseries(['EMS'], airflow.ems_variables.map { |var| "#{var}_timeseries_outvar" }, UnitConversions.convert(1.0, 'm^3/s', 'cfm'), 0, timeseries_frequency, true)
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

    # Electricity Produced
    outputs[:total_elec_produced] = get_report_meter_data_annual(['ElectricityProduced:Facility'])
    outputs[:total_elec_produced_timeseries] = get_report_meter_data_timeseries(['ElectricityProduced:Facility'], UnitConversions.convert(1.0, 'J', get_timeseries_units_from_fuel_type(FT::Elec)), 0, timeseries_frequency)
    outputs[:total_elec_net_timeseries] = @fuels[FT::Elec].timeseries_output.zip(outputs[:total_elec_produced_timeseries]).map { |c, p| c - p }

    # Emissions
    if not @emissions.empty?
      kwh_to_mwh = UnitConversions.convert(1.0, 'kWh', 'MWh')

      hourly_elec_net = nil
      @end_uses.each do |key, end_use|
        next unless end_use.hourly_output.size > 0

        hourly_elec_net = [0.0] * end_use.hourly_output.size if hourly_elec_net.nil?
        hourly_elec_net = hourly_elec_net.zip(end_use.hourly_output).map { |x, y| x + y * kwh_to_mwh }
      end
      if include_timeseries_emissions
        if timeseries_frequency == 'timestep'
          timeseries_elec_net = outputs[:total_elec_net_timeseries].map { |x| x * kwh_to_mwh }
        else
          # Need to perform calculations hourly at a minimum
          timeseries_elec_net = hourly_elec_net.dup
        end
      end

      # Calculate for each scenario
      @hpxml.header.emissions_scenarios.each do |scenario|
        key = [scenario.emissions_type, scenario.name]
        if not scenario.elec_schedule_filepath.nil?
          # Obtain Cambium hourly factors for the simulation run period
          hourly_elec_factors = File.readlines(scenario.elec_schedule_filepath).map(&:strip).map { |x| Float(x) }
        elsif not scenario.elec_value.nil?
          # Use annual value for all hours
          hourly_elec_factors = [scenario.elec_value] * 8760
        end
        year = 1999 # Try non-leap year for calculations
        sim_start_day_of_year, sim_end_day_of_year, sim_start_hour, sim_end_hour = get_sim_times_of_year(year)
        hourly_elec_factors = hourly_elec_factors[sim_start_hour..sim_end_hour]

        if hourly_elec_net.size == hourly_elec_factors[sim_start_hour..sim_end_hour].size + 24
          # Use leap-year for calculations
          year = 2000
          sim_start_day_of_year, sim_end_day_of_year, sim_start_hour, sim_end_hour = get_sim_times_of_year(year)
          # Duplicate Feb 28 Cambium values for Feb 29
          hourly_elec_factors = hourly_elec_factors[0..1415] + hourly_elec_factors[1392..1415] + hourly_elec_factors[1416..8759]
        end
        hourly_elec_factors = hourly_elec_factors[sim_start_hour..sim_end_hour] # Trim to sim period

        fail 'Unexpected failure for emissions calculations.' if hourly_elec_factors.size != hourly_elec_net.size

        # Calculate annual emissions for net electricity
        if scenario.elec_units == HPXML::EmissionsScenario::UnitsKgPerMWh
          elec_units_mult = UnitConversions.convert(1.0, 'kg', 'lbm')
        elsif scenario.elec_units == HPXML::EmissionsScenario::UnitsLbPerMWh
          elec_units_mult = 1.0
        end
        @emissions[key].annual_output_by_fuel[FT::Elec] = hourly_elec_net.zip(hourly_elec_factors).map { |x, y| x * y * elec_units_mult }.sum
        if include_timeseries_emissions
          # Calculate hourly emissions for net electricity
          if timeseries_frequency == 'timestep'
            n_timesteps_per_hour = Integer(60.0 / @hpxml.header.timestep)
            timeseries_elec_factors = hourly_elec_factors.flat_map { |y| [y] * n_timesteps_per_hour }
          else
            timeseries_elec_factors = hourly_elec_factors.dup
          end
          fail 'Unexpected failure for emissions calculations.' if timeseries_elec_factors.size != timeseries_elec_net.size

          @emissions[key].timeseries_output_by_fuel[FT::Elec] = timeseries_elec_net.zip(timeseries_elec_factors).map { |n, f| n * f * elec_units_mult }

          # Aggregate up from hourly to the desires timeseries frequency
          if ['daily', 'monthly'].include? timeseries_frequency
            if timeseries_frequency == 'daily'
              n_hours_per_period = [24] * (sim_end_day_of_year - sim_start_day_of_year + 1)
            elsif timeseries_frequency == 'monthly'
              n_days_per_month = Constants.NumDaysInMonths(year)
              n_days_per_period = n_days_per_month[@hpxml.header.sim_begin_month - 1..@hpxml.header.sim_end_month - 1]
              n_days_per_period[0] -= @hpxml.header.sim_begin_day - 1
              n_days_per_period[-1] = @hpxml.header.sim_end_day
              n_hours_per_period = n_days_per_period.map { |x| x * 24 }
            end
            fail 'Unexpected failure for emissions calculations.' if n_hours_per_period.sum != @emissions[key].timeseries_output_by_fuel[FT::Elec].size

            timeseries_output = []
            start_hour = 0
            n_hours_per_period.each do |n_hours|
              timeseries_output << @emissions[key].timeseries_output_by_fuel[FT::Elec][start_hour..start_hour + n_hours - 1].sum()
              start_hour += n_hours
            end
            @emissions[key].timeseries_output_by_fuel[FT::Elec] = timeseries_output
          end
        end

        # Calculate emissions for fossil fuels
        @fuels.each do |fuel_type, fuel|
          next if [FT::Elec].include? fuel_type

          fuel_map = { FT::Gas => [scenario.natural_gas_units, scenario.natural_gas_value],
                       FT::Propane => [scenario.propane_units, scenario.propane_value],
                       FT::Oil => [scenario.fuel_oil_units, scenario.fuel_oil_value],
                       FT::Coal => [scenario.coal_units, scenario.coal_value],
                       FT::WoodCord => [scenario.wood_units, scenario.wood_value],
                       FT::WoodPellets => [scenario.wood_pellets_units, scenario.wood_pellets_value] }
          fuel_units, fuel_factor = fuel_map[fuel_type]
          if fuel_factor.nil?
            if fuel.annual_output != 0
              runner.registerWarning("No emissions factor found for Scenario=#{scenario.name}, Type=#{scenario.emissions_type}, Fuel=#{fuel_type}.")
            end
            fuel_factor = 0.0
            fuel_units_mult = 0.0
          elsif fuel_units == HPXML::EmissionsScenario::UnitsKgPerMBtu
            fuel_units_mult = UnitConversions.convert(1.0, 'kg', 'lbm')
          elsif fuel_units == HPXML::EmissionsScenario::UnitsLbPerMBtu
            fuel_units_mult = 1.0
          end

          @emissions[key].annual_output_by_fuel[fuel_type] = UnitConversions.convert(fuel.annual_output, fuel.annual_units, 'MBtu') * fuel_factor * fuel_units_mult
          next unless include_timeseries_emissions

          fuel_to_mbtu = UnitConversions.convert(1.0, fuel.timeseries_units, 'MBtu')
          fail 'Unexpected failure for emissions calculations.' if fuel.timeseries_output.size != @emissions[key].timeseries_output_by_fuel[FT::Elec].size

          @emissions[key].timeseries_output_by_fuel[fuel_type] = fuel.timeseries_output.map { |f| f * fuel_to_mbtu * fuel_factor * fuel_units_mult }
        end

        # Sum individual fuel results for total
        @emissions[key].annual_output = @emissions[key].annual_output_by_fuel.values.sum()
        next unless not @emissions[key].timeseries_output_by_fuel.empty?

        @emissions[key].timeseries_output = @emissions[key].timeseries_output_by_fuel.first[1]
        @emissions[key].timeseries_output_by_fuel.each_with_index do |(fuel, timeseries_output), i|
          next if i == 0

          @emissions[key].timeseries_output = @emissions[key].timeseries_output.zip(timeseries_output).map { |x, y| x + y }
        end
      end
    end

    return outputs
  end

  def get_sim_times_of_year(year)
    sim_start_day_of_year = Schedule.get_day_num_from_month_day(year, @hpxml.header.sim_begin_month, @hpxml.header.sim_begin_day)
    sim_end_day_of_year = Schedule.get_day_num_from_month_day(year, @hpxml.header.sim_end_month, @hpxml.header.sim_end_day)
    sim_start_hour = (sim_start_day_of_year - 1) * 24
    sim_end_hour = sim_end_day_of_year * 24 - 1
    return sim_start_day_of_year, sim_end_day_of_year, sim_start_hour, sim_end_hour
  end

  def check_for_errors(runner, outputs)
    all_total = @fuels.values.map { |x| x.annual_output.to_f }.sum(0.0)
    all_total += @ideal_system_loads.values.map { |x| x.annual_output.to_f }.sum(0.0)
    if all_total == 0
      runner.registerError('Simulation unsuccessful.')
      return false
    end

    # Check sum of electricity produced end use outputs match total
    sum_elec_produced = -1 * @end_uses.select { |k, eu| eu.is_negative }.map { |k, eu| eu.annual_output.to_f }.sum(0.0)
    total_elec_produced = outputs[:total_elec_produced]
    if (sum_elec_produced - total_elec_produced).abs > 0.1
      runner.registerError("#{FT::Elec} produced category end uses (#{sum_elec_produced}) do not sum to total (#{total_elec_produced}).")
      return false
    end

    # Check sum of end use outputs match fuel outputs
    @fuels.keys.each do |fuel_type|
      sum_categories = @end_uses.select { |k, eu| k[0] == fuel_type }.map { |k, eu| eu.annual_output.to_f }.sum(0.0)
      fuel_total = @fuels[fuel_type].annual_output.to_f
      if fuel_type == FT::Elec
        fuel_total -= sum_elec_produced
      end
      if (fuel_total - sum_categories).abs > 0.1
        runner.registerError("#{fuel_type} category end uses (#{sum_categories}) do not sum to total (#{fuel_total}).")
        return false
      end
    end

    # Check sum of timeseries outputs match annual outputs
    { @end_uses => 'End Use',
      @fuels => 'Fuel',
      @emissions => 'Emissions',
      @loads => 'Load',
      @component_loads => 'Component Load' }.each do |outputs, output_type|
      outputs.each do |key, obj|
        next if obj.timeseries_output.empty?

        sum_timeseries = UnitConversions.convert(obj.timeseries_output.sum(0.0), obj.timeseries_units, obj.annual_units)
        annual_total = obj.annual_output.to_f
        if (annual_total - sum_timeseries).abs > 0.1
          runner.registerError("Timeseries outputs (#{sum_timeseries}) do not sum to annual output (#{annual_total}) for #{output_type}: #{key}.")
          return false
        end
      end
    end

    return true
  end

  def write_annual_output_results(runner, outputs, output_format, annual_output_path)
    # Set rounding precision.
    # Note: Make sure to round outputs with sufficient resolution for the worst case -- i.e., 1 day instead of a full year.
    dig = 2 # Default for annual (or near-annual) data
    year = 2000 # Not important
    sim_n_days = (Schedule.get_day_num_from_month_day(year, @hpxml.header.sim_end_month, @hpxml.header.sim_end_day) -
                  Schedule.get_day_num_from_month_day(year, @hpxml.header.sim_begin_month, @hpxml.header.sim_begin_day))
    if sim_n_days <= 10 # 10 days or less; add two decimal places
      dig += 2
    elsif sim_n_days <= 100 # 100 days or less; add one decimal place
      dig += 1
    end

    line_break = nil
    elec_produced = @end_uses.select { |k, eu| eu.is_negative }.map { |k, eu| eu.annual_output.to_f }.sum(0.0)

    results_out = []
    @fuels.each do |fuel_type, fuel|
      results_out << ["#{fuel.name} (#{fuel.annual_units})", fuel.annual_output.to_f.round(dig)]
      if fuel_type == FT::Elec
        results_out << ['Fuel Use: Electricity: Net (MBtu)', (fuel.annual_output.to_f + elec_produced).round(dig)]
      end
    end
    results_out << [line_break]
    @end_uses.each do |key, end_use|
      results_out << ["#{end_use.name} (#{end_use.annual_units})", end_use.annual_output.to_f.round(dig)]
    end
    if not @emissions.empty?
      results_out << [line_break]
      # Include total and disaggregated by fuel
      @emissions.each do |scenario_key, emission|
        results_out << ["#{emission.name} (#{emission.annual_units})", emission.annual_output.to_f.round(2)]
        emission.annual_output_by_fuel.each do |fuel, annual_output|
          results_out << ["#{emission.name.gsub(': Total', ': ' + fuel)} (#{emission.annual_units})", emission.annual_output_by_fuel[fuel].to_f.round(2)]
        end
      end
    end
    results_out << [line_break]
    @loads.each do |load_type, load|
      results_out << ["#{load.name} (#{load.annual_units})", load.annual_output.to_f.round(dig)]
    end
    results_out << [line_break]
    @unmet_hours.each do |load_type, unmet_hour|
      results_out << ["#{unmet_hour.name} (#{unmet_hour.annual_units})", unmet_hour.annual_output.to_f.round(dig)]
    end
    results_out << [line_break]
    @peak_fuels.each do |key, peak_fuel|
      results_out << ["#{peak_fuel.name} (#{peak_fuel.annual_units})", peak_fuel.annual_output.to_f.round(dig - 2)]
    end
    results_out << [line_break]
    @peak_loads.each do |load_type, peak_load|
      results_out << ["#{peak_load.name} (#{peak_load.annual_units})", peak_load.annual_output.to_f.round(dig)]
    end
    if @component_loads.values.map { |load| load.annual_output.to_f }.sum != 0 # Skip if component loads not calculated
      results_out << [line_break]
      @component_loads.each do |load_type, load|
        results_out << ["#{load.name} (#{load.annual_units})", load.annual_output.to_f.round(dig)]
      end
    end
    results_out << [line_break]
    @hot_water_uses.each do |hot_water_type, hot_water|
      results_out << ["#{hot_water.name} (#{hot_water.annual_units})", hot_water.annual_output.to_f.round(dig - 2)]
    end

    if output_format == 'csv'
      CSV.open(annual_output_path, 'wb') { |csv| results_out.to_a.each { |elem| csv << elem } }
    elsif output_format == 'json'
      h = {}
      results_out.each do |out|
        next if out == [line_break]

        grp, name = out[0].split(':', 2)
        h[grp] = {} if h[grp].nil?
        h[grp][name.strip] = out[1]
      end

      require 'json'
      File.open(annual_output_path, 'w') { |json| json.write(JSON.pretty_generate(h)) }
    end
    runner.registerInfo("Wrote annual output results to #{annual_output_path}.")
  end

  def report_sim_outputs(runner)
    all_outputs = []
    all_outputs << @fuels
    all_outputs << @end_uses
    all_outputs << @emissions
    all_outputs << @loads
    all_outputs << @unmet_hours
    all_outputs << @peak_fuels
    all_outputs << @peak_loads
    if @component_loads.values.map { |load| load.annual_output.to_f }.sum != 0 # Skip if component loads not calculated
      all_outputs << @component_loads
    end
    all_outputs << @hot_water_uses

    all_outputs.each do |outputs|
      outputs.each do |key, obj|
        output_name = get_runner_output_name(obj)
        output_val = obj.annual_output.to_f.round(2)
        runner.registerValue(output_name, output_val)
        runner.registerInfo("Registering #{output_val} for #{output_name}.")

        if obj.is_a?(Emission)
          # Include total and disaggregated by fuel
          obj.annual_output_by_fuel.each do |fuel, annual_output|
            output_name = get_runner_output_name(obj).gsub(': Total', ': ' + fuel)
            output_val = annual_output.to_f.round(2)
            runner.registerValue(output_name, output_val)
            runner.registerInfo("Registering #{output_val} for #{output_name}.")
          end
        end

        next unless key == FT::Elec && obj.is_a?(Fuel)

        # Also add Net Electricity
        elec_total = @fuels[FT::Elec].annual_output.to_f
        elec_produced = @end_uses.select { |k, eu| eu.is_negative }.map { |k, eu| eu.annual_output.to_f }.sum(0.0)
        output_name = 'Fuel Use: Electricity: Net (MBtu)'
        output_val = (elec_total + elec_produced).round(2)
        runner.registerValue(output_name, output_val)
        runner.registerInfo("Registering #{output_val} for #{output_name}.")
      end
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
        if not hash[sys_id].nil?
          vals << hash[sys_id]
        else
          vals << 0.0
        end
      end
      return vals
    end

    def get_sys_ids_of_interest(type, htg_ids, clg_ids, dhw_ids, vent_prehtg_ids, vent_preclg_ids)
      if type.downcase.include? 'hot water'
        return dhw_ids
      elsif type.downcase.include? 'mech vent preheating'
        return vent_prehtg_ids
      elsif type.downcase.include? 'mech vent precooling'
        return vent_preclg_ids
      elsif type.downcase.include? 'heating'
        return htg_ids
      elsif type.downcase.include? 'cooling'
        return clg_ids
      end

      return
    end

    def get_eec_value_numerator(unit)
      if ['HSPF', 'SEER', 'EER', 'CEER'].include? unit
        return 3.413
      elsif ['AFUE', 'COP', 'Percent', 'EF'].include? unit
        return 1.0
      end
    end

    def get_ids(ids, seed_id_map)
      return ids.map { |id| seed_id_map[id].nil? ? id : seed_id_map[id] }
    end

    results_out = []

    # Retrieve info from HPXML object
    # FUTURE: Move this code to the ERI workflow
    htg_ids, clg_ids, dhw_ids, vent_prehtg_ids, vent_preclg_ids = [], [], [], [], []
    htg_eecs, clg_eecs, dhw_eecs, vent_prehtg_eecs, vent_preclg_eecs = {}, {}, {}, {}, {}
    htg_fuels, dhw_fuels, vent_prehtg_fuels = {}, {}, {}
    seed_id_map = {}
    @hpxml.heating_systems.each do |htg_system|
      next unless htg_system.fraction_heat_load_served > 0

      htg_ids << htg_system.id
      seed_id_map[htg_system.id] = htg_system.seed_id
      htg_fuels[htg_system.id] = htg_system.heating_system_fuel
      if not htg_system.heating_efficiency_afue.nil?
        htg_eecs[htg_system.id] = get_eec_value_numerator('AFUE') / htg_system.heating_efficiency_afue
      elsif not htg_system.heating_efficiency_percent.nil?
        htg_eecs[htg_system.id] = get_eec_value_numerator('Percent') / htg_system.heating_efficiency_percent
      end
    end
    @hpxml.cooling_systems.each do |clg_system|
      next unless clg_system.fraction_cool_load_served > 0

      clg_ids << clg_system.id
      seed_id_map[clg_system.id] = clg_system.seed_id
      if not clg_system.cooling_efficiency_seer.nil?
        clg_eecs[clg_system.id] = get_eec_value_numerator('SEER') / clg_system.cooling_efficiency_seer
      elsif not clg_system.cooling_efficiency_eer.nil?
        clg_eecs[clg_system.id] = get_eec_value_numerator('EER') / clg_system.cooling_efficiency_eer
      elsif not clg_system.cooling_efficiency_ceer.nil?
        clg_eecs[clg_system.id] = get_eec_value_numerator('CEER') / clg_system.cooling_efficiency_ceer
      end
      if clg_system.cooling_system_type == HPXML::HVACTypeEvaporativeCooler
        clg_eecs[clg_system.id] = get_eec_value_numerator('SEER') / 15.0 # Arbitrary
      end
    end
    @hpxml.heat_pumps.each do |heat_pump|
      if heat_pump.fraction_heat_load_served > 0
        htg_ids << heat_pump.id
        seed_id_map[heat_pump.id] = heat_pump.seed_id
        htg_fuels[heat_pump.id] = heat_pump.heat_pump_fuel
        if not heat_pump.heating_efficiency_hspf.nil?
          htg_eecs[heat_pump.id] = get_eec_value_numerator('HSPF') / heat_pump.heating_efficiency_hspf
        elsif not heat_pump.heating_efficiency_cop.nil?
          htg_eecs[heat_pump.id] = get_eec_value_numerator('COP') / heat_pump.heating_efficiency_cop
        end
      end
      next unless heat_pump.fraction_cool_load_served > 0

      clg_ids << heat_pump.id
      seed_id_map[heat_pump.id] = heat_pump.seed_id
      if not heat_pump.cooling_efficiency_seer.nil?
        clg_eecs[heat_pump.id] = get_eec_value_numerator('SEER') / heat_pump.cooling_efficiency_seer
      elsif not heat_pump.cooling_efficiency_eer.nil?
        clg_eecs[heat_pump.id] = get_eec_value_numerator('EER') / heat_pump.cooling_efficiency_eer
      end
    end
    @hpxml.water_heating_systems.each do |dhw_system|
      dhw_ids << dhw_system.id
      ef_or_uef = nil
      ef_or_uef = dhw_system.energy_factor unless dhw_system.energy_factor.nil?
      ef_or_uef = dhw_system.uniform_energy_factor unless dhw_system.uniform_energy_factor.nil?
      if ef_or_uef.nil?
        # Get assumed EF for combi system
        @model.getWaterHeaterMixeds.each do |wh|
          dhw_id = wh.additionalProperties.getFeatureAsString('HPXML_ID')
          next unless (dhw_id.is_initialized && dhw_id.get == dhw_system.id)

          ef_or_uef = wh.additionalProperties.getFeatureAsDouble('EnergyFactor').get
        end
      end
      value_adj = 1.0
      value_adj = dhw_system.performance_adjustment if dhw_system.water_heater_type == HPXML::WaterHeaterTypeTankless
      if (not ef_or_uef.nil?) && (not value_adj.nil?)
        dhw_eecs[dhw_system.id] = get_eec_value_numerator('EF') / (Float(ef_or_uef) * Float(value_adj))
      end
      if [HPXML::WaterHeaterTypeCombiTankless, HPXML::WaterHeaterTypeCombiStorage].include? dhw_system.water_heater_type
        dhw_fuels[dhw_system.id] = dhw_system.related_hvac_system.heating_system_fuel
      else
        dhw_fuels[dhw_system.id] = dhw_system.fuel_type
      end
    end
    @hpxml.ventilation_fans.each do |vent_fan|
      next unless vent_fan.used_for_whole_building_ventilation

      if not vent_fan.preheating_fuel.nil?
        vent_prehtg_ids << vent_fan.id
        vent_prehtg_fuels[vent_fan.id] = vent_fan.preheating_fuel
        vent_prehtg_eecs[vent_fan.id] = get_eec_value_numerator('COP') / vent_fan.preheating_efficiency_cop
      end
      next unless not vent_fan.precooling_fuel.nil?

      vent_preclg_ids << vent_fan.id
      vent_preclg_eecs[vent_fan.id] = get_eec_value_numerator('COP') / vent_fan.precooling_efficiency_cop
    end

    # Calculate ERI Reference Loads
    (@hpxml.heating_systems + @hpxml.heat_pumps).each do |htg_system|
      next unless htg_ids.include? htg_system.id

      @loads[LT::Heating].annual_output_by_system[htg_system.id] = htg_system.fraction_heat_load_served * @loads[LT::Heating].annual_output
    end
    (@hpxml.cooling_systems + @hpxml.heat_pumps).each do |clg_system|
      next unless clg_ids.include? clg_system.id

      @loads[LT::Cooling].annual_output_by_system[clg_system.id] = clg_system.fraction_cool_load_served * @loads[LT::Cooling].annual_output
    end

    # Handle dual-fuel heat pumps
    @hpxml.heat_pumps.each do |heat_pump|
      next unless heat_pump.is_dual_fuel

      # Create separate dual fuel heat pump backup system
      dfhp_backup_id = heat_pump.id + '_DFHPBackup'
      htg_ids << dfhp_backup_id
      seed_id_map[dfhp_backup_id] = heat_pump.seed_id + '_DFHPBackup'
      htg_fuels[dfhp_backup_id] = heat_pump.backup_heating_fuel
      if not heat_pump.backup_heating_efficiency_afue.nil?
        htg_eecs[dfhp_backup_id] = get_eec_value_numerator('AFUE') / heat_pump.backup_heating_efficiency_afue
      elsif not heat_pump.backup_heating_efficiency_percent.nil?
        htg_eecs[dfhp_backup_id] = get_eec_value_numerator('Percent') / heat_pump.backup_heating_efficiency_percent
      end

      next unless [Constants.CalcTypeERIReferenceHome, Constants.CalcTypeERIIndexAdjustmentReferenceHome].include? @eri_design

      # Apportion heating load for the two systems
      primary_load, backup_load = nil
      @object_variables_by_key[[LT, LT::Heating]].each do |vals|
        sys_id, key_name, var_name = vals
        if sys_id == heat_pump.id
          primary_load = get_report_variable_data_annual([key_name], [var_name])
        elsif sys_id == dfhp_backup_id
          backup_load = get_report_variable_data_annual([key_name], [var_name])
        end
      end
      fail 'Could not obtain DFHP loads.' if primary_load.nil? || backup_load.nil?

      total_load = @loads[LT::Heating].annual_output_by_system[heat_pump.id]
      backup_ratio = backup_load / (primary_load + backup_load)
      @loads[LT::Heating].annual_output_by_system[dfhp_backup_id] = total_load * backup_ratio
      @loads[LT::Heating].annual_output_by_system[heat_pump.id] = total_load * (1.0 - backup_ratio)
    end

    # Sys IDS
    results_out << ['hpxml_heat_sys_ids', get_ids(htg_ids, seed_id_map).to_s]
    results_out << ['hpxml_cool_sys_ids', get_ids(clg_ids, seed_id_map).to_s]
    results_out << ['hpxml_dhw_sys_ids', get_ids(dhw_ids, seed_id_map).to_s]
    results_out << ['hpxml_vent_preheat_sys_ids', vent_prehtg_ids.to_s]
    results_out << ['hpxml_vent_precool_sys_ids', vent_preclg_ids.to_s]
    results_out << [line_break]

    # EECs
    results_out << ['hpxml_eec_heats', ordered_values(htg_eecs, htg_ids).to_s]
    results_out << ['hpxml_eec_cools', ordered_values(clg_eecs, clg_ids).to_s]
    results_out << ['hpxml_eec_dhws', ordered_values(dhw_eecs, dhw_ids).to_s]
    results_out << ['hpxml_eec_vent_preheats', ordered_values(vent_prehtg_eecs, vent_prehtg_ids).to_s]
    results_out << ['hpxml_eec_vent_precools', ordered_values(vent_preclg_eecs, vent_preclg_ids).to_s]
    results_out << [line_break]

    # Fuel types
    results_out << ['hpxml_heat_fuels', ordered_values(htg_fuels, htg_ids).to_s]
    results_out << ['hpxml_dwh_fuels', ordered_values(dhw_fuels, dhw_ids).to_s]
    results_out << ['hpxml_vent_preheat_fuels', ordered_values(vent_prehtg_fuels, vent_prehtg_ids).to_s]
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
      sys_ids = get_sys_ids_of_interest(end_use_type, htg_ids, clg_ids, dhw_ids, vent_prehtg_ids, vent_preclg_ids)
      if sys_ids.nil?
        results_out << [key_name, end_use.annual_output.to_s]
      else
        results_out << [key_name, ordered_values(end_use.annual_output_by_system, sys_ids).to_s]
      end
    end
    results_out << [line_break]

    # Loads by System
    @loads.each do |load_type, load|
      next unless [LT::Heating, LT::Cooling, LT::HotWaterDelivered].include? load_type
      next if ([LT::Heating, LT::Cooling].include? load_type) &&
              (not [Constants.CalcTypeERIReferenceHome, Constants.CalcTypeERIIndexAdjustmentReferenceHome].include? @eri_design)

      key_name = sanitize_string("load#{load_type}")
      sys_ids = get_sys_ids_of_interest(load_type, htg_ids, clg_ids, dhw_ids, vent_prehtg_ids, vent_preclg_ids)
      results_out << [key_name, ordered_values(load.annual_output_by_system, sys_ids).to_s]
    end
    results_out << [line_break]

    # Emissions Scenarios
    if not @emissions.empty?
      @emissions.each do |scenario_key, emission|
        scenario_type, scenario_name = scenario_key
        # Include total and disaggregated by fuel
        key_name = sanitize_string("#{scenario_type.downcase}#{scenario_name}Total")
        results_out << [key_name, emission.annual_output.to_s]
        emission.annual_output_by_fuel.each do |fuel, annual_output|
          key_name = sanitize_string("#{scenario_type.downcase}#{scenario_name}#{fuel}")
          results_out << [key_name, annual_output.to_s]
        end
      end
    end

    # Misc
    results_out << ['hpxml_cfa', @hpxml.building_construction.conditioned_floor_area.to_s]
    results_out << ['hpxml_nbr', @hpxml.building_construction.number_of_bedrooms.to_s]
    results_out << ['hpxml_nst', @hpxml.building_construction.number_of_conditioned_floors_above_grade.to_s]
    results_out << ['hpxml_residential_facility_type', '"' + @hpxml.building_construction.residential_facility_type + '"']

    CSV.open(csv_path, 'wb') { |csv| results_out.to_a.each { |elem| csv << elem } }
  end

  def write_timeseries_output_results(runner, outputs, output_format,
                                      timeseries_output_path,
                                      timeseries_frequency,
                                      include_timeseries_fuel_consumptions,
                                      include_timeseries_end_use_consumptions,
                                      include_timeseries_emissions,
                                      include_timeseries_hot_water_uses,
                                      include_timeseries_total_loads,
                                      include_timeseries_component_loads,
                                      include_timeseries_zone_temperatures,
                                      include_timeseries_airflows,
                                      include_timeseries_weather,
                                      timestamps_dst,
                                      timestamps_utc)
    return if timeseries_frequency == 'none'

    # Set rounding precision.
    # Note: Make sure to round outputs with sufficient resolution for the worst case -- i.e., 1 minute date instead of hourly data.
    dig = 2 # Default for hourly (or longer) data
    if timeseries_frequency == 'timestep'
      if @hpxml.header.timestep <= 2 # 2-minute timesteps or shorter; add two decimal places
        dig += 2
      elsif @hpxml.header.timestep <= 15 # 15-minute timesteps or shorter; add one decimal place
        dig += 1
      end
    end

    # Time column(s)
    if ['timestep', 'hourly', 'daily', 'monthly'].include? timeseries_frequency
      data = ['Time', nil]
    else
      fail "Unexpected timeseries_frequency: #{timeseries_frequency}."
    end
    @timestamps.each do |timestamp|
      data << timestamp
    end

    if timestamps_dst
      timestamps2 = [['TimeDST', nil]]
      timestamps_dst.each do |timestamp|
        timestamps2[0] << timestamp
      end
    else
      timestamps2 = []
    end

    if timestamps_utc
      timestamps3 = [['TimeUTC', nil]]
      timestamps_utc.each do |timestamp|
        timestamps3[0] << timestamp
      end
    else
      timestamps3 = []
    end

    if include_timeseries_fuel_consumptions
      fuel_data = @fuels.values.select { |x| x.timeseries_output.sum(0.0) != 0 }.map { |x| [x.name, x.timeseries_units] + x.timeseries_output.map { |v| v.round(dig) } }
      if outputs[:total_elec_produced_timeseries].sum(0.0) != 0
        fuel_data.insert(1, ['Fuel Use: Electricity: Net', get_timeseries_units_from_fuel_type(FT::Elec)] + outputs[:total_elec_net_timeseries].map { |v| v.round(dig) })
      end
    else
      fuel_data = []
    end
    if include_timeseries_end_use_consumptions
      end_use_data = @end_uses.values.select { |x| x.timeseries_output.sum(0.0) != 0 }.map { |x| [x.name, x.timeseries_units] + x.timeseries_output.map { |v| v.round(dig) } }
    else
      end_use_data = []
    end
    if include_timeseries_emissions
      # Include total and disaggregated by fuel
      emissions_data = []
      @emissions.values.each do |emission|
        emissions_data << [emission.name, emission.timeseries_units] + emission.timeseries_output.map { |v| v.round(5) }
        emission.timeseries_output_by_fuel.each do |fuel, timeseries_output|
          next if timeseries_output.sum(0.0) == 0

          emissions_data << [emission.name.gsub(': Total', ': ' + fuel), emission.timeseries_units] + timeseries_output.map { |v| v.round(5) }
        end
      end
    else
      emissions_data = []
    end
    if include_timeseries_hot_water_uses
      hot_water_use_data = @hot_water_uses.values.select { |x| x.timeseries_output.sum(0.0) != 0 }.map { |x| [x.name, x.timeseries_units] + x.timeseries_output.map { |v| v.round(dig) } }
    else
      hot_water_use_data = []
    end
    if include_timeseries_total_loads
      total_loads_data = @loads.values.select { |x| x.timeseries_output.sum(0.0) != 0 }.map { |x| [x.name, x.timeseries_units] + x.timeseries_output.map { |v| v.round(dig) } }
    else
      total_loads_data = {}
    end
    if include_timeseries_component_loads
      comp_loads_data = @component_loads.values.select { |x| x.timeseries_output.sum(0.0) != 0 }.map { |x| [x.name, x.timeseries_units] + x.timeseries_output.map { |v| v.round(dig) } }
    else
      comp_loads_data = []
    end
    if include_timeseries_zone_temperatures
      zone_temps_data = @zone_temps.values.select { |x| x.timeseries_output.sum(0.0) != 0 }.map { |x| [x.name, x.timeseries_units] + x.timeseries_output.map { |v| v.round(dig) } }
    else
      zone_temps_data = []
    end
    if include_timeseries_airflows
      airflows_data = @airflows.values.select { |x| x.timeseries_output.sum(0.0) != 0 }.map { |x| [x.name, x.timeseries_units] + x.timeseries_output.map { |v| v.round(dig) } }
    else
      airflows_data = []
    end
    if include_timeseries_weather
      weather_data = @weather.values.select { |x| x.timeseries_output.sum(0.0) != 0 }.map { |x| [x.name, x.timeseries_units] + x.timeseries_output.map { |v| v.round(dig) } }
    else
      weather_data = []
    end

    return if fuel_data.size + end_use_data.size + emissions_data.size + hot_water_use_data.size + total_loads_data.size + comp_loads_data.size + zone_temps_data.size + airflows_data.size + weather_data.size == 0

    fail 'Unable to obtain timestamps.' if @timestamps.empty?

    if output_format == 'csv'
      # Assemble data
      data = data.zip(*timestamps2, *timestamps3, *fuel_data, *end_use_data, *emissions_data, *hot_water_use_data, *total_loads_data, *comp_loads_data, *zone_temps_data, *airflows_data, *weather_data)

      # Error-check
      n_elements = []
      data.each do |data_array|
        n_elements << data_array.size
      end
      if n_elements.uniq.size > 1
        fail "Inconsistent number of array elements: #{n_elements.uniq}."
      end

      # Write file
      CSV.open(timeseries_output_path, 'wb') { |csv| data.to_a.each { |elem| csv << elem } }
    elsif output_format == 'json'
      # Assemble data
      h = {}
      h['Time'] = data[2..-1]
      h['TimeDST'] = timestamps2[2..-1] if timestamps_dst
      h['TimeUTC'] = timestamps3[2..-1] if timestamps_utc

      [fuel_data, end_use_data, emissions_data, hot_water_use_data, total_loads_data, comp_loads_data, zone_temps_data, airflows_data, weather_data].each do |d|
        d.each do |o|
          grp, name = o[0].split(':', 2)
          h[grp] = {} if h[grp].nil?
          h[grp]["#{name.strip} (#{o[1]})"] = o[2..-1]
        end
      end

      # Write file
      require 'json'
      File.open(timeseries_output_path, 'w') { |json| json.write(JSON.pretty_generate(h)) }
    end
    runner.registerInfo("Wrote timeseries output results to #{timeseries_output_path}.")
  end

  def get_report_meter_data_annual(meter_names, unit_conv = UnitConversions.convert(1.0, 'J', 'MBtu'))
    return 0.0 if meter_names.empty?

    vars = "'" + meter_names.uniq.join("','") + "'"
    query = "SELECT SUM(VariableValue*#{unit_conv}) FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableName IN (#{vars}) AND ReportingFrequency='Run Period' AND VariableUnits='J')"
    value = @sqlFile.execAndReturnFirstDouble(query)
    fail "Query error: #{query}" unless value.is_initialized

    return value.get
  end

  def get_report_variable_data_annual(key_values, variables, unit_conv = UnitConversions.convert(1.0, 'J', 'MBtu'), is_negative: false)
    return 0.0 if variables.empty?

    keys = "'" + key_values.uniq.join("','") + "'"
    vars = "'" + variables.uniq.join("','") + "'"
    neg = is_negative ? ' * -1' : ''
    query = "SELECT SUM(VariableValue*#{unit_conv})#{neg} FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex IN (SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE KeyValue IN (#{keys}) AND VariableName IN (#{vars}) AND ReportingFrequency='Run Period')"
    value = @sqlFile.execAndReturnFirstDouble(query)
    fail "Query error: #{query}" unless value.is_initialized

    return value.get
  end

  def get_report_meter_data_timeseries(meter_names, unit_conv, unit_adder, timeseries_frequency)
    return [0.0] * @timestamps.size if meter_names.empty?

    vars = "'" + meter_names.uniq.join("','") + "'"
    query = "SELECT SUM(VariableValue*#{unit_conv}+#{unit_adder}) FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableName IN (#{vars}) AND ReportingFrequency='#{reporting_frequency_map[timeseries_frequency]}' AND VariableUnits='J') GROUP BY TimeIndex ORDER BY TimeIndex"
    values = @sqlFile.execAndReturnVectorOfDouble(query)
    fail "Query error: #{query}" unless values.is_initialized

    values = values.get
    values += [0.0] * @timestamps.size if values.size == 0
    return values
  end

  def get_report_variable_data_timeseries(key_values, variables, unit_conv, unit_adder, timeseries_frequency, disable_ems_shift = false, is_negative: false)
    return [0.0] * @timestamps.size if variables.empty?

    if key_values.uniq.size > 1 && key_values.include?('EMS') && !disable_ems_shift
      # Split into EMS and non-EMS queries so that the EMS values shift occurs for just the EMS query
      # Remove this code if we ever figure out a better way to handle when EMS output should shift
      values = get_report_variable_data_timeseries(['EMS'], variables, unit_conv, unit_adder, timeseries_frequency, disable_ems_shift, is_negative: is_negative)
      sum_values = values.zip(get_report_variable_data_timeseries(key_values.select { |k| k != 'EMS' }, variables, unit_conv, unit_adder, timeseries_frequency, disable_ems_shift, is_negative: is_negative)).map { |x, y| x + y }
      return sum_values
    end

    keys = "'" + key_values.uniq.join("','") + "'"
    vars = "'" + variables.uniq.join("','") + "'"
    neg = is_negative ? ' * -1' : ''
    query = "SELECT SUM(VariableValue*#{unit_conv}+#{unit_adder})#{neg} FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex IN (SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE KeyValue IN (#{keys}) AND VariableName IN (#{vars}) AND ReportingFrequency='#{reporting_frequency_map[timeseries_frequency]}') GROUP BY TimeIndex ORDER BY TimeIndex"
    values = @sqlFile.execAndReturnVectorOfDouble(query)
    fail "Query error: #{query}" unless values.is_initialized

    values = values.get
    values += [0.0] * @timestamps.size if values.size == 0

    return values if disable_ems_shift

    # Remove this code if we ever figure out a better way to handle when EMS output should shift
    if (key_values.size == 1) && (key_values[0] == 'EMS') && (@timestamps.size > 0)
      if (timeseries_frequency.downcase == 'timestep' || (timeseries_frequency.downcase == 'hourly' && @model.getTimestep.numberOfTimestepsPerHour == 1))
        # Shift all values by 1 timestep due to EMS reporting lag
        return values[1..-1] + [values[0]]
      end
    end

    return values
  end

  def get_tabular_data_value(report_name, report_for_string, table_name, row_names, col_name, units)
    rows = "'" + row_names.uniq.join("','") + "'"
    query = "SELECT SUM(Value) FROM TabularDataWithStrings WHERE ReportName='#{report_name}' AND ReportForString='#{report_for_string}' AND TableName='#{table_name}' AND RowName IN (#{rows}) AND ColumnName='#{col_name}' AND Units='#{units}'"
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

    # Hourly Electricity (for Cambium)
    if obj.is_a?(EndUse) && (not obj.hourly_output_by_system.empty?)
      orig_values = obj.hourly_output_by_system[sys_id]
      obj.hourly_output_by_system[sys_id] = obj.hourly_output_by_system[sys_id].map { |x| x * mult }
      diffs = obj.hourly_output_by_system[sys_id].zip(orig_values).map { |x, y| x - y }
    end
  end

  def create_all_object_variables_by_key
    @object_variables_by_key = {}

    @model.getModelObjects.each do |object|
      next if object.to_AdditionalProperties.is_initialized

      [EUT, HWT, LT, ILT].each do |class_name|
        vars_by_key = get_object_output_variables_by_key(@model, object, class_name)
        next if vars_by_key.size == 0

        sys_id = object.additionalProperties.getFeatureAsString('HPXML_ID')
        if sys_id.is_initialized
          sys_id = sys_id.get
        else
          sys_id = nil
        end

        vars_by_key.each do |key, output_vars|
          output_vars.each do |output_var|
            if object.to_EnergyManagementSystemOutputVariable.is_initialized
              varkey = 'EMS'
            else
              varkey = object.name.to_s.upcase
            end
            hash_key = [class_name, key]
            @object_variables_by_key[hash_key] = [] if @object_variables_by_key[hash_key].nil?
            next if @object_variables_by_key[hash_key].include? [sys_id, varkey, output_var]

            @object_variables_by_key[hash_key] << [sys_id, varkey, output_var]
          end
        end
      end
    end
  end

  def get_object_variables(class_name, key)
    hash_key = [class_name, key]
    vars = @object_variables_by_key[hash_key]
    vars = [] if vars.nil?
    return vars
  end

  class BaseOutput
    def initialize()
      @timeseries_output = []
    end
    attr_accessor(:name, :annual_output, :timeseries_output, :annual_units, :timeseries_units)
  end

  class Fuel < BaseOutput
    def initialize(meters: [])
      super()
      @meters = meters
      @timeseries_output_by_system = {}
    end
    attr_accessor(:meters, :timeseries_output_by_system)
  end

  class EndUse < BaseOutput
    def initialize(variables: [], is_negative: false)
      super()
      @variables = variables
      @is_negative = is_negative
      @timeseries_output_by_system = {}
      @annual_output_by_system = {}
      # These outputs used to apply Cambium hourly electricity factors
      @hourly_output = []
      @hourly_output_by_system = {}
    end
    attr_accessor(:variables, :is_negative, :annual_output_by_system, :timeseries_output_by_system,
                  :hourly_output, :hourly_output_by_system)
  end

  class Emission < BaseOutput
    def initialize()
      super()
      @timeseries_output_by_fuel = {}
      @annual_output_by_fuel = {}
    end
    attr_accessor(:annual_output_by_fuel, :timeseries_output_by_fuel)
  end

  class HotWater < BaseOutput
    def initialize(variables: [])
      super()
      @variables = variables
      @timeseries_output_by_system = {}
      @annual_output_by_system = {}
    end
    attr_accessor(:variables, :annual_output_by_system, :timeseries_output_by_system)
  end

  class PeakFuel < BaseOutput
    def initialize(meters:, report:)
      super()
      @meters = meters
      @report = report
    end
    attr_accessor(:meters, :report)
  end

  class Load < BaseOutput
    def initialize(variables: [], ems_variable: nil, is_negative: false)
      super()
      @variables = variables
      @ems_variable = ems_variable
      @is_negative = is_negative
      @timeseries_output_by_system = {}
      @annual_output_by_system = {}
    end
    attr_accessor(:variables, :ems_variable, :is_negative, :annual_output_by_system, :timeseries_output_by_system)
  end

  class ComponentLoad < BaseOutput
    def initialize(ems_variable:)
      super()
      @ems_variable = ems_variable
    end
    attr_accessor(:ems_variable)
  end

  class UnmetHours < BaseOutput
    def initialize(col_name:)
      super()
      @col_name = col_name
    end
    attr_accessor(:col_name)
  end

  class IdealLoad < BaseOutput
    def initialize(variables: [])
      super()
      @variables = variables
    end
    attr_accessor(:variables)
  end

  class PeakLoad < BaseOutput
    def initialize(ems_variable:, report:)
      super()
      @ems_variable = ems_variable
      @report = report
    end
    attr_accessor(:ems_variable, :report)
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

  def setup_outputs()
    def get_timeseries_units_from_fuel_type(fuel_type)
      if fuel_type == FT::Elec
        return 'kWh'
      end

      return 'kBtu'
    end

    # End Uses

    # NOTE: Some end uses are obtained from meters, others are rolled up from
    # output variables so that we can have more control.

    create_all_object_variables_by_key()

    @end_uses = {}
    @end_uses[[FT::Elec, EUT::Heating]] = EndUse.new(variables: get_object_variables(EUT, [FT::Elec, EUT::Heating]))
    @end_uses[[FT::Elec, EUT::HeatingFanPump]] = EndUse.new(variables: get_object_variables(EUT, [FT::Elec, EUT::HeatingFanPump]))
    @end_uses[[FT::Elec, EUT::Cooling]] = EndUse.new(variables: get_object_variables(EUT, [FT::Elec, EUT::Cooling]))
    @end_uses[[FT::Elec, EUT::CoolingFanPump]] = EndUse.new(variables: get_object_variables(EUT, [FT::Elec, EUT::CoolingFanPump]))
    @end_uses[[FT::Elec, EUT::HotWater]] = EndUse.new(variables: get_object_variables(EUT, [FT::Elec, EUT::HotWater]))
    @end_uses[[FT::Elec, EUT::HotWaterRecircPump]] = EndUse.new(variables: get_object_variables(EUT, [FT::Elec, EUT::HotWaterRecircPump]))
    @end_uses[[FT::Elec, EUT::HotWaterSolarThermalPump]] = EndUse.new(variables: get_object_variables(EUT, [FT::Elec, EUT::HotWaterSolarThermalPump]))
    @end_uses[[FT::Elec, EUT::LightsInterior]] = EndUse.new(variables: get_object_variables(EUT, [FT::Elec, EUT::LightsInterior]))
    @end_uses[[FT::Elec, EUT::LightsGarage]] = EndUse.new(variables: get_object_variables(EUT, [FT::Elec, EUT::LightsGarage]))
    @end_uses[[FT::Elec, EUT::LightsExterior]] = EndUse.new(variables: get_object_variables(EUT, [FT::Elec, EUT::LightsExterior]))
    @end_uses[[FT::Elec, EUT::MechVent]] = EndUse.new(variables: get_object_variables(EUT, [FT::Elec, EUT::MechVent]))
    @end_uses[[FT::Elec, EUT::MechVentPreheat]] = EndUse.new(variables: get_object_variables(EUT, [FT::Elec, EUT::MechVentPreheat]))
    @end_uses[[FT::Elec, EUT::MechVentPrecool]] = EndUse.new(variables: get_object_variables(EUT, [FT::Elec, EUT::MechVentPrecool]))
    @end_uses[[FT::Elec, EUT::WholeHouseFan]] = EndUse.new(variables: get_object_variables(EUT, [FT::Elec, EUT::WholeHouseFan]))
    @end_uses[[FT::Elec, EUT::Refrigerator]] = EndUse.new(variables: get_object_variables(EUT, [FT::Elec, EUT::Refrigerator]))
    if @eri_design.nil? # Skip end uses not used by ERI
      @end_uses[[FT::Elec, EUT::Freezer]] = EndUse.new(variables: get_object_variables(EUT, [FT::Elec, EUT::Freezer]))
    end
    @end_uses[[FT::Elec, EUT::Dehumidifier]] = EndUse.new(variables: get_object_variables(EUT, [FT::Elec, EUT::Dehumidifier]))
    @end_uses[[FT::Elec, EUT::Dishwasher]] = EndUse.new(variables: get_object_variables(EUT, [FT::Elec, EUT::Dishwasher]))
    @end_uses[[FT::Elec, EUT::ClothesWasher]] = EndUse.new(variables: get_object_variables(EUT, [FT::Elec, EUT::ClothesWasher]))
    @end_uses[[FT::Elec, EUT::ClothesDryer]] = EndUse.new(variables: get_object_variables(EUT, [FT::Elec, EUT::ClothesDryer]))
    @end_uses[[FT::Elec, EUT::RangeOven]] = EndUse.new(variables: get_object_variables(EUT, [FT::Elec, EUT::RangeOven]))
    @end_uses[[FT::Elec, EUT::CeilingFan]] = EndUse.new(variables: get_object_variables(EUT, [FT::Elec, EUT::CeilingFan]))
    @end_uses[[FT::Elec, EUT::Television]] = EndUse.new(variables: get_object_variables(EUT, [FT::Elec, EUT::Television]))
    @end_uses[[FT::Elec, EUT::PlugLoads]] = EndUse.new(variables: get_object_variables(EUT, [FT::Elec, EUT::PlugLoads]))
    if @eri_design.nil? # Skip end uses not used by ERI
      @end_uses[[FT::Elec, EUT::Vehicle]] = EndUse.new(variables: get_object_variables(EUT, [FT::Elec, EUT::Vehicle]))
      @end_uses[[FT::Elec, EUT::WellPump]] = EndUse.new(variables: get_object_variables(EUT, [FT::Elec, EUT::WellPump]))
      @end_uses[[FT::Elec, EUT::PoolHeater]] = EndUse.new(variables: get_object_variables(EUT, [FT::Elec, EUT::PoolHeater]))
      @end_uses[[FT::Elec, EUT::PoolPump]] = EndUse.new(variables: get_object_variables(EUT, [FT::Elec, EUT::PoolPump]))
      @end_uses[[FT::Elec, EUT::HotTubHeater]] = EndUse.new(variables: get_object_variables(EUT, [FT::Elec, EUT::HotTubHeater]))
      @end_uses[[FT::Elec, EUT::HotTubPump]] = EndUse.new(variables: get_object_variables(EUT, [FT::Elec, EUT::HotTubPump]))
    end
    @end_uses[[FT::Elec, EUT::PV]] = EndUse.new(variables: get_object_variables(EUT, [FT::Elec, EUT::PV]),
                                                is_negative: true)
    @end_uses[[FT::Elec, EUT::Generator]] = EndUse.new(variables: get_object_variables(EUT, [FT::Elec, EUT::Generator]),
                                                       is_negative: true)
    @end_uses[[FT::Gas, EUT::Heating]] = EndUse.new(variables: get_object_variables(EUT, [FT::Gas, EUT::Heating]))
    @end_uses[[FT::Gas, EUT::HotWater]] = EndUse.new(variables: get_object_variables(EUT, [FT::Gas, EUT::HotWater]))
    @end_uses[[FT::Gas, EUT::ClothesDryer]] = EndUse.new(variables: get_object_variables(EUT, [FT::Gas, EUT::ClothesDryer]))
    @end_uses[[FT::Gas, EUT::RangeOven]] = EndUse.new(variables: get_object_variables(EUT, [FT::Gas, EUT::RangeOven]))
    @end_uses[[FT::Gas, EUT::MechVentPreheat]] = EndUse.new(variables: get_object_variables(EUT, [FT::Gas, EUT::MechVentPreheat]))
    if @eri_design.nil? # Skip end uses not used by ERI
      @end_uses[[FT::Gas, EUT::PoolHeater]] = EndUse.new(variables: get_object_variables(EUT, [FT::Gas, EUT::PoolHeater]))
      @end_uses[[FT::Gas, EUT::HotTubHeater]] = EndUse.new(variables: get_object_variables(EUT, [FT::Gas, EUT::HotTubHeater]))
      @end_uses[[FT::Gas, EUT::Grill]] = EndUse.new(variables: get_object_variables(EUT, [FT::Gas, EUT::Grill]))
      @end_uses[[FT::Gas, EUT::Lighting]] = EndUse.new(variables: get_object_variables(EUT, [FT::Gas, EUT::Lighting]))
      @end_uses[[FT::Gas, EUT::Fireplace]] = EndUse.new(variables: get_object_variables(EUT, [FT::Gas, EUT::Fireplace]))
    end
    @end_uses[[FT::Gas, EUT::Generator]] = EndUse.new(variables: get_object_variables(EUT, [FT::Gas, EUT::Generator]))
    @end_uses[[FT::Oil, EUT::Heating]] = EndUse.new(variables: get_object_variables(EUT, [FT::Oil, EUT::Heating]))
    @end_uses[[FT::Oil, EUT::HotWater]] = EndUse.new(variables: get_object_variables(EUT, [FT::Oil, EUT::HotWater]))
    @end_uses[[FT::Oil, EUT::ClothesDryer]] = EndUse.new(variables: get_object_variables(EUT, [FT::Oil, EUT::ClothesDryer]))
    @end_uses[[FT::Oil, EUT::RangeOven]] = EndUse.new(variables: get_object_variables(EUT, [FT::Oil, EUT::RangeOven]))
    @end_uses[[FT::Oil, EUT::MechVentPreheat]] = EndUse.new(variables: get_object_variables(EUT, [FT::Oil, EUT::MechVentPreheat]))
    if @eri_design.nil? # Skip end uses not used by ERI
      @end_uses[[FT::Oil, EUT::Grill]] = EndUse.new(variables: get_object_variables(EUT, [FT::Oil, EUT::Grill]))
      @end_uses[[FT::Oil, EUT::Lighting]] = EndUse.new(variables: get_object_variables(EUT, [FT::Oil, EUT::Lighting]))
      @end_uses[[FT::Oil, EUT::Fireplace]] = EndUse.new(variables: get_object_variables(EUT, [FT::Oil, EUT::Fireplace]))
    end
    @end_uses[[FT::Oil, EUT::Generator]] = EndUse.new(variables: get_object_variables(EUT, [FT::Oil, EUT::Generator]))
    @end_uses[[FT::Propane, EUT::Heating]] = EndUse.new(variables: get_object_variables(EUT, [FT::Propane, EUT::Heating]))
    @end_uses[[FT::Propane, EUT::HotWater]] = EndUse.new(variables: get_object_variables(EUT, [FT::Propane, EUT::HotWater]))
    @end_uses[[FT::Propane, EUT::ClothesDryer]] = EndUse.new(variables: get_object_variables(EUT, [FT::Propane, EUT::ClothesDryer]))
    @end_uses[[FT::Propane, EUT::RangeOven]] = EndUse.new(variables: get_object_variables(EUT, [FT::Propane, EUT::RangeOven]))
    @end_uses[[FT::Propane, EUT::MechVentPreheat]] = EndUse.new(variables: get_object_variables(EUT, [FT::Propane, EUT::MechVentPreheat]))
    if @eri_design.nil? # Skip end uses not used by ERI
      @end_uses[[FT::Propane, EUT::Grill]] = EndUse.new(variables: get_object_variables(EUT, [FT::Propane, EUT::Grill]))
      @end_uses[[FT::Propane, EUT::Lighting]] = EndUse.new(variables: get_object_variables(EUT, [FT::Propane, EUT::Lighting]))
      @end_uses[[FT::Propane, EUT::Fireplace]] = EndUse.new(variables: get_object_variables(EUT, [FT::Propane, EUT::Fireplace]))
    end
    @end_uses[[FT::Propane, EUT::Generator]] = EndUse.new(variables: get_object_variables(EUT, [FT::Propane, EUT::Generator]))
    @end_uses[[FT::WoodCord, EUT::Heating]] = EndUse.new(variables: get_object_variables(EUT, [FT::WoodCord, EUT::Heating]))
    @end_uses[[FT::WoodCord, EUT::HotWater]] = EndUse.new(variables: get_object_variables(EUT, [FT::WoodCord, EUT::HotWater]))
    @end_uses[[FT::WoodCord, EUT::ClothesDryer]] = EndUse.new(variables: get_object_variables(EUT, [FT::WoodCord, EUT::ClothesDryer]))
    @end_uses[[FT::WoodCord, EUT::RangeOven]] = EndUse.new(variables: get_object_variables(EUT, [FT::WoodCord, EUT::RangeOven]))
    @end_uses[[FT::WoodCord, EUT::MechVentPreheat]] = EndUse.new(variables: get_object_variables(EUT, [FT::WoodCord, EUT::MechVentPreheat]))
    if @eri_design.nil? # Skip end uses not used by ERI
      @end_uses[[FT::WoodCord, EUT::Grill]] = EndUse.new(variables: get_object_variables(EUT, [FT::WoodCord, EUT::Grill]))
      @end_uses[[FT::WoodCord, EUT::Lighting]] = EndUse.new(variables: get_object_variables(EUT, [FT::WoodCord, EUT::Lighting]))
      @end_uses[[FT::WoodCord, EUT::Fireplace]] = EndUse.new(variables: get_object_variables(EUT, [FT::WoodCord, EUT::Fireplace]))
    end
    @end_uses[[FT::WoodCord, EUT::Generator]] = EndUse.new(variables: get_object_variables(EUT, [FT::WoodCord, EUT::Generator]))
    @end_uses[[FT::WoodPellets, EUT::Heating]] = EndUse.new(variables: get_object_variables(EUT, [FT::WoodPellets, EUT::Heating]))
    @end_uses[[FT::WoodPellets, EUT::HotWater]] = EndUse.new(variables: get_object_variables(EUT, [FT::WoodPellets, EUT::HotWater]))
    @end_uses[[FT::WoodPellets, EUT::ClothesDryer]] = EndUse.new(variables: get_object_variables(EUT, [FT::WoodPellets, EUT::ClothesDryer]))
    @end_uses[[FT::WoodPellets, EUT::RangeOven]] = EndUse.new(variables: get_object_variables(EUT, [FT::WoodPellets, EUT::RangeOven]))
    @end_uses[[FT::WoodPellets, EUT::MechVentPreheat]] = EndUse.new(variables: get_object_variables(EUT, [FT::WoodPellets, EUT::MechVentPreheat]))
    if @eri_design.nil? # Skip end uses not used by ERI
      @end_uses[[FT::WoodPellets, EUT::Grill]] = EndUse.new(variables: get_object_variables(EUT, [FT::WoodPellets, EUT::Grill]))
      @end_uses[[FT::WoodPellets, EUT::Lighting]] = EndUse.new(variables: get_object_variables(EUT, [FT::WoodPellets, EUT::Lighting]))
      @end_uses[[FT::WoodPellets, EUT::Fireplace]] = EndUse.new(variables: get_object_variables(EUT, [FT::WoodPellets, EUT::Fireplace]))
    end
    @end_uses[[FT::WoodPellets, EUT::Generator]] = EndUse.new(variables: get_object_variables(EUT, [FT::WoodPellets, EUT::Generator]))
    @end_uses[[FT::Coal, EUT::Heating]] = EndUse.new(variables: get_object_variables(EUT, [FT::Coal, EUT::Heating]))
    @end_uses[[FT::Coal, EUT::HotWater]] = EndUse.new(variables: get_object_variables(EUT, [FT::Coal, EUT::HotWater]))
    @end_uses[[FT::Coal, EUT::ClothesDryer]] = EndUse.new(variables: get_object_variables(EUT, [FT::Coal, EUT::ClothesDryer]))
    @end_uses[[FT::Coal, EUT::RangeOven]] = EndUse.new(variables: get_object_variables(EUT, [FT::Coal, EUT::RangeOven]))
    @end_uses[[FT::Coal, EUT::MechVentPreheat]] = EndUse.new(variables: get_object_variables(EUT, [FT::Coal, EUT::MechVentPreheat]))
    if @eri_design.nil? # Skip end uses not used by ERI
      @end_uses[[FT::Coal, EUT::Grill]] = EndUse.new(variables: get_object_variables(EUT, [FT::Coal, EUT::Grill]))
      @end_uses[[FT::Coal, EUT::Lighting]] = EndUse.new(variables: get_object_variables(EUT, [FT::Coal, EUT::Lighting]))
      @end_uses[[FT::Coal, EUT::Fireplace]] = EndUse.new(variables: get_object_variables(EUT, [FT::Coal, EUT::Fireplace]))
    end
    @end_uses[[FT::Coal, EUT::Generator]] = EndUse.new(variables: get_object_variables(EUT, [FT::Coal, EUT::Generator]))

    @end_uses.each do |key, end_use|
      fuel_type, end_use_type = key
      end_use.name = "End Use: #{fuel_type}: #{end_use_type}"
      end_use.annual_units = 'MBtu'
      end_use.timeseries_units = get_timeseries_units_from_fuel_type(fuel_type)
    end

    # Fuels

    @fuels = {}
    @fuels[FT::Elec] = Fuel.new(meters: ["#{EPlus::FuelTypeElectricity}:Facility"])
    @fuels[FT::Gas] = Fuel.new(meters: ["#{EPlus::FuelTypeNaturalGas}:Facility"])
    @fuels[FT::Oil] = Fuel.new(meters: ["#{EPlus::FuelTypeOil}:Facility"])
    @fuels[FT::Propane] = Fuel.new(meters: ["#{EPlus::FuelTypePropane}:Facility"])
    @fuels[FT::WoodCord] = Fuel.new(meters: ["#{EPlus::FuelTypeWoodCord}:Facility"])
    @fuels[FT::WoodPellets] = Fuel.new(meters: ["#{EPlus::FuelTypeWoodPellets}:Facility"])
    @fuels[FT::Coal] = Fuel.new(meters: ["#{EPlus::FuelTypeCoal}:Facility"])

    @fuels.each do |fuel_type, fuel|
      fuel.name = "Fuel Use: #{fuel_type}: Total"
      fuel.annual_units = 'MBtu'
      fuel.timeseries_units = get_timeseries_units_from_fuel_type(fuel_type)
      if @end_uses.select { |key, end_use| key[0] == fuel_type && end_use.variables.size > 0 }.size == 0
        fuel.meters = []
      end
    end

    # Emissions
    @emissions = {}
    emissions_scenario_names = eval(@model.getBuilding.additionalProperties.getFeatureAsString('emissions_scenario_names').get)
    emissions_scenario_types = eval(@model.getBuilding.additionalProperties.getFeatureAsString('emissions_scenario_types').get)
    emissions_scenario_names.each_with_index do |scenario_name, i|
      scenario_type = emissions_scenario_types[i]
      @emissions[[scenario_type, scenario_name]] = Emission.new()
      @emissions[[scenario_type, scenario_name]].name = "Emissions: #{scenario_type}: #{scenario_name}: Total"
      @emissions[[scenario_type, scenario_name]].annual_units = 'lb'
      @emissions[[scenario_type, scenario_name]].timeseries_units = 'lb'
    end

    # Hot Water Uses
    @hot_water_uses = {}
    @hot_water_uses[HWT::ClothesWasher] = HotWater.new(variables: get_object_variables(HWT, HWT::ClothesWasher))
    @hot_water_uses[HWT::Dishwasher] = HotWater.new(variables: get_object_variables(HWT, HWT::Dishwasher))
    @hot_water_uses[HWT::Fixtures] = HotWater.new(variables: get_object_variables(HWT, HWT::Fixtures))
    @hot_water_uses[HWT::DistributionWaste] = HotWater.new(variables: get_object_variables(HWT, HWT::DistributionWaste))

    @hot_water_uses.each do |hot_water_type, hot_water|
      hot_water.name = "Hot Water: #{hot_water_type}"
      hot_water.annual_units = 'gal'
      hot_water.timeseries_units = 'gal'
    end

    # Peak Fuels
    # Using meters for energy transferred in conditioned space only (i.e., excluding ducts) to determine winter vs summer.
    @peak_fuels = {}
    @peak_fuels[[FT::Elec, PFT::Winter]] = PeakFuel.new(meters: ["Heating:EnergyTransfer:Zone:#{HPXML::LocationLivingSpace.upcase}"], report: 'Peak Electricity Winter Total')
    @peak_fuels[[FT::Elec, PFT::Summer]] = PeakFuel.new(meters: ["Cooling:EnergyTransfer:Zone:#{HPXML::LocationLivingSpace.upcase}"], report: 'Peak Electricity Summer Total')

    @peak_fuels.each do |key, peak_fuel|
      fuel_type, peak_fuel_type = key
      peak_fuel.name = "Peak #{fuel_type}: #{peak_fuel_type} Total"
      peak_fuel.annual_units = 'W'
    end

    # Loads

    @loads = {}
    @loads[LT::Heating] = Load.new(ems_variable: 'loads_htg_tot')
    @loads[LT::Cooling] = Load.new(ems_variable: 'loads_clg_tot')
    @loads[LT::HotWaterDelivered] = Load.new(variables: get_object_variables(LT, LT::HotWaterDelivered))
    @loads[LT::HotWaterTankLosses] = Load.new(variables: get_object_variables(LT, LT::HotWaterTankLosses),
                                              is_negative: true)
    @loads[LT::HotWaterDesuperheater] = Load.new(variables: get_object_variables(LT, LT::HotWaterDesuperheater))
    @loads[LT::HotWaterSolarThermal] = Load.new(variables: get_object_variables(LT, LT::HotWaterSolarThermal),
                                                is_negative: true)

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
      comp_load.name = "Component Load: #{load_type.gsub(': Delivered', '')}: #{comp_load_type}"
      comp_load.annual_units = 'MBtu'
      comp_load.timeseries_units = 'kBtu'
    end

    # Unmet Hours
    @unmet_hours = {}
    @unmet_hours[UHT::Heating] = UnmetHours.new(col_name: 'During Heating')
    @unmet_hours[UHT::Cooling] = UnmetHours.new(col_name: 'During Cooling')

    @unmet_hours.each do |load_type, unmet_hour|
      unmet_hour.name = "Unmet Hours: #{load_type}"
      unmet_hour.annual_units = 'hr'
    end

    # Ideal System Loads (expected load that is not met by the HVAC systems)
    @ideal_system_loads = {}
    @ideal_system_loads[ILT::Heating] = IdealLoad.new(variables: get_object_variables(ILT, ILT::Heating))
    @ideal_system_loads[ILT::Cooling] = IdealLoad.new(variables: get_object_variables(ILT, ILT::Cooling))

    @ideal_system_loads.each do |load_type, ideal_load|
      ideal_load.name = "Ideal System Load: #{load_type}"
      ideal_load.annual_units = 'MBtu'
    end

    # Peak Loads
    @peak_loads = {}
    @peak_loads[PLT::Heating] = PeakLoad.new(ems_variable: 'loads_htg_tot', report: 'Peak Heating Load')
    @peak_loads[PLT::Cooling] = PeakLoad.new(ems_variable: 'loads_clg_tot', report: 'Peak Cooling Load')

    @peak_loads.each do |load_type, peak_load|
      peak_load.name = "Peak Load: #{load_type}"
      peak_load.annual_units = 'kBtu'
    end

    # Zone Temperatures

    @zone_temps = {}

    # Airflows
    @airflows = {}
    @airflows[AFT::Infiltration] = Airflow.new(ems_program: Constants.ObjectNameInfiltration + ' program', ems_variables: [(Constants.ObjectNameInfiltration + ' flow act').gsub(' ', '_')])
    @airflows[AFT::MechanicalVentilation] = Airflow.new(ems_program: Constants.ObjectNameInfiltration + ' program', ems_variables: ['Qfan'])
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

  def get_object_output_variables_by_key(model, object, class_name)
    to_ft = { EPlus::FuelTypeElectricity => FT::Elec,
              EPlus::FuelTypeNaturalGas => FT::Gas,
              EPlus::FuelTypeOil => FT::Oil,
              EPlus::FuelTypePropane => FT::Propane,
              EPlus::FuelTypeWoodCord => FT::WoodCord,
              EPlus::FuelTypeWoodPellets => FT::WoodPellets,
              EPlus::FuelTypeCoal => FT::Coal }

    # For a given object, returns the output variables to be requested and associates
    # them with the appropriate keys (e.g., [FT::Elec, EUT::Heating]).

    if class_name == EUT

      # End uses

      if object.to_CoilHeatingDXSingleSpeed.is_initialized || object.to_CoilHeatingDXMultiSpeed.is_initialized
        return { [FT::Elec, EUT::Heating] => ["Heating Coil #{EPlus::FuelTypeElectricity} Energy", "Heating Coil Crankcase Heater #{EPlus::FuelTypeElectricity} Energy", "Heating Coil Defrost #{EPlus::FuelTypeElectricity} Energy"] }

      elsif object.to_CoilHeatingElectric.is_initialized
        return { [FT::Elec, EUT::Heating] => ["Heating Coil #{EPlus::FuelTypeElectricity} Energy"] }

      elsif object.to_CoilHeatingGas.is_initialized
        fuel = object.to_CoilHeatingGas.get.fuelType
        return { [to_ft[fuel], EUT::Heating] => ["Heating Coil #{fuel} Energy"] }

      elsif object.to_CoilHeatingWaterToAirHeatPumpEquationFit.is_initialized
        return { [FT::Elec, EUT::Heating] => ["Heating Coil #{EPlus::FuelTypeElectricity} Energy"] }

      elsif object.to_ZoneHVACBaseboardConvectiveElectric.is_initialized
        return { [FT::Elec, EUT::Heating] => ["Baseboard #{EPlus::FuelTypeElectricity} Energy"] }

      elsif object.to_BoilerHotWater.is_initialized
        is_combi_boiler = false
        if object.additionalProperties.getFeatureAsBoolean('IsCombiBoiler').is_initialized
          is_combi_boiler = object.additionalProperties.getFeatureAsBoolean('IsCombiBoiler').get
        end
        if not is_combi_boiler # Exclude combi boiler, whose heating & dhw energy is handled separately via EMS
          fuel = object.to_BoilerHotWater.get.fuelType
          return { [to_ft[fuel], EUT::Heating] => ["Boiler #{fuel} Energy"] }
        end

      elsif object.to_CoilCoolingDXSingleSpeed.is_initialized || object.to_CoilCoolingDXMultiSpeed.is_initialized
        vars = { [FT::Elec, EUT::Cooling] => ["Cooling Coil #{EPlus::FuelTypeElectricity} Energy"] }
        parent = model.getAirLoopHVACUnitarySystems.select { |u| u.coolingCoil.is_initialized && u.coolingCoil.get.handle.to_s == object.handle.to_s }
        if (not parent.empty?) && parent[0].heatingCoil.is_initialized
          htg_coil = parent[0].heatingCoil.get
        end
        if parent.empty?
          parent = model.getZoneHVACPackagedTerminalAirConditioners.select { |u| u.coolingCoil.handle.to_s == object.handle.to_s }
          if not parent.empty?
            htg_coil = parent[0].heatingCoil
          end
        end
        if parent.empty?
          fail 'Could not find parent object.'
        end

        if htg_coil.nil? || (not (htg_coil.to_CoilHeatingDXSingleSpeed.is_initialized || htg_coil.to_CoilHeatingDXMultiSpeed.is_initialized))
          # Crankcase variable only available if no DX heating coil on parent
          vars[[FT::Elec, EUT::Cooling]] << "Cooling Coil Crankcase Heater #{EPlus::FuelTypeElectricity} Energy"
        end
        return vars

      elsif object.to_CoilCoolingWaterToAirHeatPumpEquationFit.is_initialized
        return { [FT::Elec, EUT::Cooling] => ["Cooling Coil #{EPlus::FuelTypeElectricity} Energy"] }

      elsif object.to_EvaporativeCoolerDirectResearchSpecial.is_initialized
        return { [FT::Elec, EUT::Cooling] => ["Evaporative Cooler #{EPlus::FuelTypeElectricity} Energy"] }

      elsif object.to_CoilWaterHeatingAirToWaterHeatPumpWrapped.is_initialized
        return { [FT::Elec, EUT::HotWater] => ["Cooling Coil Water Heating #{EPlus::FuelTypeElectricity} Energy"] }

      elsif object.to_FanSystemModel.is_initialized
        if object.name.to_s.start_with? Constants.ObjectNameWaterHeater
          return { [FT::Elec, EUT::HotWater] => ["Fan #{EPlus::FuelTypeElectricity} Energy"] }
        end

      elsif object.to_PumpConstantSpeed.is_initialized
        if object.name.to_s.start_with? Constants.ObjectNameSolarHotWater
          return { [FT::Elec, EUT::HotWaterSolarThermalPump] => ["Pump #{EPlus::FuelTypeElectricity} Energy"] }
        end

      elsif object.to_WaterHeaterMixed.is_initialized
        fuel = object.to_WaterHeaterMixed.get.heaterFuelType
        return { [to_ft[fuel], EUT::HotWater] => ["Water Heater #{fuel} Energy", "Water Heater Off Cycle Parasitic #{EPlus::FuelTypeElectricity} Energy", "Water Heater On Cycle Parasitic #{EPlus::FuelTypeElectricity} Energy"] }

      elsif object.to_WaterHeaterStratified.is_initialized
        fuel = object.to_WaterHeaterStratified.get.heaterFuelType
        return { [to_ft[fuel], EUT::HotWater] => ["Water Heater #{fuel} Energy", "Water Heater Off Cycle Parasitic #{EPlus::FuelTypeElectricity} Energy", "Water Heater On Cycle Parasitic #{EPlus::FuelTypeElectricity} Energy"] }

      elsif object.to_ExteriorLights.is_initialized
        return { [FT::Elec, EUT::LightsExterior] => ["Exterior Lights #{EPlus::FuelTypeElectricity} Energy"] }

      elsif object.to_Lights.is_initialized
        end_use = { Constants.ObjectNameInteriorLighting => EUT::LightsInterior,
                    Constants.ObjectNameGarageLighting => EUT::LightsGarage }[object.to_Lights.get.endUseSubcategory]
        return { [FT::Elec, end_use] => ["Lights #{EPlus::FuelTypeElectricity} Energy"] }

      elsif object.to_ElectricLoadCenterInverterPVWatts.is_initialized
        return { [FT::Elec, EUT::PV] => ["Inverter AC Output #{EPlus::FuelTypeElectricity} Energy"] }

      elsif object.to_GeneratorMicroTurbine.is_initialized
        fuel = object.to_GeneratorMicroTurbine.get.fuelType
        return { [FT::Elec, EUT::Generator] => ["Generator Produced AC #{EPlus::FuelTypeElectricity} Energy"],
                 [to_ft[fuel], EUT::Generator] => ["Generator #{fuel} HHV Basis Energy"] }

      elsif object.to_ElectricEquipment.is_initialized
        end_use = { Constants.ObjectNameHotWaterRecircPump => EUT::HotWaterRecircPump,
                    Constants.ObjectNameClothesWasher => EUT::ClothesWasher,
                    Constants.ObjectNameClothesDryer => EUT::ClothesDryer,
                    Constants.ObjectNameDishwasher => EUT::Dishwasher,
                    Constants.ObjectNameRefrigerator => EUT::Refrigerator,
                    Constants.ObjectNameFreezer => EUT::Freezer,
                    Constants.ObjectNameCookingRange => EUT::RangeOven,
                    Constants.ObjectNameCeilingFan => EUT::CeilingFan,
                    Constants.ObjectNameWholeHouseFan => EUT::WholeHouseFan,
                    Constants.ObjectNameMechanicalVentilation => EUT::MechVent,
                    Constants.ObjectNameMiscPlugLoads => EUT::PlugLoads,
                    Constants.ObjectNameMiscTelevision => EUT::Television,
                    Constants.ObjectNameMiscPoolHeater => EUT::PoolHeater,
                    Constants.ObjectNameMiscPoolPump => EUT::PoolPump,
                    Constants.ObjectNameMiscHotTubHeater => EUT::HotTubHeater,
                    Constants.ObjectNameMiscHotTubPump => EUT::HotTubPump,
                    Constants.ObjectNameMiscElectricVehicleCharging => EUT::Vehicle,
                    Constants.ObjectNameMiscWellPump => EUT::WellPump }[object.to_ElectricEquipment.get.endUseSubcategory]
        if not end_use.nil?
          return { [FT::Elec, end_use] => ["Electric Equipment #{EPlus::FuelTypeElectricity} Energy"] }
        end

      elsif object.to_OtherEquipment.is_initialized
        fuel = object.to_OtherEquipment.get.fuelType
        end_use = { Constants.ObjectNameClothesDryer => EUT::ClothesDryer,
                    Constants.ObjectNameCookingRange => EUT::RangeOven,
                    Constants.ObjectNameMiscGrill => EUT::Grill,
                    Constants.ObjectNameMiscLighting => EUT::Lighting,
                    Constants.ObjectNameMiscFireplace => EUT::Fireplace,
                    Constants.ObjectNameMiscPoolHeater => EUT::PoolHeater,
                    Constants.ObjectNameMiscHotTubHeater => EUT::HotTubHeater,
                    Constants.ObjectNameMechanicalVentilationPreheating => EUT::MechVentPreheat,
                    Constants.ObjectNameMechanicalVentilationPrecooling => EUT::MechVentPrecool }[object.to_OtherEquipment.get.endUseSubcategory]
        if not end_use.nil?
          return { [to_ft[fuel], end_use] => ["Other Equipment #{fuel} Energy"] }
        end

      elsif object.to_ZoneHVACDehumidifierDX.is_initialized
        return { [FT::Elec, EUT::Dehumidifier] => ["Zone Dehumidifier #{EPlus::FuelTypeElectricity} Energy"] }

      elsif object.to_EnergyManagementSystemOutputVariable.is_initialized
        if object.name.to_s.end_with? Constants.ObjectNameFanPumpDisaggregatePrimaryHeat
          return { [FT::Elec, EUT::HeatingFanPump] => [object.name.to_s] }
        elsif object.name.to_s.end_with? Constants.ObjectNameFanPumpDisaggregateBackupHeat
          return { [FT::Elec, EUT::HeatingFanPump] => [object.name.to_s] }
        elsif object.name.to_s.end_with? Constants.ObjectNameFanPumpDisaggregateCool
          return { [FT::Elec, EUT::CoolingFanPump] => [object.name.to_s] }
        elsif object.name.to_s.include? Constants.ObjectNameWaterHeaterAdjustment(nil)
          fuel = object.additionalProperties.getFeatureAsString('FuelType').get
          return { [to_ft[fuel], EUT::HotWater] => [object.name.to_s] }
        elsif object.name.to_s.include? Constants.ObjectNameCombiWaterHeatingEnergy(nil)
          fuel = object.additionalProperties.getFeatureAsString('FuelType').get
          return { [to_ft[fuel], EUT::HotWater] => [object.name.to_s] }
        elsif object.name.to_s.include? Constants.ObjectNameCombiSpaceHeatingEnergy(nil)
          fuel = object.additionalProperties.getFeatureAsString('FuelType').get
          return { [to_ft[fuel], EUT::Heating] => [object.name.to_s] }
        else
          return { ems: [object.name.to_s] }
        end

      end

    elsif class_name == HWT

      # Hot Water Use

      if object.to_WaterUseEquipment.is_initialized
        hot_water_use = { Constants.ObjectNameFixtures => HWT::Fixtures,
                          Constants.ObjectNameDistributionWaste => HWT::DistributionWaste,
                          Constants.ObjectNameClothesWasher => HWT::ClothesWasher,
                          Constants.ObjectNameDishwasher => HWT::Dishwasher }[object.to_WaterUseEquipment.get.waterUseEquipmentDefinition.endUseSubcategory]
        return { hot_water_use => ['Water Use Equipment Hot Water Volume'] }

      end

    elsif class_name == LT

      # Load

      if object.to_WaterHeaterMixed.is_initialized || object.to_WaterHeaterStratified.is_initialized
        if object.to_WaterHeaterMixed.is_initialized
          capacity = object.to_WaterHeaterMixed.get.heaterMaximumCapacity.get
        else
          capacity = object.to_WaterHeaterStratified.get.heater1Capacity.get
        end
        is_combi_boiler = false
        if object.additionalProperties.getFeatureAsBoolean('IsCombiBoiler').is_initialized
          is_combi_boiler = object.additionalProperties.getFeatureAsBoolean('IsCombiBoiler').get
        end
        if capacity == 0 && object.name.to_s.include?(Constants.ObjectNameSolarHotWater)
          return { LT::HotWaterSolarThermal => ['Water Heater Use Side Heat Transfer Energy'] }
        elsif capacity > 0 || is_combi_boiler # Active water heater only (e.g., exclude desuperheater and solar thermal storage tanks)
          return { LT::HotWaterTankLosses => ['Water Heater Heat Loss Energy'] }
        end

      elsif object.to_WaterUseConnections.is_initialized
        return { LT::HotWaterDelivered => ['Water Use Connections Plant Hot Water Energy'] }

      elsif object.to_CoilWaterHeatingDesuperheater.is_initialized
        return { LT::HotWaterDesuperheater => ['Water Heater Heating Energy'] }

      elsif object.to_CoilHeatingDXSingleSpeed.is_initialized || object.to_CoilHeatingDXMultiSpeed.is_initialized || object.to_CoilHeatingGas.is_initialized
        # Needed to apportion heating loads for dual-fuel heat pumps
        return { LT::Heating => ['Heating Coil Heating Energy'] }

      end

    elsif class_name == ILT

      # Ideal Load

      if object.to_ZoneHVACIdealLoadsAirSystem.is_initialized
        if object.name.to_s == Constants.ObjectNameIdealAirSystem
          return { ILT::Heating => ['Zone Ideal Loads Zone Sensible Heating Energy'],
                   ILT::Cooling => ['Zone Ideal Loads Zone Sensible Cooling Energy'] }
        end

      end

    end

    return {}
  end
end

# register the measure to be used by the application
ReportSimulationOutput.new.registerWithApplication
