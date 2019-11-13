require_relative "constants"
require_relative "unit_conversions"
require_relative "schedules"

class MiscLoads
  def self.apply_plug(model, runner, misc_kwh, sens_frac, lat_frac,
                      weekday_sch, weekend_sch, monthly_sch, tv_kwh, cfa,
                      living_space)

    return true if misc_kwh + tv_kwh == 0

    # check for valid inputs
    if sens_frac < 0 or sens_frac > 1
      runner.registerError("Sensible fraction must be greater than or equal to 0 and less than or equal to 1.")
      return false
    end
    if lat_frac < 0 or lat_frac > 1
      runner.registerError("Latent fraction must be greater than or equal to 0 and less than or equal to 1.")
      return false
    end
    if lat_frac + sens_frac > 1
      runner.registerError("Sum of sensible and latent fractions must be less than or equal to 1.")
      return false
    end

    # Create schedule
    sch = MonthWeekdayWeekendSchedule.new(model, runner, Constants.ObjectNameMiscPlugLoads + " schedule", weekday_sch, weekend_sch, monthly_sch, mult_weekday = 1.0, mult_weekend = 1.0, normalize_values = true, create_sch_object = true, schedule_type_limits_name = Constants.ScheduleTypeLimitsFraction)
    if not sch.validated?
      return false
    end

    # Misc plug loads
    if misc_kwh > 0
      space_design_level = sch.calcDesignLevelFromDailykWh(misc_kwh / 365.0)

      # Add electric equipment for the mel
      mel_def = OpenStudio::Model::ElectricEquipmentDefinition.new(model)
      mel = OpenStudio::Model::ElectricEquipment.new(mel_def)
      mel.setName(Constants.ObjectNameMiscPlugLoads)
      mel.setEndUseSubcategory(Constants.ObjectNameMiscPlugLoads)
      mel.setSpace(living_space)
      mel_def.setName(Constants.ObjectNameMiscPlugLoads)
      mel_def.setDesignLevel(space_design_level)
      mel_def.setFractionRadiant(0.6 * sens_frac)
      mel_def.setFractionLatent(lat_frac)
      mel_def.setFractionLost(1 - sens_frac - lat_frac)
      mel.setSchedule(sch.schedule)
    end

    # Television
    tv_sens_frac = 1.0
    tv_lat_frac = 0.0

    if tv_kwh > 0
      space_design_level = sch.calcDesignLevelFromDailykWh(tv_kwh / 365.0)

      # Add electric equipment for the television
      mel_def = OpenStudio::Model::ElectricEquipmentDefinition.new(model)
      mel = OpenStudio::Model::ElectricEquipment.new(mel_def)
      mel.setName(Constants.ObjectNameMiscTelevision)
      mel.setEndUseSubcategory(Constants.ObjectNameMiscTelevision)
      mel.setSpace(living_space)
      mel_def.setName(Constants.ObjectNameMiscTelevision)
      mel_def.setDesignLevel(space_design_level)
      mel_def.setFractionRadiant(0.6 * tv_sens_frac)
      mel_def.setFractionLatent(tv_lat_frac)
      mel_def.setFractionLost(1 - tv_sens_frac - tv_lat_frac)
      mel.setSchedule(sch.schedule)
    end

    return true
  end

  def self.get_residual_mels_values(cfa)
    # Table 4.2.2.5(1) Lighting, Appliance and Miscellaneous Electric Loads in electric Reference Homes
    annual_kwh = 0.91 * cfa

    # Table 4.2.2(3). Internal Gains for Reference Homes
    load_sens = 7.27 * cfa # Btu/day
    load_lat = 0.38 * cfa # Btu/day
    total = UnitConversions.convert(annual_kwh, "kWh", "Btu") / 365.0 # Btu/day

    return annual_kwh, load_sens / total, load_lat / total
  end

  def self.get_televisions_values(cfa, nbeds)
    # Table 4.2.2.5(1) Lighting, Appliance and Miscellaneous Electric Loads in electric Reference Homes
    annual_kwh = 413.0 + 0.0 * cfa + 69.0 * nbeds

    # Table 4.2.2(3). Internal Gains for Reference Homes
    load_sens = 3861.0 + 645.0 * nbeds # Btu/day
    load_lat = 0.0 # Btu/day
    total = UnitConversions.convert(annual_kwh, "kWh", "Btu") / 365.0 # Btu/day

    return annual_kwh, load_sens / total, load_lat / total
  end
end
