# script to calculate stock decay by house type and cohort, for each county, over the period 2020-2060
rm(list=ls()) # clear workspace i.e. remove saved variables
cat("\014") # clear console
setwd("~/Yale Courses/Research/Final Paper/resstock_projections/projection_scripts")

# Last Update Peter Berrill April 30 2022

# Purpose: Calculate projected decay of housing stock by county, vintage/cohort, and house type (3) for each five years 2020-2060

# Inputs: - County_Scenario_SM_Results.RData, summary of housing stock model by county for each year 2020-2060, from Berrill & Hertwich https://doi.org/10.5334/bc.126, available at https://github.com/peterberr/US_county_HSM
#         - ctycode.RData, county FIPS code and name
# Outputs: 
#         - Intermediate_results/decayFactors.RData
#         - Intermediate_results/decayFactorsRen.RData, for use in describing decay of <2020 stock only in the renovation scenarios
#         - Intermediate_results/decayFactorsProj.RData, for projecting the decay of housing stock including future cohorts built after 2020

library(reshape2)
library(dplyr)
# load in county level results, quite a big file, can be found here https://github.com/peterberr/US_county_HSM
load("~/Yale Courses/Research/Final Paper/HSM_github/HSM_results/County_Scenario_SM_Results.RData") 
n<-names(smop_base[[3]][[1]])

cohorts<-substr(n[50:59],17,23)
years<-as.character(seq(2025,2060,5))
# define weighting factor names. WFs will track the evolution of each type-cohort combo (occupied homes) for the eight years 2025, 2030, ... , 2060
wf_names<-paste(rep("wf_SF_",80),rep(cohorts,each=8),"_",years,sep="")
wf_names[81:160]<-paste(rep("wf_MF_",80),rep(cohorts,each=8),"_",years,sep="")
wf_names[161:240]<-paste(rep("wf_MH_",80),rep(cohorts,each=8),"_",years,sep="")
shdr<-shmf<-shdm<-sb<-smop_base[,1:2]

