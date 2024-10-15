# frozen_string_literal: true

require 'csv'
require 'matrix'

# Example args: https://github.com/NREL/resstock/blob/develop/resources/hpxml-measures/workflow/hpxml_inputs.json
# Collection of methods related to the generation of stochastic occupancy schedules.
class RatedCapacityGenerator
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param random_seed [Integer] the seed for the random number generator
  # @param debug [Boolean] If true, writes extra column(s) (e.g., sleeping) for informational purposes.
  def initialize(runner:,
                 geometry_unit_cfa:, # needs assessed floor area instead
                 geometry_unit_type:,
                 vintage:, # does this exist?
                 heating_system_fuel:,
                 cooling_system_type:,
                 water_heater_fuel_type:,
                 pv_system_present:, 
                 clothes_dyers:,
                 cooking_ranges:,
                 random_seed: nil,
                 debug:,
                 **)
    @runner = runner
    @geometry_unit_cfa = geometry_unit_cfa
    @geometry_unit_type = geometry_unit_type
    @vintage = vintage
    @heating_system_fuel = heating_system_fuel
    @cooling_system_type = cooling_system_type
    @water_heater_fuel_type = water_heater_fuel_type
    @pv_system_present = pv_system_present
    @clothes_dyers = clothes_dyers
    @cooking_ranges = cooking_ranges
    @random_seed = random_seed
    @debug = debug
  end

  # The top-level method for initializing the schedules hash just before calling the main stochastic schedules method.
  #
  # @param args [Hash] Map of :argument_name => value
  # @param weather [WeatherFile] Weather object containing EPW information
  # @return [Boolean] true if successful

  # The main method for stochastic assignment of electrical panel characteristics
  #
  # @param args [Hash] Map of :argument_name => value
  # @param weather [WeatherFile] Weather object containing EPW information
  # @return [Boolean] true if successful
  def create(args:)
    # initialize a random number generator
    prng = Random.new(@random_seed)

    # pre-load the probability distribution csv files for speed
    capacity_prob_map = read_panel_rated_capacity_probs(resources_path: args[:resources_path])

    # assign rated capacity
    capacity_bin = sample_rated_capacity_bin(prng, rated_capacity_map, args)
    args[:electrical_panel_rated_capacity] = convert_rated_capacity_bin_to_value(capacity_bin, heating_system_fuel, geometry_unit_cfa)
    args[:electrical_panel_rated_capacity_bin] = capacity_bin

    return args
  end


  # TODO
  #
  # @param prng [Random] Random number generator object
  # @param power_dist_map [TODO] TODO
  # @param appliance_name [TODO] TODO
  # @return [TODO] TODO
  def sample_rated_capacity_bin(prng, rated_capacity_map, args)
    row_probability = rated_capacity_map # DO sth
    capacity_bin] = weighted_random(prng, row_probability)
    
    return capacity_bin
  end


  def convert_rated_capacity_bin_to_value(capacity_bin, heating_system_fuel, geometry_unit_cfa)
    # DO sth


  # TODO
  #
  # @param resources_path [TODO] TODO
  # @return [TODO] TODO
  def read_panel_rated_capacity_probs(resources_path:)
    file = resources_path + "/electrical_panel_rated_capacity.csv"
    probabilities = CSV.read(file)
    probabilities = probabilities.map { |entry| entry[0].to_f }
    return probabilities
  end


  # TODO
  #
  # @param prng [Random] Random number generator object
  # @param weights [TODO] TODO
  # @return [TODO] TODO
  def weighted_random(prng, weights)
    n = prng.rand
    cum_weights = 0
    weights.each_with_index do |w, index|
      cum_weights += w
      if n <= cum_weights
        return index
      end
    end
    return weights.size - 1 # If the prob weight don't sum to n, return last index
  end

end
