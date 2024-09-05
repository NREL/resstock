from input_helper import OffsetType, BuildingInfo, Inputs
from typing import List, Tuple, TypedDict, Dict
import pandas as pd
import numpy as np
import random
import math
from datetime import datetime, timedelta
from dataclasses import dataclass, fields
import os
import openstudio


class PeakTimes(TypedDict):
    pre_peak_start: float
    peak_start: float
    peak_end: float


class PeakHours(TypedDict):
    weekday_peak_hr: Dict[int, float]
    weekend_peak_hr: Dict[int, float]


class HVACSetpoints:
    def __init__(self, os_runner: openstudio.measure.OSRunner,
                 inputs: Inputs,
                 building_info: BuildingInfo,
                 cooling_setpoints: List[int],
                 heating_setpoints: List[int]):

        self.runner = os_runner
        self.sim_year = building_info.sim_year
        self.building_info = building_info
        self.cooling_setpoints = cooling_setpoints
        self.heating_setpoints = heating_setpoints
        self.total_indices = len(cooling_setpoints)
        assert len(cooling_setpoints) == len(heating_setpoints)
        self.num_timsteps_per_hour = self.total_indices // 8760
        self.shift = self._get_random_shift_amount(inputs=inputs)
        self.peak_hours_dict: PeakHours = self.get_peak_periods(building_info)
        self.log_inputs(inputs=inputs)

    def get_peak_periods(self, building_info):
        current_dir = os.path.dirname(os.path.realpath(__file__))
        peak_hours_df = pd.read_csv(f"{current_dir}/peak_hours/peak_hours.csv")
        peak_hours_df = peak_hours_df[peak_hours_df['state'] == building_info.state]
        if len(peak_hours_df) != 12:
            raise ValueError(f"No data from {building_info.state}")
        peak_hours_df = peak_hours_df.set_index('month').drop(columns=['state'])
        return peak_hours_df.to_dict()

    def _get_random_shift_amount(self, inputs: Inputs):
        assert inputs.offset_timing.random_timing_shift.val is not None, "Timing shift not set"
        min_shift = round(-self.num_timsteps_per_hour * inputs.offset_timing.random_timing_shift.val)
        max_shift = round(self.num_timsteps_per_hour * inputs.offset_timing.random_timing_shift.val)
        return random.randint(min_shift, max_shift)

    def _get_month_day(self, indx) -> Tuple[int, str]:
        """
        for each setpoint temperature,
        get the month and day type (weekday for weekend) that it belongs.
        the year number need to modify if the simulation year is not 2007.
        """

        start_of_year = datetime(self.sim_year, 1, 1)
        indx_datetime = start_of_year + timedelta(hours=indx / self.num_timsteps_per_hour)
        if indx_datetime.weekday() < 5:
            day_type = 'weekday'
        else:
            day_type = 'weekend'
        return indx_datetime.month, day_type

    def _get_offset_time(self, inputs: Inputs, index, setpoint_type):
        """
        determine the prepeak start time, on peak start and end time,
        in the unit of hour
        """

        month, day_type = self._get_month_day(index)

        if setpoint_type == 'heating':
            pre_peak_duration_hr = inputs.offset_timing.heating_pre_peak_duration.val
            on_peak_duration_hr = inputs.offset_timing.heating_on_peak_duration.val
        elif setpoint_type == 'cooling':
            pre_peak_duration_hr = inputs.offset_timing.cooling_pre_peak_duration.val
            on_peak_duration_hr = inputs.offset_timing.cooling_on_peak_duration.val
        else:
            raise ValueError(f"setpoint type {setpoint_type} is not supported")

        if day_type == 'weekday':
            peak_indx = round(self.peak_hours_dict['weekday_peak_hr'][month] * self.num_timsteps_per_hour)
        elif day_type == 'weekend':
            peak_indx = round(self.peak_hours_dict['weekend_peak_hr'][month] * self.num_timsteps_per_hour)
        else:
            raise ValueError(f"day type {day_type} is not supported")

        assert pre_peak_duration_hr is not None, "Pre-peak duration not set"
        assert on_peak_duration_hr is not None, "On-peak duration not set"

        peak_times: PeakTimes = {
            'peak_start': peak_indx,
            'peak_end': peak_indx + round(on_peak_duration_hr * self.num_timsteps_per_hour),
            'pre_peak_start': peak_indx - round(pre_peak_duration_hr * self.num_timsteps_per_hour)
        }
        peak_times['peak_end'] = peak_times['peak_end'] % (self.num_timsteps_per_hour * 24)
        peak_times['pre_peak_start'] = peak_times['pre_peak_start'] % (self.num_timsteps_per_hour * 24)
        return peak_times

    def _shift_peak_times(self, peak_times: PeakTimes, shift: int):
        peak_times['peak_start'] = self._time_shift(peak_times['peak_start'], shift)
        peak_times['peak_end'] = self._time_shift(peak_times['peak_end'], shift)
        peak_times['pre_peak_start'] = self._time_shift(peak_times['pre_peak_start'], shift)
        return peak_times

    def _time_shift(self, indx_in_day, shift):
        return (indx_in_day + shift) % (self.num_timsteps_per_hour * 24)

    def _get_setpoint_offset(self, inputs: Inputs, index_in_year, setpoint_type) -> int:
        """
        offset the setpoint to a certain value given by user inputs,
        the defalut offset value for heating is:
        increase 4F during prepeak time, decrase 4F during on peak time
        the defalut offset value for cooling is:
        decrease 4F during prepeak time, increase 4F during on peak time
        """

        offset_time = self._get_offset_time(inputs, index_in_year, setpoint_type)
        offset_time = self._shift_peak_times(offset_time, self.shift)

        if setpoint_type == 'heating':
            pre_peak_offset = inputs.relative_offset.heating_pre_peak_offset.val
            on_peak_offset = inputs.relative_offset.heating_on_peak_offset.val
        elif setpoint_type == 'cooling':
            pre_peak_offset = inputs.relative_offset.cooling_pre_peak_offset.val
            on_peak_offset = inputs.relative_offset.cooling_on_peak_offset.val
        else:
            raise ValueError(f"setpoint type {setpoint_type} is not supported")

        assert pre_peak_offset is not None, "Pre-peak offset not set"
        assert on_peak_offset is not None, "On-peak offset not set"

        index_in_day = int(index_in_year % (24 * self.num_timsteps_per_hour))
        if offset_time['pre_peak_start'] <= index_in_day < offset_time['peak_start']:
            setpoint_offset = pre_peak_offset
        elif offset_time['peak_start'] <= index_in_day < offset_time['peak_end']:
            setpoint_offset = on_peak_offset
        else:
            setpoint_offset = 0

        return setpoint_offset

    def _get_setpoint_absolute_value(self, inputs: Inputs, index_in_year, setpoint_type, existing_setpoint):
        """
        set the setpoint to a fixed value given by user inputs
        the default setpoint for heating is:
        80F during prepeak time, 55F during on peak time
        the defalut setpoint for cooling is:
        60F during prepeak time, 80F during on peak time
        """
        offset_time = self._get_offset_time(inputs, index_in_year, setpoint_type)

        if setpoint_type == 'heating':
            pre_peak_setpoint = inputs.absolute_offset.heating_pre_peak_setpoint.val
            on_peak_setpoint = inputs.absolute_offset.heating_on_peak_setpoint.val
        elif setpoint_type == 'cooling':
            pre_peak_setpoint = inputs.absolute_offset.cooling_pre_peak_setpoint.val
            on_peak_setpoint = inputs.absolute_offset.cooling_on_peak_setpoint.val
        else:
            raise ValueError(f"setpoint type {setpoint_type} is not supported")

        assert pre_peak_setpoint is not None, "Pre-peak offset not set"
        assert on_peak_setpoint is not None, "On-peak offset not set"

        index_in_day = int(index_in_year % (24 * self.num_timsteps_per_hour))
        if offset_time['pre_peak_start'] <= index_in_day < offset_time['peak_start']:
            setpoint_reponse = pre_peak_setpoint
        elif offset_time['peak_start'] <= index_in_day < offset_time['peak_end']:
            setpoint_reponse = on_peak_setpoint
        else:
            setpoint_reponse = existing_setpoint

        return setpoint_reponse

    def _clip_setpoints(self, inputs: Inputs, setpoint: int, setpoint_type):
        """
        control the range of setpoint given by user inputs
        the default range for heating is: 55-80F
        the default range for cooling is: 60-80F
        """

        if setpoint_type == 'heating':
            setpoint_max = inputs.relative_offset.heating_max.val
            setpoint_min = inputs.relative_offset.heating_min.val
        elif setpoint_type == 'cooling':
            setpoint_max = inputs.relative_offset.cooling_max.val
            setpoint_min = inputs.relative_offset.cooling_min.val
        else:
            raise ValueError(f"setpoint type {setpoint_type} is not supported")
        assert setpoint_max is not None, "Max setpoint not set"
        assert setpoint_min is not None, "Min setpoint not set"

        if setpoint > setpoint_max:
            #self.runner.registerWarning(f"Setpoint {setpoint} is greater than max setpoint {setpoint_max}")
            setpoint = setpoint_max
        elif setpoint < setpoint_min:
            #self.runner.registerWarning(f"Setpoint {setpoint} is less than min setpoint {setpoint_min}")
            setpoint = setpoint_min
        else:
            setpoint = setpoint
        return setpoint

    def _get_updated_setpoint(self, inputs: Inputs, index_in_year, setpoint_type):
        if setpoint_type == 'heating':
            existing_setpoint = self.heating_setpoints[index_in_year]
        else:
            existing_setpoint = self.cooling_setpoints[index_in_year]
        if inputs.offset_type.val == OffsetType.relative:  # make a setpoint offset compared with the default setpoint
            new_setpoint = existing_setpoint + self._get_setpoint_offset(inputs, index_in_year, setpoint_type)
        elif inputs.offset_type.val == OffsetType.absolute:  # set the setpoint to a fixed value
            self.runner.registerWarning(f"Existing heating setpoint: {existing_setpoint}")
            new_setpoint = self._get_setpoint_absolute_value(inputs, index_in_year, setpoint_type, existing_setpoint)
        else:
            raise ValueError(f"offset type {inputs.offset_type.val} is not supported")
        new_setpoint = self._clip_setpoints(inputs, new_setpoint, setpoint_type)
        return new_setpoint

    def _get_modified_setpoints(self, inputs: Inputs):
        heating_setpoints = self.heating_setpoints.copy()
        cooling_setpoints = self.cooling_setpoints.copy()
        for index in range(self.total_indices):
            heating_setpoints[index] = self._get_updated_setpoint(inputs, index, 'heating')
            cooling_setpoints[index] = self._get_updated_setpoint(inputs, index, 'cooling')
        return {'heating_setpoints': heating_setpoints, 'cooling_setpoints': cooling_setpoints}

    def log_inputs(self, inputs: Inputs):
        """Modify setpoints based on user arguments."""
        if not self.runner:
            return
        self.runner.registerInfo("Modifying setpoints ...")
        self.runner.registerInfo("Values got are")
        self.runner.registerInfo(f"{inputs.offset_type.name}={inputs.offset_type.val}")
        self.runner.registerInfo(f"{inputs.relative_offset.heating_on_peak_offset.name}="
                            f"{inputs.relative_offset.heating_on_peak_offset.val}")
        self.runner.registerInfo(f"{inputs.relative_offset.cooling_on_peak_offset.name}="
                            f"{inputs.relative_offset.cooling_on_peak_offset.val}")
        self.runner.registerInfo(f"{inputs.relative_offset.heating_pre_peak_offset.name}="
                            f"{inputs.relative_offset.heating_pre_peak_offset.val}")
        self.runner.registerInfo(f"{inputs.relative_offset.cooling_pre_peak_offset.name}="
                            f"{inputs.relative_offset.cooling_pre_peak_offset.val}")
        self.runner.registerInfo(f"{inputs.offset_timing.heating_on_peak_duration.name}="
                            f"{inputs.offset_timing.heating_on_peak_duration.val}")
        self.runner.registerInfo(f"{inputs.offset_timing.cooling_on_peak_duration.name}="
                            f"{inputs.offset_timing.cooling_on_peak_duration.val}")
        self.runner.registerInfo(f"{inputs.offset_timing.heating_pre_peak_duration.name}="
                            f"{inputs.offset_timing.heating_pre_peak_duration.val}")
        self.runner.registerInfo(f"{inputs.offset_timing.cooling_pre_peak_duration.name}="
                            f"{inputs.offset_timing.cooling_pre_peak_duration.val}")
        self.runner.registerInfo(f"{inputs.absolute_offset.cooling_on_peak_setpoint.name}="
                            f"{inputs.absolute_offset.cooling_on_peak_setpoint.val}")
        self.runner.registerInfo(f"{inputs.absolute_offset.cooling_pre_peak_setpoint.name}="
                            f"{inputs.absolute_offset.cooling_pre_peak_setpoint.val}")
        self.runner.registerInfo(f"{inputs.absolute_offset.heating_on_peak_setpoint.name}="
                            f"{inputs.absolute_offset.heating_on_peak_setpoint.val}")
        self.runner.registerInfo(f"{inputs.absolute_offset.heating_pre_peak_setpoint.name}="
                            f"{inputs.absolute_offset.heating_pre_peak_setpoint.val}")
        self.runner.registerInfo(f"state={self.building_info.state}")
