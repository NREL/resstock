# load dependencies
require 'csv'

# start the measure
class AddIntervalScheduleFromFile < OpenStudio::Measure::ModelMeasure

  # display name
  def name
    return 'Add Interval Schedule From FileLDRD'
  end

  def description
    return "This measure adds a schedule object from a file of interval data"
  end

  def modeler_description
    return "This measure adds a ScheduleInterval object from a user-specified .csv file. The measure supports hourly and 15 min interval data for leap and non-leap years.  The .csv file must contain only schedule values in the first column with 8760, 8784, 35040, or 35136 rows specified. See the example .csv files in the tests directory of this measure."
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # make an argument for file path
    time_interval = OpenStudio::Measure::OSArgument.makeStringArgument('time_interval', true)
    time_interval.setDisplayName('Enter number of minutes per interval):')
    time_interval.setDescription("Example: '15'")
    args << time_interval

    # make an argument for file path
    file_path = OpenStudio::Measure::OSArgument.makeStringArgument('file_path', true)
    file_path.setDisplayName('Enter the path to the file that contains schedule values (follow template in test folder of this measure):')
    file_path.setDescription("Example: 'C:\\Projects\\values.csv'")
    args << file_path

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    time_interval = runner.getStringArgumentValue('time_interval', user_arguments)
    file_path = runner.getStringArgumentValue('file_path', user_arguments)
    apply_to_all_zones = true

    # depending on user input, add selected zones to an array
    selected_zones = []
    if apply_to_all_zones == true
      selected_zones = model.getThermalZones
    else
      selected_zones << selected_zone
    end

    file_name = File.expand_path(file_path)
    external_file = OpenStudio::Model::ExternalFile::getExternalFile(model, file_name)
    if external_file.is_initialized
      external_file = external_file.get
    else
      runner.registerError("Some issue with file_path: #{file_name}.")
      return false
    end
    schedule_file_clg = OpenStudio::Model::ScheduleFile.new(external_file, 1, 1)
    schedule_file_clg.setName('Clg_schedule')
    schedule_file_clg.setMinutesperItem(time_interval)
    schedule_file_htg = OpenStudio::Model::ScheduleFile.new(external_file, 2, 1)
    schedule_file_htg.setName('Htg_schedule')
    schedule_file_occ = OpenStudio::Model::ScheduleFile.new(external_file, 7, 1)
    schedule_file_occ.setName('occupants')
    schedule_file_occ.setMinutesperItem(time_interval)

    people_instances = model.getPeoples
    people_instances.each do |people|
      people.setNumberofPeopleSchedule (schedule_file_occ)
    end

    light_instances = model.getLightss
    light_instances.each do |light|
      light.setSchedule(schedule_file_occ)
    end

    equip_instances = model.getElectricEquipments
    equip_instances.each do |equip|
     equip.setSchedule(schedule_file_occ)
    end

    number_zones_modified = 0
    # zones with thermostat changes
    selected_zones.each do |zone|
      thermostatSetpointDualSetpoint = zone.thermostatSetpointDualSetpoint
      if thermostatSetpointDualSetpoint.empty?
        runner.registerWarning("Cannot find existing thermostat for thermal zone '#{zone.name}', skipping.")
        next
      end
      # remove existing schedule
      thermostatSetpointDualSetpoint.get.remove

      # Assign new thermostat schedule
      thermostatSetpointDualSetpoint = OpenStudio::Model::ThermostatSetpointDualSetpoint.new(model)
      thermostatSetpointDualSetpoint.setHeatingSetpointTemperatureSchedule(schedule_file_htg)
      thermostatSetpointDualSetpoint.setCoolingSetpointTemperatureSchedule(schedule_file_clg)
      zone.setThermostatSetpointDualSetpoint(thermostatSetpointDualSetpoint)


      number_zones_modified += 1
    end
#    end

    runner.registerFinalCondition("Replaced thermostats for #{number_zones_modified} thermal zones}")

    if number_zones_modified == 0
      runner.registerAsNotApplicable('No thermostats altered')
    end

    return true
  end
end
# this allows the measure to be use by the application
AddIntervalScheduleFromFile.new.registerWithApplication
