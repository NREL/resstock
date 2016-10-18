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
    return "Adds (or replaces) residential plug loads with the specified efficiency and schedule in all finished spaces. For multifamily buildings, the plug loads can be set for all units of the building."
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
		runner.registerError("Multiplier must be greater than or equal to 0.")
		return false
    end
    
    # Get building units
    units = Geometry.get_building_units(model, runner)
    if units.nil?
        return false
    end
    
    tot_mel_ann = 0
    msgs = []
    sch = nil
    units.each do |unit|
        # Get unit beds/baths
        nbeds, nbaths = Geometry.get_unit_beds_baths(model, unit, runner)
        if nbeds.nil? or nbaths.nil?
            return false
        end
        
        # Get unit ffa
        ffa = Geometry.get_finished_floor_area_from_spaces(unit.spaces, false, runner)
        if ffa.nil?
            return false
        end
        
        #Calculate electric mel daily energy use
        mel_ann = (1108.1 + 180.2 * nbeds + 0.2785 * ffa) * mult
        mel_daily = mel_ann / 365.0
        
        unit.spaces.each do |space|
            next if Geometry.space_is_unfinished(space)
            
            space_obj_name = "#{Constants.ObjectNameMiscPlugLoads(unit.name.to_s)}|#{space.name.to_s}"
            
            # Remove any existing mels
            mels_removed = false
            space.electricEquipment.each do |space_equipment|
                next if space_equipment.name.to_s != space_obj_name
                space_equipment.remove
                mels_removed = true
            end
            if mels_removed
                runner.registerInfo("Removed existing plug loads from space #{space.name.to_s}.")
            end
            
            if mel_ann > 0

                if sch.nil?
                    # Create schedule
                    sch = MonthWeekdayWeekendSchedule.new(model, runner, Constants.ObjectNameMiscPlugLoads + " schedule", weekday_sch, weekend_sch, monthly_sch)
                    if not sch.validated?
                        return false
                    end
                end
            
                space_mel_ann = mel_ann * OpenStudio.convert(space.floorArea, "m^2", "ft^2").get/ffa
                space_design_level = sch.calcDesignLevelFromDailykWh(space_mel_ann/365.0)

                #Add electric equipment for the mel
                mel_def = OpenStudio::Model::ElectricEquipmentDefinition.new(model)
                mel = OpenStudio::Model::ElectricEquipment.new(mel_def)
                mel.setName(space_obj_name)
                mel.setSpace(space)
                mel_def.setName(space_obj_name)
                mel_def.setDesignLevel(space_design_level)
                mel_def.setFractionRadiant(0.558)
                mel_def.setFractionLatent(0.021)
                mel_def.setFractionLost(0.049)
                mel.setSchedule(sch.schedule)
                
                msgs << "Plug loads with #{space_mel_ann.round} kWhs annual energy consumption has been assigned to space '#{space.name.to_s}'."
                tot_mel_ann += space_mel_ann
            end

        end
        
    end

    # Reporting
    if msgs.size > 1
        msgs.each do |msg|
            runner.registerInfo(msg)
        end
        runner.registerFinalCondition("The building has been assigned plug loads totaling #{tot_mel_ann.round} kWhs annual energy consumption across #{units.size} units.")
    elsif msgs.size == 1
        runner.registerFinalCondition(msgs[0])
    else
        runner.registerFinalCondition("No plug loads have been assigned.")
    end
	
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ResidentialMiscellaneousElectricLoads.new.registerWithApplication