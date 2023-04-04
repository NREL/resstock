# frozen_string_literal: true

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

# start the measure
class AddThermalComfortModelTypes < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    # Measure name should be the title case of the class name.
    return 'AddThermalComfortModelTypes'
  end

  # human readable description
  def description
    return 'Adds to the model (A) any of the available thermal comfort model types, and (B) work efficiency, clothing insulation, and air velocity constant schedules.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'Specify any of the thermal comfort model types to add to People:Definition objects in the model. Specify constant values corresponding to the work efficiency, clothing insulation, and air velocity schedules.'
  end

  # define the arguments that the user will input
  def arguments(_model)
    args = OpenStudio::Measure::OSArgumentVector.new

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('thermal_comfort_model_type_fanger', true)
    arg.setDisplayName('Thermal Comfort Model Type: Fanger')
    arg.setDescription('Whether to add the Fanger thermal comfort model type.')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('thermal_comfort_model_type_pierce', true)
    arg.setDisplayName('Thermal Comfort Model Type: Pierce')
    arg.setDescription('Whether to add the Pierce thermal comfort model type.')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('thermal_comfort_model_type_ksu', true)
    arg.setDisplayName('Thermal Comfort Model Type: KSU')
    arg.setDescription('Whether to add the KSU thermal comfort model type.')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('thermal_comfort_model_type_adaptiveash55', true)
    arg.setDisplayName('Thermal Comfort Model Type: AdaptiveASH55')
    arg.setDescription('Whether to add the AdaptiveASH55 thermal comfort model type.')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('thermal_comfort_model_type_adaptivecen15251', true)
    arg.setDisplayName('Thermal Comfort Model Type: AdaptiveCEN15251')
    arg.setDescription('Whether to add the AdaptiveCEN15251 thermal comfort model type.')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('thermal_comfort_model_type_coolingeffectash55', true)
    arg.setDisplayName('Thermal Comfort Model Type: CoolingEffectASH55')
    arg.setDescription('Whether to add the CoolingEffectASH55 thermal comfort model type.')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('thermal_comfort_model_type_ankledraftash55', true)
    arg.setDisplayName('Thermal Comfort Model Type: AnkleDraftASH55')
    arg.setDescription('Whether to add the AnkleDraftASH55 thermal comfort model type.')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('work_efficiency_schedule_value', true)
    arg.setDisplayName('Work Efficiency Schedule Value')
    arg.setUnits('Frac')
    arg.setDescription('Specify the constant work efficiency schedule value.')
    arg.setDefaultValue(0.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('clothing_insulation_schedule_value', true)
    arg.setDisplayName('Clothing Insulation Schedule Value')
    arg.setUnits('Frac')
    arg.setDescription('Specify the constant clothing insulation schedule value.')
    arg.setDefaultValue(0.6)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('air_velocity_schedule_value', true)
    arg.setDisplayName('Air Velocity Schedule Value')
    arg.setUnits('Frac')
    arg.setDescription('Specify the constant air velocity schedule value.')
    arg.setDefaultValue(0.1)
    args << arg

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
    thermal_comfort_model_type_fanger = runner.getBoolArgumentValue('thermal_comfort_model_type_fanger', user_arguments)
    thermal_comfort_model_type_pierce = runner.getBoolArgumentValue('thermal_comfort_model_type_pierce', user_arguments)
    thermal_comfort_model_type_ksu = runner.getBoolArgumentValue('thermal_comfort_model_type_ksu', user_arguments)
    thermal_comfort_model_type_adaptiveash55 = runner.getBoolArgumentValue('thermal_comfort_model_type_adaptiveash55', user_arguments)
    thermal_comfort_model_type_adaptivecen15251 = runner.getBoolArgumentValue('thermal_comfort_model_type_adaptivecen15251', user_arguments)
    thermal_comfort_model_type_coolingeffectash55 = runner.getBoolArgumentValue('thermal_comfort_model_type_coolingeffectash55', user_arguments)
    thermal_comfort_model_type_ankledraftash55 = runner.getBoolArgumentValue('thermal_comfort_model_type_ankledraftash55', user_arguments)
    work_efficiency_schedule_value = runner.getDoubleArgumentValue('work_efficiency_schedule_value', user_arguments)
    clothing_insulation_schedule_value = runner.getDoubleArgumentValue('clothing_insulation_schedule_value', user_arguments)
    air_velocity_schedule_value = runner.getDoubleArgumentValue('air_velocity_schedule_value', user_arguments)

    if !thermal_comfort_model_type_fanger && !thermal_comfort_model_type_pierce && !thermal_comfort_model_type_ksu && !thermal_comfort_model_type_adaptiveash55 && !thermal_comfort_model_type_adaptivecen15251 && !thermal_comfort_model_type_coolingeffectash55 && !thermal_comfort_model_type_ankledraftash55
      runner.registerAsNotApplicable('No thermal comfort model types selected.')
      return true
    end

    people_definitions = model.getPeopleDefinitions
    peoples = model.getPeoples

    if people_definitions.size == 0 || peoples.size == 0
      runner.registerAsNotApplicable('No PeopleDefinition or People objects found in the model.')
      return true
    end

    people_definitions.each do |people_def|
      people_def.pushThermalComfortModelType('Fanger') if thermal_comfort_model_type_fanger
      people_def.pushThermalComfortModelType('Pierce') if thermal_comfort_model_type_pierce
      people_def.pushThermalComfortModelType('KSU') if thermal_comfort_model_type_ksu
      people_def.pushThermalComfortModelType('AdaptiveASH55') if thermal_comfort_model_type_adaptiveash55
      people_def.pushThermalComfortModelType('AdaptiveCEN15251') if thermal_comfort_model_type_adaptivecen15251
      people_def.pushThermalComfortModelType('CoolingEffectASH55') if thermal_comfort_model_type_coolingeffectash55
      people_def.pushThermalComfortModelType('AnkleDraftASH55') if thermal_comfort_model_type_ankledraftash55
    end

    peoples.each do |people|
      work_efficiency_schedule = OpenStudio::Model::ScheduleConstant.new(model)
      work_efficiency_schedule.setValue(work_efficiency_schedule_value)
      work_efficiency_schedule.setName('Work Efficiency Schedule')
      people.setWorkEfficiencySchedule(work_efficiency_schedule)

      clothing_insulation_schedule = OpenStudio::Model::ScheduleConstant.new(model)
      clothing_insulation_schedule.setValue(clothing_insulation_schedule_value)
      clothing_insulation_schedule.setName('Clothing Insulation Schedule')
      people.setClothingInsulationSchedule(clothing_insulation_schedule)

      air_velocity_schedule = OpenStudio::Model::ScheduleConstant.new(model)
      air_velocity_schedule.setValue(air_velocity_schedule_value)
      air_velocity_schedule.setName('Air Velocity Schedule')
      people.setAirVelocitySchedule(air_velocity_schedule)
    end

    return true
  end
end

# register the measure to be used by the application
AddThermalComfortModelTypes.new.registerWithApplication
