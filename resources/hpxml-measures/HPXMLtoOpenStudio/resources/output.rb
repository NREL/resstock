# frozen_string_literal: true

# TODO
module TE
  # Total Energy
  Total = 'Total'
  Net = 'Net'
end

# TODO
module FT
  # Fuel Types
  Elec = 'Electricity'
  Gas = 'Natural Gas'
  Oil = 'Fuel Oil'
  Propane = 'Propane'
  WoodCord = 'Wood Cord'
  WoodPellets = 'Wood Pellets'
  Coal = 'Coal'
end

# TODO
module EUT
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

# TODO
module HWT
  # Hot Water Types
  ClothesWasher = 'Clothes Washer'
  Dishwasher = 'Dishwasher'
  Fixtures = 'Fixtures'
  DistributionWaste = 'Distribution Waste'
end

# TODO
module LT
  # Load Types
  Heating = 'Heating: Delivered'
  HeatingHeatPumpBackup = 'Heating: Heat Pump Backup' # Needed for ERI calculation for dual-fuel heat pumps
  Cooling = 'Cooling: Delivered'
  HotWaterDelivered = 'Hot Water: Delivered'
  HotWaterTankLosses = 'Hot Water: Tank Losses'
  HotWaterDesuperheater = 'Hot Water: Desuperheater'
  HotWaterSolarThermal = 'Hot Water: Solar Thermal'
end

# TODO
module CLT
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

# TODO
module UHT
  # Unmet Hours Types
  Heating = 'Heating'
  Cooling = 'Cooling'
end

# TODO
module RT
  # Resilience Types
  Battery = 'Battery'
end

# TODO
module PLT
  # Peak Load Types
  Heating = 'Heating: Delivered'
  Cooling = 'Cooling: Delivered'
end

# TODO
module PFT
  # Peak Fuel Types
  Summer = 'Summer'
  Winter = 'Winter'
  Annual = 'Annual'
end

# TODO
module AFT
  # Airflow Types
  Infiltration = 'Infiltration'
  MechanicalVentilation = 'Mechanical Ventilation'
  NaturalVentilation = 'Natural Ventilation'
  WholeHouseFan = 'Whole House Fan'
end

# TODO
module WT
  # Weather Types
  DrybulbTemp = 'Drybulb Temperature'
  WetbulbTemp = 'Wetbulb Temperature'
  RelativeHumidity = 'Relative Humidity'
  WindSpeed = 'Wind Speed'
  DiffuseSolar = 'Diffuse Solar Radiation'
  DirectSolar = 'Direct Solar Radiation'
end

