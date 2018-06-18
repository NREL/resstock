require "#{File.dirname(__FILE__)}/constants"
require "#{File.dirname(__FILE__)}/unit_conversions"

class Material

    # thick_in - Thickness [in]
    # mat_base - Material object that defines k, rho, and cp. Can be overridden with values for those arguments.
    # k_in - Conductivity [Btu-in/h-ft^2-F]
    # rho - Density [lb/ft^3]
    # cp - Specific heat [Btu/lb*F]
    # rvalue - R-value [h-ft^2-F/Btu]
    def initialize(name=nil, thick_in=nil, mat_base=nil, k_in=nil, rho=nil, cp=nil, tAbs=nil, sAbs=nil, vAbs=nil, rvalue=nil)
        @name = name
        
        if not thick_in.nil?
            @thick_in = thick_in # in
            @thick = UnitConversions.convert(thick_in,"in","ft") # ft
        end
        
        if not mat_base.nil?
            @k_in = mat_base.k_in # Btu-in/h-ft^2-F
            if not mat_base.k_in.nil?
                @k = UnitConversions.convert(mat_base.k_in,"in","ft") # Btu/h-ft-F
            else
                @k = nil
            end
            @rho = mat_base.rho
            @cp = mat_base.cp
        else
            @k_in = nil
            @k = nil
            @rho = nil
            @cp = nil
        end
        
        # Override the base material if both are included
        if not k_in.nil?
            @k_in = k_in # Btu-in/h-ft^2-F
            @k = UnitConversions.convert(k_in,"in","ft") # Btu/h-ft-F
        end
        if not rho.nil?
            @rho = rho # lb/ft^3
        end
        if not cp.nil?
            @cp = cp # Btu/lb*F
        end

        @tAbs = tAbs
        @sAbs = sAbs
        @vAbs = vAbs
        
        # Calculate R-value
        if not rvalue.nil?
            @rvalue = rvalue # h-ft^2-F/Btu
        elsif not @thick_in.nil? and not @k_in.nil?
            if @k_in > 0
                @rvalue = @thick_in / @k_in # h-ft^2-F/Btu
            else
                @rvalue = @thick_in / 10000000.0 # h-ft^2-F/Btu
            end
        end
    end
    
    attr_accessor :name, :thick, :thick_in, :k, :k_in, :rho, :cp, :rvalue, :tAbs, :sAbs, :vAbs
    
    def self.AirCavityClosed(thick_in)
        rvalue = Gas.AirGapRvalue
        return self.new(name=nil, thick_in=thick_in, mat_base=nil, k_in=thick_in/rvalue, rho=Gas.Air.rho, cp=Gas.Air.cp)
    end
    
    def self.AirCavityOpen(thick_in)
        return self.new(name=nil, thick_in=thick_in, mat_base=nil, k_in=10000000.0, rho=Gas.Air.rho, cp=Gas.Air.cp)
    end
    
    def self.AirFilmOutside
        rvalue = 0.197 # hr-ft-F/Btu
        return self.new(name=Constants.AirFilm, thick_in=1.0, mat_base=nil, k_in=1.0/rvalue)
    end

    def self.AirFilmVertical
        rvalue = 0.68 # hr-ft-F/Btu (ASHRAE 2005, F25.2, Table 1)
        return self.new(name=Constants.AirFilm, thick_in=1.0, mat_base=nil, k_in=1.0/rvalue)
    end

    def self.AirFilmFlatEnhanced
        rvalue = 0.61 # hr-ft-F/Btu (ASHRAE 2005, F25.2, Table 1)
        return self.new(name=Constants.AirFilm, thick_in=1.0, mat_base=nil, k_in=1.0/rvalue)
    end

    def self.AirFilmFlatReduced
        rvalue = 0.92 # hr-ft-F/Btu (ASHRAE 2005, F25.2, Table 1)
        return self.new(name=Constants.AirFilm, thick_in=1.0, mat_base=nil, k_in=1.0/rvalue)
    end

    def self.AirFilmFloorAverage
        # For floors between conditioned spaces where heat does not flow across
        # the floor; heat transfer is only important with regards to the thermal
        rvalue = (self.AirFilmFlatReduced.rvalue + self.AirFilmFlatEnhanced.rvalue) / 2.0 # hr-ft-F/Btu
        return self.new(name=Constants.AirFilm, thick_in=1.0, mat_base=nil, k_in=1.0/rvalue)
    end

    def self.AirFilmFloorReduced
        # For floors above unconditioned basement spaces, where heat will
        # always flow down through the floor.
        rvalue = self.AirFilmFlatReduced.rvalue # hr-ft-F/Btu
        return self.new(name=Constants.AirFilm, thick_in=1.0, mat_base=nil, k_in=1.0/rvalue)
    end

    def self.AirFilmSlopeEnhanced(roof_pitch)
        # Correlation functions used to interpolate between values provided
        # in ASHRAE 2005, F25.2, Table 1 - which only provides values for
        # 0, 45, and 90 degrees. Values are for non-reflective materials of 
        # emissivity = 0.90.
        rvalue = 0.002 * Math::exp(0.0398 * roof_pitch) + 0.608 # hr-ft-F/Btu (evaluates to film_flat_enhanced at 0 degrees, 0.62 at 45 degrees, and film_vertical at 90 degrees)
        return self.new(name=Constants.AirFilm, thick_in=1.0, mat_base=nil, k_in=1.0/rvalue)
    end

    def self.AirFilmSlopeReduced(roof_pitch)
        # Correlation functions used to interpolate between values provided
        # in ASHRAE 2005, F25.2, Table 1 - which only provides values for
        # 0, 45, and 90 degrees. Values are for non-reflective materials of 
        # emissivity = 0.90.
        rvalue = 0.32 * Math::exp(-0.0154 * roof_pitch) + 0.6 # hr-ft-F/Btu (evaluates to film_flat_reduced at 0 degrees, 0.76 at 45 degrees, and film_vertical at 90 degrees)
        return self.new(name=Constants.AirFilm, thick_in=1.0, mat_base=nil, k_in=1.0/rvalue)
    end

    def self.AirFilmSlopeEnhancedReflective(roof_pitch)
        # Correlation functions used to interpolate between values provided
        # in ASHRAE 2005, F25.2, Table 1 - which only provides values for
        # 0, 45, and 90 degrees. Values are for reflective materials of 
        # emissivity = 0.05.
        rvalue = 0.00893 * Math::exp(0.0419 * roof_pitch) + 1.311 # hr-ft-F/Btu (evaluates to 1.32 at 0 degrees, 1.37 at 45 degrees, and 1.70 at 90 degrees)
        return self.new(name=Constants.AirFilm, thick_in=1.0, mat_base=nil, k_in=1.0/rvalue)
    end

    def self.AirFilmSlopeReducedReflective(roof_pitch)
        # Correlation functions used to interpolate between values provided
        # in ASHRAE 2005, F25.2, Table 1 - which only provides values for
        # 0, 45, and 90 degrees. Values are for reflective materials of 
        # emissivity = 0.05.
        rvalue = 2.999 * Math::exp(-0.0333 * roof_pitch) + 1.551 # hr-ft-F/Btu (evaluates to 4.55 at 0 degrees, 2.22 at 45 degrees, and 1.70 at 90 degrees)
        return self.new(name=Constants.AirFilm, thick_in=1.0, mat_base=nil, k_in=1.0/rvalue)
    end

    def self.AirFilmRoof(roof_pitch)
        # Use weighted average between enhanced and reduced convection based on degree days.
        #hdd_frac = hdd65f / (hdd65f + cdd65f)
        #cdd_frac = cdd65f / (hdd65f + cdd65f)
        #return self.AirFilmSlopeEnhanced(roof_pitch).rvalue * hdd_frac + self.AirFilmSlopeReduced(roof_pitch).rvalue * cdd_frac # hr-ft-F/Btu
        # Simplification to not depend on weather
        rvalue = (self.AirFilmSlopeEnhanced(roof_pitch).rvalue + self.AirFilmSlopeReduced(roof_pitch).rvalue) / 2.0 # hr-ft-F/Btu
        return self.new(name=Constants.AirFilm, thick_in=1.0, mat_base=nil, k_in=1.0/rvalue)
    end

    def self.AirFilmRoofRadiantBarrier(roof_pitch)
        # Use weighted average between enhanced and reduced convection based on degree days.
        #hdd_frac = hdd65f / (hdd65f + cdd65f)
        #cdd_frac = cdd65f / (hdd65f + cdd65f)
        #return self.AirFilmSlopeEnhancedReflective(roof_pitch).rvalue * hdd_frac + self.AirFilmSlopeReducedReflective(roof_pitch).rvalue * cdd_frac # hr-ft-F/Btu
        # Simplification to not depend on weather
        rvalue = (self.AirFilmSlopeEnhancedReflective(roof_pitch).rvalue + self.AirFilmSlopeReducedReflective(roof_pitch).rvalue) / 2.0 # hr-ft-F/Btu
        return self.new(name=Constants.AirFilm, thick_in=1.0, mat_base=nil, k_in=1.0/rvalue)
    end

    def self.CoveringBare(floorFraction=0.8, rvalue=2.08)
        # Combined layer of, e.g., carpet and bare floor
        thickness = 0.5 # in
        return self.new(name="Floor Covering", thick_in=thickness, mat_base=nil, k_in=thickness / (rvalue * floorFraction), rho=3.4, cp=0.32, tAbs=0.9, sAbs=0.9)
    end

    def self.Concrete(thick_in)
        return self.new(name="Concrete #{thick_in} in.", thick_in=thick_in, mat_base=BaseMaterial.Concrete, k_in=nil, rho=nil, cp=nil, tAbs=0.9)
    end

    def self.ExtFinishStuccoMedDark
        return self.new(name="Stucco, Medium/Dark", thick_in=1.0, mat_base=nil, k_in=4.5, rho=80.0, cp=0.21, tAbs=0.9, sAbs=0.75, vAbs=0.75)
    end

    def self.ExtFinishBrickLight
        return self.new(name="Brick, Light", thick_in=4.0, mat_base=nil, k_in=5.5, rho=110.0, cp=0.19, tAbs=0.93, sAbs=0.55, vAbs=0.55)
    end

    def self.ExtFinishBrickMedDark
        return self.new(name="Brick, Medium/Dark", thick_in=4.0, mat_base=nil, k_in=5.5, rho=110.0, cp=0.19, tAbs=0.96, sAbs=0.88, vAbs=0.88)
    end

    def self.ExtFinishWoodLight
        return self.new(name="Wood, Light", thick_in=1.0, mat_base=nil, k_in=0.71, rho=34.0, cp=0.28, tAbs=0.82, sAbs=0.3, vAbs=0.3)
    end

    def self.ExtFinishWoodMedDark
        return self.new(name="Wood, Medium/Dark", thick_in=1.0, mat_base=nil, k_in=0.71, rho=34.0, cp=0.28, tAbs=0.92, sAbs=0.75, vAbs=0.75)
    end
    
    def self.ExtFinishAluminumLight
        return self.new(name="Aluminum, Light", thick_in=0.375, mat_base=nil, k_in=0.61, rho=10.9, cp=0.29, tAbs=0.9, sAbs=0.3, vAbs=0.3)
    end

    def self.ExtFinishAluminumMedDark
        return self.new(name="Aluminum, Medium/Dark", thick_in=0.375, mat_base=nil, k_in=0.61, rho=10.9, cp=0.29, tAbs=0.94, sAbs=0.75, vAbs=0.75)
    end

    def self.ExtFinishVinylLight
        return self.new(name="Vinyl, Light", thick_in=0.375, mat_base=nil, k_in=0.62, rho=11.1, cp=0.25, tAbs=0.9, sAbs=0.3, vAbs=0.3)
    end
    
    def self.ExtFinishVinylMedDark
        return self.new(name="Vinyl, Medium/Dark", thick_in=0.375, mat_base=nil, k_in=0.62, rho=11.1, cp=0.25, tAbs=0.9, sAbs=0.75, vAbs=0.75)
    end
    
    def self.ExtFinishFiberCementLight
        return self.new(name="Fiber-Cement, Light", thick_in=0.375, mat_base=nil, k_in=1.79, rho=21.7, cp=0.24, tAbs=0.9, sAbs=0.3, vAbs=0.3)
    end
    
    def self.ExtFinishFiberCementMedDark
        return self.new(name="Fiber-Cement, Medium/Dark", thick_in=0.375, mat_base=nil, k_in=1.79, rho=21.7, cp=0.24, tAbs=0.9, sAbs=0.75, vAbs=0.75)
    end
    
    def self.FloorWood
        return Material.new(name="Wood Floor", thick_in=0.625, mat_base=nil, k_in=0.8004, rho=34.0, cp=0.29)
    end
    
    def self.GypsumWall(thick_in)
        return self.new(name="Drywall #{thick_in.to_s} in.", thick_in=thick_in, mat_base=BaseMaterial.Gypsum, k_in=nil, rho=nil, cp=nil, tAbs=0.9, sAbs=0.5, vAbs=0.1)
    end

    def self.GypsumCeiling(thick_in)
        return self.new(name="Drywall #{thick_in.to_s} in.", thick_in=thick_in, mat_base=BaseMaterial.Gypsum, k_in=nil, rho=nil, cp=nil, tAbs=0.9, sAbs=0.3, vAbs=0.1)
    end
    
    def self.RoofingAsphaltShinglesDark
        return self.RoofMaterial("Asphalt Shingles, Dark", 0.91, 0.92)
    end
    
    def self.RoofingAsphaltShinglesMed
        return self.RoofMaterial("Asphalt Shingles, Medium", 0.91, 0.85)
    end
    
    def self.RoofingAsphaltShinglesLight
        return self.RoofMaterial("Asphalt Shingles, Light", 0.91, 0.8)
    end
    
    def self.RoofingAsphaltShinglesWhiteCool
        return self.RoofMaterial("Asphalt Shingles, White or Cool Colors", 0.91, 0.75)
    end
    
    def self.RoofingTileDark
        return self.RoofMaterial("Tile, Dark", 0.94, 0.9)
    end

    def self.RoofingTileMed
        return self.RoofMaterial("Tile, Medium", 0.94, 0.75)
    end

    def self.RoofingTileLight
        return self.RoofMaterial("Tile, Light", 0.93, 0.6)
    end

    def self.RoofingTileWhite
        return self.RoofMaterial("Tile, White", 0.93, 0.3)
    end

    def self.RoofingMetalDark
        return self.RoofMaterial("Metal, Dark", 0.9, 0.9)
    end

    def self.RoofingMetalMed
        return self.RoofMaterial("Metal, Medium", 0.9, 0.75)
    end

    def self.RoofingMetalLight
        return self.RoofMaterial("Metal, Light", 0.88, 0.6)
    end

    def self.RoofingMetalWhite
        return self.RoofMaterial("Metal, White", 0.88, 0.3)
    end
    
    def self.RoofingGalvanizedSteel
        return self.RoofMaterial("Galvanized Steel", 0.88, 0.7)
    end

    def self.Soil(thick_in)
        return self.new(name="Soil #{thick_in} in.", thick_in=thick_in, mat_base=BaseMaterial.Soil)
    end

    def self.Stud2x(thick_in)
        return self.new(name="Stud 2x#{thick_in.to_s}", thick_in=thick_in, mat_base=BaseMaterial.Wood)
    end
    
    def self.Stud2x4
        return self.new(name="Stud 2x4", thick_in=3.5, mat_base=BaseMaterial.Wood)
    end

    def self.Stud2x6
        return self.new(name="Stud 2x6", thick_in=5.5, mat_base=BaseMaterial.Wood)
    end

    def self.Plywood(thick_in)
        return self.new(name="Plywood #{thick_in.to_s} in.", thick_in=thick_in, mat_base=BaseMaterial.Wood)
    end

    def self.RadiantBarrier
        return self.new(name="Radiant Barrier", thick_in=0.0084, mat_base=nil, k_in=1629.6, rho=168.6, cp=0.22, tAbs=0.05, sAbs=0.05, vAbs=0.05)
    end
    
    def self.RoofMaterial(name, emissivity, absorptivity)
        return self.new(name=name, thick_in=0.375, mat_base=nil, k_in=1.128, rho=70, cp=0.35, tAbs=emissivity, sAbs=absorptivity, vAbs=absorptivity)
    end

