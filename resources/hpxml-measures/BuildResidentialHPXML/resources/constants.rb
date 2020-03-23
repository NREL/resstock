class Constants
  def self.Auto
    return 'auto'
  end

  def self.CoordRelative
    return 'relative'
  end

  def self.SizingAuto
    return 'autosize'
  end

  def self.FuelTypeElectric
    return 'electric'
  end

  def self.FuelTypeGas
    return 'gas'
  end

  def self.FuelTypePropane
    return 'propane'
  end

  def self.FuelTypeOil
    return 'oil'
  end

  def self.FuelTypeWood
    return 'wood'
  end

  # Numbers --------------------

  def self.MaxNumPhotovoltaics
    return 2
  end

  def self.MaxNumPlugLoads
    return 2
  end

  def self.NumDaysInMonths(is_leap_year = false)
    num_days_in_months = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    num_days_in_months[1] += 1 if is_leap_year
    return num_days_in_months
  end
end
