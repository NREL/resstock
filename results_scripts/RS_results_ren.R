# RS results interpretation 
# This script reads in the results csv and uses it to calculate energy consumption by fuel and end use
rm(list=ls()) # clear workspace i.e. remove saved variables
cat("\014") # clear console
library(dplyr)
library(reshape2)
setwd("~/Yale Courses/Research/Final Paper/resstock_projections/")
# import ResStock results csvs
# 2020 base stock
load("Eagle_outputs/Complete_results/res_2020_final.RData")
rs2020<-rsn; rm(rsn)
# Regular Renovated (RR) 2020 stock in each sim year
load("Eagle_outputs/Complete_results/res_RR_2025_final.RData")
rs25RR<-rsn; rm(rsn)
load("Eagle_outputs/Complete_results/res_RR_2030_final.RData")
rs30RR<-rsn; rm(rsn)
load("Eagle_outputs/Complete_results/res_RR_2035_final.RData")
rs35RR<-rsn; rm(rsn)
load("Eagle_outputs/Complete_results/res_RR_2040_final.RData")
rs40RR<-rsn; rm(rsn)
load("Eagle_outputs/Complete_results/res_RR_2045_final.RData")
rs45RR<-rsn; rm(rsn)
load("Eagle_outputs/Complete_results/res_RR_2050_final.RData")
rs50RR<-rsn; rm(rsn)
load("Eagle_outputs/Complete_results/res_RR_2055_final.RData")
rs55RR<-rsn; rm(rsn)
load("Eagle_outputs/Complete_results/res_RR_2060_final.RData")
rs60RR<-rsn; rm(rsn)

# Advanced Renovated (AR) 2020 stock in each sim year
load("Eagle_outputs/Complete_results/res_AR_2025_final.RData")
rs25AR<-rsn; rm(rsn)
load("Eagle_outputs/Complete_results/res_AR_2030_final.RData")
rs30AR<-rsn; rm(rsn)
load("Eagle_outputs/Complete_results/res_AR_2035_final.RData")
rs35AR<-rsn; rm(rsn)
load("Eagle_outputs/Complete_results/res_AR_2040_final.RData")
rs40AR<-rsn; rm(rsn)
load("Eagle_outputs/Complete_results/res_AR_2045_final.RData")
rs45AR<-rsn; rm(rsn)
load("Eagle_outputs/Complete_results/res_AR_2050_final.RData")
rs50AR<-rsn; rm(rsn)
load("Eagle_outputs/Complete_results/res_AR_2055_final.RData")
rs55AR<-AR55; rm(AR55)
load("Eagle_outputs/Complete_results/res_AR_2060_final.RData")
rs60AR<-rsn; rm(rsn)

# Extensive Renovated (ER) 2020 stock in each sim year
load("Eagle_outputs/Complete_results/res_ER_2025_final.RData")
rs25ER<-rsn; rm(rsn)
load("Eagle_outputs/Complete_results/res_ER_2030_final.RData")
rs30ER<-rsn; rm(rsn)
load("Eagle_outputs/Complete_results/res_ER_2035_final.RData")
rs35ER<-rsn; rm(rsn)
load("Eagle_outputs/Complete_results/res_ER_2040_final.RData")
rs40ER<-rsn; rm(rsn)
load("Eagle_outputs/Complete_results/res_ER_2045_final.RData")
rs45ER<-rsn; rm(rsn)
load("Eagle_outputs/Complete_results/res_ER_2050_final.RData")
rs50ER<-rsn; rm(rsn)
load("Eagle_outputs/Complete_results/res_ER_2055_final.RData")
rs55ER<-rsn; rm(rsn)
load("Eagle_outputs/Complete_results/res_ER_2060_final.RData")
rs60ER<-rsn; rm(rsn)


# import R modified bcsv files, these describe the characteristics of future cohorts in three stock scenarios (base, hiDR, hiMF) and 4 characteristics scenarios 'scen' (base, DE, RFA, DERFA)
load("Intermediate_results/agg_bscsv.RData")

# import renovation metadata, these are produced by the resScenarios scripts
load("Intermediate_results/RenAdvanced.RData")
rs_2020_60_AR<-rs_2020_2060
rm(rs_2020_2060)
load("Intermediate_results/RenStandard.RData")
rs_2020_60_RR<-rs_2020_2060
rm(rs_2020_2060)
load("Intermediate_results/RenExtElec.RData")
rs_2020_60_ER<-rs_2020_2060
rm(rs_2020_2060)

# remove columns of job id simulation details, upgrade details, bathroom spot vent hour, cooling setpoint offset details, corridor, door area and type, eaves, EV, 
# heating setpoint offset details, lighting use (both 100%), some misc equip presence and type, overhangs, report.applicable, single door area, upgrade cost
View(names(rs2020))
rmcol<-c(2:4,6:8,10,12,28:30,34:35,37:38,57:58,84:85,93:96,100:101,106,130,131,199)
colremove<-names(rs2020)[rmcol]
# rs<-rs25RR
result_sum<-function(rs,yr) {
  # remove unneeded columns to shrink data frame size
  rs<-rs[,-rmcol] 
  # tidy up names a bit
  names(rs)<-gsub("build_existing_model.","",names(rs))
  names(rs)<-gsub("simulation_output_report.","",names(rs))
  
  # calculate energy consumption by end use and fuel in SI units
  rs$Elec_GJ<-rs$total_site_electricity_kwh*0.0036
  rs$Elec_GJ_SPH<-(rs$electricity_heating_kwh+rs$electricity_heating_supplemental_kwh+rs$electricity_fans_heating_kwh +rs$electricity_pumps_heating_kwh )*0.0036
  rs$Elec_GJ_SPC<-(rs$electricity_cooling_kwh+rs$electricity_pumps_cooling_kwh +rs$electricity_fans_cooling_kwh)*0.0036
  rs$Elec_GJ_DHW<-(rs$electricity_water_systems_kwh)*0.0036
  rs$Elec_GJ_OTH<-rs$Elec_GJ-rs$Elec_GJ_SPH-rs$Elec_GJ_SPC-rs$Elec_GJ_DHW
  
  rs$Gas_GJ<-rs$total_site_natural_gas_therm*0.1055
  rs$Gas_GJ_SPH<-rs$natural_gas_heating_therm*0.1055
  rs$Gas_GJ_DHW<-rs$natural_gas_water_systems_therm*0.1055
  rs$Gas_GJ_OTH<-rs$Gas_GJ-rs$Gas_GJ_SPH-rs$Gas_GJ_DHW
  
  rs$Oil_GJ<-rs$total_site_fuel_oil_mbtu*1.055
  rs$Oil_GJ_SPH<-rs$fuel_oil_heating_mbtu*1.055
  rs$Oil_GJ_DHW<-rs$fuel_oil_water_systems_mbtu*1.055
  rs$Oil_GJ_OTH<-rs$Oil_GJ-rs$Oil_GJ_SPH-rs$Oil_GJ_DHW
  
  rs$Prop_GJ<-rs$total_site_propane_mbtu*1.055
  rs$Prop_GJ_SPH<-rs$propane_heating_mbtu*1.055
  rs$Prop_GJ_DHW<-rs$propane_water_systems_mbtu*1.055
  rs$Prop_GJ_OTH<-rs$Prop_GJ-rs$Prop_GJ_SPH-rs$Prop_GJ_DHW
  
  rs$Tot_GJ<-rs$Elec_GJ+rs$Gas_GJ+rs$Oil_GJ+rs$Prop_GJ
  
  rs$Tot_GJ_SPH<-rs$Elec_GJ_SPH+rs$Gas_GJ_SPH+rs$Oil_GJ_SPH+rs$Prop_GJ_SPH
  rs$Tot_GJ_SPC<-rs$Elec_GJ_SPC
  rs$Tot_GJ_DHW<-rs$Elec_GJ_DHW+rs$Gas_GJ_DHW+rs$Oil_GJ_DHW+rs$Prop_GJ_DHW
  rs$Tot_GJ_OTH<-rs$Elec_GJ_OTH+rs$Gas_GJ_OTH+rs$Oil_GJ_OTH+rs$Prop_GJ_OTH
  
  rs$Tot_MJ_m2<-1000*rs$Tot_GJ/(rs$floor_area_lighting_ft_2/10.765)
  rs$Year<-yr
  rs$Year_Building<-paste(rs$Year,rs$building_id,sep="_")
  rs
}


# xs<-25 # number of simulations for each year/scenario
rs2020_sum<-result_sum(rs2020,2020)
rs25RR_sum<-result_sum(rs25RR,2025)
rs30RR_sum<-result_sum(rs30RR,2030)
rs35RR_sum<-result_sum(rs35RR,2035)
rs40RR_sum<-result_sum(rs40RR,2040)
rs45RR_sum<-result_sum(rs45RR,2045)
rs50RR_sum<-result_sum(rs50RR,2050)
rs55RR_sum<-result_sum(rs55RR,2055)
rs60RR_sum<-result_sum(rs60RR,2060)

rs25AR_sum<-result_sum(rs25AR,2025)
rs30AR_sum<-result_sum(rs30AR,2030)
rs35AR_sum<-result_sum(rs35AR,2035)
rs40AR_sum<-result_sum(rs40AR,2040)
rs45AR_sum<-result_sum(rs45AR,2045)
rs50AR_sum<-result_sum(rs50AR,2050)
rs55AR_sum<-result_sum(rs55AR,2055)
rs60AR_sum<-result_sum(rs60AR,2060)

rs25ER_sum<-result_sum(rs25ER,2025)
rs30ER_sum<-result_sum(rs30ER,2030)
rs35ER_sum<-result_sum(rs35ER,2035)
rs40ER_sum<-result_sum(rs40ER,2040)
rs45ER_sum<-result_sum(rs45ER,2045)
rs50ER_sum<-result_sum(rs50ER,2050)
rs55ER_sum<-result_sum(rs55ER,2055)
rs60ER_sum<-result_sum(rs60ER,2060)

# the rs_all_** results are already created and saved, and don't contain energy results, so they can just be loaded in
# rs_all_RR<-rs_2020_60_RR
# rs_all_RR$Year_Building<-paste(rs_all_RR$Year,rs_all_RR$Building,sep="_")
# 
# rs_all_RR<-rs_all_RR[,c("Year_Building","Year", "Building","County","State","Location.Region","Census.Division", "Census.Region", "ASHRAE.IECC.Climate.Zone.2004", "PUMA", "ISO.RTO.Region", "Geometry.Building.Type.ACS","Geometry.Building.Type.RECS",
#                         "Vintage","Vintage.ACS","Heating.Fuel","Geometry.Floor.Area","Geometry.Foundation.Type","Geometry.Wall.Type","Geometry.Stories","Geometry.Garage",
#                         "HVAC.Heating.Type.And.Fuel","HVAC.Heating.Efficiency","HVAC.Cooling.Type","HVAC.Cooling.Efficiency","Water.Heater.Fuel","Water.Heater.Efficiency",
#                         "Clothes.Dryer","Infiltration", "change_cren","change_iren","change_wren","change_hren","base_weight")] # currently comes to 34 columns
# # numbered columns are base weight, energy by type, change in renovated systems

# rs_all_RR<-rs_all_RR[order(rs_all_RR$Building),]

load("Intermediate_results/decayFactorsProj.RData")

# rs_all_RR$TC<-"MF"
# rs_all_RR[rs_all_RR$Geometry.Building.Type.RECS=="Single-Family Attached" | rs_all_RR$Geometry.Building.Type.RECS=="Single-Family Detached",]$TC<-"SF"
# rs_all_RR[rs_all_RR$Geometry.Building.Type.RECS=="Mobile Home",]$TC<-"MH"
# rs_all_RR$TC<-paste(rs_all_RR$TC,rs_all_RR$Vintage.ACS,sep="_")
# rs_all_RR$ctyTC<-paste(rs_all_RR$County,rs_all_RR$TC,sep = "")
# rs_all_RR$ctyTC<-gsub("2010s","2010-19",rs_all_RR$ctyTC)
# 
# # # at this stage we are at 36 columns
# # # now add 9 columns for each stock scenario to bring us to 63
# rs_all_RR<-left_join(rs_all_RR,sbm,by="ctyTC")
# rs_all_RR<-left_join(rs_all_RR,shdrm,by="ctyTC")
# rs_all_RR<-left_join(rs_all_RR,shmfm,by="ctyTC")
# 
# rs_all_RR$sim.range<-"Undefined"
# for (b in 1:180000) { # this takes a while, about 3.5 hours
#   # for (b in c(1:15,9900,9934)) {
#   print(b)
#   w<-which(rs_all_RR$Building==b)
# 
#   for (sr in 1:(length(w)-1)) {
#     rs_all_RR$sim.range[w[sr]]<-paste(rs_all_RR[w[sr],"Year"],rs_all_RR[w[sr+1],"Year"]-5,sep = ".")
#   }
#   for (sr in length(w)) {
#     rs_all_RR$sim.range[w[sr]]<-paste(rs_all_RR[w[sr],"Year"],"2060",sep = ".")
#   }
#   # create concordance matrix to identify which weighting factors should be zero and non-zero
#   conc<-matrix(rep(0,9*length(w)),length(w),9)
#   for (c in 1:length(w)) {
#     conc[c, which(names(rs_all_RR[37:45])==paste("wbase", substr(rs_all_RR$sim.range[w[c]],1,4),sep="_")):
#            which(names(rs_all_RR[37:45])==paste("wbase", substr(rs_all_RR$sim.range[w[c]],6,9),sep="_"))]<-1
#   }
# 
#   rs_all_RR[w,37:45]<-rs_all_RR[w,37:45]*conc
#   rs_all_RR[w,46:54]<-rs_all_RR[w,46:54]*conc
#   rs_all_RR[w,55:63]<-rs_all_RR[w,55:63]*conc
# 
# }
# save(rs_all_RR,file="Intermediate_results/RenStandard_full.Rdata")
# script to produce this file is commented out, I now load it in instead
load("Intermediate_results/RenStandard_full.Rdata") 


