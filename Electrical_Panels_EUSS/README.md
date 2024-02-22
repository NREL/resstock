# Electrical Panels
This branch is under active development and may be subject to change. This branch contains postprocessing scripts for estimating electrical panel amerage of dwelling units from ResStock run summary files. The scripts can output: 1) predicted panel amperage using LBNL's DecisionTree model (prelim_panel_model), 2) existing load calculation per 2023 NEC Section 220.

## Environment

Start a conda environment with python>=3.10:

```
conda env create -n panels -f env.yml
conda activate panels
```

## How to Use

For NEC Calculation of existing load
```
usage: postprocess_panel_existing_load_nec.py [-h] [-p] [-d] [-x] [filename]

positional arguments:
  filename              Path to ResStock result file, e.g., results_up00.csv, defaults to test data: test_data/euss1_2018_results_up00_100.csv

options:
  -h, --help            show this help message and exit
  -p, --plot_only       Make plots only based on expected output file without regenerating output_file
  -d, --sfd_only        Apply calculation to Single-Family Detached only (this is only on plotting for now)
  -x, --explode_result  Whether to export intermediate calculations as part of the results (useful for debugging)
```

For panel predicion using LBNL's DecisionTree model
```
usage: apply_panel_regression_model_20240122.py [-h] [-r] [-v] [-p] [-d] [-m] [filename]

positional arguments:
  filename              Path to ResStock result file, e.g., results_up00.csv, defaults to test data: test_data/euss1_2018_results_up00_100.csv

options:
  -h, --help            show this help message and exit
  -r, --retain_proba    If true, output is retained as a probablistic distribution of all output labels and saturation plots give the expected saturation of output. Default is one output label per dwelling
                        unit, PROBABLISTICALLY assigned.
  -v, --validate_model  Whether to validate model with LBNL supplied data by raising the error if caught
  -p, --plot_only       Make plots only based on expected output file without regenerating output file
  -d, --sfd_only        Apply calculation to Single-Family Detached only (this is only on plotting for now)
  -m, --predict_using_model
                        Whether to predict using model, note: model does not have all predictor combinations. Default to predict using tsv, which contains full combinations
```

To plot both LBNL DecisionTree model and NEC calculations applied to ResStock (e.g., for manuscript), use
```
plot_panel_results.ipynb
```

### Version of scripts used for manuscript
- `postprocess_panel_existing_load_nec_v0.py`
- `apply_panel_regression_model_20240122.py` (points to model 16570)
- `plot_panel_results.ipynb`