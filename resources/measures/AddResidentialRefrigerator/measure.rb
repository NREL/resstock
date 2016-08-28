require "#{File.dirname(__FILE__)}/resources/schedules"
require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"

#start the measure
class ResidentialRefrigerator < OpenStudio::Ruleset::ModelUserScript
  
  def name
    return "Set Residential Refrigerator"
  end
  
  def description
    return "Adds (or replaces) a residential refrigerator with the specified efficiency, operation, and schedule. For multifamily buildings, the refrigerator can be set for all units of the building."
  end
  
  def modeler_description
    return "Since there is no Refrigerator object in OpenStudio/EnergyPlus, we look for an ElectricEquipment object with the name that denotes it is a residential refrigerator. If one is found, it is replaced with the specified properties. Otherwise, a new such object is added to the model."
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
    space_args << Constants.Auto
    spaces.each do |space|
        space_args << space.name.to_s
    end
    space = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("space", space_args, true)
    space.setDisplayName("Location")
    space.setDescription("Select the space where the refrigerator is located. '#{Constants.Auto}' will choose the lowest above-grade finished space available (e.g., first story living space), or a below-grade finished space as last resort. For multifamily buildings, '#{Constants.Auto}' will choose a space for each unit of the building.")
    space.setDefaultValue(Constants.Auto)
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
    
    # Get number of units
    num_units = Geometry.get_num_units(model, runner)
    if num_units.nil?
        return false
    end
    
    # Will we be setting multiple objects?
    set_multiple_objects = false
    if num_units > 1 and space_r == Constants.Auto
        set_multiple_objects = true
    end

	# Calculate fridge daily energy use
	fridge_ann = fridge_E*mult

    #hard coded convective, radiative, latent, and lost fractions
    fridge_lat = 0
    fridge_rad = 0
    fridge_conv = 1
    fridge_lost = 1 - fridge_lat - fridge_rad - fridge_conv

    tot_fridge_ann = 0
    last_space = nil
    sch = nil
    (1..num_units).to_a.each do |unit_num|
    
        # Get unit spaces
        _nbeds, _nbaths, unit_spaces = Geometry.get_unit_beds_baths_spaces(model, unit_num, runner)
        if unit_spaces.nil?
            runner.registerError("Could not determine the spaces associated with unit #{unit_num}.")
            return false
        end
        
        if unit_num == 1 and space_r != Constants.Auto
            # Append spaces not associated with a unit
            model.getSpaces.each do |space|
                next if Geometry.space_is_finished(space)
                unit_spaces << space
            end
        end
        
        # Get space
        space = Geometry.get_space_from_string(unit_spaces, space_r)
        next if space.nil?
        
        unit_obj_name = Constants.ObjectNameRefrigerator(unit_num)

        # Remove any existing refrigerator
        frg_removed = false
        space.electricEquipment.each do |space_equipment|
            if space_equipment.name.to_s == unit_obj_name
                space_equipment.remove
                frg_removed = true
            end
        end
        if frg_removed
            runner.registerInfo("Removed existing refrigerator from space #{space.name.to_s}.")
        end

        if fridge_ann > 0
        
            if sch.nil?
                # Create schedule
                sch = MonthWeekdayWeekendSchedule.new(model, runner, Constants.ObjectNameRefrigerator + " schedule", weekday_sch, weekend_sch, monthly_sch)
                if not sch.validated?
                    return false
                end
            end
            
            design_level = sch.calcDesignLevelFromDailykWh(fridge_ann/365.0)
            
            #Add electric equipment for the fridge
            frg_def = OpenStudio::Model::ElectricEquipmentDefinition.new(model)
            frg = OpenStudio::Model::ElectricEquipment.new(frg_def)
            frg.setName(unit_obj_name)
            frg.setSpace(space)
            frg_def.setName(unit_obj_name)
            frg_def.setDesignLevel(design_level)
            frg_def.setFractionRadiant(fridge_rad)
            frg_def.setFractionLatent(fridge_lat)
            frg_def.setFractionLost(fridge_lost)
            sch.setSchedule(frg)
            
            if set_multiple_objects
                # Report each assignment plus final condition
                runner.registerInfo("A refrigerator with #{fridge_ann.round} kWhs annual energy consumption has been assigned to space '#{space.name.to_s}'.")
            end
            
            tot_fridge_ann += fridge_ann
            last_space = space
        end

    end

    #reporting final condition of model
    if tot_fridge_ann > 0
        if set_multiple_objects
            runner.registerFinalCondition("The building has been assigned refrigerators totaling #{tot_fridge_ann.round} kWhs annual energy consumption across #{num_units} units.")
        else
            runner.registerFinalCondition("A refrigerator with #{tot_fridge_ann.round} kWhs annual energy consumption has been assigned to space '#{last_space.name.to_s}'.")
        end
    else
        runner.registerFinalCondition("No refrigerator has been assigned.")
    end
	
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ResidentialRefrigerator.new.registerWithApplication