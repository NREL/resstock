# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/measures/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"
require "#{File.dirname(__FILE__)}/resources/schedules"
require "#{File.dirname(__FILE__)}/resources/util"

# start the measure
class AddResidentialBedroomsAndBathrooms < OpenStudio::Ruleset::ModelUserScript

  # human readable name
  def name
    return "Set Residential Number of Beds, Baths, and Occupants"
  end

  # human readable description
  def description
    return "Sets the number of bedrooms and bathrooms in the building as well as the number/schedule of occupants."
  end

  # human readable description of modeling approach
  def modeler_description
    return "Sets (or replaces) dummy ElectricEquipment objects that store the number of bedrooms and bathrooms associated with the model. Also sets the People object for each finished space in the model."
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

	#make an integer argument for number of bedrooms
	chs = OpenStudio::StringVector.new
	chs << "1"
	chs << "2" 
	chs << "3"
	chs << "4"
	chs << "5+"
	num_br = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("Num_Br", chs, true)
	num_br.setDisplayName("Number of Bedrooms")
    num_br.setDescription("Used to determine the energy usage of appliances and plug loads, hot water usage, mechanical ventilation rate, etc.")
	num_br.setDefaultValue("3")
	args << num_br	
	
	#make an integer argument for number of bathrooms
	chs = OpenStudio::StringVector.new
	chs << "1"
	chs << "1.5" 
	chs << "2"
	chs << "2.5"
	chs << "3+"
	num_ba = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("Num_Ba", chs, true)
	num_ba.setDisplayName("Number of Bathrooms")
    num_ba.setDescription("Used to determine the hot water usage, etc.")
	num_ba.setDefaultValue("2")
	args << num_ba		

    #Make a string argument for occupants (auto or number)
    occupants = OpenStudio::Ruleset::OSArgument::makeStringArgument("occupants", false)
    occupants.setDisplayName("Number of Occupants")
    occupants.setDescription("Use '#{Constants.Auto}' to calculate the average number of occupants from the number of bedrooms. Only used to specify the internal gains from people.")
    occupants.setDefaultValue(Constants.Auto)
    args << occupants

    #Make a string argument for 24 weekday schedule values
    weekday_sch = OpenStudio::Ruleset::OSArgument::makeStringArgument("weekday_sch", true)
    weekday_sch.setDisplayName("Weekday schedule")
    weekday_sch.setDescription("Specify the 24-hour weekday schedule.")
    weekday_sch.setDefaultValue("1.00000, 1.00000, 1.00000, 1.00000, 1.00000, 1.00000, 1.00000, 0.88310, 0.40861, 0.24189, 0.24189, 0.24189, 0.24189, 0.24189, 0.24189, 0.24189, 0.29498, 0.55310, 0.89693, 0.89693, 0.89693, 1.00000, 1.00000, 1.00000")
    args << weekday_sch
    
    #Make a string argument for 24 weekend schedule values
    weekend_sch = OpenStudio::Ruleset::OSArgument::makeStringArgument("weekend_sch", true)
    weekend_sch.setDisplayName("Weekend schedule")
    weekend_sch.setDescription("Specify the 24-hour weekend schedule.")
    weekend_sch.setDefaultValue("1.00000, 1.00000, 1.00000, 1.00000, 1.00000, 1.00000, 1.00000, 0.88310, 0.40861, 0.24189, 0.24189, 0.24189, 0.24189, 0.24189, 0.24189, 0.24189, 0.29498, 0.55310, 0.89693, 0.89693, 0.89693, 1.00000, 1.00000, 1.00000")
    args << weekend_sch

    #Make a string argument for 12 monthly schedule values
    monthly_sch = OpenStudio::Ruleset::OSArgument::makeStringArgument("monthly_sch", true)
    monthly_sch.setDisplayName("Month schedule")
    monthly_sch.setDescription("Specify the 12-month schedule.")
    monthly_sch.setDefaultValue("1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0")
    args << monthly_sch

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end
	
	num_br = runner.getStringArgumentValue("Num_Br", user_arguments)
	num_ba = runner.getStringArgumentValue("Num_Ba", user_arguments)
    weekday_sch = runner.getStringArgumentValue("weekday_sch",user_arguments)
    weekend_sch = runner.getStringArgumentValue("weekend_sch",user_arguments)
    monthly_sch = runner.getStringArgumentValue("monthly_sch",user_arguments)
    occupants = runner.getStringArgumentValue("occupants",user_arguments)

    if occupants != Constants.Auto 
        if not HelperMethods.valid_float?(occupants)
            runner.registerError("Number of Occupants must be either '#{Constants.Auto}' or a number greater than or equal to 0.")
            return false
        elsif occupants.to_f < 0
            runner.registerError("Number of Occupants must be either '#{Constants.Auto}' or a number greater than or equal to 0.")
            return false
        end
    end

	# Remove any existing bedrooms and bathrooms
	Geometry.remove_bedrooms_bathrooms(model)
	
	#Convert num bedrooms to appropriate integer
	num_br = num_br.tr('+','').to_f

	#Convert num bathrooms to appropriate float
	num_ba = num_ba.tr('+','').to_f
    
    sch = OpenStudio::Model::ScheduleRuleset.new(model, 0)
    sch.setName('empty_schedule')
	
	# Bedrooms
	br_def = OpenStudio::Model::ElectricEquipmentDefinition.new(model)
	br_def.setName("#{num_br} Bedrooms")
	br = OpenStudio::Model::ElectricEquipment.new(br_def)
	br.setName("#{num_br} Bedrooms")
    br.setSchedule(sch)
	
	# Bathrooms
	ba_def = OpenStudio::Model::ElectricEquipmentDefinition.new(model)
	ba_def.setName("#{num_ba} Bathrooms")
	ba = OpenStudio::Model::ElectricEquipment.new(ba_def)
	ba.setName("#{num_ba} Bathrooms")
    ba.setSchedule(sch)
	
	# Assign to an arbitrary space
    space = Geometry.get_default_space(model, runner)
    if space.nil?
        return false
    end
    br.setSpace(space)
    ba.setSpace(space)
	
	# Test retrieving
    nbeds, nbaths = Geometry.get_bedrooms_bathrooms(model)
    if nbeds.nil?
        runner.registerError("Number of bedrooms incorrectly set.")
        return false
    end
    if nbaths.nil?
        runner.registerError("Number of bathrooms incorrectly set.")
        return false
    end
    
    # Get FFA
    ffa = Geometry.get_building_finished_floor_area(model, runner)
    if ffa.nil?
        return false
    end

    #Calculate number of occupants & activity level
    if occupants == Constants.Auto
        num_occ = 0.87 + 0.59 * nbeds
    else
        num_occ = occupants.to_f
    end
    activity_per_person = 112.5504
    
    #hard coded convective, radiative, latent, and lost fractions
    occ_lat = 0.427
    occ_conv = 0.253
    occ_rad = 0.32
    occ_lost = 1 - occ_lat - occ_conv - occ_rad
    occ_sens = occ_rad + occ_conv

    obj_name = Constants.ObjectNameOccupants
    people_sch = MonthWeekdayWeekendSchedule.new(model, runner, obj_name + " schedule", weekday_sch, weekend_sch, monthly_sch)
    if not people_sch.validated?
        return false
    end
    activity_sch = OpenStudio::Model::ScheduleRuleset.new(model, activity_per_person)
    
    spaces = Geometry.get_finished_spaces(model)

    # Remove any existing occupants
    occ_removed = false
    spaces.each do |space|
        obj_name_space = "#{obj_name} #{space.name.to_s}"
        space.people.each do |occupant|
            if occupant.name.to_s == obj_name_space
                occupant.remove
                occ_removed = true
            end
        end
    end
    if occ_removed
        runner.registerInfo("Removed existing occupants.")
    end
    
    spaces.each do |space|
        obj_name_space = "#{obj_name} #{space.name.to_s}"
        space_num_occ = num_occ * OpenStudio.convert(space.floorArea, "m^2", "ft^2").get/ffa

        #Add people definition for the occ
        occ_def = OpenStudio::Model::PeopleDefinition.new(model)
        occ = OpenStudio::Model::People.new(occ_def)
        occ.setName(obj_name_space)
        occ.setSpace(space)
        occ_def.setName(obj_name_space)
        occ_def.setNumberOfPeopleCalculationMethod("People",1)
        occ_def.setNumberofPeople(space_num_occ)
        occ_def.setFractionRadiant(occ_rad)
        occ_def.setSensibleHeatFraction(occ_sens)
        occ_def.setMeanRadiantTemperatureCalculationType("ZoneAveraged")
        occ_def.setCarbonDioxideGenerationRate(0)
        occ_def.setEnableASHRAE55ComfortWarnings(false)
        occ.setActivityLevelSchedule(activity_sch)
        people_sch.setSchedule(occ)
    end
    
    #reporting final condition of model
    runner.registerFinalCondition("The building has been assigned #{nbeds.to_s} bedrooms, #{nbaths.to_s} bathrooms, and #{num_occ.to_s} occupants.")

    return true

  end
  
end

# register the measure to be used by the application
AddResidentialBedroomsAndBathrooms.new.registerWithApplication
