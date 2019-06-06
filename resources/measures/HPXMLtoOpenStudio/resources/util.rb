# Add classes or functions here than can be used across a variety of our python classes and modules.
require_relative "constants"
require_relative "unit_conversions"

class HelperMethods
  def self.eplus_fuel_map(fuel)
    if fuel == Constants.FuelTypeElectric
      return "Electricity"
    elsif fuel == Constants.FuelTypeGas
      return "NaturalGas"
    elsif fuel == Constants.FuelTypeOil
      return "FuelOil#1"
    elsif fuel == Constants.FuelTypePropane
      return "PropaneGas"
    elsif fuel == Constants.FuelTypeWood
      return "OtherFuel1"
    end
  end

  def self.reverse_eplus_fuel_map(fuel)
    if fuel == "Electricity"
      return Constants.FuelTypeElectric
    elsif fuel == "NaturalGas"
      return Constants.FuelTypeGas
    elsif fuel == "FuelOil#1"
      return Constants.FuelTypeOil
    elsif fuel == "PropaneGas"
      return Constants.FuelTypePropane
    elsif fuel == "OtherFuel1"
      return Constants.FuelTypeWood
    end
  end

  def self.reverse_openstudio_fuel_map(fuel)
    if fuel == "Electricity"
      return Constants.FuelTypeElectric
    elsif fuel == "Gas"
      return Constants.FuelTypeGas
    elsif fuel == "FuelOil#1"
      return Constants.FuelTypeOil
    elsif fuel == "Propane"
      return Constants.FuelTypePropane
    end
  end

  def self.remove_unused_constructions_and_materials(model, runner)
    # Code from https://bcl.nrel.gov/node/82267 (remove_orphan_objects_and_unused_resources measure)
    model.getConstructions.sort.each do |resource|
      if resource.directUseCount == 0
        runner.registerInfo("Removed construction '#{resource.name}' because it was orphaned.")
        resource.remove
      end
    end

    model.getMaterials.sort.each do |resource|
      if resource.directUseCount == 0
        runner.registerInfo("Removed material '#{resource.name}' because it was orphaned.")
        resource.remove
      end
    end
  end

  def self.state_code_map
    return { "Alabama" => "AL", "Alaska" => "AK", "Arizona" => "AZ", "Arkansas" => "AR", "California" => "CA", "Colorado" => "CO", "Connecticut" => "CT", "Delaware" => "DE", "District of Columbia" => "DC",
             "Florida" => "FL", "Georgia" => "GA", "Hawaii" => "HI", "Idaho" => "ID", "Illinois" => "IL", "Indiana" => "IN", "Iowa" => "IA", "Kansas" => "KS", "Kentucky" => "KY", "Louisiana" => "LA",
             "Maine" => "ME", "Maryland" => "MD", "Massachusetts" => "MA", "Michigan" => "MI", "Minnesota" => "MN", "Mississippi" => "MS", "Missouri" => "MO", "Montana" => "MT", "Nebraska" => "NE", "Nevada" => "NV",
             "New Hampshire" => "NH", "New Jersey" => "NJ", "New Mexico" => "NM", "New York" => "NY", "North Carolina" => "NC", "North Dakota" => "ND", "Ohio" => "OH", "Oklahoma" => "OK",
             "Oregon" => "OR", "Pennsylvania" => "PA", "Puerto Rico" => "PR", "Rhode Island" => "RI", "South Carolina" => "SC", "South Dakota" => "SD", "Tennessee" => "TN", "Texas" => "TX",
             "Utah" => "UT", "Vermont" => "VT", "Virginia" => "VA", "Washington" => "WA", "West Virginia" => "WV", "Wisconsin" => "WI", "Wyoming" => "WY" }
  end
end

class MathTools
  def self.valid_float?(str)
    !!Float(str) rescue false
  end

  def self.interp2(x, x0, x1, f0, f1)
    '''
    Returns the linear interpolation between two results.
    '''

    return f0 + ((x - x0) / (x1 - x0)) * (f1 - f0)
  end

  def self.interp4(x, y, x1, x2, y1, y2, fx1y1, fx1y2, fx2y1, fx2y2)
    '''
    Returns the bilinear interpolation between four results.
    '''

    return (fx1y1 / ((x2 - x1) * (y2 - y1))) * (x2 - x) * (y2 - y) \
          + (fx2y1 / ((x2 - x1) * (y2 - y1))) * (x - x1) * (y2 - y) \
          + (fx1y2 / ((x2 - x1) * (y2 - y1))) * (x2 - x) * (y - y1) \
          + (fx2y2 / ((x2 - x1) * (y2 - y1))) * (x - x1) * (y - y1)
  end

  def self.biquadratic(x, y, c)
    '''
    Description:
    ------------
        Calculate the result of a biquadratic polynomial with independent variables
        x and y, and a list of coefficients, c:
        z = c[1] + c[2]*x + c[3]*x**2 + c[4]*y + c[5]*y**2 + c[6]*x*y
    Inputs:
    -------
        x       float      independent variable 1
        y       float      independent variable 2
        c       tuple      list of 6 coeffients [floats]
    Outputs:
    --------
        z       float      result of biquadratic polynomial
    '''
    if c.length != 6
      puts "Error: There must be 6 coefficients in a biquadratic polynomial"
    end
    z = c[0] + c[1] * x + c[2] * x**2 + c[3] * y + c[4] * y**2 + c[5] * y * x
    return z
  end

  def self.quadratic(x, c)
    '''
    Description:
    ------------
        Calculate the result of a quadratic polynomial with independent variable
        x and a list of coefficients, c:

        y = c[1] + c[2]*x + c[3]*x**2

    Inputs:
    -------
        x       float      independent variable
        c       tuple      list of 6 coeffients [floats]

    Outputs:
    --------
        y       float      result of biquadratic polynomial
    '''
    if c.size != 3
      puts "Error: There must be 3 coefficients in a quadratic polynomial"
    end
    y = c[0] + c[1] * x + c[2] * x**2

    return y
  end

  def self.bicubic(x, y, c)
    '''
    Description:
    ------------
        Calculate the result of a bicubic polynomial with independent variables
        x and y, and a list of coefficients, c:

        z = c[1] + c[2]*x + c[3]*y + c[4]*x**2 + c[5]*x*y + c[6]*y**2 + \
            c[7]*x**3 + c[8]*y*x**2 + c[9]*x*y**2 + c[10]*y**3

    Inputs:
    -------
        x       float      independent variable 1
        y       float      independent variable 2
        c       tuple      list of 10 coeffients [floats]

    Outputs:
    --------
        z       float      result of bicubic polynomial
    '''
    if c.size != 10
      puts "Error: There must be 10 coefficients in a bicubic polynomial"
    end
    z = c[0] + c[1] * x + c[2] * y + c[3] * x**2 + c[4] * x * y + c[5] * y**2 + \
        c[6] * x**3 + c[7] * y * x**2 + c[8] * x * y**2 + c[9] * y**3

    return z
  end

  def self.Iterate(x0, f0, x1, f1, x2, f2, icount, cvg)
    '''
    Description:
    ------------
        Determine if a guess is within tolerance for convergence
        if not, output a new guess using the Newton-Raphson method
    Source:
    -------
        Based on XITERATE f77 code in ResAC (Brandemuehl)
    Inputs:
    -------
        x0      float    current guess value
        f0      float    value of function f(x) at current guess value
        x1,x2   floats   previous two guess values, used to create quadratic
                         (or linear fit)
        f1,f2   floats   previous two values of f(x)
        icount  int      iteration count
        cvg     bool     Has the iteration reached convergence?
    Outputs:
    --------
        x_new   float    new guess value
        cvg     bool     Has the iteration reached convergence?
        x1,x2   floats   updated previous two guess values, used to create quadratic
                         (or linear fit)
        f1,f2   floats   updated previous two values of f(x)
    Example:
    --------
        # Find a value of x that makes f(x) equal to some specific value f:
        # initial guess (all values of x)
        x = 1.0
        x1 = x
        x2 = x
        # initial error
        error = f - f(x)
        error1 = error
        error2 = error
        itmax = 50  # maximum iterations
        cvg = False # initialize convergence to "False"
        for i in range(1,itmax+1):
            error = f - f(x)
            x,cvg,x1,error1,x2,error2 = \
                                     Iterate(x,error,x1,error1,x2,error2,i,cvg)
            if cvg:
                break
        if cvg:
            print "x converged after", i, :iterations"
        else:
            print "x did NOT converge after", i, "iterations"
        print "x, when f(x) is", f,"is", x
    '''

    tolRel = 1e-5
    dx = 0.1

    # Test for convergence
    if ((x0 - x1).abs < tolRel * [x0.abs, Constants.small].max and icount != 1) or f0 == 0
      x_new = x0
      cvg = true
    else
      cvg = false

      if icount == 1 # Perturbation
        mode = 1
      elsif icount == 2 # Linear fit
        mode = 2
      else # Quadratic fit
        mode = 3
      end

      if mode == 3
        # Quadratic fit
        if x0 == x1 # If two xi are equal, use a linear fit
          x1 = x2
          f1 = f2
          mode = 2
        elsif x0 == x2 # If two xi are equal, use a linear fit
          mode = 2
        else
          # Set up quadratic coefficients
          c = ((f2 - f0) / (x2 - x0) - (f1 - f0) / (x1 - x0)) / (x2 - x1)
          b = (f1 - f0) / (x1 - x0) - (x1 + x0) * c
          a = f0 - (b + c * x0) * x0

          if c.abs < Constants.small # If points are co-linear, use linear fit
            mode = 2
          elsif ((a + (b + c * x1) * x1 - f1) / f1).abs > Constants.small
            # If coefficients do not accurately predict data points due to
            # round-off, use linear fit
            mode = 2
          else
            d = b**2 - 4.0 * a * c # calculate discriminant to check for real roots
            if d < 0.0 # if no real roots, use linear fit
              mode = 2
            else
              if d > 0.0 # if real unequal roots, use nearest root to recent guess
                x_new = (-b + Math.sqrt(d)) / (2 * c)
                x_other = -x_new - b / c
                if (x_new - x0).abs > (x_other - x0).abs
                  x_new = x_other
                end
              else # If real equal roots, use that root
                x_new = -b / (2 * c)
              end

              if f1 * f0 > 0 and f2 * f0 > 0 # If the previous two f(x) were the same sign as the new
                if f2.abs > f1.abs
                  x2 = x1
                  f2 = f1
                end
              else
                if f2 * f0 > 0
                  x2 = x1
                  f2 = f1
                end
              end
              x1 = x0
              f1 = f0
            end
          end
        end
      end

      if mode == 2
        # Linear Fit
        m = (f1 - f0) / (x1 - x0)
        if m == 0 # If slope is zero, use perturbation
          mode = 1
        else
          x_new = x0 - f0 / m
          x2 = x1
          f2 = f1
          x1 = x0
          f1 = f0
        end
      end

      if mode == 1
        # Perturbation
        if x0.abs > Constants.small
          x_new = x0 * (1 + dx)
        else
          x_new = dx
        end
        x2 = x1
        f2 = f1
        x1 = x0
        f1 = f0
      end
    end
    return x_new, cvg, x1, f1, x2, f2
  end
