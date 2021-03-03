# RS results interpretation 
# This script reads in the results csv and uses it to calculate energy consumption by fuel and end use
rm(list=ls()) # clear workspace i.e. remove saved variables
cat("\014") # clear console
library(dplyr)
setwd("~/Yale Courses/Research/Final Paper/resstock_scenarios/results_scripts")
# import ResStock results csvs
rs_2020<-read.csv("../Final_results/results_2020.csv")
rs_base<-read.csv("../Final_results/results_base.csv")
rs_hiDR<-read.csv("../Final_results/results_hiDR.csv")
rs_hiMF<-read.csv("../Final_results/results_hiMF.csv")
# import R modified bcsv files
load("../Intermediate_results/agg_bscsv.RData")


# rs<-rs_base
# remove columns of job id simulation details, upgrade details, bathroom spot vent hour, cooling setpoint offset details, corridor, door area and type, eaves, EV, 
# heating setpoint offset details, lighting use (both 100%), some misc equip presence and type, overhangs, report.applicable, single door area, upgrade cost
rmcol<-c(2:8,10,12,28:30,34:35,37:38,57:58,83:84,92:95,99,100,105,129,130,198)
colremove<-names(rs_base)[rmcol]

result_sum<-function(rs) {
  rs<-rs[rs$completed_status=="Success",] # hopefully this will not remove any rows.
  # remove unneeded columns to shrink data frame size
  rs<-rs[,-rmcol] 
  # tidy up names a bit
  names(rs)<-gsub("build_existing_model.","",names(rs))
  names(rs)<-gsub("simulation_output_report.","",names(rs))
  
  # calculate energy consumption by end use and fuel in SI units
  rs$Elec_GJ<-rs$total_site_electricity_kwh*0.0036
  rs$Elec_GJ_SPH<-(rs$electricity_heating_kwh+rs$electricity_heating_kwh+rs$electricity_heating_supplemental_kwh+rs$electricity_fans_heating_kwh +rs$electricity_pumps_heating_kwh )*0.0036
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
  rs
}



xs<-25 # number of simulations for each year/scenario
rs_2020_sum<-result_sum(rs_2020)

# merge resstock baseline stock scenario results with pre-simulation meta data ######
rs_base_sum<-result_sum(rs_base)
bs_base_meta<-bs_base_all[,c("Building","sim_year","scen","Building_id")]
rs_base_sum<-merge(rs_base_sum,bs_base_meta,by.x = "building_id",by.y = "Building")
# extract individual results for base stock scenarios, with different combinations of electrification/floor area characteristics
rs_base_base<-rs_base_sum[rs_base_sum$scen=="base",]
rs_base_base$cht_group<-0
rs_base_base[rs_base_base$sim_year==2030,]$cht_group<-1
rs_base_base[rs_base_base$sim_year==2035,]$cht_group<-2
rs_base_base[rs_base_base$sim_year==2040,]$cht_group<-3
rs_base_base[rs_base_base$sim_year==2045,]$cht_group<-4
rs_base_base[rs_base_base$sim_year==2050,]$cht_group<-5
rs_base_base[rs_base_base$sim_year==2055,]$cht_group<-6
rs_base_base[rs_base_base$sim_year==2060,]$cht_group<-7
rs_base_base$Building_id0<-(xs*rs_base_base$cht_group)+rs_base_base$Building_id
bid<-data.frame(bid=dupe_base-xs)
rs_base_base<-rbind(rs_base_base,inner_join(rs_base_base,bid,by=c("Building_id0"="bid")))
rs_base_base[(nrow(rs_base_base)-length(dupe_base)+1):nrow(rs_base_base),]$Building_id0<-dupe_base
rs_base_base<-rs_base_base[order(rs_base_base$Building_id0),]
rs_base_base$sim_year<-rep(rep(seq(2025,2060,5),each=xs)) # each = xs; xs depends on how many simulations for each year/scenario combo

# avg energy efficiency by cohort
tapply(rs_base_base$Tot_MJ_m2,rs_base_base$sim_year,mean)
tapply(rs_base_base$Tot_GJ,rs_base_base$sim_year,mean)

# deep electrification
rs_base_DE<-rs_base_sum[rs_base_sum$scen=="baseDE",]
rs_base_DE$cht_group<-0
rs_base_DE[rs_base_DE$sim_year==2030,]$cht_group<-1
rs_base_DE[rs_base_DE$sim_year==2035,]$cht_group<-2
rs_base_DE[rs_base_DE$sim_year==2040,]$cht_group<-3
rs_base_DE[rs_base_DE$sim_year==2045,]$cht_group<-4
rs_base_DE[rs_base_DE$sim_year==2050,]$cht_group<-5
rs_base_DE[rs_base_DE$sim_year==2055,]$cht_group<-6
rs_base_DE[rs_base_DE$sim_year==2060,]$cht_group<-7
rs_base_DE$Building_id0<-(xs*rs_base_DE$cht_group)+rs_base_DE$Building_id
bid<-data.frame(bid=dupe_baseDE-xs)
rs_base_DE<-rbind(rs_base_DE,inner_join(rs_base_DE,bid,by=c("Building_id0"="bid")))
rs_base_DE[(nrow(rs_base_DE)-length(dupe_baseDE)+1):nrow(rs_base_DE),]$Building_id0<-dupe_baseDE
rs_base_DE<-rs_base_DE[order(rs_base_DE$Building_id0),]
rs_base_DE$sim_year<-rep(rep(seq(2025,2060,5),each=xs)) # each = xs; xs depends on how many simulations for each year/scenario combo

