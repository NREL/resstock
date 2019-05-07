# Create visualizations

The scripts on this folder help create different visualizations of a ResStock project. As the projects evolve, these scripts work directly off the housing characteristics and can simply be regenerated. Find below the necessary prerequisites and regeneration information.

## Install prerequisites

### Python 2.7

The visualization script run using python 2.7.

 - [Python 2.7 installation](https://www.python.org/downloads/)

### Other Python modules

```
conda create -n myenv python=2.7
source activate myenv
conda install -c conda-forge python-graphviz
conda install ipykernel
python -m ipykernel install --user --name myenv --display-name "myenv"
pip install numpy # Numerical Python
pip install pandas # Data Frame Manipulation
pip install networkx # Network Graph Representations
pip install nxpd # Drawing Network Graphs
pip install nbformat # Jupyter Notebook Format
```

If you're on Windows, first install [Graphviz 2.38](https://graphviz.gitlab.io/_pages/Download/Download_windows.html) and then add the graphviz bin folder (e.g., C:\Program Files (x86)\Graphviz2.38\bin) to your PATH environment variable.

### Jupyter notebook

The scripts use a Jupyter interactive python notebook (ipynb). Follow directions of installing jupyter based on pip or Anaconda installation in the following link below.

- [Jupyter notebook installation](https://jupyter.org/install)

## Regenerating the visualizations

The projects will change over time. To regenerate the visualizations for all projects, run `regenerate_visualizations.ipynb`. This script will execute all the visualization scripts in this folder.

### Visualization scripts:

- Dependency wheels
- Dependency graphs

Please note that the `dependencyWheels/dep_wheel_blank_template.html` file is a blank template that is copied to the `<project_directory>/util/` folder and renamed to `dep_wheel.html` when the `dependencyWheels/createDependencyWheelData.ipynb` is run. To see the dependency wheels and dependcy graphs, go to the `<project_directory>/util/` after the visualizations have been created or updated with the `regenerate_visualizations.ipynb` notebook.