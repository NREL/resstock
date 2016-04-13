# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/measures/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/geometry"

# start the measure
class AddResidentialBedroomsAndBathrooms < OpenStudio::Ruleset::ModelUserScript

  # human readable name
  def name
    return "Set Residential Number of Bedrooms/Bathrooms"
  end

  # human readable description
  def description
    return ""
  end

  # human readable description of modeling approach
  def modeler_description
    return "Creates dummy ElectricEquipment objects to store the number of bedrooms and bathrooms associated with the model."
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
	
	num_br = runner.getStringArgumentValue("Num_Br", user_arguments)
	num_ba = runner.getStringArgumentValue("Num_Ba", user_arguments)
	
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
    if not nbeds.nil?
        runner.registerInfo("Number of bedrooms set to #{nbeds}.")
    end
    if not nbaths.nil?
        runner.registerInfo("Number of bathrooms set to #{nbaths}.")
    end
	
    return true

  end
  
end

# register the measure to be used by the application
AddResidentialBedroomsAndBathrooms.new.registerWithApplication
