require "#{File.dirname(__FILE__)}/resources/schedules"
require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"

#start the measure
class ResidentialFreezer < OpenStudio::Ruleset::ModelUserScript
  
  def name
    return "Set Residential Freezer"
  end
  
  def description
    return "Adds (or replaces) a residential freezer with the specified efficiency, operation, and schedule in the given space."
  end
  
  def modeler_description
    return "Since there is no Freezer object in OpenStudio/EnergyPlus, we look for an ElectricEquipment object with the name that denotes it is a residential freezer. If one is found, it is replaced with the specified properties. Otherwise, a new such object is added to the model."
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new
    
	#TODO: New argument for demand response for freezers (alternate schedules if automatic DR control is specified)
	
	#make a double argument for user defined freezer options
	freezer_E = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("freezer_E",true)
	freezer_E.setDisplayName("Rated Annual Consumption")
	freezer_E.setUnits("kWh/yr")
	freezer_E.setDescription("The EnergyGuide rated annual energy consumption for a freezer.")
	freezer_E.setDefaultValue(935)
	args << freezer_E
	
	#make a double argument for Occupancy Energy Multiplier
	mult = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("mult")
	mult.setDisplayName("Occupancy Energy Multiplier")
	mult.setDescription("Appliance energy use is multiplied by this factor to account for occupancy usage that differs from the national average.")
	mult.setDefaultValue(1)
	args << mult
	
	#Make a string argument for 24 weekday schedule values
	weekday_sch = OpenStudio::Ruleset::OSArgument::makeStringArgument("weekday_sch")
	weekday_sch.setDisplayName("Weekday schedule")
	weekday_sch.setDescription("Specify the 24-hour weekday schedule.")
	weekday_sch.setDefaultValue("0.040, 0.039, 0.038, 0.037, 0.036, 0.036, 0.038, 0.040, 0.041, 0.041, 0.040, 0.040, 0.042, 0.042, 0.042, 0.041, 0.044, 0.048, 0.050, 0.048, 0.047, 0.046, 0.044, 0.041")
	args << weekday_sch
    
	#Make a string argument for 24 weekend schedule values
	weekend_sch = OpenStudio::Ruleset::OSArgument::makeStringArgument("weekend_sch")
	weekend_sch.setDisplayName("Weekend schedule")
	weekend_sch.setDescription("Specify the 24-hour weekend schedule.")
	weekend_sch.setDefaultValue("0.040, 0.039, 0.038, 0.037, 0.036, 0.036, 0.038, 0.040, 0.041, 0.041, 0.040, 0.040, 0.042, 0.042, 0.042, 0.041, 0.044, 0.048, 0.050, 0.048, 0.047, 0.046, 0.044, 0.041")
	args << weekend_sch

	#Make a string argument for 12 monthly schedule values
	monthly_sch = OpenStudio::Ruleset::OSArgument::makeStringArgument("monthly_sch")
	monthly_sch.setDisplayName("Month schedule")
	monthly_sch.setDescription("Specify the 12-month schedule.")
	monthly_sch.setDefaultValue("0.837, 0.835, 1.084, 1.084, 1.084, 1.096, 1.096, 1.096, 1.096, 0.931, 0.925, 0.837")
	args << monthly_sch

    #make a choice argument for space
    spaces = model.getSpaces
    space_args = OpenStudio::StringVector.new
    spaces.each do |space|
        space_args << space.name.to_s
    end
    if space_args.empty?
        space_args << Constants.LivingSpace(1)
    end
    space = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("space", space_args, true)
    space.setDisplayName("Location")
    space.setDescription("Select the space where the freezer is located")
    if space_args.include?(Constants.LivingSpace(1))
        space.setDefaultValue(Constants.LivingSpace(1))
    end
    args << space

    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end
	
    #assign the user inputs to variables
    freezer_E = runner.getDoubleArgumentValue("freezer_E",user_arguments)
	mult = runner.getDoubleArgumentValue("mult",user_arguments)
	weekday_sch = runner.getStringArgumentValue("weekday_sch",user_arguments)
	weekend_sch = runner.getStringArgumentValue("weekend_sch",user_arguments)
	monthly_sch = runner.getStringArgumentValue("monthly_sch",user_arguments)
	space_r = runner.getStringArgumentValue("space",user_arguments)
	
	#check for valid inputs
	if freezer_E < 0
		runner.registerError("Rated annual consumption must be greater than or equal to 0.")
		return false
	end
    if mult < 0
		runner.registerError("Occupancy energy multiplier must be greater than or equal to 0.")
		return false
    end
	
    #Get space
    space = Geometry.get_space_from_string(model, space_r, runner)
    if space.nil?
        return false
    end

	#Calculate freezer daily energy use
	freezer_ann = freezer_E*mult

    #hard coded convective, radiative, latent, and lost fractions
    freezer_lat = 0
    freezer_rad = 0
    freezer_conv = 1
    freezer_lost = 1 - freezer_lat - freezer_rad - freezer_conv
	
	obj_name = Constants.ObjectNameFreezer
	sch = MonthWeekdayWeekendSchedule.new(weekday_sch, weekend_sch, monthly_sch, model, obj_name, runner)
	if not sch.validated?
		return false
	end
	design_level = sch.calcDesignLevelFromDailykWh(freezer_ann/365.0)
	
    # Remove any existing freezer
    frz_removed = false
    space.electricEquipment.each do |space_equipment|
        if space_equipment.name.to_s == obj_name
            space_equipment.remove
            frz_removed = true
        end
    end
    if frz_removed
        runner.registerInfo("Removed existing freezer.")
    end
    
    #Add electric equipment for the freezer
    frz_def = OpenStudio::Model::ElectricEquipmentDefinition.new(model)
    frz = OpenStudio::Model::ElectricEquipment.new(frz_def)
    frz.setName(obj_name)
    frz.setSpace(space)
    frz_def.setName(obj_name)
    frz_def.setDesignLevel(design_level)
    frz_def.setFractionRadiant(freezer_rad)
    frz_def.setFractionLatent(freezer_lat)
    frz_def.setFractionLost(freezer_lost)
    sch.setSchedule(frz)
	
    #reporting final condition of model
    runner.registerFinalCondition("A freezer has been set with #{freezer_ann.round} kWhs annual energy consumption.")
	
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ResidentialFreezer.new.registerWithApplication