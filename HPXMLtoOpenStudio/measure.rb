# frozen_string_literal: true

# Require all gems up front; this is much faster than multiple resource
# files lazy loading as needed, as it prevents multiple lookups for the
# same gem.
require 'openstudio'
require 'pathname'
require 'csv'
require 'oga'
require_relative 'resources/airflow'
require_relative 'resources/constants'
require_relative 'resources/constructions'
require_relative 'resources/energyplus'
require_relative 'resources/EPvalidator'
require_relative 'resources/geometry'
require_relative 'resources/hotwater_appliances'
require_relative 'resources/hpxml'
require_relative 'resources/hpxml_defaults'
require_relative 'resources/hvac'
require_relative 'resources/hvac_sizing'
require_relative 'resources/lighting'
require_relative 'resources/location'
require_relative 'resources/materials'
require_relative 'resources/misc_loads'
require_relative 'resources/psychrometrics'
require_relative 'resources/pv'
require_relative 'resources/schedules'
require_relative 'resources/simcontrols'
require_relative 'resources/unit_conversions'
require_relative 'resources/util'
require_relative 'resources/waterheater'
require_relative 'resources/weather'
require_relative 'resources/xmlhelper'

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
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('hpxml_path', true)
    arg.setDisplayName('HPXML File Path')
    arg.setDescription('Absolute/relative path of the HPXML file.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('weather_dir', true)
    arg.setDisplayName('Weather Directory')
    arg.setDescription('Absolute/relative path of the weather directory.')
    arg.setDefaultValue('weather')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('output_dir', false)
    arg.setDisplayName('Directory for Output Files')
    arg.setDescription('Absolute/relative path for the output files directory.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeBoolArgument('debug', false)
    arg.setDisplayName('Debug Mode?')
    arg.setDescription('If enabled: 1) Writes in.osm file, 2) Writes in.xml HPXML file with defaults filled, and 3) Generates additional log output. Any files written will be in the output path specified above.')
    arg.setDefaultValue(false)
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

    tear_down_model(model, runner)

    # Check for correct versions of OS
    os_version = '3.0.0'
    if OpenStudio.openStudioVersion != os_version
      fail "OpenStudio version #{os_version} is required."
    end

    # assign the user inputs to variables
    hpxml_path = runner.getStringArgumentValue('hpxml_path', user_arguments)
    weather_dir = runner.getStringArgumentValue('weather_dir', user_arguments)
    output_dir = runner.getOptionalStringArgumentValue('output_dir', user_arguments)
    debug = runner.getBoolArgumentValue('debug', user_arguments)

    unless (Pathname.new hpxml_path).absolute?
      hpxml_path = File.expand_path(File.join(File.dirname(__FILE__), hpxml_path))
    end
    unless File.exist?(hpxml_path) && hpxml_path.downcase.end_with?('.xml')
      fail "'#{hpxml_path}' does not exist or is not an .xml file."
    end

    unless (Pathname.new weather_dir).absolute?
      weather_dir = File.expand_path(File.join(File.dirname(__FILE__), '..', weather_dir))
    end
    if output_dir.is_initialized
      output_dir = output_dir.get
      unless (Pathname.new output_dir).absolute?
        output_dir = File.expand_path(File.join(File.dirname(__FILE__), output_dir))
      end
    else
      output_dir = nil
    end

    begin
      hpxml = HPXML.new(hpxml_path: hpxml_path)

      if not validate_hpxml(runner, hpxml_path, hpxml)
        return false
      end

      epw_path, cache_path = process_weather(hpxml, runner, model, weather_dir, output_dir)

      OSModel.create(hpxml, runner, model, hpxml_path, epw_path, cache_path, output_dir, debug)
    rescue Exception => e
      runner.registerError("#{e.message}\n#{e.backtrace.join("\n")}")
      return false
    end

    return true
  end

  def tear_down_model(model, runner)
    # Tear down the existing model if it exists
    has_existing_objects = (model.getThermalZones.size > 0)
    handles = OpenStudio::UUIDVector.new
    model.objects.each do |obj|
      handles << obj.handle
    end
    model.removeObjects(handles)
    if has_existing_objects
      runner.registerWarning('The model contains existing objects and is being reset.')
    end
  end

  def validate_hpxml(runner, hpxml_path, hpxml)
    schemas_dir = File.join(File.dirname(__FILE__), 'resources')

    is_valid = true

    # Validate input HPXML against schema
    XMLHelper.validate(hpxml.doc.to_xml, File.join(schemas_dir, 'HPXML.xsd'), runner).each do |error|
      runner.registerError("#{hpxml_path}: #{error}")
      is_valid = false
    end

    # Validate input HPXML against EnergyPlus Use Case
    errors = EnergyPlusValidator.run_validator(hpxml.doc)
    errors.each do |error|
      runner.registerError("#{hpxml_path}: #{error}")
      is_valid = false
    end

    # Check for additional errors
    errors = hpxml.check_for_errors()
    errors.each do |error|
      runner.registerError("#{hpxml_path}: #{error}")
      is_valid = false
    end

    return is_valid
  end

  def process_weather(hpxml, runner, model, weather_dir, output_dir)
    epw_path = hpxml.climate_and_risk_zones.weather_station_epw_filepath

    if not epw_path.nil?
      if not File.exist? epw_path
        epw_path = File.join(weather_dir, epw_path)
      end
      if not File.exist?(epw_path)
        fail "'#{epw_path}' could not be found."
      end
    else
      weather_wmo = hpxml.climate_and_risk_zones.weather_station_wmo
      CSV.foreach(File.join(weather_dir, 'data.csv'), headers: true) do |row|
        next if row['wmo'] != weather_wmo

        epw_path = File.join(weather_dir, row['filename'])
        if not File.exist?(epw_path)
          fail "'#{epw_path}' could not be found."
        end

        break
      end
      if epw_path.nil?
        fail "Weather station WMO '#{weather_wmo}' could not be found in #{File.join(weather_dir, 'data.csv')}."
      end
    end

    cache_path = epw_path.gsub('.epw', '-cache.csv')
    if not File.exist?(cache_path)
      # Process weather file to create cache .csv
      runner.registerWarning("'#{cache_path}' could not be found; regenerating it.")
      epw_file = OpenStudio::EpwFile.new(epw_path)
      OpenStudio::Model::WeatherFile.setWeatherFile(model, epw_file)
      weather = WeatherProcess.new(model, runner)
      File.open(cache_path, 'wb') do |file|
        weather.dump_to_csv(file)
      end
    end

    if not output_dir.nil?
      epw_output_path = File.join(output_dir, 'in.epw')
      FileUtils.cp(epw_path, epw_output_path)
      runner.registerInfo("Copied EPW to: #{epw_output_path}")
    end

    return epw_path, cache_path
  end
end

class OSModel
  def self.create(hpxml, runner, model, hpxml_path, epw_path, cache_path, output_dir, debug)
    @hpxml = hpxml
    @debug = debug

    @eri_version = @hpxml.header.eri_calculation_version # Hidden feature
    @eri_version = 'latest' if @eri_version.nil?
    @eri_version = Constants.ERIVersions[-1] if @eri_version == 'latest'

    @apply_ashrae140_assumptions = @hpxml.header.apply_ashrae140_assumptions # Hidden feature
    @apply_ashrae140_assumptions = false if @apply_ashrae140_assumptions.nil?

    # Init

    weather, epw_file = Location.apply_weather_file(model, runner, epw_path, cache_path)
    check_for_errors()
    set_defaults_and_globals(runner, output_dir, epw_file)
    weather = Location.apply(model, runner, weather, epw_file, @hpxml)
    add_simulation_params(model)

    # Conditioned space/zone

    spaces = {}
    create_or_get_space(model, spaces, HPXML::LocationLivingSpace)
    set_foundation_and_walls_top()
    add_setpoints(runner, model, weather, spaces)

    # Geometry/Envelope
    add_roofs(runner, model, spaces)
    add_walls(runner, model, spaces)
    add_rim_joists(runner, model, spaces)
    add_frame_floors(runner, model, spaces)
    add_foundation_walls_slabs(runner, model, spaces)
    add_interior_shading_schedule(runner, model, weather)
    add_windows(runner, model, spaces, weather)
    add_doors(runner, model, spaces)
    add_skylights(runner, model, spaces, weather)
    add_conditioned_floor_area(runner, model, spaces)
    add_thermal_mass(runner, model, spaces)
    modify_cond_basement_surface_properties(runner, model)
    assign_view_factor(runner, model, spaces)
    set_zone_volumes(runner, model, spaces)
    explode_surfaces(runner, model)
    add_num_occupants(model, runner, spaces)

    # HVAC

    add_ideal_system_for_partial_hvac(runner, model, spaces)
    add_cooling_system(runner, model, spaces)
    add_heating_system(runner, model, spaces)
    add_heat_pump(runner, model, weather, spaces)
    add_dehumidifier(runner, model, spaces)
    add_residual_hvac(runner, model, spaces)
    add_ceiling_fans(runner, model, weather, spaces)

    # Hot Water

    add_hot_water_and_appliances(runner, model, weather, spaces)

    # Plug Loads & Fuel Loads & Lighting

    add_mels(runner, model, spaces)
    add_mfls(runner, model, spaces)
    add_lighting(runner, model, weather, spaces)

    # Pools & Hot Tubs
    add_pools_and_hot_tubs(runner, model, spaces)

    # Other

    add_airflow(runner, model, weather, spaces)
    add_hvac_sizing(runner, model, weather, spaces)
    add_fuel_heating_eae(runner, model)
    add_photovoltaics(runner, model)
    add_additional_properties(runner, model, hpxml_path)
    add_component_loads_output(runner, model, spaces)

    if debug && (not output_dir.nil?)
      osm_output_path = File.join(output_dir, 'in.osm')
      File.write(osm_output_path, model.to_s)
      runner.registerInfo("Wrote file: #{osm_output_path}")
    end
  end

  private

  def self.check_for_errors()
    # Conditioned space
    location = HPXML::LocationLivingSpace
    if (@hpxml.roofs.select { |s| s.interior_adjacent_to == location }.size +
        @hpxml.frame_floors.select { |s| s.is_ceiling && (s.interior_adjacent_to == location) }.size) == 0
      fail 'There must be at least one ceiling/roof adjacent to conditioned space.'
    end
    if @hpxml.walls.select { |s| (s.interior_adjacent_to == location) && s.is_exterior }.size == 0
      fail 'There must be at least one exterior wall adjacent to conditioned space.'
    end
    if (@hpxml.slabs.select { |s| [location, HPXML::LocationBasementConditioned].include? s.interior_adjacent_to }.size +
        @hpxml.frame_floors.select { |s| s.is_floor && (s.interior_adjacent_to == location) }.size) == 0
      fail 'There must be at least one floor/slab adjacent to conditioned space.'
    end

    # Basement/Crawlspace
    [HPXML::LocationBasementConditioned,
     HPXML::LocationBasementUnconditioned,
     HPXML::LocationCrawlspaceVented,
     HPXML::LocationCrawlspaceUnvented].each do |location|
      next unless @hpxml.has_space_type(location)

      if location != HPXML::LocationBasementConditioned # HPXML file doesn't need to have FrameFloor between living and conditioned basement
        if @hpxml.frame_floors.select { |s| s.is_floor && (s.interior_adjacent_to == HPXML::LocationLivingSpace) && (s.exterior_adjacent_to == location) }.size == 0
          fail "There must be at least one ceiling adjacent to #{location}."
        end
      end
      if @hpxml.foundation_walls.select { |s| (s.interior_adjacent_to == location) && s.is_exterior }.size == 0
        fail "There must be at least one exterior foundation wall adjacent to #{location}."
      end
      if @hpxml.slabs.select { |s| s.interior_adjacent_to == location }.size == 0
        fail "There must be at least one slab adjacent to #{location}."
      end
    end

    # Garage
    location = HPXML::LocationGarage
    if @hpxml.has_space_type(location)
      if (@hpxml.roofs.select { |s| s.interior_adjacent_to == location }.size +
          @hpxml.frame_floors.select { |s| [s.interior_adjacent_to, s.exterior_adjacent_to].include? location }.size) == 0
        fail "There must be at least one roof/ceiling adjacent to #{location}."
      end
      if (@hpxml.walls.select { |s| (s.interior_adjacent_to == location) && s.is_exterior }.size +
         @hpxml.foundation_walls.select { |s| [s.interior_adjacent_to, s.exterior_adjacent_to].include?(location) && s.is_exterior }.size) == 0
        fail "There must be at least one exterior wall/foundation wall adjacent to #{location}."
      end
      if @hpxml.slabs.select { |s| s.interior_adjacent_to == location }.size == 0
        fail "There must be at least one slab adjacent to #{location}."
      end
    end

    # Attic
    [HPXML::LocationAtticVented,
     HPXML::LocationAtticUnvented].each do |location|
      next unless @hpxml.has_space_type(location)

      if @hpxml.roofs.select { |s| s.interior_adjacent_to == location }.size == 0
        fail "There must be at least one roof adjacent to #{location}."
      end

      if @hpxml.frame_floors.select { |s| s.is_ceiling && [s.interior_adjacent_to, s.exterior_adjacent_to].include?(location) }.size == 0
        fail "There must be at least one floor adjacent to #{location}."
      end
    end
  end

  def self.set_defaults_and_globals(runner, output_dir, epw_file)
    # Initialize
    @remaining_heat_load_frac = 1.0
    @remaining_cool_load_frac = 1.0
    @hvac_map = {} # mapping between HPXML HVAC systems and model objects
    @dhw_map = {}  # mapping between HPXML Water Heating systems and model objects
    @cond_bsmnt_surfaces = [] # list of surfaces in conditioned basement, used for modification of some surface properties, eg. solar absorptance, view factor, etc.

    # Set globals
    @cfa = @hpxml.building_construction.conditioned_floor_area
    @ncfl = @hpxml.building_construction.number_of_conditioned_floors
    @ncfl_ag = @hpxml.building_construction.number_of_conditioned_floors_above_grade
    @nbeds = @hpxml.building_construction.number_of_bedrooms
    @min_neighbor_distance = get_min_neighbor_distance()
    @default_azimuths = get_default_azimuths()
    @has_uncond_bsmnt = @hpxml.has_space_type(HPXML::LocationBasementUnconditioned)

    if @hpxml.building_construction.use_only_ideal_air_system.nil?
      @hpxml.building_construction.use_only_ideal_air_system = false
    end

    # Apply defaults to HPXML object
    HPXMLDefaults.apply(@hpxml, @cfa, @nbeds, @ncfl, @ncfl_ag, @has_uncond_bsmnt, @eri_version, epw_file)

    @frac_windows_operable = @hpxml.fraction_of_windows_operable()

    if @debug && (not output_dir.nil?)
      # Write updated HPXML object to file
      hpxml_defaults_path = File.join(output_dir, 'in.xml')
      XMLHelper.write_file(@hpxml.to_oga, hpxml_defaults_path)
      runner.registerInfo("Wrote file: #{hpxml_defaults_path}")
    end
  end

  def self.add_simulation_params(model)
    SimControls.apply(model, @hpxml.header)
  end

  def self.set_zone_volumes(runner, model, spaces)
    # Living space
    spaces[HPXML::LocationLivingSpace].thermalZone.get.setVolume(UnitConversions.convert(@hpxml.building_construction.conditioned_building_volume, 'ft^3', 'm^3'))

    # Basement, crawlspace, garage
    spaces.keys.each do |space_type|
      next unless [HPXML::LocationBasementUnconditioned, HPXML::LocationCrawlspaceUnvented, HPXML::LocationCrawlspaceVented, HPXML::LocationGarage].include? space_type

      floor_area = @hpxml.slabs.select { |s| s.interior_adjacent_to == space_type }.map { |s| s.area }.inject(:+)
      if space_type == HPXML::LocationGarage
        height = 8.0
      else
        height = @hpxml.foundation_walls.select { |w| w.interior_adjacent_to == space_type }.map { |w| w.height }.max
      end

      spaces[space_type].thermalZone.get.setVolume(UnitConversions.convert(floor_area * height, 'ft^3', 'm^3'))
    end

    # Attic
    spaces.keys.each do |space_type|
      next unless [HPXML::LocationAtticUnvented, HPXML::LocationAtticVented].include? space_type

      floor_area = @hpxml.frame_floors.select { |f| [f.interior_adjacent_to, f.exterior_adjacent_to].include? space_type }.map { |s| s.area }.inject(:+)
      roofs = @hpxml.roofs.select { |r| r.interior_adjacent_to == space_type }
      avg_pitch = roofs.map { |r| r.pitch }.inject(:+) / roofs.size

      # Assume square hip roof for volume calculations; energy results are very insensitive to actual volume
      length = floor_area**0.5
      height = 0.5 * Math.sin(Math.atan(avg_pitch / 12.0)) * length
      volume = [floor_area * height / 3.0, 0.01].max

      spaces[space_type].thermalZone.get.setVolume(UnitConversions.convert(volume, 'ft^3', 'm^3'))
    end
  end

  def self.explode_surfaces(runner, model)
    # Re-position surfaces so as to not shade each other and to make it easier to visualize the building.
    # FUTURE: Might be able to use the new self-shading options in E+ 8.9 ShadowCalculation object instead?

    gap_distance = UnitConversions.convert(10.0, 'ft', 'm') # distance between surfaces of the same azimuth
    rad90 = UnitConversions.convert(90, 'deg', 'rad')

    # Determine surfaces to shift and distance with which to explode surfaces horizontally outward
    surfaces = []
    azimuth_lengths = {}
    model.getSurfaces.sort.each do |surface|
      next unless ['wall', 'roofceiling'].include? surface.surfaceType.downcase
      next unless ['outdoors', 'foundation'].include? surface.outsideBoundaryCondition.downcase
      next if surface.additionalProperties.getFeatureAsDouble('Tilt').get <= 0 # skip flat roofs

      surfaces << surface
      azimuth = surface.additionalProperties.getFeatureAsInteger('Azimuth').get
      if azimuth_lengths[azimuth].nil?
        azimuth_lengths[azimuth] = 0.0
      end
      azimuth_lengths[azimuth] += surface.additionalProperties.getFeatureAsDouble('Length').get + gap_distance
    end
    max_azimuth_length = azimuth_lengths.values.max

    # Using the max length for a given azimuth, calculate the apothem (radius of the incircle) of a regular
    # n-sided polygon to create the smallest polygon possible without self-shading. The number of polygon
    # sides is defined by the minimum difference between two azimuths.
    min_azimuth_diff = 360
    azimuths_sorted = azimuth_lengths.keys.sort
    azimuths_sorted.each_with_index do |az, idx|
      diff1 = (az - azimuths_sorted[(idx + 1) % azimuths_sorted.size]).abs
      diff2 = 360.0 - diff1 # opposite direction
      if diff1 < min_azimuth_diff
        min_azimuth_diff = diff1
      end
      if diff2 < min_azimuth_diff
        min_azimuth_diff = diff2
      end
    end
    if min_azimuth_diff > 0
      nsides = [(360.0 / min_azimuth_diff).ceil, 4].max # assume rectangle at the minimum
    else
      nsides = 4
    end
    explode_distance = max_azimuth_length / (2.0 * Math.tan(UnitConversions.convert(180.0 / nsides, 'deg', 'rad')))

    add_neighbors(runner, model, max_azimuth_length)

    # Initial distance of shifts at 90-degrees to horizontal outward
    azimuth_side_shifts = {}
    azimuth_lengths.keys.each do |azimuth|
      azimuth_side_shifts[azimuth] = max_azimuth_length / 2.0
    end

    # Explode neighbors
    model.getShadingSurfaceGroups.each do |shading_surface_group|
      next if shading_surface_group.name.to_s != Constants.ObjectNameNeighbors

      shading_surface_group.shadingSurfaces.each do |shading_surface|
        azimuth = shading_surface.additionalProperties.getFeatureAsInteger('Azimuth').get
        azimuth_rad = UnitConversions.convert(azimuth, 'deg', 'rad')
        distance = shading_surface.additionalProperties.getFeatureAsDouble('Distance').get

        unless azimuth_lengths.keys.include? azimuth
          fail "A neighbor building has an azimuth (#{azimuth}) not equal to the azimuth of any wall."
        end

        # Push out horizontally
        distance += explode_distance
        transformation = get_surface_transformation(distance, Math::sin(azimuth_rad), Math::cos(azimuth_rad), 0)

        shading_surface.setVertices(transformation * shading_surface.vertices)
      end
    end

    # Explode walls, windows, doors, roofs, and skylights
    surfaces_moved = []

    surfaces.sort.each do |surface|
      next if surface.additionalProperties.getFeatureAsDouble('Tilt').get <= 0 # skip flat roofs

      if surface.adjacentSurface.is_initialized
        next if surfaces_moved.include? surface.adjacentSurface.get
      end

      azimuth = surface.additionalProperties.getFeatureAsInteger('Azimuth').get
      azimuth_rad = UnitConversions.convert(azimuth, 'deg', 'rad')

      # Push out horizontally
      distance = explode_distance

      if surface.surfaceType.downcase == 'roofceiling'
        # Ensure pitched surfaces are positioned outward justified with walls, etc.
        tilt = surface.additionalProperties.getFeatureAsDouble('Tilt').get
        width = surface.additionalProperties.getFeatureAsDouble('Width').get
        distance -= 0.5 * Math.cos(Math.atan(tilt)) * width
      end
      transformation = get_surface_transformation(distance, Math::sin(azimuth_rad), Math::cos(azimuth_rad), 0)

      surface.setVertices(transformation * surface.vertices)
      if surface.adjacentSurface.is_initialized
        surface.adjacentSurface.get.setVertices(transformation * surface.adjacentSurface.get.vertices)
      end
      surface.subSurfaces.each do |subsurface|
        subsurface.setVertices(transformation * subsurface.vertices)
        next unless subsurface.subSurfaceType.downcase == 'fixedwindow'

        subsurface.shadingSurfaceGroups.each do |overhang_group|
          overhang_group.shadingSurfaces.each do |overhang|
            overhang.setVertices(transformation * overhang.vertices)
          end
        end
      end

      # Shift at 90-degrees to previous transformation
      azimuth_side_shifts[azimuth] -= surface.additionalProperties.getFeatureAsDouble('Length').get / 2.0
      transformation_shift = get_surface_transformation(azimuth_side_shifts[azimuth], Math::sin(azimuth_rad + rad90), Math::cos(azimuth_rad + rad90), 0)

      surface.setVertices(transformation_shift * surface.vertices)
      if surface.adjacentSurface.is_initialized
        surface.adjacentSurface.get.setVertices(transformation_shift * surface.adjacentSurface.get.vertices)
      end
      surface.subSurfaces.each do |subsurface|
        subsurface.setVertices(transformation_shift * subsurface.vertices)
        next unless subsurface.subSurfaceType.downcase == 'fixedwindow'

        subsurface.shadingSurfaceGroups.each do |overhang_group|
          overhang_group.shadingSurfaces.each do |overhang|
            overhang.setVertices(transformation_shift * overhang.vertices)
          end
        end
      end

      azimuth_side_shifts[azimuth] -= (surface.additionalProperties.getFeatureAsDouble('Length').get / 2.0 + gap_distance)

      surfaces_moved << surface
    end
  end

  def self.modify_cond_basement_surface_properties(runner, model)
    # modify conditioned basement surface properties
    # - zero out interior solar absorptance in conditioned basement
    @cond_bsmnt_surfaces.each do |cond_bsmnt_surface|
      const = cond_bsmnt_surface.construction.get
      layered_const = const.to_LayeredConstruction.get
      innermost_material = layered_const.layers[layered_const.numLayers() - 1].to_StandardOpaqueMaterial.get
      # check if target surface is sharing its interior material/construction object with other surfaces
      # if so, need to clone the material/construction and make changes there, then reassign it to target surface
      mat_share = (innermost_material.directUseCount != 1)
      const_share = (const.directUseCount != 1)
      if const_share
        # create new construction + new material for these surfaces
        new_const = const.clone.to_Construction.get
        cond_bsmnt_surface.setConstruction(new_const)
        new_material = innermost_material.clone.to_StandardOpaqueMaterial.get
        layered_const = new_const.to_LayeredConstruction.get
        layered_const.setLayer(layered_const.numLayers() - 1, new_material)
      elsif mat_share
        # create new material for existing unique construction
        new_material = innermost_material.clone.to_StandardOpaqueMaterial.get
        layered_const.setLayer(layered_const.numLayers() - 1, new_material)
      end
      if layered_const.numLayers() == 1
        # split single layer into two to only change its inside facing property
        layer_mat = layered_const.layers[0].to_StandardOpaqueMaterial.get
        layer_mat.setThickness(layer_mat.thickness / 2)
        layered_const.insertLayer(1, layer_mat.clone.to_StandardOpaqueMaterial.get)
      end
      # Re-read innermost material and assign properties after adjustment
      innermost_material = layered_const.layers[layered_const.numLayers() - 1].to_StandardOpaqueMaterial.get
      innermost_material.setSolarAbsorptance(0.0)
      innermost_material.setVisibleAbsorptance(0.0)
    end
  end

  def self.assign_view_factor(runner, model, spaces)
    return if @cond_bsmnt_surfaces.empty?

    # zero out view factors between conditioned basement surfaces and living zone surfaces
    all_surfaces = [] # all surfaces in single conditioned space
    lv_surfaces = []  # surfaces in living
    cond_base_surfaces = [] # surfaces in conditioned basement

    spaces[HPXML::LocationLivingSpace].surfaces.each do |surface|
      surface.subSurfaces.each do |sub_surface|
        all_surfaces << sub_surface
      end
      all_surfaces << surface
    end
    spaces[HPXML::LocationLivingSpace].internalMass.each do |im|
      all_surfaces << im
    end

    all_surfaces.each do |surface|
      if @cond_bsmnt_surfaces.include?(surface) ||
         ((@cond_bsmnt_surfaces.include? surface.internalMassDefinition) if surface.is_a? OpenStudio::Model::InternalMass) ||
         ((@cond_bsmnt_surfaces.include? surface.surface.get) if surface.is_a? OpenStudio::Model::SubSurface)
        cond_base_surfaces << surface
      else
        lv_surfaces << surface
      end
    end

    all_surfaces.sort!

    # calculate view factors separately for living and conditioned basement
    vf_map_lv = calc_approximate_view_factor(runner, model, lv_surfaces)
    vf_map_cb = calc_approximate_view_factor(runner, model, cond_base_surfaces)

    zone_prop = spaces[HPXML::LocationLivingSpace].thermalZone.get.getZonePropertyUserViewFactorsBySurfaceName

    all_surfaces.each do |from_surface|
      all_surfaces.each do |to_surface|
        next if (vf_map_lv[from_surface].nil? || vf_map_lv[from_surface][to_surface].nil?) &&
                (vf_map_cb[from_surface].nil? || vf_map_cb[from_surface][to_surface].nil?)

        if lv_surfaces.include? from_surface
          vf = vf_map_lv[from_surface][to_surface]
        else
          vf = vf_map_cb[from_surface][to_surface]
        end
        next if vf < 0.01

        os_vf = OpenStudio::Model::ViewFactor.new(from_surface, to_surface, vf.round(10))
        zone_prop.addViewFactor(os_vf)
      end
    end
  end

  def self.calc_approximate_view_factor(runner, model, all_surfaces)
    # calculate approximate view factor using E+ approach
    # used for recalculating single thermal zone view factor matrix
    return {} if all_surfaces.size == 0
    if all_surfaces.size <= 3
      fail 'less than three surfaces in conditioned space. Please double check.'
    end

    s_azimuths = {}
    s_tilts = {}
    s_types = {}
    all_surfaces.each do |surface|
      if surface.is_a? OpenStudio::Model::InternalMass
        # Assumed values consistent with EnergyPlus source code
        s_azimuths[surface] = 0.0
        s_tilts[surface] = 90.0
      else
        s_azimuths[surface] = UnitConversions.convert(surface.azimuth, 'rad', 'deg')
        s_tilts[surface] = UnitConversions.convert(surface.tilt, 'rad', 'deg')
        if surface.is_a? OpenStudio::Model::SubSurface
          s_types[surface] = surface.surface.get.surfaceType.downcase
        else
          s_types[surface] = surface.surfaceType.downcase
        end
      end
    end

    same_ang_limit = 10.0
    vf_map = {}
    all_surfaces.each do |surface| # surface, subsurface, and internal mass
      surface_vf_map = {}

      # sum all the surface area that could be seen by surface1 up
      zone_seen_area = 0.0
      seen_surface = {}
      all_surfaces.each do |surface2|
        next if surface2 == surface
        next if surface2.is_a? OpenStudio::Model::SubSurface

        seen_surface[surface2] = false
        if surface2.is_a? OpenStudio::Model::InternalMass
          # all surfaces see internal mass
          zone_seen_area += surface2.surfaceArea.get
          seen_surface[surface2] = true
        else
          if (s_types[surface2] == 'floor') ||
             ((s_types[surface] == 'floor') && (s_types[surface2] == 'roofceiling')) ||
             ((s_azimuths[surface] - s_azimuths[surface2]).abs > same_ang_limit) ||
             ((s_tilts[surface] - s_tilts[surface2]).abs > same_ang_limit)
            zone_seen_area += surface2.grossArea # include subsurface area
            seen_surface[surface2] = true
          end
        end
      end

      all_surfaces.each do |surface2|
        next if surface2 == surface
        next if surface2.is_a? OpenStudio::Model::SubSurface # handled together with its parent surface
        next unless seen_surface[surface2]

        if surface2.is_a? OpenStudio::Model::InternalMass
          surface_vf_map[surface2] = surface2.surfaceArea.get / zone_seen_area
        else # surfaces
          if surface2.subSurfaces.size > 0
            # calculate surface and its sub surfaces view factors
            if surface2.netArea > 0.1 # base surface of a sub surface: window/door etc.
              fail "Unexpected net area for surface '#{surface2.name}'."
            end

            surface2.subSurfaces.each do |sub_surface|
              surface_vf_map[sub_surface] = sub_surface.grossArea / zone_seen_area
            end
          else # no subsurface
            surface_vf_map[surface2] = surface2.grossArea / zone_seen_area
          end
        end
      end
      vf_map[surface] = surface_vf_map
    end
    return vf_map
  end

  # FUTURE: Move this method and many below to geometry.rb
  def self.create_space_and_zone(model, spaces, space_type)
    if not spaces.keys.include? space_type
      thermal_zone = OpenStudio::Model::ThermalZone.new(model)
      thermal_zone.setName(space_type)

      space = OpenStudio::Model::Space.new(model)
      space.setName(space_type)

      st = OpenStudio::Model::SpaceType.new(model)
      st.setStandardsSpaceType(space_type)
      space.setSpaceType(st)

      space.setThermalZone(thermal_zone)
      spaces[space_type] = space
    end
  end

  def self.get_surface_transformation(offset, x, y, z)
    x = UnitConversions.convert(x, 'ft', 'm')
    y = UnitConversions.convert(y, 'ft', 'm')
    z = UnitConversions.convert(z, 'ft', 'm')

    m = OpenStudio::Matrix.new(4, 4, 0)
    m[0, 0] = 1
    m[1, 1] = 1
    m[2, 2] = 1
    m[3, 3] = 1
    m[0, 3] = x * offset
    m[1, 3] = y * offset
    m[2, 3] = z.abs * offset

    return OpenStudio::Transformation.new(m)
  end

  def self.add_floor_polygon(x, y, z)
    x = UnitConversions.convert(x, 'ft', 'm')
    y = UnitConversions.convert(y, 'ft', 'm')
    z = UnitConversions.convert(z, 'ft', 'm')

    vertices = OpenStudio::Point3dVector.new
    vertices << OpenStudio::Point3d.new(0 - x / 2, 0 - y / 2, z)
    vertices << OpenStudio::Point3d.new(0 - x / 2, y / 2, z)
    vertices << OpenStudio::Point3d.new(x / 2, y / 2, z)
    vertices << OpenStudio::Point3d.new(x / 2, 0 - y / 2, z)

    return vertices
  end

  def self.add_wall_polygon(x, y, z, azimuth = 0, offsets = [0] * 4, subsurface_area = 0)
    x = UnitConversions.convert(x, 'ft', 'm')
    y = UnitConversions.convert(y, 'ft', 'm')
    z = UnitConversions.convert(z, 'ft', 'm')

    vertices = OpenStudio::Point3dVector.new
    vertices << OpenStudio::Point3d.new(0 - (x / 2) - offsets[1], 0, z - offsets[0])
    vertices << OpenStudio::Point3d.new(0 - (x / 2) - offsets[1], 0, z + y + offsets[2])
    if subsurface_area > 0
      subsurface_area = UnitConversions.convert(subsurface_area, 'ft^2', 'm^2')
      sub_length = x / 10.0
      sub_height = subsurface_area / sub_length
      if sub_height >= y
        sub_height = y - 0.1
        sub_length = subsurface_area / sub_height
      end
      vertices << OpenStudio::Point3d.new(x - (x / 2) + offsets[3] - sub_length, 0, z + y + offsets[2])
      vertices << OpenStudio::Point3d.new(x - (x / 2) + offsets[3] - sub_length, 0, z + y + offsets[2] - sub_height)
      vertices << OpenStudio::Point3d.new(x - (x / 2) + offsets[3], 0, z + y + offsets[2] - sub_height)
    else
      vertices << OpenStudio::Point3d.new(x - (x / 2) + offsets[3], 0, z + y + offsets[2])
    end
    vertices << OpenStudio::Point3d.new(x - (x / 2) + offsets[3], 0, z - offsets[0])

    # Rotate about the z axis
    azimuth_rad = UnitConversions.convert(azimuth, 'deg', 'rad')
    m = OpenStudio::Matrix.new(4, 4, 0)
    m[0, 0] = Math::cos(-azimuth_rad)
    m[1, 1] = Math::cos(-azimuth_rad)
    m[0, 1] = -Math::sin(-azimuth_rad)
    m[1, 0] = Math::sin(-azimuth_rad)
    m[2, 2] = 1
    m[3, 3] = 1
    transformation = OpenStudio::Transformation.new(m)

    return transformation * vertices
  end

  def self.add_roof_polygon(x, y, z, azimuth = 0, tilt = 0.5)
    x = UnitConversions.convert(x, 'ft', 'm')
    y = UnitConversions.convert(y, 'ft', 'm')
    z = UnitConversions.convert(z, 'ft', 'm')

    vertices = OpenStudio::Point3dVector.new
    vertices << OpenStudio::Point3d.new(x / 2, -y / 2, 0)
    vertices << OpenStudio::Point3d.new(x / 2, y / 2, 0)
    vertices << OpenStudio::Point3d.new(-x / 2, y / 2, 0)
    vertices << OpenStudio::Point3d.new(-x / 2, -y / 2, 0)

    # Rotate about the x axis
    m = OpenStudio::Matrix.new(4, 4, 0)
    m[0, 0] = 1
    m[1, 1] = Math::cos(Math::atan(tilt))
    m[1, 2] = -Math::sin(Math::atan(tilt))
    m[2, 1] = Math::sin(Math::atan(tilt))
    m[2, 2] = Math::cos(Math::atan(tilt))
    m[3, 3] = 1
    transformation = OpenStudio::Transformation.new(m)
    vertices = transformation * vertices

    # Rotate about the z axis
    azimuth_rad = UnitConversions.convert(azimuth, 'deg', 'rad')
    rad180 = UnitConversions.convert(180, 'deg', 'rad')
    m = OpenStudio::Matrix.new(4, 4, 0)
    m[0, 0] = Math::cos(rad180 - azimuth_rad)
    m[1, 1] = Math::cos(rad180 - azimuth_rad)
    m[0, 1] = -Math::sin(rad180 - azimuth_rad)
    m[1, 0] = Math::sin(rad180 - azimuth_rad)
    m[2, 2] = 1
    m[3, 3] = 1
    transformation = OpenStudio::Transformation.new(m)
    vertices = transformation * vertices

    # Shift up by z
    new_vertices = OpenStudio::Point3dVector.new
    vertices.each do |vertex|
      new_vertices << OpenStudio::Point3d.new(vertex.x, vertex.y, vertex.z + z)
    end

    return new_vertices
  end

  def self.add_ceiling_polygon(x, y, z)
    return OpenStudio::reverse(add_floor_polygon(x, y, z))
  end

  def self.add_num_occupants(model, runner, spaces)
    # Occupants
    num_occ = @hpxml.building_occupancy.number_of_residents
    if num_occ > 0
      occ_gain, hrs_per_day, sens_frac, lat_frac = Geometry.get_occupancy_default_values()
      weekday_sch = '1.00000, 1.00000, 1.00000, 1.00000, 1.00000, 1.00000, 1.00000, 0.88310, 0.40861, 0.24189, 0.24189, 0.24189, 0.24189, 0.24189, 0.24189, 0.24189, 0.29498, 0.55310, 0.89693, 0.89693, 0.89693, 1.00000, 1.00000, 1.00000'
      weekday_sch_sum = weekday_sch.split(',').map(&:to_f).inject(0, :+)
      if (weekday_sch_sum - hrs_per_day).abs > 0.1
        fail 'Occupancy schedule inconsistent with hrs_per_day.'
      end

      weekend_sch = weekday_sch
      monthly_sch = '1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0'
      Geometry.process_occupants(model, num_occ, occ_gain, sens_frac, lat_frac, weekday_sch, weekend_sch, monthly_sch, @cfa, @nbeds, spaces[HPXML::LocationLivingSpace])
    end
  end

  def self.get_default_azimuths()
    # Returns a list of four azimuths (facing each direction). Determined based
    # on the primary azimuth, as defined by the azimuth with the largest surface
    # area, plus azimuths that are offset by 90/180/270 degrees. Used for
    # surfaces that may not have an azimuth defined (e.g., walls).
    azimuth_areas = {}
    (@hpxml.roofs + @hpxml.rim_joists + @hpxml.walls + @hpxml.foundation_walls +
     @hpxml.windows + @hpxml.skylights + @hpxml.doors).each do |surface|
      az = surface.azimuth
      next if az.nil?

      azimuth_areas[az] = 0 if azimuth_areas[az].nil?
      azimuth_areas[az] += surface.area
    end
    if azimuth_areas.empty?
      primary_azimuth = 0
    else
      primary_azimuth = azimuth_areas.max_by { |k, v| v }[0]
    end
    return [primary_azimuth,
            sanitize_azimuth(primary_azimuth + 90),
            sanitize_azimuth(primary_azimuth + 180),
            sanitize_azimuth(primary_azimuth + 270)].sort
  end

  def self.sanitize_azimuth(azimuth)
    # Ensure 0 <= orientation < 360
    while azimuth < 0
      azimuth += 360
    end
    while azimuth >= 360
      azimuth -= 360
    end
    return azimuth
  end

  def self.create_or_get_space(model, spaces, spacetype)
    if spaces[spacetype].nil?
      create_space_and_zone(model, spaces, spacetype)
    end
    return spaces[spacetype]
  end

  def self.add_roofs(runner, model, spaces)
    @hpxml.roofs.each do |roof|
      next if roof.net_area < 0.1 # skip modeling net surface area for surfaces comprised entirely of subsurface area

      if roof.azimuth.nil?
        if roof.pitch > 0
          azimuths = @default_azimuths # Model as four directions for average exterior incident solar
        else
          azimuths = [90] # Arbitrary azimuth for flat roof
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

        surface = OpenStudio::Model::Surface.new(add_roof_polygon(length, width, z_origin, azimuth, tilt), model)
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
        set_surface_interior(model, spaces, surface, roof.interior_adjacent_to)
      end

      next if surfaces.empty?

      # Apply construction
      solar_abs = roof.solar_absorptance
      emitt = roof.emittance
      has_radiant_barrier = roof.radiant_barrier
      inside_film = Material.AirFilmRoof(Geometry.get_roof_pitch([surfaces[0]]))
      outside_film = Material.AirFilmOutside
      mat_roofing = Material.RoofMaterial(roof.roof_type, emitt, solar_abs)
      if @apply_ashrae140_assumptions
        inside_film = Material.AirFilmRoofASHRAE140
        outside_film = Material.AirFilmOutsideASHRAE140
      end

      install_grade = 1
      assembly_r = roof.insulation_assembly_r_value

      if roof.is_thermal_boundary
        constr_sets = [
          WoodStudConstructionSet.new(Material.Stud2x(8.0), 0.07, 10.0, 0.75, 0.5, mat_roofing), # 2x8, 24" o.c. + R10
          WoodStudConstructionSet.new(Material.Stud2x(8.0), 0.07, 5.0, 0.75, 0.5, mat_roofing),  # 2x8, 24" o.c. + R5
          WoodStudConstructionSet.new(Material.Stud2x(8.0), 0.07, 0.0, 0.75, 0.5, mat_roofing),  # 2x8, 24" o.c.
          WoodStudConstructionSet.new(Material.Stud2x6, 0.07, 0.0, 0.75, 0.5, mat_roofing),      # 2x6, 24" o.c.
          WoodStudConstructionSet.new(Material.Stud2x4, 0.07, 0.0, 0.5, 0.5, mat_roofing),       # 2x4, 16" o.c.
          WoodStudConstructionSet.new(Material.Stud2x4, 0.01, 0.0, 0.0, 0.0, mat_roofing),       # Fallback
        ]
        match, constr_set, cavity_r = pick_wood_stud_construction_set(assembly_r, constr_sets, inside_film, outside_film, roof.id)

        Constructions.apply_closed_cavity_roof(model, surfaces, "#{roof.id} construction",
                                               cavity_r, install_grade,
                                               constr_set.stud.thick_in,
                                               true, constr_set.framing_factor,
                                               constr_set.drywall_thick_in,
                                               constr_set.osb_thick_in, constr_set.rigid_r,
                                               constr_set.exterior_material, has_radiant_barrier,
                                               inside_film, outside_film)
      else
        constr_sets = [
          GenericConstructionSet.new(10.0, 0.5, 0.0, mat_roofing), # w/R-10 rigid
          GenericConstructionSet.new(0.0, 0.5, 0.0, mat_roofing),  # Standard
          GenericConstructionSet.new(0.0, 0.0, 0.0, mat_roofing),  # Fallback
        ]
        match, constr_set, layer_r = pick_generic_construction_set(assembly_r, constr_sets, inside_film, outside_film, roof.id)

        cavity_r = 0
        cavity_ins_thick_in = 0
        framing_factor = 0
        framing_thick_in = 0

        Constructions.apply_open_cavity_roof(model, surfaces, "#{roof.id} construction",
                                             cavity_r, install_grade, cavity_ins_thick_in,
                                             framing_factor, framing_thick_in,
                                             constr_set.osb_thick_in, layer_r + constr_set.rigid_r,
                                             mat_roofing, has_radiant_barrier,
                                             inside_film, outside_film)
      end
      check_surface_assembly_rvalue(runner, surfaces, inside_film, outside_film, assembly_r, match)
    end
  end

  def self.add_walls(runner, model, spaces)
    @hpxml.walls.each do |wall|
      next if wall.net_area < 0.1 # skip modeling net surface area for surfaces comprised entirely of subsurface area

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

        surface = OpenStudio::Model::Surface.new(add_wall_polygon(length, height, z_origin, azimuth), model)
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
        set_surface_interior(model, spaces, surface, wall.interior_adjacent_to)
        set_surface_exterior(model, spaces, surface, wall.exterior_adjacent_to)
        if wall.is_interior
          surface.setSunExposure('NoSun')
          surface.setWindExposure('NoWind')
        end
      end

      next if surfaces.empty?

      # Apply construction
      # The code below constructs a reasonable wall construction based on the
      # wall type while ensuring the correct assembly R-value.

      if wall.is_thermal_boundary
        drywall_thick_in = 0.5
      else
        drywall_thick_in = 0.0
      end
      inside_film = Material.AirFilmVertical
      if wall.is_exterior
        outside_film = Material.AirFilmOutside
        mat_ext_finish = Material.ExteriorFinishMaterial(wall.siding, wall.emittance, wall.solar_absorptance)
      else
        outside_film = Material.AirFilmVertical
        mat_ext_finish = nil
      end
      if @apply_ashrae140_assumptions
        inside_film = Material.AirFilmVerticalASHRAE140
        outside_film = Material.AirFilmOutsideASHRAE140
      end

      apply_wall_construction(runner, model, surfaces, wall, wall.id, wall.wall_type, wall.insulation_assembly_r_value,
                              drywall_thick_in, inside_film, outside_film, mat_ext_finish)
    end
  end

  def self.add_rim_joists(runner, model, spaces)
    @hpxml.rim_joists.each do |rim_joist|
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

        surface = OpenStudio::Model::Surface.new(add_wall_polygon(length, height, z_origin, azimuth), model)
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
        set_surface_interior(model, spaces, surface, rim_joist.interior_adjacent_to)
        set_surface_exterior(model, spaces, surface, rim_joist.exterior_adjacent_to)
        if rim_joist.is_interior
          surface.setSunExposure('NoSun')
          surface.setWindExposure('NoWind')
        end
      end

      # Apply construction

      if rim_joist.is_thermal_boundary
        drywall_thick_in = 0.5
      else
        drywall_thick_in = 0.0
      end
      inside_film = Material.AirFilmVertical
      if rim_joist.is_exterior
        outside_film = Material.AirFilmOutside
        mat_ext_finish = Material.ExteriorFinishMaterial(rim_joist.siding, rim_joist.emittance, rim_joist.solar_absorptance)
      else
        outside_film = Material.AirFilmVertical
        mat_ext_finish = nil
      end

      assembly_r = rim_joist.insulation_assembly_r_value

      constr_sets = [
        WoodStudConstructionSet.new(Material.Stud2x(2.0), 0.17, 10.0, 2.0, drywall_thick_in, mat_ext_finish),  # 2x4 + R10
        WoodStudConstructionSet.new(Material.Stud2x(2.0), 0.17, 5.0, 2.0, drywall_thick_in, mat_ext_finish),   # 2x4 + R5
        WoodStudConstructionSet.new(Material.Stud2x(2.0), 0.17, 0.0, 2.0, drywall_thick_in, mat_ext_finish),   # 2x4
        WoodStudConstructionSet.new(Material.Stud2x(2.0), 0.01, 0.0, 0.0, 0.0, mat_ext_finish),                # Fallback
      ]
      match, constr_set, cavity_r = pick_wood_stud_construction_set(assembly_r, constr_sets, inside_film, outside_film, rim_joist.id)
      install_grade = 1

      Constructions.apply_rim_joist(model, surfaces, rim_joist, "#{rim_joist.id} construction",
                                    cavity_r, install_grade, constr_set.framing_factor,
                                    constr_set.drywall_thick_in, constr_set.osb_thick_in,
                                    constr_set.rigid_r, constr_set.exterior_material,
                                    inside_film, outside_film)
      check_surface_assembly_rvalue(runner, surfaces, inside_film, outside_film, assembly_r, match)
    end
  end

  def self.add_frame_floors(runner, model, spaces)
    @hpxml.frame_floors.each do |frame_floor|
      area = frame_floor.area
      width = Math::sqrt(area)
      length = area / width
      if frame_floor.interior_adjacent_to.include?('attic') || frame_floor.exterior_adjacent_to.include?('attic')
        z_origin = @walls_top
      else
        z_origin = @foundation_top
      end

      if frame_floor.is_ceiling
        surface = OpenStudio::Model::Surface.new(add_ceiling_polygon(length, width, z_origin), model)
        surface.additionalProperties.setFeature('SurfaceType', 'Ceiling')
      else
        surface = OpenStudio::Model::Surface.new(add_floor_polygon(length, width, z_origin), model)
        surface.additionalProperties.setFeature('SurfaceType', 'Floor')
      end
      set_surface_interior(model, spaces, surface, frame_floor.interior_adjacent_to)
      set_surface_exterior(model, spaces, surface, frame_floor.exterior_adjacent_to)
      surface.setName(frame_floor.id)
      if frame_floor.is_interior
        surface.setSunExposure('NoSun')
        surface.setWindExposure('NoWind')
      elsif frame_floor.is_floor
        surface.setSunExposure('NoSun')
      end

      # Apply construction

      if frame_floor.is_ceiling
        inside_film = Material.AirFilmFloorAverage
      else
        inside_film = Material.AirFilmFloorReduced
      end
      if frame_floor.is_ceiling
        outside_film = Material.AirFilmFloorAverage
      elsif frame_floor.is_exterior
        outside_film = Material.AirFilmOutside
      else
        outside_film = Material.AirFilmFloorReduced
      end
      if frame_floor.is_floor && (frame_floor.interior_adjacent_to == HPXML::LocationLivingSpace)
        covering = Material.CoveringBare
      end
      if @apply_ashrae140_assumptions
        if frame_floor.is_exterior # Raised floor
          inside_film = Material.AirFilmFloorASHRAE140
          outside_film = Material.AirFilmFloorZeroWindASHRAE140
          surface.setWindExposure('NoWind')
          covering = Material.CoveringBare(1.0)
        elsif frame_floor.is_ceiling # Attic floor
          inside_film = Material.AirFilmFloorASHRAE140
          outside_film = Material.AirFilmFloorASHRAE140
        end
      end
      assembly_r = frame_floor.insulation_assembly_r_value

      constr_sets = [
        WoodStudConstructionSet.new(Material.Stud2x6, 0.10, 10.0, 0.75, 0.0, covering), # 2x6, 24" o.c. + R10
        WoodStudConstructionSet.new(Material.Stud2x6, 0.10, 0.0, 0.75, 0.0, covering),  # 2x6, 24" o.c.
        WoodStudConstructionSet.new(Material.Stud2x4, 0.13, 0.0, 0.5, 0.0, covering),   # 2x4, 16" o.c.
        WoodStudConstructionSet.new(Material.Stud2x4, 0.01, 0.0, 0.0, 0.0, nil), # Fallback
      ]
      match, constr_set, cavity_r = pick_wood_stud_construction_set(assembly_r, constr_sets, inside_film, outside_film, frame_floor.id)

      mat_floor_covering = nil
      install_grade = 1

      # Floor
      Constructions.apply_floor(model, [surface], "#{frame_floor.id} construction",
                                cavity_r, install_grade,
                                constr_set.framing_factor, constr_set.stud.thick_in,
                                constr_set.osb_thick_in, constr_set.rigid_r,
                                mat_floor_covering, constr_set.exterior_material,
                                inside_film, outside_film)
      check_surface_assembly_rvalue(runner, [surface], inside_film, outside_film, assembly_r, match)
    end
  end

  def self.add_foundation_walls_slabs(runner, model, spaces)
    foundation_types = @hpxml.slabs.map { |s| s.interior_adjacent_to }.uniq

    foundation_types.each do |foundation_type|
      # Get attached foundation walls/slabs
      fnd_walls = []
      slabs = []
      @hpxml.foundation_walls.each do |foundation_wall|
        next unless foundation_wall.interior_adjacent_to == foundation_type
        next if foundation_wall.net_area < 0.1 # skip modeling net surface area for surfaces comprised entirely of subsurface area

        fnd_walls << foundation_wall
      end
      @hpxml.slabs.each do |slab|
        next unless slab.interior_adjacent_to == foundation_type

        slabs << slab
      end

      # Calculate combinations of slabs/walls for each Kiva instance
      kiva_instances = get_kiva_instances(fnd_walls, slabs)

      # Obtain some wall/slab information
      fnd_wall_lengths = {}
      fnd_walls.each do |foundation_wall|
        next unless foundation_wall.is_exterior

        fnd_wall_lengths[foundation_wall] = foundation_wall.area / foundation_wall.height
      end
      slab_exp_perims = {}
      slab_areas = {}
      slabs.each do |slab|
        slab_exp_perims[slab] = slab.exposed_perimeter
        slab_areas[slab] = slab.area
      end
      total_slab_exp_perim = slab_exp_perims.values.inject(0, :+)
      total_slab_area = slab_areas.values.inject(0, :+)
      total_fnd_wall_length = fnd_wall_lengths.values.inject(0, :+)

      no_wall_slab_exp_perim = {}

      kiva_instances.each do |foundation_wall, slab|
        # Apportion referenced walls/slabs for this Kiva instance
        slab_frac = slab_exp_perims[slab] / total_slab_exp_perim
        if total_fnd_wall_length > 0
          fnd_wall_frac = fnd_wall_lengths[foundation_wall] / total_fnd_wall_length
        else
          fnd_wall_frac = 1.0 # Handle slab foundation type
        end

        kiva_foundation = nil
        if not foundation_wall.nil?
          # Add exterior foundation wall surface
          kiva_foundation = add_foundation_wall(runner, model, spaces, foundation_wall, slab_frac,
                                                total_fnd_wall_length, total_slab_exp_perim)
        end

        # Add single combined foundation slab surface (for similar surfaces)
        slab_exp_perim = slab_exp_perims[slab] * fnd_wall_frac
        slab_area = slab_areas[slab] * fnd_wall_frac
        no_wall_slab_exp_perim[slab] = 0.0 if no_wall_slab_exp_perim[slab].nil?
        if (not foundation_wall.nil?) && (slab_exp_perim > fnd_wall_lengths[foundation_wall] * slab_frac)
          # Keep track of no-wall slab exposed perimeter
          no_wall_slab_exp_perim[slab] += (slab_exp_perim - fnd_wall_lengths[foundation_wall] * slab_frac)

          # Reduce this slab's exposed perimeter so that EnergyPlus does not automatically
          # create a second no-wall Kiva instance for each of our Kiva instances.
          # Instead, we will later create our own Kiva instance to account for it.
          # This reduces the number of Kiva instances we end up with.
          exp_perim_frac = (fnd_wall_lengths[foundation_wall] * slab_frac) / slab_exp_perim
          slab_exp_perim *= exp_perim_frac
          slab_area *= exp_perim_frac
        end
        if not foundation_wall.nil?
          z_origin = -1 * foundation_wall.depth_below_grade # Position based on adjacent foundation walls
        else
          z_origin = -1 * slab.depth_below_grade
        end
        kiva_foundation = add_foundation_slab(runner, model, spaces, slab, slab_exp_perim,
                                              slab_area, z_origin, kiva_foundation)
      end

      # For each slab, create a no-wall Kiva slab instance if needed.
      slabs.each do |slab|
        next unless no_wall_slab_exp_perim[slab] > 0.1

        z_origin = 0
        slab_area = total_slab_area * no_wall_slab_exp_perim[slab] / total_slab_exp_perim
        kiva_foundation = add_foundation_slab(runner, model, spaces, slab, no_wall_slab_exp_perim[slab],
                                              slab_area, z_origin, nil)
      end

      # Interzonal foundation wall surfaces
      # The above-grade portion of these walls are modeled as EnergyPlus surfaces with standard adjacency.
      # The below-grade portion of these walls (in contact with ground) are not modeled, as Kiva does not
      # calculate heat flow between two zones through the ground.
      fnd_walls.each do |foundation_wall|
        next unless foundation_wall.is_interior

        ag_height = foundation_wall.height - foundation_wall.depth_below_grade
        ag_net_area = foundation_wall.net_area * ag_height / foundation_wall.height
        next if ag_net_area < 0.1

        length = ag_net_area / ag_height
        z_origin = -1 * ag_height
        if foundation_wall.azimuth.nil?
          azimuth = @default_azimuths[0] # Arbitrary direction, doesn't receive exterior incident solar
        else
          azimuth = foundation_wall.azimuth
        end

        surface = OpenStudio::Model::Surface.new(add_wall_polygon(length, ag_height, z_origin, azimuth), model)
        surface.additionalProperties.setFeature('Length', length)
        surface.additionalProperties.setFeature('Azimuth', azimuth)
        surface.additionalProperties.setFeature('Tilt', 90.0)
        surface.additionalProperties.setFeature('SurfaceType', 'FoundationWall')
        surface.setName(foundation_wall.id)
        surface.setSurfaceType('Wall')
        set_surface_interior(model, spaces, surface, foundation_wall.interior_adjacent_to)
        set_surface_exterior(model, spaces, surface, foundation_wall.exterior_adjacent_to)
        surface.setSunExposure('NoSun')
        surface.setWindExposure('NoWind')

        # Apply construction

        wall_type = HPXML::WallTypeConcrete
        if foundation_wall.is_thermal_boundary
          drywall_thick_in = 0.5
        else
          drywall_thick_in = 0.0
        end
        inside_film = Material.AirFilmVertical
        outside_film = Material.AirFilmVertical
        assembly_r = foundation_wall.insulation_assembly_r_value
        if assembly_r.nil?
          concrete_thick_in = foundation_wall.thickness
          int_r = foundation_wall.insulation_interior_r_value
          ext_r = foundation_wall.insulation_exterior_r_value
          assembly_r = int_r + ext_r + Material.Concrete(concrete_thick_in).rvalue + Material.GypsumWall(drywall_thick_in).rvalue + inside_film.rvalue + outside_film.rvalue
        end
        mat_ext_finish = nil

        apply_wall_construction(runner, model, [surface], foundation_wall, foundation_wall.id, wall_type, assembly_r,
                                drywall_thick_in, inside_film, outside_film, mat_ext_finish)
      end
    end
  end

  def self.add_foundation_wall(runner, model, spaces, foundation_wall, slab_frac,
                               total_fnd_wall_length, total_slab_exp_perim)

    net_area = foundation_wall.net_area * slab_frac
    gross_area = foundation_wall.area * slab_frac
    height = foundation_wall.height
    height_ag = height - foundation_wall.depth_below_grade
    z_origin = -1 * foundation_wall.depth_below_grade
    length = gross_area / height
    if foundation_wall.azimuth.nil?
      azimuth = @default_azimuths[0] # Arbitrary; solar incidence in Kiva is applied as an orientation average (to the above grade portion of the wall)
    else
      azimuth = foundation_wall.azimuth
    end

    if total_fnd_wall_length > total_slab_exp_perim
      # Calculate exposed section of wall based on slab's total exposed perimeter.
      length *= total_slab_exp_perim / total_fnd_wall_length
    end

    if gross_area > net_area
      # Create a "notch" in the wall to account for the subsurfaces. This ensures that
      # we preserve the appropriate wall height, length, and area for Kiva.
      subsurface_area = gross_area - net_area
    else
      subsurface_area = 0
    end

    surface = OpenStudio::Model::Surface.new(add_wall_polygon(length, height, z_origin, azimuth, [0] * 4, subsurface_area), model)
    surface.additionalProperties.setFeature('Length', length)
    surface.additionalProperties.setFeature('Azimuth', azimuth)
    surface.additionalProperties.setFeature('Tilt', 90.0)
    surface.additionalProperties.setFeature('SurfaceType', 'FoundationWall')
    surface.setName(foundation_wall.id)
    surface.setSurfaceType('Wall')
    set_surface_interior(model, spaces, surface, foundation_wall.interior_adjacent_to)
    set_surface_exterior(model, spaces, surface, foundation_wall.exterior_adjacent_to)

    if foundation_wall.is_thermal_boundary
      drywall_thick_in = 0.5
    else
      drywall_thick_in = 0.0
    end
    concrete_thick_in = foundation_wall.thickness
    assembly_r = foundation_wall.insulation_assembly_r_value
    if not assembly_r.nil?
      ext_rigid_height = height
      ext_rigid_offset = 0.0
      inside_film = Material.AirFilmVertical
      ext_rigid_r = assembly_r - Material.Concrete(concrete_thick_in).rvalue - Material.GypsumWall(drywall_thick_in).rvalue - inside_film.rvalue
      int_rigid_r = 0.0
      if ext_rigid_r < 0 # Try without drywall
        drywall_thick_in = 0.0
        ext_rigid_r = assembly_r - Material.Concrete(concrete_thick_in).rvalue - Material.GypsumWall(drywall_thick_in).rvalue - inside_film.rvalue
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

    Constructions.apply_foundation_wall(model, [surface], "#{foundation_wall.id} construction",
                                        ext_rigid_offset, int_rigid_offset, ext_rigid_height, int_rigid_height,
                                        ext_rigid_r, int_rigid_r, drywall_thick_in, concrete_thick_in, height_ag)

    if not assembly_r.nil?
      check_surface_assembly_rvalue(runner, [surface], inside_film, nil, assembly_r, match)
    end

    return surface.adjacentFoundation.get
  end

  def self.add_foundation_slab(runner, model, spaces, slab, slab_exp_perim,
                               slab_area, z_origin, kiva_foundation)

    slab_tot_perim = slab_exp_perim
    if slab_tot_perim**2 - 16.0 * slab_area <= 0
      # Cannot construct rectangle with this perimeter/area. Some of the
      # perimeter is presumably not exposed, so bump up perimeter value.
      slab_tot_perim = Math.sqrt(16.0 * slab_area)
    end
    sqrt_term = [slab_tot_perim**2 - 16.0 * slab_area, 0.0].max
    slab_length = slab_tot_perim / 4.0 + Math.sqrt(sqrt_term) / 4.0
    slab_width = slab_tot_perim / 4.0 - Math.sqrt(sqrt_term) / 4.0

    surface = OpenStudio::Model::Surface.new(add_floor_polygon(slab_length, slab_width, z_origin), model)
    surface.setName(slab.id)
    surface.setSurfaceType('Floor')
    surface.setOutsideBoundaryCondition('Foundation')
    surface.additionalProperties.setFeature('SurfaceType', 'Slab')
    set_surface_interior(model, spaces, surface, slab.interior_adjacent_to)
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
    slab_gap_r = slab_under_r

    mat_carpet = nil
    if (slab.carpet_fraction > 0) && (slab.carpet_r_value > 0)
      mat_carpet = Material.CoveringBare(slab.carpet_fraction,
                                         slab.carpet_r_value)
    end

    Constructions.apply_foundation_slab(model, surface, "#{slab.id} construction",
                                        slab_under_r, slab_under_width, slab_gap_r, slab_perim_r,
                                        slab_perim_depth, slab_whole_r, slab.thickness,
                                        slab_exp_perim, mat_carpet, kiva_foundation)

    return surface.adjacentFoundation.get
  end

  def self.add_conditioned_floor_area(runner, model, spaces)
    # Check if we need to add floors between conditioned spaces (e.g., between first
    # and second story or conditioned basement ceiling).
    # This ensures that the E+ reported Conditioned Floor Area is correct.

    sum_cfa = 0.0
    @hpxml.frame_floors.each do |frame_floor|
      next unless frame_floor.is_floor
      next unless frame_floor.interior_adjacent_to == HPXML::LocationLivingSpace

      sum_cfa += frame_floor.area
    end
    @hpxml.slabs.each do |slab|
      next unless [HPXML::LocationLivingSpace, HPXML::LocationBasementConditioned].include? slab.interior_adjacent_to

      sum_cfa += slab.area
    end

    addtl_cfa = @cfa - sum_cfa
    return unless addtl_cfa > 0.1

    floor_width = Math::sqrt(addtl_cfa)
    floor_length = addtl_cfa / floor_width
    z_origin = @foundation_top + 8.0 * (@ncfl_ag - 1)

    # Add floor surface
    floor_surface = OpenStudio::Model::Surface.new(add_floor_polygon(-floor_width, -floor_length, z_origin), model)

    floor_surface.setSunExposure('NoSun')
    floor_surface.setWindExposure('NoWind')
    floor_surface.setName('inferred conditioned floor')
    floor_surface.setSurfaceType('Floor')
    floor_surface.setSpace(create_or_get_space(model, spaces, HPXML::LocationLivingSpace))
    floor_surface.setOutsideBoundaryCondition('Adiabatic')
    floor_surface.additionalProperties.setFeature('SurfaceType', 'InferredFloor')

    # Add ceiling surface
    ceiling_surface = OpenStudio::Model::Surface.new(add_ceiling_polygon(-floor_width, -floor_length, z_origin), model)

    ceiling_surface.setSunExposure('NoSun')
    ceiling_surface.setWindExposure('NoWind')
    ceiling_surface.setName('inferred conditioned ceiling')
    ceiling_surface.setSurfaceType('RoofCeiling')
    ceiling_surface.setSpace(create_or_get_space(model, spaces, HPXML::LocationLivingSpace))
    ceiling_surface.setOutsideBoundaryCondition('Adiabatic')
    ceiling_surface.additionalProperties.setFeature('SurfaceType', 'InferredCeiling')

    if not @cond_bsmnt_surfaces.empty?
      # assuming added ceiling is in conditioned basement
      @cond_bsmnt_surfaces << ceiling_surface
    end

    # Apply Construction
    apply_adiabatic_construction(runner, model, [floor_surface, ceiling_surface], 'floor')
  end

  def self.add_thermal_mass(runner, model, spaces)
    cfa_basement = @hpxml.slabs.select { |s| s.interior_adjacent_to == HPXML::LocationBasementConditioned }.map { |s| s.area }.inject(0, :+)
    if @apply_ashrae140_assumptions
      # 1024 ft2 of interior partition wall mass, no furniture mass
      drywall_thick_in = 0.5
      partition_frac_of_cfa = 1024.0 / @cfa # Ratio of partition wall area to conditioned floor area
      basement_frac_of_cfa = cfa_basement / @cfa
      Constructions.apply_partition_walls(model, 'PartitionWallConstruction', drywall_thick_in, partition_frac_of_cfa,
                                          basement_frac_of_cfa, @cond_bsmnt_surfaces, spaces[HPXML::LocationLivingSpace])
    else
      drywall_thick_in = 0.5
      partition_frac_of_cfa = 1.0 # Ratio of partition wall area to conditioned floor area
      basement_frac_of_cfa = cfa_basement / @cfa
      Constructions.apply_partition_walls(model, 'PartitionWallConstruction', drywall_thick_in, partition_frac_of_cfa,
                                          basement_frac_of_cfa, @cond_bsmnt_surfaces, spaces[HPXML::LocationLivingSpace])

      mass_lb_per_sqft = 8.0
      density_lb_per_cuft = 40.0
      mat = BaseMaterial.Wood
      Constructions.apply_furniture(model, mass_lb_per_sqft, density_lb_per_cuft, mat,
                                    basement_frac_of_cfa, @cond_bsmnt_surfaces, spaces[HPXML::LocationLivingSpace])
    end
  end

  def self.add_neighbors(runner, model, length)
    z_origin = 0 # shading surface always starts at grade

    shading_surfaces = []
    @hpxml.neighbor_buildings.each do |neighbor_building|
      height = neighbor_building.height.nil? ? @walls_top : neighbor_building.height

      shading_surface = OpenStudio::Model::ShadingSurface.new(add_wall_polygon(length, height, z_origin, neighbor_building.azimuth), model)
      shading_surface.additionalProperties.setFeature('Azimuth', neighbor_building.azimuth)
      shading_surface.additionalProperties.setFeature('Distance', neighbor_building.distance)
      shading_surface.setName("Neighbor azimuth #{neighbor_building.azimuth} distance #{neighbor_building.distance}")

      shading_surfaces << shading_surface
    end

    unless shading_surfaces.empty?
      shading_surface_group = OpenStudio::Model::ShadingSurfaceGroup.new(model)
      shading_surface_group.setName(Constants.ObjectNameNeighbors)
      shading_surfaces.each do |shading_surface|
        shading_surface.setShadingSurfaceGroup(shading_surface_group)
      end
    end
  end

  def self.add_interior_shading_schedule(runner, model, weather)
    heating_season, cooling_season = HVAC.get_default_heating_and_cooling_seasons(weather)
    @clg_season_sch = MonthWeekdayWeekendSchedule.new(model, 'cooling season schedule', Array.new(24, 1), Array.new(24, 1), cooling_season, 1.0, 1.0, true, true, Constants.ScheduleTypeLimitsFraction)

    @clg_ssn_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Schedule Value')
    @clg_ssn_sensor.setName('cool_season')
    @clg_ssn_sensor.setKeyName(@clg_season_sch.schedule.name.to_s)
  end

  def self.add_windows(runner, model, spaces, weather)
    # We already stored @fraction_of_windows_operable, so lets remove the
    # fraction_operable properties from windows and re-collapse the enclosure
    # so as to prevent potentially modeling multiple identical windows in E+,
    # which can increase simulation runtime.
    @hpxml.windows.each do |window|
      window.fraction_operable = nil
    end
    @hpxml.collapse_enclosure_surfaces()

    surfaces = []
    @hpxml.windows.each do |window|
      window_height = 4.0 # ft, default

      overhang_depth = nil
      if not window.overhangs_depth.nil?
        overhang_depth = window.overhangs_depth
        overhang_distance_to_top = window.overhangs_distance_to_top_of_window
        overhang_distance_to_bottom = window.overhangs_distance_to_bottom_of_window
        window_height = overhang_distance_to_bottom - overhang_distance_to_top
      end

      window_width = window.area / window_height
      z_origin = @foundation_top

      if window.is_exterior

        # Create parent surface slightly bigger than window
        surface = OpenStudio::Model::Surface.new(add_wall_polygon(window_width, window_height, z_origin,
                                                                  window.azimuth, [0, 0.001, 0.001, 0.001]), model)

        surface.additionalProperties.setFeature('Length', window_width)
        surface.additionalProperties.setFeature('Azimuth', window.azimuth)
        surface.additionalProperties.setFeature('Tilt', 90.0)
        surface.additionalProperties.setFeature('SurfaceType', 'Window')
        surface.setName("surface #{window.id}")
        surface.setSurfaceType('Wall')
        set_surface_interior(model, spaces, surface, window.wall.interior_adjacent_to)

        sub_surface = OpenStudio::Model::SubSurface.new(add_wall_polygon(window_width, window_height, z_origin,
                                                                         window.azimuth, [-0.001, 0, 0.001, 0]), model)
        sub_surface.setName(window.id)
        sub_surface.setSurface(surface)
        sub_surface.setSubSurfaceType('FixedWindow')

        set_subsurface_exterior(surface, window.wall.exterior_adjacent_to, spaces, model)
        surfaces << surface

        if not overhang_depth.nil?
          overhang = sub_surface.addOverhang(UnitConversions.convert(overhang_depth, 'ft', 'm'), UnitConversions.convert(overhang_distance_to_top, 'ft', 'm'))
          overhang.get.setName("#{sub_surface.name} - #{Constants.ObjectNameOverhangs}")
        end

        # Apply construction
        cool_shade_mult = window.interior_shading_factor_summer
        heat_shade_mult = window.interior_shading_factor_winter
        Constructions.apply_window(model, [sub_surface],
                                   'WindowConstruction',
                                   weather, @clg_season_sch, window.ufactor, window.shgc,
                                   heat_shade_mult, cool_shade_mult)
      else
        # Window is on an interior surface, which E+ does not allow. Model
        # as a door instead so that we can get the appropriate conduction
        # heat transfer; there is no solar gains anyway.

        # Create parent surface slightly bigger than window
        surface = OpenStudio::Model::Surface.new(add_wall_polygon(window_width, window_height, z_origin,
                                                                  window.azimuth, [0, 0.001, 0.001, 0.001]), model)

        surface.additionalProperties.setFeature('Length', window_width)
        surface.additionalProperties.setFeature('Azimuth', window.azimuth)
        surface.additionalProperties.setFeature('Tilt', 90.0)
        surface.additionalProperties.setFeature('SurfaceType', 'Door')
        surface.setName("surface #{window.id}")
        surface.setSurfaceType('Wall')
        set_surface_interior(model, spaces, surface, window.wall.interior_adjacent_to)

        sub_surface = OpenStudio::Model::SubSurface.new(add_wall_polygon(window_width, window_height, z_origin,
                                                                         window.azimuth, [0, 0, 0, 0]), model)
        sub_surface.setName(window.id)
        sub_surface.setSurface(surface)
        sub_surface.setSubSurfaceType('Door')

        set_subsurface_exterior(surface, window.wall.exterior_adjacent_to, spaces, model)
        surfaces << surface

        # Apply construction
        Constructions.apply_door(model, [sub_surface], 'Window', window.ufactor)
      end
    end

    apply_adiabatic_construction(runner, model, surfaces, 'wall')
  end

  def self.add_skylights(runner, model, spaces, weather)
    surfaces = []
    @hpxml.skylights.each do |skylight|
      tilt = skylight.roof.pitch / 12.0
      width = Math::sqrt(skylight.area)
      length = skylight.area / width
      z_origin = @walls_top + 0.5 * Math.sin(Math.atan(tilt)) * width

      # Create parent surface slightly bigger than skylight
      surface = OpenStudio::Model::Surface.new(add_roof_polygon(length + 0.001, width + 0.001, z_origin,
                                                                skylight.azimuth, tilt), model)

      surface.additionalProperties.setFeature('Length', length)
      surface.additionalProperties.setFeature('Width', width)
      surface.additionalProperties.setFeature('Azimuth', skylight.azimuth)
      surface.additionalProperties.setFeature('Tilt', tilt)
      surface.additionalProperties.setFeature('SurfaceType', 'Skylight')
      surface.setName("surface #{skylight.id}")
      surface.setSurfaceType('RoofCeiling')
      surface.setSpace(create_or_get_space(model, spaces, HPXML::LocationLivingSpace)) # Ensures it is included in Manual J sizing
      surface.setOutsideBoundaryCondition('Outdoors') # cannot be adiabatic because subsurfaces won't be created
      surfaces << surface

      sub_surface = OpenStudio::Model::SubSurface.new(add_roof_polygon(length, width, z_origin,
                                                                       skylight.azimuth, tilt), model)
      sub_surface.setName(skylight.id)
      sub_surface.setSurface(surface)
      sub_surface.setSubSurfaceType('Skylight')

      # Apply construction
      ufactor = skylight.ufactor
      shgc = skylight.shgc
      cool_shade_mult = skylight.interior_shading_factor_summer
      heat_shade_mult = skylight.interior_shading_factor_winter
      Constructions.apply_skylight(model, [sub_surface],
                                   'SkylightConstruction',
                                   weather, @clg_season_sch, ufactor, shgc,
                                   heat_shade_mult, cool_shade_mult)
    end

    apply_adiabatic_construction(runner, model, surfaces, 'roof')
  end

  def self.add_doors(runner, model, spaces)
    surfaces = []
    @hpxml.doors.each do |door|
      door_height = 6.67 # ft
      door_width = door.area / door_height
      z_origin = @foundation_top

      # Create parent surface slightly bigger than door
      surface = OpenStudio::Model::Surface.new(add_wall_polygon(door_width, door_height, z_origin,
                                                                door.azimuth, [0, 0.001, 0.001, 0.001]), model)

      surface.additionalProperties.setFeature('Length', door_width)
      surface.additionalProperties.setFeature('Azimuth', door.azimuth)
      surface.additionalProperties.setFeature('Tilt', 90.0)
      surface.additionalProperties.setFeature('SurfaceType', 'Door')
      surface.setName("surface #{door.id}")
      surface.setSurfaceType('Wall')
      set_surface_interior(model, spaces, surface, door.wall.interior_adjacent_to)

      sub_surface = OpenStudio::Model::SubSurface.new(add_wall_polygon(door_width, door_height, z_origin,
                                                                       door.azimuth, [0, 0, 0, 0]), model)
      sub_surface.setName(door.id)
      sub_surface.setSurface(surface)
      sub_surface.setSubSurfaceType('Door')

      set_subsurface_exterior(surface, door.wall.exterior_adjacent_to, spaces, model)
      surfaces << surface

      # Apply construction
      ufactor = 1.0 / door.r_value
      Constructions.apply_door(model, [sub_surface], 'Door', ufactor)
    end

    apply_adiabatic_construction(runner, model, surfaces, 'wall')
  end

  def self.apply_adiabatic_construction(runner, model, surfaces, type)
    # Arbitrary construction for heat capacitance.
    # Only applies to surfaces where outside boundary conditioned is
    # adiabatic or surface net area is near zero.
    return if surfaces.empty?

    if type == 'wall'
      Constructions.apply_wood_stud_wall(model, surfaces, nil, 'AdiabaticWallConstruction',
                                         0, 1, 3.5, true, 0.1, 0.5, 0, 99,
                                         Material.ExteriorFinishMaterial(HPXML::SidingTypeWood, 0.90, 0.75),
                                         0,
                                         Material.AirFilmVertical,
                                         Material.AirFilmVertical)
    elsif type == 'floor'
      Constructions.apply_floor(model, surfaces, 'AdiabaticFloorConstruction',
                                0, 1, 0.07, 5.5, 0.75, 99,
                                Material.FloorWood, Material.CoveringBare,
                                Material.AirFilmFloorReduced,
                                Material.AirFilmFloorReduced)
    elsif type == 'roof'
      Constructions.apply_open_cavity_roof(model, surfaces, 'AdiabaticRoofConstruction',
                                           0, 1, 7.25, 0.07, 7.25, 0.75, 99,
                                           Material.RoofMaterial(HPXML::RoofTypeAsphaltShingles, 0.90, 0.75),
                                           false,
                                           Material.AirFilmOutside,
                                           Material.AirFilmRoof(Geometry.get_roof_pitch(surfaces)))
    end
  end

  def self.add_hot_water_and_appliances(runner, model, weather, spaces)
    # Assign spaces
    @hpxml.clothes_washers.each do |clothes_washer|
      clothes_washer.additional_properties.space = get_space_from_location(clothes_washer.location, 'ClothesWasher', model, spaces)
    end
    @hpxml.clothes_dryers.each do |clothes_dryer|
      clothes_dryer.additional_properties.space = get_space_from_location(clothes_dryer.location, 'ClothesDryer', model, spaces)
    end
    @hpxml.dishwashers.each do |dishwasher|
      dishwasher.additional_properties.space = get_space_from_location(dishwasher.location, 'Dishwasher', model, spaces)
    end
    @hpxml.refrigerators.each do |refrigerator|
      refrigerator.additional_properties.space = get_space_from_location(refrigerator.location, 'Refrigerator', model, spaces)
    end
    @hpxml.freezers.each do |freezer|
      freezer.additional_properties.space = get_space_from_location(freezer.location, 'Freezer', model, spaces)
    end
    @hpxml.cooking_ranges.each do |cooking_range|
      cooking_range.additional_properties.space = get_space_from_location(cooking_range.location, 'CookingRange', model, spaces)
    end

    # Distribution
    if @hpxml.water_heating_systems.size > 0
      hot_water_distribution = @hpxml.hot_water_distributions[0]
    end

    # Solar thermal system
    solar_thermal_system = nil
    if @hpxml.solar_thermal_systems.size > 0
      solar_thermal_system = @hpxml.solar_thermal_systems[0]
    end

    # Water Heater
    @hpxml.water_heating_systems.each do |water_heating_system|
      loc_space, loc_schedule = get_space_or_schedule_from_location(water_heating_system.location, 'WaterHeatingSystem', model, spaces)

      ec_adj = HotWaterAndAppliances.get_dist_energy_consumption_adjustment(@has_uncond_bsmnt, @cfa, @ncfl, hot_water_distribution)

      if water_heating_system.water_heater_type == HPXML::WaterHeaterTypeStorage

        Waterheater.apply_tank(model, loc_space, loc_schedule, water_heating_system, ec_adj,
                               @dhw_map, @hvac_map, solar_thermal_system)

      elsif water_heating_system.water_heater_type == HPXML::WaterHeaterTypeTankless

        Waterheater.apply_tankless(model, loc_space, loc_schedule, water_heating_system, ec_adj,
                                   @nbeds, @dhw_map, @hvac_map, solar_thermal_system)

      elsif water_heating_system.water_heater_type == HPXML::WaterHeaterTypeHeatPump

        living_zone = spaces[HPXML::LocationLivingSpace].thermalZone.get

        Waterheater.apply_heatpump(model, runner, loc_space, loc_schedule, weather, water_heating_system, ec_adj,
                                   @dhw_map, @hvac_map, solar_thermal_system, living_zone)

      elsif [HPXML::WaterHeaterTypeCombiStorage, HPXML::WaterHeaterTypeCombiTankless].include? water_heating_system.water_heater_type

        Waterheater.apply_combi(model, runner, loc_space, loc_schedule, water_heating_system, ec_adj,
                                @dhw_map, @hvac_map, solar_thermal_system)

      else

        fail "Unhandled water heater (#{water_heating_system.water_heater_type})."

      end
    end

    fixtures_usage_multiplier = @hpxml.water_heating.water_fixtures_usage_multiplier
    HotWaterAndAppliances.apply(model, runner, weather, spaces[HPXML::LocationLivingSpace],
                                @cfa, @nbeds, @ncfl, @has_uncond_bsmnt, @hpxml.clothes_washers,
                                @hpxml.clothes_dryers, @hpxml.dishwashers, @hpxml.refrigerators,
                                @hpxml.freezers, @hpxml.cooking_ranges, @hpxml.ovens, fixtures_usage_multiplier,
                                @hpxml.water_fixtures, @hpxml.water_heating_systems, hot_water_distribution,
                                solar_thermal_system, @eri_version, @dhw_map)

    if (not solar_thermal_system.nil?) && (not solar_thermal_system.collector_area.nil?) # Detailed solar water heater
      loc_space, loc_schedule = get_space_or_schedule_from_location(solar_thermal_system.water_heating_system.location, 'WaterHeatingSystem', model, spaces)
      Waterheater.apply_solar_thermal(model, loc_space, loc_schedule, solar_thermal_system, @dhw_map)
    end

    # Add combi-system EMS program with water use equipment information
    Waterheater.apply_combi_system_EMS(model, @dhw_map, @hpxml.water_heating_systems)
  end

  def self.is_central_air_conditioner_and_furnace(heating_system, cooling_system)
    if not (@hpxml.heating_systems.include?(heating_system) && (heating_system.heating_system_type == HPXML::HVACTypeFurnace))
      return false
    end
    if not (@hpxml.cooling_systems.include?(cooling_system) && (cooling_system.cooling_system_type == HPXML::HVACTypeCentralAirConditioner))
      return false
    end

    return true
  end

  def self.add_cooling_system(runner, model, spaces)
    living_zone = spaces[HPXML::LocationLivingSpace].thermalZone.get

    @hpxml.cooling_systems.each do |cooling_system|
      check_distribution_system(cooling_system.distribution_system, cooling_system.cooling_system_type)

      if cooling_system.cooling_system_type == HPXML::HVACTypeCentralAirConditioner

        heating_system = cooling_system.attached_heating_system
        if not is_central_air_conditioner_and_furnace(heating_system, cooling_system)
          heating_system = nil
        end

        HVAC.apply_central_air_conditioner_furnace(model, runner, cooling_system, heating_system,
                                                   @remaining_cool_load_frac, @remaining_heat_load_frac,
                                                   living_zone, @hvac_map)

        if not heating_system.nil?
          @remaining_heat_load_frac -= heating_system.fraction_heat_load_served
        end

      elsif cooling_system.cooling_system_type == HPXML::HVACTypeRoomAirConditioner

        HVAC.apply_room_air_conditioner(model, runner, cooling_system,
                                        @remaining_cool_load_frac, living_zone,
                                        @hvac_map)

      elsif cooling_system.cooling_system_type == HPXML::HVACTypeEvaporativeCooler

        HVAC.apply_evaporative_cooler(model, runner, cooling_system,
                                      @remaining_cool_load_frac, living_zone,
                                      @hvac_map)
      end

      @remaining_cool_load_frac -= cooling_system.fraction_cool_load_served
    end
  end

  def self.add_heating_system(runner, model, spaces)
    living_zone = spaces[HPXML::LocationLivingSpace].thermalZone.get

    @hpxml.heating_systems.each do |heating_system|
      check_distribution_system(heating_system.distribution_system, heating_system.heating_system_type)

      if heating_system.heating_system_type == HPXML::HVACTypeFurnace

        cooling_system = heating_system.attached_cooling_system
        if is_central_air_conditioner_and_furnace(heating_system, cooling_system)
          next # Already processed combined AC+furnace
        end

        HVAC.apply_central_air_conditioner_furnace(model, runner, nil, heating_system,
                                                   nil, @remaining_heat_load_frac,
                                                   living_zone, @hvac_map)

      elsif heating_system.heating_system_type == HPXML::HVACTypeBoiler

        HVAC.apply_boiler(model, runner, heating_system,
                          @remaining_heat_load_frac, living_zone, @hvac_map)

      elsif heating_system.heating_system_type == HPXML::HVACTypeElectricResistance

        HVAC.apply_electric_baseboard(model, runner, heating_system,
                                      @remaining_heat_load_frac, living_zone, @hvac_map)

      elsif (heating_system.heating_system_type == HPXML::HVACTypeStove ||
             heating_system.heating_system_type == HPXML::HVACTypePortableHeater ||
             heating_system.heating_system_type == HPXML::HVACTypeWallFurnace ||
             heating_system.heating_system_type == HPXML::HVACTypeFloorFurnace ||
             heating_system.heating_system_type == HPXML::HVACTypeFireplace)

        HVAC.apply_unit_heater(model, runner, heating_system,
                               @remaining_heat_load_frac, living_zone, @hvac_map)
      end

      @remaining_heat_load_frac -= heating_system.fraction_heat_load_served
    end
  end

  def self.add_heat_pump(runner, model, weather, spaces)
    living_zone = spaces[HPXML::LocationLivingSpace].thermalZone.get

    @hpxml.heat_pumps.each do |heat_pump|
      # TODO: Move these checks into hvac.rb
      if not heat_pump.heating_capacity_17F.nil?
        if heat_pump.heating_capacity.nil?
          fail "HeatPump '#{heat_pump.id}' must have both HeatingCapacity and HeatingCapacity17F provided or not provided."
        elsif heat_pump.heating_capacity == 0.0
          heat_pump.heating_capacity_17F = nil
        end
      end
      if not heat_pump.backup_heating_fuel.nil?
        if heat_pump.backup_heating_capacity.nil? ^ heat_pump.heating_capacity.nil?
          fail "HeatPump '#{heat_pump.id}' must have both HeatingCapacity and BackupHeatingCapacity provided or not provided."
        end
      end

      check_distribution_system(heat_pump.distribution_system, heat_pump.heat_pump_type)

      if heat_pump.heat_pump_type == HPXML::HVACTypeHeatPumpAirToAir

        HVAC.apply_central_air_to_air_heat_pump(model, runner, heat_pump,
                                                @remaining_heat_load_frac,
                                                @remaining_cool_load_frac,
                                                living_zone, @hvac_map)

      elsif heat_pump.heat_pump_type == HPXML::HVACTypeHeatPumpMiniSplit

        HVAC.apply_mini_split_heat_pump(model, runner, heat_pump,
                                        @remaining_heat_load_frac,
                                        @remaining_cool_load_frac,
                                        living_zone, @hvac_map)

      elsif heat_pump.heat_pump_type == HPXML::HVACTypeHeatPumpGroundToAir

        HVAC.apply_ground_to_air_heat_pump(model, runner, weather, heat_pump,
                                           @remaining_heat_load_frac,
                                           @remaining_cool_load_frac,
                                           living_zone, @hvac_map)

      end

      @remaining_heat_load_frac -= heat_pump.fraction_heat_load_served
      @remaining_cool_load_frac -= heat_pump.fraction_cool_load_served
    end
  end

  def self.add_ideal_system_for_partial_hvac(runner, model, spaces)
    # Adds an ideal air system to meet expected unmet load (i.e., because the sum of fractions load served is less than 1)
    living_zone = spaces[HPXML::LocationLivingSpace].thermalZone.get
    obj_name = Constants.ObjectNameIdealAirSystem

    if @hpxml.building_construction.use_only_ideal_air_system
      HVAC.apply_ideal_air_loads(model, runner, obj_name, 1, 1, living_zone)
      return
    end

    # Only fraction of heating load is met
    if (@hpxml.total_fraction_heat_load_served < 1.0) && (@hpxml.total_fraction_heat_load_served > 0.0)
      sequential_heat_load_frac = @remaining_heat_load_frac - @hpxml.total_fraction_heat_load_served
      @remaining_heat_load_frac -= sequential_heat_load_frac
    else
      sequential_heat_load_frac = 0.0
    end
    # Only fraction of cooling load is met
    if (@hpxml.total_fraction_cool_load_served < 1.0) && (@hpxml.total_fraction_cool_load_served > 0.0)
      sequential_cool_load_frac = @remaining_cool_load_frac - @hpxml.total_fraction_cool_load_served
      @remaining_cool_load_frac -= sequential_cool_load_frac
    else
      sequential_cool_load_frac = 0.0
    end
    if (sequential_heat_load_frac > 0.0) || (sequential_cool_load_frac > 0.0)
      HVAC.apply_ideal_air_loads(model, runner, obj_name, sequential_cool_load_frac, sequential_heat_load_frac,
                                 living_zone)
    end
  end

  def self.add_residual_hvac(runner, model, spaces)
    living_zone = spaces[HPXML::LocationLivingSpace].thermalZone.get
    obj_name = Constants.ObjectNameIdealAirSystemResidual

    # Adds an ideal air system to meet unexpected load (i.e., because the HVAC systems are undersized to meet the load)
    #
    # Addressing unmet load ensures we can correctly calculate heating/cooling loads without having to run
    # an additional EnergyPlus simulation solely for that purpose, as well as allows us to report
    # the unmet load (i.e., the energy delivered by the ideal air system).
    if @remaining_cool_load_frac < 1.0
      sequential_cool_load_frac = 1
    else
      sequential_cool_load_frac = 0 # no cooling system, don't add ideal air for cooling either
    end

    if @remaining_heat_load_frac < 1.0
      sequential_heat_load_frac = 1
    else
      sequential_heat_load_frac = 0 # no heating system, don't add ideal air for heating either
    end
    if (sequential_heat_load_frac > 0) || (sequential_cool_load_frac > 0)
      HVAC.apply_ideal_air_loads(model, runner, obj_name, sequential_cool_load_frac, sequential_heat_load_frac,
                                 living_zone)
    end
  end

  def self.add_setpoints(runner, model, weather, spaces)
    return if @hpxml.hvac_controls.size == 0

    hvac_control = @hpxml.hvac_controls[0]
    living_zone = spaces[HPXML::LocationLivingSpace].thermalZone.get

    HVAC.apply_setpoints(model, runner, weather, hvac_control, living_zone)
  end

  def self.add_ceiling_fans(runner, model, weather, spaces)
    return if @hpxml.ceiling_fans.size == 0

    ceiling_fan = @hpxml.ceiling_fans[0]
    HVAC.apply_ceiling_fans(model, runner, weather, ceiling_fan, spaces[HPXML::LocationLivingSpace])
  end

  def self.add_dehumidifier(runner, model, spaces)
    return if @hpxml.dehumidifiers.size == 0

    dehumidifier = @hpxml.dehumidifiers[0]
    HVAC.apply_dehumidifier(model, runner, dehumidifier, spaces[HPXML::LocationLivingSpace], @hvac_map)
  end

  def self.check_distribution_system(hvac_distribution, system_type)
    return if hvac_distribution.nil?

    hvac_distribution_type_map = { HPXML::HVACTypeFurnace => [HPXML::HVACDistributionTypeAir, HPXML::HVACDistributionTypeDSE],
                                   HPXML::HVACTypeBoiler => [HPXML::HVACDistributionTypeHydronic, HPXML::HVACDistributionTypeDSE],
                                   HPXML::HVACTypeCentralAirConditioner => [HPXML::HVACDistributionTypeAir, HPXML::HVACDistributionTypeDSE],
                                   HPXML::HVACTypeEvaporativeCooler => [HPXML::HVACDistributionTypeAir, HPXML::HVACDistributionTypeDSE],
                                   HPXML::HVACTypeHeatPumpAirToAir => [HPXML::HVACDistributionTypeAir, HPXML::HVACDistributionTypeDSE],
                                   HPXML::HVACTypeHeatPumpMiniSplit => [HPXML::HVACDistributionTypeAir, HPXML::HVACDistributionTypeDSE],
                                   HPXML::HVACTypeHeatPumpGroundToAir => [HPXML::HVACDistributionTypeAir, HPXML::HVACDistributionTypeDSE] }

    if not hvac_distribution_type_map[system_type].include? hvac_distribution.distribution_system_type
      # EPvalidator.rb only checks that a HVAC distribution system of the correct type (for the given HVAC system) exists
      # in the HPXML file, not that it is attached to this HVAC system. So here we perform the more rigorous check.
      fail "Incorrect HVAC distribution system type for HVAC type: '#{system_type}'. Should be one of: #{hvac_distribution_type_map[system_type]}"
    end
  end

  def self.add_mels(runner, model, spaces)
    # Misc
    @hpxml.plug_loads.each do |plug_load|
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
        runner.registerWarning("Unexpected plug load '#{plug_load.id}'. The plug load will not be modeled.")
        next
      end

      MiscLoads.apply_plug(model, plug_load, obj_name, @cfa, spaces[HPXML::LocationLivingSpace])
    end
  end

  def self.add_mfls(runner, model, spaces)
    # Misc
    @hpxml.fuel_loads.each do |fuel_load|
      if fuel_load.fuel_load_type == HPXML::FuelLoadTypeGrill
        obj_name = Constants.ObjectNameMiscGrill
      elsif fuel_load.fuel_load_type == HPXML::FuelLoadTypeLighting
        obj_name = Constants.ObjectNameMiscLighting
      elsif fuel_load.fuel_load_type == HPXML::FuelLoadTypeFireplace
        obj_name = Constants.ObjectNameMiscFireplace
      end
      if obj_name.nil?
        runner.registerWarning("Unexpected fuel load '#{fuel_load.id}'. The fuel load will not be modeled.")
        next
      end

      MiscLoads.apply_fuel(model, fuel_load, obj_name, spaces[HPXML::LocationLivingSpace])
    end
  end

  def self.add_lighting(runner, model, weather, spaces)
    Lighting.apply(model, weather, spaces, @hpxml.lighting_groups,
                   @hpxml.lighting.usage_multiplier, @eri_version)
  end

  def self.add_pools_and_hot_tubs(runner, model, spaces)
    @hpxml.pools.each do |pool|
      MiscLoads.apply_pool_or_hot_tub_heater(model, pool, Constants.ObjectNameMiscPoolHeater, spaces[HPXML::LocationLivingSpace])
      MiscLoads.apply_pool_or_hot_tub_pump(model, pool, Constants.ObjectNameMiscPoolPump, spaces[HPXML::LocationLivingSpace])
    end

    @hpxml.hot_tubs.each do |hot_tub|
      MiscLoads.apply_pool_or_hot_tub_heater(model, hot_tub, Constants.ObjectNameMiscHotTubHeater, spaces[HPXML::LocationLivingSpace])
      MiscLoads.apply_pool_or_hot_tub_pump(model, hot_tub, Constants.ObjectNameMiscHotTubPump, spaces[HPXML::LocationLivingSpace])
    end
  end

  def self.add_airflow(runner, model, weather, spaces)
    # Vented Attic
    vented_attic = nil
    @hpxml.attics.each do |attic|
      next unless attic.attic_type == HPXML::AtticTypeVented

      vented_attic = attic
    end

    # Vented Crawlspace
    vented_crawl = nil
    @hpxml.foundations.each do |foundation|
      next unless foundation.foundation_type == HPXML::FoundationTypeCrawlspaceVented

      vented_crawl = foundation
    end

    # Ducts
    duct_systems = {}
    @hpxml.hvac_distributions.each do |hvac_distribution|
      next unless hvac_distribution.distribution_system_type == HPXML::HVACDistributionTypeAir

      air_ducts = create_ducts(runner, model, hvac_distribution, spaces)

      # Connect AirLoopHVACs to ducts
      hvac_distribution.hvac_systems.each do |hvac_system|
        @hvac_map[hvac_system.id].each do |loop|
          next unless loop.is_a? OpenStudio::Model::AirLoopHVAC

          if duct_systems[air_ducts].nil?
            duct_systems[air_ducts] = loop
          elsif duct_systems[air_ducts] != loop
            # Multiple air loops associated with this duct system, treat
            # as separate duct systems.
            air_ducts2 = create_ducts(runner, model, hvac_distribution, spaces)
            duct_systems[air_ducts2] = loop
          end
        end
      end
    end

    # Ventilation fans
    vent_mech = nil
    vent_kitchen = nil
    vent_bath = nil
    vent_whf = nil
    @hpxml.ventilation_fans.each do |vent_fan|
      if vent_fan.used_for_whole_building_ventilation
        vent_mech = vent_fan
      elsif vent_fan.used_for_seasonal_cooling_load_reduction
        vent_whf = vent_fan
      elsif vent_fan.used_for_local_ventilation
        if vent_fan.fan_location == HPXML::LocationKitchen
          vent_kitchen = vent_fan
        elsif vent_fan.fan_location == HPXML::LocationBath
          vent_bath = vent_fan
        end
      end
    end

    air_infils = @hpxml.air_infiltration_measurements
    window_area = @hpxml.windows.map { |w| w.area }.inject(0, :+)
    open_window_area = window_area * @frac_windows_operable * 0.5 * 0.2 # Assume A) 50% of the area of an operable window can be open, and B) 20% of openable window area is actually open
    site_type = @hpxml.site.site_type
    shelter_coef = @hpxml.site.shelter_coefficient
    has_flue_chimney = false # FUTURE: Expose as HPXML input
    @infil_volume = air_infils.select { |i| !i.infiltration_volume.nil? }[0].infiltration_volume
    infil_height = @hpxml.inferred_infiltration_height(@infil_volume)
    Airflow.apply(model, runner, weather, spaces, air_infils, vent_mech, vent_whf,
                  duct_systems, @infil_volume, infil_height, open_window_area,
                  @clg_ssn_sensor, @min_neighbor_distance, vent_kitchen, vent_bath,
                  vented_attic, vented_crawl, site_type, shelter_coef,
                  has_flue_chimney, @hvac_map, @eri_version, @apply_ashrae140_assumptions)
  end

  def self.create_ducts(runner, model, hvac_distribution, spaces)
    air_ducts = []

    # Duct leakage (supply/return => [value, units])
    leakage_to_outside = { HPXML::DuctTypeSupply => [0.0, nil],
                           HPXML::DuctTypeReturn => [0.0, nil] }
    hvac_distribution.duct_leakage_measurements.each do |duct_leakage_measurement|
      next unless [HPXML::UnitsCFM25, HPXML::UnitsPercent].include?(duct_leakage_measurement.duct_leakage_units) && (duct_leakage_measurement.duct_leakage_total_or_to_outside == 'to outside')
      next if duct_leakage_measurement.duct_type.nil?

      leakage_to_outside[duct_leakage_measurement.duct_type] = [duct_leakage_measurement.duct_leakage_value, duct_leakage_measurement.duct_leakage_units]
    end

    # Duct location, R-value, Area
    total_unconditioned_duct_area = { HPXML::DuctTypeSupply => 0.0,
                                      HPXML::DuctTypeReturn => 0.0 }
    hvac_distribution.ducts.each do |ducts|
      next if [HPXML::LocationLivingSpace, HPXML::LocationBasementConditioned].include? ducts.duct_location
      next if ducts.duct_type.nil?

      # Calculate total duct area in unconditioned spaces
      total_unconditioned_duct_area[ducts.duct_type] += ducts.duct_surface_area
    end

    # Create duct objects
    hvac_distribution.ducts.each do |ducts|
      next if [HPXML::LocationLivingSpace, HPXML::LocationBasementConditioned].include? ducts.duct_location
      next if ducts.duct_type.nil?
      next if total_unconditioned_duct_area[ducts.duct_type] <= 0

      duct_loc_space, duct_loc_schedule = get_space_or_schedule_from_location(ducts.duct_location, 'Duct', model, spaces)

      # Apportion leakage to individual ducts by surface area
      duct_leakage_value = leakage_to_outside[ducts.duct_type][0] * ducts.duct_surface_area / total_unconditioned_duct_area[ducts.duct_type]
      duct_leakage_units = leakage_to_outside[ducts.duct_type][1]

      duct_leakage_cfm = nil
      duct_leakage_frac = nil
      if duct_leakage_units == HPXML::UnitsCFM25
        duct_leakage_cfm = duct_leakage_value
      elsif duct_leakage_units == HPXML::UnitsPercent
        duct_leakage_frac = duct_leakage_value
      else
        fail "#{ducts.duct_type.capitalize} ducts exist but leakage was not specified for distribution system '#{hvac_distribution.id}'."
      end

      air_ducts << Duct.new(ducts.duct_type, duct_loc_space, duct_loc_schedule, duct_leakage_frac, duct_leakage_cfm, ducts.duct_surface_area, ducts.duct_insulation_r_value)
    end

    # If all ducts are in conditioned space, model leakage as going to outside
    registered_warning = false
    [HPXML::DuctTypeSupply, HPXML::DuctTypeReturn].each do |duct_side|
      next unless (leakage_to_outside[duct_side][0] > 0) && (total_unconditioned_duct_area[duct_side] == 0)

      if not registered_warning
        runner.registerWarning("HVACDistribution '#{hvac_distribution.id}' has ducts entirely within conditioned space but there is non-zero leakage to the outside. Leakage to the outside is typically zero in these situations; consider revising leakage values. Leakage will be modeled as heat lost to the ambient environment.")
        registered_warning = true
      end
      duct_area = 0.0
      duct_rvalue = 0.0
      duct_loc_space = nil # outside
      duct_loc_schedule = nil # outside
      duct_leakage_value = leakage_to_outside[duct_side][0]
      duct_leakage_units = leakage_to_outside[duct_side][1]

      duct_leakage_cfm = nil
      duct_leakage_frac = nil
      if duct_leakage_units == HPXML::UnitsCFM25
        duct_leakage_cfm = duct_leakage_value
      elsif duct_leakage_units == HPXML::UnitsPercent
        duct_leakage_frac = duct_leakage_value
      else
        fail "#{duct_side.capitalize} ducts exist but leakage was not specified for distribution system '#{hvac_distribution.id}'."
      end

      air_ducts << Duct.new(duct_side, duct_loc_space, duct_loc_schedule, duct_leakage_frac, duct_leakage_cfm, duct_area, duct_rvalue)
    end

    return air_ducts
  end

  def self.add_hvac_sizing(runner, model, weather, spaces)
    HVACSizing.apply(model, runner, weather, spaces, @hpxml, @infil_volume, @nbeds, @min_neighbor_distance, @debug)
  end

  def self.add_fuel_heating_eae(runner, model)
    # Needs to come after HVAC sizing (needs heating capacity and airflow rate)
    # FUTURE: Could remove this method and simplify everything if we could autosize via the HPXML file

    @hpxml.heating_systems.each do |heating_system|
      next unless heating_system.fraction_heat_load_served > 0

      htg_type = heating_system.heating_system_type
      next unless [HPXML::HVACTypeFurnace, HPXML::HVACTypeWallFurnace, HPXML::HVACTypeFloorFurnace, HPXML::HVACTypeStove, HPXML::HVACTypeBoiler].include? htg_type

      fuel = heating_system.heating_system_fuel
      next if fuel == HPXML::FuelTypeElectricity

      fuel_eae = heating_system.electric_auxiliary_energy
      load_frac = heating_system.fraction_heat_load_served
      sys_id = heating_system.id

      HVAC.apply_eae_to_heating_fan(runner, @hvac_map[sys_id], fuel_eae, fuel, load_frac, htg_type)
    end
  end

  def self.add_photovoltaics(runner, model)
    @hpxml.pv_systems.each do |pv_system|
      PV.apply(model, pv_system)
    end
  end

  def self.add_additional_properties(runner, model, hpxml_path)
    # Store some data for use in reporting measure
    additionalProperties = model.getBuilding.additionalProperties
    additionalProperties.setFeature('hpxml_path', hpxml_path)
    additionalProperties.setFeature('hvac_map', map_to_string(@hvac_map))
    additionalProperties.setFeature('dhw_map', map_to_string(@dhw_map))
  end

  def self.map_to_string(map)
    map_str = {}
    map.each do |sys_id, objects|
      object_name_list = []
      objects.uniq.each do |object|
        object_name_list << object.name.to_s
      end
      map_str[sys_id] = object_name_list if object_name_list.size > 0
    end
    return map_str.to_s
  end

  def self.add_component_loads_output(runner, model, spaces)
    living_zone = spaces[HPXML::LocationLivingSpace].thermalZone.get

    # Prevent certain objects (e.g., OtherEquipment) from being counted towards both, e.g., ducts and internal gains
    objects_already_processed = []

    # EMS Sensors: Global

    liv_load_sensors = {}

    liv_load_sensors[:htg] = OpenStudio::Model::EnergyManagementSystemSensor.new(model, "Heating:EnergyTransfer:Zone:#{living_zone.name.to_s.upcase}")
    liv_load_sensors[:htg].setName('htg_load_liv')

    liv_load_sensors[:clg] = OpenStudio::Model::EnergyManagementSystemSensor.new(model, "Cooling:EnergyTransfer:Zone:#{living_zone.name.to_s.upcase}")
    liv_load_sensors[:clg].setName('clg_load_liv')

    tot_load_sensors = {}

    tot_load_sensors[:htg] = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Heating:EnergyTransfer')
    tot_load_sensors[:htg].setName('htg_load_tot')

    tot_load_sensors[:clg] = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Cooling:EnergyTransfer')
    tot_load_sensors[:clg].setName('clg_load_tot')

    load_adj_sensors = {} # Sensors used to adjust E+ EnergyTransfer meter, eg. dehumidifier as load in our program, but included in Heating:EnergyTransfer as HVAC equipment

    # EMS Sensors: Surfaces, SubSurfaces, InternalMass

    surfaces_sensors = { walls: [],
                         rim_joists: [],
                         foundation_walls: [],
                         floors: [],
                         slabs: [],
                         ceilings: [],
                         roofs: [],
                         windows: [],
                         doors: [],
                         skylights: [],
                         internal_mass: [] }

    # Output diagnostics needed for some output variables used below
    output_diagnostics = model.getOutputDiagnostics
    output_diagnostics.addKey('DisplayAdvancedReportVariables')

    model.getSurfaces.sort.each_with_index do |s, idx|
      next unless s.space.get.thermalZone.get.name.to_s == living_zone.name.to_s

      surface_type = s.additionalProperties.getFeatureAsString('SurfaceType')
      if not surface_type.is_initialized
        fail "Could not identify surface type for surface: '#{s.name}'."
      end

      surface_type = surface_type.get

      s.subSurfaces.each do |ss|
        key = { 'Window' => :windows,
                'Door' => :doors,
                'Skylight' => :skylights }[surface_type]
        fail "Unexpected subsurface for component loads: '#{ss.name}'." if key.nil?

        if (surface_type == 'Window') || (surface_type == 'Skylight')
          vars = { 'Surface Window Transmitted Solar Radiation Energy' => 'ss_trans_in',
                   'Surface Window Shortwave from Zone Back Out Window Heat Transfer Rate' => 'ss_back_out',
                   'Surface Window Total Glazing Layers Absorbed Shortwave Radiation Rate' => 'ss_sw_abs',
                   'Surface Window Total Glazing Layers Absorbed Solar Radiation Energy' => 'ss_sol_abs',
                   'Surface Inside Face Initial Transmitted Diffuse Transmitted Out Window Solar Radiation Rate' => 'ss_trans_out',
                   'Surface Inside Face Convection Heat Gain Energy' => 'ss_conv',
                   'Surface Inside Face Internal Gains Radiation Heat Gain Energy' => 'ss_ig',
                   'Surface Inside Face Net Surface Thermal Radiation Heat Gain Energy' => 'ss_surf' }
        else
          vars = { 'Surface Inside Face Solar Radiation Heat Gain Energy' => 'ss_sol',
                   'Surface Inside Face Lights Radiation Heat Gain Energy' => 'ss_lgt',
                   'Surface Inside Face Convection Heat Gain Energy' => 'ss_conv',
                   'Surface Inside Face Internal Gains Radiation Heat Gain Energy' => 'ss_ig',
                   'Surface Inside Face Net Surface Thermal Radiation Heat Gain Energy' => 'ss_surf' }
        end

        surfaces_sensors[key] << []
        vars.each do |var, name|
          sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, var)
          sensor.setName(name)
          sensor.setKeyName(ss.name.to_s)
          surfaces_sensors[key][-1] << sensor
        end
      end

      next if s.netArea < 0.1 # Skip parent surfaces (of subsurfaces) that have near zero net area

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

    model.getInternalMasss.sort.each do |m|
      next unless m.space.get.thermalZone.get.name.to_s == living_zone.name.to_s

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

    # EMS Sensors: Infiltration, Mechanical Ventilation, Natural Ventilation, Whole House Fan

    air_gain_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Zone Infiltration Sensible Heat Gain Energy')
    air_gain_sensor.setName('airflow_gain')
    air_gain_sensor.setKeyName(living_zone.name.to_s)

    air_loss_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Zone Infiltration Sensible Heat Loss Energy')
    air_loss_sensor.setName('airflow_loss')
    air_loss_sensor.setKeyName(living_zone.name.to_s)

    mechvent_sensors = []
    model.getElectricEquipments.sort.each do |o|
      next unless o.name.to_s.start_with? Constants.ObjectNameMechanicalVentilation

      { 'Electric Equipment Convective Heating Energy' => 'mv_conv',
        'Electric Equipment Radiant Heating Energy' => 'mv_rad' }.each do |var, name|
        mechvent_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, var)
        mechvent_sensor.setName(name)
        mechvent_sensor.setKeyName(o.name.to_s)
        mechvent_sensors << mechvent_sensor
        objects_already_processed << o
      end
    end
    model.getOtherEquipments.sort.each do |o|
      next unless o.name.to_s.start_with? Constants.ObjectNameERVHRV

      { 'Other Equipment Convective Heating Energy' => 'mv_conv',
        'Other Equipment Radiant Heating Energy' => 'mv_rad' }.each do |var, name|
        mechvent_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, var)
        mechvent_sensor.setName(name)
        mechvent_sensor.setKeyName(o.name.to_s)
        mechvent_sensors << mechvent_sensor
        objects_already_processed << o
      end
    end

    infil_flow_actuators = []
    natvent_flow_actuators = []
    mechvent_flow_actuators = []
    whf_flow_actuators = []

    model.getEnergyManagementSystemActuators.each do |actuator|
      next unless (actuator.actuatedComponentType == 'Zone Infiltration') && (actuator.actuatedComponentControlType == 'Air Exchange Flow Rate')

      if actuator.name.to_s.start_with? Constants.ObjectNameInfiltration.gsub(' ', '_')
        infil_flow_actuators << actuator
      elsif actuator.name.to_s.start_with? Constants.ObjectNameNaturalVentilation.gsub(' ', '_')
        natvent_flow_actuators << actuator
      elsif actuator.name.to_s.start_with? Constants.ObjectNameMechanicalVentilation.gsub(' ', '_')
        mechvent_flow_actuators << actuator
      elsif actuator.name.to_s.start_with? Constants.ObjectNameWholeHouseFan.gsub(' ', '_')
        whf_flow_actuators << actuator
      end
    end
    if (infil_flow_actuators.size != 1) || (natvent_flow_actuators.size != 1) || (mechvent_flow_actuators.size != 1) || (whf_flow_actuators.size != 1)
      fail 'Could not find actuator for component loads.'
    end

    infil_flow_actuator = infil_flow_actuators[0]
    natvent_flow_actuator = natvent_flow_actuators[0]
    mechvent_flow_actuator = mechvent_flow_actuators[0]
    whf_flow_actuator = whf_flow_actuators[0]

    # EMS Sensors: Ducts

    plenum_zones = []
    model.getThermalZones.each do |zone|
      next unless zone.isPlenum

      plenum_zones << zone
    end

    ducts_sensors = []
    ducts_mix_gain_sensor = nil
    ducts_mix_loss_sensor = nil

    if not plenum_zones.empty?

      has_duct_zone_mixing = false
      living_zone.airLoopHVACs.sort.each do |airloop|
        living_zone.zoneMixing.each do |zone_mix|
          next unless zone_mix.name.to_s.start_with? airloop.name.to_s.gsub(' ', '_')

          has_duct_zone_mixing = true
        end
      end

      if has_duct_zone_mixing
        ducts_mix_gain_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Zone Mixing Sensible Heat Gain Energy')
        ducts_mix_gain_sensor.setName('duct_mix_gain')
        ducts_mix_gain_sensor.setKeyName(living_zone.name.to_s)

        ducts_mix_loss_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Zone Mixing Sensible Heat Loss Energy')
        ducts_mix_loss_sensor.setName('duct_mix_loss')
        ducts_mix_loss_sensor.setKeyName(living_zone.name.to_s)
      end

      # Return duct losses
      plenum_zones.each do |plenum_zone|
        model.getOtherEquipments.sort.each do |o|
          next unless o.space.get.thermalZone.get.name.to_s == plenum_zone.name.to_s
          next if objects_already_processed.include? o

          ducts_sensors << []
          { 'Other Equipment Convective Heating Energy' => 'ducts_conv',
            'Other Equipment Radiant Heating Energy' => 'ducts_rad' }.each do |var, name|
            ducts_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, var)
            ducts_sensor.setName(name)
            ducts_sensor.setKeyName(o.name.to_s)
            ducts_sensors[-1] << ducts_sensor
            objects_already_processed << o
          end
        end
      end

      # Supply duct losses
      living_zone.airLoopHVACs.sort.each do |airloop|
        model.getOtherEquipments.sort.each do |o|
          next unless o.space.get.thermalZone.get.name.to_s == living_zone.name.to_s
          next unless o.name.to_s.start_with? airloop.name.to_s.gsub(' ', '_')
          next if objects_already_processed.include? o

          ducts_sensors << []
          { 'Other Equipment Convective Heating Energy' => 'ducts_conv',
            'Other Equipment Radiant Heating Energy' => 'ducts_rad' }.each do |var, name|
            ducts_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, var)
            ducts_sensor.setName(name)
            ducts_sensor.setKeyName(o.name.to_s)
            ducts_sensors[-1] << ducts_sensor
            objects_already_processed << o
          end
        end
      end
    end

    # EMS Sensors: Internal Gains

    intgains_sensors = []

    model.getElectricEquipments.sort.each do |o|
      next unless o.space.get.thermalZone.get.name.to_s == living_zone.name.to_s
      next if objects_already_processed.include? o

      intgains_sensors << []
      { 'Electric Equipment Convective Heating Energy' => 'ig_ee_conv',
        'Electric Equipment Radiant Heating Energy' => 'ig_ee_rad' }.each do |var, name|
        intgains_elec_equip_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, var)
        intgains_elec_equip_sensor.setName(name)
        intgains_elec_equip_sensor.setKeyName(o.name.to_s)
        intgains_sensors[-1] << intgains_elec_equip_sensor
      end
    end

    model.getGasEquipments.sort.each do |o|
      next unless o.space.get.thermalZone.get.name.to_s == living_zone.name.to_s
      next if objects_already_processed.include? o

      intgains_sensors << []
      { 'Gas Equipment Convective Heating Energy' => 'ig_ge_conv',
        'Gas Equipment Radiant Heating Energy' => 'ig_ge_rad' }.each do |var, name|
        intgains_gas_equip_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, var)
        intgains_gas_equip_sensor.setName(name)
        intgains_gas_equip_sensor.setKeyName(o.name.to_s)
        intgains_sensors[-1] << intgains_gas_equip_sensor
      end
    end

    model.getOtherEquipments.sort.each do |o|
      next unless o.space.get.thermalZone.get.name.to_s == living_zone.name.to_s
      next if objects_already_processed.include? o

      intgains_sensors << []
      { 'Other Equipment Convective Heating Energy' => 'ig_oe_conv',
        'Other Equipment Radiant Heating Energy' => 'ig_oe_rad' }.each do |var, name|
        intgains_other_equip_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, var)
        intgains_other_equip_sensor.setName(name)
        intgains_other_equip_sensor.setKeyName(o.name.to_s)
        intgains_sensors[-1] << intgains_other_equip_sensor
      end
    end

    model.getLightss.sort.each do |e|
      next unless e.space.get.thermalZone.get.name.to_s == living_zone.name.to_s

      intgains_sensors << []
      { 'Lights Convective Heating Energy' => 'ig_lgt_conv',
        'Lights Radiant Heating Energy' => 'ig_lgt_rad',
        'Lights Visible Radiation Heating Energy' => 'ig_lgt_vis' }.each do |var, name|
        intgains_lights_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, var)
        intgains_lights_sensor.setName(name)
        intgains_lights_sensor.setKeyName(e.name.to_s)
        intgains_sensors[-1] << intgains_lights_sensor
      end
    end

    model.getPeoples.sort.each do |e|
      next unless e.space.get.thermalZone.get.name.to_s == living_zone.name.to_s

      intgains_sensors << []
      { 'People Convective Heating Energy' => 'ig_ppl_conv',
        'People Radiant Heating Energy' => 'ig_ppl_rad' }.each do |var, name|
        intgains_people = OpenStudio::Model::EnergyManagementSystemSensor.new(model, var)
        intgains_people.setName(name)
        intgains_people.setKeyName(e.name.to_s)
        intgains_sensors[-1] << intgains_people
      end
    end

    model.getZoneHVACDehumidifierDXs.each do |e|
      next unless e.thermalZone.get.name.to_s == living_zone.name.to_s

      intgains_sensors << []
      { 'Zone Dehumidifier Sensible Heating Energy' => 'ig_dehumidifier' }.each do |var, name|
        intgain_dehumidifier = OpenStudio::Model::EnergyManagementSystemSensor.new(model, var)
        intgain_dehumidifier.setName(name)
        intgain_dehumidifier.setKeyName(e.name.to_s)
        load_adj_sensors[:dehumidifier] = intgain_dehumidifier
        intgains_sensors[-1] << intgain_dehumidifier
      end
    end

    intgains_dhw_sensors = {}

    (model.getWaterHeaterMixeds + model.getWaterHeaterStratifieds).sort.each do |wh|
      next unless wh.ambientTemperatureThermalZone.is_initialized
      next unless wh.ambientTemperatureThermalZone.get.name.to_s == living_zone.name.to_s

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

    nonsurf_names = ['intgains', 'infil', 'mechvent', 'natvent', 'whf', 'ducts']

    # EMS program
    program = OpenStudio::Model::EnergyManagementSystemProgram.new(model)
    program.setName(Constants.ObjectNameComponentLoadsProgram)

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

    # EMS program: Internal gains
    program.addLine('Set hr_intgains = 0')
    intgains_sensors.each do |intgain_sensors|
      s = 'Set hr_intgains = hr_intgains'
      intgain_sensors.each do |sensor|
        s += " - #{sensor.name}"
      end
      program.addLine(s) if intgain_sensors.size > 0
    end
    intgains_dhw_sensors.each do |sensor, vals|
      off_loss, on_loss, rtf_sensor = vals
      program.addLine("Set hr_intgains = hr_intgains + #{sensor.name} * (#{off_loss}*(1-#{rtf_sensor.name}) + #{on_loss}*#{rtf_sensor.name})") # Water heater tank losses to zone
    end

    # EMS program: Infiltration, Natural Ventilation, Mechanical Ventilation, Ducts
    program.addLine("Set hr_airflow_rate = #{infil_flow_actuator.name} + #{mechvent_flow_actuator.name} + #{natvent_flow_actuator.name} + #{whf_flow_actuator.name}")
    program.addLine('If hr_airflow_rate > 0')
    program.addLine("  Set hr_infil = (#{air_loss_sensor.name} - #{air_gain_sensor.name}) * #{infil_flow_actuator.name} / hr_airflow_rate") # Airflow heat attributed to infiltration
    program.addLine("  Set hr_natvent = (#{air_loss_sensor.name} - #{air_gain_sensor.name}) * #{natvent_flow_actuator.name} / hr_airflow_rate") # Airflow heat attributed to natural ventilation
    program.addLine("  Set hr_whf = (#{air_loss_sensor.name} - #{air_gain_sensor.name}) * #{whf_flow_actuator.name} / hr_airflow_rate") # Airflow heat attributed to whole house fan
    program.addLine("  Set hr_mechvent = ((#{air_loss_sensor.name} - #{air_gain_sensor.name}) * #{mechvent_flow_actuator.name} / hr_airflow_rate)") # Airflow heat attributed to mechanical ventilation
    program.addLine('Else')
    program.addLine('  Set hr_infil = 0')
    program.addLine('  Set hr_natvent = 0')
    program.addLine('  Set hr_whf = 0')
    program.addLine('  Set hr_mechvent = 0')
    program.addLine('EndIf')
    s = 'Set hr_mechvent = hr_mechvent'
    mechvent_sensors.each do |sensor|
      s += " - #{sensor.name}" # Fan heat & ERV/HRV load
    end
    program.addLine(s) if mechvent_sensors.size > 0
    program.addLine('Set hr_ducts = 0')
    ducts_sensors.each do |duct_sensors|
      s = 'Set hr_ducts = hr_ducts'
      duct_sensors.each do |sensor|
        s += " - #{sensor.name}"
      end
      program.addLine(s) if duct_sensors.size > 0
    end
    if (not ducts_mix_loss_sensor.nil?) && (not ducts_mix_gain_sensor.nil?)
      program.addLine("Set hr_ducts = hr_ducts + (#{ducts_mix_loss_sensor.name} - #{ducts_mix_gain_sensor.name})")
    end

    # EMS program: Heating vs Cooling logic
    program.addLine('Set htg_mode = 0')
    program.addLine('Set clg_mode = 0')
    program.addLine("If (#{liv_load_sensors[:htg].name} > 0)") # Assign hour to heating if heating load
    program.addLine('  Set htg_mode = 1')
    program.addLine("ElseIf (#{liv_load_sensors[:clg].name} > 0)") # Assign hour to cooling if cooling load
    program.addLine('  Set clg_mode = 1')
    program.addLine("ElseIf (#{@clg_ssn_sensor.name} > 0)") # No load, assign hour to cooling if in cooling season definition (Note: natural ventilation & whole house fan only operate during the cooling season)
    program.addLine('  Set clg_mode = 1')
    program.addLine('Else') # No load, assign hour to heating if not in cooling season definition
    program.addLine('  Set htg_mode = 1')
    program.addLine('EndIf')

    [:htg, :clg].each do |mode|
      if mode == :htg
        sign = ''
      else
        sign = '-'
      end
      surfaces_sensors.keys.each do |k|
        program.addLine("Set loads_#{mode}_#{k} = #{sign}hr_#{k} * #{mode}_mode")
      end
      nonsurf_names.each do |nonsurf_name|
        program.addLine("Set loads_#{mode}_#{nonsurf_name} = #{sign}hr_#{nonsurf_name} * #{mode}_mode")
      end
    end

    # EMS program: Total loads
    program.addLine('Set loads_htg_tot = 0')
    program.addLine('Set loads_clg_tot = 0')
    program.addLine("If #{liv_load_sensors[:htg].name} > 0")
    s = "  Set loads_htg_tot = #{tot_load_sensors[:htg].name} - #{tot_load_sensors[:clg].name}"
    load_adj_sensors.each do |key, adj_sensor|
      if ['dehumidifier'].include? key.to_s
        s += " - #{adj_sensor.name}"
      end
    end
    program.addLine(s)
    program.addLine("ElseIf #{liv_load_sensors[:clg].name} > 0")
    s = "  Set loads_clg_tot = #{tot_load_sensors[:clg].name} - #{tot_load_sensors[:htg].name}"
    load_adj_sensors.each do |key, adj_sensor|
      if ['dehumidifier'].include? key.to_s
        s += " + #{adj_sensor.name}"
      end
    end
    program.addLine(s)
    program.addLine('EndIf')

    # EMS calling manager
    program_calling_manager = OpenStudio::Model::EnergyManagementSystemProgramCallingManager.new(model)
    program_calling_manager.setName("#{program.name} calling manager")
    program_calling_manager.setCallingPoint('EndOfZoneTimestepAfterZoneReporting')
    program_calling_manager.addProgram(program)
  end

  # FIXME: Move all of these construction methods to constructions.rb
  def self.calc_non_cavity_r(film_r, constr_set)
    # Calculate R-value for all non-cavity layers
    non_cavity_r = film_r
    if not constr_set.exterior_material.nil?
      non_cavity_r += constr_set.exterior_material.rvalue
    end
    if not constr_set.rigid_r.nil?
      non_cavity_r += constr_set.rigid_r
    end
    if not constr_set.osb_thick_in.nil?
      non_cavity_r += Material.Plywood(constr_set.osb_thick_in).rvalue
    end
    if not constr_set.drywall_thick_in.nil?
      non_cavity_r += Material.GypsumWall(constr_set.drywall_thick_in).rvalue
    end
    return non_cavity_r
  end

  def self.apply_wall_construction(runner, model, surfaces, wall, wall_id, wall_type, assembly_r,
                                   drywall_thick_in, inside_film, outside_film, mat_ext_finish)

    film_r = inside_film.rvalue + outside_film.rvalue
    if mat_ext_finish.nil?
      fallback_mat_ext_finish = nil
    else
      fallback_mat_ext_finish = Material.ExteriorFinishMaterial(mat_ext_finish.name, mat_ext_finish.tAbs, mat_ext_finish.sAbs, 0.1)
    end

    if wall_type == HPXML::WallTypeWoodStud
      install_grade = 1
      cavity_filled = true

      constr_sets = [
        WoodStudConstructionSet.new(Material.Stud2x6, 0.20, 10.0, 0.5, drywall_thick_in, mat_ext_finish), # 2x6, 24" o.c. + R10
        WoodStudConstructionSet.new(Material.Stud2x6, 0.20, 5.0, 0.5, drywall_thick_in, mat_ext_finish),  # 2x6, 24" o.c. + R5
        WoodStudConstructionSet.new(Material.Stud2x6, 0.20, 0.0, 0.5, drywall_thick_in, mat_ext_finish),  # 2x6, 24" o.c.
        WoodStudConstructionSet.new(Material.Stud2x4, 0.23, 0.0, 0.5, drywall_thick_in, mat_ext_finish),  # 2x4, 16" o.c.
        WoodStudConstructionSet.new(Material.Stud2x4, 0.01, 0.0, 0.0, 0.0, fallback_mat_ext_finish),      # Fallback
      ]
      match, constr_set, cavity_r = pick_wood_stud_construction_set(assembly_r, constr_sets, inside_film, outside_film, wall_id)

      Constructions.apply_wood_stud_wall(model, surfaces, wall, "#{wall_id} construction",
                                         cavity_r, install_grade, constr_set.stud.thick_in,
                                         cavity_filled, constr_set.framing_factor,
                                         constr_set.drywall_thick_in, constr_set.osb_thick_in,
                                         constr_set.rigid_r, constr_set.exterior_material,
                                         0, inside_film, outside_film)
    elsif wall_type == HPXML::WallTypeSteelStud
      install_grade = 1
      cavity_filled = true
      corr_factor = 0.45

      constr_sets = [
        SteelStudConstructionSet.new(5.5, corr_factor, 0.20, 10.0, 0.5, drywall_thick_in, mat_ext_finish), # 2x6, 24" o.c. + R10
        SteelStudConstructionSet.new(5.5, corr_factor, 0.20, 5.0, 0.5, drywall_thick_in, mat_ext_finish),  # 2x6, 24" o.c. + R5
        SteelStudConstructionSet.new(5.5, corr_factor, 0.20, 0.0, 0.5, drywall_thick_in, mat_ext_finish),  # 2x6, 24" o.c.
        SteelStudConstructionSet.new(3.5, corr_factor, 0.23, 0.0, 0.5, drywall_thick_in, mat_ext_finish),  # 2x4, 16" o.c.
        SteelStudConstructionSet.new(3.5, 1.0, 0.01, 0.0, 0.0, 0.0, fallback_mat_ext_finish),              # Fallback
      ]
      match, constr_set, cavity_r = pick_steel_stud_construction_set(assembly_r, constr_sets, inside_film, outside_film, wall_id)

      Constructions.apply_steel_stud_wall(model, surfaces, wall, "#{wall_id} construction",
                                          cavity_r, install_grade, constr_set.cavity_thick_in,
                                          cavity_filled, constr_set.framing_factor,
                                          constr_set.corr_factor, constr_set.drywall_thick_in,
                                          constr_set.osb_thick_in, constr_set.rigid_r,
                                          constr_set.exterior_material, inside_film, outside_film)
    elsif wall_type == HPXML::WallTypeDoubleWoodStud
      install_grade = 1
      is_staggered = false

      constr_sets = [
        DoubleStudConstructionSet.new(Material.Stud2x4, 0.23, 24.0, 0.0, 0.5, drywall_thick_in, mat_ext_finish),  # 2x4, 24" o.c.
        DoubleStudConstructionSet.new(Material.Stud2x4, 0.01, 16.0, 0.0, 0.0, 0.0, fallback_mat_ext_finish),      # Fallback
      ]
      match, constr_set, cavity_r = pick_double_stud_construction_set(assembly_r, constr_sets, inside_film, outside_film, wall_id)

      Constructions.apply_double_stud_wall(model, surfaces, wall, "#{wall_id} construction",
                                           cavity_r, install_grade, constr_set.stud.thick_in,
                                           constr_set.stud.thick_in, constr_set.framing_factor,
                                           constr_set.framing_spacing, is_staggered,
                                           constr_set.drywall_thick_in, constr_set.osb_thick_in,
                                           constr_set.rigid_r, constr_set.exterior_material,
                                           inside_film, outside_film)
    elsif wall_type == HPXML::WallTypeCMU
      density = 119.0 # lb/ft^3
      furring_r = 0
      furring_cavity_depth_in = 0 # in
      furring_spacing = 0

      constr_sets = [
        CMUConstructionSet.new(8.0, 1.4, 0.08, 0.5, drywall_thick_in, mat_ext_finish),  # 8" perlite-filled CMU
        CMUConstructionSet.new(6.0, 5.29, 0.01, 0.0, 0.0, fallback_mat_ext_finish),     # Fallback (6" hollow CMU)
      ]
      match, constr_set, rigid_r = pick_cmu_construction_set(assembly_r, constr_sets, inside_film, outside_film, wall_id)

      Constructions.apply_cmu_wall(model, surfaces, wall, "#{wall_id} construction",
                                   constr_set.thick_in, constr_set.cond_in, density,
                                   constr_set.framing_factor, furring_r,
                                   furring_cavity_depth_in, furring_spacing,
                                   constr_set.drywall_thick_in, constr_set.osb_thick_in,
                                   rigid_r, constr_set.exterior_material, inside_film,
                                   outside_film)
    elsif wall_type == HPXML::WallTypeSIP
      sheathing_thick_in = 0.44

      constr_sets = [
        SIPConstructionSet.new(10.0, 0.16, 0.0, sheathing_thick_in, 0.5, drywall_thick_in, mat_ext_finish), # 10" SIP core
        SIPConstructionSet.new(5.0, 0.16, 0.0, sheathing_thick_in, 0.5, drywall_thick_in, mat_ext_finish),  # 5" SIP core
        SIPConstructionSet.new(1.0, 0.01, 0.0, sheathing_thick_in, 0.0, 0.0, fallback_mat_ext_finish),      # Fallback
      ]
      match, constr_set, cavity_r = pick_sip_construction_set(assembly_r, constr_sets, inside_film, outside_film, wall_id)

      Constructions.apply_sip_wall(model, surfaces, wall, "#{wall_id} construction",
                                   cavity_r, constr_set.thick_in, constr_set.framing_factor,
                                   constr_set.sheath_thick_in, constr_set.drywall_thick_in,
                                   constr_set.osb_thick_in, constr_set.rigid_r,
                                   constr_set.exterior_material, inside_film, outside_film)
    elsif wall_type == HPXML::WallTypeICF
      constr_sets = [
        ICFConstructionSet.new(2.0, 4.0, 0.08, 0.0, 0.5, drywall_thick_in, mat_ext_finish), # ICF w/4" concrete and 2" rigid ins layers
        ICFConstructionSet.new(1.0, 1.0, 0.01, 0.0, 0.0, 0.0, fallback_mat_ext_finish),     # Fallback
      ]
      match, constr_set, icf_r = pick_icf_construction_set(assembly_r, constr_sets, inside_film, outside_film, wall_id)

      Constructions.apply_icf_wall(model, surfaces, wall, "#{wall_id} construction",
                                   icf_r, constr_set.ins_thick_in,
                                   constr_set.concrete_thick_in, constr_set.framing_factor,
                                   constr_set.drywall_thick_in, constr_set.osb_thick_in,
                                   constr_set.rigid_r, constr_set.exterior_material,
                                   inside_film, outside_film)
    elsif [HPXML::WallTypeConcrete, HPXML::WallTypeBrick, HPXML::WallTypeStrawBale, HPXML::WallTypeStone, HPXML::WallTypeLog].include? wall_type
      constr_sets = [
        GenericConstructionSet.new(10.0, 0.5, drywall_thick_in, mat_ext_finish), # w/R-10 rigid
        GenericConstructionSet.new(0.0, 0.5, drywall_thick_in, mat_ext_finish),  # Standard
        GenericConstructionSet.new(0.0, 0.0, 0.0, fallback_mat_ext_finish),      # Fallback
      ]
      match, constr_set, layer_r = pick_generic_construction_set(assembly_r, constr_sets, inside_film, outside_film, wall_id)

      if wall_type == HPXML::WallTypeConcrete
        thick_in = 6.0
        base_mat = BaseMaterial.Concrete
      elsif wall_type == HPXML::WallTypeBrick
        thick_in = 8.0
        base_mat = BaseMaterial.Brick
      elsif wall_type == HPXML::WallTypeStrawBale
        thick_in = 23.0
        base_mat = BaseMaterial.StrawBale
      elsif wall_type == HPXML::WallTypeStone
        thick_in = 6.0
        base_mat = BaseMaterial.Stone
      elsif wall_type == HPXML::WallTypeLog
        thick_in = 6.0
        base_mat = BaseMaterial.Wood
      end
      thick_ins = [thick_in]
      if layer_r == 0
        conds = [99]
      else
        conds = [thick_in / layer_r]
      end
      denss = [base_mat.rho]
      specheats = [base_mat.cp]

      Constructions.apply_generic_layered_wall(model, surfaces, wall, "#{wall_id} construction",
                                               thick_ins, conds, denss, specheats,
                                               constr_set.drywall_thick_in, constr_set.osb_thick_in,
                                               constr_set.rigid_r, constr_set.exterior_material,
                                               inside_film, outside_film)
    else
      fail "Unexpected wall type '#{wall_type}'."
    end

    check_surface_assembly_rvalue(runner, surfaces, inside_film, outside_film, assembly_r, match)
  end

  def self.pick_wood_stud_construction_set(assembly_r, constr_sets, inside_film, outside_film, surface_name)
    # Picks a construction set from supplied constr_sets for which a positive R-value
    # can be calculated for the unknown insulation to achieve the assembly R-value.

    constr_sets.each do |constr_set|
      fail 'Unexpected object.' unless constr_set.is_a? WoodStudConstructionSet

      film_r = inside_film.rvalue + outside_film.rvalue
      non_cavity_r = calc_non_cavity_r(film_r, constr_set)

      # Calculate effective cavity R-value
      # Assumes installation quality 1
      cavity_frac = 1.0 - constr_set.framing_factor
      cavity_r = cavity_frac / (1.0 / assembly_r - constr_set.framing_factor / (constr_set.stud.rvalue + non_cavity_r)) - non_cavity_r
      if cavity_r > 0 # Choose this construction set
        return true, constr_set, cavity_r
      end
    end

    return false, constr_sets[-1], 0.0 # Pick fallback construction with minimum R-value
  end

  def self.pick_steel_stud_construction_set(assembly_r, constr_sets, inside_film, outside_film, surface_name)
    # Picks a construction set from supplied constr_sets for which a positive R-value
    # can be calculated for the unknown insulation to achieve the assembly R-value.

    constr_sets.each do |constr_set|
      fail 'Unexpected object.' unless constr_set.is_a? SteelStudConstructionSet

      film_r = inside_film.rvalue + outside_film.rvalue
      non_cavity_r = calc_non_cavity_r(film_r, constr_set)

      # Calculate effective cavity R-value
      # Assumes installation quality 1
      cavity_r = (assembly_r - non_cavity_r) / constr_set.corr_factor
      if cavity_r > 0 # Choose this construction set
        return true, constr_set, cavity_r
      end
    end

    return false, constr_sets[-1], 0.0 # Pick fallback construction with minimum R-value
  end

  def self.pick_double_stud_construction_set(assembly_r, constr_sets, inside_film, outside_film, surface_name)
    # Picks a construction set from supplied constr_sets for which a positive R-value
    # can be calculated for the unknown insulation to achieve the assembly R-value.

    constr_sets.each do |constr_set|
      fail 'Unexpected object.' unless constr_set.is_a? DoubleStudConstructionSet

      film_r = inside_film.rvalue + outside_film.rvalue
      non_cavity_r = calc_non_cavity_r(film_r, constr_set)

      # Calculate effective cavity R-value
      # Assumes installation quality 1, not staggered, gap depth == stud depth
      # Solved in Wolfram Alpha: https://www.wolframalpha.com/input/?i=1%2FA+%3D+B%2F(2*C%2Bx%2BD)+%2B+E%2F(3*C%2BD)+%2B+(1-B-E)%2F(3*x%2BD)
      stud_frac = 1.5 / constr_set.framing_spacing
      misc_framing_factor = constr_set.framing_factor - stud_frac
      cavity_frac = 1.0 - (2 * stud_frac + misc_framing_factor)
      a = assembly_r
      b = stud_frac
      c = constr_set.stud.rvalue
      d = non_cavity_r
      e = misc_framing_factor
      cavity_r = ((3 * c + d) * Math.sqrt(4 * a**2 * b**2 + 12 * a**2 * b * e + 4 * a**2 * b + 9 * a**2 * e**2 - 6 * a**2 * e + a**2 - 48 * a * b * c - 16 * a * b * d - 36 * a * c * e + 12 * a * c - 12 * a * d * e + 4 * a * d + 36 * c**2 + 24 * c * d + 4 * d**2) + 6 * a * b * c + 2 * a * b * d + 3 * a * c * e + 3 * a * c + 3 * a * d * e + a * d - 18 * c**2 - 18 * c * d - 4 * d**2) / (2 * (-3 * a * e + 9 * c + 3 * d))
      cavity_r = 3 * cavity_r
      if cavity_r > 0 # Choose this construction set
        return true, constr_set, cavity_r
      end
    end

    return false, constr_sets[-1], 0.0 # Pick fallback construction with minimum R-value
  end

  def self.pick_sip_construction_set(assembly_r, constr_sets, inside_film, outside_film, surface_name)
    # Picks a construction set from supplied constr_sets for which a positive R-value
    # can be calculated for the unknown insulation to achieve the assembly R-value.

    constr_sets.each do |constr_set|
      fail 'Unexpected object.' unless constr_set.is_a? SIPConstructionSet

      film_r = inside_film.rvalue + outside_film.rvalue
      non_cavity_r = calc_non_cavity_r(film_r, constr_set)
      non_cavity_r += Material.new(nil, constr_set.sheath_thick_in, BaseMaterial.Wood).rvalue

      # Calculate effective SIP core R-value
      # Solved in Wolfram Alpha: https://www.wolframalpha.com/input/?i=1%2FA+%3D+B%2F(C%2BD)+%2B+E%2F(2*F%2BG%2FH*x%2BD)+%2B+(1-B-E)%2F(x%2BD)
      spline_thick_in = 0.5 # in
      ins_thick_in = constr_set.thick_in - (2.0 * spline_thick_in) # in
      framing_r = Material.new(nil, constr_set.thick_in, BaseMaterial.Wood).rvalue
      spline_r = Material.new(nil, spline_thick_in, BaseMaterial.Wood).rvalue
      spline_frac = 4.0 / 48.0 # One 4" spline for every 48" wide panel
      cavity_frac = 1.0 - (spline_frac + constr_set.framing_factor)
      a = assembly_r
      b = constr_set.framing_factor
      c = framing_r
      d = non_cavity_r
      e = spline_frac
      f = spline_r
      g = ins_thick_in
      h = constr_set.thick_in
      cavity_r = (Math.sqrt((a * b * c * g - a * b * d * h - 2 * a * b * f * h + a * c * e * g - a * c * e * h - a * c * g + a * d * e * g - a * d * e * h - a * d * g + c * d * g + c * d * h + 2 * c * f * h + d**2 * g + d**2 * h + 2 * d * f * h)**2 - 4 * (-a * b * g + c * g + d * g) * (a * b * c * d * h + 2 * a * b * c * f * h - a * c * d * h + 2 * a * c * e * f * h - 2 * a * c * f * h - a * d**2 * h + 2 * a * d * e * f * h - 2 * a * d * f * h + c * d**2 * h + 2 * c * d * f * h + d**3 * h + 2 * d**2 * f * h)) - a * b * c * g + a * b * d * h + 2 * a * b * f * h - a * c * e * g + a * c * e * h + a * c * g - a * d * e * g + a * d * e * h + a * d * g - c * d * g - c * d * h - 2 * c * f * h - g * d**2 - d**2 * h - 2 * d * f * h) / (2 * (-a * b * g + c * g + d * g))
      if cavity_r > 0 # Choose this construction set
        return true, constr_set, cavity_r
      end
    end

    return false, constr_sets[-1], 0.0 # Pick fallback construction with minimum R-value
  end

  def self.pick_cmu_construction_set(assembly_r, constr_sets, inside_film, outside_film, surface_name)
    # Picks a construction set from supplied constr_sets for which a positive R-value
    # can be calculated for the unknown insulation to achieve the assembly R-value.

    constr_sets.each do |constr_set|
      fail 'Unexpected object.' unless constr_set.is_a? CMUConstructionSet

      film_r = inside_film.rvalue + outside_film.rvalue
      non_cavity_r = calc_non_cavity_r(film_r, constr_set)

      # Calculate effective other CMU R-value
      # Assumes no furring strips
      # Solved in Wolfram Alpha: https://www.wolframalpha.com/input/?i=1%2FA+%3D+B%2F(C%2BE%2Bx)+%2B+(1-B)%2F(D%2BE%2Bx)
      a = assembly_r
      b = constr_set.framing_factor
      c = Material.new(nil, constr_set.thick_in, BaseMaterial.Wood).rvalue # Framing
      d = Material.new(nil, constr_set.thick_in, BaseMaterial.Concrete, constr_set.cond_in).rvalue # Concrete
      e = non_cavity_r
      rigid_r = 0.5 * (Math.sqrt(a**2 - 4 * a * b * c + 4 * a * b * d + 2 * a * c - 2 * a * d + c**2 - 2 * c * d + d**2) + a - c - d - 2 * e)
      if rigid_r > 0 # Choose this construction set
        return true, constr_set, rigid_r
      end
    end

    return false, constr_sets[-1], 0.0 # Pick fallback construction with minimum R-value
  end

  def self.pick_icf_construction_set(assembly_r, constr_sets, inside_film, outside_film, surface_name)
    # Picks a construction set from supplied constr_sets for which a positive R-value
    # can be calculated for the unknown insulation to achieve the assembly R-value.

    constr_sets.each do |constr_set|
      fail 'Unexpected object.' unless constr_set.is_a? ICFConstructionSet

      film_r = inside_film.rvalue + outside_film.rvalue
      non_cavity_r = calc_non_cavity_r(film_r, constr_set)

      # Calculate effective ICF rigid ins R-value
      # Solved in Wolfram Alpha: https://www.wolframalpha.com/input/?i=1%2FA+%3D+B%2F(C%2BE)+%2B+(1-B)%2F(D%2BE%2B2*x)
      a = assembly_r
      b = constr_set.framing_factor
      c = Material.new(nil, 2 * constr_set.ins_thick_in + constr_set.concrete_thick_in, BaseMaterial.Wood).rvalue # Framing
      d = Material.new(nil, constr_set.concrete_thick_in, BaseMaterial.Concrete).rvalue # Concrete
      e = non_cavity_r
      icf_r = (a * b * c - a * b * d - a * c - a * e + c * d + c * e + d * e + e**2) / (2 * (a * b - c - e))
      if icf_r > 0 # Choose this construction set
        return true, constr_set, icf_r
      end
    end

    return false, constr_sets[-1], 0.0 # Pick fallback construction with minimum R-value
  end

  def self.pick_generic_construction_set(assembly_r, constr_sets, inside_film, outside_film, surface_name)
    # Picks a construction set from supplied constr_sets for which a positive R-value
    # can be calculated for the unknown insulation to achieve the assembly R-value.

    constr_sets.each do |constr_set|
      fail 'Unexpected object.' unless constr_set.is_a? GenericConstructionSet

      film_r = inside_film.rvalue + outside_film.rvalue
      non_cavity_r = calc_non_cavity_r(film_r, constr_set)

      # Calculate effective ins layer R-value
      layer_r = assembly_r - non_cavity_r
      if layer_r > 0 # Choose this construction set
        return true, constr_set, layer_r
      end
    end

    return false, constr_sets[-1], 0.0 # Pick fallback construction with minimum R-value
  end

  def self.check_surface_assembly_rvalue(runner, surfaces, inside_film, outside_film, assembly_r, match)
    # Verify that the actual OpenStudio construction R-value matches our target assembly R-value

    film_r = 0.0
    film_r += inside_film.rvalue unless inside_film.nil?
    film_r += outside_film.rvalue unless outside_film.nil?
    surfaces.each do |surface|
      constr_r = UnitConversions.convert(1.0 / surface.construction.get.uFactor(0.0).get, 'm^2*k/w', 'hr*ft^2*f/btu') + film_r

      if surface.adjacentFoundation.is_initialized
        foundation = surface.adjacentFoundation.get
        foundation.customBlocks.each do |custom_block|
          ins_mat = custom_block.material.to_StandardOpaqueMaterial.get
          constr_r += UnitConversions.convert(ins_mat.thickness, 'm', 'ft') / UnitConversions.convert(ins_mat.thermalConductivity, 'W/(m*K)', 'Btu/(hr*ft*R)')
        end
      end

      if (assembly_r - constr_r).abs > 0.1
        if match
          fail "Construction R-value (#{constr_r}) does not match Assembly R-value (#{assembly_r}) for '#{surface.name}'."
        else
          runner.registerWarning("Assembly R-value (#{assembly_r}) for '#{surface.name}' below minimum expected value. Construction R-value increased to #{constr_r.round(2)}.")
        end
      end
    end
  end

  def self.set_surface_interior(model, spaces, surface, interior_adjacent_to)
    if [HPXML::LocationBasementConditioned].include? interior_adjacent_to
      surface.setSpace(create_or_get_space(model, spaces, HPXML::LocationLivingSpace))
      @cond_bsmnt_surfaces << surface
    else
      surface.setSpace(create_or_get_space(model, spaces, interior_adjacent_to))
    end
  end

  def self.set_surface_exterior(model, spaces, surface, exterior_adjacent_to)
    if exterior_adjacent_to == HPXML::LocationOutside
      surface.setOutsideBoundaryCondition('Outdoors')
    elsif exterior_adjacent_to == HPXML::LocationGround
      surface.setOutsideBoundaryCondition('Foundation')
    elsif exterior_adjacent_to == HPXML::LocationOtherHousingUnit
      surface.setOutsideBoundaryCondition('Adiabatic')
    elsif exterior_adjacent_to == HPXML::LocationBasementConditioned
      surface.createAdjacentSurface(create_or_get_space(model, spaces, HPXML::LocationLivingSpace))
      @cond_bsmnt_surfaces << surface
    elsif [HPXML::LocationOtherHeatedSpace, HPXML::LocationOtherMultifamilyBufferSpace, HPXML::LocationOtherNonFreezingSpace].include? exterior_adjacent_to
      set_surface_otherside_coefficients(surface, exterior_adjacent_to, model, spaces)
    else
      surface.createAdjacentSurface(create_or_get_space(model, spaces, exterior_adjacent_to))
    end
  end

  def self.set_surface_otherside_coefficients(surface, exterior_adjacent_to, model, spaces)
    if spaces[exterior_adjacent_to].nil?
      # Create E+ other side coefficient object
      otherside_object = OpenStudio::Model::SurfacePropertyOtherSideCoefficients.new(model)
      otherside_object.setName(exterior_adjacent_to)
      # Refer to: https://www.sciencedirect.com/science/article/pii/B9780123972705000066 6.1.2 Part: Wall and roof transfer functions
      otherside_object.setCombinedConvectiveRadiativeFilmCoefficient(8.3)
      # Schedule of space temperature, can be shared with water heater/ducts
      sch = get_space_temperature_schedule(model, exterior_adjacent_to, spaces)
      otherside_object.setConstantTemperatureSchedule(sch)
      surface.setSurfacePropertyOtherSideCoefficients(otherside_object)
      spaces[exterior_adjacent_to] = otherside_object
    else
      surface.setSurfacePropertyOtherSideCoefficients(spaces[exterior_adjacent_to])
    end
    surface.setSunExposure('NoSun')
    surface.setWindExposure('NoWind')
  end

  def self.get_space_temperature_schedule(model, location, spaces)
    # Create outside boundary schedules to be actuated by EMS,
    # can be shared by any surface, duct adjacent to / located in those spaces

    # return if already exists
    model.getScheduleConstants.each do |sch|
      next unless sch.name.to_s == location

      return sch
    end

    sch = OpenStudio::Model::ScheduleConstant.new(model)
    sch.setName(location)

    space_values = Geometry.get_temperature_scheduled_space_values(location)

    if location == HPXML::LocationOtherHeatedSpace
      # Create a sensor to get dynamic heating setpoint
      htg_sch = spaces[HPXML::LocationLivingSpace].thermalZone.get.thermostatSetpointDualSetpoint.get.heatingSetpointTemperatureSchedule.get
      sensor_htg_spt = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Schedule Value')
      sensor_htg_spt.setName('htg_spt')
      sensor_htg_spt.setKeyName(htg_sch.name.to_s)
      space_values[:temp_min] = sensor_htg_spt.name.to_s
    end

    # Schedule type limits compatible
    schedule_type_limits = OpenStudio::Model::ScheduleTypeLimits.new(model)
    schedule_type_limits.setUnitType('Temperature')
    sch.setScheduleTypeLimits(schedule_type_limits)

    # Sensors
    if space_values[:indoor_weight] > 0
      sensor_ia = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Zone Air Temperature')
      sensor_ia.setName('cond_zone_temp')
      sensor_ia.setKeyName(spaces[HPXML::LocationLivingSpace].name.to_s)
    end

    if space_values[:outdoor_weight] > 0
      sensor_oa = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Site Outdoor Air Drybulb Temperature')
      sensor_oa.setName('oa_temp')
    end

    if space_values[:ground_weight] > 0
      sensor_gnd = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Site Surface Ground Temperature')
      sensor_gnd.setName('ground_temp')
    end

    actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(sch, 'Schedule:Constant', 'Schedule Value')
    actuator.setName("#{location.gsub(' ', '_').gsub('-', '_')}_temp_sch")

    # EMS to actuate schedule
    program = OpenStudio::Model::EnergyManagementSystemProgram.new(model)
    program.setName("#{location.gsub('-', '_')} Temperature Program")
    program.addLine("Set #{actuator.name} = 0.0")
    if not sensor_ia.nil?
      program.addLine("Set #{actuator.name} = #{actuator.name} + (#{sensor_ia.name} * #{space_values[:indoor_weight]})")
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
  # (e.g., water heaters and ducts).
  def self.get_space_or_schedule_from_location(location, object_name, model, spaces)
    return if [HPXML::LocationOtherExterior, HPXML::LocationOutside, HPXML::LocationRoofDeck].include? location

    sch = nil
    space = nil
    if [HPXML::LocationOtherHeatedSpace, HPXML::LocationOtherHousingUnit, HPXML::LocationOtherMultifamilyBufferSpace,
        HPXML::LocationOtherNonFreezingSpace, HPXML::LocationExteriorWall, HPXML::LocationUnderSlab].include? location
      # if located in spaces where we don't model a thermal zone, create and return temperature schedule
      sch = get_space_temperature_schedule(model, location, spaces)
    else
      space = get_space_from_location(location, object_name, model, spaces)
    end

    return space, sch
  end

  # Returns an OS:Space, or nil if a MF space
  # Should be called when the object's energy use is NOT sensitive to ambient temperature
  # (e.g., appliances).
  def self.get_space_from_location(location, object_name, model, spaces)
    return if location == HPXML::LocationOther

    num_orig_spaces = spaces.size

    if location == HPXML::LocationBasementConditioned
      space = create_or_get_space(model, spaces, HPXML::LocationLivingSpace)
    else
      space = create_or_get_space(model, spaces, location)
    end

    if spaces.size != num_orig_spaces
      fail "#{object_name} location is '#{location}' but building does not have this location specified."
    end

    return space
  end

  def self.set_subsurface_exterior(surface, wall_exterior_adjacent_to, spaces, model)
    # Set its parent surface outside boundary condition, which will be also applied to subsurfaces through OS
    # The parent surface is entirely comprised of the subsurface.

    # Subsurface on foundation wall, set it to be adjacent to outdoors
    if wall_exterior_adjacent_to == HPXML::LocationGround
      surface.setOutsideBoundaryCondition('Outdoors')
    else
      set_surface_exterior(model, spaces, surface, wall_exterior_adjacent_to)
    end
  end

  def self.get_min_neighbor_distance()
    min_neighbor_distance = nil
    @hpxml.neighbor_buildings.each do |neighbor_building|
      if min_neighbor_distance.nil?
        min_neighbor_distance = 9e99
      end
      if neighbor_building.distance < min_neighbor_distance
        min_neighbor_distance = neighbor_building.distance
      end
    end
    return min_neighbor_distance
  end

  def self.get_kiva_instances(fnd_walls, slabs)
    # Identify unique Kiva foundations that are required.
    kiva_fnd_walls = []
    fnd_walls.each do |foundation_wall|
      next unless foundation_wall.is_exterior

      kiva_fnd_walls << foundation_wall
    end
    if kiva_fnd_walls.empty? # Handle slab foundation type
      kiva_fnd_walls << nil
    end

    kiva_slabs = slabs

    return kiva_fnd_walls.product(kiva_slabs)
  end

  def self.set_foundation_and_walls_top()
    @foundation_top = 0
    @hpxml.foundation_walls.each do |foundation_wall|
      top = -1 * foundation_wall.depth_below_grade + foundation_wall.height
      @foundation_top = top if top > @foundation_top
    end
    @walls_top = @foundation_top + 8.0 * @ncfl_ag
  end
