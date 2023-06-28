If the set of testing project TSV files gets changed, the sample test file will need to be re-generated. For generating buildstock.csv precomputed sample file:
1. Change n_datapoints for testing_baseline.yml to 2
2. Run ``openstudio workflow/run_analysis.rb -y project_testing/testing_baseline.yml -s``
3. Copy the buildstock.csv
