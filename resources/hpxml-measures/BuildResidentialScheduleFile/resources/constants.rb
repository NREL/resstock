# frozen_string_literal: true

class ScheduleColumns
  # Strings --------------------

  def self.Occupants
    return 'occupants'
  end

  def self.LightingInterior
    return 'lighting_interior'
  end

  def self.LightingExterior
    return 'lighting_exterior'
  end

  def self.LightingGarage
    return 'lighting_garage'
  end

  def self.LightingExteriorHoliday
    return 'lighting_exterior_holiday'
  end

  def self.CookingRange
    return 'cooking_range'
  end

  def self.Refrigerator
    return 'refrigerator'
  end

  def self.ExtraRefrigerator
    return 'extra_refrigerator'
  end

  def self.Freezer
    return 'freezer'
  end

  def self.Dishwasher
    return 'dishwasher'
  end

  def self.ClothesWasher
    return 'clothes_washer'
  end

  def self.ClothesDryer
    return 'clothes_dryer'
  end

  def self.CeilingFan
    return 'ceiling_fan'
  end

  def self.PlugLoadsOther
    return 'plug_loads_other'
  end

  def self.PlugLoadsTV
    return 'plug_loads_tv'
  end

  def self.PlugLoadsVehicle
    return 'plug_loads_vehicle'
  end

  def self.PlugLoadsWellPump
    return 'plug_loads_well_pump'
  end

  def self.FuelLoadsGrill
    return 'fuel_loads_grill'
  end

  def self.FuelLoadsLighting
    return 'fuel_loads_lighting'
  end

  def self.FuelLoadsFireplace
    return 'fuel_loads_fireplace'
  end

  def self.PoolPump
    return 'pool_pump'
  end

  def self.PoolHeater
    return 'pool_heater'
  end

  def self.HotTubPump
    return 'hot_tub_pump'
  end

  def self.HotTubHeater
    return 'hot_tub_heater'
  end

  def self.HotWaterDishwasher
    return 'hot_water_dishwasher'
  end

  def self.HotWaterClothesWasher
    return 'hot_water_clothes_washer'
  end

  def self.HotWaterFixtures
    return 'hot_water_fixtures'
  end

  def self.Vacancy
    return 'vacancy'
  end

  def self.ColNames
    # col_name => affected_by_vacancy
    return {
      ScheduleColumns.Occupants => true,
      ScheduleColumns.LightingInterior => true,
      ScheduleColumns.LightingExterior => true,
      ScheduleColumns.LightingGarage => true,
      ScheduleColumns.LightingExteriorHoliday => true,
      ScheduleColumns.CookingRange => true,
      ScheduleColumns.Refrigerator => false,
      ScheduleColumns.ExtraRefrigerator => false,
      ScheduleColumns.Freezer => false,
      ScheduleColumns.Dishwasher => true,
      ScheduleColumns.ClothesWasher => true,
      ScheduleColumns.ClothesDryer => true,
      ScheduleColumns.CeilingFan => true,
      ScheduleColumns.PlugLoadsOther => true,
      ScheduleColumns.PlugLoadsTV => true,
      ScheduleColumns.PlugLoadsVehicle => true,
      ScheduleColumns.PlugLoadsWellPump => true,
      ScheduleColumns.FuelLoadsGrill => true,
      ScheduleColumns.FuelLoadsLighting => true,
      ScheduleColumns.FuelLoadsFireplace => true,
      ScheduleColumns.PoolPump => false,
      ScheduleColumns.PoolHeater => false,
      ScheduleColumns.HotTubPump => false,
      ScheduleColumns.HotTubHeater => false,
      ScheduleColumns.HotWaterDishwasher => true,
      ScheduleColumns.HotWaterClothesWasher => true,
      ScheduleColumns.HotWaterFixtures => true,
      ScheduleColumns.Vacancy => nil,
    }
  end
end
