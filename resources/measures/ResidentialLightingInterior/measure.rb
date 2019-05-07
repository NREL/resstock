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
class ResidentialLightingInterior < OpenStudio::Measure::ModelMeasure
  # define the name that a user will see, this method may be deprecated as
  # the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Residential Interior Lighting"
  end

  def description
    return "Sets (or replaces) the lighting energy use, based on fractions of CFLs, LFLs, and LEDs, for finished spaces. For multifamily buildings, the lighting can be set for all units of the building.#{Constants.WorkflowDescription}"
  end

  def modeler_description
    return "Assigns a lighting energy use and schedule to finished spaces. The lighting schedule, by default, is calculated for the latitude/longitude of the weather location specified in the model."
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
    hw_cfl.setDescription("Fraction of all hardwired lamps (interior) that are compact fluorescent. Hardwired lighting not specified as CFL, LED, or LFL is assumed to be incandescent.")
    hw_cfl.setDefaultValue(0.34)
    args << hw_cfl

    # make a double argument for hardwired LED fraction
    hw_led = OpenStudio::Measure::OSArgument::makeDoubleArgument("hw_led", true)
    hw_led.setDisplayName("#{Constants.OptionTypeLightingFractions}: Hardwired Fraction LED")
    hw_led.setDescription("Fraction of all hardwired lamps (interior) that are LED. Hardwired lighting not specified as CFL, LED, or LFL is assumed to be incandescent.")
    hw_led.setDefaultValue(0)
    args << hw_led

    # make a double argument for hardwired LFL fraction
    hw_lfl = OpenStudio::Measure::OSArgument::makeDoubleArgument("hw_lfl", true)
    hw_lfl.setDisplayName("#{Constants.OptionTypeLightingFractions}: Hardwired Fraction LFL")
    hw_lfl.setDescription("Fraction of all hardwired lamps (interior) that are linear fluorescent. Hardwired lighting not specified as CFL, LED, or LFL is assumed to be incandescent.")
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

    # make a double argument for interior energy use
    energy_use_interior = OpenStudio::Measure::OSArgument::makeDoubleArgument("energy_use_interior", true)
    energy_use_interior.setDisplayName("#{Constants.OptionTypeLightingEnergyUses}: Interior")
    energy_use_interior.setUnits("kWh/year")
    energy_use_interior.setDescription("Total interior annual lighting energy use (excluding garages).")
    energy_use_interior.setDefaultValue(900)
    args << energy_use_interior

    # make a choice argument for option type
    choices = []
    choices << Constants.OptionTypeLightingScheduleCalculated
    choices << Constants.OptionTypeLightingScheduleUserSpecified
    sch_option_type = OpenStudio::Measure::OSArgument::makeChoiceArgument("sch_option_type", choices, true)
    sch_option_type.setDisplayName("Schedule Option Type")
    sch_option_type.setDescription("Inputs are used/ignored below based on the option type specified.")
    sch_option_type.setDefaultValue(Constants.OptionTypeLightingScheduleCalculated)
    args << sch_option_type

    # Make a string argument for 12 monthly schedule values
    monthly_sch = OpenStudio::Measure::OSArgument::makeStringArgument("monthly_sch", true)
    monthly_sch.setDisplayName("Month schedule")
    monthly_sch.setDescription("Specify the 12-month schedule.")
    monthly_sch.setDefaultValue("1.248, 1.257, 0.993, 0.989, 0.993, 0.827, 0.821, 0.821, 0.827, 0.99, 0.987, 1.248")
    args << monthly_sch

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
    energy_use_interior = runner.getDoubleArgumentValue("energy_use_interior", user_arguments)
    sch_option_type = runner.getStringArgumentValue("sch_option_type", user_arguments)
    monthly_sch = runner.getStringArgumentValue("monthly_sch", user_arguments)

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
      if energy_use_interior < 0
        runner.registerError("#{Constants.OptionTypeLightingEnergyUses}: Interior must be greater than or equal to 0.")
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

    Lighting.remove_interior(model, runner)

    tot_ltg_e = 0
    msgs = []
    sch = nil
    units.each do |unit|
      # Interior lighting
      unit_finished_spaces = Geometry.get_finished_spaces(unit.spaces)
      ffa = Geometry.get_finished_floor_area_from_spaces(unit.spaces, runner)
      if ffa.nil?
        return false
      end

      if option_type == Constants.OptionTypeLightingEnergyUses
        interior_ann = energy_use_interior
      elsif option_type == Constants.OptionTypeLightingFractions
        bm_hw_e = mult * frac_hw * (ffa * 0.542 + 334)
        bm_pg_e = mult * frac_pg * (ffa * 0.542 + 334)
        int_hw_e = (bm_hw_e * (((hw_inc * er_inc + (1 - bab_frac_inc) * bab_er_inc) + (hw_cfl * er_cfl - bab_frac_cfl * bab_er_cfl) + (hw_led * er_led - bab_frac_led * bab_er_led) + (hw_lfl * er_lfl - bab_frac_lfl * bab_er_lfl)) * smrt_replace_f * 0.9 + 0.1))
        int_pg_e = (bm_pg_e * (((pg_inc * er_inc + (1 - bab_frac_inc) * bab_er_inc) + (pg_cfl * er_cfl - bab_frac_cfl * bab_er_cfl) + (pg_led * er_led - bab_frac_led * bab_er_led) + (pg_lfl * er_lfl - bab_frac_lfl * bab_er_lfl)) * smrt_replace_f * 0.9 + 0.1))
        interior_ann = int_hw_e + int_pg_e
      end

      success, sch = Lighting.apply_interior(model, unit, runner, weather, sch, interior_ann, sch_option_type, monthly_sch)
      return false if not success

      msgs << "Lighting with #{interior_ann.round} kWhs annual energy consumption has been assigned to unit '#{unit.name.to_s}'."
      tot_ltg_e += interior_ann
    end

    # reporting final condition of model
    if msgs.size > 1
      msgs.each do |msg|
        runner.registerInfo(msg)
      end
      runner.registerFinalCondition("The building has been assigned interior lighting totaling #{tot_ltg_e.round} kWhs annual energy consumption across #{units.size} units.")
    elsif msgs.size == 1
      runner.registerFinalCondition(msgs[0])
    else
      runner.registerFinalCondition("No interior lighting has been assigned.")
    end

    return true
  end # end the run method
end # end the measure

# this allows the measure to be use by the application
ResidentialLightingInterior.new.registerWithApplication
