# frozen_string_literal: true

class Fuel
  def initialize(meters: [])
    @meters = meters
    @timeseries = []
  end
  attr_accessor(:meters, :timeseries, :units)
end

class UtilityRate
  def initialize()
    @fixedmonthlycharge = nil
    @flatratebuy = 0.0
    @realtimeprice = []

    @net_metering_excess_sellback_type = nil
    @net_metering_user_excess_sellback_rate = nil

    @feed_in_tariff_rate = nil

    @energyratestructure = []
    @energyweekdayschedule = []
    @energyweekendschedule = []

    @demandratestructure = []
    @demandweekdayschedule = []
    @demandweekendschedule = []

    @flatdemandstructure = []
  end
  attr_accessor(:fixedmonthlycharge, :flatratebuy, :realtimeprice,
                :net_metering_excess_sellback_type, :net_metering_user_excess_sellback_rate,
                :feed_in_tariff_rate,
                :energyratestructure, :energyweekdayschedule, :energyweekendschedule,
                :demandratestructure, :demandweekdayschedule, :demandweekendschedule,
                :flatdemandstructure)
end

class UtilityBill
  def initialize()
    @annual_energy_charge = 0.0
    @annual_fixed_charge = 0.0
    @annual_total = 0.0

    @monthly_energy_charge = []
    @monthly_fixed_charge = [0] * 12

    @monthly_production_credit = []
    @annual_production_credit = 0.0
  end
  attr_accessor(:annual_energy_charge, :annual_fixed_charge, :annual_total,
                :monthly_energy_charge, :monthly_fixed_charge,
                :monthly_production_credit, :annual_production_credit)
end

class CalculateUtilityBill
  def self.simple(fuel_type, header, fuel_time_series, is_production, rate, bill, net_elec)
    sum_fuel_time_series = fuel_time_series.sum
    monthly_fuel_cost = [0] * 12
    net_elec_cost = 0
    (0...fuel_time_series.size).to_a.each do |month|
      if is_production && fuel_type == FT::Elec && rate.feed_in_tariff_rate
        monthly_fuel_cost[month] = fuel_time_series[month] * rate.feed_in_tariff_rate
      else
        monthly_fuel_cost[month] = fuel_time_series[month] * rate.flatratebuy
      end

      if fuel_type == FT::Elec && sum_fuel_time_series != 0 # has PV
        if is_production
          net_elec -= fuel_time_series[month]
        else
          net_elec += fuel_time_series[month]
        end
      end

      if is_production
        bill.monthly_production_credit[month] = monthly_fuel_cost[month]
        bill.annual_production_credit += bill.monthly_production_credit[month]
      else
        bill.monthly_energy_charge[month] = monthly_fuel_cost[month]
        if not rate.fixedmonthlycharge.nil?
          # If the run period doesn't span the entire month, prorate the fixed charges
          prorate_fraction = calculate_monthly_prorate(header, month + 1)
          bill.monthly_fixed_charge[month] = rate.fixedmonthlycharge * prorate_fraction
        end

        bill.annual_energy_charge += bill.monthly_energy_charge[month]
        bill.annual_fixed_charge += bill.monthly_fixed_charge[month]
      end

      net_elec_cost = 0
    end
    return net_elec
  end

  def self.detailed_electric(fuels, rate, bill, net_elec)
    # TODO
    return net_elec
  end

  def self.calculate_monthly_prorate(header, month)
    begin_month = header.sim_begin_month
    begin_day = header.sim_begin_day
    end_month = header.sim_end_month
    end_day = header.sim_end_day
    year = header.sim_calendar_year

    if month < begin_month || month > end_month
      num_days_in_month = 0
    else
      if month == begin_month
        day_begin = begin_day
      else
        day_begin = 1
      end
      if month == end_month
        day_end = end_day
      else
        day_end = Constants.NumDaysInMonths(year)[month - 1]
      end
      num_days_in_month = day_end - day_begin + 1
    end

    return num_days_in_month.to_f / Constants.NumDaysInMonths(year)[month - 1]
  end
end
