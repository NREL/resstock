# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/measures/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"
require "#{File.dirname(__FILE__)}/resources/util"

# start the measure
class AddResidentialBedroomsAndBathrooms < OpenStudio::Ruleset::ModelUserScript

  # human readable name
  def name
    return "Set Residential Number of Beds and Baths"
  end

  # human readable description
  def description
    return "Sets the number of bedrooms and bathrooms in the building. For multifamily buildings, the bedrooms/bathrooms can be set for all units of the building."
  end

  # human readable description of modeling approach
  def modeler_description
    return "Sets (or replaces) dummy ElectricEquipment objects that store the number of bedrooms and bathrooms associated with the model."
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new		

    #make a string argument for number of bedrooms
    num_br = OpenStudio::Ruleset::OSArgument::makeStringArgument("Num_Br", false)
    num_br.setDisplayName("Number of Bedrooms")
    num_br.setDescription("Specify the number of bedrooms. For a multifamily building, specify one value for all units or a comma-separated set of values (in the correct order) for each unit. Used to determine the energy usage of appliances and plug loads, hot water usage, mechanical ventilation rate, etc.")
    num_br.setDefaultValue("3")
    args << num_br
    
    #make a string argument for number of bathrooms
    num_ba = OpenStudio::Ruleset::OSArgument::makeStringArgument("Num_Ba", false)
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
	
    num_br = runner.getStringArgumentValue("Num_Br", user_arguments).split(",").map(&:strip)
    num_ba = runner.getStringArgumentValue("Num_Ba", user_arguments).split(",").map(&:strip)
    
    num_units = Geometry.get_num_units(model, runner)
    if num_units.nil?
      return false
    end
        
    #error checking
    if not num_br.all? {|x| HelperMethods.valid_float?(x)}
      runner.registerError("Number of bedrooms must be a numerical value.")
      return false
    else
      num_br = num_br.map(&:to_f)
    end
    if not num_ba.all? {|x| HelperMethods.valid_float?(x)}
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
    if num_br.length > 1 and num_br.length != num_units
      runner.registerError("Number of bedroom elements specified inconsistent with number of multifamily units defined in the model.")
      return false
    end
    if num_ba.length > 1 and num_ba.length != num_units
      runner.registerError("Number of bathroom elements specified inconsistent with number of multifamily units defined in the model.")
      return false
    end    
    
    if num_units > 1 and num_br.length == 1
      if num_br.length == 1
        num_br = Array.new(num_units, num_br[0])
      end
      if num_ba.length == 1
        num_ba = Array.new(num_units, num_ba[0])
      end    
    end
    
    # Change to 1-based arrays for simplification
    num_br.unshift(nil)
    num_ba.unshift(nil)
      
    # Update number of bedrooms/bathrooms
    total_num_br = 0
    total_num_ba = 0    
    (1..num_units).to_a.each do |unit_num|

      _nbeds, _nbaths, unit_spaces = Geometry.get_unit_beds_baths_spaces(model, unit_num, runner)
      if unit_spaces.nil?
          runner.registerError("Could not determine the spaces associated with unit #{unit_num}.")
          return false
      end

      num_br[unit_num] = num_br[unit_num].round(2).to_s
      num_ba[unit_num] = num_ba[unit_num].round(2).to_s
      Geometry.set_unit_beds_baths_spaces(model, unit_num, unit_spaces, num_br[unit_num], num_ba[unit_num])
      if num_units > 1
        runner.registerInfo("Unit #{unit_num} has been assigned #{num_br[unit_num]} bedroom(s) and #{num_ba[unit_num]} bathroom(s).")
      end
      
      total_num_br += num_br[unit_num].to_f
      total_num_ba += num_ba[unit_num].to_f

    end
    
    #reporting final condition of model
    units_str = ""
    if num_units > 1
      units_str = " across #{num_units} units"
    end
    runner.registerFinalCondition("The building has been assigned #{total_num_br.round(2)} bedroom(s) and #{total_num_ba.round(2)} bathroom(s)#{units_str}.")

    return true

  end
  
end

# register the measure to be used by the application
AddResidentialBedroomsAndBathrooms.new.registerWithApplication
