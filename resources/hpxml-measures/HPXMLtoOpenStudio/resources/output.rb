# frozen_string_literal: true

class TE
  # Total Energy
  Total = 'Total'
  Net = 'Net'
end

class FT
  # Fuel Types
  Elec = 'Electricity'
  Gas = 'Natural Gas'
  Oil = 'Fuel Oil'
  Propane = 'Propane'
  WoodCord = 'Wood Cord'
  WoodPellets = 'Wood Pellets'
  Coal = 'Coal'
end

class EUT
  # End Use Types
  Heating = 'Heating'
  HeatingFanPump = 'Heating Fans/Pumps'
  HeatingHeatPumpBackup = 'Heating Heat Pump Backup'
  HeatingHeatPumpBackupFanPump = 'Heating Heat Pump Backup Fans/Pumps'
  Cooling = 'Cooling'
  CoolingFanPump = 'Cooling Fans/Pumps'
  HotWater = 'Hot Water'
  HotWaterRecircPump = 'Hot Water Recirc Pump'
  HotWaterSolarThermalPump = 'Hot Water Solar Thermal Pump'
  LightsInterior = 'Lighting Interior'
  LightsGarage = 'Lighting Garage'
  LightsExterior = 'Lighting Exterior'
  MechVent = 'Mech Vent'
  MechVentPreheat = 'Mech Vent Preheating'
  MechVentPrecool = 'Mech Vent Precooling'
  WholeHouseFan = 'Whole House Fan'
  Refrigerator = 'Refrigerator'
  Freezer = 'Freezer'
  Dehumidifier = 'Dehumidifier'
  Dishwasher = 'Dishwasher'
  ClothesWasher = 'Clothes Washer'
  ClothesDryer = 'Clothes Dryer'
  RangeOven = 'Range/Oven'
  CeilingFan = 'Ceiling Fan'
  Television = 'Television'
  PlugLoads = 'Plug Loads'
  Vehicle = 'Electric Vehicle Charging'
  WellPump = 'Well Pump'
  PoolHeater = 'Pool Heater'
  PoolPump = 'Pool Pump'
  PermanentSpaHeater = 'Permanent Spa Heater'
  PermanentSpaPump = 'Permanent Spa Pump'
  Grill = 'Grill'
  Lighting = 'Lighting'
  Fireplace = 'Fireplace'
  PV = 'PV'
  Generator = 'Generator'
  Battery = 'Battery'
end

class HWT
  # Hot Water Types
  ClothesWasher = 'Clothes Washer'
  Dishwasher = 'Dishwasher'
  Fixtures = 'Fixtures'
  DistributionWaste = 'Distribution Waste'
end

class LT
  # Load Types
  Heating = 'Heating: Delivered'
  HeatingHeatPumpBackup = 'Heating: Heat Pump Backup' # Needed for ERI calculation for dual-fuel heat pumps
  Cooling = 'Cooling: Delivered'
  HotWaterDelivered = 'Hot Water: Delivered'
  HotWaterTankLosses = 'Hot Water: Tank Losses'
  HotWaterDesuperheater = 'Hot Water: Desuperheater'
  HotWaterSolarThermal = 'Hot Water: Solar Thermal'
end

class CLT
  # Component Load Types
  Roofs = 'Roofs'
  Ceilings = 'Ceilings'
  Walls = 'Walls'
  RimJoists = 'Rim Joists'
  FoundationWalls = 'Foundation Walls'
  Doors = 'Doors'
  WindowsConduction = 'Windows Conduction'
  WindowsSolar = 'Windows Solar'
  SkylightsConduction = 'Skylights Conduction'
  SkylightsSolar = 'Skylights Solar'
  Floors = 'Floors'
  Slabs = 'Slabs'
  InternalMass = 'Internal Mass'
  Infiltration = 'Infiltration'
  NaturalVentilation = 'Natural Ventilation'
  MechanicalVentilation = 'Mechanical Ventilation'
  WholeHouseFan = 'Whole House Fan'
  Ducts = 'Ducts'
  InternalGains = 'Internal Gains'
  Lighting = 'Lighting'
end

class UHT
  # Unmet Hours Types
  Heating = 'Heating'
  Cooling = 'Cooling'
end

class RT
  # Resilience Types
  Battery = 'Battery'
end

class PLT
  # Peak Load Types
  Heating = 'Heating: Delivered'
  Cooling = 'Cooling: Delivered'
end

class PFT
  # Peak Fuel Types
  Summer = 'Summer'
  Winter = 'Winter'
  Annual = 'Annual'
end

class AFT
  # Airflow Types
  Infiltration = 'Infiltration'
  MechanicalVentilation = 'Mechanical Ventilation'
  NaturalVentilation = 'Natural Ventilation'
  WholeHouseFan = 'Whole House Fan'
end

class WT
  # Weather Types
  DrybulbTemp = 'Drybulb Temperature'
  WetbulbTemp = 'Wetbulb Temperature'
  RelativeHumidity = 'Relative Humidity'
  WindSpeed = 'Wind Speed'
  DiffuseSolar = 'Diffuse Solar Radiation'
  DirectSolar = 'Direct Solar Radiation'
end

class Outputs
  def self.get_total_hvac_capacities(hpxml)
    htg_cap, clg_cap, hp_backup_cap = 0.0, 0.0, 0.0
    hpxml.hvac_systems.each do |hvac_system|
      if hvac_system.is_a? HPXML::HeatingSystem
        next if hvac_system.is_heat_pump_backup_system

        htg_cap += hvac_system.heating_capacity.to_f
      elsif hvac_system.is_a? HPXML::CoolingSystem
        clg_cap += hvac_system.cooling_capacity.to_f
        if hvac_system.has_integrated_heating
          htg_cap += hvac_system.integrated_heating_system_capacity.to_f
        end
      elsif hvac_system.is_a? HPXML::HeatPump
        htg_cap += hvac_system.heating_capacity.to_f
        clg_cap += hvac_system.cooling_capacity.to_f
        if hvac_system.backup_type == HPXML::HeatPumpBackupTypeIntegrated
          hp_backup_cap += hvac_system.backup_heating_capacity.to_f
        elsif hvac_system.backup_type == HPXML::HeatPumpBackupTypeSeparate
          hp_backup_cap += hvac_system.backup_system.heating_capacity.to_f
        end
      end
    end
    return htg_cap, clg_cap, hp_backup_cap
  end
end
