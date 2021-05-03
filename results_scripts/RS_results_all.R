# script to visualize results
# FINAL results plotting for final results paper. working on updated version
library(ggplot2)
library(dplyr)
library(reshape2)
library(RColorBrewer)
library(openxlsx)
# Nov 22 2020
# Updated with new results Jan 21 2021
rm(list=ls()) # clear workspace i.e. remove saved variables
cat("\014") # clear console
setwd("~/Yale Courses/Research/Final Paper/resstock_projections/results_scripts")
# load in results
# load("~/Yale Courses/Research/Final Paper/StockModelCode/us_FA_summaries.RData") # created by bs_combine
# load("~/Yale Courses/Research/Final Paper/HSM_github/Summary_results/us_FA_summaries.RData") 
# first of all embodied/new construction emissions for 6 housing stock scenarios
load("../../HSM_github/HSM_results/US_FA_GHG_summaries.RData")
# for (n in 1:length(list.files("../Final_results/"))) {
#   load(paste("../Final_results/",list.files("../Final_results/")[n],sep=""))
# }

# then full energy results for 24 housing stock and characteristics scenarios, each with 2 electricity grid variations, all produced by RS_results_proj.R script
# first base scripts #########
load("../Final_results/res_base_RR.RData")
load("../Final_results/res_base_AR.RData")
load("../Final_results/res_hiDR_RR.RData")
load("../Final_results/res_hiDR_AR.RData")
load("../Final_results/res_hiMF_RR.RData")
load("../Final_results/res_hiMF_AR.RData")

