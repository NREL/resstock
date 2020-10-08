# load dependencies
require 'csv'

# start the measure
class AddIntervalScheduleFromFile < OpenStudio::Ruleset::ModelUserScript

  # display name
  def name
    return 'Add Interval Schedule From File'
  end

  # description
  def description
    return 'This measure adds a schedule object from a file of interval data'
  end

  # modeler description
  def modeler_description
    return 'This measure adds a ScheduleInterval object from a user-specified .csv file. The measure supports hourly and 15 min interval data for leap and non-leap years.  The .csv file must contain only schedule values in the first column with 8760, 8784, 35040, or 35136 rows specified. See the example .csv files in the tests directory of this measure.'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    # make an argumet for removing existing
    remove_existing_schedule_intervals = OpenStudio::Ruleset::OSArgument::makeBoolArgument('remove_existing_schedule_intervals', true)
    remove_existing_schedule_intervals.setDisplayName('Remove existing ScheduleInterval objects?')
    remove_existing_schedule_intervals.setDefaultValue(false)
    args << remove_existing_schedule_intervals

    # make an argument for schedule name
    schedule_name = OpenStudio::Ruleset::OSArgument::makeStringArgument('schedule_name', true)
    schedule_name.setDisplayName('Schedule Name:')
    schedule_name.setDefaultValue('Schedule From File')
    args << schedule_name

    # make an argument for file path
    file_path = OpenStudio::Ruleset::OSArgument.makeStringArgument('file_path', true)
    file_path.setDisplayName('Enter the path to the file that contains schedule values (follow template in test folder of this measure):')
    file_path.setDescription("Example: 'C:\\Projects\\values.csv'")
    args << file_path

    # make an argument for units
    unit_choices = OpenStudio::StringVector.new
    unit_choices << 'unitless'
    unit_choices << 'C'
    unit_choices << 'W'
    unit_choices << 'm/s'
    unit_choices << 'm^3/s'
    unit_choices << 'kg/s'
    unit_choices << 'Pa'
    unit_choice = OpenStudio::Ruleset::OSArgument::makeChoiceArgument('unit_choice', unit_choices, true)
    unit_choice.setDisplayName('Choose schedule units:')
    unit_choice.setDefaultValue('unitless')
    args << unit_choice

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
    remove_existing_schedule_intervals = runner.getBoolArgumentValue('remove_existing_schedule_intervals', user_arguments)
    schedule_name = runner.getStringArgumentValue('schedule_name', user_arguments)
    file_path = runner.getStringArgumentValue('file_path', user_arguments)
    unit_choice = runner.getOptionalStringArgumentValue('unit_choice', user_arguments)

    # get existing schedules
    schedule_intervals = model.getScheduleIntervals

    # report initial condition
    runner.registerInitialCondition("number of ScheduleInterval objects = #{schedule_intervals.size}")

    # remove existing schedules
    schedule_intervals.each(&:remove) if remove_existing_schedule_intervals

    # check schedule name for reasonableness
    if schedule_name == ''
      runner.registerError('Schedule name is blank. Input a schedule name.')
      return false
    end

    # check file path for reasonableness
    if file_path.empty?
      runner.registerError('Empty file path was entered.')
      return false
    end

    # strip out the potential leading and trailing quotes
    file_path.gsub!('"', '')

    # check if file exists
    if !File.exist? file_path
      runner.registerError("The file at path #{file_path} doesn't exist.")
      return false
    end  

    # read in csv values
    csv_values = CSV.read(file_path,{headers: false, converters: :float})
    num_rows = csv_values.length

    # create values for the timeseries
    schedule_values = OpenStudio::Vector.new(num_rows, 0.0)
    csv_values.each_with_index do |csv_value,i|
      schedule_values[i] = csv_value[0]
    end

    # infer interval
    interval = []
    if (num_rows == 8760) || (num_rows == 8784) #h ourly data
      interval = OpenStudio::Time.new(0, 1, 0)
    elsif (num_rows == 35_040) || (num_rows == 35_136) # 15 min interval data
      interval = OpenStudio::Time.new(0, 0, 15)
    else
      runner.registerError('This measure does not support non-hourly or non-15 min interval data.  Cast your values as 15-min or hourly interval data.  See the values template.')
      return false
    end

    # make a schedule
    startDate = OpenStudio::Date.new(OpenStudio::MonthOfYear.new(1), 1)
    timeseries = OpenStudio::TimeSeries.new(startDate, interval, schedule_values, "#{unit_choice}")
    schedule = OpenStudio::Model::ScheduleInterval::fromTimeSeries(timeseries, model)
    if schedule.empty?
      runner.registerError("Unable to make schedule from file at '#{file_path}'")
      return false
    end
    schedule = schedule.get
    schedule.setName(schedule_name)

    # reporting final condition of model
    runner.registerFinalCondition("Added schedule #{schedule_name} to the model.")

    return true
  end
end

# this allows the measure to be use by the application
AddIntervalScheduleFromFile.new.registerWithApplication