# avg energy efficiency by cohort
tapply(rs_base_DE$Tot_MJ_m2,rs_base_DE$sim_year,mean)
tapply(rs_base_DE$Tot_GJ,rs_base_DE$sim_year,mean)

# reduced Floor Area
rs_base_RFA<-rs_base_sum[rs_base_sum$scen=="baseRFA",]
rs_base_RFA$cht_group<-0
rs_base_RFA[rs_base_RFA$sim_year==2030,]$cht_group<-1
rs_base_RFA[rs_base_RFA$sim_year==2035,]$cht_group<-2
rs_base_RFA[rs_base_RFA$sim_year==2040,]$cht_group<-3
rs_base_RFA[rs_base_RFA$sim_year==2045,]$cht_group<-4
rs_base_RFA[rs_base_RFA$sim_year==2050,]$cht_group<-5
rs_base_RFA[rs_base_RFA$sim_year==2055,]$cht_group<-6
rs_base_RFA[rs_base_RFA$sim_year==2060,]$cht_group<-7
rs_base_RFA$Building_id0<-(xs*rs_base_RFA$cht_group)+rs_base_RFA$Building_id
bid<-data.frame(bid=dupe_baseRFA-xs)
rs_base_RFA<-rbind(rs_base_RFA,inner_join(rs_base_RFA,bid,by=c("Building_id0"="bid")))
rs_base_RFA[(nrow(rs_base_RFA)-length(dupe_baseRFA)+1):nrow(rs_base_RFA),]$Building_id0<-dupe_baseRFA
rs_base_RFA<-rs_base_RFA[order(rs_base_RFA$Building_id0),]
rs_base_RFA$sim_year<-rep(rep(seq(2025,2060,5),each=xs)) # each = xs; xs depends on how many simulations for each year/scenario combo

# avg energy efficiency by cohort
tapply(rs_base_RFA$Tot_MJ_m2,rs_base_RFA$sim_year,mean)
tapply(rs_base_RFA$Tot_GJ,rs_base_RFA$sim_year,mean)

# reduced Floor Area
rs_base_DERFA<-rs_base_sum[rs_base_sum$scen=="baseDERFA",]
rs_base_DERFA$cht_group<-0
rs_base_DERFA[rs_base_DERFA$sim_year==2030,]$cht_group<-1
rs_base_DERFA[rs_base_DERFA$sim_year==2035,]$cht_group<-2
rs_base_DERFA[rs_base_DERFA$sim_year==2040,]$cht_group<-3
rs_base_DERFA[rs_base_DERFA$sim_year==2045,]$cht_group<-4
rs_base_DERFA[rs_base_DERFA$sim_year==2050,]$cht_group<-5
rs_base_DERFA[rs_base_DERFA$sim_year==2055,]$cht_group<-6
rs_base_DERFA[rs_base_DERFA$sim_year==2060,]$cht_group<-7
rs_base_DERFA$Building_id0<-(xs*rs_base_DERFA$cht_group)+rs_base_DERFA$Building_id
bid<-data.frame(bid=dupe_baseDERFA-xs)
rs_base_DERFA<-rbind(rs_base_DERFA,inner_join(rs_base_DERFA,bid,by=c("Building_id0"="bid")))
rs_base_DERFA[(nrow(rs_base_DERFA)-length(dupe_baseDERFA)+1):nrow(rs_base_DERFA),]$Building_id0<-dupe_baseDERFA
rs_base_DERFA<-rs_base_DERFA[order(rs_base_DERFA$Building_id0),]
rs_base_DERFA$sim_year<-rep(rep(seq(2025,2060,5),each=xs)) # each = xs; xs depends on how many simulations for each year/scenario combo

# avg energy efficiency by cohort
tapply(rs_base_DERFA$Tot_MJ_m2,rs_base_DERFA$sim_year,mean)
tapply(rs_base_DERFA$Tot_GJ,rs_base_DERFA$sim_year,mean)


