require "#{File.dirname(__FILE__)}/constants"
require "#{File.dirname(__FILE__)}/geometry"

class HVAC

    def self.calc_EIR_from_COP(cop, supplyFanPower_Rated)
        return OpenStudio::convert((OpenStudio::convert(1,"Btu","W*h").get + supplyFanPower_Rated * 0.03333) / cop - supplyFanPower_Rated * 0.03333,"W*h","Btu").get
    end
  
    def self.calc_EIR_from_EER(eer, supplyFanPower_Rated)
        return OpenStudio::convert((1 - OpenStudio::convert(supplyFanPower_Rated * 0.03333,"W*h","Btu").get) / eer - supplyFanPower_Rated * 0.03333,"W*h","Btu").get
    end
    
    def self.calc_cfm_ton_rated(rated_airflow_rate, fanspeed_ratios, capacity_ratios)
        array = Array.new
        fanspeed_ratios.each_with_index do |fanspeed_ratio, i|
            capacity_ratio = capacity_ratios[i]
            array << fanspeed_ratio * rated_airflow_rate / capacity_ratio
        end
        return array
    end      
    
    def self.get_cooling_coefficients(runner, num_speeds, isHeatPump, curves)
        if not [1,2,4,Constants.Num_Speeds_MSHP].include? num_speeds
            runner.registerError("Number_Speeds = #{num_speeds} is not supported. Only 1, 2, 4, and 10 cooling equipment can be modeled.")
            return false
        end

        # Hard coded curves
        if isHeatPump
            if num_speeds == 1
                curves.COOL_CAP_FT_SPEC_coefficients = [3.68637657, -0.098352478, 0.000956357, 0.005838141, -0.0000127, -0.000131702]
                curves.COOL_EIR_FT_SPEC_coefficients = [-3.437356399, 0.136656369, -0.001049231, -0.0079378, 0.000185435, -0.0001441]
                curves.COOL_CAP_FFLOW_SPEC_coefficients = [0.718664047, 0.41797409, -0.136638137]
                curves.COOL_EIR_FFLOW_SPEC_coefficients = [1.143487507, -0.13943972, -0.004047787]
                
            elsif num_speeds == 2
                # one set for low, one set for high
                curves.COOL_CAP_FT_SPEC_coefficients = [[3.998418659, -0.108728222, 0.001056818, 0.007512314, -0.0000139, -0.000164716], [3.466810106, -0.091476056, 0.000901205, 0.004163355, -0.00000919, -0.000110829]]
                curves.COOL_EIR_FT_SPEC_coefficients = [[-4.282911381, 0.181023691, -0.001357391, -0.026310378, 0.000333282, -0.000197405], [-3.557757517, 0.112737397, -0.000731381, 0.013184877, 0.000132645, -0.000338716]]
                curves.COOL_CAP_FFLOW_SPEC_coefficients = [[0.655239515, 0.511655216, -0.166894731], [0.618281092, 0.569060264, -0.187341356]]
                curves.COOL_EIR_FFLOW_SPEC_coefficients = [[1.639108268, -0.998953996, 0.359845728], [1.570774717, -0.914152018, 0.343377302]]
        
            elsif num_speeds == 4
                curves.COOL_CAP_FT_SPEC_coefficients = [[3.63396857, -0.093606786, 0.000918114, 0.011852512, -0.0000318307, -0.000206446],
                                                        [1.808745668, -0.041963484, 0.000545263, 0.011346539, -0.000023838, -0.000205162],
                                                        [0.112814745, 0.005638646, 0.000203427, 0.011981545, -0.0000207957, -0.000212379],
                                                        [1.141506147, -0.023973142, 0.000420763, 0.01038334, -0.0000174633, -0.000197092]]
                curves.COOL_EIR_FT_SPEC_coefficients = [[-1.380674217, 0.083176919, -0.000676029, -0.028120348, 0.000320593, -0.0000616147],
                                                        [4.817787321, -0.100122768, 0.000673499, -0.026889359, 0.00029445, -0.0000390331],
                                                        [-1.502227232, 0.05896401, -0.000439349, 0.002198465, 0.000148486, -0.000159553],
                                                        [-3.443078025, 0.115186164, -0.000852001, 0.004678056, 0.000134319, -0.000171976]]
                curves.COOL_CAP_FFLOW_SPEC_coefficients = [[1, 0, 0], [1, 0, 0], [1, 0, 0], [1, 0, 0]]
                curves.COOL_EIR_FFLOW_SPEC_coefficients = [[1, 0, 0], [1, 0, 0], [1, 0, 0], [1, 0, 0]]
        
            elsif num_speeds == Constants.Num_Speeds_MSHP
                # NOTE: These coefficients are in SI UNITS, which differs from the coefficients for 1, 2, and 4 speed units, which are in IP UNITS
                curves.COOL_CAP_FT_SPEC_coefficients = [[1.008993521905866, 0.006512749025457, 0.0, 0.003917565735935, -0.000222646705889, 0.0]] * num_speeds
                curves.COOL_EIR_FT_SPEC_coefficients = [[0.429214441601141, -0.003604841598515, 0.000045783162727, 0.026490875804937, -0.000159212286878, -0.000159062656483]] * num_speeds
                
                curves.COOL_CAP_FFLOW_SPEC_coefficients = [[1, 0, 0]] * num_speeds
                curves.COOL_EIR_FFLOW_SPEC_coefficients = [[1, 0, 0]] * num_speeds

            end
                
        else #AC
            if num_speeds == 1
                curves.COOL_CAP_FT_SPEC_coefficients = [3.670270705, -0.098652414, 0.000955906, 0.006552414, -0.0000156, -0.000131877]
                curves.COOL_EIR_FT_SPEC_coefficients = [-3.302695861, 0.137871531, -0.001056996, -0.012573945, 0.000214638, -0.000145054]
                curves.COOL_CAP_FFLOW_SPEC_coefficients = [0.718605468, 0.410099989, -0.128705457]
                curves.COOL_EIR_FFLOW_SPEC_coefficients = [1.32299905, -0.477711207, 0.154712157]
                
            elsif num_speeds == 2
                # one set for low, one set for high
                curves.COOL_CAP_FT_SPEC_coefficients = [[3.940185508, -0.104723455, 0.001019298, 0.006471171, -0.00000953, -0.000161658], \
                                                        [3.109456535, -0.085520461, 0.000863238, 0.00863049, -0.0000210, -0.000140186]]
                curves.COOL_EIR_FT_SPEC_coefficients = [[-3.877526888, 0.164566276, -0.001272755, -0.019956043, 0.000256512, -0.000133539], \
                                                        [-1.990708931, 0.093969249, -0.00073335, -0.009062553, 0.000165099, -0.0000997]]
                curves.COOL_CAP_FFLOW_SPEC_coefficients = [[0.65673024, 0.516470835, -0.172887149], [0.690334551, 0.464383753, -0.154507638]]
                curves.COOL_EIR_FFLOW_SPEC_coefficients = [[1.562945114, -0.791859997, 0.230030877], [1.31565404, -0.482467162, 0.166239001]]

            elsif num_speeds == 4
                curves.COOL_CAP_FT_SPEC_coefficients = [[3.845135427537, -0.095933272242, 0.000924533273, 0.008939030321, -0.000021025870, -0.000191684744], \
                                                        [1.902445285801, -0.042809294549, 0.000555959865, 0.009928999493, -0.000013373437, -0.000211453245], \
                                                        [-3.176259152730, 0.107498394091, -0.000574951600, 0.005484032413, -0.000011584801, -0.000135528854], \
                                                        [1.216308942608, -0.021962441981, 0.000410292252, 0.007362335339, -0.000000025748, -0.000202117724]]
                curves.COOL_EIR_FT_SPEC_coefficients = [[-1.400822352, 0.075567798, -0.000589362, -0.024655521, 0.00032690848, -0.00010222178], \
                                                        [3.278112067, -0.07106453, 0.000468081, -0.014070845, 0.00022267912, -0.00004950051], \
                                                        [1.183747649, -0.041423179, 0.000390378, 0.021207528, 0.00011181091, -0.00034107189], \
                                                        [-3.97662986, 0.115338094, -0.000841943, 0.015962287, 0.00007757092, -0.00018579409]]
                curves.COOL_CAP_FFLOW_SPEC_coefficients = [[1, 0, 0], [1, 0, 0], [1, 0, 0], [1, 0, 0]]
                curves.COOL_EIR_FFLOW_SPEC_coefficients = [[1, 0, 0], [1, 0, 0], [1, 0, 0], [1, 0, 0]]
                
            elsif num_speeds == Constants.Num_Speeds_MSHP
                # NOTE: These coefficients are in SI UNITS, which differs from the coefficients for 1, 2, and 4 speed units, which are in IP UNITS
                curves.COOL_CAP_FT_SPEC_coefficients = [[1.008993521905866, 0.006512749025457, 0.0, 0.003917565735935, -0.000222646705889, 0.0]] * num_speeds
                curves.COOL_EIR_FT_SPEC_coefficients = [[0.429214441601141, -0.003604841598515, 0.000045783162727, 0.026490875804937, -0.000159212286878, -0.000159062656483]] * num_speeds
                
                curves.COOL_CAP_FFLOW_SPEC_coefficients = [[1, 0, 0]] * num_speeds
                curves.COOL_EIR_FFLOW_SPEC_coefficients = [[1, 0, 0]] * num_speeds
                
            end
        end
        return curves
    end

    def self.get_heating_coefficients(runner, num_speeds, curves, min_compressor_temp=nil)
        # Hard coded curves
        if num_speeds == 1
            curves.HEAT_CAP_FT_SPEC_coefficients = [0.566333415, -0.000744164, -0.0000103, 0.009414634, 0.0000506, -0.00000675]
            curves.HEAT_EIR_FT_SPEC_coefficients = [0.718398423, 0.003498178, 0.000142202, -0.005724331, 0.00014085, -0.000215321]
            curves.HEAT_CAP_FFLOW_SPEC_coefficients = [0.694045465, 0.474207981, -0.168253446]
            curves.HEAT_EIR_FFLOW_SPEC_coefficients = [2.185418751, -1.942827919, 0.757409168]

        elsif num_speeds == 2
            
            if min_compressor_temp.nil? or not self.is_cold_climate_hp(num_speeds, min_compressor_temp)
            
                # one set for low, one set for high
                curves.HEAT_CAP_FT_SPEC_coefficients = [[0.335690634, 0.002405123, -0.0000464, 0.013498735, 0.0000499, -0.00000725], [0.306358843, 0.005376987, -0.0000579, 0.011645092, 0.0000591, -0.0000203]]
                curves.HEAT_EIR_FT_SPEC_coefficients = [[0.36338171, 0.013523725, 0.000258872, -0.009450269, 0.000439519, -0.000653723], [0.981100941, -0.005158493, 0.000243416, -0.005274352, 0.000230742, -0.000336954]]
                curves.HEAT_CAP_FFLOW_SPEC_coefficients = [[0.741466907, 0.378645444, -0.119754733], [0.76634609, 0.32840943, -0.094701495]]
                curves.HEAT_EIR_FFLOW_SPEC_coefficients = [[2.153618211, -1.737190609, 0.584269478], [2.001041353, -1.58869128, 0.587593517]]
                
            else
                 
                #ORNL cold climate heat pump
                curves.HEAT_CAP_FT_SPEC_coefficients = [[0.821139, 0, 0, 0.005111, -0.00002778, 0], [0.821139, 0, 0, 0.005111, -0.00002778, 0]]   
                curves.HEAT_EIR_FT_SPEC_coefficients = [[1.244947090, 0, 0, -0.006455026, 0.000026455, 0], [1.244947090, 0, 0, -0.006455026, 0.000026455, 0]]
                curves.HEAT_CAP_FFLOW_SPEC_coefficients = [[1, 0, 0], [1, 0, 0]]
                curves.HEAT_EIR_FFLOW_SPEC_coefficients = [[1, 0, 0], [1, 0, 0]]
             
            end

        elsif num_speeds == 4
            curves.HEAT_CAP_FT_SPEC_coefficients = [[0.304192655, -0.003972566, 0.0000196432, 0.024471251, -0.000000774126, -0.0000841323],
                                                    [0.496381324, -0.00144792, 0.0, 0.016020855, 0.0000203447, -0.0000584118],
                                                    [0.697171186, -0.006189599, 0.0000337077, 0.014291981, 0.0000105633, -0.0000387956],
                                                    [0.555513805, -0.001337363, -0.00000265117, 0.014328826, 0.0000163849, -0.0000480711]]
            curves.HEAT_EIR_FT_SPEC_coefficients = [[0.708311527, 0.020732093, 0.000391479, -0.037640031, 0.000979937, -0.001079042],
                                                    [0.025480155, 0.020169585, 0.000121341, -0.004429789, 0.000166472, -0.00036447],
                                                    [0.379003189, 0.014195012, 0.0000821046, -0.008894061, 0.000151519, -0.000210299],
                                                    [0.690404655, 0.00616619, 0.000137643, -0.009350199, 0.000153427, -0.000213258]]
            curves.HEAT_CAP_FFLOW_SPEC_coefficients = [[1, 0, 0], [1, 0, 0], [1, 0, 0], [1, 0, 0]]
            curves.HEAT_EIR_FFLOW_SPEC_coefficients = [[1, 0, 0], [1, 0, 0], [1, 0, 0], [1, 0, 0]]
            
        elsif num_speeds == Constants.Num_Speeds_MSHP
            # NOTE: These coefficients are in SI UNITS, which differs from the coefficients for 1, 2, and 4 speed units, which are in IP UNITS
            curves.HEAT_CAP_FT_SPEC_coefficients = [[1.1527124655908571, -0.010386676170938, 0.0, 0.011263752411403, -0.000392549621117, 0.0]] * num_speeds            
            curves.HEAT_EIR_FT_SPEC_coefficients = [[0.966475472847719, 0.005914950101249, 0.000191201688297, -0.012965668198361, 0.000042253229429, -0.000524002558712]] * num_speeds
            
            curves.HEAT_CAP_FFLOW_SPEC_coefficients = [[1, 0, 0]] * num_speeds
            curves.HEAT_EIR_FFLOW_SPEC_coefficients = [[1, 0, 0]] * num_speeds
        end
        return curves
    end  
  
    def self._processCurvesSupplyFan(model)
      const_biquadratic = OpenStudio::Model::CurveBiquadratic.new(model)
      const_biquadratic.setName("ConstantBiquadratic")
      const_biquadratic.setCoefficient1Constant(1)
      const_biquadratic.setCoefficient2x(0)
      const_biquadratic.setCoefficient3xPOW2(0)
      const_biquadratic.setCoefficient4y(0)
      const_biquadratic.setCoefficient5yPOW2(0)
      const_biquadratic.setCoefficient6xTIMESY(0)
      const_biquadratic.setMinimumValueofx(-100)
      const_biquadratic.setMaximumValueofx(100)
      const_biquadratic.setMinimumValueofy(-100)
      const_biquadratic.setMaximumValueofy(100)   
      return const_biquadratic
    end
  
    def self._processCurvesDXCooling(model, supply, outputCapacity)

      const_biquadratic = self._processCurvesSupplyFan(model)
    
      clg_coil_stage_data = []
      (0...supply.Number_Speeds).to_a.each do |speed|
        # Cooling Capacity f(T). Convert DOE-2 curves to E+ curves
        if supply.Number_Speeds > 1.0
          c = supply.COOL_CAP_FT_SPEC_coefficients[speed]
        else
          c = supply.COOL_CAP_FT_SPEC_coefficients
        end
        cool_Cap_fT_coeff = Array.new
        cool_Cap_fT_coeff << c[0] + 32.0 * (c[1] + c[3]) + 1024.0 * (c[2] + c[4] + c[5])
        cool_Cap_fT_coeff << 9.0 / 5.0 * c[1] + 576.0 / 5.0 * c[2] + 288.0 / 5.0 * c[5]
        cool_Cap_fT_coeff << 81.0 / 25.0 * c[2]
        cool_Cap_fT_coeff << 9.0 / 5.0 * c[3] + 576.0 / 5.0 * c[4] + 288.0 / 5.0 * c[5]
        cool_Cap_fT_coeff << 81.0 / 25.0 * c[4]
        cool_Cap_fT_coeff << 81.0 / 25.0 * c[5]

        cool_cap_ft = OpenStudio::Model::CurveBiquadratic.new(model)
        if supply.Number_Speeds > 1.0
          cool_cap_ft.setName("Cool-Cap-fT#{speed + 1}")
        else
          cool_cap_ft.setName("Cool-Cap-fT")
        end
        cool_cap_ft.setCoefficient1Constant(cool_Cap_fT_coeff[0])
        cool_cap_ft.setCoefficient2x(cool_Cap_fT_coeff[1])
        cool_cap_ft.setCoefficient3xPOW2(cool_Cap_fT_coeff[2])
        cool_cap_ft.setCoefficient4y(cool_Cap_fT_coeff[3])
        cool_cap_ft.setCoefficient5yPOW2(cool_Cap_fT_coeff[4])
        cool_cap_ft.setCoefficient6xTIMESY(cool_Cap_fT_coeff[5])
        cool_cap_ft.setMinimumValueofx(13.88)
        cool_cap_ft.setMaximumValueofx(23.88)
        cool_cap_ft.setMinimumValueofy(18.33)
        cool_cap_ft.setMaximumValueofy(51.66)

        # Cooling EIR f(T) Convert DOE-2 curves to E+ curves
        if supply.Number_Speeds > 1.0
          c = supply.COOL_EIR_FT_SPEC_coefficients[speed]
        else
          c = supply.COOL_EIR_FT_SPEC_coefficients
        end
        cool_EIR_fT_coeff = Array.new
        cool_EIR_fT_coeff << c[0] + 32.0 * (c[1] + c[3]) + 1024.0 * (c[2] + c[4] + c[5])
        cool_EIR_fT_coeff << 9.0 / 5 * c[1] + 576.0 / 5 * c[2] + 288.0 / 5.0 * c[5]
        cool_EIR_fT_coeff << 81.0 / 25.0 * c[2]
        cool_EIR_fT_coeff << 9.0 / 5.0 * c[3] + 576.0 / 5.0 * c[4] + 288.0 / 5.0 * c[5]
        cool_EIR_fT_coeff << 81.0 / 25.0 * c[4]
        cool_EIR_fT_coeff << 81.0 / 25.0 * c[5]

        cool_eir_ft = OpenStudio::Model::CurveBiquadratic.new(model)
        if supply.Number_Speeds > 1.0
          cool_eir_ft.setName("Cool-EIR-fT#{speed + 1}")
        else
          cool_eir_ft.setName("Cool-EIR-fT")
        end
        cool_eir_ft.setCoefficient1Constant(cool_EIR_fT_coeff[0])
        cool_eir_ft.setCoefficient2x(cool_EIR_fT_coeff[1])
        cool_eir_ft.setCoefficient3xPOW2(cool_EIR_fT_coeff[2])
        cool_eir_ft.setCoefficient4y(cool_EIR_fT_coeff[3])
        cool_eir_ft.setCoefficient5yPOW2(cool_EIR_fT_coeff[4])
        cool_eir_ft.setCoefficient6xTIMESY(cool_EIR_fT_coeff[5])
        cool_eir_ft.setMinimumValueofx(13.88)
        cool_eir_ft.setMaximumValueofx(23.88)
        cool_eir_ft.setMinimumValueofy(18.33)
        cool_eir_ft.setMaximumValueofy(51.66)

        # Cooling PLF f(PLR) Convert DOE-2 curves to E+ curves
        cool_plf_fplr = OpenStudio::Model::CurveQuadratic.new(model)
        if supply.Number_Speeds > 1.0
          cool_plf_fplr.setName("Cool-PLF-fPLR#{speed + 1}")
        else
          cool_plf_fplr.setName("Cool-PLF-fPLR")
        end
        cool_plf_fplr.setCoefficient1Constant(supply.COOL_CLOSS_FPLR_SPEC_coefficients[0])
        cool_plf_fplr.setCoefficient2x(supply.COOL_CLOSS_FPLR_SPEC_coefficients[1])
        cool_plf_fplr.setCoefficient3xPOW2(supply.COOL_CLOSS_FPLR_SPEC_coefficients[2])
        cool_plf_fplr.setMinimumValueofx(0.0)
        cool_plf_fplr.setMaximumValueofx(1.0)
        cool_plf_fplr.setMinimumCurveOutput(0.7)
        cool_plf_fplr.setMaximumCurveOutput(1.0)

        # Cooling CAP f(FF) Convert DOE-2 curves to E+ curves
        cool_cap_fff = OpenStudio::Model::CurveQuadratic.new(model)
        if supply.Number_Speeds > 1.0
          cool_cap_fff.setName("Cool-Cap-fFF#{speed + 1}")
          cool_cap_fff.setCoefficient1Constant(supply.COOL_CAP_FFLOW_SPEC_coefficients[speed][0])
          cool_cap_fff.setCoefficient2x(supply.COOL_CAP_FFLOW_SPEC_coefficients[speed][1])
          cool_cap_fff.setCoefficient3xPOW2(supply.COOL_CAP_FFLOW_SPEC_coefficients[speed][2])
        else
          cool_cap_fff.setName("Cool-CAP-fFF")
          cool_cap_fff.setCoefficient1Constant(supply.COOL_CAP_FFLOW_SPEC_coefficients[0])
          cool_cap_fff.setCoefficient2x(supply.COOL_CAP_FFLOW_SPEC_coefficients[1])
          cool_cap_fff.setCoefficient3xPOW2(supply.COOL_CAP_FFLOW_SPEC_coefficients[2])
        end
        cool_cap_fff.setMinimumValueofx(0.0)
        cool_cap_fff.setMaximumValueofx(2.0)
        cool_cap_fff.setMinimumCurveOutput(0.0)
        cool_cap_fff.setMaximumCurveOutput(2.0)

        # Cooling EIR f(FF) Convert DOE-2 curves to E+ curves
        cool_eir_fff = OpenStudio::Model::CurveQuadratic.new(model)
        if supply.Number_Speeds > 1.0
          cool_eir_fff.setName("Cool-EIR-fFF#{speed + 1}")
          cool_eir_fff.setCoefficient1Constant(supply.COOL_EIR_FFLOW_SPEC_coefficients[speed][0])
          cool_eir_fff.setCoefficient2x(supply.COOL_EIR_FFLOW_SPEC_coefficients[speed][1])
          cool_eir_fff.setCoefficient3xPOW2(supply.COOL_EIR_FFLOW_SPEC_coefficients[speed][2])
        else
          cool_eir_fff.setName("Cool-EIR-fFF")
          cool_eir_fff.setCoefficient1Constant(supply.COOL_EIR_FFLOW_SPEC_coefficients[0])
          cool_eir_fff.setCoefficient2x(supply.COOL_EIR_FFLOW_SPEC_coefficients[1])
          cool_eir_fff.setCoefficient3xPOW2(supply.COOL_EIR_FFLOW_SPEC_coefficients[2])
        end
        cool_eir_fff.setMinimumValueofx(0.0)
        cool_eir_fff.setMaximumValueofx(2.0)
        cool_eir_fff.setMinimumCurveOutput(0.0)
        cool_eir_fff.setMaximumCurveOutput(2.0)

        stage_data = OpenStudio::Model::CoilCoolingDXMultiSpeedStageData.new(model, cool_cap_ft, cool_cap_fff, cool_eir_ft, cool_eir_fff, cool_plf_fplr, const_biquadratic)
        if outputCapacity != Constants.SizingAuto
          stage_data.setGrossRatedTotalCoolingCapacity(outputCapacity * OpenStudio::convert(1.0,"Btu/h","W").get * supply.Capacity_Ratio_Cooling[speed])
          stage_data.setRatedAirFlowRate(supply.CFM_TON_Rated[speed] * outputCapacity * OpenStudio::convert(1.0,"Btu/h","ton").get * OpenStudio::convert(1.0,"cfm","m^3/s").get * supply.Capacity_Ratio_Cooling[speed]) 
          stage_data.setGrossRatedSensibleHeatRatio(supply.SHR_Rated[speed])
        end
        stage_data.setGrossRatedCoolingCOP(1.0 / supply.CoolingEIR[speed])
        stage_data.setNominalTimeforCondensateRemovaltoBegin(1000)
        stage_data.setRatioofInitialMoistureEvaporationRateandSteadyStateLatentCapacity(1.5)
        stage_data.setMaximumCyclingRate(3)
        stage_data.setLatentCapacityTimeConstant(45)
        stage_data.setRatedWasteHeatFractionofPowerInput(0.2)
        clg_coil_stage_data[speed] = stage_data
      end
      return clg_coil_stage_data
    end
      
    def self._processCurvesDXHeating(model, supply, outputCapacity)
    
      const_biquadratic = self._processCurvesSupplyFan(model)
    
      htg_coil_stage_data = []
      # Loop through speeds to create curves for each speed
      (0...supply.Number_Speeds).to_a.each do |speed|
        # Heating Capacity f(T). Convert DOE-2 curves to E+ curves
        if supply.Number_Speeds > 1.0
          c = supply.HEAT_CAP_FT_SPEC_coefficients[speed]
        else
          c = supply.HEAT_CAP_FT_SPEC_coefficients
        end
        heat_Cap_fT_coeff = Array.new
        heat_Cap_fT_coeff << c[0] + 32.0 * (c[1] + c[3]) + 1024.0 * (c[2] + c[4] + c[5])
        heat_Cap_fT_coeff << 9.0 / 5.0 * c[1] + 576.0 / 5.0 * c[2] + 288.0 / 5.0 * c[5]
        heat_Cap_fT_coeff << 81.0 / 25.0 * c[2]
        heat_Cap_fT_coeff << 9.0 / 5.0 * c[3] + 576.0 / 5.0 * c[4] + 288.0 / 5.0 * c[5]
        heat_Cap_fT_coeff << 81.0 / 25.0 * c[4]
        heat_Cap_fT_coeff << 81.0 / 25.0 * c[5]

        hp_heat_cap_ft = OpenStudio::Model::CurveBiquadratic.new(model)
        if supply.Number_Speeds > 1.0
          hp_heat_cap_ft.setName("HP_Heat-Cap-fT#{speed + 1}")
        else
          hp_heat_cap_ft.setName("HP_Heat-Cap-fT")
        end
        hp_heat_cap_ft.setCoefficient1Constant(heat_Cap_fT_coeff[0])
        hp_heat_cap_ft.setCoefficient2x(heat_Cap_fT_coeff[1])
        hp_heat_cap_ft.setCoefficient3xPOW2(heat_Cap_fT_coeff[2])
        hp_heat_cap_ft.setCoefficient4y(heat_Cap_fT_coeff[3])
        hp_heat_cap_ft.setCoefficient5yPOW2(heat_Cap_fT_coeff[4])
        hp_heat_cap_ft.setCoefficient6xTIMESY(heat_Cap_fT_coeff[5])
        hp_heat_cap_ft.setMinimumValueofx(-100)
        hp_heat_cap_ft.setMaximumValueofx(100)
        hp_heat_cap_ft.setMinimumValueofy(-100)
        hp_heat_cap_ft.setMaximumValueofy(100)

        # Heating EIR f(T) Convert DOE-2 curves to E+ curves
        if supply.Number_Speeds > 1.0
          c = supply.HEAT_EIR_FT_SPEC_coefficients[speed]
        else
          c = supply.HEAT_EIR_FT_SPEC_coefficients
        end
        hp_heat_EIR_fT_coeff = Array.new
        hp_heat_EIR_fT_coeff << c[0] + 32.0 * (c[1] + c[3]) + 1024.0 * (c[2] + c[4] + c[5])
        hp_heat_EIR_fT_coeff << 9.0 / 5 * c[1] + 576.0 / 5 * c[2] + 288.0 / 5.0 * c[5]
        hp_heat_EIR_fT_coeff << 81.0 / 25.0 * c[2]
        hp_heat_EIR_fT_coeff << 9.0 / 5.0 * c[3] + 576.0 / 5.0 * c[4] + 288.0 / 5.0 * c[5]
        hp_heat_EIR_fT_coeff << 81.0 / 25.0 * c[4]
        hp_heat_EIR_fT_coeff << 81.0 / 25.0 * c[5]

        hp_heat_eir_ft = OpenStudio::Model::CurveBiquadratic.new(model)
        if supply.Number_Speeds > 1.0
          hp_heat_eir_ft.setName("HP_Heat-EIR-fT#{speed + 1}")
        else
          hp_heat_eir_ft.setName("HP_Heat-EIR-fT")
        end
        hp_heat_eir_ft.setCoefficient1Constant(hp_heat_EIR_fT_coeff[0])
        hp_heat_eir_ft.setCoefficient2x(hp_heat_EIR_fT_coeff[1])
        hp_heat_eir_ft.setCoefficient3xPOW2(hp_heat_EIR_fT_coeff[2])
        hp_heat_eir_ft.setCoefficient4y(hp_heat_EIR_fT_coeff[3])
        hp_heat_eir_ft.setCoefficient5yPOW2(hp_heat_EIR_fT_coeff[4])
        hp_heat_eir_ft.setCoefficient6xTIMESY(hp_heat_EIR_fT_coeff[5])
        hp_heat_eir_ft.setMinimumValueofx(-100)
        hp_heat_eir_ft.setMaximumValueofx(100)
        hp_heat_eir_ft.setMinimumValueofy(-100)
        hp_heat_eir_ft.setMaximumValueofy(100)

        hp_heat_plf_fplr = OpenStudio::Model::CurveQuadratic.new(model)
        if supply.Number_Speeds > 1.0
          hp_heat_plf_fplr.setName("HP_Heat-PLF-fPLR#{speed + 1}")
        else
          hp_heat_plf_fplr.setName("HP_Heat-PLF-fPLR")
        end
        hp_heat_plf_fplr.setCoefficient1Constant(supply.HEAT_CLOSS_FPLR_SPEC_coefficients[0])
        hp_heat_plf_fplr.setCoefficient2x(supply.HEAT_CLOSS_FPLR_SPEC_coefficients[1])
        hp_heat_plf_fplr.setCoefficient3xPOW2(supply.HEAT_CLOSS_FPLR_SPEC_coefficients[2])
        hp_heat_plf_fplr.setMinimumValueofx(-100)
        hp_heat_plf_fplr.setMaximumValueofx(100)
        hp_heat_plf_fplr.setMinimumCurveOutput(-100)
        hp_heat_plf_fplr.setMaximumCurveOutput(100)

        # Heating CAP f(FF) Convert DOE-2 curves to E+ curves
        hp_heat_cap_fff = OpenStudio::Model::CurveQuadratic.new(model)
        if supply.Number_Speeds > 1.0
          hp_heat_cap_fff.setName("HP_Heat-Cap-fFF#{speed + 1}")
          hp_heat_cap_fff.setCoefficient1Constant(supply.HEAT_CAP_FFLOW_SPEC_coefficients[speed][0])
          hp_heat_cap_fff.setCoefficient2x(supply.HEAT_CAP_FFLOW_SPEC_coefficients[speed][1])
          hp_heat_cap_fff.setCoefficient3xPOW2(supply.HEAT_CAP_FFLOW_SPEC_coefficients[speed][2])
        else
          hp_heat_cap_fff.setName("HP_Heat-CAP-fFF")
          hp_heat_cap_fff.setCoefficient1Constant(supply.HEAT_CAP_FFLOW_SPEC_coefficients[0])
          hp_heat_cap_fff.setCoefficient2x(supply.HEAT_CAP_FFLOW_SPEC_coefficients[1])
          hp_heat_cap_fff.setCoefficient3xPOW2(supply.HEAT_CAP_FFLOW_SPEC_coefficients[2])
        end
        hp_heat_cap_fff.setMinimumValueofx(0.0)
        hp_heat_cap_fff.setMaximumValueofx(2.0)
        hp_heat_cap_fff.setMinimumCurveOutput(0.0)
        hp_heat_cap_fff.setMaximumCurveOutput(2.0)

        # Heating EIR f(FF) Convert DOE-2 curves to E+ curves
        hp_heat_eir_fff = OpenStudio::Model::CurveQuadratic.new(model)
        if supply.Number_Speeds > 1.0
          hp_heat_eir_fff.setName("HP_Heat-EIR-fFF#{speed + 1}")
          hp_heat_eir_fff.setCoefficient1Constant(supply.HEAT_EIR_FFLOW_SPEC_coefficients[speed][0])
          hp_heat_eir_fff.setCoefficient2x(supply.HEAT_EIR_FFLOW_SPEC_coefficients[speed][1])
          hp_heat_eir_fff.setCoefficient3xPOW2(supply.HEAT_EIR_FFLOW_SPEC_coefficients[speed][2])
        else
          hp_heat_eir_fff.setName("HP_Heat-EIR-fFF")
          hp_heat_eir_fff.setCoefficient1Constant(supply.HEAT_EIR_FFLOW_SPEC_coefficients[0])
          hp_heat_eir_fff.setCoefficient2x(supply.HEAT_EIR_FFLOW_SPEC_coefficients[1])
          hp_heat_eir_fff.setCoefficient3xPOW2(supply.HEAT_EIR_FFLOW_SPEC_coefficients[2])
        end
        hp_heat_eir_fff.setMinimumValueofx(0.0)
        hp_heat_eir_fff.setMaximumValueofx(2.0)
        hp_heat_eir_fff.setMinimumCurveOutput(0.0)
        hp_heat_eir_fff.setMaximumCurveOutput(2.0)

        stage_data = OpenStudio::Model::CoilHeatingDXMultiSpeedStageData.new(model, hp_heat_cap_ft, hp_heat_cap_fff, hp_heat_eir_ft, hp_heat_eir_fff, hp_heat_plf_fplr, const_biquadratic)
        if outputCapacity != Constants.SizingAuto
          stage_data.setGrossRatedHeatingCapacity(outputCapacity * OpenStudio::convert(1.0,"Btu/h","W").get * supply.Capacity_Ratio_Heating[speed])
          stage_data.setRatedAirFlowRate(supply.CFM_TON_Rated_Heat[speed] * outputCapacity * OpenStudio::convert(1.0,"Btu/h","W").get * OpenStudio::convert(1.0,"cfm","m^3/s").get * supply.Capacity_Ratio_Heating[speed]) 
        end   
        stage_data.setGrossRatedHeatingCOP(1.0 / supply.HeatingEIR[speed])
        stage_data.setRatedWasteHeatFractionofPowerInput(0.2)
        htg_coil_stage_data[speed] = stage_data
      end
      return htg_coil_stage_data
    end
  
    def self.is_cold_climate_hp(num_speeds, min_compressor_temp)
        if num_speeds == 2.0 and min_compressor_temp == -99.9
            return true
        else
            return false
        end
    end
  
    def self._processAirSystemCoolingCoil(runner, number_Speeds, coolingEER, coolingSEER, supplyFanPower, supplyFanPower_Rated, shr_Rated, capacity_Ratio, fanspeed_Ratio, crankcase, crankcase_MaxT, eer_CapacityDerateFactor, supply)

        # if len(Capacity_Ratio) > len(set(Capacity_Ratio)):
        #     SimError("Capacity Ratio values must be unique ({})".format(Capacity_Ratio))

        # Curves are hardcoded for both one and two speed models
        supply.Number_Speeds = number_Speeds

        supply.CoolingEIR = Array.new
        supply.SHR_Rated = Array.new
        (0...supply.Number_Speeds).to_a.each do |speed|

          eir = calc_EIR_from_EER(coolingEER[speed], supplyFanPower_Rated)
          supply.CoolingEIR << eir

          # Convert SHRs from net to gross
          qtot_net_nominal = 12000.0
          qsens_net_nominal = qtot_net_nominal * shr_Rated[speed]
          qtot_gross_nominal = qtot_net_nominal + OpenStudio::convert(supply.CFM_TON_Rated[speed] * supplyFanPower_Rated,"Wh","Btu").get
          qsens_gross_nominal = qsens_net_nominal + OpenStudio::convert(supply.CFM_TON_Rated[speed] * supplyFanPower_Rated,"Wh","Btu").get
          supply.SHR_Rated << (qsens_gross_nominal / qtot_gross_nominal)

          # Make sure SHR's are in valid range based on E+ model limits.
          # The following correlation was devloped by Jon Winkler to test for maximum allowed SHR based on the 300 - 450 cfm/ton limits in E+
          maxSHR = 0.3821066 + 0.001050652 * supply.CFM_TON_Rated[speed] - 0.01
          supply.SHR_Rated[speed] = [supply.SHR_Rated[speed], maxSHR].min
          minSHR = 0.60   # Approximate minimum SHR such that an ADP exists
          supply.SHR_Rated[speed] = [supply.SHR_Rated[speed], minSHR].max
        end

        if supply.Number_Speeds == 1.0
            c_d = self.calc_Cd_from_SEER_EER_SingleSpeed(coolingSEER)
        elsif supply.Number_Speeds == 2.0
            c_d = self.calc_Cd_from_SEER_EER_TwoSpeed()
        elsif supply.Number_Speeds == 4.0
            c_d = self.calc_Cd_from_SEER_EER_FourSpeed()

        else
            runner.registerError("AC number of speeds must equal 1, 2, or 4.")
            return false
        end

        supply.COOL_CLOSS_FPLR_SPEC_coefficients = [(1.0 - c_d), c_d, 0.0]    # Linear part load model

        supply.Capacity_Ratio_Cooling = capacity_Ratio
        supply.fanspeed_ratio = fanspeed_Ratio
        supply.Crankcase = crankcase
        supply.Crankcase_MaxT = crankcase_MaxT

        # Supply Fan
        supply.fan_power = supplyFanPower
        supply.fan_power_rated = supplyFanPower_Rated
        supply.eff = OpenStudio::convert(supply.static / supply.fan_power,"cfm","m^3/s").get # Overall Efficiency of the Supply Fan, Motor and Drive
        supply.min_flow_ratio = fanspeed_Ratio[0] / fanspeed_Ratio[-1]

        supply.EER_CapacityDerateFactor = eer_CapacityDerateFactor

        return supply

    end

    def self._processAirSystemHeatingCoil(heatingCOP, heatingHSPF, supplyFanPower_Rated, capacity_Ratio, fanspeed_Ratio_Heating, min_T, cop_CapacityDerateFactor, supply)

        # if len(Capacity_Ratio) > len(set(Capacity_Ratio)):
        #     SimError("Capacity Ratio values must be unique ({})".format(Capacity_Ratio))

        supply.HeatingEIR = Array.new
        (0...supply.Number_Speeds).to_a.each do |speed|
          eir = calc_EIR_from_COP(heatingCOP[speed], supplyFanPower_Rated)
          supply.HeatingEIR << eir
        end

        if supply.Number_Speeds == 1.0
          c_d = self.calc_Cd_from_HSPF_COP_SingleSpeed(heatingHSPF)
        elsif supply.Number_Speeds == 2.0
          c_d = self.calc_Cd_from_HSPF_COP_TwoSpeed()
        elsif supply.Number_Speeds == 4.0
          c_d = self.calc_Cd_from_HSPF_COP_FourSpeed()
        else
          runner.registerError("HP number of speeds must equal 1, 2, or 4.")
          return false
        end

        supply.HEAT_CLOSS_FPLR_SPEC_coefficients = [(1 - c_d), c_d, 0] # Linear part load model

        supply.Capacity_Ratio_Heating = capacity_Ratio
        supply.fanspeed_ratio_heating = fanspeed_Ratio_Heating
        supply.max_temp = 105.0             # Hardcoded due to all heat pumps options having this value. Also effects the sizing so it shouldn't be a user variable
        supply.min_hp_temp = min_T          # Minimum temperature for Heat Pump operation
        supply.supp_htg_max_outdoor_temp = 40.0 # Moved from DOE-2. DOE-2 Default
        supply.max_defrost_temp = 40.0      # Moved from DOE-2. DOE-2 Default

        # Supply Air Tempteratures
        supply.htg_supply_air_temp = 105.0 # used for sizing heating flow rate
        supply.supp_htg_max_supply_temp = 170.0 # higher temp for supplemental heat as to not severely limit its use, resulting in unmet hours.    
        
        supply.COP_CapacityDerateFactor = cop_CapacityDerateFactor

        return supply

    end  
  
    def self.calc_Cd_from_SEER_EER_SingleSpeed(seer)
      # Use hard-coded Cd values
      if seer < 13.0
        return 0.20
      else
        return 0.07
      end
    end

    def self.calc_Cd_from_SEER_EER_TwoSpeed()
      # Use hard-coded Cd values
      return 0.11
    end

    def self.calc_Cd_from_SEER_EER_FourSpeed()
      # Use hard-coded Cd values
      return 0.25
    end

    def self.calc_Cd_from_HSPF_COP_SingleSpeed(hspf)
      # Use hard-coded Cd values
      if hspf < 7.0
          return 0.20
      else
          return 0.11
      end
    end

    def self.calc_Cd_from_HSPF_COP_TwoSpeed()
      # Use hard-coded Cd values
      return 0.11
    end

    def self.calc_Cd_from_HSPF_COP_FourSpeed()
      # Use hard-coded Cd values
      return 0.24
    end  
  
    def self.get_control_and_slave_zones(thermal_zones)
      control_slave_zones_hash = {}
      finished_above_grade_zones, finished_below_grade_zones = Geometry.get_finished_above_and_below_grade_zones(thermal_zones)
      control_zone = nil
      slave_zones = []
      [finished_above_grade_zones, finished_below_grade_zones].each do |finished_zones| # Preference to above-grade zone as control zone
        finished_zones.each do |finished_zone|
          if control_zone.nil?
            control_zone = finished_zone
          else
            slave_zones << finished_zone
          end
        end
      end
      unless control_zone.nil?
        control_slave_zones_hash[control_zone] = slave_zones
      end
      return control_slave_zones_hash
    end
  
    def self.existing_cooling_equipment(model, runner, thermal_zone)
      cooling_equipment = []
      model.getAirLoopHVACs.each do |air_loop|
        air_loop.thermalZones.each do |thermalZone|
          next unless thermal_zone.handle.to_s == thermalZone.handle.to_s
          air_loop.supplyComponents.each do |supply_component|
            next unless supply_component.to_AirLoopHVACUnitarySystem.is_initialized
            air_loop_unitary = supply_component.to_AirLoopHVACUnitarySystem.get
            next unless air_loop_unitary.coolingCoil.is_initialized and air_loop_unitary.heatingCoil.is_initialized
            clg_coil = air_loop_unitary.coolingCoil.get
            htg_coil = air_loop_unitary.heatingCoil.get              
            next unless ( clg_coil.to_CoilCoolingDXSingleSpeed.is_initialized and htg_coil.to_CoilHeatingDXSingleSpeed.is_initialized ) or ( clg_coil.to_CoilCoolingDXMultiSpeed.is_initialized and htg_coil.to_CoilHeatingDXMultiSpeed.is_initialized )
            runner.registerInfo("Found an air source heat pump.")
            if clg_coil.to_CoilCoolingDXSingleSpeed.is_initialized
              clg_coil = clg_coil.to_CoilCoolingDXSingleSpeed.get
            elsif clg_coil.to_CoilCoolingDXMultiSpeed.is_initialized
              clg_coil = clg_coil.to_CoilCoolingDXMultiSpeed.get
            end                        
            cooling_equipment << clg_coil
          end
        end
      end    
      model.getAirLoopHVACs.each do |air_loop|
        air_loop.thermalZones.each do |thermalZone|
          next unless thermal_zone.handle.to_s == thermalZone.handle.to_s
          air_loop.supplyComponents.each do |supply_component|
            next unless supply_component.to_AirLoopHVACUnitarySystem.is_initialized
            air_loop_unitary = supply_component.to_AirLoopHVACUnitarySystem.get
            next unless air_loop_unitary.coolingCoil.is_initialized
            clg_coil = air_loop_unitary.coolingCoil.get
            next unless clg_coil.to_CoilCoolingDXSingleSpeed.is_initialized or clg_coil.to_CoilCoolingDXMultiSpeed.is_initialized
            if air_loop_unitary.heatingCoil.is_initialized
              htg_coil = air_loop_unitary.heatingCoil.get
              next if htg_coil.to_CoilHeatingDXSingleSpeed.is_initialized or htg_coil.to_CoilHeatingDXMultiSpeed.is_initialized
            end
            runner.registerInfo("Found a central air conditioner.")
            if clg_coil.to_CoilCoolingDXSingleSpeed.is_initialized
              clg_coil = clg_coil.to_CoilCoolingDXSingleSpeed.get
            elsif clg_coil.to_CoilCoolingDXMultiSpeed.is_initialized
              clg_coil = clg_coil.to_CoilCoolingDXMultiSpeed.get
            end
            cooling_equipment << clg_coil
          end
        end
      end
      model.getZoneHVACPackagedTerminalAirConditioners.each do |ptac|
        next unless thermal_zone.handle.to_s == ptac.thermalZone.get.handle.to_s
        runner.registerInfo("Found a room air conditioner.")
        cooling_equipment << ptac
      end
      model.getZoneHVACTerminalUnitVariableRefrigerantFlows.each do |tu_vrf|
        next unless thermal_zone.handle.to_s == tu_vrf.thermalZone.get.handle.to_s
        runner.registerInfo("Found a mini-split heat pump.")
        cooling_equipment << tu_vrf
      end
      unless cooling_equipment.empty?
        return cooling_equipment
      end
      return nil
    end
    
    def self.existing_heating_equipment(model, runner, thermal_zone)
      heating_equipment = []
      model.getAirLoopHVACs.each do |air_loop|
        air_loop.thermalZones.each do |thermalZone|
          next unless thermal_zone.handle.to_s == thermalZone.handle.to_s
          air_loop.supplyComponents.each do |supply_component|
            next unless supply_component.to_AirLoopHVACUnitarySystem.is_initialized
            air_loop_unitary = supply_component.to_AirLoopHVACUnitarySystem.get
            next unless air_loop_unitary.coolingCoil.is_initialized and air_loop_unitary.heatingCoil.is_initialized
            clg_coil = air_loop_unitary.coolingCoil.get
            htg_coil = air_loop_unitary.heatingCoil.get              
            next unless ( clg_coil.to_CoilCoolingDXSingleSpeed.is_initialized and htg_coil.to_CoilHeatingDXSingleSpeed.is_initialized ) or ( clg_coil.to_CoilCoolingDXMultiSpeed.is_initialized and htg_coil.to_CoilHeatingDXMultiSpeed.is_initialized )
            runner.registerInfo("Found an air source heat pump.")
            heating_equipment << air_loop_unitary
          end
        end
      end    
      model.getAirLoopHVACs.each do |air_loop|
        air_loop.thermalZones.each do |thermalZone|
          next unless thermal_zone.handle.to_s == thermalZone.handle.to_s
          air_loop.supplyComponents.each do |supply_component|
            next unless supply_component.to_AirLoopHVACUnitarySystem.is_initialized
            air_loop_unitary = supply_component.to_AirLoopHVACUnitarySystem.get
            next unless air_loop_unitary.heatingCoil.is_initialized
            htg_coil = air_loop_unitary.heatingCoil.get
            next unless htg_coil.to_CoilHeatingGas.is_initialized or htg_coil.to_CoilHeatingElectric.is_initialized
            runner.registerInfo("Found a furnace.")
            if htg_coil.to_CoilHeatingGas.is_initialized
              htg_coil = htg_coil.to_CoilHeatingGas.get
            elsif htg_coil.to_CoilHeatingElectric.is_initialized
              htg_coil = htg_coil.to_CoilHeatingElectric.get
            end
            heating_equipment << htg_coil
          end
        end
      end
      model.getZoneHVACBaseboardConvectiveWaters.each do |baseboard|
        next unless thermal_zone.handle.to_s == baseboard.thermalZone.get.handle.to_s
        runner.registerInfo("Found a boiler.")
        heating_equipment << baseboard
      end
      model.getZoneHVACBaseboardConvectiveElectrics.each do |baseboard|
        next unless thermal_zone.handle.to_s == baseboard.thermalZone.get.handle.to_s
        runner.registerInfo("Found an electric baseboard.")
        heating_equipment << baseboard
      end
      model.getZoneHVACTerminalUnitVariableRefrigerantFlows.each do |tu_vrf|
        next unless thermal_zone.handle.to_s == tu_vrf.thermalZone.get.handle.to_s
        runner.registerInfo("Found a mini-split heat pump.")
        heating_equipment << tu_vrf
      end
      unless heating_equipment.empty?
        return heating_equipment
      end
      return nil
    end    
    
    def self.has_central_air_conditioner(model, runner, thermal_zone, remove=false, reset_air_loop=true)
      model.getAirLoopHVACs.each do |air_loop|
        air_loop.thermalZones.each do |thermalZone|
          next unless thermal_zone.handle.to_s == thermalZone.handle.to_s
          air_loop.supplyComponents.each do |supply_component|
            next unless supply_component.to_AirLoopHVACUnitarySystem.is_initialized
            air_loop_unitary = supply_component.to_AirLoopHVACUnitarySystem.get
            next unless air_loop_unitary.coolingCoil.is_initialized
            clg_coil = air_loop_unitary.coolingCoil.get
            next unless clg_coil.to_CoilCoolingDXSingleSpeed.is_initialized or clg_coil.to_CoilCoolingDXMultiSpeed.is_initialized
            if remove
              runner.registerInfo("Removed '#{clg_coil.name}' from air loop '#{air_loop.name}'")
              air_loop_unitary.resetCoolingCoil
              clg_coil.remove
              model.getScheduleConstants.each do |s|
                next if !s.name.to_s.start_with?("SupplyFanAvailability")
                s.remove
              end
              air_loop_unitary.supplyFan.get.remove
              if air_loop_unitary.supplyAirFanOperatingModeSchedule.is_initialized
                air_loop_unitary.supplyAirFanOperatingModeSchedule.get.remove
              end
              return true
            else
              if reset_air_loop
                cloned_clg_coil = clg_coil.clone
                air_loop_unitary.resetCoolingCoil
                clg_coil.remove
                model.getScheduleConstants.each do |s|
                  next if !s.name.to_s.start_with?("SupplyFanAvailability")
                  s.remove
                end
                air_loop_unitary.supplyFan.get.remove
                if air_loop_unitary.supplyAirFanOperatingModeSchedule.is_initialized
                  air_loop_unitary.supplyAirFanOperatingModeSchedule.get.remove
                end
                if cloned_clg_coil.to_CoilCoolingDXSingleSpeed.is_initialized
                  cloned_clg_coil = cloned_clg_coil.to_CoilCoolingDXSingleSpeed.get
                elsif cloned_clg_coil.to_CoilCoolingDXMultiSpeed.is_initialized
                  cloned_clg_coil = cloned_clg_coil.to_CoilCoolingDXMultiSpeed.get
                end        
                return cloned_clg_coil
              else
                return true
              end
            end
          end
        end
      end
      return nil
    end
    
    def self.has_room_air_conditioner(model, runner, thermal_zone, remove=false)
      model.getZoneHVACPackagedTerminalAirConditioners.each do |ptac|
        next unless thermal_zone.handle.to_s == ptac.thermalZone.get.handle.to_s
        if remove
          runner.registerInfo("Removed packaged terminal air conditioner '#{ptac.name}'")
          ptac.remove
          return true
        end
      end
      return nil
    end
    
    def self.has_furnace(model, runner, thermal_zone, remove=false, reset_air_loop=true)
      model.getAirLoopHVACs.each do |air_loop|
        air_loop.thermalZones.each do |thermalZone|
          next unless thermal_zone.handle.to_s == thermalZone.handle.to_s
          air_loop.supplyComponents.each do |supply_component|
            next unless supply_component.to_AirLoopHVACUnitarySystem.is_initialized
            air_loop_unitary = supply_component.to_AirLoopHVACUnitarySystem.get
            next unless air_loop_unitary.heatingCoil.is_initialized
            htg_coil = air_loop_unitary.heatingCoil.get
            next unless htg_coil.to_CoilHeatingGas.is_initialized or htg_coil.to_CoilHeatingElectric.is_initialized
            if remove
              runner.registerInfo("Removed '#{htg_coil.name}' from air loop '#{air_loop.name}'")
              air_loop_unitary.resetHeatingCoil
              htg_coil.remove
              model.getScheduleConstants.each do |s|
                next if !s.name.to_s.start_with?("SupplyFanAvailability")
                s.remove
              end
              air_loop_unitary.supplyFan.get.remove
              if air_loop_unitary.supplyAirFanOperatingModeSchedule.is_initialized
                air_loop_unitary.supplyAirFanOperatingModeSchedule.get.remove
              end
              return true
            else
              if reset_air_loop
                cloned_htg_coil = htg_coil.clone
                air_loop_unitary.resetHeatingCoil
                htg_coil.remove
                model.getScheduleConstants.each do |s|
                  next if !s.name.to_s.start_with?("SupplyFanAvailability")
                  s.remove
                end
                air_loop_unitary.supplyFan.get.remove
                if air_loop_unitary.supplyAirFanOperatingModeSchedule.is_initialized
                  air_loop_unitary.supplyAirFanOperatingModeSchedule.get.remove
                end
                if cloned_htg_coil.to_CoilHeatingGas.is_initialized
                  cloned_htg_coil = cloned_htg_coil.to_CoilHeatingGas.get
                elsif cloned_htg_coil.to_CoilHeatingElectric.is_initialized
                  cloned_htg_coil = cloned_htg_coil.to_CoilHeatingElectric.get
                end
                return cloned_htg_coil
              else
                return true
              end
            end
          end
        end
      end
      return nil
    end
    
    def self.has_boiler(model, runner, thermal_zone, remove=false)
      model.getZoneHVACBaseboardConvectiveWaters.each do |baseboard|
        next unless thermal_zone.handle.to_s == baseboard.thermalZone.get.handle.to_s
        if remove
          runner.registerInfo("Removed baseboard convective water '#{baseboard.name}'")
          baseboard.remove
          return true
        end
      end
      return nil
    end
    
    def self.has_electric_baseboard(model, runner, thermal_zone, remove=false)
      model.getZoneHVACBaseboardConvectiveElectrics.each do |baseboard|
        next unless thermal_zone.handle.to_s == baseboard.thermalZone.get.handle.to_s
        if remove
          runner.registerInfo("Removed baseboard convective electric '#{baseboard.name}'")
          baseboard.remove
          return true
        end
      end
      return nil
    end
    
    def self.has_air_source_heat_pump(model, runner, thermal_zone, remove=false)
      model.getAirLoopHVACs.each do |air_loop|
        air_loop.thermalZones.each do |thermalZone|
          next unless thermal_zone.handle.to_s == thermalZone.handle.to_s
          air_loop.supplyComponents.each do |supply_component|
            next unless supply_component.to_AirLoopHVACUnitarySystem.is_initialized
            air_loop_unitary = supply_component.to_AirLoopHVACUnitarySystem.get
            next unless air_loop_unitary.coolingCoil.is_initialized and air_loop_unitary.heatingCoil.is_initialized
            clg_coil = air_loop_unitary.coolingCoil.get
            htg_coil = air_loop_unitary.heatingCoil.get              
            next unless ( clg_coil.to_CoilCoolingDXSingleSpeed.is_initialized and htg_coil.to_CoilHeatingDXSingleSpeed.is_initialized ) or ( clg_coil.to_CoilCoolingDXMultiSpeed.is_initialized and htg_coil.to_CoilHeatingDXMultiSpeed.is_initialized )
            if remove
              runner.registerInfo("Removed '#{clg_coil.name}' and '#{htg_coil.name}' from air loop '#{air_loop.name}'")
              air_loop_unitary.resetHeatingCoil
              air_loop_unitary.resetCoolingCoil              
              htg_coil.remove
              clg_coil.remove
              supply_fan = air_loop_unitary.supplyFan.get.to_FanOnOff.get
              supply_fan.fanPowerRatioFunctionofSpeedRatioCurve.remove
              supply_fan.fanEfficiencyRatioFunctionofSpeedRatioCurve.remove
              availability_schedule = supply_fan.availabilitySchedule
              availability_schedule.remove
              supply_fan.remove
              if air_loop_unitary.supplyAirFanOperatingModeSchedule.is_initialized
                air_loop_unitary.supplyAirFanOperatingModeSchedule.get.remove
              end
              return true
            else
              return true
            end
          end
        end
      end
      return nil
    end
    
    def self.has_mini_split_heat_pump(model, runner, thermal_zone, remove=false)
      model.getAirConditionerVariableRefrigerantFlows.each do |vrf|
        vrf.terminals.each do |terminal|
          next unless thermal_zone.handle.to_s == terminal.thermalZone.get.handle.to_s
          if remove
            runner.registerInfo("Removed variable refrigerant flow terminal unit '#{terminal.name}'")
            terminal.remove
            vrf.remove
          end
          return true
        end        
      end
      return nil
    end
    
    def self.has_air_loop(model, runner, thermal_zone, remove=false)
      model.getAirLoopHVACs.each do |air_loop|
        air_loop.thermalZones.each do |thermalZone|
          next unless thermal_zone.handle.to_s == thermalZone.handle.to_s
          air_loop.supplyComponents.each do |supply_component|
            next unless supply_component.to_AirLoopHVACUnitarySystem.is_initialized
            air_loop_unitary = supply_component.to_AirLoopHVACUnitarySystem.get
            next if air_loop_unitary.heatingCoil.is_initialized or air_loop_unitary.coolingCoil.is_initialized
            if remove
              runner.registerInfo("Removed air loop '#{air_loop.name}'")
              air_loop.remove
              return true
            end
          end
        end
      end
      return nil
    end
    
    def self.remove_existing_hvac_equipment(model, runner, new_equip, thermal_zone)
      counterpart_equip = nil
      case new_equip
      when "Central Air Conditioner"
        removed_ashp = self.has_air_source_heat_pump(model, runner, thermal_zone, true)
        removed_mshp = self.has_mini_split_heat_pump(model, runner, thermal_zone, true)
        counterpart_equip = self.has_furnace(model, runner, thermal_zone)
        removed_ac = self.has_central_air_conditioner(model, runner, thermal_zone, true)
        removed_room_ac = self.has_room_air_conditioner(model, runner, thermal_zone, true)
        if removed_mshp
          removed_elec_baseboard = self.has_electric_baseboard(model, runner, thermal_zone, true)
        end
        if counterpart_equip or removed_ac or removed_ashp or removed_mshp
          self.has_air_loop(model, runner, thermal_zone, true)
        end
      when "Room Air Conditioner"
        removed_ashp = self.has_air_source_heat_pump(model, runner, thermal_zone, true)
        removed_mshp = self.has_mini_split_heat_pump(model, runner, thermal_zone, true)      
        removed_room_ac = self.has_room_air_conditioner(model, runner, thermal_zone, true)
        removed_ac = self.has_central_air_conditioner(model, runner, thermal_zone, true)
        if removed_mshp
          removed_elec_baseboard = self.has_electric_baseboard(model, runner, thermal_zone, true)
        end        
        if removed_ac or removed_ashp or removed_mshp
          self.has_air_loop(model, runner, thermal_zone, true)
        end
      when "Furnace"
        removed_ashp = self.has_air_source_heat_pump(model, runner, thermal_zone, true)
        removed_mshp = self.has_mini_split_heat_pump(model, runner, thermal_zone, true)      
        counterpart_equip = self.has_central_air_conditioner(model, runner, thermal_zone)
        removed_furnace = self.has_furnace(model, runner, thermal_zone, true)
        removed_boiler = self.has_boiler(model, runner, thermal_zone, true)
        removed_elec_baseboard = self.has_electric_baseboard(model, runner, thermal_zone, true)
        if counterpart_equip or removed_furnace or removed_ashp or removed_mshp
          self.has_air_loop(model, runner, thermal_zone, true)
        end
      when "Boiler"
        removed_boiler = self.has_boiler(model, runner, thermal_zone, true)
        removed_furnace = self.has_furnace(model, runner, thermal_zone, true)
        removed_elec_baseboard = self.has_electric_baseboard(model, runner, thermal_zone, true)
        removed_ashp = self.has_air_source_heat_pump(model, runner, thermal_zone, true)
        removed_mshp = self.has_mini_split_heat_pump(model, runner, thermal_zone, true)
        if removed_furnace or removed_ashp or removed_mshp
          self.has_air_loop(model, runner, thermal_zone, true)
        end
      when "Electric Baseboard"
        removed_elec_baseboard = self.has_electric_baseboard(model, runner, thermal_zone, true)
        removed_furnace = self.has_furnace(model, runner, thermal_zone, true)
        removed_boiler = self.has_boiler(model, runner, thermal_zone, true)
        removed_ashp = self.has_air_source_heat_pump(model, runner, thermal_zone, true)
        removed_mshp = self.has_mini_split_heat_pump(model, runner, thermal_zone, true)
        if removed_furnace or removed_ashp or removed_mshp
          self.has_air_loop(model, runner, thermal_zone, true)
        end
      when "Air Source Heat Pump"
        removed_ashp = self.has_air_source_heat_pump(model, runner, thermal_zone, true)
        removed_mshp = self.has_mini_split_heat_pump(model, runner, thermal_zone, true)
        removed_ac = self.has_central_air_conditioner(model, runner, thermal_zone, true)
        removed_room_ac = self.has_room_air_conditioner(model, runner, thermal_zone, true)
        removed_furnace = self.has_furnace(model, runner, thermal_zone, true)
        removed_boiler = self.has_boiler(model, runner, thermal_zone, true)
        removed_elec_baseboard = self.has_electric_baseboard(model, runner, thermal_zone, true)        
        if removed_ashp or removed_ac or removed_furnace or removed_mshp
          self.has_air_loop(model, runner, thermal_zone, true)
        end
      when "Mini-Split Heat Pump"
        removed_mshp = self.has_mini_split_heat_pump(model, runner, thermal_zone, true)
        removed_ashp = self.has_air_source_heat_pump(model, runner, thermal_zone, true)
        removed_ac = self.has_central_air_conditioner(model, runner, thermal_zone, true)
        removed_room_ac = self.has_room_air_conditioner(model, runner, thermal_zone, true)
        removed_furnace = self.has_furnace(model, runner, thermal_zone, true)
        removed_boiler = self.has_boiler(model, runner, thermal_zone, true)
        removed_elec_baseboard = self.has_electric_baseboard(model, runner, thermal_zone, true)
        if removed_mshp or removed_ac or removed_furnace or removed_ashp
          self.has_air_loop(model, runner, thermal_zone, true)
        end
      when "Mini-Split Heat Pump Original Model" # TODO: remove after testing new vrf mshp model
        removed_mshp = self.has_mini_split_heat_pump_original_model(model, runner, thermal_zone, true)
        removed_ashp = self.has_air_source_heat_pump(model, runner, thermal_zone, true)
        removed_ac = self.has_central_air_conditioner(model, runner, thermal_zone, true)
        removed_room_ac = self.has_room_air_conditioner(model, runner, thermal_zone, true)
        removed_furnace = self.has_furnace(model, runner, thermal_zone, true)
        removed_boiler = self.has_boiler(model, runner, thermal_zone, true)
        removed_elec_baseboard = self.has_electric_baseboard(model, runner, thermal_zone, true)
        if removed_mshp or removed_ac or removed_furnace or removed_ashp
          self.has_air_loop(model, runner, thermal_zone, true)
        end        
      end
      unless counterpart_equip.nil?
        return counterpart_equip
      end
    end

    def self.has_mini_split_heat_pump_original_model(model, runner, thermal_zone, remove=false) # TODO: remove after testing new vrf mshp model
      model.getAirLoopHVACs.each do |air_loop|
        air_loop.thermalZones.each do |thermalZone|
          next unless thermal_zone.handle.to_s == thermalZone.handle.to_s
          air_loop.supplyComponents.each do |supply_component|
            next unless supply_component.to_AirLoopHVACUnitarySystem.is_initialized
            air_loop_unitary = supply_component.to_AirLoopHVACUnitarySystem.get
            next unless air_loop_unitary.coolingCoil.is_initialized and air_loop_unitary.heatingCoil.is_initialized
            clg_coil = air_loop_unitary.coolingCoil.get
            htg_coil = air_loop_unitary.heatingCoil.get
            next unless clg_coil.to_CoilCoolingDXMultiSpeed.is_initialized and htg_coil.to_CoilHeatingDXMultiSpeed.is_initialized
            if remove
                runner.registerInfo("Removed '#{clg_coil.name}' and '#{htg_coil.name}' from air loop '#{air_loop.name}'")
                air_loop_unitary.resetHeatingCoil
                air_loop_unitary.resetCoolingCoil              
                htg_coil.remove
                clg_coil.remove
                return true
            else
              return true
            end
          end
        end
      end
      return nil
    end    
    
    def self.remove_hot_water_loop(model, runner)
      model.getPlantLoops.each do |plantLoop|
        remove = true
        supplyComponents = plantLoop.supplyComponents
        supplyComponents.each do |supplyComponent|
          if supplyComponent.to_WaterHeaterMixed.is_initialized or supplyComponent.to_WaterHeaterStratified.is_initialized or supplyComponent.to_WaterHeaterHeatPump.is_initialized # don't remove the dhw
            remove = false
          end
        end
        if remove
          runner.registerInfo("Removed plant loop '#{plantLoop.name}'")
          plantLoop.remove
        end
      end
    end 

    # Calculates heating/cooling seasons from BAHSP definition
    def self.calc_heating_and_cooling_seasons(model, weather, runner=nil)
        monthly_temps = weather.data.MonthlyAvgDrybulbs
        
        # Look up heating design db from model
        heat_design_db = HelperMethods.get_design_day_temperature(model, runner, Constants.DDYHtgDrybulb)
        if heat_design_db.nil?
            return nil, nil
        end

        # create basis lists with zero for every month
        cooling_season_temp_basis = Array.new(monthly_temps.length, 0.0)
        heating_season_temp_basis = Array.new(monthly_temps.length, 0.0)

        monthly_temps.each_with_index do |temp, i|
          if temp < 66.0
            heating_season_temp_basis[i] = 1.0
          elsif temp >= 66.0
            cooling_season_temp_basis[i] = 1.0
          end

          if (i == 0 or i == 11) and heat_design_db < 59.0
            heating_season_temp_basis[i] = 1.0
          elsif i == 6 or i == 7
            cooling_season_temp_basis[i] = 1.0
          end
        end

        cooling_season = Array.new(monthly_temps.length, 0.0)
        heating_season = Array.new(monthly_temps.length, 0.0)

        monthly_temps.each_with_index do |temp, i|
          # Heating overlaps with cooling at beginning of summer
          if i == 0 # January
            prevmonth = 11 # December
          else
            prevmonth = i - 1
          end

          if (heating_season_temp_basis[i] == 1.0 or (cooling_season_temp_basis[prevmonth] == 0.0 and cooling_season_temp_basis[i] == 1.0))
            heating_season[i] = 1.0
          else
            heating_season[i] = 0.0
          end

          if (cooling_season_temp_basis[i] == 1.0 or (heating_season_temp_basis[prevmonth] == 0.0 and heating_season_temp_basis[i] == 1.0))
            cooling_season[i] = 1.0
          else
            cooling_season[i] = 0.0
          end
        end

        # Find the first month of cooling and add one month
        (1...12).to_a.each do |i|
          if cooling_season[i] == 1.0
            cooling_season[i - 1] = 1.0
            break
          end
        end
        
        return heating_season, cooling_season
    end
    
end