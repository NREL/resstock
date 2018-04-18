class Simulation

    def self.apply(model, runner, timesteps=1)

        sim = model.getSimulationControl
        sim.setRunSimulationforSizingPeriods(false)
        
        tstep = model.getTimestep
        tstep.setNumberOfTimestepsPerHour(timesteps)
        
        shad = model.getShadowCalculation
        shad.setCalculationFrequency(20)
        shad.setMaximumFiguresInShadowOverlapCalculations(200)
        
        outsurf = model.getOutsideSurfaceConvectionAlgorithm
        outsurf.setAlgorithm('DOE-2')
        
        insurf = model.getInsideSurfaceConvectionAlgorithm
        insurf.setAlgorithm('TARP')
        
        zonecap = model.getZoneCapacitanceMultiplierResearchSpecial
        zonecap.setHumidityCapacityMultiplier(15)

        return true
    end
       
end