for (i in 1:3142) { # 3142 counties
  # calculate decay factors for SF homes in the baseline scenario, by dividing occupied units in future years by their 2020 values
  sb[i,wf_names[1:48]]<-unlist(smop_base[[3]][[i]][c(seq(6,41,5)),110:115]/unlist(rep(smop_base[[3]][[i]][1,110:115],each=8))) # decay factors for pre-2020 SF up to 2060
  sb[i,wf_names[49:50]]<-1 # new construction of 2020s cohort in 2025 and 2030 are unchanged
  sb[i,wf_names[51:56]]<-unlist(smop_base[[3]][[i]][c(seq(16,41,5)),116]/unlist(smop_base[[3]][[i]][11,116])) # 2020s cohort from 2035 onwards (6 sim years)
  # wf_names 57 and 58 (change in 2030s cohort in 2025 and 2030) do not exist
  sb[i,wf_names[59:60]]<-1 # new construction of 2030s cohort in 2035 and 2040 are unchanged
  sb[i,wf_names[61:64]]<-unlist(smop_base[[3]][[i]][c(seq(26,41,5)),117]/unlist(smop_base[[3]][[i]][21,117])) # 2030s cohort from 2045 onwards (4 sim years)
  # wf_names 65 to 68 (change in 2040s cohort in 2025:2040) do not exist
  sb[i,wf_names[69:70]]<-1 # new construction of 2040s cohort in 2045 and 2050 are unchanged
  sb[i,wf_names[71:72]]<-unlist(smop_base[[3]][[i]][c(seq(36,41,5)),118]/unlist(smop_base[[3]][[i]][31,118])) # 2040s cohort from 2055 onwards (2 sim years)
  # wf_names 73 to 78 (change in 2050s cohort in 2025:2050) do not exist
  sb[i,wf_names[79:80]]<-1 # new construction of 2050s cohort in 2055 and 2060 are unchanged
  
  # now repeat for MF 
  sb[i,wf_names[81:128]]<-unlist(smop_base[[3]][[i]][c(seq(6,41,5)),130:135]/unlist(rep(smop_base[[3]][[i]][1,130:135],each=8)))# decay factors for pre-2020 MF up to 2060
  sb[i,wf_names[129:130]]<-1 # new construction of 2020s cohort in 2025 and 2030 are unchanged
  sb[i,wf_names[131:136]]<-unlist(smop_base[[3]][[i]][c(seq(16,41,5)),136]/unlist(smop_base[[3]][[i]][11,136])) # 2020s cohort from 2035 onwards (6 sim years)
  # wf_names 137 and 138 (change in 2030s cohort in 2025 and 2030) do not exist
  sb[i,wf_names[139:140]]<-1 # new construction of 2030s cohort in 2035 and 2040 are unchanged
  sb[i,wf_names[141:144]]<-unlist(smop_base[[3]][[i]][c(seq(26,41,5)),137]/unlist(smop_base[[3]][[i]][21,137])) # 2030s cohort from 2045 onwards (4 sim years)
  # wf_names 145 to 148 (change in 2040s cohort in 2025:2040) do not exist
  sb[i,wf_names[149:150]]<-1 # new construction of 2040s cohort in 2045 and 2050 are unchanged
  sb[i,wf_names[151:152]]<-unlist(smop_base[[3]][[i]][c(seq(36,41,5)),138]/unlist(smop_base[[3]][[i]][31,138])) # 2040s cohort from 2055 onwards (2 sim years)
  # wf_names 153 to 158 (change in 2050s cohort in 2025:2050) do not exist
  sb[i,wf_names[159:160]]<-1 # new construction of 2050s cohort in 2055 and 2060 are unchanged
  
  # now repeat for MH
  sb[i,wf_names[161:208]]<-unlist(smop_base[[3]][[i]][c(seq(6,41,5)),150:155]/unlist(rep(smop_base[[3]][[i]][1,150:155],each=8))) # decay factors for pre-2020 MH up to 2060
  sb[i,wf_names[209:210]]<-1 # new construction of 2020s cohort in 2025 and 2030 are unchanged
  sb[i,wf_names[211:216]]<-unlist(smop_base[[3]][[i]][c(seq(16,41,5)),156]/unlist(smop_base[[3]][[i]][11,156])) # 2020s cohort from 2035 onwards (6 sim years)
  # wf_names 217 and 218 (change in 2030s cohort in 2025 and 2030) do not exist
  sb[i,wf_names[219:220]]<-1 # new construction of 2030s cohort in 2035 and 2040 are unchanged
  sb[i,wf_names[221:224]]<-unlist(smop_base[[3]][[i]][c(seq(26,41,5)),157]/unlist(smop_base[[3]][[i]][21,157])) # 2030s cohort from 2045 onwards (4 sim years)
  # wf_names 145 to 148 (change in 2040s cohort in 2025:2040) do not exist
  sb[i,wf_names[229:230]]<-1 # new construction of 2040s cohort in 2045 and 2050 are unchanged
  sb[i,wf_names[231:232]]<-unlist(smop_base[[3]][[i]][c(seq(36,41,5)),158]/unlist(smop_base[[3]][[i]][31,158])) # 2040s cohort from 2055 onwards (2 sim years)
  # wf_names 153 to 158 (change in 2050s cohort in 2025:2050) do not exist
  sb[i,wf_names[239:240]]<-1 # new construction of 2050s cohort in 2055 and 2060 are unchanged
  
  
  # calculate decay factors for SF homes in the hi DR scenario 
  shdr[i,wf_names[1:48]]<-unlist(smop_hiDR[[3]][[i]][c(seq(6,41,5)),110:115]/unlist(rep(smop_hiDR[[3]][[i]][1,110:115],each=8))) # decay factors for pre-2020 SF up to 2060
  shdr[i,wf_names[49:50]]<-1 # new construction of 2020s cohort in 2025 and 2030 are unchanged
  shdr[i,wf_names[51:56]]<-unlist(smop_hiDR[[3]][[i]][c(seq(16,41,5)),116]/unlist(smop_hiDR[[3]][[i]][11,116])) # 2020s cohort from 2035 onwards (6 sim years)
  # wf_names 57 and 58 (change in 2030s cohort in 2025 and 2030) do not exist
  shdr[i,wf_names[59:60]]<-1 # new construction of 2030s cohort in 2035 and 2040 are unchanged
  shdr[i,wf_names[61:64]]<-unlist(smop_hiDR[[3]][[i]][c(seq(26,41,5)),117]/unlist(smop_hiDR[[3]][[i]][21,117])) # 2030s cohort from 2045 onwards (4 sim years)
  # wf_names 65 to 68 (change in 2040s cohort in 2025:2040) do not exist
  shdr[i,wf_names[69:70]]<-1 # new construction of 2040s cohort in 2045 and 2050 are unchanged
  shdr[i,wf_names[71:72]]<-unlist(smop_hiDR[[3]][[i]][c(seq(36,41,5)),118]/unlist(smop_hiDR[[3]][[i]][31,118])) # 2040s cohort from 2055 onwards (2 sim years)
  # wf_names 73 to 78 (change in 2050s cohort in 2025:2050) do not exist
  shdr[i,wf_names[79:80]]<-1 # new construction of 2050s cohort in 2055 and 2060 are unchanged
  
  # now repeat for MF 
  shdr[i,wf_names[81:128]]<-unlist(smop_hiDR[[3]][[i]][c(seq(6,41,5)),130:135]/unlist(rep(smop_hiDR[[3]][[i]][1,130:135],each=8)))# decay factors for pre-2020 MF up to 2060
  shdr[i,wf_names[129:130]]<-1 # new construction of 2020s cohort in 2025 and 2030 are unchanged
  shdr[i,wf_names[131:136]]<-unlist(smop_hiDR[[3]][[i]][c(seq(16,41,5)),136]/unlist(smop_hiDR[[3]][[i]][11,136])) # 2020s cohort from 2035 onwards (6 sim years)
  # wf_names 137 and 138 (change in 2030s cohort in 2025 and 2030) do not exist
  shdr[i,wf_names[139:140]]<-1 # new construction of 2030s cohort in 2035 and 2040 are unchanged
  shdr[i,wf_names[141:144]]<-unlist(smop_hiDR[[3]][[i]][c(seq(26,41,5)),137]/unlist(smop_hiDR[[3]][[i]][21,137])) # 2030s cohort from 2045 onwards (4 sim years)
  # wf_names 145 to 148 (change in 2040s cohort in 2025:2040) do not exist
  shdr[i,wf_names[149:150]]<-1 # new construction of 2040s cohort in 2045 and 2050 are unchanged
  shdr[i,wf_names[151:152]]<-unlist(smop_hiDR[[3]][[i]][c(seq(36,41,5)),138]/unlist(smop_hiDR[[3]][[i]][31,138])) # 2040s cohort from 2055 onwards (2 sim years)
  # wf_names 153 to 158 (change in 2050s cohort in 2025:2050) do not exist
  shdr[i,wf_names[159:160]]<-1 # new construction of 2050s cohort in 2055 and 2060 are unchanged
  
  # now repeat for MH
  shdr[i,wf_names[161:208]]<-unlist(smop_hiDR[[3]][[i]][c(seq(6,41,5)),150:155]/unlist(rep(smop_hiDR[[3]][[i]][1,150:155],each=8))) # decay factors for pre-2020 MH up to 2060
  shdr[i,wf_names[209:210]]<-1 # new construction of 2020s cohort in 2025 and 2030 are unchanged
  shdr[i,wf_names[211:216]]<-unlist(smop_hiDR[[3]][[i]][c(seq(16,41,5)),156]/unlist(smop_hiDR[[3]][[i]][11,156])) # 2020s cohort from 2035 onwards (6 sim years)
  # wf_names 217 and 218 (change in 2030s cohort in 2025 and 2030) do not exist
  shdr[i,wf_names[219:220]]<-1 # new construction of 2030s cohort in 2035 and 2040 are unchanged
  shdr[i,wf_names[221:224]]<-unlist(smop_hiDR[[3]][[i]][c(seq(26,41,5)),157]/unlist(smop_hiDR[[3]][[i]][21,157])) # 2030s cohort from 2045 onwards (4 sim years)
  # wf_names 145 to 148 (change in 2040s cohort in 2025:2040) do not exist
  shdr[i,wf_names[229:230]]<-1 # new construction of 2040s cohort in 2045 and 2050 are unchanged
  shdr[i,wf_names[231:232]]<-unlist(smop_hiDR[[3]][[i]][c(seq(36,41,5)),158]/unlist(smop_hiDR[[3]][[i]][31,158])) # 2040s cohort from 2055 onwards (2 sim years)
  # wf_names 153 to 158 (change in 2050s cohort in 2025:2050) do not exist
  shdr[i,wf_names[239:240]]<-1 # new construction of 2050s cohort in 2055 and 2060 are unchanged
  
  
  # calculate decay factors for SF homes in the hi MF scenario 
  shmf[i,wf_names[1:48]]<-unlist(smop_hiMF[[3]][[i]][c(seq(6,41,5)),110:115]/unlist(rep(smop_hiMF[[3]][[i]][1,110:115],each=8))) # decay factors for pre-2020 SF up to 2060
  shmf[i,wf_names[49:50]]<-1 # new construction of 2020s cohort in 2025 and 2030 are unchanged
  shmf[i,wf_names[51:56]]<-unlist(smop_hiMF[[3]][[i]][c(seq(16,41,5)),116]/unlist(smop_hiMF[[3]][[i]][11,116])) # 2020s cohort from 2035 onwards (6 sim years)
  # wf_names 57 and 58 (change in 2030s cohort in 2025 and 2030) do not exist
  shmf[i,wf_names[59:60]]<-1 # new construction of 2030s cohort in 2035 and 2040 are unchanged
  shmf[i,wf_names[61:64]]<-unlist(smop_hiMF[[3]][[i]][c(seq(26,41,5)),117]/unlist(smop_hiMF[[3]][[i]][21,117])) # 2030s cohort from 2045 onwards (4 sim years)
  # wf_names 65 to 68 (change in 2040s cohort in 2025:2040) do not exist
  shmf[i,wf_names[69:70]]<-1 # new construction of 2040s cohort in 2045 and 2050 are unchanged
  shmf[i,wf_names[71:72]]<-unlist(smop_hiMF[[3]][[i]][c(seq(36,41,5)),118]/unlist(smop_hiMF[[3]][[i]][31,118])) # 2040s cohort from 2055 onwards (2 sim years)
  # wf_names 73 to 78 (change in 2050s cohort in 2025:2050) do not exist
  shmf[i,wf_names[79:80]]<-1 # new construction of 2050s cohort in 2055 and 2060 are unchanged
  
  # now repeat for MF 
  shmf[i,wf_names[81:128]]<-unlist(smop_hiMF[[3]][[i]][c(seq(6,41,5)),130:135]/unlist(rep(smop_hiMF[[3]][[i]][1,130:135],each=8)))# decay factors for pre-2020 MF up to 2060
  shmf[i,wf_names[129:130]]<-1 # new construction of 2020s cohort in 2025 and 2030 are unchanged
  shmf[i,wf_names[131:136]]<-unlist(smop_hiMF[[3]][[i]][c(seq(16,41,5)),136]/unlist(smop_hiMF[[3]][[i]][11,136])) # 2020s cohort from 2035 onwards (6 sim years)
  # wf_names 137 and 138 (change in 2030s cohort in 2025 and 2030) do not exist
  shmf[i,wf_names[139:140]]<-1 # new construction of 2030s cohort in 2035 and 2040 are unchanged
  shmf[i,wf_names[141:144]]<-unlist(smop_hiMF[[3]][[i]][c(seq(26,41,5)),137]/unlist(smop_hiMF[[3]][[i]][21,137])) # 2030s cohort from 2045 onwards (4 sim years)
  # wf_names 145 to 148 (change in 2040s cohort in 2025:2040) do not exist
  shmf[i,wf_names[149:150]]<-1 # new construction of 2040s cohort in 2045 and 2050 are unchanged
  shmf[i,wf_names[151:152]]<-unlist(smop_hiMF[[3]][[i]][c(seq(36,41,5)),138]/unlist(smop_hiMF[[3]][[i]][31,138])) # 2040s cohort from 2055 onwards (2 sim years)
  # wf_names 153 to 158 (change in 2050s cohort in 2025:2050) do not exist
  shmf[i,wf_names[159:160]]<-1 # new construction of 2050s cohort in 2055 and 2060 are unchanged
  
  # now repeat for MH
  shmf[i,wf_names[161:208]]<-unlist(smop_hiMF[[3]][[i]][c(seq(6,41,5)),150:155]/unlist(rep(smop_hiMF[[3]][[i]][1,150:155],each=8))) # decay factors for pre-2020 MH up to 2060
  shmf[i,wf_names[209:210]]<-1 # new construction of 2020s cohort in 2025 and 2030 are unchanged
  shmf[i,wf_names[211:216]]<-unlist(smop_hiMF[[3]][[i]][c(seq(16,41,5)),156]/unlist(smop_hiMF[[3]][[i]][11,156])) # 2020s cohort from 2035 onwards (6 sim years)
  # wf_names 217 and 218 (change in 2030s cohort in 2025 and 2030) do not exist
  shmf[i,wf_names[219:220]]<-1 # new construction of 2030s cohort in 2035 and 2040 are unchanged
  shmf[i,wf_names[221:224]]<-unlist(smop_hiMF[[3]][[i]][c(seq(26,41,5)),157]/unlist(smop_hiMF[[3]][[i]][21,157])) # 2030s cohort from 2045 onwards (4 sim years)
  # wf_names 145 to 148 (change in 2040s cohort in 2025:2040) do not exist
  shmf[i,wf_names[229:230]]<-1 # new construction of 2040s cohort in 2045 and 2050 are unchanged
  shmf[i,wf_names[231:232]]<-unlist(smop_hiMF[[3]][[i]][c(seq(36,41,5)),158]/unlist(smop_hiMF[[3]][[i]][31,158])) # 2040s cohort from 2055 onwards (2 sim years)
  # wf_names 153 to 158 (change in 2050s cohort in 2025:2050) do not exist
  shmf[i,wf_names[239:240]]<-1 # new construction of 2050s cohort in 2055 and 2060 are unchanged
  
  
  # calculate decay factors for SF homes in the baseline scenario 
  shdm[i,wf_names[1:48]]<-unlist(smop_hiDRMF[[3]][[i]][c(seq(6,41,5)),110:115]/unlist(rep(smop_hiDRMF[[3]][[i]][1,110:115],each=8))) # decay factors for pre-2020 SF up to 2060
  shdm[i,wf_names[49:50]]<-1 # new construction of 2020s cohort in 2025 and 2030 are unchanged
  shdm[i,wf_names[51:56]]<-unlist(smop_hiDRMF[[3]][[i]][c(seq(16,41,5)),116]/unlist(smop_hiDRMF[[3]][[i]][11,116])) # 2020s cohort from 2035 onwards (6 sim years)
  # wf_names 57 and 58 (change in 2030s cohort in 2025 and 2030) do not exist
  shdm[i,wf_names[59:60]]<-1 # new construction of 2030s cohort in 2035 and 2040 are unchanged
  shdm[i,wf_names[61:64]]<-unlist(smop_hiDRMF[[3]][[i]][c(seq(26,41,5)),117]/unlist(smop_hiDRMF[[3]][[i]][21,117])) # 2030s cohort from 2045 onwards (4 sim years)
  # wf_names 65 to 68 (change in 2040s cohort in 2025:2040) do not exist
  shdm[i,wf_names[69:70]]<-1 # new construction of 2040s cohort in 2045 and 2050 are unchanged
  shdm[i,wf_names[71:72]]<-unlist(smop_hiDRMF[[3]][[i]][c(seq(36,41,5)),118]/unlist(smop_hiDRMF[[3]][[i]][31,118])) # 2040s cohort from 2055 onwards (2 sim years)
  # wf_names 73 to 78 (change in 2050s cohort in 2025:2050) do not exist
  shdm[i,wf_names[79:80]]<-1 # new construction of 2050s cohort in 2055 and 2060 are unchanged
  
  # now repeat for MF 
  shdm[i,wf_names[81:128]]<-unlist(smop_hiDRMF[[3]][[i]][c(seq(6,41,5)),130:135]/unlist(rep(smop_hiDRMF[[3]][[i]][1,130:135],each=8)))# decay factors for pre-2020 MF up to 2060
  shdm[i,wf_names[129:130]]<-1 # new construction of 2020s cohort in 2025 and 2030 are unchanged
  shdm[i,wf_names[131:136]]<-unlist(smop_hiDRMF[[3]][[i]][c(seq(16,41,5)),136]/unlist(smop_hiDRMF[[3]][[i]][11,136])) # 2020s cohort from 2035 onwards (6 sim years)
  # wf_names 137 and 138 (change in 2030s cohort in 2025 and 2030) do not exist
  shdm[i,wf_names[139:140]]<-1 # new construction of 2030s cohort in 2035 and 2040 are unchanged
  shdm[i,wf_names[141:144]]<-unlist(smop_hiDRMF[[3]][[i]][c(seq(26,41,5)),137]/unlist(smop_hiDRMF[[3]][[i]][21,137])) # 2030s cohort from 2045 onwards (4 sim years)
  # wf_names 145 to 148 (change in 2040s cohort in 2025:2040) do not exist
  shdm[i,wf_names[149:150]]<-1 # new construction of 2040s cohort in 2045 and 2050 are unchanged
  shdm[i,wf_names[151:152]]<-unlist(smop_hiDRMF[[3]][[i]][c(seq(36,41,5)),138]/unlist(smop_hiDRMF[[3]][[i]][31,138])) # 2040s cohort from 2055 onwards (2 sim years)
  # wf_names 153 to 158 (change in 2050s cohort in 2025:2050) do not exist
  shdm[i,wf_names[159:160]]<-1 # new construction of 2050s cohort in 2055 and 2060 are unchanged
  
  # now repeat for MH
  shdm[i,wf_names[161:208]]<-unlist(smop_hiDRMF[[3]][[i]][c(seq(6,41,5)),150:155]/unlist(rep(smop_hiDRMF[[3]][[i]][1,150:155],each=8))) # decay factors for pre-2020 MH up to 2060
  shdm[i,wf_names[209:210]]<-1 # new construction of 2020s cohort in 2025 and 2030 are unchanged
  shdm[i,wf_names[211:216]]<-unlist(smop_hiDRMF[[3]][[i]][c(seq(16,41,5)),156]/unlist(smop_hiDRMF[[3]][[i]][11,156])) # 2020s cohort from 2035 onwards (6 sim years)
  # wf_names 217 and 218 (change in 2030s cohort in 2025 and 2030) do not exist
  shdm[i,wf_names[219:220]]<-1 # new construction of 2030s cohort in 2035 and 2040 are unchanged
  shdm[i,wf_names[221:224]]<-unlist(smop_hiDRMF[[3]][[i]][c(seq(26,41,5)),157]/unlist(smop_hiDRMF[[3]][[i]][21,157])) # 2030s cohort from 2045 onwards (4 sim years)
  # wf_names 145 to 148 (change in 2040s cohort in 2025:2040) do not exist
  shdm[i,wf_names[229:230]]<-1 # new construction of 2040s cohort in 2045 and 2050 are unchanged
  shdm[i,wf_names[231:232]]<-unlist(smop_hiDRMF[[3]][[i]][c(seq(36,41,5)),158]/unlist(smop_hiDRMF[[3]][[i]][31,158])) # 2040s cohort from 2055 onwards (2 sim years)
  # wf_names 153 to 158 (change in 2050s cohort in 2025:2050) do not exist
  shdm[i,wf_names[239:240]]<-1 # new construction of 2050s cohort in 2055 and 2060 are unchanged
}


