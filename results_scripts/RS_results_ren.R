rm(list=ls()) # clear workspace i.e. remove saved variables
cat("\014") # clear console
library(dplyr)
library(reshape2)

# Last Update Peter Berrill May 6 2022

# Purpose: Create dataframe combining energy and GHG results for entire renovation scenarios; assess the reductions in Energy/GHG in renovation scenarios

# Inputs: - Eagle_outputs/Complete_results/res_2020_final.RData,  ResStock results for stock in 2020
#         - Eagle_outputs/Complete_results/res_RR_2025_final.RData, ResStock results for <2020-built stock in 2025, with Reg Renovation
#         - Eagle_outputs/Complete_results/res_RR_2030_final.RData, ResStock results for <2020-built stock in 2030, with Reg Renovation
#         - Eagle_outputs/Complete_results/res_RR_2035_final.RData, ResStock results for <2020-built stock in 2035, with Reg Renovation
#         - Eagle_outputs/Complete_results/res_RR_2040_final.RData, ResStock results for <2020-built stock in 2040, with Reg Renovation
#         - Eagle_outputs/Complete_results/res_RR_2045_final.RData, ResStock results for <2020-built stock in 2045, with Reg Renovation
#         - Eagle_outputs/Complete_results/res_RR_2050_final.RData, ResStock results for <2020-built stock in 2050, with Reg Renovation
#         - Eagle_outputs/Complete_results/res_RR_2055_final.RData, ResStock results for <2020-built stock in 2055, with Reg Renovation
#         - Eagle_outputs/Complete_results/res_RR_2060_final.RData, ResStock results for <2020-built stock in 2060, with Reg Renovation
#         - Eagle_outputs/Complete_results/res_AR_2025_final.RData, ResStock results for <2020-built stock in 2025, with Adv Renovation
#         - Eagle_outputs/Complete_results/res_AR_2030_final.RData, ResStock results for <2020-built stock in 2030, with Adv Renovation
#         - Eagle_outputs/Complete_results/res_AR_2035_final.RData, ResStock results for <2020-built stock in 2035, with Adv Renovation
#         - Eagle_outputs/Complete_results/res_AR_2040_final.RData, ResStock results for <2020-built stock in 2040, with Adv Renovation
#         - Eagle_outputs/Complete_results/res_AR_2045_final.RData, ResStock results for <2020-built stock in 2045, with Adv Renovation
#         - Eagle_outputs/Complete_results/res_AR_2050_final.RData, ResStock results for <2020-built stock in 2050, with Adv Renovation
#         - Eagle_outputs/Complete_results/res_AR_2055_final.RData, ResStock results for <2020-built stock in 2055, with Adv Renovation
#         - Eagle_outputs/Complete_results/res_AR_2060_final.RData, ResStock results for <2020-built stock in 2060, with Adv Renovation
#         - Eagle_outputs/Complete_results/res_ER_2025_final.RData, ResStock results for <2020-built stock in 2025, with Ext Renovation
#         - Eagle_outputs/Complete_results/res_ER_2030_final.RData, ResStock results for <2020-built stock in 2030, with Ext Renovation
#         - Eagle_outputs/Complete_results/res_ER_2035_final.RData, ResStock results for <2020-built stock in 2035, with Ext Renovation
#         - Eagle_outputs/Complete_results/res_ER_2040_final.RData, ResStock results for <2020-built stock in 2040, with Ext Renovation
#         - Eagle_outputs/Complete_results/res_ER_2045_final.RData, ResStock results for <2020-built stock in 2045, with Ext Renovation
#         - Eagle_outputs/Complete_results/res_ER_2050_final.RData, ResStock results for <2020-built stock in 2050, with Ext Renovation
#         - Eagle_outputs/Complete_results/res_ER_2055_final.RData, ResStock results for <2020-built stock in 2055, with Ext Renovation
#         - Eagle_outputs/Complete_results/res_ER_2060_final.RData, ResStock results for <2020-built stock in 2060, with Ext Renovation
#         - Intermediate_results/agg_bscsv.RData, building characteristics for future cohorts
#         - Intermediate_results/RenAdvanced.RData, renovation building characteristis - Adv Ren
#         - Intermediate_results/RenStandard.RData, renovation building characteristics - Reg Ren
#         - Intermediate_results/RenExtElec.RData, renovation building characteristics - Ext Ren
#         - ExtData/ctycode.RData, county names and FIPS codes
#         - ExtData/GHGI_MidCase.RData, NREL GHG intensities of electricity, Mid-Case scenario
#         - ExtData/GHGI_LowRECost.RData", NREL GHG intensities of electricity, Mid-Case scenario
#         - NCC_Review_Analysis/CBA/data/MT.csv'

# Outputs: 
#         - Final_results/renGHG.RData
#         - Intermediate_results/RenStandard_full.Rdata
#         - Intermediate_results/RenStandard_EG.RData
#         - Intermediate_results/RR_redn.RData
#         - Intermediate_results/RenAdvanced_full.Rdata
#         - Intermediate_results/RenAdvanced_EG.RData
#         - Intermediate_results/AR_redn.RData
#         - Intermediate_results/RenExtElec_full.Rdata
#         - Intermediate_results/RenExtElec_EG.RData
#         - Intermediate_results/ER_redn.Rdata



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
#rs<-rs25RR
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


rs_all_RR<-rs_2020_60_RR
rs_all_RR$Year_Building<-paste(rs_all_RR$Year,rs_all_RR$Building,sep="_")
# 
rs_all_RR<-rs_all_RR[,c("Year_Building","Year", "Building","County","State","Location.Region","Census.Division", "Census.Region", "ASHRAE.IECC.Climate.Zone.2004", "PUMA", "ISO.RTO.Region", "Geometry.Building.Type.ACS","Geometry.Building.Type.RECS",
                        "Vintage","Vintage.ACS","Heating.Fuel","Geometry.Floor.Area","Geometry.Foundation.Type","Geometry.Wall.Type","Geometry.Stories","Geometry.Garage",
                        "HVAC.Heating.Type.And.Fuel","HVAC.Heating.Efficiency","HVAC.Cooling.Type","HVAC.Cooling.Efficiency","Water.Heater.Fuel","Water.Heater.Efficiency",
                        "Clothes.Dryer","Infiltration", "change_cren","change_iren","change_wren","change_hren","base_weight")] # currently comes to 34 columns
# numbered columns are base weight, energy by type, change in renovated systems

rs_all_RR<-rs_all_RR[order(rs_all_RR$Building),]

load("Intermediate_results/decayFactorsProj.RData")

rs_all_RR$TC<-"MF"
rs_all_RR[rs_all_RR$Geometry.Building.Type.RECS=="Single-Family Attached" | rs_all_RR$Geometry.Building.Type.RECS=="Single-Family Detached",]$TC<-"SF"
rs_all_RR[rs_all_RR$Geometry.Building.Type.RECS=="Mobile Home",]$TC<-"MH"
rs_all_RR$TC<-paste(rs_all_RR$TC,rs_all_RR$Vintage.ACS,sep="_")
rs_all_RR$ctyTC<-paste(rs_all_RR$County,rs_all_RR$TC,sep = "")
rs_all_RR$ctyTC<-gsub("2010s","2010-19",rs_all_RR$ctyTC)
# 
# # # at this stage we are at 36 columns
# # # now add 9 columns for each stock scenario to bring us to 63
rs_all_RR<-left_join(rs_all_RR,sbm,by="ctyTC")
rs_all_RR<-left_join(rs_all_RR,shdrm,by="ctyTC")
rs_all_RR<-left_join(rs_all_RR,shmfm,by="ctyTC")
# 
rs_all_RR$sim.range<-"Undefined"
for (b in 1:180000) { # this takes a while, about 3.5 hours
  # for (b in c(1:15,9900,9934)) {
  print(b)
  w<-which(rs_all_RR$Building==b)

  for (sr in 1:(length(w)-1)) {
    rs_all_RR$sim.range[w[sr]]<-paste(rs_all_RR[w[sr],"Year"],rs_all_RR[w[sr+1],"Year"]-5,sep = ".")
  }
  for (sr in length(w)) {
    rs_all_RR$sim.range[w[sr]]<-paste(rs_all_RR[w[sr],"Year"],"2060",sep = ".")
  }
  # create concordance matrix to identify which weighting factors should be zero and non-zero
  conc<-matrix(rep(0,9*length(w)),length(w),9)
  for (c in 1:length(w)) {
    conc[c, which(names(rs_all_RR[37:45])==paste("wbase", substr(rs_all_RR$sim.range[w[c]],1,4),sep="_")):
           which(names(rs_all_RR[37:45])==paste("wbase", substr(rs_all_RR$sim.range[w[c]],6,9),sep="_"))]<-1
  }

  rs_all_RR[w,37:45]<-rs_all_RR[w,37:45]*conc
  rs_all_RR[w,46:54]<-rs_all_RR[w,46:54]*conc
  rs_all_RR[w,55:63]<-rs_all_RR[w,55:63]*conc

}
save(rs_all_RR,file="Intermediate_results/RenStandard_full.Rdata")
# Instead of producing this rs_all_RR file, it can be loaded in (if already created) from the following location
# load("Intermediate_results/RenStandard_full.Rdata") 

# merge with the energy results
rs_all_RR_res<-rbind(rs2020_sum,rs25RR_sum,rs30RR_sum,rs35RR_sum,rs40RR_sum,rs45RR_sum,rs50RR_sum,rs55RR_sum,rs60RR_sum)
rm(rs25RR,rs25RR_sum,rs30RR,rs30RR_sum,rs35RR,rs35RR_sum,rs40RR,rs40RR_sum,rs45RR,rs45RR_sum,rs50RR,rs50RR_sum,rs55RR,rs55RR_sum,rs60RR,rs60RR_sum)
# rs_all_RR_res<-rs_all_RR_res[,c(1:3,176:200)]
rs_all_RR_res<-rs_all_RR_res[,c(1:3,23,43,44,55:63,66,81,82,88,95,103,105:111,113:122,124:129,131,133,135:141,148:200)] # bigger version

rs_RR<-merge(rs_all_RR,rs_all_RR_res)
rs_RRn<-rs_RR[order(rs_RR$Building),]
rm(rs_RR)

# we have to fix the issue of zero energy use for cooling in homes that switched from HP heating to non-HP heating.
#rs_RRn0<-rs_RRn
for (k in 2:nrow(rs_RRn)) {
  j=k-1
  if (rs_RRn$change_hren[k]!=rs_RRn$change_hren[j] & 
      rs_RRn$HVAC.Heating.Type.And.Fuel[j] %in% c('Electricity ASHP','Electricity MSHP') & 
      !rs_RRn$HVAC.Heating.Type.And.Fuel[k] %in% c('Electricity ASHP','Electricity MSHP') & 
      rs_RRn$Building[k] == rs_RRn$Building[j]) {
    rs_RRn$electricity_cooling_kwh[k]<-rs_RRn$electricity_cooling_kwh[j]
    rs_RRn$electricity_fans_cooling_kwh[k]<-rs_RRn$electricity_fans_cooling_kwh[j]
    rs_RRn$electricity_pumps_cooling_kwh[k]<-rs_RRn$electricity_pumps_cooling_kwh[j]
    rs_RRn$Elec_GJ_SPC[k]<-(rs_RRn$electricity_cooling_kwh[k]+rs_RRn$electricity_pumps_cooling_kwh[k] +rs_RRn$electricity_fans_cooling_kwh[k])*0.0036
    rs_RRn$Elec_GJ[k]<-rs_RRn$Elec_GJ_SPH[k]+rs_RRn$Elec_GJ_SPC[k]+rs_RRn$Elec_GJ_DHW[k]+rs_RRn$Elec_GJ_OTH[k]
    
    rs_RRn$Tot_GJ[k]<-rs_RRn$Elec_GJ[k]+rs_RRn$Gas_GJ[k]+rs_RRn$Oil_GJ[k]+rs_RRn$Prop_GJ[k]
    rs_RRn$Tot_GJ_SPC[k]<-rs_RRn$Elec_GJ_SPC[k]
    
    rs_RRn$Tot_MJ_m2[k]<-1000*rs_RRn$Tot_GJ[k]/(rs_RRn$floor_area_lighting_ft_2[k]/10.765)
  } 
}

load("ExtData/ctycode.RData") # from the HSM repo
load("ExtData/GHGI_MidCase.RData") # Elec GHG int data in Mid-Case scenario
load("ExtData/GHGI_LowRECost.RData") # Elec GHG int data in Low RE Cost Scenario
ctycode_num<-ctycode
ctycode_num$GeoID<-as.numeric(ctycode_num$GeoID)
# use the gea intensities here, not the rto ones
gicty_gea[gicty_gea$geoid10==46113,]$geoid10<-46102 # replace Shannon County SD with Oglala Lakota Cty
gicty_gea[gicty_gea$geoid10==2270,]$geoid10<-2158 # replace Wade Hampton AK with Kusilvak AK
gicty_gea<-merge(gicty_gea,ctycode_num,by.x="geoid10",by.y="GeoID") #

gicty_gea_yr<-gicty_gea[gicty_gea$Year %in% c(2020,2025,2030,2035,2040,2045,2050,2055,2060),] # get only the RS simulation years
gic<-dcast(gicty_gea_yr[,2:4],RS_ID ~ Year,value.var = "GHG_int")
names(gic)[2:8]<-paste("GHG_int",names(gic)[2:8],sep="_")
gic$GHG_int_2055<-0.95* gic$GHG_int_2050
gic$GHG_int_2060<-0.95* gic$GHG_int_2055
gic[,2:10]<-gic[,2:10]/3600 # convert from kg/MWh to kg/MJ

