# Add classes or functions here than can be used across a variety of our python classes and modules.
require_relative "constants"
require_relative "unit_conversions"

class HelperMethods
  def self.eplus_fuel_map(fuel)
    if fuel == Constants.FuelTypeElectric
      return "Electricity"
    elsif fuel == Constants.FuelTypeGas
      return "NaturalGas"
    elsif fuel == Constants.FuelTypeOil
      return "FuelOil#1"
    elsif fuel == Constants.FuelTypePropane
      return "PropaneGas"
    elsif fuel == Constants.FuelTypeWood
      return "OtherFuel1"
    end
  end

  def self.reverse_eplus_fuel_map(fuel)
    if fuel == "Electricity"
      return Constants.FuelTypeElectric
    elsif fuel == "NaturalGas"
      return Constants.FuelTypeGas
    elsif fuel == "FuelOil#1"
      return Constants.FuelTypeOil
    elsif fuel == "PropaneGas"
      return Constants.FuelTypePropane
    elsif fuel == "OtherFuel1"
      return Constants.FuelTypeWood
    end
  end

  def self.reverse_openstudio_fuel_map(fuel)
    if fuel == "Electricity"
      return Constants.FuelTypeElectric
    elsif fuel == "Gas"
      return Constants.FuelTypeGas
    elsif fuel == "FuelOil#1"
      return Constants.FuelTypeOil
    elsif fuel == "Propane"
      return Constants.FuelTypePropane
    end
  end

  def self.remove_unused_constructions_and_materials(model, runner)
    # Code from https://bcl.nrel.gov/node/82267 (remove_orphan_objects_and_unused_resources measure)
    model.getConstructions.sort.each do |resource|
      if resource.directUseCount == 0
        runner.registerInfo("Removed construction '#{resource.name}' because it was orphaned.")
        resource.remove
      end
    end

    model.getMaterials.sort.each do |resource|
      if resource.directUseCount == 0
        runner.registerInfo("Removed material '#{resource.name}' because it was orphaned.")
        resource.remove
      end
    end
  end

  def self.state_code_map
    return { "Alabama" => "AL", "Alaska" => "AK", "Arizona" => "AZ", "Arkansas" => "AR", "California" => "CA", "Colorado" => "CO", "Connecticut" => "CT", "Delaware" => "DE", "District of Columbia" => "DC",
             "Florida" => "FL", "Georgia" => "GA", "Hawaii" => "HI", "Idaho" => "ID", "Illinois" => "IL", "Indiana" => "IN", "Iowa" => "IA", "Kansas" => "KS", "Kentucky" => "KY", "Louisiana" => "LA",
             "Maine" => "ME", "Maryland" => "MD", "Massachusetts" => "MA", "Michigan" => "MI", "Minnesota" => "MN", "Mississippi" => "MS", "Missouri" => "MO", "Montana" => "MT", "Nebraska" => "NE", "Nevada" => "NV",
             "New Hampshire" => "NH", "New Jersey" => "NJ", "New Mexico" => "NM", "New York" => "NY", "North Carolina" => "NC", "North Dakota" => "ND", "Ohio" => "OH", "Oklahoma" => "OK",
             "Oregon" => "OR", "Pennsylvania" => "PA", "Puerto Rico" => "PR", "Rhode Island" => "RI", "South Carolina" => "SC", "South Dakota" => "SD", "Tennessee" => "TN", "Texas" => "TX",
             "Utah" => "UT", "Vermont" => "VT", "Virginia" => "VA", "Washington" => "WA", "West Virginia" => "WV", "Wisconsin" => "WI", "Wyoming" => "WY" }
  end
end

