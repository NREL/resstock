# frozen_string_literal: true

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require 'msgpack'
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
  def arguments(model) # rubocop:disable Lint/UnusedMethodArgument
    args = OpenStudio::Measure::OSArgumentVector.new

    format_chs = OpenStudio::StringVector.new
    format_chs << 'csv'
    format_chs << 'json'
    format_chs << 'msgpack'
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
    output_dir = File.dirname(runner.lastEpwFilePath.get.to_s)

    if not File.exist? File.join(output_dir, 'eplusout.msgpack')
      runner.registerError('Cannot find eplusout.msgpack.')
      return false
    end
    @msgpackData = MessagePack.unpack(File.read(File.join(output_dir, 'eplusout.msgpack'), mode: 'rb'))

    hpxml_defaults_path = model.getBuilding.additionalProperties.getFeatureAsString('hpxml_defaults_path').get
    hpxml = HPXML.new(hpxml_path: hpxml_defaults_path)

    # Set paths
    output_path = File.join(output_dir, "results_hpxml.#{output_format}")

    # Initialize
    bldg_outputs = {}
    bldg_outputs[BO::EnclosureWallAreaThermalBoundary] = BaseOutput.new
    bldg_outputs[BO::EnclosureWallAreaExterior] = BaseOutput.new
    bldg_outputs[BO::EnclosureFoundationWallAreaExterior] = BaseOutput.new
    bldg_outputs[BO::EnclosureFloorAreaConditioned] = BaseOutput.new
    bldg_outputs[BO::EnclosureFloorAreaLighting] = BaseOutput.new
    bldg_outputs[BO::EnclosureFloorAreaFoundation] = BaseOutput.new
    bldg_outputs[BO::EnclosureCeilingAreaThermalBoundary] = BaseOutput.new
    bldg_outputs[BO::EnclosureRoofArea] = BaseOutput.new
    bldg_outputs[BO::EnclosureWindowArea] = BaseOutput.new
    bldg_outputs[BO::EnclosureDoorArea] = BaseOutput.new
    bldg_outputs[BO::EnclosureDuctAreaUnconditioned] = BaseOutput.new
    bldg_outputs[BO::EnclosureRimJoistAreaExterior] = BaseOutput.new
    bldg_outputs[BO::EnclosureSlabExposedPerimeterThermalBoundary] = BaseOutput.new
    bldg_outputs[BO::SystemsCoolingCapacity] = BaseOutput.new
    bldg_outputs[BO::SystemsHeatingCapacity] = BaseOutput.new
    bldg_outputs[BO::SystemsHeatPumpBackupCapacity] = BaseOutput.new
    bldg_outputs[BO::SystemsWaterHeaterVolume] = BaseOutput.new
    bldg_outputs[BO::SystemsMechanicalVentilationFlowRate] = BaseOutput.new

    # Building outputs
    bldg_outputs.each do |bldg_type, bldg_output|
      bldg_output.output = get_bldg_output(hpxml, bldg_type)
    end

    # Primary and Secondary
    if hpxml.primary_hvac_systems.size > 0
      assign_primary_and_secondary(hpxml, bldg_outputs)
    end

    # Units
    bldg_outputs.each do |bldg_type, bldg_output|
      bldg_output.units = BO.get_units(bldg_type)
    end

    # Write/report results
    report_output_results(runner, bldg_outputs, output_format, output_path)

    return true
  end

  def report_output_results(runner, bldg_outputs, output_format, output_path)
    line_break = nil

    segment, _ = bldg_outputs.keys[0].split(':', 2)
    segment = segment.strip

    results_out = []

    bldg_outputs.each do |key, bldg_output|
      new_segment, _ = key.split(':', 2)
      new_segment = new_segment.strip
      if new_segment != segment
        results_out << [line_break]
        segment = new_segment
      end
      results_out << ["#{key} (#{bldg_output.units})", bldg_output.output.round(2)]
    end

    if ['csv'].include? output_format
      CSV.open(output_path, 'wb') { |csv| results_out.to_a.each { |elem| csv << elem } }
    elsif ['json', 'msgpack'].include? output_format
      h = {}
      results_out.each do |out|
        next if out == [line_break]

        grp, name = out[0].split(':', 2)
        h[grp] = {} if h[grp].nil?
        h[grp][name.strip] = out[1]
      end

      if output_format == 'json'
        require 'json'
        File.open(output_path, 'w') { |json| json.write(JSON.pretty_generate(h)) }
      elsif output_format == 'msgpack'
        File.open(output_path, 'w') { |json| h.to_msgpack(json) }
      end
    end
    runner.registerInfo("Wrote hpxml output to #{output_path}.")

    results_out.each do |name, value|
      next if name.nil? || value.nil?

      name = OpenStudio::toUnderscoreCase(name).chomp('_')

      runner.registerValue(name, value)
      runner.registerInfo("Registering #{value} for #{name}.")
    end
  end

  class BaseOutput
    def initialize()
      @output = 0.0
    end
    attr_accessor(:output, :units)
  end

  def get_bldg_output(hpxml, bldg_type)
    bldg_output = 0.0
    if bldg_type == BO::EnclosureWallAreaThermalBoundary
      hpxml.walls.each do |wall|
        next unless wall.is_thermal_boundary

        bldg_output += wall.area
      end
    elsif bldg_type == BO::EnclosureWallAreaExterior
      hpxml.walls.each do |wall|
        next unless wall.is_exterior

        bldg_output += wall.area
      end
    elsif bldg_type == BO::EnclosureFoundationWallAreaExterior
      hpxml.foundation_walls.each do |foundation_wall|
        next unless foundation_wall.is_exterior

        bldg_output += foundation_wall.area
      end
    elsif bldg_type == BO::EnclosureFloorAreaConditioned
      bldg_output += hpxml.building_construction.conditioned_floor_area
    elsif bldg_type == BO::EnclosureFloorAreaLighting
      if hpxml.lighting.interior_usage_multiplier.to_f != 0
        bldg_output += hpxml.building_construction.conditioned_floor_area
      end
      hpxml.slabs.each do |slab|
        next unless [HPXML::LocationGarage].include?(slab.interior_adjacent_to)
        next if hpxml.lighting.garage_usage_multiplier.to_f == 0

        bldg_output += slab.area
      end
    elsif bldg_type == BO::EnclosureFloorAreaFoundation
      hpxml.slabs.each do |slab|
        next if slab.interior_adjacent_to == HPXML::LocationGarage

        bldg_output += slab.area
      end
    elsif bldg_type == BO::EnclosureCeilingAreaThermalBoundary
      hpxml.floors.each do |floor|
        next unless floor.is_thermal_boundary
        next unless floor.is_interior
        next unless floor.is_ceiling
        next unless [HPXML::LocationAtticVented,
                     HPXML::LocationAtticUnvented].include?(floor.exterior_adjacent_to)

        bldg_output += floor.area
      end
    elsif bldg_type == BO::EnclosureRoofArea
      hpxml.roofs.each do |roof|
        bldg_output += roof.area
      end
    elsif bldg_type == BO::EnclosureWindowArea
      hpxml.windows.each do |window|
        bldg_output += window.area
      end
    elsif bldg_type == BO::EnclosureDoorArea
      hpxml.doors.each do |door|
        next unless door.is_thermal_boundary

        bldg_output += door.area
      end
    elsif bldg_type == BO::EnclosureDuctAreaUnconditioned
      hpxml.hvac_distributions.each do |hvac_distribution|
        hvac_distribution.ducts.each do |duct|
          next if [HPXML::LocationLivingSpace,
                   HPXML::LocationBasementConditioned].include?(duct.duct_location)

          bldg_output += duct.duct_surface_area * duct.duct_surface_area_multiplier
        end
      end
    elsif bldg_type == BO::EnclosureRimJoistAreaExterior
      hpxml.rim_joists.each do |rim_joist|
        bldg_output += rim_joist.area
      end
    elsif bldg_type == BO::EnclosureSlabExposedPerimeterThermalBoundary
      hpxml.slabs.each do |slab|
        next unless slab.is_exterior_thermal_boundary

        bldg_output += slab.exposed_perimeter
      end
    elsif bldg_type == BO::SystemsHeatingCapacity
      hpxml.heating_systems.each do |heating_system|
        next if heating_system.is_heat_pump_backup_system

        bldg_output += heating_system.heating_capacity
      end

      hpxml.heat_pumps.each do |heat_pump|
        bldg_output += heat_pump.heating_capacity
      end
    elsif bldg_type == BO::SystemsCoolingCapacity
      hpxml.cooling_systems.each do |cooling_system|
        bldg_output += cooling_system.cooling_capacity
      end

      hpxml.heat_pumps.each do |heat_pump|
        bldg_output += heat_pump.cooling_capacity
      end
    elsif bldg_type == BO::SystemsHeatPumpBackupCapacity
      hpxml.heat_pumps.each do |heat_pump|
        if not heat_pump.backup_heating_capacity.nil?
          bldg_output += heat_pump.backup_heating_capacity
        elsif not heat_pump.backup_system.nil?
          bldg_output += heat_pump.backup_system.heating_capacity
        end
      end
    elsif bldg_type == BO::SystemsWaterHeaterVolume
      hpxml.water_heating_systems.each do |water_heating_system|
        bldg_output += water_heating_system.tank_volume.to_f
      end
    elsif bldg_type == BO::SystemsMechanicalVentilationFlowRate
      hpxml.ventilation_fans.each do |ventilation_fan|
        next unless ventilation_fan.used_for_whole_building_ventilation

        bldg_output += ventilation_fan.flow_rate.to_f
      end
    end
    return bldg_output
  end

  def assign_primary_and_secondary(hpxml, bldg_outputs)
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
      next if heating_system.is_heat_pump_backup_system

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
      bldg_outputs["Primary #{BO::SystemsCoolingCapacity}"] = BaseOutput.new
    end

    if has_primary_heating_system
      bldg_outputs["Primary #{BO::SystemsHeatingCapacity}"] = BaseOutput.new
      bldg_outputs["Primary #{BO::SystemsHeatPumpBackupCapacity}"] = BaseOutput.new
    end

    if has_secondary_cooling_system
      bldg_outputs["Secondary #{BO::SystemsCoolingCapacity}"] = BaseOutput.new
    end

    if has_secondary_heating_system
      bldg_outputs["Secondary #{BO::SystemsHeatingCapacity}"] = BaseOutput.new
      bldg_outputs["Secondary #{BO::SystemsHeatPumpBackupCapacity}"] = BaseOutput.new
    end

    # Obtain values
    if has_primary_cooling_system || has_secondary_cooling_system
      hpxml.cooling_systems.each do |cooling_system|
        prefix = cooling_system.primary_system ? 'Primary' : 'Secondary'
        bldg_outputs["#{prefix} #{BO::SystemsCoolingCapacity}"].output += cooling_system.cooling_capacity
      end
      hpxml.heat_pumps.each do |heat_pump|
        prefix = heat_pump.primary_cooling_system ? 'Primary' : 'Secondary'
        bldg_outputs["#{prefix} #{BO::SystemsCoolingCapacity}"].output += heat_pump.cooling_capacity
      end
    end

    if has_primary_heating_system || has_secondary_heating_system
      hpxml.heating_systems.each do |heating_system|
        next if heating_system.is_heat_pump_backup_system

        prefix = heating_system.primary_system ? 'Primary' : 'Secondary'
        bldg_outputs["#{prefix} #{BO::SystemsHeatingCapacity}"].output += heating_system.heating_capacity
      end
      hpxml.heat_pumps.each do |heat_pump|
        prefix = heat_pump.primary_heating_system ? 'Primary' : 'Secondary'
        bldg_outputs["#{prefix} #{BO::SystemsHeatingCapacity}"].output += heat_pump.heating_capacity
        if not heat_pump.backup_heating_capacity.nil?
          bldg_outputs["#{prefix} #{BO::SystemsHeatPumpBackupCapacity}"].output += heat_pump.backup_heating_capacity
        elsif not heat_pump.backup_system.nil?
          bldg_outputs["#{prefix} #{BO::SystemsHeatPumpBackupCapacity}"].output += heat_pump.backup_system.heating_capacity
        end
      end
    end
  end
end

# register the measure to be used by the application
ReportHPXMLOutput.new.registerWithApplication
