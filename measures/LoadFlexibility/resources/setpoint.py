from input_helper import OffsetTypeData, OffsetTimingData, RelativeOffsetData, AbsoluteOffsetData
from typing import List
from setpoint_helper import HVACSetpoints, BuildingInfo


def modify_setpoints(runner, setpoints: HVACSetpoints, building_info: BuildingInfo):
    pass


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
    modified_setpoints = []
    for setpoints in multiple_setpoints:
        # Modify the setpoints
        modified_setpoints.append(modify_setpoints(runner, setpoints=setpoints, building_info=building_info))
    return True
