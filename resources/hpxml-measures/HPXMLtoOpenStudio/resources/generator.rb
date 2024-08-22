# frozen_string_literal: true

# Collection of methods for adding generator-related OpenStudio objects.
module Generator
  # Apply a on-site power generator to the model using OpenStudio GeneratorMicroTurbine and ElectricLoadCenterDistribution objects.
  # The system may be shared, in which case annual consumption (kBtu) and output (kWh) are apportioned to the dwelling unit by total number of bedrooms served.
  # A new ElectricLoadCenterDistribution object is created for each generator.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param nbeds [Integer] Number of bedrooms in the dwelling unit
  # @param generator [HPXML::Generator] Object that defines a single generator that provides on-site power
  # @param unit_multiplier [Integer] Number of similar dwelling units
  # @return [nil]
  def self.apply(model, nbeds, generator, unit_multiplier)
    obj_name = generator.id

    # Apply unit multiplier
    annual_consumption_kbtu = generator.annual_consumption_kbtu * unit_multiplier
    annual_output_kwh = generator.annual_output_kwh * unit_multiplier

    if generator.is_shared_system
      # Apportion to single dwelling unit by # bedrooms
      fail if generator.number_of_bedrooms_served.to_f <= nbeds.to_f # EPvalidator.xml should prevent this

      annual_consumption_kbtu = annual_consumption_kbtu * nbeds.to_f / generator.number_of_bedrooms_served.to_f
      annual_output_kwh = annual_output_kwh * nbeds.to_f / generator.number_of_bedrooms_served.to_f
    end

    input_w = UnitConversions.convert(annual_consumption_kbtu, 'kBtu', 'Wh') / 8760.0
    output_w = UnitConversions.convert(annual_output_kwh, 'kWh', 'Wh') / 8760.0
    efficiency = output_w / input_w
    fail if efficiency > 1.0 # EPvalidator.xml should prevent this

    curve_biquadratic_constant = create_curve_biquadratic_constant(model)
    curve_cubic_constant = create_curve_cubic_constant(model)

    gmt = OpenStudio::Model::GeneratorMicroTurbine.new(model)
    gmt.setName("#{obj_name} generator")
    gmt.setFuelType(EPlus.fuel_type(generator.fuel_type))
    gmt.setReferenceElectricalPowerOutput(output_w)
    gmt.setMinimumFullLoadElectricalPowerOutput(output_w - 0.001)
    gmt.setMaximumFullLoadElectricalPowerOutput(output_w)
    gmt.setReferenceElectricalEfficiencyUsingLowerHeatingValue(efficiency)
    gmt.setFuelHigherHeatingValue(50000)
    gmt.setFuelLowerHeatingValue(50000)
    gmt.setStandbyPower(0.0)
    gmt.setAncillaryPower(0.0)
    gmt.electricalPowerFunctionofTemperatureandElevationCurve.remove
    gmt.electricalEfficiencyFunctionofTemperatureCurve.remove
    gmt.electricalEfficiencyFunctionofPartLoadRatioCurve.remove
    gmt.setElectricalPowerFunctionofTemperatureandElevationCurve(curve_biquadratic_constant)
    gmt.setElectricalEfficiencyFunctionofTemperatureCurve(curve_cubic_constant)
    gmt.setElectricalEfficiencyFunctionofPartLoadRatioCurve(curve_cubic_constant)

    elcd = OpenStudio::Model::ElectricLoadCenterDistribution.new(model)
    elcd.setName("#{obj_name} elec load center dist")
    elcd.setGeneratorOperationSchemeType('Baseload')
    elcd.addGenerator(gmt)
    elcd.setElectricalBussType('AlternatingCurrent')
  end

  # Create a cubic constant curve for electrical efficiency function of temperature and part load ratio.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @return [OpenStudio::Model::CurveCubic] OpenStudio CurveCubic object
  def self.create_curve_cubic_constant(model)
    constant_cubic = OpenStudio::Model::CurveCubic.new(model)
    constant_cubic.setName('ConstantCubic')
    constant_cubic.setCoefficient1Constant(1)
    constant_cubic.setCoefficient2x(0)
    constant_cubic.setCoefficient3xPOW2(0)
    constant_cubic.setCoefficient4xPOW3(0)
    # constant_cubic.setMinimumValueofx(-100)
    # constant_cubic.setMaximumValueofx(100)
    return constant_cubic
  end

  # Create a biquadratic constant curve for electrical power function of temperature and elevation.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @return [OpenStudio::Model::CurveBiquadratic] OpenStudio CurveBiquadratic object
  def self.create_curve_biquadratic_constant(model)
    const_biquadratic = OpenStudio::Model::CurveBiquadratic.new(model)
    const_biquadratic.setName('ConstantBiquadratic')
    const_biquadratic.setCoefficient1Constant(1)
    const_biquadratic.setCoefficient2x(0)
    const_biquadratic.setCoefficient3xPOW2(0)
    const_biquadratic.setCoefficient4y(0)
    const_biquadratic.setCoefficient5yPOW2(0)
    const_biquadratic.setCoefficient6xTIMESY(0)
    # const_biquadratic.setMinimumValueofx(-100)
    # const_biquadratic.setMaximumValueofx(100)
    # const_biquadratic.setMinimumValueofy(-100)
    # const_biquadratic.setMaximumValueofy(100)
    return const_biquadratic
  end
end
