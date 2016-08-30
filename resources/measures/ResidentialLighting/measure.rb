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
class ResidentialLighting < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Residential Lighting"
  end
  
  def description
    return "Sets (or replaces) the lighting energy use, based on fractions of CFLs, LFLs, and LEDs, for finished spaces, the garage, and outside."
  end
  
  def modeler_description
    return "Assigns a lighting energy use and schedule to finished spaces, the garage, and outside. The lighting schedule is calculated for the latitude/longitude of the weather location specified in the model."
  end
  
  #define the arguments that the user will input
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new
    
    #make a double argument for hardwired CFL fraction
    hw_cfl = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("hw_cfl",true)
    hw_cfl.setDisplayName("Hardwired Fraction CFL")
    hw_cfl.setDescription("Fraction of all hardwired lamps (interior, garage, and exterior) that are compact fluorescent. Hardwired lighting not specified as CFL, LED, or LFL is assumed to be incandescent.")
    hw_cfl.setDefaultValue(0.34)
    args << hw_cfl
    
    #make a double argument for hardwired LED fraction
    hw_led = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("hw_led",true)
    hw_led.setDisplayName("Hardwired Fraction LED")
    hw_led.setDescription("Fraction of all hardwired lamps (interior, garage, and exterior) that are LED. Hardwired lighting not specified as CFL, LED, or LFL is assumed to be incandescent.")
    hw_led.setDefaultValue(0)
    args << hw_led
    
    #make a double argument for hardwired LFL fraction
    hw_lfl = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("hw_lfl",true)
    hw_lfl.setDisplayName("Hardwired Fraction LFL")
    hw_lfl.setDescription("Fraction of all hardwired lamps (interior, garage, and exterior) that are linear fluorescent. Hardwired lighting not specified as CFL, LED, or LFL is assumed to be incandescent.")
    hw_lfl.setDefaultValue(0)
    args << hw_lfl
    
    #make a double argument for Plugin CFL fraction
    pg_cfl = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("pg_cfl",true)
    pg_cfl.setDisplayName("Plugin Fraction CFL")
    pg_cfl.setDescription("Fraction of all plugin lamps that are compact fluorescent. Plugin lighting not specified as CFL, LED, or LFL is assumed to be incandescent.")
    pg_cfl.setDefaultValue(0.34)
    args << pg_cfl
    
    #make a double argument for Plugin LED fraction
    pg_led = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("pg_led",true)
    pg_led.setDisplayName("Plugin Fraction LED")
    pg_led.setDescription("Fraction of all plugin lamps that are LED. Plugin lighting not specified as CFL, LED, or LFL is assumed to be incandescent.")
    pg_led.setDefaultValue(0)
    args << pg_led
    
    #make a double argument for Plugin LFL fraction
    pg_lfl = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("pg_lfl",true)
    pg_lfl.setDisplayName("Plugin Fraction LFL")
    pg_lfl.setDescription("Fraction of all plugin lamps that are linear fluorescent. Plugin lighting not specified as CFL, LED, or LFL is assumed to be incandescent.")
    pg_lfl.setDefaultValue(0)
    args << pg_lfl
    
    #make a double argument for Incandescent Efficacy
    in_eff = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("in_eff",true)
    in_eff.setDisplayName("Incandescent Efficacy")
    in_eff.setUnits("lm/W")
    in_eff.setDescription("The ratio of light output from an incandescent lamp to the electric power it consumes.")
    in_eff.setDefaultValue(15)
    args << in_eff
    
    #make a double argument for CFL Efficacy
    cfl_eff = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("cfl_eff",true)
    cfl_eff.setDisplayName("CFL Efficacy")
    cfl_eff.setUnits("lm/W")
    cfl_eff.setDescription("The ratio of light output from a CFL lamp to the electric power it consumes.")
    cfl_eff.setDefaultValue(55)
    args << cfl_eff
    
    #make a double argument for LED Efficacy
    led_eff = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("led_eff",true)
    led_eff.setDisplayName("LED Efficacy")
    led_eff.setUnits("lm/W")
    led_eff.setDescription("The ratio of light output from a LED lamp to the electric power it consumes.")
    led_eff.setDefaultValue(80)
    args << led_eff
    
    #make a double argument for LFL Efficacy
    lfl_eff = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("lfl_eff",true)
    lfl_eff.setDisplayName("LFL Efficacy")
    lfl_eff.setUnits("lm/W")
    lfl_eff.setDescription("The ratio of light output from a LFL lamp to the electric power it consumes.")
    lfl_eff.setDefaultValue(88)
    args << lfl_eff

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
    
    #Check for valid inputs
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

    # Get FFA and garage floor area
    ffa = Geometry.get_building_finished_floor_area(model, runner)
    if ffa.nil?
        return false
    end
    gfa = Geometry.get_building_garage_floor_area(model)
    
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

    # Annual BA Benchmark lighting energy calcs
    bm_hw_e = frac_hw * (ffa * 0.542 + 334)
    bm_pg_e = frac_pg * (ffa * 0.542 + 334)

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
    smrt_replce_f = (0.1672 * hw_inc ** 4 - 0.4817 * hw_inc ** 3 + 0.6336 * hw_inc ** 2 - 0.492 * hw_inc + 1.1561)
    
    # Interior lighting
    int_hw_e = (bm_hw_e * (((hw_inc * er_inc + (1 - bab_frac_inc) * bab_er_inc) + (hw_cfl * er_cfl - bab_frac_cfl * bab_er_cfl) + (hw_led * er_led - bab_frac_led * bab_er_led) + (hw_lfl * er_lfl - bab_frac_lfl * bab_er_lfl)) * smrt_replce_f * 0.9 + 0.1))
    int_pg_e = (bm_pg_e * (((pg_inc * er_inc + (1 - bab_frac_inc) * bab_er_inc) + (pg_cfl * er_cfl - bab_frac_cfl * bab_er_cfl) + (pg_led * er_led - bab_frac_led * bab_er_led) + (pg_lfl * er_lfl - bab_frac_lfl * bab_er_lfl)) * smrt_replce_f * 0.9 + 0.1))
    ltg_ann = int_hw_e + int_pg_e
    ltg_daily = ltg_ann / 365.0
    
    # Garage lighting
    if gfa > 0
        bm_garage_e =  0.08 * gfa + 8
        garage_ann = (bm_garage_e * (((hw_inc * er_inc + (1 - bab_frac_inc) * bab_er_inc) + (hw_cfl * er_cfl - bab_frac_cfl * bab_er_cfl) + (hw_led * er_led - bab_frac_led * bab_er_led) + (hw_lfl * er_lfl - bab_frac_lfl * bab_er_lfl)) * smrt_replce_f * 0.9 + 0.1))
        garage_daily = garage_ann / 365.0
    else
        garage_ann = 0.0 
        garage_daily = 0.0
    end
    
    # Exterior lighting
    bm_outside_e = 0.145 * ffa
    outside_ann = (bm_outside_e * (((hw_inc * er_inc + (1 - bab_frac_inc) * bab_er_inc) + (hw_cfl * er_cfl - bab_frac_cfl * bab_er_cfl) + (hw_led * er_led - bab_frac_led * bab_er_led) + (hw_lfl * er_lfl - bab_frac_lfl * bab_er_lfl)) * smrt_replce_f * 0.9 + 0.1))
    outside_daily = outside_ann / 365.0

    # Total lighting
    ltg_total = ltg_ann + garage_ann + outside_ann
    
    # Calculate the lighting schedule
    weather = WeatherProcess.new(model, runner, File.dirname(__FILE__), header_only=true)
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
        monthHalfHourKWHs = []
        # Calculate hour 12.5 first; others depend on it
        monthHalfHourKWHs[24] = june_kws[24] + ((dec_kws[24] - june_kws[24]) / 2.0 / 0.266 * (1.0 / 1.5 / ((2.0*pi)**0.5)) * Math.exp(-0.5 * (((6 - monthNum).abs - 6) / 1.5)**2)) + ((dec_kws[24] - june_kws[24]) / 2 / 0.399 * (1 / 1 / ((2 * pi)**0.5)) * Math.exp(-0.5 * (((4.847 - sunrise_hour[month]).abs - 3.2) / 1.0)**2))
        for hourNum in 0..10
            monthHalfHourKWHs[hourNum] = june_kws[hourNum]
        end
        for hourNum in 11..16
            hour = (hourNum + 1.0) * 0.5
            monthHalfHourKWHs[hourNum] = june_kws[11] + 0.005 * (sunrise_hour[month] - 3.0)**2.4 * Math.exp(-1.0 * ((hour - 8.0)**2) / (2.0 * 0.8**2)) / (0.8 * (2.0 * pi)**0.5)
        end
        for hourNum in 16..24
            hour = (hourNum + 1.0) * 0.5
            monthHalfHourKWHs[hourNum] = monthHalfHourKWHs[24] + 0.005 * (sunrise_hour[month] - 3.0)**2.4 * Math.exp(-1.0 * ((hour - 8.0)**2) / (2.0 * 0.8**2.0)) / (0.8 * (2.0 * pi)**0.5)
        end
        for hourNum in 25..38
            hour = (hourNum + 1.0) * 0.5
            monthHalfHourKWHs[hourNum] = (monthHalfHourKWHs[24] + amplConst1 * Math.exp((-1.0 * (hour - (sunset_hour[month] + sunsetLag1))**2) / (2.0 * ((25.5 / ((6.5 - monthNum).abs + 20.0)) * stdDevCons1)**2)) / ((25.5 / ((6.5 - monthNum).abs + 20.0)) * stdDevCons1 * (2.0*pi)**0.5))
        end
        for hourNum in 38..44
            hour = (hourNum + 1.0) * 0.5
            temp1 = (monthHalfHourKWHs[24] + amplConst1 * Math.exp((-1.0 * (hour - (sunset_hour[month] + sunsetLag1))**2) / (2.0 * ((25.5 / ((6.5 - monthNum).abs + 20.0)) * stdDevCons1)**2)) / ((25.5 / ((6.5 - monthNum).abs + 20.0)) * stdDevCons1 * (2.0*pi)**0.5))
            temp2 = (0.04 + amplConst2 * Math.exp((-1.0 * (hour - (sunsetLag2))**2) / (2.0 * (stdDevCons2)**2)) / (stdDevCons2 * (2.0*pi)**0.5))
            if sunsetLag2 < sunset_hour[month] + sunsetLag1
                monthHalfHourKWHs[hourNum] = [temp1, temp2].min
            else
                monthHalfHourKWHs[hourNum] = [temp1, temp2].max
            end
        end
        for hourNum in 44..48
            hour = (hourNum + 1) * 0.5
            monthHalfHourKWHs[hourNum] = (0.04 + amplConst2 * Math.exp((-1 * (hour - (sunsetLag2))**2) / (2 * (stdDevCons2)**2)) / (stdDevCons2 * (2*pi)**0.5))
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
    ltg_max = 0.0
    for month in 0..11
        for hour in 0..23
            lighting_sch[month][hour] = normalized_monthly_lighting[month]*normalized_hourly_lighting[month][hour]*ltg_ann/days_m[month]
            if lighting_sch[month][hour].to_f > ltg_max
                ltg_max = lighting_sch[month][hour].to_f
                if gfa > 0
                    grg_max = normalized_monthly_lighting[month]*normalized_hourly_lighting[month][hour]*garage_ann/days_m[month]
                end
                outside_max = normalized_monthly_lighting[month]*normalized_hourly_lighting[month][hour]*outside_ann/days_m[month]
            end
        end
    end
    
    
    # Remove all existing lighting
    ltg_removed = false
    model.getExteriorLightss.each do |exterior_light|
        exterior_light.remove
        ltg_removed = true
    end
    model.getLightss.each do |light|
        light.remove
        ltg_removed = true
    end
    if ltg_removed
        runner.registerInfo("Removed existing interior/exterior lighting.")
    end

    obj_name = Constants.ObjectNameLighting
    sch = HourlyByMonthSchedule.new(model, runner, obj_name + " schedule", lighting_sch, lighting_sch)
    if not sch.validated?
        return false
    end
    
    finished_spaces = Geometry.get_finished_spaces(model)
    garage_spaces = Geometry.get_garage_spaces(model)
    outside = 'outside'
    
    (finished_spaces + garage_spaces + [outside]).each do |space|
        if space.is_a?(String)
            space_design_level = sch.calcDesignLevel(outside_max)
            obj_name_space = "#{obj_name} #{outside}"
        elsif finished_spaces.include?(space)
            space_design_level = sch.calcDesignLevel(ltg_max) * OpenStudio.convert(space.floorArea, "m^2", "ft^2").get / ffa
            obj_name_space = "#{obj_name} #{space.name.to_s}"
        elsif garage_spaces.include?(space)
            space_design_level = sch.calcDesignLevel(grg_max) * OpenStudio.convert(space.floorArea, "m^2", "ft^2").get / gfa
            obj_name_space = "#{obj_name} #{space.name.to_s}"
        end
        
        if space.is_a?(String)
            # Add exterior lighting
            ltg_def = OpenStudio::Model::ExteriorLightsDefinition.new(model)
            ltg = OpenStudio::Model::ExteriorLights.new(ltg_def)
            ltg.setName(obj_name_space)
            ltg_def.setName(obj_name_space)
            ltg_def.setDesignLevel(space_design_level)
            sch.setSchedule(ltg)
        else
            # Add lighting
            ltg_def = OpenStudio::Model::LightsDefinition.new(model)
            ltg = OpenStudio::Model::Lights.new(ltg_def)
            ltg.setName(obj_name_space)
            ltg.setSpace(space)
            ltg_def.setName(obj_name_space)
            ltg_def.setLightingLevel(space_design_level)
            ltg_def.setFractionRadiant(0.6)
            ltg_def.setFractionVisible(0.2)
            ltg_def.setReturnAirFraction(0.0)
            sch.setSchedule(ltg)
        end
    end

    #reporting final condition of model
    garage_str = ""
    if garage_ann > 0
        garage_str = ", #{garage_ann.round} kWhs garage,"
    end
    runner.registerFinalCondition("Lighting has been set with #{ltg_total.round} kWhs annual energy consumption (#{ltg_ann.round} kWhs interior#{garage_str} and #{outside_ann.round} kWhs exterior).")
    
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ResidentialLighting.new.registerWithApplication