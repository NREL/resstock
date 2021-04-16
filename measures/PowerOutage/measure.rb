# frozen_string_literal: true

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/measures/measure_writing_guide/

require 'openstudio'

# start the measure
class PowerOutage < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    return 'Power Outage'
  end

  # human readable description
  def description
    return 'This measures allows building power outages to be modeled. The user specifies the start time of the outage and the duration of the outage. During an outage, all energy consumption is set to 0, although occupants are still simulated in the home.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'This measure zeroes out the schedule for anything that consumes energy for the duration of the power outage.'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('outage_start_date', true)
    arg.setDisplayName('Power Outage: Start Date')
    arg.setDescription('Date of the start of the outage.')
    arg.setDefaultValue('January 1')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeIntegerArgument('outage_start_hour', true)
    arg.setDisplayName('Power Outage: Start Hour')
    arg.setUnits('hours')
    arg.setDescription('Hour of the day when the outage starts.')
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeIntegerArgument('outage_duration', true)
    arg.setDisplayName('Power Outage: Duration')
    arg.setUnits('hours')
    arg.setDescription('Duration of the power outage in hours.')
    arg.setDefaultValue(24)
    args << arg

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # assign the user inputs to variables
    args = get_argument_values(runner, arguments(model), user_arguments)

    # check for valid inputs
    if (args['outage_start_hour'] < 0) || (args['outage_start_hour'] > 23)
      runner.registerError('Start hour must be between 0 and 23.')
      return false
    end

    if args['outage_duration'] == 0
      runner.registerError('Outage must last for at least one hour.')
      return false
    end

    # create outage start/end date time objects
    sim_year = model.getYearDescription.calendarYear.get
    start_month = args['outage_start_date'].split[0]
    start_day = args['outage_start_date'].split[1].to_i
    outage_start_date = Time.new(sim_year, OpenStudio::monthOfYear(start_month).value, start_day, args['outage_start_hour'])
    outage_end_date = outage_start_date + args['outage_duration'] * 3600.0

    # make an outage availability schedule
    annual_hrs = (Time.new(sim_year + 1) - Time.new(sim_year)) / 3600.0
    outage_availability = [1] * annual_hrs
    outage_start_hour_of_year = ((outage_start_date - Time.new(sim_year)) / 3600.0).to_i
    outage_end_hour_of_year = ((outage_end_date - Time.new(sim_year)) / 3600.0).to_i
    outage_availability[outage_start_hour_of_year...outage_end_hour_of_year] = [0] * (outage_end_hour_of_year - outage_start_hour_of_year)
    year_start_date = OpenStudio::Date.new(OpenStudio::MonthOfYear.new(1), 1, sim_year)
    interval_length = OpenStudio::Time.new(0, 1, 0, 0) # hour
    outage_availability = OpenStudio::createVector(outage_availability)
    timeseries = OpenStudio::TimeSeries.new(year_start_date, interval_length, outage_availability, '')
    outage_availability_schedule = OpenStudio::Model::ScheduleInterval.fromTimeSeries(timeseries, model).get
    outage_availability_schedule.setName('Outage Availability Schedule')

    model.getElectricEquipments.each do |electric_equipment|
      electric_equipment.setSchedule(outage_availability_schedule)
    end

    # set outage availability schedule on all hvac objects
    # model.getThermalZones.each do |thermal_zone|
    # equipments = HVAC.existing_heating_equipment(model, runner, thermal_zone) + HVAC.existing_cooling_equipment(model, runner, thermal_zone)
    # equipments.each do |equipment|
    # equipment.setAvailabilitySchedule(outage_availability_schedule)
    # runner.registerInfo("Modified the availability schedule for '#{equipment.name}'.")
    # end
    # end

    # set the outage availability schedule on res_infil_1_wh_sch_s (so house fan zeroes out)
    # model.getEnergyManagementSystemSensors.each do |ems_sensor|
    # next unless ems_sensor.name.to_s.include? "_wh_sch_s"

    # ems_sensor.setKeyName("Outage Availability Schedule")
    # runner.registerInfo("Modified the key name for '#{ems_sensor.name}'.")
    # end

    # set outage on schedule file
    schedules_file = nil
    model.getExternalFiles.each do |external_file|
      next unless external_file.fileName.end_with?('schedules.csv')

      schedules_file = SchedulesFile.new(runner: runner, model: model, schedules_path: external_file.filePath.to_s, col_names: ScheduleGenerator.col_names.keys)
    end

    if schedules_file.nil?
      runner.registerError('Could not locate the schedule file.')
      return false
    end

    schedules_file.set_outage(outage_start_date: outage_start_date, outage_end_date: outage_end_date)

    # add additional properties object with the date of the outage for use by reporting measures
    additional_properties = model.getYearDescription.additionalProperties
    additional_properties.setFeature('PowerOutageStartDate', args['outage_start_date'])
    additional_properties.setFeature('PowerOutageStartHour', args['outage_start_hour'])
    additional_properties.setFeature('PowerOutageDuration', args['outage_duration'])

    runner.registerFinalCondition("A power outage has been added, starting on #{args['outage_start_date']} at hour #{args['outage_start_hour']} and lasting for #{args['outage_duration']} hours.")

    return true
  end
end

# this allows the measure to be use by the application
PowerOutage.new.registerWithApplication
