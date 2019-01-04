class Simulation
  def self.apply(model, runner, timesteps_per_hr = 1, min_system_timestep_mins = nil, begin_month = 1, begin_day_of_month = 1, end_month = 12, end_day_of_month = 31)
    sim = model.getSimulationControl
    sim.setRunSimulationforSizingPeriods(false)

    tstep = model.getTimestep
    tstep.setNumberOfTimestepsPerHour(timesteps_per_hr) # Timesteps/hour

    shad = model.getShadowCalculation
    shad.setCalculationFrequency(20)
    shad.setMaximumFiguresInShadowOverlapCalculations(200)

    outsurf = model.getOutsideSurfaceConvectionAlgorithm
    outsurf.setAlgorithm('DOE-2')

    insurf = model.getInsideSurfaceConvectionAlgorithm
    insurf.setAlgorithm('TARP')

    zonecap = model.getZoneCapacitanceMultiplierResearchSpecial
    zonecap.setHumidityCapacityMultiplier(15)

    if not min_system_timestep_mins.nil?
      convlim = model.getConvergenceLimits
      convlim.setMinimumSystemTimestep(min_system_timestep_mins) # Minutes
    end

    run_period = model.getRunPeriod
    run_period.setBeginMonth(begin_month)
    run_period.setBeginDayOfMonth(begin_day_of_month)
    run_period.setEndMonth(end_month)
    run_period.setEndDayOfMonth(end_day_of_month)

    return true
  end
end
