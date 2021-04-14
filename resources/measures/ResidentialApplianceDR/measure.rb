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

require File.join(resources_path, "constants")
require File.join(resources_path, "weather")
require File.join(resources_path, "hvac")
require File.join(resources_path, "schedules")
require File.join(resources_path, "geometry")
require File.join(File.dirname(__FILE__), "./schedule_modifier.rb")

# start the measure
class ApplianceDemandResponse < OpenStudio::Measure::ModelMeasure
  # define the name that a user will see, this method may be deprecated as
  # the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Appliance Demand Response Schedule"
  end

  def description
    return "This measure alters the thermostat setpoints based on inputted offset magnitudes and schedules of demand-response signals.#{Constants.WorkflowDescription}"
  end

  def modeler_description
    return "This measure applies hourly demand response controls to existing heating and cooling temperature setpoint schedules. Up to two user-defined DR schedules are inputted as csvs for heating and/or cooling to indicate specific hours of setup and setback. The csvs should contain a value of -1, 0, or 1 for every hour of the simulation period or for an entire year. Offset magnitudes for heating and cooling are also specified by the user, which is multiplied by each row of the DR schedules to generate an hourly offset schedule on-the-fly. The existing cooling and heating setpoint schedules are fetched from the model object, restructured as an hourly schedule for the simulation period, and summed with their respective hourly offset schedules. These new hourly setpoint schedules are assigned to the thermostat object in every zone. Future development of this measure may include on/off DR schedules for appliances or use with water heaters."
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # make an argument for hourly DR schedule directory
    dr_directory = OpenStudio::Measure::OSArgument::makeStringArgument("dr_directory", false)
    dr_directory.setDisplayName("Demand Response Schedule Directory")
    dr_directory.setDescription("Absolute or relative directory that contains the DR csv files")
    dr_directory.setDefaultValue("../HPXMLtoOpenStudio/resources")
    args << dr_directory

    dr_arg = OpenStudio::Measure::OSArgument::makeStringArgument("summer_peak_hours", false)
    dr_arg.setDisplayName("Peak hours for the summer time")
    dr_arg.setDescription("Peak period for the summer months in 24-hour format a-b,c-d inclusive all hours")
    dr_arg.setDefaultValue('18-22')
    args << dr_arg

    dr_arg = OpenStudio::Measure::OSArgument::makeStringArgument("summer_take_hours", false)
    dr_arg.setDisplayName("Hours for the summer during which the load is low")
    dr_arg.setDescription("Period for the summer months in 24-hour format a-b,c-d inclusive all hours, when the load is low")
    dr_arg.setDefaultValue('3-7')
    args << dr_arg

    dr_arg = OpenStudio::Measure::OSArgument::makeStringArgument("winter_peak_hours", false)
    dr_arg.setDisplayName("Peak hours for the winter time")
    dr_arg.setDescription("Peak period for the winter months in 24-hour format a-b,c-d inclusive all hours")
    dr_arg.setDefaultValue('5-9,18-22')
    args << dr_arg

    dr_arg = OpenStudio::Measure::OSArgument::makeStringArgument("winter_take_hours", false)
    dr_arg.setDisplayName("Hours for the winter during which the load is low")
    dr_arg.setDescription("Period for the winter months in 24-hour format a-b,c-d inclusive all hours, when the load is low")
    dr_arg.setDefaultValue('10-14')
    args << dr_arg

    dr_arg = OpenStudio::Measure::OSArgument::makeStringArgument("summer_months", false)
    dr_arg.setDisplayName("Which months count as summer")
    dr_arg.setDescription("List of months that count as summer months")
    dr_arg.setDefaultValue('4-10')
    args << dr_arg

    dr_arg = OpenStudio::Measure::OSArgument::makeStringArgument("winter_months", false)
    dr_arg.setDisplayName("Which months count as winter")
    dr_arg.setDescription("List of months that count as winter months")
    dr_arg.setDefaultValue('1-3,11-12')
    args << dr_arg

    dr_arg = OpenStudio::Measure::OSArgument::makeBoolArgument("shift_CW", false)
    dr_arg.setDisplayName("If clothes washer operation should be shifted to avoid the peaks")
    dr_arg.setDescription("The operation of clothes washer would be delayed or started earlier to avoid the peak hours.")
    dr_arg.setDefaultValue(false)
    args << dr_arg

    dr_arg = OpenStudio::Measure::OSArgument::makeBoolArgument("shift_CD", false)
    dr_arg.setDisplayName("If clothes dryer operation should be shifted to avoid the peaks")
    dr_arg.setDescription("The operation of clothes dryer would be delayed or started earlier to avoid the peak hours.")
    dr_arg.setDefaultValue(false)
    args << dr_arg

    dr_arg = OpenStudio::Measure::OSArgument::makeBoolArgument("shift_DW", false)
    dr_arg.setDisplayName("If dish washer operation should be shifted to avoid the peaks")
    dr_arg.setDescription("The operation of dishwasher would be delayed or started earlier to avoid the peak hours")
    dr_arg.setDefaultValue(false)
    args << dr_arg

    dr_arg = OpenStudio::Measure::OSArgument::makeBoolArgument("shift_PP", false)
    dr_arg.setDisplayName("If pool pump operation should be shifted to avoid the peaks")
    dr_arg.setDescription("The operation of pool pump would be shifted form peak hours to the take hours")
    dr_arg.setDefaultValue(false)
    args << dr_arg

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

    dr_dir = runner.getStringArgumentValue("dr_directory", user_arguments)

    summer_peak_hours = runner.getStringArgumentValue("summer_peak_hours", user_arguments)
    summer_take_hours = runner.getStringArgumentValue("summer_take_hours", user_arguments)
    winter_peak_hours = runner.getStringArgumentValue("winter_peak_hours", user_arguments)
    winter_take_hours = runner.getStringArgumentValue("winter_take_hours", user_arguments)
    summer_months = runner.getStringArgumentValue("summer_months", user_arguments)
    winter_months = runner.getStringArgumentValue("winter_months", user_arguments)

    def expand_interval_input(x)
      return x.split(',').map { |x| x.split('-').map { |x| x.to_i } }.sort.map { |x| (x[0]..x[1]).to_a }.flatten
      # return x.split(',').map{|x| x.split('-').map{|x| x.to_i}}.sort
      # '3-7,11-14' => [[3,7],[11,14]]
    end

    def array_interval_input(x)
      return x.split(',').map { |x| x.split('-').map { |x| x.to_i } }.sort
    end

    summer_peak_hours = array_interval_input(summer_peak_hours)
    winter_peak_hours = array_interval_input(winter_peak_hours)
    summer_take_hours = array_interval_input(summer_take_hours)
    winter_take_hours = array_interval_input(winter_take_hours)
    summer_months = expand_interval_input(summer_months)
    winter_months = expand_interval_input(winter_months)
    shift_CW = runner.getBoolArgumentValue("shift_CW", user_arguments)
    shift_CD = runner.getBoolArgumentValue("shift_CD", user_arguments)
    shift_DW = runner.getBoolArgumentValue("shift_DW", user_arguments)
    shift_PP = runner.getBoolArgumentValue("shift_PP", user_arguments)

    def avoid_peaks(day_sch, peak_hours, model, take_hour = [], simple_shifting = false)
      def create_new_day_schedule(times, values, model)
        new_day_sch = OpenStudio::Model::ScheduleDay.new(model)
        times.each_with_index do |time, index|
          new_day_sch.addValue(time, values[index])
        end
        return new_day_sch
      end

      old_times = day_sch.times
      old_vals = day_sch.values
      puts("Avoding peaks #{peak_hours}**********************")
      peak_hours.each do |peak|
        puts("Passing schedule: #{day_sch.times.map { |x| x.toString }},#{day_sch.values} to dodge peak to dodge #{peak}")
        if simple_shifting
          new_times, new_vals = shift_peak_to_take(day_sch, peak, take_hour, OpenStudio::Time)
          puts("Getting schedule: #{new_times.map { |x| x.toString }},#{new_vals} from shift_peak_to_take")
          day_sch = create_new_day_schedule(new_times, new_vals, model)
        else
          new_times, new_vals = dodge_peak(day_sch, peak, peak_hours, OpenStudio::Time)
          puts("Getting schedule: #{new_times.map { |x| x.toString }},#{new_vals} from dodge peak")
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

      puts("Got before Sch_Times: #{old_times.map { |x| x.toString }}")
      puts("Got after  Sch_Times: #{day_sch.times.map { |x| x.toString }}")
      puts("Got before Sch_Vals: #{old_vals}")
      puts("Got after Sch_Vals: #{day_sch.values}")
      return day_sch
    end

    if (shift_CW == false) and (shift_CD == false) and (shift_DW == false) and (shift_PP == false)
      runner.registerInfo("No appliance DR defined, ResidentialApplianceDR measure not applied")
      return true
    end

    units = Geometry.get_building_units(model, runner)

    units.each_with_index do |unit, unit_index|
      pool_pump_name = Constants.ObjectNamePoolPump(unit.name.to_s)
      model.getElectricEquipments.each do |ee|
        if ee.name.to_s == pool_pump_name
          puts("Hooray! found a pool pump #{ee}")
          puts("It's schedule is: #{ee.schedule.get}")
          existing_schedule = ee.schedule.get
          if not existing_schedule.to_ScheduleRuleset.empty?
            ruleset = existing_schedule.to_ScheduleRuleset.get
            rules = ruleset.scheduleRules()
            puts("Pool Rules vector: #{rules}")
            rules.each_with_index do |rule, index|
              day_sch = rule.daySchedule
              puts("Pool The #{index} day schedule is values ##{day_sch.times.map { |x| x.to_s }},#{day_sch.values}")
              puts("Pool For this specific dates #{rule.specificDates[0]}")
              puts("Start date: #{rule.startDate.get} and End date: #{rule.endDate.get}")
              puts("Month is #{rule.startDate.get.monthOfYear.value}")
            end
          end
        end
      end
    end

    units.each_with_index do |unit, unit_index|
      appliance_names = []
      appliance_names << Constants.ObjectNameClothesWasher(unit.name.to_s)
      appliance_names << Constants.ObjectNameClothesDryer("electric", unit.name.to_s)
      appliance_names << Constants.ObjectNameDishwasher(unit.name.to_s)
      appliance_names << Constants.ObjectNamePoolPump(unit.name.to_s)
      model.getElectricEquipments.each do |ee|
        puts("Checking EE: #{(ee.name.to_s)}")
        next if not appliance_names.include?(ee.name.to_s)

        puts("EE is to be rescheduled")
        puts("For unit #{unit.name.to_s} found ee named: #{ee.name.to_s}")
        if not ee.schedule.empty?
          puts("EE does have schedule")
          existing_schedule = ee.schedule.get
          new_schedule = OpenStudio::Model::ScheduleRuleset.new(model)
          new_schedule.setName('DR_' + existing_schedule.name.get)

          if not existing_schedule.to_ScheduleRuleset.empty?
            puts("EE does have ruleset schedule ...")
            ruleset = existing_schedule.to_ScheduleRuleset.get
            rules = ruleset.scheduleRules()
            puts("Rules vector: #{rules}")
            rules.each_with_index do |rule, index|
              day_sch = rule.daySchedule
              puts("The #{index} day schedule is values #{day_sch.values}")
              puts("For this dates #{rule.specificDates[0]}")
              # day_sch.times.each do |time|
              #   puts("Full time: #{time}, minutes #{time.totalMinutes}")
              # end
              # puts("This applies to #{rule.specificDates}")
              if ee.name.to_s == Constants.ObjectNamePoolPump(unit.name.to_s)
                # pool-pump
                start_date = rule.startDate.get
                end_date = rule.endDate.get
                if summer_months.include?(start_date.monthOfYear.value)

                  # use only the first take_hour if a list is provided.
                  summer_sch = avoid_peaks(day_sch, summer_peak_hours, model, summer_take_hours[0], true)
                  puts("Pool pump, Before after the schedule is: ")
                  puts("#{day_sch.times.map { |t| t.to_s }}")
                  puts("#{summer_sch.times.map { |t| t.to_s }}")
                  puts("#{day_sch.values}")
                  puts("#{summer_sch.values}")
                  summer_rule = OpenStudio::Model::ScheduleRule.new(new_schedule, summer_sch)
                  summer_rule.setName('summer_' + rule.name.get)
                  summer_rule.setStartDate(start_date)
                  summer_rule.setEndDate(end_date)
                  Schedule.set_weekday_rule(summer_rule)
                  Schedule.set_weekend_rule(summer_rule)
                elsif winter_months.include?(start_date.monthOfYear.value)
                  winter_sch = avoid_peaks(day_sch, winter_peak_hours, model, winter_take_hours[0], true)
                  puts("Pool pump, Before after the schedule is: ")
                  puts("#{day_sch.times.map { |t| t.to_s }}")
                  puts("#{winter_sch.times.map { |t| t.to_s }}")
                  puts("#{day_sch.values}")
                  puts("#{winter_sch.values}")
                  winter_rule = OpenStudio::Model::ScheduleRule.new(new_schedule, winter_sch)
                  winter_rule.setName('winter_' + rule.name.get)
                  winter_rule.setStartDate(start_date)
                  winter_rule.setEndDate(end_date)
                  Schedule.set_weekday_rule(winter_rule)
                  Schedule.set_weekend_rule(winter_rule)
                else
                  # if the month doesn't fall in either summer or winter, no need to change schedule. Continue with another appliance
                  next
                end

              else
                # other appliance
                puts("First date is #{rule.specificDates[0]}")
                puts("First month is #{rule.specificDates[0].monthOfYear.value}")
                summer_dates = rule.specificDates.select { |x| summer_months.include?(x.monthOfYear.value) }
                winter_dates = rule.specificDates.select { |x| winter_months.include?(x.monthOfYear.value) }
                summer_sch = avoid_peaks(day_sch, summer_peak_hours, model)
                winter_sch = avoid_peaks(day_sch, winter_peak_hours, model)
                puts("Summer dates: #{summer_dates} and winter dates #{winter_dates}")
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
            if ee.name.to_s == Constants.ObjectNamePoolPump(unit.name.to_s)
              # reset the schedule limit to 2 if it is a pool_pump
              puts("Printing design level")
              puts(ee.designLevel.get)
              old_level = ee.designLevel.get
              equip_def = ee.electricEquipmentDefinition
              puts("Equipment def: #{equip_def}")
              equip_def.setDesignLevel(old_level * 10)
              puts("New Eqip def: #{ee.electricEquipmentDefinition}")
            end
            puts
            def print_schedule(existing_schedule)
              if not existing_schedule.to_ScheduleRuleset.empty?
                ruleset = existing_schedule.to_ScheduleRuleset.get
                rules = ruleset.scheduleRules()
                puts("Rules vector: #{rules}")
                rules.each_with_index do |rule, index|
                  day_sch = rule.daySchedule
                  puts("Pool The #{index} day schedule is values ##{day_sch.times.map { |x| x.to_s }},#{day_sch.values}")

                  begin
                    puts("Pool For this specific dates #{rule.specificDates[0]}")
                  rescue
                    puts("No specific dates")
                  end

                  begin
                    puts("Start date: #{rule.startDate.get} and End date: #{rule.endDate.get}")
                  rescue
                    puts("no start/end date")
                  end
                end
              end
            end

            puts("Applying new schedule: #{ee.name.to_s}")
            print_schedule(new_schedule)
            ee.setSchedule(new_schedule)
            puts("After updating the schedule #{ee.name.to_s}")
            existing_schedule = ee.schedule.get
            print_schedule(existing_schedule)

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