# merge resstock hiDR stock scenario results with pre-simulation meta data #########
rs_hiDR_sum<-result_sum(rs_hiDR)
bs_hiDR_meta<-bs_hiDR_all[,c("Building","sim_year","scen","Building_id")]
rs_hiDR_sum<-merge(rs_hiDR_sum,bs_hiDR_meta,by.x = "building_id",by.y = "Building")
# extract individual results for hiDR stock scenarios, with different combinations of electrification/floor area characteristics
rs_hiDR_base<-rs_hiDR_sum[rs_hiDR_sum$scen=="hiDR",]
rs_hiDR_base$cht_group<-0
rs_hiDR_base[rs_hiDR_base$sim_year==2030,]$cht_group<-1
rs_hiDR_base[rs_hiDR_base$sim_year==2035,]$cht_group<-2
rs_hiDR_base[rs_hiDR_base$sim_year==2040,]$cht_group<-3
rs_hiDR_base[rs_hiDR_base$sim_year==2045,]$cht_group<-4
rs_hiDR_base[rs_hiDR_base$sim_year==2050,]$cht_group<-5
rs_hiDR_base[rs_hiDR_base$sim_year==2055,]$cht_group<-6
rs_hiDR_base[rs_hiDR_base$sim_year==2060,]$cht_group<-7
rs_hiDR_base$Building_id0<-(xs*rs_hiDR_base$cht_group)+rs_hiDR_base$Building_id
bid<-data.frame(bid=dupe_hiDR-xs)
rs_hiDR_base<-rbind(rs_hiDR_base,inner_join(rs_hiDR_base,bid,by=c("Building_id0"="bid")))
rs_hiDR_base[(nrow(rs_hiDR_base)-length(dupe_hiDR)+1):nrow(rs_hiDR_base),]$Building_id0<-dupe_hiDR
rs_hiDR_base<-rs_hiDR_base[order(rs_hiDR_base$Building_id0),]
rs_hiDR_base$sim_year<-rep(rep(seq(2025,2060,5),each=xs)) # each = xs; xs depends on how many simulations for each year/scenario combo

# avg energy efficiency by cohort
tapply(rs_hiDR_base$Tot_MJ_m2,rs_hiDR_base$sim_year,mean)
tapply(rs_hiDR_base$Tot_GJ,rs_hiDR_base$sim_year,mean)

# deep electrification
rs_hiDR_DE<-rs_hiDR_sum[rs_hiDR_sum$scen=="hiDRDE",]
rs_hiDR_DE$cht_group<-0
rs_hiDR_DE[rs_hiDR_DE$sim_year==2030,]$cht_group<-1
rs_hiDR_DE[rs_hiDR_DE$sim_year==2035,]$cht_group<-2
rs_hiDR_DE[rs_hiDR_DE$sim_year==2040,]$cht_group<-3
rs_hiDR_DE[rs_hiDR_DE$sim_year==2045,]$cht_group<-4
rs_hiDR_DE[rs_hiDR_DE$sim_year==2050,]$cht_group<-5
rs_hiDR_DE[rs_hiDR_DE$sim_year==2055,]$cht_group<-6
rs_hiDR_DE[rs_hiDR_DE$sim_year==2060,]$cht_group<-7
rs_hiDR_DE$Building_id0<-(xs*rs_hiDR_DE$cht_group)+rs_hiDR_DE$Building_id
bid<-data.frame(bid=dupe_hiDRDE-xs)
rs_hiDR_DE<-rbind(rs_hiDR_DE,inner_join(rs_hiDR_DE,bid,by=c("Building_id0"="bid")))
rs_hiDR_DE[(nrow(rs_hiDR_DE)-length(dupe_hiDRDE)+1):nrow(rs_hiDR_DE),]$Building_id0<-dupe_hiDRDE
rs_hiDR_DE<-rs_hiDR_DE[order(rs_hiDR_DE$Building_id0),]
rs_hiDR_DE$sim_year<-rep(rep(seq(2025,2060,5),each=xs)) # each = xs; xs depends on how many simulations for each year/scenario combo

# avg energy efficiency by cohort
tapply(rs_hiDR_DE$Tot_MJ_m2,rs_hiDR_DE$sim_year,mean)
tapply(rs_hiDR_DE$Tot_GJ,rs_hiDR_DE$sim_year,mean)

# reduced Floor Area
rs_hiDR_RFA<-rs_hiDR_sum[rs_hiDR_sum$scen=="hiDRRFA",]
rs_hiDR_RFA$cht_group<-0
rs_hiDR_RFA[rs_hiDR_RFA$sim_year==2030,]$cht_group<-1
rs_hiDR_RFA[rs_hiDR_RFA$sim_year==2035,]$cht_group<-2
rs_hiDR_RFA[rs_hiDR_RFA$sim_year==2040,]$cht_group<-3
rs_hiDR_RFA[rs_hiDR_RFA$sim_year==2045,]$cht_group<-4
rs_hiDR_RFA[rs_hiDR_RFA$sim_year==2050,]$cht_group<-5
rs_hiDR_RFA[rs_hiDR_RFA$sim_year==2055,]$cht_group<-6
rs_hiDR_RFA[rs_hiDR_RFA$sim_year==2060,]$cht_group<-7
rs_hiDR_RFA$Building_id0<-(xs*rs_hiDR_RFA$cht_group)+rs_hiDR_RFA$Building_id
bid<-data.frame(bid=dupe_hiDRRFA-xs)
rs_hiDR_RFA<-rbind(rs_hiDR_RFA,inner_join(rs_hiDR_RFA,bid,by=c("Building_id0"="bid")))
rs_hiDR_RFA[(nrow(rs_hiDR_RFA)-length(dupe_hiDRRFA)+1):nrow(rs_hiDR_RFA),]$Building_id0<-dupe_hiDRRFA
rs_hiDR_RFA<-rs_hiDR_RFA[order(rs_hiDR_RFA$Building_id0),]
rs_hiDR_RFA$sim_year<-rep(rep(seq(2025,2060,5),each=xs)) # each = xs; xs depends on how many simulations for each year/scenario combo