# do the same process for the Low RE Cost electricity data
gicty_gea_LREC[gicty_gea_LREC$geoid10==46113,]$geoid10<-46102 # replace Shannon County SD with Oglala Lakota Cty
gicty_gea_LREC[gicty_gea_LREC$geoid10==2270,]$geoid10<-2158 # replace Wade Hampton AK with Kusilvak AK
gicty_gea_LREC<-merge(gicty_gea_LREC,ctycode_num,by.x="geoid10",by.y="GeoID") #

gicty_gea_LREC_yr<-gicty_gea_LREC[gicty_gea_LREC$Year %in% c(2020,2025,2030,2035,2040,2045,2050,2055,2060),] # get only the RS simulation years
gic_LRE<-dcast(gicty_gea_LREC_yr[,2:4],RS_ID ~ Year,value.var = "GHG_int")
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

# no need to convert to stcy(state-type-cohort-year)-balanced weighting factors, as they are for buildings built post-2020 only

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
# we exclude CFE from the renovation analysis for now
# tot CFE kgGHG per archetype group/year in kg
# rs_RRn[,c("EnGHGkg_base_2020_CFE","EnGHGkg_base_2025_CFE","EnGHGkg_base_2030_CFE","EnGHGkg_base_2035_CFE","EnGHGkg_base_2040_CFE","EnGHGkg_base_2045_CFE","EnGHGkg_base_2050_CFE","EnGHGkg_base_2055_CFE","EnGHGkg_base_2060_CFE")]<-1000* 
#   (rs_RRn$base_weight*rs_RRn[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*
#   (rs_RRn$Elec_GJ*rs_RRn[,c("GHG_int_2020_CFE", "GHG_int_2025_CFE","GHG_int_2030_CFE","GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")]+
#      matrix(rep(rs_RRn$Gas_GJ*GHGI_NG,9),nrow(rs_RRn),9)+ matrix(rep(rs_RRn$Oil_GJ*GHGI_FO,9),nrow(rs_RRn),9)+ matrix(rep(rs_RRn$Prop_GJ*GHGI_LP,9),nrow(rs_RRn),9))
# 
# # tot CFE kgGHG per archetype group/year in kg
# rs_RRn[,c("EnGHGkg_hiDR_2020_CFE","EnGHGkg_hiDR_2025_CFE","EnGHGkg_hiDR_2030_CFE","EnGHGkg_hiDR_2035_CFE","EnGHGkg_hiDR_2040_CFE","EnGHGkg_hiDR_2045_CFE","EnGHGkg_hiDR_2050_CFE","EnGHGkg_hiDR_2055_CFE","EnGHGkg_hiDR_2060_CFE")]<-1000* 
#   (rs_RRn$base_weight*rs_RRn[,c("whiDR_2020",  "whiDR_2025", "whiDR_2030", "whiDR_2035", "whiDR_2040", "whiDR_2045", "whiDR_2050", "whiDR_2055", "whiDR_2060")])*
#   (rs_RRn$Elec_GJ*rs_RRn[,c("GHG_int_2020_CFE", "GHG_int_2025_CFE","GHG_int_2030_CFE","GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")]+
#      matrix(rep(rs_RRn$Gas_GJ*GHGI_NG,9),nrow(rs_RRn),9)+ matrix(rep(rs_RRn$Oil_GJ*GHGI_FO,9),nrow(rs_RRn),9)+ matrix(rep(rs_RRn$Prop_GJ*GHGI_LP,9),nrow(rs_RRn),9))
# 
# # tot CFE kgGHG per archetype group/year in kg
# rs_RRn[,c("EnGHGkg_hiMF_2020_CFE","EnGHGkg_hiMF_2025_CFE","EnGHGkg_hiMF_2030_CFE","EnGHGkg_hiMF_2035_CFE","EnGHGkg_hiMF_2040_CFE","EnGHGkg_hiMF_2045_CFE","EnGHGkg_hiMF_2050_CFE","EnGHGkg_hiMF_2055_CFE","EnGHGkg_hiMF_2060_CFE")]<-1000* 
#   (rs_RRn$base_weight*rs_RRn[,c("whiMF_2020",  "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")])*
#   (rs_RRn$Elec_GJ*rs_RRn[,c("GHG_int_2020_CFE", "GHG_int_2025_CFE","GHG_int_2030_CFE","GHG_int_2035_CFE","GHG_int_2040_CFE","GHG_int_2045_CFE","GHG_int_2050_CFE","GHG_int_2055_CFE","GHG_int_2060_CFE")]+
#      matrix(rep(rs_RRn$Gas_GJ*GHGI_NG,9),nrow(rs_RRn),9)+ matrix(rep(rs_RRn$Oil_GJ*GHGI_FO,9),nrow(rs_RRn),9)+ matrix(rep(rs_RRn$Prop_GJ*GHGI_LP,9),nrow(rs_RRn),9))

# calculate avg reductions in total household final energy per renovation type
rs_RRn$redn_hren<-rs_RRn$redn_wren<-rs_RRn$redn_iren<-rs_RRn$redn_cren<-rs_RRn$redn_hren_iren<-0
rs_RRn$GHG_pre<-rs_RRn$GHG_post<-0
rs_RRn$redn_GHG_pc<-rs_RRn$redn_GHG_abs<-0
rs_RRn$GHG_pre_LRE<-rs_RRn$GHG_post_LRE<-0
rs_RRn$redn_GHG_LRE_pc<-rs_RRn$redn_GHG_LRE_abs<-0
rs_RRn$change_hren_only<-rs_RRn$change_wren_only<-rs_RRn$change_iren_only<-rs_RRn$change_cren_only<-rs_RRn$change_hren_iren<-FALSE
rs_RRn$change_hren_only_prev<-rs_RRn$change_wren_only_prev<-rs_RRn$change_iren_only_prev<-rs_RRn$change_cren_only_prev<-rs_RRn$change_hren_iren_prev<-FALSE
years<-seq(2020,2060,5)
# for loop to calculate energy and GHG reductions from renovations
for (k in 1:180000) { print(k) # this will probably take a while, about 7hr 
  w<-which(rs_RRn$Building==k) 
  if (length(w) > 1) { # if there are any renovations
  for (j in 1:(length(w)-1)) {
   if (rs_RRn[w[j+1],]$change_cren!=rs_RRn[w[j],]$change_cren & identical(as.numeric(rs_RRn[w[j+1],31:33]),as.numeric(rs_RRn[w[j],31:33])) ) { # if only change_cren changes
     rs_RRn$redn_cren[w[j+1]]<-1-(rs_RRn$Tot_GJ[w[j+1]]/rs_RRn$Tot_GJ[w[j]])
     rs_RRn$change_cren_only[w[j+1]]<-TRUE
     rs_RRn$change_cren_only_prev[w[j]]<-TRUE
     }
    if (rs_RRn[w[j+1],]$change_iren!=rs_RRn[w[j],]$change_iren & identical(as.numeric(rs_RRn[w[j+1],c(30,32,33)]),as.numeric(rs_RRn[w[j],c(30,32,33)])) ) { # if only change_iren changes
      rs_RRn$redn_iren[w[j+1]]<-1-(rs_RRn$Tot_GJ[w[j+1]]/rs_RRn$Tot_GJ[w[j]])
      rs_RRn$change_iren_only[w[j+1]]<-TRUE
      rs_RRn$change_iren_only_prev[w[j]]<-TRUE
    } 
    if (rs_RRn[w[j+1],]$change_wren!=rs_RRn[w[j],]$change_wren & identical(as.numeric(rs_RRn[w[j+1],c(30,31,33)]),as.numeric(rs_RRn[w[j],c(30,31,33)])) ) { # if only change_wren changes
      rs_RRn$redn_wren[w[j+1]]<-1-(rs_RRn$Tot_GJ[w[j+1]]/rs_RRn$Tot_GJ[w[j]])
      rs_RRn$change_wren_only[w[j+1]]<-TRUE
      rs_RRn$change_wren_only_prev[w[j]]<-TRUE
    }
    if (rs_RRn[w[j+1],]$change_hren!=rs_RRn[w[j],]$change_hren & identical(as.numeric(rs_RRn[w[j+1],30:32]),as.numeric(rs_RRn[w[j],30:32])) ) { # if only change_hren changes
      rs_RRn$redn_hren[w[j+1]]<-1-(rs_RRn$Tot_GJ[w[j+1]]/rs_RRn$Tot_GJ[w[j]])
      rs_RRn$change_hren_only[w[j+1]]<-TRUE
      rs_RRn$change_hren_only_prev[w[j]]<-TRUE
    }
    if (rs_RRn[w[j+1],]$change_hren!=rs_RRn[w[j],]$change_hren & rs_RRn[w[j+1],]$change_iren!=rs_RRn[w[j],]$change_iren & identical(as.numeric(rs_RRn[w[j+1],c(30,32)]),as.numeric(rs_RRn[w[j],c(30,32)])) ) {  # if (only) change_hren and change_iren change together 
      rs_RRn$redn_hren_iren[w[j+1]]<-1-(rs_RRn$Tot_GJ[w[j+1]]/rs_RRn$Tot_GJ[w[j]])
      rs_RRn$change_hren_iren[w[j+1]]<-TRUE
      rs_RRn$change_hren_iren_prev[w[j]]<-TRUE
    }
    
    y<-which(years==rs_RRn$Year[w[j+1]])
    rs_RRn$GHG_pre[w[j]]<-rs_RRn$Elec_GJ[w[j]]*rs_RRn[w[j+1],names(rs_RRn)[169:177][y]] + rs_RRn$Gas_GJ[w[j]]*GHGI_NG +  rs_RRn$Oil_GJ[w[j]]*GHGI_FO +  rs_RRn$Prop_GJ[w[j]]*GHGI_LP  
    rs_RRn$GHG_post[w[j+1]]<-rs_RRn$Elec_GJ[w[j+1]]*rs_RRn[w[j+1],names(rs_RRn)[169:177][y]] + rs_RRn$Gas_GJ[w[j+1]]*GHGI_NG +  rs_RRn$Oil_GJ[w[j+1]]*GHGI_FO +  rs_RRn$Prop_GJ[w[j+1]]*GHGI_LP 
    rs_RRn$redn_GHG_pc[w[j+1]]<-(rs_RRn$GHG_pre[w[j]]-rs_RRn$GHG_post[w[j+1]])/rs_RRn$GHG_pre[w[j]]
    rs_RRn$redn_GHG_abs[w[j+1]]<-(rs_RRn$GHG_pre[w[j]]-rs_RRn$GHG_post[w[j+1]])
    
    rs_RRn$GHG_pre_LRE[w[j]]<-rs_RRn$Elec_GJ[w[j]]*rs_RRn[w[j+1],names(rs_RRn)[178:186][y]] + rs_RRn$Gas_GJ[w[j]]*GHGI_NG +  rs_RRn$Oil_GJ[w[j]]*GHGI_FO +  rs_RRn$Prop_GJ[w[j]]*GHGI_LP  
    rs_RRn$GHG_post_LRE[w[j+1]]<-rs_RRn$Elec_GJ[w[j+1]]*rs_RRn[w[j+1],names(rs_RRn)[178:186][y]] + rs_RRn$Gas_GJ[w[j+1]]*GHGI_NG +  rs_RRn$Oil_GJ[w[j+1]]*GHGI_FO +  rs_RRn$Prop_GJ[w[j+1]]*GHGI_LP 
    rs_RRn$redn_GHG_LRE_pc[w[j+1]]<-(rs_RRn$GHG_pre_LRE[w[j]]-rs_RRn$GHG_post_LRE[w[j+1]])/rs_RRn$GHG_pre_LRE[w[j]]
    rs_RRn$redn_GHG_LRE_abs[w[j+1]]<-(rs_RRn$GHG_pre_LRE[w[j]]-rs_RRn$GHG_post_LRE[w[j+1]])
  }
  }
}


# # tot GHG reductions per renovation, base, in kg
# rs_RRn[,c("redGHGren_base_2025","redGHGren_base_2030","redGHGren_base_2035","redGHGren_base_2040","redGHGren_base_2045","redGHGren_base_2050","redGHGren_base_2055","redGHGren_base_2060")]<-1000* 
#   (rs_RRn$base_weight*rs_RRn[,c("wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*rs_RRn$redn_GHG_abs
# 
# redn<-c(0,rs_RRn$GHG_post[2:nrow(rs_RRn)]-rs_RRn$GHG_pre[1:(nrow(rs_RRn)-1)])

