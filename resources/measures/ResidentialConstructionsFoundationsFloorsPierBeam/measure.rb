#see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/geometry"

#start the measure
class ProcessConstructionsFoundationsFloorsPierBeam < OpenStudio::Ruleset::ModelUserScript

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Residential Foundations/Floors - Pier & Beam Construction"
  end
  
  def description
    return "This measure assigns a wood stud construction to the ceiling of the pier & beam space."
  end
  
  def modeler_description
    return "Calculates and assigns material layer properties of wood stud constructions for floors finished space and pier & beam space. If the floors have an existing construction, the layers (other than floor covering and floor mass) are replaced. This measure is intended to be used in conjunction with Floor Covering and Floor Mass measures."
  end    
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make a double argument for nominal R-value of cavity insulation
    cavity_r = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("cavity_r", true)
    cavity_r.setDisplayName("Cavity Insulation Nominal R-value")
    cavity_r.setUnits("hr-ft^2-R/Btu")
    cavity_r.setDescription("Refers to the R-value of the cavity insulation and not the overall R-value of the assembly.")
    cavity_r.setDefaultValue(19.0)
    args << cavity_r

    #make a choice argument for wall cavity insulation installation grade
    installgrade_display_names = OpenStudio::StringVector.new
    installgrade_display_names << "I"
    installgrade_display_names << "II"
    installgrade_display_names << "III"
    install_grade = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("install_grade", installgrade_display_names, true)
    install_grade.setDisplayName("Cavity Install Grade")
    install_grade.setDescription("Installation grade as defined by RESNET standard. 5% of the cavity is considered missing insulation for Grade 3, 2% for Grade 2, and 0% for Grade 1.")
    install_grade.setDefaultValue("I")
    args << install_grade   

    #make a choice argument for unfinished attic ceiling framing factor
    framing_factor = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("framing_factor", true)
    framing_factor.setDisplayName("Framing Factor")
    framing_factor.setUnits("frac")
    framing_factor.setDescription("The fraction of a floor assembly that is comprised of structural framing.")
    framing_factor.setDefaultValue(0.13)
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

    surfaces = []
    Geometry.get_pier_beam_spaces(model.getSpaces).each do |space|
        space.surfaces.each do |surface|
            next if surface.surfaceType.downcase != "roofceiling"
            surfaces << surface
        end
    end
    
    # Continue if no applicable surfaces
    if surfaces.empty?
      runner.registerAsNotApplicable("Measure not applied because no applicable surfaces were found.")
      return true
    end        
    
    # Get Inputs
    pbCeilingCavityInsRvalueNominal = runner.getDoubleArgumentValue("cavity_r",user_arguments)
    pbCeilingInstallGrade = {"I"=>1, "II"=>2, "III"=>3}[runner.getStringArgumentValue("install_grade",user_arguments)]
    pbCeilingFramingFactor = runner.getDoubleArgumentValue("framing_factor",user_arguments)
    
    # Validate Inputs
    if pbCeilingCavityInsRvalueNominal < 0.0
        runner.registerError("Cavity Insulation Nominal R-value must be greater than or equal to 0.")
        return false
    end
    if pbCeilingFramingFactor < 0.0 or pbCeilingFramingFactor >= 1.0
        runner.registerError("Framing Factor must be greater than or equal to 0 and less than 1.")
        return false
    end
    
    # Process the floors
    
    # Define Materials
    if pbCeilingCavityInsRvalueNominal == 0
        mat_cavity = Material.AirCavityOpen(thick_in=Material.Stud2x6.thick_in)
    else
        mat_cavity = Material.new(name=nil, thick_in=Material.Stud2x6.thick_in, mat_base=BaseMaterial.InsulationGenericDensepack, k_in=Material.Stud2x6.thick_in / pbCeilingCavityInsRvalueNominal)
    end
    mat_framing = Material.new(name=nil, thick_in=Material.Stud2x6.thick_in, mat_base=BaseMaterial.Wood)
    mat_gap = Material.AirCavityClosed(Material.Stud2x6.thick_in)
    
    # Set paths
    pbGapFactor = Construction.get_wall_gap_factor(pbCeilingInstallGrade, pbCeilingFramingFactor, pbCeilingCavityInsRvalueNominal)
    path_fracs = [pbCeilingFramingFactor, 1 - pbCeilingFramingFactor - pbGapFactor, pbGapFactor]
    
    # Define construction
    pb_const = Construction.new(path_fracs)
    pb_const.add_layer(Material.AirFilmFloorReduced, false)
    pb_const.add_layer([mat_framing, mat_cavity, mat_gap], true, "PierBeamCeilingIns")
    pb_const.add_layer(Material.DefaultFloorSheathing, false) # sheathing added in separate measure
    pb_const.add_layer(Material.DefaultFloorMass, false) # thermal mass added in separate measure
    pb_const.add_layer(Material.DefaultFloorCovering, false) # floor covering added in separate measure
    pb_const.add_layer(Material.AirFilmFloorReduced, false)
    
    # Create and assign construction to surfaces
    if not pb_const.create_and_assign_constructions(surfaces, runner, model, name="UnfinInsFinPierBeamFloor")
        return false
    end
    
    # Remove any constructions/materials that aren't used
    HelperMethods.remove_unused_constructions_and_materials(model, runner)
    
    return true

  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ProcessConstructionsFoundationsFloorsPierBeam.new.registerWithApplication