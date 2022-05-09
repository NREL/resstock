# projection results combined with renovation results for all 12 HS stock scenarios
rm(list=ls()) # clear workspace i.e. remove saved variables
cat("\014") # clear console
library(dplyr)
library(reshape2)

# Last Update Peter Berrill May 6 2022

# Purpose: Merge energy and GHG results of renovated <2020 housing with energy and GHG results of new construction, for each scenario

# Inputs: - Eagle_outputs/res_2020_complete.csv, only used for column names
#         - Intermediate_results/agg_bscsv.RData, bcsv files describing housing characteristics of future cohorts in all stock/characteristics scenarios
#         - Intermediate_results/decayFactorsProj.RData, decay factors to model decay of housing stock by type, cohort, and county
#         - ExtData/ctycode.RData, county names and fips codes
#         - ExtData/GHGI_MidCase.RData, GHG intensity of electricityfor NREL mid-case scenario
#         - ExtData/GHGI_LowRECost.RData, GHG intensity of electricity for NREL low RE cost scenario
#         - ExtData/NewConEstimates.csv, outputs from housing stock model, total new construction summed over five year periods until 2060 for each housing stock sceanrio
#         - Eagle_outputs/Complete_results/res_base_final.RData, resstock (simulation) results for base stock/base new housing characteristics
#         - Intermediate_results/RenStandard_EG.RData, energy and GHG (EG) calculations for <2020 housing with the Regular Renovation scenario
#         - Intermediate_results/RenAdvanced_EG.RData, energy and GHG (EG) calculations for <2020 housing with the Advanced Renovation scenario
#         - Intermediate_results/RenExtElec_EG.RData, energy and GHG (EG) calculations for <2020 housing with the Extensive Renovation scenario
#         - Eagle_outputs/Complete_results/res_baseDE_final.RData, resstock (simulation) results for base stock & deep (intensive) electrification new housing characteristics
#         - Eagle_outputs/Complete_results/res_baseRFA_final.RData, resstock (simulation) results for base stock & reduced floor area new housing characteristics
#         - Eagle_outputs/Complete_results/res_baseDERFA_final.RData, resstock (simulation) results for base stock & deep (intensive) electrification, reduced floor area new housing characteristics
#         - Eagle_outputs/Complete_results/res_hiDR_final.RData, resstock (simulation) results for hiDR (hiTO) stock & base new housing characteristics
#         - Eagle_outputs/Complete_results/res_hiDRRFA_final.RData, resstock (simulation) results for hiDR (hiTO) stock & reduced floor area new housing characteristics
#         - Eagle_outputs/Complete_results/res_hiDRDE_final.RData, resstock (simulation) results for hiDR (hiTO) stock & deep (intensive) electrification new housing characteristics
#         - Eagle_outputs/Complete_results/res_hiDRDERFA_final.RData, resstock (simulation) results for hiDR (hiTO) stock & deep (intensive) electrification, reduced floor area new housing characteristics
#         - Eagle_outputs/Complete_results/res_hiMF_final.RData, resstock (simulation) results for hiMF stock & base new housing characteristics
#         - Eagle_outputs/Complete_results/res_hiMFRFA_final.RData, resstock (simulation) results for hiMF stock & reduced floor area new housing characteristics
#         - Eagle_outputs/Complete_results/res_hiMFDE_final.RData, resstock (simulation) results for hiMF stock & deep (intensive) electrification new housing characteristics
#         - Eagle_outputs/Complete_results/res_hiMFDERFA_final.RData, resstock (simulation) results for hiMF stock & deep (intensive) electrification, reduced floor area new housing characteristics


# Outputs: 
#         - Intermediate_results/rs_base_EG.RData, energy and GHG (EG) calculations for new housing, with base stock/base new housing characteristics
#         - Final_results/res_base_RR.RData, energy and GHG for entire (old and new) housing stock, with base stock/base new housing characteristics and regular renovation
#         - Final_results/res_base_AR.RData, energy and GHG for entire (old and new) housing stock, with base stock/base new housing characteristics and advanced renovation
#         - Final_results/res_base_ER.RData, energy and GHG for entire (old and new) housing stock, with base stock/base new housing characteristics and extensive renovation

#         - Intermediate_results/rs_baseDE_EG.RData, energy and GHG (EG) calculations for new housing, with base stock & deep (intensive) electrification new housing characteristics
#         - Final_results/res_baseDE_RR.RData, energy and GHG for entire (old and new) housing stock, with base stock & deep (intensive) electrification new housing characteristics
#         - Final_results/res_baseDE_AR.RData, energy and GHG for entire (old and new) housing stock, with base stock & deep (intensive) electrification new housing characteristics
#         - Final_results/res_baseDE_ER.RData, energy and GHG for entire (old and new) housing stock, with base stock & deep (intensive) electrification new housing characteristics

#         - Intermediate_results/rs_baseRFA_EG.RData, energy and GHG (EG) calculations for new housing, with base stock & reduced floor area new housing characteristics
#         - Final_results/res_baseRFA_RR.RData, energy and GHG for entire (old and new) housing stock, with base stock & reduced floor area new housing characteristics
#         - Final_results/res_baseRFA_AR.RData, energy and GHG for entire (old and new) housing stock, with base stock & reduced floor area new housing characteristics
#         - Final_results/res_baseRFA_ER.RData, energy and GHG for entire (old and new) housing stock, with base stock & reduced floor area new housing characteristics

#         - Intermediate_results/rs_baseDERFA_EG.RData, energy and GHG (EG) calculations for new housing, with base stock & deep (intensive) electrification, reduced floor area new housing characteristics
#         - Final_results/res_baseDERFA_RR.RData, energy and GHG for entire (old and new) housing stock, with base stock & deep (intensive) electrification, reduced floor area new housing characteristics
#         - Final_results/res_baseDERFA_AR.RData, energy and GHG for entire (old and new) housing stock, with base stock & deep (intensive) electrification, reduced floor area new housing characteristics
#         - Final_results/res_baseDERFA_ER.RData, energy and GHG for entire (old and new) housing stock, with base stock & deep (intensive) electrification, reduced floor area new housing characteristics

#         - Intermediate_results/rs_hiDR_EG.RData, energy and GHG (EG) calculations for new housing, with hiDR (hiTO) stock & base new housing characteristics
#         - Final_results/res_hiDR_RR.RData, energy and GHG for entire (old and new) housing stock, with hiDR (hiTO) stock & base new housing characteristics
#         - Final_results/res_hiDR_AR.RData, energy and GHG for entire (old and new) housing stock, with hiDR (hiTO) stock & base new housing characteristics
#         - Final_results/res_hiDR_ER.RData, energy and GHG for entire (old and new) housing stock, with hiDR (hiTO) stock & base new housing characteristics

#         - Intermediate_results/rs_hiDRRFA_EG.RData, energy and GHG (EG) calculations for new housing, with hiDR (hiTO) stock & reduced floor area new housing characteristics
#         - Final_results/res_hiDRRFA_RR.RData, energy and GHG for entire (old and new) housing stock, with hiDR (hiTO) stock & reduced floor area new housing characteristics
#         - Final_results/res_hiDRRFA_AR.RData, energy and GHG for entire (old and new) housing stock, with hiDR (hiTO) stock & reduced floor area new housing characteristics
#         - Final_results/res_hiDRRFA_ER.RData, energy and GHG for entire (old and new) housing stock, with hiDR (hiTO) stock & reduced floor area new housing characteristics

#         - Intermediate_results/rs_hiDRDE_EG.RData, energy and GHG (EG) calculations for new housing, with hiDR (hiTO) stock & deep (intensive) electrification new housing characteristics
#         - Final_results/res_hiDRDE_RR.RData, energy and GHG for entire (old and new) housing stock, with hiDR (hiTO) stock & deep (intensive) electrification new housing characteristics
#         - Final_results/res_hiDRDE_AR.RData, energy and GHG for entire (old and new) housing stock, with hiDR (hiTO) stock & deep (intensive) electrification new housing characteristics
#         - Final_results/res_hiDRDE_ER.RData, energy and GHG for entire (old and new) housing stock, with hiDR (hiTO) stock & deep (intensive) electrification new housing characteristics

#         - Intermediate_results/rs_hiDRDERFA_EG.RData, energy and GHG (EG) calculations for new housing, with hiDR (hiTO) stock & deep (intensive) electrification, reduced floor area new housing characteristics
#         - Final_results/res_hiDRDERFA_RR.RData, energy and GHG for entire (old and new) housing stock, with hiDR (hiTO) stock & deep (intensive) electrification, reduced floor area new housing characteristics
#         - Final_results/res_hiDRDERFA_AR.RData, energy and GHG for entire (old and new) housing stock, with hiDR (hiTO) stock & deep (intensive) electrification, reduced floor area new housing characteristics
#         - Final_results/res_hiDRDERFA_ER.RData, energy and GHG for entire (old and new) housing stock, with hiDR (hiTO) stock & deep (intensive) electrification, reduced floor area new housing characteristics

setwd("~/Yale Courses/Research/Final Paper/resstock_projections/results_scripts")

# import R modified bcsv files, these describe the characteristics of future cohorts in three stock scenarios (base, hiDR, hiMF) and 4 characteristics scenarios 'scen' (base, DE, RFA, DERFA)
load("../Intermediate_results/agg_bscsv.RData")

# other data needing loaded for all scenarios
load("../Intermediate_results/decayFactorsProj.RData") 

load("../ExtData/ctycode.RData") # from the HSM repo
load("../ExtData/GHGI_MidCase.RData") # Elec GHG int data in Mid-Case scenario
load("../ExtData/GHGI_LowRECost.RData") # Elec GHG int data in Low RE Cost Scenario
ctycode_num<-ctycode
ctycode_num$GeoID<-as.numeric(ctycode_num$GeoID)

# gicty_rto[gicty_rto$geoid10==46113,]$geoid10<-46102 # replace Shannon County SD with Oglala Lakota Cty
# gicty_rto[gicty_rto$geoid10==2270,]$geoid10<-2158 # replace Wade Hampton AK with Kusilvak AK
# gicty_rto<-merge(gicty_rto,ctycode_num,by.x="geoid10",by.y="GeoID") #
# 
# gicty_rto_yr<-gicty_rto[gicty_rto$Year %in% c(2020,2025,2030,2035,2040,2045,2050,2055,2060),] # get only the RS simulation years

gicty_gea[gicty_gea$geoid10==46113,]$geoid10<-46102 # replace Shannon County SD with Oglala Lakota Cty
gicty_gea[gicty_gea$geoid10==2270,]$geoid10<-2158 # replace Wade Hampton AK with Kusilvak AK
gicty_gea<-merge(gicty_gea,ctycode_num,by.x="geoid10",by.y="GeoID") #

gicty_gea_yr<-gicty_gea[gicty_gea$Year %in% c(2020,2025,2030,2035,2040,2045,2050,2055,2060),] # get only the RS simulation years

# decide here whether to use gea or rto GHG intensities
# RTO GHG intensities!
# gic<-dcast(gicty_rto_yr[,2:4],RS_ID ~ Year,value.var = "GHG_int")# decide here whether to use gea or rto GHG intensities

# GEA GHG intensities!
gic<-dcast(gicty_gea_yr[,2:4],RS_ID ~ Year,value.var = "GHG_int")# decide here whether to use gea or rto GHG intensities
names(gic)[2:8]<-paste("GHG_int",names(gic)[2:8],sep="_")
gic$GHG_int_2055<-0.95* gic$GHG_int_2050
gic$GHG_int_2060<-0.95* gic$GHG_int_2055
gic[,2:10]<-gic[,2:10]/3600 # convert from kg/MWh to kg/MJ

# # do the same process for the Low RE Cost electricity data
# gicty_rto_LREC[gicty_rto_LREC$geoid10==46113,]$geoid10<-46102 # replace Shannon County SD with Oglala Lakota Cty
# gicty_rto_LREC[gicty_rto_LREC$geoid10==2270,]$geoid10<-2158 # replace Wade Hampton AK with Kusilvak AK
# gicty_rto_LREC<-merge(gicty_rto_LREC,ctycode_num,by.x="geoid10",by.y="GeoID") #
# 
# gicty_rto_LREC_yr<-gicty_rto_LREC[gicty_rto_LREC$Year %in% c(2020,2025,2030,2035,2040,2045,2050,2055,2060),] # get only the RS simulation years

gicty_gea_LREC[gicty_gea_LREC$geoid10==46113,]$geoid10<-46102 # replace Shannon County SD with Oglala Lakota Cty
gicty_gea_LREC[gicty_gea_LREC$geoid10==2270,]$geoid10<-2158 # replace Wade Hampton AK with Kusilvak AK
gicty_gea_LREC<-merge(gicty_gea_LREC,ctycode_num,by.x="geoid10",by.y="GeoID") #

gicty_gea_LREC_yr<-gicty_gea_LREC[gicty_gea_LREC$Year %in% c(2020,2025,2030,2035,2040,2045,2050,2055,2060),] # get only the RS simulation years

# RTO GHG intensities!
# gic_LRE<-dcast(gicty_rto_LREC_yr[,2:4],RS_ID ~ Year,value.var = "GHG_int")

# GEA GHG intensities
gic_LRE<-dcast(gicty_gea_LREC_yr[,2:4],RS_ID ~ Year,value.var = "GHG_int")
names(gic_LRE)[2:8]<-paste("GHG_int",names(gic_LRE)[2:8],sep="_")
gic_LRE$GHG_int_2055<-0.93* gic_LRE$GHG_int_2050 # assume greater decreases in GHGI post-2050 in LREC
gic_LRE$GHG_int_2060<-0.9* gic_LRE$GHG_int_2055 # assume greater decreases in GHGI post-2050 in LREC
gic_LRE[,2:10]<-gic_LRE[,2:10]/3600 # convert from kg/MWh to kg/MJ
names(gic_LRE)[2:10]<-paste(names(gic_LRE)[2:10],"LRE",sep = "_")

# combustion fuel GHGI
GHGI_FO<-((.07396)+(25*3e-6)+(298*6e-7))/1.055  # intensity for heating oil (DFO #2) in kgCO2eq / MJ
GHGI_NG<-((0.05302)+(25*10e-6) + (298*1e-7))/1.055  # intensity for natural gas in kgCO2eq / MJ
GHGI_LP<-((.06298)+(25*3e-6)+(298*6e-7))/1.055   # intensity for LPG in kgCO2eq / MJ

# function
rmcol<-c(2:4,6:8,10,12,28:30,34:35,37:38,57:58,84:85,93:96,100:101,106,130,131,199)
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

# load in projection results, base ######
# 1 of 12 stock projection results: base stock, base NHC
print('base 1')
load("../Eagle_outputs/Complete_results/res_base_final.RData")
rsbase_base<-rsn
rm(rsn)

nce<-read.csv("../../HSM_github/HSM_results/NewConEstimates.csv")
nce<-nce[2:9,]
names(nce)<-c("Year","base","hiDR","hiMF","hiDRMF")
nce$Year<-seq(2025,2060,5)

load('../Intermediate_results/base_weights_NC.RData')

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
  bs_base_base[bs_base_base$Year==y,]$base_weight<-nce[nce$Year==y,]$base/15000 # there are 15,000 units in every 5 year period, hence the denomimator here. 
}

bs_base_base$Type3<-'MF'
bs_base_base[bs_base_base$Geometry.Building.Type.RECS=='Mobile Home',]$Type3<-'MH'
bs_base_base[bs_base_base$Geometry.Building.Type.RECS %in% c('Single-Family Detached','Single-Family Attached'),]$Type3<-'SF'

# add the STCY balanced weighting factors
names(stcy_comp_base)[c(2,4,8)]<-c('Vintage.ACS','Type3','base_weight_STCY')
bs_base_base<-merge(bs_base_base,stcy_comp_base[,c('Year','State','Type3','Vintage.ACS','base_weight_STCY')],by=c('Year','State','Type3','Vintage.ACS'))

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

bs_base_base<-left_join(bs_base_base,sbm,by="ctyTC")

# merge with the energy results
rsbb_sum<-result_sum(rsbase_base,0)
#View(names(rsbb_sum[,c(1:3,23,43,44,55:63,66,81,82,88,95,103,105:111,113:122,124:129,131,133,135:141,148:200)]))

rsbb_sum<-rsbb_sum[,c(1:3,23,43,44,55:63,66,81,82,88,95,103,105:111,113:122,124:129,131,133,135:141,148:200)] # bigger version

#all.equal(sort(unique(rsbb_sum$building_id)),sort(unique(bs_base_base$Building))) # check if its true
rs_base<-merge(bs_base_base,rsbb_sum,by.x = "Building",by.y = "building_id")
rs_base<-rs_base[,-c(which(names(rs_base) %in% c("Year.y", "Year_Building.y")))]
rs_base<-rs_base %>% rename(Year_Building = Year_Building.x, Year = Year.x)

# Here we add the GHG intensities
# add GHG intensities, Mid-Case
rs_base<-left_join(rs_base,gic,by = c("County" = "RS_ID"))
# add GHG intensities, Low RE Cost
rs_base<-left_join(rs_base,gic_LRE,by = c("County" = "RS_ID"))

rs_base[rs_base$Year==2030,]$wbase_2025<-0
rs_base[rs_base$Year==2040,]$wbase_2035<-0
rs_base[rs_base$Year==2050,]$wbase_2045<-0
rs_base[rs_base$Year==2060,]$wbase_2055<-0

