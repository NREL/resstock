# frozen_string_literal: true

# see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

# see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

# see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

resources_path = File.absolute_path(File.join(File.dirname(__FILE__), '../HPXMLtoOpenStudio/resources'))
unless File.exist? resources_path
  resources_path = File.join(OpenStudio::BCLMeasure::userMeasuresDir.to_s, 'HPXMLtoOpenStudio/resources') # Hack to run measures in the OS App since applied measures are copied off into a temporary directory
end

require File.join(resources_path, "constants")
require File.join(resources_path, "weather")
require File.join(resources_path, "hvac")
require File.join(resources_path, "schedules")
require File.join(resources_path, "geometry")
require File.join(resources_path, "appliances")
require File.join(File.dirname(__FILE__), "./schedule_modifier.rb")

# start the measure
class DemandResponseSchedule < OpenStudio::Measure::ModelMeasure
  # define the name that a user will see, this method may be deprecated as
  # the display name in PAT comes from the name field in measure.xml
  def name
    return 'Set Demand Response Schedule'
  end

  def description
    return "This measure alters the thermostat setpoints based on inputted offset magnitudes and schedules of demand-response signals.#{Constants.WorkflowDescription}"
  end

  def modeler_description
    return 'This measure applies hourly demand response controls to existing heating and cooling temperature setpoint schedules. Up to two user-defined DR schedules are inputted as csvs for heating and/or cooling to indicate specific hours of setup and setback. The csvs should contain a value of -1, 0, or 1 for every hour of the simulation period or for an entire year. Offset magnitudes for heating and cooling are also specified by the user, which is multiplied by each row of the DR schedules to generate an hourly offset schedule on-the-fly. The existing cooling and heating setpoint schedules are fetched from the model object, restructured as an hourly schedule for the simulation period, and summed with their respective hourly offset schedules. These new hourly setpoint schedules are assigned to the thermostat object in every zone. Future development of this measure may include on/off DR schedules for appliances or use with water heaters.'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # make an argument for hourly DR schedule directory
    dr_directory = OpenStudio::Measure::OSArgument::makeStringArgument('dr_directory', true)
    dr_directory.setDisplayName('Demand Response Schedule Directory')
    dr_directory.setDescription('Absolute or relative directory that contains the DR csv files')
    dr_directory.setDefaultValue('../HPXMLtoOpenStudio/resources')
    args << dr_directory

    # make an argument for hourly DR schedule csv file (must be same length as simulation period)
    dr_schedule_heat = OpenStudio::Measure::OSArgument::makeStringArgument('dr_schedule_heat', true)
    dr_schedule_heat.setDisplayName('Heating Setpoint DR Schedule File Name')
    dr_schedule_heat.setDescription('File name of the csv that contains hourly DR signals of -1, 0, or 1 for the heating setpoint schedule.')
    dr_schedule_heat.setDefaultValue('DR_ScheduleHeatSetback.csv')
    args << dr_schedule_heat

    # MAke a string argument for offset magnitude for temperature setpoint DR events
    offset_magnitude_heat = OpenStudio::Measure::OSArgument::makeDoubleArgument('offset_magnitude_heat', true)
    offset_magnitude_heat.setDisplayName('Heating DR Offset Magnitude')
    offset_magnitude_heat.setDescription('The magnitude of the heating setpoint offset, which is applied to non-zero hours specified in the DR schedule. The offset should be positive')
    offset_magnitude_heat.setUnits('degrees F')
    offset_magnitude_heat.setDefaultValue(0)
    args << offset_magnitude_heat

    # make an argument for hourly DR schedule csv file
    dr_schedule_cool = OpenStudio::Measure::OSArgument::makeStringArgument('dr_schedule_cool', true)
    dr_schedule_cool.setDisplayName('Cooling Setpoint DR Schedule File Name')
    dr_schedule_cool.setDescription('File name of the csv that contains hourly DR signals of -1, 0, or 1 for the cooling setpoint schedule.')
    dr_schedule_cool.setDefaultValue('DR_ScheduleCoolSetup.csv')
    args << dr_schedule_cool

    # MAke a string argument for offset magnitude for temperature setpoint DR events
    offset_magnitude_cool = OpenStudio::Measure::OSArgument::makeDoubleArgument('offset_magnitude_cool', true)
    offset_magnitude_cool.setDisplayName('Cooling DR Offset Magnitude')
    offset_magnitude_cool.setDescription('The magnitude of the heating setpoint offset, which is applied to non-zero hours specified in the DR schedule. The offset should be positive')
    offset_magnitude_cool.setUnits('degrees F')
    offset_magnitude_cool.setDefaultValue(0)
    args << offset_magnitude_cool

    ######  ARGS FOR APPLIANCE DEMAND RESPONSE   ######
    appl_summer_peak = OpenStudio::Measure::OSArgument::makeStringArgument("appl_summer_peak", false)
    appl_summer_peak.setDisplayName("Peak hours for the summer time")
    appl_summer_peak.setDescription("Peak period for the summer months in 24-hour format a-b,c-d inclusive all hours") # ##fix
    appl_summer_peak.setDefaultValue("0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0")
    args << appl_summer_peak

    appl_summer_take = OpenStudio::Measure::OSArgument::makeStringArgument("appl_summer_take", false)
    appl_summer_take.setDisplayName("Hours for the summer during which the load is low")
    appl_summer_take.setDescription("Period for the summer months in 24-hour format a-b,c-d inclusive all hours, when the load is low") # ##fix
    appl_summer_take.setDefaultValue("0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0")
    args << appl_summer_take

    appl_winter_peak = OpenStudio::Measure::OSArgument::makeStringArgument("appl_winter_peak", false)
    appl_winter_peak.setDisplayName("Peak hours for the winter time")
    appl_winter_peak.setDescription("Peak period for the winter months in 24-hour format a-b,c-d inclusive all hours") # ##fix
    appl_winter_peak.setDefaultValue("0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0")
    args << appl_winter_peak

    appl_winter_take_1 = OpenStudio::Measure::OSArgument::makeStringArgument("appl_winter_take_1", false)
    appl_winter_take_1.setDisplayName("Hours for the winter during which the load is low")
    appl_winter_take_1.setDescription("Period for the winter months in 24-hour format a-b,c-d inclusive all hours, when the load is low") # ##fix
    appl_winter_take_1.setDefaultValue("0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0")
    args << appl_winter_take_1

    appl_winter_take_2 = OpenStudio::Measure::OSArgument::makeStringArgument("appl_winter_take_2", false)
    appl_winter_take_2.setDisplayName("Hours for the winter during which the load is low")
    appl_winter_take_2.setDescription("Period for the winter months in 24-hour format a-b,c-d inclusive all hours, when the load is low") # ##fix
    appl_winter_take_2.setDefaultValue("0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0")
    args << appl_winter_take_2

    appl_summer_season = OpenStudio::Measure::OSArgument::makeStringArgument("appl_summer_season", false)
    appl_summer_season.setDisplayName("Which months count as summer")
    appl_summer_season.setDescription("List of months that count as summer months") # ##fix
    appl_summer_season.setDefaultValue("0,0,0,1,1,1,1,1,1,1,0,0")
    args << appl_summer_season

    appl_winter_season = OpenStudio::Measure::OSArgument::makeStringArgument("appl_winter_season", false)
    appl_winter_season.setDisplayName("Which months count as winter")
    appl_winter_season.setDescription("List of months that count as winter months") # ##fix
    appl_winter_season.setDefaultValue("1,1,1,0,0,0,0,0,0,0,1,1")
    args << appl_winter_season

    shift_CW = OpenStudio::Measure::OSArgument::makeBoolArgument("shift_CW", false)
    shift_CW.setDisplayName("Shift clothes washer")
    shift_CW.setDescription("If clothes washer operation should be shifted to avoid the peaks. The operation of clothes washer would be delayed or started earlier to avoid the peak hours.")
    shift_CW.setDefaultValue(false)
    args << shift_CW

    shift_CD = OpenStudio::Measure::OSArgument::makeBoolArgument("shift_CD", false)
    shift_CD.setDisplayName("Shift clothes dryer")
    shift_CD.setDescription("The operation of clothes dryer would be delayed or started earlier to avoid the peak hours.")
    shift_CD.setDefaultValue(false)
    args << shift_CD

    shift_DW = OpenStudio::Measure::OSArgument::makeBoolArgument("shift_DW", false)
    shift_DW.setDisplayName("Shift dishwasher")
    shift_DW.setDescription("The operation of dishwasher would be delayed or started earlier to avoid the peak hours")
    shift_DW.setDefaultValue(false)
    args << shift_DW

    shift_PP = OpenStudio::Measure::OSArgument::makeBoolArgument("shift_PP", false)
    shift_PP.setDisplayName("Shift pool pumps")
    shift_PP.setDescription("The operation of pool pump would be shifted to take hours to avoid the peak hours")
    shift_PP.setDefaultValue(false)
    args << shift_PP

    shift_EX = OpenStudio::Measure::OSArgument::makeBoolArgument("shift_EX", false)
    shift_EX.setDisplayName("Shift electronics")
    shift_EX.setDescription("A portion of the electronics will be turned off during peak hours, and some portion will be shifted to adjacent hours")
    shift_EX.setDefaultValue(false)
    args << shift_EX

    electronics_turn_off_fraction = OpenStudio::Measure::OSArgument::makeDoubleArgument("electronics_turn_off_fraction", false)
    electronics_turn_off_fraction.setDisplayName("Electronics turn off fraction")
    electronics_turn_off_fraction.setDescription("The fraction of plugloads that should be turned off during peak period")
    electronics_turn_off_fraction.setDefaultValue(0.04)
    args << electronics_turn_off_fraction

    electronics_shift_fraction = OpenStudio::Measure::OSArgument::makeDoubleArgument("electronics_shift_fraction", false)
    electronics_shift_fraction.setDisplayName("Electronics shift fraction")
    electronics_shift_fraction.setDescription("The fraction of plugloads that should be shifted from peak period to adjacent hour")
    electronics_shift_fraction.setDefaultValue(0.11)
    args << electronics_shift_fraction

    return args
  end

  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    weather = WeatherProcess.new(model, runner)
    if weather.error?
      return false
    end

    # Import thermostat DR arguments
    dr_dir = runner.getStringArgumentValue("dr_directory", user_arguments)
    offset_heat = runner.getDoubleArgumentValue("offset_magnitude_heat", user_arguments)
    dr_sch_htg = runner.getStringArgumentValue("dr_schedule_heat", user_arguments)
    offset_cool = runner.getDoubleArgumentValue("offset_magnitude_cool", user_arguments)
    dr_sch_clg = runner.getStringArgumentValue("dr_schedule_cool", user_arguments)

    # Import appliance DR arguments
    appl_summer_peak = runner.getStringArgumentValue("appl_summer_peak", user_arguments)
    appl_summer_take = runner.getStringArgumentValue("appl_summer_take", user_arguments)
    appl_winter_peak = runner.getStringArgumentValue("appl_winter_peak", user_arguments)
    appl_winter_take_1 = runner.getStringArgumentValue("appl_winter_take_1", user_arguments)
    appl_winter_take_2 = runner.getStringArgumentValue("appl_winter_take_2", user_arguments)
    appl_summer_season = runner.getStringArgumentValue("appl_summer_season", user_arguments)
    appl_winter_season = runner.getStringArgumentValue("appl_winter_season", user_arguments)
    shift_CW = runner.getBoolArgumentValue("shift_CW", user_arguments)
    shift_CD = runner.getBoolArgumentValue("shift_CD", user_arguments)
    shift_DW = runner.getBoolArgumentValue("shift_DW", user_arguments)
    shift_PP = runner.getBoolArgumentValue("shift_PP", user_arguments)
    shift_EX = runner.getBoolArgumentValue("shift_EX", user_arguments)
    electronics_turn_off_fraction = runner.getDoubleArgumentValue("electronics_turn_off_fraction", user_arguments)
    electronics_shift_fraction = runner.getDoubleArgumentValue("electronics_shift_fraction", user_arguments)

    appl_summer_peak = appl_summer_peak.split(",").map(&:to_f)
    appl_summer_take = appl_summer_take.split(",").map(&:to_f)
    appl_winter_peak = appl_winter_peak.split(",").map(&:to_f)
    appl_winter_take_1 = appl_winter_take_1.split(",").map(&:to_f)
    appl_winter_take_2 = appl_winter_take_2.split(",").map(&:to_f)
    appl_summer_season = appl_summer_season.split(",").map(&:to_f)
    appl_winter_season = appl_winter_season.split(",").map(&:to_f)

    # # Finished Zones
    finished_zones = []
    model.getThermalZones.each do |thermal_zone|
      if Geometry.zone_is_finished(thermal_zone)
        finished_zones << thermal_zone
      end
    end

    def check_tsp_args(offset_heat, offset_cool, finished_zones, runner)
      # Check for setpoint offset
      if offset_heat == 0 and offset_cool == 0
        runner.registerInfo("DR offset magnitudes are set to zero, thermostat DR not applied")
        return false
      end
      # Check if thermostat exists
      finished_zones.each do |finished_zone|
        thermostat_setpoint = finished_zone.thermostatSetpointDualSetpoint
        if !thermostat_setpoint.is_initialized
          runner.registerInfo("No thermostat setpoint defined, thermostat DR not applied")
          return false
          break
        end
      end
      return true
    end

    def check_appl_dr_args(shift_CD, shift_CW, shift_DW, shift_PP, shift_EX, appl_summer_peak, appl_winter_peak, appl_summer_season, appl_winter_season, runner)
      # Check for appliance DR
      if not shift_CD and not shift_CW and not shift_DW and not shift_EX and not shift_PP
        runner.registerInfo("No appliance specified for demand response, appliance DR not applied")
        return false
      end
      # Check for zero-array peaks
      if (appl_summer_peak - [0.0]).empty? and (appl_winter_peak - [0.0]).empty?
        runner.registerInfo("No peak hours for appliance DR specified, appliance DR not applied")
        return false
      end
      # Check for no season specified
      if (appl_summer_season - [0.0]).empty? and (appl_winter_season - [0.0]).empty?
        runner.registerInfo("No summer or winter months specified for appliance DR seasons, appliance DR not applied")
        return false
      end
      return true
    end

    # Flag for tsp dr and/or appliance dr run
    tsp_dr = true
    appl_dr = true
    if not check_tsp_args(offset_heat, offset_cool, finished_zones, runner)
      tsp_dr = false
    end
    if not check_appl_dr_args(shift_CD, shift_CW, shift_DW, shift_PP, shift_EX, appl_summer_peak, appl_winter_peak, appl_summer_season, appl_winter_season, runner)
      appl_dr = false
    end
    if not tsp_dr and not appl_dr
      runner.registerInfo("No demand response arguments specified, skipping DR measure")
      return true
    end

    year_description = model.getYearDescription
    assumed_year = year_description.assumedYear
    run_period = model.getRunPeriod
    run_period_start = Time.new(assumed_year, run_period.getBeginMonth, run_period.getBeginDayOfMonth)
    run_period_end = Time.new(assumed_year, run_period.getEndMonth, run_period.getEndDayOfMonth, 24)
    sim_hours = (run_period_end - run_period_start) / 3600

    # Import DR Schedule
    def import_DR_sched(dr_dir, dr_sch, sch_name, offset, sim_hours, model, runner)
      path_err = dr_dir + '/' + dr_sch
      unless (Pathname.new dr_dir).absolute?
        dr_dir = File.expand_path(File.join(File.dirname(__FILE__), dr_dir))
      end

      year_description = model.getYearDescription
      assumed_year = year_description.assumedYear
      yr_hrs = Constants.NumHoursInYear(year_description.isLeapYear)
      run_period = model.getRunPeriod
      run_period_start = Time.new(assumed_year, run_period.getBeginMonth, run_period.getBeginDayOfMonth)
      run_period_end = Time.new(assumed_year, run_period.getEndMonth, run_period.getEndDayOfMonth, 24)
      sim_hours = (run_period_end - run_period_start) / 3600
      dr_schedule_file = File.join(dr_dir, dr_sch)

      if File.file?(dr_schedule_file)
        dr_hrly = HourlySchedule.new(model, runner, sch_name, dr_schedule_file, 0, false, [])
        runner.registerInfo("Imported hourly '#{sch_name}' schedule from #{dr_schedule_file}")
        dr_hrly_array = dr_hrly.schedule_array.map { |x| x.to_i }
        dr_hrly.schedule.remove

        if (dr_hrly_array.length == yr_hrs) & (sim_hours != yr_hrs)
          hr_start = run_period_start.yday * 24 - 24
          hr_end = (run_period_end.yday - 1) * 24 - 1
          dr_hrly_array = dr_hrly_array[hr_start..hr_end]
        end

        return dr_hrly_array

      elsif (offset == 0) || (dr_sch == 'none')
        return Array.new(sim_hours, 0)
      else
        err_msg = "File #{dr_sch} does not exist"
        runner.registerError(err_msg)
        return
      end
    end

    # Import user DR schedule and run checks
    dr_hrly_htg = []
    dr_hrly_clg = []
    if tsp_dr
      dr_hrly_clg = import_DR_sched(dr_dir, dr_sch_clg, "DR Cooling Schedule", offset_cool, sim_hours, model, runner)
      dr_hrly_htg = import_DR_sched(dr_dir, dr_sch_htg, "DR Heating Schedule", offset_heat, sim_hours, model, runner)
      # Check if file exists (error message in import_DR_sched())
      if dr_hrly_htg == nil
        return false
      elsif dr_hrly_clg == nil
        return false
      end
    end

    # Check attributes of imported DR schedules
    def check_DR_sched(dr_hrly, model, runner)
      # Check for invalid DR flags
      if (dr_hrly.to_a - (-1..1).to_a).any?
        runner.registerError('The DR schedule must have values of -1, 0, or 1.')
        return false
      end
      return true
    end

    # Check length of DR schedule
    def check_DR_length(dr_hrly, sim_hours, model, runner)
      year_description = model.getYearDescription
      n_days = Constants.NumDaysInYear(year_description.isLeapYear)
      if (dr_hrly.length != sim_hours) && (dr_hrly.length != n_days * 24)
        runner.registerInfo('Hourly DR schedule length must equal to simulation period or a full year, no thermostat DR applied')
        return false
      end
      return true
    end

    if tsp_dr
      dr_list = []
      offset_list = [dr_hrly_htg, dr_hrly_clg]
      offset_list.each do |dr|
        if dr != []
          dr_list << dr
          if not check_DR_sched(dr, model, runner)
            return false
          end

          if not check_DR_length(dr, sim_hours, model, runner)
            return true
          end
        end
      end
    end

    # Check if DR schedules contain only zeros
    if tsp_dr
      ct = 0
      dr_list.each do |dr_hrly|
        if ((dr_hrly.to_a.max() == 0) & (dr_hrly.to_a.min() == 0))
          ct += 1
          if ct == dr_list.length
            runner.registerInfo("DR schedules contain only zeros, no thermostat DR applied")
            return true
          end
        end
      end
    end

    # Generates existing hourly schedules
    def get_existing_sched(finished_zones, sched_type, model, runner)
      # Get monthly weekend/weekday 24-hour schedules prior to setpoint inversion fix
      thermostat_setpoint = nil
      wked_monthly, wkdy_monthly = nil, nil
      finished_zones.each do |finished_zone|
        thermostat_setpoint = finished_zone.thermostatSetpointDualSetpoint
        next unless thermostat_setpoint.is_initialized

        thermostat_setpoint = thermostat_setpoint.get
        runner.registerInfo("Found existing thermostat #{thermostat_setpoint.name} for #{finished_zone.name}.")

        if sched_type == 'heat'
          prefix = 'htg'
          thermostat_setpoint.heatingSetpointTemperatureSchedule.get.remove
        elsif sched_type == 'cool'
          prefix = 'clg'
          thermostat_setpoint.coolingSetpointTemperatureSchedule.get.remove
        end

        wked_monthly = [thermostat_setpoint.additionalProperties.getFeatureAsString(prefix + '_wked').get.split(',').map { |i| i.to_f }] * 12
        wkdy_monthly = [thermostat_setpoint.additionalProperties.getFeatureAsString(prefix + '_wkdy').get.split(',').map { |i| i.to_f }] * 12
        break # All zones assumed have same schedule
      end

      # Generate base hourly schedule
      year_description = model.getYearDescription
      day_startm = [0]
      day_endm = [0]
      total_days = 0
      for d in Constants.NumDaysInMonths(year_description.isLeapYear)
        total_days += d
        d_start = total_days - d + 1
        d_end = total_days
        day_startm.push(d_start)
        day_endm.push(d_end)
      end

      day_names = { 'Monday' => 1, 'Tuesday' => 2, 'Wednesday' => 3, 'Thursday' => 4, 'Friday' => 5, 'Saturday' => 6, 'Sunday' => 7 }
      start_day_of_week = model.getYearDescription.dayofWeekforStartDay
      day_num_start = day_names[start_day_of_week]
      day_num = day_num_start
      hr_strt = 0
      hrly_base = []
      for month in 1..12
        daystrt = day_startm[month]
        dayend = day_endm[month]
        for day in daystrt..dayend
          if (day_num == 6) || (day_num == 7)
            hrly_base += wked_monthly[month - 1]
          else
            hrly_base += wkdy_monthly[month - 1]
          end
          hr_strt += 24
          day_num = day_num % 7 + 1
        end
      end
      hrly_base = hrly_base.map { |i| UnitConversions.convert(i, 'C', 'F') }

      year_description = model.getYearDescription
      assumed_year = year_description.assumedYear
      run_period = model.getRunPeriod
      run_period_start = Time.new(assumed_year, run_period.getBeginMonth, run_period.getBeginDayOfMonth)
      run_period_end = Time.new(assumed_year, run_period.getEndMonth, run_period.getEndDayOfMonth, 24)
      hr_start = run_period_start.yday * 24 - 24
      hr_end = (run_period_end - 1).yday * 24 - 1
      hrly_base = hrly_base[hr_start..hr_end]

      return(hrly_base)
    end

    # Apply DR offset & schedule to existing
    def create_new_sched(dr_hrly, hrly_base, offset)
      offset_hrly = dr_hrly.map { |x| x * offset }
      sched_hrly = [hrly_base, offset_hrly].transpose.map { |x| x.reduce(:+) }
      sched_hrly = sched_hrly.map { |i| UnitConversions.convert(i, 'F', 'C') }
      return sched_hrly
    end

    # Adjust for inverted setpoint AFTER DR applied
    def fix_setpoint_inversion(htg_hrly, clg_hrly, hvac, weather, model, runner)
      cooling_season = hvac.get_season(model, weather, runner, Constants.ObjectNameCoolingSeason)
      heating_season = hvac.get_season(model, weather, runner, Constants.ObjectNameHeatingSeason)

      year_description = model.getYearDescription
      run_period = model.getRunPeriod
      start_month = run_period.getBeginMonth - 1
      end_month = run_period.getEndMonth - 1

      day_e = 0
      days_in_month = Constants.NumDaysInMonths(year_description.isLeapYear)
      (start_month..end_month).to_a.each do |i|
        day_s = day_e + 1
        day_e = day_s + days_in_month[i] - 1
        hr1 = (day_s - 1) * 24
        hr2 = day_e * 24 - 1

        htg_hrly_month = htg_hrly[hr1..hr2]
        clg_hrly_month = clg_hrly[hr1..hr2]

        if (heating_season[i] == 1) && (cooling_season[i] == 1)
          htg_hrly[hr1..hr2] = htg_hrly_month.zip(clg_hrly_month).map { |h, c| c < h ? (h + c) / 2.0 : h }
          clg_hrly[hr1..hr2] = htg_hrly_month.zip(clg_hrly_month).map { |h, c| c < h ? (h + c) / 2.0 : c }
        elsif heating_season[i] == 1 # heating only seasons; cooling has minimum of heating
          htg_hrly[hr1..hr2] = htg_hrly_month.zip(clg_hrly_month).map { |h, c| c < h ? h : h }
          clg_hrly[hr1..hr2] = htg_hrly_month.zip(clg_hrly_month).map { |h, c| c < h ? h : c }
        elsif cooling_season[i] == 1 # cooling only seasons; heating has maximum of cooling
          htg_hrly[hr1..hr2] = htg_hrly_month.zip(clg_hrly_month).map { |h, c| c < h ? c : h }
          clg_hrly[hr1..hr2] = htg_hrly_month.zip(clg_hrly_month).map { |h, c| c < h ? c : c }
        end
      end
    end

    def create_OS_sched(sched_hrly, var_name, model, runner)
      year_description = model.getYearDescription
      assumed_year = year_description.assumedYear
      run_period = model.getRunPeriod
      run_period_start = Time.new(assumed_year, run_period.getBeginMonth, run_period.getBeginDayOfMonth)
      start_date = year_description.makeDate(run_period_start.month, run_period_start.day)
      interval = OpenStudio::Time.new(0, 1, 0, 0)
      time_series = OpenStudio::TimeSeries.new(start_date, interval, OpenStudio::createVector(sched_hrly), '')
      schedule = OpenStudio::Model::ScheduleFixedInterval.new(model)
      schedule.setTimeSeries(time_series)
      schedule.setName(var_name)

      return schedule
    end

    # Run functions and apply new schedules
    if tsp_dr
      htg_hrly_base = get_existing_sched(finished_zones, "heat", model, runner)   # Existing schedule as 12x24
      clg_hrly_base = get_existing_sched(finished_zones, "cool", model, runner)

      htg_hrly = create_new_sched(dr_hrly_htg, htg_hrly_base, offset_heat)        # New hourly schedule
      clg_hrly = create_new_sched(dr_hrly_clg, clg_hrly_base, offset_cool)

      fix_setpoint_inversion(htg_hrly, clg_hrly, HVAC, weather, model, runner)    # Fix setpoint inversions in new schedules

      htg_hrly = create_OS_sched(htg_hrly, "HeatingTSP", model, runner)           # Create fixed interval schedule using new hourly schedules
      clg_hrly = create_OS_sched(clg_hrly, "CoolingTSP", model, runner)

      # Convert back to ruleset and apply to dual thermostat
      winter_design_day_sch = OpenStudio::Model::ScheduleDay.new(model)
      winter_design_day_sch.addValue(OpenStudio::Time.new(0, 24, 0, 0), UnitConversions.convert(70, "F", "C"))
      summer_design_day_sch = OpenStudio::Model::ScheduleDay.new(model)
      summer_design_day_sch.addValue(OpenStudio::Time.new(0, 24, 0, 0), UnitConversions.convert(75, "F", "C"))
      rule_sched_h = []
      rule_sched_c = []

      finished_zones.each do |finished_zone|
        thermostat_setpoint = finished_zone.thermostatSetpointDualSetpoint
        if thermostat_setpoint.is_initialized
          thermostat_setpoint = thermostat_setpoint.get
          thermostat_setpoint.resetHeatingSetpointTemperatureSchedule()
          thermostat_setpoint.resetCoolingSetpointTemperatureSchedule()
          rule_sched_h = Schedule.ruleset_from_fixedinterval(model, htg_hrly, Constants.ObjectNameHeatingSetpoint, winter_design_day_sch, summer_design_day_sch)
          rule_sched_c = Schedule.ruleset_from_fixedinterval(model, clg_hrly, Constants.ObjectNameCoolingSetpoint, winter_design_day_sch, summer_design_day_sch)
          htg_hrly.remove
          clg_hrly.remove
          break
        end
      end

      # Set heating/cooling setpoint schedules
      finished_zones.each do |finished_zone|
        thermostat_setpoint = finished_zone.thermostatSetpointDualSetpoint
        if thermostat_setpoint.is_initialized
          thermostat_setpoint = thermostat_setpoint.get
          thermostat_setpoint.setHeatingSetpointTemperatureSchedule(rule_sched_h)
          runner.registerInfo("Set the heating setpoint schedule for #{thermostat_setpoint.name}.")
          thermostat_setpoint.setCoolingSetpointTemperatureSchedule(rule_sched_c)
          runner.registerInfo("Set the cooling setpoint schedule for #{thermostat_setpoint.name}.")
        end
      end
    end

    # Return if no appliance DR
    if not appl_dr
      return true
    end

    # *** Put Appliance DR Code HERE *** #
    def get_month_list(x)
      month_list = []
      x.each_with_index do |val, index|
        if val > 0
          month_list << index + 1
        end
      end
      return month_list
    end

    def get_array_of_intervals(x)
      array_of_intervals = []
      started = false
      x.each_with_index do |val, index|
        if val > 0 and not started
          array_of_intervals << [index, nil]
          started = true
        elsif val == 0 and started
          array_of_intervals[-1][1] = index
          started = false
        end
      end
      if started
        array_of_intervals[-1][1] = 24
      end
      return array_of_intervals
    end

    summer_peak_hours = get_array_of_intervals(appl_summer_peak)
    winter_peak_hours = get_array_of_intervals(appl_winter_peak)
    summer_take_hours = get_array_of_intervals(appl_summer_take)
    winter_take_hours_1 = get_array_of_intervals(appl_winter_take_1)
    winter_take_hours_2 = get_array_of_intervals(appl_winter_take_2)
    summer_months = get_month_list(appl_summer_season)
    winter_months = get_month_list(appl_winter_season)

    def avoid_peaks(day_sch, peak_hours, model, take_hour = [], simple_shifting = false, fractions = [0, 1])
      # simple_shifting = true will just take portion (energy) out of peak hours and dump it on top of take_hours
      # simple_shifting = false will do cluster based shifting (eg. dishwasher, clothswasher)
      # fraction = a, b. The load during peak_hours will be reduced to a*original value. The load during take_hours will be
      # increased by adding b*(Integration of original value)_during_peak_hours.

      def create_new_day_schedule(times, values, model)
        new_day_sch = OpenStudio::Model::ScheduleDay.new(model)
        times.each_with_index do |time, index|
          new_day_sch.addValue(time, values[index])
        end
        return new_day_sch
      end

      old_times = day_sch.times
      old_vals = day_sch.values
      peak_hours.each do |peak|
        if simple_shifting
          if take_hour.empty?
            if peak[1] == 23
              new_take_hour = [peak[0] - 2, peak[0]]
            else
              new_take_hour = [peak[1], peak[1] + 2]
            end
          else
            new_take_hour = take_hour
          end
          new_times, new_vals = shift_peak_to_take(day_sch, peak, new_take_hour, OpenStudio::Time, fractions)
          day_sch = create_new_day_schedule(new_times, new_vals, model)
        else
          new_times, new_vals = dodge_peak(day_sch, peak, peak_hours, OpenStudio::Time)
          day_sch = create_new_day_schedule(new_times, new_vals, model)
        end
      end

      if simple_shifting
        new_day_sch = OpenStudio::Model::ScheduleDay.new(model)
        times = day_sch.times
        values = day_sch.values
        times.each_with_index do |time, index|
          new_day_sch.addValue(time, values[index] / 10.to_f)
        end
        day_sch = new_day_sch
      end

      return day_sch
    end
    units = Geometry.get_building_units(model, runner)
    units.each_with_index do |unit, unit_index|
      model.getElectricEquipments.each do |ee|
        puts("Checking #{ee.name.to_s}")
        next if not ((ee.name.to_s == Constants.ObjectNameClothesWasher(unit.name.to_s) and shift_CW) or \
           (ee.name.to_s == Constants.ObjectNameClothesDryer("electric", unit.name.to_s) and shift_CD) or \
           (ee.name.to_s == Constants.ObjectNameDishwasher(unit.name.to_s) and shift_DW) or \
           (ee.name.to_s == Constants.ObjectNamePoolPump(unit.name.to_s) and shift_PP) or \
           (ee.name.to_s.start_with?('res misc plug loads') and shift_EX))

        puts("Applying DR to #{ee.name.to_s}")
        if not ee.schedule.empty?
          existing_schedule = ee.schedule.get
          new_schedule = OpenStudio::Model::ScheduleRuleset.new(model)
          new_schedule.setName('DR_' + existing_schedule.name.get)

          if not existing_schedule.to_ScheduleRuleset.empty?
            ruleset = existing_schedule.to_ScheduleRuleset.get
            rules = ruleset.scheduleRules()
            rules.each_with_index do |rule, index|
              day_sch = rule.daySchedule
              if ee.name.to_s == Constants.ObjectNamePoolPump(unit.name.to_s) or ee.name.to_s.start_with?('res misc plug loads')
                # pool-pump or plug loads
                start_date = rule.startDate.get
                end_date = rule.endDate.get
                if summer_months.include?(start_date.monthOfYear.value)
                  # use only the first take_hour if a list is provided.
                  if ee.name.to_s.start_with?('res misc plug loads')
                    remaining_peak_fraction = 1 - (electronics_turn_off_fraction + electronics_shift_fraction)
                    fractions = [remaining_peak_fraction, electronics_shift_fraction]
                    take_hour = []
                  else
                    fractions = [0, 1]
                    take_hour = summer_take_hours[0]
                  end
                  summer_sch = avoid_peaks(day_sch, summer_peak_hours, model, take_hour, true, fractions)
                  summer_rule = OpenStudio::Model::ScheduleRule.new(new_schedule, summer_sch)
                  summer_rule.setName('summer_' + rule.name.get)
                  summer_rule.setStartDate(start_date)
                  summer_rule.setEndDate(end_date)
                  Schedule.set_weekday_rule(summer_rule)
                  Schedule.set_weekend_rule(summer_rule)
                elsif winter_months.include?(start_date.monthOfYear.value)
                  if ee.name.to_s.start_with?('res misc plug loads')
                    remaining_peak_fraction = 1 - (electronics_turn_off_fraction + electronics_shift_fraction)
                    fractions = [remaining_peak_fraction, electronics_shift_fraction]
                    take_hour = []
                  else
                    fractions = [0, 1]
                    take_hour = winter_take_hours_1[0] # use only the first take_hour if a list is provided.
                  end
                  winter_sch = avoid_peaks(day_sch, winter_peak_hours, model, take_hour, true, fractions)
                  winter_rule = OpenStudio::Model::ScheduleRule.new(new_schedule, winter_sch)
                  winter_rule.setName('winter_' + rule.name.get)
                  winter_rule.setStartDate(start_date)
                  winter_rule.setEndDate(end_date)
                  Schedule.set_weekday_rule(winter_rule)
                  Schedule.set_weekend_rule(winter_rule)
                else
                  # if the month doesn't fall in either summer or winter
                  raise "Month #{start_date.monthOfYear.value} neither in winter nor summer"
                end

              else
                # other appliance
                summer_dates = rule.specificDates.select { |x| summer_months.include?(x.monthOfYear.value) }
                winter_dates = rule.specificDates.select { |x| winter_months.include?(x.monthOfYear.value) }
                summer_sch = avoid_peaks(day_sch, summer_peak_hours, model)
                winter_sch = avoid_peaks(day_sch, winter_peak_hours, model)
                summer_rule = OpenStudio::Model::ScheduleRule.new(new_schedule, summer_sch)
                summer_rule.setName('summer_' + rule.name.get)
                summer_dates.each { |date| summer_rule.addSpecificDate(date) }
                winter_rule = OpenStudio::Model::ScheduleRule.new(new_schedule, winter_sch)
                winter_rule.setName('winter_' + rule.name.get)
                winter_dates.each { |date| winter_rule.addSpecificDate(date) }
                Schedule.set_weekday_rule(summer_rule)
                Schedule.set_weekend_rule(summer_rule)
                Schedule.set_weekday_rule(winter_rule)
                Schedule.set_weekend_rule(winter_rule)
              end
            end
            if ee.name.to_s == Constants.ObjectNamePoolPump(unit.name.to_s) or ee.name.to_s.start_with?('res misc plug loads')
              # reset the schedule limit to 2 if it is a pool_pump
              old_level = ee.designLevel.get
              equip_def = ee.electricEquipmentDefinition
              equip_def.setDesignLevel(old_level * 10)
            end
            ee.setSchedule(new_schedule)
            existing_schedule = ee.schedule.get
          else
            runner.registerError("Expecting Ruleset schedule. Found #{existing_schedule} instead")
          end
        else
          runner.registerError("No schedule attached to clothes washer")
        end
      end
    end
  end
end
