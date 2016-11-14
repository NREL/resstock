# developed for use with Ruby 2.0.0 (have your Ruby evaluate RUBY_VERSION)

# Note that the Dehumidifier functions are all stubbed out at the end of the AddResidentialDehumidifier class
# With these stubs, the new Dehumidifier settings will be revealed as runner Info messages if
# if the thermal zone is named "showParametersForNewDummyDehumidifier"

require 'openstudio'
require 'cgi'

class AddResidentialDehumidifier < OpenStudio::Ruleset::ModelUserScript
	OSM = OpenStudio::Model
	    
    #define the name that a user will see, this method may be deprecated as
    #the display name in PAT comes from the name field in measure.xml
	def name
		return "Set Residential Dehumidifier"
	end

	def arguments(model)
		ruleset = OpenStudio::Ruleset
		osArg = ruleset::OSArgument

		args = ruleset::OSArgumentVector.new
        
        # checkbox for benchmark_use_case
		@benchmark_use_case_Arg = osArg::makeBoolArgument('benchmark_use_case', true) # true means required
		@benchmark_use_case_Arg.setDisplayName('Check this box to have a Residential DX Dehumidifier configured to BA Benchmark Home Requirements (i.e. Relative Humidity will be set to 60%)')
        @benchmark_use_case_Arg.setDefaultValue(false)
		args << @benchmark_use_case_Arg
        
        # Choice list of existing_thermal_zones
        zoneNames = model.getThermalZones.collect{|z|z.name.get}
        
        @selected_existing_thermal_zone_Arg = osArg::makeChoiceArgument("selected_existing_thermal_zone", zoneNames, true) # true means required
		@selected_existing_thermal_zone_Arg.setDisplayName("Thermal Zone where Dehumidifier will be located.")
		args << @selected_existing_thermal_zone_Arg
        
        # rated_water_removal_rate
        @rated_water_removal_rate_Arg = osArg::makeDoubleArgument("rated_water_removal_rate", true) # true means required
        @rated_water_removal_rate_Arg.setDisplayName("Full load water removal rate (pints / day) at rated air flow rate and conditions (air entering the dehumidifier 80F dry-bulb and 60% relative humidity).")
        args << @rated_water_removal_rate_Arg
        
        # rated_energy_factor
        @rated_energy_factor_Arg = osArg::makeDoubleArgument("energy_factor", true) # true means required
        @rated_energy_factor_Arg.setDisplayName("Energy factor (Litres/kWh) at rated conditions (air entering the dehumidifier at 80F dry-bulb and 60% relative humidity, and air flow rate. Enter -1 to use EnergyStar criteria for Energy Factor.")
        args << @rated_energy_factor_Arg
        
        # rated_airflow_rate
        @rated_airflow_rate_Arg = osArg::makeDoubleArgument("rated_airflow_rate", true) # true means required
        @rated_airflow_rate_Arg.setDisplayName("Dehumidifier airflow rate (cfm) at rated conditions (air entering the dehumidifier at 80F dry-bulb and 60% relative humidity. Enter -1 to have airflow rate a function of water removal rate (2.75 cfm/pint/day).")
        args << @rated_airflow_rate_Arg
        
        # relative_humidity_setpoint
        @relative_humidity_setpoint_Arg = osArg::makeDoubleArgument("relative_humidity_setpoint", true) # true means required
        @relative_humidity_setpoint_Arg.setDisplayName("The humidity setpoint of the Dehumidifier (% RH). If the checkbox for creating a Residential DX Dehumidifier is checked, this user argument will be ignored and the % RH will be set to 60")
        args << @relative_humidity_setpoint_Arg
           
		args
	end # arguments 

    #Put argument values in the following variables, returning true if they validate, false otherwise
    #    @benchmark_use_case 
    #    @selected_existing_thermal_zone
    #    @rated_water_removal_rate
    #    @rated_energy_factor
    #    @rated_airflow_rate
    #    @relative_humidity_setpoint
    #
    #Error messages and warning messages will be accumulated, i.e., we don't stop validating when we find a problem.
    #Conditions that cause errors will not also cause warnings.
    #
    #(UserScript should exit(return false) if false is returned by prevalidate, like with registerWarning)
    def prevalidate(model, runner, args)
        modelArgs = arguments(model)
  
        #use the built-in error checking 
        return false unless runner.validateUserArguments(modelArgs, args)
        
        # get the args values
        @benchmark_use_case = runner.getBoolArgumentValue("benchmark_use_case",args)
        @selected_existing_thermal_zone = model.getThermalZoneByName(runner.getStringArgumentValue("selected_existing_thermal_zone", args)).get # assume each has unique name
        @rated_water_removal_rate = runner.getDoubleArgumentValue("rated_water_removal_rate", args)
        @rated_energy_factor = runner.getDoubleArgumentValue("energy_factor", args)
        @rated_airflow_rate = runner.getDoubleArgumentValue("rated_airflow_rate", args)
        @relative_humidity_setpoint = runner.getDoubleArgumentValue("relative_humidity_setpoint", args)
        
        errors = []
        emit = lambda{|msg| errors << msg}
        
        emit["Dehumidifier rated water removal rate must be > 0 pints/day."] unless @rated_water_removal_rate > 0 
        emit["Rated Energy Factor of Dehumidifier must be > 0 Litres/kWh."] unless @rated_energy_factor > 0 or @rated_energy_factor == -1
        emit["Rated Airflow Rate of Dehumidifier must be > 0 cfm."] unless @rated_airflow_rate > 0 or @rated_airflow_rate == -1
        emit["Relative Humidity Setpoint must be greater than 0%."] unless @benchmark_use_case or @relative_humidity_setpoint > 0
        emit["Relative Humidity Setpoint must be < 100%."] unless @benchmark_use_case or @relative_humidity_setpoint < 100.0
        
        warnings = []
        emit = lambda{|msg| warnings << (msg + " Please confirm input.")}
        
        # Conditions that cause errors will not also cause warnings
        
        wrrLOW = 25
        emit["A residential dehumidifier having a water removal rate < #{wrrLOW} pints per day is suspect."] if 
            0 < @rated_water_removal_rate && @rated_water_removal_rate < wrrLOW 
        
        wrrHIGH = 200
        emit["A residential dehumidifier having a water removal rate > #{wrrHIGH} pints per day is suspect."] if @rated_water_removal_rate > wrrHIGH
        
        refacHIGH = 4
        emit["A residential dehumidifier having a Rated Energy Factor > #{'%.1f'% refacHIGH} Litres/kWh is suspect."] if @rated_energy_factor > refacHIGH
        
        refacLOW = 1
        emit["A residential dehumidifier having a Rated Energy Factor < #{'%.1f'% refacLOW} Litres/kWh is suspect."] if 
            0 < @rated_energy_factor && @rated_energy_factor < refacLOW 
            
        raflowHIGH = 500
        emit["A residential dehumidifier having a rated airflow rate > #{raflowHIGH} cfm is suspect."] if @rated_airflow_rate > raflowHIGH
        
        raflowLOW = 100
        emit["A residential dehumidifier having a rated airflow rate < #{raflowLOW} cfm is suspect."] if 
            0 < @rated_airflow_rate && @rated_airflow_rate < raflowLOW 
            
        rhsHIGH = 85
        emit["Relative Humidity Setpoint of #{@relative_humidity_setpoint} % seems high."] if 
            !@benchmark_use_case && 100 > @relative_humidity_setpoint && @relative_humidity_setpoint > rhsHIGH
        
        rhsLOW = 30
        emit["Relative Humidity Setpoint of #{@relative_humidity_setpoint} % seems low."] if 
            !@benchmark_use_case && 0 < @relative_humidity_setpoint && @relative_humidity_setpoint < rhsLOW
        
        isValid = true
        errors.map{|msg|    isValid = false ; runner.registerError(CGI.escapeHTML(msg)) }
        warnings.map{|msg|  isValid &= runner.registerWarning(CGI.escapeHTML(msg)) } 
        # isValid is true when there are no errors and no failing warnings
        #"UserScripts should return false after calling [registerError]" see http://openstudio.nrel.gov/c-sdk-documentation/ruleset       
        #"The UserScript should exit (return false) if false is returned [from registerWarning]" see http://openstudio.nrel.gov/c-sdk-documentation/ruleset 
               
        isValid        
    end # prevalidate

    
    def run(model, runner, args)
		super(model, runner, args)
    
        return false unless prevalidate(model, runner, args)
        
        #NB: assume there is a thermal zone since thermal zone is a required argument
   
        runner.registerInitialCondition(CGI.escapeHTML( initialCondition(model) ))         

        @relative_humidity_setpoint = 60 if @benchmark_use_case

        @rated_energy_factor = autoSizedEnergyFactor(@rated_water_removal_rate) if @rated_energy_factor == -1 

        @rated_airflow_rate =  @rated_water_removal_rate * 2.75 if @rated_airflow_rate == -1 # this conversion assumes removal is pints/day and airflow is cfm

        @theNewDehumidifier = newZoneHVACDehumidifierDX

        configureDehumidifier(model, @theNewDehumidifier)
        
        @oldHumidistatDehumSetpointSched = humidistatDehumSetpointSchedIfAny(@selected_existing_thermal_zone) 

        @theHumidistat,@theHumidistatIsNew = updateHumidistatFor(model, @selected_existing_thermal_zone)
        @theHumidistat.setDehumidifyingRelativeHumiditySetpointSchedule(default_dehumidification_sch(model))
        @newHumidistatDehumSetpointSched = humidistatDehumSetpointSchedIfAny(@selected_existing_thermal_zone) 

        addDehumidifierToThermalZoneAndPrioritize(model, @selected_existing_thermal_zone, @theNewDehumidifier)
           
        runner.registerFinalCondition(CGI.escapeHTML( finalCondition(model) )) 
        
        ###############################################################################################################
        # REMOVE this call to showDummyDehumidifier when Dehumidifiers are actually implemented and stubs are replaced.
        # It's just here to facilitate testing whether correct values are set in the new dehumidifier.
        ###############################################################################################################
        showDummyDehumidifier(@theNewDehumidifier,runner) if @selected_existing_thermal_zone.name.to_s == "showParametersForNewDummyDehumidifier" 
        
		true
    end # run 


    # Report count of existing OS:ZoneHVAC:Dehumidifier:DX objects prior to running the measure. 
    # Report Size (gal) and nominal Capacity (W) of eachobject.
    def initialCondition(model)     
        dhObs = dehumidifierDXObjects(model)
        
        "Initial Condition: #{dhObs.size} DehumidifierDX."+
        " Water removal rates and Energy factors: "+
        dhObs.map{|dhOb| 
            precision = 6
            waterRemovalRate_ppd = pintsFromLitres(ratedWaterRemovalRate(dhOb)).round(precision)
            energyFactor_lpkwh = ratedEnergyFactor(dhOb).round(precision)
            "#{dehumidifierName(dhOb)}(#{waterRemovalRate_ppd} pints/day, #{energyFactor_lpkwh} litres/kWh)"
        }.join(' ; ')
    end

    # Report the name of OS:ZoneHVAC:Dehumidifier:DX objects and the thermal zone the object was added to. 
    # If a ZoneControl:Humidistat dehumidifying setpoint schedule object was replaced, report the name of that schedule, 
    # as well as the name of new ZoneControl:Humidistat dehumidifying setpoint schedule.   
    # Report the final values of: rated_water_removal_rate ; rated_energy_factor ; rated_airflow_rate ; relative_humidity_setpoint
    def finalCondition(model)  
        msg  = "Added #{dehumidifierName(@theNewDehumidifier)} (OS:ZoneHVAC:Dehumidifier:DX) "+
               " to thermal zone named #{@selected_existing_thermal_zone.name}" 
        msg << ", and added a Humidistat"  if @theHumidistatIsNew
        msg << ", setting the thermal zone controls Humidistat Dehumidification Setpoint Schedule to #{@newHumidistatDehumSetpointSched.name}" 
        msg << " (replacing #{@oldHumidistatDehumSetpointSched.name})" unless nil == @oldHumidistatDehumSetpointSched
        msg << "."
            
        msg << " New Dehumidifier values: "
        msg << "Water removal rate = #{@rated_water_removal_rate} pints/day"
        msg << " ; "
        msg << "Energy factor = #{@rated_energy_factor} litres/kWh"
        msg << " ; "
        msg << "Airflow rate = #{@rated_airflow_rate} cfm"
        msg << " ; "
        msg << "Humidity setpoint = #{@relative_humidity_setpoint}%"
        
    end

    def autoSizedEnergyFactor(removalRate)
        cutoffs =  [[25,1.2],
                    [35,1.4],
                    [45,1.5],
                    [54,1.6],
                    [75,1.8]
                   ]
        cutoffsSize = cutoffs.size
        i = 0
        while (i < cutoffsSize && removalRate > cutoffs[i][0]) ; i = i+1 end
        i < cutoffsSize ? cutoffs[i][1] : 2.5
    end
    
    def nonFanZoneExhaustEquipmentList(model, thermalZone) 
        model.getZoneHVACEquipmentLists.select{|es|  es.thermalZone == thermalZone}[0] # assume there's exactly one equipment list for thermalZone
        .equipment.select{|e|e.iddObject.name != "OS:Fan:ZoneExhaust"} # ignore OS:Fan:ZoneExhaust
    end
 
    def default_water_removal_rate_curve(model)
        curve = OpenStudio::Model::CurveBiquadratic.new(model)
        curve.setCoefficient1Constant(-1.162525707)
        curve.setCoefficient2x(0.02271469)
        curve.setCoefficient3xPOW2(-0.000113208)
        curve.setCoefficient4y(0.021110538)
        curve.setCoefficient5yPOW2(-0.0000693034)
        curve.setCoefficient6xTIMESY(0.000378843)
        curve.setMinimumValueofx(-100)
        curve.setMaximumValueofx(100)
        curve.setMinimumCurveOutput(-100)
        curve.setMaximumCurveOutput(100)
        curve
    end
    
    def default_energy_factor_curve(model)
        curve = OpenStudio::Model::CurveBiquadratic.new(model)
        curve.setCoefficient1Constant(-1.902154518)
        curve.setCoefficient2x(0.063466565)
        curve.setCoefficient3xPOW2(-0.000622839)
        curve.setCoefficient4y(0.039540407)
        curve.setCoefficient5yPOW2(-0.000125637)
        curve.setCoefficient6xTIMESY(-0.000176722)
        curve.setMinimumValueofx(-100)
        curve.setMaximumValueofx(100)
        curve.setMinimumCurveOutput(-100)
        curve.setMaximumCurveOutput(100)   
        curve
    end
    
    def default_part_load_fraction_correction_curve(model)
        curve = OpenStudio::Model::CurveQuadratic.new(model)
        curve.setCoefficient1Constant(0.9)
        curve.setCoefficient2x(0.1)
        curve.setCoefficient3xPOW2(0)
        curve.setMinimumValueofx(0)
        curve.setMaximumValueofx(1.0)
        curve.setMinimumCurveOutput(0.7) 
        curve.setMaximumCurveOutput(1.0)  
        curve
    end
    
    def litresFromPints(x) 
        OpenStudio::convert(x,"gal","m^3").get*(100**3)/1000/8.0 # 8pts = 1gal ; 1(m^3) = (100^3)cc ; 1000cc = 1liter
    end
    
    def pintsFromLitres(x) 
        OpenStudio::convert(x,"m^3","gal").get*1000/(100**3)*8 # 8pts = 1gal ; 1(m^3) = (100^3)cc ; 1000cc = 1liter
    end
    
    def cmsFromCfm(x) #Cubic meters per second from cubic feet per minute
        OpenStudio::convert(x*1.0,"ft^3/min","m^3/s").get
    end
    
    def configureDehumidifier(model, dehumidifier)
    
        setRatedWaterRemovalRate(dehumidifier, litresFromPints(@rated_water_removal_rate)) 

        setRatedEnergyFactor(dehumidifier, @rated_energy_factor)     
		
        setRatedAirflowRate(dehumidifier, cmsFromCfm(@rated_airflow_rate))   	
  
        setWaterRemovalCurveName(dehumidifier, default_water_removal_rate_curve(model))
		
        setEnergyFactorCurveName(dehumidifier, default_energy_factor_curve(model))

		setPartLoadCorrelationCurveName(dehumidifier, default_part_load_fraction_correction_curve(model))
		
        setMinimumDryBulbTemperatureForDehumidificationOperation(dehumidifier, 10) 	## Note units are degrees C, hard-coding value to idd default.
		
        setMaximumDryBulbTemperatureForDehumidificationOperation(dehumidifier, 35) 	## Note units are degrees C, hard-coding value to idd default.
		
        setOffCycleParasiticElectricLoad(dehumidifier, 0)								## Note 0 is the idd default value.

    end # configureDehumidifier
    
    def dehumidificationScheduleTypeLimits(model)
        limits = OpenStudio::Model::ScheduleTypeLimits.new(model)
        limits.setName("Dehumidification Setpoint Schedule Type Limits")
        limits.setLowerLimitValue(0.0)
        limits.setUpperLimitValue(100.0)
        limits.setNumericType("Continuous")
        limits.setUnitType("Percent")
        limits
    end
    
    def default_dehumidification_sch(model)
        ruleset = OpenStudio::Model::ScheduleRuleset.new(model)
        ruleset.setName("Dehumidification Setpoint Default")
        ruleset.defaultDaySchedule().setName("Dehumidification Setpoint Default") 
        ruleset.defaultDaySchedule().addValue(OpenStudio::Time.new(0,24,0,0),@relative_humidity_setpoint)
        ruleset.setScheduleTypeLimits(dehumidificationScheduleTypeLimits(model)) 
        ruleset 
    end

    # If the thermalZone has a humidistat with a dehumidifying setpoint schedule, 
    # return that schedule, otherwise return nil
    def humidistatDehumSetpointSchedIfAny(thermalZone)     
        statMaybe = thermalZone.zoneControlHumidistat
        return nil if statMaybe.empty?
        schedMaybe = statMaybe.get.dehumidifyingRelativeHumiditySetpointSchedule
        return nil if schedMaybe.empty?
        schedMaybe.get
    end
    
    # Returns [humidistat, humidistatIsNew]
    # humidistat will be thermalZone.zoneControlHumidistat.get in the end.
    # A new humidistat will be forced upon the thermalZone if need be to accomplish this,
    # in which case humidistatIsNew will be true.  
    def updateHumidistatFor(model, thermalZone)
        statMaybe = thermalZone.zoneControlHumidistat
        if humidistatIsNew = statMaybe.empty?
            humidistat = OpenStudio::Model::ZoneControlHumidistat.new(model)
            thermalZone.setZoneControlHumidistat(humidistat)
        else
            humidistat = statMaybe.get
        end
        [humidistat,humidistatIsNew]
    end
   
    ######################################################################################################################################
    # The code from here to end-of-class comprises stubs that should be rewritten once the dehumidier type is implemented.
    # The class would probably be OpenStudio::Model::ZoneHVACDehumidifierDX, and would extend OpenStudio::Model::HVACComponent ;
    # we assume the iddObject.name for these dehumidifiers would be "OS:ZoneHVAC:Dehumidifier:DX"
    ######################################################################################################################################
    
    #############################################################################################
    #TODO replace this stub to really get all OS::ZoneHVACDehumidifierDX objects from the model
    #############################################################################################
    def dehumidifierDXObjects(model) 
        # The real code would look something like 
        # model.getZoneHVACEquipmentLists.map{|es| es.equipment}.flatten.select{|e| e.iddObject.name == "OS:ZoneHVAC:Dehumidifier:DX"}
        # 
        # Until the dehumidier type is implemented, we just return some fakes
        newDH = lambda{|name,removal,efactor| 
            dh = {name:name , ratedWaterRemovalRate: litresFromPints(removal) , ratedEnergyFactor: efactor }
        }

        [newDH["TestDummy-DehumidiferA", 111.0, 1.2],
         newDH["TestDummy-Dehumidifer1", 124.0, 2.3],
         newDH["TestDummy-Dehumidifer", 139.0, 3.4]
        ] 
     
