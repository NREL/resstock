
require "#{File.dirname(__FILE__)}/../sitewatermainstemperature.rb"

require 'test/unit'

class SiteWaterMainsTemperature_Test < Test::Unit::TestCase

  def site_water_mains_temp_case(expectation, month, annual, maxMo, minMo)
	formulas = SiteWaterMainsTemperature.new(annual, maxMo, minMo)
    precision = 4
    assert_equal(expectation.round(precision) , formulas.site_water_mains_temp(month).round(precision) )
  end  

  def test_site_water_mains_temp_cases 
    #expectations were calculated following the (adjusted) spec by hand and using  a calculator, approximating pi by 3.1415927
    site_water_mains_temp_case(50, 1, 44, 44, 44)
    site_water_mains_temp_case(32, 1, -44, -44, -44)
    site_water_mains_temp_case(49.670389, 1, 44, 45, 43)
    site_water_mains_temp_case(50.6582, 1, 45, 45, 43)
    site_water_mains_temp_case(58.5398, 3, 60, 70, 35)
  end
  
end
