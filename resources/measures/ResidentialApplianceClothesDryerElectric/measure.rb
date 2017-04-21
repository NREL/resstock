require "#{File.dirname(__FILE__)}/resources/schedules"
require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"

#start the measure
class ResidentialClothesDryer < OpenStudio::Measure::ModelMeasure
  
  def name
    return "Set Residential Electric Clothes Dryer"
  end

  def description
    return "Adds (or replaces) a residential clothes dryer with the specified efficiency, operation, and schedule. For multifamily buildings, the clothes dryer can be set for all units of the building."
  end
  
  def modeler_description
    return "Since there is no Clothes Dryer object in OpenStudio/EnergyPlus, we look for an ElectricEquipment or OtherEquipment object with the name that denotes it is a residential clothes dryer. If one is found, it is replaced with the specified properties. Otherwise, a new such object is added to the model. Note: This measure requires the number of bedrooms/bathrooms to have already been assigned."
  end

  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new
    
	#TODO: New argument for demand response for cds (alternate schedules if automatic DR control is specified)

	#make a double argument for Energy Factor
	cd_cef = OpenStudio::Measure::OSArgument::makeDoubleArgument("cd_cef",true)
	cd_cef.setDisplayName("Combined Energy Factor")
    cd_cef.setDescription("The Combined Energy Factor (CEF) measures the pounds of clothing that can be dried per kWh of electricity, including energy consumed during Stand-by and Off modes. If only an Energy Factor (EF) is available, convert using the equation: CEF = EF / 1.15.")
	cd_cef.setDefaultValue(2.7)
    cd_cef.setUnits("lb/kWh")
	args << cd_cef
    
	#make a double argument for occupancy energy multiplier
	cd_mult = OpenStudio::Measure::OSArgument::makeDoubleArgument("cd_mult",true)
	cd_mult.setDisplayName("Occupancy Energy Multiplier")
    cd_mult.setDescription("Appliance energy use is multiplied by this factor to account for occupancy usage that differs from the national average.")
	cd_mult.setDefaultValue(1)
	args << cd_mult

   	#Make a string argument for 24 weekday schedule values
	cd_weekday_sch = OpenStudio::Measure::OSArgument::makeStringArgument("cd_weekday_sch")
	cd_weekday_sch.setDisplayName("Weekday schedule")
	cd_weekday_sch.setDescription("Specify the 24-hour weekday schedule.")
	cd_weekday_sch.setDefaultValue("0.010, 0.006, 0.004, 0.002, 0.004, 0.006, 0.016, 0.032, 0.048, 0.068, 0.078, 0.081, 0.074, 0.067, 0.057, 0.061, 0.055, 0.054, 0.051, 0.051, 0.052, 0.054, 0.044, 0.024")
	args << cd_weekday_sch
    
	#Make a string argument for 24 weekend schedule values
	cd_weekend_sch = OpenStudio::Measure::OSArgument::makeStringArgument("cd_weekend_sch")
	cd_weekend_sch.setDisplayName("Weekend schedule")
	cd_weekend_sch.setDescription("Specify the 24-hour weekend schedule.")
	cd_weekend_sch.setDefaultValue("0.010, 0.006, 0.004, 0.002, 0.004, 0.006, 0.016, 0.032, 0.048, 0.068, 0.078, 0.081, 0.074, 0.067, 0.057, 0.061, 0.055, 0.054, 0.051, 0.051, 0.052, 0.054, 0.044, 0.024")
	args << cd_weekend_sch

  	#Make a string argument for 12 monthly schedule values
	cd_monthly_sch = OpenStudio::Measure::OSArgument::makeStringArgument("cd_monthly_sch", true)
	cd_monthly_sch.setDisplayName("Month schedule")
	cd_monthly_sch.setDescription("Specify the 12-month schedule.")
	cd_monthly_sch.setDefaultValue("1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0")
	args << cd_monthly_sch

	#make a double argument for Clothes Washer Integrated Modified Energy Factor
    #TODO: Remove when clothes washer info available
	cw_imef = OpenStudio::Measure::OSArgument::makeDoubleArgument("cw_imef",true)
	cw_imef.setDisplayName("Integrated Modified Energy Factor")
    cw_imef.setUnits("ft^3/kWh-cycle")
    cw_imef.setDescription("The Integrated Modified Energy Factor (IMEF) is the capacity of the clothes container divided by the total clothes washer energy consumption per cycle, where the energy consumption is the sum of the machine electrical energy consumption, the hot water energy consumption, the energy required for removal of the remaining moisture in the wash load, standby energy, and off-mode energy consumption. If only a Modified Energy Factor (MEF) is available, convert using the equation: IMEF = (MEF - 0.503) / 0.95.")
	cw_imef.setDefaultValue(0.95)
	args << cw_imef
    
    #make a double argument for Clothes Washer Rated Annual Consumption
    #TODO: Remove when clothes washer info available
    cw_rated_annual_energy = OpenStudio::Measure::OSArgument::makeDoubleArgument("cw_rated_annual_energy",true)
	cw_rated_annual_energy.setDisplayName("Clothes Washer Rated Annual Consumption")
    cw_rated_annual_energy.setUnits("kWh")
    cw_rated_annual_energy.setDescription("The annual energy consumed by the clothes washer, as rated, obtained from the EnergyGuide label. This includes both the appliance electricity consumption and the energy required for water heating.")
	cw_rated_annual_energy.setDefaultValue(387.0)
	args << cw_rated_annual_energy
    
	#make a double argument for Clothes Washer Drum Volume
    #TODO: Remove when clothes washer info available
	cw_drum_volume = OpenStudio::Measure::OSArgument::makeDoubleArgument("cw_drum_volume",true)
	cw_drum_volume.setDisplayName("Clothes Washer Drum Volume")
    cw_drum_volume.setUnits("ft^3")
    cw_drum_volume.setDescription("Volume of the washer drum.  Obtained from the EnergyStar website or the manufacturer's literature.")
	cw_drum_volume.setDefaultValue(3.5)
	args << cw_drum_volume
    
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
    space = OpenStudio::Measure::OSArgument::makeChoiceArgument("space", space_args, true)
    space.setDisplayName("Location")
    space.setDescription("Select the space where the cooking range is located. '#{Constants.Auto}' will choose the lowest above-grade finished space available (e.g., first story living space), or a below-grade finished space as last resort. For multifamily buildings, '#{Constants.Auto}' will choose a space for each unit of the building.")
    space.setDefaultValue(Constants.Auto)
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
	cd_cef = runner.getDoubleArgumentValue("cd_cef",user_arguments)
	cd_mult = runner.getDoubleArgumentValue("cd_mult",user_arguments)
	cd_weekday_sch = runner.getStringArgumentValue("cd_weekday_sch",user_arguments)
	cd_weekend_sch = runner.getStringArgumentValue("cd_weekend_sch",user_arguments)
    cd_monthly_sch = runner.getStringArgumentValue("cd_monthly_sch",user_arguments)
	cw_imef = runner.getDoubleArgumentValue("cw_imef",user_arguments)
    cw_rated_annual_energy = runner.getDoubleArgumentValue("cw_rated_annual_energy",user_arguments)
	cw_drum_volume = runner.getDoubleArgumentValue("cw_drum_volume",user_arguments)
	space_r = runner.getStringArgumentValue("space",user_arguments)
    
    #Check for valid inputs
	if cd_cef <= 0
		runner.registerError("Combined energy factor must be greater than 0.0.")
        return false
	end
	if cd_mult < 0
		runner.registerError("Occupancy energy multiplier must be greater than or equal to 0.0.")
        return false
    end
    if cw_imef <= 0
        runner.registerError("Clothes washer integrated modified energy factor must be greater than 0.0.")
        return false
    end
    if cw_rated_annual_energy <= 0
        runner.registerError("Clothes washer rated annual consumption must be greater than 0.0.")
        return false
    end
    if cw_drum_volume <= 0
        runner.registerError("Clothes washer drum volume must be greater than 0.0.")
        return false
    end

    # Get building units
    units = Geometry.get_building_units(model, runner)
    if units.nil?
        return false
    end
    
    tot_cd_ann_e = 0
    msgs = []
    sch = nil
    units.each do |unit|
        # Get unit beds/baths
        nbeds, nbaths = Geometry.get_unit_beds_baths(model, unit, runner)
        if nbeds.nil? or nbaths.nil?
            return false
        end
        
        # Get space
        space = Geometry.get_space_from_string(unit.spaces, space_r)
        next if space.nil?

        unit_obj_name_e = Constants.ObjectNameClothesDryer(Constants.FuelTypeElectric, unit.name.to_s)
        unit_obj_name_g = Constants.ObjectNameClothesDryer(Constants.FuelTypeGas, unit.name.to_s)
        unit_obj_name_p = Constants.ObjectNameClothesDryer(Constants.FuelTypePropane, unit.name.to_s)
    
        # Remove any existing clothes dryer
        objects_to_remove = []
        space.electricEquipment.each do |space_equipment|
            next if space_equipment.name.to_s != unit_obj_name_e
            objects_to_remove << space_equipment
            objects_to_remove << space_equipment.electricEquipmentDefinition
            if space_equipment.schedule.is_initialized
                objects_to_remove << space_equipment.schedule.get
            end
        end
        space.otherEquipment.each do |space_equipment|
            next if space_equipment.name.to_s != unit_obj_name_g and space_equipment.name.to_s != unit_obj_name_p
            objects_to_remove << space_equipment
            objects_to_remove << space_equipment.otherEquipmentDefinition
            if space_equipment.schedule.is_initialized
                objects_to_remove << space_equipment.schedule.get
            end
        end
        if objects_to_remove.size > 0
            runner.registerInfo("Removed existing clothes dryer from space #{space.name.to_s}.")
        end
        objects_to_remove.uniq.each do |object|
            begin
                object.remove
            rescue
                # no op
            end
        end
        
        cd_ef = cd_cef * 1.15 # RESNET interpretation
        cw_mef = 0.503 + 0.95 * cw_imef # RESNET interpretation

        # Energy Use is based on "Method for Evaluating Energy Use of Dishwashers, Clothes 
        # Washers, and Clothes Dryers" by Eastment and Hendron, Conference Paper NREL/CP-550-39769, 
        # August 2006. Their paper is in part based on the energy use calculations presented in the 
        # 10CFR Part 430, Subpt. B, App. D (DOE 1999),
        # http://ecfr.gpoaccess.gov/cgi/t/text/text-idx?c=ecfr&tpl=/ecfrbrowse/Title10/10cfr430_main_02.tpl
        # Eastment and Hendron present a method for estimating the energy consumption per cycle 
        # based on the dryer's energy factor.

        # Set some intermediate variables. An experimentally determined value for the percent 
        # reduction in the moisture content of the test load, expressed here as a fraction 
        # (DOE 10CFR Part 430, Subpt. B, App. D, Section 4.1)
        dryer_nominal_reduction_in_moisture_content = 0.66
        # The fraction of washer loads dried in a clothes dryer (DOE 10CFR Part 430, Subpt. B, 
        # App. J1, Section 4.3)
        dryer_usage_factor = 0.84
        load_adjustment_factor = 0.52

        # Set the number of cycles per year for test conditions
        cw_cycles_per_year_test = 392 # (see Eastment and Hendron, NREL/CP-550-39769, 2006)

        # Calculate test load weight (correlation based on data in Table 5.1 of 10CFR Part 430,
        # Subpt. B, App. J1, DOE 1999)
        cw_test_load = 4.103003337 * cw_drum_volume + 0.198242492 # lb

        # Eq. 10 of Eastment and Hendron, NREL/CP-550-39769, 2006.
        dryer_energy_factor_std = 0.5 # Nominal drying energy required, kWh/lb dry cloth
        dryer_elec_per_year = (cw_cycles_per_year_test * cw_drum_volume / cw_mef - 
                              cw_rated_annual_energy) # kWh
        dryer_elec_per_cycle = dryer_elec_per_year / cw_cycles_per_year_test # kWh
        remaining_moisture_after_spin = (dryer_elec_per_cycle / (load_adjustment_factor * 
                                        dryer_energy_factor_std * dryer_usage_factor * 
                                        cw_test_load) + 0.04) # lb water/lb dry cloth
        cw_remaining_water = cw_test_load * remaining_moisture_after_spin

        # Use the dryer energy factor and remaining water from the clothes washer to calculate 
        # total energy use per cycle (eq. 7 Eastment and Hendron, NREL/CP-550-39769, 2006).
        actual_cd_energy_use_per_cycle = (cw_remaining_water / (cd_ef *
                                         dryer_nominal_reduction_in_moisture_content)) # kWh/cycle
                                         
        # All energy use is electric.
        actual_cd_elec_use_per_cycle = actual_cd_energy_use_per_cycle # kWh/cycle

        # (eq. 14 Eastment and Hendron, NREL/CP-550-39769, 2006)
        actual_cw_cycles_per_year = (cw_cycles_per_year_test * (0.5 + nbeds / 6) * 
                                    (12.5 / cw_test_load)) # cycles/year

        # eq. 15 of Eastment and Hendron, NREL/CP-550-39769, 2006
        actual_cd_cycles_per_year = dryer_usage_factor * actual_cw_cycles_per_year # cycles/year

        daily_energy_elec = actual_cd_cycles_per_year * actual_cd_elec_use_per_cycle / 365 # kWh/day

        daily_energy_elec = daily_energy_elec * cd_mult

        cd_ann_e = daily_energy_elec * 365.0 # kWh/yr

        if cd_ann_e > 0
        
            if sch.nil?
                # Create schedule
                mult_weekend = 1.15
                mult_weekday = 0.94
                sch = MonthWeekdayWeekendSchedule.new(model, runner, Constants.ObjectNameClothesDryer(Constants.FuelTypeElectric) + " schedule", cd_weekday_sch, cd_weekend_sch, cd_monthly_sch, mult_weekday, mult_weekend)
                if not sch.validated?
                    return false
                end
            end

            design_level_e = sch.calcDesignLevelFromDailykWh(daily_energy_elec)

            #Add equipment for the cd
            cd_def = OpenStudio::Model::ElectricEquipmentDefinition.new(model)
            cd = OpenStudio::Model::ElectricEquipment.new(cd_def)
            cd.setName(unit_obj_name_e)
            cd.setEndUseSubcategory(unit_obj_name_e)
            cd.setSpace(space)
            cd_def.setName(unit_obj_name_e)
            cd_def.setDesignLevel(design_level_e)
            cd_def.setFractionRadiant(0.09)
            cd_def.setFractionLatent(0.05)
            cd_def.setFractionLost(0.8)
            cd.setSchedule(sch.schedule)
            
            msgs << "A clothes dryer with #{cd_ann_e.round} kWhs annual energy consumption has been assigned to space '#{space.name.to_s}'."
            
            tot_cd_ann_e += cd_ann_e
        end
        
    end
    
    # Reporting
    if msgs.size > 1
        msgs.each do |msg|
            runner.registerInfo(msg)
        end
        runner.registerFinalCondition("The building has been assigned clothes dryers totaling #{tot_cd_ann_e.round} kWhs annual energy consumption across #{units.size} units.")
    elsif msgs.size == 1
        runner.registerFinalCondition(msgs[0])
    else
        runner.registerFinalCondition("No clothes dryer has been assigned.")
    end
    
    return true
	
  end

end #end the measure

#this allows the measure to be use by the application
ResidentialClothesDryer.new.registerWithApplication