#        [{name:"TestDummy-Dehumidifer-A" , ratedWaterRemovalRate: 111.0 , ratedEnergyFactor: 1.2}]
    end

    #############################################################################################
    #TODO replace this stub to really add a OS::ZoneHVACDehumidifierDX object to a thermal zone
    #############################################################################################
    def addDehumidifierToThermalZoneAndPrioritize(model, thermalZone, dehumidifier)
        # The real code would be
        # thermalZone.addEquipment(dehumidifier)
        # thermalZone.setCoolingPriority(dehumidifier, nonFanZoneExhaustEquipmentList(model,thermalZone).size )
        if  false 
            nonFanZoneExhaustEquipmentList(model,thermalZone).size # stub code is still made to show dependency on nonFanZoneExhaustEquipmentList
        end # but this stub doesn't do anything
    end

    def  newZoneHVACDehumidifierDX #TODO replace stub to Create new OS::ZoneHVACDehumidifierDX object 
       @newZoneHVACDehumidifierDX_count = (defined? @newZoneHVACDehumidifierDX_count) ? 1+@newZoneHVACDehumidifierDX_count : 1
       {name:     "TestDummy-New-Dehumidifier#{@newZoneHVACDehumidifierDX_count==1 ? "" : @newZoneHVACDehumidifierDX_count.to_s }",
       }
    end
 
    def showDummyDehumidifier(dehumidifier,runner) # this should be deleted when eliminating stubs
        dehumidifier.map{|key,value|
            runner.registerInfo(CGI.escapeHTML("#{dehumidifierName(dehumidifier)} : #{key} = #{value}"))
        }
    end
    
    def dehumidifierName(dehumidifier)
        dehumidifier[:name] #TODO replace stub when we know how to get the name from a OS::ZoneHVACDehumidifierDX object 
    end
    
    def dehumidifierSize_gal(dehumidifier)
        dehumidifier[:size]  #TODO eliminate stub after we know how to get the size from a OS::ZoneHVACDehumidifierDX object 
    end 
    
    def dehumidifierCapacity_W(dehumidifier)
        dehumidifier[:capacity]   #TODO eliminate stub after we know how to get the capacity from a OS::ZoneHVACDehumidifierDX object 
    end 
    
    def stubbedDehumidiferSetting # this is defined to allow testing before Dehumidifiers are implemented
        @selected_existing_thermal_zone == "testingStubbedDehumidiferSetting"
    end
    
    def ratedWaterRemovalRate(dehumidifier)
        dehumidifier[:ratedWaterRemovalRate]
    end
	def setRatedWaterRemovalRate(dehumidifier, x)  ## Litres per day 
        dehumidifier[:ratedWaterRemovalRate] = x
    end

    def ratedEnergyFactor(dehumidifier)
        dehumidifier[:ratedEnergyFactor]
    end
	def setRatedEnergyFactor(dehumidifier, x)   	## Litres/kWh 
        dehumidifier[:ratedEnergyFactor] = x
	end
	
	def	setRatedAirflowRate(dehumidifier, x)   		## meters3 / sec
        dehumidifier[:ratedAirflowRate] = x
    end
    
	def	setWaterRemovalCurveName(dehumidifier, x) 
        dehumidifier[:waterRemovalCurveName] = x
	end
	
	def	setEnergyFactorCurveName(dehumidifier, x) 
        dehumidifier[:energyFactorCurveName] = x
	end
	
	def	setPartLoadCorrelationCurveName(dehumidifier, x)
        dehumidifier[:partLoadCorrelationCurveName] = x
	end
	
	def	setMinimumDryBulbTemperatureForDehumidificationOperation(dehumidifier, x) 	## degrees C
        dehumidifier[:minimumDryBulbTemperatureForDehumidificationOperation] = x
	end
	
	def	setMaximumDryBulbTemperatureForDehumidificationOperation(dehumidifier, x) 	## degrees C
        dehumidifier[:maximumDryBulbTemperatureForDehumidificationOperation] = x
	end
	
	def	setOffCycleParasiticElectricLoad(dehumidifier, x)				
        dehumidifier[:offCycleParasiticElectricLoad] = x
    end
    
end # measure AddResidentialDehumidifier
   
#this allows the measure to be use by the application
AddResidentialDehumidifier.new.registerWithApplication
