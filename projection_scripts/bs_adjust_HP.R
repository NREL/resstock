rm(list=ls()) # clear workspace i.e. remove saved variables
cat("\014") # clear console

# Last Update Peter Berrill April 30 2022

# Purpose: Adjust renovation bs files which ended up with ASHP files with Heating Type != Ducted Heat Pump and MSHP with Heating Type != Non-Ducted Heat Pump. 
# Make sure that the characteristics HVAC.Heating.Type, HVAC.Heating.Type.And.Fuel, HVAC.Cooling.Type, HVAC.Cooling.Efficiency, HVAC.Has.Shared.System, HVAC.Shared.Efficiencies, are internally consistent and compatible

# Inputs: - all bscsv files in scen_bscsv_sim
#         - all res* (resstock) files (excluding fails) in ../Eagle_outputs/

# Outputs:- all bscsv files in scen_bscsv_sim\HP_redo (a small fraction of 2020 and RR files are affected, a larger share of AR and especially ER files are affected, these needed to be re-simulated)

library(dplyr)
library(reshape2)
setwd("~/Yale Courses/Research/Final Paper/resstock_projections/scen_bscsv_sim")

rm_dot2<-function(df) {
  cn<-names(df)
  cn<-gsub("Dependency.", "Dependency=",cn)
  cn<-gsub("Option..1940", "Option=<1940",cn)
  cn<-gsub("Option.", "Option=",cn)
  cn<-gsub("\\.", " ",cn)
  cn<-gsub("Single.","Single-",cn)
  names(df)<-cn
  df
}

bs<-read.csv('bs_AR_2055.csv')

table(bs$HVAC.Heating.Type, bs$HVAC.Heating.Type.And.Fuel)
# all Electricity ASHP should have Heating Type = Ducted Heat Pump
# all Electricity MSHP should have Heating Type = Non-Ducted Heat Pump

bs_e1<-bs[bs$HVAC.Heating.Type %in% c("Ducted Heating","Non-Ducted Heating") & 
            bs$HVAC.Heating.Type.And.Fuel %in% c("Electricity ASHP","Electricity MSHP"),]

bs_e2<-bs[bs$HVAC.Has.Shared.System=="Cooling Only" & bs$HVAC.Heating.Type.And.Fuel %in% c("Electricity ASHP","Electricity MSHP"),]

bse<-rbind(bs_e1,bs_e2)
bseu<-unique(bse)

table(bs_e1$HVAC.Heating.Type, bs_e1$HVAC.Heating.Type.And.Fuel)
table(bs_e1$HVAC.Has.Shared.System)
# table(bs_ok$HVAC.Has.Shared.System)

table(bs_e1$HVAC.Has.Shared.System,bs_e1$HVAC.Heating.Type)
table(bs_e1$HVAC.Has.Shared.System,bs_e1$HVAC.Heating.Type.And.Fuel)
# 
# table(bs_ok$HVAC.Has.Shared.System,bs_ok$HVAC.Heating.Type)
# table(bs_ok$HVAC.Has.Shared.System,bs_ok$HVAC.Heating.Type.And.Fuel)
# now make the required fixes ############
table(bseu$HVAC.Heating.Type,bseu$HVAC.Heating.Type.And.Fuel, bseu$HVAC.Has.Shared.System)

bseu[bseu$HVAC.Heating.Type.And.Fuel=="Electricity ASHP",]$HVAC.Heating.Type<-"Ducted Heat Pump"
bseu[bseu$HVAC.Heating.Type.And.Fuel=="Electricity MSHP",]$HVAC.Heating.Type<-"Non-Ducted Heat Pump"

bseu$HVAC.Cooling.Type<-"Heat Pump"
bseu$HVAC.Cooling.Efficiency<-"Heat Pump"

bseu$HVAC.Has.Shared.System<-"None"
bseu$HVAC.Shared.Efficiencies<-"None"

