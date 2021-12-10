def get_cluster(sch, period, timeClass, cluster_gap_minute = 30, after_margin = 0)
  # gets a cluster of times and values that touches the period
  cluster_minutes = []
  cluster = []
  in_cluster = false
  sch.values.each_with_index do |value, index|
    time = sch.times[index]
    minute = time.totalMinutes
    if (cluster_minutes[-1] && ((minute - cluster_minutes[-1]) < cluster_gap_minute))
      # this value is less than gap-time after last value join to cluster
      cluster << [time, value]
      cluster_minutes << minute
    else
      # This value is more than an cluster_gap_minute time after
      # if it is positive value, it must join to the cluster
      if value > 1e-8
        cluster << [time, value]
        cluster_minutes << minute
      else
        # if it is zero and that too coming after more than an gap_minute
        if time.totalMinutes >= period[1] * 60 + after_margin
          # we are past the period
          if cluster_minutes[-1] && (cluster_minutes[-1] > period[0] * 60)
            # the last cluster entered the period, so return it
            return cluster
          else
            # the last cluster didn't enter the period, so return empty cluster
            return []
          end
        elsif time.totalMinutes <= period[0] * 60
          # we haven't even entered the period
          # discard the last cluster and start afresh
          cluster_minutes = [minute]
          cluster = [[time, value]]
        else
          # we have entered the period.
          # discard the last cluster if it didn't touch, otherwise add to it
          if cluster_minutes[-1] && (cluster_minutes[-1] > period[0] * 60)
            # the last cluster had entered the period. Just keep adding to it
            cluster << [time, value]
            cluster_minutes << minute
          else
            # the last cluster didn't enter the period
            # discard the last cluster and start afresh
            cluster = [[time, value]]
            cluster_minutes = [minute]
          end
        end
      end
    end
  end
  return cluster
end

def move_cluster(sch, cluster_times, distance, timeClass)
  if (not cluster_times) || (cluster_times.length == 0)
    return sch.times, sch.values
  end

  cluster_duration = cluster_times[-1].totalMinutes - cluster_times[0].totalMinutes
  to_remove_schedule_indexs = []
  moved_cluster = []
  sch.times.each_with_index do |time, index|
    next unless cluster_times.include?(time)

    new_total_minutes = time.totalMinutes + distance
    hour = (new_total_minutes / 60).to_i
    min = (new_total_minutes % 60)
    new_time = timeClass.new("#{hour}:#{min}:00")
    moved_cluster << [new_time, sch.values[index]]
    to_remove_schedule_indexs << index
  end

  # remove the to be moved schedules
  sch_times = sch.times.dup
  sch_values = sch.values.dup
  sch_times.reject!.with_index { |time, index| to_remove_schedule_indexs.include?(index) }
  sch_values.reject!.with_index { |value, index| to_remove_schedule_indexs.include?(index) }
  moved_cluster_start_time = moved_cluster[0][0].totalMinutes
  moved_cluster_end_time = moved_cluster[-1][0].totalMinutes
  len = sch_times.length
  insert_just_before_index = len - 1
  sch_times.each_with_index do |time, index|
    if time.totalMinutes == moved_cluster_start_time
      insert_just_before_index = index + 1
      moved_cluster.delete_at(0)
      break
    elsif time.totalMinutes < moved_cluster_start_time
      next
    else
      insert_just_before_index = index
      break
    end
  end
  if sch_times[insert_just_before_index] && (sch_times[insert_just_before_index].totalMinutes == moved_cluster_end_time)
    if sch_values[insert_just_before_index] < 1e-8
      sch_times.reject!.with_index { |t, i| i == insert_just_before_index }
      sch_values.reject!.with_index { |t, i| i == insert_just_before_index }
    end
  end
  if insert_just_before_index > 0
    new_sch_times = sch_times[0..insert_just_before_index - 1] + moved_cluster.transpose[0] + sch_times[insert_just_before_index..len]
    new_sch_values = sch_values[0..insert_just_before_index - 1] + moved_cluster.transpose[1] + sch_values[insert_just_before_index..len]
  else
    if sch_times.any?
      new_sch_times = moved_cluster.transpose[0] + sch_times[insert_just_before_index..len]
      new_sch_values = moved_cluster.transpose[1] + sch_values[insert_just_before_index..len]
    else
      new_sch_times = moved_cluster.transpose[0]
      new_sch_values = moved_cluster.transpose[1]
    end
  end
  return new_sch_times, new_sch_values
end

