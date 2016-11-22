#see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"

#start the measure
class ProcessConstructionsUninsulatedSurfaces < OpenStudio::Ruleset::ModelUserScript

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Residential Uninsulated Surfaces"
  end
  
  def description
    return "This measure assigns an uninsulated constructions to 1) exterior surfaces adjacent to unfinished space, 2) surfaces between two unfinished (or two finished) spaces, or 3) adiabatic surfaces."
  end
  
  def modeler_description
    return "Calculates and assigns material layer properties of uninsulated constructions for surfaces that are not typically insulated."
  end   
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # Above-grade walls between unfinished space and outdoors
    ext_wall_surfaces = []
    model.getSpaces.each do |space|
        next if Geometry.space_is_finished(space)
        next if Geometry.space_is_below_grade(space)
        space.surfaces.each do |surface|
            next if surface.surfaceType.downcase != "wall"
            next if surface.outsideBoundaryCondition.downcase != "outdoors"
            ext_wall_surfaces << surface
        end
    end
    
    # Walls between two finished spaces
    finished_wall_surfaces = []
    model.getSpaces.each do |space|
        next if Geometry.space_is_unfinished(space)
        space.surfaces.each do |surface|
            next if surface.surfaceType.downcase != "wall"
            next if not surface.adjacentSurface.is_initialized
            next if not surface.adjacentSurface.get.space.is_initialized
            adjacent_space = surface.adjacentSurface.get.space.get
            next if Geometry.space_is_unfinished(adjacent_space)
            finished_wall_surfaces << surface
        end
    end
    
    # Walls between two unfinished spaces
    unfinished_wall_surfaces = []
    model.getSpaces.each do |space|
        next if Geometry.space_is_finished(space)
        space.surfaces.each do |surface|
            next if surface.surfaceType.downcase != "wall"
            next if not surface.adjacentSurface.is_initialized
            next if not surface.adjacentSurface.get.space.is_initialized
            adjacent_space = surface.adjacentSurface.get.space.get
            next if Geometry.space_is_finished(adjacent_space)
            unfinished_wall_surfaces << surface
        end
    end
    
    # Floors between two finished spaces
    finished_floor_surfaces = []
    model.getSpaces.each do |space|
        next if Geometry.space_is_unfinished(space)
        space.surfaces.each do |surface|
            next if surface.surfaceType.downcase != "floor"
            next if not surface.adjacentSurface.is_initialized
            next if not surface.adjacentSurface.get.space.is_initialized
            adjacent_space = surface.adjacentSurface.get.space.get
            next if Geometry.space_is_unfinished(adjacent_space)
            # Floor between two finished spaces
            finished_floor_surfaces << surface
        end
    end
    
    # Floors between two unfinished spaces
    unfinished_floor_surfaces = []
    model.getSpaces.each do |space|
        next if Geometry.space_is_finished(space)
        space.surfaces.each do |surface|
            next if surface.surfaceType.downcase != "floor"
            next if not surface.adjacentSurface.is_initialized
            next if not surface.adjacentSurface.get.space.is_initialized
            adjacent_space = surface.adjacentSurface.get.space.get
            next if Geometry.space_is_finished(adjacent_space)
            # Floor between two unfinished spaces
            unfinished_floor_surfaces << surface
        end
    end
    
    # Slabs below unfinished space
    slab_surfaces = []
    model.getSpaces.each do |space|
        next if Geometry.space_is_finished(space)
        next if Geometry.space_is_below_grade(space)
        space.surfaces.each do |surface|
            next if surface.surfaceType.downcase != "floor"
            next if surface.outsideBoundaryCondition.downcase != "ground"
            # Floors between above-grade unfinished space and ground
            slab_surfaces << surface
        end
    end
    
    # Roofs above unfinished space
    roof_spaces = Geometry.get_non_attic_unfinished_roof_spaces(model.getSpaces, model)
    roof_surfaces = []
    roof_spaces.each do |space|
        space.surfaces.each do |surface|
            next if surface.surfaceType.downcase != "roofceiling"
            next if surface.outsideBoundaryCondition.downcase != "outdoors"
            roof_surfaces << surface
        end
    end
    
    # Adiabatic surfaces (assign construction for mass effects)
    model.getSpaces.each do |space|
        space.surfaces.each do |surface|
            next if surface.outsideBoundaryCondition.downcase != "adiabatic"
            if surface.surfaceType.downcase == "wall"
                if Geometry.space_is_finished(space)
                    finished_wall_surfaces << surface
                else
                    unfinished_wall_surfaces << surface
                end
            elsif surface.surfaceType.downcase == "roofceiling"
                roof_surfaces << surface
                roof_spaces << space
            elsif surface.surfaceType.downcase == "floor"
                if Geometry.space_is_finished(space)
                    finished_floor_surfaces << surface
                else
                    unfinished_floor_surfaces << surface
                end
            end
        end
    end

    # Continue if no applicable surfaces
    if ext_wall_surfaces.empty? and finished_floor_surfaces.empty? and unfinished_floor_surfaces.empty? and slab_surfaces.empty? and roof_surfaces.empty? and finished_wall_surfaces.empty? and unfinished_wall_surfaces.empty?
        runner.registerAsNotApplicable("Measure not applied because no applicable surfaces were found.")
        return true
    end    

    # Process the exterior walls
    if not ext_wall_surfaces.empty?
        # Define materials
        mat_cavity = Material.AirCavityClosed(Material.Stud2x4.thick_in)
        mat_framing = Material.new(name=nil, thick_in=Material.Stud2x4.thick_in, mat_base=BaseMaterial.Wood)
        
        # Set paths
        path_fracs = [Constants.DefaultFramingFactorInterior, 1 - Constants.DefaultFramingFactorInterior]
        
        # Define construction
        wall = Construction.new(path_fracs)
        wall.add_layer(Material.AirFilmVertical, false)
        wall.add_layer([mat_framing, mat_cavity], true, "ExtStudAndAirWall")
        wall.add_layer(Material.DefaultWallSheathing, true)
        wall.add_layer(Material.DefaultExteriorFinish, false) # exterior finish added in separate measure
        wall.add_layer(Material.AirFilmOutside, false)

        # Create and assign construction to wall surfaces
        if not wall.create_and_assign_constructions(ext_wall_surfaces, runner, model, name="ExtUninsUnfinWall")
            return false
        end
    end
    
    # Process the finished/unfinished walls
    if not finished_wall_surfaces.empty? or not unfinished_wall_surfaces.empty?
        # Define materials
        mat_cavity = Material.AirCavityClosed(Material.Stud2x4.thick_in)
        mat_framing = Material.new(name=nil, thick_in=Material.Stud2x4.thick_in, mat_base=BaseMaterial.Wood)
        
        # Set paths
        path_fracs = [Constants.DefaultFramingFactorInterior, 1 - Constants.DefaultFramingFactorInterior]
        
        # Define construction
        wall = Construction.new(path_fracs)
        wall.add_layer([mat_framing, mat_cavity], true, "IntStudAndAirWall")
    
        if not finished_wall_surfaces.empty?
            # Create and apply construction to finished surfaces
            if not wall.create_and_assign_constructions(finished_wall_surfaces, runner, model, name="FinUninsFinWall")
                return false
            end
        end
        
        if not unfinished_wall_surfaces.empty?
            # Create and apply construction to unfinished surfaces
            if not wall.create_and_assign_constructions(unfinished_wall_surfaces, runner, model, name="UnfinUninsUnfinWall")
                return false
            end
        end
    end
    
    # Process the floors
    if not finished_floor_surfaces.empty? or not unfinished_floor_surfaces.empty?
        # Define materials
        mat_cavity = Material.AirCavityClosed(Material.Stud2x6.thick_in)
        mat_framing = Material.new(name=nil, thick_in=Material.Stud2x6.thick_in, mat_base=BaseMaterial.Wood)
        
        # Set paths
        path_fracs = [Constants.DefaultFramingFactorFloor, 1 - Constants.DefaultFramingFactorFloor]

        if not finished_floor_surfaces.empty?
            # Define construction
            fin_floor = Construction.new(path_fracs)
            fin_floor.add_layer(Material.AirFilmFloorAverage, false)
            fin_floor.add_layer(Material.DefaultCeilingMass, false) # thermal mass added in separate measure
            fin_floor.add_layer([mat_framing, mat_cavity], true, "FinStudAndAirFloor")
            fin_floor.add_layer(Material.DefaultFloorSheathing, false) # sheathing added in separate measure
            fin_floor.add_layer(Material.DefaultFloorMass, false) # thermal mass added in separate measure
            fin_floor.add_layer(Material.DefaultFloorCovering, false) # floor covering added in separate measure
            fin_floor.add_layer(Material.AirFilmFloorAverage, false)

            # Create and apply construction to finished surfaces
            if not fin_floor.create_and_assign_constructions(finished_floor_surfaces, runner, model, name="FinUninsFinFloor")
                return false
            end
        end
        
        if not unfinished_floor_surfaces.empty?
            # Define construction
            unfin_floor = Construction.new(path_fracs)
            unfin_floor.add_layer(Material.AirFilmFloorAverage, false)
            unfin_floor.add_layer([mat_framing, mat_cavity], true, "UnfinStudAndAirFloor")
            unfin_floor.add_layer(Material.DefaultFloorSheathing, false) # sheathing added in separate measure
            unfin_floor.add_layer(Material.AirFilmFloorAverage, false)

            # Create and apply construction to unfinished surfaces
            if not unfin_floor.create_and_assign_constructions(unfinished_floor_surfaces, runner, model, name="UnfinUninsUnfinFloor")
                return false
            end
        end
    end
    
    # Process the slabs
    if not slab_surfaces.empty?
        # Define construction
        slab = Construction.new([1.0])
        slab.add_layer(Material.Concrete4in, true)
        slab.add_layer(Material.Soil12in, true)
        slab.add_layer(SimpleMaterial.Adiabatic, true)
        
        # Create and assign construction to surfaces
        if not slab.create_and_assign_constructions(slab_surfaces, runner, model, name="GrndUninsUnfinFloor")
            return false
        end
    end
    
    # Process the roofs
    if not roof_surfaces.empty?
        # Define materials
        mat_cavity = Material.AirCavityOpen(Material.Stud2x4.thick_in)
        mat_framing = Material.new(name=nil, thick_in=Material.Stud2x4.thick_in, mat_base=BaseMaterial.Wood)

        # Set paths
        path_fracs = [Constants.DefaultFramingFactorCeiling, 1 - Constants.DefaultFramingFactorCeiling]
        
        # Define construction
        roof_const = Construction.new(path_fracs)
        roof_const.add_layer(Material.AirFilmOutside, false)
        roof_const.add_layer(Material.DefaultRoofMaterial, false) # roof material added in separate measure
        roof_const.add_layer(Material.DefaultRoofSheathing, false) # sheathing added in separate measure
        roof_const.add_layer([mat_framing, mat_cavity], true, "StudAndAirRoof")
        roof_const.add_layer(Material.AirFilmRoof(Geometry.calculate_avg_roof_pitch(roof_spaces)), false)

        # Create and assign construction to surfaces
        if not roof_const.create_and_assign_constructions(roof_surfaces, runner, model, name="UnfinUninsExtRoof")
            return false
        end
    end
    
    # Remove any constructions/materials that aren't used
    HelperMethods.remove_unused_constructions_and_materials(model, runner)
	
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ProcessConstructionsUninsulatedSurfaces.new.registerWithApplication