# frozen_string_literal: true

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require_relative 'resources/constants.rb'

# start the measure
class ReportHPXMLOutput < OpenStudio::Measure::ReportingMeasure
  # human readable name
  def name
    # Measure name should be the title case of the class name.
    return 'HPXML Output Report'
  end

  # human readable description
  def description
    return 'Reports HPXML outputs for residential HPXML-based models.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'Parses the HPXML file and reports pre-defined outputs.'
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

    return args
  end

  # define what happens when the measure is run
  def run(runner, user_arguments)
    super(runner, user_arguments)

    model = runner.lastOpenStudioModel
    if model.empty?
      runner.registerError('Cannot find OpenStudio model.')
      return false
    end
    model = model.get

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    output_format = runner.getStringArgumentValue('output_format', user_arguments)

    sqlFile = runner.lastEnergyPlusSqlFile
    if sqlFile.empty?
      runner.registerError('Cannot find EnergyPlus sql file.')
      return false
    end
    sqlFile = sqlFile.get
    if not sqlFile.connectionOpen
      runner.registerError('EnergyPlus simulation failed.')
      return false
    end
    model.setSqlFile(sqlFile)

    hpxml_defaults_path = model.getBuilding.additionalProperties.getFeatureAsString('hpxml_defaults_path').get
    hpxml = HPXML.new(hpxml_path: hpxml_defaults_path)

    # Set paths
    output_dir = File.dirname(sqlFile.path.to_s)
    output_path = File.join(output_dir, "results_hpxml.#{output_format}")

    sqlFile.close()

    # Ensure sql file is immediately freed; otherwise we can get
    # errors on Windows when trying to delete this file.
    GC.start()

    # Initialize
    cost_multipliers = {}
    cost_multipliers[BS::WallAboveGradeConditioned] = BaseOutput.new
    cost_multipliers[BS::WallAboveGradeExterior] = BaseOutput.new
    cost_multipliers[BS::WallBelowGrade] = BaseOutput.new
    cost_multipliers[BS::FloorConditioned] = BaseOutput.new
    cost_multipliers[BS::FloorLighting] = BaseOutput.new
    cost_multipliers[BS::Ceiling] = BaseOutput.new
    cost_multipliers[BS::Roof] = BaseOutput.new
    cost_multipliers[BS::Window] = BaseOutput.new
    cost_multipliers[BS::Door] = BaseOutput.new
    cost_multipliers[BS::DuctUnconditioned] = BaseOutput.new
    cost_multipliers[BS::RimJoistAboveGradeExterior] = BaseOutput.new
    cost_multipliers[BS::SlabPerimeterExposedConditioned] = BaseOutput.new
    cost_multipliers[BS::CoolingSystem] = BaseOutput.new
    cost_multipliers[BS::HeatingSystem] = BaseOutput.new
    cost_multipliers[BS::HeatPumpBackup] = BaseOutput.new
    cost_multipliers[BS::WaterHeater] = BaseOutput.new
    cost_multipliers[BS::FlowRateMechanicalVentilation] = BaseOutput.new

    # Cost multipliers
    cost_multipliers.each do |cost_mult_type, cost_mult|
      cost_mult.output = get_cost_multiplier(hpxml, cost_mult_type)
    end

    # Primary and Secondary
    if hpxml.primary_hvac_systems.size > 0
      assign_primary_and_secondary(hpxml, cost_multipliers)
    end

    # Units
    cost_multipliers.each do |cost_mult_type, cost_mult|
      cost_mult.units = BS.get_units(cost_mult_type)
    end

    # Report results
    cost_multipliers.each do |cost_mult_type, cost_mult|
      cost_mult_type_str = OpenStudio::toUnderscoreCase("#{cost_mult_type} #{cost_mult.units}")
      cost_mult = cost_mult.output.round(2)
      runner.registerValue(cost_mult_type_str, cost_mult)
    end

    # Write results
    write_output(runner, cost_multipliers, output_format, output_path)

    return true
  end

  def write_output(runner, cost_multipliers, output_format, output_path)
    line_break = nil

    segment, _ = cost_multipliers.keys[0].split(':', 2)
    segment = segment.strip
    results_out = []
    cost_multipliers.each do |key, cost_mult|
      new_segment, _ = key.split(':', 2)
      new_segment = new_segment.strip
      if new_segment != segment
        results_out << [line_break]
        segment = new_segment
      end
      results_out << ["#{key} (#{cost_mult.units})", cost_mult.output.round(2)]
    end

    if output_format == 'csv'
      CSV.open(output_path, 'wb') { |csv| results_out.to_a.each { |elem| csv << elem } }
    elsif output_format == 'json'
      h = {}
      results_out.each do |out|
        next if out == [line_break]

        grp, name = out[0].split(':', 2)
        h[grp] = {} if h[grp].nil?
        h[grp][name.strip] = out[1]
      end

      require 'json'
      File.open(output_path, 'w') { |json| json.write(JSON.pretty_generate(h)) }
    end
    runner.registerInfo("Wrote hpxml output to #{output_path}.")
  end

  class BaseOutput
    def initialize()
      @output = 0.0
    end
    attr_accessor(:output, :units)
  end

  def get_cost_multiplier(hpxml, cost_mult_type)
    cost_mult = 0.0
    if cost_mult_type == 'Enclosure: Wall Area Thermal Boundary'
      hpxml.walls.each do |wall|
        next unless wall.is_thermal_boundary

        cost_mult += wall.area
      end
    elsif cost_mult_type == 'Enclosure: Wall Area Exterior'
      hpxml.walls.each do |wall|
        next unless wall.is_exterior

        cost_mult += wall.area
      end
    elsif cost_mult_type == 'Enclosure: Foundation Wall Area Exterior'
      hpxml.foundation_walls.each do |foundation_wall|
        next unless foundation_wall.is_exterior

        cost_mult += foundation_wall.area
      end
    elsif cost_mult_type == 'Enclosure: Floor Area Conditioned'
      cost_mult += hpxml.building_construction.conditioned_floor_area
    elsif cost_mult_type == 'Enclosure: Floor Area Lighting'
      if hpxml.lighting.interior_usage_multiplier != 0
        cost_mult += hpxml.building_construction.conditioned_floor_area
      end
      hpxml.slabs.each do |slab|
        next unless [HPXML::LocationGarage].include?(slab.interior_adjacent_to)
        next if hpxml.lighting.garage_usage_multiplier == 0

        cost_mult += slab.area
      end
    elsif cost_mult_type == 'Enclosure: Ceiling Area Thermal Boundary'
      hpxml.frame_floors.each do |frame_floor|
        next unless frame_floor.is_thermal_boundary
        next unless frame_floor.is_interior
        next unless frame_floor.is_ceiling
        next unless [HPXML::LocationAtticVented,
                     HPXML::LocationAtticUnvented].include?(frame_floor.exterior_adjacent_to)

        cost_mult += frame_floor.area
      end
    elsif cost_mult_type == 'Enclosure: Roof Area'
      hpxml.roofs.each do |roof|
        cost_mult += roof.area
      end
    elsif cost_mult_type == 'Enclosure: Window Area'
      hpxml.windows.each do |window|
        cost_mult += window.area
      end
    elsif cost_mult_type == 'Enclosure: Door Area'
      hpxml.doors.each do |door|
        cost_mult += door.area
      end
    elsif cost_mult_type == 'Enclosure: Duct Area Unconditioned'
      hpxml.hvac_distributions.each do |hvac_distribution|
        hvac_distribution.ducts.each do |duct|
          next if [HPXML::LocationLivingSpace,
                   HPXML::LocationBasementConditioned].include?(duct.duct_location)

          cost_mult += duct.duct_surface_area
        end
      end
    elsif cost_mult_type == 'Enclosure: Rim Joist Area'
      hpxml.rim_joists.each do |rim_joist|
        cost_mult += rim_joist.area
      end
    elsif cost_mult_type == 'Enclosure: Slab Exposed Perimeter Thermal Boundary'
      hpxml.slabs.each do |slab|
        next unless slab.is_exterior_thermal_boundary

        cost_mult += slab.exposed_perimeter
      end
    elsif cost_mult_type == 'Systems: Heating Capacity'
      hpxml.heating_systems.each do |heating_system|
        cost_mult += UnitConversions.convert(heating_system.heating_capacity, 'btu/hr', 'kbtu/hr')
      end

      hpxml.heat_pumps.each do |heat_pump|
        cost_mult += UnitConversions.convert(heat_pump.heating_capacity, 'btu/hr', 'kbtu/hr')
      end
    elsif cost_mult_type == 'Systems: Cooling Capacity'
      hpxml.cooling_systems.each do |cooling_system|
        cost_mult += UnitConversions.convert(cooling_system.cooling_capacity, 'btu/hr', 'kbtu/hr')
      end

      hpxml.heat_pumps.each do |heat_pump|
        cost_mult += UnitConversions.convert(heat_pump.cooling_capacity, 'btu/hr', 'kbtu/hr')
      end
    elsif cost_mult_type == 'Systems: Heat Pump Backup Capacity'
      hpxml.heat_pumps.each do |heat_pump|
        cost_mult += UnitConversions.convert(heat_pump.backup_heating_capacity, 'btu/hr', 'kbtu/hr')
      end
    elsif cost_mult_type == 'Systems: Water Heater Tank Volume'
      hpxml.water_heating_systems.each do |water_heating_system|
        cost_mult += water_heating_system.tank_volume.to_f
      end
    elsif cost_mult_type == 'Systems: Mechanical Ventilation Flow Rate'
      hpxml.ventilation_fans.each do |ventilation_fan|
        next unless ventilation_fan.used_for_whole_building_ventilation

        cost_mult += ventilation_fan.flow_rate.to_f
      end
    end
    return cost_mult
  end

  def assign_primary_and_secondary(hpxml, cost_multipliers)
    # Determine if we have primary/secondary systems
    has_primary_cooling_system = false
    has_secondary_cooling_system = false
    hpxml.cooling_systems.each do |cooling_system|
      has_primary_cooling_system = true if cooling_system.primary_system
      has_secondary_cooling_system = true if !cooling_system.primary_system
    end
    hpxml.heat_pumps.each do |heat_pump|
      has_primary_cooling_system = true if heat_pump.primary_cooling_system
      has_secondary_cooling_system = true if !heat_pump.primary_cooling_system
    end
    has_secondary_cooling_system = false unless has_primary_cooling_system

    has_primary_heating_system = false
    has_secondary_heating_system = false
    hpxml.heating_systems.each do |heating_system|
      has_primary_heating_system = true if heating_system.primary_system
      has_secondary_heating_system = true if !heating_system.primary_system
    end
    hpxml.heat_pumps.each do |heat_pump|
      has_primary_heating_system = true if heat_pump.primary_heating_system
      has_secondary_heating_system = true if !heat_pump.primary_heating_system
    end
    has_secondary_heating_system = false unless has_primary_heating_system

    # Set up order of outputs
    if has_primary_cooling_system
      cost_multipliers["Primary #{BS::CoolingSystem}"] = BaseOutput.new
    end

    if has_primary_heating_system
      cost_multipliers["Primary #{BS::HeatingSystem}"] = BaseOutput.new
      cost_multipliers["Primary #{BS::HeatPumpBackup}"] = BaseOutput.new
    end

    if has_secondary_cooling_system
      cost_multipliers["Secondary #{BS::CoolingSystem}"] = BaseOutput.new
    end

    if has_secondary_heating_system
      cost_multipliers["Secondary #{BS::HeatingSystem}"] = BaseOutput.new
      cost_multipliers["Secondary #{BS::HeatPumpBackup}"] = BaseOutput.new
    end

    # Obtain values
    if has_primary_cooling_system || has_secondary_cooling_system
      hpxml.cooling_systems.each do |cooling_system|
        prefix = cooling_system.primary_system ? 'Primary' : 'Secondary'
        cost_multipliers["#{prefix} #{BS::CoolingSystem}"].output += UnitConversions.convert(cooling_system.cooling_capacity, 'btu/hr', 'kbtu/hr')
      end
      hpxml.heat_pumps.each do |heat_pump|
        prefix = heat_pump.primary_cooling_system ? 'Primary' : 'Secondary'
        cost_multipliers["#{prefix} #{BS::CoolingSystem}"].output += UnitConversions.convert(heat_pump.cooling_capacity, 'btu/hr', 'kbtu/hr')
      end
    end

    if has_primary_heating_system || has_secondary_heating_system
      hpxml.heating_systems.each do |heating_system|
        prefix = heating_system.primary_system ? 'Primary' : 'Secondary'
        cost_multipliers["#{prefix} #{BS::HeatingSystem}"].output += UnitConversions.convert(heating_system.heating_capacity, 'btu/hr', 'kbtu/hr')
      end
      hpxml.heat_pumps.each do |heat_pump|
        prefix = heat_pump.primary_heating_system ? 'Primary' : 'Secondary'
        cost_multipliers["#{prefix} #{BS::HeatingSystem}"].output += UnitConversions.convert(heat_pump.heating_capacity, 'btu/hr', 'kbtu/hr')
        cost_multipliers["#{prefix} #{BS::HeatPumpBackup}"].output += UnitConversions.convert(heat_pump.backup_heating_capacity, 'btu/hr', 'kbtu/hr')
      end
    end
  end
end

# register the measure to be used by the application
ReportHPXMLOutput.new.registerWithApplication