# avg energy efficiency by cohort
tapply(rs_hiDR_RFA$Tot_MJ_m2,rs_hiDR_RFA$sim_year,mean)
tapply(rs_hiDR_RFA$Tot_GJ,rs_hiDR_RFA$sim_year,mean)

# reduced Floor Area
rs_hiDR_DERFA<-rs_hiDR_sum[rs_hiDR_sum$scen=="hiDRDERFA",]
rs_hiDR_DERFA$cht_group<-0
rs_hiDR_DERFA[rs_hiDR_DERFA$sim_year==2030,]$cht_group<-1
rs_hiDR_DERFA[rs_hiDR_DERFA$sim_year==2035,]$cht_group<-2
rs_hiDR_DERFA[rs_hiDR_DERFA$sim_year==2040,]$cht_group<-3
rs_hiDR_DERFA[rs_hiDR_DERFA$sim_year==2045,]$cht_group<-4
rs_hiDR_DERFA[rs_hiDR_DERFA$sim_year==2050,]$cht_group<-5
rs_hiDR_DERFA[rs_hiDR_DERFA$sim_year==2055,]$cht_group<-6
rs_hiDR_DERFA[rs_hiDR_DERFA$sim_year==2060,]$cht_group<-7
rs_hiDR_DERFA$Building_id0<-(xs*rs_hiDR_DERFA$cht_group)+rs_hiDR_DERFA$Building_id
bid<-data.frame(bid=dupe_hiDRDERFA-xs)
rs_hiDR_DERFA<-rbind(rs_hiDR_DERFA,inner_join(rs_hiDR_DERFA,bid,by=c("Building_id0"="bid")))
rs_hiDR_DERFA[(nrow(rs_hiDR_DERFA)-length(dupe_hiDRDERFA)+1):nrow(rs_hiDR_DERFA),]$Building_id0<-dupe_hiDRDERFA
rs_hiDR_DERFA<-rs_hiDR_DERFA[order(rs_hiDR_DERFA$Building_id0),]
rs_hiDR_DERFA$sim_year<-rep(rep(seq(2025,2060,5),each=xs)) # each = xs; xs depends on how many simulations for each year/scenario combo

# avg energy efficiency by cohort
tapply(rs_hiDR_DERFA$Tot_MJ_m2,rs_hiDR_DERFA$sim_year,mean)
tapply(rs_hiDR_DERFA$Tot_GJ,rs_hiDR_DERFA$sim_year,mean)

# merge resstock hiDR stock scenario results with pre-simulation meta data #########
rs_hiMF_sum<-result_sum(rs_hiMF)
bs_hiMF_meta<-bs_hiMF_all[,c("Building","sim_year","scen","Building_id")]
rs_hiMF_sum<-merge(rs_hiMF_sum,bs_hiMF_meta,by.x = "building_id",by.y = "Building")
# extract individual results for hiMF stock scenarios, with different combinations of electrification/floor area characteristics
rs_hiMF_base<-rs_hiMF_sum[rs_hiMF_sum$scen=="hiMF",]
rs_hiMF_base$cht_group<-0
rs_hiMF_base[rs_hiMF_base$sim_year==2030,]$cht_group<-1
rs_hiMF_base[rs_hiMF_base$sim_year==2035,]$cht_group<-2
rs_hiMF_base[rs_hiMF_base$sim_year==2040,]$cht_group<-3
rs_hiMF_base[rs_hiMF_base$sim_year==2045,]$cht_group<-4
rs_hiMF_base[rs_hiMF_base$sim_year==2050,]$cht_group<-5
rs_hiMF_base[rs_hiMF_base$sim_year==2055,]$cht_group<-6
rs_hiMF_base[rs_hiMF_base$sim_year==2060,]$cht_group<-7
rs_hiMF_base$Building_id0<-(xs*rs_hiMF_base$cht_group)+rs_hiMF_base$Building_id
bid<-data.frame(bid=dupe_hiMF-xs)
rs_hiMF_base<-rbind(rs_hiMF_base,inner_join(rs_hiMF_base,bid,by=c("Building_id0"="bid")))
rs_hiMF_base[(nrow(rs_hiMF_base)-length(dupe_hiMF)+1):nrow(rs_hiMF_base),]$Building_id0<-dupe_hiMF
rs_hiMF_base<-rs_hiMF_base[order(rs_hiMF_base$Building_id0),]
rs_hiMF_base$sim_year<-rep(rep(seq(2025,2060,5),each=xs)) # each = xs; xs depends on how many simulations for each year/scenario combo

# avg energy efficiency by cohort
tapply(rs_hiMF_base$Tot_MJ_m2,rs_hiMF_base$sim_year,mean)
tapply(rs_hiMF_base$Tot_GJ,rs_hiMF_base$sim_year,mean)

