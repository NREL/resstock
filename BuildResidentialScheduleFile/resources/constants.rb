# frozen_string_literal: true

# TODO
module Constants
  # TODO
  #
  # @return [String] TODO
  def self.OccupancyTypesProbabilities
    return '0.381, 0.297, 0.165, 0.157'
  end

  # TODO
  #
  # @return [String] TODO
  def self.SinkDurationProbability
    return '0.901242, 0.076572, 0.01722, 0.003798, 0.000944, 0.000154, 4.6e-05, 2.2e-05, 2.0e-06'
  end

  # TODO
  #
  # @return [String] TODO
  def self.SinkEventsPerClusterProbs
    return '0.62458, 0.18693, 0.08011, 0.0433, 0.02178, 0.01504, 0.0083, 0.00467, 0.0057, 0.00285, 0.00181, 0.00233, 0.0013, 0.00104, 0.00026'
  end

  # TODO
  #
  # @return [String] TODO
  def self.SinkHourlyOnsetProb
    return '0.007, 0.018, 0.042, 0.062, 0.066, 0.062, 0.054, 0.05, 0.049, 0.045, 0.041, 0.043, 0.048, 0.065, 0.075, 0.069, 0.057, 0.048, 0.04, 0.027, 0.014, 0.007, 0.005, 0.005'
  end

  # TODO
  #
  # @return [Integer] TODO
  def self.SinkAvgSinkClustersPerHH
    return 6657
  end

  # TODO
  #
  # @return [Integer] TODO
  def self.SinkMinutesBetweenEventGap
    return 2
  end

  # TODO
  #
  # @return [Double] TODO
  def self.SinkFlowRateMean
    return 1.14
  end

  # TODO
  #
  # @return [Double] TODO
  def self.SinkFlowRateStd
    return 0.61
  end

  # TODO
  #
  # @return [Integer] TODO
  def self.ShowerMinutesBetweenEventGap
    return 30
  end

  # TODO
  #
  # @return [Double] TODO
  def self.ShowerFlowRateMean
    return 2.25
  end

  # TODO
  #
  # @return [Double] TODO
  def self.ShowerFlowRateStd
    return 0.68
  end

  # TODO
  #
  # @return [Double] TODO
  def self.BathBathToShowerRatio
    return 0.078843
  end

  # TODO
  #
  # @return [Double] TODO
  def self.BathDurationMean
    return 5.65
  end

  # TODO
  #
  # @return [Double] TODO
  def self.BathDurationStd
    return 2.09
  end

  # TODO
  #
  # @return [Double] TODO
  def self.BathFlowRateMean
    return 4.4
  end

  # TODO
  #
  # @return [Double] TODO
  def self.BathFlowRateStd
    return 1.17
  end

  # TODO
  #
  # @return [Double] TODO
  def self.HotWaterDishwasherFlowRateMean
    return 1.39
  end

  # TODO
  #
  # @return [Double] TODO
  def self.HotWaterDishwasherFlowRateStd
    return 0.2
  end

  # TODO
  #
  # @return [Integer] TODO
  def self.HotWaterDishwasherMinutesBetweenEventGap
    return 10
  end

  # TODO
  #
  # @return [Double] TODO
  def self.HotWaterClothesWasherFlowRateMean
    return 2.2
  end

  # TODO
  #
  # @return [Double] TODO
  def self.HotWaterClothesWasherFlowRateStd
    return 0.62
  end

  # TODO
  #
  # @return [Integer] TODO
  def self.HotWaterClothesWasherMinutesBetweenEventGap
    return 4
  end

  # TODO
  #
  # @return [String] TODO
  def self.HotWaterClothesWasherLoadSizeProbability
    return '0.682926829, 0.227642276, 0.056910569, 0.032520325'
  end
end
