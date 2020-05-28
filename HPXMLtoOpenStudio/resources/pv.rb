# frozen_string_literal: true

class PV
  def self.apply(model, pv_system)
    obj_name = pv_system.id

    generator = OpenStudio::Model::GeneratorPVWatts.new(model, pv_system.max_power_output)
    generator.setName("#{obj_name} generator")
    generator.setSystemLosses(pv_system.system_losses_fraction)
    generator.setTiltAngle(pv_system.array_tilt)
    generator.setAzimuthAngle(pv_system.array_azimuth)
    if (pv_system.tracking == HPXML::PVTrackingTypeFixed) && (pv_system.location == HPXML::LocationRoof)
      generator.setArrayType('FixedRoofMounted')
    elsif (pv_system.tracking == HPXML::PVTrackingTypeFixed) && (pv_system.location == HPXML::LocationGround)
      generator.setArrayType('FixedOpenRack')
    elsif pv_system.tracking == HPXML::PVTrackingType1Axis
      generator.setArrayType('OneAxis')
    elsif pv_system.tracking == HPXML::PVTrackingType1AxisBacktracked
      generator.setArrayType('OneAxisBacktracking')
    elsif pv_system.tracking == HPXML::PVTrackingType2Axis
      generator.setArrayType('TwoAxis')
    end
    if pv_system.module_type == HPXML::PVModuleTypeStandard
      generator.setModuleType('Standard')
    elsif pv_system.module_type == HPXML::PVModuleTypePremium
      generator.setModuleType('Premium')
    elsif pv_system.module_type == HPXML::PVModuleTypeThinFilm
      generator.setModuleType('ThinFilm')
    end

    electric_load_center_dist = generator.electricLoadCenterDistribution.get
    electric_load_center_dist.setName("#{obj_name} elec load center dist")

    inverter = OpenStudio::Model::ElectricLoadCenterInverterPVWatts.new(model)
    inverter.setName("#{obj_name} inverter")
    inverter.setInverterEfficiency(pv_system.inverter_efficiency)

    electric_load_center_dist.addGenerator(generator)
    electric_load_center_dist.setInverter(inverter)
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