def dodge_peak(sch, peak_period, all_peaks, timeClass)
  cluster = get_cluster(sch, peak_period, timeClass)
  if cluster.nil? || (cluster.length == 0) || (not cluster.transpose[0][0])
    return sch.times, sch.values
  end

  times, values = cluster.transpose

  # assumes that cluster always starts with a value of 0
  raise "Cluster doesn't start with a 0 value" unless values[0] < 1e-8

  move_forward = -> {
    earliest_start_time_after = [peak_period[1] * 60, times[-1].totalMinutes].max
    # later of end of peak_period or the end of the cluster
    # toss a coin to decide shift before/after
    duration = times[-1].totalMinutes - times[0].totalMinutes
    sch_clear_until = 24 * 60 # the time after earliest start time that it's clear of schedule)
    # check if we can place the cluster immediately after the earliest start time
    peak_clear_until = 24 * 60 # the time after earliest start time that it's clear of peak

    sch.times.each_with_index do |sch_time, indx|
      if sch_time.totalMinutes < earliest_start_time_after
        # we haven't reached the earliest start time, so just keep going
        next
      else
        if sch_time.totalMinutes - earliest_start_time_after > duration
          sch_clear_until = sch_time.totalMinutes
          # we found enough room. we done here
          break
        else
          if sch.values[indx] < 1e-8
            # we found an obstruction
            # find when that obstruction ends
            found_next_slot = false
            (indx..sch.times.length - 1).each do |i|
              next unless (sch.values[i] > 1e-8) && sch.values[i + 1] && (sch.values[i + 1] < 1e-8)

              found_next_slot = true
              earliest_start_time_after = sch.times[i].totalMinutes
              break
            end
            if not found_next_slot
              return false, sch.times, sch.values
            end
          end
        end
      end
    end
    all_peaks.each_with_index do |peak, indx|
      if peak[0] * 60 <= earliest_start_time_after
        # we haven't reached the earliest start time, so just keep going
        next
      else
        peak_clear_until = peak[0] * 60
      end
    end

    clear_until = [sch_clear_until, peak_clear_until].min

    if clear_until - earliest_start_time_after >= duration
      # the cluster will fit inside the clear space
      moving_room = (clear_until - earliest_start_time_after) - duration

      inroom_move_distance = rand(moving_room)
      inroom_move_distance = 0 # make it left tight

      start_time = earliest_start_time_after + inroom_move_distance
      total_move_distance = start_time - times[0].totalMinutes
      t, v = move_cluster(sch, times, total_move_distance, timeClass)
      return true, t, v
    else
      return false, sch.times, sch.values
    end
  }

  move_backward = -> {
    duration = times[-1].totalMinutes - times[0].totalMinutes

    latest_end_time_before = [peak_period[0] * 60, times[0].totalMinutes].min
    # earlier of end of peak_period or the end of the cluster

    sch_clear_until = 0 * 60 # the time before latest_end_time_before till when (in backward direction) it's clear of schedule)
    peak_clear_until = 0 * 60 # the time before latest_end_time_before till when it's clear of peak
    lst_index = sch.times.length - 1

    # iterate from back
    lst_index.downto(0) do |indx|
      sch_time = sch.times[indx]
      if sch_time.totalMinutes > latest_end_time_before
        # we haven't reached the earliest end time, so just keep going
        next
      else
        if latest_end_time_before - sch_time.totalMinutes >= duration
          sch_clear_until = sch_time.totalMinutes
          # we found enough room. we done here
          break
        else
          if sch.values[indx] > 1e-8
            # we found an obstruction
            # find when that obstruction ends
            found_next_slot = false
            (indx - 1).downto(0) do |i|
              next unless sch.values[i] < 1e-8

              found_next_slot = true
              latest_end_time_before = sch.times[i].totalMinutes
              break
            end
            if not found_next_slot
              return false, sch.times, sch.values
            end
          end
        end
      end
    end
    (all_peaks.length - 1).downto(0) do |indx|
      peak = all_peaks[indx]
      if peak[1] * 60 > latest_end_time_before
        # we haven't reached the earliest start time, so just keep going
        next
      else
        peak_clear_until = peak[1] * 60
      end
    end

    clear_until = [sch_clear_until, peak_clear_until].max
    if (latest_end_time_before - clear_until) >= duration
      # the cluster will fit inside the clear space
      moving_room = (latest_end_time_before - clear_until) - duration

      inroom_move_distance = rand(moving_room)
      inroom_move_distance = 0 # make it left tight

      end_time = latest_end_time_before + inroom_move_distance
      total_move_distance = end_time - times[-1].totalMinutes
      t, v = move_cluster(sch, times, total_move_distance, timeClass)
      return true, t, v

    else
      return false, sch.times, sch.values
    end
  }

  is_sucess, fmoved_times, fmoved_values = move_forward.call()
  if not is_sucess
    is_sucess, bmoved_times, bmoved_values = move_backward.call()
    return bmoved_times, bmoved_values
  else
    return fmoved_times, fmoved_values
  end
end

