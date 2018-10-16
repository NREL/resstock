# insert your copyright here

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require 'erb'
require "#{File.dirname(__FILE__)}/resources/unit_conversions"

# start the measure
class ThermalCapacitanceReport < OpenStudio::Measure::ReportingMeasure

  # human readable name
  def name
    # Measure name should be the title case of the class name.
    return 'Thermal Capacitance Report'
  end

  # human readable description
  def description
    return 'TODO'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'TODO'
  end

  # define the arguments that the user will input
  def arguments
    args = OpenStudio::Measure::OSArgumentVector.new

    return args
  end
  
  # define the outputs that the measure will create
  def outputs
    buildstock_outputs = [
                          "floor_fin_ins_unfin_attic", # unfinished attic floor
                          "floor_fin_ins_unfin", # interzonal or cantilevered floor
                          "floor_fin_unins_fin", # floor between 1st/2nd story living spaces
                          "floor_unfin_unins_unfin", # floor between garage and attic
                          "floor_fnd_grnd_fin_b", # finished basement floor
                          "floor_fnd_grnd_unfin_b", # unfinished basement floor
                          "floor_fnd_grnd_fin_slab", # finished slab
                          "floor_fnd_grnd_unfin_slab", # garage slab
                          "floor_unfin_b_ins_fin", # unfinished basement ceiling
                          "floor_cs_ins_fin", # crawlspace ceiling
                          "floor_pb_ins_fin", # pier beam ceiling
                          "floor_fnd_grnd_cs", # crawlspace floor
                          "roof_unfin_unins_ext", # garage roof
                          "roof_unfin_ins_ext", # unfinished attic roof
                          "roof_fin_ins_ext", # finished attic roof
                          "wall_ext_ins_fin", # living exterior wall
                          "wall_ext_ins_unfin", # attic gable wall under insulated roof
                          "wall_ext_unins_unfin", # garage exterior wall or attic gable wall under uninsulated roof
                          "wall_fnd_grnd_fin_b", # finished basement wall
                          "wall_fnd_grnd_unfin_b", # unfinished basement wall
                          "wall_fnd_grnd_cs", # crawlspace wall
                          "wall_int_fin_ins_unfin", # interzonal wall
                          "wall_int_fin_unins_fin", # wall between two finished spaces
                          "wall_int_unfin_unins_unfin", # wall between two unfinished spaces
                          "living_space_footing_construction", # living space footing construction
                          "garage_space_footing_construction", # garage space footing construction
                          # "window_construction", # exterior window
                          "door", # exterior door
                          "residential_furniture_construction_living_space", # furniture in living
                          "residential_furniture_construction_living_space_story_2", # furniture in living, second floor
                          "residential_furniture_construction_unfinished_basement_space", # furniture in unfinished basement
                          "residential_furniture_construction_finished_basement_space", # furniture in finished basement
                          "residential_furniture_construction_garage_space", # furniture in garage
                          "living_space_air", # living space air
                          "garage_space_air", # garage space air
                          "unfinished_basement_space_air", # unfinished basement space air
                          "finished_basement_space_air", # finished basement space air
                          "crawl_space_air", # crawl space air
                          "unfinished_attic_space_air" # unfinished attic space air
                         ]
    result = OpenStudio::Measure::OSOutputVector.new
    buildstock_outputs.each do |output|
        result << OpenStudio::Measure::OSOutput.makeDoubleOutput(output)
    end
    return result
  end

  # define what happens when the measure is run
  def run(runner, user_arguments)
    super(runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments, user_arguments)
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

    desired_units = "kj/k"

    model.getConstructions.each do |construction|

      # surfaces
      area, name = get_surface_area(model, construction)
      if area > 0
        val = get_thermal_capacitance(construction, area)
        report_output(runner, name, [OpenStudio::OptionalDouble.new(val)], desired_units, desired_units)
      end

      # foundations
      area, name = get_foundation_area(model, construction)
      if area > 0
        val = get_thermal_capacitance(construction, area)
        report_output(runner, name, [OpenStudio::OptionalDouble.new(val)], desired_units, desired_units)
      end

      # sub surfaces
      area, name = get_sub_surface_area(model, construction)
      if area > 0
        val = get_thermal_capacitance(construction, area)
        report_output(runner, name, [OpenStudio::OptionalDouble.new(val)], desired_units, desired_units)
      end

      # internal mass
      area, name = get_internal_mass_area(model, construction)
      if area > 0
        val = get_thermal_capacitance(construction, area)
        report_output(runner, name, [OpenStudio::OptionalDouble.new(val)], desired_units, desired_units)
      end

    end

    report_output(runner, "living_space_air", [OpenStudio::OptionalDouble.new(UnitConversions.convert(Geometry.get_above_grade_finished_volume(model, true), "ft^3", "m^3") * 1.004 * 1.225)], desired_units, desired_units)
    model.getThermalZones.each do |thermal_zone|
      if Geometry.is_garage(thermal_zone)
        report_output(runner, "garage_space_air", [OpenStudio::OptionalDouble.new(UnitConversions.convert(Geometry.get_zone_volume(thermal_zone, false, runner), "ft^3", "m^3") * 1.004 * 1.225)], desired_units, desired_units)
      elsif Geometry.is_unfinished_basement(thermal_zone)
        report_output(runner, "unfinished_basement_space_air", [OpenStudio::OptionalDouble.new(UnitConversions.convert(Geometry.get_zone_volume(thermal_zone, false, runner), "ft^3", "m^3") * 1.004 * 1.225)], desired_units, desired_units)
      elsif Geometry.is_finished_basement(thermal_zone)
        report_output(runner, "finished_basement_space_air", [OpenStudio::OptionalDouble.new(UnitConversions.convert(Geometry.get_zone_volume(thermal_zone, false, runner), "ft^3", "m^3") * 1.004 * 1.225)], desired_units, desired_units)
      elsif Geometry.is_crawl(thermal_zone)
        report_output(runner, "crawl_space_air", [OpenStudio::OptionalDouble.new(UnitConversions.convert(Geometry.get_zone_volume(thermal_zone, false, runner), "ft^3", "m^3") * 1.004 * 1.225)], desired_units, desired_units)
      elsif Geometry.is_unfinished_attic(thermal_zone)
        report_output(runner, "unfinished_attic_space_air", [OpenStudio::OptionalDouble.new(UnitConversions.convert(Geometry.get_zone_volume(thermal_zone, false, runner), "ft^3", "m^3") * 1.004 * 1.225)], desired_units, desired_units)
      end
    end

    sqlFile.close()

    return true
  end

  def get_thermal_capacitance(construction, area)
    val = 0
    construction.layers.each do |layer|
      next unless layer.to_StandardOpaqueMaterial.is_initialized
      material = layer.to_StandardOpaqueMaterial.get
      val += material.thickness * (material.specificHeat / 1000.0) * material.density
    end
    return val * area
  end

  def get_surface_area(model, construction)
    area = 0
    model.getSurfaces.each do |surface|
      next if surface.construction.get.to_LayeredConstruction.get != construction
      area += surface.grossArea
    end
    return area, construction.name.to_s
  end

  def get_foundation_area(model, construction)
    area = 0
    space = nil
    model.getFoundationKivas.each do |foundation_kiva|
      next unless foundation_kiva.footingWallConstruction.is_initialized
      next if foundation_kiva.footingWallConstruction.get.to_LayeredConstruction.get != construction
      foundation_kiva.surfaces.each do |surface|
        area += surface.grossArea
        space = surface.space.get
      end
    end
    unless space.nil?
      return area, "#{space.name} footing construction"
    end
    return area, nil
  end

  def get_sub_surface_area(model, construction)
    area = 0
    model.getSubSurfaces.each do |sub_surface|
      next if sub_surface.construction.get.to_LayeredConstruction.get != construction
      area += sub_surface.grossArea
    end
    return area, construction.name.to_s
  end

  def get_internal_mass_area(model, construction)
    area = 0
    model.getInternalMassDefinitions.each do |internal_mass_def|
      next if internal_mass_def.construction.get.to_LayeredConstruction.get != construction
      surface_area = internal_mass_def.surfaceArea
      next unless surface_area.is_initialized
      area += surface_area.get
    end
    return area, construction.name.to_s
  end

  def report_output(runner, name, vals, os_units, desired_units, percent_of_val=1.0)
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

end

# register the measure to be used by the application
ThermalCapacitanceReport.new.registerWithApplication