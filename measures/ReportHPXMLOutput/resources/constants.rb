# frozen_string_literal: true

class BO
  EnclosureWallAreaThermalBoundary = 'Enclosure: Wall Area Thermal Boundary'
  EnclosureWallAreaExterior = 'Enclosure: Wall Area Exterior'
  EnclosureFoundationWallAreaExterior = 'Enclosure: Foundation Wall Area Exterior'
  EnclosureFloorAreaConditioned = 'Enclosure: Floor Area Conditioned'
  EnclosureFloorAreaLighting = 'Enclosure: Floor Area Lighting'
  EnclosureFloorAreaFoundation = 'Enclosure: Floor Area Foundation'
  EnclosureCeilingAreaThermalBoundary = 'Enclosure: Ceiling Area Thermal Boundary'
  EnclosureRoofArea = 'Enclosure: Roof Area'
  EnclosureWindowArea = 'Enclosure: Window Area'
  EnclosureDoorArea = 'Enclosure: Door Area'
  EnclosureDuctAreaUnconditioned = 'Enclosure: Duct Area Unconditioned'
  EnclosureRimJoistAreaExterior = 'Enclosure: Rim Joist Area'
  EnclosureSlabExposedPerimeterThermalBoundary = 'Enclosure: Slab Exposed Perimeter Thermal Boundary'

  SystemsHeatingCapacity = 'Systems: Heating Capacity'
  SystemsCoolingCapacity = 'Systems: Cooling Capacity'
  SystemsHeatPumpBackupCapacity = 'Systems: Heat Pump Backup Capacity'
  SystemsWaterHeaterVolume = 'Systems: Water Heater Tank Volume'
  SystemsMechanicalVentilationFlowRate = 'Systems: Mechanical Ventilation Flow Rate'

  DesignTemperatureHeating = 'Design Temperature: Heating'
  DesignTemperatureCooling = 'Design Temperature: Cooling'

  DesignLoadsHeatingTotal = 'Design Loads Heating: Total'
  DesignLoadsHeatingDucts = 'Design Loads Heating: Ducts'
  DesignLoadsHeatingWindows = 'Design Loads Heating: Windows'
  DesignLoadsHeatingSkylights = 'Design Loads Heating: Skylights'
  DesignLoadsHeatingDoors = 'Design Loads Heating: Doors'
  DesignLoadsHeatingWalls = 'Design Loads Heating: Walls'
  DesignLoadsHeatingRoofs = 'Design Loads Heating: Roofs'
  DesignLoadsHeatingFloors = 'Design Loads Heating: Floors'
  DesignLoadsHeatingSlabs = 'Design Loads Heating: Slabs'
  DesignLoadsHeatingCeilings = 'Design Loads Heating: Ceilings'
  DesignLoadsHeatingInfilVent = 'Design Loads Heating: Infiltration/Ventilation'

  DesignLoadsCoolingSensibleTotal = 'Design Loads Cooling Sensible: Total'
  DesignLoadsCoolingSensibleDucts = 'Design Loads Cooling Sensible: Ducts'
  DesignLoadsCoolingSensibleWindows = 'Design Loads Cooling Sensible: Windows'
  DesignLoadsCoolingSensibleSkylights = 'Design Loads Cooling Sensible: Skylights'
  DesignLoadsCoolingSensibleDoors = 'Design Loads Cooling Sensible: Doors'
  DesignLoadsCoolingSensibleWalls = 'Design Loads Cooling Sensible: Walls'
  DesignLoadsCoolingSensibleRoofs = 'Design Loads Cooling Sensible: Roofs'
  DesignLoadsCoolingSensibleFloors = 'Design Loads Cooling Sensible: Floors'
  DesignLoadsCoolingSensibleSlabs = 'Design Loads Cooling Sensible: Slabs'
  DesignLoadsCoolingSensibleCeilings = 'Design Loads Cooling Sensible: Ceilings'
  DesignLoadsCoolingSensibleInfilVent = 'Design Loads Cooling Sensible: Infiltration/Ventilation'
  DesignLoadsCoolingSensibleIntGains = 'Design Loads Cooling Sensible: Internal Gains'

  DesignLoadsCoolingLatentTotal = 'Design Loads Cooling Latent: Total'
  DesignLoadsCoolingLatentDucts = 'Design Loads Cooling Latent: Ducts'
  DesignLoadsCoolingLatentInfilVent = 'Design Loads Cooling Latent: Infiltration/Ventilation'
  DesignLoadsCoolingLatentIntGains = 'Design Loads Cooling Latent: Internal Gains'

  def self.get_units(bldg_type)
    if bldg_type.include? 'Area'
      return 'ft^2'
    elsif bldg_type.include? 'Perimeter'
      return 'ft'
    elsif bldg_type.include? 'Capacity'
      return 'Btu/h'
    elsif bldg_type.include? 'Tank Volume'
      return 'gal'
    elsif bldg_type.include? 'Flow Rate'
      return 'cfm'
    elsif bldg_type == 'Fixed'
      return '1'
    elsif bldg_type.include? 'Design Temperature'
      return 'F'
    elsif bldg_type.include? 'Design Loads'
      return 'Btu/h'
    end

    fail "Unable to assign units to: #{bldg_type}"
  end
end