def shift_peak_to_take(sch, peak_period, take_period, timeClass, fraction = [0, 1])
  times = sch.times
  vals = sch.values

  # find the energy inside the peak-period
  energy_sum = 0
  prev_time_minutes = 0
  times.each_with_index do |time, index|
    cur_val = vals[index]
    if time.totalMinutes > peak_period[0] * 60
      if prev_time_minutes < peak_period[0]
        prev_time_minutes = peak_period[0] * 60
      end
      if time.totalMinutes > peak_period[1] * 60
        energy_sum += cur_val * (peak_period[1] * 60 - prev_time_minutes)
        break
      else
        energy_sum += cur_val * (time.totalMinutes - prev_time_minutes)
      end
    end
    prev_time_minutes = time.totalMinutes
  end

  if energy_sum == 0
    # because there is no energy inside the peak means, there is nothing to be done.
    return times, vals
  end

  if fraction[0] == 0
    # clear the schedule during peak_period
    new_sch_times = []
    new_sch_vals = []
    entered_peak = false
    times.each_with_index do |time, index|
      cur_val = vals[index]
      if (time.totalMinutes >= peak_period[0] * 60) && (not entered_peak)
        prev_index = index - 1
        new_sch_times = times[0, prev_index + 1] # indexes upto prev index
        new_sch_vals = vals[0, prev_index + 1]
        entered_peak = true # enter here only once
        if cur_val > 0
          new_sch_times << timeClass.new("#{peak_period[0]}:00:00")
          new_sch_vals << cur_val
        end
      end

      next unless time.totalMinutes >= peak_period[1] * 60

      if time.totalMinutes == peak_period[1] * 60
        # if this entry is exactly at the ending boundary, just make it 0
        new_sch_times << time
        new_sch_vals << 0
        new_sch_times += times[index + 1..-1]
        new_sch_vals += vals[index + 1..-1]
      else
        if cur_val > 0
          # add a point at the ending boundary with value 0 if it isn't already 0
          new_sch_times << timeClass.new("#{peak_period[1]}:00:00")
          new_sch_vals << 0
        end
        new_sch_times += times[index..-1]
        new_sch_vals += vals[index..-1]
      end
      break
    end
  else
    # reduce the energy during peak period to a certain fraction
    new_sch_times = []
    new_sch_vals = []
    entered = false
    times.each_with_index do |time, index|
      cur_val = vals[index]
      if (time.totalMinutes >= peak_period[0] * 60) && ((time.totalMinutes < peak_period[1] * 60) || (not entered))
        if not entered
          entered = true
          if time.totalMinutes == peak_period[0] * 60
            new_sch_times << time
            new_sch_vals << cur_val
          elsif time.totalMinutes > peak_period[0] * 60
            new_sch_times << timeClass.new("#{peak_period[0]}:00:00")
            new_sch_vals << cur_val
            if time.totalMinutes < peak_period[1] * 60
              new_sch_times << time
              new_sch_vals << cur_val * fraction[0]
            end
          end
        else
          new_sch_times << time
          new_sch_vals << cur_val * fraction[0]
        end
      end
      if time.totalMinutes >= peak_period[1] * 60
        if time.totalMinutes == peak_period[1] * 60
          new_sch_times << time
          new_sch_vals << cur_val * fraction[0]
          new_sch_times += times[index + 1..-1]
          new_sch_vals += vals[index + 1..-1]
        else
          new_sch_times << timeClass.new("#{peak_period[1]}:00:00")
          new_sch_vals << cur_val * fraction[0]
          new_sch_times += times[index..-1]
          new_sch_vals += vals[index..-1]
        end
        break
      end
      if time.totalMinutes < peak_period[0] * 60
        new_sch_times << time
        new_sch_vals << cur_val
      end
    end
  end

  # put (fraction of) the energy back into take period
  energy_addition = fraction[1] * energy_sum.to_f / ((take_period[1] - take_period[0]) * 60)
  take_added_sch_time = []
  take_added_sch_vals = []
  entered = false
  new_sch_times.each_with_index do |time, index|
    cur_val = new_sch_vals[index]
    if (time.totalMinutes >= take_period[0] * 60) && ((time.totalMinutes < take_period[1] * 60) || (not entered))
      if not entered
        entered = true
        if time.totalMinutes == take_period[0] * 60
          take_added_sch_time << time
          take_added_sch_vals << cur_val
        elsif time.totalMinutes > take_period[0] * 60
          take_added_sch_time << timeClass.new("#{take_period[0]}:00:00")
          take_added_sch_vals << cur_val
          if time.totalMinutes < take_period[1] * 60
            take_added_sch_time << time
            take_added_sch_vals << cur_val + energy_addition
          end
        end
      else
        take_added_sch_time << time
        take_added_sch_vals << cur_val + energy_addition
      end
    end
    if time.totalMinutes >= take_period[1] * 60
      if time.totalMinutes == take_period[1] * 60
        take_added_sch_time << time
        take_added_sch_vals << cur_val + energy_addition
        take_added_sch_time += new_sch_times[index + 1..-1]
        take_added_sch_vals += new_sch_vals[index + 1..-1]
      else
        take_added_sch_time << timeClass.new("#{take_period[1]}:00:00")
        take_added_sch_vals << cur_val + energy_addition
        take_added_sch_time += new_sch_times[index..-1]
        take_added_sch_vals += new_sch_vals[index..-1]
      end
      break
    end
    if time.totalMinutes < take_period[0] * 60
      take_added_sch_time << time
      take_added_sch_vals << cur_val
    end
  end
  return take_added_sch_time, take_added_sch_vals
end
