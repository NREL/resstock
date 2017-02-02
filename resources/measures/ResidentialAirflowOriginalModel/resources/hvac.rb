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
        hp_heat_plf_fplr.setMinimumValueofx(0)
        hp_heat_plf_fplr.setMaximumValueofx(1)
        hp_heat_plf_fplr.setMinimumCurveOutput(0.7)
        hp_heat_plf_fplr.setMaximumCurveOutput(1)

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

        # Supply Air Temperatures
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
  
    def self.get_furnace_hir(furnaceInstalledAFUE)
      # Based on DOE2 Volume 5 Compliance Analysis manual.
      # This is not used until we have a better way of disaggregating AFUE
      # if FurnaceInstalledAFUE <= 0.835:
      #     hir = 1 / (0.2907 * FurnaceInstalledAFUE + 0.5787)
      # else:
      #     hir = 1 / (1.1116 * FurnaceInstalledAFUE - 0.098185)

      hir = 1.0 / furnaceInstalledAFUE
      return hir
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
      # Returns a list of cooling equipment objects (AirLoopHVACUnitarySystems or ZoneHVACComponents)
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
            runner.registerInfo("Found #{Constants.ObjectNameAirSourceHeatPump} in #{thermal_zone.name}.")
            cooling_equipment << air_loop_unitary
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
            runner.registerInfo("Found #{Constants.ObjectNameCentralAirConditioner} in #{thermal_zone.name}.")
            cooling_equipment << air_loop_unitary
          end
        end
      end
      model.getZoneHVACPackagedTerminalAirConditioners.each do |ptac|
        next unless thermal_zone.handle.to_s == ptac.thermalZone.get.handle.to_s
        runner.registerInfo("Found #{Constants.ObjectNameRoomAirConditioner} in #{thermal_zone.name}.")
        cooling_equipment << ptac
      end
      model.getZoneHVACTerminalUnitVariableRefrigerantFlows.each do |tu_vrf|
        next unless thermal_zone.handle.to_s == tu_vrf.thermalZone.get.handle.to_s
        runner.registerInfo("Found #{Constants.ObjectNameMiniSplitHeatPump} in #{thermal_zone.name}.")
        cooling_equipment << tu_vrf
      end
      model.getAirLoopHVACs.each do |air_loop|
        air_loop.thermalZones.each do |thermalZone|
          next unless thermal_zone.handle.to_s == thermalZone.handle.to_s
          air_loop.supplyComponents.each do |supply_component|
            next unless supply_component.to_AirLoopHVACUnitarySystem.is_initialized
            air_loop_unitary = supply_component.to_AirLoopHVACUnitarySystem.get
            next unless air_loop_unitary.coolingCoil.is_initialized and air_loop_unitary.heatingCoil.is_initialized
            clg_coil = air_loop_unitary.coolingCoil.get
            htg_coil = air_loop_unitary.heatingCoil.get              
            next unless clg_coil.to_CoilCoolingWaterToAirHeatPumpEquationFit.is_initialized and htg_coil.to_CoilHeatingWaterToAirHeatPumpEquationFit.is_initialized
            runner.registerInfo("Found #{Constants.ObjectNameGroundSourceHeatPumpVerticalBore} in #{thermal_zone.name}.")
            cooling_equipment << air_loop_unitary
          end
        end
      end
      return cooling_equipment
    end
    
    def self.existing_heating_equipment(model, runner, thermal_zone)
      # Returns a list of heating equipment objects (AirLoopHVACUnitarySystems or ZoneHVACComponents)
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
            runner.registerInfo("Found #{Constants.ObjectNameAirSourceHeatPump} in #{thermal_zone.name}.")
            heating_equipment << air_loop_unitary
          end
        end
      end
      furnaceFuelType = nil
      model.getAirLoopHVACs.each do |air_loop|
        air_loop.thermalZones.each do |thermalZone|
          next unless thermal_zone.handle.to_s == thermalZone.handle.to_s
          air_loop.supplyComponents.each do |supply_component|
            next unless supply_component.to_AirLoopHVACUnitarySystem.is_initialized
            air_loop_unitary = supply_component.to_AirLoopHVACUnitarySystem.get
            next unless air_loop_unitary.heatingCoil.is_initialized
            htg_coil = air_loop_unitary.heatingCoil.get
            next unless htg_coil.to_CoilHeatingGas.is_initialized or htg_coil.to_CoilHeatingElectric.is_initialized
            begin
              furnaceFuelType = HelperMethods.reverse_eplus_fuel_map(htg_coil.to_CoilHeatingGas.get.fuelType)
            rescue
              furnaceFuelType = Constants.FuelTypeElectric
            end
            runner.registerInfo("Found #{Constants.ObjectNameFurnace(furnaceFuelType)} in #{thermal_zone.name}.")
            heating_equipment << air_loop_unitary
          end
        end
      end
      boilerFuelType = nil
      model.getPlantLoops.each do |plant_loop|
        plant_loop.supplyComponents.each do |supply_component|
          next unless supply_component.to_BoilerHotWater.is_initialized
          boilerFuelType = HelperMethods.reverse_eplus_fuel_map(supply_component.to_BoilerHotWater.get.fuelType)
          break
        end
      end
      model.getZoneHVACBaseboardConvectiveWaters.each do |baseboard|
        next unless thermal_zone.handle.to_s == baseboard.thermalZone.get.handle.to_s
        runner.registerInfo("Found #{Constants.ObjectNameBoiler(boilerFuelType)} serving #{thermal_zone.name}.")
        heating_equipment << baseboard
      end
      model.getZoneHVACBaseboardConvectiveElectrics.each do |baseboard|
        next unless thermal_zone.handle.to_s == baseboard.thermalZone.get.handle.to_s
        runner.registerInfo("Found #{Constants.ObjectNameElectricBaseboard} in #{thermal_zone.name}.")
        heating_equipment << baseboard
      end
      model.getZoneHVACTerminalUnitVariableRefrigerantFlows.each do |tu_vrf|
        next unless thermal_zone.handle.to_s == tu_vrf.thermalZone.get.handle.to_s
        runner.registerInfo("Found #{Constants.ObjectNameMiniSplitHeatPump} in #{thermal_zone.name}.")
        heating_equipment << tu_vrf
      end
      model.getAirLoopHVACs.each do |air_loop|
        air_loop.thermalZones.each do |thermalZone|
          next unless thermal_zone.handle.to_s == thermalZone.handle.to_s
          air_loop.supplyComponents.each do |supply_component|
            next unless supply_component.to_AirLoopHVACUnitarySystem.is_initialized
            air_loop_unitary = supply_component.to_AirLoopHVACUnitarySystem.get
            next unless air_loop_unitary.coolingCoil.is_initialized and air_loop_unitary.heatingCoil.is_initialized
            clg_coil = air_loop_unitary.coolingCoil.get
            htg_coil = air_loop_unitary.heatingCoil.get              
            next unless clg_coil.to_CoilCoolingWaterToAirHeatPumpEquationFit.is_initialized and htg_coil.to_CoilHeatingWaterToAirHeatPumpEquationFit.is_initialized
            runner.registerInfo("Found #{Constants.ObjectNameGroundSourceHeatPumpVerticalBore} in #{thermal_zone.name}.")
            heating_equipment << air_loop_unitary
          end
        end
      end
      return heating_equipment
    end  

    def self.get_coil_from_hvac_component(hvac_component)
      # Cooling coils
      if hvac_component.to_CoilCoolingDXSingleSpeed.is_initialized
        return hvac_component.to_CoilCoolingDXSingleSpeed.get
      elsif hvac_component.to_CoilCoolingDXMultiSpeed.is_initialized
        return hvac_component.to_CoilCoolingDXMultiSpeed.get
      elsif hvac_component.to_CoilCoolingDXVariableRefrigerantFlow.is_initialized
        return hvac_component.to_CoilCoolingDXVariableRefrigerantFlow.get
      elsif hvac_component.to_CoilCoolingWaterToAirHeatPumpEquationFit.is_initialized
        return hvac_component.to_CoilCoolingWaterToAirHeatPumpEquationFit.get
      end
        
      # Heating coils  
      if hvac_component.to_CoilHeatingDXSingleSpeed.is_initialized
        return hvac_component.to_CoilHeatingDXSingleSpeed.get
      elsif hvac_component.to_CoilHeatingDXMultiSpeed.is_initialized
        return hvac_component.to_CoilHeatingDXMultiSpeed.get
      elsif hvac_component.to_CoilHeatingDXVariableRefrigerantFlow.is_initialized
        return hvac_component.to_CoilHeatingDXVariableRefrigerantFlow.get
      elsif hvac_component.to_CoilHeatingGas.is_initialized
        return hvac_component.to_CoilHeatingGas.get
      elsif hvac_component.to_CoilHeatingElectric.is_initialized
        return hvac_component.to_CoilHeatingElectric.get
      elsif hvac_component.to_CoilHeatingWaterBaseboard.is_initialized
        return hvac_component.to_CoilHeatingWaterBaseboard.get
      elsif hvac_component.to_CoilHeatingWaterToAirHeatPumpEquationFit.is_initialized
        return hvac_component.to_CoilHeatingWaterToAirHeatPumpEquationFit.get
      end
      return hvac_component
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
              runner.registerInfo("Removed '#{clg_coil.name}' from '#{air_loop.name}'.")
              air_loop_unitary.resetCoolingCoil
              clg_coil.remove
              air_loop_unitary.supplyFan.get.remove
            else
              if reset_air_loop
                cloned_clg_coil = clg_coil.clone
                air_loop_unitary.resetCoolingCoil
                clg_coil.remove
                air_loop_unitary.supplyFan.get.remove
                cloned_clg_coil = self.get_coil_from_hvac_component(cloned_clg_coil)
                cloned_clg_coil.setName(clg_coil.name.to_s)
                return cloned_clg_coil
              end
            end
            return true
          end
        end
      end
      return nil
    end
    
    def self.has_room_air_conditioner(model, runner, thermal_zone, remove=false)
      model.getZoneHVACPackagedTerminalAirConditioners.each do |ptac|
        next unless thermal_zone.handle.to_s == ptac.thermalZone.get.handle.to_s
        if remove
          runner.registerInfo("Removed '#{ptac.name}' from #{thermal_zone.name}.")
          ptac.remove
        end
        return true
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
              runner.registerInfo("Removed '#{htg_coil.name}' from '#{air_loop.name}'.")
              air_loop_unitary.resetHeatingCoil
              htg_coil.remove
              air_loop_unitary.supplyFan.get.remove
            else
              if reset_air_loop
                cloned_htg_coil = htg_coil.clone
                air_loop_unitary.resetHeatingCoil
                htg_coil.remove
                air_loop_unitary.supplyFan.get.remove
                if cloned_htg_coil.to_CoilHeatingGas.is_initialized
                  cloned_htg_coil = cloned_htg_coil.to_CoilHeatingGas.get
                elsif cloned_htg_coil.to_CoilHeatingElectric.is_initialized
                  cloned_htg_coil = cloned_htg_coil.to_CoilHeatingElectric.get
                end
                cloned_htg_coil.setName(htg_coil.name.to_s)
                return cloned_htg_coil
              end
            end
            return true
          end
        end
      end
      return nil
    end
    
    def self.has_boiler(model, runner, thermal_zone, remove=false)
      model.getZoneHVACBaseboardConvectiveWaters.each do |baseboard|
        next unless thermal_zone.handle.to_s == baseboard.thermalZone.get.handle.to_s
        if remove
          runner.registerInfo("Removed '#{baseboard.name}' from #{thermal_zone.name}.")
          baseboard.remove
        end
        return true
      end
      return nil
    end
    
    def self.has_electric_baseboard(model, runner, thermal_zone, remove=false)
      model.getZoneHVACBaseboardConvectiveElectrics.each do |baseboard|
        next unless thermal_zone.handle.to_s == baseboard.thermalZone.get.handle.to_s
        if remove
          runner.registerInfo("Removed '#{baseboard.name}' from #{thermal_zone.name}.")
          baseboard.remove
        end
        return true
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
              runner.registerInfo("Removed '#{clg_coil.name}' and '#{htg_coil.name}' from '#{air_loop.name}'.")
              air_loop_unitary.resetHeatingCoil
              air_loop_unitary.resetCoolingCoil              
              htg_coil.remove
              clg_coil.remove
            end
            return true
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
            runner.registerInfo("Removed '#{terminal.name}' from #{thermal_zone.name}.")
            terminal.remove
            vrf.remove
          end
          return true
        end        
      end
      return nil
    end
    
    def self.has_gshp_vert_bore(model, runner, thermal_zone, remove=false)
      model.getAirLoopHVACs.each do |air_loop|
        air_loop.thermalZones.each do |thermalZone|
          next unless thermal_zone.handle.to_s == thermalZone.handle.to_s
          air_loop.supplyComponents.each do |supply_component|
            next unless supply_component.to_AirLoopHVACUnitarySystem.is_initialized
            air_loop_unitary = supply_component.to_AirLoopHVACUnitarySystem.get
            next unless air_loop_unitary.coolingCoil.is_initialized and air_loop_unitary.heatingCoil.is_initialized
            clg_coil = air_loop_unitary.coolingCoil.get
            htg_coil = air_loop_unitary.heatingCoil.get              
            next unless clg_coil.to_CoilCoolingWaterToAirHeatPumpEquationFit.is_initialized and htg_coil.to_CoilHeatingWaterToAirHeatPumpEquationFit.is_initialized
            if remove
              runner.registerInfo("Removed '#{clg_coil.name}' and '#{htg_coil.name}' from '#{air_loop.name}'.")
              air_loop_unitary.resetHeatingCoil
              air_loop_unitary.resetCoolingCoil              
              htg_coil.remove
              clg_coil.remove
            end
            return true
          end
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
              runner.registerInfo("Removed '#{air_loop.name}' from #{thermal_zone.name}.")
              air_loop.remove
            end
            return true
          end
        end
      end
      return nil
    end
    
    def self.remove_existing_hvac_equipment(model, runner, new_equip, thermal_zone)
      counterpart_equip = nil
      case new_equip
      when Constants.ObjectNameCentralAirConditioner
        removed_ashp = self.has_air_source_heat_pump(model, runner, thermal_zone, true)
        removed_mshp = self.has_mini_split_heat_pump(model, runner, thermal_zone, true)
        counterpart_equip = self.has_furnace(model, runner, thermal_zone)
        removed_ac = self.has_central_air_conditioner(model, runner, thermal_zone, true)
        removed_room_ac = self.has_room_air_conditioner(model, runner, thermal_zone, true)
        removed_gshp_vert_bore = self.has_gshp_vert_bore(model, runner, thermal_zone, true)
        if removed_mshp
          removed_elec_baseboard = self.has_electric_baseboard(model, runner, thermal_zone, true)
        end
        if counterpart_equip or removed_ac or removed_ashp or removed_gshp_vert_bore
          self.has_air_loop(model, runner, thermal_zone, true)
        end
        if removed_gshp_vert_bore
          self.remove_hot_water_loop(model, runner)
        end
      when Constants.ObjectNameRoomAirConditioner
        removed_ashp = self.has_air_source_heat_pump(model, runner, thermal_zone, true)
        removed_mshp = self.has_mini_split_heat_pump(model, runner, thermal_zone, true)      
        removed_room_ac = self.has_room_air_conditioner(model, runner, thermal_zone, true)
        removed_ac = self.has_central_air_conditioner(model, runner, thermal_zone, true)
        removed_gshp_vert_bore = self.has_gshp_vert_bore(model, runner, thermal_zone, true)
        if removed_mshp
          removed_elec_baseboard = self.has_electric_baseboard(model, runner, thermal_zone, true)
        end        
        if removed_ac or removed_ashp or removed_gshp_vert_bore
          self.has_air_loop(model, runner, thermal_zone, true)
        end
        if removed_gshp_vert_bore
          self.remove_hot_water_loop(model, runner)
        end        
      when Constants.ObjectNameFurnace
        removed_ashp = self.has_air_source_heat_pump(model, runner, thermal_zone, true)
        removed_mshp = self.has_mini_split_heat_pump(model, runner, thermal_zone, true)      
        counterpart_equip = self.has_central_air_conditioner(model, runner, thermal_zone)
        removed_furnace = self.has_furnace(model, runner, thermal_zone, true)
        removed_boiler = self.has_boiler(model, runner, thermal_zone, true)
        removed_elec_baseboard = self.has_electric_baseboard(model, runner, thermal_zone, true)
        removed_gshp_vert_bore = self.has_gshp_vert_bore(model, runner, thermal_zone, true)
        if counterpart_equip or removed_furnace or removed_ashp or removed_gshp_vert_bore
          self.has_air_loop(model, runner, thermal_zone, true)
        end
      when Constants.ObjectNameBoiler
        removed_boiler = self.has_boiler(model, runner, thermal_zone, true)
        removed_furnace = self.has_furnace(model, runner, thermal_zone, true)
        removed_elec_baseboard = self.has_electric_baseboard(model, runner, thermal_zone, true)
        removed_ashp = self.has_air_source_heat_pump(model, runner, thermal_zone, true)
        removed_mshp = self.has_mini_split_heat_pump(model, runner, thermal_zone, true)
        removed_gshp_vert_bore = self.has_gshp_vert_bore(model, runner, thermal_zone, true)
        if removed_furnace or removed_ashp or removed_mshp or removed_gshp_vert_bore
          self.has_air_loop(model, runner, thermal_zone, true)
        end
      when Constants.ObjectNameElectricBaseboard
        removed_elec_baseboard = self.has_electric_baseboard(model, runner, thermal_zone, true)
        removed_furnace = self.has_furnace(model, runner, thermal_zone, true)
        removed_boiler = self.has_boiler(model, runner, thermal_zone, true)
        removed_ashp = self.has_air_source_heat_pump(model, runner, thermal_zone, true)
        removed_mshp = self.has_mini_split_heat_pump(model, runner, thermal_zone, true)
        removed_gshp_vert_bore = self.has_gshp_vert_bore(model, runner, thermal_zone, true)
        if removed_furnace or removed_ashp or removed_gshp_vert_bore
          self.has_air_loop(model, runner, thermal_zone, true)
        end
      when Constants.ObjectNameAirSourceHeatPump
        removed_ashp = self.has_air_source_heat_pump(model, runner, thermal_zone, true)
        removed_mshp = self.has_mini_split_heat_pump(model, runner, thermal_zone, true)
        removed_ac = self.has_central_air_conditioner(model, runner, thermal_zone, true)
        removed_room_ac = self.has_room_air_conditioner(model, runner, thermal_zone, true)
        removed_furnace = self.has_furnace(model, runner, thermal_zone, true)
        removed_boiler = self.has_boiler(model, runner, thermal_zone, true)
        removed_elec_baseboard = self.has_electric_baseboard(model, runner, thermal_zone, true)
        removed_gshp_vert_bore = self.has_gshp_vert_bore(model, runner, thermal_zone, true)
        if removed_ashp or removed_ac or removed_furnace or removed_gshp_vert_bore
          self.has_air_loop(model, runner, thermal_zone, true)
        end
      when Constants.ObjectNameMiniSplitHeatPump
        removed_mshp = self.has_mini_split_heat_pump(model, runner, thermal_zone, true)
        removed_ashp = self.has_air_source_heat_pump(model, runner, thermal_zone, true)
        removed_ac = self.has_central_air_conditioner(model, runner, thermal_zone, true)
        removed_room_ac = self.has_room_air_conditioner(model, runner, thermal_zone, true)
        removed_furnace = self.has_furnace(model, runner, thermal_zone, true)
        removed_boiler = self.has_boiler(model, runner, thermal_zone, true)
        removed_elec_baseboard = self.has_electric_baseboard(model, runner, thermal_zone, true)
        removed_gshp_vert_bore = self.has_gshp_vert_bore(model, runner, thermal_zone, true)
        if removed_ac or removed_furnace or removed_ashp or removed_gshp_vert_bore
          self.has_air_loop(model, runner, thermal_zone, true)
        end
      when Constants.ObjectNameGroundSourceHeatPumpVerticalBore
        removed_ashp = self.has_air_source_heat_pump(model, runner, thermal_zone, true)
        removed_mshp = self.has_mini_split_heat_pump(model, runner, thermal_zone, true)
        removed_ac = self.has_central_air_conditioner(model, runner, thermal_zone, true)
        removed_room_ac = self.has_room_air_conditioner(model, runner, thermal_zone, true)
        removed_furnace = self.has_furnace(model, runner, thermal_zone, true)
        removed_boiler = self.has_boiler(model, runner, thermal_zone, true)
        removed_elec_baseboard = self.has_electric_baseboard(model, runner, thermal_zone, true)
        removed_gshp_vert_bore = self.has_gshp_vert_bore(model, runner, thermal_zone, true)
        if removed_ashp or removed_ac or removed_furnace or removed_gshp_vert_bore
          self.has_air_loop(model, runner, thermal_zone, true)
        end
      end
      unless counterpart_equip.nil?
        return counterpart_equip
      end
    end   
    
    def self.remove_hot_water_loop(model, runner)
      model.getPlantLoops.each do |plant_loop|
        remove = true
        plant_loop.supplyComponents.each do |supply_component|
          if supply_component.to_WaterHeaterMixed.is_initialized or supply_component.to_WaterHeaterStratified.is_initialized or supply_component.to_WaterHeaterHeatPump.is_initialized # don't remove the dhw
            remove = false
          end
        end
        if remove
          runner.registerInfo("Removed '#{plant_loop.name}' from model.")
          plant_loop.remove
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