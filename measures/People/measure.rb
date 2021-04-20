class ResidentialClothesDryer < OpenStudio::Measure::ModelMeasure
  def name
    return "People"
  end

  def description
    return "Add 'Pierce' Thermal Comfort Model Type to the People object"
  end

  def modeler_description
    return "Add 'Pierce' Thermal Comfort Model Type to the People object. Hardcode like a boss"
  end

  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new
    return args
  end

  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    model.getSpaces.each do |space|
      space.people.each do |people|
        people.peopleDefinition.each do |peopleDef|
          peopleDef.pushThermalComfortModelType("Pierce")
        end
      end
    end
  end
end
