# frozen_string_literal: true

class SimControls
  def self.apply(model, header)
    sim = model.getSimulationControl
    sim.setRunSimulationforSizingPeriods(false)

    tstep = model.getTimestep
    tstep.setNumberOfTimestepsPerHour(60 / header.timestep)

    shad = model.getShadowCalculation
    shad.setMaximumFiguresInShadowOverlapCalculations(200)
    # Detailed diffuse algorithm is required for window interior shading with varying
    # transmittance schedules
    shad.setSkyDiffuseModelingAlgorithm('DetailedSkyDiffuseModeling')
    # Use EnergyPlus default of 20 days for update frequency; it is a reasonable balance
    # between speed and accuracy (e.g., sun position, picking up any change in window
    # interior shading transmittance, etc.).
    shad.setShadingCalculationUpdateFrequency(20)

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
    run_period.setBeginDayOfMonth(header.sim_begin_day)
    run_period.setEndMonth(header.sim_end_month)
    run_period.setEndDayOfMonth(header.sim_end_day)
  end
end