class MathTools
  def self.valid_float?(str)
    !!Float(str) rescue false
  end

  def self.interp2(x, x0, x1, f0, f1)
    '''
    Returns the linear interpolation between two results.
    '''

    return f0 + ((x - x0) / (x1 - x0)) * (f1 - f0)
  end

  def self.interp4(x, y, x1, x2, y1, y2, fx1y1, fx1y2, fx2y1, fx2y2)
    '''
    Returns the bilinear interpolation between four results.
    '''

    return (fx1y1 / ((x2 - x1) * (y2 - y1))) * (x2 - x) * (y2 - y) \
          + (fx2y1 / ((x2 - x1) * (y2 - y1))) * (x - x1) * (y2 - y) \
          + (fx1y2 / ((x2 - x1) * (y2 - y1))) * (x2 - x) * (y - y1) \
          + (fx2y2 / ((x2 - x1) * (y2 - y1))) * (x - x1) * (y - y1)
  end

  def self.biquadratic(x, y, c)
    '''
    Description:
    ------------
        Calculate the result of a biquadratic polynomial with independent variables
        x and y, and a list of coefficients, c:
        z = c[1] + c[2]*x + c[3]*x**2 + c[4]*y + c[5]*y**2 + c[6]*x*y
    Inputs:
    -------
        x       float      independent variable 1
        y       float      independent variable 2
        c       tuple      list of 6 coeffients [floats]
    Outputs:
    --------
        z       float      result of biquadratic polynomial
    '''
    if c.length != 6
      puts "Error: There must be 6 coefficients in a biquadratic polynomial"
    end
    z = c[0] + c[1] * x + c[2] * x**2 + c[3] * y + c[4] * y**2 + c[5] * y * x
    return z
  end

  def self.quadratic(x, c)
    '''
    Description:
    ------------
        Calculate the result of a quadratic polynomial with independent variable
        x and a list of coefficients, c:

        y = c[1] + c[2]*x + c[3]*x**2

    Inputs:
    -------
        x       float      independent variable
        c       tuple      list of 6 coeffients [floats]

    Outputs:
    --------
        y       float      result of biquadratic polynomial
    '''
    if c.size != 3
      puts "Error: There must be 3 coefficients in a quadratic polynomial"
    end
    y = c[0] + c[1] * x + c[2] * x**2

    return y
  end

  def self.bicubic(x, y, c)
    '''
    Description:
    ------------
        Calculate the result of a bicubic polynomial with independent variables
        x and y, and a list of coefficients, c:

        z = c[1] + c[2]*x + c[3]*y + c[4]*x**2 + c[5]*x*y + c[6]*y**2 + \
            c[7]*x**3 + c[8]*y*x**2 + c[9]*x*y**2 + c[10]*y**3

    Inputs:
    -------
        x       float      independent variable 1
        y       float      independent variable 2
        c       tuple      list of 10 coeffients [floats]

    Outputs:
    --------
        z       float      result of bicubic polynomial
    '''
    if c.size != 10
      puts "Error: There must be 10 coefficients in a bicubic polynomial"
    end
    z = c[0] + c[1] * x + c[2] * y + c[3] * x**2 + c[4] * x * y + c[5] * y**2 + \
        c[6] * x**3 + c[7] * y * x**2 + c[8] * x * y**2 + c[9] * y**3

    return z
  end

  def self.Iterate(x0, f0, x1, f1, x2, f2, icount, cvg)
    '''
    Description:
    ------------
        Determine if a guess is within tolerance for convergence
        if not, output a new guess using the Newton-Raphson method
    Source:
    -------
        Based on XITERATE f77 code in ResAC (Brandemuehl)
    Inputs:
    -------
        x0      float    current guess value
        f0      float    value of function f(x) at current guess value
        x1,x2   floats   previous two guess values, used to create quadratic
                         (or linear fit)
        f1,f2   floats   previous two values of f(x)
        icount  int      iteration count
        cvg     bool     Has the iteration reached convergence?
    Outputs:
    --------
        x_new   float    new guess value
        cvg     bool     Has the iteration reached convergence?
        x1,x2   floats   updated previous two guess values, used to create quadratic
                         (or linear fit)
        f1,f2   floats   updated previous two values of f(x)
    Example:
    --------
        # Find a value of x that makes f(x) equal to some specific value f:
        # initial guess (all values of x)
        x = 1.0
        x1 = x
        x2 = x
        # initial error
        error = f - f(x)
        error1 = error
        error2 = error
        itmax = 50  # maximum iterations
        cvg = False # initialize convergence to "False"
        for i in range(1,itmax+1):
            error = f - f(x)
            x,cvg,x1,error1,x2,error2 = \
                                     Iterate(x,error,x1,error1,x2,error2,i,cvg)
            if cvg:
                break
        if cvg:
            print "x converged after", i, :iterations"
        else:
            print "x did NOT converge after", i, "iterations"
        print "x, when f(x) is", f,"is", x
    '''

    tolRel = 1e-5
    dx = 0.1

    # Test for convergence
    if ((x0 - x1).abs < tolRel * [x0.abs, Constants.small].max and icount != 1) or f0 == 0
      x_new = x0
      cvg = true
    else
      cvg = false

      if icount == 1 # Perturbation
        mode = 1
      elsif icount == 2 # Linear fit
        mode = 2
      else # Quadratic fit
        mode = 3
      end

      if mode == 3
        # Quadratic fit
        if x0 == x1 # If two xi are equal, use a linear fit
          x1 = x2
          f1 = f2
          mode = 2
        elsif x0 == x2 # If two xi are equal, use a linear fit
          mode = 2
        else
          # Set up quadratic coefficients
          c = ((f2 - f0) / (x2 - x0) - (f1 - f0) / (x1 - x0)) / (x2 - x1)
          b = (f1 - f0) / (x1 - x0) - (x1 + x0) * c
          a = f0 - (b + c * x0) * x0

          if c.abs < Constants.small # If points are co-linear, use linear fit
            mode = 2
          elsif ((a + (b + c * x1) * x1 - f1) / f1).abs > Constants.small
            # If coefficients do not accurately predict data points due to
            # round-off, use linear fit
            mode = 2
          else
            d = b**2 - 4.0 * a * c # calculate discriminant to check for real roots
            if d < 0.0 # if no real roots, use linear fit
              mode = 2
            else
              if d > 0.0 # if real unequal roots, use nearest root to recent guess
                x_new = (-b + Math.sqrt(d)) / (2 * c)
                x_other = -x_new - b / c
                if (x_new - x0).abs > (x_other - x0).abs
                  x_new = x_other
                end
              else # If real equal roots, use that root
                x_new = -b / (2 * c)
              end

              if f1 * f0 > 0 and f2 * f0 > 0 # If the previous two f(x) were the same sign as the new
                if f2.abs > f1.abs
                  x2 = x1
                  f2 = f1
                end
              else
                if f2 * f0 > 0
                  x2 = x1
                  f2 = f1
                end
              end
              x1 = x0
              f1 = f0
            end
          end
        end
      end

      if mode == 2
        # Linear Fit
        m = (f1 - f0) / (x1 - x0)
        if m == 0 # If slope is zero, use perturbation
          mode = 1
        else
          x_new = x0 - f0 / m
          x2 = x1
          f2 = f1
          x1 = x0
          f1 = f0
        end
      end

      if mode == 1
        # Perturbation
        if x0.abs > Constants.small
          x_new = x0 * (1 + dx)
        else
          x_new = dx
        end
        x2 = x1
        f2 = f1
        x1 = x0
        f1 = f0
      end
    end
    return x_new, cvg, x1, f1, x2, f2
  end
