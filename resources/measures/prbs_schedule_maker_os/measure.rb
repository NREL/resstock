# insert your copyright here

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

# start the measure
class PrbsScheduleMakerOS < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    # Measure name should be the title case of the class name.
    return 'PrbsScheduleMakerOS'
  end

  # human readable description
  def description
    return 'OS version of measure that makes a PRBS DR event schedule'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'OS version of measure that makes a PRBS DR event schedule'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    dr_event_schedule = OpenStudio::Measure::OSArgument.makeStringArgument("dr_event_schedule", true)
    dr_event_schedule.setDisplayName("DR Event Schedule Name")
    dr_event_schedule.setDescription("Name of the schedule to use for setting the EMS code.")
    dr_event_schedule.setDefaultValue("dr_event_hvac")
    args << dr_event_schedule

    minimum_value = OpenStudio::Measure::OSArgument.makeDoubleArgument('minimum_value', true)
    minimum_value.setDisplayName("Minimum Value for PRBS Signal")
    minimum_value.setDescription("The minimum value to use. Typically -1 or 0.")
    minimum_value.setDefaultValue(0.0)
    args << minimum_value
    
    maximum_value = OpenStudio::Measure::OSArgument.makeDoubleArgument('maximum_value', true)
    maximum_value.setDisplayName("Maximum Value for PRBS Signal")
    maximum_value.setDescription("The maximum value to use. Typically 0 or 1.")
    maximum_value.setDefaultValue(1.0)
    args << maximum_value
    
    timestep = OpenStudio::Measure::OSArgument.makeDoubleArgument('timestep', false)
    timestep.setDisplayName("Timestep (min)")
    timestep.setDescription("By default, the measure pulls the simulation timestep from the OpenStudio model. This argument provides the option to override that value.")
    args << timestep
    
    minimum_hold_duration = OpenStudio::Measure::OSArgument.makeDoubleArgument('minimum_hold_duration', false)
    minimum_hold_duration.setDisplayName("Minimum Hold Duration of DR State (min)")
    minimum_hold_duration.setDescription("Specifies the minimum hold duration of the DR state.  Cannot be shorter than ((1 / Nyquist frequency) = 2 * timestep); otherwise, input will be overridden.")
    args << minimum_hold_duration
		
    maximum_hold_duration = OpenStudio::Measure::OSArgument.makeDoubleArgument('maximum_hold_duration', false)
    maximum_hold_duration.setDisplayName("Maximum Hold Duration of DR State (min)")
    maximum_hold_duration.setDescription("Specifies the maximum hold duration of the DR state.  Cannot be longer than 3 hrs (180 min); otherwise, input will be overridden.")
    args << maximum_hold_duration
		
    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # assign the user inputs to variables
    dr_event_schedule_name = runner.getStringArgumentValue("dr_event_schedule", user_arguments)
    minimum_value = runner.getDoubleArgumentValue("minimum_value", user_arguments)
    maximum_value = runner.getDoubleArgumentValue("maximum_value", user_arguments)
    timestep = runner.getOptionalDoubleArgumentValue("timestep", user_arguments)
    minimum_hold_duration = runner.getOptionalDoubleArgumentValue("minimum_hold_duration", user_arguments)
    maximum_hold_duration = runner.getOptionalDoubleArgumentValue("maximum_hold_duration", user_arguments)
		
    # handle frequency arguments
    if timestep.is_initialized
      timestep = timestep.get
    else
			timestep_object = model.getTimestep
			timesteps_per_hour = timestep_object.numberOfTimestepsPerHour
      timestep = (60.0 / timesteps_per_hour).round
    end
    runner.registerValue('timestep_used', 'Timestep used, in minutes.', timestep)
		
    nyquist_frequency = 0.5 / Float(timestep)
    runner.registerValue('nyquist_frequency', 'Nyquist frequency, in min^{-1}', nyquist_frequency)
		
		default_maximum_hold_duration = 3.0 # hours
		
		# validate maximum hold duration 
    if maximum_hold_duration.is_initialized
      maximum_hold_duration = maximum_hold_duration.get
			# check against maximum value
			if maximum_hold_duration > default_maximum_hold_duration
        runner.registerWarning("Maximum hold duration must not exceed #{default_maximum_hold_duration.round(1)} hours; reducing from #{maximum_hold_duration.round()} min to #{default_maximum_hold_duration*60.round()} min")
				maximum_hold_duration = default_maximum_hold_duration*60
			end
			# check against minimum value
			if maximum_hold_duration < 2*timestep
        runner.registerWarning("Maximum hold duration must not be less than #{2*timestep.round()} min; increasing from #{maximum_hold_duration.round()} min to #{2*timestep.round()} min")
				maximum_hold_duration = 2*timestep
			end
		else
			runner.registerInfo("Maximum hold duration not specified; defaulting to #{default_maximum_hold_duration.round(1)} hours")
			maximum_hold_duration = default_maximum_hold_duration*60
    end
		
		# validate minimum hold duration 
    if minimum_hold_duration.is_initialized
      minimum_hold_duration = minimum_hold_duration.get
			# check against minimum value
			if minimum_hold_duration < 2*timestep
        runner.registerWarning("Minimum hold duration must not be less than #{2*timestep.round()} min; increasing from #{minimum_hold_duration.round()} min to #{2*timestep.round()} min")
				minimum_hold_duration = 2*timestep
			end
			# check against maximum value
			if minimum_hold_duration < default_maximum_hold_duration
        runner.registerWarning("Minimum hold duration must not exceed #{default_maximum_hold_duration.round(1)} hours; reducing from #{minimum_hold_duration.round()} min to #{default_maximum_hold_duration*60.round()} min")
				minimum_hold_duration = default_maximum_hold_duration
			end
		else	
			runner.registerInfo("Minimum hold duration not specified; defaulting to #{2*timestep.round()} min")
			minimum_hold_duration = 2*timestep
    end
		
		# compare minimum and maximum hold durations
		unless minimum_hold_duration <= maximum_hold_duration
			runner.registerWarning("Minimum hold duration must not exceed maximum hold duration; increasing minimum hold duration from #{minimum_hold_duration.round()} min to #{maximum_hold_duration.round()} min")
			minimum_hold_duration = maximum_hold_duration
		end
		
		# set frequency fractions
		min_nf_frac = (1.0 / maximum_hold_duration ) / nyquist_frequency
		max_nf_frac = (1.0 / minimum_hold_duration ) / nyquist_frequency
    runner.registerValue('min_nf_frac_used', 'Minimum fraction of Nyquist frequency used in measure.', min_nf_frac)
    runner.registerValue('max_nf_frac_used', 'Maximum fraction of Nyquist frequency used in measure.', max_nf_frac)
    runner.registerValue('max_timestep', 'Maximum timestep (min) used as unit in the new schedule.', 1.0 / (min_nf_frac * nyquist_frequency))
    min_timestep = (1.0 / (max_nf_frac * nyquist_frequency)).round # min
    if 60 % min_timestep != 0
      runner.registerError("The smallest timestep, #{min_timestep} min, is not a divisor of 60.")
      return false
    end
    runner.registerValue('min_timestep', 'Minimum timestep (min) used as a unit in the new schedule.', min_timestep)
		
    # compose the dr schedule
		filepath = File.join(File.dirname(File.dirname(File.dirname(__FILE__))),'files','PRBS_Schedule.csv')
		
    # actual schedule file
    minutes = 0;
    next_value = nil
    next_duration = nil
    next_num_timesteps = 0
    File.open(filepath, 'w') { |file| 
      while minutes < 8760*60
        if (next_num_timesteps == 0)
          next_value = ([0, 1].sample == 0) ? minimum_value : maximum_value
          next_duration = 1.0 / (rand(min_nf_frac..max_nf_frac) * nyquist_frequency) # minutes
          next_num_timesteps = (next_duration / Float(min_timestep)).round
        end
        while (minutes < 8760*60) and (next_num_timesteps > 0)
          file.write(next_value.to_s + "\n")
          next_num_timesteps = next_num_timesteps - 1
          minutes = minutes + min_timestep
        end
      end
    }
		
		# create dr schedule and assign prbs schedule data to it
		# create external file for prbs schedule data
		
		# if File.exists?(filepath)
			# runner.registerInfo("CSV file exists")
		# else
			# runner.registerInfo("CSV file does not exist")
		# end
		
		prbs_external_file = OpenStudio::Model::ExternalFile::getExternalFile(model, filepath)
		
		if prbs_external_file.is_initialized
			prbs_external_file = prbs_external_file.get
			puts "Found CSV file at: #{filepath}"
		else
			runner.registerError("File (#{filepath}) could not be found and cannot be assigned to ScheduleFile object(s)")
			return false
		end
		dr_event_schedule = OpenStudio::Model::ScheduleFile.new(prbs_external_file,1,0)
		dr_event_schedule.setName(dr_event_schedule_name)
		
    runner.registerInfo("Added schedule #{dr_event_schedule.name}")
		
    return true
  end
end

# register the measure to be used by the application
PrbsScheduleMakerOS.new.registerWithApplication