# df<-rs_RRn[,1:296]
# rentype<-'hren'
# rentype='hren_iren'
# 
# df <- rs_RRn
calc_cum_red<-function(df,rentype) { # currently cumulating reductions over 25 years for those renovations finished by 2025, 2030, and 2035 respectively
  
  # extract ren1 (After) and ren2 (Before), dataframes shwoing house details and energy consumption after and before renovations
  if (rentype != 'hren_iren') {
  ren1<-df[df[,paste('change_',rentype,'_only',sep='')]==TRUE, c('Year','Building','Year_Building','base_weight', 'ctyTC', 'Elec_GJ','Gas_GJ','Oil_GJ','Prop_GJ',names(df)[which(startsWith(names(df),'GHG_int'))])]
  ren2<-df[df[,paste('change_',rentype,'_only_prev',sep='')]==TRUE, c('Year','Building','Year_Building','Elec_GJ','Gas_GJ','Oil_GJ','Prop_GJ',names(df)[which(startsWith(names(df),'GHG_int'))])]
  }
  if(rentype == 'hren_iren') {
    ren1<-df[df$change_hren_iren==TRUE, c('Year','Building','Year_Building','base_weight', 'ctyTC', 'Elec_GJ','Gas_GJ','Oil_GJ','Prop_GJ',names(df)[which(startsWith(names(df),'GHG_int'))])]
    ren2<-df[df$change_hren_iren_prev==TRUE, c('Year','Building','Year_Building','Elec_GJ','Gas_GJ','Oil_GJ','Prop_GJ',names(df)[which(startsWith(names(df),'GHG_int'))])]
  }
  
  ren3<-ren1[,1:5] # maybe change the selected columns if nec
  # add stock decay factors for base and NOT hiDR stock scenarios
  ren3<-merge(ren3,sbm)
  #ren3<-merge(ren3,shdrm)
  ren3<-ren3[with(ren3, order(Building,Year)),]
  rownames(ren3)<-1:nrow(ren3)
  
  
  ren3[,c('redn2025','redn2030','redn2035','redn2040','redn2045','redn2050','redn2055','redn2060','redn2025_2050','redn2030_2055','redn2035_2060',
          'redn2025_LRE','redn2030_LRE','redn2035_LRE','redn2040_LRE','redn2045_LRE','redn2050_LRE','redn2055_LRE','redn2060_LRE','redn2025_2050_LRE','redn2030_2055_LRE','redn2035_2060_LRE',
          'sredn2025','sredn2030','sredn2035','sredn2040','sredn2045','sredn2050','sredn2055','sredn2060','sredn2025_2050','sredn2030_2055','sredn2035_2060',
          'sredn2025_LRE','sredn2030_LRE','sredn2035_LRE','sredn2040_LRE','sredn2045_LRE','sredn2050_LRE','sredn2055_LRE','sredn2060_LRE','sredn2025_2050_LRE','sredn2030_2055_LRE','sredn2035_2060_LRE')]<-0
  
  for (y in seq(2025,2035,5)) {
    ren3[ren3$Year==y,paste('redn',y,sep="")]<-(ren2[ren1$Year==y,]$Elec_GJ*ren2[ren1$Year==y,paste('GHG_int_',y,sep="")]  + ren2[ren1$Year==y,]$Gas_GJ*GHGI_NG + ren2[ren1$Year==y,]$Oil_GJ*GHGI_FO + ren2[ren1$Year==y,]$Prop_GJ*GHGI_LP) - 
      (ren1[ren1$Year==y,]$Elec_GJ*ren1[ren1$Year==y,paste('GHG_int_',y,sep="")] + ren1[ren1$Year==y,]$Gas_GJ*GHGI_NG + ren1[ren1$Year==y,]$Oil_GJ*GHGI_FO + ren1[ren1$Year==y,]$Prop_GJ*GHGI_LP)
    
    ren3[ren3$Year==y,paste('redn',y+5,sep="")]<-(ren2[ren1$Year==y,]$Elec_GJ*ren2[ren1$Year==y,paste('GHG_int_',y+5,sep="")]  + ren2[ren1$Year==y,]$Gas_GJ*GHGI_NG + ren2[ren1$Year==y,]$Oil_GJ*GHGI_FO + ren2[ren1$Year==y,]$Prop_GJ*GHGI_LP) - 
      (ren1[ren1$Year==y,]$Elec_GJ*ren1[ren1$Year==y,paste('GHG_int_',y+5,sep="")] + ren1[ren1$Year==y,]$Gas_GJ*GHGI_NG + ren1[ren1$Year==y,]$Oil_GJ*GHGI_FO + ren1[ren1$Year==y,]$Prop_GJ*GHGI_LP)
    
    ren3[ren3$Year==y,paste('redn',y+10,sep="")]<-(ren2[ren1$Year==y,]$Elec_GJ*ren2[ren1$Year==y,paste('GHG_int_',y+10,sep="")]  + ren2[ren1$Year==y,]$Gas_GJ*GHGI_NG + ren2[ren1$Year==y,]$Oil_GJ*GHGI_FO + ren2[ren1$Year==y,]$Prop_GJ*GHGI_LP) - 
      (ren1[ren1$Year==y,]$Elec_GJ*ren1[ren1$Year==y,paste('GHG_int_',y+10,sep="")] + ren1[ren1$Year==y,]$Gas_GJ*GHGI_NG + ren1[ren1$Year==y,]$Oil_GJ*GHGI_FO + ren1[ren1$Year==y,]$Prop_GJ*GHGI_LP)
    
    ren3[ren3$Year==y,paste('redn',y+15,sep="")]<-(ren2[ren1$Year==y,]$Elec_GJ*ren2[ren1$Year==y,paste('GHG_int_',y+15,sep="")]  + ren2[ren1$Year==y,]$Gas_GJ*GHGI_NG + ren2[ren1$Year==y,]$Oil_GJ*GHGI_FO + ren2[ren1$Year==y,]$Prop_GJ*GHGI_LP) - 
      (ren1[ren1$Year==y,]$Elec_GJ*ren1[ren1$Year==y,paste('GHG_int_',y+15,sep="")] + ren1[ren1$Year==y,]$Gas_GJ*GHGI_NG + ren1[ren1$Year==y,]$Oil_GJ*GHGI_FO + ren1[ren1$Year==y,]$Prop_GJ*GHGI_LP)
    
    ren3[ren3$Year==y,paste('redn',y+20,sep="")]<-(ren2[ren1$Year==y,]$Elec_GJ*ren2[ren1$Year==y,paste('GHG_int_',y+20,sep="")]  + ren2[ren1$Year==y,]$Gas_GJ*GHGI_NG + ren2[ren1$Year==y,]$Oil_GJ*GHGI_FO + ren2[ren1$Year==y,]$Prop_GJ*GHGI_LP) - 
      (ren1[ren1$Year==y,]$Elec_GJ*ren1[ren1$Year==y,paste('GHG_int_',y+20,sep="")] + ren1[ren1$Year==y,]$Gas_GJ*GHGI_NG + ren1[ren1$Year==y,]$Oil_GJ*GHGI_FO + ren1[ren1$Year==y,]$Prop_GJ*GHGI_LP)
    
    ren3[ren3$Year==y,paste('redn',y+25,sep="")]<-(ren2[ren1$Year==y,]$Elec_GJ*ren2[ren1$Year==y,paste('GHG_int_',y+25,sep="")]  + ren2[ren1$Year==y,]$Gas_GJ*GHGI_NG + ren2[ren1$Year==y,]$Oil_GJ*GHGI_FO + ren2[ren1$Year==y,]$Prop_GJ*GHGI_LP) - 
      (ren1[ren1$Year==y,]$Elec_GJ*ren1[ren1$Year==y,paste('GHG_int_',y+25,sep="")] + ren1[ren1$Year==y,]$Gas_GJ*GHGI_NG + ren1[ren1$Year==y,]$Oil_GJ*GHGI_FO + ren1[ren1$Year==y,]$Prop_GJ*GHGI_LP)
    
    # stock-wide reductions
    
    ren3[ren3$Year==y,paste('sredn',y,sep="")]<-ren3[ren3$Year==y,'base_weight']*ren3[ren3$Year==y,paste('wbase_',y,sep="")]*ren3[ren3$Year==y,paste('redn',y,sep="")]
    ren3[ren3$Year==y,paste('sredn',y+5,sep="")]<-ren3[ren3$Year==y,'base_weight']*ren3[ren3$Year==y,paste('wbase_',y+5,sep="")]*ren3[ren3$Year==y,paste('redn',y+5,sep="")]
    ren3[ren3$Year==y,paste('sredn',y+10,sep="")]<-ren3[ren3$Year==y,'base_weight']*ren3[ren3$Year==y,paste('wbase_',y+10,sep="")]*ren3[ren3$Year==y,paste('redn',y+10,sep="")]
    ren3[ren3$Year==y,paste('sredn',y+15,sep="")]<-ren3[ren3$Year==y,'base_weight']*ren3[ren3$Year==y,paste('wbase_',y+15,sep="")]*ren3[ren3$Year==y,paste('redn',y+15,sep="")]
    ren3[ren3$Year==y,paste('sredn',y+20,sep="")]<-ren3[ren3$Year==y,'base_weight']*ren3[ren3$Year==y,paste('wbase_',y+20,sep="")]*ren3[ren3$Year==y,paste('redn',y+20,sep="")]
    ren3[ren3$Year==y,paste('sredn',y+25,sep="")]<-ren3[ren3$Year==y,'base_weight']*ren3[ren3$Year==y,paste('wbase_',y+25,sep="")]*ren3[ren3$Year==y,paste('redn',y+25,sep="")]
    
    # Repeat for LRE grid scenarios
    
    ren3[ren3$Year==y,paste('redn',y,'_LRE',sep="")]<-(ren2[ren1$Year==y,]$Elec_GJ*ren2[ren1$Year==y,paste('GHG_int_',y,'_LRE',sep="")]  + ren2[ren1$Year==y,]$Gas_GJ*GHGI_NG + ren2[ren1$Year==y,]$Oil_GJ*GHGI_FO + ren2[ren1$Year==y,]$Prop_GJ*GHGI_LP) - 
      (ren1[ren1$Year==y,]$Elec_GJ*ren1[ren1$Year==y,paste('GHG_int_',y,'_LRE',sep="")] + ren1[ren1$Year==y,]$Gas_GJ*GHGI_NG + ren1[ren1$Year==y,]$Oil_GJ*GHGI_FO + ren1[ren1$Year==y,]$Prop_GJ*GHGI_LP)
    
    ren3[ren3$Year==y,paste('redn',y+5,'_LRE',sep="")]<-(ren2[ren1$Year==y,]$Elec_GJ*ren2[ren1$Year==y,paste('GHG_int_',y+5,'_LRE',sep="")]  + ren2[ren1$Year==y,]$Gas_GJ*GHGI_NG + ren2[ren1$Year==y,]$Oil_GJ*GHGI_FO + ren2[ren1$Year==y,]$Prop_GJ*GHGI_LP) - 
      (ren1[ren1$Year==y,]$Elec_GJ*ren1[ren1$Year==y,paste('GHG_int_',y+5,'_LRE',sep="")] + ren1[ren1$Year==y,]$Gas_GJ*GHGI_NG + ren1[ren1$Year==y,]$Oil_GJ*GHGI_FO + ren1[ren1$Year==y,]$Prop_GJ*GHGI_LP)
    
    ren3[ren3$Year==y,paste('redn',y+10,'_LRE',sep="")]<-(ren2[ren1$Year==y,]$Elec_GJ*ren2[ren1$Year==y,paste('GHG_int_',y+10,'_LRE',sep="")]  + ren2[ren1$Year==y,]$Gas_GJ*GHGI_NG + ren2[ren1$Year==y,]$Oil_GJ*GHGI_FO + ren2[ren1$Year==y,]$Prop_GJ*GHGI_LP) - 
      (ren1[ren1$Year==y,]$Elec_GJ*ren1[ren1$Year==y,paste('GHG_int_',y+10,'_LRE',sep="")] + ren1[ren1$Year==y,]$Gas_GJ*GHGI_NG + ren1[ren1$Year==y,]$Oil_GJ*GHGI_FO + ren1[ren1$Year==y,]$Prop_GJ*GHGI_LP)
    
    ren3[ren3$Year==y,paste('redn',y+15,'_LRE',sep="")]<-(ren2[ren1$Year==y,]$Elec_GJ*ren2[ren1$Year==y,paste('GHG_int_',y+15,'_LRE',sep="")]  + ren2[ren1$Year==y,]$Gas_GJ*GHGI_NG + ren2[ren1$Year==y,]$Oil_GJ*GHGI_FO + ren2[ren1$Year==y,]$Prop_GJ*GHGI_LP) - 
      (ren1[ren1$Year==y,]$Elec_GJ*ren1[ren1$Year==y,paste('GHG_int_',y+15,'_LRE',sep="")] + ren1[ren1$Year==y,]$Gas_GJ*GHGI_NG + ren1[ren1$Year==y,]$Oil_GJ*GHGI_FO + ren1[ren1$Year==y,]$Prop_GJ*GHGI_LP)
    
    ren3[ren3$Year==y,paste('redn',y+20,'_LRE',sep="")]<-(ren2[ren1$Year==y,]$Elec_GJ*ren2[ren1$Year==y,paste('GHG_int_',y+20,'_LRE',sep="")]  + ren2[ren1$Year==y,]$Gas_GJ*GHGI_NG + ren2[ren1$Year==y,]$Oil_GJ*GHGI_FO + ren2[ren1$Year==y,]$Prop_GJ*GHGI_LP) - 
      (ren1[ren1$Year==y,]$Elec_GJ*ren1[ren1$Year==y,paste('GHG_int_',y+20,'_LRE',sep="")] + ren1[ren1$Year==y,]$Gas_GJ*GHGI_NG + ren1[ren1$Year==y,]$Oil_GJ*GHGI_FO + ren1[ren1$Year==y,]$Prop_GJ*GHGI_LP)
    
    ren3[ren3$Year==y,paste('redn',y+25,'_LRE',sep="")]<-(ren2[ren1$Year==y,]$Elec_GJ*ren2[ren1$Year==y,paste('GHG_int_',y+25,'_LRE',sep="")]  + ren2[ren1$Year==y,]$Gas_GJ*GHGI_NG + ren2[ren1$Year==y,]$Oil_GJ*GHGI_FO + ren2[ren1$Year==y,]$Prop_GJ*GHGI_LP) - 
      (ren1[ren1$Year==y,]$Elec_GJ*ren1[ren1$Year==y,paste('GHG_int_',y+25,'_LRE',sep="")] + ren1[ren1$Year==y,]$Gas_GJ*GHGI_NG + ren1[ren1$Year==y,]$Oil_GJ*GHGI_FO + ren1[ren1$Year==y,]$Prop_GJ*GHGI_LP)
    
    # stock-wide reductions
    
    ren3[ren3$Year==y,paste('sredn',y,'_LRE',sep="")]<-ren3[ren3$Year==y,'base_weight']*ren3[ren3$Year==y,paste('wbase_',y,sep="")]*ren3[ren3$Year==y,paste('redn',y,'_LRE',sep="")]
    ren3[ren3$Year==y,paste('sredn',y+5,'_LRE',sep="")]<-ren3[ren3$Year==y,'base_weight']*ren3[ren3$Year==y,paste('wbase_',y+5,sep="")]*ren3[ren3$Year==y,paste('redn',y+5,'_LRE',sep="")]
    ren3[ren3$Year==y,paste('sredn',y+10,'_LRE',sep="")]<-ren3[ren3$Year==y,'base_weight']*ren3[ren3$Year==y,paste('wbase_',y+10,sep="")]*ren3[ren3$Year==y,paste('redn',y+10,'_LRE',sep="")]
    ren3[ren3$Year==y,paste('sredn',y+15,'_LRE',sep="")]<-ren3[ren3$Year==y,'base_weight']*ren3[ren3$Year==y,paste('wbase_',y+15,sep="")]*ren3[ren3$Year==y,paste('redn',y+15,'_LRE',sep="")]
    ren3[ren3$Year==y,paste('sredn',y+20,'_LRE',sep="")]<-ren3[ren3$Year==y,'base_weight']*ren3[ren3$Year==y,paste('wbase_',y+20,sep="")]*ren3[ren3$Year==y,paste('redn',y+20,'_LRE',sep="")]
    ren3[ren3$Year==y,paste('sredn',y+25,'_LRE',sep="")]<-ren3[ren3$Year==y,'base_weight']*ren3[ren3$Year==y,paste('wbase_',y+25,sep="")]*ren3[ren3$Year==y,paste('redn',y+25,'_LRE',sep="")]
    
     
    for (k in which(ren3$Year==y)) {
      ren3[k,paste('redn',paste(y,y+25,sep="_"),sep="")]<-sum(spline(seq(y,y+25,5),ren3[k,paste('redn',seq(y,y+25,5),sep="")],xout = y:(y+25))$y[1:25])
      ren3[k,paste('redn',paste(y,y+25,sep="_"),'_LRE',sep="")]<-sum(spline(seq(y,y+25,5),ren3[k,paste('redn',seq(y,y+25,5),'_LRE',sep="")],xout = y:(y+25))$y[1:25])
      # sum stockwide reductions
      ren3[k,paste('sredn',paste(y,y+25,sep="_"),sep="")]<-sum(spline(seq(y,y+25,5),ren3[k,paste('sredn',seq(y,y+25,5),sep="")],xout = y:(y+25))$y[1:25])
      ren3[k,paste('sredn',paste(y,y+25,sep="_"),'_LRE',sep="")]<-sum(spline(seq(y,y+25,5),ren3[k,paste('sredn',seq(y,y+25,5),'_LRE',sep="")],xout = y:(y+25))$y[1:25])
      
    }
  }
  ren3$redn_cum<-rowSums(ren3[,c('redn2025_2050','redn2030_2055','redn2035_2060')])
  ren3$redn_cum_LRE<-rowSums(ren3[,c('redn2025_2050_LRE','redn2030_2055_LRE','redn2035_2060_LRE')])
  
  ren3$sredn_cum<-rowSums(ren3[,c('sredn2025_2050','sredn2030_2055','sredn2035_2060')])
  ren3$sredn_cum_LRE<-rowSums(ren3[,c('sredn2025_2050_LRE','sredn2030_2055_LRE','sredn2035_2060_LRE')])
  
  
  ren4<-ren3[,c('Year','Year_Building','redn_cum','redn_cum_LRE','sredn_cum','sredn_cum_LRE')]
  ren4<-ren4[ren4$Year<2040,] # only include those which have renovations until 235, which can be included in the 25yr time horizon 
  names(ren4)[3:6]<-paste(rentype,names(ren4)[3:6],'tCO2',sep='_')
  df<-merge(df,ren4,all.x = TRUE)
  df<-df[with(df, order(Building,Year)),]
  rownames(df)<-1:nrow(df)
  df
}

