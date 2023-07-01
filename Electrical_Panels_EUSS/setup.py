#!/usr/bin/env python

import setuptools
from codecs import open
import os
import sys

if sys.version_info.major < 3 or (
    sys.version_info.major == 3 and sys.version_info.minor < 10
):
    raise Exception("This package requires python 3.10 or higher")

here = os.path.abspath(os.path.dirname(__file__))
metadata = {}

with open(os.path.join(here, "__version__.py"), "r", encoding="utf-8") as f:
    exec(f.read(), metadata)

# with open("README.md", "r", "utf-8") as f:
#     readme = f.read()

setuptools.setup(
    name=metadata["__name__"],
    version=metadata["__version__"],
    description=metadata["__description__"],
    # long_description=readme,
    # long_description_content_type="text/markdown",
    url=metadata["__url__"],
    packages=setuptools.find_packages(),
    python_requires=">=3.10",
    install_requires=[
        "pandas<2",
        "ipython",
        "pyarrow",
        "scipy",
        "openpyxl",
        "matplotlib",
        "scikit-learn==0.24.2",
    ], # pip install -e .
    extras_require={
        "dev": [
            "pytest",
            "flake8==3.8.2",
            "boto3",
            "awscli",
            "black",
            "plotly",
            
        ] # pip install -e .[dev]
    },
)
