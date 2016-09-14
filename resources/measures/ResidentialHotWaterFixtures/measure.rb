require "#{File.dirname(__FILE__)}/resources/schedules"
require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/weather"
require "#{File.dirname(__FILE__)}/resources/unit_conversions"
require "#{File.dirname(__FILE__)}/resources/geometry"
require "#{File.dirname(__FILE__)}/resources/waterheater"


#start the measure
class ResidentialShowersSinksBaths < OpenStudio::Ruleset::ModelUserScript
    OSM = OpenStudio::Model
            
    #define the name that a user will see, this method may be deprecated as
    #the display name in PAT comes from the name field in measure.xml
    def name
        return "Set Residential Hot Water Fixtures"
    end

    def description
        return "Adds water use due to showers, sinks, and baths into the home. This water use also results in internal gains due to the hot water use. The total hot water use and space gains are modified by the DHW distribution measure if it is also run. Hot water is assumed to be used at 110 F for these end uses."
    end
      
    def modeler_description
        return "Creates three new WaterUse:Equipment objects to represent showers, sinks, and baths in a home. OtherEquipment objects are also added to take into account the heat gain in the space due to hot water use."
    end

    def arguments(model)
        ruleset = OpenStudio::Ruleset
        osargument = ruleset::OSArgument

        args = ruleset::OSArgumentVector.new
            
        #Shower hot water use multiplier
        shower_mult = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("shower_mult",true)
        shower_mult.setDisplayName("Multiplier on shower hot water use")
        shower_mult.setDescription("Multiplier on Building America HSP shower hot water consumption. HSP perscribes shower hot water consumption of 14 + 4.67 * n_bedrooms gal/day at 110 F.")
        shower_mult.setDefaultValue(1.0)
        args << shower_mult
        
        #Sink hot water use multiplier
        sink_mult = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("sink_mult",true)
        sink_mult.setDisplayName("Multiplier on sink hot water use")
        sink_mult.setDescription("Multiplier on Building America HSP sink hot water consumption. HSP perscribes sink hot water consumption of 12.5 + 4.16 * n_bedrooms gal/day at 110 F.")
        sink_mult.setDefaultValue(1.0)
        args << sink_mult
            
        #Bath hot water use multiplier
        bath_mult = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("bath_mult",true)
        bath_mult.setDisplayName("Multiplier on bath hot water use")
        bath_mult.setDescription("Multiplier on Building America HSP bath hot water consumption. HSP perscribes bath hot water consumption of 3.5 + 1.17 * n_bedrooms gal/day at 110 F.")
        bath_mult.setDefaultValue(1.0)
        args << bath_mult

        #make a choice argument for plant loop
        plant_loops = model.getPlantLoops
        plant_loop_args = OpenStudio::StringVector.new
        plant_loops.each do |plant_loop|
            plant_loop_args << plant_loop.name.to_s
        end
        if plant_loop_args.empty?
            plant_loop_args << Constants.PlantLoopDomesticWater
        end
        plant_loop = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("plant_loop", plant_loop_args, true)
        plant_loop.setDisplayName("Plant Loop")
        plant_loop.setDescription("Select the plant loop for the clothes washer")
        if plant_loop_args.include?(Constants.PlantLoopDomesticWater)
            plant_loop.setDefaultValue(Constants.PlantLoopDomesticWater)
        end
        args << plant_loop

		#make a choice argument for space
        spaces = model.getSpaces
        space_args = OpenStudio::StringVector.new
        spaces.each do |space|
            space_args << space.name.to_s
        end
        if space_args.empty?
            space_args << Constants.LivingSpace(1)
        end
        space = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("space", space_args, true)
        space.setDisplayName("Location")
        space.setDescription("Select the space where the dishwasher is located")
        if space_args.include?(Constants.LivingSpace(1))
            space.setDefaultValue(Constants.LivingSpace(1))
        end
        args << space

		return args
	end #end the arguments method

	#define what happens when the measure is run
	def run(model, runner, user_arguments)
		super(model, runner, user_arguments)

		#use the built-in error checking 
		if not runner.validateUserArguments(arguments(model), user_arguments)
			return false
		end

		#assign the user inputs to variables
        sh_mult = runner.getDoubleArgumentValue("shower_mult",user_arguments)
        s_mult = runner.getDoubleArgumentValue("sink_mult", user_arguments)
        b_mult = runner.getDoubleArgumentValue("bath_mult", user_arguments)
        ssb_loc = runner.getStringArgumentValue("space",user_arguments)
        plant_loop_s = runner.getStringArgumentValue("plant_loop", user_arguments)
        
        #Check for valid and reasonable inputs
        if sh_mult < 0
            runner.registerError("Shower hot water usage multiplier must be greater than 0")
            return false
        end
        
        if sh_mult < 0.1
            runner.registerWarning("Shower hot water usage multiplier seems very low, double check input")
            return false
        end
        
        if sh_mult > 10
            runner.registerWarning("Shower hot water usage multiplier seems very high, double check input")
            return false
        end
        
        if s_mult < 0
            runner.registerError("Sink hot water usage multiplier must be greater than 0")
            return false
        end
        
        if s_mult < 0.1
            runner.registerWarning("Sink hot water usage multiplier seems very low, double check input")
            return false
        end
        
        if s_mult > 10
            runner.registerWarning("Sink hot water usage multiplier seems very high, double check input")
            return false
        end
        
        if b_mult < 0
            runner.registerError("Bath hot water usage multiplier must be greater than 0")
            return false
        end
        
        if b_mult < 0.1
            runner.registerWarning("Bath hot water usage multiplier seems very low, double check input")
            return false
        end
        
        if b_mult > 10
            runner.registerWarning("Bath hot water usage multiplier seems very high, double check input")
            return false
        end
        
        #Get space
        space = Geometry.get_space_from_string(model.getSpaces, ssb_loc, runner)
        if space.nil?
            return false
        end

        #Get plant loop
        plant_loop = Waterheater.get_plant_loop_from_string(model.getPlantLoops, plant_loop_s, model.getSpaces, runner)
        if plant_loop.nil?
            return false
        end
        
        # Get number of bedrooms/bathrooms
        nbeds, nbaths, unit_spaces = Geometry.get_unit_beds_baths_spaces(model, 1, runner)
        if nbeds.nil? or nbaths.nil?
            runner.registerError("Could not determine number of bedrooms or bathrooms. Run the 'Add Residential Bedrooms And Bathrooms' measure first.")
            return false
        end
        
        #Create a constant mixed use temperature schedule at 110 F
        mixed_use_t = 110 #F
        
        #Calc daily gpm and annual gain of each end use
        sh_gpd = (14.0 + 4.67 * nbeds) * sh_mult
        s_gpd = (12.5 + 4.16 * nbeds) * s_mult
        b_gpd = (3.5 + 1.17 * nbeds) * b_mult
        sh_name = Constants.ObjectNameShower
        s_name = Constants.ObjectNameSink
        b_name = Constants.ObjectNameBath
        
        #Get schedules for each end use
        sh_sch = HotWaterSchedule.new(model, runner, sh_name + " schedule", sh_name + " temperature schedule", nbeds, 1, "Shower", mixed_use_t, File.dirname(__FILE__))
        s_sch = HotWaterSchedule.new(model, runner, s_name + " schedule",  s_name + " temperature schedule", nbeds, 1, "Sink", mixed_use_t, File.dirname(__FILE__))
        b_sch = HotWaterSchedule.new(model, runner, b_name + " schedule",  b_name + " temperature schedule", nbeds, 1, "Bath", mixed_use_t, File.dirname(__FILE__))
        if not sh_sch.validated? or not s_sch.validated? or not b_sch.validated?
            return false
        end
        
        sh_peak_flow = sh_sch.calcPeakFlowFromDailygpm(sh_gpd)
        s_peak_flow = s_sch.calcPeakFlowFromDailygpm(s_gpd)  
        b_peak_flow = b_sch.calcPeakFlowFromDailygpm(b_gpd)  
        
        #Add water use equipment objects
        sh_wu_def = OpenStudio::Model::WaterUseEquipmentDefinition.new(model)
        sh_wu = OpenStudio::Model::WaterUseEquipment.new(sh_wu_def)
        sh_wu.setName(sh_name)
        sh_wu.setSpace(space)
        sh_wu_def.setName(sh_name)
        sh_wu_def.setPeakFlowRate(sh_peak_flow)
        sh_wu_def.setEndUseSubcategory("Domestic Hot Water")
        sh_sch.setWaterSchedule(sh_wu)
        
        s_wu_def = OpenStudio::Model::WaterUseEquipmentDefinition.new(model)
        s_wu = OpenStudio::Model::WaterUseEquipment.new(s_wu_def)
        s_wu.setName(s_name)
        s_wu.setSpace(space)
        s_wu_def.setName(s_name)
        s_wu_def.setPeakFlowRate(s_peak_flow)
        s_wu_def.setEndUseSubcategory("Domestic Hot Water")
        s_sch.setWaterSchedule(s_wu)
        
        b_wu_def = OpenStudio::Model::WaterUseEquipmentDefinition.new(model)
        b_wu = OpenStudio::Model::WaterUseEquipment.new(b_wu_def)
        b_wu.setName(b_name)
        b_wu.setSpace(space)
        b_wu_def.setName(b_name)
        b_wu_def.setPeakFlowRate(b_peak_flow)
        b_wu_def.setEndUseSubcategory("Domestic Hot Water")
        b_sch.setWaterSchedule(b_wu)
        
        #Reuse existing water use connection if possible
        equip_added = false
        plant_loop.demandComponents.each do |component|
            next unless component.to_WaterUseConnections.is_initialized
            connection = component.to_WaterUseConnections.get
            connection.addWaterUseEquipment(sh_wu)
            connection.addWaterUseEquipment(s_wu)
            connection.addWaterUseEquipment(b_wu)
            runner.registerInfo("Shower, sink, and bath end uses were added to an existing WaterUseConnection object")
            equip_added = true
            break
        end
        #
        #plant_loop.demandComponents.each do |component|
        #    if component.to_WaterUseConnections.is_initialized
        #        connection = component.to_WaterUseConnections.get
        #        connection.addWaterUseEquipment(sh_wu)
        #        connection.addWaterUseEquipment(s_wu)
        #        connection.addWaterUseEquipment(b_wu)
        #        runner.registerInfo("Shower, sink, and bath end uses were added to an existing WaterUseConnection object")
        #        equip_added = true
        #    end
        #end
        if not equip_added
            #Need new water heater connection
            connection = OpenStudio::Model::WaterUseConnections.new(model)
            connection.addWaterUseEquipment(sh_wu)
            connection.addWaterUseEquipment(s_wu)
            connection.addWaterUseEquipment(b_wu)
            plant_loop.addDemandBranchForComponent(connection)
            runner.registerInfo("Shower, sink, and bath end uses were added to a new WaterUseConnection object")
        end
        
        #Add OtherEquipment objects for the heat gains from hot water use
        sh_sens_load = (741 + 247 * nbeds) * sh_mult # Btu/day
        sh_lat_load = (703 + 235 * nbeds) * sh_mult # Btu/day
        sh_tot_load = OpenStudio.convert(sh_sens_load + sh_lat_load, "Btu", "kWh").get #kWh/day
        sh_lat = sh_lat_load / (sh_lat_load + sh_sens_load)
        sh_design_level = sh_sch.calcDesignLevelFromDailykWh(sh_tot_load)
        
        s_sens_load = (310 + 103 * nbeds) * s_mult # Btu/day
        s_lat_load = (140 + 47 * nbeds) * s_mult # Btu/day
        s_tot_load = OpenStudio.convert(s_sens_load + s_lat_load, "Btu", "kWh").get #kWh/day
        s_lat = s_lat_load / (s_lat_load + s_sens_load)
        s_design_level = s_sch.calcDesignLevelFromDailykWh(s_tot_load)
        
        b_sens_load = (185 + 62 * nbeds) * b_mult # Btu/day
        b_lat_load = 0 # Btu/day
        b_tot_load = OpenStudio.convert(b_sens_load + b_lat_load, "Btu", "kWh").get #kWh/day
        b_lat = b_lat_load / (b_lat_load + b_sens_load)
        b_design_level = b_sch.calcDesignLevelFromDailykWh(b_tot_load)

        # Remove any existing ssb
        ssb_removed = false
        space.otherEquipment.each do |space_equipment|
            if space_equipment.name.to_s == sh_name or space_equipment.name.to_s == s_name or space_equipment.name.to_s == b_name
                space_equipment.remove
                ssb_removed = true
            end
        end
        if ssb_removed
            runner.registerInfo("Removed existing showers, sinks, and baths.")
        end
    
        #Add other equipment for the shower, sink, and bath
        sh_oe_def = OpenStudio::Model::OtherEquipmentDefinition.new(model)
        sh_oe = OpenStudio::Model::OtherEquipment.new(sh_oe_def)
        sh_oe.setName(sh_name)
        sh_oe.setSpace(space)
        sh_oe_def.setName(sh_name)
        sh_oe_def.setDesignLevel(sh_design_level)
        sh_oe_def.setFractionRadiant(0)
        sh_oe_def.setFractionLatent(sh_lat)
        sh_oe_def.setFractionLost(0)
        sh_sch.setSchedule(sh_oe)
        
        s_oe_def = OpenStudio::Model::OtherEquipmentDefinition.new(model)
        s_oe = OpenStudio::Model::OtherEquipment.new(s_oe_def)
        s_oe.setName(s_name)
        s_oe.setSpace(space)
        s_oe_def.setName(s_name)
        s_oe_def.setDesignLevel(s_design_level)
        s_oe_def.setFractionRadiant(0)
        s_oe_def.setFractionLatent(s_lat)
        s_oe_def.setFractionLost(0)
        s_sch.setSchedule(s_oe)
        
        b_oe_def = OpenStudio::Model::OtherEquipmentDefinition.new(model)
        b_oe = OpenStudio::Model::OtherEquipment.new(b_oe_def)
        b_oe.setName(b_name)
        b_oe.setSpace(space)
        b_oe_def.setName(b_name)
        b_oe_def.setDesignLevel(b_design_level)
        b_oe_def.setFractionRadiant(0)
        b_oe_def.setFractionLatent(b_lat)
        b_oe_def.setFractionLost(0)
        b_sch.setSchedule(b_oe)
        
        #reporting final condition of model
        runner.registerFinalCondition("Showers, sinks and bath hot water end uses, drawing #{sh_gpd.round(1)} , #{s_gpd.round(1)} gal/day, and #{b_gpd.round(1)} gal/day respectively, have been added to plant loop #{plant_loop_s} and their associated space gains have been added to space #{space.name}.")
	
        return true
    end
end #end the measure

#this allows the measure to be use by the application
ResidentialShowersSinksBaths.new.registerWithApplication