# Calculate cumulative reductions
rs_RRn<-calc_cum_red(rs_RRn,'cren')
rs_RRn<-calc_cum_red(rs_RRn,'iren')
rs_RRn<-calc_cum_red(rs_RRn,'wren')
rs_RRn<-calc_cum_red(rs_RRn,'hren')
rs_RRn<-calc_cum_red(rs_RRn,'hren_iren')

# see how the renovation families compare to each other
# avg by year
tapply(rs_RRn$hren_redn_cum_tCO2 ,list(rs_RRn$Year,rs_RRn$change_hren_only),mean,na.rm=TRUE) # 13-14 tCO2 on average
tapply(rs_RRn$wren_redn_cum_tCO2 ,list(rs_RRn$Year,rs_RRn$change_wren_only),mean,na.rm=TRUE) # 5t CO2 on average
tapply(rs_RRn$iren_redn_cum_tCO2 ,list(rs_RRn$Year,rs_RRn$change_iren_only),mean,na.rm=TRUE) # 25-31 tCO2 on average  
tapply(rs_RRn$cren_redn_cum_tCO2 ,list(rs_RRn$Year,rs_RRn$change_cren_only),mean,na.rm=TRUE) # 0.9 tCO2
tapply(rs_RRn$hren_iren_redn_cum_tCO2 ,list(rs_RRn$Year,rs_RRn$change_hren_iren),mean,na.rm=TRUE) # 43-45 tCO2 on average

# avg by Division
tapply(rs_RRn$hren_redn_cum_tCO2 ,list(rs_RRn$Census.Division,rs_RRn$change_hren_only),mean,na.rm=TRUE) # New England is so far ahead here. Especially in Maine and Vermont
tapply(rs_RRn$wren_redn_cum_tCO2 ,list(rs_RRn$Census.Division,rs_RRn$change_wren_only),mean,na.rm=TRUE) 
tapply(rs_RRn$iren_redn_cum_tCO2 ,list(rs_RRn$Census.Division,rs_RRn$change_iren_only),mean,na.rm=TRUE) # NE and ENC have biggest impact
tapply(rs_RRn$cren_redn_cum_tCO2 ,list(rs_RRn$Census.Division,rs_RRn$change_cren_only),mean,na.rm=TRUE) # only real savings in ESC and WSC 
tapply(rs_RRn$hren_iren_redn_cum_tCO2 ,list(rs_RRn$Census.Division,rs_RRn$change_hren_iren),mean,na.rm=TRUE) # from 25 tCO2 in WSC to 68 tCO2 in NE, next highest is MitAtl

# avg by House Type
tapply(rs_RRn$hren_redn_cum_tCO2 ,list(rs_RRn$Geometry.Building.Type.RECS,rs_RRn$change_hren_only),mean,na.rm=TRUE) 
tapply(rs_RRn$hren_redn_cum_tCO2 ,list(rs_RRn$Geometry.Building.Type.ACS,rs_RRn$change_hren_only),mean,na.rm=TRUE) 
tapply(rs_RRn$wren_redn_cum_tCO2 ,list(rs_RRn$Geometry.Building.Type.RECS,rs_RRn$change_wren_only),mean,na.rm=TRUE) 
tapply(rs_RRn$iren_redn_cum_tCO2 ,list(rs_RRn$Geometry.Building.Type.RECS,rs_RRn$change_iren_only),mean,na.rm=TRUE) 
tapply(rs_RRn$cren_redn_cum_tCO2 ,list(rs_RRn$Geometry.Building.Type.RECS,rs_RRn$change_cren_only),mean,na.rm=TRUE) 
tapply(rs_RRn$hren_iren_redn_cum_tCO2 ,list(rs_RRn$Geometry.Building.Type.RECS,rs_RRn$change_hren_iren),mean,na.rm=TRUE)

# avg by Vintage
tapply(rs_RRn$hren_redn_cum_tCO2 ,list(rs_RRn$Vintage.ACS,rs_RRn$change_hren_only),mean,na.rm=TRUE) 
tapply(rs_RRn$wren_redn_cum_tCO2 ,list(rs_RRn$Vintage.ACS,rs_RRn$change_wren_only),mean,na.rm=TRUE) 
tapply(rs_RRn$iren_redn_cum_tCO2 ,list(rs_RRn$Vintage.ACS,rs_RRn$change_iren_only),mean,na.rm=TRUE) # unusual that 2010s houses have a large avg, but N is small, 1072 in this case
tapply(rs_RRn$cren_redn_cum_tCO2 ,list(rs_RRn$Vintage.ACS,rs_RRn$change_cren_only),mean,na.rm=TRUE) 
tapply(rs_RRn$hren_iren_redn_cum_tCO2 ,list(rs_RRn$Vintage.ACS,rs_RRn$change_hren_iren),mean,na.rm=TRUE) # 68t on average in <1940

# avg by House Size. 
tapply(rs_RRn$hren_redn_cum_tCO2 ,list(rs_RRn$Geometry.Floor.Area,rs_RRn$change_hren_only),mean,na.rm=TRUE) 
tapply(rs_RRn$wren_redn_cum_tCO2 ,list(rs_RRn$Geometry.Floor.Area,rs_RRn$change_wren_only),mean,na.rm=TRUE) 
tapply(rs_RRn$iren_redn_cum_tCO2 ,list(rs_RRn$Geometry.Floor.Area,rs_RRn$change_iren_only),mean,na.rm=TRUE) 
tapply(rs_RRn$cren_redn_cum_tCO2 ,list(rs_RRn$Geometry.Floor.Area,rs_RRn$change_cren_only),mean,na.rm=TRUE) 
tapply(rs_RRn$hren_iren_redn_cum_tCO2 ,list(rs_RRn$Geometry.Floor.Area,rs_RRn$change_hren_iren),mean,na.rm=TRUE) # 117 tCO2 on average in homes over 4000 ft2


# include climate zone in rs_RRn
cz<-rs_2020_60_RR[,c('County','Building.America.Climate.Zone')]
cz<-unique(cz)
rs_RRn<-merge(rs_RRn,cz)
rs_RRn<-rs_RRn[with(rs_RRn, order(Building,Year)),]

# save this modified dataframe
save(rs_RRn,file = "Intermediate_results/RenStandard_EG.RData")

# compare the renovations by 4 major ren. groups, in each sim year

# cooling
tapply(rs_RRn$redn_GHG_pc,list(rs_RRn$Year,rs_RRn$change_cren_only),mean) # 0.2% in 2025 to 0% in 2060, negative between 2045-2055

# insulation/envelope
tapply(rs_RRn$redn_GHG_pc,list(rs_RRn$Year,rs_RRn$change_iren_only),mean) # 16% in 2025 to 12% in 2060
tapply(rs_RRn$redn_GHG_abs,list(rs_RRn$Year,rs_RRn$change_iren_only),mean) # 1.33t in 2025 to 0.63t in 2060
# total annual insulation renovation reductions scaled across the housing stock, in Mt/yr, for each sim year ## NOT SURE WHICH COLUMNS THIS USED TO REFER TO
colSums(rs_RRn[rs_RRn$change_iren_only==TRUE,288:295])*1e-9 # 9Mt in 2025 to 14.5Mt in 2060

# heating
tapply(rs_RRn$redn_GHG_pc,list(rs_RRn$Year,rs_RRn$change_hren_only),mean) # 6% in 2025 to 0.2% in 2060
tapply(rs_RRn$redn_GHG_abs,list(rs_RRn$Year,rs_RRn$change_hren_only),mean) # 0.6t in 2025 to 0.2t in 2060
# total annual heating only renovation reductions scaled across the housing stock, in Mt/yr, for each sim year
colSums(rs_RRn[rs_RRn$change_hren_only==TRUE,288:295])*1e-9 # 3.5Mt in 2025 to 7Mt in 2040 to 3.7Mt in 2060

# cooling
tapply(rs_RRn$redn_GHG_pc,list(rs_RRn$Year,rs_RRn$change_cren_only),mean) # 0.2% in 2025 to 0% in 2060
tapply(rs_RRn$redn_GHG_abs,list(rs_RRn$Year,rs_RRn$change_cren_only),mean) # 0.05t in 2025 to 0.01t in 2060
# total annual cooling only renovation reductions scaled across the housing stock, in Mt/yr, for each sim year
colSums(rs_RRn[rs_RRn$change_cren_only==TRUE,288:295])*1e-9 # 0.7Mt in 2025 to 1.5Mt in 2040 to 0.15Mt in 2060. always positive

# water heating
tapply(rs_RRn$redn_GHG_pc,list(rs_RRn$Year,rs_RRn$change_wren_only),mean) # 3% in 2025 to 1.5% in 2060
tapply(rs_RRn$redn_GHG_abs,list(rs_RRn$Year,rs_RRn$change_wren_only),mean) # 0.2t in 2025 to 0.1t in 2060
# total annual dhw only renovation reductions scaled across the housing stock, in Mt/yr, for each sim year
colSums(rs_RRn[rs_RRn$change_wren_only==TRUE,288:295])*1e-9 # 1.3Mt in 2025 to 3Mt in 2040 to 2.2Mt in 2060

# now look in more detail at specific renovations within groups, starting with heating

heatren=cbind(as.data.frame(rs_RRn[which(rs_RRn$change_hren_only_prev),c('Heating.Fuel','HVAC.Heating.Efficiency')]),as.data.frame(rs_RRn[which(rs_RRn$change_hren_only),c('Year_Building','Year','Building','Heating.Fuel','HVAC.Heating.Efficiency')]))

names(heatren)[c(1,2,6,7)]=c('Fuel_pre','Efficiency_pre','Fuel_post','Efficiency_post')
# distinguish electric HP from electric resistance
heatren[substring(heatren$Efficiency_pre,1,4) %in% c('ASHP','MSHP'),'Fuel_pre']<-'Electricity HP'
heatren[substring(heatren$Efficiency_post,1,4) %in% c('ASHP', 'MSHP'),'Fuel_post']<-'Electricity HP'

