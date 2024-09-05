import unittest
import pandas as pd
from dataclasses import fields
from pathlib import Path
import sys
import pytest
# update python path to include parent folder
CURRENT_DIR_PATH = Path(__file__).parent.absolute()
sys.path.insert(0, str(CURRENT_DIR_PATH.parent / 'resources'))
from setpoint import HVACSetpoints
from input_helper import BuildingInfo, OffsetTimingData, get_input_from_dict
sys.path.pop(0)

DEFAULT_ARGS = {'cooling_max': 80,
                'cooling_min': 60,
                'cooling_on_peak_duration': 4,
                'cooling_on_peak_offset': 4,
                'cooling_on_peak_setpoint': 80,
                'cooling_pre_peak_duration': 4,
                'cooling_pre_peak_offset': 4,
                'cooling_pre_peak_setpoint': 60,
                'heating_max': 80,
                'heating_min': 55,
                'heating_on_peak_duration': 4,
                'heating_on_peak_offset': 4,
                'heating_on_peak_setpoint': 55,
                'heating_pre_peak_duration': 4,
                'heating_pre_peak_offset': 4,
                'heating_pre_peak_setpoint': 80,
                'offset_type': 'relative',
                'random_timing_shift': 1.0,
                'upgrade_name': 'None'}

class Testsetpoint:

    def setup_method(self, method):
        print('setUp')
        self.peak_hours = pd.read_csv(CURRENT_DIR_PATH / "peak_hours.csv")
        example_setpoints = pd.read_csv(CURRENT_DIR_PATH / 'example_setpoints.csv')
        inputs = get_input_from_dict(DEFAULT_ARGS)
        self.hvac_setpoints = HVACSetpoints(os_runner=None,
                                            building_info=BuildingInfo(sim_year=2025, state='CO'),
                                            inputs=inputs,
                                            heating_setpoints=example_setpoints['heating_setpoints'].tolist(),
                                            cooling_setpoints=example_setpoints['cooling_setpoints'].tolist())

    def test_get_month_day(self):
        print('test_get_month_day')
        assert self.hvac_setpoints._get_month_day(0) == (1, 'weekday')
        # 2025 Jan 1 is wednesday. 3 * 24 + 1 should be saturday
        assert self.hvac_setpoints._get_month_day(3 * 24 + 1) == (1, 'weekend')
        assert self.hvac_setpoints._get_month_day(8755) == (12, 'weekday')
        assert self.hvac_setpoints._get_month_day(8755) == (12, 'weekday')
    
    def test_shift_peak_times(self):
        print('test_shift_peak_times')
        peak_times = {
            'peak_start': 19,
            'peak_end': 22,
            'pre_peak_start': 15
        }
        peak_times_shift = self.hvac_setpoints._shift_peak_times(peak_times, 2)
        assert peak_times_shift['peak_start'] == 21
        assert peak_times_shift['peak_end'] == 0
        assert peak_times_shift['pre_peak_start'] == 17

    @pytest.mark.parametrize("max_shift_amount", [0.25, 0.5, 1, 2])
    def test_random_shift(self, max_shift_amount):
        new_args = DEFAULT_ARGS.copy()
        # shift_amount = 0.25
        new_args['random_timing_shift'] = max_shift_amount
        inputs = get_input_from_dict(new_args)
        max_shift = float('-inf')
        min_shift = float('inf')
        for i in range(20):
            shift_amount = self.hvac_setpoints._get_random_shift_amount(inputs)
            assert round(-max_shift_amount) <= shift_amount <= round(max_shift_amount)
            max_shift = max(max_shift, shift_amount)
            min_shift = min(min_shift, shift_amount)
        assert max_shift == round(max_shift_amount)
        assert min_shift == round(-max_shift_amount)

    @pytest.mark.parametrize("setpoint_type", ['heating', 'cooling'])
    def test_get_offset_time(self, setpoint_type):
        print('test_get_offset_time')
        new_args = DEFAULT_ARGS.copy()
        inputs = get_input_from_dict(new_args)
        peak_times = self.hvac_setpoints._get_offset_time(inputs, 1, setpoint_type=setpoint_type)
        assert peak_times['peak_start'] == 19
        assert peak_times['peak_end'] == 23
        assert peak_times['pre_peak_start'] == 15

        new_args[f'{setpoint_type}_on_peak_duration'] = 5
        new_args[f'{setpoint_type}_pre_peak_duration'] = 5
        inputs = get_input_from_dict(new_args)
        peak_times = self.hvac_setpoints._get_offset_time(inputs, 1, setpoint_type=setpoint_type)
        assert peak_times['peak_start'] == 19
        assert peak_times['peak_end'] == 0
        assert peak_times['pre_peak_start'] == 14

    @pytest.mark.parametrize("setpoint_type", ['heating'])
    def test_get_setpoint_offset(self, setpoint_type):
        print('test_get_setpoint_offset_heating')
        new_args = DEFAULT_ARGS.copy()
        inputs = get_input_from_dict(new_args)
        print('no_offset')
        setpoint_offset = self.hvac_setpoints._get_setpoint_offset(inputs, 1, setpoint_type=setpoint_type)
        assert setpoint_offset == 0
        print('pre_peak_offset')
        setpoint_offset = self.hvac_setpoints._get_setpoint_offset(inputs, 16, setpoint_type=setpoint_type)
        assert setpoint_offset == new_args['heating_pre_peak_offset']
        print('peak_offset')
        setpoint_offset = self.hvac_setpoints._get_setpoint_offset(inputs, 19, setpoint_type=setpoint_type)
        assert setpoint_offset == new_args['heating_on_peak_offset']

    @pytest.mark.parametrize("setpoint_type", ['cooling'])
    def test_get_setpoint_offset(self, setpoint_type):
        print('test_get_setpoint_offset_cooling')
        new_args = DEFAULT_ARGS.copy()
        inputs = get_input_from_dict(new_args)
        print('no_offset')
        setpoint_offset = self.hvac_setpoints._get_setpoint_offset(inputs, 1, setpoint_type=setpoint_type)
        assert setpoint_offset == 0
        print('pre_peak_offset')
        setpoint_offset = self.hvac_setpoints._get_setpoint_offset(inputs, 16, setpoint_type=setpoint_type)
        assert setpoint_offset == new_args['cooling_pre_peak_offset']
        print('peak_offset')
        setpoint_offset = self.hvac_setpoints._get_setpoint_offset(inputs, 19, setpoint_type=setpoint_type)
        assert setpoint_offset == new_args['cooling_on_peak_offset']

    
    @pytest.mark.parametrize("setpoint_type", ['heating'])
    def test_get_setpoint_absolute_value(self, setpoint_type):
        print('test_get_setpoint_absolute_value_heating')
        new_args = DEFAULT_ARGS.copy()
        inputs = get_input_from_dict(new_args)
        print('no_offset')
        setpoint_reponse = self.hvac_setpoints._get_setpoint_absolute_value(inputs, 1, setpoint_type=setpoint_type, existing_setpoint=72)
        assert setpoint_reponse == 72
        print('pre_peak_setpoint')
        setpoint_reponse = self.hvac_setpoints._get_setpoint_absolute_value(inputs, 16, setpoint_type=setpoint_type, existing_setpoint=72)
        assert setpoint_reponse == 80
        print('peak_setpoint')
        setpoint_reponse = self.hvac_setpoints._get_setpoint_absolute_value(inputs, 19, setpoint_type=setpoint_type, existing_setpoint=72)
        assert setpoint_reponse == 55
    
    @pytest.mark.parametrize("setpoint_type", ['cooling'])
    def test_get_setpoint_absolute_value(self, setpoint_type):
        print('test_get_setpoint_absolute_value_cooling')
        new_args = DEFAULT_ARGS.copy()
        inputs = get_input_from_dict(new_args)
        print('no_offset')
        setpoint_reponse = self.hvac_setpoints._get_setpoint_absolute_value(inputs, 1, setpoint_type=setpoint_type, existing_setpoint=72)
        assert setpoint_reponse == 72
        print('pre_peak_setpoint')
        setpoint_reponse = self.hvac_setpoints._get_setpoint_absolute_value(inputs, 16, setpoint_type=setpoint_type, existing_setpoint=72)
        assert setpoint_reponse == 60
        print('peak_setpoint')
        setpoint_reponse = self.hvac_setpoints._get_setpoint_absolute_value(inputs, 19, setpoint_type=setpoint_type, existing_setpoint=72)
        assert setpoint_reponse == 80
    
    @pytest.mark.parametrize("setpoint_type", ['heating'])
    def test_clip_setpoints(self, setpoint_type):
        print('test_clip_setpoints_heating')
        new_args = DEFAULT_ARGS.copy()
        inputs = get_input_from_dict(new_args)
        print('within range')
        setpoint = self.hvac_setpoints._clip_setpoints(inputs, 70, setpoint_type=setpoint_type)
        assert setpoint == 70
        print('Setpoint is less than min setpoint')
        setpoint = self.hvac_setpoints._clip_setpoints(inputs, 40, setpoint_type=setpoint_type)
        assert setpoint == new_args['heating_min']
        print('Setpoint is greater than max setpoint')
        setpoint = self.hvac_setpoints._clip_setpoints(inputs, 90, setpoint_type=setpoint_type)
        assert setpoint == new_args['heating_max']
    
    @pytest.mark.parametrize("setpoint_type", ['cooling'])
    def test_clip_setpoints(self, setpoint_type):
        print('test_clip_setpoints_cooling')
        new_args = DEFAULT_ARGS.copy()
        inputs = get_input_from_dict(new_args)
        print('within range')
        setpoint = self.hvac_setpoints._clip_setpoints(inputs, 70, setpoint_type=setpoint_type)
        assert setpoint == 70
        print('Setpoint is less than min setpoint')
        setpoint = self.hvac_setpoints._clip_setpoints(inputs, 40, setpoint_type=setpoint_type)
        assert setpoint == new_args['cooling_min']
        print('Setpoint is greater than max setpoint')
        setpoint = self.hvac_setpoints._clip_setpoints(inputs, 90, setpoint_type=setpoint_type)
        assert setpoint == new_args['cooling_max']
