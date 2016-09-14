# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/measures/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"
require "#{File.dirname(__FILE__)}/resources/schedules"
require "#{File.dirname(__FILE__)}/resources/util"

# start the measure
class AddResidentialOccupants < OpenStudio::Ruleset::ModelUserScript

  # human readable name
  def name
    return "Set Residential Number of Occupants"
  end

  # human readable description
  def description
    return "Sets the number of occupants in the building. For multifamily buildings, the people can be set for all units of the building."
  end

  # human readable description of modeling approach
  def modeler_description
    return "Sets (or replaces) the People object for each finished space in the model."
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new		

    #Make a string argument for occupants (auto or number)
    num_occ = OpenStudio::Ruleset::OSArgument::makeStringArgument("num_occ", false)
    num_occ.setDisplayName("Number of Occupants")
    num_occ.setDescription("Specify the number of occupants. For a multifamily building, specify one value for all units or a comma-separated set of values (in the correct order) for each unit. A value of '#{Constants.Auto}' will calculate the average number of occupants from the number of bedrooms. Used to specify the internal gains from people only.")
    num_occ.setDefaultValue(Constants.Auto)
    args << num_occ

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
	
    num_occ = runner.getStringArgumentValue("num_occ",user_arguments)
    weekday_sch = runner.getStringArgumentValue("weekday_sch",user_arguments)
    weekend_sch = runner.getStringArgumentValue("weekend_sch",user_arguments)
    monthly_sch = runner.getStringArgumentValue("monthly_sch",user_arguments)
    
    num_units = Geometry.get_num_units(model, runner)
    if num_units.nil?
      return false
    end
    num_occ = num_occ.split(",").map(&:strip)
    
    #error checking
    if num_occ.length > 1 and num_occ.length != num_units
      runner.registerError("Number of occupant elements specified inconsistent with number of multifamily units defined in the model.")
      return false
    end
    
    if num_units > 1 and num_occ.length == 1
      num_occ = Array.new(num_units, num_occ[0])
    end 
    
    # Change to 1-based arrays or simplification
    num_occ.unshift(nil)

    people_sch = MonthWeekdayWeekendSchedule.new(model, runner, Constants.ObjectNameOccupants + " schedule", weekday_sch, weekend_sch, monthly_sch)
    if not people_sch.validated?
        return false
    end
    activity_per_person = 112.5504
    activity_sch = OpenStudio::Model::ScheduleRuleset.new(model, activity_per_person)    

    #hard coded convective, radiative, latent, and lost fractions
    occ_lat = 0.427
    occ_conv = 0.253
    occ_rad = 0.32
    occ_lost = 1 - occ_lat - occ_conv - occ_rad
    occ_sens = occ_rad + occ_conv
    
    # Update number of occupants
    total_num_occ = 0
    (1..num_units).to_a.each do |unit_num|
    
      unit_occ = num_occ[unit_num]

      if unit_occ != Constants.Auto 
          if not HelperMethods.valid_float?(unit_occ)
              runner.registerError("Number of Occupants must be either '#{Constants.Auto}' or a number greater than or equal to 0.")
              return false
          elsif unit_occ.to_f < 0
              runner.registerError("Number of Occupants must be either '#{Constants.Auto}' or a number greater than or equal to 0.")
              return false
          end
      end

      # Get number of beds and unit spaces
      nbeds, nbaths, unit_spaces = Geometry.get_unit_beds_baths_spaces(model, unit_num, runner)
      if nbeds.nil? or unit_spaces.nil?
          return false
      end

      # Calculate number of occupants for this unit
      if unit_occ == Constants.Auto
          if num_units > 1 # multifamily equation
              unit_occ = 0.63 + 0.92 * nbeds
          else # single-family equation
              unit_occ = 0.87 + 0.59 * nbeds
          end
      else
          unit_occ = unit_occ.to_f
      end

      # Get FFA
      ffa = Geometry.get_finished_floor_area_from_spaces(unit_spaces, runner)
      if ffa.nil?
          return false
      end
      
      # Assign occupants to each space of the unit
      spaces = Geometry.get_finished_spaces(unit_spaces)      
      spaces.each do |space|
      
          space_obj_name = "#{Constants.ObjectNameOccupants(unit_num)}|#{space.name.to_s}"
          
          # Remove any existing people
          people_removed = false
          space.people.each do |people|
              people.remove
              people_removed = true
          end
          if people_removed
              runner.registerInfo("Removed existing people from space #{space.name.to_s}.")
          end
          
          space_num_occ = unit_occ * OpenStudio.convert(space.floorArea, "m^2", "ft^2").get / ffa
          total_num_occ += space_num_occ

          #Add people definition for the occ
          occ_def = OpenStudio::Model::PeopleDefinition.new(model)
          occ = OpenStudio::Model::People.new(occ_def)
          occ.setName(space_obj_name)
          occ.setSpace(space)
          occ_def.setName(space_obj_name)
          occ_def.setNumberOfPeopleCalculationMethod("People",1)
          occ_def.setNumberofPeople(space_num_occ)
          occ_def.setFractionRadiant(occ_rad)
          occ_def.setSensibleHeatFraction(occ_sens)
          occ_def.setMeanRadiantTemperatureCalculationType("ZoneAveraged")
          occ_def.setCarbonDioxideGenerationRate(0)
          occ_def.setEnableASHRAE55ComfortWarnings(false)
          occ.setActivityLevelSchedule(activity_sch)
          people_sch.setSchedule(occ)
          
          if num_units > 1
            runner.registerInfo("Space #{space.name.to_s} of Unit #{unit_num} has been assigned #{space_num_occ.round(2)} occupant(s).")
          end
      end

    end
    
    #reporting final condition of model
    units_str = ""
    if num_units > 1
      units_str = " across #{num_units} units"
    end
    runner.registerFinalCondition("The building has been assigned #{total_num_occ.round(2)} occupant(s)#{units_str}.")

    return true

  end
  
end

# register the measure to be used by the application
AddResidentialOccupants.new.registerWithApplication