# calculate total energy and emissions from future housing 
rs_base[,c("Tot_GJ_base_2020",  "Tot_GJ_base_2025","Tot_GJ_base_2030","Tot_GJ_base_2035","Tot_GJ_base_2040","Tot_GJ_base_2045","Tot_GJ_base_2050","Tot_GJ_base_2055","Tot_GJ_base_2060")]<-
  (rs_base$base_weight_STCY*rs_base[,c("wbase_2020", "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*
  (rs_base$Elec_GJ+rs_base$Gas_GJ+rs_base$Prop_GJ+rs_base$Oil_GJ)

# tot kgGHG per archetype group/year in kg
rs_base[,c("EnGHGkg_base_2020","EnGHGkg_base_2025","EnGHGkg_base_2030","EnGHGkg_base_2035","EnGHGkg_base_2040","EnGHGkg_base_2045","EnGHGkg_base_2050","EnGHGkg_base_2055","EnGHGkg_base_2060")]<-1000* 
  (rs_base$base_weight_STCY*rs_base[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*
  (rs_base$Elec_GJ*rs_base[,c("GHG_int_2020", "GHG_int_2025","GHG_int_2030","GHG_int_2035","GHG_int_2040","GHG_int_2045","GHG_int_2050","GHG_int_2055","GHG_int_2060")]+
     matrix(rep(rs_base$Gas_GJ*GHGI_NG,9),nrow(rs_base),9)+ matrix(rep(rs_base$Oil_GJ*GHGI_FO,9),nrow(rs_base),9)+ matrix(rep(rs_base$Prop_GJ*GHGI_LP,9),nrow(rs_base),9))

# tot LRE kgGHG per archetype group/year in kg
rs_base[,c("EnGHGkg_base_2020_LRE","EnGHGkg_base_2025_LRE","EnGHGkg_base_2030_LRE","EnGHGkg_base_2035_LRE","EnGHGkg_base_2040_LRE","EnGHGkg_base_2045_LRE","EnGHGkg_base_2050_LRE","EnGHGkg_base_2055_LRE","EnGHGkg_base_2060_LRE")]<-1000* 
  (rs_base$base_weight_STCY*rs_base[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*
  (rs_base$Elec_GJ*rs_base[,c("GHG_int_2020_LRE", "GHG_int_2025_LRE","GHG_int_2030_LRE","GHG_int_2035_LRE","GHG_int_2040_LRE","GHG_int_2045_LRE","GHG_int_2050_LRE","GHG_int_2055_LRE","GHG_int_2060_LRE")]+
     matrix(rep(rs_base$Gas_GJ*GHGI_NG,9),nrow(rs_base),9)+ matrix(rep(rs_base$Oil_GJ*GHGI_FO,9),nrow(rs_base),9)+ matrix(rep(rs_base$Prop_GJ*GHGI_LP,9),nrow(rs_base),9))


save(rs_base,file="../Intermediate_results/rs_base_EG.RData")
# load("../Intermediate_results/rs_base_EG.RData")
# now merge with the AR/RR files
load("../Intermediate_results/RenStandard_EG.RData") #

n1<-names(rs_RRn) # <2020 stock, Reg Ren
n2<-names(rs_base) # new construction

# before binding rows, make the Building codes in rs_base distinct from those in rs_RRn
rs_base$Building<-180000+rs_base$Building
rs_base$Year_Building<-paste(rs_base$Year,rs_base$Building,sep="_")

# check the GHG ints in the two files
G1<-unique(rs_RRn[,c('County','GHG_int_2020')])
names(G1)[2]<-'GHG_int_2020_ex'
G2<-unique(rs_base[,c('County','GHG_int_2020')])
names(G2)[2]<-'GHG_int_2020_nc'
G3<-merge(G2,G1)
all(G3$GHG_int_2020_nc==G3$GHG_int_2020_ex) # they are all the same

rs_base_all_RR<-bind_rows(rs_RRn,rs_base) #  make sure base_weight_STCY is added

# fix the NAs in earlier base_weight_STCY
rs_base_all_RR<-rs_base_all_RR[,names(rs_base_all_RR) %in% names(rs_base)]
rs_base_all_RR[is.na(rs_base_all_RR$base_weight_STCY), ]$base_weight_STCY<-0
rs_base_all_RR[rs_base_all_RR$base_weight_STCY==0,]$base_weight_STCY<-rs_base_all_RR[rs_base_all_RR$base_weight_STCY==0,]$base_weight_STCY+rs_base_all_RR[rs_base_all_RR$base_weight_STCY==0,]$base_weight

rs_base_all_RR$Type3<-'MF'
rs_base_all_RR[rs_base_all_RR$Geometry.Building.Type.RECS=='Mobile Home',]$Type3<-'MH'
rs_base_all_RR[rs_base_all_RR$Geometry.Building.Type.RECS %in% c('Single-Family Detached','Single-Family Attached'),]$Type3<-'SF'

# let's see how they compare at a higher resolution, such as state or county, then i need esimates of totalstock in future years by type, year, county.
# make function

comp_ests<-function(df,yr,geo,wf,stock) {
  dfc<-as.data.frame(round(tapply(df$base_weight*df[,wf],list(df[,geo],df$Type3),sum)))
  dfc[,geo]<-rownames(dfc)
  dfc<-melt(dfc)
  dfc$Year<-yr
  names(dfc)[2:3]<-c('Type3','UnitCount0')
  dfc<-dfc[,c(4,1:3)]
  
  dfcs<-as.data.frame(round(tapply(df$base_weight_STCY*df[,wf],list(df[,geo],df$Type3),sum)))
  dfcs[,geo]<-rownames(dfcs)
  dfcs<-melt(dfcs)
  dfcs$Year<-yr
  names(dfcs)[2:3]<-c('Type3','UnitCount_STCY')
  dfc<-merge(dfc,dfcs)
  
  # if (geo=='State') {dfc<-merge(dfc,stock_tsy_base)}
  # if (geo=='County') {dfc<-merge(dfc,stock_tcy_base)}
  dfc<-merge(dfc,stock)
  
  
  dfc$comp_est<-round(dfc$UnitCount_STCY/dfc$UnitCount0,2)
  
  dfc$comp0<-round(dfc$UnitCount0/dfc$UnitCount,2)
  dfc$compSTCY<-round(dfc$UnitCount_STCY/dfc$UnitCount,2)
  
  dfc
}

# I currently lean towards using the STCY version, but the deciding factor will be whether the STCY weights produce more consistent estiamtes b/w base and hiDR stock scenarios
st40<-comp_ests(rs_base_all_RR,2040,'State','wbase_2040',stock_tsy_base)
st60<-comp_ests(rs_base_all_RR,2060,'State','wbase_2060',stock_tsy_base)

cty50<-comp_ests(rs_base_all_RR,2050,'County','wbase_2050',stock_tcy_base)
st50<-comp_ests(rs_base_all_RR,2050,'State','wbase_2050',stock_tsy_base)


# example of calculating national level emissions in each year , except without construction related emissions
colSums(rs_base_all_RR[,176:184])*1e-9 # 
# example of calculating national level emissions in each year , LRE elec
colSums(rs_base_all_RR[,185:193])*1e-9 # 

save(rs_base_all_RR,file="../Final_results/res_base_RR.RData")
rm(rs_base_all_RR)
# now Advanced Renovation
load("../Intermediate_results/RenAdvanced_EG.RData")

n1<-names(rs_ARn) # <2020 stock, Adv Ren
n2<-names(rs_base) # new construction

# check the GHG ints in the two files
G1<-unique(rs_ARn[,c('County','GHG_int_2020')])
names(G1)[2]<-'GHG_int_2020_ex'
G2<-unique(rs_base[,c('County','GHG_int_2020')])
names(G2)[2]<-'GHG_int_2020_nc'
G3<-merge(G2,G1)
print(all(G3$GHG_int_2020_nc==G3$GHG_int_2020_ex))

rs_base_all_AR<-bind_rows(rs_ARn,rs_base)

rs_base_all_AR<-rs_base_all_AR[,names(rs_base_all_AR) %in% names(rs_base)]

rs_base_all_AR[is.na(rs_base_all_AR$base_weight_STCY), ]$base_weight_STCY<-0
rs_base_all_AR[rs_base_all_AR$base_weight_STCY==0,]$base_weight_STCY<-rs_base_all_AR[rs_base_all_AR$base_weight_STCY==0,]$base_weight_STCY+rs_base_all_AR[rs_base_all_AR$base_weight_STCY==0,]$base_weight

# example of calculating national level emissions in each year , except without construction related emissions
colSums(rs_base_all_AR[,176:184])*1e-9 # 
# example of calculating national level emissions in each year , LREC
colSums(rs_base_all_AR[,185:193])*1e-9 # 

save(rs_base_all_AR,file="../Final_results/res_base_AR.RData")
rm(rs_base_all_AR)
# now Extensive Renovation
load("../Intermediate_results/RenExtElec_EG.RData")

n1<-names(rs_ERn) # <2020 stock, Ext Ren
n2<-names(rs_base) # new construction

# check the GHG ints in the two files
G1<-unique(rs_ERn[,c('County','GHG_int_2020')])
names(G1)[2]<-'GHG_int_2020_ex'
G2<-unique(rs_base[,c('County','GHG_int_2020')])
names(G2)[2]<-'GHG_int_2020_nc'
G3<-merge(G2,G1)
print(all(G3$GHG_int_2020_nc==G3$GHG_int_2020_ex))

rs_base_all_ER<-bind_rows(rs_ERn,rs_base)

rs_base_all_ER<-rs_base_all_ER[,names(rs_base_all_ER) %in% names(rs_base)]

rs_base_all_ER[is.na(rs_base_all_ER$base_weight_STCY), ]$base_weight_STCY<-0
rs_base_all_ER[rs_base_all_ER$base_weight_STCY==0,]$base_weight_STCY<-rs_base_all_ER[rs_base_all_ER$base_weight_STCY==0,]$base_weight_STCY+rs_base_all_ER[rs_base_all_ER$base_weight_STCY==0,]$base_weight

# example of calculating national level emissions in each year , except without construction related emissions
colSums(rs_base_all_ER[,176:184])*1e-9 # 
# example of calculating national level emissions in each year , LREC
colSums(rs_base_all_ER[,185:193])*1e-9 # 

save(rs_base_all_ER,file="../Final_results/res_base_ER.RData")
rm(rs_base_all_ER)
rm(rs_base)
rm(rsbase_base)
# load in projection results, base DE ######
# 2 of 12 stock projection results: base stock, DE NHC
print('base 2')
load("../Eagle_outputs/Complete_results/res_baseDE_final.RData")
rsbase_DE<-rsn
rm(rsn)

bs_base_DE<-bs_base_all[bs_base_all$scen=="baseDE",]
bs_base_DE$Year<-bs_base_DE$sim_year

bs_base_DE$Year_Building<-paste(bs_base_DE$Year,bs_base_DE$Building,sep="_")

bs_base_DE<-bs_base_DE[,c("Year_Building","Year", "Building","County","State","Location.Region","Census.Division", "Census.Region", "ASHRAE.IECC.Climate.Zone.2004", "PUMA", "ISO.RTO.Region", "Geometry.Building.Type.ACS","Geometry.Building.Type.RECS",
                              "Vintage","Vintage.ACS","Heating.Fuel","Geometry.Floor.Area","Geometry.Foundation.Type","Geometry.Wall.Type","Geometry.Stories","Geometry.Garage",
                              "HVAC.Heating.Type.And.Fuel","HVAC.Heating.Efficiency","HVAC.Cooling.Type","HVAC.Cooling.Efficiency","Water.Heater.Fuel","Water.Heater.Efficiency",
                              "Clothes.Dryer","Infiltration")] # currently comes to 29 columns, without "change_cren","change_iren","change_wren","change_hren", "base_weight". Add these in for consistency
bs_base_DE[,c("change_cren","change_iren","change_wren","change_hren")]<-0

bs_base_DE$base_weight<-0
# add base weights for each sim year, based on the new construction estimates
for (y in seq(2025,2060,5)) {
  bs_base_DE[bs_base_DE$Year==y,]$base_weight<-nce[nce$Year==y,]$base/15000
}

bs_base_DE$Type3<-'MF'
bs_base_DE[bs_base_DE$Geometry.Building.Type.RECS=='Mobile Home',]$Type3<-'MH'
bs_base_DE[bs_base_DE$Geometry.Building.Type.RECS %in% c('Single-Family Detached','Single-Family Attached'),]$Type3<-'SF'

names(stcy_comp_base)[c(2,4,8)]<-c('Vintage.ACS','Type3','base_weight_STCY')
bs_base_DE<-merge(bs_base_DE,stcy_comp_base[,c('Year','State','Type3','Vintage.ACS','base_weight_STCY')],by=c('Year','State','Type3','Vintage.ACS'))

bs_base_DE$TC<-"MF"
bs_base_DE[bs_base_DE$Geometry.Building.Type.RECS=="Single-Family Attached" | bs_base_DE$Geometry.Building.Type.RECS=="Single-Family Detached",]$TC<-"SF"
bs_base_DE[bs_base_DE$Geometry.Building.Type.RECS=="Mobile Home",]$TC<-"MH"
bs_base_DE$TC<-paste(bs_base_DE$TC,bs_base_DE$Vintage.ACS,sep="_")
bs_base_DE$ctyTC<-paste(bs_base_DE$County,bs_base_DE$TC,sep = "")
bs_base_DE$ctyTC<-gsub("2010s","2010-19",bs_base_DE$ctyTC)
bs_base_DE$ctyTC<-gsub("2020s","2020-29",bs_base_DE$ctyTC)
bs_base_DE$ctyTC<-gsub("2030s","2030-39",bs_base_DE$ctyTC)
bs_base_DE$ctyTC<-gsub("2040s","2040-49",bs_base_DE$ctyTC)
bs_base_DE$ctyTC<-gsub("2050s","2050-60",bs_base_DE$ctyTC)

bs_base_DE<-left_join(bs_base_DE,sbm,by="ctyTC")

# merge with the energy results
rsbDE_sum<-result_sum(rsbase_DE,0)
rsbDE_sum<-rsbDE_sum[,c(1:3,23,43,44,55:63,66,81,82,88,95,103,105:111,113:122,124:129,131,133,135:141,148:200)] # bigger version

rs_baseDE<-merge(bs_base_DE,rsbDE_sum,by.x = "Building",by.y = "building_id")
rs_baseDE<-rs_baseDE[,-c(which(names(rs_baseDE) %in% c("Year.y", "Year_Building.y")))]
rs_baseDE<-rs_baseDE %>% rename(Year_Building = Year_Building.x, Year = Year.x)

# add GHG intensities, Mid-Case
rs_baseDE<-left_join(rs_baseDE,gic,by = c("County" = "RS_ID"))
# add GHG intensities, Low RE Cost
rs_baseDE<-left_join(rs_baseDE,gic_LRE,by = c("County" = "RS_ID"))

rs_baseDE[rs_baseDE$Year==2030,]$wbase_2025<-0
rs_baseDE[rs_baseDE$Year==2040,]$wbase_2035<-0
rs_baseDE[rs_baseDE$Year==2050,]$wbase_2045<-0
rs_baseDE[rs_baseDE$Year==2060,]$wbase_2055<-0
# here change the base weights to the preferred geographic option
rs_baseDE[,c("Tot_GJ_base_2020",  "Tot_GJ_base_2025","Tot_GJ_base_2030","Tot_GJ_base_2035","Tot_GJ_base_2040","Tot_GJ_base_2045","Tot_GJ_base_2050","Tot_GJ_base_2055","Tot_GJ_base_2060")]<-
  (rs_baseDE$base_weight_STCY*rs_baseDE[,c("wbase_2020", "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*
  (rs_baseDE$Elec_GJ+rs_baseDE$Gas_GJ+rs_baseDE$Prop_GJ+rs_baseDE$Oil_GJ)

# tot kgGHG per archetype group/year in kg
rs_baseDE[,c("EnGHGkg_base_2020","EnGHGkg_base_2025","EnGHGkg_base_2030","EnGHGkg_base_2035","EnGHGkg_base_2040","EnGHGkg_base_2045","EnGHGkg_base_2050","EnGHGkg_base_2055","EnGHGkg_base_2060")]<-1000* 
  (rs_baseDE$base_weight_STCY*rs_baseDE[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*
  (rs_baseDE$Elec_GJ*rs_baseDE[,c("GHG_int_2020", "GHG_int_2025","GHG_int_2030","GHG_int_2035","GHG_int_2040","GHG_int_2045","GHG_int_2050","GHG_int_2055","GHG_int_2060")]+
     matrix(rep(rs_baseDE$Gas_GJ*GHGI_NG,9),nrow(rs_baseDE),9)+ matrix(rep(rs_baseDE$Oil_GJ*GHGI_FO,9),nrow(rs_baseDE),9)+ matrix(rep(rs_baseDE$Prop_GJ*GHGI_LP,9),nrow(rs_baseDE),9))

# tot LRE kgGHG per archetype group/year in kg
rs_baseDE[,c("EnGHGkg_base_2020_LRE","EnGHGkg_base_2025_LRE","EnGHGkg_base_2030_LRE","EnGHGkg_base_2035_LRE","EnGHGkg_base_2040_LRE","EnGHGkg_base_2045_LRE","EnGHGkg_base_2050_LRE","EnGHGkg_base_2055_LRE","EnGHGkg_base_2060_LRE")]<-1000* 
  (rs_baseDE$base_weight_STCY*rs_baseDE[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*
  (rs_baseDE$Elec_GJ*rs_baseDE[,c("GHG_int_2020_LRE", "GHG_int_2025_LRE","GHG_int_2030_LRE","GHG_int_2035_LRE","GHG_int_2040_LRE","GHG_int_2045_LRE","GHG_int_2050_LRE","GHG_int_2055_LRE","GHG_int_2060_LRE")]+
     matrix(rep(rs_baseDE$Gas_GJ*GHGI_NG,9),nrow(rs_baseDE),9)+ matrix(rep(rs_baseDE$Oil_GJ*GHGI_FO,9),nrow(rs_baseDE),9)+ matrix(rep(rs_baseDE$Prop_GJ*GHGI_LP,9),nrow(rs_baseDE),9))

save(rs_baseDE,file="../Intermediate_results/rs_baseDE_EG.RData")

# now merge with the AR/RR files
n1<-names(rs_RRn) # <2020 stock, Reg Ren
n2<-names(rs_baseDE) # new construction

# check the GHG ints in the two files
G1<-unique(rs_RRn[,c('County','GHG_int_2020')])
names(G1)[2]<-'GHG_int_2020_ex'
G2<-unique(rs_baseDE[,c('County','GHG_int_2020')])
names(G2)[2]<-'GHG_int_2020_nc'
G3<-merge(G2,G1)
print(all(G3$GHG_int_2020_nc==G3$GHG_int_2020_ex))

# before binding rows, make the Building codes in rs_baseDE distinct from those in rs_RRn
rs_baseDE$Building<-180000+rs_baseDE$Building
rs_baseDE$Year_Building<-paste(rs_baseDE$Year,rs_baseDE$Building,sep="_")

rs_baseDE_all_RR<-bind_rows(rs_RRn,rs_baseDE)

rs_baseDE_all_RR<-rs_baseDE_all_RR[,names(rs_baseDE_all_RR) %in% names(rs_baseDE)]

rs_baseDE_all_RR[is.na(rs_baseDE_all_RR$base_weight_STCY), ]$base_weight_STCY<-0 # this can be a little slow/sticky
rs_baseDE_all_RR[rs_baseDE_all_RR$base_weight_STCY==0,]$base_weight_STCY<-rs_baseDE_all_RR[rs_baseDE_all_RR$base_weight_STCY==0,]$base_weight_STCY+rs_baseDE_all_RR[rs_baseDE_all_RR$base_weight_STCY==0,]$base_weight

# example of calculating national level emissions in each year , except without construction related emissions
colSums(rs_baseDE_all_RR[,176:184])*1e-9 # 
# example of calculating national level emissions in each year , LRE elec
colSums(rs_baseDE_all_RR[,185:193])*1e-9 #

save(rs_baseDE_all_RR,file="../Final_results/res_baseDE_RR.RData")
rm(rs_baseDE_all_RR)

# now advanced renovation
n1<-names(rs_ARn) # <2020 stock, Adv Ren
n2<-names(rs_baseDE) # new construction

# check the GHG ints in the two files
G1<-unique(rs_ARn[,c('County','GHG_int_2020')])
names(G1)[2]<-'GHG_int_2020_ex'
G2<-unique(rs_baseDE[,c('County','GHG_int_2020')])
names(G2)[2]<-'GHG_int_2020_nc'
G3<-merge(G2,G1)
print(all(G3$GHG_int_2020_nc==G3$GHG_int_2020_ex))

rs_baseDE_all_AR<-bind_rows(rs_ARn,rs_baseDE)

rs_baseDE_all_AR<-rs_baseDE_all_AR[,names(rs_baseDE_all_AR) %in% names(rs_baseDE)]

rs_baseDE_all_AR[is.na(rs_baseDE_all_AR$base_weight_STCY), ]$base_weight_STCY<-0 # this can be a little slow/sticky
rs_baseDE_all_AR[rs_baseDE_all_AR$base_weight_STCY==0,]$base_weight_STCY<-rs_baseDE_all_AR[rs_baseDE_all_AR$base_weight_STCY==0,]$base_weight_STCY+rs_baseDE_all_AR[rs_baseDE_all_AR$base_weight_STCY==0,]$base_weight

# example of calculating national level emissions in each year , except without construction related emissions
colSums(rs_baseDE_all_AR[,176:184])*1e-9 # 
# example of calculating national level emissions in each year , LREC
colSums(rs_baseDE_all_AR[,185:193])*1e-9 #

save(rs_baseDE_all_AR,file="../Final_results/res_baseDE_AR.RData")
rm(rs_baseDE_all_AR)
# now ext renovation
n1<-names(rs_ERn) # <2020 stock, Adv Ren
n2<-names(rs_baseDE) # new construction

# check the GHG ints in the two files
G1<-unique(rs_ERn[,c('County','GHG_int_2020')])
names(G1)[2]<-'GHG_int_2020_ex'
G2<-unique(rs_baseDE[,c('County','GHG_int_2020')])
names(G2)[2]<-'GHG_int_2020_nc'
G3<-merge(G2,G1)
print(all(G3$GHG_int_2020_nc==G3$GHG_int_2020_ex))

rs_baseDE_all_ER<-bind_rows(rs_ERn,rs_baseDE)

rs_baseDE_all_ER<-rs_baseDE_all_ER[,names(rs_baseDE_all_ER) %in% names(rs_baseDE)]

rs_baseDE_all_ER[is.na(rs_baseDE_all_ER$base_weight_STCY), ]$base_weight_STCY<-0 # this can be a little slow/sticky
rs_baseDE_all_ER[rs_baseDE_all_ER$base_weight_STCY==0,]$base_weight_STCY<-rs_baseDE_all_ER[rs_baseDE_all_ER$base_weight_STCY==0,]$base_weight_STCY+rs_baseDE_all_ER[rs_baseDE_all_ER$base_weight_STCY==0,]$base_weight

# example of calculating national level emissions in each year , except without construction related emissions
colSums(rs_baseDE_all_ER[,176:184])*1e-9 # 
# example of calculating national level emissions in each year , LREC
colSums(rs_baseDE_all_ER[,185:193])*1e-9 # 

save(rs_baseDE_all_ER,file="../Final_results/res_baseDE_ER.RData")
rm(rs_baseDE_all_ER)
rm(rs_baseDE)
rm(rsbase_DE)
# load in projection results, base RFA ######
# 3 of 12 stock projection results: base stock, RFA NHC
print('base 3')
load("../Eagle_outputs/Complete_results/res_baseRFA_final.RData")
rsbase_RFA<-rsn
rm(rsn)

bs_base_RFA<-bs_base_all[bs_base_all$scen=="baseRFA",]
bs_base_RFA$Year<-bs_base_RFA$sim_year

bs_base_RFA$Year_Building<-paste(bs_base_RFA$Year,bs_base_RFA$Building,sep="_")

bs_base_RFA<-bs_base_RFA[,c("Year_Building","Year", "Building","County","State","Location.Region","Census.Division", "Census.Region", "ASHRAE.IECC.Climate.Zone.2004", "PUMA", "ISO.RTO.Region", "Geometry.Building.Type.ACS","Geometry.Building.Type.RECS",
                          "Vintage","Vintage.ACS","Heating.Fuel","Geometry.Floor.Area","Geometry.Foundation.Type","Geometry.Wall.Type","Geometry.Stories","Geometry.Garage",
                          "HVAC.Heating.Type.And.Fuel","HVAC.Heating.Efficiency","HVAC.Cooling.Type","HVAC.Cooling.Efficiency","Water.Heater.Fuel","Water.Heater.Efficiency",
                          "Clothes.Dryer","Infiltration")] # currently comes to 29 columns, without "change_cren","change_iren","change_wren","change_hren", "base_weight". Add these in for consistency
bs_base_RFA[,c("change_cren","change_iren","change_wren","change_hren")]<-0

bs_base_RFA$base_weight<-0
# add base weights for each sim year, based on the new construction estimates
for (y in seq(2025,2060,5)) {
  bs_base_RFA[bs_base_RFA$Year==y,]$base_weight<-nce[nce$Year==y,]$base/15000
}

bs_base_RFA$Type3<-'MF'
bs_base_RFA[bs_base_RFA$Geometry.Building.Type.RECS=='Mobile Home',]$Type3<-'MH'
bs_base_RFA[bs_base_RFA$Geometry.Building.Type.RECS %in% c('Single-Family Detached','Single-Family Attached'),]$Type3<-'SF'

names(stcy_comp_base)[c(2,4,8)]<-c('Vintage.ACS','Type3','base_weight_STCY')
bs_base_RFA<-merge(bs_base_RFA,stcy_comp_base[,c('Year','State','Type3','Vintage.ACS','base_weight_STCY')],by=c('Year','State','Type3','Vintage.ACS'))

bs_base_RFA$TC<-"MF"
bs_base_RFA[bs_base_RFA$Geometry.Building.Type.RECS=="Single-Family Attached" | bs_base_RFA$Geometry.Building.Type.RECS=="Single-Family Detached",]$TC<-"SF"
bs_base_RFA[bs_base_RFA$Geometry.Building.Type.RECS=="Mobile Home",]$TC<-"MH"
bs_base_RFA$TC<-paste(bs_base_RFA$TC,bs_base_RFA$Vintage.ACS,sep="_")
bs_base_RFA$ctyTC<-paste(bs_base_RFA$County,bs_base_RFA$TC,sep = "")
bs_base_RFA$ctyTC<-gsub("2010s","2010-19",bs_base_RFA$ctyTC)
bs_base_RFA$ctyTC<-gsub("2020s","2020-29",bs_base_RFA$ctyTC)
bs_base_RFA$ctyTC<-gsub("2030s","2030-39",bs_base_RFA$ctyTC)
bs_base_RFA$ctyTC<-gsub("2040s","2040-49",bs_base_RFA$ctyTC)
bs_base_RFA$ctyTC<-gsub("2050s","2050-60",bs_base_RFA$ctyTC)

bs_base_RFA<-left_join(bs_base_RFA,sbm,by="ctyTC")

# merge with the energy results
rsbRFA_sum<-result_sum(rsbase_RFA,0)
rsbRFA_sum<-rsbRFA_sum[,c(1:3,23,43,44,55:63,66,81,82,88,95,103,105:111,113:122,124:129,131,133,135:141,148:200)] # bigger version


rs_baseRFA<-merge(bs_base_RFA,rsbRFA_sum,by.x = "Building",by.y = "building_id")
rs_baseRFA<-rs_baseRFA[,-c(which(names(rs_baseRFA) %in% c("Year.y", "Year_Building.y")))]
rs_baseRFA<-rs_baseRFA %>% rename(Year_Building = Year_Building.x, Year = Year.x)

# add GHG intensities, Mid-Case
rs_baseRFA<-left_join(rs_baseRFA,gic,by = c("County" = "RS_ID"))
# add GHG intensities, Low RE Cost
rs_baseRFA<-left_join(rs_baseRFA,gic_LRE,by = c("County" = "RS_ID"))

rs_baseRFA[rs_baseRFA$Year==2030,]$wbase_2025<-0
rs_baseRFA[rs_baseRFA$Year==2040,]$wbase_2035<-0
rs_baseRFA[rs_baseRFA$Year==2050,]$wbase_2045<-0
rs_baseRFA[rs_baseRFA$Year==2060,]$wbase_2055<-0

rs_baseRFA[,c("Tot_GJ_base_2020",  "Tot_GJ_base_2025","Tot_GJ_base_2030","Tot_GJ_base_2035","Tot_GJ_base_2040","Tot_GJ_base_2045","Tot_GJ_base_2050","Tot_GJ_base_2055","Tot_GJ_base_2060")]<-
  (rs_baseRFA$base_weight_STCY*rs_baseRFA[,c("wbase_2020", "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*
  (rs_baseRFA$Elec_GJ+rs_baseRFA$Gas_GJ+rs_baseRFA$Prop_GJ+rs_baseRFA$Oil_GJ)

# tot kgGHG per archetype group/year in kg
rs_baseRFA[,c("EnGHGkg_base_2020","EnGHGkg_base_2025","EnGHGkg_base_2030","EnGHGkg_base_2035","EnGHGkg_base_2040","EnGHGkg_base_2045","EnGHGkg_base_2050","EnGHGkg_base_2055","EnGHGkg_base_2060")]<-1000* 
  (rs_baseRFA$base_weight_STCY*rs_baseRFA[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*
  (rs_baseRFA$Elec_GJ*rs_baseRFA[,c("GHG_int_2020", "GHG_int_2025","GHG_int_2030","GHG_int_2035","GHG_int_2040","GHG_int_2045","GHG_int_2050","GHG_int_2055","GHG_int_2060")]+
     matrix(rep(rs_baseRFA$Gas_GJ*GHGI_NG,9),nrow(rs_baseRFA),9)+ matrix(rep(rs_baseRFA$Oil_GJ*GHGI_FO,9),nrow(rs_baseRFA),9)+ matrix(rep(rs_baseRFA$Prop_GJ*GHGI_LP,9),nrow(rs_baseRFA),9))

# tot LRE kgGHG per archetype group/year in kg
rs_baseRFA[,c("EnGHGkg_base_2020_LRE","EnGHGkg_base_2025_LRE","EnGHGkg_base_2030_LRE","EnGHGkg_base_2035_LRE","EnGHGkg_base_2040_LRE","EnGHGkg_base_2045_LRE","EnGHGkg_base_2050_LRE","EnGHGkg_base_2055_LRE","EnGHGkg_base_2060_LRE")]<-1000* 
  (rs_baseRFA$base_weight_STCY*rs_baseRFA[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*
  (rs_baseRFA$Elec_GJ*rs_baseRFA[,c("GHG_int_2020_LRE", "GHG_int_2025_LRE","GHG_int_2030_LRE","GHG_int_2035_LRE","GHG_int_2040_LRE","GHG_int_2045_LRE","GHG_int_2050_LRE","GHG_int_2055_LRE","GHG_int_2060_LRE")]+
     matrix(rep(rs_baseRFA$Gas_GJ*GHGI_NG,9),nrow(rs_baseRFA),9)+ matrix(rep(rs_baseRFA$Oil_GJ*GHGI_FO,9),nrow(rs_baseRFA),9)+ matrix(rep(rs_baseRFA$Prop_GJ*GHGI_LP,9),nrow(rs_baseRFA),9))


save(rs_baseRFA,file="../Intermediate_results/rs_baseRFA_EG.RData")

# now merge with the AR/RR files
n1<-names(rs_RRn) # <2020 stock, Reg Ren
n2<-names(rs_baseRFA) # new construction

# check the GHG ints in the two files
G1<-unique(rs_RRn[,c('County','GHG_int_2020')])
names(G1)[2]<-'GHG_int_2020_ex'
G2<-unique(rs_baseRFA[,c('County','GHG_int_2020')])
names(G2)[2]<-'GHG_int_2020_nc'
G3<-merge(G2,G1)
print(all(G3$GHG_int_2020_nc==G3$GHG_int_2020_ex))

# before binding rows, make the Building codes in rs_baseRFA distinct from those in rs_RRn
rs_baseRFA$Building<-180000+rs_baseRFA$Building
rs_baseRFA$Year_Building<-paste(rs_baseRFA$Year,rs_baseRFA$Building,sep="_")

rs_baseRFA_all_RR<-bind_rows(rs_RRn,rs_baseRFA)

rs_baseRFA_all_RR<-rs_baseRFA_all_RR[,names(rs_baseRFA_all_RR) %in% names(rs_baseRFA)]

rs_baseRFA_all_RR[is.na(rs_baseRFA_all_RR$base_weight_STCY), ]$base_weight_STCY<-0 # this can be a little slow/sticky
rs_baseRFA_all_RR[rs_baseRFA_all_RR$base_weight_STCY==0,]$base_weight_STCY<-rs_baseRFA_all_RR[rs_baseRFA_all_RR$base_weight_STCY==0,]$base_weight_STCY+rs_baseRFA_all_RR[rs_baseRFA_all_RR$base_weight_STCY==0,]$base_weight

# example of calculating national level emissions in each year , except without construction related emissions
colSums(rs_baseRFA_all_RR[,176:184])*1e-9 # 
# example of calculating national level emissions in each year , LRE elec
colSums(rs_baseRFA_all_RR[,185:193])*1e-9 # 

save(rs_baseRFA_all_RR,file="../Final_results/res_baseRFA_RR.RData")
rm(rs_baseRFA_all_RR)
# now advanced renovation
n1<-names(rs_ARn) # <2020 stock, Adv Ren
n2<-names(rs_baseRFA) # new construction

# check the GHG ints in the two files
G1<-unique(rs_ARn[,c('County','GHG_int_2020')])
names(G1)[2]<-'GHG_int_2020_ex'
G2<-unique(rs_baseRFA[,c('County','GHG_int_2020')])
names(G2)[2]<-'GHG_int_2020_nc'
G3<-merge(G2,G1)
print(all(G3$GHG_int_2020_nc==G3$GHG_int_2020_ex))

rs_baseRFA_all_AR<-bind_rows(rs_ARn,rs_baseRFA)

rs_baseRFA_all_AR<-rs_baseRFA_all_AR[,names(rs_baseRFA_all_AR) %in% names(rs_baseRFA)]

rs_baseRFA_all_AR[is.na(rs_baseRFA_all_AR$base_weight_STCY), ]$base_weight_STCY<-0 # this can be a little slow/sticky
rs_baseRFA_all_AR[rs_baseRFA_all_AR$base_weight_STCY==0,]$base_weight_STCY<-rs_baseRFA_all_AR[rs_baseRFA_all_AR$base_weight_STCY==0,]$base_weight_STCY+rs_baseRFA_all_AR[rs_baseRFA_all_AR$base_weight_STCY==0,]$base_weight

# example of calculating national level emissions in each year , except without construction related emissions
colSums(rs_baseRFA_all_AR[,176:184])*1e-9 # 
# example of calculating national level emissions in each year , LREC
colSums(rs_baseRFA_all_AR[,185:193])*1e-9 # 

save(rs_baseRFA_all_AR,file="../Final_results/res_baseRFA_AR.RData")
rm(rs_baseRFA_all_AR)
# now extensive renovation
n1<-names(rs_ERn) # <2020 stock, Adv Ren
n2<-names(rs_baseRFA) # new construction

# check the GHG ints in the two files
G1<-unique(rs_ERn[,c('County','GHG_int_2020')])
names(G1)[2]<-'GHG_int_2020_ex'
G2<-unique(rs_baseRFA[,c('County','GHG_int_2020')])
names(G2)[2]<-'GHG_int_2020_nc'
G3<-merge(G2,G1)
print(all(G3$GHG_int_2020_nc==G3$GHG_int_2020_ex))

rs_baseRFA_all_ER<-bind_rows(rs_ERn,rs_baseRFA)

rs_baseRFA_all_ER<-rs_baseRFA_all_ER[,names(rs_baseRFA_all_ER) %in% names(rs_baseRFA)]

rs_baseRFA_all_ER[is.na(rs_baseRFA_all_ER$base_weight_STCY), ]$base_weight_STCY<-0 # this can be a little slow/sticky
rs_baseRFA_all_ER[rs_baseRFA_all_ER$base_weight_STCY==0,]$base_weight_STCY<-rs_baseRFA_all_ER[rs_baseRFA_all_ER$base_weight_STCY==0,]$base_weight_STCY+rs_baseRFA_all_ER[rs_baseRFA_all_ER$base_weight_STCY==0,]$base_weight

# example of calculating national level emissions in each year , except without construction related emissions
colSums(rs_baseRFA_all_ER[,176:184])*1e-9 #
# example of calculating national level emissions in each year , LREC
colSums(rs_baseRFA_all_ER[,185:193])*1e-9 # 

save(rs_baseRFA_all_ER,file="../Final_results/res_baseRFA_ER.RData")
rm(rs_baseRFA_all_ER)
rm(rs_baseRFA)
rm(rsbase_RFA)
# load in projection results, base DERFA ######
# 4 of 12 stock projection results: base stock, DERFA NHC
print('base 4')
load("../Eagle_outputs/Complete_results/res_baseDERFA_final.RData")
rsbase_DERFA<-rsn
rm(rsn)

bs_base_DERFA<-bs_base_all[bs_base_all$scen=="baseDERFA",]
bs_base_DERFA$Year<-bs_base_DERFA$sim_year

bs_base_DERFA$Year_Building<-paste(bs_base_DERFA$Year,bs_base_DERFA$Building,sep="_")

bs_base_DERFA<-bs_base_DERFA[,c("Year_Building","Year", "Building","County","State","Location.Region","Census.Division", "Census.Region", "ASHRAE.IECC.Climate.Zone.2004", "PUMA", "ISO.RTO.Region", "Geometry.Building.Type.ACS","Geometry.Building.Type.RECS",
                            "Vintage","Vintage.ACS","Heating.Fuel","Geometry.Floor.Area","Geometry.Foundation.Type","Geometry.Wall.Type","Geometry.Stories","Geometry.Garage",
                            "HVAC.Heating.Type.And.Fuel","HVAC.Heating.Efficiency","HVAC.Cooling.Type","HVAC.Cooling.Efficiency","Water.Heater.Fuel","Water.Heater.Efficiency",
                            "Clothes.Dryer","Infiltration")] # currently comes to 29 columns, without "change_cren","change_iren","change_wren","change_hren", "base_weight". Add these in for consistency
bs_base_DERFA[,c("change_cren","change_iren","change_wren","change_hren")]<-0

bs_base_DERFA$base_weight<-0
# add base weights for each sim year, based on the new construction estimates
for (y in seq(2025,2060,5)) {
  bs_base_DERFA[bs_base_DERFA$Year==y,]$base_weight<-nce[nce$Year==y,]$base/15000
}

bs_base_DERFA$Type3<-'MF'
bs_base_DERFA[bs_base_DERFA$Geometry.Building.Type.RECS=='Mobile Home',]$Type3<-'MH'
bs_base_DERFA[bs_base_DERFA$Geometry.Building.Type.RECS %in% c('Single-Family Detached','Single-Family Attached'),]$Type3<-'SF'

names(stcy_comp_base)[c(2,4,8)]<-c('Vintage.ACS','Type3','base_weight_STCY')
bs_base_DERFA<-merge(bs_base_DERFA,stcy_comp_base[,c('Year','State','Type3','Vintage.ACS','base_weight_STCY')],by=c('Year','State','Type3','Vintage.ACS'))

bs_base_DERFA$TC<-"MF"
bs_base_DERFA[bs_base_DERFA$Geometry.Building.Type.RECS=="Single-Family Attached" | bs_base_DERFA$Geometry.Building.Type.RECS=="Single-Family Detached",]$TC<-"SF"
bs_base_DERFA[bs_base_DERFA$Geometry.Building.Type.RECS=="Mobile Home",]$TC<-"MH"
bs_base_DERFA$TC<-paste(bs_base_DERFA$TC,bs_base_DERFA$Vintage.ACS,sep="_")
bs_base_DERFA$ctyTC<-paste(bs_base_DERFA$County,bs_base_DERFA$TC,sep = "")
bs_base_DERFA$ctyTC<-gsub("2010s","2010-19",bs_base_DERFA$ctyTC)
bs_base_DERFA$ctyTC<-gsub("2020s","2020-29",bs_base_DERFA$ctyTC)
bs_base_DERFA$ctyTC<-gsub("2030s","2030-39",bs_base_DERFA$ctyTC)
bs_base_DERFA$ctyTC<-gsub("2040s","2040-49",bs_base_DERFA$ctyTC)
bs_base_DERFA$ctyTC<-gsub("2050s","2050-60",bs_base_DERFA$ctyTC)

bs_base_DERFA<-left_join(bs_base_DERFA,sbm,by="ctyTC")

# merge with the energy results
rsbDERFA_sum<-result_sum(rsbase_DERFA,0)
rsbDERFA_sum<-rsbDERFA_sum[,c(1:3,23,43,44,55:63,66,81,82,88,95,103,105:111,113:122,124:129,131,133,135:141,148:200)] # bigger version

rs_baseDERFA<-merge(bs_base_DERFA,rsbDERFA_sum,by.x = "Building",by.y = "building_id")
rs_baseDERFA<-rs_baseDERFA[,-c(which(names(rs_baseDERFA) %in% c("Year.y", "Year_Building.y")))]
rs_baseDERFA<-rs_baseDERFA %>% rename(Year_Building = Year_Building.x, Year = Year.x)

# add GHG intensities, Mid-Case
rs_baseDERFA<-left_join(rs_baseDERFA,gic,by = c("County" = "RS_ID"))
# add GHG intensities, Low RE Cost
rs_baseDERFA<-left_join(rs_baseDERFA,gic_LRE,by = c("County" = "RS_ID"))

rs_baseDERFA[rs_baseDERFA$Year==2030,]$wbase_2025<-0
rs_baseDERFA[rs_baseDERFA$Year==2040,]$wbase_2035<-0
rs_baseDERFA[rs_baseDERFA$Year==2050,]$wbase_2045<-0
rs_baseDERFA[rs_baseDERFA$Year==2060,]$wbase_2055<-0

rs_baseDERFA[,c("Tot_GJ_base_2020",  "Tot_GJ_base_2025","Tot_GJ_base_2030","Tot_GJ_base_2035","Tot_GJ_base_2040","Tot_GJ_base_2045","Tot_GJ_base_2050","Tot_GJ_base_2055","Tot_GJ_base_2060")]<-
  (rs_baseDERFA$base_weight_STCY*rs_baseDERFA[,c("wbase_2020", "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*
  (rs_baseDERFA$Elec_GJ+rs_baseDERFA$Gas_GJ+rs_baseDERFA$Prop_GJ+rs_baseDERFA$Oil_GJ)

# tot kgGHG per archetype group/year in kg
rs_baseDERFA[,c("EnGHGkg_base_2020","EnGHGkg_base_2025","EnGHGkg_base_2030","EnGHGkg_base_2035","EnGHGkg_base_2040","EnGHGkg_base_2045","EnGHGkg_base_2050","EnGHGkg_base_2055","EnGHGkg_base_2060")]<-1000* 
  (rs_baseDERFA$base_weight_STCY*rs_baseDERFA[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*
  (rs_baseDERFA$Elec_GJ*rs_baseDERFA[,c("GHG_int_2020", "GHG_int_2025","GHG_int_2030","GHG_int_2035","GHG_int_2040","GHG_int_2045","GHG_int_2050","GHG_int_2055","GHG_int_2060")]+
     matrix(rep(rs_baseDERFA$Gas_GJ*GHGI_NG,9),nrow(rs_baseDERFA),9)+ matrix(rep(rs_baseDERFA$Oil_GJ*GHGI_FO,9),nrow(rs_baseDERFA),9)+ matrix(rep(rs_baseDERFA$Prop_GJ*GHGI_LP,9),nrow(rs_baseDERFA),9))

# tot LRE kgGHG per archetype group/year in kg
rs_baseDERFA[,c("EnGHGkg_base_2020_LRE","EnGHGkg_base_2025_LRE","EnGHGkg_base_2030_LRE","EnGHGkg_base_2035_LRE","EnGHGkg_base_2040_LRE","EnGHGkg_base_2045_LRE","EnGHGkg_base_2050_LRE","EnGHGkg_base_2055_LRE","EnGHGkg_base_2060_LRE")]<-1000* 
  (rs_baseDERFA$base_weight_STCY*rs_baseDERFA[,c("wbase_2020",  "wbase_2025", "wbase_2030", "wbase_2035", "wbase_2040", "wbase_2045", "wbase_2050", "wbase_2055", "wbase_2060")])*
  (rs_baseDERFA$Elec_GJ*rs_baseDERFA[,c("GHG_int_2020_LRE", "GHG_int_2025_LRE","GHG_int_2030_LRE","GHG_int_2035_LRE","GHG_int_2040_LRE","GHG_int_2045_LRE","GHG_int_2050_LRE","GHG_int_2055_LRE","GHG_int_2060_LRE")]+
     matrix(rep(rs_baseDERFA$Gas_GJ*GHGI_NG,9),nrow(rs_baseDERFA),9)+ matrix(rep(rs_baseDERFA$Oil_GJ*GHGI_FO,9),nrow(rs_baseDERFA),9)+ matrix(rep(rs_baseDERFA$Prop_GJ*GHGI_LP,9),nrow(rs_baseDERFA),9))

save(rs_baseDERFA,file="../Intermediate_results/rs_baseDERFA_EG.RData")

# now  merge with the AR/RR files
n1<-names(rs_RRn) # <2020 stock, Reg Ren
n2<-names(rs_baseDERFA) # new construction

# check the GHG ints in the two files
G1<-unique(rs_RRn[,c('County','GHG_int_2020')])
names(G1)[2]<-'GHG_int_2020_ex'
G2<-unique(rs_baseDERFA[,c('County','GHG_int_2020')])
names(G2)[2]<-'GHG_int_2020_nc'
G3<-merge(G2,G1)
print(all(G3$GHG_int_2020_nc==G3$GHG_int_2020_ex))

# before binding rows, make the Building codes in rs_baseDERFA distinct from those in rs_RRn
rs_baseDERFA$Building<-180000+rs_baseDERFA$Building
rs_baseDERFA$Year_Building<-paste(rs_baseDERFA$Year,rs_baseDERFA$Building,sep="_")

rs_baseDERFA_all_RR<-bind_rows(rs_RRn,rs_baseDERFA)

rs_baseDERFA_all_RR<-rs_baseDERFA_all_RR[,names(rs_baseDERFA_all_RR) %in% names(rs_baseDERFA)]

rs_baseDERFA_all_RR[is.na(rs_baseDERFA_all_RR$base_weight_STCY), ]$base_weight_STCY<-0 # this can be a little slow/sticky
rs_baseDERFA_all_RR[rs_baseDERFA_all_RR$base_weight_STCY==0,]$base_weight_STCY<-rs_baseDERFA_all_RR[rs_baseDERFA_all_RR$base_weight_STCY==0,]$base_weight_STCY+rs_baseDERFA_all_RR[rs_baseDERFA_all_RR$base_weight_STCY==0,]$base_weight

# example of calculating national level emissions in each year , except without construction related emissions
colSums(rs_baseDERFA_all_RR[,176:184])*1e-9 # 
# example of calculating national level emissions in each year , LRE elec
colSums(rs_baseDERFA_all_RR[,185:193])*1e-9 # 

save(rs_baseDERFA_all_RR,file="../Final_results/res_baseDERFA_RR.RData")
rm(rs_baseDERFA_all_RR)
# now advanced renovation
n1<-names(rs_ARn) # <2020 stock, Adv Ren
n2<-names(rs_baseDERFA) # new construction

# check the GHG ints in the two files
G1<-unique(rs_ARn[,c('County','GHG_int_2020')])
names(G1)[2]<-'GHG_int_2020_ex'
G2<-unique(rs_baseDERFA[,c('County','GHG_int_2020')])
names(G2)[2]<-'GHG_int_2020_nc'
G3<-merge(G2,G1)
print(all(G3$GHG_int_2020_nc==G3$GHG_int_2020_ex))

rs_baseDERFA_all_AR<-bind_rows(rs_ARn,rs_baseDERFA)

rs_baseDERFA_all_AR<-rs_baseDERFA_all_AR[,names(rs_baseDERFA_all_AR) %in% names(rs_baseDERFA)]

rs_baseDERFA_all_AR[is.na(rs_baseDERFA_all_AR$base_weight_STCY), ]$base_weight_STCY<-0 # this can be a little slow/sticky
rs_baseDERFA_all_AR[rs_baseDERFA_all_AR$base_weight_STCY==0,]$base_weight_STCY<-rs_baseDERFA_all_AR[rs_baseDERFA_all_AR$base_weight_STCY==0,]$base_weight_STCY+rs_baseDERFA_all_AR[rs_baseDERFA_all_AR$base_weight_STCY==0,]$base_weight

# example of calculating national level emissions in each year , except without construction related emissions
colSums(rs_baseDERFA_all_AR[,176:184])*1e-9 # 
# example of calculating national level emissions in each year , LREC
colSums(rs_baseDERFA_all_AR[,185:193])*1e-9 # 

save(rs_baseDERFA_all_AR,file="../Final_results/res_baseDERFA_AR.RData")
rm(rs_baseDERFA_all_AR)
# now extended renovation
n1<-names(rs_ERn) # <2020 stock, Adv Ren
n2<-names(rs_baseDERFA) # new construction

# check the GHG ints in the two files
G1<-unique(rs_ERn[,c('County','GHG_int_2020')])
names(G1)[2]<-'GHG_int_2020_ex'
G2<-unique(rs_baseDERFA[,c('County','GHG_int_2020')])
names(G2)[2]<-'GHG_int_2020_nc'
G3<-merge(G2,G1)
print(all(G3$GHG_int_2020_nc==G3$GHG_int_2020_ex))

rs_baseDERFA_all_ER<-bind_rows(rs_ERn,rs_baseDERFA)

rs_baseDERFA_all_ER<-rs_baseDERFA_all_ER[,names(rs_baseDERFA_all_ER) %in% names(rs_baseDERFA)]

rs_baseDERFA_all_ER[is.na(rs_baseDERFA_all_ER$base_weight_STCY), ]$base_weight_STCY<-0 # this can be a little slow/sticky
rs_baseDERFA_all_ER[rs_baseDERFA_all_ER$base_weight_STCY==0,]$base_weight_STCY<-rs_baseDERFA_all_ER[rs_baseDERFA_all_ER$base_weight_STCY==0,]$base_weight_STCY+rs_baseDERFA_all_ER[rs_baseDERFA_all_ER$base_weight_STCY==0,]$base_weight

# example of calculating national level emissions in each year , except without construction related emissions
colSums(rs_baseDERFA_all_ER[,176:184])*1e-9 # 
# example of calculating national level emissions in each year , LREC
colSums(rs_baseDERFA_all_ER[,185:193])*1e-9 # 

save(rs_baseDERFA_all_ER,file="../Final_results/res_baseDERFA_ER.RData")
rm(rs_baseDERFA_all_ER)
rm(rs_baseDERFA)

# replicate all of base with the hiDR scenarios

# load in projection results, hiDR ######
# 5 of 12 stock projection results: hiDR stock, base NHC
print('hiDR 5')
load("../Eagle_outputs/Complete_results/res_hiDR_final.RData")
rshiDR_base<-rsn
rm(rsn)

bs_hiDR_base<-bs_hiDR_all[bs_hiDR_all$scen=="hiDR",]
bs_hiDR_base$Year<-bs_hiDR_base$sim_year

bs_hiDR_base$Year_Building<-paste(bs_hiDR_base$Year,bs_hiDR_base$Building,sep="_")

bs_hiDR_base<-bs_hiDR_base[,c("Year_Building","Year", "Building","County","State","Location.Region","Census.Division", "Census.Region", "ASHRAE.IECC.Climate.Zone.2004", "PUMA", "ISO.RTO.Region", "Geometry.Building.Type.ACS","Geometry.Building.Type.RECS",
                              "Vintage","Vintage.ACS","Heating.Fuel","Geometry.Floor.Area","Geometry.Foundation.Type","Geometry.Wall.Type","Geometry.Stories","Geometry.Garage",
                              "HVAC.Heating.Type.And.Fuel","HVAC.Heating.Efficiency","HVAC.Cooling.Type","HVAC.Cooling.Efficiency","Water.Heater.Fuel","Water.Heater.Efficiency",
                              "Clothes.Dryer","Infiltration")] # currently comes to 29 columns, without "change_cren","change_iren","change_wren","change_hren", "base_weight". Add these in for consistency
bs_hiDR_base[,c("change_cren","change_iren","change_wren","change_hren")]<-0

bs_hiDR_base$base_weight<-0
# add base weights for each sim year, based on the new construction estimates
for (y in seq(2025,2060,5)) {
  bs_hiDR_base[bs_hiDR_base$Year==y,]$base_weight<-nce[nce$Year==y,]$hiDR/15000
}

bs_hiDR_base$Type3<-'MF'
bs_hiDR_base[bs_hiDR_base$Geometry.Building.Type.RECS=='Mobile Home',]$Type3<-'MH'
bs_hiDR_base[bs_hiDR_base$Geometry.Building.Type.RECS %in% c('Single-Family Detached','Single-Family Attached'),]$Type3<-'SF'

names(stcy_comp_hiDR)[c(2,4,8)]<-c('Vintage.ACS','Type3','base_weight_STCY')
bs_hiDR_base<-merge(bs_hiDR_base,stcy_comp_hiDR[,c('Year','State','Type3','Vintage.ACS','base_weight_STCY')],by=c('Year','State','Type3','Vintage.ACS'))

bs_hiDR_base$TC<-"MF"
bs_hiDR_base[bs_hiDR_base$Geometry.Building.Type.RECS=="Single-Family Attached" | bs_hiDR_base$Geometry.Building.Type.RECS=="Single-Family Detached",]$TC<-"SF"
bs_hiDR_base[bs_hiDR_base$Geometry.Building.Type.RECS=="Mobile Home",]$TC<-"MH"
bs_hiDR_base$TC<-paste(bs_hiDR_base$TC,bs_hiDR_base$Vintage.ACS,sep="_")
bs_hiDR_base$ctyTC<-paste(bs_hiDR_base$County,bs_hiDR_base$TC,sep = "")
bs_hiDR_base$ctyTC<-gsub("2010s","2010-19",bs_hiDR_base$ctyTC)
bs_hiDR_base$ctyTC<-gsub("2020s","2020-29",bs_hiDR_base$ctyTC)
bs_hiDR_base$ctyTC<-gsub("2030s","2030-39",bs_hiDR_base$ctyTC)
bs_hiDR_base$ctyTC<-gsub("2040s","2040-49",bs_hiDR_base$ctyTC)
bs_hiDR_base$ctyTC<-gsub("2050s","2050-60",bs_hiDR_base$ctyTC)

bs_hiDR_base<-left_join(bs_hiDR_base,shdrm,by="ctyTC")

# merge with the energy results
rshdrb_sum<-result_sum(rshiDR_base,0)
rshdrb_sum<-rshdrb_sum[,c(1:3,23,43,44,55:63,66,81,82,88,95,103,105:111,113:122,124:129,131,133,135:141,148:200)] # bigger version

rs_hiDR<-merge(bs_hiDR_base,rshdrb_sum,by.x = "Building",by.y = "building_id")
rs_hiDR<-rs_hiDR[,-c(which(names(rs_hiDR) %in% c("Year.y", "Year_Building.y")))]
rs_hiDR<-rs_hiDR %>% rename(Year_Building = Year_Building.x, Year = Year.x)

# add GHG intensities, Mid-Case
rs_hiDR<-left_join(rs_hiDR,gic,by = c("County" = "RS_ID"))
# add GHG intensities, Low RE Cost
rs_hiDR<-left_join(rs_hiDR,gic_LRE,by = c("County" = "RS_ID"))

rs_hiDR[rs_hiDR$Year==2030,]$whiDR_2025<-0
rs_hiDR[rs_hiDR$Year==2040,]$whiDR_2035<-0
rs_hiDR[rs_hiDR$Year==2050,]$whiDR_2045<-0
rs_hiDR[rs_hiDR$Year==2060,]$whiDR_2055<-0

rs_hiDR[,c("Tot_GJ_hiDR_2020",  "Tot_GJ_hiDR_2025","Tot_GJ_hiDR_2030","Tot_GJ_hiDR_2035","Tot_GJ_hiDR_2040","Tot_GJ_hiDR_2045","Tot_GJ_hiDR_2050","Tot_GJ_hiDR_2055","Tot_GJ_hiDR_2060")]<-
  (rs_hiDR$base_weight_STCY*rs_hiDR[,c("whiDR_2020", "whiDR_2025", "whiDR_2030", "whiDR_2035", "whiDR_2040", "whiDR_2045", "whiDR_2050", "whiDR_2055", "whiDR_2060")])*
  (rs_hiDR$Elec_GJ+rs_hiDR$Gas_GJ+rs_hiDR$Prop_GJ+rs_hiDR$Oil_GJ)

# tot kgGHG per archetype group/year in kg
rs_hiDR[,c("EnGHGkg_hiDR_2020","EnGHGkg_hiDR_2025","EnGHGkg_hiDR_2030","EnGHGkg_hiDR_2035","EnGHGkg_hiDR_2040","EnGHGkg_hiDR_2045","EnGHGkg_hiDR_2050","EnGHGkg_hiDR_2055","EnGHGkg_hiDR_2060")]<-1000* 
  (rs_hiDR$base_weight_STCY*rs_hiDR[,c("whiDR_2020",  "whiDR_2025", "whiDR_2030", "whiDR_2035", "whiDR_2040", "whiDR_2045", "whiDR_2050", "whiDR_2055", "whiDR_2060")])*
  (rs_hiDR$Elec_GJ*rs_hiDR[,c("GHG_int_2020", "GHG_int_2025","GHG_int_2030","GHG_int_2035","GHG_int_2040","GHG_int_2045","GHG_int_2050","GHG_int_2055","GHG_int_2060")]+
     matrix(rep(rs_hiDR$Gas_GJ*GHGI_NG,9),nrow(rs_hiDR),9)+ matrix(rep(rs_hiDR$Oil_GJ*GHGI_FO,9),nrow(rs_hiDR),9)+ matrix(rep(rs_hiDR$Prop_GJ*GHGI_LP,9),nrow(rs_hiDR),9))

# tot LRE kgGHG per archetype group/year in kg
rs_hiDR[,c("EnGHGkg_hiDR_2020_LRE","EnGHGkg_hiDR_2025_LRE","EnGHGkg_hiDR_2030_LRE","EnGHGkg_hiDR_2035_LRE","EnGHGkg_hiDR_2040_LRE","EnGHGkg_hiDR_2045_LRE","EnGHGkg_hiDR_2050_LRE","EnGHGkg_hiDR_2055_LRE","EnGHGkg_hiDR_2060_LRE")]<-1000* 
  (rs_hiDR$base_weight_STCY*rs_hiDR[,c("whiDR_2020",  "whiDR_2025", "whiDR_2030", "whiDR_2035", "whiDR_2040", "whiDR_2045", "whiDR_2050", "whiDR_2055", "whiDR_2060")])*
  (rs_hiDR$Elec_GJ*rs_hiDR[,c("GHG_int_2020_LRE", "GHG_int_2025_LRE","GHG_int_2030_LRE","GHG_int_2035_LRE","GHG_int_2040_LRE","GHG_int_2045_LRE","GHG_int_2050_LRE","GHG_int_2055_LRE","GHG_int_2060_LRE")]+
     matrix(rep(rs_hiDR$Gas_GJ*GHGI_NG,9),nrow(rs_hiDR),9)+ matrix(rep(rs_hiDR$Oil_GJ*GHGI_FO,9),nrow(rs_hiDR),9)+ matrix(rep(rs_hiDR$Prop_GJ*GHGI_LP,9),nrow(rs_hiDR),9))

save(rs_hiDR,file="../Intermediate_results/rs_hiDR_EG.RData") 

# now  merge with the AR/RR files
n1<-names(rs_RRn) # <2020 stock, Reg Ren
n2<-names(rs_hiDR) # new construction

# check the GHG ints in the two files
G1<-unique(rs_RRn[,c('County','GHG_int_2020')])
names(G1)[2]<-'GHG_int_2020_ex'
G2<-unique(rs_hiDR[,c('County','GHG_int_2020')])
names(G2)[2]<-'GHG_int_2020_nc'
G3<-merge(G2,G1)
print(all(G3$GHG_int_2020_nc==G3$GHG_int_2020_ex))

# before binding rows, make the Building codes in rs_hiDR distinct from those in rs_RRn
rs_hiDR$Building<-180000+rs_hiDR$Building
rs_hiDR$Year_Building<-paste(rs_hiDR$Year,rs_hiDR$Building,sep="_")

rs_hiDR_all_RR<-bind_rows(rs_RRn,rs_hiDR)

rs_hiDR_all_RR<-rs_hiDR_all_RR[,names(rs_hiDR_all_RR) %in% names(rs_hiDR)]

rs_hiDR_all_RR[is.na(rs_hiDR_all_RR$base_weight_STCY), ]$base_weight_STCY<-0 # this can be a little slow/sticky
rs_hiDR_all_RR[rs_hiDR_all_RR$base_weight_STCY==0,]$base_weight_STCY<-rs_hiDR_all_RR[rs_hiDR_all_RR$base_weight_STCY==0,]$base_weight_STCY+rs_hiDR_all_RR[rs_hiDR_all_RR$base_weight_STCY==0,]$base_weight

# example of calculating national level emissions in each year , except without construction related emissions
colSums(rs_hiDR_all_RR[,176:184])*1e-9 # 
# example of calculating national level emissions in each year , LRE elec
colSums(rs_hiDR_all_RR[,185:193])*1e-9 # 

rs_hiDR_all_RR$Type3<-'MF'
rs_hiDR_all_RR[rs_hiDR_all_RR$Geometry.Building.Type.RECS=='Mobile Home',]$Type3<-'MH'
rs_hiDR_all_RR[rs_hiDR_all_RR$Geometry.Building.Type.RECS %in% c('Single-Family Detached','Single-Family Attached'),]$Type3<-'SF'

st40hd<-comp_ests(rs_hiDR_all_RR,2040,'State','whiDR_2040',stock_tsy_hiDR)
st60hd<-comp_ests(rs_hiDR_all_RR,2060,'State','whiDR_2060',stock_tsy_hiDR)

# compare between base and hiDR, this dataframe shows that the STCY weights produce total stock estimates by type and state that are much more internally consistent, than the original base weights. That seals it.
base_hiDR_comp_st<-data.frame(Year=st40$Year,State=st40$State,Type3=st40$Type3,
                              Est40_base0=st40$UnitCount0,Est40_hiDR0=st40hd$UnitCount0,
                              Est40_base_STCY=st40$UnitCount_STCY,Est40_hiDR_STCY=st40hd$UnitCount_STCY,
                              Est60_base0=st60$UnitCount0,Est60_hiDR0=st60hd$UnitCount0,
                              Est60_base_STCY=st60$UnitCount_STCY,Est60_hiDR_STCY=st60hd$UnitCount_STCY)

base_hiDR_comp_st$EstRatio_2040_0<-base_hiDR_comp_st$Est40_hiDR0/base_hiDR_comp_st$Est40_base0
base_hiDR_comp_st$EstRatio_2040_STCY<-base_hiDR_comp_st$Est40_hiDR_STCY/base_hiDR_comp_st$Est40_base_STCY

base_hiDR_comp_st$EstRatio_2060_0<-base_hiDR_comp_st$Est60_hiDR0/base_hiDR_comp_st$Est60_base0
base_hiDR_comp_st$EstRatio_2060_STCY<-base_hiDR_comp_st$Est60_hiDR_STCY/base_hiDR_comp_st$Est60_base_STCY

cty50hd<-comp_ests(rs_hiDR_all_RR,2050,'County','whiDR_2050',stock_tcy_hiDR)
st50hd<-comp_ests(rs_hiDR_all_RR,2050,'State','whiDR_2050',stock_tsy_hiDR)

save(rs_hiDR_all_RR,file="../Final_results/res_hiDR_RR.RData")
rm(rs_hiDR_all_RR)
# now advanced renovation
n1<-names(rs_ARn) # <2020 stock, Reg Ren
n2<-names(rs_hiDR) # new construction

# check the GHG ints in the two files
G1<-unique(rs_ARn[,c('County','GHG_int_2020')])
names(G1)[2]<-'GHG_int_2020_ex'
G2<-unique(rs_hiDR[,c('County','GHG_int_2020')])
names(G2)[2]<-'GHG_int_2020_nc'
G3<-merge(G2,G1)
print(all(G3$GHG_int_2020_nc==G3$GHG_int_2020_ex))

rs_hiDR_all_AR<-bind_rows(rs_ARn,rs_hiDR)

rs_hiDR_all_AR<-rs_hiDR_all_AR[,names(rs_hiDR_all_AR) %in% names(rs_hiDR)]

rs_hiDR_all_AR[is.na(rs_hiDR_all_AR$base_weight_STCY), ]$base_weight_STCY<-0 # this can be a little slow/sticky
rs_hiDR_all_AR[rs_hiDR_all_AR$base_weight_STCY==0,]$base_weight_STCY<-rs_hiDR_all_AR[rs_hiDR_all_AR$base_weight_STCY==0,]$base_weight_STCY+rs_hiDR_all_AR[rs_hiDR_all_AR$base_weight_STCY==0,]$base_weight

# example of calculating national level emissions in each year , except without construction related emissions
colSums(rs_hiDR_all_AR[,176:184])*1e-9 # 
# example of calculating national level emissions in each year , LREC
colSums(rs_hiDR_all_AR[,185:193])*1e-9 #

save(rs_hiDR_all_AR,file="../Final_results/res_hiDR_AR.RData")
rm(rs_hiDR_all_AR)
# now extensive renovation
n1<-names(rs_ERn) # <2020 stock, Reg Ren
n2<-names(rs_hiDR) # new construction

# check the GHG ints in the two files
G1<-unique(rs_ERn[,c('County','GHG_int_2020')])
names(G1)[2]<-'GHG_int_2020_ex'
G2<-unique(rs_hiDR[,c('County','GHG_int_2020')])
names(G2)[2]<-'GHG_int_2020_nc'
G3<-merge(G2,G1)
print(all(G3$GHG_int_2020_nc==G3$GHG_int_2020_ex))

rs_hiDR_all_ER<-bind_rows(rs_ERn,rs_hiDR)

rs_hiDR_all_ER<-rs_hiDR_all_ER[,names(rs_hiDR_all_ER) %in% names(rs_hiDR)]

rs_hiDR_all_ER[is.na(rs_hiDR_all_ER$base_weight_STCY), ]$base_weight_STCY<-0 # this can be a little slow/sticky
rs_hiDR_all_ER[rs_hiDR_all_ER$base_weight_STCY==0,]$base_weight_STCY<-rs_hiDR_all_ER[rs_hiDR_all_ER$base_weight_STCY==0,]$base_weight_STCY+rs_hiDR_all_ER[rs_hiDR_all_ER$base_weight_STCY==0,]$base_weight


# example of calculating national level emissions in each year , except without construction related emissions
colSums(rs_hiDR_all_ER[,176:184])*1e-9 # 
# example of calculating national level emissions in each year , LREC
colSums(rs_hiDR_all_ER[,185:193])*1e-9 # 

save(rs_hiDR_all_ER,file="../Final_results/res_hiDR_ER.RData")
rm(rs_hiDR_all_ER)
rm(rs_hiDR)
rm(rshiDR_base)
# load in projection results, hiDRRFA ######
# 6 of 12 stock projection results: hiDR stock, RFA NHC
print('hiDR 6')
load("../Eagle_outputs/Complete_results/res_hiDRRFA_final.RData")
rshiDR_RFA<-rsn
rm(rsn)

bs_hiDR_RFA<-bs_hiDR_all[bs_hiDR_all$scen=="hiDRRFA",]
bs_hiDR_RFA$Year<-bs_hiDR_RFA$sim_year

bs_hiDR_RFA$Year_Building<-paste(bs_hiDR_RFA$Year,bs_hiDR_RFA$Building,sep="_")

bs_hiDR_RFA<-bs_hiDR_RFA[,c("Year_Building","Year", "Building","County","State","Location.Region","Census.Division", "Census.Region", "ASHRAE.IECC.Climate.Zone.2004", "PUMA", "ISO.RTO.Region", "Geometry.Building.Type.ACS","Geometry.Building.Type.RECS",
                              "Vintage","Vintage.ACS","Heating.Fuel","Geometry.Floor.Area","Geometry.Foundation.Type","Geometry.Wall.Type","Geometry.Stories","Geometry.Garage",
                              "HVAC.Heating.Type.And.Fuel","HVAC.Heating.Efficiency","HVAC.Cooling.Type","HVAC.Cooling.Efficiency","Water.Heater.Fuel","Water.Heater.Efficiency",
                              "Clothes.Dryer","Infiltration")] # currently comes to 29 columns, without "change_cren","change_iren","change_wren","change_hren", "base_weight". Add these in for consistency
bs_hiDR_RFA[,c("change_cren","change_iren","change_wren","change_hren")]<-0

bs_hiDR_RFA$base_weight<-0
# add base weights for each sim year, based on the new construction estimates
for (y in seq(2025,2060,5)) {
  bs_hiDR_RFA[bs_hiDR_RFA$Year==y,]$base_weight<-nce[nce$Year==y,]$hiDR/15000
}

bs_hiDR_RFA$Type3<-'MF'
bs_hiDR_RFA[bs_hiDR_RFA$Geometry.Building.Type.RECS=='Mobile Home',]$Type3<-'MH'
bs_hiDR_RFA[bs_hiDR_RFA$Geometry.Building.Type.RECS %in% c('Single-Family Detached','Single-Family Attached'),]$Type3<-'SF'

names(stcy_comp_hiDR)[c(2,4,8)]<-c('Vintage.ACS','Type3','base_weight_STCY')
bs_hiDR_RFA<-merge(bs_hiDR_RFA,stcy_comp_hiDR[,c('Year','State','Type3','Vintage.ACS','base_weight_STCY')],by=c('Year','State','Type3','Vintage.ACS'))

bs_hiDR_RFA$TC<-"MF"
bs_hiDR_RFA[bs_hiDR_RFA$Geometry.Building.Type.RECS=="Single-Family Attached" | bs_hiDR_RFA$Geometry.Building.Type.RECS=="Single-Family Detached",]$TC<-"SF"
bs_hiDR_RFA[bs_hiDR_RFA$Geometry.Building.Type.RECS=="Mobile Home",]$TC<-"MH"
bs_hiDR_RFA$TC<-paste(bs_hiDR_RFA$TC,bs_hiDR_RFA$Vintage.ACS,sep="_")
bs_hiDR_RFA$ctyTC<-paste(bs_hiDR_RFA$County,bs_hiDR_RFA$TC,sep = "")
bs_hiDR_RFA$ctyTC<-gsub("2010s","2010-19",bs_hiDR_RFA$ctyTC)
bs_hiDR_RFA$ctyTC<-gsub("2020s","2020-29",bs_hiDR_RFA$ctyTC)
bs_hiDR_RFA$ctyTC<-gsub("2030s","2030-39",bs_hiDR_RFA$ctyTC)
bs_hiDR_RFA$ctyTC<-gsub("2040s","2040-49",bs_hiDR_RFA$ctyTC)
bs_hiDR_RFA$ctyTC<-gsub("2050s","2050-60",bs_hiDR_RFA$ctyTC)

bs_hiDR_RFA<-left_join(bs_hiDR_RFA,shdrm,by="ctyTC")

# merge with the energy results
rshdrRFA_sum<-result_sum(rshiDR_RFA,0)
rshdrRFA_sum<-rshdrRFA_sum[,c(1:3,23,43,44,55:63,66,81,82,88,95,103,105:111,113:122,124:129,131,133,135:141,148:200)] # bigger version

rs_hiDRRFA<-merge(bs_hiDR_RFA,rshdrRFA_sum,by.x = "Building",by.y = "building_id")
rs_hiDRRFA<-rs_hiDRRFA[,-c(which(names(rs_hiDRRFA) %in% c("Year.y", "Year_Building.y")))]
rs_hiDRRFA<-rs_hiDRRFA %>% rename(Year_Building = Year_Building.x, Year = Year.x)

# add GHG intensities, Mid-Case
rs_hiDRRFA<-left_join(rs_hiDRRFA,gic,by = c("County" = "RS_ID"))
# add GHG intensities, Low RE Cost
rs_hiDRRFA<-left_join(rs_hiDRRFA,gic_LRE,by = c("County" = "RS_ID"))

rs_hiDRRFA[rs_hiDRRFA$Year==2030,]$whiDR_2025<-0
rs_hiDRRFA[rs_hiDRRFA$Year==2040,]$whiDR_2035<-0
rs_hiDRRFA[rs_hiDRRFA$Year==2050,]$whiDR_2045<-0
rs_hiDRRFA[rs_hiDRRFA$Year==2060,]$whiDR_2055<-0

rs_hiDRRFA[,c("Tot_GJ_hiDR_2020",  "Tot_GJ_hiDR_2025","Tot_GJ_hiDR_2030","Tot_GJ_hiDR_2035","Tot_GJ_hiDR_2040","Tot_GJ_hiDR_2045","Tot_GJ_hiDR_2050","Tot_GJ_hiDR_2055","Tot_GJ_hiDR_2060")]<-
  (rs_hiDRRFA$base_weight_STCY*rs_hiDRRFA[,c("whiDR_2020", "whiDR_2025", "whiDR_2030", "whiDR_2035", "whiDR_2040", "whiDR_2045", "whiDR_2050", "whiDR_2055", "whiDR_2060")])*
  (rs_hiDRRFA$Elec_GJ+rs_hiDRRFA$Gas_GJ+rs_hiDRRFA$Prop_GJ+rs_hiDRRFA$Oil_GJ)

# tot kgGHG per archetype group/year in kg
rs_hiDRRFA[,c("EnGHGkg_hiDR_2020","EnGHGkg_hiDR_2025","EnGHGkg_hiDR_2030","EnGHGkg_hiDR_2035","EnGHGkg_hiDR_2040","EnGHGkg_hiDR_2045","EnGHGkg_hiDR_2050","EnGHGkg_hiDR_2055","EnGHGkg_hiDR_2060")]<-1000* 
  (rs_hiDRRFA$base_weight_STCY*rs_hiDRRFA[,c("whiDR_2020",  "whiDR_2025", "whiDR_2030", "whiDR_2035", "whiDR_2040", "whiDR_2045", "whiDR_2050", "whiDR_2055", "whiDR_2060")])*
  (rs_hiDRRFA$Elec_GJ*rs_hiDRRFA[,c("GHG_int_2020", "GHG_int_2025","GHG_int_2030","GHG_int_2035","GHG_int_2040","GHG_int_2045","GHG_int_2050","GHG_int_2055","GHG_int_2060")]+
     matrix(rep(rs_hiDRRFA$Gas_GJ*GHGI_NG,9),nrow(rs_hiDRRFA),9)+ matrix(rep(rs_hiDRRFA$Oil_GJ*GHGI_FO,9),nrow(rs_hiDRRFA),9)+ matrix(rep(rs_hiDRRFA$Prop_GJ*GHGI_LP,9),nrow(rs_hiDRRFA),9))

# tot LRE kgGHG per archetype group/year in kg
rs_hiDRRFA[,c("EnGHGkg_hiDR_2020_LRE","EnGHGkg_hiDR_2025_LRE","EnGHGkg_hiDR_2030_LRE","EnGHGkg_hiDR_2035_LRE","EnGHGkg_hiDR_2040_LRE","EnGHGkg_hiDR_2045_LRE","EnGHGkg_hiDR_2050_LRE","EnGHGkg_hiDR_2055_LRE","EnGHGkg_hiDR_2060_LRE")]<-1000* 
  (rs_hiDRRFA$base_weight_STCY*rs_hiDRRFA[,c("whiDR_2020",  "whiDR_2025", "whiDR_2030", "whiDR_2035", "whiDR_2040", "whiDR_2045", "whiDR_2050", "whiDR_2055", "whiDR_2060")])*
  (rs_hiDRRFA$Elec_GJ*rs_hiDRRFA[,c("GHG_int_2020_LRE", "GHG_int_2025_LRE","GHG_int_2030_LRE","GHG_int_2035_LRE","GHG_int_2040_LRE","GHG_int_2045_LRE","GHG_int_2050_LRE","GHG_int_2055_LRE","GHG_int_2060_LRE")]+
     matrix(rep(rs_hiDRRFA$Gas_GJ*GHGI_NG,9),nrow(rs_hiDRRFA),9)+ matrix(rep(rs_hiDRRFA$Oil_GJ*GHGI_FO,9),nrow(rs_hiDRRFA),9)+ matrix(rep(rs_hiDRRFA$Prop_GJ*GHGI_LP,9),nrow(rs_hiDRRFA),9))

save(rs_hiDRRFA,file="../Intermediate_results/rs_hiDRRFA_EG.RData") 

# now merge with the AR/RR files
n1<-names(rs_RRn) # <2020 stock, Reg Ren
n2<-names(rs_hiDRRFA) # new construction

# check the GHG ints in the two files
G1<-unique(rs_RRn[,c('County','GHG_int_2020')])
names(G1)[2]<-'GHG_int_2020_ex'
G2<-unique(rs_hiDRRFA[,c('County','GHG_int_2020')])
names(G2)[2]<-'GHG_int_2020_nc'
G3<-merge(G2,G1)
print(all(G3$GHG_int_2020_nc==G3$GHG_int_2020_ex))

# before binding rows, make the Building codes in rs_hiDRRFA distinct from thosw in rs_RRb
rs_hiDRRFA$Building<-180000+rs_hiDRRFA$Building
rs_hiDRRFA$Year_Building<-paste(rs_hiDRRFA$Year,rs_hiDRRFA$Building,sep="_")

rs_hiDRRFA_all_RR<-bind_rows(rs_RRn,rs_hiDRRFA)

rs_hiDRRFA_all_RR<-rs_hiDRRFA_all_RR[,names(rs_hiDRRFA_all_RR) %in% names(rs_hiDRRFA)]

rs_hiDRRFA_all_RR[is.na(rs_hiDRRFA_all_RR$base_weight_STCY), ]$base_weight_STCY<-0 # this can be a little slow/sticky
rs_hiDRRFA_all_RR[rs_hiDRRFA_all_RR$base_weight_STCY==0,]$base_weight_STCY<-rs_hiDRRFA_all_RR[rs_hiDRRFA_all_RR$base_weight_STCY==0,]$base_weight_STCY+rs_hiDRRFA_all_RR[rs_hiDRRFA_all_RR$base_weight_STCY==0,]$base_weight

# example of calculating national level emissions in each year , except without construction related emissions
colSums(rs_hiDRRFA_all_RR[,176:184])*1e-9 #
# example of calculating national level emissions in each year , LRE elec
colSums(rs_hiDRRFA_all_RR[,185:193])*1e-9 # 

save(rs_hiDRRFA_all_RR,file="../Final_results/res_hiDRRFA_RR.RData")
rm(rs_hiDRRFA_all_RR)
# now advanced renovation
n1<-names(rs_ARn) # <2020 stock, Reg Ren
n2<-names(rs_hiDRRFA) # new construction

# check the GHG ints in the two files
G1<-unique(rs_ARn[,c('County','GHG_int_2020')])
names(G1)[2]<-'GHG_int_2020_ex'
G2<-unique(rs_hiDRRFA[,c('County','GHG_int_2020')])
names(G2)[2]<-'GHG_int_2020_nc'
G3<-merge(G2,G1)
print(all(G3$GHG_int_2020_nc==G3$GHG_int_2020_ex))

rs_hiDRRFA_all_AR<-bind_rows(rs_ARn,rs_hiDRRFA)

rs_hiDRRFA_all_AR<-rs_hiDRRFA_all_AR[,names(rs_hiDRRFA_all_AR) %in% names(rs_hiDRRFA)]

rs_hiDRRFA_all_AR[is.na(rs_hiDRRFA_all_AR$base_weight_STCY), ]$base_weight_STCY<-0 # this can be a little slow/sticky
rs_hiDRRFA_all_AR[rs_hiDRRFA_all_AR$base_weight_STCY==0,]$base_weight_STCY<-rs_hiDRRFA_all_AR[rs_hiDRRFA_all_AR$base_weight_STCY==0,]$base_weight_STCY+rs_hiDRRFA_all_AR[rs_hiDRRFA_all_AR$base_weight_STCY==0,]$base_weight

# example of calculating national level emissions in each year , except without construction related emissions
colSums(rs_hiDRRFA_all_AR[,176:184])*1e-9 # 
# example of calculating national level emissions in each year , LREC
colSums(rs_hiDRRFA_all_AR[,185:193])*1e-9 #

save(rs_hiDRRFA_all_AR,file="../Final_results/res_hiDRRFA_AR.RData")
rm(rs_hiDRRFA_all_AR)
# now extensive renovation
n1<-names(rs_ERn) # <2020 stock, EE Ren
n2<-names(rs_hiDRRFA) # new construction

# check the GHG ints in the two files
G1<-unique(rs_ERn[,c('County','GHG_int_2020')])
names(G1)[2]<-'GHG_int_2020_ex'
G2<-unique(rs_hiDRRFA[,c('County','GHG_int_2020')])
names(G2)[2]<-'GHG_int_2020_nc'
G3<-merge(G2,G1)
print(all(G3$GHG_int_2020_nc==G3$GHG_int_2020_ex))

rs_hiDRRFA_all_ER<-bind_rows(rs_ERn,rs_hiDRRFA)

rs_hiDRRFA_all_ER<-rs_hiDRRFA_all_ER[,names(rs_hiDRRFA_all_ER) %in% names(rs_hiDRRFA)]

rs_hiDRRFA_all_ER[is.na(rs_hiDRRFA_all_ER$base_weight_STCY), ]$base_weight_STCY<-0 # this can be a little slow/sticky
rs_hiDRRFA_all_ER[rs_hiDRRFA_all_ER$base_weight_STCY==0,]$base_weight_STCY<-rs_hiDRRFA_all_ER[rs_hiDRRFA_all_ER$base_weight_STCY==0,]$base_weight_STCY+rs_hiDRRFA_all_ER[rs_hiDRRFA_all_ER$base_weight_STCY==0,]$base_weight

# example of calculating national level emissions in each year , except without construction related emissions
colSums(rs_hiDRRFA_all_ER[,176:184])*1e-9 # 
# example of calculating national level emissions in each year , LREC
colSums(rs_hiDRRFA_all_ER[,185:193])*1e-9 # 

save(rs_hiDRRFA_all_ER,file="../Final_results/res_hiDRRFA_ER.RData")
rm(rs_hiDRRFA_all_ER)
rm(rshiDR_RFA)
rm(rs_hiDRRFA)
# load in projection results, hiDRDE ######
# 7 of 12 stock projection results: hiDR stock, DE NHC
print('hiDR 7')
load("../Eagle_outputs/Complete_results/res_hiDRDE_final.RData")
rshiDR_DE<-rsn
rm(rsn)

bs_hiDR_DE<-bs_hiDR_all[bs_hiDR_all$scen=="hiDRDE",]
bs_hiDR_DE$Year<-bs_hiDR_DE$sim_year

bs_hiDR_DE$Year_Building<-paste(bs_hiDR_DE$Year,bs_hiDR_DE$Building,sep="_")

bs_hiDR_DE<-bs_hiDR_DE[,c("Year_Building","Year", "Building","County","State","Location.Region","Census.Division", "Census.Region", "ASHRAE.IECC.Climate.Zone.2004", "PUMA", "ISO.RTO.Region", "Geometry.Building.Type.ACS","Geometry.Building.Type.RECS",
                            "Vintage","Vintage.ACS","Heating.Fuel","Geometry.Floor.Area","Geometry.Foundation.Type","Geometry.Wall.Type","Geometry.Stories","Geometry.Garage",
                            "HVAC.Heating.Type.And.Fuel","HVAC.Heating.Efficiency","HVAC.Cooling.Type","HVAC.Cooling.Efficiency","Water.Heater.Fuel","Water.Heater.Efficiency",
                            "Clothes.Dryer","Infiltration")] # currently comes to 29 columns, without "change_cren","change_iren","change_wren","change_hren", "base_weight". Add these in for consistency
bs_hiDR_DE[,c("change_cren","change_iren","change_wren","change_hren")]<-0

bs_hiDR_DE$base_weight<-0
# add base weights for each sim year, based on the new construction estimates
for (y in seq(2025,2060,5)) {
  bs_hiDR_DE[bs_hiDR_DE$Year==y,]$base_weight<-nce[nce$Year==y,]$hiDR/15000
}

bs_hiDR_DE$Type3<-'MF'
bs_hiDR_DE[bs_hiDR_DE$Geometry.Building.Type.RECS=='Mobile Home',]$Type3<-'MH'
bs_hiDR_DE[bs_hiDR_DE$Geometry.Building.Type.RECS %in% c('Single-Family Detached','Single-Family Attached'),]$Type3<-'SF'

names(stcy_comp_hiDR)[c(2,4,8)]<-c('Vintage.ACS','Type3','base_weight_STCY')
bs_hiDR_DE<-merge(bs_hiDR_DE,stcy_comp_hiDR[,c('Year','State','Type3','Vintage.ACS','base_weight_STCY')],by=c('Year','State','Type3','Vintage.ACS'))

bs_hiDR_DE$TC<-"MF"
bs_hiDR_DE[bs_hiDR_DE$Geometry.Building.Type.RECS=="Single-Family Attached" | bs_hiDR_DE$Geometry.Building.Type.RECS=="Single-Family Detached",]$TC<-"SF"
bs_hiDR_DE[bs_hiDR_DE$Geometry.Building.Type.RECS=="Mobile Home",]$TC<-"MH"
bs_hiDR_DE$TC<-paste(bs_hiDR_DE$TC,bs_hiDR_DE$Vintage.ACS,sep="_")
bs_hiDR_DE$ctyTC<-paste(bs_hiDR_DE$County,bs_hiDR_DE$TC,sep = "")
bs_hiDR_DE$ctyTC<-gsub("2010s","2010-19",bs_hiDR_DE$ctyTC)
bs_hiDR_DE$ctyTC<-gsub("2020s","2020-29",bs_hiDR_DE$ctyTC)
bs_hiDR_DE$ctyTC<-gsub("2030s","2030-39",bs_hiDR_DE$ctyTC)
bs_hiDR_DE$ctyTC<-gsub("2040s","2040-49",bs_hiDR_DE$ctyTC)
bs_hiDR_DE$ctyTC<-gsub("2050s","2050-60",bs_hiDR_DE$ctyTC)

bs_hiDR_DE<-left_join(bs_hiDR_DE,shdrm,by="ctyTC")

# merge with the energy results
rshdrDE_sum<-result_sum(rshiDR_DE,0)
rshdrDE_sum<-rshdrDE_sum[,c(1:3,23,43,44,55:63,66,81,82,88,95,103,105:111,113:122,124:129,131,133,135:141,148:200)] # bigger version

rs_hiDRDE<-merge(bs_hiDR_DE,rshdrDE_sum,by.x = "Building",by.y = "building_id")
rs_hiDRDE<-rs_hiDRDE[,-c(which(names(rs_hiDRDE) %in% c("Year.y", "Year_Building.y")))]
rs_hiDRDE<-rs_hiDRDE %>% rename(Year_Building = Year_Building.x, Year = Year.x)

# add GHG intensities, Mid-Case
rs_hiDRDE<-left_join(rs_hiDRDE,gic,by = c("County" = "RS_ID"))
# add GHG intensities, Low RE Cost
rs_hiDRDE<-left_join(rs_hiDRDE,gic_LRE,by = c("County" = "RS_ID"))

rs_hiDRDE[rs_hiDRDE$Year==2030,]$whiDR_2025<-0
rs_hiDRDE[rs_hiDRDE$Year==2040,]$whiDR_2035<-0
rs_hiDRDE[rs_hiDRDE$Year==2050,]$whiDR_2045<-0
rs_hiDRDE[rs_hiDRDE$Year==2060,]$whiDR_2055<-0

rs_hiDRDE[,c("Tot_GJ_hiDR_2020",  "Tot_GJ_hiDR_2025","Tot_GJ_hiDR_2030","Tot_GJ_hiDR_2035","Tot_GJ_hiDR_2040","Tot_GJ_hiDR_2045","Tot_GJ_hiDR_2050","Tot_GJ_hiDR_2055","Tot_GJ_hiDR_2060")]<-
  (rs_hiDRDE$base_weight_STCY*rs_hiDRDE[,c("whiDR_2020", "whiDR_2025", "whiDR_2030", "whiDR_2035", "whiDR_2040", "whiDR_2045", "whiDR_2050", "whiDR_2055", "whiDR_2060")])*
  (rs_hiDRDE$Elec_GJ+rs_hiDRDE$Gas_GJ+rs_hiDRDE$Prop_GJ+rs_hiDRDE$Oil_GJ)

# tot kgGHG per archetype group/year in kg
rs_hiDRDE[,c("EnGHGkg_hiDR_2020","EnGHGkg_hiDR_2025","EnGHGkg_hiDR_2030","EnGHGkg_hiDR_2035","EnGHGkg_hiDR_2040","EnGHGkg_hiDR_2045","EnGHGkg_hiDR_2050","EnGHGkg_hiDR_2055","EnGHGkg_hiDR_2060")]<-1000* 
  (rs_hiDRDE$base_weight_STCY*rs_hiDRDE[,c("whiDR_2020",  "whiDR_2025", "whiDR_2030", "whiDR_2035", "whiDR_2040", "whiDR_2045", "whiDR_2050", "whiDR_2055", "whiDR_2060")])*
  (rs_hiDRDE$Elec_GJ*rs_hiDRDE[,c("GHG_int_2020", "GHG_int_2025","GHG_int_2030","GHG_int_2035","GHG_int_2040","GHG_int_2045","GHG_int_2050","GHG_int_2055","GHG_int_2060")]+
     matrix(rep(rs_hiDRDE$Gas_GJ*GHGI_NG,9),nrow(rs_hiDRDE),9)+ matrix(rep(rs_hiDRDE$Oil_GJ*GHGI_FO,9),nrow(rs_hiDRDE),9)+ matrix(rep(rs_hiDRDE$Prop_GJ*GHGI_LP,9),nrow(rs_hiDRDE),9))

# tot LRE kgGHG per archetype group/year in kg
rs_hiDRDE[,c("EnGHGkg_hiDR_2020_LRE","EnGHGkg_hiDR_2025_LRE","EnGHGkg_hiDR_2030_LRE","EnGHGkg_hiDR_2035_LRE","EnGHGkg_hiDR_2040_LRE","EnGHGkg_hiDR_2045_LRE","EnGHGkg_hiDR_2050_LRE","EnGHGkg_hiDR_2055_LRE","EnGHGkg_hiDR_2060_LRE")]<-1000* 
  (rs_hiDRDE$base_weight_STCY*rs_hiDRDE[,c("whiDR_2020",  "whiDR_2025", "whiDR_2030", "whiDR_2035", "whiDR_2040", "whiDR_2045", "whiDR_2050", "whiDR_2055", "whiDR_2060")])*
  (rs_hiDRDE$Elec_GJ*rs_hiDRDE[,c("GHG_int_2020_LRE", "GHG_int_2025_LRE","GHG_int_2030_LRE","GHG_int_2035_LRE","GHG_int_2040_LRE","GHG_int_2045_LRE","GHG_int_2050_LRE","GHG_int_2055_LRE","GHG_int_2060_LRE")]+
     matrix(rep(rs_hiDRDE$Gas_GJ*GHGI_NG,9),nrow(rs_hiDRDE),9)+ matrix(rep(rs_hiDRDE$Oil_GJ*GHGI_FO,9),nrow(rs_hiDRDE),9)+ matrix(rep(rs_hiDRDE$Prop_GJ*GHGI_LP,9),nrow(rs_hiDRDE),9))

save(rs_hiDRDE,file="../Intermediate_results/rs_hiDRDE_EG.RData") 

# now merge with the AR/RR files
n1<-names(rs_RRn) # <2020 stock, Reg Ren
n2<-names(rs_hiDRDE) # new construction

# check the GHG ints in the two files
G1<-unique(rs_RRn[,c('County','GHG_int_2020')])
names(G1)[2]<-'GHG_int_2020_ex'
G2<-unique(rs_hiDRDE[,c('County','GHG_int_2020')])
names(G2)[2]<-'GHG_int_2020_nc'
G3<-merge(G2,G1)
print(all(G3$GHG_int_2020_nc==G3$GHG_int_2020_ex))

# before binding rows, make the Building codes in rs_hiDRDE distinct from those in rs_RRn
rs_hiDRDE$Building<-180000+rs_hiDRDE$Building
rs_hiDRDE$Year_Building<-paste(rs_hiDRDE$Year,rs_hiDRDE$Building,sep="_")

rs_hiDRDE_all_RR<-bind_rows(rs_RRn,rs_hiDRDE)

rs_hiDRDE_all_RR<-rs_hiDRDE_all_RR[,names(rs_hiDRDE_all_RR) %in% names(rs_hiDRDE)]

rs_hiDRDE_all_RR[is.na(rs_hiDRDE_all_RR$base_weight_STCY), ]$base_weight_STCY<-0 # this can be a little slow/sticky
rs_hiDRDE_all_RR[rs_hiDRDE_all_RR$base_weight_STCY==0,]$base_weight_STCY<-rs_hiDRDE_all_RR[rs_hiDRDE_all_RR$base_weight_STCY==0,]$base_weight_STCY+rs_hiDRDE_all_RR[rs_hiDRDE_all_RR$base_weight_STCY==0,]$base_weight

# example of calculating national level emissions in each year , except without construction related emissions
colSums(rs_hiDRDE_all_RR[,176:184])*1e-9 # 
# example of calculating national level emissions in each year , LRE elec
colSums(rs_hiDRDE_all_RR[,185:193])*1e-9 # 

save(rs_hiDRDE_all_RR,file="../Final_results/res_hiDRDE_RR.RData")
rm(rs_hiDRDE_all_RR)
# now advanced ren
n1<-names(rs_ARn) # <2020 stock, Adv Ren
n2<-names(rs_hiDRDE) # new construction

# check the GHG ints in the two files
G1<-unique(rs_ARn[,c('County','GHG_int_2020')])
names(G1)[2]<-'GHG_int_2020_ex'
G2<-unique(rs_hiDRDE[,c('County','GHG_int_2020')])
names(G2)[2]<-'GHG_int_2020_nc'
G3<-merge(G2,G1)
print(all(G3$GHG_int_2020_nc==G3$GHG_int_2020_ex))

rs_hiDRDE_all_AR<-bind_rows(rs_ARn,rs_hiDRDE)

rs_hiDRDE_all_AR<-rs_hiDRDE_all_AR[,names(rs_hiDRDE_all_AR) %in% names(rs_hiDRDE)]

rs_hiDRDE_all_AR[is.na(rs_hiDRDE_all_AR$base_weight_STCY), ]$base_weight_STCY<-0 # this can be a little slow/sticky
rs_hiDRDE_all_AR[rs_hiDRDE_all_AR$base_weight_STCY==0,]$base_weight_STCY<-rs_hiDRDE_all_AR[rs_hiDRDE_all_AR$base_weight_STCY==0,]$base_weight_STCY+rs_hiDRDE_all_AR[rs_hiDRDE_all_AR$base_weight_STCY==0,]$base_weight

# example of calculating national level emissions in each year , except without construction related emissions
colSums(rs_hiDRDE_all_AR[,176:184])*1e-9 # 
# example of calculating national level emissions in each year , LREC
colSums(rs_hiDRDE_all_AR[,185:193])*1e-9 # 

save(rs_hiDRDE_all_AR,file="../Final_results/res_hiDRDE_AR.RData")
rm(rs_hiDRDE_all_AR)
# now extensive ren
n1<-names(rs_ERn) # <2020 stock, Ext Ren
n2<-names(rs_hiDRDE) # new construction

# check the GHG ints in the two files
G1<-unique(rs_ERn[,c('County','GHG_int_2020')])
names(G1)[2]<-'GHG_int_2020_ex'
G2<-unique(rs_hiDRDE[,c('County','GHG_int_2020')])
names(G2)[2]<-'GHG_int_2020_nc'
G3<-merge(G2,G1)
print(all(G3$GHG_int_2020_nc==G3$GHG_int_2020_ex))

rs_hiDRDE_all_ER<-bind_rows(rs_ERn,rs_hiDRDE)

rs_hiDRDE_all_ER<-rs_hiDRDE_all_ER[,names(rs_hiDRDE_all_ER) %in% names(rs_hiDRDE)]

rs_hiDRDE_all_ER[is.na(rs_hiDRDE_all_ER$base_weight_STCY), ]$base_weight_STCY<-0 # this can be a little slow/sticky
rs_hiDRDE_all_ER[rs_hiDRDE_all_ER$base_weight_STCY==0,]$base_weight_STCY<-rs_hiDRDE_all_ER[rs_hiDRDE_all_ER$base_weight_STCY==0,]$base_weight_STCY+rs_hiDRDE_all_ER[rs_hiDRDE_all_ER$base_weight_STCY==0,]$base_weight

# example of calculating national level emissions in each year , except without construction related emissions
colSums(rs_hiDRDE_all_ER[,176:184])*1e-9 # 
# example of calculating national level emissions in each year , LREC
colSums(rs_hiDRDE_all_ER[,185:193])*1e-9 # 

save(rs_hiDRDE_all_ER,file="../Final_results/res_hiDRDE_ER.RData")
rm(rs_hiDRDE_all_ER)
rm(rshiDR_DE)
rm(rs_hiDRDE)
# load in projection results, hiDRDERFA ######
# 8 of 12 stock projection results: hiDR stock, DERFA NHC
print('hiDR 8')
load("../Eagle_outputs/Complete_results/res_hiDRDERFA_final.RData")
rshiDR_DERFA<-rsn
rm(rsn)

bs_hiDR_DERFA<-bs_hiDR_all[bs_hiDR_all$scen=="hiDRDERFA",]
bs_hiDR_DERFA$Year<-bs_hiDR_DERFA$sim_year

bs_hiDR_DERFA$Year_Building<-paste(bs_hiDR_DERFA$Year,bs_hiDR_DERFA$Building,sep="_")

bs_hiDR_DERFA<-bs_hiDR_DERFA[,c("Year_Building","Year", "Building","County","State","Location.Region","Census.Division", "Census.Region", "ASHRAE.IECC.Climate.Zone.2004", "PUMA", "ISO.RTO.Region", "Geometry.Building.Type.ACS","Geometry.Building.Type.RECS",
                          "Vintage","Vintage.ACS","Heating.Fuel","Geometry.Floor.Area","Geometry.Foundation.Type","Geometry.Wall.Type","Geometry.Stories","Geometry.Garage",
                          "HVAC.Heating.Type.And.Fuel","HVAC.Heating.Efficiency","HVAC.Cooling.Type","HVAC.Cooling.Efficiency","Water.Heater.Fuel","Water.Heater.Efficiency",
                          "Clothes.Dryer","Infiltration")] # currently comes to 29 columns, without "change_cren","change_iren","change_wren","change_hren", "base_weight". Add these in for consistency
bs_hiDR_DERFA[,c("change_cren","change_iren","change_wren","change_hren")]<-0

bs_hiDR_DERFA$base_weight<-0
# add base weights for each sim year, based on the new construction estimates
for (y in seq(2025,2060,5)) {
  bs_hiDR_DERFA[bs_hiDR_DERFA$Year==y,]$base_weight<-nce[nce$Year==y,]$hiDR/15000
}

bs_hiDR_DERFA$Type3<-'MF'
bs_hiDR_DERFA[bs_hiDR_DERFA$Geometry.Building.Type.RECS=='Mobile Home',]$Type3<-'MH'
bs_hiDR_DERFA[bs_hiDR_DERFA$Geometry.Building.Type.RECS %in% c('Single-Family Detached','Single-Family Attached'),]$Type3<-'SF'

names(stcy_comp_hiDR)[c(2,4,8)]<-c('Vintage.ACS','Type3','base_weight_STCY')
bs_hiDR_DERFA<-merge(bs_hiDR_DERFA,stcy_comp_hiDR[,c('Year','State','Type3','Vintage.ACS','base_weight_STCY')],by=c('Year','State','Type3','Vintage.ACS'))

bs_hiDR_DERFA$TC<-"MF"
bs_hiDR_DERFA[bs_hiDR_DERFA$Geometry.Building.Type.RECS=="Single-Family Attached" | bs_hiDR_DERFA$Geometry.Building.Type.RECS=="Single-Family Detached",]$TC<-"SF"
bs_hiDR_DERFA[bs_hiDR_DERFA$Geometry.Building.Type.RECS=="Mobile Home",]$TC<-"MH"
bs_hiDR_DERFA$TC<-paste(bs_hiDR_DERFA$TC,bs_hiDR_DERFA$Vintage.ACS,sep="_")
bs_hiDR_DERFA$ctyTC<-paste(bs_hiDR_DERFA$County,bs_hiDR_DERFA$TC,sep = "")
bs_hiDR_DERFA$ctyTC<-gsub("2010s","2010-19",bs_hiDR_DERFA$ctyTC)
bs_hiDR_DERFA$ctyTC<-gsub("2020s","2020-29",bs_hiDR_DERFA$ctyTC)
bs_hiDR_DERFA$ctyTC<-gsub("2030s","2030-39",bs_hiDR_DERFA$ctyTC)
bs_hiDR_DERFA$ctyTC<-gsub("2040s","2040-49",bs_hiDR_DERFA$ctyTC)
bs_hiDR_DERFA$ctyTC<-gsub("2050s","2050-60",bs_hiDR_DERFA$ctyTC)

bs_hiDR_DERFA<-left_join(bs_hiDR_DERFA,shdrm,by="ctyTC")

# merge with the energy results
rshdrDERFA_sum<-result_sum(rshiDR_DERFA,0)
rshdrDERFA_sum<-rshdrDERFA_sum[,c(1:3,23,43,44,55:63,66,81,82,88,95,103,105:111,113:122,124:129,131,133,135:141,148:200)] # bigger version

rs_hiDRDERFA<-merge(bs_hiDR_DERFA,rshdrDERFA_sum,by.x = "Building",by.y = "building_id")
rs_hiDRDERFA<-rs_hiDRDERFA[,-c(which(names(rs_hiDRDERFA) %in% c("Year.y", "Year_Building.y")))]
rs_hiDRDERFA<-rs_hiDRDERFA %>% rename(Year_Building = Year_Building.x, Year = Year.x) #

# add GHG intensities, Mid-Case
rs_hiDRDERFA<-left_join(rs_hiDRDERFA,gic,by = c("County" = "RS_ID"))
# add GHG intensities, Low RE Cost
rs_hiDRDERFA<-left_join(rs_hiDRDERFA,gic_LRE,by = c("County" = "RS_ID"))

rs_hiDRDERFA[rs_hiDRDERFA$Year==2030,]$whiDR_2025<-0
rs_hiDRDERFA[rs_hiDRDERFA$Year==2040,]$whiDR_2035<-0
rs_hiDRDERFA[rs_hiDRDERFA$Year==2050,]$whiDR_2045<-0
rs_hiDRDERFA[rs_hiDRDERFA$Year==2060,]$whiDR_2055<-0

rs_hiDRDERFA[,c("Tot_GJ_hiDR_2020",  "Tot_GJ_hiDR_2025","Tot_GJ_hiDR_2030","Tot_GJ_hiDR_2035","Tot_GJ_hiDR_2040","Tot_GJ_hiDR_2045","Tot_GJ_hiDR_2050","Tot_GJ_hiDR_2055","Tot_GJ_hiDR_2060")]<-
  (rs_hiDRDERFA$base_weight_STCY*rs_hiDRDERFA[,c("whiDR_2020", "whiDR_2025", "whiDR_2030", "whiDR_2035", "whiDR_2040", "whiDR_2045", "whiDR_2050", "whiDR_2055", "whiDR_2060")])*
  (rs_hiDRDERFA$Elec_GJ+rs_hiDRDERFA$Gas_GJ+rs_hiDRDERFA$Prop_GJ+rs_hiDRDERFA$Oil_GJ)

# tot kgGHG per archetype group/year in kg
rs_hiDRDERFA[,c("EnGHGkg_hiDR_2020","EnGHGkg_hiDR_2025","EnGHGkg_hiDR_2030","EnGHGkg_hiDR_2035","EnGHGkg_hiDR_2040","EnGHGkg_hiDR_2045","EnGHGkg_hiDR_2050","EnGHGkg_hiDR_2055","EnGHGkg_hiDR_2060")]<-1000* 
  (rs_hiDRDERFA$base_weight_STCY*rs_hiDRDERFA[,c("whiDR_2020",  "whiDR_2025", "whiDR_2030", "whiDR_2035", "whiDR_2040", "whiDR_2045", "whiDR_2050", "whiDR_2055", "whiDR_2060")])*
  (rs_hiDRDERFA$Elec_GJ*rs_hiDRDERFA[,c("GHG_int_2020", "GHG_int_2025","GHG_int_2030","GHG_int_2035","GHG_int_2040","GHG_int_2045","GHG_int_2050","GHG_int_2055","GHG_int_2060")]+
     matrix(rep(rs_hiDRDERFA$Gas_GJ*GHGI_NG,9),nrow(rs_hiDRDERFA),9)+ matrix(rep(rs_hiDRDERFA$Oil_GJ*GHGI_FO,9),nrow(rs_hiDRDERFA),9)+ matrix(rep(rs_hiDRDERFA$Prop_GJ*GHGI_LP,9),nrow(rs_hiDRDERFA),9))

# tot LRE kgGHG per archetype group/year in kg
rs_hiDRDERFA[,c("EnGHGkg_hiDR_2020_LRE","EnGHGkg_hiDR_2025_LRE","EnGHGkg_hiDR_2030_LRE","EnGHGkg_hiDR_2035_LRE","EnGHGkg_hiDR_2040_LRE","EnGHGkg_hiDR_2045_LRE","EnGHGkg_hiDR_2050_LRE","EnGHGkg_hiDR_2055_LRE","EnGHGkg_hiDR_2060_LRE")]<-1000* 
  (rs_hiDRDERFA$base_weight_STCY*rs_hiDRDERFA[,c("whiDR_2020",  "whiDR_2025", "whiDR_2030", "whiDR_2035", "whiDR_2040", "whiDR_2045", "whiDR_2050", "whiDR_2055", "whiDR_2060")])*
  (rs_hiDRDERFA$Elec_GJ*rs_hiDRDERFA[,c("GHG_int_2020_LRE", "GHG_int_2025_LRE","GHG_int_2030_LRE","GHG_int_2035_LRE","GHG_int_2040_LRE","GHG_int_2045_LRE","GHG_int_2050_LRE","GHG_int_2055_LRE","GHG_int_2060_LRE")]+
     matrix(rep(rs_hiDRDERFA$Gas_GJ*GHGI_NG,9),nrow(rs_hiDRDERFA),9)+ matrix(rep(rs_hiDRDERFA$Oil_GJ*GHGI_FO,9),nrow(rs_hiDRDERFA),9)+ matrix(rep(rs_hiDRDERFA$Prop_GJ*GHGI_LP,9),nrow(rs_hiDRDERFA),9))

save(rs_hiDRDERFA,file="../Intermediate_results/rs_hiDRDERFA_EG.RData")

# now merge with the AR/RR files
n1<-names(rs_RRn) # <2020 stock, Reg Ren
n2<-names(rs_hiDRDERFA) # new construction

# check the GHG ints in the two files
G1<-unique(rs_RRn[,c('County','GHG_int_2020')])
names(G1)[2]<-'GHG_int_2020_ex'
G2<-unique(rs_hiDRDERFA[,c('County','GHG_int_2020')])
names(G2)[2]<-'GHG_int_2020_nc'
G3<-merge(G2,G1)
print(all(G3$GHG_int_2020_nc==G3$GHG_int_2020_ex))

# before binding rows, make the Building codes in rs_hiDRDERFA distinct from those in rs_RRn
rs_hiDRDERFA$Building<-180000+rs_hiDRDERFA$Building
rs_hiDRDERFA$Year_Building<-paste(rs_hiDRDERFA$Year,rs_hiDRDERFA$Building,sep="_")

rs_hiDRDERFA_all_RR<-bind_rows(rs_RRn,rs_hiDRDERFA)

rs_hiDRDERFA_all_RR<-rs_hiDRDERFA_all_RR[,names(rs_hiDRDERFA_all_RR) %in% names(rs_hiDRDERFA)]

rs_hiDRDERFA_all_RR[is.na(rs_hiDRDERFA_all_RR$base_weight_STCY), ]$base_weight_STCY<-0 # this can be a little slow/sticky
rs_hiDRDERFA_all_RR[rs_hiDRDERFA_all_RR$base_weight_STCY==0,]$base_weight_STCY<-rs_hiDRDERFA_all_RR[rs_hiDRDERFA_all_RR$base_weight_STCY==0,]$base_weight_STCY+rs_hiDRDERFA_all_RR[rs_hiDRDERFA_all_RR$base_weight_STCY==0,]$base_weight

# example of calculating national level emissions in each year , except without construction related emissions
colSums(rs_hiDRDERFA_all_RR[,176:184])*1e-9 # 
# example of calculating national level emissions in each year , LRE elec
colSums(rs_hiDRDERFA_all_RR[,185:193])*1e-9 # 

save(rs_hiDRDERFA_all_RR,file="../Final_results/res_hiDRDERFA_RR.RData")
rm(rs_hiDRDERFA_all_RR)
# now advanced ren
n1<-names(rs_ARn) # <2020 stock, Reg Ren
n2<-names(rs_hiDRDERFA) # new construction

# check the GHG ints in the two files
G1<-unique(rs_ARn[,c('County','GHG_int_2020')])
names(G1)[2]<-'GHG_int_2020_ex'
G2<-unique(rs_hiDRDERFA[,c('County','GHG_int_2020')])
names(G2)[2]<-'GHG_int_2020_nc'
G3<-merge(G2,G1)
print(all(G3$GHG_int_2020_nc==G3$GHG_int_2020_ex))

rs_hiDRDERFA_all_AR<-bind_rows(rs_ARn,rs_hiDRDERFA)

rs_hiDRDERFA_all_AR<-rs_hiDRDERFA_all_AR[,names(rs_hiDRDERFA_all_AR) %in% names(rs_hiDRDERFA)]

rs_hiDRDERFA_all_AR[is.na(rs_hiDRDERFA_all_AR$base_weight_STCY), ]$base_weight_STCY<-0 # this can be a little slow/sticky
rs_hiDRDERFA_all_AR[rs_hiDRDERFA_all_AR$base_weight_STCY==0,]$base_weight_STCY<-rs_hiDRDERFA_all_AR[rs_hiDRDERFA_all_AR$base_weight_STCY==0,]$base_weight_STCY+rs_hiDRDERFA_all_AR[rs_hiDRDERFA_all_AR$base_weight_STCY==0,]$base_weight

# example of calculating national level emissions in each year , except without construction related emissions
colSums(rs_hiDRDERFA_all_AR[,176:184])*1e-9 # 
# example of calculating national level emissions in each year , LREC
colSums(rs_hiDRDERFA_all_AR[,185:193])*1e-9 #

save(rs_hiDRDERFA_all_AR,file="../Final_results/res_hiDRDERFA_AR.RData")
rm(rs_hiDRDERFA_all_AR)
# now extensive ren
n1<-names(rs_ERn) # <2020 stock, Reg Ren
n2<-names(rs_hiDRDERFA) # new construction

# check the GHG ints in the two files
G1<-unique(rs_ERn[,c('County','GHG_int_2020')])
names(G1)[2]<-'GHG_int_2020_ex'
G2<-unique(rs_hiDRDERFA[,c('County','GHG_int_2020')])
names(G2)[2]<-'GHG_int_2020_nc'
G3<-merge(G2,G1)
print(all(G3$GHG_int_2020_nc==G3$GHG_int_2020_ex))

rs_hiDRDERFA_all_ER<-bind_rows(rs_ERn,rs_hiDRDERFA)

rs_hiDRDERFA_all_ER<-rs_hiDRDERFA_all_ER[,names(rs_hiDRDERFA_all_ER) %in% names(rs_hiDRDERFA)]

rs_hiDRDERFA_all_ER[is.na(rs_hiDRDERFA_all_ER$base_weight_STCY), ]$base_weight_STCY<-0 # this can be a little slow/sticky
rs_hiDRDERFA_all_ER[rs_hiDRDERFA_all_ER$base_weight_STCY==0,]$base_weight_STCY<-rs_hiDRDERFA_all_ER[rs_hiDRDERFA_all_ER$base_weight_STCY==0,]$base_weight_STCY+rs_hiDRDERFA_all_ER[rs_hiDRDERFA_all_ER$base_weight_STCY==0,]$base_weight

# example of calculating national level emissions in each year , except without construction related emissions
colSums(rs_hiDRDERFA_all_ER[,176:184])*1e-9 # 
# example of calculating national level emissions in each year , LREC
colSums(rs_hiDRDERFA_all_ER[,185:193])*1e-9 #

save(rs_hiDRDERFA_all_ER,file="../Final_results/res_hiDRDERFA_ER.RData")
rm(rs_hiDRDERFA_all_ER)
rm(rshiDR_DERFA)
rm(rs_hiDRDERFA)
# finally the hi MF scenarios #############
# load in projection results, hiDR ######
# 9 of 12 stock projection results: hiMF stock, base NHC
print('hiMF 9')
load("../Eagle_outputs/Complete_results/res_hiMF_final.RData")
rshiMF_base<-rsn
rm(rsn)

bs_hiMF_base<-bs_hiMF_all[bs_hiMF_all$scen=="hiMF",]
bs_hiMF_base$Year<-bs_hiMF_base$sim_year

bs_hiMF_base$Year_Building<-paste(bs_hiMF_base$Year,bs_hiMF_base$Building,sep="_")

bs_hiMF_base<-bs_hiMF_base[,c("Year_Building","Year", "Building","County","State","Location.Region","Census.Division", "Census.Region", "ASHRAE.IECC.Climate.Zone.2004", "PUMA", "ISO.RTO.Region", "Geometry.Building.Type.ACS","Geometry.Building.Type.RECS",
                              "Vintage","Vintage.ACS","Heating.Fuel","Geometry.Floor.Area","Geometry.Foundation.Type","Geometry.Wall.Type","Geometry.Stories","Geometry.Garage",
                              "HVAC.Heating.Type.And.Fuel","HVAC.Heating.Efficiency","HVAC.Cooling.Type","HVAC.Cooling.Efficiency","Water.Heater.Fuel","Water.Heater.Efficiency",
                              "Clothes.Dryer","Infiltration")] # currently comes to 29 columns, without "change_cren","change_iren","change_wren","change_hren", "base_weight". Add these in for consistency
bs_hiMF_base[,c("change_cren","change_iren","change_wren","change_hren")]<-0

bs_hiMF_base$base_weight<-0
# add base weights for each sim year, based on the new construction estimates
for (y in seq(2025,2060,5)) {
  bs_hiMF_base[bs_hiMF_base$Year==y,]$base_weight<-nce[nce$Year==y,]$hiMF/15000
}
bs_hiMF_base$Type3<-'MF'
bs_hiMF_base[bs_hiMF_base$Geometry.Building.Type.RECS=='Mobile Home',]$Type3<-'MH'
bs_hiMF_base[bs_hiMF_base$Geometry.Building.Type.RECS %in% c('Single-Family Detached','Single-Family Attached'),]$Type3<-'SF'

names(stcy_comp_hiMF)[c(2,4,8)]<-c('Vintage.ACS','Type3','base_weight_STCY')
bs_hiMF_base<-merge(bs_hiMF_base,stcy_comp_hiMF[,c('Year','State','Type3','Vintage.ACS','base_weight_STCY')],by=c('Year','State','Type3','Vintage.ACS'))

bs_hiMF_base$TC<-"MF"
bs_hiMF_base[bs_hiMF_base$Geometry.Building.Type.RECS=="Single-Family Attached" | bs_hiMF_base$Geometry.Building.Type.RECS=="Single-Family Detached",]$TC<-"SF"
bs_hiMF_base[bs_hiMF_base$Geometry.Building.Type.RECS=="Mobile Home",]$TC<-"MH"
bs_hiMF_base$TC<-paste(bs_hiMF_base$TC,bs_hiMF_base$Vintage.ACS,sep="_")
bs_hiMF_base$ctyTC<-paste(bs_hiMF_base$County,bs_hiMF_base$TC,sep = "")
bs_hiMF_base$ctyTC<-gsub("2010s","2010-19",bs_hiMF_base$ctyTC)
bs_hiMF_base$ctyTC<-gsub("2020s","2020-29",bs_hiMF_base$ctyTC)
bs_hiMF_base$ctyTC<-gsub("2030s","2030-39",bs_hiMF_base$ctyTC)
bs_hiMF_base$ctyTC<-gsub("2040s","2040-49",bs_hiMF_base$ctyTC)
bs_hiMF_base$ctyTC<-gsub("2050s","2050-60",bs_hiMF_base$ctyTC)

bs_hiMF_base<-left_join(bs_hiMF_base,shmfm,by="ctyTC")

# merge with the energy results
rshmfb_sum<-result_sum(rshiMF_base,0)
rshmfb_sum<-rshmfb_sum[,c(1:3,23,43,44,55:63,66,81,82,88,95,103,105:111,113:122,124:129,131,133,135:141,148:200)] # bigger version

rs_hiMF<-merge(bs_hiMF_base,rshmfb_sum,by.x = "Building",by.y = "building_id")
rs_hiMF<-rs_hiMF[,-c(which(names(rs_hiMF) %in% c("Year.y", "Year_Building.y")))]
rs_hiMF<-rs_hiMF %>% rename(Year_Building = Year_Building.x, Year = Year.x)

# add GHG intensities, Mid-Case
rs_hiMF<-left_join(rs_hiMF,gic,by = c("County" = "RS_ID"))
# add GHG intensities, Low RE Cost
rs_hiMF<-left_join(rs_hiMF,gic_LRE,by = c("County" = "RS_ID"))

rs_hiMF[rs_hiMF$Year==2030,]$whiMF_2025<-0
rs_hiMF[rs_hiMF$Year==2040,]$whiMF_2035<-0
rs_hiMF[rs_hiMF$Year==2050,]$whiMF_2045<-0
rs_hiMF[rs_hiMF$Year==2060,]$whiMF_2055<-0

rs_hiMF[,c("Tot_GJ_hiMF_2020",  "Tot_GJ_hiMF_2025","Tot_GJ_hiMF_2030","Tot_GJ_hiMF_2035","Tot_GJ_hiMF_2040","Tot_GJ_hiMF_2045","Tot_GJ_hiMF_2050","Tot_GJ_hiMF_2055","Tot_GJ_hiMF_2060")]<-
  (rs_hiMF$base_weight_STCY*rs_hiMF[,c("whiMF_2020", "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")])*
  (rs_hiMF$Elec_GJ+rs_hiMF$Gas_GJ+rs_hiMF$Prop_GJ+rs_hiMF$Oil_GJ)

# tot kgGHG per archetype group/year in kg
rs_hiMF[,c("EnGHGkg_hiMF_2020","EnGHGkg_hiMF_2025","EnGHGkg_hiMF_2030","EnGHGkg_hiMF_2035","EnGHGkg_hiMF_2040","EnGHGkg_hiMF_2045","EnGHGkg_hiMF_2050","EnGHGkg_hiMF_2055","EnGHGkg_hiMF_2060")]<-1000* 
  (rs_hiMF$base_weight_STCY*rs_hiMF[,c("whiMF_2020",  "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")])*
  (rs_hiMF$Elec_GJ*rs_hiMF[,c("GHG_int_2020", "GHG_int_2025","GHG_int_2030","GHG_int_2035","GHG_int_2040","GHG_int_2045","GHG_int_2050","GHG_int_2055","GHG_int_2060")]+
     matrix(rep(rs_hiMF$Gas_GJ*GHGI_NG,9),nrow(rs_hiMF),9)+ matrix(rep(rs_hiMF$Oil_GJ*GHGI_FO,9),nrow(rs_hiMF),9)+ matrix(rep(rs_hiMF$Prop_GJ*GHGI_LP,9),nrow(rs_hiMF),9))

# tot LRE kgGHG per archetype group/year in kg
rs_hiMF[,c("EnGHGkg_hiMF_2020_LRE","EnGHGkg_hiMF_2025_LRE","EnGHGkg_hiMF_2030_LRE","EnGHGkg_hiMF_2035_LRE","EnGHGkg_hiMF_2040_LRE","EnGHGkg_hiMF_2045_LRE","EnGHGkg_hiMF_2050_LRE","EnGHGkg_hiMF_2055_LRE","EnGHGkg_hiMF_2060_LRE")]<-1000* 
  (rs_hiMF$base_weight_STCY*rs_hiMF[,c("whiMF_2020",  "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")])*
  (rs_hiMF$Elec_GJ*rs_hiMF[,c("GHG_int_2020_LRE", "GHG_int_2025_LRE","GHG_int_2030_LRE","GHG_int_2035_LRE","GHG_int_2040_LRE","GHG_int_2045_LRE","GHG_int_2050_LRE","GHG_int_2055_LRE","GHG_int_2060_LRE")]+
     matrix(rep(rs_hiMF$Gas_GJ*GHGI_NG,9),nrow(rs_hiMF),9)+ matrix(rep(rs_hiMF$Oil_GJ*GHGI_FO,9),nrow(rs_hiMF),9)+ matrix(rep(rs_hiMF$Prop_GJ*GHGI_LP,9),nrow(rs_hiMF),9))

save(rs_hiMF,file="../Intermediate_results/rs_hiMF_EG.RData") 
# now  merge with the AR/RR files
n1<-names(rs_RRn) # <2020 stock, Reg Ren
n2<-names(rs_hiMF) # new construction

# check the GHG ints in the two files
G1<-unique(rs_RRn[,c('County','GHG_int_2020')])
names(G1)[2]<-'GHG_int_2020_ex'
G2<-unique(rs_hiMF[,c('County','GHG_int_2020')])
names(G2)[2]<-'GHG_int_2020_nc'
G3<-merge(G2,G1)
print(all(G3$GHG_int_2020_nc==G3$GHG_int_2020_ex))

# before binding rows, make the Building codes in rs_hiMF distinct from those in rs_RRn
rs_hiMF$Building<-180000+rs_hiMF$Building
rs_hiMF$Year_Building<-paste(rs_hiMF$Year,rs_hiMF$Building,sep="_")

rs_hiMF_all_RR<-bind_rows(rs_RRn,rs_hiMF)

rs_hiMF_all_RR<-rs_hiMF_all_RR[,names(rs_hiMF_all_RR) %in% names(rs_hiMF)]

rs_hiMF_all_RR[is.na(rs_hiMF_all_RR$base_weight_STCY), ]$base_weight_STCY<-0 # this can be a little slow/sticky
rs_hiMF_all_RR[rs_hiMF_all_RR$base_weight_STCY==0,]$base_weight_STCY<-rs_hiMF_all_RR[rs_hiMF_all_RR$base_weight_STCY==0,]$base_weight_STCY+rs_hiMF_all_RR[rs_hiMF_all_RR$base_weight_STCY==0,]$base_weight

# example of calculating national level emissions in each year , except without construction related emissions
colSums(rs_hiMF_all_RR[,176:184])*1e-9 # 
# example of calculating national level emissions in each year , LRE elec
colSums(rs_hiMF_all_RR[,185:193])*1e-9 # 

rs_hiMF_all_RR$Type3<-'MF'
rs_hiMF_all_RR[rs_hiMF_all_RR$Geometry.Building.Type.RECS=='Mobile Home',]$Type3<-'MH'
rs_hiMF_all_RR[rs_hiMF_all_RR$Geometry.Building.Type.RECS %in% c('Single-Family Detached','Single-Family Attached'),]$Type3<-'SF'

st40hm<-comp_ests(rs_hiMF_all_RR,2040,'State','whiMF_2040',stock_tsy_hiMF)
st60hm<-comp_ests(rs_hiMF_all_RR,2060,'State','whiMF_2060',stock_tsy_hiMF)

cty50hm<-comp_ests(rs_hiMF_all_RR,2050,'County','whiMF_2050',stock_tcy_hiMF)
st50hm<-comp_ests(rs_hiMF_all_RR,2050,'State','whiMF_2050',stock_tsy_hiMF)

# save the comparisions of stock estiamtes 
# particular non-small counties with strange estimates include St Louis City and County MO, and Denton County TX. The problem here is beyond weighting factors and probably relates to counties not well represented by their puma-averge stock chars.
# These (and other similarly 'out' counties) should be excluded from any county level stock-scenario analysis
save(st40,st40hd,st40hm,st50,st50hd,st50hm,st60,st60hd,st60hm,cty50,cty50hd,cty50hm,base_hiDR_comp_st,file="../Final_results/StockCountComp.RData")

save(rs_hiMF_all_RR,file="../Final_results/res_hiMF_RR.RData")
rm(rs_hiMF_all_RR)
# now advanced ren
n1<-names(rs_ARn) # <2020 stock, Adv Ren
n2<-names(rs_hiMF) # new construction

# check the GHG ints in the two files
G1<-unique(rs_ARn[,c('County','GHG_int_2020')])
names(G1)[2]<-'GHG_int_2020_ex'
G2<-unique(rs_hiMF[,c('County','GHG_int_2020')])
names(G2)[2]<-'GHG_int_2020_nc'
G3<-merge(G2,G1)
print(all(G3$GHG_int_2020_nc==G3$GHG_int_2020_ex))


rs_hiMF_all_AR<-bind_rows(rs_ARn,rs_hiMF)

rs_hiMF_all_AR<-rs_hiMF_all_AR[,names(rs_hiMF_all_AR) %in% names(rs_hiMF)]

rs_hiMF_all_AR[is.na(rs_hiMF_all_AR$base_weight_STCY), ]$base_weight_STCY<-0 # this can be a little slow/sticky
rs_hiMF_all_AR[rs_hiMF_all_AR$base_weight_STCY==0,]$base_weight_STCY<-rs_hiMF_all_AR[rs_hiMF_all_AR$base_weight_STCY==0,]$base_weight_STCY+rs_hiMF_all_AR[rs_hiMF_all_AR$base_weight_STCY==0,]$base_weight

# example of calculating national level emissions in each year , except without construction related emissions
colSums(rs_hiMF_all_AR[,176:184])*1e-9 # 
# example of calculating national level emissions in each year , LREC
colSums(rs_hiMF_all_AR[,185:193])*1e-9 # 

save(rs_hiMF_all_AR,file="../Final_results/res_hiMF_AR.RData")
rm(rs_hiMF_all_AR)
# now extensive ren
n1<-names(rs_ERn) # <2020 stock, Ext Ren
n2<-names(rs_hiMF) # new construction

# check the GHG ints in the two files
G1<-unique(rs_ERn[,c('County','GHG_int_2020')])
names(G1)[2]<-'GHG_int_2020_ex'
G2<-unique(rs_hiMF[,c('County','GHG_int_2020')])
names(G2)[2]<-'GHG_int_2020_nc'
G3<-merge(G2,G1)
print(all(G3$GHG_int_2020_nc==G3$GHG_int_2020_ex))


rs_hiMF_all_ER<-bind_rows(rs_ERn,rs_hiMF)

rs_hiMF_all_ER<-rs_hiMF_all_ER[,names(rs_hiMF_all_ER) %in% names(rs_hiMF)]

rs_hiMF_all_ER[is.na(rs_hiMF_all_ER$base_weight_STCY), ]$base_weight_STCY<-0 # this can be a little slow/sticky
rs_hiMF_all_ER[rs_hiMF_all_ER$base_weight_STCY==0,]$base_weight_STCY<-rs_hiMF_all_ER[rs_hiMF_all_ER$base_weight_STCY==0,]$base_weight_STCY+rs_hiMF_all_ER[rs_hiMF_all_ER$base_weight_STCY==0,]$base_weight

# example of calculating national level emissions in each year , except without construction related emissions
colSums(rs_hiMF_all_ER[,176:184])*1e-9 # 
# example of calculating national level emissions in each year , LREC
colSums(rs_hiMF_all_ER[,185:193])*1e-9 # 

save(rs_hiMF_all_ER,file="../Final_results/res_hiMF_ER.RData")
rm(rs_hiMF_all_ER)
rm(rshiMF_base)
rm(rs_hiMF)
# load in projection results, hiMFRFA ######
# 10 of 12 stock projection results: hiMF stock, RFA NHC
print('hiMF 10')
load("../Eagle_outputs/Complete_results/res_hiMFRFA_final.RData")
rshiMF_RFA<-rsn
rm(rsn)

bs_hiMF_RFA<-bs_hiMF_all[bs_hiMF_all$scen=="hiMFRFA",]
bs_hiMF_RFA$Year<-bs_hiMF_RFA$sim_year

bs_hiMF_RFA$Year_Building<-paste(bs_hiMF_RFA$Year,bs_hiMF_RFA$Building,sep="_")

bs_hiMF_RFA<-bs_hiMF_RFA[,c("Year_Building","Year", "Building","County","State","Location.Region","Census.Division", "Census.Region", "ASHRAE.IECC.Climate.Zone.2004", "PUMA", "ISO.RTO.Region", "Geometry.Building.Type.ACS","Geometry.Building.Type.RECS",
                            "Vintage","Vintage.ACS","Heating.Fuel","Geometry.Floor.Area","Geometry.Foundation.Type","Geometry.Wall.Type","Geometry.Stories","Geometry.Garage",
                            "HVAC.Heating.Type.And.Fuel","HVAC.Heating.Efficiency","HVAC.Cooling.Type","HVAC.Cooling.Efficiency","Water.Heater.Fuel","Water.Heater.Efficiency",
                            "Clothes.Dryer","Infiltration")] # currently comes to 29 columns, without "change_cren","change_iren","change_wren","change_hren", "base_weight". Add these in for consistency
bs_hiMF_RFA[,c("change_cren","change_iren","change_wren","change_hren")]<-0

bs_hiMF_RFA$base_weight<-0
# add base weights for each sim year, based on the new construction estimates
for (y in seq(2025,2060,5)) {
  bs_hiMF_RFA[bs_hiMF_RFA$Year==y,]$base_weight<-nce[nce$Year==y,]$hiMF/15000
}
bs_hiMF_RFA$Type3<-'MF'
bs_hiMF_RFA[bs_hiMF_RFA$Geometry.Building.Type.RECS=='Mobile Home',]$Type3<-'MH'
bs_hiMF_RFA[bs_hiMF_RFA$Geometry.Building.Type.RECS %in% c('Single-Family Detached','Single-Family Attached'),]$Type3<-'SF'

names(stcy_comp_hiMF)[c(2,4,8)]<-c('Vintage.ACS','Type3','base_weight_STCY')
bs_hiMF_RFA<-merge(bs_hiMF_RFA,stcy_comp_hiMF[,c('Year','State','Type3','Vintage.ACS','base_weight_STCY')],by=c('Year','State','Type3','Vintage.ACS'))

bs_hiMF_RFA$TC<-"MF"
bs_hiMF_RFA[bs_hiMF_RFA$Geometry.Building.Type.RECS=="Single-Family Attached" | bs_hiMF_RFA$Geometry.Building.Type.RECS=="Single-Family Detached",]$TC<-"SF"
bs_hiMF_RFA[bs_hiMF_RFA$Geometry.Building.Type.RECS=="Mobile Home",]$TC<-"MH"
bs_hiMF_RFA$TC<-paste(bs_hiMF_RFA$TC,bs_hiMF_RFA$Vintage.ACS,sep="_")
bs_hiMF_RFA$ctyTC<-paste(bs_hiMF_RFA$County,bs_hiMF_RFA$TC,sep = "")
bs_hiMF_RFA$ctyTC<-gsub("2010s","2010-19",bs_hiMF_RFA$ctyTC)
bs_hiMF_RFA$ctyTC<-gsub("2020s","2020-29",bs_hiMF_RFA$ctyTC)
bs_hiMF_RFA$ctyTC<-gsub("2030s","2030-39",bs_hiMF_RFA$ctyTC)
bs_hiMF_RFA$ctyTC<-gsub("2040s","2040-49",bs_hiMF_RFA$ctyTC)
bs_hiMF_RFA$ctyTC<-gsub("2050s","2050-60",bs_hiMF_RFA$ctyTC)

bs_hiMF_RFA<-left_join(bs_hiMF_RFA,shmfm,by="ctyTC")

# merge with the energy results
rshmfRFA_sum<-result_sum(rshiMF_RFA,0)
rshmfRFA_sum<-rshmfRFA_sum[,c(1:3,23,43,44,55:63,66,81,82,88,95,103,105:111,113:122,124:129,131,133,135:141,148:200)] # bigger version

rs_hiMFRFA<-merge(bs_hiMF_RFA,rshmfRFA_sum,by.x = "Building",by.y = "building_id")
rs_hiMFRFA<-rs_hiMFRFA[,-c(which(names(rs_hiMFRFA) %in% c("Year.y", "Year_Building.y")))]
rs_hiMFRFA<-rs_hiMFRFA %>% rename(Year_Building = Year_Building.x, Year = Year.x)

# add GHG intensities, Mid-Case
rs_hiMFRFA<-left_join(rs_hiMFRFA,gic,by = c("County" = "RS_ID"))
# add GHG intensities, Low RE Cost
rs_hiMFRFA<-left_join(rs_hiMFRFA,gic_LRE,by = c("County" = "RS_ID"))

rs_hiMFRFA[rs_hiMFRFA$Year==2030,]$whiMF_2025<-0
rs_hiMFRFA[rs_hiMFRFA$Year==2040,]$whiMF_2035<-0
rs_hiMFRFA[rs_hiMFRFA$Year==2050,]$whiMF_2045<-0
rs_hiMFRFA[rs_hiMFRFA$Year==2060,]$whiMF_2055<-0

rs_hiMFRFA[,c("Tot_GJ_hiMF_2020",  "Tot_GJ_hiMF_2025","Tot_GJ_hiMF_2030","Tot_GJ_hiMF_2035","Tot_GJ_hiMF_2040","Tot_GJ_hiMF_2045","Tot_GJ_hiMF_2050","Tot_GJ_hiMF_2055","Tot_GJ_hiMF_2060")]<-
  (rs_hiMFRFA$base_weight_STCY*rs_hiMFRFA[,c("whiMF_2020", "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")])*
  (rs_hiMFRFA$Elec_GJ+rs_hiMFRFA$Gas_GJ+rs_hiMFRFA$Prop_GJ+rs_hiMFRFA$Oil_GJ)

# tot kgGHG per archetype group/year in kg
rs_hiMFRFA[,c("EnGHGkg_hiMF_2020","EnGHGkg_hiMF_2025","EnGHGkg_hiMF_2030","EnGHGkg_hiMF_2035","EnGHGkg_hiMF_2040","EnGHGkg_hiMF_2045","EnGHGkg_hiMF_2050","EnGHGkg_hiMF_2055","EnGHGkg_hiMF_2060")]<-1000* 
  (rs_hiMFRFA$base_weight_STCY*rs_hiMFRFA[,c("whiMF_2020",  "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")])*
  (rs_hiMFRFA$Elec_GJ*rs_hiMFRFA[,c("GHG_int_2020", "GHG_int_2025","GHG_int_2030","GHG_int_2035","GHG_int_2040","GHG_int_2045","GHG_int_2050","GHG_int_2055","GHG_int_2060")]+
     matrix(rep(rs_hiMFRFA$Gas_GJ*GHGI_NG,9),nrow(rs_hiMFRFA),9)+ matrix(rep(rs_hiMFRFA$Oil_GJ*GHGI_FO,9),nrow(rs_hiMFRFA),9)+ matrix(rep(rs_hiMFRFA$Prop_GJ*GHGI_LP,9),nrow(rs_hiMFRFA),9))

# tot LRE kgGHG per archetype group/year in kg
rs_hiMFRFA[,c("EnGHGkg_hiMF_2020_LRE","EnGHGkg_hiMF_2025_LRE","EnGHGkg_hiMF_2030_LRE","EnGHGkg_hiMF_2035_LRE","EnGHGkg_hiMF_2040_LRE","EnGHGkg_hiMF_2045_LRE","EnGHGkg_hiMF_2050_LRE","EnGHGkg_hiMF_2055_LRE","EnGHGkg_hiMF_2060_LRE")]<-1000* 
  (rs_hiMFRFA$base_weight_STCY*rs_hiMFRFA[,c("whiMF_2020",  "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")])*
  (rs_hiMFRFA$Elec_GJ*rs_hiMFRFA[,c("GHG_int_2020_LRE", "GHG_int_2025_LRE","GHG_int_2030_LRE","GHG_int_2035_LRE","GHG_int_2040_LRE","GHG_int_2045_LRE","GHG_int_2050_LRE","GHG_int_2055_LRE","GHG_int_2060_LRE")]+
     matrix(rep(rs_hiMFRFA$Gas_GJ*GHGI_NG,9),nrow(rs_hiMFRFA),9)+ matrix(rep(rs_hiMFRFA$Oil_GJ*GHGI_FO,9),nrow(rs_hiMFRFA),9)+ matrix(rep(rs_hiMFRFA$Prop_GJ*GHGI_LP,9),nrow(rs_hiMFRFA),9))

save(rs_hiMFRFA,file="../Intermediate_results/rs_hiMFRFA_EG.RData") 

# now merge with the AR/RR files
n1<-names(rs_RRn) # <2020 stock, Reg Ren
n2<-names(rs_hiMFRFA) # new construction

# check the GHG ints in the two files
G1<-unique(rs_RRn[,c('County','GHG_int_2020')])
names(G1)[2]<-'GHG_int_2020_ex'
G2<-unique(rs_hiMFRFA[,c('County','GHG_int_2020')])
names(G2)[2]<-'GHG_int_2020_nc'
G3<-merge(G2,G1)
print(all(G3$GHG_int_2020_nc==G3$GHG_int_2020_ex))


# before binding rows, make the Building codes in rs_hiMFRFA distinct from those in rs_RRn
rs_hiMFRFA$Building<-180000+rs_hiMFRFA$Building
rs_hiMFRFA$Year_Building<-paste(rs_hiMFRFA$Year,rs_hiMFRFA$Building,sep="_")

rs_hiMFRFA_all_RR<-bind_rows(rs_RRn,rs_hiMFRFA)

rs_hiMFRFA_all_RR<-rs_hiMFRFA_all_RR[,names(rs_hiMFRFA_all_RR) %in% names(rs_hiMFRFA)]

rs_hiMFRFA_all_RR[is.na(rs_hiMFRFA_all_RR$base_weight_STCY), ]$base_weight_STCY<-0 # this can be a little slow/sticky
rs_hiMFRFA_all_RR[rs_hiMFRFA_all_RR$base_weight_STCY==0,]$base_weight_STCY<-rs_hiMFRFA_all_RR[rs_hiMFRFA_all_RR$base_weight_STCY==0,]$base_weight_STCY+rs_hiMFRFA_all_RR[rs_hiMFRFA_all_RR$base_weight_STCY==0,]$base_weight

# example of calculating national level emissions in each year , except without construction related emissions
colSums(rs_hiMFRFA_all_RR[,176:184])*1e-9 # 
# example of calculating national level emissions in each year , LRE elec
colSums(rs_hiMFRFA_all_RR[,185:193])*1e-9 # 

save(rs_hiMFRFA_all_RR,file="../Final_results/res_hiMFRFA_RR.RData")
rm(rs_hiMFRFA_all_RR)
# now advanced ren
n1<-names(rs_ARn) # <2020 stock, Reg Ren
n2<-names(rs_hiMFRFA) # new construction

# check the GHG ints in the two files
G1<-unique(rs_ARn[,c('County','GHG_int_2020')])
names(G1)[2]<-'GHG_int_2020_ex'
G2<-unique(rs_hiMFRFA[,c('County','GHG_int_2020')])
names(G2)[2]<-'GHG_int_2020_nc'
G3<-merge(G2,G1)
print(all(G3$GHG_int_2020_nc==G3$GHG_int_2020_ex))


rs_hiMFRFA_all_AR<-bind_rows(rs_ARn,rs_hiMFRFA)

rs_hiMFRFA_all_AR<-rs_hiMFRFA_all_AR[,names(rs_hiMFRFA_all_AR) %in% names(rs_hiMFRFA)]

rs_hiMFRFA_all_AR[is.na(rs_hiMFRFA_all_AR$base_weight_STCY), ]$base_weight_STCY<-0 # this can be a little slow/sticky
rs_hiMFRFA_all_AR[rs_hiMFRFA_all_AR$base_weight_STCY==0,]$base_weight_STCY<-rs_hiMFRFA_all_AR[rs_hiMFRFA_all_AR$base_weight_STCY==0,]$base_weight_STCY+rs_hiMFRFA_all_AR[rs_hiMFRFA_all_AR$base_weight_STCY==0,]$base_weight

# example of calculating national level emissions in each year , except without construction related emissions
colSums(rs_hiMFRFA_all_AR[,176:184])*1e-9 # 
# example of calculating national level emissions in each year , LREC
colSums(rs_hiMFRFA_all_AR[,185:193])*1e-9 # 

save(rs_hiMFRFA_all_AR,file="../Final_results/res_hiMFRFA_AR.RData")
rm(rs_hiMFRFA_all_AR)
# now extensive ren
n1<-names(rs_ERn) # <2020 stock, Reg Ren
n2<-names(rs_hiMFRFA) # new construction

# check the GHG ints in the two files
G1<-unique(rs_ERn[,c('County','GHG_int_2020')])
names(G1)[2]<-'GHG_int_2020_ex'
G2<-unique(rs_hiMFRFA[,c('County','GHG_int_2020')])
names(G2)[2]<-'GHG_int_2020_nc'
G3<-merge(G2,G1)
print(all(G3$GHG_int_2020_nc==G3$GHG_int_2020_ex))


rs_hiMFRFA_all_ER<-bind_rows(rs_ERn,rs_hiMFRFA)

rs_hiMFRFA_all_ER<-rs_hiMFRFA_all_ER[,names(rs_hiMFRFA_all_ER) %in% names(rs_hiMFRFA)]

rs_hiMFRFA_all_ER[is.na(rs_hiMFRFA_all_ER$base_weight_STCY), ]$base_weight_STCY<-0 # this can be a little slow/sticky
rs_hiMFRFA_all_ER[rs_hiMFRFA_all_ER$base_weight_STCY==0,]$base_weight_STCY<-rs_hiMFRFA_all_ER[rs_hiMFRFA_all_ER$base_weight_STCY==0,]$base_weight_STCY+rs_hiMFRFA_all_ER[rs_hiMFRFA_all_ER$base_weight_STCY==0,]$base_weight

# example of calculating national level emissions in each year , except without construction related emissions
colSums(rs_hiMFRFA_all_ER[,176:184])*1e-9 # 
# example of calculating national level emissions in each year , LREC
colSums(rs_hiMFRFA_all_ER[,185:193])*1e-9 # 

save(rs_hiMFRFA_all_ER,file="../Final_results/res_hiMFRFA_ER.RData")
rm(rs_hiMFRFA_all_ER)
rm(rshiMF_RFA)
rm(rs_hiMFRFA)
# load in projection results, hiMFDE ######
# 11 of 12 stock projection results: hiMF stock, DE NHC
print('hiMF 11')
load("../Eagle_outputs/Complete_results/res_hiMFDE_final.RData")
rshiMF_DE<-rsn
rm(rsn)

bs_hiMF_DE<-bs_hiMF_all[bs_hiMF_all$scen=="hiMFDE",]
bs_hiMF_DE$Year<-bs_hiMF_DE$sim_year

bs_hiMF_DE$Year_Building<-paste(bs_hiMF_DE$Year,bs_hiMF_DE$Building,sep="_")

bs_hiMF_DE<-bs_hiMF_DE[,c("Year_Building","Year", "Building","County","State","Location.Region","Census.Division", "Census.Region", "ASHRAE.IECC.Climate.Zone.2004", "PUMA", "ISO.RTO.Region", "Geometry.Building.Type.ACS","Geometry.Building.Type.RECS",
                            "Vintage","Vintage.ACS","Heating.Fuel","Geometry.Floor.Area","Geometry.Foundation.Type","Geometry.Wall.Type","Geometry.Stories","Geometry.Garage",
                            "HVAC.Heating.Type.And.Fuel","HVAC.Heating.Efficiency","HVAC.Cooling.Type","HVAC.Cooling.Efficiency","Water.Heater.Fuel","Water.Heater.Efficiency",
                            "Clothes.Dryer","Infiltration")] # currently comes to 29 columns, without "change_cren","change_iren","change_wren","change_hren", "base_weight". Add these in for consistency
bs_hiMF_DE[,c("change_cren","change_iren","change_wren","change_hren")]<-0

bs_hiMF_DE$base_weight<-0
# add base weights for each sim year, based on the new construction estimates
for (y in seq(2025,2060,5)) {
  bs_hiMF_DE[bs_hiMF_DE$Year==y,]$base_weight<-nce[nce$Year==y,]$hiMF/15000
}
bs_hiMF_DE$Type3<-'MF'
bs_hiMF_DE[bs_hiMF_DE$Geometry.Building.Type.RECS=='Mobile Home',]$Type3<-'MH'
bs_hiMF_DE[bs_hiMF_DE$Geometry.Building.Type.RECS %in% c('Single-Family Detached','Single-Family Attached'),]$Type3<-'SF'

names(stcy_comp_hiMF)[c(2,4,8)]<-c('Vintage.ACS','Type3','base_weight_STCY')
bs_hiMF_DE<-merge(bs_hiMF_DE,stcy_comp_hiMF[,c('Year','State','Type3','Vintage.ACS','base_weight_STCY')],by=c('Year','State','Type3','Vintage.ACS'))

bs_hiMF_DE$TC<-"MF"
bs_hiMF_DE[bs_hiMF_DE$Geometry.Building.Type.RECS=="Single-Family Attached" | bs_hiMF_DE$Geometry.Building.Type.RECS=="Single-Family Detached",]$TC<-"SF"
bs_hiMF_DE[bs_hiMF_DE$Geometry.Building.Type.RECS=="Mobile Home",]$TC<-"MH"
bs_hiMF_DE$TC<-paste(bs_hiMF_DE$TC,bs_hiMF_DE$Vintage.ACS,sep="_")
bs_hiMF_DE$ctyTC<-paste(bs_hiMF_DE$County,bs_hiMF_DE$TC,sep = "")
bs_hiMF_DE$ctyTC<-gsub("2010s","2010-19",bs_hiMF_DE$ctyTC)
bs_hiMF_DE$ctyTC<-gsub("2020s","2020-29",bs_hiMF_DE$ctyTC)
bs_hiMF_DE$ctyTC<-gsub("2030s","2030-39",bs_hiMF_DE$ctyTC)
bs_hiMF_DE$ctyTC<-gsub("2040s","2040-49",bs_hiMF_DE$ctyTC)
bs_hiMF_DE$ctyTC<-gsub("2050s","2050-60",bs_hiMF_DE$ctyTC)

bs_hiMF_DE<-left_join(bs_hiMF_DE,shmfm,by="ctyTC")

# merge with the energy results
rshmfDE_sum<-result_sum(rshiMF_DE,0)
rshmfDE_sum<-rshmfDE_sum[,c(1:3,23,43,44,55:63,66,81,82,88,95,103,105:111,113:122,124:129,131,133,135:141,148:200)] # bigger version

rs_hiMFDE<-merge(bs_hiMF_DE,rshmfDE_sum,by.x = "Building",by.y = "building_id")
rs_hiMFDE<-rs_hiMFDE[,-c(which(names(rs_hiMFDE) %in% c("Year.y", "Year_Building.y")))]
rs_hiMFDE<-rs_hiMFDE %>% rename(Year_Building = Year_Building.x, Year = Year.x)

# add GHG intensities, Mid-Case
rs_hiMFDE<-left_join(rs_hiMFDE,gic,by = c("County" = "RS_ID"))
# add GHG intensities, Low RE Cost
rs_hiMFDE<-left_join(rs_hiMFDE,gic_LRE,by = c("County" = "RS_ID"))

rs_hiMFDE[rs_hiMFDE$Year==2030,]$whiMF_2025<-0
rs_hiMFDE[rs_hiMFDE$Year==2040,]$whiMF_2035<-0
rs_hiMFDE[rs_hiMFDE$Year==2050,]$whiMF_2045<-0
rs_hiMFDE[rs_hiMFDE$Year==2060,]$whiMF_2055<-0

rs_hiMFDE[,c("Tot_GJ_hiMF_2020",  "Tot_GJ_hiMF_2025","Tot_GJ_hiMF_2030","Tot_GJ_hiMF_2035","Tot_GJ_hiMF_2040","Tot_GJ_hiMF_2045","Tot_GJ_hiMF_2050","Tot_GJ_hiMF_2055","Tot_GJ_hiMF_2060")]<-
  (rs_hiMFDE$base_weight_STCY*rs_hiMFDE[,c("whiMF_2020", "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")])*
  (rs_hiMFDE$Elec_GJ+rs_hiMFDE$Gas_GJ+rs_hiMFDE$Prop_GJ+rs_hiMFDE$Oil_GJ)

# tot kgGHG per archetype group/year in kg
rs_hiMFDE[,c("EnGHGkg_hiMF_2020","EnGHGkg_hiMF_2025","EnGHGkg_hiMF_2030","EnGHGkg_hiMF_2035","EnGHGkg_hiMF_2040","EnGHGkg_hiMF_2045","EnGHGkg_hiMF_2050","EnGHGkg_hiMF_2055","EnGHGkg_hiMF_2060")]<-1000* 
  (rs_hiMFDE$base_weight_STCY*rs_hiMFDE[,c("whiMF_2020",  "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")])*
  (rs_hiMFDE$Elec_GJ*rs_hiMFDE[,c("GHG_int_2020", "GHG_int_2025","GHG_int_2030","GHG_int_2035","GHG_int_2040","GHG_int_2045","GHG_int_2050","GHG_int_2055","GHG_int_2060")]+
     matrix(rep(rs_hiMFDE$Gas_GJ*GHGI_NG,9),nrow(rs_hiMFDE),9)+ matrix(rep(rs_hiMFDE$Oil_GJ*GHGI_FO,9),nrow(rs_hiMFDE),9)+ matrix(rep(rs_hiMFDE$Prop_GJ*GHGI_LP,9),nrow(rs_hiMFDE),9))

# tot LRE kgGHG per archetype group/year in kg
rs_hiMFDE[,c("EnGHGkg_hiMF_2020_LRE","EnGHGkg_hiMF_2025_LRE","EnGHGkg_hiMF_2030_LRE","EnGHGkg_hiMF_2035_LRE","EnGHGkg_hiMF_2040_LRE","EnGHGkg_hiMF_2045_LRE","EnGHGkg_hiMF_2050_LRE","EnGHGkg_hiMF_2055_LRE","EnGHGkg_hiMF_2060_LRE")]<-1000* 
  (rs_hiMFDE$base_weight_STCY*rs_hiMFDE[,c("whiMF_2020",  "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")])*
  (rs_hiMFDE$Elec_GJ*rs_hiMFDE[,c("GHG_int_2020_LRE", "GHG_int_2025_LRE","GHG_int_2030_LRE","GHG_int_2035_LRE","GHG_int_2040_LRE","GHG_int_2045_LRE","GHG_int_2050_LRE","GHG_int_2055_LRE","GHG_int_2060_LRE")]+
     matrix(rep(rs_hiMFDE$Gas_GJ*GHGI_NG,9),nrow(rs_hiMFDE),9)+ matrix(rep(rs_hiMFDE$Oil_GJ*GHGI_FO,9),nrow(rs_hiMFDE),9)+ matrix(rep(rs_hiMFDE$Prop_GJ*GHGI_LP,9),nrow(rs_hiMFDE),9))

save(rs_hiMFDE,file="../Intermediate_results/rs_hiMFDE_EG.RData")

# now merge with the AR/RR files
n1<-names(rs_RRn) # <2020 stock, Reg Ren
n2<-names(rs_hiMFDE) # new construction

# check the GHG ints in the two files
G1<-unique(rs_RRn[,c('County','GHG_int_2020')])
names(G1)[2]<-'GHG_int_2020_ex'
G2<-unique(rs_hiMFDE[,c('County','GHG_int_2020')])
names(G2)[2]<-'GHG_int_2020_nc'
G3<-merge(G2,G1)
print(all(G3$GHG_int_2020_nc==G3$GHG_int_2020_ex))


# before binding rows, make the Building codes in rs_hiMFDE distinct from those in rs_RRn
rs_hiMFDE$Building<-180000+rs_hiMFDE$Building
rs_hiMFDE$Year_Building<-paste(rs_hiMFDE$Year,rs_hiMFDE$Building,sep="_")

rs_hiMFDE_all_RR<-bind_rows(rs_RRn,rs_hiMFDE)

rs_hiMFDE_all_RR<-rs_hiMFDE_all_RR[,names(rs_hiMFDE_all_RR) %in% names(rs_hiMFDE)]

rs_hiMFDE_all_RR[is.na(rs_hiMFDE_all_RR$base_weight_STCY), ]$base_weight_STCY<-0 # this can be a little slow/sticky
rs_hiMFDE_all_RR[rs_hiMFDE_all_RR$base_weight_STCY==0,]$base_weight_STCY<-rs_hiMFDE_all_RR[rs_hiMFDE_all_RR$base_weight_STCY==0,]$base_weight_STCY+rs_hiMFDE_all_RR[rs_hiMFDE_all_RR$base_weight_STCY==0,]$base_weight

# example of calculating national level emissions in each year , except without construction related emissions
colSums(rs_hiMFDE_all_RR[,176:184])*1e-9 # 
# example of calculating national level emissions in each year , LRE elec
colSums(rs_hiMFDE_all_RR[,185:193])*1e-9 # 

save(rs_hiMFDE_all_RR,file="../Final_results/res_hiMFDE_RR.RData")
rm(rs_hiMFDE_all_RR)
# now advanced ren
n1<-names(rs_ARn) # <2020 stock, Reg Ren
n2<-names(rs_hiMFDE) # new construction

# check the GHG ints in the two files
G1<-unique(rs_ARn[,c('County','GHG_int_2020')])
names(G1)[2]<-'GHG_int_2020_ex'
G2<-unique(rs_hiMFDE[,c('County','GHG_int_2020')])
names(G2)[2]<-'GHG_int_2020_nc'
G3<-merge(G2,G1)
print(all(G3$GHG_int_2020_nc==G3$GHG_int_2020_ex))


rs_hiMFDE_all_AR<-bind_rows(rs_ARn,rs_hiMFDE)

rs_hiMFDE_all_AR<-rs_hiMFDE_all_AR[,names(rs_hiMFDE_all_AR) %in% names(rs_hiMFDE)]

rs_hiMFDE_all_AR[is.na(rs_hiMFDE_all_AR$base_weight_STCY), ]$base_weight_STCY<-0 # this can be a little slow/sticky
rs_hiMFDE_all_AR[rs_hiMFDE_all_AR$base_weight_STCY==0,]$base_weight_STCY<-rs_hiMFDE_all_AR[rs_hiMFDE_all_AR$base_weight_STCY==0,]$base_weight_STCY+rs_hiMFDE_all_AR[rs_hiMFDE_all_AR$base_weight_STCY==0,]$base_weight

# example of calculating national level emissions in each year , except without construction related emissions
colSums(rs_hiMFDE_all_AR[,176:184])*1e-9 # 
# example of calculating national level emissions in each year , LREC
colSums(rs_hiMFDE_all_AR[,185:193])*1e-9 # 

save(rs_hiMFDE_all_AR,file="../Final_results/res_hiMFDE_AR.RData")
rm(rs_hiMFDE_all_AR)
# now extensive ren
n1<-names(rs_ERn) # <2020 stock, Reg Ren
n2<-names(rs_hiMFDE) # new construction

# check the GHG ints in the two files
G1<-unique(rs_ERn[,c('County','GHG_int_2020')])
names(G1)[2]<-'GHG_int_2020_ex'
G2<-unique(rs_hiMFDE[,c('County','GHG_int_2020')])
names(G2)[2]<-'GHG_int_2020_nc'
G3<-merge(G2,G1)
print(all(G3$GHG_int_2020_nc==G3$GHG_int_2020_ex))


rs_hiMFDE_all_ER<-bind_rows(rs_ERn,rs_hiMFDE)

rs_hiMFDE_all_ER<-rs_hiMFDE_all_ER[,names(rs_hiMFDE_all_ER) %in% names(rs_hiMFDE)]

rs_hiMFDE_all_ER[is.na(rs_hiMFDE_all_ER$base_weight_STCY), ]$base_weight_STCY<-0 # this can be a little slow/sticky
rs_hiMFDE_all_ER[rs_hiMFDE_all_ER$base_weight_STCY==0,]$base_weight_STCY<-rs_hiMFDE_all_ER[rs_hiMFDE_all_ER$base_weight_STCY==0,]$base_weight_STCY+rs_hiMFDE_all_ER[rs_hiMFDE_all_ER$base_weight_STCY==0,]$base_weight

# example of calculating national level emissions in each year , except without construction related emissions
colSums(rs_hiMFDE_all_ER[,176:184])*1e-9 # 
# example of calculating national level emissions in each year , LREC
colSums(rs_hiMFDE_all_ER[,185:193])*1e-9 # 

save(rs_hiMFDE_all_ER,file="../Final_results/res_hiMFDE_ER.RData")
rm(rs_hiMFDE_all_ER)
rm(rshiMF_DE)
rm(rs_hiMFDE)
# load in projection results, hiMFDERFA ######
# 12 of 12 stock projection results: hiMF stock, DERFA NHC
print('hiMF 12')
load("../Eagle_outputs/Complete_results/res_hiMFDERFA_final.RData")
rshiMF_DERFA<-rsn
rm(rsn)

bs_hiMF_DERFA<-bs_hiMF_all[bs_hiMF_all$scen=="hiMFDERFA",]
bs_hiMF_DERFA$Year<-bs_hiMF_DERFA$sim_year

bs_hiMF_DERFA$Year_Building<-paste(bs_hiMF_DERFA$Year,bs_hiMF_DERFA$Building,sep="_")

bs_hiMF_DERFA<-bs_hiMF_DERFA[,c("Year_Building","Year", "Building","County","State","Location.Region","Census.Division", "Census.Region", "ASHRAE.IECC.Climate.Zone.2004", "PUMA", "ISO.RTO.Region", "Geometry.Building.Type.ACS","Geometry.Building.Type.RECS",
                          "Vintage","Vintage.ACS","Heating.Fuel","Geometry.Floor.Area","Geometry.Foundation.Type","Geometry.Wall.Type","Geometry.Stories","Geometry.Garage",
                          "HVAC.Heating.Type.And.Fuel","HVAC.Heating.Efficiency","HVAC.Cooling.Type","HVAC.Cooling.Efficiency","Water.Heater.Fuel","Water.Heater.Efficiency",
                          "Clothes.Dryer","Infiltration")] # currently comes to 29 columns, without "change_cren","change_iren","change_wren","change_hren", "base_weight". Add these in for consistency
bs_hiMF_DERFA[,c("change_cren","change_iren","change_wren","change_hren")]<-0

bs_hiMF_DERFA$base_weight<-0
# add base weights for each sim year, based on the new construction estimates
for (y in seq(2025,2060,5)) {
  bs_hiMF_DERFA[bs_hiMF_DERFA$Year==y,]$base_weight<-nce[nce$Year==y,]$hiMF/15000
}

bs_hiMF_DERFA$Type3<-'MF'
bs_hiMF_DERFA[bs_hiMF_DERFA$Geometry.Building.Type.RECS=='Mobile Home',]$Type3<-'MH'
bs_hiMF_DERFA[bs_hiMF_DERFA$Geometry.Building.Type.RECS %in% c('Single-Family Detached','Single-Family Attached'),]$Type3<-'SF'

names(stcy_comp_hiMF)[c(2,4,8)]<-c('Vintage.ACS','Type3','base_weight_STCY')
bs_hiMF_DERFA<-merge(bs_hiMF_DERFA,stcy_comp_hiMF[,c('Year','State','Type3','Vintage.ACS','base_weight_STCY')],by=c('Year','State','Type3','Vintage.ACS'))

bs_hiMF_DERFA$TC<-"MF"
bs_hiMF_DERFA[bs_hiMF_DERFA$Geometry.Building.Type.RECS=="Single-Family Attached" | bs_hiMF_DERFA$Geometry.Building.Type.RECS=="Single-Family Detached",]$TC<-"SF"
bs_hiMF_DERFA[bs_hiMF_DERFA$Geometry.Building.Type.RECS=="Mobile Home",]$TC<-"MH"
bs_hiMF_DERFA$TC<-paste(bs_hiMF_DERFA$TC,bs_hiMF_DERFA$Vintage.ACS,sep="_")
bs_hiMF_DERFA$ctyTC<-paste(bs_hiMF_DERFA$County,bs_hiMF_DERFA$TC,sep = "")
bs_hiMF_DERFA$ctyTC<-gsub("2010s","2010-19",bs_hiMF_DERFA$ctyTC)
bs_hiMF_DERFA$ctyTC<-gsub("2020s","2020-29",bs_hiMF_DERFA$ctyTC)
bs_hiMF_DERFA$ctyTC<-gsub("2030s","2030-39",bs_hiMF_DERFA$ctyTC)
bs_hiMF_DERFA$ctyTC<-gsub("2040s","2040-49",bs_hiMF_DERFA$ctyTC)
bs_hiMF_DERFA$ctyTC<-gsub("2050s","2050-60",bs_hiMF_DERFA$ctyTC)

bs_hiMF_DERFA<-left_join(bs_hiMF_DERFA,shmfm,by="ctyTC")

# merge with the energy results
rshmfDERFA_sum<-result_sum(rshiMF_DERFA,0)
rshmfDERFA_sum<-rshmfDERFA_sum[,c(1:3,23,43,44,55:63,66,81,82,88,95,103,105:111,113:122,124:129,131,133,135:141,148:200)] # bigger version

rs_hiMFDERFA<-merge(bs_hiMF_DERFA,rshmfDERFA_sum,by.x = "Building",by.y = "building_id")
rs_hiMFDERFA<-rs_hiMFDERFA[,-c(which(names(rs_hiMFDERFA) %in% c("Year.y", "Year_Building.y")))]
rs_hiMFDERFA<-rs_hiMFDERFA %>% rename(Year_Building = Year_Building.x, Year = Year.x)

# add GHG intensities, Mid-Case
rs_hiMFDERFA<-left_join(rs_hiMFDERFA,gic,by = c("County" = "RS_ID"))
# add GHG intensities, Low RE Cost
rs_hiMFDERFA<-left_join(rs_hiMFDERFA,gic_LRE,by = c("County" = "RS_ID"))

rs_hiMFDERFA[rs_hiMFDERFA$Year==2030,]$whiMF_2025<-0
rs_hiMFDERFA[rs_hiMFDERFA$Year==2040,]$whiMF_2035<-0
rs_hiMFDERFA[rs_hiMFDERFA$Year==2050,]$whiMF_2045<-0
rs_hiMFDERFA[rs_hiMFDERFA$Year==2060,]$whiMF_2055<-0

rs_hiMFDERFA[,c("Tot_GJ_hiMF_2020",  "Tot_GJ_hiMF_2025","Tot_GJ_hiMF_2030","Tot_GJ_hiMF_2035","Tot_GJ_hiMF_2040","Tot_GJ_hiMF_2045","Tot_GJ_hiMF_2050","Tot_GJ_hiMF_2055","Tot_GJ_hiMF_2060")]<-
  (rs_hiMFDERFA$base_weight_STCY*rs_hiMFDERFA[,c("whiMF_2020", "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")])*
  (rs_hiMFDERFA$Elec_GJ+rs_hiMFDERFA$Gas_GJ+rs_hiMFDERFA$Prop_GJ+rs_hiMFDERFA$Oil_GJ)

# tot kgGHG per archetype group/year in kg
rs_hiMFDERFA[,c("EnGHGkg_hiMF_2020","EnGHGkg_hiMF_2025","EnGHGkg_hiMF_2030","EnGHGkg_hiMF_2035","EnGHGkg_hiMF_2040","EnGHGkg_hiMF_2045","EnGHGkg_hiMF_2050","EnGHGkg_hiMF_2055","EnGHGkg_hiMF_2060")]<-1000* 
  (rs_hiMFDERFA$base_weight_STCY*rs_hiMFDERFA[,c("whiMF_2020",  "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")])*
  (rs_hiMFDERFA$Elec_GJ*rs_hiMFDERFA[,c("GHG_int_2020", "GHG_int_2025","GHG_int_2030","GHG_int_2035","GHG_int_2040","GHG_int_2045","GHG_int_2050","GHG_int_2055","GHG_int_2060")]+
     matrix(rep(rs_hiMFDERFA$Gas_GJ*GHGI_NG,9),nrow(rs_hiMFDERFA),9)+ matrix(rep(rs_hiMFDERFA$Oil_GJ*GHGI_FO,9),nrow(rs_hiMFDERFA),9)+ matrix(rep(rs_hiMFDERFA$Prop_GJ*GHGI_LP,9),nrow(rs_hiMFDERFA),9))

# tot LRE kgGHG per archetype group/year in kg
rs_hiMFDERFA[,c("EnGHGkg_hiMF_2020_LRE","EnGHGkg_hiMF_2025_LRE","EnGHGkg_hiMF_2030_LRE","EnGHGkg_hiMF_2035_LRE","EnGHGkg_hiMF_2040_LRE","EnGHGkg_hiMF_2045_LRE","EnGHGkg_hiMF_2050_LRE","EnGHGkg_hiMF_2055_LRE","EnGHGkg_hiMF_2060_LRE")]<-1000* 
  (rs_hiMFDERFA$base_weight_STCY*rs_hiMFDERFA[,c("whiMF_2020",  "whiMF_2025", "whiMF_2030", "whiMF_2035", "whiMF_2040", "whiMF_2045", "whiMF_2050", "whiMF_2055", "whiMF_2060")])*
  (rs_hiMFDERFA$Elec_GJ*rs_hiMFDERFA[,c("GHG_int_2020_LRE", "GHG_int_2025_LRE","GHG_int_2030_LRE","GHG_int_2035_LRE","GHG_int_2040_LRE","GHG_int_2045_LRE","GHG_int_2050_LRE","GHG_int_2055_LRE","GHG_int_2060_LRE")]+
     matrix(rep(rs_hiMFDERFA$Gas_GJ*GHGI_NG,9),nrow(rs_hiMFDERFA),9)+ matrix(rep(rs_hiMFDERFA$Oil_GJ*GHGI_FO,9),nrow(rs_hiMFDERFA),9)+ matrix(rep(rs_hiMFDERFA$Prop_GJ*GHGI_LP,9),nrow(rs_hiMFDERFA),9))

save(rs_hiMFDERFA,file="../Intermediate_results/rs_hiMFDERFA_EG.RData")

# now merge with the AR/RR files

n1<-names(rs_RRn) # <2020 stock, Reg Ren
n2<-names(rs_hiMFDERFA) # new construction

# check the GHG ints in the two files
G1<-unique(rs_RRn[,c('County','GHG_int_2020')])
names(G1)[2]<-'GHG_int_2020_ex'
G2<-unique(rs_hiMFDERFA[,c('County','GHG_int_2020')])
names(G2)[2]<-'GHG_int_2020_nc'
G3<-merge(G2,G1)
print(all(G3$GHG_int_2020_nc==G3$GHG_int_2020_ex))


# before binding rows, make the Building codes in rs_hiMFDERFA distinct from those in rs_RRn
rs_hiMFDERFA$Building<-180000+rs_hiMFDERFA$Building
rs_hiMFDERFA$Year_Building<-paste(rs_hiMFDERFA$Year,rs_hiMFDERFA$Building,sep="_")

rs_hiMFDERFA_all_RR<-bind_rows(rs_RRn,rs_hiMFDERFA)

rs_hiMFDERFA_all_RR<-rs_hiMFDERFA_all_RR[,names(rs_hiMFDERFA_all_RR) %in% names(rs_hiMFDERFA)]

rs_hiMFDERFA_all_RR[is.na(rs_hiMFDERFA_all_RR$base_weight_STCY), ]$base_weight_STCY<-0 # this can be a little slow/sticky
rs_hiMFDERFA_all_RR[rs_hiMFDERFA_all_RR$base_weight_STCY==0,]$base_weight_STCY<-rs_hiMFDERFA_all_RR[rs_hiMFDERFA_all_RR$base_weight_STCY==0,]$base_weight_STCY+rs_hiMFDERFA_all_RR[rs_hiMFDERFA_all_RR$base_weight_STCY==0,]$base_weight

# example of calculating national level emissions in each year , except without construction related emissions
colSums(rs_hiMFDERFA_all_RR[,176:184])*1e-9 # 
# example of calculating national level emissions in each year , LRE elec
colSums(rs_hiMFDERFA_all_RR[,185:193])*1e-9 # 

save(rs_hiMFDERFA_all_RR,file="../Final_results/res_hiMFDERFA_RR.RData")
rm(rs_hiMFDERFA_all_RR)
# now advanced ren
n1<-names(rs_ARn) # <2020 stock, Reg Ren
n2<-names(rs_hiMFDERFA) # new construction

# check the GHG ints in the two files
G1<-unique(rs_ARn[,c('County','GHG_int_2020')])
names(G1)[2]<-'GHG_int_2020_ex'
G2<-unique(rs_hiMFDERFA[,c('County','GHG_int_2020')])
names(G2)[2]<-'GHG_int_2020_nc'
G3<-merge(G2,G1)
print(all(G3$GHG_int_2020_nc==G3$GHG_int_2020_ex))

rs_hiMFDERFA_all_AR<-bind_rows(rs_ARn,rs_hiMFDERFA)

rs_hiMFDERFA_all_AR<-rs_hiMFDERFA_all_AR[,names(rs_hiMFDERFA_all_AR) %in% names(rs_hiMFDERFA)]

rs_hiMFDERFA_all_AR[is.na(rs_hiMFDERFA_all_AR$base_weight_STCY), ]$base_weight_STCY<-0 # this can be a little slow/sticky
rs_hiMFDERFA_all_AR[rs_hiMFDERFA_all_AR$base_weight_STCY==0,]$base_weight_STCY<-rs_hiMFDERFA_all_AR[rs_hiMFDERFA_all_AR$base_weight_STCY==0,]$base_weight_STCY+rs_hiMFDERFA_all_AR[rs_hiMFDERFA_all_AR$base_weight_STCY==0,]$base_weight

# example of calculating national level emissions in each year , except without construction related emissions
colSums(rs_hiMFDERFA_all_AR[,176:184])*1e-9 # 
# example of calculating national level emissions in each year , LREC
colSums(rs_hiMFDERFA_all_AR[,185:193])*1e-9 # 

save(rs_hiMFDERFA_all_AR,file="../Final_results/res_hiMFDERFA_AR.RData")
rm(rs_hiMFDERFA_all_AR)
# now extensive ren
n1<-names(rs_ERn) # <2020 stock, Reg Ren
n2<-names(rs_hiMFDERFA) # new construction

# check the GHG ints in the two files
G1<-unique(rs_ERn[,c('County','GHG_int_2020')])
names(G1)[2]<-'GHG_int_2020_ex'
G2<-unique(rs_hiMFDERFA[,c('County','GHG_int_2020')])
names(G2)[2]<-'GHG_int_2020_nc'
G3<-merge(G2,G1)
print(all(G3$GHG_int_2020_nc==G3$GHG_int_2020_ex))

rs_hiMFDERFA_all_ER<-bind_rows(rs_ERn,rs_hiMFDERFA)

rs_hiMFDERFA_all_ER<-rs_hiMFDERFA_all_ER[,names(rs_hiMFDERFA_all_ER) %in% names(rs_hiMFDERFA)]

rs_hiMFDERFA_all_ER[is.na(rs_hiMFDERFA_all_ER$base_weight_STCY), ]$base_weight_STCY<-0 # this can be a little slow/sticky
rs_hiMFDERFA_all_ER[rs_hiMFDERFA_all_ER$base_weight_STCY==0,]$base_weight_STCY<-rs_hiMFDERFA_all_ER[rs_hiMFDERFA_all_ER$base_weight_STCY==0,]$base_weight_STCY+rs_hiMFDERFA_all_ER[rs_hiMFDERFA_all_ER$base_weight_STCY==0,]$base_weight

# example of calculating national level emissions in each year , except without construction related emissions
colSums(rs_hiMFDERFA_all_ER[,176:184])*1e-9 # 
# example of calculating national level emissions in each year , LREC
colSums(rs_hiMFDERFA_all_ER[,185:193])*1e-9 # 

save(rs_hiMFDERFA_all_ER,file="../Final_results/res_hiMFDERFA_ER.RData")
print('done')