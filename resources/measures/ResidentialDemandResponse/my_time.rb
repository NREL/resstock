class MyTime
  def initialize(time)
    @time = time.split(':').map(&:to_i)
  end

  def totalMinutes
    return @time[0] * 60 + @time[1]
  end

  def totalHours
    return @time[0]
  end

  def minutes
    return @time[1]
  end

  def hours
    return @time[0]
  end

  def seconds
    return @time[2]
  end

  def to_s
    return "#{"%02d" % self.hours}:#{"%02d" % self.minutes}:#{"%02d" % self.seconds}"
  end

  def inspect
    return "#{"%02d" % self.hours}:#{"%02d" % self.minutes}:#{"%02d" % self.seconds}"
  end

  def <=>(other)
    self.totalMinutes <=> other.totalMinutes
  end
end