end

class BaseMaterial

    def initialize(rho, cp, k_in)
        @rho = rho
        @cp = cp
        @k_in = k_in
    end
    
    attr_accessor :rho, :cp, :k_in

    def self.Gypsum
        return self.new(rho=50.0, cp=0.2, k_in=1.1112)
    end

    def self.Wood
        return self.new(rho=32.0, cp=0.29, k_in=0.8004)
    end
    
    def self.Concrete
        return self.new(rho=140.0, cp=0.2, k_in=9.0912)
    end

    def self.Gypcrete
        # http://www.maxxon.com/gyp-crete/data
        return self.new(rho=100.0, cp=0.223, k_in=4.7424)
    end

    def self.InsulationRigid
        return self.new(rho=2.0, cp=0.29, k_in=0.204)
    end
    
    def self.InsulationCelluloseDensepack
        return self.new(rho=3.5, cp=0.25, k=nil)
    end

    def self.InsulationCelluloseLoosefill
        return self.new(rho=1.5, cp=0.25, k=nil)
    end

    def self.InsulationFiberglassDensepack
        return self.new(rho=2.2, cp=0.25, k=nil)
    end

    def self.InsulationFiberglassLoosefill
        return self.new(rho=0.5, cp=0.25, k=nil)
    end

    def self.InsulationGenericDensepack
        return self.new(rho=(self.InsulationFiberglassDensepack.rho + self.InsulationCelluloseDensepack.rho) / 2.0, cp=0.25, k=nil)
    end

    def self.InsulationGenericLoosefill
        return self.new(rho=(self.InsulationFiberglassLoosefill.rho + self.InsulationCelluloseLoosefill.rho) / 2.0, cp=0.25, k=nil)
    end

    def self.Soil
        return self.new(rho=115.0, cp=0.1, k_in=12.0)
    end

