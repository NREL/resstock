#see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"

#start the measure
class ProcessConstructionsWallsExteriorDoubleWoodStud < OpenStudio::Measure::ModelMeasure

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Residential Walls - Double Wood Stud Construction"
  end
  
  def description
    return "This measure assigns a double wood stud construction to above-grade exterior walls adjacent to finished space or attic walls under insulated roofs.#{Constants.WorkflowDescription}"
  end
  
  def modeler_description
    return "Calculates and assigns material layer properties of wood stud constructions for 1) above-grade walls between finished space and outside, and 2) above-grade walls between attics under insulated roofs and outside. If the walls have an existing construction, the layers (other than exterior finish, wall sheathing, and wall mass) are replaced. This measure is intended to be used in conjunction with Exterior Finish, Wall Sheathing, and Exterior Wall Mass measures."
  end   
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    #make a double argument for nominal R-value of installed cavity insulation
    cavity_r = OpenStudio::Measure::OSArgument::makeDoubleArgument("cavity_r", true)
    cavity_r.setDisplayName("Cavity Insulation Nominal R-value")
    cavity_r.setUnits("hr-ft^2-R/Btu")
    cavity_r.setDescription("Refers to the R-value of the cavity insulation and not the overall R-value of the assembly.")
    cavity_r.setDefaultValue(33.0)
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

    #make a double argument for stud depth
    stud_depth = OpenStudio::Measure::OSArgument::makeDoubleArgument("stud_depth", true)
    stud_depth.setDisplayName("Stud Depth")
    stud_depth.setUnits("in")
    stud_depth.setDescription("Depth of the studs. 3.5\" for 2x4s, 5.5\" for 2x6s, etc. The total cavity depth of the double stud wall = (2 x stud depth) + gap depth.")
    stud_depth.setDefaultValue("3.5")
    args << stud_depth
    
    #make a double argument for gap depth
    gap_depth = OpenStudio::Measure::OSArgument::makeDoubleArgument("gap_depth", true)
    gap_depth.setDisplayName("Gap Depth")
    gap_depth.setUnits("in")
    gap_depth.setDescription("Depth of the gap between walls.")
    gap_depth.setDefaultValue(3.5)
    args << gap_depth    
    
    #make a double argument for framing factor
    framing_factor = OpenStudio::Measure::OSArgument::makeDoubleArgument("framing_factor", true)
    framing_factor.setDisplayName("Framing Factor")
    framing_factor.setUnits("frac")
    framing_factor.setDescription("The fraction of a wall assembly that is comprised of structural framing for the individual (inner and outer) stud walls.")
    framing_factor.setDefaultValue("0.22")
    args << framing_factor

    #make a double argument for framing spacing
    framing_spacing = OpenStudio::Measure::OSArgument::makeDoubleArgument("framing_spacing", true)
    framing_spacing.setDisplayName("Framing Spacing")
    framing_spacing.setUnits("in")
    framing_spacing.setDescription("The on-center spacing between framing in a wall assembly.")
    framing_spacing.setDefaultValue("24")
    args << framing_spacing

    #make a bool argument for staggering of studs
    is_staggered = OpenStudio::Measure::OSArgument::makeBoolArgument("is_staggered", true)
    is_staggered.setDisplayName("Staggered Studs")
    is_staggered.setDescription("Indicates that the double studs are aligned in a staggered fashion (as opposed to being center).") 
    is_staggered.setDefaultValue(false)
    args << is_staggered

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
    dsWallCavityInsRvalue = runner.getDoubleArgumentValue("cavity_r",user_arguments)
    dsWallInstallGrade = {"I"=>1, "II"=>2, "III"=>3}[runner.getStringArgumentValue("install_grade",user_arguments)]
    dsWallStudDepth = runner.getDoubleArgumentValue("stud_depth",user_arguments)
    dsWallGapDepth = runner.getDoubleArgumentValue("gap_depth",user_arguments)
    dsWallFramingFactor = runner.getDoubleArgumentValue("framing_factor",user_arguments)
    dsWallStudSpacing = runner.getDoubleArgumentValue("framing_spacing",user_arguments)
    dsWallIsStaggered = runner.getBoolArgumentValue("is_staggered",user_arguments)
    
    # Validate inputs
    if dsWallCavityInsRvalue <= 0.0
        runner.registerError("Cavity Insulation Nominal R-value must be greater than 0.")
        return false
    end
    if dsWallStudDepth <= 0.0
        runner.registerError("Stud Depth must be greater than 0.")
        return false
    end
    if dsWallGapDepth < 0.0
        runner.registerError("Gap Depth must be greater than or equal to 0.")
        return false
    end
    if dsWallFramingFactor < 0.0 or dsWallFramingFactor >= 1.0
        runner.registerError("Framing Factor must be greater than or equal to 0 and less than 1.")
        return false
    end
    if dsWallStudSpacing <= 0.0
        runner.registerError("Framing Spacing must be greater than 0.")
        return false
    end

    # Process the double wood stud walls
    
    # Define materials
    cavityDepth = 2.0 * dsWallStudDepth + dsWallGapDepth
    mat_ins_inner_outer = Material.new(name=nil, thick_in=dsWallStudDepth, mat_base=BaseMaterial.InsulationGenericDensepack, k_in=cavityDepth / dsWallCavityInsRvalue)
    mat_ins_middle = Material.new(name=nil, thick_in=dsWallGapDepth, mat_base=BaseMaterial.InsulationGenericDensepack, k_in=cavityDepth / dsWallCavityInsRvalue)
    mat_framing_inner_outer = Material.new(name=nil, thick_in=dsWallStudDepth, mat_base=BaseMaterial.Wood)
    mat_framing_middle = Material.new(name=nil, thick_in=dsWallGapDepth, mat_base=BaseMaterial.Wood)
    mat_stud = Material.new(name=nil, thick_in=dsWallStudDepth, mat_base=BaseMaterial.Wood)
    mat_gap_total = Material.AirCavityClosed(cavityDepth)
    mat_gap_inner_outer = Material.new(name=nil, thick_in=dsWallStudDepth, mat_base=nil, k_in=dsWallStudDepth / (mat_gap_total.rvalue * dsWallStudDepth / cavityDepth), rho=Gas.Air.rho, cp=Gas.Air.cp)
    mat_gap_middle = Material.new(name=nil, thick_in=dsWallGapDepth, mat_base=nil, k_in=dsWallGapDepth / (mat_gap_total.rvalue * dsWallGapDepth / cavityDepth), rho=Gas.Air.rho, cp=Gas.Air.cp)
    
    # Set paths
    stud_frac = 1.5 / dsWallStudSpacing
    dsWallMiscFramingFactor = dsWallFramingFactor - stud_frac
    if dsWallMiscFramingFactor < 0
        runner.registerError("Framing Factor (#{dsWallFramingFactor.to_s}) is less than the framing solely provided by the studs (#{stud_frac.to_s}).")
        return false
    end
    dsGapFactor = Construction.get_wall_gap_factor(dsWallInstallGrade, dsWallFramingFactor, dsWallCavityInsRvalue)
    path_fracs = [dsWallMiscFramingFactor, stud_frac, stud_frac, dsGapFactor, (1.0 - (2 * stud_frac + dsWallMiscFramingFactor + dsGapFactor))] 
    
    if not finished_surfaces.empty?
        # Define construction
        fin_double_stud_wall = Construction.new(path_fracs)
        fin_double_stud_wall.add_layer(Material.AirFilmVertical, false)
        fin_double_stud_wall.add_layer(Material.DefaultWallMass, false) # thermal mass added in separate measure
        fin_double_stud_wall.add_layer([mat_framing_inner_outer, mat_stud, mat_ins_inner_outer, mat_gap_inner_outer, mat_ins_inner_outer], true, "StudandCavityInner")
        if dsWallGapDepth > 0
            fin_double_stud_wall.add_layer([mat_framing_middle, mat_ins_middle, mat_ins_middle, mat_gap_middle, mat_ins_middle], true, "Cavity")
        end
        if dsWallIsStaggered
            fin_double_stud_wall.add_layer([mat_framing_inner_outer, mat_ins_inner_outer, mat_stud, mat_gap_inner_outer, mat_ins_inner_outer], true, "StudandCavityOuter")
        else
            fin_double_stud_wall.add_layer([mat_framing_inner_outer, mat_stud, mat_ins_inner_outer, mat_gap_inner_outer, mat_ins_inner_outer], true, "StudandCavityOuter")
        end
        fin_double_stud_wall.add_layer(Material.DefaultWallSheathing, false) # OSB added in separate measure
        fin_double_stud_wall.add_layer(Material.DefaultExteriorFinish, false) # exterior finish added in separate measure
        fin_double_stud_wall.add_layer(Material.AirFilmOutside, false)

        # Create and assign construction to surfaces
        if not fin_double_stud_wall.create_and_assign_constructions(finished_surfaces, runner, model, name="ExtInsFinWall")
            return false
        end
    end
    
    if not unfinished_surfaces.empty?
        # Define construction
        unfin_double_stud_wall = Construction.new(path_fracs)
        unfin_double_stud_wall.add_layer(Material.AirFilmVertical, false)
        unfin_double_stud_wall.add_layer([mat_framing_inner_outer, mat_stud, mat_ins_inner_outer, mat_gap_inner_outer, mat_ins_inner_outer], true, "StudandCavityInner")
        if dsWallGapDepth > 0
            unfin_double_stud_wall.add_layer([mat_framing_middle, mat_ins_middle, mat_ins_middle, mat_gap_middle, mat_ins_middle], true, "Cavity")
        end
        if dsWallIsStaggered
            unfin_double_stud_wall.add_layer([mat_framing_inner_outer, mat_ins_inner_outer, mat_stud, mat_gap_inner_outer, mat_ins_inner_outer], true, "StudandCavityOuter")
        else
            unfin_double_stud_wall.add_layer([mat_framing_inner_outer, mat_stud, mat_ins_inner_outer, mat_gap_inner_outer, mat_ins_inner_outer], true, "StudandCavityOuter")
        end
        unfin_double_stud_wall.add_layer(Material.DefaultWallSheathing, false) # OSB added in separate measure
        unfin_double_stud_wall.add_layer(Material.DefaultExteriorFinish, false) # exterior finish added in separate measure
        unfin_double_stud_wall.add_layer(Material.AirFilmOutside, false)

        # Create and assign construction to surfaces
        if not unfin_double_stud_wall.create_and_assign_constructions(unfinished_surfaces, runner, model, name="ExtInsFinWall")
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
            unit.setFeature(Constants.SizingInfoWallType(surface), "DoubleWoodStud")
        end
    end

    # Remove any constructions/materials that aren't used
    HelperMethods.remove_unused_constructions_and_materials(model, runner)

    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ProcessConstructionsWallsExteriorDoubleWoodStud.new.registerWithApplication