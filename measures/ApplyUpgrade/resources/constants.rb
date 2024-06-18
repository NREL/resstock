# frozen_string_literal: true

class Constants
  def self.NumApplyUpgradeOptions
    return 25
  end

  def self.NumApplyUpgradesCostsPerOption
    return 2
  end

  def self.CostMultiplierChoices
    return [
      '',
      'Fixed (1)',
      'Wall Area, Above-Grade, Conditioned (ft^2)',
      'Wall Area, Above-Grade, Exterior (ft^2)',
      'Wall Area, Below-Grade (ft^2)',
      'Floor Area, Conditioned (ft^2)',
      'Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)',
      'Floor Area, Lighting (ft^2)',
      'Floor Area, Foundation (ft^2)',
      'Floor Area, Attic (ft^2)',
      'Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)',
      'Roof Area (ft^2)',
      'Window Area (ft^2)',
      'Door Area (ft^2)',
      'Duct Unconditioned Surface Area (ft^2)',
      'Rim Joist Area, Above-Grade, Exterior (ft^2)',
      'Slab Perimeter, Exposed, Conditioned (ft)',
      'Size, Heating System Primary (kBtu/h)',
      'Size, Heating System Secondary (kBtu/h)',
      'Size, Cooling System Primary (kBtu/h)',
      'Size, Heat Pump Backup Primary (kBtu/h)',
      'Size, Water Heater (gal)',
      'Flow Rate, Mechanical Ventilation (cfm)'
    ]
  end
end