# deep electrification
rs_hiMF_DE<-rs_hiMF_sum[rs_hiMF_sum$scen=="hiMFDE",]
rs_hiMF_DE$cht_group<-0
rs_hiMF_DE[rs_hiMF_DE$sim_year==2030,]$cht_group<-1
rs_hiMF_DE[rs_hiMF_DE$sim_year==2035,]$cht_group<-2
rs_hiMF_DE[rs_hiMF_DE$sim_year==2040,]$cht_group<-3
rs_hiMF_DE[rs_hiMF_DE$sim_year==2045,]$cht_group<-4
rs_hiMF_DE[rs_hiMF_DE$sim_year==2050,]$cht_group<-5
rs_hiMF_DE[rs_hiMF_DE$sim_year==2055,]$cht_group<-6
rs_hiMF_DE[rs_hiMF_DE$sim_year==2060,]$cht_group<-7
rs_hiMF_DE$Building_id0<-(xs*rs_hiMF_DE$cht_group)+rs_hiMF_DE$Building_id
bid<-data.frame(bid=dupe_hiMFDE-xs)
rs_hiMF_DE<-rbind(rs_hiMF_DE,inner_join(rs_hiMF_DE,bid,by=c("Building_id0"="bid")))
rs_hiMF_DE[(nrow(rs_hiMF_DE)-length(dupe_hiMFDE)+1):nrow(rs_hiMF_DE),]$Building_id0<-dupe_hiMFDE
rs_hiMF_DE<-rs_hiMF_DE[order(rs_hiMF_DE$Building_id0),]
rs_hiMF_DE$sim_year<-rep(rep(seq(2025,2060,5),each=xs)) # each = xs; xs depends on how many simulations for each year/scenario combo

# avg energy efficiency by cohort
tapply(rs_hiMF_DE$Tot_MJ_m2,rs_hiMF_DE$sim_year,mean)
tapply(rs_hiMF_DE$Tot_GJ,rs_hiMF_DE$sim_year,mean)

# reduced Floor Area
rs_hiMF_RFA<-rs_hiMF_sum[rs_hiMF_sum$scen=="hiMFRFA",]
rs_hiMF_RFA$cht_group<-0
rs_hiMF_RFA[rs_hiMF_RFA$sim_year==2030,]$cht_group<-1
rs_hiMF_RFA[rs_hiMF_RFA$sim_year==2035,]$cht_group<-2
rs_hiMF_RFA[rs_hiMF_RFA$sim_year==2040,]$cht_group<-3
rs_hiMF_RFA[rs_hiMF_RFA$sim_year==2045,]$cht_group<-4
rs_hiMF_RFA[rs_hiMF_RFA$sim_year==2050,]$cht_group<-5
rs_hiMF_RFA[rs_hiMF_RFA$sim_year==2055,]$cht_group<-6
rs_hiMF_RFA[rs_hiMF_RFA$sim_year==2060,]$cht_group<-7
rs_hiMF_RFA$Building_id0<-(xs*rs_hiMF_RFA$cht_group)+rs_hiMF_RFA$Building_id
bid<-data.frame(bid=dupe_hiMFRFA-xs)
rs_hiMF_RFA<-rbind(rs_hiMF_RFA,inner_join(rs_hiMF_RFA,bid,by=c("Building_id0"="bid")))
rs_hiMF_RFA[(nrow(rs_hiMF_RFA)-length(dupe_hiMFRFA)+1):nrow(rs_hiMF_RFA),]$Building_id0<-dupe_hiMFRFA
rs_hiMF_RFA<-rs_hiMF_RFA[order(rs_hiMF_RFA$Building_id0),]
rs_hiMF_RFA$sim_year<-rep(rep(seq(2025,2060,5),each=xs)) # each = xs; xs depends on how many simulations for each year/scenario combo

# avg energy efficiency by cohort
tapply(rs_hiMF_RFA$Tot_MJ_m2,rs_hiMF_RFA$sim_year,mean)
tapply(rs_hiMF_RFA$Tot_GJ,rs_hiMF_RFA$sim_year,mean)

# reduced Floor Area
rs_hiMF_DERFA<-rs_hiMF_sum[rs_hiMF_sum$scen=="hiMFDERFA",]
rs_hiMF_DERFA$cht_group<-0
rs_hiMF_DERFA[rs_hiMF_DERFA$sim_year==2030,]$cht_group<-1
rs_hiMF_DERFA[rs_hiMF_DERFA$sim_year==2035,]$cht_group<-2
rs_hiMF_DERFA[rs_hiMF_DERFA$sim_year==2040,]$cht_group<-3
rs_hiMF_DERFA[rs_hiMF_DERFA$sim_year==2045,]$cht_group<-4
rs_hiMF_DERFA[rs_hiMF_DERFA$sim_year==2050,]$cht_group<-5
rs_hiMF_DERFA[rs_hiMF_DERFA$sim_year==2055,]$cht_group<-6
rs_hiMF_DERFA[rs_hiMF_DERFA$sim_year==2060,]$cht_group<-7
rs_hiMF_DERFA$Building_id0<-(xs*rs_hiMF_DERFA$cht_group)+rs_hiMF_DERFA$Building_id
bid<-data.frame(bid=dupe_hiMFDERFA-xs)
rs_hiMF_DERFA<-rbind(rs_hiMF_DERFA,inner_join(rs_hiMF_DERFA,bid,by=c("Building_id0"="bid")))
rs_hiMF_DERFA[(nrow(rs_hiMF_DERFA)-length(dupe_hiMFDERFA)+1):nrow(rs_hiMF_DERFA),]$Building_id0<-dupe_hiMFDERFA
rs_hiMF_DERFA<-rs_hiMF_DERFA[order(rs_hiMF_DERFA$Building_id0),]
rs_hiMF_DERFA$sim_year<-rep(rep(seq(2025,2060,5),each=xs)) # each = xs; xs depends on how many simulations for each year/scenario combo

