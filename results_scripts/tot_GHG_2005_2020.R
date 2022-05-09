rm(list=ls()) # clear workspace i.e. remove saved variables
cat("\014") # clear console

# Last Update Peter Berrill May 8 2022

# Purpose: Estimate 2005/2020 total residential emissions, including energy and embodied emissions, and based on that calculate emission reduction targets for 2030 and 2050

# Inputs: - ExtData/US_FA_GHG_summaries.RData
#         - Reported statistics on US energy emissions and residential construction activities

# Outputs: 
#         - Estimates of total residential emissions in 2005 and 2020, and 2030/2050 targets based on 2005/2020 emissions

# energy emissions from most recent (2022) US GHG Inventory https://www.epa.gov/ghgemissions/inventory-us-greenhouse-gas-emissions-and-sinks-1990-2020, see table ES-6
en05=1247.2 # energy emissions in MT CO2e
en20=923.1 # energy emissions in MT CO2e


# let's see what 2005 residential emissions are based on a floor area perspective
load("../ExtData/US_FA_GHG_summaries.RData")

# GHG intensities per m2 by three housing types:
emb05_LC<-data.frame(type=c('SF','MF','MH'), GHG_int_kgm2=c(us_base_FA$GHG_NC_SF[1]/us_base_FA$NC_SF_m2[1],us_base_FA$GHG_NC_MF[1]/us_base_FA$NC_MF_m2[1],us_base_FA$GHG_NC_MH[1]/us_base_FA$NC_MH_m2[1]))

# Number of housing units constructed in 05, from survey of construction/Census, can be found here https://github.com/peterberr/US_county_HSM/tree/main/Data
emb05_LC$Units<-c(1635900,295500,146800)

# average size in m2 of SF, MF, MH in 2005, from characteristics of new construction (https://www.census.gov/construction/chars/) and MH survey (https://www.census.gov/data/tables/time-series/econ/mhs/annual-data.html) - MH data of avg size unavailable before 2014, assumed 2014 avg size for 2005
# 2434, 1247, 1438 sqft respectively
emb05_LC$avg_m2<-c(226.1,115.8,134)
emb05_LC$Tot_m2<-emb05_LC$avg_m2*emb05_LC$Units
emb05_LC$Tot_GHG_kg<-emb05_LC$Tot_m2*emb05_LC$GHG_int_kgm2
# total embodied emissions in ktons.
sumemb05_LC<-round(sum(emb05_LC$Tot_GHG_kg)*1e-6)  # 84.33 Mt

tot_GHG_05_Mt<-0.001*sumemb05_LC+en05

# redo embodied emissions for 2020
emb20_LC<-emb05_LC
# housing units constructed in 2020
emb20_LC$Units<-c(1286900,375200,94400)
# avg size of housing built in 2020
emb20_LC$avg_m2<-c(230.4,104.1,136.5)
emb20_LC$Tot_m2<-emb20_LC$avg_m2*emb20_LC$Units
emb20_LC$Tot_GHG_kg<-emb20_LC$Tot_m2*emb20_LC$GHG_int_kgm2
# total embodied emissions in ktons.
sumemb20_LC<-round(sum(emb20_LC$Tot_GHG_kg)*1e-6) # 69.86 Mt

# for reference, here is what the housing stock model estimates for embodied emissions from construction in 2020.
est_emb20_LC<-round(us_base_FA$GHG_NC[1]*1e-6) # 88.59 Mt
# the model-based estimate is 27% higher than the observed floor area based estimate, probably due to the model esimating higher construction than what actually occured, in part due to the convergence of vacancy rates meaning a lot more construction occurs in urban areas

tot_GHG_20_Mt<-0.001*sumemb20_LC+en20

# AK and HI's 2005 and 2009 res energy consumption, from EIA-SEDS
akhi<-data.frame(year=c(2005,2005,2005,2019,2019,2019), state=c('AK','HI','US','AK','HI','US'),res_Gbtu=c(53.5,48.6,21574,33.7,34.5,21037))
100*sum(akhi$res_Gbtu[1:2])/akhi$res_Gbtu[3] # 0.5% of 2005 US res energy
100*sum(akhi$res_Gbtu[4:5])/akhi$res_Gbtu[6] # 0.3% of 2019 US res energy

# So, only 0.5% of residential energy is used in these two states combined. Howevr, 1.1% of all energy related CO2, and 1% of US residential direct and electricity (all) emissions occured in AK and HI in 2018, see here https://www.eia.gov/environment/emissions/state/excel/table4.xlsx
# Further, 0,6% of the housing stock is located in these two states.
# So I think 99% is the best correction factor to reduce US residential emissions by, in order to reflect the absence of these from our model

# need to include correction factor for AK and HI
round(0.99*0.5*tot_GHG_20_Mt) # 492
round(0.99*0.5*tot_GHG_05_Mt) # 659
round(0.99*0.2*tot_GHG_05_Mt) # 264

round(0.99*tot_GHG_20_Mt) # 983
round(0.99*tot_GHG_05_Mt) # 1318