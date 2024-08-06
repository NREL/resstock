import unittest
import pandas as pd
from dataclasses import fields
from pathlib import Path
import sys
# update python path to include parent folder
CURRENT_DIR_PATH = Path(__file__).parent.absolute()
sys.path.insert(0, str(CURRENT_DIR_PATH.parent)+'/resources')
import setpoint

class Testsetpoint(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        print('setUpClass')

    @classmethod
    def tearDownClass(cls):
        print('tearDownClass')

    def setUp(self):
        print('setUp')
        state = 'CO'
        on_peak_hour_weekday = pd.read_csv(f"on_peak_hour/{state}_weekday_on_peak.csv") 
        on_peak_hour_weekend = pd.read_csv(f"on_peak_hour/{state}_weekend_on_peak.csv") 
        self.on_peak_hour_weekday_dict = on_peak_hour_weekday.set_index('month').transpose().to_dict()
        self.on_peak_hour_weekend_dict = on_peak_hour_weekend.set_index('month').transpose().to_dict()

    def tearDown(self):
        print('tearDown')

    def test_get_month_day(self):
        print('test_get_month_day')
        self.assertEqual(setpoint.get_month_day(8755, 8760), (12, 'weekday'))
        self.assertEqual(setpoint.get_month_day(2, 8760), (1, 'weekday'))
   
    def test_get_prepeak_and_peak_start_end_winter(self):
        print('test_get_prepeak_and_peak_start_end_winter')
        offset_time = setpoint.get_prepeak_and_peak_start_end(2, 8760, self.on_peak_hour_weekday_dict, self.on_peak_hour_weekend_dict, 'heating')
        self.assertEqual(offset_time.pre_peak_start_morning, 1)
        self.assertEqual(offset_time.peak_start_morning, 5)
        self.assertEqual(offset_time.peak_end_morning, 8)
        self.assertEqual(offset_time.pre_peak_start_afternoon, 13)
        self.assertEqual(offset_time.peak_start_afternoon, 17)
        self.assertEqual(offset_time.peak_end_afternoon, 20)
    
    def test_get_prepeak_and_peak_start_end_summer(self):
        print('test_get_prepeak_and_peak_start_end_summer')
        offset_time = setpoint.get_prepeak_and_peak_start_end(5000, 8760, self.on_peak_hour_weekday_dict, self.on_peak_hour_weekend_dict, 'cooling')
        self.assertEqual(offset_time.pre_peak_start_afternoon, 11)
        self.assertEqual(offset_time.peak_start_afternoon, 15)
        self.assertEqual(offset_time.peak_end_afternoon, 18)
    
    def test_time_shift(self):
        print('test_time_shift')
        offset_time = setpoint.get_prepeak_and_peak_start_end(2, 8760, self.on_peak_hour_weekday_dict, self.on_peak_hour_weekend_dict, 'heating')
        for f in fields(offset_time):
            value = getattr(offset_time, f.name)
            value = setpoint.time_shift(value, 1, 1)
            if isinstance(value, (int, float)):
                setattr(offset_time, f.name, value)
        self.assertEqual(offset_time.pre_peak_start_morning, 2)
        self.assertEqual(offset_time.peak_start_morning, 6)
        self.assertEqual(offset_time.peak_end_morning, 9)
        self.assertEqual(offset_time.pre_peak_start_afternoon, 14)
        self.assertEqual(offset_time.peak_start_afternoon, 18)
        self.assertEqual(offset_time.peak_end_afternoon, 21)
    
    def test_get_setpoint_offset_heating(self):
        print('test_get_setpoint_offset_heating')
        setpoint_offset = setpoint.get_setpoint_offset(3, 8760, self.on_peak_hour_weekday_dict, self.on_peak_hour_weekend_dict, 0, 'heating')
        self.assertEqual(setpoint_offset, 4)
        setpoint_offset = setpoint.get_setpoint_offset(7, 8760, self.on_peak_hour_weekday_dict, self.on_peak_hour_weekend_dict, 0, 'heating')
        self.assertEqual(setpoint_offset, -4)
    
    def test_get_setpoint_offset_cooling(self):
        print('test_get_setpoint_offset_cooling')
        setpoint_offset = setpoint.get_setpoint_offset(2916, 8760, self.on_peak_hour_weekday_dict, self.on_peak_hour_weekend_dict, 0, 'cooling')
        self.assertEqual(setpoint_offset, -4)
        setpoint_offset = setpoint.get_setpoint_offset(2920, 8760, self.on_peak_hour_weekday_dict, self.on_peak_hour_weekend_dict, 0, 'cooling')
        self.assertEqual(setpoint_offset, 4)
    
    def test_get_setpoint_absolute_value_heating(self):
        print('test_get_setpoint_absolute_value_heating')
        setpoint_reponse = setpoint.get_setpoint_absolute_value(3, 8760, self.on_peak_hour_weekday_dict, self.on_peak_hour_weekend_dict, 0, 'heating', 70)
        self.assertEqual(setpoint_reponse, 80)
        setpoint_reponse = setpoint.get_setpoint_absolute_value(7, 8760, self.on_peak_hour_weekday_dict, self.on_peak_hour_weekend_dict, 0, 'heating', 70)
        self.assertEqual(setpoint_reponse, 55)
        setpoint_reponse = setpoint.get_setpoint_absolute_value(10, 8760, self.on_peak_hour_weekday_dict, self.on_peak_hour_weekend_dict, 0, 'heating', 70)
        self.assertEqual(setpoint_reponse, 70)
    
    def test_get_setpoint_absolute_value_cooling(self):
        print('test_get_setpoint_absolute_value_cooling')
        setpoint_reponse = setpoint.get_setpoint_absolute_value(2916, 8760, self.on_peak_hour_weekday_dict, self.on_peak_hour_weekend_dict, 0, 'cooling', 70)
        self.assertEqual(setpoint_reponse, 60)
        setpoint_reponse = setpoint.get_setpoint_absolute_value(2920, 8760, self.on_peak_hour_weekday_dict, self.on_peak_hour_weekend_dict, 0, 'cooling', 70)
        self.assertEqual(setpoint_reponse, 80)
        setpoint_reponse = setpoint.get_setpoint_absolute_value(2924, 8760, self.on_peak_hour_weekday_dict, self.on_peak_hour_weekend_dict, 0, 'cooling', 70)
        self.assertEqual(setpoint_reponse, 70)
    
    def test_clip_setpoints(self):
        print('test_clip_setpoints')
        self.assertEqual(setpoint.clip_setpoints(90, 'heating'), 80)
        self.assertEqual(setpoint.clip_setpoints(70, 'heating'), 70)
        self.assertEqual(setpoint.clip_setpoints(40, 'heating'), 55)
        self.assertEqual(setpoint.clip_setpoints(90, 'cooling'), 80)
        self.assertEqual(setpoint.clip_setpoints(70, 'cooling'), 70)
        self.assertEqual(setpoint.clip_setpoints(40, 'cooling'), 60)

if __name__ == '__main__':
    unittest.main()