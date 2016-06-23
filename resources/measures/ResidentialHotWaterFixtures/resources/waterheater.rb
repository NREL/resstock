# Add classes or functions here than can be used across a variety of our python classes and modules.
require "#{File.dirname(__FILE__)}/constants"
require "#{File.dirname(__FILE__)}/util"
require "#{File.dirname(__FILE__)}/weather"
require "#{File.dirname(__FILE__)}/geometry"

class Waterheater
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
				return input power
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
		pump = OpenStudio::Model::PumpConstantSpeed.new(model)
		pump.setFractionofMotorInefficienciestoFluidStream(0)
		pump.setMotorEfficiency(1)
		pump.setRatedPowerConsumption(0)
		pump.setRatedPumpHead(1)
		return pump
	end
	
	def self.create_new_schedule_ruleset(name, schedule_name, t_set, model)
		#Create a setpoint schedule for the water heater
		new_schedule = OpenStudio::Model::ScheduleRuleset.new(model)
		t_set_c = OpenStudio::convert(t_set,"F","C").get
		new_schedule.setName(name)
		new_schedule.defaultDaySchedule.setName(schedule_name)
		new_schedule.defaultDaySchedule.addValue(OpenStudio::Time.new("24:00:00"), t_set)
		return new_schedule
	end
	
	def self.create_new_heater(cap, fuel, vol, nbeds, nbaths, ef, re, t_set, loc, oncycle_p, offcycle_p, tanktype, cyc_derate, model, runner)
	
		new_heater = OpenStudio::Model::WaterHeaterMixed.new(model)
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
		self.configure_setpoint_schedule(new_heater, t_set, tanktype, model, runner)
		new_heater.setMaximumTemperatureLimit(99.0)
        if tanktype == Constants.WaterHeaterTypeTankless
            new_heater.setHeaterControlType("Modulate")
            new_heater.setDeadbandTemperatureDifference(0)
        else
            new_heater.setHeaterControlType("Cycle")
            new_heater.setDeadbandTemperatureDifference(2)
		end
        
		vol_m3 = OpenStudio::convert(act_vol, "gal", "m^3").get
		new_heater.setHeaterMinimumCapacity(0.0)
		new_heater.setHeaterMaximumCapacity(capacity_w)
		new_heater.setHeaterFuelType(fuel_eplus)
		new_heater.setHeaterThermalEfficiency(eta_c)
		new_heater.setAmbientTemperatureIndicator("ThermalZone")
		new_heater.setTankVolume(vol_m3)
		
		#Set parasitic power consumption
        if tanktype == Constants.WaterHeaterTypeTankless 
            if fuel == Constants.FuelTypeGas
                #TODO: Different fractions if the home only has certain appliances (say no dishwasher or cw)
                runtime_frac = [[0.0275, 0.0267, 0.0270, 0.0267, 0.0270, 0.0264, 0.0265, 0.0269, 0.0269, 0.0269], [0.0327, 0.0334, 0.0333, 0.0336, 0.0333, 0.0334, 0.0340, 0.0337, 0.0326, 0.0334], [0.0397, 0.0393, 0.0394, 0.0399, 0.0401, 0.0397, 0.0395, 0.0393, 0.0397, 0.0399], [0.0454, 0.0470, 0.0459, 0.0458, 0.0457, 0.0469, 0.0461, 0.0459, 0.0462, 0.0469], [0.0527, 0.0519, 0.0526, 0.0534, 0.0528, 0.0524, 0.0533, 0.0531, 0.0526, 0.0537]]
                avg_elec = oncycle_p * runtime_frac[nbeds-1][0] + offcycle_p * (1-runtime_frac[nbeds-1][0]) #TODO: for MF, this needs to take into account unit number
                new_heater.setOnCycleParasiticFuelConsumptionRate(avg_elec)
                new_heater.setOnCycleParasiticFuelType("Electricity")
                new_heater.setOnCycleParasiticHeatFractiontoTank(0)
                
                new_heater.setOffCycleParasiticFuelConsumptionRate(avg_elec)
                new_heater.setOffCycleParasiticFuelType("Electricity")
                new_heater.setOffCycleParasiticHeatFractiontoTank(0)
            else
                new_heater.setOnCycleParasiticFuelConsumptionRate(0)
                new_heater.setOffCycleParasiticFuelConsumptionRate(0)
            end
        else
            new_heater.setOnCycleParasiticFuelConsumptionRate(oncycle_p)
            new_heater.setOnCycleParasiticFuelType("Electricity")
            new_heater.setOnCycleParasiticHeatFractiontoTank(0)
            
            new_heater.setOffCycleParasiticFuelConsumptionRate(offcycle_p)
            new_heater.setOffCycleParasiticFuelType("Electricity")
            new_heater.setOffCycleParasiticHeatFractiontoTank(0)
        end
		
		#Set fraction of heat loss from tank to ambient (vs out flue)
		#Based on lab testing done by LBNL
        if tanktype == Constants.WaterHeaterTypeTankless
            skinlossfrac = 1.0
        else
            if fuel  == Constants.FuelTypeGas or fuel == Constants.FuelTypePropane
                if oncycle_p == 0
                    skinlossfrac = 0.64
                elsif ef < 0.8
                    skinlossfrac = 0.91
                else
                    skinlossfrac = 0.96
                end
            else
                skinlossfrac = 1.0
            end
        end
		new_heater.setOffCycleLossFractiontoThermalZone(skinlossfrac)
		new_heater.setOnCycleLossFractiontoThermalZone(1.0)

		thermal_zone = model.getThermalZones.find{|tz| tz.name.get == loc.to_s}
		new_heater.setAmbientTemperatureThermalZone(thermal_zone)
		ua_w_k = OpenStudio::convert(ua, "Btu/hr*R", "W/K").get
		new_heater.setOnCycleLossCoefficienttoAmbientTemperature(ua_w_k)
		new_heater.setOffCycleLossCoefficienttoAmbientTemperature(ua_w_k)
		
		return new_heater
	end 
  
    def self.configure_setpoint_schedule(new_heater, t_set, tanktype, model, runner)
        if tanktype == Constants.WaterHeaterTypeTankless
            set_temp = OpenStudio::convert(t_set,"F","C").get #Half the deadband (for tank water heaters) to account for E+ deadband
        else
            set_temp = OpenStudio::convert(t_set,"F","C").get + 1 #Half the deadband (for tank water heaters) to account for E+ deadband
		end
        new_schedule = self.create_new_schedule_ruleset("DHW Set Temp", "DHW Set Temp", set_temp, model)
		new_heater.setSetpointTemperatureSchedule(new_schedule)
		runner.registerInfo("A schedule named DHW Set Temp was created and applied to the gas water heater, using a constant temperature of #{t_set.to_s} F for generating domestic hot water.")
	end
	
	def self.create_new_loop(model)
		#Create a new plant loop for the water heater
		loop = OpenStudio::Model::PlantLoop.new(model)
		loop.setName("Domestic Hot Water Loop")
		loop.sizingPlant.setDesignLoopExitTemperature(60)
		loop.sizingPlant.setLoopDesignTemperatureDifference(50)
        loop.setPlantLoopVolume(0.003) #~1 gal
			
		bypass_pipe  = OpenStudio::Model::PipeAdiabatic.new(model)
		out_pipe = OpenStudio::Model::PipeAdiabatic.new(model)
		
		loop.addSupplyBranchForComponent(bypass_pipe)
		out_pipe.addToNode(loop.supplyOutletNode)
		
		return loop
	end
	
	def self.get_water_heater_setpoint(model, plant_loop, runner)
        waterHeater = nil
        plant_loop.supplyComponents.each do |wh|
            if wh.to_WaterHeaterMixed.is_initialized
                waterHeater = wh.to_WaterHeaterMixed.get
            elsif wh.to_WaterHeaterStratified.is_initialized
                waterHeater = wh.to_WaterHeaterStratified.get
            else
                next
            end
            if waterHeater.setpointTemperatureSchedule.nil?
                runner.registerError("Water heater found without a setpoint temperature schedule.")
                return nil
            end
        end
        if waterHeater.nil?
            runner.registerError("No water heater found; add a residential water heater first.")
            return nil
        end
        min_max_result = Schedule.getMinMaxAnnualProfileValue(model, waterHeater.setpointTemperatureSchedule.get)
        wh_setpoint = OpenStudio.convert((min_max_result['min'] + min_max_result['max'])/2.0, "C", "F").get
        if min_max_result['min'] != min_max_result['max']
            runner.registerWarning("Water heater setpoint is not constant. Using average setpoint temperature of #{wh_setpoint.round} F.")
        end
        return wh_setpoint
    end
    
    def self.get_water_heater_location_auto(model, runner)
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
        living = Geometry.get_default_space(model)
        garage = Geometry.get_garage_spaces(model)
        fin_basement = Geometry.get_finished_basement_spaces(model)
        unfin_basement = Geometry.get_unfinished_basement_spaces(model)
        wh_tz = nil
        if ba_cz_name == Constants.BAZoneHotDry or ba_cz_name == Constants.BAZoneHotHumid
            #check if the building has a garage
            if garage.length > 0
                wh_tz = garage[0].thermalZone.get.name
            elsif not living.nil? #no garage, in living space
                wh_tz = living.thermalZone.get.name
            end
        elsif ba_cz_name == Constants.BAZoneMarine or ba_cz_name == Constants.BAZoneMixedHumid or ba_cz_name == Constants.BAZoneMixedHumid or ba_cz_name == Constants.BAZoneCold or ba_cz_name == Constants.BAZoneVeryCold or ba_cz_name == Constants.BAZoneSubarctic
            #FIXME: always locating the water heater in the first unconditioned space, what if there's multiple
            if fin_basement.length > 0
                wh_tz = fin_basement[0].thermalZone.get.name
            elsif unfin_basement.length > 0
                wh_tz = unfin_basement[0].thermalZone.get.name
            elsif not living.nil? #no basement, in living space
                wh_tz = living.thermalZone.get.name
            end
        else
            runner.registerWarning("No Building America climate zone has been assigned. The water heater location will be chosen with the following priority: basement > garage > living")
            #check for suitable WH locations
            #FIXME: in BEopt, priority goes living>fin attic. Since we always assign a zone as the living space in OS, this is the final location.
            #If geometry.rb is changed to better identify living zones, update this code to differentiate between living tz and fin attic tz
            if fin_basement.length > 0
                wh_tz = fin_basement[0].thermalZone.get.name
            elsif unfin_basement.length > 0
                wh_tz = unfin_basement[0].thermalZone.get.name
            elsif garage.length > 0
                wh_tz = garage[0].thermalZone.get.name
            elsif not living.nil? #no basement or garage, in living space
                wh_tz = living.thermalZone.get.name
            end
        end
        
        return wh_tz
    end
end