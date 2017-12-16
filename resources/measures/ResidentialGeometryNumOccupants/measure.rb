# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/measures/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"
require "#{File.dirname(__FILE__)}/resources/schedules"
require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/unit_conversions"

# start the measure
class AddResidentialOccupants < OpenStudio::Measure::ModelMeasure

  # human readable name
  def name
    return "Set Residential Number of Occupants"
  end

  # human readable description
  def description
    return "Sets the number of occupants in the building. For multifamily buildings, the people can be set for all units of the building.#{Constants.WorkflowDescription}"
  end

  # human readable description of modeling approach
  def modeler_description
    return "Sets (or replaces) the People object for each finished space in the model."
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new        

    #Make a string argument for occupants (auto or number)
    num_occ = OpenStudio::Measure::OSArgument::makeStringArgument("num_occ", true)
    num_occ.setDisplayName("Number of Occupants")
    num_occ.setDescription("Specify the number of occupants. For a multifamily building, specify one value for all units or a comma-separated set of values (in the correct order) for each unit. A value of '#{Constants.Auto}' will calculate the average number of occupants from the number of bedrooms. Used to specify the internal gains from people only.")
    num_occ.setDefaultValue(Constants.Auto)
    args << num_occ
    
    # Make a double argument for occupant gains
    occ_gain = OpenStudio::Measure::OSArgument::makeDoubleArgument("occ_gain", true)
    occ_gain.setDisplayName("Internal Gains")
    occ_gain.setDescription("Occupant heat gain, both sensible and latent.")
    occ_gain.setUnits("Btu/person/hr")
    occ_gain.setDefaultValue(384.0)
    args << occ_gain

    # Make a double argument for sensible fraction
    sens_frac = OpenStudio::Measure::OSArgument::makeDoubleArgument("sens_frac", true)
    sens_frac.setDisplayName("Sensible Fraction")
    sens_frac.setDescription("Fraction of internal gains that are sensible.")
    sens_frac.setDefaultValue(0.573)
    args << sens_frac

    # Make a double argument for latent fraction
    lat_frac = OpenStudio::Measure::OSArgument::makeDoubleArgument("lat_frac", true)
    lat_frac.setDisplayName("Latent Fraction")
    lat_frac.setDescription("Fraction of internal gains that are latent.")
    lat_frac.setDefaultValue(0.427)
    args << lat_frac

    #Make a string argument for 24 weekday schedule values
    weekday_sch = OpenStudio::Measure::OSArgument::makeStringArgument("weekday_sch", true)
    weekday_sch.setDisplayName("Weekday schedule")
    weekday_sch.setDescription("Specify the 24-hour weekday schedule.")
    weekday_sch.setDefaultValue("1.00000, 1.00000, 1.00000, 1.00000, 1.00000, 1.00000, 1.00000, 0.88310, 0.40861, 0.24189, 0.24189, 0.24189, 0.24189, 0.24189, 0.24189, 0.24189, 0.29498, 0.55310, 0.89693, 0.89693, 0.89693, 1.00000, 1.00000, 1.00000")
    args << weekday_sch
    
    #Make a string argument for 24 weekend schedule values
    weekend_sch = OpenStudio::Measure::OSArgument::makeStringArgument("weekend_sch", true)
    weekend_sch.setDisplayName("Weekend schedule")
    weekend_sch.setDescription("Specify the 24-hour weekend schedule.")
    weekend_sch.setDefaultValue("1.00000, 1.00000, 1.00000, 1.00000, 1.00000, 1.00000, 1.00000, 0.88310, 0.40861, 0.24189, 0.24189, 0.24189, 0.24189, 0.24189, 0.24189, 0.24189, 0.29498, 0.55310, 0.89693, 0.89693, 0.89693, 1.00000, 1.00000, 1.00000")
    args << weekend_sch

    #Make a string argument for 12 monthly schedule values
    monthly_sch = OpenStudio::Measure::OSArgument::makeStringArgument("monthly_sch", true)
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
    occ_gain = runner.getDoubleArgumentValue("occ_gain",user_arguments)
    sens_frac = runner.getDoubleArgumentValue("sens_frac",user_arguments)
    lat_frac = runner.getDoubleArgumentValue("lat_frac",user_arguments)
    weekday_sch = runner.getStringArgumentValue("weekday_sch",user_arguments)
    weekend_sch = runner.getStringArgumentValue("weekend_sch",user_arguments)
    monthly_sch = runner.getStringArgumentValue("monthly_sch",user_arguments)
    
    # Get building units
    units = Geometry.get_building_units(model, runner)
    if units.nil?
        return false
    end

    num_occ = num_occ.split(",").map(&:strip)
    
    #error checking
    if num_occ.length > 1 and num_occ.length != units.size
      runner.registerError("Number of occupant elements specified inconsistent with number of multifamily units defined in the model.")
      return false
    end
    
    if units.size > 1 and num_occ.length == 1
      num_occ = Array.new(units.size, num_occ[0])
    end 
    
    if occ_gain < 0
      runner.registerError("Internal gains cannot be negative.")
      return false
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
    
    activity_per_person = UnitConversions.convert(occ_gain, "Btu/hr", "W")

    #hard coded convective, radiative, latent, and lost fractions
    occ_lat = lat_frac
    occ_sens = sens_frac
    occ_conv = 0.442*occ_sens
    occ_rad = 0.558*occ_sens
    occ_lost = 1 - occ_lat - occ_conv - occ_rad
    
    # Update number of occupants
    total_num_occ = 0
    people_sch = nil
    activity_sch = nil
    units.each_with_index do |unit, unit_index|
    
      unit_occ = num_occ[unit_index]

      if unit_occ != Constants.Auto 
          if not MathTools.valid_float?(unit_occ)
              runner.registerError("Number of Occupants must be either '#{Constants.Auto}' or a number greater than or equal to 0.")
              return false
          elsif unit_occ.to_f < 0
              runner.registerError("Number of Occupants must be either '#{Constants.Auto}' or a number greater than or equal to 0.")
              return false
          end
      end

      # Get number of beds
      nbeds, nbaths = Geometry.get_unit_beds_baths(model, unit, runner)
      if nbeds.nil?
          return false
      end

      # Calculate number of occupants for this unit
      if unit_occ == Constants.Auto
          if units.size > 1 # multifamily equation
              unit_occ = 0.63 + 0.92 * nbeds
          else # single-family equation
              unit_occ = 0.87 + 0.59 * nbeds
          end
      else
          unit_occ = unit_occ.to_f
      end

      # Get FFA
      ffa = Geometry.get_finished_floor_area_from_spaces(unit.spaces, false, runner)
      if ffa.nil?
          return false
      end
      
      # Assign occupants to each space of the unit
      spaces = Geometry.get_finished_spaces(unit.spaces)      
      spaces.each do |space|
      
          space_obj_name = "#{Constants.ObjectNameOccupants(unit.name.to_s)}|#{space.name.to_s}"
          
          # Remove any existing people
          objects_to_remove = []
          space.people.each do |people|
              objects_to_remove << people
              objects_to_remove << people.peopleDefinition
              if people.numberofPeopleSchedule.is_initialized
                  objects_to_remove << people.numberofPeopleSchedule.get
              end
              if people.activityLevelSchedule.is_initialized
                  objects_to_remove << people.activityLevelSchedule.get
              end
          end
          if objects_to_remove.size > 0
              runner.registerInfo("Removed existing people from space '#{space.name.to_s}'.")
          end
          objects_to_remove.uniq.each do |object|
              begin
                  object.remove
              rescue
                  # no op
              end
          end

          space_num_occ = unit_occ * UnitConversions.convert(space.floorArea, "m^2", "ft^2") / ffa
          
          if space_num_occ > 0
          
              if people_sch.nil?
                  # Create schedule
                  people_sch = MonthWeekdayWeekendSchedule.new(model, runner, Constants.ObjectNameOccupants + " schedule", weekday_sch, weekend_sch, monthly_sch)
                  if not people_sch.validated?
                      return false
                  end
              end
              
              if activity_sch.nil?
                  # Create schedule
                  activity_sch = OpenStudio::Model::ScheduleRuleset.new(model, activity_per_person)
              end

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
              occ.setNumberofPeopleSchedule(people_sch.schedule)
              
              total_num_occ += space_num_occ
          end
          
      end

      if units.size > 1
        runner.registerInfo("#{unit.name.to_s} has been assigned #{unit_occ.round(2)} occupant(s).")
      end

    end
    
    #reporting final condition of model
    units_str = ""
    if units.size > 1
      units_str = " across #{units.size} units"
    end
    runner.registerFinalCondition("The building has been assigned #{total_num_occ.round(2)} occupant(s)#{units_str}.")

    return true

  end
  
end

# register the measure to be used by the application
AddResidentialOccupants.new.registerWithApplication