for (j in 3:206) { # replace nans and infs (which are caused by 0 initial stocks) to weighting factors of 1.
  sb[which(is.infinite(sb[,j])|is.na(sb[,j])),j]<-1
  shdr[which(is.infinite(shdr[,j])|is.na(shdr[,j])),j]<-1
  shmf[which(is.infinite(shmf[,j])|is.na(shmf[,j])),j]<-1
  shdm[which(is.infinite(shdm[,j])|is.na(shdm[,j])),j]<-1
}
save(sb,shdr,shmf,shdm,file = "../Intermediate_results/decayFactors.RData") 
# now add some additional preprocessing to the decay factor dfs for use in other scripts ######
load("~/Yale Courses/Research/Final Paper/HSM_github/Intermediate_results/ctycode.RData")
# First for use in the renovation scripts
# first preserve the original data frames
sb0<-sb
shdm0<-shdm
shdr0<-shdr
shmf0<-shmf

sb<-merge(sb0,ctycode)
shdr<-merge(shdr0,ctycode)
shmf<-merge(shmf0,ctycode)
shdm<-merge(shdm0,ctycode)

sbm<-melt(sb)
sbm$variable<-gsub("p19","<19",sbm$variable)
sbm$TCY<-substr(sbm$variable,4,18)
sbm$TCY<-gsub("0_","0-",sbm$TCY)
# fix/revert the <1940_
sbm$TCY<-gsub("<1940-","<1940_",sbm$TCY)
sbm<-merge(sbm,ctycode)
sbm$ctyTCY<-paste(sbm$RS_ID,sbm$TCY,sep="")
sbm<-sbm[,c("ctyTCY","value")]
names(sbm)[2]<-"wf_base"
# organize so there are eight columns, one for each future year. 
sbm$Year<-substr(sbm$ctyTCY,nchar(sbm$ctyTCY)-3,nchar(sbm$ctyTCY))
sbm$ctyTCY<-substr(sbm$ctyTCY,1,nchar(sbm$ctyTCY)-5)
sbm<-dcast(sbm,ctyTCY~Year,value.var = "wf_base")
# remove future cohorts which play no role in the renonvation of the <2020 stock
w<-which(substr(sbm$ctyTCY,nchar(sbm$ctyTCY)-6,nchar(sbm$ctyTCY)-3) %in% c("2020","2030","2040","2050"))
sbm<-sbm[-w,]
names(sbm)[1]<-"ctyTC"
names(sbm)[2:9]<-c("wbase_2025","wbase_2030","wbase_2035","wbase_2040","wbase_2045","wbase_2050","wbase_2055","wbase_2060")