# bseu[bseu$HVAC.Heating.Type %in% c("Ducted Heat Pump","Non-Ducted Heat Pump") & !bseu$HVAC.Cooling.Type=="Shared Cooling",]$HVAC.Cooling.Type<-"Heat Pump"
# bseu[bseu$HVAC.Cooling.Type=="Heat Pump",]$HVAC.Cooling.Efficiency<-"Heat Pump"

bs0<-bs[!bs$Building %in% bseu$Building,]

bs_new<-rbind(bs0,bseu)
bs_new<-bs_new[order(bs_new$Building),]
identical(bs$Building,bs_new$Building) # should be true 
# check and save #########
table(bs_new$HVAC.Heating.Type,bs_new$HVAC.Heating.Type.And.Fuel, bs_new$HVAC.Has.Shared.System)
table(bseu$`HVAC Heating Type`,bseu$`HVAC Heating Type And Fuel`, bseu$`HVAC Has Shared System`)

table(bs_new$HVAC.Heating.Type,bs_new$HVAC.Heating.Type.And.Fuel)
table(bs$HVAC.Heating.Type,bs$HVAC.Heating.Type.And.Fuel)
table(bs_new$HVAC.Heating.Type,bs_new$HVAC.Has.Shared.System)
table(bs$HVAC.Heating.Type,bs$HVAC.Has.Shared.System)

bs_new<-rm_dot2(bs_new)
write.csv(bs_new,file='HP_redo/bs_AR_2055.csv', row.names = FALSE)
bseu<-rm_dot2(bseu)
write.csv(bseu,file='HP_redo/bs_AR_2055_redo.csv', row.names = FALSE)
# now read in the results of the re-sim, and check that things look good #########
res<-read.csv("../Eagle_outputs/HP_redo/res_AR_2055_redo2.csv")
rs2020<-read.csv("../Eagle_outputs/res_2020_complete.csv")

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
rs20<-result_sum(rs2020,2020)
AR55rd<-result_sum(res,2055)

# results look reasonable
round(tapply(AR55rd$Tot_GJ_SPH,AR55rd$hvac_heating_type_and_fuel,mean),2)
round(tapply(rs20$Tot_GJ_SPH,rs20$hvac_heating_type_and_fuel,mean),2)

round(tapply(AR55rd$hvac_heating_capacity_w ,AR55rd$hvac_heating_type_and_fuel,mean),2)
round(tapply(rs20$hvac_heating_capacity_w,rs20$hvac_heating_type_and_fuel,mean),2)

round(tapply(AR55rd$Tot_GJ_SPC,AR55rd$hvac_heating_type_and_fuel,mean),2)
round(tapply(rs20$Tot_GJ_SPC,rs20$hvac_heating_type_and_fuel,mean),2)

round(tapply(AR55rd$Tot_GJ,AR55rd$hvac_heating_type_and_fuel,mean),2)
round(tapply(rs20$Tot_GJ,rs20$hvac_heating_type_and_fuel,mean),2)

# now apply adjustment to all bs csv files #########
filenames<-c("bs_RR_2025.csv","bs_RR_2030.csv","bs_RR_2035.csv","bs_RR_2040.csv","bs_RR_2045.csv","bs_RR_2050.csv","bs_RR_2055.csv","bs_RR_2060.csv",
             "bs_AR_2025.csv","bs_AR_2030.csv","bs_AR_2035.csv","bs_AR_2040.csv","bs_AR_2045.csv","bs_AR_2050.csv","bs_AR_2060.csv",
             "bs_ER_2025.csv","bs_ER_2030.csv","bs_ER_2035.csv","bs_ER_2040.csv","bs_ER_2045.csv","bs_ER_2050.csv","bs_ER_2055.csv","bs_ER_2060.csv",
             "bs_base.csv","bs_baseDE.csv","bs_baseDERFA.csv","bs_baseRFA.csv","bs_hiDR.csv","bs_hiDRDE.csv", 
             "bs_hiDRDERFA.csv","bs_hiDRRFA.csv","bs_hiMF.csv","bs_hiMFDE.csv","bs_hiMFDERFA.csv","bs_hiMFRFA.csv","bs2020_180k.csv")

