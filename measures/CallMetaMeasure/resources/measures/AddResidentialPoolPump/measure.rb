require "#{File.dirname(__FILE__)}/resources/schedules"
require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"

#start the measure
class ResidentialPoolPump < OpenStudio::Ruleset::ModelUserScript
  
  def name
    return "Set Residential Pool Pump"
  end
  
  def description
    return "Adds (or replaces) a residential pool pump with the specified efficiency and schedule. The pool is assumed to be outdoors."
  end
  
  def modeler_description
    return "Since there is no Pool Pump object in OpenStudio/EnergyPlus, we look for an ElectricEquipment object with the name that denotes it is a residential pool pump. If one is found, it is replaced with the specified properties. Otherwise, a new such object is added to the model. Note: This measure requires the number of bedrooms/bathrooms to have already been assigned."
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new
    
	#TODO: New argument for demand response for pool pumps (alternate schedules if automatic DR control is specified)
	
	#make a double argument for Base Energy Use
	base_energy = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("base_energy")
	base_energy.setDisplayName("Base Energy Use")
    base_energy.setUnits("kWh/yr")
	base_energy.setDescription("The national average (Building America Benchmark) energy use.")
	base_energy.setDefaultValue(2250)
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
	weekday_sch.setDefaultValue("0.003, 0.003, 0.003, 0.004, 0.008, 0.015, 0.026, 0.044, 0.084, 0.121, 0.127, 0.121, 0.120, 0.090, 0.075, 0.061, 0.037, 0.023, 0.013, 0.008, 0.004, 0.003, 0.003, 0.003")
	args << weekday_sch
    
	#Make a string argument for 24 weekend schedule values
	weekend_sch = OpenStudio::Ruleset::OSArgument::makeStringArgument("weekend_sch")
	weekend_sch.setDisplayName("Weekend schedule")
	weekend_sch.setDescription("Specify the 24-hour weekend schedule.")
	weekend_sch.setDefaultValue("0.003, 0.003, 0.003, 0.004, 0.008, 0.015, 0.026, 0.044, 0.084, 0.121, 0.127, 0.121, 0.120, 0.090, 0.075, 0.061, 0.037, 0.023, 0.013, 0.008, 0.004, 0.003, 0.003, 0.003")
	args << weekend_sch

	#Make a string argument for 12 monthly schedule values
	monthly_sch = OpenStudio::Ruleset::OSArgument::makeStringArgument("monthly_sch")
	monthly_sch.setDisplayName("Month schedule")
	monthly_sch.setDescription("Specify the 12-month schedule.")
	monthly_sch.setDefaultValue("1.154, 1.161, 1.013, 1.010, 1.013, 0.888, 0.883, 0.883, 0.888, 0.978, 0.974, 1.154")
	args << monthly_sch

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
    ann_elec = base_energy * mult # kWh/yr
    
    if scale_energy
        #Scale energy use by num beds and floor area
        constant = ann_elec/2
        nbr_coef = ann_elec/4/3
        ffa_coef = ann_elec/4/1920
        pp_ann = constant + nbr_coef * nbeds + ffa_coef * ffa # kWh/yr
    else
        pp_ann = ann_elec # kWh/yr
    end

    #hard coded convective, radiative, latent, and lost fractions
    pp_lat = 0
    pp_rad = 0
    pp_conv = 0
    pp_lost = 1 - pp_lat - pp_rad - pp_conv
	
	obj_name = Constants.ObjectNamePoolPump
	sch = MonthHourSchedule.new(weekday_sch, weekend_sch, monthly_sch, model, obj_name, runner)
	if not sch.validated?
		return false
	end
	design_level = sch.calcDesignLevelFromDailykWh(pp_ann/365.0)
	
	#add pool pump to an arbitrary space (there are no space gains)
	has_pp = 0
	replace_pp = 0
    space = Geometry.get_default_space(model, runner)
    if space.nil?
        return false
    end
    space_equipments = space.electricEquipment
    space_equipments.each do |space_equipment|
        if space_equipment.electricEquipmentDefinition.name.get.to_s == obj_name
            has_pp = 1
            runner.registerInfo("There is already a pool pump, the existing pool pump will be replaced with the specified pool pump.")
            space_equipment.electricEquipmentDefinition.setDesignLevel(design_level)
            sch.setSchedule(space_equipment)
            replace_pp = 1
        end
    end
    if has_pp == 0 
        has_pp = 1
        
        #Add electric equipment for the pool pump
        pp_def = OpenStudio::Model::ElectricEquipmentDefinition.new(model)
        pp = OpenStudio::Model::ElectricEquipment.new(pp_def)
        pp.setName(obj_name)
        pp.setSpace(space)
        pp_def.setName(obj_name)
        pp_def.setDesignLevel(design_level)
        pp_def.setFractionRadiant(pp_rad)
        pp_def.setFractionLatent(pp_lat)
        pp_def.setFractionLost(pp_lost)
        sch.setSchedule(pp)
        
    end
	
    #reporting final condition of model
    runner.registerFinalCondition("A pool pump has been set with #{pp_ann.round} kWhs annual energy consumption.")
	
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ResidentialPoolPump.new.registerWithApplication