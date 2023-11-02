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

6. Open `config.yaml` with your favorite code editor and modify the variables as needed.


## Output

There are several kinds of output you can generate.

### __A. Quick Look Report__
Quick look output gives the average energy consumption per dwelling unit grouped by state and upgrades for select end use columns, emission and cost output. This is the fastest way to verify no catastrophic mistake has been made.

__Steps to produce Quick Look Report__

1. Make sure `config.yaml` contains correct run_names, db_name and other settings.
2. Run the `get_quick_look_report.py` from the terminal

   `python get_quick_look_report.py`

Once this script completes (It can take 10-20 minutes), you will be able to find a file named `file_prefix_quick_look.csv` inside the output folder which contains the average values for the various quick look columns configured in the `confg.yaml`. You can open this file in Tableau or Excel to see if the results are as expected.

__Bonus: Quick Look report plot__

There is additional script to quickly visualize the values in `file_prefix_quick_look.csv`. 

1. To run the script, start it with:

   `python get_quick_look_plots.py`

The script will ask for the full path to the `file_prefix_quick_look.csv` file. Provide the full path. You can even pass multiple files (perhaps generated from two different set of runs - such as medium and full runs) by separating them with a comma and it will show the result in a nice side-by-side bar graph for easy eyeballing! Enjoy.

__Quick Look report plot output__

The output from the quick plot can be found inside output_folder/quick_plots




### __B. Full Report (To be viewed in Tableau)__

The full report generates a set of processed files that can be imported in Tableau to generate the detailed dashboard.

__Steps to generate full report.__

1. Make sure `config.yaml` contains correct run_names, db_name and other settings.
2. Run the `get_full_report.py`

   `python get_full_report.py`

   Depending upon run size and internet speed, it can take some time. In the full size largee run, about 65 GB of data needs to be downloaded before the processing can start. Make sure you have at least about 80 GB of space in your laptop. For medium run, 5 - 10 GB should be sufficient.

__Full report output__

Once the processing completes, you should be able to find various csv files in the output folder. There will be two top level folders in the output_folder.
   
   `full`: This contains the full dataset.

   `head`: This contains only the top 1000 rows from each file. It is useful to quickly verify the contents when the full size files are too large to open in excel.

   When state_split is False, all files are placed inside 'All' folder. When it is true, the files are placed in folders named by the keys in state_grouping dict.
