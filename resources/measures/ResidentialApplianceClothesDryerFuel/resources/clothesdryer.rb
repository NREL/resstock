require "#{File.dirname(__FILE__)}/constants"
require "#{File.dirname(__FILE__)}/unit_conversions"

class ClothesDryer

  def self.apply(model, unit, runner, sch, cef, mult, weekday_sch, weekend_sch, monthly_sch, 
                 space, fuel_type, fuel_split)
  
      # Get unit beds/baths
      nbeds, nbaths = Geometry.get_unit_beds_baths(model, unit, runner)
      if nbeds.nil? or nbaths.nil?
          return false
      end
      
      # Get clothes washer properties
      cw = nil
      model.getElectricEquipments.each do |ee|
          next if ee.name.to_s != Constants.ObjectNameClothesWasher(unit.name.to_s)
          cw = ee
      end
      if cw.nil?
          runner.registerError("Could not find clothes washer equipment.")
          return false
      end
      cw_drum_volume = unit.getFeatureAsDouble(Constants.ClothesWasherDrumVolume(cw))
      cw_imef = unit.getFeatureAsDouble(Constants.ClothesWasherIMEF(cw))
      cw_rated_annual_energy = unit.getFeatureAsDouble(Constants.ClothesWasherRatedAnnualEnergy(cw))
      if !cw_drum_volume.is_initialized or !cw_imef.is_initialized or !cw_rated_annual_energy.is_initialized
          runner.registerError("Could not find clothes washer properties.")
          return false
      end
      cw_drum_volume = cw_drum_volume.get
      cw_imef = cw_imef.get
      cw_rated_annual_energy = cw_rated_annual_energy.get
      
      unit_obj_name_e = Constants.ObjectNameClothesDryer(Constants.FuelTypeElectric, unit.name.to_s)
      unit_obj_name_f = Constants.ObjectNameClothesDryer(fuel_type, unit.name.to_s)
      
      ef = cef * 1.15 # RESNET interpretation
      cw_mef = 0.503 + 0.95 * cw_imef # RESNET interpretation

      # Energy Use is based on "Method for Evaluating Energy Use of Dishwashers, Clothes 
      # Washers, and Clothes Dryers" by Eastment and Hendron, Conference Paper NREL/CP-550-39769, 
      # August 2006. Their paper is in part based on the energy use calculations presented in the 
      # 10CFR Part 430, Subpt. B, App. D (DOE 1999),
      # http://ecfr.gpoaccess.gov/cgi/t/text/text-idx?c=ecfr&tpl=/ecfrbrowse/Title10/10cfr430_main_02.tpl
      # Eastment and Hendron present a method for estimating the energy consumption per cycle 
      # based on the dryer's energy factor.

      # Set some intermediate variables. An experimentally determined value for the percent 
      # reduction in the moisture content of the test load, expressed here as a fraction 
      # (DOE 10CFR Part 430, Subpt. B, App. D, Section 4.1)
      dryer_nominal_reduction_in_moisture_content = 0.66
      # The fraction of washer loads dried in a clothes dryer (DOE 10CFR Part 430, Subpt. B, 
      # App. J1, Section 4.3)
      dryer_usage_factor = 0.84
      load_adjustment_factor = 0.52

      # Set the number of cycles per year for test conditions
      cw_cycles_per_year_test = 392 # (see Eastment and Hendron, NREL/CP-550-39769, 2006)

      # Calculate test load weight (correlation based on data in Table 5.1 of 10CFR Part 430,
      # Subpt. B, App. J1, DOE 1999)
      cw_test_load = 4.103003337 * cw_drum_volume + 0.198242492 # lb

      # Eq. 10 of Eastment and Hendron, NREL/CP-550-39769, 2006.
      dryer_energy_factor_std = 0.5 # Nominal drying energy required, kWh/lb dry cloth
      dryer_elec_per_year = (cw_cycles_per_year_test * cw_drum_volume / cw_mef - 
                            cw_rated_annual_energy) # kWh
      dryer_elec_per_cycle = dryer_elec_per_year / cw_cycles_per_year_test # kWh
      remaining_moisture_after_spin = (dryer_elec_per_cycle / (load_adjustment_factor * 
                                      dryer_energy_factor_std * dryer_usage_factor * 
                                      cw_test_load) + 0.04) # lb water/lb dry cloth
      cw_remaining_water = cw_test_load * remaining_moisture_after_spin

      # Use the dryer energy factor and remaining water from the clothes washer to calculate 
      # total energy use per cycle (eq. 7 Eastment and Hendron, NREL/CP-550-39769, 2006).
      actual_cd_energy_use_per_cycle = (cw_remaining_water / (ef *
                                       dryer_nominal_reduction_in_moisture_content)) # kWh/cycle
                                       
      if fuel_type == Constants.FuelTypeElectric
          # All energy use is electric.
          actual_cd_elec_use_per_cycle = actual_cd_energy_use_per_cycle # kWh/cycle
      else
          # Use assumed split between electricity and fuel use to calculate each.
          # eq. 8 of Eastment and Hendron, NREL/CP-550-39769, 2006
          actual_cd_elec_use_per_cycle = fuel_split * actual_cd_energy_use_per_cycle # kWh/cycle
          # eq. 9 of Eastment and Hendron, NREL/CP-550-39769, 2006
          actual_cd_fuel_use_per_cycle = (1 - fuel_split) * actual_cd_energy_use_per_cycle # kWh/cycle
      end

      # (eq. 14 Eastment and Hendron, NREL/CP-550-39769, 2006)
      actual_cw_cycles_per_year = (cw_cycles_per_year_test * (0.5 + nbeds / 6) * 
                                  (12.5 / cw_test_load)) # cycles/year

      # eq. 15 of Eastment and Hendron, NREL/CP-550-39769, 2006
      actual_cd_cycles_per_year = dryer_usage_factor * actual_cw_cycles_per_year # cycles/year

      daily_energy_elec = actual_cd_cycles_per_year * actual_cd_elec_use_per_cycle / 365 # kWh/day
      daily_energy_elec = daily_energy_elec * mult
      ann_e = daily_energy_elec * 365.0 # kWh/yr
      
      ann_f = 0
      if fuel_type != Constants.FuelTypeElectric
          daily_energy_fuel = actual_cd_cycles_per_year * actual_cd_fuel_use_per_cycle / 365 # kWh/day
          daily_energy_fuel = UnitConversions.convert(daily_energy_fuel * mult, "kWh", "therm") # therm/day
          ann_f = daily_energy_fuel * 365.0 # therms/yr
      end

      if ann_e > 0 or ann_f > 0
      
          if sch.nil?
              # Create schedule
              mult_weekend = 1.15
              mult_weekday = 0.94
              sch = MonthWeekdayWeekendSchedule.new(model, runner, Constants.ObjectNameClothesDryer(fuel_type) + " schedule", weekday_sch, weekend_sch, monthly_sch, mult_weekday, mult_weekend)
              if not sch.validated?
                  return false
              end
          end

          #Add equipment for the cd
          if fuel_type == Constants.FuelTypeElectric
          
              design_level_e = sch.calcDesignLevelFromDailykWh(daily_energy_elec)

              cd_def = OpenStudio::Model::ElectricEquipmentDefinition.new(model)
              cd = OpenStudio::Model::ElectricEquipment.new(cd_def)
              cd.setName(unit_obj_name_e)
              cd.setEndUseSubcategory(unit_obj_name_e)
              cd.setSpace(space)
              cd_def.setName(unit_obj_name_e)
              cd_def.setDesignLevel(design_level_e)
              cd_def.setFractionRadiant(0.09)
              cd_def.setFractionLatent(0.05)
              cd_def.setFractionLost(0.8)
              cd.setSchedule(sch.schedule)
              
          else
          
              design_level_e = sch.calcDesignLevelFromDailykWh(daily_energy_elec)
              
              if design_level_e > 0
                  cd_def2 = OpenStudio::Model::ElectricEquipmentDefinition.new(model)
                  cd2 = OpenStudio::Model::ElectricEquipment.new(cd_def2)
                  cd2.setName(unit_obj_name_e)
                  cd2.setEndUseSubcategory(unit_obj_name_e)
                  cd2.setSpace(space)
                  cd_def2.setName(unit_obj_name_e)
                  cd_def2.setDesignLevel(design_level_e)
                  cd_def2.setFractionRadiant(0.6)
                  cd_def2.setFractionLatent(0.0)
                  cd_def2.setFractionLost(0.0)
                  cd2.setSchedule(sch.schedule)
              end
              
              design_level_f = sch.calcDesignLevelFromDailyTherm(daily_energy_fuel)
              
              cd_def = OpenStudio::Model::OtherEquipmentDefinition.new(model)
              cd = OpenStudio::Model::OtherEquipment.new(cd_def)
              cd.setName(unit_obj_name_f)
              cd.setEndUseSubcategory(unit_obj_name_f)
              cd.setFuelType(HelperMethods.eplus_fuel_map(fuel_type))
              cd.setSpace(space)
              cd_def.setName(unit_obj_name_f)
              cd_def.setDesignLevel(design_level_f)
              cd_def.setFractionRadiant(0.06)
              cd_def.setFractionLatent(0.05)
              cd_def.setFractionLost(0.85)
              cd.setSchedule(sch.schedule)
          
          end
          
          unit.setFeature(Constants.ClothesDryerCEF(cd), cef.to_f)
          unit.setFeature(Constants.ClothesDryerMult(cd), mult.to_f)
          unit.setFeature(Constants.ClothesDryerWeekdaySch(cd), weekday_sch.to_s)
          unit.setFeature(Constants.ClothesDryerWeekendSch(cd), weekend_sch.to_s)
          unit.setFeature(Constants.ClothesDryerMonthlySch(cd), monthly_sch.to_s)
          unit.setFeature(Constants.ClothesDryerFuelType(cd), fuel_type.to_s)
          unit.setFeature(Constants.ClothesDryerFuelSplit(cd), fuel_split.to_f)
          
      end
      
      return true, ann_e, ann_f, sch
  
  end
  
  def self.remove_existing(runner, space, obj_name, display_remove_msg=true)
      # Remove any existing clothes dryer
      objects_to_remove = []
      space.electricEquipment.each do |space_equipment|
          next if not space_equipment.name.to_s.start_with? obj_name
          objects_to_remove << space_equipment
          objects_to_remove << space_equipment.electricEquipmentDefinition
          if space_equipment.schedule.is_initialized
              objects_to_remove << space_equipment.schedule.get
          end
      end
      space.otherEquipment.each do |space_equipment|
          next if not space_equipment.name.to_s.start_with? obj_name
          objects_to_remove << space_equipment
          objects_to_remove << space_equipment.otherEquipmentDefinition
          if space_equipment.schedule.is_initialized
              objects_to_remove << space_equipment.schedule.get
          end
      end
      if objects_to_remove.size > 0 and display_remove_msg
          runner.registerInfo("Removed existing clothes dryer from space '#{space.name.to_s}'.")
      end
      objects_to_remove.uniq.each do |object|
          begin
              object.remove
          rescue
              # no op
          end
      end
  end

end 