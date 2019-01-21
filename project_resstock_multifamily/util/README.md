# Utility folder for the Multifamily project

This folder contiains scripts for documentation and visualizations of the ResStock project.  All the housing characteristics information is found in the `housing characteristics info.json` file.  Each of the folders contains a script to generate some aspect of the documentation and visualizations.  All these scripts can be updates by executing the `regenerate_documentation.ipynb` notebook, so that when changes are made to the project the figures and information will update.  If housing characteristics are added (or removed) from a project, please add (remove) them from the `housing characteristics info.json` file.

- **dataSourceTable:** Creates a table from the housing characteristics and data sources in the `housing characteristics info.json` file.
- **dependencyGraphs:** Creates a graph of the housing characteristics and their dependencies. These graphs show how the characteristics are connected and where the characteristics are positioned in the hierarchy of the graph.
- **dependencyWheels:** Creates a wheel that displays either the dependents or dependencies of each housing characteristic in an interactive graphic.
- **sankeyDiagram:** Creates a flow chart of the characteristics to their data sources from the `housing characteristics info.json`.
- **updateJsonDepsOpts:** Updates the dependencies and options in the `housing characteristic infor.json` file based on the dependencies and options in the `<project_folder>/housing_characteristic` TSV files.