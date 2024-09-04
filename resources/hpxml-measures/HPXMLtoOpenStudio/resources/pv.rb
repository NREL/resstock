# frozen_string_literal: true

# Collection of methods for adding photovoltaic-related OpenStudio objects.
module PV
  # Apply a photovoltaic system to the model using OpenStudio ElectricLoadCenterDistribution, ElectricLoadCenterInverterPVWatts, and GeneratorPVWatts objects.
  # The system may be shared, in which case max power is apportioned to the dwelling unit by total number of bedrooms served.
  # In case an ElectricLoadCenterDistribution object does not already exist, a new ElectricLoadCenterInverterPVWatts object is set on a new ElectricLoadCenterDistribution object.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param nbeds [Integer] Number of bedrooms in the dwelling unit
  # @param pv_system [HPXML::PVSystem] Object that defines a single solar electric photovoltaic (PV) system
  # @param unit_multiplier [Integer] Number of similar dwelling units
  # @return [nil]
  def self.apply(model, nbeds, pv_system, unit_multiplier)
    obj_name = pv_system.id

    # Apply unit multiplier
    max_power = pv_system.max_power_output * unit_multiplier

    if pv_system.is_shared_system
      # Apportion to single dwelling unit by # bedrooms
      fail if pv_system.number_of_bedrooms_served.to_f <= nbeds.to_f # EPvalidator.xml should prevent this

      max_power = max_power * nbeds.to_f / pv_system.number_of_bedrooms_served.to_f
    end

    elcds = model.getElectricLoadCenterDistributions
    if elcds.empty?
      elcd = OpenStudio::Model::ElectricLoadCenterDistribution.new(model)
      elcd.setName('PVSystem elec load center dist')

      ipvwatts = OpenStudio::Model::ElectricLoadCenterInverterPVWatts.new(model)
      ipvwatts.setName('PVSystem inverter')
      ipvwatts.setInverterEfficiency(pv_system.inverter.inverter_efficiency)

      elcd.setInverter(ipvwatts)
    else
      elcd = elcds[0]
    end

    gpvwatts = OpenStudio::Model::GeneratorPVWatts.new(model, max_power)
    gpvwatts.setName("#{obj_name} generator")
    gpvwatts.setSystemLosses(pv_system.system_losses_fraction)
    gpvwatts.setTiltAngle(pv_system.array_tilt)
    gpvwatts.setAzimuthAngle(pv_system.array_azimuth)
    if (pv_system.tracking == HPXML::PVTrackingTypeFixed) && (pv_system.location == HPXML::LocationRoof)
      gpvwatts.setArrayType('FixedRoofMounted')
    elsif (pv_system.tracking == HPXML::PVTrackingTypeFixed) && (pv_system.location == HPXML::LocationGround)
      gpvwatts.setArrayType('FixedOpenRack')
    elsif pv_system.tracking == HPXML::PVTrackingType1Axis
      gpvwatts.setArrayType('OneAxis')
    elsif pv_system.tracking == HPXML::PVTrackingType1AxisBacktracked
      gpvwatts.setArrayType('OneAxisBacktracking')
    elsif pv_system.tracking == HPXML::PVTrackingType2Axis
      gpvwatts.setArrayType('TwoAxis')
    end
    if pv_system.module_type == HPXML::PVModuleTypeStandard
      gpvwatts.setModuleType('Standard')
    elsif pv_system.module_type == HPXML::PVModuleTypePremium
      gpvwatts.setModuleType('Premium')
    elsif pv_system.module_type == HPXML::PVModuleTypeThinFilm
      gpvwatts.setModuleType('ThinFilm')
    end

    elcd.addGenerator(gpvwatts)
  end

  # Calculation from HEScore for module power from year.
  #
  # @param year_modules_manufactured [Integer] year of manufacture of the modules
  # @return [Double] the calculated module power from year (W/panel)
  def self.calc_module_power_from_year(year_modules_manufactured)
    return 13.3 * year_modules_manufactured - 26494.0 # W/panel
  end

  # Calculation from HEScore for losses fraction from year.
  #
  # @param year_modules_manufactured [Integer] year of manufacture of the modules
  # @param default_loss_fraction [Double] the default loss fraction
  # @return [Double] the calculated losses fraction from year
  def self.calc_losses_fraction_from_year(year_modules_manufactured, default_loss_fraction)
    age = Time.new.year - year_modules_manufactured
    age_losses = 1.0 - 0.995**Float(age)
    losses_fraction = 1.0 - (1.0 - default_loss_fraction) * (1.0 - age_losses)
    return losses_fraction
  end

  # Get the default inverter efficiency.
  #
  # @return [Double] the default inverter efficiency
  def self.get_default_inv_eff()
    return 0.96 # PVWatts default inverter efficiency
  end

  # Get the default system losses.
  #
  # @param year_modules_manufactured [Integer] year of manufacture of the modules
  # @return [Double] the default system losses
  def self.get_default_system_losses(year_modules_manufactured = nil)
    default_loss_fraction = 0.14 # PVWatts default system losses
    if not year_modules_manufactured.nil?
      return calc_losses_fraction_from_year(year_modules_manufactured, default_loss_fraction)
    else
      return default_loss_fraction
    end
  end
end
