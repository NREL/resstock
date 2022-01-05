# this section comes after the re-simulations have been done in Eagle ###########

rm(list=ls()) # clear workspace i.e. remove saved variables
cat("\014") # clear console
library(dplyr)
library(reshape2)
setwd("~/Yale Courses/Research/Final Paper/resstock_projections/")

filenames<-c("res_RR_2025","res_RR_2030","res_RR_2035","res_RR_2040",
            "res_RR_2045","res_RR_2050","res_RR_2055","res_RR_2060",
            "res_AR_2025","res_AR_2030","res_AR_2035","res_AR_2040",
            "res_AR_2045","res_AR_2050","res_AR_2055","res_AR_2060",
            "res_2020","res_base","res_baseDE","res_baseDERFA","res_baseRFA",
            "res_hiDR","res_hiDRDE","res_hiDRDERFA","res_hiDRRFA",
            "res_hiMF","res_hiMFDE","res_hiMFDERFA","res_hiMFRFA",
            "res_ER_2025","res_ER_2030","res_ER_2035","res_ER_2040",
            "res_ER_2045","res_ER_2050","res_ER_2055","res_ER_2060")

# rs<-read.csv("Eagle_outputs/res_RR_2025.csv")
# rs1<-read.csv("Eagle_outputs/HP_redo/res_RR_2025_redo.csv")
# 
# rs0<-rs[!rs$building_id %in% rs1$building_id,]
# 
# rsn<-rbind(rs0,rs1)
# 
# rsn<-rsn[order(rsn$building_id),]
# identical(rs$building_id,rsn$building_id) # this should be true
# 
# mean(rs$simulation_output_report.total_site_energy_mbtu,na.rm = TRUE)
# mean(rsn$simulation_output_report.total_site_energy_mbtu,na.rm = TRUE) # about a 5% increase in avg total energy for AR55
# 
# mean(rs$simulation_output_report.hvac_heating_capacity_w,na.rm = TRUE)
# mean(rsn$simulation_output_report.hvac_heating_capacity_w,na.rm = TRUE) # about a 20% increase in avg heating capacity
# 
# mean(rs$simulation_output_report.electricity_heating_kwh,na.rm = TRUE)
# mean(rsn$simulation_output_report.electricity_heating_kwh,na.rm = TRUE) # about a 27% increase in avg electric heating
# 
# save(rsn,file="Eagle_outputs/Complete_results/res_RR_2025_final.RData")
odd<-seq(1,1001,2)
# now do for all in a function #########
identical_id<-rite_size<-any_dupe<-any_fail<-inc_elec_SPH<-inc_heat_cap<-inc_tot_GJ<-data.frame(df=filenames,val=rep(0,length(filenames)))

for (k in 1:37) { print(k)
  if (k<17 | k >29) {rs<-read.csv(paste("Eagle_outputs/",filenames[k],".csv",sep=""))}
  if (k==17) {rs<-read.csv("Eagle_outputs/res_2020_complete.csv")}
  if (k %in% 18:29) {rs<-read.csv(paste("Eagle_outputs/",substr(filenames[k],1,4),"proj_",substr(filenames[k],5,nchar(filenames[k])),".csv",sep=""))}
  rs1<-read.csv(paste("Eagle_outputs/HP_redo/",filenames[k],"_redo.csv",sep=""))
  
  bs1_fn<-paste("scen_bscsv_sim/HP_redo/",gsub("res","bs",filenames[k]),"_redo.csv",sep="")
  if (k==17) {bs1_fn<-"scen_bscsv_sim/HP_redo/bs2020_180k_redo.csv"}
  bs1<-read.csv(bs1_fn)
  
  rite_size[k,"val"]<-nrow(bs1)==nrow(rs1)
  
  rs0<-rs[!rs$building_id %in% rs1$building_id,]
  
  rsn<-rbind(rs0,rs1)
  
  if (k==16) {
    rs2<-read.csv(paste("Eagle_outputs/HP_redo/",filenames[k],"_redo2.csv",sep=""))
    rs3<-rbind(rs1,rs2)
    rs0<-rs[!rs$building_id %in% rs3$building_id,]
    rsn<-rbind(rs0,rs3)
    }
  
  if (nrow(rsn)>nrow(rs)) { any_dupe[k,"val"]<-1
    
    t2<-as.data.frame(table(rsn$building_id))
    t2b<-as.numeric(as.character(t2[which(t2$Freq>1),1]))
    
    rst<-rs1[rs1$building_id %in% t2b,]
    rst<-rst[rst$build_existing_model.hvac_cooling_type=="Heat Pump",]
    
    rst[,2:4]<-NA
    # rstn<-unique(rst) for some reason this doesn't remove all dupes
    o<-odd[1:(nrow(rst)/2)]
    rstn<-rst[o,]
    rs1<-rs1[!rs1$building_id %in% t2b,]
    rs1<-rbind(rs1,rstn)
    rs1<-rs1[order(rs1$building_id),]
    rsn<-rbind(rs0,rs1)
    }
  
  rsn<-rsn[order(rsn$building_id),]
  identical_id[k,"val"]<-identical(rs$building_id,rsn$building_id) # this should be true
  
  
  inc_tot_GJ[k,"val"]<-100*(mean(rsn$simulation_output_report.total_site_energy_mbtu,na.rm = TRUE)/
    mean(rs$simulation_output_report.total_site_energy_mbtu,na.rm = TRUE)-1)
  
  inc_heat_cap[k,"val"]<-100*(mean(rsn$simulation_output_report.hvac_heating_capacity_w,na.rm = TRUE)/
                          mean(rs$simulation_output_report.hvac_heating_capacity_w,na.rm = TRUE)-1)
  
  inc_elec_SPH[k,"val"]<-100*(mean(rsn$simulation_output_report.electricity_heating_kwh,na.rm = TRUE)/
                          mean(rs$simulation_output_report.electricity_heating_kwh,na.rm = TRUE)-1)
  
  any_fail[k,"val"]<-any(!rsn$completed_status=="Success")
 
  # fn_save<-paste("Eagle_outputs/Complete_results/",filenames[k],"_final.RData",sep="")
  # save(rsn,file=fn_save)
}
all(identical_id$val==1)
all(rite_size$val==1) # only AR 2060 has false.

