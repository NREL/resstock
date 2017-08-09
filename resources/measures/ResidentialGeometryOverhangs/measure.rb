# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/measures/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"

# start the measure
class CreateResidentialOverhangs < OpenStudio::Measure::ModelMeasure

  # human readable name
  def name
    return "Set Residential Overhangs"
  end

  # human readable description
  def description
    return "Sets presence/dimensions of overhangs for windows on the specified building facade(s).#{Constants.WorkflowDescription}"
  end

  # human readable description of modeling approach
  def modeler_description
    return "Creates overhang shading surfaces for windows on the specified building facade(s) and specified depth/offset. Any existing overhang shading surfaces are removed."
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    #make a choice argument for above-grade exterior walls adjacent to finished space or attic walls under insulated roofs
    sub_surfaces = get_window_sub_surfaces(model)
    sub_surfaces_args = OpenStudio::StringVector.new
    sub_surfaces_args << Constants.Auto
    sub_surfaces.each do |sub_surface|
      sub_surfaces_args << sub_surface.name.to_s
    end
    surface = OpenStudio::Measure::OSArgument::makeChoiceArgument("sub_surface", sub_surfaces_args, false)
    surface.setDisplayName("Sub Surface(s)")
    surface.setDescription("Select the sub surface(s) to assign overhangs.")
    surface.setDefaultValue(Constants.Auto)
    args << surface
    
    depth = OpenStudio::Measure::OSArgument::makeDoubleArgument("depth", true)
    depth.setDisplayName("Depth")
    depth.setUnits("ft")
    depth.setDescription("Depth of the overhang. The distance from the wall surface in the direction normal to the wall surface.")
    depth.setDefaultValue(2.0)
    args << depth

    offset = OpenStudio::Measure::OSArgument::makeDoubleArgument("offset", true)
    offset.setDisplayName("Offset")
    offset.setUnits("ft")
    offset.setDescription("Height of the overhangs above windows, relative to the top of the window framing.")
    offset.setDefaultValue(0.5)
    args << offset

    # TODO: addOverhang() sets WidthExtension=Offset*2.
    # width_extension = OpenStudio::Measure::OSArgument::makeDoubleArgument("width_extension", true)
    # width_extension.setDisplayName("Width Extension")
    # width_extension.setUnits("ft")
    # width_extension.setDescription("Length that the overhang extends beyond the window width, relative to the outside of the window framing.")
    # width_extension.setDefaultValue(1.0)
    # args << width_extension

    facade_bools = OpenStudio::StringVector.new
    facade_bools << "Front Facade"
    facade_bools << "Back Facade"
    facade_bools << "Left Facade"    
    facade_bools << "Right Facade"
    facade_bools.each do |facade_bool|
        facade = facade_bool.split(' ')[0]
        arg = OpenStudio::Measure::OSArgument::makeBoolArgument(facade_bool.downcase.gsub(" ", "_"), true)
        arg.setDisplayName(facade_bool)
        arg.setDescription("Specifies the presence of overhangs for windows on the #{facade.downcase} facade.")
        arg.setDefaultValue(true)
        args << arg
    end    

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    sub_surface_s = runner.getOptionalStringArgumentValue("sub_surface",user_arguments)
    if not sub_surface_s.is_initialized
      sub_surface_s = Constants.Auto
    else
      sub_surface_s = sub_surface_s.get
    end
    
    sub_surfaces = get_window_sub_surfaces(model)
    
    unless sub_surface_s == Constants.Auto
      sub_surfaces.delete_if { |sub_surface| sub_surface.name.to_s != sub_surface_s }
    end
    
    depth = OpenStudio.convert(runner.getDoubleArgumentValue("depth",user_arguments), "ft", "m").get
    offset = OpenStudio.convert(runner.getDoubleArgumentValue("offset",user_arguments), "ft", "m").get
    # width_extension = OpenStudio.convert(runner.getDoubleArgumentValue("width_extension",user_arguments), "ft", "m").get
    facade_bools = OpenStudio::StringVector.new
    facade_bools << "#{Constants.FacadeFront} Facade"
    facade_bools << "#{Constants.FacadeBack} Facade"
    facade_bools << "#{Constants.FacadeLeft} Facade"    
    facade_bools << "#{Constants.FacadeRight} Facade"
    facade_bools_hash = Hash.new
    facade_bools.each do |facade_bool|
        facade_bools_hash[facade_bool] = runner.getBoolArgumentValue(facade_bool.downcase.gsub(" ", "_"),user_arguments)
    end    

    # error checking
    if depth < 0
        runner.registerError("Overhang depth must be greater than or equal to 0.")
        return false
    end
    if offset < 0
        runner.registerError("Overhang offset must be greater than or equal to 0.")
        return false
    end
    # if width_extension < 0 
        # runner.registerError("Overhang width extension must be greater than or equal to 0.")
        # return false
    # end

    # Remove existing overhangs
    num_removed = 0    
    model.getShadingSurfaceGroups.each do |shading_surface_group|
      remove_group = false
      shading_surface_group.shadingSurfaces.each do |shading_surface|
        next unless shading_surface.name.to_s.downcase.include? "overhang"
        num_removed += 1
        remove_group = true
      end
      if remove_group
        shading_surface_group.remove
      end
    end
    if num_removed > 0
        runner.registerInfo("#{num_removed} overhang shading surfaces removed.")
    end
    
    # No overhangs to add? Exit here.
    if depth == 0
        if num_removed == 0
            runner.registerAsNotApplicable("No overhangs were added or removed.")
        end
        return true
    end
    
    windows_found = false
    
    sub_surfaces.each do |sub_surface|

        windows_found = true
        facade = Geometry.get_facade_for_surface(sub_surface)
        next if facade.nil?
        next if !facade_bools_hash["#{facade} Facade"]

        overhang = sub_surface.addOverhang(depth, offset)
        overhang.get.setName("#{sub_surface.name} - Overhang")
        
        runner.registerInfo("#{overhang.get.name.to_s} added.")

    end
    
    if not windows_found
      runner.registerAsNotApplicable("No windows found for adding overhangs.")
      return true
    end
    
    return true
    
  end
  
  def get_window_sub_surfaces(model)
    sub_surfaces = []
    model.getSubSurfaces.each do |sub_surface|
      next if not sub_surface.subSurfaceType.downcase.include? "window"
      sub_surfaces << sub_surface
    end
    return sub_surfaces  
  end
  
end

# register the measure to be used by the application
CreateResidentialOverhangs.new.registerWithApplication