res_filenames<-c("res_RR_2025.csv","res_RR_2030_complete.csv","res_RR_2035.csv","res_RR_2040.csv","res_RR_2045.csv","res_RR_2050.csv","res_RR_2055.csv","res_RR_2060_complete.csv",
                 "res_AR_2025.csv","res_AR_2030.csv","res_AR_2035.csv","res_AR_2040.csv","res_AR_2045.csv","res_AR_2050.csv","res_AR_2060.csv",
                 "res_ER_2025.csv","res_ER_2030.csv","res_ER_2035.csv","res_ER_2040.csv","res_ER_2045.csv","res_ER_2050.csv","res_ER_2055.csv","res_ER_2060.csv",
                 "res_proj_base.csv","res_proj_baseDE.csv","res_proj_baseDERFA.csv","res_proj_baseRFA.csv","res_proj_hiDR.csv","res_proj_hiDRDE.csv", 
                 "res_proj_hiDRDERFA.csv","res_proj_hiDRRFA.csv","res_proj_hiMF.csv","res_proj_hiMFDE.csv","res_proj_hiMFDERFA.csv","res_proj_hiMFRFA.csv","res_2020_complete.csv")

for (k in 1:length(filenames)) { print(k)
  fn<-filenames[k]
  rfn<-paste("../Eagle_outputs/",res_filenames[k],sep="")
  bs<-read.csv(fn)
  rs<-read.csv(rfn)
  
  bs_e1<-bs[bs$HVAC.Heating.Type %in% c("Ducted Heating","Non-Ducted Heating") & 
              bs$HVAC.Heating.Type.And.Fuel %in% c("Electricity ASHP","Electricity MSHP"),]
  
  bs_e2<-bs[bs$HVAC.Has.Shared.System=="Cooling Only" & bs$HVAC.Heating.Type.And.Fuel %in% c("Electricity ASHP","Electricity MSHP"),]
  
  # bs_e3<-bs[bs$County %in% c("TX, Nolan County","TX, Fisher County","TX, Stonewall County"),]
  bs_e3<-bs[bs$Building %in% rs[!rs$completed_status=="Success",]$building_id,]
  
  bse<-rbind(bs_e1,bs_e2)
  bseu<-unique(bse)
  
  bseu[bseu$HVAC.Heating.Type.And.Fuel=="Electricity ASHP",]$HVAC.Heating.Type<-"Ducted Heat Pump"
  bseu[bseu$HVAC.Heating.Type.And.Fuel=="Electricity MSHP",]$HVAC.Heating.Type<-"Non-Ducted Heat Pump"
  
  bseu$HVAC.Cooling.Type<-"Heat Pump"
  bseu$HVAC.Cooling.Efficiency<-"Heat Pump"
  
  bseu$HVAC.Has.Shared.System<-"None"
  bseu$HVAC.Shared.Efficiencies<-"None"
  
  bseu<-unique(rbind(bseu,bs_e3))
  bseu<-bseu[order(bseu$Building),]
  bseu<-rm_dot2(bseu)
  
  save_fn<-paste('HP_redo/',substring(fn,1,nchar(fn)-4),'_redo.csv',sep = "")
  write.csv(bseu,file=save_fn, row.names = FALSE)
}

# run again for the failed jobs in AR 2060 ########

fn<-"HP_redo/bs_AR_2060_redo.csv"
rfn<-"../Eagle_outputs/HP_redo/res_AR_2060_redo.csv"
bs<-read.csv(fn)
rs<-read.csv(rfn)

bse<-bs[!bs$Building %in% rs$building_id,]
bseu<-unique(bse)

bseu<-rm_dot2(bseu)

save_fn<-"HP_redo/bs_AR_2060_redo2.csv"
write.csv(bseu,file=save_fn, row.names = FALSE)