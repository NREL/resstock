#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

require "#{File.dirname(__FILE__)}/resources/geometry"
require "#{File.dirname(__FILE__)}/resources/schedules"
require "#{File.dirname(__FILE__)}/resources/weather"

#start the measure
class ResidentialLighting < OpenStudio::Measure::ModelMeasure

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Residential Lighting"
  end
  
  def description
    return "Sets (or replaces) the lighting energy use, based on fractions of CFLs, LFLs, and LEDs, for finished spaces, the garage, and outside. For multifamily buildings, the lighting can be set for all units of the building.#{Constants.WorkflowDescription}"
  end
  
  def modeler_description
    return "Assigns a lighting energy use and schedule to finished spaces, the garage, and outside. The lighting schedule is calculated for the latitude/longitude of the weather location specified in the model."
  end
  
  #define the arguments that the user will input
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new
    
    #make a choice argument for option type
    choices = []
    choices << Constants.OptionTypeLightingFractions
    choices << Constants.OptionTypeLightingEnergyUses
    option_type = OpenStudio::Measure::OSArgument::makeChoiceArgument("option_type",choices,true)
    option_type.setDisplayName("Option Type")
    option_type.setDescription("Inputs are used/ignored below based on the option type specified.")
    option_type.setDefaultValue(Constants.OptionTypeLightingFractions)
    args << option_type
    
    #make a double argument for hardwired CFL fraction
    hw_cfl = OpenStudio::Measure::OSArgument::makeDoubleArgument("hw_cfl",true)
    hw_cfl.setDisplayName("#{Constants.OptionTypeLightingFractions}: Hardwired Fraction CFL")
    hw_cfl.setDescription("Fraction of all hardwired lamps (interior, garage, and exterior) that are compact fluorescent. Hardwired lighting not specified as CFL, LED, or LFL is assumed to be incandescent.")
    hw_cfl.setDefaultValue(0.34)
    args << hw_cfl
    
    #make a double argument for hardwired LED fraction
    hw_led = OpenStudio::Measure::OSArgument::makeDoubleArgument("hw_led",true)
    hw_led.setDisplayName("#{Constants.OptionTypeLightingFractions}: Hardwired Fraction LED")
    hw_led.setDescription("Fraction of all hardwired lamps (interior, garage, and exterior) that are LED. Hardwired lighting not specified as CFL, LED, or LFL is assumed to be incandescent.")
    hw_led.setDefaultValue(0)
    args << hw_led
    
    #make a double argument for hardwired LFL fraction
    hw_lfl = OpenStudio::Measure::OSArgument::makeDoubleArgument("hw_lfl",true)
    hw_lfl.setDisplayName("#{Constants.OptionTypeLightingFractions}: Hardwired Fraction LFL")
    hw_lfl.setDescription("Fraction of all hardwired lamps (interior, garage, and exterior) that are linear fluorescent. Hardwired lighting not specified as CFL, LED, or LFL is assumed to be incandescent.")
    hw_lfl.setDefaultValue(0)
    args << hw_lfl
    
    #make a double argument for Plugin CFL fraction
    pg_cfl = OpenStudio::Measure::OSArgument::makeDoubleArgument("pg_cfl",true)
    pg_cfl.setDisplayName("#{Constants.OptionTypeLightingFractions}: Plugin Fraction CFL")
    pg_cfl.setDescription("Fraction of all plugin lamps that are compact fluorescent. Plugin lighting not specified as CFL, LED, or LFL is assumed to be incandescent.")
    pg_cfl.setDefaultValue(0.34)
    args << pg_cfl
    
    #make a double argument for Plugin LED fraction
    pg_led = OpenStudio::Measure::OSArgument::makeDoubleArgument("pg_led",true)
    pg_led.setDisplayName("#{Constants.OptionTypeLightingFractions}: Plugin Fraction LED")
    pg_led.setDescription("Fraction of all plugin lamps that are LED. Plugin lighting not specified as CFL, LED, or LFL is assumed to be incandescent.")
    pg_led.setDefaultValue(0)
    args << pg_led
    
    #make a double argument for Plugin LFL fraction
    pg_lfl = OpenStudio::Measure::OSArgument::makeDoubleArgument("pg_lfl",true)
    pg_lfl.setDisplayName("#{Constants.OptionTypeLightingFractions}: Plugin Fraction LFL")
    pg_lfl.setDescription("Fraction of all plugin lamps that are linear fluorescent. Plugin lighting not specified as CFL, LED, or LFL is assumed to be incandescent.")
    pg_lfl.setDefaultValue(0)
    args << pg_lfl
    
    #make a double argument for Incandescent Efficacy
    in_eff = OpenStudio::Measure::OSArgument::makeDoubleArgument("in_eff",true)
    in_eff.setDisplayName("#{Constants.OptionTypeLightingFractions}: Incandescent Efficacy")
    in_eff.setUnits("lm/W")
    in_eff.setDescription("The ratio of light output from an incandescent lamp to the electric power it consumes.")
    in_eff.setDefaultValue(15)
    args << in_eff
    
    #make a double argument for CFL Efficacy
    cfl_eff = OpenStudio::Measure::OSArgument::makeDoubleArgument("cfl_eff",true)
    cfl_eff.setDisplayName("#{Constants.OptionTypeLightingFractions}: CFL Efficacy")
    cfl_eff.setUnits("lm/W")
    cfl_eff.setDescription("The ratio of light output from a CFL lamp to the electric power it consumes.")
    cfl_eff.setDefaultValue(55)
    args << cfl_eff
    
    #make a double argument for LED Efficacy
    led_eff = OpenStudio::Measure::OSArgument::makeDoubleArgument("led_eff",true)
    led_eff.setDisplayName("#{Constants.OptionTypeLightingFractions}: LED Efficacy")
    led_eff.setUnits("lm/W")
    led_eff.setDescription("The ratio of light output from a LED lamp to the electric power it consumes.")
    led_eff.setDefaultValue(80)
    args << led_eff
    
    #make a double argument for LFL Efficacy
    lfl_eff = OpenStudio::Measure::OSArgument::makeDoubleArgument("lfl_eff",true)
    lfl_eff.setDisplayName("#{Constants.OptionTypeLightingFractions}: LFL Efficacy")
    lfl_eff.setUnits("lm/W")
    lfl_eff.setDescription("The ratio of light output from a LFL lamp to the electric power it consumes.")
    lfl_eff.setDefaultValue(88)
    args << lfl_eff
    
    #make a double argument for interior energy use
    energy_use_interior = OpenStudio::Measure::OSArgument::makeDoubleArgument("energy_use_interior",true)
    energy_use_interior.setDisplayName("#{Constants.OptionTypeLightingEnergyUses}: Interior")
    energy_use_interior.setUnits("kWh/year")
    energy_use_interior.setDescription("Total interior annual lighting energy use (excluding garages).")
    energy_use_interior.setDefaultValue(900)
    args << energy_use_interior    

    #make a double argument for garage energy use
    energy_use_garage = OpenStudio::Measure::OSArgument::makeDoubleArgument("energy_use_garage",true)
    energy_use_garage.setDisplayName("#{Constants.OptionTypeLightingEnergyUses}: Garage")
    energy_use_garage.setUnits("kWh/year")
    energy_use_garage.setDescription("Total garage annual lighting energy use. Only applied if there is a garage space.")
    energy_use_garage.setDefaultValue(100)
    args << energy_use_garage    

    #make a double argument for exterior energy use
    energy_use_exterior = OpenStudio::Measure::OSArgument::makeDoubleArgument("energy_use_exterior",true)
    energy_use_exterior.setDisplayName("#{Constants.OptionTypeLightingEnergyUses}: Exterior")
    energy_use_exterior.setUnits("kWh/year")
    energy_use_exterior.setDescription("Total exterior annual lighting energy use.")
    energy_use_exterior.setDefaultValue(300)
    args << energy_use_exterior    

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
    option_type = runner.getStringArgumentValue("option_type",user_arguments)
    hw_cfl = runner.getDoubleArgumentValue("hw_cfl",user_arguments)
    hw_led = runner.getDoubleArgumentValue("hw_led",user_arguments)
    hw_lfl = runner.getDoubleArgumentValue("hw_lfl",user_arguments)
    pg_cfl = runner.getDoubleArgumentValue("pg_cfl",user_arguments)
    pg_led = runner.getDoubleArgumentValue("pg_led",user_arguments)
    pg_lfl = runner.getDoubleArgumentValue("pg_lfl",user_arguments)
    in_eff = runner.getDoubleArgumentValue("in_eff",user_arguments)
    cfl_eff = runner.getDoubleArgumentValue("cfl_eff",user_arguments)
    led_eff = runner.getDoubleArgumentValue("led_eff",user_arguments)
    lfl_eff = runner.getDoubleArgumentValue("lfl_eff",user_arguments)
    energy_use_interior = runner.getDoubleArgumentValue("energy_use_interior",user_arguments)
    energy_use_garage = runner.getDoubleArgumentValue("energy_use_garage",user_arguments)
    energy_use_exterior = runner.getDoubleArgumentValue("energy_use_exterior",user_arguments)
    
    #Check for valid inputs
    if option_type == Constants.OptionTypeLightingFractions
      if hw_cfl < 0 or hw_cfl > 1
          runner.registerError("Hardwired Fraction CFL must be greater than or equal to 0 and less than or equal to 1.")
          return false
      end
      if hw_led < 0 or hw_led > 1
          runner.registerError("Hardwired Fraction LED must be greater than or equal to 0 and less than or equal to 1.")
          return false
      end
      if hw_lfl < 0 or hw_lfl > 1
          runner.registerError("Hardwired Fraction LFL must be greater than or equal to 0 and less than or equal to 1.")
          return false
      end
      if hw_cfl + hw_led + hw_lfl > 1
          runner.registerError("Sum of CFL, LED, and LFL Hardwired Fractions must be less than or equal to 1.")
          return false
      end
      if pg_cfl < 0 or pg_cfl > 1
          runner.registerError("Plugin Fraction CFL must be greater than or equal to 0 and less than or equal to 1.")
          return false
      end
      if pg_led < 0 or pg_led > 1
          runner.registerError("Plugin Fraction LED must be greater than or equal to 0 and less than or equal to 1.")
          return false
      end
      if pg_lfl < 0 or pg_lfl > 1
          runner.registerError("Plugin Fraction LFL must be greater than or equal to 0 and less than or equal to 1.")
          return false
      end
      if pg_cfl + pg_led + pg_lfl > 1
          runner.registerError("Sum of CFL, LED, and LFL Plugin Fractions must be less than or equal to 1.")
          return false
      end
      if in_eff <= 0
          runner.registerError("Incandescent Efficacy must be greater than 0.")
          return false
      end
      if cfl_eff <= 0
          runner.registerError("CFL Efficacy must be greater than 0.")
          return false
      end
      if led_eff <= 0
          runner.registerError("LED Efficacy must be greater than 0.")
          return false
      end
      if lfl_eff <= 0
          runner.registerError("LFL Efficacy must be greater than 0.")
          return false
      end
    elsif option_type == Constants.OptionTypeLightingEnergyUses
      if energy_use_interior < 0
          runner.registerError("#{Constants.OptionTypeLightingEnergyUses}: Interior must be greater than or equal to 0.")
          return false
      end
      if energy_use_garage < 0
          runner.registerError("#{Constants.OptionTypeLightingEnergyUses}: Garage must be greater than or equal to 0.")
          return false
      end
      if energy_use_exterior < 0
          runner.registerError("#{Constants.OptionTypeLightingEnergyUses}: Exterior must be greater than or equal to 0.")
          return false
      end
    end
    
    # Get building units
    units = Geometry.get_building_units(model, runner)
    if units.nil?
        return false
    end

    # Fractions hardwired vs plugin
    frac_hw = 0.8
    frac_pg = 0.2

    bab_frac_inc = 0.66
    bab_frac_cfl = 0.34
    bab_frac_led = 0.00
    bab_frac_lfl = 0.00

    # Incandescent fractions
    hw_inc = 1 - hw_cfl - hw_led - hw_lfl
    pg_inc = 1 - pg_cfl - pg_led - pg_lfl

    # Efficacy ratios
    bab_inc_ef = 15.0
    bab_cfl_ef = 55.0
    bab_led_ef = 80.0
    bab_lfl_ef = 88.0
    er_cfl = bab_inc_ef / cfl_eff
    er_led = bab_inc_ef / led_eff
    er_lfl = bab_inc_ef / lfl_eff
    er_inc = bab_inc_ef / in_eff
    bab_er_cfl = bab_inc_ef / bab_cfl_ef 
    bab_er_led = bab_inc_ef / bab_led_ef 
    bab_er_lfl = bab_inc_ef / bab_lfl_ef
    bab_er_inc = bab_inc_ef / bab_inc_ef

    # Smart Replacement Factor
    smrt_replace_f = (0.1672 * hw_inc ** 4 - 0.4817 * hw_inc ** 3 + 0.6336 * hw_inc ** 2 - 0.492 * hw_inc + 1.1561)

    # Calculate the lighting schedule
    weather = WeatherProcess.new(model, runner, File.dirname(__FILE__))
    if weather.error?
        return false
    end
    lat = weather.header.Latitude
    long = weather.header.Longitude
    tz = weather.header.Timezone
    std_long = -tz*15
    pi = Math::PI
    
    # Sunrise and sunset hours
    sunrise_hour = []
    sunset_hour = []
    normalized_hourly_lighting = [[1..24],[1..24],[1..24],[1..24],[1..24],[1..24],[1..24],[1..24],[1..24],[1..24],[1..24],[1..24]]
    for month in 0..11
        if lat < 51.49
            m_num = month+1
            jul_day = m_num*30-15
            if not (m_num < 4 or m_num > 10)
                offset = 1
            else
                offset = 0
            end
            declination = 23.45 * Math.sin(0.9863 * (284 + jul_day) * 0.01745329)
            deg_rad = pi/180
            rad_deg = 1/deg_rad
            b = (jul_day-1) * 0.9863
            equation_of_time = (0.01667 * (0.01719 + 0.42815 * Math.cos(deg_rad*b) - 7.35205 * Math.sin(deg_rad*b) - 3.34976 * Math.cos(deg_rad*(2*b)) - 9.37199 * Math.sin(deg_rad*(2*b))))
            sunset_hour_angle = rad_deg * (Math.acos(-1 * Math.tan(deg_rad*lat) * Math.tan(deg_rad*declination)))
            sunrise_hour[month] =  offset + (12.0 - 1 * sunset_hour_angle/15.0) - equation_of_time - (std_long + long)/15
            sunset_hour[month] = offset + (12.0 + 1 * sunset_hour_angle/15.0) - equation_of_time - (std_long + long)/15
        else
            sunrise_hour = [8.125726064, 7.449258072, 6.388688653, 6.232405257, 5.27722936, 4.84705384, 5.127512162, 5.860163988, 6.684378904, 7.521267411, 7.390441945, 8.080667697]
            sunset_hour = [16.22214058, 17.08642353, 17.98324493, 19.83547864, 20.65149672, 21.20662992, 21.12124777, 20.37458274, 19.25834757, 18.08155615, 16.14359164, 15.75571306]
        end
    end
                
    dec_kws = [0.075, 0.055, 0.040, 0.035, 0.030, 0.025, 0.025, 0.025, 0.025, 0.025, 0.025, 0.030, 0.045, 0.075, 0.130, 0.160, 0.140, 0.100, 0.075, 0.065, 0.060, 0.050, 0.045, 0.045, 0.045, 0.045, 0.045, 0.045, 0.050, 0.060, 0.080, 0.130, 0.190, 0.230, 0.250, 0.260, 0.260, 0.250, 0.240, 0.225, 0.225, 0.220, 0.210, 0.200, 0.180, 0.155, 0.125, 0.100]
    june_kws = [0.060, 0.040, 0.035, 0.025, 0.020, 0.020, 0.020, 0.020, 0.020, 0.020, 0.020, 0.020, 0.020, 0.025, 0.030, 0.030, 0.025, 0.020, 0.015, 0.015, 0.015, 0.015, 0.015, 0.015, 0.015, 0.015, 0.015, 0.015, 0.015, 0.015, 0.015, 0.015, 0.020, 0.020, 0.020, 0.025, 0.025, 0.030, 0.030, 0.035, 0.045, 0.060, 0.085, 0.125, 0.145, 0.130, 0.105, 0.080]
    lighting_seasonal_multiplier =   [1.075, 1.064951905, 1.0375, 1.0, 0.9625, 0.935048095, 0.925, 0.935048095, 0.9625, 1.0, 1.0375, 1.064951905]          
    amplConst1 = 0.929707907917098
    sunsetLag1 = 2.45016230615269
    stdDevCons1 = 1.58679810983444
    amplConst2 = 1.1372291802273
    sunsetLag2 = 20.1501965859073
    stdDevCons2 = 2.36567663279954

    monthly_kwh_per_day = []
    days_m = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    wtd_avg_monthly_kwh_per_day = 0
    for monthNum in 1..12
        month = monthNum-1
        monthHalfHourKWHs = [0]
        # Calculate hour 12.5 first; others depend on it
        #monthHalfHourKWHs[24] = june_kws[24] + ((dec_kws[24] - june_kws[24]) / 2.0 / 0.266 * (1.0 / 1.5 / ((2.0*pi)**0.5)) * Math.exp(-0.5 * (((6 - monthNum).abs - 6) / 1.5)**2)) + ((dec_kws[24] - june_kws[24]) / 2 / 0.399 * (1 / 1 / ((2 * pi)**0.5)) * Math.exp(-0.5 * (((4.847 - sunrise_hour[month]).abs - 3.2) / 1.0)**2))
        for hourNum in 0..9
            monthHalfHourKWHs[hourNum] = june_kws[hourNum]
        end
        for hourNum in 9..17
            hour = (hourNum + 1.0) * 0.5
            monthHalfHourKWHs[hourNum] = (monthHalfHourKWHs[8]  - (0.15 / (2 * pi)) * Math.sin((2 * pi) * (hour - 4.5) / 3.5) + (0.15 / 3.5) * (hour - 4.5)) * lighting_seasonal_multiplier[month] 
        end
        for hourNum in 17..29
            hour = (hourNum + 1.0) * 0.5
            monthHalfHourKWHs[hourNum] = (monthHalfHourKWHs[16] - (-0.02 / (2 * pi)) * Math.sin((2 * pi) * (hour - 8.5) / 5.5) + (-0.02 / 5.5) * (hour - 8.5)) * lighting_seasonal_multiplier[month]
        end
        for hourNum in 29..45
            hour = (hourNum + 1.0) * 0.5
            monthHalfHourKWHs[hourNum] = (monthHalfHourKWHs[28] + amplConst1 * Math.exp((-1.0 * (hour - (sunset_hour[month] + sunsetLag1))**2) / (2.0 * ((25.5 / ((6.5 - monthNum).abs + 20.0)) * stdDevCons1)**2)) / ((25.5 / ((6.5 - monthNum).abs + 20.0)) * stdDevCons1 * (2.0*pi)**0.5))
        end
        for hourNum in 45..46
            hour = (hourNum + 1.0) * 0.5
            temp1 = (monthHalfHourKWHs[44] + amplConst1 * Math.exp((-1.0 * (hour - (sunset_hour[month] + sunsetLag1))**2) / (2.0 * ((25.5 / ((6.5 - monthNum).abs + 20.0)) * stdDevCons1)**2)) / ((25.5 / ((6.5 - monthNum).abs + 20.0)) * stdDevCons1 * (2.0*pi)**0.5))
            temp2 = (0.04 + amplConst2 * Math.exp((-1.0 * (hour - (sunsetLag2))**2) / (2.0 * (stdDevCons2)**2)) / (stdDevCons2 * (2.0*pi)**0.5))
            if sunsetLag2 < sunset_hour[month] + sunsetLag1
                monthHalfHourKWHs[hourNum] = [temp1, temp2].min
            else
                monthHalfHourKWHs[hourNum] = [temp1, temp2].max
            end
        end
        for hourNum in 46..47
            hour = (hourNum + 1) * 0.5
            monthHalfHourKWHs[hourNum] = (0.04 + amplConst2 * Math.exp((-1.0 * (hour - (sunsetLag2))**2) / (2.0 * (stdDevCons2)**2)) / (stdDevCons2 * (2.0*pi)**0.5))
        end

        sum_kWh = 0.0
        for timenum in 0..47
            sum_kWh = sum_kWh + monthHalfHourKWHs[timenum]
        end
        for hour in 0..23
            ltg_hour = (monthHalfHourKWHs[hour*2] + monthHalfHourKWHs[hour*2+1]).to_f
            normalized_hourly_lighting[month][hour] = ltg_hour/sum_kWh
            monthly_kwh_per_day[month] = sum_kWh/2.0 
       end
       wtd_avg_monthly_kwh_per_day = wtd_avg_monthly_kwh_per_day + monthly_kwh_per_day[month] * days_m[month]/365.0
    end
    
    # Calculate normalized monthly lighting fractions
    seasonal_multiplier = []
    sumproduct_seasonal_multiplier = 0
    normalized_monthly_lighting = seasonal_multiplier
    for month in 0..11
        seasonal_multiplier[month] = (monthly_kwh_per_day[month]/wtd_avg_monthly_kwh_per_day)
        sumproduct_seasonal_multiplier += seasonal_multiplier[month] * days_m[month]
    end
    
    for month in 0..11
        normalized_monthly_lighting[month] = seasonal_multiplier[month] * days_m[month] / sumproduct_seasonal_multiplier
    end
    
    # Calc schedule values
    lighting_sch = [[],[],[],[],[],[],[],[],[],[],[],[]]
    sch_max = 0.0
    for month in 0..11
        for hour in 0..23
            lighting_sch[month][hour] = normalized_monthly_lighting[month]*normalized_hourly_lighting[month][hour]/days_m[month]
            if lighting_sch[month][hour] > sch_max
                sch_max = lighting_sch[month][hour]
            end
        end
    end
    
    # Remove all existing lighting
    objects_to_remove = []
    model.getExteriorLightss.each do |exterior_light|
        objects_to_remove << exterior_light
        objects_to_remove << exterior_light.exteriorLightsDefinition
        if exterior_light.schedule.is_initialized
            objects_to_remove << exterior_light.schedule.get
        end
    end
    model.getLightss.each do |light|
        objects_to_remove << light
        objects_to_remove << light.lightsDefinition
        if light.schedule.is_initialized
            objects_to_remove << light.schedule.get
        end
    end
    if objects_to_remove.size > 0
        runner.registerInfo("Removed existing interior/exterior lighting from the model.")
    end
    objects_to_remove.uniq.each do |object|
        begin
            object.remove
        rescue
            # no op
        end
    end

    tot_ltg = 0
    all_unit_garage_spaces = []
    num_units_without_garage = 0
    msgs = []
    sch = nil
    units.each do |unit|
        
        # Get unit ffa and finished spaces
        unit_finished_spaces = Geometry.get_finished_spaces(unit.spaces)
        ffa = Geometry.get_finished_floor_area_from_spaces(unit.spaces, false, runner)
        if ffa.nil?
            return false
        end
        
        # Get unit garage floor area
        unit_garage_spaces = Geometry.get_garage_spaces(unit.spaces, model)
        gfa = Geometry.get_floor_area_from_spaces(unit_garage_spaces)
        if unit_garage_spaces.size == 0
            num_units_without_garage += 1
        end

        # Interior lighting
        if option_type == Constants.OptionTypeLightingEnergyUses
            ltg_ann = energy_use_interior
        elsif option_type == Constants.OptionTypeLightingFractions
            bm_hw_e = frac_hw * (ffa * 0.542 + 334)
            bm_pg_e = frac_pg * (ffa * 0.542 + 334)
            int_hw_e = (bm_hw_e * (((hw_inc * er_inc + (1 - bab_frac_inc) * bab_er_inc) + (hw_cfl * er_cfl - bab_frac_cfl * bab_er_cfl) + (hw_led * er_led - bab_frac_led * bab_er_led) + (hw_lfl * er_lfl - bab_frac_lfl * bab_er_lfl)) * smrt_replace_f * 0.9 + 0.1))
            int_pg_e = (bm_pg_e * (((pg_inc * er_inc + (1 - bab_frac_inc) * bab_er_inc) + (pg_cfl * er_cfl - bab_frac_cfl * bab_er_cfl) + (pg_led * er_led - bab_frac_led * bab_er_led) + (pg_lfl * er_lfl - bab_frac_lfl * bab_er_lfl)) * smrt_replace_f * 0.9 + 0.1))
            ltg_ann = int_hw_e + int_pg_e
        end
    
        # Garage lighting
        if gfa > 0
            if option_type == Constants.OptionTypeLightingEnergyUses
                garage_ann = energy_use_garage
            elsif option_type == Constants.OptionTypeLightingFractions
                bm_garage_e =  0.08 * gfa + 8
                garage_ann = (bm_garage_e * (((hw_inc * er_inc + (1 - bab_frac_inc) * bab_er_inc) + (hw_cfl * er_cfl - bab_frac_cfl * bab_er_cfl) + (hw_led * er_led - bab_frac_led * bab_er_led) + (hw_lfl * er_lfl - bab_frac_lfl * bab_er_lfl)) * smrt_replace_f * 0.9 + 0.1))
            end
        else
            garage_ann = 0.0 
        end
    
        # Finished/Garage spaces for the unit
        (unit_finished_spaces + unit_garage_spaces).each do |space|
            space_obj_name = "#{Constants.ObjectNameLighting(unit.name.to_s)} #{space.name.to_s}"

            if sch.nil?
                # Create schedule
                sch = HourlyByMonthSchedule.new(model, runner, Constants.ObjectNameLighting + " schedule", lighting_sch, lighting_sch)
                if not sch.validated?
                    return false
                end
            end
            
            if unit_finished_spaces.include?(space)
                space_ltg_ann = ltg_ann * OpenStudio.convert(space.floorArea, "m^2", "ft^2").get / ffa
            elsif unit_garage_spaces.include?(space)
                space_ltg_ann = garage_ann * OpenStudio.convert(space.floorArea, "m^2", "ft^2").get / gfa
            end
            space_design_level = sch.calcDesignLevel(sch_max*space_ltg_ann)
        
            # Add lighting
            ltg_def = OpenStudio::Model::LightsDefinition.new(model)
            ltg = OpenStudio::Model::Lights.new(ltg_def)
            ltg.setName(space_obj_name)
            ltg.setSpace(space)
            ltg_def.setName(space_obj_name)
            ltg_def.setLightingLevel(space_design_level)
            ltg_def.setFractionRadiant(0.6)
            ltg_def.setFractionVisible(0.2)
            ltg_def.setReturnAirFraction(0.0)
            ltg.setSchedule(sch.schedule)

            msgs << "Lighting with #{space_ltg_ann.round} kWhs annual energy consumption has been assigned to space '#{space.name.to_s}'."
            tot_ltg += space_ltg_ann
            
        end
        
    end
    
    # Common garage lighting (garages not associated with a unit)
    common_spaces = Geometry.get_all_common_spaces(model, runner)
    common_garage_spaces = Geometry.get_garage_spaces(common_spaces, model)
    common_gfa = Geometry.get_floor_area_from_spaces(common_garage_spaces)
    if option_type == Constants.OptionTypeLightingEnergyUses
        common_garage_ann = energy_use_garage * num_units_without_garage
    elsif option_type == Constants.OptionTypeLightingFractions
        common_bm_garage_e =  0.08 * common_gfa + 8 * num_units_without_garage
        common_garage_ann = (common_bm_garage_e * (((hw_inc * er_inc + (1 - bab_frac_inc) * bab_er_inc) + (hw_cfl * er_cfl - bab_frac_cfl * bab_er_cfl) + (hw_led * er_led - bab_frac_led * bab_er_led) + (hw_lfl * er_lfl - bab_frac_lfl * bab_er_lfl)) * smrt_replace_f * 0.9 + 0.1))
    end
    
    common_garage_spaces.each do |garage_space|
        space_obj_name = "#{Constants.ObjectNameLighting} #{garage_space.name.to_s}"
    
        if sch.nil?
            # Create schedule
            sch = HourlyByMonthSchedule.new(model, runner, Constants.ObjectNameLighting + " schedule", lighting_sch, lighting_sch)
            if not sch.validated?
                return false
            end
        end
        
        space_ltg_ann = common_garage_ann * OpenStudio.convert(garage_space.floorArea, "m^2", "ft^2").get / common_gfa
        space_design_level = sch.calcDesignLevel(sch_max*space_ltg_ann)
    
        # Add lighting
        ltg_def = OpenStudio::Model::LightsDefinition.new(model)
        ltg = OpenStudio::Model::Lights.new(ltg_def)
        ltg.setName(space_obj_name)
        ltg.setSpace(garage_space)
        ltg_def.setName(space_obj_name)
        ltg_def.setLightingLevel(space_design_level)
        ltg_def.setFractionRadiant(0.6)
        ltg_def.setFractionVisible(0.2)
        ltg_def.setReturnAirFraction(0.0)
        ltg.setSchedule(sch.schedule)

        msgs << "Lighting with #{space_ltg_ann.round} kWhs annual energy consumption has been assigned to space '#{garage_space.name.to_s}'."
        tot_ltg += space_ltg_ann
        
    end
    
    # Exterior Lighting
    if option_type == Constants.OptionTypeLightingEnergyUses
        outside_ann = energy_use_exterior
    elsif option_type == Constants.OptionTypeLightingFractions
        total_ffa = Geometry.get_finished_floor_area_from_spaces(model.getSpaces, true, runner)
        bm_outside_e = 0.145 * total_ffa
        outside_ann = (bm_outside_e * (((hw_inc * er_inc + (1 - bab_frac_inc) * bab_er_inc) + (hw_cfl * er_cfl - bab_frac_cfl * bab_er_cfl) + (hw_led * er_led - bab_frac_led * bab_er_led) + (hw_lfl * er_lfl - bab_frac_lfl * bab_er_lfl)) * smrt_replace_f * 0.9 + 0.1))
    end

    space_design_level = sch.calcDesignLevel(sch_max*outside_ann)
    space_obj_name = "#{Constants.ObjectNameLighting} exterior"
    
    # Add exterior lighting
    ltg_def = OpenStudio::Model::ExteriorLightsDefinition.new(model)
    ltg = OpenStudio::Model::ExteriorLights.new(ltg_def)
    ltg.setName(space_obj_name)
    ltg_def.setName(space_obj_name)
    ltg_def.setDesignLevel(space_design_level)
    ltg.setSchedule(sch.schedule)
    
    msgs << "Lighting with #{outside_ann.round} kWhs annual energy consumption has been assigned to the exterior'."
    tot_ltg += outside_ann

    #reporting final condition of model
    if msgs.size > 1
        msgs.each do |msg|
            runner.registerInfo(msg)
        end
        runner.registerFinalCondition("The building has been assigned lighting totaling #{tot_ltg.round} kWhs annual energy consumption across #{units.size} units.")
    elsif msgs.size == 1
        runner.registerFinalCondition(msgs[0])
    else
        runner.registerFinalCondition("No lighting has been assigned.")
    end

    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ResidentialLighting.new.registerWithApplication