# merge with the energy results
rs_all_RR_res<-rbind(rs2020_sum,rs25RR_sum,rs30RR_sum,rs35RR_sum,rs40RR_sum,rs45RR_sum,rs50RR_sum,rs55RR_sum,rs60RR_sum)
# rs_all_RR_res<-rs_all_RR_res[,c(1:3,176:200)]
rs_all_RR_res<-rs_all_RR_res[,c(1:3,23,43,44,55:63,66,81,82,88,95,103,105:111,113:122,124:129,131,133,135:141,148:200)] # bigger version

rs_RR<-merge(rs_all_RR,rs_all_RR_res)
rs_RRn<-rs_RR[order(rs_RR$Building),]

# no longer need to modify the failed TX simulations

load("ExtData/ctycode.RData") # from the HSM repo
load("ExtData/GHGI_MidCase.RData") # Elec GHG int data in Mid-Case scenario
load("ExtData/GHGI_LowRECost.RData") # Elec GHG int data in Low RE Cost Scenario
ctycode_num<-ctycode
ctycode_num$GeoID<-as.numeric(ctycode_num$GeoID)

gicty_rto[gicty_rto$geoid10==46113,]$geoid10<-46102 # replace Shannon County SD with Oglala Lakota Cty
gicty_rto[gicty_rto$geoid10==2270,]$geoid10<-2158 # replace Wade Hampton AK with Kusilvak AK
gicty_rto<-merge(gicty_rto,ctycode_num,by.x="geoid10",by.y="GeoID") #

gicty_rto_yr<-gicty_rto[gicty_rto$Year %in% c(2020,2025,2030,2035,2040,2045,2050,2055,2060),] # get only the RS simulation years
gic<-dcast(gicty_rto_yr[,2:4],RS_ID ~ Year,value.var = "GHG_int")
names(gic)[2:8]<-paste("GHG_int",names(gic)[2:8],sep="_")
gic$GHG_int_2055<-0.95* gic$GHG_int_2050
gic$GHG_int_2060<-0.95* gic$GHG_int_2055
gic[,2:10]<-gic[,2:10]/3600 # convert from kg/MWh to kg/MJ

# do the same process for the Low RE Cost electricity data
gicty_rto_LREC[gicty_rto_LREC$geoid10==46113,]$geoid10<-46102 # replace Shannon County SD with Oglala Lakota Cty
gicty_rto_LREC[gicty_rto_LREC$geoid10==2270,]$geoid10<-2158 # replace Wade Hampton AK with Kusilvak AK
gicty_rto_LREC<-merge(gicty_rto_LREC,ctycode_num,by.x="geoid10",by.y="GeoID") #

gicty_rto_LREC_yr<-gicty_rto_LREC[gicty_rto_LREC$Year %in% c(2020,2025,2030,2035,2040,2045,2050,2055,2060),] # get only the RS simulation years
gic_LRE<-dcast(gicty_rto_LREC_yr[,2:4],RS_ID ~ Year,value.var = "GHG_int")
names(gic_LRE)[2:8]<-paste("GHG_int",names(gic_LRE)[2:8],sep="_")
gic_LRE$GHG_int_2055<-0.93* gic_LRE$GHG_int_2050 # assume greater decreases in GHGI post-2050 in LREC
gic_LRE$GHG_int_2060<-0.9* gic_LRE$GHG_int_2055 # assume greater decreases in GHGI post-2050 in LREC
gic_LRE[,2:10]<-gic_LRE[,2:10]/3600 # convert from kg/MWh to kg/MJ
names(gic_LRE)[2:10]<-paste(names(gic_LRE)[2:10],"LRE",sep = "_")

# add GHG intensities, Mid-Case
rs_RRn<-left_join(rs_RRn,gic,by = c("County" = "RS_ID"))
# add GHG intensities, Low RE Cost
rs_RRn<-left_join(rs_RRn,gic_LRE,by = c("County" = "RS_ID"))

# calculation total energy and GHG
GHGI_FO<-((.07396)+(25*3e-6)+(298*6e-7))/1.055  # intensity for heating oil (DFO #2) in kgCO2eq / MJ
GHGI_NG<-((0.05302)+(25*10e-6) + (298*1e-7))/1.055  # intensity for natural gas in kgCO2eq / MJ
GHGI_LP<-((.06298)+(25*3e-6)+(298*6e-7))/1.055   # intensity for LPG in kgCO2eq / MJ

