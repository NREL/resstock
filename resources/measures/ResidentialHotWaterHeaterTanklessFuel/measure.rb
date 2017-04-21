# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/measures/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/waterheater"
require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"

#start the measure
class ResidentialHotWaterHeaterTanklessFuel < OpenStudio::Measure::ModelMeasure

    #define the name that a user will see, this method may be deprecated as
    #the display name in PAT comes from the name field in measure.xml
    def name
        return "Set Residential Fuel Tankless Water Heater"
    end
  
    def description
        return "This measure adds a new residential fuel tankless water heater to the model based on user inputs. If there is already an existing residential water heater in the model, it is replaced. For multifamily buildings, the water heater can be set for all units of the building."
    end
  
    def modeler_description
        return "The measure will create a new instance of the OS:WaterHeater:Mixed object representing a fuel tankless water heater. The water heater will be placed on the plant loop 'Domestic Hot Water Loop'. If this loop already exists, any water heater on that loop will be removed and replaced with a water heater consistent with this measure. If it doesn't exist, it will be created."
    end

    #define the arguments that the user will input
    def arguments(model)
        ruleset = OpenStudio::Measure
    
        osargument = ruleset::OSArgument
    
        args = ruleset::OSArgumentVector.new

        #make a string argument for furnace fuel type
        fuel_display_names = OpenStudio::StringVector.new
        fuel_display_names << Constants.FuelTypeGas
        fuel_display_names << Constants.FuelTypePropane
        fueltype = OpenStudio::Measure::OSArgument::makeChoiceArgument("fuel_type", fuel_display_names, true)
        fueltype.setDisplayName("Fuel Type")
        fueltype.setDescription("Type of fuel used for water heating.")
        fueltype.setDefaultValue(Constants.FuelTypeGas)
        args << fueltype

        # make an argument for hot water setpoint temperature
        dhw_setpoint = osargument::makeDoubleArgument("setpoint_temp", true)
        dhw_setpoint.setDisplayName("Setpoint")
        dhw_setpoint.setDescription("Water heater setpoint temperature.")
        dhw_setpoint.setUnits("F")
        dhw_setpoint.setDefaultValue(125)
        args << dhw_setpoint
	
        # make an argument for water_heater_location
        thermal_zones = model.getThermalZones
        thermal_zone_names = thermal_zones.select { |tz| not tz.name.empty?}.collect{|tz| tz.name.get }
        thermal_zone_names << Constants.Auto
        water_heater_location = osargument::makeChoiceArgument("location",thermal_zone_names, true)
        water_heater_location.setDefaultValue(Constants.Auto)
        water_heater_location.setDisplayName("Location")
        water_heater_location.setDescription("Thermal zone where the water heater is located. #{Constants.Auto} will locate the water heater according the BA House Simulation Protocols: A garage (if available) or the living space in hot-dry and hot-humid climates, a basement (finished or unfinished, if available) or living space in all other climates.")
	
        args << water_heater_location

        # make an argument for water_heater_capacity
        water_heater_capacity = osargument::makeDoubleArgument("capacity", true)
        water_heater_capacity.setDisplayName("Input Capacity")
        water_heater_capacity.setDescription("The maximum energy input rating of the water heater.")
        water_heater_capacity.setUnits("kBtu/hr")
        water_heater_capacity.setDefaultValue(100000000.0)
        args << water_heater_capacity

        # make an argument for the rated energy factor
        rated_energy_factor = osargument::makeDoubleArgument("energy_factor", true)
        rated_energy_factor.setDisplayName("Rated Energy Factor")
        rated_energy_factor.setDescription("For water heaters, Energy Factor is the ratio of useful energy output from the water heater to the total amount of energy delivered from the water heater. The higher the EF is, the more efficient the water heater. Procedures to test the EF of water heaters are defined by the Department of Energy in 10 Code of Federal Regulation Part 430, Appendix E to Subpart B.")
        rated_energy_factor.setDefaultValue(0.82)
        args << rated_energy_factor

        # make an argument for cycling_derate
        cycling_derate = osargument::makeDoubleArgument("cycling_derate", true)
        cycling_derate.setDisplayName("Cycling Derate")
        cycling_derate.setDescription("Annual energy derate for cycling inefficiencies -- accounts for the impact of thermal cycling and small hot water draws on the heat exchanger. CEC's 2008 Title24 implemented an 8% derate for tankless water heaters. ")
        cycling_derate.setUnits("Frac")
        cycling_derate.setDefaultValue(0.08)
        args << cycling_derate
	
        # make an argument on cycle electricity consumption
        offcyc_power = osargument::makeDoubleArgument("offcyc_power", true)
        offcyc_power.setDisplayName("Parasitic Electric Power")
        offcyc_power.setDescription("Off cycle electric power draw for controls, etc.")
        offcyc_power.setUnits("W")
        offcyc_power.setDefaultValue(5.0)
        args << offcyc_power
	
        # make an argument on cycle electricity consumption
        oncyc_power = osargument::makeDoubleArgument("oncyc_power", true)
        oncyc_power.setDisplayName("Forced Draft Fan Power")
        oncyc_power.setDescription("On cycle electric power draw from the forced draft fan motor.")
        oncyc_power.setUnits("W")
        oncyc_power.setDefaultValue(65.0)
        args << oncyc_power
    
        return args
    end #end the arguments method

    #define what happens when the measure is run
    def run(model, runner, user_arguments)
        super(model, runner, user_arguments)

	
        #Assign user inputs to variables
        fuel_type = runner.getStringArgumentValue("fuel_type",user_arguments)
        cap = runner.getDoubleArgumentValue("capacity",user_arguments)
        ef = runner.getDoubleArgumentValue("energy_factor",user_arguments)
        cd = runner.getDoubleArgumentValue("cycling_derate",user_arguments)
        water_heater_loc = runner.getStringArgumentValue("location",user_arguments)
        t_set = runner.getDoubleArgumentValue("setpoint_temp",user_arguments).to_f
        oncycle_p = runner.getDoubleArgumentValue("oncyc_power",user_arguments)
        offcycle_p = runner.getDoubleArgumentValue("offcyc_power",user_arguments)
        
        #Validate inputs
        if not runner.validateUserArguments(arguments(model), user_arguments)
            return false
        end
	
        # Validate inputs further
        valid_ef = validate_rated_energy_factor(ef, runner)
        if valid_ef.nil?
            return false
        end
        valid_t_set = validate_setpoint_temperature(t_set, runner)
        if valid_t_set.nil?
            return false
        end
        valid_cap = validate_water_heater_capacity(cap, runner)
        if valid_cap.nil?
            return false
        end
        valid_cd = validate_water_heater_cycling_derate(cd, runner)
        if valid_cd.nil?
            return false
        end
        valid_epar = validate_parasitic_elec(oncycle_p, offcycle_p, runner)
	    if valid_epar.nil?
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
        
        units.each do |unit|
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
            if water_heater_loc == Constants.Auto
                water_heater_tz = Waterheater.get_water_heater_location_auto(model, unit.spaces, runner)
                if water_heater_tz.nil?
                    runner.registerError("The water heater cannot be automatically assigned to a thermal zone. Please manually select which zone the water heater should be located in.")
                    return false
                end
            else
                unit_zones = Geometry.get_thermal_zones_from_spaces(unit.spaces)
                water_heater_tz = Geometry.get_thermal_zone_from_string(unit_zones, water_heater_loc.to_s)
                next if water_heater_tz.nil?
            end

            #Check if a DHW plant loop already exists, if not add it
            loop = nil
        
            model.getPlantLoops.each do |pl|
                next if pl.name.to_s != Constants.PlantLoopDomesticWater(unit.name.to_s)
                loop = pl
                #Remove any existing water heater
                objects_to_remove = []
                pl.supplyComponents.each do |wh|
                    next if !wh.to_WaterHeaterMixed.is_initialized and !wh.to_WaterHeaterStratified.is_initialized and !wh.to_WaterHeaterHeatPump.is_initialized
                    objects_to_remove << wh
                    if wh.to_WaterHeaterMixed.is_initialized
                        wh = wh.to_WaterHeaterMixed.get
                    elsif wh.to_WaterHeaterStratified.is_initialized
                        wh = wh.to_WaterHeaterStratified.get
                    elsif wh.to_WaterHeaterHeatPump.is_initialized
                        wh = wh.to_WaterHeaterHeatPump.get
                    end
                    if wh.setpointTemperatureSchedule.is_initialized
                        objects_to_remove << wh.setpointTemperatureSchedule.get
                    end
                end
                if objects_to_remove.size > 0
                    runner.registerInfo("Removed existing water heater from plant loop #{pl.name.to_s}.")
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
                runner.registerInitialCondition("No water heater model currently exists")
                loop = Waterheater.create_new_loop(model, Constants.PlantLoopDomesticWater(unit.name.to_s), t_set, "tankless")
            end

            if loop.components(OpenStudio::Model::PumpVariableSpeed::iddObjectType).empty?
                new_pump = Waterheater.create_new_pump(model)
                new_pump.addToNode(loop.supplyInletNode)
            end

            if loop.supplyOutletNode.setpointManagers.empty?
                new_manager = Waterheater.create_new_schedule_manager(t_set, model, "tank")
                new_manager.addToNode(loop.supplyOutletNode)
            end
        
            new_heater = Waterheater.create_new_heater(sch_unit_index, Constants.ObjectNameWaterHeater(unit.name.to_s), cap, fuel_type, 1, nbeds, nbaths, ef, 0, t_set, water_heater_tz, oncycle_p, offcycle_p, Constants.WaterHeaterTypeTankless, cd, File.dirname(__FILE__), model, runner)
        
            loop.addSupplyBranchForComponent(new_heater)
            
        end
            
        register_final_conditions(runner, model)
  
        return true
 
    end #end the run method

    private

    def register_final_conditions(runner, model)
        final_condition = list_water_heaters(model, runner).join("\n")
        runner.registerFinalCondition(final_condition)
    end    

    def list_water_heaters(model, runner)
        water_heaters = []

        existing_heaters = model.getWaterHeaterMixeds
        for heater in existing_heaters do
            heatername = heater.name.get
            loopname = heater.plantLoop.get.name.get

            capacity_si = heater.getHeaterMaximumCapacity.get
            capacity = OpenStudio.convert(capacity_si.value, capacity_si.units.standardString, "kBtu/hr").get
            volume_si = heater.getTankVolume.get
            volume = OpenStudio.convert(volume_si.value, volume_si.units.standardString, "gal").get
            te = heater.getHeaterThermalEfficiency.get.value
          
            water_heaters << "Water heater '#{heatername}' added to plant loop '#{loopname}', with a capacity of #{capacity.round(1)} kBtu/hr" +
            " and a burner efficiency of  #{te.round(2)}."
        end
        water_heaters
    end

    def validate_rated_energy_factor(ef, runner)
        if (ef >= 1 or ef <= 0)
            runner.registerError("Rated energy factor must be greater than 0 and less than 1.")
            return nil
        end
        return true
    end
  
    def validate_setpoint_temperature(t_set, runner)
        if (t_set <= 0 or t_set >= 212)
            runner.registerError("Hot water temperature must be greater than 0 and less than 212.")
            return nil
        end
        return true
    end

    def validate_water_heater_capacity(cap, runner)
        if cap <= 0
            runner.registerError("Nominal capacity must be greater than 0.")
            return nil
        end
        return true
    end
    
    def validate_water_heater_cycling_derate(cd, runner)
        if (cd < 0 or cd > 1)
            runner.registerError("Cycling derate must be at least 0 and at most 1.")
            return nil
        end
        return true
    end
  
    def validate_parasitic_elec(oncycle_p, offcycle_p, runner)
        if oncycle_p < 0
            runner.registerError("Forced draft fan power must be greater than 0.")
            return nil
        end
        if offcycle_p < 0
            runner.registerError("Parasitic electricity power must be greater than 0.")
            return nil
        end
        return true
    end
  
  
end #end the measure

#this allows the measure to be use by the application
ResidentialHotWaterHeaterTanklessFuel.new.registerWithApplication