shdrm<-melt(shdr)
shdrm$variable<-gsub("p19","<19",shdrm$variable)
shdrm$TCY<-substr(shdrm$variable,4,18)
shdrm$TCY<-gsub("0_","0-",shdrm$TCY)
# fix/revert the <1940_
shdrm$TCY<-gsub("<1940-","<1940_",shdrm$TCY)
shdrm<-merge(shdrm,ctycode)
shdrm$ctyTCY<-paste(shdrm$RS_ID,shdrm$TCY,sep="")
shdrm<-shdrm[,c("ctyTCY","value")]
names(shdrm)[2]<-"wf_hiDR"
# organize so there are eight columns, one for each future year. 
shdrm$Year<-substr(shdrm$ctyTCY,nchar(shdrm$ctyTCY)-3,nchar(shdrm$ctyTCY))
shdrm$ctyTCY<-substr(shdrm$ctyTCY,1,nchar(shdrm$ctyTCY)-5)
shdrm<-dcast(shdrm,ctyTCY~Year,value.var = "wf_hiDR")
# remove future cohorts which play no role in the renonvation of the <2020 stock
w<-which(substr(shdrm$ctyTCY,nchar(shdrm$ctyTCY)-6,nchar(shdrm$ctyTCY)-3) %in% c("2020","2030","2040","2050"))
shdrm<-shdrm[-w,]
names(shdrm)[1]<-"ctyTC"
names(shdrm)[2:9]<-c("whiDR_2025","whiDR_2030","whiDR_2035","whiDR_2040","whiDR_2045","whiDR_2050","whiDR_2055","whiDR_2060")

