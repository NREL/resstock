# LARGEEE Run Processing script for factsheet dashboard

This folder contains python scripts to process largeee run result and generate csv files that can be used in Tableau for the factsheet dashboard. A significant section of the code is copied from https://github.com/NREL/SightGlassDataProcessing/tree/main/telescope and adapted to use polars instead of pandas. 

## Getting started
1. Clone the repository to your computer.
2. Open a command promt (or "conda prompt" in Windows) and `cd` into this (largeee_processing) folder.
3. Create a new python 3.10 environment with:
   
   `conda create -n largeee python=3.10`
4. Activate the environment
   
   `conda activate largeee`

5. Install the requirements:
   
   `pip install -r requirements.txt`

6. Open `launch_processing.py` with your favorite code editor and modify the following variables near the top of the files.
   
   `output_folder`: Modify this to change the name of the output folder.

   `state_split`: Change it to False if you want single group with all states. Change it to True if you want to split based on various state-based grouping.

   `state_grouping`: If __state_split__ is True, split the output files based on this grouping. You can modify this if you want a different grouping.

   `run_names`: This is the list of run names uploaded to Athena. __The first run is assumed to be baseline run__. Modify this to process new runs.

   `wide_chars`: These are the housing characteristics what will be exported in the wide-format characteristics file. You can add/remove as needed. Wide format includes 'weight' column by default.

   `long_chars`: These are the housing characteristics what will be exported in the long-format characteristics file. You can add/remove as needed.

7. Start the processing.
   
   `python launch_processing.py`

   Depending upon run size and internet speed, it can take some time. In the full size largee run, about 65 GB of data needs to be downloaded before the processing can start. Make sure you have at least about 80 GB of space in your laptop. For medium run, 5 - 10 GB should be sufficient.

## Output
Once the processing completes, you should be able to find various csv files in the output folder. There will be two top level folders in the output_folder.
   
   `full`: This contains the full dataset.

   `head`: This contains only the top 1000 rows from each file. It is useful to quickly verify the contents when the full size files are too large to open in excel.

   When state_split is False, all files are placed inside 'All' folder. When it is true, the files are placed in folders named by the keys in state_grouping dict.
