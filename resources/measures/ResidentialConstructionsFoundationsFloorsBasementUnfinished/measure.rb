#see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"

#start the measure
class ProcessConstructionsFoundationsFloorsBasementUnfinished < OpenStudio::Measure::ModelMeasure
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Residential Foundations/Floors - Unfinished Basement Constructions"
  end
  
  def description
    return "This measure assigns constructions to the unfinished basement ceilings, walls, and floors."
  end
  
  def modeler_description
    return "Calculates and assigns material layer properties of constructions for: 1) ceilings above below-grade unfinished space, 2) walls between below-grade unfinished space and ground, and 3) floors below below-grade unfinished space. Below-grade spaces are assumed to be basements (and not crawlspaces) if the space height is greater than or equal to #{Constants.MinimumBasementHeight.to_s} ft."
  end  
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    #make a double argument for wall insulation height
    wall_ins_height = OpenStudio::Measure::OSArgument::makeDoubleArgument("wall_ins_height", true)
    wall_ins_height.setDisplayName("Wall Insulation Height")
	wall_ins_height.setUnits("ft")
	wall_ins_height.setDescription("Height of the insulation on the basement wall.")
    wall_ins_height.setDefaultValue(8)
    args << wall_ins_height

    #make a double argument for wall cavity R-value
    wall_cavity_r = OpenStudio::Measure::OSArgument::makeDoubleArgument("wall_cavity_r", true)
    wall_cavity_r.setDisplayName("Wall Cavity Insulation Installed R-value")
	wall_cavity_r.setUnits("h-ft^2-R/Btu")
	wall_cavity_r.setDescription("Refers to the R-value of the cavity insulation as installed and not the overall R-value of the assembly. If batt insulation must be compressed to fit within the cavity (e.g. R19 in a 5.5\" 2x6 cavity), use an R-value that accounts for this effect (see HUD Mobile Home Construction and Safety Standards 3280.509 for reference).")
    wall_cavity_r.setDefaultValue(0)
    args << wall_cavity_r

    #make a choice argument for model objects
    installgrade_display_names = OpenStudio::StringVector.new
    installgrade_display_names << "I"
    installgrade_display_names << "II"
    installgrade_display_names << "III"

	#make a choice argument for wall cavity insulation installation grade
	wall_cavity_grade = OpenStudio::Measure::OSArgument::makeChoiceArgument("wall_cavity_grade", installgrade_display_names, true)
	wall_cavity_grade.setDisplayName("Wall Cavity Install Grade")
	wall_cavity_grade.setDescription("Installation grade as defined by RESNET standard. 5% of the cavity is considered missing insulation for Grade 3, 2% for Grade 2, and 0% for Grade 1.")
    wall_cavity_grade.setDefaultValue("I")
	args << wall_cavity_grade

    #make a double argument for wall cavity depth
    wall_cavity_depth = OpenStudio::Measure::OSArgument::makeDoubleArgument("wall_cavity_depth", true)
    wall_cavity_depth.setDisplayName("Wall Cavity Depth")
	wall_cavity_depth.setUnits("in")
	wall_cavity_depth.setDescription("Depth of the stud cavity. 3.5\" for 2x4s, 5.5\" for 2x6s, etc.")
    wall_cavity_depth.setDefaultValue(0)
    args << wall_cavity_depth

	#make a bool argument for whether the cavity insulation fills the wall cavity
	wall_cavity_insfills = OpenStudio::Measure::OSArgument::makeBoolArgument("wall_cavity_insfills", true)
	wall_cavity_insfills.setDisplayName("Wall Insulation Fills Cavity")
	wall_cavity_insfills.setDescription("When the insulation does not completely fill the depth of the cavity, air film resistances are added to the insulation R-value.")
    wall_cavity_insfills.setDefaultValue(false)
	args << wall_cavity_insfills

    #make a double argument for wall framing factor
    wall_ff = OpenStudio::Measure::OSArgument::makeDoubleArgument("wall_ff", true)
    wall_ff.setDisplayName("Wall Framing Factor")
	wall_ff.setUnits("frac")
	wall_ff.setDescription("The fraction of a basement wall assembly that is comprised of structural framing.")
    wall_ff.setDefaultValue(0)
    args << wall_ff
    
    #make a double argument for wall continuous insulation R-value
    wall_rigid_r = OpenStudio::Measure::OSArgument::makeDoubleArgument("wall_rigid_r", true)
    wall_rigid_r.setDisplayName("Wall Continuous Insulation Nominal R-value")
	wall_rigid_r.setUnits("hr-ft^2-R/Btu")
	wall_rigid_r.setDescription("The R-value of the continuous insulation.")
    wall_rigid_r.setDefaultValue(10.0)
    args << wall_rigid_r

    #make a double argument for wall continuous insulation thickness
    wall_rigid_thick_in = OpenStudio::Measure::OSArgument::makeDoubleArgument("wall_rigid_thick_in", true)
    wall_rigid_thick_in.setDisplayName("Wall Continuous Insulation Thickness")
	wall_rigid_thick_in.setUnits("in")
	wall_rigid_thick_in.setDescription("The thickness of the continuous insulation.")
    wall_rigid_thick_in.setDefaultValue(2.0)
    args << wall_rigid_thick_in

    #make a double argument for ceiling cavity R-value
    ceil_cavity_r = OpenStudio::Measure::OSArgument::makeDoubleArgument("ceil_cavity_r", true)
    ceil_cavity_r.setDisplayName("Ceiling Cavity Insulation Nominal R-value")
	ceil_cavity_r.setUnits("h-ft^2-R/Btu")
	ceil_cavity_r.setDescription("Refers to the R-value of the cavity insulation and not the overall R-value of the assembly.")
    ceil_cavity_r.setDefaultValue(0)
    args << ceil_cavity_r

	#make a choice argument for ceiling cavity insulation installation grade
	ceil_cavity_grade = OpenStudio::Measure::OSArgument::makeChoiceArgument("ceil_cavity_grade", installgrade_display_names, true)
	ceil_cavity_grade.setDisplayName("Ceiling Cavity Install Grade")
	ceil_cavity_grade.setDescription("Installation grade as defined by RESNET standard. 5% of the cavity is considered missing insulation for Grade 3, 2% for Grade 2, and 0% for Grade 1.")
    ceil_cavity_grade.setDefaultValue("I")
	args << ceil_cavity_grade

	#make a choice argument for ceiling framing factor
	ceil_ff = OpenStudio::Measure::OSArgument::makeDoubleArgument("ceil_ff", true)
    ceil_ff.setDisplayName("Ceiling Framing Factor")
	ceil_ff.setUnits("frac")
	ceil_ff.setDescription("Fraction of ceiling that is framing.")
    ceil_ff.setDefaultValue(0.13)
	args << ceil_ff

	#make a choice argument for ceiling joist height
	ceil_joist_height = OpenStudio::Measure::OSArgument::makeDoubleArgument("ceil_joist_height", true)
	ceil_joist_height.setDisplayName("Ceiling Joist Height")
	ceil_joist_height.setUnits("in")
	ceil_joist_height.setDescription("Height of the joist member.")
	ceil_joist_height.setDefaultValue("9.25")
	args << ceil_joist_height	
    
    #make a string argument for exposed perimeter
    exposed_perim = OpenStudio::Measure::OSArgument::makeStringArgument("exposed_perim", true)
	exposed_perim.setDisplayName("Exposed Perimeter")
	exposed_perim.setUnits("ft")
	exposed_perim.setDescription("Total length of the basement's perimeter that is on the exterior of the building's footprint.")
	exposed_perim.setDefaultValue(Constants.Auto)
	args << exposed_perim	
    
    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    wall_surfaces = []
    floor_surfaces = []
    ceiling_surfaces = []
    spaces = Geometry.get_unfinished_basement_spaces(model.getSpaces)
    spaces.each do |space|
        space.surfaces.each do |surface|
            # Wall between below-grade unfinished space and ground
            if surface.surfaceType.downcase == "wall" and surface.outsideBoundaryCondition.downcase == "ground"
                wall_surfaces << surface
            end
            # Floor below below-grade unfinished space
            if surface.surfaceType.downcase == "floor" and surface.outsideBoundaryCondition.downcase == "ground"
                floor_surfaces << surface
            end
            # Ceiling above below-grade unfinished space and below finished space
            if surface.surfaceType.downcase == "roofceiling" and surface.adjacentSurface.is_initialized and surface.adjacentSurface.get.space.is_initialized
                adjacent_space = surface.adjacentSurface.get.space.get
                if Geometry.space_is_finished(adjacent_space)
                    ceiling_surfaces << surface
                end
            end
        end
    end

    # Continue if no applicable surfaces
    if wall_surfaces.empty? and floor_surfaces.empty? and ceiling_surfaces.empty?
      runner.registerAsNotApplicable("Measure not applied because no applicable surfaces were found.")
      return true
    end   
    
    # Get Inputs
    ufbsmtWallInsHeight = runner.getDoubleArgumentValue("wall_ins_height",user_arguments)
    ufbsmtWallCavityInsRvalueInstalled = runner.getDoubleArgumentValue("wall_cavity_r",user_arguments)
    ufbsmtWallInstallGrade = {"I"=>1, "II"=>2, "III"=>3}[runner.getStringArgumentValue("wall_cavity_grade",user_arguments)]
    ufbsmtWallCavityDepth = runner.getDoubleArgumentValue("wall_cavity_depth",user_arguments)
    ufbsmtWallCavityInsFillsCavity = runner.getBoolArgumentValue("wall_cavity_insfills",user_arguments)
    ufbsmtWallFramingFactor = runner.getDoubleArgumentValue("wall_ff",user_arguments)
    ufbsmtWallContInsRvalue = runner.getDoubleArgumentValue("wall_rigid_r",user_arguments)
    ufbsmtWallContInsThickness = runner.getDoubleArgumentValue("wall_rigid_thick_in",user_arguments)
    ufbsmtCeilingCavityInsRvalueNominal = runner.getDoubleArgumentValue("ceil_cavity_r",user_arguments)
    ufbsmtCeilingInstallGrade = {"I"=>1, "II"=>2, "III"=>3}[runner.getStringArgumentValue("ceil_cavity_grade",user_arguments)]
    ufbsmtCeilingFramingFactor = runner.getDoubleArgumentValue("ceil_ff",user_arguments)
    ufbsmtCeilingJoistHeight = runner.getDoubleArgumentValue("ceil_joist_height",user_arguments)
    exposed_perim = runner.getStringArgumentValue("exposed_perim",user_arguments)

    # Validate Inputs
    if ufbsmtWallInsHeight < 0.0
        runner.registerError("Wall Insulation Height must be greater than or equal to 0.")
        return false
    end
    if ufbsmtWallCavityInsRvalueInstalled < 0.0
        runner.registerError("Wall Cavity Insulation Installed R-value must be greater than or equal to 0.")
        return false
    end
    if ufbsmtWallCavityDepth < 0.0
        runner.registerError("Wall Cavity Depth must be greater than or equal to 0.")
        return false
    end
    if ufbsmtWallFramingFactor < 0.0 or ufbsmtWallFramingFactor >= 1.0
        runner.registerError("Wall Framing Factor must be greater than or equal to 0 and less than 1.")
        return false
    end
    if ufbsmtWallContInsRvalue < 0.0
        runner.registerError("Wall Continuous Insulation Nominal R-value must be greater than or equal to 0.")
        return false
    end
    if ufbsmtWallContInsThickness < 0.0
        runner.registerError("Wall Continuous Insulation Thickness must be greater than or equal to 0.")
        return false
    end
    if ufbsmtCeilingCavityInsRvalueNominal < 0.0
        runner.registerError("Ceiling Cavity Insulation Nominal R-value must be greater than or equal to 0.")
        return false
    end
    if ufbsmtCeilingFramingFactor < 0.0 or ufbsmtCeilingFramingFactor >= 1.0
        runner.registerError("Ceiling Framing Factor must be greater than or equal to 0 and less than 1.")
        return false
    end
    if ufbsmtCeilingJoistHeight <= 0.0
        runner.registerError("Ceiling Joist Height must be greater than 0.")
        return false
    end
    if exposed_perim != Constants.Auto and (not MathTools.valid_float?(exposed_perim) or exposed_perim.to_f < 0)
        runner.registerError("Exposed Perimeter must be #{Constants.Auto} or a number greater than or equal to 0.")
        return false
    end
    
    # Get geometry values
    ubFloorArea = Geometry.get_floor_area_from_spaces(spaces)
    if exposed_perim == Constants.Auto
        ubExtPerimeter = Geometry.calculate_exposed_perimeter(model, floor_surfaces, has_foundation_walls=true)
    else
        ubExtPerimeter = exposed_perim.to_f
    end
    ubExtWallArea = ubExtPerimeter * Geometry.spaces_avg_height(spaces)

    # -------------------------------
    # Process the basement walls
    # -------------------------------
    
    if not wall_surfaces.empty?
        # Define materials
        mat_framing = nil
        mat_cavity = nil
        mat_grap = nil
        mat_rigid = nil
        if ufbsmtWallCavityDepth > 0
            if ufbsmtWallCavityInsRvalueInstalled > 0
                if ufbsmtWallCavityInsFillsCavity
                    # Insulation
                    mat_cavity = Material.new(name=nil, thick_in=ufbsmtWallCavityDepth, mat_base=BaseMaterial.InsulationGenericDensepack, k_in=ufbsmtWallCavityDepth / ufbsmtWallCavityInsRvalueInstalled)
                else
                    # Insulation plus air gap when insulation thickness < cavity depth
                    mat_cavity = Material.new(name=nil, thick_in=ufbsmtWallCavityDepth, mat_base=BaseMaterial.InsulationGenericDensepack, k_in=ufbsmtWallCavityDepth / (ufbsmtWallCavityInsRvalueInstalled + Gas.AirGapRvalue))
                end
            else
                # Empty cavity
                mat_cavity = Material.AirCavityClosed(ufbsmtWallCavityDepth)
            end
            mat_framing = Material.new(name=nil, thick_in=ufbsmtWallCavityDepth, mat_base=BaseMaterial.Wood)
            mat_gap = Material.AirCavityClosed(ufbsmtWallCavityDepth)
        end
        if ufbsmtWallContInsThickness > 0
            mat_rigid = Material.new(name=nil, thick_in=ufbsmtWallContInsThickness, mat_base=BaseMaterial.InsulationRigid, k_in=ufbsmtWallContInsThickness / ufbsmtWallContInsRvalue)
        end
        
        # Set paths
        gapFactor = Construction.get_wall_gap_factor(ufbsmtWallInstallGrade, ufbsmtWallFramingFactor, ufbsmtWallCavityInsRvalueInstalled)
        path_fracs = [ufbsmtWallFramingFactor, 1 - ufbsmtWallFramingFactor - gapFactor, gapFactor]

        # Define construction (only used to calculate assembly R-value)
        ufbsmt_wall = Construction.new(path_fracs)
        ufbsmt_wall.add_layer(Material.AirFilmVertical, false)
        if ufbsmtWallCavityDepth > 0
            ufbsmt_wall.add_layer(Material.DefaultWallMass, false) # thermal mass added in separate measure
        end
        if not mat_framing.nil? and not mat_cavity.nil? and not mat_gap.nil?
            ufbsmt_wall.add_layer([mat_framing, mat_cavity, mat_gap], false)
        end
        if ufbsmtWallCavityInsRvalueInstalled > 0 or ufbsmtWallContInsRvalue > 0
            # For foundation walls, only add OSB if there is wall insulation.
            ufbsmt_wall.add_layer(Material.DefaultWallSheathing, false)
        end
        if not mat_rigid.nil?
            ufbsmt_wall.add_layer(mat_rigid, false)
        end

        overall_wall_Rvalue = ufbsmt_wall.assembly_rvalue(runner)
        if overall_wall_Rvalue.nil?
            return false
        end
        
        # Calculate fictitious layer behind finished basement wall to achieve equivalent R-value. See Winkelmann article.
        conduction_factor = Construction.get_basement_conduction_factor(ufbsmtWallInsHeight, overall_wall_Rvalue)
        if ubExtPerimeter > 0
            ub_effective_Rvalue = ubExtWallArea / (conduction_factor * ubExtPerimeter) # hr*ft^2*F/Btu
        else
            ub_effective_Rvalue = 1000 # hr*ft^2*F/Btu
        end
        # Insulation of 4ft height inside a 8ft basement is modeled completely in the fictitious layer
        mat_fic_insul_layer = nil
        if ufbsmtWallContInsRvalue > 0 and ufbsmtWallInsHeight == 8
            thick_in = ufbsmtWallContInsRvalue*BaseMaterial.InsulationRigid.k_in
            mat_fic_insul_layer = Material.new(name="UFBaseWallIns", thick_in=thick_in, mat_base=BaseMaterial.InsulationRigid)
            insul_layer_rvalue = ufbsmtWallContInsRvalue
        else
            insul_layer_rvalue = 0
        end
        ub_US_Rvalue = Material.Concrete8in.rvalue + Material.AirFilmVertical.rvalue + insul_layer_rvalue # hr*ft^2*F/Btu
        ub_fictitious_Rvalue = ub_effective_Rvalue - Material.Soil12in.rvalue - ub_US_Rvalue # hr*ft^2*F/Btu
        mat_fic_wall = nil
        if ub_fictitious_Rvalue > 0
            mat_fic_wall = SimpleMaterial.new(name="UFBaseWall-FicR", rvalue=ub_fictitious_Rvalue)
        end
        
        # Define actual construction
        fic_ufbsmt_wall = Construction.new([1])
        fic_ufbsmt_wall.add_layer(Material.AirFilmVertical, false)
        fic_ufbsmt_wall.add_layer(Material.DefaultWallMass, false) # thermal mass added in separate measure
        if not mat_fic_insul_layer.nil?
            fic_ufbsmt_wall.add_layer(mat_fic_insul_layer, true)
        end
        fic_ufbsmt_wall.add_layer(Material.Concrete8in, true)
        fic_ufbsmt_wall.add_layer(Material.Soil12in, true)
        if not mat_fic_wall.nil?
            fic_ufbsmt_wall.add_layer(mat_fic_wall, true)
        end

        # Create and assign construction to surfaces
        if not fic_ufbsmt_wall.create_and_assign_constructions(wall_surfaces, runner, model, name="GrndInsUnfinBWall")
            return false
        end
    end

    # -------------------------------
    # Process the basement floor
    # -------------------------------

    if not floor_surfaces.empty?
        ub_total_UA = ubExtWallArea / ub_effective_Rvalue # Btu/hr*F
        ub_wall_Rvalue = ub_US_Rvalue + Material.Soil12in.rvalue
        ub_wall_UA = ubExtWallArea / ub_wall_Rvalue
        
        # Fictitious layer below basement floor to achieve equivalent R-value. See Winklemann article.
        if ub_fictitious_Rvalue < 0 # Not enough cond through walls, need to add in floor conduction
            ub_floor_Rvalue = ubFloorArea / (ub_total_UA - ub_wall_UA) - Material.Soil12in.rvalue - Material.Concrete4in.rvalue # hr*ft^2*F/Btu (assumes basement floor is a 4-in concrete slab)
        else
            ub_floor_Rvalue = 1000 # hr*ft^2*F/Btu
        end
        
        # Define materials
        mat_fic_floor = SimpleMaterial.new(name="UFBaseFloor-FicR", rvalue=ub_floor_Rvalue)
        
        # Define construction
        ub_floor = Construction.new([1.0])
        ub_floor.add_layer(Material.Concrete4in, true)
        ub_floor.add_layer(Material.Soil12in, true)
        ub_floor.add_layer(mat_fic_floor, true)
        
        # Create and assign construction to surfaces
        if not ub_floor.create_and_assign_constructions(floor_surfaces, runner, model, name="GrndUninsUnfinBFloor")
            return false
        end
    end
    
    # -------------------------------
    # Process the basement ceiling
    # -------------------------------
    
    if not ceiling_surfaces.empty?
        # Define materials
        mat_2x = Material.Stud2x(ufbsmtCeilingJoistHeight)
        if ufbsmtCeilingCavityInsRvalueNominal == 0
            mat_cavity = Material.AirCavityOpen(mat_2x.thick_in)
        else    
            mat_cavity = Material.new(name=nil, thick_in=mat_2x.thick_in, mat_base=BaseMaterial.InsulationGenericDensepack, k_in=mat_2x.thick_in / ufbsmtCeilingCavityInsRvalueNominal)
        end
        mat_framing = Material.new(name=nil, thick_in=mat_2x.thick_in, mat_base=BaseMaterial.Wood)
        mat_gap = Material.AirCavityOpen(ufbsmtCeilingJoistHeight)
        
        # Set paths
        gapFactor = Construction.get_wall_gap_factor(ufbsmtCeilingInstallGrade, ufbsmtCeilingFramingFactor, ufbsmtCeilingCavityInsRvalueNominal)
        path_fracs = [ufbsmtCeilingFramingFactor, 1 - ufbsmtCeilingFramingFactor - gapFactor, gapFactor]
        
        # Define construction
        ub_ceiling = Construction.new(path_fracs)
        ub_ceiling.add_layer(Material.AirFilmFloorReduced, false)
        ub_ceiling.add_layer([mat_framing, mat_cavity, mat_gap], true, "UFBsmtCeilingIns")
        ub_ceiling.add_layer(Material.DefaultFloorSheathing, false) # sheathing added in separate measure
        ub_ceiling.add_layer(Material.DefaultFloorMass, false) # thermal mass added in separate measure
        ub_ceiling.add_layer(Material.DefaultFloorCovering, false) # floor covering added in separate measure
        ub_ceiling.add_layer(Material.AirFilmFloorReduced, false)
        
        # Create and assign construction to surfaces
        if not ub_ceiling.create_and_assign_constructions(ceiling_surfaces, runner, model, name="UnfinBInsFinFloor")
            return false
        end
    end
    
    # Store info for HVAC Sizing measure
    units = Geometry.get_building_units(model, runner)
    if units.nil?
        return false
    end
    units.each do |unit|
        unit.spaces.each do |space|
            next if not spaces.include?(space)
            unit.setFeature(Constants.SizingInfoSpaceWallsInsulated(space), ((ufbsmtWallCavityDepth > 0 and ufbsmtWallCavityInsRvalueInstalled > 0) or (ufbsmtWallContInsThickness > 0 and ufbsmtWallContInsRvalue > 0)))
            unit.setFeature(Constants.SizingInfoSpaceCeilingInsulated(space), (ufbsmtCeilingCavityInsRvalueNominal > 0))
        end
    end
    if not wall_surfaces.empty?
        wall_surfaces.each do |surface|
            units.each do |unit|
                next if not unit.spaces.include?(surface.space.get)
                unit.setFeature(Constants.SizingInfoBasementWallInsulationHeight(surface), ufbsmtWallInsHeight)
                unit.setFeature(Constants.SizingInfoBasementWallRvalue(surface), overall_wall_Rvalue)
            end
        end
    end

    # Remove any constructions/materials that aren't used
    HelperMethods.remove_unused_constructions_and_materials(model, runner)

    return true
 
  end #end the run method
  
end #end the measure

#this allows the measure to be use by the application
ProcessConstructionsFoundationsFloorsBasementUnfinished.new.registerWithApplication