shmfm<-melt(shmf)
shmfm$variable<-gsub("p19","<19",shmfm$variable)
shmfm$TCY<-substr(shmfm$variable,4,18)
shmfm$TCY<-gsub("0_","0-",shmfm$TCY)
# fix/revert the <1940_
shmfm$TCY<-gsub("<1940-","<1940_",shmfm$TCY)
shmfm<-merge(shmfm,ctycode)
shmfm$ctyTCY<-paste(shmfm$RS_ID,shmfm$TCY,sep="")
shmfm<-shmfm[,c("ctyTCY","value")]
names(shmfm)[2]<-"wf_hiMF"
# organize so there are eight columns, one for each future year. 
shmfm$Year<-substr(shmfm$ctyTCY,nchar(shmfm$ctyTCY)-3,nchar(shmfm$ctyTCY))
shmfm$ctyTCY<-substr(shmfm$ctyTCY,1,nchar(shmfm$ctyTCY)-5)
shmfm<-dcast(shmfm,ctyTCY~Year,value.var = "wf_hiMF")
# remove future cohorts which play no role in the renonvation of the <2020 stock
w<-which(substr(shmfm$ctyTCY,nchar(shmfm$ctyTCY)-6,nchar(shmfm$ctyTCY)-3) %in% c("2020","2030","2040","2050"))
shmfm<-shmfm[-w,]
names(shmfm)[1]<-"ctyTC"
names(shmfm)[2:9]<-c("whiMF_2025","whiMF_2030","whiMF_2035","whiMF_2040","whiMF_2045","whiMF_2050","whiMF_2055","whiMF_2060")

