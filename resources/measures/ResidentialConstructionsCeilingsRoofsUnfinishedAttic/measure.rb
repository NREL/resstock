#see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/geometry"

#start the measure
class ProcessConstructionsCeilingsRoofsUnfinishedAttic < OpenStudio::Measure::ModelMeasure

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Residential Ceilings/Roofs - Unfinished Attic Constructions"
  end
  
  def description
    return "This measure assigns constructions to unfinished attic floors and ceilings.#{Constants.WorkflowDescription}"
  end
  
  def modeler_description
    return "Calculates and assigns material layer properties of constructions for 1) floors between unfinished space under a roof and finished space and 2) roofs of unfinished space."
  end    
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new
    
    #make a choice argument for unfinished attic floors and ceilings
    ceiling_surfaces, roof_surfaces, spaces = get_unfinished_attic_ceilings_and_roofs_surfaces(model)
    surfaces_args = OpenStudio::StringVector.new
    surfaces_args << Constants.Auto
    (ceiling_surfaces + roof_surfaces).each do |surface|
      surfaces_args << surface.name.to_s
    end   
    surface = OpenStudio::Measure::OSArgument::makeChoiceArgument("surface", surfaces_args, false)
    surface.setDisplayName("Surface(s)")
    surface.setDescription("Select the surface(s) to assign constructions.")
    surface.setDefaultValue(Constants.Auto)
    args << surface    
    
    #make a double argument for ceiling R-value
    ceil_r = OpenStudio::Measure::OSArgument::makeDoubleArgument("ceil_r", true)
    ceil_r.setDisplayName("Ceiling Insulation Nominal R-value")
    ceil_r.setUnits("h-ft^2-R/Btu")
    ceil_r.setDescription("Refers to the R-value of the insulation and not the overall R-value of the assembly.")
    ceil_r.setDefaultValue(30)
    args << ceil_r

    #make a choice argument for model objects
    installgrade_display_names = OpenStudio::StringVector.new
    installgrade_display_names << "I"
    installgrade_display_names << "II"
    installgrade_display_names << "III"

    #make a choice argument for ceiling insulation installation grade
    ceil_grade = OpenStudio::Measure::OSArgument::makeChoiceArgument("ceil_grade", installgrade_display_names, true)
    ceil_grade.setDisplayName("Ceiling Install Grade")
    ceil_grade.setDescription("Installation grade as defined by RESNET standard. 5% of the cavity is considered missing insulation for Grade 3, 2% for Grade 2, and 0% for Grade 1.")
    ceil_grade.setDefaultValue("I")
    args << ceil_grade

    #make a choice argument for ceiling insulation thickness
    ceil_ins_thick_in = OpenStudio::Measure::OSArgument::makeDoubleArgument("ceil_ins_thick_in", true)
    ceil_ins_thick_in.setDisplayName("Ceiling Insulation Thickness")
    ceil_ins_thick_in.setUnits("in")
    ceil_ins_thick_in.setDescription("The thickness in inches of insulation required to obtain the specified R-value.")
    ceil_ins_thick_in.setDefaultValue(8.55)
    args << ceil_ins_thick_in

    #make a choice argument for ceiling framing factor
    ceil_ff = OpenStudio::Measure::OSArgument::makeDoubleArgument("ceil_ff", true)
    ceil_ff.setDisplayName("Ceiling Framing Factor")
    ceil_ff.setUnits("frac")
    ceil_ff.setDescription("Fraction of ceiling that is framing.")
    ceil_ff.setDefaultValue(0.07)
    args << ceil_ff

    #make a choice argument for ceiling joist height
    ceil_joist_height = OpenStudio::Measure::OSArgument::makeDoubleArgument("ceil_joist_height", true)
    ceil_joist_height.setDisplayName("Ceiling Joist Height")
    ceil_joist_height.setUnits("in")
    ceil_joist_height.setDescription("Height of the joist member.")
    ceil_joist_height.setDefaultValue(3.5)
    args << ceil_joist_height    

    #make a double argument for roof cavity R-value
    roof_cavity_r = OpenStudio::Measure::OSArgument::makeDoubleArgument("roof_cavity_r", true)
    roof_cavity_r.setDisplayName("Roof Cavity Insulation Nominal R-value")
    roof_cavity_r.setUnits("h-ft^2-R/Btu")
    roof_cavity_r.setDescription("Refers to the R-value of the cavity insulation and not the overall R-value of the assembly.")
    roof_cavity_r.setDefaultValue(0)
    args << roof_cavity_r
    
    #make a choice argument for roof cavity insulation installation grade
    roof_cavity_grade = OpenStudio::Measure::OSArgument::makeChoiceArgument("roof_cavity_grade", installgrade_display_names, true)
    roof_cavity_grade.setDisplayName("Roof Cavity Install Grade")
    roof_cavity_grade.setDescription("Installation grade as defined by RESNET standard. 5% of the cavity is considered missing insulation for Grade 3, 2% for Grade 2, and 0% for Grade 1.")
    roof_cavity_grade.setDefaultValue("I")
    args << roof_cavity_grade

    #make a choice argument for roof cavity insulation thickness
    roof_cavity_ins_thick_in = OpenStudio::Measure::OSArgument::makeDoubleArgument("roof_cavity_ins_thick_in", true)
    roof_cavity_ins_thick_in.setDisplayName("Roof Cavity Insulation Thickness")
    roof_cavity_ins_thick_in.setUnits("in")
    roof_cavity_ins_thick_in.setDescription("The thickness in inches of insulation required to obtain the specified R-value.")
    roof_cavity_ins_thick_in.setDefaultValue(0)
    args << roof_cavity_ins_thick_in
    
    #make a choice argument for roof framing factor
    roof_ff = OpenStudio::Measure::OSArgument::makeDoubleArgument("roof_ff", true)
    roof_ff.setDisplayName("Roof Framing Factor")
    roof_ff.setUnits("frac")
    roof_ff.setDescription("Fraction of roof that is framing.")
    roof_ff.setDefaultValue(0.07)
    args << roof_ff

    #make a choice argument for roof framing thickness
    roof_fram_thick_in = OpenStudio::Measure::OSArgument::makeDoubleArgument("roof_fram_thick_in", true)
    roof_fram_thick_in.setDisplayName("Roof Framing Thickness")
    roof_fram_thick_in.setUnits("in")
    roof_fram_thick_in.setDescription("Thickness of roof framing.")
    roof_fram_thick_in.setDefaultValue(7.25)
    args << roof_fram_thick_in

    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    #use the built-in error checking
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    surface_s = runner.getOptionalStringArgumentValue("surface",user_arguments)
    if not surface_s.is_initialized
      surface_s = Constants.Auto
    else
      surface_s = surface_s.get
    end
    
    ceiling_surfaces, roof_surfaces, spaces = get_unfinished_attic_ceilings_and_roofs_surfaces(model)
    
    unless surface_s == Constants.Auto
      ceiling_surfaces.delete_if { |surface| surface.name.to_s != surface_s }
      roof_surfaces.delete_if { |surface| surface.name.to_s != surface_s }
    end

    # Continue if no applicable surfaces
    if ceiling_surfaces.empty? and roof_surfaces.empty?
        runner.registerAsNotApplicable("Measure not applied because no applicable surfaces were found.")
        return true
    end
    
    # Get Inputs
    uACeilingInsRvalueNominal = runner.getDoubleArgumentValue("ceil_r",user_arguments)
    uACeilingInstallGrade = {"I"=>1, "II"=>2, "III"=>3}[runner.getStringArgumentValue("ceil_grade",user_arguments)]
    uACeilingInsThickness = runner.getDoubleArgumentValue("ceil_ins_thick_in",user_arguments)
    uACeilingFramingFactor = runner.getDoubleArgumentValue("ceil_ff",user_arguments)
    uACeilingJoistHeight = runner.getDoubleArgumentValue("ceil_joist_height",user_arguments)
    uARoofInsRvalueNominal = runner.getDoubleArgumentValue("roof_cavity_r",user_arguments)
    uARoofInstallGrade = {"I"=>1, "II"=>2, "III"=>3}[runner.getStringArgumentValue("roof_cavity_grade",user_arguments)]
    uARoofInsThickness = runner.getDoubleArgumentValue("roof_cavity_ins_thick_in",user_arguments)
    uARoofFramingFactor = runner.getDoubleArgumentValue("roof_ff",user_arguments)
    uARoofFramingThickness = runner.getDoubleArgumentValue("roof_fram_thick_in",user_arguments)
    
    # Validate Inputs
    if uACeilingInsRvalueNominal < 0.0
        runner.registerError("Ceiling Insulation Nominal R-value must be greater than or equal to 0.")
        return false
    end
    if uACeilingInsThickness < 0.0
        runner.registerError("Ceiling Insulation Thickness must be greater than or equal to 0.")
        return false
    end
    if uACeilingFramingFactor < 0.0 or uACeilingFramingFactor >= 1.0
        runner.registerError("Ceiling Framing Factor must be greater than or equal to 0 and less than 1.")
        return false
    end
    if uACeilingJoistHeight <= 0.0
        runner.registerError("Ceiling Joist Height must be greater than 0.")
        return false
    end
    if uARoofInsRvalueNominal < 0.0
        runner.registerError("Roof Cavity Insulation Nominal R-value must be greater than or equal to 0.")
        return false
    end
    if uARoofInsThickness < 0.0
        runner.registerError("Roof Cavity Insulation Thickness must be greater than or equal to 0.")
        return false
    end
    if uARoofFramingFactor < 0.0 or uARoofFramingFactor >= 1.0
        runner.registerError("Roof Framing Factor must be greater than or equal to 0 and less than 1.")
        return false
    end
    if uARoofFramingThickness <= 0.0
        runner.registerError("Roof Framing Thickness must be greater than 0.")
        return false
    end
    
    # Get geometry values
    
    # -------------------------------
    # Process the attic ceiling
    # -------------------------------

    mat_film_roof = Material.AirFilmRoof(Geometry.calculate_avg_roof_pitch(spaces))

    if not ceiling_surfaces.empty?

      # TODO: Attic perimeter derate is currrently disabled
      # <- implementation goes here ->
    
      # Define materials
      mat_addtl_ins = nil
      if uACeilingInsThickness >= uACeilingJoistHeight
          # If the ceiling insulation thickness is greater than the joist thickness
          cavity_k = uACeilingInsThickness / uACeilingInsRvalueNominal
          if uACeilingInsThickness > uACeilingJoistHeight
              # If there is additional insulation beyond the rafter height,
              # these inputs are used for defining an additional layer
              mat_addtl_ins = Material.new(name="UAAdditionalCeilingIns", thick_in=(uACeilingInsThickness - uACeilingJoistHeight), mat_base=BaseMaterial.InsulationGenericLoosefill, k_in=cavity_k)
          end
          mat_cavity = Material.new(name=nil, thick_in=uACeilingJoistHeight, mat_base=BaseMaterial.InsulationGenericLoosefill, k_in=cavity_k)
      else
          # Else the joist thickness is greater than the ceiling insulation thickness
          if uACeilingInsRvalueNominal == 0
              mat_cavity = Material.AirCavityOpen(uACeilingJoistHeight)
          else
              mat_cavity = Material.new(name=nil, thick_in=uACeilingJoistHeight, mat_base=BaseMaterial.InsulationGenericLoosefill, k_in=uACeilingJoistHeight / uACeilingInsRvalueNominal)
          end
      end
      mat_framing = Material.new(name=nil, thick_in=uACeilingJoistHeight, mat_base=BaseMaterial.Wood)
      mat_gap = Material.AirCavityOpen(uACeilingJoistHeight)
      
      # Set paths
      gapFactor = Construction.get_wall_gap_factor(uACeilingInstallGrade, uACeilingFramingFactor, uACeilingInsRvalueNominal)
      path_fracs = [uACeilingFramingFactor, 1 - uACeilingFramingFactor - gapFactor, gapFactor]
      
      # Define construction
      attic_floor = Construction.new(path_fracs)
      attic_floor.add_layer(Material.AirFilmFloorAverage, false)
      if not mat_addtl_ins.nil?
          attic_floor.add_layer(mat_addtl_ins, true)
      end
      attic_floor.add_layer([mat_framing, mat_cavity, mat_gap], true, "UATrussandIns")
      attic_floor.add_layer(Material.GypsumCeiling1_2in, false) # thermal mass added in separate measure
      attic_floor.add_layer(Material.AirFilmFloorAverage, false)
      
      # Create and assign construction to ceiling surfaces
      if not attic_floor.create_and_assign_constructions(ceiling_surfaces, runner, model, name="FinInsUnfinUAFloor")
          return false
      end
    end    
    
    # -------------------------------
    # Process the attic roof
    # -------------------------------
    
    if not roof_surfaces.empty?
        # Define materials
        uA_roof_ins_thickness_in = [uARoofInsThickness, uARoofFramingThickness].max
        if uARoofInsRvalueNominal == 0
            mat_cavity = Material.AirCavityOpen(uA_roof_ins_thickness_in)
        else
            cavity_k = uARoofInsThickness / uARoofInsRvalueNominal
            if uARoofInsThickness < uARoofFramingThickness
                cavity_k = cavity_k * uARoofFramingThickness / uARoofInsThickness
            end
            mat_cavity = Material.new(name=nil, thick_in=uA_roof_ins_thickness_in, mat_base=BaseMaterial.InsulationGenericDensepack, k_in=cavity_k)
        end
        if uARoofInsThickness > uARoofFramingThickness and uARoofFramingThickness > 0
            wood_k = BaseMaterial.Wood.k_in * uARoofInsThickness / uARoofFramingThickness
        else
            wood_k = BaseMaterial.Wood.k_in
        end
        mat_framing = Material.new(name=nil, thick_in=uA_roof_ins_thickness_in, mat_base=BaseMaterial.Wood, k_in=wood_k)
        mat_gap = Material.AirCavityOpen(uA_roof_ins_thickness_in)
        
        # Set paths
        gapFactor = Construction.get_wall_gap_factor(uARoofInstallGrade, uARoofFramingFactor, uARoofInsRvalueNominal)
        path_fracs = [uARoofFramingFactor, 1 - uARoofFramingFactor - gapFactor, gapFactor]
        
        # Define construction
        roof = Construction.new(path_fracs)
        roof.add_layer(mat_film_roof, false)
        roof.add_layer([mat_framing, mat_cavity, mat_gap], true, "UARoofIns")
        roof.add_layer(Material.DefaultRoofSheathing, false) # roof sheathing added in separate measure
        roof.add_layer(Material.DefaultRoofMaterial, false) # roof material added in separate measure
        roof.add_layer(Material.AirFilmOutside, false)

        # Create and assign construction to roof surfaces
        if not roof.create_and_assign_constructions(roof_surfaces, runner, model, name="UnfinInsExtRoof")
            return false
        end
        
    end
    
    # Remove any constructions/materials that aren't used
    HelperMethods.remove_unused_constructions_and_materials(model, runner)

    return true
 
  end #end the run method
  
  def get_unfinished_attic_ceilings_and_roofs_surfaces(model)
  
    spaces = Geometry.get_unfinished_attic_spaces(model.getSpaces, model)

    ceiling_surfaces = []
    spaces.each do |space|
        space.surfaces.each do |surface|
            next if surface.surfaceType.downcase != "floor"
            next if not surface.adjacentSurface.is_initialized
            next if not surface.adjacentSurface.get.space.is_initialized
            adjacent_space = surface.adjacentSurface.get.space.get
            next if Geometry.space_is_unfinished(adjacent_space)
            ceiling_surfaces << surface
        end   
    end 
    
    roof_surfaces = []
    spaces.each do |space|
        space.surfaces.each do |surface|
            next if surface.surfaceType.downcase != "roofceiling" or surface.outsideBoundaryCondition.downcase != "outdoors"
            roof_surfaces << surface
        end   
    end  
  
    return ceiling_surfaces, roof_surfaces, spaces
  
  end

end #end the measure

#this allows the measure to be use by the application
ProcessConstructionsCeilingsRoofsUnfinishedAttic.new.registerWithApplication