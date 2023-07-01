# Electrical Panels
This branch is under active development and may be subject to change. This branch contains postprocessing scripts for estimating electrical panel amerage of dwelling units from ResStock run summary files. The scripts can output: 1) predicted panel amperage using LBNL's DecisionTree model (prelim_panel_model), 2) code-minimum panel amperage per 2023 NEC Section 220.

## Environment

Start a conda environment with python>=3.10:

```
conda create -n panels python pip
conda activate panels
pip install -e .
```

## How to Use

For NEC Calculation
```
postprocess_electrical_panel_size_nec.py [-h] [-p] [-d] [filename]

positional arguments:
  filename         Path to ResStock result file, e.g., results_up00.csv, defaults to test data:
                   test_data/euss1_2018_results_up00_100.csv

options:
  -h, --help       show this help message and exit
  -p, --plot_only  Make plots only based on expected output file
  -d, --sfd_only   Apply calculation to Single-Family Detached only (this is only on plotting for now)
```

For panel predicion using LBNL's DecisionTree model
```
apply_panel_regression_model.py [-h] [-b] [-r] [-p] [-d] [filename]

positional arguments:
  filename             Path to ResStock result file, e.g., results_up00.csv, defaults to test data:
                       test_data/euss1_2018_results_up00_100.csv

options:
  -h, --help           show this help message and exit
  -b, --predict_proba  Whether to use model.predict_proba() to predict output as a distribution of output
                       labels
  -r, --retain_proba   Only apply in conjunction with --predict_proba flag. When applied, predicted output is
                       retained as a distribution of output labels and saturation plots give the expected
                       saturation of output. Otherwise, predicted output is drawn probablistically based on
                       the distribution of output labels and saturation plots give near expected saturation of
                       output (with stochasticity)
  -p, --plot_only      Make plots only based on expected output file
  ```