shdmm<-melt(shdm)
shdmm$variable<-gsub("p19","<19",shdmm$variable)
shdmm$TCY<-substr(shdmm$variable,4,18)
shdmm$TCY<-gsub("0_","0-",shdmm$TCY)
# fix/revert the <1940_
shdmm$TCY<-gsub("<1940-","<1940_",shdmm$TCY)
shdmm<-merge(shdmm,ctycode)
shdmm$ctyTCY<-paste(shdmm$RS_ID,shdmm$TCY,sep="")
shdmm<-shdmm[,c("ctyTCY","value")]
names(shdmm)[2]<-"wf_hiDRMF"
# organize so there are eight columns, one for each future year. 
shdmm$Year<-substr(shdmm$ctyTCY,nchar(shdmm$ctyTCY)-3,nchar(shdmm$ctyTCY))
shdmm$ctyTCY<-substr(shdmm$ctyTCY,1,nchar(shdmm$ctyTCY)-5)
shdmm<-dcast(shdmm,ctyTCY~Year,value.var = "wf_hiDRMF")
# remove future cohorts which play no role in the renonvation of the <2020 stock
w<-which(substr(shdmm$ctyTCY,nchar(shdmm$ctyTCY)-6,nchar(shdmm$ctyTCY)-3) %in% c("2020","2030","2040","2050"))
shdmm<-shdmm[-w,]
names(shdmm)[1]<-"ctyTC"
names(shdmm)[2:9]<-c("whiDRMF_2025","whiDRMF_2030","whiDRMF_2035","whiDRMF_2040","whiDRMF_2045","whiDRMF_2050","whiDRMF_2055","whiDRMF_2060")

