require "#{File.dirname(__FILE__)}/constants"
require "#{File.dirname(__FILE__)}/unit_conversions"

class Airflow

  def self.get_duct_location_frac_leakage(duct_location_frac, stories)
    if duct_location_frac == Constants.Auto
      # Duct location fraction per 2010 BA Benchmark
      if stories == 1
        duct_location_frac_leakage = 1
      else
        duct_location_frac_leakage = 0.65
      end
    else
      duct_location_frac_leakage = duct_location_frac.to_f
    end
    return duct_location_frac_leakage
  end

  def self.get_infiltration_ACH_from_SLA(sla, numStories, weather)
    # Returns the infiltration annual average ACH given a SLA.
    w = calc_infiltration_w_factor(weather)

    # Equation from ASHRAE 119-1998 (using numStories for simplification)
    norm_lkage = 1000.0 * sla * numStories ** 0.3

    # Equation from ASHRAE 136-1993
    return norm_lkage * w
  end  
  
  def self.get_infiltration_SLA_from_ACH(ach, numStories, weather)
    # Returns the infiltration SLA given an annual average ACH.
    w = calc_infiltration_w_factor(weather)
    
    return ach/(w * 1000 * numStories**0.3) 
  end

  def self.get_infiltration_SLA_from_ACH50(ach50, n_i, conditionedFloorArea, conditionedVolume, pressure_difference_Pa=50)
    # Returns the infiltration SLA given a ACH50.
    return ((ach50 * 0.2835 * 4.0 ** n_i * conditionedVolume) / (conditionedFloorArea * UnitConversions.convert(1.0,"ft^2","in^2") * pressure_difference_Pa ** n_i * 60.0))
  end  
  
  def self.get_infiltration_ACH50_from_SLA(sla, n_i, conditionedFloorArea, conditionedVolume, pressure_difference_Pa=50)
    # Returns the infiltration ACH50 given a SLA.
    return ((sla * conditionedFloorArea * UnitConversions.convert(1.0,"ft^2","in^2") * pressure_difference_Pa ** n_i * 60.0)/(0.2835 * 4.0 ** n_i * conditionedVolume))
  end


  def self.calc_duct_lkage_at_diff_pressure(q_old, p_old, p_new)
    return q_old * (p_new / p_old) ** 0.6 # Derived from Equation C-1 (Annex C), p34, ASHRAE Standard 152-2004.
  end
  
  def self.get_duct_insulation_rvalue(nominalR, isSupply)
    # Insulated duct values based on "True R-Values of Round Residential Ductwork" 
    # by Palmiter & Kruse 2006. Linear extrapolation from SEEM's "DuctTrueRValues"
    # worksheet in, e.g., ExistingResidentialSingleFamily_SEEMRuns_v05.xlsm.
    #
    # Nominal | 4.2 | 6.0 | 8.0 | 11.0
    # --------|-----|-----|-----|----
    # Supply  | 4.5 | 5.7 | 6.8 | 8.4
    # Return  | 4.9 | 6.3 | 7.8 | 9.7
    #
    # Uninsulated ducts are set to R-1.7 based on ASHRAE HOF and the above paper.
    if nominalR <=  0
      return 1.7
    end
    if isSupply
      return 2.2438 + 0.5619*nominalR
    else
      return 2.0388 + 0.7053*nominalR
    end
  end

  def self.get_duct_supply_surface_area(mult, ffa, num_stories)
    # Duct Surface Areas per 2010 BA Benchmark
    if num_stories == 1
      return 0.27 * ffa * mult # ft^2
    else
      return 0.2 * ffa * mult
    end
  end
  
  def self.get_duct_return_surface_area(mult, ffa, num_stories, duct_num_returns)
    # Duct Surface Areas per 2010 BA Benchmark
    if num_stories == 1
      return [0.05 * duct_num_returns * ffa, 0.25 * ffa].min * mult
    else
      return [0.04 * duct_num_returns * ffa, 0.19 * ffa].min * mult
    end
  end

  def self.get_duct_num_returns(duct_num_returns, num_stories)
    if duct_num_returns.nil?
      return 0
    elsif duct_num_returns == Constants.Auto
      # Duct Number Returns per 2010 BA Benchmark Addendum
      return 1 + num_stories
    end
    return duct_num_returns.to_i
  end  

  def self.get_mech_vent_whole_house_cfm(frac622, num_beds, ffa, std)
    # Returns the ASHRAE 62.2 whole house mechanical ventilation rate, excluding any infiltration credit.
    if std == '2013'
      return frac622 * ((num_beds + 1.0) * 7.5 + 0.03 * ffa)
    end
    return frac622 * ((num_beds + 1.0) * 7.5 + 0.01 * ffa)
  end  
  
  def self.calc_infiltration_w_factor(weather)
    # Returns a w factor for infiltration calculations; see ticket #852 for derivation.
    hdd65f = weather.data.HDD65F
    ws = weather.data.AnnualAvgWindspeed
    a = 0.36250748
    b = 0.365317169
    c = 0.028902855
    d = 0.050181043
    e = 0.009596674
    f = -0.041567541
    # in ACH
    w = (a + b * hdd65f / 10000.0 + c * (hdd65f / 10000.0) ** 2.0 + d * ws + e * ws ** 2 + f * hdd65f / 10000.0 * ws)
    return w
  end

end