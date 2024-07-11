# frozen_string_literal: true

# TODO
class UtilityBills
  # TODO
  #
  # @param fuel_type [TODO] TODO
  # @return [TODO] TODO
  def self.get_fuel_units(fuel_type)
    return { HPXML::FuelTypeElectricity => 'kwh',
             HPXML::FuelTypeNaturalGas => 'therm',
             HPXML::FuelTypeOil => 'gal_fuel_oil',
             HPXML::FuelTypePropane => 'gal_propane',
             HPXML::FuelTypeCoal => 'kbtu',
             HPXML::FuelTypeWoodCord => 'kbtu',
             HPXML::FuelTypeWoodPellets => 'kbtu' }[fuel_type]
  end

  # TODO
  #
  # @param runner [OpenStudio::Measure::OSRunner] OpenStudio Runner object
  # @param state_code [TODO] TODO
  # @param fuel_type [TODO] TODO
  # @param fixed_charge [TODO] TODO
  # @param marginal_rate [TODO] TODO
  # @return [TODO] TODO
  def self.get_rates_from_eia_data(runner, state_code, fuel_type, fixed_charge, marginal_rate = nil)
    msn_codes = Constants.StateCodesMap.keys
    msn_codes << 'US'
    return unless msn_codes.include? state_code # Check if the state_code is valid

    average_rate = nil
    if [HPXML::FuelTypeElectricity, HPXML::FuelTypeNaturalGas].include? fuel_type
      household_consumption = get_household_consumption(state_code, fuel_type)
      if not marginal_rate.nil?
        # Calculate average rate from user-specified fixed charge, user-specified marginal rate, and EIA data
        average_rate = marginal_rate_to_average_rate(marginal_rate, fixed_charge, household_consumption)
      else
        average_rate = get_eia_seds_rate(runner, state_code, fuel_type)
        marginal_rate = average_rate_to_marginal_rate(average_rate, fixed_charge, household_consumption)
      end
    elsif [HPXML::FuelTypeOil, HPXML::FuelTypePropane, HPXML::FuelTypeCoal, HPXML::FuelTypeWoodCord, HPXML::FuelTypeWoodPellets].include? fuel_type
      marginal_rate = get_eia_seds_rate(runner, state_code, fuel_type)
    end

    marginal_rate = marginal_rate.round(4) unless marginal_rate.nil?
    average_rate = average_rate.round(4) unless average_rate.nil?

    return marginal_rate, average_rate
  end

  # TODO
  #
  # @param state_code [TODO] TODO
  # @param fuel_type [TODO] TODO
  # @return [TODO] TODO
  def self.get_household_consumption(state_code, fuel_type)
    rows = CSV.read(File.join(File.dirname(__FILE__), '../../ReportUtilityBills/resources/simple_rates/HouseholdConsumption.csv'))
    rows.each do |row|
      next if row[0] != state_code

      if fuel_type == HPXML::FuelTypeElectricity
        return Float(row[1])
      elsif fuel_type == HPXML::FuelTypeNaturalGas
        return Float(row[2])
      end
    end
  end

  # TODO
  #
  # @param average_rate [TODO] TODO
  # @param fixed_charge [TODO] TODO
  # @param household_consumption [TODO] TODO
  # @return [TODO] TODO
  def self.average_rate_to_marginal_rate(average_rate, fixed_charge, household_consumption)
    return average_rate - 12.0 * fixed_charge / household_consumption
  end

  # TODO
  #
  # @param marginal_rate [TODO] TODO
  # @param fixed_charge [TODO] TODO
  # @param household_consumption [TODO] TODO
  # @return [TODO] TODO
  def self.marginal_rate_to_average_rate(marginal_rate, fixed_charge, household_consumption)
    return marginal_rate + 12.0 * fixed_charge / household_consumption
  end

  # TODO
  #
  # @param runner [OpenStudio::Measure::OSRunner] OpenStudio Runner object
  # @param state_code [TODO] TODO
  # @param fuel_type [TODO] TODO
  # @return [TODO] TODO
  def self.get_eia_seds_rate(runner, state_code, fuel_type)
    msn_code_map = {
      HPXML::FuelTypeElectricity => 'ESRCD',
      HPXML::FuelTypeNaturalGas => 'NGRCD',
      HPXML::FuelTypeOil => 'DFRCD',
      HPXML::FuelTypePropane => 'PQRCD',
      HPXML::FuelTypeCoal => 'CLRCD',
      HPXML::FuelTypeWoodCord => 'WDRCD',
      HPXML::FuelTypeWoodPellets => 'WDRCD'
    }

    CSV.foreach(File.join(File.dirname(__FILE__), '../../ReportUtilityBills/resources/simple_rates/pr_all_update.csv'), headers: true) do |row|
      next if row['State'].upcase != state_code.upcase # State
      next if row['MSN'].upcase != msn_code_map[fuel_type] # EIA SEDS MSN code

      seds_rate = row.to_h.values.reverse.find { |rate| rate.to_f != 0 } # If the rate for the latest year is unavailable, find the last non-nil/non-zero rate.
      begin
        seds_rate = Float(seds_rate)
      rescue ArgumentError, TypeError
        seds_rate = 0.0
        runner.registerWarning("No EIA SEDS rate for #{fuel_type} was found for the state of #{state_code}.") if not runner.nil?
      end

      # Convert $/MBtu to $/XXX
      seds_rate = UnitConversions.convert(seds_rate, get_fuel_units(fuel_type), 'mbtu')
      return seds_rate
    end
  end
end
