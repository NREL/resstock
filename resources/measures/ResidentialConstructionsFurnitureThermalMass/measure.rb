#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/geometry"

#start the measure
class ProcessThermalMassFurniture < OpenStudio::Measure::ModelMeasure

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Residential Furniture Thermal Mass"
  end
  
  def description
    return "Adds (or replaces) furniture mass to finished and unfinished spaces.#{Constants.WorkflowDescription}"
  end
  
  def modeler_description
    return "This measure creates constructions representing the internal mass of furniture in finished and unfinished spaces. If existing furniture mass objects are found, they are removed."
  end    
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    #make an argument for furniture area fraction
    area_fraction = OpenStudio::Measure::OSArgument::makeDoubleArgument("area_fraction",true)
    area_fraction.setDisplayName("Area Fraction")
    area_fraction.setDescription("Fraction of finished floor area covered by furniture.  Furniture intercepts a portion of radiation which would otherwise be distributed to floor surfaces, based on this variable.")
    area_fraction.setDefaultValue(0.4)
    args << area_fraction

    #make an argument for furniture mass
    mass = OpenStudio::Measure::OSArgument::makeDoubleArgument("mass",true)
    mass.setDisplayName("Mass")
    mass.setUnits("lb/ft^2")
    mass.setDescription("Furniture mass per finished floor area.")
    mass.setDefaultValue(8.0)
    args << mass
    
    #make an argument for furniture solar absorptance
    solar_abs = OpenStudio::Measure::OSArgument::makeDoubleArgument("solar_abs",true)
    solar_abs.setDisplayName("Solar Absorptance")
    solar_abs.setDescription("Solar absorptance of furnishings in finished spaces.")
    solar_abs.setDefaultValue(0.6)
    args << solar_abs

    #make an argument for finished furniture mass
    conductivity = OpenStudio::Measure::OSArgument::makeDoubleArgument("conductivity",true)
    conductivity.setDisplayName("Conductivity")
    conductivity.setUnits("Btu-in/h-ft^2-R")
    conductivity.setDescription("Conductivity of furnishings in finished spaces.")
    conductivity.setDefaultValue(BaseMaterial.Wood.k_in)
    args << conductivity

    #make an argument for finished furniture density
    density = OpenStudio::Measure::OSArgument::makeDoubleArgument("density",true)
    density.setDisplayName("Density")
    density.setUnits("lb/ft^3")
    density.setDescription("Density of furnishings in finished spaces.")
    density.setDefaultValue(40.0)
    args << density

    #make an argument for finished furniture specific heat
    specific_heat = OpenStudio::Measure::OSArgument::makeDoubleArgument("specific_heat",true)
    specific_heat.setDisplayName("Density")
    specific_heat.setUnits("Btu/lb-R")
    specific_heat.setDescription("Specific heat of furnishings in finished spaces.")
    specific_heat.setDefaultValue(BaseMaterial.Wood.cp)
    args << specific_heat

    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end
    
    # Finished spaces
    finishedAreaFraction = runner.getDoubleArgumentValue("area_fraction",user_arguments)
    finishedMass = runner.getDoubleArgumentValue("mass",user_arguments)
    finishedSolarAbsorptance = runner.getDoubleArgumentValue("solar_abs",user_arguments)
    finishedConductivity = runner.getDoubleArgumentValue("conductivity",user_arguments)
    finishedDensity = runner.getDoubleArgumentValue("density",user_arguments)
    finishedSpecHeat = runner.getDoubleArgumentValue("specific_heat",user_arguments)
    
    # Unfinished basements
    unfinBasementAreaFraction = 0.4
    unfinBasementMass = 8.0
    unfinBasementSolarAbsorptance = 0.6
    unfinBasementConductivity = BaseMaterial.Wood.k_in
    unfinBasementDensity = 40.0
    unfinBasementSpecHeat = BaseMaterial.Wood.cp

    # Garages
    garageAreaFraction = 0.1
    garageMass = 2.0
    garageSolarAbsorptance = 0.6
    garageConductivity = BaseMaterial.Wood.k_in
    garageDensity = 40.0
    garageSpecHeat = BaseMaterial.Wood.cp
    
    # Remove any existing furniture mass.
    furniture_removed = false
    model.getInternalMasss.each do |im|
        next if not im.name.get.include?(Constants.ObjectNameFurniture)
        md = im.internalMassDefinition
        constr = nil
        if md.construction.is_initialized
            constr = md.construction.get
            if constr.to_LayeredConstruction.is_initialized
                constr.to_LayeredConstruction.get.layers.each do |mat|
                    mat.remove
                end
            end
            constr.remove
        end
        im.remove
        md.remove
        furniture_removed = true
    end
    if furniture_removed
        runner.registerInfo("Removed existing furniture mass.")
    end
    
    # Add user-specified furniture mass
    finished_spaces = Geometry.get_finished_spaces(model.getSpaces)
    unfinished_basement_spaces = Geometry.get_unfinished_basement_spaces(model.getSpaces)
    garage_spaces = Geometry.get_garage_spaces(model.getSpaces, model)
    model.getSpaces.each do |space|
        furnAreaFraction = nil
        if finished_spaces.include?(space)
            furnAreaFraction = finishedAreaFraction
            furnMass = finishedMass
            furnSolarAbsorptance = finishedSolarAbsorptance
            furnConductivity = finishedConductivity
            furnDensity = finishedDensity
            furnSpecHeat = finishedSpecHeat
        elsif unfinished_basement_spaces.include?(space)
            furnAreaFraction = unfinBasementAreaFraction
            furnMass = unfinBasementMass
            furnSolarAbsorptance = unfinBasementSolarAbsorptance
            furnConductivity = unfinBasementConductivity
            furnDensity = unfinBasementDensity
            furnSpecHeat = unfinBasementSpecHeat
        elsif garage_spaces.include?(space)
            furnAreaFraction = garageAreaFraction
            furnMass = garageMass
            furnSolarAbsorptance = garageSolarAbsorptance
            furnConductivity = garageConductivity
            furnDensity = garageDensity
            furnSpecHeat = garageSpecHeat
        end
        
        next if furnAreaFraction.nil?
        next if furnAreaFraction <= 0
        next if space.floorArea <= 0
        
        mat_obj_name_space = "#{Constants.ObjectNameFurniture} material #{space.name.to_s}"
        constr_obj_name_space = "#{Constants.ObjectNameFurniture} construction #{space.name.to_s}"
        mass_obj_name_space = "#{Constants.ObjectNameFurniture} mass #{space.name.to_s}"
        
        furnThickness = furnMass / (furnDensity * furnAreaFraction) # ft
        
        fm = OpenStudio::Model::StandardOpaqueMaterial.new(model)
        fm.setName(mat_obj_name_space)
        fm.setRoughness("Rough")
        fm.setThickness(OpenStudio::convert(furnThickness,"ft","m").get)
        fm.setConductivity(OpenStudio::convert(furnConductivity,"Btu*in/hr*ft^2*R","W/m*K").get)
        fm.setDensity(OpenStudio::convert(furnDensity,"lb/ft^3","kg/m^3").get)
        fm.setSpecificHeat(OpenStudio::convert(furnSpecHeat,"Btu/lb*R","J/kg*K").get)
        fm.setThermalAbsorptance(0.9)
        fm.setSolarAbsorptance(furnSolarAbsorptance)
        fm.setVisibleAbsorptance(0.1)

        f = OpenStudio::Model::Construction.new([fm])
        f.setName(constr_obj_name_space)      

        md = OpenStudio::Model::InternalMassDefinition.new(model)
        md.setName(mass_obj_name_space)
        md.setConstruction(f)
        md.setSurfaceArea(furnAreaFraction * space.floorArea)
        
        im = OpenStudio::Model::InternalMass.new(md)
        im.setName(mass_obj_name_space)
        im.setSpace(space)
        
        runner.registerInfo("Assigned internal mass object '#{mass_obj_name_space}' to space '#{space.name}'.")
    end
    
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ProcessThermalMassFurniture.new.registerWithApplication