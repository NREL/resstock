from dataclasses import dataclass, field
import openstudio
from typing import Optional
from typing import TypeVar, Generic, List
import dataclasses
T = TypeVar('T')


class OffsetType:
    relative: str = 'relative'
    absolute: str = 'absolute'


@dataclass(frozen=True)
class BuildingInfo:
    state: str = "CO"
    sim_year: int = 2019


@dataclass(frozen=True)
class Argument(Generic[T]):
    """
    This class defines both the input argument to the measure as well as the value passed.
    The measure input argument is obtained using the getOSArgument which is used by the measure's
    argument method.

    During the run, the value passed to the measure is obtained from the runner and the val
    attribute is set using the set_val method. This method ensures that the value is set only once.
    """
    name: str
    type: type
    displayname: Optional[str] = None
    description: Optional[str] = None
    required: bool = False
    modelDependent: bool = False
    choices: tuple = field(default_factory=tuple)
    default: Optional[T] = None
    val: Optional[T] = None

    def getOSArgument(self):
        arg_type = self.type
        if arg_type is tuple:
            os_arg = openstudio.measure.OSArgument.makeChoiceArgument(
                self.name, self.choices, self.required, self.modelDependent)
        elif arg_type is int:
            os_arg = openstudio.measure.OSArgument.makeIntegerArgument(self.name, self.required, self.modelDependent)
        elif arg_type is float:
            os_arg = openstudio.measure.OSArgument.makeDoubleArgument(self.name, self.required, self.modelDependent)
        elif arg_type is str:
            os_arg = openstudio.measure.OSArgument.makeStringArgument(self.name, self.required, self.modelDependent)
        elif arg_type is bool:
            os_arg = openstudio.measure.OSArgument.makeBoolArgument(self.name, self.required, self.modelDependent)
        else:
            raise ValueError(f"Unexpected field type {arg_type}")

        if self.displayname:
            os_arg.setDisplayName(self.displayname)
        if self.description:
            os_arg.setDescription(self.description)
        if self.default:
            os_arg.setDefaultValue(self.default)
        return os_arg

    def set_val(self, val):
        if self.val is not None:
            raise ValueError(f"Value can only be set once. Current value is {self.val}")
        self.__dict__['val'] = val
        return self.val


@dataclass(frozen=True)
class RelativeOffsetData:
    heating_pre_peak_offset: Argument[int] = field(default_factory=lambda: Argument(
        name='heating_pre_peak_offset',
        type=int,
        default=4,
        displayname="Heating Pre-Peak Offset (deg F)",
        description="How much increase offset to apply to the heating schedule in degree fahrenheit before the peak. Only used"
                    " if offset type is relative."
    ))
    heating_on_peak_offset: Argument[int] = field(default_factory=lambda: Argument(
        name='heating_on_peak_offset',
        type=int,
        default=4,
        displayname="Heating On-Peak Offset (deg F)",
        description="How much decrease offset to apply to the heating schedule in degree fahrenheit on the peak. Only used"
                    " if offset type is relative."
    ))
    heating_max: Argument[int] = field(default_factory=lambda: Argument(
        name='heating_max',
        type=int,
        default=80,
        displayname="Heating Max Setpoint (deg F)",
        description="The maximum heating setpoint in degree fahrenheit offsets should honor. Only used if offset"
                    " type is relative."
    ))
    heating_min: Argument[int] = field(default_factory=lambda: Argument(
        name='heating_min',
        type=int,
        default=55,
        displayname="Heating Min Setpoint (deg F)",
        description="The minimum heating setpoint in degree fahrenheit that offsets should honor. Only used if"
                    " offset type is relative."
    ))
    cooling_pre_peak_offset: Argument[int] = field(default_factory=lambda: Argument(
        name='cooling_pre_peak_offset',
        type=int,
        default=4,
        displayname="Cooling Pre-Peak Offset (deg F)",
        description="How much decrease offset to apply to the cooling schedule in degree fahrenheit before the peak."
                    " Only used if offset type is relative."
    ))
    cooling_on_peak_offset: Argument[int] = field(default_factory=lambda: Argument(
        name='cooling_on_peak_offset',
        type=int,
        default=4,
        displayname="Cooling On-Peak Offset (deg F)",
        description="How much increase offset to apply to the cooling schedule in degree fahrenheit on the peak."
                    " Only used if offset type is relative."
    ))
    cooling_max: Argument[int] = field(default_factory=lambda: Argument(
        name='cooling_max',
        type=int,
        default=80,
        displayname="Cooling Max Setpoint (deg F)",
        description="The maximum cooling setpoint in degree fahrenheit offsets should honor. Only used"
                    " if offset type is relative."
    ))
    cooling_min: Argument[int] = field(default_factory=lambda: Argument(
        name='cooling_min',
        type=int,
        default=60,
        displayname="Cooling Min Setpoint (deg F)",
        description="The minimum cooling setpoint in degree fahrenheit that offsets should honor."
                    " Only used if offset type is relative."
    ))


