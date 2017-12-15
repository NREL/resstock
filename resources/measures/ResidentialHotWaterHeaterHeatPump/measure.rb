# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/measures/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/waterheater"
require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"
require "#{File.dirname(__FILE__)}/resources/psychrometrics"
require "#{File.dirname(__FILE__)}/resources/unit_conversions"

#start the measure
class ResidentialHotWaterHeaterHeatPump < OpenStudio::Measure::ModelMeasure

    #define the name that a user will see, this method may be deprecated as
    #the display name in PAT comes from the name field in measure.xml
    def name
        return "Set Residential Heat Pump Water Heater"
    end
  
    def description
        return "This measure adds a new residential heat pump water heater to the model based on user inputs. If there is already an existing residential water heater in the model, it is replaced. For multifamily buildings, the water heater can be set for all units of the building.#{Constants.WorkflowDescription}"
    end
  
    def modeler_description
        return "The measure will create a new instance of the OS:WaterHeater:HeatPump:WrappedCondenser object representing a heat pump water heater and EMS code for the controls. The water heater will be placed on the plant loop 'Domestic Hot Water Loop'. If this loop already exists, any water heater on that loop will be removed and replaced with a water heater consistent with this measure. If it doesn't exist, it will be created."
    end

    #define the arguments that the user will input
    def arguments(model)
        ruleset = OpenStudio::Ruleset
    
        osargument = OpenStudio::Measure::OSArgument
    
        args = OpenStudio::Measure::OSArgumentVector.new

        # make an argument for the storage tank volume
        storage_tank_volume = osargument::makeDoubleArgument("storage_tank_volume", true)
        storage_tank_volume.setDisplayName("Tank Volume")
        storage_tank_volume.setDescription("Nominal volume of the of the water heater tank.")
        storage_tank_volume.setUnits("gal")
        storage_tank_volume.setDefaultValue(50)
        args << storage_tank_volume

        # make an argument for hot water setpoint temperature
        dhw_setpoint = osargument::makeDoubleArgument("setpoint_temp", true)
        dhw_setpoint.setDisplayName("Setpoint")
        dhw_setpoint.setDescription("Water heater setpoint temperature.")
        dhw_setpoint.setUnits("F")
        dhw_setpoint.setDefaultValue(125)
        args << dhw_setpoint
        
        #make a choice argument for water heater location
        spaces = Geometry.get_all_unit_spaces(model)
        if spaces.nil?
            spaces = []
        end
        space_args = OpenStudio::StringVector.new
        space_args << Constants.Auto
        spaces.each do |space|
            space_args << space.name.to_s
        end
        space = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("space", space_args, true)
        space.setDisplayName("Location")
        space.setDescription("Select the space where the water heater is located. #{Constants.Auto} will locate the water heater according the BA House Simulation Protocols: A garage (if available) or the living space in hot-dry and hot-humid climates, a basement (finished or unfinished, if available) or living space in all other climates.")
        space.setDefaultValue(Constants.Auto)
        args << space
        
        # make an argument for element_capacity
        element_capacity = osargument::makeDoubleArgument("element_capacity", true)
        element_capacity.setDisplayName("Input Capacity")
        element_capacity.setDescription("The capacity of the backup electric resistance elements in the tank.")
        element_capacity.setUnits("kW")
        element_capacity.setDefaultValue(4.5)
        args << element_capacity
        
        # make an argument for min_temp
        min_temp = osargument::makeDoubleArgument("min_temp", true)
        min_temp.setDisplayName("Minimum Abient Temperature")
        min_temp.setDescription("The minimum ambient air temperature at which the heat pump compressor will operate.")
        min_temp.setUnits("F")
        min_temp.setDefaultValue(45)
        args << min_temp
        
        # make an argument for max_temp
        max_temp = osargument::makeDoubleArgument("max_temp", true)
        max_temp.setDisplayName("Maximum Ambient Temperature")
        max_temp.setDescription("The maximum ambient air temperature at which the heat pump compressor will operate.")
        max_temp.setUnits("F")
        max_temp.setDefaultValue(120)
        args << max_temp
        
        # make an argument for cap
        cap = osargument::makeDoubleArgument("cap", true)
        cap.setDisplayName("Rated Capacity")
        cap.setDescription("The input power of the HPWH compressor at rated conditions.")
        cap.setUnits("kW")
        cap.setDefaultValue(0.5)
        args << cap
        
        # make an argument for cop
        cop = osargument::makeDoubleArgument("cop", true)
        cop.setDisplayName("Rated COP")
        cop.setDescription("The coefficient of performance of the HPWH compressor at rated conditions.")
        cop.setDefaultValue(2.8)
        args << cop
        
        # make an argument for shr
        shr = osargument::makeDoubleArgument("shr", true)
        shr.setDisplayName("Rated SHR")
        shr.setDescription("The sensible heat ratio of the HPWH's evaporator at rated conditions. This is the net SHR of the evaporator and includes the effects of fan heat.")
        shr.setDefaultValue(0.88)
        args << shr
        
        # make an argument for airflow_rate
        airflow_rate = osargument::makeDoubleArgument("airflow_rate", true)
        airflow_rate.setDisplayName("Airflow Rate")
        airflow_rate.setDescription("Air flow rate of the HPWH.")
        airflow_rate.setUnits("cfm")
        airflow_rate.setDefaultValue(181)
        args << airflow_rate
        
        # make an argument for fan_power
        fan_power = osargument::makeDoubleArgument("fan_power", true)
        fan_power.setDisplayName("Fan Power")
        fan_power.setDescription("Fan power (in W) per delivered airflow rate (in cfm).")
        fan_power.setUnits("W/cfm")
        fan_power.setDefaultValue(0.0462)
        args << fan_power
        
        # make an argument for parasitics
        parasitics = osargument::makeDoubleArgument("parasitics", true)
        parasitics.setDisplayName("Parasitics")
        parasitics.setDescription("Parasitic electricity consumption of the HPWH.")
        parasitics.setUnits("W")
        parasitics.setDefaultValue(3)
        args << parasitics
        
        # make an argument for tank_ua
        tank_ua = osargument::makeDoubleArgument("tank_ua", true)
        tank_ua.setDisplayName("Tank UA")
        tank_ua.setDescription("The overall UA of the tank.")
        tank_ua.setUnits("Btu/h-R")
        tank_ua.setDefaultValue(3.9)
        args << tank_ua
        
        # make an argument for int_factor
        int_factor = osargument::makeDoubleArgument("int_factor", true)
        int_factor.setDisplayName("Interaction Factor")
        int_factor.setDescription("Specifies how much the HPWH space conditioning impact interacts with the building's HVAC equipment. This can be used to account for situations such as when a HPWH is in a closet and only a portion of the HPWH's space cooling affects the HVAC system.")
        int_factor.setDefaultValue(1.0)
        args << int_factor
        
        # make an argument for temp_depress
        temp_depress = osargument::makeDoubleArgument("temp_depress", true)
        temp_depress.setDisplayName("Temperature Depression")
        temp_depress.setDescription("The reduction in ambient air temperature in the space where the water heater is located. This variable can be used to simulate the impact the HPWH has on its own performance when installing in a confined space suc as a utility closet.")
        temp_depress.setUnits("F")
        temp_depress.setDefaultValue(0)
        args << temp_depress
        
        # make an argument for ducting
        #COMMENTED OUT FOR NOW, NEED TO INTEGRATE WITH AIRFLOW MEASURE
        #ducting_names = OpenStudio::StringVector.new
        #ducting_names << "none"
        #ducting_names << Constants.VentTypeExhaust
        #ducting_names << Constants.VentTypeSupply
        #ducting_names << Constants.VentTypeBalanced
        #ducting = osargument::makeChoiceArgument("ducting", ducting_names, true)
        #ducting.setDisplayName("Ducting")
        #ducting.setDescription("Specifies where the HPWH pulls air from/exhausts to. The HPWH can currentlyonly be ducted outside of the home, not to different zones within the home.")
        #ducting.setDefaultValue("none")
        #args << ducting
        
        return args
    end #end the arguments method

    #define what happens when the measure is run
    def run(model, runner, user_arguments)
        super(model, runner, user_arguments)

        #Assign user inputs to variables
        e_cap = runner.getDoubleArgumentValue("element_capacity",user_arguments)
        vol = runner.getDoubleArgumentValue("storage_tank_volume",user_arguments)
        water_heater_space_name = runner.getStringArgumentValue("space",user_arguments)
        t_set = runner.getDoubleArgumentValue("setpoint_temp",user_arguments).to_f
        min_temp = runner.getDoubleArgumentValue("min_temp",user_arguments).to_f
        max_temp = runner.getDoubleArgumentValue("max_temp",user_arguments).to_f
        cap = runner.getDoubleArgumentValue("cap",user_arguments).to_f
        cop = runner.getDoubleArgumentValue("cop",user_arguments).to_f
        shr = runner.getDoubleArgumentValue("shr",user_arguments).to_f
        airflow_rate = runner.getDoubleArgumentValue("airflow_rate",user_arguments).to_f
        fan_power = runner.getDoubleArgumentValue("fan_power",user_arguments).to_f
        parasitics = runner.getDoubleArgumentValue("parasitics",user_arguments).to_f
        tank_ua = runner.getDoubleArgumentValue("tank_ua",user_arguments).to_f
        int_factor = runner.getDoubleArgumentValue("int_factor",user_arguments).to_f
        temp_depress = runner.getDoubleArgumentValue("temp_depress",user_arguments).to_f
        #ducting = runner.getStringArgumentValue("ducting",user_arguments)
        ducting = "none"
        
        input_power_w = UnitConversions.convert(cap,"kW","W") 
        rated_heat_cap = input_power_w * cop
        
        #Validate inputs
        if not runner.validateUserArguments(arguments(model), user_arguments)
            return false
        end
        
        # Validate inputs further
        valid_vol = validate_storage_tank_volume(vol, runner)
        if valid_vol.nil?
            return false
        end
        valid_t_set = validate_setpoint_temperature(t_set, runner)
        if valid_t_set.nil?
            return false
        end
        valid_cap = validate_element_capacity(e_cap, runner)
        if valid_cap.nil?
            return false
        end
        
        valid_min_temp = validate_min_temp(min_temp,runner)
        if valid_min_temp.nil?
            return false
        end
        
        valid_max_temp = validate_max_temp(max_temp,runner)
        if valid_max_temp.nil?
            return false
        end
        
        valid_cap = validate_cap(cap,runner)
        if valid_cap.nil?
            return false
        end
        
        valid_cop = validate_cop(cop,runner)
        if valid_cop.nil?
            return false
        end
        
        valid_shr = validate_shr(shr,runner)
        if valid_shr.nil?
            return false
        end
        
        valid_airflow_rate = validate_airflow_rate(airflow_rate,runner)
        if valid_airflow_rate.nil?
            return false
        end
        
        valid_fan_power = validate_fan_power(fan_power,runner)
        if valid_fan_power.nil?
            return false
        end
        
        valid_parasitics = validate_parasitics(parasitics,runner)
        if valid_parasitics.nil?
            return false
        end
        
        valid_ua = validate_tank_ua(tank_ua,runner)
        if valid_ua.nil?
            return false
        end
        
        valid_int_factor = validate_int_factor(int_factor,runner)
        if valid_int_factor.nil?
            return false
        end
        
        valid_temp_depress = validate_temp_depress(temp_depress,runner)
        if valid_temp_depress.nil?
            return false
        end
        
        # Get building units
        units = Geometry.get_building_units(model, runner)
        if units.nil?
            return false
        end

        #Check if mains temperature has been set
        if !model.getSite.siteWaterMainsTemperature.is_initialized
            runner.registerError("Mains water temperature has not been set.")
            return false
        end

        ["Zone Outdoor Air Drybulb Temperature", "Zone Outdoor Air Relative Humidity", "Zone Mean Air Temperature", "Zone Air Relative Humidity", "Water Heater Heat Loss Rate", "Cooling Coil Sensible Cooling Rate", "Cooling Coil Latent Cooling Rate", "Fan Electric Power", "Zone Mean Air Humidity Ratio", "System Node Pressure", "System Node Temperature", "System Node Humidity Ratio", "System Node Current Density Volume Flow Rate", "Water Heater Temperature Node 3", "Water Heater Heater 2 Heating Energy", "Water Heater Heater 1 Heating Energy"].each do |output_var_name|
          unless model.getOutputVariables.any? {|existing_output_var| existing_output_var.name.to_s == output_var_name} 
            output_var = OpenStudio::Model::OutputVariable.new(output_var_name, model)
            output_var.setName(output_var_name)
          end
        end
        
        zone_outdoor_air_drybulb_temp_output_var = nil
        zone_outdoor_air_relative_humidity_output_var = nil
        space_temp_output_var = nil
        space_rh_output_var = nil
        wh_tank_losses = nil
        hpwh_sensible_cooling = nil
        hpwh_latent_cooling = nil
        hpwh_fan_power = nil
        hpwh_amb_w = nil
        hpwh_amb_p = nil
        hpwh_tair_out = nil
        hpwh_wair_out = nil
        hpwh_v_air = nil
        t_ctrl = nil
        le_p = nil
        ue_p = nil
        model.getOutputVariables.each do |output_var|
          if output_var.name.to_s == "Zone Outdoor Air Drybulb Temperature"
            zone_outdoor_air_drybulb_temp_output_var = output_var
          elsif output_var.name.to_s == "Zone Outdoor Air Relative Humidity"
            zone_outdoor_air_relative_humidity_output_var = output_var
          elsif output_var.name.to_s == "Zone Mean Air Temperature"
            space_temp_output_var = output_var
          elsif output_var.name.to_s == "Zone Air Relative Humidity"
            space_rh_output_var = output_var
          elsif output_var.name.to_s == "Water Heater Heat Loss Rate"
            wh_tank_losses = output_var
          elsif output_var.name.to_s == "Cooling Coil Sensible Cooling Rate"
            hpwh_sensible_cooling = output_var
          elsif output_var.name.to_s == "Cooling Coil Latent Cooling Rate"
            hpwh_latent_cooling = output_var
          elsif output_var.name.to_s == "Fan Electric Power"
            hpwh_fan_power = output_var
          elsif output_var.name.to_s == "Zone Mean Air Humidity Ratio"
            hpwh_amb_w = output_var
          elsif output_var.name.to_s == "System Node Pressure"
            hpwh_amb_p = output_var
          elsif output_var.name.to_s == "System Node Temperature"
            hpwh_tair_out = output_var       
          elsif output_var.name.to_s == "System Node Humidity Ratio"
            hpwh_wair_out = output_var
          elsif output_var.name.to_s == "System Node Current Density Volume Flow Rate"
            hpwh_v_air = output_var
          elsif output_var.name.to_s == "Water Heater Temperature Node 3"
            t_ctrl = output_var
          elsif output_var.name.to_s == "Water Heater Heater 2 Heating Energy"
            le_p = output_var  
          elsif output_var.name.to_s == "Water Heater Heater 1 Heating Energy"
            ue_p = output_var
          end
        end
        
        weather = WeatherProcess.new(model, runner, File.dirname(__FILE__))
        if weather.error?
            return false
        end
        alt = weather.header.Altitude

        units.each do |unit|

            obj_name_hpwh = Constants.ObjectNameWaterHeater(unit.name.to_s.gsub("unit", "u")).gsub("|","_")

            unit_num = Geometry.get_unit_number(model, unit, runner)

            # Get unit beds/baths
            nbeds, nbaths = Geometry.get_unit_beds_baths(model, unit, runner)
            if nbeds.nil? or nbaths.nil?
                return false
            end
            sch_unit_index = Geometry.get_unit_dhw_sched_index(model, unit, runner)
            if sch_unit_index.nil?
                return false
            end

            #If location is Auto, get the location
            water_heater_tz = nil
            if water_heater_space_name != Constants.Auto
                water_heater_tz = Geometry.get_thermal_zones_from_spaces([Geometry.get_space_from_string(model.getSpaces, water_heater_space_name)])[0]
            else
                water_heater_tz = Waterheater.get_water_heater_location_auto(model, unit.spaces, runner)
                if water_heater_tz.nil?
                    runner.registerError("The water heater cannot be automatically assigned to a thermal zone. Please manually select which zone the water heater should be located in.")
                    return false
                end
            end
            water_heater_space = water_heater_tz.spaces[0] #first space in the zone
        
            #Check if a DHW plant loop already exists, if not add it
            loop = nil
        
            model.getPlantLoops.each do |pl|
                next if pl.name.to_s != Constants.PlantLoopDomesticWater(unit.name.to_s)
                loop = pl
                #Remove any existing water heater
                objects_to_remove = []
                pl.supplyComponents.each do |wh|
                    next if !wh.to_WaterHeaterMixed.is_initialized and !wh.to_WaterHeaterStratified.is_initialized
                    if wh.to_WaterHeaterMixed.is_initialized
                        objects_to_remove << wh
                        if wh.to_WaterHeaterMixed.get.setpointTemperatureSchedule.is_initialized
                          objects_to_remove << wh.to_WaterHeaterMixed.get.setpointTemperatureSchedule.get
                        end
                    elsif wh.to_WaterHeaterStratified.is_initialized
                        if not wh.to_WaterHeaterStratified.get.secondaryPlantLoop.is_initialized
                          model.getWaterHeaterHeatPumpWrappedCondensers.each do |hpwh|
                            objects_to_remove << hpwh.tank
                            objects_to_remove << hpwh                            
                          end
                          objects_to_remove << wh.to_WaterHeaterStratified.get.heater1SetpointTemperatureSchedule
                          objects_to_remove << wh.to_WaterHeaterStratified.get.heater2SetpointTemperatureSchedule
                          Waterheater.remove_existing_hpwh(model, obj_name_hpwh)
                        end
                    end
                end
                if objects_to_remove.size > 0
                    runner.registerInfo("Removed the existing water heater from plant loop #{pl.name.to_s}.")
                end
                objects_to_remove.uniq.each do |object|
                    begin
                        object.remove
                    rescue
                        # no op
                    end
                end
            end

            if loop.nil?
                runner.registerInfo("A new plant loop for DHW will be added to the model")
                runner.registerInitialCondition("There is no existing water heater")
                loop = Waterheater.create_new_loop(model, Constants.PlantLoopDomesticWater(unit.name.to_s), t_set, Constants.WaterHeaterTypeHeatPump)
            else
                runner.registerInitialCondition("An existing water heater was found in the model. This water heater will be removed and replace with a heat pump water heater")
            end

            if loop.components(OpenStudio::Model::PumpVariableSpeed::iddObjectType).empty?
                new_pump = Waterheater.create_new_pump(model)
                new_pump.addToNode(loop.supplyInletNode)
            end

            if loop.supplyOutletNode.setpointManagers.empty?
                new_manager = Waterheater.create_new_schedule_manager(t_set, model, Constants.WaterHeaterTypeHeatPump)
                new_manager.addToNode(loop.supplyOutletNode)
            end

            #Only ever going to make HPWHs in this measure, so don't split this code out to waterheater.rb
            #Calculate some geometry parameters for UA, the location of sensors and heat sources in the tank
            
            if vol > 50
                hpwh_param = 80
            else
                hpwh_param = 50
            end
            
            h_tank = 0.0188 * vol + 0.0935 #Linear relationship that gets GE height at 50 gal and AO Smith height at 80 gal
            v_actual = 0.9 * vol
            pi = Math::PI
            r_tank = (UnitConversions.convert(v_actual,"gal","m^3") / (pi * h_tank))**0.5
            a_tank = 2 * pi * r_tank * (r_tank + h_tank)
            u_tank = (5.678 * tank_ua) / UnitConversions.convert(a_tank, "m^2", "ft^2")
                
            if hpwh_param == 50
                h_UE = (1 - (3.5/12)) * h_tank #in the 4th node of the tank (counting from top)
                h_LE = (1 - (10.5/12)) * h_tank #in the 11th node of the tank (counting from top)
                h_condtop = (1 - (5.5/12)) * h_tank #in the 6th node of the tank (counting from top)
                h_condbot = (1 - (10.99/12)) * h_tank #in the 11th node of the tank
                h_hpctrl = (1 - (2.5/12)) * h_tank #in the 3rd node of the tank
            else
                h_UE = (1 - (3.5/12)) * h_tank #in the 3rd node of the tank (counting from top)
                h_LE = (1 - (9.5/12)) * h_tank #in the 10th node of the tank (counting from top)
                h_condtop = (1 - (5.5/12)) * h_tank #in the 6th node of the tank (counting from top)
                h_condbot = 0.01 #bottom node
                h_hpctrl_up = (1 - (2.5/12)) * h_tank #in the 3rd node of the tank
                h_hpctrl_low = (1 - (8.5/12)) * h_tank #in the 9th node of the tank
            end
            
            #Calculate an altitude adjusted rated evaporator wetbulb temperature
            rated_ewb_F = 56.4
            rated_edb_F = 67.5
            rated_ewb = UnitConversions.convert(rated_ewb_F,"F","C")
            rated_edb = UnitConversions.convert(rated_edb_F,"F","C")
            w_rated = Psychrometrics.w_fT_Twb_P(rated_edb_F,rated_ewb_F,14.7)
            dp_rated = Psychrometrics.Tdp_fP_w(14.7, w_rated)
            p_atm = Psychrometrics.Pstd_fZ(alt)
            w_adj = Psychrometrics.w_fT_Twb_P(dp_rated, dp_rated, p_atm)
            twb_adj = Psychrometrics.Twb_fT_w_P(rated_edb_F, w_adj, p_atm)
            
            #Add in schedules for Tamb, RHamb, and the compressor
            hpwh_tamb = OpenStudio::Model::ScheduleConstant.new(model)
            hpwh_tamb.setName("#{obj_name_hpwh} Tamb act")
            hpwh_tamb.setValue(23)
            
            hpwh_rhamb = OpenStudio::Model::ScheduleConstant.new(model)
            hpwh_rhamb.setName("#{obj_name_hpwh} RHamb act")
            hpwh_rhamb.setValue(0.5)
            
            if ducting == Constants.VentTypeSupply or ducting == Constants.VentTypeBalanced
                hpwh_tamb2 = OpenStudio::Model::ScheduleConstant.new(model)
                hpwh_tamb2.setName("#{obj_name_hpwh} Tamb act2")
                hpwh_tamb2.setValue(23)
            end
            
            tset_C = UnitConversions.convert(t_set,"F","C").to_f.round(2)
            hp_setpoint = OpenStudio::Model::ScheduleConstant.new(model)
            hp_setpoint.setName("#{obj_name_hpwh} WaterHeaterHPSchedule")
            hp_setpoint.setValue(tset_C)
            
            hpwh_bottom_element_sp = OpenStudio::Model::ScheduleConstant.new(model)
            hpwh_bottom_element_sp.setName("#{obj_name_hpwh} BottomElementSetpoint")
            
            hpwh_top_element_sp = OpenStudio::Model::ScheduleConstant.new(model)
            hpwh_top_element_sp.setName("#{obj_name_hpwh} TopElementSetpoint")
            
            if hpwh_param == 50
                hpwh_bottom_element_sp.setValue(tset_C)
                sp = (tset_C-2.89).round(2)
                hpwh_top_element_sp.setValue(sp)
            else
                hpwh_bottom_element_sp.setValue(-60)
                sp = (tset_C-9.0001).round(4)
                hpwh_top_element_sp.setValue(sp)
            end
            
            #WaterHeater:HeatPump:WrappedCondenser
            hpwh = OpenStudio::Model::WaterHeaterHeatPumpWrappedCondenser.new(model)
            hpwh.setName("#{obj_name_hpwh} hpwh")
            hpwh.setCompressorSetpointTemperatureSchedule(hp_setpoint)
            if hpwh_param == 50
                hpwh.setDeadBandTemperatureDifference(0.5)
            else
                hpwh.setDeadBandTemperatureDifference(3.89)
            end
            hpwh.setCondenserBottomLocation(h_condbot)
            hpwh.setCondenserTopLocation(h_condtop)
            hpwh.setEvaporatorAirFlowRate(UnitConversions.convert(airflow_rate,"ft^3/min","m^3/s"))
            hpwh.setInletAirConfiguration("Schedule")
            hpwh.setInletAirTemperatureSchedule(hpwh_tamb)
            hpwh.setInletAirHumiditySchedule(hpwh_rhamb)
            hpwh.setMinimumInletAirTemperatureforCompressorOperation(UnitConversions.convert(min_temp,"F","C"))
            hpwh.setMaximumInletAirTemperatureforCompressorOperation(UnitConversions.convert(max_temp,"F","C"))
            hpwh.setCompressorLocation("Schedule")
            hpwh.setCompressorAmbientTemperatureSchedule(hpwh_tamb)
            hpwh.setFanPlacement("DrawThrough")
            hpwh.setOnCycleParasiticElectricLoad(0)
            hpwh.setOffCycleParasiticElectricLoad(0)
            hpwh.setParasiticHeatRejectionLocation("Outdoors")
            hpwh.setTankElementControlLogic("MutuallyExclusive")
            if hpwh_param == 50
                hpwh.setControlSensor1HeightInStratifiedTank(h_hpctrl)
                hpwh.setControlSensor1Weight(1)
                hpwh.setControlSensor2HeightInStratifiedTank(h_hpctrl)
            else
                hpwh.setControlSensor1HeightInStratifiedTank(h_hpctrl_up)
                hpwh.setControlSensor1Weight(0.75)
                hpwh.setControlSensor2HeightInStratifiedTank(h_hpctrl_low)
            end

            #Curves
            hpwh_cap = OpenStudio::Model::CurveBiquadratic.new(model)
            hpwh_cap.setName("HPWH-Cap-fT")
            hpwh_cap.setCoefficient1Constant(0.563)
            hpwh_cap.setCoefficient2x(0.0437)
            hpwh_cap.setCoefficient3xPOW2(0.000039)
            hpwh_cap.setCoefficient4y(0.0055)
            hpwh_cap.setCoefficient5yPOW2(-0.000148)
            hpwh_cap.setCoefficient6xTIMESY(-0.000145)
            hpwh_cap.setMinimumValueofx(0)
            hpwh_cap.setMaximumValueofx(100)
            hpwh_cap.setMinimumValueofy(0)
            hpwh_cap.setMaximumValueofy(100)  
            
            hpwh_cop = OpenStudio::Model::CurveBiquadratic.new(model)
            hpwh_cop.setName("HPWH-COP-fT")
            hpwh_cop.setCoefficient1Constant(1.1332)
            hpwh_cop.setCoefficient2x(0.063)
            hpwh_cop.setCoefficient3xPOW2(-0.0000979)
            hpwh_cop.setCoefficient4y(-0.00972)
            hpwh_cop.setCoefficient5yPOW2(-0.0000214)
            hpwh_cop.setCoefficient6xTIMESY(-0.000686)
            hpwh_cop.setMinimumValueofx(0)
            hpwh_cop.setMaximumValueofx(100)
            hpwh_cop.setMinimumValueofy(0)
            hpwh_cop.setMaximumValueofy(100)  
            
            #Coil:WaterHeating:AirToWaterHeatPump:Wrapped
            coil = hpwh.dXCoil.to_CoilWaterHeatingAirToWaterHeatPumpWrapped.get
            coil.setName("#{obj_name_hpwh} coil")
            coil.setRatedHeatingCapacity(rated_heat_cap)
            coil.setRatedCOP(cop)
            coil.setRatedSensibleHeatRatio(shr)
            coil.setRatedEvaporatorInletAirDryBulbTemperature(rated_edb)
            coil.setRatedEvaporatorInletAirWetBulbTemperature(UnitConversions.convert(twb_adj,"F","C"))
            coil.setRatedCondenserWaterTemperature(48.89)
            coil.setRatedEvaporatorAirFlowRate(UnitConversions.convert(airflow_rate,"ft^3/min","m^3/s"))
            coil.setEvaporatorFanPowerIncludedinRatedCOP(true)
            coil.setEvaporatorAirTemperatureTypeforCurveObjects("WetBulbTemperature")
            coil.setHeatingCapacityFunctionofTemperatureCurve(hpwh_cap)
            coil.setHeatingCOPFunctionofTemperatureCurve(hpwh_cop)
            coil.setMaximumAmbientTemperatureforCrankcaseHeaterOperation(0)
            
            #WaterHeater:Stratified
            tank = hpwh.tank.to_WaterHeaterStratified.get
            tank.setName("#{obj_name_hpwh} tank")
            tank.setEndUseSubcategory("Domestic Hot Water")
            tank.setTankVolume(UnitConversions.convert(v_actual,"gal","m^3"))
            tank.setTankHeight(h_tank)
            tank.setMaximumTemperatureLimit(90)
            tank.setHeaterPriorityControl("MasterSlave")
            tank.setHeater1SetpointTemperatureSchedule(hpwh_top_element_sp) #Overwritten later by EMS
            tank.setHeater1Capacity(UnitConversions.convert(e_cap,"kW","W"))
            tank.setHeater1Height(h_UE)
            if hpwh_param == 50
                tank.setHeater1DeadbandTemperatureDifference(25)
            else
                tank.setHeater1DeadbandTemperatureDifference(18.5)
            end
            tank.setHeater2SetpointTemperatureSchedule(hpwh_bottom_element_sp)
            tank.setHeater2Capacity(UnitConversions.convert(e_cap,"kW","W"))
            tank.setHeater2Height(h_LE)
            if hpwh_param == 50
                tank.setHeater2DeadbandTemperatureDifference(30)
            else
                tank.setHeater2DeadbandTemperatureDifference(3.89)
            end
            tank.setHeaterFuelType("Electricity")
            tank.setHeaterThermalEfficiency(1)
            tank.setOffCycleParasiticFuelConsumptionRate(parasitics)
            tank.setOffCycleParasiticFuelType("Electricity")
            tank.setOnCycleParasiticFuelConsumptionRate(parasitics)
            tank.setOnCycleParasiticFuelType("Electricity")
            tank.setAmbientTemperatureIndicator("Schedule")
            tank.setUniformSkinLossCoefficientperUnitAreatoAmbientTemperature(u_tank)
            if ducting == Constants.VentTypeSupply or ducting == Constants.VentTypeBalanced
                tank.setAmbientTemperatureSchedule(hpwh_tamb2)
            else
                tank.setAmbientTemperatureSchedule(hpwh_tamb)
            end
            tank.setNumberofNodes(12)
            tank.setAdditionalDestratificationConductivity(0)
            tank.setNode1AdditionalLossCoefficient(0)
            tank.setNode2AdditionalLossCoefficient(0)
            tank.setNode3AdditionalLossCoefficient(0)
            tank.setNode4AdditionalLossCoefficient(0)
            tank.setNode5AdditionalLossCoefficient(0)
            tank.setNode6AdditionalLossCoefficient(0)
            tank.setNode7AdditionalLossCoefficient(0)
            tank.setNode8AdditionalLossCoefficient(0)
            tank.setNode9AdditionalLossCoefficient(0)
            tank.setNode10AdditionalLossCoefficient(0)
            tank.setNode11AdditionalLossCoefficient(0)
            tank.setNode12AdditionalLossCoefficient(0)
            tank.setUseSideDesignFlowRate((UnitConversions.convert(v_actual,"gal","m^3"))/60.1)
            tank.setSourceSideDesignFlowRate(0)
            tank.setSourceSideFlowControlMode("")
            tank.setSourceSideInletHeight(0)
            tank.setSourceSideOutletHeight(0)
            
            #Fan:OnOff
            fan = hpwh.fan.to_FanOnOff.get
            fan.setName("#{obj_name_hpwh} fan")
            if hpwh_param == 50
                fan.setFanEfficiency(23/fan_power * UnitConversions.convert(1,"ft^3/min","m^3/s"))
                fan.setPressureRise(23)
            else
                fan.setFanEfficiency(65/fan_power * UnitConversions.convert(1,"ft^3/min","m^3/s"))
                fan.setPressureRise(65)
            end
            fan.setMaximumFlowRate(UnitConversions.convert(airflow_rate,"ft^3/min","m^3/s"))
            fan.setMotorEfficiency(1.0)
            fan.setMotorInAirstreamFraction(1.0)
            fan.setEndUseSubcategory("Domestic Hot Water")
            
            #Add in EMS program for HPWH interaction with the living space & ambient air temperature depression
            if int_factor != 1 and ducting != "none"
                runner.registerWarning("Interaction factor must be 1 when ducting a HPWH. The input interaction factor value will be ignored and a value of 1 will be used instead.")
                int_factor = 1
            end
            
            #Add in other equipment objects for sensible/latent gains
            hpwh_sens_def = OpenStudio::Model::OtherEquipmentDefinition.new(model)
            hpwh_sens_def.setName("#{obj_name_hpwh} sens")
            hpwh_sens = OpenStudio::Model::OtherEquipment.new(hpwh_sens_def)
            hpwh_sens.setName(hpwh_sens_def.name.to_s)
            hpwh_sens.setSpace(water_heater_space)            
            hpwh_sens_def.setDesignLevel(0)
            hpwh_sens_def.setFractionRadiant(0)
            hpwh_sens_def.setFractionLatent(0)
            hpwh_sens_def.setFractionLost(0)
            hpwh_sens.setSchedule(model.alwaysOnDiscreteSchedule)
            
            hpwh_lat_def = OpenStudio::Model::OtherEquipmentDefinition.new(model)
            hpwh_lat_def.setName("#{obj_name_hpwh} lat")
            hpwh_lat = OpenStudio::Model::OtherEquipment.new(hpwh_lat_def)
            hpwh_lat.setName(hpwh_lat_def.name.to_s)
            hpwh_lat.setSpace(water_heater_space)            
            hpwh_lat_def.setDesignLevel(0)
            hpwh_lat_def.setFractionRadiant(0)
            hpwh_lat_def.setFractionLatent(1)
            hpwh_lat_def.setFractionLost(0)
            hpwh_lat.setSchedule(model.alwaysOnDiscreteSchedule)
            
            #If ducted to outside, get outdoor air T & RH and add a separate actuator for the space temperature for tank losses
            if ducting == Constants.VentTypeSupply or ducting == Constants.VentTypeBalanced

                tout_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, zone_outdoor_air_drybulb_temp_output_var)
                tout_sensor.setName("#{obj_name_hpwh} Tout")
                tout_sensor.setKeyName(unit.living_zone.name.to_s)  
                
                sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, zone_outdoor_air_relative_humidity_output_var)
                sensor.setName("#{obj_name_hpwh} RHout")
                sensor.setKeyName(unit.living_zone.name.to_s)
                
                hpwh_tamb2 = OpenStudio::Model::ScheduleConstant.new(model)
                hpwh_tamb2.setName("#{obj_name_hpwh} Tamb act2")
                hpwh_tamb2.setValue(23)
                
                tamb_act2_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(hpwh_tamb2, "Schedule:Constant", "Schedule Value")
                tamb_act2_actuator.setName("#{obj_name_hpwh} Tamb act2")
            
            end
            
            #EMS Sensors: Space Temperature & RH, HP sens and latent loads, tank losses, fan power
            amb_temp_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, space_temp_output_var)
            amb_temp_sensor.setName("#{obj_name_hpwh} amb temp")
            amb_temp_sensor.setKeyName(water_heater_tz.name.to_s)
            
            amb_rh_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, space_rh_output_var)
            amb_rh_sensor.setName("#{obj_name_hpwh} amb rh")
            amb_rh_sensor.setKeyName(water_heater_tz.name.to_s)
            
            tl_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, wh_tank_losses)
            tl_sensor.setName("#{obj_name_hpwh} tl")
            tl_sensor.setKeyName("#{obj_name_hpwh} tank")
            
            sens_cool_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, hpwh_sensible_cooling)
            sens_cool_sensor.setName("#{obj_name_hpwh} sens cool")
            sens_cool_sensor.setKeyName("#{obj_name_hpwh} coil")
            
            lat_cool_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, hpwh_latent_cooling)
            lat_cool_sensor.setName("#{obj_name_hpwh} lat cool")
            lat_cool_sensor.setKeyName("#{obj_name_hpwh} coil")
            
            fan_power_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, hpwh_fan_power)
            fan_power_sensor.setName("#{obj_name_hpwh} fan pwr")
            fan_power_sensor.setKeyName("#{obj_name_hpwh} fan")
            
            #EMS Actuators: Inlet T & RH, sensible and latent gains to the space
            tamb_act_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(hpwh_tamb,"Schedule:Constant","Schedule Value")
            tamb_act_actuator.setName("#{obj_name_hpwh} Tamb act")
            
            rhamb_act_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(hpwh_rhamb,"Schedule:Constant","Schedule Value")
            rhamb_act_actuator.setName("#{obj_name_hpwh} RHamb act")
            
            sens_act_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(hpwh_sens,"OtherEquipment","Power Level")
            sens_act_actuator.setName("#{hpwh_sens.name} act")
            
            lat_act_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(hpwh_lat,"OtherEquipment","Power Level")
            lat_act_actuator.setName("#{hpwh_lat.name} act")
            
            on_off_trend_var = OpenStudio::Model::EnergyManagementSystemTrendVariable.new(model, "#{obj_name_hpwh} sens cool".gsub(" ","_"))
            on_off_trend_var.setName("#{obj_name_hpwh} on off")
            on_off_trend_var.setNumberOfTimestepsToBeLogged(2)
            
            #Additioanl sensors if supply or exhaust to calculate the load on the space from the HPWH
            if ducting == Constants.VentTypeSupply or ducting == Constants.VentTypeExhaust

                amb_w_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, hpwh_amb_w)
                amb_w_sensor.setName("#{obj_name_hpwh} amb w")
                amb_w_sensor.setKeyName(water_heater_tz)

                sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, hpwh_amb_p)
                sensor.setName("#{obj_name_hpwh} amb p")
                sensor.setKeyName(water_heater_tz)

                sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, hpwh_tair_out)
                sensor.setName("#{obj_name_hpwh} tair out")
                sensor.setKeyName(water_heater_tz)

                sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, hpwh_wair_out)
                sensor.setName("#{obj_name_hpwh} wair out")
                sensor.setKeyName(water_heater_tz)

                sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, hpwh_v_air)
                sensor.setName("#{obj_name_hpwh} v air")
                
            end
            
            temp_depress_c = temp_depress / 1.8 #don't use convert because it's a delta
            timestep_minutes = (60/model.getTimestep.numberOfTimestepsPerHour).to_i
            #EMS Program for ducting
            hpwh_ducting_program = OpenStudio::Model::EnergyManagementSystemProgram.new(model)
            hpwh_ducting_program.setName("#{obj_name_hpwh} InletAir")
            if not (water_heater_tz.name.to_s.start_with?(Constants.FinishedBasementZone) or water_heater_tz.name.to_s.start_with?(Constants.LivingZone))
                runner.registerWarning("Confined space installations are typically used represent installations in locations like a utility closet. Utility closets installations are typically only done in conditioned spaces.")
            end
            if temp_depress_c > 0 and ducting == "none"
                hpwh_ducting_program.addLine("Set HPWH_last_#{unit_num} = (@TrendValue #{on_off_trend_var.name} 1)")
                hpwh_ducting_program.addLine("Set HPWH_now_#{unit_num} = #{on_off_trend_var.name}")
                hpwh_ducting_program.addLine("Set num = (@Ln 2)")
                hpwh_ducting_program.addLine("If (HPWH_last_#{unit_num} == 0) && (HPWH_now_#{unit_num}<>0)") #HPWH just turned on
                hpwh_ducting_program.addLine("Set HPWHOn_#{unit_num} = 0")
                hpwh_ducting_program.addLine("Set exp = -(HPWHOn_#{unit_num} / 9.4) * num")
                hpwh_ducting_program.addLine("Set exponent = (@Exp exp)")
                hpwh_ducting_program.addLine("Set T_dep = (#{temp_depress_c} * exponent) - #{temp_depress_c}")
                hpwh_ducting_program.addLine("Set HPWHOn_#{unit_num} = HPWHOn_#{unit_num} + #{timestep_minutes}")
                hpwh_ducting_program.addLine("ElseIf (HPWH_last_#{unit_num} <> 0) && (HPWH_now_#{unit_num}<>0)") #HPWH has been running for more than 1 timestep
                hpwh_ducting_program.addLine("Set exp = -(HPWHOn_#{unit_num} / 9.4) * num")
                hpwh_ducting_program.addLine("If exp < -20")
                hpwh_ducting_program.addLine("Set exponent = 0")
                hpwh_ducting_program.addLine("Else")
                hpwh_ducting_program.addLine("Set exponent = (@Exp exp)")
                hpwh_ducting_program.addLine("EndIf")
                hpwh_ducting_program.addLine("Set T_dep = (#{temp_depress_c} * exponent) - #{temp_depress_c}")
                hpwh_ducting_program.addLine("Set HPWHOn_#{unit_num} = HPWHOn_#{unit_num} + #{timestep_minutes}")
                hpwh_ducting_program.addLine("Else")
                hpwh_ducting_program.addLine("If (Hour == 0) && (DayOfYear == 1)")
                hpwh_ducting_program.addLine("Set HPWHOn_#{unit_num} = 0") #Assume HPWH starts off for initial conditions
                hpwh_ducting_program.addLine("EndIF")
                hpwh_ducting_program.addLine("Set HPWHOn_#{unit_num} = HPWHOn_#{unit_num} - #{timestep_minutes}")
                hpwh_ducting_program.addLine("If HPWHOn_#{unit_num} < 0")
                hpwh_ducting_program.addLine("Set HPWHOn_#{unit_num} = 0")
                hpwh_ducting_program.addLine("EndIf")
                hpwh_ducting_program.addLine("Set exp = -(HPWHOn_#{unit_num} / 9.4) * num")
                hpwh_ducting_program.addLine("If exp < -20")
                hpwh_ducting_program.addLine("Set exponent = 0")
                hpwh_ducting_program.addLine("Else")
                hpwh_ducting_program.addLine("Set exponent = (@Exp exp)")
                hpwh_ducting_program.addLine("EndIf")
                hpwh_ducting_program.addLine("Set T_dep = (#{temp_depress_c} * exponent) - #{temp_depress_c}")
                hpwh_ducting_program.addLine("EndIf")
                hpwh_ducting_program.addLine("Set T_hpwh_inlet_#{unit_num} = #{amb_temp_sensor.name} + T_dep")
            else
                if ducting == Constants.VentTypeBalanced or ducting == Constants.VentTypeSupply
                    hpwh_ducting_program.addLine("Set T_hpwh_inlet_#{unit_num} = HPWH_out_temp_#{unit_num}")
                else
                    hpwh_ducting_program.addLine("Set T_hpwh_inlet_#{unit_num} = #{amb_temp_sensor.name}")
                end
            end
            if ducting == "none"
                hpwh_ducting_program.addLine("Set #{tamb_act_actuator.name} = T_hpwh_inlet_#{unit_num}")
                hpwh_ducting_program.addLine("Set #{rhamb_act_actuator.name} = #{amb_rh_sensor.name}/100")
                hpwh_ducting_program.addLine("Set temp1=(#{tl_sensor.name}*#{int_factor})+#{fan_power_sensor.name}*#{int_factor}")
                hpwh_ducting_program.addLine("Set #{sens_act_actuator.name} = 0-(#{sens_cool_sensor.name}*#{int_factor})-temp1")
                hpwh_ducting_program.addLine("Set #{lat_act_actuator.name} = 0 - #{lat_cool_sensor.name} * #{int_factor}")
            elsif ducting == Constants.VentTypeBalanced
                hpwh_ducting_program.addLine("Set #{tamb_act_actuator.name} = T_hpwh_inlet_#{unit_num}")
                hpwh_ducting_program.addLine("Set #{tamb_act2_actuator.name} = #{amb_temp_sensor.name}")
                hpwh_ducting_program.addLine("Set #{rhamb_act_actuator.name} = HPWH_out_rh_#{unit_num}/100")
                hpwh_ducting_program.addLine("Set #{sens_act_actuator.name} = 0 - #{tl_sensor.name}")
                hpwh_ducting_program.addLine("Set #{lat_act_actuator.name} = 0")
            elsif ducting == Constants.VentTypeSupply
                hpwh_ducting_program.addLine("Set rho = (@RhoAirFnPbTdbW HPWH_amb_P_#{unit_num} HPWHTair_out_#{unit_num} HPWHWair_out_#{unit_num})")
                hpwh_ducting_program.addLine("Set cp = (@CpAirFnWTdb HPWHWair_out_#{unit_num} HPWHTair_out_#{unit_num})")
                hpwh_ducting_program.addLine("Set h = (@HFnTdbW HPWHTair_out_#{unit_num} HPWHWair_out_#{unit_num})")
                hpwh_ducting_program.addLine("Set HPWH_sens_gain = rho*cp*(HPWHTair_out_#{unit_num}-#{amb_temp_sensor.name})*V_airHPWH_#{unit_num}")
                hpwh_ducting_program.addLine("Set HPWH_lat_gain = h*rho*(HPWHWair_out_#{unit_num}-#{amb_w_sensor.name})*V_airHPWH_#{unit_num}")
                hpwh_ducting_program.addLine("Set #{tamb_act_actuator.name} = T_hpwh_inlet_#{unit_num}")
                hpwh_ducting_program.addLine("Set #{tamb_act2_actuator.name} = #{amb_temp_sensor.name}")
                hpwh_ducting_program.addLine("Set #{rhamb_act_actuator.name} = HPWH_out_rh_#{unit_num}/100")
                hpwh_ducting_program.addLine("Set #{sens_act_actuator.name} = HPWH_sens_gain_#{unit_num} - #{tl_sensor.name}")
                hpwh_ducting_program.addLine("Set #{lat_act_actuator.name} = HPWH_lat_gain_#{unit_num}")
            elsif ducting == Constants.VentTypeExhaust
                hpwh_ducting_program.addLine("Set rho = (@RhoAirFnPbTdbW HPWH_amb_P_#{unit_num} HPWHTair_out_#{unit_num} HPWHWair_out_#{unit_num})")
                hpwh_ducting_program.addLine("Set cp = (@CpAirFnWTdb HPWHWair_out_#{unit_num} HPWHTair_out_#{unit_num})")
                hpwh_ducting_program.addLine("Set h = (@HFnTdbW HPWHTair_out_#{unit_num} HPWHWair_out_#{unit_num})")
                hpwh_ducting_program.addLine("Set HPWH_sens_gain = rho*cp*(#{tout_sensor.name}-#{amb_temp_sensor.name})*V_airHPWH_#{unit_num}")
                hpwh_ducting_program.addLine("Set HPWH_lat_gain = h*rho*(Wout_#{unit_num}-#{amb_w_sensor.name})*V_airHPWH_#{unit_num}")
                hpwh_ducting_program.addLine("Set #{tamb_act_actuator.name} = T_hpwh_inlet_#{unit_num}")
                hpwh_ducting_program.addLine("Set #{rhamb_act_actuator.name} = #{amb_rh_sensor.name}/100")
                hpwh_ducting_program.addLine("Set #{sens_act_actuator.name} = HPWH_sens_gain_#{unit_num} - #{tl_sensor.name}")
                hpwh_ducting_program.addLine("Set #{lat_act_actuator.name} = HPWH_lat_gain_#{unit_num}")
            end
            
            leschedoverride_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(hpwh_bottom_element_sp,"Schedule:Constant", "Schedule Value")
            leschedoverride_actuator.setName("#{obj_name_hpwh} LESchedOverride")
            
            #EMS for the 50 gal HPWH control logic
            if hpwh_param == 80
                
                hpwh_ctrl_program = OpenStudio::Model::EnergyManagementSystemProgram.new(model)
                hpwh_ctrl_program.setName("#{obj_name_hpwh} Control")
                if ducting == Constants.VentTypeSupply or ducting == Constants.VentTypeBalanced
                    hpwh_ctrl_program.addLine("If (HPWH_out_temp_#{unit_num} < #{UnitConversions.convert(min_temp,"F","C")}) || (HPWH_out_temp_#{unit_num} > #{UnitConversions.convert(max_temp,"F","C")})")
                else
                    hpwh_ctrl_program.addLine("If (#{amb_temp_sensor.name}<#{UnitConversions.convert(min_temp,"F","C").round(2)}) || (#{amb_temp_sensor.name}>#{UnitConversions.convert(max_temp,"F","C").round(2)})")
                end
                hpwh_ctrl_program.addLine("Set #{leschedoverride_actuator.name} = #{tset_C}")
                hpwh_ctrl_program.addLine("Else")
                hpwh_ctrl_program.addLine("Set #{leschedoverride_actuator.name} = 0")
                hpwh_ctrl_program.addLine("EndIf")
                
            else #hpwh_param == 50

                t_ctrl_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, t_ctrl)
                t_ctrl_sensor.setName("#{obj_name_hpwh} T ctrl")
                t_ctrl_sensor.setKeyName("#{obj_name_hpwh} tank")
                
                le_p_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, le_p)
                le_p_sensor.setName("#{obj_name_hpwh} LE P")
                le_p_sensor.setKeyName("#{obj_name_hpwh} tank")
                
                ue_p_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, ue_p)
                ue_p_sensor.setName("#{obj_name_hpwh} UE P")
                ue_p_sensor.setKeyName("#{obj_name_hpwh} tank")
                
                hpschedoverride_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(hp_setpoint,"Schedule:Constant", "Schedule Value")
                hpschedoverride_actuator.setName("#{obj_name_hpwh} HPSchedOverride")
                
                ueschedoverride_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(hpwh_top_element_sp,"Schedule:Constant", "Schedule Value")
                ueschedoverride_actuator.setName("#{obj_name_hpwh} UESchedOverride")

                uetrend_trend_var = OpenStudio::Model::EnergyManagementSystemTrendVariable.new(model, ue_p_sensor.name.to_s)
                uetrend_trend_var.setName("#{obj_name_hpwh} UETrend")
                uetrend_trend_var.setNumberOfTimestepsToBeLogged(2)
                
                letrend_trend_var = OpenStudio::Model::EnergyManagementSystemTrendVariable.new(model, le_p_sensor.name.to_s)
                letrend_trend_var.setName("#{obj_name_hpwh} LETrend")
                letrend_trend_var.setNumberOfTimestepsToBeLogged(2)
                
                ueschedoverridetemp = (tset_C - 1.89).round(2)
                t_ems_control1 = (tset_C - 11.29).round(2)
                t_ems_control2 = (tset_C - 0.39).round(2)
                
                hpwh_ctrl_program = OpenStudio::Model::EnergyManagementSystemProgram.new(model)
                hpwh_ctrl_program.setName("#{obj_name_hpwh} Control")
                hpwh_ctrl_program.addLine("Set #{ueschedoverride_actuator.name} = #{ueschedoverridetemp}")
                hpwh_ctrl_program.addLine("Set #{hpschedoverride_actuator.name} = #{tset_C}")
                hpwh_ctrl_program.addLine("Set UEMax_#{unit_num} = (@TrendMax #{uetrend_trend_var.name} 2)")
                hpwh_ctrl_program.addLine("Set LEMax_#{unit_num} = (@TrendMax #{letrend_trend_var.name} 2)")
                hpwh_ctrl_program.addLine("Set ElemOn_#{unit_num} = (@Max UEMax_#{unit_num} LEMax_#{unit_num})")
                hpwh_ctrl_program.addLine("If (#{t_ctrl_sensor.name}<#{t_ems_control1}) || ((ElemOn_#{unit_num}>0) && (#{t_ctrl_sensor.name}<#{t_ems_control2}))") #Small offset in second value is to prevent the element overshooting the setpoint due to mixing
                hpwh_ctrl_program.addLine("Set #{leschedoverride_actuator.name} = 70")
                hpwh_ctrl_program.addLine("Set #{hpschedoverride_actuator.name} = 0")
                hpwh_ctrl_program.addLine("Else")
                hpwh_ctrl_program.addLine("Set #{leschedoverride_actuator.name} = 0")
                hpwh_ctrl_program.addLine("Set #{hpschedoverride_actuator.name} = #{tset_C}")
                hpwh_ctrl_program.addLine("EndIf")
                
            end
            
            #ProgramCallingManagers
            program_calling_manager = OpenStudio::Model::EnergyManagementSystemProgramCallingManager.new(model)
            program_calling_manager.setName("#{obj_name_hpwh} ProgramManager")
            program_calling_manager.setCallingPoint("InsideHVACSystemIterationLoop")
            program_calling_manager.addProgram(hpwh_ctrl_program)
            program_calling_manager.addProgram(hpwh_ducting_program)
            
            storage_tank = Waterheater.get_shw_storage_tank(model, unit)
        
            if storage_tank.nil?
              loop.addSupplyBranchForComponent(tank)
            else
              storage_tank.setHeater1SetpointTemperatureSchedule(tank.heater1SetpointTemperatureSchedule)
              storage_tank.setHeater2SetpointTemperatureSchedule(tank.heater2SetpointTemperatureSchedule)            
              tank.addToNode(storage_tank.supplyOutletModelObject.get.to_Node.get)
            end
            
        end
        
        rated_heat_cap_kW = UnitConversions.convert(rated_heat_cap,"W","kW") 
        runner.registerFinalCondition("A new  #{vol.round} gallon heat pump water heater, with a rated COP of #{cop} and a nominal heat pump capacity of #{rated_heat_cap_kW.round(2)} kW has been added to the model")
        
        return true
 
    end #end the run method

    private
    
    def validate_storage_tank_volume(vol, runner)
        vol = vol.to_f
        if vol <= 0.0
            runner.registerError("Storage tank volume must be greater than 0.")   
            return nil
        end
        if vol < 20.0
            runner.registerWarning("Tank volume seems low, double check inputs.")
        elsif vol > 120.0
            runner.registerWarning("Tank volume seems high, double check inputs.")
        end
        return true
    end
  
    def validate_setpoint_temperature(t_set, runner)
        if (t_set <= 0.0 or t_set >= 212.0)
            runner.registerError("Hot water temperature must be greater than 0 and less than 212.")
            return nil
        end
        if t_set < 100.0
            runner.registerInfo("Setpoint temperature seems low, which could lead to bacteria growth in the tank. Double check inputs.")
        elsif t_set > 140.0
            runner.registerWarning("Setpoint temperature seems high, which may present a scalding risk. Double check inputs.")
        end
        return true
    end

    def validate_element_capacity(e_cap, runner)
        if e_cap < 0.0
            runner.registerError("Element capacity must be greater than 0.")
            return nil
        end
        if e_cap == 0.0
            runner.registerWarning("Element capacity of 0 wil disable the electric elements in the tank, double check inputs.")
        elsif e_cap < 2.0
            runner.registerWarning("Element capacity seems low, double check inputs.")
        elsif e_cap > 10.0
            runner.registerWarning("Element capacity seems high, double check inputs.")
        end
        return true
    end
    
    def validate_min_temp(min_temp, runner)
        if min_temp >= 80.0
            runner.registerError("Minimum temperature will prevent HPWH from running, double check inputs.")
            return nil
        end
        if min_temp <= -30.0
            runner.registerWarning("Minimum temperature seems low, double check inputs.")
        elsif min_temp >= 50.0
            runner.registerWarning("Minimum temperature seems high, double check inputs.")
        end
        return true
    end
    
    def validate_max_temp(max_temp, runner)
        if max_temp <= 0.0
            runner.registerError("Maximum temperature will prevent HPWH from running, double check inputs.")
            return nil
        end
        if max_temp <= 100.0
            runner.registerWarning("Maximum temperature seems low, double check inputs.")
        elsif max_temp >= 140.0
            runner.registerWarning("Maximum temperature seems high, double check inputs.")
        end
        return true
    end
    
    def validate_cap(cap, runner)
        if cap <= 0.0
            runner.registerError("Rated capacity must be greater than 0.")
            return nil
        end
        if cap <= 0.2
            runner.registerWarning("Rated capacity seems low, double check inputs.")
        elsif cap >= 4.0
            runner.registerWarning("Rated capacity seems high, double check inputs")
        end
        return true
    end
    
    def validate_cop(cop, runner)
        if cop <= 0.0
            runner.registerError("Rated COP must be greater than 0.")
            return nil
        end
        if cop <= 1.0
            runner.registerWarning("Rated COP seems low, double check inputs.")
        elsif cop >= 6.0
            runner.registerWarning("Rated COP seems high, double check inputs.")
        end
        return true
    end
    
    def validate_shr(shr, runner)
        if (shr < 0.0 or shr > 1.0)
            runner.registerError("Rated sensible heat ratio must be between 0 and 1.")
            return nil
        end
        if shr <= 0.7
            runner.registerWarning("Rated sensible heat ratio seems low, double check inputs.")
        end
        return true
    end
    
    def validate_airflow_rate(airflow_rate, runner)
        if airflow_rate <= 0.0
            runner.registerError("Airflow rate must be greater than 0.")
            return nil
        end
        if airflow_rate <= 50.0
            runner.registerWarning("Airflow rate seems low, double check inputs.")
        elsif airflow_rate >= 1000.0
            runner.registerWarning("Airflow rate seems high, double check inputs.")
        end
        return true
    end
    
    def validate_fan_power(fan_power, runner)
        if fan_power <= 0.0
            runner.registerError("Fan power must be greater than 0.")
            return nil
        end
        if fan_power > 1.0
            runner.registerWarning("Fan power seems high, double check inputs.")
        end
        return true
    end
    
	def validate_parasitics(parasitics, runner)
        if parasitics < 0.0
            runner.registerError("Parasitics must be greater than 0.")
            return nil
        end
        if parasitics > 20.0
            runner.registerWarning("Parasitics seem high, double check inputs.")
        end
        return true
    end
    
    def validate_tank_ua(tank_ua, runner)
        if tank_ua <= 0.0
            runner.registerError("Tank UA must be greater than 0.")
            return nil
        end
        if tank_ua <= 1.0
            runner.registerWarning("Tank UA seems low, double check inputs.")
        elsif tank_ua > 10.0
            runner.registerWarning("Tank UA seems high, double check inputs.")
        end
        return true
    end
    
    def validate_int_factor(int_factor, runner)
        if (int_factor < 0.0 or int_factor > 1.0)
            runner.registerError("Interaction factor must be between 0 and 1.")
            return nil
        end
        return true
    end
    
    def validate_temp_depress(temp_depress, runner)
        if temp_depress < 0.0 
            runner.registerError("Temperature depression must be greater than 0.")
            return nil
        end
        if temp_depress > 15.0
            runner.registerWarning("Temperature depression seems large, double check inputs.")
        end
        return true
    end
  
end #end the measure

#this allows the measure to be use by the application
ResidentialHotWaterHeaterHeatPump.new.registerWithApplication
