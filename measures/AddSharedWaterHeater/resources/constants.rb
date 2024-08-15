# frozen_string_literal: true

module Constants
  # Strings --------------------

  def self.ObjectNameSharedWaterHeater
    return 'shared water heater'
  end

  def self.WaterHeaterTypeHeatPump
    return 'heat pump water heater with storage and swing tanks'
  end

  def self.WaterHeaterTypeBoiler
    return 'boiler with storage tanks'
  end

  def self.WaterHeaterTypeCombiHeatPump
    return 'space-heating heat pump water heater with storage and swing tanks'
  end

  def self.WaterHeaterTypeCombiBoiler
    return 'space-heating boiler with storage tanks'
  end
end
