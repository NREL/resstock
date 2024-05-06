# frozen_string_literal: true

# Require all gems up front; this is much faster than multiple resource
# files lazy loading as needed, as it prevents multiple lookups for the
# same gem.
require 'pathname'
require 'csv'
require 'oga'
Dir["#{File.dirname(__FILE__)}/resources/*.rb"].each do |resource_file|
  next if resource_file.include? 'minitest_helper.rb'

  require resource_file
end

# start the measure
class HPXMLtoOpenStudio < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    return 'HPXML to OpenStudio Translator'
  end

  # human readable description
  def description
    return 'Translates HPXML file to OpenStudio Model'
  end

  # human readable description of modeling approach
  def modeler_description
    return ''
  end

  # define the arguments that the user will input
  def arguments(model) # rubocop:disable Lint/UnusedMethodArgument
    args = OpenStudio::Measure::OSArgumentVector.new

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('hpxml_path', true)
    arg.setDisplayName('HPXML File Path')
    arg.setDescription('Absolute/relative path of the HPXML file.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('output_dir', true)
    arg.setDisplayName('Directory for Output Files')
    arg.setDescription('Absolute/relative path for the output files directory.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeBoolArgument('debug', false)
    arg.setDisplayName('Debug Mode?')
    arg.setDescription('If true: 1) Writes in.osm file, 2) Generates additional log output, and 3) Creates all EnergyPlus output files.')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeBoolArgument('add_component_loads', false)
    arg.setDisplayName('Add component loads?')
    arg.setDescription('If true, adds the calculation of heating/cooling component loads (not enabled by default for faster performance).')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeBoolArgument('skip_validation', false)
    arg.setDisplayName('Skip Validation?')
    arg.setDescription('If true, bypasses HPXML input validation for faster performance. WARNING: This should only be used if the supplied HPXML file has already been validated against the Schema & Schematron documents.')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('building_id', false)
    arg.setDisplayName('BuildingID')
    arg.setDescription('The ID of the HPXML Building. Only required if the HPXML has multiple Building elements and WholeSFAorMFBuildingSimulation is not true.')
    args << arg

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    Geometry.tear_down_model(model, runner)

    Version.check_openstudio_version()

    # assign the user inputs to variables
    hpxml_path = runner.getStringArgumentValue('hpxml_path', user_arguments)
    output_dir = runner.getStringArgumentValue('output_dir', user_arguments)
    add_component_loads = runner.getBoolArgumentValue('add_component_loads', user_arguments)
    debug = runner.getBoolArgumentValue('debug', user_arguments)
    skip_validation = runner.getBoolArgumentValue('skip_validation', user_arguments)
    building_id = runner.getOptionalStringArgumentValue('building_id', user_arguments)
    building_id = building_id.is_initialized ? building_id.get : nil

    unless (Pathname.new hpxml_path).absolute?
      hpxml_path = File.expand_path(hpxml_path)
    end
    unless File.exist?(hpxml_path) && hpxml_path.downcase.end_with?('.xml')
      fail "'#{hpxml_path}' does not exist or is not an .xml file."
    end

    unless (Pathname.new output_dir).absolute?
      output_dir = File.expand_path(output_dir)
    end

    begin
      if skip_validation
        schema_validator = nil
        schematron_validator = nil
      else
        schema_path = File.join(File.dirname(__FILE__), 'resources', 'hpxml_schema', 'HPXML.xsd')
        schema_validator = XMLValidator.get_schema_validator(schema_path)
        schematron_path = File.join(File.dirname(__FILE__), 'resources', 'hpxml_schematron', 'EPvalidator.xml')
        schematron_validator = XMLValidator.get_schematron_validator(schematron_path)
      end

      hpxml = HPXML.new(hpxml_path: hpxml_path, schema_validator: schema_validator, schematron_validator: schematron_validator, building_id: building_id)
      hpxml.errors.each do |error|
        runner.registerError(error)
      end
      hpxml.warnings.each do |warning|
        runner.registerWarning(warning)
      end
      return false unless hpxml.errors.empty?

      eri_version = hpxml.header.eri_calculation_version # Hidden feature
      eri_version = 'latest' if eri_version.nil?
      eri_version = Constants.ERIVersions[-1] if eri_version == 'latest'

      # Process weather once upfront
      epw_path = Location.get_epw_path(hpxml.buildings[0], hpxml_path)
      weather = WeatherProcess.new(epw_path: epw_path, runner: runner, hpxml: hpxml)
      epw_file = OpenStudio::EpwFile.new(epw_path)
      hpxml.buildings.each_with_index do |hpxml_bldg, i|
        next if i == 0
        next if Location.get_epw_path(hpxml_bldg, hpxml_path) == epw_path

        fail 'Weather station EPW filepath has different values across dwelling units.'
      end

      if hpxml.header.whole_sfa_or_mf_building_sim && (hpxml.buildings.size > 1)
        if hpxml.buildings.map { |hpxml_bldg| hpxml_bldg.batteries.size }.sum > 0
          # FUTURE: Figure out how to allow this. If we allow it, update docs and hpxml_translator_test.rb too.
          # Batteries use "TrackFacilityElectricDemandStoreExcessOnSite"; to support modeling of batteries in whole
          # SFA/MF building simulations, we'd need to create custom meters with electricity usage *for each unit*
          # and switch to "TrackMeterDemandStoreExcessOnSite".
          # https://github.com/NREL/OpenStudio-HPXML/issues/1499
          fail 'Modeling batteries for whole SFA/MF buildings is not currently supported.'
        end
      end

      # Apply HPXML defaults upfront; process schedules & emissions
      hpxml_sch_map = {}
      check_emissions_references(hpxml.header, hpxml_path)
      hpxml.buildings.each_with_index do |hpxml_bldg, i|
        check_schedule_references(hpxml_bldg.header, hpxml_path)
        in_schedules_csv = 'in.schedules.csv'
        in_schedules_csv = "in.schedules#{i + 1}.csv" if i > 0
        schedules_file = SchedulesFile.new(runner: runner,
                                           schedules_paths: hpxml_bldg.header.schedules_filepaths,
                                           year: Location.get_sim_calendar_year(hpxml.header.sim_calendar_year, epw_file),
                                           unavailable_periods: hpxml.header.unavailable_periods,
                                           output_path: File.join(output_dir, in_schedules_csv))
        HPXMLDefaults.apply(runner, hpxml, hpxml_bldg, eri_version, weather, epw_file: epw_file, schedules_file: schedules_file)
        hpxml_sch_map[hpxml_bldg] = schedules_file
      end
      validate_emissions_files(hpxml.header)

      # Write updated HPXML object (w/ defaults) to file for inspection
      hpxml_defaults_path = File.join(output_dir, 'in.xml')
      XMLHelper.write_file(hpxml.to_doc, hpxml_defaults_path)

      # Create OpenStudio model
      hpxml_osm_map = {}
      hpxml.buildings.each_with_index do |hpxml_bldg, i|
        schedules_file = hpxml_sch_map[hpxml_bldg]
        if hpxml.buildings.size > 1
          # Create the model for this single unit
          unit_model = OpenStudio::Model::Model.new
          create_unit_model(hpxml, hpxml_bldg, runner, unit_model, epw_path, epw_file, weather, debug, schedules_file, eri_version, i + 1)
          hpxml_osm_map[hpxml_bldg] = unit_model
        else
          create_unit_model(hpxml, hpxml_bldg, runner, model, epw_path, epw_file, weather, debug, schedules_file, eri_version, i + 1)
          hpxml_osm_map[hpxml_bldg] = model
        end
      end

      # Merge unit models into final model
      if hpxml.buildings.size > 1
        add_unit_model_to_model(model, hpxml_osm_map)
      end

      # Output
      add_unmet_hours_output(model, hpxml_osm_map)
      add_loads_output(model, add_component_loads, hpxml_osm_map)
      set_output_files(model)
      add_additional_properties(model, hpxml, hpxml_osm_map, hpxml_path, building_id, hpxml_defaults_path)
      # Uncomment to debug EMS
      # add_ems_debug_output(model)

      if debug
        # Write OSM file to run dir
        osm_output_path = File.join(output_dir, 'in.osm')
        File.write(osm_output_path, model.to_s)
        runner.registerInfo("Wrote file: #{osm_output_path}")

        # Copy EPW file to run dir
        epw_output_path = File.join(output_dir, 'in.epw')
        FileUtils.cp(epw_path, epw_output_path)
      end
    rescue Exception => e
      runner.registerError("#{e.message}\n#{e.backtrace.join("\n")}")
      return false
    end

    return true
  end

  def add_unit_model_to_model(model, hpxml_osm_map)
    unique_objects = { 'OS:ConvergenceLimits' => 'ConvergenceLimits',
                       'OS:Foundation:Kiva:Settings' => 'FoundationKivaSettings',
                       'OS:OutputControl:Files' => 'OutputControlFiles',
                       'OS:Output:Diagnostics' => 'OutputDiagnostics',
                       'OS:Output:JSON' => 'OutputJSON',
                       'OS:PerformancePrecisionTradeoffs' => 'PerformancePrecisionTradeoffs',
                       'OS:RunPeriod' => 'RunPeriod',
                       'OS:RunPeriodControl:DaylightSavingTime' => 'RunPeriodControlDaylightSavingTime',
                       'OS:ShadowCalculation' => 'ShadowCalculation',
                       'OS:SimulationControl' => 'SimulationControl',
                       'OS:Site' => 'Site',
                       'OS:Site:GroundTemperature:Deep' => 'SiteGroundTemperatureDeep',
                       'OS:Site:GroundTemperature:Shallow' => 'SiteGroundTemperatureShallow',
                       'OS:Site:WaterMainsTemperature' => 'SiteWaterMainsTemperature',
                       'OS:SurfaceConvectionAlgorithm:Inside' => 'InsideSurfaceConvectionAlgorithm',
                       'OS:SurfaceConvectionAlgorithm:Outside' => 'OutsideSurfaceConvectionAlgorithm',
                       'OS:Timestep' => 'Timestep' }

    # Handle unique objects first: Grab one from the first model we find the
    # object on (may not be the first unit).
    unit_model_objects = []
    unique_handles_to_skip = []
    uuid_regex = /\{(.*?)\}/
    unique_objects.each do |idd_obj, osm_class|
      first_model_object_by_type = nil
      hpxml_osm_map.values.each do |unit_model|
        next if unit_model.getObjectsByType(idd_obj.to_IddObjectType).empty?

        model_object = unit_model.send("get#{osm_class}")

        if first_model_object_by_type.nil?
          # Retain object for model
          unit_model_objects << model_object
          first_model_object_by_type = model_object
          if idd_obj == 'OS:Site:WaterMainsTemperature' # Handle referenced child object too
            unit_model_objects << unit_model.getObjectsByName(model_object.temperatureSchedule.get.name.to_s)[0]
          end
        else
          # Throw error if different values between this model_object and first_model_object_by_type
          if model_object.to_s.gsub(uuid_regex, '') != first_model_object_by_type.to_s.gsub(uuid_regex, '')
            fail "Unique object (#{idd_obj}) has different values across dwelling units."
          end

          if idd_obj == 'OS:Site:WaterMainsTemperature' # Handle referenced child object too
            if model_object.temperatureSchedule.get.to_s.gsub(uuid_regex, '') != first_model_object_by_type.temperatureSchedule.get.to_s.gsub(uuid_regex, '')
              fail "Unique object (#{idd_obj}) has different values across dwelling units."
            end
          end
        end

        unique_handles_to_skip << model_object.handle.to_s
        if idd_obj == 'OS:Site:WaterMainsTemperature' # Handle referenced child object too
          unique_handles_to_skip << model_object.temperatureSchedule.get.handle.to_s
        end
      end
    end

    hpxml_osm_map.values.each_with_index do |unit_model, unit_number|
      shift_geometry(unit_model, unit_number)
      prefix_all_unit_model_objects(unit_model, unit_number)

      # Handle remaining (non-unique) objects now
      unit_model.objects.each do |obj|
        next if unit_number > 0 && obj.to_Building.is_initialized
        next if unique_handles_to_skip.include? obj.handle.to_s

        unit_model_objects << obj
      end
    end

    model.addObjects(unit_model_objects, true)
  end

  def shift_geometry(unit_model, unit_number)
    # Shift units so they aren't right on top and shade each other
    y_shift = 200.0 * unit_number # meters

    # shift the unit so it's not right on top of the previous one
    unit_model.getSpaces.sort.each do |space|
      space.setYOrigin(y_shift)
    end

    # shift shading surfaces
    m = OpenStudio::Matrix.new(4, 4, 0)
    m[0, 0] = 1
    m[1, 1] = 1
    m[2, 2] = 1
    m[3, 3] = 1
    m[1, 3] = y_shift
    t = OpenStudio::Transformation.new(m)

    unit_model.getShadingSurfaceGroups.each do |shading_surface_group|
      next if shading_surface_group.space.is_initialized # already got shifted

      shading_surface_group.shadingSurfaces.each do |shading_surface|
        shading_surface.setVertices(t * shading_surface.vertices)
      end
    end
  end

  def prefix_all_unit_model_objects(unit_model, unit_number)
    # Prefix all objects with name using unit number
    # FUTURE: Create objects with unique names up front so we don't have to do this

    # EMS objects
    ems_map = {}

    unit_model.getEnergyManagementSystemSensors.each do |sensor|
      ems_map[sensor.name.to_s] = make_variable_name(sensor.name, unit_number)
      sensor.setKeyName(make_variable_name(sensor.keyName, unit_number)) unless sensor.keyName.empty? || sensor.keyName.downcase == 'environment'
    end

    unit_model.getEnergyManagementSystemActuators.each do |actuator|
      ems_map[actuator.name.to_s] = make_variable_name(actuator.name, unit_number)
    end

    unit_model.getEnergyManagementSystemInternalVariables.each do |internal_variable|
      ems_map[internal_variable.name.to_s] = make_variable_name(internal_variable.name, unit_number)
      internal_variable.setInternalDataIndexKeyName(make_variable_name(internal_variable.internalDataIndexKeyName, unit_number)) unless internal_variable.internalDataIndexKeyName.empty?
    end

    unit_model.getEnergyManagementSystemGlobalVariables.each do |global_variable|
      ems_map[global_variable.name.to_s] = make_variable_name(global_variable.name, unit_number)
    end

    unit_model.getEnergyManagementSystemOutputVariables.each do |output_variable|
      next if output_variable.emsVariableObject.is_initialized

      new_ems_variable_name = make_variable_name(output_variable.emsVariableName, unit_number)
      ems_map[output_variable.emsVariableName.to_s] = new_ems_variable_name
      output_variable.setEMSVariableName(new_ems_variable_name)
    end

    unit_model.getEnergyManagementSystemSubroutines.each do |subroutine|
      ems_map[subroutine.name.to_s] = make_variable_name(subroutine.name, unit_number)
    end

    # variables in program lines don't get updated automatically
    lhs_characters = [' ', ',', '(', ')', '+', '-', '*', '/', ';']
    rhs_characters = [''] + lhs_characters
    (unit_model.getEnergyManagementSystemPrograms + unit_model.getEnergyManagementSystemSubroutines).each do |program|
      new_lines = []
      program.lines.each do |line|
        ems_map.each do |old_name, new_name|
          next unless line.include?(old_name)

          # old_name between at least 1 character, with the exception of '' on left and ' ' on right
          lhs_characters.each do |lhs|
            next unless line.include?("#{lhs}#{old_name}")

            rhs_characters.each do |rhs|
              next unless line.include?("#{lhs}#{old_name}#{rhs}")
              next if lhs == '' && ['', ' '].include?(rhs)

              line.gsub!("#{lhs}#{old_name}#{rhs}", "#{lhs}#{new_name}#{rhs}")
            end
          end
        end
        new_lines << line
      end
      program.setLines(new_lines)
    end

    # All model objects
    unit_model.objects.each do |model_object|
      next if model_object.name.nil?

      if unit_number == 0
        # OpenStudio is unhappy if these schedules are renamed
        next if model_object.name.to_s == unit_model.alwaysOnContinuousSchedule.name.to_s
        next if model_object.name.to_s == unit_model.alwaysOnDiscreteSchedule.name.to_s
        next if model_object.name.to_s == unit_model.alwaysOffDiscreteSchedule.name.to_s
      end

      model_object.setName(make_variable_name(model_object.name, unit_number))
    end
  end

  def make_variable_name(obj_name, unit_number)
    return "unit#{unit_number + 1}_#{obj_name}".gsub(' ', '_').gsub('-', '_')
  end

  def create_unit_model(hpxml, hpxml_bldg, runner, model, epw_path, epw_file, weather, debug, schedules_file, eri_version, unit_num)
    @hpxml_header = hpxml.header
    @hpxml_bldg = hpxml_bldg
    @debug = debug
    @schedules_file = schedules_file
    @eri_version = eri_version

    @apply_ashrae140_assumptions = @hpxml_header.apply_ashrae140_assumptions # Hidden feature
    @apply_ashrae140_assumptions = false if @apply_ashrae140_assumptions.nil?

    # Here we turn off OS error-checking so that any invalid values provided
    # to OS SDK methods are passed along to EnergyPlus and produce errors. If
    # we didn't go this, we'd end up with successful EnergyPlus simulations that
    # use the wrong (default) value unless we check the return value of *every*
    # OS SDK setter method to notice there was an invalid value provided.
    # See https://github.com/NREL/OpenStudio/pull/4505 for more background.
    model.setStrictnessLevel('None'.to_StrictnessLevel)

    # Init
    OpenStudio::Model::WeatherFile.setWeatherFile(model, epw_file)
    set_defaults_and_globals()
    Location.apply(model, weather, epw_file, @hpxml_header, @hpxml_bldg)
    add_simulation_params(model)

    # Conditioned space/zone
    spaces = {}
    create_or_get_space(model, spaces, HPXML::LocationConditionedSpace)
    set_foundation_and_walls_top()
    set_heating_and_cooling_seasons()
    add_setpoints(runner, model, weather, spaces)

    # Geometry/Envelope
    add_roofs(runner, model, spaces)
    add_walls(runner, model, spaces)
    add_rim_joists(runner, model, spaces)
    add_floors(runner, model, spaces)
    add_foundation_walls_slabs(runner, model, weather, spaces)
    add_windows(model, spaces)
    add_doors(model, spaces)
    add_skylights(model, spaces)
    add_conditioned_floor_area(model, spaces)
    add_thermal_mass(model, spaces)
    Geometry.set_zone_volumes(spaces, @hpxml_bldg, @apply_ashrae140_assumptions)
    Geometry.explode_surfaces(model, @hpxml_bldg, @walls_top)
    add_num_occupants(model, runner, spaces)

    # HVAC
    @hvac_unavailable_periods = Schedule.get_unavailable_periods(runner, SchedulesFile::Columns[:HVAC].name, @hpxml_header.unavailable_periods)
    airloop_map = {} # Map of HPXML System ID -> AirLoopHVAC (or ZoneHVACFourPipeFanCoil)
    add_ideal_system(model, spaces, epw_path)
    add_cooling_system(model, runner, weather, spaces, airloop_map)
    add_heating_system(runner, model, weather, spaces, airloop_map)
    add_heat_pump(runner, model, weather, spaces, airloop_map)
    add_dehumidifiers(runner, model, spaces)
    add_ceiling_fans(runner, model, weather, spaces)

    # Hot Water
    add_hot_water_and_appliances(runner, model, weather, spaces)

    # Plug Loads & Fuel Loads & Lighting
    add_mels(runner, model, spaces)
    add_mfls(runner, model, spaces)
    add_lighting(runner, model, spaces)

    # Pools & Permanent Spas
    add_pools_and_permanent_spas(runner, model, spaces)

    # Other
    add_cooling_season(model, weather)
    add_airflow(runner, model, weather, spaces, airloop_map)
    add_photovoltaics(model)
    add_generators(model)
    add_batteries(runner, model, spaces)
    add_building_unit(model, unit_num)
  end

  def check_emissions_references(hpxml_header, hpxml_path)
    # Check/update file references
    hpxml_header.emissions_scenarios.each do |scenario|
      if hpxml_header.emissions_scenarios.select { |s| s.emissions_type == scenario.emissions_type && s.name == scenario.name }.size > 1
        fail "Found multiple Emissions Scenarios with the Scenario Name=#{scenario.name} and Emissions Type=#{scenario.emissions_type}."
      end
      next if scenario.elec_schedule_filepath.nil?

      scenario.elec_schedule_filepath = FilePath.check_path(scenario.elec_schedule_filepath,
                                                            File.dirname(hpxml_path),
                                                            'Emissions File')
    end
  end

  def check_schedule_references(hpxml_bldg_header, hpxml_path)
    # Check/update file references
    hpxml_bldg_header.schedules_filepaths = hpxml_bldg_header.schedules_filepaths.collect { |sfp|
      FilePath.check_path(sfp,
                          File.dirname(hpxml_path),
                          'Schedules')
    }
  end

  def validate_emissions_files(hpxml_header)
    hpxml_header.emissions_scenarios.each do |scenario|
      next if scenario.elec_schedule_filepath.nil?

      data = File.readlines(scenario.elec_schedule_filepath)
      num_header_rows = scenario.elec_schedule_number_of_header_rows
      col_index = scenario.elec_schedule_column_number - 1

      if data.size != 8760 + num_header_rows
        fail "Emissions File has invalid number of rows (#{data.size}). Expected 8760 plus #{num_header_rows} header row(s)."
      end
      if col_index > data[num_header_rows, 8760].map { |x| x.count(',') }.min
        fail "Emissions File has too few columns. Cannot find column number (#{scenario.elec_schedule_column_number})."
      end
    end
  end

  def set_defaults_and_globals()
    # Initialize
    @remaining_heat_load_frac = 1.0
    @remaining_cool_load_frac = 1.0

    # Set globals
    @cfa = @hpxml_bldg.building_construction.conditioned_floor_area
    @ncfl = @hpxml_bldg.building_construction.number_of_conditioned_floors
    @ncfl_ag = @hpxml_bldg.building_construction.number_of_conditioned_floors_above_grade
    @nbeds = @hpxml_bldg.building_construction.number_of_bedrooms
    @default_azimuths = HPXMLDefaults.get_default_azimuths(@hpxml_bldg)

    # Apply unit multipliers to HVAC systems and water heaters
    HVAC.apply_unit_multiplier(@hpxml_bldg)
    # Ensure that no capacities/airflows are zero in order to prevent potential E+ errors.
    HVAC.ensure_nonzero_sizing_values(@hpxml_bldg)
    # Make adjustments for modeling purposes
    @frac_windows_operable = @hpxml_bldg.fraction_of_windows_operable()
    @hpxml_bldg.collapse_enclosure_surfaces() # Speeds up simulation
    @hpxml_bldg.delete_adiabatic_subsurfaces() # EnergyPlus doesn't allow this

    # We don't want this to be written to in.xml, because then if you ran the in.xml
    # file, you would get different results (operational calculation) relative to the
    # original file (asset calculation).
    if @hpxml_bldg.building_occupancy.number_of_residents.nil?
      @hpxml_bldg.building_occupancy.number_of_residents = Geometry.get_occupancy_default_num(@nbeds)
    elsif (@hpxml_bldg.building_occupancy.number_of_residents == 0) && (not @apply_ashrae140_assumptions)
      # If zero occupants, ensure end uses of interest are zeroed out
      @hpxml_header.unavailable_periods.add(column_name: 'Vacancy',
                                            begin_month: @hpxml_header.sim_begin_month,
                                            begin_day: @hpxml_header.sim_begin_day,
                                            begin_hour: 0,
                                            end_month: @hpxml_header.sim_end_month,
                                            end_day: @hpxml_header.sim_end_day,
                                            end_hour: 24,
                                            natvent_availability: HPXML::ScheduleUnavailable)
    end
  end

  def add_simulation_params(model)
    SimControls.apply(model, @hpxml_header)
  end

  def add_num_occupants(model, runner, spaces)
    # Occupants
    num_occ = @hpxml_bldg.building_occupancy.number_of_residents
    return if num_occ <= 0

    Geometry.apply_occupants(model, runner, @hpxml_bldg, num_occ, spaces[HPXML::LocationConditionedSpace],
                             @schedules_file, @hpxml_header.unavailable_periods)
  end

  def create_or_get_space(model, spaces, location)
    if spaces[location].nil?
      Geometry.create_space_and_zone(model, spaces, location, @hpxml_bldg.building_construction.number_of_units)
    end
    return spaces[location]
  end

  def add_roofs(runner, model, spaces)
    @hpxml_bldg.roofs.each do |roof|
      next if roof.net_area < 1.0 # skip modeling net surface area for surfaces comprised entirely of subsurface area

      if roof.azimuth.nil?
        if roof.pitch > 0
          azimuths = @default_azimuths # Model as four directions for average exterior incident solar
        else
          azimuths = [@default_azimuths[0]] # Arbitrary azimuth for flat roof
        end
      else
        azimuths = [roof.azimuth]
      end

      surfaces = []

      azimuths.each do |azimuth|
        width = Math::sqrt(roof.net_area)
        length = (roof.net_area / width) / azimuths.size
        tilt = roof.pitch / 12.0
        z_origin = @walls_top + 0.5 * Math.sin(Math.atan(tilt)) * width

        vertices = Geometry.create_roof_vertices(length, width, z_origin, azimuth, tilt)
        surface = OpenStudio::Model::Surface.new(vertices, model)
        surfaces << surface
        surface.additionalProperties.setFeature('Length', length)
        surface.additionalProperties.setFeature('Width', width)
        surface.additionalProperties.setFeature('Azimuth', azimuth)
        surface.additionalProperties.setFeature('Tilt', tilt)
        surface.additionalProperties.setFeature('SurfaceType', 'Roof')
        if azimuths.size > 1
          surface.setName("#{roof.id}:#{azimuth}")
        else
          surface.setName(roof.id)
        end
        surface.setSurfaceType('RoofCeiling')
        surface.setOutsideBoundaryCondition('Outdoors')
        set_surface_interior(model, spaces, surface, roof)
      end

      next if surfaces.empty?

      # Apply construction
      has_radiant_barrier = roof.radiant_barrier
      if has_radiant_barrier
        radiant_barrier_grade = roof.radiant_barrier_grade
      end
      # FUTURE: Create Constructions.get_air_film(surface) method; use in measure.rb and hpxml_translator_test.rb
      inside_film = Material.AirFilmRoof(Geometry.get_roof_pitch([surfaces[0]]))
      outside_film = Material.AirFilmOutside
      mat_roofing = Material.RoofMaterial(roof.roof_type)
      if @apply_ashrae140_assumptions
        inside_film = Material.AirFilmRoofASHRAE140
        outside_film = Material.AirFilmOutsideASHRAE140
      end
      mat_int_finish = Material.InteriorFinishMaterial(roof.interior_finish_type, roof.interior_finish_thickness)
      if mat_int_finish.nil?
        fallback_mat_int_finish = nil
      else
        fallback_mat_int_finish = Material.InteriorFinishMaterial(mat_int_finish.name, 0.1) # Try thin material
      end

      install_grade = 1
      assembly_r = roof.insulation_assembly_r_value

      if not mat_int_finish.nil?
        # Closed cavity
        constr_sets = [
          WoodStudConstructionSet.new(Material.Stud2x(8.0), 0.07, 20.0, 0.75, mat_int_finish, mat_roofing),    # 2x8, 24" o.c. + R20
          WoodStudConstructionSet.new(Material.Stud2x(8.0), 0.07, 10.0, 0.75, mat_int_finish, mat_roofing),    # 2x8, 24" o.c. + R10
          WoodStudConstructionSet.new(Material.Stud2x(8.0), 0.07, 0.0, 0.75, mat_int_finish, mat_roofing),     # 2x8, 24" o.c.
          WoodStudConstructionSet.new(Material.Stud2x6, 0.07, 0.0, 0.75, mat_int_finish, mat_roofing),         # 2x6, 24" o.c.
          WoodStudConstructionSet.new(Material.Stud2x4, 0.07, 0.0, 0.5, mat_int_finish, mat_roofing),          # 2x4, 16" o.c.
          WoodStudConstructionSet.new(Material.Stud2x4, 0.01, 0.0, 0.0, fallback_mat_int_finish, mat_roofing), # Fallback
        ]
        match, constr_set, cavity_r = Constructions.pick_wood_stud_construction_set(assembly_r, constr_sets, inside_film, outside_film)

        Constructions.apply_closed_cavity_roof(model, surfaces, "#{roof.id} construction",
                                               cavity_r, install_grade,
                                               constr_set.stud.thick_in,
                                               true, constr_set.framing_factor,
                                               constr_set.mat_int_finish,
                                               constr_set.osb_thick_in, constr_set.rigid_r,
                                               constr_set.mat_ext_finish, has_radiant_barrier,
                                               inside_film, outside_film, radiant_barrier_grade,
                                               roof.solar_absorptance, roof.emittance)
      else
        # Open cavity
        constr_sets = [
          GenericConstructionSet.new(10.0, 0.5, nil, mat_roofing), # w/R-10 rigid
          GenericConstructionSet.new(0.0, 0.5, nil, mat_roofing),  # Standard
          GenericConstructionSet.new(0.0, 0.0, nil, mat_roofing),  # Fallback
        ]
        match, constr_set, layer_r = Constructions.pick_generic_construction_set(assembly_r, constr_sets, inside_film, outside_film)

        cavity_r = 0
        cavity_ins_thick_in = 0
        framing_factor = 0
        framing_thick_in = 0

        Constructions.apply_open_cavity_roof(model, surfaces, "#{roof.id} construction",
                                             cavity_r, install_grade, cavity_ins_thick_in,
                                             framing_factor, framing_thick_in,
                                             constr_set.osb_thick_in, layer_r + constr_set.rigid_r,
                                             constr_set.mat_ext_finish, has_radiant_barrier,
                                             inside_film, outside_film, radiant_barrier_grade,
                                             roof.solar_absorptance, roof.emittance)
      end
      Constructions.check_surface_assembly_rvalue(runner, surfaces, inside_film, outside_film, assembly_r, match)
    end
  end

  def add_walls(runner, model, spaces)
    @hpxml_bldg.walls.each do |wall|
      next if wall.net_area < 1.0 # skip modeling net surface area for surfaces comprised entirely of subsurface area

      if wall.azimuth.nil?
        if wall.is_exterior
          azimuths = @default_azimuths # Model as four directions for average exterior incident solar
        else
          azimuths = [@default_azimuths[0]] # Arbitrary direction, doesn't receive exterior incident solar
        end
      else
        azimuths = [wall.azimuth]
      end

      surfaces = []

      azimuths.each do |azimuth|
        height = 8.0 * @ncfl_ag
        length = (wall.net_area / height) / azimuths.size
        z_origin = @foundation_top

        vertices = Geometry.create_wall_vertices(length, height, z_origin, azimuth)
        surface = OpenStudio::Model::Surface.new(vertices, model)
        surfaces << surface
        surface.additionalProperties.setFeature('Length', length)
        surface.additionalProperties.setFeature('Azimuth', azimuth)
        surface.additionalProperties.setFeature('Tilt', 90.0)
        surface.additionalProperties.setFeature('SurfaceType', 'Wall')
        if azimuths.size > 1
          surface.setName("#{wall.id}:#{azimuth}")
        else
          surface.setName(wall.id)
        end
        surface.setSurfaceType('Wall')
        set_surface_interior(model, spaces, surface, wall)
        set_surface_exterior(model, spaces, surface, wall)
        if wall.is_interior
          surface.setSunExposure('NoSun')
          surface.setWindExposure('NoWind')
        end
      end

      next if surfaces.empty?

      # Apply construction
      # The code below constructs a reasonable wall construction based on the
      # wall type while ensuring the correct assembly R-value.
      has_radiant_barrier = wall.radiant_barrier
      if has_radiant_barrier
        radiant_barrier_grade = wall.radiant_barrier_grade
      end
      inside_film = Material.AirFilmVertical
      if wall.is_exterior
        outside_film = Material.AirFilmOutside
        mat_ext_finish = Material.ExteriorFinishMaterial(wall.siding)
      else
        outside_film = Material.AirFilmVertical
        mat_ext_finish = nil
      end
      if @apply_ashrae140_assumptions
        inside_film = Material.AirFilmVerticalASHRAE140
        outside_film = Material.AirFilmOutsideASHRAE140
      end
      mat_int_finish = Material.InteriorFinishMaterial(wall.interior_finish_type, wall.interior_finish_thickness)

      Constructions.apply_wall_construction(runner, model, surfaces, wall.id, wall.wall_type, wall.insulation_assembly_r_value,
                                            mat_int_finish, has_radiant_barrier, inside_film, outside_film,
                                            radiant_barrier_grade, mat_ext_finish, wall.solar_absorptance,
                                            wall.emittance)
    end
  end

  def add_rim_joists(runner, model, spaces)
    @hpxml_bldg.rim_joists.each do |rim_joist|
      if rim_joist.azimuth.nil?
        if rim_joist.is_exterior
          azimuths = @default_azimuths # Model as four directions for average exterior incident solar
        else
          azimuths = [@default_azimuths[0]] # Arbitrary direction, doesn't receive exterior incident solar
        end
      else
        azimuths = [rim_joist.azimuth]
      end

      surfaces = []

      azimuths.each do |azimuth|
        height = 1.0
        length = (rim_joist.area / height) / azimuths.size
        z_origin = @foundation_top

        vertices = Geometry.create_wall_vertices(length, height, z_origin, azimuth)
        surface = OpenStudio::Model::Surface.new(vertices, model)
        surfaces << surface
        surface.additionalProperties.setFeature('Length', length)
        surface.additionalProperties.setFeature('Azimuth', azimuth)
        surface.additionalProperties.setFeature('Tilt', 90.0)
        surface.additionalProperties.setFeature('SurfaceType', 'RimJoist')
        if azimuths.size > 1
          surface.setName("#{rim_joist.id}:#{azimuth}")
        else
          surface.setName(rim_joist.id)
        end
        surface.setSurfaceType('Wall')
        set_surface_interior(model, spaces, surface, rim_joist)
        set_surface_exterior(model, spaces, surface, rim_joist)
        if rim_joist.is_interior
          surface.setSunExposure('NoSun')
          surface.setWindExposure('NoWind')
        end
      end

      # Apply construction

      inside_film = Material.AirFilmVertical
      if rim_joist.is_exterior
        outside_film = Material.AirFilmOutside
        mat_ext_finish = Material.ExteriorFinishMaterial(rim_joist.siding)
      else
        outside_film = Material.AirFilmVertical
        mat_ext_finish = nil
      end

      assembly_r = rim_joist.insulation_assembly_r_value

      constr_sets = [
        WoodStudConstructionSet.new(Material.Stud2x(2.0), 0.17, 20.0, 2.0, nil, mat_ext_finish),  # 2x4 + R20
        WoodStudConstructionSet.new(Material.Stud2x(2.0), 0.17, 10.0, 2.0, nil, mat_ext_finish),  # 2x4 + R10
        WoodStudConstructionSet.new(Material.Stud2x(2.0), 0.17, 0.0, 2.0, nil, mat_ext_finish),   # 2x4
        WoodStudConstructionSet.new(Material.Stud2x(2.0), 0.01, 0.0, 0.0, nil, mat_ext_finish),   # Fallback
      ]
      match, constr_set, cavity_r = Constructions.pick_wood_stud_construction_set(assembly_r, constr_sets, inside_film, outside_film)
      install_grade = 1

      Constructions.apply_rim_joist(model, surfaces, "#{rim_joist.id} construction",
                                    cavity_r, install_grade, constr_set.framing_factor,
                                    constr_set.mat_int_finish, constr_set.osb_thick_in,
                                    constr_set.rigid_r, constr_set.mat_ext_finish,
                                    inside_film, outside_film, rim_joist.solar_absorptance,
                                    rim_joist.emittance)
      Constructions.check_surface_assembly_rvalue(runner, surfaces, inside_film, outside_film, assembly_r, match)
    end
  end

  def add_floors(runner, model, spaces)
    @hpxml_bldg.floors.each do |floor|
      area = floor.area
      width = Math::sqrt(area)
      length = area / width
      if floor.interior_adjacent_to.include?('attic') || floor.exterior_adjacent_to.include?('attic')
        z_origin = @walls_top
      else
        z_origin = @foundation_top
      end

      if floor.is_ceiling
        vertices = Geometry.create_ceiling_vertices(length, width, z_origin, @default_azimuths)
        surface = OpenStudio::Model::Surface.new(vertices, model)
        surface.additionalProperties.setFeature('SurfaceType', 'Ceiling')
      else
        vertices = Geometry.create_floor_vertices(length, width, z_origin, @default_azimuths)
        surface = OpenStudio::Model::Surface.new(vertices, model)
        surface.additionalProperties.setFeature('SurfaceType', 'Floor')
      end
      surface.additionalProperties.setFeature('Tilt', 0.0)
      set_surface_interior(model, spaces, surface, floor)
      set_surface_exterior(model, spaces, surface, floor)
      surface.setName(floor.id)
      if floor.is_interior
        surface.setSunExposure('NoSun')
        surface.setWindExposure('NoWind')
      elsif floor.is_floor
        surface.setSunExposure('NoSun')
        if floor.exterior_adjacent_to == HPXML::LocationManufacturedHomeUnderBelly
          foundation = @hpxml_bldg.foundations.find { |x| x.to_location == floor.exterior_adjacent_to }
          if foundation.belly_wing_skirt_present
            surface.setWindExposure('NoWind')
          end
        end
      end

      # Apply construction

      if floor.is_ceiling
        if @apply_ashrae140_assumptions
          # Attic floor
          inside_film = Material.AirFilmFloorASHRAE140
          outside_film = Material.AirFilmFloorASHRAE140
        else
          inside_film = Material.AirFilmFloorAverage
          outside_film = Material.AirFilmFloorAverage
        end
        mat_int_finish_or_covering = Material.InteriorFinishMaterial(floor.interior_finish_type, floor.interior_finish_thickness)
        has_radiant_barrier = floor.radiant_barrier
        if has_radiant_barrier
          radiant_barrier_grade = floor.radiant_barrier_grade
        end
      else # Floor
        if @apply_ashrae140_assumptions
          # Raised floor
          inside_film = Material.AirFilmFloorASHRAE140
          outside_film = Material.AirFilmFloorZeroWindASHRAE140
          surface.setWindExposure('NoWind')
          mat_int_finish_or_covering = Material.CoveringBare(1.0)
        else
          inside_film = Material.AirFilmFloorReduced
          if floor.is_exterior
            outside_film = Material.AirFilmOutside
          else
            outside_film = Material.AirFilmFloorReduced
          end
          if floor.interior_adjacent_to == HPXML::LocationConditionedSpace
            mat_int_finish_or_covering = Material.CoveringBare
          end
        end
      end

      Constructions.apply_floor_ceiling_construction(runner, model, [surface], floor.id, floor.floor_type, floor.is_ceiling, floor.insulation_assembly_r_value,
                                                     mat_int_finish_or_covering, has_radiant_barrier, inside_film, outside_film, radiant_barrier_grade)
    end
  end

  def add_foundation_walls_slabs(runner, model, weather, spaces)
    foundation_types = @hpxml_bldg.slabs.map { |s| s.interior_adjacent_to }.uniq

    foundation_types.each do |foundation_type|
      # Get attached slabs/foundation walls
      slabs = []
      @hpxml_bldg.slabs.each do |slab|
        next unless slab.interior_adjacent_to == foundation_type

        slabs << slab
        slab.exposed_perimeter = [slab.exposed_perimeter, 1.0].max # minimum value to prevent error if no exposed slab
      end

      slabs.each do |slab|
        slab_frac = slab.exposed_perimeter / slabs.map { |s| s.exposed_perimeter }.sum
        ext_fnd_walls = slab.connected_foundation_walls.select { |fw| fw.net_area >= 1.0 && fw.is_exterior }

        if ext_fnd_walls.empty?
          # Slab w/o foundation walls
          add_foundation_slab(model, weather, spaces, slab, -1 * slab.depth_below_grade.to_f, slab.exposed_perimeter, nil)
        else
          # Slab w/ foundation walls
          ext_fnd_walls_length = ext_fnd_walls.map { |fw| fw.area / fw.height }.sum
          remaining_exposed_length = slab.exposed_perimeter

          # Since we don't know which FoundationWalls are adjacent to which Slabs, we apportion
          # each FoundationWall to each slab.
          ext_fnd_walls.each do |fnd_wall|
            # Both the foundation wall and slab must have same exposed length to prevent Kiva errors.
            # For the foundation wall, we are effectively modeling the net *exposed* area.
            fnd_wall_length = fnd_wall.area / fnd_wall.height
            apportioned_exposed_length = fnd_wall_length / ext_fnd_walls_length * slab.exposed_perimeter # Slab exposed perimeter apportioned to this foundation wall
            apportioned_total_length = fnd_wall_length * slab_frac # Foundation wall length apportioned to this slab
            exposed_length = [apportioned_exposed_length, apportioned_total_length].min
            remaining_exposed_length -= exposed_length

            kiva_foundation = add_foundation_wall(runner, model, spaces, fnd_wall, exposed_length, fnd_wall_length)
            add_foundation_slab(model, weather, spaces, slab, -1 * fnd_wall.depth_below_grade, exposed_length, kiva_foundation)
          end

          if remaining_exposed_length > 1 # Skip if a small length (e.g., due to rounding)
            # The slab's exposed perimeter exceeds the sum of attached exterior foundation wall lengths.
            # This may legitimately occur for a walkout basement, where a portion of the slab has no
            # adjacent foundation wall.
            add_foundation_slab(model, weather, spaces, slab, 0, remaining_exposed_length, nil)
          end
        end
      end

      # Interzonal foundation wall surfaces
      # The above-grade portion of these walls are modeled as EnergyPlus surfaces with standard adjacency.
      # The below-grade portion of these walls (in contact with ground) are not modeled, as Kiva does not
      # calculate heat flow between two zones through the ground.
      int_fnd_walls = @hpxml_bldg.foundation_walls.select { |fw| fw.is_interior && fw.interior_adjacent_to == foundation_type }
      int_fnd_walls.each do |fnd_wall|
        next unless fnd_wall.is_interior

        ag_height = fnd_wall.height - fnd_wall.depth_below_grade
        ag_net_area = fnd_wall.net_area * ag_height / fnd_wall.height
        next if ag_net_area < 1.0

        length = ag_net_area / ag_height
        z_origin = -1 * ag_height
        if fnd_wall.azimuth.nil?
          azimuth = @default_azimuths[0] # Arbitrary direction, doesn't receive exterior incident solar
        else
          azimuth = fnd_wall.azimuth
        end

        vertices = Geometry.create_wall_vertices(length, ag_height, z_origin, azimuth)
        surface = OpenStudio::Model::Surface.new(vertices, model)
        surface.additionalProperties.setFeature('Length', length)
        surface.additionalProperties.setFeature('Azimuth', azimuth)
        surface.additionalProperties.setFeature('Tilt', 90.0)
        surface.additionalProperties.setFeature('SurfaceType', 'FoundationWall')
        surface.setName(fnd_wall.id)
        surface.setSurfaceType('Wall')
        set_surface_interior(model, spaces, surface, fnd_wall)
        set_surface_exterior(model, spaces, surface, fnd_wall)
        surface.setSunExposure('NoSun')
        surface.setWindExposure('NoWind')

        # Apply construction

        wall_type = HPXML::WallTypeConcrete
        inside_film = Material.AirFilmVertical
        outside_film = Material.AirFilmVertical
        assembly_r = fnd_wall.insulation_assembly_r_value
        mat_int_finish = Material.InteriorFinishMaterial(fnd_wall.interior_finish_type, fnd_wall.interior_finish_thickness)
        if assembly_r.nil?
          concrete_thick_in = fnd_wall.thickness
          int_r = fnd_wall.insulation_interior_r_value
          ext_r = fnd_wall.insulation_exterior_r_value
          mat_concrete = Material.Concrete(concrete_thick_in)
          mat_int_finish_rvalue = mat_int_finish.nil? ? 0.0 : mat_int_finish.rvalue
          assembly_r = int_r + ext_r + mat_concrete.rvalue + mat_int_finish_rvalue + inside_film.rvalue + outside_film.rvalue
        end
        mat_ext_finish = nil

        Constructions.apply_wall_construction(runner,
                                              model,
                                              [surface],
                                              fnd_wall.id,
                                              wall_type,
                                              assembly_r,
                                              mat_int_finish,
                                              false,
                                              inside_film,
                                              outside_film,
                                              nil,
                                              mat_ext_finish,
                                              nil,
                                              nil)
      end
    end
  end

  def add_foundation_wall(runner, model, spaces, foundation_wall, exposed_length, fnd_wall_length)
    exposed_fraction = exposed_length / fnd_wall_length
    net_exposed_area = foundation_wall.net_area * exposed_fraction
    gross_exposed_area = foundation_wall.area * exposed_fraction
    height = foundation_wall.height
    height_ag = height - foundation_wall.depth_below_grade
    z_origin = -1 * foundation_wall.depth_below_grade
    if foundation_wall.azimuth.nil?
      azimuth = @default_azimuths[0] # Arbitrary; solar incidence in Kiva is applied as an orientation average (to the above grade portion of the wall)
    else
      azimuth = foundation_wall.azimuth
    end

    return if exposed_length < 0.1 # Avoid Kiva error if exposed wall length is too small

    if gross_exposed_area > net_exposed_area
      # Create a "notch" in the wall to account for the subsurfaces. This ensures that
      # we preserve the appropriate wall height, length, and area for Kiva.
      subsurface_area = gross_exposed_area - net_exposed_area
    else
      subsurface_area = 0
    end

    vertices = Geometry.create_wall_vertices(exposed_length, height, z_origin, azimuth, subsurface_area: subsurface_area)
    surface = OpenStudio::Model::Surface.new(vertices, model)
    surface.additionalProperties.setFeature('Length', exposed_length)
    surface.additionalProperties.setFeature('Azimuth', azimuth)
    surface.additionalProperties.setFeature('Tilt', 90.0)
    surface.additionalProperties.setFeature('SurfaceType', 'FoundationWall')
    surface.setName(foundation_wall.id)
    surface.setSurfaceType('Wall')
    set_surface_interior(model, spaces, surface, foundation_wall)
    set_surface_exterior(model, spaces, surface, foundation_wall)

    assembly_r = foundation_wall.insulation_assembly_r_value
    mat_int_finish = Material.InteriorFinishMaterial(foundation_wall.interior_finish_type, foundation_wall.interior_finish_thickness)
    mat_wall = Material.FoundationWallMaterial(foundation_wall.type, foundation_wall.thickness)
    if not assembly_r.nil?
      ext_rigid_height = height
      ext_rigid_offset = 0.0
      inside_film = Material.AirFilmVertical

      mat_int_finish_rvalue = mat_int_finish.nil? ? 0.0 : mat_int_finish.rvalue
      ext_rigid_r = assembly_r - mat_wall.rvalue - mat_int_finish_rvalue - inside_film.rvalue
      int_rigid_r = 0.0
      if ext_rigid_r < 0 # Try without interior finish
        mat_int_finish = nil
        ext_rigid_r = assembly_r - mat_wall.rvalue - inside_film.rvalue
      end
      if (ext_rigid_r > 0) && (ext_rigid_r < 0.1)
        ext_rigid_r = 0.0 # Prevent tiny strip of insulation
      end
      if ext_rigid_r < 0
        ext_rigid_r = 0.0
        match = false
      else
        match = true
      end
    else
      ext_rigid_offset = foundation_wall.insulation_exterior_distance_to_top
      ext_rigid_height = foundation_wall.insulation_exterior_distance_to_bottom - ext_rigid_offset
      ext_rigid_r = foundation_wall.insulation_exterior_r_value
      int_rigid_offset = foundation_wall.insulation_interior_distance_to_top
      int_rigid_height = foundation_wall.insulation_interior_distance_to_bottom - int_rigid_offset
      int_rigid_r = foundation_wall.insulation_interior_r_value
    end

    soil_k_in = UnitConversions.convert(@hpxml_bldg.site.ground_conductivity, 'ft', 'in')

    Constructions.apply_foundation_wall(model, [surface], "#{foundation_wall.id} construction",
                                        ext_rigid_offset, int_rigid_offset, ext_rigid_height, int_rigid_height,
                                        ext_rigid_r, int_rigid_r, mat_int_finish, mat_wall, height_ag,
                                        soil_k_in)

    if not assembly_r.nil?
      Constructions.check_surface_assembly_rvalue(runner, [surface], inside_film, nil, assembly_r, match)
    end

    return surface.adjacentFoundation.get
  end

  def add_foundation_slab(model, weather, spaces, slab, z_origin, exposed_length, kiva_foundation)
    exposed_fraction = exposed_length / slab.exposed_perimeter
    slab_tot_perim = exposed_length
    slab_area = slab.area * exposed_fraction
    if slab_tot_perim**2 - 16.0 * slab_area <= 0
      # Cannot construct rectangle with this perimeter/area. Some of the
      # perimeter is presumably not exposed, so bump up perimeter value.
      slab_tot_perim = Math.sqrt(16.0 * slab_area)
    end
    sqrt_term = [slab_tot_perim**2 - 16.0 * slab_area, 0.0].max
    slab_length = slab_tot_perim / 4.0 + Math.sqrt(sqrt_term) / 4.0
    slab_width = slab_tot_perim / 4.0 - Math.sqrt(sqrt_term) / 4.0

    vertices = Geometry.create_floor_vertices(slab_length, slab_width, z_origin, @default_azimuths)
    surface = OpenStudio::Model::Surface.new(vertices, model)
    surface.setName(slab.id)
    surface.setSurfaceType('Floor')
    surface.setOutsideBoundaryCondition('Foundation')
    surface.additionalProperties.setFeature('SurfaceType', 'Slab')
    set_surface_interior(model, spaces, surface, slab)
    surface.setSunExposure('NoSun')
    surface.setWindExposure('NoWind')

    slab_perim_r = slab.perimeter_insulation_r_value
    slab_perim_depth = slab.perimeter_insulation_depth
    if (slab_perim_r == 0) || (slab_perim_depth == 0)
      slab_perim_r = 0
      slab_perim_depth = 0
    end

    if slab.under_slab_insulation_spans_entire_slab
      slab_whole_r = slab.under_slab_insulation_r_value
      slab_under_r = 0
      slab_under_width = 0
    else
      slab_under_r = slab.under_slab_insulation_r_value
      slab_under_width = slab.under_slab_insulation_width
      if (slab_under_r == 0) || (slab_under_width == 0)
        slab_under_r = 0
        slab_under_width = 0
      end
      slab_whole_r = 0
    end
    slab_gap_r = slab.gap_insulation_r_value

    mat_carpet = nil
    if (slab.carpet_fraction > 0) && (slab.carpet_r_value > 0)
      mat_carpet = Material.CoveringBare(slab.carpet_fraction,
                                         slab.carpet_r_value)
    end
    soil_k_in = UnitConversions.convert(@hpxml_bldg.site.ground_conductivity, 'ft', 'in')

    Constructions.apply_foundation_slab(model, surface, "#{slab.id} construction",
                                        slab_under_r, slab_under_width, slab_gap_r, slab_perim_r,
                                        slab_perim_depth, slab_whole_r, slab.thickness,
                                        exposed_length, mat_carpet, soil_k_in, kiva_foundation)

    kiva_foundation = surface.adjacentFoundation.get

    foundation_walls_insulated = false
    foundation_ceiling_insulated = false
    @hpxml_bldg.foundation_walls.each do |fnd_wall|
      next unless fnd_wall.interior_adjacent_to == slab.interior_adjacent_to
      next unless fnd_wall.exterior_adjacent_to == HPXML::LocationGround

      if fnd_wall.insulation_assembly_r_value.to_f > 5
        foundation_walls_insulated = true
      elsif fnd_wall.insulation_exterior_r_value.to_f + fnd_wall.insulation_interior_r_value.to_f > 0
        foundation_walls_insulated = true
      end
    end
    @hpxml_bldg.floors.each do |floor|
      next unless floor.interior_adjacent_to == HPXML::LocationConditionedSpace
      next unless floor.exterior_adjacent_to == slab.interior_adjacent_to

      if floor.insulation_assembly_r_value > 5
        foundation_ceiling_insulated = true
      end
    end

    Constructions.apply_kiva_initial_temp(kiva_foundation, slab, weather,
                                          spaces[HPXML::LocationConditionedSpace].thermalZone.get,
                                          @hpxml_header.sim_begin_month, @hpxml_header.sim_begin_day,
                                          @hpxml_header.sim_calendar_year, @schedules_file,
                                          foundation_walls_insulated, foundation_ceiling_insulated)

    return kiva_foundation
  end

  def add_conditioned_floor_area(model, spaces)
    # Check if we need to add floors between conditioned spaces (e.g., between first
    # and second story or conditioned basement ceiling).
    # This ensures that the E+ reported Conditioned Floor Area is correct.

    sum_cfa = 0.0
    @hpxml_bldg.floors.each do |floor|
      next unless floor.is_floor
      next unless [HPXML::LocationConditionedSpace, HPXML::LocationBasementConditioned].include?(floor.interior_adjacent_to) ||
                  [HPXML::LocationConditionedSpace, HPXML::LocationBasementConditioned].include?(floor.exterior_adjacent_to)

      sum_cfa += floor.area
    end
    @hpxml_bldg.slabs.each do |slab|
      next unless [HPXML::LocationConditionedSpace, HPXML::LocationBasementConditioned].include? slab.interior_adjacent_to

      sum_cfa += slab.area
    end

    addtl_cfa = @cfa - sum_cfa

    fail if addtl_cfa < -1.0 # Allow some rounding; EPvalidator.xml should prevent this

    return unless addtl_cfa > 1.0 # Allow some rounding

    floor_width = Math::sqrt(addtl_cfa)
    floor_length = addtl_cfa / floor_width
    z_origin = @foundation_top + 8.0 * (@ncfl_ag - 1)

    # Add floor surface
    vertices = Geometry.create_floor_vertices(floor_length, floor_width, z_origin, @default_azimuths)
    floor_surface = OpenStudio::Model::Surface.new(vertices, model)

    floor_surface.setSunExposure('NoSun')
    floor_surface.setWindExposure('NoWind')
    floor_surface.setName('inferred conditioned floor')
    floor_surface.setSurfaceType('Floor')
    floor_surface.setSpace(create_or_get_space(model, spaces, HPXML::LocationConditionedSpace))
    floor_surface.setOutsideBoundaryCondition('Adiabatic')
    floor_surface.additionalProperties.setFeature('SurfaceType', 'InferredFloor')
    floor_surface.additionalProperties.setFeature('Tilt', 0.0)

    # Add ceiling surface
    vertices = Geometry.create_ceiling_vertices(floor_length, floor_width, z_origin, @default_azimuths)
    ceiling_surface = OpenStudio::Model::Surface.new(vertices, model)

    ceiling_surface.setSunExposure('NoSun')
    ceiling_surface.setWindExposure('NoWind')
    ceiling_surface.setName('inferred conditioned ceiling')
    ceiling_surface.setSurfaceType('RoofCeiling')
    ceiling_surface.setSpace(create_or_get_space(model, spaces, HPXML::LocationConditionedSpace))
    ceiling_surface.setOutsideBoundaryCondition('Adiabatic')
    ceiling_surface.additionalProperties.setFeature('SurfaceType', 'InferredCeiling')
    ceiling_surface.additionalProperties.setFeature('Tilt', 0.0)

    # Apply Construction
    apply_adiabatic_construction(model, [floor_surface, ceiling_surface], 'floor')
  end

  def add_thermal_mass(model, spaces)
    if @apply_ashrae140_assumptions
      # 1024 ft2 of interior partition wall mass, no furniture mass
      mat_int_finish = Material.InteriorFinishMaterial(HPXML::InteriorFinishGypsumBoard, 0.5)
      partition_wall_area = 1024.0 * 2 # Exposed partition wall area (both sides)
      Constructions.apply_partition_walls(model, 'PartitionWallConstruction', mat_int_finish, partition_wall_area, spaces)
    else
      mat_int_finish = Material.InteriorFinishMaterial(@hpxml_bldg.partition_wall_mass.interior_finish_type, @hpxml_bldg.partition_wall_mass.interior_finish_thickness)
      partition_wall_area = @hpxml_bldg.partition_wall_mass.area_fraction * @cfa # Exposed partition wall area (both sides)
      Constructions.apply_partition_walls(model, 'PartitionWallConstruction', mat_int_finish, partition_wall_area, spaces)

      Constructions.apply_furniture(model, @hpxml_bldg.furniture_mass, spaces)
    end
  end

  def add_cooling_season(model, weather)
    # Create cooling season schedule
    # Applies to natural ventilation and calculation of component loads, not HVAC equipment
    # Uses BAHSP cooling season, not user-specified cooling season (which may be, e.g., year-round)
    _, default_cooling_months = HVAC.get_default_heating_and_cooling_seasons(weather, @hpxml_bldg.latitude)

    clg_season_sch = MonthWeekdayWeekendSchedule.new(model, 'cooling season schedule', Array.new(24, 1), Array.new(24, 1), default_cooling_months, Constants.ScheduleTypeLimitsFraction)
    @clg_ssn_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Schedule Value')
    @clg_ssn_sensor.setName('cool_season')
    @clg_ssn_sensor.setKeyName(clg_season_sch.schedule.name.to_s)
  end

  def add_windows(model, spaces)
    # We already stored @fraction_of_windows_operable, so lets remove the
    # fraction_operable properties from windows and re-collapse the enclosure
    # so as to prevent potentially modeling multiple identical windows in E+,
    # which can increase simulation runtime.
    @hpxml_bldg.windows.each do |window|
      window.fraction_operable = nil
    end
    @hpxml_bldg.collapse_enclosure_surfaces()

    shading_schedules = {}

    surfaces = []
    @hpxml_bldg.windows.each do |window|
      window_height = 4.0 # ft, default

      overhang_depth = nil
      if (not window.overhangs_depth.nil?) && (window.overhangs_depth > 0)
        overhang_depth = window.overhangs_depth
        overhang_distance_to_top = window.overhangs_distance_to_top_of_window
        overhang_distance_to_bottom = window.overhangs_distance_to_bottom_of_window
        window_height = overhang_distance_to_bottom - overhang_distance_to_top
      end

      window_length = window.area / window_height
      z_origin = @foundation_top

      ufactor, shgc = Constructions.get_ufactor_shgc_adjusted_by_storms(window.storm_type, window.ufactor, window.shgc)

      if window.is_exterior

        # Create parent surface slightly bigger than window
        vertices = Geometry.create_wall_vertices(window_length, window_height, z_origin, window.azimuth, add_buffer: true)
        surface = OpenStudio::Model::Surface.new(vertices, model)

        surface.additionalProperties.setFeature('Length', window_length)
        surface.additionalProperties.setFeature('Azimuth', window.azimuth)
        surface.additionalProperties.setFeature('Tilt', 90.0)
        surface.additionalProperties.setFeature('SurfaceType', 'Window')
        surface.setName("surface #{window.id}")
        surface.setSurfaceType('Wall')
        set_surface_interior(model, spaces, surface, window.wall)

        vertices = Geometry.create_wall_vertices(window_length, window_height, z_origin, window.azimuth)
        sub_surface = OpenStudio::Model::SubSurface.new(vertices, model)
        sub_surface.setName(window.id)
        sub_surface.setSurface(surface)
        sub_surface.setSubSurfaceType('FixedWindow')

        set_subsurface_exterior(surface, spaces, model, window.wall)
        surfaces << surface

        if not overhang_depth.nil?
          overhang = sub_surface.addOverhang(UnitConversions.convert(overhang_depth, 'ft', 'm'), UnitConversions.convert(overhang_distance_to_top, 'ft', 'm'))
          overhang.get.setName("#{sub_surface.name} overhangs")
        end

        # Apply construction
        Constructions.apply_window(model, sub_surface, 'WindowConstruction', ufactor, shgc)

        # Apply interior/exterior shading (as needed)
        Constructions.apply_window_skylight_shading(model, window, sub_surface, shading_schedules, @hpxml_header, @hpxml_bldg)
      else
        # Window is on an interior surface, which E+ does not allow. Model
        # as a door instead so that we can get the appropriate conduction
        # heat transfer; there is no solar gains anyway.

        # Create parent surface slightly bigger than window
        vertices = Geometry.create_wall_vertices(window_length, window_height, z_origin, window.azimuth, add_buffer: true)
        surface = OpenStudio::Model::Surface.new(vertices, model)

        surface.additionalProperties.setFeature('Length', window_length)
        surface.additionalProperties.setFeature('Azimuth', window.azimuth)
        surface.additionalProperties.setFeature('Tilt', 90.0)
        surface.additionalProperties.setFeature('SurfaceType', 'Door')
        surface.setName("surface #{window.id}")
        surface.setSurfaceType('Wall')
        set_surface_interior(model, spaces, surface, window.wall)

        vertices = Geometry.create_wall_vertices(window_length, window_height, z_origin, window.azimuth)
        sub_surface = OpenStudio::Model::SubSurface.new(vertices, model)
        sub_surface.setName(window.id)
        sub_surface.setSurface(surface)
        sub_surface.setSubSurfaceType('Door')

        set_subsurface_exterior(surface, spaces, model, window.wall)
        surfaces << surface

        # Apply construction
        inside_film = Material.AirFilmVertical
        outside_film = Material.AirFilmVertical
        Constructions.apply_door(model, [sub_surface], 'Window', ufactor, inside_film, outside_film)
      end
    end

    apply_adiabatic_construction(model, surfaces, 'wall')
  end

  def add_skylights(model, spaces)
    surfaces = []
    shading_schedules = {}

    @hpxml_bldg.skylights.each do |skylight|
      tilt = skylight.roof.pitch / 12.0
      width = Math::sqrt(skylight.area)
      length = skylight.area / width
      z_origin = @walls_top + 0.5 * Math.sin(Math.atan(tilt)) * width

      ufactor, shgc = Constructions.get_ufactor_shgc_adjusted_by_storms(skylight.storm_type, skylight.ufactor, skylight.shgc)

      # Create parent surface slightly bigger than skylight
      vertices = Geometry.create_roof_vertices(length, width, z_origin, skylight.azimuth, tilt, add_buffer: true)
      surface = OpenStudio::Model::Surface.new(vertices, model)
      surface.additionalProperties.setFeature('Length', length)
      surface.additionalProperties.setFeature('Width', width)
      surface.additionalProperties.setFeature('Azimuth', skylight.azimuth)
      surface.additionalProperties.setFeature('Tilt', tilt)
      surface.additionalProperties.setFeature('SurfaceType', 'Skylight')
      surface.setName("surface #{skylight.id}")
      surface.setSurfaceType('RoofCeiling')
      surface.setSpace(create_or_get_space(model, spaces, HPXML::LocationConditionedSpace)) # Ensures it is included in Manual J sizing
      surface.setOutsideBoundaryCondition('Outdoors') # cannot be adiabatic because subsurfaces won't be created
      surfaces << surface

      vertices = Geometry.create_roof_vertices(length, width, z_origin, skylight.azimuth, tilt)
      sub_surface = OpenStudio::Model::SubSurface.new(vertices, model)
      sub_surface.setName(skylight.id)
      sub_surface.setSurface(surface)
      sub_surface.setSubSurfaceType('Skylight')

      # Apply construction
      Constructions.apply_skylight(model, sub_surface, 'SkylightConstruction', ufactor, shgc)

      # Apply interior/exterior shading (as needed)
      Constructions.apply_window_skylight_shading(model, skylight, sub_surface, shading_schedules, @hpxml_header, @hpxml_bldg)
    end

    apply_adiabatic_construction(model, surfaces, 'roof')
  end

  def add_doors(model, spaces)
    surfaces = []
    @hpxml_bldg.doors.each do |door|
      door_height = 6.67 # ft
      door_length = door.area / door_height
      z_origin = @foundation_top

      # Create parent surface slightly bigger than door
      vertices = Geometry.create_wall_vertices(door_length, door_height, z_origin, door.azimuth, add_buffer: true)
      surface = OpenStudio::Model::Surface.new(vertices, model)

      surface.additionalProperties.setFeature('Length', door_length)
      surface.additionalProperties.setFeature('Azimuth', door.azimuth)
      surface.additionalProperties.setFeature('Tilt', 90.0)
      surface.additionalProperties.setFeature('SurfaceType', 'Door')
      surface.setName("surface #{door.id}")
      surface.setSurfaceType('Wall')
      set_surface_interior(model, spaces, surface, door.wall)

      vertices = Geometry.create_wall_vertices(door_length, door_height, z_origin, door.azimuth)
      sub_surface = OpenStudio::Model::SubSurface.new(vertices, model)
      sub_surface.setName(door.id)
      sub_surface.setSurface(surface)
      sub_surface.setSubSurfaceType('Door')

      set_subsurface_exterior(surface, spaces, model, door.wall)
      surfaces << surface

      # Apply construction
      ufactor = 1.0 / door.r_value
      inside_film = Material.AirFilmVertical
      if door.wall.is_exterior
        outside_film = Material.AirFilmOutside
      else
        outside_film = Material.AirFilmVertical
      end
      Constructions.apply_door(model, [sub_surface], 'Door', ufactor, inside_film, outside_film)
    end

    apply_adiabatic_construction(model, surfaces, 'wall')
  end

  def apply_adiabatic_construction(model, surfaces, type)
    # Arbitrary construction for heat capacitance.
    # Only applies to surfaces where outside boundary conditioned is
    # adiabatic or surface net area is near zero.
    return if surfaces.empty?

    if type == 'wall'
      mat_int_finish = Material.InteriorFinishMaterial(HPXML::InteriorFinishGypsumBoard, 0.5)
      mat_ext_finish = Material.ExteriorFinishMaterial(HPXML::SidingTypeWood)
      Constructions.apply_wood_stud_wall(model, surfaces, 'AdiabaticWallConstruction',
                                         0, 1, 3.5, true, 0.1, mat_int_finish, 0, 99, mat_ext_finish, false,
                                         Material.AirFilmVertical, Material.AirFilmVertical, nil)
    elsif type == 'floor'
      Constructions.apply_wood_frame_floor_ceiling(model, surfaces, 'AdiabaticFloorConstruction', false,
                                                   0, 1, 0.07, 5.5, 0.75, 99, Material.CoveringBare, false,
                                                   Material.AirFilmFloorReduced, Material.AirFilmFloorReduced, nil)
    elsif type == 'roof'
      Constructions.apply_open_cavity_roof(model, surfaces, 'AdiabaticRoofConstruction',
                                           0, 1, 7.25, 0.07, 7.25, 0.75, 99,
                                           Material.RoofMaterial(HPXML::RoofTypeAsphaltShingles),
                                           false, Material.AirFilmOutside,
                                           Material.AirFilmRoof(Geometry.get_roof_pitch(surfaces)), nil)
    end
  end

  def add_hot_water_and_appliances(runner, model, weather, spaces)
    # Assign spaces
    @hpxml_bldg.clothes_washers.each do |clothes_washer|
      clothes_washer.additional_properties.space = get_space_from_location(clothes_washer.location, spaces)
    end
    @hpxml_bldg.clothes_dryers.each do |clothes_dryer|
      clothes_dryer.additional_properties.space = get_space_from_location(clothes_dryer.location, spaces)
    end
    @hpxml_bldg.dishwashers.each do |dishwasher|
      dishwasher.additional_properties.space = get_space_from_location(dishwasher.location, spaces)
    end
    @hpxml_bldg.refrigerators.each do |refrigerator|
      loc_space, loc_schedule = get_space_or_schedule_from_location(refrigerator.location, model, spaces)
      refrigerator.additional_properties.loc_space = loc_space
      refrigerator.additional_properties.loc_schedule = loc_schedule
    end
    @hpxml_bldg.freezers.each do |freezer|
      loc_space, loc_schedule = get_space_or_schedule_from_location(freezer.location, model, spaces)
      freezer.additional_properties.loc_space = loc_space
      freezer.additional_properties.loc_schedule = loc_schedule
    end
    @hpxml_bldg.cooking_ranges.each do |cooking_range|
      cooking_range.additional_properties.space = get_space_from_location(cooking_range.location, spaces)
    end

    # Distribution
    if @hpxml_bldg.water_heating_systems.size > 0
      hot_water_distribution = @hpxml_bldg.hot_water_distributions[0]
    end

    # Solar thermal system
    solar_thermal_system = nil
    if @hpxml_bldg.solar_thermal_systems.size > 0
      solar_thermal_system = @hpxml_bldg.solar_thermal_systems[0]
    end

    # Water Heater
    unavailable_periods = Schedule.get_unavailable_periods(runner, SchedulesFile::Columns[:WaterHeater].name, @hpxml_header.unavailable_periods)
    unit_multiplier = @hpxml_bldg.building_construction.number_of_units
    has_uncond_bsmnt = @hpxml_bldg.has_location(HPXML::LocationBasementUnconditioned)
    has_cond_bsmnt = @hpxml_bldg.has_location(HPXML::LocationBasementConditioned)
    plantloop_map = {}
    @hpxml_bldg.water_heating_systems.each do |water_heating_system|
      loc_space, loc_schedule = get_space_or_schedule_from_location(water_heating_system.location, model, spaces)

      ec_adj = HotWaterAndAppliances.get_dist_energy_consumption_adjustment(has_uncond_bsmnt, has_cond_bsmnt, @cfa, @ncfl, water_heating_system, hot_water_distribution)

      sys_id = water_heating_system.id
      if water_heating_system.water_heater_type == HPXML::WaterHeaterTypeStorage
        plantloop_map[sys_id] = Waterheater.apply_tank(model, runner, loc_space, loc_schedule, water_heating_system, ec_adj, solar_thermal_system, @eri_version, @schedules_file, unavailable_periods, unit_multiplier, @nbeds)
      elsif water_heating_system.water_heater_type == HPXML::WaterHeaterTypeTankless
        plantloop_map[sys_id] = Waterheater.apply_tankless(model, runner, loc_space, loc_schedule, water_heating_system, ec_adj, solar_thermal_system, @eri_version, @schedules_file, unavailable_periods, unit_multiplier, @nbeds)
      elsif water_heating_system.water_heater_type == HPXML::WaterHeaterTypeHeatPump
        conditioned_zone = spaces[HPXML::LocationConditionedSpace].thermalZone.get
        plantloop_map[sys_id] = Waterheater.apply_heatpump(model, runner, loc_space, loc_schedule, @hpxml_bldg.elevation, water_heating_system, ec_adj, solar_thermal_system, conditioned_zone, @eri_version, @schedules_file, unavailable_periods, unit_multiplier, @nbeds)
      elsif [HPXML::WaterHeaterTypeCombiStorage, HPXML::WaterHeaterTypeCombiTankless].include? water_heating_system.water_heater_type
        plantloop_map[sys_id] = Waterheater.apply_combi(model, runner, loc_space, loc_schedule, water_heating_system, ec_adj, solar_thermal_system, @eri_version, @schedules_file, unavailable_periods, unit_multiplier, @nbeds)
      else
        fail "Unhandled water heater (#{water_heating_system.water_heater_type})."
      end
    end

    # Hot water fixtures and appliances
    showers_peak_flows = HotWaterAndAppliances.apply(model, runner, @hpxml_header, @hpxml_bldg, weather, spaces, hot_water_distribution,
                                                     solar_thermal_system, @eri_version, @schedules_file, plantloop_map,
                                                     @hpxml_header.unavailable_periods, @hpxml_bldg.building_construction.number_of_units,
                                                     @apply_ashrae140_assumptions)

    if (not solar_thermal_system.nil?) && (not solar_thermal_system.collector_area.nil?) # Detailed solar water heater
      loc_space, loc_schedule = get_space_or_schedule_from_location(solar_thermal_system.water_heating_system.location, model, spaces)
      Waterheater.apply_solar_thermal(model, loc_space, loc_schedule, solar_thermal_system, plantloop_map, unit_multiplier)
    end

    # Add combi-system EMS program with water use equipment information
    Waterheater.apply_combi_system_EMS(model, @hpxml_bldg.water_heating_systems, plantloop_map)

    # Add unmet wh loads calculation
    Waterheater.unmet_wh_loads_program(model, @hpxml_bldg.water_heating_systems, plantloop_map, showers_peak_flows)
  end

  def add_cooling_system(model, runner, weather, spaces, airloop_map)
    conditioned_zone = spaces[HPXML::LocationConditionedSpace].thermalZone.get

    HVAC.get_hpxml_hvac_systems(@hpxml_bldg).each do |hvac_system|
      next if hvac_system[:cooling].nil?
      next unless hvac_system[:cooling].is_a? HPXML::CoolingSystem

      cooling_system = hvac_system[:cooling]
      heating_system = hvac_system[:heating]

      check_distribution_system(cooling_system.distribution_system, cooling_system.cooling_system_type)

      # Calculate cooling sequential load fractions
      sequential_cool_load_fracs = HVAC.calc_sequential_load_fractions(cooling_system.fraction_cool_load_served.to_f, @remaining_cool_load_frac, @cooling_days)
      @remaining_cool_load_frac -= cooling_system.fraction_cool_load_served.to_f

      # Calculate heating sequential load fractions
      if not heating_system.nil?
        sequential_heat_load_fracs = HVAC.calc_sequential_load_fractions(heating_system.fraction_heat_load_served, @remaining_heat_load_frac, @heating_days)
        @remaining_heat_load_frac -= heating_system.fraction_heat_load_served
      elsif cooling_system.has_integrated_heating
        sequential_heat_load_fracs = HVAC.calc_sequential_load_fractions(cooling_system.integrated_heating_system_fraction_heat_load_served, @remaining_heat_load_frac, @heating_days)
        @remaining_heat_load_frac -= cooling_system.integrated_heating_system_fraction_heat_load_served
      else
        sequential_heat_load_fracs = [0]
      end

      sys_id = cooling_system.id
      if [HPXML::HVACTypeCentralAirConditioner,
          HPXML::HVACTypeRoomAirConditioner,
          HPXML::HVACTypeMiniSplitAirConditioner,
          HPXML::HVACTypePTAC].include? cooling_system.cooling_system_type

        airloop_map[sys_id] = HVAC.apply_air_source_hvac_systems(model, runner, cooling_system, heating_system, sequential_cool_load_fracs, sequential_heat_load_fracs,
                                                                 weather.data.AnnualMaxDrybulb, weather.data.AnnualMinDrybulb,
                                                                 conditioned_zone, @hvac_unavailable_periods, @schedules_file, @hpxml_bldg)

      elsif [HPXML::HVACTypeEvaporativeCooler].include? cooling_system.cooling_system_type

        airloop_map[sys_id] = HVAC.apply_evaporative_cooler(model, cooling_system, sequential_cool_load_fracs,
                                                            conditioned_zone, @hvac_unavailable_periods,
                                                            @hpxml_bldg.building_construction.number_of_units)
      end
    end
  end

  def add_heating_system(runner, model, weather, spaces, airloop_map)
    conditioned_zone = spaces[HPXML::LocationConditionedSpace].thermalZone.get

    HVAC.get_hpxml_hvac_systems(@hpxml_bldg).each do |hvac_system|
      next if hvac_system[:heating].nil?
      next unless hvac_system[:heating].is_a? HPXML::HeatingSystem

      cooling_system = hvac_system[:cooling]
      heating_system = hvac_system[:heating]

      check_distribution_system(heating_system.distribution_system, heating_system.heating_system_type)

      if (heating_system.heating_system_type == HPXML::HVACTypeFurnace) && (not cooling_system.nil?)
        next # Already processed combined AC+furnace
      end

      # Calculate heating sequential load fractions
      if heating_system.is_heat_pump_backup_system
        # Heating system will be last in the EquipmentList and should meet entirety of
        # remaining load during the heating season.
        sequential_heat_load_fracs = @heating_days.map(&:to_f)
        if not heating_system.fraction_heat_load_served.nil?
          fail 'Heat pump backup system cannot have a fraction heat load served specified.'
        end
      else
        sequential_heat_load_fracs = HVAC.calc_sequential_load_fractions(heating_system.fraction_heat_load_served, @remaining_heat_load_frac, @heating_days)
        @remaining_heat_load_frac -= heating_system.fraction_heat_load_served
      end

      sys_id = heating_system.id
      if [HPXML::HVACTypeFurnace].include? heating_system.heating_system_type

        airloop_map[sys_id] = HVAC.apply_air_source_hvac_systems(model, runner, nil, heating_system, [0], sequential_heat_load_fracs,
                                                                 weather.data.AnnualMaxDrybulb, weather.data.AnnualMinDrybulb,
                                                                 conditioned_zone, @hvac_unavailable_periods, @schedules_file, @hpxml_bldg)

      elsif [HPXML::HVACTypeBoiler].include? heating_system.heating_system_type

        airloop_map[sys_id] = HVAC.apply_boiler(model, runner, heating_system, sequential_heat_load_fracs, conditioned_zone,
                                                @hvac_unavailable_periods)

      elsif [HPXML::HVACTypeElectricResistance].include? heating_system.heating_system_type

        HVAC.apply_electric_baseboard(model, heating_system,
                                      sequential_heat_load_fracs, conditioned_zone, @hvac_unavailable_periods)

      elsif [HPXML::HVACTypeStove,
             HPXML::HVACTypeSpaceHeater,
             HPXML::HVACTypeWallFurnace,
             HPXML::HVACTypeFloorFurnace,
             HPXML::HVACTypeFireplace].include? heating_system.heating_system_type

        HVAC.apply_unit_heater(model, heating_system,
                               sequential_heat_load_fracs, conditioned_zone, @hvac_unavailable_periods)
      end

      next unless heating_system.is_heat_pump_backup_system

      # Store OS object for later use
      equipment_list = model.getZoneHVACEquipmentLists.find { |el| el.thermalZone == conditioned_zone }
      @heat_pump_backup_system_object = equipment_list.equipment[-1]
    end
  end

  def add_heat_pump(runner, model, weather, spaces, airloop_map)
    conditioned_zone = spaces[HPXML::LocationConditionedSpace].thermalZone.get

    HVAC.get_hpxml_hvac_systems(@hpxml_bldg).each do |hvac_system|
      next if hvac_system[:cooling].nil?
      next unless hvac_system[:cooling].is_a? HPXML::HeatPump

      heat_pump = hvac_system[:cooling]

      check_distribution_system(heat_pump.distribution_system, heat_pump.heat_pump_type)

      # Calculate heating sequential load fractions
      sequential_heat_load_fracs = HVAC.calc_sequential_load_fractions(heat_pump.fraction_heat_load_served, @remaining_heat_load_frac, @heating_days)
      @remaining_heat_load_frac -= heat_pump.fraction_heat_load_served

      # Calculate cooling sequential load fractions
      sequential_cool_load_fracs = HVAC.calc_sequential_load_fractions(heat_pump.fraction_cool_load_served, @remaining_cool_load_frac, @cooling_days)
      @remaining_cool_load_frac -= heat_pump.fraction_cool_load_served

      sys_id = heat_pump.id
      if [HPXML::HVACTypeHeatPumpWaterLoopToAir].include? heat_pump.heat_pump_type

        airloop_map[sys_id] = HVAC.apply_water_loop_to_air_heat_pump(model, heat_pump,
                                                                     sequential_heat_load_fracs, sequential_cool_load_fracs,
                                                                     conditioned_zone, @hvac_unavailable_periods)

      elsif [HPXML::HVACTypeHeatPumpAirToAir,
             HPXML::HVACTypeHeatPumpMiniSplit,
             HPXML::HVACTypeHeatPumpPTHP,
             HPXML::HVACTypeHeatPumpRoom].include? heat_pump.heat_pump_type

        airloop_map[sys_id] = HVAC.apply_air_source_hvac_systems(model, runner, heat_pump, heat_pump, sequential_cool_load_fracs, sequential_heat_load_fracs,
                                                                 weather.data.AnnualMaxDrybulb, weather.data.AnnualMinDrybulb,
                                                                 conditioned_zone, @hvac_unavailable_periods, @schedules_file, @hpxml_bldg)
      elsif [HPXML::HVACTypeHeatPumpGroundToAir].include? heat_pump.heat_pump_type

        airloop_map[sys_id] = HVAC.apply_ground_to_air_heat_pump(model, runner, weather, heat_pump,
                                                                 sequential_heat_load_fracs, sequential_cool_load_fracs,
                                                                 conditioned_zone, @hpxml_bldg.site.ground_conductivity, @hpxml_bldg.site.ground_diffusivity,
                                                                 @hvac_unavailable_periods, @hpxml_bldg.building_construction.number_of_units)

      end

      next if heat_pump.backup_system.nil?

      equipment_list = model.getZoneHVACEquipmentLists.find { |el| el.thermalZone == conditioned_zone }

      # Set priority to be last (i.e., after the heat pump that it is backup for)
      equipment_list.setHeatingPriority(@heat_pump_backup_system_object, 99)
      equipment_list.setCoolingPriority(@heat_pump_backup_system_object, 99)
    end
  end

  def add_ideal_system(model, spaces, epw_path)
    # Adds an ideal air system as needed to meet the load under certain circumstances:
    # 1. the sum of fractions load served is less than 1, or
    # 2. we're using an ideal air system for e.g. ASHRAE 140 loads calculation.
    conditioned_zone = spaces[HPXML::LocationConditionedSpace].thermalZone.get

    if @apply_ashrae140_assumptions && (@hpxml_bldg.total_fraction_heat_load_served + @hpxml_bldg.total_fraction_heat_load_served == 0.0)
      cooling_load_frac = 1.0
      heating_load_frac = 1.0
      if @apply_ashrae140_assumptions
        if epw_path.end_with? 'USA_CO_Colorado.Springs-Peterson.Field.724660_TMY3.epw'
          cooling_load_frac = 0.0
        elsif epw_path.end_with? 'USA_NV_Las.Vegas-McCarran.Intl.AP.723860_TMY3.epw'
          heating_load_frac = 0.0
        else
          fail 'Unexpected weather file for ASHRAE 140 run.'
        end
      end
      HVAC.apply_ideal_air_loads(model, [cooling_load_frac], [heating_load_frac],
                                 conditioned_zone, @hvac_unavailable_periods)
      return
    end

    if (@hpxml_bldg.total_fraction_heat_load_served < 1.0) && (@hpxml_bldg.total_fraction_heat_load_served > 0.0)
      sequential_heat_load_fracs = HVAC.calc_sequential_load_fractions(@remaining_heat_load_frac - @hpxml_bldg.total_fraction_heat_load_served, @remaining_heat_load_frac, @heating_days)
      @remaining_heat_load_frac -= (1.0 - @hpxml_bldg.total_fraction_heat_load_served)
    else
      sequential_heat_load_fracs = [0.0]
    end

    if (@hpxml_bldg.total_fraction_cool_load_served < 1.0) && (@hpxml_bldg.total_fraction_cool_load_served > 0.0)
      sequential_cool_load_fracs = HVAC.calc_sequential_load_fractions(@remaining_cool_load_frac - @hpxml_bldg.total_fraction_cool_load_served, @remaining_cool_load_frac, @cooling_days)
      @remaining_cool_load_frac -= (1.0 - @hpxml_bldg.total_fraction_cool_load_served)
    else
      sequential_cool_load_fracs = [0.0]
    end

    if (sequential_heat_load_fracs.sum > 0.0) || (sequential_cool_load_fracs.sum > 0.0)
      HVAC.apply_ideal_air_loads(model, sequential_cool_load_fracs, sequential_heat_load_fracs,
                                 conditioned_zone, @hvac_unavailable_periods)
    end
  end

  def add_setpoints(runner, model, weather, spaces)
    return if @hpxml_bldg.hvac_controls.size == 0

    hvac_control = @hpxml_bldg.hvac_controls[0]
    conditioned_zone = spaces[HPXML::LocationConditionedSpace].thermalZone.get
    has_ceiling_fan = (@hpxml_bldg.ceiling_fans.size > 0)

    HVAC.apply_setpoints(model, runner, weather, hvac_control, conditioned_zone, has_ceiling_fan, @heating_days, @cooling_days, @hpxml_header.sim_calendar_year, @schedules_file)
  end

  def add_ceiling_fans(runner, model, weather, spaces)
    return if @hpxml_bldg.ceiling_fans.size == 0

    ceiling_fan = @hpxml_bldg.ceiling_fans[0]
    HVAC.apply_ceiling_fans(model, runner, weather, ceiling_fan, spaces[HPXML::LocationConditionedSpace],
                            @schedules_file, @hpxml_header.unavailable_periods)
  end

  def add_dehumidifiers(runner, model, spaces)
    return if @hpxml_bldg.dehumidifiers.size == 0

    HVAC.apply_dehumidifiers(runner, model, @hpxml_bldg.dehumidifiers, spaces[HPXML::LocationConditionedSpace], @hpxml_header.unavailable_periods,
                             @hpxml_bldg.building_construction.number_of_units)
  end

  def check_distribution_system(hvac_distribution, system_type)
    return if hvac_distribution.nil?

    hvac_distribution_type_map = { HPXML::HVACTypeFurnace => [HPXML::HVACDistributionTypeAir, HPXML::HVACDistributionTypeDSE],
                                   HPXML::HVACTypeBoiler => [HPXML::HVACDistributionTypeHydronic, HPXML::HVACDistributionTypeAir, HPXML::HVACDistributionTypeDSE],
                                   HPXML::HVACTypeCentralAirConditioner => [HPXML::HVACDistributionTypeAir, HPXML::HVACDistributionTypeDSE],
                                   HPXML::HVACTypeEvaporativeCooler => [HPXML::HVACDistributionTypeAir, HPXML::HVACDistributionTypeDSE],
                                   HPXML::HVACTypeMiniSplitAirConditioner => [HPXML::HVACDistributionTypeAir, HPXML::HVACDistributionTypeDSE],
                                   HPXML::HVACTypeHeatPumpAirToAir => [HPXML::HVACDistributionTypeAir, HPXML::HVACDistributionTypeDSE],
                                   HPXML::HVACTypeHeatPumpMiniSplit => [HPXML::HVACDistributionTypeAir, HPXML::HVACDistributionTypeDSE],
                                   HPXML::HVACTypeHeatPumpGroundToAir => [HPXML::HVACDistributionTypeAir, HPXML::HVACDistributionTypeDSE],
                                   HPXML::HVACTypeHeatPumpWaterLoopToAir => [HPXML::HVACDistributionTypeAir, HPXML::HVACDistributionTypeDSE] }

    if not hvac_distribution_type_map[system_type].include? hvac_distribution.distribution_system_type
      fail "Incorrect HVAC distribution system type for HVAC type: '#{system_type}'. Should be one of: #{hvac_distribution_type_map[system_type]}"
    end
  end

  def add_mels(runner, model, spaces)
    # Misc
    @hpxml_bldg.plug_loads.each do |plug_load|
      if plug_load.plug_load_type == HPXML::PlugLoadTypeOther
        obj_name = Constants.ObjectNameMiscPlugLoads
      elsif plug_load.plug_load_type == HPXML::PlugLoadTypeTelevision
        obj_name = Constants.ObjectNameMiscTelevision
      elsif plug_load.plug_load_type == HPXML::PlugLoadTypeElectricVehicleCharging
        obj_name = Constants.ObjectNameMiscElectricVehicleCharging
      elsif plug_load.plug_load_type == HPXML::PlugLoadTypeWellPump
        obj_name = Constants.ObjectNameMiscWellPump
      end
      if obj_name.nil?
        runner.registerWarning("Unexpected plug load type '#{plug_load.plug_load_type}'. The plug load will not be modeled.")
        next
      end

      MiscLoads.apply_plug(model, runner, plug_load, obj_name, spaces[HPXML::LocationConditionedSpace], @apply_ashrae140_assumptions,
                           @schedules_file, @hpxml_header.unavailable_periods)
    end
  end

  def add_mfls(runner, model, spaces)
    # Misc
    @hpxml_bldg.fuel_loads.each do |fuel_load|
      if fuel_load.fuel_load_type == HPXML::FuelLoadTypeGrill
        obj_name = Constants.ObjectNameMiscGrill
      elsif fuel_load.fuel_load_type == HPXML::FuelLoadTypeLighting
        obj_name = Constants.ObjectNameMiscLighting
      elsif fuel_load.fuel_load_type == HPXML::FuelLoadTypeFireplace
        obj_name = Constants.ObjectNameMiscFireplace
      end
      if obj_name.nil?
        runner.registerWarning("Unexpected fuel load type '#{fuel_load.fuel_load_type}'. The fuel load will not be modeled.")
        next
      end

      MiscLoads.apply_fuel(model, runner, fuel_load, obj_name, spaces[HPXML::LocationConditionedSpace],
                           @schedules_file, @hpxml_header.unavailable_periods)
    end
  end

  def add_lighting(runner, model, spaces)
    Lighting.apply(runner, model, spaces, @hpxml_bldg.lighting_groups, @hpxml_bldg.lighting, @eri_version,
                   @schedules_file, @cfa, @hpxml_header.unavailable_periods, @hpxml_bldg.building_construction.number_of_units)
  end

  def add_pools_and_permanent_spas(runner, model, spaces)
    (@hpxml_bldg.pools + @hpxml_bldg.permanent_spas).each do |pool_or_spa|
      next if pool_or_spa.type == HPXML::TypeNone

      MiscLoads.apply_pool_or_permanent_spa_heater(runner, model, pool_or_spa, spaces[HPXML::LocationConditionedSpace],
                                                   @schedules_file, @hpxml_header.unavailable_periods)
      next if pool_or_spa.pump_type == HPXML::TypeNone

      MiscLoads.apply_pool_or_permanent_spa_pump(runner, model, pool_or_spa, spaces[HPXML::LocationConditionedSpace],
                                                 @schedules_file, @hpxml_header.unavailable_periods)
    end
  end

  def add_airflow(runner, model, weather, spaces, airloop_map)
    # Ducts
    duct_systems = {}
    @hpxml_bldg.hvac_distributions.each do |hvac_distribution|
      next unless hvac_distribution.distribution_system_type == HPXML::HVACDistributionTypeAir

      air_ducts = create_ducts(model, hvac_distribution, spaces)
      next if air_ducts.empty?

      # Connect AirLoopHVACs to ducts
      added_ducts = false
      hvac_distribution.hvac_systems.each do |hvac_system|
        next if airloop_map[hvac_system.id].nil?

        object = airloop_map[hvac_system.id]
        if duct_systems[air_ducts].nil?
          duct_systems[air_ducts] = object
          added_ducts = true
        elsif duct_systems[air_ducts] != object
          # Multiple air loops associated with this duct system, treat
          # as separate duct systems.
          air_ducts2 = create_ducts(model, hvac_distribution, spaces)
          duct_systems[air_ducts2] = object
          added_ducts = true
        end
      end
      if not added_ducts
        fail 'Unexpected error adding ducts to model.'
      end
    end

    # Duct leakage to outside warnings?
    # Need to check here instead of in schematron in case duct locations are defaulted
    @hpxml_bldg.hvac_distributions.each do |hvac_distribution|
      next unless hvac_distribution.distribution_system_type == HPXML::HVACDistributionTypeAir
      next if hvac_distribution.duct_leakage_measurements.empty?

      # Skip if there's a duct outside conditioned space
      next if hvac_distribution.ducts.select { |d| !HPXML::conditioned_locations_this_unit.include?(d.duct_location) }.size > 0

      # Issue warning if duct leakage to outside above a certain threshold and ducts completely in conditioned space
      issue_warning = false
      units = hvac_distribution.duct_leakage_measurements[0].duct_leakage_units
      lto_measurements = hvac_distribution.duct_leakage_measurements.select { |dlm| dlm.duct_leakage_total_or_to_outside == HPXML::DuctLeakageToOutside }
      sum_lto = lto_measurements.map { |dlm| dlm.duct_leakage_value }.sum(0.0)
      if units == HPXML::UnitsCFM25
        issue_warning = true if sum_lto > 0.04 * @cfa
      elsif units == HPXML::UnitsCFM50
        issue_warning = true if sum_lto > 0.06 * @cfa
      elsif units == HPXML::UnitsPercent
        issue_warning = true if sum_lto > 0.05
      end
      next unless issue_warning

      runner.registerWarning('Ducts are entirely within conditioned space but there is moderate leakage to the outside. Leakage to the outside is typically zero or near-zero in these situations, consider revising leakage values. Leakage will be modeled as heat lost to the ambient environment.')
    end

    # Create HVAC availability sensor
    hvac_availability_sensor = nil
    if not @hvac_unavailable_periods.empty?
      avail_sch = ScheduleConstant.new(model, SchedulesFile::Columns[:HVAC].name, 1.0, Constants.ScheduleTypeLimitsFraction, unavailable_periods: @hvac_unavailable_periods)

      hvac_availability_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Schedule Value')
      hvac_availability_sensor.setName('hvac availability s')
      hvac_availability_sensor.setKeyName(avail_sch.schedule.name.to_s)
      hvac_availability_sensor.additionalProperties.setFeature('ObjectType', Constants.ObjectNameHVACAvailabilitySensor)
    end

    Airflow.apply(model, runner, weather, spaces, @hpxml_header, @hpxml_bldg, @cfa, @nbeds,
                  @ncfl_ag, duct_systems, airloop_map, @clg_ssn_sensor, @eri_version,
                  @frac_windows_operable, @apply_ashrae140_assumptions, @schedules_file,
                  @hpxml_header.unavailable_periods, hvac_availability_sensor)
  end

  def create_ducts(model, hvac_distribution, spaces)
    air_ducts = []

    # Duct leakage (supply/return => [value, units])
    leakage_to_outside = { HPXML::DuctTypeSupply => [0.0, nil],
                           HPXML::DuctTypeReturn => [0.0, nil] }
    hvac_distribution.duct_leakage_measurements.each do |duct_leakage_measurement|
      next unless [HPXML::UnitsCFM25, HPXML::UnitsCFM50, HPXML::UnitsPercent].include?(duct_leakage_measurement.duct_leakage_units) && (duct_leakage_measurement.duct_leakage_total_or_to_outside == 'to outside')
      next if duct_leakage_measurement.duct_type.nil?

      leakage_to_outside[duct_leakage_measurement.duct_type] = [duct_leakage_measurement.duct_leakage_value, duct_leakage_measurement.duct_leakage_units]
    end

    # Duct location, R-value, Area
    total_unconditioned_duct_area = { HPXML::DuctTypeSupply => 0.0,
                                      HPXML::DuctTypeReturn => 0.0 }
    hvac_distribution.ducts.each do |ducts|
      next if HPXML::conditioned_locations_this_unit.include? ducts.duct_location
      next if ducts.duct_type.nil?

      # Calculate total duct area in unconditioned spaces
      total_unconditioned_duct_area[ducts.duct_type] += ducts.duct_surface_area * ducts.duct_surface_area_multiplier
    end

    # Create duct objects
    hvac_distribution.ducts.each do |ducts|
      next if HPXML::conditioned_locations_this_unit.include? ducts.duct_location
      next if ducts.duct_type.nil?
      next if total_unconditioned_duct_area[ducts.duct_type] <= 0

      duct_loc_space, duct_loc_schedule = get_space_or_schedule_from_location(ducts.duct_location, model, spaces)

      # Apportion leakage to individual ducts by surface area
      duct_leakage_value = leakage_to_outside[ducts.duct_type][0] * ducts.duct_surface_area * ducts.duct_surface_area_multiplier / total_unconditioned_duct_area[ducts.duct_type]
      duct_leakage_units = leakage_to_outside[ducts.duct_type][1]

      duct_leakage_frac = nil
      if duct_leakage_units == HPXML::UnitsCFM25
        duct_leakage_cfm25 = duct_leakage_value
      elsif duct_leakage_units == HPXML::UnitsCFM50
        duct_leakage_cfm50 = duct_leakage_value
      elsif duct_leakage_units == HPXML::UnitsPercent
        duct_leakage_frac = duct_leakage_value
      else
        fail "#{ducts.duct_type.capitalize} ducts exist but leakage was not specified for distribution system '#{hvac_distribution.id}'."
      end

      air_ducts << Duct.new(ducts.duct_type, duct_loc_space, duct_loc_schedule, duct_leakage_frac, duct_leakage_cfm25, duct_leakage_cfm50,
                            ducts.duct_surface_area * ducts.duct_surface_area_multiplier, ducts.duct_effective_r_value, ducts.duct_buried_insulation_level)
    end

    # If all ducts are in conditioned space, model leakage as going to outside
    [HPXML::DuctTypeSupply, HPXML::DuctTypeReturn].each do |duct_side|
      next unless (leakage_to_outside[duct_side][0] > 0) && (total_unconditioned_duct_area[duct_side] == 0)

      duct_area = 0.0
      duct_effective_r_value = 99 # arbitrary
      duct_loc_space = nil # outside
      duct_loc_schedule = nil # outside
      duct_leakage_value = leakage_to_outside[duct_side][0]
      duct_leakage_units = leakage_to_outside[duct_side][1]

      if duct_leakage_units == HPXML::UnitsCFM25
        duct_leakage_cfm25 = duct_leakage_value
      elsif duct_leakage_units == HPXML::UnitsCFM50
        duct_leakage_cfm50 = duct_leakage_value
      elsif duct_leakage_units == HPXML::UnitsPercent
        duct_leakage_frac = duct_leakage_value
      else
        fail "#{duct_side.capitalize} ducts exist but leakage was not specified for distribution system '#{hvac_distribution.id}'."
      end

      air_ducts << Duct.new(duct_side, duct_loc_space, duct_loc_schedule, duct_leakage_frac, duct_leakage_cfm25, duct_leakage_cfm50, duct_area,
                            duct_effective_r_value, HPXML::DuctBuriedInsulationNone)
    end

    return air_ducts
  end

  def add_photovoltaics(model)
    @hpxml_bldg.pv_systems.each do |pv_system|
      next if pv_system.inverter.inverter_efficiency == @hpxml_bldg.pv_systems[0].inverter.inverter_efficiency

      fail 'Expected all InverterEfficiency values to be equal.'
    end
    @hpxml_bldg.pv_systems.each do |pv_system|
      PV.apply(model, @nbeds, pv_system, @hpxml_bldg.building_construction.number_of_units)
    end
  end

  def add_generators(model)
    @hpxml_bldg.generators.each do |generator|
      Generator.apply(model, @nbeds, generator, @hpxml_bldg.building_construction.number_of_units)
    end
  end

  def add_batteries(runner, model, spaces)
    @hpxml_bldg.batteries.each do |battery|
      # Assign space
      battery.additional_properties.space = get_space_from_location(battery.location, spaces)
      Battery.apply(runner, model, @nbeds, @hpxml_bldg.pv_systems, battery, @schedules_file, @hpxml_bldg.building_construction.number_of_units)
    end
  end

  def add_building_unit(model, unit_num)
    return if unit_num.nil?

    unit = OpenStudio::Model::BuildingUnit.new(model)
    unit.additionalProperties.setFeature('unit_num', unit_num)
    model.getSpaces.each do |s|
      s.setBuildingUnit(unit)
    end
  end

  def add_additional_properties(model, hpxml, hpxml_osm_map, hpxml_path, building_id, hpxml_defaults_path)
    # Store some data for use in reporting measure
    additionalProperties = model.getBuilding.additionalProperties
    additionalProperties.setFeature('hpxml_path', hpxml_path)
    additionalProperties.setFeature('hpxml_defaults_path', hpxml_defaults_path)
    additionalProperties.setFeature('building_id', building_id.to_s)
    additionalProperties.setFeature('emissions_scenario_names', hpxml.header.emissions_scenarios.map { |s| s.name }.to_s)
    additionalProperties.setFeature('emissions_scenario_types', hpxml.header.emissions_scenarios.map { |s| s.emissions_type }.to_s)
    heated_zones, cooled_zones = [], []
    hpxml_osm_map.each do |hpxml_bldg, unit_model|
      conditioned_zone_name = unit_model.getThermalZones.find { |z| z.additionalProperties.getFeatureAsString('ObjectType').to_s == HPXML::LocationConditionedSpace }.name.to_s

      heated_zones << conditioned_zone_name if hpxml_bldg.total_fraction_heat_load_served > 0
      cooled_zones << conditioned_zone_name if hpxml_bldg.total_fraction_cool_load_served > 0
    end
    additionalProperties.setFeature('heated_zones', heated_zones.to_s)
    additionalProperties.setFeature('cooled_zones', cooled_zones.to_s)
    additionalProperties.setFeature('is_southern_hemisphere', hpxml_osm_map.keys[0].latitude < 0)
  end

  def add_unmet_hours_output(model, hpxml_osm_map)
    # We do our own unmet hours calculation via EMS so that we can incorporate,
    # e.g., heating/cooling seasons into the logic. The calculation layers on top
    # of the built-in EnergyPlus unmet hours output.

    # Create sensors and gather data
    htg_sensors, clg_sensors = {}, {}
    total_heat_load_serveds, total_cool_load_serveds = {}, {}
    htg_start_days, htg_end_days, clg_start_days, clg_end_days = {}, {}, {}, {}
    hpxml_osm_map.each_with_index do |(hpxml_bldg, unit_model), unit|
      conditioned_zone_name = unit_model.getThermalZones.find { |z| z.additionalProperties.getFeatureAsString('ObjectType').to_s == HPXML::LocationConditionedSpace }.name.to_s

      # EMS sensors
      htg_sensors[unit] = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Zone Heating Setpoint Not Met Time')
      htg_sensors[unit].setName('zone htg unmet s')
      htg_sensors[unit].setKeyName(conditioned_zone_name)

      clg_sensors[unit] = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Zone Cooling Setpoint Not Met Time')
      clg_sensors[unit].setName('zone clg unmet s')
      clg_sensors[unit].setKeyName(conditioned_zone_name)

      total_heat_load_serveds[unit] = hpxml_bldg.total_fraction_heat_load_served
      total_cool_load_serveds[unit] = hpxml_bldg.total_fraction_cool_load_served

      hvac_control = hpxml_bldg.hvac_controls[0]
      next unless not hvac_control.nil?

      sim_year = @hpxml_header.sim_calendar_year
      htg_start_days[unit] = Schedule.get_day_num_from_month_day(sim_year, hvac_control.seasons_heating_begin_month, hvac_control.seasons_heating_begin_day)
      htg_end_days[unit] = Schedule.get_day_num_from_month_day(sim_year, hvac_control.seasons_heating_end_month, hvac_control.seasons_heating_end_day)
      clg_start_days[unit] = Schedule.get_day_num_from_month_day(sim_year, hvac_control.seasons_cooling_begin_month, hvac_control.seasons_cooling_begin_day)
      clg_end_days[unit] = Schedule.get_day_num_from_month_day(sim_year, hvac_control.seasons_cooling_end_month, hvac_control.seasons_cooling_end_day)
    end

    hvac_availability_sensor = model.getEnergyManagementSystemSensors.find { |s| s.additionalProperties.getFeatureAsString('ObjectType').to_s == Constants.ObjectNameHVACAvailabilitySensor }

    # EMS program
    clg_hrs = 'clg_unmet_hours'
    htg_hrs = 'htg_unmet_hours'
    program = OpenStudio::Model::EnergyManagementSystemProgram.new(model)
    program.setName('unmet hours program')
    program.additionalProperties.setFeature('ObjectType', Constants.ObjectNameUnmetHoursProgram)
    program.addLine("Set #{htg_hrs} = 0")
    program.addLine("Set #{clg_hrs} = 0")
    for unit in 0..hpxml_osm_map.size - 1
      if total_heat_load_serveds[unit] > 0
        if htg_end_days[unit] >= htg_start_days[unit]
          line = "If ((DayOfYear >= #{htg_start_days[unit]}) && (DayOfYear <= #{htg_end_days[unit]}))"
        else
          line = "If ((DayOfYear >= #{htg_start_days[unit]}) || (DayOfYear <= #{htg_end_days[unit]}))"
        end
        line += " && (#{hvac_availability_sensor.name} == 1)" if not hvac_availability_sensor.nil?
        program.addLine(line)
        program.addLine("  If #{htg_sensors[unit].name} > #{htg_hrs}") # Use max hourly value across all units
        program.addLine("    Set #{htg_hrs} = #{htg_sensors[unit].name}")
        program.addLine('  EndIf')
        program.addLine('EndIf')
      end
      next unless total_cool_load_serveds[unit] > 0

      if clg_end_days[unit] >= clg_start_days[unit]
        line = "If ((DayOfYear >= #{clg_start_days[unit]}) && (DayOfYear <= #{clg_end_days[unit]}))"
      else
        line = "If ((DayOfYear >= #{clg_start_days[unit]}) || (DayOfYear <= #{clg_end_days[unit]}))"
      end
      line += " && (#{hvac_availability_sensor.name} == 1)" if not hvac_availability_sensor.nil?
      program.addLine(line)
      program.addLine("  If #{clg_sensors[unit].name} > #{clg_hrs}") # Use max hourly value across all units
      program.addLine("    Set #{clg_hrs} = #{clg_sensors[unit].name}")
      program.addLine('  EndIf')
      program.addLine('EndIf')
    end

    # EMS calling manager
    program_calling_manager = OpenStudio::Model::EnergyManagementSystemProgramCallingManager.new(model)
    program_calling_manager.setName("#{program.name} calling manager")
    program_calling_manager.setCallingPoint('EndOfZoneTimestepBeforeZoneReporting')
    program_calling_manager.addProgram(program)
  end

  def add_loads_output(model, add_component_loads, hpxml_osm_map)
    loads_data = add_total_loads_output(model, hpxml_osm_map)
    return unless add_component_loads

    add_component_loads_output(model, hpxml_osm_map, loads_data)
  end

  def add_total_loads_output(model, hpxml_osm_map)
    # Create sensors and gather data
    htg_cond_load_sensors, clg_cond_load_sensors = {}, {}
    htg_duct_load_sensors, clg_duct_load_sensors = {}, {}
    total_heat_load_serveds, total_cool_load_serveds = {}, {}
    dehumidifier_sensors = {}

    hpxml_osm_map.each_with_index do |(hpxml_bldg, unit_model), unit|
      # Retrieve objects
      conditioned_zone_name = unit_model.getThermalZones.find { |z| z.additionalProperties.getFeatureAsString('ObjectType').to_s == HPXML::LocationConditionedSpace }.name.to_s
      duct_zone_names = unit_model.getThermalZones.select { |z| z.isPlenum }.map { |z| z.name.to_s }
      dehumidifier = unit_model.getZoneHVACDehumidifierDXs
      dehumidifier_name = dehumidifier[0].name.to_s unless dehumidifier.empty?

      # Fraction heat/cool load served
      if @hpxml_header.apply_ashrae140_assumptions
        total_heat_load_serveds[unit] = 1.0
        total_cool_load_serveds[unit] = 1.0
      else
        total_heat_load_serveds[unit] = hpxml_bldg.total_fraction_heat_load_served
        total_cool_load_serveds[unit] = hpxml_bldg.total_fraction_cool_load_served
      end

      # Energy transferred in conditioned zone, used for determining heating (winter) vs cooling (summer)
      htg_cond_load_sensors[unit] = OpenStudio::Model::EnergyManagementSystemSensor.new(model, "Heating:EnergyTransfer:Zone:#{conditioned_zone_name.upcase}")
      htg_cond_load_sensors[unit].setName('htg_load_cond')
      clg_cond_load_sensors[unit] = OpenStudio::Model::EnergyManagementSystemSensor.new(model, "Cooling:EnergyTransfer:Zone:#{conditioned_zone_name.upcase}")
      clg_cond_load_sensors[unit].setName('clg_load_cond')

      # Energy transferred in duct zone(s)
      htg_duct_load_sensors[unit] = []
      clg_duct_load_sensors[unit] = []
      duct_zone_names.each do |duct_zone_name|
        htg_duct_load_sensors[unit] << OpenStudio::Model::EnergyManagementSystemSensor.new(model, "Heating:EnergyTransfer:Zone:#{duct_zone_name.upcase}")
        htg_duct_load_sensors[unit][-1].setName('htg_load_duct')
        clg_duct_load_sensors[unit] << OpenStudio::Model::EnergyManagementSystemSensor.new(model, "Cooling:EnergyTransfer:Zone:#{duct_zone_name.upcase}")
        clg_duct_load_sensors[unit][-1].setName('clg_load_duct')
      end

      # Need to adjusted E+ EnergyTransfer meters for dehumidifier internal gains
      next if dehumidifier_name.nil?

      dehumidifier_sensors[unit] = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Zone Dehumidifier Sensible Heating Energy')
      dehumidifier_sensors[unit].setName('ig_dehumidifier')
      dehumidifier_sensors[unit].setKeyName(dehumidifier_name)
    end

    # EMS program
    program = OpenStudio::Model::EnergyManagementSystemProgram.new(model)
    program.setName('total loads program')
    program.additionalProperties.setFeature('ObjectType', Constants.ObjectNameTotalLoadsProgram)
    program.addLine('Set loads_htg_tot = 0')
    program.addLine('Set loads_clg_tot = 0')
    for unit in 0..hpxml_osm_map.size - 1
      program.addLine("If #{htg_cond_load_sensors[unit].name} > 0")
      program.addLine("  Set loads_htg_tot = loads_htg_tot + (#{htg_cond_load_sensors[unit].name} - #{clg_cond_load_sensors[unit].name}) * #{total_heat_load_serveds[unit]}")
      for i in 0..htg_duct_load_sensors[unit].size - 1
        program.addLine("  Set loads_htg_tot = loads_htg_tot + (#{htg_duct_load_sensors[unit][i].name} - #{clg_duct_load_sensors[unit][i].name}) * #{total_heat_load_serveds[unit]}")
      end
      if not dehumidifier_sensors[unit].nil?
        program.addLine("  Set loads_htg_tot = loads_htg_tot - #{dehumidifier_sensors[unit].name}")
      end
      program.addLine('EndIf')
    end
    for unit in 0..hpxml_osm_map.size - 1
      program.addLine("If #{clg_cond_load_sensors[unit].name} > 0")
      program.addLine("  Set loads_clg_tot = loads_clg_tot + (#{clg_cond_load_sensors[unit].name} - #{htg_cond_load_sensors[unit].name}) * #{total_cool_load_serveds[unit]}")
      for i in 0..clg_duct_load_sensors[unit].size - 1
        program.addLine("  Set loads_clg_tot = loads_clg_tot + (#{clg_duct_load_sensors[unit][i].name} - #{htg_duct_load_sensors[unit][i].name}) * #{total_cool_load_serveds[unit]}")
      end
      if not dehumidifier_sensors[unit].nil?
        program.addLine("  Set loads_clg_tot = loads_clg_tot + #{dehumidifier_sensors[unit].name}")
      end
      program.addLine('EndIf')
    end

    # EMS calling manager
    program_calling_manager = OpenStudio::Model::EnergyManagementSystemProgramCallingManager.new(model)
    program_calling_manager.setName("#{program.name} calling manager")
    program_calling_manager.setCallingPoint('EndOfZoneTimestepAfterZoneReporting')
    program_calling_manager.addProgram(program)

    return htg_cond_load_sensors, clg_cond_load_sensors, total_heat_load_serveds, total_cool_load_serveds, dehumidifier_sensors
  end

  def add_component_loads_output(model, hpxml_osm_map, loads_data)
    htg_cond_load_sensors, clg_cond_load_sensors, total_heat_load_serveds, total_cool_load_serveds, dehumidifier_sensors = loads_data

    # Output diagnostics needed for some output variables used below
    output_diagnostics = model.getOutputDiagnostics
    output_diagnostics.addKey('DisplayAdvancedReportVariables')

    area_tolerance = UnitConversions.convert(1.0, 'ft^2', 'm^2')

    nonsurf_names = ['intgains', 'lighting', 'infil', 'mechvent', 'natvent', 'whf', 'ducts']
    surf_names = ['walls', 'rim_joists', 'foundation_walls', 'floors', 'slabs', 'ceilings',
                  'roofs', 'windows_conduction', 'windows_solar', 'doors', 'skylights_conduction',
                  'skylights_solar', 'internal_mass']

    # EMS program
    program = OpenStudio::Model::EnergyManagementSystemProgram.new(model)
    program.setName('component loads program')
    program.additionalProperties.setFeature('ObjectType', Constants.ObjectNameComponentLoadsProgram)

    # Initialize
    [:htg, :clg].each do |mode|
      surf_names.each do |surf_name|
        program.addLine("Set loads_#{mode}_#{surf_name} = 0")
      end
      nonsurf_names.each do |nonsurf_name|
        program.addLine("Set loads_#{mode}_#{nonsurf_name} = 0")
      end
    end

    hpxml_osm_map.values.each_with_index do |unit_model, unit|
      conditioned_zone = unit_model.getThermalZones.find { |z| z.additionalProperties.getFeatureAsString('ObjectType').to_s == HPXML::LocationConditionedSpace }

      # Prevent certain objects (e.g., OtherEquipment) from being counted towards both, e.g., ducts and internal gains
      objects_already_processed = []

      # EMS Sensors: Surfaces, SubSurfaces, InternalMass
      surfaces_sensors = {}
      surf_names.each do |surf_name|
        surfaces_sensors[surf_name.to_sym] = []
      end

      unit_model.getSurfaces.sort.each do |s|
        next unless s.space.get.thermalZone.get.name.to_s == conditioned_zone.name.to_s

        surface_type = s.additionalProperties.getFeatureAsString('SurfaceType')
        if not surface_type.is_initialized
          fail "Could not identify surface type for surface: '#{s.name}'."
        end

        surface_type = surface_type.get

        s.subSurfaces.each do |ss|
          # Conduction (windows, skylights, doors)
          key = { 'Window' => :windows_conduction,
                  'Door' => :doors,
                  'Skylight' => :skylights_conduction }[surface_type]
          fail "Unexpected subsurface for component loads: '#{ss.name}'." if key.nil?

          if (surface_type == 'Window') || (surface_type == 'Skylight')
            vars = { 'Surface Inside Face Convection Heat Gain Energy' => 'ss_conv',
                     'Surface Inside Face Internal Gains Radiation Heat Gain Energy' => 'ss_ig',
                     'Surface Inside Face Net Surface Thermal Radiation Heat Gain Energy' => 'ss_surf' }
          else
            vars = { 'Surface Inside Face Solar Radiation Heat Gain Energy' => 'ss_sol',
                     'Surface Inside Face Lights Radiation Heat Gain Energy' => 'ss_lgt',
                     'Surface Inside Face Convection Heat Gain Energy' => 'ss_conv',
                     'Surface Inside Face Internal Gains Radiation Heat Gain Energy' => 'ss_ig',
                     'Surface Inside Face Net Surface Thermal Radiation Heat Gain Energy' => 'ss_surf' }
          end

          vars.each do |var, name|
            surfaces_sensors[key] << []
            sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, var)
            sensor.setName(name)
            sensor.setKeyName(ss.name.to_s)
            surfaces_sensors[key][-1] << sensor
          end

          # Solar (windows, skylights)
          next unless (surface_type == 'Window') || (surface_type == 'Skylight')

          key = { 'Window' => :windows_solar,
                  'Skylight' => :skylights_solar }[surface_type]
          vars = { 'Surface Window Transmitted Solar Radiation Energy' => 'ss_trans_in',
                   'Surface Window Shortwave from Zone Back Out Window Heat Transfer Rate' => 'ss_back_out',
                   'Surface Window Total Glazing Layers Absorbed Shortwave Radiation Rate' => 'ss_sw_abs',
                   'Surface Window Total Glazing Layers Absorbed Solar Radiation Energy' => 'ss_sol_abs',
                   'Surface Inside Face Initial Transmitted Diffuse Transmitted Out Window Solar Radiation Rate' => 'ss_trans_out' }

          surfaces_sensors[key] << []
          vars.each do |var, name|
            sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, var)
            sensor.setName(name)
            sensor.setKeyName(ss.name.to_s)
            surfaces_sensors[key][-1] << sensor
          end
        end

        next if s.netArea < area_tolerance # Skip parent surfaces (of subsurfaces) that have near zero net area

        key = { 'FoundationWall' => :foundation_walls,
                'RimJoist' => :rim_joists,
                'Wall' => :walls,
                'Slab' => :slabs,
                'Floor' => :floors,
                'Ceiling' => :ceilings,
                'Roof' => :roofs,
                'InferredCeiling' => :internal_mass,
                'InferredFloor' => :internal_mass }[surface_type]
        fail "Unexpected surface for component loads: '#{s.name}'." if key.nil?

        surfaces_sensors[key] << []
        { 'Surface Inside Face Convection Heat Gain Energy' => 's_conv',
          'Surface Inside Face Internal Gains Radiation Heat Gain Energy' => 's_ig',
          'Surface Inside Face Solar Radiation Heat Gain Energy' => 's_sol',
          'Surface Inside Face Lights Radiation Heat Gain Energy' => 's_lgt',
          'Surface Inside Face Net Surface Thermal Radiation Heat Gain Energy' => 's_surf' }.each do |var, name|
          sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, var)
          sensor.setName(name)
          sensor.setKeyName(s.name.to_s)
          surfaces_sensors[key][-1] << sensor
        end
      end

      unit_model.getInternalMasss.sort.each do |m|
        next unless m.space.get.thermalZone.get.name.to_s == conditioned_zone.name.to_s

        surfaces_sensors[:internal_mass] << []
        { 'Surface Inside Face Convection Heat Gain Energy' => 'im_conv',
          'Surface Inside Face Internal Gains Radiation Heat Gain Energy' => 'im_ig',
          'Surface Inside Face Solar Radiation Heat Gain Energy' => 'im_sol',
          'Surface Inside Face Lights Radiation Heat Gain Energy' => 'im_lgt',
          'Surface Inside Face Net Surface Thermal Radiation Heat Gain Energy' => 'im_surf' }.each do |var, name|
          sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, var)
          sensor.setName(name)
          sensor.setKeyName(m.name.to_s)
          surfaces_sensors[:internal_mass][-1] << sensor
        end
      end

      # EMS Sensors: Infiltration, Natural Ventilation, Whole House Fan
      infil_sensors, natvent_sensors, whf_sensors = [], [], []
      unit_model.getSpaceInfiltrationDesignFlowRates.sort.each do |i|
        next unless i.space.get.thermalZone.get.name.to_s == conditioned_zone.name.to_s

        object_type = i.additionalProperties.getFeatureAsString('ObjectType').get

        { 'Infiltration Sensible Heat Gain Energy' => 'airflow_gain',
          'Infiltration Sensible Heat Loss Energy' => 'airflow_loss' }.each do |var, name|
          airflow_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, var)
          airflow_sensor.setName(name)
          airflow_sensor.setKeyName(i.name.to_s)
          if object_type == Constants.ObjectNameInfiltration
            infil_sensors << airflow_sensor
          elsif object_type == Constants.ObjectNameNaturalVentilation
            natvent_sensors << airflow_sensor
          elsif object_type == Constants.ObjectNameWholeHouseFan
            whf_sensors << airflow_sensor
          end
        end
      end

      # EMS Sensors: Mechanical Ventilation
      mechvents_sensors = []
      unit_model.getElectricEquipments.sort.each do |o|
        next unless o.endUseSubcategory == Constants.ObjectNameMechanicalVentilation

        objects_already_processed << o
        { 'Electric Equipment Convective Heating Energy' => 'mv_conv',
          'Electric Equipment Radiant Heating Energy' => 'mv_rad' }.each do |var, name|
          mechvent_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, var)
          mechvent_sensor.setName(name)
          mechvent_sensor.setKeyName(o.name.to_s)
          mechvents_sensors << mechvent_sensor
        end
      end
      unit_model.getOtherEquipments.sort.each do |o|
        next unless o.endUseSubcategory == Constants.ObjectNameMechanicalVentilationHouseFan

        objects_already_processed << o
        { 'Other Equipment Convective Heating Energy' => 'mv_conv',
          'Other Equipment Radiant Heating Energy' => 'mv_rad' }.each do |var, name|
          mechvent_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, var)
          mechvent_sensor.setName(name)
          mechvent_sensor.setKeyName(o.name.to_s)
          mechvents_sensors << mechvent_sensor
        end
      end

      # EMS Sensors: Ducts
      ducts_sensors = []
      ducts_mix_gain_sensor = nil
      ducts_mix_loss_sensor = nil
      conditioned_zone.zoneMixing.each do |zone_mix|
        object_type = zone_mix.additionalProperties.getFeatureAsString('ObjectType').to_s
        next unless object_type == Constants.ObjectNameDuctLoad

        ducts_mix_gain_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Zone Mixing Sensible Heat Gain Energy')
        ducts_mix_gain_sensor.setName('duct_mix_gain')
        ducts_mix_gain_sensor.setKeyName(conditioned_zone.name.to_s)

        ducts_mix_loss_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Zone Mixing Sensible Heat Loss Energy')
        ducts_mix_loss_sensor.setName('duct_mix_loss')
        ducts_mix_loss_sensor.setKeyName(conditioned_zone.name.to_s)
      end
      unit_model.getOtherEquipments.sort.each do |o|
        next if objects_already_processed.include? o
        next unless o.endUseSubcategory == Constants.ObjectNameDuctLoad

        objects_already_processed << o
        { 'Other Equipment Convective Heating Energy' => 'ducts_conv',
          'Other Equipment Radiant Heating Energy' => 'ducts_rad' }.each do |var, name|
          ducts_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, var)
          ducts_sensor.setName(name)
          ducts_sensor.setKeyName(o.name.to_s)
          ducts_sensors << ducts_sensor
        end
      end

      # EMS Sensors: Lighting
      lightings_sensors = []
      unit_model.getLightss.sort.each do |e|
        next unless e.space.get.thermalZone.get.name.to_s == conditioned_zone.name.to_s

        { 'Lights Convective Heating Energy' => 'ig_lgt_conv',
          'Lights Radiant Heating Energy' => 'ig_lgt_rad',
          'Lights Visible Radiation Heating Energy' => 'ig_lgt_vis' }.each do |var, name|
          intgains_lights_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, var)
          intgains_lights_sensor.setName(name)
          intgains_lights_sensor.setKeyName(e.name.to_s)
          lightings_sensors << intgains_lights_sensor
        end
      end

      # EMS Sensors: Internal Gains
      intgains_sensors = []
      unit_model.getElectricEquipments.sort.each do |o|
        next if objects_already_processed.include? o
        next unless o.space.get.thermalZone.get.name.to_s == conditioned_zone.name.to_s

        { 'Electric Equipment Convective Heating Energy' => 'ig_ee_conv',
          'Electric Equipment Radiant Heating Energy' => 'ig_ee_rad' }.each do |var, name|
          intgains_elec_equip_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, var)
          intgains_elec_equip_sensor.setName(name)
          intgains_elec_equip_sensor.setKeyName(o.name.to_s)
          intgains_sensors << intgains_elec_equip_sensor
        end
      end

      unit_model.getOtherEquipments.sort.each do |o|
        next if objects_already_processed.include? o
        next unless o.space.get.thermalZone.get.name.to_s == conditioned_zone.name.to_s

        { 'Other Equipment Convective Heating Energy' => 'ig_oe_conv',
          'Other Equipment Radiant Heating Energy' => 'ig_oe_rad' }.each do |var, name|
          intgains_other_equip_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, var)
          intgains_other_equip_sensor.setName(name)
          intgains_other_equip_sensor.setKeyName(o.name.to_s)
          intgains_sensors << intgains_other_equip_sensor
        end
      end

      unit_model.getPeoples.sort.each do |e|
        next unless e.space.get.thermalZone.get.name.to_s == conditioned_zone.name.to_s

        { 'People Convective Heating Energy' => 'ig_ppl_conv',
          'People Radiant Heating Energy' => 'ig_ppl_rad' }.each do |var, name|
          intgains_people = OpenStudio::Model::EnergyManagementSystemSensor.new(model, var)
          intgains_people.setName(name)
          intgains_people.setKeyName(e.name.to_s)
          intgains_sensors << intgains_people
        end
      end

      if not dehumidifier_sensors[unit].nil?
        intgains_sensors << dehumidifier_sensors[unit]
      end

      intgains_dhw_sensors = {}

      (unit_model.getWaterHeaterMixeds + unit_model.getWaterHeaterStratifieds).sort.each do |wh|
        next unless wh.ambientTemperatureThermalZone.is_initialized
        next unless wh.ambientTemperatureThermalZone.get.name.to_s == conditioned_zone.name.to_s

        dhw_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Water Heater Heat Loss Energy')
        dhw_sensor.setName('dhw_loss')
        dhw_sensor.setKeyName(wh.name.to_s)

        if wh.is_a? OpenStudio::Model::WaterHeaterMixed
          oncycle_loss = wh.onCycleLossFractiontoThermalZone
          offcycle_loss = wh.offCycleLossFractiontoThermalZone
        else
          oncycle_loss = wh.skinLossFractiontoZone
          offcycle_loss = wh.offCycleFlueLossFractiontoZone
        end

        dhw_rtf_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Water Heater Runtime Fraction')
        dhw_rtf_sensor.setName('dhw_rtf')
        dhw_rtf_sensor.setKeyName(wh.name.to_s)

        intgains_dhw_sensors[dhw_sensor] = [offcycle_loss, oncycle_loss, dhw_rtf_sensor]
      end

      # EMS program: Surfaces
      surfaces_sensors.each do |k, surface_sensors|
        program.addLine("Set hr_#{k} = 0")
        surface_sensors.each do |sensors|
          s = "Set hr_#{k} = hr_#{k}"
          sensors.each do |sensor|
            # remove ss_net if switch
            if sensor.name.to_s.start_with?('ss_net', 'ss_sol_abs', 'ss_trans_in')
              s += " - #{sensor.name}"
            elsif sensor.name.to_s.start_with?('ss_sw_abs', 'ss_trans_out', 'ss_back_out')
              s += " + #{sensor.name} * ZoneTimestep * 3600"
            else
              s += " + #{sensor.name}"
            end
          end
          program.addLine(s) if sensors.size > 0
        end
      end

      # EMS program: Internal Gains, Lighting, Infiltration, Natural Ventilation, Mechanical Ventilation, Ducts
      { 'intgains' => intgains_sensors,
        'lighting' => lightings_sensors,
        'infil' => infil_sensors,
        'natvent' => natvent_sensors,
        'whf' => whf_sensors,
        'mechvent' => mechvents_sensors,
        'ducts' => ducts_sensors }.each do |loadtype, sensors|
        program.addLine("Set hr_#{loadtype} = 0")
        next if sensors.empty?

        s = "Set hr_#{loadtype} = hr_#{loadtype}"
        sensors.each do |sensor|
          if ['intgains', 'lighting', 'mechvent', 'ducts'].include? loadtype
            s += " - #{sensor.name}"
          elsif sensor.name.to_s.include? 'gain'
            s += " - #{sensor.name}"
          elsif sensor.name.to_s.include? 'loss'
            s += " + #{sensor.name}"
          end
        end
        program.addLine(s)
      end
      intgains_dhw_sensors.each do |sensor, vals|
        off_loss, on_loss, rtf_sensor = vals
        program.addLine("Set hr_intgains = hr_intgains + #{sensor.name} * (#{off_loss}*(1-#{rtf_sensor.name}) + #{on_loss}*#{rtf_sensor.name})") # Water heater tank losses to zone
      end
      if (not ducts_mix_loss_sensor.nil?) && (not ducts_mix_gain_sensor.nil?)
        program.addLine("Set hr_ducts = hr_ducts + (#{ducts_mix_loss_sensor.name} - #{ducts_mix_gain_sensor.name})")
      end

      # EMS program: Heating vs Cooling logic
      program.addLine('Set htg_mode = 0')
      program.addLine('Set clg_mode = 0')
      program.addLine("If (#{htg_cond_load_sensors[unit].name} > 0)") # Assign hour to heating if heating load
      program.addLine("  Set htg_mode = #{total_heat_load_serveds[unit]}")
      program.addLine("ElseIf (#{clg_cond_load_sensors[unit].name} > 0)") # Assign hour to cooling if cooling load
      program.addLine("  Set clg_mode = #{total_cool_load_serveds[unit]}")
      program.addLine("ElseIf (#{@clg_ssn_sensor.name} > 0)") # No load, assign hour to cooling if in cooling season definition (Note: natural ventilation & whole house fan only operate during the cooling season)
      program.addLine("  Set clg_mode = #{total_cool_load_serveds[unit]}")
      program.addLine('Else') # No load, assign hour to heating if not in cooling season definition
      program.addLine("  Set htg_mode = #{total_heat_load_serveds[unit]}")
      program.addLine('EndIf')

      unit_multiplier = @hpxml_bldg.building_construction.number_of_units
      [:htg, :clg].each do |mode|
        if mode == :htg
          sign = ''
        else
          sign = '-'
        end
        surf_names.each do |surf_name|
          program.addLine("Set loads_#{mode}_#{surf_name} = loads_#{mode}_#{surf_name} + (#{sign}hr_#{surf_name} * #{mode}_mode * #{unit_multiplier})")
        end
        nonsurf_names.each do |nonsurf_name|
          program.addLine("Set loads_#{mode}_#{nonsurf_name} = loads_#{mode}_#{nonsurf_name} + (#{sign}hr_#{nonsurf_name} * #{mode}_mode * #{unit_multiplier})")
        end
      end
    end

    # EMS calling manager
    program_calling_manager = OpenStudio::Model::EnergyManagementSystemProgramCallingManager.new(model)
    program_calling_manager.setName("#{program.name} calling manager")
    program_calling_manager.setCallingPoint('EndOfZoneTimestepAfterZoneReporting')
    program_calling_manager.addProgram(program)
  end

  def set_output_files(model)
    oj = model.getOutputJSON
    oj.setOptionType('TimeSeriesAndTabular')
    oj.setOutputJSON(false)
    oj.setOutputMessagePack(true)

    ocf = model.getOutputControlFiles
    ocf.setOutputAUDIT(@debug)
    ocf.setOutputCSV(@debug)
    ocf.setOutputBND(@debug)
    ocf.setOutputEIO(@debug)
    ocf.setOutputESO(@debug)
    ocf.setOutputMDD(@debug)
    ocf.setOutputMTD(@debug)
    ocf.setOutputMTR(@debug)
    ocf.setOutputRDD(@debug)
    ocf.setOutputSHD(@debug)
    ocf.setOutputCSV(@debug)
    ocf.setOutputSQLite(@debug)
    ocf.setOutputPerfLog(@debug)
  end

  def add_ems_debug_output(model)
    oems = model.getOutputEnergyManagementSystem
    oems.setActuatorAvailabilityDictionaryReporting('Verbose')
    oems.setInternalVariableAvailabilityDictionaryReporting('Verbose')
    oems.setEMSRuntimeLanguageDebugOutputLevel('Verbose')
  end

  def set_surface_interior(model, spaces, surface, hpxml_surface)
    interior_adjacent_to = hpxml_surface.interior_adjacent_to
    if HPXML::conditioned_below_grade_locations.include? interior_adjacent_to
      surface.setSpace(create_or_get_space(model, spaces, HPXML::LocationConditionedSpace))
    else
      surface.setSpace(create_or_get_space(model, spaces, interior_adjacent_to))
    end
  end

  def set_surface_exterior(model, spaces, surface, hpxml_surface)
    exterior_adjacent_to = hpxml_surface.exterior_adjacent_to
    is_adiabatic = hpxml_surface.is_adiabatic
    if [HPXML::LocationOutside, HPXML::LocationManufacturedHomeUnderBelly].include? exterior_adjacent_to
      surface.setOutsideBoundaryCondition('Outdoors')
    elsif exterior_adjacent_to == HPXML::LocationGround
      surface.setOutsideBoundaryCondition('Foundation')
    elsif is_adiabatic
      surface.setOutsideBoundaryCondition('Adiabatic')
    elsif [HPXML::LocationOtherHeatedSpace, HPXML::LocationOtherMultifamilyBufferSpace,
           HPXML::LocationOtherNonFreezingSpace, HPXML::LocationOtherHousingUnit].include? exterior_adjacent_to
      set_surface_otherside_coefficients(surface, exterior_adjacent_to, model, spaces)
    elsif HPXML::conditioned_below_grade_locations.include? exterior_adjacent_to
      adjacent_surface = surface.createAdjacentSurface(create_or_get_space(model, spaces, HPXML::LocationConditionedSpace)).get
      adjacent_surface.additionalProperties.setFeature('SurfaceType', surface.additionalProperties.getFeatureAsString('SurfaceType').get)
    else
      adjacent_surface = surface.createAdjacentSurface(create_or_get_space(model, spaces, exterior_adjacent_to)).get
      adjacent_surface.additionalProperties.setFeature('SurfaceType', surface.additionalProperties.getFeatureAsString('SurfaceType').get)
    end
  end

  def set_surface_otherside_coefficients(surface, exterior_adjacent_to, model, spaces)
    otherside_coeffs = nil
    model.getSurfacePropertyOtherSideCoefficientss.each do |c|
      next unless c.name.to_s == exterior_adjacent_to

      otherside_coeffs = c
    end
    if otherside_coeffs.nil?
      # Create E+ other side coefficient object
      otherside_coeffs = OpenStudio::Model::SurfacePropertyOtherSideCoefficients.new(model)
      otherside_coeffs.setName(exterior_adjacent_to)
      otherside_coeffs.setCombinedConvectiveRadiativeFilmCoefficient(UnitConversions.convert(1.0 / Material.AirFilmVertical.rvalue, 'Btu/(hr*ft^2*F)', 'W/(m^2*K)'))
      # Schedule of space temperature, can be shared with water heater/ducts
      sch = get_space_temperature_schedule(model, exterior_adjacent_to, spaces)
      otherside_coeffs.setConstantTemperatureSchedule(sch)
    end
    surface.setSurfacePropertyOtherSideCoefficients(otherside_coeffs)
    surface.setSunExposure('NoSun')
    surface.setWindExposure('NoWind')
  end

  def get_space_temperature_schedule(model, location, spaces)
    # Create outside boundary schedules to be actuated by EMS,
    # can be shared by any surface, duct adjacent to / located in those spaces

    # return if already exists
    model.getScheduleConstants.each do |sch|
      next unless sch.name.to_s == location

      return sch
    end

    sch = OpenStudio::Model::ScheduleConstant.new(model)
    sch.setName(location)
    sch.additionalProperties.setFeature('ObjectType', location)

    space_values = Geometry.get_temperature_scheduled_space_values(location)

    htg_weekday_setpoints, htg_weekend_setpoints = HVAC.get_default_heating_setpoint(HPXML::HVACControlTypeManual, @eri_version)
    if htg_weekday_setpoints.split(', ').uniq.size == 1 && htg_weekend_setpoints.split(', ').uniq.size == 1 && htg_weekday_setpoints.split(', ').uniq == htg_weekend_setpoints.split(', ').uniq
      default_htg_sp = htg_weekend_setpoints.split(', ').uniq[0].to_f # F
    else
      fail 'Unexpected heating setpoints.'
    end

    clg_weekday_setpoints, clg_weekend_setpoints = HVAC.get_default_cooling_setpoint(HPXML::HVACControlTypeManual, @eri_version)
    if clg_weekday_setpoints.split(', ').uniq.size == 1 && clg_weekend_setpoints.split(', ').uniq.size == 1 && clg_weekday_setpoints.split(', ').uniq == clg_weekend_setpoints.split(', ').uniq
      default_clg_sp = clg_weekend_setpoints.split(', ').uniq[0].to_f # F
    else
      fail 'Unexpected cooling setpoints.'
    end

    if location == HPXML::LocationOtherHeatedSpace
      if spaces[HPXML::LocationConditionedSpace].thermalZone.get.thermostatSetpointDualSetpoint.is_initialized
        # Create a sensor to get dynamic heating setpoint
        htg_sch = spaces[HPXML::LocationConditionedSpace].thermalZone.get.thermostatSetpointDualSetpoint.get.heatingSetpointTemperatureSchedule.get
        sensor_htg_spt = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Schedule Value')
        sensor_htg_spt.setName('htg_spt')
        sensor_htg_spt.setKeyName(htg_sch.name.to_s)
        space_values[:temp_min] = sensor_htg_spt.name.to_s
      else
        # No HVAC system; use the defaulted heating setpoint.
        space_values[:temp_min] = default_htg_sp # F
      end
    end

    # Schedule type limits compatible
    schedule_type_limits = OpenStudio::Model::ScheduleTypeLimits.new(model)
    schedule_type_limits.setUnitType('Temperature')
    sch.setScheduleTypeLimits(schedule_type_limits)

    # Sensors
    if space_values[:indoor_weight] > 0
      if not spaces[HPXML::LocationConditionedSpace].thermalZone.get.thermostatSetpointDualSetpoint.is_initialized
        # No HVAC system; use the average of defaulted heating/cooling setpoints.
        sensor_ia = UnitConversions.convert((default_htg_sp + default_clg_sp) / 2.0, 'F', 'C')
      else
        sensor_ia = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Zone Air Temperature')
        sensor_ia.setName('cond_zone_temp')
        sensor_ia.setKeyName(spaces[HPXML::LocationConditionedSpace].thermalZone.get.name.to_s)
        sensor_ia = sensor_ia.name
      end
    end

    if space_values[:outdoor_weight] > 0
      sensor_oa = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Site Outdoor Air Drybulb Temperature')
      sensor_oa.setName('oa_temp')
    end

    if space_values[:ground_weight] > 0
      sensor_gnd = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Site Surface Ground Temperature')
      sensor_gnd.setName('ground_temp')
    end

    actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(sch, *EPlus::EMSActuatorScheduleConstantValue)
    actuator.setName("#{location.gsub(' ', '_').gsub('-', '_')}_temp_sch")

    # EMS to actuate schedule
    program = OpenStudio::Model::EnergyManagementSystemProgram.new(model)
    program.setName("#{location.gsub('-', '_')} Temperature Program")
    program.addLine("Set #{actuator.name} = 0.0")
    if not sensor_ia.nil?
      program.addLine("Set #{actuator.name} = #{actuator.name} + (#{sensor_ia} * #{space_values[:indoor_weight]})")
    end
    if not sensor_oa.nil?
      program.addLine("Set #{actuator.name} = #{actuator.name} + (#{sensor_oa.name} * #{space_values[:outdoor_weight]})")
    end
    if not sensor_gnd.nil?
      program.addLine("Set #{actuator.name} = #{actuator.name} + (#{sensor_gnd.name} * #{space_values[:ground_weight]})")
    end
    if not space_values[:temp_min].nil?
      if space_values[:temp_min].is_a? String
        min_temp_c = space_values[:temp_min]
      else
        min_temp_c = UnitConversions.convert(space_values[:temp_min], 'F', 'C')
      end
      program.addLine("If #{actuator.name} < #{min_temp_c}")
      program.addLine("Set #{actuator.name} = #{min_temp_c}")
      program.addLine('EndIf')
    end

    program_cm = OpenStudio::Model::EnergyManagementSystemProgramCallingManager.new(model)
    program_cm.setName("#{program.name} calling manager")
    program_cm.setCallingPoint('EndOfSystemTimestepAfterHVACReporting')
    program_cm.addProgram(program)

    return sch
  end

  # Returns an OS:Space, or temperature OS:Schedule for a MF space, or nil if outside
  # Should be called when the object's energy use is sensitive to ambient temperature
  # (e.g., water heaters, ducts, and refrigerators).
  def get_space_or_schedule_from_location(location, model, spaces)
    return if [HPXML::LocationOtherExterior,
               HPXML::LocationOutside,
               HPXML::LocationRoofDeck].include? location

    sch = nil
    space = nil
    if [HPXML::LocationOtherHeatedSpace,
        HPXML::LocationOtherHousingUnit,
        HPXML::LocationOtherMultifamilyBufferSpace,
        HPXML::LocationOtherNonFreezingSpace,
        HPXML::LocationExteriorWall,
        HPXML::LocationUnderSlab].include? location
      # if located in spaces where we don't model a thermal zone, create and return temperature schedule
      sch = get_space_temperature_schedule(model, location, spaces)
    else
      space = get_space_from_location(location, spaces)
    end

    return space, sch
  end

  # Returns an OS:Space, or nil if a MF space or outside
  # Should be called when the object's energy use is NOT sensitive to ambient temperature
  # (e.g., appliances).
  def get_space_from_location(location, spaces)
    return if [HPXML::LocationOutside,
               HPXML::LocationOtherHeatedSpace,
               HPXML::LocationOtherHousingUnit,
               HPXML::LocationOtherMultifamilyBufferSpace,
               HPXML::LocationOtherNonFreezingSpace].include? location

    if HPXML::conditioned_locations.include? location
      location = HPXML::LocationConditionedSpace
    end

    return spaces[location]
  end

  def set_subsurface_exterior(surface, spaces, model, hpxml_surface)
    # Set its parent surface outside boundary condition, which will be also applied to subsurfaces through OS
    # The parent surface is entirely comprised of the subsurface.

    # Subsurface on foundation wall, set it to be adjacent to outdoors
    if hpxml_surface.exterior_adjacent_to == HPXML::LocationGround
      surface.setOutsideBoundaryCondition('Outdoors')
    else
      set_surface_exterior(model, spaces, surface, hpxml_surface)
    end
  end

  def set_foundation_and_walls_top()
    @foundation_top = 0
    @hpxml_bldg.floors.each do |floor|
      # Keeping the floor at ground level for ASHRAE 140 tests yields the expected results
      if floor.is_floor && floor.is_exterior && !@apply_ashrae140_assumptions
        @foundation_top = 2.0
      end
    end
    @hpxml_bldg.foundation_walls.each do |foundation_wall|
      top = -1 * foundation_wall.depth_below_grade + foundation_wall.height
      @foundation_top = top if top > @foundation_top
    end
    @walls_top = @foundation_top + @hpxml_bldg.building_construction.average_ceiling_height * @ncfl_ag
  end

  def set_heating_and_cooling_seasons()
    return if @hpxml_bldg.hvac_controls.size == 0

    hvac_control = @hpxml_bldg.hvac_controls[0]

    htg_start_month = hvac_control.seasons_heating_begin_month
    htg_start_day = hvac_control.seasons_heating_begin_day
    htg_end_month = hvac_control.seasons_heating_end_month
    htg_end_day = hvac_control.seasons_heating_end_day
    clg_start_month = hvac_control.seasons_cooling_begin_month
    clg_start_day = hvac_control.seasons_cooling_begin_day
    clg_end_month = hvac_control.seasons_cooling_end_month
    clg_end_day = hvac_control.seasons_cooling_end_day

    @heating_days = Schedule.get_daily_season(@hpxml_header.sim_calendar_year, htg_start_month, htg_start_day, htg_end_month, htg_end_day)
    @cooling_days = Schedule.get_daily_season(@hpxml_header.sim_calendar_year, clg_start_month, clg_start_day, clg_end_month, clg_end_day)
  end
end

# register the measure to be used by the application
HPXMLtoOpenStudio.new.registerWithApplication