# avg energy efficiency by cohort
tapply(rs_hiMF_DERFA$Tot_MJ_m2,rs_hiMF_DERFA$sim_year,mean)
tapply(rs_hiMF_DERFA$Tot_GJ,rs_hiMF_DERFA$sim_year,mean)

# compare efficiencies
tapply(rs_base_base$Tot_GJ,rs_base_base$vintage,mean)
tapply(rs_base_DE$Tot_GJ,rs_base_DE$vintage,mean)
tapply(rs_base_RFA$Tot_GJ,rs_base_RFA$vintage,mean)
tapply(rs_base_DERFA$Tot_GJ,rs_base_DERFA$vintage,mean)

tapply(rs_hiDR_base$Tot_GJ,rs_hiDR_base$vintage,mean)
tapply(rs_hiDR_DE$Tot_GJ,rs_hiDR_DE$vintage,mean)
tapply(rs_hiDR_RFA$Tot_GJ,rs_hiDR_RFA$vintage,mean)
tapply(rs_hiDR_DERFA$Tot_GJ,rs_hiDR_DERFA$vintage,mean)

tapply(rs_hiMF_base$Tot_GJ,rs_hiMF_base$vintage,mean)
tapply(rs_hiMF_DE$Tot_GJ,rs_hiMF_DE$vintage,mean)
tapply(rs_hiMF_RFA$Tot_GJ,rs_hiMF_RFA$vintage,mean)
tapply(rs_hiMF_DERFA$Tot_GJ,rs_hiMF_DERFA$vintage,mean)

tapply(rs_2020_sum$Tot_GJ,rs_2020_sum$vintage,mean)

save(rs_2020_sum,rs_base_base,rs_base_DE,rs_base_RFA,rs_base_DERFA,
     rs_hiDR_base,rs_hiDR_DE,rs_hiDR_RFA,rs_hiDR_DERFA,
     rs_hiMF_base,rs_hiMF_DE,rs_hiMF_RFA,rs_hiMF_DERFA,file="../Final_results/results_summaries.RData")

# compared household energy by different groups
# tapply(d$Tot_GJ_unit,d$building_america_climate_zone,mean)
# 
# tapply(d$Tot_GJ_unit,d$geometry_building_type_recs,mean)
# 
# tapply(d$Tot_GJ_unit,d$vintage,mean)
# 
# tapply(d$Tot_MJ_m2,d$geometry_building_type_recs,mean)

d10<-result_sum(rs2010)
d20<-result_sum(rs2020)
d30<-result_sum(rs2030)
d40<-result_sum(rs2040)
d50<-result_sum(rs2050)

tapply(d10$Oil_GJ,d10$heating_fuel,mean)
tapply(d20$Oil_GJ,d20$heating_fuel,mean) # ok there are no new homes built with oil

tapply(d10$Gas_GJ,d10$heating_fuel,mean)
tapply(d20$Gas_GJ,d20$heating_fuel,mean)
tapply(d30$Gas_GJ,d30$heating_fuel,mean)
tapply(d40$Gas_GJ,d40$heating_fuel,mean)
tapply(d50$Gas_GJ,d50$heating_fuel,mean)

tapply(d10$Gas_GJ,list(d10$heating_fuel,d10$water_heater_fuel),mean)
# compare 2010s with 2020s ##########
d10$Gas_GJ_20<-NA
d10$Elec_GJ_20<-NA
d10$Prop_GJ_20<-NA
for (i in 1:nrow(d10)) {
  for (j in 1:nrow(d20)) {
    # d10[d10$building_id[i]==d20$building_id[j],]$Gas_GJ_20<-d20$Gas_GJ[j]
    if (d10$building_id[i]==d20$building_id[j] & d10$heating_fuel[i]==d20$heating_fuel[j] &d10$water_heater_fuel[i]==d20$water_heater_fuel[j]) {
      d10$Gas_GJ_20[i]<-d20$Gas_GJ[j]
      d10$Elec_GJ_20[i]<-d20$Elec_GJ[j]
      d10$Prop_GJ_20[i]<-d20$Prop_GJ[j]
    }
  }
}
d10$Gas_GJ_20_10<-d10$Gas_GJ_20/d10$Gas_GJ
d10[is.nan(d10$Gas_GJ_20_10) | is.infinite((d10$Gas_GJ_20_10)),]$Gas_GJ_20_10<-NA
mean(d10$Gas_GJ_20_10,na.rm = TRUE) # 15% reduction in gas in 2020 vs 2010
mean(d10[d10$geometry_building_type_recs %in% c("Single-Family Detached","Single-Family Attached"),]$Gas_GJ_20_10,na.rm = TRUE ) # 14% in SF
mean(d10[d10$geometry_building_type_recs %in% c("Multi-Family with 2-4 Units","Multi-Family with 5+ Units"),]$Gas_GJ_20_10,na.rm = TRUE ) # 26% in MF

