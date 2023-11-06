# frozen_string_literal: true

class PV
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

  def self.calc_module_power_from_year(year_modules_manufactured)
    # Calculation from HEScore
    return 13.3 * year_modules_manufactured - 26494.0 # W/panel
  end

  def self.calc_losses_fraction_from_year(year_modules_manufactured, default_loss_fraction)
    # Calculation from HEScore
    age = Time.new.year - year_modules_manufactured
    age_losses = 1.0 - 0.995**Float(age)
    losses_fraction = 1.0 - (1.0 - default_loss_fraction) * (1.0 - age_losses)
    return losses_fraction
  end

  def self.get_default_inv_eff()
    return 0.96 # PVWatts default inverter efficiency
  end

  def self.get_default_system_losses(year_modules_manufactured = nil)
    default_loss_fraction = 0.14 # PVWatts default system losses
    if not year_modules_manufactured.nil?
      return calc_losses_fraction_from_year(year_modules_manufactured, default_loss_fraction)
    else
      return default_loss_fraction
    end
  end
end
