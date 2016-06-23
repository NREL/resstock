
require "#{File.dirname(__FILE__)}/../scheduledraws"
require "#{File.dirname(__FILE__)}/../dailyusage"
require "#{File.dirname(__FILE__)}/../sitewatermainstemperature"

require 'test/unit'

class ScheduleDraws_Test < Test::Unit::TestCase

  def newTester(args) # for initializing a Formulas object, stipulating only the arguments you care about for a test
    d=  {average_annual_temp: 70,  number_of_bedrooms: rand(1..5)}
    d[:max_monthly_average_temp] = d[:min_monthly_average_temp] = d[:average_annual_temp]
    
    g = lambda{|k| args.has_key?(k) ? args[k] : d[k]}
	
	@swmt = SiteWaterMainsTemperature.new(g[:average_annual_temp], g[:max_monthly_average_temp], g[:min_monthly_average_temp])
	
	daily_usage = StandardDailyUsage.new(g[:number_of_bedrooms], @swmt)
    
	StandardScheduleDraws.new(daily_usage)
  end

  def test_main_functions_DEVTYPES_coverage # confirm that the functions intended especially for export are defined for all device types
    formulas = newTester({})
   
    DHW::DEVTYPES.map{|devType|
        begin
            try = lambda{|m,f| refute_equal(nil , f[formulas.method(@tried = m)] , "#{m} on devType=#{devType}") }
            
            try[:peak_gph, lambda{|m| m.call(devType)}]
            try[:draw_profile, lambda{|m| m.call(devType,12,24)}]
        rescue StandardError => e
            refute(true, "Method #{@tried.to_s} failed on devType=#{devType.to_s} ; #{e.message} :: #{e.backtrace} ")
        end     
    }
    
  end 
  
  def test_daily_usage_gals_clothes_washer
    num_bdr = 2
    formulas = newTester(average_annual_temp:       44, 
                         max_monthly_average_temp:  44,
                         min_monthly_average_temp:  44,
                         number_of_bedrooms:        num_bdr
                        )
    
    assert_equal(2.35 + (0.78 * num_bdr) , formulas.daily_usage_gals(:clothes_washer , 1))
  end
  
  def test_daily_usage_gals_sinks_with_positive_ratio
    nbr = 2
    temp = 90
    month = 3
    
    formulas = newTester(average_annual_temp:       temp, 
                         max_monthly_average_temp:  temp,
                         min_monthly_average_temp:  temp,
                         number_of_bedrooms:        nbr
                        )
        
    swmt = @swmt.site_water_mains_temp(month)
    assert(swmt < 110 , "Test design assumes site_water_mains_temp is below 110 (it's #{swmt})")
    
    assert_equal(12.5 + (4.16 * nbr * (110 - swmt) / (125 - swmt) ), formulas.daily_usage_gals(:sinks , month))
  end
  
  def test_flowPortionByHour_Consistency
    newTester({}).flowPortionByHour
    .map{| devType , hoursMap | 
    
        assert_equal(24, hoursMap.size , "#{devType.to_s} flow should have 24 entries, not #{hoursMap.size}")
        
        (1..24).each{|i| assert(hoursMap.keys.include?(i) , "#{devType.to_s} flow should have an entry for hour=#{i}")}
        
        sum = hoursMap.values.reduce(:+).round(2)
        assert_equal(1, sum , "#{devType.to_s} flow should sum to 1.00, not #{sum}")
    } 
  end
  
  def test_flowPortionByHour_Coverage
    f = newTester({}).flowPortionByHour
    
    assert_equal(0.014 , f[:sinks][1] )
    assert_equal(0.011 , f[:showers][1] )
    assert_equal(0.008 , f[:baths][1] )
    assert_equal(0.015 , f[:dishwasher][1] )
    assert_equal(0.009 , f[:clothes_washer][1] )
    
  end
 
  def test_peak_gph_is_max_hourly_usage_gals
    
    nbr = 2
    temp = 90
    month = 3
    formulas = newTester(average_annual_temp:       temp, 
                         max_monthly_average_temp:  temp+10,
                         min_monthly_average_temp:  temp-10,
                         number_of_bedrooms:        nbr
                        )
  
    dailyByMonth = (1..12).map{|m| formulas.daily_usage_gals(:sinks,m)}
    refute_equal(dailyByMonth.min, dailyByMonth.max, "Test plan assumes that not all months have same daily usage")
        
    max_hourly_usage_gals = (1..12).map{|mo| (1..24).map{|hr| formulas.hourly_usage_gals(:sinks,mo,hr)}}.flatten.max # as in spec
    
    assert_equal(max_hourly_usage_gals , formulas.peak_gph(:sinks) , "peak_gph should calclate max of hourly_usage_gals")
  end

end
