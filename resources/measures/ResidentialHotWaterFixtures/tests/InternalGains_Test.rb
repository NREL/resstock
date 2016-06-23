
require "#{File.dirname(__FILE__)}/../internalgains"

require 'test/unit'

class InternalGains_Test < Test::Unit::TestCase

  def test_main_functions_DEVTYPES_coverage # confirm that the functions intended especially for export are defined for all device types
    formulas = InternalGains.new(rand(1..5))
   
    DHW::DEVTYPES.map{|devType|
        begin
            try = lambda{|m,f| refute_equal(nil , f[formulas.method(@tried = m)] , "#{m} on devType=#{devType}") }
            
            try[:design_btuperhr, lambda{|m| m.call(devType)}]
            try[:latent_fraction, lambda{|m| m.call(devType)}]
            try[:load_profile, lambda{|m| m.call(devType,1, 12)}] if formulas.gainPortionByHour_MAX[devType] >0
        rescue StandardError => e
            refute(true, "Method #{@tried.to_s} failed on devType=#{devType.to_s} ; #{e.message} :: #{e.backtrace} ")
        end     
    }
    
  end 
  
  def test_design_btuperhour_for_sinks
    num_bdr = 2
    sinks_daily_sense_internal_gain = 310 + 103 * (num_bdr) # copied from spec
    sinks_daily_latent_internal_gain = 147 + 47 * (num_bdr) # copied from spec
    
    max_hourly_gain = 0.075 # by inspection of spec's gain fraction table for sinks; this is for hour=19
    
    expected = (max_hourly_gain*sinks_daily_sense_internal_gain)+(max_hourly_gain*sinks_daily_latent_internal_gain ) 
    
    formulas = InternalGains.new(num_bdr)
    assert_equal(expected , formulas.design_btuperhr(:sinks))
  end
  
  def test_daily_sense_internal_gain_btu_sinks
    nbr = 2
    formulas = InternalGains.new(nbr)
    
    assert_equal(310 + (103 * nbr) , formulas.daily_sense_internal_gain_btu(:sinks))
  end
     
  def test_daily_latent_internal_gain_btu_sinks
    nbr = 2
    formulas = InternalGains.new(nbr)
    
    assert_equal(147 + (47 * nbr) , formulas.daily_latent_internal_gain_btu(:sinks))
  end
  
  def test_daily_latent_internal_gain_btu_baths_is_zero
	formulas = InternalGains.new(rand(1..5)) 
    assert_equal(0 , formulas.daily_latent_internal_gain_btu(:baths))
  end
  
  def test_hourly_latent_internal_gain_btu_dishwasher_is_zero
    formulas = InternalGains.new(rand(1..5)) 
    
    assert_equal(0 , formulas.daily_latent_internal_gain_btu(:dishwasher))
  end
  
  def test_peak_sense_internal_gain_btuperhr_is_max_hourly_sense_internal_gain_btu
    formulas = InternalGains.new(3) 
    
    max_hourly_sense_internal_gain_btu = (1..24).map{|h| formulas.hourly_sense_internal_gain_btu(:sinks,h)}.max 
    
    assert_equal(max_hourly_sense_internal_gain_btu , formulas.peak_sense_internal_gain_btuperhr(:sinks) )
  end
    
  def test_gainPortionByHour_Consistency
    InternalGains.new(rand(1..5)).gainPortionByHour
    .map{| devType , hoursMap | 
    
        assert_equal(24, hoursMap.size , "#{devType.to_s} gain should have 24 entries, not #{hoursMap.size}")
        
        (1..24).each{|i| assert(hoursMap.keys.include?(i) , "#{devType.to_s} gain should have an entry for hour=#{i}")}
        
        sum = hoursMap.values.reduce(:+).round(2)
        assert_equal(1, sum , "#{devType.to_s} gain should sum to 1.00, not #{sum}")
    } 
  end
  
  def test_gainPortionByHour_Coverage
    f = InternalGains.new(rand(1..5)).gainPortionByHour
    
    assert_equal(0.014 , f[:sinks][1] )
    assert_equal(0.011 , f[:showers][1] )
    assert_equal(0.008 , f[:baths][1] )
    
    dwkey = :dishwasher
    refute(f.has_key?(dwkey) , "Test plan assumes that there's no dishwasher key")
    assert_equal(0 , f[dwkey][2] , "Dishwasher gain portion should be zero even though no table was provided")
  end
 
  def test_latent_fraction
    formulas = InternalGains.new(rand(1..5))
    assert_equal(0.31222 , formulas.latent_fraction(:sinks) , "sinks")
    assert_equal(0 , formulas.latent_fraction(:baths) , "baths")
  end
end