end

class SimpleMaterial

    def initialize(name=nil, rvalue=nil)
        @name = name
        @rvalue = rvalue
    end
    
    attr_accessor :name, :rvalue

    def self.Adiabatic
        return self.new(name="Adiabatic", rvalue=1000)
    end

end

class GlazingMaterial

    def initialize(name=nil, ufactor=nil, shgc=nil)
        @name = name
        @ufactor = ufactor
        @shgc = shgc
    end
    
    attr_accessor :name, :ufactor, :shgc
end

class Liquid

    def initialize(rho, cp, k, mu, h_fg, t_frz, t_boil, t_crit)
        @rho    = rho       # Density (lb/ft3)
        @cp     = cp        # Specific Heat (Btu/lbm-R)
        @k      = k         # Thermal Conductivity (Btu/h-ft-R)
        @mu     = mu        # Dynamic Viscosity (lbm/ft-h)
        @h_fg   = h_fg      # Latent Heat of Vaporization (Btu/lbm)
        @t_frz  = t_frz     # Freezing Temperature (degF)
        @t_boil = t_boil    # Boiling Temperature (degF)
        @t_crit = t_crit    # Critical Temperature (degF)
    end
    
    attr_accessor :rho, :cp, :k, :mu, :h_fg, :t_frz, :t_boil, :t_crit

    def self.H2O_l
        # From EES at STP
        return self.new(62.32,0.9991,0.3386,2.424,1055,32.0,212.0,nil)
    end

    def self.R22_l
        # Converted from EnthDR22 f77 in ResAC (Brandemuehl)
        return self.new(nil,0.2732,nil,nil,100.5,nil,-41.35,204.9)
    end
  
