"""insert your copyright here.

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/
"""

import typing
import openstudio
from pathlib import Path
import os
import json
import subprocess
import dataclasses
import xml.etree.ElementTree as ET
import sys


if os.environ.get('DEBUGPY', '') == 'true':
    import debugpy
    debugpy.listen(5694, in_process_debug_adapter=True)
    print("Waiting for debugger attach")
    debugpy.wait_for_client()

RESOURCES_DIR = Path(__file__).parent / "resources"
sys.path.insert(0, str(RESOURCES_DIR))
from setpoint import modify_all_setpoints
from input_helper import OffsetType, RelativeOffsetData, AbsoluteOffsetData, ALL_MEASURE_ARGS
from xml_helper import HPXML
from setpoint_helper import HVACSetpoints, BuildingInfo
sys.path.pop(0)


class LoadFlexibility(openstudio.measure.ModelMeasure):
    """A Residential Load Flexibility measure."""

    def name(self):
        """Returns the human readable name.

        Measure name should be the title case of the class name.
        The measure name is the first contact a user has with the measure;
        it is also shared throughout the measure workflow, visible in the OpenStudio Application,
        PAT, Server Management Consoles, and in output reports.
        As such, measure names should clearly describe the measure's function,
        while remaining general in nature
        """
        return "LoadFlexibility"

    def description(self):
        """Human readable description.

        The measure description is intended for a general audience and should not assume
        that the reader is familiar with the design and construction practices suggested by the measure.
        """
        return "A measure to apply load shifting / shedding to a building based on various user arguments."

    def modeler_description(self):
        """Human readable description of modeling approach.

        The modeler description is intended for the energy modeler using the measure.
        It should explain the measure's intent, and include any requirements about
        how the baseline model must be set up, major assumptions made by the measure,
        and relevant citations or references to applicable modeling resources
        """
        return "This applies a load shifting / shedding strategy to a building."

    def arguments(self, model: typing.Optional[openstudio.model.Model] = None):
        """Prepares user arguments for the measure.
        Measure arguments define which -- if any -- input parameters the user may set before running the measure.
        """
        args = openstudio.measure.OSArgumentVector()
        for arg in ALL_MEASURE_ARGS:
            args.append(arg.getOSArgument())

        return args

    def get_hpxml_path(self, runner: openstudio.measure.OSRunner):
        workflow_json = json.loads(str(runner.workflow()))
        hpxml_path = [step['arguments']['hpxml_path'] for step in workflow_json['steps']
                      if 'HPXMLtoOpenStudio' in step['measure_dir_name']][0]
        return hpxml_path

    def get_setpoint_csv(self, setpoint: HVACSetpoints):
        header = 'heating_setpoint,cooling_setpoint'
        vals = '\n'.join([','.join([str(v) for v in val_pair])
                         for val_pair in zip(setpoint.heating_setpoint, setpoint.cooling_setpoint)])
        return f"{header}\n{vals}"

    def process_arguments(self, runner, arg_dict: dict, passed_arg: set):
        if arg_dict['offset_type'] == OffsetType.absolute:
            relative_offset_fields = set(f.name for f in dataclasses.fields(RelativeOffsetData))
            if intersect_args := passed_arg & relative_offset_fields:
                runner.registerWargning(f"These inputs are ignored ({intersect_args}) since offset type is absolute.")
                return False
        if arg_dict['offset_type'] == OffsetType.relative:
            absolute_offset_fields = set(f.name for f in dataclasses.fields(AbsoluteOffsetData))
            if intersect_args := passed_arg & absolute_offset_fields:
                runner.registerError(f"These inputs are ignored ({intersect_args}) since offset type is relative.")
                return False

        for arg in ALL_MEASURE_ARGS:
            arg.set_val(arg_dict[arg.name])

    def run(
        self,
        model: openstudio.model.Model,
        runner: openstudio.measure.OSRunner,
        user_arguments: openstudio.measure.OSArgumentMap,
    ):
        """Defines what happens when the measure is run."""
        super().run(model, runner, user_arguments)  # Do **NOT** remove this line

        if not (runner.validateUserArguments(self.arguments(model), user_arguments)):
            return False

        runner.registerInfo("Starting LoadFlexibility")
        arg_dict = runner.getArgumentValues(self.arguments(model), user_arguments)
        passed_args = {arg_name for arg_name, arg_value in dict(user_arguments).items() if arg_value.hasValue()}
        self.process_arguments(runner, arg_dict, passed_args)  # sets the values of the arguments in the dataclasses

        osw_path = str(runner.workflow().oswPath().get())

        hpxml_path = self.get_hpxml_path(runner)
        result = subprocess.run(["openstudio", f"{RESOURCES_DIR}/create_setpoint_schedules.rb",
                                 hpxml_path, osw_path],
                                capture_output=True)
        setpoints = [HVACSetpoints(**setpoint) for setpoint in json.loads(result.stdout)
                     ]  # [{"heating setpoint": [], "cooling setpoint": []}]
        if result.returncode != 0:
            runner.registerError(f"Failed to run create_setpoint_schedules.rb : {result.stderr}")
            return False
        building_info = BuildingInfo()
        modify_all_setpoints(runner, setpoints, building_info)
        hpxml = HPXML(hpxml_path)
        doc_buildings = hpxml.findall("Building")
        for (indx, building) in enumerate(doc_buildings):
            doc_building_id = building.find("ns:BuildingID", hpxml.ns).get('id')
            output_csv_name = f"hvac_setpoint_schedule_{doc_building_id}.csv"
            output_csv_path = Path(hpxml_path).parent / output_csv_name
            setpoint_dict = setpoints[indx]
            with open(output_csv_path, 'w', newline='') as f:
                f.write(self.get_setpoint_csv(setpoint_dict))
            extension = hpxml.create_elements_as_needed(building, ['BuildingDetails', 'BuildingSummary', 'extension'])

            existing_schedules = hpxml.findall('SchedulesFilePath', extension)
            for schedule in existing_schedules:
                if schedule.text == str(output_csv_path):
                    break
            else:
                schedule_path = ET.SubElement(extension, 'SchedulesFilePath')
                schedule_path.text = str(output_csv_path)

        hpxml.tree.write(hpxml_path, xml_declaration=True, encoding='utf-8')
        return True


# register the measure to be used by the application
LoadFlexibility().registerWithApplication()