GHG_base_RR<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_base_all_RR[,176:184])) # emissions in Mt 
GHG_base_RR<-data.frame(data.frame(EnGHG=with(select(GHG_base_RR,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="A",RenScen="RR",ElecScen="MC")
names(GHG_base_RR)[1:2]<-c("Year","EnGHG")
GHG_base_RR$EmGHG<-us_base_FA$GHG_NC*1e-9
GHG_base_RR$EmGHG[41]<-GHG_base_RR$EmGHG[40]
GHG_base_RR$TotGHG<-GHG_base_RR$EmGHG+GHG_base_RR$EnGHG

GHG_base_RR_LREC<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_base_all_RR[,185:193])) # emissions in Mt 
GHG_base_RR_LREC<-data.frame(data.frame(EnGHG=with(select(GHG_base_RR_LREC,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="A",RenScen="RR",ElecScen="LREC")
names(GHG_base_RR_LREC)[1:2]<-c("Year","EnGHG")
GHG_base_RR_LREC$EmGHG<-us_base_FA$GHG_NC*1e-9
GHG_base_RR_LREC$EmGHG[41]<-GHG_base_RR_LREC$EmGHG[40]
GHG_base_RR_LREC$TotGHG<-GHG_base_RR_LREC$EmGHG+GHG_base_RR_LREC$EnGHG

GHG_base_AR<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_base_all_AR[,176:184])) # emissions in Mt 
GHG_base_AR<-data.frame(data.frame(EnGHG=with(select(GHG_base_AR,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="A",RenScen="AR",ElecScen="MC")
names(GHG_base_AR)[1:2]<-c("Year","EnGHG")
GHG_base_AR$EmGHG<-us_base_FA$GHG_NC*1e-9
GHG_base_AR$EmGHG[41]<-GHG_base_AR$EmGHG[40]
GHG_base_AR$TotGHG<-GHG_base_AR$EmGHG+GHG_base_AR$EnGHG

GHG_base_AR_LREC<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_base_all_AR[,185:193])) # emissions in Mt 
GHG_base_AR_LREC<-data.frame(data.frame(EnGHG=with(select(GHG_base_AR_LREC,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="A",RenScen="AR",ElecScen="LREC")
names(GHG_base_AR_LREC)[1:2]<-c("Year","EnGHG")
GHG_base_AR_LREC$EmGHG<-us_base_FA$GHG_NC*1e-9
GHG_base_AR_LREC$EmGHG[41]<-GHG_base_AR_LREC$EmGHG[40]
GHG_base_AR_LREC$TotGHG<-GHG_base_AR_LREC$EmGHG+GHG_base_AR_LREC$EnGHG

# hi DR
GHG_hiDR_RR<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_hiDR_all_RR[,176:184])) # emissions in Mt 
GHG_hiDR_RR<-data.frame(data.frame(EnGHG=with(select(GHG_hiDR_RR,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=2,CharScen="A",RenScen="RR",ElecScen="MC")
names(GHG_hiDR_RR)[1:2]<-c("Year","EnGHG")
GHG_hiDR_RR$EmGHG<-us_hiDR_FA$GHG_NC*1e-9
GHG_hiDR_RR$EmGHG[41]<-GHG_hiDR_RR$EmGHG[40]
GHG_hiDR_RR$TotGHG<-GHG_hiDR_RR$EmGHG+GHG_hiDR_RR$EnGHG

GHG_hiDR_RR_LREC<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_hiDR_all_RR[,185:193])) # emissions in Mt 
GHG_hiDR_RR_LREC<-data.frame(data.frame(EnGHG=with(select(GHG_hiDR_RR_LREC,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=2,CharScen="A",RenScen="RR",ElecScen="LREC")
names(GHG_hiDR_RR_LREC)[1:2]<-c("Year","EnGHG")
GHG_hiDR_RR_LREC$EmGHG<-us_hiDR_FA$GHG_NC*1e-9
GHG_hiDR_RR_LREC$EmGHG[41]<-GHG_hiDR_RR_LREC$EmGHG[40]
GHG_hiDR_RR_LREC$TotGHG<-GHG_hiDR_RR_LREC$EmGHG+GHG_hiDR_RR_LREC$EnGHG

GHG_hiDR_AR<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_hiDR_all_AR[,176:184])) # emissions in Mt 
GHG_hiDR_AR<-data.frame(data.frame(EnGHG=with(select(GHG_hiDR_AR,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=2,CharScen="A",RenScen="AR",ElecScen="MC")
names(GHG_hiDR_AR)[1:2]<-c("Year","EnGHG")
GHG_hiDR_AR$EmGHG<-us_hiDR_FA$GHG_NC*1e-9
GHG_hiDR_AR$EmGHG[41]<-GHG_hiDR_AR$EmGHG[40]
GHG_hiDR_AR$TotGHG<-GHG_hiDR_AR$EmGHG+GHG_hiDR_AR$EnGHG

GHG_hiDR_AR_LREC<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_hiDR_all_AR[,185:193])) # emissions in Mt 
GHG_hiDR_AR_LREC<-data.frame(data.frame(EnGHG=with(select(GHG_hiDR_AR_LREC,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=2,CharScen="A",RenScen="AR",ElecScen="LREC")
names(GHG_hiDR_AR_LREC)[1:2]<-c("Year","EnGHG")
GHG_hiDR_AR_LREC$EmGHG<-us_hiDR_FA$GHG_NC*1e-9
GHG_hiDR_AR_LREC$EmGHG[41]<-GHG_hiDR_AR_LREC$EmGHG[40]
GHG_hiDR_AR_LREC$TotGHG<-GHG_hiDR_AR_LREC$EmGHG+GHG_hiDR_AR_LREC$EnGHG

# hi MF
GHG_hiMF_RR<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_hiMF_all_RR[,176:184])) # emissions in Mt 
GHG_hiMF_RR<-data.frame(data.frame(EnGHG=with(select(GHG_hiMF_RR,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=3,CharScen="A",RenScen="RR",ElecScen="MC")
names(GHG_hiMF_RR)[1:2]<-c("Year","EnGHG")
GHG_hiMF_RR$EmGHG<-us_hiMF_FA$GHG_NC*1e-9
GHG_hiMF_RR$EmGHG[41]<-GHG_hiMF_RR$EmGHG[40]
GHG_hiMF_RR$TotGHG<-GHG_hiMF_RR$EmGHG+GHG_hiMF_RR$EnGHG

GHG_hiMF_RR_LREC<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_hiMF_all_RR[,185:193])) # emissions in Mt 
GHG_hiMF_RR_LREC<-data.frame(data.frame(EnGHG=with(select(GHG_hiMF_RR_LREC,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=3,CharScen="A",RenScen="RR",ElecScen="LREC")
names(GHG_hiMF_RR_LREC)[1:2]<-c("Year","EnGHG")
GHG_hiMF_RR_LREC$EmGHG<-us_hiMF_FA$GHG_NC*1e-9
GHG_hiMF_RR_LREC$EmGHG[41]<-GHG_hiMF_RR_LREC$EmGHG[40]
GHG_hiMF_RR_LREC$TotGHG<-GHG_hiMF_RR_LREC$EmGHG+GHG_hiMF_RR_LREC$EnGHG

GHG_hiMF_AR<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_hiMF_all_AR[,176:184])) # emissions in Mt 
GHG_hiMF_AR<-data.frame(data.frame(EnGHG=with(select(GHG_hiMF_AR,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=3,CharScen="A",RenScen="AR",ElecScen="MC")
names(GHG_hiMF_AR)[1:2]<-c("Year","EnGHG")
GHG_hiMF_AR$EmGHG<-us_hiMF_FA$GHG_NC*1e-9
GHG_hiMF_AR$EmGHG[41]<-GHG_hiMF_AR$EmGHG[40]
GHG_hiMF_AR$TotGHG<-GHG_hiMF_AR$EmGHG+GHG_hiMF_AR$EnGHG

GHG_hiMF_AR_LREC<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_hiMF_all_AR[,185:193])) # emissions in Mt 
GHG_hiMF_AR_LREC<-data.frame(data.frame(EnGHG=with(select(GHG_hiMF_AR_LREC,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=3,CharScen="A",RenScen="AR",ElecScen="LREC")
names(GHG_hiMF_AR_LREC)[1:2]<-c("Year","EnGHG")
GHG_hiMF_AR_LREC$EmGHG<-us_hiMF_FA$GHG_NC*1e-9
GHG_hiMF_AR_LREC$EmGHG[41]<-GHG_hiMF_AR_LREC$EmGHG[40]
GHG_hiMF_AR_LREC$TotGHG<-GHG_hiMF_AR_LREC$EmGHG+GHG_hiMF_AR_LREC$EnGHG

# calculation source emissions from fuel
# combustion fuel GHGI
GHGI_FO<-((.07396)+(25*3e-6)+(298*6e-7))/1.055  # intensity for heating oil (DFO #2) in kgCO2eq / MJ
GHGI_NG<-((0.05302)+(25*10e-6) + (298*1e-7))/1.055  # intensity for natural gas in kgCO2eq / MJ
GHGI_LP<-((.06298)+(25*3e-6)+(298*6e-7))/1.055   # intensity for LPG in kgCO2eq / MJ

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


OldOilGHG_base_RR<-data.frame(Year=seq(2020,2060,5),OilGHG=colSums(rs_base_all_RR[,196:204])*1e-9)
NewOilGHG_base_RR<-data.frame(Year=seq(2020,2060,5),OilGHG=colSums(rs_base_all_RR[,205:213])*1e-9)
OldGasGHG_base_RR<-data.frame(Year=seq(2020,2060,5),GasGHG=colSums(rs_base_all_RR[,214:222])*1e-9)
NewGasGHG_base_RR<-data.frame(Year=seq(2020,2060,5),GasGHG=colSums(rs_base_all_RR[,223:231])*1e-9)
OldElecGHG_base_RR<-data.frame(Year=seq(2020,2060,5),ElecGHG=colSums(rs_base_all_RR[,232:240])*1e-9)
NewElecGHG_base_RR<-data.frame(Year=seq(2020,2060,5),ElecGHG=colSums(rs_base_all_RR[,241:249])*1e-9)


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

OldElecGHG_base_RR_LREC<-data.frame(Year=seq(2020,2060,5),ElecGHG=colSums(rs_base_all_RR[,250:258])*1e-9)
NewElecGHG_base_RR_LREC<-data.frame(Year=seq(2020,2060,5),ElecGHG=colSums(rs_base_all_RR[,259:267])*1e-9)

GHG_base_RR_LREC$OldOilGHG<-data.frame(OilGHG=with(select(OldOilGHG_base_RR,Year,OilGHG),spline(Year,OilGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_base_RR_LREC$NewOilGHG<-data.frame(OilGHG=with(select(NewOilGHG_base_RR,Year,OilGHG),spline(Year,OilGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_base_RR_LREC$OldGasGHG<-data.frame(GasGHG=with(select(OldGasGHG_base_RR,Year,GasGHG),spline(Year,GasGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_base_RR_LREC$NewGasGHG<-data.frame(GasGHG=with(select(NewGasGHG_base_RR,Year,GasGHG),spline(Year,GasGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_base_RR_LREC$OldElecGHG<-data.frame(ElecGHG=with(select(OldElecGHG_base_RR_LREC,Year,ElecGHG),spline(Year,ElecGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_base_RR_LREC$NewElecGHG<-data.frame(ElecGHG=with(select(NewElecGHG_base_RR_LREC,Year,ElecGHG),spline(Year,ElecGHG,xout = 2020:2060)),method="spline()")[,2]


# do same for hi DR RR

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


OldOilGHG_hiDR_RR<-data.frame(Year=seq(2020,2060,5),OilGHG=colSums(rs_hiDR_all_RR[,196:204])*1e-9)
NewOilGHG_hiDR_RR<-data.frame(Year=seq(2020,2060,5),OilGHG=colSums(rs_hiDR_all_RR[,205:213])*1e-9)
OldGasGHG_hiDR_RR<-data.frame(Year=seq(2020,2060,5),GasGHG=colSums(rs_hiDR_all_RR[,214:222])*1e-9)
NewGasGHG_hiDR_RR<-data.frame(Year=seq(2020,2060,5),GasGHG=colSums(rs_hiDR_all_RR[,223:231])*1e-9)
OldElecGHG_hiDR_RR<-data.frame(Year=seq(2020,2060,5),ElecGHG=colSums(rs_hiDR_all_RR[,232:240])*1e-9)
NewElecGHG_hiDR_RR<-data.frame(Year=seq(2020,2060,5),ElecGHG=colSums(rs_hiDR_all_RR[,241:249])*1e-9)


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

OldElecGHG_hiDR_RR_LREC<-data.frame(Year=seq(2020,2060,5),ElecGHG=colSums(rs_hiDR_all_RR[,250:258])*1e-9)
NewElecGHG_hiDR_RR_LREC<-data.frame(Year=seq(2020,2060,5),ElecGHG=colSums(rs_hiDR_all_RR[,259:267])*1e-9)

GHG_hiDR_RR_LREC$OldOilGHG<-data.frame(OilGHG=with(select(OldOilGHG_hiDR_RR,Year,OilGHG),spline(Year,OilGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_hiDR_RR_LREC$NewOilGHG<-data.frame(OilGHG=with(select(NewOilGHG_hiDR_RR,Year,OilGHG),spline(Year,OilGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_hiDR_RR_LREC$OldGasGHG<-data.frame(GasGHG=with(select(OldGasGHG_hiDR_RR,Year,GasGHG),spline(Year,GasGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_hiDR_RR_LREC$NewGasGHG<-data.frame(GasGHG=with(select(NewGasGHG_hiDR_RR,Year,GasGHG),spline(Year,GasGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_hiDR_RR_LREC$OldElecGHG<-data.frame(ElecGHG=with(select(OldElecGHG_hiDR_RR_LREC,Year,ElecGHG),spline(Year,ElecGHG,xout = 2020:2060)),method="spline()")[,2]
GHG_hiDR_RR_LREC$NewElecGHG<-data.frame(ElecGHG=with(select(NewElecGHG_hiDR_RR_LREC,Year,ElecGHG),spline(Year,ElecGHG,xout = 2020:2060)),method="spline()")[,2]

# calculate relative changes in emissiosn from difference sources
GHG_base_RR$EmGHG_pc<-GHG_base_RR$EmGHG/GHG_base_RR$EmGHG[1]
GHG_base_RR$TotGHG_pc<-GHG_base_RR$TotGHG/GHG_base_RR$TotGHG[1]
GHG_base_RR$OilGHG_pc<-rowSums(GHG_base_RR[,c("OldOilGHG","NewOilGHG")])/GHG_base_RR$OldOilGHG[1]
GHG_base_RR$GasGHG_pc<-rowSums(GHG_base_RR[,c("OldGasGHG","NewGasGHG")])/GHG_base_RR$OldGasGHG[1]
GHG_base_RR$ElecGHG_pc<-rowSums(GHG_base_RR[,c("OldElecGHG","NewElecGHG")])/GHG_base_RR$OldElecGHG[1]
GHG_base_RR$EmGHG_pc_tot<-GHG_base_RR$EmGHG/GHG_base_RR$TotGHG

GHG_base_RR_LREC$EmGHG_pc<-GHG_base_RR_LREC$EmGHG/GHG_base_RR_LREC$EmGHG[1]
GHG_base_RR_LREC$TotGHG_pc<-GHG_base_RR_LREC$TotGHG/GHG_base_RR_LREC$TotGHG[1]
GHG_base_RR_LREC$OilGHG_pc<-rowSums(GHG_base_RR_LREC[,c("OldOilGHG","NewOilGHG")])/GHG_base_RR_LREC$OldOilGHG[1]
GHG_base_RR_LREC$GasGHG_pc<-rowSums(GHG_base_RR_LREC[,c("OldGasGHG","NewGasGHG")])/GHG_base_RR_LREC$OldGasGHG[1]
GHG_base_RR_LREC$ElecGHG_pc<-rowSums(GHG_base_RR_LREC[,c("OldElecGHG","NewElecGHG")])/GHG_base_RR_LREC$OldElecGHG[1]
GHG_base_RR_LREC$EmGHG_pc_tot<-GHG_base_RR_LREC$EmGHG/GHG_base_RR_LREC$TotGHG

GHG_hiDR_RR$EmGHG_pc<-GHG_hiDR_RR$EmGHG/GHG_hiDR_RR$EmGHG[1]
GHG_hiDR_RR$TotGHG_pc<-GHG_hiDR_RR$TotGHG/GHG_hiDR_RR$TotGHG[1]
GHG_hiDR_RR$OilGHG_pc<-rowSums(GHG_hiDR_RR[,c("OldOilGHG","NewOilGHG")])/GHG_hiDR_RR$OldOilGHG[1]
GHG_hiDR_RR$GasGHG_pc<-rowSums(GHG_hiDR_RR[,c("OldGasGHG","NewGasGHG")])/GHG_hiDR_RR$OldGasGHG[1]
GHG_hiDR_RR$ElecGHG_pc<-rowSums(GHG_hiDR_RR[,c("OldElecGHG","NewElecGHG")])/GHG_hiDR_RR$OldElecGHG[1]
GHG_hiDR_RR$EmGHG_pc_tot<-GHG_hiDR_RR$EmGHG/GHG_hiDR_RR$TotGHG

GHG_hiDR_RR_LREC$EmGHG_pc<-GHG_hiDR_RR_LREC$EmGHG/GHG_hiDR_RR_LREC$EmGHG[1]
GHG_hiDR_RR_LREC$TotGHG_pc<-GHG_hiDR_RR_LREC$TotGHG/GHG_hiDR_RR_LREC$TotGHG[1]
GHG_hiDR_RR_LREC$OilGHG_pc<-rowSums(GHG_hiDR_RR_LREC[,c("OldOilGHG","NewOilGHG")])/GHG_hiDR_RR_LREC$OldOilGHG[1]
GHG_hiDR_RR_LREC$GasGHG_pc<-rowSums(GHG_hiDR_RR_LREC[,c("OldGasGHG","NewGasGHG")])/GHG_hiDR_RR_LREC$OldGasGHG[1]
GHG_hiDR_RR_LREC$ElecGHG_pc<-rowSums(GHG_hiDR_RR_LREC[,c("OldElecGHG","NewElecGHG")])/GHG_hiDR_RR_LREC$OldElecGHG[1]
GHG_hiDR_RR_LREC$EmGHG_pc_tot<-GHG_hiDR_RR_LREC$EmGHG/GHG_hiDR_RR_LREC$TotGHG

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

fn<-"../Supplementary_results/EI.xlsx"
wb<-createWorkbook()
addWorksheet(wb, "base_RR_2020")
writeData(wb, "base_RR_2020", EI_base_RR20)
addWorksheet(wb, "base_RR_2060")
writeData(wb, "base_RR_2060", EI_base_RR60)
addWorksheet(wb, "base_AR_2060")
writeData(wb, "base_AR_2060", EI_base_AR60)

saveWorkbook(wb,file = fn,overwrite = TRUE)

m2_base_RR<-tapply(rs_base_all_RR$Tot_MJ_m2,list(rs_base_all_RR$Vintage,rs_base_all_RR$Year,rs_base_all_RR$Type3),mean)

write.csv(EI_base_RR,file = "../Supplementary_results/EI_base_RR.csv")

# total energy per type and vintage in 2060, in PJ
round(tapply(rs_base_all_RR$Tot_GJ*rs_base_all_RR$base_weight*rs_base_all_RR$wbase_2060,list(rs_base_all_RR$Type3,rs_base_all_RR$Vintage),sum)*1e-6)
# total GHG by type and vintage in 2060, in MTon
round(tapply(rs_base_all_RR$EnGHGkg_base_2060,list(rs_base_all_RR$Type3,rs_base_all_RR$Vintage),sum)*1e-9,2)

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
 
# tapply(rs_base_all_AR$Tot_MJ_m2,list(rs_base_all_AR$Year,rs_base_all_AR$Segment,rs_base_all_AR$Type3),mean)

# EI_ren_RR<-1000*tapply(rs_base_all_RR$Tot_GJ,list(rs_base_all_RR$Type3,rs_base_all_RR$Year,rs_base_all_RR$Segment),sum)/
#   (tapply(rs_base_all_RR$floor_area_lighting_ft_2,list(rs_base_all_RR$Type3,rs_base_all_RR$Year,rs_base_all_RR$Segment),sum)/10.765)
# 
# EI_ren_AR<-1000*tapply(rs_base_all_AR$Tot_GJ,list(rs_base_all_AR$Type3,rs_base_all_AR$Year,rs_base_all_AR$Segment),sum)/
#   (tapply(rs_base_all_AR$floor_area_lighting_ft_2,list(rs_base_all_AR$Type3,rs_base_all_AR$Year,rs_base_all_AR$Segment),sum)/10.765)
# 
# 1000*tapply(rs_base_all_RR$Tot_GJ,list(rs_base_all_RR$Year,rs_base_all_RR$Segment),sum)/
#   (tapply(rs_base_all_RR$floor_area_lighting_ft_2,list(rs_base_all_RR$Year,rs_base_all_RR$Segment),sum)/10.765)
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

EI_seg<-data.frame(Year=seq(2020,2060,5),New=EI_RR_New,RR_OldUnRen=EI_RR_OU,RR_OldRen=EI_RR_OR,AR_OldUnRen=EI_AR_OU,AR_OldRen=EI_AR_OR)

write.csv(EI_seg,file="../Supplementary_results/EI_seg_base.csv")

# make graphs of housing stock characteristics using dplyr pipe
rs_base_all_RR[,c("Housing Units 2020","Housing Units 2025","Housing Units 2030","Housing Units 2035","Housing Units 2040","Housing Units 2045","Housing Units 2050","Housing Units 2055","Housing Units 2060")]<-
  rs_base_all_RR$base_weight*rs_base_all_RR[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")]

rs_base_all_AR[,c("Housing Units 2020","Housing Units 2025","Housing Units 2030","Housing Units 2035","Housing Units 2040","Housing Units 2045","Housing Units 2050","Housing Units 2055","Housing Units 2060")]<-
  rs_base_all_AR$base_weight*rs_base_all_AR[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")]

# take 1, here try to calculate future emissions without renovation or reduction in GHG intensity of electricity
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

New_G20<-colSums(rs_base_NC[,279:287])*1e-9
# emissions from new housing with grid decarbonization
New_MC<-colSums(rs_base_NC[,176:184])*1e-9

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

Old_NR_MC<-colSums(rs_base_Old[,279:287])*1e-9

# No action scenarios
NA_scen<-data.frame(Year=seq(2020,2060,5),Old_NR_G20=Old_NR_G20,New_G20=New_G20,Old_NR_MC=Old_NR_MC,New_MC=New_MC)
NA_scen$EnGHG_NR_G20<-NA_scen$Old_NR_G20+NA_scen$New_G20
NA_scen$EnGHG_NR_MC<-NA_scen$Old_NR_MC+NA_scen$New_MC

GHG_base_NR<-data.frame(data.frame(EnGHG=with(select(NA_scen,Year,EnGHG_NR_MC),spline(Year,EnGHG_NR_MC,xout=2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="A",RenScen="NR",ElecScen="MC")
names(GHG_base_NR)[1:2]<-c("Year","EnGHG")
GHG_base_NR$EmGHG<-us_base_FA$GHG_NC*1e-9
GHG_base_NR$EmGHG[41]<-GHG_base_NR$EmGHG[40]
GHG_base_NR$TotGHG<-GHG_base_NR$EmGHG+GHG_base_NR$EnGHG

GHG_base_NR_G20<-data.frame(data.frame(EnGHG=with(select(NA_scen,Year,EnGHG_NR_G20),spline(Year,EnGHG_NR_G20,xout=2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="A",RenScen="NR",ElecScen="G20")
names(GHG_base_NR_G20)[1:2]<-c("Year","EnGHG")
GHG_base_NR_G20$EmGHG<-us_base_FA$GHG_NC*1e-9
GHG_base_NR_G20$EmGHG[41]<-GHG_base_NR_G20$EmGHG[40]
GHG_base_NR_G20$TotGHG<-GHG_base_NR_G20$EmGHG+GHG_base_NR_G20$EnGHG

# continue with the dplyr pipe operations
r<-melt(rs_base_all_RR %>% group_by(Heating.Fuel) %>% summarise(across(starts_with("Housing Units"),sum)))
names(r)[2]<-'Year'
r$Year<-gsub('Housing Units ','', r$Year)
r[r$Heating.Fuel %in% c("None","Other Fuel"),]$Heating.Fuel<-"Other/None"
windows(width = 7, height = 6.5)
ggplot(r,aes(Year,1e-6*value,fill=Heating.Fuel)) + geom_col() + theme_bw() +
  labs(title = "a) 1A Baseline Stock Reg Renovation ",  y = "Million Housing Units") + scale_fill_brewer(palette="Dark2")  +
  theme(axis.text=element_text(size=11),axis.title=element_text(size=12,face = "bold"),plot.title = element_text(size = 12))

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
# r$ACH50<-as.factor(r$ACH50)
windows(width = 7, height = 6.5)
ggplot(r,aes(Year,1e-6*value,fill=ACH50)) + geom_col() + theme_bw() +
  labs(title = "Pre-2020 housing units by Infiltration, 2020-2060", subtitle = "Baseline, Regular Renovation",  y = "Million Housing Units") + scale_fill_manual(values=colorRampPalette(brewer.pal(8,"Dark2"))(15))  +
  theme(axis.text=element_text(size=11),axis.title=element_text(size=12,face = "bold"),plot.title = element_text(size = 12))

r<-melt(rs_base_all_AR %>% group_by(Heating.Fuel) %>% summarise(across(starts_with("Housing Units"),sum)))
names(r)[2]<-'Year'
r$Year<-gsub('Housing Units ','', r$Year)
r[r$Heating.Fuel %in% c("None","Other Fuel"),]$Heating.Fuel<-"Other/None"
windows(width = 7, height = 6.5)
ggplot(r,aes(Year,1e-6*value,fill=Heating.Fuel)) + geom_col() + theme_bw() +
  labs(title = "b) 1A Baseline Stock Adv Renovation ",  y = "Million Housing Units") + scale_fill_brewer(palette="Dark2")  +
  theme(axis.text=element_text(size=11),axis.title=element_text(size=12,face = "bold"),plot.title = element_text(size = 12))

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
  labs(title = "Pre-2020 housing units by Infiltration, 2020-2060", subtitle = "Baseline, Advanced Renovation",  y = "Million Housing Units") + scale_fill_manual(values=colorRampPalette(brewer.pal(8,"Dark2"))(15))  +
  theme(axis.text=element_text(size=11),axis.title=element_text(size=12,face = "bold"),plot.title = element_text(size = 12))

# hi DR
rs_hiDR_all_RR[,c("Housing Units 2020","Housing Units 2025","Housing Units 2030","Housing Units 2035","Housing Units 2040","Housing Units 2045","Housing Units 2050","Housing Units 2055","Housing Units 2060")]<-
  rs_hiDR_all_RR$base_weight*rs_hiDR_all_RR[,c("whiDR_2020",  "whiDR_2025", "whiDR_2030", "whiDR_2035", "whiDR_2040", "whiDR_2045", "whiDR_2050", "whiDR_2055", "whiDR_2060")]

rs_hiDR_all_AR[,c("Housing Units 2020","Housing Units 2025","Housing Units 2030","Housing Units 2035","Housing Units 2040","Housing Units 2045","Housing Units 2050","Housing Units 2055","Housing Units 2060")]<-
  rs_hiDR_all_AR$base_weight*rs_hiDR_all_AR[,c("whiDR_2020",  "whiDR_2025", "whiDR_2030", "whiDR_2035", "whiDR_2040", "whiDR_2045", "whiDR_2050", "whiDR_2055", "whiDR_2060")]


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


r<-melt(rs_hiMF_all_RR %>% group_by(Heating.Fuel) %>% summarise(across(starts_with("Housing Units"),sum)))
names(r)[2]<-'Year'
r$Year<-gsub('Housing Units ','', r$Year)
r[r$Heating.Fuel %in% c("None","Other Fuel"),]$Heating.Fuel<-"Other/None"
windows(width = 7, height = 6.5)
ggplot(r,aes(Year,1e-6*value,fill=Heating.Fuel)) + geom_col() + theme_bw() +
  labs(title = "c) 2A Hi Multifamily Reg Renovation ",  y = "Million Housing Units") + scale_fill_brewer(palette="Dark2")  +
  theme(axis.text=element_text(size=11),axis.title=element_text(size=12,face = "bold"),plot.title = element_text(size = 12))

r<-melt(rs_hiMF_all_AR %>% group_by(Heating.Fuel) %>% summarise(across(starts_with("Housing Units"),sum)))
names(r)[2]<-'Year'
r$Year<-gsub('Housing Units ','', r$Year)
r[r$Heating.Fuel %in% c("None","Other Fuel"),]$Heating.Fuel<-"Other/None"
windows(width = 7, height = 6.5)
ggplot(r,aes(Year,1e-6*value,fill=Heating.Fuel)) + geom_col() + theme_bw() +
  labs(title = "d) 2A Hi Multifamily Adv Renovation ",  y = "Million Housing Units") + scale_fill_brewer(palette="Dark2")  +
  theme(axis.text=element_text(size=11),axis.title=element_text(size=12,face = "bold"),plot.title = element_text(size = 12))


rm(list=ls(pattern = "rs_"))

# second RFA scripts #########
load("../Final_results/res_baseRFA_RR.RData")
load("../Final_results/res_baseRFA_AR.RData")
load("../Final_results/res_hiDRRFA_RR.RData")
load("../Final_results/res_hiDRRFA_AR.RData")
load("../Final_results/res_hiMFRFA_RR.RData")
load("../Final_results/res_hiMFRFA_AR.RData")

GHG_baseRFA_RR<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_baseRFA_all_RR[,176:184])) # emissions in Mt 
GHG_baseRFA_RR<-data.frame(data.frame(EnGHG=with(select(GHG_baseRFA_RR,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="B",RenScen="RR",ElecScen="MC")
names(GHG_baseRFA_RR)[1:2]<-c("Year","EnGHG")
GHG_baseRFA_RR$EmGHG<-us_RFA_FA$GHG_NC*1e-9
GHG_baseRFA_RR$EmGHG[41]<-GHG_baseRFA_RR$EmGHG[40]
GHG_baseRFA_RR$TotGHG<-GHG_baseRFA_RR$EmGHG+GHG_baseRFA_RR$EnGHG

GHG_baseRFA_RR_LREC<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_baseRFA_all_RR[,185:193])) # emissions in Mt 
GHG_baseRFA_RR_LREC<-data.frame(data.frame(EnGHG=with(select(GHG_baseRFA_RR_LREC,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="B",RenScen="RR",ElecScen="LREC")
names(GHG_baseRFA_RR_LREC)[1:2]<-c("Year","EnGHG")
GHG_baseRFA_RR_LREC$EmGHG<-us_RFA_FA$GHG_NC*1e-9
GHG_baseRFA_RR_LREC$EmGHG[41]<-GHG_baseRFA_RR_LREC$EmGHG[40]
GHG_baseRFA_RR_LREC$TotGHG<-GHG_baseRFA_RR_LREC$EmGHG+GHG_baseRFA_RR_LREC$EnGHG

GHG_baseRFA_AR<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_baseRFA_all_AR[,176:184])) # emissions in Mt 
GHG_baseRFA_AR<-data.frame(data.frame(EnGHG=with(select(GHG_baseRFA_AR,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="B",RenScen="AR",ElecScen="MC")
names(GHG_baseRFA_AR)[1:2]<-c("Year","EnGHG")
GHG_baseRFA_AR$EmGHG<-us_RFA_FA$GHG_NC*1e-9
GHG_baseRFA_AR$EmGHG[41]<-GHG_baseRFA_AR$EmGHG[40]
GHG_baseRFA_AR$TotGHG<-GHG_baseRFA_AR$EmGHG+GHG_baseRFA_AR$EnGHG

GHG_baseRFA_AR_LREC<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_baseRFA_all_AR[,185:193])) # emissions in Mt 
GHG_baseRFA_AR_LREC<-data.frame(data.frame(EnGHG=with(select(GHG_baseRFA_AR_LREC,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="B",RenScen="AR",ElecScen="LREC")
names(GHG_baseRFA_AR_LREC)[1:2]<-c("Year","EnGHG")
GHG_baseRFA_AR_LREC$EmGHG<-us_RFA_FA$GHG_NC*1e-9
GHG_baseRFA_AR_LREC$EmGHG[41]<-GHG_baseRFA_AR_LREC$EmGHG[40]
GHG_baseRFA_AR_LREC$TotGHG<-GHG_baseRFA_AR_LREC$EmGHG+GHG_baseRFA_AR_LREC$EnGHG

# hi DR
GHG_hiDRRFA_RR<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_hiDRRFA_all_RR[,176:184])) # emissions in Mt 
GHG_hiDRRFA_RR<-data.frame(data.frame(EnGHG=with(select(GHG_hiDRRFA_RR,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=2,CharScen="B",RenScen="RR",ElecScen="MC")
names(GHG_hiDRRFA_RR)[1:2]<-c("Year","EnGHG")
GHG_hiDRRFA_RR$EmGHG<-us_hiDR_RFA_FA$GHG_NC*1e-9
GHG_hiDRRFA_RR$EmGHG[41]<-GHG_hiDRRFA_RR$EmGHG[40]
GHG_hiDRRFA_RR$TotGHG<-GHG_hiDRRFA_RR$EmGHG+GHG_hiDRRFA_RR$EnGHG

GHG_hiDRRFA_RR_LREC<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_hiDRRFA_all_RR[,185:193])) # emissions in Mt 
GHG_hiDRRFA_RR_LREC<-data.frame(data.frame(EnGHG=with(select(GHG_hiDRRFA_RR_LREC,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=2,CharScen="B",RenScen="RR",ElecScen="LREC")
names(GHG_hiDRRFA_RR_LREC)[1:2]<-c("Year","EnGHG")
GHG_hiDRRFA_RR_LREC$EmGHG<-us_hiDR_RFA_FA$GHG_NC*1e-9
GHG_hiDRRFA_RR_LREC$EmGHG[41]<-GHG_hiDRRFA_RR_LREC$EmGHG[40]
GHG_hiDRRFA_RR_LREC$TotGHG<-GHG_hiDRRFA_RR_LREC$EmGHG+GHG_hiDRRFA_RR_LREC$EnGHG

GHG_hiDRRFA_AR<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_hiDRRFA_all_AR[,176:184])) # emissions in Mt 
GHG_hiDRRFA_AR<-data.frame(data.frame(EnGHG=with(select(GHG_hiDRRFA_AR,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=2,CharScen="B",RenScen="AR",ElecScen="MC")
names(GHG_hiDRRFA_AR)[1:2]<-c("Year","EnGHG")
GHG_hiDRRFA_AR$EmGHG<-us_hiDR_RFA_FA$GHG_NC*1e-9
GHG_hiDRRFA_AR$EmGHG[41]<-GHG_hiDRRFA_AR$EmGHG[40]
GHG_hiDRRFA_AR$TotGHG<-GHG_hiDRRFA_AR$EmGHG+GHG_hiDRRFA_AR$EnGHG

GHG_hiDRRFA_AR_LREC<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_hiDRRFA_all_AR[,185:193])) # emissions in Mt 
GHG_hiDRRFA_AR_LREC<-data.frame(data.frame(EnGHG=with(select(GHG_hiDRRFA_AR_LREC,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=2,CharScen="B",RenScen="AR",ElecScen="LREC")
names(GHG_hiDRRFA_AR_LREC)[1:2]<-c("Year","EnGHG")
GHG_hiDRRFA_AR_LREC$EmGHG<-us_hiDR_RFA_FA$GHG_NC*1e-9
GHG_hiDRRFA_AR_LREC$EmGHG[41]<-GHG_hiDRRFA_AR_LREC$EmGHG[40]
GHG_hiDRRFA_AR_LREC$TotGHG<-GHG_hiDRRFA_AR_LREC$EmGHG+GHG_hiDRRFA_AR_LREC$EnGHG

# hi MF
GHG_hiMFRFA_RR<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_hiMFRFA_all_RR[,176:184])) # emissions in Mt 
GHG_hiMFRFA_RR<-data.frame(data.frame(EnGHG=with(select(GHG_hiMFRFA_RR,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=3,CharScen="B",RenScen="RR",ElecScen="MC")
names(GHG_hiMFRFA_RR)[1:2]<-c("Year","EnGHG")
GHG_hiMFRFA_RR$EmGHG<-us_hiMF_RFA_FA$GHG_NC*1e-9
GHG_hiMFRFA_RR$EmGHG[41]<-GHG_hiMFRFA_RR$EmGHG[40]
GHG_hiMFRFA_RR$TotGHG<-GHG_hiMFRFA_RR$EmGHG+GHG_hiMFRFA_RR$EnGHG

GHG_hiMFRFA_RR_LREC<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_hiMFRFA_all_RR[,185:193])) # emissions in Mt 
GHG_hiMFRFA_RR_LREC<-data.frame(data.frame(EnGHG=with(select(GHG_hiMFRFA_RR_LREC,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=3,CharScen="B",RenScen="RR",ElecScen="LREC")
names(GHG_hiMFRFA_RR_LREC)[1:2]<-c("Year","EnGHG")
GHG_hiMFRFA_RR_LREC$EmGHG<-us_hiMF_RFA_FA$GHG_NC*1e-9
GHG_hiMFRFA_RR_LREC$EmGHG[41]<-GHG_hiMFRFA_RR_LREC$EmGHG[40]
GHG_hiMFRFA_RR_LREC$TotGHG<-GHG_hiMFRFA_RR_LREC$EmGHG+GHG_hiMFRFA_RR_LREC$EnGHG

GHG_hiMFRFA_AR<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_hiMFRFA_all_AR[,176:184])) # emissions in Mt 
GHG_hiMFRFA_AR<-data.frame(data.frame(EnGHG=with(select(GHG_hiMFRFA_AR,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=3,CharScen="B",RenScen="AR",ElecScen="MC")
names(GHG_hiMFRFA_AR)[1:2]<-c("Year","EnGHG")
GHG_hiMFRFA_AR$EmGHG<-us_hiMF_RFA_FA$GHG_NC*1e-9
GHG_hiMFRFA_AR$EmGHG[41]<-GHG_hiMFRFA_AR$EmGHG[40]
GHG_hiMFRFA_AR$TotGHG<-GHG_hiMFRFA_AR$EmGHG+GHG_hiMFRFA_AR$EnGHG

GHG_hiMFRFA_AR_LREC<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_hiMFRFA_all_AR[,185:193])) # emissions in Mt 
GHG_hiMFRFA_AR_LREC<-data.frame(data.frame(EnGHG=with(select(GHG_hiMFRFA_AR_LREC,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=3,CharScen="B",RenScen="AR",ElecScen="LREC")
names(GHG_hiMFRFA_AR_LREC)[1:2]<-c("Year","EnGHG")
GHG_hiMFRFA_AR_LREC$EmGHG<-us_hiMF_RFA_FA$GHG_NC*1e-9
GHG_hiMFRFA_AR_LREC$EmGHG[41]<-GHG_hiMFRFA_AR_LREC$EmGHG[40]
GHG_hiMFRFA_AR_LREC$TotGHG<-GHG_hiMFRFA_AR_LREC$EmGHG+GHG_hiMFRFA_AR_LREC$EnGHG

rm(list=ls(pattern = "rs_"))

# third baseDE scripts #########
load("../Final_results/res_baseDE_RR.RData")
load("../Final_results/res_baseDE_AR.RData")
load("../Final_results/res_hiDRDE_RR.RData")
load("../Final_results/res_hiDRDE_AR.RData")
load("../Final_results/res_hiMFDE_RR.RData")
load("../Final_results/res_hiMFDE_AR.RData")

GHG_baseDE_RR<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_baseDE_all_RR[,176:184])) # emissions in Mt 
GHG_baseDE_RR<-data.frame(data.frame(EnGHG=with(select(GHG_baseDE_RR,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="C",RenScen="RR",ElecScen="MC")
names(GHG_baseDE_RR)[1:2]<-c("Year","EnGHG")
GHG_baseDE_RR$EmGHG<-us_base_FA$GHG_NC*1e-9
GHG_baseDE_RR$EmGHG[41]<-GHG_baseDE_RR$EmGHG[40]
GHG_baseDE_RR$TotGHG<-GHG_baseDE_RR$EmGHG+GHG_baseDE_RR$EnGHG

GHG_baseDE_RR_LREC<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_baseDE_all_RR[,185:193])) # emissions in Mt 
GHG_baseDE_RR_LREC<-data.frame(data.frame(EnGHG=with(select(GHG_baseDE_RR_LREC,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="C",RenScen="RR",ElecScen="LREC")
names(GHG_baseDE_RR_LREC)[1:2]<-c("Year","EnGHG")
GHG_baseDE_RR_LREC$EmGHG<-us_base_FA$GHG_NC*1e-9
GHG_baseDE_RR_LREC$EmGHG[41]<-GHG_baseDE_RR_LREC$EmGHG[40]
GHG_baseDE_RR_LREC$TotGHG<-GHG_baseDE_RR_LREC$EmGHG+GHG_baseDE_RR_LREC$EnGHG

GHG_baseDE_AR<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_baseDE_all_AR[,176:184])) # emissions in Mt 
GHG_baseDE_AR<-data.frame(data.frame(EnGHG=with(select(GHG_baseDE_AR,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="C",RenScen="AR",ElecScen="MC")
names(GHG_baseDE_AR)[1:2]<-c("Year","EnGHG")
GHG_baseDE_AR$EmGHG<-us_base_FA$GHG_NC*1e-9
GHG_baseDE_AR$EmGHG[41]<-GHG_baseDE_AR$EmGHG[40]
GHG_baseDE_AR$TotGHG<-GHG_baseDE_AR$EmGHG+GHG_baseDE_AR$EnGHG

GHG_baseDE_AR_LREC<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_baseDE_all_AR[,185:193])) # emissions in Mt 
GHG_baseDE_AR_LREC<-data.frame(data.frame(EnGHG=with(select(GHG_baseDE_AR_LREC,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="C",RenScen="AR",ElecScen="LREC")
names(GHG_baseDE_AR_LREC)[1:2]<-c("Year","EnGHG")
GHG_baseDE_AR_LREC$EmGHG<-us_base_FA$GHG_NC*1e-9
GHG_baseDE_AR_LREC$EmGHG[41]<-GHG_baseDE_AR_LREC$EmGHG[40]
GHG_baseDE_AR_LREC$TotGHG<-GHG_baseDE_AR_LREC$EmGHG+GHG_baseDE_AR_LREC$EnGHG

# hi DR
GHG_hiDRDE_RR<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_hiDRDE_all_RR[,176:184])) # emissions in Mt 
GHG_hiDRDE_RR<-data.frame(data.frame(EnGHG=with(select(GHG_hiDRDE_RR,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=2,CharScen="C",RenScen="RR",ElecScen="MC")
names(GHG_hiDRDE_RR)[1:2]<-c("Year","EnGHG")
GHG_hiDRDE_RR$EmGHG<-us_hiDR_FA$GHG_NC*1e-9
GHG_hiDRDE_RR$EmGHG[41]<-GHG_hiDRDE_RR$EmGHG[40]
GHG_hiDRDE_RR$TotGHG<-GHG_hiDRDE_RR$EmGHG+GHG_hiDRDE_RR$EnGHG

GHG_hiDRDE_RR_LREC<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_hiDRDE_all_RR[,185:193])) # emissions in Mt 
GHG_hiDRDE_RR_LREC<-data.frame(data.frame(EnGHG=with(select(GHG_hiDRDE_RR_LREC,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=2,CharScen="C",RenScen="RR",ElecScen="LREC")
names(GHG_hiDRDE_RR_LREC)[1:2]<-c("Year","EnGHG")
GHG_hiDRDE_RR_LREC$EmGHG<-us_hiDR_FA$GHG_NC*1e-9
GHG_hiDRDE_RR_LREC$EmGHG[41]<-GHG_hiDRDE_RR_LREC$EmGHG[40]
GHG_hiDRDE_RR_LREC$TotGHG<-GHG_hiDRDE_RR_LREC$EmGHG+GHG_hiDRDE_RR_LREC$EnGHG

GHG_hiDRDE_AR<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_hiDRDE_all_AR[,176:184])) # emissions in Mt 
GHG_hiDRDE_AR<-data.frame(data.frame(EnGHG=with(select(GHG_hiDRDE_AR,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=2,CharScen="C",RenScen="AR",ElecScen="MC")
names(GHG_hiDRDE_AR)[1:2]<-c("Year","EnGHG")
GHG_hiDRDE_AR$EmGHG<-us_hiDR_FA$GHG_NC*1e-9
GHG_hiDRDE_AR$EmGHG[41]<-GHG_hiDRDE_AR$EmGHG[40]
GHG_hiDRDE_AR$TotGHG<-GHG_hiDRDE_AR$EmGHG+GHG_hiDRDE_AR$EnGHG

GHG_hiDRDE_AR_LREC<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_hiDRDE_all_AR[,185:193])) # emissions in Mt 
GHG_hiDRDE_AR_LREC<-data.frame(data.frame(EnGHG=with(select(GHG_hiDRDE_AR_LREC,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=2,CharScen="C",RenScen="AR",ElecScen="LREC")
names(GHG_hiDRDE_AR_LREC)[1:2]<-c("Year","EnGHG")
GHG_hiDRDE_AR_LREC$EmGHG<-us_hiDR_FA$GHG_NC*1e-9
GHG_hiDRDE_AR_LREC$EmGHG[41]<-GHG_hiDRDE_AR_LREC$EmGHG[40]
GHG_hiDRDE_AR_LREC$TotGHG<-GHG_hiDRDE_AR_LREC$EmGHG+GHG_hiDRDE_AR_LREC$EnGHG

# hi MF
GHG_hiMFDE_RR<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_hiMFDE_all_RR[,176:184])) # emissions in Mt 
GHG_hiMFDE_RR<-data.frame(data.frame(EnGHG=with(select(GHG_hiMFDE_RR,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=3,CharScen="C",RenScen="RR",ElecScen="MC")
names(GHG_hiMFDE_RR)[1:2]<-c("Year","EnGHG")
GHG_hiMFDE_RR$EmGHG<-us_hiMF_FA$GHG_NC*1e-9
GHG_hiMFDE_RR$EmGHG[41]<-GHG_hiMFDE_RR$EmGHG[40]
GHG_hiMFDE_RR$TotGHG<-GHG_hiMFDE_RR$EmGHG+GHG_hiMFDE_RR$EnGHG

GHG_hiMFDE_RR_LREC<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_hiMFDE_all_RR[,185:193])) # emissions in Mt 
GHG_hiMFDE_RR_LREC<-data.frame(data.frame(EnGHG=with(select(GHG_hiMFDE_RR_LREC,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=3,CharScen="C",RenScen="RR",ElecScen="LREC")
names(GHG_hiMFDE_RR_LREC)[1:2]<-c("Year","EnGHG")
GHG_hiMFDE_RR_LREC$EmGHG<-us_hiMF_FA$GHG_NC*1e-9
GHG_hiMFDE_RR_LREC$EmGHG[41]<-GHG_hiMFDE_RR_LREC$EmGHG[40]
GHG_hiMFDE_RR_LREC$TotGHG<-GHG_hiMFDE_RR_LREC$EmGHG+GHG_hiMFDE_RR_LREC$EnGHG

GHG_hiMFDE_AR<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_hiMFDE_all_AR[,176:184])) # emissions in Mt 
GHG_hiMFDE_AR<-data.frame(data.frame(EnGHG=with(select(GHG_hiMFDE_AR,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=3,CharScen="C",RenScen="AR",ElecScen="MC")
names(GHG_hiMFDE_AR)[1:2]<-c("Year","EnGHG")
GHG_hiMFDE_AR$EmGHG<-us_hiMF_FA$GHG_NC*1e-9
GHG_hiMFDE_AR$EmGHG[41]<-GHG_hiMFDE_AR$EmGHG[40]
GHG_hiMFDE_AR$TotGHG<-GHG_hiMFDE_AR$EmGHG+GHG_hiMFDE_AR$EnGHG

GHG_hiMFDE_AR_LREC<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_hiMFDE_all_AR[,185:193])) # emissions in Mt 
GHG_hiMFDE_AR_LREC<-data.frame(data.frame(EnGHG=with(select(GHG_hiMFDE_AR_LREC,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=3,CharScen="C",RenScen="AR",ElecScen="LREC")
names(GHG_hiMFDE_AR_LREC)[1:2]<-c("Year","EnGHG")
GHG_hiMFDE_AR_LREC$EmGHG<-us_hiMF_FA$GHG_NC*1e-9
GHG_hiMFDE_AR_LREC$EmGHG[41]<-GHG_hiMFDE_AR_LREC$EmGHG[40]
GHG_hiMFDE_AR_LREC$TotGHG<-GHG_hiMFDE_AR_LREC$EmGHG+GHG_hiMFDE_AR_LREC$EnGHG

# make graphs of housing stock characteristics using dplyr pipe
rs_baseDE_all_RR[,c("Housing Units 2020","Housing Units 2025","Housing Units 2030","Housing Units 2035","Housing Units 2040","Housing Units 2045","Housing Units 2050","Housing Units 2055","Housing Units 2060")]<-
  rs_baseDE_all_RR$base_weight*rs_baseDE_all_RR[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")]

rs_baseDE_all_AR[,c("Housing Units 2020","Housing Units 2025","Housing Units 2030","Housing Units 2035","Housing Units 2040","Housing Units 2045","Housing Units 2050","Housing Units 2055","Housing Units 2060")]<-
  rs_baseDE_all_AR$base_weight*rs_baseDE_all_AR[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")]


r<-melt(rs_baseDE_all_RR %>% group_by(Heating.Fuel) %>% summarise(across(starts_with("Housing Units"),sum)))
names(r)[2]<-'Year'
r$Year<-gsub('Housing Units ','', r$Year)
r[r$Heating.Fuel %in% c("None","Other Fuel"),]$Heating.Fuel<-"Other/None"
windows(width = 7, height = 6.5)
ggplot(r,aes(Year,1e-6*value,fill=Heating.Fuel)) + geom_col() + theme_bw() +
  labs(title = "c) 1C Baseline Stock Deep Elec Reg Renovation ",  y = "Million Housing Units") + scale_fill_brewer(palette="Dark2")  +
  theme(axis.text=element_text(size=11),axis.title=element_text(size=12,face = "bold"),plot.title = element_text(size = 12))

r<-melt(rs_baseDE_all_AR %>% group_by(Heating.Fuel) %>% summarise(across(starts_with("Housing Units"),sum)))
names(r)[2]<-'Year'
r$Year<-gsub('Housing Units ','', r$Year)
r[r$Heating.Fuel %in% c("None","Other Fuel"),]$Heating.Fuel<-"Other/None"
windows(width = 7, height = 6.5)
ggplot(r,aes(Year,1e-6*value,fill=Heating.Fuel)) + geom_col() + theme_bw() +
  labs(title = "d) 1C Baseline Stock Deep Elec Adv Renovation ",  y = "Million Housing Units") + scale_fill_brewer(palette="Dark2")  +
  theme(axis.text=element_text(size=11),axis.title=element_text(size=12,face = "bold"),plot.title = element_text(size = 12))

# make graphs of housing stock characteristics using dplyr pipe
rs_hiMFDE_all_RR[,c("Housing Units 2020","Housing Units 2025","Housing Units 2030","Housing Units 2035","Housing Units 2040","Housing Units 2045","Housing Units 2050","Housing Units 2055","Housing Units 2060")]<-
  rs_hiMFDE_all_RR$base_weight*rs_hiMFDE_all_RR[,c("whiMF_2020",  "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")]

rs_hiMFDE_all_AR[,c("Housing Units 2020","Housing Units 2025","Housing Units 2030","Housing Units 2035","Housing Units 2040","Housing Units 2045","Housing Units 2050","Housing Units 2055","Housing Units 2060")]<-
  rs_hiMFDE_all_AR$base_weight*rs_hiMFDE_all_AR[,c("whiMF_2020",  "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")]


r<-melt(rs_hiMFDE_all_RR %>% group_by(Heating.Fuel) %>% summarise(across(starts_with("Housing Units"),sum)))
names(r)[2]<-'Year'
r$Year<-gsub('Housing Units ','', r$Year)
r[r$Heating.Fuel %in% c("None","Other Fuel"),]$Heating.Fuel<-"Other/None"
windows(width = 7, height = 6.5)
ggplot(r,aes(Year,1e-6*value,fill=Heating.Fuel)) + geom_col() + theme_bw() +
  labs(title = "e) 3C Hi Multifamily Deep Elec Reg Renovation ",  y = "Million Housing Units") + scale_fill_brewer(palette="Dark2")  +
  theme(axis.text=element_text(size=11),axis.title=element_text(size=12,face = "bold"),plot.title = element_text(size = 12))

r<-melt(rs_hiMFDE_all_AR %>% group_by(Heating.Fuel) %>% summarise(across(starts_with("Housing Units"),sum)))
names(r)[2]<-'Year'
r$Year<-gsub('Housing Units ','', r$Year)
r[r$Heating.Fuel %in% c("None","Other Fuel"),]$Heating.Fuel<-"Other/None"
windows(width = 7, height = 6.5)
ggplot(r,aes(Year,1e-6*value,fill=Heating.Fuel)) + geom_col() + theme_bw() +
  labs(title = "f) 3C Hi Multifamily Deep Elec Adv Renovation ",  y = "Million Housing Units") + scale_fill_brewer(palette="Dark2")  +
  theme(axis.text=element_text(size=11),axis.title=element_text(size=12,face = "bold"),plot.title = element_text(size = 12))

r<-melt(rs_hiMFDE_all_AR %>% filter(Vintage %in% c("2020s","2030s","2040s","2050s")) %>% group_by(Heating.Fuel) %>% summarise(across(starts_with("Housing Units"),sum)))
names(r)[2]<-'Year'
r$Year<-gsub('Housing Units ','', r$Year)
r[r$Heating.Fuel %in% c("None","Other Fuel"),]$Heating.Fuel<-"Other/None"
windows(width = 7, height = 6.5)
ggplot(r,aes(Year,1e-6*value,fill=Heating.Fuel)) + geom_col() + theme_bw() +
  labs(title = "h) 3C Hi Multifamily Deep Elec Adv Renovation, New Housing",  y = "Million Housing Units") + scale_fill_brewer(palette="Dark2")  +
  theme(axis.text=element_text(size=11),axis.title=element_text(size=12,face = "bold"),plot.title = element_text(size = 12))


rm(list=ls(pattern = "rs_"))

# FOURTH DERFA scripts #########
load("../Final_results/res_baseDERFA_RR.RData")
load("../Final_results/res_baseDERFA_AR.RData")
load("../Final_results/res_hiDRDERFA_RR.RData")
load("../Final_results/res_hiDRDERFA_AR.RData")
load("../Final_results/res_hiMFDERFA_RR.RData")
load("../Final_results/res_hiMFDERFA_AR.RData")

GHG_baseDERFA_RR<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_baseDERFA_all_RR[,176:184])) # emissions in Mt 
GHG_baseDERFA_RR<-data.frame(data.frame(EnGHG=with(select(GHG_baseDERFA_RR,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="D",RenScen="RR",ElecScen="MC")
names(GHG_baseDERFA_RR)[1:2]<-c("Year","EnGHG")
GHG_baseDERFA_RR$EmGHG<-us_RFA_FA$GHG_NC*1e-9
GHG_baseDERFA_RR$EmGHG[41]<-GHG_baseDERFA_RR$EmGHG[40]
GHG_baseDERFA_RR$TotGHG<-GHG_baseDERFA_RR$EmGHG+GHG_baseDERFA_RR$EnGHG

GHG_baseDERFA_RR_LREC<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_baseDERFA_all_RR[,185:193])) # emissions in Mt 
GHG_baseDERFA_RR_LREC<-data.frame(data.frame(EnGHG=with(select(GHG_baseDERFA_RR_LREC,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="D",RenScen="RR",ElecScen="LREC")
names(GHG_baseDERFA_RR_LREC)[1:2]<-c("Year","EnGHG")
GHG_baseDERFA_RR_LREC$EmGHG<-us_RFA_FA$GHG_NC*1e-9
GHG_baseDERFA_RR_LREC$EmGHG[41]<-GHG_baseDERFA_RR_LREC$EmGHG[40]
GHG_baseDERFA_RR_LREC$TotGHG<-GHG_baseDERFA_RR_LREC$EmGHG+GHG_baseDERFA_RR_LREC$EnGHG

GHG_baseDERFA_AR<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_baseDERFA_all_AR[,176:184])) # emissions in Mt 
GHG_baseDERFA_AR<-data.frame(data.frame(EnGHG=with(select(GHG_baseDERFA_AR,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="D",RenScen="AR",ElecScen="MC")
names(GHG_baseDERFA_AR)[1:2]<-c("Year","EnGHG")
GHG_baseDERFA_AR$EmGHG<-us_RFA_FA$GHG_NC*1e-9
GHG_baseDERFA_AR$EmGHG[41]<-GHG_baseDERFA_AR$EmGHG[40]
GHG_baseDERFA_AR$TotGHG<-GHG_baseDERFA_AR$EmGHG+GHG_baseDERFA_AR$EnGHG

GHG_baseDERFA_AR_LREC<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_baseDERFA_all_AR[,185:193])) # emissions in Mt 
GHG_baseDERFA_AR_LREC<-data.frame(data.frame(EnGHG=with(select(GHG_baseDERFA_AR_LREC,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=1,CharScen="D",RenScen="AR",ElecScen="LREC")
names(GHG_baseDERFA_AR_LREC)[1:2]<-c("Year","EnGHG")
GHG_baseDERFA_AR_LREC$EmGHG<-us_RFA_FA$GHG_NC*1e-9
GHG_baseDERFA_AR_LREC$EmGHG[41]<-GHG_baseDERFA_AR_LREC$EmGHG[40]
GHG_baseDERFA_AR_LREC$TotGHG<-GHG_baseDERFA_AR_LREC$EmGHG+GHG_baseDERFA_AR_LREC$EnGHG

# hi DR
GHG_hiDRDERFA_RR<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_hiDRDERFA_all_RR[,176:184])) # emissions in Mt 
GHG_hiDRDERFA_RR<-data.frame(data.frame(EnGHG=with(select(GHG_hiDRDERFA_RR,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=2,CharScen="D",RenScen="RR",ElecScen="MC")
names(GHG_hiDRDERFA_RR)[1:2]<-c("Year","EnGHG")
GHG_hiDRDERFA_RR$EmGHG<-us_hiDR_RFA_FA$GHG_NC*1e-9
GHG_hiDRDERFA_RR$EmGHG[41]<-GHG_hiDRDERFA_RR$EmGHG[40]
GHG_hiDRDERFA_RR$TotGHG<-GHG_hiDRDERFA_RR$EmGHG+GHG_hiDRDERFA_RR$EnGHG

GHG_hiDRDERFA_RR_LREC<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_hiDRDERFA_all_RR[,185:193])) # emissions in Mt 
GHG_hiDRDERFA_RR_LREC<-data.frame(data.frame(EnGHG=with(select(GHG_hiDRDERFA_RR_LREC,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=2,CharScen="D",RenScen="RR",ElecScen="LREC")
names(GHG_hiDRDERFA_RR_LREC)[1:2]<-c("Year","EnGHG")
GHG_hiDRDERFA_RR_LREC$EmGHG<-us_hiDR_RFA_FA$GHG_NC*1e-9
GHG_hiDRDERFA_RR_LREC$EmGHG[41]<-GHG_hiDRDERFA_RR_LREC$EmGHG[40]
GHG_hiDRDERFA_RR_LREC$TotGHG<-GHG_hiDRDERFA_RR_LREC$EmGHG+GHG_hiDRDERFA_RR_LREC$EnGHG

GHG_hiDRDERFA_AR<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_hiDRDERFA_all_AR[,176:184])) # emissions in Mt 
GHG_hiDRDERFA_AR<-data.frame(data.frame(EnGHG=with(select(GHG_hiDRDERFA_AR,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=2,CharScen="D",RenScen="AR",ElecScen="MC")
names(GHG_hiDRDERFA_AR)[1:2]<-c("Year","EnGHG")
GHG_hiDRDERFA_AR$EmGHG<-us_hiDR_RFA_FA$GHG_NC*1e-9
GHG_hiDRDERFA_AR$EmGHG[41]<-GHG_hiDRDERFA_AR$EmGHG[40]
GHG_hiDRDERFA_AR$TotGHG<-GHG_hiDRDERFA_AR$EmGHG+GHG_hiDRDERFA_AR$EnGHG

GHG_hiDRDERFA_AR_LREC<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_hiDRDERFA_all_AR[,185:193])) # emissions in Mt 
GHG_hiDRDERFA_AR_LREC<-data.frame(data.frame(EnGHG=with(select(GHG_hiDRDERFA_AR_LREC,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=2,CharScen="D",RenScen="AR",ElecScen="LREC")
names(GHG_hiDRDERFA_AR_LREC)[1:2]<-c("Year","EnGHG")
GHG_hiDRDERFA_AR_LREC$EmGHG<-us_hiDR_RFA_FA$GHG_NC*1e-9
GHG_hiDRDERFA_AR_LREC$EmGHG[41]<-GHG_hiDRDERFA_AR_LREC$EmGHG[40]
GHG_hiDRDERFA_AR_LREC$TotGHG<-GHG_hiDRDERFA_AR_LREC$EmGHG+GHG_hiDRDERFA_AR_LREC$EnGHG

# hi MF
GHG_hiMFDERFA_RR<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_hiMFDERFA_all_RR[,176:184])) # emissions in Mt 
GHG_hiMFDERFA_RR<-data.frame(data.frame(EnGHG=with(select(GHG_hiMFDERFA_RR,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=3,CharScen="D",RenScen="RR",ElecScen="MC")
names(GHG_hiMFDERFA_RR)[1:2]<-c("Year","EnGHG")
GHG_hiMFDERFA_RR$EmGHG<-us_hiMF_RFA_FA$GHG_NC*1e-9
GHG_hiMFDERFA_RR$EmGHG[41]<-GHG_hiMFDERFA_RR$EmGHG[40]
GHG_hiMFDERFA_RR$TotGHG<-GHG_hiMFDERFA_RR$EmGHG+GHG_hiMFDERFA_RR$EnGHG

GHG_hiMFDERFA_RR_LREC<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_hiMFDERFA_all_RR[,185:193])) # emissions in Mt 
GHG_hiMFDERFA_RR_LREC<-data.frame(data.frame(EnGHG=with(select(GHG_hiMFDERFA_RR_LREC,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=3,CharScen="D",RenScen="RR",ElecScen="LREC")
names(GHG_hiMFDERFA_RR_LREC)[1:2]<-c("Year","EnGHG")
GHG_hiMFDERFA_RR_LREC$EmGHG<-us_hiMF_RFA_FA$GHG_NC*1e-9
GHG_hiMFDERFA_RR_LREC$EmGHG[41]<-GHG_hiMFDERFA_RR_LREC$EmGHG[40]
GHG_hiMFDERFA_RR_LREC$TotGHG<-GHG_hiMFDERFA_RR_LREC$EmGHG+GHG_hiMFDERFA_RR_LREC$EnGHG

GHG_hiMFDERFA_AR<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_hiMFDERFA_all_AR[,176:184])) # emissions in Mt 
GHG_hiMFDERFA_AR<-data.frame(data.frame(EnGHG=with(select(GHG_hiMFDERFA_AR,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=3,CharScen="D",RenScen="AR",ElecScen="MC")
names(GHG_hiMFDERFA_AR)[1:2]<-c("Year","EnGHG")
GHG_hiMFDERFA_AR$EmGHG<-us_hiMF_RFA_FA$GHG_NC*1e-9
GHG_hiMFDERFA_AR$EmGHG[41]<-GHG_hiMFDERFA_AR$EmGHG[40]
GHG_hiMFDERFA_AR$TotGHG<-GHG_hiMFDERFA_AR$EmGHG+GHG_hiMFDERFA_AR$EnGHG

GHG_hiMFDERFA_AR_LREC<-data.frame(Year=seq(2020,2060,5),EnGHG=1e-9*colSums(rs_hiMFDERFA_all_AR[,185:193])) # emissions in Mt 
GHG_hiMFDERFA_AR_LREC<-data.frame(data.frame(EnGHG=with(select(GHG_hiMFDERFA_AR_LREC,Year,EnGHG),spline(Year,EnGHG,xout = 2020:2060)),method="spline()")[,1:2],StockScen=3,CharScen="D",RenScen="AR",ElecScen="LREC")
names(GHG_hiMFDERFA_AR_LREC)[1:2]<-c("Year","EnGHG")
GHG_hiMFDERFA_AR_LREC$EmGHG<-us_hiMF_RFA_FA$GHG_NC*1e-9
GHG_hiMFDERFA_AR_LREC$EmGHG[41]<-GHG_hiMFDERFA_AR_LREC$EmGHG[40]
GHG_hiMFDERFA_AR_LREC$TotGHG<-GHG_hiMFDERFA_AR_LREC$EmGHG+GHG_hiMFDERFA_AR_LREC$EnGHG

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


OldOilGHG_hiMFDERFA_AR<-data.frame(Year=seq(2020,2060,5),OilGHG=colSums(rs_hiMFDERFA_all_AR[,196:204])*1e-9)
NewOilGHG_hiMFDERFA_AR<-data.frame(Year=seq(2020,2060,5),OilGHG=colSums(rs_hiMFDERFA_all_AR[,205:213])*1e-9)
OldGasGHG_hiMFDERFA_AR<-data.frame(Year=seq(2020,2060,5),GasGHG=colSums(rs_hiMFDERFA_all_AR[,214:222])*1e-9)
NewGasGHG_hiMFDERFA_AR<-data.frame(Year=seq(2020,2060,5),GasGHG=colSums(rs_hiMFDERFA_all_AR[,223:231])*1e-9)
OldElecGHG_hiMFDERFA_AR<-data.frame(Year=seq(2020,2060,5),ElecGHG=colSums(rs_hiMFDERFA_all_AR[,232:240])*1e-9)
NewElecGHG_hiMFDERFA_AR<-data.frame(Year=seq(2020,2060,5),ElecGHG=colSums(rs_hiMFDERFA_all_AR[,241:249])*1e-9)


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

OldElecGHG_hiMFDERFA_AR_LREC<-data.frame(Year=seq(2020,2060,5),ElecGHG=colSums(rs_hiMFDERFA_all_AR[,250:258])*1e-9)
NewElecGHG_hiMFDERFA_AR_LREC<-data.frame(Year=seq(2020,2060,5),ElecGHG=colSums(rs_hiMFDERFA_all_AR[,259:267])*1e-9)

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

rm(list=ls(pattern = "rs_"))


GHGall<-data.frame(matrix(ncol = 8,nrow=0))
names(GHGall)<-names(GHG_base_AR)
for (a in 1:length(ls(pattern = "GHG_"))) {x<-get(ls(pattern = "GHG_")[a]);GHGall<-rbind(GHGall,x[,1:8])}
GHGall$Housing_Scenario<-"1A Baseline"
GHGall[GHGall$StockScen==1 & GHGall$CharScen=="B",] $Housing_Scenario<-"1B Baseline RFA"
GHGall[GHGall$StockScen==1 & GHGall$CharScen=="C",] $Housing_Scenario<-"1C Baseline DE"
GHGall[GHGall$StockScen==1 & GHGall$CharScen=="D",] $Housing_Scenario<-"1D Baseline DE & RFA"

GHGall[GHGall$StockScen==2 & GHGall$CharScen=="A",] $Housing_Scenario<-"2A High Turnover"
GHGall[GHGall$StockScen==2 & GHGall$CharScen=="B",] $Housing_Scenario<-"2B High Turnover RFA"
GHGall[GHGall$StockScen==2 & GHGall$CharScen=="C",] $Housing_Scenario<-"2C High Turnover DE"
GHGall[GHGall$StockScen==2 & GHGall$CharScen=="D",] $Housing_Scenario<-"2D High Turnover DE & RFA"

GHGall[GHGall$StockScen==3 & GHGall$CharScen=="A",] $Housing_Scenario<-"3A High Multifamily"
GHGall[GHGall$StockScen==3 & GHGall$CharScen=="B",] $Housing_Scenario<-"3B High Multifamily RFA"
GHGall[GHGall$StockScen==3 & GHGall$CharScen=="C",] $Housing_Scenario<-"3C High Multifamily DE"
GHGall[GHGall$StockScen==3 & GHGall$CharScen=="D",] $Housing_Scenario<-"3D High Multifamily DE & RFA"

GHGall$StockScen<-as.character(GHGall$StockScen)

GHGall$CharScenario<-"A. Base"
GHGall[GHGall$CharScen=="B",]$CharScenario<-"B. RFA"
GHGall[GHGall$CharScen=="C",]$CharScenario<-"C. DE"
GHGall[GHGall$CharScen=="D",]$CharScenario<-"D. RFA + DE"

GHGall$StockScenario<-"1 Baseline"
GHGall[GHGall$StockScen=="2",]$StockScenario<-"2 Hi Turnover"
GHGall[GHGall$StockScen=="3",]$StockScenario<-"3 Hi Multifamily"

save(GHGall,file="../Final_results/GHGall.RData")

ghg_MC_RR<-GHGall[GHGall$ElecScen=="MC" & GHGall$RenScen=="RR",]

pdf<-data.frame(xa=2050,ya=330) # 20% of 2005 emissions (1.65 Gt total from residential sector energy + construction). Based on US GHGI plus Berrill et al JIE 
odf<-data.frame(xa=2030,ya=450) # 50% of 2020 emissions based on this study
hdf<-data.frame(xa=2030,ya=808) # 49% of 2005 emissions (1.65 Gt total from residential sector energy + construction). Based on US GHGI plus Berrill et al JIE 

windows(width = 9.2,height = 7.5)
ggplot(ghg_MC_RR,aes(Year,TotGHG,group=Housing_Scenario)) + geom_line(aes(color=CharScenario,linetype=StockScenario),size=1.1,alpha=0.7) + scale_y_continuous(labels = scales::comma,limits = c(250,1000)) +
  geom_segment(aes(x=2048,xend=2052,y=330,yend=330),linetype="dashed") + geom_text(x=2050, y=310, label="Paris 2050 Target") + geom_point(data=pdf,aes(x=xa,y=ya,group=1)) +
  geom_segment(aes(x=2028,xend=2032,y=450,yend=450),linetype="dashed") + geom_text(x=2030, y=430, label="1.5°C  Target") + geom_point(data=odf,aes(x=xa,y=ya,group=1)) +
  geom_segment(aes(x=2028,xend=2032,y=808,yend=808),linetype="dashed") + geom_text(x=2023.5, y=788, label="49% 2030  Target") + geom_point(data=hdf,aes(x=xa,y=ya,group=1)) +
  labs(title ="a) Mid-Case Electricity, Regular Renovation",y="Mton CO2e") + theme_bw() + 
  # scale_color_brewer(palette="Set1")  + scale_linetype_manual(values=c("solid","dotted","dashed")) +
  scale_color_manual(values=c('black','red','orange3','blue'))  + scale_linetype_manual(values=c("solid","dotted","dashed")) +
  theme(axis.text=element_text(size=11),axis.title=element_text(size=12,face = "bold"),plot.title = element_text(size = 12),legend.key.width = unit(1,'cm'))

ghg_MC_AR<-GHGall[GHGall$ElecScen=="MC" & GHGall$RenScen=="AR",]
windows(width = 9.2,height = 7.5)
ggplot(ghg_MC_AR,aes(Year,TotGHG,group=Housing_Scenario)) + geom_line(aes(color=CharScenario,linetype=StockScenario),size=1.1,alpha=0.7) + scale_y_continuous(labels = scales::comma,limits = c(250,1000)) +
  geom_segment(aes(x=2048,xend=2052,y=330,yend=330),linetype="dashed") + geom_text(x=2050, y=310, label="Paris 2050 Target") + geom_point(data=pdf,aes(x=xa,y=ya,group=1)) +
  geom_segment(aes(x=2028,xend=2032,y=450,yend=450),linetype="dashed") + geom_text(x=2030, y=430, label="1.5°C  Target") + geom_point(data=odf,aes(x=xa,y=ya,group=1)) +
  geom_segment(aes(x=2028,xend=2032,y=808,yend=808),linetype="dashed") + geom_text(x=2023.5, y=788, label="49% 2030  Target") + geom_point(data=hdf,aes(x=xa,y=ya,group=1)) +
  labs(title ="b) Mid-Case Electricity, Advanced Renovation",y="Mton CO2e") + theme_bw() + 
  # scale_color_brewer(palette="Set1")  + scale_linetype_manual(values=c("solid","dotted","dashed")) +
  scale_color_manual(values=c('black','red','orange3','blue'))  + scale_linetype_manual(values=c("solid","dotted","dashed")) +
  theme(axis.text=element_text(size=11),axis.title=element_text(size=12,face = "bold"),plot.title = element_text(size = 12),legend.key.width = unit(1,'cm'))

ghg_LRE_RR<-GHGall[GHGall$ElecScen=="LREC" & GHGall$RenScen=="RR",]
windows(width = 9.2,height = 7.5)
ggplot(ghg_LRE_RR,aes(Year,TotGHG,group=Housing_Scenario)) + geom_line(aes(color=CharScenario,linetype=StockScenario),size=1.1,alpha=0.7) + scale_y_continuous(labels = scales::comma,limits = c(250,1000)) +
  geom_segment(aes(x=2048,xend=2052,y=330,yend=330),linetype="dashed") + geom_text(x=2050, y=310, label="Paris 2050 Target") + geom_point(data=pdf,aes(x=xa,y=ya,group=1)) +
  geom_segment(aes(x=2028,xend=2032,y=808,yend=808),linetype="dashed") + geom_text(x=2035, y=788, label="49% 2030  Target") + geom_point(data=hdf,aes(x=xa,y=ya,group=1)) +
  geom_segment(aes(x=2028,xend=2032,y=450,yend=450),linetype="dashed") + geom_text(x=2030, y=430, label="1.5°C  Target") + geom_point(data=odf,aes(x=xa,y=ya,group=1)) +
  labs(title ="c) Low RE Cost Electricity, Regular Renovation, 2020-2060",y="Mton CO2e") + theme_bw() + 
  scale_color_manual(values=c('black','red','orange3','blue'))  + scale_linetype_manual(values=c("solid","dotted","dashed")) +
  theme(axis.text=element_text(size=11),axis.title=element_text(size=12,face = "bold"),plot.title = element_text(size = 12),legend.key.width = unit(1,'cm'))

ghg_LRE_AR<-GHGall[GHGall$ElecScen=="LREC" & GHGall$RenScen=="AR",]
windows(width = 9.2,height = 7.5)
ggplot(ghg_LRE_AR,aes(Year,TotGHG,group=Housing_Scenario)) + geom_line(aes(color=CharScenario,linetype=StockScenario),size=1.1,alpha=0.7) + scale_y_continuous(labels = scales::comma,limits = c(250,1000)) +
  geom_segment(aes(x=2048,xend=2052,y=330,yend=330),linetype="dashed") + geom_text(x=2046, y=310, label="Paris 2050 Target") + geom_point(data=pdf,aes(x=xa,y=ya,group=1)) +
  geom_segment(aes(x=2028,xend=2032,y=450,yend=450),linetype="dashed") + geom_text(x=2030, y=430, label="1.5°C  Target") + geom_point(data=odf,aes(x=xa,y=ya,group=1)) +
  geom_segment(aes(x=2028,xend=2032,y=808,yend=808),linetype="dashed") + geom_text(x=2035, y=788, label="49% 2030  Target") + geom_point(data=hdf,aes(x=xa,y=ya,group=1)) +
  labs(title ="d) Low RE Cost Electricity, Advanced Renovation",y="Mton CO2e") + theme_bw() + 
  scale_color_manual(values=c('black','red','orange3','blue'))  + scale_linetype_manual(values=c("solid","dotted","dashed")) +
  theme(axis.text=element_text(size=11),axis.title=element_text(size=12,face = "bold"),plot.title = element_text(size = 12),legend.key.width = unit(1,'cm'))

# just for the legend
windows(width = 50,height =10)
ggplot(ghg_LRE_AR,aes(Year,TotGHG,group=Housing_Scenario)) + geom_line(aes(color=CharScenario,linetype=StockScenario),size=1,alpha=0.65) + scale_y_continuous(labels = scales::comma,limits = c(250,1000)) +
  geom_segment(aes(x=2048,xend=2052,y=330,yend=330),linetype="dashed") + geom_text(x=2050, y=310, label="Paris 2050 Target") + geom_point(data=pdf,aes(x=xa,y=ya,group=1)) +
  geom_segment(aes(x=2028,xend=2032,y=450,yend=450),linetype="dashed") + geom_text(x=2030, y=430, label="1.5°C  Target") + geom_point(data=odf,aes(x=xa,y=ya,group=1)) +
  labs(title ="a) Total annual residential GHG emissions, 2020-2060",y="Mton CO2e",subtitle = "Low RE Cost Electricity, Advanced Renovation") + theme_bw() + 
  scale_color_manual(values=c('black','red','orange3','blue'))  + scale_linetype_manual(values=c("solid","dotted","dashed")) +
  theme(axis.text=element_text(size=11),axis.title=element_text(size=12,face = "bold"),plot.title = element_text(size = 12, face = "bold"),
        legend.key.width = unit(1,'cm'),legend.key.size = unit(1,'cm'),legend.key.height = unit(2,'cm'), legend.position = "bottom",legend.text =  element_text(size = 12),legend.title =  element_text(size = 12))


cum_emission<-tapply(GHGall$TotGHG,list(GHGall$Housing_Scenario,GHGall$RenScen,GHGall$ElecScen),sum)

summary(lm(GHGall$TotGHG~GHGall$ElecScen)) # 115.6 annually, 4.6Gt over 40 years

cem<-melt(cum_emission)

# now differenecs between cumulative emissions for a area or cascade chart

GHG_base_NR[,c("Housing_Scenario","CharScenario","StockScenario")]<-rep(c("No Renovation","A. Base","1 Baseline"),each=41)
GHG_base_NR_G20[,c("Housing_Scenario","CharScenario","StockScenario")]<-rep(c("No Ren., 2020 Elec Grid","A. Base","1 Baseline"),each=41)

GHGall<-rbind(GHGall,GHG_base_NR,GHG_base_NR_G20)

GHGdff<-rbind(GHGall[GHGall$StockScen==1&GHGall$CharScen=="A"&GHGall$ElecScen=="G20"&GHGall$RenScen=="NR",],
              GHGall[GHGall$StockScen==1&GHGall$CharScen=="A"&GHGall$ElecScen=="MC"&GHGall$RenScen=="NR",], # Mid-Case Elec
              GHGall[GHGall$StockScen==1&GHGall$CharScen=="A"&GHGall$ElecScen=="MC"&GHGall$RenScen=="RR",], # Reg Ren
              GHGall[GHGall$StockScen==1&GHGall$CharScen=="A"&GHGall$ElecScen=="LREC"&GHGall$RenScen=="RR",], # LREC
              GHGall[GHGall$StockScen==1&GHGall$CharScen=="A"&GHGall$ElecScen=="LREC"&GHGall$RenScen=="AR",], # AR
              GHGall[GHGall$StockScen==1&GHGall$CharScen=="B"&GHGall$ElecScen=="LREC"&GHGall$RenScen=="AR",], # RFA
              GHGall[GHGall$StockScen==3&GHGall$CharScen=="B"&GHGall$ElecScen=="LREC"&GHGall$RenScen=="AR",], # hiMF
              GHGall[GHGall$StockScen==3&GHGall$CharScen=="D"&GHGall$ElecScen=="LREC"&GHGall$RenScen=="AR",]) # DE RFA
GHGdff$DiffGHG<-GHGdff$TotGHG

GHGdff[GHGdff$ElecScen=="G20"&GHGdff$RenScen=="NR"&GHGdff$CharScen=="A" & GHGdff$StockScen==1,]$DiffGHG<- # diff G20 and MC
  GHGdff[GHGdff$ElecScen=="G20"&GHGdff$RenScen=="NR"&GHGdff$CharScen=="A" & GHGdff$StockScen==1,]$DiffGHG-GHGdff[GHGdff$ElecScen=="MC"&GHGdff$RenScen=="NR"&GHGdff$CharScen=="A" & GHGdff$StockScen==1,]$DiffGHG
GHGdff[GHGdff$ElecScen=="MC"&GHGdff$RenScen=="NR"&GHGdff$CharScen=="A" & GHGdff$StockScen==1,]$DiffGHG<- # diff NR and RR
  GHGdff[GHGdff$ElecScen=="MC"&GHGdff$RenScen=="NR"&GHGdff$CharScen=="A" & GHGdff$StockScen==1,]$DiffGHG-GHGdff[GHGdff$ElecScen=="MC"&GHGdff$RenScen=="RR"&GHGdff$CharScen=="A" & GHGdff$StockScen==1,]$DiffGHG
GHGdff[GHGdff$ElecScen=="MC"&GHGdff$RenScen=="RR"&GHGdff$CharScen=="A" & GHGdff$StockScen==1,]$DiffGHG<- # diff between MC and LREC
  GHGdff[GHGdff$ElecScen=="MC"&GHGdff$RenScen=="RR"&GHGdff$CharScen=="A" & GHGdff$StockScen==1,]$DiffGHG-GHGdff[GHGdff$ElecScen=="LREC"&GHGdff$RenScen=="RR"&GHGdff$CharScen=="A" & GHGdff$StockScen==1,]$DiffGHG
GHGdff[GHGdff$ElecScen=="LREC"&GHGdff$RenScen=="RR"&GHGdff$CharScen=="A" & GHGdff$StockScen==1,]$DiffGHG<- # diff between RR and AR
  GHGdff[GHGdff$ElecScen=="LREC"&GHGdff$RenScen=="RR"&GHGdff$CharScen=="A" & GHGdff$StockScen==1,]$DiffGHG-GHGdff[GHGdff$ElecScen=="LREC"&GHGdff$RenScen=="AR"&GHGdff$CharScen=="A" & GHGdff$StockScen==1,]$DiffGHG
GHGdff[GHGdff$ElecScen=="LREC"&GHGdff$RenScen=="AR"&GHGdff$CharScen=="A" & GHGdff$StockScen==1,]$DiffGHG<- # diff between BaseChar and RFA
  GHGdff[GHGdff$ElecScen=="LREC"&GHGdff$RenScen=="AR"&GHGdff$CharScen=="A" & GHGdff$StockScen==1,]$DiffGHG-GHGdff[GHGdff$ElecScen=="LREC"&GHGdff$RenScen=="AR"&GHGdff$CharScen=="B" & GHGdff$StockScen==1,]$DiffGHG
GHGdff[GHGdff$ElecScen=="LREC"&GHGdff$RenScen=="AR"&GHGdff$CharScen=="B" & GHGdff$StockScen==1,]$DiffGHG<- # diff between Baseline stock and hiMF
  GHGdff[GHGdff$ElecScen=="LREC"&GHGdff$RenScen=="AR"&GHGdff$CharScen=="B" & GHGdff$StockScen==1,]$DiffGHG-GHGdff[GHGdff$ElecScen=="LREC"&GHGdff$RenScen=="AR"&GHGdff$CharScen=="B" & GHGdff$StockScen==3,]$DiffGHG
GHGdff[GHGdff$ElecScen=="LREC"&GHGdff$RenScen=="AR"&GHGdff$CharScen=="B" & GHGdff$StockScen==3,]$DiffGHG<- # diff between RFA and DE RFA
  GHGdff[GHGdff$ElecScen=="LREC"&GHGdff$RenScen=="AR"&GHGdff$CharScen=="B" & GHGdff$StockScen==3,]$DiffGHG-GHGdff[GHGdff$ElecScen=="LREC"&GHGdff$RenScen=="AR"&GHGdff$CharScen=="D" & GHGdff$StockScen==3,]$DiffGHG

# GHGdff[GHGdff$ElecScen=="LREC"&GHGdff$RenScen=="RR",]$DiffGHG<-GHGdff[GHGdff$ElecScen=="LREC"&GHGdff$RenScen=="RR",]$TotGHG-GHGdff[GHGdff$ElecScen=="LREC"&GHGdff$RenScen=="AR",]$TotGHG

GHGdff$Strategy<-"6. Residual Emissions" # Emissions in the most optimistic case.
GHGdff[GHGdff$ElecScen=="G20"&GHGdff$RenScen=="NR"&GHGdff$CharScen=="A" & GHGdff$StockScen==1,]$Strategy<-"0. Mid-Case Elec Grid" #  the differences between No Ren and Reg Ren
GHGdff[GHGdff$ElecScen=="MC"&GHGdff$RenScen=="NR"&GHGdff$CharScen=="A" & GHGdff$StockScen==1,]$Strategy<-"0. Reg Renovation" #  the differences between No Ren and Reg Ren
GHGdff[GHGdff$ElecScen=="MC"&GHGdff$RenScen=="RR"&GHGdff$CharScen=="A" & GHGdff$StockScen==1,]$Strategy<-"1. LREC Elec Grid" #  the differences between MC Elec and LREC elec
GHGdff[GHGdff$ElecScen=="LREC"&GHGdff$RenScen=="RR"&GHGdff$CharScen=="A" & GHGdff$StockScen==1,]$Strategy<-"2. Adv Renovation" # the difference between LREC RR, and LREC AR
GHGdff[GHGdff$ElecScen=="LREC"&GHGdff$RenScen=="AR"&GHGdff$CharScen=="A" & GHGdff$StockScen==1,]$Strategy<-"3. Reduced Floor Area" # the difference between LREC AR, and LREC AR RFA
GHGdff[GHGdff$ElecScen=="LREC"&GHGdff$RenScen=="AR"&GHGdff$CharScen=="B" & GHGdff$StockScen==1,]$Strategy<-"4. High Multifamily" # the difference between LREC AR RFA, and LREC AR RFA hi MF
GHGdff[GHGdff$ElecScen=="LREC"&GHGdff$RenScen=="AR"&GHGdff$CharScen=="B" & GHGdff$StockScen==3,]$Strategy<-"5. Deep Electrification" # the difference between LREC AR RFA hiMF, and LREC AR DE RFA hi MF

windows(width = 7.5,height = 5.5)
ggplot(GHGdff,aes(Year,DiffGHG,fill=Strategy))+geom_area() + scale_y_continuous(breaks = seq(0,1200,200)) +
  labs(title ="GHG reduction potential by sequential strategy adoption",y="Mton CO2e") + theme_bw() + 
  scale_fill_brewer(palette="Dark2")  +
  theme(axis.text=element_text(size=11),axis.title=element_text(size=12, face = "bold"),plot.title = element_text(size = 12, face = "bold"),
        legend.key.width = unit(1,'cm'),legend.text =  element_text(size = 10))

# add lines for particular scenarios
# GHG_base_NR$Housing_Scenario<-"No Renovation"
# GHG_base_NR_G20$Housing_Scenario<-"No Renovation, No Decarbonization"

GHGln<-rbind(GHGall[GHGall$StockScen==1&GHGall$CharScen=="A"&GHGall$ElecScen=="MC"&GHGall$RenScen=="RR",],
             GHGall[GHGall$StockScen==3&GHGall$CharScen=="D"&GHGall$ElecScen=="LREC"&GHGall$RenScen=="AR",],
             GHGall[GHGall$StockScen==1&GHGall$CharScen=="A"&GHGall$ElecScen=="G20"&GHGall$RenScen=="NR",]) # DE RFA
GHGln$Scenario<-GHGln$Housing_Scenario
GHGln[GHGln$Housing_Scenario=="1A Baseline",]$Scenario<-"1A Baseline, RR, Mid-Case Elec"
GHGln[GHGln$Housing_Scenario=="3D High Multifamily DE & RFA",]$Scenario<-"3D High Multifamily DE & RFA, AR, LREC Elec"
GHGln[GHGln$Housing_Scenario=="No Ren., 2020 Elec Grid",]$Scenario<-"1A Baseline, NR, 2020 Elec"


colarea<-c("#D5D6DE","8D8E91",colorRampPalette(brewer.pal(6,"Dark2"))(6)[1:5],"#FFFFFF")
colln<-colorRampPalette(brewer.pal(4,"Set1"))(2)
colln<-c('tan4','black','blue')
windows(width = 7.5,height = 5.5)
ggplot() + geom_area(data=GHGdff,aes(Year,DiffGHG,fill=Strategy)) + geom_line(data=GHGln,aes(Year,TotGHG,color=Scenario),size=1.1,linetype="longdash") + scale_y_continuous(breaks = seq(0,1200,200),limits = c(0,1000)) +
  labs(title ="GHG reduction potential by sequential strategy adoption",y="Mton CO2e") + theme_classic() + 
  scale_fill_manual(values=colarea)  + scale_color_manual(values=colln) +
  theme(axis.text=element_text(size=11),axis.title=element_text(size=12, face = "bold"),plot.title = element_text(size = 12, face = "bold"),
        legend.key.width = unit(1,'cm'),legend.text =  element_text(size = 10))


# Emissions from construction, and fuel use in new and old construction
g_base_RR<-melt(GHG_base_RR[,-c(2,8)],id.vars = c("Year","StockScen","CharScen","RenScen","ElecScen"))
names(g_base_RR)[6:7]<-c("Var","GHG")
g_base_RR$Source<-g_base_RR$Var
levels(g_base_RR$Source)<-list("Construction" = "EmGHG","Oil <2020"="OldOilGHG","Oil >2020" = "NewOilGHG",
                               "Gas <2020"="OldGasGHG","Gas >2020" = "NewGasGHG",
                               "Elec <2020"="OldElecGHG","Elec >2020" = "NewElecGHG")
g_base_RR$Source<-factor(g_base_RR$Source,levels=rev(levels(g_base_RR$Source)))

g_base_RR_LREC<-melt(GHG_base_RR_LREC[,-c(2,8)],id.vars = c("Year","StockScen","CharScen","RenScen","ElecScen"))
names(g_base_RR_LREC)[6:7]<-c("Var","GHG")
g_base_RR_LREC$Source<-g_base_RR_LREC$Var
levels(g_base_RR_LREC$Source)<-list("Construction" = "EmGHG","Oil <2020"="OldOilGHG","Oil >2020" = "NewOilGHG",
                               "Gas <2020"="OldGasGHG","Gas >2020" = "NewGasGHG",
                               "Elec <2020"="OldElecGHG","Elec >2020" = "NewElecGHG")
g_base_RR_LREC$Source<-factor(g_base_RR_LREC$Source,levels=rev(levels(g_base_RR_LREC$Source)))

g_hiDR_RR<-melt(GHG_hiDR_RR[,-c(2,8)],id.vars = c("Year","StockScen","CharScen","RenScen","ElecScen"))
names(g_hiDR_RR)[6:7]<-c("Var","GHG")
g_hiDR_RR$Source<-g_hiDR_RR$Var
levels(g_hiDR_RR$Source)<-list("Construction" = "EmGHG","Oil <2020"="OldOilGHG","Oil >2020" = "NewOilGHG",
                               "Gas <2020"="OldGasGHG","Gas >2020" = "NewGasGHG",
                               "Elec <2020"="OldElecGHG","Elec >2020" = "NewElecGHG")
g_hiDR_RR$Source<-factor(g_hiDR_RR$Source,levels=rev(levels(g_hiDR_RR$Source)))

g_hiDR_RR_LREC<-melt(GHG_hiDR_RR_LREC[,-c(2,8)],id.vars = c("Year","StockScen","CharScen","RenScen","ElecScen"))
names(g_hiDR_RR_LREC)[6:7]<-c("Var","GHG")
g_hiDR_RR_LREC$Source<-g_hiDR_RR_LREC$Var
levels(g_hiDR_RR_LREC$Source)<-list("Construction" = "EmGHG","Oil <2020"="OldOilGHG","Oil >2020" = "NewOilGHG",
                                    "Gas <2020"="OldGasGHG","Gas >2020" = "NewGasGHG",
                                    "Elec <2020"="OldElecGHG","Elec >2020" = "NewElecGHG")
g_hiDR_RR_LREC$Source<-factor(g_hiDR_RR_LREC$Source,levels=rev(levels(g_hiDR_RR_LREC$Source)))


g_hiMFDERFA_AR<-melt(GHG_hiMFDERFA_AR[,-c(2,8)],id.vars = c("Year","StockScen","CharScen","RenScen","ElecScen"))
names(g_hiMFDERFA_AR)[6:7]<-c("Var","GHG")
g_hiMFDERFA_AR$Source<-g_hiMFDERFA_AR$Var
levels(g_hiMFDERFA_AR$Source)<-list("Construction" = "EmGHG","Oil <2020"="OldOilGHG","Oil >2020" = "NewOilGHG",
                               "Gas <2020"="OldGasGHG","Gas >2020" = "NewGasGHG",
                               "Elec <2020"="OldElecGHG","Elec >2020" = "NewElecGHG")
g_hiMFDERFA_AR$Source<-factor(g_hiMFDERFA_AR$Source,levels=rev(levels(g_hiMFDERFA_AR$Source)))

g_hiMFDERFA_AR_LREC<-melt(GHG_hiMFDERFA_AR_LREC[,-c(2,8)],id.vars = c("Year","StockScen","CharScen","RenScen","ElecScen"))
names(g_hiMFDERFA_AR_LREC)[6:7]<-c("Var","GHG")
g_hiMFDERFA_AR_LREC$Source<-g_hiMFDERFA_AR_LREC$Var
levels(g_hiMFDERFA_AR_LREC$Source)<-list("Construction" = "EmGHG","Oil <2020"="OldOilGHG","Oil >2020" = "NewOilGHG",
                                    "Gas <2020"="OldGasGHG","Gas >2020" = "NewGasGHG",
                                    "Elec <2020"="OldElecGHG","Elec >2020" = "NewElecGHG")
g_hiMFDERFA_AR_LREC$Source<-factor(g_hiMFDERFA_AR_LREC$Source,levels=rev(levels(g_hiMFDERFA_AR_LREC$Source)))

save(g_base_RR,g_base_RR_LREC,g_hiMFDERFA_AR,g_hiMFDERFA_AR_LREC,file="../Final_results/GHG_Source.RData")


windows(width = 8,height = 7)
ggplot(g_base_RR,aes(Year,GHG,fill=Source)) + geom_bar(position="stack", stat="identity") +
  labs(title ="a) Baseline Stock and Characteristics (1A), Reg Ren, MC Electricity",y="Mton CO2e") + theme_bw() + 
  scale_fill_brewer(palette="Dark2")  +
  theme(axis.text=element_text(size=11),axis.title=element_text(size=12, face = "bold"),plot.title = element_text(size = 12))

windows(width = 8,height = 7)
ggplot(g_base_RR_LREC,aes(Year,GHG,fill=Source)) + geom_bar(position="stack", stat="identity") +
  labs(title ="b) Baseline Stock and Characteristics (1A), Reg Ren, LREC Electricity",y="Mton CO2e") + theme_bw() + 
  scale_fill_brewer(palette="Dark2")  +
  theme(axis.text=element_text(size=11),axis.title=element_text(size=12, face = "bold"),plot.title = element_text(size = 12))

windows(width = 8,height = 7)
ggplot(g_hiMFDERFA_AR,aes(Year,GHG,fill=Source)) + geom_bar(position="stack", stat="identity") +
  labs(title ="e) Hi MF Deep Elec & Reduced FA (3D), Adv Ren, MC Electricity",y="Mton CO2e") + theme_bw() + 
  scale_fill_brewer(palette="Dark2")  +
  theme(axis.text=element_text(size=11),axis.title=element_text(size=12, face = "bold"),plot.title = element_text(size = 12))

windows(width = 8,height = 7)
ggplot(g_hiMFDERFA_AR_LREC,aes(Year,GHG,fill=Source)) + geom_bar(position="stack", stat="identity") +
  labs(title ="f) Hi MF Deep Elec & Reduced FA (3D), Adv Ren, LREC Electricity",y="Mton CO2e") + theme_bw() + 
  scale_fill_brewer(palette="Dark2")  +
  theme(axis.text=element_text(size=11),axis.title=element_text(size=12, face = "bold"),plot.title = element_text(size = 12))

windows(width = 8,height = 7)
ggplot(g_hiDR_RR,aes(Year,GHG,fill=Source)) + geom_bar(position="stack", stat="identity") +
  labs(title ="c) Hi Turnover (2A), Reg Ren, MC Electricity",y="Mton CO2e") + theme_bw() + 
  scale_fill_brewer(palette="Dark2")  +
  theme(axis.text=element_text(size=11),axis.title=element_text(size=12, face = "bold"),plot.title = element_text(size = 12))

windows(width = 8,height = 7)
ggplot(g_hiDR_RR_LREC,aes(Year,GHG,fill=Source)) + geom_bar(position="stack", stat="identity") +
  labs(title ="d) Hi Turnover (2A), Reg Ren, LREC Electricity",y="Mton CO2e") + theme_bw() + 
  scale_fill_brewer(palette="Dark2")  +
  theme(axis.text=element_text(size=11),axis.title=element_text(size=12, face = "bold"),plot.title = element_text(size = 12))