end

class OutputVariables
  def self.zone_indoor_air_wetbulb_temperature(tdb, w, pr)
    tdb = tdb.collect { |n| UnitConversions.convert(n, "C", "F") } # degF
    pr = pr.collect { |n| UnitConversions.convert(n, "pa", "psi") } # psi
    twb = [tdb, w, pr].transpose.collect { |x, y, z| Psychrometrics.Twb_fT_w_P(x, y, z) } # degF
    twb = twb.collect { |n| UnitConversions.convert(n, "F", "C") } # degC
    return twb # degC
  end

  def self.wetbulb_globe_temperature(twb, mrt)
    twbg = [twb.collect { |n| n * 0.7 }, mrt.collect { |n| n * 0.3 }].transpose.map { |x| x.reduce(:+) } # degC
    return twbg # degC
  end
end

class OutputMeters
  def self.create_custom_building_unit_meters(model, runner, reporting_frequency, include_enduse_subcategories = false)
    # Initialize custom meter hash containing meter names and key/var groups
    custom_meter_infos = {}

    # Get building units
    units = Geometry.get_building_units(model, runner)

    units.each do |unit|
      # Get all zones in unit
      thermal_zones = []
      unit.spaces.each do |space|
        thermal_zone = space.thermalZone.get
        unless thermal_zones.include? thermal_zone
          thermal_zones << thermal_zone
        end
      end

      electricity_heating(custom_meter_infos, model, runner, unit, thermal_zones)
      electricity_cooling(custom_meter_infos, model, runner, unit, thermal_zones)
      electricity_interior_lighting(custom_meter_infos, model, runner, unit, thermal_zones)
      electricity_exterior_lighting(custom_meter_infos, model, runner, unit, thermal_zones)
      electricity_interior_equipment(custom_meter_infos, model, runner, unit, thermal_zones)
      electricity_fans_heating(custom_meter_infos, model, runner, unit, thermal_zones)
      electricity_fans_cooling(custom_meter_infos, model, runner, unit, thermal_zones)
      electricity_pumps_heating(custom_meter_infos, model, runner, unit, thermal_zones)
      electricity_pumps_cooling(custom_meter_infos, model, runner, unit, thermal_zones)
      electricity_water_systems(custom_meter_infos, model, runner, unit, thermal_zones)
      electricity_photovoltaics(custom_meter_infos, model, runner, unit, thermal_zones)
      natural_gas_heating(custom_meter_infos, model, runner, unit, thermal_zones)
      natural_gas_interior_equipment(custom_meter_infos, model, runner, unit, thermal_zones)
      natural_gas_water_systems(custom_meter_infos, model, runner, unit, thermal_zones)
      fuel_oil_heating(custom_meter_infos, model, runner, unit, thermal_zones)
      fuel_oil_interior_equipment(custom_meter_infos, model, runner, unit, thermal_zones)
      fuel_oil_water_systems(custom_meter_infos, model, runner, unit, thermal_zones)
      propane_heating(custom_meter_infos, model, runner, unit, thermal_zones)
      propane_interior_equipment(custom_meter_infos, model, runner, unit, thermal_zones)
      propane_water_systems(custom_meter_infos, model, runner, unit, thermal_zones)

      if include_enduse_subcategories
        electricity_refrigerator(custom_meter_infos, model, runner, unit, thermal_zones)
        electricity_clothes_washer(custom_meter_infos, model, runner, unit, thermal_zones)
        electricity_clothes_dryer(custom_meter_infos, model, runner, unit, thermal_zones)
        natural_gas_clothes_dryer(custom_meter_infos, model, runner, unit, thermal_zones)
        propane_clothes_dryer(custom_meter_infos, model, runner, unit, thermal_zones)
        electricity_cooking_range(custom_meter_infos, model, runner, unit, thermal_zones)
        natural_gas_cooking_range(custom_meter_infos, model, runner, unit, thermal_zones)
        propane_cooking_range(custom_meter_infos, model, runner, unit, thermal_zones)
        electricity_dishwasher(custom_meter_infos, model, runner, unit, thermal_zones)
        electricity_plug_loads(custom_meter_infos, model, runner, unit, thermal_zones)
        electricity_house_fan(custom_meter_infos, model, runner, unit, thermal_zones)
        electricity_range_fan(custom_meter_infos, model, runner, unit, thermal_zones)
        electricity_bath_fan(custom_meter_infos, model, runner, unit, thermal_zones)
        electricity_ceiling_fan(custom_meter_infos, model, runner, unit, thermal_zones)
        electricity_extra_refrigerator(custom_meter_infos, model, runner, unit, thermal_zones)
        electricity_freezer(custom_meter_infos, model, runner, unit, thermal_zones)
        electricity_pool_heater(custom_meter_infos, model, runner, unit, thermal_zones)
        natural_gas_pool_heater(custom_meter_infos, model, runner, unit, thermal_zones)
        electricity_pool_pump(custom_meter_infos, model, runner, unit, thermal_zones)
        electricity_hot_tub_heater(custom_meter_infos, model, runner, unit, thermal_zones)
        natural_gas_hot_tub_heater(custom_meter_infos, model, runner, unit, thermal_zones)
        electricity_hot_tub_pump(custom_meter_infos, model, runner, unit, thermal_zones)
        natural_gas_grill(custom_meter_infos, model, runner, unit, thermal_zones)
        natural_gas_lighting(custom_meter_infos, model, runner, unit, thermal_zones)
        natural_gas_fireplace(custom_meter_infos, model, runner, unit, thermal_zones)
        electricity_well_pump(custom_meter_infos, model, runner, unit, thermal_zones)
        electricity_garage_lighting(custom_meter_infos, model, runner, unit, thermal_zones)
      end
    end

    results = OpenStudio::IdfObjectVector.new
    custom_meter_infos.each do |meter_name, custom_meter_info|
      next if custom_meter_info["key_var_groups"].empty?

      custom_meter = create_custom_meter(meter_name: meter_name,
                                         fuel_type: custom_meter_info["fuel_type"],
                                         key_var_groups: custom_meter_info["key_var_groups"])
      results << OpenStudio::IdfObject.load(custom_meter).get
      results << OpenStudio::IdfObject.load("Output:Meter,#{meter_name},#{reporting_frequency};").get
    end

    return results
  end

  def self.create_custom_meter(meter_name:,
                               fuel_type:,
                               key_var_groups:)
    custom_meter = "Meter:Custom,#{meter_name},#{fuel_type}"
    key_var_groups.each do |key_var_group|
      key, var = key_var_group
      custom_meter += ",#{key},#{var}"
    end
    custom_meter += ";"
    return custom_meter
  end

  def self.electricity_heating(custom_meter_infos, model, runner, unit, thermal_zones)
    custom_meter_infos["#{unit.name}:ElectricityHeating"] = { "fuel_type" => "Electricity", "key_var_groups" => [] }
    custom_meter_infos["Central:ElectricityHeating"] = { "fuel_type" => "Electricity", "key_var_groups" => [] }
    thermal_zones.each do |thermal_zone|
      heating_equipment = HVAC.existing_heating_equipment(model, runner, thermal_zone)
      heating_equipment.each do |htg_equip|
        clg_coil, htg_coil, supp_htg_coil = HVAC.get_coils_from_hvac_equip(htg_equip)

        if htg_equip.is_a? OpenStudio::Model::AirLoopHVACUnitarySystem
          custom_meter_infos["#{unit.name}:ElectricityHeating"]["key_var_groups"] << ["#{htg_coil.name}", "Heating Coil Electric Energy"]
          custom_meter_infos["#{unit.name}:ElectricityHeating"]["key_var_groups"] << ["#{htg_equip.name}", "Unitary System Heating Ancillary Electric Energy"]
          unless htg_coil.is_a? OpenStudio::Model::CoilCoolingWaterToAirHeatPumpEquationFit
            custom_meter_infos["#{unit.name}:ElectricityHeating"]["key_var_groups"] << ["#{htg_coil.name}", "Heating Coil Defrost Electric Energy"]
            custom_meter_infos["#{unit.name}:ElectricityHeating"]["key_var_groups"] << ["#{htg_coil.name}", "Heating Coil Crankcase Heater Electric Energy"]
          end
          unless supp_htg_coil.nil?
            custom_meter_infos["#{unit.name}:ElectricityHeating"]["key_var_groups"] << ["#{supp_htg_coil.name}", "Heating Coil Electric Energy"]
          end
        elsif htg_equip.is_a? OpenStudio::Model::ZoneHVACBaseboardConvectiveWater

          model.getPlantLoops.each do |plant_loop|
            is_specified_zone = false
            units_served = []
            plant_loop.demandComponents.each do |demand_component|
              next unless demand_component.to_CoilHeatingWaterBaseboard.is_initialized

              demand_coil = demand_component.to_CoilHeatingWaterBaseboard.get
              thermal_zone_served = demand_coil.containingZoneHVACComponent.get.thermalZone.get
              thermal_zone_served.spaces.each do |space_served|
                unit_served = space_served.buildingUnit.get
                next if units_served.include? unit_served

                units_served << unit_served
              end
              next if thermal_zone_served != thermal_zone

              is_specified_zone = true
            end
            next unless is_specified_zone

            plant_loop.supplyComponents.each do |supply_component|
              next unless supply_component.to_BoilerHotWater.is_initialized

              if units_served.length != 1 # this is a central system
                if supply_component.to_BoilerHotWater.get.fuelType == "Electricity"
                  custom_meter_infos["Central:ElectricityHeating"]["key_var_groups"] << ["#{supply_component.name}", "Boiler Electric Energy"]
                end
                custom_meter_infos["Central:ElectricityHeating"]["key_var_groups"] << ["#{supply_component.name}", "Boiler Ancillary Electric Energy"]
              else
                if supply_component.to_BoilerHotWater.get.fuelType == "Electricity"
                  custom_meter_infos["#{unit.name}:ElectricityHeating"]["key_var_groups"] << ["#{supply_component.name}", "Boiler Electric Energy"]
                end
                custom_meter_infos["#{unit.name}:ElectricityHeating"]["key_var_groups"] << ["#{supply_component.name}", "Boiler Ancillary Electric Energy"]
              end
            end
          end

        elsif htg_equip.is_a? OpenStudio::Model::ZoneHVACBaseboardConvectiveElectric
          custom_meter_infos["#{unit.name}:ElectricityHeating"]["key_var_groups"] << ["#{htg_equip.name}", "Baseboard Electric Energy"]

        elsif htg_equip.is_a? OpenStudio::Model::ZoneHVACFourPipeFanCoil or htg_equip.is_a? OpenStudio::Model::ZoneHVACPackagedTerminalAirConditioner

          model.getPlantLoops.each do |plant_loop|
            is_specified_zone = false
            units_served = []
            plant_loop.demandComponents.each do |demand_component|
              next unless demand_component.to_CoilHeatingWater.is_initialized

              demand_coil = demand_component.to_CoilHeatingWater.get
              thermal_zone_served = demand_coil.containingZoneHVACComponent.get.thermalZone.get
              thermal_zone_served.spaces.each do |space_served|
                unit_served = space_served.buildingUnit.get
                next if units_served.include? unit_served

                units_served << unit_served
              end
              next if thermal_zone_served != thermal_zone

              is_specified_zone = true
            end
            next unless is_specified_zone

            plant_loop.supplyComponents.each do |supply_component|
              next unless supply_component.to_BoilerHotWater.is_initialized

              if units_served.length != 1 # this is a central system
                if supply_component.to_BoilerHotWater.get.fuelType == "Electricity"
                  custom_meter_infos["Central:ElectricityHeating"]["key_var_groups"] << ["#{supply_component.name}", "Boiler Electric Energy"]
                end
                custom_meter_infos["Central:ElectricityHeating"]["key_var_groups"] << ["#{supply_component.name}", "Boiler Ancillary Electric Energy"]
              else
                if supply_component.to_BoilerHotWater.get.fuelType == "Electricity"
                  custom_meter_infos["#{unit.name}:ElectricityHeating"]["key_var_groups"] << ["#{supply_component.name}", "Boiler Electric Energy"]
                end
                custom_meter_infos["#{unit.name}:ElectricityHeating"]["key_var_groups"] << ["#{supply_component.name}", "Boiler Ancillary Electric Energy"]
              end
            end
          end

        end
      end
    end
  end

  def self.electricity_cooling(custom_meter_infos, model, runner, unit, thermal_zones)
    custom_meter_infos["#{unit.name}:ElectricityCooling"] = { "fuel_type" => "Electricity", "key_var_groups" => [] }
    custom_meter_infos["Central:ElectricityCooling"] = { "fuel_type" => "Electricity", "key_var_groups" => [] }
    thermal_zones.each do |thermal_zone|
      cooling_equipment = HVAC.existing_cooling_equipment(model, runner, thermal_zone)
      cooling_equipment.each do |clg_equip|
        clg_coil, htg_coil, supp_htg_coil = HVAC.get_coils_from_hvac_equip(clg_equip)

        if clg_equip.is_a? OpenStudio::Model::AirLoopHVACUnitarySystem
          custom_meter_infos["#{unit.name}:ElectricityCooling"]["key_var_groups"] << ["#{clg_coil.name}", "Cooling Coil Electric Energy"]
          custom_meter_infos["#{unit.name}:ElectricityCooling"]["key_var_groups"] << ["#{clg_equip.name}", "Unitary System Cooling Ancillary Electric Energy"]
          unless clg_coil.is_a? OpenStudio::Model::CoilCoolingWaterToAirHeatPumpEquationFit
            custom_meter_infos["#{unit.name}:ElectricityCooling"]["key_var_groups"] << ["#{clg_coil.name}", "Cooling Coil Crankcase Heater Electric Energy"]
          end
        elsif clg_equip.is_a? OpenStudio::Model::ZoneHVACPackagedTerminalAirConditioner
          custom_meter_infos["#{unit.name}:ElectricityCooling"]["key_var_groups"] << ["#{clg_coil.name}", "Cooling Coil Electric Energy"]
        elsif clg_equip.is_a? OpenStudio::Model::ZoneHVACFourPipeFanCoil
          model.getPlantLoops.each do |plant_loop|
            is_specified_zone = false
            units_served = []
            plant_loop.demandComponents.each do |demand_component|
              next unless demand_component.to_CoilCoolingWater.is_initialized

              demand_coil = demand_component.to_CoilCoolingWater.get
              thermal_zone_served = demand_coil.containingZoneHVACComponent.get.thermalZone.get
              thermal_zone_served.spaces.each do |space_served|
                unit_served = space_served.buildingUnit.get
                next if units_served.include? unit_served

                units_served << unit_served
              end
              next if thermal_zone_served != thermal_zone

              is_specified_zone = true
            end
            next unless is_specified_zone

            plant_loop.supplyComponents.each do |supply_component|
              next unless supply_component.to_ChillerElectricEIR.is_initialized

              if units_served.length != 1 # this is a central system
                custom_meter_infos["Central:ElectricityCooling"]["key_var_groups"] << ["#{supply_component.name}", "Chiller Electric Energy"]
              else
                custom_meter_infos["#{unit.name}:ElectricityCooling"]["key_var_groups"] << ["#{supply_component.name}", "Chiller Electric Energy"]
              end
            end
          end

        end
      end
      dehumidifiers = HVAC.get_dehumidifiers(model, runner, thermal_zone)
      dehumidifiers.each do |dehumidifier|
        custom_meter_infos["#{unit.name}:ElectricityCooling"]["key_var_groups"] << ["#{dehumidifier.name}", "Zone Dehumidifier Electric Energy"]
      end
    end
  end

  def self.electricity_interior_lighting(custom_meter_infos, model, runner, unit, thermal_zones)
    custom_meter_infos["#{unit.name}:ElectricityInteriorLighting"] = { "fuel_type" => "Electricity", "key_var_groups" => [] }
    thermal_zones.each do |thermal_zone|
      custom_meter_infos["#{unit.name}:ElectricityInteriorLighting"]["key_var_groups"] << ["", "InteriorLights:Electricity:Zone:#{thermal_zone.name}"]
    end
  end

  def self.electricity_exterior_lighting(custom_meter_infos, model, runner, unit, thermal_zones)
    custom_meter_infos["Central:ElectricityExteriorLighting"] = { "fuel_type" => "Electricity", "key_var_groups" => [] }
    custom_meter_infos["Central:ElectricityExteriorHolidayLighting"] = { "fuel_type" => "Electricity", "key_var_groups" => [] }
    model.getExteriorLightss.each do |exterior_lights|
      if exterior_lights.endUseSubcategory.include? Constants.ObjectNameLightingExteriorHoliday
        custom_meter_infos["Central:ElectricityExteriorHolidayLighting"]["key_var_groups"] << ["#{exterior_lights.name}", "Exterior Lights Electric Energy"]
      else
        custom_meter_infos["Central:ElectricityExteriorLighting"]["key_var_groups"] << ["#{exterior_lights.name}", "Exterior Lights Electric Energy"]
      end
    end
  end

  def self.electricity_interior_equipment(custom_meter_infos, model, runner, unit, thermal_zones)
    custom_meter_infos["#{unit.name}:ElectricityInteriorEquipment"] = { "fuel_type" => "Electricity", "key_var_groups" => [] }
    unit.spaces.each do |space|
      space.electricEquipment.each do |equip|
        custom_meter_infos["#{unit.name}:ElectricityInteriorEquipment"]["key_var_groups"] << ["#{equip.name}", "Electric Equipment Electric Energy"]
      end
    end
    custom_meter_infos["Central:ElectricityInteriorEquipment"] = { "fuel_type" => "Electricity", "key_var_groups" => [] }
    model.getSpaces.each do |space|
      next if space.buildingUnit.is_initialized

      space.electricEquipment.each do |equip|
        custom_meter_infos["Central:ElectricityInteriorEquipment"]["key_var_groups"] << ["#{equip.name}", "Electric Equipment Electric Energy"]
      end
    end
  end

  def self.electricity_fans_heating(custom_meter_infos, model, runner, unit, thermal_zones)
    custom_meter_infos["#{unit.name}:ElectricityFansHeating"] = { "fuel_type" => "Electricity", "key_var_groups" => [] }
    thermal_zones.each do |thermal_zone|
      heating_equipment = HVAC.existing_heating_equipment(model, runner, thermal_zone)
      heating_equipment.each do |htg_equip|
        clg_coil, htg_coil, supp_htg_coil = HVAC.get_coils_from_hvac_equip(htg_equip)
        if htg_equip.is_a? OpenStudio::Model::AirLoopHVACUnitarySystem
          custom_meter_infos["#{unit.name}:ElectricityFansHeating"]["key_var_groups"] << ["#{htg_equip.supplyFan.get.name}", "Fan Electric Energy"]
        end
      end
    end
    model.getPlantLoops.each do |plant_loop|
      if plant_loop.name.to_s == Constants.PlantLoopDomesticWater(unit.name.to_s)
        water_heater = Waterheater.get_water_heater(model, plant_loop, runner)
        if water_heater.is_a? OpenStudio::Model::WaterHeaterHeatPumpWrappedCondenser
          custom_meter_infos["#{unit.name}:ElectricityFansHeating"]["key_var_groups"] << ["#{water_heater.fan.name}", "Fan Electric Energy"]
        end
      end
    end
  end

  def self.electricity_fans_cooling(custom_meter_infos, model, runner, unit, thermal_zones)
    custom_meter_infos["#{unit.name}:ElectricityFansCooling"] = { "fuel_type" => "Electricity", "key_var_groups" => [] }
    thermal_zones.each do |thermal_zone|
      cooling_equipment = HVAC.existing_cooling_equipment(model, runner, thermal_zone)
      cooling_equipment.each do |clg_equip|
        clg_coil, htg_coil, supp_htg_coil = HVAC.get_coils_from_hvac_equip(clg_equip)
        if clg_equip.is_a? OpenStudio::Model::AirLoopHVACUnitarySystem
          custom_meter_infos["#{unit.name}:ElectricityFansCooling"]["key_var_groups"] << ["#{clg_equip.supplyFan.get.name}", "Fan Electric Energy"]
        elsif clg_equip.is_a? OpenStudio::Model::ZoneHVACPackagedTerminalAirConditioner or clg_equip.is_a? OpenStudio::Model::ZoneHVACFourPipeFanCoil
          custom_meter_infos["#{unit.name}:ElectricityFansCooling"]["key_var_groups"] << ["#{clg_equip.supplyAirFan.name}", "Fan Electric Energy"] # FIXME: all fan coil fan energy is assigned to fan cooling
        end
      end
    end
  end

  def self.electricity_pumps_heating(custom_meter_infos, model, runner, unit, thermal_zones)
    custom_meter_infos["#{unit.name}:ElectricityPumpsHeating"] = { "fuel_type" => "Electricity", "key_var_groups" => [] }
    custom_meter_infos["Central:ElectricityPumpsHeating"] = { "fuel_type" => "Electricity", "key_var_groups" => [] }
    model.getEnergyManagementSystemOutputVariables.each do |ems_output_var|
      if ems_output_var.name.to_s.include? "Central htg pump:Pumps:Electricity"
        custom_meter_infos["Central:ElectricityPumpsHeating"]["key_var_groups"] << ["", "#{ems_output_var.name}"]
      elsif ems_output_var.name.to_s.include? "htg pump:Pumps:Electricity" and ems_output_var.emsVariableName.to_s == "#{unit.name}_pumps_h".gsub(" ", "_")
        custom_meter_infos["#{unit.name}:ElectricityPumpsHeating"]["key_var_groups"] << ["", "#{ems_output_var.name}"]
      end
    end
    model.getPumpConstantSpeeds.each do |pump| # shw pump
      next unless pump.name.to_s.include? Constants.ObjectNameSolarHotWater

      if (unit.name.to_s == "unit 1" and not pump.name.to_s.include? "unit") or pump.name.to_s.end_with? "#{unit.name.to_s} pump"
        custom_meter_infos["#{unit.name}:ElectricityPumpsHeating"]["key_var_groups"] << ["#{pump.name}", "Pump Electric Energy"]
      end
    end
  end

  def self.electricity_pumps_cooling(custom_meter_infos, model, runner, unit, thermal_zones)
    custom_meter_infos["#{unit.name}:ElectricityPumpsCooling"] = { "fuel_type" => "Electricity", "key_var_groups" => [] }
    custom_meter_infos["Central:ElectricityPumpsCooling"] = { "fuel_type" => "Electricity", "key_var_groups" => [] }
    model.getEnergyManagementSystemOutputVariables.each do |ems_output_var|
      if ems_output_var.name.to_s.include? "Central clg pump:Pumps:Electricity"
        custom_meter_infos["Central:ElectricityPumpsCooling"]["key_var_groups"] << ["", "#{ems_output_var.name}"]
      elsif ems_output_var.name.to_s.include? "clg pump:Pumps:Electricity" and ems_output_var.emsVariableName.to_s == "#{unit.name}_pumps_c".gsub(" ", "_")
        custom_meter_infos["#{unit.name}:ElectricityPumpsCooling"]["key_var_groups"] << ["", "#{ems_output_var.name}"]
      end
    end
  end

  def self.electricity_water_systems(custom_meter_infos, model, runner, unit, thermal_zones)
    custom_meter_infos["#{unit.name}:ElectricityWaterSystems"] = { "fuel_type" => "Electricity", "key_var_groups" => [] }
    model.getPlantLoops.each do |plant_loop|
      if plant_loop.name.to_s == Constants.PlantLoopDomesticWater(unit.name.to_s)
        water_heater = Waterheater.get_water_heater(model, plant_loop, runner)

        if water_heater.is_a? OpenStudio::Model::WaterHeaterMixed
          custom_meter_infos["#{unit.name}:ElectricityWaterSystems"]["key_var_groups"] << ["#{water_heater.name}", "Water Heater Off Cycle Parasitic Electric Energy"]
          custom_meter_infos["#{unit.name}:ElectricityWaterSystems"]["key_var_groups"] << ["#{water_heater.name}", "Water Heater On Cycle Parasitic Electric Energy"]
          next if water_heater.heaterFuelType != "Electricity"

          custom_meter_infos["#{unit.name}:ElectricityWaterSystems"]["key_var_groups"] << ["#{water_heater.name}", "Water Heater Electric Energy"]
        elsif water_heater.is_a? OpenStudio::Model::WaterHeaterHeatPumpWrappedCondenser
          custom_meter_infos["#{unit.name}:ElectricityWaterSystems"]["key_var_groups"] << ["#{water_heater.name}", "Water Heater Off Cycle Ancillary Electric Energy"]
          custom_meter_infos["#{unit.name}:ElectricityWaterSystems"]["key_var_groups"] << ["#{water_heater.name}", "Water Heater On Cycle Ancillary Electric Energy"]

          tank = water_heater.tank.to_WaterHeaterStratified.get
          custom_meter_infos["#{unit.name}:ElectricityWaterSystems"]["key_var_groups"] << ["#{tank.name}", "Water Heater Electric Energy"]
          custom_meter_infos["#{unit.name}:ElectricityWaterSystems"]["key_var_groups"] << ["#{tank.name}", "Water Heater Off Cycle Parasitic Electric Energy"]
          custom_meter_infos["#{unit.name}:ElectricityWaterSystems"]["key_var_groups"] << ["#{tank.name}", "Water Heater On Cycle Parasitic Electric Energy"]

          coil = water_heater.dXCoil.to_CoilWaterHeatingAirToWaterHeatPumpWrapped.get
          custom_meter_infos["#{unit.name}:ElectricityWaterSystems"]["key_var_groups"] << ["#{coil.name}", "Cooling Coil Crankcase Heater Electric Energy"]
          custom_meter_infos["#{unit.name}:ElectricityWaterSystems"]["key_var_groups"] << ["#{coil.name}", "Cooling Coil Water Heating Electric Energy"]
        end
      end
    end
    shw_tank = Waterheater.get_shw_storage_tank(model, unit)
    unless shw_tank.nil?
      custom_meter_infos["#{unit.name}:ElectricityWaterSystems"]["key_var_groups"] << ["#{shw_tank.name}", "Water Heater Electric Energy"]
      custom_meter_infos["#{unit.name}:ElectricityWaterSystems"]["key_var_groups"] << ["#{shw_tank.name}", "Water Heater Off Cycle Parasitic Electric Energy"]
      custom_meter_infos["#{unit.name}:ElectricityWaterSystems"]["key_var_groups"] << ["#{shw_tank.name}", "Water Heater On Cycle Parasitic Electric Energy"]
    end
  end

  def self.electricity_photovoltaics(custom_meter_infos, model, runner, unit, thermal_zones)
    custom_meter_infos["Central:ElectricityPhotovoltaics"] = { "fuel_type" => "Electricity", "key_var_groups" => [] }
    model.getGeneratorPVWattss.each do |generator_pvwatts|
      custom_meter_infos["Central:ElectricityPhotovoltaics"]["key_var_groups"] << ["#{generator_pvwatts.name}", "Generator Produced DC Electric Energy"]
    end
    model.getElectricLoadCenterInverterPVWattss.each do |electric_load_center_inverter_pvwatts|
      custom_meter_infos["Central:ElectricityPhotovoltaics"]["key_var_groups"] << ["#{electric_load_center_inverter_pvwatts.name}", "Inverter Conversion Loss Decrement Energy"]
    end
  end

  def self.natural_gas_heating(custom_meter_infos, model, runner, unit, thermal_zones)
    custom_meter_infos["#{unit.name}:NaturalGasHeating"] = { "fuel_type" => "NaturalGas", "key_var_groups" => [] }
    custom_meter_infos["Central:NaturalGasHeating"] = { "fuel_type" => "NaturalGas", "key_var_groups" => [] }
    thermal_zones.each do |thermal_zone|
      heating_equipment = HVAC.existing_heating_equipment(model, runner, thermal_zone)
      heating_equipment.each do |htg_equip|
        clg_coil, htg_coil, supp_htg_coil = HVAC.get_coils_from_hvac_equip(htg_equip)

        if htg_equip.is_a? OpenStudio::Model::AirLoopHVACUnitarySystem
          next if htg_coil.is_a? OpenStudio::Model::CoilHeatingElectric or htg_coil.is_a? OpenStudio::Model::CoilHeatingDXSingleSpeed or htg_coil.is_a? OpenStudio::Model::CoilHeatingDXMultiSpeed

          if htg_coil.is_a? OpenStudio::Model::CoilHeatingGas
            next if htg_coil.fuelType != "NaturalGas"
          end

          custom_meter_infos["#{unit.name}:NaturalGasHeating"]["key_var_groups"] << ["#{htg_coil.name}", "Heating Coil Gas Energy"]
          custom_meter_infos["#{unit.name}:NaturalGasHeating"]["key_var_groups"] << ["#{htg_coil.name}", "Heating Coil Ancillary Gas Energy"]

        elsif htg_equip.is_a? OpenStudio::Model::ZoneHVACBaseboardConvectiveWater
          model.getPlantLoops.each do |plant_loop|
            is_specified_zone = false
            units_served = []
            plant_loop.demandComponents.each do |demand_component|
              next unless demand_component.to_CoilHeatingWaterBaseboard.is_initialized

              demand_coil = demand_component.to_CoilHeatingWaterBaseboard.get
              thermal_zone_served = demand_coil.containingZoneHVACComponent.get.thermalZone.get
              thermal_zone_served.spaces.each do |space_served|
                unit_served = space_served.buildingUnit.get
                next if units_served.include? unit_served

                units_served << unit_served
              end
              next if thermal_zone_served != thermal_zone

              is_specified_zone = true
            end
            next unless is_specified_zone

            plant_loop.supplyComponents.each do |supply_component|
              next unless supply_component.to_BoilerHotWater.is_initialized
              next if supply_component.to_BoilerHotWater.get.fuelType != "NaturalGas"

              if units_served.length != 1 # this is a central system
                custom_meter_infos["Central:NaturalGasHeating"]["key_var_groups"] << ["#{supply_component.name}", "Boiler Gas Energy"]
              else
                custom_meter_infos["#{unit.name}:NaturalGasHeating"]["key_var_groups"] << ["#{supply_component.name}", "Boiler Gas Energy"]
              end
            end
          end

        elsif htg_equip.is_a? OpenStudio::Model::ZoneHVACFourPipeFanCoil or htg_equip.is_a? OpenStudio::Model::ZoneHVACPackagedTerminalAirConditioner
          model.getPlantLoops.each do |plant_loop|
            is_specified_zone = false
            units_served = []
            plant_loop.demandComponents.each do |demand_component|
              next unless demand_component.to_CoilHeatingWater.is_initialized

              demand_coil = demand_component.to_CoilHeatingWater.get
              thermal_zone_served = demand_coil.containingZoneHVACComponent.get.thermalZone.get
              thermal_zone_served.spaces.each do |space_served|
                unit_served = space_served.buildingUnit.get
                next if units_served.include? unit_served

                units_served << unit_served
              end
              next if thermal_zone_served != thermal_zone

              is_specified_zone = true
            end
            next unless is_specified_zone

            plant_loop.supplyComponents.each do |supply_component|
              next unless supply_component.to_BoilerHotWater.is_initialized
              next if supply_component.to_BoilerHotWater.get.fuelType != "NaturalGas"

              if units_served.length != 1 # this is a central system
                custom_meter_infos["Central:NaturalGasHeating"]["key_var_groups"] << ["#{supply_component.name}", "Boiler Gas Energy"]
              else
                custom_meter_infos["#{unit.name}:NaturalGasHeating"]["key_var_groups"] << ["#{supply_component.name}", "Boiler Gas Energy"]
              end
            end
          end
        end
      end
    end
  end

  def self.natural_gas_interior_equipment(custom_meter_infos, model, runner, unit, thermal_zones)
    custom_meter_infos["#{unit.name}:NaturalGasInteriorEquipment"] = { "fuel_type" => "NaturalGas", "key_var_groups" => [] }
    unit.spaces.each do |space|
      space.gasEquipment.each do |equip|
        custom_meter_infos["#{unit.name}:NaturalGasInteriorEquipment"]["key_var_groups"] << ["#{equip.name}", "Gas Equipment Gas Energy"]
      end
      space.otherEquipment.each do |equip|
        next if equip.fuelType != "NaturalGas"

        custom_meter_infos["#{unit.name}:NaturalGasInteriorEquipment"]["key_var_groups"] << ["#{equip.name}", "Other Equipment Gas Energy"]
      end
    end
    custom_meter_infos["Central:NaturalGasInteriorEquipment"] = { "fuel_type" => "NaturalGas", "key_var_groups" => [] }
    model.getSpaces.each do |space|
      next if space.buildingUnit.is_initialized

      space.gasEquipment.each do |equip|
        custom_meter_infos["Central:NaturalGasInteriorEquipment"]["key_var_groups"] << ["#{equip.name}", "Gas Equipment Gas Energy"]
      end
      space.otherEquipment.each do |equip|
        next if equip.fuelType != "NaturalGas"

        custom_meter_infos["Central:NaturalGasInteriorEquipment"]["key_var_groups"] << ["#{equip.name}", "Other Equipment Gas Energy"]
      end
    end
  end

  def self.natural_gas_water_systems(custom_meter_infos, model, runner, unit, thermal_zones)
    custom_meter_infos["#{unit.name}:NaturalGasWaterSystems"] = { "fuel_type" => "NaturalGas", "key_var_groups" => [] }
    model.getPlantLoops.each do |plant_loop|
      if plant_loop.name.to_s == Constants.PlantLoopDomesticWater(unit.name.to_s)
        water_heater = Waterheater.get_water_heater(model, plant_loop, runner)
        next unless water_heater.is_a? OpenStudio::Model::WaterHeaterMixed
        next if water_heater.heaterFuelType != "NaturalGas"

        custom_meter_infos["#{unit.name}:NaturalGasWaterSystems"]["key_var_groups"] << ["#{water_heater.name}", "Water Heater Gas Energy"]
      end
    end
  end

  def self.fuel_oil_heating(custom_meter_infos, model, runner, unit, thermal_zones)
    custom_meter_infos["#{unit.name}:FuelOilHeating"] = { "fuel_type" => "FuelOil#1", "key_var_groups" => [] }
    custom_meter_infos["Central:FuelOilHeating"] = { "fuel_type" => "FuelOil#1", "key_var_groups" => [] }
    thermal_zones.each do |thermal_zone|
      heating_equipment = HVAC.existing_heating_equipment(model, runner, thermal_zone)
      heating_equipment.each do |htg_equip|
        clg_coil, htg_coil, supp_htg_coil = HVAC.get_coils_from_hvac_equip(htg_equip)

        if htg_equip.is_a? OpenStudio::Model::AirLoopHVACUnitarySystem
          next if htg_coil.is_a? OpenStudio::Model::CoilHeatingElectric or htg_coil.is_a? OpenStudio::Model::CoilHeatingDXSingleSpeed or htg_coil.is_a? OpenStudio::Model::CoilHeatingDXMultiSpeed

          if htg_coil.is_a? OpenStudio::Model::CoilHeatingGas
            next if htg_coil.fuelType != "FuelOil#1"
          end

          custom_meter_infos["#{unit.name}:FuelOilHeating"]["key_var_groups"] << ["#{htg_coil.name}", "Heating Coil FuelOil#1 Energy"]
          custom_meter_infos["#{unit.name}:FuelOilHeating"]["key_var_groups"] << ["#{htg_coil.name}", "Heating Coil Ancillary FuelOil#1 Energy"]

        elsif htg_equip.is_a? OpenStudio::Model::ZoneHVACBaseboardConvectiveWater
          model.getPlantLoops.each do |plant_loop|
            is_specified_zone = false
            units_served = []
            plant_loop.demandComponents.each do |demand_component|
              next unless demand_component.to_CoilHeatingWaterBaseboard.is_initialized

              demand_coil = demand_component.to_CoilHeatingWaterBaseboard.get
              thermal_zone_served = demand_coil.containingZoneHVACComponent.get.thermalZone.get
              thermal_zone_served.spaces.each do |space_served|
                unit_served = space_served.buildingUnit.get
                next if units_served.include? unit_served

                units_served << unit_served
              end
              next if thermal_zone_served != thermal_zone

              is_specified_zone = true
            end
            next unless is_specified_zone

            plant_loop.supplyComponents.each do |supply_component|
              next unless supply_component.to_BoilerHotWater.is_initialized
              next if supply_component.to_BoilerHotWater.get.fuelType != "FuelOil#1"

              if units_served.length != 1 # this is a central system
                custom_meter_infos["Central:FuelOilHeating"]["key_var_groups"] << ["#{supply_component.name}", "Boiler FuelOil#1 Energy"]
              else
                custom_meter_infos["#{unit.name}:FuelOilHeating"]["key_var_groups"] << ["#{supply_component.name}", "Boiler FuelOil#1 Energy"]
              end
            end
          end

        elsif htg_equip.is_a? OpenStudio::Model::ZoneHVACFourPipeFanCoil or htg_equip.is_a? OpenStudio::Model::ZoneHVACPackagedTerminalAirConditioner
          model.getPlantLoops.each do |plant_loop|
            is_specified_zone = false
            units_served = []
            plant_loop.demandComponents.each do |demand_component|
              next unless demand_component.to_CoilHeatingWater.is_initialized

              demand_coil = demand_component.to_CoilHeatingWater.get
              thermal_zone_served = demand_coil.containingZoneHVACComponent.get.thermalZone.get
              thermal_zone_served.spaces.each do |space_served|
                unit_served = space_served.buildingUnit.get
                next if units_served.include? unit_served

                units_served << unit_served
              end
              next if thermal_zone_served != thermal_zone

              is_specified_zone = true
            end
            next unless is_specified_zone

            plant_loop.supplyComponents.each do |supply_component|
              next unless supply_component.to_BoilerHotWater.is_initialized
              next if supply_component.to_BoilerHotWater.get.fuelType != "FuelOil#1"

              if units_served.length != 1 # this is a central system
                custom_meter_infos["Central:FuelOilHeating"]["key_var_groups"] << ["#{supply_component.name}", "Boiler FuelOil#1 Energy"]
              else
                custom_meter_infos["#{unit.name}:FuelOilHeating"]["key_var_groups"] << ["#{supply_component.name}", "Boiler FuelOil#1 Energy"]
              end
            end
          end

        end
      end
    end
  end

  def self.fuel_oil_interior_equipment(custom_meter_infos, model, runner, unit, thermal_zones)
    custom_meter_infos["#{unit.name}:FuelOilInteriorEquipment"] = { "fuel_type" => "FuelOil#1", "key_var_groups" => [] }
    unit.spaces.each do |space|
      space.otherEquipment.each do |equip|
        next if equip.fuelType != "FuelOil#1"

        custom_meter_infos["#{unit.name}:FuelOilInteriorEquipment"]["key_var_groups"] << ["#{equip.name}", "Other Equipment FuelOil#1 Energy"]
      end
    end
    custom_meter_infos["Central:FuelOilInteriorEquipment"] = { "fuel_type" => "FuelOil#1", "key_var_groups" => [] }
    model.getSpaces.each do |space|
      next if space.buildingUnit.is_initialized

      space.otherEquipment.each do |equip|
        next if equip.fuelType != "FuelOil#1"

        custom_meter_infos["Central:FuelOilInteriorEquipment"]["key_var_groups"] << ["#{equip.name}", "Other Equipment FuelOil#1 Energy"]
      end
    end
  end

  def self.fuel_oil_water_systems(custom_meter_infos, model, runner, unit, thermal_zones)
    custom_meter_infos["#{unit.name}:FuelOilWaterSystems"] = { "fuel_type" => "FuelOil#1", "key_var_groups" => [] }
    model.getPlantLoops.each do |plant_loop|
      if plant_loop.name.to_s == Constants.PlantLoopDomesticWater(unit.name.to_s)
        water_heater = Waterheater.get_water_heater(model, plant_loop, runner)
        next unless water_heater.is_a? OpenStudio::Model::WaterHeaterMixed
        next if water_heater.heaterFuelType != "FuelOil#1"

        custom_meter_infos["#{unit.name}:FuelOilWaterSystems"]["key_var_groups"] << ["#{water_heater.name}", "Water Heater FuelOil#1 Energy"]
      end
    end
  end

  def self.propane_heating(custom_meter_infos, model, runner, unit, thermal_zones)
    custom_meter_infos["#{unit.name}:PropaneHeating"] = { "fuel_type" => "PropaneGas", "key_var_groups" => [] }
    custom_meter_infos["Central:PropaneHeating"] = { "fuel_type" => "PropaneGas", "key_var_groups" => [] }
    thermal_zones.each do |thermal_zone|
      heating_equipment = HVAC.existing_heating_equipment(model, runner, thermal_zone)
      heating_equipment.each do |htg_equip|
        clg_coil, htg_coil, supp_htg_coil = HVAC.get_coils_from_hvac_equip(htg_equip)

        if htg_equip.is_a? OpenStudio::Model::AirLoopHVACUnitarySystem
          next if htg_coil.is_a? OpenStudio::Model::CoilHeatingElectric or htg_coil.is_a? OpenStudio::Model::CoilHeatingDXSingleSpeed or htg_coil.is_a? OpenStudio::Model::CoilHeatingDXMultiSpeed

          if htg_coil.is_a? OpenStudio::Model::CoilHeatingGas
            next if htg_coil.fuelType != "PropaneGas"
          end

          custom_meter_infos["#{unit.name}:PropaneHeating"]["key_var_groups"] << ["#{htg_coil.name}", "Heating Coil Propane Energy"]
          custom_meter_infos["#{unit.name}:PropaneHeating"]["key_var_groups"] << ["#{htg_coil.name}", "Heating Coil Ancillary Propane Energy"]

        elsif htg_equip.is_a? OpenStudio::Model::ZoneHVACBaseboardConvectiveWater
          model.getPlantLoops.each do |plant_loop|
            is_specified_zone = false
            units_served = []
            plant_loop.demandComponents.each do |demand_component|
              next unless demand_component.to_CoilHeatingWaterBaseboard.is_initialized

              demand_coil = demand_component.to_CoilHeatingWaterBaseboard.get
              thermal_zone_served = demand_coil.containingZoneHVACComponent.get.thermalZone.get
              thermal_zone_served.spaces.each do |space_served|
                unit_served = space_served.buildingUnit.get
                next if units_served.include? unit_served

                units_served << unit_served
              end
              next if thermal_zone_served != thermal_zone

              is_specified_zone = true
            end
            next unless is_specified_zone

            plant_loop.supplyComponents.each do |supply_component|
              next unless supply_component.to_BoilerHotWater.is_initialized
              next if supply_component.to_BoilerHotWater.get.fuelType != "PropaneGas"

              if units_served.length != 1 # this is a central system
                custom_meter_infos["Central:PropaneHeating"]["key_var_groups"] << ["#{supply_component.name}", "Boiler Propane Energy"]
              else
                custom_meter_infos["#{unit.name}:PropaneHeating"]["key_var_groups"] << ["#{supply_component.name}", "Boiler Propane Energy"]
              end
            end
          end

        elsif htg_equip.is_a? OpenStudio::Model::ZoneHVACFourPipeFanCoil or htg_equip.is_a? OpenStudio::Model::ZoneHVACPackagedTerminalAirConditioner
          model.getPlantLoops.each do |plant_loop|
            is_specified_zone = false
            units_served = []
            plant_loop.demandComponents.each do |demand_component|
              next unless demand_component.to_CoilHeatingWater.is_initialized

              demand_coil = demand_component.to_CoilHeatingWater.get
              thermal_zone_served = demand_coil.containingZoneHVACComponent.get.thermalZone.get
              thermal_zone_served.spaces.each do |space_served|
                unit_served = space_served.buildingUnit.get
                next if units_served.include? unit_served

                units_served << unit_served
              end
              next if thermal_zone_served != thermal_zone

              is_specified_zone = true
            end
            next unless is_specified_zone

            plant_loop.supplyComponents.each do |supply_component|
              next unless supply_component.to_BoilerHotWater.is_initialized
              next if supply_component.to_BoilerHotWater.get.fuelType != "PropaneGas"

              if units_served.length != 1 # this is a central system
                custom_meter_infos["Central:PropaneHeating"]["key_var_groups"] << ["#{supply_component.name}", "Boiler Propane Energy"]
              else
                custom_meter_infos["#{unit.name}:PropaneHeating"]["key_var_groups"] << ["#{supply_component.name}", "Boiler Propane Energy"]
              end
            end
          end
        end
      end
    end
  end

  def self.propane_interior_equipment(custom_meter_infos, model, runner, unit, thermal_zones)
    custom_meter_infos["#{unit.name}:PropaneInteriorEquipment"] = { "fuel_type" => "PropaneGas", "key_var_groups" => [] }
    unit.spaces.each do |space|
      space.otherEquipment.each do |equip|
        next if equip.fuelType != "PropaneGas"

        custom_meter_infos["#{unit.name}:PropaneInteriorEquipment"]["key_var_groups"] << ["#{equip.name}", "Other Equipment Propane Energy"]
      end
    end
    custom_meter_infos["Central:PropaneInteriorEquipment"] = { "fuel_type" => "PropaneGas", "key_var_groups" => [] }
    model.getSpaces.each do |space|
      next if space.buildingUnit.is_initialized

      space.otherEquipment.each do |equip|
        next if equip.fuelType != "PropaneGas"

        custom_meter_infos["Central:PropaneInteriorEquipment"]["key_var_groups"] << ["#{equip.name}", "Other Equipment Propane Energy"]
      end
    end
  end

  def self.propane_water_systems(custom_meter_infos, model, runner, unit, thermal_zones)
    custom_meter_infos["#{unit.name}:PropaneWaterSystems"] = { "fuel_type" => "PropaneGas", "key_var_groups" => [] }
    model.getPlantLoops.each do |plant_loop|
      if plant_loop.name.to_s == Constants.PlantLoopDomesticWater(unit.name.to_s)
        water_heater = Waterheater.get_water_heater(model, plant_loop, runner)
        next unless water_heater.is_a? OpenStudio::Model::WaterHeaterMixed
        next if water_heater.heaterFuelType != "PropaneGas"

        custom_meter_infos["#{unit.name}:PropaneWaterSystems"]["key_var_groups"] << ["#{water_heater.name}", "Water Heater Propane Energy"]
      end
    end
  end

  def self.electricity_refrigerator(custom_meter_infos, model, runner, unit, thermal_zones)
    custom_meter_infos["#{unit.name}:ElectricityRefrigerator"] = { "fuel_type" => "Electricity", "key_var_groups" => [] }
    unit.spaces.each do |space|
      space.electricEquipment.each do |equip|
        next unless equip.endUseSubcategory.include? Constants.ObjectNameRefrigerator

        custom_meter_infos["#{unit.name}:ElectricityRefrigerator"]["key_var_groups"] << ["#{equip.name}", "Electric Equipment Electric Energy"]
      end
    end
  end

  def self.electricity_clothes_washer(custom_meter_infos, model, runner, unit, thermal_zones)
    custom_meter_infos["#{unit.name}:ElectricityClothesWasher"] = { "fuel_type" => "Electricity", "key_var_groups" => [] }
    unit.spaces.each do |space|
      space.electricEquipment.each do |equip|
        next unless equip.endUseSubcategory.include? Constants.ObjectNameClothesWasher

        custom_meter_infos["#{unit.name}:ElectricityClothesWasher"]["key_var_groups"] << ["#{equip.name}", "Electric Equipment Electric Energy"]
      end
    end
  end

  def self.electricity_clothes_dryer(custom_meter_infos, model, runner, unit, thermal_zones)
    custom_meter_infos["#{unit.name}:ElectricityClothesDryer"] = { "fuel_type" => "Electricity", "key_var_groups" => [] }
    unit.spaces.each do |space|
      space.electricEquipment.each do |equip|
        next unless equip.endUseSubcategory.include? Constants.ObjectNameClothesDryer(nil)

        custom_meter_infos["#{unit.name}:ElectricityClothesDryer"]["key_var_groups"] << ["#{equip.name}", "Electric Equipment Electric Energy"]
      end
    end
  end

  def self.natural_gas_clothes_dryer(custom_meter_infos, model, runner, unit, thermal_zones)
    custom_meter_infos["#{unit.name}:NaturalGasClothesDryer"] = { "fuel_type" => "NaturalGas", "key_var_groups" => [] }
    unit.spaces.each do |space|
      space.otherEquipment.each do |equip|
        next unless equip.fuelType == "NaturalGas"
        next unless equip.endUseSubcategory.include? Constants.ObjectNameClothesDryer(nil)

        custom_meter_infos["#{unit.name}:NaturalGasClothesDryer"]["key_var_groups"] << ["#{equip.name}", "Other Equipment Gas Energy"]
      end
    end
  end

  def self.propane_clothes_dryer(custom_meter_infos, model, runner, unit, thermal_zones)
    custom_meter_infos["#{unit.name}:PropaneClothesDryer"] = { "fuel_type" => "PropaneGas", "key_var_groups" => [] }
    unit.spaces.each do |space|
      space.otherEquipment.each do |equip|
        next unless equip.fuelType == "PropaneGas"
        next unless equip.endUseSubcategory.include? Constants.ObjectNameClothesDryer(nil)

        custom_meter_infos["#{unit.name}:PropaneClothesDryer"]["key_var_groups"] << ["#{equip.name}", "Other Equipment Propane Energy"]
      end
    end
  end

  def self.electricity_cooking_range(custom_meter_infos, model, runner, unit, thermal_zones)
    custom_meter_infos["#{unit.name}:ElectricityCookingRange"] = { "fuel_type" => "Electricity", "key_var_groups" => [] }
    unit.spaces.each do |space|
      space.electricEquipment.each do |equip|
        next unless equip.endUseSubcategory.include? Constants.ObjectNameCookingRange(nil)

        custom_meter_infos["#{unit.name}:ElectricityCookingRange"]["key_var_groups"] << ["#{equip.name}", "Electric Equipment Electric Energy"]
      end
    end
  end

  def self.natural_gas_cooking_range(custom_meter_infos, model, runner, unit, thermal_zones)
    custom_meter_infos["#{unit.name}:NaturalGasCookingRange"] = { "fuel_type" => "NaturalGas", "key_var_groups" => [] }
    unit.spaces.each do |space|
      space.otherEquipment.each do |equip|
        next unless equip.fuelType == "NaturalGas"
        next unless equip.endUseSubcategory.include? Constants.ObjectNameCookingRange(nil)

        custom_meter_infos["#{unit.name}:NaturalGasCookingRange"]["key_var_groups"] << ["#{equip.name}", "Other Equipment Gas Energy"]
      end
    end
  end

  def self.propane_cooking_range(custom_meter_infos, model, runner, unit, thermal_zones)
    custom_meter_infos["#{unit.name}:PropaneCookingRange"] = { "fuel_type" => "PropaneGas", "key_var_groups" => [] }
    unit.spaces.each do |space|
      space.otherEquipment.each do |equip|
        next unless equip.fuelType == "PropaneGas"
        next unless equip.endUseSubcategory.include? Constants.ObjectNameCookingRange(nil)

        custom_meter_infos["#{unit.name}:PropaneCookingRange"]["key_var_groups"] << ["#{equip.name}", "Other Equipment Propane Energy"]
      end
    end
  end

  def self.electricity_dishwasher(custom_meter_infos, model, runner, unit, thermal_zones)
    custom_meter_infos["#{unit.name}:ElectricityDishwasher"] = { "fuel_type" => "Electricity", "key_var_groups" => [] }
    unit.spaces.each do |space|
      space.electricEquipment.each do |equip|
        next unless equip.endUseSubcategory.include? Constants.ObjectNameDishwasher

        custom_meter_infos["#{unit.name}:ElectricityDishwasher"]["key_var_groups"] << ["#{equip.name}", "Electric Equipment Electric Energy"]
      end
    end
  end

  def self.electricity_plug_loads(custom_meter_infos, model, runner, unit, thermal_zones)
    custom_meter_infos["#{unit.name}:ElectricityPlugLoads"] = { "fuel_type" => "Electricity", "key_var_groups" => [] }
    unit.spaces.each do |space|
      space.electricEquipment.each do |equip|
        next unless equip.endUseSubcategory.include? Constants.ObjectNameMiscPlugLoads

        custom_meter_infos["#{unit.name}:ElectricityPlugLoads"]["key_var_groups"] << ["#{equip.name}", "Electric Equipment Electric Energy"]
      end
    end
  end

  def self.electricity_house_fan(custom_meter_infos, model, runner, unit, thermal_zones)
    custom_meter_infos["#{unit.name}:ElectricityHouseFan"] = { "fuel_type" => "Electricity", "key_var_groups" => [] }
    unit.spaces.each do |space|
      space.electricEquipment.each do |equip|
        next unless equip.endUseSubcategory.include? "house fan"

        custom_meter_infos["#{unit.name}:ElectricityHouseFan"]["key_var_groups"] << ["#{equip.name}", "Electric Equipment Electric Energy"]
      end
    end
  end

  def self.electricity_range_fan(custom_meter_infos, model, runner, unit, thermal_zones)
    custom_meter_infos["#{unit.name}:ElectricityRangeFan"] = { "fuel_type" => "Electricity", "key_var_groups" => [] }
    unit.spaces.each do |space|
      space.electricEquipment.each do |equip|
        next unless equip.endUseSubcategory.include? "range fan"

        custom_meter_infos["#{unit.name}:ElectricityRangeFan"]["key_var_groups"] << ["#{equip.name}", "Electric Equipment Electric Energy"]
      end
    end
  end

  def self.electricity_bath_fan(custom_meter_infos, model, runner, unit, thermal_zones)
    custom_meter_infos["#{unit.name}:ElectricityBathFan"] = { "fuel_type" => "Electricity", "key_var_groups" => [] }
    unit.spaces.each do |space|
      space.electricEquipment.each do |equip|
        next unless equip.endUseSubcategory.include? "bath fan"

        custom_meter_infos["#{unit.name}:ElectricityBathFan"]["key_var_groups"] << ["#{equip.name}", "Electric Equipment Electric Energy"]
      end
    end
  end

  def self.electricity_ceiling_fan(custom_meter_infos, model, runner, unit, thermal_zones)
    custom_meter_infos["#{unit.name}:ElectricityCeilingFan"] = { "fuel_type" => "Electricity", "key_var_groups" => [] }
    unit.spaces.each do |space|
      space.electricEquipment.each do |equip|
        next unless equip.endUseSubcategory.include? Constants.ObjectNameCeilingFan

        custom_meter_infos["#{unit.name}:ElectricityCeilingFan"]["key_var_groups"] << ["#{equip.name}", "Electric Equipment Electric Energy"]
      end
    end
  end

  def self.electricity_extra_refrigerator(custom_meter_infos, model, runner, unit, thermal_zones)
    custom_meter_infos["#{unit.name}:ElectricityExtraRefrigerator"] = { "fuel_type" => "Electricity", "key_var_groups" => [] }
    unit.spaces.each do |space|
      space.electricEquipment.each do |equip|
        next unless equip.endUseSubcategory.include? Constants.ObjectNameExtraRefrigerator

        custom_meter_infos["#{unit.name}:ElectricityExtraRefrigerator"]["key_var_groups"] << ["#{equip.name}", "Electric Equipment Electric Energy"]
      end
    end

    custom_meter_infos["Central:ElectricityExtraRefrigerator"] = { "fuel_type" => "Electricity", "key_var_groups" => [] }
    model.getSpaces.each do |space|
      next if space.buildingUnit.is_initialized

      space.electricEquipment.each do |equip|
        next unless equip.endUseSubcategory.include? Constants.ObjectNameExtraRefrigerator

        custom_meter_infos["Central:ElectricityExtraRefrigerator"]["key_var_groups"] << ["#{equip.name}", "Electric Equipment Electric Energy"]
      end
    end
  end

  def self.electricity_freezer(custom_meter_infos, model, runner, unit, thermal_zones)
    custom_meter_infos["#{unit.name}:ElectricityFreezer"] = { "fuel_type" => "Electricity", "key_var_groups" => [] }
    unit.spaces.each do |space|
      space.electricEquipment.each do |equip|
        next unless equip.endUseSubcategory.include? Constants.ObjectNameFreezer

        custom_meter_infos["#{unit.name}:ElectricityFreezer"]["key_var_groups"] << ["#{equip.name}", "Electric Equipment Electric Energy"]
      end
    end

    custom_meter_infos["Central:ElectricityFreezer"] = { "fuel_type" => "Electricity", "key_var_groups" => [] }
    model.getSpaces.each do |space|
      next if space.buildingUnit.is_initialized

      space.electricEquipment.each do |equip|
        next unless equip.endUseSubcategory.include? Constants.ObjectNameFreezer

        custom_meter_infos["Central:ElectricityFreezer"]["key_var_groups"] << ["#{equip.name}", "Electric Equipment Electric Energy"]
      end
    end
  end

  def self.electricity_pool_heater(custom_meter_infos, model, runner, unit, thermal_zones)
    custom_meter_infos["#{unit.name}:ElectricityPoolHeater"] = { "fuel_type" => "Electricity", "key_var_groups" => [] }
    unit.spaces.each do |space|
      space.electricEquipment.each do |equip|
        next unless equip.endUseSubcategory.include? Constants.ObjectNamePoolHeater(Constants.FuelTypeElectric)

        custom_meter_infos["#{unit.name}:ElectricityPoolHeater"]["key_var_groups"] << ["#{equip.name}", "Electric Equipment Electric Energy"]
      end
    end
  end

  def self.natural_gas_pool_heater(custom_meter_infos, model, runner, unit, thermal_zones)
    custom_meter_infos["#{unit.name}:NaturalGasPoolHeater"] = { "fuel_type" => "NaturalGas", "key_var_groups" => [] }
    unit.spaces.each do |space|
      space.gasEquipment.each do |equip|
        next unless equip.endUseSubcategory.include? Constants.ObjectNamePoolHeater(Constants.FuelTypeGas)

        custom_meter_infos["#{unit.name}:NaturalGasPoolHeater"]["key_var_groups"] << ["#{equip.name}", "Gas Equipment Gas Energy"]
      end
    end
  end

  def self.electricity_pool_pump(custom_meter_infos, model, runner, unit, thermal_zones)
    custom_meter_infos["#{unit.name}:ElectricityPoolPump"] = { "fuel_type" => "Electricity", "key_var_groups" => [] }
    unit.spaces.each do |space|
      space.electricEquipment.each do |equip|
        next unless equip.endUseSubcategory.include? Constants.ObjectNamePoolPump

        custom_meter_infos["#{unit.name}:ElectricityPoolPump"]["key_var_groups"] << ["#{equip.name}", "Electric Equipment Electric Energy"]
      end
    end
  end

  def self.electricity_hot_tub_heater(custom_meter_infos, model, runner, unit, thermal_zones)
    custom_meter_infos["#{unit.name}:ElectricityHotTubHeater"] = { "fuel_type" => "Electricity", "key_var_groups" => [] }
    unit.spaces.each do |space|
      space.electricEquipment.each do |equip|
        next unless equip.endUseSubcategory.include? Constants.ObjectNameHotTubHeater(Constants.FuelTypeElectric)

        custom_meter_infos["#{unit.name}:ElectricityHotTubHeater"]["key_var_groups"] << ["#{equip.name}", "Electric Equipment Electric Energy"]
      end
    end
  end

  def self.natural_gas_hot_tub_heater(custom_meter_infos, model, runner, unit, thermal_zones)
    custom_meter_infos["#{unit.name}:NaturalGasHotTubHeater"] = { "fuel_type" => "NaturalGas", "key_var_groups" => [] }
    unit.spaces.each do |space|
      space.gasEquipment.each do |equip|
        next unless equip.endUseSubcategory.include? Constants.ObjectNameHotTubHeater(Constants.FuelTypeGas)

        custom_meter_infos["#{unit.name}:NaturalGasHotTubHeater"]["key_var_groups"] << ["#{equip.name}", "Gas Equipment Gas Energy"]
      end
    end
  end

  def self.electricity_hot_tub_pump(custom_meter_infos, model, runner, unit, thermal_zones)
    custom_meter_infos["#{unit.name}:ElectricityHotTubPump"] = { "fuel_type" => "Electricity", "key_var_groups" => [] }
    unit.spaces.each do |space|
      space.electricEquipment.each do |equip|
        next unless equip.endUseSubcategory.include? Constants.ObjectNameHotTubPump

        custom_meter_infos["#{unit.name}:ElectricityHotTubPump"]["key_var_groups"] << ["#{equip.name}", "Electric Equipment Electric Energy"]
      end
    end
  end

  def self.natural_gas_grill(custom_meter_infos, model, runner, unit, thermal_zones)
    custom_meter_infos["#{unit.name}:NaturalGasGrill"] = { "fuel_type" => "NaturalGas", "key_var_groups" => [] }
    unit.spaces.each do |space|
      space.gasEquipment.each do |equip|
        next unless equip.endUseSubcategory.include? Constants.ObjectNameGasGrill

        custom_meter_infos["#{unit.name}:NaturalGasGrill"]["key_var_groups"] << ["#{equip.name}", "Gas Equipment Gas Energy"]
      end
    end

    custom_meter_infos["Central:NaturalGasGrill"] = { "fuel_type" => "NaturalGas", "key_var_groups" => [] }
    model.getSpaces.each do |space|
      next if space.buildingUnit.is_initialized

      space.gasEquipment.each do |equip|
        next unless equip.endUseSubcategory.include? Constants.ObjectNameGasGrill

        custom_meter_infos["Central:NaturalGasGrill"]["key_var_groups"] << ["#{equip.name}", "Gas Equipment Gas Energy"]
      end
    end
  end

  def self.natural_gas_lighting(custom_meter_infos, model, runner, unit, thermal_zones)
    custom_meter_infos["#{unit.name}:NaturalGasLighting"] = { "fuel_type" => "NaturalGas", "key_var_groups" => [] }
    unit.spaces.each do |space|
      space.gasEquipment.each do |equip|
        next unless equip.endUseSubcategory.include? Constants.ObjectNameGasLighting

        custom_meter_infos["#{unit.name}:NaturalGasLighting"]["key_var_groups"] << ["#{equip.name}", "Gas Equipment Gas Energy"]
      end
    end

    custom_meter_infos["Central:NaturalGasLighting"] = { "fuel_type" => "NaturalGas", "key_var_groups" => [] }
    model.getSpaces.each do |space|
      next if space.buildingUnit.is_initialized

      space.gasEquipment.each do |equip|
        next unless equip.endUseSubcategory.include? Constants.ObjectNameGasLighting

        custom_meter_infos["Central:NaturalGasLighting"]["key_var_groups"] << ["#{equip.name}", "Gas Equipment Gas Energy"]
      end
    end
  end

  def self.natural_gas_fireplace(custom_meter_infos, model, runner, unit, thermal_zones)
    custom_meter_infos["#{unit.name}:NaturalGasFireplace"] = { "fuel_type" => "NaturalGas", "key_var_groups" => [] }
    unit.spaces.each do |space|
      space.gasEquipment.each do |equip|
        next unless equip.endUseSubcategory.include? Constants.ObjectNameGasFireplace

        custom_meter_infos["#{unit.name}:NaturalGasFireplace"]["key_var_groups"] << ["#{equip.name}", "Gas Equipment Gas Energy"]
      end
    end

    custom_meter_infos["Central:NaturalGasFireplace"] = { "fuel_type" => "NaturalGas", "key_var_groups" => [] }
    model.getSpaces.each do |space|
      next if space.buildingUnit.is_initialized

      space.gasEquipment.each do |equip|
        next unless equip.endUseSubcategory.include? Constants.ObjectNameGasFireplace

        custom_meter_infos["Central:NaturalGasFireplace"]["key_var_groups"] << ["#{equip.name}", "Gas Equipment Gas Energy"]
      end
    end
  end

  def self.electricity_well_pump(custom_meter_infos, model, runner, unit, thermal_zones)
    custom_meter_infos["#{unit.name}:ElectricityWellPump"] = { "fuel_type" => "Electricity", "key_var_groups" => [] }
    unit.spaces.each do |space|
      space.electricEquipment.each do |equip|
        next unless equip.endUseSubcategory.include? Constants.ObjectNameWellPump

        custom_meter_infos["#{unit.name}:ElectricityWellPump"]["key_var_groups"] << ["#{equip.name}", "Electric Equipment Electric Energy"]
      end
    end
  end

  def self.electricity_garage_lighting(custom_meter_infos, model, runner, unit, thermal_zones)
    custom_meter_infos["Central:ElectricityGarageLighting"] = { "fuel_type" => "Electricity", "key_var_groups" => [] }
    model.getLightss.each do |lights|
      next unless lights.endUseSubcategory.include? Constants.ObjectNameLightingGarage

      custom_meter_infos["Central:ElectricityGarageLighting"]["key_var_groups"] << ["#{lights.name}", "Lights Electric Energy"]
    end
  end
end
