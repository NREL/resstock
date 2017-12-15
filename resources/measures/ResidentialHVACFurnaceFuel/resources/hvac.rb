require "#{File.dirname(__FILE__)}/constants"
require "#{File.dirname(__FILE__)}/geometry"
require "#{File.dirname(__FILE__)}/util"
require "#{File.dirname(__FILE__)}/unit_conversions"

class HVAC

    def self.calc_EIR_from_COP(cop, supplyFanPower_Rated)
        return UnitConversions.convert((UnitConversions.convert(1,"Btu","Wh") + supplyFanPower_Rated * 0.03333) / cop - supplyFanPower_Rated * 0.03333,"Wh","Btu")
    end
  
    def self.calc_EIR_from_EER(eer, supplyFanPower_Rated)
        return UnitConversions.convert((1 - UnitConversions.convert(supplyFanPower_Rated * 0.03333,"Wh","Btu")) / eer - supplyFanPower_Rated * 0.03333,"Wh","Btu")
    end
    
    def self.calc_cfm_ton_rated(rated_airflow_rate, fanspeed_ratios, capacity_ratios)
        array = []
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
            si_coeff = []
            si_coeff << coeff[0] + 32.0 * (coeff[1] + coeff[3]) + 1024.0 * (coeff[2] + coeff[4] + coeff[5])
            si_coeff << 9.0 / 5.0 * coeff[1] + 576.0 / 5.0 * coeff[2] + 288.0 / 5.0 * coeff[5]
            si_coeff << 81.0 / 25.0 * coeff[2]
            si_coeff << 9.0 / 5.0 * coeff[3] + 576.0 / 5.0 * coeff[4] + 288.0 / 5.0 * coeff[5]
            si_coeff << 81.0 / 25.0 * coeff[4]
            si_coeff << 81.0 / 25.0 * coeff[5]        
            return si_coeff
        else
            # Convert SI curves to IP curves
            ip_coeff = []
            ip_coeff << coeff[0] - 160.0/9.0 * (coeff[1] + coeff[3]) + 25600.0/81.0 * (coeff[2] + coeff[4] + coeff[5])
            ip_coeff << 5.0/9.0 * (coeff[1] - 320.0/9.0 * coeff[2] - 160.0/9.0 * coeff[5])
            ip_coeff << 25.0/81.0 * coeff[2]
            ip_coeff << 5.0/9.0 * (coeff[3] - 320.0/9.0 * coeff[4] - 160.0/9.0 * coeff[5])
            ip_coeff << 25.0/81.0 * coeff[4]
            ip_coeff << 25.0/81.0 * coeff[5]
            return ip_coeff
        end
    end
    
    def self.convert_curve_gshp(coeff, gshp_to_biquadratic)
        m1 = 32 - 273.15 * 1.8
        m2 = 283 * 1.8
        if gshp_to_biquadratic
            biq_coeff = []
            biq_coeff << coeff[0] - m1 * ((coeff[1] + coeff[2]) / m2)
            biq_coeff << coeff[1] / m2
            biq_coeff << 0
            biq_coeff << coeff[2] / m2
            biq_coeff << 0
            biq_coeff << 0
            return biq_coeff
        else
            gsph_coeff = []
            gsph_coeff << coeff[0] + m1 * (coeff[1] + coeff[3])
            gsph_coeff << m2 * coeff[1]
            gsph_coeff << m2 * coeff[3]
            gsph_coeff << 0
            gsph_coeff << 0
            return gsph_coeff
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
      
    def self.calc_coil_stage_data_cooling(model, outputCapacity, number_Speeds, coolingEIR, shr_Rated_Gross, cOOL_CAP_FT_SPEC, cOOL_EIR_FT_SPEC, cOOL_CLOSS_FPLR_SPEC, cOOL_CAP_FFLOW_SPEC, cOOL_EIR_FFLOW_SPEC, distributionSystemEfficiency)

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
          stage_data.setGrossRatedTotalCoolingCapacity(UnitConversions.convert(outputCapacity,"Btu/hr","W")) # Used by HVACSizing measure
        end
        stage_data.setGrossRatedSensibleHeatRatio(shr_Rated_Gross[speed])
        stage_data.setGrossRatedCoolingCOP(distributionSystemEfficiency / coolingEIR[speed])
        stage_data.setNominalTimeforCondensateRemovaltoBegin(1000)
        stage_data.setRatioofInitialMoistureEvaporationRateandSteadyStateLatentCapacity(1.5)
        stage_data.setMaximumCyclingRate(3)
        stage_data.setLatentCapacityTimeConstant(45)
        stage_data.setRatedWasteHeatFractionofPowerInput(0.2)
        clg_coil_stage_data[speed] = stage_data
      end
      return clg_coil_stage_data
    end
      
    def self.calc_coil_stage_data_heating(model, outputCapacity, number_Speeds, heatingEIR, hEAT_CAP_FT_SPEC, hEAT_EIR_FT_SPEC, hEAT_CLOSS_FPLR_SPEC, hEAT_CAP_FFLOW_SPEC, hEAT_EIR_FFLOW_SPEC, distributionSystemEfficiency)
    
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
          stage_data.setGrossRatedHeatingCapacity(UnitConversions.convert(outputCapacity,"Btu/hr","W")) # Used by HVACSizing measure
        end   
        stage_data.setGrossRatedHeatingCOP(distributionSystemEfficiency / heatingEIR[speed])
        stage_data.setRatedWasteHeatFractionofPowerInput(0.2)
        htg_coil_stage_data[speed] = stage_data
      end
      return htg_coil_stage_data
    end
    
    def self.calc_cooling_eir(number_Speeds, coolingEER, supplyFanPower_Rated)
        coolingEIR = []
        (0...number_Speeds).to_a.each do |speed|
          eir = calc_EIR_from_EER(coolingEER[speed], supplyFanPower_Rated)
          coolingEIR << eir
        end
        return coolingEIR
    end
    
    def self.calc_heating_eir(number_Speeds, heatingCOP, supplyFanPower_Rated)
        heatingEIR = []
        (0...number_Speeds).to_a.each do |speed|
          eir = calc_EIR_from_COP(heatingCOP[speed], supplyFanPower_Rated)
          heatingEIR << eir
        end
        return heatingEIR
    end
    
    def self.calc_shr_rated_gross(number_Speeds, shr_Rated_Net, supplyFanPower_Rated, cFM_TON_Rated)
    
        # Convert SHRs from net to gross
        sHR_Rated_Gross = []
        (0...number_Speeds).to_a.each do |speed|

          qtot_net_nominal = 12000.0
          qsens_net_nominal = qtot_net_nominal * shr_Rated_Net[speed]
          qtot_gross_nominal = qtot_net_nominal + UnitConversions.convert(cFM_TON_Rated[speed] * supplyFanPower_Rated,"Wh","Btu")
          qsens_gross_nominal = qsens_net_nominal + UnitConversions.convert(cFM_TON_Rated[speed] * supplyFanPower_Rated,"Wh","Btu")
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
          c_d = self.get_c_d_cooling(number_Speeds, coolingSEER)
        end
        return [(1.0 - c_d), c_d, 0.0] # Linear part load model
    end
    
    def self.calc_plr_coefficients_heating(number_Speeds, heatingHSPF, c_d=nil)
        if c_d.nil?
          c_d = self.get_c_d_heating(number_Speeds, heatingHSPF)
        end
        return [(1 - c_d), c_d, 0] # Linear part load model
    end
    
    def self.get_c_d_cooling(number_Speeds, coolingSEER)
        # Degradation coefficient for cooling
        if number_Speeds == 1
          if coolingSEER < 13.0
            return 0.20
          else
            return 0.07
          end
        elsif number_Speeds == 2
          return 0.11
        elsif number_Speeds == 4
          return 0.25
        end
    end
    
    def self.get_c_d_heating(number_Speeds, heatingHSPF)
        # Degradation coefficient for heating
        if number_Speeds == 1
          if heatingHSPF < 7.0
            return 0.20
          else
            return 0.11
          end
        elsif number_Speeds == 2
          return 0.11
        elsif number_Speeds == 4
          return 0.24
        end
    end
    
    def self.get_boiler_curve(model, isCondensing)
        if isCondensing
            return HVAC.create_curve_biquadratic(model, [1.058343061, -0.052650153, -0.0087272, -0.001742217, 0.00000333715, 0.000513723], "CondensingBoilerEff", 0.2, 1.0, 30.0, 85.0)
        else
            return HVAC.create_curve_bicubic(model, [1.111720116, 0.078614078, -0.400425756, 0.0, -0.000156783, 0.009384599, 0.234257955, 1.32927e-06, -0.004446701, -1.22498e-05], "NonCondensingBoilerEff", 0.1, 1.0, 20.0, 80.0)
        end
    end
  
    def self.calculate_fan_efficiency(static, fan_power)
        return UnitConversions.convert(static / fan_power,"cfm","m^3/s") # Overall Efficiency of the Supply Fan, Motor and Drive
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
      # Returns a list of cooling equipment objects
      cooling_equipment = []
      if self.has_ashp(model, runner, thermal_zone)
        runner.registerInfo("Found air source heat pump in #{thermal_zone.name}.")
        system, clg_coil, htg_coil, air_loop = self.get_unitary_system(model, runner, thermal_zone)
        cooling_equipment << system
      end
      if self.has_central_ac(model, runner, thermal_zone)
        runner.registerInfo("Found central air conditioner in #{thermal_zone.name}.")
        system, clg_coil, htg_coil, air_loop = self.get_unitary_system(model, runner, thermal_zone)
        cooling_equipment << system
      end
      if self.has_room_ac(model, runner, thermal_zone)
        runner.registerInfo("Found room air conditioner in #{thermal_zone.name}.")
        ptac = self.get_ptac(model, runner, thermal_zone)
        cooling_equipment << ptac
      end
      if self.has_mshp(model, runner, thermal_zone)
        runner.registerInfo("Found mini split heat pump in #{thermal_zone.name}.")
        vrf = self.get_vrf(model, runner, thermal_zone)
        vrf.terminals.each do |terminal|
          cooling_equipment << terminal
        end
      end
      if self.has_gshp(model, runner, thermal_zone)
        system, clg_coil, htg_coil, air_loop = self.get_unitary_system(model, runner, thermal_zone)
        runner.registerInfo("Found ground source heat pump in #{thermal_zone.name}.")
        cooling_equipment << system
      end
      return cooling_equipment
    end
    
    def self.existing_heating_equipment(model, runner, thermal_zone)
      # Returns a list of heating equipment objects
      heating_equipment = []
      if self.has_ashp(model, runner, thermal_zone)
        runner.registerInfo("Found air source heat pump in #{thermal_zone.name}.")
        system, clg_coil, htg_coil, air_loop = self.get_unitary_system(model, runner, thermal_zone)
        heating_equipment << system
      end
      if self.has_furnace(model, runner, thermal_zone)
        runner.registerInfo("Found furnace in #{thermal_zone.name}.")
        system, clg_coil, htg_coil, air_loop = self.get_unitary_system(model, runner, thermal_zone)
        heating_equipment << system
      end
      if self.has_boiler(model, runner, thermal_zone)
        runner.registerInfo("Found boiler serving #{thermal_zone.name}.")
        baseboard = self.get_baseboard_water(model, runner, thermal_zone)
        heating_equipment << baseboard
      end
      if self.has_electric_baseboard(model, runner, thermal_zone)
        runner.registerInfo("Found electric baseboard in #{thermal_zone.name}.")
        baseboard = self.get_baseboard_electric(model, runner, thermal_zone)
        heating_equipment << baseboard
      end
      if self.has_mshp(model, runner, thermal_zone)
        runner.registerInfo("Found mini split heat pump in #{thermal_zone.name}.")
        vrf = self.get_vrf(model, runner, thermal_zone)
        vrf.terminals.each do |terminal|
          heating_equipment << terminal
        end
      end
      if self.has_gshp(model, runner, thermal_zone)
        runner.registerInfo("Found ground source heat pump in #{thermal_zone.name}.")
        system, clg_coil, htg_coil, air_loop = self.get_unitary_system(model, runner, thermal_zone)
        heating_equipment << system
      end
      return heating_equipment
    end
    
    def self.get_coils_from_hvac_equip(hvac_equip)
      # Returns the clg coil, htg coil, and supp htg coil as applicable
      clg_coil = nil
      htg_coil = nil
      supp_htg_coil = nil
      if hvac_equip.is_a? OpenStudio::Model::AirLoopHVACUnitarySystem
        htg_coil = HVAC.get_coil_from_hvac_component(hvac_equip.heatingCoil)
        clg_coil = HVAC.get_coil_from_hvac_component(hvac_equip.coolingCoil)
        supp_htg_coil = HVAC.get_coil_from_hvac_component(hvac_equip.supplementalHeatingCoil)
      elsif hvac_equip.to_ZoneHVACTerminalUnitVariableRefrigerantFlow.is_initialized
        htg_coil = HVAC.get_coil_from_hvac_component(hvac_equip.heatingCoil)
        clg_coil = HVAC.get_coil_from_hvac_component(hvac_equip.coolingCoil)
      elsif hvac_equip.is_a? OpenStudio::Model::ZoneHVACBaseboardConvectiveWater
        htg_coil = HVAC.get_coil_from_hvac_component(hvac_equip.heatingCoil)
      elsif hvac_equip.is_a? OpenStudio::Model::ZoneHVACPackagedTerminalAirConditioner
        htg_coil = HVAC.get_coil_from_hvac_component(hvac_equip.heatingCoil)
        clg_coil = HVAC.get_coil_from_hvac_component(hvac_equip.coolingCoil)
      end
      return clg_coil, htg_coil, supp_htg_coil
    end

    def self.get_coil_from_hvac_component(hvac_component)
      # Check for optional objects
      if (hvac_component.is_a? OpenStudio::Model::OptionalHVACComponent or
          hvac_component.is_a? OpenStudio::Model::OptionalCoilHeatingDXVariableRefrigerantFlow or
          hvac_component.is_a? OpenStudio::Model::OptionalCoilCoolingDXVariableRefrigerantFlow)
        return nil if not hvac_component.is_initialized
        hvac_component = hvac_component.get
      end
    
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
    
    def self.get_unitary_system(model, runner, thermal_zone)
      # Returns the unitary system, cooling coil, heating coil, and air loop if available
      model.getAirLoopHVACs.each do |air_loop|
        air_loop.thermalZones.each do |thermalZone|
          next unless thermal_zone.handle.to_s == thermalZone.handle.to_s
          air_loop.supplyComponents.each do |supply_component|
            next unless supply_component.to_AirLoopHVACUnitarySystem.is_initialized
            system = supply_component.to_AirLoopHVACUnitarySystem.get
            clg_coil = nil
            htg_coil = nil
            if system.coolingCoil.is_initialized
              clg_coil = system.coolingCoil.get
            end
            if system.heatingCoil.is_initialized
              htg_coil = system.heatingCoil.get
            end
            return system, clg_coil, htg_coil, air_loop
          end
        end
      end
      return nil, nil, nil, nil
    end
    
    def self.get_vrf(model, runner, thermal_zone)
      # Returns the VRF or nil
      model.getAirConditionerVariableRefrigerantFlows.each do |vrf|
        vrf.terminals.each do |terminal|
          next unless thermal_zone.handle.to_s == terminal.thermalZone.get.handle.to_s
          return vrf
        end
      end
      return nil
    end
    
    def self.get_ptac(model, runner, thermal_zone)
      # Returns the PTAC or nil
      model.getZoneHVACPackagedTerminalAirConditioners.each do |ptac|
        next unless thermal_zone.handle.to_s == ptac.thermalZone.get.handle.to_s
        return ptac
      end
      return nil
    end
    
    def self.get_baseboard_water(model, runner, thermal_zone)
      # Returns the water baseboard or nil
      model.getZoneHVACBaseboardConvectiveWaters.each do |baseboard|
        next unless thermal_zone.handle.to_s == baseboard.thermalZone.get.handle.to_s
        return baseboard
      end
      return nil
    end
    
    def self.get_baseboard_electric(model, runner, thermal_zone)
      # Returns the electric baseboard or nil
      model.getZoneHVACBaseboardConvectiveElectrics.each do |baseboard|
        next unless thermal_zone.handle.to_s == baseboard.thermalZone.get.handle.to_s
        return baseboard
      end
      return nil
    end
    
    # Has Equipment methods
    
    def self.has_central_ac(model, runner, thermal_zone)
      system, clg_coil, htg_coil, air_loop = self.get_unitary_system(model, runner, thermal_zone)
      if system.nil? or clg_coil.nil?
        return false
      end
      if not (clg_coil.to_CoilCoolingDXSingleSpeed.is_initialized or clg_coil.to_CoilCoolingDXMultiSpeed.is_initialized)
        return false
      end
      if not htg_coil.nil?
        if htg_coil.to_CoilHeatingDXSingleSpeed.is_initialized or htg_coil.to_CoilHeatingDXMultiSpeed.is_initialized
          return false # ASHP
        end
      end
      return true
    end
    
    def self.has_ashp(model, runner, thermal_zone)
      system, clg_coil, htg_coil, air_loop = self.get_unitary_system(model, runner, thermal_zone)
      if system.nil? or clg_coil.nil? or htg_coil.nil?
        return false
      end
      if not (clg_coil.to_CoilCoolingDXSingleSpeed.is_initialized or clg_coil.to_CoilCoolingDXMultiSpeed.is_initialized)
        return false
      end
      if not (htg_coil.to_CoilHeatingDXSingleSpeed.is_initialized or htg_coil.to_CoilHeatingDXMultiSpeed.is_initialized)
        return false
      end
      return true
    end
    
    def self.has_gshp(model, runner, thermal_zone)
      system, clg_coil, htg_coil, air_loop = self.get_unitary_system(model, runner, thermal_zone)
      if system.nil? or clg_coil.nil? or htg_coil.nil?
        return false
      end
      if not clg_coil.to_CoilCoolingWaterToAirHeatPumpEquationFit.is_initialized
        return false
      end
      if not htg_coil.to_CoilHeatingWaterToAirHeatPumpEquationFit.is_initialized
        return false
      end
      return true
    end
    
    def self.has_furnace(model, runner, thermal_zone)
      system, clg_coil, htg_coil, air_loop = self.get_unitary_system(model, runner, thermal_zone)
      if system.nil? or htg_coil.nil?
        return false
      end
      if not (htg_coil.to_CoilHeatingGas.is_initialized or htg_coil.to_CoilHeatingElectric.is_initialized)
        return false
      end
      return true
    end
    
    def self.has_mshp(model, runner, thermal_zone)
      vrf = self.get_vrf(model, runner, thermal_zone)
      if vrf.nil?
        return false
      end
      return true
    end
    
    def self.has_room_ac(model, runner, thermal_zone)
      ptac = self.get_ptac(model, runner, thermal_zone)
      if not ptac.nil?
        return true
      end
      return false
    end
    
    def self.has_boiler(model, runner, thermal_zone)
      baseboard = self.get_baseboard_water(model, runner, thermal_zone)
      if not baseboard.nil?
        return true
      end
      return false
    end
    
    def self.has_electric_baseboard(model, runner, thermal_zone)
      baseboard = self.get_baseboard_electric(model, runner, thermal_zone)
      if not baseboard.nil?
        return true
      end
      return false
    end
    
    # Remove Equipment methods
    
    def self.remove_central_ac(model, runner, thermal_zone)
      # Returns true if the object was removed
      return false if not self.has_central_ac(model, runner, thermal_zone)
      system, clg_coil, htg_coil, air_loop = self.get_unitary_system(model, runner, thermal_zone)
      runner.registerInfo("Removed '#{clg_coil.name}' from '#{air_loop.name}'.")
      system.resetCoolingCoil
      clg_coil.remove
      system.supplyFan.get.remove
      return true
    end
    
    
    def self.remove_ashp(model, runner, thermal_zone)
      # Returns true if the object was removed
      return false if not self.has_ashp(model, runner, thermal_zone)
      system, clg_coil, htg_coil, air_loop = self.get_unitary_system(model, runner, thermal_zone)
      runner.registerInfo("Removed '#{clg_coil.name}' and '#{htg_coil.name}' from '#{air_loop.name}'.")
      system.resetHeatingCoil
      system.resetCoolingCoil              
      htg_coil.remove
      clg_coil.remove
      return true
    end
    
    def self.remove_gshp(model, runner, thermal_zone)
      # Returns true if the object was removed
      return false if not self.has_gshp(model, runner, thermal_zone)
      system, clg_coil, htg_coil, air_loop = self.get_unitary_system(model, runner, thermal_zone)
      runner.registerInfo("Removed '#{clg_coil.name}' and '#{htg_coil.name}' from '#{air_loop.name}'.")
      system.resetHeatingCoil
      system.resetCoolingCoil              
      htg_coil.remove
      clg_coil.remove
      return true
    end
    
    def self.remove_furnace(model, runner, thermal_zone)
      # Returns true if the object was removed
      return false if not self.has_furnace(model, runner, thermal_zone)
      system, clg_coil, htg_coil, air_loop = self.get_unitary_system(model, runner, thermal_zone)
      runner.registerInfo("Removed '#{htg_coil.name}' from '#{air_loop.name}'.")
      system.resetHeatingCoil
      htg_coil.remove
      system.supplyFan.get.remove
      return true
    end
    
    def self.remove_mshp(model, runner, thermal_zone, unit)
      # Returns true if the object was removed
      return false if not self.has_mshp(model, runner, thermal_zone)
      vrf = self.get_vrf(model, runner, thermal_zone)
      runner.registerInfo("Removed '#{vrf.name}' from #{thermal_zone.name}.")
      vrf.terminals.each do |terminal|
        terminal.remove
      end
      vrf.remove

      obj_name = Constants.ObjectNameMiniSplitHeatPump(unit.name.to_s)
      
      model.getOutputVariables.each do |output_var|
        next unless output_var.name.to_s == Constants.ObjectNameMiniSplitHeatPump + " vrf heat energy output var"
        output_var.remove
      end
      model.getOutputVariables.each do |output_var|
        next unless output_var.name.to_s == Constants.ObjectNameMiniSplitHeatPump + " zone outdoor air drybulb temp output var"
        output_var.remove
      end

      model.getEnergyManagementSystemSensors.each do |sensor|
        next unless sensor.name.to_s == "#{obj_name} vrf energy sensor".gsub(" ","_").gsub("|","_")
        sensor.remove
      end
      model.getEnergyManagementSystemSensors.each do |sensor|
        next unless sensor.name.to_s == "#{obj_name} vrf fbsmt energy sensor".gsub(" ","_").gsub("|","_")
        sensor.remove
      end
      model.getEnergyManagementSystemSensors.each do |sensor|
        next unless sensor.name.to_s == "#{obj_name} tout sensor".gsub(" ","_").gsub("|","_")
        sensor.remove
      end
      model.getEnergyManagementSystemActuators.each do |actuator|
        next unless actuator.name.to_s == "#{obj_name} pan heater actuator".gsub(" ","_").gsub("|","_")
        actuator.remove
      end
      model.getEnergyManagementSystemPrograms.each do |program|
        next unless program.name.to_s == "#{obj_name} pan heater program".gsub(" ","_")
        program.remove
      end          
      model.getEnergyManagementSystemProgramCallingManagers.each do |program_calling_manager|
        next unless program_calling_manager.name.to_s == obj_name + " pan heater program calling manager"
        program_calling_manager.remove
      end
      
      thermal_zone.spaces.each do |space|
        space.electricEquipment.each do |equip|
          next unless equip.name.to_s == obj_name + " pan heater equip"
          equip.electricEquipmentDefinition.remove
        end
      end
      return true
    end
    
    def self.remove_room_ac(model, runner, thermal_zone)
      # Returns true if the object was removed
      return false if not self.has_room_ac(model, runner, thermal_zone)
      ptac = self.get_ptac(model, runner, thermal_zone)
      runner.registerInfo("Removed '#{ptac.name}' from #{thermal_zone.name}.")
      ptac.remove
      return true
    end
    
    def self.remove_boiler(model, runner, thermal_zone)
      # Returns true if the object was removed
      return false if not self.has_boiler(model, runner, thermal_zone)
      baseboard = self.get_baseboard_water(model, runner, thermal_zone)
      runner.registerInfo("Removed '#{baseboard.name}' from #{thermal_zone.name}.")
      baseboard.remove
      return true
    end
    
    def self.remove_electric_baseboard(model, runner, thermal_zone)
      # Returns true if the object was removed
      return false if not self.has_electric_baseboard(model, runner, thermal_zone)
      baseboard = self.get_baseboard_electric(model, runner, thermal_zone)
      runner.registerInfo("Removed '#{baseboard.name}' from #{thermal_zone.name}.")
      baseboard.remove
      return true
    end
    
    def self.remove_boiler_and_gshp_loops(model, runner)
      # TODO: Add a BuildingUnit argument
      model.getPlantLoops.each do |plant_loop|
        remove = false
        plant_loop.supplyComponents.each do |supply_component|
          if supply_component.to_BoilerHotWater.is_initialized or supply_component.to_GroundHeatExchangerVertical.is_initialized or supply_component.to_GroundHeatExchangerHorizontalTrench.is_initialized
            remove = true
          end
        end
        if remove
          runner.registerInfo("Removed '#{plant_loop.name}' from model.")
          plant_loop.remove
        end
      end
    end 
    
    def self.remove_air_loop(model, runner, thermal_zone, clone_perf=false)
      # Returns the cloned perf or nil
      model.getAirLoopHVACs.each do |air_loop|
        air_loop.thermalZones.each do |thermalZone|
          next unless thermal_zone.handle.to_s == thermalZone.handle.to_s
          air_loop.supplyComponents.each do |supply_component|
            next unless supply_component.to_AirLoopHVACUnitarySystem.is_initialized
            air_loop_unitary = supply_component.to_AirLoopHVACUnitarySystem.get
            next if air_loop_unitary.heatingCoil.is_initialized or air_loop_unitary.coolingCoil.is_initialized
            runner.registerInfo("Removed '#{air_loop.name}' from #{thermal_zone.name}.")
            cloned_perf = nil
            if clone_perf and air_loop_unitary.designSpecificationMultispeedObject.is_initialized
              perf = air_loop_unitary.designSpecificationMultispeedObject.get
              cloned_perf = perf.clone.to_UnitarySystemPerformanceMultispeed.get
              cloned_perf.setName(perf.name.to_s)
            end
            air_loop.remove
            return cloned_perf
          end
        end
      end
      return nil
    end
    
    # Reset Equipment methods
    
    def self.reset_central_ac(model, runner, thermal_zone)
      # Returns the cloned coil or nil
      return nil if not self.has_central_ac(model, runner, thermal_zone)
      system, clg_coil, htg_coil, air_loop = self.get_unitary_system(model, runner, thermal_zone)
      cloned_clg_coil = clg_coil.clone
      system.resetCoolingCoil
      clg_coil.remove
      system.supplyFan.get.remove
      cloned_clg_coil = self.get_coil_from_hvac_component(cloned_clg_coil)
      cloned_clg_coil.setName(clg_coil.name.to_s)
      return cloned_clg_coil
    end
    
    def self.reset_furnace(model, runner, thermal_zone)
      # Returns the cloned coil or nil
      return nil if not self.has_furnace(model, runner, thermal_zone)
      system, clg_coil, htg_coil, air_loop = self.get_unitary_system(model, runner, thermal_zone)
      cloned_htg_coil = htg_coil.clone
      system.resetHeatingCoil
      htg_coil.remove
      system.supplyFan.get.remove
      if cloned_htg_coil.to_CoilHeatingGas.is_initialized
        cloned_htg_coil = cloned_htg_coil.to_CoilHeatingGas.get
      elsif cloned_htg_coil.to_CoilHeatingElectric.is_initialized
        cloned_htg_coil = cloned_htg_coil.to_CoilHeatingElectric.get
      end
      cloned_htg_coil.setName(htg_coil.name.to_s)
      return cloned_htg_coil
    end
    
    def self.remove_existing_hvac_equipment(model, runner, new_equip, thermal_zone, clone_perf, unit)
      counterpart_equip = nil
      perf = nil
      case new_equip
      when Constants.ObjectNameCentralAirConditioner
        removed_ashp = self.remove_ashp(model, runner, thermal_zone)
        removed_mshp = self.remove_mshp(model, runner, thermal_zone, unit)
        counterpart_equip = self.reset_furnace(model, runner, thermal_zone)
        removed_ac = self.remove_central_ac(model, runner, thermal_zone)
        removed_room_ac = self.remove_room_ac(model, runner, thermal_zone)
        removed_gshp = self.remove_gshp(model, runner, thermal_zone)
        if removed_mshp
          removed_elec_baseboard = self.remove_electric_baseboard(model, runner, thermal_zone)
        end
        if counterpart_equip or removed_ac or removed_ashp or removed_gshp
          self.remove_air_loop(model, runner, thermal_zone)
        end
        if removed_gshp
          self.remove_boiler_and_gshp_loops(model, runner)
        end
      when Constants.ObjectNameRoomAirConditioner
        removed_ashp = self.remove_ashp(model, runner, thermal_zone)
        removed_mshp = self.remove_mshp(model, runner, thermal_zone, unit)
        removed_room_ac = self.remove_room_ac(model, runner, thermal_zone)
        removed_ac = self.remove_central_ac(model, runner, thermal_zone)
        removed_gshp = self.remove_gshp(model, runner, thermal_zone)
        if removed_mshp
          removed_elec_baseboard = self.remove_electric_baseboard(model, runner, thermal_zone)
        end        
        if removed_ac or removed_ashp or removed_gshp
          self.remove_air_loop(model, runner, thermal_zone)
        end
        if removed_gshp
          self.remove_boiler_and_gshp_loops(model, runner)
        end        
      when Constants.ObjectNameFurnace
        removed_ashp = self.remove_ashp(model, runner, thermal_zone)
        removed_mshp = self.remove_mshp(model, runner, thermal_zone, unit)
        counterpart_equip = self.reset_central_ac(model, runner, thermal_zone)
        removed_furnace = self.remove_furnace(model, runner, thermal_zone)
        removed_boiler = self.remove_boiler(model, runner, thermal_zone)
        removed_elec_baseboard = self.remove_electric_baseboard(model, runner, thermal_zone)
        removed_gshp = self.remove_gshp(model, runner, thermal_zone)
        if counterpart_equip or removed_furnace or removed_ashp or removed_gshp
          if removed_ashp or removed_gshp
            clone_perf = false
          end
          perf = self.remove_air_loop(model, runner, thermal_zone, clone_perf)
        end
      when Constants.ObjectNameBoiler
        removed_boiler = self.remove_boiler(model, runner, thermal_zone)
        removed_furnace = self.remove_furnace(model, runner, thermal_zone)
        removed_elec_baseboard = self.remove_electric_baseboard(model, runner, thermal_zone)
        removed_ashp = self.remove_ashp(model, runner, thermal_zone)
        removed_mshp = self.remove_mshp(model, runner, thermal_zone, unit)
        removed_gshp = self.remove_gshp(model, runner, thermal_zone)
        if removed_furnace or removed_ashp or removed_mshp or removed_gshp
          self.remove_air_loop(model, runner, thermal_zone)
        end
      when Constants.ObjectNameElectricBaseboard
        removed_elec_baseboard = self.remove_electric_baseboard(model, runner, thermal_zone)
        removed_furnace = self.remove_furnace(model, runner, thermal_zone)
        removed_boiler = self.remove_boiler(model, runner, thermal_zone)
        removed_ashp = self.remove_ashp(model, runner, thermal_zone)
        removed_mshp = self.remove_mshp(model, runner, thermal_zone, unit)
        removed_gshp = self.remove_gshp(model, runner, thermal_zone)
        if removed_furnace or removed_ashp or removed_gshp
          self.remove_air_loop(model, runner, thermal_zone)
        end
      when Constants.ObjectNameAirSourceHeatPump
        removed_ashp = self.remove_ashp(model, runner, thermal_zone)
        removed_mshp = self.remove_mshp(model, runner, thermal_zone, unit)
        removed_ac = self.remove_central_ac(model, runner, thermal_zone)
        removed_room_ac = self.remove_room_ac(model, runner, thermal_zone)
        removed_furnace = self.remove_furnace(model, runner, thermal_zone)
        removed_boiler = self.remove_boiler(model, runner, thermal_zone)
        removed_elec_baseboard = self.remove_electric_baseboard(model, runner, thermal_zone)
        removed_gshp = self.remove_gshp(model, runner, thermal_zone)
        if removed_ashp or removed_ac or removed_furnace or removed_gshp
          self.remove_air_loop(model, runner, thermal_zone)
        end
      when Constants.ObjectNameMiniSplitHeatPump
        removed_mshp = self.remove_mshp(model, runner, thermal_zone, unit)
        removed_ashp = self.remove_ashp(model, runner, thermal_zone)
        removed_ac = self.remove_central_ac(model, runner, thermal_zone)
        removed_room_ac = self.remove_room_ac(model, runner, thermal_zone)
        removed_furnace = self.remove_furnace(model, runner, thermal_zone)
        removed_boiler = self.remove_boiler(model, runner, thermal_zone)
        removed_elec_baseboard = self.remove_electric_baseboard(model, runner, thermal_zone)
        removed_gshp = self.remove_gshp(model, runner, thermal_zone)
        if removed_ac or removed_furnace or removed_ashp or removed_gshp
          self.remove_air_loop(model, runner, thermal_zone)
        end
      when Constants.ObjectNameGroundSourceHeatPumpVerticalBore
        removed_ashp = self.remove_ashp(model, runner, thermal_zone)
        removed_mshp = self.remove_mshp(model, runner, thermal_zone, unit)
        removed_ac = self.remove_central_ac(model, runner, thermal_zone)
        removed_room_ac = self.remove_room_ac(model, runner, thermal_zone)
        removed_furnace = self.remove_furnace(model, runner, thermal_zone)
        removed_boiler = self.remove_boiler(model, runner, thermal_zone)
        removed_elec_baseboard = self.remove_electric_baseboard(model, runner, thermal_zone)
        removed_gshp = self.remove_gshp(model, runner, thermal_zone)
        if removed_ashp or removed_ac or removed_furnace or removed_gshp
          self.remove_air_loop(model, runner, thermal_zone)
        end
      end
      return counterpart_equip, perf
    end   
    
    def self.prioritize_zone_hvac(model, runner, zone)
      zone_hvac_priority_list = [
                                 "ZoneHVACEnergyRecoveryVentilator", 
                                 "ZoneHVACTerminalUnitVariableRefrigerantFlow", 
                                 "ZoneHVACBaseboardConvectiveElectric", 
                                 "ZoneHVACBaseboardConvectiveWater", 
                                 "AirTerminalSingleDuctUncontrolled", 
                                 "ZoneHVACDehumidifierDX", 
                                 "ZoneHVACPackagedTerminalAirConditioner"
                                ]    
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