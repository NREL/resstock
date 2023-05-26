If the set of testing project TSV files gets changed, the "outdated" sample test files will need to be re-generated. For generating buildstock_extra.csv and buildstock_missing.csv precomputed sample files:
1. Change n_datapoints for testing_baseline.yml to 2
2. Run ``openstudio workflow/run_analysis.rb -y project_testing/testing_baseline.yml -s``
3. Copy the buildstock.csv, and either rename to:
   - buildstock_extra.csv; then add column "Extra Parameter" with options of "1" and "2"
   - buildstock_missing.csv; then remove column "HVAC Cooling Partial Space Conditioning"