end

class Gas

    def initialize(rho, cp, k, mu, m)
        @rho    = rho           # Density (lb/ft3)
        @cp     = cp            # Specific Heat (Btu/lbm-R)
        @k      = k             # Thermal Conductivity (Btu/h-ft-R)
        @mu     = mu            # Dynamic Viscosity (lbm/ft-h)
        @m      = m             # Molecular Weight (lbm/lbmol)
        if @m
            gas_constant = 1.9858 # Gas Constant (Btu/lbmol-R)
            @r  = gas_constant / m # Gas Constant (Btu/lbm-R)
        else
            @r = nil
        end
    end
    
    attr_accessor :rho, :cp, :k, :mu, :m, :r
  
    def self.Air
        # From EES at STP
        return self.new(0.07518,0.2399,0.01452,0.04415,28.97)
    end
    
    def self.AirGapRvalue
        return 1.0 # hr*ft*F/Btu (Assume for all air gap configurations since there is no correction for direction of heat flow in the simulation tools)
    end

    def self.H2O_v
        # From EES at STP
        return self.new(nil,0.4495,nil,nil,18.02)
    end
    
    def self.R22_v
        # Converted from EnthDR22 f77 in ResAC (Brandemuehl)
        return self.new(nil,0.1697,nil,nil,nil)
    end

    def self.PsychMassRat
        return self.H2O_v.m / self.Air.m
    end
