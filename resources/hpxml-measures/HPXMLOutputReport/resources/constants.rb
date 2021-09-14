# frozen_string_literal: true

class BS
  WallAboveGradeConditioned = 'Surface Area: Wall Above-Grade Conditioned'
  WallAboveGradeExterior = 'Surface Area: Wall Above-Grade Exterior'
  WallBelowGrade = 'Surface Area: Wall Below-Grade'
  FloorConditioned = 'Surface Area: Floor Conditioned'
  FloorAttic = 'Surface Area: Floor Attic'
  FloorLighting = 'Surface Area: Floor Lighting'
  Roof = 'Surface Area: Roof'
  Window = 'Surface Area: Window'
  Door = 'Surface Area: Door'
  DuctUnconditioned = 'Surface Area: Duct Unconditioned'
  RimJoistAboveGradeExterior = 'Surface Area: Rim Joist Above-Grade Exterior'
  HeatingSystem = 'Size: Heating System'
  CoolingSystem = 'Size: Cooling System'
  HeatPumpBackup = 'Size: Heat Pump Backup'
  WaterHeater = 'Size: Water Heater'
  FlowRateMechanicalVentilation = 'Other: Flow Rate Mechanical Ventilation'
  SlabPerimeterExposedConditioned = 'Other: Slab Perimeter Exposed Conditioned'

  def self.get_units(cost_mult_type)
    if cost_mult_type.include?('Area')
      return 'ft^2'
    elsif cost_mult_type.include?('Perimeter')
      return 'ft'
    elsif cost_mult_type.include?('Size')
      if cost_mult_type.include?('Heating') || cost_mult_type.include?('Cooling') || cost_mult_type.include?('Heat Pump')
        return 'kBtu/h'
      else
        return 'gal'
      end
    elsif cost_mult_type.include?('Flow')
      return 'cfm'
    elsif cost_mult_type == 'Fixed'
      return '1'
    end

    fail "Unable to assign units to: #{cost_mult_type}"
  end
end
