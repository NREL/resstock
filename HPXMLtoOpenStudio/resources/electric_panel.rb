# frozen_string_literal: true

# TODO
module ElectricPanel
  # TODO
  def self.calculate(hpxml_bldg, electric_panel, update_hpxml: true)
    panel_loads = PanelLoadValues.new

    calculate_load_based(hpxml_bldg, electric_panel, panel_loads)
    calculate_breaker_spaces(electric_panel, panel_loads)

    # Assign load-based capacities to HPXML objects for output
    return unless update_hpxml

    electric_panel.clb_total_w = panel_loads.LoadBased_CapacityW.round(1)
    electric_panel.clb_total_a = panel_loads.LoadBased_CapacityA.round
    electric_panel.clb_headroom_a = panel_loads.LoadBased_HeadRoomA.round

    electric_panel.bs_total = panel_loads.BreakerSpaces_Total
    electric_panel.bs_occupied = panel_loads.BreakerSpaces_Occupied
    electric_panel.bs_headroom = panel_loads.BreakerSpaces_HeadRoom
  end

  # TODO
  def self.get_panel_load_heating_system(hpxml_bldg, panel_load)
    hpxml_bldg.heating_systems.each do |heating_system|
      next if !panel_load.system_idrefs.include?(heating_system.id)

      return heating_system
    end
    return
  end

  # TODO
  def self.get_panel_load_heat_pump(hpxml_bldg, panel_load)
    hpxml_bldg.heat_pumps.each do |heat_pump|
      next if !panel_load.system_idrefs.include?(heat_pump.id)

      return heat_pump
    end
    return
  end

  # TODO
  def self.get_panel_load_heating(hpxml_bldg, electric_panel, addition: nil)
    htg = 0
    electric_panel.panel_loads.each do |panel_load|
      next if panel_load.type != HPXML::ElectricPanelLoadTypeHeating

      heating_system = get_panel_load_heating_system(hpxml_bldg, panel_load)
      if !heating_system.nil?
        heating_system_watts = panel_load.power
        primary_heat_pump_watts = 0
        if !heating_system.primary_heat_pump.nil?
          primary_heat_pump_watts = electric_panel.panel_loads.find { |pl| pl.system_idrefs.include?(heating_system.primary_heat_pump.id) }.power
        end

        if addition.nil? ||
           (addition && panel_load.addition) ||
           (!addition && !panel_load.addition)
          if (primary_heat_pump_watts == 0) ||
             (!heating_system.primary_heat_pump.nil? && heating_system.primary_heat_pump.simultaneous_backup) ||
             (!heating_system.primary_heat_pump.nil? && heating_system_watts >= primary_heat_pump_watts)
            htg += heating_system_watts
          end
        end
      end

      heat_pump = get_panel_load_heat_pump(hpxml_bldg, panel_load)
      next unless !heat_pump.nil?

      heat_pump_watts = panel_load.power
      backup_system_watts = 0
      if !heat_pump.backup_system.nil?
        backup_system_watts = electric_panel.panel_loads.find { |pl| pl.system_idrefs.include?(heat_pump.backup_system.id) }.power
      end

      next unless addition.nil? ||
                  (addition && panel_load.addition) ||
                  (!addition && !panel_load.addition)

      next unless (backup_system_watts == 0) ||
                  (!heat_pump.backup_system.nil? && heat_pump.simultaneous_backup) ||
                  (!heat_pump.backup_system.nil? && heat_pump_watts >= backup_system_watts)

      htg += heat_pump_watts
    end
    return htg
  end

  # TODO
  def self.calculate_load_based(hpxml_bldg, electric_panel, panel_loads)
    htg_existing = get_panel_load_heating(hpxml_bldg, electric_panel, addition: false)
    htg_new = get_panel_load_heating(hpxml_bldg, electric_panel, addition: true)
    clg_existing = electric_panel.panel_loads.select { |panel_load| panel_load.type == HPXML::ElectricPanelLoadTypeCooling && !panel_load.addition }.map { |pl| pl.power }.sum(0.0)
    clg_new = electric_panel.panel_loads.select { |panel_load| panel_load.type == HPXML::ElectricPanelLoadTypeCooling && panel_load.addition }.map { |pl| pl.power }.sum(0.0)

    # Part A
    other_load = [htg_existing, clg_existing].max
    electric_panel.panel_loads.each do |panel_load|
      next if panel_load.type == HPXML::ElectricPanelLoadTypeHeating || panel_load.type == HPXML::ElectricPanelLoadTypeCooling

      other_load += panel_load.power
    end

    threshold = 8000.0 # W

    part_a = 1.0 * [threshold, other_load].min + 0.4 * [0, other_load - threshold].max

    # Part B
    part_b = [htg_new, clg_new].max

    panel_loads.LoadBased_CapacityW = part_a + part_b
    panel_loads.LoadBased_CapacityA = panel_loads.LoadBased_CapacityW / Float(electric_panel.voltage)
    panel_loads.LoadBased_HeadRoomA = electric_panel.max_current_rating - panel_loads.LoadBased_CapacityA
  end

  # TODO
  def self.calculate_meter_based(hpxml_bldg, electric_panel, peak_fuels)
    htg_new = get_panel_load_heating(hpxml_bldg, electric_panel, addition: true)
    clg_new = electric_panel.panel_loads.select { |panel_load| panel_load.type == HPXML::ElectricPanelLoadTypeCooling && panel_load.addition }.map { |pl| pl.power }.sum(0.0)

    new_loads = [htg_new, clg_new].max
    electric_panel.panel_loads.each do |panel_load|
      next if panel_load.type == HPXML::ElectricPanelLoadTypeHeating || panel_load.type == HPXML::ElectricPanelLoadTypeCooling

      new_loads += panel_load.power if panel_load.addition
    end

    capacity_w = new_loads + 1.25 * peak_fuels[[FT::Elec, PFT::Annual]].annual_output
    capacity_a = capacity_w / Float(electric_panel.voltage)
    headroom_a = electric_panel.max_current_rating - capacity_a
    return capacity_w, capacity_a, headroom_a
  end

  # TODO
  def self.calculate_breaker_spaces(electric_panel, panel_loads)
    occupied = electric_panel.panel_loads.map { |panel_load| panel_load.breaker_spaces }.sum(0.0)
    if !electric_panel.total_breaker_spaces.nil?
      total = electric_panel.total_breaker_spaces
    else
      total = occupied + electric_panel.headroom_breaker_spaces
    end

    panel_loads.BreakerSpaces_Total = total
    panel_loads.BreakerSpaces_Occupied = occupied
    panel_loads.BreakerSpaces_HeadRoom = total - occupied
  end
end

# TODO
class PanelLoadValues
  LOADBASED_ATTRS = [:LoadBased_CapacityW,
                     :LoadBased_CapacityA,
                     :LoadBased_HeadRoomA]
  BREAKERSPACE_ATTRS = [:BreakerSpaces_Occupied,
                        :BreakerSpaces_Total,
                        :BreakerSpaces_HeadRoom]
  attr_accessor(*LOADBASED_ATTRS)
  attr_accessor(*BREAKERSPACE_ATTRS)

  def initialize
    (LOADBASED_ATTRS +
     BREAKERSPACE_ATTRS).each do |attr|
      send("#{attr}=", 0.0)
    end
  end
end
