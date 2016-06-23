
require "#{File.dirname(__FILE__)}/../dhw"
require "#{File.dirname(__FILE__)}/../recirculation"

require 'test/unit'

class Recirculation_Test < Test::Unit::TestCase
  
  def default_arguments
	{ :distribution_location => "Basement or Interior Space",
	:distribution_type => "Trunk and Branch",
	:pipe_material => "Copper",
	:recirculation_type => "None",
	:insulation_nominal_r_value => 3.0,
	:number_of_bedrooms => 3,
	:dhw_gains => MockDHWFormulas.new,
	:dhw_draws => MockDHWFormulas.new,
	:site_water_temp => MockDHWFormulas.new
	}
  end
  
  # Simple case not using a & b parameters
  def test_daily_usage_adjustment_case_1
	expected_adjustments = {:showers => -0.795, :sinks => -2.235, :baths => -0.09}
    formulas = RecirculationFormulas.new(default_arguments)
	
	for_all_fixtures do |e, m|
	  assert_in_delta(expected_adjustments[e], formulas.daily_usage_adjustment(e, m), 0.01, "Adjustment for equipment type #{e} and month #{m} did not match expected")
	end
  end

  # Case using parameters a-e (includes monthly variation)
  def test_daily_usage_adjustment_case_3
    # Expected adjustments taken from spreadsheet "Formulas for DHW Distribution.xlsx" with corrections for sin phase and apparent typos
	expected_adjustments = {:showers => [-3.31744, -3.16067, -2.98497, -2.83741, -2.75753, -2.76674, -2.86256, -3.01933, -3.19503, -3.34259, -3.42247, -3.41326],
							:sinks => [-3.59241, -3.35295, -3.08456, -2.85916, -2.73715, -2.75121, -2.89759, -3.13705, -3.40544, -3.63084, -3.75285, -3.73879],
							:baths => [-0.76089, -0.71892, -0.67188, -0.63237, -0.61099, -0.61345, -0.63911, -0.68108, -0.72812, -0.76763, -0.78901, -0.78655]}
    formulas = RecirculationFormulas.new(default_arguments.merge({ :distribution_location => "Attic" }))
	
	for_all_fixtures do |e, m|
	  assert_in_delta(expected_adjustments[e][m-1], formulas.daily_usage_adjustment(e, m), 0.01, "Adjustment for equipment type #{e} and month #{m} did not match expected")
	end
  end
  
  # Case using parameters a-f and avg_gpd
  def test_daily_usage_adjustment_case_4
    # Expected adjustments taken from spreadsheet "Formulas for DHW Distribution.xlsx" with corrections for sin phase and apparent typos
	expected_adjustments = {:showers => [-4.03877, -3.88808, -3.71919, -3.57736, -3.50058, -3.50943, -3.60154, -3.75222, -3.92111, -4.06295, -4.13973, -4.13088],
							:sinks => [-4.97178, -4.75302, -4.50784, -4.30193, -4.19047, -4.20332, -4.33704, -4.55580, -4.80098, -5.00689, -5.11835, -5.10550],
							:baths => [-0.86424, -0.82319, -0.77718, -0.73854, -0.71762, -0.72003, -0.74513, -0.78618, -0.83219, -0.87083, -0.89175, -0.88934]}
    formulas = RecirculationFormulas.new(default_arguments.merge({ :distribution_location => "Attic", :pipe_material => "Pex" }))
	
	for_all_fixtures do |e, m|
	  assert_in_delta(expected_adjustments[e][m-1], formulas.daily_usage_adjustment(e, m), 0.01, "Adjustment for equipment type #{e} and month #{m} did not match expected")
	end
  end
  
  # Case using parameters a-g and avg_gpd
  def test_daily_usage_adjustment_case_6
    # Expected adjustments taken from spreadsheet "Formulas for DHW Distribution.xlsx" with corrections for sin phase and apparent typos
	expected_adjustments = {:showers => [-4.344275, -4.196162, -4.030159, -3.890746, -3.815279, -3.823978, -3.914514, -4.062627, -4.228630, -4.368043, -4.443510, -4.434811],
							:sinks => [-5.183994, -4.968421, -4.726809, -4.523898, -4.414058, -4.426720, -4.558492, -4.774065, -5.015677, -5.218588, -5.328428, -5.315766],
							:baths => [-0.941758, -0.901394, -0.856154, -0.818161, -0.797595, -0.799966, -0.824639, -0.865003, -0.910242, -0.948235, -0.968802, -0.966431]}
    formulas = RecirculationFormulas.new(default_arguments.merge({ :distribution_type => "Home run", :distribution_location => "Attic" }))
	
	for_all_fixtures do |e, m|
	  assert_in_delta(expected_adjustments[e][m-1], formulas.daily_usage_adjustment(e, m), 0.01, "Adjustment for equipment type #{e} and month #{m} did not match expected")
	end
  end

  CASES = {
		{:distribution_location => "Basement or Interior Space", :distribution_type => "Trunk and Branch", :pipe_material => "Copper", :recirculation_type => "None"} => 1,
		{:distribution_location => "Basement or Interior Space", :distribution_type => "Trunk and Branch", :pipe_material => "Pex", :recirculation_type => "None"} => 2,
		{:distribution_location => "Attic", :distribution_type => "Trunk and Branch", :pipe_material => "Copper", :recirculation_type => "None"} => 3,
		{:distribution_location => "Garage", :distribution_type => "Trunk and Branch", :pipe_material => "Copper", :recirculation_type => "None"} => 3,
		{:distribution_location => "Attic", :distribution_type => "Trunk and Branch", :pipe_material => "Pex", :recirculation_type => "None"} => 4,
		{:distribution_location => "Garage", :distribution_type => "Trunk and Branch", :pipe_material => "Pex", :recirculation_type => "None"} => 4,
		{:distribution_location => "Basement or Interior Space", :distribution_type => "Home run", :pipe_material => "Copper", :recirculation_type => "None"} => 5,
		{:distribution_location => "Basement or Interior Space", :distribution_type => "Home run", :pipe_material => "Pex", :recirculation_type => "None"} => 5,
		{:distribution_location => "Attic", :distribution_type => "Home run", :pipe_material => "Copper", :recirculation_type => "None"} => 6,
		{:distribution_location => "Attic", :distribution_type => "Home run", :pipe_material => "Pex", :recirculation_type => "None"} => 6,
		{:distribution_location => "Garage", :distribution_type => "Home run", :pipe_material => "Copper", :recirculation_type => "None"} => 6,
		{:distribution_location => "Garage", :distribution_type => "Home run", :pipe_material => "Pex", :recirculation_type => "None"} => 6,
		{:distribution_location => "Basement or Interior Space", :distribution_type => "Trunk and Branch", :pipe_material => "Copper", :recirculation_type => "Timer"} => 7,
		{:distribution_location => "Basement or Interior Space", :distribution_type => "Trunk and Branch", :pipe_material => "Copper", :recirculation_type => "Demand"} => 8,
		{:distribution_location => "Basement or Interior Space", :distribution_type => "Trunk and Branch", :pipe_material => "Pex", :recirculation_type => "Timer"} => 9,
		{:distribution_location => "Basement or Interior Space", :distribution_type => "Trunk and Branch", :pipe_material => "Pex", :recirculation_type => "Demand"} => 10,
  }
  
  def test_all_cases_supported
	
	CASES.each do |filter, casenum|
		formulas = RecirculationFormulas.new(default_arguments.merge(filter))
		
		for_all_fixtures do |e, m|
			refute_nil formulas.daily_usage_adjustment(e, m), "Adjustment for equipment type #{e} and month #{m} not found for case #{casenum}"
		end
	end
  end
    
  def for_all_fixtures
	[:showers, :sinks, :baths].each do |e|
		(1..12).each do |m|
			yield(e, m)
		end
	end
  end
  
  def test_recovery_adjustment_zero_for_cases_1_to_8
		
	CASES.select {|k, v| v <= 8}.each do |filter, casenum|
		formulas = RecirculationFormulas.new(default_arguments.merge(filter))
		(1..12).each do |m|
			total_recovery = DHW::DEVTYPES.inject(0) {|sum,dt| sum + formulas.recovery_adjustment(dt, m)}
			assert_equal 0.0, total_recovery
		end
	end
  end
  
  def test_recovery_adjustment_case_9
	expected_adjustment = [1.042957, 1.038022, 1.040908, 1.050976, 1.065916, 1.082057, 1.095096, 1.101301, 1.098814, 1.088386, 1.073074, 1.057097]
	
	CASES.select {|k, v| v == 9}.each do |filter, casenum|
		formulas = RecirculationFormulas.new(default_arguments.merge(filter))
		(1..12).each do |m|
			total_recovery = DHW::DEVTYPES.inject(0) {|sum,dt| sum + formulas.recovery_adjustment(dt, m)}
			assert_in_delta expected_adjustment[m-1], total_recovery, 0.001, "Adjustment for month #{m} not as expected"
		end
	end
  end

  def test_recovery_adjustment_case_10
	expected_adjustment = [-3.452459, -3.436124, -3.445675, -3.479003, -3.528461, -3.581891, -3.625053, -3.645592, -3.637360, -3.602841, -3.552154, -3.499266]
	
	CASES.select {|k, v| v == 10}.each do |filter, casenum|
		formulas = RecirculationFormulas.new(default_arguments.merge(filter))
		(1..12).each do |m|
			total_recovery = DHW::DEVTYPES.inject(0) {|sum,dt| sum + formulas.recovery_adjustment(dt, m)}
			assert_in_delta expected_adjustment[m-1], total_recovery, 0.001, "Adjustment for month #{m} not as expected"
		end
	end
  end
  
  def test_internal_gains
	# These test data were generated using number of bedrooms = 2 as 3 bedrooms (used for the rest of the tests in this file) is a degenerate case in the gain equations
	expected_total_gains = {
		1 => [2446.83408735991,2371.12755386678,2286.2765698754,2215.01688802324,2176.44248251549,2180.88933415646,2227.16591264009,2302.87244613322,2387.7234301246,2458.98311197676,2497.55751748451,2493.11066584354],
		2 => [1846.60839754483,1778.1906830658,1701.50892089644,1637.10992728422,1602.24936056091,1606.26808142772,1648.08927687377,1716.5069913528,1793.18875352216,1857.58774713438,1892.44831385769,1888.42959299088],
		3 => [666.414162004528,645.794902882416,622.685082039235,603.276957307143,592.770920034707,593.982054424727,606.585837995472,627.205097117584,650.314917960765,669.723042692857,680.229079965293,679.017945575273],
		4 => [502.511031250772,486.963034590687,469.537024511615,454.902286341538,446.980186354571,447.893444844579,457.397354936684,472.945351596769,490.371361675841,505.006099845917,512.928199832885,512.014941342877],
		5 => [1983.01401859635,1921.65835987321,1852.89166595807,1795.13991695166,1763.87764736172,1767.48155707845,1804.98598140365,1866.34164012679,1935.10833404193,1992.86008304834,2024.12235263828,2020.51844292155],
		6 => [930.319733979427,901.535076096952,869.27357325843,842.179669096057,827.513153349945,829.203907070046,846.798894162457,875.583552044931,907.845054883453,934.938959045827,949.605474791938,947.914721071838],
		7 => [5893.02766825214,5710.69381127051,5506.33618893611,5334.71226112059,5241.80852068397,5252.51844985008,5363.97233174786,5546.30618872949,5750.66381106389,5922.28773887941,6015.19147931603,6004.48155014992],
		8 => [2861.96875387176,2773.41770153823,2674.17073331382,2590.82099418551,2545.70197944206,2550.90329264728,2605.03124612824,2693.58229846177,2792.82926668618,2876.17900581449,2921.29802055794,2916.09670735272],
		9 => [4443.65017972501,4306.16094295944,4152.06463859171,4022.65124693378,3952.59698177015,3960.67282687779,4044.7148660819,4182.20410284747,4336.3004072152,4465.71379887313,4535.76806403675,4527.69221892912],
		10 => [2158.07369037547,2091.30157903165,2016.4641893205,1953.61413937878,1919.59204933263,1923.51411073473,1964.32941039973,2031.10152174355,2105.93891145469,2168.78896139641,2202.81105144256,2198.88899004046]		
	}
	
	CASES.each do |filter, casenum|
		formulas = RecirculationFormulas.new(default_arguments.merge(filter).merge({:number_of_bedrooms => 2}))
		(1..12).each do |m|
			total_gains = [:showers, :sinks, :baths].inject(0) { |sum, dt| sum + formulas.internal_gains_adjustment(dt, m) }
			assert_in_delta expected_total_gains[casenum][m-1], total_gains, 0.001, "Internal gains adjustment for case #{casenum} month #{m} not as expected"
		end
	end
  end
  
  def test_internal_gains_apportioned_based_on_design_energy
	formulas = RecirculationFormulas.new(default_arguments)
	
	assert_in_delta 1.0/2.0, formulas.internal_gains_adjustment(:baths, 1) / formulas.internal_gains_adjustment(:sinks, 1), 0.001
	assert_in_delta 2.0/3.0, formulas.internal_gains_adjustment(:sinks, 1) / formulas.internal_gains_adjustment(:showers, 1), 0.001
  end
  
  def test_pump_internal_gains
	
	expected_gains = {
		1 => Array.new(12, 0),
		2 => Array.new(12, 0),
		3 => Array.new(12, 0),
		4 => Array.new(12, 0),
		5 => Array.new(12, 0),
		6 => Array.new(12, 0),
		7 => [16.3918, 14.8055, 16.3918, 15.8630, 16.3918, 15.8630, 16.3918, 16.3918, 15.8630, 16.3918, 15.8630, 16.3918],
		8 => [0.12400, 0.11200, 0.12400, 0.12000, 0.12400, 0.12000, 0.12400, 0.12400, 0.12000, 0.12400, 0.12000, 0.12400],
		9 => [16.391781, 14.805479, 16.391781, 15.863014, 16.391781, 15.863014, 16.391781, 16.391781, 15.863014, 16.391781, 15.863014, 16.391781],
		10 => [0.124000, 0.112000, 0.124000, 0.120000, 0.124000, 0.120000, 0.124000, 0.124000, 0.120000, 0.124000, 0.120000, 0.124000]
	}
  
	
	CASES.each do |filter, casenum|
		formulas = RecirculationFormulas.new(default_arguments.merge(filter))
		(1..12).each do |m|
			assert_in_delta expected_gains[casenum][m-1], formulas.pump_energy(m), 0.001, "Pump gains for case #{casenum} month #{m} not as expected"
		end
	end
	
  end

end

class MockDHWFormulas
	
	def initialize
		# Avg GPDs from spreadsheet "Formulas for DHW Distribution.xlsx"
		@avg_gpds = {:showers => 21.91547253, :sinks => 19.54475201, :baths => 5.48473625}
	end

	def avg_annual_gpd(equiptype)
		@avg_gpds[equiptype]
	end
	
	def site_water_mains_temp(month)
		[49.291008, 48.954855, 49.151800, 49.830507, 50.814061, 51.846082, 52.657559, 53.036968, 52.885409, 52.242390, 51.275523, 50.236836][month-1]
	end
	
  def design_btuperhr(devType)
	{:showers => 3000, :sinks => 2000, :baths => 1000 }[devType]
  end
 
end