d10$Elec_GJ_20_10<-d10$Elec_GJ_20/d10$Elec_GJ
d10[is.nan(d10$Elec_GJ_20_10) | is.infinite((d10$Elec_GJ_20_10)),]$Elec_GJ_20_10<-NA # not applicable to elec
mean(d10$Elec_GJ_20_10,na.rm = TRUE) # 9% reduction in Elec in 2020 vs 2010
mean(d10[d10$geometry_building_type_recs %in% c("Single-Family Detached","Single-Family Attached"),]$Elec_GJ_20_10,na.rm = TRUE ) # 8% in SF
mean(d10[d10$geometry_building_type_recs %in% c("Multi-Family with 2-4 Units","Multi-Family with 5+ Units"),]$Elec_GJ_20_10,na.rm = TRUE ) # 14% in MF

d10$Prop_GJ_20_10<-d10$Prop_GJ_20/d10$Prop_GJ
d10[is.nan(d10$Prop_GJ_20_10) | is.infinite((d10$Prop_GJ_20_10)),]$Prop_GJ_20_10<-NA
mean(d10$Prop_GJ_20_10,na.rm = TRUE) # 42% reduction in Prop in 2020 vs 2010, not sure if i believe, or probably a very small sample
# compare with 2030s ########
d10$Gas_GJ_30<-NA
d10$Elec_GJ_30<-NA
d10$Prop_GJ_30<-NA
for (i in 1:nrow(d10)) {
  for (j in 1:nrow(d30)) {
    # d10[d10$building_id[i]==d30$building_id[j],]$Gas_GJ_30<-d30$Gas_GJ[j]
    if (d10$building_id[i]==d30$building_id[j] & d10$heating_fuel[i]==d30$heating_fuel[j] &d10$water_heater_fuel[i]==d30$water_heater_fuel[j]) {
      d10$Gas_GJ_30[i]<-d30$Gas_GJ[j]
      d10$Elec_GJ_30[i]<-d30$Elec_GJ[j]
      d10$Prop_GJ_30[i]<-d30$Prop_GJ[j]
    }
  }
}
d10$Gas_GJ_30_10<-d10$Gas_GJ_30/d10$Gas_GJ
d10[is.nan(d10$Gas_GJ_30_10) | is.infinite((d10$Gas_GJ_30_10)),]$Gas_GJ_30_10<-NA
mean(d10$Gas_GJ_30_10,na.rm = TRUE) # 28% reduction in gas in 2030 vs 2010
mean(d10[d10$geometry_building_type_recs %in% c("Single-Family Detached","Single-Family Attached"),]$Gas_GJ_30_10,na.rm = TRUE ) # 28% in SF
mean(d10[d10$geometry_building_type_recs %in% c("Multi-Family with 2-4 Units","Multi-Family with 5+ Units"),]$Gas_GJ_30_10,na.rm = TRUE ) # 24% in MF

d10$Elec_GJ_30_10<-d10$Elec_GJ_30/d10$Elec_GJ
d10[is.nan(d10$Elec_GJ_30_10) | is.infinite((d10$Elec_GJ_30_10)),]$Elec_GJ_30_10<-NA # not applicable to elec
mean(d10$Elec_GJ_30_10,na.rm = TRUE) # 16% reduction in Elec in 2030 vs 2010
mean(d10[d10$geometry_building_type_recs %in% c("Single-Family Detached","Single-Family Attached"),]$Elec_GJ_30_10,na.rm = TRUE ) # 16% in SF
mean(d10[d10$geometry_building_type_recs %in% c("Multi-Family with 2-4 Units","Multi-Family with 5+ Units"),]$Elec_GJ_30_10,na.rm = TRUE ) # 15% in MF

d10$Prop_GJ_30_10<-d10$Prop_GJ_30/d10$Prop_GJ
d10[is.nan(d10$Prop_GJ_30_10) | is.infinite((d10$Prop_GJ_30_10)),]$Prop_GJ_30_10<-NA
mean(d10$Prop_GJ_30_10,na.rm = TRUE) # 54% reduction in Prop in 2020 vs 2010, not sure if i believe, or probably a very small sample

