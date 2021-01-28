#!/bin/bash

# run sampling for 2025 scenarios
ruby resources/run_sampling.rb -p project_national_2025_base -n 15000 -o bs2025base15k.csv
ruby resources/run_sampling.rb -p project_national_2025_hiDR -n 15000 -o bs2025hiDR15k.csv
ruby resources/run_sampling.rb -p project_national_2025_hiMF -n 15000 -o bs2025hiMF15k.csv
ruby resources/run_sampling.rb -p project_national_2025_hiDRMF -n 15000 -o bs2025hiDRMF15k.csv

# run sampling for 2030 scenarios
ruby resources/run_sampling.rb -p project_national_2030_base -n 15000 -o bs2030base15k.csv
ruby resources/run_sampling.rb -p project_national_2030_hiDR -n 15000 -o bs2030hiDR15k.csv
ruby resources/run_sampling.rb -p project_national_2030_hiMF -n 15000 -o bs2030hiMF15k.csv
ruby resources/run_sampling.rb -p project_national_2030_hiDRMF -n 15000 -o bs2030hiDRMF15k.csv

# run sampling for 2035 scenarios
ruby resources/run_sampling.rb -p project_national_2035_base -n 15000 -o bs2035base15k.csv
ruby resources/run_sampling.rb -p project_national_2035_hiDR -n 15000 -o bs2035hiDR15k.csv
ruby resources/run_sampling.rb -p project_national_2035_hiMF -n 15000 -o bs2035hiMF15k.csv
ruby resources/run_sampling.rb -p project_national_2035_hiDRMF -n 15000 -o bs2035hiDRMF15k.csv

# run sampling for 2040 scenarios
ruby resources/run_sampling.rb -p project_national_2040_base -n 15000 -o bs2040base15k.csv
ruby resources/run_sampling.rb -p project_national_2040_hiDR -n 15000 -o bs2040hiDR15k.csv
ruby resources/run_sampling.rb -p project_national_2040_hiMF -n 15000 -o bs2040hiMF15k.csv
ruby resources/run_sampling.rb -p project_national_2040_hiDRMF -n 15000 -o bs2040hiDRMF15k.csv

# run sampling for 2045 scenarios
ruby resources/run_sampling.rb -p project_national_2045_base -n 15000 -o bs2045base15k.csv
ruby resources/run_sampling.rb -p project_national_2045_hiDR -n 15000 -o bs2045hiDR15k.csv
ruby resources/run_sampling.rb -p project_national_2045_hiMF -n 15000 -o bs2045hiMF15k.csv
ruby resources/run_sampling.rb -p project_national_2045_hiDRMF -n 15000 -o bs2045hiDRMF15k.csv

# run sampling for 2050 scenarios
ruby resources/run_sampling.rb -p project_national_2050_base -n 15000 -o bs2050base15k.csv
ruby resources/run_sampling.rb -p project_national_2050_hiDR -n 15000 -o bs2050hiDR15k.csv
ruby resources/run_sampling.rb -p project_national_2050_hiMF -n 15000 -o bs2050hiMF15k.csv
ruby resources/run_sampling.rb -p project_national_2050_hiDRMF -n 15000 -o bs2050hiDRMF15k.csv

# run sampling for 2055 scenarios
ruby resources/run_sampling.rb -p project_national_2055_base -n 15000 -o bs2055base15k.csv
ruby resources/run_sampling.rb -p project_national_2055_hiDR -n 15000 -o bs2055hiDR15k.csv
ruby resources/run_sampling.rb -p project_national_2055_hiMF -n 15000 -o bs2055hiMF15k.csv
ruby resources/run_sampling.rb -p project_national_2055_hiDRMF -n 15000 -o bs2055hiDRMF15k.csv

# run sampling for 2060 scenarios
ruby resources/run_sampling.rb -p project_national_2060_base -n 15000 -o bs2060base15k.csv
ruby resources/run_sampling.rb -p project_national_2060_hiDR -n 15000 -o bs2060hiDR15k.csv
ruby resources/run_sampling.rb -p project_national_2060_hiMF -n 15000 -o bs2060hiMF15k.csv
ruby resources/run_sampling.rb -p project_national_2060_hiDRMF -n 15000 -o bs2060hiDRMF15k.csv