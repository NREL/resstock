require "#{File.dirname(__FILE__)}/resources/schedules"
require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/weather"
require "#{File.dirname(__FILE__)}/resources/unit_conversions"
require "#{File.dirname(__FILE__)}/resources/geometry"
require "#{File.dirname(__FILE__)}/resources/waterheater"

#start the measure
class ResidentialHotWaterDistribution < OpenStudio::Ruleset::ModelUserScript
    OSM = OpenStudio::Model
            
    #define the name that a user will see, this method may be deprecated as
    #the display name in PAT comes from the name field in measure.xml
    def name
        return "Set Residential Hot Water Distribution"
    end

    def description
        return "Adds a hot water distribution system, including pipes and any recirculation pumps, into the home. This measure must be run after showers, sinks, and baths have been added to the home."
    end
      
    def modeler_description
        return "Modifies the existing HotWater:Equipment Objects for showers, sinks, and baths to take into account the additional water drawn due to distribution system inefficiencies. Also adds an internal gain to the space due to heat loss from the pipes and an ElectricEquipment object for the pump if recirculation is included."
    end

    def arguments(model)
        ruleset = OpenStudio::Ruleset
        osargument = ruleset::OSArgument

        args = ruleset::OSArgumentVector.new
            
        #Distribution pipe material
        pipe_mat_display_name = OpenStudio::StringVector.new
        pipe_mat_display_name << Constants.MaterialCopper
        pipe_mat_display_name << Constants.MaterialPEX
        pipe_mat = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("pipe_mat", pipe_mat_display_name, true)
        pipe_mat.setDisplayName("Pipe Material")
        pipe_mat.setDescription("The plumbing material.")
        pipe_mat.setDefaultValue(Constants.MaterialCopper)
        args << pipe_mat
        
        #Distribution system layout
        dist_layout_display_name = OpenStudio::StringVector.new
        dist_layout_display_name << Constants.PipeTypeHomeRun
        dist_layout_display_name << Constants.PipeTypeTrunkBranch
        dist_layout = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("dist_layout", dist_layout_display_name, true)
        dist_layout.setDisplayName("Distribution system layout")
        dist_layout.setDescription("The plumbing layout of the hot water distribution system. Trunk and branch uses a main trunk line to supply various branch take-offs to specific fixtures. In the home run layout, all fixtures are fed from dedicated piping that runs directly from central manifolds.")
        dist_layout.setDefaultValue(Constants.PipeTypeTrunkBranch)
        args << dist_layout
        
        #make a choice argument for space
        space_display_name = OpenStudio::StringVector.new
        space_display_name << Constants.LocationInterior
        space_display_name << Constants.LocationExterior
        space = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("space", space_display_name, true)
        space.setDescription("Select the primary space where the DHW distribution system is located.")
        space.setDefaultValue(Constants.LocationInterior)
        args << space
        
        #Recirculation Type
        recirc_type_display_name = OpenStudio::StringVector.new
        recirc_type_display_name << Constants.RecircTypeNone
        recirc_type_display_name << Constants.RecircTypeTimer
        recirc_type_display_name << Constants.RecircTypeDemand
        recirc_type = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("recirc_type", recirc_type_display_name, true)
        recirc_type.setDisplayName("Recirculation Type")
        recirc_type.setDescription("The type of hot water recirculation control, if any. Timer recirculation control assumes 16 hours of daily pump operation from 6am to 10pm. Demand recirculation controls assume push button control at all non-appliance fistures with 100% ideal control.")
        recirc_type.setDefaultValue(Constants.RecircTypeNone)
        args << recirc_type
                    
        #Insulation
        dist_ins = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("dist_ins",true)
        dist_ins.setDisplayName("Insulation Nominal R-Value")
        dist_ins.setUnits("h-ft^2-R/Btu")
        dist_ins.setDescription("Nominal R-value of the insulation on the DHW distribution system.")
        dist_ins.setDefaultValue(0.0)
        args << dist_ins

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
        pipe_mat = runner.getStringArgumentValue("pipe_mat", user_arguments)
        dist_layout = runner.getStringArgumentValue("dist_layout", user_arguments)
        dist_ins = runner.getDoubleArgumentValue("dist_ins", user_arguments)
        recirc_type = runner.getStringArgumentValue("recirc_type", user_arguments)
        dist_loc = runner.getStringArgumentValue("space", user_arguments)
        
        #Check for valid and reasonable inputs
        if dist_ins < 0
            runner.registerError("Distribution system insulation must have a positive R-value")
        end
        if dist_ins > 20
            runner.registerWarning("Distribution system insulation R-value is very large, double check inputs.")
        end
        
        #Get number of bedrooms/bathrooms
        nbeds, nbaths = Geometry.get_bedrooms_bathrooms(model, runner)
        if nbeds.nil? or nbaths.nil?
            return false
        end
        
        #Find which space the showers, sinks, and baths were previously assigned to and get the peak flow rates
        shower_max = nil
        sink_max = nil
        bath_max = nil
        shower_wu = nil
        sink_wu = nil
        bath_wu = nil
        dist_space = nil
        sh_name = Constants.ObjectNameShower
        s_name = Constants.ObjectNameSink
        b_name = Constants.ObjectNameBath
        
        spaces = model.getSpaces
        spaces.each do |space|
            space.waterUseEquipment.each do |space_equipment|
                if space_equipment.name.to_s == sh_name
                    shower_max = space_equipment.waterUseEquipmentDefinition.peakFlowRate
                    dist_space = space
                    shower_wu = space_equipment
                elsif space_equipment.name.to_s == s_name
                    sink_max = space_equipment.waterUseEquipmentDefinition.peakFlowRate
                    sink_wu = space_equipment
                elsif space_equipment.name.to_s == b_name
                    bath_max = space_equipment.waterUseEquipmentDefinition.peakFlowRate
                    bath_wu = space_equipment
                else
                    next
                end
            end
        end
        
        if shower_max.nil?
            runner.registerError("Residential Hot Water Fixture measure must be run prior to running this measure. Missing showers.")
            return false
        end
        if sink_max.nil?
            runner.registerError("Residential Hot Water Fixture measure must be run prior to running this measure. Missing sinks.")
            return false
        end
        if bath_max.nil?
            runner.registerError("Residential Hot Water Fixture measure must be run prior to running this measure. Missing baths.")
            return false
        end
        
        #Get mains water temperature and current shower, sink, and bath water uses
        weather = WeatherProcess.new(model,runner,File.dirname(__FILE__))
        if weather.error?
            return false
        end
        tmains = weather.data.MainsMonthlyTemps

        
        mixed_use_t = Constants.MixedUseT
        sh_sch = HotWaterSchedule.new(model, runner, sh_name + " schedule", sh_name + " temperature schedule", nbeds, 0, "Shower", mixed_use_t, File.dirname(__FILE__))
        s_sch = HotWaterSchedule.new(model, runner, s_name + " schedule",  s_name + " temperature schedule", nbeds, 0, "Sink", mixed_use_t, File.dirname(__FILE__))
        b_sch = HotWaterSchedule.new(model, runner, b_name + " schedule",  b_name + " temperature schedule", nbeds, 0, "Bath", mixed_use_t, File.dirname(__FILE__))
        shower_daily = sh_sch.calcDailyGpmFromPeakFlow(shower_max)
        sink_daily = s_sch.calcDailyGpmFromPeakFlow(sink_max)
        bath_daily = b_sch.calcDailyGpmFromPeakFlow(bath_max)
        
        daily_recovery_load = Array.new(12,0)
        daily_shower_increase = Array.new(12,0)
        daily_sink_increase = Array.new(12,0)
        daily_bath_increase = Array.new(12,0)
        monthly_internal_gain = Array.new(12,0)
        water_mix_to_h = Array.new(12,0)
        if dist_loc == Constants.LocationInterior
            gain_hourly_sch = "0.00623, 0.00312, 0.00078, 0.00078, 0.00312, 0.02181, 0.07477, 0.07944, 0.07632, 0.06698, 0.06075, 0.04829, 0.04206, 0.03738, 0.03738, 0.03271, 0.04361, 0.05763, 0.06854, 0.06542, 0.05919, 0.04829, 0.04206, 0.02336" #Hardcoded in sim.py, so not making an input here
            gain_monthly_sch = "1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0"
            dist_name = "Hot Water Distribution"
            gain_sch = MonthWeekdayWeekendSchedule.new(model, runner, dist_name + " schedule", gain_hourly_sch, gain_hourly_sch, gain_monthly_sch)
            if not gain_sch.validated?
                return false
            end
        end
        pi = Math::PI
        deg_rad = pi/180.0
        default_dist = false
        
        wh_setpoint = nil
        plant_loop = nil
        model.getPlantLoops.each do |pl|
            pl.supplyComponents.each do |wh|
                if wh.to_WaterHeaterMixed.is_initialized or wh.to_WaterHeaterStratified.is_initialized
                    wh_setpoint = Waterheater.get_water_heater_setpoint(model, pl, runner)
                    plant_loop = pl
                end
            end
        end
        if wh_setpoint.nil?
            return false
            runner.registerError("No water heater was found in the existing model. Add a residential water heater before adding hot water distrtibution.")
        end
        
        for m in 0..11
            water_mix_to_h[m] = [(mixed_use_t - tmains[m]) / (wh_setpoint - tmains[m]), 0].max
        end
        
        #Calculate the pump energy consumption (in kWh/day)
        if recirc_type == Constants.RecircTypeNone
            pump_e_ann = 0
        elsif recirc_type == Constants.RecircTypeTimer
            for m in 0..11 
                daily_recovery_load[m] = [(18135.0 + 2538.0 * nbeds + (-12265.0 - 1495.0 * nbeds) * dist_ins / 2.0) / \
                                (8.33 * (120.0 - tmains[m]) * 4184.0 * 0.00023886),0].max
            end
            pump_e_ann = 193.0
        elsif recirc_type == Constants.RecircTypeDemand
            for m in 0..11
                 daily_recovery_load[m] = [(-3648.0 + 2344.0 * nbeds + (-1328.0 - 761.0 * nbeds) * dist_ins / 2.0) / \
                                 (8.33 * (120.0 - tmains[m]) * 4184.0 * 0.00023886),0].max
            end
            pump_e_ann = (-0.13 + 0.72 * nbeds + (0.13 - 0.17 * nbeds) * dist_ins / 2.0)
        end
        pump_e = pump_e_ann / 365.0
        #Case 1: Trunk & Branch, Copper, Interior, No Recirc
        if dist_layout == Constants.PipeTypeTrunkBranch and pipe_mat == Constants.MaterialCopper and \
           dist_loc == Constants.LocationInterior and recirc_type == Constants.RecircTypeNone
            for m in 0..11
                daily_shower_increase[m] = [(-0.305 - 0.75 * nbeds) * dist_ins / 2.0,0].min #gal/day
                daily_bath_increase[m] = [(0.03 - 0.03 * nbeds) * dist_ins / 2.0,0].min #gal/day
                daily_sink_increase[m] = [(-0.755 - 0.245 * nbeds) * dist_ins / 2.0,0].min #gal/day
                monthly_internal_gain[m] = [Constants.MonthNumDays[m] * (4257.0 + 735.0 * (nbeds - 3) - \
                                           (948.0 + 158.0 * (nbeds - 3)) * dist_ins / 2.0) * (1 + 1.0 / 4257.0 * \
                                           (362.0 + (63.0 * (nbeds - 3))) * Math.sin(deg_rad * (360.0 * ((m + 1.0) / 12.0) + 0.3))),0].max #Btu/month
            end
        #Case 2: Trunk & Branch, PEX, Interior, No Recirc
        elsif dist_layout == Constants.PipeTypeTrunkBranch and pipe_mat == Constants.MaterialPEX and \
              dist_loc == Constants.LocationInterior and recirc_type == Constants.RecircTypeNone
            for m in 0..11
                daily_shower_increase[m] = [-0.85 - 0.44 * dist_ins / 2.0,0].min #gal/day
                daily_bath_increase[m] = [-0.12 - 0.06 * dist_ins / 2.0,0].min #gal/day
                daily_sink_increase[m] = [-1.69 - 1.74 * dist_ins / 2.0,0].min #gal/day
                monthly_internal_gain[m] = [Constants.MonthNumDays[m] * (4257.0 - 1047.0 - 732.0 * dist_ins / 2.0) * \
                                           (1 + 1.0 / 4257.0 * 735.0 * (nbeds - 3) + 1.0 / 4257.0 * (362.0 + (63.0 * (nbeds - 3))) * \
                                           Math.sin(deg_rad * (360.0 * ((m + 1.0) / 12.0) + 0.3))),0].max #Btu/month
            end
        #Case 3: Trunk & Branch, Copper, Exterior, No Recirc
        elsif dist_layout == Constants.PipeTypeTrunkBranch and pipe_mat == Constants.MaterialCopper and \
              dist_loc == Constants.LocationExterior and recirc_type == Constants.RecircTypeNone
            for m in 0..11
                daily_shower_increase[m] = [((-1.14 - 0.36 * nbeds) + (-0.34 - 0.08 * nbeds) * dist_ins / 2.0) * \
                                           (1 + 0.11 * Math.sin(deg_rad * (360.0 * ((m + 1.0) / 12.0) + 0.3))),0].min #gal/day 
                daily_bath_increase[m] = [((-0.28 - 0.11 * nbeds) + (0.06 - 0.04 * nbeds) * dist_ins / 2.0) * \
                                         (1 + 0.13 * Math.sin(deg_rad * (360.0 * ((m + 1.0) / 12.0)) + 0.3)),0].min #gal/day
                daily_sink_increase[m] = [((-0.89 - 0.32 * nbeds) + (-1.86 + 0.31 * nbeds) * dist_ins / 2.0) * \
                                         (1 + 0.16 * Math.sin(deg_rad * (360.0 * ((m + 1.0) / 12.0)) + 0.3)),0].min #gal/day
                monthly_internal_gain[m] = 0 #Btu/month
            end
        #Case 4: Trunk & Branch, PEX, Exterior, No Recirc
        elsif dist_layout == Constants.PipeTypeTrunkBranch and pipe_mat == Constants.MaterialPEX and \
              dist_loc == Constants.LocationExterior and recirc_type == Constants.RecircTypeNone
            for m in 0..11
                daily_shower_increase[m] = [-0.85 + (shower_daily * water_mix_to_h[m] - 0.85) / \
                                           (shower_daily * water_mix_to_h[m]) * ((-1.14 - 0.36 * nbeds) + \
                                           (-0.34 - 0.08 * nbeds) * dist_ins / 2.0) * (1.0 + 0.11 * Math.sin(deg_rad * (360.0 * \
                                           (m / 12.0) + 0.3))),0].min #gal/day
                daily_bath_increase[m] = [-0.12 + (bath_daily * water_mix_to_h[m] - 0.85) / \
                                         (bath_daily * water_mix_to_h[m]) * ((-0.28 - 0.11 * nbeds) + \
                                         (0.06 - 0.04 * nbeds) * dist_ins / 2.0) * \
                                         (1.0 + 0.13 * Math.sin(deg_rad * (360.0 * (m / 12.0) + 0.3))),0].min #gal/day
                daily_sink_increase[m] = [-1.69 + (sink_daily * water_mix_to_h[m] - 1.69) / \
                                         (sink_daily * water_mix_to_h[m]) * ((-0.89 - 0.32 * nbeds) + \
                                         (-1.86 + 0.31 * nbeds) * dist_ins / 2.0) * (1.0 + 0.16 * \
                                         Math.sin(deg_rad * (360.0 * ((m + 1.0) / 12.0) + 0.3))),0].min #gal/day
                monthly_internal_gain[m] = 0 #Btu/month
            end
        #Case 5: Home Run, PEX, Interior, No Recirc
        elsif dist_layout == Constants.PipeTypeHomeRun and pipe_mat == Constants.MaterialPEX and \
              dist_loc == Constants.LocationInterior and recirc_type == Constants.RecircTypeNone
            for m in 0..11
                daily_shower_increase[m] = [(-0.52 - 0.23 * nbeds) + (-0.35 + 0.02 * nbeds) * dist_ins / 2.0,0].min #gal/day
                daily_bath_increase[m] = [(-0.06 - 0.05 * nbeds) + (-0.11 + 0.03 * nbeds) * dist_ins / 2.0,0].min #gal/day
                daily_sink_increase[m] = [(0.21 - 0.72 * nbeds) + (-0.75 - 0.15 * nbeds) * dist_ins / 2.0,0].min #gal/day
                monthly_internal_gain[m] = [Constants.MonthNumDays[m] * (4257.0 + 735.0 * (nbeds - 3) - (1142.0 + 378.0 * (nbeds - 3)) - \
                                           ((649.0 + 73.0 * (nbeds - 3)) * dist_ins / 2.0)) * (1.0 + 1.0 / 4257.0 * (362.0 + (63.0 * (nbeds - 3))) * \
                                           Math.sin(deg_rad * (360.0 * ((m + 1.0) / 12.0)) + 0.3)),0].max #Btu/month
            end
        #Case 6: Homerun, PEX, Exterior, No Recirc
        elsif dist_layout == Constants.PipeTypeHomeRun and pipe_mat == Constants.MaterialPEX and \
              dist_loc == Constants.LocationExterior and recirc_type == Constants.RecircTypeNone
            for m in 0..11
                daily_shower_increase[m] = [-0.52 - 0.23 * nbeds + (shower_daily * water_mix_to_h[m] - 0.52 - 0.23 * nbeds) / \
                                           (shower_daily * water_mix_to_h[m]) * ((-1.14 - 0.36 * nbeds) + \
                                           (-0.34 - 0.08 * nbeds) * dist_ins / 2.0) * (1 + 0.11 * \
                                           Math.sin(deg_rad * (360.0 * (m / 12.0) + 0.3))),0].min #gal/day
                daily_bath_increase[m] = [-0.06 - 0.05 * nbeds + (bath_daily * water_mix_to_h[m] - 0.06 - 0.05 * nbeds) / \
                                         (bath_daily * water_mix_to_h[m]) * ((-0.28 - 0.11 * nbeds) + \
                                         (0.06 - 0.04 * nbeds) * dist_ins / 2.0) * (1 + 0.13 * \
                                         Math.sin(deg_rad * (360.0 * (m / 12.0)) + 0.3)),0].min #gal/day
                daily_sink_increase[m] = [0.21 - 0.72 * nbeds + (sink_daily * water_mix_to_h[m] + 0.21 - 0.72 * nbeds) / \
                                         (sink_daily * water_mix_to_h[m]) * ((-0.89 - 0.32 * nbeds) + \
                                         (-1.86 + 0.31 * nbeds) * dist_ins / 2.0) * (1 + 0.16 * \
                                         Math.sin(deg_rad * (360.0 * ((m + 1.0) / 12.0)) + 0.3)),0].min #gal/day
                monthly_internal_gain[m] = 0 #Btu/month
            end
        #Case 7: Trunk & Branch, Copper, Interior, Timer
        elsif dist_layout == Constants.PipeTypeTrunkBranch and pipe_mat == Constants.MaterialCopper and \
              dist_loc == Constants.LocationInterior and recirc_type == Constants.RecircTypeTimer
            for m in 0..11
                daily_shower_increase[m] = [(-2.15 + 0.25 * nbeds) + (-0.16 - 0.08 * nbeds) * dist_ins / 2.0,0].min #gal/day
                daily_bath_increase[m] = [(-0.27 + 0.04 * nbeds) + (-0.01 - 0.03 * nbeds) * dist_ins / 2.0,0].min #gal/day
                daily_sink_increase[m] = [(-2.01 - 0.95 * nbeds) + (-0.36 - 0.13 * nbeds) * dist_ins / 2.0,0].min #gal/day
                monthly_internal_gain[m] =  [Constants.MonthNumDays[m] * (4257.0 + 735.0 * (nbeds - 3) + (20148.0 + 2140.0 * (nbeds - 3)) - \
                                            ((11956.0 + 1355.0 * (nbeds - 3)) * dist_ins / 2.0)) * (1.0 + 1.0 / 4257.0 * (362.0 + (63.0 * \
                                            (nbeds - 3))) * Math.sin(deg_rad * (360.0 * ((m + 1.0) / 12.0) + 0.3))),0].max #Btu/month
            end
        #Case 8: Trunk & Branch, Copper, Interior, Demand
        elsif dist_layout == Constants.PipeTypeTrunkBranch and pipe_mat == Constants.MaterialCopper and \
              dist_loc == Constants.LocationInterior and recirc_type == Constants.RecircTypeDemand
            for m in 0..11
                daily_shower_increase[m] = [(-2.61 + 0.35 * nbeds) + (0.05 - 0.13 * nbeds) * dist_ins / 2.0,0].min #gal/day
                daily_bath_increase[m] = [(-0.26 + 0.01 * nbeds) - 0.03 * dist_ins / 2.0,0].min #gal/day
                daily_sink_increase[m] = [(-1.34 - 0.91 * nbeds) + (-0.64 - 0.07 * nbeds) * dist_ins / 2.0,0].min #gal/day
                monthly_internal_gain[m] = [Constants.MonthNumDays[m] * (4257.0 + 735.0 * (nbeds - 3) + (1458.0 + 1066.0 * (nbeds - 3)) - \
                                           ((1332.0 + 545.0 * (nbeds - 3)) * dist_ins / 2.0)) * \
                                           (1.0 + 1.0 / 4257.0 * (362.0 + (63.0 * (nbeds - 3))) * \
                                           Math.sin(deg_rad * (360.0 * ((m + 1.0) / 12.0) + 0.3))),0].max #Btu/month
            end
        #Case 9: Trunk & Branch, PEX, Interior, Timer
        elsif dist_layout == Constants.PipeTypeTrunkBranch and pipe_mat == Constants.MaterialPEX and \
              dist_loc == Constants.LocationInterior and recirc_type == Constants.RecircTypeTimer
            for m in 0..11
                daily_shower_increase[m] = [-0.85 + (shower_daily * water_mix_to_h[m] - 0.85) / \
                                           (shower_daily * water_mix_to_h[m]) * ((-2.15 + 0.25 * nbeds) + \
                                           (-0.16 - 0.08 * nbeds) * dist_ins / 2.0),0].min #gal/day
                daily_bath_increase[m] = [-0.12 + (bath_daily * water_mix_to_h[m] - 0.12) / \
                                         (bath_daily * water_mix_to_h[m]) * ((-0.27 + 0.04 * nbeds) + \
                                         (-0.01 - 0.03 * nbeds) * dist_ins / 2.0),0].min #gal/day
                daily_sink_increase[m] = [-1.69 + (sink_daily * water_mix_to_h[m] - 1.69) / \
                                         (sink_daily * water_mix_to_h[m]) * ((-2.01 - 0.95 * nbeds) + \
                                         (-0.36 - 0.13 * nbeds) * dist_ins / 2.0),0].min #gal/day
                monthly_internal_gain[m] = [Constants.MonthNumDays[m] * ((4257.0 - 1047.0) * (1.0 + 1.0 / 4257.0 * 735.0 * (nbeds - 3.0) + \
                                           1.0 / 4257.0 * (20148.0 + 2140.0 * (nbeds - 3.0)) - 1.0 / 4257.0 * ((11956.0 + 1355.0 * \
                                           (nbeds - 3.0)) * dist_ins / 2.0)) * (1.0 + 1.0 / 4257.0 * (362.0 + (63.0 * (nbeds - 3.0))) * \
                                           Math.sin(deg_rad * (360.0 * ((m + 1.0) / 12.0) + 0.3)))),0.0].max #Btu/month
            end
        #Case 10: Trunk & Branch, PEX, Interior, Demand
        elsif dist_layout == Constants.PipeTypeTrunkBranch and pipe_mat == Constants.MaterialPEX and \
              dist_loc == Constants.LocationInterior and recirc_type == Constants.RecircTypeDemand
            for m in 0..11
                daily_shower_increase[m] = [-0.85 + (shower_daily * water_mix_to_h[m] - 0.85) / \
                                           (shower_daily * water_mix_to_h[m]) * ((-2.61 + 0.35 * nbeds) + \
                                           (0.05 - 0.13 * nbeds) * dist_ins / 2.0),0].min #gal/day
                daily_bath_increase[m] = [-0.12 + (bath_daily * water_mix_to_h[m] - 0.12) / \
                                         (bath_daily * water_mix_to_h[m]) * ((-0.26 + 0.01 * nbeds) - \
                                         0.03 * dist_ins / 2.0),0].min #gal/day
                daily_sink_increase[m] = [-1.69 + (sink_daily * water_mix_to_h[m] - 1.69) / \
                                         (sink_daily * water_mix_to_h[m]) * ((-1.34 - 0.91 * nbeds) + \
                                         (-0.64 - 0.07 * nbeds) * dist_ins / 2.0),0].min #gal/day
                monthly_internal_gain[m] = [Constants.MonthNumDays[m] * ((4257.0 - 1047.0) * (1.0 + 1.0 / 4257.0 * 735.0 * (nbeds - 3) + \
                                           1.0 / 4257.0 * (1458.0 + 1066.0 * (nbeds - 3)) - 1.0 / 4257.0 * ((1332.0 + 545.0 * (nbeds - 3)) * \
                                           dist_ins / 2.0)) * (1.0 + 1.0 / 4257.0 * (362.0 + (63.0 * (nbeds - 3))) * \
                                           Math.sin(deg_rad * (360.0 * ((m + 1.0) / 12.0) + 0.3)))),0].max #Btu/month
            end
        #Case 11: Doesn't match any of the specified configurations (no HWsim runs were ever done for this situation)
        else
            runner.registerWarning("Unexpected DHW distribution configuration, defaulting to BA Benchmark configuration.")
            for m in 0..11
                daily_shower_increase[m] = 0 #gal/day
                daily_bath_increase[m] = 0 #gal/day
                daily_sink_increase[m] = 0 #gal/day
                monthly_internal_gain[m] = [Constants.MonthNumDays[m] * (4257.0 + 735.0 * (nbeds - 3)) * 
                                           (1.0 + 1.0 / 4257.0 * (362.0 + (63.0 * (nbeds - 3))) * 
                                           Math.sin(deg_rad * (360.0 * (m / 12.0) + 0.3))),0].max
                daily_recovery_load[m] = 0 #gal/day
            end
            default_dist = true
            pump_energy = 0 # kWh/day
        end
        
        #Sum the monthly values and calculate the new max flow rate 
        recovery_load_inc = 0
        daily_shower_inc = 0
        daily_sink_inc = 0
        daily_bath_inc = 0
        ann_int_gain = 0
        
        for m in 0..11
            recovery_load_inc += Constants.MonthNumDays[m] * daily_recovery_load[m] / water_mix_to_h[m] / (365.0 * 3.0) #Split evenly across all end uses
            daily_shower_inc += Constants.MonthNumDays[m] * daily_shower_increase[m] / water_mix_to_h[m] / 365.0
            daily_sink_inc += Constants.MonthNumDays[m] * daily_sink_increase[m] / water_mix_to_h[m] / 365.0
            daily_bath_inc += Constants.MonthNumDays[m] * daily_bath_increase[m] / water_mix_to_h[m] / 365.0
            ann_int_gain += OpenStudio.convert(monthly_internal_gain[m], "Btu", "kWh").get
        end
        
        new_shower_daily = shower_daily + recovery_load_inc + daily_shower_inc
        new_sink_daily = sink_daily + recovery_load_inc + daily_sink_inc
        new_bath_daily = bath_daily + recovery_load_inc + daily_bath_inc
        
        mixed_use_t = Constants.MixedUseT #F
        sh_dist_name = Constants.ObjectNameShowerDist
        s_dist_name = Constants.ObjectNameSinkDist
        b_dist_name = Constants.ObjectNameBathDist
        recirc_name = "Recirculation Pump"
        
        sh_new_peak_flow = sh_sch.calcPeakFlowFromDailygpm(new_shower_daily)
        s_new_peak_flow = s_sch.calcPeakFlowFromDailygpm(new_sink_daily)
        b_new_peak_flow = b_sch.calcPeakFlowFromDailygpm(new_bath_daily)
        
        shower_wu_def = shower_wu.waterUseEquipmentDefinition
        sink_wu_def = sink_wu.waterUseEquipmentDefinition
        bath_wu_def = bath_wu.waterUseEquipmentDefinition
        shower_wu_def.setPeakFlowRate(sh_new_peak_flow)
        sink_wu_def.setPeakFlowRate(s_new_peak_flow)
        bath_wu_def.setPeakFlowRate(b_new_peak_flow)

        #add in an otherEquipment obect for the monthly internal gain (if pipes are inside a space)
        if dist_loc == Constants.LocationInterior
            dist_design_level = gain_sch.calcDesignLevelFromDailykWh(ann_int_gain/365.0)
            dist_oe_def = OpenStudio::Model::OtherEquipmentDefinition.new(model)
            dist_oe = OpenStudio::Model::OtherEquipment.new(dist_oe_def)
            dist_oe.setName(dist_name)
            dist_oe.setSpace(dist_space)
            dist_oe_def.setName(dist_name)
            dist_oe_def.setDesignLevel(dist_design_level)
            dist_oe_def.setFractionRadiant(0)
            dist_oe_def.setFractionLatent(0)
            dist_oe_def.setFractionLost(0)
            gain_sch.setSchedule(dist_oe)
        end
        
        if recirc_type != Constants.RecircTypeNone
            recirc_pump_name = "recirculation pump"
            recirc_pump_design_level = sh_sch.calcDesignLevelFromDailykWh(pump_e)
            recirc_pump_def = OpenStudio::Model::ElectricEquipmentDefinition.new(model)
            recirc_pump = OpenStudio::Model::ElectricEquipment.new(recirc_pump_def)
            recirc_pump.setName(recirc_pump_name)
            recirc_pump.setSpace(dist_space)
            recirc_pump_def.setName(recirc_pump_name)
            recirc_pump_def.setDesignLevel(recirc_pump_design_level)
            if dist_loc == Constants.LocationInterior
                recirc_pump_def.setFractionRadiant(0.5)
                recirc_pump_def.setFractionLatent(0)
                recirc_pump_def.setFractionLost(0)
            else
                recirc_pump_def.setFractionRadiant(0)
                recirc_pump_def.setFractionLatent(0)
                recirc_pump_def.setFractionLost(1)
            end
            sh_sch.setSchedule(recirc_pump)
        end
        
        #reporting final condition of model
        if default_dist
            runner.registerFinalCondition("The defined DHW distribution system could not be modeled, and a default system was installed instead. For a list of acceptable distribution system configurations, see Table 18 of the December 2008 Building America Research Benchmark Definition (http://www.nrel.gov/docs/fy09osti/44816.pdf)")
        else
            if recirc_type != Constants.RecircTypeNone
                runner.registerFinalCondition("A new #{pipe_mat}, #{dist_layout} DHW distribution system has been added to the #{dist_loc} of the home with a recirculation pump energy consumption of #{pump_e_ann.round(2)} kWh/yr.")
            else
                runner.registerFinalCondition("A new #{pipe_mat}, #{dist_layout} DHW distribution system has been added to the #{dist_loc} of the home.")
            end
        end
        return true
    end

end #end the measure

#this allows the measure to be use by the application
ResidentialHotWaterDistribution.new.registerWithApplication