save(sbm,shdrm,shmfm,shdmm,file = "../Intermediate_results/decayFactorsRen.RData") 

sbm<-melt(sb)
sbm$variable<-gsub("p19","<19",sbm$variable)
sbm$TCY<-substr(sbm$variable,4,18)
sbm$TCY<-gsub("0_","0-",sbm$TCY)
# fix/revert the <1940_
sbm$TCY<-gsub("<1940-","<1940_",sbm$TCY)
sbm<-merge(sbm,ctycode)
sbm$ctyTCY<-paste(sbm$RS_ID,sbm$TCY,sep="")
sbm<-sbm[,c("ctyTCY","value")]
names(sbm)[2]<-"wf_base"
# organize so there are eight columns, one for each future year. 
sbm$Year<-substr(sbm$ctyTCY,nchar(sbm$ctyTCY)-3,nchar(sbm$ctyTCY))
sbm$ctyTCY<-substr(sbm$ctyTCY,1,nchar(sbm$ctyTCY)-5)
sbm<-dcast(sbm,ctyTCY~Year,value.var = "wf_base")
sbm[is.na(sbm)]<-0 # this will calculate energy consumption of cohorts before their time as 0
names(sbm)[1:9]<-c("ctyTC","wbase_2025","wbase_2030","wbase_2035","wbase_2040","wbase_2045","wbase_2050","wbase_2055","wbase_2060")
sbm$wbase_2020<-c(1,1,1,1,1,1,0,0,0,0) # add column for 2020
sbm<-sbm[,c(1,10,2:9)] # reorder columns

