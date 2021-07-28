# frozen_string_literal: true

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

resources_path = File.absolute_path(File.join(File.dirname(__FILE__), '../HPXMLtoOpenStudio/resources'))
unless File.exist? resources_path
  resources_path = File.join(OpenStudio::BCLMeasure::userMeasuresDir.to_s, 'HPXMLtoOpenStudio/resources') # Hack to run measures in the OS App since applied measures are copied off into a temporary directory
end
require File.join(resources_path, 'constants')
require File.join(resources_path, 'geometry')
require File.join(resources_path, 'hvac')
require File.join(resources_path, 'weather')

# start the measure
class ProcessCeilingFan < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    return 'Set Residential Ceiling Fan'
  end

  # human readable description
  def description
    return "Adds (or replaces) residential ceiling fan(s) and schedule in all finished spaces. For multifamily buildings, the ceiling fan(s) can be set for all units of the building.#{Constants.WorkflowDescription}"
  end

  # human readable description of modeling approach
  def modeler_description
    return 'Since there is no Ceiling Fan object in OpenStudio/EnergyPlus, we look for an ElectricEquipment object with the name that denotes it is residential ceiling fan. If one is found, it is replaced with the specified properties. Otherwise, a new such object is added to the model. Note: This measure requires the number of bedrooms/bathrooms to have already been assigned.'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # make a string argument for specified number
    specified_num = OpenStudio::Measure::OSArgument::makeIntegerArgument('specified_num', true)
    specified_num.setDisplayName('Specified Number')
    specified_num.setUnits('#/unit')
    specified_num.setDescription('Total number of fans.')
    specified_num.setDefaultValue(1)
    args << specified_num

    # make a double argument for power
    power = OpenStudio::Measure::OSArgument::makeDoubleArgument('power', true)
    power.setDisplayName('Power')
    power.setUnits('W')
    power.setDescription('Power consumption per fan assuming it runs at medium speed.')
    power.setDefaultValue(45.0)
    args << power

    # make a double argument for cooling setpoint offset
    cooling_setpoint_offset = OpenStudio::Measure::OSArgument::makeDoubleArgument('cooling_setpoint_offset', true)
    cooling_setpoint_offset.setDisplayName('Cooling Setpoint Offset')
    cooling_setpoint_offset.setUnits('degrees F')
    cooling_setpoint_offset.setDescription('Increase in cooling set point due to fan usage.')
    cooling_setpoint_offset.setDefaultValue(0)
    args << cooling_setpoint_offset

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    specified_num = runner.getIntegerArgumentValue('specified_num', user_arguments)
    power = runner.getDoubleArgumentValue('power', user_arguments)
    cooling_setpoint_offset = runner.getDoubleArgumentValue('cooling_setpoint_offset', user_arguments)

    # get building units
    units = Geometry.get_building_units(model, runner)
    if units.nil?
      return false
    end

    schedules_file = SchedulesFile.new(runner: runner, model: model)
    if not schedules_file.validated?
      return false
    end

    weather = WeatherProcess.new(model, runner)
    if weather.error?
      return false
    end

    sch = nil
    units.each do |unit|
      HVAC.remove_ceiling_fans(runner, model, unit)

      success, sch = HVAC.apply_ceiling_fans(model, unit, runner, weather, specified_num, power,
                                             cooling_setpoint_offset, sch, schedules_file)
      return false if not success
    end # units

    schedules_file.set_vacancy(col_name: 'ceiling_fan')

    return true
  end
end

# register the measure to be used by the application
ProcessCeilingFan.new.registerWithApplication
