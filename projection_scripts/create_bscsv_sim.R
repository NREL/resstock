# create csv files for simulation
rm(list=ls()) # clear workspace i.e. remove saved variables
cat("\014") # clear console
# Last Update April 30 2022 Peter Berrill
# Purpose: This script takes the .RData files describing housing characteristics post-renovation, and generates .csv files which can be sent to ResStock for simulation

# Inputs: 3 renovation .RData files; RenStandard, RenAdvanced, RenExtElec. 
# Outputs: 24 (8 sim_years by 3 renovation scenarios) renovation buildstock csv type files: bs_RR_2025.csv, bs_RR_2030.csv, etc.


setwd("~/Yale Courses/Research/Final Paper/resstock_projections/projection_scripts")
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

load("../Intermediate_results/RenStandard.RData")
rs_RR<-rs_2020_2060
load("../Intermediate_results/RenAdvanced.RData")
rs_AR<-rs_2020_2060
rm(rs_2020_2060)
load("../Intermediate_results/RenExtElec.RData")
rs_ER<-rs_2020_2060
rm(rs_2020_2060)

rs_RR_2025<-rm_dot2(rs_RR[rs_RR$Year==2025,1:114])
rs_RR_2030<-rm_dot2(rs_RR[rs_RR$Year==2030,1:114])
rs_RR_2035<-rm_dot2(rs_RR[rs_RR$Year==2035,1:114])
rs_RR_2040<-rm_dot2(rs_RR[rs_RR$Year==2040,1:114])
rs_RR_2045<-rm_dot2(rs_RR[rs_RR$Year==2045,1:114])
rs_RR_2050<-rm_dot2(rs_RR[rs_RR$Year==2050,1:114])
rs_RR_2055<-rm_dot2(rs_RR[rs_RR$Year==2055,1:114])
rs_RR_2060<-rm_dot2(rs_RR[rs_RR$Year==2060,1:114])

rs_AR_2025<-rm_dot2(rs_AR[rs_AR$Year==2025,1:114])
rs_AR_2030<-rm_dot2(rs_AR[rs_AR$Year==2030,1:114])
rs_AR_2035<-rm_dot2(rs_AR[rs_AR$Year==2035,1:114])
rs_AR_2040<-rm_dot2(rs_AR[rs_AR$Year==2040,1:114])
rs_AR_2045<-rm_dot2(rs_AR[rs_AR$Year==2045,1:114])
rs_AR_2050<-rm_dot2(rs_AR[rs_AR$Year==2050,1:114])
rs_AR_2055<-rm_dot2(rs_AR[rs_AR$Year==2055,1:114])
rs_AR_2060<-rm_dot2(rs_AR[rs_AR$Year==2060,1:114])

rs_ER_2025<-rm_dot2(rs_ER[rs_ER$Year==2025,1:114])
rs_ER_2030<-rm_dot2(rs_ER[rs_ER$Year==2030,1:114])
rs_ER_2035<-rm_dot2(rs_ER[rs_ER$Year==2035,1:114])
rs_ER_2040<-rm_dot2(rs_ER[rs_ER$Year==2040,1:114])
rs_ER_2045<-rm_dot2(rs_ER[rs_ER$Year==2045,1:114])
rs_ER_2050<-rm_dot2(rs_ER[rs_ER$Year==2050,1:114])
rs_ER_2055<-rm_dot2(rs_ER[rs_ER$Year==2055,1:114])
rs_ER_2060<-rm_dot2(rs_ER[rs_ER$Year==2060,1:114])

rs_ER_sample<-rs_ER_2025[1:10,]
rs_TX<-rs_ER_2025[rs_ER_2025$County=="TX, Nolan County",]
rs_ER_sample<-rbind(rs_ER_sample,rs_TX)


write.csv(rs_RR_2025,file='../scen_bscsv_sim/bs_RR_2025.csv', row.names = FALSE)
write.csv(rs_RR_2030,file='../scen_bscsv_sim/bs_RR_2030.csv', row.names = FALSE)
write.csv(rs_RR_2035,file='../scen_bscsv_sim/bs_RR_2035.csv', row.names = FALSE)
write.csv(rs_RR_2040,file='../scen_bscsv_sim/bs_RR_2040.csv', row.names = FALSE)
write.csv(rs_RR_2045,file='../scen_bscsv_sim/bs_RR_2045.csv', row.names = FALSE)
write.csv(rs_RR_2050,file='../scen_bscsv_sim/bs_RR_2050.csv', row.names = FALSE)
write.csv(rs_RR_2055,file='../scen_bscsv_sim/bs_RR_2055.csv', row.names = FALSE)
write.csv(rs_RR_2060,file='../scen_bscsv_sim/bs_RR_2060.csv', row.names = FALSE)

write.csv(rs_AR_2025,file='../scen_bscsv_sim/bs_AR_2025.csv', row.names = FALSE)
write.csv(rs_AR_2030,file='../scen_bscsv_sim/bs_AR_2030.csv', row.names = FALSE)
write.csv(rs_AR_2035,file='../scen_bscsv_sim/bs_AR_2035.csv', row.names = FALSE)
write.csv(rs_AR_2040,file='../scen_bscsv_sim/bs_AR_2040.csv', row.names = FALSE)
write.csv(rs_AR_2045,file='../scen_bscsv_sim/bs_AR_2045.csv', row.names = FALSE)
write.csv(rs_AR_2050,file='../scen_bscsv_sim/bs_AR_2050.csv', row.names = FALSE)
write.csv(rs_AR_2055,file='../scen_bscsv_sim/bs_AR_2055.csv', row.names = FALSE)
write.csv(rs_AR_2060,file='../scen_bscsv_sim/bs_AR_2060.csv', row.names = FALSE)

write.csv(rs_ER_2025,file='../scen_bscsv_sim/bs_ER_2025.csv', row.names = FALSE)
write.csv(rs_ER_2030,file='../scen_bscsv_sim/bs_ER_2030.csv', row.names = FALSE)
write.csv(rs_ER_2035,file='../scen_bscsv_sim/bs_ER_2035.csv', row.names = FALSE)
write.csv(rs_ER_2040,file='../scen_bscsv_sim/bs_ER_2040.csv', row.names = FALSE)
write.csv(rs_ER_2045,file='../scen_bscsv_sim/bs_ER_2045.csv', row.names = FALSE)
write.csv(rs_ER_2050,file='../scen_bscsv_sim/bs_ER_2050.csv', row.names = FALSE)
write.csv(rs_ER_2055,file='../scen_bscsv_sim/bs_ER_2055.csv', row.names = FALSE)
write.csv(rs_ER_2060,file='../scen_bscsv_sim/bs_ER_2060.csv', row.names = FALSE)

write.csv(rs_ER_sample,file='../scen_bscsv_sim/bs_ER_sample.csv', row.names = FALSE)


