# frozen_string_literal: true

class BS
  WallAboveGradeConditioned = 'Enclosure: Wall Area Thermal Boundary'
  WallAboveGradeExterior = 'Enclosure: Wall Area Exterior'
  WallBelowGrade = 'Enclosure: Foundation Wall Area Exterior'
  FloorConditioned = 'Enclosure: Floor Area Conditioned'
  FloorLighting = 'Enclosure: Floor Area Lighting'
  Ceiling = 'Enclosure: Ceiling Area Thermal Boundary'
  Roof = 'Enclosure: Roof Area'
  Window = 'Enclosure: Window Area'
  Door = 'Enclosure: Door Area'
  DuctUnconditioned = 'Enclosure: Duct Area Unconditioned'
  RimJoistAboveGradeExterior = 'Enclosure: Rim Joist Area'
  SlabPerimeterExposedConditioned = 'Enclosure: Slab Exposed Perimeter Thermal Boundary'
  HeatingSystem = 'Systems: Heating Capacity'
  CoolingSystem = 'Systems: Cooling Capacity'
  HeatPumpBackup = 'Systems: Heat Pump Backup Capacity'
  WaterHeater = 'Systems: Water Heater Tank Volume'
  FlowRateMechanicalVentilation = 'Systems: Mechanical Ventilation Flow Rate'

  def self.get_units(cost_mult_type)
    if cost_mult_type.include?('Area')
      return 'ft^2'
    elsif cost_mult_type.include?('Perimeter')
      return 'ft'
    elsif cost_mult_type.include?('Capacity')
      return 'kBtu/h'
    elsif cost_mult_type.include?('Tank Volume')
      return 'gal'
    elsif cost_mult_type.include?('Flow Rate')
      return 'cfm'
    elsif cost_mult_type == 'Fixed'
      return '1'
    end

    fail "Unable to assign units to: #{cost_mult_type}"
  end
end