end

# FIXME: Move all of these construction classes to constructions.rb
class WoodStudConstructionSet
  def initialize(stud, framing_factor, rigid_r, osb_thick_in, drywall_thick_in, exterior_material)
    @stud = stud
    @framing_factor = framing_factor
    @rigid_r = rigid_r
    @osb_thick_in = osb_thick_in
    @drywall_thick_in = drywall_thick_in
    @exterior_material = exterior_material
  end
  attr_accessor(:stud, :framing_factor, :rigid_r, :osb_thick_in, :drywall_thick_in, :exterior_material)
end

class SteelStudConstructionSet
  def initialize(cavity_thick_in, corr_factor, framing_factor, rigid_r, osb_thick_in, drywall_thick_in, exterior_material)
    @cavity_thick_in = cavity_thick_in
    @corr_factor = corr_factor
    @framing_factor = framing_factor
    @rigid_r = rigid_r
    @osb_thick_in = osb_thick_in
    @drywall_thick_in = drywall_thick_in
    @exterior_material = exterior_material
  end
  attr_accessor(:cavity_thick_in, :corr_factor, :framing_factor, :rigid_r, :osb_thick_in, :drywall_thick_in, :exterior_material)
end

class DoubleStudConstructionSet
  def initialize(stud, framing_factor, framing_spacing, rigid_r, osb_thick_in, drywall_thick_in, exterior_material)
    @stud = stud
    @framing_factor = framing_factor
    @framing_spacing = framing_spacing
    @rigid_r = rigid_r
    @osb_thick_in = osb_thick_in
    @drywall_thick_in = drywall_thick_in
    @exterior_material = exterior_material
  end
  attr_accessor(:stud, :framing_factor, :framing_spacing, :rigid_r, :osb_thick_in, :drywall_thick_in, :exterior_material)
