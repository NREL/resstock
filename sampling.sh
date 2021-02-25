#!/bin/bash

# # run sampling for 2020
# ruby resources/run_sampling.rb -p project_national_2020 -n 25 -o ../scen_bscsv/bs2020_25.csv

# # run sampling for 2025 scenarios
# ruby resources/run_sampling.rb -p project_national_2025_base -n 25 -o ../scen_bscsv/bs2025base_25.csv
# ruby resources/run_sampling.rb -p project_national_2025_hiDR -n 25 -o ../scen_bscsv/bs2025hiDR_25.csv
# ruby resources/run_sampling.rb -p project_national_2025_hiMF -n 25 -o ../scen_bscsv/bs2025hiMF_25.csv
# ruby resources/run_sampling.rb -p project_national_2025_hiDRMF -n 25 -o ../scen_bscsv/bs2025hiDRMF_25.csv

# # run sampling for 2030 scenarios
# ruby resources/run_sampling.rb -p project_national_2030_base -n 25 -o ../scen_bscsv/bs2030base_25.csv
# ruby resources/run_sampling.rb -p project_national_2030_hiDR -n 25 -o ../scen_bscsv/bs2030hiDR_25.csv
# ruby resources/run_sampling.rb -p project_national_2030_hiMF -n 25 -o ../scen_bscsv/bs2030hiMF_25.csv
# ruby resources/run_sampling.rb -p project_national_2030_hiDRMF -n 25 -o ../scen_bscsv/bs2030hiDRMF_25.csv

# # run sampling for 2035 scenarios
# ruby resources/run_sampling.rb -p project_national_2035_base -n 25 -o ../scen_bscsv/bs2035base_25.csv
# ruby resources/run_sampling.rb -p project_national_2035_hiDR -n 25 -o ../scen_bscsv/bs2035hiDR_25.csv
# ruby resources/run_sampling.rb -p project_national_2035_hiMF -n 25 -o ../scen_bscsv/bs2035hiMF_25.csv
# ruby resources/run_sampling.rb -p project_national_2035_hiDRMF -n 25 -o ../scen_bscsv/bs2035hiDRMF_25.csv

# # run sampling for 2040 scenarios
# ruby resources/run_sampling.rb -p project_national_2040_base -n 25 -o ../scen_bscsv/bs2040base_25.csv
# ruby resources/run_sampling.rb -p project_national_2040_hiDR -n 25 -o ../scen_bscsv/bs2040hiDR_25.csv
# ruby resources/run_sampling.rb -p project_national_2040_hiMF -n 25 -o ../scen_bscsv/bs2040hiMF_25.csv
# ruby resources/run_sampling.rb -p project_national_2040_hiDRMF -n 25 -o ../scen_bscsv/bs2040hiDRMF_25.csv

# # run sampling for 2045 scenarios
# ruby resources/run_sampling.rb -p project_national_2045_base -n 25 -o ../scen_bscsv/bs2045base_25.csv
# ruby resources/run_sampling.rb -p project_national_2045_hiDR -n 25 -o ../scen_bscsv/bs2045hiDR_25.csv
# ruby resources/run_sampling.rb -p project_national_2045_hiMF -n 25 -o ../scen_bscsv/bs2045hiMF_25.csv
# ruby resources/run_sampling.rb -p project_national_2045_hiDRMF -n 25 -o ../scen_bscsv/bs2045hiDRMF_25.csv

# # run sampling for 2050 scenarios
# ruby resources/run_sampling.rb -p project_national_2050_base -n 25 -o ../scen_bscsv/bs2050base_25.csv
# ruby resources/run_sampling.rb -p project_national_2050_hiDR -n 25 -o ../scen_bscsv/bs2050hiDR_25.csv
# ruby resources/run_sampling.rb -p project_national_2050_hiMF -n 25 -o ../scen_bscsv/bs2050hiMF_25.csv
# ruby resources/run_sampling.rb -p project_national_2050_hiDRMF -n 25 -o ../scen_bscsv/bs2050hiDRMF_25.csv

# # run sampling for 2055 scenarios
# ruby resources/run_sampling.rb -p project_national_2055_base -n 25 -o ../scen_bscsv/bs2055base_25.csv
# ruby resources/run_sampling.rb -p project_national_2055_hiDR -n 25 -o ../scen_bscsv/bs2055hiDR_25.csv
# ruby resources/run_sampling.rb -p project_national_2055_hiMF -n 25 -o ../scen_bscsv/bs2055hiMF_25.csv
# ruby resources/run_sampling.rb -p project_national_2055_hiDRMF -n 25 -o ../scen_bscsv/bs2055hiDRMF_25.csv