end

class UtilityBill
  def self.calculate_simple(annual_energy, fixed_rate, marginal_rate)
    total_annual_energy = annual_energy.inject(0) { |sum, x| sum + x }
    total_bill = 12.0 * fixed_rate + total_annual_energy * marginal_rate
    return total_bill
  end

  def self.remove_leap_day(timeseries)
    if timeseries.length == 8784 # leap year
      timeseries = timeseries[0..1415] + timeseries[1440..-1] # remove leap day
    end
    return timeseries
  end

  def self.calculate_simple_electric(load, gen, ur_monthly_fixed_charge, ur_flat_buy_rate, pv_compensation_type, pv_annual_excess_sellback_rate_type, pv_sellback_rate, pv_tariff_rate, test_name)
    analysis_period = 1
    degradation = [0]
    system_use_lifetime_output = 0
    inflation_rate = 0
    ur_flat_sell_rate = 0
    ur_nm_yearend_sell_rate = 0
    ur_enable_net_metering = 1
    ur_excess_monthly_energy_or_dollars = 0
    if pv_annual_excess_sellback_rate_type == Constants.PVNetMeteringExcessRetailElectricityCost
      pv_sellback_rate = ur_flat_buy_rate
    end
    if pv_compensation_type == Constants.PVTypeNetMetering
      ur_nm_yearend_sell_rate = pv_sellback_rate.to_f
    elsif pv_compensation_type == Constants.PVTypeFeedInTariff
      ur_enable_net_metering = 0
      ur_flat_sell_rate = pv_tariff_rate.to_f
    end

    p_data = SscApi.create_data_object
    SscApi.set_number(p_data, "analysis_period", analysis_period)
    SscApi.set_array(p_data, "degradation", degradation)
    SscApi.set_array(p_data, "gen", gen)
    SscApi.set_array(p_data, "load", load)
    SscApi.set_number(p_data, "system_use_lifetime_output", system_use_lifetime_output)
    SscApi.set_number(p_data, "inflation_rate", inflation_rate)
    SscApi.set_number(p_data, "ur_flat_buy_rate", ur_flat_buy_rate)
    SscApi.set_number(p_data, "ur_flat_sell_rate", ur_flat_sell_rate)
    SscApi.set_number(p_data, "ur_enable_net_metering", ur_enable_net_metering)
    SscApi.set_number(p_data, "ur_nm_yearend_sell_rate", ur_nm_yearend_sell_rate)
    SscApi.set_number(p_data, "ur_monthly_fixed_charge", ur_monthly_fixed_charge)
    SscApi.set_number(p_data, "ur_excess_monthly_energy_or_dollars", ur_excess_monthly_energy_or_dollars)

    p_mod = SscApi.create_module("utilityrate3")
    SscApi.execute_module(p_mod, p_data)

    utility_bills = SscApi.get_array(p_data, "utility_bill_w_sys")
    total_bill = utility_bills[1]

    unless test_name.nil?
      hourly = SscApi.get_array(p_data, "year1_hourly_ec_with_system")
      CSV.open("./measures/UtilityBillCalculations/tests/#{test_name}.csv", "w") do |csv|
        csv << ["year1_hourly_ec_with_system"]
        hourly.each do |val|
          csv << [val]
        end
      end
    end

    return total_bill
  end

  def self.calculate_detailed_electric(load, gen, pv_compensation_type, pv_annual_excess_sellback_rate_type, pv_sellback_rate, pv_tariff_rate, tariff, test_name)
    analysis_period = 1
    degradation = [0]
    system_use_lifetime_output = 0
    inflation_rate = 0
    ur_flat_buy_rate = 0
    ur_flat_sell_rate = 0
    ur_nm_yearend_sell_rate = 0
    ur_enable_net_metering = 1
    ur_excess_monthly_energy_or_dollars = 1
    if pv_annual_excess_sellback_rate_type == Constants.PVNetMeteringExcessUserSpecified
      pv_sellback_rate = pv_sellback_rate.to_f
    end
    if pv_compensation_type == Constants.PVTypeFeedInTariff
      ur_enable_net_metering = 0
      ur_flat_sell_rate = pv_tariff_rate.to_f
    end

    p_data = SscApi.create_data_object
    SscApi.set_number(p_data, "analysis_period", analysis_period)
    SscApi.set_array(p_data, "degradation", degradation)
    SscApi.set_array(p_data, "gen", gen)
    SscApi.set_array(p_data, "load", load)
    SscApi.set_number(p_data, "system_use_lifetime_output", system_use_lifetime_output)
    SscApi.set_number(p_data, "inflation_rate", inflation_rate)
    SscApi.set_number(p_data, "ur_flat_buy_rate", ur_flat_buy_rate)
    SscApi.set_number(p_data, "ur_flat_sell_rate", ur_flat_sell_rate)
    SscApi.set_number(p_data, "ur_enable_net_metering", ur_enable_net_metering)
    SscApi.set_number(p_data, "ur_nm_yearend_sell_rate", ur_nm_yearend_sell_rate)
    SscApi.set_number(p_data, "ur_excess_monthly_energy_or_dollars", ur_excess_monthly_energy_or_dollars)

    unless tariff[:fixedmonthlycharge].nil?
      SscApi.set_number(p_data, "ur_monthly_fixed_charge", tariff[:fixedmonthlycharge])
    end

    energyweekdayschedule = tariff[:energyweekdayschedule]
    energyweekdayschedule.each_with_index do |day_sch, i|
      shifted_day_sch = day_sch[1..-1] + [day_sch[0]]
      energyweekdayschedule[i] = shifted_day_sch
    end

    energyweekendschedule = tariff[:energyweekendschedule]
    energyweekendschedule.each_with_index do |day_sch, i|
      shifted_day_sch = day_sch[1..-1] + [day_sch[0]]
      energyweekendschedule[i] = shifted_day_sch
    end

    SscApi.set_number(p_data, "ur_ec_enable", 1)
    SscApi.set_matrix(p_data, "ur_ec_sched_weekday", Matrix.rows(energyweekdayschedule) + Matrix.rows(Array.new(12, Array.new(24, 1))))
    SscApi.set_matrix(p_data, "ur_ec_sched_weekend", Matrix.rows(energyweekendschedule) + Matrix.rows(Array.new(12, Array.new(24, 1))))
    tariff[:energyratestructure].each_with_index do |period, i|
      period_num = i + 1
      period.each_with_index do |tier, j|
        tier_num = j + 1
        rate = 0
        unless tier[:rate].nil?
          rate += tier[:rate]
        end
        unless tier[:adj].nil?
          rate += tier[:adj]
        end
        SscApi.set_number(p_data, "ur_ec_p#{period_num}_t#{tier_num}_br", rate)
        if pv_annual_excess_sellback_rate_type == Constants.PVNetMeteringExcessRetailElectricityCost
          SscApi.set_number(p_data, "ur_ec_p#{period_num}_t#{tier_num}_sr", rate)
        end
        max = 1000000000.0
        unless tier[:max].nil?
          max = tier[:max]
        end
        SscApi.set_number(p_data, "ur_ec_p#{period_num}_t#{tier_num}_ub", max)
      end
    end

    unless tariff[:demandratestructure].nil?
      SscApi.set_number(p_data, "ur_dc_enable", 1)
      SscApi.set_matrix(p_data, "ur_dc_sched_weekday", Matrix.rows(tariff[:demandweekdayschedule]))
      SscApi.set_matrix(p_data, "ur_dc_sched_weekend", Matrix.rows(tariff[:demandweekendschedule]))
      tariff[:demandratestructure].each_with_index do |period, i|
        period_num = i + 1
        period.each_with_index do |tier, j|
          tier_num = j + 1
          rate = tier[:rate]
          unless tier[:adj].nil?
            rate += tier[:adj]
          end
          SscApi.set_number(p_data, "ur_dc_p#{period_num}_t#{tier_num}_dc", rate)
          max = 1000000000.0
          unless tier[:max].nil?
            max = tier[:max]
          end
          SscApi.set_number(p_data, "ur_dc_p#{period_num}_t#{tier_num}_ub", max)
        end
      end
    end

    p_mod = SscApi.create_module("utilityrate3")
    SscApi.execute_module(p_mod, p_data)

    utility_bills = SscApi.get_array(p_data, "utility_bill_w_sys")
    total_bill = utility_bills[1]

    unless test_name.nil?
      hourly = SscApi.get_array(p_data, "year1_hourly_ec_with_system")
      CSV.open("./measures/UtilityBillCalculations/tests/#{test_name}.csv", "w") do |csv|
        csv << ["year1_hourly_ec_with_system"]
        hourly.each do |val|
          csv << [val]
        end
      end
    end

    return total_bill
  end

  def self.calculate_realtime_electric(load, gen, tariffs, test_name)
    rates = tariffs[:realtimepricing].split(",").collect { |i| i.to_f }
    net_facility = load.zip(gen).map { |x, y| x - y }
    hourly = net_facility.zip(rates).map { |x, y| x * y }
    marginal = hourly.inject(0) { |sum, x| sum + x }
    fixed = tariffs[:fixedmonthlycharge].to_f * 12.0
    total_bill = marginal + fixed

    unless test_name.nil?
      CSV.open("./measures/UtilityBillCalculations/tests/#{test_name}.csv", "w") do |csv|
        csv << ["year1_hourly_ec_with_system"]
        hourly.each do |val|
          csv << [val]
        end
      end
    end

    return total_bill
  end

  def self.validate_tariff(tariff)
    return false if tariff.nil?

    rate_structures_available = [:energyratestructure, :demandratestructure]
    rate_structures_contained = tariff.keys & rate_structures_available
    return false if rate_structures_contained.empty?

    return true
  end
end

class OutputVariables
  def self.zone_indoor_air_wetbulb_temperature(tdb, w, pr)
    tdb = tdb.collect { |n| UnitConversions.convert(n, "C", "F") } # degF
    pr = pr.collect { |n| UnitConversions.convert(n, "pa", "psi") } # psi
    twb = [tdb, w, pr].transpose.collect { |x, y, z| Psychrometrics.Twb_fT_w_P(x, y, z) } # degF
    twb = twb.collect { |n| UnitConversions.convert(n, "F", "C") } # degC
    return twb # degC
  end

  def self.wetbulb_globe_temperature(twb, mrt)
    twbg = [twb.collect { |n| n * 0.7 }, mrt.collect { |n| n * 0.3 }].transpose.map { |x| x.reduce(:+) } # degC
    return twbg # degC
  end
end
