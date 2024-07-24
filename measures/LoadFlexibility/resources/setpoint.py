from input_helper import OffsetTypeData, OffsetTimingData, RelativeOffsetData, AbsoluteOffsetData
from typing import List
from setpoint_helper import HVACSetpoints, BuildingInfo
import pandas as pd
import numpy as np
import math
from datetime import datetime
from dataclasses import dataclass, fields

def get_month_day(year_index, total_indices, year=2007):
    """
    for each setpoint temperature,
    get the month and day type (weekday for weekend) that it belongs.
    the year number need to modify if the simulation year is not 2007.
    """

    num_timsteps_per_hour = total_indices / 8760
    hour_num = year_index // num_timsteps_per_hour
    day_num = int(hour_num // 24 + 1)
    month = datetime.strptime(str(year) + "-" + str(day_num), "%Y-%j").strftime("%m")

    # need to modify based on the simulation year what the first day is
    # the first day in 2007 is Monday
    if day_num % 7 < 5:
        day_type = 'weekday'
    else:
        day_type = 'weekend'
        
    return month, day_type

@dataclass
class peak_time_default:
    pre_peak_start_morning: int = 0 
    peak_start_morning: int = 0
    peak_end_morning: int = 0
    pre_peak_start_afternoon: int = 0
    peak_start_afternoon: int = 0
    peak_end_afternoon: int = 0

def get_prepeak_and_peak_start_end(year_index, total_indices, on_peak_hour_weekday_dict, on_peak_hour_weekend_dict, setpoint_type):
    """
    determine the prepeak start time, on peak start and end time,
    in the unit of hour
    """

    month, day_type = get_month_day(year_index, total_indices)

    if setpoint_type == 'heating':
        pre_peak_duration = OffsetTimingData.heating_pre_peak_duration
        on_peak_duration = OffsetTimingData.heating_on_peak_duration
    if setpoint_type == 'cooling':
        pre_peak_duration = OffsetTimingData.cooling_pre_peak_duration
        on_peak_duration = OffsetTimingData.cooling_on_peak_duration

    if day_type == 'weekday':
        row = on_peak_hour_weekday_dict[month]
    else:
        row = on_peak_hour_weekend_dict[month]
        
    row_morning = list(row.values())[:15]
    row_afternoon = list(row.values())[11:]

    offset_time = peak_time_default()
    if 1 in row_morning:
        on_peak_start_index = row_morning.index(1)
        on_peak_end_index = len(row_morning) - row_morning[::-1].index(1) - 1
        on_peak_mid_index = math.ceil((on_peak_start_index + on_peak_end_index)/2)
        offset_time.peak_start_morning = math.ceil(on_peak_mid_index - on_peak_duration/2)
        offset_time.peak_end_morning = math.ceil(on_peak_mid_index + on_peak_duration/2)-1
        offset_time.pre_peak_start_morning = offset_time.peak_start_morning - pre_peak_duration
    if 1 in row_afternoon:
        on_peak_start_index = row_afternoon.index(1) + 11
        on_peak_end_index = len(row_afternoon) - row_afternoon[::-1].index(1) - 1 + 11
        on_peak_mid_index = math.ceil((on_peak_start_index + on_peak_end_index)/2)
        offset_time.peak_start_afternoon = math.ceil(on_peak_mid_index - on_peak_duration/2)
        offset_time.peak_end_afternoon =  math.ceil(on_peak_mid_index + on_peak_duration/2)-1
        offset_time.pre_peak_start_afternoon = offset_time.peak_start_afternoon - pre_peak_duration
            
    return offset_time

def time_shift(time, num_timsteps_per_hour, shift):
    time_shift = time * num_timsteps_per_hour + shift
    return time_shift

def get_setpoint_offset(year_index, total_indices, on_peak_hour_weekday_dict, on_peak_hour_weekend_dict, shift, setpoint_type):
    """
    offset the setpoint to a certain value given by user inputs,
    the defalut offset value for heating is:
    increase 4F during prepeak time, decrase 4F during on peak time
    the defalut offset value for cooling is:
    decrease 4F during prepeak time, increase 4F during on peak time
    """

    num_timsteps_per_hour = total_indices / 8760
    offset_time = get_prepeak_and_peak_start_end(year_index, total_indices, on_peak_hour_weekday_dict, on_peak_hour_weekend_dict, setpoint_type)

    #To avoid coincidence response, randomly shift the demand response from - 1hour to 1 hour
    for f in fields(offset_time):
        value = getattr(offset_time, f.name)
        value = time_shift(value, num_timsteps_per_hour, shift)
        if isinstance(value, (int, float)):
            setattr(offset_time, f.name, value)
    
    if setpoint_type == 'heating':
        pre_peak_offset = RelativeOffsetData.heating_pre_peak_offset
        on_peak_offset = RelativeOffsetData.heating_on_peak_offset
    if setpoint_type == 'cooling':
        pre_peak_offset = RelativeOffsetData.cooling_pre_peak_offset
        on_peak_offset = RelativeOffsetData.cooling_on_peak_offset

    day_index = int(year_index % (24*num_timsteps_per_hour))    
    if (offset_time.pre_peak_start_morning <= day_index < offset_time.peak_start_morning)\
        or (offset_time.pre_peak_start_afternoon <= day_index < offset_time.peak_start_afternoon):
        setpoint_offset = pre_peak_offset
    elif (offset_time.peak_start_morning <= day_index <= offset_time.peak_end_morning)\
        or (offset_time.peak_start_afternoon <= day_index <= offset_time.peak_end_afternoon):
        setpoint_offset = on_peak_offset
    else:
        setpoint_offset = 0
            
    return setpoint_offset

def get_setpoint_absolute_value(year_index,  total_indices, on_peak_hour_weekday_dict, on_peak_hour_weekend_dict, shift, setpoint_type, setpoint_default):
    """
    set the setpoint to a fixed value given by user inputs
    the default setpoint for heating is:
    80F during prepeak time, 55F during on peak time
    the defalut setpoint for cooling is:
    60F during prepeak time, 80F during on peak time
    """
    num_timsteps_per_hour = total_indices / 8760
    offset_time = get_prepeak_and_peak_start_end(year_index, total_indices, on_peak_hour_weekday_dict, on_peak_hour_weekend_dict, setpoint_type)

    #To avoid coincidence response, randomly shift the demand response from - 1hour to 1 hour
    for f in fields(offset_time):
        value = getattr(offset_time, f.name)
        value = time_shift(value, num_timsteps_per_hour, shift)
        if isinstance(value, (int, float)):
            setattr(offset_time, f.name, value)
    
    if setpoint_type == 'heating':
        pre_peak_setpoint = AbsoluteOffsetData.heating_pre_peak_setpoint
        on_peak_setpoint = AbsoluteOffsetData.heating_on_peak_setpoint
    if setpoint_type == 'cooling':
        pre_peak_setpoint = AbsoluteOffsetData.cooling_pre_peak_setpoint
        on_peak_setpoint = AbsoluteOffsetData.cooling_on_peak_setpoint

    day_index = int(year_index % (24*num_timsteps_per_hour))    
    if (offset_time.pre_peak_start_morning <= day_index < offset_time.peak_start_morning)\
        or (offset_time.pre_peak_start_afternoon <= day_index < offset_time.peak_start_afternoon):
        setpoint_reponse = pre_peak_setpoint
    elif (offset_time.peak_start_morning <= day_index <= offset_time.peak_end_morning)\
        or (offset_time.peak_start_afternoon <= day_index <= offset_time.peak_end_afternoon):
        setpoint_reponse = on_peak_setpoint
    else:
        setpoint_reponse = setpoint_default
            
    return setpoint_reponse

def clip_setpoints(setpoint, setpoint_type):
    """
    control the range of setpoint given by user inputs
    the default range for heating is: 55-80F
    the default range for cooling is: 60-80F
    """

    if setpoint_type == 'heating':
        setpoint_max = RelativeOffsetData.heating_max
        setpoint_min = RelativeOffsetData.heating_min
    elif setpoint_type == 'cooling':
        setpoint_max = RelativeOffsetData.cooling_max
        setpoint_min = RelativeOffsetData.cooling_min
        
    if setpoint > setpoint_max:
        setpoint = setpoint_max
    elif setpoint < setpoint_min:
        setpoint = setpoint_min
    return setpoint

def modify_setpoints(runner, index, total_indices, on_peak_hour_weekday_dict, on_peak_hour_weekend_dict, shift, setpoints: HVACSetpoints):
    if OffsetTypeData.offset_type == relative: # make a setpoint offset compared with the default setpoint
        setpoints.heating_setpoint += get_setpoint_offset(index, total_indices, on_peak_hour_weekday_dict, on_peak_hour_weekend_dict, shift, 'heating')
        setpoints.cooling_setpoint += get_setpoint_offset(index, total_indices, on_peak_hour_weekday_dict, on_peak_hour_weekend_dict, shift, 'cooling')
    elif OffsetTypeData.offset_type == absolute: # set the setpoint to a fixed value
        setpoints.heating_setpoint = get_setpoint_absolute_value(index, total_indices, on_peak_hour_weekday_dict, on_peak_hour_weekend_dict, shift, 'heating', setpoints.heating_setpoint)
        setpoints.cooling_setpoint = get_setpoint_absolute_value(index, total_indices, on_peak_hour_weekday_dict, on_peak_hour_weekend_dict, shift, 'cooling', setpoints.cooling_setpoint)

    setpoints.heating_setpoint = clip_setpoints(setpoints.heating_setpoint, 'heating')
    setpoints.cooling_setpoint = clip_setpoints(setpoints.cooling_setpoint, 'cooling')
    return setpoints


def modify_all_setpoints(runner, multiple_setpoints: List[HVACSetpoints], building_info: BuildingInfo):
    """Modify setpoints based on user arguments."""
    runner.registerInfo("Modifying setpoints ...")
    runner.registerInfo("Values got are")
    runner.registerInfo(f"{OffsetTypeData.offset_type.name}={OffsetTypeData.offset_type.val}")
    runner.registerInfo(f"{RelativeOffsetData.heating_on_peak_offset.name}="
                        f"{RelativeOffsetData.heating_on_peak_offset.val}")
    runner.registerInfo(f"{RelativeOffsetData.cooling_on_peak_offset.name}="
                        f"{RelativeOffsetData.cooling_on_peak_offset.val}")
    runner.registerInfo(f"{RelativeOffsetData.heating_pre_peak_offset.name}="
                        f"{RelativeOffsetData.heating_pre_peak_offset.val}")
    runner.registerInfo(f"{RelativeOffsetData.cooling_pre_peak_offset.name}="
                        f"{RelativeOffsetData.cooling_pre_peak_offset.val}")
    runner.registerInfo(f"{OffsetTimingData.heating_on_peak_duration.name}="
                        f"{OffsetTimingData.heating_on_peak_duration.val}")
    runner.registerInfo(f"{OffsetTimingData.cooling_on_peak_duration.name}="
                        f"{OffsetTimingData.cooling_on_peak_duration.val}")
    runner.registerInfo(f"{OffsetTimingData.heating_pre_peak_duration.name}="
                        f"{OffsetTimingData.heating_pre_peak_duration.val}")
    runner.registerInfo(f"{OffsetTimingData.cooling_pre_peak_duration.name}="
                        f"{OffsetTimingData.cooling_pre_peak_duration.val}")
    runner.registerInfo(f"{AbsoluteOffsetData.cooling_on_peak_setpoint.name}="
                        f"{AbsoluteOffsetData.cooling_on_peak_setpoint.val}")
    runner.registerInfo(f"{AbsoluteOffsetData.cooling_pre_peak_setpoint.name}="
                        f"{AbsoluteOffsetData.cooling_pre_peak_setpoint.val}")
    runner.registerInfo(f"{AbsoluteOffsetData.heating_on_peak_setpoint.name}="
                        f"{AbsoluteOffsetData.heating_on_peak_setpoint.val}")
    runner.registerInfo(f"{AbsoluteOffsetData.heating_pre_peak_setpoint.name}="
                        f"{AbsoluteOffsetData.heating_pre_peak_setpoint.val}")
    runner.registerInfo(f"state={building_info.state}")
    # Modify the setpoint using above data
    ## on peak hour##
    on_peak_hour_weekday = pd.read_csv(f"on_peak_hour/{building_info.state}_weekday_on_peak.csv") # csv file is generated from on_peak_hour_generation.py
    on_peak_hour_weekend = pd.read_csv(f"on_peak_hour/{building_info.state}_weekend_on_peak.csv") # csv file is generated from on_peak_hour_generation.py
    on_peak_hour_weekday_dict = on_peak_hour_weekday.set_index('month').transpose().to_dict()
    on_peak_hour_weekend_dict = on_peak_hour_weekend.set_index('month').transpose().to_dict()

    #To avoid coincidence response, randomly shift the demand response from - 1hour to 1 hour
    total_indices = len(multiple_setpoints)
    num_timsteps_per_hour = total_indices / 8760
    shift = np.random.randint(-num_timsteps_per_hour, num_timsteps_per_hour, 1)[0]
    
    modified_setpoints = []
    for setpoints in multiple_setpoints:
        index = 0
        # Modify the setpoints
        modified_setpoints.append(modify_setpoints(runner, index, total_indices, on_peak_hour_weekday_dict, on_peak_hour_weekend_dict, shift, setpoints=setpoints))
        index += 1
    return True
