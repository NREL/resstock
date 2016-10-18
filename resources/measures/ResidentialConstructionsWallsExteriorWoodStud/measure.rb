#see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"

#start the measure
class ProcessConstructionsWallsExteriorWoodStud < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Residential Walls - Wood Stud Construction"
  end
  
  def description
    return "This measure assigns a wood stud construction to above-grade exterior walls adjacent to finished space."
  end
  
  def modeler_description
    return "Calculates and assigns material layer properties of wood stud constructions for above-grade walls between finished space and outside. If the walls have an existing construction, the layers (other than exterior finish, wall sheathing, and wall mass) are replaced. This measure is intended to be used in conjunction with Exterior Finish, Wall Sheathing, and Exterior Wall Mass measures."
  end  
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make a double argument for R-value of installed cavity insulation
    userdefined_instcavr = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("cavity_r", true)
    userdefined_instcavr.setDisplayName("Cavity Insulation Installed R-value")
    userdefined_instcavr.setUnits("hr-ft^2-R/Btu")
    userdefined_instcavr.setDescription("Refers to the R-value of the cavity insulation and not the overall R-value of the assembly. If batt insulation must be compressed to fit within the cavity (e.g., R19 in a 5.5\" 2x6 cavity), use an R-value that accounts for this effect (see HUD Mobile Home Construction and Safety Standards 3280.509 for reference).")
    userdefined_instcavr.setDefaultValue(13.0)
    args << userdefined_instcavr

    #make a choice argument for model objects
    installgrade_display_names = OpenStudio::StringVector.new
    installgrade_display_names << "I"
    installgrade_display_names << "II"
    installgrade_display_names << "III"
    
    #make a choice argument for wall cavity insulation installation grade
    selected_installgrade = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("install_grade", installgrade_display_names, true)
    selected_installgrade.setDisplayName("Cavity Install Grade")
    selected_installgrade.setDescription("Installation grade as defined by RESNET standard. 5% of the cavity is considered missing insulation for Grade 3, 2% for Grade 2, and 0% for Grade 1.")
    selected_installgrade.setDefaultValue("I")
    args << selected_installgrade

    #make a double argument for wall cavity depth
    selected_cavdepth = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("cavity_depth", true)
    selected_cavdepth.setDisplayName("Cavity Depth")
    selected_cavdepth.setUnits("in")
    selected_cavdepth.setDescription("Depth of the stud cavity. 3.5\" for 2x4s, 5.5\" for 2x6s, etc.")
    selected_cavdepth.setDefaultValue("3.5")
    args << selected_cavdepth
    
    #make a bool argument for whether the cavity insulation fills the cavity
    selected_insfills = OpenStudio::Ruleset::OSArgument::makeBoolArgument("ins_fills_cavity", true)
    selected_insfills.setDisplayName("Insulation Fills Cavity")
    selected_insfills.setDescription("When the insulation does not completely fill the depth of the cavity, air film resistances are added to the insulation R-value.")
    selected_insfills.setDefaultValue(true)
    args << selected_insfills

    #make a double argument for framing factor
    selected_ffactor = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("framing_factor", true)
    selected_ffactor.setDisplayName("Framing Factor")
    selected_ffactor.setUnits("frac")
    selected_ffactor.setDescription("The fraction of a wall assembly that is comprised of structural framing.")
    selected_ffactor.setDefaultValue("0.25")
    args << selected_ffactor
        
    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end
    
    # Above-grade wall between finished space and outdoors
    surfaces = []
    model.getSpaces.each do |space|
        next if Geometry.space_is_unfinished(space)
        next if Geometry.space_is_below_grade(space)
        space.surfaces.each do |surface|
            if surface.surfaceType.downcase == "wall" and surface.outsideBoundaryCondition.downcase == "outdoors"
                surfaces << surface
            end
        end
    end
    
    # Continue if no applicable surfaces
    if surfaces.empty?
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
    
    # Define construction
    wood_stud_wall = Construction.new(path_fracs)
    wood_stud_wall.add_layer(Material.AirFilmVertical, false)
    wood_stud_wall.add_layer(Material.DefaultWallMass, false) # thermal mass added in separate measure
    wood_stud_wall.add_layer([mat_framing, mat_cavity, mat_gap], true, "StudAndCavity")       
    wood_stud_wall.add_layer(Material.DefaultWallSheathing, false) # OSB added in separate measure
    wood_stud_wall.add_layer(Material.DefaultExteriorFinish, false) # exterior finish added in separate measure
    wood_stud_wall.add_layer(Material.AirFilmOutside, false)

    # Create and assign construction to surfaces
    if not wood_stud_wall.create_and_assign_constructions(surfaces, runner, model, name="ExtInsFinWall")
        return false
    end

    # Remove any constructions/materials that aren't used
    HelperMethods.remove_unused_constructions_and_materials(model, runner)

    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ProcessConstructionsWallsExteriorWoodStud.new.registerWithApplication