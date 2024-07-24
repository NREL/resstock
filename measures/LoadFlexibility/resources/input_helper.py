from dataclasses import dataclass, field
import openstudio
from typing import Optional
from typing import TypeVar, Generic, List
T = TypeVar('T')


class OffsetType:
    relative: str = 'relative'
    absolute: str = 'absolute'


@dataclass(frozen=True)
class Argument(Generic[T]):
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
class __OffsetTypeData:
    offset_type: Argument[str] = Argument(
        name='offset_type',
        type=tuple,
        displayname="Setpoint offset type",
        description="Whether to apply the demand response setpoints relative to the default setpoints"
                    " or as absolute values.",
        required=True,
        choices=(OffsetType.relative, OffsetType.absolute),
        default=OffsetType.relative
    )


# Create an instance of the class.
# This is the only instance that should be created and is used everywhere the module is imported.
OffsetTypeData = __OffsetTypeData()


@dataclass(frozen=True)
class __RelativeOffsetData:
    heating_pre_peak_offset: Argument[int] = Argument(
        name='heating_pre_peak_offset',
        type=int,
        default=4,
        displayname="Heating Pre-Peak Offset (deg F)",
        description="How much offset to apply to the heating schedule in degree fahrenheit before the peak. Only used"
                    " if offset type is relative."
    )
    heating_on_peak_offset: Argument[int] = Argument(
        name='heating_on_peak_offset',
        type=int,
        default=4,
        displayname="Heating On-Peak Offset (deg F)",
        description="How much offset to apply to the heating schedule in degree fahrenheit on the peak. Only used"
                    " if offset type is relative."
    )
    heating_max: Argument[int] = Argument(
        name='heating_max',
        type=int,
        default=80,
        displayname="Heating Max Setpoint (deg F)",
        description="The maximum heating setpoint in degree fahrenheit offsets should honor. Only used if offset"
                    " type is relative."
    )
    heating_min: Argument[int] = Argument(
        name='heating_min',
        type=int,
        default=55,
        displayname="Heating Min Setpoint (deg F)",
        description="The minimum heating setpoint in degree fahrenheit that offsets should honor. Only used if"
                    " offset type is relative."
    )
    cooling_pre_peak_offset: Argument[int] = Argument(
        name='cooling_pre_peak_offset',
        type=int,
        default=4,
        displayname="Cooling Pre-Peak Offset (deg F)",
        description="How much offset to apply to the cooling schedule in degree fahrenheit before the peak."
                    " Only used if offset type is relative."
    )
    cooling_on_peak_offset: Argument[int] = Argument(
        name='cooling_on_peak_offset',
        type=int,
        default=4,
        displayname="Cooling On-Peak Offset (deg F)",
        description="How much offset to apply to the cooling schedule in degree fahrenheit on the peak."
                    " Only used if offset type is relative."
    )
    cooling_max: Argument[int] = Argument(
        name='cooling_max',
        type=int,
        default=80,
        displayname="Cooling Max Setpoint (deg F)",
        description="The maximum cooling setpoint in degree fahrenheit offsets should honor. Only used"
                    " if offset type is relative."
    )
    cooling_min: Argument[int] = Argument(
        name='cooling_min',
        type=int,
        default=60,
        displayname="Cooling Min Setpoint (deg F)",
        description="The minimum cooling setpoint in degree fahrenheit that offsets should honor."
                    " Only used if offset type is relative."
    )


RelativeOffsetData = __RelativeOffsetData()


@dataclass(frozen=True)
class __AbsoluteOffsetData:
    heating_on_peak_setpoint: Argument[int] = Argument(
        name='heating_on_peak_setpoint',
        type=int,
        default=55,
        displayname="Heating On-Peak Setpoint (deg F)",
        description="The heating setpoint in degree fahrenheit on the peak. Only used if offset type is absolute."
    )
    heating_pre_peak_setpoint: Argument[int] = Argument(
        name='heating_pre_peak_setpoint',
        type=int,
        default=80,
        displayname="Heating Pre-Peak Setpoint (deg F)",
        description="The heating setpoint in degree fahrenheit before the peak. Only used if offset type is absolute."
    )
    cooling_on_peak_setpoint: Argument[int] = Argument(
        name='cooling_on_peak_setpoint',
        type=int,
        default=80,
        displayname="Cooling On-Peak Setpoint (deg F)",
        description="The cooling setpoint in degree fahrenheit on the peak. Only used if offset type is absolute."
    )
    cooling_pre_peak_setpoint: Argument[int] = Argument(
        name='cooling_pre_peak_setpoint',
        type=int,
        default=60,
        displayname="Cooling Pre-Peak Setpoint (deg F)",
        description="The cooling setpoint in degree fahrenheit before the peak. Only used if offset type is absolute."
    )


AbsoluteOffsetData = __AbsoluteOffsetData()


@dataclass(frozen=True)
class __OffsetTimingData:
    heating_pre_peak_duration: Argument[int] = Argument(
        name='heating_pre_peak_duration',
        type=int,
        default=4,
        displayname="Heating Pre-Peak Duration (hours)",
        description="The duration of the pre-peak period in hours."
    )
    cooling_pre_peak_duration: Argument[int] = Argument(
        name='cooling_pre_peak_duration',
        type=int,
        default=4,
        displayname="Cooling Pre-Peak Duration (hours)",
        description="The duration of the pre-peak period in hours."
    )
    heating_on_peak_duration: Argument[int] = Argument(
        name='heating_on_peak_duration',
        type=int,
        default=4,
        displayname="Heating On-Peak Duration (hours)",
        description="The duration of the on-peak period in hours."
    )
    cooling_on_peak_duration: Argument[int] = Argument(
        name='cooling_on_peak_duration',
        type=int,
        default=4,
        displayname="Cooling On-Peak Duration (hours)",
        description="The duration of the on-peak period in hours."
    )


OffsetTimingData = __OffsetTimingData()


def get_args(cls) -> List[Argument]:
    return [field.default for field in cls.__dataclass_fields__.values()]


ALL_MEASURE_ARGS = get_args(OffsetTypeData)
ALL_MEASURE_ARGS += get_args(RelativeOffsetData)
ALL_MEASURE_ARGS += get_args(AbsoluteOffsetData)
ALL_MEASURE_ARGS += get_args(OffsetTimingData)
# absolute_offset_fields = get_dataclass_info(AbsoluteOffsetData)
# offset_timing_fields = get_dataclass_info(OffsetTimingData)

# all_offset_fields = {**relative_offset_fields, **absolute_offset_fields, **offset_timing_fields}
