# Documentation Setup

## Install Prerequisites

In a clean Python 3 [venv](https://docs.python.org/3/library/venv.html) or [conda environment](https://docs.conda.io/projects/conda/en/latest/user-guide/tasks/manage-environments.html), install the requirements as follows:

```
pip install -r requirements.txt
```

## Build the Docs Locally

With your environment activated, run the following command on Windows

```
./make.bat livehtml
```

And on Mac/Linux

```
make livehtml
```

That will build the docs and open them in a new browser window. It will also keep a server running that will watch for changes in the source files, rebuild, and refresh the docs. This is useful to see in real time how changes you make in the docs source will be rendered. 

## Edit the Docs

In the `source` folder there are a number of `*.rst` files. They are in the reStructuredText format. There's a [guide for how to edit it on the Sphinx website](http://www.sphinx-doc.org/en/stable/rest.html). Upon committing and pushing, the docs will be updated automatically on [Read The Docs](http://resstock.readthedocs.io/en/latest/).
