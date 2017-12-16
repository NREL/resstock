#see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/geometry"
require "#{File.dirname(__FILE__)}/resources/unit_conversions"

#start the measure
class ProcessConstructionsFoundationsFloorsSlab < OpenStudio::Measure::ModelMeasure
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Residential Foundations/Floors - Slab Construction"
  end
  
  def description
    return "This measure assigns a construction to slabs-on-grade.#{Constants.WorkflowDescription}"
  end
  
  def modeler_description
    return "Calculates and assigns material layer properties of slab constructions for floors between above-grade finished space and the ground."
  end  
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    #make a choice argument for above-grade ground floors adjacent to finished space
    surfaces = get_slab_floor_surfaces(model)
    surfaces_args = OpenStudio::StringVector.new
    surfaces_args << Constants.Auto
    surfaces.each do |surface|
      surfaces_args << surface.name.to_s
    end
    surface = OpenStudio::Measure::OSArgument::makeChoiceArgument("surface", surfaces_args, false)
    surface.setDisplayName("Surface(s)")
    surface.setDescription("Select the surface(s) to assign constructions.")
    surface.setDefaultValue(Constants.Auto)
    args << surface    
    
    #make a double argument for slab perimeter insulation R-value
    perim_r = OpenStudio::Measure::OSArgument::makeDoubleArgument("perim_r", true)
    perim_r.setDisplayName("Perimeter Insulation Nominal R-value")
    perim_r.setUnits("hr-ft^2-R/Btu")
    perim_r.setDescription("Perimeter insulation is placed horizontally below the perimeter of the slab.")
    perim_r.setDefaultValue(0.0)
    args << perim_r
    
    #make a double argument for slab perimeter insulation width
    perim_width = OpenStudio::Measure::OSArgument::makeDoubleArgument("perim_width", true)
    perim_width.setDisplayName("Perimeter Insulation Width")
    perim_width.setUnits("ft")
    perim_width.setDescription("The distance from the perimeter of the house where the perimeter insulation ends.")
    perim_width.setDefaultValue(0.0)
    args << perim_width

    #make a double argument for whole slab insulation R-value
    whole_r = OpenStudio::Measure::OSArgument::makeDoubleArgument("whole_r", true)
    whole_r.setDisplayName("Whole Slab Insulation Nominal R-value")
    whole_r.setUnits("hr-ft^2-R/Btu")
    whole_r.setDescription("Whole slab insulation is placed horizontally below the entire slab.")
    whole_r.setDefaultValue(0.0)
    args << whole_r
    
    #make a double argument for slab gap R-value
    gap_r = OpenStudio::Measure::OSArgument::makeDoubleArgument("gap_r", true)
    gap_r.setDisplayName("Gap Insulation Nominal R-value")
    gap_r.setUnits("hr-ft^2-R/Btu")
    gap_r.setDescription("Gap insulation is placed vertically between the edge of the slab and the foundation wall.")
    gap_r.setDefaultValue(0.0)
    args << gap_r

    #make a double argument for slab exterior insulation R-value
    ext_r = OpenStudio::Measure::OSArgument::makeDoubleArgument("ext_r", true)
    ext_r.setDisplayName("Exterior Insulation Nominal R-value")
    ext_r.setUnits("hr-ft^2-R/Btu")
    ext_r.setDescription("Exterior insulation is placed vertically on the exterior of the foundation wall.")
    ext_r.setDefaultValue(0.0)
    args << ext_r
    
    #make a double argument for slab exterior insulation depth
    ext_depth = OpenStudio::Measure::OSArgument::makeDoubleArgument("ext_depth", true)
    ext_depth.setDisplayName("Exterior Insulation Depth")
    ext_depth.setUnits("ft")
    ext_depth.setDescription("The depth of the exterior foundation insulation.")
    ext_depth.setDefaultValue(0.0)
    args << ext_depth

    #make a double argument for slab mass thickness
    mass_thick_in = OpenStudio::Measure::OSArgument::makeDoubleArgument("mass_thick_in", true)
    mass_thick_in.setDisplayName("Mass Thickness")
    mass_thick_in.setUnits("in")
    mass_thick_in.setDescription("Thickness of the slab foundation mass.")
    mass_thick_in.setDefaultValue(4.0)
    args << mass_thick_in
    
    #make a double argument for slab mass conductivity
    mass_cond = OpenStudio::Measure::OSArgument::makeDoubleArgument("mass_conductivity", true)
    mass_cond.setDisplayName("Mass Conductivity")
    mass_cond.setUnits("Btu-in/h-ft^2-R")
    mass_cond.setDescription("Conductivity of the slab foundation mass.")
    mass_cond.setDefaultValue(9.1)
    args << mass_cond

    #make a double argument for slab mass density
    mass_dens = OpenStudio::Measure::OSArgument::makeDoubleArgument("mass_density", true)
    mass_dens.setDisplayName("Mass Density")
    mass_dens.setUnits("lb/ft^3")
    mass_dens.setDescription("Density of the slab foundation mass.")
    mass_dens.setDefaultValue(140.0)
    args << mass_dens

    #make a double argument for slab mass specific heat
    mass_specheat = OpenStudio::Measure::OSArgument::makeDoubleArgument("mass_specific_heat", true)
    mass_specheat.setDisplayName("Mass Specific Heat")
    mass_specheat.setUnits("Btu/lb-R")
    mass_specheat.setDescription("Specific heat of the slab foundation mass.")
    mass_specheat.setDefaultValue(0.2)
    args << mass_specheat
    
    #make a string argument for exposed perimeter
    exposed_perim = OpenStudio::Measure::OSArgument::makeStringArgument("exposed_perim", true)
    exposed_perim.setDisplayName("Exposed Perimeter")
    exposed_perim.setUnits("ft")
    exposed_perim.setDescription("Total length of the slab's perimeter that is on the exterior of the building's footprint.")
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

    surface_s = runner.getOptionalStringArgumentValue("surface",user_arguments)
    if not surface_s.is_initialized
      surface_s = Constants.Auto
    else
      surface_s = surface_s.get
    end

    surfaces = get_slab_floor_surfaces(model)
    
    unless surface_s == Constants.Auto
      surfaces.delete_if { |surface| surface.name.to_s != surface_s }
    end
    
    spaces = []
    surfaces.each do |surface|
      space = surface.space.get
      if not spaces.include? space
          # Floors between above-grade finished space and ground
          spaces << space
      end
    end
  
    # Continue if no applicable surfaces
    if surfaces.empty?
      runner.registerAsNotApplicable("Measure not applied because no applicable surfaces were found.")
      return true
    end

    # Get Inputs
    slabPerimeterRvalue = runner.getDoubleArgumentValue("perim_r",user_arguments)
    slabPerimeterInsWidth = runner.getDoubleArgumentValue("perim_width",user_arguments)
    slabWholeInsRvalue = runner.getDoubleArgumentValue("whole_r",user_arguments)
    slabGapRvalue = runner.getDoubleArgumentValue("gap_r",user_arguments)
    slabExtRvalue = runner.getDoubleArgumentValue("ext_r",user_arguments)
    slabExtInsDepth = runner.getDoubleArgumentValue("ext_depth",user_arguments)
    slabMassThickIn = runner.getDoubleArgumentValue("mass_thick_in",user_arguments)
    slabMassCond = runner.getDoubleArgumentValue("mass_conductivity",user_arguments)
    slabMassDens = runner.getDoubleArgumentValue("mass_density",user_arguments)
    slabMassSpecHeat = runner.getDoubleArgumentValue("mass_specific_heat",user_arguments)
    exposed_perim = runner.getStringArgumentValue("exposed_perim",user_arguments)

    # Validate Inputs
    if slabPerimeterRvalue < 0.0
        runner.registerError("Perimeter Insulation Nominal R-value must be greater than or equal to 0.")
        return false    
    end
    if slabPerimeterInsWidth < 0.0
        runner.registerError("Perimeter Insulation Width must be greater than or equal to 0.")
        return false    
    end
    if slabWholeInsRvalue < 0.0
        runner.registerError("Whole Slab Insulation Nominal R-value must be greater than or equal to 0.")
        return false    
    end
    if slabGapRvalue < 0.0
        runner.registerError("Gap Insulation Nominal R-value must be greater than or equal to 0.")
        return false    
    end
    if slabExtRvalue < 0.0
        runner.registerError("Exterior Insulation Nominal R-value must be greater than or equal to 0.")
        return false    
    end
    if slabExtInsDepth < 0.0
        runner.registerError("Exterior Insulation Depth must be greater than or equal to 0.")
        return false    
    end
    if slabMassThickIn <= 0.0
        runner.registerError("Mass Thickness must be greater than 0.")
        return false    
    end
    if slabMassCond <= 0.0
        runner.registerError("Mass Conductivity must be greater than 0.")
        return false    
    end
    if slabMassDens <= 0.0
        runner.registerError("Mass Density must be greater than 0.")
        return false    
    end
    if slabMassSpecHeat <= 0.0
        runner.registerError("Mass Specific Heat must be greater than 0.")
        return false    
    end
    if (slabPerimeterRvalue == 0.0 and slabPerimeterInsWidth != 0.0) or (slabPerimeterRvalue != 0.0 and slabPerimeterInsWidth == 0.0)
        runner.registerError("Perimeter insulation does not have both properties (R-value and Width) entered.")
        return false    
    end
    if (slabExtRvalue == 0.0 and slabExtInsDepth != 0.0) or (slabExtRvalue != 0.0 and slabExtInsDepth == 0.0)
        runner.registerError("Exterior insulation does not have both properties (R-value and Depth) entered.")
        return false    
    end
    if ((slabPerimeterRvalue > 0.0 and slabWholeInsRvalue > 0.0) or
        (slabPerimeterRvalue > 0.0 and slabExtRvalue > 0.0) or 
        (slabWholeInsRvalue > 0.0 and slabExtRvalue > 0.0) or 
        (slabExtRvalue > 0.0 and slabGapRvalue > 0.0) or
        (slabGapRvalue > 0.0 and slabPerimeterRvalue == 0 and slabWholeInsRvalue == 0 and slabExtRvalue == 0))
        runner.registerError("Invalid insulation configuration. The only valid configurations are: Exterior, Perimeter+Gap, Whole+Gap, Perimeter, or Whole.")
        return false    
    end
    if exposed_perim != Constants.Auto and (not MathTools.valid_float?(exposed_perim) or exposed_perim.to_f < 0)
        runner.registerError("Exposed Perimeter must be #{Constants.Auto} or a number greater than or equal to 0.")
        return false
    end
    
    # Get geometry values
    slabArea = Geometry.calculate_total_area_from_surfaces(surfaces)
    if exposed_perim == Constants.Auto
        slabExtPerimeter = Geometry.calculate_exposed_perimeter(model, surfaces)
    else
        slabExtPerimeter = exposed_perim.to_f
    end
    
    # Process the slab

    # Define materials
    slabCarpetPerimeterConduction, slabBarePerimeterConduction, slabHasWholeInsulation = SlabPerimeterConductancesByType(slabPerimeterRvalue, slabGapRvalue, slabPerimeterInsWidth, slabExtRvalue, slabWholeInsRvalue, slabExtInsDepth)
    mat_slab = Material.new(name='SlabMass', thick_in=slabMassThickIn, mat_base=nil, k_in=slabMassCond, rho=slabMassDens, cp=slabMassSpecHeat)

    # Models one floor surface with an equivalent carpented/bare material (Better alternative
    # to having two floors with twice the total area, compensated by thinning mass thickness.)
    carpetFloorFraction = Material.CoveringBare.rvalue/Material.CoveringBare(floorFraction=1.0).rvalue
    slab_perimeter_conduction = slabCarpetPerimeterConduction * carpetFloorFraction + slabBarePerimeterConduction * (1 - carpetFloorFraction)

    if slabExtPerimeter > 0
        effective_slab_Rvalue = slabArea / (slabExtPerimeter * slab_perimeter_conduction)
    else
        effective_slab_Rvalue = 1000.0 # hr*ft^2*F/Btu
    end

    slab_Rvalue = mat_slab.rvalue + Material.AirFilmFlatReduced.rvalue + Material.Soil12in.rvalue + Material.DefaultFloorCovering.rvalue
    fictitious_slab_Rvalue = effective_slab_Rvalue - slab_Rvalue

    if fictitious_slab_Rvalue <= 0
        runner.registerWarning("The slab foundation thickness will be automatically reduced to avoid simulation errors, but overall R-value will remain the same.")
        slab_factor = effective_slab_Rvalue / slab_Rvalue
        mat_slab.thick_in = mat_slab.thick_in * slab_factor
    end

    mat_fic = nil
    if fictitious_slab_Rvalue > 0
        # Fictitious layer below slab to achieve equivalent R-value. See Winkelmann article.
        mat_fic = Material.new(name="Mat-Fic-Slab", thick_in=1.0, mat_base=nil, k_in=1.0/fictitious_slab_Rvalue, rho=2.5, cp=0.29)
    end

    # Define construction
    slab = Construction.new([1.0])
    slab.add_layer(Material.AirFilmFlatReduced, false)
    slab.add_layer(Material.DefaultFloorCovering, false) # floor covering added in separate measure
    slab.add_layer(mat_slab, true)
    slab.add_layer(Material.Soil12in, true)
    if not mat_fic.nil?
        slab.add_layer(mat_fic, true)
    end
    
    # Create and assign construction to surfaces
    if not slab.create_and_assign_constructions(surfaces, runner, model, name="Slab")
        return false
    end
    
    # Store info for HVAC Sizing measure
    units = Geometry.get_building_units(model, runner)
    if units.nil?
        return false
    end
    surfaces.each do |surface|
        units.each do |unit|
            next if not unit.spaces.include?(surface.space.get)
            unit.setFeature(Constants.SizingInfoSlabRvalue(surface), effective_slab_Rvalue)
        end
    end
    
    # Remove any constructions/materials that aren't used
    HelperMethods.remove_unused_constructions_and_materials(model, runner)

    return true
 
  end #end the run method

  def SlabPerimeterConductancesByType(slabPerimeterRvalue, slabGapRvalue, slabPerimeterInsWidth, slabExtRvalue, slabWholeInsRvalue, slabExtInsDepth)
    slabWidth = 28 # Width (shorter dimension) of slab, feet, to match Winkelmann analysis.
    slabLength = 55 # Longer dimension of slab, feet, to match Winkelmann analysis.
    soilConductivity = 1
    slabHasWholeInsulation = false
    if slabPerimeterRvalue > 0
        slabCarpetPerimeterConduction = PerimeterSlabInsulation(slabPerimeterRvalue, slabGapRvalue, slabPerimeterInsWidth, slabWidth, slabLength, 1, soilConductivity)
        slabBarePerimeterConduction = PerimeterSlabInsulation(slabPerimeterRvalue, slabGapRvalue, slabPerimeterInsWidth, slabWidth, slabLength, 0, soilConductivity)
    elsif slabExtRvalue > 0
        slabCarpetPerimeterConduction = ExteriorSlabInsulation(slabExtInsDepth, slabExtRvalue, 1)
        slabBarePerimeterConduction = ExteriorSlabInsulation(slabExtInsDepth, slabExtRvalue, 0)
    elsif slabWholeInsRvalue > 0
        slabHasWholeInsulation = true
        slabCarpetPerimeterConduction = FullSlabInsulation(slabWholeInsRvalue, slabGapRvalue, slabWidth, slabLength, 1, soilConductivity)
        slabBarePerimeterConduction = FullSlabInsulation(slabWholeInsRvalue, slabGapRvalue, slabWidth, slabLength, 0, soilConductivity)
    else
        slabCarpetPerimeterConduction = FullSlabInsulation(0, 0, slabWidth, slabLength, 1, soilConductivity)
        slabBarePerimeterConduction = FullSlabInsulation(0, 0, slabWidth, slabLength, 0, soilConductivity)
    end
    
    return slabCarpetPerimeterConduction, slabBarePerimeterConduction, slabHasWholeInsulation
    
  end
  

  def PerimeterSlabInsulation(rperim, rgap, wperim, slabWidth, slabLength, carpet, k)
    # Coded by Dennis Barley, April 2013.
    # This routine calculates the perimeter conductance for a slab with insulation 
    #   under the slab perimeter as well as gap insulation around the edge.
    #   The algorithm is based on a correlation to a set of related, fully insulated
    #   and uninsulated slab (sections), using the FullSlabInsulation function above.
    # Parameters:
    #   Rperim     = R-factor of insulation placed horizontally under the slab perimeter, h*ft2*F/Btu
    #   Rgap       = R-factor of insulation placed vertically between edge of slab & foundation wall, h*ft2*F/Btu
    #   Wperim     = Width of the perimeter insulation, ft.  Must be > 0.
    #   SlabWidth  = width (shorter dimension) of the slab, ft
    #   SlabLength = longer dimension of the slab, ft
    #   Carpet     = 1 if carpeted, 0 if not carpeted
    #   k          = thermal conductivity of the soil, Btu/h*ft*F
    # Constants:
    k2 = 0.329201  # 1st curve fit coefficient
    p = -0.327734  # 2nd curve fit coefficient
    q = 1.158418  # 3rd curve fit coefficient
    r = 0.144171  # 4th curve fit coefficient
    # Per Dennis email on 1/30/2015, a width = 0 appears to be some sort of singular point in the algorithm, 
    # which is based on subtracting whole-slab models and curve-fitting the interactions to match Winkelmann 
    # results.... So a recommended simple fix would be to set a minimum value of 1 foot (or maybe 2 feet) 
    # for the width of perimeter insulation.
    wperimeter = [wperim, 1].max
    # Related, fully insulated slabs:
    b = FullSlabInsulation(rperim, rgap, 2 * wperimeter, slabLength, carpet, k)
    c = FullSlabInsulation(0 ,0 , slabWidth, slabLength, carpet, k)
    d = FullSlabInsulation(0, 0, 2 * wperimeter, slabLength, carpet, k)
    # Trap zeros or small negatives before exponents are applied:
    dB = [d-b, 0.0000001].max
    cD = [c-d, 0.0000001].max
    wp = [wperimeter, 0.0000001].max
    # Result:
    perimeterConductance = b + c - d + k2 * (2 * wp / slabWidth) ** p * dB ** q * cD ** r 
    return perimeterConductance 
  end

  def FullSlabInsulation(rbottom, rgap, w, l, carpet, k)
    # Coded by Dennis Barley, March 2013.
    # This routine calculates the perimeter conductance for a slab with insulation 
    #   under the entire slab as well as gap insulation around the edge.
    # Parameters:
    #   Rbottom = R-factor of insulation placed horizontally under the entire slab, h*ft2*F/Btu
    #   Rgap    = R-factor of insulation placed vertically between edge of slab & foundation wall, h*ft2*F/Btu
    #   W       = width (shorter dimension) of the slab, ft.  Set to 28 to match Winkelmann analysis.
    #   L       = longer dimension of the slab, ft.  Set to 55 to match Winkelmann analysis. 
    #   Carpet  = 1 if carpeted, 0 if not carpeted
    #   k       = thermal conductivity of the soil, Btu/h*ft*F.  Set to 1 to match Winkelmann analysis.
    # Constants:
    zf = 0      # Depth of slab bottom, ft
    r0 = 1.47    # Thermal resistance of concrete slab and inside air film, h*ft2*F/Btu
    rca = 0      # R-value of carpet, if absent,  h*ft2*F/Btu
    rcp = 2.0      # R-value of carpet, if present, h*ft2*F/Btu
    rsea = 0.8860  # Effective resistance of slab edge if carpet is absent,  h*ft2*F/Btu
    rsep = 1.5260  # Effective resistance of slab edge if carpet is present, h*ft2*F/Btu
    t  = 4.0 / 12.0  # Thickness of slab: Assumed value if 4 inches; not a variable in the analysis, ft
    # Carpet factors:
    if carpet == 0
        rc  = rca
        rse = rsea
    elsif carpet == 1
        rc  = rcp
        rse = rsep
    end
            
    rother = rc + r0 + rbottom   # Thermal resistance other than the soil (from inside air to soil)
    # Ubottom:
    term1 = 2.0 * k / (Math::PI * w)
    term3 = zf / 2.0 + k * rother / Math::PI
    term2 = term3 + w / 2.0
    ubottom = term1 * Math::log(term2 / term3)
    pbottom = ubottom * (l * w) / (2.0 * (l + w))
    # Uedge:
    uedge = 1.0 / (rse + rgap)
    pedge = t * uedge
    # Result:
    perimeterConductance = pbottom + pedge
    return perimeterConductance
  end

  def ExteriorSlabInsulation(depth, rvalue, carpet)
    # Coded by Dennis Barley, April 2013.
    # This routine calculates the perimeter conductance for a slab with insulation 
    #   placed vertically outside the foundation.
    #   This is a correlation to Winkelmann results.
    # Parameters:
    #   Depth     = Depth to which insulation extends into the ground, ft
    #   Rvalue    = R-factor of insulation, h*ft2*F/Btu
    #   Carpet    = 1 if carpeted, 0 if not carpeted
    # Carpet factors:
    if carpet == 0
        a  = 9.02928
        b  = 8.20902
        e1 = 0.54383
        e2 = 0.74266
    elsif carpet == 1
        a  =  8.53957
        b  = 11.09168
        e1 =  0.57937
        e2 =  0.80699
    end
    perimeterConductance = a / (b + rvalue ** e1 * depth ** e2) 
    return perimeterConductance
  end
  
  def get_slab_floor_surfaces(model)
    surfaces = []
    model.getSpaces.each do |space|
        next if Geometry.space_is_unfinished(space)
        next if Geometry.space_is_below_grade(space)
        space.surfaces.each do |surface|
            next if surface.surfaceType.downcase != "floor"
            next if surface.outsideBoundaryCondition.downcase != "ground"
            surfaces << surface
        end
    end
    return surfaces
  end
  
end #end the measure

#this allows the measure to be use by the application
ProcessConstructionsFoundationsFloorsSlab.new.registerWithApplication