heatren$FuelEff_pre<-paste(heatren$Fuel_pre,heatren$Efficiency_pre,sep="_")
heatren$FuelEff_post<-paste(heatren$Fuel_post,heatren$Efficiency_post,sep="_")
heatren$pre_post<-paste(heatren$FuelEff_pre,heatren$FuelEff_post,sep="->")
heatren$Fuel_pre_post<-paste(heatren$Fuel_pre,heatren$Fuel_post,sep="->")
heatren<-heatren[,c('Year_Building','pre_post','Fuel_pre_post')]

# get the full details for buildings that had only a heat ren
rs_RRn2<-merge(rs_RRn,heatren,by='Year_Building',all.x = TRUE)
rs_RRn2<-rs_RRn2[with(rs_RRn2, order(Building,Year)),]

rs_RRn2<-rs_RRn2[,c('Year_Building','Year','Building','County','State','Census.Division','Census.Region','ASHRAE.IECC.Climate.Zone.2004','Building.America.Climate.Zone','ISO.RTO.Region',
                    'Geometry.Building.Type.ACS','Geometry.Building.Type.RECS','Vintage','Vintage.ACS','Heating.Fuel','Geometry.Floor.Area','HVAC.Heating.Type.And.Fuel',
                    'HVAC.Heating.Efficiency','HVAC.Cooling.Type','HVAC.Cooling.Efficiency','Water.Heater.Fuel','Water.Heater.Efficiency','Infiltration',
                    names(rs_RRn2)[which(startsWith(names(rs_RRn2),'insulation'))],names(rs_RRn2)[which(startsWith(names(rs_RRn2),'electricity'))],
                    names(rs_RRn2)[which(startsWith(names(rs_RRn2),'natural_gas'))],names(rs_RRn2)[which(startsWith(names(rs_RRn2),'propane'))],names(rs_RRn2)[which(startsWith(names(rs_RRn2),'fuel_oil'))],
                    names(rs_RRn2)[which(startsWith(names(rs_RRn2),'size'))],names(rs_RRn2)[which(startsWith(names(rs_RRn2),'total'))],
                    names(rs_RRn2)[which(startsWith(names(rs_RRn2),'Elec'))],names(rs_RRn2)[which(startsWith(names(rs_RRn2),'Gas'))],
                    names(rs_RRn2)[which(startsWith(names(rs_RRn2),'Oil'))],names(rs_RRn2)[which(startsWith(names(rs_RRn2),'Prop'))],
                    names(rs_RRn2)[which(startsWith(names(rs_RRn2),'Tot'))],names(rs_RRn2)[which(startsWith(names(rs_RRn2),'EnGHG'))],
                    names(rs_RRn2)[which(startsWith(names(rs_RRn2),'redn'))],names(rs_RRn2)[which(startsWith(names(rs_RRn2),'change'))],
                    names(rs_RRn2)[which(startsWith(names(rs_RRn2),'GHG_p'))],names(rs_RRn2)[which(startsWith(names(rs_RRn2),'redG'))],'pre_post','Fuel_pre_post',
                    names(rs_RRn2)[which(startsWith(names(rs_RRn2),'hren'))],names(rs_RRn2)[which(startsWith(names(rs_RRn2),'iren'))],
                    names(rs_RRn2)[which(startsWith(names(rs_RRn2),'wren'))],names(rs_RRn2)[which(startsWith(names(rs_RRn2),'cren'))])]
rs_RRn2$hren_assess<-rs_RRn2$change_hren_only | rs_RRn2$change_hren_only_prev
# extract only the rows we are comparing, that is buildings that either had a heat ren, or those buildings immediately pre-heat ren
rs_RRh<-rs_RRn2[rs_RRn2$hren_assess==TRUE,]

rs_RRh$RenState<-'post'
rs_RRh[is.na(rs_RRh$pre_post),]$RenState<-'pre'

# mean absolute annual GHG savings per household from heating renovations, by sim year, and with detailed fuel switching combos
hr_det_avg<-data.frame(tapply(rs_RRh[rs_RRh$RenState=='post',]$redn_GHG_abs,list(rs_RRh[rs_RRh$RenState=='post',]$Fuel_pre_post,rs_RRh[rs_RRh$RenState=='post',]$Year),mean))
names(hr_det_avg)<-gsub("X","", names(hr_det_avg))

tapply(rs_RRh[rs_RRh$RenState=='post',]$redGHGren_base_2025,list(rs_RRh[rs_RRh$RenState=='post',]$Fuel_pre_post,rs_RRh[rs_RRh$RenState=='post',]$Year),mean)*1e-6


hr_det<-data.frame('2025'=tapply(rs_RRh[rs_RRh$RenState=='post',which(startsWith(names(rs_RRh),'redGHGren_base'))[1]],list(rs_RRh[rs_RRh$RenState=='post',]$Fuel_pre_post),sum)*1e-6)
for (y in 2:8) {
  hr_det[,toString(as.character(years[y+1]))]<-data.frame(tapply(rs_RRh[rs_RRh$RenState=='post',which(startsWith(names(rs_RRh),'redGHGren_base'))[y]],list(rs_RRh[rs_RRh$RenState=='post',]$Fuel_pre_post),sum)*1e-6)
}
names(hr_det)[1]<-'2025'
hr_det$FuelSwitch<-rownames(hr_det)
rownames(hr_det)<-1:nrow(hr_det)

# very interesting the combined insights from hr_det and hr_det_avg:
# 1. In the avg results we see that changing away from fuel oil is by far the highest-impact renovation, with FO->HP giving avg annual savings ~5t/yr in 2025 declining to 2.7Gt/yr in 2060 (as the # of least efficient FO equipment declines)
# this is followed by FO->NG (until 2040) giving 2-3 t/yr savings, and FO->Elec giving ~2 t/yr savings
# By comparison, FO->FO replacements give savings of ~1.2 t/yr, and NG->NG replacements initially save ~0.6 t/yr, eventually declining to <0.4 t/yr by 2060
# 2. In the aggregated annual results, by far the biggest impact renovation is NG->NG with annual reductions b/w 2-4 Mt/yr depending on the year, this is followed by FO->FO renovations which save 0.5-0.9Mt/yr, and then HP->HP which save 0.4-0.8 Mt/yr
# Electricity Resistance->Gas gives positive savings at the aggregate scale even in 2045! FO->NG and LPG->LPG give substantial savings too, ranging from 0.2-0.4 Mt/yr.
# the highest avg impact renovations at the aggregated scale give <0.1 Mt/yr for FO->HP and FO->Elec, and 0.2-0.4 for FO->NG,

# next let's see how these comparisons play out per grid zone, and climate zone

sum_redn<-function(df,var) { # need to extend this to include LRE 
  v<-data.frame(round(tapply(df[df$RenState=='post',]$redn_GHG_abs,
                             list(df[df$RenState=='post',]$Fuel_pre_post,df[df$RenState=='post',]$Year,df[df$RenState=='post',var]),mean),2))
  v$FuelSwitch<-rownames(v)
  v<-melt(v)
  v[,var]<-substring(v$variable,7)
  v$Year<-as.numeric(substring(v$variable,2,5))
  v<-v[,c('Year',var,'FuelSwitch','value')]
  names(v)[4]<-'GHG_Redn_avg_t_yr'

  
  hr_det_v0<-data.frame(tapply(df[df$RenState=='post',which(startsWith(names(df),'redGHGren_base'))[1]],list(df[df$RenState=='post',]$Fuel_pre_post,df[df$RenState=='post',var]),sum)*1e-6)
  hr_det_v0$FuelSwitch<-rownames(hr_det_v0)
  hr_det_v0<-melt(hr_det_v0)
  hr_det_v0$Year<-years[2]
  
  for (y in 2:8) {
    hr_det_v<-data.frame(tapply(df[df$RenState=='post',which(startsWith(names(df),'redGHGren_base'))[y]],list(df[df$RenState=='post',]$Fuel_pre_post,df[df$RenState=='post',var]),sum)*1e-6)
    hr_det_v$FuelSwitch<-rownames(hr_det_v)
    hr_det_v<-melt(hr_det_v)
    hr_det_v$Year<-years[y+1]
    
    hr_det_v0<-rbind(hr_det_v0,hr_det_v)
  }
  if (var %in% c('Vintage.ACS','Vintage','Geometry.Floor.Area')) {hr_det_v0$variable<-gsub("X","",hr_det_v0$variable)}
  names(hr_det_v0)[2]<-var
  
  hr_det_v0<-hr_det_v0[,c('Year',var,'FuelSwitch','value')]
  names(hr_det_v0)[4]<-'GHG_Redn_StockTot_kt_yr'
  hr_det_v0$GHG_Redn_StockTot_kt_yr<-round(hr_det_v0$GHG_Redn_StockTot_kt_yr,1)
  
  v<-merge(v,hr_det_v0)
  
  # now add some cumulative impact measures
  # first average cumulative impact
  vc<-data.frame(round(tapply(df[df$RenState=='post',]$hren_redn_cum_tCO2,
                                 list(df[df$RenState=='post',]$Fuel_pre_post,df[df$RenState=='post',]$Year,df[df$RenState=='post',var]),mean),2))
  vc$FuelSwitch<-rownames(vc)
  vc<-melt(vc)
  vc[,var]<-substring(vc$variable,7)
  vc$Year<-as.numeric(substring(vc$variable,2,5))
  vc<-vc[,c('Year',var,'FuelSwitch','value')]
  names(vc)[4]<-'GHG_Redn_Cum_avg_t'
  # then stock-wide sum cumulative impacts
  vcs<-data.frame(round(tapply(df[df$RenState=='post',]$hren_sredn_cum_tCO2,
                                 list(df[df$RenState=='post',]$Fuel_pre_post,df[df$RenState=='post',]$Year,df[df$RenState=='post',var]),sum),2))*1e-6
  vcs$FuelSwitch<-rownames(vcs)
  vcs<-melt(vcs)
  vcs[,var]<-substring(vcs$variable,7)
  vcs$Year<-as.numeric(substring(vcs$variable,2,5))
  vcs<-vcs[,c('Year',var,'FuelSwitch','value')]
  names(vcs)[4]<-'GHG_Redn_Cum_StockTot_Mt'
  
  v<-merge(v,vc)
  
  v<-merge(v,vcs)
  
  count<-melt(tapply(df$Building,list(df$Year,df[,var],df$Fuel_pre_post),length))
  names(count)<-c('Year',var,'FuelSwitch','Count')
  count[,var]<-gsub('<','.',count[,var])
  count[,var]<-gsub('-','.',count[,var])
  count[,var]<-gsub(' ','.',count[,var])
  
  v<-merge(v,count)
  v$NumBuildings<-round(1000*v$GHG_Redn_StockTot_kt_yr/v$GHG_Redn_avg_t_yr)
  
  vl<-v[v$FuelSwitch %in% c('Electricity->Electricity HP','Electricity->Natural Gas','Electricity->Electricity',
                            'Electricity HP->Electricity HP',
                            'Fuel Oil->Electricity','Fuel Oil->Electricity HP','Fuel Oil->Fuel Oil','Fuel Oil->Natural Gas',
                            'Natural Gas->Electricity','Natural Gas->Electricity HP','Natural Gas->Natural Gas',
                            'Propane->Electricity','Propane->Electricity HP','Propane->Propane','Propane->Natural Gas'),]
  
  vl<-vl[complete.cases(vl),]
  vl<-vl[vl$Count>9,]
  # pick out some highlights with high potential impact
  #vl_highlight<-vl[vl$GHG_Redn_StockTot_kt_yr>150 & vl$NumBuildings<500000,].
  # ... measured as high cumulative potential in an individual buildings or stock wide
  vl_highlight<-vl[vl$GHG_Redn_Cum_StockTot_Mt>1.5 | vl$GHG_Redn_Cum_avg_t>30 ,]
  
  return (list(v, vl,vl_highlight))
}

sr<-sum_redn(rs_RRh,'Vintage.ACS')
vint<-sr[[1]]
vint_sum<-sr[[2]]
vint_highlight<-sr[[3]]

sr<-sum_redn(rs_RRh,'Census.Region')
reg<-sr[[1]]
reg_sum<-sr[[2]]
reg_highlight<-sr[[3]]

sr<-sum_redn(rs_RRh,'Census.Region')
reg<-sr[[1]]
reg_sum<-sr[[2]]
reg_highlight<-sr[[3]]

sr<-sum_redn(rs_RRh,'Census.Division')
div<-sr[[1]]
div_sum<-sr[[2]]
div_highlight<-sr[[3]]

sr<-sum_redn(rs_RRh,'Building.America.Climate.Zone')
bacz<-sr[[1]]
bacz_sum<-sr[[2]]
bacz_highlight<-sr[[3]]

sr<-sum_redn(rs_RRh,'State')
st<-sr[[1]]
st_sum<-sr[[2]]
st_highlight<-sr[[3]]

# now repeat for water heating
dhwren=cbind(as.data.frame(rs_RRn[which(rs_RRn$change_wren_only_prev),c('Heating.Fuel','HVAC.Heating.Efficiency')]),as.data.frame(rs_RRn[which(rs_RRn$change_wren_only),c('Year_Building','Year','Building','Heating.Fuel','HVAC.Heating.Efficiency')]))

names(dhwren)[c(1,2,6,7)]=c('Fuel_pre','Efficiency_pre','Fuel_post','Efficiency_post')
# distinguish electric HP from electric resistance
dhwren[substring(dhwren$Efficiency_pre,1,4) %in% c('ASHP','MSHP'),'Fuel_pre']<-'Electricity HP'
dhwren[substring(dhwren$Efficiency_post,1,4) %in% c('ASHP', 'MSHP'),'Fuel_post']<-'Electricity HP'