# create the desirable data frame for weighting factors in the hiDR scenario
shdrm<-melt(shdr)
shdrm$variable<-gsub("p19","<19",shdrm$variable)
shdrm$TCY<-substr(shdrm$variable,4,18)
shdrm$TCY<-gsub("0_","0-",shdrm$TCY)
# fix/revert the <1940_
shdrm$TCY<-gsub("<1940-","<1940_",shdrm$TCY)
shdrm<-merge(shdrm,ctycode)
shdrm$ctyTCY<-paste(shdrm$RS_ID,shdrm$TCY,sep="")
shdrm<-shdrm[,c("ctyTCY","value")]
names(shdrm)[2]<-"wf_hiDR"
# organize so there are eight columns, one for each future year. 
shdrm$Year<-substr(shdrm$ctyTCY,nchar(shdrm$ctyTCY)-3,nchar(shdrm$ctyTCY))
shdrm$ctyTCY<-substr(shdrm$ctyTCY,1,nchar(shdrm$ctyTCY)-5)
shdrm<-dcast(shdrm,ctyTCY~Year,value.var = "wf_hiDR")
shdrm[is.na(shdrm)]<-0 # this will calculate energy consumption of cohorts before their time as 0
names(shdrm)[1:9]<-c("ctyTC","whiDR_2025","whiDR_2030","whiDR_2035","whiDR_2040","whiDR_2045","whiDR_2050","whiDR_2055","whiDR_2060")
shdrm$whiDR_2020<-c(1,1,1,1,1,1,0,0,0,0)
shdrm<-shdrm[,c(1,10,2:9)]

# create the desirable data frame for weighting factors in the hiMF scenario
shmfm<-melt(shmf)
shmfm$variable<-gsub("p19","<19",shmfm$variable)
shmfm$TCY<-substr(shmfm$variable,4,18)
shmfm$TCY<-gsub("0_","0-",shmfm$TCY)
# fix/revert the <1940_
shmfm$TCY<-gsub("<1940-","<1940_",shmfm$TCY)
shmfm<-merge(shmfm,ctycode)
shmfm$ctyTCY<-paste(shmfm$RS_ID,shmfm$TCY,sep="")
shmfm<-shmfm[,c("ctyTCY","value")]
names(shmfm)[2]<-"wf_hiMF"
# organize so there are eight columns, one for each future year. 
shmfm$Year<-substr(shmfm$ctyTCY,nchar(shmfm$ctyTCY)-3,nchar(shmfm$ctyTCY))
shmfm$ctyTCY<-substr(shmfm$ctyTCY,1,nchar(shmfm$ctyTCY)-5)
shmfm<-dcast(shmfm,ctyTCY~Year,value.var = "wf_hiMF")
shmfm[is.na(shmfm)]<-0 # this will calculate energy consumption of cohorts before their time as 0
names(shmfm)[1:9]<-c("ctyTC","whiMF_2025","whiMF_2030","whiMF_2035","whiMF_2040","whiMF_2045","whiMF_2050","whiMF_2055","whiMF_2060")
shmfm$whiMF_2020<-c(1,1,1,1,1,1,0,0,0,0)
shmfm<-shmfm[,c(1,10,2:9)]

# create the desirable data frame for weighting factors in the hiDRMF scenario
shdmm<-melt(shdm)
shdmm$variable<-gsub("p19","<19",shdmm$variable)
shdmm$TCY<-substr(shdmm$variable,4,18)
shdmm$TCY<-gsub("0_","0-",shdmm$TCY)
# fix/revert the <1940_
shdmm$TCY<-gsub("<1940-","<1940_",shdmm$TCY)
shdmm<-merge(shdmm,ctycode)
shdmm$ctyTCY<-paste(shdmm$RS_ID,shdmm$TCY,sep="")
shdmm<-shdmm[,c("ctyTCY","value")]
names(shdmm)[2]<-"wf_hiDRMF"
# organize so there are eight columns, one for each future year. 
shdmm$Year<-substr(shdmm$ctyTCY,nchar(shdmm$ctyTCY)-3,nchar(shdmm$ctyTCY))
shdmm$ctyTCY<-substr(shdmm$ctyTCY,1,nchar(shdmm$ctyTCY)-5)
shdmm<-dcast(shdmm,ctyTCY~Year,value.var = "wf_hiDRMF")
shdmm[is.na(shdmm)]<-0 # this will calculate energy consumption of cohorts before their time as 0
names(shdmm)[1:9]<-c("ctyTC","whiDRMF_2025","whiDRMF_2030","whiDRMF_2035","whiDRMF_2040","whiDRMF_2045","whiDRMF_2050","whiDRMF_2055","whiDRMF_2060")
shdmm$whiDRMF_2020<-c(1,1,1,1,1,1,0,0,0,0)
shdmm<-shdmm[,c(1,10,2:9)]

save(sbm,shdrm,shmfm,shdmm,file = "../Intermediate_results/decayFactorsProj.RData") # for use in projecting stocks including future cohorts