# compare with 2040s ########
d10$Gas_GJ_40<-NA
d10$Elec_GJ_40<-NA
d10$Prop_GJ_40<-NA
for (i in 1:nrow(d10)) {
  for (j in 1:nrow(d40)) {
    # d10[d10$building_id[i]==d40$building_id[j],]$Gas_GJ_40<-d40$Gas_GJ[j]
    if (d10$building_id[i]==d40$building_id[j] & d10$heating_fuel[i]==d40$heating_fuel[j] &d10$water_heater_fuel[i]==d40$water_heater_fuel[j]) {
      d10$Gas_GJ_40[i]<-d40$Gas_GJ[j]
      d10$Elec_GJ_40[i]<-d40$Elec_GJ[j]
      d10$Prop_GJ_40[i]<-d40$Prop_GJ[j]
    }
  }
}
d10$Gas_GJ_40_10<-d10$Gas_GJ_40/d10$Gas_GJ
d10[is.nan(d10$Gas_GJ_40_10) | is.infinite((d10$Gas_GJ_40_10)),]$Gas_GJ_40_10<-NA
mean(d10$Gas_GJ_40_10,na.rm = TRUE) # 35% reduction in gas in 2040 vs 2010
mean(d10[d10$geometry_building_type_recs %in% c("Single-Family Detached","Single-Family Attached"),]$Gas_GJ_40_10,na.rm = TRUE ) # 36% in SF
mean(d10[d10$geometry_building_type_recs %in% c("Multi-Family with 2-4 Units","Multi-Family with 5+ Units"),]$Gas_GJ_40_10,na.rm = TRUE ) # 29% in MF, 8 observations

d10$Elec_GJ_40_10<-d10$Elec_GJ_40/d10$Elec_GJ
d10[is.nan(d10$Elec_GJ_40_10) | is.infinite((d10$Elec_GJ_40_10)),]$Elec_GJ_40_10<-NA # not applicable to elec
mean(d10$Elec_GJ_40_10,na.rm = TRUE) # 22% reduction in Elec in 2040 vs 2010
mean(d10[d10$geometry_building_type_recs %in% c("Single-Family Detached","Single-Family Attached"),]$Elec_GJ_40_10,na.rm = TRUE ) # 23% in SF
mean(d10[d10$geometry_building_type_recs %in% c("Multi-Family with 2-4 Units","Multi-Family with 5+ Units"),]$Elec_GJ_40_10,na.rm = TRUE ) # 18% in MF, 14 observations

d10$Prop_GJ_40_10<-d10$Prop_GJ_40/d10$Prop_GJ
d10[is.nan(d10$Prop_GJ_40_10) | is.infinite((d10$Prop_GJ_40_10)),]$Prop_GJ_40_10<-NA
mean(d10$Prop_GJ_40_10,na.rm = TRUE) # 60% reduction in Prop in 2020 vs 2010, not sure if i believe, or probably a very small sample

# compare with 2050s ########
d10$Gas_GJ_50<-NA
d10$Elec_GJ_50<-NA
d10$Prop_GJ_50<-NA
for (i in 1:nrow(d10)) {
  for (j in 1:nrow(d50)) {
    # d10[d10$building_id[i]==d50$building_id[j],]$Gas_GJ_50<-d50$Gas_GJ[j]
    if (d10$building_id[i]==d50$building_id[j] & d10$heating_fuel[i]==d50$heating_fuel[j] &d10$water_heater_fuel[i]==d50$water_heater_fuel[j]) {
      d10$Gas_GJ_50[i]<-d50$Gas_GJ[j]
      d10$Elec_GJ_50[i]<-d50$Elec_GJ[j]
      d10$Prop_GJ_50[i]<-d50$Prop_GJ[j]
    }
  }
}
d10$Gas_GJ_50_10<-d10$Gas_GJ_50/d10$Gas_GJ
d10[is.nan(d10$Gas_GJ_50_10) | is.infinite((d10$Gas_GJ_50_10)),]$Gas_GJ_50_10<-NA
mean(d10$Gas_GJ_50_10,na.rm = TRUE) # 36% reduction in gas in 2050 vs 2010
mean(d10[d10$geometry_building_type_recs %in% c("Single-Family Detached","Single-Family Attached"),]$Gas_GJ_50_10,na.rm = TRUE ) # 43% in SF
mean(d10[d10$geometry_building_type_recs %in% c("Multi-Family with 2-4 Units","Multi-Family with 5+ Units"),]$Gas_GJ_50_10,na.rm = TRUE ) # 7% in MF, base on only 5 observations

d10$Elec_GJ_50_10<-d10$Elec_GJ_50/d10$Elec_GJ
d10[is.nan(d10$Elec_GJ_50_10) | is.infinite((d10$Elec_GJ_50_10)),]$Elec_GJ_50_10<-NA # not applicable to elec
mean(d10$Elec_GJ_50_10,na.rm = TRUE) # 25% reduction in Elec in 2050 vs 2010
mean(d10[d10$geometry_building_type_recs %in% c("Single-Family Detached","Single-Family Attached"),]$Elec_GJ_50_10,na.rm = TRUE ) # 26% in SF, 48 observation
mean(d10[d10$geometry_building_type_recs %in% c("Multi-Family with 2-4 Units","Multi-Family with 5+ Units"),]$Elec_GJ_50_10,na.rm = TRUE ) # 24% in MF, 10 observations

d10$Prop_GJ_50_10<-d10$Prop_GJ_50/d10$Prop_GJ
d10[is.nan(d10$Prop_GJ_50_10) | is.infinite((d10$Prop_GJ_50_10)),]$Prop_GJ_50_10<-NA
mean(d10$Prop_GJ_50_10,na.rm = TRUE) # 0% reduction in Prop in 2020 vs 2010, not sure if i believe, or probably a very small sample