dhwren$FuelEff_pre<-paste(dhwren$Fuel_pre,dhwren$Efficiency_pre,sep="_")
dhwren$FuelEff_post<-paste(dhwren$Fuel_post,dhwren$Efficiency_post,sep="_")
dhwren$pre_post<-paste(dhwren$FuelEff_pre,dhwren$FuelEff_post,sep="->")
dhwren$Fuel_pre_post<-paste(dhwren$Fuel_pre,dhwren$Fuel_post,sep="->")
dhwren<-dhwren[,c('Year_Building','pre_post','Fuel_pre_post')]

# get the full details for buildings that had only a heat ren
rs_RRn2<-merge(rs_RRn,dhwren,by='Year_Building',all.x = TRUE)
rs_RRn2<-rs_RRn2[with(rs_RRn2, order(Building,Year)),]

rs_RRn2<-rs_RRn2[,c('Year_Building','Year','Building','County','State','Census.Division','Census.Region','ASHRAE.IECC.Climate.Zone.2004','Building.America.Climate.Zone','ISO.RTO.Region',
                    'Geometry.Building.Type.ACS','Geometry.Building.Type.RECS','Vintage','Vintage.ACS','Heating.Fuel','Geometry.Floor.Area','HVAC.Heating.Type.And.Fuel',
                    'HVAC.Heating.Efficiency','HVAC.Cooling.Type','HVAC.Cooling.Efficiency','Water.Heater.Fuel','Water.Heater.Efficiency','Infiltration',
                    names(rs_RRn2)[which(startsWith(names(rs_RRn2),'insulation'))],names(rs_RRn2)[which(startsWith(names(rs_RRn2),'electricity'))],
                    names(rs_RRn2)[which(startsWith(names(rs_RRn2),'natural_gas'))],names(rs_RRn2)[which(startsWith(names(rs_RRn2),'propane'))],names(rs_RRn2)[which(startsWith(names(rs_RRn2),'fuel_oil'))],
                    names(rs_RRn2)[which(startsWith(names(rs_RRn2),'size'))],names(rs_RRn2)[which(startsWith(names(rs_RRn2),'total'))],
                    names(rs_RRn2)[which(startsWith(names(rs_RRn2),'Elec'))],names(rs_RRn2)[which(startsWith(names(rs_RRn2),'Gas'))],
                    names(rs_RRn2)[which(startsWith(names(rs_RRn2),'Oil'))],names(rs_RRn2)[which(startsWith(names(rs_RRn2),'Prop'))],
                    names(rs_RRn2)[which(startsWith(names(rs_RRn2),'Tot'))],names(rs_RRn2)[which(startsWith(names(rs_RRn2),'EnGHG'))],
                    names(rs_RRn2)[which(startsWith(names(rs_RRn2),'redn'))],names(rs_RRn2)[which(startsWith(names(rs_RRn2),'change'))],
                    names(rs_RRn2)[which(startsWith(names(rs_RRn2),'GHG_p'))],names(rs_RRn2)[which(startsWith(names(rs_RRn2),'redG'))],'pre_post','Fuel_pre_post',
                    names(rs_RRn2)[which(startsWith(names(rs_RRn2),'hren'))],names(rs_RRn2)[which(startsWith(names(rs_RRn2),'iren'))],
                    names(rs_RRn2)[which(startsWith(names(rs_RRn2),'wren'))],names(rs_RRn2)[which(startsWith(names(rs_RRn2),'cren'))])]
rs_RRn2$wren_assess<-rs_RRn2$change_wren_only | rs_RRn2$change_wren_only_prev
# extract only the rows we are comparing, that is buildings that either had a heat ren, or those buildings immediately pre-heat ren
rs_RRw<-rs_RRn2[rs_RRn2$wren_assess==TRUE,]

rs_RRw$RenState<-'post'
rs_RRw[is.na(rs_RRw$pre_post),]$RenState<-'pre'

# calculate summary renovation reductions in energy demand

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

# save the summary tables of renovation effects
save(heat_typ_reg_rr,heat_age_reg_rr,heat_typ_age_rr, cool_typ_reg_rr,cool_age_reg_rr,cool_typ_age_rr, dhw_typ_reg_rr,dhw_age_reg_rr,dhw_typ_age_rr,
     ins_typ_reg_rr,ins_age_reg_rr,ins_typ_age_rr,file = "Intermediate_results/RR_redn.RData")

# repeat the long function of adding decay factors with the AR files ########
rs_all_AR<-rs_2020_60_AR
rs_all_AR$Year_Building<-paste(rs_all_AR$Year,rs_all_AR$Building,sep="_")

rs_all_AR<-rs_all_AR[,c("Year_Building","Year", "Building","County","State","Location.Region","Census.Division", "Census.Region", "ASHRAE.IECC.Climate.Zone.2004", "PUMA", "ISO.RTO.Region", "Geometry.Building.Type.ACS","Geometry.Building.Type.RECS",
                        "Vintage","Vintage.ACS","Heating.Fuel","Geometry.Floor.Area","Geometry.Foundation.Type","Geometry.Wall.Type","Geometry.Stories","Geometry.Garage",
                        "HVAC.Heating.Type.And.Fuel","HVAC.Heating.Efficiency","HVAC.Cooling.Type","HVAC.Cooling.Efficiency","Water.Heater.Fuel","Water.Heater.Efficiency",
                        "Clothes.Dryer","Infiltration", "change_cren","change_iren","change_wren","change_hren","base_weight")] # currently comes to 34 columns

rs_all_AR<-rs_all_AR[order(rs_all_AR$Building),]

rs_all_AR$TC<-"MF"
rs_all_AR[rs_all_AR$Geometry.Building.Type.RECS=="Single-Family Attached" | rs_all_AR$Geometry.Building.Type.RECS=="Single-Family Detached",]$TC<-"SF"
rs_all_AR[rs_all_AR$Geometry.Building.Type.RECS=="Mobile Home",]$TC<-"MH"
rs_all_AR$TC<-paste(rs_all_AR$TC,rs_all_AR$Vintage.ACS,sep="_")
rs_all_AR$ctyTC<-paste(rs_all_AR$County,rs_all_AR$TC,sep = "")
rs_all_AR$ctyTC<-gsub("2010s","2010-19",rs_all_AR$ctyTC)

# at this stage we are at 36 columns
# now add 9 columns for each stock scenario to bring us to 63
rs_all_AR<-left_join(rs_all_AR,sbm,by="ctyTC")
rs_all_AR<-left_join(rs_all_AR,shdrm,by="ctyTC")
rs_all_AR<-left_join(rs_all_AR,shmfm,by="ctyTC")

rs_all_AR$sim.range<-"Undefined"
for (b in 1:180000) { # this takes a while
  # for (b in c(1:15,9900,9934)) {
  print(b)
  w<-which(rs_all_AR$Building==b)

  for (sr in 1:(length(w)-1)) {
    rs_all_AR$sim.range[w[sr]]<-paste(rs_all_AR[w[sr],"Year"],rs_all_AR[w[sr+1],"Year"]-5,sep = ".")
  }
  for (sr in length(w)) {
    rs_all_AR$sim.range[w[sr]]<-paste(rs_all_AR[w[sr],"Year"],"2060",sep = ".")
  }
  # create concordance matrix to identify which weighting factors should be zero and non-zero
  conc<-matrix(rep(0,9*length(w)),length(w),9)
  for (c in 1:length(w)) {
    conc[c, which(names(rs_all_AR[37:45])==paste("wbase", substr(rs_all_AR$sim.range[w[c]],1,4),sep="_")):
           which(names(rs_all_AR[37:45])==paste("wbase", substr(rs_all_AR$sim.range[w[c]],6,9),sep="_"))]<-1
  }

  rs_all_AR[w,37:45]<-rs_all_AR[w,37:45]*conc
  rs_all_AR[w,46:54]<-rs_all_AR[w,46:54]*conc
  rs_all_AR[w,55:63]<-rs_all_AR[w,55:63]*conc

}
save(rs_all_AR,file="../Intermediate_results/RenAdvanced_full.Rdata")
# againm if the rs_all_AR has already been created, best to load it in with the line below, as it takes a long time to generate
# load("Intermediate_results/RenAdvanced_full.Rdata")

# merge with the energy results
rs_all_AR_res<-rbind(rs2020_sum,rs25AR_sum,rs30AR_sum,rs35AR_sum,rs40AR_sum,rs45AR_sum,rs50AR_sum,rs55AR_sum,rs60AR_sum)
rm(rs25AR,rs25AR_sum,rs30AR,rs30AR_sum,rs35AR,rs35AR_sum,rs40AR,rs40AR_sum,rs45AR,rs45AR_sum,rs50AR,rs50AR_sum,rs55AR,rs55AR_sum,rs60AR,rs60AR_sum)
rs_all_AR_res<-rs_all_AR_res[,c(1:3,23,43,44,55:63,66,81,82,88,95,103,105:111,113:122,124:129,131,133,135:141,148:200)] # bigger reduced version

rs_AR<-merge(rs_all_AR,rs_all_AR_res)
rs_ARn<-rs_AR[order(rs_AR$Building),]
rm(rs_AR)
# add GHG intensities, Mid-Case. make sure to use the gea intensities, which were calculated above, for use with RegRen
rs_ARn<-left_join(rs_ARn,gic,by = c("County" = "RS_ID"))
# add GHG intensities, Low RE Cost
rs_ARn<-left_join(rs_ARn,gic_LRE,by = c("County" = "RS_ID"))

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

# calculate avg reductions in total household final energy per renovation type
rs_ARn$redn_hren<-rs_ARn$redn_wren<-rs_ARn$redn_iren<-rs_ARn$redn_cren<-rs_ARn$redn_hren_iren<-0
rs_ARn$GHG_pre<-rs_ARn$GHG_post<-0
rs_ARn$redn_GHG_pc<-rs_ARn$redn_GHG_abs<-0
rs_ARn$GHG_pre_LRE<-rs_ARn$GHG_post_LRE<-0
rs_ARn$redn_GHG_LRE_pc<-rs_ARn$redn_GHG_LRE_abs<-0
rs_ARn$change_hren_only<-rs_ARn$change_wren_only<-rs_ARn$change_iren_only<-rs_ARn$change_cren_only<-rs_ARn$change_hren_iren<-FALSE
rs_ARn$change_hren_only_prev<-rs_ARn$change_wren_only_prev<-rs_ARn$change_iren_only_prev<-rs_ARn$change_cren_only_prev<-rs_ARn$change_hren_iren_prev<-FALSE
years<-seq(2020,2060,5)
for (k in 1:180000) { print(k) # this will probably take a while, about 7 hrs. do this tonight.
  w<-which(rs_ARn$Building==k) 
  if (length(w) > 1) { # if there are any renovations
    for (j in 1:(length(w)-1)) {
      if (rs_ARn[w[j+1],]$change_cren!=rs_ARn[w[j],]$change_cren & identical(as.numeric(rs_ARn[w[j+1],31:33]),as.numeric(rs_ARn[w[j],31:33])) ) { # if only change_cren changes
        rs_ARn$redn_cren[w[j+1]]<-1-(rs_ARn$Tot_GJ[w[j+1]]/rs_ARn$Tot_GJ[w[j]])
        rs_ARn$change_cren_only[w[j+1]]<-TRUE
        rs_ARn$change_cren_only_prev[w[j]]<-TRUE
      }
      if (rs_ARn[w[j+1],]$change_iren!=rs_ARn[w[j],]$change_iren & identical(as.numeric(rs_ARn[w[j+1],c(30,32,33)]),as.numeric(rs_ARn[w[j],c(30,32,33)])) ) { # if only change_iren changes
        rs_ARn$redn_iren[w[j+1]]<-1-(rs_ARn$Tot_GJ[w[j+1]]/rs_ARn$Tot_GJ[w[j]])
        rs_ARn$change_iren_only[w[j+1]]<-TRUE
        rs_ARn$change_iren_only_prev[w[j]]<-TRUE
      } 
      if (rs_ARn[w[j+1],]$change_wren!=rs_ARn[w[j],]$change_wren & identical(as.numeric(rs_ARn[w[j+1],c(30,31,33)]),as.numeric(rs_ARn[w[j],c(30,31,33)])) ) { # if only change_wren changes
        rs_ARn$redn_wren[w[j+1]]<-1-(rs_ARn$Tot_GJ[w[j+1]]/rs_ARn$Tot_GJ[w[j]])
        rs_ARn$change_wren_only[w[j+1]]<-TRUE
        rs_ARn$change_wren_only_prev[w[j]]<-TRUE
      }
      if (rs_ARn[w[j+1],]$change_hren!=rs_ARn[w[j],]$change_hren & identical(as.numeric(rs_ARn[w[j+1],30:32]),as.numeric(rs_ARn[w[j],30:32])) ) { # if only change_hren changes
        rs_ARn$redn_hren[w[j+1]]<-1-(rs_ARn$Tot_GJ[w[j+1]]/rs_ARn$Tot_GJ[w[j]])
        rs_ARn$change_hren_only[w[j+1]]<-TRUE
        rs_ARn$change_hren_only_prev[w[j]]<-TRUE
      }
      if (rs_ARn[w[j+1],]$change_hren!=rs_ARn[w[j],]$change_hren & rs_ARn[w[j+1],]$change_iren!=rs_ARn[w[j],]$change_iren & identical(as.numeric(rs_ARn[w[j+1],c(30,32)]),as.numeric(rs_ARn[w[j],c(30,32)])) ) {  # if (only) change_hren and change_iren change together 
        rs_ARn$redn_hren_iren[w[j+1]]<-1-(rs_ARn$Tot_GJ[w[j+1]]/rs_ARn$Tot_GJ[w[j]])
        rs_ARn$change_hren_iren[w[j+1]]<-TRUE
        rs_ARn$change_hren_iren_prev[w[j]]<-TRUE
      }
      
      y<-which(years==rs_ARn$Year[w[j+1]])
      rs_ARn$GHG_pre[w[j]]<-rs_ARn$Elec_GJ[w[j]]*rs_ARn[w[j+1],names(rs_ARn)[169:177][y]] + rs_ARn$Gas_GJ[w[j]]*GHGI_NG +  rs_ARn$Oil_GJ[w[j]]*GHGI_FO +  rs_ARn$Prop_GJ[w[j]]*GHGI_LP  
      rs_ARn$GHG_post[w[j+1]]<-rs_ARn$Elec_GJ[w[j+1]]*rs_ARn[w[j+1],names(rs_ARn)[169:177][y]] + rs_ARn$Gas_GJ[w[j+1]]*GHGI_NG +  rs_ARn$Oil_GJ[w[j+1]]*GHGI_FO +  rs_ARn$Prop_GJ[w[j+1]]*GHGI_LP 
      rs_ARn$redn_GHG_pc[w[j+1]]<-(rs_ARn$GHG_pre[w[j]]-rs_ARn$GHG_post[w[j+1]])/rs_ARn$GHG_pre[w[j]]
      
      rs_ARn$GHG_pre_LRE[w[j]]<-rs_ARn$Elec_GJ[w[j]]*rs_ARn[w[j+1],names(rs_ARn)[178:186][y]] + rs_ARn$Gas_GJ[w[j]]*GHGI_NG +  rs_ARn$Oil_GJ[w[j]]*GHGI_FO +  rs_ARn$Prop_GJ[w[j]]*GHGI_LP  
      rs_ARn$GHG_post_LRE[w[j+1]]<-rs_ARn$Elec_GJ[w[j+1]]*rs_ARn[w[j+1],names(rs_ARn)[178:186][y]] + rs_ARn$Gas_GJ[w[j+1]]*GHGI_NG +  rs_ARn$Oil_GJ[w[j+1]]*GHGI_FO +  rs_ARn$Prop_GJ[w[j+1]]*GHGI_LP 
      rs_ARn$redn_GHG_LRE_pc[w[j+1]]<-(rs_ARn$GHG_pre_LRE[w[j]]-rs_ARn$GHG_post_LRE[w[j+1]])/rs_ARn$GHG_pre_LRE[w[j]]
      rs_ARn$redn_GHG_LRE_abs[w[j+1]]<-(rs_ARn$GHG_pre_LRE[w[j]]-rs_ARn$GHG_post_LRE[w[j+1]])
    }
  }
}

