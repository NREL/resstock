require "#{File.dirname(__FILE__)}/resources/schedules"
require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"

#start the measure
class ResidentialExtraRefrigerator < OpenStudio::Ruleset::ModelUserScript
  
  def name
    return "Set Residential Extra Refrigerator"
  end
  
  def description
    return "Adds (or replaces) a residential extra refrigerator with the specified efficiency, operation, and schedule in the given space."
  end
  
  def modeler_description
    return "Since there is no Extra Refrigerator object in OpenStudio/EnergyPlus, we look for an ElectricEquipment object with the name that denotes it is a residential extra refrigerator. If one is found, it is replaced with the specified properties. Otherwise, a new such object is added to the model."
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new
    
	#TODO: New argument for demand response for fridges (alternate schedules if automatic DR control is specified)
	
	#make a double argument for user defined fridge options
	fridge_E = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("fridge_E",true)
	fridge_E.setDisplayName("Rated Annual Consumption")
	fridge_E.setUnits("kWh/yr")
	fridge_E.setDescription("The EnergyGuide rated annual energy consumption for a refrigerator.")
	fridge_E.setDefaultValue(434)
	args << fridge_E
	
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
    space.setDescription("Select the space where the extra refrigerator is located")
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
    fridge_E = runner.getDoubleArgumentValue("fridge_E",user_arguments)
	mult = runner.getDoubleArgumentValue("mult",user_arguments)
	weekday_sch = runner.getStringArgumentValue("weekday_sch",user_arguments)
	weekend_sch = runner.getStringArgumentValue("weekend_sch",user_arguments)
	monthly_sch = runner.getStringArgumentValue("monthly_sch",user_arguments)
	space_r = runner.getStringArgumentValue("space",user_arguments)
	
	#check for valid inputs
	if fridge_E < 0
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

	#Calculate fridge daily energy use
	fridge_ann = fridge_E*mult

    #hard coded convective, radiative, latent, and lost fractions
    fridge_lat = 0
    fridge_rad = 0
    fridge_conv = 1
    fridge_lost = 1 - fridge_lat - fridge_rad - fridge_conv
	
	obj_name = Constants.ObjectNameExtraRefrigerator
	sch = MonthHourSchedule.new(weekday_sch, weekend_sch, monthly_sch, model, obj_name, runner)
	if not sch.validated?
		return false
	end
	design_level = sch.calcDesignLevelFromDailykWh(fridge_ann/365.0)
	
	#add extra refrigerator to the selected space
	has_fridge = 0
	replace_fridge = 0
    space_equipments = space.electricEquipment
    space_equipments.each do |space_equipment|
        if space_equipment.electricEquipmentDefinition.name.get.to_s == obj_name
            has_fridge = 1
            runner.registerInfo("This space already has an extra refrigerator, the existing extra refrigerator will be replaced with the specified extra refrigerator.")
            space_equipment.electricEquipmentDefinition.setDesignLevel(design_level)
            sch.setSchedule(space_equipment)
            replace_fridge = 1
        end
    end
    if has_fridge == 0 
        has_fridge = 1
        
        #Add electric equipment for the extra fridge
        frg_def = OpenStudio::Model::ElectricEquipmentDefinition.new(model)
        frg = OpenStudio::Model::ElectricEquipment.new(frg_def)
        frg.setName(obj_name)
        frg.setSpace(space)
        frg_def.setName(obj_name)
        frg_def.setDesignLevel(design_level)
        frg_def.setFractionRadiant(fridge_rad)
        frg_def.setFractionLatent(fridge_lat)
        frg_def.setFractionLost(fridge_lost)
        sch.setSchedule(frg)
        
    end
	
    #reporting final condition of model
    runner.registerFinalCondition("An extra fridge has been set with #{fridge_ann.round} kWhs annual energy consumption.")

    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ResidentialExtraRefrigerator.new.registerWithApplication