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

    # def test_get_prepeak_and_peak_start_end_summer(self):
    #     print('test_get_prepeak_and_peak_start_end_summer')
    #     offset_time = setpoint.get_prepeak_and_peak_start_end(5000, 8760, self.on_peak_hour_weekday_dict, self.on_peak_hour_weekend_dict, 'cooling')
    #     self.assertEqual(offset_time.pre_peak_start_afternoon, 11)
    #     self.assertEqual(offset_time.peak_start_afternoon, 15)
    #     self.assertEqual(offset_time.peak_end_afternoon, 18)

    # def test_time_shift(self):
    #     print('test_time_shift')
    #     offset_time = setpoint.get_prepeak_and_peak_start_end(2, 8760, self.on_peak_hour_weekday_dict, self.on_peak_hour_weekend_dict, 'heating')
    #     for f in fields(offset_time):
    #         value = getattr(offset_time, f.name)
    #         value = setpoint.time_shift(value, 1, 1)
    #         if isinstance(value, (int, float)):
    #             setattr(offset_time, f.name, value)
    #     self.assertEqual(offset_time.pre_peak_start_morning, 2)
    #     self.assertEqual(offset_time.peak_start_morning, 6)
    #     self.assertEqual(offset_time.peak_end_morning, 9)
    #     self.assertEqual(offset_time.pre_peak_start_afternoon, 14)
    #     self.assertEqual(offset_time.peak_start_afternoon, 18)
    #     self.assertEqual(offset_time.peak_end_afternoon, 21)

    # def test_get_setpoint_offset_heating(self):
    #     print('test_get_setpoint_offset_heating')
    #     setpoint_offset = setpoint.get_setpoint_offset(3, 8760, self.on_peak_hour_weekday_dict, self.on_peak_hour_weekend_dict, 0, 'heating')
    #     self.assertEqual(setpoint_offset, 4)
    #     setpoint_offset = setpoint.get_setpoint_offset(7, 8760, self.on_peak_hour_weekday_dict, self.on_peak_hour_weekend_dict, 0, 'heating')
    #     self.assertEqual(setpoint_offset, -4)

    # def test_get_setpoint_offset_cooling(self):
    #     print('test_get_setpoint_offset_cooling')
    #     setpoint_offset = setpoint.get_setpoint_offset(2916, 8760, self.on_peak_hour_weekday_dict, self.on_peak_hour_weekend_dict, 0, 'cooling')
    #     self.assertEqual(setpoint_offset, -4)
    #     setpoint_offset = setpoint.get_setpoint_offset(2920, 8760, self.on_peak_hour_weekday_dict, self.on_peak_hour_weekend_dict, 0, 'cooling')
    #     self.assertEqual(setpoint_offset, 4)

    # def test_get_setpoint_absolute_value_heating(self):
    #     print('test_get_setpoint_absolute_value_heating')
    #     setpoint_reponse = setpoint.get_setpoint_absolute_value(3, 8760, self.on_peak_hour_weekday_dict, self.on_peak_hour_weekend_dict, 0, 'heating', 70)
    #     self.assertEqual(setpoint_reponse, 80)
    #     setpoint_reponse = setpoint.get_setpoint_absolute_value(7, 8760, self.on_peak_hour_weekday_dict, self.on_peak_hour_weekend_dict, 0, 'heating', 70)
    #     self.assertEqual(setpoint_reponse, 55)
    #     setpoint_reponse = setpoint.get_setpoint_absolute_value(10, 8760, self.on_peak_hour_weekday_dict, self.on_peak_hour_weekend_dict, 0, 'heating', 70)
    #     self.assertEqual(setpoint_reponse, 70)

    # def test_get_setpoint_absolute_value_cooling(self):
    #     print('test_get_setpoint_absolute_value_cooling')
    #     setpoint_reponse = setpoint.get_setpoint_absolute_value(2916, 8760, self.on_peak_hour_weekday_dict, self.on_peak_hour_weekend_dict, 0, 'cooling', 70)
    #     self.assertEqual(setpoint_reponse, 60)
    #     setpoint_reponse = setpoint.get_setpoint_absolute_value(2920, 8760, self.on_peak_hour_weekday_dict, self.on_peak_hour_weekend_dict, 0, 'cooling', 70)
    #     self.assertEqual(setpoint_reponse, 80)
    #     setpoint_reponse = setpoint.get_setpoint_absolute_value(2924, 8760, self.on_peak_hour_weekday_dict, self.on_peak_hour_weekend_dict, 0, 'cooling', 70)
    #     self.assertEqual(setpoint_reponse, 70)

    # def test_clip_setpoints(self):
    #     print('test_clip_setpoints')
    #     self.assertEqual(setpoint.clip_setpoints(90, 'heating'), 80)
    #     self.assertEqual(setpoint.clip_setpoints(70, 'heating'), 70)
    #     self.assertEqual(setpoint.clip_setpoints(40, 'heating'), 55)
    #     self.assertEqual(setpoint.clip_setpoints(90, 'cooling'), 80)
    #     self.assertEqual(setpoint.clip_setpoints(70, 'cooling'), 70)
    #     self.assertEqual(setpoint.clip_setpoints(40, 'cooling'), 60)