# total energy in GJ
rs_RRn[,c("Tot_GJ_base_2020",  "Tot_GJ_base_2025","Tot_GJ_base_2030","Tot_GJ_base_2035","Tot_GJ_base_2040","Tot_GJ_base_2045","Tot_GJ_base_2050","Tot_GJ_base_2055","Tot_GJ_base_2060")]<-
  (rs_RRn$base_weight*rs_RRn[,c("wbase_2020", "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*
  (rs_RRn$Elec_GJ+rs_RRn$Gas_GJ+rs_RRn$Prop_GJ+rs_RRn$Oil_GJ)

rs_RRn[,c("Tot_GJ_hiDR_2020",  "Tot_GJ_hiDR_2025","Tot_GJ_hiDR_2030","Tot_GJ_hiDR_2035","Tot_GJ_hiDR_2040","Tot_GJ_hiDR_2045","Tot_GJ_hiDR_2050","Tot_GJ_hiDR_2055","Tot_GJ_hiDR_2060")]<-
  (rs_RRn$base_weight*rs_RRn[,c("whiDR_2020", "whiDR_2025", "whiDR_2030", "whiDR_2035", "whiDR_2040", "whiDR_2045", "whiDR_2050", "whiDR_2055", "whiDR_2060")])*
  (rs_RRn$Elec_GJ+rs_RRn$Gas_GJ+rs_RRn$Prop_GJ+rs_RRn$Oil_GJ)
# NEED to include the MF results, for combination with the projection results
rs_RRn[,c("Tot_GJ_hiMF_2020",  "Tot_GJ_hiMF_2025","Tot_GJ_hiMF_2030","Tot_GJ_hiMF_2035","Tot_GJ_hiMF_2040","Tot_GJ_hiMF_2045","Tot_GJ_hiMF_2050","Tot_GJ_hiMF_2055","Tot_GJ_hiMF_2060")]<-
  (rs_RRn$base_weight*rs_RRn[,c("whiMF_2020", "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")])*
  (rs_RRn$Elec_GJ+rs_RRn$Gas_GJ+rs_RRn$Prop_GJ+rs_RRn$Oil_GJ)


# tot kgGHG per archetype group/year in kg
rs_RRn[,c("EnGHGkg_base_2020","EnGHGkg_base_2025","EnGHGkg_base_2030","EnGHGkg_base_2035","EnGHGkg_base_2040","EnGHGkg_base_2045","EnGHGkg_base_2050","EnGHGkg_base_2055","EnGHGkg_base_2060")]<-1000* 
  (rs_RRn$base_weight*rs_RRn[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*
  (rs_RRn$Elec_GJ*rs_RRn[,c("GHG_int_2020", "GHG_int_2025","GHG_int_2030","GHG_int_2035","GHG_int_2040","GHG_int_2045","GHG_int_2050","GHG_int_2055","GHG_int_2060")]+
     matrix(rep(rs_RRn$Gas_GJ*GHGI_NG,9),nrow(rs_RRn),9)+ matrix(rep(rs_RRn$Oil_GJ*GHGI_FO,9),nrow(rs_RRn),9)+ matrix(rep(rs_RRn$Prop_GJ*GHGI_LP,9),nrow(rs_RRn),9))

# tot kgGHG per archetype group/year in kg
rs_RRn[,c("EnGHGkg_hiDR_2020","EnGHGkg_hiDR_2025","EnGHGkg_hiDR_2030","EnGHGkg_hiDR_2035","EnGHGkg_hiDR_2040","EnGHGkg_hiDR_2045","EnGHGkg_hiDR_2050","EnGHGkg_hiDR_2055","EnGHGkg_hiDR_2060")]<-1000* 
  (rs_RRn$base_weight*rs_RRn[,c("whiDR_2020",  "whiDR_2025", "whiDR_2030", "whiDR_2035", "whiDR_2040", "whiDR_2045", "whiDR_2050", "whiDR_2055", "whiDR_2060")])*
  (rs_RRn$Elec_GJ*rs_RRn[,c("GHG_int_2020", "GHG_int_2025","GHG_int_2030","GHG_int_2035","GHG_int_2040","GHG_int_2045","GHG_int_2050","GHG_int_2055","GHG_int_2060")]+
     matrix(rep(rs_RRn$Gas_GJ*GHGI_NG,9),nrow(rs_RRn),9)+ matrix(rep(rs_RRn$Oil_GJ*GHGI_FO,9),nrow(rs_RRn),9)+ matrix(rep(rs_RRn$Prop_GJ*GHGI_LP,9),nrow(rs_RRn),9))

# tot kgGHG per archetype group/year in kg
rs_RRn[,c("EnGHGkg_hiMF_2020","EnGHGkg_hiMF_2025","EnGHGkg_hiMF_2030","EnGHGkg_hiMF_2035","EnGHGkg_hiMF_2040","EnGHGkg_hiMF_2045","EnGHGkg_hiMF_2050","EnGHGkg_hiMF_2055","EnGHGkg_hiMF_2060")]<-1000* 
  (rs_RRn$base_weight*rs_RRn[,c("whiMF_2020",  "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")])*
  (rs_RRn$Elec_GJ*rs_RRn[,c("GHG_int_2020", "GHG_int_2025","GHG_int_2030","GHG_int_2035","GHG_int_2040","GHG_int_2045","GHG_int_2050","GHG_int_2055","GHG_int_2060")]+
     matrix(rep(rs_RRn$Gas_GJ*GHGI_NG,9),nrow(rs_RRn),9)+ matrix(rep(rs_RRn$Oil_GJ*GHGI_FO,9),nrow(rs_RRn),9)+ matrix(rep(rs_RRn$Prop_GJ*GHGI_LP,9),nrow(rs_RRn),9))

# tot LRE kgGHG per archetype group/year in kg
rs_RRn[,c("EnGHGkg_base_2020_LRE","EnGHGkg_base_2025_LRE","EnGHGkg_base_2030_LRE","EnGHGkg_base_2035_LRE","EnGHGkg_base_2040_LRE","EnGHGkg_base_2045_LRE","EnGHGkg_base_2050_LRE","EnGHGkg_base_2055_LRE","EnGHGkg_base_2060_LRE")]<-1000* 
  (rs_RRn$base_weight*rs_RRn[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*
  (rs_RRn$Elec_GJ*rs_RRn[,c("GHG_int_2020_LRE", "GHG_int_2025_LRE","GHG_int_2030_LRE","GHG_int_2035_LRE","GHG_int_2040_LRE","GHG_int_2045_LRE","GHG_int_2050_LRE","GHG_int_2055_LRE","GHG_int_2060_LRE")]+
     matrix(rep(rs_RRn$Gas_GJ*GHGI_NG,9),nrow(rs_RRn),9)+ matrix(rep(rs_RRn$Oil_GJ*GHGI_FO,9),nrow(rs_RRn),9)+ matrix(rep(rs_RRn$Prop_GJ*GHGI_LP,9),nrow(rs_RRn),9))

# tot LRE kgGHG per archetype group/year in kg
rs_RRn[,c("EnGHGkg_hiDR_2020_LRE","EnGHGkg_hiDR_2025_LRE","EnGHGkg_hiDR_2030_LRE","EnGHGkg_hiDR_2035_LRE","EnGHGkg_hiDR_2040_LRE","EnGHGkg_hiDR_2045_LRE","EnGHGkg_hiDR_2050_LRE","EnGHGkg_hiDR_2055_LRE","EnGHGkg_hiDR_2060_LRE")]<-1000* 
  (rs_RRn$base_weight*rs_RRn[,c("whiDR_2020",  "whiDR_2025", "whiDR_2030", "whiDR_2035", "whiDR_2040", "whiDR_2045", "whiDR_2050", "whiDR_2055", "whiDR_2060")])*
  (rs_RRn$Elec_GJ*rs_RRn[,c("GHG_int_2020_LRE", "GHG_int_2025_LRE","GHG_int_2030_LRE","GHG_int_2035_LRE","GHG_int_2040_LRE","GHG_int_2045_LRE","GHG_int_2050_LRE","GHG_int_2055_LRE","GHG_int_2060_LRE")]+
     matrix(rep(rs_RRn$Gas_GJ*GHGI_NG,9),nrow(rs_RRn),9)+ matrix(rep(rs_RRn$Oil_GJ*GHGI_FO,9),nrow(rs_RRn),9)+ matrix(rep(rs_RRn$Prop_GJ*GHGI_LP,9),nrow(rs_RRn),9))

# tot LRE kgGHG per archetype group/year in kg
rs_RRn[,c("EnGHGkg_hiMF_2020_LRE","EnGHGkg_hiMF_2025_LRE","EnGHGkg_hiMF_2030_LRE","EnGHGkg_hiMF_2035_LRE","EnGHGkg_hiMF_2040_LRE","EnGHGkg_hiMF_2045_LRE","EnGHGkg_hiMF_2050_LRE","EnGHGkg_hiMF_2055_LRE","EnGHGkg_hiMF_2060_LRE")]<-1000* 
  (rs_RRn$base_weight*rs_RRn[,c("whiMF_2020",  "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")])*
  (rs_RRn$Elec_GJ*rs_RRn[,c("GHG_int_2020_LRE", "GHG_int_2025_LRE","GHG_int_2030_LRE","GHG_int_2035_LRE","GHG_int_2040_LRE","GHG_int_2045_LRE","GHG_int_2050_LRE","GHG_int_2055_LRE","GHG_int_2060_LRE")]+
     matrix(rep(rs_RRn$Gas_GJ*GHGI_NG,9),nrow(rs_RRn),9)+ matrix(rep(rs_RRn$Oil_GJ*GHGI_FO,9),nrow(rs_RRn),9)+ matrix(rep(rs_RRn$Prop_GJ*GHGI_LP,9),nrow(rs_RRn),9))


# calculate avg reductions per renovation type
rs_RRn$redn_hren<-rs_RRn$redn_wren<-rs_RRn$redn_iren<-rs_RRn$redn_cren<-0
rs_RRn$change_hren_only<-rs_RRn$change_wren_only<-rs_RRn$change_iren_only<-rs_RRn$change_cren_only<-FALSE
for (k in 1:180000) { print(k) # this will probably take a while, about 3hs. Have to come back and redo this
  w<-which(rs_RRn$Building==k) 
  if (length(w) > 1) { # if there are any renovations
  for (j in 1:(length(w)-1)) {
   if (rs_RRn[w[j+1],]$change_cren!=rs_RRn[w[j],]$change_cren & identical(as.numeric(rs_RRn[w[j+1],31:33]),as.numeric(rs_RRn[w[j],31:33])) ) { # if only change_cren changes
     rs_RRn$redn_cren[w[j+1]]<-1-(rs_RRn$Tot_GJ[w[j+1]]/rs_RRn$Tot_GJ[w[j]])
     rs_RRn$change_cren_only[w[j+1]]<-TRUE
   }
    if (rs_RRn[w[j+1],]$change_iren!=rs_RRn[w[j],]$change_iren & identical(as.numeric(rs_RRn[w[j+1],c(30,32,33)]),as.numeric(rs_RRn[w[j],c(30,32,33)])) ) { # if only change_iren changes
      rs_RRn$redn_iren[w[j+1]]<-1-(rs_RRn$Tot_GJ[w[j+1]]/rs_RRn$Tot_GJ[w[j]])
      rs_RRn$change_iren_only[w[j+1]]<-TRUE
    } 
    if (rs_RRn[w[j+1],]$change_wren!=rs_RRn[w[j],]$change_wren & identical(as.numeric(rs_RRn[w[j+1],c(30,31,33)]),as.numeric(rs_RRn[w[j],c(30,31,33)])) ) { # if only change_wren changes
      rs_RRn$redn_wren[w[j+1]]<-1-(rs_RRn$Tot_GJ[w[j+1]]/rs_RRn$Tot_GJ[w[j]])
      rs_RRn$change_wren_only[w[j+1]]<-TRUE
    }
    if (rs_RRn[w[j+1],]$change_hren!=rs_RRn[w[j],]$change_hren & identical(as.numeric(rs_RRn[w[j+1],30:32]),as.numeric(rs_RRn[w[j],30:32])) ) { # if only change_hren changes
      rs_RRn$redn_hren[w[j+1]]<-1-(rs_RRn$Tot_GJ[w[j+1]]/rs_RRn$Tot_GJ[w[j]])
      rs_RRn$change_hren_only[w[j+1]]<-TRUE
    }
  }
  }
}

tapply(rs_RRn$redn_cren,rs_RRn$change_cren_only,mean) # 1.4%
tapply(rs_RRn$redn_iren,rs_RRn$change_iren_only,mean) # 13.9%
tapply(rs_RRn$redn_wren,rs_RRn$change_wren_only,mean) # 3.25#
tapply(rs_RRn$redn_hren,rs_RRn$change_hren_only,mean) # 6.5%

tapply(rs_RRn$redn_cren,list(rs_RRn$change_cren_only,rs_RRn$Geometry.Building.Type.RECS), mean) # highest in SFD and MH, negative in MF
tapply(rs_RRn$redn_iren,list(rs_RRn$change_iren_only,rs_RRn$Geometry.Building.Type.RECS), mean) # highest in MF2-4 & SFD (both 15%)
tapply(rs_RRn$redn_wren,list(rs_RRn$change_wren_only,rs_RRn$Geometry.Building.Type.RECS), mean) # highest in SFA (4.8%), lowest in MH
tapply(rs_RRn$redn_hren,list(rs_RRn$change_hren_only,rs_RRn$Geometry.Building.Type.RECS), mean) # highest in SFD (7.5%) & MH (7.2%)

tapply(rs_RRn$redn_cren,list(rs_RRn$change_cren_only,rs_RRn$Vintage), mean) # negative in older homes (<1970)
tapply(rs_RRn$redn_iren,list(rs_RRn$change_iren_only,rs_RRn$Vintage), mean) # highest in older homes (~20%)
tapply(rs_RRn$redn_wren,list(rs_RRn$change_wren_only,rs_RRn$Vintage), mean) # reasonably steady across vintages, slightly higher in older homes
tapply(rs_RRn$redn_hren,list(rs_RRn$change_hren_only,rs_RRn$Vintage), mean) # highest in older homes (>8%)

tapply(rs_RRn$redn_cren,list(rs_RRn$change_cren_only,rs_RRn$Census.Region), mean) # only >0 in South
tapply(rs_RRn$redn_iren,list(rs_RRn$change_iren_only,rs_RRn$Census.Region), mean) # highest in MW and NE (17%)
tapply(rs_RRn$redn_wren,list(rs_RRn$change_wren_only,rs_RRn$Census.Region), mean) # lowest in the south (2.4%), highest in NE and W, ~4%
tapply(rs_RRn$redn_hren,list(rs_RRn$change_hren_only,rs_RRn$Census.Region), mean) # highest in NE, ME, ~8%

heat_typ_reg_rr<-tapply(rs_RRn$redn_hren,list(rs_RRn$change_hren_only,rs_RRn$Geometry.Building.Type.RECS,rs_RRn$Census.Region), mean)[2,,] 
cool_typ_reg_rr<-tapply(rs_RRn$redn_cren,list(rs_RRn$change_cren_only,rs_RRn$Geometry.Building.Type.RECS,rs_RRn$Census.Region), mean)[2,,] 
dhw_typ_reg_rr<-tapply(rs_RRn$redn_wren,list(rs_RRn$change_wren_only,rs_RRn$Geometry.Building.Type.RECS,rs_RRn$Census.Region), mean)[2,,] 
ins_typ_reg_rr<-tapply(rs_RRn$redn_iren,list(rs_RRn$change_iren_only,rs_RRn$Geometry.Building.Type.RECS,rs_RRn$Census.Region), mean)[2,,] 

heat_age_reg_rr<-tapply(rs_RRn$redn_hren,list(rs_RRn$change_hren_only,rs_RRn$Vintage.ACS,rs_RRn$Census.Region), mean)[2,,] 
cool_age_reg_rr<-tapply(rs_RRn$redn_cren,list(rs_RRn$change_cren_only,rs_RRn$Vintage.ACS,rs_RRn$Census.Region), mean)[2,,] 
dhw_age_reg_rr<-tapply(rs_RRn$redn_wren,list(rs_RRn$change_wren_only,rs_RRn$Vintage.ACS,rs_RRn$Census.Region), mean)[2,,] 
ins_age_reg_rr<-tapply(rs_RRn$redn_iren,list(rs_RRn$change_iren_only,rs_RRn$Vintage.ACS,rs_RRn$Census.Region), mean)[2,,] 

heat_typ_age_rr<-tapply(rs_RRn$redn_hren,list(rs_RRn$change_hren_only,rs_RRn$Geometry.Building.Type.RECS,rs_RRn$Vintage.ACS), mean)[2,,] 
cool_typ_age_rr<-tapply(rs_RRn$redn_cren,list(rs_RRn$change_cren_only,rs_RRn$Geometry.Building.Type.RECS,rs_RRn$Vintage.ACS), mean)[2,,] 
dhw_typ_age_rr<-tapply(rs_RRn$redn_wren,list(rs_RRn$change_wren_only,rs_RRn$Geometry.Building.Type.RECS,rs_RRn$Vintage.ACS), mean)[2,,] 
ins_typ_age_rr<-tapply(rs_RRn$redn_iren,list(rs_RRn$change_iren_only,rs_RRn$Geometry.Building.Type.RECS,rs_RRn$Vintage.ACS), mean)[2,,] 

# save this modified dataframe
save(rs_RRn,file = "Intermediate_results/RenStandard_EG.RData")
save(heat_typ_reg_rr,heat_age_reg_rr,heat_typ_age_rr, cool_typ_reg_rr,cool_age_reg_rr,cool_typ_age_rr, dhw_typ_reg_rr,dhw_age_reg_rr,dhw_typ_age_rr,
     ins_typ_reg_rr,ins_age_reg_rr,ins_typ_age_rr,file = "Intermediate_results/RR_redn.RData")

# repeat the long function of adding decay factors with the AR files ########
# rs_all_AR<-rs_2020_60_AR
# rs_all_AR$Year_Building<-paste(rs_all_AR$Year,rs_all_AR$Building,sep="_")
# 
# rs_all_AR<-rs_all_AR[,c("Year_Building","Year", "Building","County","State","Location.Region","Census.Division", "Census.Region", "ASHRAE.IECC.Climate.Zone.2004", "PUMA", "ISO.RTO.Region", "Geometry.Building.Type.ACS","Geometry.Building.Type.RECS",
#                         "Vintage","Vintage.ACS","Heating.Fuel","Geometry.Floor.Area","Geometry.Foundation.Type","Geometry.Wall.Type","Geometry.Stories","Geometry.Garage",
#                         "HVAC.Heating.Type.And.Fuel","HVAC.Heating.Efficiency","HVAC.Cooling.Type","HVAC.Cooling.Efficiency","Water.Heater.Fuel","Water.Heater.Efficiency",
#                         "Clothes.Dryer","Infiltration", "change_cren","change_iren","change_wren","change_hren","base_weight")] # currently comes to 34 columns
# 
# rs_all_AR<-rs_all_AR[order(rs_all_AR$Building),]
# 
# rs_all_AR$TC<-"MF"
# rs_all_AR[rs_all_AR$Geometry.Building.Type.RECS=="Single-Family Attached" | rs_all_AR$Geometry.Building.Type.RECS=="Single-Family Detached",]$TC<-"SF"
# rs_all_AR[rs_all_AR$Geometry.Building.Type.RECS=="Mobile Home",]$TC<-"MH"
# rs_all_AR$TC<-paste(rs_all_AR$TC,rs_all_AR$Vintage.ACS,sep="_")
# rs_all_AR$ctyTC<-paste(rs_all_AR$County,rs_all_AR$TC,sep = "")
# rs_all_AR$ctyTC<-gsub("2010s","2010-19",rs_all_AR$ctyTC)
# 
# # at this stage we are at 36 columns
# # now add 9 columns for each stock scenario to bring us to 63
# rs_all_AR<-left_join(rs_all_AR,sbm,by="ctyTC")
# rs_all_AR<-left_join(rs_all_AR,shdrm,by="ctyTC")
# rs_all_AR<-left_join(rs_all_AR,shmfm,by="ctyTC")
# rs_all_AR<-left_join(rs_all_AR,shdmm,by="ctyTC") excluding the high dem and high MF scenario

# rs_all_AR$sim.range<-"Undefined"
# for (b in 1:180000) { # this takes a while, up to 4 hours, it's done once and can be loaded in using the call below
#   # for (b in c(1:15,9900,9934)) {
#   print(b)
#   w<-which(rs_all_AR$Building==b)
#   
#   for (sr in 1:(length(w)-1)) {
#     rs_all_AR$sim.range[w[sr]]<-paste(rs_all_AR[w[sr],"Year"],rs_all_AR[w[sr+1],"Year"]-5,sep = ".")
#   }
#   for (sr in length(w)) {
#     rs_all_AR$sim.range[w[sr]]<-paste(rs_all_AR[w[sr],"Year"],"2060",sep = ".")
#   }
#   # create concordance matrix to identify which weighting factors should be zero and non-zero
#   conc<-matrix(rep(0,9*length(w)),length(w),9)
#   for (c in 1:length(w)) {
#     conc[c, which(names(rs_all_AR[37:45])==paste("wbase", substr(rs_all_AR$sim.range[w[c]],1,4),sep="_")):
#            which(names(rs_all_AR[37:45])==paste("wbase", substr(rs_all_AR$sim.range[w[c]],6,9),sep="_"))]<-1
#   }
#   
#   rs_all_AR[w,37:45]<-rs_all_AR[w,37:45]*conc
#   rs_all_AR[w,46:54]<-rs_all_AR[w,46:54]*conc
#   rs_all_AR[w,55:63]<-rs_all_AR[w,55:63]*conc
#   
# }
# save(rs_all_AR,file="../Intermediate_results/RenAdvanced_full.Rdata")
load("Intermediate_results/RenAdvanced_full.Rdata")

# merge with the energy results
rs_all_AR_res<-rbind(rs2020_sum,rs25AR_sum,rs30AR_sum,rs35AR_sum,rs40AR_sum,rs45AR_sum,rs50AR_sum,rs55AR_sum,rs60AR_sum)
rs_all_AR_res<-rs_all_AR_res[,c(1:3,23,43,44,55:63,66,81,82,88,95,103,105:111,113:122,124:129,131,133,135:141,148:200)] # bigger reduced version

rs_AR<-merge(rs_all_AR,rs_all_AR_res)
rs_ARn<-rs_AR[order(rs_AR$Building),]

load("ExtData/ctycode.RData") # from the HSM repo
load("ExtData/GHGI_MidCase.RData") # Elec GHG int data in Mid-Case scenario
load("ExtData/GHGI_LowRECost.RData") # Elec GHG int data in Low RE Cost Scenario
ctycode_num<-ctycode
ctycode_num$GeoID<-as.numeric(ctycode_num$GeoID)

gicty_rto[gicty_rto$geoid10==46113,]$geoid10<-46102 # replace Shannon County SD with Oglala Lakota Cty
gicty_rto[gicty_rto$geoid10==2270,]$geoid10<-2158 # replace Wade Hampton AK with Kusilvak AK
gicty_rto<-merge(gicty_rto,ctycode_num,by.x="geoid10",by.y="GeoID") #

gicty_rto_yr<-gicty_rto[gicty_rto$Year %in% c(2020,2025,2030,2035,2040,2045,2050,2055,2060),] # get only the RS simulation years
gic<-dcast(gicty_rto_yr[,2:4],RS_ID ~ Year,value.var = "GHG_int")
names(gic)[2:8]<-paste("GHG_int",names(gic)[2:8],sep="_")
gic$GHG_int_2055<-0.95* gic$GHG_int_2050
gic$GHG_int_2060<-0.95* gic$GHG_int_2055
gic[,2:10]<-gic[,2:10]/3600 # convert from kg/MWh to kg/MJ

# do the same process for the Low RE Cost electricity data
gicty_rto_LREC[gicty_rto_LREC$geoid10==46113,]$geoid10<-46102 # replace Shannon County SD with Oglala Lakota Cty
gicty_rto_LREC[gicty_rto_LREC$geoid10==2270,]$geoid10<-2158 # replace Wade Hampton AK with Kusilvak AK
gicty_rto_LREC<-merge(gicty_rto_LREC,ctycode_num,by.x="geoid10",by.y="GeoID") #

gicty_rto_LREC_yr<-gicty_rto_LREC[gicty_rto_LREC$Year %in% c(2020,2025,2030,2035,2040,2045,2050,2055,2060),] # get only the RS simulation years
gic_LRE<-dcast(gicty_rto_LREC_yr[,2:4],RS_ID ~ Year,value.var = "GHG_int")
names(gic_LRE)[2:8]<-paste("GHG_int",names(gic_LRE)[2:8],sep="_")
gic_LRE$GHG_int_2055<-0.93* gic_LRE$GHG_int_2050 # assume greater decreases in GHGI post-2050 in LREC
gic_LRE$GHG_int_2060<-0.9* gic_LRE$GHG_int_2055 # assume greater decreases in GHGI post-2050 in LREC
gic_LRE[,2:10]<-gic_LRE[,2:10]/3600 # convert from kg/MWh to kg/MJ
names(gic_LRE)[2:10]<-paste(names(gic_LRE)[2:10],"LRE",sep = "_")

# add GHG intensities, Mid-Case
rs_ARn<-left_join(rs_ARn,gic,by = c("County" = "RS_ID"))
# add GHG intensities, Low RE Cost
rs_ARn<-left_join(rs_ARn,gic_LRE,by = c("County" = "RS_ID"))

# calculation total energy and GHG
GHGI_FO<-((.07396)+(25*3e-6)+(298*6e-7))/1.055  # intensity for heating oil (DFO #2) in kgCO2eq / MJ
GHGI_NG<-((0.05302)+(25*10e-6) + (298*1e-7))/1.055  # intensity for natural gas in kgCO2eq / MJ
GHGI_LP<-((.06298)+(25*3e-6)+(298*6e-7))/1.055   # intensity for LPG in kgCO2eq / MJ

# total energy in GJ
rs_ARn[,c("Tot_GJ_base_2020",  "Tot_GJ_base_2025","Tot_GJ_base_2030","Tot_GJ_base_2035","Tot_GJ_base_2040","Tot_GJ_base_2045","Tot_GJ_base_2050","Tot_GJ_base_2055","Tot_GJ_base_2060")]<-
  (rs_ARn$base_weight*rs_ARn[,c("wbase_2020", "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*
  (rs_ARn$Elec_GJ+rs_ARn$Gas_GJ+rs_ARn$Prop_GJ+rs_ARn$Oil_GJ)

rs_ARn[,c("Tot_GJ_hiDR_2020",  "Tot_GJ_hiDR_2025","Tot_GJ_hiDR_2030","Tot_GJ_hiDR_2035","Tot_GJ_hiDR_2040","Tot_GJ_hiDR_2045","Tot_GJ_hiDR_2050","Tot_GJ_hiDR_2055","Tot_GJ_hiDR_2060")]<-
  (rs_ARn$base_weight*rs_ARn[,c("whiDR_2020", "whiDR_2025", "whiDR_2030", "whiDR_2035", "whiDR_2040", "whiDR_2045", "whiDR_2050", "whiDR_2055", "whiDR_2060")])*
  (rs_ARn$Elec_GJ+rs_ARn$Gas_GJ+rs_ARn$Prop_GJ+rs_ARn$Oil_GJ)

rs_ARn[,c("Tot_GJ_hiMF_2020",  "Tot_GJ_hiMF_2025","Tot_GJ_hiMF_2030","Tot_GJ_hiMF_2035","Tot_GJ_hiMF_2040","Tot_GJ_hiMF_2045","Tot_GJ_hiMF_2050","Tot_GJ_hiMF_2055","Tot_GJ_hiMF_2060")]<-
  (rs_ARn$base_weight*rs_ARn[,c("whiMF_2020", "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")])*
  (rs_ARn$Elec_GJ+rs_ARn$Gas_GJ+rs_ARn$Prop_GJ+rs_ARn$Oil_GJ)

# tot kgGHG per archetype group/year in kg
rs_ARn[,c("EnGHGkg_base_2020","EnGHGkg_base_2025","EnGHGkg_base_2030","EnGHGkg_base_2035","EnGHGkg_base_2040","EnGHGkg_base_2045","EnGHGkg_base_2050","EnGHGkg_base_2055","EnGHGkg_base_2060")]<-1000* 
  (rs_ARn$base_weight*rs_ARn[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*
  (rs_ARn$Elec_GJ*rs_ARn[,c("GHG_int_2020", "GHG_int_2025","GHG_int_2030","GHG_int_2035","GHG_int_2040","GHG_int_2045","GHG_int_2050","GHG_int_2055","GHG_int_2060")]+
     matrix(rep(rs_ARn$Gas_GJ*GHGI_NG,9),nrow(rs_ARn),9)+ matrix(rep(rs_ARn$Oil_GJ*GHGI_FO,9),nrow(rs_ARn),9)+ matrix(rep(rs_ARn$Prop_GJ*GHGI_LP,9),nrow(rs_ARn),9))

# tot kgGHG per archetype group/year in kg
rs_ARn[,c("EnGHGkg_hiDR_2020","EnGHGkg_hiDR_2025","EnGHGkg_hiDR_2030","EnGHGkg_hiDR_2035","EnGHGkg_hiDR_2040","EnGHGkg_hiDR_2045","EnGHGkg_hiDR_2050","EnGHGkg_hiDR_2055","EnGHGkg_hiDR_2060")]<-1000* 
  (rs_ARn$base_weight*rs_ARn[,c("whiDR_2020",  "whiDR_2025", "whiDR_2030", "whiDR_2035", "whiDR_2040", "whiDR_2045", "whiDR_2050", "whiDR_2055", "whiDR_2060")])*
  (rs_ARn$Elec_GJ*rs_ARn[,c("GHG_int_2020", "GHG_int_2025","GHG_int_2030","GHG_int_2035","GHG_int_2040","GHG_int_2045","GHG_int_2050","GHG_int_2055","GHG_int_2060")]+
     matrix(rep(rs_ARn$Gas_GJ*GHGI_NG,9),nrow(rs_ARn),9)+ matrix(rep(rs_ARn$Oil_GJ*GHGI_FO,9),nrow(rs_ARn),9)+ matrix(rep(rs_ARn$Prop_GJ*GHGI_LP,9),nrow(rs_ARn),9))

rs_ARn[,c("EnGHGkg_hiMF_2020","EnGHGkg_hiMF_2025","EnGHGkg_hiMF_2030","EnGHGkg_hiMF_2035","EnGHGkg_hiMF_2040","EnGHGkg_hiMF_2045","EnGHGkg_hiMF_2050","EnGHGkg_hiMF_2055","EnGHGkg_hiMF_2060")]<-1000*
  (rs_ARn$base_weight*rs_ARn[,c("whiMF_2020",  "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")])*
  (rs_ARn$Elec_GJ*rs_ARn[,c("GHG_int_2020", "GHG_int_2025","GHG_int_2030","GHG_int_2035","GHG_int_2040","GHG_int_2045","GHG_int_2050","GHG_int_2055","GHG_int_2060")]+
     matrix(rep(rs_ARn$Gas_GJ*GHGI_NG,9),nrow(rs_ARn),9)+ matrix(rep(rs_ARn$Oil_GJ*GHGI_FO,9),nrow(rs_ARn),9)+ matrix(rep(rs_ARn$Prop_GJ*GHGI_LP,9),nrow(rs_ARn),9))

# tot LRE kgGHG per archetype group/year in kg
rs_ARn[,c("EnGHGkg_base_2020_LRE","EnGHGkg_base_2025_LRE","EnGHGkg_base_2030_LRE","EnGHGkg_base_2035_LRE","EnGHGkg_base_2040_LRE","EnGHGkg_base_2045_LRE","EnGHGkg_base_2050_LRE","EnGHGkg_base_2055_LRE","EnGHGkg_base_2060_LRE")]<-1000* 
  (rs_ARn$base_weight*rs_ARn[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*
  (rs_ARn$Elec_GJ*rs_ARn[,c("GHG_int_2020_LRE", "GHG_int_2025_LRE","GHG_int_2030_LRE","GHG_int_2035_LRE","GHG_int_2040_LRE","GHG_int_2045_LRE","GHG_int_2050_LRE","GHG_int_2055_LRE","GHG_int_2060_LRE")]+
     matrix(rep(rs_ARn$Gas_GJ*GHGI_NG,9),nrow(rs_ARn),9)+ matrix(rep(rs_ARn$Oil_GJ*GHGI_FO,9),nrow(rs_ARn),9)+ matrix(rep(rs_ARn$Prop_GJ*GHGI_LP,9),nrow(rs_ARn),9))

# tot LRE kgGHG per archetype group/year in kg
rs_ARn[,c("EnGHGkg_hiDR_2020_LRE","EnGHGkg_hiDR_2025_LRE","EnGHGkg_hiDR_2030_LRE","EnGHGkg_hiDR_2035_LRE","EnGHGkg_hiDR_2040_LRE","EnGHGkg_hiDR_2045_LRE","EnGHGkg_hiDR_2050_LRE","EnGHGkg_hiDR_2055_LRE","EnGHGkg_hiDR_2060_LRE")]<-1000* 
  (rs_ARn$base_weight*rs_ARn[,c("whiDR_2020",  "whiDR_2025", "whiDR_2030", "whiDR_2035", "whiDR_2040", "whiDR_2045", "whiDR_2050", "whiDR_2055", "whiDR_2060")])*
  (rs_ARn$Elec_GJ*rs_ARn[,c("GHG_int_2020_LRE", "GHG_int_2025_LRE","GHG_int_2030_LRE","GHG_int_2035_LRE","GHG_int_2040_LRE","GHG_int_2045_LRE","GHG_int_2050_LRE","GHG_int_2055_LRE","GHG_int_2060_LRE")]+
     matrix(rep(rs_ARn$Gas_GJ*GHGI_NG,9),nrow(rs_ARn),9)+ matrix(rep(rs_ARn$Oil_GJ*GHGI_FO,9),nrow(rs_ARn),9)+ matrix(rep(rs_ARn$Prop_GJ*GHGI_LP,9),nrow(rs_ARn),9))

# tot LRE kgGHG per archetype group/year in kg
rs_ARn[,c("EnGHGkg_hiMF_2020_LRE","EnGHGkg_hiMF_2025_LRE","EnGHGkg_hiMF_2030_LRE","EnGHGkg_hiMF_2035_LRE","EnGHGkg_hiMF_2040_LRE","EnGHGkg_hiMF_2045_LRE","EnGHGkg_hiMF_2050_LRE","EnGHGkg_hiMF_2055_LRE","EnGHGkg_hiMF_2060_LRE")]<-1000* 
  (rs_ARn$base_weight*rs_ARn[,c("whiMF_2020",  "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")])*
  (rs_ARn$Elec_GJ*rs_ARn[,c("GHG_int_2020_LRE", "GHG_int_2025_LRE","GHG_int_2030_LRE","GHG_int_2035_LRE","GHG_int_2040_LRE","GHG_int_2045_LRE","GHG_int_2050_LRE","GHG_int_2055_LRE","GHG_int_2060_LRE")]+
     matrix(rep(rs_ARn$Gas_GJ*GHGI_NG,9),nrow(rs_ARn),9)+ matrix(rep(rs_ARn$Oil_GJ*GHGI_FO,9),nrow(rs_ARn),9)+ matrix(rep(rs_ARn$Prop_GJ*GHGI_LP,9),nrow(rs_ARn),9))

# calculate avg reductions per renovation type
rs_ARn$redn_hren<-rs_ARn$redn_wren<-rs_ARn$redn_iren<-rs_ARn$redn_cren<-0
rs_ARn$change_hren_only<-rs_ARn$change_wren_only<-rs_ARn$change_iren_only<-rs_ARn$change_cren_only<-FALSE
for (k in 1:180000) { print(k) # this will probably take a while, about 3hs
  w<-which(rs_ARn$Building==k) 
  if (length(w) > 1) { # if there are any renovations
    for (j in 1:(length(w)-1)) {
      if (rs_ARn[w[j+1],]$change_cren!=rs_ARn[w[j],]$change_cren & identical(as.numeric(rs_ARn[w[j+1],31:33]),as.numeric(rs_ARn[w[j],31:33])) ) { # if only change_cren changes
        rs_ARn$redn_cren[w[j+1]]<-1-(rs_ARn$Tot_GJ[w[j+1]]/rs_ARn$Tot_GJ[w[j]])
        rs_ARn$change_cren_only[w[j+1]]<-TRUE
      }
      if (rs_ARn[w[j+1],]$change_iren!=rs_ARn[w[j],]$change_iren & identical(as.numeric(rs_ARn[w[j+1],c(30,32,33)]),as.numeric(rs_ARn[w[j],c(30,32,33)])) ) { # if only change_iren changes
        rs_ARn$redn_iren[w[j+1]]<-1-(rs_ARn$Tot_GJ[w[j+1]]/rs_ARn$Tot_GJ[w[j]])
        rs_ARn$change_iren_only[w[j+1]]<-TRUE
      } 
      if (rs_ARn[w[j+1],]$change_wren!=rs_ARn[w[j],]$change_wren & identical(as.numeric(rs_ARn[w[j+1],c(30,31,33)]),as.numeric(rs_ARn[w[j],c(30,31,33)])) ) { # if only change_wren changes
        rs_ARn$redn_wren[w[j+1]]<-1-(rs_ARn$Tot_GJ[w[j+1]]/rs_ARn$Tot_GJ[w[j]])
        rs_ARn$change_wren_only[w[j+1]]<-TRUE
      }
      if (rs_ARn[w[j+1],]$change_hren!=rs_ARn[w[j],]$change_hren & identical(as.numeric(rs_ARn[w[j+1],30:32]),as.numeric(rs_ARn[w[j],30:32])) ) { # if only change_hren changes
        rs_ARn$redn_hren[w[j+1]]<-1-(rs_ARn$Tot_GJ[w[j+1]]/rs_ARn$Tot_GJ[w[j]])
        rs_ARn$change_hren_only[w[j+1]]<-TRUE
      }
    }
  }
}

tapply(rs_ARn$redn_cren,rs_ARn$change_cren_only,mean) # 0.2%
tapply(rs_ARn$redn_iren,rs_ARn$change_iren_only,mean) # 12.0%
tapply(rs_ARn$redn_wren,rs_ARn$change_wren_only,mean) # 5.0%
tapply(rs_ARn$redn_hren,rs_ARn$change_hren_only,mean) # 10.2#

tapply(rs_ARn$redn_cren,list(rs_ARn$change_cren_only,rs_ARn$Geometry.Building.Type.RECS), mean) # highest in MH. Negative in MF, 
tapply(rs_ARn$redn_iren,list(rs_ARn$change_iren_only,rs_ARn$Geometry.Building.Type.RECS), mean) # highest in MF 2-4, followed by SFD
tapply(rs_ARn$redn_wren,list(rs_ARn$change_wren_only,rs_ARn$Geometry.Building.Type.RECS), mean) # # highest in MF 5+, lowest in MH
tapply(rs_ARn$redn_hren,list(rs_ARn$change_hren_only,rs_ARn$Geometry.Building.Type.RECS), mean) # highest in MH and SFD

tapply(rs_ARn$redn_cren,list(rs_ARn$change_cren_only,rs_ARn$Vintage), mean) # negative in old homes
tapply(rs_ARn$redn_iren,list(rs_ARn$change_iren_only,rs_ARn$Vintage), mean) # highest (~17%) in old homes
tapply(rs_ARn$redn_wren,list(rs_ARn$change_wren_only,rs_ARn$Vintage), mean) # very similar acroess vintages
tapply(rs_ARn$redn_hren,list(rs_ARn$change_hren_only,rs_ARn$Vintage), mean) # highest in old homes

tapply(rs_ARn$redn_cren,list(rs_ARn$change_cren_only,rs_ARn$Census.Region), mean) # only get savings in the south
tapply(rs_ARn$redn_iren,list(rs_ARn$change_iren_only,rs_ARn$Census.Region), mean) # highest in the MW, NE (14%)
tapply(rs_ARn$redn_wren,list(rs_ARn$change_wren_only,rs_ARn$Census.Region), mean) # highest in the West
tapply(rs_ARn$redn_hren,list(rs_ARn$change_hren_only,rs_ARn$Census.Region), mean) # highest (15-16%) in MW and NE

heat_typ_reg_ar<-tapply(rs_ARn$redn_hren,list(rs_ARn$change_hren_only,rs_ARn$Geometry.Building.Type.RECS,rs_ARn$Census.Region), mean)[2,,] 
cool_typ_reg_ar<-tapply(rs_ARn$redn_cren,list(rs_ARn$change_cren_only,rs_ARn$Geometry.Building.Type.RECS,rs_ARn$Census.Region), mean)[2,,] 
dhw_typ_reg_ar<-tapply(rs_ARn$redn_wren,list(rs_ARn$change_wren_only,rs_ARn$Geometry.Building.Type.RECS,rs_ARn$Census.Region), mean)[2,,] 
ins_typ_reg_ar<-tapply(rs_ARn$redn_iren,list(rs_ARn$change_iren_only,rs_ARn$Geometry.Building.Type.RECS,rs_ARn$Census.Region), mean)[2,,] 

heat_age_reg_ar<-tapply(rs_ARn$redn_hren,list(rs_ARn$change_hren_only,rs_ARn$Vintage.ACS,rs_ARn$Census.Region), mean)[2,,] 
cool_age_reg_ar<-tapply(rs_ARn$redn_cren,list(rs_ARn$change_cren_only,rs_ARn$Vintage.ACS,rs_ARn$Census.Region), mean)[2,,] 
dhw_age_reg_ar<-tapply(rs_ARn$redn_wren,list(rs_ARn$change_wren_only,rs_ARn$Vintage.ACS,rs_ARn$Census.Region), mean)[2,,] 
ins_age_reg_ar<-tapply(rs_ARn$redn_iren,list(rs_ARn$change_iren_only,rs_ARn$Vintage.ACS,rs_ARn$Census.Region), mean)[2,,] 

heat_typ_age_ar<-tapply(rs_ARn$redn_hren,list(rs_ARn$change_hren_only,rs_ARn$Geometry.Building.Type.RECS,rs_ARn$Vintage.ACS), mean)[2,,] 
cool_typ_age_ar<-tapply(rs_ARn$redn_cren,list(rs_ARn$change_cren_only,rs_ARn$Geometry.Building.Type.RECS,rs_ARn$Vintage.ACS), mean)[2,,] 
dhw_typ_age_ar<-tapply(rs_ARn$redn_wren,list(rs_ARn$change_wren_only,rs_ARn$Geometry.Building.Type.RECS,rs_ARn$Vintage.ACS), mean)[2,,] 
ins_typ_age_ar<-tapply(rs_ARn$redn_iren,list(rs_ARn$change_iren_only,rs_ARn$Geometry.Building.Type.RECS,rs_ARn$Vintage.ACS), mean)[2,,] 

save(heat_typ_reg_ar,heat_age_reg_ar,heat_typ_age_ar, cool_typ_reg_ar,cool_age_reg_ar,cool_typ_age_ar,dhw_typ_reg_ar,dhw_age_reg_ar,dhw_typ_age_ar,ins_typ_reg_ar,ins_age_reg_ar,ins_typ_age_ar,
     file = "Intermediate_results/AR_redn.RData")

# save this modified dataframe
save(rs_ARn,file = "Intermediate_results/RenAdvanced_EG.RData")

# compare the emissions trajectories with mid-case and LRE GHG intensity, base stock scenario, need to redo the column selections
# # mid-case elec
# colSums(rs_ARn[,205:213])*1e-9
# # LRE elec
# colSums(rs_ARn[,223:231])*1e-9
# 
# windows()
# plot(colSums(rs_ARn[,205:213])*1e-9,ylim = c(100,820))
# lines(colSums(rs_ARn[,223:231])*1e-9)
# lines(colSums(rs_RRn[,205:213])*1e-9,col="blue")
# lines(colSums(rs_RRn[,223:231])*1e-9,col="blue")

# repeat the long function of adding decay factors with the ER files ########
rs_all_ER<-rs_2020_60_ER
rs_all_ER$Year_Building<-paste(rs_all_ER$Year,rs_all_ER$Building,sep="_")

rs_all_ER<-rs_all_ER[,c("Year_Building","Year", "Building","County","State","Location.Region","Census.Division", "Census.Region", "ASHRAE.IECC.Climate.Zone.2004", "PUMA", "ISO.RTO.Region", "Geometry.Building.Type.ACS","Geometry.Building.Type.RECS",
                        "Vintage","Vintage.ACS","Heating.Fuel","Geometry.Floor.Area","Geometry.Foundation.Type","Geometry.Wall.Type","Geometry.Stories","Geometry.Garage",
                        "HVAC.Heating.Type.And.Fuel","HVAC.Heating.Efficiency","HVAC.Cooling.Type","HVAC.Cooling.Efficiency","Water.Heater.Fuel","Water.Heater.Efficiency",
                        "Clothes.Dryer","Infiltration", "change_cren","change_iren","change_wren","change_hren","base_weight")] # currently comes to 34 columns

rs_all_ER<-rs_all_ER[order(rs_all_ER$Building),]
#
rs_all_ER$TC<-"MF"
rs_all_ER[rs_all_ER$Geometry.Building.Type.RECS=="Single-Family Attached" | rs_all_ER$Geometry.Building.Type.RECS=="Single-Family Detached",]$TC<-"SF"
rs_all_ER[rs_all_ER$Geometry.Building.Type.RECS=="Mobile Home",]$TC<-"MH"
rs_all_ER$TC<-paste(rs_all_ER$TC,rs_all_ER$Vintage.ACS,sep="_")
rs_all_ER$ctyTC<-paste(rs_all_ER$County,rs_all_ER$TC,sep = "")
rs_all_ER$ctyTC<-gsub("2010s","2010-19",rs_all_ER$ctyTC)

# at this stage we are at 36 columns
# now add 9 columns for each stock scenario to bring us to 63
rs_all_ER<-left_join(rs_all_ER,sbm,by="ctyTC")
rs_all_ER<-left_join(rs_all_ER,shdrm,by="ctyTC")
rs_all_ER<-left_join(rs_all_ER,shmfm,by="ctyTC")
# rs_all_ER<-left_join(rs_all_ER,shdmm,by="ctyTC") excluding the high dem and high MF scenario

# rs_all_ER$sim.range<-"Undefined"
# THIS IS WHERE I RESTART
for (b in 1:180000) { # this takes a while, up to 4 hours, it's done once and can be loaded in using the call below
  print(b)
  w<-which(rs_all_ER$Building==b)

  for (sr in 1:(length(w)-1)) {
    rs_all_ER$sim.range[w[sr]]<-paste(rs_all_ER[w[sr],"Year"],rs_all_ER[w[sr+1],"Year"]-5,sep = ".")
  }
  for (sr in length(w)) {
    rs_all_ER$sim.range[w[sr]]<-paste(rs_all_ER[w[sr],"Year"],"2060",sep = ".")
  }
  # create concordance matrix to identify which weighting factors should be zero and non-zero
  conc<-matrix(rep(0,9*length(w)),length(w),9)
  for (c in 1:length(w)) {
    conc[c, which(names(rs_all_ER[37:45])==paste("wbase", substr(rs_all_ER$sim.range[w[c]],1,4),sep="_")):
           which(names(rs_all_ER[37:45])==paste("wbase", substr(rs_all_ER$sim.range[w[c]],6,9),sep="_"))]<-1
  }

  rs_all_ER[w,37:45]<-rs_all_ER[w,37:45]*conc
  rs_all_ER[w,46:54]<-rs_all_ER[w,46:54]*conc
  rs_all_ER[w,55:63]<-rs_all_ER[w,55:63]*conc

}
save(rs_all_ER,file="../Intermediate_results/RenExtElec_full.Rdata")
load("Intermediate_results/RenExtElec_full.Rdata")

# merge with the energy results
rs_all_ER_res<-rbind(rs2020_sum,rs25ER_sum,rs30ER_sum,rs35ER_sum,rs40ER_sum,rs45ER_sum,rs50ER_sum,rs55ER_sum,rs60ER_sum)
rs_all_ER_res<-rs_all_ER_res[,c(1:3,23,43,44,55:63,66,81,82,88,95,103,105:111,113:122,124:129,131,133,135:141,148:200)] # bigger reduced version

rs_ER<-merge(rs_all_ER,rs_all_ER_res)
rs_ERn<-rs_ER[order(rs_ER$Building),]

# continue from here

load("ExtData/ctycode.RData") # from the HSM repo
load("ExtData/GHGI_MidCase.RData") # Elec GHG int data in Mid-Case scenario
load("ExtData/GHGI_LowRECost.RData") # Elec GHG int data in Low RE Cost Scenario
ctycode_num<-ctycode
ctycode_num$GeoID<-as.numeric(ctycode_num$GeoID)

gicty_rto[gicty_rto$geoid10==46113,]$geoid10<-46102 # replace Shannon County SD with Oglala Lakota Cty
gicty_rto[gicty_rto$geoid10==2270,]$geoid10<-2158 # replace Wade Hampton AK with Kusilvak AK
gicty_rto<-merge(gicty_rto,ctycode_num,by.x="geoid10",by.y="GeoID") #

gicty_rto_yr<-gicty_rto[gicty_rto$Year %in% c(2020,2025,2030,2035,2040,2045,2050,2055,2060),] # get only the RS simulation years
gic<-dcast(gicty_rto_yr[,2:4],RS_ID ~ Year,value.var = "GHG_int")
names(gic)[2:8]<-paste("GHG_int",names(gic)[2:8],sep="_")
gic$GHG_int_2055<-0.95* gic$GHG_int_2050
gic$GHG_int_2060<-0.95* gic$GHG_int_2055
gic[,2:10]<-gic[,2:10]/3600 # convert from kg/MWh to kg/MJ

# do the same process for the Low RE Cost electricity data
gicty_rto_LREC[gicty_rto_LREC$geoid10==46113,]$geoid10<-46102 # replace Shannon County SD with Oglala Lakota Cty
gicty_rto_LREC[gicty_rto_LREC$geoid10==2270,]$geoid10<-2158 # replace Wade Hampton AK with Kusilvak AK
gicty_rto_LREC<-merge(gicty_rto_LREC,ctycode_num,by.x="geoid10",by.y="GeoID") #

gicty_rto_LREC_yr<-gicty_rto_LREC[gicty_rto_LREC$Year %in% c(2020,2025,2030,2035,2040,2045,2050,2055,2060),] # get only the RS simulation years
gic_LRE<-dcast(gicty_rto_LREC_yr[,2:4],RS_ID ~ Year,value.var = "GHG_int")
names(gic_LRE)[2:8]<-paste("GHG_int",names(gic_LRE)[2:8],sep="_")
gic_LRE$GHG_int_2055<-0.93* gic_LRE$GHG_int_2050 # assume greater decreases in GHGI post-2050 in LREC
gic_LRE$GHG_int_2060<-0.9* gic_LRE$GHG_int_2055 # assume greater decreases in GHGI post-2050 in LREC
gic_LRE[,2:10]<-gic_LRE[,2:10]/3600 # convert from kg/MWh to kg/MJ
names(gic_LRE)[2:10]<-paste(names(gic_LRE)[2:10],"LRE",sep = "_")

# add GHG intensities, Mid-Case
rs_ERn<-left_join(rs_ERn,gic,by = c("County" = "RS_ID"))
# add GHG intensities, Low RE Cost
rs_ERn<-left_join(rs_ERn,gic_LRE,by = c("County" = "RS_ID"))

# calculation total energy and GHG
GHGI_FO<-((.07396)+(25*3e-6)+(298*6e-7))/1.055  # intensity for heating oil (DFO #2) in kgCO2eq / MJ
GHGI_NG<-((0.05302)+(25*10e-6) + (298*1e-7))/1.055  # intensity for natural gas in kgCO2eq / MJ
GHGI_LP<-((.06298)+(25*3e-6)+(298*6e-7))/1.055   # intensity for LPG in kgCO2eq / MJ

# total energy in GJ
rs_ERn[,c("Tot_GJ_base_2020",  "Tot_GJ_base_2025","Tot_GJ_base_2030","Tot_GJ_base_2035","Tot_GJ_base_2040","Tot_GJ_base_2045","Tot_GJ_base_2050","Tot_GJ_base_2055","Tot_GJ_base_2060")]<-
  (rs_ERn$base_weight*rs_ERn[,c("wbase_2020", "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*
  (rs_ERn$Elec_GJ+rs_ERn$Gas_GJ+rs_ERn$Prop_GJ+rs_ERn$Oil_GJ)

rs_ERn[,c("Tot_GJ_hiDR_2020",  "Tot_GJ_hiDR_2025","Tot_GJ_hiDR_2030","Tot_GJ_hiDR_2035","Tot_GJ_hiDR_2040","Tot_GJ_hiDR_2045","Tot_GJ_hiDR_2050","Tot_GJ_hiDR_2055","Tot_GJ_hiDR_2060")]<-
  (rs_ERn$base_weight*rs_ERn[,c("whiDR_2020", "whiDR_2025", "whiDR_2030", "whiDR_2035", "whiDR_2040", "whiDR_2045", "whiDR_2050", "whiDR_2055", "whiDR_2060")])*
  (rs_ERn$Elec_GJ+rs_ERn$Gas_GJ+rs_ERn$Prop_GJ+rs_ERn$Oil_GJ)

rs_ERn[,c("Tot_GJ_hiMF_2020",  "Tot_GJ_hiMF_2025","Tot_GJ_hiMF_2030","Tot_GJ_hiMF_2035","Tot_GJ_hiMF_2040","Tot_GJ_hiMF_2045","Tot_GJ_hiMF_2050","Tot_GJ_hiMF_2055","Tot_GJ_hiMF_2060")]<-
  (rs_ERn$base_weight*rs_ERn[,c("whiMF_2020", "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")])*
  (rs_ERn$Elec_GJ+rs_ERn$Gas_GJ+rs_ERn$Prop_GJ+rs_ERn$Oil_GJ)

# tot kgGHG per archetype group/year in kg
rs_ERn[,c("EnGHGkg_base_2020","EnGHGkg_base_2025","EnGHGkg_base_2030","EnGHGkg_base_2035","EnGHGkg_base_2040","EnGHGkg_base_2045","EnGHGkg_base_2050","EnGHGkg_base_2055","EnGHGkg_base_2060")]<-1000* 
  (rs_ERn$base_weight*rs_ERn[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*
  (rs_ERn$Elec_GJ*rs_ERn[,c("GHG_int_2020", "GHG_int_2025","GHG_int_2030","GHG_int_2035","GHG_int_2040","GHG_int_2045","GHG_int_2050","GHG_int_2055","GHG_int_2060")]+
     matrix(rep(rs_ERn$Gas_GJ*GHGI_NG,9),nrow(rs_ERn),9)+ matrix(rep(rs_ERn$Oil_GJ*GHGI_FO,9),nrow(rs_ERn),9)+ matrix(rep(rs_ERn$Prop_GJ*GHGI_LP,9),nrow(rs_ERn),9))

# tot kgGHG per archetype group/year in kg
rs_ERn[,c("EnGHGkg_hiDR_2020","EnGHGkg_hiDR_2025","EnGHGkg_hiDR_2030","EnGHGkg_hiDR_2035","EnGHGkg_hiDR_2040","EnGHGkg_hiDR_2045","EnGHGkg_hiDR_2050","EnGHGkg_hiDR_2055","EnGHGkg_hiDR_2060")]<-1000* 
  (rs_ERn$base_weight*rs_ERn[,c("whiDR_2020",  "whiDR_2025", "whiDR_2030", "whiDR_2035", "whiDR_2040", "whiDR_2045", "whiDR_2050", "whiDR_2055", "whiDR_2060")])*
  (rs_ERn$Elec_GJ*rs_ERn[,c("GHG_int_2020", "GHG_int_2025","GHG_int_2030","GHG_int_2035","GHG_int_2040","GHG_int_2045","GHG_int_2050","GHG_int_2055","GHG_int_2060")]+
     matrix(rep(rs_ERn$Gas_GJ*GHGI_NG,9),nrow(rs_ERn),9)+ matrix(rep(rs_ERn$Oil_GJ*GHGI_FO,9),nrow(rs_ERn),9)+ matrix(rep(rs_ERn$Prop_GJ*GHGI_LP,9),nrow(rs_ERn),9))

rs_ERn[,c("EnGHGkg_hiMF_2020","EnGHGkg_hiMF_2025","EnGHGkg_hiMF_2030","EnGHGkg_hiMF_2035","EnGHGkg_hiMF_2040","EnGHGkg_hiMF_2045","EnGHGkg_hiMF_2050","EnGHGkg_hiMF_2055","EnGHGkg_hiMF_2060")]<-1000*
  (rs_ERn$base_weight*rs_ERn[,c("whiMF_2020",  "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")])*
  (rs_ERn$Elec_GJ*rs_ERn[,c("GHG_int_2020", "GHG_int_2025","GHG_int_2030","GHG_int_2035","GHG_int_2040","GHG_int_2045","GHG_int_2050","GHG_int_2055","GHG_int_2060")]+
     matrix(rep(rs_ERn$Gas_GJ*GHGI_NG,9),nrow(rs_ERn),9)+ matrix(rep(rs_ERn$Oil_GJ*GHGI_FO,9),nrow(rs_ERn),9)+ matrix(rep(rs_ERn$Prop_GJ*GHGI_LP,9),nrow(rs_ERn),9))

# tot LRE kgGHG per archetype group/year in kg
rs_ERn[,c("EnGHGkg_base_2020_LRE","EnGHGkg_base_2025_LRE","EnGHGkg_base_2030_LRE","EnGHGkg_base_2035_LRE","EnGHGkg_base_2040_LRE","EnGHGkg_base_2045_LRE","EnGHGkg_base_2050_LRE","EnGHGkg_base_2055_LRE","EnGHGkg_base_2060_LRE")]<-1000* 
  (rs_ERn$base_weight*rs_ERn[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*
  (rs_ERn$Elec_GJ*rs_ERn[,c("GHG_int_2020_LRE", "GHG_int_2025_LRE","GHG_int_2030_LRE","GHG_int_2035_LRE","GHG_int_2040_LRE","GHG_int_2045_LRE","GHG_int_2050_LRE","GHG_int_2055_LRE","GHG_int_2060_LRE")]+
     matrix(rep(rs_ERn$Gas_GJ*GHGI_NG,9),nrow(rs_ERn),9)+ matrix(rep(rs_ERn$Oil_GJ*GHGI_FO,9),nrow(rs_ERn),9)+ matrix(rep(rs_ERn$Prop_GJ*GHGI_LP,9),nrow(rs_ERn),9))

# tot LRE kgGHG per archetype group/year in kg
rs_ERn[,c("EnGHGkg_hiDR_2020_LRE","EnGHGkg_hiDR_2025_LRE","EnGHGkg_hiDR_2030_LRE","EnGHGkg_hiDR_2035_LRE","EnGHGkg_hiDR_2040_LRE","EnGHGkg_hiDR_2045_LRE","EnGHGkg_hiDR_2050_LRE","EnGHGkg_hiDR_2055_LRE","EnGHGkg_hiDR_2060_LRE")]<-1000* 
  (rs_ERn$base_weight*rs_ERn[,c("whiDR_2020",  "whiDR_2025", "whiDR_2030", "whiDR_2035", "whiDR_2040", "whiDR_2045", "whiDR_2050", "whiDR_2055", "whiDR_2060")])*
  (rs_ERn$Elec_GJ*rs_ERn[,c("GHG_int_2020_LRE", "GHG_int_2025_LRE","GHG_int_2030_LRE","GHG_int_2035_LRE","GHG_int_2040_LRE","GHG_int_2045_LRE","GHG_int_2050_LRE","GHG_int_2055_LRE","GHG_int_2060_LRE")]+
     matrix(rep(rs_ERn$Gas_GJ*GHGI_NG,9),nrow(rs_ERn),9)+ matrix(rep(rs_ERn$Oil_GJ*GHGI_FO,9),nrow(rs_ERn),9)+ matrix(rep(rs_ERn$Prop_GJ*GHGI_LP,9),nrow(rs_ERn),9))

# tot LRE kgGHG per archetype group/year in kg
rs_ERn[,c("EnGHGkg_hiMF_2020_LRE","EnGHGkg_hiMF_2025_LRE","EnGHGkg_hiMF_2030_LRE","EnGHGkg_hiMF_2035_LRE","EnGHGkg_hiMF_2040_LRE","EnGHGkg_hiMF_2045_LRE","EnGHGkg_hiMF_2050_LRE","EnGHGkg_hiMF_2055_LRE","EnGHGkg_hiMF_2060_LRE")]<-1000* 
  (rs_ERn$base_weight*rs_ERn[,c("whiMF_2020",  "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")])*
  (rs_ERn$Elec_GJ*rs_ERn[,c("GHG_int_2020_LRE", "GHG_int_2025_LRE","GHG_int_2030_LRE","GHG_int_2035_LRE","GHG_int_2040_LRE","GHG_int_2045_LRE","GHG_int_2050_LRE","GHG_int_2055_LRE","GHG_int_2060_LRE")]+
     matrix(rep(rs_ERn$Gas_GJ*GHGI_NG,9),nrow(rs_ERn),9)+ matrix(rep(rs_ERn$Oil_GJ*GHGI_FO,9),nrow(rs_ERn),9)+ matrix(rep(rs_ERn$Prop_GJ*GHGI_LP,9),nrow(rs_ERn),9))

# calculate avg reductions per renovation type
rs_ERn$redn_hren<-rs_ERn$redn_wren<-rs_ERn$redn_iren<-rs_ERn$redn_cren<-0
rs_ERn$change_hren_only<-rs_ERn$change_wren_only<-rs_ERn$change_iren_only<-rs_ERn$change_cren_only<-FALSE
for (k in 1:180000) { print(k) # this will probably take a while, about 3hs
  w<-which(rs_ERn$Building==k) 
  if (length(w) > 1) { # if there are any renovations
    for (j in 1:(length(w)-1)) {
      if (rs_ERn[w[j+1],]$change_cren!=rs_ERn[w[j],]$change_cren & identical(as.numeric(rs_ERn[w[j+1],31:33]),as.numeric(rs_ERn[w[j],31:33])) ) { # if only change_cren changes
        rs_ERn$redn_cren[w[j+1]]<-1-(rs_ERn$Tot_GJ[w[j+1]]/rs_ERn$Tot_GJ[w[j]])
        rs_ERn$change_cren_only[w[j+1]]<-TRUE
      }
      if (rs_ERn[w[j+1],]$change_iren!=rs_ERn[w[j],]$change_iren & identical(as.numeric(rs_ERn[w[j+1],c(30,32,33)]),as.numeric(rs_ERn[w[j],c(30,32,33)])) ) { # if only change_iren changes
        rs_ERn$redn_iren[w[j+1]]<-1-(rs_ERn$Tot_GJ[w[j+1]]/rs_ERn$Tot_GJ[w[j]])
        rs_ERn$change_iren_only[w[j+1]]<-TRUE
      } 
      if (rs_ERn[w[j+1],]$change_wren!=rs_ERn[w[j],]$change_wren & identical(as.numeric(rs_ERn[w[j+1],c(30,31,33)]),as.numeric(rs_ERn[w[j],c(30,31,33)])) ) { # if only change_wren changes
        rs_ERn$redn_wren[w[j+1]]<-1-(rs_ERn$Tot_GJ[w[j+1]]/rs_ERn$Tot_GJ[w[j]])
        rs_ERn$change_wren_only[w[j+1]]<-TRUE
      }
      if (rs_ERn[w[j+1],]$change_hren!=rs_ERn[w[j],]$change_hren & identical(as.numeric(rs_ERn[w[j+1],30:32]),as.numeric(rs_ERn[w[j],30:32])) ) { # if only change_hren changes
        rs_ERn$redn_hren[w[j+1]]<-1-(rs_ERn$Tot_GJ[w[j+1]]/rs_ERn$Tot_GJ[w[j]])
        rs_ERn$change_hren_only[w[j+1]]<-TRUE
      }
    }
  }
}

tapply(rs_ERn$redn_cren,rs_ERn$change_cren_only,mean) # 0.2%
tapply(rs_ERn$redn_iren,rs_ERn$change_iren_only,mean) # 9.8%
tapply(rs_ERn$redn_wren,rs_ERn$change_wren_only,mean) # 7.2%
tapply(rs_ERn$redn_hren,rs_ERn$change_hren_only,mean) # 15.1%

tapply(rs_ERn$redn_cren,list(rs_ERn$change_cren_only,rs_ERn$Geometry.Building.Type.RECS), mean) # highest in MH. Negative in MF, 
tapply(rs_ERn$redn_iren,list(rs_ERn$change_iren_only,rs_ERn$Geometry.Building.Type.RECS), mean) # highest in MF 2-4, followed by SFD
tapply(rs_ERn$redn_wren,list(rs_ERn$change_wren_only,rs_ERn$Geometry.Building.Type.RECS), mean) # # highest in MF 5+, lowest in MH
tapply(rs_ERn$redn_hren,list(rs_ERn$change_hren_only,rs_ERn$Geometry.Building.Type.RECS), mean) # highest in MH and SFD

tapply(rs_ERn$redn_cren,list(rs_ERn$change_cren_only,rs_ERn$Vintage), mean) # negative in old homes
tapply(rs_ERn$redn_iren,list(rs_ERn$change_iren_only,rs_ERn$Vintage), mean) # highest (~17%) in old homes
tapply(rs_ERn$redn_wren,list(rs_ERn$change_wren_only,rs_ERn$Vintage), mean) # very similar acroess vintages
tapply(rs_ERn$redn_hren,list(rs_ERn$change_hren_only,rs_ERn$Vintage), mean) # highest in old homes

tapply(rs_ERn$redn_cren,list(rs_ERn$change_cren_only,rs_ERn$Census.Region), mean) # only get savings in the south
tapply(rs_ERn$redn_iren,list(rs_ERn$change_iren_only,rs_ERn$Census.Region), mean) # highest in the MW, NE (14%)
tapply(rs_ERn$redn_wren,list(rs_ERn$change_wren_only,rs_ERn$Census.Region), mean) # highest in the West
tapply(rs_ERn$redn_hren,list(rs_ERn$change_hren_only,rs_ERn$Census.Region), mean) # highest (15-16%) in MW and NE

heat_typ_reg_er<-tapply(rs_ERn$redn_hren,list(rs_ERn$change_hren_only,rs_ERn$Geometry.Building.Type.RECS,rs_ERn$Census.Region), mean)[2,,] 
cool_typ_reg_er<-tapply(rs_ERn$redn_cren,list(rs_ERn$change_cren_only,rs_ERn$Geometry.Building.Type.RECS,rs_ERn$Census.Region), mean)[2,,] 
dhw_typ_reg_er<-tapply(rs_ERn$redn_wren,list(rs_ERn$change_wren_only,rs_ERn$Geometry.Building.Type.RECS,rs_ERn$Census.Region), mean)[2,,] 
ins_typ_reg_er<-tapply(rs_ERn$redn_iren,list(rs_ERn$change_iren_only,rs_ERn$Geometry.Building.Type.RECS,rs_ERn$Census.Region), mean)[2,,] 

heat_age_reg_er<-tapply(rs_ERn$redn_hren,list(rs_ERn$change_hren_only,rs_ERn$Vintage.ACS,rs_ERn$Census.Region), mean)[2,,] 
cool_age_reg_er<-tapply(rs_ERn$redn_cren,list(rs_ERn$change_cren_only,rs_ERn$Vintage.ACS,rs_ERn$Census.Region), mean)[2,,] 
dhw_age_reg_er<-tapply(rs_ERn$redn_wren,list(rs_ERn$change_wren_only,rs_ERn$Vintage.ACS,rs_ERn$Census.Region), mean)[2,,] 
ins_age_reg_er<-tapply(rs_ERn$redn_iren,list(rs_ERn$change_iren_only,rs_ERn$Vintage.ACS,rs_ERn$Census.Region), mean)[2,,] 

heat_typ_age_er<-tapply(rs_ERn$redn_hren,list(rs_ERn$change_hren_only,rs_ERn$Geometry.Building.Type.RECS,rs_ERn$Vintage.ACS), mean)[2,,] 
cool_typ_age_er<-tapply(rs_ERn$redn_cren,list(rs_ERn$change_cren_only,rs_ERn$Geometry.Building.Type.RECS,rs_ERn$Vintage.ACS), mean)[2,,] 
dhw_typ_age_er<-tapply(rs_ERn$redn_wren,list(rs_ERn$change_wren_only,rs_ERn$Geometry.Building.Type.RECS,rs_ERn$Vintage.ACS), mean)[2,,] 
ins_typ_age_er<-tapply(rs_ERn$redn_iren,list(rs_ERn$change_iren_only,rs_ERn$Geometry.Building.Type.RECS,rs_ERn$Vintage.ACS), mean)[2,,] 

save(heat_typ_reg_er,heat_age_reg_er,heat_typ_age_er, cool_typ_reg_er,cool_age_reg_er,cool_typ_age_er,dhw_typ_reg_er,dhw_age_reg_er,dhw_typ_age_er,ins_typ_reg_er,ins_age_reg_er,ins_typ_age_er,
     file = "Intermediate_results/ER_redn.RData")

# save this modified dataframe
save(rs_ERn,file = "Intermediate_results/RenExtElec_EG.RData")

# this needs redone with all EG files, using the new R final projections
# Now all Renovation data are calculated, load in projection results ######
# rsbase_base<-read.csv("Eagle_outputs/res_proj_base.csv")
load("Eagle_outputs/Complete_results/res_base_final.RData")
rsbase_base<-rsn

# load("../Intermediate_results/agg_bscsv.RData") # should be already loaded if run from beginning
nce<-read.csv("../HSM_github/HSM_results/NewConEstimates.csv")
nce<-nce[2:9,]
names(nce)<-c("Year","base","hiDR","hiMF","hiDRMF")
nce$Year<-seq(2025,2060,5)

bs_base_base<-bs_base_all[bs_base_all$scen=="base",]
bs_base_base$Year<-bs_base_base$sim_year

bs_base_base$Year_Building<-paste(bs_base_base$Year,bs_base_base$Building,sep="_")

bs_base_base<-bs_base_base[,c("Year_Building","Year", "Building","County","State","Location.Region","Census.Division", "Census.Region", "ASHRAE.IECC.Climate.Zone.2004", "PUMA", "ISO.RTO.Region", "Geometry.Building.Type.ACS","Geometry.Building.Type.RECS",
                        "Vintage","Vintage.ACS","Heating.Fuel","Geometry.Floor.Area","Geometry.Foundation.Type","Geometry.Wall.Type","Geometry.Stories","Geometry.Garage",
                        "HVAC.Heating.Type.And.Fuel","HVAC.Heating.Efficiency","HVAC.Cooling.Type","HVAC.Cooling.Efficiency","Water.Heater.Fuel","Water.Heater.Efficiency",
                        "Clothes.Dryer","Infiltration")] # currently comes to 29 columns, without "change_cren","change_iren","change_wren","change_hren", "base_weight". Add these in for consistency
bs_base_base[,c("change_cren","change_iren","change_wren","change_hren")]<-0

bs_base_base$base_weight<-0
# add base weights for each sim year, based on the new construction estimates
for (y in seq(2025,2060,5)) {
  bs_base_base[bs_base_base$Year==y,]$base_weight<-nce[nce$Year==y,]$base/15000
}
# load("../Intermediate_results/decayFactorsProj.RData") # should be already loaded 

bs_base_base$TC<-"MF"
bs_base_base[bs_base_base$Geometry.Building.Type.RECS=="Single-Family Attached" | bs_base_base$Geometry.Building.Type.RECS=="Single-Family Detached",]$TC<-"SF"
bs_base_base[bs_base_base$Geometry.Building.Type.RECS=="Mobile Home",]$TC<-"MH"
bs_base_base$TC<-paste(bs_base_base$TC,bs_base_base$Vintage.ACS,sep="_")
bs_base_base$ctyTC<-paste(bs_base_base$County,bs_base_base$TC,sep = "")
bs_base_base$ctyTC<-gsub("2010s","2010-19",bs_base_base$ctyTC)
bs_base_base$ctyTC<-gsub("2020s","2020-29",bs_base_base$ctyTC)
bs_base_base$ctyTC<-gsub("2030s","2030-39",bs_base_base$ctyTC)
bs_base_base$ctyTC<-gsub("2040s","2040-49",bs_base_base$ctyTC)
bs_base_base$ctyTC<-gsub("2050s","2050-60",bs_base_base$ctyTC)

# at this stage we are at 36 columns
# now add 9 columns for the applicable stock scenario to bring us to 45
bs_base_base<-left_join(bs_base_base,sbm,by="ctyTC")

# merge with the energy results
rsbb_sum<-result_sum(rsbase_base,0)
rsbb_sum<-rsbb_sum[,c(1:3,23,43,44,55:63,66,81,82,88,95,103,105:111,113:122,124:129,131,133,135:141,148:200)] # bigger version

all.equal(rsbb_sum$building_id,bs_base_base$Building) # check if its true
rs_base<-merge(bs_base_base,rsbb_sum,by.x = "Building",by.y = "building_id")
rs_base<-rs_base[,-c(which(names(rs_base) %in% c("Year.y", "Year_Building.y")))]
names(rs_base)[2:3]<-c("Year_Building","Year")

# modify the failed TX simulations no longer neccessar

# add GHG intensities, Mid-Case
rs_base<-left_join(rs_base,gic,by = c("County" = "RS_ID"))
# add GHG intensities, Low RE Cost
rs_base<-left_join(rs_base,gic_LRE,by = c("County" = "RS_ID"))

rs_base[rs_base$Year==2030,]$wbase_2025<-0
rs_base[rs_base$Year==2040,]$wbase_2035<-0
rs_base[rs_base$Year==2050,]$wbase_2045<-0
rs_base[rs_base$Year==2060,]$wbase_2055<-0

rs_base[,c("Tot_GJ_base_2020",  "Tot_GJ_base_2025","Tot_GJ_base_2030","Tot_GJ_base_2035","Tot_GJ_base_2040","Tot_GJ_base_2045","Tot_GJ_base_2050","Tot_GJ_base_2055","Tot_GJ_base_2060")]<-
  (rs_base$base_weight*rs_base[,c("wbase_2020", "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*
  (rs_base$Elec_GJ+rs_base$Gas_GJ+rs_base$Prop_GJ+rs_base$Oil_GJ)

# tot kgGHG per archetype group/year in kg
rs_base[,c("EnGHGkg_base_2020","EnGHGkg_base_2025","EnGHGkg_base_2030","EnGHGkg_base_2035","EnGHGkg_base_2040","EnGHGkg_base_2045","EnGHGkg_base_2050","EnGHGkg_base_2055","EnGHGkg_base_2060")]<-1000* 
  (rs_base$base_weight*rs_base[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*
  (rs_base$Elec_GJ*rs_base[,c("GHG_int_2020", "GHG_int_2025","GHG_int_2030","GHG_int_2035","GHG_int_2040","GHG_int_2045","GHG_int_2050","GHG_int_2055","GHG_int_2060")]+
     matrix(rep(rs_base$Gas_GJ*GHGI_NG,9),nrow(rs_base),9)+ matrix(rep(rs_base$Oil_GJ*GHGI_FO,9),nrow(rs_base),9)+ matrix(rep(rs_base$Prop_GJ*GHGI_LP,9),nrow(rs_base),9))

# tot LRE kgGHG per archetype group/year in kg
rs_base[,c("EnGHGkg_base_2020_LRE","EnGHGkg_base_2025_LRE","EnGHGkg_base_2030_LRE","EnGHGkg_base_2035_LRE","EnGHGkg_base_2040_LRE","EnGHGkg_base_2045_LRE","EnGHGkg_base_2050_LRE","EnGHGkg_base_2055_LRE","EnGHGkg_base_2060_LRE")]<-1000* 
  (rs_base$base_weight*rs_base[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*
  (rs_base$Elec_GJ*rs_base[,c("GHG_int_2020_LRE", "GHG_int_2025_LRE","GHG_int_2030_LRE","GHG_int_2035_LRE","GHG_int_2040_LRE","GHG_int_2045_LRE","GHG_int_2050_LRE","GHG_int_2055_LRE","GHG_int_2060_LRE")]+
     matrix(rep(rs_base$Gas_GJ*GHGI_NG,9),nrow(rs_base),9)+ matrix(rep(rs_base$Oil_GJ*GHGI_FO,9),nrow(rs_base),9)+ matrix(rep(rs_base$Prop_GJ*GHGI_LP,9),nrow(rs_base),9))


# some summary stats
# growth of new housing stock
colSums((rs_base$base_weight*rs_base[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")]))
# avg household energy consumption per construction year
tapply(rs_base$Tot_GJ,rs_base$Year,mean)
# avg energy efficiency per construction year
tapply(rs_base$Tot_MJ_m2,rs_base$Year,mean)

# avg energy efficiency per construction year, in kWh/m2. These are quite efficient. In EU, current range is 200-300 kWh/m2 https://ec.europa.eu/energy/eu-buildings-factsheets-topics-tree/energy-use-buildings_en, actually maybe more like 150 https://www.osti.gov/servlets/purl/1249501
tapply(rs_base$Tot_MJ_m2,rs_base$Year,mean)/3.6

# total GHG emissions from NC 2025-2060 in Mid-Case
colSums((rs_base[,176:184]))*1e-9

# total GHG emissions from NC 2025-2060 in LRE scenario. I was a bit confused about this, but I think the reduction between 2040-2045 is from reductions in GHGI of elec, which outweigh the stock growth
colSums((rs_base[,185:193]))*1e-9
# see the difference bewteen average GHGI elec here
mean(rs_base$GHG_int_2040_LRE)
mean(rs_base$GHG_int_2045_LRE)

save(rs_base,file="Intermediate_results/rs_base_EG.RData")
# load("../Intermediate_results/rs_base_EG.RData")
# now try to merge with the AR/RR files

load("Intermediate_results/RenStandard_EG.RData")

n1<-names(rs_RRn) # <2020 stock, Reg Ren
n2<-names(rs_base) # new construction
bdiff<-rs_RRn[,!n1 %in% n2]

# new insert: before binding rows, make the Building codes in rs_base distinct from thos in rs_RRb
rs_base$Building<-180000+rs_base$Building
rs_base$Year_Building<-paste(rs_base$Year,rs_base$Building,sep="_")
rs_base_all_RR<-bind_rows(rs_RRn,rs_base)

rs_base_all_RR<-rs_base_all_RR[,names(rs_base_all_RR) %in% names(rs_base)]

# evolution of efficiency over cohorts, in kWh/m2
tapply(rs_base_all_RR$Tot_MJ_m2,rs_base_all_RR$Vintage,mean)/3.6
# evolution of efficiency over cohorts and time, in kWh/m2
tapply(rs_base_all_RR$Tot_MJ_m2,list(rs_base_all_RR$Vintage,rs_base_all_RR$Year),mean)/3.6

# example of calculating national level emissions in each year a la  Fig 2, except without construction related emissions
colSums(rs_base_all_RR[,176:184])*1e-9 # 
# example of calculating national level emissions in each year a la  Fig 2, LRE elec
colSums(rs_base_all_RR[,185:193])*1e-9 # 

# example of calculation state level emissions in one year
tapply(rs_base_all_RR$EnGHGkg_base_2020,rs_base_all_RR$State,sum)*1e-9
tapply(rs_base_all_RR$EnGHGkg_base_2060,rs_base_all_RR$State,sum)*1e-9
# biggest reductions in AL, OK, WV, SC, much of this likely populations related
tapply(rs_base_all_RR$EnGHGkg_base_2060,rs_base_all_RR$State,sum)/tapply(rs_base_all_RR$EnGHGkg_base_2020,rs_base_all_RR$State,sum)

save(rs_base_all_RR,file="Final_results/res_base_RR.RData")

load("../Intermediate_results/RenAdvanced_EG.RData")

n1<-names(rs_ARn) # <2020 stock, Reg Ren
n2<-names(rs_base) # new construction
bdiff<-rs_ARn[,!n1 %in% n2]

rs_base_all_AR<-bind_rows(rs_ARn,rs_base)

rs_base_all_AR<-rs_base_all_AR[,names(rs_base_all_AR) %in% names(rs_base)]

# evolution of efficiency over cohorts, in kWh/m2
tapply(rs_base_all_AR$Tot_MJ_m2,rs_base_all_AR$Vintage,mean)/3.6
# evolution of efficiency over cohorts and time, in kWh/m2
tapply(rs_base_all_AR$Tot_MJ_m2,list(rs_base_all_AR$Vintage,rs_base_all_AR$Year),mean)/3.6

# example of calculating national level emissions in each year a la  Fig 2, except without construction related emissions
colSums(rs_base_all_AR[,176:184])*1e-9 # 
# example of calculating national level emissions in each year a la  Fig 2, LREC
colSums(rs_base_all_AR[,185:193])*1e-9 # 

# example of calculation state level emissions in one year
tapply(rs_base_all_AR$EnGHGkg_base_2020,rs_base_all_AR$State,sum)*1e-9
tapply(rs_base_all_AR$EnGHGkg_base_2060,rs_base_all_AR$State,sum)*1e-9
# biggest reductions in AL, OK, WV, SC, much of this likely populations related
tapply(rs_base_all_AR$EnGHGkg_base_2060,rs_base_all_AR$State,sum)/tapply(rs_base_all_AR$EnGHGkg_base_2020,rs_base_all_AR$State,sum)

save(rs_base_all_AR,file="../Final_results/res_base_AR.RData")
