require "csv"
require "matrix"
resources_path = File.absolute_path(File.join(File.dirname(__FILE__), "../HPXMLtoOpenStudio/resources"))
unless File.exists? resources_path
  resources_path = File.join(OpenStudio::BCLMeasure::userMeasuresDir.to_s, "HPXMLtoOpenStudio/resources") # Hack to run measures in the OS App since applied measures are copied off into a temporary directory
end
require File.join(resources_path, "constants")
require File.join(resources_path, "geometry")
require File.join(resources_path, "unit_conversions")
require File.join(resources_path, "appliances")

# start the measure
class ResidentialScheduleGenerator < OpenStudio::Measure::ModelMeasure
  def name
    return "Generate Appliance schedules"
  end

  def description
    return "Generates occupancy based schedules for various residential appliances.#{Constants.WorkflowDescription}"
  end

  def modeler_description
    return "a"
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # make an argument for number of units
    arg = OpenStudio::Measure::OSArgument::makeIntegerArgument("num_units", true)
    arg.setDisplayName("Num Units")
    arg.setUnits("#")
    arg.setDescription("The number of units.")
    arg.setDefaultValue(1)
    args << arg

    # make a string argument for number of bedrooms
    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("num_bedrooms", true)
    arg.setDisplayName("Number of Bedrooms")
    arg.setDescription("Specify the number of bedrooms.")
    arg.setDefaultValue(3)
    args << arg

    # Make a string argument for occupants (auto or number)
    arg = OpenStudio::Measure::OSArgument::makeStringArgument("num_occupants", true)
    arg.setDisplayName("Number of Occupants")
    arg.setDescription("Specify the number of occupants.")
    arg.setDefaultValue(Constants.Auto)
    args << arg

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # assign the user inputs to variables
    num_units = runner.getIntegerArgumentValue("num_units", user_arguments)
    num_bedrooms = runner.getDoubleArgumentValue("num_bedrooms", user_arguments)
    num_occupants = runner.getStringArgumentValue("num_occupants", user_arguments)

    if num_occupants == Constants.Auto
      if num_units > 1 # multifamily equation
        num_occupants = 0.63 + 0.92 * num_bedrooms
      else # single-family equation
        num_occupants = 0.87 + 0.59 * num_bedrooms
      end
    else
      num_occupants = num_occupants.to_i
    end

    minutes_per_steps = 10
    if model.getSimulationControl.timestep.is_initialized
      minutes_per_steps = 60 / model.getSimulationControl.timestep.get.numberOfTimestepsPerHour
    end
    model.getYearDescription.isLeapYear ? total_days_in_year = 366 : total_days_in_year = 365

    schedules_path =  File.join(File.dirname(__FILE__), "../HPXMLtoOpenStudio/resources/schedules")
    resources_path =  File.join(File.dirname(__FILE__), "../HPXMLtoOpenStudio/resources")

    occupancy_cluster_types_tsv_path = schedules_path + "/Occupancy_Types.tsv"
    occ_types_dist = CSV.read(occupancy_cluster_types_tsv_path, { :col_sep => "\t" })
    occ_types = occ_types_dist[0].map { |i| i.split('=')[1] }
    occ_prob = occ_types_dist[1].map { |i| i.to_f }
    # use the built-in error checking
    def weighted_random(weights)
      n = rand()
      cum_weights = 0
      weights.each_with_index do |w, index|
        cum_weights += w
        if n <= cum_weights
          return index
        end
      end
    end

    unless runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    all_simulated_values = []
    (1..num_occupants).each do |i|
      num_states = 7
      num_ts_per_day = 96

      occ_index = weighted_random(occ_prob)
      occ_type = occ_types[occ_index]
      init_prob_file = schedules_path + "/mkv_chain_probabilities/mkv_chain_initial_prob_cluster_#{occ_index}.csv"
      initial_prob = CSV.read(init_prob_file)
      initial_prob = initial_prob.map { |x| x[0].to_f }
      # initial_prob = Matrix.build(7,1){|i, j| initial_prob[i][0].to_f}
      transition_matrix_file = schedules_path + "/mkv_chain_probabilities/mkv_chain_transition_prob_cluster_#{occ_index}.csv"
      transition_matrix = CSV.read(transition_matrix_file)
      transition_matrix = transition_matrix.map { |x| x.map { |y| y.to_f } }
      simulated_values = []
      total_days_in_year.times do
        init_sate_val = weighted_random(initial_prob)
        init_state = [0] * num_states
        init_state[init_sate_val] = 1
        simulated_values << init_state
        (num_ts_per_day - 1).times do |j|
          current_state = simulated_values[-1]
          transition_probs = transition_matrix[j * 7...(j + 1) * 7]
          transition_probs_matrix = Matrix[*transition_probs]
          current_state_vec = Matrix.row_vector(current_state)
          new_prob = current_state_vec * transition_probs_matrix
          new_prob = new_prob.to_a[0]
          init_sate_val = weighted_random(new_prob)
          new_state = [0] * num_states
          new_state[init_sate_val] = 1
          simulated_values << new_state
        end
      end
      all_simulated_values << Matrix[*simulated_values]
    end

    # shape of all_simulated_values is [2, 35040, 7] i.e. (num_occupants, period_in_a_year, number_of_states)
    daily_plugload_sch = CSV.read(schedules_path + "/plugload_sch.csv")
    daily_lighting_sch = CSV.read(schedules_path + "/lighting_sch.csv")
    daily_refrigerator_sch = CSV.read(schedules_path + "/refrigerator_sch.csv")
    daily_ceiling_fan_sch = CSV.read(schedules_path + "/ceiling_fan_sch.csv")

    # "occupants", "cooking_range", "plug_loads", "refrigerator", "lighting_interior", "lighting_exterior", "lighting_garage", "clothes_washer", "clothes_dryer", "dishwasher", "baths", "showers", "sinks", "ceiling_fan"

    plugload_schedule = []
    refrigerator_schedule = []
    lighting_interior_schedule = []
    lighting_exterior_schedule = []
    lighting_garage_schedule = []
    lighting_holiday_schedule = []
    ceiling_fan_schedule = []
    sink_schedule = []
    bath_schedule = []

    shower_schedule = []
    clothes_washer_schedule = []
    clothes_dryer_schedule = []
    dish_washer_schedule = []
    cooking_schedule = []
    away_schedule = []
    idle_schedule = []
    sleeping_schedule = []

    def get_value_from_daily_sch(daily_sch, month, is_weekday, minute)
      is_weekday ? sch = daily_sch[0] : sch = daily_sch[1]
      return sch[(minute / 60).to_i].to_f * daily_sch[2][month].to_f
    end

    sim_year = model.getYearDescription.calendarYear.get
    start_day = DateTime.new(sim_year, 1, 1)
    total_days_in_year.times do |day|
      today = start_day + day
      month = today.month
      day_of_week = today.wday
      [0, 6].include?(day_of_week) ? is_weekday = false : is_weekday = true
      steps_in_day = 24 * 60 / minutes_per_steps
      steps_in_day.times do |step|
        minute = step * minutes_per_steps
        index_15 = (minute / 15).to_i
        index_hour = (minute / 60).to_i
        step_per_hour = 60 / minutes_per_steps

        def sum_across_occupants(all_simulated_values, activity_index, time_index)
          sum = 0
          all_simulated_values.size.times do |i|
            sum += all_simulated_values[i][time_index, activity_index]
          end
          return sum
        end

        # the schedule is set as the sum of values of individual occupants
        sleeping_schedule << sum_across_occupants(all_simulated_values, 0, index_15) / num_occupants
        shower_schedule << sum_across_occupants(all_simulated_values, 1, index_15) / num_occupants
        clothes_washer_schedule << sum_across_occupants(all_simulated_values, 2, index_15) / num_occupants
        hour_before_washer = clothes_washer_schedule[-step_per_hour]
        if hour_before_washer.nil?
          clothes_dryer_schedule << 0
        else
          clothes_dryer_schedule << hour_before_washer
        end
        cooking_schedule << sum_across_occupants(all_simulated_values, 3, index_15) / num_occupants
        dish_washer_schedule << sum_across_occupants(all_simulated_values, 4, index_15) / num_occupants
        away_schedule << sum_across_occupants(all_simulated_values, 5, index_15) / num_occupants
        idle_schedule << sum_across_occupants(all_simulated_values, 6, index_15) / num_occupants

        plugload_schedule << get_value_from_daily_sch(daily_plugload_sch, month, is_weekday, minute)
        refrigerator_schedule << get_value_from_daily_sch(daily_refrigerator_sch, month, is_weekday, minute)
        lighting_interior_schedule << get_value_from_daily_sch(daily_lighting_sch, month, is_weekday, minute)
        lighting_exterior_schedule << lighting_interior_schedule[-1]
        lighting_garage_schedule << lighting_interior_schedule[-1]
        lighting_holiday_schedule << lighting_interior_schedule[-1]
        ceiling_fan_schedule << get_value_from_daily_sch(daily_ceiling_fan_sch, month, is_weekday, minute)
        sink_schedule << shower_schedule[-1]
        bath_schedule << shower_schedule[-1]
      end
    end
    output_csv_file = File.expand_path("../appliances_schedules.csv")
    CSV.open(output_csv_file, "w") do |csv|
      csv << ["occupants", "cooking_range", "plug_loads", "refrigerator", "lighting_interior", "lighting_exterior",
              "lighting_garage", "lighting_exterior_holiday", "clothes_washer", "clothes_dryer", "dishwasher", "baths", "showers", "sinks", "ceiling_fan"]
      shower_schedule.size.times do |i|
        csv << [(1 - away_schedule[i]), cooking_schedule[i], plugload_schedule[i], refrigerator_schedule[i],
                lighting_interior_schedule[i], lighting_exterior_schedule[i], lighting_garage_schedule[i], lighting_holiday_schedule[i],
                clothes_washer_schedule[i], clothes_dryer_schedule[i], dish_washer_schedule[i], bath_schedule[i],
                shower_schedule[i], sink_schedule[i], ceiling_fan_schedule[i]]
      end
    end

    runner.registerInfo("Generated schedule file: #{File.expand_path(output_csv_file)}")

    model.getBuilding.additionalProperties.setFeature("Schedule Path", File.expand_path(output_csv_file))

    return true
  end
end # end the measure

# this allows the measure to be use by the application
ResidentialScheduleGenerator.new.registerWithApplication
