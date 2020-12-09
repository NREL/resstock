# load dependencies
require 'csv'

# start the measure
class AddIntervalScheduleFromFileLDRD < OpenStudio::Measure::ModelMeasure
  # display name
  def name
    return 'Add Interval Schedule From FileLDRD'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # make an argument for cluster folder name
    cluster = OpenStudio::Ruleset::OSArgument.makeStringArgument('cluster', true)
    cluster.setDisplayName('Enter the name of the cluster')
    cluster.setDescription("Example: 1")
    cluster.setDefaultValue("1")
    args << cluster

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # load cluster folder
    measure_dir = File.dirname(__FILE__)
    puts "measure_dir == #{measure_dir}"
    cluster = runner.getStringArgumentValue('cluster', user_arguments)
    cluster_dir = File.join(measure_dir, 'clusters/' + cluster + '/')

    # get files
    file_path_weekday = File.join(cluster_dir, 'weekday.csv')
    puts "file_path_weekday = #{file_path_weekday}"
    file_path_weekend = File.join(cluster_dir, 'weekday.csv')
    puts "file_path_weekend = #{file_path_weekend}"
    # file_path_pre_schedule = File.expand_path(File.join(measure_dir, '../../../workflows/generated_files/schedules.csv'))
    file_path_pre_schedule = File.expand_path("../")
    puts "file_path_pre_schedule = #{file_path_pre_schedule}"

    puts " file_path_pre_schedule directory === #{File.dirname(file_path_pre_schedule)}"

    # load CSVs
    profiles_weekend = CSV.read(file_path_weekend, converters: [CSV::Converters[:float]], headers: true)
    profiles_weekday = CSV.read(file_path_weekday, converters: [CSV::Converters[:float]], headers: true)
    pre_schedules = CSV.read(file_path_pre_schedule + "/schedules.csv", converters: [CSV::Converters[:float]], :headers => true)

    # get time interval from model
    timesteps_per_hour = model.getTimestep.numberOfTimestepsPerHour
    time_interval = (60 / timesteps_per_hour).to_s
    puts "time_interval ====  #{time_interval.class}"
    puts "time_interval ====  #{time_interval}"

    # random occupancy generator with weight
    def random_weighted(weighted)
      # puts weighted
      max = sum_of_weights(weighted)
      # target = rand(1..max)
      target = rand()
      weighted.each do |item, weight|
        return item if target <= weight

        target -= weight
      end
    end

    def sum_of_weights(weighted)
      weighted.inject(0) { |sum, (item, weight)| sum + weight }
    end
    ## putting number of peoles in to an array
    peoplecaps = []
    people_instances = model.getPeoples
    people_instances.each do |people|
      next unless !people.numberOfPeople.empty?

      peoplecap = people.numberOfPeople.get.to_f
      peoplecaps << peoplecap
    end

    # calcualte the total number of people
    people_cap = peoplecaps.inject(0) { |sum, x| sum + x } # adding the total number of people in the house
    runner.registerInfo("peoplecap = '#{people_cap}' ")
    if people_cap < 2.0
      profile_weekday = profiles_weekday['Occ_1']
      profile_weekend = profiles_weekend['Occ_1']
    elsif people_cap < 3.0
      profile_weekday = profiles_weekday['Occ_2']
      profile_weekend = profiles_weekend['Occ_2']
    else
      profile_weekday = profiles_weekday['Occ_3']
      profile_weekend = profiles_weekend['Occ_3']
    end

    occ_yearly = []
    total_days_in_year = 365
    start_day = DateTime.new(2018, 1, 1)
    timesteps = 60 / time_interval.to_f
    total_days_in_year.times do |day|
      today = start_day + day
      day_of_week = today.wday
      if [0, 6].include?(day_of_week)
        # Weekend
        day_type = "weekend"
        profile = profile_weekend
      else
        # weekday
        day_type = "weekday"
        profile = profile_weekday
      end
      # puts profile
      profile.each do |p|
        timesteps.to_i.times do |t|
          occ_value = random_weighted(occ: p, unocc: 1 - p)
          puts "AT timestep #{t} and probability #{p} ..... occupancy ==== #{occ_value}"

          occ_yearly << occ_value
        end
      end
    end

    importedPlug = pre_schedules['plug_loads']
    importedlight = pre_schedules['lighting_interior']
    CSV.open(File.dirname(file_path_pre_schedule) + "/new_schedules.csv", "w") do |csv|
      csv << ['OccSch', 'lightSch', 'equipSch', 'thermostat_clg', 'thermostat_htg']
      ct = 0
      occ_yearly.each do |p|
        # puts p.class
        if p.to_s.include? "unocc"
          csv <<  [0, 0, 0, 27, 18]
        else
          csv <<  [1, importedlight[ct], importedPlug[ct], 23, 21]
        end
        ct += 1
      end
    end

    apply_to_all_zones = true

    # depending on user input, add selected zones to an array
    selected_zones = []
    if apply_to_all_zones == true
      selected_zones = model.getThermalZones
    else
      selected_zones << selected_zone
    end
    file_name = File.realpath(File.dirname(file_path_pre_schedule) + '/new_schedules.csv')
    external_file = OpenStudio::Model::ExternalFile::getExternalFile(model, file_name)
    external_file = external_file.get

    schedule_file_occ = OpenStudio::Model::ScheduleFile.new(external_file, 1, 1)
    schedule_file_occ.setName('occupants')
    schedule_file_occ.setMinutesperItem(time_interval)

    schedule_file_light = OpenStudio::Model::ScheduleFile.new(external_file, 2, 1)
    schedule_file_light.setName('interiorLights')
    schedule_file_light.setMinutesperItem(time_interval)

    schedule_file_equip = OpenStudio::Model::ScheduleFile.new(external_file, 3, 1)
    schedule_file_equip.setName('equipments')
    schedule_file_equip.setMinutesperItem(time_interval)

    schedule_file_clg = OpenStudio::Model::ScheduleFile.new(external_file, 4, 1)
    schedule_file_clg.setName('Clg_schedule')
    schedule_file_clg.setMinutesperItem(time_interval)
    schedule_file_htg = OpenStudio::Model::ScheduleFile.new(external_file, 5, 1)
    schedule_file_htg.setName('Htg_schedule')

    people_instances = model.getPeoples
    people_instances.each do |people|
      people.setNumberofPeopleSchedule (schedule_file_occ)
    end

    light_instances = model.getLightss
    light_instances.each do |light|
      light.setSchedule(schedule_file_light)
    end

    equip_instances = model.getElectricEquipments
    equip_instances.each do |equip|
      equip.setSchedule(schedule_file_equip)
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
AddIntervalScheduleFromFileLDRD.new.registerWithApplication