end

class AirFilms

    def self.OutsideR
        return 0.197 # hr-ft-F/Btu
    end
  
    def self.VerticalR
        return 0.68 # hr-ft-F/Btu (ASHRAE 2005, F25.2, Table 1)
    end
  
    def self.FlatEnhancedR
        return 0.61 # hr-ft-F/Btu (ASHRAE 2005, F25.2, Table 1)
    end
  
    def self.FlatReducedR
        return 0.92 # hr-ft-F/Btu (ASHRAE 2005, F25.2, Table 1)
    end
  
    def self.FloorAverageR
        # For floors between conditioned spaces where heat does not flow across
        # the floor; heat transfer is only important with regards to the thermal
        return (self.FlatReducedR + self.FlatEnhancedR) / 2.0 # hr-ft-F/Btu
    end

    def self.FloorReducedR
        # For floors above unconditioned basement spaces, where heat will
        # always flow down through the floor.
        return self.FlatReducedR # hr-ft-F/Btu
    end
  
    def self.SlopeEnhancedR(roof_pitch)
        # Correlation functions used to interpolate between values provided
        # in ASHRAE 2005, F25.2, Table 1 - which only provides values for
        # 0, 45, and 90 degrees. Values are for non-reflective materials of 
        # emissivity = 0.90.
        return 0.002 * Math::exp(0.0398 * roof_pitch) + 0.608 # hr-ft-F/Btu (evaluates to film_flat_enhanced at 0 degrees, 0.62 at 45 degrees, and film_vertical at 90 degrees)
    end
  
    def self.SlopeReducedR(roof_pitch)
        # Correlation functions used to interpolate between values provided
        # in ASHRAE 2005, F25.2, Table 1 - which only provides values for
        # 0, 45, and 90 degrees. Values are for non-reflective materials of 
        # emissivity = 0.90.
        return 0.32 * Math::exp(-0.0154 * roof_pitch) + 0.6 # hr-ft-F/Btu (evaluates to film_flat_reduced at 0 degrees, 0.76 at 45 degrees, and film_vertical at 90 degrees)
    end
  
    def self.SlopeEnhancedReflectiveR(roof_pitch)
        # Correlation functions used to interpolate between values provided
        # in ASHRAE 2005, F25.2, Table 1 - which only provides values for
        # 0, 45, and 90 degrees. Values are for reflective materials of 
        # emissivity = 0.05.
        return 0.00893 * Math::exp(0.0419 * roof_pitch) + 1.311 # hr-ft-F/Btu (evaluates to 1.32 at 0 degrees, 1.37 at 45 degrees, and 1.70 at 90 degrees)
    end
  
    def self.SlopeReducedReflectiveR(roof_pitch)
        # Correlation functions used to interpolate between values provided
        # in ASHRAE 2005, F25.2, Table 1 - which only provides values for
        # 0, 45, and 90 degrees. Values are for reflective materials of 
        # emissivity = 0.05.
        return 2.999 * Math::exp(-0.0333 * roof_pitch) + 1.551 # hr-ft-F/Btu (evaluates to 4.55 at 0 degrees, 2.22 at 45 degrees, and 1.70 at 90 degrees)
    end
  
    def self.RoofR(roof_pitch)
        # Use weighted average between enhanced and reduced convection based on degree days.
        #hdd_frac = hdd65f / (hdd65f + cdd65f)
        #cdd_frac = cdd65f / (hdd65f + cdd65f)
        #return self.SlopeEnhancedR(roof_pitch) * hdd_frac + self.SlopeReducedR(roof_pitch) * cdd_frac # hr-ft-F/Btu
        # Simplification to not depend on weather
        return (self.SlopeEnhancedR(roof_pitch) + self.SlopeReducedR(roof_pitch)) / 2.0 # hr-ft-F/Btu
    end
  
    def self.RoofRadiantBarrierR(roof_pitch)
        # Use weighted average between enhanced and reduced convection based on degree days.
        #hdd_frac = hdd65f / (hdd65f + cdd65f)
        #cdd_frac = cdd65f / (hdd65f + cdd65f)
        #return self.SlopeEnhancedReflectiveR(roof_pitch) * hdd_frac + self.SlopeReducedReflectiveR(roof_pitch) * cdd_frac # hr-ft-F/Btu
        # Simplification to not depend on weather
        return (self.SlopeEnhancedReflectiveR(roof_pitch) + self.SlopeReducedReflectiveR(roof_pitch)) / 2.0 # hr-ft-F/Btu
    end
    
end
