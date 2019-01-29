# Utility folder for the Multifamily project

This folder contiains scripts for documentation and visualizations of the ResStock project.  All the housing characteristics information is found in the `housing characteristics info.json` file.  Each of the folders contains a script to generate some aspect of the documentation and visualizations.  All these scripts can be updates by executing the `regenerate_documentation.ipynb` notebook, so that when changes are made to the project the figures and information will update.  If housing characteristics are added (or removed) from a project, please add (remove) them from the `housing characteristics info.json` file.

- **dataSourceTable:** Creates a table from the housing characteristics and data sources in the `housing characteristics info.json` file.
- **dependencyGraphs:** Creates a graph of the housing characteristics and their dependencies. These graphs show how the characteristics are connected and where the characteristics are positioned in the hierarchy of the graph.
- **dependencyWheels:** Creates a wheel that displays either the dependents or dependencies of each housing characteristic in an interactive graphic.
- **sankeyDiagram:** Creates a flow chart of the characteristics to their data sources from the `housing characteristics info.json`.
- **updateJsonDepsOpts:** Updates the dependencies and options in the `housing characteristic infor.json` file based on the dependencies and options in the `<project_folder>/housing_characteristic` TSV files.

# Updating Documentation

The project folders, housing characteristics, dependencies, and options for a project are bound to change as the project is developed.  For developers, find in the below sections some information about how to update the figures and files. 

## Housing characteristics information

The majority of the documentation in this `util` folder is based on the `housing characteristics info.json` file.  This file is a database for the housing characteristics and includes the following information about each housing characteristic.

- **Name:** The name of the housing characteristic that matches the TSv file in the `<project_folder>/housing_characteristics` directory.
- **Features:** A set of features that describe the housing characteristic
    - **Category:** A string that groups different housing characteristics together.
    - **Description:** A detailed description of what the housing characteristic.
    - **Dependencies:** A list of the dependencies in the TSV file.
    - **Options:** A list of the options in the TSV file.
    - **Assumptions:** A discussion of the different assumptions used to create the distributions or measure arguments.
    - **Data Sources:** A list of the data sources used to create the distributions and measure arguments. Each data source has its own meta data.
        - **Name:** An abreviated name of the data source.
        - **url:** A link to the data source if available.
        - **bibtex:** Text for the bibtex citation of the data source
        - **remark:** Remarks about the data source (i.e. publically available or obtained from a private data source or company).

## Procedure to update the documentation

After updating a project please perform the following steps. 

1. For all renamed housing characteristics, find the old housing characteristic and update the *Name* field in the `housing characteristics info.json` file.  Re-order the renamed characteristic to keep in alphabetical order.
2. For all new housing characteristics, create a new entry in the 
The majority of the update process is automated by the  `housing characteristics info.json` file by filling out as many fields as possible. The list of dependencies and options can be empty as they will be automatically generated from running `regenerate_documentation.ipynb` notebook. Please ensure the new characteristic is inserted to maintain alphabetical order.
3. Run the `regenerate_documentation.ipynb` notebook.  This notebook will go into the different folders of this directory and update the figures, tables, and files.  Watch the first block to ensure that all housing characteristics are present in the `housing characteristics info.json` file. 