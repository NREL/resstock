# frozen_string_literal: true

# Collection of methods related to electric panel load calculations.
module ElectricPanel
  # Calculates load-based capacity and breaker spaces for an electric panel.
  #
  # @param hpxml_header [HPXML::Header] HPXML Header object (one per HPXML file)
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param electric_panel [HPXML::ElectricPanel] Object that defines a single electric panel
  # @param update_hpxml [Boolean] Whether to update the HPXML object so that in.xml reports load-based capacities and breaker spaces
  # @return [nil]
  def self.calculate(hpxml_header, hpxml_bldg, electric_panel)
    capacity_types = []
    capacity_total_watts = []
    capacity_total_amps = []
    capacity_headroom_amps = []
    hpxml_header.panel_calculation_types.each do |panel_calculation_type|
      next unless panel_calculation_type.include?('Load-Based')

      load_based_capacity_values = LoadBasedCapacityValues.new
      calculate_load_based(hpxml_bldg, electric_panel, load_based_capacity_values, panel_calculation_type)

      capacity_types << panel_calculation_type
      capacity_total_watts << load_based_capacity_values.LoadBased_CapacityW.round(1)
      capacity_total_amps << load_based_capacity_values.LoadBased_CapacityA.round
      capacity_headroom_amps << load_based_capacity_values.LoadBased_HeadRoomA.round
    end
    electric_panel.capacity_types = capacity_types
    electric_panel.capacity_total_watts = capacity_total_watts
    electric_panel.capacity_total_amps = capacity_total_amps
    electric_panel.capacity_headroom_amps = capacity_headroom_amps

    breaker_spaces_values = BreakerSpacesValues.new
    calculate_breaker_spaces(electric_panel, breaker_spaces_values)

    electric_panel.breaker_spaces_total = breaker_spaces_values.BreakerSpaces_Total
    electric_panel.breaker_spaces_occupied = breaker_spaces_values.BreakerSpaces_Occupied
    electric_panel.breaker_spaces_headroom = breaker_spaces_values.BreakerSpaces_HeadRoom
  end

  # Get the heating system attached to the given panel load.
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param [HPXML::PanelLoad] Object that defines a single electric panel load
  # @return [HPXML::HeatingSystem] The heating system referenced by the panel load
  def self.get_panel_load_heating_system(hpxml_bldg, panel_load)
    hpxml_bldg.heating_systems.each do |heating_system|
      next if !panel_load.system_idrefs.include?(heating_system.id)

      return heating_system
    end
    return
  end

  # Get the heat pump attached to the given panel load.
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param [HPXML::PanelLoad] Object that defines a single electric panel load
  # @return [HPXML::HeatPump] The heat pump referenced by the panel load
  def self.get_panel_load_heat_pump(hpxml_bldg, panel_load)
    hpxml_bldg.heat_pumps.each do |heat_pump|
      next if !panel_load.system_idrefs.include?(heat_pump.id)

      return heat_pump
    end
    return
  end

  # Gets the electric panel's heating load.
  # The returned heating load depends on several factors:
  # - whether the backup heating system can operate simultaneous with the primary heating system (if it can, we sum; if it can't, we take the max)
  # - whether we are tabulating all heating loads, only existing heating loads, or only new heating loads
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param electric_panel [HPXML::ElectricPanel] Object that defines a single electric panel
  # @param addition [nil or Boolean] Whether we are getting all, existing, or new heating loads
  # @return [Double] The electric panel's
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

  # Calculate the load-based capacity for the given electric panel and panel loads according to NEC 220.83.
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param electric_panel [HPXML::ElectricPanel] Object that defines a single electric panel
  # @param panel_loads [Array<HPXML::PanelLoad>] List of panel load objects
  # @return [nil]
  def self.calculate_load_based(hpxml_bldg, electric_panel, panel_loads, panel_calculation_type)
    if panel_calculation_type == HPXML::ElectricPanelLoadCalculationType2023LoadBased
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

      # Part A
      part_a = 1.0 * [threshold, other_load].min + 0.4 * [0, other_load - threshold].max

      # Part B
      part_b = [htg_new, clg_new].max

      panel_loads.LoadBased_CapacityW = part_a + part_b
      panel_loads.LoadBased_CapacityA = panel_loads.LoadBased_CapacityW / Float(electric_panel.voltage)
      panel_loads.LoadBased_HeadRoomA = electric_panel.max_current_rating - panel_loads.LoadBased_CapacityA
    elsif panel_calculation_type == HPXML::ElectricPanelLoadCalculationType2026LoadBased
      # TODO
      panel_loads.LoadBased_CapacityW = 1
      panel_loads.LoadBased_CapacityA = 2
      panel_loads.LoadBased_HeadRoomA = 3
    end
  end

  # Calculate the meter-based capacity and headroom for the given electric panel and panel loads according to NEC 220.87.
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param electric_panel [HPXML::ElectricPanel] Object that defines a single electric panel
  # @param peak_fuels [Hash] Map of peak building electricity outputs
  # @return [Array<Double, Double, Double>] The capacity (W), the capacity (A), and headroom (A)
  def self.calculate_meter_based(hpxml_bldg, electric_panel, peak_fuels, panel_calculation_type)
    if panel_calculation_type == HPXML::ElectricPanelLoadCalculationType2023MeterBased
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
    elsif panel_calculation_type == HPXML::ElectricPanelLoadCalculationType2026MeterBased
      # TODO
      return 1, 2, 3
    end
  end

  # Calculate the number of panel breaker spaces corresponding to total, occupied, and headroom.
  #
  # @param electric_panel [HPXML::ElectricPanel] Object that defines a single electric panel
  # @param [Array<HPXML::PanelLoad>] List of panel load objects
  # @return [nil]
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

# Object with calculated panel load capacity
class LoadBasedCapacityValues
  LOADBASED_ATTRS = [:LoadBased_CapacityW,
                     :LoadBased_CapacityA,
                     :LoadBased_HeadRoomA]
  attr_accessor(*LOADBASED_ATTRS)

  def initialize
    LOADBASED_ATTRS.each do |attr|
      send("#{attr}=", 0.0)
    end
  end
end

# Object with breaker spaces
class BreakerSpacesValues
  BREAKERSPACE_ATTRS = [:BreakerSpaces_Occupied,
                        :BreakerSpaces_Total,
                        :BreakerSpaces_HeadRoom]
  attr_accessor(*BREAKERSPACE_ATTRS)

  def initialize
    BREAKERSPACE_ATTRS.each do |attr|
      send("#{attr}=", 0.0)
    end
  end
end
