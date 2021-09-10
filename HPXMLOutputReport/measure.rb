# frozen_string_literal: true

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require_relative 'resources/constants.rb'

# start the measure
class HPXMLOutputReport < OpenStudio::Measure::ReportingMeasure
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
    output_path = File.join(output_dir, "hpxml_output.#{output_format}")

    sqlFile.close()

    # Ensure sql file is immediately freed; otherwise we can get
    # errors on Windows when trying to delete this file.
    GC.start()

    # Initialize
    cost_multipliers = {}
    cost_multipliers[BS::Fixed] = BaseOutput.new
    cost_multipliers[BS::WallAreaAboveGradeConditioned] = BaseOutput.new
    cost_multipliers[BS::WallAreaAboveGradeExterior] = BaseOutput.new
    cost_multipliers[BS::WallAreaBelowGrade] = BaseOutput.new
    cost_multipliers[BS::FloorAreaConditioned] = BaseOutput.new
    cost_multipliers[BS::FloorAreaAttic] = BaseOutput.new
    cost_multipliers[BS::FloorAreaLighting] = BaseOutput.new
    cost_multipliers[BS::RoofArea] = BaseOutput.new
    cost_multipliers[BS::WindowArea] = BaseOutput.new
    cost_multipliers[BS::DoorArea] = BaseOutput.new
    cost_multipliers[BS::DuctUnconditionedSurfaceArea] = BaseOutput.new
    cost_multipliers[BS::SizeWaterHeater] = BaseOutput.new
    cost_multipliers[BS::FlowRateMechanicalVentilation] = BaseOutput.new
    cost_multipliers[BS::SlabPerimeterExposedConditioned] = BaseOutput.new
    cost_multipliers[BS::RimJoistAreaAboveGradeExterior] = BaseOutput.new

    hpxml.heating_systems.each do |heating_system|
      cost_multipliers["#{BS::SizeHeatingSystem}: #{heating_system.id}"] = BaseOutput.new
    end

    hpxml.cooling_systems.each do |cooling_system|
      cost_multipliers["#{BS::SizeCoolingSystem}: #{cooling_system.id}"] = BaseOutput.new
    end

    hpxml.heat_pumps.each do |heat_pump|
      cost_multipliers["#{BS::SizeHeatingSystem}: #{heat_pump.id}"] = BaseOutput.new
      cost_multipliers["#{BS::SizeCoolingSystem}: #{heat_pump.id}"] = BaseOutput.new
      cost_multipliers["#{BS::SizeHeatPumpBackup}: #{heat_pump.id}"] = BaseOutput.new
    end

    # Cost multipliers
    cost_multipliers.each do |cost_mult_type, cost_mult|
      cost_mult.name = "Building Summary: #{cost_mult_type}"
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

    results_out = []
    cost_multipliers.each do |key, cost_mult|
      results_out << ["#{cost_mult.name} (#{cost_mult.units})", cost_mult.output.round(2)]
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
    end
    attr_accessor(:name, :output, :units)
  end

  def get_cost_multiplier(hpxml, cost_mult_type)
    cost_mult = 0.0
    if cost_mult_type == 'Fixed'
      cost_mult += 1.0
    elsif cost_mult_type == 'Wall Area Above-Grade Conditioned'
      hpxml.walls.each do |wall|
        next unless wall.is_thermal_boundary

        cost_mult += wall.area
      end
    elsif cost_mult_type == 'Wall Area Above-Grade Exterior'
      hpxml.walls.each do |wall|
        next unless wall.is_exterior

        cost_mult += wall.area
      end
    elsif cost_mult_type == 'Wall Area Below-Grade'
      hpxml.foundation_walls.each do |foundation_wall|
        next unless foundation_wall.is_exterior

        cost_mult += foundation_wall.area
      end
    elsif cost_mult_type == 'Floor Area Conditioned'
      cost_mult += hpxml.building_construction.conditioned_floor_area
    elsif cost_mult_type == 'Floor Area Attic'
      hpxml.frame_floors.each do |frame_floor|
        next unless frame_floor.is_thermal_boundary
        next unless frame_floor.is_interior
        next unless frame_floor.is_ceiling
        next unless [HPXML::LocationAtticVented, HPXML::LocationAtticUnvented].include?(frame_floor.exterior_adjacent_to)

        cost_mult += frame_floor.area
      end
    elsif cost_mult_type == 'Floor Area Lighting'
      if hpxml.lighting.interior_usage_multiplier != 0
        cost_mult += hpxml.building_construction.conditioned_floor_area
      end
      hpxml.slabs.each do |slab|
        next unless [HPXML::LocationGarage].include?(slab.interior_adjacent_to)
        next if hpxml.lighting.garage_usage_multiplier == 0

        cost_mult += slab.area
      end
    elsif cost_mult_type == 'Roof Area'
      hpxml.roofs.each do |roof|
        cost_mult += roof.area
      end
    elsif cost_mult_type == 'Window Area'
      hpxml.windows.each do |window|
        cost_mult += window.area
      end
    elsif cost_mult_type == 'Door Area'
      hpxml.doors.each do |door|
        cost_mult += door.area
      end
    elsif cost_mult_type == 'Duct Unconditioned Surface Area'
      hpxml.hvac_distributions.each do |hvac_distribution|
        hvac_distribution.ducts.each do |duct|
          next if [HPXML::LocationLivingSpace, HPXML::LocationBasementConditioned].include?(duct.duct_location)

          cost_mult += duct.duct_surface_area
        end
      end
    elsif cost_mult_type.include? 'Size Heating System'
      hpxml.heating_systems.each do |heating_system|
        next if heating_system.id != cost_mult_type.split(': ')[1]

        cost_mult += UnitConversions.convert(heating_system.heating_capacity, 'btu/hr', 'kbtu/hr')
      end

      hpxml.heat_pumps.each do |heat_pump|
        next if heat_pump.id != cost_mult_type.split(': ')[1]

        cost_mult += UnitConversions.convert(heat_pump.heating_capacity, 'btu/hr', 'kbtu/hr')
      end
    elsif cost_mult_type.include? 'Size Cooling System'
      hpxml.cooling_systems.each do |cooling_system|
        next if cooling_system.id != cost_mult_type.split(': ')[1]

        cost_mult += UnitConversions.convert(cooling_system.cooling_capacity, 'btu/hr', 'kbtu/hr')
      end

      hpxml.heat_pumps.each do |heat_pump|
        next if heat_pump.id != cost_mult_type.split(': ')[1]

        cost_mult += UnitConversions.convert(heat_pump.cooling_capacity, 'btu/hr', 'kbtu/hr')
      end
    elsif cost_mult_type.include? 'Size Heat Pump Backup'
      hpxml.heat_pumps.each do |heat_pump|
        next if heat_pump.id != cost_mult_type.split(': ')[1]

        cost_mult += UnitConversions.convert(heat_pump.backup_heating_capacity, 'btu/hr', 'kbtu/hr')
      end
    elsif cost_mult_type == 'Size Water Heater'
      hpxml.water_heating_systems.each do |water_heating_system|
        next if water_heating_system.tank_volume.nil?

        cost_mult += water_heating_system.tank_volume
      end
    elsif cost_mult_type == 'Flow Rate Mechanical Ventilation'
      hpxml.ventilation_fans.each do |ventilation_fan|
        next unless ventilation_fan.used_for_whole_building_ventilation

        if ventilation_fan.rated_flow_rate
          cost_mult += ventilation_fan.rated_flow_rate
        end
      end
    elsif cost_mult_type == 'Slab Perimeter Exposed Conditioned'
      hpxml.slabs.each do |slab|
        next unless slab.is_exterior_thermal_boundary

        cost_mult += slab.exposed_perimeter
      end
    elsif cost_mult_type == 'Rim Joist Area Above-Grade Exterior'
      hpxml.rim_joists.each do |rim_joist|
        cost_mult += rim_joist.area
      end
    end
    return cost_mult
  end

  def assign_primary_and_secondary(hpxml, cost_multipliers)
    hpxml.heating_systems.each do |heating_system|
      next if !heating_system.primary_system

      cost_mult = BaseOutput.new
      cost_mult.output = cost_multipliers["#{BS::SizeHeatingSystem}: #{heating_system.id}"].output
      cost_multipliers["#{BS::SizeHeatingSystem}: Primary"] = cost_mult

      hpxml.heating_systems.each do |heating_system2|
        next if heating_system == heating_system2

        if not cost_multipliers.keys.include?("#{BS::SizeHeatingSystem}: Secondary")
          cost_mult = BaseOutput.new
          cost_mult.output = 0
          cost_multipliers["#{BS::SizeHeatingSystem}: Secondary"] = cost_mult
        end

        cost_mult = cost_multipliers["#{BS::SizeHeatingSystem}: Secondary"]
        cost_mult.output += cost_multipliers["#{BS::SizeHeatingSystem}: #{heating_system2.id}"].output
      end
    end

    hpxml.cooling_systems.each do |cooling_system|
      next if !cooling_system.primary_system

      cost_mult = BaseOutput.new
      cost_mult.output = cost_multipliers["#{BS::SizeCoolingSystem}: #{cooling_system.id}"].output
      cost_multipliers["#{BS::SizeCoolingSystem}: Primary"] = cost_mult

      hpxml.cooling_systems.each do |cooling_system2|
        next if cooling_system == cooling_system2

        if not cost_multipliers.keys.include?("#{BS::SizeCoolingSystem}: Secondary")
          cost_mult = BaseOutput.new
          cost_mult.output = 0
          cost_multipliers["#{BS::SizeCoolingSystem}: Secondary"] = cost_mult
        end

        cost_mult = cost_multipliers["#{BS::SizeCoolingSystem}: Secondary"]
        cost_mult.output += cost_multipliers["#{BS::SizeCoolingSystem}: #{cooling_system2.id}"].output
      end
    end

    hpxml.heat_pumps.each do |heat_pump|
      next if !heat_pump.primary_system

      cost_mult = BaseOutput.new
      cost_mult.output = cost_multipliers["#{BS::SizeHeatingSystem}: #{heat_pump.id}"].output
      cost_multipliers["#{BS::SizeHeatingSystem}: Primary"] = cost_mult

      cost_mult = BaseOutput.new
      cost_mult.output = cost_multipliers["#{BS::SizeHeatPumpBackup}: #{heat_pump.id}"].output
      cost_multipliers["#{BS::SizeHeatPumpBackup}: Primary"] = cost_mult

      hpxml.heat_pumps.each do |heat_pump2|
        next if heat_pump == heat_pump2

        if not cost_multipliers.keys.include?("#{BS::SizeHeatingSystem}: Secondary")
          cost_mult = BaseOutput.new
          cost_mult.output = 0
          cost_multipliers["#{BS::SizeHeatingSystem}: Secondary"] = cost_mult
        end

        cost_mult = cost_multipliers["#{BS::SizeHeatingSystem}: Secondary"]
        cost_mult.output += cost_multipliers["#{BS::SizeHeatingSystem}: #{heat_pump2.id}"].output

        if not cost_multipliers.keys.include?("#{BS::SizeHeatPumpBackup}: Secondary")
          cost_mult = BaseOutput.new
          cost_mult.output = 0
          cost_multipliers["#{BS::SizeHeatPumpBackup}: Secondary"] = cost_mult
        end

        cost_mult = cost_multipliers["#{BS::SizeHeatPumpBackup}: Secondary"]
        cost_mult.output += cost_multipliers["#{BS::SizeHeatPumpBackup}: #{heat_pump2.id}"].output
      end
    end
  end
end

# register the measure to be used by the application
HPXMLOutputReport.new.registerWithApplication
