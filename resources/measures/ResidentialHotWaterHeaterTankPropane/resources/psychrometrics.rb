require "#{File.dirname(__FILE__)}/constants"
require "#{File.dirname(__FILE__)}/unit_conversions"
require "#{File.dirname(__FILE__)}/util"

class Psychrometrics
  def self.rhoD_fT_w_P(tdb, w, p)
        '''
        Description:
        ------------
            Calculate the density of dry air at a given drybulb temperature,
            humidity ratio and pressure.

        Source:
        -------
            2009 ASHRAE Handbook

        Inputs:
        -------
            Tdb     float      drybulb temperature   (degF)
            w       float      humidity ratio        (lbm/lbm)
            P       float      pressure              (psia)

        Outputs:
        --------
            rhoD    float      density of dry air    (lbm/ft3)
        '''
    pair = Gas.PsychMassRat * p / (Gas.PsychMassRat + w) # (psia)
    rhoD = OpenStudio::convert(pair,"psi","Btu/ft^3").get / Gas.Air.r / (OpenStudio::convert(tdb,"F","R").get) # (lbm/ft3)

    return rhoD

  end

  def self.h_fT_w_SI(tdb, w)
        '''
        Description:
        ------------
            Calculate the enthalpy at a given drybulb temperature
            and humidity ratio.

        Source:
        -------
            2009 ASHRAE Handbook

        Inputs:
        -------
            Tdb     float      drybulb temperature   (degC)
            w       float      humidity ratio        (kg/kg)

        Outputs:
        --------
            h       float      enthalpy              (J/kg)
        '''
    h = 1000.0 * (1.006 * tdb + w * (2501.0 + 1.86 * tdb))
    return h
  end

  def self.w_fT_h_SI(tdb, h)
        '''
        Description:
        ------------
            Calculate the humidity ratio at a given drybulb temperature
            and enthalpy.

        Source:
        -------
            2009 ASHRAE Handbook

        Inputs:
        -------
            Tdb     float      drybulb temperature  (degC)
            h       float      enthalpy              (J/kg)

        Outputs:
        --------
            w       float      humidity ratio        (kg/kg)
        '''
    w = (h / 1000.0 - 1.006 * tdb) / (2501.0 + 1.86 * tdb)
    return w
  end

  def self.Pstd_fZ(z)
        '''
        Description:
        ------------
            Calculate standard pressure of air at a given altitude

        Source:
        -------
            2009 ASHRAE Handbook

        Inputs:
        -------
            Z        float        altitude     (feet)

        Outputs:
        --------
            Pstd    float        barometric pressure (psia)
        '''

    pstd = 14.696 * ((1 - 6.8754e-6 * z) ** 5.2559)
    return pstd
  end

  def self.W_fT_Twb_P(tdb, twb, p)
        '''
        Description:
        ------------
            Calculate the humidity ratio at a given drybulb temperature,
            wetbulb temperature and pressure.

        Source:
        -------
            ASHRAE Handbook 2009

        Inputs:
        -------
            Tdb     float      drybulb temperature   (degF)
            Twb     float      wetbulb temperature   (degF)
            P       float      pressure              (psia)

        Outputs:
        --------
            w       float      humidity ratio        (lbm/lbm)
        '''
    w_star = self.w_fP(p, self.Psat_fT(twb))

    w = ((Liquid.H2O_l.h_fg - (Liquid.H2O_l.cp - Gas.H2O_v.cp) * twb) * w_star - Gas.Air.cp * (tdb - twb)) / (Liquid.H2O_l.h_fg + Gas.H2O_v.cp * tdb - Liquid.H2O_l.cp * twb) # (lbm/lbm)
    return w
  end

  def self.w_fP(p, pw)
        '''
        Description:
        ------------
            Calculate the humidity ratio at a given pressure and partial pressure.

        Source:
        -------
            Based on HUMRATIO f77 code in ResAC (Brandemuehl)

        Inputs:
        -------
            P       float      pressure              (psia)
            Pw      float      partial pressure      (psia)

        Outputs:
        --------
            w       float      humidity ratio        (lbm/lbm)
        '''
    w = Gas.PsychMassRat * pw / (p - pw)
    return w
  end

  def self.Psat_fT(tdb)
        '''
        Description:
        ------------
            Calculate the saturation pressure of water vapor at a given temperature

        Source:
        -------
            2009 ASHRAE Handbook

        Inputs:
        -------
            Tdb     float      drybulb temperature      (degF)

        Outputs:
        --------
            Psat    float      saturated vapor pressure (psia)
        '''
    c1 = -1.0214165e4
    c2 = -4.8932428
    c3 = -5.3765794e-3
    c4 = 1.9202377e-7
    c5 = 3.5575832e-10
    c6 = -9.0344688e-14
    c7 = 4.1635019
    c8 = -1.0440397e4
    c9 = -1.1294650e1
    c10 = -2.7022355e-2
    c11 = 1.2890360e-5
    c12 = -2.4780681e-9
    c13 = 6.5459673

    t_abs = OpenStudio::convert(tdb,"F","R").get
    t_frz_abs = OpenStudio::convert(Liquid.H2O_l.t_frz,"F","R").get

    # If below freezing, calculate saturation pressure over ice
    if t_abs < t_frz_abs
      psat = Math.exp(c1 / t_abs + c2 + t_abs * (c3 + t_abs * (c4 + t_abs * (c5 + c6 * t_abs))) + c7 * Math.log(t_abs))
    # If above freezing, calculate saturation pressure over liquid water
    elsif
      psat = Math.exp(c8 / t_abs + c9 + t_abs * (c10 + t_abs * (c11 + c12 * t_abs)) + c13 * Math.log(t_abs))
    end
    return psat
  end
  
  def self.CoilAoFactor(dBin, wBin, p, qdot, cfm, shr)                   
        '''
       Description:
        ------------
            Find the coil Ao factor at the given incoming air state (entering drybubl and wetbulb) and CFM,
            total capacity and SHR            


        Source:
        -------
            EnergyPlus source code

        Inputs:
        -------
            Tdb    float    Entering Dry Bulb (degF)
            Twb    float    Entering Wet Bulb (degF)
            P      float    Barometric pressure (psi)
            Qdot   float    Total capacity of unit (kBtu/h)
            cfm    float    Volumetric flow rate of unit (CFM)
            shr    float    Sensible heat ratio
        Outputs:
        --------
            Ao    float    Coil Ao Factor
        '''
    
    bf = self.CoilBypassFactor(dBin, wBin, p, qdot, cfm, shr)        
    mfr = UnitConversion.lbm_min2kg_s(self.CalculateMassflowRate(dBin, wBin, p, cfm))
    
    ntu = -1.0 * Math.log(bf)
    ao = ntu * mfr
    return ao
  end
  
  def self.CoilBypassFactor(dBin, wBin, p, qdot, cfm, shr)
        '''
       Description:
        ------------
            Find the coil bypass factor at the given incoming air state (entering drybubl and wetbulb) and CFM,
            total capacity and SHR            


        Source:
        -------
            EnergyPlus source code

        Inputs:
        -------
            Tdb    float    Entering Dry Bulb (degF)
            Twb    float    Entering Wet Bulb (degF)
            P      float    Barometric pressure (psi)
            Qdot   float    Total capacity of unit (kBtu/h)
            cfm    float    Volumetric flow rate of unit (CFM)
            shr    float    Sensible heat ratio
        Outputs:
        --------
            CBF    float    Coil Bypass Factor
        '''
        
    mfr = UnitConversion.lbm_min2kg_s(self.CalculateMassflowRate(dBin, wBin, p, cfm))

    tin = OpenStudio::convert(dBin,"F","C").get
    win = self.w_fT_Twb_P(dBin, wBin, p)
    p = OpenStudio::convert(p,"psi","kPa").get
                    
    dH = OpenStudio::convert(qdot,"kBtu/h","W").get / mfr
    hin = self.h_fT_w_SI(tin, win)
    h_Tin_Wout = hin - (1-shr)*dH
    wout = self.w_fT_h_SI(tin,h_Tin_Wout)
    dW = win - wout
    hout = hin - dH
    tout = self.T_fw_h_SI(wout, hout)                    
    rH_out = self.R_fT_w_P_SI(tout, wout, p)
    
    if rH_out > 1
        puts 'Error: Conditions passed to CoilBypassFactor result in outlet RH > 100%'
    end
                
    dT = tin - tout   
    m_c = dW / dT        
    
    t_ADP = self.Tdp_fP_w_SI(p, wout)  # Initial guess for iteration
    
    if shr == 1           
        w_ADP = self.w_fT_Twb_P_SI(t_ADP, t_ADP, p)
        h_ADP = self.h_fT_w_SI(t_ADP, w_ADP)
        bF = (hout - h_ADP) / (hin - h_ADP)
        return max(bF, 0.01)
    end
    
    cnt = 0
    tol = 1.0
    errorLast = 100
    d_T_ADP = 5.0
    
    while cnt < 100 and tol > 0.001       
        # for i in range(1,itmax+1):
                    
        if cnt > 0
            t_ADP = t_ADP + d_T_ADP
        end
        
        w_ADP = self.w_fT_Twb_P_SI(t_ADP, t_ADP, p)
       
        m = (win - w_ADP) / (tin - t_ADP)
        error = (m - m_c) / m_c

        if error > 0 and errorLast < 0
            d_T_ADP = -1.0*d_T_ADP/2.0
        end
        
        if error < 0 and errorLast > 0
            d_T_ADP = -1.0*d_T_ADP/2.0
        end
       
        errorLast = error
        tol = error.abs.to_f
        cnt = cnt + 1
    end        

    h_ADP = self.h_fT_w_SI(t_ADP, w_ADP)
    
    bF = (hout - h_ADP) / (hin - h_ADP)
    return [bF, 0.01].max
  end
  
  def self.CalculateMassflowRate(dBin, wBin, p, cfm)
        '''
       Description:
        ------------
            Calculate the mass flow rate at the given incoming air state (entering drybubl and wetbulb) and CFM            

        Source:
        -------
            

        Inputs:
        -------
            Tdb    float    Entering Dry Bulb (degF)
            Twb    float    Entering Wet Bulb (degF)
            P      float    Barometric pressure (psi)            
            cfm    float    Volumetric flow rate of unit (CFM)            
        Outputs:
        --------
            mfr    float    mass flow rate (lbm/min)            
        '''    
    win= self.w_fT_Twb_P(dBin, wBin, p)
    rho_in = self.rhoD_fT_w_P(dBin, win, p)        
    mfr = cfm*rho_in
    return mfr
  end

  def self.T_fw_h_SI(w, h)
        '''
        Description:
        ------------
            Calculate the drybulb temperature at a given humidity ratio
            and enthalpy.

        Source:
        -------
            2009 ASHRAE Handbook

        Inputs:
        -------
            w       float      humidity ratio        (kg/kg)
            h       float      enthalpy              (J/kg)

        Outputs:
        --------
            T       float      drybulb temperature  (degC)
        '''        
                        
    t = (h/1000 - w*2501) / (1.006 + w*1.86)            
    return t
  end        
  
  def self.R_fT_w_P_SI(tdb,w,p)
        '''
        Description:
        ------------
            Calculate the relative humidity at a given drybulb temperature,
            humidity ratio and pressure.

        Source:
        -------
            2009 ASHRAE Handbook

        Inputs:
        -------
            Tdb     float      drybulb temperature   (degC)
            w       float      humidity ratio        (g/g)
            P       float      pressure              (kPa)

        Outputs:
        --------
            R       float      relative humidity     (1/1)
        '''
    return self.R_fT_w_P(OpenStudio::convert(tdb,"C","F").get, w, OpenStudio::convert(p,"kPa","psi").get)     
  end
  
  def self.Tdp_fP_w_SI(p,w)
        '''
        Description:
        ------------
            Calculate the dewpoint temperature at a given pressure
            and humidity ratio.

            There are two available methods:

            CalcMethod == 1: Uses the correlation method from ASHRAE Handbook
            CalcMethod <> 1: Uses the saturation temperature at the partial
                             pressure

        Source:
        -------
            2009 ASHRAE Handbook

        Inputs:
        -------
            P       float      pressure              (kPa)
            w       float      humidity ratio        (g/g)

        Outputs:
        --------
            Tdp     float      dewpoint temperature  (degC)            
        '''
    return OpenStudio::convert(self.Tdp_fP_w(OpenStudio::convert(p,"kPa","psi").get, w),"F","C").get
  end        
  
  def self.w_fT_Twb_P_SI(tdb,twb,p)
        '''
        Description:
        ------------
            Calculate the humidity ratio at a given drybulb temperature,
            wetbulb temperature and pressure.

        Source:
        -------
            ASHRAE Handbook 2009

        Inputs:
        -------
            Tdb     float      drybulb temperature   (degC)
            Twb     float      wetbulb temperature   (degC)
            P       float      pressure              (kPa)

        Outputs:
        --------
            w       float      humidity ratio        (g/g)
        '''
        
    return self.w_fT_Twb_P(OpenStudio::convert(tdb,"C","F").get, OpenStudio::convert(twb,"C","F").get, OpenStudio::convert(p,"kPa","psi").get)      
  end        
  
  def self.w_fT_Twb_P(tdb,twb,p)
        '''
        Description:
        ------------
            Calculate the humidity ratio at a given drybulb temperature,
            wetbulb temperature and pressure.

        Source:
        -------
            ASHRAE Handbook 2009

        Inputs:
        -------
            Tdb     float      drybulb temperature   (degF)
            Twb     float      wetbulb temperature   (degF)
            P       float      pressure              (psia)

        Outputs:
        --------
            w       float      humidity ratio        (lbm/lbm)
        '''
    w_star = self.w_fP(p,self.Psat_fT(twb))

    w = ((Liquid.H2O_l.h_fg - (Liquid.H2O_l.cp - Gas.H2O_v.cp)*twb)*w_star \
                 - Gas.Air.cp*(tdb - twb))/(Liquid.H2O_l.h_fg + Gas.H2O_v.cp*tdb \
                 - Liquid.H2O_l.cp*twb) # (lbm/lbm)

    return w
  end        
  
  def self.R_fT_w_P(tdb,w,p)
        '''
        Description:
        ------------
            Calculate the relative humidity at a given drybulb temperature,
            humidity ratio and pressure.

        Source:
        -------
            2009 ASHRAE Handbook

        Inputs:
        -------
            Tdb     float      drybulb temperature   (degF)
            w       float      humidity ratio        (lbm/lbm)
            P       float      pressure              (psia)

        Outputs:
        --------
            R       float      relative humidity     (1/1)
        '''
    pw = self.Pw_fP_w(p,w)
    r = pw/self.Psat_fT(tdb)
    return r
  end        
  
  def self.Pw_fP_w(p,w)
        '''
        Description:
        ------------
            Calculate the partial vapor pressure at a given pressure and
            humidity ratio.

        Source:
        -------
            2009 ASHRAE Handbook

        Inputs:
        -------
            P       float      pressure              (psia)
            w       float      humidity ratio        (lbm/lbm)

        Outputs:
        --------
            Pw      float      partial pressure      (psia)
        '''

    pw = p*w/(Gas.PsychMassRat + w)
    return pw
  end        
    
  def self.Tdp_fP_w(p,w)
        '''
        Description:
        ------------
            Calculate the dewpoint temperature at a given pressure
            and humidity ratio.

            There are two available methods:

            CalcMethod == 1: Uses the correlation method from ASHRAE Handbook
            CalcMethod <> 1: Uses the saturation temperature at the partial
                             pressure

        Source:
        -------
            2009 ASHRAE Handbook

        Inputs:
        -------
            P       float      pressure              (psia)
            w       float      humidity ratio        (lbm/lbm)

        Outputs:
        --------
            Tdp     float      dewpoint temperature  (degF)
        '''

    calcMethod = 1

    if calcMethod == 1

        c14 = 100.45
        c15 = 33.193
        c16 = 2.319
        c17 = 0.17074
        c18 = 1.2063

        pw = self.Pw_fP_w(p,w) # (psia)
        alpha = Math.log(pw)
        tdp1 = c14 + c15*alpha + c16*alpha**2 + c17*alpha**3 + c18*pw**0.1984
        tdp2 = 90.12 + 26.142*alpha + 0.8927*alpha**2
        if tdp1 >= Liquid.H2O_l.t_frz
            tdp = tdp1
        else
            tdp = tdp2
        end

    else

        # based on DEWPOINT f77 code in ResAC (Brandemuehl)
        if w < Constants.small
            tdp = -999.0
        else
            pw = self.Pw_fP_w(p,w)
            tdp = self.Tsat_fP(pw)
        end
            
    end
    return tdp
  end        
  
  def self.CalculateSHR(dBin, wBin, p, q, cfm, ao)
        '''
       Description:
        ------------
            Calculate the coil SHR at the given incoming air state, CFM, total capacity, and coil
            Ao factor                        
    
        Source:
        -------
            EnergyPlus source code
    
        Inputs:
        -------
            Tdb    float    Entering Dry Bulb (degF)
            Twb    float    Entering Wet Bulb (degF)
            P      float    Barometric pressure (psi)
            Q      float    Total capacity of unit (kBtu/h)
            cfm    float    Volumetric flow rate of unit (CFM)
            Ao     float    Coil Ao factor (=UA/Cp - IN SI UNITS)
        Outputs:
        --------
            SHR    float    Sensible Heat Ratio
        '''
        
    mfr = UnitConversion.lbm_min2kg_s(self.CalculateMassflowRate(dBin, wBin, p, cfm))
    bf = Math.exp(-1.0*ao/mfr)
    
    win = self.w_fT_Twb_P(dBin, wBin, p)
    p = OpenStudio::convert(p,"psi","kPa").get
    tin = OpenStudio::convert(dBin,"F","C").get
    hin = self.h_fT_w_SI(tin, win)
    dH = OpenStudio::convert(q,"kBtu/h","W").get / mfr
    h_ADP = hin - dH / (1-bf)
    
    # T_ADP = self.Tsat_fh_P_SI(H_ADP, P)
    # W_ADP = self.w_fT_h_SI(T_ADP, H_ADP)
    
    # Initialize
    t_ADP = self.Tdp_fP_w_SI(p, win)
    t_ADP_1 = t_ADP # (degC)
    t_ADP_2 = t_ADP # (degC)
    w_ADP = self.w_fT_R_P_SI(t_ADP, 1.0, p)
    error = h_ADP - self.h_fT_w_SI(t_ADP, w_ADP)
    error1 = error
    error2 = error

    itmax = 50  # maximum iterations
    cvg = false

    (1...itmax+1).each do |i|

        w_ADP = self.w_fT_R_P_SI(t_ADP, 1.0, p)    
        error = h_ADP - self.h_fT_w_SI(t_ADP, w_ADP)

        t_ADP,cvg,t_ADP_1,error1,t_ADP_2,error2 = HelperMethods.Iterate(t_ADP,error,t_ADP_1,error1,t_ADP_2,error2,i,cvg)

        if cvg
            break
        end
    end

    if not cvg
        puts 'Warning: Tsat_fh_P failed to converge'        
    end
    
    h_Tin_Wadp = self.h_fT_w_SI(tin, w_ADP)
    
    if (hin - h_ADP != 0)
        shr = [(h_Tin_Wadp-h_ADP) / (hin - h_ADP),1.0].min
    else
        shr = 1
    end        
    return shr
  end        
    
  def self.w_fT_R_P_SI(tdb,r,p)
        '''
        Description:
        ------------
            Calculate the humidity ratio at a given drybulb temperature,
            relative humidity and pressure.

        Source:
        -------
            2009 ASHRAE Handbook

        Inputs:
        -------
            Tdb     float      drybulb temperature   (degC)
            R       float      relative humidity     (1/1)
            P       float      pressure              (kPa)

        Outputs:
        --------
            w       float      humidity ratio        (g/g)
        '''
    pws = OpenStudio::convert(self.Psat_fT(OpenStudio::convert(tdb,"C","F").get),"psi","kPa").get
    pw = r * pws
    w = 0.62198 * pw / (p - pw)
    return w
  end        
    
end