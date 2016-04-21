require "#{File.dirname(__FILE__)}/resources/schedules"
require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"

#start the measure
class ResidentialGasFireplace < OpenStudio::Ruleset::ModelUserScript
  
  def name
    return "Set Residential Gas Fireplace"
  end
  
  def description
    return "Adds (or replaces) a residential gas fireplace with the specified efficiency and schedule in the given space."
  end
  
  def modeler_description
    return "Since there is no Gas Fireplace object in OpenStudio/EnergyPlus, we look for a GasEquipment object with the name that denotes it is a residential gas fireplace. If one is found, it is replaced with the specified properties. Otherwise, a new such object is added to the model. Note: This measure requires the number of bedrooms/bathrooms to have already been assigned."
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new
    
	#make a double argument for Base Energy Use
	base_energy = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("base_energy")
	base_energy.setDisplayName("Base Energy Use")
    base_energy.setUnits("therm/yr")
	base_energy.setDescription("The national average (Building America Benchmark) energy use.")
	base_energy.setDefaultValue(60)
	args << base_energy

	#make a double argument for Energy Multiplier
	mult = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("mult")
	mult.setDisplayName("Energy Multiplier")
	mult.setDescription("Sets the annual energy use equal to the base energy use times this multiplier.")
	mult.setDefaultValue(1)
	args << mult
	
    #make a boolean argument for Scale Energy Use
	scale_energy = OpenStudio::Ruleset::OSArgument::makeBoolArgument("scale_energy",true)
	scale_energy.setDisplayName("Scale Energy Use")
	scale_energy.setDescription("If true, scales the energy use relative to a 3-bedroom, 1920 sqft house using the following equation: Fscale = (0.5 + 0.25 x Nbr/3 + 0.25 x FFA/1920) where Nbr is the number of bedrooms and FFA is the finished floor area.")
	scale_energy.setDefaultValue(true)
	args << scale_energy

	#Make a string argument for 24 weekday schedule values
	weekday_sch = OpenStudio::Ruleset::OSArgument::makeStringArgument("weekday_sch")
	weekday_sch.setDisplayName("Weekday schedule")
	weekday_sch.setDescription("Specify the 24-hour weekday schedule.")
	weekday_sch.setDefaultValue("0.044, 0.023, 0.019, 0.015, 0.016, 0.018, 0.026, 0.033, 0.033, 0.032, 0.033, 0.033, 0.032, 0.032, 0.032, 0.033, 0.045, 0.057, 0.066, 0.076, 0.081, 0.086, 0.075, 0.065")
	args << weekday_sch
    
	#Make a string argument for 24 weekend schedule values
	weekend_sch = OpenStudio::Ruleset::OSArgument::makeStringArgument("weekend_sch")
	weekend_sch.setDisplayName("Weekend schedule")
	weekend_sch.setDescription("Specify the 24-hour weekend schedule.")
	weekend_sch.setDefaultValue("0.044, 0.023, 0.019, 0.015, 0.016, 0.018, 0.026, 0.033, 0.033, 0.032, 0.033, 0.033, 0.032, 0.032, 0.032, 0.033, 0.045, 0.057, 0.066, 0.076, 0.081, 0.086, 0.075, 0.065")
	args << weekend_sch

	#Make a string argument for 12 monthly schedule values
	monthly_sch = OpenStudio::Ruleset::OSArgument::makeStringArgument("monthly_sch")
	monthly_sch.setDisplayName("Month schedule")
	monthly_sch.setDescription("Specify the 12-month schedule.")
	monthly_sch.setDefaultValue("1.154, 1.161, 1.013, 1.010, 1.013, 0.888, 0.883, 0.883, 0.888, 0.978, 0.974, 1.154")
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
    space.setDescription("Select the space where the fireplace is located.")
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
    base_energy = runner.getDoubleArgumentValue("base_energy",user_arguments)
	mult = runner.getDoubleArgumentValue("mult",user_arguments)
    scale_energy = runner.getBoolArgumentValue("scale_energy",user_arguments)
	weekday_sch = runner.getStringArgumentValue("weekday_sch",user_arguments)
	weekend_sch = runner.getStringArgumentValue("weekend_sch",user_arguments)
	monthly_sch = runner.getStringArgumentValue("monthly_sch",user_arguments)

    #check for valid inputs
    if base_energy < 0
		runner.registerError("Base energy use must be greater than or equal to 0.")
		return false
    end
    if mult < 0
		runner.registerError("Energy multiplier must be greater than or equal to 0.")
		return false
    end

	# Space
	space_r = runner.getStringArgumentValue("space",user_arguments)
    space = Geometry.get_space_from_string(model, space_r, runner)
    if space.nil?
        return false
    end

    # Get FFA and number of bedrooms/bathrooms
    ffa = Geometry.get_building_finished_floor_area(model, runner)
    if ffa.nil?
        return false
    end
    nbeds, nbaths = Geometry.get_bedrooms_bathrooms(model, runner)
    if nbeds.nil? or nbaths.nil?
        return false
    end
    
	#Calculate annual energy use
    ann_g = base_energy * mult # therm/yr
    
    if scale_energy
        #Scale energy use by num beds and floor area
        constant = ann_g/2
        nbr_coef = ann_g/4/3
        ffa_coef = ann_g/4/1920
        gg_ann_g = constant + nbr_coef * nbeds + ffa_coef * ffa # therm/yr
    else
        gg_ann_g = ann_g # therm/yr
    end

    #hard coded convective, radiative, latent, and lost fractions
    gg_lat = 0.1
    gg_rad = 0.3
    gg_conv = 0.2
    gg_lost = 1 - gg_lat - gg_rad - gg_conv
	
	obj_name = Constants.ObjectNameGasFireplace
	sch = MonthHourSchedule.new(weekday_sch, weekend_sch, monthly_sch, model, obj_name, runner)
	if not sch.validated?
		return false
	end
	design_level = sch.calcDesignLevelFromDailyTherm(gg_ann_g/365.0)
	
	#add fireplace to the space
	has_gg = 0
	replace_gg = 0
    space_equipments_g = space.gasEquipment
    space_equipments_g.each do |space_equipment_g| #check for an existing gas fireplace
        if space_equipment_g.gasEquipmentDefinition.name.get.to_s == obj_name
            has_gg = 1
            runner.registerInfo("There is already a gas fireplace. The existing gas fireplace will be replaced with the specified gas fireplace.")
            space_equipment_g.gasEquipmentDefinition.setDesignLevel(design_level)
            sch.setSchedule(space_equipment_g)
            replace_gg = 1
        end
    end

    if has_gg == 0 
        has_gg = 1
        
        #Add gas equipment for the fireplace
        gg_def = OpenStudio::Model::GasEquipmentDefinition.new(model)
        gg = OpenStudio::Model::GasEquipment.new(gg_def)
        gg.setName(obj_name)
        gg.setSpace(space)
        gg_def.setName(obj_name)
        gg_def.setDesignLevel(design_level)
        gg_def.setFractionRadiant(gg_rad)
        gg_def.setFractionLatent(gg_lat)
        gg_def.setFractionLost(gg_lost)
        sch.setSchedule(gg)
        
    end
	
    #reporting final condition of model
    runner.registerFinalCondition("A gas fireplace has been set with #{gg_ann_g.round} therms annual energy consumption.")
	
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ResidentialGasFireplace.new.registerWithApplication