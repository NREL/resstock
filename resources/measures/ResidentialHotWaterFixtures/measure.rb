require "#{File.dirname(__FILE__)}/resources/schedules"
require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/weather"
require "#{File.dirname(__FILE__)}/resources/unit_conversions"
require "#{File.dirname(__FILE__)}/resources/geometry"
require "#{File.dirname(__FILE__)}/resources/waterheater"


#start the measure
class ResidentialHotWaterFixtures < OpenStudio::Ruleset::ModelUserScript
    OSM = OpenStudio::Model
            
    #define the name that a user will see, this method may be deprecated as
    #the display name in PAT comes from the name field in measure.xml
    def name
        return "Set Residential Hot Water Fixtures"
    end

    def description
        return "Adds (or replaces) residential hot water fixtures -- showers, sinks, and baths. For multifamily buildings, the hot water fixtures can be set for all units of the building."
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
        shower_mult.setDescription("Multiplier on Building America HSP shower hot water consumption. HSP prescribes shower hot water consumption of 14 + 4.67 * n_bedrooms gal/day at 110 F.")
        shower_mult.setDefaultValue(1.0)
        args << shower_mult
        
        #Sink hot water use multiplier
        sink_mult = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("sink_mult",true)
        sink_mult.setDisplayName("Multiplier on sink hot water use")
        sink_mult.setDescription("Multiplier on Building America HSP sink hot water consumption. HSP prescribes sink hot water consumption of 12.5 + 4.16 * n_bedrooms gal/day at 110 F.")
        sink_mult.setDefaultValue(1.0)
        args << sink_mult
            
        #Bath hot water use multiplier
        bath_mult = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("bath_mult",true)
        bath_mult.setDisplayName("Multiplier on bath hot water use")
        bath_mult.setDescription("Multiplier on Building America HSP bath hot water consumption. HSP prescribes bath hot water consumption of 3.5 + 1.17 * n_bedrooms gal/day at 110 F.")
        bath_mult.setDefaultValue(1.0)
        args << bath_mult
        
        #make a choice argument for space
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
        space.setDescription("Select the space where the hot water fixtures are located. '#{Constants.Auto}' will choose the lowest above-grade finished space available (e.g., first story living space), or a below-grade finished space as last resort. For multifamily buildings, '#{Constants.Auto}' will choose a space for each unit of the building.")
        space.setDefaultValue(Constants.Auto)
        args << space

        #make a choice argument for plant loop
        plant_loops = model.getPlantLoops
        plant_loop_args = OpenStudio::StringVector.new
        plant_loop_args << Constants.Auto
        plant_loops.each do |plant_loop|
            plant_loop_args << plant_loop.name.to_s
        end
        plant_loop = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("plant_loop", plant_loop_args, true)
        plant_loop.setDisplayName("Plant Loop")
        plant_loop.setDescription("Select the plant loop for the hot water fixtures. '#{Constants.Auto}' will try to choose the plant loop associated with the specified space. For multifamily buildings, '#{Constants.Auto}' will choose the plant loop for each unit of the building.")
        plant_loop.setDefaultValue(Constants.Auto)
        args << plant_loop

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
        space_r = runner.getStringArgumentValue("space",user_arguments)
        plant_loop_s = runner.getStringArgumentValue("plant_loop", user_arguments)
        
        #Check for valid and reasonable inputs
        if sh_mult < 0
            runner.registerError("Shower hot water usage multiplier must be greater than or equal to 0.")
            return false
        end
        if s_mult < 0
            runner.registerError("Sink hot water usage multiplier must be greater than or equal to 0.")
            return false
        end
        if b_mult < 0
            runner.registerError("Bath hot water usage multiplier must be greater than or equal to 0.")
            return false
        end
        
        # Get number of units
        num_units = Geometry.get_num_units(model, runner)
        if num_units.nil?
            return false
        end

        tot_sh_gpd = 0
        tot_s_gpd = 0
        tot_b_gpd = 0
        info_msgs = []
        sch_sh = nil
        sch_s = nil
        sch_b = nil
        (1..num_units).to_a.each do |unit_num|
        
            # Get unit beds/baths/spaces
            nbeds, nbaths, unit_spaces = Geometry.get_unit_beds_baths_spaces(model, unit_num, runner)
            if unit_spaces.nil?
                runner.registerError("Could not determine the spaces associated with unit #{unit_num}.")
                return false
            end
            if nbeds.nil? or nbaths.nil?
                runner.registerError("Could not determine number of bedrooms or bathrooms. Run the 'Add Residential Bedrooms And Bathrooms' measure first.")
                return false
            end

            # Get space
            space = Geometry.get_space_from_string(unit_spaces, space_r)
            next if space.nil?

            #Get plant loop
            plant_loop = Waterheater.get_plant_loop_from_string(model.getPlantLoops, plant_loop_s, unit_spaces, runner)
            if plant_loop.nil?
                return false
            end

            obj_name_sh = Constants.ObjectNameShower(unit_num)
            obj_name_s = Constants.ObjectNameSink(unit_num)
            obj_name_b = Constants.ObjectNameBath(unit_num)
        
            # Remove any existing ssb
            ssb_removed = false
            space.otherEquipment.each do |space_equipment|
                if space_equipment.name.to_s == obj_name_sh or space_equipment.name.to_s == obj_name_s or space_equipment.name.to_s == obj_name_b
                    space_equipment.remove
                    ssb_removed = true
                end
            end
            space.waterUseEquipment.each do |space_equipment|
                if space_equipment.name.to_s == obj_name_sh or space_equipment.name.to_s == obj_name_s or space_equipment.name.to_s == obj_name_b
                    space_equipment.remove
                    ssb_removed = true
                end
            end
            if ssb_removed
                runner.registerInfo("Removed existing showers, sinks, and baths from space #{space.name.to_s}.")
            end
        
            #Create a constant mixed use temperature schedule at 110 F
            mixed_use_t = 110 #F
            
            #Calc daily gpm and annual gain of each end use
            sh_gpd = (14.0 + 4.67 * nbeds) * sh_mult
            s_gpd = (12.5 + 4.16 * nbeds) * s_mult
            b_gpd = (3.5 + 1.17 * nbeds) * b_mult
            
            # Shower internal gains
            sh_sens_load = (741 + 247 * nbeds) * sh_mult # Btu/day
            sh_lat_load = (703 + 235 * nbeds) * sh_mult # Btu/day
            sh_tot_load = OpenStudio.convert(sh_sens_load + sh_lat_load, "Btu", "kWh").get #kWh/day
            sh_lat = sh_lat_load / (sh_lat_load + sh_sens_load)

            # Sink internal gains
            s_sens_load = (310 + 103 * nbeds) * s_mult # Btu/day
            s_lat_load = (140 + 47 * nbeds) * s_mult # Btu/day
            s_tot_load = OpenStudio.convert(s_sens_load + s_lat_load, "Btu", "kWh").get #kWh/day
            s_lat = s_lat_load / (s_lat_load + s_sens_load)
        
            # Bath internal gains
            b_sens_load = (185 + 62 * nbeds) * b_mult # Btu/day
            b_lat_load = 0 # Btu/day
            b_tot_load = OpenStudio.convert(b_sens_load + b_lat_load, "Btu", "kWh").get #kWh/day
            b_lat = b_lat_load / (b_lat_load + b_sens_load)
            
            if sh_gpd > 0 or s_gpd > 0 or b_gpd > 0
            
                #Reuse existing water use connection if possible
                water_use_connection = nil
                plant_loop.demandComponents.each do |component|
                    next unless component.to_WaterUseConnections.is_initialized
                    water_use_connection = component.to_WaterUseConnections.get
                    break
                end
                if water_use_connection.nil?
                    #Need new water heater connection
                    water_use_connection = OpenStudio::Model::WaterUseConnections.new(model)
                    plant_loop.addDemandBranchForComponent(water_use_connection)
                end
                
            end
            
            # Showers
            if sh_gpd > 0
                
                if sch_sh.nil?
                    # Create schedule
                    sch_sh = HotWaterSchedule.new(model, runner, Constants.ObjectNameShower + " schedule", Constants.ObjectNameShower + " temperature schedule", nbeds, unit_num, "Shower", mixed_use_t, File.dirname(__FILE__))
                    if not sch_sh.validated?
                        return false
                    end
                end
            
                sh_peak_flow = sch_sh.calcPeakFlowFromDailygpm(sh_gpd)
                sh_design_level = sch_sh.calcDesignLevelFromDailykWh(sh_tot_load)
                
                #Add water use equipment objects
                sh_wu_def = OpenStudio::Model::WaterUseEquipmentDefinition.new(model)
                sh_wu = OpenStudio::Model::WaterUseEquipment.new(sh_wu_def)
                sh_wu.setName(obj_name_sh)
                sh_wu.setSpace(space)
                sh_wu_def.setName(obj_name_sh)
                sh_wu_def.setPeakFlowRate(sh_peak_flow)
                sh_wu_def.setEndUseSubcategory("Domestic Hot Water")
                sch_sh.setWaterSchedule(sh_wu)
                water_use_connection.addWaterUseEquipment(sh_wu)
                
                #Add other equipment
                sh_oe_def = OpenStudio::Model::OtherEquipmentDefinition.new(model)
                sh_oe = OpenStudio::Model::OtherEquipment.new(sh_oe_def)
                sh_oe.setName(obj_name_sh)
                sh_oe.setSpace(space)
                sh_oe_def.setName(obj_name_sh)
                sh_oe_def.setDesignLevel(sh_design_level)
                sh_oe_def.setFractionRadiant(0)
                sh_oe_def.setFractionLatent(sh_lat)
                sh_oe_def.setFractionLost(0)
                sch_sh.setSchedule(sh_oe)
                
                tot_sh_gpd += sh_gpd
            end
            
            # Sinks
            if s_gpd > 0
            
                if sch_s.nil?
                    # Create schedule
                    sch_s = HotWaterSchedule.new(model, runner, Constants.ObjectNameSink + " schedule", Constants.ObjectNameSink + " temperature schedule", nbeds, unit_num, "Sink", mixed_use_t, File.dirname(__FILE__))
                    if not sch_s.validated?
                        return false
                    end
                end
            
                s_peak_flow = sch_s.calcPeakFlowFromDailygpm(s_gpd)  
                s_design_level = sch_s.calcDesignLevelFromDailykWh(s_tot_load)
                
                #Add water use equipment objects
                s_wu_def = OpenStudio::Model::WaterUseEquipmentDefinition.new(model)
                s_wu = OpenStudio::Model::WaterUseEquipment.new(s_wu_def)
                s_wu.setName(obj_name_s)
                s_wu.setSpace(space)
                s_wu_def.setName(obj_name_s)
                s_wu_def.setPeakFlowRate(s_peak_flow)
                s_wu_def.setEndUseSubcategory("Domestic Hot Water")
                sch_s.setWaterSchedule(s_wu)
                water_use_connection.addWaterUseEquipment(s_wu)
                
                #Add other equipment
                s_oe_def = OpenStudio::Model::OtherEquipmentDefinition.new(model)
                s_oe = OpenStudio::Model::OtherEquipment.new(s_oe_def)
                s_oe.setName(obj_name_s)
                s_oe.setSpace(space)
                s_oe_def.setName(obj_name_s)
                s_oe_def.setDesignLevel(s_design_level)
                s_oe_def.setFractionRadiant(0)
                s_oe_def.setFractionLatent(s_lat)
                s_oe_def.setFractionLost(0)
                sch_s.setSchedule(s_oe)
                
                tot_s_gpd += s_gpd
            end
            
            # Baths
            if b_gpd > 0
            
                if sch_b.nil?
                    # Create schedule
                    sch_b = HotWaterSchedule.new(model, runner, Constants.ObjectNameSink + " schedule", Constants.ObjectNameSink + " temperature schedule", nbeds, unit_num, "Bath", mixed_use_t, File.dirname(__FILE__))
                    if not sch_b.validated?
                        return false
                    end
                end
            
                b_peak_flow = sch_b.calcPeakFlowFromDailygpm(b_gpd)
                b_design_level = sch_b.calcDesignLevelFromDailykWh(b_tot_load)
                
                #Add water use equipment objects
                b_wu_def = OpenStudio::Model::WaterUseEquipmentDefinition.new(model)
                b_wu = OpenStudio::Model::WaterUseEquipment.new(b_wu_def)
                b_wu.setName(obj_name_b)
                b_wu.setSpace(space)
                b_wu_def.setName(obj_name_b)
                b_wu_def.setPeakFlowRate(b_peak_flow)
                b_wu_def.setEndUseSubcategory("Domestic Hot Water")
                sch_b.setWaterSchedule(b_wu)
                water_use_connection.addWaterUseEquipment(b_wu)
                
                #Add other equipment
                b_oe_def = OpenStudio::Model::OtherEquipmentDefinition.new(model)
                b_oe = OpenStudio::Model::OtherEquipment.new(b_oe_def)
                b_oe.setName(obj_name_b)
                b_oe.setSpace(space)
                b_oe_def.setName(obj_name_b)
                b_oe_def.setDesignLevel(b_design_level)
                b_oe_def.setFractionRadiant(0)
                b_oe_def.setFractionLatent(b_lat)
                b_oe_def.setFractionLost(0)
                sch_b.setSchedule(b_oe)
                
                tot_b_gpd += b_gpd
            end
            
            if sh_gpd > 0 or s_gpd > 0 or b_gpd > 0
                info_msgs << "Shower, sinks, and bath fixtures drawing #{sh_gpd.round(1)}, #{s_gpd.round(1)}, and #{b_gpd.round(1)} gal/day respectively have been added to plant loop '#{plant_loop.name}' and assigned to space '#{space.name.to_s}'."
            end
            
        end
        
        # Reporting
        if info_msgs.size > 1
            info_msgs.each do |info_msg|
                runner.registerInfo(info_msg)
            end
            runner.registerFinalCondition("The building has been assigned shower, sink, and bath fixtures drawing a total of #{(tot_sh_gpd + tot_s_gpd + tot_b_gpd).round(1)} gal/day across #{num_units} units.")
        elsif info_msgs.size == 1
            runner.registerFinalCondition(info_msgs[0])
        else
            runner.registerFinalCondition("No shower, sink, or bath fixtures have been assigned.")
        end
	
        return true
        
    end
end #end the measure

#this allows the measure to be use by the application
ResidentialHotWaterFixtures.new.registerWithApplication
