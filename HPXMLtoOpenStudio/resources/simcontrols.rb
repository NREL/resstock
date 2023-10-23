# frozen_string_literal: true

class SimControls
  def self.apply(model, hpxml)
    sim = model.getSimulationControl
    sim.setRunSimulationforSizingPeriods(false)

    tstep = model.getTimestep
    tstep.setNumberOfTimestepsPerHour(60 / hpxml.header.timestep)

    shad = model.getShadowCalculation
    shad.setMaximumFiguresInShadowOverlapCalculations(200)
    # Use EnergyPlus default of 20 days for update frequency; it is a reasonable balance
    # between speed and accuracy (e.g., sun position, picking up any change in window
    # interior shading transmittance, etc.).
    shad.setShadingCalculationUpdateFrequency(20)

    outsurf = model.getOutsideSurfaceConvectionAlgorithm
    outsurf.setAlgorithm('DOE-2')

    insurf = model.getInsideSurfaceConvectionAlgorithm
    insurf.setAlgorithm('TARP')

    zonecap = model.getZoneCapacitanceMultiplierResearchSpecial
    zonecap.setTemperatureCapacityMultiplier(hpxml.header.temperature_capacitance_multiplier)
    zonecap.setHumidityCapacityMultiplier(15)

    convlim = model.getConvergenceLimits
    convlim.setMinimumSystemTimestep(0)

    run_period = model.getRunPeriod
    run_period.setBeginMonth(hpxml.header.sim_begin_month)
    run_period.setBeginDayOfMonth(hpxml.header.sim_begin_day)
    run_period.setEndMonth(hpxml.header.sim_end_month)
    run_period.setEndDayOfMonth(hpxml.header.sim_end_day)

    ppt = model.getPerformancePrecisionTradeoffs
    ppt.setZoneRadiantExchangeAlgorithm('CarrollMRT')
  end
end
