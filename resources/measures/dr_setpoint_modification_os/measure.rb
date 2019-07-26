# insert your copyright here

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

# start the measure
class DrSetpointModificationOS < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    # Measure name should be the title case of the class name.
    return 'DrSetpointModificationOS'
  end

  # human readable description
  def description
    return 'Modify the cooling setpoint of the HVAC system during a DR event'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'Modify the cooling setpoint of the HVAC system during a DR event'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # DR event schedule name
    dr_event_schedule = OpenStudio::Measure::OSArgument.makeStringArgument("dr_event_schedule", true)
    dr_event_schedule.setDisplayName("DR Event Schedule Name")
    dr_event_schedule.setDescription("Name of the schedule to use for setting the EMS code.")
    dr_event_schedule.setDefaultValue("dr_event_hvac")
    args << dr_event_schedule

    # Amount to raise cooling setpoint by during DR Event
    event_delta_t = OpenStudio::Measure::OSArgument.makeDoubleArgument("event_delta_t", true)
    event_delta_t.setDisplayName("Event Delta T")
    event_delta_t.setDescription("Amount to raise cooling setpoint by during DR Event.  Use negative number to decrease cooling setpoint during event.")
    event_delta_t.setUnits("degC")
    #event_delta_t.setMinValue(-20.0)
    #event_delta_t.setMaxValue(20.0)
    args << event_delta_t

    # Cooling setpoint schedule
    cooling_setpoint_schedule = OpenStudio::Measure::OSArgument.makeStringArgument("cooling_setpoint_schedule", true)
    cooling_setpoint_schedule.setDisplayName("Cooling Setpoint Schedule Name")
    cooling_setpoint_schedule.setDescription("Name of the cooling setpoint schedule to modify.")
    cooling_setpoint_schedule.setDefaultValue("res cooling setpoint")
    args << cooling_setpoint_schedule

    # Heating setpoint schedule
    heating_setpoint_schedule = OpenStudio::Measure::OSArgument.makeStringArgument("heating_setpoint_schedule", true)
    heating_setpoint_schedule.setDisplayName("Heating Setpoint Schedule Name")
    heating_setpoint_schedule.setDescription("Name of the heating setpoint schedule. Will not be changed, but needed for EMS script.")
    heating_setpoint_schedule.setDefaultValue("res heating setpoint")
    args << heating_setpoint_schedule

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
    event_delta_t = runner.getDoubleArgumentValue("event_delta_t", user_arguments)
    cooling_setpoint_schedule_name = runner.getStringArgumentValue("cooling_setpoint_schedule", user_arguments)
    heating_setpoint_schedule_name = runner.getStringArgumentValue("heating_setpoint_schedule", user_arguments)
    dr_event_schedule_name = runner.getStringArgumentValue("dr_event_schedule", user_arguments)

    # confirm schedules exist and load them

    # confirm cooling setpoint schedule exists
      cooling_setpoint_schedule = model.getObjectByTypeAndName('OS_Schedule_Ruleset'.to_IddObjectType, cooling_setpoint_schedule_name)
      if cooling_setpoint_schedule.is_initialized
        cooling_setpoint_schedule = cooling_setpoint_schedule.get.to_ScheduleRuleset.get
      else
        runner.registerError("ERROR.  Schedule #{cooling_setpoint_schedule_name} cannot be loaded")
        return false
      end

    # confirm heating setpoint schedule exists
      heating_setpoint_schedule = model.getObjectByTypeAndName('OS_Schedule_Ruleset'.to_IddObjectType, heating_setpoint_schedule_name)
      if heating_setpoint_schedule.is_initialized
        heating_setpoint_schedule = heating_setpoint_schedule.get.to_ScheduleRuleset.get
      else
        runner.registerError("ERROR.  Schedule #{heating_setpoint_schedule_name} cannot be loaded")
        return false
      end

    # confirm dr event schedule exists
      dr_event_schedule = model.getObjectByTypeAndName('OS_Schedule_Ruleset'.to_IddObjectType, dr_event_schedule_name)
      if dr_event_schedule.is_initialized
        dr_event_schedule = dr_event_schedule.get.to_ScheduleRuleset.get
      else
				dr_event_schedule = model.getObjectByTypeAndName('OS_Schedule_File'.to_IddObjectType, dr_event_schedule_name)
				if dr_event_schedule.is_initialized
					dr_event_schedule = dr_event_schedule.get.to_ScheduleFile.get
				else
					runner.registerError("ERROR.  Schedule #{dr_event_schedule_name} cannot be loaded")
					return false
				end	
      end

    # copy the heating and cooling setpoint schedules
    schedules_to_copy = Array[cooling_setpoint_schedule, heating_setpoint_schedule]
    schedules_to_copy.each do |schedule|
      schedule_copy = schedule.clone(model)
      schedule_copy = schedule_copy.to_ScheduleRuleset.get
      schedule_copy.setName("#{schedule.name.get.to_s}_copy")
      runner.registerInfo("Schedule '#{schedule_copy.name}' was added.")
    end

    # add ems code to modify setpoint schedules
    # create dr schedule sensor
    dr_schedule_value = OpenStudio::Model::EnergyManagementSystemSensor.new(model,"Schedule Value")
    dr_schedule_value.setName("#{dr_event_schedule_name}_sen")
    dr_schedule_value.setKeyName(dr_event_schedule_name)

    # create existing cooling setpoint sensor
    existing_cooling_setpoint = OpenStudio::Model::EnergyManagementSystemSensor.new(model,"Schedule Value")
    existing_cooling_setpoint.setName("existing_cooling_setpoint_sen")
    existing_cooling_setpoint.setKeyName("#{cooling_setpoint_schedule_name}_copy")

    # create existing heating setpoint sensor
    existing_heating_setpoint = OpenStudio::Model::EnergyManagementSystemSensor.new(model,"Schedule Value")
    existing_heating_setpoint.setName("existing_heating_setpoint_sen")
    existing_heating_setpoint.setKeyName("#{heating_setpoint_schedule_name}_copy")

    # create cooling setpoint actuator
    cooling_setpoint_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(cooling_setpoint_schedule,"Schedule:Year","Schedule Value")
    cooling_setpoint_actuator.setName("#{cooling_setpoint_schedule_name}_act")

    # create heating setpoint actuator
    heating_setpoint_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(heating_setpoint_schedule,"Schedule:Year","Schedule Value")
    heating_setpoint_actuator.setName("#{heating_setpoint_schedule_name}_act")
    
    # create ems program
    thermostat_shift_program = OpenStudio::Model::EnergyManagementSystemProgram.new(model)
    thermostat_shift_program.setName("thermostat_shift_program")
    thermostat_shift_program_body = <<-EMS
      IF (@Abs #{dr_schedule_value.name.get.to_s}) > 1.0E-8
        SET #{cooling_setpoint_actuator.name.get.to_s} = #{existing_cooling_setpoint.name.get.to_s} + #{event_delta_t} * #{dr_schedule_value.name.get.to_s}
      ELSE
        SET #{cooling_setpoint_actuator.name.get.to_s} = #{existing_cooling_setpoint.name.get.to_s}
      ENDIF
      IF #{cooling_setpoint_actuator.name.get.to_s} < #{existing_heating_setpoint.name.get.to_s}
        SET #{heating_setpoint_actuator.name.get.to_s} = #{cooling_setpoint_actuator.name.get.to_s} - 1.0,
      ELSE
        SET #{heating_setpoint_actuator.name.get.to_s} = #{existing_heating_setpoint.name.get.to_s}
      ENDIF  
    EMS
    thermostat_shift_program.setBody(thermostat_shift_program_body)
    
    # create ems program calling manager
    thermostat_shift_program_calling_manager = OpenStudio::Model::EnergyManagementSystemProgramCallingManager.new(model)
    thermostat_shift_program_calling_manager.setName("thermostat_shift_program_calling_manager")
    thermostat_shift_program_calling_manager.setProgram(thermostat_shift_program,0)
    thermostat_shift_program_calling_manager.setCallingPoint("BeginTimestepBeforePredictor")
    
    # specify ems output
    thermostat_shift_program_ems_output = model.getOutputEnergyManagementSystem
    thermostat_shift_program_ems_output.setActuatorAvailabilityDictionaryReporting("Verbose")
    thermostat_shift_program_ems_output.setInternalVariableAvailabilityDictionaryReporting("Verbose")
    thermostat_shift_program_ems_output.setEMSRuntimeLanguageDebugOutputLevel("Verbose")

    return true
  end
end

# register the measure to be used by the application
DrSetpointModificationOS.new.registerWithApplication
