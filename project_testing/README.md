# Testing Project Folder

This folder contains the ResStock inputs to test our OpenStudio measures workflow. The main inputs that characterize the building stock is the housing characteristics in the `housing_characteristics/` directory.

## Visualization of the Housing Characteristic Dependencies

ResStock is built upon the conditional probabilites of the housing characteristics.  Each housing characteristic has a set of dependencies and dependants.  An interactive dependency and dependents visualization is provided in the links below:

<a href="https://htmlpreview.github.io/?https://github.com/NREL/OpenStudio-BuildStock/blob/master/project_testing/util/dependency_wheel/dep_wheel.html">Testing Project: Dependency Wheel</a>

## Visualization of the Housing Characteristics as a Graph

The conditional dependencies of the housing characteristic allow for the formulation of the housing characteristics as a directed graph (or network).  In the graph the housing characteristics are the nodes and the dependencies are directed edges.  A visualization of the noted, edges, and different levels of the graph can be seen in the `.pdf` files in the `util/dependency_graphs` directory.