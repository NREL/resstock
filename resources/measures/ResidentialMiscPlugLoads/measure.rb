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
class ResidentialMiscellaneousElectricLoads < OpenStudio::Measure::ModelMeasure
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Residential Plug Loads"
  end
  
  def description
    return "Adds (or replaces) residential plug loads with the specified efficiency and schedule in all finished spaces. For multifamily buildings, the plug loads can be set for all units of the building.#{Constants.WorkflowDescription}"
  end
  
  def modeler_description
    return "Since there is no Plug Loads object in OpenStudio/EnergyPlus, we look for an ElectricEquipment object with the name that denotes it is residential plug loads. If one is found, it is replaced with the specified properties. Otherwise, a new such object is added to the model. Note: This measure requires the number of bedrooms/bathrooms to have already been assigned."
  end
  
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new
    
    #TODO: New argument for demand response for mels (alternate schedules if automatic DR control is specified)
    
    #make a choice argument for option type
    choices = []
    choices << Constants.OptionTypePlugLoadsMultiplier
    choices << Constants.OptionTypePlugLoadsEnergyUse
    option_type = OpenStudio::Measure::OSArgument::makeChoiceArgument("option_type",choices,true)
    option_type.setDisplayName("Option Type")
    option_type.setDescription("Inputs are used/ignored below based on the option type specified.")
    option_type.setDefaultValue(Constants.OptionTypePlugLoadsMultiplier)
    args << option_type
    
    #make a double argument for BA Benchmark multiplier
    mult = OpenStudio::Measure::OSArgument::makeDoubleArgument("mult", true)
    mult.setDisplayName("#{Constants.OptionTypePlugLoadsMultiplier}")
    mult.setDefaultValue(1)
    mult.setDescription("A multiplier on the national average energy use, which is calculated as: (1108.1 + 180.2 * Nbeds + 0.2785 * FFA), where Nbeds is the number of bedrooms and FFA is the finished floor area in sqft.")
    args << mult
    
    #make a double argument for annual energy use
    energy_use = OpenStudio::Measure::OSArgument::makeDoubleArgument("energy_use", true)
    energy_use.setDisplayName("#{Constants.OptionTypePlugLoadsEnergyUse}")
    energy_use.setDefaultValue(2000)
    energy_use.setDescription("Annual energy use of the plug loads.")
    energy_use.setUnits("kWh/year")
    args << energy_use
    
    # Make a double argument for sensible fraction
    sens_frac = OpenStudio::Measure::OSArgument::makeDoubleArgument("sens_frac", true)
    sens_frac.setDisplayName("Sensible Fraction")
    sens_frac.setDescription("Fraction of internal gains that are sensible.")
    sens_frac.setDefaultValue(0.93)
    args << sens_frac
    
    # Make a double argument for latent fraction
    lat_frac = OpenStudio::Measure::OSArgument::makeDoubleArgument("lat_frac", true)
    lat_frac.setDisplayName("Latent Fraction")
    lat_frac.setDescription("Fraction of internal gains that are latent.")
    lat_frac.setDefaultValue(0.021)
    args << lat_frac
    
    #Make a string argument for 24 weekday schedule values
    weekday_sch = OpenStudio::Measure::OSArgument::makeStringArgument("weekday_sch", true)
    weekday_sch.setDisplayName("Weekday schedule")
    weekday_sch.setDescription("Specify the 24-hour weekday schedule.")
    weekday_sch.setDefaultValue("0.04, 0.037, 0.037, 0.036, 0.033, 0.036, 0.043, 0.047, 0.034, 0.023, 0.024, 0.025, 0.024, 0.028, 0.031, 0.032, 0.039, 0.053, 0.063, 0.067, 0.071, 0.069, 0.059, 0.05")
    args << weekday_sch
    
    #Make a string argument for 24 weekend schedule values
    weekend_sch = OpenStudio::Measure::OSArgument::makeStringArgument("weekend_sch", true)
    weekend_sch.setDisplayName("Weekend schedule")
    weekend_sch.setDescription("Specify the 24-hour weekend schedule.")
    weekend_sch.setDefaultValue("0.04, 0.037, 0.037, 0.036, 0.033, 0.036, 0.043, 0.047, 0.034, 0.023, 0.024, 0.025, 0.024, 0.028, 0.031, 0.032, 0.039, 0.053, 0.063, 0.067, 0.071, 0.069, 0.059, 0.05")
    args << weekend_sch

    #Make a string argument for 12 monthly schedule values
    monthly_sch = OpenStudio::Measure::OSArgument::makeStringArgument("monthly_sch", true)
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
    option_type = runner.getStringArgumentValue("option_type",user_arguments)
    mult = runner.getDoubleArgumentValue("mult",user_arguments)
    energy_use = runner.getDoubleArgumentValue("energy_use",user_arguments)
    sens_frac = runner.getDoubleArgumentValue("sens_frac",user_arguments)
    lat_frac = runner.getDoubleArgumentValue("lat_frac",user_arguments)
    weekday_sch = runner.getStringArgumentValue("weekday_sch",user_arguments)
    weekend_sch = runner.getStringArgumentValue("weekend_sch",user_arguments)
    monthly_sch = runner.getStringArgumentValue("monthly_sch",user_arguments)

    #check for valid inputs
    if option_type == Constants.OptionTypePlugLoadsMultiplier
      if mult < 0
        runner.registerError("#{Constants.OptionTypePlugLoadsMultiplier} must be greater than or equal to 0.")
        return false
      end
    elsif option_type == Constants.OptionTypePlugLoadsEnergyUse
      if energy_use < 0
        runner.registerError("#{Constants.OptionTypePlugLoadsEnergyUse} must be greater than or equal to 0.")
        return false
      end
    end
    if sens_frac < 0 or sens_frac > 1
      runner.registerError("Sensible fraction must be greater than or equal to 0 and less than or equal to 1.")
      return false
    end
    if lat_frac < 0 or lat_frac > 1
      runner.registerError("Latent fraction must be greater than or equal to 0 and less than or equal to 1.")
      return false
    end
    if lat_frac + sens_frac > 1
      runner.registerError("Sum of sensible and latent fractions must be less than or equal to 1.")
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
        if option_type == Constants.OptionTypePlugLoadsMultiplier
            mel_ann = (1108.1 + 180.2 * nbeds + 0.2785 * ffa) * mult
        elsif option_type == Constants.OptionTypePlugLoadsEnergyUse
            mel_ann = energy_use
        end
        mel_daily = mel_ann / 365.0
        
        unit.spaces.each do |space|
            next if Geometry.space_is_unfinished(space)
            
            obj_name = "#{Constants.ObjectNameMiscPlugLoads(unit.name.to_s)}"
            space_obj_name = "#{obj_name}|#{space.name.to_s}"
            
            # Remove any existing mels
            objects_to_remove = []
            space.electricEquipment.each do |space_equipment|
                next if space_equipment.name.to_s != space_obj_name
                objects_to_remove << space_equipment
                objects_to_remove << space_equipment.electricEquipmentDefinition
                if space_equipment.schedule.is_initialized
                    objects_to_remove << space_equipment.schedule.get
                end
            end
            if objects_to_remove.size > 0
                runner.registerInfo("Removed existing plug loads from space #{space.name.to_s}.")
            end
            objects_to_remove.uniq.each do |object|
                begin
                    object.remove
                rescue
                    # no op
                end
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
                mel.setEndUseSubcategory(obj_name)
                mel.setSpace(space)
                mel_def.setName(space_obj_name)
                mel_def.setDesignLevel(space_design_level)
                mel_def.setFractionRadiant(0.6 * sens_frac)
                mel_def.setFractionLatent(lat_frac)
                mel_def.setFractionLost(1 - sens_frac - lat_frac)
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