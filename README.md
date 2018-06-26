OpenStudio-BuildStock
===================

BuildStock, built on the [OpenStudio platform](http://openstudio.net), is a project geared at modeling the existing building stock for, e.g., national, regional, or local analysis, using the [EnergyPlus simulation engine](http://energyplus.net). It consists of ResStock and ComStock, sister tools for modeling the residential and commercial building stock, respectively. 

This project is a <b>work-in-progress</b>.

Unit Test Status: [![CircleCI](https://circleci.com/gh/NREL/OpenStudio-BuildStock/tree/master.svg?style=svg)](https://circleci.com/gh/NREL/OpenStudio-BuildStock/tree/master)

For more information, please visit the [documentation](http://resstock.readthedocs.io/en/latest/).

![BuildStock workflow](https://user-images.githubusercontent.com/5861765/32569254-da2895c8-c47d-11e7-93cb-05fb4c8806d7.png)

## ResStock for Multifamily Low-Rise

A beta release of ResStock with Multifamily Low-Rise capabilities is now available!

Repository: https://github.com/NREL/OpenStudio-BuildStock/tree/multifamily_tests

Project folder: https://github.com/NREL/OpenStudio-BuildStock/tree/multifamily_tests/project_resstock_multifamily

This dependency graph illustrates the relationship between the conditional probability distributions used to describe the U.S. residential building stock. Blue color indicates the parameters and dependencies added to represent for the low-rise multifamily sector.
![image](https://user-images.githubusercontent.com/1276021/40512741-fa539b58-5f60-11e8-8423-36efd677b81d.png)