# # run sampling for 2060 scenarios
# ruby resources/run_sampling.rb -p project_national_2060_base -n 25 -o ../scen_bscsv/bs2060base_25.csv
# ruby resources/run_sampling.rb -p project_national_2060_hiDR -n 25 -o ../scen_bscsv/bs2060hiDR_25.csv
# ruby resources/run_sampling.rb -p project_national_2060_hiMF -n 25 -o ../scen_bscsv/bs2060hiMF_25.csv
# ruby resources/run_sampling.rb -p project_national_2060_hiDRMF -n 25 -o ../scen_bscsv/bs2060hiDRMF_25.csv

# # Now implement scenarios with different characteristics in new construction, regarding electrification and floor area
# # make the temporary housing char
# # 2025_base
# cp -r project_national_2025_base project_national_2025_base_DE
# cp project_national_2025_base_DE/scenario_dependent_characteristics/Deep_Electrification/* project_national_2025_base_DE/housing_characteristics/
# ruby resources/run_sampling.rb -p project_national_2025_base_DE -n 25 -o ../scen_bscsv/bs2025baseDE_25.csv

# cp -r project_national_2025_base project_national_2025_base_RFA
# cp project_national_2025_base_RFA/scenario_dependent_characteristics/Reduced_FloorArea/* project_national_2025_base_RFA/housing_characteristics/
# ruby resources/run_sampling.rb -p project_national_2025_base_RFA -n 25 -o ../scen_bscsv/bs2025baseRFA_25.csv

# cp -r project_national_2025_base_DE project_national_2025_base_DERFA
# cp project_national_2025_base_DERFA/scenario_dependent_characteristics/Reduced_FloorArea/* project_national_2025_base_DERFA/housing_characteristics/
# ruby resources/run_sampling.rb -p project_national_2025_base_DERFA -n 25 -o ../scen_bscsv/bs2025baseDERFA_25.csv

# rm -rf project_national_2025_base_DE project_national_2025_base_RFA project_national_2025_base_DERFA
# # repeat for all stock_year scenarios
# # 2025_hiDR
# cp -r project_national_2025_hiDR project_national_2025_hiDR_DE
# cp project_national_2025_hiDR_DE/scenario_dependent_characteristics/Deep_Electrification/* project_national_2025_hiDR_DE/housing_characteristics/
# ruby resources/run_sampling.rb -p project_national_2025_hiDR_DE -n 25 -o ../scen_bscsv/bs2025hiDRDE_25.csv

# cp -r project_national_2025_hiDR project_national_2025_hiDR_RFA
# cp project_national_2025_hiDR_RFA/scenario_dependent_characteristics/Reduced_FloorArea/* project_national_2025_hiDR_RFA/housing_characteristics/
# ruby resources/run_sampling.rb -p project_national_2025_hiDR_RFA -n 25 -o ../scen_bscsv/bs2025hiDRRFA_25.csv

# cp -r project_national_2025_hiDR_DE project_national_2025_hiDR_DERFA
# cp project_national_2025_hiDR_DERFA/scenario_dependent_characteristics/Reduced_FloorArea/* project_national_2025_hiDR_DERFA/housing_characteristics/
# ruby resources/run_sampling.rb -p project_national_2025_hiDR_DERFA -n 25 -o ../scen_bscsv/bs2025hiDRDERFA_25.csv

# rm -rf project_national_2025_hiDR_DE project_national_2025_hiDR_RFA project_national_2025_hiDR_DERFA