# Calculate cumulative reductions
rs_ARn<-calc_cum_red(rs_ARn,'cren')
rs_ARn<-calc_cum_red(rs_ARn,'iren')
rs_ARn<-calc_cum_red(rs_ARn,'wren')
rs_ARn<-calc_cum_red(rs_ARn,'hren')
rs_ARn<-calc_cum_red(rs_ARn,'hren_iren')

# see how the renovation families compare to each other
# avg by year
tapply(rs_ARn$hren_redn_cum_tCO2 ,list(rs_ARn$Year,rs_ARn$change_hren_only),mean,na.rm=TRUE) # 20 tCO2 on average
tapply(rs_ARn$wren_redn_cum_tCO2 ,list(rs_ARn$Year,rs_ARn$change_wren_only),mean,na.rm=TRUE) # 6t CO2 on average
tapply(rs_ARn$iren_redn_cum_tCO2 ,list(rs_ARn$Year,rs_ARn$change_iren_only),mean,na.rm=TRUE) # 21-28 tCO2 on average  
tapply(rs_ARn$cren_redn_cum_tCO2 ,list(rs_ARn$Year,rs_ARn$change_cren_only),mean,na.rm=TRUE) # 0.7-1.4 tCO2
tapply(rs_ARn$hren_iren_redn_cum_tCO2 ,list(rs_ARn$Year,rs_ARn$change_hren_iren),mean,na.rm=TRUE) # 48-50 tCO2 on average

# avg by Division
tapply(rs_ARn$hren_redn_cum_tCO2 ,list(rs_ARn$Census.Division,rs_ARn$change_hren_only),mean,na.rm=TRUE) # New England is so far ahead here. Especially in Maine and Vermont
tapply(rs_ARn$wren_redn_cum_tCO2 ,list(rs_ARn$Census.Division,rs_ARn$change_wren_only),mean,na.rm=TRUE) 
tapply(rs_ARn$iren_redn_cum_tCO2 ,list(rs_ARn$Census.Division,rs_ARn$change_iren_only),mean,na.rm=TRUE) # NE and ENC have biggest impact
tapply(rs_ARn$cren_redn_cum_tCO2 ,list(rs_ARn$Census.Division,rs_ARn$change_cren_only),mean,na.rm=TRUE) # only real savings in ESC and WSC 
tapply(rs_ARn$hren_iren_redn_cum_tCO2 ,list(rs_ARn$Census.Division,rs_ARn$change_hren_iren),mean,na.rm=TRUE) # from 26 tCO2 in WSC to 94 tCO2 in NE, next highest is MitAtl

# avg by House Type
tapply(rs_ARn$hren_redn_cum_tCO2 ,list(rs_ARn$Geometry.Building.Type.RECS,rs_ARn$change_hren_only),mean,na.rm=TRUE) 
tapply(rs_ARn$hren_redn_cum_tCO2 ,list(rs_ARn$Geometry.Building.Type.ACS,rs_ARn$change_hren_only),mean,na.rm=TRUE) 
tapply(rs_ARn$wren_redn_cum_tCO2 ,list(rs_ARn$Geometry.Building.Type.RECS,rs_ARn$change_wren_only),mean,na.rm=TRUE) 
tapply(rs_ARn$iren_redn_cum_tCO2 ,list(rs_ARn$Geometry.Building.Type.RECS,rs_ARn$change_iren_only),mean,na.rm=TRUE) 
tapply(rs_ARn$cren_redn_cum_tCO2 ,list(rs_ARn$Geometry.Building.Type.RECS,rs_ARn$change_cren_only),mean,na.rm=TRUE) 
tapply(rs_ARn$hren_iren_redn_cum_tCO2 ,list(rs_ARn$Geometry.Building.Type.RECS,rs_ARn$change_hren_iren),mean,na.rm=TRUE)

# avg by Vintage
tapply(rs_ARn$hren_redn_cum_tCO2 ,list(rs_ARn$Vintage.ACS,rs_ARn$change_hren_only),mean,na.rm=TRUE) 
tapply(rs_ARn$wren_redn_cum_tCO2 ,list(rs_ARn$Vintage.ACS,rs_ARn$change_wren_only),mean,na.rm=TRUE) 
tapply(rs_ARn$iren_redn_cum_tCO2 ,list(rs_ARn$Vintage.ACS,rs_ARn$change_iren_only),mean,na.rm=TRUE) # unusual that 2010s houses have a large avg, but N is small, 1072 in this case
tapply(rs_ARn$cren_redn_cum_tCO2 ,list(rs_ARn$Vintage.ACS,rs_ARn$change_cren_only),mean,na.rm=TRUE) 
tapply(rs_ARn$hren_iren_redn_cum_tCO2 ,list(rs_ARn$Vintage.ACS,rs_ARn$change_hren_iren),mean,na.rm=TRUE) # 68t on average in <1940

# avg by House Size. 
tapply(rs_ARn$hren_redn_cum_tCO2 ,list(rs_ARn$Geometry.Floor.Area,rs_ARn$change_hren_only),mean,na.rm=TRUE) 
tapply(rs_ARn$wren_redn_cum_tCO2 ,list(rs_ARn$Geometry.Floor.Area,rs_ARn$change_wren_only),mean,na.rm=TRUE) 
tapply(rs_ARn$iren_redn_cum_tCO2 ,list(rs_ARn$Geometry.Floor.Area,rs_ARn$change_iren_only),mean,na.rm=TRUE) 
tapply(rs_ARn$cren_redn_cum_tCO2 ,list(rs_ARn$Geometry.Floor.Area,rs_ARn$change_cren_only),mean,na.rm=TRUE) 
tapply(rs_ARn$hren_iren_redn_cum_tCO2 ,list(rs_ARn$Geometry.Floor.Area,rs_ARn$change_hren_iren),mean,na.rm=TRUE) # 117 tCO2 on average in homes over 4000 ft2

# include climate zone in rs_ARn
rs_ARn<-merge(rs_ARn,cz)
rs_ARn<-rs_ARn[with(rs_ARn, order(Building,Year)),]

# save this modified dataframe
save(rs_ARn,file = "Intermediate_results/RenAdvanced_EG.RData")

# calculate summary of renovations on energy reduction
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

# and now finally for ER #########
rs_all_ER<-rs_2020_60_ER
rs_all_ER$Year_Building<-paste(rs_all_ER$Year,rs_all_ER$Building,sep="_")

rs_all_ER<-rs_all_ER[,c("Year_Building","Year", "Building","County","State","Location.Region","Census.Division", "Census.Region", "ASHRAE.IECC.Climate.Zone.2004", "PUMA", "ISO.RTO.Region", "Geometry.Building.Type.ACS","Geometry.Building.Type.RECS",
                        "Vintage","Vintage.ACS","Heating.Fuel","Geometry.Floor.Area","Geometry.Foundation.Type","Geometry.Wall.Type","Geometry.Stories","Geometry.Garage",
                        "HVAC.Heating.Type.And.Fuel","HVAC.Heating.Efficiency","HVAC.Cooling.Type","HVAC.Cooling.Efficiency","Water.Heater.Fuel","Water.Heater.Efficiency",
                        "Clothes.Dryer","Infiltration", "change_cren","change_iren","change_wren","change_hren","base_weight")] # currently comes to 34 columns

rs_all_ER<-rs_all_ER[order(rs_all_ER$Building),]

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