end

class SIPConstructionSet
  def initialize(thick_in, framing_factor, rigid_r, sheath_thick_in, osb_thick_in, drywall_thick_in, exterior_material)
    @thick_in = thick_in
    @framing_factor = framing_factor
    @rigid_r = rigid_r
    @sheath_thick_in = sheath_thick_in
    @osb_thick_in = osb_thick_in
    @drywall_thick_in = drywall_thick_in
    @exterior_material = exterior_material
  end
  attr_accessor(:thick_in, :framing_factor, :rigid_r, :sheath_thick_in, :osb_thick_in, :drywall_thick_in, :exterior_material)
end

class CMUConstructionSet
  def initialize(thick_in, cond_in, framing_factor, osb_thick_in, drywall_thick_in, exterior_material)
    @thick_in = thick_in
    @cond_in = cond_in
    @framing_factor = framing_factor
    @osb_thick_in = osb_thick_in
    @drywall_thick_in = drywall_thick_in
    @exterior_material = exterior_material
    @rigid_r = nil # solved for
  end
  attr_accessor(:thick_in, :cond_in, :framing_factor, :rigid_r, :osb_thick_in, :drywall_thick_in, :exterior_material)
end

class ICFConstructionSet
  def initialize(ins_thick_in, concrete_thick_in, framing_factor, rigid_r, osb_thick_in, drywall_thick_in, exterior_material)
    @ins_thick_in = ins_thick_in
    @concrete_thick_in = concrete_thick_in
    @framing_factor = framing_factor
    @rigid_r = rigid_r
    @osb_thick_in = osb_thick_in
    @drywall_thick_in = drywall_thick_in
    @exterior_material = exterior_material
  end
  attr_accessor(:ins_thick_in, :concrete_thick_in, :framing_factor, :rigid_r, :osb_thick_in, :drywall_thick_in, :exterior_material)
end

class GenericConstructionSet
  def initialize(rigid_r, osb_thick_in, drywall_thick_in, exterior_material)
    @rigid_r = rigid_r
    @osb_thick_in = osb_thick_in
    @drywall_thick_in = drywall_thick_in
    @exterior_material = exterior_material
  end
  attr_accessor(:rigid_r, :osb_thick_in, :drywall_thick_in, :exterior_material)
end

# register the measure to be used by the application
HPXMLtoOpenStudio.new.registerWithApplication
