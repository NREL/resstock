# frozen_string_literal: true

class BS
  Fixed = 'Fixed'
  WallAreaAboveGradeConditioned = 'Wall Area Above-Grade Conditioned'
  WallAreaAboveGradeExterior = 'Wall Area Above-Grade Exterior'
  WallAreaBelowGrade = 'Wall Area Below-Grade'
  FloorAreaConditioned = 'Floor Area Conditioned'
  FloorAreaAttic = 'Floor Area Attic'
  FloorAreaLighting = 'Floor Area Lighting'
  RoofArea = 'Roof Area'
  WindowArea = 'Window Area'
  DoorArea = 'Door Area'
  DuctUnconditionedSurfaceArea = 'Duct Unconditioned Surface Area'
  SizeHeatingSystem = 'Size Heating System'
  SizeCoolingSystem = 'Size Cooling System'
  SizeHeatPumpBackup = 'Size Heat Pump Backup'
  SizeWaterHeater = 'Size Water Heater'
  FlowRateMechanicalVentilation = 'Flow Rate Mechanical Ventilation'
  SlabPerimeterExposedConditioned = 'Slab Perimeter Exposed Conditioned'
  RimJoistAreaAboveGradeExterior = 'Rim Joist Area Above-Grade Exterior'

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