# 2025_hiMF
cp -r project_national_2025_hiMF project_national_2025_hiMF_DE
cp project_national_2025_hiMF_DE/scenario_dependent_characteristics/Deep_Electrification/* project_national_2025_hiMF_DE/housing_characteristics/
ruby resources/run_sampling.rb -p project_national_2025_hiMF_DE -n 25 -o ../scen_bscsv/bs2025hiMFDE_25.csv

cp -r project_national_2025_hiMF project_national_2025_hiMF_RFA
cp project_national_2025_hiMF_RFA/scenario_dependent_characteristics/Reduced_FloorArea/* project_national_2025_hiMF_RFA/housing_characteristics/
ruby resources/run_sampling.rb -p project_national_2025_hiMF_RFA -n 25 -o ../scen_bscsv/bs2025hiMFRFA_25.csv

cp -r project_national_2025_hiMF_DE project_national_2025_hiMF_DERFA
cp project_national_2025_hiMF_DERFA/scenario_dependent_characteristics/Reduced_FloorArea/* project_national_2025_hiMF_DERFA/housing_characteristics/
ruby resources/run_sampling.rb -p project_national_2025_hiMF_DERFA -n 25 -o ../scen_bscsv/bs2025hiMFDERFA_25.csv

rm -rf project_national_2025_hiMF_DE project_national_2025_hiMF_RFA project_national_2025_hiMF_DERFA

# 2030_base
cp -r project_national_2030_base project_national_2030_base_DE
cp project_national_2030_base_DE/scenario_dependent_characteristics/Deep_Electrification/* project_national_2030_base_DE/housing_characteristics/
ruby resources/run_sampling.rb -p project_national_2030_base_DE -n 25 -o ../scen_bscsv/bs2030baseDE_25.csv

cp -r project_national_2030_base project_national_2030_base_RFA
cp project_national_2030_base_RFA/scenario_dependent_characteristics/Reduced_FloorArea/* project_national_2030_base_RFA/housing_characteristics/
ruby resources/run_sampling.rb -p project_national_2030_base_RFA -n 25 -o ../scen_bscsv/bs2030baseRFA_25.csv

cp -r project_national_2030_base_DE project_national_2030_base_DERFA
cp project_national_2030_base_DERFA/scenario_dependent_characteristics/Reduced_FloorArea/* project_national_2030_base_DERFA/housing_characteristics/
ruby resources/run_sampling.rb -p project_national_2030_base_DERFA -n 25 -o ../scen_bscsv/bs2030baseDERFA_25.csv

rm -rf project_national_2030_base_DE project_national_2030_base_RFA project_national_2030_base_DERFA
# repeat for all stock_year scenarios
# 2030_hiDR
cp -r project_national_2030_hiDR project_national_2030_hiDR_DE
cp project_national_2030_hiDR_DE/scenario_dependent_characteristics/Deep_Electrification/* project_national_2030_hiDR_DE/housing_characteristics/
ruby resources/run_sampling.rb -p project_national_2030_hiDR_DE -n 25 -o ../scen_bscsv/bs2030hiDRDE_25.csv

cp -r project_national_2030_hiDR project_national_2030_hiDR_RFA
cp project_national_2030_hiDR_RFA/scenario_dependent_characteristics/Reduced_FloorArea/* project_national_2030_hiDR_RFA/housing_characteristics/
ruby resources/run_sampling.rb -p project_national_2030_hiDR_RFA -n 25 -o ../scen_bscsv/bs2030hiDRRFA_25.csv

cp -r project_national_2030_hiDR_DE project_national_2030_hiDR_DERFA
cp project_national_2030_hiDR_DERFA/scenario_dependent_characteristics/Reduced_FloorArea/* project_national_2030_hiDR_DERFA/housing_characteristics/
ruby resources/run_sampling.rb -p project_national_2030_hiDR_DERFA -n 25 -o ../scen_bscsv/bs2030hiDRDERFA_25.csv

rm -rf project_national_2030_hiDR_DE project_national_2030_hiDR_RFA project_national_2030_hiDR_DERFA

# 2030_hiMF
cp -r project_national_2030_hiMF project_national_2030_hiMF_DE
cp project_national_2030_hiMF_DE/scenario_dependent_characteristics/Deep_Electrification/* project_national_2030_hiMF_DE/housing_characteristics/
ruby resources/run_sampling.rb -p project_national_2030_hiMF_DE -n 25 -o ../scen_bscsv/bs2030hiMFDE_25.csv

cp -r project_national_2030_hiMF project_national_2030_hiMF_RFA
cp project_national_2030_hiMF_RFA/scenario_dependent_characteristics/Reduced_FloorArea/* project_national_2030_hiMF_RFA/housing_characteristics/
ruby resources/run_sampling.rb -p project_national_2030_hiMF_RFA -n 25 -o ../scen_bscsv/bs2030hiMFRFA_25.csv

cp -r project_national_2030_hiMF_DE project_national_2030_hiMF_DERFA
cp project_national_2030_hiMF_DERFA/scenario_dependent_characteristics/Reduced_FloorArea/* project_national_2030_hiMF_DERFA/housing_characteristics/
ruby resources/run_sampling.rb -p project_national_2030_hiMF_DERFA -n 25 -o ../scen_bscsv/bs2030hiMFDERFA_25.csv

rm -rf project_national_2030_hiMF_DE project_national_2030_hiMF_RFA project_national_2030_hiMF_DERFA

# 2035_base
cp -r project_national_2035_base project_national_2035_base_DE
cp project_national_2035_base_DE/scenario_dependent_characteristics/Deep_Electrification/* project_national_2035_base_DE/housing_characteristics/
ruby resources/run_sampling.rb -p project_national_2035_base_DE -n 25 -o ../scen_bscsv/bs2035baseDE_25.csv

cp -r project_national_2035_base project_national_2035_base_RFA
cp project_national_2035_base_RFA/scenario_dependent_characteristics/Reduced_FloorArea/* project_national_2035_base_RFA/housing_characteristics/
ruby resources/run_sampling.rb -p project_national_2035_base_RFA -n 25 -o ../scen_bscsv/bs2035baseRFA_25.csv

cp -r project_national_2035_base_DE project_national_2035_base_DERFA
cp project_national_2035_base_DERFA/scenario_dependent_characteristics/Reduced_FloorArea/* project_national_2035_base_DERFA/housing_characteristics/
ruby resources/run_sampling.rb -p project_national_2035_base_DERFA -n 25 -o ../scen_bscsv/bs2035baseDERFA_25.csv

rm -rf project_national_2035_base_DE project_national_2035_base_RFA project_national_2035_base_DERFA
# repeat for all stock_year scenarios
# 2035_hiDR
cp -r project_national_2035_hiDR project_national_2035_hiDR_DE
cp project_national_2035_hiDR_DE/scenario_dependent_characteristics/Deep_Electrification/* project_national_2035_hiDR_DE/housing_characteristics/
ruby resources/run_sampling.rb -p project_national_2035_hiDR_DE -n 25 -o ../scen_bscsv/bs2035hiDRDE_25.csv

cp -r project_national_2035_hiDR project_national_2035_hiDR_RFA
cp project_national_2035_hiDR_RFA/scenario_dependent_characteristics/Reduced_FloorArea/* project_national_2035_hiDR_RFA/housing_characteristics/
ruby resources/run_sampling.rb -p project_national_2035_hiDR_RFA -n 25 -o ../scen_bscsv/bs2035hiDRRFA_25.csv

cp -r project_national_2035_hiDR_DE project_national_2035_hiDR_DERFA
cp project_national_2035_hiDR_DERFA/scenario_dependent_characteristics/Reduced_FloorArea/* project_national_2035_hiDR_DERFA/housing_characteristics/
ruby resources/run_sampling.rb -p project_national_2035_hiDR_DERFA -n 25 -o ../scen_bscsv/bs2035hiDRDERFA_25.csv

rm -rf project_national_2035_hiDR_DE project_national_2035_hiDR_RFA project_national_2035_hiDR_DERFA

# 2035_hiMF
cp -r project_national_2035_hiMF project_national_2035_hiMF_DE
cp project_national_2035_hiMF_DE/scenario_dependent_characteristics/Deep_Electrification/* project_national_2035_hiMF_DE/housing_characteristics/
ruby resources/run_sampling.rb -p project_national_2035_hiMF_DE -n 25 -o ../scen_bscsv/bs2035hiMFDE_25.csv

cp -r project_national_2035_hiMF project_national_2035_hiMF_RFA
cp project_national_2035_hiMF_RFA/scenario_dependent_characteristics/Reduced_FloorArea/* project_national_2035_hiMF_RFA/housing_characteristics/
ruby resources/run_sampling.rb -p project_national_2035_hiMF_RFA -n 25 -o ../scen_bscsv/bs2035hiMFRFA_25.csv

cp -r project_national_2035_hiMF_DE project_national_2035_hiMF_DERFA
cp project_national_2035_hiMF_DERFA/scenario_dependent_characteristics/Reduced_FloorArea/* project_national_2035_hiMF_DERFA/housing_characteristics/
ruby resources/run_sampling.rb -p project_national_2035_hiMF_DERFA -n 25 -o ../scen_bscsv/bs2035hiMFDERFA_25.csv

rm -rf project_national_2035_hiMF_DE project_national_2035_hiMF_RFA project_national_2035_hiMF_DERFA

# 2040_base
cp -r project_national_2040_base project_national_2040_base_DE
cp project_national_2040_base_DE/scenario_dependent_characteristics/Deep_Electrification/* project_national_2040_base_DE/housing_characteristics/
ruby resources/run_sampling.rb -p project_national_2040_base_DE -n 25 -o ../scen_bscsv/bs2040baseDE_25.csv

cp -r project_national_2040_base project_national_2040_base_RFA
cp project_national_2040_base_RFA/scenario_dependent_characteristics/Reduced_FloorArea/* project_national_2040_base_RFA/housing_characteristics/
ruby resources/run_sampling.rb -p project_national_2040_base_RFA -n 25 -o ../scen_bscsv/bs2040baseRFA_25.csv

cp -r project_national_2040_base_DE project_national_2040_base_DERFA
cp project_national_2040_base_DERFA/scenario_dependent_characteristics/Reduced_FloorArea/* project_national_2040_base_DERFA/housing_characteristics/
ruby resources/run_sampling.rb -p project_national_2040_base_DERFA -n 25 -o ../scen_bscsv/bs2040baseDERFA_25.csv

rm -rf project_national_2040_base_DE project_national_2040_base_RFA project_national_2040_base_DERFA
# repeat for all stock_year scenarios
# 2040_hiDR
cp -r project_national_2040_hiDR project_national_2040_hiDR_DE
cp project_national_2040_hiDR_DE/scenario_dependent_characteristics/Deep_Electrification/* project_national_2040_hiDR_DE/housing_characteristics/
ruby resources/run_sampling.rb -p project_national_2040_hiDR_DE -n 25 -o ../scen_bscsv/bs2040hiDRDE_25.csv

cp -r project_national_2040_hiDR project_national_2040_hiDR_RFA
cp project_national_2040_hiDR_RFA/scenario_dependent_characteristics/Reduced_FloorArea/* project_national_2040_hiDR_RFA/housing_characteristics/
ruby resources/run_sampling.rb -p project_national_2040_hiDR_RFA -n 25 -o ../scen_bscsv/bs2040hiDRRFA_25.csv

cp -r project_national_2040_hiDR_DE project_national_2040_hiDR_DERFA
cp project_national_2040_hiDR_DERFA/scenario_dependent_characteristics/Reduced_FloorArea/* project_national_2040_hiDR_DERFA/housing_characteristics/
ruby resources/run_sampling.rb -p project_national_2040_hiDR_DERFA -n 25 -o ../scen_bscsv/bs2040hiDRDERFA_25.csv

rm -rf project_national_2040_hiDR_DE project_national_2040_hiDR_RFA project_national_2040_hiDR_DERFA

# 2040_hiMF
cp -r project_national_2040_hiMF project_national_2040_hiMF_DE
cp project_national_2040_hiMF_DE/scenario_dependent_characteristics/Deep_Electrification/* project_national_2040_hiMF_DE/housing_characteristics/
ruby resources/run_sampling.rb -p project_national_2040_hiMF_DE -n 25 -o ../scen_bscsv/bs2040hiMFDE_25.csv

cp -r project_national_2040_hiMF project_national_2040_hiMF_RFA
cp project_national_2040_hiMF_RFA/scenario_dependent_characteristics/Reduced_FloorArea/* project_national_2040_hiMF_RFA/housing_characteristics/
ruby resources/run_sampling.rb -p project_national_2040_hiMF_RFA -n 25 -o ../scen_bscsv/bs2040hiMFRFA_25.csv

cp -r project_national_2040_hiMF_DE project_national_2040_hiMF_DERFA
cp project_national_2040_hiMF_DERFA/scenario_dependent_characteristics/Reduced_FloorArea/* project_national_2040_hiMF_DERFA/housing_characteristics/
ruby resources/run_sampling.rb -p project_national_2040_hiMF_DERFA -n 25 -o ../scen_bscsv/bs2040hiMFDERFA_25.csv

rm -rf project_national_2040_hiMF_DE project_national_2040_hiMF_RFA project_national_2040_hiMF_DERFA

# 2045_base
cp -r project_national_2045_base project_national_2045_base_DE
cp project_national_2045_base_DE/scenario_dependent_characteristics/Deep_Electrification/* project_national_2045_base_DE/housing_characteristics/
ruby resources/run_sampling.rb -p project_national_2045_base_DE -n 25 -o ../scen_bscsv/bs2045baseDE_25.csv

cp -r project_national_2045_base project_national_2045_base_RFA
cp project_national_2045_base_RFA/scenario_dependent_characteristics/Reduced_FloorArea/* project_national_2045_base_RFA/housing_characteristics/
ruby resources/run_sampling.rb -p project_national_2045_base_RFA -n 25 -o ../scen_bscsv/bs2045baseRFA_25.csv

cp -r project_national_2045_base_DE project_national_2045_base_DERFA
cp project_national_2045_base_DERFA/scenario_dependent_characteristics/Reduced_FloorArea/* project_national_2045_base_DERFA/housing_characteristics/
ruby resources/run_sampling.rb -p project_national_2045_base_DERFA -n 25 -o ../scen_bscsv/bs2045baseDERFA_25.csv

rm -rf project_national_2045_base_DE project_national_2045_base_RFA project_national_2045_base_DERFA
# repeat for all stock_year scenarios
# 2045_hiDR
cp -r project_national_2045_hiDR project_national_2045_hiDR_DE
cp project_national_2045_hiDR_DE/scenario_dependent_characteristics/Deep_Electrification/* project_national_2045_hiDR_DE/housing_characteristics/
ruby resources/run_sampling.rb -p project_national_2045_hiDR_DE -n 25 -o ../scen_bscsv/bs2045hiDRDE_25.csv

cp -r project_national_2045_hiDR project_national_2045_hiDR_RFA
cp project_national_2045_hiDR_RFA/scenario_dependent_characteristics/Reduced_FloorArea/* project_national_2045_hiDR_RFA/housing_characteristics/
ruby resources/run_sampling.rb -p project_national_2045_hiDR_RFA -n 25 -o ../scen_bscsv/bs2045hiDRRFA_25.csv

cp -r project_national_2045_hiDR_DE project_national_2045_hiDR_DERFA
cp project_national_2045_hiDR_DERFA/scenario_dependent_characteristics/Reduced_FloorArea/* project_national_2045_hiDR_DERFA/housing_characteristics/
ruby resources/run_sampling.rb -p project_national_2045_hiDR_DERFA -n 25 -o ../scen_bscsv/bs2045hiDRDERFA_25.csv

rm -rf project_national_2045_hiDR_DE project_national_2045_hiDR_RFA project_national_2045_hiDR_DERFA

# 2045_hiMF
cp -r project_national_2045_hiMF project_national_2045_hiMF_DE
cp project_national_2045_hiMF_DE/scenario_dependent_characteristics/Deep_Electrification/* project_national_2045_hiMF_DE/housing_characteristics/
ruby resources/run_sampling.rb -p project_national_2045_hiMF_DE -n 25 -o ../scen_bscsv/bs2045hiMFDE_25.csv

cp -r project_national_2045_hiMF project_national_2045_hiMF_RFA
cp project_national_2045_hiMF_RFA/scenario_dependent_characteristics/Reduced_FloorArea/* project_national_2045_hiMF_RFA/housing_characteristics/
ruby resources/run_sampling.rb -p project_national_2045_hiMF_RFA -n 25 -o ../scen_bscsv/bs2045hiMFRFA_25.csv

cp -r project_national_2045_hiMF_DE project_national_2045_hiMF_DERFA
cp project_national_2045_hiMF_DERFA/scenario_dependent_characteristics/Reduced_FloorArea/* project_national_2045_hiMF_DERFA/housing_characteristics/
ruby resources/run_sampling.rb -p project_national_2045_hiMF_DERFA -n 25 -o ../scen_bscsv/bs2045hiMFDERFA_25.csv

rm -rf project_national_2045_hiMF_DE project_national_2045_hiMF_RFA project_national_2045_hiMF_DERFA

# 2050_base
cp -r project_national_2050_base project_national_2050_base_DE
cp project_national_2050_base_DE/scenario_dependent_characteristics/Deep_Electrification/* project_national_2050_base_DE/housing_characteristics/
ruby resources/run_sampling.rb -p project_national_2050_base_DE -n 25 -o ../scen_bscsv/bs2050baseDE_25.csv

cp -r project_national_2050_base project_national_2050_base_RFA
cp project_national_2050_base_RFA/scenario_dependent_characteristics/Reduced_FloorArea/* project_national_2050_base_RFA/housing_characteristics/
ruby resources/run_sampling.rb -p project_national_2050_base_RFA -n 25 -o ../scen_bscsv/bs2050baseRFA_25.csv

cp -r project_national_2050_base_DE project_national_2050_base_DERFA
cp project_national_2050_base_DERFA/scenario_dependent_characteristics/Reduced_FloorArea/* project_national_2050_base_DERFA/housing_characteristics/
ruby resources/run_sampling.rb -p project_national_2050_base_DERFA -n 25 -o ../scen_bscsv/bs2050baseDERFA_25.csv

rm -rf project_national_2050_base_DE project_national_2050_base_RFA project_national_2050_base_DERFA
# repeat for all stock_year scenarios
# 2050_hiDR
cp -r project_national_2050_hiDR project_national_2050_hiDR_DE
cp project_national_2050_hiDR_DE/scenario_dependent_characteristics/Deep_Electrification/* project_national_2050_hiDR_DE/housing_characteristics/
ruby resources/run_sampling.rb -p project_national_2050_hiDR_DE -n 25 -o ../scen_bscsv/bs2050hiDRDE_25.csv

cp -r project_national_2050_hiDR project_national_2050_hiDR_RFA
cp project_national_2050_hiDR_RFA/scenario_dependent_characteristics/Reduced_FloorArea/* project_national_2050_hiDR_RFA/housing_characteristics/
ruby resources/run_sampling.rb -p project_national_2050_hiDR_RFA -n 25 -o ../scen_bscsv/bs2050hiDRRFA_25.csv

cp -r project_national_2050_hiDR_DE project_national_2050_hiDR_DERFA
cp project_national_2050_hiDR_DERFA/scenario_dependent_characteristics/Reduced_FloorArea/* project_national_2050_hiDR_DERFA/housing_characteristics/
ruby resources/run_sampling.rb -p project_national_2050_hiDR_DERFA -n 25 -o ../scen_bscsv/bs2050hiDRDERFA_25.csv

rm -rf project_national_2050_hiDR_DE project_national_2050_hiDR_RFA project_national_2050_hiDR_DERFA

# 2050_hiMF
cp -r project_national_2050_hiMF project_national_2050_hiMF_DE
cp project_national_2050_hiMF_DE/scenario_dependent_characteristics/Deep_Electrification/* project_national_2050_hiMF_DE/housing_characteristics/
ruby resources/run_sampling.rb -p project_national_2050_hiMF_DE -n 25 -o ../scen_bscsv/bs2050hiMFDE_25.csv

cp -r project_national_2050_hiMF project_national_2050_hiMF_RFA
cp project_national_2050_hiMF_RFA/scenario_dependent_characteristics/Reduced_FloorArea/* project_national_2050_hiMF_RFA/housing_characteristics/
ruby resources/run_sampling.rb -p project_national_2050_hiMF_RFA -n 25 -o ../scen_bscsv/bs2050hiMFRFA_25.csv

cp -r project_national_2050_hiMF_DE project_national_2050_hiMF_DERFA
cp project_national_2050_hiMF_DERFA/scenario_dependent_characteristics/Reduced_FloorArea/* project_national_2050_hiMF_DERFA/housing_characteristics/
ruby resources/run_sampling.rb -p project_national_2050_hiMF_DERFA -n 25 -o ../scen_bscsv/bs2050hiMFDERFA_25.csv

rm -rf project_national_2050_hiMF_DE project_national_2050_hiMF_RFA project_national_2050_hiMF_DERFA

# 2055_base
cp -r project_national_2055_base project_national_2055_base_DE
cp project_national_2055_base_DE/scenario_dependent_characteristics/Deep_Electrification/* project_national_2055_base_DE/housing_characteristics/
ruby resources/run_sampling.rb -p project_national_2055_base_DE -n 25 -o ../scen_bscsv/bs2055baseDE_25.csv

cp -r project_national_2055_base project_national_2055_base_RFA
cp project_national_2055_base_RFA/scenario_dependent_characteristics/Reduced_FloorArea/* project_national_2055_base_RFA/housing_characteristics/
ruby resources/run_sampling.rb -p project_national_2055_base_RFA -n 25 -o ../scen_bscsv/bs2055baseRFA_25.csv

cp -r project_national_2055_base_DE project_national_2055_base_DERFA
cp project_national_2055_base_DERFA/scenario_dependent_characteristics/Reduced_FloorArea/* project_national_2055_base_DERFA/housing_characteristics/
ruby resources/run_sampling.rb -p project_national_2055_base_DERFA -n 25 -o ../scen_bscsv/bs2055baseDERFA_25.csv

rm -rf project_national_2055_base_DE project_national_2055_base_RFA project_national_2055_base_DERFA
# repeat for all stock_year scenarios
# 2055_hiDR
cp -r project_national_2055_hiDR project_national_2055_hiDR_DE
cp project_national_2055_hiDR_DE/scenario_dependent_characteristics/Deep_Electrification/* project_national_2055_hiDR_DE/housing_characteristics/
ruby resources/run_sampling.rb -p project_national_2055_hiDR_DE -n 25 -o ../scen_bscsv/bs2055hiDRDE_25.csv

cp -r project_national_2055_hiDR project_national_2055_hiDR_RFA
cp project_national_2055_hiDR_RFA/scenario_dependent_characteristics/Reduced_FloorArea/* project_national_2055_hiDR_RFA/housing_characteristics/
ruby resources/run_sampling.rb -p project_national_2055_hiDR_RFA -n 25 -o ../scen_bscsv/bs2055hiDRRFA_25.csv

cp -r project_national_2055_hiDR_DE project_national_2055_hiDR_DERFA
cp project_national_2055_hiDR_DERFA/scenario_dependent_characteristics/Reduced_FloorArea/* project_national_2055_hiDR_DERFA/housing_characteristics/
ruby resources/run_sampling.rb -p project_national_2055_hiDR_DERFA -n 25 -o ../scen_bscsv/bs2055hiDRDERFA_25.csv

rm -rf project_national_2055_hiDR_DE project_national_2055_hiDR_RFA project_national_2055_hiDR_DERFA

# 2055_hiMF
cp -r project_national_2055_hiMF project_national_2055_hiMF_DE
cp project_national_2055_hiMF_DE/scenario_dependent_characteristics/Deep_Electrification/* project_national_2055_hiMF_DE/housing_characteristics/
ruby resources/run_sampling.rb -p project_national_2055_hiMF_DE -n 25 -o ../scen_bscsv/bs2055hiMFDE_25.csv

cp -r project_national_2055_hiMF project_national_2055_hiMF_RFA
cp project_national_2055_hiMF_RFA/scenario_dependent_characteristics/Reduced_FloorArea/* project_national_2055_hiMF_RFA/housing_characteristics/
ruby resources/run_sampling.rb -p project_national_2055_hiMF_RFA -n 25 -o ../scen_bscsv/bs2055hiMFRFA_25.csv

cp -r project_national_2055_hiMF_DE project_national_2055_hiMF_DERFA
cp project_national_2055_hiMF_DERFA/scenario_dependent_characteristics/Reduced_FloorArea/* project_national_2055_hiMF_DERFA/housing_characteristics/
ruby resources/run_sampling.rb -p project_national_2055_hiMF_DERFA -n 25 -o ../scen_bscsv/bs2055hiMFDERFA_25.csv

rm -rf project_national_2055_hiMF_DE project_national_2055_hiMF_RFA project_national_2055_hiMF_DERFA

# 2060_base
cp -r project_national_2060_base project_national_2060_base_DE
cp project_national_2060_base_DE/scenario_dependent_characteristics/Deep_Electrification/* project_national_2060_base_DE/housing_characteristics/
ruby resources/run_sampling.rb -p project_national_2060_base_DE -n 25 -o ../scen_bscsv/bs2060baseDE_25.csv

cp -r project_national_2060_base project_national_2060_base_RFA
cp project_national_2060_base_RFA/scenario_dependent_characteristics/Reduced_FloorArea/* project_national_2060_base_RFA/housing_characteristics/
ruby resources/run_sampling.rb -p project_national_2060_base_RFA -n 25 -o ../scen_bscsv/bs2060baseRFA_25.csv

cp -r project_national_2060_base_DE project_national_2060_base_DERFA
cp project_national_2060_base_DERFA/scenario_dependent_characteristics/Reduced_FloorArea/* project_national_2060_base_DERFA/housing_characteristics/
ruby resources/run_sampling.rb -p project_national_2060_base_DERFA -n 25 -o ../scen_bscsv/bs2060baseDERFA_25.csv

rm -rf project_national_2060_base_DE project_national_2060_base_RFA project_national_2060_base_DERFA
# repeat for all stock_year scenarios
# 2060_hiDR
cp -r project_national_2060_hiDR project_national_2060_hiDR_DE
cp project_national_2060_hiDR_DE/scenario_dependent_characteristics/Deep_Electrification/* project_national_2060_hiDR_DE/housing_characteristics/
ruby resources/run_sampling.rb -p project_national_2060_hiDR_DE -n 25 -o ../scen_bscsv/bs2060hiDRDE_25.csv

cp -r project_national_2060_hiDR project_national_2060_hiDR_RFA
cp project_national_2060_hiDR_RFA/scenario_dependent_characteristics/Reduced_FloorArea/* project_national_2060_hiDR_RFA/housing_characteristics/
ruby resources/run_sampling.rb -p project_national_2060_hiDR_RFA -n 25 -o ../scen_bscsv/bs2060hiDRRFA_25.csv

cp -r project_national_2060_hiDR_DE project_national_2060_hiDR_DERFA
cp project_national_2060_hiDR_DERFA/scenario_dependent_characteristics/Reduced_FloorArea/* project_national_2060_hiDR_DERFA/housing_characteristics/
ruby resources/run_sampling.rb -p project_national_2060_hiDR_DERFA -n 25 -o ../scen_bscsv/bs2060hiDRDERFA_25.csv

rm -rf project_national_2060_hiDR_DE project_national_2060_hiDR_RFA project_national_2060_hiDR_DERFA

# 2060_hiMF
cp -r project_national_2060_hiMF project_national_2060_hiMF_DE
cp project_national_2060_hiMF_DE/scenario_dependent_characteristics/Deep_Electrification/* project_national_2060_hiMF_DE/housing_characteristics/
ruby resources/run_sampling.rb -p project_national_2060_hiMF_DE -n 25 -o ../scen_bscsv/bs2060hiMFDE_25.csv

cp -r project_national_2060_hiMF project_national_2060_hiMF_RFA
cp project_national_2060_hiMF_RFA/scenario_dependent_characteristics/Reduced_FloorArea/* project_national_2060_hiMF_RFA/housing_characteristics/
ruby resources/run_sampling.rb -p project_national_2060_hiMF_RFA -n 25 -o ../scen_bscsv/bs2060hiMFRFA_25.csv

cp -r project_national_2060_hiMF_DE project_national_2060_hiMF_DERFA
cp project_national_2060_hiMF_DERFA/scenario_dependent_characteristics/Reduced_FloorArea/* project_national_2060_hiMF_DERFA/housing_characteristics/
ruby resources/run_sampling.rb -p project_national_2060_hiMF_DERFA -n 25 -o ../scen_bscsv/bs2060hiMFDERFA_25.csv

rm -rf project_national_2060_hiMF_DE project_national_2060_hiMF_RFA project_national_2060_hiMF_DERFA