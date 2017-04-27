# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/measures/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"

# start the measure
class ProcessConstructionsWallsExteriorSteelStud < OpenStudio::Measure::ModelMeasure

  # human readable name
  def name
    return "Set Residential Walls - Steel Stud Construction"
  end

  # human readable description
  def description
    return "This measure assigns a steel stud construction to above-grade exterior walls adjacent to finished space or attic walls under insulated roofs."
  end

  # human readable description of modeling approach
  def modeler_description
    return "Calculates and assigns material layer properties of wood stud constructions for 1) above-grade walls between finished space and outside, and 2) above-grade walls between attics under insulated roofs and outside. If the walls have an existing construction, the layers (other than exterior finish, wall sheathing, and wall mass) are replaced. This measure is intended to be used in conjunction with Exterior Finish, Wall Sheathing, and Exterior Wall Mass measures."
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    #make a double argument for nominal R-value of nominal cavity insulation
    cavity_r = OpenStudio::Measure::OSArgument::makeDoubleArgument("cavity_r", true)
    cavity_r.setDisplayName("Cavity Insulation Nominal R-value")
    cavity_r.setUnits("hr-ft^2-R/Btu")
    cavity_r.setDescription("Refers to the R-value of the cavity insulation and not the overall R-value of the assembly.")
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

    #make a double argument for correction factor
    correction_factor = OpenStudio::Measure::OSArgument::makeDoubleArgument("correction_factor", true)
    correction_factor.setDisplayName("Correction Factor")
    correction_factor.setDescription("The parallel path correction factor, as specified in Table C402.1.4.1 of the 2015 IECC as well as ASHRAE Standard 90.1, is used to determine the thermal resistance of wall assemblies containing metal framing.")
    correction_factor.setDefaultValue(0.46)
    args << correction_factor

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
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
    ssWallCavityInsRvalueNominal = runner.getDoubleArgumentValue("cavity_r",user_arguments)
    ssWallInstallGrade = {"I"=>1, "II"=>2, "III"=>3}[runner.getStringArgumentValue("install_grade",user_arguments)]
    ssWallCavityDepth = runner.getDoubleArgumentValue("cavity_depth",user_arguments)
    ssWallCavityInsFillsCavity = runner.getBoolArgumentValue("ins_fills_cavity",user_arguments)  
    ssWallFramingFactor = runner.getDoubleArgumentValue("framing_factor",user_arguments)
    ssWallCorrectionFactor = runner.getDoubleArgumentValue("correction_factor",user_arguments)  
    
    # Validate inputs
    if ssWallCavityInsRvalueNominal < 0.0
        runner.registerError("Cavity Insulation Nominal R-value must be greater than or equal to 0.")
        return false
    end
    if ssWallCavityDepth <= 0.0
        runner.registerError("Cavity Depth must be greater than 0.")
        return false
    end
    if ssWallFramingFactor < 0.0 or ssWallFramingFactor >= 1.0
        runner.registerError("Framing Factor must be greater than or equal to 0 and less than 1.")
        return false
    end
    if ssWallCorrectionFactor < 0.0 or ssWallCorrectionFactor > 1.0
        runner.registerError("Correction Factor must be greater than or equal to 0 and less than or equal to 1.")
        return false
    end

    # Process the steel stud walls
    
    # Define materials
    eR = ssWallCavityInsRvalueNominal * ssWallCorrectionFactor # The effective R-value of the cavity insulation with steel stud framing
    if eR > 0
        if ssWallCavityInsFillsCavity
            # Insulation
            mat_cavity = Material.new(name=nil, thick_in=ssWallCavityDepth, mat_base=BaseMaterial.InsulationGenericDensepack, k_in=ssWallCavityDepth / eR)
        else
            # Insulation plus air gap when insulation thickness < cavity depth
            mat_cavity = Material.new(name=nil, thick_in=ssWallCavityDepth, mat_base=BaseMaterial.InsulationGenericDensepack, k_in=ssWallCavityDepth / (eR + Gas.AirGapRvalue))
        end
    else
        # Empty cavity
        mat_cavity = Material.AirCavityClosed(ssWallCavityDepth)
    end
    mat_gap = Material.AirCavityClosed(ssWallCavityDepth)
    
    # Set paths
    gapFactor = Construction.get_wall_gap_factor(ssWallInstallGrade, ssWallFramingFactor, ssWallCavityInsRvalueNominal)
    path_fracs = [1 - gapFactor, gapFactor]

    if not finished_surfaces.empty?
        # Define constructions
        fin_steel_stud_wall = Construction.new(path_fracs)
        fin_steel_stud_wall.add_layer(Material.AirFilmVertical, false)
        fin_steel_stud_wall.add_layer(Material.DefaultWallMass, false) # thermal mass added in separate measure
        fin_steel_stud_wall.add_layer([mat_cavity, mat_gap], true, "StudAndCavity")
        fin_steel_stud_wall.add_layer(Material.DefaultWallSheathing, false) # OSB added in separate measure
        fin_steel_stud_wall.add_layer(Material.DefaultExteriorFinish, false) # exterior finish added in separate measure
        fin_steel_stud_wall.add_layer(Material.AirFilmOutside, false)

        # Create and assign construction to surfaces
        if not fin_steel_stud_wall.create_and_assign_constructions(finished_surfaces, runner, model, name="ExtInsFinWall")
            return false
        end
    end

    if not unfinished_surfaces.empty?
        # Define constructions
        unfin_steel_stud_wall = Construction.new(path_fracs)
        unfin_steel_stud_wall.add_layer(Material.AirFilmVertical, false)
        unfin_steel_stud_wall.add_layer([mat_cavity, mat_gap], true, "StudAndCavity")
        unfin_steel_stud_wall.add_layer(Material.DefaultWallSheathing, false) # OSB added in separate measure
        unfin_steel_stud_wall.add_layer(Material.DefaultExteriorFinish, false) # exterior finish added in separate measure
        unfin_steel_stud_wall.add_layer(Material.AirFilmOutside, false)

        # Create and assign construction to surfaces
        if not unfin_steel_stud_wall.create_and_assign_constructions(unfinished_surfaces, runner, model, name="ExtInsFinWall")
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
            unit.setFeature(Constants.SizingInfoWallType(surface), "SteelStud")
            unit.setFeature(Constants.SizingInfoStudWallCavityRvalue(surface), ssWallCavityInsRvalueNominal)
        end
    end

    # Remove any constructions/materials that aren't used
    HelperMethods.remove_unused_constructions_and_materials(model, runner)
    
    return true

  end
  
end

# register the measure to be used by the application
ProcessConstructionsWallsExteriorSteelStud.new.registerWithApplication
