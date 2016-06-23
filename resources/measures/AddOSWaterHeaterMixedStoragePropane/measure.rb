# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/measures/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/waterheater"
require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"

#start the measure
class AddOSWaterHeaterMixedStoragePropane < OpenStudio::Ruleset::ModelUserScript

    #define the name that a user will see, this method may be deprecated as
    #the display name in PAT comes from the name field in measure.xml
    def name
        return "Set Residential Propane Tank Water Heater"
    end
  
    def description
        return "This measure adds a new residential propane storage water heater to the model based on user inputs. If there is already an existing residential water heater in the model, it is replaced."
    end
  
    def modeler_description
        return "The measure will create a new instance of the OS:WaterHeater:Mixed object representing a propane storage water heater. The measure will be placed on the plant loop 'Domestic Hot Water Loop'. If this loop already exists, any water heater on that loop will be removed and replaced with a water heater consistent with this measure. If it doesn't exist, it will be created."
    end

    OS = OpenStudio
    OSM = OS::Model
  
    #define the arguments that the user will input
    def arguments(model)
        ruleset = OpenStudio::Ruleset
    
        osargument = ruleset::OSArgument
    
        args = ruleset::OSArgumentVector.new

        # make an argument for the storage tank volume
        storage_tank_volume = osargument::makeStringArgument("storage_tank_volume", true)
        storage_tank_volume.setDisplayName("Tank Volume")
        storage_tank_volume.setDescription("Nominal volume of the of the water heater tank. Set to #{Constants.Auto} to have volume autosized.")
        storage_tank_volume.setUnits("gal")
        storage_tank_volume.setDefaultValue(Constants.Auto)
        args << storage_tank_volume

        # make an argument for hot water setpoint temperature
        dhw_setpoint = osargument::makeDoubleArgument("dhw_setpoint_temperature", true)
        dhw_setpoint.setDisplayName("Setpoint")
        dhw_setpoint.setDescription("Water heater setpoint temperature.")
        dhw_setpoint.setUnits("F")
        dhw_setpoint.setDefaultValue(125)
        args << dhw_setpoint
	
        # make an argument for water_heater_location
        thermal_zones = model.getThermalZones
        thermal_zone_names = thermal_zones.select { |tz| not tz.name.empty?}.collect{|tz| tz.name.get }
        thermal_zone_names << Constants.Auto
        water_heater_location = osargument::makeChoiceArgument("water_heater_location",thermal_zone_names, true)
        water_heater_location.setDefaultValue(Constants.Auto)
        water_heater_location.setDisplayName("Location")
        water_heater_location.setDescription("Thermal zone where the water heater is located. #{Constants.Auto} will locate the water heater according the BA House Simulation Protocols: A garage (if available) or the living space in hot-dry and hot-humid climates, a basement (finished or unfinished, if available) or living space in all other climates.")
	
        args << water_heater_location

        # make an argument for water_heater_capacity
        water_heater_capacity = osargument::makeStringArgument("water_heater_capacity", true)
        water_heater_capacity.setDisplayName("Input Capacity")
        water_heater_capacity.setDescription("The maximum energy input rating of the water heater. Set to #{Constants.Auto} to have this field autosized.")
        water_heater_capacity.setUnits("kBtu/hr")
        water_heater_capacity.setDefaultValue("40.0")
        args << water_heater_capacity

        # make an argument for the rated energy factor
        rated_energy_factor = osargument::makeStringArgument("rated_energy_factor", true)
        rated_energy_factor.setDisplayName("Rated Energy Factor")
        rated_energy_factor.setDescription("For water heaters, Energy Factor is the ratio of useful energy output from the water heater to the total amount of energy delivered from the water heater. The higher the EF is, the more efficient the water heater. Procedures to test the EF of water heaters are defined by the Department of Energy in 10 Code of Federal Regulation Part 430, Appendix E to Subpart B. Enter #{Constants.Auto} for a water heater that meets the minimum federal efficiency requirements.")
        rated_energy_factor.setDefaultValue("0.59")
        args << rated_energy_factor

        # make an argument for water_heater_recovery_efficiency
        water_heater_recovery_efficiency = osargument::makeDoubleArgument("water_heater_recovery_efficiency", true)
        water_heater_recovery_efficiency.setDisplayName("Recovery Efficiency")
        water_heater_recovery_efficiency.setDescription("For water heaters, the recovery efficiency is the ratio of energy delivered to the water to the energy content of the fuel consumed by the water heater. Test procedures to test recovery efficiency are defined by the Department of Energy in 10 Code of Federal Regulations Part 430, Appendix E to Subpart B. This information can often be found in the AHRI Certification Directory or on the EnergyStar website.")
        water_heater_recovery_efficiency.setUnits("Frac")
        water_heater_recovery_efficiency.setDefaultValue(0.76)
        args << water_heater_recovery_efficiency
	
        # make an argument on cycle electricity consumption
        offcyc_power = osargument::makeDoubleArgument("offcyc_power", true)
        offcyc_power.setDisplayName("Parasitic Electric Power")
        offcyc_power.setDescription("Off cycle electric power draw for controls, etc.")
        offcyc_power.setUnits("W")
        offcyc_power.setDefaultValue(0)
        args << offcyc_power
	
        # make an argument on cycle electricity consumption
        oncyc_power = osargument::makeDoubleArgument("oncyc_power", true)
        oncyc_power.setDisplayName("Forced Draft Fan Power")
        oncyc_power.setDescription("On cycle electric power draw from the forced draft fan motor.")
        oncyc_power.setUnits("W")
        oncyc_power.setDefaultValue(0)
        args << oncyc_power
    
        return args
    end #end the arguments method

    #define what happens when the measure is run
    def run(model, runner, user_arguments)
        super(model, runner, user_arguments)

	
        #Assign user inputs to variables
        cap = runner.getStringArgumentValue("water_heater_capacity",user_arguments)
        vol = runner.getStringArgumentValue("storage_tank_volume",user_arguments)
        ef = runner.getStringArgumentValue("rated_energy_factor",user_arguments)
        re = runner.getDoubleArgumentValue("water_heater_recovery_efficiency",user_arguments)
        water_heater_tz = runner.getStringArgumentValue("water_heater_location",user_arguments)
        t_set = runner.getDoubleArgumentValue("dhw_setpoint_temperature",user_arguments).to_f
        oncycle_p = runner.getDoubleArgumentValue("oncyc_power",user_arguments)
        offcycle_p = runner.getDoubleArgumentValue("offcyc_power",user_arguments)
	
        #Validate inputs
        if not runner.validateUserArguments(arguments(model), user_arguments)
            return false
        end
	
        # Validate inputs further
        valid_vol = validate_storage_tank_volume(vol, runner)
        if valid_vol.nil?
            return false
        end
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
        valid_re = validate_water_heater_recovery_efficiency(re, runner)
        if valid_re.nil?
            return false
        end
        valid_epar = validate_parasitic_elec(oncycle_p, offcycle_p, runner)
	    if valid_epar.nil?
            return false
        end
        
        #If location is Auto, get the location
        if water_heater_tz == Constants.Auto
            water_heater_tz = Waterheater.get_water_heater_location_auto(model, runner)
            if water_heater_tz.nil?
                runner.registerError("The water heater cannot be automatically assigned to a thermal zone. Please manually select which zone the water heater should be located in.")
                return false
            else
                runner.registerInfo("Water heater is located in #{water_heater_tz} thermal zone")
            end
        end
    
        
        # Get number of bedrooms/bathrooms
        nbeds, nbaths = Geometry.get_bedrooms_bathrooms(model, runner)
        if nbeds.nil? or nbaths.nil?
            return false
        end
        
        #Check if mains temperature has been set
        t_mains = model.getSiteWaterMainsTemperature
        if t_mains.calculationMethod.nil?
            runner.registerError("Mains water temperature must be set before adding a water heater")
            return false
        end
	
        #Check if a DHW plant loop already exists, if not add it
        loop = nil
	
        model.getPlantLoops.each do |pl|
            if pl.name.to_s == Constants.PlantLoopDomesticWater
                runner.registerInfo("A propane water heater will be added to the existing DHW plant loop")
                loop = HelperMethods.get_plant_loop_from_string(model, Constants.PlantLoopDomesticWater, runner)
                if loop.nil?
                    return false
                end
                #Remove the existing water heater
                pl.supplyComponents.each do |wh|
                    if wh.to_WaterHeaterMixed.is_initialized
                        waterHeater = wh.to_WaterHeaterMixed.get
                        waterHeater.remove
                        runner.registerInitialCondition("The existing mixed water heater has been removed and will be replaced with the new user specified water heater")
                    elsif wh.to_WaterHeaterStratified.is_initialized
                        waterHeater = wh.to_WaterHeaterStratified.get
                        waterHeater.remove
                        runner.registerInitialCondition("The existing stratified water heater has been removed and will be replaced with the new user specified water heater")
                    end
                end
            end
        end

        if loop.nil?
            runner.registerInfo("A new plant loop for DHW will be added to the model")
            runner.registerInitialCondition("No water heater model currently exists")
            loop = Waterheater.create_new_loop(model)
        end

        if loop.components(OSM::PumpConstantSpeed::iddObjectType).empty?
            new_pump = Waterheater.create_new_pump(model)
            new_pump.addToNode(loop.supplyInletNode)
        end

        if loop.supplyOutletNode.setpointManagers.empty?
            new_manager = create_new_schedule_manager(t_set, model)
            new_manager.addToNode(loop.supplyOutletNode)
        end
	
			
        new_heater = Waterheater.create_new_heater(cap, Constants.FuelTypePropane, vol, nbeds, nbaths, ef, re, t_set, water_heater_tz, oncycle_p, offcycle_p, Constants.WaterHeaterTypeTank, 0, model, runner)
	
        loop.addSupplyBranchForComponent(new_heater)
        
        register_final_conditions(runner, model)
  
        return true
 
    end #end the run method

    private

    def create_new_schedule_manager(t_set, model)
        new_schedule = Waterheater.create_new_schedule_ruleset("DHW Temp", "DHW Temp Default", t_set, model)
        OSM::SetpointManagerScheduled.new(model, new_schedule)
    end 

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
            te = heater.getHeaterThermalEfficiency
          
            water_heaters << "Water heater '#{heatername}' added to plant loop '#{loopname}', with a capacity of #{capacity.round(1)} kBtu/hr" +
            " and an actual tank volume of #{volume.round(1)} gal."
        end
        water_heaters
    end

    
    def validate_storage_tank_volume(vol, runner)
        return true if (vol == Constants.Auto)  # flag for autosizing
        vol = vol.to_f

        if vol <= 0
            runner.registerError("Storage tank volume must be greater than 0 gallons. Make sure that the volume entered is a number > 0 or #{Constants.Auto}.")   
            return nil
        end
        if vol < 25
            runner.registerWarning("A storage tank volume of less than 25 gallons and a certified rating is not commercially available. Please review the input.")
        end     
        if vol > 120
            runner.registerWarning("A water heater with a storage tank volume of greater than 120 gallons and a certified rating is not commercially available. Please review the input.")
        end    
        return true
    end

    def validate_rated_energy_factor(ef, runner)
        return true if (ef == Constants.Auto)  # flag for autosizing
        ef = ef.to_f

        if (ef >= 1)
            runner.registerError("Rated energy factor has a maximum value of 1.0 for propane water heaters.")
            return nil
        end
        if (ef <= 0)
            runner.registerError("Rated energy factor must be greater than 0. Make sure that the entered value is a number > 0 or #{Constants.Auto}.")
            return nil
        end
        if (ef >0.82)
            runner.registerWarning("Rated energy factor for commercially available propane storage water heaters should be less than 0.82")
        end    
        if (ef <0.48)
            runner.registerWarning("Rated energy factor for commercially available propane storage water heaters should be greater than 0.48")
        end    
        return true
    end
  
    def validate_setpoint_temperature(t_set, runner)
        if (t_set <= 0)
            runner.registerError("Hot water temperature must be greater than 0.")
            return nil
        end
        if (t_set >= 212)
            runner.registerError("Hot water temperature must be less than the boiling point of water.")
            return nil
        end
        if (t_set > 140)
            runner.registerWarning("Hot water setpoint schedule DHW_Temp has values greater than 140F. This temperature, if achieved, may cause scalding.")
        end    
        if (t_set < 120)
            runner.registerWarning("Hot water setpoint schedule DHW_Temp has values less than 120F. This temperature may promote the growth of Legionellae or other bacteria.")               
        end    
        return true
    end

    def validate_water_heater_capacity(cap, runner)
        return true if cap == Constants.Auto # Autosized
        cap = cap.to_f

        if cap <= 0
            runner.registerError("Propane storage water heater nominal capacity must be greater than 0 kBtu/hr. Make sure that the entered capacity is a number greater than 0 or #{Constants.Auto}.")
            return nil
        end
        if cap < 25
            runner.registerWarning("Commercially available residential propane storage water heaters should have a minimum nominal capacity of 25 kBtu/h.")
        end
        if cap > 75
            runner.registerWarning("Commercially available residential propane storage water heaters should have a maximum nominal capacity of 75 kBtu/h.")
        end
        return true
    end
    
    def validate_water_heater_recovery_efficiency(re, runner)
        if (re < 0)
            runner.registerError("Propane storage water heater recovery efficiency must be at least 0 and at most 1.")
            return nil
        end
        if (re > 1)
            runner.registerError("Propane storage water heater recovery efficiency must be at least 0 and at most 1.")
            return nil
        end
        if (re < 0.70)
            runner.registerWarning("Commercially available propane storage water heaters should have a minimum rated recovery efficiency of 0.70.")
        end
        if (re > 0.90)
            runner.registerWarning("Commercially available propane storage water heaters should have a maximum rated recovery efficiency of 0.90.")
        end
        return true
    end
  
    def validate_parasitic_elec(oncycle_p, offcycle_p, runner)
        if oncycle_p < 0
            runner.registerError("Forced draft fan power must be greater than 0")
            return nil
        end
        if offcycle_p < 0
            runner.registerError("Parasitic electricity power must be greater than 0")
            return nil
        end
        if oncycle_p > 100
            runner.registerWarning("Forced draft power consumption is larger than typically seen for residential water heaters, double check inputs")
        end
        if offcycle_p > 30
            runner.registerWarning("Parasitic power consumption is larger than typically seen for residential water heaters, double check inputs")
        end
        return true
    end
  
  
end #end the measure

#this allows the measure to be use by the application
AddOSWaterHeaterMixedStoragePropane.new.registerWithApplication
