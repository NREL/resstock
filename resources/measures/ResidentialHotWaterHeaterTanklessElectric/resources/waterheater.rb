# Add classes or functions here than can be used across a variety of our python classes and modules.
require "#{File.dirname(__FILE__)}/constants"
require "#{File.dirname(__FILE__)}/util"
require "#{File.dirname(__FILE__)}/weather"
require "#{File.dirname(__FILE__)}/geometry"
require "#{File.dirname(__FILE__)}/schedules"

class Waterheater

    def self.get_plant_loop_from_string(plant_loops, plantloop_s, spaces, unit_num, runner=nil)
        if plantloop_s == Constants.Auto
            return self.get_plant_loop_for_spaces(plant_loops, spaces, unit_num, runner)
        end
        plant_loop = nil
        plant_loops.each do |pl|
            if pl.name.to_s == plantloop_s
                plant_loop = pl
                break
            end
        end
        if plant_loop.nil? and !runner
            runner.registerError("Could not find plant loop with the name '#{plantloop_s}'.")
        end
        return plant_loop
    end
    
    def self.get_plant_loop_for_spaces(plant_loops, spaces, unit_num, runner=nil)
        # We obtain the plant loop for a given set of space by comparing 
        # their associated thermal zones to the thermal zone that each plant
        # loop water heater is located in.
        spaces.each do |space|
            next if !space.thermalZone.is_initialized
            zone = space.thermalZone.get
            wh_type = "none" #TODO: 2 tank SHW might have both mixed and stratified tanks
            plant_loops.each do |pl|
                pl.supplyComponents.each do |wh|
                    if wh.to_WaterHeaterMixed.is_initialized
                        waterHeater = wh.to_WaterHeaterMixed.get
                        wh_type = "mixed" 
                    elsif wh.to_WaterHeaterStratified.is_initialized
                        waterHeater = wh.to_WaterHeaterStratified.get
                        wh_type = "stratified"
                    else
                        next
                    end
                    if wh_type == "mixed"
                        next if !waterHeater.ambientTemperatureThermalZone.is_initialized
                        next if waterHeater.ambientTemperatureThermalZone.get.name.to_s != zone.name.to_s
                        return pl
                    elsif wh_type == "stratified"
                        #Check if the water heater has a thermal zone attached to it, if not check if it has a schedule and the schedule name matches what we expect
                        if waterHeater.ambientTemperatureThermalZone.is_initialized
                            next if waterHeater.ambientTemperatureThermalZone.get.name.to_s != zone.name.to_s
                            return pl
                        elsif waterHeater.ambientTemperatureSchedule.is_initialized
                            if waterHeater.ambientTemperatureSchedule.get.name.to_s == "HPWH_Tamb_act_#{unit_num}" or waterHeater.ambientTemperatureSchedule.get.name.to_s == "HPWH_Tamb_act2_#{unit_num}"
                                return pl
                            end
                        end
                    end
                end
            end
        end
        if !runner.nil?
            runner.registerError("Could not find plant loop.")
        end
        return nil
    end

    def self.deadband(tank_type)
        if tank_type == Constants.WaterHeaterTypeTank
            return 2.0 # deg-C
        else
            return 0.0 # deg-C
        end
    end
    
    def self.calc_nom_tankvol(vol, fuel, num_beds, num_baths)
        #Calculates the volume of a water heater
        if vol == Constants.Auto
            #Based on the BA HSP
            if fuel == Constants.FuelTypeElectric
            # Source: Table 5 HUD-FHA Minimum Water Heater Capacities for One- and 
            # Two-Family Living Units (ASHRAE HVAC Applications 2007)
                if num_baths < 2
                    if num_beds < 2
                        return 20
                    elsif num_beds < 3
                        return 30
                    else
                        return 40
                    end
                elsif num_baths < 3
                    if num_beds < 3
                        return 40
                    elsif num_beds < 5
                        return 50
                    else
                        return 66
                    end
                else
                    if num_beds < 4
                        return 50
                    elsif num_beds < 6
                        return 66
                    else
                        return 80
                    end
                end
            
            else # Non-electric tank WHs
            # Source: 2010 HSP Addendum
                if num_beds <= 2
                    return 30
                elsif num_beds == 3
                    if num_baths <= 1.5
                        return 30
                    else
                        return 40
                    end
                elsif num_beds == 4
                    if num_baths <= 2.5
                        return 40
                    else
                        return 50
                    end
                else
                    return 50
                end
            end
        else #user entered volume
            return vol.to_f
        end
    end

    def self.calc_capacity(cap, fuel, num_beds, num_baths)
    #Calculate the capacity of the water heater based on the fuel type and number of bedrooms and bathrooms in a home
    #returns the capacity in kBtu/hr
        if cap == Constants.Auto
            if fuel != Constants.FuelTypeElectric
                if num_beds <= 3
                    input_power = 36
                elsif num_beds == 4
                    if num_baths <= 2.5
                        input_power = 36
                    else
                        input_power = 38
                    end
                elsif num_beds == 5
                    input_power = 47
                else
                    input_power = 50
                end
                return input_power
            
            else
                if num_beds == 1
                    input_power = 2.5
                elsif num_beds == 2
                    if num_baths <= 1.5
                        input_power = 3.5
                    else
                        input_power = 4.5
                    end
                elsif num_beds == 3
                    if num_baths <= 1.5
                        input_power = 4.5
                    else
                        input_power = 5.5
                    end
                else
                    input_power = 5.5
                end
                return input_power
            end
            
        else #fixed heater size
            return cap.to_f
        end
    end

    def self.calc_actual_tankvol(vol, fuel, tanktype)
    #Convert the nominal tank volume to an actual volume
        if tanktype == Constants.WaterHeaterTypeTankless
            act_vol = 1 #gal
        else
            if fuel == Constants.FuelTypeElectric
                act_vol = 0.9 * vol
            else
                act_vol = 0.95 * vol
            end
        end
        return act_vol
    end
    
    def self.calc_ef(ef, vol, fuel)
    #Calculate the energy factor as a function of the tank volume and fuel type
        if ef == Constants.Auto
            if fuel == Constants.FuelTypePropane or fuel == Constants.FuelTypeGas
                return 0.67 - (0.0019 * vol)
            elsif fuel == Constants.FuelTypeElectric
                return 0.97 - (0.00132 * vol)
            else
                return 0.59 - (0.0019 * vol)
            end
        else #user input energy factor
            return ef.to_f
        end
    end

    def self.calc_tank_UA(vol, fuel, ef, re, pow, tanktype, cyc_derate)
    #Calculates the U value, UA of the tank and conversion efficiency (eta_c)
    #based on the Energy Factor and recovery efficiency of the tank
    #Source: Burch and Erickson 2004 - http://www.nrel.gov/docs/gen/fy04/36035.pdf
        if tanktype == Constants.WaterHeaterTypeTankless
            eta_c = ef * (1 - cyc_derate)
            ua = 0
            surface_area = 1
        else
            pi = Math::PI
            volume_drawn = 64.3 # gal/day
            density = 8.2938 # lb/gal
            draw_mass = volume_drawn * density # lb
            cp = 1.0007 # Btu/lb-F
            t = 135 # F
            t_in = 58 # F
            t_env = 67.5 # F
            q_load = draw_mass * cp * (t - t_in) # Btu/day
            height = 48 # inches
            diameter = 24 * ((vol * 0.1337) / (height / 12 * pi)) ** 0.5 # inches       
            surface_area = 2 * pi * (diameter / 12) ** 2 / 4 + pi * (diameter / 12) * (height / 12) # sqft

            if fuel != Constants.FuelTypeElectric
                ua = (re / ef - 1) / ((t - t_env) * (24 / q_load - 1 / (1000*(pow) * ef))) #Btu/hr-F
                eta_c = (re + ua * (t - t_env) / (1000 * pow))
            else # is Electric
                ua = q_load * (1 / ef - 1) / ((t - t_env) * 24)
                eta_c = 1.0
            end
        end
        u = ua / surface_area #Btu/hr-ft^2-F
        return u, ua, eta_c
    end
    
    def self.create_new_pump(model)
        #Add a pump to the new DHW loop
        pump = OpenStudio::Model::PumpVariableSpeed.new(model)
        pump.setRatedFlowRate(0.01)
        pump.setFractionofMotorInefficienciestoFluidStream(0)
        pump.setMotorEfficiency(1)
        pump.setRatedPowerConsumption(0)
        pump.setRatedPumpHead(1)
        pump.setCoefficient1ofthePartLoadPerformanceCurve(0)
        pump.setCoefficient2ofthePartLoadPerformanceCurve(1)
        pump.setCoefficient3ofthePartLoadPerformanceCurve(0)
        pump.setCoefficient4ofthePartLoadPerformanceCurve(0)
        pump.setPumpControlType("Intermittent")
        return pump
    end
    
    def self.create_new_schedule_manager(t_set, model, wh_type="tank")
        new_schedule = OpenStudio::Model::ScheduleConstant.new(model)
        new_schedule.setName("DHW Temp")
        if wh_type == "tank"
            new_schedule.setValue(OpenStudio::convert(t_set,"F","C").get + 1)
        else #tankless
            new_schedule.setValue(OpenStudio::convert(t_set,"F","C").get)
        end
        OpenStudio::Model::SetpointManagerScheduled.new(model, new_schedule)
    end 
    
    def self.create_new_heater(unit_index, name, cap, fuel, vol, nbeds, nbaths, ef, re, t_set, thermal_zone, oncycle_p, offcycle_p, tanktype, cyc_derate, measure_dir, model, runner)
    
        new_heater = OpenStudio::Model::WaterHeaterMixed.new(model)
        new_heater.setName(name)
        fuel_eplus = HelperMethods.eplus_fuel_map(fuel)
        capacity = self.calc_capacity(cap, fuel, nbeds, nbaths)
        if fuel != Constants.FuelTypeElectric
            capacity_w = OpenStudio::convert(capacity,"kBtu/hr","W").get
        else
            capacity_w = OpenStudio::convert(capacity,"kW","W").get
        end
        nom_vol = self.calc_nom_tankvol(vol, fuel, nbeds, nbaths)
        act_vol = self.calc_actual_tankvol(nom_vol, fuel, tanktype)
        energy_factor = self.calc_ef(ef, nom_vol, fuel)
        u, ua, eta_c = self.calc_tank_UA(act_vol, fuel, energy_factor, re, capacity, tanktype, cyc_derate)
        self.configure_setpoint_schedule(new_heater, t_set, tanktype, model)
        new_heater.setMaximumTemperatureLimit(99.0)
        if tanktype == Constants.WaterHeaterTypeTankless
            new_heater.setHeaterControlType("Modulate")
        else
            new_heater.setHeaterControlType("Cycle")
        end
        new_heater.setDeadbandTemperatureDifference(self.deadband(tanktype))
        
        vol_m3 = OpenStudio::convert(act_vol, "gal", "m^3").get
        new_heater.setHeaterMinimumCapacity(0.0)
        new_heater.setHeaterMaximumCapacity(capacity_w)
        new_heater.setHeaterFuelType(fuel_eplus)
        new_heater.setHeaterThermalEfficiency(eta_c)
        new_heater.setTankVolume(vol_m3)
        
        #Set parasitic power consumption
        if tanktype == Constants.WaterHeaterTypeTankless 
            # Tankless WHs are set to "modulate", not "cycle", so they end up
            # effectively always on. Thus, we need to use a weighted-average of
            # on-cycle and off-cycle parasitics.
            sch = HotWaterSchedule.new(model, runner, "", "", nbeds, unit_index, nil, 0, measure_dir, false)
            if not sch.validated?
                return nil
            end
            runtime_frac = sch.getOntimeFraction
            avg_elec = oncycle_p * runtime_frac + offcycle_p * (1-runtime_frac)
            
            new_heater.setOnCycleParasiticFuelConsumptionRate(avg_elec)
            new_heater.setOffCycleParasiticFuelConsumptionRate(avg_elec)
        else
            new_heater.setOnCycleParasiticFuelConsumptionRate(oncycle_p)
            new_heater.setOffCycleParasiticFuelConsumptionRate(offcycle_p)
        end
        new_heater.setOnCycleParasiticFuelType("Electricity")
        new_heater.setOffCycleParasiticFuelType("Electricity")
        new_heater.setOnCycleParasiticHeatFractiontoTank(0)
        new_heater.setOffCycleParasiticHeatFractiontoTank(0)
        
        #Set fraction of heat loss from tank to ambient (vs out flue)
        #Based on lab testing done by LBNL
        skinlossfrac = 1.0
        if fuel != Constants.FuelTypeElectric and tanktype == Constants.WaterHeaterTypeTank
            if oncycle_p == 0
                skinlossfrac = 0.64
            elsif energy_factor < 0.8
                skinlossfrac = 0.91
            else
                skinlossfrac = 0.96
            end
        end
        new_heater.setOffCycleLossFractiontoThermalZone(skinlossfrac)
        new_heater.setOnCycleLossFractiontoThermalZone(1.0)

        new_heater.setAmbientTemperatureIndicator("ThermalZone")
        new_heater.setAmbientTemperatureThermalZone(thermal_zone)
        if new_heater.ambientTemperatureSchedule.is_initialized
            new_heater.ambientTemperatureSchedule.get.remove
        end
        ua_w_k = OpenStudio::convert(ua, "Btu/hr*R", "W/K").get
        new_heater.setOnCycleLossCoefficienttoAmbientTemperature(ua_w_k)
        new_heater.setOffCycleLossCoefficienttoAmbientTemperature(ua_w_k)
        
        return new_heater
    end 
  
    def self.configure_setpoint_schedule(new_heater, t_set, tanktype, model)
        set_temp_c = OpenStudio::convert(t_set,"F","C").get + self.deadband(tanktype)/2.0 #Half the deadband to account for E+ deadband
        new_schedule = OpenStudio::Model::ScheduleConstant.new(model)
        new_schedule.setName("WH Setpoint Temp")
        new_schedule.setValue(set_temp_c)
        if new_heater.setpointTemperatureSchedule.is_initialized
            new_heater.setpointTemperatureSchedule.get.remove
        end
        new_heater.setSetpointTemperatureSchedule(new_schedule)
    end
    
    def self.create_new_loop(model, name, t_set, wh_type="tank")
        #Create a new plant loop for the water heater
        loop = OpenStudio::Model::PlantLoop.new(model)
        loop.setName(name)
        if wh_type == "tank"
            loop.sizingPlant.setDesignLoopExitTemperature(OpenStudio::convert(t_set,"F","C").get + 1)
        else #tankless
            loop.sizingPlant.setDesignLoopExitTemperature(OpenStudio::convert(t_set,"F","C").get)
        end
        loop.sizingPlant.setLoopDesignTemperatureDifference(OpenStudio::convert(10,"R","K").get)
        loop.setPlantLoopVolume(0.003) #~1 gal
        loop.setMaximumLoopFlowRate(0.01) # This size represents the physical limitations to flow due to losses in the piping system. For BEopt we assume that the pipes are always adequately sized
            
        bypass_pipe  = OpenStudio::Model::PipeAdiabatic.new(model)
        out_pipe = OpenStudio::Model::PipeAdiabatic.new(model)
        
        loop.addSupplyBranchForComponent(bypass_pipe)
        out_pipe.addToNode(loop.supplyOutletNode)
        
        return loop
    end
    
    def self.get_water_heater_setpoint(model, plant_loop, runner)
        waterHeater = nil
        wh_type = nil
        hpwh = model.getWaterHeaterHeatPumpWrappedCondensers
        len_wh_array = 0 #TODO: what to do for MF cases with multiple HPWHs? presumably this method will be called with a unit number and the # of hpwhs should be 1
        if hpwh.size > 0
            wh_type = "hpwh"
            for wh in hpwh
                waterHeater = wh
                len_wh_array += 1
            end
        end
        if wh_type.nil?
            plant_loop.supplyComponents.each do |wh|
                if wh.to_WaterHeaterMixed.is_initialized
                    waterHeater = wh.to_WaterHeaterMixed.get
                    wh_type = "mixed"
                    break
                end
            end
        end
        if wh_type == "mixed"
            if waterHeater.setpointTemperatureSchedule.nil?
                runner.registerError("Water heater found without a setpoint temperature schedule.")
                return nil
            end
        elsif wh_type == "hpwh"
            if waterHeater.compressorSetpointTemperatureSchedule.nil?
                runner.registerError("Heat pump water heater found without a setpoint temperature schedule.")
                return nil
            end
        end
        if waterHeater.nil?
            runner.registerError("No water heater found; add a residential water heater first.")
            return nil
        end
        if wh_type == "mixed"
            return OpenStudio.convert(waterHeater.setpointTemperatureSchedule.get.to_ScheduleConstant.get.value - waterHeater.deadbandTemperatureDifference/2.0,"C","F").get
        else #wh_type == "hpwh"
            return OpenStudio.convert(waterHeater.compressorSetpointTemperatureSchedule.to_ScheduleConstant.get.value,"C","F").get
        end
    end
    
    def self.get_water_heater_location_auto(model, spaces, runner)
        #If auto is picked, get the BA climate zone, 
        #check if the building has a garage/basement, 
        #and assign the water heater location appropriately
        climateZones = model.getClimateZones
        ba_cz_name = ""
        climateZones.climateZones.each do |climateZone|
            if climateZone.institution == Constants.BuildingAmericaClimateZone
                ba_cz_name = climateZone.value.to_s
            end
        end
        living = Geometry.get_unit_default_finished_space(spaces, runner)
        garage = Geometry.get_garage_spaces(spaces, model)
        fin_basement = Geometry.get_finished_basement_spaces(spaces)
        unfin_basement = Geometry.get_unfinished_basement_spaces(spaces)
        wh_tz = nil
        if ba_cz_name == Constants.BAZoneHotDry or ba_cz_name == Constants.BAZoneHotHumid
            #check if the building has a garage
            if garage.length > 0
                wh_tz = garage[0].thermalZone.get
            elsif not living.nil? #no garage, in living space
                wh_tz = living.thermalZone.get
            end
        elsif ba_cz_name == Constants.BAZoneMarine or ba_cz_name == Constants.BAZoneMixedHumid or ba_cz_name == Constants.BAZoneMixedHumid or ba_cz_name == Constants.BAZoneCold or ba_cz_name == Constants.BAZoneVeryCold or ba_cz_name == Constants.BAZoneSubarctic
            #TODO: always locating the water heater in the first unconditioned space, what if there's multiple
            if fin_basement.length > 0
                wh_tz = fin_basement[0].thermalZone.get
            elsif unfin_basement.length > 0
                wh_tz = unfin_basement[0].thermalZone.get
            elsif not living.nil? #no basement, in living space
                wh_tz = living.thermalZone.get
            end
        else
            runner.registerWarning("No Building America climate zone has been assigned. The water heater location will be chosen with the following priority: basement > garage > living")
            #check for suitable WH locations
            #TODO: in BEopt, priority goes living>fin attic. Since we always assign a zone as the living space in OS, this is the final location.
            #If geometry.rb is changed to better identify living zones, update this code to differentiate between living tz and fin attic tz
            if fin_basement.length > 0
                wh_tz = fin_basement[0].thermalZone.get
            elsif unfin_basement.length > 0
                wh_tz = unfin_basement[0].thermalZone.get
            elsif garage.length > 0
                wh_tz = garage[0].thermalZone.get
            elsif not living.nil? #no basement or garage, in living space
                wh_tz = living.thermalZone.get
            end
        end
        
        return wh_tz
    end
end