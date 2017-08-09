# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/measures/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"
require "#{File.dirname(__FILE__)}/resources/util"

# start the measure
class AddResidentialBedroomsAndBathrooms < OpenStudio::Measure::ModelMeasure

  # human readable name
  def name
    return "Set Residential Number of Beds and Baths"
  end

  # human readable description
  def description
    return "Sets the number of bedrooms and bathrooms in the building. For multifamily buildings, the bedrooms/bathrooms can be set for all units of the building.#{Constants.WorkflowDescription}"
  end

  # human readable description of modeling approach
  def modeler_description
    return "Sets (or replaces) dummy ElectricEquipment objects that store the number of bedrooms and bathrooms associated with the model."
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new        

    #make a string argument for number of bedrooms
    num_br = OpenStudio::Measure::OSArgument::makeStringArgument("num_bedrooms", false)
    num_br.setDisplayName("Number of Bedrooms")
    num_br.setDescription("Specify the number of bedrooms. For a multifamily building, specify one value for all units or a comma-separated set of values (in the correct order) for each unit. Used to determine the energy usage of appliances and plug loads, hot water usage, mechanical ventilation rate, etc.")
    num_br.setDefaultValue("3")
    args << num_br
    
    #make a string argument for number of bathrooms
    num_ba = OpenStudio::Measure::OSArgument::makeStringArgument("num_bathrooms", false)
    num_ba.setDisplayName("Number of Bathrooms")
    num_ba.setDescription("Specify the number of bathrooms. For a multifamily building, specify one value for all units or a comma-separated set of values (in the correct order) for each unit. Used to determine the hot water usage, etc.")
    num_ba.setDefaultValue("2")
    args << num_ba
    
    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end
    
    num_br = runner.getStringArgumentValue("num_bedrooms", user_arguments).split(",").map(&:strip)
    num_ba = runner.getStringArgumentValue("num_bathrooms", user_arguments).split(",").map(&:strip)
    
    # Get building units
    units = Geometry.get_building_units(model, runner)
    if units.nil?
        return false
    end
    
    #error checking
    if not num_br.all? {|x| MathTools.valid_float?(x)}
      runner.registerError("Number of bedrooms must be a numerical value.")
      return false
    else
      num_br = num_br.map(&:to_f)
    end
    if not num_ba.all? {|x| MathTools.valid_float?(x)}
      runner.registerError("Number of bathrooms must be a numerical value.")
      return false
    else
      num_ba = num_ba.map(&:to_f)
    end
    if num_br.any? {|x| x <= 0 or x % 1 != 0}
      runner.registerError("Number of bedrooms must be a positive integer.")
      return false
    end
    if num_ba.any? {|x| x <= 0 or x % 0.25 != 0}
      runner.registerError("Number of bathrooms must be a positive multiple of 0.25.")
      return false
    end
    if num_br.length > 1 and num_ba.length > 1 and num_br.length != num_ba.length
      runner.registerError("Number of bedroom elements specified inconsistent with number of bathroom elements specified.")
      return false
    end
    if num_br.length > 1 and num_br.length != units.size
      runner.registerError("Number of bedroom elements specified inconsistent with number of multifamily units defined in the model.")
      return false
    end
    if num_ba.length > 1 and num_ba.length != units.size
      runner.registerError("Number of bathroom elements specified inconsistent with number of multifamily units defined in the model.")
      return false
    end    
    
    if units.size > 1 and num_br.length == 1
      if num_br.length == 1
        num_br = Array.new(units.size, num_br[0])
      end
      if num_ba.length == 1
        num_ba = Array.new(units.size, num_ba[0])
      end    
    end
    
    # Update number of bedrooms/bathrooms
    total_num_br = 0
    total_num_ba = 0
    units.each_with_index do |unit, unit_index|
      
      num_br[unit_index] = num_br[unit_index].to_i
      num_ba[unit_index] = num_ba[unit_index].to_f
      
      unit.setFeature(Constants.BuildingUnitFeatureNumBedrooms, num_br[unit_index])
      unit.setFeature(Constants.BuildingUnitFeatureNumBathrooms, num_ba[unit_index])
      
      if units.size > 1
        runner.registerInfo("Unit '#{unit_index}' has been assigned #{num_br[unit_index].to_s} bedroom(s) and #{num_ba[unit_index].round(2).to_s} bathroom(s).")
      end
      
      total_num_br += num_br[unit_index]
      total_num_ba += num_ba[unit_index]

    end
    
    #reporting final condition of model
    units_str = ""
    if units.size > 1
      units_str = " across #{units.size} units"
    end
    runner.registerFinalCondition("The building has been assigned #{total_num_br.to_s} bedroom(s) and #{total_num_ba.round(2).to_s} bathroom(s)#{units_str}.")

    return true

  end
  
end

# register the measure to be used by the application
AddResidentialBedroomsAndBathrooms.new.registerWithApplication
