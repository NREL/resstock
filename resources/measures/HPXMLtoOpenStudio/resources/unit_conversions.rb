class UnitConversions
  # As there is a performance penalty to using OpenStudio's built-in unit convert()
  # method, we use, our own methods here.

  def self.convert(x, from, to, fuel_type = nil)
    from.downcase!
    to.downcase!

    return x if from == to

    # Energy
    if from == 'btu' and to == 'j'
      return x * 1055.05585262
    elsif from == 'btu' and to == 'kwh'
      return x / 3412.141633127942
    elsif from == 'btu' and to == 'wh'
      return x / 3.412141633127942
    elsif from == 'j' and to == 'btu'
      return x * 3412.141633127942 / 1000.0 / 3600.0
    elsif from == 'j' and to == 'kbtu'
      return x * 3412.141633127942 / 1000.0 / 3600.0 / 1000.0
    elsif from == 'j' and to == 'kwh'
      return x / 3600000.0
    elsif from == 'kbtu' and to == 'therm'
      return x / 100.0
    elsif from == 'j' and to == 'therm'
      return x * 3412.141633127942 / 1000.0 / 3600.0 / 1000.0 / 100.0
    elsif from == 'kj' and to == 'btu'
      return x * 0.9478171203133172
    elsif from == 'gj' and to == 'mbtu'
      return x * 0.9478171203133172
    elsif from == 'kwh' and to == 'btu'
      return x * 3412.141633127942
    elsif from == 'kwh' and to == 'j'
      return x * 3600000.0
    elsif from == 'wh' and to == 'gj'
      return x * 0.0000036
    elsif from == 'kwh' and to == 'therm'
      return x / 29.307107017222222
    elsif from == 'kwh' and to == 'wh'
      return x * 1000.0
    elsif from == 'mbtu' and to == 'wh'
      return x * 293071.0701722222
    elsif from == 'therm' and to == 'btu'
      return x * 100000.0
    elsif from == 'therm' and to == 'kbtu'
      return x * 100.0
    elsif from == 'therm' and to == 'kwh'
      return x * 29.307107017222222
    elsif from == 'therm' and to == 'wh'
      return x * 29307.10701722222
    elsif from == 'wh' and to == 'btu'
      return x * 3.412141633127942
    elsif from == 'wh' and to == 'kwh'
      return x / 1000.0
    elsif from == 'wh' and to == 'therm'
      return x / 29307.10701722222
    elsif from == 'wh' and to == 'mbtu'
      return x / 293071.0701722222
    elsif from == 'kbtu' and to == 'btu'
      return x * 1000.0
    elsif from == 'btu' and to == 'gal'
      if fuel_type == Constants.FuelTypePropane
        return x / 91600.0
      elsif fuel_type == Constants.FuelTypeOil
        return x / 139000.0
      end

      fail "Unhandled unit conversion from #{from} to #{to} for #{fuel_type}."
    elsif from == 'gal' and to == 'btu'
      if fuel_type == Constants.FuelTypePropane
        return x * 91600.0
      elsif fuel_type == Constants.FuelTypeOil
        return x * 139000.0
      end

      fail "Unhandled unit conversion from #{from} to #{to} for #{fuel_type}."
    elsif from == 'j' and to == 'gal'
      if fuel_type == Constants.FuelTypePropane
        return x * 3412.141633127942 / 1000.0 / 3600.0 / 91600.0
      elsif fuel_type == Constants.FuelTypeOil
        return x * 3412.141633127942 / 1000.0 / 3600.0 / 139000.0
      end

      fail "Unhandled unit conversion from #{from} to #{to} for #{fuel_type}."

    # Power
    elsif from == 'btu/hr' and to == 'ton'
      return x / 12000.0
    elsif from == 'btu/hr' and to == 'w'
      return x * 0.2930710701722222
    elsif from == 'kbtu/hr' and to == 'btu/hr'
      return x * 1000.0
    elsif from == 'btu/hr' and to == 'kbtu/hr'
      return x / 1000.0
    elsif from == 'kbtu/hr' and to == 'w'
      return x * 293.0710701722222
    elsif from == 'kw' and to == 'w'
      return x * 1000.0
    elsif from == 'ton' and to == 'btu/hr'
      return x * 12000.0
    elsif from == 'ton' and to == 'kbtu/hr'
      return x * 12.0
    elsif from == 'ton' and to == 'w'
      return x * 3516.85284207
    elsif from == 'w' and to == 'btu/hr'
      return x * 3.412141633127942
    elsif from == 'w' and to == 'kbtu/hr'
      return x / 293.0710701722222
    elsif from == 'w' and to == 'kw'
      return x / 1000.0
    elsif from == 'w' and to == 'ton'
      return x / 3516.85284207
    elsif from == 'kw' and to == 'kbtu/hr'
      return x / 0.2930710701722222
    elsif from == 'kbtu/hr' and to == 'kw'
      return x * 0.2930710701722222

    # Power Flux
    elsif from == 'w/m^2' and to == 'btu/(hr*ft^2)'
      return x * 0.3169983306281505

    # Temperature
    elsif from == 'c' and to == 'f'
      return 1.8 * x + 32.0
    elsif from == 'c' and to == 'k'
      return x + 273.15
    elsif from == 'f' and to == 'c'
      return (x - 32.0) / 1.8
    elsif from == 'f' and to == 'r'
      return x + 459.67
    elsif from == 'k' and to == 'c'
      return x - 273.15
    elsif from == 'k' and to == 'r'
      return x * 1.8
    elsif from == 'r' and to == 'f'
      return x - 459.67
    elsif from == 'r' and to == 'k'
      return x / 1.8

    # Specific Heat
    elsif from == 'btu/(lbm*r)' and to == 'j/(kg*k)' # by mass
      return x * 4187.0
    elsif from == 'btu/(ft^3*f)' and to == 'j/(m^3*k)' # by volume
      return x * 67100.0
    elsif from == 'btu/(lbm*r)' and to == 'wh/(kg*k)'
      return x * 1.1632

    # Length
    elsif from == 'ft' and to == 'in'
      return x * 12.0
    elsif from == 'ft' and to == 'm'
      return x * 0.3048
    elsif from == 'in' and to == 'ft'
      return x / 12.0
    elsif from == 'in' and to == 'm'
      return x * 0.0254
    elsif from == 'm' and to == 'ft'
      return x / 0.3048
    elsif from == 'm' and to == 'in'
      return x / 0.0254
    elsif from == 'mm' and to == 'm'
      return x / 1000.0

    # Area
    elsif from == 'cm^2' and to == 'ft^2'
      return x / 929.0304
    elsif from == 'ft^2' and to == 'cm^2'
      return x * 929.0304
    elsif from == 'ft^2' and to == 'in^2'
      return x * 144.0
    elsif from == 'ft^2' and to == 'm^2'
      return x * 0.09290304
    elsif from == 'm^2' and to == 'ft^2'
      return x / 0.09290304

    # Volume
    elsif from == 'ft^3' and to == 'gal'
      return x * 7.480519480579059
    elsif from == 'ft^3' and to == 'l'
      return x * 28.316846591999997
    elsif from == 'ft^3' and to == 'm^3'
      return x * 0.028316846592000004
    elsif from == 'gal' and to == 'ft^3'
      return x / 7.480519480579059
    elsif from == 'gal' and to == 'in^3'
      return x * 231.0
    elsif from == 'gal' and to == 'm^3'
      return x * 0.0037854117839698515
    elsif from == 'in^3' and to == 'gal'
      return x / 231.0
    elsif from == 'l' and to == 'pint'
      return x * 2.1133764
    elsif from == 'l' and to == 'ft^3'
      return x / 28.316846591999997
    elsif from == 'm^3' and to == 'ft^3'
      return x / 0.028316846592000004
    elsif from == 'm^3' and to == 'gal'
      return x / 0.0037854117839698515
    elsif from == 'pint' and to == 'l'
      return x * 0.47317647

    # Mass
    elsif from == 'lbm' and to == 'kg'
      return x * 0.45359237
    elsif from == 'kg' and to == 'lbm'
      return x / 0.45359237

    # Volume Flow Rate
    elsif from == 'cfm' and to == 'm^3/s'
      return x / 2118.880003289315
    elsif from == 'ft^3/min' and to == 'm^3/s'
      return x / 2118.880003289315
    elsif from == 'gal/min' and to == 'm^3/s'
      return x / 15850.323141615143
    elsif from == 'm^3/s' and to == 'gal/min'
      return x * 15850.323141615143
    elsif from == 'm^3/s' and to == 'cfm'
      return x * 2118.880003289315
    elsif from == 'm^3/s' and to == 'ft^3/min'
      return x * 2118.880003289315

    # Mass Flow Rate
    elsif from == 'lbm/min' and to == 'kg/hr'
      return x * 27.2155422
    elsif from == 'lbm/min' and to == 'kg/s'
      return x * 27.2155422 / 3600.0

    # Time
    elsif from == 'day' and to == 'hr'
      return x * 24.0
    elsif from == 'day' and to == 'yr'
      return x / 365.0
    elsif from == 'hr' and to == 'min'
      return x * 60.0
    elsif from == 'hr' and to == 's'
      return x * 3600.0
    elsif from == 'hr' and to == 'yr'
      return x / 8760.0
    elsif from == 'min' and to == 'hr'
      return x / 60.0
    elsif from == 'min' and to == 's'
      return x * 60.0
    elsif from == 'yr' and to == 'day'
      return x * 365.0
    elsif from == 'yr' and to == 'hr'
      return x * 8760.0

    # Velocity
    elsif from == 'knots' and to == 'm/s'
      return x * 0.51444444
    elsif from == 'mph' and to == 'm/s'
      return x * 0.44704
    elsif from == 'm/s' and to == 'knots'
      return x * 1.9438445
    elsif from == 'm/s' and to == 'mph'
      return x * 2.2369363

    # Pressure & Density
    elsif from == 'atm' and to == 'btu/ft^3'
      return x * 2.719
    elsif from == 'atm' and to == 'kpa'
      return x * 101.325
    elsif from == 'atm' and to == 'psi'
      return x * 14.692
    elsif from == 'inh2o' and to == 'pa'
      return x * 249.1
    elsif from == 'kg/m^3' and to == 'lbm/ft^3'
      return x / 16.02
    elsif from == 'kpa' and to == 'psi'
      return x / 6.89475729
    elsif from == 'lbm/(ft*s^2)' and to == 'inh2o'
      return x * 0.005974
    elsif from == 'lbm/ft^3' and to == 'inh2o/mph^2'
      return x * 0.01285
    elsif from == 'lbm/ft^3' and to == 'kg/m^3'
      return x * 16.02
    elsif from == 'psi' and to == 'btu/ft^3'
      return x * 0.185
    elsif from == 'psi' and to == 'kpa'
      return x * 6.89475729
    elsif from == 'psi' and to == 'pa'
      return x * 6.89475729 * 1000.0
    elsif from == 'pa' and to == 'psi'
      return x / 6895.0

    # Angles
    elsif from == 'deg' and to == 'rad'
      return x / 57.29578
    elsif from == 'rad' and to == 'deg'
      return x * 57.29578

    # R-Value
    elsif from == 'hr*ft^2*f/btu' and to == 'm^2*k/w'
      return x * 0.1761
    elsif from == 'm^2*k/w' and to == 'hr*ft^2*f/btu'
      return x / 0.1761

    # U-Factor
    elsif from == 'btu/(hr*ft^2*f)' and to == 'w/(m^2*k)'
      return x * 5.678
    elsif from == 'w/(m^2*k)' and to == 'btu/(hr*ft^2*f)'
      return x / 5.678

    # UA
    elsif from == 'btu/(hr*f)' and to == 'w/k'
      return x * 0.5275
    elsif from == 'w/k' and to == 'btu/(hr*f)'
      return x / 0.5275

    # Thermal Conductivity
    elsif from == 'w/(m*k)' and to == 'btu/(hr*ft*r)'
      return x / 1.731
    elsif from == 'btu/(hr*ft*r)' and to == 'w/(m*k)'
      return x * 1.731
    elsif from == 'btu*in/(hr*ft^2*r)' and to == 'w/(m*k)'
      return x * 0.14425

    # Infiltration
    elsif from == 'ft^2/(s^2*r)' and to == 'l^2/(s^2*cm^4*k)'
      return x * 0.001672
    elsif from == 'inh2o/mph^2' and to == 'pa*s^2/m^2'
      return x * 1246.0
    elsif from == 'inh2o/r' and to == 'pa/k'
      return x * 448.4

    # Humidity
    elsif from == 'lbm/lbm' and to == 'grains'
      return x * 7000.0
    end

    fail "Unhandled unit conversion from #{from} to #{to}."
  end

  def self.get_scalar_unit_conversion(var_name, old_units, fuel_type)
    if old_units == "m3"
      old_units = "m^3"
    end

    new_units = nil
    if ["J", "m^3", "m3"].include? old_units
      if var_name.downcase.include? "electricity"
        new_units = "kWh"
      elsif var_name.downcase.include? "gas"
        new_units = "therm"
      else
        new_units = "gal"
      end
      return new_units, self.convert(1.0, old_units, new_units, fuel_type)
    else
      return nil, nil
    end
  end
end
