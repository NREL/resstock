"""insert your copyright here."""

from pathlib import Path

import openstudio
import os
import sys
import pytest
os.environ['PYTEST_RUNNING'] = 'true'
# update python path to include parent folder
CURRENT_DIR_PATH = Path(__file__).parent.absolute()
sys.path.insert(0, str(CURRENT_DIR_PATH.parent))
import dataclasses
from measure import LoadFlexibility
from resources.input_helper import Inputs, AbsoluteOffsetData, OffsetTimingData, RelativeOffsetData
from resources.setpoint import HVACSetpoints
sys.path.pop(0)
# del sys.modules['measure']


class TestLoadFlexibility:
    """Py.test module for LoadFlexibility."""

    def test_number_of_arguments_and_argument_names(self):
        """Test that the arguments are what we expect."""
        # create an instance of the measure
        measure = LoadFlexibility()

        # make an empty model
        model = openstudio.model.Model()
        example_inputs = Inputs()
        # get arguments and test that they are what we are expecting
        arguments = measure.arguments(model)
        single_fields = [example_inputs.upgrade_name.name, example_inputs.offset_type.name]
        absolute_fields = [f.name for f in example_inputs.absolute_offset.__dict__.values()]
        relative_fields = [f.name for f in example_inputs.relative_offset.__dict__.values()]
        offset_timing_fields = [f.name for f in example_inputs.offset_timing.__dict__.values()]
        expected_all_args = sorted(single_fields + absolute_fields + relative_fields + offset_timing_fields)
        actual_all_args = sorted([arg.name() for arg in arguments])
        assert actual_all_args == expected_all_args

    # def test_setpoint_get_month_day(self):
    #     year_index = 8759
    #     total_indices = 8760
    #     year = 2020
    #     month, day = HVACSetpoints._get_month_day(year_index, total_indices, year)
    #     assert month == 12
    #     assert day == 31


    # def test_valid_argument_values(self):

    #     arg_dict = {}
    #     arg_dict['offset_type'] = OffsetType.relative
    #     arg_dict[AbsoluteOffsetData.cooling_on_peak_setpoint]

    # def test_bad_argument_values(self):
    #     """Test running the measure with inappropriate arguments, and that the measure reports failure."""
    #     # create an instance of the measure
    #     measure = LoadFlexibility()

    #     # create runner with empty OSW
    #     osw = openstudio.WorkflowJSON()
    #     runner = openstudio.measure.OSRunner(osw)

    #     # Make an empty model
    #     model = openstudio.model.Model()

    #     # get arguments
    #     arguments = measure.arguments(model)
    #     argument_map = openstudio.measure.convertOSArgumentVectorToMap(arguments)

    #     # create hash of argument values.
    #     # If the argument has a default that you want to use,
    #     # you don't need it in the dict
    #     args_dict = {}
    #     args_dict["offset"] = -4

    #     # populate argument with specified hash value if specified
    #     for arg in arguments:
    #         temp_arg_var = arg.clone()
    #         if arg.name() in args_dict:
    #             assert temp_arg_var.setValue(args_dict[arg.name()])
    #             argument_map[arg.name()] = temp_arg_var

    #     # run the measure
    #     measure.run(model, runner, argument_map)
    #     result = runner.result()

    #     # show the output
    #     # show_output(result)
    #     print(f"results: {result}")

    #     # assert that it failed
    #     assert result.value().valueName() == "Fail"

    # def test_good_argument_values(self):
    #     """Test running the measure with inappropriate arguments, and that the measure reports failure."""
    #     # create an instance of the measure
    #     measure = LoadFlexibility()

    #     # create runner with empty OSW
    #     osw = openstudio.WorkflowJSON()
    #     runner = openstudio.measure.OSRunner(osw)

    #     # Make an empty model
    #     model = openstudio.model.Model()

    #     # get arguments
    #     arguments = measure.arguments(model)
    #     argument_map = openstudio.measure.convertOSArgumentVectorToMap(arguments)

    #     # create hash of argument values.
    #     # If the argument has a default that you want to use,
    #     # you don't need it in the dict
    #     args_dict = {}
    #     args_dict["offset"] = 4

    #     # populate argument with specified hash value if specified
    #     for arg in arguments:
    #         temp_arg_var = arg.clone()
    #         if arg.name() in args_dict:
    #             assert temp_arg_var.setValue(args_dict[arg.name()])
    #             argument_map[arg.name()] = temp_arg_var

    #     # run the measure
    #     measure.run(model, runner, argument_map)
    #     result = runner.result()
    #     # show the output
    #     # show_output(result)
    #     print(f"results: {result}")

    #     # assert that it failed
    #     assert result.value().valueName() == "Success"

if __name__ == "__main__":
    import sys
    if len(sys.argv) > 1:
        pytest.main([__file__] + sys.argv[1:])
    else:
        pytest.main()