@dataclass(frozen=True)
class AbsoluteOffsetData:
    heating_on_peak_setpoint: Argument[int] = field(default_factory=lambda: Argument(
        name='heating_on_peak_setpoint',
        type=int,
        default=55,
        displayname="Heating On-Peak Setpoint (deg F)",
        description="The heating setpoint in degree fahrenheit on the peak. Only used if offset type is absolute."
    ))
    heating_pre_peak_setpoint: Argument[int] = field(default_factory=lambda: Argument(
        name='heating_pre_peak_setpoint',
        type=int,
        default=80,
        displayname="Heating Pre-Peak Setpoint (deg F)",
        description="The heating setpoint in degree fahrenheit before the peak. Only used if offset type is absolute."
    ))
    cooling_on_peak_setpoint: Argument[int] = field(default_factory=lambda: Argument(
        name='cooling_on_peak_setpoint',
        type=int,
        default=80,
        displayname="Cooling On-Peak Setpoint (deg F)",
        description="The cooling setpoint in degree fahrenheit on the peak. Only used if offset type is absolute."
    ))
    cooling_pre_peak_setpoint: Argument[int] = field(default_factory=lambda: Argument(
        name='cooling_pre_peak_setpoint',
        type=int,
        default=60,
        displayname="Cooling Pre-Peak Setpoint (deg F)",
        description="The cooling setpoint in degree fahrenheit before the peak. Only used if offset type is absolute."
    ))


@dataclass(frozen=True)
class OffsetTimingData:
    heating_pre_peak_duration: Argument[int] = field(default_factory=lambda: Argument(
        name='heating_pre_peak_duration',
        type=int,
        default=4,
        displayname="Heating Pre-Peak Duration (hours)",
        description="The duration of the pre-peak period in hours."
    ))
    cooling_pre_peak_duration: Argument[int] = field(default_factory=lambda: Argument(
        name='cooling_pre_peak_duration',
        type=int,
        default=4,
        displayname="Cooling Pre-Peak Duration (hours)",
        description="The duration of the pre-peak period in hours."
    ))
    heating_on_peak_duration: Argument[int] = field(default_factory=lambda: Argument(
        name='heating_on_peak_duration',
        type=int,
        default=4,
        displayname="Heating On-Peak Duration (hours)",
        description="The duration of the on-peak period in hours."
    ))
    cooling_on_peak_duration: Argument[int] = field(default_factory=lambda: Argument(
        name='cooling_on_peak_duration',
        type=int,
        default=4,
        displayname="Cooling On-Peak Duration (hours)",
        description="The duration of the on-peak period in hours."
    ))
    random_timing_shift: Argument[float] = field(default_factory=lambda: Argument(
        name='random_timing_shift',
        type=float,
        default=1.0,
        displayname="Random Timing Shift",
        description="Random shift to the start and end times in hour to avoid coincident peaks. If the value is 1, start and end time will be shifted by a maximum of +- 1 hour."
    ))


@dataclass
class Inputs:
    upgrade_name: Argument[str] = field(default_factory=lambda: Argument(
        name='upgrade_name',
        type=str,
        default="None",
        displayname='Upgrade Name',
        description='The name of the upgrade when used as a part of upgrade measure'
    ))
    offset_type: Argument[str] = field(default_factory=lambda: Argument(
        name='offset_type',
        type=tuple,
        displayname="Setpoint offset type",
        description="Whether to apply the demand response setpoints relative to the default setpoints"
        " or as absolute values.",
        required=True,
        choices=(OffsetType.relative, OffsetType.absolute),
        default=OffsetType.relative
    ))
    relative_offset: RelativeOffsetData = field(default_factory=lambda: RelativeOffsetData())
    absolute_offset: AbsoluteOffsetData = field(default_factory=lambda: AbsoluteOffsetData())
    offset_timing: OffsetTimingData = field(default_factory=lambda: OffsetTimingData())


def get_input_from_dict(arg_dict) -> Inputs:
    inputs = Inputs()
    inputs.upgrade_name.set_val(arg_dict.get('upgrade_name'))
    inputs.offset_type.set_val(arg_dict.get('offset_type'))
    input_args = []
    input_args += inputs.relative_offset.__dict__.values()
    input_args += inputs.absolute_offset.__dict__.values()
    input_args += inputs.offset_timing.__dict__.values()
    for input_field in input_args:
        input_field.set_val(arg_dict[input_field.name])
    return inputs
