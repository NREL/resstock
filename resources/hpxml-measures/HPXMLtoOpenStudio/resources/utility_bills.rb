# frozen_string_literal: true

class UtilityBills
  def self.get_rates_from_eia_data(runner, state_code, fuel_type, fixed_charge, marginal_rate = nil)
    if state_code == 'US'
      if fuel_type == HPXML::FuelTypeElectricity
        state_name = 'United States'
      else
        state_name = 'U.S.'
      end
    else
      state_name = Constants.StateCodesMap[state_code]
    end
    return if state_name.nil?

    average_rate = nil
    if fuel_type == HPXML::FuelTypeElectricity
      household_consumption = get_household_consumption(state_code, fuel_type)
      if not marginal_rate.nil?
        # Calculate average rate from user-specified fixed charge, user-specified marginal rate, and EIA data
        average_rate = marginal_rate_to_average_rate(marginal_rate, fixed_charge, household_consumption)
      else
        # Calculate marginal & average rates from user-specified fixed charge and EIA data
        year_ix = nil
        rows = CSV.read(File.join(File.dirname(__FILE__), '../../ReportUtilityBills/resources/simple_rates/Average_retail_price_of_electricity.csv'))
        rows.each do |row|
          year_ix = row.size - 1 if row[0] == 'description' # last item in the row
          next if row[0].upcase != "Residential : #{state_name}".upcase

          average_rate = Float(row[year_ix]) / 100.0 # Convert cents/kWh to $/kWh
        end
        marginal_rate = average_rate_to_marginal_rate(average_rate, fixed_charge, household_consumption)
      end

    elsif fuel_type == HPXML::FuelTypeNaturalGas
      household_consumption = get_household_consumption(state_code, fuel_type)
      if not marginal_rate.nil?
        # Calculate average rate from user-specified fixed charge, user-specified marginal rate, and EIA data
        average_rate = marginal_rate_to_average_rate(marginal_rate, fixed_charge, household_consumption)
      else
        # Calculate marginal & average rates from user-specified fixed charge and EIA data
        rows = CSV.read(File.join(File.dirname(__FILE__), '../../ReportUtilityBills/resources/simple_rates/NG_PRI_SUM_A_EPG0_PRS_DMCF_A.csv'))
        rows = rows[2..-1]
        state_ix = rows[0].index("#{state_name} Price of Natural Gas Delivered to Residential Consumers (Dollars per Thousand Cubic Feet)")
        rows[1..-1].each do |row|
          average_rate = Float(row[state_ix]) / 10.37 if !row[state_ix].nil? # Convert Mcf to therms, from https://www.eia.gov/tools/faqs/faq.php?id=45&t=7
        end
        marginal_rate = average_rate_to_marginal_rate(average_rate, fixed_charge, household_consumption)
      end

    elsif [HPXML::FuelTypeOil, HPXML::FuelTypePropane].include? fuel_type
      if fuel_type == HPXML::FuelTypeOil
        marginal_rates = get_gallon_marginal_rates('PET_PRI_WFR_A_EPD2F_PRS_DPGAL_W.csv')
        header = "Weekly #{state_name} Weekly No. 2 Heating Oil Residential Price  (Dollars per Gallon)"
      elsif fuel_type == HPXML::FuelTypePropane
        marginal_rates = get_gallon_marginal_rates('PET_PRI_WFR_A_EPLLPA_PRS_DPGAL_W.csv')
        header = "Weekly #{state_name} Propane Residential Price  (Dollars per Gallon)"
      end

      if marginal_rates[header].nil?
        padd = get_state_code_to_padd[state_code]
        marginal_rates.keys.each do |k|
          header = k if k.include?(padd)
        end
        average = "region (#{padd})"

        if marginal_rates[header].nil?
          if fuel_type == HPXML::FuelTypeOil
            header = 'Weekly U.S. Weekly No. 2 Heating Oil Residential Price  (Dollars per Gallon)'
          elsif fuel_type == HPXML::FuelTypePropane
            header = 'Weekly U.S. Propane Residential Price  (Dollars per Gallon)'
          end
          average = 'national'
        end

        runner.registerWarning("Could not find state average #{fuel_type} rate based on #{state_name}; using #{average} average.") if !runner.nil?
      end
      marginal_rate = marginal_rates[header].sum / marginal_rates[header].size
    end

    return marginal_rate, average_rate
  end

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

  def self.average_rate_to_marginal_rate(average_rate, fixed_charge, household_consumption)
    return average_rate - 12.0 * fixed_charge / household_consumption
  end

  def self.marginal_rate_to_average_rate(marginal_rate, fixed_charge, household_consumption)
    return marginal_rate + 12.0 * fixed_charge / household_consumption
  end

  def self.get_state_code_to_padd
    # https://www.eia.gov/tools/glossary/index.php?id=petroleum%20administration%20for%20defense%20district
    padd_to_state_codes = { 'PADD 1A' => ['CT', 'MA', 'ME', 'NH', 'RI', 'VT'],
                            'PADD 1B' => ['DE', 'DC', 'MD', 'NJ', 'NY', 'PA'],
                            'PADD 1C' => ['FL', 'GA', 'NC', 'SC', 'WV', 'VA'],
                            'PADD 2' => ['IA', 'IL', 'IN', 'KS', 'KY', 'MI', 'MN', 'MO', 'ND', 'NE', 'OH', 'OK', 'SD', 'TN', 'WI'],
                            'PADD 3' => ['AL', 'AR', 'LA', 'MS', 'NM', 'TX'],
                            'PADD 4' => ['CO', 'ID', 'MT', 'UT', 'WY'],
                            'PADD 5' => ['AK', 'AZ', 'CA', 'HI', 'NV', 'OR', 'WA'] }

    state_code_to_padd = {}
    padd_to_state_codes.each do |padd, state_codes|
      state_codes.each do |state_code|
        state_code_to_padd[state_code] = padd
      end
    end

    return state_code_to_padd
  end

  def self.get_gallon_marginal_rates(filename)
    marginal_rates = {}

    rows = CSV.read(File.join(File.dirname(__FILE__), "../../ReportUtilityBills/resources/simple_rates/#{filename}"))
    rows = rows[2..-1]
    headers = rows[0]

    rows = rows.reverse[1..26].transpose
    rows.each_with_index do |row, i|
      marginal_rates[headers[i]] = row
    end

    marginal_rates.delete('Date')
    marginal_rates.each do |header, values|
      if values.all? { |x| x.nil? }
        marginal_rates.delete(header)
        next
      end
      marginal_rates[header] = marginal_rates[header].map { |x| Float(x) }
    end

    return marginal_rates
  end
end