tapply(rs1$simulation_output_report.electricity_heating_kwh,
       list(rs1$build_existing_model.hvac_heating_efficiency,rs1$build_existing_model.climate_zone_ba),median)
tapply(rs1$simulation_output_report.hvac_heating_capacity_w,
       list(rs1$build_existing_model.hvac_heating_efficiency,rs1$build_existing_model.climate_zone_ba),median)
tapply(rs1$simulation_output_report.hours_heating_setpoint_not_met,
       list(rs1$build_existing_model.hvac_heating_efficiency,rs1$build_existing_model.climate_zone_ba),median)
tapply(rs1$simulation_output_report.total_site_energy_mbtu,
       list(rs1$build_existing_model.hvac_heating_efficiency,rs1$build_existing_model.climate_zone_ba),median)

# now do some more results checks #######
# replace the 2055 AR fail with the 2060 AR version of the same building
load("Eagle_outputs/Complete_results/res_AR_2055_final.RData")
AR55<-rsn
load("Eagle_outputs/Complete_results/res_AR_2060_final.RData")
AR60<-rsn
f55<-AR60[AR60$building_id==31042,]
f<-AR55[!AR55$completed_status=="Success",]
AR55<-AR55[AR55$completed_status=="Success",]
AR55<-rbind(AR55,f55)
AR55<-AR55[order(AR55$building_id),]
save(AR55,file="Eagle_outputs/Complete_results/res_AR_2055_final.RData")
# replace the 2030 ER fails
rm(rsn)
load("Eagle_outputs/Complete_results/res_ER_2030_final.RData")
ER30<-rsn
load("Eagle_outputs/Complete_results/res_ER_2040_final.RData")
ER40<-rsn
load("Eagle_outputs/Complete_results/res_ER_2055_final.RData")
ER55<-rsn
f<-ER30[!ER30$completed_status=="Success",]
ER30<-ER30[ER30$completed_status=="Success",]
f30<-ER55[ER55$building_id==116166,]
f30[2,]<-ER40[ER40$building_id==130823,]
rm(rsn)
rsn<-rbind(ER30,f30)
rsn<-rsn[order(rsn$building_id),]
all(rsn$completed_status=='Success') # this should be true
save(rsn,file="Eagle_outputs/Complete_results/res_ER_2030_final.RData")

# replace 2040 ER fails
f<-ER40[!ER40$completed_status=="Success",]
ER40<-ER40[ER40$completed_status=="Success",]
f40<-ER55[ER55$building_id==116166,]
rm(rsn)
rsn<-rbind(ER40,f40)
rsn<-rsn[order(rsn$building_id),]
all(rsn$completed_status=='Success') # this should be true
save(rsn,file="Eagle_outputs/Complete_results/res_ER_2040_final.RData")

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
AR55s<-result_sum(AR55,2055)

round(tapply(AR55s$Tot_GJ_SPH,AR55s$hvac_heating_efficiency,mean),1)
round(tapply(AR55s$hours_heating_setpoint_not_met,AR55s$hvac_heating_efficiency,mean),1)
tapply(AR55s$Tot_GJ_SPH,AR55s$hvac_heating_efficiency,length)

round(tapply(AR55s$Tot_GJ_SPH,AR55s$hvac_heating_type_and_fuel,mean),1)
round(tapply(AR55s$hours_heating_setpoint_not_met,AR55s$hvac_heating_type_and_fuel,mean),1)

round(tapply(AR55s$Tot_GJ_SPH,AR55s$hvac_cooling_type,mean),1)
round(tapply(AR55s$hours_heating_setpoint_not_met,AR55s$hvac_cooling_type,mean),1)

round(tapply(AR55s$Tot_GJ_SPH,AR55s$hvac_has_shared_system,mean),1)
round(tapply(AR55s$hours_heating_setpoint_not_met,AR55s$hvac_has_shared_system,mean),1)

AR60s<-result_sum(AR60,2060)
round(tapply(AR60s$Tot_GJ_SPH,AR60s$hvac_heating_efficiency,mean),1)
round(tapply(AR60s$hours_heating_setpoint_not_met,AR60s$hvac_heating_efficiency,mean),1)
tapply(AR60s$Tot_GJ_SPH,AR60s$hvac_heating_efficiency,length)

round(tapply(AR60s$Tot_GJ_SPH,AR60s$hvac_heating_type_and_fuel,mean),1)
round(tapply(AR60s$hours_heating_setpoint_not_met,AR60s$hvac_heating_type_and_fuel,mean),1)

round(tapply(AR60s$Tot_GJ_SPH,AR60s$hvac_cooling_type,mean),1)
round(tapply(AR60s$hours_heating_setpoint_not_met,AR60s$hvac_cooling_type,mean),1)

round(tapply(AR60s$Tot_GJ_SPH,AR60s$hvac_has_shared_system,mean),1)
round(tapply(AR60s$hours_heating_setpoint_not_met,AR60s$hvac_has_shared_system,mean),1)
