#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/schedules"
require "#{File.dirname(__FILE__)}/resources/geometry"

#start the measure
class ResidentialMiscellaneousElectricLoads < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Residential Plug Loads"
  end
  
  def description
    return "Adds (or replaces) residential plug loads with the specified efficiency and schedule in all finished spaces."
  end
  
  def modeler_description
    return "Since there is no Plug Loads object in OpenStudio/EnergyPlus, we look for an ElectricEquipment object with the name that denotes it is residential plug loads. If one is found, it is replaced with the specified properties. Otherwise, a new such object is added to the model. Note: This measure requires the number of bedrooms/bathrooms to have already been assigned."
  end
  
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new
    
	#TODO: New argument for demand response for mels (alternate schedules if automatic DR control is specified)
	
	#make a double argument for BA Benchamrk multiplier
	mult = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("mult")
	mult.setDisplayName("Building America Benchmark Multipler")
	mult.setDefaultValue(1)
	args << mult
	
	#Make a string argument for 24 weekday schedule values
	weekday_sch = OpenStudio::Ruleset::OSArgument::makeStringArgument("weekday_sch", true)
	weekday_sch.setDisplayName("Weekday schedule")
	weekday_sch.setDescription("Specify the 24-hour weekday schedule.")
	weekday_sch.setDefaultValue("0.04, 0.037, 0.037, 0.036, 0.033, 0.036, 0.043, 0.047, 0.034, 0.023, 0.024, 0.025, 0.024, 0.028, 0.031, 0.032, 0.039, 0.053, 0.063, 0.067, 0.071, 0.069, 0.059, 0.05")
	args << weekday_sch
    
	#Make a string argument for 24 weekend schedule values
	weekend_sch = OpenStudio::Ruleset::OSArgument::makeStringArgument("weekend_sch", true)
	weekend_sch.setDisplayName("Weekend schedule")
	weekend_sch.setDescription("Specify the 24-hour weekend schedule.")
	weekend_sch.setDefaultValue("0.04, 0.037, 0.037, 0.036, 0.033, 0.036, 0.043, 0.047, 0.034, 0.023, 0.024, 0.025, 0.024, 0.028, 0.031, 0.032, 0.039, 0.053, 0.063, 0.067, 0.071, 0.069, 0.059, 0.05")
	args << weekend_sch

	#Make a string argument for 12 monthly schedule values
	monthly_sch = OpenStudio::Ruleset::OSArgument::makeStringArgument("monthly_sch", true)
	monthly_sch.setDisplayName("Month schedule")
	monthly_sch.setDescription("Specify the 12-month schedule.")
	monthly_sch.setDefaultValue("1.248, 1.257, 0.993, 0.989, 0.993, 0.827, 0.821, 0.821, 0.827, 0.99, 0.987, 1.248")
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
	mult = runner.getDoubleArgumentValue("mult",user_arguments)
	weekday_sch = runner.getStringArgumentValue("weekday_sch",user_arguments)
	weekend_sch = runner.getStringArgumentValue("weekend_sch",user_arguments)
	monthly_sch = runner.getStringArgumentValue("monthly_sch",user_arguments)

    #check for valid inputs
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
	
	#if multiplier is defined, make sure it is positive
	if mult <= 0
		runner.registerError("Multiplier must be greater than or equal to 0.0.")
        return false
	end
	
	#Calculate electric mel daily energy use
    mel_ann = (1108.1 + 180.2 * nbeds + 0.2785 * ffa) * mult
	mel_daily = mel_ann / 365.0
    
	#hard coded convective, radiative, latent, and lost fractions
	mel_lat = 0.021
	mel_rad = 0.558
	mel_conv = 0.372
	mel_lost = 1 - mel_lat - mel_rad - mel_conv

    obj_name = Constants.ObjectNameMiscPlugLoads
	sch = MonthHourSchedule.new(weekday_sch, weekend_sch, monthly_sch, model, obj_name, runner)
	if not sch.validated?
		return false
	end
    
    Geometry.get_finished_spaces(model).each do |space|
        obj_name_space = "#{obj_name} #{space.name.to_s}"
        space_energy_ann = mel_ann * OpenStudio.convert(space.floorArea, "m^2", "ft^2").get/ffa
        space_design_level = sch.calcDesignLevelFromDailykWh(space_energy_ann/365.0)
        #add mels to each finished space
        has_elec_mel = 0
        space.electricEquipment.each do |space_equipment|
            if space_equipment.electricEquipmentDefinition.name.get.to_s == obj_name_space
                has_elec_mel = 1
                runner.registerWarning("This space (#{space.name}) already has misc plug loads, the existing plug loads will be replaced with the specific misc plug loads.")
                space_equipment.electricEquipmentDefinition.setDesignLevel(space_design_level)
                sch.setSchedule(space_equipment)
            end
        end
        if has_elec_mel == 0 
            has_elec_mel = 1

            #Add electric equipment for the mel
            mel_def = OpenStudio::Model::ElectricEquipmentDefinition.new(model)
            mel = OpenStudio::Model::ElectricEquipment.new(mel_def)
            mel.setName(obj_name_space)
            mel.setSpace(space)
            mel_def.setName(obj_name_space)
            mel_def.setDesignLevel(space_design_level)
            mel_def.setFractionRadiant(mel_rad)
            mel_def.setFractionLatent(mel_lat)
            mel_def.setFractionLost(mel_lost)
            sch.setSchedule(mel)
        end
    end
	
    #reporting final condition of model
    runner.registerFinalCondition("Misc plug loads have been set with #{mel_ann.round} kWhs annual energy consumption.")
	
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ResidentialMiscellaneousElectricLoads.new.registerWithApplication