# TODO
module Outputs
  # TODO
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @return [TODO] TODO
  def self.get_total_hvac_capacities(hpxml_bldg)
    htg_cap, clg_cap, hp_backup_cap = 0.0, 0.0, 0.0
    unit_multiplier = hpxml_bldg.building_construction.number_of_units
    hpxml_bldg.hvac_systems.each do |hvac_system|
      if hvac_system.is_a? HPXML::HeatingSystem
        next if hvac_system.is_heat_pump_backup_system

        htg_cap += hvac_system.heating_capacity.to_f * unit_multiplier
      elsif hvac_system.is_a? HPXML::CoolingSystem
        clg_cap += hvac_system.cooling_capacity.to_f * unit_multiplier
        if hvac_system.has_integrated_heating
          htg_cap += hvac_system.integrated_heating_system_capacity.to_f * unit_multiplier
        end
      elsif hvac_system.is_a? HPXML::HeatPump
        htg_cap += hvac_system.heating_capacity.to_f * unit_multiplier
        clg_cap += hvac_system.cooling_capacity.to_f * unit_multiplier
        if hvac_system.backup_type == HPXML::HeatPumpBackupTypeIntegrated
          hp_backup_cap += hvac_system.backup_heating_capacity.to_f * unit_multiplier
        elsif hvac_system.backup_type == HPXML::HeatPumpBackupTypeSeparate
          hp_backup_cap += hvac_system.backup_system.heating_capacity.to_f * unit_multiplier
        end
      end
    end
    return htg_cap, clg_cap, hp_backup_cap
  end

  # TODO
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @return [TODO] TODO
  def self.get_total_hvac_airflows(hpxml_bldg)
    htg_cfm, clg_cfm = 0.0, 0.0
    unit_multiplier = hpxml_bldg.building_construction.number_of_units
    hpxml_bldg.hvac_systems.each do |hvac_system|
      if hvac_system.is_a? HPXML::HeatingSystem
        htg_cfm += hvac_system.heating_airflow_cfm.to_f * unit_multiplier
      elsif hvac_system.is_a? HPXML::CoolingSystem
        clg_cfm += hvac_system.cooling_airflow_cfm.to_f * unit_multiplier
        if hvac_system.has_integrated_heating
          htg_cfm += hvac_system.integrated_heating_system_airflow_cfm.to_f * unit_multiplier
        end
      elsif hvac_system.is_a? HPXML::HeatPump
        htg_cfm += hvac_system.heating_airflow_cfm.to_f * unit_multiplier
        clg_cfm += hvac_system.cooling_airflow_cfm.to_f * unit_multiplier
      end
    end
    return htg_cfm, clg_cfm
  end

  # TODO
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param results_out [TODO] TODO
  # @return [TODO] TODO
  def self.append_sizing_results(hpxml_bldgs, results_out)
    line_break = nil

    # Summary HVAC capacities
    results_out << ['HVAC Capacity: Heating (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| Outputs.get_total_hvac_capacities(hpxml_bldg)[0] }.sum(0.0).round(1)]
    results_out << ['HVAC Capacity: Cooling (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| Outputs.get_total_hvac_capacities(hpxml_bldg)[1] }.sum(0.0).round(1)]
    results_out << ['HVAC Capacity: Heat Pump Backup (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| Outputs.get_total_hvac_capacities(hpxml_bldg)[2] }.sum(0.0).round(1)]

    # HVAC design temperatures
    results_out << [line_break]
    results_out << ['HVAC Design Temperature: Heating (F)', (hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.header.manualj_heating_design_temp }.sum(0.0) / hpxml_bldgs.size).round(2)]
    results_out << ['HVAC Design Temperature: Cooling (F)', (hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.header.manualj_cooling_design_temp }.sum(0.0) / hpxml_bldgs.size).round(2)]

    # HVAC Building design loads
    results_out << [line_break]
    results_out << ['HVAC Design Load: Heating: Total (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.hdl_total * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Heating: Ducts (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.hdl_ducts * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Heating: Windows (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.hdl_windows * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Heating: Skylights (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.hdl_skylights * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Heating: Doors (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.hdl_doors * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Heating: Walls (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.hdl_walls * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Heating: Roofs (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.hdl_roofs * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Heating: Floors (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.hdl_floors * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Heating: Slabs (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.hdl_slabs * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Heating: Ceilings (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.hdl_ceilings * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Heating: Infiltration (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.hdl_infil * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Heating: Ventilation (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.hdl_vent * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Heating: Piping (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.hdl_piping * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Cooling Sensible: Total (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.cdl_sens_total * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Cooling Sensible: Ducts (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.cdl_sens_ducts * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Cooling Sensible: Windows (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.cdl_sens_windows * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Cooling Sensible: Skylights (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.cdl_sens_skylights * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Cooling Sensible: Doors (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.cdl_sens_doors * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Cooling Sensible: Walls (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.cdl_sens_walls * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Cooling Sensible: Roofs (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.cdl_sens_roofs * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Cooling Sensible: Floors (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.cdl_sens_floors * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Cooling Sensible: Slabs (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.cdl_sens_slabs * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Cooling Sensible: Ceilings (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.cdl_sens_ceilings * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Cooling Sensible: Infiltration (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.cdl_sens_infil * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Cooling Sensible: Ventilation (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.cdl_sens_vent * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Cooling Sensible: Internal Gains (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.cdl_sens_intgains * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Cooling Sensible: Blower Heat (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.cdl_sens_blowerheat * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Cooling Sensible: AED Excursion (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.cdl_sens_aedexcursion * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Cooling Latent: Total (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.cdl_lat_total * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Cooling Latent: Ducts (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.cdl_lat_ducts * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Cooling Latent: Infiltration (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.cdl_lat_infil * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Cooling Latent: Ventilation (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.cdl_lat_vent * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]
    results_out << ['HVAC Design Load: Cooling Latent: Internal Gains (Btu/h)', hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.hvac_plant.cdl_lat_intgains * hpxml_bldg.building_construction.number_of_units }.sum(0.0).round(1)]

    # HVAC Zone design loads
    hpxml_bldgs.each do |hpxml_bldg|
      hpxml_bldg.conditioned_zones.each do |zone|
        next if zone.id.start_with? Constants::AutomaticallyAdded

        results_out << [line_break]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Heating: Total (Btu/h)", zone.hdl_total.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Heating: Ducts (Btu/h)", zone.hdl_ducts.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Heating: Windows (Btu/h)", zone.hdl_windows.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Heating: Skylights (Btu/h)", zone.hdl_skylights.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Heating: Doors (Btu/h)", zone.hdl_doors.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Heating: Walls (Btu/h)", zone.hdl_walls.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Heating: Roofs (Btu/h)", zone.hdl_roofs.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Heating: Floors (Btu/h)", zone.hdl_floors.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Heating: Slabs (Btu/h)", zone.hdl_slabs.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Heating: Ceilings (Btu/h)", zone.hdl_ceilings.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Heating: Infiltration (Btu/h)", zone.hdl_infil.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Heating: Ventilation (Btu/h)", zone.hdl_vent.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Heating: Piping (Btu/h)", zone.hdl_piping.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Cooling Sensible: Total (Btu/h)", zone.cdl_sens_total.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Cooling Sensible: Ducts (Btu/h)", zone.cdl_sens_ducts.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Cooling Sensible: Windows (Btu/h)", zone.cdl_sens_windows.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Cooling Sensible: Skylights (Btu/h)", zone.cdl_sens_skylights.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Cooling Sensible: Doors (Btu/h)", zone.cdl_sens_doors.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Cooling Sensible: Walls (Btu/h)", zone.cdl_sens_walls.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Cooling Sensible: Roofs (Btu/h)", zone.cdl_sens_roofs.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Cooling Sensible: Floors (Btu/h)", zone.cdl_sens_floors.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Cooling Sensible: Slabs (Btu/h)", zone.cdl_sens_slabs.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Cooling Sensible: Ceilings (Btu/h)", zone.cdl_sens_ceilings.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Cooling Sensible: Infiltration (Btu/h)", zone.cdl_sens_infil.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Cooling Sensible: Ventilation (Btu/h)", zone.cdl_sens_vent.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Cooling Sensible: Internal Gains (Btu/h)", zone.cdl_sens_intgains.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Cooling Sensible: Blower Heat (Btu/h)", zone.cdl_sens_blowerheat.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Cooling Sensible: AED Excursion (Btu/h)", zone.cdl_sens_aedexcursion.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Cooling Latent: Total (Btu/h)", zone.cdl_lat_total.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Cooling Latent: Ducts (Btu/h)", zone.cdl_lat_ducts.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Cooling Latent: Infiltration (Btu/h)", zone.cdl_lat_infil.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Cooling Latent: Ventilation (Btu/h)", zone.cdl_lat_vent.round(1)]
        results_out << ["HVAC Zone Design Load: #{zone.id}: Cooling Latent: Internal Gains (Btu/h)", zone.cdl_lat_intgains.round(1)]
      end
    end

    # HVAC Space design loads
    hpxml_bldgs.each do |hpxml_bldg|
      hpxml_bldg.conditioned_spaces.each do |space|
        results_out << [line_break]
        # Note: Latent loads are not calculated for spaces
        results_out << ["HVAC Space Design Load: #{space.id}: Heating: Total (Btu/h)", space.hdl_total.round(1)]
        results_out << ["HVAC Space Design Load: #{space.id}: Heating: Ducts (Btu/h)", space.hdl_ducts.round(1)]
        results_out << ["HVAC Space Design Load: #{space.id}: Heating: Windows (Btu/h)", space.hdl_windows.round(1)]
        results_out << ["HVAC Space Design Load: #{space.id}: Heating: Skylights (Btu/h)", space.hdl_skylights.round(1)]
        results_out << ["HVAC Space Design Load: #{space.id}: Heating: Doors (Btu/h)", space.hdl_doors.round(1)]
        results_out << ["HVAC Space Design Load: #{space.id}: Heating: Walls (Btu/h)", space.hdl_walls.round(1)]
        results_out << ["HVAC Space Design Load: #{space.id}: Heating: Roofs (Btu/h)", space.hdl_roofs.round(1)]
        results_out << ["HVAC Space Design Load: #{space.id}: Heating: Floors (Btu/h)", space.hdl_floors.round(1)]
        results_out << ["HVAC Space Design Load: #{space.id}: Heating: Slabs (Btu/h)", space.hdl_slabs.round(1)]
        results_out << ["HVAC Space Design Load: #{space.id}: Heating: Ceilings (Btu/h)", space.hdl_ceilings.round(1)]
        results_out << ["HVAC Space Design Load: #{space.id}: Heating: Infiltration (Btu/h)", space.hdl_infil.round(1)]
        results_out << ["HVAC Space Design Load: #{space.id}: Cooling Sensible: Total (Btu/h)", space.cdl_sens_total.round(1)]
        results_out << ["HVAC Space Design Load: #{space.id}: Cooling Sensible: Ducts (Btu/h)", space.cdl_sens_ducts.round(1)]
        results_out << ["HVAC Space Design Load: #{space.id}: Cooling Sensible: Windows (Btu/h)", space.cdl_sens_windows.round(1)]
        results_out << ["HVAC Space Design Load: #{space.id}: Cooling Sensible: Skylights (Btu/h)", space.cdl_sens_skylights.round(1)]
        results_out << ["HVAC Space Design Load: #{space.id}: Cooling Sensible: Doors (Btu/h)", space.cdl_sens_doors.round(1)]
        results_out << ["HVAC Space Design Load: #{space.id}: Cooling Sensible: Walls (Btu/h)", space.cdl_sens_walls.round(1)]
        results_out << ["HVAC Space Design Load: #{space.id}: Cooling Sensible: Roofs (Btu/h)", space.cdl_sens_roofs.round(1)]
        results_out << ["HVAC Space Design Load: #{space.id}: Cooling Sensible: Floors (Btu/h)", space.cdl_sens_floors.round(1)]
        results_out << ["HVAC Space Design Load: #{space.id}: Cooling Sensible: Slabs (Btu/h)", space.cdl_sens_slabs.round(1)]
        results_out << ["HVAC Space Design Load: #{space.id}: Cooling Sensible: Ceilings (Btu/h)", space.cdl_sens_ceilings.round(1)]
        results_out << ["HVAC Space Design Load: #{space.id}: Cooling Sensible: Infiltration (Btu/h)", space.cdl_sens_infil.round(1)]
        results_out << ["HVAC Space Design Load: #{space.id}: Cooling Sensible: Internal Gains (Btu/h)", space.cdl_sens_intgains.round(1)]
        results_out << ["HVAC Space Design Load: #{space.id}: Cooling Sensible: AED Excursion (Btu/h)", space.cdl_sens_aedexcursion.round(1)]
      end
    end

    # Geothermal loop
    results_out << [line_break]
    geothermal_loops = hpxml_bldgs.map { |hpxml_bldg| hpxml_bldg.geothermal_loops }.flatten
    num_boreholes = geothermal_loops.map { |loop| loop.num_bore_holes }.sum(0)
    total_length = geothermal_loops.map { |loop| loop.bore_length * loop.num_bore_holes }.sum(0.0)
    results_out << ['HVAC Geothermal Loop: Borehole/Trench Count', num_boreholes]
    results_out << ['HVAC Geothermal Loop: Borehole/Trench Length (ft)', (total_length / [num_boreholes, 1].max).round(1)] # [num_boreholes, 1].max to prevent divide by zero

    return results_out
  end

  # TODO
  #
  # @param results_out [TODO] TODO
  # @param output_format [TODO] TODO
  # @param output_file_path [TODO] TODO
  # @param mode [TODO] TODO
  # @return [TODO] TODO
  def self.write_results_out_to_file(results_out, output_format, output_file_path, mode = 'w')
    line_break = nil
    if ['csv'].include? output_format
      CSV.open(output_file_path, mode) { |csv| results_out.to_a.each { |elem| csv << elem } }
    elsif ['json', 'msgpack'].include? output_format
      h = {}
      results_out.each do |out|
        next if out == [line_break]

        if out[0].include? ':'
          grp, name = out[0].split(':', 2)
          h[grp] = {} if h[grp].nil?
          h[grp][name.strip] = out[1]
        else
          h[out[0]] = out[1]
        end
      end

      if output_format == 'json'
        require 'json'
        File.open(output_file_path, mode) { |json| json.write(JSON.pretty_generate(h)) }
      elsif output_format == 'msgpack'
        File.open(output_file_path, "#{mode}b") { |json| h.to_msgpack(json) }
      end
    end
  end
end
