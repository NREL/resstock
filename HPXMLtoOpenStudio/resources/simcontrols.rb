# frozen_string_literal: true

class SimControls
  def self.apply(model, header)
    sim = model.getSimulationControl
    sim.setRunSimulationforSizingPeriods(false)

    tstep = model.getTimestep
    tstep.setNumberOfTimestepsPerHour(60 / header.timestep)

    shad = model.getShadowCalculation
    shad.setShadingCalculationUpdateFrequency(20)
    shad.setMaximumFiguresInShadowOverlapCalculations(200)

    outsurf = model.getOutsideSurfaceConvectionAlgorithm
    outsurf.setAlgorithm('DOE-2')

    insurf = model.getInsideSurfaceConvectionAlgorithm
    insurf.setAlgorithm('TARP')

    zonecap = model.getZoneCapacitanceMultiplierResearchSpecial
    zonecap.setHumidityCapacityMultiplier(15)

    convlim = model.getConvergenceLimits
    convlim.setMinimumSystemTimestep(0)

    run_period = model.getRunPeriod
    run_period.setBeginMonth(header.sim_begin_month)
    run_period.setBeginDayOfMonth(header.sim_begin_day_of_month)
    run_period.setEndMonth(header.sim_end_month)
    run_period.setEndDayOfMonth(header.sim_end_day_of_month)
  end
end
