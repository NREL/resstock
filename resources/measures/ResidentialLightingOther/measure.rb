# see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

# see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

# see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

resources_path = File.absolute_path(File.join(File.dirname(__FILE__), "../HPXMLtoOpenStudio/resources"))
unless File.exists? resources_path
  resources_path = File.join(OpenStudio::BCLMeasure::userMeasuresDir.to_s, "HPXMLtoOpenStudio/resources") # Hack to run measures in the OS App since applied measures are copied off into a temporary directory
end
require File.join(resources_path, "geometry")
require File.join(resources_path, "weather")
require File.join(resources_path, "lighting")

# start the measure
class ResidentialLightingOther < OpenStudio::Measure::ModelMeasure
  # define the name that a user will see, this method may be deprecated as
  # the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Residential Other Lighting"
  end

  def description
    return "Sets (or replaces) the lighting energy use, based on fractions of CFLs, LFLs, and LEDs, for the garage and outside. For multifamily buildings, the lighting can be set for all units of the building.#{Constants.WorkflowDescription}"
  end

  def modeler_description
    return "Assigns a lighting energy use and schedule to the garage and outside. The lighting schedule, by default, is calculated for the latitude/longitude of the weather location specified in the model."
  end

  # define the arguments that the user will input
  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # make a choice argument for option type
    choices = []
    choices << Constants.OptionTypeLightingFractions
    choices << Constants.OptionTypeLightingEnergyUses
    option_type = OpenStudio::Measure::OSArgument::makeChoiceArgument("option_type", choices, true)
    option_type.setDisplayName("Option Type")
    option_type.setDescription("Inputs are used/ignored below based on the option type specified.")
    option_type.setDefaultValue(Constants.OptionTypeLightingFractions)
    args << option_type

    # make a double argument for hardwired CFL fraction
    hw_cfl = OpenStudio::Measure::OSArgument::makeDoubleArgument("hw_cfl", true)
    hw_cfl.setDisplayName("#{Constants.OptionTypeLightingFractions}: Hardwired Fraction CFL")
    hw_cfl.setDescription("Fraction of all hardwired lamps (garage and exterior) that are compact fluorescent. Hardwired lighting not specified as CFL, LED, or LFL is assumed to be incandescent.")
    hw_cfl.setDefaultValue(0.34)
    args << hw_cfl

    # make a double argument for hardwired LED fraction
    hw_led = OpenStudio::Measure::OSArgument::makeDoubleArgument("hw_led", true)
    hw_led.setDisplayName("#{Constants.OptionTypeLightingFractions}: Hardwired Fraction LED")
    hw_led.setDescription("Fraction of all hardwired lamps (garage and exterior) that are LED. Hardwired lighting not specified as CFL, LED, or LFL is assumed to be incandescent.")
    hw_led.setDefaultValue(0)
    args << hw_led

    # make a double argument for hardwired LFL fraction
    hw_lfl = OpenStudio::Measure::OSArgument::makeDoubleArgument("hw_lfl", true)
    hw_lfl.setDisplayName("#{Constants.OptionTypeLightingFractions}: Hardwired Fraction LFL")
    hw_lfl.setDescription("Fraction of all hardwired lamps (garage and exterior) that are linear fluorescent. Hardwired lighting not specified as CFL, LED, or LFL is assumed to be incandescent.")
    hw_lfl.setDefaultValue(0)
    args << hw_lfl

    # make a double argument for Plugin CFL fraction
    pg_cfl = OpenStudio::Measure::OSArgument::makeDoubleArgument("pg_cfl", true)
    pg_cfl.setDisplayName("#{Constants.OptionTypeLightingFractions}: Plugin Fraction CFL")
    pg_cfl.setDescription("Fraction of all plugin lamps that are compact fluorescent. Plugin lighting not specified as CFL, LED, or LFL is assumed to be incandescent.")
    pg_cfl.setDefaultValue(0.34)
    args << pg_cfl

    # make a double argument for Plugin LED fraction
    pg_led = OpenStudio::Measure::OSArgument::makeDoubleArgument("pg_led", true)
    pg_led.setDisplayName("#{Constants.OptionTypeLightingFractions}: Plugin Fraction LED")
    pg_led.setDescription("Fraction of all plugin lamps that are LED. Plugin lighting not specified as CFL, LED, or LFL is assumed to be incandescent.")
    pg_led.setDefaultValue(0)
    args << pg_led

    # make a double argument for Plugin LFL fraction
    pg_lfl = OpenStudio::Measure::OSArgument::makeDoubleArgument("pg_lfl", true)
    pg_lfl.setDisplayName("#{Constants.OptionTypeLightingFractions}: Plugin Fraction LFL")
    pg_lfl.setDescription("Fraction of all plugin lamps that are linear fluorescent. Plugin lighting not specified as CFL, LED, or LFL is assumed to be incandescent.")
    pg_lfl.setDefaultValue(0)
    args << pg_lfl

    # make a double argument for BA Benchmark multiplier
    mult = OpenStudio::Measure::OSArgument::makeDoubleArgument("mult", true)
    mult.setDisplayName("#{Constants.OptionTypeLightingFractions}: Multiplier")
    mult.setDescription("A multiplier on the national average lighting energy. 0.75 indicates a 25% reduction in the lighting energy, 1.0 indicates the same lighting energy as the national average, 1.25 indicates a 25% increase in the lighting energy, etc.")
    mult.setDefaultValue(1)
    args << mult

    # make a double argument for Incandescent Efficacy
    in_eff = OpenStudio::Measure::OSArgument::makeDoubleArgument("in_eff", true)
    in_eff.setDisplayName("#{Constants.OptionTypeLightingFractions}: Incandescent Efficacy")
    in_eff.setUnits("lm/W")
    in_eff.setDescription("The ratio of light output from an incandescent lamp to the electric power it consumes.")
    in_eff.setDefaultValue(15)
    args << in_eff

    # make a double argument for CFL Efficacy
    cfl_eff = OpenStudio::Measure::OSArgument::makeDoubleArgument("cfl_eff", true)
    cfl_eff.setDisplayName("#{Constants.OptionTypeLightingFractions}: CFL Efficacy")
    cfl_eff.setUnits("lm/W")
    cfl_eff.setDescription("The ratio of light output from a CFL lamp to the electric power it consumes.")
    cfl_eff.setDefaultValue(55)
    args << cfl_eff

    # make a double argument for LED Efficacy
    led_eff = OpenStudio::Measure::OSArgument::makeDoubleArgument("led_eff", true)
    led_eff.setDisplayName("#{Constants.OptionTypeLightingFractions}: LED Efficacy")
    led_eff.setUnits("lm/W")
    led_eff.setDescription("The ratio of light output from a LED lamp to the electric power it consumes.")
    led_eff.setDefaultValue(80)
    args << led_eff

    # make a double argument for LFL Efficacy
    lfl_eff = OpenStudio::Measure::OSArgument::makeDoubleArgument("lfl_eff", true)
    lfl_eff.setDisplayName("#{Constants.OptionTypeLightingFractions}: LFL Efficacy")
    lfl_eff.setUnits("lm/W")
    lfl_eff.setDescription("The ratio of light output from a LFL lamp to the electric power it consumes.")
    lfl_eff.setDefaultValue(88)
    args << lfl_eff

    # make a double argument for garage energy use
    energy_use_garage = OpenStudio::Measure::OSArgument::makeDoubleArgument("energy_use_garage", true)
    energy_use_garage.setDisplayName("#{Constants.OptionTypeLightingEnergyUses}: Garage")
    energy_use_garage.setUnits("kWh/year")
    energy_use_garage.setDescription("Total garage annual lighting energy use. Only applied if there is a garage space.")
    energy_use_garage.setDefaultValue(100)
    args << energy_use_garage

    # make a double argument for exterior energy use
    energy_use_exterior = OpenStudio::Measure::OSArgument::makeDoubleArgument("energy_use_exterior", true)
    energy_use_exterior.setDisplayName("#{Constants.OptionTypeLightingEnergyUses}: Exterior")
    energy_use_exterior.setUnits("kWh/year")
    energy_use_exterior.setDescription("Total exterior annual lighting energy use.")
    energy_use_exterior.setDefaultValue(300)
    args << energy_use_exterior

    # make a choice argument for option type
    choices = []
    choices << Constants.OptionTypeLightingScheduleCalculated
    choices << Constants.OptionTypeLightingScheduleUserSpecified
    sch_option_type = OpenStudio::Measure::OSArgument::makeChoiceArgument("sch_option_type", choices, true)
    sch_option_type.setDisplayName("Schedule Option Type")
    sch_option_type.setDescription("Inputs are used/ignored below based on the option type specified.")
    sch_option_type.setDefaultValue(Constants.OptionTypeLightingScheduleCalculated)
    args << sch_option_type

    # Make a string argument for 24 weekday schedule values
    weekday_sch = OpenStudio::Measure::OSArgument::makeStringArgument("weekday_sch", true)
    weekday_sch.setDisplayName("Weekday schedule")
    weekday_sch.setDescription("Specify the 24-hour weekday schedule.")
    # schedule from T24 2016 Residential ACM Appendix C Table 8 Exterior Lighting Hourly Multiplier (Weekdays)
    weekday_sch.setDefaultValue("0.046, 0.046, 0.046, 0.046, 0.046, 0.037, 0.035, 0.034, 0.033, 0.028, 0.022, 0.015, 0.012, 0.011, 0.011, 0.012, 0.019, 0.037, 0.049, 0.065, 0.091, 0.105, 0.091, 0.063")
    args << weekday_sch

    # Make a string argument for 24 weekend schedule values
    weekend_sch = OpenStudio::Measure::OSArgument::makeStringArgument("weekend_sch", true)
    weekend_sch.setDisplayName("Weekend schedule")
    weekend_sch.setDescription("Specify the 24-hour weekend schedule.")
    # schedule from T24 2016 Residential ACM Appendix C Table 8 Exterior Lighting Hourly Multiplier (Weekends)
    weekend_sch.setDefaultValue("0.046, 0.046, 0.045, 0.045, 0.046, 0.045, 0.044, 0.041, 0.036, 0.03, 0.024, 0.016, 0.012, 0.011, 0.011, 0.012, 0.019, 0.038, 0.048, 0.06, 0.083, 0.098, 0.085, 0.059")
    args << weekend_sch

    # Make a string argument for 12 monthly schedule values
    monthly_sch = OpenStudio::Measure::OSArgument::makeStringArgument("monthly_sch", true)
    monthly_sch.setDisplayName("Month schedule")
    monthly_sch.setDescription("Specify the 12-month schedule.")
    monthly_sch.setDefaultValue("1.248, 1.257, 0.993, 0.989, 0.993, 0.827, 0.821, 0.821, 0.827, 0.99, 0.987, 1.248")
    args << monthly_sch

    # make a double argument for exterior energy use during holiday period
    holiday_daily_energy_use_exterior = OpenStudio::Measure::OSArgument::makeDoubleArgument("holiday_daily_energy_use_exterior", true)
    holiday_daily_energy_use_exterior.setDisplayName("#{Constants.OptionTypeLightingEnergyUses}: Holiday Exterior")
    holiday_daily_energy_use_exterior.setUnits("kWh/day")
    holiday_daily_energy_use_exterior.setDescription("Daily exterior lighting energy use during holiday period.")
    holiday_daily_energy_use_exterior.setDefaultValue(0)
    args << holiday_daily_energy_use_exterior

    # make a string argument for start date of the holiday period
    holiday_start_date = OpenStudio::Measure::OSArgument.makeStringArgument("holiday_start_date", true)
    holiday_start_date.setDisplayName("Holiday Period Start Date")
    holiday_start_date.setDescription("Date of the start of the holiday period.")
    holiday_start_date.setDefaultValue("November 27")
    args << holiday_start_date

    # make a string argument for end date of the holiday period
    holiday_end_date = OpenStudio::Measure::OSArgument.makeStringArgument("holiday_end_date", true)
    holiday_end_date.setDisplayName("Holiday Period End Date")
    holiday_end_date.setDescription("Date of the end of the holiday period.")
    holiday_end_date.setDefaultValue("January 6")
    args << holiday_end_date

    # Make a string argument for 24 holiday period schedule values
    holiday_sch = OpenStudio::Measure::OSArgument::makeStringArgument("holiday_sch", true)
    holiday_sch.setDisplayName("Holiday schedule")
    holiday_sch.setDescription("Specify the 24-hour holiday schedule.")
    holiday_sch.setDefaultValue("0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.008168, 0.098016, 0.168028, 0.193699, 0.283547, 0.192532, 0.03734, 0.01867")
    args << holiday_sch

    return args
  end # end the arguments method

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # assign the user inputs to variables
    option_type = runner.getStringArgumentValue("option_type", user_arguments)
    hw_cfl = runner.getDoubleArgumentValue("hw_cfl", user_arguments)
    hw_led = runner.getDoubleArgumentValue("hw_led", user_arguments)
    hw_lfl = runner.getDoubleArgumentValue("hw_lfl", user_arguments)
    pg_cfl = runner.getDoubleArgumentValue("pg_cfl", user_arguments)
    pg_led = runner.getDoubleArgumentValue("pg_led", user_arguments)
    pg_lfl = runner.getDoubleArgumentValue("pg_lfl", user_arguments)
    mult = runner.getDoubleArgumentValue("mult", user_arguments)
    in_eff = runner.getDoubleArgumentValue("in_eff", user_arguments)
    cfl_eff = runner.getDoubleArgumentValue("cfl_eff", user_arguments)
    led_eff = runner.getDoubleArgumentValue("led_eff", user_arguments)
    lfl_eff = runner.getDoubleArgumentValue("lfl_eff", user_arguments)
    energy_use_garage = runner.getDoubleArgumentValue("energy_use_garage", user_arguments)
    energy_use_exterior = runner.getDoubleArgumentValue("energy_use_exterior", user_arguments)
    sch_option_type = runner.getStringArgumentValue("sch_option_type", user_arguments)
    weekday_sch = runner.getStringArgumentValue("weekday_sch", user_arguments)
    weekend_sch = runner.getStringArgumentValue("weekend_sch", user_arguments)
    monthly_sch = runner.getStringArgumentValue("monthly_sch", user_arguments)
    holiday_daily_energy_use_exterior = runner.getDoubleArgumentValue("holiday_daily_energy_use_exterior", user_arguments)
    holiday_start_date = runner.getStringArgumentValue("holiday_start_date", user_arguments)
    holiday_end_date = runner.getStringArgumentValue("holiday_end_date", user_arguments)
    holiday_sch = runner.getStringArgumentValue("holiday_sch", user_arguments)

    # Check for valid inputs
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
      if mult < 0
        runner.registerError("Lamps used multiplier must be greater than or equal to 0.")
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
      if energy_use_garage < 0
        runner.registerError("#{Constants.OptionTypeLightingEnergyUses}: Garage must be greater than or equal to 0.")
        return false
      end
      if energy_use_exterior < 0
        runner.registerError("#{Constants.OptionTypeLightingEnergyUses}: Exterior must be greater than or equal to 0.")
        return false
      end
      if holiday_daily_energy_use_exterior < 0
        runner.registerError("#{Constants.OptionTypeLightingEnergyUses}: Holiday Exterior must be greater than or equal to 0.")
        return false
      end
    end

    # Get building units
    units = Geometry.get_building_units(model, runner)
    if units.nil?
      return false
    end

    # Calculate the lighting schedule
    weather = WeatherProcess.new(model, runner)
    if weather.error?
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
    smrt_replace_f = (0.1672 * hw_inc**4 - 0.4817 * hw_inc**3 + 0.6336 * hw_inc**2 - 0.492 * hw_inc + 1.1561)

    Lighting.remove_other(model, runner)

    tot_ltg_e = 0
    msgs = []
    sch = nil

    # Garage lighting (garages not associated with a unit)
    garage_spaces = Geometry.get_garage_spaces(model.getSpaces)
    gfa = Geometry.get_floor_area_from_spaces(garage_spaces)
    if option_type == Constants.OptionTypeLightingEnergyUses
      garage_ann = energy_use_garage
    elsif option_type == Constants.OptionTypeLightingFractions
      common_bm_garage_e = mult * (0.08 * gfa + 8 * units.size)
      garage_ann = (common_bm_garage_e * (((hw_inc * er_inc + (1 - bab_frac_inc) * bab_er_inc) + (hw_cfl * er_cfl - bab_frac_cfl * bab_er_cfl) + (hw_led * er_led - bab_frac_led * bab_er_led) + (hw_lfl * er_lfl - bab_frac_lfl * bab_er_lfl)) * smrt_replace_f * 0.9 + 0.1))
    end

    success = Lighting.apply_garage(model, runner, weather, sch, garage_ann, sch_option_type, weekday_sch, weekend_sch, monthly_sch)
    return false if not success

    if garage_spaces.length > 0
      msgs << "Lighting with #{garage_ann.round} kWhs annual energy consumption has been assigned to the garage(s)."
      tot_ltg_e += garage_ann
    end

    # Exterior Lighting
    exterior_ann = 0
    if option_type == Constants.OptionTypeLightingEnergyUses
      exterior_ann = energy_use_exterior
    elsif option_type == Constants.OptionTypeLightingFractions
      total_ffa = Geometry.get_finished_floor_area_from_spaces(model.getSpaces, runner)
      bm_outside_e = mult * (0.145 * total_ffa)
      exterior_ann = (bm_outside_e * (((hw_inc * er_inc + (1 - bab_frac_inc) * bab_er_inc) + (hw_cfl * er_cfl - bab_frac_cfl * bab_er_cfl) + (hw_led * er_led - bab_frac_led * bab_er_led) + (hw_lfl * er_lfl - bab_frac_lfl * bab_er_lfl)) * smrt_replace_f * 0.9 + 0.1))
    end

    success = Lighting.apply_exterior(model, runner, weather, sch, exterior_ann, sch_option_type, weekday_sch, weekend_sch, monthly_sch)
    return false if not success

    msgs << "Lighting with #{exterior_ann.round} kWhs annual energy consumption has been assigned to the exterior."
    tot_ltg_e += exterior_ann

    # Exterior Holiday Lighting
    if holiday_daily_energy_use_exterior > 0
      year_description = model.getYearDescription
      assumed_year = year_description.assumedYear

      months = { "January" => 1, "February" => 2, "March" => 3, "April" => 4, "May" => 5, "June" => 6, "July" => 7, "August" => 8, "September" => 9, "October" => 10, "November" => 11, "December" => 12 }
      holiday_start_month = months[holiday_start_date.split[0]]
      holiday_end_month = months[holiday_end_date.split[0]]

      if holiday_start_month.nil? or holiday_end_month.nil?
        runner.registerError("Invalid holiday period month(s) entered.")
        return false
      end

      holiday_start_day = holiday_start_date.split[1].to_i
      holiday_end_day = holiday_end_date.split[1].to_i

      begin
        holiday_start = Time.new(assumed_year, holiday_start_month, holiday_start_day)
        holiday_end = Time.new(assumed_year, holiday_end_month, holiday_end_day)
      rescue
        runner.registerError("Invalid holiday period date(s) entered.")
        return false
      end

      holiday_periods = []
      if holiday_start < holiday_end # contiguous holiday
        num_holiday_seconds = (holiday_end - holiday_start)

        holiday_s = OpenStudio::Date.new(OpenStudio::MonthOfYear.new(holiday_start.month), holiday_start.day, holiday_start.year)
        holiday_e = OpenStudio::Date.new(OpenStudio::MonthOfYear.new(holiday_end.month), holiday_end.day, holiday_end.year)
        holiday_periods << [holiday_s, holiday_e]
      else # non contiguous holiday
        num_holiday_seconds = (holiday_end - Time.new(assumed_year)) + (Time.new(assumed_year + 1) - holiday_start)

        holiday_s = OpenStudio::Date.new(OpenStudio::MonthOfYear.new(1), 1, assumed_year)
        holiday_e = OpenStudio::Date.new(OpenStudio::MonthOfYear.new(holiday_end.month), holiday_end.day, holiday_end.year)
        holiday_periods << [holiday_s, holiday_e]

        holiday_s = OpenStudio::Date.new(OpenStudio::MonthOfYear.new(holiday_start.month), holiday_start.day, holiday_start.year)
        holiday_e = OpenStudio::Date.new(OpenStudio::MonthOfYear.new(12), 31, assumed_year)
        holiday_periods << [holiday_s, holiday_e]
      end
      num_holiday_days = (num_holiday_seconds / 3600 / 24).to_i + 1

      success = Lighting.apply_exterior_holiday(model, runner, holiday_daily_energy_use_exterior, holiday_periods, holiday_sch)
      return false if not success

      msgs << "Holiday lighting with #{(num_holiday_days * holiday_daily_energy_use_exterior).round} kWhs annual energy consumption has been assigned to the exterior from #{holiday_start_date} until #{holiday_end_date}."
      tot_ltg_e += (num_holiday_days * holiday_daily_energy_use_exterior)
    end

    # reporting final condition of model
    if msgs.size > 1
      msgs.each do |msg|
        runner.registerInfo(msg)
      end
      runner.registerFinalCondition("The building has been assigned garage and exterior lighting totaling #{tot_ltg_e.round} kWhs annual energy consumption across #{units.size} units.")
    elsif msgs.size == 1
      runner.registerFinalCondition(msgs[0])
    else
      runner.registerFinalCondition("No garage or exterior lighting has been assigned.")
    end

    return true
  end # end the run method
end # end the measure

# this allows the measure to be use by the application
ResidentialLightingOther.new.registerWithApplication