rs_all_ER$sim.range<-"Undefined"
for (b in 1:180000) { # this takes a while
  # for (b in c(1:15,9900,9934)) {
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
save(rs_all_ER,file="../Intermediate_results/RenAdvanced_full.Rdata")
# best to only create this file once, and then using the line below to load it in
# load("Intermediate_results/RenExtElec_full.Rdata")

# merge with the energy results
rs_all_ER_res<-rbind(rs2020_sum,rs25ER_sum,rs30ER_sum,rs35ER_sum,rs40ER_sum,rs45ER_sum,rs50ER_sum,rs55ER_sum,rs60ER_sum)
rm(rs25ER,rs25ER_sum,rs30ER,rs30ER_sum,rs35ER,rs35ER_sum,rs40ER,rs40ER_sum,rs45ER,rs45ER_sum,rs50ER,rs50ER_sum,rs55ER,rs55ER_sum,rs60ER,rs60ER_sum)
rs_all_ER_res<-rs_all_ER_res[,c(1:3,23,43,44,55:63,66,81,82,88,95,103,105:111,113:122,124:129,131,133,135:141,148:200)] # bigger reduced version

rs_ER<-merge(rs_all_ER,rs_all_ER_res)
rs_ERn<-rs_ER[order(rs_ER$Building),]
rm(rs_ER)
# add GHG intensities, Mid-Case. make sure to use the gea intensities, which were calculated above, for use with RegRen
rs_ERn<-left_join(rs_ERn,gic,by = c("County" = "RS_ID"))
# add GHG intensities, Low RE Cost
rs_ERn<-left_join(rs_ERn,gic_LRE,by = c("County" = "RS_ID"))

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

# calculate avg reductions in total household final energy per renovation type
rs_ERn$redn_hren<-rs_ERn$redn_wren<-rs_ERn$redn_iren<-rs_ERn$redn_cren<-rs_ERn$redn_hren_iren<-0
rs_ERn$GHG_pre<-rs_ERn$GHG_post<-0
rs_ERn$redn_GHG_pc<-rs_ERn$redn_GHG_abs<-0
rs_ERn$GHG_pre_LRE<-rs_ERn$GHG_post_LRE<-0
rs_ERn$redn_GHG_LRE_pc<-rs_ERn$redn_GHG_LRE_abs<-0
rs_ERn$change_hren_only<-rs_ERn$change_wren_only<-rs_ERn$change_iren_only<-rs_ERn$change_cren_only<-rs_ERn$change_hren_iren<-FALSE
rs_ERn$change_hren_only_prev<-rs_ERn$change_wren_only_prev<-rs_ERn$change_iren_only_prev<-rs_ERn$change_cren_only_prev<-rs_ERn$change_hren_iren_prev<-FALSE
years<-seq(2020,2060,5)
for (k in 1:180000) { print(k) # this will probably take a while, about 7 hrs. 
  w<-which(rs_ERn$Building==k) 
  if (length(w) > 1) { # if there are any renovations
    for (j in 1:(length(w)-1)) {
      if (rs_ERn[w[j+1],]$change_cren!=rs_ERn[w[j],]$change_cren & identical(as.numeric(rs_ERn[w[j+1],31:33]),as.numeric(rs_ERn[w[j],31:33])) ) { # if only change_cren changes
        rs_ERn$redn_cren[w[j+1]]<-1-(rs_ERn$Tot_GJ[w[j+1]]/rs_ERn$Tot_GJ[w[j]])
        rs_ERn$change_cren_only[w[j+1]]<-TRUE
        rs_ERn$change_cren_only_prev[w[j]]<-TRUE
      }
      if (rs_ERn[w[j+1],]$change_iren!=rs_ERn[w[j],]$change_iren & identical(as.numeric(rs_ERn[w[j+1],c(30,32,33)]),as.numeric(rs_ERn[w[j],c(30,32,33)])) ) { # if only change_iren changes
        rs_ERn$redn_iren[w[j+1]]<-1-(rs_ERn$Tot_GJ[w[j+1]]/rs_ERn$Tot_GJ[w[j]])
        rs_ERn$change_iren_only[w[j+1]]<-TRUE
        rs_ERn$change_iren_only_prev[w[j]]<-TRUE
      } 
      if (rs_ERn[w[j+1],]$change_wren!=rs_ERn[w[j],]$change_wren & identical(as.numeric(rs_ERn[w[j+1],c(30,31,33)]),as.numeric(rs_ERn[w[j],c(30,31,33)])) ) { # if only change_wren changes
        rs_ERn$redn_wren[w[j+1]]<-1-(rs_ERn$Tot_GJ[w[j+1]]/rs_ERn$Tot_GJ[w[j]])
        rs_ERn$change_wren_only[w[j+1]]<-TRUE
        rs_ERn$change_wren_only_prev[w[j]]<-TRUE
      }
      if (rs_ERn[w[j+1],]$change_hren!=rs_ERn[w[j],]$change_hren & identical(as.numeric(rs_ERn[w[j+1],30:32]),as.numeric(rs_ERn[w[j],30:32])) ) { # if only change_hren changes
        rs_ERn$redn_hren[w[j+1]]<-1-(rs_ERn$Tot_GJ[w[j+1]]/rs_ERn$Tot_GJ[w[j]])
        rs_ERn$change_hren_only[w[j+1]]<-TRUE
        rs_ERn$change_hren_only_prev[w[j]]<-TRUE
      }
      if (rs_ERn[w[j+1],]$change_hren!=rs_ERn[w[j],]$change_hren & rs_ERn[w[j+1],]$change_iren!=rs_ERn[w[j],]$change_iren & identical(as.numeric(rs_ERn[w[j+1],c(30,32)]),as.numeric(rs_ERn[w[j],c(30,32)])) ) {  # if (only) change_hren and change_iren change together 
        rs_ERn$redn_hren_iren[w[j+1]]<-1-(rs_ERn$Tot_GJ[w[j+1]]/rs_ERn$Tot_GJ[w[j]])
        rs_ERn$change_hren_iren[w[j+1]]<-TRUE
        rs_ERn$change_hren_iren_prev[w[j]]<-TRUE
      }
      
      y<-which(years==rs_ERn$Year[w[j+1]])
      rs_ERn$GHG_pre[w[j]]<-rs_ERn$Elec_GJ[w[j]]*rs_ERn[w[j+1],names(rs_ERn)[169:177][y]] + rs_ERn$Gas_GJ[w[j]]*GHGI_NG +  rs_ERn$Oil_GJ[w[j]]*GHGI_FO +  rs_ERn$Prop_GJ[w[j]]*GHGI_LP  
      rs_ERn$GHG_post[w[j+1]]<-rs_ERn$Elec_GJ[w[j+1]]*rs_ERn[w[j+1],names(rs_ERn)[169:177][y]] + rs_ERn$Gas_GJ[w[j+1]]*GHGI_NG +  rs_ERn$Oil_GJ[w[j+1]]*GHGI_FO +  rs_ERn$Prop_GJ[w[j+1]]*GHGI_LP 
      rs_ERn$redn_GHG_pc[w[j+1]]<-(rs_ERn$GHG_pre[w[j]]-rs_ERn$GHG_post[w[j+1]])/rs_ERn$GHG_pre[w[j]]
      rs_ERn$redn_GHG_abs[w[j+1]]<-(rs_ERn$GHG_pre[w[j]]-rs_ERn$GHG_post[w[j+1]])
      
      rs_ERn$GHG_pre_LRE[w[j]]<-rs_ERn$Elec_GJ[w[j]]*rs_ERn[w[j+1],names(rs_ERn)[178:186][y]] + rs_ERn$Gas_GJ[w[j]]*GHGI_NG +  rs_ERn$Oil_GJ[w[j]]*GHGI_FO +  rs_ERn$Prop_GJ[w[j]]*GHGI_LP  
      rs_ERn$GHG_post_LRE[w[j+1]]<-rs_ERn$Elec_GJ[w[j+1]]*rs_ERn[w[j+1],names(rs_ERn)[178:186][y]] + rs_ERn$Gas_GJ[w[j+1]]*GHGI_NG +  rs_ERn$Oil_GJ[w[j+1]]*GHGI_FO +  rs_ERn$Prop_GJ[w[j+1]]*GHGI_LP 
      rs_ERn$redn_GHG_LRE_pc[w[j+1]]<-(rs_ERn$GHG_pre_LRE[w[j]]-rs_ERn$GHG_post_LRE[w[j+1]])/rs_ERn$GHG_pre_LRE[w[j]]
      rs_ERn$redn_GHG_LRE_abs[w[j+1]]<-(rs_ERn$GHG_pre_LRE[w[j]]-rs_ERn$GHG_post_LRE[w[j+1]])
    }
  }
}

# Calculate cumulative reductions
rs_ERn<-calc_cum_red(rs_ERn,'cren')
rs_ERn<-calc_cum_red(rs_ERn,'iren')
rs_ERn<-calc_cum_red(rs_ERn,'wren')
rs_ERn<-calc_cum_red(rs_ERn,'hren')
rs_ERn<-calc_cum_red(rs_ERn,'hren_iren')

# see how the renovation families compare to each other
# avg by year
tapply(rs_ERn$hren_redn_cum_tCO2 ,list(rs_ERn$Year,rs_ERn$change_hren_only),mean,na.rm=TRUE) # 29-36 tCO2 on average
tapply(rs_ERn$wren_redn_cum_tCO2 ,list(rs_ERn$Year,rs_ERn$change_wren_only),mean,na.rm=TRUE) # 6t CO2 on average
tapply(rs_ERn$iren_redn_cum_tCO2 ,list(rs_ERn$Year,rs_ERn$change_iren_only),mean,na.rm=TRUE) # 16-28 tCO2 on average  
tapply(rs_ERn$cren_redn_cum_tCO2 ,list(rs_ERn$Year,rs_ERn$change_cren_only),mean,na.rm=TRUE) # 0.5-1.4 tCO2
tapply(rs_ERn$hren_iren_redn_cum_tCO2 ,list(rs_ERn$Year,rs_ERn$change_hren_iren),mean,na.rm=TRUE) # 58-62 tCO2 on average

# avg by Division
tapply(rs_ERn$hren_redn_cum_tCO2 ,list(rs_ERn$Census.Division,rs_ERn$change_hren_only),mean,na.rm=TRUE) # New England is so far ahead here. Especially in Maine and Vermont
tapply(rs_ERn$wren_redn_cum_tCO2 ,list(rs_ERn$Census.Division,rs_ERn$change_wren_only),mean,na.rm=TRUE) 
tapply(rs_ERn$iren_redn_cum_tCO2 ,list(rs_ERn$Census.Division,rs_ERn$change_iren_only),mean,na.rm=TRUE) # NE and ENC have biggest impact
tapply(rs_ERn$cren_redn_cum_tCO2 ,list(rs_ERn$Census.Division,rs_ERn$change_cren_only),mean,na.rm=TRUE) # only real savings in ESC and WSC 
tapply(rs_ERn$hren_iren_redn_cum_tCO2 ,list(rs_ERn$Census.Division,rs_ERn$change_hren_iren),mean,na.rm=TRUE) # from 33 tCO2 in WSC to 130 tCO2 in NE, next highest is MitAtl

# avg by House Type
tapply(rs_ERn$hren_redn_cum_tCO2 ,list(rs_ERn$Geometry.Building.Type.RECS,rs_ERn$change_hren_only),mean,na.rm=TRUE) 
tapply(rs_ERn$hren_redn_cum_tCO2 ,list(rs_ERn$Geometry.Building.Type.ACS,rs_ERn$change_hren_only),mean,na.rm=TRUE) 
tapply(rs_ERn$wren_redn_cum_tCO2 ,list(rs_ERn$Geometry.Building.Type.RECS,rs_ERn$change_wren_only),mean,na.rm=TRUE) 
tapply(rs_ERn$iren_redn_cum_tCO2 ,list(rs_ERn$Geometry.Building.Type.RECS,rs_ERn$change_iren_only),mean,na.rm=TRUE) 
tapply(rs_ERn$cren_redn_cum_tCO2 ,list(rs_ERn$Geometry.Building.Type.RECS,rs_ERn$change_cren_only),mean,na.rm=TRUE) 
tapply(rs_ERn$hren_iren_redn_cum_tCO2 ,list(rs_ERn$Geometry.Building.Type.RECS,rs_ERn$change_hren_iren),mean,na.rm=TRUE)

# avg by Vintage
tapply(rs_ERn$hren_redn_cum_tCO2 ,list(rs_ERn$Vintage.ACS,rs_ERn$change_hren_only),mean,na.rm=TRUE) 
tapply(rs_ERn$wren_redn_cum_tCO2 ,list(rs_ERn$Vintage.ACS,rs_ERn$change_wren_only),mean,na.rm=TRUE) 
tapply(rs_ERn$iren_redn_cum_tCO2 ,list(rs_ERn$Vintage.ACS,rs_ERn$change_iren_only),mean,na.rm=TRUE) # unusual that 2010s houses have a large avg, but N is small, 1072 in this case
tapply(rs_ERn$cren_redn_cum_tCO2 ,list(rs_ERn$Vintage.ACS,rs_ERn$change_cren_only),mean,na.rm=TRUE) 
tapply(rs_ERn$hren_iren_redn_cum_tCO2 ,list(rs_ERn$Vintage.ACS,rs_ERn$change_hren_iren),mean,na.rm=TRUE) # 68t on average in <1940

# avg by House Size. 
tapply(rs_ERn$hren_redn_cum_tCO2 ,list(rs_ERn$Geometry.Floor.Area,rs_ERn$change_hren_only),mean,na.rm=TRUE) 
tapply(rs_ERn$wren_redn_cum_tCO2 ,list(rs_ERn$Geometry.Floor.Area,rs_ERn$change_wren_only),mean,na.rm=TRUE) 
tapply(rs_ERn$iren_redn_cum_tCO2 ,list(rs_ERn$Geometry.Floor.Area,rs_ERn$change_iren_only),mean,na.rm=TRUE) 
tapply(rs_ERn$cren_redn_cum_tCO2 ,list(rs_ERn$Geometry.Floor.Area,rs_ERn$change_cren_only),mean,na.rm=TRUE) 
tapply(rs_ERn$hren_iren_redn_cum_tCO2 ,list(rs_ERn$Geometry.Floor.Area,rs_ERn$change_hren_iren),mean,na.rm=TRUE) # 139 tCO2 on average in homes over 4000 ft2

# include climate zone in rs_ERn
rs_ERn<-merge(rs_ERn,cz)
rs_ERn<-rs_ERn[with(rs_ERn, order(Building,Year)),]

# save this modified dataframe
save(rs_ERn,file = "Intermediate_results/RenExtElec_EG.RData")

# calculate summary reductions of energy demand by renovation
heat_typ_reg_ar<-tapply(rs_ERn$redn_hren,list(rs_ERn$change_hren_only,rs_ERn$Geometry.Building.Type.RECS,rs_ERn$Census.Region), mean)[2,,] 
cool_typ_reg_ar<-tapply(rs_ERn$redn_cren,list(rs_ERn$change_cren_only,rs_ERn$Geometry.Building.Type.RECS,rs_ERn$Census.Region), mean)[2,,] 
dhw_typ_reg_ar<-tapply(rs_ERn$redn_wren,list(rs_ERn$change_wren_only,rs_ERn$Geometry.Building.Type.RECS,rs_ERn$Census.Region), mean)[2,,] 
ins_typ_reg_ar<-tapply(rs_ERn$redn_iren,list(rs_ERn$change_iren_only,rs_ERn$Geometry.Building.Type.RECS,rs_ERn$Census.Region), mean)[2,,] 

heat_age_reg_ar<-tapply(rs_ERn$redn_hren,list(rs_ERn$change_hren_only,rs_ERn$Vintage.ACS,rs_ERn$Census.Region), mean)[2,,] 
cool_age_reg_ar<-tapply(rs_ERn$redn_cren,list(rs_ERn$change_cren_only,rs_ERn$Vintage.ACS,rs_ERn$Census.Region), mean)[2,,] 
dhw_age_reg_ar<-tapply(rs_ERn$redn_wren,list(rs_ERn$change_wren_only,rs_ERn$Vintage.ACS,rs_ERn$Census.Region), mean)[2,,] 
ins_age_reg_ar<-tapply(rs_ERn$redn_iren,list(rs_ERn$change_iren_only,rs_ERn$Vintage.ACS,rs_ERn$Census.Region), mean)[2,,] 

heat_typ_age_ar<-tapply(rs_ERn$redn_hren,list(rs_ERn$change_hren_only,rs_ERn$Geometry.Building.Type.RECS,rs_ERn$Vintage.ACS), mean)[2,,] 
cool_typ_age_ar<-tapply(rs_ERn$redn_cren,list(rs_ERn$change_cren_only,rs_ERn$Geometry.Building.Type.RECS,rs_ERn$Vintage.ACS), mean)[2,,] 
dhw_typ_age_ar<-tapply(rs_ERn$redn_wren,list(rs_ERn$change_wren_only,rs_ERn$Geometry.Building.Type.RECS,rs_ERn$Vintage.ACS), mean)[2,,] 
ins_typ_age_ar<-tapply(rs_ERn$redn_iren,list(rs_ERn$change_iren_only,rs_ERn$Geometry.Building.Type.RECS,rs_ERn$Vintage.ACS), mean)[2,,] 

# save summary tables
save(heat_typ_reg_ar,heat_age_reg_ar,heat_typ_age_ar, cool_typ_reg_ar,cool_age_reg_ar,cool_typ_age_ar,dhw_typ_reg_ar,dhw_age_reg_ar,dhw_typ_age_ar,ins_typ_reg_ar,ins_age_reg_ar,ins_typ_age_ar,
     file = "Intermediate_results/ER_redn.RData")