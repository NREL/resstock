# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/measures/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"
require "#{File.dirname(__FILE__)}/resources/unit_conversions"

# start the measure
class SetResidentialWindowArea < OpenStudio::Measure::ModelMeasure

  # human readable name
  def name
    return "Set Residential Window Area"
  end

  # human readable description
  def description
    return "Sets the window area for the building. Doors with glazing should be set as window area.#{Constants.WorkflowDescription}"
  end

  # human readable description of modeling approach
  def modeler_description
    return "Automatically creates and positions standard residential windows based on the specified window area on each building facade. Windows are only added to surfaces between finished space and outside. Any existing windows are removed."
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    #make a double argument for front wwr
    front_wwr = OpenStudio::Measure::OSArgument::makeDoubleArgument("front_wwr", true)
    front_wwr.setDisplayName("Front Window-to-Wall Ratio")
    front_wwr.setDescription("The ratio of window area to wall area for the building's front facade. Enter 0 if specifying Front Window Area instead.")
    front_wwr.setDefaultValue(0.18)
    args << front_wwr

    #make a double argument for back wwr
    back_wwr = OpenStudio::Measure::OSArgument::makeDoubleArgument("back_wwr", true)
    back_wwr.setDisplayName("Back Window-to-Wall Ratio")
    back_wwr.setDescription("The ratio of window area to wall area for the building's back facade. Enter 0 if specifying Back Window Area instead.")
    back_wwr.setDefaultValue(0.18)
    args << back_wwr

    #make a double argument for left wwr
    left_wwr = OpenStudio::Measure::OSArgument::makeDoubleArgument("left_wwr", true)
    left_wwr.setDisplayName("Left Window-to-Wall Ratio")
    left_wwr.setDescription("The ratio of window area to wall area for the building's left facade. Enter 0 if specifying Left Window Area instead.")
    left_wwr.setDefaultValue(0.18)
    args << left_wwr

    #make a double argument for right wwr
    right_wwr = OpenStudio::Measure::OSArgument::makeDoubleArgument("right_wwr", true)
    right_wwr.setDisplayName("Right Window-to-Wall Ratio")
    right_wwr.setDescription("The ratio of window area to wall area for the building's right facade. Enter 0 if specifying Right Window Area instead.")
    right_wwr.setDefaultValue(0.18)
    args << right_wwr

    #make a double argument for front area
    front_area = OpenStudio::Measure::OSArgument::makeDoubleArgument("front_area", true)
    front_area.setDisplayName("Front Window Area")
    front_area.setDescription("The amount of window area on the building's front facade. Enter 0 if specifying Front Window-to-Wall Ratio instead.")
    front_area.setDefaultValue(0)
    args << front_area

    #make a double argument for back area
    back_area = OpenStudio::Measure::OSArgument::makeDoubleArgument("back_area", true)
    back_area.setDisplayName("Back Window Area")
    back_area.setDescription("The amount of window area on the building's back facade. Enter 0 if specifying Back Window-to-Wall Ratio instead.")
    back_area.setDefaultValue(0)
    args << back_area

    #make a double argument for left area
    left_area = OpenStudio::Measure::OSArgument::makeDoubleArgument("left_area", true)
    left_area.setDisplayName("Left Window Area")
    left_area.setDescription("The amount of window area on the building's left facade. Enter 0 if specifying Left Window-to-Wall Ratio instead.")
    left_area.setDefaultValue(0)
    args << left_area

    #make a double argument for right area
    right_area = OpenStudio::Measure::OSArgument::makeDoubleArgument("right_area", true)
    right_area.setDisplayName("Right Window Area")
    right_area.setDescription("The amount of window area on the building's right facade. Enter 0 if specifying Right Window-to-Wall Ratio instead.")
    right_area.setDefaultValue(0)
    args << right_area

    #make a double argument for aspect ratio
    aspect_ratio = OpenStudio::Measure::OSArgument::makeDoubleArgument("aspect_ratio", true)
    aspect_ratio.setDisplayName("Window Aspect Ratio")
    aspect_ratio.setDescription("Ratio of window height to width.")
    aspect_ratio.setDefaultValue(1.333)
    args << aspect_ratio

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    facades = [Constants.FacadeFront, Constants.FacadeBack, Constants.FacadeLeft, Constants.FacadeRight]

    wwrs = {}
    wwrs[Constants.FacadeFront] = runner.getDoubleArgumentValue("front_wwr",user_arguments)
    wwrs[Constants.FacadeBack] = runner.getDoubleArgumentValue("back_wwr",user_arguments)
    wwrs[Constants.FacadeLeft] = runner.getDoubleArgumentValue("left_wwr",user_arguments)
    wwrs[Constants.FacadeRight] = runner.getDoubleArgumentValue("right_wwr",user_arguments)
    areas = {}
    areas[Constants.FacadeFront] = runner.getDoubleArgumentValue("front_area",user_arguments)
    areas[Constants.FacadeBack] = runner.getDoubleArgumentValue("back_area",user_arguments)
    areas[Constants.FacadeLeft] = runner.getDoubleArgumentValue("left_area",user_arguments)
    areas[Constants.FacadeRight] = runner.getDoubleArgumentValue("right_area",user_arguments)
    aspect_ratio = runner.getDoubleArgumentValue("aspect_ratio",user_arguments)

    # Remove existing windows and store surfaces that should get windows by facade
    surfaces = {Constants.FacadeFront=>[], Constants.FacadeBack=>[],
                Constants.FacadeLeft=>[], Constants.FacadeRight=>[]}
    constructions = {}
    warn_msg = nil
    Geometry.get_finished_spaces(model.getSpaces).each do |space|
        space.surfaces.each do |surface|
            next if not (surface.surfaceType.downcase == "wall" and surface.outsideBoundaryCondition.downcase == "outdoors")
            next if (90 - surface.tilt*180/Math::PI).abs > 0.01 # Not a vertical wall
            win_removed = false
            construction = nil
            surface.subSurfaces.each do |sub_surface|
                next if sub_surface.subSurfaceType.downcase != "fixedwindow"
                if sub_surface.construction.is_initialized
                  if not construction.nil? and construction != sub_surface.construction.get
                    warn_msg = "Multiple constructions found. An arbitrary construction may be assigned to new window(s)."
                  end
                  construction = sub_surface.construction.get
                end
                sub_surface.remove
                win_removed = true
            end
            if win_removed
                runner.registerInfo("Removed fixed window(s) from #{surface.name}.")
            end
            facade = Geometry.get_facade_for_surface(surface)
            next if facade.nil?
            surfaces[facade] << surface
            if not construction.nil? and not constructions.keys.include? facade
              constructions[facade] = construction
            end
        end
    end
    if not warn_msg.nil?
      runner.registerWarning(warn_msg)
    end
    
    # error checking
    facades.each do |facade|
      if wwrs[facade] > 0 and areas[facade] > 0
        runner.registerError("Both #{facade} window-to-wall ratio and #{facade} window area are specified.")
        return false
      elsif wwrs[facade] < 0 or wwrs[facade] >= 1
        runner.registerError("#{facade.capitalize} window-to-wall ratio must be greater than or equal to 0 and less than 1.")
        return false
      elsif areas[facade] < 0
        runner.registerError("#{facade.capitalize} window area must be greater than or equal to 0.")
        return false
      end
    end
    if aspect_ratio <= 0
      runner.registerError("Window Aspect Ratio must be greater than 0.")
      return false
    end
    
    # Split any surfaces that have doors so that we can ignore them when adding windows
    facades.each do |facade|
        surfaces_to_add = []
        surfaces[facade].each do |surface|
            next if surface.subSurfaces.size == 0
            new_surfaces = surface.splitSurfaceForSubSurfaces
            new_surfaces.each do |new_surface|
                next if new_surface.subSurfaces.size > 0
                surfaces_to_add << new_surface
            end
        end
        surfaces_to_add.each do |surface_to_add|
            surfaces[facade] << surface_to_add
        end
    end
    
    # Default assumptions
    min_single_window_area = 5.333 # sqft
    max_single_window_area = 12.0 # sqft
    window_gap_y = 1.0 # ft; distance from top of wall
    window_gap_x = 0.2 # ft; distance between windows in a two-window group
    min_wall_height_for_window = Math.sqrt(max_single_window_area * aspect_ratio) + window_gap_y * 1.05 # allow some wall area above/below
    min_window_width = Math.sqrt(min_single_window_area / aspect_ratio) * 1.05 # allow some wall area to the left/right
    
    # Calculate available area for each wall, facade
    surface_avail_area = {}
    facade_avail_area = {}
    facades.each do |facade|
        facade_avail_area[facade] = 0
        surfaces[facade].each do |surface|
            if not surface_avail_area.include? surface
                surface_avail_area[surface] = 0
            end
            next if surface.subSurfaces.size > 0
            area = get_wall_area_for_windows(surface, min_wall_height_for_window, min_window_width, runner)
            surface_avail_area[surface] += area
            facade_avail_area[facade] += area
        end
    end
    
    surface_window_area = {}
    target_facade_areas = {}
    facades.each do |facade|
    
        # Initialize
        surfaces[facade].each do |surface|
            surface_window_area[surface] = 0
        end
    
        # Calculate target window area for this facade
        target_facade_areas[facade] = 0.0
        if wwrs[facade] > 0
          wall_area = 0
          surfaces[facade].each do |surface|
              wall_area += UnitConversions.convert(surface.grossArea, "m^2", "ft^2")
          end
          target_facade_areas[facade] = wall_area * wwrs[facade]
        else
          target_facade_areas[facade] = areas[facade]
        end
        
        next if target_facade_areas[facade] == 0
        
        if target_facade_areas[facade] < min_single_window_area
            # If the total window area for the facade is less than the minimum window area,
            # set all of the window area to the surface with the greatest available wall area
            surface = my_hash.max_by{|k,v| v}[0]
            surface_window_area[surface] = target_facade_areas[facade]
            next
        end
        
        # Initial guess for wall of this facade
        surfaces[facade].each do |surface|
            surface_window_area[surface] = surface_avail_area[surface] / facade_avail_area[facade] * target_facade_areas[facade]
        end
        
        # If window area for a surface is less than the minimum window area, 
        # set the window area to zero and proportionally redistribute to the
        # other surfaces.
        surfaces[facade].each_with_index do |surface, surface_num|
            next if surface_window_area[surface] >= min_single_window_area
            
            removed_window_area = surface_window_area[surface]
            surface_window_area[surface] = 0
            
            # Future surfaces are those that have not yet been compared to min_single_window_area
            future_surfaces_area = 0
            surfaces[facade].each_with_index do |future_surface, future_surface_num|
                next if future_surface_num <= surface_num
                future_surfaces_area += surface_avail_area[future_surface]
            end
            next if future_surfaces_area == 0
            
            surfaces[facade].each_with_index do |future_surface, future_surface_num|
                next if future_surface_num <= surface_num
                surface_window_area[future_surface] += removed_window_area * surface_window_area[future_surface] / future_surfaces_area
            end
        end
        
        # Because the above process is calculated based on the order of surfaces, it's possible
        # that we have less area for this facade than we should. If so, redistribute proportionally
        # to all surfaces that have window area.
        sum_window_area = 0
        surfaces[facade].each do |surface|
            sum_window_area += surface_window_area[surface]
        end
        next if sum_window_area == 0
        surfaces[facade].each do |surface|
            surface_window_area[surface] += surface_window_area[surface] / sum_window_area * (target_facade_areas[facade] - sum_window_area)
        end
    
    end
    
    tot_win_area = 0
    facades.each do |facade|
        facade_win_area = 0
        surfaces[facade].each do |surface|
            next if surface_window_area[surface] == 0
            if not add_windows_to_wall(surface, surface_window_area[surface], window_gap_y, window_gap_x, aspect_ratio, max_single_window_area, facade, constructions, model, runner)
                return false
            end
            tot_win_area += surface_window_area[surface]
            facade_win_area += surface_window_area[surface]
        end
        if (facade_win_area - target_facade_areas[facade]).abs > 0.1
            runner.registerWarning("Unable to assign appropriate window area for #{facade} facade.")
        end
    end
    
    if tot_win_area == 0
      runner.registerFinalCondition("No windows added.")
      return true
    end
    
    runner.registerFinalCondition("The building has been assigned #{tot_win_area.round(1)} ft^2 total window area.")
    
    return true

  end
  
  def get_wall_area_for_windows(surface, min_wall_height_for_window, min_window_width, runner)
    # Only allow on gable and rectangular walls
    if not (Geometry.is_rectangular_wall(surface) or Geometry.is_gable_wall(surface))
        return 0.0
    end
  
    # Can't fit the smallest window?
    if Geometry.get_surface_length(surface) < min_window_width
        return 0.0
    end
    
    # Wall too short?
    if min_wall_height_for_window > Geometry.get_surface_height(surface)
        return 0.0
    end
    
    # Gable too short?
    # TODO: super crude safety factor of 1.5
    if Geometry.is_gable_wall(surface) and min_wall_height_for_window > Geometry.get_surface_height(surface)/1.5
        return 0.0
    end

    return UnitConversions.convert(surface.grossArea, "m^2", "ft^2")
  end
  
  def add_windows_to_wall(surface, window_area, window_gap_y, window_gap_x, aspect_ratio, max_single_window_area, facade, constructions, model, runner)
    wall_width = Geometry.get_surface_length(surface)
    wall_height = Geometry.get_surface_height(surface)
    
    # Calculate number of windows needed
    num_windows = (window_area / max_single_window_area).ceil
    num_window_groups = (num_windows / 2.0).ceil
    num_window_gaps = num_window_groups
    if num_windows % 2 == 1
        num_window_gaps -= 1
    end
    window_width = Math.sqrt((window_area / num_windows.to_f) / aspect_ratio)
    window_height = (window_area / num_windows.to_f) / window_width
    width_for_windows = window_width * num_windows.to_f + window_gap_x * num_window_gaps.to_f
    if width_for_windows > wall_width
        runner.registerError("Could not fit windows on #{surface.name.to_s}.")
        return false
    end
    
    # Position window from top of surface
    win_top = wall_height - window_gap_y
    if Geometry.is_gable_wall(surface)
        # For gable surfaces, position windows from bottom of surface so they fit
        win_top = window_height + window_gap_y
    end
    
    # Groups of two windows
    win_num = 0
    for i in (1..num_window_groups)
        
        # Center vertex for group
        group_cx = wall_width * i / (num_window_groups+1).to_f
        group_cy = win_top - window_height / 2.0
        
        if not (i == num_window_groups and num_windows % 2 == 1)
            # Two windows in group
            win_num += 1
            add_window_to_wall(surface, window_width, window_height, group_cx - window_width/2.0 - window_gap_x/2.0, group_cy, win_num, facade, constructions, model, runner)
            win_num += 1
            add_window_to_wall(surface, window_width, window_height, group_cx + window_width/2.0 + window_gap_x/2.0, group_cy, win_num, facade, constructions, model, runner)
        else
            # One window in group
            win_num += 1
            add_window_to_wall(surface, window_width, window_height, group_cx, group_cy, win_num, facade, constructions, model, runner)
        end
    end
    runner.registerInfo("Added #{num_windows.to_s} window(s), totaling #{window_area.round(1).to_s} ft^2, to #{surface.name}.")
    return true
  end
  
  def add_window_to_wall(surface, win_width, win_height, win_center_x, win_center_y, win_num, facade, constructions, model, runner)
    
    # Create window vertices in relative coordinates, ft
    upperleft = [win_center_x - win_width/2.0, win_center_y + win_height/2.0]
    upperright = [win_center_x + win_width/2.0, win_center_y + win_height/2.0]
    lowerright = [win_center_x + win_width/2.0, win_center_y - win_height/2.0]
    lowerleft = [win_center_x - win_width/2.0, win_center_y - win_height/2.0]
    
    # Convert to 3D geometry; assign to surface
    window_polygon = OpenStudio::Point3dVector.new
    if facade == Constants.FacadeFront
        multx = 1
        multy = 0
    elsif facade == Constants.FacadeBack
        multx = -1
        multy = 0
    elsif facade == Constants.FacadeLeft
        multx = 0
        multy = -1
    elsif facade == Constants.FacadeRight
        multx = 0
        multy = 1
    end
    if facade == Constants.FacadeBack or facade == Constants.FacadeLeft
        leftx = Geometry.getSurfaceXValues([surface]).max
        lefty = Geometry.getSurfaceYValues([surface]).max
    else
        leftx = Geometry.getSurfaceXValues([surface]).min
        lefty = Geometry.getSurfaceYValues([surface]).min
    end
    bottomz = Geometry.getSurfaceZValues([surface]).min
    [upperleft, lowerleft, lowerright, upperright ].each do |coord|
        newx = UnitConversions.convert(leftx + multx * coord[0], "ft", "m")
        newy = UnitConversions.convert(lefty + multy * coord[0], "ft", "m")
        newz = UnitConversions.convert(bottomz + coord[1], "ft", "m")
        window_vertex = OpenStudio::Point3d.new(newx, newy, newz)
        window_polygon << window_vertex
    end
    sub_surface = OpenStudio::Model::SubSurface.new(window_polygon, model)
    sub_surface.setName("#{surface.name} - Window #{win_num.to_s}")
    sub_surface.setSurface(surface)
    sub_surface.setSubSurfaceType("FixedWindow")
    if not constructions[facade].nil?
      sub_surface.setConstruction(constructions[facade])
    end
    
  end
  
end

# register the measure to be used by the application
SetResidentialWindowArea.new.registerWithApplication
