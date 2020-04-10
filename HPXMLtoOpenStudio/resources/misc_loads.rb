require_relative 'constants'
require_relative 'unit_conversions'
require_relative 'schedules'

class MiscLoads
  def self.apply_plug(model, plug_load_misc, plug_load_tv, schedule, cfa,
                      living_space)

    misc_kwh = 0
    if not plug_load_misc.nil?
      misc_kwh = plug_load_misc.kWh_per_year * plug_load_misc.usage_multiplier
    end
    tv_kwh = 0
    if not plug_load_tv.nil?
      tv_kwh = plug_load_tv.kWh_per_year * plug_load_tv.usage_multiplier
    end

    return if misc_kwh + tv_kwh <= 0

    sens_frac = plug_load_misc.frac_sensible
    lat_frac = plug_load_misc.frac_latent

    # check for valid inputs
    if (sens_frac < 0) || (sens_frac > 1)
      fail 'Sensible fraction must be greater than or equal to 0 and less than or equal to 1.'
    end
    if (lat_frac < 0) || (lat_frac > 1)
      fail 'Latent fraction must be greater than or equal to 0 and less than or equal to 1.'
    end
    if lat_frac + sens_frac > 1
      fail 'Sum of sensible and latent fractions must be less than or equal to 1.'
    end

    # Create schedule
    sch = MonthWeekdayWeekendSchedule.new(model, Constants.ObjectNameMiscPlugLoads + ' schedule', schedule.weekday_fractions, schedule.weekend_fractions, schedule.monthly_multipliers, 1.0, 1.0, true, true, Constants.ScheduleTypeLimitsFraction)

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
  end

  def self.get_residual_mels_default_values(cfa)
    annual_kwh = 0.91 * cfa
    frac_lost = 0.10
    frac_sens = (1.0 - frac_lost) * 0.95
    frac_lat = 1.0 - frac_sens - frac_lost
    return annual_kwh, frac_sens, frac_lat
  end

  def self.get_televisions_default_values(cfa, nbeds)
    annual_kwh = 413.0 + 0.0 * cfa + 69.0 * nbeds
    frac_lost = 0.0
    frac_sens = (1.0 - frac_lost) * 1.0
    frac_lat = 1.0 - frac_sens - frac_lost
    return annual_kwh, frac_sens, frac_lat
  end
end
