from typing import List
from dataclasses import dataclass


@dataclass(frozen=True)
class HVACSetpoints:
    heating_setpoint: List[float]
    cooling_setpoint: List[float]
