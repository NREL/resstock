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
    
    def self.create_curve_biquadratic_constant(model)
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
    
    def self.create_curve_cubic_constant(model)
        constant_cubic = OpenStudio::Model::CurveCubic.new(model)
        constant_cubic.setName("ConstantCubic")
        constant_cubic.setCoefficient1Constant(1)
        constant_cubic.setCoefficient2x(0)
        constant_cubic.setCoefficient3xPOW2(0)
        constant_cubic.setCoefficient4xPOW3(0)
        constant_cubic.setMinimumValueofx(-100)
        constant_cubic.setMaximumValueofx(100)
        return constant_cubic
    end

    def self.convert_curve_biquadratic(coeff, ip_to_si)
        if ip_to_si
            # Convert IP curves to SI curves
            si_coeff = Array.new
            si_coeff << coeff[0] + 32.0 * (coeff[1] + coeff[3]) + 1024.0 * (coeff[2] + coeff[4] + coeff[5])
            si_coeff << 9.0 / 5.0 * coeff[1] + 576.0 / 5.0 * coeff[2] + 288.0 / 5.0 * coeff[5]
            si_coeff << 81.0 / 25.0 * coeff[2]
            si_coeff << 9.0 / 5.0 * coeff[3] + 576.0 / 5.0 * coeff[4] + 288.0 / 5.0 * coeff[5]
            si_coeff << 81.0 / 25.0 * coeff[4]
            si_coeff << 81.0 / 25.0 * coeff[5]        
            return si_coeff
        else
            # Convert SI curves to IP curves
            ip_coeff = Array.new
            ip_coeff << coeff[0] - 160.0/9.0 * (coeff[1] + coeff[3]) + 25600.0/81.0 * (coeff[2] + coeff[4] + coeff[5])
            ip_coeff << 5.0/9.0 * (coeff[1] - 320.0/9.0 * coeff[2] - 160.0/9.0 * coeff[5])
            ip_coeff << 25.0/81.0 * coeff[2]
            ip_coeff << 5.0/9.0 * (coeff[3] - 320.0/9.0 * coeff[4] - 160.0/9.0 * coeff[5])
            ip_coeff << 25.0/81.0 * coeff[4]
            ip_coeff << 25.0/81.0 * coeff[5]
            return ip_coeff
        end
    end
    
    def self.create_curve_biquadratic(model, coeff, name, minX, maxX, minY, maxY)
        curve = OpenStudio::Model::CurveBiquadratic.new(model)
        curve.setName(name)
        curve.setCoefficient1Constant(coeff[0])
        curve.setCoefficient2x(coeff[1])
        curve.setCoefficient3xPOW2(coeff[2])
        curve.setCoefficient4y(coeff[3])
        curve.setCoefficient5yPOW2(coeff[4])
        curve.setCoefficient6xTIMESY(coeff[5])
        curve.setMinimumValueofx(minX)
        curve.setMaximumValueofx(maxX)
        curve.setMinimumValueofy(minY)
        curve.setMaximumValueofy(maxY)
        return curve
    end
    
    def self.create_curve_bicubic(model, coeff, name, minX, maxX, minY, maxY)
        curve = OpenStudio::Model::CurveBicubic.new(model)
        curve.setName(name)
        curve.setCoefficient1Constant(coeff[0])
        curve.setCoefficient2x(coeff[1])
        curve.setCoefficient3xPOW2(coeff[2])
        curve.setCoefficient4y(coeff[3])
        curve.setCoefficient5yPOW2(coeff[4])
        curve.setCoefficient6xTIMESY(coeff[5])
        curve.setCoefficient7xPOW3(coeff[6])
        curve.setCoefficient8yPOW3(coeff[7])
        curve.setCoefficient9xPOW2TIMESY(coeff[8])
        curve.setCoefficient10xTIMESYPOW2(coeff[9])
        curve.setMinimumValueofx(minX)
        curve.setMaximumValueofx(maxX)
        curve.setMinimumValueofy(minY)
        curve.setMaximumValueofy(maxY)
        return curve
    end
    
    def self.create_curve_quadratic(model, coeff, name, minX, maxX, minY, maxY, is_dimensionless=false)
        curve = OpenStudio::Model::CurveQuadratic.new(model)
        curve.setName(name)
        curve.setCoefficient1Constant(coeff[0])
        curve.setCoefficient2x(coeff[1])
        curve.setCoefficient3xPOW2(coeff[2])
        curve.setMinimumValueofx(minX)
        curve.setMaximumValueofx(maxX)
        if not minY.nil?
            curve.setMinimumCurveOutput(minY)
        end
        if not maxY.nil?
            curve.setMaximumCurveOutput(maxY)
        end
        if is_dimensionless
            curve.setInputUnitTypeforX("Dimensionless")
            curve.setOutputUnitType("Dimensionless")
        end
        return curve
    end
    
    def self.create_curve_cubic(model, coeff, name, minX, maxX, minY, maxY)    
      curve = OpenStudio::Model::CurveCubic.new(model)
      curve.setName(name)
      curve.setCoefficient1Constant(coeff[0])
      curve.setCoefficient2x(coeff[1])
      curve.setCoefficient3xPOW2(coeff[2])
      curve.setCoefficient4xPOW3(coeff[3])
      curve.setMinimumValueofx(minX)
      curve.setMaximumValueofx(maxX)
      curve.setMinimumCurveOutput(minY)
      curve.setMaximumCurveOutput(maxY)
      return curve
    end
    
    def self.create_curve_exponent(model, coeff, name, minX, maxX)
      curve = OpenStudio::Model::CurveExponent.new(model)
      curve.setName(name)
      curve.setCoefficient1Constant(coeff[0])
      curve.setCoefficient2Constant(coeff[1])
      curve.setCoefficient3Constant(coeff[2])
      curve.setMinimumValueofx(minX)
      curve.setMaximumValueofx(maxX)
      return curve
    end
      
    def self.calc_coil_stage_data_cooling(model, outputCapacity, number_Speeds, coolingEIR, shr_Rated_Gross, cOOL_CAP_FT_SPEC, cOOL_EIR_FT_SPEC, cOOL_CLOSS_FPLR_SPEC, cOOL_CAP_FFLOW_SPEC, cOOL_EIR_FFLOW_SPEC)

      const_biquadratic = self.create_curve_biquadratic_constant(model)
    
      clg_coil_stage_data = []
      (0...number_Speeds).to_a.each do |speed|
      
        cool_cap_ft_curve = self.create_curve_biquadratic(model, self.convert_curve_biquadratic(cOOL_CAP_FT_SPEC[speed], true), "Cool-Cap-fT#{speed+1}", 13.88, 23.88, 18.33, 51.66)
        cool_eir_ft_curve = self.create_curve_biquadratic(model, self.convert_curve_biquadratic(cOOL_EIR_FT_SPEC[speed], true), "Cool-EIR-fT#{speed+1}", 13.88, 23.88, 18.33, 51.66)
        cool_plf_fplr_curve = self.create_curve_quadratic(model, cOOL_CLOSS_FPLR_SPEC[speed], "Cool-PLF-fPLR#{speed+1}", 0, 1, 0.7, 1)
        cool_cap_fff_curve = self.create_curve_quadratic(model, cOOL_CAP_FFLOW_SPEC[speed], "Cool-Cap-fFF#{speed+1}", 0, 2, 0, 2)
        cool_eir_fff_curve = self.create_curve_quadratic(model, cOOL_EIR_FFLOW_SPEC[speed], "Cool-EIR-fFF#{speed+1}", 0, 2, 0, 2)

        stage_data = OpenStudio::Model::CoilCoolingDXMultiSpeedStageData.new(model, 
                                                                             cool_cap_ft_curve, 
                                                                             cool_cap_fff_curve, 
                                                                             cool_eir_ft_curve, 
                                                                             cool_eir_fff_curve, 
                                                                             cool_plf_fplr_curve, 
                                                                             const_biquadratic)
        if outputCapacity != Constants.SizingAuto and outputCapacity != Constants.SizingAutoMaxLoad
          stage_data.setGrossRatedTotalCoolingCapacity(OpenStudio::convert(outputCapacity,"Btu/h","W").get) # Used by HVACSizing measure
        end
        stage_data.setGrossRatedSensibleHeatRatio(shr_Rated_Gross[speed])
        stage_data.setGrossRatedCoolingCOP(1.0 / coolingEIR[speed])
        stage_data.setNominalTimeforCondensateRemovaltoBegin(1000)
        stage_data.setRatioofInitialMoistureEvaporationRateandSteadyStateLatentCapacity(1.5)
        stage_data.setMaximumCyclingRate(3)
        stage_data.setLatentCapacityTimeConstant(45)
        stage_data.setRatedWasteHeatFractionofPowerInput(0.2)
        clg_coil_stage_data[speed] = stage_data
      end
      return clg_coil_stage_data
    end
      
    def self.calc_coil_stage_data_heating(model, outputCapacity, number_Speeds, heatingEIR, hEAT_CAP_FT_SPEC, hEAT_EIR_FT_SPEC, hEAT_CLOSS_FPLR_SPEC, hEAT_CAP_FFLOW_SPEC, hEAT_EIR_FFLOW_SPEC)
    
      const_biquadratic = self.create_curve_biquadratic_constant(model)
    
      htg_coil_stage_data = []
      # Loop through speeds to create curves for each speed
      (0...number_Speeds).to_a.each do |speed|

        hp_heat_cap_ft_curve = self.create_curve_biquadratic(model, self.convert_curve_biquadratic(hEAT_CAP_FT_SPEC[speed], true), "HP_Heat-Cap-fT#{speed+1}", -100, 100, -100, 100)
        hp_heat_eir_ft_curve = self.create_curve_biquadratic(model, self.convert_curve_biquadratic(hEAT_EIR_FT_SPEC[speed], true), "HP_Heat-EIR-fT#{speed+1}", -100, 100, -100, 100)
        hp_heat_plf_fplr_curve = self.create_curve_quadratic(model, hEAT_CLOSS_FPLR_SPEC[speed], "HP_Heat-PLF-fPLR#{speed+1}", 0, 1, 0.7, 1)
        hp_heat_cap_fff_curve = self.create_curve_quadratic(model, hEAT_CAP_FFLOW_SPEC[speed], "HP_Heat-CAP-fFF#{speed+1}", 0, 2, 0, 2)
        hp_heat_eir_fff_curve = self.create_curve_quadratic(model, hEAT_EIR_FFLOW_SPEC[speed], "HP_Heat-EIR-fFF#{speed+1}", 0, 2, 0, 2)
      
        stage_data = OpenStudio::Model::CoilHeatingDXMultiSpeedStageData.new(model, 
                                                                             hp_heat_cap_ft_curve, 
                                                                             hp_heat_cap_fff_curve, 
                                                                             hp_heat_eir_ft_curve, 
                                                                             hp_heat_eir_fff_curve, 
                                                                             hp_heat_plf_fplr_curve, 
                                                                             const_biquadratic)
        if outputCapacity != Constants.SizingAuto and outputCapacity != Constants.SizingAutoMaxLoad
          stage_data.setGrossRatedHeatingCapacity(OpenStudio::convert(outputCapacity,"Btu/h","W").get) # Used by HVACSizing measure
        end   
        stage_data.setGrossRatedHeatingCOP(1.0 / heatingEIR[speed])
        stage_data.setRatedWasteHeatFractionofPowerInput(0.2)
        htg_coil_stage_data[speed] = stage_data
      end
      return htg_coil_stage_data
    end
    
    def self.calc_cooling_eir(number_Speeds, coolingEER, supplyFanPower_Rated)
        coolingEIR = Array.new
        (0...number_Speeds).to_a.each do |speed|
          eir = calc_EIR_from_EER(coolingEER[speed], supplyFanPower_Rated)
          coolingEIR << eir
        end
        return coolingEIR
    end
    
    def self.calc_heating_eir(number_Speeds, heatingCOP, supplyFanPower_Rated)
        heatingEIR = Array.new
        (0...number_Speeds).to_a.each do |speed|
          eir = calc_EIR_from_COP(heatingCOP[speed], supplyFanPower_Rated)
          heatingEIR << eir
        end
        return heatingEIR
    end
    
    def self.calc_shr_rated_gross(number_Speeds, shr_Rated_Net, supplyFanPower_Rated, cFM_TON_Rated)
    
        # Convert SHRs from net to gross
        sHR_Rated_Gross = Array.new
        (0...number_Speeds).to_a.each do |speed|

          qtot_net_nominal = 12000.0
          qsens_net_nominal = qtot_net_nominal * shr_Rated_Net[speed]
          qtot_gross_nominal = qtot_net_nominal + OpenStudio::convert(cFM_TON_Rated[speed] * supplyFanPower_Rated,"Wh","Btu").get
          qsens_gross_nominal = qsens_net_nominal + OpenStudio::convert(cFM_TON_Rated[speed] * supplyFanPower_Rated,"Wh","Btu").get
          sHR_Rated_Gross << (qsens_gross_nominal / qtot_gross_nominal)

          # Make sure SHR's are in valid range based on E+ model limits.
          # The following correlation was developed by Jon Winkler to test for maximum allowed SHR based on the 300 - 450 cfm/ton limits in E+
          maxSHR = 0.3821066 + 0.001050652 * cFM_TON_Rated[speed] - 0.01
          sHR_Rated_Gross[speed] = [sHR_Rated_Gross[speed], maxSHR].min
          minSHR = 0.60   # Approximate minimum SHR such that an ADP exists
          sHR_Rated_Gross[speed] = [sHR_Rated_Gross[speed], minSHR].max
        end
        
        return sHR_Rated_Gross
    
    end
    
    def self.calc_plr_coefficients_cooling(number_Speeds, coolingSEER, c_d=nil)
        if c_d.nil?
            if number_Speeds == 1
                c_d = self.calc_Cd_from_SEER_EER_SingleSpeed(coolingSEER)
            elsif number_Speeds == 2
                c_d = self.calc_Cd_from_SEER_EER_TwoSpeed()
            elsif number_Speeds == 4
                c_d = self.calc_Cd_from_SEER_EER_FourSpeed()
            end
        end
        return [(1.0 - c_d), c_d, 0.0] # Linear part load model
    end
    
    def self.calc_plr_coefficients_heating(number_Speeds, heatingHSPF, c_d=nil)
        if c_d.nil?
            if number_Speeds == 1
              c_d = self.calc_Cd_from_HSPF_COP_SingleSpeed(heatingHSPF)
            elsif number_Speeds == 2
              c_d = self.calc_Cd_from_HSPF_COP_TwoSpeed()
            elsif number_Speeds == 4
              c_d = self.calc_Cd_from_HSPF_COP_FourSpeed()
            end
        end
        return [(1 - c_d), c_d, 0] # Linear part load model
    end
    
    def self.get_boiler_curve(model, isCondensing)
        if isCondensing
            return HVAC.create_curve_biquadratic(model, [1.058343061, -0.052650153, -0.0087272, -0.001742217, 0.00000333715, 0.000513723], "CondensingBoilerEff", 0.2, 1.0, 30.0, 85.0)
        else
            return HVAC.create_curve_bicubic(model, [1.111720116, 0.078614078, -0.400425756, 0.0, -0.000156783, 0.009384599, 0.234257955, 1.32927e-06, -0.004446701, -1.22498e-05], "NonCondensingBoilerEff", 0.1, 1.0, 20.0, 80.0)
        end
    end
  
    def self.calculate_fan_efficiency(static, fan_power)
        return OpenStudio::convert(static / fan_power,"cfm","m^3/s").get # Overall Efficiency of the Supply Fan, Motor and Drive
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
    
    def self.prioritize_zone_hvac(model, runner, zone)
      zone_hvac_priority_list = ["ZoneHVACEnergyRecoveryVentilator", "ZoneHVACTerminalUnitVariableRefrigerantFlow", "ZoneHVACBaseboardConvectiveElectric", "ZoneHVACBaseboardConvectiveWater", "AirTerminalSingleDuctUncontrolled", "ZoneHVACDehumidifierDX", "ZoneHVACPackagedTerminalAirConditioner"]    
      zone_hvac_list = []
      zone_hvac_priority_list.each do |zone_hvac_type|
        zone.equipment.each do |object|
          next if not object.respond_to?("to_#{zone_hvac_type}")
          next if not object.public_send("to_#{zone_hvac_type}").is_initialized
          new_object = object.public_send("to_#{zone_hvac_type}").get
          zone_hvac_list << new_object
        end
      end
      return zone_hvac_list
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
        heat_design_db = weather.design.HeatingDrybulb
        
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