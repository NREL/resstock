# script to visualize results
# FINAL results plotting for final results paper. working on updated version
library(ggplot2)
library(dplyr)
library(reshape2)
library(RColorBrewer)
library(openxlsx)
# Nov 22 2020
# Updated with new results July 20 2021
rm(list=ls()) # clear workspace i.e. remove saved variables
cat("\014") # clear console
setwd("~/Yale Courses/Research/Final Paper/resstock_projections/results_scripts")
# load in results
# first of all embodied/new construction emissions for 6 housing stock scenarios
load("../../HSM_github/HSM_results/US_FA_GHG_summaries.RData")
# then embodied emissions from renovations
load("../Final_results/renGHG.RData")
# for (n in 1:length(list.files("../Final_results/"))) {
#   load(paste("../Final_results/",list.files("../Final_results/")[n],sep=""))
# }

# then full energy results for 24 housing stock and characteristics scenarios, each with 2 electricity grid variations, all produced by RS_results_proj.R script
# first base scripts #########
load("../Final_results/res_base_RR.RData")
load("../Final_results/res_base_AR.RData")
load("../Final_results/res_base_ER.RData")
load("../Final_results/res_hiDR_RR.RData")
load("../Final_results/res_hiDR_AR.RData")
load("../Final_results/res_hiDR_ER.RData")
load("../Final_results/res_hiMF_RR.RData")
load("../Final_results/res_hiMF_AR.RData")
load("../Final_results/res_hiMF_ER.RData")

# add in GHG intensities for 2035 CFE
rs_base_all_RR[,c("GHG_int_2020_CFE","GHG_int_2025_CFE")]<-rs_base_all_RR[,c("GHG_int_2020_LRE","GHG_int_2025_LRE")]
rs_base_all_RR[,c("GHG_int_2030_CFE")]<-0.5*rs_base_all_RR[,c("GHG_int_2025_LRE")]
rs_base_all_RR[,c("GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")]<-0

rs_base_all_AR[,c("GHG_int_2020_CFE","GHG_int_2025_CFE")]<-rs_base_all_AR[,c("GHG_int_2020_LRE","GHG_int_2025_LRE")]
rs_base_all_AR[,c("GHG_int_2030_CFE")]<-0.5*rs_base_all_AR[,c("GHG_int_2025_LRE")]
rs_base_all_AR[,c("GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")]<-0

rs_base_all_ER[,c("GHG_int_2020_CFE","GHG_int_2025_CFE")]<-rs_base_all_ER[,c("GHG_int_2020_LRE","GHG_int_2025_LRE")]
rs_base_all_ER[,c("GHG_int_2030_CFE")]<-0.5*rs_base_all_ER[,c("GHG_int_2025_LRE")]
rs_base_all_ER[,c("GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")]<-0

# add in GHG emissions for CFE
# first define intensities for fuel combustion
GHGI_FO<-((.07396)+(25*3e-6)+(298*6e-7))/1.055  # intensity for heating oil (DFO #2) in kgCO2eq / MJ
GHGI_NG<-((0.05302)+(25*10e-6) + (298*1e-7))/1.055  # intensity for natural gas in kgCO2eq / MJ
GHGI_LP<-((.06298)+(25*3e-6)+(298*6e-7))/1.055   # intensity for LPG in kgCO2eq / MJ

rs_base_all_RR[,c("EnGHGkg_base_2020_CFE","EnGHGkg_base_2025_CFE","EnGHGkg_base_2030_CFE","EnGHGkg_base_2035_CFE","EnGHGkg_base_2040_CFE","EnGHGkg_base_2045_CFE","EnGHGkg_base_2050_CFE","EnGHGkg_base_2055_CFE","EnGHGkg_base_2060_CFE")]<-1000* 
  (rs_base_all_RR$base_weight*rs_base_all_RR[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*
  (rs_base_all_RR$Elec_GJ*rs_base_all_RR[,c("GHG_int_2020_CFE", "GHG_int_2025_CFE","GHG_int_2030_CFE","GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")]+
     matrix(rep(rs_base_all_RR$Gas_GJ*GHGI_NG,9),nrow(rs_base_all_RR),9)+ matrix(rep(rs_base_all_RR$Oil_GJ*GHGI_FO,9),nrow(rs_base_all_RR),9)+ matrix(rep(rs_base_all_RR$Prop_GJ*GHGI_LP,9),nrow(rs_base_all_RR),9))

rs_base_all_AR[,c("EnGHGkg_base_2020_CFE","EnGHGkg_base_2025_CFE","EnGHGkg_base_2030_CFE","EnGHGkg_base_2035_CFE","EnGHGkg_base_2040_CFE","EnGHGkg_base_2045_CFE","EnGHGkg_base_2050_CFE","EnGHGkg_base_2055_CFE","EnGHGkg_base_2060_CFE")]<-1000* 
  (rs_base_all_AR$base_weight*rs_base_all_AR[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*
  (rs_base_all_AR$Elec_GJ*rs_base_all_AR[,c("GHG_int_2020_CFE", "GHG_int_2025_CFE","GHG_int_2030_CFE","GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")]+
     matrix(rep(rs_base_all_AR$Gas_GJ*GHGI_NG,9),nrow(rs_base_all_AR),9)+ matrix(rep(rs_base_all_AR$Oil_GJ*GHGI_FO,9),nrow(rs_base_all_AR),9)+ matrix(rep(rs_base_all_AR$Prop_GJ*GHGI_LP,9),nrow(rs_base_all_AR),9))

rs_base_all_ER[,c("EnGHGkg_base_2020_CFE","EnGHGkg_base_2025_CFE","EnGHGkg_base_2030_CFE","EnGHGkg_base_2035_CFE","EnGHGkg_base_2040_CFE","EnGHGkg_base_2045_CFE","EnGHGkg_base_2050_CFE","EnGHGkg_base_2055_CFE","EnGHGkg_base_2060_CFE")]<-1000*
  (rs_base_all_ER$base_weight*rs_base_all_ER[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*
  (rs_base_all_ER$Elec_GJ*rs_base_all_ER[,c("GHG_int_2020_CFE", "GHG_int_2025_CFE","GHG_int_2030_CFE","GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")]+
     matrix(rep(rs_base_all_ER$Gas_GJ*GHGI_NG,9),nrow(rs_base_all_ER),9)+ matrix(rep(rs_base_all_ER$Oil_GJ*GHGI_FO,9),nrow(rs_base_all_ER),9)+ matrix(rep(rs_base_all_ER$Prop_GJ*GHGI_LP,9),nrow(rs_base_all_ER),9))

GHG_base_RR<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_base_all_RR[,176:184])) # emissions in Mt 
GHG_base_RR<-data.frame(data.frame(EnGHG=with(select(GHG_base_RR,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="A",RenScen="RR",ElecScen="MC")
names(GHG_base_RR)[1:2]<-c("Year","EnGHG")
GHG_base_RR$EmGHG<-us_base_FA$GHG_NC*1e-9
GHG_base_RR$EmGHG[41]<-GHG_base_RR$EmGHG[40]
GHG_base_RR$RenGHG<-renGHGall[renGHGall$Scen=="Base_Reg",]$MtCO2e
GHG_base_RR$TotGHG<-GHG_base_RR$EmGHG+GHG_base_RR$RenGHG+GHG_base_RR$EnGHG

GHG_base_RR_LREC<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_base_all_RR[,185:193])) # emissions in Mt 
GHG_base_RR_LREC<-data.frame(data.frame(EnGHG=with(select(GHG_base_RR_LREC,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="A",RenScen="RR",ElecScen="LREC")
names(GHG_base_RR_LREC)[1:2]<-c("Year","EnGHG")
GHG_base_RR_LREC$EmGHG<-us_base_FA$GHG_NC*1e-9
GHG_base_RR_LREC$EmGHG[41]<-GHG_base_RR_LREC$EmGHG[40]
GHG_base_RR_LREC$RenGHG<-renGHGall[renGHGall$Scen=="Base_Reg",]$MtCO2e
GHG_base_RR_LREC$TotGHG<-GHG_base_RR_LREC$EmGHG+GHG_base_RR_LREC$RenGHG+GHG_base_RR_LREC$EnGHG

# for CFE, EnGHG needs to be done first by electricity, and then recombined with fuel EnGHG
rs_base_all_RR[,c("ElecGHGkg_2020_LRE","ElecGHGkg_2025_LRE","ElecGHGkg_2030_LRE","ElecGHGkg_2035_LRE","ElecGHGkg_2040_LRE","ElecGHGkg_2045_LRE","ElecGHGkg_2050_LRE","ElecGHGkg_2055_LRE","ElecGHGkg_2060_LRE")]<-1000* 
  (rs_base_all_RR$base_weight*rs_base_all_RR[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*
  (rs_base_all_RR$Elec_GJ*rs_base_all_RR[,c("GHG_int_2020_LRE", "GHG_int_2025_LRE","GHG_int_2030_LRE","GHG_int_2035_LRE","GHG_int_2040_LRE","GHG_int_2045_LRE","GHG_int_2050_LRE","GHG_int_2055_LRE","GHG_int_2060_LRE")])

rs_base_all_RR[,c("ElecGHGkg_2020_CFE","ElecGHGkg_2025_CFE","ElecGHGkg_2030_CFE","ElecGHGkg_2035_CFE","ElecGHGkg_2040_CFE","ElecGHGkg_2045_CFE","ElecGHGkg_2050_CFE","ElecGHGkg_2055_CFE","ElecGHGkg_2060_CFE")]<-1000* 
  (rs_base_all_RR$base_weight*rs_base_all_RR[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*
  (rs_base_all_RR$Elec_GJ*rs_base_all_RR[,c("GHG_int_2020_CFE", "GHG_int_2025_CFE","GHG_int_2030_CFE","GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")])

GHGelec_base_RR_LRE<-data.frame(Year=seq(2020,2060,5),ElGHG=1e-9*colSums(rs_base_all_RR[,212:220])) # emissions in Mt 
GHGelec_base_RR_LRE<-data.frame(data.frame(ElGHG=with(select(GHGelec_base_RR_LRE,Year,ElGHG),spline(Year,ElGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="A",RenScen="RR",ElecScen="LRE")
names(GHGelec_base_RR_LRE)[1:2]<-c("Year","ElGHG")

GHGelec_base_RR_CFE<-data.frame(Year=seq(2020,2060,5),ElGHG=1e-9*colSums(rs_base_all_RR[,221:229])) # emissions in Mt 
GHGelec_base_RR_CFE<-data.frame(data.frame(ElGHG=with(select(GHGelec_base_RR_CFE,Year,ElGHG),spline(Year,ElGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="A",RenScen="RR",ElecScen="CFE")
names(GHGelec_base_RR_CFE)[1:2]<-c("Year","ElGHG")

GHGelec_base_RR_CFE$ElGHG[1:6]<-GHGelec_base_RR_LRE$ElGHG[1:6] # 2020:2025 is same in CFE as in LRE
GHGelec_base_RR_CFE$ElGHG[16:41]<-0 # 2035:2060 is 0 in CFE

GHG_base_RR_CFE<-GHG_base_RR_LREC
GHG_base_RR_CFE$ElecScen<-"CFE"
GHG_base_RR_CFE$EnGHG<-GHG_base_RR_LREC$EnGHG-GHGelec_base_RR_LRE$ElGHG+GHGelec_base_RR_CFE$ElGHG # energy emissions equal total LRE enGHG - LRE elGHG + CFE elGHG
GHG_base_RR_CFE$EmGHG<-us_base_FA$GHG_NC*1e-9
GHG_base_RR_CFE$EmGHG[41]<-GHG_base_RR_CFE$EmGHG[40]
GHG_base_RR_CFE$RenGHG<-renGHGall[renGHGall$Scen=="Base_Reg",]$MtCO2e
GHG_base_RR_CFE$TotGHG<-GHG_base_RR_CFE$EmGHG+GHG_base_RR_CFE$RenGHG+GHG_base_RR_CFE$EnGHG
# base AR
GHG_base_AR<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_base_all_AR[,176:184])) # emissions in Mt 
GHG_base_AR<-data.frame(data.frame(EnGHG=with(select(GHG_base_AR,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="A",RenScen="AR",ElecScen="MC")
names(GHG_base_AR)[1:2]<-c("Year","EnGHG")
GHG_base_AR$EmGHG<-us_base_FA$GHG_NC*1e-9
GHG_base_AR$EmGHG[41]<-GHG_base_AR$EmGHG[40]
GHG_base_AR$RenGHG<-renGHGall[renGHGall$Scen=="Base_Adv",]$MtCO2e
GHG_base_AR$TotGHG<-GHG_base_AR$EmGHG+GHG_base_AR$RenGHG+GHG_base_AR$EnGHG

GHG_base_AR_LREC<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_base_all_AR[,185:193])) # emissions in Mt 
GHG_base_AR_LREC<-data.frame(data.frame(EnGHG=with(select(GHG_base_AR_LREC,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="A",RenScen="AR",ElecScen="LREC")
names(GHG_base_AR_LREC)[1:2]<-c("Year","EnGHG")
GHG_base_AR_LREC$EmGHG<-us_base_FA$GHG_NC*1e-9
GHG_base_AR_LREC$EmGHG[41]<-GHG_base_AR_LREC$EmGHG[40]
GHG_base_AR_LREC$RenGHG<-renGHGall[renGHGall$Scen=="Base_Adv",]$MtCO2e
GHG_base_AR_LREC$TotGHG<-GHG_base_AR_LREC$EmGHG+GHG_base_AR_LREC$RenGHG+GHG_base_AR_LREC$EnGHG

# for CFE, EnGHG needs to be done first by electricity, and then recombined with fuel EnGHG
rs_base_all_AR[,c("ElecGHGkg_2020_LRE","ElecGHGkg_2025_LRE","ElecGHGkg_2030_LRE","ElecGHGkg_2035_LRE","ElecGHGkg_2040_LRE","ElecGHGkg_2045_LRE","ElecGHGkg_2050_LRE","ElecGHGkg_2055_LRE","ElecGHGkg_2060_LRE")]<-1000* 
  (rs_base_all_AR$base_weight*rs_base_all_AR[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*
  (rs_base_all_AR$Elec_GJ*rs_base_all_AR[,c("GHG_int_2020_LRE", "GHG_int_2025_LRE","GHG_int_2030_LRE","GHG_int_2035_LRE","GHG_int_2040_LRE","GHG_int_2045_LRE","GHG_int_2050_LRE","GHG_int_2055_LRE","GHG_int_2060_LRE")])

rs_base_all_AR[,c("ElecGHGkg_2020_CFE","ElecGHGkg_2025_CFE","ElecGHGkg_2030_CFE","ElecGHGkg_2035_CFE","ElecGHGkg_2040_CFE","ElecGHGkg_2045_CFE","ElecGHGkg_2050_CFE","ElecGHGkg_2055_CFE","ElecGHGkg_2060_CFE")]<-1000* 
  (rs_base_all_AR$base_weight*rs_base_all_AR[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*
  (rs_base_all_AR$Elec_GJ*rs_base_all_AR[,c("GHG_int_2020_CFE", "GHG_int_2025_CFE","GHG_int_2030_CFE","GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")])

GHGelec_base_AR_LRE<-data.frame(Year=seq(2020,2060,5),ElGHG=1e-9*colSums(rs_base_all_AR[,212:220])) # emissions in Mt 
GHGelec_base_AR_LRE<-data.frame(data.frame(ElGHG=with(select(GHGelec_base_AR_LRE,Year,ElGHG),spline(Year,ElGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="A",RenScen="AR",ElecScen="LRE")
names(GHGelec_base_AR_LRE)[1:2]<-c("Year","ElGHG")

GHGelec_base_AR_CFE<-data.frame(Year=seq(2020,2060,5),ElGHG=1e-9*colSums(rs_base_all_AR[,221:229])) # emissions in Mt 
GHGelec_base_AR_CFE<-data.frame(data.frame(ElGHG=with(select(GHGelec_base_AR_CFE,Year,ElGHG),spline(Year,ElGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="A",RenScen="AR",ElecScen="CFE")
names(GHGelec_base_AR_CFE)[1:2]<-c("Year","ElGHG")

GHGelec_base_AR_CFE$ElGHG[1:6]<-GHGelec_base_AR_LRE$ElGHG[1:6] # 2020:2025 is same in CFE as in LRE
GHGelec_base_AR_CFE$ElGHG[16:41]<-0 # 2035:2060 is 0 in CFE

GHG_base_AR_CFE<-GHG_base_AR_LREC
GHG_base_AR_CFE$ElecScen<-"CFE"
GHG_base_AR_CFE$EnGHG<-GHG_base_AR_LREC$EnGHG-GHGelec_base_AR_LRE$ElGHG+GHGelec_base_AR_CFE$ElGHG # energy emissions equal total LRE enGHG - LRE elGHG + CFE elGHG
GHG_base_AR_CFE$EmGHG<-us_base_FA$GHG_NC*1e-9
GHG_base_AR_CFE$EmGHG[41]<-GHG_base_AR_CFE$EmGHG[40]
GHG_base_AR_CFE$RenGHG<-renGHGall[renGHGall$Scen=="Base_Adv",]$MtCO2e
GHG_base_AR_CFE$TotGHG<-GHG_base_AR_CFE$EmGHG+GHG_base_AR_CFE$RenGHG+GHG_base_AR_CFE$EnGHG
# base ER
GHG_base_ER<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_base_all_ER[,176:184])) # emissions in Mt 
GHG_base_ER<-data.frame(data.frame(EnGHG=with(select(GHG_base_ER,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="A",RenScen="ER",ElecScen="MC")
names(GHG_base_ER)[1:2]<-c("Year","EnGHG")
GHG_base_ER$EmGHG<-us_base_FA$GHG_NC*1e-9
GHG_base_ER$EmGHG[41]<-GHG_base_ER$EmGHG[40]
GHG_base_ER$RenGHG<-renGHGall[renGHGall$Scen=="Base_Ext",]$MtCO2e
GHG_base_ER$TotGHG<-GHG_base_ER$EmGHG+GHG_base_ER$RenGHG+GHG_base_ER$EnGHG

GHG_base_ER_LREC<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_base_all_ER[,185:193])) # emissions in Mt 
GHG_base_ER_LREC<-data.frame(data.frame(EnGHG=with(select(GHG_base_ER_LREC,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="A",RenScen="ER",ElecScen="LREC")
names(GHG_base_ER_LREC)[1:2]<-c("Year","EnGHG")
GHG_base_ER_LREC$EmGHG<-us_base_FA$GHG_NC*1e-9
GHG_base_ER_LREC$EmGHG[41]<-GHG_base_ER_LREC$EmGHG[40]
GHG_base_ER_LREC$RenGHG<-renGHGall[renGHGall$Scen=="Base_Ext",]$MtCO2e
GHG_base_ER_LREC$TotGHG<-GHG_base_ER_LREC$EmGHG+GHG_base_ER_LREC$RenGHG+GHG_base_ER_LREC$EnGHG

# for CFE, EnGHG needs to be done first by electricity, and then recombined with fuel EnGHG
rs_base_all_ER[,c("ElecGHGkg_2020_LRE","ElecGHGkg_2025_LRE","ElecGHGkg_2030_LRE","ElecGHGkg_2035_LRE","ElecGHGkg_2040_LRE","ElecGHGkg_2045_LRE","ElecGHGkg_2050_LRE","ElecGHGkg_2055_LRE","ElecGHGkg_2060_LRE")]<-1000* 
  (rs_base_all_ER$base_weight*rs_base_all_ER[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*
  (rs_base_all_ER$Elec_GJ*rs_base_all_ER[,c("GHG_int_2020_LRE", "GHG_int_2025_LRE","GHG_int_2030_LRE","GHG_int_2035_LRE","GHG_int_2040_LRE","GHG_int_2045_LRE","GHG_int_2050_LRE","GHG_int_2055_LRE","GHG_int_2060_LRE")])

rs_base_all_ER[,c("ElecGHGkg_2020_CFE","ElecGHGkg_2025_CFE","ElecGHGkg_2030_CFE","ElecGHGkg_2035_CFE","ElecGHGkg_2040_CFE","ElecGHGkg_2045_CFE","ElecGHGkg_2050_CFE","ElecGHGkg_2055_CFE","ElecGHGkg_2060_CFE")]<-1000* 
  (rs_base_all_ER$base_weight*rs_base_all_ER[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*
  (rs_base_all_ER$Elec_GJ*rs_base_all_ER[,c("GHG_int_2020_CFE", "GHG_int_2025_CFE","GHG_int_2030_CFE","GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")])

GHGelec_base_ER_LRE<-data.frame(Year=seq(2020,2060,5),ElGHG=1e-9*colSums(rs_base_all_ER[,212:220])) # emissions in Mt 
GHGelec_base_ER_LRE<-data.frame(data.frame(ElGHG=with(select(GHGelec_base_ER_LRE,Year,ElGHG),spline(Year,ElGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="A",RenScen="ER",ElecScen="LRE")
names(GHGelec_base_ER_LRE)[1:2]<-c("Year","ElGHG")

GHGelec_base_ER_CFE<-data.frame(Year=seq(2020,2060,5),ElGHG=1e-9*colSums(rs_base_all_ER[,221:229])) # emissions in Mt 
GHGelec_base_ER_CFE<-data.frame(data.frame(ElGHG=with(select(GHGelec_base_ER_CFE,Year,ElGHG),spline(Year,ElGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="A",RenScen="ER",ElecScen="CFE")
names(GHGelec_base_ER_CFE)[1:2]<-c("Year","ElGHG")

GHGelec_base_ER_CFE$ElGHG[1:6]<-GHGelec_base_ER_LRE$ElGHG[1:6] # 2020:2025 is same in CFE as in LRE
GHGelec_base_ER_CFE$ElGHG[16:41]<-0 # 2035:2060 is 0 in CFE

GHG_base_ER_CFE<-GHG_base_ER_LREC
GHG_base_ER_CFE$ElecScen<-"CFE"
GHG_base_ER_CFE$EnGHG<-GHG_base_ER_LREC$EnGHG-GHGelec_base_ER_LRE$ElGHG+GHGelec_base_ER_CFE$ElGHG # energy emissions equal total LRE enGHG - LRE elGHG + CFE elGHG
GHG_base_ER_CFE$EmGHG<-us_base_FA$GHG_NC*1e-9
GHG_base_ER_CFE$EmGHG[41]<-GHG_base_ER_CFE$EmGHG[40]
GHG_base_ER_CFE$RenGHG<-renGHGall[renGHGall$Scen=="Base_Ext",]$MtCO2e
GHG_base_ER_CFE$TotGHG<-GHG_base_ER_CFE$EmGHG+GHG_base_ER_CFE$RenGHG+GHG_base_ER_CFE$EnGHG

# hi DR
# add in GHG intensities for 2035 CFE
rs_hiDR_all_RR[,c("GHG_int_2020_CFE","GHG_int_2025_CFE")]<-rs_hiDR_all_RR[,c("GHG_int_2020_LRE","GHG_int_2025_LRE")]
rs_hiDR_all_RR[,c("GHG_int_2030_CFE")]<-0.5*rs_hiDR_all_RR[,c("GHG_int_2025_LRE")]
rs_hiDR_all_RR[,c("GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")]<-0

rs_hiDR_all_AR[,c("GHG_int_2020_CFE","GHG_int_2025_CFE")]<-rs_hiDR_all_AR[,c("GHG_int_2020_LRE","GHG_int_2025_LRE")]
rs_hiDR_all_AR[,c("GHG_int_2030_CFE")]<-0.5*rs_hiDR_all_AR[,c("GHG_int_2025_LRE")]
rs_hiDR_all_AR[,c("GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")]<-0

rs_hiDR_all_ER[,c("GHG_int_2020_CFE","GHG_int_2025_CFE")]<-rs_hiDR_all_ER[,c("GHG_int_2020_LRE","GHG_int_2025_LRE")]
rs_hiDR_all_ER[,c("GHG_int_2030_CFE")]<-0.5*rs_hiDR_all_ER[,c("GHG_int_2025_LRE")]
rs_hiDR_all_ER[,c("GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")]<-0

# add in GHG emissions for CFE
rs_hiDR_all_RR[,c("EnGHGkg_hiDR_2020_CFE","EnGHGkg_hiDR_2025_CFE","EnGHGkg_hiDR_2030_CFE","EnGHGkg_hiDR_2035_CFE","EnGHGkg_hiDR_2040_CFE","EnGHGkg_hiDR_2045_CFE","EnGHGkg_hiDR_2050_CFE","EnGHGkg_hiDR_2055_CFE","EnGHGkg_hiDR_2060_CFE")]<-1000* 
  (rs_hiDR_all_RR$base_weight*rs_hiDR_all_RR[,c("whiDR_2020",  "whiDR_2025", "whiDR_2030", "whiDR_2035", "whiDR_2040", "whiDR_2045", "whiDR_2050", "whiDR_2055", "whiDR_2060")])*
  (rs_hiDR_all_RR$Elec_GJ*rs_hiDR_all_RR[,c("GHG_int_2020_CFE", "GHG_int_2025_CFE","GHG_int_2030_CFE","GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")]+
     matrix(rep(rs_hiDR_all_RR$Gas_GJ*GHGI_NG,9),nrow(rs_hiDR_all_RR),9)+ matrix(rep(rs_hiDR_all_RR$Oil_GJ*GHGI_FO,9),nrow(rs_hiDR_all_RR),9)+ matrix(rep(rs_hiDR_all_RR$Prop_GJ*GHGI_LP,9),nrow(rs_hiDR_all_RR),9))

rs_hiDR_all_AR[,c("EnGHGkg_hiDR_2020_CFE","EnGHGkg_hiDR_2025_CFE","EnGHGkg_hiDR_2030_CFE","EnGHGkg_hiDR_2035_CFE","EnGHGkg_hiDR_2040_CFE","EnGHGkg_hiDR_2045_CFE","EnGHGkg_hiDR_2050_CFE","EnGHGkg_hiDR_2055_CFE","EnGHGkg_hiDR_2060_CFE")]<-1000* 
  (rs_hiDR_all_AR$base_weight*rs_hiDR_all_AR[,c("whiDR_2020",  "whiDR_2025", "whiDR_2030", "whiDR_2035", "whiDR_2040", "whiDR_2045", "whiDR_2050", "whiDR_2055", "whiDR_2060")])*
  (rs_hiDR_all_AR$Elec_GJ*rs_hiDR_all_AR[,c("GHG_int_2020_CFE", "GHG_int_2025_CFE","GHG_int_2030_CFE","GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")]+
     matrix(rep(rs_hiDR_all_AR$Gas_GJ*GHGI_NG,9),nrow(rs_hiDR_all_AR),9)+ matrix(rep(rs_hiDR_all_AR$Oil_GJ*GHGI_FO,9),nrow(rs_hiDR_all_AR),9)+ matrix(rep(rs_hiDR_all_AR$Prop_GJ*GHGI_LP,9),nrow(rs_hiDR_all_AR),9))

rs_hiDR_all_ER[,c("EnGHGkg_hiDR_2020_CFE","EnGHGkg_hiDR_2025_CFE","EnGHGkg_hiDR_2030_CFE","EnGHGkg_hiDR_2035_CFE","EnGHGkg_hiDR_2040_CFE","EnGHGkg_hiDR_2045_CFE","EnGHGkg_hiDR_2050_CFE","EnGHGkg_hiDR_2055_CFE","EnGHGkg_hiDR_2060_CFE")]<-1000* 
  (rs_hiDR_all_ER$base_weight*rs_hiDR_all_ER[,c("whiDR_2020",  "whiDR_2025", "whiDR_2030", "whiDR_2035", "whiDR_2040", "whiDR_2045", "whiDR_2050", "whiDR_2055", "whiDR_2060")])*
  (rs_hiDR_all_ER$Elec_GJ*rs_hiDR_all_ER[,c("GHG_int_2020_CFE", "GHG_int_2025_CFE","GHG_int_2030_CFE","GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")]+
     matrix(rep(rs_hiDR_all_ER$Gas_GJ*GHGI_NG,9),nrow(rs_hiDR_all_ER),9)+ matrix(rep(rs_hiDR_all_ER$Oil_GJ*GHGI_FO,9),nrow(rs_hiDR_all_ER),9)+ matrix(rep(rs_hiDR_all_ER$Prop_GJ*GHGI_LP,9),nrow(rs_hiDR_all_ER),9))


GHG_hiDR_RR<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_hiDR_all_RR[,176:184])) # emissions in Mt 
GHG_hiDR_RR<-data.frame(data.frame(EnGHG=with(select(GHG_hiDR_RR,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=2,CharScen="A",RenScen="RR",ElecScen="MC")
names(GHG_hiDR_RR)[1:2]<-c("Year","EnGHG")
GHG_hiDR_RR$EmGHG<-us_hiDR_FA$GHG_NC*1e-9
GHG_hiDR_RR$EmGHG[41]<-GHG_hiDR_RR$EmGHG[40]
GHG_hiDR_RR$RenGHG<-renGHGall[renGHGall$Scen=="hiTO_Reg",]$MtCO2e
GHG_hiDR_RR$TotGHG<-GHG_hiDR_RR$EmGHG+GHG_hiDR_RR$RenGHG+GHG_hiDR_RR$EnGHG

GHG_hiDR_RR_LREC<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_hiDR_all_RR[,185:193])) # emissions in Mt 
GHG_hiDR_RR_LREC<-data.frame(data.frame(EnGHG=with(select(GHG_hiDR_RR_LREC,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=2,CharScen="A",RenScen="RR",ElecScen="LREC")
names(GHG_hiDR_RR_LREC)[1:2]<-c("Year","EnGHG")
GHG_hiDR_RR_LREC$EmGHG<-us_hiDR_FA$GHG_NC*1e-9
GHG_hiDR_RR_LREC$EmGHG[41]<-GHG_hiDR_RR_LREC$EmGHG[40]
GHG_hiDR_RR_LREC$RenGHG<-renGHGall[renGHGall$Scen=="hiTO_Reg",]$MtCO2e
GHG_hiDR_RR_LREC$TotGHG<-GHG_hiDR_RR_LREC$EmGHG+GHG_hiDR_RR_LREC$RenGHG+GHG_hiDR_RR_LREC$EnGHG

# for CFE, EnGHG needs to be done first by electricity, and then recombined with fuel EnGHG
rs_hiDR_all_RR[,c("ElecGHGkg_2020_LRE","ElecGHGkg_2025_LRE","ElecGHGkg_2030_LRE","ElecGHGkg_2035_LRE","ElecGHGkg_2040_LRE","ElecGHGkg_2045_LRE","ElecGHGkg_2050_LRE","ElecGHGkg_2055_LRE","ElecGHGkg_2060_LRE")]<-1000* 
  (rs_hiDR_all_RR$base_weight*rs_hiDR_all_RR[,c("whiDR_2020",  "whiDR_2025", "whiDR_2030", "whiDR_2035", "whiDR_2040", "whiDR_2045", "whiDR_2050", "whiDR_2055", "whiDR_2060")])*
  (rs_hiDR_all_RR$Elec_GJ*rs_hiDR_all_RR[,c("GHG_int_2020_LRE", "GHG_int_2025_LRE","GHG_int_2030_LRE","GHG_int_2035_LRE","GHG_int_2040_LRE","GHG_int_2045_LRE","GHG_int_2050_LRE","GHG_int_2055_LRE","GHG_int_2060_LRE")])

rs_hiDR_all_RR[,c("ElecGHGkg_2020_CFE","ElecGHGkg_2025_CFE","ElecGHGkg_2030_CFE","ElecGHGkg_2035_CFE","ElecGHGkg_2040_CFE","ElecGHGkg_2045_CFE","ElecGHGkg_2050_CFE","ElecGHGkg_2055_CFE","ElecGHGkg_2060_CFE")]<-1000* 
  (rs_hiDR_all_RR$base_weight*rs_hiDR_all_RR[,c("whiDR_2020",  "whiDR_2025", "whiDR_2030", "whiDR_2035", "whiDR_2040", "whiDR_2045", "whiDR_2050", "whiDR_2055", "whiDR_2060")])*
  (rs_hiDR_all_RR$Elec_GJ*rs_hiDR_all_RR[,c("GHG_int_2020_CFE", "GHG_int_2025_CFE","GHG_int_2030_CFE","GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")])

GHGelec_hiDR_RR_LRE<-data.frame(Year=seq(2020,2060,5),ElGHG=1e-9*colSums(rs_hiDR_all_RR[,212:220])) # emissions in Mt 
GHGelec_hiDR_RR_LRE<-data.frame(data.frame(ElGHG=with(select(GHGelec_hiDR_RR_LRE,Year,ElGHG),spline(Year,ElGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="A",RenScen="RR",ElecScen="LRE")
names(GHGelec_hiDR_RR_LRE)[1:2]<-c("Year","ElGHG")

GHGelec_hiDR_RR_CFE<-data.frame(Year=seq(2020,2060,5),ElGHG=1e-9*colSums(rs_hiDR_all_RR[,221:229])) # emissions in Mt 
GHGelec_hiDR_RR_CFE<-data.frame(data.frame(ElGHG=with(select(GHGelec_hiDR_RR_CFE,Year,ElGHG),spline(Year,ElGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="A",RenScen="RR",ElecScen="CFE")
names(GHGelec_hiDR_RR_CFE)[1:2]<-c("Year","ElGHG")

GHGelec_hiDR_RR_CFE$ElGHG[1:6]<-GHGelec_hiDR_RR_LRE$ElGHG[1:6] # 2020:2025 is same in CFE as in LRE
GHGelec_hiDR_RR_CFE$ElGHG[16:41]<-0 # 2035:2060 is 0 in CFE

GHG_hiDR_RR_CFE<-GHG_hiDR_RR_LREC
GHG_hiDR_RR_CFE$ElecScen<-"CFE"
GHG_hiDR_RR_CFE$EnGHG<-GHG_hiDR_RR_LREC$EnGHG-GHGelec_hiDR_RR_LRE$ElGHG+GHGelec_hiDR_RR_CFE$ElGHG # energy emissions equal total LRE enGHG - LRE elGHG + CFE elGHG
GHG_hiDR_RR_CFE$EmGHG<-us_hiDR_FA$GHG_NC*1e-9
GHG_hiDR_RR_CFE$EmGHG[41]<-GHG_hiDR_RR_CFE$EmGHG[40]
GHG_hiDR_RR_CFE$RenGHG<-renGHGall[renGHGall$Scen=="hiTO_Reg",]$MtCO2e
GHG_hiDR_RR_CFE$TotGHG<-GHG_hiDR_RR_CFE$EmGHG+GHG_hiDR_RR_CFE$RenGHG+GHG_hiDR_RR_CFE$EnGHG
# hiDR AR
GHG_hiDR_AR<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_hiDR_all_AR[,176:184])) # emissions in Mt 
GHG_hiDR_AR<-data.frame(data.frame(EnGHG=with(select(GHG_hiDR_AR,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=2,CharScen="A",RenScen="AR",ElecScen="MC")
names(GHG_hiDR_AR)[1:2]<-c("Year","EnGHG")
GHG_hiDR_AR$EmGHG<-us_hiDR_FA$GHG_NC*1e-9
GHG_hiDR_AR$EmGHG[41]<-GHG_hiDR_AR$EmGHG[40]
GHG_hiDR_AR$RenGHG<-renGHGall[renGHGall$Scen=="hiTO_Adv",]$MtCO2e
GHG_hiDR_AR$TotGHG<-GHG_hiDR_AR$EmGHG+GHG_hiDR_AR$RenGHG+GHG_hiDR_AR$EnGHG

GHG_hiDR_AR_LREC<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_hiDR_all_AR[,185:193])) # emissions in Mt 
GHG_hiDR_AR_LREC<-data.frame(data.frame(EnGHG=with(select(GHG_hiDR_AR_LREC,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=2,CharScen="A",RenScen="AR",ElecScen="LREC")
names(GHG_hiDR_AR_LREC)[1:2]<-c("Year","EnGHG")
GHG_hiDR_AR_LREC$EmGHG<-us_hiDR_FA$GHG_NC*1e-9
GHG_hiDR_AR_LREC$EmGHG[41]<-GHG_hiDR_AR_LREC$EmGHG[40]
GHG_hiDR_AR_LREC$RenGHG<-renGHGall[renGHGall$Scen=="hiTO_Adv",]$MtCO2e
GHG_hiDR_AR_LREC$TotGHG<-GHG_hiDR_AR_LREC$EmGHG+GHG_hiDR_AR_LREC$RenGHG+GHG_hiDR_AR_LREC$EnGHG

# for CFE, EnGHG needs to be done first by electricity, and then recombined with fuel EnGHG
rs_hiDR_all_AR[,c("ElecGHGkg_2020_LRE","ElecGHGkg_2025_LRE","ElecGHGkg_2030_LRE","ElecGHGkg_2035_LRE","ElecGHGkg_2040_LRE","ElecGHGkg_2045_LRE","ElecGHGkg_2050_LRE","ElecGHGkg_2055_LRE","ElecGHGkg_2060_LRE")]<-1000* 
  (rs_hiDR_all_AR$base_weight*rs_hiDR_all_AR[,c("whiDR_2020",  "whiDR_2025", "whiDR_2030", "whiDR_2035", "whiDR_2040", "whiDR_2045", "whiDR_2050", "whiDR_2055", "whiDR_2060")])*
  (rs_hiDR_all_AR$Elec_GJ*rs_hiDR_all_AR[,c("GHG_int_2020_LRE", "GHG_int_2025_LRE","GHG_int_2030_LRE","GHG_int_2035_LRE","GHG_int_2040_LRE","GHG_int_2045_LRE","GHG_int_2050_LRE","GHG_int_2055_LRE","GHG_int_2060_LRE")])

rs_hiDR_all_AR[,c("ElecGHGkg_2020_CFE","ElecGHGkg_2025_CFE","ElecGHGkg_2030_CFE","ElecGHGkg_2035_CFE","ElecGHGkg_2040_CFE","ElecGHGkg_2045_CFE","ElecGHGkg_2050_CFE","ElecGHGkg_2055_CFE","ElecGHGkg_2060_CFE")]<-1000* 
  (rs_hiDR_all_AR$base_weight*rs_hiDR_all_AR[,c("whiDR_2020",  "whiDR_2025", "whiDR_2030", "whiDR_2035", "whiDR_2040", "whiDR_2045", "whiDR_2050", "whiDR_2055", "whiDR_2060")])*
  (rs_hiDR_all_AR$Elec_GJ*rs_hiDR_all_AR[,c("GHG_int_2020_CFE", "GHG_int_2025_CFE","GHG_int_2030_CFE","GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")])

GHGelec_hiDR_AR_LRE<-data.frame(Year=seq(2020,2060,5),ElGHG=1e-9*colSums(rs_hiDR_all_AR[,212:220])) # emissions in Mt 
GHGelec_hiDR_AR_LRE<-data.frame(data.frame(ElGHG=with(select(GHGelec_hiDR_AR_LRE,Year,ElGHG),spline(Year,ElGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="A",RenScen="AR",ElecScen="LRE")
names(GHGelec_hiDR_AR_LRE)[1:2]<-c("Year","ElGHG")

GHGelec_hiDR_AR_CFE<-data.frame(Year=seq(2020,2060,5),ElGHG=1e-9*colSums(rs_hiDR_all_AR[,221:229])) # emissions in Mt 
GHGelec_hiDR_AR_CFE<-data.frame(data.frame(ElGHG=with(select(GHGelec_hiDR_AR_CFE,Year,ElGHG),spline(Year,ElGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="A",RenScen="AR",ElecScen="CFE")
names(GHGelec_hiDR_AR_CFE)[1:2]<-c("Year","ElGHG")

GHGelec_hiDR_AR_CFE$ElGHG[1:6]<-GHGelec_hiDR_AR_LRE$ElGHG[1:6] # 2020:2025 is same in CFE as in LRE
GHGelec_hiDR_AR_CFE$ElGHG[16:41]<-0 # 2035:2060 is 0 in CFE

GHG_hiDR_AR_CFE<-GHG_hiDR_AR_LREC
GHG_hiDR_AR_CFE$ElecScen<-"CFE"
GHG_hiDR_AR_CFE$EnGHG<-GHG_hiDR_AR_LREC$EnGHG-GHGelec_hiDR_AR_LRE$ElGHG+GHGelec_hiDR_AR_CFE$ElGHG # energy emissions equal total LRE enGHG - LRE elGHG + CFE elGHG
GHG_hiDR_AR_CFE$EmGHG<-us_hiDR_FA$GHG_NC*1e-9
GHG_hiDR_AR_CFE$EmGHG[41]<-GHG_hiDR_AR_CFE$EmGHG[40]
GHG_hiDR_AR_CFE$RenGHG<-renGHGall[renGHGall$Scen=="hiTO_Adv",]$MtCO2e
GHG_hiDR_AR_CFE$TotGHG<-GHG_hiDR_AR_CFE$EmGHG+GHG_hiDR_AR_CFE$RenGHG+GHG_hiDR_AR_CFE$EnGHG
# hiDR ER
GHG_hiDR_ER<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_hiDR_all_ER[,176:184])) # emissions in Mt 
GHG_hiDR_ER<-data.frame(data.frame(EnGHG=with(select(GHG_hiDR_ER,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=2,CharScen="A",RenScen="ER",ElecScen="MC")
names(GHG_hiDR_ER)[1:2]<-c("Year","EnGHG")
GHG_hiDR_ER$EmGHG<-us_hiDR_FA$GHG_NC*1e-9
GHG_hiDR_ER$EmGHG[41]<-GHG_hiDR_ER$EmGHG[40]
GHG_hiDR_ER$RenGHG<-renGHGall[renGHGall$Scen=="hiTO_Ext",]$MtCO2e
GHG_hiDR_ER$TotGHG<-GHG_hiDR_ER$EmGHG+GHG_hiDR_ER$RenGHG+GHG_hiDR_ER$EnGHG

GHG_hiDR_ER_LREC<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_hiDR_all_ER[,185:193])) # emissions in Mt 
GHG_hiDR_ER_LREC<-data.frame(data.frame(EnGHG=with(select(GHG_hiDR_ER_LREC,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=2,CharScen="A",RenScen="ER",ElecScen="LREC")
names(GHG_hiDR_ER_LREC)[1:2]<-c("Year","EnGHG")
GHG_hiDR_ER_LREC$EmGHG<-us_hiDR_FA$GHG_NC*1e-9
GHG_hiDR_ER_LREC$EmGHG[41]<-GHG_hiDR_ER_LREC$EmGHG[40]
GHG_hiDR_ER_LREC$RenGHG<-renGHGall[renGHGall$Scen=="hiTO_Ext",]$MtCO2e
GHG_hiDR_ER_LREC$TotGHG<-GHG_hiDR_ER_LREC$EmGHG+GHG_hiDR_ER_LREC$RenGHG+GHG_hiDR_ER_LREC$EnGHG
# for CFE, EnGHG needs to be done first by electricity, and then recombined with fuel EnGHG
rs_hiDR_all_ER[,c("ElecGHGkg_2020_LRE","ElecGHGkg_2025_LRE","ElecGHGkg_2030_LRE","ElecGHGkg_2035_LRE","ElecGHGkg_2040_LRE","ElecGHGkg_2045_LRE","ElecGHGkg_2050_LRE","ElecGHGkg_2055_LRE","ElecGHGkg_2060_LRE")]<-1000* 
  (rs_hiDR_all_ER$base_weight*rs_hiDR_all_ER[,c("whiDR_2020",  "whiDR_2025", "whiDR_2030", "whiDR_2035", "whiDR_2040", "whiDR_2045", "whiDR_2050", "whiDR_2055", "whiDR_2060")])*
  (rs_hiDR_all_ER$Elec_GJ*rs_hiDR_all_ER[,c("GHG_int_2020_LRE", "GHG_int_2025_LRE","GHG_int_2030_LRE","GHG_int_2035_LRE","GHG_int_2040_LRE","GHG_int_2045_LRE","GHG_int_2050_LRE","GHG_int_2055_LRE","GHG_int_2060_LRE")])

rs_hiDR_all_ER[,c("ElecGHGkg_2020_CFE","ElecGHGkg_2025_CFE","ElecGHGkg_2030_CFE","ElecGHGkg_2035_CFE","ElecGHGkg_2040_CFE","ElecGHGkg_2045_CFE","ElecGHGkg_2050_CFE","ElecGHGkg_2055_CFE","ElecGHGkg_2060_CFE")]<-1000* 
  (rs_hiDR_all_ER$base_weight*rs_hiDR_all_ER[,c("whiDR_2020",  "whiDR_2025", "whiDR_2030", "whiDR_2035", "whiDR_2040", "whiDR_2045", "whiDR_2050", "whiDR_2055", "whiDR_2060")])*
  (rs_hiDR_all_ER$Elec_GJ*rs_hiDR_all_ER[,c("GHG_int_2020_CFE", "GHG_int_2025_CFE","GHG_int_2030_CFE","GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")])

GHGelec_hiDR_ER_LRE<-data.frame(Year=seq(2020,2060,5),ElGHG=1e-9*colSums(rs_hiDR_all_ER[,212:220])) # emissions in Mt 
GHGelec_hiDR_ER_LRE<-data.frame(data.frame(ElGHG=with(select(GHGelec_hiDR_ER_LRE,Year,ElGHG),spline(Year,ElGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="A",RenScen="ER",ElecScen="LRE")
names(GHGelec_hiDR_ER_LRE)[1:2]<-c("Year","ElGHG")

GHGelec_hiDR_ER_CFE<-data.frame(Year=seq(2020,2060,5),ElGHG=1e-9*colSums(rs_hiDR_all_ER[,221:229])) # emissions in Mt 
GHGelec_hiDR_ER_CFE<-data.frame(data.frame(ElGHG=with(select(GHGelec_hiDR_ER_CFE,Year,ElGHG),spline(Year,ElGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="A",RenScen="ER",ElecScen="CFE")
names(GHGelec_hiDR_ER_CFE)[1:2]<-c("Year","ElGHG")

GHGelec_hiDR_ER_CFE$ElGHG[1:6]<-GHGelec_hiDR_ER_LRE$ElGHG[1:6] # 2020:2025 is same in CFE as in LRE
GHGelec_hiDR_ER_CFE$ElGHG[16:41]<-0 # 2035:2060 is 0 in CFE

GHG_hiDR_ER_CFE<-GHG_hiDR_ER_LREC
GHG_hiDR_ER_CFE$ElecScen<-"CFE"
GHG_hiDR_ER_CFE$EnGHG<-GHG_hiDR_ER_LREC$EnGHG-GHGelec_hiDR_ER_LRE$ElGHG+GHGelec_hiDR_ER_CFE$ElGHG # energy emissions equal total LRE enGHG - LRE elGHG + CFE elGHG
GHG_hiDR_ER_CFE$EmGHG<-us_hiDR_FA$GHG_NC*1e-9
GHG_hiDR_ER_CFE$EmGHG[41]<-GHG_hiDR_ER_CFE$EmGHG[40]
GHG_hiDR_ER_CFE$RenGHG<-renGHGall[renGHGall$Scen=="hiTO_Ext",]$MtCO2e
GHG_hiDR_ER_CFE$TotGHG<-GHG_hiDR_ER_CFE$EmGHG+GHG_hiDR_ER_CFE$RenGHG+GHG_hiDR_ER_CFE$EnGHG

# hi MF
# add in GHG intensities for 2035 CFE
rs_hiMF_all_RR[,c("GHG_int_2020_CFE","GHG_int_2025_CFE")]<-rs_hiMF_all_RR[,c("GHG_int_2020_LRE","GHG_int_2025_LRE")]
rs_hiMF_all_RR[,c("GHG_int_2030_CFE")]<-0.5*rs_hiMF_all_RR[,c("GHG_int_2025_LRE")]
rs_hiMF_all_RR[,c("GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")]<-0

rs_hiMF_all_AR[,c("GHG_int_2020_CFE","GHG_int_2025_CFE")]<-rs_hiMF_all_AR[,c("GHG_int_2020_LRE","GHG_int_2025_LRE")]
rs_hiMF_all_AR[,c("GHG_int_2030_CFE")]<-0.5*rs_hiMF_all_AR[,c("GHG_int_2025_LRE")]
rs_hiMF_all_AR[,c("GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")]<-0

rs_hiMF_all_ER[,c("GHG_int_2020_CFE","GHG_int_2025_CFE")]<-rs_hiMF_all_ER[,c("GHG_int_2020_LRE","GHG_int_2025_LRE")]
rs_hiMF_all_ER[,c("GHG_int_2030_CFE")]<-0.5*rs_hiMF_all_ER[,c("GHG_int_2025_LRE")]
rs_hiMF_all_ER[,c("GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")]<-0

# add in GHG emissions for CFE
rs_hiMF_all_RR[,c("EnGHGkg_hiMF_2020_CFE","EnGHGkg_hiMF_2025_CFE","EnGHGkg_hiMF_2030_CFE","EnGHGkg_hiMF_2035_CFE","EnGHGkg_hiMF_2040_CFE","EnGHGkg_hiMF_2045_CFE","EnGHGkg_hiMF_2050_CFE","EnGHGkg_hiMF_2055_CFE","EnGHGkg_hiMF_2060_CFE")]<-1000* 
  (rs_hiMF_all_RR$base_weight*rs_hiMF_all_RR[,c("whiMF_2020",  "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")])*
  (rs_hiMF_all_RR$Elec_GJ*rs_hiMF_all_RR[,c("GHG_int_2020_CFE", "GHG_int_2025_CFE","GHG_int_2030_CFE","GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")]+
     matrix(rep(rs_hiMF_all_RR$Gas_GJ*GHGI_NG,9),nrow(rs_hiMF_all_RR),9)+ matrix(rep(rs_hiMF_all_RR$Oil_GJ*GHGI_FO,9),nrow(rs_hiMF_all_RR),9)+ matrix(rep(rs_hiMF_all_RR$Prop_GJ*GHGI_LP,9),nrow(rs_hiMF_all_RR),9))

rs_hiMF_all_AR[,c("EnGHGkg_hiMF_2020_CFE","EnGHGkg_hiMF_2025_CFE","EnGHGkg_hiMF_2030_CFE","EnGHGkg_hiMF_2035_CFE","EnGHGkg_hiMF_2040_CFE","EnGHGkg_hiMF_2045_CFE","EnGHGkg_hiMF_2050_CFE","EnGHGkg_hiMF_2055_CFE","EnGHGkg_hiMF_2060_CFE")]<-1000* 
  (rs_hiMF_all_AR$base_weight*rs_hiMF_all_AR[,c("whiMF_2020",  "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")])*
  (rs_hiMF_all_AR$Elec_GJ*rs_hiMF_all_AR[,c("GHG_int_2020_CFE", "GHG_int_2025_CFE","GHG_int_2030_CFE","GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")]+
     matrix(rep(rs_hiMF_all_AR$Gas_GJ*GHGI_NG,9),nrow(rs_hiMF_all_AR),9)+ matrix(rep(rs_hiMF_all_AR$Oil_GJ*GHGI_FO,9),nrow(rs_hiMF_all_AR),9)+ matrix(rep(rs_hiMF_all_AR$Prop_GJ*GHGI_LP,9),nrow(rs_hiMF_all_AR),9))

rs_hiMF_all_ER[,c("EnGHGkg_hiMF_2020_CFE","EnGHGkg_hiMF_2025_CFE","EnGHGkg_hiMF_2030_CFE","EnGHGkg_hiMF_2035_CFE","EnGHGkg_hiMF_2040_CFE","EnGHGkg_hiMF_2045_CFE","EnGHGkg_hiMF_2050_CFE","EnGHGkg_hiMF_2055_CFE","EnGHGkg_hiMF_2060_CFE")]<-1000* 
  (rs_hiMF_all_ER$base_weight*rs_hiMF_all_ER[,c("whiMF_2020",  "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")])*
  (rs_hiMF_all_ER$Elec_GJ*rs_hiMF_all_ER[,c("GHG_int_2020_CFE", "GHG_int_2025_CFE","GHG_int_2030_CFE","GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")]+
     matrix(rep(rs_hiMF_all_ER$Gas_GJ*GHGI_NG,9),nrow(rs_hiMF_all_ER),9)+ matrix(rep(rs_hiMF_all_ER$Oil_GJ*GHGI_FO,9),nrow(rs_hiMF_all_ER),9)+ matrix(rep(rs_hiMF_all_ER$Prop_GJ*GHGI_LP,9),nrow(rs_hiMF_all_ER),9))


GHG_hiMF_RR<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_hiMF_all_RR[,176:184])) # emissions in Mt 
GHG_hiMF_RR<-data.frame(data.frame(EnGHG=with(select(GHG_hiMF_RR,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=3,CharScen="A",RenScen="RR",ElecScen="MC")
names(GHG_hiMF_RR)[1:2]<-c("Year","EnGHG")
GHG_hiMF_RR$EmGHG<-us_hiMF_FA$GHG_NC*1e-9
GHG_hiMF_RR$EmGHG[41]<-GHG_hiMF_RR$EmGHG[40]
GHG_hiMF_RR$RenGHG<-renGHGall[renGHGall$Scen=="hiMF_Reg",]$MtCO2e
GHG_hiMF_RR$TotGHG<-GHG_hiMF_RR$EmGHG+GHG_hiMF_RR$RenGHG+GHG_hiMF_RR$EnGHG

GHG_hiMF_RR_LREC<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_hiMF_all_RR[,185:193])) # emissions in Mt 
GHG_hiMF_RR_LREC<-data.frame(data.frame(EnGHG=with(select(GHG_hiMF_RR_LREC,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=3,CharScen="A",RenScen="RR",ElecScen="LREC")
names(GHG_hiMF_RR_LREC)[1:2]<-c("Year","EnGHG")
GHG_hiMF_RR_LREC$EmGHG<-us_hiMF_FA$GHG_NC*1e-9
GHG_hiMF_RR_LREC$EmGHG[41]<-GHG_hiMF_RR_LREC$EmGHG[40]
GHG_hiMF_RR_LREC$RenGHG<-renGHGall[renGHGall$Scen=="hiMF_Reg",]$MtCO2e
GHG_hiMF_RR_LREC$TotGHG<-GHG_hiMF_RR_LREC$EmGHG+GHG_hiMF_RR_LREC$RenGHG+GHG_hiMF_RR_LREC$EnGHG

# for CFE, EnGHG needs to be done first by electricity, and then recombined with fuel EnGHG
rs_hiMF_all_RR[,c("ElecGHGkg_2020_LRE","ElecGHGkg_2025_LRE","ElecGHGkg_2030_LRE","ElecGHGkg_2035_LRE","ElecGHGkg_2040_LRE","ElecGHGkg_2045_LRE","ElecGHGkg_2050_LRE","ElecGHGkg_2055_LRE","ElecGHGkg_2060_LRE")]<-1000* 
  (rs_hiMF_all_RR$base_weight*rs_hiMF_all_RR[,c("whiMF_2020",  "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")])*
  (rs_hiMF_all_RR$Elec_GJ*rs_hiMF_all_RR[,c("GHG_int_2020_LRE", "GHG_int_2025_LRE","GHG_int_2030_LRE","GHG_int_2035_LRE","GHG_int_2040_LRE","GHG_int_2045_LRE","GHG_int_2050_LRE","GHG_int_2055_LRE","GHG_int_2060_LRE")])

rs_hiMF_all_RR[,c("ElecGHGkg_2020_CFE","ElecGHGkg_2025_CFE","ElecGHGkg_2030_CFE","ElecGHGkg_2035_CFE","ElecGHGkg_2040_CFE","ElecGHGkg_2045_CFE","ElecGHGkg_2050_CFE","ElecGHGkg_2055_CFE","ElecGHGkg_2060_CFE")]<-1000* 
  (rs_hiMF_all_RR$base_weight*rs_hiMF_all_RR[,c("whiMF_2020",  "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")])*
  (rs_hiMF_all_RR$Elec_GJ*rs_hiMF_all_RR[,c("GHG_int_2020_CFE", "GHG_int_2025_CFE","GHG_int_2030_CFE","GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")])

GHGelec_hiMF_RR_LRE<-data.frame(Year=seq(2020,2060,5),ElGHG=1e-9*colSums(rs_hiMF_all_RR[,212:220])) # emissions in Mt 
GHGelec_hiMF_RR_LRE<-data.frame(data.frame(ElGHG=with(select(GHGelec_hiMF_RR_LRE,Year,ElGHG),spline(Year,ElGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="A",RenScen="RR",ElecScen="LRE")
names(GHGelec_hiMF_RR_LRE)[1:2]<-c("Year","ElGHG")

GHGelec_hiMF_RR_CFE<-data.frame(Year=seq(2020,2060,5),ElGHG=1e-9*colSums(rs_hiMF_all_RR[,221:229])) # emissions in Mt 
GHGelec_hiMF_RR_CFE<-data.frame(data.frame(ElGHG=with(select(GHGelec_hiMF_RR_CFE,Year,ElGHG),spline(Year,ElGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="A",RenScen="RR",ElecScen="CFE")
names(GHGelec_hiMF_RR_CFE)[1:2]<-c("Year","ElGHG")

GHGelec_hiMF_RR_CFE$ElGHG[1:6]<-GHGelec_hiMF_RR_LRE$ElGHG[1:6] # 2020:2025 is same in CFE as in LRE
GHGelec_hiMF_RR_CFE$ElGHG[16:41]<-0 # 2035:2060 is 0 in CFE

GHG_hiMF_RR_CFE<-GHG_hiMF_RR_LREC
GHG_hiMF_RR_CFE$ElecScen<-"CFE"
GHG_hiMF_RR_CFE$EnGHG<-GHG_hiMF_RR_LREC$EnGHG-GHGelec_hiMF_RR_LRE$ElGHG+GHGelec_hiMF_RR_CFE$ElGHG # energy emissions equal total LRE enGHG - LRE elGHG + CFE elGHG
GHG_hiMF_RR_CFE$EmGHG<-us_hiMF_FA$GHG_NC*1e-9
GHG_hiMF_RR_CFE$EmGHG[41]<-GHG_hiMF_RR_CFE$EmGHG[40]
GHG_hiMF_RR_CFE$RenGHG<-renGHGall[renGHGall$Scen=="hiMF_Reg",]$MtCO2e
GHG_hiMF_RR_CFE$TotGHG<-GHG_hiMF_RR_CFE$EmGHG+GHG_hiMF_RR_CFE$RenGHG+GHG_hiMF_RR_CFE$EnGHG

# hiMF AR
GHG_hiMF_AR<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_hiMF_all_AR[,176:184])) # emissions in Mt 
GHG_hiMF_AR<-data.frame(data.frame(EnGHG=with(select(GHG_hiMF_AR,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=3,CharScen="A",RenScen="AR",ElecScen="MC")
names(GHG_hiMF_AR)[1:2]<-c("Year","EnGHG")
GHG_hiMF_AR$EmGHG<-us_hiMF_FA$GHG_NC*1e-9
GHG_hiMF_AR$EmGHG[41]<-GHG_hiMF_AR$EmGHG[40]
GHG_hiMF_AR$RenGHG<-renGHGall[renGHGall$Scen=="hiMF_Adv",]$MtCO2e
GHG_hiMF_AR$TotGHG<-GHG_hiMF_AR$EmGHG+GHG_hiMF_AR$RenGHG+GHG_hiMF_AR$EnGHG

GHG_hiMF_AR_LREC<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_hiMF_all_AR[,185:193])) # emissions in Mt 
GHG_hiMF_AR_LREC<-data.frame(data.frame(EnGHG=with(select(GHG_hiMF_AR_LREC,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=3,CharScen="A",RenScen="AR",ElecScen="LREC")
names(GHG_hiMF_AR_LREC)[1:2]<-c("Year","EnGHG")
GHG_hiMF_AR_LREC$EmGHG<-us_hiMF_FA$GHG_NC*1e-9
GHG_hiMF_AR_LREC$EmGHG[41]<-GHG_hiMF_AR_LREC$EmGHG[40]
GHG_hiMF_AR_LREC$RenGHG<-renGHGall[renGHGall$Scen=="hiMF_Adv",]$MtCO2e
GHG_hiMF_AR_LREC$TotGHG<-GHG_hiMF_AR_LREC$EmGHG+GHG_hiMF_AR_LREC$RenGHG+GHG_hiMF_AR_LREC$EnGHG

# for CFE, EnGHG needs to be done first by electricity, and then recombined with fuel EnGHG
rs_hiMF_all_AR[,c("ElecGHGkg_2020_LRE","ElecGHGkg_2025_LRE","ElecGHGkg_2030_LRE","ElecGHGkg_2035_LRE","ElecGHGkg_2040_LRE","ElecGHGkg_2045_LRE","ElecGHGkg_2050_LRE","ElecGHGkg_2055_LRE","ElecGHGkg_2060_LRE")]<-1000* 
  (rs_hiMF_all_AR$base_weight*rs_hiMF_all_AR[,c("whiMF_2020",  "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")])*
  (rs_hiMF_all_AR$Elec_GJ*rs_hiMF_all_AR[,c("GHG_int_2020_LRE", "GHG_int_2025_LRE","GHG_int_2030_LRE","GHG_int_2035_LRE","GHG_int_2040_LRE","GHG_int_2045_LRE","GHG_int_2050_LRE","GHG_int_2055_LRE","GHG_int_2060_LRE")])

rs_hiMF_all_AR[,c("ElecGHGkg_2020_CFE","ElecGHGkg_2025_CFE","ElecGHGkg_2030_CFE","ElecGHGkg_2035_CFE","ElecGHGkg_2040_CFE","ElecGHGkg_2045_CFE","ElecGHGkg_2050_CFE","ElecGHGkg_2055_CFE","ElecGHGkg_2060_CFE")]<-1000* 
  (rs_hiMF_all_AR$base_weight*rs_hiMF_all_AR[,c("whiMF_2020",  "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")])*
  (rs_hiMF_all_AR$Elec_GJ*rs_hiMF_all_AR[,c("GHG_int_2020_CFE", "GHG_int_2025_CFE","GHG_int_2030_CFE","GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")])

GHGelec_hiMF_AR_LRE<-data.frame(Year=seq(2020,2060,5),ElGHG=1e-9*colSums(rs_hiMF_all_AR[,212:220])) # emissions in Mt 
GHGelec_hiMF_AR_LRE<-data.frame(data.frame(ElGHG=with(select(GHGelec_hiMF_AR_LRE,Year,ElGHG),spline(Year,ElGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="A",RenScen="AR",ElecScen="LRE")
names(GHGelec_hiMF_AR_LRE)[1:2]<-c("Year","ElGHG")

GHGelec_hiMF_AR_CFE<-data.frame(Year=seq(2020,2060,5),ElGHG=1e-9*colSums(rs_hiMF_all_AR[,221:229])) # emissions in Mt 
GHGelec_hiMF_AR_CFE<-data.frame(data.frame(ElGHG=with(select(GHGelec_hiMF_AR_CFE,Year,ElGHG),spline(Year,ElGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="A",RenScen="AR",ElecScen="CFE")
names(GHGelec_hiMF_AR_CFE)[1:2]<-c("Year","ElGHG")

GHGelec_hiMF_AR_CFE$ElGHG[1:6]<-GHGelec_hiMF_AR_LRE$ElGHG[1:6] # 2020:2025 is same in CFE as in LRE
GHGelec_hiMF_AR_CFE$ElGHG[16:41]<-0 # 2035:2060 is 0 in CFE

GHG_hiMF_AR_CFE<-GHG_hiMF_AR_LREC
GHG_hiMF_AR_CFE$ElecScen<-"CFE"
GHG_hiMF_AR_CFE$EnGHG<-GHG_hiMF_AR_LREC$EnGHG-GHGelec_hiMF_AR_LRE$ElGHG+GHGelec_hiMF_AR_CFE$ElGHG # energy emissions equal total LRE enGHG - LRE elGHG + CFE elGHG
GHG_hiMF_AR_CFE$EmGHG<-us_hiMF_FA$GHG_NC*1e-9
GHG_hiMF_AR_CFE$EmGHG[41]<-GHG_hiMF_AR_CFE$EmGHG[40]
GHG_hiMF_AR_CFE$RenGHG<-renGHGall[renGHGall$Scen=="hiMF_Adv",]$MtCO2e
GHG_hiMF_AR_CFE$TotGHG<-GHG_hiMF_AR_CFE$EmGHG+GHG_hiMF_AR_CFE$RenGHG+GHG_hiMF_AR_CFE$EnGHG

# hiMF ER
GHG_hiMF_ER<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_hiMF_all_ER[,176:184])) # emissions in Mt 
GHG_hiMF_ER<-data.frame(data.frame(EnGHG=with(select(GHG_hiMF_ER,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=3,CharScen="A",RenScen="ER",ElecScen="MC")
names(GHG_hiMF_ER)[1:2]<-c("Year","EnGHG")
GHG_hiMF_ER$EmGHG<-us_hiMF_FA$GHG_NC*1e-9
GHG_hiMF_ER$EmGHG[41]<-GHG_hiMF_ER$EmGHG[40]
GHG_hiMF_ER$RenGHG<-renGHGall[renGHGall$Scen=="hiMF_Ext",]$MtCO2e
GHG_hiMF_ER$TotGHG<-GHG_hiMF_ER$EmGHG+GHG_hiMF_ER$RenGHG+GHG_hiMF_ER$EnGHG

GHG_hiMF_ER_LREC<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_hiMF_all_ER[,185:193])) # emissions in Mt 
GHG_hiMF_ER_LREC<-data.frame(data.frame(EnGHG=with(select(GHG_hiMF_ER_LREC,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=3,CharScen="A",RenScen="ER",ElecScen="LREC")
names(GHG_hiMF_ER_LREC)[1:2]<-c("Year","EnGHG")
GHG_hiMF_ER_LREC$EmGHG<-us_hiMF_FA$GHG_NC*1e-9
GHG_hiMF_ER_LREC$EmGHG[41]<-GHG_hiMF_ER_LREC$EmGHG[40]
GHG_hiMF_ER_LREC$RenGHG<-renGHGall[renGHGall$Scen=="hiMF_Ext",]$MtCO2e
GHG_hiMF_ER_LREC$TotGHG<-GHG_hiMF_ER_LREC$EmGHG+GHG_hiMF_ER_LREC$RenGHG+GHG_hiMF_ER_LREC$EnGHG

# for CFE, EnGHG needs to be done first by electricity, and then recombined with fuel EnGHG
rs_hiMF_all_ER[,c("ElecGHGkg_2020_LRE","ElecGHGkg_2025_LRE","ElecGHGkg_2030_LRE","ElecGHGkg_2035_LRE","ElecGHGkg_2040_LRE","ElecGHGkg_2045_LRE","ElecGHGkg_2050_LRE","ElecGHGkg_2055_LRE","ElecGHGkg_2060_LRE")]<-1000* 
  (rs_hiMF_all_ER$base_weight*rs_hiMF_all_ER[,c("whiMF_2020",  "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")])*
  (rs_hiMF_all_ER$Elec_GJ*rs_hiMF_all_ER[,c("GHG_int_2020_LRE", "GHG_int_2025_LRE","GHG_int_2030_LRE","GHG_int_2035_LRE","GHG_int_2040_LRE","GHG_int_2045_LRE","GHG_int_2050_LRE","GHG_int_2055_LRE","GHG_int_2060_LRE")])

rs_hiMF_all_ER[,c("ElecGHGkg_2020_CFE","ElecGHGkg_2025_CFE","ElecGHGkg_2030_CFE","ElecGHGkg_2035_CFE","ElecGHGkg_2040_CFE","ElecGHGkg_2045_CFE","ElecGHGkg_2050_CFE","ElecGHGkg_2055_CFE","ElecGHGkg_2060_CFE")]<-1000* 
  (rs_hiMF_all_ER$base_weight*rs_hiMF_all_ER[,c("whiMF_2020",  "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")])*
  (rs_hiMF_all_ER$Elec_GJ*rs_hiMF_all_ER[,c("GHG_int_2020_CFE", "GHG_int_2025_CFE","GHG_int_2030_CFE","GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")])

GHGelec_hiMF_ER_LRE<-data.frame(Year=seq(2020,2060,5),ElGHG=1e-9*colSums(rs_hiMF_all_ER[,212:220])) # emissions in Mt 
GHGelec_hiMF_ER_LRE<-data.frame(data.frame(ElGHG=with(select(GHGelec_hiMF_ER_LRE,Year,ElGHG),spline(Year,ElGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="A",RenScen="ER",ElecScen="LRE")
names(GHGelec_hiMF_ER_LRE)[1:2]<-c("Year","ElGHG")

GHGelec_hiMF_ER_CFE<-data.frame(Year=seq(2020,2060,5),ElGHG=1e-9*colSums(rs_hiMF_all_ER[,221:229])) # emissions in Mt 
GHGelec_hiMF_ER_CFE<-data.frame(data.frame(ElGHG=with(select(GHGelec_hiMF_ER_CFE,Year,ElGHG),spline(Year,ElGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="A",RenScen="ER",ElecScen="CFE")
names(GHGelec_hiMF_ER_CFE)[1:2]<-c("Year","ElGHG")

GHGelec_hiMF_ER_CFE$ElGHG[1:6]<-GHGelec_hiMF_ER_LRE$ElGHG[1:6] # 2020:2025 is same in CFE as in LRE
GHGelec_hiMF_ER_CFE$ElGHG[16:41]<-0 # 2035:2060 is 0 in CFE

GHG_hiMF_ER_CFE<-GHG_hiMF_ER_LREC
GHG_hiMF_ER_CFE$ElecScen<-"CFE"
GHG_hiMF_ER_CFE$EnGHG<-GHG_hiMF_ER_LREC$EnGHG-GHGelec_hiMF_ER_LRE$ElGHG+GHGelec_hiMF_ER_CFE$ElGHG # energy emissions equal total LRE enGHG - LRE elGHG + CFE elGHG
GHG_hiMF_ER_CFE$EmGHG<-us_hiMF_FA$GHG_NC*1e-9
GHG_hiMF_ER_CFE$EmGHG[41]<-GHG_hiMF_ER_CFE$EmGHG[40]
GHG_hiMF_ER_CFE$RenGHG<-renGHGall[renGHGall$Scen=="hiMF_Ext",]$MtCO2e
GHG_hiMF_ER_CFE$TotGHG<-GHG_hiMF_ER_CFE$EmGHG+GHG_hiMF_ER_CFE$RenGHG+GHG_hiMF_ER_CFE$EnGHG

# calculation source emissions from fuel for base RR #########
rs_base_all_RR$NewCon<-0
rs_base_all_RR[rs_base_all_RR$Vintage.ACS %in% c("2020s","2030s","2040s","2050s"),]$NewCon<-1
rs_base_all_RR$OldCon<-0
rs_base_all_RR[rs_base_all_RR$NewCon==0,]$OldCon<-1

rs_base_all_RR[,c("Old_OilGHGkg_2020","Old_OilGHGkg_2025","Old_OilGHGkg_2030","Old_OilGHGkg_2035","Old_OilGHGkg_2040","Old_OilGHGkg_2045","Old_OilGHGkg_2050","Old_OilGHGkg_2055","Old_OilGHGkg_2060")]<-1000* 
  rs_base_all_RR$OldCon*(rs_base_all_RR$base_weight*rs_base_all_RR[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*
  (matrix(rep(rs_base_all_RR$Oil_GJ*GHGI_FO,9),nrow(rs_base_all_RR),9)+ matrix(rep(rs_base_all_RR$Prop_GJ*GHGI_LP,9),nrow(rs_base_all_RR),9))

rs_base_all_RR[,c("New_OilGHGkg_2020","New_OilGHGkg_2025","New_OilGHGkg_2030","New_OilGHGkg_2035","New_OilGHGkg_2040","New_OilGHGkg_2045","New_OilGHGkg_2050","New_OilGHGkg_2055","New_OilGHGkg_2060")]<-1000* 
  rs_base_all_RR$NewCon*(rs_base_all_RR$base_weight*rs_base_all_RR[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*
  (matrix(rep(rs_base_all_RR$Oil_GJ*GHGI_FO,9),nrow(rs_base_all_RR),9)+ matrix(rep(rs_base_all_RR$Prop_GJ*GHGI_LP,9),nrow(rs_base_all_RR),9))

rs_base_all_RR[,c("Old_GasGHGkg_2020","Old_GasGHGkg_2025","Old_GasGHGkg_2030","Old_GasGHGkg_2035","Old_GasGHGkg_2040","Old_GasGHGkg_2045","Old_GasGHGkg_2050","Old_GasGHGkg_2055","Old_GasGHGkg_2060")]<-1000* 
  rs_base_all_RR$OldCon*(rs_base_all_RR$base_weight*rs_base_all_RR[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*
  (matrix(rep(rs_base_all_RR$Gas_GJ*GHGI_NG,9),nrow(rs_base_all_RR),9))

rs_base_all_RR[,c("New_GasGHGkg_2020","New_GasGHGkg_2025","New_GasGHGkg_2030","New_GasGHGkg_2035","New_GasGHGkg_2040","New_GasGHGkg_2045","New_GasGHGkg_2050","New_GasGHGkg_2055","New_GasGHGkg_2060")]<-1000* 
  rs_base_all_RR$NewCon*(rs_base_all_RR$base_weight*rs_base_all_RR[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*
  (matrix(rep(rs_base_all_RR$Gas_GJ*GHGI_NG,9),nrow(rs_base_all_RR),9))

rs_base_all_RR[,c("Old_ElecGHGkg_2020","Old_ElecGHGkg_2025","Old_ElecGHGkg_2030","Old_ElecGHGkg_2035","Old_ElecGHGkg_2040","Old_ElecGHGkg_2045","Old_ElecGHGkg_2050","Old_ElecGHGkg_2055","Old_ElecGHGkg_2060")]<-1000* 
  rs_base_all_RR$OldCon*(rs_base_all_RR$base_weight*rs_base_all_RR[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*
  (rs_base_all_RR$Elec_GJ*rs_base_all_RR[,c("GHG_int_2020", "GHG_int_2025","GHG_int_2030","GHG_int_2035","GHG_int_2040","GHG_int_2045","GHG_int_2050","GHG_int_2055","GHG_int_2060")])

rs_base_all_RR[,c("New_ElecGHGkg_2020","New_ElecGHGkg_2025","New_ElecGHGkg_2030","New_ElecGHGkg_2035","New_ElecGHGkg_2040","New_ElecGHGkg_2045","New_ElecGHGkg_2050","New_ElecGHGkg_2055","New_ElecGHGkg_2060")]<-1000* 
  rs_base_all_RR$NewCon*(rs_base_all_RR$base_weight*rs_base_all_RR[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*
  (rs_base_all_RR$Elec_GJ*rs_base_all_RR[,c("GHG_int_2020", "GHG_int_2025","GHG_int_2030","GHG_int_2035","GHG_int_2040","GHG_int_2045","GHG_int_2050","GHG_int_2055","GHG_int_2060")])

# redefine these with new column numbers after introducing the new columns for CFE electricity
OldOilGHG_base_RR<-data.frame(Year=seq(2020,2060,5),OilGHG=colSums(rs_base_all_RR[,232:240])*1e-9)
NewOilGHG_base_RR<-data.frame(Year=seq(2020,2060,5),OilGHG=colSums(rs_base_all_RR[,241:249])*1e-9)
OldGasGHG_base_RR<-data.frame(Year=seq(2020,2060,5),GasGHG=colSums(rs_base_all_RR[,250:258])*1e-9)
NewGasGHG_base_RR<-data.frame(Year=seq(2020,2060,5),GasGHG=colSums(rs_base_all_RR[,259:267])*1e-9)
OldElecGHG_base_RR<-data.frame(Year=seq(2020,2060,5),ElecGHG=colSums(rs_base_all_RR[,268:276])*1e-9)
NewElecGHG_base_RR<-data.frame(Year=seq(2020,2060,5),ElecGHG=colSums(rs_base_all_RR[,277:285])*1e-9)

GHG_base_RR$OldOilGHG<-data.frame(OilGHG=with(select(OldOilGHG_base_RR,Year,OilGHG),spline(Year,OilGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_base_RR$NewOilGHG<-data.frame(OilGHG=with(select(NewOilGHG_base_RR,Year,OilGHG),spline(Year,OilGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_base_RR$OldGasGHG<-data.frame(GasGHG=with(select(OldGasGHG_base_RR,Year,GasGHG),spline(Year,GasGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_base_RR$NewGasGHG<-data.frame(GasGHG=with(select(NewGasGHG_base_RR,Year,GasGHG),spline(Year,GasGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_base_RR$OldElecGHG<-data.frame(ElecGHG=with(select(OldElecGHG_base_RR,Year,ElecGHG),spline(Year,ElecGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_base_RR$NewElecGHG<-data.frame(ElecGHG=with(select(NewElecGHG_base_RR,Year,ElecGHG),spline(Year,ElecGHG,xout = 2020:2060)),method="spline()")[,2]

# repeat for LREC electricity
rs_base_all_RR[,c("Old_ElecGHGkg_2020_LRE","Old_ElecGHGkg_2025_LRE","Old_ElecGHGkg_2030_LRE","Old_ElecGHGkg_2035_LRE","Old_ElecGHGkg_2040_LRE","Old_ElecGHGkg_2045_LRE","Old_ElecGHGkg_2050_LRE","Old_ElecGHGkg_2055_LRE","Old_ElecGHGkg_2060_LRE")]<-1000* 
  rs_base_all_RR$OldCon*(rs_base_all_RR$base_weight*rs_base_all_RR[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*
  (rs_base_all_RR$Elec_GJ*rs_base_all_RR[,c("GHG_int_2020_LRE", "GHG_int_2025_LRE","GHG_int_2030_LRE","GHG_int_2035_LRE","GHG_int_2040_LRE","GHG_int_2045_LRE","GHG_int_2050_LRE","GHG_int_2055_LRE","GHG_int_2060_LRE")])

rs_base_all_RR[,c("New_ElecGHGkg_2020_LRE","New_ElecGHGkg_2025_LRE","New_ElecGHGkg_2030_LRE","New_ElecGHGkg_2035_LRE","New_ElecGHGkg_2040_LRE","New_ElecGHGkg_2045_LRE","New_ElecGHGkg_2050_LRE","New_ElecGHGkg_2055_LRE","New_ElecGHGkg_2060_LRE")]<-1000* 
  rs_base_all_RR$NewCon*(rs_base_all_RR$base_weight*rs_base_all_RR[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*
  (rs_base_all_RR$Elec_GJ*rs_base_all_RR[,c("GHG_int_2020_LRE", "GHG_int_2025_LRE","GHG_int_2030_LRE","GHG_int_2035_LRE","GHG_int_2040_LRE","GHG_int_2045_LRE","GHG_int_2050_LRE","GHG_int_2055_LRE","GHG_int_2060_LRE")])

OldElecGHG_base_RR_LREC<-data.frame(Year=seq(2020,2060,5),ElecGHG=colSums(rs_base_all_RR[,286:294])*1e-9)
NewElecGHG_base_RR_LREC<-data.frame(Year=seq(2020,2060,5),ElecGHG=colSums(rs_base_all_RR[,295:303])*1e-9)

GHG_base_RR_LREC$OldOilGHG<-data.frame(OilGHG=with(select(OldOilGHG_base_RR,Year,OilGHG),spline(Year,OilGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_base_RR_LREC$NewOilGHG<-data.frame(OilGHG=with(select(NewOilGHG_base_RR,Year,OilGHG),spline(Year,OilGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_base_RR_LREC$OldGasGHG<-data.frame(GasGHG=with(select(OldGasGHG_base_RR,Year,GasGHG),spline(Year,GasGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_base_RR_LREC$NewGasGHG<-data.frame(GasGHG=with(select(NewGasGHG_base_RR,Year,GasGHG),spline(Year,GasGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_base_RR_LREC$OldElecGHG<-data.frame(ElecGHG=with(select(OldElecGHG_base_RR_LREC,Year,ElecGHG),spline(Year,ElecGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_base_RR_LREC$NewElecGHG<-data.frame(ElecGHG=with(select(NewElecGHG_base_RR_LREC,Year,ElecGHG),spline(Year,ElecGHG,xout = 2020:2060)),method="spline()")[,2]

# repeat for CFE electricity, this can be slow
rs_base_all_RR[,c("Old_ElecGHGkg_2020_CFE","Old_ElecGHGkg_2025_CFE","Old_ElecGHGkg_2030_CFE","Old_ElecGHGkg_2035_CFE","Old_ElecGHGkg_2040_CFE","Old_ElecGHGkg_2045_CFE","Old_ElecGHGkg_2050_CFE","Old_ElecGHGkg_2055_CFE","Old_ElecGHGkg_2060_CFE")]<-1000* 
  rs_base_all_RR$OldCon*(rs_base_all_RR$base_weight*rs_base_all_RR[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*
  (rs_base_all_RR$Elec_GJ*rs_base_all_RR[,c("GHG_int_2020_CFE", "GHG_int_2025_CFE","GHG_int_2030_CFE","GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")])

rs_base_all_RR[,c("New_ElecGHGkg_2020_CFE","New_ElecGHGkg_2025_CFE","New_ElecGHGkg_2030_CFE","New_ElecGHGkg_2035_CFE","New_ElecGHGkg_2040_CFE","New_ElecGHGkg_2045_CFE","New_ElecGHGkg_2050_CFE","New_ElecGHGkg_2055_CFE","New_ElecGHGkg_2060_CFE")]<-1000* 
  rs_base_all_RR$NewCon*(rs_base_all_RR$base_weight*rs_base_all_RR[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*
  (rs_base_all_RR$Elec_GJ*rs_base_all_RR[,c("GHG_int_2020_CFE", "GHG_int_2025_CFE","GHG_int_2030_CFE","GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")])

OldElecGHG_base_RR_CFE<-data.frame(Year=seq(2020,2060,5),ElecGHG=colSums(rs_base_all_RR[,304:312])*1e-9)
NewElecGHG_base_RR_CFE<-data.frame(Year=seq(2020,2060,5),ElecGHG=colSums(rs_base_all_RR[,313:321])*1e-9)

GHG_base_RR_CFE$OldOilGHG<-data.frame(OilGHG=with(select(OldOilGHG_base_RR,Year,OilGHG),spline(Year,OilGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_base_RR_CFE$NewOilGHG<-data.frame(OilGHG=with(select(NewOilGHG_base_RR,Year,OilGHG),spline(Year,OilGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_base_RR_CFE$OldGasGHG<-data.frame(GasGHG=with(select(OldGasGHG_base_RR,Year,GasGHG),spline(Year,GasGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_base_RR_CFE$NewGasGHG<-data.frame(GasGHG=with(select(NewGasGHG_base_RR,Year,GasGHG),spline(Year,GasGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_base_RR_CFE$OldElecGHG<-data.frame(ElecGHG=with(select(OldElecGHG_base_RR_CFE,Year,ElecGHG),spline(Year,ElecGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_base_RR_CFE$NewElecGHG<-data.frame(ElecGHG=with(select(NewElecGHG_base_RR_CFE,Year,ElecGHG),spline(Year,ElecGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_base_RR_CFE$OldElecGHG[1:6]<-GHG_base_RR_LREC$OldElecGHG[1:6] # 2020:2025 same as LRE
GHG_base_RR_CFE$NewElecGHG[1:6]<-GHG_base_RR_LREC$NewElecGHG[1:6] # 2020:2025 same as LRE
GHG_base_RR_CFE$OldElecGHG[16:41]<-GHG_base_RR_CFE$NewElecGHG[16:41]<-0

# calculation source emissions from fuel for base ER #########
rs_base_all_ER$NewCon<-0
rs_base_all_ER[rs_base_all_ER$Vintage.ACS %in% c("2020s","2030s","2040s","2050s"),]$NewCon<-1
rs_base_all_ER$OldCon<-0
rs_base_all_ER[rs_base_all_ER$NewCon==0,]$OldCon<-1

rs_base_all_ER[,c("Old_OilGHGkg_2020","Old_OilGHGkg_2025","Old_OilGHGkg_2030","Old_OilGHGkg_2035","Old_OilGHGkg_2040","Old_OilGHGkg_2045","Old_OilGHGkg_2050","Old_OilGHGkg_2055","Old_OilGHGkg_2060")]<-1000* 
  rs_base_all_ER$OldCon*(rs_base_all_ER$base_weight*rs_base_all_ER[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*
  (matrix(rep(rs_base_all_ER$Oil_GJ*GHGI_FO,9),nrow(rs_base_all_ER),9)+ matrix(rep(rs_base_all_ER$Prop_GJ*GHGI_LP,9),nrow(rs_base_all_ER),9))

rs_base_all_ER[,c("New_OilGHGkg_2020","New_OilGHGkg_2025","New_OilGHGkg_2030","New_OilGHGkg_2035","New_OilGHGkg_2040","New_OilGHGkg_2045","New_OilGHGkg_2050","New_OilGHGkg_2055","New_OilGHGkg_2060")]<-1000* 
  rs_base_all_ER$NewCon*(rs_base_all_ER$base_weight*rs_base_all_ER[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*
  (matrix(rep(rs_base_all_ER$Oil_GJ*GHGI_FO,9),nrow(rs_base_all_ER),9)+ matrix(rep(rs_base_all_ER$Prop_GJ*GHGI_LP,9),nrow(rs_base_all_ER),9))

rs_base_all_ER[,c("Old_GasGHGkg_2020","Old_GasGHGkg_2025","Old_GasGHGkg_2030","Old_GasGHGkg_2035","Old_GasGHGkg_2040","Old_GasGHGkg_2045","Old_GasGHGkg_2050","Old_GasGHGkg_2055","Old_GasGHGkg_2060")]<-1000* 
  rs_base_all_ER$OldCon*(rs_base_all_ER$base_weight*rs_base_all_ER[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*
  (matrix(rep(rs_base_all_ER$Gas_GJ*GHGI_NG,9),nrow(rs_base_all_ER),9))

rs_base_all_ER[,c("New_GasGHGkg_2020","New_GasGHGkg_2025","New_GasGHGkg_2030","New_GasGHGkg_2035","New_GasGHGkg_2040","New_GasGHGkg_2045","New_GasGHGkg_2050","New_GasGHGkg_2055","New_GasGHGkg_2060")]<-1000* 
  rs_base_all_ER$NewCon*(rs_base_all_ER$base_weight*rs_base_all_ER[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*
  (matrix(rep(rs_base_all_ER$Gas_GJ*GHGI_NG,9),nrow(rs_base_all_ER),9))

rs_base_all_ER[,c("Old_ElecGHGkg_2020","Old_ElecGHGkg_2025","Old_ElecGHGkg_2030","Old_ElecGHGkg_2035","Old_ElecGHGkg_2040","Old_ElecGHGkg_2045","Old_ElecGHGkg_2050","Old_ElecGHGkg_2055","Old_ElecGHGkg_2060")]<-1000* 
  rs_base_all_ER$OldCon*(rs_base_all_ER$base_weight*rs_base_all_ER[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*
  (rs_base_all_ER$Elec_GJ*rs_base_all_ER[,c("GHG_int_2020", "GHG_int_2025","GHG_int_2030","GHG_int_2035","GHG_int_2040","GHG_int_2045","GHG_int_2050","GHG_int_2055","GHG_int_2060")])

rs_base_all_ER[,c("New_ElecGHGkg_2020","New_ElecGHGkg_2025","New_ElecGHGkg_2030","New_ElecGHGkg_2035","New_ElecGHGkg_2040","New_ElecGHGkg_2045","New_ElecGHGkg_2050","New_ElecGHGkg_2055","New_ElecGHGkg_2060")]<-1000* 
  rs_base_all_ER$NewCon*(rs_base_all_ER$base_weight*rs_base_all_ER[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*
  (rs_base_all_ER$Elec_GJ*rs_base_all_ER[,c("GHG_int_2020", "GHG_int_2025","GHG_int_2030","GHG_int_2035","GHG_int_2040","GHG_int_2045","GHG_int_2050","GHG_int_2055","GHG_int_2060")])

# redefine these with new column numbers after introducing the new columns for CFE electricity
OldOilGHG_base_ER<-data.frame(Year=seq(2020,2060,5),OilGHG=colSums(rs_base_all_ER[,232:240])*1e-9)
NewOilGHG_base_ER<-data.frame(Year=seq(2020,2060,5),OilGHG=colSums(rs_base_all_ER[,241:249])*1e-9)
OldGasGHG_base_ER<-data.frame(Year=seq(2020,2060,5),GasGHG=colSums(rs_base_all_ER[,250:258])*1e-9)
NewGasGHG_base_ER<-data.frame(Year=seq(2020,2060,5),GasGHG=colSums(rs_base_all_ER[,259:267])*1e-9)
OldElecGHG_base_ER<-data.frame(Year=seq(2020,2060,5),ElecGHG=colSums(rs_base_all_ER[,268:276])*1e-9)
NewElecGHG_base_ER<-data.frame(Year=seq(2020,2060,5),ElecGHG=colSums(rs_base_all_ER[,277:285])*1e-9)

GHG_base_ER$OldOilGHG<-data.frame(OilGHG=with(select(OldOilGHG_base_ER,Year,OilGHG),spline(Year,OilGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_base_ER$NewOilGHG<-data.frame(OilGHG=with(select(NewOilGHG_base_ER,Year,OilGHG),spline(Year,OilGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_base_ER$OldGasGHG<-data.frame(GasGHG=with(select(OldGasGHG_base_ER,Year,GasGHG),spline(Year,GasGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_base_ER$NewGasGHG<-data.frame(GasGHG=with(select(NewGasGHG_base_ER,Year,GasGHG),spline(Year,GasGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_base_ER$OldElecGHG<-data.frame(ElecGHG=with(select(OldElecGHG_base_ER,Year,ElecGHG),spline(Year,ElecGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_base_ER$NewElecGHG<-data.frame(ElecGHG=with(select(NewElecGHG_base_ER,Year,ElecGHG),spline(Year,ElecGHG,xout = 2020:2060)),method="spline()")[,2]

# repeat for LREC electricity
rs_base_all_ER[,c("Old_ElecGHGkg_2020_LRE","Old_ElecGHGkg_2025_LRE","Old_ElecGHGkg_2030_LRE","Old_ElecGHGkg_2035_LRE","Old_ElecGHGkg_2040_LRE","Old_ElecGHGkg_2045_LRE","Old_ElecGHGkg_2050_LRE","Old_ElecGHGkg_2055_LRE","Old_ElecGHGkg_2060_LRE")]<-1000* 
  rs_base_all_ER$OldCon*(rs_base_all_ER$base_weight*rs_base_all_ER[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*
  (rs_base_all_ER$Elec_GJ*rs_base_all_ER[,c("GHG_int_2020_LRE", "GHG_int_2025_LRE","GHG_int_2030_LRE","GHG_int_2035_LRE","GHG_int_2040_LRE","GHG_int_2045_LRE","GHG_int_2050_LRE","GHG_int_2055_LRE","GHG_int_2060_LRE")])

rs_base_all_ER[,c("New_ElecGHGkg_2020_LRE","New_ElecGHGkg_2025_LRE","New_ElecGHGkg_2030_LRE","New_ElecGHGkg_2035_LRE","New_ElecGHGkg_2040_LRE","New_ElecGHGkg_2045_LRE","New_ElecGHGkg_2050_LRE","New_ElecGHGkg_2055_LRE","New_ElecGHGkg_2060_LRE")]<-1000* 
  rs_base_all_ER$NewCon*(rs_base_all_ER$base_weight*rs_base_all_ER[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*
  (rs_base_all_ER$Elec_GJ*rs_base_all_ER[,c("GHG_int_2020_LRE", "GHG_int_2025_LRE","GHG_int_2030_LRE","GHG_int_2035_LRE","GHG_int_2040_LRE","GHG_int_2045_LRE","GHG_int_2050_LRE","GHG_int_2055_LRE","GHG_int_2060_LRE")])

OldElecGHG_base_ER_LREC<-data.frame(Year=seq(2020,2060,5),ElecGHG=colSums(rs_base_all_ER[,286:294])*1e-9)
NewElecGHG_base_ER_LREC<-data.frame(Year=seq(2020,2060,5),ElecGHG=colSums(rs_base_all_ER[,295:303])*1e-9)

GHG_base_ER_LREC$OldOilGHG<-data.frame(OilGHG=with(select(OldOilGHG_base_ER,Year,OilGHG),spline(Year,OilGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_base_ER_LREC$NewOilGHG<-data.frame(OilGHG=with(select(NewOilGHG_base_ER,Year,OilGHG),spline(Year,OilGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_base_ER_LREC$OldGasGHG<-data.frame(GasGHG=with(select(OldGasGHG_base_ER,Year,GasGHG),spline(Year,GasGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_base_ER_LREC$NewGasGHG<-data.frame(GasGHG=with(select(NewGasGHG_base_ER,Year,GasGHG),spline(Year,GasGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_base_ER_LREC$OldElecGHG<-data.frame(ElecGHG=with(select(OldElecGHG_base_ER_LREC,Year,ElecGHG),spline(Year,ElecGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_base_ER_LREC$NewElecGHG<-data.frame(ElecGHG=with(select(NewElecGHG_base_ER_LREC,Year,ElecGHG),spline(Year,ElecGHG,xout = 2020:2060)),method="spline()")[,2]

# repeat for CFE electricity
rs_base_all_ER[,c("Old_ElecGHGkg_2020_CFE","Old_ElecGHGkg_2025_CFE","Old_ElecGHGkg_2030_CFE","Old_ElecGHGkg_2035_CFE","Old_ElecGHGkg_2040_CFE","Old_ElecGHGkg_2045_CFE","Old_ElecGHGkg_2050_CFE","Old_ElecGHGkg_2055_CFE","Old_ElecGHGkg_2060_CFE")]<-1000* 
  rs_base_all_ER$OldCon*(rs_base_all_ER$base_weight*rs_base_all_ER[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*
  (rs_base_all_ER$Elec_GJ*rs_base_all_ER[,c("GHG_int_2020_CFE", "GHG_int_2025_CFE","GHG_int_2030_CFE","GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")])

rs_base_all_ER[,c("New_ElecGHGkg_2020_CFE","New_ElecGHGkg_2025_CFE","New_ElecGHGkg_2030_CFE","New_ElecGHGkg_2035_CFE","New_ElecGHGkg_2040_CFE","New_ElecGHGkg_2045_CFE","New_ElecGHGkg_2050_CFE","New_ElecGHGkg_2055_CFE","New_ElecGHGkg_2060_CFE")]<-1000* 
  rs_base_all_ER$NewCon*(rs_base_all_ER$base_weight*rs_base_all_ER[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*
  (rs_base_all_ER$Elec_GJ*rs_base_all_ER[,c("GHG_int_2020_CFE", "GHG_int_2025_CFE","GHG_int_2030_CFE","GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")])

OldElecGHG_base_ER_CFE<-data.frame(Year=seq(2020,2060,5),ElecGHG=colSums(rs_base_all_ER[,304:312])*1e-9)
NewElecGHG_base_ER_CFE<-data.frame(Year=seq(2020,2060,5),ElecGHG=colSums(rs_base_all_ER[,313:321])*1e-9)

GHG_base_ER_CFE$OldOilGHG<-data.frame(OilGHG=with(select(OldOilGHG_base_ER,Year,OilGHG),spline(Year,OilGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_base_ER_CFE$NewOilGHG<-data.frame(OilGHG=with(select(NewOilGHG_base_ER,Year,OilGHG),spline(Year,OilGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_base_ER_CFE$OldGasGHG<-data.frame(GasGHG=with(select(OldGasGHG_base_ER,Year,GasGHG),spline(Year,GasGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_base_ER_CFE$NewGasGHG<-data.frame(GasGHG=with(select(NewGasGHG_base_ER,Year,GasGHG),spline(Year,GasGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_base_ER_CFE$OldElecGHG<-data.frame(ElecGHG=with(select(OldElecGHG_base_ER_CFE,Year,ElecGHG),spline(Year,ElecGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_base_ER_CFE$NewElecGHG<-data.frame(ElecGHG=with(select(NewElecGHG_base_ER_CFE,Year,ElecGHG),spline(Year,ElecGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_base_ER_CFE$OldElecGHG[1:6]<-GHG_base_ER_LREC$OldElecGHG[1:6] # 2020:2025 same as LRE
GHG_base_ER_CFE$NewElecGHG[1:6]<-GHG_base_ER_LREC$NewElecGHG[1:6] # 2020:2025 same as LRE
GHG_base_ER_CFE$OldElecGHG[16:41]<-GHG_base_ER_CFE$NewElecGHG[16:41]<-0

# calculation source emissions from fuel for hiDR RR ###########
rs_hiDR_all_RR$NewCon<-0
rs_hiDR_all_RR[rs_hiDR_all_RR$Vintage.ACS %in% c("2020s","2030s","2040s","2050s"),]$NewCon<-1
rs_hiDR_all_RR$OldCon<-0
rs_hiDR_all_RR[rs_hiDR_all_RR$NewCon==0,]$OldCon<-1

rs_hiDR_all_RR[,c("Old_OilGHGkg_2020","Old_OilGHGkg_2025","Old_OilGHGkg_2030","Old_OilGHGkg_2035","Old_OilGHGkg_2040","Old_OilGHGkg_2045","Old_OilGHGkg_2050","Old_OilGHGkg_2055","Old_OilGHGkg_2060")]<-1000* 
  rs_hiDR_all_RR$OldCon*(rs_hiDR_all_RR$base_weight*rs_hiDR_all_RR[,c("whiDR_2020",  "whiDR_2025", "whiDR_2030", "whiDR_2035", "whiDR_2040", "whiDR_2045", "whiDR_2050", "whiDR_2055", "whiDR_2060")])*
  (matrix(rep(rs_hiDR_all_RR$Oil_GJ*GHGI_FO,9),nrow(rs_hiDR_all_RR),9)+ matrix(rep(rs_hiDR_all_RR$Prop_GJ*GHGI_LP,9),nrow(rs_hiDR_all_RR),9))

rs_hiDR_all_RR[,c("New_OilGHGkg_2020","New_OilGHGkg_2025","New_OilGHGkg_2030","New_OilGHGkg_2035","New_OilGHGkg_2040","New_OilGHGkg_2045","New_OilGHGkg_2050","New_OilGHGkg_2055","New_OilGHGkg_2060")]<-1000* 
  rs_hiDR_all_RR$NewCon*(rs_hiDR_all_RR$base_weight*rs_hiDR_all_RR[,c("whiDR_2020",  "whiDR_2025", "whiDR_2030", "whiDR_2035", "whiDR_2040", "whiDR_2045", "whiDR_2050", "whiDR_2055", "whiDR_2060")])*
  (matrix(rep(rs_hiDR_all_RR$Oil_GJ*GHGI_FO,9),nrow(rs_hiDR_all_RR),9)+ matrix(rep(rs_hiDR_all_RR$Prop_GJ*GHGI_LP,9),nrow(rs_hiDR_all_RR),9))

rs_hiDR_all_RR[,c("Old_GasGHGkg_2020","Old_GasGHGkg_2025","Old_GasGHGkg_2030","Old_GasGHGkg_2035","Old_GasGHGkg_2040","Old_GasGHGkg_2045","Old_GasGHGkg_2050","Old_GasGHGkg_2055","Old_GasGHGkg_2060")]<-1000* 
  rs_hiDR_all_RR$OldCon*(rs_hiDR_all_RR$base_weight*rs_hiDR_all_RR[,c("whiDR_2020",  "whiDR_2025", "whiDR_2030", "whiDR_2035", "whiDR_2040", "whiDR_2045", "whiDR_2050", "whiDR_2055", "whiDR_2060")])*
  (matrix(rep(rs_hiDR_all_RR$Gas_GJ*GHGI_NG,9),nrow(rs_hiDR_all_RR),9))

rs_hiDR_all_RR[,c("New_GasGHGkg_2020","New_GasGHGkg_2025","New_GasGHGkg_2030","New_GasGHGkg_2035","New_GasGHGkg_2040","New_GasGHGkg_2045","New_GasGHGkg_2050","New_GasGHGkg_2055","New_GasGHGkg_2060")]<-1000* 
  rs_hiDR_all_RR$NewCon*(rs_hiDR_all_RR$base_weight*rs_hiDR_all_RR[,c("whiDR_2020",  "whiDR_2025", "whiDR_2030", "whiDR_2035", "whiDR_2040", "whiDR_2045", "whiDR_2050", "whiDR_2055", "whiDR_2060")])*
  (matrix(rep(rs_hiDR_all_RR$Gas_GJ*GHGI_NG,9),nrow(rs_hiDR_all_RR),9))

rs_hiDR_all_RR[,c("Old_ElecGHGkg_2020","Old_ElecGHGkg_2025","Old_ElecGHGkg_2030","Old_ElecGHGkg_2035","Old_ElecGHGkg_2040","Old_ElecGHGkg_2045","Old_ElecGHGkg_2050","Old_ElecGHGkg_2055","Old_ElecGHGkg_2060")]<-1000* 
  rs_hiDR_all_RR$OldCon*(rs_hiDR_all_RR$base_weight*rs_hiDR_all_RR[,c("whiDR_2020",  "whiDR_2025", "whiDR_2030", "whiDR_2035", "whiDR_2040", "whiDR_2045", "whiDR_2050", "whiDR_2055", "whiDR_2060")])*
  (rs_hiDR_all_RR$Elec_GJ*rs_hiDR_all_RR[,c("GHG_int_2020", "GHG_int_2025","GHG_int_2030","GHG_int_2035","GHG_int_2040","GHG_int_2045","GHG_int_2050","GHG_int_2055","GHG_int_2060")])

rs_hiDR_all_RR[,c("New_ElecGHGkg_2020","New_ElecGHGkg_2025","New_ElecGHGkg_2030","New_ElecGHGkg_2035","New_ElecGHGkg_2040","New_ElecGHGkg_2045","New_ElecGHGkg_2050","New_ElecGHGkg_2055","New_ElecGHGkg_2060")]<-1000* 
  rs_hiDR_all_RR$NewCon*(rs_hiDR_all_RR$base_weight*rs_hiDR_all_RR[,c("whiDR_2020",  "whiDR_2025", "whiDR_2030", "whiDR_2035", "whiDR_2040", "whiDR_2045", "whiDR_2050", "whiDR_2055", "whiDR_2060")])*
  (rs_hiDR_all_RR$Elec_GJ*rs_hiDR_all_RR[,c("GHG_int_2020", "GHG_int_2025","GHG_int_2030","GHG_int_2035","GHG_int_2040","GHG_int_2045","GHG_int_2050","GHG_int_2055","GHG_int_2060")])

OldOilGHG_hiDR_RR<-data.frame(Year=seq(2020,2060,5),OilGHG=colSums(rs_hiDR_all_RR[,232:240])*1e-9)
NewOilGHG_hiDR_RR<-data.frame(Year=seq(2020,2060,5),OilGHG=colSums(rs_hiDR_all_RR[,241:249])*1e-9)
OldGasGHG_hiDR_RR<-data.frame(Year=seq(2020,2060,5),GasGHG=colSums(rs_hiDR_all_RR[,250:258])*1e-9)
NewGasGHG_hiDR_RR<-data.frame(Year=seq(2020,2060,5),GasGHG=colSums(rs_hiDR_all_RR[,259:267])*1e-9)
OldElecGHG_hiDR_RR<-data.frame(Year=seq(2020,2060,5),ElecGHG=colSums(rs_hiDR_all_RR[,268:276])*1e-9)
NewElecGHG_hiDR_RR<-data.frame(Year=seq(2020,2060,5),ElecGHG=colSums(rs_hiDR_all_RR[,277:285])*1e-9)

GHG_hiDR_RR$OldOilGHG<-data.frame(OilGHG=with(select(OldOilGHG_hiDR_RR,Year,OilGHG),spline(Year,OilGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_hiDR_RR$NewOilGHG<-data.frame(OilGHG=with(select(NewOilGHG_hiDR_RR,Year,OilGHG),spline(Year,OilGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_hiDR_RR$OldGasGHG<-data.frame(GasGHG=with(select(OldGasGHG_hiDR_RR,Year,GasGHG),spline(Year,GasGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_hiDR_RR$NewGasGHG<-data.frame(GasGHG=with(select(NewGasGHG_hiDR_RR,Year,GasGHG),spline(Year,GasGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_hiDR_RR$OldElecGHG<-data.frame(ElecGHG=with(select(OldElecGHG_hiDR_RR,Year,ElecGHG),spline(Year,ElecGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_hiDR_RR$NewElecGHG<-data.frame(ElecGHG=with(select(NewElecGHG_hiDR_RR,Year,ElecGHG),spline(Year,ElecGHG,xout = 2020:2060)),method="spline()")[,2]

# repeat for LREC electricity
rs_hiDR_all_RR[,c("Old_ElecGHGkg_2020_LRE","Old_ElecGHGkg_2025_LRE","Old_ElecGHGkg_2030_LRE","Old_ElecGHGkg_2035_LRE","Old_ElecGHGkg_2040_LRE","Old_ElecGHGkg_2045_LRE","Old_ElecGHGkg_2050_LRE","Old_ElecGHGkg_2055_LRE","Old_ElecGHGkg_2060_LRE")]<-1000* 
  rs_hiDR_all_RR$OldCon*(rs_hiDR_all_RR$base_weight*rs_hiDR_all_RR[,c("whiDR_2020",  "whiDR_2025", "whiDR_2030", "whiDR_2035", "whiDR_2040", "whiDR_2045", "whiDR_2050", "whiDR_2055", "whiDR_2060")])*
  (rs_hiDR_all_RR$Elec_GJ*rs_hiDR_all_RR[,c("GHG_int_2020_LRE", "GHG_int_2025_LRE","GHG_int_2030_LRE","GHG_int_2035_LRE","GHG_int_2040_LRE","GHG_int_2045_LRE","GHG_int_2050_LRE","GHG_int_2055_LRE","GHG_int_2060_LRE")])

rs_hiDR_all_RR[,c("New_ElecGHGkg_2020_LRE","New_ElecGHGkg_2025_LRE","New_ElecGHGkg_2030_LRE","New_ElecGHGkg_2035_LRE","New_ElecGHGkg_2040_LRE","New_ElecGHGkg_2045_LRE","New_ElecGHGkg_2050_LRE","New_ElecGHGkg_2055_LRE","New_ElecGHGkg_2060_LRE")]<-1000* 
  rs_hiDR_all_RR$NewCon*(rs_hiDR_all_RR$base_weight*rs_hiDR_all_RR[,c("whiDR_2020",  "whiDR_2025", "whiDR_2030", "whiDR_2035", "whiDR_2040", "whiDR_2045", "whiDR_2050", "whiDR_2055", "whiDR_2060")])*
  (rs_hiDR_all_RR$Elec_GJ*rs_hiDR_all_RR[,c("GHG_int_2020_LRE", "GHG_int_2025_LRE","GHG_int_2030_LRE","GHG_int_2035_LRE","GHG_int_2040_LRE","GHG_int_2045_LRE","GHG_int_2050_LRE","GHG_int_2055_LRE","GHG_int_2060_LRE")])

OldElecGHG_hiDR_RR_LREC<-data.frame(Year=seq(2020,2060,5),ElecGHG=colSums(rs_hiDR_all_RR[,286:294])*1e-9)
NewElecGHG_hiDR_RR_LREC<-data.frame(Year=seq(2020,2060,5),ElecGHG=colSums(rs_hiDR_all_RR[,295:303])*1e-9)

GHG_hiDR_RR_LREC$OldOilGHG<-data.frame(OilGHG=with(select(OldOilGHG_hiDR_RR,Year,OilGHG),spline(Year,OilGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_hiDR_RR_LREC$NewOilGHG<-data.frame(OilGHG=with(select(NewOilGHG_hiDR_RR,Year,OilGHG),spline(Year,OilGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_hiDR_RR_LREC$OldGasGHG<-data.frame(GasGHG=with(select(OldGasGHG_hiDR_RR,Year,GasGHG),spline(Year,GasGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_hiDR_RR_LREC$NewGasGHG<-data.frame(GasGHG=with(select(NewGasGHG_hiDR_RR,Year,GasGHG),spline(Year,GasGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_hiDR_RR_LREC$OldElecGHG<-data.frame(ElecGHG=with(select(OldElecGHG_hiDR_RR_LREC,Year,ElecGHG),spline(Year,ElecGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_hiDR_RR_LREC$NewElecGHG<-data.frame(ElecGHG=with(select(NewElecGHG_hiDR_RR_LREC,Year,ElecGHG),spline(Year,ElecGHG,xout = 2020:2060)),method="spline()")[,2]

# repeat for CFE electricity
rs_hiDR_all_RR[,c("Old_ElecGHGkg_2020_CFE","Old_ElecGHGkg_2025_CFE","Old_ElecGHGkg_2030_CFE","Old_ElecGHGkg_2035_CFE","Old_ElecGHGkg_2040_CFE","Old_ElecGHGkg_2045_CFE","Old_ElecGHGkg_2050_CFE","Old_ElecGHGkg_2055_CFE","Old_ElecGHGkg_2060_CFE")]<-1000* 
  rs_hiDR_all_RR$OldCon*(rs_hiDR_all_RR$base_weight*rs_hiDR_all_RR[,c("whiDR_2020",  "whiDR_2025", "whiDR_2030", "whiDR_2035", "whiDR_2040", "whiDR_2045", "whiDR_2050", "whiDR_2055", "whiDR_2060")])*
  (rs_hiDR_all_RR$Elec_GJ*rs_hiDR_all_RR[,c("GHG_int_2020_CFE", "GHG_int_2025_CFE","GHG_int_2030_CFE","GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")])

rs_hiDR_all_RR[,c("New_ElecGHGkg_2020_CFE","New_ElecGHGkg_2025_CFE","New_ElecGHGkg_2030_CFE","New_ElecGHGkg_2035_CFE","New_ElecGHGkg_2040_CFE","New_ElecGHGkg_2045_CFE","New_ElecGHGkg_2050_CFE","New_ElecGHGkg_2055_CFE","New_ElecGHGkg_2060_CFE")]<-1000* 
  rs_hiDR_all_RR$NewCon*(rs_hiDR_all_RR$base_weight*rs_hiDR_all_RR[,c("whiDR_2020",  "whiDR_2025", "whiDR_2030", "whiDR_2035", "whiDR_2040", "whiDR_2045", "whiDR_2050", "whiDR_2055", "whiDR_2060")])*
  (rs_hiDR_all_RR$Elec_GJ*rs_hiDR_all_RR[,c("GHG_int_2020_CFE", "GHG_int_2025_CFE","GHG_int_2030_CFE","GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")])

OldElecGHG_hiDR_RR_CFE<-data.frame(Year=seq(2020,2060,5),ElecGHG=colSums(rs_hiDR_all_RR[,304:312])*1e-9)
NewElecGHG_hiDR_RR_CFE<-data.frame(Year=seq(2020,2060,5),ElecGHG=colSums(rs_hiDR_all_RR[,313:321])*1e-9)

GHG_hiDR_RR_CFE$OldOilGHG<-data.frame(OilGHG=with(select(OldOilGHG_hiDR_RR,Year,OilGHG),spline(Year,OilGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_hiDR_RR_CFE$NewOilGHG<-data.frame(OilGHG=with(select(NewOilGHG_hiDR_RR,Year,OilGHG),spline(Year,OilGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_hiDR_RR_CFE$OldGasGHG<-data.frame(GasGHG=with(select(OldGasGHG_hiDR_RR,Year,GasGHG),spline(Year,GasGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_hiDR_RR_CFE$NewGasGHG<-data.frame(GasGHG=with(select(NewGasGHG_hiDR_RR,Year,GasGHG),spline(Year,GasGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_hiDR_RR_CFE$OldElecGHG<-data.frame(ElecGHG=with(select(OldElecGHG_hiDR_RR_CFE,Year,ElecGHG),spline(Year,ElecGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_hiDR_RR_CFE$NewElecGHG<-data.frame(ElecGHG=with(select(NewElecGHG_hiDR_RR_CFE,Year,ElecGHG),spline(Year,ElecGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_hiDR_RR_CFE$OldElecGHG[1:6]<-GHG_hiDR_RR_LREC$OldElecGHG[1:6] # 2020:2025 same as LRE
GHG_hiDR_RR_CFE$NewElecGHG[1:6]<-GHG_hiDR_RR_LREC$NewElecGHG[1:6] # 2020:2025 same as LRE
GHG_hiDR_RR_CFE$OldElecGHG[16:41]<-GHG_hiDR_RR_CFE$NewElecGHG[16:41]<-0

# calculate relative changes in emissiosn from difference sources, can skip past this bit ###### until defining stock segments
# GHG_base_RR$EmGHG_pc<-GHG_base_RR$EmGHG/GHG_base_RR$EmGHG[1]
# GHG_base_RR$TotGHG_pc<-GHG_base_RR$TotGHG/GHG_base_RR$TotGHG[1]
# GHG_base_RR$OilGHG_pc<-rowSums(GHG_base_RR[,c("OldOilGHG","NewOilGHG")])/GHG_base_RR$OldOilGHG[1]
# GHG_base_RR$GasGHG_pc<-rowSums(GHG_base_RR[,c("OldGasGHG","NewGasGHG")])/GHG_base_RR$OldGasGHG[1]
# GHG_base_RR$ElecGHG_pc<-rowSums(GHG_base_RR[,c("OldElecGHG","NewElecGHG")])/GHG_base_RR$OldElecGHG[1]
# GHG_base_RR$EmGHG_pc_tot<-GHG_base_RR$EmGHG/GHG_base_RR$TotGHG
# 
# GHG_base_RR_LREC$EmGHG_pc<-GHG_base_RR_LREC$EmGHG/GHG_base_RR_LREC$EmGHG[1]
# GHG_base_RR_LREC$TotGHG_pc<-GHG_base_RR_LREC$TotGHG/GHG_base_RR_LREC$TotGHG[1]
# GHG_base_RR_LREC$OilGHG_pc<-rowSums(GHG_base_RR_LREC[,c("OldOilGHG","NewOilGHG")])/GHG_base_RR_LREC$OldOilGHG[1]
# GHG_base_RR_LREC$GasGHG_pc<-rowSums(GHG_base_RR_LREC[,c("OldGasGHG","NewGasGHG")])/GHG_base_RR_LREC$OldGasGHG[1]
# GHG_base_RR_LREC$ElecGHG_pc<-rowSums(GHG_base_RR_LREC[,c("OldElecGHG","NewElecGHG")])/GHG_base_RR_LREC$OldElecGHG[1]
# GHG_base_RR_LREC$EmGHG_pc_tot<-GHG_base_RR_LREC$EmGHG/GHG_base_RR_LREC$TotGHG
# 
# GHG_hiDR_RR$EmGHG_pc<-GHG_hiDR_RR$EmGHG/GHG_hiDR_RR$EmGHG[1]
# GHG_hiDR_RR$TotGHG_pc<-GHG_hiDR_RR$TotGHG/GHG_hiDR_RR$TotGHG[1]
# GHG_hiDR_RR$OilGHG_pc<-rowSums(GHG_hiDR_RR[,c("OldOilGHG","NewOilGHG")])/GHG_hiDR_RR$OldOilGHG[1]
# GHG_hiDR_RR$GasGHG_pc<-rowSums(GHG_hiDR_RR[,c("OldGasGHG","NewGasGHG")])/GHG_hiDR_RR$OldGasGHG[1]
# GHG_hiDR_RR$ElecGHG_pc<-rowSums(GHG_hiDR_RR[,c("OldElecGHG","NewElecGHG")])/GHG_hiDR_RR$OldElecGHG[1]
# GHG_hiDR_RR$EmGHG_pc_tot<-GHG_hiDR_RR$EmGHG/GHG_hiDR_RR$TotGHG
# 
# GHG_hiDR_RR_LREC$EmGHG_pc<-GHG_hiDR_RR_LREC$EmGHG/GHG_hiDR_RR_LREC$EmGHG[1]
# GHG_hiDR_RR_LREC$TotGHG_pc<-GHG_hiDR_RR_LREC$TotGHG/GHG_hiDR_RR_LREC$TotGHG[1]
# GHG_hiDR_RR_LREC$OilGHG_pc<-rowSums(GHG_hiDR_RR_LREC[,c("OldOilGHG","NewOilGHG")])/GHG_hiDR_RR_LREC$OldOilGHG[1]
# GHG_hiDR_RR_LREC$GasGHG_pc<-rowSums(GHG_hiDR_RR_LREC[,c("OldGasGHG","NewGasGHG")])/GHG_hiDR_RR_LREC$OldGasGHG[1]
# GHG_hiDR_RR_LREC$ElecGHG_pc<-rowSums(GHG_hiDR_RR_LREC[,c("OldElecGHG","NewElecGHG")])/GHG_hiDR_RR_LREC$OldElecGHG[1]
# GHG_hiDR_RR_LREC$EmGHG_pc_tot<-GHG_hiDR_RR_LREC$EmGHG/GHG_hiDR_RR_LREC$TotGHG

rs_base_all_RR$Type3<-"MF"
rs_base_all_RR[rs_base_all_RR$Geometry.Building.Type.RECS=="Single-Family Attached" | rs_base_all_RR$Geometry.Building.Type.RECS=="Single-Family Detached",]$Type3<-"SF"
rs_base_all_RR[rs_base_all_RR$Geometry.Building.Type.RECS=="Mobile Home",]$Type3<-"MH"

EI_base_RR20<-1000*tapply(rs_base_all_RR$Tot_GJ*rs_base_all_RR$base_weight*rs_base_all_RR$wbase_2020,list(rs_base_all_RR$Type3,rs_base_all_RR$Vintage),sum)/
  (tapply(rs_base_all_RR$floor_area_lighting_ft_2*rs_base_all_RR$base_weight*rs_base_all_RR$wbase_2020,list(rs_base_all_RR$Type3,rs_base_all_RR$Vintage),sum)/10.765)
EI_base_RR60<-1000*tapply(rs_base_all_RR$Tot_GJ*rs_base_all_RR$base_weight*rs_base_all_RR$wbase_2060,list(rs_base_all_RR$Type3,rs_base_all_RR$Vintage),sum)/
  (tapply(rs_base_all_RR$floor_area_lighting_ft_2*rs_base_all_RR$base_weight*rs_base_all_RR$wbase_2060,list(rs_base_all_RR$Type3,rs_base_all_RR$Vintage),sum)/10.765)

rs_base_all_AR$Type3<-"MF"
rs_base_all_AR[rs_base_all_AR$Geometry.Building.Type.RECS=="Single-Family Attached" | rs_base_all_AR$Geometry.Building.Type.RECS=="Single-Family Detached",]$Type3<-"SF"
rs_base_all_AR[rs_base_all_AR$Geometry.Building.Type.RECS=="Mobile Home",]$Type3<-"MH"

rs_base_all_AR$NewCon<-0
rs_base_all_AR[rs_base_all_AR$Vintage.ACS %in% c("2020s","2030s","2040s","2050s"),]$NewCon<-1
rs_base_all_AR$OldCon<-0
rs_base_all_AR[rs_base_all_AR$NewCon==0,]$OldCon<-1

EI_base_AR60<-1000*tapply(rs_base_all_AR$Tot_GJ*rs_base_all_AR$base_weight*rs_base_all_AR$wbase_2060,list(rs_base_all_AR$Type3,rs_base_all_AR$Vintage),sum)/
  (tapply(rs_base_all_AR$floor_area_lighting_ft_2*rs_base_all_AR$base_weight*rs_base_all_AR$wbase_2060,list(rs_base_all_AR$Type3,rs_base_all_AR$Vintage),sum)/10.765)

rs_base_all_ER$Type3<-"MF"
rs_base_all_ER[rs_base_all_ER$Geometry.Building.Type.RECS=="Single-Family Attached" | rs_base_all_ER$Geometry.Building.Type.RECS=="Single-Family Detached",]$Type3<-"SF"
rs_base_all_ER[rs_base_all_ER$Geometry.Building.Type.RECS=="Mobile Home",]$Type3<-"MH"

rs_base_all_ER$NewCon<-0
rs_base_all_ER[rs_base_all_ER$Vintage.ACS %in% c("2020s","2030s","2040s","2050s"),]$NewCon<-1
rs_base_all_ER$OldCon<-0
rs_base_all_ER[rs_base_all_ER$NewCon==0,]$OldCon<-1

EI_base_ER60<-1000*tapply(rs_base_all_ER$Tot_GJ*rs_base_all_ER$base_weight*rs_base_all_ER$wbase_2060,list(rs_base_all_ER$Type3,rs_base_all_ER$Vintage),sum)/
  (tapply(rs_base_all_ER$floor_area_lighting_ft_2*rs_base_all_ER$base_weight*rs_base_all_ER$wbase_2060,list(rs_base_all_ER$Type3,rs_base_all_ER$Vintage),sum)/10.765)

fn<-"../Supplementary_results_new/EI.xlsx"
wb<-createWorkbook()
addWorksheet(wb, "base_RR_2020")
writeData(wb, "base_RR_2020", EI_base_RR20)
addWorksheet(wb, "base_RR_2060")
writeData(wb, "base_RR_2060", EI_base_RR60)
addWorksheet(wb, "base_AR_2060")
writeData(wb, "base_AR_2060", EI_base_AR60)
addWorksheet(wb, "base_ER_2060")
writeData(wb, "base_ER_2060", EI_base_ER60)

saveWorkbook(wb,file = fn,overwrite = TRUE)

m2_base_RR<-tapply(rs_base_all_RR$Tot_MJ_m2,list(rs_base_all_RR$Vintage,rs_base_all_RR$Year,rs_base_all_RR$Type3),mean)

# this object hasn't been created?
# write.csv(EI_base_RR,file = "../Supplementary_results_new/EI_base_RR.csv")

# total energy per type and vintage in 2060, in PJ
round(tapply(rs_base_all_RR$Tot_GJ*rs_base_all_RR$base_weight*rs_base_all_RR$wbase_2060,list(rs_base_all_RR$Type3,rs_base_all_RR$Vintage),sum)*1e-6)
# total GHG by type and vintage in 2060, in MTon
round(tapply(rs_base_all_RR$EnGHGkg_base_2060,list(rs_base_all_RR$Type3,rs_base_all_RR$Vintage),sum)*1e-9,2)

# come back here, define stock segments
rs_base_all_RR$Segment<-"Old_Renovated"
rs_base_all_RR[rs_base_all_RR$Vintage %in% c("2020s","2030s","2040s","2050s"),]$Segment<-"New"
rs_base_all_RR[!rs_base_all_RR$Segment=="New" & rs_base_all_RR$Year==2020,]$Segment<-"Old_Unrenovated"

stock_seg_RR<-melt(data.frame(Year=seq(2020,2060,5),New=colSums((rs_base_all_RR[rs_base_all_RR$Segment=="New",]$base_weight*rs_base_all_RR[rs_base_all_RR$Segment=="New",
                                            c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])),
                       Old_Renovated=colSums((rs_base_all_RR[rs_base_all_RR$Segment=="Old_Renovated",]$base_weight*rs_base_all_RR[rs_base_all_RR$Segment=="Old_Renovated",
                                            c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])),
                       Old_Unrenovated=colSums((rs_base_all_RR[rs_base_all_RR$Segment=="Old_Unrenovated",]$base_weight*rs_base_all_RR[rs_base_all_RR$Segment=="Old_Unrenovated",
                                            c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")]))),id.vars='Year')
names(stock_seg_RR)[2]<-"Housing Segment"
windows(width=8,height = 6.5)
ggplot(stock_seg_RR,aes(Year,1E-6*value,fill=`Housing Segment`)) + geom_area()  + 
  labs(title ="a) Stock evolution with Regular Renovation",y="Million Housing Units") + theme_bw() + 
  scale_fill_brewer(palette="Set2")  +
  theme(axis.text=element_text(size=11),axis.title=element_text(size=12,face = "bold"),plot.title = element_text(size = 12),legend.key.width = unit(1,'cm'))

rs_base_all_AR$Segment<-"Old_Renovated"
rs_base_all_AR[rs_base_all_AR$Vintage %in% c("2020s","2030s","2040s","2050s"),]$Segment<-"New"
rs_base_all_AR[!rs_base_all_AR$Segment=="New" & rs_base_all_AR$Year==2020,]$Segment<-"Old_Unrenovated"

stock_seg_AR<-melt(data.frame(Year=seq(2020,2060,5),New=colSums((rs_base_all_AR[rs_base_all_AR$Segment=="New",]$base_weight*rs_base_all_AR[rs_base_all_AR$Segment=="New",
                                                                                                                                           c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])),
                              Old_Renovated=colSums((rs_base_all_AR[rs_base_all_AR$Segment=="Old_Renovated",]$base_weight*rs_base_all_AR[rs_base_all_AR$Segment=="Old_Renovated",
                                                                                                                                   c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])),
                              Old_Unrenovated=colSums((rs_base_all_AR[rs_base_all_AR$Segment=="Old_Unrenovated",]$base_weight*rs_base_all_AR[rs_base_all_AR$Segment=="Old_Unrenovated",
                                                                                                                                       c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")]))),id.vars='Year')
names(stock_seg_AR)[2]<-"Housing Segment"
windows(width=8,height = 6.5)
ggplot(stock_seg_AR,aes(Year,1E-6*value,fill=`Housing Segment`)) + geom_area()  + 
  labs(title ="b) Stock evolution with Advanced Renovation",y="Million Housing Units") + theme_bw() + 
  scale_fill_brewer(palette="Set2")  +
  theme(axis.text=element_text(size=11),axis.title=element_text(size=12,face = "bold"),plot.title = element_text(size = 12),legend.key.width = unit(1,'cm'))

rs_base_all_ER$Segment<-"Old_Renovated"
rs_base_all_ER[rs_base_all_ER$Vintage %in% c("2020s","2030s","2040s","2050s"),]$Segment<-"New"
rs_base_all_ER[!rs_base_all_ER$Segment=="New" & rs_base_all_ER$Year==2020,]$Segment<-"Old_Unrenovated"

# Energy intensity in new, renovated, and unrenovated housing by year. Can be done with tapply instead if we make columns for Tot_m2_2020, Tot_m2_2025, etc., as done for Tot_GJ and EnGHG etc.
EI_RR_New<-1000*colSums(rs_base_all_RR[rs_base_all_RR$Segment=="New",167:175])/
  (colSums(rs_base_all_RR[rs_base_all_RR$Segment=="New",]$base_weight*rs_base_all_RR[rs_base_all_RR$Segment=="New",]$floor_area_lighting_ft_2*
             rs_base_all_RR[rs_base_all_RR$Segment=="New",37:45])/10.765)

EI_RR_OU<-1000*colSums(rs_base_all_RR[rs_base_all_RR$Segment=="Old_Unrenovated",167:175])/
  (colSums(rs_base_all_RR[rs_base_all_RR$Segment=="Old_Unrenovated",]$base_weight*rs_base_all_RR[rs_base_all_RR$Segment=="Old_Unrenovated",]$floor_area_lighting_ft_2*
             rs_base_all_RR[rs_base_all_RR$Segment=="Old_Unrenovated",37:45])/10.765)

EI_RR_OR<-1000*colSums(rs_base_all_RR[rs_base_all_RR$Segment=="Old_Renovated",167:175])/
  (colSums(rs_base_all_RR[rs_base_all_RR$Segment=="Old_Renovated",]$base_weight*rs_base_all_RR[rs_base_all_RR$Segment=="Old_Renovated",]$floor_area_lighting_ft_2*
             rs_base_all_RR[rs_base_all_RR$Segment=="Old_Renovated",37:45])/10.765)

EI_AR_New<-1000*colSums(rs_base_all_AR[rs_base_all_AR$Segment=="New",167:175])/
  (colSums(rs_base_all_AR[rs_base_all_AR$Segment=="New",]$base_weight*rs_base_all_AR[rs_base_all_AR$Segment=="New",]$floor_area_lighting_ft_2*
             rs_base_all_AR[rs_base_all_AR$Segment=="New",37:45])/10.765)

EI_AR_OU<-1000*colSums(rs_base_all_AR[rs_base_all_AR$Segment=="Old_Unrenovated",167:175])/
  (colSums(rs_base_all_AR[rs_base_all_AR$Segment=="Old_Unrenovated",]$base_weight*rs_base_all_AR[rs_base_all_AR$Segment=="Old_Unrenovated",]$floor_area_lighting_ft_2*
             rs_base_all_AR[rs_base_all_AR$Segment=="Old_Unrenovated",37:45])/10.765)

EI_AR_OR<-1000*colSums(rs_base_all_AR[rs_base_all_AR$Segment=="Old_Renovated",167:175])/
  (colSums(rs_base_all_AR[rs_base_all_AR$Segment=="Old_Renovated",]$base_weight*rs_base_all_AR[rs_base_all_AR$Segment=="Old_Renovated",]$floor_area_lighting_ft_2*
             rs_base_all_AR[rs_base_all_AR$Segment=="Old_Renovated",37:45])/10.765)

EI_ER_New<-1000*colSums(rs_base_all_ER[rs_base_all_ER$Segment=="New",167:175])/
  (colSums(rs_base_all_ER[rs_base_all_ER$Segment=="New",]$base_weight*rs_base_all_ER[rs_base_all_ER$Segment=="New",]$floor_area_lighting_ft_2*
             rs_base_all_ER[rs_base_all_ER$Segment=="New",37:45])/10.765)

EI_ER_OU<-1000*colSums(rs_base_all_ER[rs_base_all_ER$Segment=="Old_Unrenovated",167:175])/
  (colSums(rs_base_all_ER[rs_base_all_ER$Segment=="Old_Unrenovated",]$base_weight*rs_base_all_ER[rs_base_all_ER$Segment=="Old_Unrenovated",]$floor_area_lighting_ft_2*
             rs_base_all_ER[rs_base_all_ER$Segment=="Old_Unrenovated",37:45])/10.765)

EI_ER_OR<-1000*colSums(rs_base_all_ER[rs_base_all_ER$Segment=="Old_Renovated",167:175])/
  (colSums(rs_base_all_ER[rs_base_all_ER$Segment=="Old_Renovated",]$base_weight*rs_base_all_ER[rs_base_all_ER$Segment=="Old_Renovated",]$floor_area_lighting_ft_2*
             rs_base_all_ER[rs_base_all_ER$Segment=="Old_Renovated",37:45])/10.765)

EI_seg<-data.frame(Year=seq(2020,2060,5),New=EI_RR_New,RR_OldUnRen=EI_RR_OU,RR_OldRen=EI_RR_OR,
                   AR_OldUnRen=EI_AR_OU,AR_OldRen=EI_AR_OR,
                   ER_OldUnRen=EI_ER_OU,ER_OldRen=EI_ER_OR)

write.csv(EI_seg,file="../Supplementary_results_new/EI_seg_base.csv")

# make graphs of housing stock characteristics using dplyr pipe ##########
rs_base_all_RR[,c("Housing Units 2020","Housing Units 2025","Housing Units 2030","Housing Units 2035","Housing Units 2040","Housing Units 2045","Housing Units 2050","Housing Units 2055","Housing Units 2060")]<-
  rs_base_all_RR$base_weight*rs_base_all_RR[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")]

rs_base_all_AR[,c("Housing Units 2020","Housing Units 2025","Housing Units 2030","Housing Units 2035","Housing Units 2040","Housing Units 2045","Housing Units 2050","Housing Units 2055","Housing Units 2060")]<-
  rs_base_all_AR$base_weight*rs_base_all_AR[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")]

rs_base_all_ER[,c("Housing Units 2020","Housing Units 2025","Housing Units 2030","Housing Units 2035","Housing Units 2040","Housing Units 2045","Housing Units 2050","Housing Units 2055","Housing Units 2060")]<-
  rs_base_all_ER$base_weight*rs_base_all_ER[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")]

# here calculate future emissions without renovation or reduction in GHG intensity of electricity
tapply(rs_base_all_RR$EnGHGkg_base_2020,rs_base_all_RR$Segment,sum)
tapply(rs_base_all_RR$`Housing Units 2020`,rs_base_all_RR$Segment,sum)
st_dec<-rs_base_all_RR %>% group_by(Segment) %>% summarise(across(starts_with("Housing Units"),sum))
# emissions from <20 stock assuming no renovations or grid decarbonization
Old_NR_G20<-1e-9*tapply(rs_base_all_RR$EnGHGkg_base_2020,rs_base_all_RR$Segment,sum)[3]*colSums(st_dec[2:3,2:10])/122516868
# emissions from new housing assuming no grid decarbonization
rs_base_NC<-rs_base_all_RR[rs_base_all_RR$Building>180000,]

rs_base_NC[,c("EnGHGkg_G20_2020","EnGHGkg_G20_2025","EnGHGkg_G20_2030","EnGHGkg_G20_2035","EnGHGkg_G20_2040","EnGHGkg_G20_2045","EnGHGkg_G20_2050","EnGHGkg_G20_2055","EnGHGkg_G20_2060")]<-1000* 
  (rs_base_NC$base_weight*rs_base_NC[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*
  (rs_base_NC$Elec_GJ*rs_base_NC[,c("GHG_int_2020", "GHG_int_2020","GHG_int_2020","GHG_int_2020","GHG_int_2020","GHG_int_2020","GHG_int_2020","GHG_int_2020","GHG_int_2020")]+
     matrix(rep(rs_base_NC$Gas_GJ*GHGI_NG,9),nrow(rs_base_NC),9)+ matrix(rep(rs_base_NC$Oil_GJ*GHGI_FO,9),nrow(rs_base_NC),9)+ matrix(rep(rs_base_NC$Prop_GJ*GHGI_LP,9),nrow(rs_base_NC),9))

# check these column numbers very well
# emissions from new housing with no change in grid intensity
New_G20<-colSums(rs_base_NC[,c("EnGHGkg_G20_2020","EnGHGkg_G20_2025","EnGHGkg_G20_2030","EnGHGkg_G20_2035","EnGHGkg_G20_2040","EnGHGkg_G20_2045","EnGHGkg_G20_2050","EnGHGkg_G20_2055","EnGHGkg_G20_2060")])*1e-9
# emissions from new housing with grid decarbonization
New_MC<-colSums(rs_base_NC[,c("EnGHGkg_base_2020","EnGHGkg_base_2025","EnGHGkg_base_2030","EnGHGkg_base_2035","EnGHGkg_base_2040","EnGHGkg_base_2045","EnGHGkg_base_2050","EnGHGkg_base_2055","EnGHGkg_base_2060")])*1e-9

# emissions from <20 assuming no renovation, but with grid decarbonization
rs_base_Old<-rs_base_all_RR[rs_base_all_RR$Building<180001 & rs_base_all_RR$Year==2020,]
rs_base_Old<-rs_base_Old[,-c(38:45)] # remove the old wbase from 2025 on
# need to reapply the decay factors wbase...
load("../Intermediate_results/decayFactorsRen.RData") 

rs_base_Old<-left_join(rs_base_Old,sbm,by="ctyTC")

rs_base_Old[,c("EnGHGkg_base_NR_2020","EnGHGkg_base_NR_2025","EnGHGkg_base_NR_2030","EnGHGkg_base_NR_2035","EnGHGkg_base_NR_2040","EnGHGkg_base_NR_2045","EnGHGkg_base_NR_2050","EnGHGkg_base_NR_2055","EnGHGkg_base_NR_2060")]<-1000* 
  (rs_base_Old$base_weight*rs_base_Old[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*
  (rs_base_Old$Elec_GJ*rs_base_Old[,c("GHG_int_2020", "GHG_int_2025","GHG_int_2030","GHG_int_2035","GHG_int_2040","GHG_int_2045","GHG_int_2050","GHG_int_2055","GHG_int_2060")]+
     matrix(rep(rs_base_Old$Gas_GJ*GHGI_NG,9),nrow(rs_base_Old),9)+ matrix(rep(rs_base_Old$Oil_GJ*GHGI_FO,9),nrow(rs_base_Old),9)+ matrix(rep(rs_base_Old$Prop_GJ*GHGI_LP,9),nrow(rs_base_Old),9))

Old_NR_MC<-colSums(rs_base_Old[,c("EnGHGkg_base_NR_2020","EnGHGkg_base_NR_2025","EnGHGkg_base_NR_2030","EnGHGkg_base_NR_2035","EnGHGkg_base_NR_2040","EnGHGkg_base_NR_2045","EnGHGkg_base_NR_2050","EnGHGkg_base_NR_2055","EnGHGkg_base_NR_2060")])*1e-9 # make sure of correct column selection

# No action scenarios
NA_scen<-data.frame(Year=seq(2020,2060,5),Old_NR_G20=Old_NR_G20,New_G20=New_G20,Old_NR_MC=Old_NR_MC,New_MC=New_MC)
NA_scen$EnGHG_NR_G20<-NA_scen$Old_NR_G20+NA_scen$New_G20
NA_scen$EnGHG_NR_MC<-NA_scen$Old_NR_MC+NA_scen$New_MC

GHG_base_NR<-data.frame(data.frame(EnGHG=with(select(NA_scen,Year,EnGHG_NR_MC),spline(Year,EnGHG_NR_MC,xout=2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="A",RenScen="NR",ElecScen="MC")
names(GHG_base_NR)[1:2]<-c("Year","EnGHG")
GHG_base_NR$EmGHG<-us_base_FA$GHG_NC*1e-9
GHG_base_NR$EmGHG[41]<-GHG_base_NR$EmGHG[40]
# GHG_base_NR$RenGHG<-renGHGall[renGHGall$Scen=="Base_Reg",]$MtCO2e # actually, in this no renovation scenario, there are no renovation emissions
GHG_base_NR$TotGHG<-GHG_base_NR$EmGHG+GHG_base_NR$EnGHG

GHG_base_NR_G20<-data.frame(data.frame(EnGHG=with(select(NA_scen,Year,EnGHG_NR_G20),spline(Year,EnGHG_NR_G20,xout=2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="A",RenScen="NR",ElecScen="G20")
names(GHG_base_NR_G20)[1:2]<-c("Year","EnGHG")
GHG_base_NR_G20$EmGHG<-us_base_FA$GHG_NC*1e-9
GHG_base_NR_G20$EmGHG[41]<-GHG_base_NR_G20$EmGHG[40]
GHG_base_NR_G20$TotGHG<-GHG_base_NR_G20$EmGHG+GHG_base_NR_G20$EnGHG

# continue with the dplyr pipe operations
# Fig S8a
r<-melt(rs_base_all_RR %>% group_by(Heating.Fuel) %>% summarise(across(starts_with("Housing Units"),sum)))
names(r)[2]<-'Year'
r$Year<-gsub('Housing Units ','', r$Year)
r[r$Heating.Fuel %in% c("None","Other Fuel"),]$Heating.Fuel<-"Other/None"
windows(width = 7, height = 6.5)
ggplot(r,aes(Year,1e-6*value,fill=Heating.Fuel)) + geom_col() + theme_bw() +
  labs(title = "a) 1A Baseline Stock, Reg. Renovation ",  y = "Million Housing Units") + scale_fill_brewer(palette="Dark2")  +
  theme(axis.text=element_text(size=11),axis.title=element_text(size=12,face = "bold"),plot.title = element_text(size = 12))
# Fig S12a
r<-melt(rs_base_all_RR[rs_base_all_RR$OldCon==1,] %>% group_by(Infiltration) %>% summarise(across(starts_with("Housing Units"),sum)))
names(r)[2]<-'Year'
r$Year<-gsub('Housing Units ','', r$Year)
r$ACH<-as.numeric(gsub(' ACH50','',r$Infiltration))
r$ACH50<-"1-3"
r[r$ACH>3 & r$ACH<8,]$ACH50<-"4-7"
r[r$ACH>7 & r$ACH<15,]$ACH50<-"8-10"
r[r$ACH>10&r$ACH<25,]$ACH50<-"15-20"
r[r$ACH>20&r$ACH<40,]$ACH50<-"25-30"
r[r$ACH>30,]$ACH50<-"40+"
r$ACH50<-factor(r$ACH50,levels=c("1-3","4-7","8-10","15-20","25-30","40+"))
windows(width = 7, height = 6.5)
ggplot(r,aes(Year,1e-6*value,fill=ACH50)) + geom_col() + theme_bw() +
  labs(title = "a) Pre-2020 housing units by Infiltration, 2020-2060", subtitle = "Baseline Stock, Regular Renovation",  y = "Million Housing Units") + scale_fill_manual(values=colorRampPalette(brewer.pal(8,"Dark2"))(15))  +
  theme(axis.text=element_text(size=11),axis.title=element_text(size=11,face = "bold"),plot.title = element_text(size = 12))

# Fig S8b
r<-melt(rs_base_all_AR %>% group_by(Heating.Fuel) %>% summarise(across(starts_with("Housing Units"),sum)))
names(r)[2]<-'Year'
r$Year<-gsub('Housing Units ','', r$Year)
r[r$Heating.Fuel %in% c("None","Other Fuel"),]$Heating.Fuel<-"Other/None"
windows(width = 7, height = 6.5)
ggplot(r,aes(Year,1e-6*value,fill=Heating.Fuel)) + geom_col() + theme_bw() +
  labs(title = "b) 1A Baseline Stock, Adv. Renovation ",  y = "Million Housing Units") + scale_fill_brewer(palette="Dark2")  +
  theme(axis.text=element_text(size=11),axis.title=element_text(size=12,face = "bold"),plot.title = element_text(size = 12))
# Fig S8c
r<-melt(rs_base_all_ER %>% group_by(Heating.Fuel) %>% summarise(across(starts_with("Housing Units"),sum)))
names(r)[2]<-'Year'
r$Year<-gsub('Housing Units ','', r$Year)
r[r$Heating.Fuel %in% c("None","Other Fuel"),]$Heating.Fuel<-"Other/None"
windows(width = 7, height = 6.5)
ggplot(r,aes(Year,1e-6*value,fill=Heating.Fuel)) + geom_col() + theme_bw() +
  labs(title = "c) 1A Baseline Stock, Ext. Renovation ",  y = "Million Housing Units") + scale_fill_brewer(palette="Dark2")  +
  theme(axis.text=element_text(size=11),axis.title=element_text(size=12,face = "bold"),plot.title = element_text(size = 12))
# Fig S12b - OldCon needs to have been defined
r<-melt(rs_base_all_AR[rs_base_all_AR$OldCon==1,] %>% group_by(Infiltration) %>% summarise(across(starts_with("Housing Units"),sum)))
names(r)[2]<-'Year'
r$Year<-gsub('Housing Units ','', r$Year)
r$ACH<-as.numeric(gsub(' ACH50','',r$Infiltration))
r$ACH50<-"1-3"
r[r$ACH>3 & r$ACH<8,]$ACH50<-"4-7"
r[r$ACH>7 & r$ACH<15,]$ACH50<-"8-10"
r[r$ACH>10&r$ACH<25,]$ACH50<-"15-20"
r[r$ACH>20&r$ACH<40,]$ACH50<-"25-30"
r[r$ACH>30,]$ACH50<-"40+"
r$ACH50<-factor(r$ACH50,levels=c("1-3","4-7","8-10","15-20","25-30","40+"))
windows(width = 7, height = 6.5)
ggplot(r,aes(Year,1e-6*value,fill=ACH50)) + geom_col() + theme_bw() +
  labs(title = "b) Pre-2020 housing units by Infiltration, 2020-2060", subtitle = "Baseline Stock, Advanced/Extensive Renovation",  y = "Million Housing Units") + scale_fill_manual(values=colorRampPalette(brewer.pal(8,"Dark2"))(15))  +
  theme(axis.text=element_text(size=11),axis.title=element_text(size=12,face = "bold"),plot.title = element_text(size = 12))

# Fig S12bc
r<-melt(rs_base_all_ER[rs_base_all_ER$OldCon==1,] %>% group_by(Infiltration) %>% summarise(across(starts_with("Housing Units"),sum)))
names(r)[2]<-'Year'
r$Year<-gsub('Housing Units ','', r$Year)
r$ACH<-as.numeric(gsub(' ACH50','',r$Infiltration))
r$ACH50<-"1-3"
r[r$ACH>3 & r$ACH<8,]$ACH50<-"4-7"
r[r$ACH>7 & r$ACH<15,]$ACH50<-"8-10"
r[r$ACH>10&r$ACH<25,]$ACH50<-"15-20"
r[r$ACH>20&r$ACH<40,]$ACH50<-"25-30"
r[r$ACH>30,]$ACH50<-"40+"
r$ACH50<-factor(r$ACH50,levels=c("1-3","4-7","8-10","15-20","25-30","40+"))
windows(width = 7, height = 6.5)
ggplot(r,aes(Year,1e-6*value,fill=ACH50)) + geom_col() + theme_bw() +
  labs(title = "b) Pre-2020 housing units by Infiltration, 2020-2060", subtitle = "Baseline, Advanced/Extensive Renovation",  y = "Million Housing Units") + scale_fill_manual(values=colorRampPalette(brewer.pal(8,"Dark2"))(15))  +
  theme(axis.text=element_text(size=11),axis.title=element_text(size=12,face = "bold"),plot.title = element_text(size = 12))

# try other characteristics graphs, first heating efficiency ########
# RR
r<-melt(rs_base_all_RR[rs_base_all_RR$OldCon==1&rs_base_all_RR$Heating.Fuel=="Electricity",] %>% group_by(HVAC.Heating.Efficiency) %>% summarise(across(starts_with("Housing Units"),sum)))
names(r)[2]<-'Year'
r$Year<-gsub('Housing Units ','', r$Year)
names(r)[1]<-'Equip. Type & Efficiency'
windows(width = 7.6, height = 5.8)
ggplot(r,aes(Year,1e-6*value,fill=`Equip. Type & Efficiency`)) + geom_col() + theme_bw() + ylim(0,88) +
  labs(title = "a) Pre-2020 electric-heated housing units by equipment type", subtitle = "Baseline Stock, Regular Renovation",  y = "Million Housing Units") + scale_fill_manual(values=colorRampPalette(brewer.pal(8,"Dark2"))(15))  +
  theme(axis.text=element_text(size=11),axis.title=element_text(size=12,face = "bold"),plot.title = element_text(size = 12))
# AR
r<-melt(rs_base_all_AR[rs_base_all_AR$OldCon==1&rs_base_all_AR$Heating.Fuel=="Electricity",] %>% group_by(HVAC.Heating.Efficiency) %>% summarise(across(starts_with("Housing Units"),sum)))
names(r)[2]<-'Year'
r$Year<-gsub('Housing Units ','', r$Year)
names(r)[1]<-'Equip. Type & Efficiency'
windows(width = 7.6, height = 5.8)
ggplot(r,aes(Year,1e-6*value,fill=`Equip. Type & Efficiency`)) + geom_col() + theme_bw() + ylim(0,88) +
  labs(title = "b) Pre-2020 electric-heated housing units by equipment type", subtitle = "Baseline Stock, Advanced Renovation",  y = "Million Housing Units") + scale_fill_manual(values=colorRampPalette(brewer.pal(8,"Dark2"))(15))  +
  theme(axis.text=element_text(size=11),axis.title=element_text(size=12,face = "bold"),plot.title = element_text(size = 12))
# ER
r<-melt(rs_base_all_ER[rs_base_all_ER$OldCon==1&rs_base_all_ER$Heating.Fuel=="Electricity",] %>% group_by(HVAC.Heating.Efficiency) %>% summarise(across(starts_with("Housing Units"),sum)))
names(r)[2]<-'Year'
r$Year<-gsub('Housing Units ','', r$Year)
names(r)[1]<-'Equip. Type & Efficiency'
windows(width = 7.6, height = 5.8)
ggplot(r,aes(Year,1e-6*value,fill=`Equip. Type & Efficiency`)) + geom_col() + theme_bw() + ylim(0,88) +
  labs(title = "c) Pre-2020 electric-heated housing units by equipment type", subtitle = "Baseline Stock, Extensive Renovation",  y = "Million Housing Units") + scale_fill_manual(values=colorRampPalette(brewer.pal(8,"Dark2"))(15))  +
  theme(axis.text=element_text(size=11),axis.title=element_text(size=12,face = "bold"),plot.title = element_text(size = 12))
# next nat gas heating systems
# RR
r<-melt(rs_base_all_RR[rs_base_all_RR$OldCon==1&rs_base_all_RR$Heating.Fuel=="Natural Gas",] %>% group_by(HVAC.Heating.Efficiency) %>% summarise(across(starts_with("Housing Units"),sum)))
names(r)[2]<-'Year'
r$Year<-gsub('Housing Units ','', r$Year)
names(r)[1]<-'Equip. Type & Efficiency'
windows(width = 7.6, height = 5.8)
ggplot(r,aes(Year,1e-6*value,fill=`Equip. Type & Efficiency`)) + geom_col() + theme_bw() +
  labs(title = "a) Pre-2020 gas-heated housing units by equipment type", subtitle = "Baseline Stock, Regular Renovation",  y = "Million Housing Units") + scale_fill_manual(values=colorRampPalette(brewer.pal(9,"Set1"))(15))  +
  theme(axis.text=element_text(size=11),axis.title=element_text(size=12,face = "bold"),plot.title = element_text(size = 12))
# AR
r<-melt(rs_base_all_AR[rs_base_all_AR$OldCon==1&rs_base_all_AR$Heating.Fuel=="Natural Gas",] %>% group_by(HVAC.Heating.Efficiency) %>% summarise(across(starts_with("Housing Units"),sum)))
names(r)[2]<-'Year'
r$Year<-gsub('Housing Units ','', r$Year)
names(r)[1]<-'Equip. Type & Efficiency'
windows(width = 7.6, height = 5.8)
ggplot(r,aes(Year,1e-6*value,fill=`Equip. Type & Efficiency`)) + geom_col() + theme_bw() +
  labs(title = "b) Pre-2020 gas-heated housing units by equipment type", subtitle = "Baseline Stock, Advanced Renovation",  y = "Million Housing Units") + scale_fill_manual(values=colorRampPalette(brewer.pal(9,"Set1"))(15))  +
  theme(axis.text=element_text(size=11),axis.title=element_text(size=12,face = "bold"),plot.title = element_text(size = 12))
# ER
r<-melt(rs_base_all_ER[rs_base_all_ER$OldCon==1&rs_base_all_ER$Heating.Fuel=="Natural Gas",] %>% group_by(HVAC.Heating.Efficiency) %>% summarise(across(starts_with("Housing Units"),sum)))
names(r)[2]<-'Year'
r$Year<-gsub('Housing Units ','', r$Year)
names(r)[1]<-'Equip. Type & Efficiency'
windows(width = 7.6, height = 5.8)
ggplot(r,aes(Year,1e-6*value,fill=`Equip. Type & Efficiency`)) + geom_col() + theme_bw() +
  labs(title = "c) Pre-2020 gas-heated housing units by equipment type", subtitle = "Baseline Stock, Extensive Renovation",  y = "Million Housing Units") + scale_fill_manual(values=colorRampPalette(brewer.pal(9,"Set1"))(15))  +
  theme(axis.text=element_text(size=11),axis.title=element_text(size=12,face = "bold"),plot.title = element_text(size = 12))
# next fuel oil heating systems
# RR
r<-melt(rs_base_all_RR[rs_base_all_RR$OldCon==1&rs_base_all_RR$Heating.Fuel=="Fuel Oil",] %>% group_by(HVAC.Heating.Efficiency) %>% summarise(across(starts_with("Housing Units"),sum)))
names(r)[2]<-'Year'
r$Year<-gsub('Housing Units ','', r$Year)
names(r)[1]<-'Equip. Type & Efficiency'
windows(width = 7.6, height = 5.8)
ggplot(r,aes(Year,1e-6*value,fill=`Equip. Type & Efficiency`)) + geom_col() + theme_bw() +
  labs(title = "a) Pre-2020 oil-heated housing units by equipment type", subtitle = "Baseline Stock, Regular Renovation",  y = "Million Housing Units") + scale_fill_manual(values=colorRampPalette(brewer.pal(8,"Dark2"))(15))  +
  theme(axis.text=element_text(size=11),axis.title=element_text(size=12,face = "bold"),plot.title = element_text(size = 12))
# AR
r<-melt(rs_base_all_AR[rs_base_all_AR$OldCon==1&rs_base_all_AR$Heating.Fuel=="Fuel Oil",] %>% group_by(HVAC.Heating.Efficiency) %>% summarise(across(starts_with("Housing Units"),sum)))
names(r)[2]<-'Year'
r$Year<-gsub('Housing Units ','', r$Year)
names(r)[1]<-'Equip. Type & Efficiency'
windows(width = 7.6, height = 5.8)
ggplot(r,aes(Year,1e-6*value,fill=`Equip. Type & Efficiency`)) + geom_col() + theme_bw() +
  labs(title = "b) Pre-2020 oil-heated housing units by equipment type", subtitle = "Baseline Stock, Advanced Renovation",  y = "Million Housing Units") + scale_fill_manual(values=colorRampPalette(brewer.pal(8,"Dark2"))(15))  +
  theme(axis.text=element_text(size=11),axis.title=element_text(size=12,face = "bold"),plot.title = element_text(size = 12))
# ER
r<-melt(rs_base_all_ER[rs_base_all_ER$OldCon==1&rs_base_all_ER$Heating.Fuel=="Fuel Oil",] %>% group_by(HVAC.Heating.Efficiency) %>% summarise(across(starts_with("Housing Units"),sum)))
names(r)[2]<-'Year'
r$Year<-gsub('Housing Units ','', r$Year)
names(r)[1]<-'Equip. Type & Efficiency'
windows(width = 7.6, height = 5.8)
ggplot(r,aes(Year,1e-6*value,fill=`Equip. Type & Efficiency`)) + geom_col() + theme_bw() +
  labs(title = "c) Pre-2020 oil-heated housing units by equipment type", subtitle = "Baseline Stock, Extensive Renovation",  y = "Million Housing Units") + scale_fill_manual(values=colorRampPalette(brewer.pal(8,"Dark2"))(15))  +
  theme(axis.text=element_text(size=11),axis.title=element_text(size=12,face = "bold"),plot.title = element_text(size = 12))
## next AC Type
#RR
r<-melt(rs_base_all_RR[rs_base_all_RR$OldCon==1,] %>% group_by(HVAC.Cooling.Efficiency) %>% summarise(across(starts_with("Housing Units"),sum)))
names(r)[2]<-'Year'
r$Year<-gsub('Housing Units ','', r$Year)
names(r)[1]<-'AC Type & Efficiency'
r$`AC Type & Efficiency`<-gsub('AC, S','Cent. AC, S',r$`AC Type & Efficiency`)
cols<-colorRampPalette(brewer.pal(12,"Paired"))(length(unique(r$`AC Type & Efficiency`)))
cols[which(cols=="#FFFF99")]<-"#BA5993" # Replace the bright yellow
windows(width = 7.6, height = 5.8)
ggplot(r,aes(Year,1e-6*value,fill=`AC Type & Efficiency`)) + geom_col() + theme_bw() +
  labs(title = "a) Pre-2020 housing units by AC type", subtitle = "Baseline Stock, Regular Renovation",  y = "Million Housing Units") + scale_fill_manual(values = cols)   +
  theme(axis.text=element_text(size=11),axis.title=element_text(size=12,face = "bold"),plot.title = element_text(size = 12))
#AR , need to have NewCon OldCon defined
r<-melt(rs_base_all_AR[rs_base_all_AR$OldCon==1,] %>% group_by(HVAC.Cooling.Efficiency) %>% summarise(across(starts_with("Housing Units"),sum)))
names(r)[2]<-'Year'
r$Year<-gsub('Housing Units ','', r$Year)
names(r)[1]<-'AC Type & Efficiency'
r$`AC Type & Efficiency`<-gsub('AC, S','Cent. AC, S',r$`AC Type & Efficiency`)
cols<-colorRampPalette(brewer.pal(12,"Paired"))(length(unique(r$`AC Type & Efficiency`)))
cols[which(cols=="#FFFF99")]<-"#BA5993" # Replace the bright yellow
windows(width = 7.6, height = 5.8)
ggplot(r,aes(Year,1e-6*value,fill=`AC Type & Efficiency`)) + geom_col() + theme_bw() +
  labs(title = "b) Pre-2020 housing units by AC type", subtitle = "Baseline Stock, Advanced/Extensive Renovation",  y = "Million Housing Units") + scale_fill_manual(values = cols)   +
  theme(axis.text=element_text(size=11),axis.title=element_text(size=12,face = "bold"),plot.title = element_text(size = 12))
#ER
r<-melt(rs_base_all_ER[rs_base_all_ER$OldCon==1,] %>% group_by(HVAC.Cooling.Efficiency) %>% summarise(across(starts_with("Housing Units"),sum)))
names(r)[2]<-'Year'
r$Year<-gsub('Housing Units ','', r$Year)
names(r)[1]<-'AC Type & Efficiency'
r$`AC Type & Efficiency`<-gsub('AC, S','Cent. AC, S',r$`AC Type & Efficiency`)
cols<-colorRampPalette(brewer.pal(12,"Paired"))(length(unique(r$`AC Type & Efficiency`)))
cols[which(cols=="#FFFF99")]<-"#BA5993" # Replace the bright yellow
windows(width = 7.6, height = 5.8)
ggplot(r,aes(Year,1e-6*value,fill=`AC Type & Efficiency`)) + geom_col() + theme_bw() +
  labs(title = "c) Pre-2020 housing units by AC type", subtitle = "Baseline, Extensive Renovation",  y = "Million Housing Units") + scale_fill_manual(values = cols)   +
  theme(axis.text=element_text(size=11),axis.title=element_text(size=12,face = "bold"),plot.title = element_text(size = 12))
# now water heating equipment type
# RR
r<-melt(rs_base_all_RR[rs_base_all_RR$OldCon==1,] %>% group_by(Water.Heater.Efficiency) %>% summarise(across(starts_with("Housing Units"),sum)))
names(r)[2]<-'Year'
r$Year<-gsub('Housing Units ','', r$Year)
names(r)[1]<-'HW Type & Efficiency'
r$`HW Type & Efficiency`<-gsub(', 80 gal','',r$`HW Type & Efficiency`)
r$`HW Type & Efficiency`<-gsub('FIXME ','',r$`HW Type & Efficiency`)
windows(width = 7.6, height = 5.8)
ggplot(r,aes(Year,1e-6*value,fill=`HW Type & Efficiency`)) + geom_col() + theme_bw() +
  labs(title = "a) Pre-2020 housing units by Hot Water equipment type", subtitle = "Baseline Stock, Regular Renovation",  y = "Million Housing Units") + scale_fill_manual(values=colorRampPalette(brewer.pal(9,"Set1"))(16)[-11])  +
  theme(axis.text=element_text(size=11),axis.title=element_text(size=12,face = "bold"),plot.title = element_text(size = 12))
# AR
r<-melt(rs_base_all_AR[rs_base_all_AR$OldCon==1,] %>% group_by(Water.Heater.Efficiency) %>% summarise(across(starts_with("Housing Units"),sum)))
names(r)[2]<-'Year'
r$Year<-gsub('Housing Units ','', r$Year)
names(r)[1]<-'HW Type & Efficiency'
r$`HW Type & Efficiency`<-gsub(', 80 gal','',r$`HW Type & Efficiency`)
r$`HW Type & Efficiency`<-gsub('FIXME ','',r$`HW Type & Efficiency`)
windows(width = 7.6, height = 5.8)
ggplot(r,aes(Year,1e-6*value,fill=`HW Type & Efficiency`)) + geom_col() + theme_bw() +
  labs(title = "b) Pre-2020 housing units by Hot Water equipment type", subtitle = "Baseline Stock, Advanced Renovation",  y = "Million Housing Units") + scale_fill_manual(values=colorRampPalette(brewer.pal(9,"Set1"))(16)[-11])  +
  theme(axis.text=element_text(size=11),axis.title=element_text(size=12,face = "bold"),plot.title = element_text(size = 12))
# ER
r<-melt(rs_base_all_ER[rs_base_all_ER$OldCon==1,] %>% group_by(Water.Heater.Efficiency) %>% summarise(across(starts_with("Housing Units"),sum)))
names(r)[2]<-'Year'
r$Year<-gsub('Housing Units ','', r$Year)
names(r)[1]<-'HW Type & Efficiency'
r$`HW Type & Efficiency`<-gsub(', 80 gal','',r$`HW Type & Efficiency`)
r$`HW Type & Efficiency`<-gsub('FIXME ','',r$`HW Type & Efficiency`)
windows(width = 7.6, height = 5.8)
ggplot(r,aes(Year,1e-6*value,fill=`HW Type & Efficiency`)) + geom_col() + theme_bw() +
  labs(title = "c) Pre-2020 housing units by Hot Water equipment type", subtitle = "Baseline Stock, Extensive Renovation",  y = "Million Housing Units") + scale_fill_manual(values=colorRampPalette(brewer.pal(9,"Set1"))(16)[-11])  +
  theme(axis.text=element_text(size=11),axis.title=element_text(size=12,face = "bold"),plot.title = element_text(size = 12))

# Wall insulation
# RR
r<-melt(rs_base_all_RR[rs_base_all_RR$OldCon==1,] %>% group_by(insulation_wall) %>% summarise(across(starts_with("Housing Units"),sum)))
names(r)[2]<-'Year'
r$Year<-gsub('Housing Units ','', r$Year)
names(r)[1]<-'Wall Insulation'
cols<-colorRampPalette(brewer.pal(12,"Paired"))(length(unique(r$`Wall Insulation`)))
cols[which(cols=="#FFFF99")]<-"#BA5993" # Replace the bright yellow
windows(width = 7.6, height = 5.8)
ggplot(r,aes(Year,1e-6*value,fill=`Wall Insulation`)) + geom_col() + theme_bw() +
  labs(title = "a) Pre-2020 housing units by Wall Insulation", subtitle = "Baseline Stock, Regular Renovation",  y = "Million Housing Units") + scale_fill_manual(values=cols)  +
  theme(axis.text=element_text(size=11),axis.title=element_text(size=12,face = "bold"),plot.title = element_text(size = 12))

# AR
r<-melt(rs_base_all_AR[rs_base_all_AR$OldCon==1,] %>% group_by(insulation_wall) %>% summarise(across(starts_with("Housing Units"),sum)))
names(r)[2]<-'Year'
r$Year<-gsub('Housing Units ','', r$Year)
names(r)[1]<-'Wall Insulation'
cols<-colorRampPalette(brewer.pal(12,"Paired"))(length(unique(r$`Wall Insulation`)))
cols[which(cols=="#FFFF99")]<-"#BA5993" # Replace the bright yellow
windows(width = 7.6, height = 5.8)
ggplot(r,aes(Year,1e-6*value,fill=`Wall Insulation`)) + geom_col() + theme_bw() +
  labs(title = "b) Pre-2020 housing units by Wall Insulation", subtitle = "Baseline Stock, Advanced/Extensive Renovation",  y = "Million Housing Units") + scale_fill_manual(values=cols)  +
  theme(axis.text=element_text(size=11),axis.title=element_text(size=12,face = "bold"),plot.title = element_text(size = 12))

# ER
r<-melt(rs_base_all_ER[rs_base_all_ER$OldCon==1,] %>% group_by(insulation_wall) %>% summarise(across(starts_with("Housing Units"),sum)))
names(r)[2]<-'Year'
r$Year<-gsub('Housing Units ','', r$Year)
names(r)[1]<-'Wall Insulation'
cols<-colorRampPalette(brewer.pal(12,"Paired"))(length(unique(r$`Wall Insulation`)))
cols[which(cols=="#FFFF99")]<-"#BA5993" # Replace the bright yellow
windows(width = 7.6, height = 5.8)
ggplot(r,aes(Year,1e-6*value,fill=`Wall Insulation`)) + geom_col() + theme_bw() +
  labs(title = "c) Pre-2020 housing units by Wall Insulation", subtitle = "Baseline, Extensive Renovation",  y = "Million Housing Units") + scale_fill_manual(values=cols)  +
  theme(axis.text=element_text(size=11),axis.title=element_text(size=12,face = "bold"),plot.title = element_text(size = 12))

# electrification of new construction
r<-melt(rs_base_all_RR[rs_base_all_RR$NewCon==1&rs_base_all_RR$Heating.Fuel=="Electricity",] %>% group_by(Census.Region) %>% summarise(across(starts_with("Housing Units"),sum)))
names(r)[2]<-'Year'
r$Year<-gsub('Housing Units ','', r$Year)
r<-r[r$Year>2020,]

r2<-melt(rs_base_all_RR[rs_base_all_RR$NewCon==1,] %>% group_by(Census.Region) %>% summarise(across(starts_with("Housing Units"),sum)))
names(r2)[2]<-'Year'
r2$Year<-gsub('Housing Units ','', r2$Year)
r2<-r2[r2$Year>2020,]

names(r2)[3]<-"All"
names(r)[3]<-"Elec"
r3<-merge(r,r2)
r3$Elec_pc<-r3$Elec/r3$All

windows(width = 7.6, height = 5.8)
ggplot(r3,aes(Year,100*Elec_pc,group=Census.Region)) + geom_line(aes(color=Census.Region),size=1) + theme_bw() + ylim(0,100) +
  labs(title = "a) Share of new construction with electric heating, by Census Region", subtitle = "Baseline",  y = "Million Housing Units") + scale_fill_manual(values=cols)  +
  theme(axis.text=element_text(size=11),axis.title=element_text(size=12,face = "bold"),plot.title = element_text(size = 12))

# hi DR
rs_hiDR_all_RR[,c("Housing Units 2020","Housing Units 2025","Housing Units 2030","Housing Units 2035","Housing Units 2040","Housing Units 2045","Housing Units 2050","Housing Units 2055","Housing Units 2060")]<-
  rs_hiDR_all_RR$base_weight*rs_hiDR_all_RR[,c("whiDR_2020",  "whiDR_2025", "whiDR_2030", "whiDR_2035", "whiDR_2040", "whiDR_2045", "whiDR_2050", "whiDR_2055", "whiDR_2060")]

rs_hiDR_all_AR[,c("Housing Units 2020","Housing Units 2025","Housing Units 2030","Housing Units 2035","Housing Units 2040","Housing Units 2045","Housing Units 2050","Housing Units 2055","Housing Units 2060")]<-
  rs_hiDR_all_AR$base_weight*rs_hiDR_all_AR[,c("whiDR_2020",  "whiDR_2025", "whiDR_2030", "whiDR_2035", "whiDR_2040", "whiDR_2045", "whiDR_2050", "whiDR_2055", "whiDR_2060")]

rs_hiDR_all_ER[,c("Housing Units 2020","Housing Units 2025","Housing Units 2030","Housing Units 2035","Housing Units 2040","Housing Units 2045","Housing Units 2050","Housing Units 2055","Housing Units 2060")]<-
  rs_hiDR_all_ER$base_weight*rs_hiDR_all_ER[,c("whiDR_2020",  "whiDR_2025", "whiDR_2030", "whiDR_2035", "whiDR_2040", "whiDR_2045", "whiDR_2050", "whiDR_2055", "whiDR_2060")]


r<-melt(rs_hiDR_all_RR %>% group_by(Heating.Fuel) %>% summarise(across(starts_with("Housing Units"),sum)))
names(r)[2]<-'Year'
r$Year<-gsub('Housing Units ','', r$Year)
r[r$Heating.Fuel %in% c("None","Other Fuel"),]$Heating.Fuel<-"Other/None"
windows(width = 7, height = 6.5)
ggplot(r,aes(Year,1e-6*value,fill=Heating.Fuel)) + geom_col() + theme_bw() +
  labs(title = "c) 2A Hi Turnover Reg Renovation ",  y = "Million Housing Units") + scale_fill_brewer(palette="Dark2")  +
  theme(axis.text=element_text(size=11),axis.title=element_text(size=12,face = "bold"),plot.title = element_text(size = 12))

r<-melt(rs_hiDR_all_AR %>% group_by(Heating.Fuel) %>% summarise(across(starts_with("Housing Units"),sum)))
names(r)[2]<-'Year'
r$Year<-gsub('Housing Units ','', r$Year)
r[r$Heating.Fuel %in% c("None","Other Fuel"),]$Heating.Fuel<-"Other/None"
windows(width = 7, height = 6.5)
ggplot(r,aes(Year,1e-6*value,fill=Heating.Fuel)) + geom_col() + theme_bw() +
  labs(title = "d) 2A Hi Turnover Adv Renovation ",  y = "Million Housing Units") + scale_fill_brewer(palette="Dark2")  +
  theme(axis.text=element_text(size=11),axis.title=element_text(size=12,face = "bold"),plot.title = element_text(size = 12))

# hi MF
rs_hiMF_all_RR[,c("Housing Units 2020","Housing Units 2025","Housing Units 2030","Housing Units 2035","Housing Units 2040","Housing Units 2045","Housing Units 2050","Housing Units 2055","Housing Units 2060")]<-
  rs_hiMF_all_RR$base_weight*rs_hiMF_all_RR[,c("whiMF_2020",  "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")]

rs_hiMF_all_AR[,c("Housing Units 2020","Housing Units 2025","Housing Units 2030","Housing Units 2035","Housing Units 2040","Housing Units 2045","Housing Units 2050","Housing Units 2055","Housing Units 2060")]<-
  rs_hiMF_all_AR$base_weight*rs_hiMF_all_AR[,c("whiMF_2020",  "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")]

rs_hiMF_all_ER[,c("Housing Units 2020","Housing Units 2025","Housing Units 2030","Housing Units 2035","Housing Units 2040","Housing Units 2045","Housing Units 2050","Housing Units 2055","Housing Units 2060")]<-
  rs_hiMF_all_ER$base_weight*rs_hiMF_all_ER[,c("whiMF_2020",  "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")]

r<-melt(rs_hiMF_all_RR %>% group_by(Heating.Fuel) %>% summarise(across(starts_with("Housing Units"),sum)))
names(r)[2]<-'Year'
r$Year<-gsub('Housing Units ','', r$Year)
r[r$Heating.Fuel %in% c("None","Other Fuel"),]$Heating.Fuel<-"Other/None"
windows(width = 7, height = 6.5)
ggplot(r,aes(Year,1e-6*value,fill=Heating.Fuel)) + geom_col() + theme_bw() +
  labs(title = "d) 2A Hi Multifamily Reg Renovation ",  y = "Million Housing Units") + scale_fill_brewer(palette="Dark2")  +
  theme(axis.text=element_text(size=11),axis.title=element_text(size=12,face = "bold"),plot.title = element_text(size = 12))

r<-melt(rs_hiMF_all_AR %>% group_by(Heating.Fuel) %>% summarise(across(starts_with("Housing Units"),sum)))
names(r)[2]<-'Year'
r$Year<-gsub('Housing Units ','', r$Year)
r[r$Heating.Fuel %in% c("None","Other Fuel"),]$Heating.Fuel<-"Other/None"
windows(width = 7, height = 6.5)
ggplot(r,aes(Year,1e-6*value,fill=Heating.Fuel)) + geom_col() + theme_bw() +
  labs(title = "d) 2A Hi Multifamily Adv Renovation ",  y = "Million Housing Units") + scale_fill_brewer(palette="Dark2")  +
  theme(axis.text=element_text(size=11),axis.title=element_text(size=12,face = "bold"),plot.title = element_text(size = 12))
# can remove these data frames, which will no longer be needed
rm(list=ls(pattern = "rs_"))
rm(list=ls(pattern = "New"))
rm(list=ls(pattern = "Old"))

# second RFA scripts #########
load("../Final_results/res_baseRFA_RR.RData")
load("../Final_results/res_baseRFA_AR.RData")
load("../Final_results/res_baseRFA_ER.RData")
load("../Final_results/res_hiDRRFA_RR.RData")
load("../Final_results/res_hiDRRFA_AR.RData")
load("../Final_results/res_hiDRRFA_ER.RData")
load("../Final_results/res_hiMFRFA_RR.RData")
load("../Final_results/res_hiMFRFA_AR.RData")
load("../Final_results/res_hiMFRFA_ER.RData")

# add in GHG intensities for 2035 CFE
rs_baseRFA_all_RR[,c("GHG_int_2020_CFE","GHG_int_2025_CFE")]<-rs_baseRFA_all_RR[,c("GHG_int_2020_LRE","GHG_int_2025_LRE")]
rs_baseRFA_all_RR[,c("GHG_int_2030_CFE")]<-0.5*rs_baseRFA_all_RR[,c("GHG_int_2025_LRE")]
rs_baseRFA_all_RR[,c("GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")]<-0

rs_baseRFA_all_AR[,c("GHG_int_2020_CFE","GHG_int_2025_CFE")]<-rs_baseRFA_all_AR[,c("GHG_int_2020_LRE","GHG_int_2025_LRE")]
rs_baseRFA_all_AR[,c("GHG_int_2030_CFE")]<-0.5*rs_baseRFA_all_AR[,c("GHG_int_2025_LRE")]
rs_baseRFA_all_AR[,c("GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")]<-0

rs_baseRFA_all_ER[,c("GHG_int_2020_CFE","GHG_int_2025_CFE")]<-rs_baseRFA_all_ER[,c("GHG_int_2020_LRE","GHG_int_2025_LRE")]
rs_baseRFA_all_ER[,c("GHG_int_2030_CFE")]<-0.5*rs_baseRFA_all_ER[,c("GHG_int_2025_LRE")]
rs_baseRFA_all_ER[,c("GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")]<-0

# add in GHG emissions for CFE
rs_baseRFA_all_RR[,c("EnGHGkg_base_2020_CFE","EnGHGkg_base_2025_CFE","EnGHGkg_base_2030_CFE","EnGHGkg_base_2035_CFE","EnGHGkg_base_2040_CFE","EnGHGkg_base_2045_CFE","EnGHGkg_base_2050_CFE","EnGHGkg_base_2055_CFE","EnGHGkg_base_2060_CFE")]<-1000* 
  (rs_baseRFA_all_RR$base_weight*rs_baseRFA_all_RR[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*
  (rs_baseRFA_all_RR$Elec_GJ*rs_baseRFA_all_RR[,c("GHG_int_2020_CFE", "GHG_int_2025_CFE","GHG_int_2030_CFE","GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")]+
     matrix(rep(rs_baseRFA_all_RR$Gas_GJ*GHGI_NG,9),nrow(rs_baseRFA_all_RR),9)+ matrix(rep(rs_baseRFA_all_RR$Oil_GJ*GHGI_FO,9),nrow(rs_baseRFA_all_RR),9)+ matrix(rep(rs_baseRFA_all_RR$Prop_GJ*GHGI_LP,9),nrow(rs_baseRFA_all_RR),9))

rs_baseRFA_all_AR[,c("EnGHGkg_base_2020_CFE","EnGHGkg_base_2025_CFE","EnGHGkg_base_2030_CFE","EnGHGkg_base_2035_CFE","EnGHGkg_base_2040_CFE","EnGHGkg_base_2045_CFE","EnGHGkg_base_2050_CFE","EnGHGkg_base_2055_CFE","EnGHGkg_base_2060_CFE")]<-1000* 
  (rs_baseRFA_all_AR$base_weight*rs_baseRFA_all_AR[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*
  (rs_baseRFA_all_AR$Elec_GJ*rs_baseRFA_all_AR[,c("GHG_int_2020_CFE", "GHG_int_2025_CFE","GHG_int_2030_CFE","GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")]+
     matrix(rep(rs_baseRFA_all_AR$Gas_GJ*GHGI_NG,9),nrow(rs_baseRFA_all_AR),9)+ matrix(rep(rs_baseRFA_all_AR$Oil_GJ*GHGI_FO,9),nrow(rs_baseRFA_all_AR),9)+ matrix(rep(rs_baseRFA_all_AR$Prop_GJ*GHGI_LP,9),nrow(rs_baseRFA_all_AR),9))

rs_baseRFA_all_ER[,c("EnGHGkg_base_2020_CFE","EnGHGkg_base_2025_CFE","EnGHGkg_base_2030_CFE","EnGHGkg_base_2035_CFE","EnGHGkg_base_2040_CFE","EnGHGkg_base_2045_CFE","EnGHGkg_base_2050_CFE","EnGHGkg_base_2055_CFE","EnGHGkg_base_2060_CFE")]<-1000*
  (rs_baseRFA_all_ER$base_weight*rs_baseRFA_all_ER[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*
  (rs_baseRFA_all_ER$Elec_GJ*rs_baseRFA_all_ER[,c("GHG_int_2020_CFE", "GHG_int_2025_CFE","GHG_int_2030_CFE","GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")]+
     matrix(rep(rs_baseRFA_all_ER$Gas_GJ*GHGI_NG,9),nrow(rs_baseRFA_all_ER),9)+ matrix(rep(rs_baseRFA_all_ER$Oil_GJ*GHGI_FO,9),nrow(rs_baseRFA_all_ER),9)+ matrix(rep(rs_baseRFA_all_ER$Prop_GJ*GHGI_LP,9),nrow(rs_baseRFA_all_ER),9))

# start compiling emissions
GHG_baseRFA_RR<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_baseRFA_all_RR[,176:184])) # emissions in Mt 
GHG_baseRFA_RR<-data.frame(data.frame(EnGHG=with(select(GHG_baseRFA_RR,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="B",RenScen="RR",ElecScen="MC")
names(GHG_baseRFA_RR)[1:2]<-c("Year","EnGHG")
GHG_baseRFA_RR$EmGHG<-us_RFA_FA$GHG_NC*1e-9
GHG_baseRFA_RR$EmGHG[41]<-GHG_baseRFA_RR$EmGHG[40]
GHG_baseRFA_RR$RenGHG<-renGHGall[renGHGall$Scen=="Base_Reg",]$MtCO2e
GHG_baseRFA_RR$TotGHG<-GHG_baseRFA_RR$EmGHG+GHG_baseRFA_RR$RenGHG+GHG_baseRFA_RR$EnGHG

GHG_baseRFA_RR_LREC<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_baseRFA_all_RR[,185:193])) # emissions in Mt 
GHG_baseRFA_RR_LREC<-data.frame(data.frame(EnGHG=with(select(GHG_baseRFA_RR_LREC,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="B",RenScen="RR",ElecScen="LREC")
names(GHG_baseRFA_RR_LREC)[1:2]<-c("Year","EnGHG")
GHG_baseRFA_RR_LREC$EmGHG<-us_RFA_FA$GHG_NC*1e-9
GHG_baseRFA_RR_LREC$EmGHG[41]<-GHG_baseRFA_RR_LREC$EmGHG[40]
GHG_baseRFA_RR_LREC$RenGHG<-renGHGall[renGHGall$Scen=="Base_Reg",]$MtCO2e
GHG_baseRFA_RR_LREC$TotGHG<-GHG_baseRFA_RR_LREC$EmGHG+GHG_baseRFA_RR_LREC$RenGHG+GHG_baseRFA_RR_LREC$EnGHG

# for CFE, EnGHG needs to be done first by electricity, and then recombined with fuel EnGHG
rs_baseRFA_all_RR[,c("ElecGHGkg_2020_LRE","ElecGHGkg_2025_LRE","ElecGHGkg_2030_LRE","ElecGHGkg_2035_LRE","ElecGHGkg_2040_LRE","ElecGHGkg_2045_LRE","ElecGHGkg_2050_LRE","ElecGHGkg_2055_LRE","ElecGHGkg_2060_LRE")]<-1000* 
  (rs_baseRFA_all_RR$base_weight*rs_baseRFA_all_RR[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*
  (rs_baseRFA_all_RR$Elec_GJ*rs_baseRFA_all_RR[,c("GHG_int_2020_LRE", "GHG_int_2025_LRE","GHG_int_2030_LRE","GHG_int_2035_LRE","GHG_int_2040_LRE","GHG_int_2045_LRE","GHG_int_2050_LRE","GHG_int_2055_LRE","GHG_int_2060_LRE")])

rs_baseRFA_all_RR[,c("ElecGHGkg_2020_CFE","ElecGHGkg_2025_CFE","ElecGHGkg_2030_CFE","ElecGHGkg_2035_CFE","ElecGHGkg_2040_CFE","ElecGHGkg_2045_CFE","ElecGHGkg_2050_CFE","ElecGHGkg_2055_CFE","ElecGHGkg_2060_CFE")]<-1000* 
  (rs_baseRFA_all_RR$base_weight*rs_baseRFA_all_RR[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*
  (rs_baseRFA_all_RR$Elec_GJ*rs_baseRFA_all_RR[,c("GHG_int_2020_CFE", "GHG_int_2025_CFE","GHG_int_2030_CFE","GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")])

GHGelec_baseRFA_RR_LRE<-data.frame(Year=seq(2020,2060,5),ElGHG=1e-9*colSums(rs_baseRFA_all_RR[,212:220])) # emissions in Mt 
GHGelec_baseRFA_RR_LRE<-data.frame(data.frame(ElGHG=with(select(GHGelec_baseRFA_RR_LRE,Year,ElGHG),spline(Year,ElGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="A",RenScen="RR",ElecScen="LRE")
names(GHGelec_baseRFA_RR_LRE)[1:2]<-c("Year","ElGHG")

GHGelec_baseRFA_RR_CFE<-data.frame(Year=seq(2020,2060,5),ElGHG=1e-9*colSums(rs_baseRFA_all_RR[,221:229])) # emissions in Mt 
GHGelec_baseRFA_RR_CFE<-data.frame(data.frame(ElGHG=with(select(GHGelec_baseRFA_RR_CFE,Year,ElGHG),spline(Year,ElGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="A",RenScen="RR",ElecScen="CFE")
names(GHGelec_baseRFA_RR_CFE)[1:2]<-c("Year","ElGHG")

GHGelec_baseRFA_RR_CFE$ElGHG[1:6]<-GHGelec_baseRFA_RR_LRE$ElGHG[1:6] # 2020:2025 is same in CFE as in LRE
GHGelec_baseRFA_RR_CFE$ElGHG[16:41]<-0 # 2035:2060 is 0 in CFE

GHG_baseRFA_RR_CFE<-GHG_baseRFA_RR_LREC
GHG_baseRFA_RR_CFE$ElecScen<-"CFE"
GHG_baseRFA_RR_CFE$EnGHG<-GHG_baseRFA_RR_LREC$EnGHG-GHGelec_baseRFA_RR_LRE$ElGHG+GHGelec_baseRFA_RR_CFE$ElGHG # energy emissions equal total LRE enGHG - LRE elGHG + CFE elGHG
GHG_baseRFA_RR_CFE$EmGHG<-us_RFA_FA$GHG_NC*1e-9
GHG_baseRFA_RR_CFE$EmGHG[41]<-GHG_baseRFA_RR_CFE$EmGHG[40]
GHG_baseRFA_RR_CFE$RenGHG<-renGHGall[renGHGall$Scen=="Base_Reg",]$MtCO2e
GHG_baseRFA_RR_CFE$TotGHG<-GHG_baseRFA_RR_CFE$EmGHG+GHG_baseRFA_RR_CFE$RenGHG+GHG_baseRFA_RR_CFE$EnGHG

# RFA AR
GHG_baseRFA_AR<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_baseRFA_all_AR[,176:184])) # emissions in Mt 
GHG_baseRFA_AR<-data.frame(data.frame(EnGHG=with(select(GHG_baseRFA_AR,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="B",RenScen="AR",ElecScen="MC")
names(GHG_baseRFA_AR)[1:2]<-c("Year","EnGHG")
GHG_baseRFA_AR$EmGHG<-us_RFA_FA$GHG_NC*1e-9
GHG_baseRFA_AR$EmGHG[41]<-GHG_baseRFA_AR$EmGHG[40]
GHG_baseRFA_AR$RenGHG<-renGHGall[renGHGall$Scen=="Base_Adv",]$MtCO2e
GHG_baseRFA_AR$TotGHG<-GHG_baseRFA_AR$EmGHG+GHG_baseRFA_AR$RenGHG+GHG_baseRFA_AR$EnGHG

GHG_baseRFA_AR_LREC<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_baseRFA_all_AR[,185:193])) # emissions in Mt 
GHG_baseRFA_AR_LREC<-data.frame(data.frame(EnGHG=with(select(GHG_baseRFA_AR_LREC,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="B",RenScen="AR",ElecScen="LREC")
names(GHG_baseRFA_AR_LREC)[1:2]<-c("Year","EnGHG")
GHG_baseRFA_AR_LREC$EmGHG<-us_RFA_FA$GHG_NC*1e-9
GHG_baseRFA_AR_LREC$EmGHG[41]<-GHG_baseRFA_AR_LREC$EmGHG[40]
GHG_baseRFA_AR_LREC$RenGHG<-renGHGall[renGHGall$Scen=="Base_Adv",]$MtCO2e
GHG_baseRFA_AR_LREC$TotGHG<-GHG_baseRFA_AR_LREC$EmGHG+GHG_baseRFA_AR_LREC$RenGHG+GHG_baseRFA_AR_LREC$EnGHG

# for CFE, EnGHG needs to be done first by electricity, and then recombined with fuel EnGHG
rs_baseRFA_all_AR[,c("ElecGHGkg_2020_LRE","ElecGHGkg_2025_LRE","ElecGHGkg_2030_LRE","ElecGHGkg_2035_LRE","ElecGHGkg_2040_LRE","ElecGHGkg_2045_LRE","ElecGHGkg_2050_LRE","ElecGHGkg_2055_LRE","ElecGHGkg_2060_LRE")]<-1000* 
  (rs_baseRFA_all_AR$base_weight*rs_baseRFA_all_AR[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*
  (rs_baseRFA_all_AR$Elec_GJ*rs_baseRFA_all_AR[,c("GHG_int_2020_LRE", "GHG_int_2025_LRE","GHG_int_2030_LRE","GHG_int_2035_LRE","GHG_int_2040_LRE","GHG_int_2045_LRE","GHG_int_2050_LRE","GHG_int_2055_LRE","GHG_int_2060_LRE")])

rs_baseRFA_all_AR[,c("ElecGHGkg_2020_CFE","ElecGHGkg_2025_CFE","ElecGHGkg_2030_CFE","ElecGHGkg_2035_CFE","ElecGHGkg_2040_CFE","ElecGHGkg_2045_CFE","ElecGHGkg_2050_CFE","ElecGHGkg_2055_CFE","ElecGHGkg_2060_CFE")]<-1000* 
  (rs_baseRFA_all_AR$base_weight*rs_baseRFA_all_AR[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*
  (rs_baseRFA_all_AR$Elec_GJ*rs_baseRFA_all_AR[,c("GHG_int_2020_CFE", "GHG_int_2025_CFE","GHG_int_2030_CFE","GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")])

GHGelec_baseRFA_AR_LRE<-data.frame(Year=seq(2020,2060,5),ElGHG=1e-9*colSums(rs_baseRFA_all_AR[,212:220])) # emissions in Mt 
GHGelec_baseRFA_AR_LRE<-data.frame(data.frame(ElGHG=with(select(GHGelec_baseRFA_AR_LRE,Year,ElGHG),spline(Year,ElGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="A",RenScen="AR",ElecScen="LRE")
names(GHGelec_baseRFA_AR_LRE)[1:2]<-c("Year","ElGHG")

GHGelec_baseRFA_AR_CFE<-data.frame(Year=seq(2020,2060,5),ElGHG=1e-9*colSums(rs_baseRFA_all_AR[,221:229])) # emissions in Mt 
GHGelec_baseRFA_AR_CFE<-data.frame(data.frame(ElGHG=with(select(GHGelec_baseRFA_AR_CFE,Year,ElGHG),spline(Year,ElGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="A",RenScen="AR",ElecScen="CFE")
names(GHGelec_baseRFA_AR_CFE)[1:2]<-c("Year","ElGHG")

GHGelec_baseRFA_AR_CFE$ElGHG[1:6]<-GHGelec_baseRFA_AR_LRE$ElGHG[1:6] # 2020:2025 is same in CFE as in LRE
GHGelec_baseRFA_AR_CFE$ElGHG[16:41]<-0 # 2035:2060 is 0 in CFE

GHG_baseRFA_AR_CFE<-GHG_baseRFA_AR_LREC
GHG_baseRFA_AR_CFE$ElecScen<-"CFE"
GHG_baseRFA_AR_CFE$EnGHG<-GHG_baseRFA_AR_LREC$EnGHG-GHGelec_baseRFA_AR_LRE$ElGHG+GHGelec_baseRFA_AR_CFE$ElGHG # energy emissions equal total LRE enGHG - LRE elGHG + CFE elGHG
GHG_baseRFA_AR_CFE$EmGHG<-us_RFA_FA$GHG_NC*1e-9
GHG_baseRFA_AR_CFE$EmGHG[41]<-GHG_baseRFA_AR_CFE$EmGHG[40]
GHG_baseRFA_AR_CFE$RenGHG<-renGHGall[renGHGall$Scen=="Base_Adv",]$MtCO2e
GHG_baseRFA_AR_CFE$TotGHG<-GHG_baseRFA_AR_CFE$EmGHG+GHG_baseRFA_AR_CFE$RenGHG+GHG_baseRFA_AR_CFE$EnGHG

# RFA ER
GHG_baseRFA_ER<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_baseRFA_all_ER[,176:184])) # emissions in Mt 
GHG_baseRFA_ER<-data.frame(data.frame(EnGHG=with(select(GHG_baseRFA_ER,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="B",RenScen="ER",ElecScen="MC")
names(GHG_baseRFA_ER)[1:2]<-c("Year","EnGHG")
GHG_baseRFA_ER$EmGHG<-us_RFA_FA$GHG_NC*1e-9
GHG_baseRFA_ER$EmGHG[41]<-GHG_baseRFA_ER$EmGHG[40]
GHG_baseRFA_ER$RenGHG<-renGHGall[renGHGall$Scen=="Base_Ext",]$MtCO2e
GHG_baseRFA_ER$TotGHG<-GHG_baseRFA_ER$EmGHG+GHG_baseRFA_ER$RenGHG+GHG_baseRFA_ER$EnGHG

GHG_baseRFA_ER_LREC<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_baseRFA_all_ER[,185:193])) # emissions in Mt 
GHG_baseRFA_ER_LREC<-data.frame(data.frame(EnGHG=with(select(GHG_baseRFA_ER_LREC,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="B",RenScen="ER",ElecScen="LREC")
names(GHG_baseRFA_ER_LREC)[1:2]<-c("Year","EnGHG")
GHG_baseRFA_ER_LREC$EmGHG<-us_RFA_FA$GHG_NC*1e-9
GHG_baseRFA_ER_LREC$EmGHG[41]<-GHG_baseRFA_ER_LREC$EmGHG[40]
GHG_baseRFA_ER_LREC$RenGHG<-renGHGall[renGHGall$Scen=="Base_Ext",]$MtCO2e
GHG_baseRFA_ER_LREC$TotGHG<-GHG_baseRFA_ER_LREC$EmGHG+GHG_baseRFA_ER_LREC$RenGHG+GHG_baseRFA_ER_LREC$EnGHG

# for CFE, EnGHG needs to be done first by electricity, and then recombined with fuel EnGHG
rs_baseRFA_all_ER[,c("ElecGHGkg_2020_LRE","ElecGHGkg_2025_LRE","ElecGHGkg_2030_LRE","ElecGHGkg_2035_LRE","ElecGHGkg_2040_LRE","ElecGHGkg_2045_LRE","ElecGHGkg_2050_LRE","ElecGHGkg_2055_LRE","ElecGHGkg_2060_LRE")]<-1000* 
  (rs_baseRFA_all_ER$base_weight*rs_baseRFA_all_ER[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*
  (rs_baseRFA_all_ER$Elec_GJ*rs_baseRFA_all_ER[,c("GHG_int_2020_LRE", "GHG_int_2025_LRE","GHG_int_2030_LRE","GHG_int_2035_LRE","GHG_int_2040_LRE","GHG_int_2045_LRE","GHG_int_2050_LRE","GHG_int_2055_LRE","GHG_int_2060_LRE")])

rs_baseRFA_all_ER[,c("ElecGHGkg_2020_CFE","ElecGHGkg_2025_CFE","ElecGHGkg_2030_CFE","ElecGHGkg_2035_CFE","ElecGHGkg_2040_CFE","ElecGHGkg_2045_CFE","ElecGHGkg_2050_CFE","ElecGHGkg_2055_CFE","ElecGHGkg_2060_CFE")]<-1000* 
  (rs_baseRFA_all_ER$base_weight*rs_baseRFA_all_ER[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*
  (rs_baseRFA_all_ER$Elec_GJ*rs_baseRFA_all_ER[,c("GHG_int_2020_CFE", "GHG_int_2025_CFE","GHG_int_2030_CFE","GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")])

GHGelec_baseRFA_ER_LRE<-data.frame(Year=seq(2020,2060,5),ElGHG=1e-9*colSums(rs_baseRFA_all_ER[,212:220])) # emissions in Mt 
GHGelec_baseRFA_ER_LRE<-data.frame(data.frame(ElGHG=with(select(GHGelec_baseRFA_ER_LRE,Year,ElGHG),spline(Year,ElGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="A",RenScen="ER",ElecScen="LRE")
names(GHGelec_baseRFA_ER_LRE)[1:2]<-c("Year","ElGHG")

GHGelec_baseRFA_ER_CFE<-data.frame(Year=seq(2020,2060,5),ElGHG=1e-9*colSums(rs_baseRFA_all_ER[,221:229])) # emissions in Mt 
GHGelec_baseRFA_ER_CFE<-data.frame(data.frame(ElGHG=with(select(GHGelec_baseRFA_ER_CFE,Year,ElGHG),spline(Year,ElGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="A",RenScen="ER",ElecScen="CFE")
names(GHGelec_baseRFA_ER_CFE)[1:2]<-c("Year","ElGHG")

GHGelec_baseRFA_ER_CFE$ElGHG[1:6]<-GHGelec_baseRFA_ER_LRE$ElGHG[1:6] # 2020:2025 is same in CFE as in LRE
GHGelec_baseRFA_ER_CFE$ElGHG[16:41]<-0 # 2035:2060 is 0 in CFE

GHG_baseRFA_ER_CFE<-GHG_baseRFA_ER_LREC
GHG_baseRFA_ER_CFE$ElecScen<-"CFE"
GHG_baseRFA_ER_CFE$EnGHG<-GHG_baseRFA_ER_LREC$EnGHG-GHGelec_baseRFA_ER_LRE$ElGHG+GHGelec_baseRFA_ER_CFE$ElGHG # energy emissions equal total LRE enGHG - LRE elGHG + CFE elGHG
GHG_baseRFA_ER_CFE$EmGHG<-us_RFA_FA$GHG_NC*1e-9
GHG_baseRFA_ER_CFE$EmGHG[41]<-GHG_baseRFA_ER_CFE$EmGHG[40]
GHG_baseRFA_ER_CFE$RenGHG<-renGHGall[renGHGall$Scen=="Base_Ext",]$MtCO2e
GHG_baseRFA_ER_CFE$TotGHG<-GHG_baseRFA_ER_CFE$EmGHG+GHG_baseRFA_ER_CFE$RenGHG+GHG_baseRFA_ER_CFE$EnGHG

# hi DR
# add in GHG intensities for 2035 CFE
rs_hiDRRFA_all_RR[,c("GHG_int_2020_CFE","GHG_int_2025_CFE")]<-rs_hiDRRFA_all_RR[,c("GHG_int_2020_LRE","GHG_int_2025_LRE")]
rs_hiDRRFA_all_RR[,c("GHG_int_2030_CFE")]<-0.5*rs_hiDRRFA_all_RR[,c("GHG_int_2025_LRE")]
rs_hiDRRFA_all_RR[,c("GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")]<-0

rs_hiDRRFA_all_AR[,c("GHG_int_2020_CFE","GHG_int_2025_CFE")]<-rs_hiDRRFA_all_AR[,c("GHG_int_2020_LRE","GHG_int_2025_LRE")]
rs_hiDRRFA_all_AR[,c("GHG_int_2030_CFE")]<-0.5*rs_hiDRRFA_all_AR[,c("GHG_int_2025_LRE")]
rs_hiDRRFA_all_AR[,c("GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")]<-0

rs_hiDRRFA_all_ER[,c("GHG_int_2020_CFE","GHG_int_2025_CFE")]<-rs_hiDRRFA_all_ER[,c("GHG_int_2020_LRE","GHG_int_2025_LRE")]
rs_hiDRRFA_all_ER[,c("GHG_int_2030_CFE")]<-0.5*rs_hiDRRFA_all_ER[,c("GHG_int_2025_LRE")]
rs_hiDRRFA_all_ER[,c("GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")]<-0

# add in GHG emissions for CFE
rs_hiDRRFA_all_RR[,c("EnGHGkg_hiDR_2020_CFE","EnGHGkg_hiDR_2025_CFE","EnGHGkg_hiDR_2030_CFE","EnGHGkg_hiDR_2035_CFE","EnGHGkg_hiDR_2040_CFE","EnGHGkg_hiDR_2045_CFE","EnGHGkg_hiDR_2050_CFE","EnGHGkg_hiDR_2055_CFE","EnGHGkg_hiDR_2060_CFE")]<-1000* 
  (rs_hiDRRFA_all_RR$base_weight*rs_hiDRRFA_all_RR[,c("whiDR_2020",  "whiDR_2025", "whiDR_2030", "whiDR_2035", "whiDR_2040", "whiDR_2045", "whiDR_2050", "whiDR_2055", "whiDR_2060")])*
  (rs_hiDRRFA_all_RR$Elec_GJ*rs_hiDRRFA_all_RR[,c("GHG_int_2020_CFE", "GHG_int_2025_CFE","GHG_int_2030_CFE","GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")]+
     matrix(rep(rs_hiDRRFA_all_RR$Gas_GJ*GHGI_NG,9),nrow(rs_hiDRRFA_all_RR),9)+ matrix(rep(rs_hiDRRFA_all_RR$Oil_GJ*GHGI_FO,9),nrow(rs_hiDRRFA_all_RR),9)+ matrix(rep(rs_hiDRRFA_all_RR$Prop_GJ*GHGI_LP,9),nrow(rs_hiDRRFA_all_RR),9))

rs_hiDRRFA_all_AR[,c("EnGHGkg_hiDR_2020_CFE","EnGHGkg_hiDR_2025_CFE","EnGHGkg_hiDR_2030_CFE","EnGHGkg_hiDR_2035_CFE","EnGHGkg_hiDR_2040_CFE","EnGHGkg_hiDR_2045_CFE","EnGHGkg_hiDR_2050_CFE","EnGHGkg_hiDR_2055_CFE","EnGHGkg_hiDR_2060_CFE")]<-1000* 
  (rs_hiDRRFA_all_AR$base_weight*rs_hiDRRFA_all_AR[,c("whiDR_2020",  "whiDR_2025", "whiDR_2030", "whiDR_2035", "whiDR_2040", "whiDR_2045", "whiDR_2050", "whiDR_2055", "whiDR_2060")])*
  (rs_hiDRRFA_all_AR$Elec_GJ*rs_hiDRRFA_all_AR[,c("GHG_int_2020_CFE", "GHG_int_2025_CFE","GHG_int_2030_CFE","GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")]+
     matrix(rep(rs_hiDRRFA_all_AR$Gas_GJ*GHGI_NG,9),nrow(rs_hiDRRFA_all_AR),9)+ matrix(rep(rs_hiDRRFA_all_AR$Oil_GJ*GHGI_FO,9),nrow(rs_hiDRRFA_all_AR),9)+ matrix(rep(rs_hiDRRFA_all_AR$Prop_GJ*GHGI_LP,9),nrow(rs_hiDRRFA_all_AR),9))

rs_hiDRRFA_all_ER[,c("EnGHGkg_hiDR_2020_CFE","EnGHGkg_hiDR_2025_CFE","EnGHGkg_hiDR_2030_CFE","EnGHGkg_hiDR_2035_CFE","EnGHGkg_hiDR_2040_CFE","EnGHGkg_hiDR_2045_CFE","EnGHGkg_hiDR_2050_CFE","EnGHGkg_hiDR_2055_CFE","EnGHGkg_hiDR_2060_CFE")]<-1000*
  (rs_hiDRRFA_all_ER$base_weight*rs_hiDRRFA_all_ER[,c("whiDR_2020",  "whiDR_2025", "whiDR_2030", "whiDR_2035", "whiDR_2040", "whiDR_2045", "whiDR_2050", "whiDR_2055", "whiDR_2060")])*
  (rs_hiDRRFA_all_ER$Elec_GJ*rs_hiDRRFA_all_ER[,c("GHG_int_2020_CFE", "GHG_int_2025_CFE","GHG_int_2030_CFE","GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")]+
     matrix(rep(rs_hiDRRFA_all_ER$Gas_GJ*GHGI_NG,9),nrow(rs_hiDRRFA_all_ER),9)+ matrix(rep(rs_hiDRRFA_all_ER$Oil_GJ*GHGI_FO,9),nrow(rs_hiDRRFA_all_ER),9)+ matrix(rep(rs_hiDRRFA_all_ER$Prop_GJ*GHGI_LP,9),nrow(rs_hiDRRFA_all_ER),9))

# start compiling emissions
GHG_hiDRRFA_RR<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_hiDRRFA_all_RR[,176:184])) # emissions in Mt 
GHG_hiDRRFA_RR<-data.frame(data.frame(EnGHG=with(select(GHG_hiDRRFA_RR,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=2,CharScen="B",RenScen="RR",ElecScen="MC")
names(GHG_hiDRRFA_RR)[1:2]<-c("Year","EnGHG")
GHG_hiDRRFA_RR$EmGHG<-us_hiDR_RFA_FA$GHG_NC*1e-9
GHG_hiDRRFA_RR$EmGHG[41]<-GHG_hiDRRFA_RR$EmGHG[40]
GHG_hiDRRFA_RR$RenGHG<-renGHGall[renGHGall$Scen=="hiTO_Reg",]$MtCO2e
GHG_hiDRRFA_RR$TotGHG<-GHG_hiDRRFA_RR$EmGHG+GHG_hiDRRFA_RR$RenGHG+GHG_hiDRRFA_RR$EnGHG

GHG_hiDRRFA_RR_LREC<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_hiDRRFA_all_RR[,185:193])) # emissions in Mt 
GHG_hiDRRFA_RR_LREC<-data.frame(data.frame(EnGHG=with(select(GHG_hiDRRFA_RR_LREC,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=2,CharScen="B",RenScen="RR",ElecScen="LREC")
names(GHG_hiDRRFA_RR_LREC)[1:2]<-c("Year","EnGHG")
GHG_hiDRRFA_RR_LREC$EmGHG<-us_hiDR_RFA_FA$GHG_NC*1e-9
GHG_hiDRRFA_RR_LREC$EmGHG[41]<-GHG_hiDRRFA_RR_LREC$EmGHG[40]
GHG_hiDRRFA_RR_LREC$RenGHG<-renGHGall[renGHGall$Scen=="hiTO_Reg",]$MtCO2e
GHG_hiDRRFA_RR_LREC$TotGHG<-GHG_hiDRRFA_RR_LREC$EmGHG+GHG_hiDRRFA_RR_LREC$RenGHG+GHG_hiDRRFA_RR_LREC$EnGHG

# for CFE, EnGHG needs to be done first by electricity, and then recombined with fuel EnGHG
rs_hiDRRFA_all_RR[,c("ElecGHGkg_2020_LRE","ElecGHGkg_2025_LRE","ElecGHGkg_2030_LRE","ElecGHGkg_2035_LRE","ElecGHGkg_2040_LRE","ElecGHGkg_2045_LRE","ElecGHGkg_2050_LRE","ElecGHGkg_2055_LRE","ElecGHGkg_2060_LRE")]<-1000* 
  (rs_hiDRRFA_all_RR$base_weight*rs_hiDRRFA_all_RR[,c("whiDR_2020",  "whiDR_2025", "whiDR_2030", "whiDR_2035", "whiDR_2040", "whiDR_2045", "whiDR_2050", "whiDR_2055", "whiDR_2060")])*
  (rs_hiDRRFA_all_RR$Elec_GJ*rs_hiDRRFA_all_RR[,c("GHG_int_2020_LRE", "GHG_int_2025_LRE","GHG_int_2030_LRE","GHG_int_2035_LRE","GHG_int_2040_LRE","GHG_int_2045_LRE","GHG_int_2050_LRE","GHG_int_2055_LRE","GHG_int_2060_LRE")])

rs_hiDRRFA_all_RR[,c("ElecGHGkg_2020_CFE","ElecGHGkg_2025_CFE","ElecGHGkg_2030_CFE","ElecGHGkg_2035_CFE","ElecGHGkg_2040_CFE","ElecGHGkg_2045_CFE","ElecGHGkg_2050_CFE","ElecGHGkg_2055_CFE","ElecGHGkg_2060_CFE")]<-1000* 
  (rs_hiDRRFA_all_RR$base_weight*rs_hiDRRFA_all_RR[,c("whiDR_2020",  "whiDR_2025", "whiDR_2030", "whiDR_2035", "whiDR_2040", "whiDR_2045", "whiDR_2050", "whiDR_2055", "whiDR_2060")])*
  (rs_hiDRRFA_all_RR$Elec_GJ*rs_hiDRRFA_all_RR[,c("GHG_int_2020_CFE", "GHG_int_2025_CFE","GHG_int_2030_CFE","GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")])

GHGelec_hiDRRFA_RR_LRE<-data.frame(Year=seq(2020,2060,5),ElGHG=1e-9*colSums(rs_hiDRRFA_all_RR[,212:220])) # emissions in Mt 
GHGelec_hiDRRFA_RR_LRE<-data.frame(data.frame(ElGHG=with(select(GHGelec_hiDRRFA_RR_LRE,Year,ElGHG),spline(Year,ElGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="A",RenScen="RR",ElecScen="LRE")
names(GHGelec_hiDRRFA_RR_LRE)[1:2]<-c("Year","ElGHG")

GHGelec_hiDRRFA_RR_CFE<-data.frame(Year=seq(2020,2060,5),ElGHG=1e-9*colSums(rs_hiDRRFA_all_RR[,221:229])) # emissions in Mt 
GHGelec_hiDRRFA_RR_CFE<-data.frame(data.frame(ElGHG=with(select(GHGelec_hiDRRFA_RR_CFE,Year,ElGHG),spline(Year,ElGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="A",RenScen="RR",ElecScen="CFE")
names(GHGelec_hiDRRFA_RR_CFE)[1:2]<-c("Year","ElGHG")

GHGelec_hiDRRFA_RR_CFE$ElGHG[1:6]<-GHGelec_hiDRRFA_RR_LRE$ElGHG[1:6] # 2020:2025 is same in CFE as in LRE
GHGelec_hiDRRFA_RR_CFE$ElGHG[16:41]<-0 # 2035:2060 is 0 in CFE

GHG_hiDRRFA_RR_CFE<-GHG_hiDRRFA_RR_LREC
GHG_hiDRRFA_RR_CFE$ElecScen<-"CFE"
GHG_hiDRRFA_RR_CFE$EnGHG<-GHG_hiDRRFA_RR_LREC$EnGHG-GHGelec_hiDRRFA_RR_LRE$ElGHG+GHGelec_hiDRRFA_RR_CFE$ElGHG # energy emissions equal total LRE enGHG - LRE elGHG + CFE elGHG
GHG_hiDRRFA_RR_CFE$EmGHG<-us_hiDR_RFA_FA$GHG_NC*1e-9 # make sure this refers to the correct us_* file
GHG_hiDRRFA_RR_CFE$EmGHG[41]<-GHG_hiDRRFA_RR_CFE$EmGHG[40]
GHG_hiDRRFA_RR_CFE$RenGHG<-renGHGall[renGHGall$Scen=="hiTO_Reg",]$MtCO2e
GHG_hiDRRFA_RR_CFE$TotGHG<-GHG_hiDRRFA_RR_CFE$EmGHG+GHG_hiDRRFA_RR_CFE$RenGHG+GHG_hiDRRFA_RR_CFE$EnGHG

# hiDRRFA AR
GHG_hiDRRFA_AR<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_hiDRRFA_all_AR[,176:184])) # emissions in Mt 
GHG_hiDRRFA_AR<-data.frame(data.frame(EnGHG=with(select(GHG_hiDRRFA_AR,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=2,CharScen="B",RenScen="AR",ElecScen="MC")
names(GHG_hiDRRFA_AR)[1:2]<-c("Year","EnGHG")
GHG_hiDRRFA_AR$EmGHG<-us_hiDR_RFA_FA$GHG_NC*1e-9
GHG_hiDRRFA_AR$EmGHG[41]<-GHG_hiDRRFA_AR$EmGHG[40]
GHG_hiDRRFA_AR$RenGHG<-renGHGall[renGHGall$Scen=="hiTO_Adv",]$MtCO2e
GHG_hiDRRFA_AR$TotGHG<-GHG_hiDRRFA_AR$EmGHG+GHG_hiDRRFA_AR$RenGHG+GHG_hiDRRFA_AR$EnGHG

GHG_hiDRRFA_AR_LREC<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_hiDRRFA_all_AR[,185:193])) # emissions in Mt 
GHG_hiDRRFA_AR_LREC<-data.frame(data.frame(EnGHG=with(select(GHG_hiDRRFA_AR_LREC,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=2,CharScen="B",RenScen="AR",ElecScen="LREC")
names(GHG_hiDRRFA_AR_LREC)[1:2]<-c("Year","EnGHG")
GHG_hiDRRFA_AR_LREC$EmGHG<-us_hiDR_RFA_FA$GHG_NC*1e-9
GHG_hiDRRFA_AR_LREC$EmGHG[41]<-GHG_hiDRRFA_AR_LREC$EmGHG[40]
GHG_hiDRRFA_AR_LREC$RenGHG<-renGHGall[renGHGall$Scen=="hiTO_Adv",]$MtCO2e
GHG_hiDRRFA_AR_LREC$TotGHG<-GHG_hiDRRFA_AR_LREC$EmGHG+GHG_hiDRRFA_AR_LREC$RenGHG+GHG_hiDRRFA_AR_LREC$EnGHG

# for CFE, EnGHG needs to be done first by electricity, and then recombined with fuel EnGHG
rs_hiDRRFA_all_AR[,c("ElecGHGkg_2020_LRE","ElecGHGkg_2025_LRE","ElecGHGkg_2030_LRE","ElecGHGkg_2035_LRE","ElecGHGkg_2040_LRE","ElecGHGkg_2045_LRE","ElecGHGkg_2050_LRE","ElecGHGkg_2055_LRE","ElecGHGkg_2060_LRE")]<-1000* 
  (rs_hiDRRFA_all_AR$base_weight*rs_hiDRRFA_all_AR[,c("whiDR_2020",  "whiDR_2025", "whiDR_2030", "whiDR_2035", "whiDR_2040", "whiDR_2045", "whiDR_2050", "whiDR_2055", "whiDR_2060")])*
  (rs_hiDRRFA_all_AR$Elec_GJ*rs_hiDRRFA_all_AR[,c("GHG_int_2020_LRE", "GHG_int_2025_LRE","GHG_int_2030_LRE","GHG_int_2035_LRE","GHG_int_2040_LRE","GHG_int_2045_LRE","GHG_int_2050_LRE","GHG_int_2055_LRE","GHG_int_2060_LRE")])

rs_hiDRRFA_all_AR[,c("ElecGHGkg_2020_CFE","ElecGHGkg_2025_CFE","ElecGHGkg_2030_CFE","ElecGHGkg_2035_CFE","ElecGHGkg_2040_CFE","ElecGHGkg_2045_CFE","ElecGHGkg_2050_CFE","ElecGHGkg_2055_CFE","ElecGHGkg_2060_CFE")]<-1000* 
  (rs_hiDRRFA_all_AR$base_weight*rs_hiDRRFA_all_AR[,c("whiDR_2020",  "whiDR_2025", "whiDR_2030", "whiDR_2035", "whiDR_2040", "whiDR_2045", "whiDR_2050", "whiDR_2055", "whiDR_2060")])*
  (rs_hiDRRFA_all_AR$Elec_GJ*rs_hiDRRFA_all_AR[,c("GHG_int_2020_CFE", "GHG_int_2025_CFE","GHG_int_2030_CFE","GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")])

GHGelec_hiDRRFA_AR_LRE<-data.frame(Year=seq(2020,2060,5),ElGHG=1e-9*colSums(rs_hiDRRFA_all_AR[,212:220])) # emissions in Mt 
GHGelec_hiDRRFA_AR_LRE<-data.frame(data.frame(ElGHG=with(select(GHGelec_hiDRRFA_AR_LRE,Year,ElGHG),spline(Year,ElGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="A",RenScen="RR",ElecScen="LRE")
names(GHGelec_hiDRRFA_AR_LRE)[1:2]<-c("Year","ElGHG")

GHGelec_hiDRRFA_AR_CFE<-data.frame(Year=seq(2020,2060,5),ElGHG=1e-9*colSums(rs_hiDRRFA_all_AR[,221:229])) # emissions in Mt 
GHGelec_hiDRRFA_AR_CFE<-data.frame(data.frame(ElGHG=with(select(GHGelec_hiDRRFA_AR_CFE,Year,ElGHG),spline(Year,ElGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="A",RenScen="RR",ElecScen="CFE")
names(GHGelec_hiDRRFA_AR_CFE)[1:2]<-c("Year","ElGHG")

GHGelec_hiDRRFA_AR_CFE$ElGHG[1:6]<-GHGelec_hiDRRFA_AR_LRE$ElGHG[1:6] # 2020:2025 is same in CFE as in LRE
GHGelec_hiDRRFA_AR_CFE$ElGHG[16:41]<-0 # 2035:2060 is 0 in CFE

GHG_hiDRRFA_AR_CFE<-GHG_hiDRRFA_AR_LREC
GHG_hiDRRFA_AR_CFE$ElecScen<-"CFE"
GHG_hiDRRFA_AR_CFE$EnGHG<-GHG_hiDRRFA_AR_LREC$EnGHG-GHGelec_hiDRRFA_AR_LRE$ElGHG+GHGelec_hiDRRFA_AR_CFE$ElGHG # energy emissions equal total LRE enGHG - LRE elGHG + CFE elGHG
GHG_hiDRRFA_AR_CFE$EmGHG<-us_hiDR_RFA_FA$GHG_NC*1e-9 # make sure this refers to the correct us_* file
GHG_hiDRRFA_AR_CFE$EmGHG[41]<-GHG_hiDRRFA_AR_CFE$EmGHG[40]
GHG_hiDRRFA_AR_CFE$RenGHG<-renGHGall[renGHGall$Scen=="hiTO_Adv",]$MtCO2e
GHG_hiDRRFA_AR_CFE$TotGHG<-GHG_hiDRRFA_AR_CFE$EmGHG+GHG_hiDRRFA_AR_CFE$RenGHG+GHG_hiDRRFA_AR_CFE$EnGHG

# hiDRRFA ER
GHG_hiDRRFA_ER<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_hiDRRFA_all_ER[,176:184])) # emissions in Mt 
GHG_hiDRRFA_ER<-data.frame(data.frame(EnGHG=with(select(GHG_hiDRRFA_ER,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=2,CharScen="B",RenScen="ER",ElecScen="MC")
names(GHG_hiDRRFA_ER)[1:2]<-c("Year","EnGHG")
GHG_hiDRRFA_ER$EmGHG<-us_hiDR_RFA_FA$GHG_NC*1e-9
GHG_hiDRRFA_ER$EmGHG[41]<-GHG_hiDRRFA_ER$EmGHG[40]
GHG_hiDRRFA_ER$RenGHG<-renGHGall[renGHGall$Scen=="hiTO_Ext",]$MtCO2e
GHG_hiDRRFA_ER$TotGHG<-GHG_hiDRRFA_ER$EmGHG+GHG_hiDRRFA_ER$RenGHG+GHG_hiDRRFA_ER$EnGHG

GHG_hiDRRFA_ER_LREC<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_hiDRRFA_all_ER[,185:193])) # emissions in Mt 
GHG_hiDRRFA_ER_LREC<-data.frame(data.frame(EnGHG=with(select(GHG_hiDRRFA_ER_LREC,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=2,CharScen="B",RenScen="ER",ElecScen="LREC")
names(GHG_hiDRRFA_ER_LREC)[1:2]<-c("Year","EnGHG")
GHG_hiDRRFA_ER_LREC$EmGHG<-us_hiDR_RFA_FA$GHG_NC*1e-9
GHG_hiDRRFA_ER_LREC$EmGHG[41]<-GHG_hiDRRFA_ER_LREC$EmGHG[40]
GHG_hiDRRFA_ER_LREC$RenGHG<-renGHGall[renGHGall$Scen=="hiTO_Ext",]$MtCO2e
GHG_hiDRRFA_ER_LREC$TotGHG<-GHG_hiDRRFA_ER_LREC$EmGHG+GHG_hiDRRFA_ER_LREC$RenGHG+GHG_hiDRRFA_ER_LREC$EnGHG

# for CFE, EnGHG needs to be done first by electricity, and then recombined with fuel EnGHG
rs_hiDRRFA_all_ER[,c("ElecGHGkg_2020_LRE","ElecGHGkg_2025_LRE","ElecGHGkg_2030_LRE","ElecGHGkg_2035_LRE","ElecGHGkg_2040_LRE","ElecGHGkg_2045_LRE","ElecGHGkg_2050_LRE","ElecGHGkg_2055_LRE","ElecGHGkg_2060_LRE")]<-1000* 
  (rs_hiDRRFA_all_ER$base_weight*rs_hiDRRFA_all_ER[,c("whiDR_2020",  "whiDR_2025", "whiDR_2030", "whiDR_2035", "whiDR_2040", "whiDR_2045", "whiDR_2050", "whiDR_2055", "whiDR_2060")])*
  (rs_hiDRRFA_all_ER$Elec_GJ*rs_hiDRRFA_all_ER[,c("GHG_int_2020_LRE", "GHG_int_2025_LRE","GHG_int_2030_LRE","GHG_int_2035_LRE","GHG_int_2040_LRE","GHG_int_2045_LRE","GHG_int_2050_LRE","GHG_int_2055_LRE","GHG_int_2060_LRE")])

rs_hiDRRFA_all_ER[,c("ElecGHGkg_2020_CFE","ElecGHGkg_2025_CFE","ElecGHGkg_2030_CFE","ElecGHGkg_2035_CFE","ElecGHGkg_2040_CFE","ElecGHGkg_2045_CFE","ElecGHGkg_2050_CFE","ElecGHGkg_2055_CFE","ElecGHGkg_2060_CFE")]<-1000* 
  (rs_hiDRRFA_all_ER$base_weight*rs_hiDRRFA_all_ER[,c("whiDR_2020",  "whiDR_2025", "whiDR_2030", "whiDR_2035", "whiDR_2040", "whiDR_2045", "whiDR_2050", "whiDR_2055", "whiDR_2060")])*
  (rs_hiDRRFA_all_ER$Elec_GJ*rs_hiDRRFA_all_ER[,c("GHG_int_2020_CFE", "GHG_int_2025_CFE","GHG_int_2030_CFE","GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")])

GHGelec_hiDRRFA_ER_LRE<-data.frame(Year=seq(2020,2060,5),ElGHG=1e-9*colSums(rs_hiDRRFA_all_ER[,212:220])) # emissions in Mt 
GHGelec_hiDRRFA_ER_LRE<-data.frame(data.frame(ElGHG=with(select(GHGelec_hiDRRFA_ER_LRE,Year,ElGHG),spline(Year,ElGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="A",RenScen="RR",ElecScen="LRE")
names(GHGelec_hiDRRFA_ER_LRE)[1:2]<-c("Year","ElGHG")

GHGelec_hiDRRFA_ER_CFE<-data.frame(Year=seq(2020,2060,5),ElGHG=1e-9*colSums(rs_hiDRRFA_all_ER[,221:229])) # emissions in Mt 
GHGelec_hiDRRFA_ER_CFE<-data.frame(data.frame(ElGHG=with(select(GHGelec_hiDRRFA_ER_CFE,Year,ElGHG),spline(Year,ElGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="A",RenScen="RR",ElecScen="CFE")
names(GHGelec_hiDRRFA_ER_CFE)[1:2]<-c("Year","ElGHG")

GHGelec_hiDRRFA_ER_CFE$ElGHG[1:6]<-GHGelec_hiDRRFA_ER_LRE$ElGHG[1:6] # 2020:2025 is same in CFE as in LRE
GHGelec_hiDRRFA_ER_CFE$ElGHG[16:41]<-0 # 2035:2060 is 0 in CFE

GHG_hiDRRFA_ER_CFE<-GHG_hiDRRFA_ER_LREC
GHG_hiDRRFA_ER_CFE$ElecScen<-"CFE"
GHG_hiDRRFA_ER_CFE$EnGHG<-GHG_hiDRRFA_ER_LREC$EnGHG-GHGelec_hiDRRFA_ER_LRE$ElGHG+GHGelec_hiDRRFA_ER_CFE$ElGHG # energy emissions equal total LRE enGHG - LRE elGHG + CFE elGHG
GHG_hiDRRFA_ER_CFE$EmGHG<-us_hiDR_RFA_FA$GHG_NC*1e-9 # make sure this refers to the correct us_* file
GHG_hiDRRFA_ER_CFE$EmGHG[41]<-GHG_hiDRRFA_ER_CFE$EmGHG[40]
GHG_hiDRRFA_ER_CFE$RenGHG<-renGHGall[renGHGall$Scen=="hiTO_Ext",]$MtCO2e
GHG_hiDRRFA_ER_CFE$TotGHG<-GHG_hiDRRFA_ER_CFE$EmGHG+GHG_hiDRRFA_ER_CFE$RenGHG+GHG_hiDRRFA_ER_CFE$EnGHG

# hi MF
# add in GHG intensities for 2035 CFE
rs_hiMFRFA_all_RR[,c("GHG_int_2020_CFE","GHG_int_2025_CFE")]<-rs_hiMFRFA_all_RR[,c("GHG_int_2020_LRE","GHG_int_2025_LRE")]
rs_hiMFRFA_all_RR[,c("GHG_int_2030_CFE")]<-0.5*rs_hiMFRFA_all_RR[,c("GHG_int_2025_LRE")]
rs_hiMFRFA_all_RR[,c("GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")]<-0

rs_hiMFRFA_all_AR[,c("GHG_int_2020_CFE","GHG_int_2025_CFE")]<-rs_hiMFRFA_all_AR[,c("GHG_int_2020_LRE","GHG_int_2025_LRE")]
rs_hiMFRFA_all_AR[,c("GHG_int_2030_CFE")]<-0.5*rs_hiMFRFA_all_AR[,c("GHG_int_2025_LRE")]
rs_hiMFRFA_all_AR[,c("GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")]<-0

rs_hiMFRFA_all_ER[,c("GHG_int_2020_CFE","GHG_int_2025_CFE")]<-rs_hiMFRFA_all_ER[,c("GHG_int_2020_LRE","GHG_int_2025_LRE")]
rs_hiMFRFA_all_ER[,c("GHG_int_2030_CFE")]<-0.5*rs_hiMFRFA_all_ER[,c("GHG_int_2025_LRE")]
rs_hiMFRFA_all_ER[,c("GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")]<-0

# add in GHG emissions for CFE
rs_hiMFRFA_all_RR[,c("EnGHGkg_hiMF_2020_CFE","EnGHGkg_hiMF_2025_CFE","EnGHGkg_hiMF_2030_CFE","EnGHGkg_hiMF_2035_CFE","EnGHGkg_hiMF_2040_CFE","EnGHGkg_hiMF_2045_CFE","EnGHGkg_hiMF_2050_CFE","EnGHGkg_hiMF_2055_CFE","EnGHGkg_hiMF_2060_CFE")]<-1000* 
  (rs_hiMFRFA_all_RR$base_weight*rs_hiMFRFA_all_RR[,c("whiMF_2020",  "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")])*
  (rs_hiMFRFA_all_RR$Elec_GJ*rs_hiMFRFA_all_RR[,c("GHG_int_2020_CFE", "GHG_int_2025_CFE","GHG_int_2030_CFE","GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")]+
     matrix(rep(rs_hiMFRFA_all_RR$Gas_GJ*GHGI_NG,9),nrow(rs_hiMFRFA_all_RR),9)+ matrix(rep(rs_hiMFRFA_all_RR$Oil_GJ*GHGI_FO,9),nrow(rs_hiMFRFA_all_RR),9)+ matrix(rep(rs_hiMFRFA_all_RR$Prop_GJ*GHGI_LP,9),nrow(rs_hiMFRFA_all_RR),9))

rs_hiMFRFA_all_AR[,c("EnGHGkg_hiMF_2020_CFE","EnGHGkg_hiMF_2025_CFE","EnGHGkg_hiMF_2030_CFE","EnGHGkg_hiMF_2035_CFE","EnGHGkg_hiMF_2040_CFE","EnGHGkg_hiMF_2045_CFE","EnGHGkg_hiMF_2050_CFE","EnGHGkg_hiMF_2055_CFE","EnGHGkg_hiMF_2060_CFE")]<-1000* 
  (rs_hiMFRFA_all_AR$base_weight*rs_hiMFRFA_all_AR[,c("whiMF_2020",  "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")])*
  (rs_hiMFRFA_all_AR$Elec_GJ*rs_hiMFRFA_all_AR[,c("GHG_int_2020_CFE", "GHG_int_2025_CFE","GHG_int_2030_CFE","GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")]+
     matrix(rep(rs_hiMFRFA_all_AR$Gas_GJ*GHGI_NG,9),nrow(rs_hiMFRFA_all_AR),9)+ matrix(rep(rs_hiMFRFA_all_AR$Oil_GJ*GHGI_FO,9),nrow(rs_hiMFRFA_all_AR),9)+ matrix(rep(rs_hiMFRFA_all_AR$Prop_GJ*GHGI_LP,9),nrow(rs_hiMFRFA_all_AR),9))

rs_hiMFRFA_all_ER[,c("EnGHGkg_hiMF_2020_CFE","EnGHGkg_hiMF_2025_CFE","EnGHGkg_hiMF_2030_CFE","EnGHGkg_hiMF_2035_CFE","EnGHGkg_hiMF_2040_CFE","EnGHGkg_hiMF_2045_CFE","EnGHGkg_hiMF_2050_CFE","EnGHGkg_hiMF_2055_CFE","EnGHGkg_hiMF_2060_CFE")]<-1000*
  (rs_hiMFRFA_all_ER$base_weight*rs_hiMFRFA_all_ER[,c("whiMF_2020",  "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")])*
  (rs_hiMFRFA_all_ER$Elec_GJ*rs_hiMFRFA_all_ER[,c("GHG_int_2020_CFE", "GHG_int_2025_CFE","GHG_int_2030_CFE","GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")]+
     matrix(rep(rs_hiMFRFA_all_ER$Gas_GJ*GHGI_NG,9),nrow(rs_hiMFRFA_all_ER),9)+ matrix(rep(rs_hiMFRFA_all_ER$Oil_GJ*GHGI_FO,9),nrow(rs_hiMFRFA_all_ER),9)+ matrix(rep(rs_hiMFRFA_all_ER$Prop_GJ*GHGI_LP,9),nrow(rs_hiMFRFA_all_ER),9))
# start compiling emissions
GHG_hiMFRFA_RR<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_hiMFRFA_all_RR[,176:184])) # emissions in Mt 
GHG_hiMFRFA_RR<-data.frame(data.frame(EnGHG=with(select(GHG_hiMFRFA_RR,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=3,CharScen="B",RenScen="RR",ElecScen="MC")
names(GHG_hiMFRFA_RR)[1:2]<-c("Year","EnGHG")
GHG_hiMFRFA_RR$EmGHG<-us_hiMF_RFA_FA$GHG_NC*1e-9
GHG_hiMFRFA_RR$EmGHG[41]<-GHG_hiMFRFA_RR$EmGHG[40]
GHG_hiMFRFA_RR$RenGHG<-renGHGall[renGHGall$Scen=="hiMF_Reg",]$MtCO2e
GHG_hiMFRFA_RR$TotGHG<-GHG_hiMFRFA_RR$EmGHG+GHG_hiMFRFA_RR$RenGHG+GHG_hiMFRFA_RR$EnGHG

GHG_hiMFRFA_RR_LREC<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_hiMFRFA_all_RR[,185:193])) # emissions in Mt 
GHG_hiMFRFA_RR_LREC<-data.frame(data.frame(EnGHG=with(select(GHG_hiMFRFA_RR_LREC,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=3,CharScen="B",RenScen="RR",ElecScen="LREC")
names(GHG_hiMFRFA_RR_LREC)[1:2]<-c("Year","EnGHG")
GHG_hiMFRFA_RR_LREC$EmGHG<-us_hiMF_RFA_FA$GHG_NC*1e-9
GHG_hiMFRFA_RR_LREC$EmGHG[41]<-GHG_hiMFRFA_RR_LREC$EmGHG[40]
GHG_hiMFRFA_RR_LREC$RenGHG<-renGHGall[renGHGall$Scen=="hiMF_Reg",]$MtCO2e
GHG_hiMFRFA_RR_LREC$TotGHG<-GHG_hiMFRFA_RR_LREC$EmGHG+GHG_hiMFRFA_RR_LREC$RenGHG+GHG_hiMFRFA_RR_LREC$EnGHG

# for CFE, EnGHG needs to be done first by electricity, and then recombined with fuel EnGHG
rs_hiMFRFA_all_RR[,c("ElecGHGkg_2020_LRE","ElecGHGkg_2025_LRE","ElecGHGkg_2030_LRE","ElecGHGkg_2035_LRE","ElecGHGkg_2040_LRE","ElecGHGkg_2045_LRE","ElecGHGkg_2050_LRE","ElecGHGkg_2055_LRE","ElecGHGkg_2060_LRE")]<-1000* 
  (rs_hiMFRFA_all_RR$base_weight*rs_hiMFRFA_all_RR[,c("whiMF_2020",  "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")])*
  (rs_hiMFRFA_all_RR$Elec_GJ*rs_hiMFRFA_all_RR[,c("GHG_int_2020_LRE", "GHG_int_2025_LRE","GHG_int_2030_LRE","GHG_int_2035_LRE","GHG_int_2040_LRE","GHG_int_2045_LRE","GHG_int_2050_LRE","GHG_int_2055_LRE","GHG_int_2060_LRE")])

rs_hiMFRFA_all_RR[,c("ElecGHGkg_2020_CFE","ElecGHGkg_2025_CFE","ElecGHGkg_2030_CFE","ElecGHGkg_2035_CFE","ElecGHGkg_2040_CFE","ElecGHGkg_2045_CFE","ElecGHGkg_2050_CFE","ElecGHGkg_2055_CFE","ElecGHGkg_2060_CFE")]<-1000* 
  (rs_hiMFRFA_all_RR$base_weight*rs_hiMFRFA_all_RR[,c("whiMF_2020",  "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")])*
  (rs_hiMFRFA_all_RR$Elec_GJ*rs_hiMFRFA_all_RR[,c("GHG_int_2020_CFE", "GHG_int_2025_CFE","GHG_int_2030_CFE","GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")])

GHGelec_hiMFRFA_RR_LRE<-data.frame(Year=seq(2020,2060,5),ElGHG=1e-9*colSums(rs_hiMFRFA_all_RR[,212:220])) # emissions in Mt 
GHGelec_hiMFRFA_RR_LRE<-data.frame(data.frame(ElGHG=with(select(GHGelec_hiMFRFA_RR_LRE,Year,ElGHG),spline(Year,ElGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="A",RenScen="RR",ElecScen="LRE")
names(GHGelec_hiMFRFA_RR_LRE)[1:2]<-c("Year","ElGHG")

GHGelec_hiMFRFA_RR_CFE<-data.frame(Year=seq(2020,2060,5),ElGHG=1e-9*colSums(rs_hiMFRFA_all_RR[,221:229])) # emissions in Mt 
GHGelec_hiMFRFA_RR_CFE<-data.frame(data.frame(ElGHG=with(select(GHGelec_hiMFRFA_RR_CFE,Year,ElGHG),spline(Year,ElGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="A",RenScen="RR",ElecScen="CFE")
names(GHGelec_hiMFRFA_RR_CFE)[1:2]<-c("Year","ElGHG")

GHGelec_hiMFRFA_RR_CFE$ElGHG[1:6]<-GHGelec_hiMFRFA_RR_LRE$ElGHG[1:6] # 2020:2025 is same in CFE as in LRE
GHGelec_hiMFRFA_RR_CFE$ElGHG[16:41]<-0 # 2035:2060 is 0 in CFE

GHG_hiMFRFA_RR_CFE<-GHG_hiMFRFA_RR_LREC
GHG_hiMFRFA_RR_CFE$ElecScen<-"CFE"
GHG_hiMFRFA_RR_CFE$EnGHG<-GHG_hiMFRFA_RR_LREC$EnGHG-GHGelec_hiMFRFA_RR_LRE$ElGHG+GHGelec_hiMFRFA_RR_CFE$ElGHG # energy emissions equal total LRE enGHG - LRE elGHG + CFE elGHG
GHG_hiMFRFA_RR_CFE$EmGHG<-us_hiMF_RFA_FA$GHG_NC*1e-9 # make sure this refers to the correct us_* file
GHG_hiMFRFA_RR_CFE$EmGHG[41]<-GHG_hiMFRFA_RR_CFE$EmGHG[40]
GHG_hiMFRFA_RR_CFE$RenGHG<-renGHGall[renGHGall$Scen=="hiMF_Reg",]$MtCO2e
GHG_hiMFRFA_RR_CFE$TotGHG<-GHG_hiMFRFA_RR_CFE$EmGHG+GHG_hiMFRFA_RR_CFE$RenGHG+GHG_hiMFRFA_RR_CFE$EnGHG

# hiMFRFA AR
GHG_hiMFRFA_AR<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_hiMFRFA_all_AR[,176:184])) # emissions in Mt 
GHG_hiMFRFA_AR<-data.frame(data.frame(EnGHG=with(select(GHG_hiMFRFA_AR,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=3,CharScen="B",RenScen="AR",ElecScen="MC")
names(GHG_hiMFRFA_AR)[1:2]<-c("Year","EnGHG")
GHG_hiMFRFA_AR$EmGHG<-us_hiMF_RFA_FA$GHG_NC*1e-9
GHG_hiMFRFA_AR$EmGHG[41]<-GHG_hiMFRFA_AR$EmGHG[40]
GHG_hiMFRFA_AR$RenGHG<-renGHGall[renGHGall$Scen=="hiMF_Adv",]$MtCO2e
GHG_hiMFRFA_AR$TotGHG<-GHG_hiMFRFA_AR$EmGHG+GHG_hiMFRFA_AR$RenGHG+GHG_hiMFRFA_AR$EnGHG

GHG_hiMFRFA_AR_LREC<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_hiMFRFA_all_AR[,185:193])) # emissions in Mt 
GHG_hiMFRFA_AR_LREC<-data.frame(data.frame(EnGHG=with(select(GHG_hiMFRFA_AR_LREC,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=3,CharScen="B",RenScen="AR",ElecScen="LREC")
names(GHG_hiMFRFA_AR_LREC)[1:2]<-c("Year","EnGHG")
GHG_hiMFRFA_AR_LREC$EmGHG<-us_hiMF_RFA_FA$GHG_NC*1e-9
GHG_hiMFRFA_AR_LREC$EmGHG[41]<-GHG_hiMFRFA_AR_LREC$EmGHG[40]
GHG_hiMFRFA_AR_LREC$RenGHG<-renGHGall[renGHGall$Scen=="hiMF_Adv",]$MtCO2e
GHG_hiMFRFA_AR_LREC$TotGHG<-GHG_hiMFRFA_AR_LREC$EmGHG+GHG_hiMFRFA_AR_LREC$RenGHG+GHG_hiMFRFA_AR_LREC$EnGHG

# for CFE, EnGHG needs to be done first by electricity, and then recombined with fuel EnGHG
rs_hiMFRFA_all_AR[,c("ElecGHGkg_2020_LRE","ElecGHGkg_2025_LRE","ElecGHGkg_2030_LRE","ElecGHGkg_2035_LRE","ElecGHGkg_2040_LRE","ElecGHGkg_2045_LRE","ElecGHGkg_2050_LRE","ElecGHGkg_2055_LRE","ElecGHGkg_2060_LRE")]<-1000* 
  (rs_hiMFRFA_all_AR$base_weight*rs_hiMFRFA_all_AR[,c("whiMF_2020",  "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")])*
  (rs_hiMFRFA_all_AR$Elec_GJ*rs_hiMFRFA_all_AR[,c("GHG_int_2020_LRE", "GHG_int_2025_LRE","GHG_int_2030_LRE","GHG_int_2035_LRE","GHG_int_2040_LRE","GHG_int_2045_LRE","GHG_int_2050_LRE","GHG_int_2055_LRE","GHG_int_2060_LRE")])

rs_hiMFRFA_all_AR[,c("ElecGHGkg_2020_CFE","ElecGHGkg_2025_CFE","ElecGHGkg_2030_CFE","ElecGHGkg_2035_CFE","ElecGHGkg_2040_CFE","ElecGHGkg_2045_CFE","ElecGHGkg_2050_CFE","ElecGHGkg_2055_CFE","ElecGHGkg_2060_CFE")]<-1000* 
  (rs_hiMFRFA_all_AR$base_weight*rs_hiMFRFA_all_AR[,c("whiMF_2020",  "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")])*
  (rs_hiMFRFA_all_AR$Elec_GJ*rs_hiMFRFA_all_AR[,c("GHG_int_2020_CFE", "GHG_int_2025_CFE","GHG_int_2030_CFE","GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")])

GHGelec_hiMFRFA_AR_LRE<-data.frame(Year=seq(2020,2060,5),ElGHG=1e-9*colSums(rs_hiMFRFA_all_AR[,212:220])) # emissions in Mt 
GHGelec_hiMFRFA_AR_LRE<-data.frame(data.frame(ElGHG=with(select(GHGelec_hiMFRFA_AR_LRE,Year,ElGHG),spline(Year,ElGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="A",RenScen="AR",ElecScen="LRE")
names(GHGelec_hiMFRFA_AR_LRE)[1:2]<-c("Year","ElGHG")

GHGelec_hiMFRFA_AR_CFE<-data.frame(Year=seq(2020,2060,5),ElGHG=1e-9*colSums(rs_hiMFRFA_all_AR[,221:229])) # emissions in Mt 
GHGelec_hiMFRFA_AR_CFE<-data.frame(data.frame(ElGHG=with(select(GHGelec_hiMFRFA_AR_CFE,Year,ElGHG),spline(Year,ElGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="A",RenScen="AR",ElecScen="CFE")
names(GHGelec_hiMFRFA_AR_CFE)[1:2]<-c("Year","ElGHG")

GHGelec_hiMFRFA_AR_CFE$ElGHG[1:6]<-GHGelec_hiMFRFA_AR_LRE$ElGHG[1:6] # 2020:2025 is same in CFE as in LRE
GHGelec_hiMFRFA_AR_CFE$ElGHG[16:41]<-0 # 2035:2060 is 0 in CFE

GHG_hiMFRFA_AR_CFE<-GHG_hiMFRFA_AR_LREC
GHG_hiMFRFA_AR_CFE$ElecScen<-"CFE"
GHG_hiMFRFA_AR_CFE$EnGHG<-GHG_hiMFRFA_AR_LREC$EnGHG-GHGelec_hiMFRFA_AR_LRE$ElGHG+GHGelec_hiMFRFA_AR_CFE$ElGHG # energy emissions equal total LRE enGHG - LRE elGHG + CFE elGHG
GHG_hiMFRFA_AR_CFE$EmGHG<-us_hiMF_RFA_FA$GHG_NC*1e-9 # make sure this refers to the correct us_* file
GHG_hiMFRFA_AR_CFE$EmGHG[41]<-GHG_hiMFRFA_AR_CFE$EmGHG[40]
GHG_hiMFRFA_AR_CFE$RenGHG<-renGHGall[renGHGall$Scen=="hiMF_Adv",]$MtCO2e
GHG_hiMFRFA_AR_CFE$TotGHG<-GHG_hiMFRFA_AR_CFE$EmGHG+GHG_hiMFRFA_AR_CFE$RenGHG+GHG_hiMFRFA_AR_CFE$EnGHG

# hiMFRFA ER
GHG_hiMFRFA_ER<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_hiMFRFA_all_ER[,176:184])) # emissions in Mt 
GHG_hiMFRFA_ER<-data.frame(data.frame(EnGHG=with(select(GHG_hiMFRFA_ER,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=3,CharScen="B",RenScen="ER",ElecScen="MC")
names(GHG_hiMFRFA_ER)[1:2]<-c("Year","EnGHG")
GHG_hiMFRFA_ER$EmGHG<-us_hiMF_RFA_FA$GHG_NC*1e-9
GHG_hiMFRFA_ER$EmGHG[41]<-GHG_hiMFRFA_ER$EmGHG[40]
GHG_hiMFRFA_ER$RenGHG<-renGHGall[renGHGall$Scen=="hiMF_Ext",]$MtCO2e
GHG_hiMFRFA_ER$TotGHG<-GHG_hiMFRFA_ER$EmGHG+GHG_hiMFRFA_ER$RenGHG+GHG_hiMFRFA_ER$EnGHG

GHG_hiMFRFA_ER_LREC<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_hiMFRFA_all_ER[,185:193])) # emissions in Mt 
GHG_hiMFRFA_ER_LREC<-data.frame(data.frame(EnGHG=with(select(GHG_hiMFRFA_ER_LREC,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=3,CharScen="B",RenScen="ER",ElecScen="LREC")
names(GHG_hiMFRFA_ER_LREC)[1:2]<-c("Year","EnGHG")
GHG_hiMFRFA_ER_LREC$EmGHG<-us_hiMF_RFA_FA$GHG_NC*1e-9
GHG_hiMFRFA_ER_LREC$EmGHG[41]<-GHG_hiMFRFA_ER_LREC$EmGHG[40]
GHG_hiMFRFA_ER_LREC$RenGHG<-renGHGall[renGHGall$Scen=="hiMF_Ext",]$MtCO2e
GHG_hiMFRFA_ER_LREC$TotGHG<-GHG_hiMFRFA_ER_LREC$EmGHG+GHG_hiMFRFA_ER_LREC$RenGHG+GHG_hiMFRFA_ER_LREC$EnGHG

# for CFE, EnGHG needs to be done first by electricity, and then recombined with fuel EnGHG
rs_hiMFRFA_all_ER[,c("ElecGHGkg_2020_LRE","ElecGHGkg_2025_LRE","ElecGHGkg_2030_LRE","ElecGHGkg_2035_LRE","ElecGHGkg_2040_LRE","ElecGHGkg_2045_LRE","ElecGHGkg_2050_LRE","ElecGHGkg_2055_LRE","ElecGHGkg_2060_LRE")]<-1000* 
  (rs_hiMFRFA_all_ER$base_weight*rs_hiMFRFA_all_ER[,c("whiMF_2020",  "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")])*
  (rs_hiMFRFA_all_ER$Elec_GJ*rs_hiMFRFA_all_ER[,c("GHG_int_2020_LRE", "GHG_int_2025_LRE","GHG_int_2030_LRE","GHG_int_2035_LRE","GHG_int_2040_LRE","GHG_int_2045_LRE","GHG_int_2050_LRE","GHG_int_2055_LRE","GHG_int_2060_LRE")])

rs_hiMFRFA_all_ER[,c("ElecGHGkg_2020_CFE","ElecGHGkg_2025_CFE","ElecGHGkg_2030_CFE","ElecGHGkg_2035_CFE","ElecGHGkg_2040_CFE","ElecGHGkg_2045_CFE","ElecGHGkg_2050_CFE","ElecGHGkg_2055_CFE","ElecGHGkg_2060_CFE")]<-1000* 
  (rs_hiMFRFA_all_ER$base_weight*rs_hiMFRFA_all_ER[,c("whiMF_2020",  "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")])*
  (rs_hiMFRFA_all_ER$Elec_GJ*rs_hiMFRFA_all_ER[,c("GHG_int_2020_CFE", "GHG_int_2025_CFE","GHG_int_2030_CFE","GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")])

GHGelec_hiMFRFA_ER_LRE<-data.frame(Year=seq(2020,2060,5),ElGHG=1e-9*colSums(rs_hiMFRFA_all_ER[,212:220])) # emissions in Mt 
GHGelec_hiMFRFA_ER_LRE<-data.frame(data.frame(ElGHG=with(select(GHGelec_hiMFRFA_ER_LRE,Year,ElGHG),spline(Year,ElGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="A",RenScen="ER",ElecScen="LRE")
names(GHGelec_hiMFRFA_ER_LRE)[1:2]<-c("Year","ElGHG")

GHGelec_hiMFRFA_ER_CFE<-data.frame(Year=seq(2020,2060,5),ElGHG=1e-9*colSums(rs_hiMFRFA_all_ER[,221:229])) # emissions in Mt 
GHGelec_hiMFRFA_ER_CFE<-data.frame(data.frame(ElGHG=with(select(GHGelec_hiMFRFA_ER_CFE,Year,ElGHG),spline(Year,ElGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="A",RenScen="ER",ElecScen="CFE")
names(GHGelec_hiMFRFA_ER_CFE)[1:2]<-c("Year","ElGHG")

GHGelec_hiMFRFA_ER_CFE$ElGHG[1:6]<-GHGelec_hiMFRFA_ER_LRE$ElGHG[1:6] # 2020:2025 is same in CFE as in LRE
GHGelec_hiMFRFA_ER_CFE$ElGHG[16:41]<-0 # 2035:2060 is 0 in CFE

GHG_hiMFRFA_ER_CFE<-GHG_hiMFRFA_ER_LREC
GHG_hiMFRFA_ER_CFE$ElecScen<-"CFE"
GHG_hiMFRFA_ER_CFE$EnGHG<-GHG_hiMFRFA_ER_LREC$EnGHG-GHGelec_hiMFRFA_ER_LRE$ElGHG+GHGelec_hiMFRFA_ER_CFE$ElGHG # energy emissions equal total LRE enGHG - LRE elGHG + CFE elGHG
GHG_hiMFRFA_ER_CFE$EmGHG<-us_hiMF_RFA_FA$GHG_NC*1e-9 # make sure this refers to the correct us_* file
GHG_hiMFRFA_ER_CFE$EmGHG[41]<-GHG_hiMFRFA_ER_CFE$EmGHG[40]
GHG_hiMFRFA_ER_CFE$RenGHG<-renGHGall[renGHGall$Scen=="hiMF_Ext",]$MtCO2e
GHG_hiMFRFA_ER_CFE$TotGHG<-GHG_hiMFRFA_ER_CFE$EmGHG+GHG_hiMFRFA_ER_CFE$RenGHG+GHG_hiMFRFA_ER_CFE$EnGHG

rm(list=ls(pattern = "rs_"))
rm(list=ls(pattern = "GHGelec"))

# third baseDE scripts #########
load("../Final_results/res_baseDE_RR.RData")
load("../Final_results/res_baseDE_AR.RData")
load("../Final_results/res_baseDE_ER.RData")
load("../Final_results/res_hiDRDE_RR.RData")
load("../Final_results/res_hiDRDE_AR.RData")
load("../Final_results/res_hiDRDE_ER.RData")
load("../Final_results/res_hiMFDE_RR.RData")
load("../Final_results/res_hiMFDE_AR.RData")
load("../Final_results/res_hiMFDE_ER.RData")

# add in GHG intensities for 2035 CFE
rs_baseDE_all_RR[,c("GHG_int_2020_CFE","GHG_int_2025_CFE")]<-rs_baseDE_all_RR[,c("GHG_int_2020_LRE","GHG_int_2025_LRE")]
rs_baseDE_all_RR[,c("GHG_int_2030_CFE")]<-0.5*rs_baseDE_all_RR[,c("GHG_int_2025_LRE")]
rs_baseDE_all_RR[,c("GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")]<-0

rs_baseDE_all_AR[,c("GHG_int_2020_CFE","GHG_int_2025_CFE")]<-rs_baseDE_all_AR[,c("GHG_int_2020_LRE","GHG_int_2025_LRE")]
rs_baseDE_all_AR[,c("GHG_int_2030_CFE")]<-0.5*rs_baseDE_all_AR[,c("GHG_int_2025_LRE")]
rs_baseDE_all_AR[,c("GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")]<-0

rs_baseDE_all_ER[,c("GHG_int_2020_CFE","GHG_int_2025_CFE")]<-rs_baseDE_all_ER[,c("GHG_int_2020_LRE","GHG_int_2025_LRE")]
rs_baseDE_all_ER[,c("GHG_int_2030_CFE")]<-0.5*rs_baseDE_all_ER[,c("GHG_int_2025_LRE")]
rs_baseDE_all_ER[,c("GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")]<-0

# add in GHG emissions for CFE
rs_baseDE_all_RR[,c("EnGHGkg_baseDE_2020_CFE","EnGHGkg_baseDE_2025_CFE","EnGHGkg_baseDE_2030_CFE","EnGHGkg_baseDE_2035_CFE","EnGHGkg_baseDE_2040_CFE","EnGHGkg_baseDE_2045_CFE","EnGHGkg_baseDE_2050_CFE","EnGHGkg_baseDE_2055_CFE","EnGHGkg_baseDE_2060_CFE")]<-1000* 
  (rs_baseDE_all_RR$base_weight*rs_baseDE_all_RR[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*
  (rs_baseDE_all_RR$Elec_GJ*rs_baseDE_all_RR[,c("GHG_int_2020_CFE", "GHG_int_2025_CFE","GHG_int_2030_CFE","GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")]+
     matrix(rep(rs_baseDE_all_RR$Gas_GJ*GHGI_NG,9),nrow(rs_baseDE_all_RR),9)+ matrix(rep(rs_baseDE_all_RR$Oil_GJ*GHGI_FO,9),nrow(rs_baseDE_all_RR),9)+ matrix(rep(rs_baseDE_all_RR$Prop_GJ*GHGI_LP,9),nrow(rs_baseDE_all_RR),9))

rs_baseDE_all_AR[,c("EnGHGkg_baseDE_2020_CFE","EnGHGkg_baseDE_2025_CFE","EnGHGkg_baseDE_2030_CFE","EnGHGkg_baseDE_2035_CFE","EnGHGkg_baseDE_2040_CFE","EnGHGkg_baseDE_2045_CFE","EnGHGkg_baseDE_2050_CFE","EnGHGkg_baseDE_2055_CFE","EnGHGkg_baseDE_2060_CFE")]<-1000* 
  (rs_baseDE_all_AR$base_weight*rs_baseDE_all_AR[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*
  (rs_baseDE_all_AR$Elec_GJ*rs_baseDE_all_AR[,c("GHG_int_2020_CFE", "GHG_int_2025_CFE","GHG_int_2030_CFE","GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")]+
     matrix(rep(rs_baseDE_all_AR$Gas_GJ*GHGI_NG,9),nrow(rs_baseDE_all_AR),9)+ matrix(rep(rs_baseDE_all_AR$Oil_GJ*GHGI_FO,9),nrow(rs_baseDE_all_AR),9)+ matrix(rep(rs_baseDE_all_AR$Prop_GJ*GHGI_LP,9),nrow(rs_baseDE_all_AR),9))

rs_baseDE_all_ER[,c("EnGHGkg_baseDE_2020_CFE","EnGHGkg_baseDE_2025_CFE","EnGHGkg_baseDE_2030_CFE","EnGHGkg_baseDE_2035_CFE","EnGHGkg_baseDE_2040_CFE","EnGHGkg_baseDE_2045_CFE","EnGHGkg_baseDE_2050_CFE","EnGHGkg_baseDE_2055_CFE","EnGHGkg_baseDE_2060_CFE")]<-1000*
  (rs_baseDE_all_ER$base_weight*rs_baseDE_all_ER[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*
  (rs_baseDE_all_ER$Elec_GJ*rs_baseDE_all_ER[,c("GHG_int_2020_CFE", "GHG_int_2025_CFE","GHG_int_2030_CFE","GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")]+
     matrix(rep(rs_baseDE_all_ER$Gas_GJ*GHGI_NG,9),nrow(rs_baseDE_all_ER),9)+ matrix(rep(rs_baseDE_all_ER$Oil_GJ*GHGI_FO,9),nrow(rs_baseDE_all_ER),9)+ matrix(rep(rs_baseDE_all_ER$Prop_GJ*GHGI_LP,9),nrow(rs_baseDE_all_ER),9))

# start compiling emissions
GHG_baseDE_RR<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_baseDE_all_RR[,176:184])) # emissions in Mt 
GHG_baseDE_RR<-data.frame(data.frame(EnGHG=with(select(GHG_baseDE_RR,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="C",RenScen="RR",ElecScen="MC")
names(GHG_baseDE_RR)[1:2]<-c("Year","EnGHG")
GHG_baseDE_RR$EmGHG<-us_base_FA$GHG_NC*1e-9
GHG_baseDE_RR$EmGHG[41]<-GHG_baseDE_RR$EmGHG[40]
GHG_baseDE_RR$RenGHG<-renGHGall[renGHGall$Scen=="Base_Reg",]$MtCO2e
GHG_baseDE_RR$TotGHG<-GHG_baseDE_RR$EmGHG+GHG_baseDE_RR$RenGHG+GHG_baseDE_RR$EnGHG

GHG_baseDE_RR_LREC<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_baseDE_all_RR[,185:193])) # emissions in Mt 
GHG_baseDE_RR_LREC<-data.frame(data.frame(EnGHG=with(select(GHG_baseDE_RR_LREC,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="C",RenScen="RR",ElecScen="LREC")
names(GHG_baseDE_RR_LREC)[1:2]<-c("Year","EnGHG")
GHG_baseDE_RR_LREC$EmGHG<-us_base_FA$GHG_NC*1e-9
GHG_baseDE_RR_LREC$EmGHG[41]<-GHG_baseDE_RR_LREC$EmGHG[40]
GHG_baseDE_RR_LREC$RenGHG<-renGHGall[renGHGall$Scen=="Base_Reg",]$MtCO2e
GHG_baseDE_RR_LREC$TotGHG<-GHG_baseDE_RR_LREC$EmGHG+GHG_baseDE_RR_LREC$RenGHG+GHG_baseDE_RR_LREC$EnGHG

# for CFE, EnGHG needs to be done first by electricity, and then recombined with fuel EnGHG
rs_baseDE_all_RR[,c("ElecGHGkg_2020_LRE","ElecGHGkg_2025_LRE","ElecGHGkg_2030_LRE","ElecGHGkg_2035_LRE","ElecGHGkg_2040_LRE","ElecGHGkg_2045_LRE","ElecGHGkg_2050_LRE","ElecGHGkg_2055_LRE","ElecGHGkg_2060_LRE")]<-1000* 
  (rs_baseDE_all_RR$base_weight*rs_baseDE_all_RR[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*
  (rs_baseDE_all_RR$Elec_GJ*rs_baseDE_all_RR[,c("GHG_int_2020_LRE", "GHG_int_2025_LRE","GHG_int_2030_LRE","GHG_int_2035_LRE","GHG_int_2040_LRE","GHG_int_2045_LRE","GHG_int_2050_LRE","GHG_int_2055_LRE","GHG_int_2060_LRE")])

rs_baseDE_all_RR[,c("ElecGHGkg_2020_CFE","ElecGHGkg_2025_CFE","ElecGHGkg_2030_CFE","ElecGHGkg_2035_CFE","ElecGHGkg_2040_CFE","ElecGHGkg_2045_CFE","ElecGHGkg_2050_CFE","ElecGHGkg_2055_CFE","ElecGHGkg_2060_CFE")]<-1000* 
  (rs_baseDE_all_RR$base_weight*rs_baseDE_all_RR[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*
  (rs_baseDE_all_RR$Elec_GJ*rs_baseDE_all_RR[,c("GHG_int_2020_CFE", "GHG_int_2025_CFE","GHG_int_2030_CFE","GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")])

GHGelec_baseDE_RR_LRE<-data.frame(Year=seq(2020,2060,5),ElGHG=1e-9*colSums(rs_baseDE_all_RR[,212:220])) # emissions in Mt 
GHGelec_baseDE_RR_LRE<-data.frame(data.frame(ElGHG=with(select(GHGelec_baseDE_RR_LRE,Year,ElGHG),spline(Year,ElGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="A",RenScen="RR",ElecScen="LRE")
names(GHGelec_baseDE_RR_LRE)[1:2]<-c("Year","ElGHG")

GHGelec_baseDE_RR_CFE<-data.frame(Year=seq(2020,2060,5),ElGHG=1e-9*colSums(rs_baseDE_all_RR[,221:229])) # emissions in Mt 
GHGelec_baseDE_RR_CFE<-data.frame(data.frame(ElGHG=with(select(GHGelec_baseDE_RR_CFE,Year,ElGHG),spline(Year,ElGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="A",RenScen="RR",ElecScen="CFE")
names(GHGelec_baseDE_RR_CFE)[1:2]<-c("Year","ElGHG")

GHGelec_baseDE_RR_CFE$ElGHG[1:6]<-GHGelec_baseDE_RR_LRE$ElGHG[1:6] # 2020:2025 is same in CFE as in LRE
GHGelec_baseDE_RR_CFE$ElGHG[16:41]<-0 # 2035:2060 is 0 in CFE

GHG_baseDE_RR_CFE<-GHG_baseDE_RR_LREC
GHG_baseDE_RR_CFE$ElecScen<-"CFE"
GHG_baseDE_RR_CFE$EnGHG<-GHG_baseDE_RR_LREC$EnGHG-GHGelec_baseDE_RR_LRE$ElGHG+GHGelec_baseDE_RR_CFE$ElGHG # energy emissions equal total LRE enGHG - LRE elGHG + CFE elGHG
GHG_baseDE_RR_CFE$EmGHG<-us_base_FA$GHG_NC*1e-9 # make sure this refers to the correct us_* file
GHG_baseDE_RR_CFE$EmGHG[41]<-GHG_baseDE_RR_CFE$EmGHG[40]
GHG_baseDE_RR_CFE$RenGHG<-renGHGall[renGHGall$Scen=="Base_Reg",]$MtCO2e
GHG_baseDE_RR_CFE$TotGHG<-GHG_baseDE_RR_CFE$EmGHG+GHG_baseDE_RR_CFE$RenGHG+GHG_baseDE_RR_CFE$EnGHG

# baseDE AR
GHG_baseDE_AR<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_baseDE_all_AR[,176:184])) # emissions in Mt 
GHG_baseDE_AR<-data.frame(data.frame(EnGHG=with(select(GHG_baseDE_AR,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="C",RenScen="AR",ElecScen="MC")
names(GHG_baseDE_AR)[1:2]<-c("Year","EnGHG")
GHG_baseDE_AR$EmGHG<-us_base_FA$GHG_NC*1e-9
GHG_baseDE_AR$EmGHG[41]<-GHG_baseDE_AR$EmGHG[40]
GHG_baseDE_AR$RenGHG<-renGHGall[renGHGall$Scen=="Base_Adv",]$MtCO2e
GHG_baseDE_AR$TotGHG<-GHG_baseDE_AR$EmGHG+GHG_baseDE_AR$RenGHG+GHG_baseDE_AR$EnGHG

GHG_baseDE_AR_LREC<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_baseDE_all_AR[,185:193])) # emissions in Mt 
GHG_baseDE_AR_LREC<-data.frame(data.frame(EnGHG=with(select(GHG_baseDE_AR_LREC,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="C",RenScen="AR",ElecScen="LREC")
names(GHG_baseDE_AR_LREC)[1:2]<-c("Year","EnGHG")
GHG_baseDE_AR_LREC$EmGHG<-us_base_FA$GHG_NC*1e-9
GHG_baseDE_AR_LREC$EmGHG[41]<-GHG_baseDE_AR_LREC$EmGHG[40]
GHG_baseDE_AR_LREC$RenGHG<-renGHGall[renGHGall$Scen=="Base_Adv",]$MtCO2e
GHG_baseDE_AR_LREC$TotGHG<-GHG_baseDE_AR_LREC$EmGHG+GHG_baseDE_AR_LREC$RenGHG+GHG_baseDE_AR_LREC$EnGHG

# for CFE, EnGHG needs to be done first by electricity, and then recombined with fuel EnGHG
rs_baseDE_all_AR[,c("ElecGHGkg_2020_LRE","ElecGHGkg_2025_LRE","ElecGHGkg_2030_LRE","ElecGHGkg_2035_LRE","ElecGHGkg_2040_LRE","ElecGHGkg_2045_LRE","ElecGHGkg_2050_LRE","ElecGHGkg_2055_LRE","ElecGHGkg_2060_LRE")]<-1000* 
  (rs_baseDE_all_AR$base_weight*rs_baseDE_all_AR[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*
  (rs_baseDE_all_AR$Elec_GJ*rs_baseDE_all_AR[,c("GHG_int_2020_LRE", "GHG_int_2025_LRE","GHG_int_2030_LRE","GHG_int_2035_LRE","GHG_int_2040_LRE","GHG_int_2045_LRE","GHG_int_2050_LRE","GHG_int_2055_LRE","GHG_int_2060_LRE")])

rs_baseDE_all_AR[,c("ElecGHGkg_2020_CFE","ElecGHGkg_2025_CFE","ElecGHGkg_2030_CFE","ElecGHGkg_2035_CFE","ElecGHGkg_2040_CFE","ElecGHGkg_2045_CFE","ElecGHGkg_2050_CFE","ElecGHGkg_2055_CFE","ElecGHGkg_2060_CFE")]<-1000* 
  (rs_baseDE_all_AR$base_weight*rs_baseDE_all_AR[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*
  (rs_baseDE_all_AR$Elec_GJ*rs_baseDE_all_AR[,c("GHG_int_2020_CFE", "GHG_int_2025_CFE","GHG_int_2030_CFE","GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")])

GHGelec_baseDE_AR_LRE<-data.frame(Year=seq(2020,2060,5),ElGHG=1e-9*colSums(rs_baseDE_all_AR[,212:220])) # emissions in Mt 
GHGelec_baseDE_AR_LRE<-data.frame(data.frame(ElGHG=with(select(GHGelec_baseDE_AR_LRE,Year,ElGHG),spline(Year,ElGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="A",RenScen="AR",ElecScen="LRE")
names(GHGelec_baseDE_AR_LRE)[1:2]<-c("Year","ElGHG")

GHGelec_baseDE_AR_CFE<-data.frame(Year=seq(2020,2060,5),ElGHG=1e-9*colSums(rs_baseDE_all_AR[,221:229])) # emissions in Mt 
GHGelec_baseDE_AR_CFE<-data.frame(data.frame(ElGHG=with(select(GHGelec_baseDE_AR_CFE,Year,ElGHG),spline(Year,ElGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="A",RenScen="AR",ElecScen="CFE")
names(GHGelec_baseDE_AR_CFE)[1:2]<-c("Year","ElGHG")

GHGelec_baseDE_AR_CFE$ElGHG[1:6]<-GHGelec_baseDE_AR_LRE$ElGHG[1:6] # 2020:2025 is same in CFE as in LRE
GHGelec_baseDE_AR_CFE$ElGHG[16:41]<-0 # 2035:2060 is 0 in CFE

GHG_baseDE_AR_CFE<-GHG_baseDE_AR_LREC
GHG_baseDE_AR_CFE$ElecScen<-"CFE"
GHG_baseDE_AR_CFE$EnGHG<-GHG_baseDE_AR_LREC$EnGHG-GHGelec_baseDE_AR_LRE$ElGHG+GHGelec_baseDE_AR_CFE$ElGHG # energy emissions equal total LRE enGHG - LRE elGHG + CFE elGHG
GHG_baseDE_AR_CFE$EmGHG<-us_base_FA$GHG_NC*1e-9 # make sure this refers to the correct us_* file
GHG_baseDE_AR_CFE$EmGHG[41]<-GHG_baseDE_AR_CFE$EmGHG[40]
GHG_baseDE_AR_CFE$RenGHG<-renGHGall[renGHGall$Scen=="Base_Adv",]$MtCO2e
GHG_baseDE_AR_CFE$TotGHG<-GHG_baseDE_AR_CFE$EmGHG+GHG_baseDE_AR_CFE$RenGHG+GHG_baseDE_AR_CFE$EnGHG

# baseDE ER
GHG_baseDE_ER<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_baseDE_all_ER[,176:184])) # emissions in Mt 
GHG_baseDE_ER<-data.frame(data.frame(EnGHG=with(select(GHG_baseDE_ER,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="C",RenScen="ER",ElecScen="MC")
names(GHG_baseDE_ER)[1:2]<-c("Year","EnGHG")
GHG_baseDE_ER$EmGHG<-us_base_FA$GHG_NC*1e-9
GHG_baseDE_ER$EmGHG[41]<-GHG_baseDE_ER$EmGHG[40]
GHG_baseDE_ER$RenGHG<-renGHGall[renGHGall$Scen=="Base_Ext",]$MtCO2e
GHG_baseDE_ER$TotGHG<-GHG_baseDE_ER$EmGHG+GHG_baseDE_ER$RenGHG+GHG_baseDE_ER$EnGHG

GHG_baseDE_ER_LREC<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_baseDE_all_ER[,185:193])) # emissions in Mt 
GHG_baseDE_ER_LREC<-data.frame(data.frame(EnGHG=with(select(GHG_baseDE_ER_LREC,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="C",RenScen="ER",ElecScen="LREC")
names(GHG_baseDE_ER_LREC)[1:2]<-c("Year","EnGHG")
GHG_baseDE_ER_LREC$EmGHG<-us_base_FA$GHG_NC*1e-9
GHG_baseDE_ER_LREC$EmGHG[41]<-GHG_baseDE_ER_LREC$EmGHG[40]
GHG_baseDE_ER_LREC$RenGHG<-renGHGall[renGHGall$Scen=="Base_Ext",]$MtCO2e
GHG_baseDE_ER_LREC$TotGHG<-GHG_baseDE_ER_LREC$EmGHG+GHG_baseDE_ER_LREC$RenGHG+GHG_baseDE_ER_LREC$EnGHG

# for CFE, EnGHG needs to be done first by electricity, and then recombined with fuel EnGHG
rs_baseDE_all_ER[,c("ElecGHGkg_2020_LRE","ElecGHGkg_2025_LRE","ElecGHGkg_2030_LRE","ElecGHGkg_2035_LRE","ElecGHGkg_2040_LRE","ElecGHGkg_2045_LRE","ElecGHGkg_2050_LRE","ElecGHGkg_2055_LRE","ElecGHGkg_2060_LRE")]<-1000* 
  (rs_baseDE_all_ER$base_weight*rs_baseDE_all_ER[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*
  (rs_baseDE_all_ER$Elec_GJ*rs_baseDE_all_ER[,c("GHG_int_2020_LRE", "GHG_int_2025_LRE","GHG_int_2030_LRE","GHG_int_2035_LRE","GHG_int_2040_LRE","GHG_int_2045_LRE","GHG_int_2050_LRE","GHG_int_2055_LRE","GHG_int_2060_LRE")])

rs_baseDE_all_ER[,c("ElecGHGkg_2020_CFE","ElecGHGkg_2025_CFE","ElecGHGkg_2030_CFE","ElecGHGkg_2035_CFE","ElecGHGkg_2040_CFE","ElecGHGkg_2045_CFE","ElecGHGkg_2050_CFE","ElecGHGkg_2055_CFE","ElecGHGkg_2060_CFE")]<-1000* 
  (rs_baseDE_all_ER$base_weight*rs_baseDE_all_ER[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*
  (rs_baseDE_all_ER$Elec_GJ*rs_baseDE_all_ER[,c("GHG_int_2020_CFE", "GHG_int_2025_CFE","GHG_int_2030_CFE","GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")])

GHGelec_baseDE_ER_LRE<-data.frame(Year=seq(2020,2060,5),ElGHG=1e-9*colSums(rs_baseDE_all_ER[,212:220])) # emissions in Mt 
GHGelec_baseDE_ER_LRE<-data.frame(data.frame(ElGHG=with(select(GHGelec_baseDE_ER_LRE,Year,ElGHG),spline(Year,ElGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="A",RenScen="ER",ElecScen="LRE")
names(GHGelec_baseDE_ER_LRE)[1:2]<-c("Year","ElGHG")

GHGelec_baseDE_ER_CFE<-data.frame(Year=seq(2020,2060,5),ElGHG=1e-9*colSums(rs_baseDE_all_ER[,221:229])) # emissions in Mt 
GHGelec_baseDE_ER_CFE<-data.frame(data.frame(ElGHG=with(select(GHGelec_baseDE_ER_CFE,Year,ElGHG),spline(Year,ElGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="A",RenScen="ER",ElecScen="CFE")
names(GHGelec_baseDE_ER_CFE)[1:2]<-c("Year","ElGHG")

GHGelec_baseDE_ER_CFE$ElGHG[1:6]<-GHGelec_baseDE_ER_LRE$ElGHG[1:6] # 2020:2025 is same in CFE as in LRE
GHGelec_baseDE_ER_CFE$ElGHG[16:41]<-0 # 2035:2060 is 0 in CFE

GHG_baseDE_ER_CFE<-GHG_baseDE_ER_LREC
GHG_baseDE_ER_CFE$ElecScen<-"CFE"
GHG_baseDE_ER_CFE$EnGHG<-GHG_baseDE_ER_LREC$EnGHG-GHGelec_baseDE_ER_LRE$ElGHG+GHGelec_baseDE_ER_CFE$ElGHG # energy emissions equal total LRE enGHG - LRE elGHG + CFE elGHG
GHG_baseDE_ER_CFE$EmGHG<-us_base_FA$GHG_NC*1e-9 # make sure this refers to the correct us_* file
GHG_baseDE_ER_CFE$EmGHG[41]<-GHG_baseDE_ER_CFE$EmGHG[40]
GHG_baseDE_ER_CFE$RenGHG<-renGHGall[renGHGall$Scen=="Base_Ext",]$MtCO2e
GHG_baseDE_ER_CFE$TotGHG<-GHG_baseDE_ER_CFE$EmGHG+GHG_baseDE_ER_CFE$RenGHG+GHG_baseDE_ER_CFE$EnGHG

# hi DRDE
# add in GHG intensities for 2035 CFE
rs_hiDRDE_all_RR[,c("GHG_int_2020_CFE","GHG_int_2025_CFE")]<-rs_hiDRDE_all_RR[,c("GHG_int_2020_LRE","GHG_int_2025_LRE")]
rs_hiDRDE_all_RR[,c("GHG_int_2030_CFE")]<-0.5*rs_hiDRDE_all_RR[,c("GHG_int_2025_LRE")]
rs_hiDRDE_all_RR[,c("GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")]<-0

rs_hiDRDE_all_AR[,c("GHG_int_2020_CFE","GHG_int_2025_CFE")]<-rs_hiDRDE_all_AR[,c("GHG_int_2020_LRE","GHG_int_2025_LRE")]
rs_hiDRDE_all_AR[,c("GHG_int_2030_CFE")]<-0.5*rs_hiDRDE_all_AR[,c("GHG_int_2025_LRE")]
rs_hiDRDE_all_AR[,c("GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")]<-0

rs_hiDRDE_all_ER[,c("GHG_int_2020_CFE","GHG_int_2025_CFE")]<-rs_hiDRDE_all_ER[,c("GHG_int_2020_LRE","GHG_int_2025_LRE")]
rs_hiDRDE_all_ER[,c("GHG_int_2030_CFE")]<-0.5*rs_hiDRDE_all_ER[,c("GHG_int_2025_LRE")]
rs_hiDRDE_all_ER[,c("GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")]<-0

# add in GHG emissions for CFE
rs_hiDRDE_all_RR[,c("EnGHGkg_hiDR_2020_CFE","EnGHGkg_hiDR_2025_CFE","EnGHGkg_hiDR_2030_CFE","EnGHGkg_hiDR_2035_CFE","EnGHGkg_hiDR_2040_CFE","EnGHGkg_hiDR_2045_CFE","EnGHGkg_hiDR_2050_CFE","EnGHGkg_hiDR_2055_CFE","EnGHGkg_hiDR_2060_CFE")]<-1000* 
  (rs_hiDRDE_all_RR$base_weight*rs_hiDRDE_all_RR[,c("whiDR_2020",  "whiDR_2025", "whiDR_2030", "whiDR_2035", "whiDR_2040", "whiDR_2045", "whiDR_2050", "whiDR_2055", "whiDR_2060")])*
  (rs_hiDRDE_all_RR$Elec_GJ*rs_hiDRDE_all_RR[,c("GHG_int_2020_CFE", "GHG_int_2025_CFE","GHG_int_2030_CFE","GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")]+
     matrix(rep(rs_hiDRDE_all_RR$Gas_GJ*GHGI_NG,9),nrow(rs_hiDRDE_all_RR),9)+ matrix(rep(rs_hiDRDE_all_RR$Oil_GJ*GHGI_FO,9),nrow(rs_hiDRDE_all_RR),9)+ matrix(rep(rs_hiDRDE_all_RR$Prop_GJ*GHGI_LP,9),nrow(rs_hiDRDE_all_RR),9))

rs_hiDRDE_all_AR[,c("EnGHGkg_hiDR_2020_CFE","EnGHGkg_hiDR_2025_CFE","EnGHGkg_hiDR_2030_CFE","EnGHGkg_hiDR_2035_CFE","EnGHGkg_hiDR_2040_CFE","EnGHGkg_hiDR_2045_CFE","EnGHGkg_hiDR_2050_CFE","EnGHGkg_hiDR_2055_CFE","EnGHGkg_hiDR_2060_CFE")]<-1000* 
  (rs_hiDRDE_all_AR$base_weight*rs_hiDRDE_all_AR[,c("whiDR_2020",  "whiDR_2025", "whiDR_2030", "whiDR_2035", "whiDR_2040", "whiDR_2045", "whiDR_2050", "whiDR_2055", "whiDR_2060")])*
  (rs_hiDRDE_all_AR$Elec_GJ*rs_hiDRDE_all_AR[,c("GHG_int_2020_CFE", "GHG_int_2025_CFE","GHG_int_2030_CFE","GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")]+
     matrix(rep(rs_hiDRDE_all_AR$Gas_GJ*GHGI_NG,9),nrow(rs_hiDRDE_all_AR),9)+ matrix(rep(rs_hiDRDE_all_AR$Oil_GJ*GHGI_FO,9),nrow(rs_hiDRDE_all_AR),9)+ matrix(rep(rs_hiDRDE_all_AR$Prop_GJ*GHGI_LP,9),nrow(rs_hiDRDE_all_AR),9))

rs_hiDRDE_all_ER[,c("EnGHGkg_hiDR_2020_CFE","EnGHGkg_hiDR_2025_CFE","EnGHGkg_hiDR_2030_CFE","EnGHGkg_hiDR_2035_CFE","EnGHGkg_hiDR_2040_CFE","EnGHGkg_hiDR_2045_CFE","EnGHGkg_hiDR_2050_CFE","EnGHGkg_hiDR_2055_CFE","EnGHGkg_hiDR_2060_CFE")]<-1000* 
  (rs_hiDRDE_all_ER$base_weight*rs_hiDRDE_all_ER[,c("whiDR_2020",  "whiDR_2025", "whiDR_2030", "whiDR_2035", "whiDR_2040", "whiDR_2045", "whiDR_2050", "whiDR_2055", "whiDR_2060")])*
  (rs_hiDRDE_all_ER$Elec_GJ*rs_hiDRDE_all_ER[,c("GHG_int_2020_CFE", "GHG_int_2025_CFE","GHG_int_2030_CFE","GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")]+
     matrix(rep(rs_hiDRDE_all_ER$Gas_GJ*GHGI_NG,9),nrow(rs_hiDRDE_all_ER),9)+ matrix(rep(rs_hiDRDE_all_ER$Oil_GJ*GHGI_FO,9),nrow(rs_hiDRDE_all_ER),9)+ matrix(rep(rs_hiDRDE_all_ER$Prop_GJ*GHGI_LP,9),nrow(rs_hiDRDE_all_ER),9))

# start compiling emissions
GHG_hiDRDE_RR<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_hiDRDE_all_RR[,176:184])) # emissions in Mt 
GHG_hiDRDE_RR<-data.frame(data.frame(EnGHG=with(select(GHG_hiDRDE_RR,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=2,CharScen="C",RenScen="RR",ElecScen="MC")
names(GHG_hiDRDE_RR)[1:2]<-c("Year","EnGHG")
GHG_hiDRDE_RR$EmGHG<-us_hiDR_FA$GHG_NC*1e-9
GHG_hiDRDE_RR$EmGHG[41]<-GHG_hiDRDE_RR$EmGHG[40]
GHG_hiDRDE_RR$RenGHG<-renGHGall[renGHGall$Scen=="hiTO_Reg",]$MtCO2e
GHG_hiDRDE_RR$TotGHG<-GHG_hiDRDE_RR$EmGHG+GHG_hiDRDE_RR$RenGHG+GHG_hiDRDE_RR$EnGHG

GHG_hiDRDE_RR_LREC<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_hiDRDE_all_RR[,185:193])) # emissions in Mt 
GHG_hiDRDE_RR_LREC<-data.frame(data.frame(EnGHG=with(select(GHG_hiDRDE_RR_LREC,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=2,CharScen="C",RenScen="RR",ElecScen="LREC")
names(GHG_hiDRDE_RR_LREC)[1:2]<-c("Year","EnGHG")
GHG_hiDRDE_RR_LREC$EmGHG<-us_hiDR_FA$GHG_NC*1e-9
GHG_hiDRDE_RR_LREC$EmGHG[41]<-GHG_hiDRDE_RR_LREC$EmGHG[40]
GHG_hiDRDE_RR_LREC$RenGHG<-renGHGall[renGHGall$Scen=="hiTO_Reg",]$MtCO2e
GHG_hiDRDE_RR_LREC$TotGHG<-GHG_hiDRDE_RR_LREC$EmGHG+GHG_hiDRDE_RR_LREC$RenGHG+GHG_hiDRDE_RR_LREC$EnGHG

# for CFE, EnGHG needs to be done first by electricity, and then recombined with fuel EnGHG
rs_hiDRDE_all_RR[,c("ElecGHGkg_2020_LRE","ElecGHGkg_2025_LRE","ElecGHGkg_2030_LRE","ElecGHGkg_2035_LRE","ElecGHGkg_2040_LRE","ElecGHGkg_2045_LRE","ElecGHGkg_2050_LRE","ElecGHGkg_2055_LRE","ElecGHGkg_2060_LRE")]<-1000* 
  (rs_hiDRDE_all_RR$base_weight*rs_hiDRDE_all_RR[,c("whiDR_2020",  "whiDR_2025", "whiDR_2030", "whiDR_2035", "whiDR_2040", "whiDR_2045", "whiDR_2050", "whiDR_2055", "whiDR_2060")])*
  (rs_hiDRDE_all_RR$Elec_GJ*rs_hiDRDE_all_RR[,c("GHG_int_2020_LRE", "GHG_int_2025_LRE","GHG_int_2030_LRE","GHG_int_2035_LRE","GHG_int_2040_LRE","GHG_int_2045_LRE","GHG_int_2050_LRE","GHG_int_2055_LRE","GHG_int_2060_LRE")])

rs_hiDRDE_all_RR[,c("ElecGHGkg_2020_CFE","ElecGHGkg_2025_CFE","ElecGHGkg_2030_CFE","ElecGHGkg_2035_CFE","ElecGHGkg_2040_CFE","ElecGHGkg_2045_CFE","ElecGHGkg_2050_CFE","ElecGHGkg_2055_CFE","ElecGHGkg_2060_CFE")]<-1000* 
  (rs_hiDRDE_all_RR$base_weight*rs_hiDRDE_all_RR[,c("whiDR_2020",  "whiDR_2025", "whiDR_2030", "whiDR_2035", "whiDR_2040", "whiDR_2045", "whiDR_2050", "whiDR_2055", "whiDR_2060")])*
  (rs_hiDRDE_all_RR$Elec_GJ*rs_hiDRDE_all_RR[,c("GHG_int_2020_CFE", "GHG_int_2025_CFE","GHG_int_2030_CFE","GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")])

GHGelec_hiDRDE_RR_LRE<-data.frame(Year=seq(2020,2060,5),ElGHG=1e-9*colSums(rs_hiDRDE_all_RR[,212:220])) # emissions in Mt 
GHGelec_hiDRDE_RR_LRE<-data.frame(data.frame(ElGHG=with(select(GHGelec_hiDRDE_RR_LRE,Year,ElGHG),spline(Year,ElGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="A",RenScen="RR",ElecScen="LRE")
names(GHGelec_hiDRDE_RR_LRE)[1:2]<-c("Year","ElGHG")

GHGelec_hiDRDE_RR_CFE<-data.frame(Year=seq(2020,2060,5),ElGHG=1e-9*colSums(rs_hiDRDE_all_RR[,221:229])) # emissions in Mt 
GHGelec_hiDRDE_RR_CFE<-data.frame(data.frame(ElGHG=with(select(GHGelec_hiDRDE_RR_CFE,Year,ElGHG),spline(Year,ElGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="A",RenScen="RR",ElecScen="CFE")
names(GHGelec_hiDRDE_RR_CFE)[1:2]<-c("Year","ElGHG")

GHGelec_hiDRDE_RR_CFE$ElGHG[1:6]<-GHGelec_hiDRDE_RR_LRE$ElGHG[1:6] # 2020:2025 is same in CFE as in LRE
GHGelec_hiDRDE_RR_CFE$ElGHG[16:41]<-0 # 2035:2060 is 0 in CFE

GHG_hiDRDE_RR_CFE<-GHG_hiDRDE_RR_LREC
GHG_hiDRDE_RR_CFE$ElecScen<-"CFE"
GHG_hiDRDE_RR_CFE$EnGHG<-GHG_hiDRDE_RR_LREC$EnGHG-GHGelec_hiDRDE_RR_LRE$ElGHG+GHGelec_hiDRDE_RR_CFE$ElGHG # energy emissions equal total LRE enGHG - LRE elGHG + CFE elGHG
GHG_hiDRDE_RR_CFE$EmGHG<-us_hiDR_FA$GHG_NC*1e-9 # make sure this refers to the correct us_* file
GHG_hiDRDE_RR_CFE$EmGHG[41]<-GHG_hiDRDE_RR_CFE$EmGHG[40]
GHG_hiDRDE_RR_CFE$RenGHG<-renGHGall[renGHGall$Scen=="hiTO_Reg",]$MtCO2e
GHG_hiDRDE_RR_CFE$TotGHG<-GHG_hiDRDE_RR_CFE$EmGHG+GHG_hiDRDE_RR_CFE$RenGHG+GHG_hiDRDE_RR_CFE$EnGHG

# hiDRDE AR
GHG_hiDRDE_AR<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_hiDRDE_all_AR[,176:184])) # emissions in Mt 
GHG_hiDRDE_AR<-data.frame(data.frame(EnGHG=with(select(GHG_hiDRDE_AR,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=2,CharScen="C",RenScen="AR",ElecScen="MC")
names(GHG_hiDRDE_AR)[1:2]<-c("Year","EnGHG")
GHG_hiDRDE_AR$EmGHG<-us_hiDR_FA$GHG_NC*1e-9
GHG_hiDRDE_AR$EmGHG[41]<-GHG_hiDRDE_AR$EmGHG[40]
GHG_hiDRDE_AR$RenGHG<-renGHGall[renGHGall$Scen=="hiTO_Adv",]$MtCO2e
GHG_hiDRDE_AR$TotGHG<-GHG_hiDRDE_AR$EmGHG+GHG_hiDRDE_AR$RenGHG+GHG_hiDRDE_AR$EnGHG

GHG_hiDRDE_AR_LREC<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_hiDRDE_all_AR[,185:193])) # emissions in Mt 
GHG_hiDRDE_AR_LREC<-data.frame(data.frame(EnGHG=with(select(GHG_hiDRDE_AR_LREC,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=2,CharScen="C",RenScen="AR",ElecScen="LREC")
names(GHG_hiDRDE_AR_LREC)[1:2]<-c("Year","EnGHG")
GHG_hiDRDE_AR_LREC$EmGHG<-us_hiDR_FA$GHG_NC*1e-9
GHG_hiDRDE_AR_LREC$EmGHG[41]<-GHG_hiDRDE_AR_LREC$EmGHG[40]
GHG_hiDRDE_AR_LREC$RenGHG<-renGHGall[renGHGall$Scen=="hiTO_Adv",]$MtCO2e
GHG_hiDRDE_AR_LREC$TotGHG<-GHG_hiDRDE_AR_LREC$EmGHG+GHG_hiDRDE_AR_LREC$RenGHG+GHG_hiDRDE_AR_LREC$EnGHG

# for CFE, EnGHG needs to be done first by electricity, and then recombined with fuel EnGHG
rs_hiDRDE_all_AR[,c("ElecGHGkg_2020_LRE","ElecGHGkg_2025_LRE","ElecGHGkg_2030_LRE","ElecGHGkg_2035_LRE","ElecGHGkg_2040_LRE","ElecGHGkg_2045_LRE","ElecGHGkg_2050_LRE","ElecGHGkg_2055_LRE","ElecGHGkg_2060_LRE")]<-1000* 
  (rs_hiDRDE_all_AR$base_weight*rs_hiDRDE_all_AR[,c("whiDR_2020",  "whiDR_2025", "whiDR_2030", "whiDR_2035", "whiDR_2040", "whiDR_2045", "whiDR_2050", "whiDR_2055", "whiDR_2060")])*
  (rs_hiDRDE_all_AR$Elec_GJ*rs_hiDRDE_all_AR[,c("GHG_int_2020_LRE", "GHG_int_2025_LRE","GHG_int_2030_LRE","GHG_int_2035_LRE","GHG_int_2040_LRE","GHG_int_2045_LRE","GHG_int_2050_LRE","GHG_int_2055_LRE","GHG_int_2060_LRE")])

rs_hiDRDE_all_AR[,c("ElecGHGkg_2020_CFE","ElecGHGkg_2025_CFE","ElecGHGkg_2030_CFE","ElecGHGkg_2035_CFE","ElecGHGkg_2040_CFE","ElecGHGkg_2045_CFE","ElecGHGkg_2050_CFE","ElecGHGkg_2055_CFE","ElecGHGkg_2060_CFE")]<-1000* 
  (rs_hiDRDE_all_AR$base_weight*rs_hiDRDE_all_AR[,c("whiDR_2020",  "whiDR_2025", "whiDR_2030", "whiDR_2035", "whiDR_2040", "whiDR_2045", "whiDR_2050", "whiDR_2055", "whiDR_2060")])*
  (rs_hiDRDE_all_AR$Elec_GJ*rs_hiDRDE_all_AR[,c("GHG_int_2020_CFE", "GHG_int_2025_CFE","GHG_int_2030_CFE","GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")])

GHGelec_hiDRDE_AR_LRE<-data.frame(Year=seq(2020,2060,5),ElGHG=1e-9*colSums(rs_hiDRDE_all_AR[,212:220])) # emissions in Mt 
GHGelec_hiDRDE_AR_LRE<-data.frame(data.frame(ElGHG=with(select(GHGelec_hiDRDE_AR_LRE,Year,ElGHG),spline(Year,ElGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="A",RenScen="AR",ElecScen="LRE")
names(GHGelec_hiDRDE_AR_LRE)[1:2]<-c("Year","ElGHG")

GHGelec_hiDRDE_AR_CFE<-data.frame(Year=seq(2020,2060,5),ElGHG=1e-9*colSums(rs_hiDRDE_all_AR[,221:229])) # emissions in Mt 
GHGelec_hiDRDE_AR_CFE<-data.frame(data.frame(ElGHG=with(select(GHGelec_hiDRDE_AR_CFE,Year,ElGHG),spline(Year,ElGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="A",RenScen="AR",ElecScen="CFE")
names(GHGelec_hiDRDE_AR_CFE)[1:2]<-c("Year","ElGHG")

GHGelec_hiDRDE_AR_CFE$ElGHG[1:6]<-GHGelec_hiDRDE_AR_LRE$ElGHG[1:6] # 2020:2025 is same in CFE as in LRE
GHGelec_hiDRDE_AR_CFE$ElGHG[16:41]<-0 # 2035:2060 is 0 in CFE

GHG_hiDRDE_AR_CFE<-GHG_hiDRDE_AR_LREC
GHG_hiDRDE_AR_CFE$ElecScen<-"CFE"
GHG_hiDRDE_AR_CFE$EnGHG<-GHG_hiDRDE_AR_LREC$EnGHG-GHGelec_hiDRDE_AR_LRE$ElGHG+GHGelec_hiDRDE_AR_CFE$ElGHG # energy emissions equal total LRE enGHG - LRE elGHG + CFE elGHG
GHG_hiDRDE_AR_CFE$EmGHG<-us_hiDR_FA$GHG_NC*1e-9 # make sure this refers to the correct us_* file
GHG_hiDRDE_AR_CFE$EmGHG[41]<-GHG_hiDRDE_AR_CFE$EmGHG[40]
GHG_hiDRDE_AR_CFE$RenGHG<-renGHGall[renGHGall$Scen=="hiTO_Adv",]$MtCO2e
GHG_hiDRDE_AR_CFE$TotGHG<-GHG_hiDRDE_AR_CFE$EmGHG+GHG_hiDRDE_AR_CFE$RenGHG+GHG_hiDRDE_AR_CFE$EnGHG

# hiDRDE ER
GHG_hiDRDE_ER<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_hiDRDE_all_ER[,176:184])) # emissions in Mt 
GHG_hiDRDE_ER<-data.frame(data.frame(EnGHG=with(select(GHG_hiDRDE_ER,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=2,CharScen="C",RenScen="ER",ElecScen="MC")
names(GHG_hiDRDE_ER)[1:2]<-c("Year","EnGHG")
GHG_hiDRDE_ER$EmGHG<-us_hiDR_FA$GHG_NC*1e-9
GHG_hiDRDE_ER$EmGHG[41]<-GHG_hiDRDE_ER$EmGHG[40]
GHG_hiDRDE_ER$RenGHG<-renGHGall[renGHGall$Scen=="hiTO_Ext",]$MtCO2e
GHG_hiDRDE_ER$TotGHG<-GHG_hiDRDE_ER$EmGHG+GHG_hiDRDE_ER$RenGHG+GHG_hiDRDE_ER$EnGHG

GHG_hiDRDE_ER_LREC<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_hiDRDE_all_ER[,185:193])) # emissions in Mt 
GHG_hiDRDE_ER_LREC<-data.frame(data.frame(EnGHG=with(select(GHG_hiDRDE_ER_LREC,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=2,CharScen="C",RenScen="ER",ElecScen="LREC")
names(GHG_hiDRDE_ER_LREC)[1:2]<-c("Year","EnGHG")
GHG_hiDRDE_ER_LREC$EmGHG<-us_hiDR_FA$GHG_NC*1e-9
GHG_hiDRDE_ER_LREC$EmGHG[41]<-GHG_hiDRDE_ER_LREC$EmGHG[40]
GHG_hiDRDE_ER_LREC$RenGHG<-renGHGall[renGHGall$Scen=="hiTO_Ext",]$MtCO2e
GHG_hiDRDE_ER_LREC$TotGHG<-GHG_hiDRDE_ER_LREC$EmGHG+GHG_hiDRDE_ER_LREC$RenGHG+GHG_hiDRDE_ER_LREC$EnGHG

# for CFE, EnGHG needs to be done first by electricity, and then recombined with fuel EnGHG
rs_hiDRDE_all_ER[,c("ElecGHGkg_2020_LRE","ElecGHGkg_2025_LRE","ElecGHGkg_2030_LRE","ElecGHGkg_2035_LRE","ElecGHGkg_2040_LRE","ElecGHGkg_2045_LRE","ElecGHGkg_2050_LRE","ElecGHGkg_2055_LRE","ElecGHGkg_2060_LRE")]<-1000* 
  (rs_hiDRDE_all_ER$base_weight*rs_hiDRDE_all_ER[,c("whiDR_2020",  "whiDR_2025", "whiDR_2030", "whiDR_2035", "whiDR_2040", "whiDR_2045", "whiDR_2050", "whiDR_2055", "whiDR_2060")])*
  (rs_hiDRDE_all_ER$Elec_GJ*rs_hiDRDE_all_ER[,c("GHG_int_2020_LRE", "GHG_int_2025_LRE","GHG_int_2030_LRE","GHG_int_2035_LRE","GHG_int_2040_LRE","GHG_int_2045_LRE","GHG_int_2050_LRE","GHG_int_2055_LRE","GHG_int_2060_LRE")])

rs_hiDRDE_all_ER[,c("ElecGHGkg_2020_CFE","ElecGHGkg_2025_CFE","ElecGHGkg_2030_CFE","ElecGHGkg_2035_CFE","ElecGHGkg_2040_CFE","ElecGHGkg_2045_CFE","ElecGHGkg_2050_CFE","ElecGHGkg_2055_CFE","ElecGHGkg_2060_CFE")]<-1000* 
  (rs_hiDRDE_all_ER$base_weight*rs_hiDRDE_all_ER[,c("whiDR_2020",  "whiDR_2025", "whiDR_2030", "whiDR_2035", "whiDR_2040", "whiDR_2045", "whiDR_2050", "whiDR_2055", "whiDR_2060")])*
  (rs_hiDRDE_all_ER$Elec_GJ*rs_hiDRDE_all_ER[,c("GHG_int_2020_CFE", "GHG_int_2025_CFE","GHG_int_2030_CFE","GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")])

GHGelec_hiDRDE_ER_LRE<-data.frame(Year=seq(2020,2060,5),ElGHG=1e-9*colSums(rs_hiDRDE_all_ER[,212:220])) # emissions in Mt 
GHGelec_hiDRDE_ER_LRE<-data.frame(data.frame(ElGHG=with(select(GHGelec_hiDRDE_ER_LRE,Year,ElGHG),spline(Year,ElGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="A",RenScen="ER",ElecScen="LRE")
names(GHGelec_hiDRDE_ER_LRE)[1:2]<-c("Year","ElGHG")

GHGelec_hiDRDE_ER_CFE<-data.frame(Year=seq(2020,2060,5),ElGHG=1e-9*colSums(rs_hiDRDE_all_ER[,221:229])) # emissions in Mt 
GHGelec_hiDRDE_ER_CFE<-data.frame(data.frame(ElGHG=with(select(GHGelec_hiDRDE_ER_CFE,Year,ElGHG),spline(Year,ElGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="A",RenScen="ER",ElecScen="CFE")
names(GHGelec_hiDRDE_ER_CFE)[1:2]<-c("Year","ElGHG")

GHGelec_hiDRDE_ER_CFE$ElGHG[1:6]<-GHGelec_hiDRDE_ER_LRE$ElGHG[1:6] # 2020:2025 is same in CFE as in LRE
GHGelec_hiDRDE_ER_CFE$ElGHG[16:41]<-0 # 2035:2060 is 0 in CFE

GHG_hiDRDE_ER_CFE<-GHG_hiDRDE_ER_LREC
GHG_hiDRDE_ER_CFE$ElecScen<-"CFE"
GHG_hiDRDE_ER_CFE$EnGHG<-GHG_hiDRDE_ER_LREC$EnGHG-GHGelec_hiDRDE_ER_LRE$ElGHG+GHGelec_hiDRDE_ER_CFE$ElGHG # energy emissions equal total LRE enGHG - LRE elGHG + CFE elGHG
GHG_hiDRDE_ER_CFE$EmGHG<-us_hiDR_FA$GHG_NC*1e-9 # make sure this refers to the correct us_* file
GHG_hiDRDE_ER_CFE$EmGHG[41]<-GHG_hiDRDE_ER_CFE$EmGHG[40]
GHG_hiDRDE_ER_CFE$RenGHG<-renGHGall[renGHGall$Scen=="hiTO_Ext",]$MtCO2e
GHG_hiDRDE_ER_CFE$TotGHG<-GHG_hiDRDE_ER_CFE$EmGHG+GHG_hiDRDE_ER_CFE$RenGHG+GHG_hiDRDE_ER_CFE$EnGHG

# hi MFDE 
# add in GHG intensities for 2035 CFE
rs_hiMFDE_all_RR[,c("GHG_int_2020_CFE","GHG_int_2025_CFE")]<-rs_hiMFDE_all_RR[,c("GHG_int_2020_LRE","GHG_int_2025_LRE")]
rs_hiMFDE_all_RR[,c("GHG_int_2030_CFE")]<-0.5*rs_hiMFDE_all_RR[,c("GHG_int_2025_LRE")]
rs_hiMFDE_all_RR[,c("GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")]<-0

rs_hiMFDE_all_AR[,c("GHG_int_2020_CFE","GHG_int_2025_CFE")]<-rs_hiMFDE_all_AR[,c("GHG_int_2020_LRE","GHG_int_2025_LRE")]
rs_hiMFDE_all_AR[,c("GHG_int_2030_CFE")]<-0.5*rs_hiMFDE_all_AR[,c("GHG_int_2025_LRE")]
rs_hiMFDE_all_AR[,c("GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")]<-0

rs_hiMFDE_all_ER[,c("GHG_int_2020_CFE","GHG_int_2025_CFE")]<-rs_hiMFDE_all_ER[,c("GHG_int_2020_LRE","GHG_int_2025_LRE")]
rs_hiMFDE_all_ER[,c("GHG_int_2030_CFE")]<-0.5*rs_hiMFDE_all_ER[,c("GHG_int_2025_LRE")]
rs_hiMFDE_all_ER[,c("GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")]<-0

# add in GHG emissions for CFE
rs_hiMFDE_all_RR[,c("EnGHGkg_hiMF_2020_CFE","EnGHGkg_hiMF_2025_CFE","EnGHGkg_hiMF_2030_CFE","EnGHGkg_hiMF_2035_CFE","EnGHGkg_hiMF_2040_CFE","EnGHGkg_hiMF_2045_CFE","EnGHGkg_hiMF_2050_CFE","EnGHGkg_hiMF_2055_CFE","EnGHGkg_hiMF_2060_CFE")]<-1000* 
  (rs_hiMFDE_all_RR$base_weight*rs_hiMFDE_all_RR[,c("whiMF_2020",  "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")])*
  (rs_hiMFDE_all_RR$Elec_GJ*rs_hiMFDE_all_RR[,c("GHG_int_2020_CFE", "GHG_int_2025_CFE","GHG_int_2030_CFE","GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")]+
     matrix(rep(rs_hiMFDE_all_RR$Gas_GJ*GHGI_NG,9),nrow(rs_hiMFDE_all_RR),9)+ matrix(rep(rs_hiMFDE_all_RR$Oil_GJ*GHGI_FO,9),nrow(rs_hiMFDE_all_RR),9)+ matrix(rep(rs_hiMFDE_all_RR$Prop_GJ*GHGI_LP,9),nrow(rs_hiMFDE_all_RR),9))

rs_hiMFDE_all_AR[,c("EnGHGkg_hiMF_2020_CFE","EnGHGkg_hiMF_2025_CFE","EnGHGkg_hiMF_2030_CFE","EnGHGkg_hiMF_2035_CFE","EnGHGkg_hiMF_2040_CFE","EnGHGkg_hiMF_2045_CFE","EnGHGkg_hiMF_2050_CFE","EnGHGkg_hiMF_2055_CFE","EnGHGkg_hiMF_2060_CFE")]<-1000* 
  (rs_hiMFDE_all_AR$base_weight*rs_hiMFDE_all_AR[,c("whiMF_2020",  "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")])*
  (rs_hiMFDE_all_AR$Elec_GJ*rs_hiMFDE_all_AR[,c("GHG_int_2020_CFE", "GHG_int_2025_CFE","GHG_int_2030_CFE","GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")]+
     matrix(rep(rs_hiMFDE_all_AR$Gas_GJ*GHGI_NG,9),nrow(rs_hiMFDE_all_AR),9)+ matrix(rep(rs_hiMFDE_all_AR$Oil_GJ*GHGI_FO,9),nrow(rs_hiMFDE_all_AR),9)+ matrix(rep(rs_hiMFDE_all_AR$Prop_GJ*GHGI_LP,9),nrow(rs_hiMFDE_all_AR),9))

rs_hiMFDE_all_ER[,c("EnGHGkg_hiMF_2020_CFE","EnGHGkg_hiMF_2025_CFE","EnGHGkg_hiMF_2030_CFE","EnGHGkg_hiMF_2035_CFE","EnGHGkg_hiMF_2040_CFE","EnGHGkg_hiMF_2045_CFE","EnGHGkg_hiMF_2050_CFE","EnGHGkg_hiMF_2055_CFE","EnGHGkg_hiMF_2060_CFE")]<-1000* 
  (rs_hiMFDE_all_ER$base_weight*rs_hiMFDE_all_ER[,c("whiMF_2020",  "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")])*
  (rs_hiMFDE_all_ER$Elec_GJ*rs_hiMFDE_all_ER[,c("GHG_int_2020_CFE", "GHG_int_2025_CFE","GHG_int_2030_CFE","GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")]+
     matrix(rep(rs_hiMFDE_all_ER$Gas_GJ*GHGI_NG,9),nrow(rs_hiMFDE_all_ER),9)+ matrix(rep(rs_hiMFDE_all_ER$Oil_GJ*GHGI_FO,9),nrow(rs_hiMFDE_all_ER),9)+ matrix(rep(rs_hiMFDE_all_ER$Prop_GJ*GHGI_LP,9),nrow(rs_hiMFDE_all_ER),9))

# start compiling emissions
GHG_hiMFDE_RR<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_hiMFDE_all_RR[,176:184])) # emissions in Mt 
GHG_hiMFDE_RR<-data.frame(data.frame(EnGHG=with(select(GHG_hiMFDE_RR,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=3,CharScen="C",RenScen="RR",ElecScen="MC")
names(GHG_hiMFDE_RR)[1:2]<-c("Year","EnGHG")
GHG_hiMFDE_RR$EmGHG<-us_hiMF_FA$GHG_NC*1e-9
GHG_hiMFDE_RR$EmGHG[41]<-GHG_hiMFDE_RR$EmGHG[40]
GHG_hiMFDE_RR$RenGHG<-renGHGall[renGHGall$Scen=="hiMF_Reg",]$MtCO2e
GHG_hiMFDE_RR$TotGHG<-GHG_hiMFDE_RR$EmGHG+GHG_hiMFDE_RR$RenGHG+GHG_hiMFDE_RR$EnGHG

GHG_hiMFDE_RR_LREC<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_hiMFDE_all_RR[,185:193])) # emissions in Mt 
GHG_hiMFDE_RR_LREC<-data.frame(data.frame(EnGHG=with(select(GHG_hiMFDE_RR_LREC,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=3,CharScen="C",RenScen="RR",ElecScen="LREC")
names(GHG_hiMFDE_RR_LREC)[1:2]<-c("Year","EnGHG")
GHG_hiMFDE_RR_LREC$EmGHG<-us_hiMF_FA$GHG_NC*1e-9
GHG_hiMFDE_RR_LREC$EmGHG[41]<-GHG_hiMFDE_RR_LREC$EmGHG[40]
GHG_hiMFDE_RR_LREC$RenGHG<-renGHGall[renGHGall$Scen=="hiMF_Reg",]$MtCO2e
GHG_hiMFDE_RR_LREC$TotGHG<-GHG_hiMFDE_RR_LREC$EmGHG+GHG_hiMFDE_RR_LREC$RenGHG+GHG_hiMFDE_RR_LREC$EnGHG

# for CFE, EnGHG needs to be done first by electricity, and then recombined with fuel EnGHG
rs_hiMFDE_all_RR[,c("ElecGHGkg_2020_LRE","ElecGHGkg_2025_LRE","ElecGHGkg_2030_LRE","ElecGHGkg_2035_LRE","ElecGHGkg_2040_LRE","ElecGHGkg_2045_LRE","ElecGHGkg_2050_LRE","ElecGHGkg_2055_LRE","ElecGHGkg_2060_LRE")]<-1000* 
  (rs_hiMFDE_all_RR$base_weight*rs_hiMFDE_all_RR[,c("whiMF_2020",  "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")])*
  (rs_hiMFDE_all_RR$Elec_GJ*rs_hiMFDE_all_RR[,c("GHG_int_2020_LRE", "GHG_int_2025_LRE","GHG_int_2030_LRE","GHG_int_2035_LRE","GHG_int_2040_LRE","GHG_int_2045_LRE","GHG_int_2050_LRE","GHG_int_2055_LRE","GHG_int_2060_LRE")])

rs_hiMFDE_all_RR[,c("ElecGHGkg_2020_CFE","ElecGHGkg_2025_CFE","ElecGHGkg_2030_CFE","ElecGHGkg_2035_CFE","ElecGHGkg_2040_CFE","ElecGHGkg_2045_CFE","ElecGHGkg_2050_CFE","ElecGHGkg_2055_CFE","ElecGHGkg_2060_CFE")]<-1000* 
  (rs_hiMFDE_all_RR$base_weight*rs_hiMFDE_all_RR[,c("whiMF_2020",  "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")])*
  (rs_hiMFDE_all_RR$Elec_GJ*rs_hiMFDE_all_RR[,c("GHG_int_2020_CFE", "GHG_int_2025_CFE","GHG_int_2030_CFE","GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")])

GHGelec_hiMFDE_RR_LRE<-data.frame(Year=seq(2020,2060,5),ElGHG=1e-9*colSums(rs_hiMFDE_all_RR[,212:220])) # emissions in Mt 
GHGelec_hiMFDE_RR_LRE<-data.frame(data.frame(ElGHG=with(select(GHGelec_hiMFDE_RR_LRE,Year,ElGHG),spline(Year,ElGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="A",RenScen="RR",ElecScen="LRE")
names(GHGelec_hiMFDE_RR_LRE)[1:2]<-c("Year","ElGHG")

GHGelec_hiMFDE_RR_CFE<-data.frame(Year=seq(2020,2060,5),ElGHG=1e-9*colSums(rs_hiMFDE_all_RR[,221:229])) # emissions in Mt 
GHGelec_hiMFDE_RR_CFE<-data.frame(data.frame(ElGHG=with(select(GHGelec_hiMFDE_RR_CFE,Year,ElGHG),spline(Year,ElGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="A",RenScen="RR",ElecScen="CFE")
names(GHGelec_hiMFDE_RR_CFE)[1:2]<-c("Year","ElGHG")

GHGelec_hiMFDE_RR_CFE$ElGHG[1:6]<-GHGelec_hiMFDE_RR_LRE$ElGHG[1:6] # 2020:2025 is same in CFE as in LRE
GHGelec_hiMFDE_RR_CFE$ElGHG[16:41]<-0 # 2035:2060 is 0 in CFE

GHG_hiMFDE_RR_CFE<-GHG_hiMFDE_RR_LREC
GHG_hiMFDE_RR_CFE$ElecScen<-"CFE"
GHG_hiMFDE_RR_CFE$EnGHG<-GHG_hiMFDE_RR_LREC$EnGHG-GHGelec_hiMFDE_RR_LRE$ElGHG+GHGelec_hiMFDE_RR_CFE$ElGHG # energy emissions equal total LRE enGHG - LRE elGHG + CFE elGHG
GHG_hiMFDE_RR_CFE$EmGHG<-us_hiMF_FA$GHG_NC*1e-9 # make sure this refers to the correct us_* file
GHG_hiMFDE_RR_CFE$EmGHG[41]<-GHG_hiMFDE_RR_CFE$EmGHG[40]
GHG_hiMFDE_RR_CFE$RenGHG<-renGHGall[renGHGall$Scen=="hiMF_Reg",]$MtCO2e
GHG_hiMFDE_RR_CFE$TotGHG<-GHG_hiMFDE_RR_CFE$EmGHG+GHG_hiMFDE_RR_CFE$RenGHG+GHG_hiMFDE_RR_CFE$EnGHG

# hiMFDE AR
GHG_hiMFDE_AR<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_hiMFDE_all_AR[,176:184])) # emissions in Mt 
GHG_hiMFDE_AR<-data.frame(data.frame(EnGHG=with(select(GHG_hiMFDE_AR,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=3,CharScen="C",RenScen="AR",ElecScen="MC")
names(GHG_hiMFDE_AR)[1:2]<-c("Year","EnGHG")
GHG_hiMFDE_AR$EmGHG<-us_hiMF_FA$GHG_NC*1e-9
GHG_hiMFDE_AR$EmGHG[41]<-GHG_hiMFDE_AR$EmGHG[40]
GHG_hiMFDE_AR$RenGHG<-renGHGall[renGHGall$Scen=="hiMF_Adv",]$MtCO2e
GHG_hiMFDE_AR$TotGHG<-GHG_hiMFDE_AR$EmGHG+GHG_hiMFDE_AR$RenGHG+GHG_hiMFDE_AR$EnGHG

GHG_hiMFDE_AR_LREC<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_hiMFDE_all_AR[,185:193])) # emissions in Mt 
GHG_hiMFDE_AR_LREC<-data.frame(data.frame(EnGHG=with(select(GHG_hiMFDE_AR_LREC,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=3,CharScen="C",RenScen="AR",ElecScen="LREC")
names(GHG_hiMFDE_AR_LREC)[1:2]<-c("Year","EnGHG")
GHG_hiMFDE_AR_LREC$EmGHG<-us_hiMF_FA$GHG_NC*1e-9
GHG_hiMFDE_AR_LREC$EmGHG[41]<-GHG_hiMFDE_AR_LREC$EmGHG[40]
GHG_hiMFDE_AR_LREC$RenGHG<-renGHGall[renGHGall$Scen=="hiMF_Adv",]$MtCO2e
GHG_hiMFDE_AR_LREC$TotGHG<-GHG_hiMFDE_AR_LREC$EmGHG+GHG_hiMFDE_AR_LREC$RenGHG+GHG_hiMFDE_AR_LREC$EnGHG

# for CFE, EnGHG needs to be done first by electricity, and then recombined with fuel EnGHG
rs_hiMFDE_all_AR[,c("ElecGHGkg_2020_LRE","ElecGHGkg_2025_LRE","ElecGHGkg_2030_LRE","ElecGHGkg_2035_LRE","ElecGHGkg_2040_LRE","ElecGHGkg_2045_LRE","ElecGHGkg_2050_LRE","ElecGHGkg_2055_LRE","ElecGHGkg_2060_LRE")]<-1000* 
  (rs_hiMFDE_all_AR$base_weight*rs_hiMFDE_all_AR[,c("whiMF_2020",  "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")])*
  (rs_hiMFDE_all_AR$Elec_GJ*rs_hiMFDE_all_AR[,c("GHG_int_2020_LRE", "GHG_int_2025_LRE","GHG_int_2030_LRE","GHG_int_2035_LRE","GHG_int_2040_LRE","GHG_int_2045_LRE","GHG_int_2050_LRE","GHG_int_2055_LRE","GHG_int_2060_LRE")])

rs_hiMFDE_all_AR[,c("ElecGHGkg_2020_CFE","ElecGHGkg_2025_CFE","ElecGHGkg_2030_CFE","ElecGHGkg_2035_CFE","ElecGHGkg_2040_CFE","ElecGHGkg_2045_CFE","ElecGHGkg_2050_CFE","ElecGHGkg_2055_CFE","ElecGHGkg_2060_CFE")]<-1000* 
  (rs_hiMFDE_all_AR$base_weight*rs_hiMFDE_all_AR[,c("whiMF_2020",  "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")])*
  (rs_hiMFDE_all_AR$Elec_GJ*rs_hiMFDE_all_AR[,c("GHG_int_2020_CFE", "GHG_int_2025_CFE","GHG_int_2030_CFE","GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")])

GHGelec_hiMFDE_AR_LRE<-data.frame(Year=seq(2020,2060,5),ElGHG=1e-9*colSums(rs_hiMFDE_all_AR[,212:220])) # emissions in Mt 
GHGelec_hiMFDE_AR_LRE<-data.frame(data.frame(ElGHG=with(select(GHGelec_hiMFDE_AR_LRE,Year,ElGHG),spline(Year,ElGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="A",RenScen="AR",ElecScen="LRE")
names(GHGelec_hiMFDE_AR_LRE)[1:2]<-c("Year","ElGHG")

GHGelec_hiMFDE_AR_CFE<-data.frame(Year=seq(2020,2060,5),ElGHG=1e-9*colSums(rs_hiMFDE_all_AR[,221:229])) # emissions in Mt 
GHGelec_hiMFDE_AR_CFE<-data.frame(data.frame(ElGHG=with(select(GHGelec_hiMFDE_AR_CFE,Year,ElGHG),spline(Year,ElGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="A",RenScen="AR",ElecScen="CFE")
names(GHGelec_hiMFDE_AR_CFE)[1:2]<-c("Year","ElGHG")

GHGelec_hiMFDE_AR_CFE$ElGHG[1:6]<-GHGelec_hiMFDE_AR_LRE$ElGHG[1:6] # 2020:2025 is same in CFE as in LRE
GHGelec_hiMFDE_AR_CFE$ElGHG[16:41]<-0 # 2035:2060 is 0 in CFE

GHG_hiMFDE_AR_CFE<-GHG_hiMFDE_AR_LREC
GHG_hiMFDE_AR_CFE$ElecScen<-"CFE"
GHG_hiMFDE_AR_CFE$EnGHG<-GHG_hiMFDE_AR_LREC$EnGHG-GHGelec_hiMFDE_AR_LRE$ElGHG+GHGelec_hiMFDE_AR_CFE$ElGHG # energy emissions equal total LRE enGHG - LRE elGHG + CFE elGHG
GHG_hiMFDE_AR_CFE$EmGHG<-us_hiMF_FA$GHG_NC*1e-9 # make sure this refers to the correct us_* file
GHG_hiMFDE_AR_CFE$EmGHG[41]<-GHG_hiMFDE_AR_CFE$EmGHG[40]
GHG_hiMFDE_AR_CFE$RenGHG<-renGHGall[renGHGall$Scen=="hiMF_Adv",]$MtCO2e
GHG_hiMFDE_AR_CFE$TotGHG<-GHG_hiMFDE_AR_CFE$EmGHG+GHG_hiMFDE_AR_CFE$RenGHG+GHG_hiMFDE_AR_CFE$EnGHG

#hiMFDE ER
GHG_hiMFDE_ER<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_hiMFDE_all_ER[,176:184])) # emissions in Mt 
GHG_hiMFDE_ER<-data.frame(data.frame(EnGHG=with(select(GHG_hiMFDE_ER,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=3,CharScen="C",RenScen="ER",ElecScen="MC")
names(GHG_hiMFDE_ER)[1:2]<-c("Year","EnGHG")
GHG_hiMFDE_ER$EmGHG<-us_hiMF_FA$GHG_NC*1e-9
GHG_hiMFDE_ER$EmGHG[41]<-GHG_hiMFDE_ER$EmGHG[40]
GHG_hiMFDE_ER$RenGHG<-renGHGall[renGHGall$Scen=="hiMF_Ext",]$MtCO2e
GHG_hiMFDE_ER$TotGHG<-GHG_hiMFDE_ER$EmGHG+GHG_hiMFDE_ER$RenGHG+GHG_hiMFDE_ER$EnGHG

GHG_hiMFDE_ER_LREC<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_hiMFDE_all_ER[,185:193])) # emissions in Mt 
GHG_hiMFDE_ER_LREC<-data.frame(data.frame(EnGHG=with(select(GHG_hiMFDE_ER_LREC,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=3,CharScen="C",RenScen="ER",ElecScen="LREC")
names(GHG_hiMFDE_ER_LREC)[1:2]<-c("Year","EnGHG")
GHG_hiMFDE_ER_LREC$EmGHG<-us_hiMF_FA$GHG_NC*1e-9
GHG_hiMFDE_ER_LREC$EmGHG[41]<-GHG_hiMFDE_ER_LREC$EmGHG[40]
GHG_hiMFDE_ER_LREC$RenGHG<-renGHGall[renGHGall$Scen=="hiMF_Ext",]$MtCO2e
GHG_hiMFDE_ER_LREC$TotGHG<-GHG_hiMFDE_ER_LREC$EmGHG+GHG_hiMFDE_ER_LREC$RenGHG+GHG_hiMFDE_ER_LREC$EnGHG

# for CFE, EnGHG needs to be done first by electricity, and then recombined with fuel EnGHG
rs_hiMFDE_all_ER[,c("ElecGHGkg_2020_LRE","ElecGHGkg_2025_LRE","ElecGHGkg_2030_LRE","ElecGHGkg_2035_LRE","ElecGHGkg_2040_LRE","ElecGHGkg_2045_LRE","ElecGHGkg_2050_LRE","ElecGHGkg_2055_LRE","ElecGHGkg_2060_LRE")]<-1000* 
  (rs_hiMFDE_all_ER$base_weight*rs_hiMFDE_all_ER[,c("whiMF_2020",  "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")])*
  (rs_hiMFDE_all_ER$Elec_GJ*rs_hiMFDE_all_ER[,c("GHG_int_2020_LRE", "GHG_int_2025_LRE","GHG_int_2030_LRE","GHG_int_2035_LRE","GHG_int_2040_LRE","GHG_int_2045_LRE","GHG_int_2050_LRE","GHG_int_2055_LRE","GHG_int_2060_LRE")])

rs_hiMFDE_all_ER[,c("ElecGHGkg_2020_CFE","ElecGHGkg_2025_CFE","ElecGHGkg_2030_CFE","ElecGHGkg_2035_CFE","ElecGHGkg_2040_CFE","ElecGHGkg_2045_CFE","ElecGHGkg_2050_CFE","ElecGHGkg_2055_CFE","ElecGHGkg_2060_CFE")]<-1000* 
  (rs_hiMFDE_all_ER$base_weight*rs_hiMFDE_all_ER[,c("whiMF_2020",  "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")])*
  (rs_hiMFDE_all_ER$Elec_GJ*rs_hiMFDE_all_ER[,c("GHG_int_2020_CFE", "GHG_int_2025_CFE","GHG_int_2030_CFE","GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")])

GHGelec_hiMFDE_ER_LRE<-data.frame(Year=seq(2020,2060,5),ElGHG=1e-9*colSums(rs_hiMFDE_all_ER[,212:220])) # emissions in Mt 
GHGelec_hiMFDE_ER_LRE<-data.frame(data.frame(ElGHG=with(select(GHGelec_hiMFDE_ER_LRE,Year,ElGHG),spline(Year,ElGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="A",RenScen="ER",ElecScen="LRE")
names(GHGelec_hiMFDE_ER_LRE)[1:2]<-c("Year","ElGHG")

GHGelec_hiMFDE_ER_CFE<-data.frame(Year=seq(2020,2060,5),ElGHG=1e-9*colSums(rs_hiMFDE_all_ER[,221:229])) # emissions in Mt 
GHGelec_hiMFDE_ER_CFE<-data.frame(data.frame(ElGHG=with(select(GHGelec_hiMFDE_ER_CFE,Year,ElGHG),spline(Year,ElGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="A",RenScen="ER",ElecScen="CFE")
names(GHGelec_hiMFDE_ER_CFE)[1:2]<-c("Year","ElGHG")

GHGelec_hiMFDE_ER_CFE$ElGHG[1:6]<-GHGelec_hiMFDE_ER_LRE$ElGHG[1:6] # 2020:2025 is same in CFE as in LRE
GHGelec_hiMFDE_ER_CFE$ElGHG[16:41]<-0 # 2035:2060 is 0 in CFE

GHG_hiMFDE_ER_CFE<-GHG_hiMFDE_ER_LREC
GHG_hiMFDE_ER_CFE$ElecScen<-"CFE"
GHG_hiMFDE_ER_CFE$EnGHG<-GHG_hiMFDE_ER_LREC$EnGHG-GHGelec_hiMFDE_ER_LRE$ElGHG+GHGelec_hiMFDE_ER_CFE$ElGHG # energy emissions equal total LRE enGHG - LRE elGHG + CFE elGHG
GHG_hiMFDE_ER_CFE$EmGHG<-us_hiMF_FA$GHG_NC*1e-9 # make sure this refers to the correct us_* file
GHG_hiMFDE_ER_CFE$EmGHG[41]<-GHG_hiMFDE_ER_CFE$EmGHG[40]
GHG_hiMFDE_ER_CFE$RenGHG<-renGHGall[renGHGall$Scen=="hiMF_Ext",]$MtCO2e
GHG_hiMFDE_ER_CFE$TotGHG<-GHG_hiMFDE_ER_CFE$EmGHG+GHG_hiMFDE_ER_CFE$RenGHG+GHG_hiMFDE_ER_CFE$EnGHG

# make graphs of housing stock characteristics using dplyr pipe
rs_baseDE_all_RR[,c("Housing Units 2020","Housing Units 2025","Housing Units 2030","Housing Units 2035","Housing Units 2040","Housing Units 2045","Housing Units 2050","Housing Units 2055","Housing Units 2060")]<-
  rs_baseDE_all_RR$base_weight*rs_baseDE_all_RR[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")]

rs_baseDE_all_AR[,c("Housing Units 2020","Housing Units 2025","Housing Units 2030","Housing Units 2035","Housing Units 2040","Housing Units 2045","Housing Units 2050","Housing Units 2055","Housing Units 2060")]<-
  rs_baseDE_all_AR$base_weight*rs_baseDE_all_AR[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")]

rs_baseDE_all_ER[,c("Housing Units 2020","Housing Units 2025","Housing Units 2030","Housing Units 2035","Housing Units 2040","Housing Units 2045","Housing Units 2050","Housing Units 2055","Housing Units 2060")]<-
  rs_baseDE_all_ER$base_weight*rs_baseDE_all_ER[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")]

# Fig S7d
r<-melt(rs_baseDE_all_RR %>% group_by(Heating.Fuel) %>% summarise(across(starts_with("Housing Units"),sum)))
names(r)[2]<-'Year'
r$Year<-gsub('Housing Units ','', r$Year)
r[r$Heating.Fuel %in% c("None","Other Fuel"),]$Heating.Fuel<-"Other/None"
windows(width = 7, height = 6.5)
ggplot(r,aes(Year,1e-6*value,fill=Heating.Fuel)) + geom_col() + theme_bw() +
  labs(title = "d) 1C Baseline Stock, Inc. Elec., Reg. Renovation ",  y = "Million Housing Units") + scale_fill_brewer(palette="Dark2")  +
  theme(axis.text=element_text(size=11),axis.title=element_text(size=12,face = "bold"),plot.title = element_text(size = 12))
# Fig S7e
r<-melt(rs_baseDE_all_AR %>% group_by(Heating.Fuel) %>% summarise(across(starts_with("Housing Units"),sum)))
names(r)[2]<-'Year'
r$Year<-gsub('Housing Units ','', r$Year)
r[r$Heating.Fuel %in% c("None","Other Fuel"),]$Heating.Fuel<-"Other/None"
windows(width = 7, height = 6.5)
ggplot(r,aes(Year,1e-6*value,fill=Heating.Fuel)) + geom_col() + theme_bw() +
  labs(title = "e) 1C Baseline Stock, Inc. Elec., Adv. Renovation ",  y = "Million Housing Units") + scale_fill_brewer(palette="Dark2")  +
  theme(axis.text=element_text(size=11),axis.title=element_text(size=12,face = "bold"),plot.title = element_text(size = 12))
# Fig S7f
r<-melt(rs_baseDE_all_ER %>% group_by(Heating.Fuel) %>% summarise(across(starts_with("Housing Units"),sum)))
names(r)[2]<-'Year'
r$Year<-gsub('Housing Units ','', r$Year)
r[r$Heating.Fuel %in% c("None","Other Fuel"),]$Heating.Fuel<-"Other/None"
windows(width = 7, height = 6.5)
ggplot(r,aes(Year,1e-6*value,fill=Heating.Fuel)) + geom_col() + theme_bw() +
  labs(title = "f) 1C Baseline Stock, Inc. Elec., Ext. Renovation ",  y = "Million Housing Units") + scale_fill_brewer(palette="Dark2")  +
  theme(axis.text=element_text(size=11),axis.title=element_text(size=12,face = "bold"),plot.title = element_text(size = 12))

# make graphs of housing stock characteristics using dplyr pipe
rs_hiMFDE_all_RR[,c("Housing Units 2020","Housing Units 2025","Housing Units 2030","Housing Units 2035","Housing Units 2040","Housing Units 2045","Housing Units 2050","Housing Units 2055","Housing Units 2060")]<-
  rs_hiMFDE_all_RR$base_weight*rs_hiMFDE_all_RR[,c("whiMF_2020",  "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")]

rs_hiMFDE_all_AR[,c("Housing Units 2020","Housing Units 2025","Housing Units 2030","Housing Units 2035","Housing Units 2040","Housing Units 2045","Housing Units 2050","Housing Units 2055","Housing Units 2060")]<-
  rs_hiMFDE_all_AR$base_weight*rs_hiMFDE_all_AR[,c("whiMF_2020",  "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")]

rs_hiMFDE_all_ER[,c("Housing Units 2020","Housing Units 2025","Housing Units 2030","Housing Units 2035","Housing Units 2040","Housing Units 2045","Housing Units 2050","Housing Units 2055","Housing Units 2060")]<-
  rs_hiMFDE_all_ER$base_weight*rs_hiMFDE_all_ER[,c("whiMF_2020",  "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")]

# Fig S7g, not included
r<-melt(rs_hiMFDE_all_RR %>% group_by(Heating.Fuel) %>% summarise(across(starts_with("Housing Units"),sum)))
names(r)[2]<-'Year'
r$Year<-gsub('Housing Units ','', r$Year)
r[r$Heating.Fuel %in% c("None","Other Fuel"),]$Heating.Fuel<-"Other/None"
windows(width = 7, height = 6.5)
ggplot(r,aes(Year,1e-6*value,fill=Heating.Fuel)) + geom_col() + theme_bw() +
  labs(title = "g) 3C Hi Multifamily, Inc. Elec., Reg. Renovation ",  y = "Million Housing Units") + scale_fill_brewer(palette="Dark2")  +
  theme(axis.text=element_text(size=11),axis.title=element_text(size=12,face = "bold"),plot.title = element_text(size = 12))
# Fig S7h, not included
r<-melt(rs_hiMFDE_all_AR %>% group_by(Heating.Fuel) %>% summarise(across(starts_with("Housing Units"),sum)))
names(r)[2]<-'Year'
r$Year<-gsub('Housing Units ','', r$Year)
r[r$Heating.Fuel %in% c("None","Other Fuel"),]$Heating.Fuel<-"Other/None"
windows(width = 7, height = 6.5)
ggplot(r,aes(Year,1e-6*value,fill=Heating.Fuel)) + geom_col() + theme_bw() +
  labs(title = "h) 3C Hi Multifamily Deep Elec Adv Renovation ",  y = "Million Housing Units") + scale_fill_brewer(palette="Dark2")  +
  theme(axis.text=element_text(size=11),axis.title=element_text(size=12,face = "bold"),plot.title = element_text(size = 12))
# Fig S7i, not included
r<-melt(rs_hiMFDE_all_ER %>% group_by(Heating.Fuel) %>% summarise(across(starts_with("Housing Units"),sum)))
names(r)[2]<-'Year'
r$Year<-gsub('Housing Units ','', r$Year)
r[r$Heating.Fuel %in% c("None","Other Fuel"),]$Heating.Fuel<-"Other/None"
windows(width = 7, height = 6.5)
ggplot(r,aes(Year,1e-6*value,fill=Heating.Fuel)) + geom_col() + theme_bw() +
  labs(title = "i) 3C Hi Multifamily Deep Elec Ext Renovation ",  y = "Million Housing Units") + scale_fill_brewer(palette="Dark2")  +
  theme(axis.text=element_text(size=11),axis.title=element_text(size=12,face = "bold"),plot.title = element_text(size = 12))

r<-melt(rs_hiMFDE_all_AR %>% filter(Vintage %in% c("2020s","2030s","2040s","2050s")) %>% group_by(Heating.Fuel) %>% summarise(across(starts_with("Housing Units"),sum)))
names(r)[2]<-'Year'
r$Year<-gsub('Housing Units ','', r$Year)
r[r$Heating.Fuel %in% c("None","Other Fuel"),]$Heating.Fuel<-"Other/None"
windows(width = 7, height = 6.5)
ggplot(r,aes(Year,1e-6*value,fill=Heating.Fuel)) + geom_col() + theme_bw() +
  labs(title = "h) 3C Hi Multifamily Deep Elec Adv Renovation, New Housing",  y = "Million Housing Units") + scale_fill_brewer(palette="Dark2")  +
  theme(axis.text=element_text(size=11),axis.title=element_text(size=12,face = "bold"),plot.title = element_text(size = 12))

# electricfication in new homes with DE, by census region
# supp Fig 16a
r<-melt(rs_base_all_RR[rs_base_all_RR$Heating.Fuel=="Electricity",] %>% filter(Vintage %in% c("2020s","2030s","2040s","2050s")) %>% group_by(Census.Region,Vintage) %>% summarise(across(starts_with("Housing Units"),sum)))
names(r)[3]<-'Year'
r$Year<-gsub('Housing Units ','', r$Year)
r$Year_Vint<-paste(r$Year,r$Vintage,sep="_")
r<-r %>% filter(Year_Vint %in% c("2025_2020s","2030_2020s",
                                 "2035_2030s","2040_2030s",
                                 "2045_2040s","2050_2040s",
                                 "2055_2050s","2060_2050s"))
r[r$Year=="2030",]$value<-r[r$Year=="2030",]$value-r[r$Year=="2025",]$value

r2<-melt(rs_base_all_RR %>% filter(Vintage %in% c("2020s","2030s","2040s","2050s")) %>% group_by(Census.Region,Vintage) %>% summarise(across(starts_with("Housing Units"),sum)))
names(r2)[3]<-'Year'
r2$Year<-gsub('Housing Units ','', r2$Year)
r2$Year_Vint<-paste(r2$Year,r2$Vintage,sep="_")
r2<-r2 %>% filter(Year_Vint %in% c("2025_2020s","2030_2020s",
                                   "2035_2030s","2040_2030s",
                                   "2045_2040s","2050_2040s",
                                   "2055_2050s","2060_2050s"))
r2[r2$Year=="2030",]$value<-r2[r2$Year=="2030",]$value-r2[r2$Year=="2025",]$value

names(r2)[4]<-"All"
names(r)[4]<-"Elec"
r3<-merge(r,r2)
r3$Elec_pc<-r3$Elec/r3$All

windows(width = 7.6, height = 5.8)
ggplot(r3,aes(Year,Elec_pc,group=Census.Region)) + geom_line(aes(color=Census.Region),size=1) + theme_bw() + scale_y_continuous(labels = scales::percent,limits = c(0,1)) +
  labs(title = "a) Share of new construction with electric heating, by Census Region", subtitle = "Base Housing Characteristics",  y = "% of New Housing") + scale_fill_manual(values=cols)  +
  theme(axis.text=element_text(size=11),axis.title=element_text(size=12,face = "bold"),plot.title = element_text(size = 12))

# supp Fig 16b
r<-melt(rs_baseDE_all_RR[rs_baseDE_all_RR$Heating.Fuel=="Electricity",] %>% filter(Vintage %in% c("2020s","2030s","2040s","2050s")) %>% group_by(Census.Region,Vintage) %>% summarise(across(starts_with("Housing Units"),sum)))
names(r)[3]<-'Year'
r$Year<-gsub('Housing Units ','', r$Year)
r$Year_Vint<-paste(r$Year,r$Vintage,sep="_")
r<-r %>% filter(Year_Vint %in% c("2025_2020s","2030_2020s",
                                 "2035_2030s","2040_2030s",
                                 "2045_2040s","2050_2040s",
                                 "2055_2050s","2060_2050s"))
r[r$Year=="2030",]$value<-r[r$Year=="2030",]$value-r[r$Year=="2025",]$value

r2<-melt(rs_baseDE_all_RR %>% filter(Vintage %in% c("2020s","2030s","2040s","2050s")) %>% group_by(Census.Region,Vintage) %>% summarise(across(starts_with("Housing Units"),sum)))
names(r2)[3]<-'Year'
r2$Year<-gsub('Housing Units ','', r2$Year)
r2$Year_Vint<-paste(r2$Year,r2$Vintage,sep="_")
r2<-r2 %>% filter(Year_Vint %in% c("2025_2020s","2030_2020s",
                                 "2035_2030s","2040_2030s",
                                 "2045_2040s","2050_2040s",
                                 "2055_2050s","2060_2050s"))
r2[r2$Year=="2030",]$value<-r2[r2$Year=="2030",]$value-r2[r2$Year=="2025",]$value

names(r2)[4]<-"All"
names(r)[4]<-"Elec"
r3<-merge(r,r2)
r3$Elec_pc<-r3$Elec/r3$All

windows(width = 7.6, height = 5.8)
ggplot(r3,aes(Year,Elec_pc,group=Census.Region)) + geom_line(aes(color=Census.Region),size=1) + theme_bw() + scale_y_continuous(labels = scales::percent,limits = c(0,1)) +
  labs(title = "b) Share of new construction with electric heating, by Census Region", subtitle = "Increased Electrification",  y = "% of New Housing") + scale_fill_manual(values=cols)  +
  theme(axis.text=element_text(size=11),axis.title=element_text(size=12,face = "bold"),plot.title = element_text(size = 12))

rm(list=ls(pattern = "rs_"))
rm(list=ls(pattern = "GHGelec"))

# FOURTH DERFA scripts #########
load("../Final_results/res_baseDERFA_RR.RData")
load("../Final_results/res_baseDERFA_AR.RData")
load("../Final_results/res_baseDERFA_ER.RData")
load("../Final_results/res_hiDRDERFA_RR.RData")
load("../Final_results/res_hiDRDERFA_AR.RData")
load("../Final_results/res_hiDRDERFA_ER.RData")
load("../Final_results/res_hiMFDERFA_RR.RData")
load("../Final_results/res_hiMFDERFA_AR.RData")
load("../Final_results/res_hiMFDERFA_ER.RData")

# add in GHG intensities for 2035 CFE
rs_baseDERFA_all_RR[,c("GHG_int_2020_CFE","GHG_int_2025_CFE")]<-rs_baseDERFA_all_RR[,c("GHG_int_2020_LRE","GHG_int_2025_LRE")]
rs_baseDERFA_all_RR[,c("GHG_int_2030_CFE")]<-0.5*rs_baseDERFA_all_RR[,c("GHG_int_2025_LRE")]
rs_baseDERFA_all_RR[,c("GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")]<-0

rs_baseDERFA_all_AR[,c("GHG_int_2020_CFE","GHG_int_2025_CFE")]<-rs_baseDERFA_all_AR[,c("GHG_int_2020_LRE","GHG_int_2025_LRE")]
rs_baseDERFA_all_AR[,c("GHG_int_2030_CFE")]<-0.5*rs_baseDERFA_all_AR[,c("GHG_int_2025_LRE")]
rs_baseDERFA_all_AR[,c("GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")]<-0

rs_baseDERFA_all_ER[,c("GHG_int_2020_CFE","GHG_int_2025_CFE")]<-rs_baseDERFA_all_ER[,c("GHG_int_2020_LRE","GHG_int_2025_LRE")]
rs_baseDERFA_all_ER[,c("GHG_int_2030_CFE")]<-0.5*rs_baseDERFA_all_ER[,c("GHG_int_2025_LRE")]
rs_baseDERFA_all_ER[,c("GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")]<-0

# add in GHG emissions for CFE
rs_baseDERFA_all_RR[,c("EnGHGkg_baseDERFA_2020_CFE","EnGHGkg_baseDERFA_2025_CFE","EnGHGkg_baseDERFA_2030_CFE","EnGHGkg_baseDERFA_2035_CFE","EnGHGkg_baseDERFA_2040_CFE","EnGHGkg_baseDERFA_2045_CFE","EnGHGkg_baseDERFA_2050_CFE","EnGHGkg_baseDERFA_2055_CFE","EnGHGkg_baseDERFA_2060_CFE")]<-1000* 
  (rs_baseDERFA_all_RR$base_weight*rs_baseDERFA_all_RR[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*
  (rs_baseDERFA_all_RR$Elec_GJ*rs_baseDERFA_all_RR[,c("GHG_int_2020_CFE", "GHG_int_2025_CFE","GHG_int_2030_CFE","GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")]+
     matrix(rep(rs_baseDERFA_all_RR$Gas_GJ*GHGI_NG,9),nrow(rs_baseDERFA_all_RR),9)+ matrix(rep(rs_baseDERFA_all_RR$Oil_GJ*GHGI_FO,9),nrow(rs_baseDERFA_all_RR),9)+ matrix(rep(rs_baseDERFA_all_RR$Prop_GJ*GHGI_LP,9),nrow(rs_baseDERFA_all_RR),9))

rs_baseDERFA_all_AR[,c("EnGHGkg_baseDERFA_2020_CFE","EnGHGkg_baseDERFA_2025_CFE","EnGHGkg_baseDERFA_2030_CFE","EnGHGkg_baseDERFA_2035_CFE","EnGHGkg_baseDERFA_2040_CFE","EnGHGkg_baseDERFA_2045_CFE","EnGHGkg_baseDERFA_2050_CFE","EnGHGkg_baseDERFA_2055_CFE","EnGHGkg_baseDERFA_2060_CFE")]<-1000* 
  (rs_baseDERFA_all_AR$base_weight*rs_baseDERFA_all_AR[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*
  (rs_baseDERFA_all_AR$Elec_GJ*rs_baseDERFA_all_AR[,c("GHG_int_2020_CFE", "GHG_int_2025_CFE","GHG_int_2030_CFE","GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")]+
     matrix(rep(rs_baseDERFA_all_AR$Gas_GJ*GHGI_NG,9),nrow(rs_baseDERFA_all_AR),9)+ matrix(rep(rs_baseDERFA_all_AR$Oil_GJ*GHGI_FO,9),nrow(rs_baseDERFA_all_AR),9)+ matrix(rep(rs_baseDERFA_all_AR$Prop_GJ*GHGI_LP,9),nrow(rs_baseDERFA_all_AR),9))

rs_baseDERFA_all_ER[,c("EnGHGkg_baseDERFA_2020_CFE","EnGHGkg_baseDERFA_2025_CFE","EnGHGkg_baseDERFA_2030_CFE","EnGHGkg_baseDERFA_2035_CFE","EnGHGkg_baseDERFA_2040_CFE","EnGHGkg_baseDERFA_2045_CFE","EnGHGkg_baseDERFA_2050_CFE","EnGHGkg_baseDERFA_2055_CFE","EnGHGkg_baseDERFA_2060_CFE")]<-1000*
  (rs_baseDERFA_all_ER$base_weight*rs_baseDERFA_all_ER[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*
  (rs_baseDERFA_all_ER$Elec_GJ*rs_baseDERFA_all_ER[,c("GHG_int_2020_CFE", "GHG_int_2025_CFE","GHG_int_2030_CFE","GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")]+
     matrix(rep(rs_baseDERFA_all_ER$Gas_GJ*GHGI_NG,9),nrow(rs_baseDERFA_all_ER),9)+ matrix(rep(rs_baseDERFA_all_ER$Oil_GJ*GHGI_FO,9),nrow(rs_baseDERFA_all_ER),9)+ matrix(rep(rs_baseDERFA_all_ER$Prop_GJ*GHGI_LP,9),nrow(rs_baseDERFA_all_ER),9))

# start compiling emissions
GHG_baseDERFA_RR<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_baseDERFA_all_RR[,176:184])) # emissions in Mt 
GHG_baseDERFA_RR<-data.frame(data.frame(EnGHG=with(select(GHG_baseDERFA_RR,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="D",RenScen="RR",ElecScen="MC")
names(GHG_baseDERFA_RR)[1:2]<-c("Year","EnGHG")
GHG_baseDERFA_RR$EmGHG<-us_RFA_FA$GHG_NC*1e-9
GHG_baseDERFA_RR$EmGHG[41]<-GHG_baseDERFA_RR$EmGHG[40]
GHG_baseDERFA_RR$RenGHG<-renGHGall[renGHGall$Scen=="Base_Reg",]$MtCO2e
GHG_baseDERFA_RR$TotGHG<-GHG_baseDERFA_RR$EmGHG+GHG_baseDERFA_RR$RenGHG+GHG_baseDERFA_RR$EnGHG

GHG_baseDERFA_RR_LREC<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_baseDERFA_all_RR[,185:193])) # emissions in Mt 
GHG_baseDERFA_RR_LREC<-data.frame(data.frame(EnGHG=with(select(GHG_baseDERFA_RR_LREC,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="D",RenScen="RR",ElecScen="LREC")
names(GHG_baseDERFA_RR_LREC)[1:2]<-c("Year","EnGHG")
GHG_baseDERFA_RR_LREC$EmGHG<-us_RFA_FA$GHG_NC*1e-9
GHG_baseDERFA_RR_LREC$EmGHG[41]<-GHG_baseDERFA_RR_LREC$EmGHG[40]
GHG_baseDERFA_RR_LREC$RenGHG<-renGHGall[renGHGall$Scen=="Base_Reg",]$MtCO2e
GHG_baseDERFA_RR_LREC$TotGHG<-GHG_baseDERFA_RR_LREC$EmGHG+GHG_baseDERFA_RR_LREC$RenGHG+GHG_baseDERFA_RR_LREC$EnGHG

# for CFE, EnGHG needs to be done first by electricity, and then recombined with fuel EnGHG
rs_baseDERFA_all_RR[,c("ElecGHGkg_2020_LRE","ElecGHGkg_2025_LRE","ElecGHGkg_2030_LRE","ElecGHGkg_2035_LRE","ElecGHGkg_2040_LRE","ElecGHGkg_2045_LRE","ElecGHGkg_2050_LRE","ElecGHGkg_2055_LRE","ElecGHGkg_2060_LRE")]<-1000* 
  (rs_baseDERFA_all_RR$base_weight*rs_baseDERFA_all_RR[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*
  (rs_baseDERFA_all_RR$Elec_GJ*rs_baseDERFA_all_RR[,c("GHG_int_2020_LRE", "GHG_int_2025_LRE","GHG_int_2030_LRE","GHG_int_2035_LRE","GHG_int_2040_LRE","GHG_int_2045_LRE","GHG_int_2050_LRE","GHG_int_2055_LRE","GHG_int_2060_LRE")])

rs_baseDERFA_all_RR[,c("ElecGHGkg_2020_CFE","ElecGHGkg_2025_CFE","ElecGHGkg_2030_CFE","ElecGHGkg_2035_CFE","ElecGHGkg_2040_CFE","ElecGHGkg_2045_CFE","ElecGHGkg_2050_CFE","ElecGHGkg_2055_CFE","ElecGHGkg_2060_CFE")]<-1000* 
  (rs_baseDERFA_all_RR$base_weight*rs_baseDERFA_all_RR[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*
  (rs_baseDERFA_all_RR$Elec_GJ*rs_baseDERFA_all_RR[,c("GHG_int_2020_CFE", "GHG_int_2025_CFE","GHG_int_2030_CFE","GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")])

GHGelec_baseDERFA_RR_LRE<-data.frame(Year=seq(2020,2060,5),ElGHG=1e-9*colSums(rs_baseDERFA_all_RR[,212:220])) # emissions in Mt 
GHGelec_baseDERFA_RR_LRE<-data.frame(data.frame(ElGHG=with(select(GHGelec_baseDERFA_RR_LRE,Year,ElGHG),spline(Year,ElGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="A",RenScen="RR",ElecScen="LRE")
names(GHGelec_baseDERFA_RR_LRE)[1:2]<-c("Year","ElGHG")

GHGelec_baseDERFA_RR_CFE<-data.frame(Year=seq(2020,2060,5),ElGHG=1e-9*colSums(rs_baseDERFA_all_RR[,221:229])) # emissions in Mt 
GHGelec_baseDERFA_RR_CFE<-data.frame(data.frame(ElGHG=with(select(GHGelec_baseDERFA_RR_CFE,Year,ElGHG),spline(Year,ElGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="A",RenScen="RR",ElecScen="CFE")
names(GHGelec_baseDERFA_RR_CFE)[1:2]<-c("Year","ElGHG")

GHGelec_baseDERFA_RR_CFE$ElGHG[1:6]<-GHGelec_baseDERFA_RR_LRE$ElGHG[1:6] # 2020:2025 is same in CFE as in LRE
GHGelec_baseDERFA_RR_CFE$ElGHG[16:41]<-0 # 2035:2060 is 0 in CFE

GHG_baseDERFA_RR_CFE<-GHG_baseDERFA_RR_LREC
GHG_baseDERFA_RR_CFE$ElecScen<-"CFE"
GHG_baseDERFA_RR_CFE$EnGHG<-GHG_baseDERFA_RR_LREC$EnGHG-GHGelec_baseDERFA_RR_LRE$ElGHG+GHGelec_baseDERFA_RR_CFE$ElGHG # energy emissions equal total LRE enGHG - LRE elGHG + CFE elGHG
GHG_baseDERFA_RR_CFE$EmGHG<-us_RFA_FA$GHG_NC*1e-9 # make sure this refers to the correct us_* file
GHG_baseDERFA_RR_CFE$EmGHG[41]<-GHG_baseDERFA_RR_CFE$EmGHG[40]
GHG_baseDERFA_RR_CFE$RenGHG<-renGHGall[renGHGall$Scen=="Base_Reg",]$MtCO2e
GHG_baseDERFA_RR_CFE$TotGHG<-GHG_baseDERFA_RR_CFE$EmGHG+GHG_baseDERFA_RR_CFE$RenGHG+GHG_baseDERFA_RR_CFE$EnGHG

# DERFA AR
GHG_baseDERFA_AR<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_baseDERFA_all_AR[,176:184])) # emissions in Mt 
GHG_baseDERFA_AR<-data.frame(data.frame(EnGHG=with(select(GHG_baseDERFA_AR,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="D",RenScen="AR",ElecScen="MC")
names(GHG_baseDERFA_AR)[1:2]<-c("Year","EnGHG")
GHG_baseDERFA_AR$EmGHG<-us_RFA_FA$GHG_NC*1e-9
GHG_baseDERFA_AR$EmGHG[41]<-GHG_baseDERFA_AR$EmGHG[40]
GHG_baseDERFA_AR$RenGHG<-renGHGall[renGHGall$Scen=="Base_Adv",]$MtCO2e
GHG_baseDERFA_AR$TotGHG<-GHG_baseDERFA_AR$EmGHG+GHG_baseDERFA_AR$RenGHG+GHG_baseDERFA_AR$EnGHG

GHG_baseDERFA_AR_LREC<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_baseDERFA_all_AR[,185:193])) # emissions in Mt 
GHG_baseDERFA_AR_LREC<-data.frame(data.frame(EnGHG=with(select(GHG_baseDERFA_AR_LREC,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="D",RenScen="AR",ElecScen="LREC")
names(GHG_baseDERFA_AR_LREC)[1:2]<-c("Year","EnGHG")
GHG_baseDERFA_AR_LREC$EmGHG<-us_RFA_FA$GHG_NC*1e-9
GHG_baseDERFA_AR_LREC$EmGHG[41]<-GHG_baseDERFA_AR_LREC$EmGHG[40]
GHG_baseDERFA_AR_LREC$RenGHG<-renGHGall[renGHGall$Scen=="Base_Adv",]$MtCO2e
GHG_baseDERFA_AR_LREC$TotGHG<-GHG_baseDERFA_AR_LREC$EmGHG+GHG_baseDERFA_AR_LREC$RenGHG+GHG_baseDERFA_AR_LREC$EnGHG

# for CFE, EnGHG needs to be done first by electricity, and then recombined with fuel EnGHG
rs_baseDERFA_all_AR[,c("ElecGHGkg_2020_LRE","ElecGHGkg_2025_LRE","ElecGHGkg_2030_LRE","ElecGHGkg_2035_LRE","ElecGHGkg_2040_LRE","ElecGHGkg_2045_LRE","ElecGHGkg_2050_LRE","ElecGHGkg_2055_LRE","ElecGHGkg_2060_LRE")]<-1000* 
  (rs_baseDERFA_all_AR$base_weight*rs_baseDERFA_all_AR[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*
  (rs_baseDERFA_all_AR$Elec_GJ*rs_baseDERFA_all_AR[,c("GHG_int_2020_LRE", "GHG_int_2025_LRE","GHG_int_2030_LRE","GHG_int_2035_LRE","GHG_int_2040_LRE","GHG_int_2045_LRE","GHG_int_2050_LRE","GHG_int_2055_LRE","GHG_int_2060_LRE")])

rs_baseDERFA_all_AR[,c("ElecGHGkg_2020_CFE","ElecGHGkg_2025_CFE","ElecGHGkg_2030_CFE","ElecGHGkg_2035_CFE","ElecGHGkg_2040_CFE","ElecGHGkg_2045_CFE","ElecGHGkg_2050_CFE","ElecGHGkg_2055_CFE","ElecGHGkg_2060_CFE")]<-1000* 
  (rs_baseDERFA_all_AR$base_weight*rs_baseDERFA_all_AR[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*
  (rs_baseDERFA_all_AR$Elec_GJ*rs_baseDERFA_all_AR[,c("GHG_int_2020_CFE", "GHG_int_2025_CFE","GHG_int_2030_CFE","GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")])

GHGelec_baseDERFA_AR_LRE<-data.frame(Year=seq(2020,2060,5),ElGHG=1e-9*colSums(rs_baseDERFA_all_AR[,212:220])) # emissions in Mt 
GHGelec_baseDERFA_AR_LRE<-data.frame(data.frame(ElGHG=with(select(GHGelec_baseDERFA_AR_LRE,Year,ElGHG),spline(Year,ElGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="A",RenScen="AR",ElecScen="LRE")
names(GHGelec_baseDERFA_AR_LRE)[1:2]<-c("Year","ElGHG")

GHGelec_baseDERFA_AR_CFE<-data.frame(Year=seq(2020,2060,5),ElGHG=1e-9*colSums(rs_baseDERFA_all_AR[,221:229])) # emissions in Mt 
GHGelec_baseDERFA_AR_CFE<-data.frame(data.frame(ElGHG=with(select(GHGelec_baseDERFA_AR_CFE,Year,ElGHG),spline(Year,ElGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="A",RenScen="AR",ElecScen="CFE")
names(GHGelec_baseDERFA_AR_CFE)[1:2]<-c("Year","ElGHG")

GHGelec_baseDERFA_AR_CFE$ElGHG[1:6]<-GHGelec_baseDERFA_AR_LRE$ElGHG[1:6] # 2020:2025 is same in CFE as in LRE
GHGelec_baseDERFA_AR_CFE$ElGHG[16:41]<-0 # 2035:2060 is 0 in CFE

GHG_baseDERFA_AR_CFE<-GHG_baseDERFA_AR_LREC
GHG_baseDERFA_AR_CFE$ElecScen<-"CFE"
GHG_baseDERFA_AR_CFE$EnGHG<-GHG_baseDERFA_AR_LREC$EnGHG-GHGelec_baseDERFA_AR_LRE$ElGHG+GHGelec_baseDERFA_AR_CFE$ElGHG # energy emissions equal total LRE enGHG - LRE elGHG + CFE elGHG
GHG_baseDERFA_AR_CFE$EmGHG<-us_RFA_FA$GHG_NC*1e-9 # make sure this refers to the correct us_* file
GHG_baseDERFA_AR_CFE$EmGHG[41]<-GHG_baseDERFA_AR_CFE$EmGHG[40]
GHG_baseDERFA_AR_CFE$RenGHG<-renGHGall[renGHGall$Scen=="Base_Adv",]$MtCO2e
GHG_baseDERFA_AR_CFE$TotGHG<-GHG_baseDERFA_AR_CFE$EmGHG+GHG_baseDERFA_AR_CFE$RenGHG+GHG_baseDERFA_AR_CFE$EnGHG

# DERFA ER
GHG_baseDERFA_ER<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_baseDERFA_all_ER[,176:184])) # emissions in Mt 
GHG_baseDERFA_ER<-data.frame(data.frame(EnGHG=with(select(GHG_baseDERFA_ER,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="D",RenScen="ER",ElecScen="MC")
names(GHG_baseDERFA_ER)[1:2]<-c("Year","EnGHG")
GHG_baseDERFA_ER$EmGHG<-us_RFA_FA$GHG_NC*1e-9
GHG_baseDERFA_ER$EmGHG[41]<-GHG_baseDERFA_ER$EmGHG[40]
GHG_baseDERFA_ER$RenGHG<-renGHGall[renGHGall$Scen=="Base_Ext",]$MtCO2e
GHG_baseDERFA_ER$TotGHG<-GHG_baseDERFA_ER$EmGHG+GHG_baseDERFA_ER$RenGHG+GHG_baseDERFA_ER$EnGHG

GHG_baseDERFA_ER_LREC<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_baseDERFA_all_ER[,185:193])) # emissions in Mt 
GHG_baseDERFA_ER_LREC<-data.frame(data.frame(EnGHG=with(select(GHG_baseDERFA_ER_LREC,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="D",RenScen="ER",ElecScen="LREC")
names(GHG_baseDERFA_ER_LREC)[1:2]<-c("Year","EnGHG")
GHG_baseDERFA_ER_LREC$EmGHG<-us_RFA_FA$GHG_NC*1e-9
GHG_baseDERFA_ER_LREC$EmGHG[41]<-GHG_baseDERFA_ER_LREC$EmGHG[40]
GHG_baseDERFA_ER_LREC$RenGHG<-renGHGall[renGHGall$Scen=="Base_Ext",]$MtCO2e
GHG_baseDERFA_ER_LREC$TotGHG<-GHG_baseDERFA_ER_LREC$EmGHG+GHG_baseDERFA_ER_LREC$RenGHG+GHG_baseDERFA_ER_LREC$EnGHG

# for CFE, EnGHG needs to be done first by electricity, and then recombined with fuel EnGHG
rs_baseDERFA_all_ER[,c("ElecGHGkg_2020_LRE","ElecGHGkg_2025_LRE","ElecGHGkg_2030_LRE","ElecGHGkg_2035_LRE","ElecGHGkg_2040_LRE","ElecGHGkg_2045_LRE","ElecGHGkg_2050_LRE","ElecGHGkg_2055_LRE","ElecGHGkg_2060_LRE")]<-1000* 
  (rs_baseDERFA_all_ER$base_weight*rs_baseDERFA_all_ER[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*
  (rs_baseDERFA_all_ER$Elec_GJ*rs_baseDERFA_all_ER[,c("GHG_int_2020_LRE", "GHG_int_2025_LRE","GHG_int_2030_LRE","GHG_int_2035_LRE","GHG_int_2040_LRE","GHG_int_2045_LRE","GHG_int_2050_LRE","GHG_int_2055_LRE","GHG_int_2060_LRE")])

rs_baseDERFA_all_ER[,c("ElecGHGkg_2020_CFE","ElecGHGkg_2025_CFE","ElecGHGkg_2030_CFE","ElecGHGkg_2035_CFE","ElecGHGkg_2040_CFE","ElecGHGkg_2045_CFE","ElecGHGkg_2050_CFE","ElecGHGkg_2055_CFE","ElecGHGkg_2060_CFE")]<-1000* 
  (rs_baseDERFA_all_ER$base_weight*rs_baseDERFA_all_ER[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*
  (rs_baseDERFA_all_ER$Elec_GJ*rs_baseDERFA_all_ER[,c("GHG_int_2020_CFE", "GHG_int_2025_CFE","GHG_int_2030_CFE","GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")])

GHGelec_baseDERFA_ER_LRE<-data.frame(Year=seq(2020,2060,5),ElGHG=1e-9*colSums(rs_baseDERFA_all_ER[,212:220])) # emissions in Mt 
GHGelec_baseDERFA_ER_LRE<-data.frame(data.frame(ElGHG=with(select(GHGelec_baseDERFA_ER_LRE,Year,ElGHG),spline(Year,ElGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="A",RenScen="ER",ElecScen="LRE")
names(GHGelec_baseDERFA_ER_LRE)[1:2]<-c("Year","ElGHG")

GHGelec_baseDERFA_ER_CFE<-data.frame(Year=seq(2020,2060,5),ElGHG=1e-9*colSums(rs_baseDERFA_all_ER[,221:229])) # emissions in Mt 
GHGelec_baseDERFA_ER_CFE<-data.frame(data.frame(ElGHG=with(select(GHGelec_baseDERFA_ER_CFE,Year,ElGHG),spline(Year,ElGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="A",RenScen="ER",ElecScen="CFE")
names(GHGelec_baseDERFA_ER_CFE)[1:2]<-c("Year","ElGHG")

GHGelec_baseDERFA_ER_CFE$ElGHG[1:6]<-GHGelec_baseDERFA_ER_LRE$ElGHG[1:6] # 2020:2025 is same in CFE as in LRE
GHGelec_baseDERFA_ER_CFE$ElGHG[16:41]<-0 # 2035:2060 is 0 in CFE

GHG_baseDERFA_ER_CFE<-GHG_baseDERFA_ER_LREC
GHG_baseDERFA_ER_CFE$ElecScen<-"CFE"
GHG_baseDERFA_ER_CFE$EnGHG<-GHG_baseDERFA_ER_LREC$EnGHG-GHGelec_baseDERFA_ER_LRE$ElGHG+GHGelec_baseDERFA_ER_CFE$ElGHG # energy emissions equal total LRE enGHG - LRE elGHG + CFE elGHG
GHG_baseDERFA_ER_CFE$EmGHG<-us_RFA_FA$GHG_NC*1e-9 # make sure this refers to the correct us_* file
GHG_baseDERFA_ER_CFE$EmGHG[41]<-GHG_baseDERFA_ER_CFE$EmGHG[40]
GHG_baseDERFA_ER_CFE$RenGHG<-renGHGall[renGHGall$Scen=="Base_Ext",]$MtCO2e
GHG_baseDERFA_ER_CFE$TotGHG<-GHG_baseDERFA_ER_CFE$EmGHG+GHG_baseDERFA_ER_CFE$RenGHG+GHG_baseDERFA_ER_CFE$EnGHG

# hi DR DERFA
# add in GHG intensities for 2035 CFE
rs_hiDRDERFA_all_RR[,c("GHG_int_2020_CFE","GHG_int_2025_CFE")]<-rs_hiDRDERFA_all_RR[,c("GHG_int_2020_LRE","GHG_int_2025_LRE")]
rs_hiDRDERFA_all_RR[,c("GHG_int_2030_CFE")]<-0.5*rs_hiDRDERFA_all_RR[,c("GHG_int_2025_LRE")]
rs_hiDRDERFA_all_RR[,c("GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")]<-0

rs_hiDRDERFA_all_AR[,c("GHG_int_2020_CFE","GHG_int_2025_CFE")]<-rs_hiDRDERFA_all_AR[,c("GHG_int_2020_LRE","GHG_int_2025_LRE")]
rs_hiDRDERFA_all_AR[,c("GHG_int_2030_CFE")]<-0.5*rs_hiDRDERFA_all_AR[,c("GHG_int_2025_LRE")]
rs_hiDRDERFA_all_AR[,c("GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")]<-0

rs_hiDRDERFA_all_ER[,c("GHG_int_2020_CFE","GHG_int_2025_CFE")]<-rs_hiDRDERFA_all_ER[,c("GHG_int_2020_LRE","GHG_int_2025_LRE")]
rs_hiDRDERFA_all_ER[,c("GHG_int_2030_CFE")]<-0.5*rs_hiDRDERFA_all_ER[,c("GHG_int_2025_LRE")]
rs_hiDRDERFA_all_ER[,c("GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")]<-0

# add in GHG emissions for CFE
rs_hiDRDERFA_all_RR[,c("EnGHGkg_hiDR_2020_CFE","EnGHGkg_hiDR_2025_CFE","EnGHGkg_hiDR_2030_CFE","EnGHGkg_hiDR_2035_CFE","EnGHGkg_hiDR_2040_CFE","EnGHGkg_hiDR_2045_CFE","EnGHGkg_hiDR_2050_CFE","EnGHGkg_hiDR_2055_CFE","EnGHGkg_hiDR_2060_CFE")]<-1000* 
  (rs_hiDRDERFA_all_RR$base_weight*rs_hiDRDERFA_all_RR[,c("whiDR_2020",  "whiDR_2025", "whiDR_2030", "whiDR_2035", "whiDR_2040", "whiDR_2045", "whiDR_2050", "whiDR_2055", "whiDR_2060")])*
  (rs_hiDRDERFA_all_RR$Elec_GJ*rs_hiDRDERFA_all_RR[,c("GHG_int_2020_CFE", "GHG_int_2025_CFE","GHG_int_2030_CFE","GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")]+
     matrix(rep(rs_hiDRDERFA_all_RR$Gas_GJ*GHGI_NG,9),nrow(rs_hiDRDERFA_all_RR),9)+ matrix(rep(rs_hiDRDERFA_all_RR$Oil_GJ*GHGI_FO,9),nrow(rs_hiDRDERFA_all_RR),9)+ matrix(rep(rs_hiDRDERFA_all_RR$Prop_GJ*GHGI_LP,9),nrow(rs_hiDRDERFA_all_RR),9))

rs_hiDRDERFA_all_AR[,c("EnGHGkg_hiDR_2020_CFE","EnGHGkg_hiDR_2025_CFE","EnGHGkg_hiDR_2030_CFE","EnGHGkg_hiDR_2035_CFE","EnGHGkg_hiDR_2040_CFE","EnGHGkg_hiDR_2045_CFE","EnGHGkg_hiDR_2050_CFE","EnGHGkg_hiDR_2055_CFE","EnGHGkg_hiDR_2060_CFE")]<-1000* 
  (rs_hiDRDERFA_all_AR$base_weight*rs_hiDRDERFA_all_AR[,c("whiDR_2020",  "whiDR_2025", "whiDR_2030", "whiDR_2035", "whiDR_2040", "whiDR_2045", "whiDR_2050", "whiDR_2055", "whiDR_2060")])*
  (rs_hiDRDERFA_all_AR$Elec_GJ*rs_hiDRDERFA_all_AR[,c("GHG_int_2020_CFE", "GHG_int_2025_CFE","GHG_int_2030_CFE","GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")]+
     matrix(rep(rs_hiDRDERFA_all_AR$Gas_GJ*GHGI_NG,9),nrow(rs_hiDRDERFA_all_AR),9)+ matrix(rep(rs_hiDRDERFA_all_AR$Oil_GJ*GHGI_FO,9),nrow(rs_hiDRDERFA_all_AR),9)+ matrix(rep(rs_hiDRDERFA_all_AR$Prop_GJ*GHGI_LP,9),nrow(rs_hiDRDERFA_all_AR),9))

rs_hiDRDERFA_all_ER[,c("EnGHGkg_hiDR_2020_CFE","EnGHGkg_hiDR_2025_CFE","EnGHGkg_hiDR_2030_CFE","EnGHGkg_hiDR_2035_CFE","EnGHGkg_hiDR_2040_CFE","EnGHGkg_hiDR_2045_CFE","EnGHGkg_hiDR_2050_CFE","EnGHGkg_hiDR_2055_CFE","EnGHGkg_hiDR_2060_CFE")]<-1000* 
  (rs_hiDRDERFA_all_ER$base_weight*rs_hiDRDERFA_all_ER[,c("whiDR_2020",  "whiDR_2025", "whiDR_2030", "whiDR_2035", "whiDR_2040", "whiDR_2045", "whiDR_2050", "whiDR_2055", "whiDR_2060")])*
  (rs_hiDRDERFA_all_ER$Elec_GJ*rs_hiDRDERFA_all_ER[,c("GHG_int_2020_CFE", "GHG_int_2025_CFE","GHG_int_2030_CFE","GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")]+
     matrix(rep(rs_hiDRDERFA_all_ER$Gas_GJ*GHGI_NG,9),nrow(rs_hiDRDERFA_all_ER),9)+ matrix(rep(rs_hiDRDERFA_all_ER$Oil_GJ*GHGI_FO,9),nrow(rs_hiDRDERFA_all_ER),9)+ matrix(rep(rs_hiDRDERFA_all_ER$Prop_GJ*GHGI_LP,9),nrow(rs_hiDRDERFA_all_ER),9))

# start compiling emissions
GHG_hiDRDERFA_RR<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_hiDRDERFA_all_RR[,176:184])) # emissions in Mt 
GHG_hiDRDERFA_RR<-data.frame(data.frame(EnGHG=with(select(GHG_hiDRDERFA_RR,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=2,CharScen="D",RenScen="RR",ElecScen="MC")
names(GHG_hiDRDERFA_RR)[1:2]<-c("Year","EnGHG")
GHG_hiDRDERFA_RR$EmGHG<-us_hiDR_RFA_FA$GHG_NC*1e-9
GHG_hiDRDERFA_RR$EmGHG[41]<-GHG_hiDRDERFA_RR$EmGHG[40]
GHG_hiDRDERFA_RR$RenGHG<-renGHGall[renGHGall$Scen=="hiTO_Reg",]$MtCO2e
GHG_hiDRDERFA_RR$TotGHG<-GHG_hiDRDERFA_RR$EmGHG+GHG_hiDRDERFA_RR$RenGHG+GHG_hiDRDERFA_RR$EnGHG

GHG_hiDRDERFA_RR_LREC<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_hiDRDERFA_all_RR[,185:193])) # emissions in Mt 
GHG_hiDRDERFA_RR_LREC<-data.frame(data.frame(EnGHG=with(select(GHG_hiDRDERFA_RR_LREC,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=2,CharScen="D",RenScen="RR",ElecScen="LREC")
names(GHG_hiDRDERFA_RR_LREC)[1:2]<-c("Year","EnGHG")
GHG_hiDRDERFA_RR_LREC$EmGHG<-us_hiDR_RFA_FA$GHG_NC*1e-9
GHG_hiDRDERFA_RR_LREC$EmGHG[41]<-GHG_hiDRDERFA_RR_LREC$EmGHG[40]
GHG_hiDRDERFA_RR_LREC$RenGHG<-renGHGall[renGHGall$Scen=="hiTO_Reg",]$MtCO2e
GHG_hiDRDERFA_RR_LREC$TotGHG<-GHG_hiDRDERFA_RR_LREC$EmGHG+GHG_hiDRDERFA_RR_LREC$RenGHG+GHG_hiDRDERFA_RR_LREC$EnGHG

# for CFE, EnGHG needs to be done first by electricity, and then recombined with fuel EnGHG
rs_hiDRDERFA_all_RR[,c("ElecGHGkg_2020_LRE","ElecGHGkg_2025_LRE","ElecGHGkg_2030_LRE","ElecGHGkg_2035_LRE","ElecGHGkg_2040_LRE","ElecGHGkg_2045_LRE","ElecGHGkg_2050_LRE","ElecGHGkg_2055_LRE","ElecGHGkg_2060_LRE")]<-1000* 
  (rs_hiDRDERFA_all_RR$base_weight*rs_hiDRDERFA_all_RR[,c("whiDR_2020",  "whiDR_2025", "whiDR_2030", "whiDR_2035", "whiDR_2040", "whiDR_2045", "whiDR_2050", "whiDR_2055", "whiDR_2060")])*
  (rs_hiDRDERFA_all_RR$Elec_GJ*rs_hiDRDERFA_all_RR[,c("GHG_int_2020_LRE", "GHG_int_2025_LRE","GHG_int_2030_LRE","GHG_int_2035_LRE","GHG_int_2040_LRE","GHG_int_2045_LRE","GHG_int_2050_LRE","GHG_int_2055_LRE","GHG_int_2060_LRE")])

rs_hiDRDERFA_all_RR[,c("ElecGHGkg_2020_CFE","ElecGHGkg_2025_CFE","ElecGHGkg_2030_CFE","ElecGHGkg_2035_CFE","ElecGHGkg_2040_CFE","ElecGHGkg_2045_CFE","ElecGHGkg_2050_CFE","ElecGHGkg_2055_CFE","ElecGHGkg_2060_CFE")]<-1000* 
  (rs_hiDRDERFA_all_RR$base_weight*rs_hiDRDERFA_all_RR[,c("whiDR_2020",  "whiDR_2025", "whiDR_2030", "whiDR_2035", "whiDR_2040", "whiDR_2045", "whiDR_2050", "whiDR_2055", "whiDR_2060")])*
  (rs_hiDRDERFA_all_RR$Elec_GJ*rs_hiDRDERFA_all_RR[,c("GHG_int_2020_CFE", "GHG_int_2025_CFE","GHG_int_2030_CFE","GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")])

GHGelec_hiDRDERFA_RR_LRE<-data.frame(Year=seq(2020,2060,5),ElGHG=1e-9*colSums(rs_hiDRDERFA_all_RR[,212:220])) # emissions in Mt 
GHGelec_hiDRDERFA_RR_LRE<-data.frame(data.frame(ElGHG=with(select(GHGelec_hiDRDERFA_RR_LRE,Year,ElGHG),spline(Year,ElGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="A",RenScen="RR",ElecScen="LRE")
names(GHGelec_hiDRDERFA_RR_LRE)[1:2]<-c("Year","ElGHG")

GHGelec_hiDRDERFA_RR_CFE<-data.frame(Year=seq(2020,2060,5),ElGHG=1e-9*colSums(rs_hiDRDERFA_all_RR[,221:229])) # emissions in Mt 
GHGelec_hiDRDERFA_RR_CFE<-data.frame(data.frame(ElGHG=with(select(GHGelec_hiDRDERFA_RR_CFE,Year,ElGHG),spline(Year,ElGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="A",RenScen="RR",ElecScen="CFE")
names(GHGelec_hiDRDERFA_RR_CFE)[1:2]<-c("Year","ElGHG")

GHGelec_hiDRDERFA_RR_CFE$ElGHG[1:6]<-GHGelec_hiDRDERFA_RR_LRE$ElGHG[1:6] # 2020:2025 is same in CFE as in LRE
GHGelec_hiDRDERFA_RR_CFE$ElGHG[16:41]<-0 # 2035:2060 is 0 in CFE

GHG_hiDRDERFA_RR_CFE<-GHG_hiDRDERFA_RR_LREC
GHG_hiDRDERFA_RR_CFE$ElecScen<-"CFE"
GHG_hiDRDERFA_RR_CFE$EnGHG<-GHG_hiDRDERFA_RR_LREC$EnGHG-GHGelec_hiDRDERFA_RR_LRE$ElGHG+GHGelec_hiDRDERFA_RR_CFE$ElGHG # energy emissions equal total LRE enGHG - LRE elGHG + CFE elGHG
GHG_hiDRDERFA_RR_CFE$EmGHG<-us_hiDR_RFA_FA$GHG_NC*1e-9 # make sure this refers to the correct us_* file
GHG_hiDRDERFA_RR_CFE$EmGHG[41]<-GHG_hiDRDERFA_RR_CFE$EmGHG[40]
GHG_hiDRDERFA_RR_CFE$RenGHG<-renGHGall[renGHGall$Scen=="hiTO_Reg",]$MtCO2e
GHG_hiDRDERFA_RR_CFE$TotGHG<-GHG_hiDRDERFA_RR_CFE$EmGHG+GHG_hiDRDERFA_RR_CFE$RenGHG+GHG_hiDRDERFA_RR_CFE$EnGHG

# hiDR DERFA AR
GHG_hiDRDERFA_AR<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_hiDRDERFA_all_AR[,176:184])) # emissions in Mt 
GHG_hiDRDERFA_AR<-data.frame(data.frame(EnGHG=with(select(GHG_hiDRDERFA_AR,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=2,CharScen="D",RenScen="AR",ElecScen="MC")
names(GHG_hiDRDERFA_AR)[1:2]<-c("Year","EnGHG")
GHG_hiDRDERFA_AR$EmGHG<-us_hiDR_RFA_FA$GHG_NC*1e-9
GHG_hiDRDERFA_AR$EmGHG[41]<-GHG_hiDRDERFA_AR$EmGHG[40]
GHG_hiDRDERFA_AR$RenGHG<-renGHGall[renGHGall$Scen=="hiTO_Adv",]$MtCO2e
GHG_hiDRDERFA_AR$TotGHG<-GHG_hiDRDERFA_AR$EmGHG+GHG_hiDRDERFA_AR$RenGHG+GHG_hiDRDERFA_AR$EnGHG

GHG_hiDRDERFA_AR_LREC<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_hiDRDERFA_all_AR[,185:193])) # emissions in Mt 
GHG_hiDRDERFA_AR_LREC<-data.frame(data.frame(EnGHG=with(select(GHG_hiDRDERFA_AR_LREC,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=2,CharScen="D",RenScen="AR",ElecScen="LREC")
names(GHG_hiDRDERFA_AR_LREC)[1:2]<-c("Year","EnGHG")
GHG_hiDRDERFA_AR_LREC$EmGHG<-us_hiDR_RFA_FA$GHG_NC*1e-9
GHG_hiDRDERFA_AR_LREC$EmGHG[41]<-GHG_hiDRDERFA_AR_LREC$EmGHG[40]
GHG_hiDRDERFA_AR_LREC$RenGHG<-renGHGall[renGHGall$Scen=="hiTO_Adv",]$MtCO2e
GHG_hiDRDERFA_AR_LREC$TotGHG<-GHG_hiDRDERFA_AR_LREC$EmGHG+GHG_hiDRDERFA_AR_LREC$RenGHG+GHG_hiDRDERFA_AR_LREC$EnGHG

# for CFE, EnGHG needs to be done first by electricity, and then recombined with fuel EnGHG
rs_hiDRDERFA_all_AR[,c("ElecGHGkg_2020_LRE","ElecGHGkg_2025_LRE","ElecGHGkg_2030_LRE","ElecGHGkg_2035_LRE","ElecGHGkg_2040_LRE","ElecGHGkg_2045_LRE","ElecGHGkg_2050_LRE","ElecGHGkg_2055_LRE","ElecGHGkg_2060_LRE")]<-1000* 
  (rs_hiDRDERFA_all_AR$base_weight*rs_hiDRDERFA_all_AR[,c("whiDR_2020",  "whiDR_2025", "whiDR_2030", "whiDR_2035", "whiDR_2040", "whiDR_2045", "whiDR_2050", "whiDR_2055", "whiDR_2060")])*
  (rs_hiDRDERFA_all_AR$Elec_GJ*rs_hiDRDERFA_all_AR[,c("GHG_int_2020_LRE", "GHG_int_2025_LRE","GHG_int_2030_LRE","GHG_int_2035_LRE","GHG_int_2040_LRE","GHG_int_2045_LRE","GHG_int_2050_LRE","GHG_int_2055_LRE","GHG_int_2060_LRE")])

rs_hiDRDERFA_all_AR[,c("ElecGHGkg_2020_CFE","ElecGHGkg_2025_CFE","ElecGHGkg_2030_CFE","ElecGHGkg_2035_CFE","ElecGHGkg_2040_CFE","ElecGHGkg_2045_CFE","ElecGHGkg_2050_CFE","ElecGHGkg_2055_CFE","ElecGHGkg_2060_CFE")]<-1000* 
  (rs_hiDRDERFA_all_AR$base_weight*rs_hiDRDERFA_all_AR[,c("whiDR_2020",  "whiDR_2025", "whiDR_2030", "whiDR_2035", "whiDR_2040", "whiDR_2045", "whiDR_2050", "whiDR_2055", "whiDR_2060")])*
  (rs_hiDRDERFA_all_AR$Elec_GJ*rs_hiDRDERFA_all_AR[,c("GHG_int_2020_CFE", "GHG_int_2025_CFE","GHG_int_2030_CFE","GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")])

GHGelec_hiDRDERFA_AR_LRE<-data.frame(Year=seq(2020,2060,5),ElGHG=1e-9*colSums(rs_hiDRDERFA_all_AR[,212:220])) # emissions in Mt 
GHGelec_hiDRDERFA_AR_LRE<-data.frame(data.frame(ElGHG=with(select(GHGelec_hiDRDERFA_AR_LRE,Year,ElGHG),spline(Year,ElGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="A",RenScen="AR",ElecScen="LRE")
names(GHGelec_hiDRDERFA_AR_LRE)[1:2]<-c("Year","ElGHG")

GHGelec_hiDRDERFA_AR_CFE<-data.frame(Year=seq(2020,2060,5),ElGHG=1e-9*colSums(rs_hiDRDERFA_all_AR[,221:229])) # emissions in Mt 
GHGelec_hiDRDERFA_AR_CFE<-data.frame(data.frame(ElGHG=with(select(GHGelec_hiDRDERFA_AR_CFE,Year,ElGHG),spline(Year,ElGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="A",RenScen="AR",ElecScen="CFE")
names(GHGelec_hiDRDERFA_AR_CFE)[1:2]<-c("Year","ElGHG")

GHGelec_hiDRDERFA_AR_CFE$ElGHG[1:6]<-GHGelec_hiDRDERFA_AR_LRE$ElGHG[1:6] # 2020:2025 is same in CFE as in LRE
GHGelec_hiDRDERFA_AR_CFE$ElGHG[16:41]<-0 # 2035:2060 is 0 in CFE

GHG_hiDRDERFA_AR_CFE<-GHG_hiDRDERFA_AR_LREC
GHG_hiDRDERFA_AR_CFE$ElecScen<-"CFE"
GHG_hiDRDERFA_AR_CFE$EnGHG<-GHG_hiDRDERFA_AR_LREC$EnGHG-GHGelec_hiDRDERFA_AR_LRE$ElGHG+GHGelec_hiDRDERFA_AR_CFE$ElGHG # energy emissions equal total LRE enGHG - LRE elGHG + CFE elGHG
GHG_hiDRDERFA_AR_CFE$EmGHG<-us_hiDR_RFA_FA$GHG_NC*1e-9 # make sure this refers to the correct us_* file
GHG_hiDRDERFA_AR_CFE$EmGHG[41]<-GHG_hiDRDERFA_AR_CFE$EmGHG[40]
GHG_hiDRDERFA_AR_CFE$RenGHG<-renGHGall[renGHGall$Scen=="hiTO_Adv",]$MtCO2e
GHG_hiDRDERFA_AR_CFE$TotGHG<-GHG_hiDRDERFA_AR_CFE$EmGHG+GHG_hiDRDERFA_AR_CFE$RenGHG+GHG_hiDRDERFA_AR_CFE$EnGHG

# hiDR DERFA ER
GHG_hiDRDERFA_ER<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_hiDRDERFA_all_ER[,176:184])) # emissions in Mt 
GHG_hiDRDERFA_ER<-data.frame(data.frame(EnGHG=with(select(GHG_hiDRDERFA_ER,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=2,CharScen="D",RenScen="ER",ElecScen="MC")
names(GHG_hiDRDERFA_ER)[1:2]<-c("Year","EnGHG")
GHG_hiDRDERFA_ER$EmGHG<-us_hiDR_RFA_FA$GHG_NC*1e-9
GHG_hiDRDERFA_ER$EmGHG[41]<-GHG_hiDRDERFA_ER$EmGHG[40]
GHG_hiDRDERFA_ER$RenGHG<-renGHGall[renGHGall$Scen=="hiTO_Ext",]$MtCO2e
GHG_hiDRDERFA_ER$TotGHG<-GHG_hiDRDERFA_ER$EmGHG+GHG_hiDRDERFA_ER$RenGHG+GHG_hiDRDERFA_ER$EnGHG

GHG_hiDRDERFA_ER_LREC<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_hiDRDERFA_all_ER[,185:193])) # emissions in Mt 
GHG_hiDRDERFA_ER_LREC<-data.frame(data.frame(EnGHG=with(select(GHG_hiDRDERFA_ER_LREC,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=2,CharScen="D",RenScen="ER",ElecScen="LREC")
names(GHG_hiDRDERFA_ER_LREC)[1:2]<-c("Year","EnGHG")
GHG_hiDRDERFA_ER_LREC$EmGHG<-us_hiDR_RFA_FA$GHG_NC*1e-9
GHG_hiDRDERFA_ER_LREC$EmGHG[41]<-GHG_hiDRDERFA_ER_LREC$EmGHG[40]
GHG_hiDRDERFA_ER_LREC$RenGHG<-renGHGall[renGHGall$Scen=="hiTO_Ext",]$MtCO2e
GHG_hiDRDERFA_ER_LREC$TotGHG<-GHG_hiDRDERFA_ER_LREC$EmGHG+GHG_hiDRDERFA_ER_LREC$RenGHG+GHG_hiDRDERFA_ER_LREC$EnGHG

# for CFE, EnGHG needs to be done first by electricity, and then recombined with fuel EnGHG
rs_hiDRDERFA_all_ER[,c("ElecGHGkg_2020_LRE","ElecGHGkg_2025_LRE","ElecGHGkg_2030_LRE","ElecGHGkg_2035_LRE","ElecGHGkg_2040_LRE","ElecGHGkg_2045_LRE","ElecGHGkg_2050_LRE","ElecGHGkg_2055_LRE","ElecGHGkg_2060_LRE")]<-1000* 
  (rs_hiDRDERFA_all_ER$base_weight*rs_hiDRDERFA_all_ER[,c("whiDR_2020",  "whiDR_2025", "whiDR_2030", "whiDR_2035", "whiDR_2040", "whiDR_2045", "whiDR_2050", "whiDR_2055", "whiDR_2060")])*
  (rs_hiDRDERFA_all_ER$Elec_GJ*rs_hiDRDERFA_all_ER[,c("GHG_int_2020_LRE", "GHG_int_2025_LRE","GHG_int_2030_LRE","GHG_int_2035_LRE","GHG_int_2040_LRE","GHG_int_2045_LRE","GHG_int_2050_LRE","GHG_int_2055_LRE","GHG_int_2060_LRE")])

rs_hiDRDERFA_all_ER[,c("ElecGHGkg_2020_CFE","ElecGHGkg_2025_CFE","ElecGHGkg_2030_CFE","ElecGHGkg_2035_CFE","ElecGHGkg_2040_CFE","ElecGHGkg_2045_CFE","ElecGHGkg_2050_CFE","ElecGHGkg_2055_CFE","ElecGHGkg_2060_CFE")]<-1000* 
  (rs_hiDRDERFA_all_ER$base_weight*rs_hiDRDERFA_all_ER[,c("whiDR_2020",  "whiDR_2025", "whiDR_2030", "whiDR_2035", "whiDR_2040", "whiDR_2045", "whiDR_2050", "whiDR_2055", "whiDR_2060")])*
  (rs_hiDRDERFA_all_ER$Elec_GJ*rs_hiDRDERFA_all_ER[,c("GHG_int_2020_CFE", "GHG_int_2025_CFE","GHG_int_2030_CFE","GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")])

GHGelec_hiDRDERFA_ER_LRE<-data.frame(Year=seq(2020,2060,5),ElGHG=1e-9*colSums(rs_hiDRDERFA_all_ER[,212:220])) # emissions in Mt 
GHGelec_hiDRDERFA_ER_LRE<-data.frame(data.frame(ElGHG=with(select(GHGelec_hiDRDERFA_ER_LRE,Year,ElGHG),spline(Year,ElGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="A",RenScen="ER",ElecScen="LRE")
names(GHGelec_hiDRDERFA_ER_LRE)[1:2]<-c("Year","ElGHG")

GHGelec_hiDRDERFA_ER_CFE<-data.frame(Year=seq(2020,2060,5),ElGHG=1e-9*colSums(rs_hiDRDERFA_all_ER[,221:229])) # emissions in Mt 
GHGelec_hiDRDERFA_ER_CFE<-data.frame(data.frame(ElGHG=with(select(GHGelec_hiDRDERFA_ER_CFE,Year,ElGHG),spline(Year,ElGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="A",RenScen="ER",ElecScen="CFE")
names(GHGelec_hiDRDERFA_ER_CFE)[1:2]<-c("Year","ElGHG")

GHGelec_hiDRDERFA_ER_CFE$ElGHG[1:6]<-GHGelec_hiDRDERFA_ER_LRE$ElGHG[1:6] # 2020:2025 is same in CFE as in LRE
GHGelec_hiDRDERFA_ER_CFE$ElGHG[16:41]<-0 # 2035:2060 is 0 in CFE

GHG_hiDRDERFA_ER_CFE<-GHG_hiDRDERFA_ER_LREC
GHG_hiDRDERFA_ER_CFE$ElecScen<-"CFE"
GHG_hiDRDERFA_ER_CFE$EnGHG<-GHG_hiDRDERFA_ER_LREC$EnGHG-GHGelec_hiDRDERFA_ER_LRE$ElGHG+GHGelec_hiDRDERFA_ER_CFE$ElGHG # energy emissions equal total LRE enGHG - LRE elGHG + CFE elGHG
GHG_hiDRDERFA_ER_CFE$EmGHG<-us_hiDR_RFA_FA$GHG_NC*1e-9 # make sure this refers to the correct us_* file
GHG_hiDRDERFA_ER_CFE$EmGHG[41]<-GHG_hiDRDERFA_ER_CFE$EmGHG[40]
GHG_hiDRDERFA_ER_CFE$RenGHG<-renGHGall[renGHGall$Scen=="hiTO_Ext",]$MtCO2e
GHG_hiDRDERFA_ER_CFE$TotGHG<-GHG_hiDRDERFA_ER_CFE$EmGHG+GHG_hiDRDERFA_ER_CFE$RenGHG+GHG_hiDRDERFA_ER_CFE$EnGHG

# add source emissions from fuel for hiDR RR ###########
rs_hiDRDERFA_all_ER$NewCon<-0
rs_hiDRDERFA_all_ER[rs_hiDRDERFA_all_ER$Vintage.ACS %in% c("2020s","2030s","2040s","2050s"),]$NewCon<-1
rs_hiDRDERFA_all_ER$OldCon<-0
rs_hiDRDERFA_all_ER[rs_hiDRDERFA_all_ER$NewCon==0,]$OldCon<-1

rs_hiDRDERFA_all_ER[,c("Old_OilGHGkg_2020","Old_OilGHGkg_2025","Old_OilGHGkg_2030","Old_OilGHGkg_2035","Old_OilGHGkg_2040","Old_OilGHGkg_2045","Old_OilGHGkg_2050","Old_OilGHGkg_2055","Old_OilGHGkg_2060")]<-1000* 
  rs_hiDRDERFA_all_ER$OldCon*(rs_hiDRDERFA_all_ER$base_weight*rs_hiDRDERFA_all_ER[,c("whiDR_2020",  "whiDR_2025", "whiDR_2030", "whiDR_2035", "whiDR_2040", "whiDR_2045", "whiDR_2050", "whiDR_2055", "whiDR_2060")])*
  (matrix(rep(rs_hiDRDERFA_all_ER$Oil_GJ*GHGI_FO,9),nrow(rs_hiDRDERFA_all_ER),9)+ matrix(rep(rs_hiDRDERFA_all_ER$Prop_GJ*GHGI_LP,9),nrow(rs_hiDRDERFA_all_ER),9))

rs_hiDRDERFA_all_ER[,c("New_OilGHGkg_2020","New_OilGHGkg_2025","New_OilGHGkg_2030","New_OilGHGkg_2035","New_OilGHGkg_2040","New_OilGHGkg_2045","New_OilGHGkg_2050","New_OilGHGkg_2055","New_OilGHGkg_2060")]<-1000* 
  rs_hiDRDERFA_all_ER$NewCon*(rs_hiDRDERFA_all_ER$base_weight*rs_hiDRDERFA_all_ER[,c("whiDR_2020",  "whiDR_2025", "whiDR_2030", "whiDR_2035", "whiDR_2040", "whiDR_2045", "whiDR_2050", "whiDR_2055", "whiDR_2060")])*
  (matrix(rep(rs_hiDRDERFA_all_ER$Oil_GJ*GHGI_FO,9),nrow(rs_hiDRDERFA_all_ER),9)+ matrix(rep(rs_hiDRDERFA_all_ER$Prop_GJ*GHGI_LP,9),nrow(rs_hiDRDERFA_all_ER),9))

rs_hiDRDERFA_all_ER[,c("Old_GasGHGkg_2020","Old_GasGHGkg_2025","Old_GasGHGkg_2030","Old_GasGHGkg_2035","Old_GasGHGkg_2040","Old_GasGHGkg_2045","Old_GasGHGkg_2050","Old_GasGHGkg_2055","Old_GasGHGkg_2060")]<-1000* 
  rs_hiDRDERFA_all_ER$OldCon*(rs_hiDRDERFA_all_ER$base_weight*rs_hiDRDERFA_all_ER[,c("whiDR_2020",  "whiDR_2025", "whiDR_2030", "whiDR_2035", "whiDR_2040", "whiDR_2045", "whiDR_2050", "whiDR_2055", "whiDR_2060")])*
  (matrix(rep(rs_hiDRDERFA_all_ER$Gas_GJ*GHGI_NG,9),nrow(rs_hiDRDERFA_all_ER),9))

rs_hiDRDERFA_all_ER[,c("New_GasGHGkg_2020","New_GasGHGkg_2025","New_GasGHGkg_2030","New_GasGHGkg_2035","New_GasGHGkg_2040","New_GasGHGkg_2045","New_GasGHGkg_2050","New_GasGHGkg_2055","New_GasGHGkg_2060")]<-1000* 
  rs_hiDRDERFA_all_ER$NewCon*(rs_hiDRDERFA_all_ER$base_weight*rs_hiDRDERFA_all_ER[,c("whiDR_2020",  "whiDR_2025", "whiDR_2030", "whiDR_2035", "whiDR_2040", "whiDR_2045", "whiDR_2050", "whiDR_2055", "whiDR_2060")])*
  (matrix(rep(rs_hiDRDERFA_all_ER$Gas_GJ*GHGI_NG,9),nrow(rs_hiDRDERFA_all_ER),9))

rs_hiDRDERFA_all_ER[,c("Old_ElecGHGkg_2020","Old_ElecGHGkg_2025","Old_ElecGHGkg_2030","Old_ElecGHGkg_2035","Old_ElecGHGkg_2040","Old_ElecGHGkg_2045","Old_ElecGHGkg_2050","Old_ElecGHGkg_2055","Old_ElecGHGkg_2060")]<-1000* 
  rs_hiDRDERFA_all_ER$OldCon*(rs_hiDRDERFA_all_ER$base_weight*rs_hiDRDERFA_all_ER[,c("whiDR_2020",  "whiDR_2025", "whiDR_2030", "whiDR_2035", "whiDR_2040", "whiDR_2045", "whiDR_2050", "whiDR_2055", "whiDR_2060")])*
  (rs_hiDRDERFA_all_ER$Elec_GJ*rs_hiDRDERFA_all_ER[,c("GHG_int_2020", "GHG_int_2025","GHG_int_2030","GHG_int_2035","GHG_int_2040","GHG_int_2045","GHG_int_2050","GHG_int_2055","GHG_int_2060")])

rs_hiDRDERFA_all_ER[,c("New_ElecGHGkg_2020","New_ElecGHGkg_2025","New_ElecGHGkg_2030","New_ElecGHGkg_2035","New_ElecGHGkg_2040","New_ElecGHGkg_2045","New_ElecGHGkg_2050","New_ElecGHGkg_2055","New_ElecGHGkg_2060")]<-1000* 
  rs_hiDRDERFA_all_ER$NewCon*(rs_hiDRDERFA_all_ER$base_weight*rs_hiDRDERFA_all_ER[,c("whiDR_2020",  "whiDR_2025", "whiDR_2030", "whiDR_2035", "whiDR_2040", "whiDR_2045", "whiDR_2050", "whiDR_2055", "whiDR_2060")])*
  (rs_hiDRDERFA_all_ER$Elec_GJ*rs_hiDRDERFA_all_ER[,c("GHG_int_2020", "GHG_int_2025","GHG_int_2030","GHG_int_2035","GHG_int_2040","GHG_int_2045","GHG_int_2050","GHG_int_2055","GHG_int_2060")])

OldOilGHG_hiDRDERFA_ER<-data.frame(Year=seq(2020,2060,5),OilGHG=colSums(rs_hiDRDERFA_all_ER[,232:240])*1e-9)
NewOilGHG_hiDRDERFA_ER<-data.frame(Year=seq(2020,2060,5),OilGHG=colSums(rs_hiDRDERFA_all_ER[,241:249])*1e-9)
OldGasGHG_hiDRDERFA_ER<-data.frame(Year=seq(2020,2060,5),GasGHG=colSums(rs_hiDRDERFA_all_ER[,250:258])*1e-9)
NewGasGHG_hiDRDERFA_ER<-data.frame(Year=seq(2020,2060,5),GasGHG=colSums(rs_hiDRDERFA_all_ER[,259:267])*1e-9)
OldElecGHG_hiDRDERFA_ER<-data.frame(Year=seq(2020,2060,5),ElecGHG=colSums(rs_hiDRDERFA_all_ER[,268:276])*1e-9)
NewElecGHG_hiDRDERFA_ER<-data.frame(Year=seq(2020,2060,5),ElecGHG=colSums(rs_hiDRDERFA_all_ER[,277:285])*1e-9)

GHG_hiDRDERFA_ER$OldOilGHG<-data.frame(OilGHG=with(select(OldOilGHG_hiDRDERFA_ER,Year,OilGHG),spline(Year,OilGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_hiDRDERFA_ER$NewOilGHG<-data.frame(OilGHG=with(select(NewOilGHG_hiDRDERFA_ER,Year,OilGHG),spline(Year,OilGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_hiDRDERFA_ER$OldGasGHG<-data.frame(GasGHG=with(select(OldGasGHG_hiDRDERFA_ER,Year,GasGHG),spline(Year,GasGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_hiDRDERFA_ER$NewGasGHG<-data.frame(GasGHG=with(select(NewGasGHG_hiDRDERFA_ER,Year,GasGHG),spline(Year,GasGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_hiDRDERFA_ER$OldElecGHG<-data.frame(ElecGHG=with(select(OldElecGHG_hiDRDERFA_ER,Year,ElecGHG),spline(Year,ElecGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_hiDRDERFA_ER$NewElecGHG<-data.frame(ElecGHG=with(select(NewElecGHG_hiDRDERFA_ER,Year,ElecGHG),spline(Year,ElecGHG,xout = 2020:2060)),method="spline()")[,2]

# repeat for LREC electricity
rs_hiDRDERFA_all_ER[,c("Old_ElecGHGkg_2020_LRE","Old_ElecGHGkg_2025_LRE","Old_ElecGHGkg_2030_LRE","Old_ElecGHGkg_2035_LRE","Old_ElecGHGkg_2040_LRE","Old_ElecGHGkg_2045_LRE","Old_ElecGHGkg_2050_LRE","Old_ElecGHGkg_2055_LRE","Old_ElecGHGkg_2060_LRE")]<-1000* 
  rs_hiDRDERFA_all_ER$OldCon*(rs_hiDRDERFA_all_ER$base_weight*rs_hiDRDERFA_all_ER[,c("whiDR_2020",  "whiDR_2025", "whiDR_2030", "whiDR_2035", "whiDR_2040", "whiDR_2045", "whiDR_2050", "whiDR_2055", "whiDR_2060")])*
  (rs_hiDRDERFA_all_ER$Elec_GJ*rs_hiDRDERFA_all_ER[,c("GHG_int_2020_LRE", "GHG_int_2025_LRE","GHG_int_2030_LRE","GHG_int_2035_LRE","GHG_int_2040_LRE","GHG_int_2045_LRE","GHG_int_2050_LRE","GHG_int_2055_LRE","GHG_int_2060_LRE")])

rs_hiDRDERFA_all_ER[,c("New_ElecGHGkg_2020_LRE","New_ElecGHGkg_2025_LRE","New_ElecGHGkg_2030_LRE","New_ElecGHGkg_2035_LRE","New_ElecGHGkg_2040_LRE","New_ElecGHGkg_2045_LRE","New_ElecGHGkg_2050_LRE","New_ElecGHGkg_2055_LRE","New_ElecGHGkg_2060_LRE")]<-1000* 
  rs_hiDRDERFA_all_ER$NewCon*(rs_hiDRDERFA_all_ER$base_weight*rs_hiDRDERFA_all_ER[,c("whiDR_2020",  "whiDR_2025", "whiDR_2030", "whiDR_2035", "whiDR_2040", "whiDR_2045", "whiDR_2050", "whiDR_2055", "whiDR_2060")])*
  (rs_hiDRDERFA_all_ER$Elec_GJ*rs_hiDRDERFA_all_ER[,c("GHG_int_2020_LRE", "GHG_int_2025_LRE","GHG_int_2030_LRE","GHG_int_2035_LRE","GHG_int_2040_LRE","GHG_int_2045_LRE","GHG_int_2050_LRE","GHG_int_2055_LRE","GHG_int_2060_LRE")])

OldElecGHG_hiDRDERFA_ER_LREC<-data.frame(Year=seq(2020,2060,5),ElecGHG=colSums(rs_hiDRDERFA_all_ER[,286:294])*1e-9)
NewElecGHG_hiDRDERFA_ER_LREC<-data.frame(Year=seq(2020,2060,5),ElecGHG=colSums(rs_hiDRDERFA_all_ER[,295:303])*1e-9)

GHG_hiDRDERFA_ER_LREC$OldOilGHG<-data.frame(OilGHG=with(select(OldOilGHG_hiDRDERFA_ER,Year,OilGHG),spline(Year,OilGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_hiDRDERFA_ER_LREC$NewOilGHG<-data.frame(OilGHG=with(select(NewOilGHG_hiDRDERFA_ER,Year,OilGHG),spline(Year,OilGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_hiDRDERFA_ER_LREC$OldGasGHG<-data.frame(GasGHG=with(select(OldGasGHG_hiDRDERFA_ER,Year,GasGHG),spline(Year,GasGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_hiDRDERFA_ER_LREC$NewGasGHG<-data.frame(GasGHG=with(select(NewGasGHG_hiDRDERFA_ER,Year,GasGHG),spline(Year,GasGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_hiDRDERFA_ER_LREC$OldElecGHG<-data.frame(ElecGHG=with(select(OldElecGHG_hiDRDERFA_ER_LREC,Year,ElecGHG),spline(Year,ElecGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_hiDRDERFA_ER_LREC$NewElecGHG<-data.frame(ElecGHG=with(select(NewElecGHG_hiDRDERFA_ER_LREC,Year,ElecGHG),spline(Year,ElecGHG,xout = 2020:2060)),method="spline()")[,2]

# repeat for CFE electricity
rs_hiDRDERFA_all_ER[,c("Old_ElecGHGkg_2020_CFE","Old_ElecGHGkg_2025_CFE","Old_ElecGHGkg_2030_CFE","Old_ElecGHGkg_2035_CFE","Old_ElecGHGkg_2040_CFE","Old_ElecGHGkg_2045_CFE","Old_ElecGHGkg_2050_CFE","Old_ElecGHGkg_2055_CFE","Old_ElecGHGkg_2060_CFE")]<-1000* 
  rs_hiDRDERFA_all_ER$OldCon*(rs_hiDRDERFA_all_ER$base_weight*rs_hiDRDERFA_all_ER[,c("whiDR_2020",  "whiDR_2025", "whiDR_2030", "whiDR_2035", "whiDR_2040", "whiDR_2045", "whiDR_2050", "whiDR_2055", "whiDR_2060")])*
  (rs_hiDRDERFA_all_ER$Elec_GJ*rs_hiDRDERFA_all_ER[,c("GHG_int_2020_CFE", "GHG_int_2025_CFE","GHG_int_2030_CFE","GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")])

rs_hiDRDERFA_all_ER[,c("New_ElecGHGkg_2020_CFE","New_ElecGHGkg_2025_CFE","New_ElecGHGkg_2030_CFE","New_ElecGHGkg_2035_CFE","New_ElecGHGkg_2040_CFE","New_ElecGHGkg_2045_CFE","New_ElecGHGkg_2050_CFE","New_ElecGHGkg_2055_CFE","New_ElecGHGkg_2060_CFE")]<-1000* 
  rs_hiDRDERFA_all_ER$NewCon*(rs_hiDRDERFA_all_ER$base_weight*rs_hiDRDERFA_all_ER[,c("whiDR_2020",  "whiDR_2025", "whiDR_2030", "whiDR_2035", "whiDR_2040", "whiDR_2045", "whiDR_2050", "whiDR_2055", "whiDR_2060")])*
  (rs_hiDRDERFA_all_ER$Elec_GJ*rs_hiDRDERFA_all_ER[,c("GHG_int_2020_CFE", "GHG_int_2025_CFE","GHG_int_2030_CFE","GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")])

OldElecGHG_hiDRDERFA_ER_CFE<-data.frame(Year=seq(2020,2060,5),ElecGHG=colSums(rs_hiDRDERFA_all_ER[,304:312])*1e-9)
NewElecGHG_hiDRDERFA_ER_CFE<-data.frame(Year=seq(2020,2060,5),ElecGHG=colSums(rs_hiDRDERFA_all_ER[,313:321])*1e-9)

GHG_hiDRDERFA_ER_CFE$OldOilGHG<-data.frame(OilGHG=with(select(OldOilGHG_hiDRDERFA_ER,Year,OilGHG),spline(Year,OilGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_hiDRDERFA_ER_CFE$NewOilGHG<-data.frame(OilGHG=with(select(NewOilGHG_hiDRDERFA_ER,Year,OilGHG),spline(Year,OilGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_hiDRDERFA_ER_CFE$OldGasGHG<-data.frame(GasGHG=with(select(OldGasGHG_hiDRDERFA_ER,Year,GasGHG),spline(Year,GasGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_hiDRDERFA_ER_CFE$NewGasGHG<-data.frame(GasGHG=with(select(NewGasGHG_hiDRDERFA_ER,Year,GasGHG),spline(Year,GasGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_hiDRDERFA_ER_CFE$OldElecGHG<-data.frame(ElecGHG=with(select(OldElecGHG_hiDRDERFA_ER_CFE,Year,ElecGHG),spline(Year,ElecGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_hiDRDERFA_ER_CFE$NewElecGHG<-data.frame(ElecGHG=with(select(NewElecGHG_hiDRDERFA_ER_CFE,Year,ElecGHG),spline(Year,ElecGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_hiDRDERFA_ER_CFE$OldElecGHG[1:6]<-GHG_hiDRDERFA_ER_LREC$OldElecGHG[1:6] # 2020:2025 same as LRE
GHG_hiDRDERFA_ER_CFE$NewElecGHG[1:6]<-GHG_hiDRDERFA_ER_LREC$NewElecGHG[1:6] # 2020:2025 same as LRE
GHG_hiDRDERFA_ER_CFE$OldElecGHG[16:41]<-GHG_hiDRDERFA_ER_CFE$NewElecGHG[16:41]<-0

# hi MF
# add in GHG intensities for 2035 CFE
rs_hiMFDERFA_all_RR[,c("GHG_int_2020_CFE","GHG_int_2025_CFE")]<-rs_hiMFDERFA_all_RR[,c("GHG_int_2020_LRE","GHG_int_2025_LRE")]
rs_hiMFDERFA_all_RR[,c("GHG_int_2030_CFE")]<-0.5*rs_hiMFDERFA_all_RR[,c("GHG_int_2025_LRE")]
rs_hiMFDERFA_all_RR[,c("GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")]<-0

rs_hiMFDERFA_all_AR[,c("GHG_int_2020_CFE","GHG_int_2025_CFE")]<-rs_hiMFDERFA_all_AR[,c("GHG_int_2020_LRE","GHG_int_2025_LRE")]
rs_hiMFDERFA_all_AR[,c("GHG_int_2030_CFE")]<-0.5*rs_hiMFDERFA_all_AR[,c("GHG_int_2025_LRE")]
rs_hiMFDERFA_all_AR[,c("GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")]<-0

rs_hiMFDERFA_all_ER[,c("GHG_int_2020_CFE","GHG_int_2025_CFE")]<-rs_hiMFDERFA_all_ER[,c("GHG_int_2020_LRE","GHG_int_2025_LRE")]
rs_hiMFDERFA_all_ER[,c("GHG_int_2030_CFE")]<-0.5*rs_hiMFDERFA_all_ER[,c("GHG_int_2025_LRE")]
rs_hiMFDERFA_all_ER[,c("GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")]<-0

# add in GHG emissions for CFE
rs_hiMFDERFA_all_RR[,c("EnGHGkg_hiMF_2020_CFE","EnGHGkg_hiMF_2025_CFE","EnGHGkg_hiMF_2030_CFE","EnGHGkg_hiMF_2035_CFE","EnGHGkg_hiMF_2040_CFE","EnGHGkg_hiMF_2045_CFE","EnGHGkg_hiMF_2050_CFE","EnGHGkg_hiMF_2055_CFE","EnGHGkg_hiMF_2060_CFE")]<-1000* 
  (rs_hiMFDERFA_all_RR$base_weight*rs_hiMFDERFA_all_RR[,c("whiMF_2020",  "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")])*
  (rs_hiMFDERFA_all_RR$Elec_GJ*rs_hiMFDERFA_all_RR[,c("GHG_int_2020_CFE", "GHG_int_2025_CFE","GHG_int_2030_CFE","GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")]+
     matrix(rep(rs_hiMFDERFA_all_RR$Gas_GJ*GHGI_NG,9),nrow(rs_hiMFDERFA_all_RR),9)+ matrix(rep(rs_hiMFDERFA_all_RR$Oil_GJ*GHGI_FO,9),nrow(rs_hiMFDERFA_all_RR),9)+ matrix(rep(rs_hiMFDERFA_all_RR$Prop_GJ*GHGI_LP,9),nrow(rs_hiMFDERFA_all_RR),9))

rs_hiMFDERFA_all_AR[,c("EnGHGkg_hiMF_2020_CFE","EnGHGkg_hiMF_2025_CFE","EnGHGkg_hiMF_2030_CFE","EnGHGkg_hiMF_2035_CFE","EnGHGkg_hiMF_2040_CFE","EnGHGkg_hiMF_2045_CFE","EnGHGkg_hiMF_2050_CFE","EnGHGkg_hiMF_2055_CFE","EnGHGkg_hiMF_2060_CFE")]<-1000* 
  (rs_hiMFDERFA_all_AR$base_weight*rs_hiMFDERFA_all_AR[,c("whiMF_2020",  "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")])*
  (rs_hiMFDERFA_all_AR$Elec_GJ*rs_hiMFDERFA_all_AR[,c("GHG_int_2020_CFE", "GHG_int_2025_CFE","GHG_int_2030_CFE","GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")]+
     matrix(rep(rs_hiMFDERFA_all_AR$Gas_GJ*GHGI_NG,9),nrow(rs_hiMFDERFA_all_AR),9)+ matrix(rep(rs_hiMFDERFA_all_AR$Oil_GJ*GHGI_FO,9),nrow(rs_hiMFDERFA_all_AR),9)+ matrix(rep(rs_hiMFDERFA_all_AR$Prop_GJ*GHGI_LP,9),nrow(rs_hiMFDERFA_all_AR),9))

rs_hiMFDERFA_all_ER[,c("EnGHGkg_hiMF_2020_CFE","EnGHGkg_hiMF_2025_CFE","EnGHGkg_hiMF_2030_CFE","EnGHGkg_hiMF_2035_CFE","EnGHGkg_hiMF_2040_CFE","EnGHGkg_hiMF_2045_CFE","EnGHGkg_hiMF_2050_CFE","EnGHGkg_hiMF_2055_CFE","EnGHGkg_hiMF_2060_CFE")]<-1000* 
  (rs_hiMFDERFA_all_ER$base_weight*rs_hiMFDERFA_all_ER[,c("whiMF_2020",  "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")])*
  (rs_hiMFDERFA_all_ER$Elec_GJ*rs_hiMFDERFA_all_ER[,c("GHG_int_2020_CFE", "GHG_int_2025_CFE","GHG_int_2030_CFE","GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")]+
     matrix(rep(rs_hiMFDERFA_all_ER$Gas_GJ*GHGI_NG,9),nrow(rs_hiMFDERFA_all_ER),9)+ matrix(rep(rs_hiMFDERFA_all_ER$Oil_GJ*GHGI_FO,9),nrow(rs_hiMFDERFA_all_ER),9)+ matrix(rep(rs_hiMFDERFA_all_ER$Prop_GJ*GHGI_LP,9),nrow(rs_hiMFDERFA_all_ER),9))

# start compiling emissions
GHG_hiMFDERFA_RR<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_hiMFDERFA_all_RR[,176:184])) # emissions in Mt 
GHG_hiMFDERFA_RR<-data.frame(data.frame(EnGHG=with(select(GHG_hiMFDERFA_RR,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=3,CharScen="D",RenScen="RR",ElecScen="MC")
names(GHG_hiMFDERFA_RR)[1:2]<-c("Year","EnGHG")
GHG_hiMFDERFA_RR$EmGHG<-us_hiMF_RFA_FA$GHG_NC*1e-9
GHG_hiMFDERFA_RR$EmGHG[41]<-GHG_hiMFDERFA_RR$EmGHG[40]
GHG_hiMFDERFA_RR$RenGHG<-renGHGall[renGHGall$Scen=="hiMF_Reg",]$MtCO2e
GHG_hiMFDERFA_RR$TotGHG<-GHG_hiMFDERFA_RR$EmGHG+GHG_hiMFDERFA_RR$RenGHG+GHG_hiMFDERFA_RR$EnGHG

GHG_hiMFDERFA_RR_LREC<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_hiMFDERFA_all_RR[,185:193])) # emissions in Mt 
GHG_hiMFDERFA_RR_LREC<-data.frame(data.frame(EnGHG=with(select(GHG_hiMFDERFA_RR_LREC,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=3,CharScen="D",RenScen="RR",ElecScen="LREC")
names(GHG_hiMFDERFA_RR_LREC)[1:2]<-c("Year","EnGHG")
GHG_hiMFDERFA_RR_LREC$EmGHG<-us_hiMF_RFA_FA$GHG_NC*1e-9
GHG_hiMFDERFA_RR_LREC$EmGHG[41]<-GHG_hiMFDERFA_RR_LREC$EmGHG[40]
GHG_hiMFDERFA_RR_LREC$RenGHG<-renGHGall[renGHGall$Scen=="hiMF_Reg",]$MtCO2e
GHG_hiMFDERFA_RR_LREC$TotGHG<-GHG_hiMFDERFA_RR_LREC$EmGHG+GHG_hiMFDERFA_RR_LREC$RenGHG+GHG_hiMFDERFA_RR_LREC$EnGHG

# for CFE, EnGHG needs to be done first by electricity, and then recombined with fuel EnGHG
rs_hiMFDERFA_all_RR[,c("ElecGHGkg_2020_LRE","ElecGHGkg_2025_LRE","ElecGHGkg_2030_LRE","ElecGHGkg_2035_LRE","ElecGHGkg_2040_LRE","ElecGHGkg_2045_LRE","ElecGHGkg_2050_LRE","ElecGHGkg_2055_LRE","ElecGHGkg_2060_LRE")]<-1000* 
  (rs_hiMFDERFA_all_RR$base_weight*rs_hiMFDERFA_all_RR[,c("whiMF_2020",  "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")])*
  (rs_hiMFDERFA_all_RR$Elec_GJ*rs_hiMFDERFA_all_RR[,c("GHG_int_2020_LRE", "GHG_int_2025_LRE","GHG_int_2030_LRE","GHG_int_2035_LRE","GHG_int_2040_LRE","GHG_int_2045_LRE","GHG_int_2050_LRE","GHG_int_2055_LRE","GHG_int_2060_LRE")])

rs_hiMFDERFA_all_RR[,c("ElecGHGkg_2020_CFE","ElecGHGkg_2025_CFE","ElecGHGkg_2030_CFE","ElecGHGkg_2035_CFE","ElecGHGkg_2040_CFE","ElecGHGkg_2045_CFE","ElecGHGkg_2050_CFE","ElecGHGkg_2055_CFE","ElecGHGkg_2060_CFE")]<-1000* 
  (rs_hiMFDERFA_all_RR$base_weight*rs_hiMFDERFA_all_RR[,c("whiMF_2020",  "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")])*
  (rs_hiMFDERFA_all_RR$Elec_GJ*rs_hiMFDERFA_all_RR[,c("GHG_int_2020_CFE", "GHG_int_2025_CFE","GHG_int_2030_CFE","GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")])

GHGelec_hiMFDERFA_RR_LRE<-data.frame(Year=seq(2020,2060,5),ElGHG=1e-9*colSums(rs_hiMFDERFA_all_RR[,212:220])) # emissions in Mt 
GHGelec_hiMFDERFA_RR_LRE<-data.frame(data.frame(ElGHG=with(select(GHGelec_hiMFDERFA_RR_LRE,Year,ElGHG),spline(Year,ElGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="A",RenScen="RR",ElecScen="LRE")
names(GHGelec_hiMFDERFA_RR_LRE)[1:2]<-c("Year","ElGHG")

GHGelec_hiMFDERFA_RR_CFE<-data.frame(Year=seq(2020,2060,5),ElGHG=1e-9*colSums(rs_hiMFDERFA_all_RR[,221:229])) # emissions in Mt 
GHGelec_hiMFDERFA_RR_CFE<-data.frame(data.frame(ElGHG=with(select(GHGelec_hiMFDERFA_RR_CFE,Year,ElGHG),spline(Year,ElGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="A",RenScen="RR",ElecScen="CFE")
names(GHGelec_hiMFDERFA_RR_CFE)[1:2]<-c("Year","ElGHG")

GHGelec_hiMFDERFA_RR_CFE$ElGHG[1:6]<-GHGelec_hiMFDERFA_RR_LRE$ElGHG[1:6] # 2020:2025 is same in CFE as in LRE
GHGelec_hiMFDERFA_RR_CFE$ElGHG[16:41]<-0 # 2035:2060 is 0 in CFE

GHG_hiMFDERFA_RR_CFE<-GHG_hiMFDERFA_RR_LREC
GHG_hiMFDERFA_RR_CFE$ElecScen<-"CFE"
GHG_hiMFDERFA_RR_CFE$EnGHG<-GHG_hiMFDERFA_RR_LREC$EnGHG-GHGelec_hiMFDERFA_RR_LRE$ElGHG+GHGelec_hiMFDERFA_RR_CFE$ElGHG # energy emissions equal total LRE enGHG - LRE elGHG + CFE elGHG
GHG_hiMFDERFA_RR_CFE$EmGHG<-us_hiMF_RFA_FA$GHG_NC*1e-9 # make sure this refers to the correct us_* file
GHG_hiMFDERFA_RR_CFE$EmGHG[41]<-GHG_hiMFDERFA_RR_CFE$EmGHG[40]
GHG_hiMFDERFA_RR_CFE$RenGHG<-renGHGall[renGHGall$Scen=="hiMF_Reg",]$MtCO2e
GHG_hiMFDERFA_RR_CFE$TotGHG<-GHG_hiMFDERFA_RR_CFE$EmGHG+GHG_hiMFDERFA_RR_CFE$RenGHG+GHG_hiMFDERFA_RR_CFE$EnGHG

# hiMF DERFA AR
GHG_hiMFDERFA_AR<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_hiMFDERFA_all_AR[,176:184])) # emissions in Mt 
GHG_hiMFDERFA_AR<-data.frame(data.frame(EnGHG=with(select(GHG_hiMFDERFA_AR,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=3,CharScen="D",RenScen="AR",ElecScen="MC")
names(GHG_hiMFDERFA_AR)[1:2]<-c("Year","EnGHG")
GHG_hiMFDERFA_AR$EmGHG<-us_hiMF_RFA_FA$GHG_NC*1e-9
GHG_hiMFDERFA_AR$EmGHG[41]<-GHG_hiMFDERFA_AR$EmGHG[40]
GHG_hiMFDERFA_AR$RenGHG<-renGHGall[renGHGall$Scen=="hiMF_Adv",]$MtCO2e
GHG_hiMFDERFA_AR$TotGHG<-GHG_hiMFDERFA_AR$EmGHG+GHG_hiMFDERFA_AR$RenGHG+GHG_hiMFDERFA_AR$EnGHG

GHG_hiMFDERFA_AR_LREC<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_hiMFDERFA_all_AR[,185:193])) # emissions in Mt 
GHG_hiMFDERFA_AR_LREC<-data.frame(data.frame(EnGHG=with(select(GHG_hiMFDERFA_AR_LREC,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=3,CharScen="D",RenScen="AR",ElecScen="LREC")
names(GHG_hiMFDERFA_AR_LREC)[1:2]<-c("Year","EnGHG")
GHG_hiMFDERFA_AR_LREC$EmGHG<-us_hiMF_RFA_FA$GHG_NC*1e-9
GHG_hiMFDERFA_AR_LREC$EmGHG[41]<-GHG_hiMFDERFA_AR_LREC$EmGHG[40]
GHG_hiMFDERFA_AR_LREC$RenGHG<-renGHGall[renGHGall$Scen=="hiMF_Adv",]$MtCO2e
GHG_hiMFDERFA_AR_LREC$TotGHG<-GHG_hiMFDERFA_AR_LREC$EmGHG+GHG_hiMFDERFA_AR_LREC$RenGHG+GHG_hiMFDERFA_AR_LREC$EnGHG

# for CFE, EnGHG needs to be done first by electricity, and then recombined with fuel EnGHG
rs_hiMFDERFA_all_AR[,c("ElecGHGkg_2020_LRE","ElecGHGkg_2025_LRE","ElecGHGkg_2030_LRE","ElecGHGkg_2035_LRE","ElecGHGkg_2040_LRE","ElecGHGkg_2045_LRE","ElecGHGkg_2050_LRE","ElecGHGkg_2055_LRE","ElecGHGkg_2060_LRE")]<-1000* 
  (rs_hiMFDERFA_all_AR$base_weight*rs_hiMFDERFA_all_AR[,c("whiMF_2020",  "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")])*
  (rs_hiMFDERFA_all_AR$Elec_GJ*rs_hiMFDERFA_all_AR[,c("GHG_int_2020_LRE", "GHG_int_2025_LRE","GHG_int_2030_LRE","GHG_int_2035_LRE","GHG_int_2040_LRE","GHG_int_2045_LRE","GHG_int_2050_LRE","GHG_int_2055_LRE","GHG_int_2060_LRE")])

rs_hiMFDERFA_all_AR[,c("ElecGHGkg_2020_CFE","ElecGHGkg_2025_CFE","ElecGHGkg_2030_CFE","ElecGHGkg_2035_CFE","ElecGHGkg_2040_CFE","ElecGHGkg_2045_CFE","ElecGHGkg_2050_CFE","ElecGHGkg_2055_CFE","ElecGHGkg_2060_CFE")]<-1000* 
  (rs_hiMFDERFA_all_AR$base_weight*rs_hiMFDERFA_all_AR[,c("whiMF_2020",  "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")])*
  (rs_hiMFDERFA_all_AR$Elec_GJ*rs_hiMFDERFA_all_AR[,c("GHG_int_2020_CFE", "GHG_int_2025_CFE","GHG_int_2030_CFE","GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")])

GHGelec_hiMFDERFA_AR_LRE<-data.frame(Year=seq(2020,2060,5),ElGHG=1e-9*colSums(rs_hiMFDERFA_all_AR[,212:220])) # emissions in Mt 
GHGelec_hiMFDERFA_AR_LRE<-data.frame(data.frame(ElGHG=with(select(GHGelec_hiMFDERFA_AR_LRE,Year,ElGHG),spline(Year,ElGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="A",RenScen="AR",ElecScen="LRE")
names(GHGelec_hiMFDERFA_AR_LRE)[1:2]<-c("Year","ElGHG")

GHGelec_hiMFDERFA_AR_CFE<-data.frame(Year=seq(2020,2060,5),ElGHG=1e-9*colSums(rs_hiMFDERFA_all_AR[,221:229])) # emissions in Mt 
GHGelec_hiMFDERFA_AR_CFE<-data.frame(data.frame(ElGHG=with(select(GHGelec_hiMFDERFA_AR_CFE,Year,ElGHG),spline(Year,ElGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="A",RenScen="AR",ElecScen="CFE")
names(GHGelec_hiMFDERFA_AR_CFE)[1:2]<-c("Year","ElGHG")

GHGelec_hiMFDERFA_AR_CFE$ElGHG[1:6]<-GHGelec_hiMFDERFA_AR_LRE$ElGHG[1:6] # 2020:2025 is same in CFE as in LRE
GHGelec_hiMFDERFA_AR_CFE$ElGHG[16:41]<-0 # 2035:2060 is 0 in CFE

GHG_hiMFDERFA_AR_CFE<-GHG_hiMFDERFA_AR_LREC
GHG_hiMFDERFA_AR_CFE$ElecScen<-"CFE"
GHG_hiMFDERFA_AR_CFE$EnGHG<-GHG_hiMFDERFA_AR_LREC$EnGHG-GHGelec_hiMFDERFA_AR_LRE$ElGHG+GHGelec_hiMFDERFA_AR_CFE$ElGHG # energy emissions equal total LRE enGHG - LRE elGHG + CFE elGHG
GHG_hiMFDERFA_AR_CFE$EmGHG<-us_hiMF_RFA_FA$GHG_NC*1e-9 # make sure this refers to the correct us_* file
GHG_hiMFDERFA_AR_CFE$EmGHG[41]<-GHG_hiMFDERFA_AR_CFE$EmGHG[40]
GHG_hiMFDERFA_AR_CFE$RenGHG<-renGHGall[renGHGall$Scen=="hiMF_Adv",]$MtCO2e
GHG_hiMFDERFA_AR_CFE$TotGHG<-GHG_hiMFDERFA_AR_CFE$EmGHG+GHG_hiMFDERFA_AR_CFE$RenGHG+GHG_hiMFDERFA_AR_CFE$EnGHG

# hiMF DERFA ER
GHG_hiMFDERFA_ER<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_hiMFDERFA_all_ER[,176:184])) # emissions in Mt 
GHG_hiMFDERFA_ER<-data.frame(data.frame(EnGHG=with(select(GHG_hiMFDERFA_ER,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=3,CharScen="D",RenScen="ER",ElecScen="MC")
names(GHG_hiMFDERFA_ER)[1:2]<-c("Year","EnGHG")
GHG_hiMFDERFA_ER$EmGHG<-us_hiMF_RFA_FA$GHG_NC*1e-9
GHG_hiMFDERFA_ER$EmGHG[41]<-GHG_hiMFDERFA_ER$EmGHG[40]
GHG_hiMFDERFA_ER$RenGHG<-renGHGall[renGHGall$Scen=="hiMF_Ext",]$MtCO2e
GHG_hiMFDERFA_ER$TotGHG<-GHG_hiMFDERFA_ER$EmGHG+GHG_hiMFDERFA_ER$RenGHG+GHG_hiMFDERFA_ER$EnGHG

GHG_hiMFDERFA_ER_LREC<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_hiMFDERFA_all_ER[,185:193])) # emissions in Mt 
GHG_hiMFDERFA_ER_LREC<-data.frame(data.frame(EnGHG=with(select(GHG_hiMFDERFA_ER_LREC,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=3,CharScen="D",RenScen="ER",ElecScen="LREC")
names(GHG_hiMFDERFA_ER_LREC)[1:2]<-c("Year","EnGHG")
GHG_hiMFDERFA_ER_LREC$EmGHG<-us_hiMF_RFA_FA$GHG_NC*1e-9
GHG_hiMFDERFA_ER_LREC$EmGHG[41]<-GHG_hiMFDERFA_ER_LREC$EmGHG[40]
GHG_hiMFDERFA_ER_LREC$RenGHG<-renGHGall[renGHGall$Scen=="hiMF_Ext",]$MtCO2e
GHG_hiMFDERFA_ER_LREC$TotGHG<-GHG_hiMFDERFA_ER_LREC$EmGHG+GHG_hiMFDERFA_ER_LREC$RenGHG+GHG_hiMFDERFA_ER_LREC$EnGHG

# for CFE, EnGHG needs to be done first by electricity, and then recombined with fuel EnGHG
rs_hiMFDERFA_all_ER[,c("ElecGHGkg_2020_LRE","ElecGHGkg_2025_LRE","ElecGHGkg_2030_LRE","ElecGHGkg_2035_LRE","ElecGHGkg_2040_LRE","ElecGHGkg_2045_LRE","ElecGHGkg_2050_LRE","ElecGHGkg_2055_LRE","ElecGHGkg_2060_LRE")]<-1000* 
  (rs_hiMFDERFA_all_ER$base_weight*rs_hiMFDERFA_all_ER[,c("whiMF_2020",  "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")])*
  (rs_hiMFDERFA_all_ER$Elec_GJ*rs_hiMFDERFA_all_ER[,c("GHG_int_2020_LRE", "GHG_int_2025_LRE","GHG_int_2030_LRE","GHG_int_2035_LRE","GHG_int_2040_LRE","GHG_int_2045_LRE","GHG_int_2050_LRE","GHG_int_2055_LRE","GHG_int_2060_LRE")])

rs_hiMFDERFA_all_ER[,c("ElecGHGkg_2020_CFE","ElecGHGkg_2025_CFE","ElecGHGkg_2030_CFE","ElecGHGkg_2035_CFE","ElecGHGkg_2040_CFE","ElecGHGkg_2045_CFE","ElecGHGkg_2050_CFE","ElecGHGkg_2055_CFE","ElecGHGkg_2060_CFE")]<-1000* 
  (rs_hiMFDERFA_all_ER$base_weight*rs_hiMFDERFA_all_ER[,c("whiMF_2020",  "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")])*
  (rs_hiMFDERFA_all_ER$Elec_GJ*rs_hiMFDERFA_all_ER[,c("GHG_int_2020_CFE", "GHG_int_2025_CFE","GHG_int_2030_CFE","GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")])

GHGelec_hiMFDERFA_ER_LRE<-data.frame(Year=seq(2020,2060,5),ElGHG=1e-9*colSums(rs_hiMFDERFA_all_ER[,212:220])) # emissions in Mt 
GHGelec_hiMFDERFA_ER_LRE<-data.frame(data.frame(ElGHG=with(select(GHGelec_hiMFDERFA_ER_LRE,Year,ElGHG),spline(Year,ElGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="A",RenScen="ER",ElecScen="LRE")
names(GHGelec_hiMFDERFA_ER_LRE)[1:2]<-c("Year","ElGHG")

GHGelec_hiMFDERFA_ER_CFE<-data.frame(Year=seq(2020,2060,5),ElGHG=1e-9*colSums(rs_hiMFDERFA_all_ER[,221:229])) # emissions in Mt 
GHGelec_hiMFDERFA_ER_CFE<-data.frame(data.frame(ElGHG=with(select(GHGelec_hiMFDERFA_ER_CFE,Year,ElGHG),spline(Year,ElGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="A",RenScen="ER",ElecScen="CFE")
names(GHGelec_hiMFDERFA_ER_CFE)[1:2]<-c("Year","ElGHG")

GHGelec_hiMFDERFA_ER_CFE$ElGHG[1:6]<-GHGelec_hiMFDERFA_ER_LRE$ElGHG[1:6] # 2020:2025 is same in CFE as in LRE
GHGelec_hiMFDERFA_ER_CFE$ElGHG[16:41]<-0 # 2035:2060 is 0 in CFE

GHG_hiMFDERFA_ER_CFE<-GHG_hiMFDERFA_ER_LREC
GHG_hiMFDERFA_ER_CFE$ElecScen<-"CFE"
GHG_hiMFDERFA_ER_CFE$EnGHG<-GHG_hiMFDERFA_ER_LREC$EnGHG-GHGelec_hiMFDERFA_ER_LRE$ElGHG+GHGelec_hiMFDERFA_ER_CFE$ElGHG # energy emissions equal total LRE enGHG - LRE elGHG + CFE elGHG
GHG_hiMFDERFA_ER_CFE$EmGHG<-us_hiMF_RFA_FA$GHG_NC*1e-9 # make sure this refers to the correct us_* file
GHG_hiMFDERFA_ER_CFE$EmGHG[41]<-GHG_hiMFDERFA_ER_CFE$EmGHG[40]
GHG_hiMFDERFA_ER_CFE$RenGHG<-renGHGall[renGHGall$Scen=="hiMF_Ext",]$MtCO2e
GHG_hiMFDERFA_ER_CFE$TotGHG<-GHG_hiMFDERFA_ER_CFE$EmGHG+GHG_hiMFDERFA_ER_CFE$RenGHG+GHG_hiMFDERFA_ER_CFE$EnGHG

# add in extra data for the hi MF DERFA AR scenario
rs_hiMFDERFA_all_AR$NewCon<-0
rs_hiMFDERFA_all_AR[rs_hiMFDERFA_all_AR$Vintage.ACS %in% c("2020s","2030s","2040s","2050s"),]$NewCon<-1
rs_hiMFDERFA_all_AR$OldCon<-0
rs_hiMFDERFA_all_AR[rs_hiMFDERFA_all_AR$NewCon==0,]$OldCon<-1

rs_hiMFDERFA_all_AR[,c("Old_OilGHGkg_2020","Old_OilGHGkg_2025","Old_OilGHGkg_2030","Old_OilGHGkg_2035","Old_OilGHGkg_2040","Old_OilGHGkg_2045","Old_OilGHGkg_2050","Old_OilGHGkg_2055","Old_OilGHGkg_2060")]<-1000* 
  rs_hiMFDERFA_all_AR$OldCon*(rs_hiMFDERFA_all_AR$base_weight*rs_hiMFDERFA_all_AR[,c("whiMF_2020",  "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")])*
  (matrix(rep(rs_hiMFDERFA_all_AR$Oil_GJ*GHGI_FO,9),nrow(rs_hiMFDERFA_all_AR),9)+ matrix(rep(rs_hiMFDERFA_all_AR$Prop_GJ*GHGI_LP,9),nrow(rs_hiMFDERFA_all_AR),9))

rs_hiMFDERFA_all_AR[,c("New_OilGHGkg_2020","New_OilGHGkg_2025","New_OilGHGkg_2030","New_OilGHGkg_2035","New_OilGHGkg_2040","New_OilGHGkg_2045","New_OilGHGkg_2050","New_OilGHGkg_2055","New_OilGHGkg_2060")]<-1000* 
  rs_hiMFDERFA_all_AR$NewCon*(rs_hiMFDERFA_all_AR$base_weight*rs_hiMFDERFA_all_AR[,c("whiMF_2020",  "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")])*
  (matrix(rep(rs_hiMFDERFA_all_AR$Oil_GJ*GHGI_FO,9),nrow(rs_hiMFDERFA_all_AR),9)+ matrix(rep(rs_hiMFDERFA_all_AR$Prop_GJ*GHGI_LP,9),nrow(rs_hiMFDERFA_all_AR),9))

rs_hiMFDERFA_all_AR[,c("Old_GasGHGkg_2020","Old_GasGHGkg_2025","Old_GasGHGkg_2030","Old_GasGHGkg_2035","Old_GasGHGkg_2040","Old_GasGHGkg_2045","Old_GasGHGkg_2050","Old_GasGHGkg_2055","Old_GasGHGkg_2060")]<-1000* 
  rs_hiMFDERFA_all_AR$OldCon*(rs_hiMFDERFA_all_AR$base_weight*rs_hiMFDERFA_all_AR[,c("whiMF_2020",  "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")])*
  (matrix(rep(rs_hiMFDERFA_all_AR$Gas_GJ*GHGI_NG,9),nrow(rs_hiMFDERFA_all_AR),9))

rs_hiMFDERFA_all_AR[,c("New_GasGHGkg_2020","New_GasGHGkg_2025","New_GasGHGkg_2030","New_GasGHGkg_2035","New_GasGHGkg_2040","New_GasGHGkg_2045","New_GasGHGkg_2050","New_GasGHGkg_2055","New_GasGHGkg_2060")]<-1000* 
  rs_hiMFDERFA_all_AR$NewCon*(rs_hiMFDERFA_all_AR$base_weight*rs_hiMFDERFA_all_AR[,c("whiMF_2020",  "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")])*
  (matrix(rep(rs_hiMFDERFA_all_AR$Gas_GJ*GHGI_NG,9),nrow(rs_hiMFDERFA_all_AR),9))

rs_hiMFDERFA_all_AR[,c("Old_ElecGHGkg_2020","Old_ElecGHGkg_2025","Old_ElecGHGkg_2030","Old_ElecGHGkg_2035","Old_ElecGHGkg_2040","Old_ElecGHGkg_2045","Old_ElecGHGkg_2050","Old_ElecGHGkg_2055","Old_ElecGHGkg_2060")]<-1000* 
  rs_hiMFDERFA_all_AR$OldCon*(rs_hiMFDERFA_all_AR$base_weight*rs_hiMFDERFA_all_AR[,c("whiMF_2020",  "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")])*
  (rs_hiMFDERFA_all_AR$Elec_GJ*rs_hiMFDERFA_all_AR[,c("GHG_int_2020", "GHG_int_2025","GHG_int_2030","GHG_int_2035","GHG_int_2040","GHG_int_2045","GHG_int_2050","GHG_int_2055","GHG_int_2060")])

rs_hiMFDERFA_all_AR[,c("New_ElecGHGkg_2020","New_ElecGHGkg_2025","New_ElecGHGkg_2030","New_ElecGHGkg_2035","New_ElecGHGkg_2040","New_ElecGHGkg_2045","New_ElecGHGkg_2050","New_ElecGHGkg_2055","New_ElecGHGkg_2060")]<-1000* 
  rs_hiMFDERFA_all_AR$NewCon*(rs_hiMFDERFA_all_AR$base_weight*rs_hiMFDERFA_all_AR[,c("whiMF_2020",  "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")])*
  (rs_hiMFDERFA_all_AR$Elec_GJ*rs_hiMFDERFA_all_AR[,c("GHG_int_2020", "GHG_int_2025","GHG_int_2030","GHG_int_2035","GHG_int_2040","GHG_int_2045","GHG_int_2050","GHG_int_2055","GHG_int_2060")])


OldOilGHG_hiMFDERFA_AR<-data.frame(Year=seq(2020,2060,5),OilGHG=colSums(rs_hiMFDERFA_all_AR[,232:240])*1e-9)
NewOilGHG_hiMFDERFA_AR<-data.frame(Year=seq(2020,2060,5),OilGHG=colSums(rs_hiMFDERFA_all_AR[,241:249])*1e-9)
OldGasGHG_hiMFDERFA_AR<-data.frame(Year=seq(2020,2060,5),GasGHG=colSums(rs_hiMFDERFA_all_AR[,250:258])*1e-9)
NewGasGHG_hiMFDERFA_AR<-data.frame(Year=seq(2020,2060,5),GasGHG=colSums(rs_hiMFDERFA_all_AR[,259:267])*1e-9)
OldElecGHG_hiMFDERFA_AR<-data.frame(Year=seq(2020,2060,5),ElecGHG=colSums(rs_hiMFDERFA_all_AR[,268:276])*1e-9)
NewElecGHG_hiMFDERFA_AR<-data.frame(Year=seq(2020,2060,5),ElecGHG=colSums(rs_hiMFDERFA_all_AR[,277:285])*1e-9)


GHG_hiMFDERFA_AR$OldOilGHG<-data.frame(OilGHG=with(select(OldOilGHG_hiMFDERFA_AR,Year,OilGHG),spline(Year,OilGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_hiMFDERFA_AR$NewOilGHG<-data.frame(OilGHG=with(select(NewOilGHG_hiMFDERFA_AR,Year,OilGHG),spline(Year,OilGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_hiMFDERFA_AR$OldGasGHG<-data.frame(GasGHG=with(select(OldGasGHG_hiMFDERFA_AR,Year,GasGHG),spline(Year,GasGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_hiMFDERFA_AR$NewGasGHG<-data.frame(GasGHG=with(select(NewGasGHG_hiMFDERFA_AR,Year,GasGHG),spline(Year,GasGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_hiMFDERFA_AR$OldElecGHG<-data.frame(ElecGHG=with(select(OldElecGHG_hiMFDERFA_AR,Year,ElecGHG),spline(Year,ElecGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_hiMFDERFA_AR$NewElecGHG<-data.frame(ElecGHG=with(select(NewElecGHG_hiMFDERFA_AR,Year,ElecGHG),spline(Year,ElecGHG,xout = 2020:2060)),method="spline()")[,2]

# repeat for LREC electricity
rs_hiMFDERFA_all_AR[,c("Old_ElecGHGkg_2020_LRE","Old_ElecGHGkg_2025_LRE","Old_ElecGHGkg_2030_LRE","Old_ElecGHGkg_2035_LRE","Old_ElecGHGkg_2040_LRE","Old_ElecGHGkg_2045_LRE","Old_ElecGHGkg_2050_LRE","Old_ElecGHGkg_2055_LRE","Old_ElecGHGkg_2060_LRE")]<-1000* 
  rs_hiMFDERFA_all_AR$OldCon*(rs_hiMFDERFA_all_AR$base_weight*rs_hiMFDERFA_all_AR[,c("whiMF_2020",  "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")])*
  (rs_hiMFDERFA_all_AR$Elec_GJ*rs_hiMFDERFA_all_AR[,c("GHG_int_2020_LRE", "GHG_int_2025_LRE","GHG_int_2030_LRE","GHG_int_2035_LRE","GHG_int_2040_LRE","GHG_int_2045_LRE","GHG_int_2050_LRE","GHG_int_2055_LRE","GHG_int_2060_LRE")])

rs_hiMFDERFA_all_AR[,c("New_ElecGHGkg_2020_LRE","New_ElecGHGkg_2025_LRE","New_ElecGHGkg_2030_LRE","New_ElecGHGkg_2035_LRE","New_ElecGHGkg_2040_LRE","New_ElecGHGkg_2045_LRE","New_ElecGHGkg_2050_LRE","New_ElecGHGkg_2055_LRE","New_ElecGHGkg_2060_LRE")]<-1000* 
  rs_hiMFDERFA_all_AR$NewCon*(rs_hiMFDERFA_all_AR$base_weight*rs_hiMFDERFA_all_AR[,c("whiMF_2020",  "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")])*
  (rs_hiMFDERFA_all_AR$Elec_GJ*rs_hiMFDERFA_all_AR[,c("GHG_int_2020_LRE", "GHG_int_2025_LRE","GHG_int_2030_LRE","GHG_int_2035_LRE","GHG_int_2040_LRE","GHG_int_2045_LRE","GHG_int_2050_LRE","GHG_int_2055_LRE","GHG_int_2060_LRE")])

OldElecGHG_hiMFDERFA_AR_LREC<-data.frame(Year=seq(2020,2060,5),ElecGHG=colSums(rs_hiMFDERFA_all_AR[,286:294])*1e-9)
NewElecGHG_hiMFDERFA_AR_LREC<-data.frame(Year=seq(2020,2060,5),ElecGHG=colSums(rs_hiMFDERFA_all_AR[,295:303])*1e-9)

GHG_hiMFDERFA_AR_LREC$OldOilGHG<-data.frame(OilGHG=with(select(OldOilGHG_hiMFDERFA_AR,Year,OilGHG),spline(Year,OilGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_hiMFDERFA_AR_LREC$NewOilGHG<-data.frame(OilGHG=with(select(NewOilGHG_hiMFDERFA_AR,Year,OilGHG),spline(Year,OilGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_hiMFDERFA_AR_LREC$OldGasGHG<-data.frame(GasGHG=with(select(OldGasGHG_hiMFDERFA_AR,Year,GasGHG),spline(Year,GasGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_hiMFDERFA_AR_LREC$NewGasGHG<-data.frame(GasGHG=with(select(NewGasGHG_hiMFDERFA_AR,Year,GasGHG),spline(Year,GasGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_hiMFDERFA_AR_LREC$OldElecGHG<-data.frame(ElecGHG=with(select(OldElecGHG_hiMFDERFA_AR_LREC,Year,ElecGHG),spline(Year,ElecGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_hiMFDERFA_AR_LREC$NewElecGHG<-data.frame(ElecGHG=with(select(NewElecGHG_hiMFDERFA_AR_LREC,Year,ElecGHG),spline(Year,ElecGHG,xout = 2020:2060)),method="spline()")[,2]

GHG_hiMFDERFA_AR$EmGHG_pc<-GHG_hiMFDERFA_AR$EmGHG/GHG_hiMFDERFA_AR$EmGHG[1]
GHG_hiMFDERFA_AR$TotGHG_pc<-GHG_hiMFDERFA_AR$TotGHG/GHG_hiMFDERFA_AR$TotGHG[1]
GHG_hiMFDERFA_AR$OilGHG_pc<-rowSums(GHG_hiMFDERFA_AR[,c("OldOilGHG","NewOilGHG")])/GHG_hiMFDERFA_AR$OldOilGHG[1]
GHG_hiMFDERFA_AR$GasGHG_pc<-rowSums(GHG_hiMFDERFA_AR[,c("OldGasGHG","NewGasGHG")])/GHG_hiMFDERFA_AR$OldGasGHG[1]
GHG_hiMFDERFA_AR$ElecGHG_pc<-rowSums(GHG_hiMFDERFA_AR[,c("OldElecGHG","NewElecGHG")])/GHG_hiMFDERFA_AR$OldElecGHG[1]
GHG_hiMFDERFA_AR$EmGHG_pc_tot<-GHG_hiMFDERFA_AR$EmGHG/GHG_hiMFDERFA_AR$TotGHG

GHG_hiMFDERFA_AR_LREC$EmGHG_pc<-GHG_hiMFDERFA_AR_LREC$EmGHG/GHG_hiMFDERFA_AR_LREC$EmGHG[1]
GHG_hiMFDERFA_AR_LREC$TotGHG_pc<-GHG_hiMFDERFA_AR_LREC$TotGHG/GHG_hiMFDERFA_AR_LREC$TotGHG[1]
GHG_hiMFDERFA_AR_LREC$OilGHG_pc<-rowSums(GHG_hiMFDERFA_AR_LREC[,c("OldOilGHG","NewOilGHG")])/GHG_hiMFDERFA_AR_LREC$OldOilGHG[1]
GHG_hiMFDERFA_AR_LREC$GasGHG_pc<-rowSums(GHG_hiMFDERFA_AR_LREC[,c("OldGasGHG","NewGasGHG")])/GHG_hiMFDERFA_AR_LREC$OldGasGHG[1]
GHG_hiMFDERFA_AR_LREC$ElecGHG_pc<-rowSums(GHG_hiMFDERFA_AR_LREC[,c("OldElecGHG","NewElecGHG")])/GHG_hiMFDERFA_AR_LREC$OldElecGHG[1]
GHG_hiMFDERFA_AR_LREC$EmGHG_pc_tot<-GHG_hiMFDERFA_AR_LREC$EmGHG/GHG_hiMFDERFA_AR_LREC$TotGHG

# repeat for CFE electricity
rs_hiMFDERFA_all_AR[,c("Old_ElecGHGkg_2020_CFE","Old_ElecGHGkg_2025_CFE","Old_ElecGHGkg_2030_CFE","Old_ElecGHGkg_2035_CFE","Old_ElecGHGkg_2040_CFE","Old_ElecGHGkg_2045_CFE","Old_ElecGHGkg_2050_CFE","Old_ElecGHGkg_2055_CFE","Old_ElecGHGkg_2060_CFE")]<-1000* 
  rs_hiMFDERFA_all_AR$OldCon*(rs_hiMFDERFA_all_AR$base_weight*rs_hiMFDERFA_all_AR[,c("whiMF_2020",  "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")])*
  (rs_hiMFDERFA_all_AR$Elec_GJ*rs_hiMFDERFA_all_AR[,c("GHG_int_2020_CFE", "GHG_int_2025_CFE","GHG_int_2030_CFE","GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")])

rs_hiMFDERFA_all_AR[,c("New_ElecGHGkg_2020_CFE","New_ElecGHGkg_2025_CFE","New_ElecGHGkg_2030_CFE","New_ElecGHGkg_2035_CFE","New_ElecGHGkg_2040_CFE","New_ElecGHGkg_2045_CFE","New_ElecGHGkg_2050_CFE","New_ElecGHGkg_2055_CFE","New_ElecGHGkg_2060_CFE")]<-1000* 
  rs_hiMFDERFA_all_AR$NewCon*(rs_hiMFDERFA_all_AR$base_weight*rs_hiMFDERFA_all_AR[,c("whiMF_2020",  "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")])*
  (rs_hiMFDERFA_all_AR$Elec_GJ*rs_hiMFDERFA_all_AR[,c("GHG_int_2020_CFE", "GHG_int_2025_CFE","GHG_int_2030_CFE","GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")])

OldElecGHG_hiMFDERFA_AR_CFE<-data.frame(Year=seq(2020,2060,5),ElecGHG=colSums(rs_hiMFDERFA_all_AR[,304:312])*1e-9)
NewElecGHG_hiMFDERFA_AR_CFE<-data.frame(Year=seq(2020,2060,5),ElecGHG=colSums(rs_hiMFDERFA_all_AR[,313:321])*1e-9)

GHG_hiMFDERFA_AR_CFE$OldOilGHG<-data.frame(OilGHG=with(select(OldOilGHG_hiMFDERFA_AR,Year,OilGHG),spline(Year,OilGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_hiMFDERFA_AR_CFE$NewOilGHG<-data.frame(OilGHG=with(select(NewOilGHG_hiMFDERFA_AR,Year,OilGHG),spline(Year,OilGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_hiMFDERFA_AR_CFE$OldGasGHG<-data.frame(GasGHG=with(select(OldGasGHG_hiMFDERFA_AR,Year,GasGHG),spline(Year,GasGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_hiMFDERFA_AR_CFE$NewGasGHG<-data.frame(GasGHG=with(select(NewGasGHG_hiMFDERFA_AR,Year,GasGHG),spline(Year,GasGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_hiMFDERFA_AR_CFE$OldElecGHG<-data.frame(ElecGHG=with(select(OldElecGHG_hiMFDERFA_AR_CFE,Year,ElecGHG),spline(Year,ElecGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_hiMFDERFA_AR_CFE$NewElecGHG<-data.frame(ElecGHG=with(select(NewElecGHG_hiMFDERFA_AR_CFE,Year,ElecGHG),spline(Year,ElecGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_hiMFDERFA_AR_CFE$OldElecGHG[1:6]<-GHG_hiMFDERFA_AR_LREC$OldElecGHG[1:6] # 2020:2025 same as LRE
GHG_hiMFDERFA_AR_CFE$NewElecGHG[1:6]<-GHG_hiMFDERFA_AR_LREC$NewElecGHG[1:6] # 2020:2025 same as LRE
GHG_hiMFDERFA_AR_CFE$OldElecGHG[16:41]<-GHG_hiMFDERFA_AR_CFE$NewElecGHG[16:41]<-0

# maybe unneccesary?
# GHG_hiMFDERFA_AR$EmGHG_pc<-GHG_hiMFDERFA_AR$EmGHG/GHG_hiMFDERFA_AR$EmGHG[1]
# GHG_hiMFDERFA_AR$TotGHG_pc<-GHG_hiMFDERFA_AR$TotGHG/GHG_hiMFDERFA_AR$TotGHG[1]
# GHG_hiMFDERFA_AR$OilGHG_pc<-rowSums(GHG_hiMFDERFA_AR[,c("OldOilGHG","NewOilGHG")])/GHG_hiMFDERFA_AR$OldOilGHG[1]
# GHG_hiMFDERFA_AR$GasGHG_pc<-rowSums(GHG_hiMFDERFA_AR[,c("OldGasGHG","NewGasGHG")])/GHG_hiMFDERFA_AR$OldGasGHG[1]
# GHG_hiMFDERFA_AR$ElecGHG_pc<-rowSums(GHG_hiMFDERFA_AR[,c("OldElecGHG","NewElecGHG")])/GHG_hiMFDERFA_AR$OldElecGHG[1]
# GHG_hiMFDERFA_AR$EmGHG_pc_tot<-GHG_hiMFDERFA_AR$EmGHG/GHG_hiMFDERFA_AR$TotGHG
# 
# GHG_hiMFDERFA_AR_CFE$EmGHG_pc<-GHG_hiMFDERFA_AR_CFE$EmGHG/GHG_hiMFDERFA_AR_CFE$EmGHG[1]
# GHG_hiMFDERFA_AR_CFE$TotGHG_pc<-GHG_hiMFDERFA_AR_CFE$TotGHG/GHG_hiMFDERFA_AR_CFE$TotGHG[1]
# GHG_hiMFDERFA_AR_CFE$OilGHG_pc<-rowSums(GHG_hiMFDERFA_AR_CFE[,c("OldOilGHG","NewOilGHG")])/GHG_hiMFDERFA_AR_CFE$OldOilGHG[1]
# GHG_hiMFDERFA_AR_CFE$GasGHG_pc<-rowSums(GHG_hiMFDERFA_AR_CFE[,c("OldGasGHG","NewGasGHG")])/GHG_hiMFDERFA_AR_CFE$OldGasGHG[1]
# GHG_hiMFDERFA_AR_CFE$ElecGHG_pc<-rowSums(GHG_hiMFDERFA_AR_CFE[,c("OldElecGHG","NewElecGHG")])/GHG_hiMFDERFA_AR_CFE$OldElecGHG[1]
# GHG_hiMFDERFA_AR_CFE$EmGHG_pc_tot<-GHG_hiMFDERFA_AR_CFE$EmGHG/GHG_hiMFDERFA_AR_CFE$TotGHG

# add in extra data for the hi MF DERFA ER scenario
rs_hiMFDERFA_all_ER$NewCon<-0
rs_hiMFDERFA_all_ER[rs_hiMFDERFA_all_ER$Vintage.ACS %in% c("2020s","2030s","2040s","2050s"),]$NewCon<-1
rs_hiMFDERFA_all_ER$OldCon<-0
rs_hiMFDERFA_all_ER[rs_hiMFDERFA_all_ER$NewCon==0,]$OldCon<-1

rs_hiMFDERFA_all_ER[,c("Old_OilGHGkg_2020","Old_OilGHGkg_2025","Old_OilGHGkg_2030","Old_OilGHGkg_2035","Old_OilGHGkg_2040","Old_OilGHGkg_2045","Old_OilGHGkg_2050","Old_OilGHGkg_2055","Old_OilGHGkg_2060")]<-1000* 
  rs_hiMFDERFA_all_ER$OldCon*(rs_hiMFDERFA_all_ER$base_weight*rs_hiMFDERFA_all_ER[,c("whiMF_2020",  "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")])*
  (matrix(rep(rs_hiMFDERFA_all_ER$Oil_GJ*GHGI_FO,9),nrow(rs_hiMFDERFA_all_ER),9)+ matrix(rep(rs_hiMFDERFA_all_ER$Prop_GJ*GHGI_LP,9),nrow(rs_hiMFDERFA_all_ER),9))

rs_hiMFDERFA_all_ER[,c("New_OilGHGkg_2020","New_OilGHGkg_2025","New_OilGHGkg_2030","New_OilGHGkg_2035","New_OilGHGkg_2040","New_OilGHGkg_2045","New_OilGHGkg_2050","New_OilGHGkg_2055","New_OilGHGkg_2060")]<-1000* 
  rs_hiMFDERFA_all_ER$NewCon*(rs_hiMFDERFA_all_ER$base_weight*rs_hiMFDERFA_all_ER[,c("whiMF_2020",  "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")])*
  (matrix(rep(rs_hiMFDERFA_all_ER$Oil_GJ*GHGI_FO,9),nrow(rs_hiMFDERFA_all_ER),9)+ matrix(rep(rs_hiMFDERFA_all_ER$Prop_GJ*GHGI_LP,9),nrow(rs_hiMFDERFA_all_ER),9))

rs_hiMFDERFA_all_ER[,c("Old_GasGHGkg_2020","Old_GasGHGkg_2025","Old_GasGHGkg_2030","Old_GasGHGkg_2035","Old_GasGHGkg_2040","Old_GasGHGkg_2045","Old_GasGHGkg_2050","Old_GasGHGkg_2055","Old_GasGHGkg_2060")]<-1000* 
  rs_hiMFDERFA_all_ER$OldCon*(rs_hiMFDERFA_all_ER$base_weight*rs_hiMFDERFA_all_ER[,c("whiMF_2020",  "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")])*
  (matrix(rep(rs_hiMFDERFA_all_ER$Gas_GJ*GHGI_NG,9),nrow(rs_hiMFDERFA_all_ER),9))

rs_hiMFDERFA_all_ER[,c("New_GasGHGkg_2020","New_GasGHGkg_2025","New_GasGHGkg_2030","New_GasGHGkg_2035","New_GasGHGkg_2040","New_GasGHGkg_2045","New_GasGHGkg_2050","New_GasGHGkg_2055","New_GasGHGkg_2060")]<-1000* 
  rs_hiMFDERFA_all_ER$NewCon*(rs_hiMFDERFA_all_ER$base_weight*rs_hiMFDERFA_all_ER[,c("whiMF_2020",  "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")])*
  (matrix(rep(rs_hiMFDERFA_all_ER$Gas_GJ*GHGI_NG,9),nrow(rs_hiMFDERFA_all_ER),9))

rs_hiMFDERFA_all_ER[,c("Old_ElecGHGkg_2020","Old_ElecGHGkg_2025","Old_ElecGHGkg_2030","Old_ElecGHGkg_2035","Old_ElecGHGkg_2040","Old_ElecGHGkg_2045","Old_ElecGHGkg_2050","Old_ElecGHGkg_2055","Old_ElecGHGkg_2060")]<-1000* 
  rs_hiMFDERFA_all_ER$OldCon*(rs_hiMFDERFA_all_ER$base_weight*rs_hiMFDERFA_all_ER[,c("whiMF_2020",  "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")])*
  (rs_hiMFDERFA_all_ER$Elec_GJ*rs_hiMFDERFA_all_ER[,c("GHG_int_2020", "GHG_int_2025","GHG_int_2030","GHG_int_2035","GHG_int_2040","GHG_int_2045","GHG_int_2050","GHG_int_2055","GHG_int_2060")])

rs_hiMFDERFA_all_ER[,c("New_ElecGHGkg_2020","New_ElecGHGkg_2025","New_ElecGHGkg_2030","New_ElecGHGkg_2035","New_ElecGHGkg_2040","New_ElecGHGkg_2045","New_ElecGHGkg_2050","New_ElecGHGkg_2055","New_ElecGHGkg_2060")]<-1000* 
  rs_hiMFDERFA_all_ER$NewCon*(rs_hiMFDERFA_all_ER$base_weight*rs_hiMFDERFA_all_ER[,c("whiMF_2020",  "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")])*
  (rs_hiMFDERFA_all_ER$Elec_GJ*rs_hiMFDERFA_all_ER[,c("GHG_int_2020", "GHG_int_2025","GHG_int_2030","GHG_int_2035","GHG_int_2040","GHG_int_2045","GHG_int_2050","GHG_int_2055","GHG_int_2060")])


OldOilGHG_hiMFDERFA_ER<-data.frame(Year=seq(2020,2060,5),OilGHG=colSums(rs_hiMFDERFA_all_ER[,232:240])*1e-9)
NewOilGHG_hiMFDERFA_ER<-data.frame(Year=seq(2020,2060,5),OilGHG=colSums(rs_hiMFDERFA_all_ER[,241:249])*1e-9)
OldGasGHG_hiMFDERFA_ER<-data.frame(Year=seq(2020,2060,5),GasGHG=colSums(rs_hiMFDERFA_all_ER[,250:258])*1e-9)
NewGasGHG_hiMFDERFA_ER<-data.frame(Year=seq(2020,2060,5),GasGHG=colSums(rs_hiMFDERFA_all_ER[,259:267])*1e-9)
OldElecGHG_hiMFDERFA_ER<-data.frame(Year=seq(2020,2060,5),ElecGHG=colSums(rs_hiMFDERFA_all_ER[,268:276])*1e-9)
NewElecGHG_hiMFDERFA_ER<-data.frame(Year=seq(2020,2060,5),ElecGHG=colSums(rs_hiMFDERFA_all_ER[,277:285])*1e-9)

GHG_hiMFDERFA_ER$OldOilGHG<-data.frame(OilGHG=with(select(OldOilGHG_hiMFDERFA_ER,Year,OilGHG),spline(Year,OilGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_hiMFDERFA_ER$NewOilGHG<-data.frame(OilGHG=with(select(NewOilGHG_hiMFDERFA_ER,Year,OilGHG),spline(Year,OilGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_hiMFDERFA_ER$OldGasGHG<-data.frame(GasGHG=with(select(OldGasGHG_hiMFDERFA_ER,Year,GasGHG),spline(Year,GasGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_hiMFDERFA_ER$NewGasGHG<-data.frame(GasGHG=with(select(NewGasGHG_hiMFDERFA_ER,Year,GasGHG),spline(Year,GasGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_hiMFDERFA_ER$OldElecGHG<-data.frame(ElecGHG=with(select(OldElecGHG_hiMFDERFA_ER,Year,ElecGHG),spline(Year,ElecGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_hiMFDERFA_ER$NewElecGHG<-data.frame(ElecGHG=with(select(NewElecGHG_hiMFDERFA_ER,Year,ElecGHG),spline(Year,ElecGHG,xout = 2020:2060)),method="spline()")[,2]

# repeat for LREC electricity
rs_hiMFDERFA_all_ER[,c("Old_ElecGHGkg_2020_LRE","Old_ElecGHGkg_2025_LRE","Old_ElecGHGkg_2030_LRE","Old_ElecGHGkg_2035_LRE","Old_ElecGHGkg_2040_LRE","Old_ElecGHGkg_2045_LRE","Old_ElecGHGkg_2050_LRE","Old_ElecGHGkg_2055_LRE","Old_ElecGHGkg_2060_LRE")]<-1000* 
  rs_hiMFDERFA_all_ER$OldCon*(rs_hiMFDERFA_all_ER$base_weight*rs_hiMFDERFA_all_ER[,c("whiMF_2020",  "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")])*
  (rs_hiMFDERFA_all_ER$Elec_GJ*rs_hiMFDERFA_all_ER[,c("GHG_int_2020_LRE", "GHG_int_2025_LRE","GHG_int_2030_LRE","GHG_int_2035_LRE","GHG_int_2040_LRE","GHG_int_2045_LRE","GHG_int_2050_LRE","GHG_int_2055_LRE","GHG_int_2060_LRE")])

rs_hiMFDERFA_all_ER[,c("New_ElecGHGkg_2020_LRE","New_ElecGHGkg_2025_LRE","New_ElecGHGkg_2030_LRE","New_ElecGHGkg_2035_LRE","New_ElecGHGkg_2040_LRE","New_ElecGHGkg_2045_LRE","New_ElecGHGkg_2050_LRE","New_ElecGHGkg_2055_LRE","New_ElecGHGkg_2060_LRE")]<-1000* 
  rs_hiMFDERFA_all_ER$NewCon*(rs_hiMFDERFA_all_ER$base_weight*rs_hiMFDERFA_all_ER[,c("whiMF_2020",  "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")])*
  (rs_hiMFDERFA_all_ER$Elec_GJ*rs_hiMFDERFA_all_ER[,c("GHG_int_2020_LRE", "GHG_int_2025_LRE","GHG_int_2030_LRE","GHG_int_2035_LRE","GHG_int_2040_LRE","GHG_int_2045_LRE","GHG_int_2050_LRE","GHG_int_2055_LRE","GHG_int_2060_LRE")])

OldElecGHG_hiMFDERFA_ER_LREC<-data.frame(Year=seq(2020,2060,5),ElecGHG=colSums(rs_hiMFDERFA_all_ER[,286:294])*1e-9)
NewElecGHG_hiMFDERFA_ER_LREC<-data.frame(Year=seq(2020,2060,5),ElecGHG=colSums(rs_hiMFDERFA_all_ER[,295:303])*1e-9)

GHG_hiMFDERFA_ER_LREC$OldOilGHG<-data.frame(OilGHG=with(select(OldOilGHG_hiMFDERFA_ER,Year,OilGHG),spline(Year,OilGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_hiMFDERFA_ER_LREC$NewOilGHG<-data.frame(OilGHG=with(select(NewOilGHG_hiMFDERFA_ER,Year,OilGHG),spline(Year,OilGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_hiMFDERFA_ER_LREC$OldGasGHG<-data.frame(GasGHG=with(select(OldGasGHG_hiMFDERFA_ER,Year,GasGHG),spline(Year,GasGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_hiMFDERFA_ER_LREC$NewGasGHG<-data.frame(GasGHG=with(select(NewGasGHG_hiMFDERFA_ER,Year,GasGHG),spline(Year,GasGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_hiMFDERFA_ER_LREC$OldElecGHG<-data.frame(ElecGHG=with(select(OldElecGHG_hiMFDERFA_ER_LREC,Year,ElecGHG),spline(Year,ElecGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_hiMFDERFA_ER_LREC$NewElecGHG<-data.frame(ElecGHG=with(select(NewElecGHG_hiMFDERFA_ER_LREC,Year,ElecGHG),spline(Year,ElecGHG,xout = 2020:2060)),method="spline()")[,2]

# GHG_hiMFDERFA_ER$EmGHG_pc<-GHG_hiMFDERFA_ER$EmGHG/GHG_hiMFDERFA_ER$EmGHG[1]
# GHG_hiMFDERFA_ER$TotGHG_pc<-GHG_hiMFDERFA_ER$TotGHG/GHG_hiMFDERFA_ER$TotGHG[1]
# GHG_hiMFDERFA_ER$OilGHG_pc<-rowSums(GHG_hiMFDERFA_ER[,c("OldOilGHG","NewOilGHG")])/GHG_hiMFDERFA_ER$OldOilGHG[1]
# GHG_hiMFDERFA_ER$GasGHG_pc<-rowSums(GHG_hiMFDERFA_ER[,c("OldGasGHG","NewGasGHG")])/GHG_hiMFDERFA_ER$OldGasGHG[1]
# GHG_hiMFDERFA_ER$ElecGHG_pc<-rowSums(GHG_hiMFDERFA_ER[,c("OldElecGHG","NewElecGHG")])/GHG_hiMFDERFA_ER$OldElecGHG[1]
# GHG_hiMFDERFA_ER$EmGHG_pc_tot<-GHG_hiMFDERFA_ER$EmGHG/GHG_hiMFDERFA_ER$TotGHG
# 
# GHG_hiMFDERFA_ER_LREC$EmGHG_pc<-GHG_hiMFDERFA_ER_LREC$EmGHG/GHG_hiMFDERFA_ER_LREC$EmGHG[1]
# GHG_hiMFDERFA_ER_LREC$TotGHG_pc<-GHG_hiMFDERFA_ER_LREC$TotGHG/GHG_hiMFDERFA_ER_LREC$TotGHG[1]
# GHG_hiMFDERFA_ER_LREC$OilGHG_pc<-rowSums(GHG_hiMFDERFA_ER_LREC[,c("OldOilGHG","NewOilGHG")])/GHG_hiMFDERFA_ER_LREC$OldOilGHG[1]
# GHG_hiMFDERFA_ER_LREC$GasGHG_pc<-rowSums(GHG_hiMFDERFA_ER_LREC[,c("OldGasGHG","NewGasGHG")])/GHG_hiMFDERFA_ER_LREC$OldGasGHG[1]
# GHG_hiMFDERFA_ER_LREC$ElecGHG_pc<-rowSums(GHG_hiMFDERFA_ER_LREC[,c("OldElecGHG","NewElecGHG")])/GHG_hiMFDERFA_ER_LREC$OldElecGHG[1]
# GHG_hiMFDERFA_ER_LREC$EmGHG_pc_tot<-GHG_hiMFDERFA_ER_LREC$EmGHG/GHG_hiMFDERFA_ER_LREC$TotGHG

# repeat for CFE electricity
rs_hiMFDERFA_all_ER[,c("Old_ElecGHGkg_2020_CFE","Old_ElecGHGkg_2025_CFE","Old_ElecGHGkg_2030_CFE","Old_ElecGHGkg_2035_CFE","Old_ElecGHGkg_2040_CFE","Old_ElecGHGkg_2045_CFE","Old_ElecGHGkg_2050_CFE","Old_ElecGHGkg_2055_CFE","Old_ElecGHGkg_2060_CFE")]<-1000* 
  rs_hiMFDERFA_all_ER$OldCon*(rs_hiMFDERFA_all_ER$base_weight*rs_hiMFDERFA_all_ER[,c("whiMF_2020",  "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")])*
  (rs_hiMFDERFA_all_ER$Elec_GJ*rs_hiMFDERFA_all_ER[,c("GHG_int_2020_CFE", "GHG_int_2025_CFE","GHG_int_2030_CFE","GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")])

rs_hiMFDERFA_all_ER[,c("New_ElecGHGkg_2020_CFE","New_ElecGHGkg_2025_CFE","New_ElecGHGkg_2030_CFE","New_ElecGHGkg_2035_CFE","New_ElecGHGkg_2040_CFE","New_ElecGHGkg_2045_CFE","New_ElecGHGkg_2050_CFE","New_ElecGHGkg_2055_CFE","New_ElecGHGkg_2060_CFE")]<-1000* 
  rs_hiMFDERFA_all_ER$NewCon*(rs_hiMFDERFA_all_ER$base_weight*rs_hiMFDERFA_all_ER[,c("whiMF_2020",  "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")])*
  (rs_hiMFDERFA_all_ER$Elec_GJ*rs_hiMFDERFA_all_ER[,c("GHG_int_2020_CFE", "GHG_int_2025_CFE","GHG_int_2030_CFE","GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")])

OldElecGHG_hiMFDERFA_ER_CFE<-data.frame(Year=seq(2020,2060,5),ElecGHG=colSums(rs_hiMFDERFA_all_ER[,304:312])*1e-9)
NewElecGHG_hiMFDERFA_ER_CFE<-data.frame(Year=seq(2020,2060,5),ElecGHG=colSums(rs_hiMFDERFA_all_ER[,313:321])*1e-9)

GHG_hiMFDERFA_ER_CFE$OldOilGHG<-data.frame(OilGHG=with(select(OldOilGHG_hiMFDERFA_ER,Year,OilGHG),spline(Year,OilGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_hiMFDERFA_ER_CFE$NewOilGHG<-data.frame(OilGHG=with(select(NewOilGHG_hiMFDERFA_ER,Year,OilGHG),spline(Year,OilGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_hiMFDERFA_ER_CFE$OldGasGHG<-data.frame(GasGHG=with(select(OldGasGHG_hiMFDERFA_ER,Year,GasGHG),spline(Year,GasGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_hiMFDERFA_ER_CFE$NewGasGHG<-data.frame(GasGHG=with(select(NewGasGHG_hiMFDERFA_ER,Year,GasGHG),spline(Year,GasGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_hiMFDERFA_ER_CFE$OldElecGHG<-data.frame(ElecGHG=with(select(OldElecGHG_hiMFDERFA_ER_CFE,Year,ElecGHG),spline(Year,ElecGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_hiMFDERFA_ER_CFE$NewElecGHG<-data.frame(ElecGHG=with(select(NewElecGHG_hiMFDERFA_ER_CFE,Year,ElecGHG),spline(Year,ElecGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_hiMFDERFA_ER_CFE$OldElecGHG[1:6]<-GHG_hiMFDERFA_ER_LREC$OldElecGHG[1:6] # 2020:2025 same as LRE
GHG_hiMFDERFA_ER_CFE$NewElecGHG[1:6]<-GHG_hiMFDERFA_ER_LREC$NewElecGHG[1:6] # 2020:2025 same as LRE
GHG_hiMFDERFA_ER_CFE$OldElecGHG[16:41]<-GHG_hiMFDERFA_ER_CFE$NewElecGHG[16:41]<-0


rm(list=ls(pattern = "rs_"))
rm(list=ls(pattern = "GHGelec"))
rm(list=ls(pattern = "New"))
rm(list=ls(pattern = "Old"))

# combine results
GHGall<-data.frame(matrix(ncol = 9,nrow=0))
names(GHGall)<-names(GHG_baseRFA_AR)
# ng<-ls(pattern = "GHG_")[-c(5,6,75:98)] # workaround, need to figure out why there are all the extra files matching the pattern and how to avoid them
ng<-ls(pattern = "GHG_") # check i don't need the workaround, at present 110: the 108 combos plus two No Ren scenario
GHG_base_NR$RenGHG<-GHG_base_NR_G20$RenGHG<-0
# for (a in 1:length(ls(pattern = "GHG_"))) {x<-get(ls(pattern = "GHG_")[a]);GHGall<-rbind(GHGall,x[,1:8])}
for (a in 1:length(ng)) {x<-get(ng[a]); x1<-x[,names(GHGall)];GHGall<-rbind(GHGall,x1)}
GHGall$Housing_Scenario<-"1A Baseline"
GHGall[GHGall$StockScen==1 & GHGall$CharScen=="B",] $Housing_Scenario<-"1B Baseline RFA"
GHGall[GHGall$StockScen==1 & GHGall$CharScen=="C",] $Housing_Scenario<-"1C Baseline IE"
GHGall[GHGall$StockScen==1 & GHGall$CharScen=="D",] $Housing_Scenario<-"1D Baseline IE & RFA"

GHGall[GHGall$StockScen==2 & GHGall$CharScen=="A",] $Housing_Scenario<-"2A High Turnover"
GHGall[GHGall$StockScen==2 & GHGall$CharScen=="B",] $Housing_Scenario<-"2B High Turnover RFA"
GHGall[GHGall$StockScen==2 & GHGall$CharScen=="C",] $Housing_Scenario<-"2C High Turnover IE"
GHGall[GHGall$StockScen==2 & GHGall$CharScen=="D",] $Housing_Scenario<-"2D High Turnover IE & RFA"

GHGall[GHGall$StockScen==3 & GHGall$CharScen=="A",] $Housing_Scenario<-"3A High Multifamily"
GHGall[GHGall$StockScen==3 & GHGall$CharScen=="B",] $Housing_Scenario<-"3B High Multifamily RFA"
GHGall[GHGall$StockScen==3 & GHGall$CharScen=="C",] $Housing_Scenario<-"3C High Multifamily IE"
GHGall[GHGall$StockScen==3 & GHGall$CharScen=="D",] $Housing_Scenario<-"3D High Multifamily IE & RFA"

GHGall$StockScen<-as.character(GHGall$StockScen)

GHGall$`New House Chars`<-"A. Base"
GHGall[GHGall$CharScen=="B",]$`New House Chars`<-"B. RFA"
GHGall[GHGall$CharScen=="C",]$`New House Chars`<-"C. IE"
GHGall[GHGall$CharScen=="D",]$`New House Chars`<-"D. RFA + IE"

GHGall$StockScenario<-"1 Baseline"
GHGall[GHGall$StockScen=="2",]$StockScenario<-"2 Hi Turnover"
GHGall[GHGall$StockScen=="3",]$StockScenario<-"3 Hi Multifamily"
# here i save all of the GHG files
save(GHGall,file="../Final_results/GHGall_new.RData")
# load("../Final_results/GHGall_new.RData")
# first make Fig 1 plots #
# try new, with all plots together.
GHGall$UniqScen<-paste(GHGall$StockScen,GHGall$CharScen,GHGall$RenScen,GHGall$ElecScen,sep="_")
GHGall$ElecRen<-paste(GHGall$ElecScen,GHGall$RenScen,sep="_")

ghg<-GHGall[!GHGall$RenScen=="NR",] # exclude the no ren scenario
ghg$`Elec_Ren Scen` <-factor(ghg$ElecRen,ordered = TRUE,
                       levels=c("MC_RR","MC_AR","MC_ER","LREC_RR","LREC_AR","LREC_ER","CFE_RR","CFE_AR","CFE_ER"))

obg<-c("#8C2D04","#F16913","#FDAE6B","#084594","#6BAED6","#C6DBEF","#005A32","#41AB5D","#A1D99B") # oranges blues greens
rbo<-c("#99000D", "#FB6A4A","#FCBBA1" ,"#084594","#6BAED6","#C6DBEF","#8C2D04","#F16913","#FDAE6B")
rbg<-c("#99000D", "#FB6A4A","#FCBBA1" ,"#084594","#6BAED6","#C6DBEF","#005A32","#41AB5D","#A1D99B")

pdf<-data.frame(xa=2050,ya=330) # 20% of 2005 emissions (1.65 Gt total from residential sector energy + construction). Based on US GHGI plus Berrill et al JIE 
odf<-data.frame(xa=2030,ya=450) # 50% of 2020 emissions based on this study
hdf<-data.frame(xa=2030,ya=825) # 50% of 2005 emissions (1.65 Gt total from residential sector energy + construction). Based on US GHGI plus Berrill et al JIE 
zdf<-data.frame(xa=2050,ya=0) # 1.5 goal of 0 by 2050

windows(width = 9.2,height = 7.5)
ggplot(ghg,aes(Year,TotGHG,group=UniqScen)) + geom_line(aes(color=`Elec_Ren Scen`),size=1.05,alpha=1) + 
  scale_y_continuous(labels = scales::comma,limits = c(0,960)) + scale_color_manual(values=rbg) +theme_bw() + 
  geom_segment(aes(x=2048,xend=2052,y=330,yend=330),linetype="dashed")+geom_text(x=2049, y=350, label="Paris 2050 Target") + geom_point(data=pdf,aes(x=xa,y=ya,group=1)) +
  geom_segment(aes(x=2028,xend=2032,y=450,yend=450),linetype="dashed")+geom_text(x=2030, y=430, label="1.5°C  Target") + geom_point(data=odf,aes(x=xa,y=ya,group=1)) +
  geom_segment(aes(x=2028,xend=2032,y=825,yend=825),linetype="dashed")+geom_text(x=2034, y=850, label="50% 2030  Target") + geom_point(data=hdf,aes(x=xa,y=ya,group=1)) +
  geom_segment(aes(x=2048,xend=2052,y=0,yend=0),linetype="dashed")+geom_text(x=2050, y=20, label="1.5°C  Target") + geom_point(data=zdf,aes(x=xa,y=ya,group=1)) +
  labs(title ="Annual Emissions by Electricity and Renovation Scenario",y="Mton CO2e") +
  theme(axis.text=element_text(size=11),axis.title=element_text(size=12,face = "bold"),plot.title = element_text(size = 12),legend.key.width = unit(1,'cm'))

ghg_MC_RR<-GHGall[GHGall$ElecScen=="MC" & GHGall$RenScen=="RR",]
# windows(width = 9.2,height = 7.5)
# ggplot(ghg_MC_RR,aes(Year,TotGHG,group=UniqScen)) + geom_line(aes(color=CharScenario),size=1.1,alpha=0.7) + 
#   scale_y_continuous(labels = scales::comma,limits = c(40,960)) + theme_bw()
# 
# windows(width = 9.2,height = 7.5)
# ggplot(ghg_MC_RR,aes(Year,TotGHG,group=UniqScen)) + geom_line(aes(color=StockScenario),size=1.1,alpha=0.7) + 
#   scale_y_continuous(labels = scales::comma,limits = c(40,960)) + theme_bw()
  
ghg_hi_lo<-GHGall[GHGall$ElecRen %in% c("MC_RR","CFE_ER"),]

windows(width = 9.2,height = 7.5)
ggplot(ghg_hi_lo,aes(Year,TotGHG,group=UniqScen)) + geom_line(aes(color=`New House Chars`),size=1.05,alpha=0.75) + 
  scale_y_continuous(labels = scales::comma,limits = c(0,960)) + theme_bw() + 
  scale_color_manual(values=c(brewer.pal(n = 8, name = "Paired")[c(2,4,6,8)])) +
  geom_segment(aes(x=2048,xend=2052,y=330,yend=330),linetype="dashed")+geom_text(x=2049, y=350, label="Paris 2050 Target") + geom_point(data=pdf,aes(x=xa,y=ya,group=1)) +
  geom_segment(aes(x=2028,xend=2032,y=450,yend=450),linetype="dashed")+geom_text(x=2030, y=430, label="1.5°C  Target") + geom_point(data=odf,aes(x=xa,y=ya,group=1)) +
  geom_segment(aes(x=2028,xend=2032,y=825,yend=825),linetype="dashed")+geom_text(x=2034, y=850, label="50% 2030  Target") + geom_point(data=hdf,aes(x=xa,y=ya,group=1)) +
  geom_segment(aes(x=2048,xend=2052,y=0,yend=0),linetype="dashed")+geom_text(x=2050, y=20, label="1.5°C  Target") + geom_point(data=zdf,aes(x=xa,y=ya,group=1)) +
  geom_label(x=2056,y=565,label="MC_RR") + geom_label(x=2056,y=184,label="CFE_ER") + 
  labs(title ="b) Annual Emissions by New Housing Characteristic Scenarios",y="Mton CO2e",subtitle = "     Selected Electricity and Renovation Scenarios (MC_RR, CFE_ER)") +
  theme(axis.text=element_text(size=11),axis.title=element_text(size=12,face = "bold"),plot.title = element_text(size = 12),legend.key.width = unit(1,'cm'))

windows(width = 9.2,height = 7.5)
ggplot(ghg_hi_lo,aes(Year,TotGHG,group=UniqScen)) + geom_line(aes(color=StockScenario),size=1.05,alpha=0.85) + 
  scale_y_continuous(labels = scales::comma,limits = c(0,960)) + theme_bw() + 
  scale_color_manual(values=c(brewer.pal(n = 8, name = "Set1")[c(3:5)])) +
  geom_segment(aes(x=2048,xend=2052,y=330,yend=330),linetype="dashed")+geom_text(x=2049, y=350, label="Paris 2050 Target") + geom_point(data=pdf,aes(x=xa,y=ya,group=1)) +
  geom_segment(aes(x=2028,xend=2032,y=450,yend=450),linetype="dashed")+geom_text(x=2030, y=430, label="1.5°C  Target") + geom_point(data=odf,aes(x=xa,y=ya,group=1)) +
  geom_segment(aes(x=2028,xend=2032,y=825,yend=825),linetype="dashed")+geom_text(x=2034, y=850, label="50% 2030  Target") + geom_point(data=hdf,aes(x=xa,y=ya,group=1)) +
  geom_segment(aes(x=2048,xend=2052,y=0,yend=0),linetype="dashed")+geom_text(x=2050, y=20, label="1.5°C  Target") + geom_point(data=zdf,aes(x=xa,y=ya,group=1)) +
  geom_label(x=2056,y=565,label="MC_RR") + geom_label(x=2056,y=184,label="CFE_ER") + 
  labs(title ="c) Annual Emissions by Housing Stock Evolution Scenarios",y="Mton CO2e",subtitle = "     Selected Electricity and Renovation Scenarios (MC_RR, CFE_ER)") +
  theme(axis.text=element_text(size=11),axis.title=element_text(size=12,face = "bold"),plot.title = element_text(size = 12),legend.key.width = unit(1,'cm'))

# try to improve the visual appeal of fig 2b,c
windows(width = 9.2,height = 7.5)
ggplot(ghg_hi_lo[ghg_hi_lo$Year>2039, ],aes(Year,TotGHG,group=UniqScen)) + geom_line(aes(color=`New House Chars`),size=1.05,alpha=1) + 
  scale_y_continuous(labels = scales::comma,limits = c(0,720)) + theme_bw() + 
  # scale_color_brewer(palette = "Dark2") +
  scale_color_manual(values=c('blue','red','limegreen','gray0')) +
  # scale_color_manual(values=c(brewer.pal(n = 8, name = "Dark2")[c(1,4,7,8)])) + 
  # scale_color_manual(values=c(brewer.pal(n = 8, name = "Paired")[c(2,4,6,8)])) +
  geom_segment(aes(x=2048,xend=2052,y=330,yend=330),linetype="dashed")+geom_text(x=2049, y=350, label="Paris 2050 Target") + geom_point(data=pdf,aes(x=xa,y=ya,group=1)) +
  # geom_segment(aes(x=2028,xend=2032,y=450,yend=450),linetype="dashed")+geom_text(x=2030, y=430, label="1.5°C  Target") + geom_point(data=odf,aes(x=xa,y=ya,group=1)) +
  # geom_segment(aes(x=2028,xend=2032,y=825,yend=825),linetype="dashed")+geom_text(x=2034, y=850, label="50% 2030  Target") + geom_point(data=hdf,aes(x=xa,y=ya,group=1)) +
  geom_segment(aes(x=2048,xend=2052,y=0,yend=0),linetype="dashed")+geom_text(x=2050, y=20, label="1.5°C  Target") + geom_point(data=zdf,aes(x=xa,y=ya,group=1)) +
  geom_label(x=2056,y=565,label="MC_RR") + geom_label(x=2056,y=184,label="CFE_ER") + 
  labs(title ="b) Annual Emissions by New Housing Characteristic Scenarios, 2040-2060",y="Mton CO2e",subtitle = "     Selected Electricity and Renovation Scenarios (MC_RR, CFE_ER)") +
  theme(axis.text=element_text(size=11),axis.title=element_text(size=12,face = "bold"),plot.title = element_text(size = 12),legend.key.width = unit(1,'cm'))


windows(width = 9.2,height = 7.5)
ggplot(ghg_hi_lo[ghg_hi_lo$Year>2039, ],aes(Year,TotGHG,group=UniqScen)) + geom_line(aes(color=StockScenario),size=1.05,alpha=1) + 
  scale_y_continuous(labels = scales::comma,limits = c(0,720)) + theme_bw() + 
  # scale_color_manual(values=c(brewer.pal(n = 8, name = "Set1")[c(3:5)])) +
  scale_color_manual(values=c('blue','red','limegreen')) +
  geom_segment(aes(x=2048,xend=2052,y=330,yend=330),linetype="dashed")+geom_text(x=2049, y=350, label="Paris 2050 Target") + geom_point(data=pdf,aes(x=xa,y=ya,group=1)) +
  # geom_segment(aes(x=2028,xend=2032,y=450,yend=450),linetype="dashed")+geom_text(x=2030, y=430, label="1.5°C  Target") + geom_point(data=odf,aes(x=xa,y=ya,group=1)) +
  # geom_segment(aes(x=2028,xend=2032,y=825,yend=825),linetype="dashed")+geom_text(x=2034, y=850, label="50% 2030  Target") + geom_point(data=hdf,aes(x=xa,y=ya,group=1)) +
  geom_segment(aes(x=2048,xend=2052,y=0,yend=0),linetype="dashed")+geom_text(x=2050, y=20, label="1.5°C  Target") + geom_point(data=zdf,aes(x=xa,y=ya,group=1)) +
  geom_label(x=2056,y=565,label="MC_RR") + geom_label(x=2056,y=184,label="CFE_ER") + 
  labs(title ="c) Annual Emissions by Housing Stock Evolution Scenarios, 2040-2060",y="Mton CO2e",subtitle = "     Selected Electricity and Renovation Scenarios (MC_RR, CFE_ER)") +
  theme(axis.text=element_text(size=11),axis.title=element_text(size=12,face = "bold"),plot.title = element_text(size = 12),legend.key.width = unit(1,'cm'))


# the following figures are now redundant, i deleted most, just keep one in comments for reference
# windows(width = 9.2,height = 7.5)
# ggplot(ghg_MC_RR,aes(Year,TotGHG,group=Housing_Scenario)) + geom_line(aes(color=CharScenario,linetype=StockScenario),size=1.1,alpha=0.7) + scale_y_continuous(labels = scales::comma,limits = c(250,1000)) +
#   geom_segment(aes(x=2048,xend=2052,y=330,yend=330),linetype="dashed") + geom_text(x=2050, y=310, label="Paris 2050 Target") + geom_point(data=pdf,aes(x=xa,y=ya,group=1)) +
#   geom_segment(aes(x=2028,xend=2032,y=450,yend=450),linetype="dashed") + geom_text(x=2030, y=430, label="1.5°C  Target") + geom_point(data=odf,aes(x=xa,y=ya,group=1)) +
#   geom_segment(aes(x=2028,xend=2032,y=808,yend=808),linetype="dashed") + geom_text(x=2023.5, y=788, label="49% 2030  Target") + geom_point(data=hdf,aes(x=xa,y=ya,group=1)) +
#   labs(title ="a) Mid-Case Electricity, Regular Renovation",y="Mton CO2e") + theme_bw() + 
#   # scale_color_brewer(palette="Set1")  + scale_linetype_manual(values=c("solid","dotted","dashed")) +
#   scale_color_manual(values=c('black','red','orange3','blue'))  + scale_linetype_manual(values=c("solid","dotted","dashed")) +
#   theme(axis.text=element_text(size=11),axis.title=element_text(size=12,face = "bold"),plot.title = element_text(size = 12),legend.key.width = unit(1,'cm'))


# just for the legend
# windows(width = 50,height =10)
# ggplot(ghg_LRE_AR,aes(Year,TotGHG,group=Housing_Scenario)) + geom_line(aes(color=CharScenario,linetype=StockScenario),size=1,alpha=0.65) + scale_y_continuous(labels = scales::comma,limits = c(250,1000)) +
#   geom_segment(aes(x=2048,xend=2052,y=330,yend=330),linetype="dashed") + geom_text(x=2050, y=310, label="Paris 2050 Target") + geom_point(data=pdf,aes(x=xa,y=ya,group=1)) +
#   geom_segment(aes(x=2028,xend=2032,y=450,yend=450),linetype="dashed") + geom_text(x=2030, y=430, label="1.5°C  Target") + geom_point(data=odf,aes(x=xa,y=ya,group=1)) +
#   labs(title ="a) Total annual residential GHG emissions, 2020-2060",y="Mton CO2e",subtitle = "Low RE Cost Electricity, Advanced Renovation") + theme_bw() + 
#   scale_color_manual(values=c('black','red','orange3','blue'))  + scale_linetype_manual(values=c("solid","dotted","dashed")) +
#   theme(axis.text=element_text(size=11),axis.title=element_text(size=12,face = "bold"),plot.title = element_text(size = 12, face = "bold"),
#         legend.key.width = unit(1,'cm'),legend.key.size = unit(1,'cm'),legend.key.height = unit(2,'cm'), legend.position = "bottom",legend.text =  element_text(size = 12),legend.title =  element_text(size = 12))


cum_emission<-tapply(GHGall$TotGHG,list(GHGall$Housing_Scenario,GHGall$RenScen,GHGall$ElecScen),sum)

summary(lm(GHGall$TotGHG~GHGall$ElecScen)) # 124 annually, 4.6Gt over 40 years

cem<-melt(cum_emission)
cem2<-cem[complete.cases(cem),]
write.csv(cem2,file="../Final_results/CumEmissions.csv",row.names = FALSE)

# now differenecs between cumulative emissions for a area or cascade chart

# GHG_base_NR[,c("Housing_Scenario","CharScenario","StockScenario")]<-rep(c("No Renovation","A. Base","1 Baseline"),each=41)
# GHG_base_NR_G20[,c("Housing_Scenario","CharScenario","StockScenario")]<-rep(c("No Ren., 2020 Elec Grid","A. Base","1 Baseline"),each=41)
# GHGall<-rbind(GHGall,GHG_base_NR,GHG_base_NR_G20)
GHGall[GHGall$RenScen=="NR" & GHGall$ElecScen=="MC",]$Housing_Scenario<-"No Renovation"
GHGall[GHGall$RenScen=="NR" & GHGall$ElecScen=="G20",]$Housing_Scenario<-"No Ren., 2020 Elec Grid"

# new ordering of strategies, including CFE35 
GHGdff<-rbind(GHGall[GHGall$StockScen==1&GHGall$CharScen=="A"&GHGall$ElecScen=="G20"&GHGall$RenScen=="NR",], # G20, no ren
              GHGall[GHGall$StockScen==1&GHGall$CharScen=="A"&GHGall$ElecScen=="MC"&GHGall$RenScen=="NR",], # Mid-Case Elec
              GHGall[GHGall$StockScen==1&GHGall$CharScen=="A"&GHGall$ElecScen=="MC"&GHGall$RenScen=="RR",], # Reg Ren
              GHGall[GHGall$StockScen==1&GHGall$CharScen=="A"&GHGall$ElecScen=="LREC"&GHGall$RenScen=="RR",], # LREC
              GHGall[GHGall$StockScen==1&GHGall$CharScen=="A"&GHGall$ElecScen=="CFE"&GHGall$RenScen=="RR",], # CFE
              GHGall[GHGall$StockScen==1&GHGall$CharScen=="A"&GHGall$ElecScen=="CFE"&GHGall$RenScen=="AR",], # AR
              GHGall[GHGall$StockScen==1&GHGall$CharScen=="A"&GHGall$ElecScen=="CFE"&GHGall$RenScen=="ER",], # ER
              GHGall[GHGall$StockScen==1&GHGall$CharScen=="C"&GHGall$ElecScen=="CFE"&GHGall$RenScen=="ER",], # IE
              GHGall[GHGall$StockScen==1&GHGall$CharScen=="D"&GHGall$ElecScen=="CFE"&GHGall$RenScen=="ER",], # IE RFA
              GHGall[GHGall$StockScen==3&GHGall$CharScen=="D"&GHGall$ElecScen=="CFE"&GHGall$RenScen=="ER",]) # hiMF
GHGdff$DiffGHG<-GHGdff$TotGHG

GHGdff[GHGdff$ElecScen=="G20"&GHGdff$RenScen=="NR"&GHGdff$CharScen=="A" & GHGdff$StockScen==1,]$DiffGHG<- # diff G20 and MC
  GHGdff[GHGdff$ElecScen=="G20"&GHGdff$RenScen=="NR"&GHGdff$CharScen=="A" & GHGdff$StockScen==1,]$DiffGHG-GHGdff[GHGdff$ElecScen=="MC"&GHGdff$RenScen=="NR"&GHGdff$CharScen=="A" & GHGdff$StockScen==1,]$DiffGHG
GHGdff[GHGdff$ElecScen=="MC"&GHGdff$RenScen=="NR"&GHGdff$CharScen=="A" & GHGdff$StockScen==1,]$DiffGHG<- # diff NR and RR
  GHGdff[GHGdff$ElecScen=="MC"&GHGdff$RenScen=="NR"&GHGdff$CharScen=="A" & GHGdff$StockScen==1,]$DiffGHG-GHGdff[GHGdff$ElecScen=="MC"&GHGdff$RenScen=="RR"&GHGdff$CharScen=="A" & GHGdff$StockScen==1,]$DiffGHG
GHGdff[GHGdff$ElecScen=="MC"&GHGdff$RenScen=="RR"&GHGdff$CharScen=="A" & GHGdff$StockScen==1,]$DiffGHG<- # diff between MC and LREC
  GHGdff[GHGdff$ElecScen=="MC"&GHGdff$RenScen=="RR"&GHGdff$CharScen=="A" & GHGdff$StockScen==1,]$DiffGHG-GHGdff[GHGdff$ElecScen=="LREC"&GHGdff$RenScen=="RR"&GHGdff$CharScen=="A" & GHGdff$StockScen==1,]$DiffGHG
GHGdff[GHGdff$ElecScen=="LREC"&GHGdff$RenScen=="RR"&GHGdff$CharScen=="A" & GHGdff$StockScen==1,]$DiffGHG<- # diff between CFE and CFE
  GHGdff[GHGdff$ElecScen=="LREC"&GHGdff$RenScen=="RR"&GHGdff$CharScen=="A" & GHGdff$StockScen==1,]$DiffGHG-GHGdff[GHGdff$ElecScen=="CFE"&GHGdff$RenScen=="RR"&GHGdff$CharScen=="A" & GHGdff$StockScen==1,]$DiffGHG
GHGdff[GHGdff$ElecScen=="CFE"&GHGdff$RenScen=="RR"&GHGdff$CharScen=="A" & GHGdff$StockScen==1,]$DiffGHG<- # diff between RR and AR
  GHGdff[GHGdff$ElecScen=="CFE"&GHGdff$RenScen=="RR"&GHGdff$CharScen=="A" & GHGdff$StockScen==1,]$DiffGHG-GHGdff[GHGdff$ElecScen=="CFE"&GHGdff$RenScen=="AR"&GHGdff$CharScen=="A" & GHGdff$StockScen==1,]$DiffGHG
GHGdff[GHGdff$ElecScen=="CFE"&GHGdff$RenScen=="AR"&GHGdff$CharScen=="A" & GHGdff$StockScen==1,]$DiffGHG<- # diff between AR and ER
  GHGdff[GHGdff$ElecScen=="CFE"&GHGdff$RenScen=="AR"&GHGdff$CharScen=="A" & GHGdff$StockScen==1,]$DiffGHG-GHGdff[GHGdff$ElecScen=="CFE"&GHGdff$RenScen=="ER"&GHGdff$CharScen=="A" & GHGdff$StockScen==1,]$DiffGHG
GHGdff[GHGdff$ElecScen=="CFE"&GHGdff$RenScen=="ER"&GHGdff$CharScen=="A" & GHGdff$StockScen==1,]$DiffGHG<- # diff between BaseChar and IE
  GHGdff[GHGdff$ElecScen=="CFE"&GHGdff$RenScen=="ER"&GHGdff$CharScen=="A" & GHGdff$StockScen==1,]$DiffGHG-GHGdff[GHGdff$ElecScen=="CFE"&GHGdff$RenScen=="ER"&GHGdff$CharScen=="C" & GHGdff$StockScen==1,]$DiffGHG
GHGdff[GHGdff$ElecScen=="CFE"&GHGdff$RenScen=="ER"&GHGdff$CharScen=="C" & GHGdff$StockScen==1,]$DiffGHG<- # diff between IE and IE RFA
  GHGdff[GHGdff$ElecScen=="CFE"&GHGdff$RenScen=="ER"&GHGdff$CharScen=="C" & GHGdff$StockScen==1,]$DiffGHG-GHGdff[GHGdff$ElecScen=="CFE"&GHGdff$RenScen=="ER"&GHGdff$CharScen=="D" & GHGdff$StockScen==1,]$DiffGHG
GHGdff[GHGdff$ElecScen=="CFE"&GHGdff$RenScen=="ER"&GHGdff$CharScen=="D" & GHGdff$StockScen==1,]$DiffGHG<- # diff between Baseline Stock and hiMF
  GHGdff[GHGdff$ElecScen=="CFE"&GHGdff$RenScen=="ER"&GHGdff$CharScen=="D" & GHGdff$StockScen==1,]$DiffGHG-GHGdff[GHGdff$ElecScen=="CFE"&GHGdff$RenScen=="ER"&GHGdff$CharScen=="D" & GHGdff$StockScen==3,]$DiffGHG

# GHGdff[GHGdff$ElecScen=="LREC"&GHGdff$RenScen=="RR",]$DiffGHG<-GHGdff[GHGdff$ElecScen=="LREC"&GHGdff$RenScen=="RR",]$TotGHG-GHGdff[GHGdff$ElecScen=="LREC"&GHGdff$RenScen=="AR",]$TotGHG

GHGdff$Strategy<-"8. Residual Emissions" # Emissions in the most optimistic case.
GHGdff[GHGdff$ElecScen=="G20"&GHGdff$RenScen=="NR"&GHGdff$CharScen=="A" & GHGdff$StockScen==1,]$Strategy<-"0. Mid-Case Electricity Supply" #  the differences between No Ren and Reg Ren
GHGdff[GHGdff$ElecScen=="MC"&GHGdff$RenScen=="NR"&GHGdff$CharScen=="A" & GHGdff$StockScen==1,]$Strategy<-"0. Reg. Renovation" #  the differences between No Ren and Reg Ren
GHGdff[GHGdff$ElecScen=="MC"&GHGdff$RenScen=="RR"&GHGdff$CharScen=="A" & GHGdff$StockScen==1,]$Strategy<-"1. LREC Electricity Supply" #  the differences between MC Elec and LREC elec
GHGdff[GHGdff$ElecScen=="LREC"&GHGdff$RenScen=="RR"&GHGdff$CharScen=="A" & GHGdff$StockScen==1,]$Strategy<-"2. CFE35 Electricity Supply" #  the differences between ;REC Elec and CFE35   elec
GHGdff[GHGdff$ElecScen=="CFE"&GHGdff$RenScen=="RR"&GHGdff$CharScen=="A" & GHGdff$StockScen==1,]$Strategy<-"3. Adv. Renovation & Electrification" # the difference between CFE RR, and CFE AR
GHGdff[GHGdff$ElecScen=="CFE"&GHGdff$RenScen=="AR"&GHGdff$CharScen=="A" & GHGdff$StockScen==1,]$Strategy<-"4. Ext. Renovation & Electrification" # the difference between CFE AR, and CFE ER
GHGdff[GHGdff$ElecScen=="CFE"&GHGdff$RenScen=="ER"&GHGdff$CharScen=="A" & GHGdff$StockScen==1,]$Strategy<-"5. Increased Electrification (NHC)" # the difference between CFE ER, and CFE ER IE
GHGdff[GHGdff$ElecScen=="CFE"&GHGdff$RenScen=="ER"&GHGdff$CharScen=="C" & GHGdff$StockScen==1,]$Strategy<-"6. Reduced Floor Area (NHC)" # the difference between CFE ER IE, and CFE ER IERFA
GHGdff[GHGdff$ElecScen=="CFE"&GHGdff$RenScen=="ER"&GHGdff$CharScen=="D" & GHGdff$StockScen==1,]$Strategy<-"7. High Multifamily (HSE)" # the difference between CFE ER IERFA, and CFE ER IERFA hi MF

# windows(width = 7.5,height = 5.5)
# ggplot(GHGdff,aes(Year,DiffGHG,fill=Strategy))+geom_area() + scale_y_continuous(breaks = seq(0,1200,200)) +
#   labs(title ="GHG reduction potential by sequential strategy adoption",y="Mton CO2e") + theme_bw() + 
#   scale_fill_brewer(palette="Paired")  +
#   theme(axis.text=element_text(size=11),axis.title=element_text(size=12, face = "bold"),plot.title = element_text(size = 12, face = "bold"),
#         legend.key.width = unit(1,'cm'),legend.text =  element_text(size = 10))

# add lines for particular scenarios
# GHG_base_NR$Housing_Scenario<-"No Renovation"
# GHG_base_NR_G20$Housing_Scenario<-"No Renovation, No Decarbonization"

GHGln<-rbind(GHGall[GHGall$StockScen==1&GHGall$CharScen=="A"&GHGall$ElecScen=="MC"&GHGall$RenScen=="RR",], # reg ren, mc grid
             GHGall[GHGall$StockScen==3&GHGall$CharScen=="D"&GHGall$ElecScen=="CFE"&GHGall$RenScen=="ER",], # hi MF, IERFA, CFE grid, ext ren
             GHGall[GHGall$StockScen==1&GHGall$CharScen=="A"&GHGall$ElecScen=="G20"&GHGall$RenScen=="NR",]) # no ren, 2020 grid
GHGln$Scenario<-GHGln$Housing_Scenario
GHGln[GHGln$Housing_Scenario=="1A Baseline",]$Scenario<-"1A Baseline, RR, Mid-Case Elec"
GHGln[GHGln$Housing_Scenario=="3D High Multifamily IE & RFA",]$Scenario<-"3D High MF IE & RFA, ER, CFE Elec"
GHGln[GHGln$Housing_Scenario=="No Ren., 2020 Elec Grid",]$Scenario<-"1A Baseline, NR, 2020 Elec"

bop<-c("#2171B5","#9ECAE1","#D94801","#FD8D3C","#7A0177","#DD3497","#FA9FB5")
# colarea<-c("#D5D6DE","8D8E91",bop,"#FFFFFF")
colarea<-c("#D5D6DE","8D8E91",bop,"#F5F5DC")
colln<-colorRampPalette(brewer.pal(4,"Set1"))(2)
colln<-c('tan4','black','blue')
windows(width = 9,height = 6.2)
ggplot() + geom_area(data=GHGdff,aes(Year,DiffGHG,fill=Strategy)) + geom_line(data=GHGln,aes(Year,TotGHG,color=Scenario),size=1,linetype="longdash") + scale_y_continuous(breaks = seq(0,1200,200),limits = c(0,1000)) +
  labs(title ="a) GHG reduction potential by sequential strategy adoption",y="Mton CO2e",subtitle = "Strategy Group Order: Grid, Renovation, New Housing Chars/Stock Evolution") + theme_classic() + 
  scale_fill_manual(values=colarea)  + scale_color_manual(values=colln) +
  theme(axis.text=element_text(size=11),axis.title=element_text(size=12, face = "bold"),plot.title = element_text(size = 12),
        legend.key.width = unit(1,'cm'),legend.text =  element_text(size = 10)) + guides(linetype=guide_legend(order=1),color=guide_legend(order=2))

# now with target lables
windows(width = 9,height = 6.2)
ggplot() + geom_area(data=GHGdff,aes(Year,DiffGHG,fill=Strategy)) + 
  geom_line(data=GHGln,aes(Year,TotGHG,color=Scenario),size=1,linetype="longdash") + scale_y_continuous(breaks = seq(0,1200,200),limits = c(0,1000)) +
  geom_segment(aes(x=2048,xend=2052,y=330,yend=330),linetype="dashed")+geom_text(aes(x=2049, y=310, label="Paris 2050 Target")) + geom_point(data=pdf,aes(x=xa,y=ya,group=1)) +
  geom_segment(aes(x=2048,xend=2052,y=0,yend=0),linetype="dashed")+geom_text(aes(x=2050, y=20, label="1.5°C  Target")) + geom_point(data=zdf,aes(x=xa,y=ya,group=1)) +
  labs(title ="a) GHG reduction potential by sequential strategy adoption",y="Mton CO2e",subtitle = "Strategy Group Order: Grid, Renovation, New Housing Chars/Stock Evolution") + theme_classic() + 
  scale_fill_manual(values=colarea)  + scale_color_manual(values=colln) +
  theme(axis.text=element_text(size=11),axis.title=element_text(size=12, face = "bold"),plot.title = element_text(size = 12),
        legend.key.width = unit(1,'cm'),legend.text =  element_text(size = 10)) + guides(linetype=guide_legend(order=1),color=guide_legend(order=2))

# repeat Fig 3 with different order
# new ordering of strategies, including CFE35 
GHGdff2<-rbind(GHGall[GHGall$StockScen==1&GHGall$CharScen=="A"&GHGall$ElecScen=="G20"&GHGall$RenScen=="NR",], # G20, no ren
              GHGall[GHGall$StockScen==1&GHGall$CharScen=="A"&GHGall$ElecScen=="MC"&GHGall$RenScen=="NR",], # Mid-Case Elec
              GHGall[GHGall$StockScen==1&GHGall$CharScen=="A"&GHGall$ElecScen=="MC"&GHGall$RenScen=="RR",], # Reg Ren
              GHGall[GHGall$StockScen==1&GHGall$CharScen=="B"&GHGall$ElecScen=="MC"&GHGall$RenScen=="RR",], # RFA
              GHGall[GHGall$StockScen==3&GHGall$CharScen=="B"&GHGall$ElecScen=="MC"&GHGall$RenScen=="RR",], # hiMF
              GHGall[GHGall$StockScen==3&GHGall$CharScen=="D"&GHGall$ElecScen=="MC"&GHGall$RenScen=="RR",], # IE
              GHGall[GHGall$StockScen==3&GHGall$CharScen=="D"&GHGall$ElecScen=="MC"&GHGall$RenScen=="AR",], # AR
              GHGall[GHGall$StockScen==3&GHGall$CharScen=="D"&GHGall$ElecScen=="MC"&GHGall$RenScen=="ER",], # ER
              GHGall[GHGall$StockScen==3&GHGall$CharScen=="D"&GHGall$ElecScen=="LREC"&GHGall$RenScen=="ER",], # LREC
              GHGall[GHGall$StockScen==3&GHGall$CharScen=="D"&GHGall$ElecScen=="CFE"&GHGall$RenScen=="ER",]) # CFE
GHGdff2$DiffGHG<-GHGdff2$TotGHG

GHGdff2[GHGdff2$ElecScen=="G20"&GHGdff2$RenScen=="NR"&GHGdff2$CharScen=="A" & GHGdff2$StockScen==1,]$DiffGHG<- # diff G20 and MC
  GHGdff2[GHGdff2$ElecScen=="G20"&GHGdff2$RenScen=="NR"&GHGdff2$CharScen=="A" & GHGdff2$StockScen==1,]$DiffGHG-GHGdff2[GHGdff2$ElecScen=="MC"&GHGdff2$RenScen=="NR"&GHGdff2$CharScen=="A" & GHGdff2$StockScen==1,]$DiffGHG
GHGdff2[GHGdff2$ElecScen=="MC"&GHGdff2$RenScen=="NR"&GHGdff2$CharScen=="A" & GHGdff2$StockScen==1,]$DiffGHG<- # diff NR and RR
  GHGdff2[GHGdff2$ElecScen=="MC"&GHGdff2$RenScen=="NR"&GHGdff2$CharScen=="A" & GHGdff2$StockScen==1,]$DiffGHG-GHGdff2[GHGdff2$ElecScen=="MC"&GHGdff2$RenScen=="RR"&GHGdff2$CharScen=="A" & GHGdff2$StockScen==1,]$DiffGHG
GHGdff2[GHGdff2$ElecScen=="MC"&GHGdff2$RenScen=="RR"&GHGdff2$CharScen=="A" & GHGdff2$StockScen==1,]$DiffGHG<- # diff between Base and RFA
  GHGdff2[GHGdff2$ElecScen=="MC"&GHGdff2$RenScen=="RR"&GHGdff2$CharScen=="A" & GHGdff2$StockScen==1,]$DiffGHG-GHGdff2[GHGdff2$ElecScen=="MC"&GHGdff2$RenScen=="RR"&GHGdff2$CharScen=="B" & GHGdff2$StockScen==1,]$DiffGHG
GHGdff2[GHGdff2$ElecScen=="MC"&GHGdff2$RenScen=="RR"&GHGdff2$CharScen=="B" & GHGdff2$StockScen==1,]$DiffGHG<- # diff between RFA and RFA hiMF
  GHGdff2[GHGdff2$ElecScen=="MC"&GHGdff2$RenScen=="RR"&GHGdff2$CharScen=="B" & GHGdff2$StockScen==1,]$DiffGHG-GHGdff2[GHGdff2$ElecScen=="MC"&GHGdff2$RenScen=="RR"&GHGdff2$CharScen=="B" & GHGdff2$StockScen==3,]$DiffGHG
GHGdff2[GHGdff2$ElecScen=="MC"&GHGdff2$RenScen=="RR"&GHGdff2$CharScen=="B" & GHGdff2$StockScen==3,]$DiffGHG<- # diff between RFA hiMF and IERFA hi MF
  GHGdff2[GHGdff2$ElecScen=="MC"&GHGdff2$RenScen=="RR"&GHGdff2$CharScen=="B" & GHGdff2$StockScen==3,]$DiffGHG-GHGdff2[GHGdff2$ElecScen=="MC"&GHGdff2$RenScen=="RR"&GHGdff2$CharScen=="D" & GHGdff2$StockScen==3,]$DiffGHG
GHGdff2[GHGdff2$ElecScen=="MC"&GHGdff2$RenScen=="RR"&GHGdff2$CharScen=="D" & GHGdff2$StockScen==3,]$DiffGHG<- # diff between RR and AR
  GHGdff2[GHGdff2$ElecScen=="MC"&GHGdff2$RenScen=="RR"&GHGdff2$CharScen=="D" & GHGdff2$StockScen==3,]$DiffGHG-GHGdff2[GHGdff2$ElecScen=="MC"&GHGdff2$RenScen=="AR"&GHGdff2$CharScen=="D" & GHGdff2$StockScen==3,]$DiffGHG
GHGdff2[GHGdff2$ElecScen=="MC"&GHGdff2$RenScen=="AR"&GHGdff2$CharScen=="D" & GHGdff2$StockScen==3,]$DiffGHG<- # diff between AR and ER
  GHGdff2[GHGdff2$ElecScen=="MC"&GHGdff2$RenScen=="AR"&GHGdff2$CharScen=="D" & GHGdff2$StockScen==3,]$DiffGHG-GHGdff2[GHGdff2$ElecScen=="MC"&GHGdff2$RenScen=="ER"&GHGdff2$CharScen=="D" & GHGdff2$StockScen==3,]$DiffGHG
GHGdff2[GHGdff2$ElecScen=="MC"&GHGdff2$RenScen=="ER"&GHGdff2$CharScen=="D" & GHGdff2$StockScen==3,]$DiffGHG<- # diff between MC and LREC
  GHGdff2[GHGdff2$ElecScen=="MC"&GHGdff2$RenScen=="ER"&GHGdff2$CharScen=="D" & GHGdff2$StockScen==3,]$DiffGHG-GHGdff2[GHGdff2$ElecScen=="LREC"&GHGdff2$RenScen=="ER"&GHGdff2$CharScen=="D" & GHGdff2$StockScen==3,]$DiffGHG
GHGdff2[GHGdff2$ElecScen=="LREC"&GHGdff2$RenScen=="ER"&GHGdff2$CharScen=="D" & GHGdff2$StockScen==3,]$DiffGHG<- # diff between LREC and CFE
  GHGdff2[GHGdff2$ElecScen=="LREC"&GHGdff2$RenScen=="ER"&GHGdff2$CharScen=="D" & GHGdff2$StockScen==3,]$DiffGHG-GHGdff2[GHGdff2$ElecScen=="CFE"&GHGdff2$RenScen=="ER"&GHGdff2$CharScen=="D" & GHGdff2$StockScen==3,]$DiffGHG

GHGdff2$Strategy<-"8. Residual Emissions" # Emissions in the most optimistic case.
GHGdff2[GHGdff2$ElecScen=="G20"&GHGdff2$RenScen=="NR"&GHGdff2$CharScen=="A" & GHGdff2$StockScen==1,]$Strategy<-"0. Mid-Case Electricity Supply" #  the differences between No Ren and Reg Ren
GHGdff2[GHGdff2$ElecScen=="MC"&GHGdff2$RenScen=="NR"&GHGdff2$CharScen=="A" & GHGdff2$StockScen==1,]$Strategy<-"0. Reg. Renovation" #  the differences between No Ren and Reg Ren
GHGdff2[GHGdff2$ElecScen=="MC"&GHGdff2$RenScen=="RR"&GHGdff2$CharScen=="A" & GHGdff2$StockScen==1,]$Strategy<-"1. Reduced Floor Area (NHC)" #  the differences between MC Elec and LREC elec
GHGdff2[GHGdff2$ElecScen=="MC"&GHGdff2$RenScen=="RR"&GHGdff2$CharScen=="B" & GHGdff2$StockScen==1,]$Strategy<-"2. High Multifamily (HSE)" #  the differences between ;REC Elec and CFE35   elec
GHGdff2[GHGdff2$ElecScen=="MC"&GHGdff2$RenScen=="RR"&GHGdff2$CharScen=="B" & GHGdff2$StockScen==3,]$Strategy<-"3. Increased Electrification (NHC)" # the difference between CFE RR, and CFE AR
GHGdff2[GHGdff2$ElecScen=="MC"&GHGdff2$RenScen=="RR"&GHGdff2$CharScen=="D" & GHGdff2$StockScen==3,]$Strategy<-"4. Adv. Renovation & Electrification" # the difference between CFE AR, and CFE ER
GHGdff2[GHGdff2$ElecScen=="MC"&GHGdff2$RenScen=="AR"&GHGdff2$CharScen=="D" & GHGdff2$StockScen==3,]$Strategy<-"5. Ext. Renovation & Electrification" # the difference between CFE ER, and CFE ER IE
GHGdff2[GHGdff2$ElecScen=="MC"&GHGdff2$RenScen=="ER"&GHGdff2$CharScen=="D" & GHGdff2$StockScen==3,]$Strategy<-"6. LREC Electricity Supply" # the difference between CFE ER IE, and CFE ER IERFA
GHGdff2[GHGdff2$ElecScen=="LREC"&GHGdff2$RenScen=="ER"&GHGdff2$CharScen=="D" & GHGdff2$StockScen==3,]$Strategy<-"7. CFE35 Electricity Supply" # the difference between CFE ER IERFA, and CFE ER IERFA hi MF

pob<-c("#DD3497","#FA9FB5","#7A0177","#D94801","#FD8D3C","#2171B5","#9ECAE1")
colarea<-c("#D5D6DE","8D8E91",pob,"#F5F5DC")
colln<-colorRampPalette(brewer.pal(4,"Set1"))(2)
colln<-c('tan4','black','blue')
windows(width = 9,height = 6.2)
ggplot() + geom_area(data=GHGdff2,aes(Year,DiffGHG,fill=Strategy)) + geom_line(data=GHGln,aes(Year,TotGHG,color=Scenario),size=1,linetype="longdash") + scale_y_continuous(breaks = seq(0,1200,200),limits = c(0,1000)) +
  labs(title ="b) GHG reduction potential by sequential strategy adoption",y="Mton CO2e",subtitle = "Strategy Group Order: New Housing Chars/Stock Evolution, Renovation, Grid") + theme_classic() + 
  scale_fill_manual(values=colarea)  + scale_color_manual(values=colln) +
  theme(axis.text=element_text(size=11),axis.title=element_text(size=12, face = "bold"),plot.title = element_text(size = 12),
        legend.key.width = unit(1,'cm'),legend.text =  element_text(size = 10)) + guides(linetype=guide_legend(order=1),color=guide_legend(order=2))

windows(width = 9,height = 6.2)
ggplot() + geom_area(data=GHGdff2,aes(Year,DiffGHG,fill=Strategy)) + 
  geom_line(data=GHGln,aes(Year,TotGHG,color=Scenario),size=1,linetype="longdash") + scale_y_continuous(breaks = seq(0,1200,200),limits = c(0,1000)) +
  geom_segment(aes(x=2048,xend=2052,y=330,yend=330),linetype="dashed")+geom_text(aes(x=2049, y=310, label="Paris 2050 Target")) + geom_point(data=pdf,aes(x=xa,y=ya,group=1)) +
  geom_segment(aes(x=2048,xend=2052,y=0,yend=0),linetype="dashed")+geom_text(aes(x=2050, y=20, label="1.5°C  Target")) + geom_point(data=zdf,aes(x=xa,y=ya,group=1)) +
  labs(title ="b) GHG reduction potential by sequential strategy adoption",y="Mton CO2e",subtitle = "Strategy Group Order: New Housing Chars/Stock Evolution, Renovation, Grid") + theme_classic() + 
  scale_fill_manual(values=colarea)  + scale_color_manual(values=colln) +
  theme(axis.text=element_text(size=11),axis.title=element_text(size=12, face = "bold"),plot.title = element_text(size = 12),
        legend.key.width = unit(1,'cm'),legend.text =  element_text(size = 10)) + guides(linetype=guide_legend(order=1),color=guide_legend(order=2))



# Emissions from construction, and fuel use in new and old construction, Fig 3 #########
# 1
# g_base_RR<-melt(GHG_base_RR[,-c(2,8,15:20)],id.vars = c("Year","StockScen","CharScen","RenScen","ElecScen"))
g_base_RR<-melt(GHG_base_RR[,c("Year","StockScen","CharScen","RenScen","ElecScen","EmGHG","RenGHG","OldOilGHG","NewOilGHG","OldGasGHG","NewGasGHG","OldElecGHG","NewElecGHG")],id.vars = c("Year","StockScen","CharScen","RenScen","ElecScen"))
names(g_base_RR)[6:7]<-c("Var","GHG")
g_base_RR$Source<-g_base_RR$Var
levels(g_base_RR$Source)<-list("Emb. Constr." = "EmGHG","Emb. Renov." = "RenGHG","Oil <2020"="OldOilGHG","Oil >2020" = "NewOilGHG",
                               "Gas <2020"="OldGasGHG","Gas >2020" = "NewGasGHG",
                               "Elec <2020"="OldElecGHG","Elec >2020" = "NewElecGHG")
g_base_RR$Source<-factor(g_base_RR$Source,levels=rev(levels(g_base_RR$Source)))
# 2a
# g_base_RR_LREC<-melt(GHG_base_RR_LREC[,-c(2,8,15:20)],id.vars = c("Year","StockScen","CharScen","RenScen","ElecScen"))
g_base_RR_LREC<-melt(GHG_base_RR_LREC[,c("Year","StockScen","CharScen","RenScen","ElecScen","EmGHG","RenGHG","OldOilGHG","NewOilGHG","OldGasGHG","NewGasGHG","OldElecGHG","NewElecGHG")],id.vars = c("Year","StockScen","CharScen","RenScen","ElecScen"))
names(g_base_RR_LREC)[6:7]<-c("Var","GHG")
g_base_RR_LREC$Source<-g_base_RR_LREC$Var
levels(g_base_RR_LREC$Source)<-list("Emb. Constr." = "EmGHG","Emb. Renov." = "RenGHG","Oil <2020"="OldOilGHG","Oil >2020" = "NewOilGHG",
                               "Gas <2020"="OldGasGHG","Gas >2020" = "NewGasGHG",
                               "Elec <2020"="OldElecGHG","Elec >2020" = "NewElecGHG")
g_base_RR_LREC$Source<-factor(g_base_RR_LREC$Source,levels=rev(levels(g_base_RR_LREC$Source)))
# 2b
# g_base_RR_CFE<-melt(GHG_base_RR_CFE[,-c(2,8,15:20)],id.vars = c("Year","StockScen","CharScen","RenScen","ElecScen"))
g_base_RR_CFE<-melt(GHG_base_RR_CFE[,c("Year","StockScen","CharScen","RenScen","ElecScen","EmGHG","RenGHG","OldOilGHG","NewOilGHG","OldGasGHG","NewGasGHG","OldElecGHG","NewElecGHG")],id.vars = c("Year","StockScen","CharScen","RenScen","ElecScen"))
names(g_base_RR_CFE)[6:7]<-c("Var","GHG")
g_base_RR_CFE$Source<-g_base_RR_CFE$Var
levels(g_base_RR_CFE$Source)<-list("Emb. Constr." = "EmGHG","Emb. Renov." = "RenGHG","Oil <2020"="OldOilGHG","Oil >2020" = "NewOilGHG",
                                    "Gas <2020"="OldGasGHG","Gas >2020" = "NewGasGHG",
                                    "Elec <2020"="OldElecGHG","Elec >2020" = "NewElecGHG")
g_base_RR_CFE$Source<-factor(g_base_RR_CFE$Source,levels=rev(levels(g_base_RR_CFE$Source)))

# 3
# g_base_ER<-melt(GHG_base_ER[,-c(2,8,15:20)],id.vars = c("Year","StockScen","CharScen","RenScen","ElecScen"))
g_base_ER<-melt(GHG_base_ER[,c("Year","StockScen","CharScen","RenScen","ElecScen","EmGHG","RenGHG","OldOilGHG","NewOilGHG","OldGasGHG","NewGasGHG","OldElecGHG","NewElecGHG")],id.vars = c("Year","StockScen","CharScen","RenScen","ElecScen"))
names(g_base_ER)[6:7]<-c("Var","GHG")
g_base_ER$Source<-g_base_ER$Var
levels(g_base_ER$Source)<-list("Emb. Constr." = "EmGHG","Emb. Renov." = "RenGHG","Oil <2020"="OldOilGHG","Oil >2020" = "NewOilGHG",
                               "Gas <2020"="OldGasGHG","Gas >2020" = "NewGasGHG",
                               "Elec <2020"="OldElecGHG","Elec >2020" = "NewElecGHG")
g_base_ER$Source<-factor(g_base_ER$Source,levels=rev(levels(g_base_ER$Source)))

# 4a
# g_base_ER_LREC<-melt(GHG_base_ER_LREC[,-c(2,8,15:20)],id.vars = c("Year","StockScen","CharScen","RenScen","ElecScen"))
g_base_ER_LREC<-melt(GHG_base_ER_LREC[,c("Year","StockScen","CharScen","RenScen","ElecScen","EmGHG","RenGHG","OldOilGHG","NewOilGHG","OldGasGHG","NewGasGHG","OldElecGHG","NewElecGHG")],id.vars = c("Year","StockScen","CharScen","RenScen","ElecScen"))
names(g_base_ER_LREC)[6:7]<-c("Var","GHG")
g_base_ER_LREC$Source<-g_base_ER_LREC$Var
levels(g_base_ER_LREC$Source)<-list("Emb. Constr." = "EmGHG","Emb. Renov." = "RenGHG","Oil <2020"="OldOilGHG","Oil >2020" = "NewOilGHG",
                               "Gas <2020"="OldGasGHG","Gas >2020" = "NewGasGHG",
                               "Elec <2020"="OldElecGHG","Elec >2020" = "NewElecGHG")
g_base_ER_LREC$Source<-factor(g_base_ER_LREC$Source,levels=rev(levels(g_base_ER_LREC$Source)))

# 4b
# g_base_ER_CFE<-melt(GHG_base_ER_CFE[,-c(2,8,15:20)],id.vars = c("Year","StockScen","CharScen","RenScen","ElecScen"))
g_base_ER_CFE<-melt(GHG_base_ER_CFE[,c("Year","StockScen","CharScen","RenScen","ElecScen","EmGHG","RenGHG","OldOilGHG","NewOilGHG","OldGasGHG","NewGasGHG","OldElecGHG","NewElecGHG")],id.vars = c("Year","StockScen","CharScen","RenScen","ElecScen"))
names(g_base_ER_CFE)[6:7]<-c("Var","GHG")
g_base_ER_CFE$Source<-g_base_ER_CFE$Var
levels(g_base_ER_CFE$Source)<-list("Emb. Constr." = "EmGHG","Emb. Renov." = "RenGHG","Oil <2020"="OldOilGHG","Oil >2020" = "NewOilGHG",
                                    "Gas <2020"="OldGasGHG","Gas >2020" = "NewGasGHG",
                                    "Elec <2020"="OldElecGHG","Elec >2020" = "NewElecGHG")
g_base_ER_CFE$Source<-factor(g_base_ER_CFE$Source,levels=rev(levels(g_base_ER_CFE$Source)))

# 5a
# g_hiDRDERFA_ER_LREC<-melt(GHG_hiDRDERFA_ER_LREC[,-c(2,8,15:20)],id.vars = c("Year","StockScen","CharScen","RenScen","ElecScen"))
g_hiDRDERFA_ER_LREC<-melt(GHG_hiDRDERFA_ER_LREC[,c("Year","StockScen","CharScen","RenScen","ElecScen","EmGHG","RenGHG","OldOilGHG","NewOilGHG","OldGasGHG","NewGasGHG","OldElecGHG","NewElecGHG")],id.vars = c("Year","StockScen","CharScen","RenScen","ElecScen"))
names(g_hiDRDERFA_ER_LREC)[6:7]<-c("Var","GHG")
g_hiDRDERFA_ER_LREC$Source<-g_hiDRDERFA_ER_LREC$Var
levels(g_hiDRDERFA_ER_LREC$Source)<-list("Emb. Constr." = "EmGHG","Emb. Renov." = "RenGHG","Oil <2020"="OldOilGHG","Oil >2020" = "NewOilGHG",
                                         "Gas <2020"="OldGasGHG","Gas >2020" = "NewGasGHG",
                                         "Elec <2020"="OldElecGHG","Elec >2020" = "NewElecGHG")
g_hiDRDERFA_ER_LREC$Source<-factor(g_hiDRDERFA_ER_LREC$Source,levels=rev(levels(g_hiDRDERFA_ER_LREC$Source)))
# 5b
# g_hiDRDERFA_ER_CFE<-melt(GHG_hiDRDERFA_ER_CFE[,-c(2,8,15:20)],id.vars = c("Year","StockScen","CharScen","RenScen","ElecScen"))
g_hiDRDERFA_ER_CFE<-melt(GHG_hiDRDERFA_ER_CFE[,c("Year","StockScen","CharScen","RenScen","ElecScen","EmGHG","RenGHG","OldOilGHG","NewOilGHG","OldGasGHG","NewGasGHG","OldElecGHG","NewElecGHG")],id.vars = c("Year","StockScen","CharScen","RenScen","ElecScen"))
names(g_hiDRDERFA_ER_CFE)[6:7]<-c("Var","GHG")
g_hiDRDERFA_ER_CFE$Source<-g_hiDRDERFA_ER_CFE$Var
levels(g_hiDRDERFA_ER_CFE$Source)<-list("Emb. Constr." = "EmGHG","Emb. Renov." = "RenGHG","Oil <2020"="OldOilGHG","Oil >2020" = "NewOilGHG",
                                        "Gas <2020"="OldGasGHG","Gas >2020" = "NewGasGHG",
                                        "Elec <2020"="OldElecGHG","Elec >2020" = "NewElecGHG")
g_hiDRDERFA_ER_CFE$Source<-factor(g_hiDRDERFA_ER_CFE$Source,levels=rev(levels(g_hiDRDERFA_ER_CFE$Source)))

# 6a
# g_hiMFDERFA_ER_LREC<-melt(GHG_hiMFDERFA_ER_LREC[,-c(2,8,15:20)],id.vars = c("Year","StockScen","CharScen","RenScen","ElecScen"))
g_hiMFDERFA_ER_LREC<-melt(GHG_hiMFDERFA_ER_LREC[,c("Year","StockScen","CharScen","RenScen","ElecScen","EmGHG","RenGHG","OldOilGHG","NewOilGHG","OldGasGHG","NewGasGHG","OldElecGHG","NewElecGHG")],id.vars = c("Year","StockScen","CharScen","RenScen","ElecScen"))
names(g_hiMFDERFA_ER_LREC)[6:7]<-c("Var","GHG")
g_hiMFDERFA_ER_LREC$Source<-g_hiMFDERFA_ER_LREC$Var
levels(g_hiMFDERFA_ER_LREC$Source)<-list("Emb. Constr." = "EmGHG","Emb. Renov." = "RenGHG","Oil <2020"="OldOilGHG","Oil >2020" = "NewOilGHG",
                                         "Gas <2020"="OldGasGHG","Gas >2020" = "NewGasGHG",
                                         "Elec <2020"="OldElecGHG","Elec >2020" = "NewElecGHG")
g_hiMFDERFA_ER_LREC$Source<-factor(g_hiMFDERFA_ER_LREC$Source,levels=rev(levels(g_hiMFDERFA_ER_LREC$Source)))
# 6b
# g_hiMFDERFA_ER_CFE<-melt(GHG_hiMFDERFA_ER_CFE[,-c(2,8,15:20)],id.vars = c("Year","StockScen","CharScen","RenScen","ElecScen"))
g_hiMFDERFA_ER_CFE<-melt(GHG_hiMFDERFA_ER_CFE[,c("Year","StockScen","CharScen","RenScen","ElecScen","EmGHG","RenGHG","OldOilGHG","NewOilGHG","OldGasGHG","NewGasGHG","OldElecGHG","NewElecGHG")],id.vars = c("Year","StockScen","CharScen","RenScen","ElecScen"))
names(g_hiMFDERFA_ER_CFE)[6:7]<-c("Var","GHG")
g_hiMFDERFA_ER_CFE$Source<-g_hiMFDERFA_ER_CFE$Var
levels(g_hiMFDERFA_ER_CFE$Source)<-list("Emb. Constr." = "EmGHG","Emb. Renov." = "RenGHG","Oil <2020"="OldOilGHG","Oil >2020" = "NewOilGHG",
                                         "Gas <2020"="OldGasGHG","Gas >2020" = "NewGasGHG",
                                         "Elec <2020"="OldElecGHG","Elec >2020" = "NewElecGHG")
g_hiMFDERFA_ER_CFE$Source<-factor(g_hiMFDERFA_ER_CFE$Source,levels=rev(levels(g_hiMFDERFA_ER_CFE$Source)))

# save(g_base_RR,g_base_RR_LREC,g_hiMFDERFA_AR,g_hiMFDERFA_AR_LREC,g_hiMFDERFA_ER,g_hiMFDERFA_ER_LREC,file="../Final_results/GHG_Source.RData")
save(g_base_RR,g_base_RR_LREC,g_base_RR_CFE,g_base_ER,g_base_ER_LREC,g_base_ER_CFE,
     g_hiDRDERFA_ER_LREC,g_hiDRDERFA_ER_CFE,g_hiMFDERFA_ER_LREC,g_hiMFDERFA_ER_CFE,file="../Final_results/GHG_Source_new.RData")
# load("../Final_results/GHG_Source_new.RData")
# try now to make a dual axis version of Fig 3
# base emissions
GHG_base_RR$CumGHG<-GHG_base_RR$TotGHG
for (k in 2:41) {
  GHG_base_RR$CumGHG[k]<-GHG_base_RR$CumGHG[k-1]+GHG_base_RR$TotGHG[k]
}
GHG_base_RR$CumGHG_Gt<-0.001*GHG_base_RR$CumGHG
coeff<-0.03
g_base_RR$`Ann. Emissions`<-g_base_RR$Source

# 3b base RR LREC
GHG_base_RR_LREC$CumGHG<-GHG_base_RR_LREC$TotGHG
for (k in 2:41) {
  GHG_base_RR_LREC$CumGHG[k]<-GHG_base_RR_LREC$CumGHG[k-1]+GHG_base_RR_LREC$TotGHG[k]
}
GHG_base_RR_LREC$CumGHG_Gt<-0.001*GHG_base_RR_LREC$CumGHG
cc1<-GHG_base_RR[,c("Year","CumGHG_Gt")]
cc1$`Cum. Emissions` <-"Baseline scenario"
cc2<-GHG_base_RR_LREC[,c("Year","CumGHG_Gt")]
cc2$`Cum. Emissions`<-"This scenario"
cc<-rbind(cc1,cc2)
g_base_RR_LREC$`Ann. Emissions`<-g_base_RR_LREC$Source
# windows(width = 9.5,height = 7)
# ggplot(g_base_RR_LREC) + geom_bar(aes(x=Year,y=GHG,fill=`Ann. Emissions`), position="stack", stat="identity") +
#   geom_line(data=cc,aes(x=Year,y=CumGHG_Gt/coeff,linetype=`Cum. Emissions`),size=0.8,color="blue")+
#   scale_y_continuous(name = "Annual Emissions (Mt CO2e)", limits = c(0,940), breaks = c(0,250,500,750,1000),
#                      sec.axis = sec_axis(~.*coeff, name="Cum. Emissions (Gt CO2e)",breaks = c(7.5,15,22.5,30))) + 
#   labs(title="b) Baseline Stock and Characteristics (1A), Reg. Renovation, LREC Elec") +
#   theme_bw() + scale_fill_brewer(palette="Dark2")  +
#   theme(axis.text=element_text(size=11),axis.title=element_text(size=12, face = "bold"),
#         axis.title.y.right = element_text(angle=90),plot.title = element_text(size = 12),
#         legend.text=element_text(size=10))
# try to increase font size and highlight differences between figures
# 3(b)
windows(width = 9.5,height = 7)
ggplot(g_base_RR_LREC) + geom_bar(aes(x=Year,y=GHG,fill=`Ann. Emissions`), position="stack", stat="identity") +
  geom_line(data=cc,aes(x=Year,y=CumGHG_Gt/coeff,linetype=`Cum. Emissions`),size=0.8,color="blue")+
  scale_y_continuous(name = "Annual Emissions (Mt CO2e)", limits = c(0,960), breaks = c(0,250,500,750,1000),
                     sec.axis = sec_axis(~.*coeff, name="Cum. Emissions (Gt CO2e)",breaks = c(7.5,15,22.5,30))) + 
  labs(title="b) Baseline Stock and Characteristics (1A)",
       subtitle = "      Regular Renovation, LREC Elec") +
  # theme_bw() + scale_fill_manual(values=c(brewer.pal(12,"Paired")[c(3,4,5,6,9,10)],"#A6761D","#AAAAAA"))  +
  # theme_bw() + scale_fill_manual(values=c(brewer.pal(12,"Paired")[c(3,4,5,6,9,10)],"#696969","#AAAAAA"))  +
  theme_bw() + scale_fill_manual(values=c(brewer.pal(12,"Paired")[c(3,4,5,6,9,10)],"#EEB486","#8A592B"))  +
  theme(axis.text=element_text(size=12),axis.title=element_text(size=12, face = "bold"),
        axis.title.y.right = element_text(angle=90),
        plot.title = element_text(size = 13),plot.subtitle = element_text(size=12,face="bold",color = "red3"),
        legend.text=element_text(size=11),legend.title = element_text(face="bold"))

# 3a base ER
GHG_base_ER$CumGHG<-GHG_base_ER$TotGHG
for (k in 2:41) {
  GHG_base_ER$CumGHG[k]<-GHG_base_ER$CumGHG[k-1]+GHG_base_ER$TotGHG[k]
}
GHG_base_ER$CumGHG_Gt<-0.001*GHG_base_ER$CumGHG
cc1<-GHG_base_RR[,c("Year","CumGHG_Gt")]
cc1$`Cum. Emissions` <-"Baseline scenario"
cc2<-GHG_base_ER[,c("Year","CumGHG_Gt")]
cc2$`Cum. Emissions`<-"This scenario"
cc<-rbind(cc1,cc2)
g_base_ER$`Ann. Emissions`<-g_base_ER$Source
# g_base_ER$`Ann. Emissions`<-gsub("<2020","OldStock",g_base_ER$`Ann. Emissions`)
# g_base_ER$`Ann. Emissions`<-gsub(">2020","NewCon",g_base_ER$`Ann. Emissions`)

# windows(width = 9.5,height = 7)
# ggplot(g_base_ER) + geom_bar(aes(x=Year,y=GHG,fill=`Ann. Emissions`), position="stack", stat="identity") +
#     geom_line(data=cc,aes(x=Year,y=CumGHG_Gt/coeff,linetype=`Cum. Emissions`),size=0.8,color="blue")+
#     scale_y_continuous(name = "Annual Emissions (Mt CO2e)", limits = c(0,940), breaks = c(0,250,500,750,1000),
#                      sec.axis = sec_axis(~.*coeff, name="Cum. Emissions (Gt CO2e)",breaks = c(7.5,15,22.5,30))) + 
#     labs(title="a) Baseline Stock and Characteristics (1A), Ext. Renovation, MC Elec") +
#     theme_bw() + scale_fill_brewer(palette="Dark2")  +
#     theme(axis.text=element_text(size=11),axis.title=element_text(size=12, face = "bold"),
#         axis.title.y.right = element_text(angle=90),plot.title = element_text(size = 12),
#         legend.text=element_text(size=10))

# try to increase font size and highlight differences between figures
# 3(a)
windows(width = 9.5,height = 7)
ggplot(g_base_ER) + geom_bar(aes(x=Year,y=GHG,fill=`Ann. Emissions`), position="stack", stat="identity") +
  geom_line(data=cc,aes(x=Year,y=CumGHG_Gt/coeff,linetype=`Cum. Emissions`),size=0.8,color="blue")+
  scale_y_continuous(name = "Annual Emissions (Mt CO2e)", limits = c(0,960), breaks = c(0,250,500,750,1000),
                     sec.axis = sec_axis(~.*coeff, name="Cum. Emissions (Gt CO2e)",breaks = c(7.5,15,22.5,30))) + 
  labs(title="a) Baseline Stock and Characteristics (1A)",
       subtitle = "      Extensive Renovation, MC Elec") +
  # theme_bw() + scale_fill_manual(values=c(brewer.pal(12,"Paired")[c(3,4,5,6,9,10)],"#A6761D","#AAAAAA"))  +
  # theme_bw() + scale_fill_manual(values=c(brewer.pal(12,"Paired")[c(3,4,5,6,9,10)],"#C2C2C2","#616161"))  +
  theme_bw() + scale_fill_manual(values=c(brewer.pal(12,"Paired")[c(3,4,5,6,9,10)],"#EEB486","#8A592B"))  +
  theme(axis.text=element_text(size=12),axis.title=element_text(size=12, face = "bold"),
        axis.title.y.right = element_text(angle=90),
        plot.title = element_text(size = 13),plot.subtitle = element_text(size=12,face="bold",color = "red3"),
        legend.text=element_text(size=11),legend.title = element_text(face="bold"))


# 3c hiMFDERFA ER_LREC
GHG_hiMFDERFA_ER_LREC$CumGHG<-GHG_hiMFDERFA_ER_LREC$TotGHG
for (k in 2:41) {
  GHG_hiMFDERFA_ER_LREC$CumGHG[k]<-GHG_hiMFDERFA_ER_LREC$CumGHG[k-1]+GHG_hiMFDERFA_ER_LREC$TotGHG[k]
}
GHG_hiMFDERFA_ER_LREC$CumGHG_Gt<-0.001*GHG_hiMFDERFA_ER_LREC$CumGHG
cc1<-GHG_base_RR[,c("Year","CumGHG_Gt")]
cc1$`Cum. Emissions` <-"Baseline scenario"
cc2<-GHG_hiMFDERFA_ER_LREC[,c("Year","CumGHG_Gt")]
cc2$`Cum. Emissions`<-"This scenario"
cc<-rbind(cc1,cc2)
g_hiMFDERFA_ER_LREC$`Ann. Emissions`<-g_hiMFDERFA_ER_LREC$Source
# windows(width = 9.5,height = 7)
# ggplot(g_hiMFDERFA_ER_LREC) + geom_bar(aes(x=Year,y=GHG,fill=`Ann. Emissions`), position="stack", stat="identity") +
#   geom_line(data=cc,aes(x=Year,y=CumGHG_Gt/coeff,linetype=`Cum. Emissions`),size=0.8,color="blue")+
#   scale_y_continuous(name = "Annual Emissions (Mt CO2e)", limits = c(0,940), breaks = c(0,250,500,750,1000),
#                      sec.axis = sec_axis(~.*coeff, name="Cum. Emissions (Gt CO2e)",breaks = c(7.5,15,22.5,30))) + 
#   labs(title="c) Hi MF Inc. Elec, RFA (3D), Ext. Renovation, LREC Elec") +
#   theme_bw() + scale_fill_brewer(palette="Dark2")  +
#   theme(axis.text=element_text(size=11),axis.title=element_text(size=12, face = "bold"),
#         axis.title.y.right = element_text(angle=90),plot.title = element_text(size = 12),
#         legend.text=element_text(size=10))
# try to increase font size and highlight differences between figures
# 3(c)
windows(width = 9.5,height = 7)
ggplot(g_hiMFDERFA_ER_LREC) + geom_bar(aes(x=Year,y=GHG,fill=`Ann. Emissions`), position="stack", stat="identity") +
  geom_line(data=cc,aes(x=Year,y=CumGHG_Gt/coeff,linetype=`Cum. Emissions`),size=0.8,color="blue")+
  scale_y_continuous(name = "Annual Emissions (Mt CO2e)", limits = c(0,960), breaks = c(0,250,500,750,1000),
                     sec.axis = sec_axis(~.*coeff, name="Cum. Emissions (Gt CO2e)",breaks = c(7.5,15,22.5,30))) + 
  labs(title="c) Hi Multifamily, Inc. Electrification, Red. Floor Area (3D)",
       subtitle = "      Extensive Renovation, LREC Elec") +
  # theme_bw() + scale_fill_manual(values=c(brewer.pal(12,"Paired")[c(3,4,5,6,9,10)],"#A6761D"))  +
  # theme_bw() + scale_fill_manual(values=c(brewer.pal(12,"Paired")[c(3,4,5,6,9,10)],"#C2C2C2","#616161"))  +
  theme_bw() + scale_fill_manual(values=c(brewer.pal(12,"Paired")[c(3,4,5,6,9,10)],"#EEB486","#8A592B"))  +
  theme(axis.text=element_text(size=12),axis.title=element_text(size=12, face = "bold"),
        axis.title.y.right = element_text(angle=90),
        plot.title = element_text(size = 13),plot.subtitle = element_text(size=12,face="bold",color = "red3"),
        legend.text=element_text(size=11),legend.title = element_text(face="bold"))

# 3d hiMFDERFA ER_CFE
GHG_hiMFDERFA_ER_CFE$CumGHG<-GHG_hiMFDERFA_ER_CFE$TotGHG
for (k in 2:41) {
  GHG_hiMFDERFA_ER_CFE$CumGHG[k]<-GHG_hiMFDERFA_ER_CFE$CumGHG[k-1]+GHG_hiMFDERFA_ER_CFE$TotGHG[k]
}
GHG_hiMFDERFA_ER_CFE$CumGHG_Gt<-0.001*GHG_hiMFDERFA_ER_CFE$CumGHG
cc1<-GHG_base_RR[,c("Year","CumGHG_Gt")]
cc1$`Cum. Emissions` <-"Baseline scenario"
cc2<-GHG_hiMFDERFA_ER_CFE[,c("Year","CumGHG_Gt")]
cc2$`Cum. Emissions`<-"This scenario"
cc<-rbind(cc1,cc2)
g_hiMFDERFA_ER_CFE$`Ann. Emissions`<-g_hiMFDERFA_ER_CFE$Source
# windows(width = 9.5,height = 7)
# ggplot(g_hiMFDERFA_ER_CFE) + geom_bar(aes(x=Year,y=GHG,fill=`Ann. Emissions`), position="stack", stat="identity") +
#   geom_line(data=cc,aes(x=Year,y=CumGHG_Gt/coeff,linetype=`Cum. Emissions`),size=0.8,color="blue")+
#   scale_y_continuous(name = "Annual Emissions (Mt CO2e)", limits = c(0,940), breaks = c(0,250,500,750,1000),
#                      sec.axis = sec_axis(~.*coeff, name="Cum. Emissions (Gt CO2e)",breaks = c(7.5,15,22.5,30))) + 
#   labs(title="d) Hi MF Inc. Elec, RFA (3D), Ext. Renovation, CFE Elec") +
#   theme_bw() + scale_fill_brewer(palette="Dark2")  +
#   theme(axis.text=element_text(size=11),axis.title=element_text(size=12, face = "bold"),
#         axis.title.y.right = element_text(angle=90),plot.title = element_text(size = 12),
#         legend.text=element_text(size=10))

# try to increase font size and highlight differences between figures
# 3(d)
windows(width = 9.5,height = 7)
ggplot(g_hiMFDERFA_ER_CFE) + geom_bar(aes(x=Year,y=GHG,fill=`Ann. Emissions`), position="stack", stat="identity") +
  geom_line(data=cc,aes(x=Year,y=CumGHG_Gt/coeff,linetype=`Cum. Emissions`),size=0.8,color="blue")+
  scale_y_continuous(name = "Annual Emissions (Mt CO2e)", limits = c(0,960), breaks = c(0,250,500,750,1000),
                     sec.axis = sec_axis(~.*coeff, name="Cum. Emissions (Gt CO2e)",breaks = c(7.5,15,22.5,30))) + 
  labs(title="d) Hi Multifamily, Inc. Electrification, Red. Floor Area (3D)",
       subtitle = "      Extensive Renovation, CFE Elec") +
  # theme_bw() + scale_fill_manual(values=c(brewer.pal(12,"Paired")[c(3,4,5,6,9,10)],"#A6761D"))  +
  theme_bw() + scale_fill_manual(values=c(brewer.pal(12,"Paired")[c(3,4,5,6,9,10)],"#EEB486","#8A592B"))  +
  theme(axis.text=element_text(size=12),axis.title=element_text(size=12, face = "bold"),
        axis.title.y.right = element_text(angle=90),
        plot.title = element_text(size = 13),plot.subtitle = element_text(size=12,face="bold",color = "red3"),
        legend.text=element_text(size=11),legend.title = element_text(face="bold"))
# save data for fig. 3
save(g_base_RR,g_base_RR_LREC,g_base_ER,
     g_hiMFDERFA_ER_LREC,g_hiMFDERFA_ER_CFE,file="../Final_results/Fig3.RData")
# see the ranges in emissions ####
GHG2050<-GHGall[!GHGall$RenScen=="NR"& GHGall$Year==2050,]
# how many make the 2050 target of 330?
length(which(GHG2050$TotGHG<330))

GHG2060<-GHGall[!GHGall$RenScen=="NR"& GHGall$Year==2060,]
GHG2030<-GHGall[!GHGall$RenScen=="NR"& GHGall$Year==2030,]
# how many make the 2030 target of 825?
length(which(GHG2030$TotGHG<825))
GHG2020<-GHGall[!GHGall$RenScen=="NR"& GHGall$Year==2020,]
# difference between base characteristics and IE+RFA
min(GHG2050[GHG2050$CharScen=="A","TotGHG"]-GHG2050[GHG2050$CharScen=="D","TotGHG"])
max(GHG2050[GHG2050$CharScen=="A","TotGHG"]-GHG2050[GHG2050$CharScen=="D","TotGHG"])

summary(GHG2050[GHG2050$CharScen=="A","TotGHG"]-GHG2050[GHG2050$CharScen=="D","TotGHG"])

GHG2045<-GHGall[!GHGall$RenScen=="NR"& GHGall$Year==2045,]
summary(GHG2045[GHG2045$RenScen=="ER"&GHG2045$ElecScen=="CFE","TotGHG"])
summary(GHG2050[GHG2050$RenScen=="ER"&GHG2050$ElecScen=="CFE","TotGHG"])
summary(GHG2060[GHG2060$RenScen=="ER"&GHG2060$ElecScen=="CFE","TotGHG"])

GHG2050$empc<-GHG2050$EmGHG/GHG2050$TotGHG
GHG2060$empc<-GHG2060$EmGHG/GHG2060$TotGHG

summary(GHG2050[GHG2050$ElecScen=="CFE" & GHG2050$RenScen=="ER", ]$empc)
summary(GHG2060[GHG2060$ElecScen=="CFE" & GHG2060$RenScen=="ER", ]$empc)

em2$Stock<-substr(cem2$Var1,1,1)
cem2$NHC<-substr(cem2$Var1,2,2)

# diff in cum emissions between NHC A and NH D
min(cem2[cem2$NHC=="A"&!cem2$Var2=="NR","value"]-cem2[cem2$NHC=="D"&!cem2$Var2=="NR","value"])
max(cem2[cem2$NHC=="A"&!cem2$Var2=="NR","value"]-cem2[cem2$NHC=="D"&!cem2$Var2=="NR","value"])

# diff in cum emissions between hiMF and baseline
min(cem2[cem2$Stock==1&!cem2$Var2=="NR","value"]-cem2[cem2$Stock==3&!cem2$Var2=="NR","value"])
max(cem2[cem2$Stock==1&!cem2$Var2=="NR","value"]-cem2[cem2$Stock==3&!cem2$Var2=="NR","value"])

# diff in cum emissions between CFE and LREC
min(cem2[cem2$Var3=="LREC"&!cem2$Var2=="NR","value"]-cem2[cem2$Var3=="CFE"&!cem2$Var2=="NR","value"])
max(cem2[cem2$Stock==1&!cem2$Var2=="NR","value"]-cem2[cem2$Stock==3&!cem2$Var2=="NR","value"])

# per cap emissions 2020
1e6*887.0747/327259783
# per cap emissions 2050
1e6*83.70639/382556223

# total electricity in 2020 in baseline ER: 1.407e12 kWh (PWh) sum from EIA is for 2020 Res. is 1.462 (https://www.eia.gov/electricity/monthly/epm_table_grapher.php?t=epmt_5_01)
sum(rs_base_all_ER$base_weight*rs_base_all_ER$wbase_2020*rs_base_all_ER$total_site_electricity_kwh)

# total electricity in 2050 in baseline ER 
sum(rs_base_all_ER$base_weight*rs_base_all_ER$wbase_2050*rs_base_all_ER$total_site_electricity_kwh)
# same in hiMFDERFA_ER
sum(rs_hiMFDERFA_all_ER$base_weight*rs_hiMFDERFA_all_ER$whiMF_2050*rs_hiMFDERFA_all_ER$total_site_electricity_kwh)
# difference is around 1.4%, quite disappointing
sum(rs_base_all_ER$base_weight*rs_base_all_ER$wbase_2050*rs_base_all_ER$total_site_electricity_kwh)/sum(rs_hiMFDERFA_all_ER$base_weight*rs_hiMFDERFA_all_ER$whiMF_2050*rs_hiMFDERFA_all_ER$total_site_electricity_kwh)

# total energy in 2050 in baseline ER 
sum(rs_base_all_ER$base_weight*rs_base_all_ER$wbase_2050*rs_base_all_ER$Tot_GJ)
# same in hiMFDERFA_ER
sum(rs_hiMFDERFA_all_ER$base_weight*rs_hiMFDERFA_all_ER$whiMF_2050*rs_hiMFDERFA_all_ER$Tot_GJ)
# difference is 11.4%. much more impressive
sum(rs_base_all_ER$base_weight*rs_base_all_ER$wbase_2050*rs_base_all_ER$Tot_GJ)/sum(rs_hiMFDERFA_all_ER$base_weight*rs_hiMFDERFA_all_ER$whiMF_2050*rs_hiMFDERFA_all_ER$Tot_GJ)

# total energy in 2050 in baseline ER 
sum(rs_base_all_ER$base_weight*rs_base_all_ER$wbase_2050*rs_base_all_ER$Elec_GJ)
# same in hiMFDERFA_ER
sum(rs_hiMFDERFA_all_ER$base_weight*rs_hiMFDERFA_all_ER$whiMF_2050*rs_hiMFDERFA_all_ER$Elec_GJ)
# difference is 11.4%. much more impressive
sum(rs_base_all_ER$base_weight*rs_base_all_ER$wbase_2050*rs_base_all_ER$Elec_GJ)/sum(rs_hiMFDERFA_all_ER$base_weight*rs_hiMFDERFA_all_ER$whiMF_2050*rs_hiMFDERFA_all_ER$Elec_GJ)

# need to compare against the basline with DE
# total electricity in 2050 in baseline ER: 1.846e12 kWh
sum(rs_baseDE_all_ER$base_weight*rs_baseDE_all_ER$wbase_2050*rs_baseDE_all_ER$total_site_electricity_kwh)
# same in hiMFDERFA_ER: 1.743e12 kWh
sum(rs_hiMFDERFA_all_ER$base_weight*rs_hiMFDERFA_all_ER$whiMF_2050*rs_hiMFDERFA_all_ER$total_site_electricity_kwh)
# 6% reduction here
1-sum(rs_hiMFDERFA_all_ER$base_weight*rs_hiMFDERFA_all_ER$whiMF_2050*rs_hiMFDERFA_all_ER$total_site_electricity_kwh)/sum(rs_baseDE_all_ER$base_weight*rs_baseDE_all_ER$wbase_2050*rs_baseDE_all_ER$total_site_electricity_kwh)

# total electricity in 2050 in baseline ER 
sum(rs_baseDE_all_ER$base_weight*rs_baseDE_all_ER$wbase_2050*rs_baseDE_all_ER$Tot_GJ)
# same in hiMFDERFA_ER
sum(rs_hiMFDERFA_all_ER$base_weight*rs_hiMFDERFA_all_ER$whiMF_2050*rs_hiMFDERFA_all_ER$Tot_GJ)
# 6% reduction here
1-sum(rs_hiMFDERFA_all_ER$base_weight*rs_hiMFDERFA_all_ER$whiMF_2050*rs_hiMFDERFA_all_ER$Tot_GJ)/sum(rs_baseDE_all_ER$base_weight*rs_baseDE_all_ER$wbase_2050*rs_baseDE_all_ER$Tot_GJ)
