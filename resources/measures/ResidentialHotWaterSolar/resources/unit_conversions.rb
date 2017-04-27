class UnitConversion

	# Contains unit conversions not available in OpenStudio.convert.
	
	# See http://nrel.github.io/OpenStudio-user-documentation/reference/measure_code_examples/
	# for available OS unit conversions. Note that this list may not be complete, so try out
	# new unit conversions before adding them here.

	def self.knots2m_s(knots)
		# knots -> m/s
		return 0.51444444*knots
	end
  
	def self.atm2Btu_ft3(atm)
		# atm -> Btu/ft^3
		return 2.719*atm
	end
	
    def self.atm2kPa(x)
        # atm -> kPa
        return x*101.325
    end
	
    def self.atm2psi(x)
        # atm -> psi
        return x*14.692
    end

	def self.lbm_ft32inH2O_mph2(lbm_ft3)
	    # lbm/ft^3 -> inH2O/mph^2
		return 0.01285*lbm_ft3
	end
	
	def self.lbm_fts22inH2O(lbm_fts2)
	    # lbm/(ft-s^2) -> inH2O
		return 0.005974*lbm_fts2
	end
	
	def self.lbm_ft32kg_m3(lbm_ft3)
		# lbm/ft^3 -> kg/m^3
		return 16.02*lbm_ft3
	end
	
	def self.inH2O2Pa(inH2O)
		# inH2O -> Pa
		return 249.1*inH2O
	end
    
  def self.ft32gal(ft3)
      # ft^3 -> gal
      return 7.4805195*ft3
  end
  
  def self.lbm_min2kg_hr(lbm_min)
      # lbm/min -> kg/hr
      return 27.215542*lbm_min
  end
  
  def self.lbm_min2kg_s(lbm_min)
      # lbm/min -> kg/s
      return self.lbm_min2kg_hr(lbm_min) / 3600.0
  end
  
  def self.btu2gal(btu, fueltype)
      # Btu -> gal
      if fueltype == Constants.FuelTypePropane
          return btu/91600.0
      elsif fueltype == Constants.FuelTypeOil
          return btu/139000.0
      end
      return nil
  end
  
  # Stack Coefficient
  def self.inH2O_R2Pa_K(nH2O_R)
    # inH2O/R -> Pa/K
    return 448.4*nH2O_R
  end
  
  def self.ft2_s2R2L2_s2cm4K(ft2_s2R)
    # ft^2/(s^2-R) -> L^2/(s^2-cm^4-K)
    return 0.001672*ft2_s2R
  end
  
  # Wind Coefficient
  def self.inH2O_mph2Pas2_m2(inH2O_mph)
    # inH2O/mph^2 -> Pa-s^2/m^2
    return 1246.0*inH2O_mph
  end
  
  def self._2L2s2_s2cm4m2(x)
    # I don't know what this means. I just copied it directly out of Global.bmi
    return 0.01*x
  end
  
  def self.pint2liter(pints)
    # pints -> liters
    return 0.47317647*pints
  end
  
  def self.liter2pint(liters)
    # liters -> pints
    return 2.1133764*liters
  end

  # Humidity ratio
  def self.lbm_lbm2grains(lbm_lbm)
    # lbm/lbm -> grains
    return lbm_lbm * 7000.0
  end
    
end
