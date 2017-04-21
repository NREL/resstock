#see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"

#start the measure
class ProcessConstructionsWallsExteriorWoodStud < OpenStudio::Measure::ModelMeasure
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Residential Walls - Wood Stud Construction"
  end
  
  def description
    return "This measure assigns a wood stud construction to above-grade exterior walls adjacent to finished space or attic walls under insulated roofs."
  end
  
  def modeler_description
    return "Calculates and assigns material layer properties of wood stud constructions for 1) above-grade walls between finished space and outside, and 2) above-grade walls between attics under insulated roofs and outside. If the walls have an existing construction, the layers (other than exterior finish, wall sheathing, and wall mass) are replaced. This measure is intended to be used in conjunction with Exterior Finish, Wall Sheathing, and Exterior Wall Mass measures."
  end  
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    #make a double argument for R-value of installed cavity insulation
    cavity_r = OpenStudio::Measure::OSArgument::makeDoubleArgument("cavity_r", true)
    cavity_r.setDisplayName("Cavity Insulation Installed R-value")
    cavity_r.setUnits("hr-ft^2-R/Btu")
    cavity_r.setDescription("Refers to the R-value of the cavity insulation and not the overall R-value of the assembly. If batt insulation must be compressed to fit within the cavity (e.g., R19 in a 5.5\" 2x6 cavity), use an R-value that accounts for this effect (see HUD Mobile Home Construction and Safety Standards 3280.509 for reference).")
    cavity_r.setDefaultValue(13.0)
    args << cavity_r

    #make a choice argument for wall cavity insulation installation grade
    installgrade_display_names = OpenStudio::StringVector.new
    installgrade_display_names << "I"
    installgrade_display_names << "II"
    installgrade_display_names << "III"
    install_grade = OpenStudio::Measure::OSArgument::makeChoiceArgument("install_grade", installgrade_display_names, true)
    install_grade.setDisplayName("Cavity Install Grade")
    install_grade.setDescription("Installation grade as defined by RESNET standard. 5% of the cavity is considered missing insulation for Grade 3, 2% for Grade 2, and 0% for Grade 1.")
    install_grade.setDefaultValue("I")
    args << install_grade

    #make a double argument for wall cavity depth
    cavity_depth = OpenStudio::Measure::OSArgument::makeDoubleArgument("cavity_depth", true)
    cavity_depth.setDisplayName("Cavity Depth")
    cavity_depth.setUnits("in")
    cavity_depth.setDescription("Depth of the stud cavity. 3.5\" for 2x4s, 5.5\" for 2x6s, etc.")
    cavity_depth.setDefaultValue("3.5")
    args << cavity_depth
    
    #make a bool argument for whether the cavity insulation fills the cavity
    ins_fills_cavity = OpenStudio::Measure::OSArgument::makeBoolArgument("ins_fills_cavity", true)
    ins_fills_cavity.setDisplayName("Insulation Fills Cavity")
    ins_fills_cavity.setDescription("When the insulation does not completely fill the depth of the cavity, air film resistances are added to the insulation R-value.")
    ins_fills_cavity.setDefaultValue(true)
    args << ins_fills_cavity

    #make a double argument for framing factor
    framing_factor = OpenStudio::Measure::OSArgument::makeDoubleArgument("framing_factor", true)
    framing_factor.setDisplayName("Framing Factor")
    framing_factor.setUnits("frac")
    framing_factor.setDescription("The fraction of a wall assembly that is comprised of structural framing.")
    framing_factor.setDefaultValue("0.25")
    args << framing_factor
        
    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end
    
    finished_surfaces = []
    unfinished_surfaces = []
    model.getSpaces.each do |space|
        # Wall between finished space and outdoors
        if Geometry.space_is_finished(space) and Geometry.space_is_above_grade(space)
            space.surfaces.each do |surface|
                next if surface.surfaceType.downcase != "wall" or surface.outsideBoundaryCondition.downcase != "outdoors"
                finished_surfaces << surface
            end
        # Attic wall under an insulated roof
        elsif Geometry.is_unfinished_attic(space)
            attic_roof_r = Construction.get_space_r_value(runner, space, "roofceiling")
            next if attic_roof_r.nil? or attic_roof_r <= 5 # assume uninsulated if <= R-5 assembly
            space.surfaces.each do |surface|
                next if surface.surfaceType.downcase != "wall" or surface.outsideBoundaryCondition.downcase != "outdoors"
                unfinished_surfaces << surface
            end
        end
    end
    
    # Continue if no applicable surfaces
    if finished_surfaces.empty? and unfinished_surfaces.empty?
      runner.registerAsNotApplicable("Measure not applied because no applicable surfaces were found.")
      return true
    end     
    
    # Get inputs
    wsWallCavityInsRvalueInstalled = runner.getDoubleArgumentValue("cavity_r",user_arguments)
    wsWallInstallGrade = {"I"=>1, "II"=>2, "III"=>3}[runner.getStringArgumentValue("install_grade",user_arguments)]
    wsWallCavityDepth = runner.getDoubleArgumentValue("cavity_depth",user_arguments)
    wsWallCavityInsFillsCavity = runner.getBoolArgumentValue("ins_fills_cavity",user_arguments)
    wsWallFramingFactor = runner.getDoubleArgumentValue("framing_factor",user_arguments)
    
    # Validate inputs
    if wsWallCavityInsRvalueInstalled < 0.0
        runner.registerError("Cavity Insulation Installed R-value must be greater than or equal to 0.")
        return false
    end
    if wsWallCavityDepth <= 0.0
        runner.registerError("Cavity Depth must be greater than 0.")
        return false
    end
    if wsWallFramingFactor < 0.0 or wsWallFramingFactor >= 1.0
        runner.registerError("Framing Factor must be greater than or equal to 0 and less than 1.")
        return false
    end

    # Process the wood stud walls

    # Define materials
    if wsWallCavityInsRvalueInstalled > 0
        if wsWallCavityInsFillsCavity
            # Insulation
            mat_cavity = Material.new(name=nil, thick_in=wsWallCavityDepth, mat_base=BaseMaterial.InsulationGenericDensepack, k_in=wsWallCavityDepth / wsWallCavityInsRvalueInstalled)
        else
            # Insulation plus air gap when insulation thickness < cavity depth
            mat_cavity = Material.new(name=nil, thick_in=wsWallCavityDepth, mat_base=BaseMaterial.InsulationGenericDensepack, k_in=wsWallCavityDepth / (wsWallCavityInsRvalueInstalled + Gas.AirGapRvalue))
        end
    else
        # Empty cavity
        mat_cavity = Material.AirCavityClosed(wsWallCavityDepth)
    end
    mat_framing = Material.new(name=nil, thick_in=wsWallCavityDepth, mat_base=BaseMaterial.Wood)
    mat_gap = Material.AirCavityClosed(wsWallCavityDepth)

    # Set paths
    gapFactor = Construction.get_wall_gap_factor(wsWallInstallGrade, wsWallFramingFactor, wsWallCavityInsRvalueInstalled)
    path_fracs = [wsWallFramingFactor, 1 - wsWallFramingFactor - gapFactor, gapFactor]
    
    
    if not finished_surfaces.empty?
        # Define construction
        fin_wood_stud_wall = Construction.new(path_fracs)
        fin_wood_stud_wall.add_layer(Material.AirFilmVertical, false)
        fin_wood_stud_wall.add_layer(Material.DefaultWallMass, false) # thermal mass added in separate measure
        fin_wood_stud_wall.add_layer([mat_framing, mat_cavity, mat_gap], true, "StudAndCavity")       
        fin_wood_stud_wall.add_layer(Material.DefaultWallSheathing, false) # OSB added in separate measure
        fin_wood_stud_wall.add_layer(Material.DefaultExteriorFinish, false) # exterior finish added in separate measure
        fin_wood_stud_wall.add_layer(Material.AirFilmOutside, false)

        # Create and assign construction to surfaces
        if not fin_wood_stud_wall.create_and_assign_constructions(finished_surfaces, runner, model, name="ExtInsFinWall")
            return false
        end
    end
    
    if not unfinished_surfaces.empty?
        # Define construction
        unfin_wood_stud_wall = Construction.new(path_fracs)
        unfin_wood_stud_wall.add_layer(Material.AirFilmVertical, false)
        unfin_wood_stud_wall.add_layer([mat_framing, mat_cavity, mat_gap], true, "StudAndCavity")       
        unfin_wood_stud_wall.add_layer(Material.DefaultWallSheathing, false) # OSB added in separate measure
        unfin_wood_stud_wall.add_layer(Material.DefaultExteriorFinish, false) # exterior finish added in separate measure
        unfin_wood_stud_wall.add_layer(Material.AirFilmOutside, false)

        # Create and assign construction to surfaces
        if not unfin_wood_stud_wall.create_and_assign_constructions(unfinished_surfaces, runner, model, name="ExtInsUnfinWall")
            return false
        end
    end
    
    # Store info for HVAC Sizing measure
    units = Geometry.get_building_units(model, runner)
    if units.nil?
        return false
    end
    (finished_surfaces + unfinished_surfaces).each do |surface|
        units.each do |unit|
            next if not unit.spaces.include?(surface.space.get)
            unit.setFeature(Constants.SizingInfoWallType(surface), "WoodStud")
            unit.setFeature(Constants.SizingInfoWoodStudWallCavityRvalue(surface), wsWallCavityInsRvalueInstalled)
        end
    end

    # Remove any constructions/materials that aren't used
    HelperMethods.remove_unused_constructions_and_materials(model, runner)

    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ProcessConstructionsWallsExteriorWoodStud.new.registerWithApplication